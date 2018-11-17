/*-
 * election.c --
 *	This functions in this file are responsible for performing the
 *	election algorithm used by the customs daemons.
 *
 * Copyright (c) 1988, 1989 by the Regents of the University of California
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any non-commercial purpose
 * and without fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California,
 * Berkeley Softworks and Adam de Boor make no representations about
 * the suitability of this software for any purpose.  It is provided
 * "as is" without express or implied warranty.
 */
#ifndef lint
static char *rcsid =
"$Id: election.c,v 1.3 91/07/12 17:11:04 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customsInt.h"
#include    "log.h"
#include    <sys/file.h>
#include    <sys/stat.h>
#include    <errno.h>
#include    <arpa/inet.h>
#include    <assert.h>
#include    <stdio.h>

struct sockaddr_in   masterAddr;

/*-
 * bool_t
 * CustomsCampaign ()
 *
 * Broadcast by an sca that wants to become the master. Response is TRUE
 * if someone else is also trying to become the master. FALSE if someone else
 * already is the master.
 */

/*-
 * void
 * CustomsNewMaster()
 *
 * Broadcast by the new mca to all scas to inform them that a new master
 * has been elected and the receiving sca should restart.
 */

static enum {
    HAVE_NONE,   	  	/* No response */
    HAVE_CONFLICT,	  	/* Other agent also campaigning */
    HAVE_MASTER  	  	/* Master exists */
} 	    	  	    campaignResponse;

typedef struct sockaddr_in  SockAddr;
typedef struct in_addr	    InetAddr;

/*
 * A variable to track where we are in an election.
 */
enum {
    NONE,   	    /* No election is taking place */
    WAITING,	    /* We've ok'd someone else's petition, now waiting for
		     * NewMaster message */
    PETITIONING,    /* We've asked to become the master. Waiting for
		     * responses */
    BACKOFF,	    /* Our petition was refused. Waiting to try again. */
    REGISTERING,    /* Registering with the new master */
    YEARNING,	    /* We're not allowed to become the master, but we have
		     * no master on the horizon, so wait until someone
		     * speaks up. */
} ElectionState;

InetAddr    	  lastPetition;	/* Address of last sca whose petition we
				 * accepted. Valid only if WAITING */
Rpc_Event    	  waitEvent;	/* Event for returning to NONE state after
				 * WAITING */

struct timeval	  backOff;  	/* Timeout for exponential backoff */

long	    	  elect_Token;	/* Token for our network. Set at startup */

static void 	  ElectCampaign(),
		  ElectNewMaster(),
		  ElectForce();
/*-
 *-----------------------------------------------------------------------
 * Elect_Init --
 *	Initialize this module.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The random number generator is randomized, ElectionState set to
 *	NONE, lastPetition set to INADDR_ANY and the election RPC servers
 *	installed on the main udp socket.
 *
 *-----------------------------------------------------------------------
 */
