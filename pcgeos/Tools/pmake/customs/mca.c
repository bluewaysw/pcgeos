/*-
 * mca.c --
 *	Functions to act as the Master Customs Agent.
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
 *
 */
#ifndef lint
static char *rcsid =
"$Id: mca.c,v 1.3 92/04/17 21:50:49 dloft Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customsInt.h"
#include    "lst.h"
#include    "string.h"
#include    "log.h"
#include    <netdb.h>
#include    <stdio.h>

typedef struct {
    char    	  	*name;    	/* The name of the host */
    Lst	    	  	clients;  	/* A list of machines it will serve */
    long 	  	avail;    	/* 0 if the machine is available */
    long    	    	rating;	    	/* Availability index (high => more
					 * available */
    struct in_addr	addr;	    	/* Address of the server. */
    unsigned long 	arch;	    	/* Architecture code */
    Rpc_Event  	  	downEvent;  	/* If this event ever gets taken,
					 * the host is down... */
} Server, *ServerPtr;

static Lst  	    allHosts; 	    /* All hosts we know of */
static LstNode	    lastAlloc;	    /* Last server allocated */
static ServerPtr    us;	    	    /* Our record */
static u_long  	    nextID = 0;	    /* The next ID for an export permit */
static Rpc_Event    boastEvent;	    /* Event that causes us to boast of our
				     * mastery at random intervals */
/*-
 *-----------------------------------------------------------------------
 * MCACmpAddr --
 *	Compare the address of a Server record to the desired address.
 *
 * Results:
 *	0 or non-0 depending on match or non-match, resp.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
static int
MCACmpAddr (servPtr, addrPtr)
    ServerPtr	  	servPtr;
    struct in_addr	*addrPtr;
{
    return (servPtr->addr.s_addr - addrPtr->s_addr);
}

/*-
 *-----------------------------------------------------------------------
 * MCAFindHostAddr --
 *	Find a host in the list of allHosts using its address as a key.
 *	Create it if it isn't there and create is TRUE.
 *
 * Results:
 *	The ServerPtr for the host.
 *
 * Side Effects:
 *	A Server structure may be allocated and filled in.
 *
 *-----------------------------------------------------------------------
 */
static ServerPtr
MCAFindHostAddr (addr, name, create)
    struct sockaddr_in	*addr;	    /* Address of host */
    char    	  	*name;	    /* Optional name (must exist if create is
				     * TRUE) */
    Boolean 	  	create;	    /* True if should create a record if we
				     * cannot find one */
{
    LstNode 	  	ln;
    ServerPtr	  	servPtr;
    struct hostent 	*he;

    if (addr->sin_addr.s_addr == htonl(INADDR_LOOPBACK)) {
	/*
	 * 'localhost' address (127.1) means us.
	 */
	servPtr = us;
    } else {
	ln = Lst_Find (allHosts, &addr->sin_addr, MCACmpAddr);
	if (ln != NILLNODE) {
	    servPtr = (ServerPtr) Lst_Datum (ln);
	} else if (create) {
	    servPtr = (ServerPtr) malloc (sizeof (Server));
	    servPtr->avail = AVAIL_DOWN;
	    if (name == (char *)0) {
		he = gethostbyaddr((char *)&addr->sin_addr,
				   sizeof(addr->sin_addr),
				   AF_INET);
		if (he == (struct hostent *)NULL) {
		    name = InetNtoA(addr->sin_addr);
		} else {
		    name = he->h_name;
		}
	    }
	    servPtr->name = (char *) malloc ((unsigned)(strlen(name) + 1));
	    strcpy (servPtr->name, name);
	    servPtr->clients = NILLST;
	    servPtr->addr = addr->sin_addr;
	    servPtr->downEvent = (Rpc_Event)0;
	    servPtr->arch = 0;	/* Unknown architecture */
	    (void)Lst_AtEnd (allHosts, (ClientData)servPtr);
	} else {
	    servPtr = (ServerPtr) NULL;
	}
    }

    return servPtr;
}

