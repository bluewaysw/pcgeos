/*-
 * avail.c --
 *	Functions to check the status of the local machine to see
 *	if it can accept processes.
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
"$Id: avail.c,v 1.20 89/11/14 13:45:53 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customsInt.h"
#include    <stdio.h>

static unsigned long   	maxLoad = 0.5 * LOADSCALE;
static int  	  	minSwapFree=25;	/* 75% used swap => not available */
static int  	  	minIdle=15*60;	/* Keyboard must have been idle at
					 * least 15 minutes (when this is
					 * 15 * 60)... */
static int  	  	maxImports = 2;	/* Largest number of imported jobs */

static Rpc_Event  	availEvent;	/* Event for checking availability */
static struct timeval	availInterval;	/* Interval at which checks should
					 * be made for the availability of
					 * this host. */
static int  	    	availCheck;  	/* Mask of criteria to examine */
int	    	    	avail_Bias; 	/* Bias for rating calculation */

/*-
 *-----------------------------------------------------------------------
 * Avail_Send --
 *	Send the availability of the local host.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An availability packet is sent to the master.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Avail_Send ()
{
    Avail   	  avail;
    static int	  sending = 0;	    /* XXX: A kludge to prevent endless
				     * recursion. At times, for no reason I've
				     * been able to determine, the avail event
				     * will be triggered during the call to
				     * CUSTOMS_AVAIL (hard to believe since
				     * the timeout for the avail event is
				     * twice as long as the total for the
				     * rpc, but...). Once it starts, it
				     * continues and the calls never seem to
				     * complete. To prevent this, we use a
				     * static flag and don't send anything
				     * if a call is already being sent. */
    if (sending) {
	return(FALSE);
    } else {
	sending = 1;
    }
    
    avail.addr =  	localAddr.sin_addr;
    avail.interval = 	availInterval;
    avail.avail = 	Avail_Local(AVAIL_EVERYTHING, &avail.rating);

    if (verbose) {
	printf ("Localhost %s available\n", avail.avail ? "not" : "is");
	fflush(stdout);
    }

    if (!Elect_InProgress() &&
	(Rpc_Call(udpSocket, &masterAddr, (Rpc_Proc)CUSTOMS_AVAIL,
		  sizeof(avail), (Rpc_Opaque)&avail,
		  0, (Rpc_Opaque)0,
		  CUSTOMSINT_NRETRY, &retryTimeOut) != RPC_SUCCESS)) {
		      Elect_GetMaster();
    }
    sending = 0;
    return (FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * AvailSet --
 *	Set the availability criteria. Returns an OR of bits if the
 *	parameters are out-of-range.
 *
 * Results:
 *	Any of AVAIL_IDLE, AVAIL_SWAP, AVAIL_LOAD and AVAIL_IMPORTS
 *	or'ed together (or 0 if things are ok).
 *
 * Side Effects:
 *	The availabilty criteria are altered.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
AvailSet (from, msg, len, adPtr, fromRemote)
    struct sockaddr_in	*from;	    /* Address of sender */
    Rpc_Message	  	msg;	    /* Message for return */
    int	    	  	len;	    /* Length of criteria */
    Avail_Data	  	*adPtr;	    /* New criteria */
    Boolean 	  	fromRemote; /* TRUE if from remote call */
{
    int	    	  result;

    if (!Local(from)) {
	Rpc_Error(msg, RPC_ACCESS);
    } else if (len != sizeof(Avail_Data)) {
	Rpc_Error(msg, RPC_BADARGS);
    } else {
	/*
	 * Bounds-check the passed parameters, setting bits in result to
	 * correspond to bad values.
	 */
	result = 0;
	if ((adPtr->changeMask & AVAIL_IDLE) && (adPtr->idleTime > MAX_IDLE)) {
	    result |= AVAIL_IDLE;
	}
	if ((adPtr->changeMask & AVAIL_SWAP) && (adPtr->swapPct > MAX_SWAP)) {
	    result |= AVAIL_SWAP;
	}
	if ((adPtr->changeMask & AVAIL_LOAD) &&
	    (adPtr->loadAvg < MIN_LOAD) &&
	    (adPtr->loadAvg != 0))
	{
	    result |= AVAIL_LOAD;
	}
	if ((adPtr->changeMask & AVAIL_IMPORTS) &&
	    (adPtr->imports < MIN_IMPORTS) &&
	    (adPtr->imports != 0))
	{
	    result |= AVAIL_IMPORTS;
	}
	if (result == 0) {
	    /*
	     * Everything ok -- change what needs changing.
	     */
	    if (adPtr->changeMask & AVAIL_IDLE) {
		minIdle = adPtr->idleTime;
	    }
	    if (adPtr->changeMask & AVAIL_SWAP) {
		minSwapFree = adPtr->swapPct;
	    }
	    if (adPtr->changeMask & AVAIL_LOAD) {
		maxLoad = adPtr->loadAvg;
	    }
	    if (adPtr->changeMask & AVAIL_IMPORTS) {
		maxImports = adPtr->imports;
	    }
	}
	/*
	 * Set return value: changeMask gets error bits. the other fields get
	 * the current criteria.
	 */
	adPtr->changeMask = result;
	adPtr->idleTime = minIdle;
	adPtr->swapPct = minSwapFree;
	adPtr->loadAvg = maxLoad;
	adPtr->imports = maxImports;

	/*
	 * Only send a reply if the call was actually remote (it's not
	 * when called from main...)
	 */
	if (fromRemote) {
	    Rpc_Return(msg, len, (Rpc_Opaque)adPtr);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * AvailSetInterval --
 *	Alter the interval at which availability checks are made.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The interval in availInterval is changed and availEvent is altered
 *	to reflect this change.
 *
 *-----------------------------------------------------------------------
 */
static void
AvailSetInterval (from, msg, len, intervalPtr)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    struct timeval	*intervalPtr;
{
    if (!Local(from)) {
	Rpc_Error(msg, RPC_ACCESS);
    } else if (len != sizeof(struct timeval)) {
	Rpc_Error(msg, RPC_BADARGS);
    } else if (intervalPtr->tv_sec < 5) {
	Rpc_Error(msg, RPC_BADARGS);
    } else {
	availInterval = *intervalPtr;
	Rpc_EventReset(availEvent, &availInterval);
	Rpc_Return(msg, 0, (Rpc_Opaque)0);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Avail_Init --
 *	Initialize things for here...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	We exit if can't initialize.
 *
 *-----------------------------------------------------------------------
 */
void
Avail_Init(criteria, checkTime)
    Avail_Data	  *criteria;	    /* Initial criteria */
    int	    	  checkTime;	    /* Initial check interval */
{
    availInterval.tv_sec = checkTime ? checkTime : 10;
    availInterval.tv_usec = 0;

    availCheck = OS_Init();
    
    availEvent = Rpc_EventCreate(&availInterval, Avail_Send, (Rpc_Opaque)0);
	
    Rpc_ServerCreate(udpSocket, CUSTOMS_AVAILINTV, AvailSetInterval,
		     Swap_Timeval, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, CUSTOMS_SETAVAIL, AvailSet,
		     Swap_Avail, Swap_Avail, (Rpc_Opaque)TRUE);
	
    AvailSet(&localAddr, (Rpc_Message)0, sizeof(Avail_Data), criteria,
	     FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * Avail_Local --
 *	See if the local host is available for migration
 *
 * Results:
 *	0 if it is, else one of the AVAIL bits indicating which criterion
 *	wasn't satisfied.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Avail_Local(what, ratingPtr)
    int	    what; 	/* Mask of things to check */
    long    *ratingPtr;	/* Place to store rating of current availabilty */
{
    /*
     * Mask out bits the OS module says it can't check.
     */
    what &= availCheck;
    /*
     * Start the rating out with the bias factor. The bias is intended for
     * situations where certains machines are noticeably faster than others
     * and are to be prefered even if the two appear to be loaded the same.
     */
    *ratingPtr = avail_Bias;
    
    /*
     * If an minimum idle time was specified, check to make sure the
     * keyboard idle time exceeds that.
     */
    if ((what & AVAIL_IDLE) && minIdle) {
	int idleTime = OS_Idle();

	if (idleTime < minIdle) {
	    if (verbose) {
		printf ("Only %d seconds idle (%d min)\n",
			idleTime, minIdle);
		fflush(stdout);
	    }
	    return AVAIL_IDLE;
	}
	*ratingPtr += idleTime - minIdle;
    }

    /*
     * Either the machine has been idle long enough or the user didn't
     * specify an idle time, so now, if the user gave a free swap space
     * percentage beyond which the daemon may not go, tally up the total
     * free blocks in the swap map and see if it's too few.
     */
    if ((what & AVAIL_SWAP) && minSwapFree) {
	int swapPct = OS_Swap();
	
	if (swapPct < minSwapFree) {
	    if (verbose) {
		printf ("Only %d%% free swap blocks\n", swapPct);
		fflush(stdout);
	    }
	    return AVAIL_SWAP;
	}
	*ratingPtr += swapPct - minSwapFree;
    }

    /*
     * So far so good. Now if the user gave some maximum load average (note
     * that it can't be 0) which the daemon may not exceed, check all three
     * load averages to make sure that none exceeds the limit.
     */
    if ((what & AVAIL_LOAD) && maxLoad > 0) {
	unsigned long	load = OS_Load();

	if (load > maxLoad) {
	    if (verbose) {
		printf ("load: %f\n", (double) load/FSCALE);
	    }
	    return AVAIL_LOAD;
	}
	*ratingPtr += maxLoad - load;
    }

    /*
     * Reduce the rating proportional to the amount of work we've accepted if
     * we're not completely full. We weight this heavily in an attempt
     * to avoid double allocations by the master (by changing the rating
     * drastically, we hope to shift the focus to some other available machine)
     */
    if ((what & AVAIL_IMPORTS) && maxImports && (Import_NJobs() >= maxImports))
    {
	return AVAIL_IMPORTS;
    }
    *ratingPtr -= Import_NJobs() * 200;

    /*
     * Great! This machine is available.
     */
    return 0;
}
