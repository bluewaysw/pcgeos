/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Communications.
 * FILE:	  rpc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 19, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Rpc_Call  	    Call a procedure on the PC
 *	Rpc_Init  	    Initialize stuff for a patient
 *	Rpc_ServerCreate    Create a server for a patient
 *	Rpc_ServerDelete    Delete a server for a patient
 *	Rpc_EventCreate	    Create a timeout event
 *	Rpc_EventDelete	    Delete a timeout event
 *	Rpc_EventResetb	    Reset the interval and timeout for an event
 *	Rpc_Watch 	    Pay attention to a stream
 *	Rpc_Ignore	    Ignore a stream
 *	Rpc_Error 	    Return an error to the PC
 *	Rpc_Return	    Return data to the PC
 *	Rpc_Abort   	    Abort all pending calls
 *	Rpc_Wait  	    Wait for something to happen
 *	Rpc_Run	  	    Wait for something to happen indefinitely
 *	Rpc_Debug 	    Turn debugging for module on/off
 *	Rpc_ErrorMessage    Return a description of an error status
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/19/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	The functions in this module implement the RPC protocol
 *	used for communication with the GEOS debugging stub.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: rpc.c,v 4.50 97/12/11 09:48:02 cthomas Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "file.h"
#include "geos.h"
#include "handle.h"
#include "rpc.h"
#include "type.h"
#include "ui.h"
#include "value.h"
#include "var.h"
#include "objfmt.h"
#include "gc.h"
#include <compat/file.h>
#if defined(_WIN32)
# include <winutil.h>
# include <conio.h>
#endif

#include <ctype.h>

#define abort std_abort
#include <compat/stdlib.h>
#undef abort

/*
 * Conditionally swap a shortword (only if the external variable 'swap' is
 * true)
 */
#define swaps(s) (swap ? ((s & 0xff) << 8) | ((s >> 8) & 0xff) : s)

/*
 * The RPC mechanism implemented in this file was designed for the customs
 * agent and has been adapted to the RPC protocol used for communication
 * with the PC GEOS debugging stub. For now, it supports only communication
 * over a single serial line.
 *
 * A server is created for any procedure  procNum  using the function
 * Rpc_ServerCreate(procNum, handleProc, argsType, replyType, handleData).
 * The handler function may be called at any time, even while a
 * call is being made, so handlers should be written
 * accordingly. argsType and replyType are Type descriptions formed by
 * the Type module that are used to byte-swap the arguments and reply IN PLACE
 * should the PC have a different byte order. All byte-swapping is handled
 * on this end, rather than burdening the PC with it, even though it has
 * nothing better to do and can do it in three instructions. If no data are
 * passed and/or returned, or swapping isn't necessary, type_Byte should be
 * given.
 *
 * The system is organized around an event queue and select masks. Events
 * occur at scheduled times with the process sleeping in between events by
 * waiting on a set of streams, as defined by the select masks. Multiple calls
 * may be pending -- each one has an event for resending and replies are
 * handled by the selection mechanism. The event queue is ordered by timeout
 * time. The function Rpc_Wait is what processes the queue and calls the
 * various handlers.
 *
 * Each stream may have only one function to handle its readiness. Thus a
 * program should not express interest in the stream unless it has unregistered
 * interest in all rpc services on that stream.
 *
 * <procNum, message-id> is an ordered pair that uniquely
 * identifies a given RPC call. This pair is used for caching calls and
 * responses to them.
 *
 * The protocol relies on the acknowledgement implicit in the return of
 * data. Every service routine must call Rpc_Return() at least once, even
 * if no data are to be returned. The only time an explicit acknowledgement
 * packet is sent is when a duplicate call is received for one that is
 * currently being processed. The acknowledgement indicates that the client
 * is to continue waiting and resending at whatever interval it chooses.
 *
 * Outgoing data are byte-swapped using the Var module, given a type
 * description
 */

#if defined(unix)
# include <sys/ioctl.h>
# include <sys/types.h>
# include <sys/file.h>
# include <sys/uio.h>
# include <sys/signal.h>
#endif

#if defined(_WIN32)
# undef FIXED
# undef LONG
# define LONG LONG_biff
# define SID SID_biff
# define timeval timeval_biff
# undef timercmp
# define timercmp timercmp_biff
# define fd_set fd_set_biff
# include <compat/windows.h>
# undef fd_set
# undef timercmp
# undef timeval
# undef SID
# undef LONG
# define FIXED 0x80
# undef sleep
# define sleep(s) (Sleep((s) * 1000))
# include <curses.h>
extern HANDLE hConIn;
#endif

#include "netware.h"
#include <errno.h>

#if defined(_WIN32)
# include <io.h>
# include <sys/stat.h>

void RpcExitNtSerial(void);

#endif

#if defined(_MSDOS)
# include <stat.h>
# include <bios.h>
#endif

#if defined(_MSDOS)
# include "serial.h"
#elif defined(_WIN32)
# include "ntserial.h"
#endif

#if defined(_MSDOS) || defined(_WIN32)
typedef long    fd_mask;
# define NBBY    8               /* number of bits in a byte */

# if CLOCKS_PER_SEC < 1000000
#  define timertoclock(tvp)    (((tvp)->tv_sec * CLOCKS_PER_SEC) + \
			      ((tvp)->tv_usec / (1000000/CLOCKS_PER_SEC)))
# else
#  define timertoclock(tvp)    (((tvp)->tv_sec * CLOCKS_PER_SEC) + \
			      (((tvp)->tv_usec * CLOCKS_PER_SEC)/1000000))
# endif
#endif

# define FD_SETSIZE  256	/* Make sure this is big enough for both */
				/* Sun and ISI... */

/* fd stuff exists in winsock.h for _WIN32, but isn't compatible */
#if defined(_MSDOS) || defined(_WIN32)
# define NFDBITS (sizeof (fd_mask) * NBBY)       /* bits per mask */
# define howmany(x, y)   (((x)+((y)-1))/(y))
typedef struct fd_set {
        fd_mask fds_bits[howmany(FD_SETSIZE, NFDBITS)];
} fd_set;
# define FD_SET(n, p)   ((p)->fds_bits[(n)/NFDBITS] |= (1 << ((n) % NFDBITS)))
# define FD_CLR(n, p)   ((p)->fds_bits[(n)/NFDBITS] &= ~(1 << ((n) % NFDBITS)))
# define FD_ISSET(n, p) ((p)->fds_bits[(n)/NFDBITS] & (1 << ((n) % NFDBITS)))
# define FD_ZERO(p)     bzero((char *)(p), sizeof (*(p)))
#endif

#include <stdio.h>
#include "safesjmp.h"

extern int  	    attached;	    /* Set in ibm.c; non-zero if actually
				     * in contact with the PC. All RPC's fail
				     * if this is FALSE */
extern int  	    tryingToAttach; /* Set in ibm.c; from Ibm_Connect */

int	  	    commMode = CM_NONE;   /* type of comm.,
					   * eg. serial, netw, dde
					   */
static int          keyboardFD = 0;
static int  	    geosFD = -1;    /* serial or netware file descriptor */
#if defined(_MSDOS) || defined(_WIN32)
static int  	    mouseFD = -1;
#endif

#if 0
static Type 	    typeRpcHeader;
#endif /* 0 */
Rpc_Stat	    rpc_LastError;  /* Last error from Rpc_Call */

#define timeadd(tv1,tv2,tvd) \
/*struct timeval *tv1, *tv2, *tvd;*/ \
{\
    (tvd)->tv_usec = (tv1)->tv_usec + (tv2)->tv_usec;\
    if ((tvd)->tv_usec >= 1000000) {\
	(tvd)->tv_sec = (tv1)->tv_sec + (tv2)->tv_sec + 1;\
	(tvd)->tv_usec -= 1000000;\
    } else {\
	(tvd)->tv_sec = (tv1)->tv_sec + (tv2)->tv_sec;\
    }\
}

/*
 * The ID of a message is simply an unsigned long that increments for each
 * message.
 */
typedef byte RpcID;
#define RpcIDEqual(id1, id2)	(id1 == id2)
#define RpcHash(id)	    	(((id) ^ (id >> 3)) & (CACHE_THREADS-1))

/*
 * RPC CACHE DEFINITIONS
 */
/*
 * The cache is kept as a table of doubly-linked lists, hashed on the ID of the
 * message, hanging from the RpcServer structure for the procedure call. The
 * 'prev' pointer of the first entry in the chain points to the pointer in
 * the table for that chain (i.e. *e->prev == e). Cache entries are flushed 10
 * seconds after their last reference.
 *
 * A cache entry may be in one of two states: replied-to or reply-pending.
 * If a call comes in that maps to an entry for which a reply is still
 * pending, an RPC_ACKNOWLEDGE message is returned, informing the caller that
 * the call is still in progress.
 *
 * If a call comes in that maps to an entry that has been replied-to, the
 * reply is resent and the call dropped.
 */
typedef struct CacheEntry {
    enum {
	REPLY_PENDING,	    	    	/* Service of call is in progress */
	REPLY_SENT,	    	    	/* Reply has been sent already */
    }	    	  	status;	    /* Status of call */
    RpcID   	  	id; 	    /* ID of call */
    Rpc_Event	  	flushEvent; /* Event to flush cache entry */
    Rpc_Stat	  	error;	    /* If not RPC_SUCCESS, contains the
				     * error code returned for the call */
    Rpc_Opaque	  	replyData;  /* Data for reply */
    int	    	  	replySize;  /* Size of reply data */
    struct CacheEntry	*next;	    /* Next call in cache */
    struct CacheEntry	*prev;	    /* Previous call in cache or address of
				     * pointer to head of chain if head of
				     * chain */
} CacheEntry;

#define CACHE_THREADS	8  	/* The number of chains in each server
				 * cache. NOTE: dependence on this value
				 * in RpcHash() -- must be (2^n) */
/*
 * RPC CALL DEFINITIONS
 */
#define RpcTypeMask	    (RPC_CALL|RPC_REPLY|RPC_ERROR|RPC_ACK)
#define RpcIsCall(hdrPtr)   (((hdrPtr)->rh_flags&RpcTypeMask)==RPC_CALL)
#define RpcIsReply(hdrPtr)  (((hdrPtr)->rh_flags&RpcTypeMask)==RPC_REPLY)
#define RpcIsError(hdrPtr)  (((hdrPtr)->rh_flags&RpcTypeMask)==RPC_ERROR)
#define RpcIsAck(hdrPtr)    (((hdrPtr)->rh_flags&RpcTypeMask)==RPC_ACK)

/*
 * The RpcCall structure contains all information needed to track an RPC
 * call and its replies. It is given as the argument for RpcResend when the
 * resend timer expires.
 */
typedef struct RpcCall {
    struct RpcCall	*next;	    /* Next in chain for socket */
    RpcID   	  	id; 	    /* ID number of message */

    /*
     * Information for receiving replies
     */
    Rpc_Stat 	  	status;	    /* Status of call */
    int	    	  	replyLen;   /* Expected length of reply */
    Rpc_Opaque 	  	reply;	    /* Place to store reply data */
    Type    	  	replyType;  /* Type of reply data (for swapping) */
    Boolean    	  	replied;    /* Reply received */

    /*
     * Information for issuing the call.
     */
    int	    	  	sock;	    /* Socket over which to make the call */
    struct iovec 	message[2]; /* Outgoing message */
    int	    	  	numRetries; /* Number of resends left */
    Rpc_Event   	resend;	    /* Event used for resending */
} RpcCall;

static RpcCall	  	*rpcCalls[FD_SETSIZE];

/*
 * RPC SERVER DEFINITIONS
 */
/*
 * A service is established for a stream by linking a RpcServer structure into
 * its rpcServers list. The handler function is called when a call on the
 * procedure procNum is received over the stream.
 */
typedef struct RpcServer {
    struct RpcServer	*next;
    Rpc_Proc   	  	procNum;    		/* Procedure number */
    void    	  	(*serverProc)();    	/* Function to handle it */
    Type		argType;    	    	/* Type for swapping args */
    Type		replyType;  	    	/* Type for swapping reply */
    Rpc_Opaque 	  	data;	    	    	/* Datum to pass proc */
    CacheEntry	  	*cache[CACHE_THREADS];	/* Call cache */
} RpcServer;

/*
 * The RpcMessage structure contains all the information needed to reply to
 * an rpc call.
 */
typedef struct RpcMessage {
    RpcHeader	  	*header;    	/* Original message header */
    RpcServer		*server;	/* Server for message (so we can
					 * swap the reply) */
    CacheEntry	  	*e; 	    	/* Entry in server cache to modify */
} RpcMessage;

static RpcServer  	*rpcServers[FD_SETSIZE];

static RpcServer    	*geosServers = (RpcServer *)0;

/*
 * WAIT DEFINITIONS
 */
/*
 * RpcEvent structures are what make up the event queue (events) around which
 * this system revolves. Each has a time at which the event should occur and
 * a function to call when the event happens, along with a single piece of
 * data to be passed to the function. The event queue is time-ordered.
 */
typedef struct RpcEvent {
    struct RpcEvent  	*next;
#if defined(unix)
    struct timeval	timeout;    	/* Time at which event should occur */
    struct timeval	interval;   	/* Interval at which event should
					 * recur. */
# define etimercmp(tp1, tp2, c) timercmp(tp1, tp2, c)
#else
    clock_t 	    	timeout;    	/* Time at which event should occur */
    clock_t 		interval;   	/* Interval at which event should
					 * recur. */
# define etimercmp(tp1, tp2, c) (*(tp1) c *(tp2))
#endif
    Boolean    	  	(*eventProc)();	/* Function to be called at timeout */
    Rpc_Opaque 	  	data;	    	/* Datum to pass it */
} RpcEvent;

static RpcEvent	  	*events;    	/* All waiting events */

/*
 * The 'streams' array contains the information needed to handle the readiness
 * of a stream. The 'state' field is set from the arguments to Rpc_Watch and
 * is used to remove the stream from the select masks when interest in it
 * changes. If 'state' is 0, noone is interested in the stream.
 */
typedef struct _RpcStream {
    int	    	  	state; 	    	/* Current interest */
    void    	  	(*streamProc)(int, Opaque, int);/* Function to handle readiness */
    Rpc_Opaque 	  	data;	    	/* Datum to pass to handler */
    struct _RpcStream	*saved;	    	/* Previous saved state */
} RpcStream;

static RpcStream   	streams[FD_SETSIZE];

fd_set	    	  	rpc_readMask;	/* Readable stream select mask */
fd_set			rpc_writeMask;	/* Writable stream select mask */
fd_set			rpc_exceptMask;	/* Exceptable stream select mask */

/*
 * MISCELLANEOUS DEFINITIONS
 */
int			rpcDebug = 0;     /* Print debugging info (RD_ flags
					   * defined in rpc.h) */
#if defined(unix)
static Boolean 	    	noSig = FALSE;	/* Don't use IOT signal to keep
					 * owner of tty from dealing with it */
#endif

/*
 * Interval for flushing a call entry from the cache
 */
static struct timeval	flushTimeOut = {
    10, 0
};

static struct timeval  	defaultRetry = {
    RETRY_SEC, RETRY_USEC
};

typedef union {
    RpcHeader    	    header; /* Header for incoming message */
    byte	    	    buf[RPC_MAX_DATA];
}	    	    	RpcMessageBuf;

/*
 * Data types for our various funky calls that probably ought to be
 * someplace else... Initialized in Rpc_Init()
 */
Type   	    typeGetNextDataBlock;
Type	    typeReadGeodeArgs;
Type	    typeReadGeodeReply;
Type	    typeIndexToOffsetArgs;
Type	    typeIndexToOffsetReply;

#if defined(unix)
static char ttyName[64];
static int  isModem=0;
#elif defined(_WIN32)
# include "npipe.h"
extern HANDLE cntlcEvent;
HANDLE hCommunication = NULL;
OVERLAPPED overlapRead, overlapWrite;

static char npipeName[256];
static char ttysetting[25];

static BOOL incomingRead = FALSE;   	  /* incoming data has been read */
static CHAR incomingBuf[RPC_MAX_DATA];
static int  incomingLen = 0;
static BOOL outstandingRead = FALSE;	  /* a read attempt for incoming
					   * data read has occurred, but
					   * not completed */
#endif


/***********************************************************************
 *				RpcSendV
 ***********************************************************************
 * SYNOPSIS:	    Send data down the serial line including proper
 *	    	    framing bytes and quoting things as necessary
 * CALLED BY:	    RpcResend, RpcSend, Rpc_Return
 * RETURN:	    -1 if bytes couldn't be sent
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/91		Initial Revision
 *
 ***********************************************************************/
static void inline
RpcNewIOV(struct iovec 	**iovPtr,
	  int	    	*curIOVPtr,
	  int	    	*iovLenPtr,
	  byte	    	*base,
	  int	    	len)
{
    *curIOVPtr += 1;

    if (*curIOVPtr == *iovLenPtr) {
	*iovLenPtr *= 2;
	*iovPtr = (struct iovec *)realloc((malloc_t)(*iovPtr),
					  *iovLenPtr * sizeof(struct iovec));
    }

    (*iovPtr)[*curIOVPtr].iov_base = (caddr_t)base;
    (*iovPtr)[*curIOVPtr].iov_len = len;
}