/*-
 *-----------------------------------------------------------------------
 * MCACmpServerName --
 *	See if the given Server record has the required name. Callback
 *	procedure for MCAFindHost.
 *
 * Results:
 *	0 if the names match. non-zero otherwise.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
MCACmpServerName(servPtr, name)
    ServerPtr	  servPtr;
    char    	  *name;
{
    return (strcmp (servPtr->name, name));
}

/*-
 *-----------------------------------------------------------------------
 * MCAFindHost --
 *	Find a host in the list of allHosts and create it if it isn't
 *	there.
 *
 * Results:
 *	The ServerPtr for the host.
 *
 * Side Effects:
 *	A Server structure may be allocated and filled in.
 *
 *-----------------------------------------------------------------------
 */
static ServerPtr
MCAFindHost (name, create)
    char    	  	*name;
    Boolean 	  	create;
{
    LstNode 	  	ln;
    ServerPtr	  	servPtr;
    struct hostent 	*he;
    struct sockaddr_in 	them;

    ln = Lst_Find (allHosts, (ClientData)name, MCACmpServerName);
    if (ln != NILLNODE) {
	servPtr = (ServerPtr) Lst_Datum (ln);
    } else {
	he = gethostbyname(name);
	if (he == (struct hostent *)NULL) {
	    printf("MCAFindHost: %s unknown\n", name);
	    return (ServerPtr)NULL;
	}
	them.sin_family = AF_INET;
	them.sin_port = 0;
	bcopy(he->h_addr, &them.sin_addr, sizeof(them.sin_addr));
	servPtr = MCAFindHostAddr(&them, name, create);
    }

    return servPtr;
}

/*-
 *-----------------------------------------------------------------------
 * MCADown --
 *	The given server hasn't sent an availability packet in the
 *	required amount of time, so we mark it down...
 *
 * Results:
 *	FALSE.
 *
 * Side Effects:
 *	The given server is marked unavailable and its downEvent
 *	field is zeroed.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
MCADown (servPtr)
    ServerPtr	  servPtr;
{
    servPtr->avail |= AVAIL_DOWN;
    Rpc_EventDelete(servPtr->downEvent);
    servPtr->downEvent = (Rpc_Event)0;
    return(FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * MCAAvail --
 *	Register the availability of a host. We do not return errors
 *	to avoid complicating the Avail module.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	the avail field of the host is altered. An event to mark the host
 *	down is registered.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
MCAAvail (from, msg, len, avail)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    Avail   	  	*avail;	    /* New availability */
{
    ServerPtr	  hostPtr;

    hostPtr = MCAFindHostAddr(from, (char *)0, FALSE);

    if (hostPtr == (ServerPtr)NULL) {
	if (verbose) {
	    printf ("Avail packet received fom unregistered host %x?!",
		      from->sin_addr.s_addr);
	}
    } else if (len == sizeof(Avail)) {
	if (verbose) {
	    printf ("%s %s available (%d)\n", hostPtr->name,
		      avail->avail?"not":"is", avail->avail ? 0:avail->rating);
	}
	
	hostPtr->avail = avail->avail;
	hostPtr->rating = avail->rating;

	if (hostPtr->downEvent) {
	    Rpc_EventReset(hostPtr->downEvent, &avail->interval);
	} else {
	    hostPtr->downEvent = Rpc_EventCreate(&avail->interval, MCADown,
						 (Rpc_Opaque)hostPtr);
	}
    }

    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/*
 * Structure passed as the data for MCAAvailHost since we need to pass two
 * pieces of data and only have one ClientData for passing it.
 */
struct sb {
    ServerPtr	    clntPtr;
    int	    	    flags;
    long    	    rating; /* Rating of currently chosen server */
    ServerPtr	    server; /* Currently chosen server */
};
/*-
 *-----------------------------------------------------------------------
 * MCAAvailHost --
 *	Callback procedure for MCA_HostInt to find a server for a given
 *	client.
 *
 * Results:
 *	0 if the current one is good. 1 if it isn't.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
MCAAvailHost (servPtr, data)
    ServerPtr	  servPtr;
    struct sb	  *data;
{
    if (verbose) {
	printf("\tchecking %s: avail = %d, arch = %d\n",
	       servPtr->name, servPtr->avail, servPtr->arch);
    }
    if ((servPtr->avail == 0) && (servPtr != data->clntPtr) &&
	(!(data->flags & EXPORT_SAME) ||
	 (servPtr->arch == data->clntPtr->arch)) &&
	(!(data->flags & EXPORT_68020) || (servPtr->arch <= 2)) && /*XXX*/
	((servPtr->clients == NILLST) ||
	 (Lst_Member (servPtr->clients,
		      (ClientData)(data->clntPtr)) != NILLNODE)) &&
	(servPtr->rating > data->rating))
    {
	data->rating = servPtr->rating;
	data->server = servPtr;
    }
    return 1;
}