void
Elect_Init ()
{
    struct timeval t;

    /*
     * Randomize for exponential backoff
     */
    gettimeofday(&t, (struct timezone *)NULL);
    srandom((int)(getpid() + gethostid() + t.tv_sec + t.tv_usec));
    
    ElectionState = NONE;
    lastPetition.s_addr = htonl(INADDR_ANY);

    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_CAMPAIGN, ElectCampaign,
		     Rpc_SwapLong, Rpc_SwapLong, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_NEWMASTER, ElectNewMaster,
		     Rpc_SwapLong, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_ELECT, ElectForce,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * ElectBackOffDone --
 *	Called when the backOff time has expired. Sets the boolean to
 *	which it is pointed to TRUE.
 *
 * Results:
 *	TRUE.
 *
 * Side Effects:
 *	'done' in ElectBackOff is set TRUE.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ElectBackOffDone(donePtr)
    Boolean *donePtr;
{
    *donePtr = TRUE;
    return(TRUE);
}

/*-
 *-----------------------------------------------------------------------
 * ElectBackOff --
 *	Delay for a random amount of time that increases exponentially
 *	each time this is called. If backOff is 0, a new random time
 *	is selected, else the old time is multiplied by 2.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	We delay for a while, handling requests from clients and other
 *	agents as gracefully as possible.
 *
 *-----------------------------------------------------------------------
 */
static void
ElectBackOff()
{
    Rpc_Event	  backEvent;
    Boolean 	  done;
    
    if ((backOff.tv_sec == 0) && (backOff.tv_usec == 0)) {
	int t;

	/*
	 * 1,000,000 ~ 2^20, so take the low twenty bits for microseconds
	 * and the next 3 bits for seconds to get the new backoff amount.
	 */
	t = random();
	backOff.tv_usec = t & 0xfffff;
	backOff.tv_sec = (t >> 20) & 7;
    } else {
	/*
	 * Double the delay.
	 */
	backOff.tv_usec *= 2;
	backOff.tv_sec *= 2;
    }
    /*
     * Normalize the time value
     */
    while (backOff.tv_usec > 1000000) {
	backOff.tv_sec += 1;
	backOff.tv_usec -= 1000000;
    }

    done = FALSE;
    backEvent = Rpc_EventCreate(&backOff, ElectBackOffDone, (Rpc_Opaque)&done);
    if (verbose) {
	printf ("waiting %d.%06d seconds\n", backOff.tv_sec, backOff.tv_usec);
    }

    while (!done) {
	Rpc_Wait();
    }
    Rpc_EventDelete(backEvent);
}

/*-
 *-----------------------------------------------------------------------
 * ElectCampaignResponse --
 *	Catch the response to a CAMPAIGN broadcast. Accepts responses
 *	until one comes from the current master.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If the response is FALSE (master saying no), masterAddr is
 *	overwritten and campaignResponse is set to HAVE_MASTER. Else,
 *	campaignResponse is set to HAVE_CONFLICT.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static Boolean
ElectCampaignResponse(from, len, response)
    struct sockaddr_in	*from;	    /* Source of response */
    int	    	  	len;	    /* Length of response */
    Boolean 	  	*response;  /* Response value */
{
    if (ntohs(from->sin_port) != udpPort) {
	/*
	 * If response from a non-agent, ignore it
	 */
	return(False);
    } else if (*response) {
	if (campaignResponse == HAVE_NONE) {
	    campaignResponse = HAVE_CONFLICT;
	}
    } else if (campaignResponse == HAVE_MASTER) {
	if (from->sin_addr.s_addr != masterAddr.sin_addr.s_addr) {
	    /*
	     * If more than one agent is claiming to be the master, inform
	     * the first one we met of the other one's address. It'll take
	     * care of the rest. Not sure how to actually use this, since
	     * broadcasting isn't multi-threaded enough -- will get responses
	     * back and lose them while this call is in progress.
	     */
	    printf("Warning: duplicate master at %s\n",
		   InetNtoA(from->sin_addr));
	    (void) Rpc_Call(udpSocket, &masterAddr, (Rpc_Proc)CUSTOMS_CONFLICT,
			    sizeof(struct sockaddr_in), (Rpc_Opaque)from,
			    0, (Rpc_Opaque)0,
			    CUSTOMSINT_NRETRY, &retryTimeOut);
	}
    } else {
	campaignResponse = HAVE_MASTER;
	masterAddr = *from;
	return (True);
    }
    /*
     * We want to broadcast for the entire time....
     */
    return (False);
}

/*-
 *-----------------------------------------------------------------------
 * ElectMasterResponse --
 *	Catch the response to a MASTER broadcast. For each successful
 *	response, we attempt to register with the master. If that
 *	succeeds, we're happy.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	masterAddr is overwritten with the master address returned
 *	by the broadcast.
 *
 *	If the response pans out, ElectionState is reset to NONE.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static Boolean
ElectMasterResponse(from, len, response)
    struct sockaddr_in	*from;	    /* Source of response */
    int	    	  	len;	    /* Length of response */
    struct sockaddr_in 	*response;  /* Response value */
{
    if (ntohs(from->sin_port) != udpPort) {
	/*
	 * If response from a non-agent, ignore it
	 */
	return(False);
    } else {
	Rpc_Stat    rstat;

	if (verbose) {
	    printf("received response of %s. registering...",
		   InetNtoA(from->sin_addr));
	}
	rstat = Rpc_Call(udpSocket, &masterAddr,
			 (Rpc_Proc)CUSTOMS_REG,
			 regPacketLen, (Rpc_Opaque)regPacket,
			 0, (Rpc_Opaque)0,
			 CUSTOMSINT_NRETRY, &retryTimeOut);

	if (rstat == RPC_SUCCESS) {
	    if (verbose) {
		printf ("New master: %s\n",
			InetNtoA(masterAddr.sin_addr));
	    }
	    ElectionState = NONE;
	    return (True);	/* Stop the broadcast */
	} else if (verbose) {
	    printf("GetMaster: contacting new: %s\n",
		   Rpc_ErrorMessage(rstat));
	}
	/*
	 * Keep searching...
	 */
	return(False);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Elect_GetMaster --
 *	Elect a new master using a broadcast election algorithm. When
 *	this function returns, a new master will have been elected and its
 *	address stored in masterAddr. If we are that new master, amMaster
 *	will be TRUE.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	masterAddr is overwritten and amMaster may be changed.
 *
 *-----------------------------------------------------------------------
 */
void
Elect_GetMaster ()
{
    Boolean  	  	conflict;   	    /* Space for Campaign response */
    Rpc_Stat	  	rstat;	    	    /* Status of broadcast */
    SockAddr	  	broadcast;  	    /* Address to which to broadcast */

    timerclear(&backOff);
    broadcast.sin_family = AF_INET;
    broadcast.sin_port = htons(udpPort);
    broadcast.sin_addr.s_addr = htonl(INADDR_ANY);
    
    /*
     * If we're not allowed to become the master, wait until someone comes
     * along to be it. Master agents will occasionally trumpet their mastery
     * so we won't wait forever after a network partition...
     */
    if (!canBeMaster) {
	ElectionState = YEARNING;

	if (verbose) {
	    printf("Seeking new master...");
	    fflush(stdout);
	}
	
	/*
	 * First see if anyone else knows the name of a good master.
	 */
	rstat = Rpc_Broadcast(udpSocket, &broadcast,
			      (Rpc_Proc)CUSTOMS_MASTER,
			      sizeof(elect_Token), (Rpc_Opaque)&elect_Token,
			      sizeof(masterAddr), (Rpc_Opaque)&masterAddr,
			      3, &retryTimeOut,
			      ElectMasterResponse);

	if (verbose && rstat != RPC_SUCCESS) {
	    printf("no such luck. Waiting for master to appear.\n");
    	    fflush(stdout);
	}
	    
	/*
	 * If we found one, ElectionState will no longer be YEARNING and
	 * this loop will do nothing. Else we will await the return of
	 * a master...
	 */
	while (ElectionState == YEARNING) {
	    Rpc_Wait();
	}
	return;
    }
    
    while (1) {
	if (verbose) {
	    printf("Petitioning...");
	}
	ElectionState = PETITIONING;
	campaignResponse = HAVE_NONE;
	rstat = Rpc_Broadcast(udpSocket, &broadcast,
			      (Rpc_Proc)CUSTOMS_CAMPAIGN,
			      sizeof(elect_Token), (Rpc_Opaque)&elect_Token,
			      sizeof(conflict), (Rpc_Opaque)&conflict,
			      3, &retryTimeOut,
			      ElectCampaignResponse);
	switch(rstat) {
	    case RPC_SUCCESS:
		/*
		 * Someone objected to our becoming master.
		 */
		if (campaignResponse == HAVE_CONFLICT) {
		    /*
		     * Objected because it was also trying to become the
		     * master. Do exponential backoff in an attempt not
		     * to conflict again.
		     */
		    if (verbose) {
			printf("CONFLICT: backing off\n");
		    }
		    ElectionState = BACKOFF;
		    ElectBackOff();
		    break;
		} else if (campaignResponse == HAVE_MASTER) {
		    /*
		     * Objected because it was already the master.
		     * Attempt to contact the agent. If we manage to do so,
		     * register with it. If that fails, try again...
		     */
		    if (verbose) {
			printf("REFUSED: Contacting new master...");
		    }
		    ElectionState = NONE;
		    rstat = Rpc_Call(udpSocket, &masterAddr,
				     (Rpc_Proc)CUSTOMS_REG,
				     regPacketLen, (Rpc_Opaque)regPacket,
				     0, (Rpc_Opaque)0,
				     CUSTOMSINT_NRETRY, &retryTimeOut);
		    if (rstat == RPC_SUCCESS) {
			if (verbose) {
			    printf ("New master: %s\n",
				    InetNtoA(masterAddr.sin_addr));
			}
			return;
		    } else if (verbose) {
			printf("GetMaster: contacting new: %s\n",
			       Rpc_ErrorMessage(rstat));
		    }
		    break;
		}
		/*FALLTHRU*/
	    case RPC_TIMEDOUT:
		/*
		 * Noone responded. We are the master.
		 */
		masterAddr = localAddr;
		if (verbose) {
		    printf("No one responded: Accepting mastery\n");
		}
		/*
		 * Become the master -- it will send out the NEWMASTER call
		 * when it's ready.
		 */
		ElectionState = NONE;
		amMaster = TRUE;
		MCA_Init();
		Log_Send(LOG_NEWMASTER, 1, xdr_sockaddr_in, &localAddr);

		return;
	    default: {
		extern int errno;
		extern char *sys_errlist[];

		printf("Rpc_Broadcast: %s\n", sys_errlist[errno]);
		printf("CUSTOMS_CAMPAIGN: %s\n", Rpc_ErrorMessage(rstat));
		break;
	    }
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Elect_InProgress --
 *	Tell if an election is in progress.
 *
 * Results:
 *	TRUE if there's one going. FALSE otherwise.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Elect_InProgress ()
{
    return ((ElectionState == PETITIONING) || (ElectionState == BACKOFF) ||
	    (ElectionState == YEARNING));
}
    

/*-
 *-----------------------------------------------------------------------
 * ElectClearWait --
 *	Return from WAITING to NONE state. Callback for ElectCampaign.
 *
 * Results:
 *	FALSE.
 *
 * Side Effects:
 *	ElectionState is set to NONE if it was WAITING.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ElectClearWait()
{
    if (ElectionState == WAITING) {
	ElectionState = NONE;
    }
    Rpc_EventDelete(waitEvent);
    waitEvent = (Rpc_Event)0;
    return(FALSE);
}
/*-
 *-----------------------------------------------------------------------
 * ElectCampaign --
 *	Stub for CUSTOMS_CAMPAIGN call. To allow for an heterogenous
 *	network, this stub only pays attention to calls for which the
 *	data is elect_Token. elect_Token is set at startup and allows a
 *	network to be partitioned into subnets.
 *
 *	If we have nothing to say, we don't respond at all. We can do that
 *	now there's only the campaigning agent waiting.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A response will be generated if we are (a) campaigning ourselves or
 * 	(b) we are the master.
 *
 *-----------------------------------------------------------------------
 */
static void
ElectCampaign(from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    int	    	  	*data;
{
    Boolean 	  	response;
    
    if (verbose) {
	printf("Received CAMPAIGN from %d@%s: ", ntohs(from->sin_port),
	       InetNtoA(from->sin_addr));
    }
    if (ntohs(from->sin_port) != udpPort) {
	return;
    }
    if (Local(from)) {
	if (verbose) {
	    printf("talking to myself, again...\n");
	}
    } else if ((len == sizeof(int)) && (*data == elect_Token)) {
	/*
	 * If machine has same byte-order as we do, then we can play
	 * master/slave with it...
	 */
	if (amMaster) {
	    if (verbose) {
		printf("return(FALSE)\n");
	    }
	    response = FALSE;
	    Rpc_Return(msg, sizeof(response), (Rpc_Opaque)&response);
	} else if (ElectionState == PETITIONING) {
	    if (verbose) {
		printf ("return(TRUE)\n");
	    }
	    response = TRUE;
	    Rpc_Return(msg, sizeof(response), (Rpc_Opaque)&response);
	} else if ((ElectionState == WAITING) &&
		   (lastPetition.s_addr != from->sin_addr.s_addr))
	{
	    /*
	     * If someone else was campaigning, we refuse to let
	     * this agent become the master. This is in case the
	     * campaigning one missed the broadcast somehow.
	     */
	    if (verbose) {
		printf ("return (TRUE) -- conflict with %s\n",
			InetNtoA(lastPetition));
	    }
	    response = TRUE;
	    Rpc_Return(msg, sizeof(response),
		       (Rpc_Opaque)&response);
	} else {
	    /*
	     * It's ok for this agent to become master, as far as we're
	     * concerned. Because petitions are broadcast at startup,
	     * we don't want to stay in the WAITING state forever, or
	     * we'll have to wait for everyone to timeout before we can
	     * elect a master (everyone's petitions will be refused
	     * until then) and that isn't good. So we set an event for
	     * twenty seconds from now to return to the NONE state.
	     */
	    struct timeval waitTimeout;
	    
	    if (verbose) {
		printf("OK\n");
	    }
	    if (ElectionState == NONE) {
		/*
		 * Only alter the state if no election was in progress.
		 * We must allow petitions if ElectionState == BACKOFF,
		 * but if we set ElectionState to WAITING, the Avail
		 * module might try to send to a non-existent master...
		 */
		ElectionState = WAITING;
	    }
	    lastPetition = from->sin_addr;
	    
	    waitTimeout.tv_sec = 10;
	    waitTimeout.tv_usec = 0;
	    if (waitEvent != (Rpc_Event)NULL) {
		Rpc_EventDelete(waitEvent);
	    }
	    waitEvent = Rpc_EventCreate(&waitTimeout, ElectClearWait,
					(Rpc_Opaque)0);
	}
    } else if (verbose) {
	printf("not my type\n");
    }
}

/*-
 *-----------------------------------------------------------------------
 * ElectNewMaster --
 *	Stub for the CUSTOMS_NEWMASTER broadcast call.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If we currently are the master, cancels our mastery.
 *
 *-----------------------------------------------------------------------
 */
static void
ElectNewMaster(from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    int	    	  	*data;
{
    Rpc_Stat	  	rstat;

    if (verbose) {
	printf ("Received NEWMASTER from %d@%s: ", ntohs(from->sin_port),
		InetNtoA(from->sin_addr));
    }
    if (ntohs(from->sin_port) != udpPort) {
	time_t	now;

	time(&now);
	if (verbose) {
	    printf("wrong port number -- %s", ctime(&now));
	} else {
	    printf("Bogus NEWMASTER from %d@%s -- %s", ntohs(from->sin_port),
		   InetNtoA(from->sin_addr), ctime(&now));
	}
	return;
    }
    if ((ElectionState == NONE) || (ElectionState == WAITING) ||
	(ElectionState == YEARNING))
    {
	if (Local(from)) {
	    assert(ElectionState != YEARNING);
	    Rpc_Return(msg, 0, (Rpc_Opaque)0);
	    if (verbose) {
		printf ("talking to myself, again...\n");
	    }
	} else if ((len == sizeof(int)) && (*data == elect_Token)) {
	    Rpc_Return(msg, 0, (Rpc_Opaque)0);
	    if (amMaster) {
		if (verbose) {
		    printf ("cancelling mastery\n");
		}
		MCA_Cancel();
		amMaster = FALSE;
	    } else if (verbose) {
		putchar('\n');
	    }
	    masterAddr = *from;
	    ElectionState = REGISTERING;
	    rstat = Rpc_Call(udpSocket, &masterAddr, (Rpc_Proc)CUSTOMS_REG,
			     regPacketLen, (Rpc_Opaque)regPacket,
			     0, (Rpc_Opaque)0,
			     CUSTOMSINT_NRETRY, &retryTimeOut);

	    if (rstat != RPC_SUCCESS) {
		printf ("Registering with new master: %s\n",
			Rpc_ErrorMessage(rstat));
		Elect_GetMaster();
	    }
	    ElectionState = NONE;
	} else if (verbose) {
	    printf ("not my type\n");
	}
    } else if (verbose) {
	printf ("ignored\n");
    }
}
/*-
 *-----------------------------------------------------------------------
 * ElectForce --
 *	Force an election, cancelling our mastery, if we're the master.
 *
 * Results:
 *	Nothing.
 *
 * Side Effects:
 *	
 *-----------------------------------------------------------------------
 */
static void
ElectForce(from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    int	    	  	*data;
{
    if (verbose) {
	printf("ELECT received from %d@%s...",
	       ntohs(from->sin_port), InetNtoA(from->sin_addr));
    }
    
    /*
     * Signal our acceptance
     */
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
    
    /*
     * If we're the master, cancel it before starting the election.
     */
    if (amMaster) {
	if (verbose) {
	    printf ("cancelling mastery\n");
	}
	MCA_Cancel();
	amMaster = FALSE;
    } else if (verbose) {
	putchar('\n');
    }

    /*
     * Now force an election.
     */
    Elect_GetMaster();
}
