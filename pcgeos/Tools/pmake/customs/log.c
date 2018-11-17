/*-
 * log.c --
 *	Functions to talk to a logging server via udp RPC.
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
"$Id: log.c,v 1.6 89/11/14 13:46:09 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customsInt.h"
#include    "log.h"
#include    <varargs.h>

static Boolean	    	    logServer;
static struct sockaddr_in   logServerAddr;
static int  	  	    numFails;

#define NUM_FAILS_ALLOWED   3	/* Number of failures allowed before log
				 * server is evicted */
/*-
 *-----------------------------------------------------------------------
 * Log_Send --
 *	Send a message to the log server. Encodes the arguments using
 *	XDR functions and sends an RPC call on the log socket.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	logServer will be set FALSE if an error occurs.
 *
 *-----------------------------------------------------------------------
 */
/*VARARGS2*/
void
Log_Send (procNum, pieces, va_alist)
    Rpc_Proc   	  	    procNum;  	/* Procedure to call for log server */
    int	    	  	    pieces; 	/* Number of pieces of data to
					 * encode */
    va_dcl
{
    XDR	    	  	    stream;   	/* Memory stream for encoding */
    va_list 	  	    args;    	/* Var for accessing arguments */
    xdrproc_t	  	    encode;   	/* Function to encode data */
    caddr_t 	  	    data;    	/* Data to encode */
    char    	  	    logBuf[MAX_DATA_SIZE];
    int	  	  	    len;	/* Length of encoded data */

    if (logServer) {
	xdrmem_create (&stream, logBuf, sizeof(logBuf), XDR_ENCODE);

	/*
	 * Encode each piece of data using the xdr function given for it.
	 */
	va_start(args);
	while (pieces--) {
	    encode = va_arg(args, xdrproc_t);
	    data = va_arg(args, caddr_t);
	    if (!(*encode) (&stream, data)) {
		logServer = FALSE;
		return;
	    }
	}
	va_end (args);

	/*
	 * All pieces now encoded, send the buffer off to the server using
	 * the standard, short, internal timeout and resend values.
	 */
	len = XDR_GETPOS(&stream);
	if (Rpc_Call(udpSocket, &logServerAddr, procNum,
		     len, (Rpc_Opaque)logBuf,
		     0, (Rpc_Opaque)0,
		     CUSTOMSINT_NRETRY, &retryTimeOut) != RPC_SUCCESS)
	{
	    if (--numFails == 0) {
		logServer = FALSE;
	    }
	} else {
	    numFails = NUM_FAILS_ALLOWED;
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * LogStart --
 *	Start up a log connection with another process.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Of course.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
LogStart(from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    Boolean 	  	*data;	    /* TRUE if should evict previous server */
{
    if (logServer) {
	if (len != sizeof(Boolean)) {
	    Rpc_Error(msg, RPC_BADARGS);
	} else if (! *data) {
	    Rpc_Error(msg, RPC_ACCESS);
	    return;
	} else {
	    Rpc_Return(msg, 0, (Rpc_Opaque)0);
	    Log_Send(LOG_EVICT, 1, xdr_sockaddr_in, from);
	}
    } else {
	Rpc_Return(msg, 0, (Rpc_Opaque)0);
    }
    logServer = TRUE;
    logServerAddr = *from;
    numFails = NUM_FAILS_ALLOWED;
}

/*-
 *-----------------------------------------------------------------------
 * Log_Init --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
void
Log_Init()
{
    logServer = FALSE;
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_LOG, LogStart,
		     Rpc_SwapLong, Rpc_SwapNull, (Rpc_Opaque)0);
}