/*-
 *-----------------------------------------------------------------------
 * MCA_HostInt --
 *	Allocate a host for the given machine.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An ExportPermit containing either the address of a machine,
 *	or INADDR_ANY in the case of failure, is sent to the requesting
 *	host and an allocation packet is sent to the server which
 *	was allocated...
 *
 *-----------------------------------------------------------------------
 */
void
MCA_HostInt (from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    Host_Data  	  	*data;	    /* UID and flags for client process */
{
    LstNode 	  	ln;
    ServerPtr	  	clntPtr;    /* Client requesting Host */
    ServerPtr	  	servPtr;    /* Agent to serve client */
    ExportPermit	permit;	    /* Permit to send to client */
    ExportPermit  	allocPermit;/* Permit to send to server */
    int	    	  	uid;

    if (len != sizeof(Host_Data)) {
	Rpc_Error(msg, RPC_BADARGS);
	return;
    }
    uid = data->uid;
    
    clntPtr = MCAFindHostAddr (from, (char *)0, FALSE);

    if ((clntPtr == (ServerPtr) NULL) ||
	(ntohs(from->sin_port) != udpPort))
    {
	/*
	 * XXX: This should probably be done through syslog as well to bring
	 * such attempts to the attention of the proper authorities
	 */
	time_t	now;
	
	time(&now);
	printf("HostInt from %d@%s -- %s", ntohs(from->sin_port),
	       InetNtoA(from->sin_addr),
	       ctime(&now));
	permit.addr.s_addr = htonl(INADDR_ANY);
    } else {
	if (verbose) {
	    printf("HostInt from %s. UID %d, flags %x", clntPtr->name,
		   data->uid, data->flags);
	    if (data->flags & EXPORT_SAME) {
		printf("arch = %d\n", clntPtr->arch);
	    } else {
		putc('\n', stdout);
	    }
	}
	while(1) {
	    /*
	     * Starting from the host that was last allocated, search through
	     * the list of hosts for one that the calling host may use. If
	     * none is found, ln will be NILLNODE, else it will be the Lst
	     * node containing the first host that may be given to the
	     * requesting one. We do this until we can actually
	     * contact the host we've allocated. If this takes a while,
	     * the requesting agent and the client will both hang.
	     */
	    struct sb sb;

	    sb.clntPtr = clntPtr;
	    sb.flags = data->flags;
	    sb.rating = 0;
	    sb.server = NULL;

	    /*
	     * Use Lst_FindFrom since Lst_ForEachFrom doesn't go
	     * round a circular list. MCAAvailHost just never "finds" the
	     * node for which we're "looking"
	     */
	    (void)Lst_FindFrom (allHosts, Lst_Succ(lastAlloc),
			        (ClientData)&sb, MCAAvailHost);

	    if (sb.server == NULL) {
		if (verbose) {
		    printf("\tno host available\n");
		}
		permit.addr.s_addr = htonl(INADDR_ANY);
		permit.id = 0;
		break;
	    } else {
		struct sockaddr_in  victim; /* Address of victim */
		Rpc_Stat  	    stat;   /* Result of call */
		AllocReply  	    reply;
		
		servPtr = sb.server;
		lastAlloc = Lst_Member(allHosts, (ClientData)servPtr);
		if (verbose) {
		    printf ("%s given to %s for uid %d\n", servPtr->name,
			    clntPtr->name, uid);
		}
		permit.addr = servPtr->addr;
		permit.id = (nextID++ & 0xffff) | (uid << 16);

		/*
		 * Before we reply to the requesting server, we must tell the
		 * victim what a lucky machine it is...
		 */
		allocPermit.addr = clntPtr->addr;
		allocPermit.id = permit.id;
		victim.sin_family = AF_INET;
		victim.sin_port = htons(udpPort);
		victim.sin_addr = servPtr->addr;
		
		stat = Rpc_Call(udpSocket, &victim, (Rpc_Proc)CUSTOMS_ALLOC,
				sizeof(allocPermit),
				(Rpc_Opaque)&allocPermit,
				sizeof(reply),
				(Rpc_Opaque)&reply,
				CUSTOMSINT_NRETRY, &retryTimeOut);
		if (stat != RPC_SUCCESS) {
		    /*
		     * OOPS. Mark the host down and try again...
		     */
		    if (verbose) {
			printf("OOPS: %s down (%s) -- looping\n",
				servPtr->name, Rpc_ErrorMessage(stat));
		    }
		    servPtr->avail = AVAIL_DOWN;
		} else {
		    servPtr->avail = reply.avail;
		    servPtr->rating = reply.rating;
		    break;
		}
	    }
	}
    }
    Rpc_Return(msg, sizeof(permit), (Rpc_Opaque)&permit);
}

/*-
 *-----------------------------------------------------------------------
 * MCARegister --
 *	Register a machine as serving a set of hosts. The data buffer
 *	looks like this:
 *	<server-name>\0+<arch><number-of-clients><client-1>\0<client-2>\0...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A record is created for the host, if one doesn't exist. Its
 *	list of clients is set to contain the records for the hosts it
 *	will serve, unless it will serve the single host ALL, in which
 *	case the clients list is set to NILLST to signal its availability
 *	to all hosts.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
MCARegister (from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    char    	  	*data;	    /* Registration buffer */
{
    int	    	  numClients;	    /* Number of clients agent will handle */
    ServerPtr	  servPtr;  	    /* Record for registering agent */
    ServerPtr	  clntPtr;  	    /* Record for client agent will handle */
    register int  i;
    register char *buf;
    long    	  *lp;
    

    Rpc_Return(msg, 0, (Rpc_Opaque)0);

    /*
     * Make sure the call comes from another agent -- if not, ignore it.
     *
     * XXX: Should also allow limiting to a group of addresses or networks.
     */
    if (ntohs(from->sin_port) != udpPort) {
	time_t	now;

	time(&now);
	printf("Register from %d@%s -- %s", ntohs(from->sin_port),
	       InetNtoA(from->sin_addr), ctime(&now));
	return;
    }
    
    /*
     * Find and create a record for the agent, leaving it in servPtr
     */
    servPtr = MCAFindHostAddr(from, data, TRUE);
    
    buf = data;
	
    /*
     * If the agent was registered before, nuke any previous list of clients
     * before creating a new one
     */
    if (servPtr->clients != NILLST) {
	Lst_Destroy (servPtr->clients, NOFREE);
    }
    servPtr->clients = Lst_Init (TRUE);
	
    if (verbose) {
	printf ("Register %s: ", servPtr->name);
    }

    Log_Send(LOG_NEWAGENT, 1, xdr_sockaddr_in, from);

    /*
     * The number of clients is stored on a 32-bit boundary, so put buf at the
     * next one beyond the machine name string (being sure to include at least
     * one null in our calculations) and extract the number of clients.
     */
    buf += strlen(buf)+1;
    lp = Customs_Align(buf, long *);
    servPtr->arch = *lp++;
    
    numClients = *lp++;

    buf = (char *)lp;

    if (verbose) {
	printf ("%d clients (", numClients);
    }
    if (numClients == 1 && strcmp (buf, "ALL") == 0) {
	/*
	 * If there's only one client given and it is ALL, then guess what?
	 * the server will accept connections from all hosts.
	 */
	Lst_Destroy (servPtr->clients, NOFREE);
	servPtr->clients = NILLST;
	if (verbose) {
	    printf ("ALL clients)\n");
	}
    } else {
	/*
	 * Go through the buffer picking out the host names and adding them
	 * as clients of the server.
	 */
	for (i = numClients; i != 0; i--) {
	    clntPtr = MCAFindHost (buf, TRUE);
	    buf += strlen (buf) + 1;
	    
	    if (clntPtr != (ServerPtr)NULL) {
		if (verbose) {
		    printf ("%s%s", clntPtr->name, i != 1 ? "," : ")\n");
		}
		Lst_AtEnd (servPtr->clients, (ClientData)clntPtr);
	    }
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * MCAInfo --
 *	Provide allocation and registration information...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The info is sent as a reply.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
MCAInfo (from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    Rpc_Opaque 	  	data;
{
    LstNode 	     	ln;
    register ServerPtr 	servPtr;
    ServerPtr	  	clntPtr;
    int	    	  	i;
    char    	  	info[MAX_INFO_SIZE];
    register char 	*cp;

    /*
     * The information about all the hosts is stored in the 'info' buffer
     * in the following format:
     *	<number-of-hosts>   	integer
     *	<host1>	  	    	{
     *	    	  	    	    name (rounded to next 32-bit boundary)
     *	    	  	    	    availability
     *	    	    	    	    availability index
     *				    architecture
     *	    	  	    	    number of clients (0 if ALL)
     *	    	  	    	    indices of clients (0..numClients)
     *	    	  	    	}
     *     .
     *     .
     *     .
     *	<host-n>  	    	ditto
     *	<last-allocated>    	integer (index of host last allocated)
     *
     * Due to the variable size of the host names and client lists, this
     * is not really amenable to a one-dimensional C structure, so...
     */
    cp = info;
    *(int *)cp = Lst_Length(allHosts);
    cp += sizeof(int);
    if (Lst_Open(allHosts) == FAILURE) {
	Rpc_Error(msg, RPC_SYSTEMERR);
	return;
    }
    for (ln=Lst_Next(allHosts); !Lst_IsAtEnd(allHosts); ln=Lst_Next(allHosts)){
	int  	nameLen;
	
	/*
	 * First copy the name (the size of which is rounded up to the
	 * next 32-bit boundary)
	 */
	servPtr = (ServerPtr)Lst_Datum(ln);

	/*
	 * Check for buffer overflow
	 */
	if (sizeof(info) < cp - info
		+ strlen(servPtr->name) + sizeof(long) /* name + align */
		+ 3 * sizeof(long)	/* avail + rating + arch */
		+ sizeof(int)		/* numclients */
		+ (servPtr->clients == NILLST ? 0
			: sizeof(int) * Lst_Length(servPtr->clients))
					/* clients indices */	)
	{
	    Lst_Close(allHosts);
	    printf ("Reginfo exceeds max RPC data size");
	    Rpc_Error(msg, RPC_TOOBIG);
	    return;
	}

	strcpy(cp, servPtr->name);
	cp += strlen(servPtr->name) + 1;
	cp = Customs_Align(cp, char *);
	
	*(long *)cp = servPtr->avail;
	cp += sizeof(long);
	*(long *)cp = servPtr->rating;
	cp += sizeof(long);
	
	*(long *)cp = servPtr->arch;
	cp += sizeof(long);

	if (servPtr->clients != NILLST) {
	    /*
	     * Stuff the number of clients served into the buffer and
	     * pass down the list, storing the index of each client in
	     * turn.
	     */
	    *(int *)cp = Lst_Length(servPtr->clients);
	    cp += sizeof(int);
	    if (Lst_Open(servPtr->clients) == FAILURE) {
		Rpc_Error(msg, RPC_SYSTEMERR);
		return;
	    }
	    for (ln = Lst_Next(servPtr->clients);
		 !Lst_IsAtEnd(servPtr->clients);
		 ln = Lst_Next(servPtr->clients)) {
		     clntPtr = (ServerPtr)Lst_Datum(ln);
		     *(int *)cp = Lst_Index(allHosts,
					    (ClientData)clntPtr);
		     cp += sizeof(int);
	    }
	    Lst_Close(servPtr->clients);
	} else {
	    /*
	     * 0 clients served => all clients served
	     */
	    *(int *)cp = 0;
	    cp += sizeof(int);
	}
    }
    Lst_Close(allHosts);

    /*
     * Find last-allocated host and store its index
     */
    servPtr = (ServerPtr)Lst_Datum(lastAlloc);
    *(int *)cp = Lst_Index(allHosts, (ClientData)servPtr);
    cp += sizeof(int);
    Rpc_Return(msg, cp - info, (Rpc_Opaque)info);
}


/*-
 *-----------------------------------------------------------------------
 * MCANewMasterResponse --
 *	Handle a response to a NEWMASTER broadcast. Doesn't do anything
 *	except return True.
 *
 * Results:
 *	True.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static Boolean
MCANewMasterResponse(from, len, data)
    struct sockaddr_in	*from;
    int	    	  	len;
    Rpc_Opaque 	  	data;
{
    if (ntohs(from->sin_port) != udpPort) {
	/*
	 * Ignore response if not from offical port
	 */
	return(False);
    } else {
	return (True);
    }
}
/*-
 *-----------------------------------------------------------------------
 * MCABoast --
 *	Tell the world we're the master agent. The call is sent out at
 *	random times between five and ten minutes apart to deal with
 *	network partitions. Registration is a fairly lightweight
 *	operation, so five-to-ten minutes seems like a reasonable
 *	interval.
 *
 * Results:
 *	False (don't stay awake)
 *
 * Side Effects:
 *	The event we're given is reset for a random time between five and
 *	ten minutes away.
 *	
 *-----------------------------------------------------------------------
 */
static Boolean
MCABoast(data, ev)
    Rpc_Opaque	    data;   	/* Data stored (Nothing) */
    Rpc_Event	    ev;	    	/* Event that called us */
{
    struct timeval  again;  	/* Time at which to broadcast again */
    struct sockaddr_in broadcast;  /* Address to which to broadcast */

    broadcast.sin_family = AF_INET;
    broadcast.sin_port = htons(udpPort);
    broadcast.sin_addr.s_addr = htonl(INADDR_ANY);
    
    /*
     * Let the world know we consider ourselves the master.
     */
    (void)Rpc_Broadcast(udpSocket, &broadcast,
			(Rpc_Proc)CUSTOMS_NEWMASTER,
			sizeof(elect_Token), (Rpc_Opaque)&elect_Token,
			0, (Rpc_Opaque)0,
			CUSTOMSINT_NRETRY, &retryTimeOut,
			MCANewMasterResponse, (Rpc_Opaque)0);

    if (boastEvent != NULL) {
	/*
	 * Pick a random time between five and ten minutes from now at which
	 * to broadcast again. Note the conditional on boastEvent still
	 * being non-null. This is to handle getting a NEWMASTER call ourselves
	 * during the broadcast.
	 */
	again.tv_sec = (random() % 300) + 300;
	again.tv_usec = (random() % 1000000);

	Rpc_EventReset(ev, &again);
    }

    return(False);
}
/*-
 *-----------------------------------------------------------------------
 * MCA_Init --
 *	Initialize things as the master agent.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Loads.
 *
 *-----------------------------------------------------------------------
 */
void
MCA_Init ()
{
    ServerPtr	    clntPtr;
    register int    numC;
    register char   **c;
    struct timeval  junk;   /* Timeval needed for creating the boastEvent. */
    
    allHosts = Lst_Init (TRUE);

    us = MCAFindHost (localhost, TRUE);
    us->addr = localAddr.sin_addr;
    us->arch = arch;

    if (numClients != 1 || strcmp (clients[0], "ALL") != 0) {
	us->clients = Lst_Init (FALSE);
	c = clients;
	for (numC = numClients; numC != 0; numC--, c++) {
	    clntPtr = MCAFindHost (*c, TRUE);
	    if (clntPtr != (ServerPtr)NULL) {
		Lst_AtEnd (us->clients, (ClientData) clntPtr);
	    }
	}
    } else {
	us->clients = NILLST;
    }

    lastAlloc = Lst_First(allHosts);

    /*
     * Register the services we as the master will perform.
     */
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_AVAIL, MCAAvail,
		     Swap_AvailInt, Rpc_SwapNull, (Rpc_Opaque)TRUE);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_HOSTINT, MCA_HostInt,
		     Swap_Host, Swap_ExportPermit, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_REG, MCARegister,
		     Swap_RegPacket, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_INFO, MCAInfo,
		     Rpc_SwapNull, Swap_Info, (Rpc_Opaque)0);
    /*
     * Create an event for sending out a period NEWMASTER call (see below).
     * The time doesn't matter since MCABoast will reset the thing right
     * away.
     */
    junk.tv_sec = junk.tv_usec = 1;
    boastEvent = Rpc_EventCreate(&junk, MCABoast, (Rpc_Opaque)NULL);

    /*
     * Dispatch initial NEWMASTER call. The idea is to send out NEWMASTER
     * broadcasts and regular, though random, intervals to handle the
     * resolution of a network partition -- if you have two masters on
     * the net, when the first one sends out the NEWMASTER call, the second
     * will cancel its master automatically, while all the agents that
     * had the second agent listed as the master will register with the first.
     */
    MCABoast(NULL, boastEvent);
}

/*-
 *-----------------------------------------------------------------------
 * MCAFreeServer --
 *	Free a server description.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The data for the given server is freed.
 *
 *-----------------------------------------------------------------------
 */
static void
MCAFreeServer(servPtr)
    ServerPtr	  servPtr;
{
    free(servPtr->name);
    if (servPtr->downEvent) {
	Rpc_EventDelete(servPtr->downEvent);
    }
    if (servPtr->clients != NILLST) {
	Lst_Destroy(servPtr->clients, NOFREE);
    }
    free((char *)servPtr);
}

/*-
 *-----------------------------------------------------------------------
 * MCA_Cancel --
 *	Stop acting as the MCA. Involves destroying our records and
 *	unregistering our master services.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	All the data on the allHosts list are freed.
 *
 *-----------------------------------------------------------------------
 */
void
MCA_Cancel()
{
    Lst_Destroy(allHosts, MCAFreeServer);
    
    Rpc_ServerDelete(udpSocket, (Rpc_Proc)CUSTOMS_AVAIL);
    Rpc_ServerDelete(udpSocket, (Rpc_Proc)CUSTOMS_HOSTINT);
    Rpc_ServerDelete(udpSocket, (Rpc_Proc)CUSTOMS_REG);
    Rpc_ServerDelete(udpSocket, (Rpc_Proc)CUSTOMS_INFO);

    Rpc_EventDelete(boastEvent);

    boastEvent = (Rpc_Event)NULL;
}