static int
RpcSendV(int    	fd,
	 struct iovec	*iov,
	 int	    	iov_len)
{
    static unsigned char    startText[] = {
	RPC_MSG_START
    };
    static unsigned char    endText[] = {
	RPC_MSG_END
    };
    static unsigned char    quoteStart[] = {
	RPC_MSG_QUOTE, RPC_MSG_QUOTE_START
    };
    static unsigned char    quoteEnd[] = {
	RPC_MSG_QUOTE, RPC_MSG_QUOTE_END
    };
    static unsigned char    quoteQuote[] = {
	RPC_MSG_QUOTE, RPC_MSG_QUOTE_QUOTE
    };
    struct iovec    *newiov;
    int	    	    newiovlen;
    int	    	    curiov;
    int	    	    i;
    int	    	    useNextIOV;
    byte    	    checksum;
    byte      	    checksumBuf[1];
#if defined(_WIN32)
    int             bytesWritten;
#endif

    if (commMode == CM_NETWARE) {
	return (NetWare_WriteV(fd, iov, iov_len));
    }

#if defined(_WIN32)
    if (commMode == CM_NPIPE) {
	if (geosFD < 0) {
	    Boolean returnVal;

	    returnVal = Rpc_Connect();
	    if (returnVal == FALSE) {
		return (-1);
	    }
	}
	bytesWritten = NPipe_WriteV(hCommunication, iov, iov_len,
				    &overlapWrite);
	if (bytesWritten == -1) {
	    DWORD lastError;

	    if (win32dbg == TRUE) {
		char buf[1000];

		WinUtil_SprintError(buf, "NPipe_WriteV");
		MessageFlush(buf);
	    }
	    lastError = GetLastError();
	    if ((lastError == ERROR_BROKEN_PIPE)
		|| (lastError == ERROR_INVALID_HANDLE))
	    {
		Ibm_LostContact();
	    }
	}
	return bytesWritten;
    }
#endif  /* _WIN32 case */

    /*
     * Start with two more iovec's than passed, one for RPC_MSG_START, and
     * one for RPC_MSG_END and one for the checksum.
     */
    newiovlen = iov_len+3;
    newiov = (struct iovec *)malloc(newiovlen * sizeof(struct iovec));

    curiov = 0;
    newiov[curiov].iov_base = (caddr_t)startText;
    newiov[curiov].iov_len = sizeof(startText);

    checksum = 0;

    /*
     * Build up a new array of iovec structures, using the special static
     * strings where the quoting of RPC_MSG_START, RPC_MSG_QUOTE and
     * RPC_MSG_END requires it. Don't want to copy data around, you
     * know.
     */

    for (i = 0; i < iov_len; i++) {
	unsigned char	*bp;
	int    	    	len;

	useNextIOV = 1;

	for (bp = (unsigned char *)iov[i].iov_base, len = iov[i].iov_len;
	     len > 0;
	     len--, bp++)
	{
	    checksum += *bp;

	    switch(*bp) {
		case RPC_MSG_START:
		    RpcNewIOV(&newiov, &curiov, &newiovlen,
			      quoteStart, sizeof(quoteStart));
		    useNextIOV = 1;
		    break;
		case RPC_MSG_QUOTE:
		    RpcNewIOV(&newiov, &curiov, &newiovlen,
			      quoteQuote, sizeof(quoteQuote));
		    useNextIOV = 1;
		    break;
		case RPC_MSG_END:
		    RpcNewIOV(&newiov, &curiov, &newiovlen,
			      quoteEnd, sizeof(quoteEnd));
		    useNextIOV = 1;
		    break;
		default:
		    if (useNextIOV) {
			RpcNewIOV(&newiov, &curiov, &newiovlen,
				  bp, 1);
		    } else {
			/*
			 * Up the length of the current iov by one to include
			 * the current byte.
			 */
			newiov[curiov].iov_len++;
		    }
		    useNextIOV = 0;
		    break;
	    }
	}
    }

    /*
     * Negate the checksum and tack it onto the end so the sum of all the bytes
     * in the message will be 0, dealing with the checksum being one of the
     * three special bytes in our protocol.
     */
    checksumBuf[0] = ~checksum + 1;
    switch(checksumBuf[0]) {
	case RPC_MSG_START:
	    RpcNewIOV(&newiov, &curiov, &newiovlen,
		      quoteStart, sizeof(quoteStart));
	    break;
	case RPC_MSG_QUOTE:
	    RpcNewIOV(&newiov, &curiov, &newiovlen,
		      quoteQuote, sizeof(quoteQuote));
	    break;
	case RPC_MSG_END:
	    RpcNewIOV(&newiov, &curiov, &newiovlen,
		      quoteEnd, sizeof(quoteEnd));
	    break;
	default:
	    RpcNewIOV(&newiov, &curiov, &newiovlen, (byte *)&checksumBuf, 1);
	    break;
    }

    /*
     * Tack the RPC_MSG_END onto the end of things.
     */
    RpcNewIOV(&newiov, &curiov, &newiovlen,
	      endText, sizeof(endText));

    /*
     * Write the whole thing out to the port.
     */
    if (curiov+1 > 16) {
	/*
	 * SunOS has a 16-vector limit for this call, apparently...
	 */
	struct iovec	*tiov;
	int 	    	tiovlen;
	int 	    	nwritten = 0;

	for (tiov = newiov; curiov >= 0; tiov += tiovlen, curiov -= tiovlen) {
	    if (curiov+1 > 16) {
		tiovlen = 16;
	    } else {
		tiovlen = curiov+1;
	    }

#if defined(unix)
	    i = writev(fd, tiov, tiovlen);
#elif defined(_MSDOS)
	    i = Serial_WriteV(tiov, tiovlen);
#elif defined(_WIN32)
	    i = Ntserial_WriteV(hCommunication, tiov, tiovlen, &overlapWrite);
#endif
	    if (i < 0) {
#if defined(_WIN32)
		if (win32dbg == TRUE) {
		    char buf[1000];

		    WinUtil_SprintError(buf, "Ntserial_WriteV");
		    MessageFlush(buf);
		}
#endif
		nwritten = i;
		break;
	    } else {
		nwritten += i;
	    }
	}
	i = nwritten;
    } else {

#if defined(unix)
	i = writev(fd, newiov, curiov+1);
#elif defined(_MSDOS)
	i = Serial_WriteV(newiov, curiov+1);
#else defined(_WIN32)
	i = Ntserial_WriteV(hCommunication, newiov, curiov+1, &overlapWrite);
	if ((i < 0) && (win32dbg == TRUE)) {
	    char buf[1000];

	    WinUtil_SprintError(buf, "Ntserial_WriteV");
	    MessageFlush(buf);
	}
#endif
    }

    free((malloc_t)newiov);
    return(i);
}


/***********************************************************************
 *				RpcSend
 ***********************************************************************
 * SYNOPSIS:	    Send a buffer o' bytes down the line handling
 *	    	    link-level framing, etc.
 * CALLED BY:	    Rpc_Error, Rpc_Exit, Rpc_Send
 * RETURN:	    < 0 on error
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/91		Initial Revision
 *
 ***********************************************************************/
static int
RpcSend(int 	    fd,
	void	    *buf,
	unsigned    size)
{
    struct iovec    iov;

    iov.iov_base = buf;
    iov.iov_len = size;
    return(RpcSendV(fd, &iov, 1));
}


/*-
 *-----------------------------------------------------------------------
 * RpcUniqueID --
 *	Return an unique identifier for a message.
 *
 * Results:
 *	The identifier.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static RpcID
RpcUniqueID(void)
{
    static RpcID  nextID = 0;

    return (++nextID);
}

/*-
 *-----------------------------------------------------------------------
 * RpcCacheFlushEntry --
 *	Flush an entry from a server's cache when it hasn't been
 *	referenced in a while.
 *
 * Results:
 *	False -- no need to stay awake.
 *
 * Side Effects:
 *	The CacheEntry structure is removed from the server's cache
 *	and freed.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
RpcCacheFlushEntry(CacheEntry	*e, 	/* Entry to flush */
		   Rpc_Event  	ev) 	/* Event that caused this call */
{
    if (rpcDebug & RD_CACHE) {
	Message("Flushing entry for %u\n", e->id);
    }

    if (e->flushEvent != ev) {
	Warning("RpcCacheFlushEntry: flushEvent (%x) != ev (%x)\n",
		e->flushEvent, ev);
    }
    /*
     * If call still in-progress (some of our calls take a really long time
     * to process), just let the event timeout again before we flush anything.
     */
    if (e->status == REPLY_PENDING) {
	return(False);
    }

    Rpc_EventDelete(ev);
    if (*((CacheEntry **)e->prev) == e) {
	/*
	 * Head of chain: move head to next
	 */
	*((CacheEntry **)e->prev) = e->next;
    } else {
	/*
	 * Element of chain: link previous to next
	 */
	e->prev->next = e->next;
    }

    /*
     * Link next element to previous (this also sets up the prev field
     * properly if e was the head of the chain).
     */
    if (e->next != (CacheEntry *)NULL) {
	e->next->prev = e->prev;
    }
    if (e->replyData != (Rpc_Opaque)0) {
	free((char *)e->replyData);
    }
    free((char *)e);

    return (False);
}

/*-
 *-----------------------------------------------------------------------
 * RpcCacheDestroy --
 *	Clean out the cache for an RpcServer.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Frees all memory and nukes all events associated with the cache
 *	entries.
 *
 *-----------------------------------------------------------------------
 */
static void
RpcCacheDestroy(RpcServer *s)	/* The server whose cache should be destroyed */
{
    register int  	i;
    register CacheEntry	*e;

    for (i = 0; i < CACHE_THREADS; i++) {
	for (e = s->cache[i]; e != (CacheEntry *)0; e = e->next) {
	    if (e->replyData != (Rpc_Opaque)0) {
		free((char *)e->replyData);
	    }
	    Rpc_EventDelete(e->flushEvent);
	    free((char *)e);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * RpcCacheFind --
 *	Find an RPC call in a server's cache. If it's not there and
 *	create is True, the entry is created and *entryNewPtr is set
 *	True. If the entry cannot be created, or doesn't exist and
 *	create is False, NULL is returned.
 *
 * Results:
 *	The CacheEntry for the call, or NULL if none.
 *
 * Side Effects:
 *	A CacheEntry structure is created and linked into the cache
 *	for the server.
 *
 *-----------------------------------------------------------------------
 */
static CacheEntry *
RpcCacheFind(RpcServer *server,    	/* Server in whose cache the call
					 * should be sought */
	     RpcID  	id, 	    	/* ID number of the call */
	     Boolean 	create,	    	/* True if should create an entry
					 * if we don't find it */
	     Boolean 	*entryNewPtr)	/* Set True if a new entry was
					 * created */
{
    CacheEntry	    *e;
    int  	    chain;

    chain = RpcHash(id);
    e = server->cache[chain];

    /*
     * Look for existing cache entry.
     */
    if (rpcDebug & RD_CACHE) {
	Message("RpcCacheFind: seeking #%u...", id);
    }
    while (e != (CacheEntry *)0) {
	if (RpcIDEqual(id, e->id)) {
	    break;
	} else {
	    e = e->next;
	}
    }

    if (e == (CacheEntry *)NULL) {
	if (create) {
	    /*
	     * Create new entry and link it at the head of its chain,
	     * setting *entryNewPtr as necessary.
	     */
	    if (rpcDebug & RD_CACHE) {
		Message("creating new entry\n");
	    }
	    e = (CacheEntry *)malloc_tagged(sizeof(CacheEntry), TAG_RPC);
	    e->id = 	    id;
	    e->status =     REPLY_PENDING;
	    e->flushEvent = Rpc_EventCreate(&flushTimeOut,
					    (Boolean (*)(void *, void *))RpcCacheFlushEntry,
					    (Rpc_Opaque)e);
	    e->error =	    RPC_SUCCESS;
	    e->replyData =  (Rpc_Opaque)0;
	    e->replySize =  0;

	    e->next =	    server->cache[chain];
	    e->prev =	    (CacheEntry *)&server->cache[chain];
	    server->cache[chain] = e;
	    if (e->next != (CacheEntry *)NULL) {
		e->next->prev = e;
	    }

	    if (entryNewPtr != (Boolean *)NULL) {
		*entryNewPtr = True;
	    }
	} else {
	    if (rpcDebug & RD_CACHE) {
		Message("returning NULL\n");
	    }
	    return ((CacheEntry *)NULL);
	}
    } else if (entryNewPtr != (Boolean *)NULL) {
	/*
	 * No new entry created -- mark *entryNewPtr false to indicate this
	 */
	if (rpcDebug & RD_CACHE) {
	    Message("found it\n");
	}
	*entryNewPtr = False;
    }

    /*
     * The entry was referenced, so reset the flush timer for it. Check
     * for null because Rpc_Broadcast uses a cache and biffs the flush
     * events for each entry in the cache.
     */
    if (e->flushEvent) {
	Rpc_EventReset(e->flushEvent, &flushTimeOut);
    }
    return (e);
}

#if defined(unix)

/*-
 *-----------------------------------------------------------------------
 * RpcCheckStreams --
 *	Check the set of watched streams for bad ones and remove them from
 *	the set. Called by Rpc_Wait when an EBADF error is returned from
 *	select().
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The state field of any bad stream is set to 0 and the stream removed
 *	from all bit masks.
 *
 *-----------------------------------------------------------------------
 */
static void
RpcCheckStreams(void)
{
    register int  	stream;

    /*
     * For each stream that someone is interested in, do an innocuous lseek
     * on it. If the lseek returns an EBADF error, the descriptor is bad, so
     * we clear it out of all the select masks and set its state to 0. Note
     * that if the stream is unseekable, we'll get an EINVAL error, not EBADF.
     */
    for (stream=0; stream < FD_SETSIZE; stream++) {
	if (streams[stream].state) {
	    errno = 0;

	    if ((lseek(stream, 0, L_INCR) < 0) &&
		(errno == EBADF))
	    {
		if (rpcDebug & RD_STREAM) {
		    Message("%d bad -- flushing\n", stream);
		}
		FD_CLR(stream, &rpc_readMask);
		FD_CLR(stream, &rpc_writeMask);
		FD_CLR(stream, &rpc_exceptMask);
		streams[stream].state = 0;
	    }
	}
    }
}
#endif   /* unix */

#if DEBUG_OUTPUT_RPC_DATA_TO_FILE
/* Routines to dump the raw packet information to a file called C:\rpcfile.txt */
static FILE *rpcfile = NULL;
void DebugRpcReceived(RpcMessageBuf *p_msg)
{
    int i ;

    if (rpcfile == NULL)  {
        rpcfile = fopen("c:\\rpcfile.txt", "w") ;
    }

    fprintf(rpcfile, "recv %d (proc %d) [%d] :", p_msg->header.rh_id, p_msg->header.rh_procNum, p_msg->header.rh_length) ;
    for (i=0; i<p_msg->header.rh_length; i++)
        fprintf(rpcfile, " %02X", p_msg->buf[sizeof(p_msg->header)+i]) ;
    fprintf(rpcfile, "\n") ;
    fflush(rpcfile) ;
}

void DebugRpcCall(RpcCall *p_call)
{
    RpcHeader *p_header ;
    int i ;
    unsigned char *p_data ;

    if (rpcfile == NULL)  {
        rpcfile = fopen("c:\\rpcfile.txt", "w") ;
    }

    p_header = (RpcHeader *)p_call->message[0].iov_base ;
    p_data = (unsigned char *)p_call->message[1].iov_base ;
    i = p_call->message[1].iov_len ;

    fprintf(rpcfile, "call %d (proc %d) [%d]:", p_header->rh_id, p_header->rh_procNum, i) ;
    for (; i; i--)
        fprintf(rpcfile, " %02X", *(p_data++)) ;
    fprintf(rpcfile, "\n") ;
    fflush(rpcfile) ;
}
#else
#define DebugRpcReceived(msg)  ((void)0)
#define DebugRpcCall(p_call)   ((void)0)
#endif  /* DEBUG_OUTPUT_RPC_DATA_TO_FILE */



/***********************************************************************
 *				RpcProcessMessage
 ***********************************************************************
 * SYNOPSIS:	Process a complete message received from the PC
 * CALLED BY:	RpcHandleStream
 * RETURN:	nothing
 * SIDE EFFECTS:?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/12/91		Initial Revision
 *
 ***********************************************************************/
static void
RpcProcessMessage(int		stream,
		  RpcMessageBuf	*messagePtr,
		  int		msgLen)
{
    if (messagePtr->header.rh_length + sizeof(RpcHeader) != msgLen) {
	if (rpcDebug & RD_PACKET) {
	    Message("short message received. is %d bytes, s/b %d bytes\n",
		    msgLen, messagePtr->header.rh_length + sizeof(RpcHeader));
	}
	return;
    }

    if (RpcIsCall(&messagePtr->header)) {
	/*
	 * Find server and call out.
	 */
	register RpcServer  *server;
	RpcMessageBuf	    message;
	RpcMessage	    msg;
	CacheEntry	    *e;
	Boolean		    isNew;


	/*
	 * Locate the server for the call so we can search its cache for
	 * the call being already active.
	 */
	for (server = rpcServers[stream];
	     (server != (RpcServer *)0) &&
	     (server->procNum != messagePtr->header.rh_procNum);
	     server = server->next)
	{
	    ;
	}
	msg.header = &messagePtr->header;

	if (server == (RpcServer *)0) {
	    if (rpcDebug & RD_SERVE) {
		Message("%u: no such procedure\n",
			messagePtr->header.rh_procNum);
	    }
	    msg.server = 0;
	    msg.e = 0;
	    Rpc_Error((Rpc_Message)&msg, RPC_NOPROC);
	    return;
	}

	msg.e =
	    e = RpcCacheFind(server, messagePtr->header.rh_id, True, &isNew);

	/*
	 * XXX: Should do more error checking (e.g. does length match?).
	 * ID in sequence?
	 */
	msg.server = server;
	msg.header = &messagePtr->header;

	if (isNew) {
	    /*
	     * Must copy the passed message to local space in case the server
	     * needs to call something, which could well overwrite the global
	     * message buffer...
	     */
	    message = *messagePtr;
	    msg.header = &message.header;

	    if (rpcDebug & RD_SERVE) {
		Message("Call on %d: id %u procedure %d\n",
			stream,
			message.header.rh_id,
			message.header.rh_procNum);
	    }

	    /*
	     * Check their byte-order against ours and call the swap procedure
	     * if it's not the same.
	     */
	    if (swap && !Type_IsNull(server->argType)) {
		Var_SwapValue(VAR_FETCH, server->argType,
			      message.header.rh_length,
			      (genptr)&message.buf[sizeof(RpcHeader)]);
	    }

	    (*server->serverProc)((Rpc_Message)&msg,
				  message.header.rh_length,
				  (Rpc_Opaque)&message.buf[sizeof(RpcHeader)],
				  server->data);
	    /*
	     * Make sure the server generated some reply. If not, generate
	     * a null-reply. Note we don't do this for broadcast messages
	     * as they only get explicit replies -- the server may just have
	     * decided the message wasn't really for it. Broadcasts are
	     * rather general, after all.
	     */
	    if (e->status != REPLY_SENT) {
		Message("No reply sent for call %u to procedure %d on %d\n",
			message.header.rh_id,
			message.header.rh_procNum,
			stream);
		Message("Generating zero-length reply...\n");
		Rpc_Return((Rpc_Message)&msg, 0, (Rpc_Opaque)NULL);
	    }
	} else if (e->status == REPLY_PENDING) {
	    /*
	     * This call is already being serviced. Drop it on the floor --
	     * the stub will resend forever anyway.
	     */
	    if (rpcDebug & (RD_SERVE|RD_CACHE)) {
		Message("Call on %d: id %u procedure %d\n\tdropped because "
			"call already in progress\n",
			stream, messagePtr->header.rh_id,
			messagePtr->header.rh_procNum);
	    }
	} else if (e->error == RPC_SUCCESS) {
	    if (rpcDebug & (RD_CACHE|RD_SERVE)) {
		Message("%d byte reply cached: resending\n",
			e->replySize);
	    }
	    Rpc_Return((Rpc_Message)&msg, e->replySize, e->replyData);
	} else {
	    if (rpcDebug & (RD_CACHE|RD_SERVE))	 {
		Message("error %d cached: resending\n", e->error);
	    }
	    Rpc_Error((Rpc_Message)&msg, e->error);
	}
    } else {
	/*
	 * It's a reply of some sort. Find the associated call...
	 */
	register RpcCall    *call;
	register RpcCall    **prev;

	if (rpcDebug & RD_CALL) {
	    Message ("Reply to %u: ", messagePtr->header.rh_id);
	}

	prev = &rpcCalls[stream];
	for (call = rpcCalls[stream]; call != (RpcCall *)0; call = call->next){
	    if (RpcIDEqual(messagePtr->header.rh_id, call->id)) {
		break;
	    } else {
		prev = &call->next;
	    }
	}
	if (call != (RpcCall *)0) {
	    switch (messagePtr->header.rh_flags & RpcTypeMask) {
		case RPC_REPLY:
		    /*
		     * The message is a real reply.
		     *
		     * If the returned data are too big for the buffer the
		     * caller passed, drop the packet and signal an RPC_TOOBIG
		     * error.
		     *
		     * Else, copy the returned data to the buffer supplied by
		     * the caller and mark the call as successful.
		     */
		    if (messagePtr->header.rh_length > call->replyLen) {
			call->status = RPC_TOOBIG;
			if (rpcDebug & RD_CALL) {
			    Message("too big, %d bytes instead of %d bytes\n",
				    	messagePtr->header.rh_length,
				    	call->replyLen);
			}
		    } else {
			if (messagePtr->header.rh_length != 0) {
			    bcopy ((char *)(messagePtr->buf+sizeof(RpcHeader)),
				   (char *)call->reply,
				   messagePtr->header.rh_length);
			}
                        DebugRpcReceived(messagePtr) ;
			if (swap && !Type_IsNull(call->replyType)) {
			    /*
			     * Byte swap the reply
			     */
			    Var_SwapValue(VAR_FETCH,
					  call->replyType,
					  messagePtr->header.rh_length,
					  (genptr)call->reply);
			}

			if (rpcDebug & RD_CALL) {
			    Message ("%d bytes received\n",
				    messagePtr->header.rh_length);
			}
			call->status = RPC_SUCCESS;
		    }
		    break;
		case RPC_ERROR:
		    /*
		     * The message is an error reply. The data for the message
		     * are the return status for the call and we copy it
		     * directly into call->status.
		     */
		    call->status=
			*(Rpc_Stat *)&messagePtr->buf[sizeof(RpcHeader)];
		    if (rpcDebug & RD_CALL) {
			Message ("error %d\n", call->status);
		    }
		    break;
		case RPC_ACK:
		    /*
		     * Server is acknowledging our call. Up the number of
		     * retries allowed for the call once for each
		     * acknowledegment received. This effectively forgets
		     * we ever resent the request.
		     */
		    if (rpcDebug & RD_CALL) {
			Message ("ACK\n");
		    }
		    call->numRetries += 1;
		    return;
		default:
		    if (rpcDebug & RD_CALL) {
			Message("bogus message received on %d\n", stream);
		    }
		    return;
	    }
	    /*
	     * Cleanup: If the message got a real reply, (RPC_REPLY or
	     * RPC_ERROR), we'll get down here. We first remove the call
	     * from the list of those pending, then mark the message as
	     * replied-to and save the remote address.
	     */
	    *prev = call->next;
	    call->replied = True;
	} else {
	    if (rpcDebug & RD_CALL) {
		Message("no such message queued\n");
	    }
	}
    }
}

#if !defined(_MSDOS)
/*********************************************************************
 *			Rpc_RsCommon
 *********************************************************************
 * SYNOPSIS: start up Geos on the remote PC
 * CALLED BY:	main
 * RETURN:  nothing
 * SIDE EFFECTS: starts up Geos on the remote PC
 * STRATEGY: send the magic sequence to the swat stub
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/ 7/92		Initial version
 *
 *********************************************************************/
void
Rpc_RsCommon(char c)
{
    char	startBuf[4];

    /*
     * Not possible if using network to debug.
     */
    if (commMode == CM_NETWARE) {
	return;
    }

    startBuf[0] = 0x1b; /* escape character */
    startBuf[1] = 'R';
    startBuf[2] = 'S';
    startBuf[3] = c;
    RpcSend(geosFD, startBuf, 4);
}

/*********************************************************************
 *			Rpc_Rs
 *********************************************************************
 * SYNOPSIS: start up Geos on the remote PC
 * CALLED BY:	main
 * RETURN:  nothing
 * SIDE EFFECTS: starts up Geos on the remote PC
 * STRATEGY: send the magic sequence to the swat stub
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/ 7/92		Initial version
 *
 *********************************************************************/
void
Rpc_Rs(void)
{
    Rpc_RsCommon(0x20);
}

/*********************************************************************
 *			Rpc_Rss
 *********************************************************************
 * SYNOPSIS: start up Geos on the remote PC
 * CALLED BY:	main
 * RETURN:  nothing
 * SIDE EFFECTS: starts up Geos on the remote PC
 * STRATEGY: send the magic sequence to the swat stub
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/ 7/92		Initial version
 *
 *********************************************************************/
void
Rpc_Rss(void)
{
    Rpc_RsCommon(0x21);
}

/*********************************************************************
 *			Rpc_Rsn
 *********************************************************************
 * SYNOPSIS: start up Geos on the remote PC
 * CALLED BY:	main
 * RETURN:  nothing
 * SIDE EFFECTS: starts up Geos on the remote PC
 * STRATEGY: send the magic sequence to the swat stub
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/ 7/92		Initial version
 *
 *********************************************************************/
void
Rpc_Rsn(void)
{
    Rpc_RsCommon(0x22);
}

/*********************************************************************
 *			Rpc_Rssn
 *********************************************************************
 * SYNOPSIS: start up Geos on the remote PC
 * CALLED BY:	main
 * RETURN:  nothing
 * SIDE EFFECTS: starts up Geos on the remote PC
 * STRATEGY: send the magic sequence to the swat stub
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/ 7/92		Initial version
 *
 *********************************************************************/
void
Rpc_Rssn(void)
{
    Rpc_RsCommon(0x23);
}

#endif  /* !_MSDOS */

/*-
 *-----------------------------------------------------------------------
 * RpcHandleStream --
 *	Handle incoming data on an rpc stream, be it a call or a reply.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If it is a call, the appropriate server function is called. If
 *	it is a reply, the replied, remote and status fields of the
 *	RpcCall structure for the call are altered and the RpcCall
 *	structure removed from the list of calls for the socket.
 *
 *-----------------------------------------------------------------------
 */

#define RPC_STATE_SYNC	    1
#define RPC_STATE_QUOTE	    2
#define RPC_STATE_BASE	    3

static RpcMessageBuf	rpcMsg;
static int		rpcMsgLen = 0;	  /* Length of actual message */
static int		rpcState = RPC_STATE_SYNC;

/*ARGSUSED*/
static void
RpcHandleStream(int	    stream, /* Stream that's ready */
		Rpc_Opaque  data,   /* Data we stored (UNUSED) */
		int	    what)   /* What it's ready for (UNUSED) */
{
    byte		*bp;
    int			bytesRead;
#if defined(_WIN32)
    DWORD		numRead;
#endif

    /*
     * If waiting for RPC_MSG_START, make sure we read at the start of the
     * buffer...
     */
    if (rpcState == RPC_STATE_SYNC) {
	rpcMsgLen = 0;
    }
    bp = &rpcMsg.buf[rpcMsgLen];

    errno = 0;

    /*
     * If debugging over the net, go read the entire packet and process it.
     */
    switch(commMode) {
    case CM_SERIAL:
    {

#if defined(unix)
	bytesRead = read(stream, bp, 1);
#elif defined(_MSDOS)
	bytesRead = Serial_Read(bp, 1);
#elif defined(_WIN32)
	if (outstandingRead == TRUE) {
	    WaitForSingleObject(overlapRead.hEvent, INFINITE);
	    GetOverlappedResult(hCommunication, &overlapRead,
				&numRead, FALSE);
	    incomingLen = numRead;
	    outstandingRead = FALSE;
	    incomingRead = TRUE;
	}
	if (incomingRead == TRUE) {
	    bcopy(incomingBuf, bp, incomingLen);
	    incomingBuf[0] = '\0';
	    bytesRead = incomingLen;
	    incomingRead = FALSE;
	} else {
	    bytesRead = Ntserial_Read(hCommunication, bp, 1,
				      &overlapRead, TRUE);
	}
#endif

	if (bytesRead == 1) {
	    if ((rpcState != RPC_STATE_SYNC) || (*bp == RPC_MSG_START)) {
		/*
		 * We're either actively reading a message, or we just got
		 * the start-of-message byte from the line.
		 */
		switch (*bp) {
		case RPC_MSG_START:
		    /*
		     * Start of a new message. Reset things, setting rpcMsgLen
		     * to 0 in case we were previously in the middle of
		     * a message whose RPC_MSG_END we lost.
		     */
		    rpcState = RPC_STATE_BASE;
		    rpcMsgLen = 0;
		    break;
		case RPC_MSG_END:
		{
		    /*
		     * Message complete, in theory. Go process the thing. Place
		     * the receiver machine in SYNC state in case message is
		     * a call and we end up back at Rpc_Wait before we get
		     * back here...
		     */
		    byte    checksum;
		    byte    *end;

		    rpcState = RPC_STATE_SYNC;
		    end = &rpcMsg.buf[rpcMsgLen];

		    checksum = 0;
		    for (bp = &rpcMsg.buf[0]; bp < end; bp++)
		    {
			checksum += *bp;
		    }
		    if (checksum == 0) {
			/* rpcMsgLen-1 b/c message doesn't include checksum */
			RpcProcessMessage(stream, &rpcMsg, rpcMsgLen-1);
		    } else if (rpcDebug & RD_PACKET) {
			Message("message checksum (%02xh) non-zero\n",
				checksum);
		    }
		    break;
		}
		case RPC_MSG_QUOTE:
		    /*
		     * Beginning of two-byte quoted sequence. Valid only
		     * in base message state. If received any other time,
		     * then message corrupt, so resynch.
		     */
		    if (rpcState == RPC_STATE_BASE) {
			rpcState = RPC_STATE_QUOTE;
		    } else {
			rpcState = RPC_STATE_SYNC;
		    }
		    break;
		case RPC_MSG_QUOTE_QUOTE:
		    /*
		     * Special meaning in QUOTE state, being the quote
		     * byte itself. If not in QUOTE state, leave
		     * as-is.
		     */
		    if (rpcState == RPC_STATE_QUOTE) {
			*bp = RPC_MSG_QUOTE;
			rpcState = RPC_STATE_BASE;
		    }
		    rpcMsgLen++;
		    break;
		case RPC_MSG_QUOTE_START:
		    /*
		     * Special meaning in QUOTE state, being RPC_MSG_START.
		     * If not in QUOTE state, leave as-is.
		     */
		    if (rpcState == RPC_STATE_QUOTE) {
			*bp = RPC_MSG_START;
			rpcState = RPC_STATE_BASE;
		    }
		    rpcMsgLen++;
		    break;
		case RPC_MSG_QUOTE_END:
		    /*
		     * Special meaning in QUOTE state, being RPC_MSG_END.
		     * If not in QUOTE state, leave as-is.
		     */
		    if (rpcState == RPC_STATE_QUOTE) {
			*bp = RPC_MSG_END;
			rpcState = RPC_STATE_BASE;
		    }
		    rpcMsgLen++;
		    break;
		default:
		    if (rpcState != RPC_STATE_BASE) {
			/*
			 * Must be in quote state where only above three
			 * bytes are valid. Packet is bad, so resynch.
			 */
			rpcState = RPC_STATE_SYNC;
		    } else {
			/*
			 * Byte already in the buffer, so advance our counter.
			 */
			rpcMsgLen++;
		    }
		    break;
		}
		/*
		 * If buffer now full, packet must be bad,
		 * so drop it and resynch.
		 */
		if (rpcMsgLen == RPC_MAX_DATA) {
		    rpcState = RPC_STATE_SYNC;
		}
	    } else {
#if defined(_WIN32)
		if (win32dbg == TRUE) {
		    MessageFlush("<bad byte=%x>", (*bp)&255);
		}
#endif
	    }
	}
#if !defined(_MSDOS)   /* Can't happen in the DOS version */
	else
	{
	    /* Incomplete read */
# if defined(_WIN32)
	    if (bytesRead == -1) {
# else
		/*
		 * errno is set to 0 at the start, so if it's non-zero now,
		 * there was an error in the reading, not just an end-of-file
		 */
	    if (errno != 0) {
		extern char *sys_errlist[];
		MessageFlush("RpcHandleStream: read: %s\n",
			     sys_errlist[errno]);
# endif
	    } else {
		/*
		 * If we received an end-of-file, we assume the service
		 * is at an end and close the thing down...Any pending
		 * calls are marked timed out, since we won't be able to
		 * receive any replies on this stream.
		 */
		register RpcServer	*s;
		register RpcCall	*c;

		Message("Incomplete message received (%d bytes)\n",
			rpcMsgLen);

		if (rpcDebug & RD_STREAM) {
		    Message("EOF on %d -- closing\n", stream);
		}

		for (s = rpcServers[stream];
		     s != (RpcServer *)0;
		     s = rpcServers[stream])
		{
			rpcServers[stream] = s->next;
			free((char *)s);
		}

		for (c = rpcCalls[stream];
		     c != (RpcCall *)0;
		     c = rpcCalls[stream])
		{
		    c->replied = True;
		    c->status = RPC_TIMEDOUT;
		    rpcCalls[stream] = c->next;
		}

		Rpc_Ignore(stream);
# if !defined(_WIN32)
		(void) close(stream);
# else
		Ntserial_Exit(&hCommunication, &overlapRead, &overlapWrite);
# endif
	    }
	}
#endif       /* ends the !MSDOS */
	break;
    }
    case CM_NETWARE:
	rpcMsgLen = NetWare_Read(stream, &rpcMsg.buf,
				 sizeof(rpcMsg.buf));
	if (rpcMsgLen != 0) {
	    RpcProcessMessage(stream, &rpcMsg, rpcMsgLen);
	}
	break;
#if defined(_WIN32)
    case CM_NPIPE:
	if (outstandingRead == TRUE) {
	    WaitForSingleObject(overlapRead.hEvent, INFINITE);
	    GetOverlappedResult(hCommunication, &overlapRead,
				&numRead, FALSE);
	    incomingLen = numRead;
	    outstandingRead = FALSE;
	    incomingRead = TRUE;
	}
	if (incomingRead == TRUE) {
	    bcopy(incomingBuf, rpcMsg.buf, incomingLen);
	    rpcMsgLen = incomingLen;
	    RpcProcessMessage(stream, &rpcMsg, rpcMsgLen);
	    incomingRead = FALSE;
	} else {
	    if (geosFD < 0) {
		(void)Rpc_Connect();
	    }
	    rpcMsgLen = NPipe_Read(hCommunication,
				   &rpcMsg.buf,
				   sizeof(rpcMsg.buf),
				   &overlapRead, TRUE);
	    if (rpcMsgLen > 0) {
		RpcProcessMessage(stream, &rpcMsg, rpcMsgLen);
	    } else if (rpcMsgLen == -1) {
		DWORD lastError;

		if (win32dbg == TRUE) {
		    char buf[1000];

		    WinUtil_SprintError(buf, "NPipe_Read");
		    MessageFlush(buf);
		}
		lastError = GetLastError();
		if ((lastError == ERROR_BROKEN_PIPE)
		|| (lastError == ERROR_INVALID_HANDLE))
		{
		    Ibm_LostContact();
		}
	    }
	}
	break;
#endif
    default:
	assert(0);
	break;
    }
}

/*-
 *-----------------------------------------------------------------------
 * RpcResend --
 *	(Re)Send a call to an rpc server. If numRetries is 0, aborts the
 *	call with an RPC_TIMEDOUT error.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The replied and status fields of the RpcCall structure for the
 *	call may be altered and the RpcCall structure removed from the
 *	list of pending calls.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
RpcResend(Rpc_Opaque	clientData,	/* Record for message to be sent */
	  Rpc_Event	event)		/* UNUSED */
{
    register RpcCall	*c;	    /* Current call in list */
    register RpcCall	**prev;	    /* Pointer to next field of previous call*/
    int			numBytes;   /* Number of bytes in message */
    Rpc_Stat		status;	    /* Status of call */
    RpcHeader		*header;    /* Header of message being resent (for
				     * debug output) */
    RpcCall		*call;	    /* Record for message to be sent */

    if (clientData < (Rpc_Opaque)&status) {
	Warning("RpcResend: call is below current stack, deleting event %x\n",
		event);
	Rpc_EventDelete(event);
	return (FALSE);
    }
    call = (RpcCall *)clientData;

    if (call->sock > 32) {
	Warning("Invalid call (sock = %d), deleting event %x\n", call->sock,
		event);
	Rpc_EventDelete(event);
	return (FALSE);
    }

    header = (RpcHeader *)call->message[0].iov_base;
    status = RPC_SUCCESS;	    /* Assume success */

    if (!call->replied) {
	if (rpcDebug & RD_CALL) {
	    Message("Resending %u (proc %d): ", call->id, header->rh_procNum);
	}
	if (call->numRetries != 0) {
	    call->numRetries -= 1;
	    if (rpcDebug & RD_CALL) {
		Message("%d left\n", call->numRetries);
	    }
	    do {
		numBytes = RpcSendV(call->sock, call->message, 2);
	    } while ((numBytes < 0) && (errno == EINTR));

	    if (numBytes < 0) {
		if (rpcDebug & (RD_CALL|RD_STREAM)) {
		    extern char *sys_errlist[];
		    MessageFlush("RpcResend: writev: %s\n",
				 sys_errlist[errno]);
		}
		status = RPC_CANTSEND;
	    } else {
		status = RPC_SUCCESS;
	    }
	} else if (!(rpcDebug & RD_NO_TIMEOUT)) {
	    if (rpcDebug & RD_CALL) {
		Message("TIMEOUT\n");
	    }
	    status = RPC_TIMEDOUT;
	}
	if (status != RPC_SUCCESS) {
	    /*
	     * If the resend was unsuccessful, mark the call as replied-to and
	     * install the status as the response. Then remove the call from
	     * the list of calls pending for the socket and tell Rpc_Wait not
	     * to go to sleep so the message sender can be woken up as soon as
	     * possible
	     */
	    call->replied = True;
	    call->status = status;

	    prev = &rpcCalls[call->sock];
	    for (c = rpcCalls[call->sock]; c != (RpcCall *)0; c = c->next) {
		if (c == call) {
		    break;
		} else {
		    prev = &c->next;
		}
	    }
	    if (c != (RpcCall *)0) {
		*prev = c->next;
	    }
	    return (True);
	} else {
	    /*
	     * Tell Rpc_Wait it's ok to go to sleep, if it wants to. Nothing
	     * interesting will happen for this call until a response comes
	     * back.
	     */
	    return (False);
	}
    } else {
	/*
	 * If the message has already been replied-to, we don't want to
	 * go to sleep. Rather, Rpc_Wait should return to its caller so
	 * the message may be processed as quickly as possible.
	 */
	if(rpcDebug & RD_CALL) {
	    Message("Resend on replied-to message %u\n", call->id);
	}
	return(True);
    }
}


/*-
 *-----------------------------------------------------------------------
 * RpcQueueEvent --
 *	Place an RpcEvent on the event queue in time-order.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The events list is altered to contain the given event.
 *
 *-----------------------------------------------------------------------
 */
static void
RpcQueueEvent(register RpcEvent	*ev)
{
    register RpcEvent	*e;
    register RpcEvent	**prev;

    if (rpcDebug & RD_EVENT_QUEUE) {
#if defined(unix)
	Message ("Queueing event %xh (timeout = %d.%06d)\n", ev,
		 ev->timeout.tv_sec, ev->timeout.tv_usec);
#else
	Message ("Queueing event %xh (timeout = %u)\n", ev,
		 ev->timeout);
#endif
    }
    prev = &events;
    for (e = *prev; e != (RpcEvent *)0; e = *prev) {
	if (etimercmp(&(ev->timeout), &(e->timeout), <)) {
	    break;
	} else {
	    prev = &(e->next);
	}
    }
    ev->next = e;
    *prev = ev;
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_EventCreate --
 *	Create an event and place it on the queue of events.
 *
 * Results:
 *	An opaque whatsit to be used for deleting the event, if necessary.
 *
 * Side Effects:
 *	An RpcEvent structure is created and placed on the queue.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Event
Rpc_EventCreate(struct timeval	*interval,	/* Timeout period for event */
		Boolean		(*eventProc)(Rpc_Opaque, Rpc_Event),	/* Function to handle timeout*/
		Rpc_Opaque	data)		/* Datum to pass it */
{
    register RpcEvent	*ev;

    ev = (RpcEvent *)malloc_tagged(sizeof(RpcEvent), TAG_RPC);
#if defined(unix)
    (void)gettimeofday(&ev->timeout, (struct timezone *)0);
    timeadd(&ev->timeout,interval,&ev->timeout);
    ev->interval = *interval;
#else
    ev->interval = timertoclock(interval);
    ev->timeout = clock() + ev->interval;
#endif
    ev->eventProc = eventProc;
    ev->data = data;

    if (rpcDebug & RD_EVENT_QUEUE) {
	Message("Created event %xh\n", (unsigned int)ev);
    }
    RpcQueueEvent(ev);
    return((Rpc_Event)ev);
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_EventDelete --
 *	Remove an event from the event queue.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The given event is removed from the event queue.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_EventDelete(Rpc_Event   event)    /* Event to remove */
{
    register RpcEvent	*ev;
    register RpcEvent	*e;
    register RpcEvent	**prev;

    if (rpcDebug & RD_EVENT_QUEUE) {
	Message("Deleting event %xh...", event);
    }
    ev = (RpcEvent *)event;
    prev = &events;
    for (e = *prev; e != (RpcEvent *)0; e = *prev) {
	if (e == ev) {
	    break;
	} else {
	    prev = &e->next;
	}
    }
    if (e != (RpcEvent *)0) {
	*prev = e->next;
	if (rpcDebug & RD_EVENT_QUEUE) {
	    Message("\n");
	}
	free((char *)e);
    } else if (rpcDebug & RD_EVENT_QUEUE) {
	Message("non-existent\n");
    } else {
	Message("attempting to delete non-existent event %x\n", event);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_EventReset --
 *	Reset the time of an existing event. Event is moved to interval
 *	seconds from now.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The event is moved in the event queue.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_EventReset(Rpc_Event	event,	    /* Event to alter */
	       struct timeval	*interval)  /* New interval */
{
    register RpcEvent	*ev;
    register RpcEvent	*e;
    register RpcEvent	**prev;
#if defined(unix)
    struct timeval	now;
#endif

    if (rpcDebug & RD_EVENT_QUEUE) {
	Message("Reseting event %xh...", event);
    }
    ev = (RpcEvent *)event;
    prev = &events;

    for (e = events; e != (RpcEvent *)0; e = e->next) {
	if (e == ev) {
	    break;
	} else {
	    prev = &e->next;
	}
    }

    if (e != (RpcEvent *)0) {
	if (rpcDebug & RD_EVENT_QUEUE) {
	    Message("\n");
	}
	*prev = e->next;
    } else if (rpcDebug & RD_EVENT_QUEUE) {
	Message("nonexistent\n");
    }

#if defined(unix)
    ev->interval = *interval;
    (void)gettimeofday(&now, (struct timezone *)0);
    timeadd(&now, &ev->interval, &ev->timeout);
#else
    ev->interval = timertoclock(interval);
    ev->timeout = clock() + ev->interval;
#endif
    RpcQueueEvent(ev);
}


/*-
 *-----------------------------------------------------------------------
 * RpcWait--
 *	Wait for something to happen -- either an event to timeout or a
 *	stream to become ready. Call all appropriate handler functions
 *	and return. If poll is non-zero, select won't block, but if any
 *	streams are ready, their handlers will be called.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Events may be removed from the event queue.
 *
 *-----------------------------------------------------------------------
 */
static void
RpcWait(int poll)
{
#if defined(unix)
    struct timeval	now;		/* Current time */
    struct timeval	tv;		/* Actual interval to wait */
    struct timeval	*timeout;	/* Pointer to interval to wait */
#else
    clock_t		now;		/* Current time */
# if defined(_WIN32)
    clock_t		tv;		/* Actual interval to wait */
    DWORD		millisecs;	/* interval in milliseconds */
# endif
#endif

    register RpcEvent	*ev;		/* Current event */
    Boolean		stayAwake;	/* True if shouldn't go to sleep */
    fd_set		readMask,
			writeMask,
			exceptMask;
    int			nstreams;

#if defined(_WIN32)
    BOOL                peekResult;
    INPUT_RECORD        inputrec;
    DWORD		dWaitResult;
    DWORD               dwRead;
    DWORD		nwaits;         /* number of things to wait on */
    HANDLE		hwaits[3] = {NULL, NULL, NULL}; /* wait handles */
    DWORD		numRead;
#endif

#if defined(_MSDOS)
    Boolean		irqState;

    irqState = Ui_Interrupt();
#endif
    if (rpcDebug & RD_STREAM) {
	Message("Rpc_Wait:\n");
    }
    while (1) {
	stayAwake = False;
#if defined(unix)
	timeout = (struct timeval *)0;
#endif

	/*
	 * First handle any timeout event whose time has passed...We have
	 * to get the current time each time through because one of the event
	 * routines could have recursed and taken a long time. In such a case,
	 * when we get back to this level, we'll go to sleep for a lot longer
	 * than we really want. It's only 100 usecs per gettimeofday call,
	 * anyway...
	 */
#if !defined(unix)
# define gettimeofday(tvp, tzp)	(*(tvp) = clock())
#endif
	for (ev = events, (void)gettimeofday(&now, (struct timezone *)0);
	     (ev != (RpcEvent *)0) && etimercmp(&now, &ev->timeout, >);
	     ev = events, (void)gettimeofday(&now, (struct timezone *)0))
	{
	    events = ev->next;
	    /*
	     * Set the time for the event's recurrence. In the past
	     * this was the interval added to the timeout. This
	     * can cause the process to become swamped, however,
	     * so now add it to the current time so even if the
	     * event is taken late, it will be taken again after the
	     * given delay.
	     */
#if defined(unix)
	    timeadd(&ev->interval,&now,&ev->timeout);
#else
	    ev->timeout = now + ev->interval;
#endif

	    RpcQueueEvent(ev);
	    if (rpcDebug & RD_EVENT_TAKEN) {
#if defined(unix)
		Message("\ttaking event %xh (%d.%06d, now = %d.%06d)\n", ev,
			ev->timeout.tv_sec, ev->timeout.tv_usec,
			now.tv_sec, now.tv_usec);
#else
		Message("\ttaking event %xh (%u, now = %u)\n", ev,
			ev->timeout, now);
#endif
	    }
	    stayAwake = (*ev->eventProc) (ev->data, ev) || stayAwake;
	}
	if (stayAwake) {
	    /*
	     * If we're not to go to sleep, return to the caller.
	     */
	    if (rpcDebug & RD_STREAM) {
		Message("\tstaying awake\n");
	    }
	    return;
	}

#if defined(unix)
	if (poll) {
	    /*
	     * If just polling, timeout immediately
	     */
	    tv.tv_usec = tv.tv_sec = 0;
	    timeout = &tv;
	} else if (ev != (RpcEvent *)0) {
	    /*
	     * There's still an event pending, so figure out the time to its
	     * expiration and point 'timeout' at it.
	     */
	    tv.tv_usec = ev->timeout.tv_usec - now.tv_usec;
	    if (tv.tv_usec < 0) {
		tv.tv_usec += 1000000;
		tv.tv_sec = ev->timeout.tv_sec - now.tv_sec - 1;
	    } else {
		tv.tv_sec = ev->timeout.tv_sec - now.tv_sec;
	    }
	    timeout = &tv;
	}

	readMask = rpc_readMask;
	writeMask = rpc_writeMask;
	exceptMask = rpc_exceptMask;
	errno = 0;
	if (rpcDebug & RD_STREAM) {
	    Message("\tread(%xh), write(%xh), except(%xh)",
		    readMask.fds_bits[0],
		    writeMask.fds_bits[0],
		    exceptMask.fds_bits[0]);
	    if (timeout) {
		Message(", to(%d.%06d)\n", timeout->tv_sec, timeout->tv_usec);
	    } else {
		Message("\n");
	    }
	}
	nstreams = select(FD_SETSIZE, &readMask, &writeMask, &exceptMask,
			  timeout);
#elif defined(_MSDOS)
	/*
	 * In the DOS world, we only look for the keyboard and our serial
	 * port. There's no way to find other things being ready, so...
	 *
	 * but wait, there's more, we now have mouse support, so we must look
	 * for mouse events as well...
	 * XXX: just return everything else (except exceptMask) set?
	 */
	nstreams = 0;
	FD_ZERO(&readMask);
	FD_ZERO(&writeMask);
	FD_ZERO(&exceptMask);

	if (FD_ISSET(keyboardFD, &rpc_readMask)
	    && _bios_keybrd(_KEYBRD_READY)) {
	    nstreams += 1;
	    FD_SET(keyboardFD, &readMask);
	}
	/* now that swat can work over a network or a serial cable, we must
	 * check for either case
	 */
	if (FD_ISSET(geosFD, &rpc_readMask)
	    && ( ((commMode == CM_NETWARE) && Ipx_CheckPacket()) ||
		 ((commMode == CM_SERIAL) && Serial_Check(hCommunication)))) {
	    nstreams += 1;
	    FD_SET(geosFD, &readMask);
	}
	if ((mouseFD > 0) && (FD_ISSET(mouseFD, &rpc_readMask))) {
	    nstreams += 1;
	    FD_SET(mouseFD, &readMask);
	}
	errno = 0;
	/*
	 * If Ctrl+C typed since we started looping, break out so we can
	 * process it.
	 */
	if (Ui_Interrupt() != irqState) {
	    break;
	}
#elif defined(_WIN32)
	if (poll) {
	    /*
	     * If just polling, timeout immediately
	     */
	    tv = 0;
	} else if (ev != (RpcEvent *)0) {
	    /*
	     * There's still an event pending, so figure out the time to its
	     * expiration and point 'timeout' at it.
	     */
	    tv = ev->timeout - now;
	} else {
	    /*
	     * let's wait for ever, well 5 seconds that is
	     */
	    tv = 5000;
	}
	millisecs = (tv * (long) 1000) / CLK_TCK;

	nstreams = 0;
	FD_ZERO(&readMask);
	FD_ZERO(&writeMask);
	FD_ZERO(&exceptMask);

	nwaits = 0;
	/*
	 * check if we should wait on the keyboard
	 */
	if ((FD_ISSET(keyboardFD, &rpc_readMask)
	     || ((mouseFD > 0) && FD_ISSET(mouseFD, &rpc_readMask)))
	    && (hConIn != NULL))
	{
	    hwaits[nwaits++] = hConIn;
	}
	/*
	 * check if we should wait on the communications method, eg. npipe
	 */
	if ((geosFD >= 0) && (FD_ISSET(geosFD, &rpc_readMask))
	    && (hCommunication != NULL))
	{
	    if (incomingRead == TRUE) {
		/*
		 * if already some stuff is already read
		 */
		nstreams += 1;
		FD_SET(geosFD, &readMask);
	    } else if (outstandingRead == TRUE) {
		/*
		 * if we are already waiting on it, keep waiting
		 */
		hwaits[nwaits++] = overlapRead.hEvent;
	    } else {
		/*
		 * need to request data and wait for it
		 */
		switch(commMode) {
		case CM_NPIPE:
		    incomingLen = NPipe_Read(hCommunication,
					     incomingBuf,
					     sizeof(incomingBuf),
					     &overlapRead, FALSE);
		    if (incomingLen > 0) {
			if (GetLastError() != ERROR_IO_PENDING) {
			    /*
			     * read hasn't read ALL the data yet
			     */
			    incomingRead = TRUE;
			    outstandingRead = FALSE;
			    nstreams += 1;
			    FD_SET(geosFD, &readMask);
			} else {
			    /*
			     * ALL data is ready
			     */
			    outstandingRead = TRUE;
			}
		    } else if (incomingLen == -1) {
			/*
			 * problem - read blew up
			 */
			DWORD lastError;

			if (win32dbg == TRUE) {
			    char buf[1000];

			    WinUtil_SprintError(buf, "NPipe_Read");
			    MessageFlush(buf);
			}
			lastError = GetLastError();
			if ((lastError == ERROR_BROKEN_PIPE)
			    || (lastError == ERROR_INVALID_HANDLE))
			{
			    Ibm_LostContact();
			    goto afterRpcLoop;
			}
		    } else {
			/*
			 * incomingLen == 0; wait for data to arrive
			 */
			outstandingRead = TRUE;
			/*
			 * set the wait handle to the overlapped io event
			 */
			hwaits[nwaits++] = overlapRead.hEvent;
		    }
		    break;
		case CM_SERIAL:
		    incomingLen = Ntserial_Read(hCommunication,
						incomingBuf,
						1,
						&overlapRead,
						FALSE);
		    if (incomingLen >= 1) {
			if ((incomingLen > 1) && (win32dbg == TRUE)) {
			    MessageFlush("Ntserial_Read too much data");
			}
			/*
			 * got a byte from the serial port
			 */
			incomingRead = TRUE;
			outstandingRead = FALSE;
			nstreams += 1;
			FD_SET(geosFD, &readMask);
		    } else if (incomingLen == -1) {
			if (win32dbg == TRUE) {
			    char buf[1000];

			    WinUtil_SprintError(buf, "Ntserial_Read");
			    MessageFlush(buf);
			}
			goto afterRpcLoop;
		    } else {
			/*
			 * waiting for a byte from the serial port
			 */
			outstandingRead = TRUE;
			/*
			 * set the wait handle to the overlapped io event
			 */
			hwaits[nwaits++] = overlapRead.hEvent;
		    }
		    break;
		default:
		    Punt("Communications method is unsupported");
		}
	    }
	}

	if (nstreams == 0) {
	    /*
	     * none of the streams have data right now, so block on them all
	     */
	    hwaits[nwaits++] = cntlcEvent;
	    dWaitResult = WaitForMultipleObjects(nwaits,
						 hwaits,
						 FALSE,
						 millisecs);
	    if (dWaitResult == WAIT_FAILED) {
		Punt("WaitForMultipleObjects failed");
	    }
	    else if (dWaitResult == WAIT_TIMEOUT)
	    {
		    dWaitResult = WAIT_TIMEOUT;
	    }
	    else if ( hwaits[dWaitResult - WAIT_OBJECT_0] == hConIn ) {
		/*
		 * check the keyboard & mouse to see what input we got
		 */
		peekResult = PeekConsoleInput(hConIn, &inputrec, 1, &dwRead);
		if (peekResult == TRUE) {
		    if (dwRead > 0) {
			if (FD_ISSET(keyboardFD, &rpc_readMask)) {
			    if (((inputrec.EventType == KEY_EVENT) &&
				 (inputrec.Event.KeyEvent.bKeyDown == TRUE)) ||
				((inputrec.EventType == MOUSE_EVENT) &&
				 (inputrec.Event.MouseEvent.dwEventFlags == 0)
				 &&
			   ((inputrec.Event.MouseEvent.dwButtonState == 1) ||
			   (inputrec.Event.MouseEvent.dwButtonState == 2))))
			    {
				nstreams += 1;
				FD_SET(keyboardFD, &readMask);
			    }
			}
			if (nstreams == 0) {
			    /*
			     * need to read the input or else we'll never see
			     * the other input records
			     */
			    ReadConsoleInput(hConIn, &inputrec, 1, &dwRead);
			}
		    }
		} else {
		    Punt("Severe problem - Peek Console Input failed");
		}
	    }

	    else if ( hwaits[dWaitResult - WAIT_OBJECT_0] == overlapRead.hEvent )
	    {
		/*
		 * data came in from the overlapped io of the communication
		 * method
		 */
		if (!GetOverlappedResult(hCommunication, &overlapRead,
				    &numRead, FALSE))
		    MessageFlush("GetOverlappedResult returned FALSE\n");
		incomingLen = numRead;
		outstandingRead = FALSE;
		incomingRead = TRUE;
		nstreams += 1;
		FD_SET(geosFD, &readMask);
		if ((commMode == CM_SERIAL)
		    && (incomingBuf[0] == 0)
		    && (rpcState == RPC_STATE_SYNC))
		{
		    /*
		     * problem - wait for a tenth of a second and proceed
		     */
		    if (win32dbg == TRUE) {
			MessageFlush("Bad read over serial port\n");
		    }
		    Sleep(100);
		}
	    }

	    else if ( hwaits[dWaitResult - WAIT_OBJECT_0] == cntlcEvent )
	    {
		/*
		 * cntlc was hit - time to get outta here
		 */
		goto afterRpcLoop;
	    }
	}
#endif  /* _WIN32 */

	if (nstreams > 0) {
	    /*
	     * Something is ready. Find it and call its handler function.
	     * For each stream that's ready, we find all the things it's
	     * ready for and stick the appropriate RPC_*ABLE constants in
	     * 'what', removing the stream from the various masks as we
	     * go. The handler is called once for each ready stream.
	     * Once all the streams have been handled, we break out of the
	     * loop and return.
	     */
	    register int base;
	    fd_mask	rmask,
		wmask,
		emask;
	    register int stream;
	    register int what;
	    register fd_mask tmask;

	    if (rpcDebug & RD_STREAM) {
		printf("result:\n");
		fflush(stdout);
	    }

	    for (base = 0,
		     rmask = readMask.fds_bits[0],
		     wmask = writeMask.fds_bits[0],
		     emask = exceptMask.fds_bits[0];

		 base < sizeof(rpc_readMask.fds_bits)/sizeof(fd_mask);

		 base++,
		     rmask = readMask.fds_bits[base],
		     wmask = writeMask.fds_bits[base],
		     emask = exceptMask.fds_bits[base])
	    {
		if (rpcDebug & RD_STREAM) {
		    Message("\tread(%xh), write(%xh), except(%xh)\n",
			    rmask, wmask, emask);
		}

#define CHKSTR(n,mask,what) \
		if (!FD_ISSET((n), &(mask))) { \
	            continue; \
		}

		while(rmask) {
		    stream = ffs(rmask) - 1;
		    tmask = 1 << stream;

		    stream += base * (sizeof(fd_mask) * NBBY);

		    rmask &= ~tmask;
		    what = RPC_READABLE;

		    CHKSTR(stream, rpc_readMask, "reading");

		    if (rpcDebug & RD_STREAM) {
			Message("\t%d: read", stream);
		    }
		    if (wmask & tmask) {
			wmask &= ~tmask;

			CHKSTR(stream, rpc_writeMask, "writing");

			what |= RPC_WRITABLE;
			if (rpcDebug & RD_STREAM) {
			    Message(",write");
			}
		    }
		    if (emask & tmask) {
			emask &= ~tmask;

			CHKSTR(stream, rpc_exceptMask, "excepting");

			what |= RPC_EXCEPTABLE;
			if(rpcDebug & RD_STREAM) {
			    Message(",except");
			}

		    }
		    if (rpcDebug & RD_STREAM) {
			Message("\n");
		    }
		    (*streams[stream].streamProc) (stream,
						   streams[stream].data,
						   what);
		}
		while (wmask != 0) {
		    stream = ffs(wmask) - 1;
		    tmask = 1 << stream;
		    stream += base * (sizeof(fd_mask)*NBBY);
		    wmask &= ~tmask;
		    what = RPC_WRITABLE;

		    CHKSTR(stream, rpc_writeMask, "writing");

		    if (rpcDebug & RD_STREAM) {
			Message("\t%d: write", stream);
		    }
		    if (emask & tmask) {
			emask &= ~tmask;
			what |= RPC_EXCEPTABLE;

			CHKSTR(stream, rpc_exceptMask, "excepting");

			if (rpcDebug & RD_STREAM) {
			    Message(",except");
			}
		    }
		    if (rpcDebug & RD_STREAM) {
			Message("\n");
		    }
		    (*streams[stream].streamProc) (stream,
						   streams[stream].data,
						   what);
		}
		while (emask != 0) {
		    stream = ffs(emask) - 1;
		    tmask = 1 << stream;
		    stream += base * (sizeof(fd_mask)*NBBY);
		    emask &= ~tmask;

		    CHKSTR(stream, rpc_exceptMask, "excepting");

		    if(rpcDebug & RD_STREAM) {
			Message("\t%d:except\n", stream);
		    }
		    (* streams[stream].streamProc) (stream,
						    streams[stream].data,
						    RPC_EXCEPTABLE);
		}
	    }
	    return;
	}

#if defined(unix)
	else if (nstreams < 0) {
	    if (errno == EBADF) {
		RpcCheckStreams();
	    } else if (rpcDebug & RD_STREAM) {
		extern char *sys_errlist[];
		MessageFlush("RpcWait: select: %s\n", sys_errlist[errno]);
		if (errno == EINTR) {
		    goto afterRpcLoop;
		}
	    } else if (errno == EINTR) {
		/*
		 * If the select call was interrupted, return now. This doesn't
		 * do any harm (things generally loop on Rpc_Wait anyway) and
		 * allows the wait command to function...
		 */
		goto afterRpcLoop;
	    }
	}
#endif
    }
afterRpcLoop:
    return;
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_Wait --
 *	Wait for something to happen -- either an event to timeout or a
 *	stream to become ready. Call all appropriate handler functions
 *	and return.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Events may be removed from the event queue.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Wait(void)
{
    RpcWait(0);
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_Poll --
 *	See if anything's ready to happen and if so, make it happen. If
 *	nothing's ready, return right away.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	See RpcWait, above.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Poll(void)
{
    RpcWait(1);
}


/***********************************************************************
 *				Rpc_Push
 ***********************************************************************
 * SYNOPSIS:	    Save the current state of the passed stream for
 *	    	    later restoration by Rpc_Pop
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    stuff be allocated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/95	Initial Revision
 *
 ***********************************************************************/
void
Rpc_Push(int 	    stream) 	    	/* Stream whose state is to be saved */
{
    RpcStream	*old;

    old = (RpcStream *)malloc_tagged(sizeof(RpcStream), TAG_RPC);
    old->state = streams[stream].state;
    old->streamProc = streams[stream].streamProc;
    old->data = streams[stream].data;
    old->saved = streams[stream].saved;
    streams[stream].saved = old;
}


/***********************************************************************
 *				Rpc_Pop
 ***********************************************************************
 * SYNOPSIS:	    Restore the most-recently saved state of the passed
 *		    stream.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    TRUE if something popped.
 * SIDE EFFECTS:    the state is popped and the stream watching set
 *		    as it was when Rpc_Push was called.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/95	Initial Revision
 *
 ***********************************************************************/
Boolean
Rpc_Pop(int 	    stream)
{
    RpcStream	*old;

    old = streams[stream].saved;
    if (old != 0) {
	streams[stream].saved = old->saved;

	if (old->state) {
	    Rpc_Watch(stream, old->state, old->streamProc, old->data);
	} else {
	    Rpc_Ignore(stream);
	}
	free((char *)old);
	return (TRUE);
    } else {
	return (FALSE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_Watch--
 *	Pay attention to the state of the given stream. Any previous
 *	handler/state is overridden.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The data for 'streams[sock]' is altered. rpc_readMask,
 *	rpc_writeMask and rpc_exceptMask may be changed.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Watch(int		stream,		    /* Stream to observe */
	  int		state,		    /* State to watch for */
	  void		(*streamProc)(int, Opaque, int),    /* Function to call when state
					     * acheived */
	  Rpc_Opaque	data)		    /* Datum to pass it */
{
    /*
     * This used to print out who was trying to watch the thing, but the ISI
     * compiler is kind of tricky, so don't bother.
     */
    if (stream >= FD_SETSIZE) {
	Message("Trying to watch stream %d\n", stream);
	return;
    }

    if (streams[stream].state != 0) {
	FD_CLR(stream, &rpc_readMask);
	FD_CLR(stream, &rpc_writeMask);
	FD_CLR(stream, &rpc_exceptMask);
    }
    streams[stream].state = state;
    streams[stream].streamProc = streamProc;
    streams[stream].data = data;
    if (state & RPC_READABLE) {
	FD_SET(stream, &rpc_readMask);
    }
    if (state & RPC_WRITABLE) {
	FD_SET(stream, &rpc_writeMask);
    }
    if (state & RPC_EXCEPTABLE) {
	FD_SET(stream, &rpc_exceptMask);
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Ignore --
 *	Ignore the state of the given stream.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The stream is removed from all the select masks.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Ignore(int	  stream)	/* Stream to ignore */
{
    streams[stream].state = 0;
    FD_CLR(stream, &rpc_readMask);
    FD_CLR(stream, &rpc_writeMask);
    FD_CLR(stream, &rpc_exceptMask);
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Error --
 *	Generate an error response for an RPC call.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An error packet is sent if the call wasn't a broadcast.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Error(Rpc_Message	rpcMsg,	    /* Message to respond to */
	  Rpc_Stat	stat)	    /* Status to return */
{
    register RpcMessage	*realMsg = (RpcMessage *)rpcMsg;
    RpcMessageBuf	reply;

    if (rpcDebug & RD_SERVE) {
	Message("error code %d, procedure %d, id %u\n",
	       stat, realMsg->header->rh_procNum,
	       realMsg->header->rh_id);
    }
    reply.header.rh_id =	realMsg->header->rh_id;
    reply.header.rh_procNum =		realMsg->header->rh_procNum;
    reply.header.rh_flags = realMsg->header->rh_flags ^ (RPC_CALL|RPC_ERROR);
    reply.header.rh_length =		1;

    reply.buf[sizeof(RpcHeader)] = stat;

    while((RpcSend(geosFD, (char *)&reply,
		   sizeof(RpcHeader)+reply.header.rh_length) < 0) &&
	  (errno == EINTR))
    {
	;
    }

    if (realMsg->e != (CacheEntry *)0) {
	realMsg->e->status = REPLY_SENT;
	realMsg->e->error = stat;
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Return --
 *	Send a reply to an RPC call.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A reply message is sent. Memory will be allocated to cache the
 *	reply data if this is the first reply for a message (the status
 *	of the CacheEntry for it is REPLY_PENDING) and the status of the
 *	cache entry upgraded to REPLY_SENT, with replySize and replyData
 *	set appropriately.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Return(Rpc_Message	rpcMsg,	    /* Message to respond to */
	   int		length,	    /* Length of data to return */
	   Rpc_Opaque	data)	    /* Data to return */
{
    register RpcMessage	*realMsg = (RpcMessage *)rpcMsg;
    int			numBytes;
    RpcMessageBuf	reply;

    if (rpcDebug & RD_SERVE) {
	Message("return %d bytes for procedure %d, id %u\n",
	       length, realMsg->header->rh_procNum,
	       realMsg->header->rh_id);
    }
    /*
     * First set up the header of the reply message. If too many data are
     * being passed back, an RPC_TOOBIG error is generated instead of the
     * reply. Note that we indicate the byteOrder for the message is the same
     * as that sent, since we byte-swap it to be the same.
     */
    reply.header.rh_id =	    realMsg->header->rh_id;
    reply.header.rh_procNum =	realMsg->header->rh_procNum;
    reply.header.rh_flags =	    (realMsg->header->rh_flags ^
				     (RPC_CALL|RPC_REPLY));

    if (length <= RPC_MAX_DATA) {
	reply.header.rh_length =     length;
    } else {
	Rpc_Error(rpcMsg, RPC_TOOBIG);
	return;
    }

    /*
     * Handle caching and swapping: If there were actually reply data,
     * allocate new storage for them and copy them in, pointing the replyData
     * field of the CacheEntry at them, else set both the replyData and
     * replySize fields to 0. Mark the entry as REPLY_SENT.
     */
    if ((realMsg->e != (CacheEntry *)0) &&
	(realMsg->e->status == REPLY_PENDING))
    {
	realMsg->e->status = REPLY_SENT;

	if (length == 0) {
	    if (rpcDebug & RD_CACHE) {
		Message("Marking zero-length reply\n");
	    }
	    realMsg->e->replySize = 0;
	    realMsg->e->replyData = (Rpc_Opaque)0;
	} else {
	    if (swap && !Type_IsNull(realMsg->server->replyType)) {
		if (rpcDebug & (RD_CACHE|RD_SERVE)) {
		    Message("Swapping reply of %d bytes\n", length);
		}
		Var_SwapValue(VAR_STORE, realMsg->server->replyType,
			      length, (genptr)data);
	    }

	    if (rpcDebug & RD_CACHE) {
		Message("Marking reply of %d bytes\n", length);
	    }
	    realMsg->e->replySize = length;
	    realMsg->e->replyData = (Rpc_Opaque)malloc_tagged(length, TAG_RPC);
	    bcopy((char *)data, (char *)realMsg->e->replyData, length);
	}
    } else if (swap && !Type_IsNull(realMsg->server->replyType)) {
	Var_SwapValue(VAR_STORE, realMsg->server->replyType,
		      length, (genptr)data);
    }

    bcopy(data, &reply.buf[sizeof(RpcHeader)], length);

    /*
     * Keep sending the message while the thing keeps being interrupted.
     */
    do {
	numBytes = RpcSend(geosFD, &reply, length+sizeof(RpcHeader));
    } while ((numBytes < 0) && (errno == EINTR));

    if (numBytes < 0) {
	if (rpcDebug & (RD_SERVE|RD_STREAM)) {
	    perror("Rpc_Return: writev");
	}
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_ServerCreate --
 *	Set a server for a <patient, procedure-number> pair. The server
 *	should be declared as follows:
 *	    serverProc(msg, dataLen, data, serverData)
 *		  Patient patient;
 *		  Rpc_Opaque msg;
 *		  int dataLen;
 *		  Rpc_Opaque data;
 *		  Rpc_Opaque serverData;
 *
 *	msg is an opaque parameter that must be used to send a reply.
 *	dataLen is the number of bytes of data that came with the request.
 *	data is the data that were sent with the request.
 *	serverData is the piece of data supplied when the server was created.
 *
 *	data and serverData should not, of course, be opaque to the server...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Any previous server is overridden.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_ServerCreate(Rpc_Proc	procNum,	    /* Procedure number to
						     * serve */
		 void		(*serverProc) (Rpc_Message msg,
					       int dataLen,
					       Rpc_Opaque data,
					       Rpc_Opaque clientData),
		 Type		argType,	    /* Type description for
						     * args */
		 Type		replyType,	    /* Type description for
						     * reply */
		 Rpc_Opaque	serverData)	    /* Datum to pass to server
						     * function */
{
    register RpcServer	*s;

    assert(geosFD != 0);
    assert(geosFD > 0);  /* XXXdan debug */

    /*
     * Look for previous server record and use it if present
     */
    for (s = rpcServers[geosFD];
	 (s != (RpcServer *)0) && (s->procNum != procNum);
	 s = s->next)
    {
	;
    }
    if (s == (RpcServer *)0) {
	/*
	 * Didn't exist: create new record and link it into the list of
	 * servers on the socket.
	 */
	s = (RpcServer *)malloc_tagged(sizeof(RpcServer), TAG_RPC);
	s->next = rpcServers[geosFD];
	rpcServers[geosFD] = s;
    } else {
	/*
	 * It did exist. Since we're zeroing out the cache, we want to
	 * destroy previously-cached calls.
	 */
	RpcCacheDestroy(s);

	GC_UnregisterType(s->argType);
	GC_UnregisterType(s->replyType);
    }

    /*
     * Make sure neither type will be biffed by garbage collection
     */
    GC_RegisterType(argType);
    GC_RegisterType(replyType);

    /*
     * Install new server in server record
     */
    s->procNum = procNum;
    s->serverProc = serverProc;
    s->argType = argType;
    s->replyType = replyType;
    s->data = serverData;
    bzero((char *)s->cache, sizeof(s->cache));

    /*
     * Install handler for stream if no server here before, resetting the
     * receiver state to SYNC to look for RPC_MSG_START.
     */
    if (s->next == NULL) {
	rpcState = RPC_STATE_SYNC;
	Rpc_Watch(geosFD, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_ServerDelete --
 *	Deletes the handler for the given procedure on the given socket.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If the handler was defined, it is removed from the list and freed.
 *	If no calls are pending on the socket and this is the last server
 *	for the socket, the socket is ignored in later selects.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_ServerDelete(Rpc_Proc procNum)	/* Procedure number to stop handling */
{
    register RpcServer	*s;
    register RpcServer	**prev;

    assert(geosFD != 0);
    assert(geosFD > 0);  /* XXXdan debug */

    prev = &rpcServers[geosFD];
    for (s = rpcServers[geosFD];
	 (s != (RpcServer *)0) && (s->procNum != procNum);
	 s = s->next)
    {
	prev = &s->next;
    }

    if (s != (RpcServer *)0) {
	RpcCacheDestroy(s);
	GC_UnregisterType(s->argType);
	GC_UnregisterType(s->replyType);
	*prev = s->next;
	free((char *)s);
	if ((rpcServers[geosFD] == (RpcServer *)0) &&
	    (rpcCalls[geosFD] == (RpcCall *)0))
	{
	    Rpc_Ignore(geosFD);
	}
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Call --
 *	Invoke a remote procedure on another machine.
 *
 * Results:
 *	RPC_SUCCESS if the call went ok.
 *	RPC_TIMEDOUT if the server couldn't be reached in the given time.
 *	RPC_CANTSEND if couldn't send the message, for some reason.
 *
 * Side Effects:
 *	Messages are sent...
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Rpc_Call(Rpc_Proc	procNum,    /* Procedure number to call */
	 int		inLength,   /* Length of data for call */
	 Type		inType,	    /* Type of args */
	 Rpc_Opaque	inData,	    /* Data for call */
	 int		outLength,  /* Expected length of results. */
	 Type		outType,    /* Type of reply data */
	 Rpc_Opaque	outData)    /* Place to store results of call */
{
    RpcHeader		header;
    RpcCall		call;
    struct timeval	retry;

    if (inLength > RPC_MAX_DATA) {
	return (rpc_LastError = RPC_TOOBIG);
    }
    if ((attached == FALSE) && (tryingToAttach == FALSE)) {
	return(rpc_LastError = RPC_NOTATTACHED);
    }

    assert(geosFD >= 0);

    retry = defaultRetry;

    call.sock =			    geosFD;
    call.numRetries =		    NUM_RETRIES;
    call.id =			    RpcUniqueID();
    call.replyLen =		    outLength;
    call.reply =		    outData;
    call.replyType =		    outType;
    call.resend =		    Rpc_EventCreate(&retry,
						    RpcResend,
						    (Rpc_Opaque)&call);
    call.replied =		    False;
    call.next =			    rpcCalls[geosFD];

    rpcCalls[geosFD] = &call;

    header.rh_id =		    call.id;
    header.rh_procNum =		    procNum;
    header.rh_flags =		    RPC_CALL;
    header.rh_length =		    inLength;

    if (swap) {

#if 0
	Var_SwapValue(VAR_STORE, typeRpcHeader, sizeof(header),
		      (genptr)&header);
#endif /* 0 */
	if (!Type_IsNull(inType)) {
	    Var_SwapValue(VAR_STORE, inType, inLength, (genptr)inData);
	}
    }

    call.message[0].iov_base =	    (caddr_t)&header;
    call.message[0].iov_len =	    sizeof(header);
    call.message[1].iov_base =	    (caddr_t)inData;
    call.message[1].iov_len =	    inLength;

    /* We might trap the call and it's data to a file. */
    DebugRpcCall(&call) ;

    /*
     * Set to catch responses and send initial packet.
     */
    Rpc_Watch(geosFD, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);
    (void)RpcResend(&call, (Rpc_Event)NULL);

    while (!call.replied) {
#if defined(_WIN32)   /* experiment on WIN32 only - XXXdan */
	if (Ui_Interrupt() == TRUE) {
	    if (MessageFlush != NULL) {
		MessageFlush("User interrupt detected while trying to "
			     "communicate with GEOS\n");
	    }
	    return(RPC_TIMEDOUT);
	}
#endif
	Rpc_Wait();
    }

    /*
     * Cleanup: nuke the resend event and ignore the socket if we aren't
     * paying attention to it anymore (no servers for it and no calls pending
     * on it)
     */
    Rpc_EventDelete(call.resend);

    if ((rpcServers[geosFD] == (RpcServer *)0) &&
	(rpcCalls[geosFD] == (RpcCall *)0))
    {
	Rpc_Ignore(geosFD);
    }
    if (call.status != RPC_SUCCESS) {
	rpc_LastError = call.status;
    }

    return(call.status);
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Run --
 *	Function to run the Rpc system. This never returns. The program
 *	is expected to revolve around the system, being completely
 *	event-driven.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Not really.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Run(void)
{
    while(1) {
	Rpc_Wait();
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Debug --
 *	Set debugging state to 'debug'. If True, debug messages are
 *	printed to track the operation of rpc system.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	rpcDebug's value is altered.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Debug(int debug)
{
    rpcDebug = debug;
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_ErrorMessage --
 *	Return a string that describes the given error code.
 *
 * Results:
 *	See above.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
char *
Rpc_ErrorMessage(Rpc_Stat		stat)
{
    static char		*messages[] = {
	"Call was successful",
	"Couldn't send message",
	"Call timed out",
	"Arguments/results too big",
	"No such procedure",
	"Access denied",
	"Invalid argument(s)",
	"Remote system error",
	"Cannot load non-resident block",
	"No handle covering desired address",
	"Not attached to GEOS",
	"Target machine is running incompatible software",
    };
    int			index = (int)stat;

    if (index > sizeof(messages)/sizeof(char *)) {
	return ("Unknown error");
    } else {
	return (messages[index]);
    }
}


/***********************************************************************
 *				Rpc_LastError
 ***********************************************************************
 * SYNOPSIS:	    Return a message describing the most recent call error
 * CALLED BY:	    GLOBAL
 * RETURN:	    The aforementioned error message
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Call Rpc_ErrorMessage(rpc_LastError)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
char *
Rpc_LastError(void)
{
    return(Rpc_ErrorMessage(rpc_LastError));
}


/*-
 *-----------------------------------------------------------------------
 * Rpc_Reset --
 *	Reset the RPC system to its base startup state.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	All streams are ignored. All servers are destroyed. All events
 *	are deleted. All calls are terminated.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Reset(void)
{
    register int	stream;
    register RpcCall	*call;
    register RpcServer	*server;
    register RpcEvent	*event;

    FD_ZERO(&rpc_readMask);
    FD_ZERO(&rpc_writeMask);
    FD_ZERO(&rpc_exceptMask);

    for (stream = 0; stream < FD_SETSIZE; stream++) {
	streams[stream].state = 0;
	for (call = rpcCalls[stream];
	     call != (RpcCall *)0;
	     call = call->next)
	{
	    call->replied = True;
	    call->status = RPC_TIMEDOUT;
	}
	for (server = rpcServers[stream];
	     server != (RpcServer *)0;
	     server = server->next)
	{
	    free((char *)server);
	}
    }

    for (event = events; event != (RpcEvent *)0; event = events) {
	events = event->next;
	free((char *)event);
    }
}


/***********************************************************************
 *				Rpc_Abort
 ***********************************************************************
 * SYNOPSIS:	    Abort all pending calls.
 * CALLED BY:	    Ui_TopLevel.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All the RpcCall structures in the rpcCalls[geosFD]
 *	list are unlinked and their events deleted.
 *
 * STRATEGY:
 *	Go down the list of active calls, mark them all RPC_TIMEOUT and
 *	unlink them, then nuke their resend event. The intent is to
 *	handle both an abort with normal stack unwinding and a longjmp.
 *
 *	This is used by IbmHalt prior to returning to the top level mostly
 *	to take care of ugly situations where it was trying to access
 *	memory and received a fault of some sort.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/16/88	Initial Revision
 *
 ***********************************************************************/
void
Rpc_Abort(void)
{
    RpcCall	*call;

    if (geosFD < 0) {
	return;
    }

    for (call = rpcCalls[geosFD]; call != (RpcCall *)NULL; call = call->next){
	if (!call->replied) {
	    call->replied = True;
	    call->status = RPC_TIMEDOUT;
	}
	Rpc_EventDelete(call->resend);
	call->resend = (Rpc_Event *)NULL;
    }

    rpcCalls[geosFD] = (RpcCall *)NULL;
}


/***********************************************************************
 *				RpcSendFile
 ***********************************************************************
 * SYNOPSIS:	    send a file through rpc
 * CALLED BY:	    Tcl
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/93		Initial Revision
 *      Joon    10/93           Retransmit bad blocks
 *
 ***********************************************************************/
#define SYNC_SIZE 1
#define MAX_RETRY_COUNT 3
DEFCMD(send-file,RpcSendFile,TCL_EXACT, NULL, obscure,
"")
{
    FileType fp;
    char   *buf, *cp;
    byte   sync[SYNC_SIZE];
    int long    size, retry;
    long   filePos = 0, fileSize;
    struct stat stbuf;
    int    returnCode;

    if (argc != 3) {
	RpcSend(geosFD, ";", 2);
	Tcl_RetPrintf(interp, "Usage: send-file <src> <dest>.");
	return(TCL_ERROR);
    }

#if defined(_MSDOS) || defined(_WIN32)
    /*
     * on the PC convert slashes for pathnames on the host machine
     */
    for (cp = argv[1]; (cp = index(cp, '/')) != (char *)NULL; *cp = '\\');
#endif

    /*
     * convert slashes for path names on the target PC
     */
    for (cp = argv[2]; (cp = index(cp, '/')) != (char *)NULL; *cp = '\\');

    /*
     * open up the source file
     */
    returnCode = FileUtil_Open(&fp, argv[1], O_RDONLY | O_BINARY,
			       SH_DENYWR, 0);
    if (returnCode == FALSE) {
	char errmsg[512];

	FileUtil_SprintError(errmsg, "send-file error");
	MessageFlush("%s", errmsg);
	Tcl_RetPrintf(interp, "Error opening file %s.", argv[1]);
	return(TCL_ERROR);
    }
    /*
     * get file size
     */
    stat(argv[1], &stbuf);
    fileSize = stbuf.st_size;

    /*
     * send down the filename of the destination
     */
    if (Rpc_Call(RPC_SEND_FILE, strlen(argv[2])+1, type_Void, argv[2],
	     	    1, type_Void, &sync) != RPC_SUCCESS)
    {
	Tcl_RetPrintf(interp, "Error sending file %s.", argv[1]);
	return(TCL_ERROR);
    }

    /*
     * if we don't get back a sync then what probably happened is that
     * there was a bad filename given (ie. bad path or illegal file name
     */
    if (sync[0] != FILE_XFER_SYNC) {
	if (sync[0] == FILE_XFER_ERROR_DOS_SEM_TAKEN) {
	    Tcl_RetPrintf(interp, "Unable to send file.  DOS is busy.");
	} else {
	    Tcl_RetPrintf(interp, "Unable to create file %s on target. "
			  "The path does not exist.", argv[2]);
	}
	return(TCL_ERROR);
    }

    /*
     * ok, both ends are happy, so go ahead and start sending down the file in
     * 0.5K blocks
     */

    Message("Sending file %s to %s\n", argv[1], argv[2]);
    buf = malloc(FILE_XFER_BLOCK_SIZE);

    do {
	/*
	 * read in next block from source file
	 */
	(void)FileUtil_Read(fp, buf, FILE_XFER_BLOCK_SIZE, &size);
	/* XXXdan-q handle error reading file??? */
	retry = 0;

	if (!size)
	{
	    /*
	     * send out a zero size block so the stub knows to close the
	     * file
	     */
	    if (Rpc_Call(RPC_SEND_FILE_NEXT_BLOCK, Type_Sizeof(type_Void),
			type_Void, buf, 1,
		     	type_Void, &sync) != RPC_SUCCESS)
	    {
		Message("\nError sending file.\n");
		return TCL_ERROR;
	    }
	    break;
	}
	do {

	    if (Rpc_Call(RPC_SEND_FILE_NEXT_BLOCK, size, type_Void, buf, 1,
		     	type_Void, &sync) != RPC_SUCCESS)
	    {
		Message("\nError sending file.\n");
		return TCL_ERROR;
	    }

	    if (sync[0] == FILE_XFER_RETRY) {
		Message("\nError in packet transfer - resending packet.\n");
		retry++;
	    }
	} while ((sync[0] != FILE_XFER_SYNC) && (retry < MAX_RETRY_COUNT));

	if (retry < MAX_RETRY_COUNT) {
	    filePos += size;
	    MessageFlush("\rBytes transfered: %ld/%ld (%d%%) ",
			 filePos, fileSize, filePos*100/fileSize);
	}
    } while ((size == FILE_XFER_BLOCK_SIZE) && (retry < MAX_RETRY_COUNT));

    if (retry >= MAX_RETRY_COUNT)
	MessageFlush("\nToo many errors, transfer aborted.\n");
    else
	MessageFlush("\nSend complete.\n");

    (void)FileUtil_Close(fp);
    Tcl_Return(interp, "", TCL_STATIC);
    free(buf);
    return TCL_OK;

}

/*********************************************************************
 *			Rpc_IndexToOffset
 *********************************************************************
 * SYNOPSIS:	    convert an index in the export table to an actual offset
 * CALLED BY:	    Sym_GetFuncData
 * RETURN:	    converted offset
 * SIDE EFFECTS:    nothing
 * STRATEGY:	    ask to stub to look into the export table of
 *		    the geode for us
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/13/93		Initial version
 *
 *********************************************************************/
Address
Rpc_IndexToOffset(Patient   patient,	    /* patient whose table to use */
		  word	    index,	    /* index to convert */
		  ObjSym    *s)		    /* symbol to adjust values in */
{
    int	    	    i;

    IndexToOffsetArgs	itoa;
    IndexToOffsetReply	itor;


    for(i=3; i>0; i--)
    {
	itoa.ITOA_geodeHandle = Handle_ID(patient->core);
	itoa.ITOA_index = index;
	if (Rpc_Call(RPC_INDEX_TO_OFFSET, sizeof(itoa), typeIndexToOffsetArgs,
				(Opaque)&itoa, sizeof(itor),
				typeIndexToOffsetReply, (Opaque)&itor)
		    == RPC_SUCCESS)
	{
	    break;
	}
    }
    if (!i)
    {
	MessageFlush("Error in RPC call index-to-offset. %04x\n", index);
	return((Address)NULL);
    }

#if 0
    MessageFlush("Index %04x to offset %04x\n", index, itor.ITOR_offset);
#endif

    /*
     * as an optimization go ahead and adjust the values while in memory
     */
    s->flags &= ~OSYM_ENTRY;
    s->u.addrSym.address = itor.ITOR_offset;
    return (Address)itor.ITOR_offset;
}

/*********************************************************************
 *			RpcGetRestOfData
 *********************************************************************
 * SYNOPSIS: 	get a generic block of data from the target
 * CALLED BY:	Rpc_ReadFromGeode
 * RETURN:  	buffer filled with data
 * SIDE EFFECTS:
 * STRATEGY:	the stub will know what data to send from a previous RPC call
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	11/18/93		Initial version
 *
 *********************************************************************/

int
RpcGetRestOfData(void *buffer, dword size)
{
    dword   	    	curpos=0;
    GetNextDataBlock	gndb;

    while (curpos < size)
    {
	word	getsize;

	if (size-curpos < FILE_XFER_BLOCK_SIZE) {
	    getsize = size-curpos;
	} else {
	    getsize = FILE_XFER_BLOCK_SIZE;
	}
	gndb.GNDB_size = getsize;
    	if (Rpc_Call(RPC_GET_NEXT_DATA_BLOCK,
		     	    	sizeof(gndb), typeGetNextDataBlock, &gndb,
				getsize, type_Void,
		     	    	(Opaque)((char *)buffer+curpos))
	    	    != RPC_SUCCESS)
	{
	    return TCL_ERROR;
	}
	curpos += getsize;
    }
    return TCL_OK;
}

/*********************************************************************
 *			Rpc_ReadFromGeode
 *********************************************************************
 * SYNOPSIS:	C routine to read info from a geode over on the targer
 * CALLED BY:	IbmFindBlock
 * RETURN:	buffer full of data
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/24/93		Initial version
 *
 *********************************************************************/
int
Rpc_ReadFromGeode(Patient   patient,	/* patient whose Geode to read */
		  dword	    offset,	/* place in file to start reading */
		  word	    size,	/* number of bytes to read */
		  word	    dataType,	/* type of data to get */
		  char	    *buf,	/* buffer to put data into */
		  word	    dataValue1, /* values depend on data type */
		  word	    dataValue2)
{
    ReadGeodeArgs   rga;


    struct {
	ReadGeodeReply      rgr;
	char    	    readGeodeBuf[256];
    } myrgr;

    int		    i;

    assert(size <= 1024);
    for (i = 3; i > 0; i--)
    {
	word	getsize;

	rga.RGA_offset = offset - sizeof(GeosFileHeader2);
	rga.RGA_dataType = dataType;
	rga.RGA_dataValue1 = dataValue1;
	rga.RGA_dataValue2 = dataValue2;

	if (patient == loader)
	{
	    if (dataType == GEODE_DATA_LOADER)
	    {
		/* special case for the loader, we only ask for one thing
		 * from the loader, and that is the size of the header...
		 */
	    	rga.RGA_geodeHandle = 1;
	    }
	    else
	    {
		return(TCL_ERROR);
	    }
	}
	else
	{
	    rga.RGA_geodeHandle = Handle_ID(patient->core);
	}

	/* send off for the whole thing if it fits in one RPC call, else
	 * send off for as much as we can and then get the rest in chunks
	 */
	getsize = size + sizeof(myrgr.rgr);
	if (getsize > FILE_XFER_BLOCK_SIZE)
	{
	    getsize = FILE_XFER_BLOCK_SIZE;
	}
	rga.RGA_size = getsize - sizeof(myrgr.rgr);
	if (Rpc_Call(RPC_READ_GEODE, sizeof(rga), typeReadGeodeArgs,
				 (Opaque)&rga,
				 getsize, typeReadGeodeReply,
		     	    	(Opaque)&myrgr)
		    != RPC_SUCCESS)
	{
	    return(TCL_ERROR);
	}

	if (myrgr.rgr.RGR_ok != FILE_XFER_SYNC)
	{
	    /* no good, so try again, or exit if this was our last try */
	    continue;
	}
	getsize -= sizeof(myrgr.rgr);	/* now actual size of data received */
	memcpy(buf, myrgr.readGeodeBuf, getsize);
	if (getsize == size)
	{
	    /* we got the whole thing, so return */
	    return (TCL_OK);
	}
	else
	{
	    /* we got the first chunk, now lets get the rest */
	    return RpcGetRestOfData(buf+getsize, size - getsize);
	}
    }
    return (TCL_ERROR);
}

/*********************************************************************
 *			Rpc_ReadGeodeCmd
 *********************************************************************
 * SYNOPSIS: 	read data from a geode down on the PC
 * CALLED BY:	Ibm_ReadBytes and others
 * RETURN:
 * SIDE EFFECTS:buffer filled with data read from Geode
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/23/93		Initial version
 *
 *********************************************************************/
DEFCMD(rpc-read-geode,Rpc_ReadGeode,TCL_EXACT,NULL,obscure,
"")
{
    Patient patient;	    /* patient from whose geode to read */
    char   *buf;  	    /* a buffer to put data into */
    dword   offset;	    /* offset into file to start reading */
    word   size; 	    /* number of bytes to read <= 1024 */

    patient = (Patient)atoi(argv[1]);
    offset = atoi(argv[2]);
    size = atoi(argv[3]);

    buf = malloc(size);
    Rpc_ReadFromGeode(patient, offset, size, GEODE_DATA_NORMAL, buf, 0, 0);
    Tcl_Return(interp, buf, TCL_DYNAMIC);
    return TCL_OK;
}


/***********************************************************************
 *				RpcFindGeode
 ***********************************************************************
 * SYNOPSIS:	    find geos application on target machine
 * CALLED BY:	    Tcl
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JS	8/ 3/93   	Initial Revision
 *
 ***********************************************************************/
DEFCMD(rpc-find-geode,RpcFindGeode,TCL_EXACT,NULL,obscure,
"Usage:\n\
    rpc-find-geode [-n] <geode_name>\n\
\n\
Examples:\n\
    \"rpc-find-geode write\"		Find path of EC GeoWrite\n\
    \"rpc-find-geode -n write\"		Find path of non-EC GeoWrite\n\
\n\
Synopsis:\n\
    Find path of geode on target machine.\n\
")
{
    char geodeName[RPC_FIND_GEODE_XFER_SIZE];
    char pathName[RPC_FIND_GEODE_XFER_SIZE];
    int i;

    if ((argc < 2) || (argc > 3) ||
	((argc == 3) && (strcmp(argv[1], "-n") != 0))) {
	Tcl_Error(interp, "Usage: find-geode [-n] <geode_name>");
    }

    /*
     * Space pad geodeName.
     */
    strncpy(geodeName, argv[argc-1], GEODE_NAME_SIZE);
    geodeName[GEODE_NAME_SIZE] = '\0';

    if ((i = strlen(geodeName)) < GEODE_NAME_SIZE)
	for (; i < GEODE_NAME_SIZE; i++)
	    geodeName[i] = ' ';

    if (argc == 2)
	strcpy(geodeName+GEODE_NAME_SIZE, "E   ");
    else
	strcpy(geodeName+GEODE_NAME_SIZE, "    ");

    /* temporarily change timeout value to 30 seconds */
    i = defaultRetry.tv_sec;
    defaultRetry.tv_sec = 30;

    /* send down the geodeName */
    if (Rpc_Call(RPC_FIND_GEODE,
		 sizeof(geodeName), Type_CreateArray(0,127,type_Int,type_Byte),
		 (Opaque)&geodeName,
		 sizeof(pathName), Type_CreateArray(0,127,type_Int,type_Byte),
		 (Opaque)&pathName)
	!= RPC_SUCCESS)	{
	defaultRetry.tv_sec = i;
	MessageFlush("Error in RPC call to find geode.\n");
	return(TCL_ERROR);
    }

    defaultRetry.tv_sec = i;
    Tcl_RetPrintf(interp, "%s", pathName);
    return TCL_OK;
}	/* End of RpcFindGeode.	*/

/***********************************************************************
 *				RpcDebugCmd
 ***********************************************************************
 * SYNOPSIS:	    Set our internal debug flag
 * CALLED BY:	    Tcl
 * RETURN:	    State of debug flag
 * SIDE EFFECTS:    debug may be altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/10/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(rpc-dbg,RpcDebug,TCL_EXACT,NULL,obscure,
"Usage:\n\
    rpc-dbg <flag>+\n\
\n\
Examples:\n\
    \"rpc-dbg +stream\"	Turn on debugging output for stream-related RPC\n\
 	    	    	functions\n\
    \"rpc-dbg -packet\"	Turn off debugging of packet-level functions.\n\
\n\
Synopsis:\n\
    Adjusts or returns the state of Swat's internal RPC debug flags.\n\
\n\
Notes:\n\
    * <flag> is a '+' (to activate) or '-' (to deactivate) followed by a\n\
      string from the following set:\n\
	Flag		Printed info pertains to...\n\
	------------------------------------------------------------------	\n\
	stream	    	watching/handling of streams.\n\
	eventQueue	manipulation of the timer-event queue.\n\
	eventTaken  	tells when a timer-event is activated.\n\
	call	    	calls from Swat to the PC.\n\
	serve	    	calls from the PC to Swat.\n\
	packet	    	packet-level protocol.\n\
	noTimeout   	refuses to allow any call to time out.\n\
 	cache	    	cache into\n\
\n\
    * Returns the list of enabled debug flags.\n\
\n\
See also:\n\
    rpc.\n\
")
{
    static struct {
	char	*name;
	int 	flag;
    }	flags[] = {
	{"stream",   	RD_STREAM},
	{"eventQueue",	RD_EVENT_QUEUE},
	{"eventTaken",	RD_EVENT_TAKEN},
	{"call",	RD_CALL},
	{"serve",    	RD_SERVE},
	{"packet",   	RD_PACKET},
	{"noTimeout",	RD_NO_TIMEOUT},
	{"cache",    	RD_CACHE}
    };
    char    	*retargv[sizeof(flags)/sizeof(flags[0])];
    int	    	retargc;
    int	    	i;
    int	    	set, clear;

    set = clear = 0;

    for (i = 1; i < argc; i++) {
	char	*f;
	int 	j;

	f = argv[i];
	if (argv[i][0] == '-' || argv[i][0] == '+') {
	    f++;
	}
	for (j = 0; j < sizeof(flags)/sizeof(flags[0]); j++) {
	    if (strcmp(f, flags[j].name) == 0) {
		break;
	    }
	}

	if (j == sizeof(flags)/sizeof(flags[0])) {
	    Tcl_RetPrintf(interp, "%s is not a valid debug flag", f);
	    return(TCL_ERROR);
	}

	if (argv[i][0] == '-') {
	    clear |= flags[j].flag;
	} else {
	    set |= flags[j].flag;
	}
    }

    rpcDebug = (rpcDebug | set) & ~clear;

    for (i = 0, retargc = 0; i < sizeof(flags)/sizeof(flags[0]); i++) {
	if (rpcDebug & flags[i].flag) {
	    retargv[retargc++] = flags[i].name;
	}
    }
    Tcl_Return(interp, Tcl_Merge(retargc, retargv), TCL_DYNAMIC);
    return(TCL_OK);
}
/*
 * Token allocated both for servers and events, containing the procedure to
 * call and the data to pass it.
 */
typedef struct {
    char    	*procName;  	/* Procedure to call */
    char    	*data;	    	/* Extra data to pass it */
    Rpc_Opaque	other;	    	/* Extra piece of data we need */
} RpcTclToken;


/***********************************************************************
 *				RpcTclServer
 ***********************************************************************
 * SYNOPSIS:	    Call a TCL-level RPC server
 * CALLED BY:	    RpcWait
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	    Convert the arguments to a value list.
 *	    Invoke the procedure.
 *	    Convert the results back to binary and send them as a reply.
 *	    If result was an error, convert message to binary and send
 *	    	as error code.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
static void
RpcTclServer(Rpc_Message    msg,
	     int	    len,
	     Rpc_Opaque	    data,
	     Rpc_Opaque     clientData)
{
    RpcTclToken	    *token = (RpcTclToken *)clientData;
    RpcMessage	    *message = (RpcMessage *)msg;
    char    	    *args[4];
    char    	    *cmd;
    char    	    lenStr[10];

    args[0] = token->procName;
    args[1] = lenStr;
    args[2] = Value_ConvertToString(message->server->argType, data);
    args[3] = token->data;

    sprintf(lenStr, "%d", len);

    cmd = Tcl_Merge(4, args);

    switch (Tcl_Eval(interp, cmd, 0, (const char **)NULL)) {
	case TCL_OK:
	{
	    Opaque  repData;
	    int	    repSize = Type_Sizeof(message->server->replyType);

	    repData = Value_ConvertFromString(message->server->replyType,
					      interp->result);

	    if (repData == NULL) {
		Rpc_Error(msg, RPC_SYSTEMERR);
	    } else {
		Rpc_Return(msg, repSize, repData);
		free(repData);
	    }
	    break;
	}
	case TCL_ERROR:
	    Rpc_Error(msg, (unsigned char)atoi(interp->result));
	    break;
    }

    free(cmd);
    free(args[1]);
}


/***********************************************************************
 *				RpcTclEvent
 ***********************************************************************
 * SYNOPSIS:	    Front-end for a TCL-level RPC event
 * CALLED BY:	    RpcWait
 * RETURN:	    1 if should stay awake, 0 if not
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
static Boolean
RpcTclEvent(Rpc_Opaque	clientData,
	    Rpc_Event	event)
{
    RpcTclToken	    *token = (RpcTclToken *)clientData;
    char    	    *args[3];
    char    	    *cmd;
    char    	    evStr[10];

    args[0] = token->procName;
    args[1] = token->data;
    sprintf(evStr, "%d", (int)token);
    args[2] = evStr;

    cmd = Tcl_Merge(3, args);

    if (Tcl_Eval(interp, cmd, 0, (const char **)NULL) != TCL_OK) {
	/*
	 * Stay awake on any error
	 */
	free(cmd);
	return(1);
    } else {
	free(cmd);
	return(atoi(interp->result));
    }
}


/***********************************************************************
 *				RpcCmd
 ***********************************************************************
 * SYNOPSIS:	    Tcl-level interface to RPC system
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Internal routines will be called...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/17/89	Initial Revision
 *
 ***********************************************************************/
#define RPC_CALLCMD 	(ClientData)0
#define RPC_SERVECMD	(ClientData)1
#define RPC_DELETECMD	(ClientData)2
#define RPC_EVENTCMD	(ClientData)3
#define RPC_DEBUGCMD	(ClientData)4
#define RPC_TIMEOUTCMD	(ClientData)5
#define RPC_WAITCMD 	(ClientData)6
static const CmdSubRec rpcCmds[] = {
    {"call", 	RPC_CALLCMD,	4, 4,	"<proc> <argType> <args> <repType>"},
    {"serve",	RPC_SERVECMD,	4, 5,	"<proc> <argType> <repType> <procName> [<data>]"},
    {"delete",	RPC_DELETECMD,	1, 1,	"(<server>|<event>)"},
    {"event",	RPC_EVENTCMD,	2, 3,	"<time> <procName> [<data>]"},
    {"debug",	RPC_DEBUGCMD,	0, TCL_CMD_NOCHECK,	"(+<flag>|-<flag>)*"},
    {"timeout",	RPC_TIMEOUTCMD,	0, 1,	"[(on|off|1|0)]"},
    {"wait", 	RPC_WAITCMD,	0, 0,	""},
    {NULL,   	0,  	    	0, 0, 	NULL}
};

DEFCMD(rpc,Rpc,1,rpcCmds,swat_prog.obscure,
"Usage:\n\
    rpc call <proc> <argType> <args> <repType>\n\
    rpc serve <proc> <argType> <repType> <procName> [<data>]\n\
    rpc delete (<server>|<event>)\n\
    rpc event <time> <procName> [<data>]\n\
    rpc debug (+<flag>|-<flag>)*\n\
    rpc timeout [(on|off|1|0)]\n\
    rpc wait \n\
\n\
Examples:\n\
    \"var e [rpc event 1.5 puffball]\"	Registers a timed event to call\n\
					the procedure \"puffball\" every 1.5\n\
					seconds (starting 1.5 seconds from now).\n\
    \"rpc wait\"				Allows input etc. to be handled while\n\
					in a Tcl procedure.\n\
    \"rpc delete $e\" 	    	    	Nuke the event registered before.\n\
\n\
Synopsis:\n\
    This command provides access to the RPC system by which Swat communicates\n\
    with the stub running on the PC. IT IS INTENDED ONLY FOR SYSTEMS TCL\n\
    PROGRAMMERS WHO KNOW WHAT THEY ARE DOING. While screwing up will cause no\n\
    permanent damage, it can make your debugging session rather unhappy.\n\
\n\
Notes:\n\
    * \"rpc call\" calls a procedure in the stub.	<proc> is the procedure number\n\
      or name to call in the stub. <argType> is a type token describing the\n\
      arguments being passed. <args> is a value string such as would be\n\
      returned from \"value fetch\" of <argType>. <repType> is the type of data\n\
      expected in return. This may be oversized if a variable amount of\n\
      response data is expected, but it must reflect the actual type of data\n\
      being returned so the values can be properly byte-swapped. It is not an\n\
      error to get too little data back from the stub. Too much data, however,\n\
      is an error. The data returned by the stub comes back to you as a value\n\
      list.\n\
\n\
      If the call cannot be completed, this will generate an error, the\n\
      message for which will describe the problem.\n\
\n\
    * \"rpc serve\" registers a Tcl procedure to serve remote calls from the\n\
      stub. <proc> is the procedure number to serve. <argType> is a type token\n\
      describing the arguments expected for the procedure, while <repType>\n\
      describes the data returned by the server. <procName> is the name of the\n\
      server procedure. It will be called:\n\
	<procName> <length> <args> <data>\n\
      <length> is the number of bytes of data received. <args> is a value\n\
      list of the passed data, while <data> is the same as the <data> argument\n\
      to this call. This argument will always be passed, even if <data> is\n\
      omitted when the server is registered.\n\
\n\
      Returns a token for the server. The server can be unregistered via the\n\
      \"rpc delete\" command.\n\
\n\
    * \"rpc event\" registers an event to be called at a regular interval. <time>\n\
      is the number of seconds between calls (as a real number). <procName> is\n\
      the name of the procedure to call and <data> an optional piece of data\n\
      to pass it. The procedure is called:\n\
	<procName> <data> <event>\n\
      <event> is the event token returned by this call. All three arguments\n\
      are passed, regardless of the presence of a <data> parameter to this\n\
      call. The procedure should return a non-zero number if the RPC system\n\
      should return immediately, rather than going to sleep to wait for\n\
      something on one of its input streams.\n\
\n\
    * \"rpc delete\" deletes an event, or unregisters a server. If argument is\n\
      a server token, as returned by \"rpc serve\", the server is unregistered.\n\
      If it's an event token, as returned by \"rpc event\", the event is\n\
      deleted.\n\
\n\
    * \"rpc debug\" takes the same arguments and performs the same actions as\n\
      the \"rpc-dbg\" command, which see.\n\
\n\
    * \"rpc timeout\" allows you to insist that calls made from Swat to the PC\n\
      never time out, but instead continue being resent until they are answered\n\
      or aborted in some fashion. When timeout errors are enabled, if the PC\n\
      hasn't responded in 2 seconds (a 1 second interval between the two calls),\n\
      the returns an error. TURNING OFF TIMEOUTS AFFECTS ALL CALLS, NOT JUST\n\
      THOSE ISSUED WITH THE \"rpc call\" COMMAND.\n\
\n\
    * \"rpc wait\" waits for something to happen. The \"something\" can be the\n\
      firing of a timed event, or the readiness of a stream to be messed with.\n\
      It returns once whatever happened has been processed. This is usually\n\
      called in a loop until a particular condition has been met. Without\n\
      this, all timed-events, keyboard input, and RPC service is suspended\n\
      until control returns to the top-level interpreter loop.\n\
\n\
See also:\n\
    rpc-dbg, value.\n\
")
{
    switch((int)clientData) {
	case (int)RPC_CALLCMD:
	{
	    Opaque  	argData, repData;
	    Type    	argType, repType;
	    int	    	argSize, repSize;
	    Rpc_Proc	procNum=0;
	    static const struct {
		const char  *name;
		const int   procNum;
	    }	    	procMap[] = {
		{"RPC_GOODBYE1", RPC_GOODBYE1},
		{"RPC_GOODBYE", RPC_GOODBYE},
		{"RPC_EXIT1", RPC_EXIT1},
		{"RPC_EXIT", RPC_EXIT},
		{"RPC_CONTINUE", RPC_CONTINUE},
		{"RPC_STEP", RPC_STEP},
		{"RPC_SKIPBPT", RPC_SKIPBPT},
		{"RPC_READ_REGS", RPC_READ_REGS},
		{"RPC_WRITE_REGS", RPC_WRITE_REGS},
		{"RPC_READ_MEM", RPC_READ_MEM},
		{"RPC_WRITE_MEM", RPC_WRITE_MEM},
		{"RPC_FILL_MEM8", RPC_FILL_MEM8},
		{"RPC_FILL_MEM16", RPC_FILL_MEM16},
		{"RPC_READ_IO8", RPC_READ_IO8},
		{"RPC_READ_IO16", RPC_READ_IO16},
		{"RPC_WRITE_IO8", RPC_WRITE_IO8},
		{"RPC_WRITE_IO16", RPC_WRITE_IO16},
		{"RPC_READ_ABS", RPC_READ_ABS},
		{"RPC_WRITE_ABS", RPC_WRITE_ABS},
		{"RPC_FILL_ABS8", RPC_FILL_ABS8},
		{"RPC_FILL_ABS16", RPC_FILL_ABS16},
		{"RPC_BLOCK_FIND", RPC_BLOCK_FIND},
		{"RPC_BLOCK_INFO", RPC_BLOCK_INFO},
		{"RPC_MASK", RPC_MASK},
		{"RPC_INTERRUPT", RPC_INTERRUPT},
		{"RPC_CBREAK", RPC_CBREAK},
		{"RPC_NOCBREAK", RPC_NOCBREAK},
		{"RPC_CHGCBREAK", RPC_CHGCBREAK},
		{"RPC_SETTBREAK", RPC_SETTBREAK},
		{"RPC_GETTBREAK", RPC_GETTBREAK},
		{"RPC_ZEROTBREAK", RPC_ZEROTBREAK},
		{"RPC_CLEARTBREAK", RPC_CLEARTBREAK},
		{"RPC_SETTIMEBRK", RPC_SETTIMEBRK},
		{"RPC_GETTIMEBRK", RPC_GETTIMEBRK},
		{"RPC_ZEROTIMEBRK", RPC_ZEROTIMEBRK},
		{"RPC_CLEARTIMEBRK", RPC_CLEARTIMEBRK},
		{"RPC_TRACE_FETCH", RPC_TRACE_FETCH},
		{"RPC_TRACE_NEXT", RPC_TRACE_NEXT},
		{"RPC_BRK_FILL", RPC_BRK_FILL},
		{"RPC_BRK_WRITE", RPC_BRK_WRITE},
		{"RPC_READ_FPU", RPC_READ_FPU},
		{"RPC_WRITE_FPU", RPC_WRITE_FPU},
		{"RPC_SEND_FILE", RPC_SEND_FILE},
		{"RPC_SEND_FILE_NEXT_BLOCK", RPC_SEND_FILE_NEXT_BLOCK},
		{"RPC_READ_GEODE", RPC_READ_GEODE},
		{"RPC_INDEX_TO_OFFSET", RPC_INDEX_TO_OFFSET},
		{"RPC_FIND_GEODE", RPC_FIND_GEODE},
		{"RPC_READ_XMS_MEM", RPC_READ_XMS_MEM},
		{"RPC_READ_DEBUG_REGS", RPC_READ_DEBUG_REGS},
		{"RPC_WRITE_DEBUG_REGS", RPC_WRITE_DEBUG_REGS}
	    };

	    /*
	     * Convert from external to internal format...
	     */
	    if (isdigit(argv[2][0])) {
		procNum = cvtnum(argv[2], (char **)NULL);
	    } else {
		int i;

		for (i = sizeof(procMap)/sizeof(procMap[0])-1; i >= 0; i--) {
		    if (strcmp(procMap[i].name, argv[2]) == 0) {
			procNum = procMap[i].procNum;
			break;
		    }
		}
		if (i < 0) {
		    Tcl_RetPrintf(interp, "%s is not a defined procedure",
				  argv[2]);
		    return(TCL_ERROR);
		}
	    }
	    argType = Type_ToToken(argv[3]);
	    repType = Type_ToToken(argv[5]);
	    if (Type_IsNull(argType)) {
		Tcl_Error(interp, "invalid argument type");
	    }
	    if (Type_IsNull(repType)) {
		Tcl_Error(interp, "invalid reply type");
	    }

	    argData = Value_ConvertFromString(argType, argv[4]);
	    if (argData == NullOpaque) {
		/*
		 * Error message left in return value by
		 * Value_ConvertFromString
		 */
		return(TCL_ERROR);
	    }

	    /*
	     * Allocate room for reply data and issue the call
	     */
	    argSize = Type_Sizeof(argType);
	    repSize = Type_Sizeof(repType);

	    repData = (Opaque)malloc_tagged(repSize, TAG_RPC);
	    if (Rpc_Call(procNum, argSize, argType, argData,
			 repSize, repType, repData) != RPC_SUCCESS)
	    {
		free(argData);
		free(repData);
		/*
		 * Signal error using message for error we got back
		 */
		Tcl_RetPrintf(interp, "rpc call: %s", Rpc_LastError());
		return(TCL_ERROR);
	    }


	    /*
	     * Convert reply data to ascii and return it.
	     */
	    Tcl_Return(interp, Value_ConvertToString(repType, repData),
		       TCL_DYNAMIC);

	    /*
	     * Free argument/reply buffers
	     */
	    free(argData);
	    free(repData);
	    break;
	}
	case (int)RPC_SERVECMD:
	{
	    Rpc_Proc	procNum;
	    Type    	argType, repType;
	    RpcTclToken	*token;

	    /*
	     * Convert from external to internal format
	     */
	    procNum = cvtnum(argv[2], (char **)NULL);
	    argType = Type_ToToken(argv[3]);
	    repType = Type_ToToken(argv[4]);
	    if (Type_IsNull(argType)) {
		Tcl_Error(interp, "invalid argument type");
	    }
	    if (Type_IsNull(repType)) {
		Tcl_Error(interp, "invalid reply type");
	    }

	    /*
	     * Initialize token we use for both servers and events. We
	     * place both the procedure name and the extra data in the same
	     * block immediately after the binary portion of the token.
	     */
	    token = (RpcTclToken *)malloc_tagged(sizeof(RpcTclToken)+
						 strlen(argv[5])+1+
						 (argc==7?strlen(argv[6]):0)+1,
						 TAG_RPCSRV);
	    token->procName = (char *)(token+1);
	    token->data = token->procName + strlen(argv[5]) + 1;
	    token->other = (Rpc_Opaque)((long)procNum);

	    strcpy(token->procName, argv[5]);
	    strcpy(token->data, argc==7 ? argv[6] : "");

	    /*
	     * Register the server, having it give control to our front-end
	     * routine.
	     */
	    Rpc_ServerCreate(procNum, RpcTclServer, argType, repType,
			     (Rpc_Opaque)token);

	    /*
	     * Return token
	     */
	    Tcl_RetPrintf(interp, "%d", token);
	    break;
	}
	case (int)RPC_EVENTCMD:
	{
	    RpcTclToken	    *token;
	    struct timeval  tv;
	    double  	    tval;
#ifndef __WATCOMC__
	    extern double   atof();
#endif

	    /*
	     * Convert time from ascii real to number of seconds and useconds
	     */
	    tval = atof(argv[2]);
	    tv.tv_sec = tval;
	    tv.tv_usec = 1000000 * (tval - tv.tv_sec);

	    /*
	     * Allocate and initialize token for the event.
	     * Again, the procedure name and procedure data
	     * get placed in the same block.
	     */
	    token = (RpcTclToken *)malloc_tagged(sizeof(RpcTclToken)+
						 strlen(argv[3])+1+
						 (argc==5?strlen(argv[4]):0)+1,
						 TAG_RPCEV);
	    token->procName = (char *)(token+1);
	    token->data = token->procName + strlen(argv[3]) + 1;

	    strcpy(token->procName, argv[3]);
	    strcpy(token->data, argc==5 ? argv[4] : "");

	    /*
	     * Create the event, pointing it to our front-end routine.
	     */
	    token->other = (Rpc_Opaque)Rpc_EventCreate(&tv,
						       RpcTclEvent,
						       (Rpc_Opaque)token);

	    /*
	     * Return the token to the caller
	     */
	    Tcl_RetPrintf(interp, "%d", token);
	    break;
	}
	case (int)RPC_DELETECMD:
	{
	    RpcTclToken	    *token;

	    token = (RpcTclToken *)atoi(argv[2]);

	    if (VALIDTPTR(token, TAG_RPCSRV)) {
		/*
		 * Server token -- unregister the server.
		 */
		Rpc_ServerDelete((Rpc_Proc)((long)token->other));
	    } else if (VALIDTPTR(token, TAG_RPCEV)) {
		/*
		 * Event token -- delete the event
		 */
		Rpc_EventDelete((Rpc_Event)token->other);
	    } else {
		/*
		 * Choke
		 */
		Tcl_Error(interp, "rpc delete: invalid token");
	    }
	    /*
	     * Free the token record -- no longer needed.
	     */
	    free((malloc_t)token);
	    break;
	}
	case (int)RPC_DEBUGCMD:
	    return RpcDebugCmd(clientData, interp, argc-1, argv+1);
	case (int)RPC_TIMEOUTCMD:
	    if (argc == 3) {
		/*
		 * Set timeout error status.
		 */
		if (strcmp(argv[2], "off") == 0) {
		    rpcDebug &= ~RD_NO_TIMEOUT;
		} else if (strcmp(argv[2], "on") == 0) {
		    rpcDebug |= RD_NO_TIMEOUT;
		} else {
		    if (atoi(argv[2])) {
			rpcDebug |= RD_NO_TIMEOUT;
		    } else {
			rpcDebug &= ~RD_NO_TIMEOUT;
		    }
		}
	    }
	    Tcl_Return(interp,
		       (rpcDebug & RD_NO_TIMEOUT) ? "1" : "0",
		       TCL_STATIC);
	    break;
	case (int)RPC_WAITCMD:
	    Rpc_Wait();
	    break;
    }
    return(TCL_OK);
}

#if defined(unix)

/***********************************************************************
 *				RpcOpenModem
 ***********************************************************************
 * SYNOPSIS:	    Try and open a modem for contacting a remote system.
 * CALLED BY:	    Rpc_Init
 * RETURN:	    nothing
 * SIDE EFFECTS:    isModem is set true
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/90		Initial Revision
 *
 ***********************************************************************/
static void
RpcOpenModem(char   *modem)
{
    geosFD = open(modem, O_RDWR, 0);
    if ((geosFD < 0) && (errno == ENOENT) && (index(modem, '/') == 0)){
	char	realModem[64];

	sprintf(realModem, "/dev/%s", modem);
	geosFD = open(realModem, O_RDWR, 0);
	if ((geosFD < 0) && (errno == ENOENT)) {
	    sprintf(realModem, "/dev/dialer%s", modem);
	    geosFD = open(realModem, O_RDWR, 0);
	}
    }

    if (geosFD >= 0) {
	struct sgttyb	sgb;

	if (ioctl(geosFD, TIOCGETP, &sgb) < 0) {
	    perror("TIOCGETP");
	    (void)close(geosFD);
	    geosFD = -1;
	} else {
	    /*
	     * Adjust retry to account for line speed. Double it for
	     * anything under 9600 baud. Double it again if the speed is
	     * under 2400...
	     */
	    if (sgb.sg_ospeed < B9600) {
		defaultRetry.tv_sec *= 2;
	    }
	    if (sgb.sg_ospeed < B2400) {
		defaultRetry.tv_sec *= 2;
	    }
	}
    }

    isModem = TRUE; /* Don't close connection between sessions */
}
#endif /* unix */


/***********************************************************************
 *				Rpc_Init
 ***********************************************************************
 * SYNOPSIS:	  Initialize the module for the patient/debugger
 * CALLED BY:	  Ibm_Init
 * RETURN:	  TRUE if successful/FALSE if not
 * SIDE EFFECTS:  geosFD is set.
 *
 * STRATEGY:	  Well...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/22/88		Initial Revision
 *
 ***********************************************************************/
void
Rpc_Init(int		*argcPtr,
	 char		**argv)
{
    const char 	  	*tty=0;
    char    	  	**nav;
    char    	  	**av;
    int			ac;
#if defined(_WIN32)
    char		workbuf[256];
    long		comport = 0;
    long		baudrate = 0;
    BOOL		returnCode;
    int long			retryMult = 0;
    char		*npipe=0;
    int			npipeTries;
#elif defined(unix)
    char    	    	*modem=0;
#endif

    for (av = nav = &argv[1], ac = *argcPtr-1; ac > 0; ac--, av++) {
	if (strncmp(*av, "-t", 2) == 0) {           /* look for tty arg */
	    if ((av[0][2] == '\0') && (ac > 1)) {
		tty = av[1];
		av++, ac--;
		*argcPtr -= 2;
		commMode = CM_SERIAL;
	    } else if (av[0][2] == '\0') {
		MessageFlush("-t needs an argument\n");
		exit(1);
	    } else {
		tty = &av[0][2];
		*argcPtr -= 1;
		commMode = CM_SERIAL;
	    }
	}

#if defined(unix)
	else if (strncmp(*av, "-m", 2) == 0) {      /* look for modem arg */
	    if ((av[0][2] == '\0') && (ac > 1)) {
		modem = av[1];
		av++, ac--;
		*argcPtr -= 2;
	    } else if (av[0][2] == '\0') {
		MessageFlush("-m needs an argument\n");
		exit(1);
	    } else {
		modem = &av[0][2];
		*argcPtr -= 1;
	    }
	} else if (strcmp(*av, "-S") == 0) {         /* look for signal arg */
	    noSig = TRUE;
	    *argcPtr -= 1;
	}
#endif /* unix */
#if !defined(_WIN32)
	else if (strcmp(*av, "-net") == 0) {       /* look for net arg */
	    av++, ac--;
	    if (ac == 0) {
		MessageFlush("-net needs an argument\n");
		exit(1);
	    }
	    *argcPtr -= 2;
	    geosFD = NetWare_Init(*av);
	    if (geosFD >= 0) {
		commMode = CM_NETWARE;
	    } else {
		exit(1);
	    }
	}
#else
	else if (strncmp(*av, "-npipe", 6) == 0) {     /* look for npipe arg */
	    if ((av[0][6] == '\0') && (ac > 1)) {
		npipe = av[1];
		commMode = CM_NPIPE;
		av++, ac--;
		*argcPtr -= 2;
	    } else if (av[0][6] == '\0') {
		MessageFlush("-npipe needs an argument in form "
			     "\\\\<server>\\pipe\\<name>\n");
		exit(1);
	    } else {
		npipe = &av[0][6];
		commMode = CM_NPIPE;
		*argcPtr -= 1;
	    }
	}
#endif   /* !_WIN32 */
	else {
	    /*
	     * Copy the argument (down)
	     */
	    *nav++ = *av;
	}
    }

#if !defined(_WIN32)
    /*
     * If we don't already have a connection open to a GEOS system, try and
     * open one now.
     */

    /*
     * Look for SWAT_NET variable first, so long as we've not gotten a
     * connection yet and we're not overridden by a -t flag.
     */
    if ((geosFD < 0 && tty == 0) && (getenv("SWAT_NET") != NULL)) {
	geosFD = NetWare_Init(getenv("SWAT_NET"));

	if (geosFD >= 0) {
	    commMode = CM_NETWARE;
	}
    }
    if (geosFD < 0) {
	/*
	 * no netware. no npipe. lets hope serial comes thru.
	 */
	commMode = CM_SERIAL;
# if defined(unix)
	if (modem != 0) {
	    noSig = TRUE;   	/* Assume noone using the modem, so noone to
				 * which to send signals */
	    RpcOpenModem(modem);
	} else {
	    if (tty == 0) {
		char    *ptty = (char *)getenv("PTTY");

		if (ptty == NULL) {
		    /*
		     * Needs to give a -t arg the very first time around
		     * so we know where to spew our garbage
		     */
		    need_tty:

		    MessageFlush("Need a tty for communication "
				 "(-t <dev> you know)\n");
		    if (Ui_Exit) {
			(*Ui_Exit)();
		    }
		    exit(1);
		} else {
		    tty = index(ptty, '/');
		    if (tty == NULL) {
			goto need_tty;
		    }
		    Message("Using %s\n", tty);
		}
	    }
	    geosFD = open(tty, O_RDWR, 0);
	    if ((geosFD < 0) && (errno == ENOENT) && (index(tty, '/') == 0)){
		/*
		 * Couldn't find the beast and there wasn't a path there, try
		 * opening the thing in the /dev/ directory
		 */
		char  realTTY[64];

		sprintf(realTTY, "/dev/%s", tty);
		geosFD = open(realTTY, O_RDWR, 0);
		if (geosFD < 0) {
		    sprintf(realTTY, "/dev/tty%s", tty);
		    geosFD = open(realTTY, O_RDWR, 0);
		}
	    }
	}

	if (geosFD < 0) {
	    /*
	     * Couldn't find the tty the user wants to use, so we can't
	     * do nothin'
	     */
	    MessageFlush("Couldn't open device for reading and writing");
	    if (Ui_Exit) {
		(*Ui_Exit)();
	    }
	    exit(1);
	} else {
	    tty = (char *)ttyname(geosFD);
	    if (tty != NULL) {
		strcpy(ttyName, tty);
	    } else {
		ttyName[0] = '\0';
	    }
	}

# else /* _MSDOS */
	if (tty == 0) {
	    tty = getenv("PTTY");
	    if ((tty == 0) || (tty[0] == '\0')) {
		MessageFlush("Unable to determine serial port to use\n");
		sleep(5);
		if (Ui_Exit) {
		    (*Ui_Exit)();
		}
		exit(1);
	    }
	}
	if (!Serial_Init(tty, 1)) {
	    Message("Unable to reinitialize serial port \"%s\".", tty);
	    if (Ui_Exit) {
		(*Ui_Exit)();
	    }
	    exit(1);
	}
	/*
	 * Arrange for port to be closed before we go away.
	 */
	atexit(Serial_Exit);

	geosFD = 1;		/* Fake descriptor number that won't interfere
				 * with anything... in theory. */
# endif
    }
#else /* now handle _WIN32 */
    if (commMode == CM_NONE) {
	returnCode = Registry_FindStringValue(Tcl_GetVar(interp,
							 "file-reg-swat",
							 TRUE),
					      "COMM_MODE",
					      workbuf,
					      sizeof(workbuf));
	if ((returnCode != FALSE) && (workbuf[0] != '\0')) {
	    if (strcmpi(workbuf, "Serial") == 0) {
		commMode = CM_SERIAL;
	    } else if (strcmpi(workbuf, "Named Pipe") == 0) {
		commMode = CM_NPIPE;
	    } else {
		MessageFlush("Communications mode is not recognized,"
			     " check the setup\n");
		Swat_Death();
	    }
	} else {
	    MessageFlush("Communications mode is not set, check the setup\n");
	    Swat_Death();
	}
    }

    switch (commMode) {
    case CM_NPIPE:
	if (npipe == NULL) {
	    returnCode = Registry_FindStringValue(Tcl_GetVar(interp,
							     "file-reg-swat",
							     TRUE),
						  "NAMED_PIPE",
						  workbuf,
						  sizeof(workbuf));
	    if ((returnCode != FALSE) && (workbuf[0] != '\0')) {
		npipe = workbuf;
	    } else {
		MessageFlush("Named Pipe value is not set, check the setup\n");
		Swat_Death();
	    }
	}
	npipeTries = 0;
    retrynpipe1:
	returnCode = NPipe_ClientInit(npipe, &hCommunication, &overlapRead,
				      &overlapWrite);
	if (returnCode == TRUE) {
	    geosFD = 1;    /* Fake descriptor number that won't interfere
			    * with anything... in theory. */
	    strcpy(npipeName, npipe);
	    /*
	     * Wait to give stub a chance to complete connection
	     */
	    Sleep(500);
	} else {
	    /*
	     * kludge - since stub takes time to get started, try 10 times,
	     *          a max of 2 seconds to connect to the named pipe
	     */
	    if (npipeTries < 10) {
		if (win32dbg == TRUE) {
		    MessageFlush("Waiting for GEOS...");
		}
		npipeTries++;
		Sleep(200);
		goto retrynpipe1;
	    }
	    if (win32dbg == TRUE) {
		char buf[1000];

		WinUtil_SprintError(buf, "NPipe_ClientInit");
		MessageFlush(buf);
		MessageFlush("Pipe name = %s\n", npipe);
	    }
	    MessageFlush("Can't contact GEOS using NT native mode\n");
	    Swat_Death();
	}
	break;
    case CM_SERIAL:
	if (tty == 0) {
	    returnCode = Registry_FindDWORDValue(Tcl_GetVar(interp,
							    "file-reg-ntsdk",
							    TRUE),
						 "SERIAL_COM_PORT", &comport);
	    if (returnCode != FALSE) {
		returnCode = Registry_FindDWORDValue(Tcl_GetVar(interp,
							      "file-reg-ntsdk",
								TRUE),
						     "SERIAL_BAUD_RATE",
						     &baudrate);
		if (returnCode != FALSE) {
		    sprintf(workbuf, "%d,%d", comport, baudrate);
		    tty = workbuf;
		} else {
		    MessageFlush("Serial Baud Rate is not set, "
				 "check the setup\n");
		    Swat_Death();
		}
	    } else {
		MessageFlush("Serial Com Port is not set, check the setup\n");
		Swat_Death();
	    }
	}

	if (Ntserial_Init(&hCommunication, tty, &overlapRead, &overlapWrite)
	    == FALSE) {
	    if (win32dbg == TRUE) {
		char buf[1000];

		WinUtil_SprintError(buf, "Ntserial_Init");
		MessageFlush(buf);
	    }
	    MessageFlush("Can't contact GEOS using the Serial Port: com port"
			 " = %d, baud rate = %d\n", comport, baudrate);
	    Swat_Death();
	}
	strcpy(ttysetting, tty);
	geosFD = 1;    /*
			*Fake descriptor number that won't interfere
			* with anything... in theory.
			*/
	atexit(RpcExitNtSerial);
	break;
    default:
	MessageFlush("No communications mode was specified, "
		     "check the setup\n");
	Swat_Death();
    }
#endif

#if defined(_MSDOS)
    /*
     * try to init the mouse if its not already active
     */
    if (mouseFD < 0) {
	if (MouseStart()) {
	    mouseFD = 2;
	}
    }
#endif

    Cmd_Create(&RpcDebugCmdRec);
    Cmd_Create(&RpcCmdRec);
    Cmd_Create(&RpcSendFileCmdRec);
    Cmd_Create(&Rpc_ReadGeodeCmdRec);
    Cmd_Create(&RpcFindGeodeCmdRec);

    typeGetNextDataBlock =
	Type_CreatePackedStruct("GNDB_size", type_Word,
				0);
    typeReadGeodeArgs =
	Type_CreatePackedStruct("RGA_size", type_Word,
				"RGA_geodeHandle", type_Word,
				"RGA_offset", type_Long,
				"RGA_dataType", type_Word,
				"RGA_dataValue1", type_Word,
				"RGA_dataValue2", type_Word,
				0);

    typeReadGeodeReply =
	Type_CreatePackedStruct("RGR_size", type_Word,
				"RGR_ok", type_Byte, 0);
    typeIndexToOffsetArgs =
	Type_CreatePackedStruct("ITOA_geodeHande", type_Word,
				"ITOA_index", type_Word,
				0);
    typeIndexToOffsetReply =
	Type_CreatePackedStruct("ITOA_offset", type_Word,
				0);
    GC_RegisterType(typeGetNextDataBlock);
    GC_RegisterType(typeReadGeodeArgs);
    GC_RegisterType(typeReadGeodeReply);
    GC_RegisterType(typeIndexToOffsetArgs);
    GC_RegisterType(typeIndexToOffsetReply);

#if 0
    typeRpcHeader = Type_CreatePackedStruct("rh_flags", type_Byte,
					    "rh_procNum", type_Byte,
					    "rh_length", type_Byte,
					    "rh_id", type_Byte,
					    (char *)0);
#endif /* 0 */

#if defined(_WIN32)
    returnCode = Registry_FindDWORDValue(Tcl_GetVar(interp, "file-reg-swat",
						    TRUE),
					 "TIMEOUT_MULTIPLIER", &retryMult);
    if (returnCode != FALSE) {
	if (retryMult > 1) {
	    defaultRetry.tv_sec *= retryMult;
	    MessageFlush("Timeout upped to %d secs\n",
		    defaultRetry.tv_sec);
	}
    }
#endif
}


/***********************************************************************
 *				Rpc_Connect
 ***********************************************************************
 * SYNOPSIS:	    Reconnect to the PC, taking over control of the tty
 * CALLED BY:	    IbmConnectCmd, Rpc_Init
 * RETURN:	    successful connecting
 * SIDE EFFECTS:    The tty's terminal modes be changed a lot...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
Boolean
Rpc_Connect(void)
{

#if defined(unix)
    struct sgttyb   sgb;
    struct tchars   tc;
    struct ltchars  ltc;    int	    	    local;

    /*
     * Re-open the terminal if it was closed before.
     */
    if (geosFD < 0) {
	geosFD = open(ttyName, O_RDWR, 0);
	if (geosFD < 0) {
	    MessageFlush("Couldn't re-open tty for reading and writing");
	    if (Ui_Exit) {
		(*Ui_Exit)();
	    }
	    exit(1);
	}
	/*
	 * Register all the servers for the stream that were here before.
	 */
	rpcServers[geosFD] = geosServers;
    }

    /*
     * See if the thing is actually a tty and set it up for our use
     * if it is. If the TIOCGETP returns ok, the line is a tty.
     */
    if (ioctl(geosFD, TIOCGETP, &sgb) == 0) {
	(void)ioctl(geosFD, TIOCGETC, &tc);
	(void)ioctl(geosFD, TIOCGLTC, &ltc);
	(void)ioctl(geosFD, TIOCLGET, &local);

	sgb.sg_flags |= RAW;
	sgb.sg_flags &= ~(ECHO|XTABS|CBREAK);
	local |= LLITOUT|LPASS8|LDECCTQ;
	local &= ~(LTOSTOP|LMDMBUF|LTILDE);

	tc.t_intrc = tc.t_quitc = tc.t_eofc = tc.t_brkc =
	    tc.t_startc = tc.t_stopc = ltc.t_suspc = ltc.t_dsuspc =
		ltc.t_flushc = ltc.t_werasc = ltc.t_lnextc = -1;

	(void)ioctl(geosFD, TIOCSETP, &sgb);
	(void)ioctl(geosFD, TIOCSETC, &tc);
	(void)ioctl(geosFD, TIOCSLTC, &ltc);
	(void)ioctl(geosFD, TIOCLSET, &local);
/*	(void)ioctl(geosFD, TIOCEXCL, 0);  */

	/*
	 * Send an IOT signal to the pcwin on the terminal to tell
	 * it to shut up.
	 */
	if (!noSig) {
	    int	pgrp;

	    (void)ioctl(geosFD, TIOCGPGRP, &pgrp);

	    if (pgrp != 0 && pgrp != getpid()) {
		if (kill(pgrp, SIGIOT) < 0) {
		    extern char *sys_errlist[];
		    extern int	errno;

		    /*
		     * Don't bitch if we don't have permission -- assume that
		     * if we were able to open the device, the dude has a
		     * hacked shell script keeping the port open and at a
		     * specific baud rate, and we just don't have the right
		     * to send it a signal. No big wup.
		     */
		    if (errno != EPERM) {
			Warning("kill(%d): %s", pgrp, sys_errlist[errno]);
		    }
		}
	    }
	}
    }

#elif defined(_WIN32)
    int returnCode = FALSE;
    int npipeTries;

    if ((geosFD < 0) && (commMode == CM_NPIPE)) {
	if (win32dbg == TRUE) {
	    MessageFlush("\nreconnecting and initializing the named pipe...");
	}
	npipeTries = 0;
    retrynpipe2:
        returnCode = NPipe_ClientInit(npipeName, &hCommunication,
				      &overlapRead, &overlapWrite);
	if (win32dbg == TRUE) {
	    MessageFlush("done\n");
	}
        if (returnCode == TRUE) {
	    geosFD = 1;		/*
				 * Fake descriptor number that won't
				 * interfere with anything... in
				 * theory.
				 */
	    incomingRead = FALSE;
	    outstandingRead = FALSE;
	    /*
	     * Wait to give stub a chance to complete connection
	     */
	    Sleep(2000);
	} else {
	    /*
	     * kludge - since stub takes time to get started, try 10 times,
	     *          a max of 2 seconds to connect to the named pipe
	     */
	    if (npipeTries < 10) {
		Sleep(200);
		if (win32dbg == TRUE) {
		    MessageFlush("Waiting for GEOS...");
		}
		npipeTries++;
		goto retrynpipe2;
	    }
	    if (win32dbg == TRUE) {
		char buf[1000];

		WinUtil_SprintError(buf, "NPipe_ClientInit");
		MessageFlush(buf);
		MessageFlush("Pipe name = %s\n", npipeName);
	    }
	    MessageFlush("Can't contact GEOS using NT native mode\n");
	    return FALSE;
	}
	/*
	 * Register all the servers for the stream that were here before.
	 */
	rpcServers[geosFD] = geosServers;
    }
    if ((geosFD < 0) && (commMode == CM_SERIAL)) {
	Ntserial_Exit(&hCommunication, &overlapRead, &overlapWrite);

	if (win32dbg == TRUE) {
	    MessageFlush("\nreconnecting and initializing the com port...");
	}
	returnCode = Ntserial_Init(&hCommunication, ttysetting, &overlapRead,
				&overlapWrite);
	if (win32dbg == TRUE) {
	    MessageFlush("done\n");
	}
	if (returnCode == TRUE) {
	    geosFD = 1;		/*
				 * Fake descriptor number that won't
				 * interfere with anything... in
				 * theory.
				 */
	    incomingRead = FALSE;
	    outstandingRead = FALSE;
	} else {
	    if (win32dbg == TRUE) {
		char buf[1000];

		WinUtil_SprintError(buf, "Ntserial_Init");
		MessageFlush(buf);
	    }
	    MessageFlush("Couldn't contact GEOS over the Serial Port: %s\n",
			 ttysetting);
	    return FALSE;
	}
	/*
	 * Register all the servers for the stream that were here before.
	 */
	rpcServers[geosFD] = geosServers;
    }

#endif

    /*
     * Pay attention to the stream if there are servers already registered
     * for it...
     */
    if (rpcServers[geosFD]) {
	rpcState = RPC_STATE_SYNC;
	Rpc_Watch(geosFD, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);
    }
    return TRUE;
}


/***********************************************************************
 *				Rpc_Disconnect
 ***********************************************************************
 * SYNOPSIS:	    Disconnect from the PC, relinquishing control of the tty
 * CALLED BY:	    IbmDetachCmd, IbmQuitCmd
 * RETURN:	    successful disconnecting
 * SIDE EFFECTS:    The tty's owner is sent a signal 31
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
Boolean
Rpc_Disconnect(int wakeup)
{
    RpcServer   *s;

    if (geosFD < 0) {
	return FALSE;
    }

    Rpc_Ignore(geosFD);

    /* save away the gesoServers if we need them or not, just in case */
    geosServers = rpcServers[geosFD];
#if defined(unix)
    /*
     * Close and reset the tty...
     */
    if (!noSig && wakeup) {
	int	pgrp;

	(void)ioctl(geosFD, TIOCGPGRP, &pgrp);

	if (pgrp != 0 && pgrp != getpid()) {
	    if (kill(pgrp, 31) < 0) {
		extern char *sys_errlist[];
		extern int  errno;

		/*
		 * Don't bitch if we don't have permission -- assume that
		 * if we were able to open the device, the dude has a
		 * hacked shell script keeping the port open and at a
		 * specific baud rate, and we just don't have the right
		 * to send it a signal. No big wup.
		 */
		if (errno != EPERM) {
		    Warning("kill(%d): %s", pgrp, sys_errlist[errno]);
		}
	    }
	}
    }
    /*
     * If we know we can re-open the thing later, close down the stream
     * to the terminal. This keeps us from getting nailed if the person
     * logs out (or is logged out by circumstances)
     */
    if (!isModem && ttyName[0] != '\0') {
	/*
	 * Save all the servers registered for the stream for re-attach.
	 */
	rpcServers[geosFD] = (RpcServer *)0;
	/*
	 * Now close the beast down.
	 */
	close(geosFD);
	geosFD = -1;
    }
#elif defined(_WIN32)
    if ((geosFD >= 0) && (commMode == CM_NPIPE)) {
	/*
	 * Save all the servers registered for the stream for re-attach.
	 */
	rpcServers[geosFD] = (RpcServer *)0;
	/*
	 * Now close the beast down.
	 */
	if (win32dbg == TRUE) {
	    MessageFlush("\ndisconnecting and closing the named pipe...");
	}
        NPipe_ClientExit(&hCommunication, &overlapRead, &overlapWrite);
	if (win32dbg == TRUE) {
	    MessageFlush("done\n");
	}
	geosFD = -1;
	incomingRead = FALSE;
	outstandingRead = FALSE;
    } else if ((geosFD >= 0) && (commMode == CM_SERIAL)) {
	/*
	 * Save all the servers registered for the stream for re-attach.
	 */
	rpcServers[geosFD] = (RpcServer *)0;
	/*
	 * Now close the beast down.
	 */
	if (win32dbg == TRUE) {
	    MessageFlush("\ndisconnecting and closing the com port...");
	}
	Ntserial_Exit(&hCommunication, &overlapRead, &overlapWrite);
	if (win32dbg == TRUE) {
	    MessageFlush("done\n");
	}
	geosFD = -1;
	incomingRead = FALSE;
	outstandingRead = FALSE;
    }
#endif

    /*
     * Clear out their call caches so we start afresh next time..
     */
    for (s = geosServers; s != NULL; s = s->next) {
	RpcCacheDestroy(s);
	bzero((char *)s->cache, sizeof(s->cache));
    }
    return TRUE;
}


/***********************************************************************
 *				Rpc_Exit
 ***********************************************************************
 * SYNOPSIS:	    Dismantle the RPC system in preparation for exit.
 * CALLED BY:	    IbmQuitCmd, Ibm_PingPC
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A final RPC is sent -- no reply is expected.
 *
 * STRATEGY:	    Put together the given rpc and send it, reset the
 *	    	    tty (later) and return.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/23/88	Initial Revision
 *
 ***********************************************************************/
void
Rpc_Exit(Rpc_Proc   exitProcNum)    	/* Procedure to call for the exit */
{
    RpcHeader	    header;

    /*
     * Put together the final RPC
     */
    header.rh_id = RpcUniqueID();
    header.rh_procNum = exitProcNum;
    header.rh_length = 0;
    header.rh_flags = RPC_CALL;

    /*
     * Swap it if necessary
     */
#if 0
    if (swap) {
	Var_SwapValue(VAR_STORE, typeRpcHeader, sizeof(header),
		      (genptr)&header);
    }
#endif 0
    /*
     * Send it down the line.
     */
    while((RpcSend(geosFD, &header, sizeof(header)) < 0) &&
	  (errno == EINTR))
    {
	;
    }
}


/***********************************************************************
 *				Rpc_Send
 ***********************************************************************
 *
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	???	???	   	Initial Revision
 *
 ***********************************************************************/
void
Rpc_Send(Rpc_Proc   exitProcNum)    	/* Procedure to call for the exit */
{
    RpcHeader	    header;

    /*
     * Put together the final RPC
     */
    header.rh_id = RpcUniqueID();
    header.rh_procNum = exitProcNum;
    header.rh_length = 0;
    header.rh_flags = RPC_CALL;

    /*
     * Swap it if necessary
     */
#if 0
    if (swap) {
	Var_SwapValue(VAR_STORE, typeRpcHeader, sizeof(header),
		      (genptr)&header);
    }
#endif /* 0 */

    /*
     * Send it down the line.
     */
    while((RpcSend(geosFD, &header, sizeof(header)) < 0) &&
	  (errno == EINTR))
    {
	;
    }

/*    (void)ioctl(geosFD, TIOCNXCL, 0);*/
}	/* End of Rpc_Send.	*/


#if defined(_WIN32)
/***********************************************************************
 *				RpcExitNtSerial
 ***********************************************************************
 *
 * SYNOPSIS:	    calls exit routine for nt serial with handle
 * CALLED BY:	    atexit
 * RETURN:	    void
 * SIDE EFFECTS:    closes serial port
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	12/02/96   	Initial Revision
 *
 ***********************************************************************/
void
RpcExitNtSerial(void)
{
    Ntserial_Exit(&hCommunication, &overlapRead, &overlapWrite);
}	/* End of RpcExitNtSerial.	*/
#endif

#if REGS_32
/***********************************************************************
 *			RegisterMapping
 ***********************************************************************
 *
 * SYNOPSIS:	    Convert REG_?X to reg_?x.  The mapping is no longer
 *                  one to one when using 32 bit registers.
 * RETURN:	    int
 * SIDE EFFECTS:    NOTE:  Don't map REG_IP through this routine,
 *                  it'll return (E)AX
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	les	07/10/00   	Initial Revision
 *
 ***********************************************************************/
/* Convert REG_AX types to reg_ax types */
int RegisterMapping(int regIndex)
{
    static int mapping[] = {
        reg_ax,
        reg_cx,
        reg_dx,
        reg_bx,

        reg_sp,
        reg_bp,
        reg_si,
        reg_di,

        reg_es,
        reg_cs,
        reg_ss,
        reg_ds,

        /* Lower half (?L, 8-bits) */
        reg_ax,
        reg_bx,
        reg_cx,
        reg_dx,

        /* Upper half (?H vars, 8-bits) */
        reg_ax,
        reg_bx,
        reg_cx,
        reg_dx,

        /* Ip */
        0,

        /* 32-bit registers */
        reg_ax,
        reg_cx,
        reg_dx,
        reg_bx,

        reg_sp,
        reg_bp,
        reg_si,
        reg_di,

        /* FS, GS, and EIP */
        reg_fs,
        reg_gs,
        0
    } ;

    if (regIndex < (sizeof(mapping)/sizeof(mapping[0])))
        return (mapping[regIndex]/2) ;

    return regIndex ; /* LES!!! Need a warning or something here */
}
#endif
