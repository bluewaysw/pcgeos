/*-
 * rpc.c --
 *	Remote Procedure Call and timeout mechanism for customs.
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
#if defined(unix)
#ifndef lint
static char *rcsid =
"$Id: rpc.c,v 1.7 93/01/30 15:38:28 adam Exp $ SPRITE (Berkeley)";
#endif lint

/*
 * The RPC mechanism implemented in this file was designed for the customs
 * agent. It supports both udp and tcp transport and requires the complete
 * address of the destination each time (for udp). It also supports broadcast
 * messages as required.
 *
 * A server is created for any <socket, procNum> pair using the function
 * Rpc_ServerCreate(socket, procNum, handleProc, swapArgsProc, swapReplyProc,
 * handleData). The handler function may be called at any time, even while a
 * call is being made on another socket, so handlers should be written
 * accordingly.
 *
 * Two swapping procedures may be provided to byte-swap the call arguments and
 * reply data should the byteorder of the calling host be different from that
 * on the local host. If no data are passed and/or returned, or swapping
 * isn't necessary, Rpc_SwapNull may be given.
 *
 * The system is organized around an event queue and select masks. Events
 * occur at scheduled times with the process sleeping in between events by
 * waiting on a set of streams, as defined by the select masks. Multiple calls
 * may be pending -- each one has an event for resending and replies are
 * handled by the selection mechanism. The event queue is ordered by timeout
 * time. The function Rpc_Wait is what processes the queue and calls the
 * various handlers. Everything here eventually makes its way back to
 * Rpc_Wait.
 *
 * Each stream may have only one function to handle its readiness. Thus a
 * program should not express interest in the stream unless it has unregistered
 * interest in all rpc services on that stream.
 *
 * <remaddr, remport, sock, procnum, message-id> is a 5-tuple that uniquely
 * identifies a given RPC call. This tuple is used for caching calls and
 * responses to them.
 *
 * The protocol relies on the acknowledgement implicit in the return of
 * data. Every service routine must call Rpc_Return() at least once, even
 * if no data are to be returned. The only time an explicit acknowledgement
 * packet is sent is when a duplicate call is received for one that is
 * currently being processed. The acknowledgement indicates that the client
 * is to continue waiting and resending at whatever interval it chooses.
 */

#define FD_SETSIZE  256		/* Make sure this is big enough for both */
				/* Sun and ISI... */

#include    <sys/time.h>
#include    <sys/ioctl.h>
#include    <sys/types.h>
#include    <sys/socket.h>
#include    <sys/file.h>
#include    <netinet/in.h>
#include    <net/if.h>
#include    <arpa/inet.h>
#include    <sys/uio.h>
#include    <errno.h>
#include    <stdio.h>
#include    <setjmp.h>
#include    <sys/signal.h>
#include    <assert.h>

extern int errno;		/* Not all systems define this */

#include    "rpc.h"


#ifndef MAX_DATA_SIZE
#define MAX_DATA_SIZE	2048
#endif  /* MAX_DATA_SIZE */

#ifndef MAXNETS
#define MAXNETS	    	10  	/* Maximum number of networks a machine may
				 * be on (Max # Rpc_Broadcast will broadcast
				 * to, anyway) */
#endif /* MAXNETS */
/*
 * Macro for adding two time values together into a third.
 */
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
 * Timeout for receiving something more from a TCP packet.
 */
#define RPC_TCP_RECV_RETRY  	4
#define RPC_TCP_RECV_URETRY 	0

/*
 * Macro to deal with incompatible calling conventions between gcc and cc on
 * a sparc (gcc passes the address in a register, since the structure is
 * small enough, while cc still passes the address).
 */
#if defined(__GNUC__) && defined(sparc)
#define InetNtoA(addr)	inet_ntoa(&(addr))
#else
#define InetNtoA(addr)	inet_ntoa(addr)
#endif

/*
 * The ID of a message is simply an unsigned long that increments for each
 * message.
 */
typedef unsigned long RpcID;
#define RpcIDEqual(id1, id2)	(id1 == id2)
#define RpcHash(id)	    	(((id) ^ (id >> 3) ^ (id >> 9)) & \
				 (CACHE_THREADS-1))

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
	REPLY_NOT_SENT,			/* Reply not sent, as call was
					 * broadcast. */
    }	    	  	status;	    /* Status of call */
    RpcID   	  	id; 	    /* ID of call */
    struct sockaddr_in	from;	    /* Where call came from */
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
/*
 * The MsgHeader is prepended to each out-going message and is expected to
 * be present on each incoming message on a service stream. All fields
 * larger than a byte are presented in network-byte-order (except the id,
 * which is unique in any byte-order, so long as the byte-order is consistent).
 * Only one of the message type bits may be on at once.
 */
typedef struct {
    RpcID   	  	id; 	    /* Message id */
    u_long  	  	byteOrder;  /* Magic number indicating the byte order
				     * of the sending host. */
    Rpc_Proc   	  	procNum;    /* Procedure number */
    short   	  	flags;	    /* Flags */
    	    	  	    	    	/* MESSAGE TYPES: */
#define RPC_CALL  	0x0001   	/* Message is a call */
#define RPC_REPLY 	0x0002   	/* Message is a reply */
#define RPC_ERROR 	0x0004   	/* Message is an error reply. Status
					 * is message data */
#define RPC_ACKNOWLEDGE	0x0008	    	/* Message is acknowledgement, not
					 * reply, indicating service still
					 * in progress */
    	    	  	    	    	/* MODIFIERS: */
#define RPC_BROADCAST	0x0100   	/* Message is broadcast, so don't
					 * reply with errors */
    int	    	  	length;	    /* Length of following data */
} MsgHeader;

#define RpcTypeMask	    (RPC_CALL|RPC_REPLY|RPC_ERROR|RPC_ACKNOWLEDGE)
#define RpcIsCall(hdrPtr)   (((hdrPtr)->flags&RpcTypeMask)==RPC_CALL)
#define RpcIsReply(hdrPtr)  (((hdrPtr)->flags&RpcTypeMask)==RPC_REPLY)
#define RpcIsError(hdrPtr)  (((hdrPtr)->flags&RpcTypeMask)==RPC_ERROR)
#define RpcIsAck(hdrPtr)    (((hdrPtr)->flags&RpcTypeMask)==RPC_ACKNOWLEDGE)

#define RPC_MAGIC 	0x03020100  /* Magic number placed in byteOrder
				     * field of outgoing message to indicate
				     * sending host's byte order */

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
    struct sockaddr_in	remote;	    /* Address of responder */
    int	    	  	replyLen;   /* Expected length of reply */
    Rpc_Opaque 	  	reply;	    /* Place to store reply data */
    Boolean    	  	replied;    /* Reply received */

    /*
     * Information for issuing the call.
     */
    int	    	  	sock;	    /* Socket over which to make the call */
    struct msghdr 	message;    /* Outgoing message */
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
    void    	  	(*swapArgsProc)();    	/* Function to swap args */
    void		(*swapReplyProc)(); 	/* Function to swap reply */
    Rpc_Opaque 	  	data;	    	    	/* Datum to pass procs */
    CacheEntry	  	*cache[CACHE_THREADS];	/* Call cache */
} RpcServer;

/*
 * The RpcMessage structure contains all the information needed to reply to
 * an rpc call.
 */
typedef struct RpcMessage {
    MsgHeader	  	*header;    	/* Original message header */
    struct sockaddr_in	*remote;    	/* Address of caller */
    int	    	  	sock;	    	/* Socket on which to reply */
    CacheEntry	  	*e; 	    	/* Entry in server cache to modify */
    RpcServer		*server;	/* Server for message (so we can
					 * swap the reply) */
} RpcMessage;

static RpcServer  	*rpcServers[FD_SETSIZE];

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
    struct timeval	timeout;    	/* Time at which event should occur */
    struct timeval	interval;   	/* Interval at which event should
					 * recur. */
    Boolean    	  	(*handler)();	/* Function to be called at timeout */
    Rpc_Opaque 	  	data;	    	/* Datum to pass it */
} RpcEvent;

static RpcEvent	  	*events;    	/* All waiting events */

/*
 * The 'streams' array contains the information needed to handle the readiness
 * of a stream. The 'state' field is set from the arguments to Rpc_Watch and
 * is used to remove the stream from the select masks when interest in it
 * changes. If 'state' is 0, noone is interested in the stream.
 */
static struct {
    int	    	  	state; 	    	/* Current interest */
    void    	  	(*handler)();	/* Function to handle readiness */
    Rpc_Opaque 	  	data;	    	/* Datum to pass to handler */
} 	    	  	streams[FD_SETSIZE];

fd_set	    	  	rpc_readMask;	/* Readable stream select mask */
fd_set			rpc_writeMask;	/* Writeable stream select mask */
fd_set			rpc_exceptMask;	/* Exceptable stream select mask */

/*
 * MISCELLANEOUS DEFINITIONS
 */
static Boolean	  	rpcDebug;   	/* Print debugging info */
static void 	  	RpcTcpAccept();	/* Perform ACCEPT on TCP RPC socket */

static int		rpcWaitSeq = 0;	/* Sequence number for current Rpc_Wait
					 * so we can tell if a call to a
					 * handler caused us to be called
					 * back, which invalidates our
					 * select results */
/*
 * Interval for flushing a call entry from the cache
 */
static struct timeval	flushTimeOut = {
    10, 0
};

/*-
 *-----------------------------------------------------------------------
 * RpcUniqueID --
 *	Return an unique identifier for a message. Potential clashes
 *	between hosts are reduced by using a random number on startup.
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
RpcUniqueID()
{
    static RpcID  nextID = 0;

    if (nextID == 0) {
	srandom(time(0) ^ getpid());
	nextID = random();
    } else {
	nextID += 1;
    }
    return (nextID);
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
RpcCacheFlushEntry(e, ev)
    register CacheEntry	*e; 	/* Entry to flush */
    Rpc_Event	  	ev; 	/* Event that caused this call */
{
    if (rpcDebug) {
	printf("Flushing entry for %u\n", e->id);
    }
    
    /*
     * If reply hasn't even been sent yet, we certainly shouldn't flush
     * the entry from the cache. Instead, we return True in a vain attempt
     * to get back to the server procedure.
     */
    if (e->status == REPLY_PENDING) {
	Rpc_EventReset(e->flushEvent, &flushTimeOut);
	return (True);
    }

    if ((e->flushEvent != ev) /* && rpcDebug */) {
	printf("RpcCacheFlushEntry: flushEvent (%x) != ev (%x)\n",
	       e->flushEvent, ev);
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
RpcCacheDestroy(s)
    RpcServer	  	*s;    /* The server whose cache should be destroyed */
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
RpcCacheFind(server, from, id, create, entryNewPtr)
    RpcServer	  	*server;    	/* Server in whose cache the call
					 * should be sought */
    register struct sockaddr_in	*from; 	/* Origin of the call */
    RpcID   	  	id; 	    	/* ID number of the call */
    Boolean 	  	create;	    	/* True if should create an entry
					 * if we don't find it */
    Boolean 	  	*entryNewPtr;	/* Set True if a new entry was
					 * created */
{
    register CacheEntry	*e;
    register int  	chain;

    chain = RpcHash(id);
    e = server->cache[chain];
 
    /*
     * Look for existing cache entry.
     */
    if (rpcDebug) {
	printf("RpcCacheFind: seeking %d@%s #%u...",
	       ntohs(from->sin_port),
	       InetNtoA(from->sin_addr),
	       id);
    }
    while (e != (CacheEntry *)0) {
	if ((e->from.sin_addr.s_addr == from->sin_addr.s_addr) &&
	    (e->from.sin_port == from->sin_port) &&
	    (RpcIDEqual(id, e->id))) {
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
	    if (rpcDebug) {
		printf("creating new entry\n");
	    }
	    e = (CacheEntry *)malloc(sizeof(CacheEntry));
	    e->id = 	    id;
	    e->from =	    *from;
	    e->status =     REPLY_PENDING;
	    e->flushEvent = (Rpc_Event)NULL;
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
	    if (rpcDebug) {
		printf("returning NULL\n");
	    }
	    return ((CacheEntry *)NULL);
	}
    } else if (entryNewPtr != (Boolean *)NULL) {
	/*
	 * No new entry created -- mark *entryNewPtr false to indicate this
	 */
	if (rpcDebug) {
	    printf("found it\n");
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
RpcCheckStreams()
{
    register int  	stream;
    register RpcCall 	*call;

    /*
     * For each stream that someone is interested in, perform an innocuous
     * lseek on it just to see if the descriptor itself is valid (if the
     * stream is unseekable, we'll get an EINVAL error). If the descriptor
     * is bad, clear it out of all the select masks and set its state to 0.
     */
    for (stream=0; stream < FD_SETSIZE; stream++){
	if (streams[stream].state) {
	    errno = 0;
	    if ((lseek(stream, 0, L_INCR) < 0) &&
		(errno == EBADF))
	    {
		if (rpcDebug) {
		    printf("%d bad\n", stream);
		    fflush(stdout);
		}
		FD_CLR(stream, &rpc_readMask);
		FD_CLR(stream, &rpc_writeMask);
		FD_CLR(stream, &rpc_exceptMask);
		streams[stream].state = 0;

		/*
		 * Mark all the calls on this stream as failed.
		 *
		 * XXX: What about servers?
		 */
		for (call = rpcCalls[stream];
		     call != (RpcCall *)NULL;
		     call = call->next)
		{
		    call->replied = True;
		    call->status = RPC_CANTSEND;
		}
	    }
	}
    }
}

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
/*ARGSUSED*/
static void
RpcHandleStream(stream, data, what)
    int	    	  	stream;   	/* Stream that's ready */
    Rpc_Opaque 	  	data;	    	/* Data we stored (UNUSED) */
    int	    	  	what;	    	/* What it's ready for (UNUSED) */
{
    struct sockaddr_in	remote;	    	/* Address of sender */
    int	    	  	remotelen;  	/* size of 'remote' (for recvfrom) */
    struct {
	MsgHeader 	    header;
	unsigned char	    buf[MAX_DATA_SIZE];
    }	    	  	message;    	/* Place for the message coming in */
    int	    	  	msgLen;	    	/* Length of actual message */

    /*
     * Keep trying to read the message as long as the recvfrom call is
     * interrupted.
     */
    do {
	remote.sin_addr.s_addr = 0;
	remotelen = sizeof(remote);
	msgLen = recvfrom(stream, (char *)&message, sizeof(message), 0,
			  (struct sockaddr *)&remote, &remotelen);
    } while ((msgLen < 0) && (errno == EINTR));
    
    /*
     * recvfrom may not actually return the address for a connected tcp stream.
     * Since we need the beastie, we must query the system by hand in such a
     * case.
     */
    if ((msgLen > 0) && (remote.sin_addr.s_addr == 0)) {
	remotelen = sizeof(remote);
	if ((getpeername(stream, (struct sockaddr *)&remote,
			 &remotelen) < 0) ||
	    (remote.sin_addr.s_addr == 0))
	{
	    if (rpcDebug) {
		printf ("Could not get address of caller\n");
	    }
	    return;
	}
    }
    
    if (msgLen < (int)sizeof(MsgHeader)) {
	if (msgLen < 0) {
	    if (errno == ENOTCONN) {
		/*
		 * The stream must be a passive TCP socket. Accept on it
		 * to create a new rpc socket...
		 */
		RpcTcpAccept(stream);
	    } else {
		perror("recvfrom");
	    }
	} else if (msgLen == 0) {
	    /*
	     * If we received an end-of-file, we assume the service is at
	     * an end and close the thing down...Any pending calls are
	     * marked timed out, since we won't be able to receive any
	     * replies on this socket.
	     */
	    register RpcServer	*s;
	    register RpcCall	*c;

	    if (rpcDebug) {
		printf("EOF on %d -- closing\n", stream);
	    }

	    for (s = rpcServers[stream];
		 s != (RpcServer *)0;
		 s = rpcServers[stream]) {
		     RpcCacheDestroy(s);
		     rpcServers[stream] = s->next;
		     free((char *)s);
	    }
	    for (c = rpcCalls[stream];
		 c != (RpcCall *)0;
		 c = rpcCalls[stream]) {
		     c->replied = True;
		     c->status = RPC_TIMEDOUT;
		     rpcCalls[stream] = c->next;
	    }
	    
	    Rpc_Ignore(stream);
	    (void) close(stream);
	} else if(rpcDebug) {
	    printf("Incomplete header received (%d bytes)\n", msgLen);
	}
	return;
    }

    /*
     * Message received. Byte swap the header to match the local machine's
     * byte-order.
     */
    message.header.id =     	ntohl(message.header.id);
    message.header.procNum =	ntohs(message.header.procNum);
    message.header.flags =	ntohs(message.header.flags);
    message.header.length =	ntohl(message.header.length);

    while (msgLen - (int)sizeof(MsgHeader) < message.header.length) {
	/*
	 * This must be a TCP socket. Try reading until we have all of the
	 * message. -- stolcke@icsi.berkeley.edu
	 */
	fd_set	    	fds;
	struct timeval	tv;
	int 	    	result;

	FD_ZERO(&fds);
	FD_SET(stream, &fds);

	tv.tv_sec = RPC_TCP_RECV_RETRY;
	tv.tv_usec = RPC_TCP_RECV_URETRY;
	
	result = select(stream+1, &fds, NULL, NULL, &tv);

	if (result < 0) {
	    perror("select");
	} else if (result == 0) {
	    if (rpcDebug) {
		printf("select: timed out after %d.%06d seconds\n",
		       tv.tv_sec, tv.tv_usec);
	    }
	} else {
	    result = recv(stream, (char *)&message+msgLen,
			  message.header.length + sizeof(MsgHeader) - msgLen,
			  0);
	    if (result < 0) {
		perror("recv");
	    }
	}
	if (result <= 0) {
	    if (rpcDebug) {
		printf ("Incomplete message received: was %d, s/b %d\n",
			msgLen - sizeof(MsgHeader),
			message.header.length);
	    }
	    return;
	}

	if (rpcDebug) {
	    printf("Continuation message (%d bytes) received.\n", result);
	}

	msgLen += result;
    }

    if (RpcIsCall(&message.header)) {
	/*
	 * Find server and call out.
	 */
	register RpcServer  *server;
	RpcMessage	    msg;
	CacheEntry	    *e;
	Boolean	  	    isNew;

	msg.header = &message.header;
	msg.remote = &remote;
	msg.sock   = stream;
	msg.e	   = (CacheEntry *)NULL;
	
	if (rpcDebug) {
	    printf("Call on %d: id %u procedure %d\n",
		   stream,
		   message.header.id,
		   message.header.procNum);
	}
	
	for (server = rpcServers[stream];
	     server != (RpcServer *)0;
	     server = server->next)
	{
	    if (server->procNum == message.header.procNum) {
		break;
	    }
	}
	if (server == (RpcServer *)0) {
	    if (rpcDebug) {
		printf("No such procedure\n");
	    }
	    Rpc_Error((Rpc_Message)&msg, RPC_NOPROC);
	    return;
	}
	    
	/*
	 * XXX: Should do more error checking (e.g. does length match?)
	 */
	e = RpcCacheFind(server, &remote, message.header.id, True, &isNew);
	msg.e = e;
	
	if (isNew) {
	    msg.server = server;
	    /*
	     * Check their byte-order against ours and call the swap procedure
	     * if it's not the same.
	     */
	    if ((message.header.byteOrder != RPC_MAGIC) &&
		(server->swapArgsProc != Rpc_SwapNull))
	    {
		(* server->swapArgsProc) (message.header.length,
					  (Rpc_Opaque)message.buf,
					  server->data);
	    }

	    (* server->serverProc) (&remote, (Rpc_Message)&msg,
				    message.header.length,
				    (Rpc_Opaque)message.buf,
				    server->data);

	    /*
	     * Make sure the server generated some reply. If not, generate
	     * a null-reply. Note we don't do this for broadcast messages
	     * as they only get explicit replies -- the server may just have
	     * decided the message wasn't really for it. Broadcasts are
	     * rather general, after all.
	     */
	    if (e->status == REPLY_PENDING){
		if ((message.header.flags & RPC_BROADCAST) == 0) {
		    printf("No reply sent for call %u to procedure %d on %d\n",
			   message.header.id,
			   message.header.procNum,
			   stream);
		    printf("Generating zero-length reply...\n");
		    Rpc_Return((Rpc_Message)&msg, 0, (Rpc_Opaque)NULL);
		} else {
		    /*
		     * So RpcCacheFlushEntry knows it's ok to flush the thing.
		     */
		    e->status = REPLY_NOT_SENT;
		}
	    }
	    /*
	     * Now the call has been handled, it is a good time to set the
	     * flush timer for the cache entry.
	     */
	    e->flushEvent = Rpc_EventCreate(&flushTimeOut,
					    RpcCacheFlushEntry,
					    (Rpc_Opaque)e);
	} else {
	    if (e->status == REPLY_PENDING) {
		/*
		 * This call is already being serviced. Return an explicit
		 * acknowledgement to the sender to let it know we're still
		 * alive and working, then drop the request. This is *not*
		 * done for broadcast requests -- if a reply is needed,
		 * it is done explicitly or not at all.
		 */
		register MsgHeader  *header;
		int	    	    numBytes;

		if (rpcDebug) {
		    printf("call cached: sending ACK\n");
		}
		header = &message.header;
		if ((header->flags & RPC_BROADCAST) == 0) {
		    header->procNum = htons(header->procNum);
		    header->flags ^= (RPC_ACKNOWLEDGE|RPC_CALL);
		    header->flags = htons(header->flags);
		    header->length = 0;
		    
		    do {
			numBytes = sendto(stream,
					  (char *)header, sizeof(MsgHeader),
					  0,
					  (struct sockaddr *)&remote,
					  sizeof(remote));
		    } while ((numBytes < 0) && (errno == EINTR));
		}
	    } else if (e->status == REPLY_SENT) {
		/*
		 * A reply has already been sent for this call. We use
		 * Rpc_Return to return the data already sent. Note
		 * that Rpc_Return can tell when it's a resend by the status
		 * being REPLY_SENT...Again, the request is dropped.
		 */
		if (e->error == RPC_SUCCESS) {
		    if(rpcDebug) {
			printf("%d byte reply cached: resending\n",
			       e->replySize);
		    }
		    Rpc_Return((Rpc_Message)&msg, e->replySize, e->replyData);
		} else {
		    if (rpcDebug) {
			printf("error %d cached: resending\n", e->error);
		    }
		    Rpc_Error((Rpc_Message)&msg, e->error);
		}
	    }
	}
    } else {
	/*
	 * It's a reply of some sort. Find the associated call...
	 */
	register RpcCall    *call;
	register RpcCall    **prev;

	if (rpcDebug) {
	    printf ("Reply to %u: ", message.header.id);
	}
	
	prev = &rpcCalls[stream];
	for (call = rpcCalls[stream]; call != (RpcCall *)0; call = call->next){
	    if (RpcIDEqual(message.header.id, call->id)) {
		break;
	    } else {
		prev = &call->next;
	    }
	}
	if (call != (RpcCall *)0) {
	    switch (message.header.flags & RpcTypeMask) {
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
		    if (message.header.length > call->replyLen) {
			call->status = RPC_TOOBIG;
			if (rpcDebug) {
			    printf("too big\n");
			}
		    } else {
			if (message.header.length != 0) {
			    bcopy ((char *)message.buf,
				   (char *)call->reply,
				   message.header.length);
			}
			call->replyLen = message.header.length;
			if (rpcDebug) {
			    printf ("%d bytes received\n",
				    message.header.length);
			}
			call->status = RPC_SUCCESS;
		    }
		    break;
		case RPC_ERROR:
		    /*
		     * The message is an error reply. The data for the message
		     * are the return status for the call -- in network byte
		     * order -- and we copy it directly into call->status.
		     */
		    call->status = *(Rpc_Stat *)message.buf;
		    call->status = ntohl(call->status);
		    if (rpcDebug) {
			printf ("error %d\n", call->status);
		    }
		    break;
		case RPC_ACKNOWLEDGE:
		    /*
		     * Server is acknowledging our call. Up the number of
		     * retries allowed for the call once for each
		     * acknowledegment received. This effectively forgets
		     * we ever resent the request.
		     */
		    if (rpcDebug) {
			printf ("ACK\n");
		    }
		    call->numRetries += 1;
		    return;
		default:
		    if (rpcDebug) {
			printf("bogus message received on %d\n", stream);
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
	    call->remote = remote;
	} else {
	    if (rpcDebug) {
		printf("no such message queued\n");
	    }
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_MessageSocket --
 *	Return the socket used to receive the given Rpc_Message.
 *
 * Results:
 *	The above-mentioned socket.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Rpc_MessageSocket(msg)
    Rpc_Message	  	msg;	    /* Received message */
{
    return(((RpcMessage *)msg)->sock);
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
RpcResend(call)
    RpcCall 	  	*call;      /* Record for message to be sent */
{
    register RpcCall	*c; 	    /* Current call in list */
    register RpcCall	**prev;	    /* Pointer to next field of previous call*/
    int	    	  	numBytes;   /* Number of bytes in message */
    Rpc_Stat	  	status;	    /* Status of call */
    MsgHeader	  	*header;    /* Header of message being resent (for
				     * debug output) */
    
    header = (MsgHeader *)call->message.msg_iov[0].iov_base;
    
    if (!call->replied) {
	if (rpcDebug) {
	    printf("Resending %u: ", ntohl(header->id));
	}
	if (call->numRetries != 0) {
	    call->numRetries -= 1;
	    if (rpcDebug) {
		printf("%d left\n", call->numRetries);
	    }
	send_again:
	    do {
		numBytes = sendmsg (call->sock, &call->message, 0);
	    } while ((numBytes < 0) && (errno == EINTR));

	    if (numBytes < 0) {
		if (rpcDebug) {
		    perror("RpcResend");
		}
		switch(errno) {
		    case EMSGSIZE:
			status = RPC_TOOBIG;
			break;
		    case ENOTCONN:
			/*
			 * Socket is a disconnected TCP socket. Connect it to
			 * the server to which this call is directed. XXX: This
			 * connection is irreversible. If the connection
			 * succeeds, resend the message.
			 */
			if (connect(call->sock,
				    (struct sockaddr *)call->message.msg_name,
				    call->message.msg_namelen) == 0)
			{
			    goto send_again;
			} else {
			    if (rpcDebug) {
				perror("connect");
			    }
			}
			/*FALLTHRU*/
		    default:
			status = RPC_CANTSEND;
			break;
		}
	    } else {
		status = RPC_SUCCESS;
	    }
	} else {
	    if (rpcDebug) {
		printf("TIMEOUT\n");
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
	if(rpcDebug) {
	    printf("Resend on replied-to message %u\n", ntohl(header->id));
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
RpcQueueEvent(ev)
    register RpcEvent	*ev;
{
    register RpcEvent	*e;
    register RpcEvent	**prev;
    
    if (rpcDebug) {
	printf ("Queueing event %x (timeout = %d)\n", ev, ev->timeout);
    }
    prev = &events;
    for (e = *prev; e != (RpcEvent *)0; e = *prev) {
	if (timercmp(&ev->timeout, &e->timeout, <)) {
	    break;
	} else {
	    prev = &e->next;
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
Rpc_EventCreate(interval, handler, data)
    struct timeval	*interval;  	/* Timeout period for event */
    Boolean    	  	(*handler)();	/* Function to handle timeout */
    Rpc_Opaque 	  	data;	    	/* Datum to pass it */
{
    register RpcEvent	*ev;

    ev = (RpcEvent *)malloc(sizeof(RpcEvent));
    (void)gettimeofday(&ev->timeout, (struct timezone *)0);
    timeadd(&ev->timeout,interval,&ev->timeout);
    ev->interval = *interval;
    ev->handler = handler;
    ev->data = data;

    if (rpcDebug) {
	printf("Created event %x\n", ev);
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
Rpc_EventDelete(event)
    Rpc_Event	  	event;    /* Event to remove */
{
    register RpcEvent	*ev;
    register RpcEvent	*e;
    register RpcEvent	**prev;
    register int  	caller;

    if (rpcDebug) {
	printf("Deleting event %x...", event);
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
	if (rpcDebug) {
	    printf("\n");
	}
	bzero(e, sizeof(*e));
	free((char *)e);
    } else if (rpcDebug) {
	printf("non-existent\n");
#ifdef notdef
    } else {
	asm("movl a6@(4),d7");
	printf("0x%x deleting non-existent event %x\n",
	       caller, event);
	for (e = events; e != (RpcEvent *)0; e = e->next) {
	    printf("%x expires at %d.%06d (handler=0x%x)\n",
		   e,
		   e->timeout.tv_sec,
		   e->timeout.tv_usec,
		   e->handler);
	}
#endif notdef
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
Rpc_EventReset(event, interval)
    Rpc_Event	  	event;	    /* Event to alter */
    struct timeval	*interval;  /* New interval */
{
    register RpcEvent	*ev;
    register RpcEvent	*e;
    register RpcEvent	**prev;
    struct timeval	now;

    if (rpcDebug) {
	printf("Reseting event %x...", event);
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
	if (rpcDebug) {
	    printf("\n");
	}
	*prev = e->next;
    } else if (rpcDebug) {
	printf("nonexistent\n");
    }
    ev->interval = *interval;
    (void)gettimeofday(&now, (struct timezone *)0);
    timeadd(&now, &ev->interval, &ev->timeout);
    RpcQueueEvent(ev);
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
Rpc_Wait()
{
    struct timeval	now;	    	/* Current time */
    struct timeval	tv; 	    	/* Actual interval to wait */
    struct timeval	*timeout;   	/* Pointer to interval to wait */
    register RpcEvent	*ev;	    	/* Current event */
    Boolean 	  	stayAwake;  	/* True if shouldn't go to sleep */
    fd_set    	  	readMask,
			writeMask,
			exceptMask;
    int			nstreams;
    int			ourSeq;

    if (rpcDebug) {
	printf("Rpc_Wait:\n");
    }
    while (1) {
	stayAwake = False;
	timeout = (struct timeval *)0;

	/*
	 * First handle any timeout event whose time has passed...We have
	 * to get the current time each time through because one of the event
	 * routines could have recursed and taken a long time. In such a case,
	 * when we get back to this level, we'll go to sleep for a lot longer
	 * than we really want. It's only 100 usecs per gettimeofday call,
	 * anyway...
	 */
	for (ev = events, (void)gettimeofday(&now, (struct timezone *)0);
	     ev != (RpcEvent *)0 && timercmp(&now, &ev->timeout, >);
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
	    timeadd(&ev->interval,&now,&ev->timeout);
	    RpcQueueEvent(ev);
	    if (rpcDebug) {
		printf("\ttaking event %x\n", ev);
	    }
	    stayAwake = (*ev->handler) (ev->data, ev) || stayAwake;
	}
	if (stayAwake) {
	    /*
	     * If we're not to go to sleep, return to the caller.
	     */
	    if (rpcDebug) {
		printf("\tstaying awake\n");
	    }
	    return;
	}
	if (ev != (RpcEvent *)0) {
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
	if (rpcDebug) {
	    printf("\tread(%x), write(%x), except(%x)",
		   readMask.fds_bits[0],
		   writeMask.fds_bits[0],
		   exceptMask.fds_bits[0]);
	    if (timeout) {
		printf(", to(%d.%06d)\n", timeout->tv_sec, timeout->tv_usec);
	    } else {
		printf("\n");
	    }
	}
	ourSeq = ++rpcWaitSeq;

	nstreams = select(FD_SETSIZE,&readMask,&writeMask,&exceptMask,timeout);
	if (nstreams > 0) {
	    /*
	     * Something is ready. Find it and call its handler function.
	     * For each stream that's ready, we find all the things it's ready
	     * for and stick the appropriate RPC_*ABLE constants in 'what',
	     * removing the stream from the various masks as we go. The handler
	     * is called once for each ready stream.
	     *
	     * Once all the streams have been handled, we break out of the loop
	     * and return.
	     */
	    register int base;
	    fd_mask 	rmask,
			wmask,
			emask;
	    register int stream;
	    register int what;
	    register fd_mask tmask;

	    if (rpcDebug) {
		printf("result:\n");
		fflush(stdout);
	    }
	    
	    for (base = 0,
		 rmask = readMask.fds_bits[0],
		 wmask = writeMask.fds_bits[0],
		 emask = exceptMask.fds_bits[0];

		 base < sizeof(rpc_readMask.fds_bits)/sizeof(fd_mask) &&
		 rpcWaitSeq == ourSeq;

		 base++,
		 rmask = readMask.fds_bits[base],
		 wmask = writeMask.fds_bits[base],
		 emask = exceptMask.fds_bits[base])
	    {
		if (rpcDebug) {
		    printf("\tread(%x), write(%x), except(%x)\n",
			   rmask, wmask, emask);
		    fflush(stdout);
		}
		
#define CHKSTR(n,mask,what) \
    if (!FD_ISSET((n), &(mask))) { \
	continue; \
    }
		while(rmask && rpcWaitSeq == ourSeq) {
		    stream = ffs(rmask) - 1;
		    tmask = 1 << stream;
		    
		    stream += base * (sizeof(fd_mask) * NBBY);

		    rmask &= ~tmask;
		    what = RPC_READABLE;

CHKSTR(stream, rpc_readMask, "reading");
		    
		    
		    if (rpcDebug) {
			printf("\t%d: read", stream);
		    }	
		    if (wmask & tmask) {
			wmask &= ~tmask;
CHKSTR(stream, rpc_writeMask, "writing");
		    
			what |= RPC_WRITABLE;
			if (rpcDebug) {
			    printf(",write");
			}
		    }
		    if (emask & tmask) {
			emask &= ~tmask;
CHKSTR(stream, rpc_exceptMask, "excepting");
		    
			what |= RPC_EXCEPTABLE;
			if(rpcDebug) {
			    printf(",except");
			}
			
		    }
		    if (rpcDebug) {
			putchar('\n');
		    }
		    (*streams[stream].handler) (stream,
						streams[stream].data,
						what);
		}
		while (wmask != 0 && rpcWaitSeq == ourSeq) {
		    stream = ffs(wmask) - 1;
		    tmask = 1 << stream;
		    stream += base * (sizeof(fd_mask)*NBBY);
		    wmask &= ~tmask;
		    what = RPC_WRITABLE;
		    
CHKSTR(stream, rpc_writeMask, "writing");
		    
		    if (rpcDebug) {
			printf("\t%d: write", stream);
		    }
		    if (emask & tmask) {
			emask &= ~tmask;
			what |= RPC_EXCEPTABLE;
CHKSTR(stream, rpc_exceptMask, "excepting");
		    
			if (rpcDebug) {
			    printf(",except");
			}
		    }
		    if (rpcDebug) {
			putchar('\n');
		    }
		    (*streams[stream].handler) (stream,
						streams[stream].data,
						what);
		}
		while (emask != 0 && rpcWaitSeq == ourSeq) {
		    stream = ffs(emask) - 1;
		    tmask = 1 << stream;
		    stream += base * (sizeof(fd_mask)*NBBY);
		    emask &= ~tmask;
CHKSTR(stream, rpc_exceptMask, "excepting");
		    
		    if(rpcDebug) {
			printf("\t%d:except\n", stream);
		    }
		    (* streams[stream].handler) (stream,
						 streams[stream].data,
						 RPC_EXCEPTABLE);
		}
	    }
	    return;
	} else if (nstreams < 0) {
	    /*
	     * Error
	     */
	    if (errno == EBADF) {
		/*
		 * Some file descriptor was bad -- find it and nuke it
		 */
		RpcCheckStreams();
	    } else if (errno == EINTR) {
		/*
		 * Allow signals to make us return.
		 */
		return;
	    } else if (rpcDebug) {
		perror("select");
	    }
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_Watch --
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
Rpc_Watch(stream, state, handler, data)
    int	    	  stream;   	/* Stream to observe */
    int	    	  state;    	/* State to watch for */
    void    	  (*handler)();	/* Function to call when state acheived */
    Rpc_Opaque 	  data;	    	/* Datum to pass it */
{
    if (streams[stream].state != 0) {
	if (streams[stream].state & RPC_READABLE) {
	    FD_CLR(stream, &rpc_readMask);
	}
	if (streams[stream].state & RPC_WRITABLE) {
	    FD_CLR(stream, &rpc_writeMask);
	}
	if (streams[stream].state & RPC_EXCEPTABLE) {
	    FD_CLR(stream, &rpc_exceptMask);
	}
    }
    streams[stream].state = state;
    streams[stream].handler = handler;
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
Rpc_Ignore(stream)
    int	    	  stream;   	/* Stream to ignore */
{
    register int  mask;

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
Rpc_Error(rpcMsg, stat)
    Rpc_Message	  	rpcMsg;	    /* Message to respond to */
    Rpc_Stat	  	stat;	    /* Status to return */
{
    register RpcMessage	*realMsg = (RpcMessage *)rpcMsg;
    struct {
	MsgHeader 	    header;
	Rpc_Stat  	    stat;
    }	    	  	errorMsg;

    if (rpcDebug) {
	printf("error on %d: code %d, procedure %d, id %u\n",
	       realMsg->sock, stat, realMsg->header->procNum,
	       realMsg->header->id);
    }
    if ((realMsg->header->flags & RPC_BROADCAST) == 0) {
	errorMsg.header.id = 	    htonl(realMsg->header->id);
	errorMsg.header.byteOrder = realMsg->header->byteOrder;
	errorMsg.header.procNum =   htons(realMsg->header->procNum);
	errorMsg.header.flags =
	    htons(realMsg->header->flags ^ (RPC_CALL|RPC_ERROR));
	errorMsg.header.length =    htonl(sizeof(stat));
	errorMsg.stat =     	    (Rpc_Stat)htonl(stat);

	while ((sendto(realMsg->sock, (char *)&errorMsg, sizeof(errorMsg), 0,
		       (struct sockaddr *)realMsg->remote,
		       sizeof(*realMsg->remote)) < 0) &&
	       (errno == EINTR)) {
		   ;
	}
	if (realMsg->e != (CacheEntry *)0) {
	    realMsg->e->status = REPLY_SENT;
	    realMsg->e->error = stat;
	}
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
 * 	of the CacheEntry for it is REPLY_PENDING) and the status of the
 *	cache entry upgraded to REPLY_SENT, with replySize and replyData
 *	set appropriately.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_Return(rpcMsg, length, data)
    Rpc_Message	  	rpcMsg;	    /* Message to respond to */
    int	    	  	length;	    /* Length of data to return */
    Rpc_Opaque 	  	data;	    /* Data to return */
{
    register RpcMessage	*realMsg = (RpcMessage *)rpcMsg;
    struct msghdr 	msg;
    struct iovec  	iov[2];
    MsgHeader	  	header;
    int	    	  	numBytes;

    if (rpcDebug) {
	printf("return on %d: %d bytes for procedure %d, id %u\n",
	       realMsg->sock, length, realMsg->header->procNum,
	       realMsg->header->id);
    }
    /*
     * First set up the header of the reply message. If too many data are
     * being passed back, an RPC_TOOBIG error is generated instead of the
     * reply. Note that we indicate the byteOrder for the message is the same
     * as that sent, since we byte-swap it to be the same.
     */
    header.id =   	    htonl(realMsg->header->id);
    header.byteOrder =	    realMsg->header->byteOrder;
    header.procNum = 	    htons(realMsg->header->procNum);
    header.flags = 	    htons(realMsg->header->flags^(RPC_CALL|RPC_REPLY));
    if (length <= MAX_DATA_SIZE) {
	header.length =     htonl(length);
    } else {
	Rpc_Error(rpcMsg, RPC_TOOBIG);
	return;
    }

    /*
     * Handle caching and swapping: If there were actually reply data,
     * allocate new storage for them and copy them in, pointing the replyData
     * field of the CacheEntry at them, else set both the replyData and
     * replySize fields to 0. Mark the entry as REPLY_SENT.
     * (Only do this if status is REPLY_PENDING to allow RpcHandleStream to
     * use us to resend a cached reply.)
     */
    if ((realMsg->e != (CacheEntry *)0) &&
	(realMsg->e->status == REPLY_PENDING))
    {
	realMsg->e->status = REPLY_SENT;
	
	if (length == 0) {
	    if (rpcDebug) {
		printf("Marking zero-length reply\n");
	    }
	    realMsg->e->replySize = 0;
	    realMsg->e->replyData = (Rpc_Opaque)0;
	} else {
	    if ((header.byteOrder != RPC_MAGIC) &&
		(realMsg->server->swapReplyProc != Rpc_SwapNull))
	    {
		if (rpcDebug) {
		    printf("Swapping reply of %d bytes\n", length);
		}
		(* realMsg->server->swapReplyProc)(length,
						   (Rpc_Opaque)data,
						   realMsg->server->data);
	    }
	    
	    if (rpcDebug) {
		printf("Marking reply of %d bytes\n", length);
	    }
	    realMsg->e->replySize = length;
	    realMsg->e->replyData = (Rpc_Opaque)malloc(length);
	    bcopy((char *)data, (char *)realMsg->e->replyData, length);
	}
    }
	

    /*
     * Then the I/O vector for the message (to avoid copies, of course)
     */
    iov[0].iov_base = 	    (caddr_t)&header;
    iov[0].iov_len =	    sizeof(header);
    iov[1].iov_base =	    (caddr_t)data;
    iov[1].iov_len =	    length;

    /*
     * Finally the msghdr for the sendmsg call.
     */
    msg.msg_name =	    (caddr_t)realMsg->remote;
    msg.msg_namelen =	    sizeof(*realMsg->remote);
    msg.msg_iov = 	    iov;
    msg.msg_iovlen =	    (length != 0) ? 2 : 1;
    msg.msg_accrights =	    (caddr_t)0;
    msg.msg_accrightslen =  0;

    /*
     * Keep sending the message while the thing keeps being interrupted.
     */
    do {
	numBytes = sendmsg(realMsg->sock, &msg, 0);
    } while ((numBytes < 0) && (errno == EINTR));

    if (numBytes < 0) {
	if (rpcDebug) {
	    perror("Rpc_Return: sendmsg");
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_ServerCreate --
 *	Set a server for a <socket, procedure-number> pair. The server
 *	should be declared as follows:
 *	    serverProc(fromPtr, msg, dataLen, data, serverData)
 *	    	  struct sockaddr_in *fromPtr;
 *	    	  Rpc_Opaque msg;
 *	    	  int dataLen;
 *	    	  Rpc_Opaque data;
 *	    	  Rpc_Opaque serverData;
 *
 *	fromPtr points to the address of the sender of the request.
 *	msg is an opaque parameter that must be used to send a reply.
 *	dataLen is the number of bytes of data that came with the request.
 *	data is the data that were sent with the request.
 *	serverData is the piece of data supplied when the server was created.
 *
 *	data and serverData should not, of course, be opaque to the server...
 *
 *	The swap procedures should be declared as:
 *	    swapProc(length, data, serverData)
 *		int		length;
 *		Rpc_Opaque	data;
 *		Rpc_Opaque  	serverData;
 *
 *	data is the data to be swapped and length is its length. serverData
 *	is the same as for the serverProc call.
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
Rpc_ServerCreate(sock, procNum, serverProc, swapArgsProc, swapReplyProc,
		 serverData)
    int	    	  sock;	    	    /* Socket for server */
    Rpc_Proc 	  procNum;  	    /* Procedure number to serve */
    void    	  (*serverProc)();  /* Handler function to call */
    void    	  (*swapArgsProc)();/* Swapping function for args */
    void	  (*swapReplyProc)();/* Swapping function for reply */
    Rpc_Opaque 	  serverData;	    /* Datum to pass to server function */
{
    register RpcServer	*s;

    /*
     * Look for previous server record and use it if present
     */
    for (s = rpcServers[sock]; s != (RpcServer *)0; s = s->next) {
	if (s->procNum == procNum) {
	    break;
	}
    }
    if (s == (RpcServer *)0) {
	/*
	 * Didn't exist: create new record and link it into the list of
	 * servers on the socket.
	 */
	s = (RpcServer *)malloc(sizeof(RpcServer));
	s->next = rpcServers[sock];
	rpcServers[sock] = s;
    } else {
	/*
	 * It did exist. Since we're zeroing out the cache, we want to
	 * destroy previously-cached calls.
	 */
	RpcCacheDestroy(s);
    }

    /*
     * Install new server in server record
     */
    s->procNum = procNum;
    s->serverProc = serverProc;
    s->swapArgsProc = swapArgsProc;
    s->swapReplyProc = swapReplyProc;
    s->data = serverData;
    bzero((char *)s->cache, sizeof(s->cache));

    /*
     * Install handler for stream.
     */
    Rpc_Watch(sock, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);
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
Rpc_ServerDelete(sock, procNum)
    int	    sock; 	/* Socket handler is on */
    Rpc_Proc procNum;	/* Procedure number to stop handling */
{
    register RpcServer 	*s;
    register RpcServer	**prev;

    prev = &rpcServers[sock];
    for (s = rpcServers[sock]; s != (RpcServer *)0; s = s->next) {
	if (s->procNum == procNum) {
	    break;
	} else {
	    prev = &s->next;
	}
    }
    if (s != (RpcServer *)0) {
	*prev = s->next;
	RpcCacheDestroy(s);
	free((char *)s);
	if ((rpcServers[sock] == (RpcServer *)0) &&
	    (rpcCalls[sock] == (RpcCall *)0)) {
		Rpc_Ignore(sock);
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
Rpc_Call(sock, server, procNum, inLength, inData, outLength, outData,
	 numRetries, retry)
    int	    	  	sock;	    /* Socket on which to call */
    struct sockaddr_in	*server;    /* Complete address of server */
    Rpc_Proc 	  	procNum;    /* Procedure number to call */
    int	    	  	inLength;   /* Length of data for call */
    Rpc_Opaque 	  	inData;	    /* Data for call */
    int	    	  	outLength;  /* Expected length of results. If 0,
				     * call will be acknowledged before it
				     * is handled on remote side. */
    Rpc_Opaque 	  	outData;    /* Place to store results of call */
    int	    	  	numRetries; /* Number of times to try the call before
				     * timing out */
    struct timeval	*retry;	    /* Interval at which to retry */
{
    struct iovec  	iov[2];
    MsgHeader 	  	header;
    RpcCall	  	call;

    if (inLength > MAX_DATA_SIZE) {
	return (RPC_TOOBIG);
    }
    call.message.msg_name =  	    (caddr_t)server;
    call.message.msg_namelen =	    sizeof(*server);
    call.message.msg_iov =   	    iov;
    call.message.msg_iovlen =	    (inLength != 0) ? 2 : 1;
    call.message.msg_accrights =     (caddr_t)0;
    call.message.msg_accrightslen =  0;

    call.sock = 	    	    sock;
    call.numRetries =	    	    numRetries;
    call.id =	  	    	    RpcUniqueID();
    call.replyLen =	    	    outLength;
    call.reply =  	    	    outData;
    call.resend = 	    	    Rpc_EventCreate(retry,
						    RpcResend,
						    (Rpc_Opaque)&call);
    call.replied =	    	    False;
    call.next =   	    	    rpcCalls[sock];

    rpcCalls[sock] = &call;

    header.id =	  	    	    htonl(call.id);
    header.byteOrder =		    RPC_MAGIC;
    header.procNum =	    	    htons(procNum);
    header.flags =	    	    htons(RPC_CALL);
    header.length =	    	    htonl(inLength);

    iov[0].iov_base = 	    	    (caddr_t)&header;
    iov[0].iov_len = 	    	    sizeof(header);
    iov[1].iov_base = 	    	    (caddr_t)inData;
    iov[1].iov_len = 	    	    inLength;

    /*
     * Set to catch responses and send initial packet.
     */
    Rpc_Watch(sock, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);
    (void)RpcResend(&call);

    while (!call.replied) {
	Rpc_Wait();
    }

    /*
     * Cleanup: nuke the resend event and ignore the socket if we aren't
     * paying attention to it anymore (no servers for it and no calls pending
     * on it)
     */
    Rpc_EventDelete(call.resend);

    if ((rpcServers[sock] == (RpcServer *)0) &&
	(rpcCalls[sock] == (RpcCall *)0))
    {
	Rpc_Ignore(sock);
    }
    return(call.status);
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_GetNetworks --
 *	Return the network address(es) of this machine (as suitable for
 *	broadcasting).
 *
 * Results:
 *	The broadcast address(es) for the machine and the number of
 *	networks the machine is on.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_GetNetworks(sock, maxNets, networks, numNetsPtr)
    int	    	  	sock;	    /* Socket with which to find the networks*/
    int			maxNets;    /* Maximum number of networks supported */
    struct sockaddr_in	*networks;  /* Where to store the addresses. These are
				     * full sockaddr_in's to make life easier
				     * for the caller */
    int	    	    	*numNetsPtr;/* Place to store the actual number of
				     * networks */
{
    struct ifconf 	ifc;	    /* Record of all known network
				     * interfaces */
    struct ifreq  	ifreq,	    /* Current network interface */
			*ifr;	    /* Pointer into ifc of current interface */
    int	    	  	n;  	    /* Number of networks left to check */
    char    	  	buf[1024];  /* Buffer for fetching interface info */
    struct in_addr 	addr;	    /* Actual broadcast address */
    int	    	    	i;  	    /* Current broadcast network (entry in
				     * "networks") */

    ifc.ifc_len = sizeof(buf);
    ifc.ifc_buf = buf;
    i = 0;

    if (ioctl(sock, SIOCGIFCONF, (char *)&ifc) >= 0) {
	/*
	 * First fetch info for all the networks known
	 */
	ifr = ifc.ifc_req;

	/*
	 * Step through each network known, looking for those that are up and
	 * have broadcasting enabled
	 */
	for (n = ifc.ifc_len/sizeof (struct ifreq);
	     (i < maxNets) && (n > 0);
	     n--, ifr++)
	{
	    /*
	     * Copy so we can mangle the address to get the interface flags
	     */
	    ifreq = *ifr;

	    /*
	     * Find the state of the interface
	     */
	    if (ioctl(sock, SIOCGIFFLAGS, (char *)&ifreq) < 0) {
		if (rpcDebug) {
		    perror("Rpc_GetNetworks: ioctl (get interface flags)");
		}
		continue;
	    }

	    if ((ifreq.ifr_flags & IFF_BROADCAST) &&
		(ifreq.ifr_flags & IFF_UP) &&
		(ifr->ifr_addr.sa_family == AF_INET))
	    {
		/*
		 * Good stuff, Maynard. We can broadcast on it and it's up.
		 * Now figure out the actual address to use for broadcasting.
		 * The way this works is:
		 *  - If the system supports broadcast addresses and this
		 *    interface has one, we use that.
		 *  - If the system supports netmasks and the interface has
		 *    one, we take the interface's address and mask out
		 *    the bits indicated by the mask, assuming that to be
		 *    the broadcast address.
		 *  - As a last resort, we use inet_netof to find the network
		 *    part of the interface's address and assume we can
		 *    broadcast there.
		 */
		struct sockaddr_in *sin;    /* Pointer into ifreq for ease
					     * of reference */
		    
		addr = ((struct sockaddr_in *)&ifr->ifr_addr)->sin_addr;
		sin = (struct sockaddr_in *)&ifreq.ifr_addr;
#ifdef SIOCGIFBRDADDR
		if (ioctl(sock, SIOCGIFBRDADDR, &ifreq) == 0) {
		    /*
		     * If the interface has a broadcast address associated
		     * with it, use that.
		     */
		    addr = sin->sin_addr;
		} else
#endif SIOCGIFBRDADDR
#ifdef SIOCGIFNETMASK
		    if (ioctl(sock, SIOCGIFNETMASK, &ifreq) == 0) {
			/*
			 * If the interface has a netmask defined, use
			 * that mask to determine the network address for
			 * broadcasting. Both addr and ifreq.ifr_addr are
			 * in network-order, so no need to convert...
			 */
			addr.s_addr &= sin->sin_addr.s_addr;
		    } else {
			addr = inet_makeaddr(inet_netof(addr), INADDR_ANY);
		    }
#else
		addr = inet_makeaddr(inet_netof(addr), INADDR_ANY);
#endif SIOCGIFNETMASK

		networks[i].sin_addr = addr;
		i++;
	    }
	}
    }

    /*
     * Return the number of networks actually found.
     */
    *numNetsPtr = i;
}

/***********************************************************************
 *				Rpc_BroadcastToNets
 ***********************************************************************
 * SYNOPSIS:	    Broadcast an rpc call to one or more networks.
 *	    	    handleProc should be declared:
 *	    	    	Bool
 *	    	    	handleProc(fromPtr, dataLen, data)
 *	    	    	    struct sockaddr_in *fromPtr;
 *	    	    	    int dataLen;
 *	    	    	    Rpc_Opaque data;
 *	    	    It should return True if broadcasting should stop and
 *	    	    False if it should continue.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    RPC_SUCCESS if at least one reply was received.
 *	    	    RPC_TIMEDOUT if no reply was received.
 * SIDE EFFECTS:    A call is broadcast over the network.
 *	    	    outData is overwritten.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/15/94		Initial Revision
 *
 ***********************************************************************/
Rpc_Stat
Rpc_BroadcastToNets(sock, networks, numNets, procNum, inLength, inData,
		    outLength, outData, numRetries, retry, handleProc,
		    handleData)
    int	    	  	sock;	    	    /* Socket on which to call */
    struct sockaddr_in	*networks;    	    /* Broadcast address(es) to use */
    unsigned	    	numNets;    	    /* Number of entries in networks */
    Rpc_Proc 	  	procNum;    	    /* Procedure number to call */
    int	    	  	inLength;   	    /* Length of data for call */
    Rpc_Opaque 	  	inData;	    	    /* Data for call */
    int	    	  	outLength;  	    /* Expected length of results. If
					     * 0, call will be acknowledged
					     * before it is handled on remote
					     * side. */
    Rpc_Opaque 	  	outData;    	    /* Place to store results of
					     * call */
    int	    	  	numRetries; 	    /* Number of times to try the call
					     * before timing out */
    struct timeval	*retry;	    	    /* Interval at which to retry */
    Boolean    	  	(*handleProc)();    /* Function to handle responses */
    Rpc_Opaque	    	handleData; 	    /* Extra data to pass to
					     * handleProc */
{
    RpcCall	  	calls[MAXNETS];	    /* Call records for above */
    MsgHeader 	  	header[MAXNETS];    /* Headers for above */
    struct iovec  	iov[MAXNETS][2];    /* sendmsg vectors for above */
    int	    	  	numResponses = 0;   /* Number of responses received
					     * so far */
    int			one = 1;    	    /* For setsockopt */
    int	    	    	i;  	    	    /* Index into calls et al */
    Rpc_Stat	    	result=RPC_TIMEDOUT;/* Our return value */
    RpcServer	    	cache;	    	    /* Fake server record for caching
					     * responses */
    if (inLength > MAX_DATA_SIZE) {
	return (RPC_TOOBIG);
    }

    if (numNets >= MAXNETS) {
	return (RPC_TOOBIG);
    }
    
#ifdef SO_BROADCAST
    /*
     * Enable broadcasting on this socket. If we can't do that, we can't
     * send...
     */
    if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &one, sizeof(one)) < 0){
	if (rpcDebug) {
	    perror("setsockopt");
	    printf("sock = %d\n", sock);
	}
	return(RPC_CANTSEND);
    }
#endif SO_BROADCAST

    /*
     * For each network to which we're broadcasting, make up a unique RpcCall
     * structure, with proper address, id, header, etc. Link it in and issue
     * the initial call in this loop.
     */
    for (i = 0; i < numNets; i++) {
	/*
	 * Set up message header first.
	 */
	calls[i].message.msg_name =  	    (caddr_t)&networks[i];
	calls[i].message.msg_namelen =	    sizeof(networks[i]);
	calls[i].message.msg_iov =   	    iov[i];
	calls[i].message.msg_iovlen =	    (inLength != 0) ? 2 : 1;
	calls[i].message.msg_accrights =    (caddr_t)0;
	calls[i].message.msg_accrightslen = 0;
	
	/*
	 * Initialize the rest of our parameters. Note the message must have
	 * a unique ID so it can be found when someone on the network responds.
	 */
	calls[i].sock = 	    	    sock;
	calls[i].numRetries =	    	    numRetries;
	calls[i].id =	  	    	    RpcUniqueID();
	calls[i].replyLen =	    	    outLength;
	calls[i].reply =  	    	    outData;
	calls[i].resend = 	    	    Rpc_EventCreate(retry,
							    RpcResend,
							    (Rpc_Opaque)&calls[i]);
	calls[i].replied = 	    	    False;

	/*
	 * Link it into the chain of calls for this socket
	 */
	calls[i].next =			    rpcCalls[sock];
	rpcCalls[sock] =		    &calls[i];
	
	/*
	 * Set up the header to go with the call.
	 */
	header[i].id =	  	    	    htonl(calls[i].id);
	header[i].byteOrder =		    RPC_MAGIC;
	header[i].procNum =	    	    htons(procNum);
	header[i].flags =	    	    htons(RPC_CALL|RPC_BROADCAST);
	header[i].length =	    	    htonl(inLength);
	
	/*
	 * Set up the I/O vector for the message (to avoid copying)
	 */
	iov[i][0].iov_base = 	    	    (caddr_t)&header[i];
	iov[i][0].iov_len = 	    	    sizeof(header[i]);
	iov[i][1].iov_base = 	    	    (caddr_t)inData;
	iov[i][1].iov_len = 	    	    inLength;

	/*
	 * Dispatch the initial broadcast call
	 */
	(void)RpcResend(&calls[i]);
    }

    /*
     * Initialize the "server" cache
     */
    bzero(cache.cache, sizeof(cache.cache));
    
    /*
     * Watch for replies on this socket
     */
    Rpc_Watch(sock, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);

    /*
     * Loop for the entire broadcast period, reinstalling the call each
     * time it receives a response until either all the calls report an
     * error or the handler function returns True. If any of the errors
     * isn't RPC_TIMEDOUT, record it as the result to return.
     */
    while(1) {
	int	failures;   /* The number of failed calls */
	    
	/*
	 * Wait for something to happen
	 */
	Rpc_Wait();
	
	/*
	 * Check all our calls for success or failure.
	 */
	for (failures = i = 0; i < numNets; i++) {
	    if (calls[i].replied) {
		if (calls[i].status == RPC_SUCCESS) {
		    CacheEntry	*e;
		    Boolean 	new;

		    /*
		     * Check the response cache to see if this party's
		     * been heard from before.
		     */
		    e = RpcCacheFind(&cache, &calls[i].remote, (RpcID)0,
				     True, &new);

		    if (new) {
			/*
			 * Note another successful response
			 */
			numResponses += 1;

			if ((*handleProc)(&calls[i].remote,
					  calls[i].replyLen,
					  outData,
					  handleData))
			{
			    /*
			     * Handler returned True -- abort the whole
			     * process.
			     */
			    goto done_broadcast;
			}
		    }
		    /*
		     * Requeue and reinitialize the call. The event is
		     * still registered, so the call will continue to be
		     * sent.
		     */
		    calls[i].replied 	= False;
		    calls[i].replyLen 	= outLength;
		    calls[i].next   	= rpcCalls[sock];

		    rpcCalls[sock] = &calls[i];
		} else {
		    if (calls[i].status != RPC_TIMEDOUT) {
			/*
			 * Didn't timeout -- record that as our return code.
			 * XXX: This shouldn't abort the broadcast on
			 * that interface, though...
			 */
			result = calls[i].status;
		    }
		    /*
		     * Note another failed call.
		     */
		    failures++;
		}
	    }
	}
	if (failures == numNets) {
	    /*
	     * All done -- get out of here
	     */
	    break;
	}
    }

done_broadcast:
    /*
     * Delete the resend event for each call and unlink structures for calls
     * that haven't been replied to.
     */
    for (i = 0; i < numNets; i++) {
	Rpc_EventDelete(calls[i].resend);

	if (!calls[i].replied) {
	    register RpcCall *call;
	    register RpcCall **prev;

	    prev = &rpcCalls[sock];
	    for (call = *prev; call != (RpcCall *)0; call = call->next) {
		if (call == &calls[i]) {
		    /*
		     * Found it -- unlink
		     */
		    *prev = call->next;
		    break;
		} else {
		    prev = &call->next;
		}
	    }
	}
    }

    /*
     * Nuke the cache.
     */
    RpcCacheDestroy(&cache);
    
    /*
     * If nothing left on the socket, ignore it
     */
    if ((rpcServers[sock] == (RpcServer *)0) &&
	(rpcCalls[sock] == (RpcCall *)0))
    {
	Rpc_Ignore(sock);
    }
    
    if (result == RPC_TIMEDOUT) {
	/*
	 * If timed out, return success as long as we got something from
	 * someone.
	 */
	return(numResponses ? RPC_SUCCESS : RPC_TIMEDOUT);
    } else {
	/*
	 * Worse error -- return it.
	 */
	return(result);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_Broadcast --
 *	Broadcast an rpc call. If the server's address (server->sin_addr)
 *	is not INADDR_ANY, then only that network is used. (if the address
 *	isn't a network, this degenerates to an Rpc_Call with a callback
 *	function and no response on error).
 *	handleProc should be declared:
 *	    Bool
 *	    handleProc(fromPtr, dataLen, data)
 *	    	  struct sockaddr_in *fromPtr;
 *	    	  int dataLen;
 *	    	  Rpc_Opaque data;
 *	It should return True if broadcasting should stop and False if it
 *	should continue.
 *
 * Results:
 *	RPC_SUCCESS if at least one reply was received.
 *	RPC_TIMEDOUT if no reply was received.
 *
 * Side Effects:
 *	A call is broadcast over the network.
 *	outData is overwritten.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Rpc_Broadcast(sock, server, procNum, inLength, inData, outLength, outData,
	      numRetries, retry, handleProc, handleData)
    int	    	  	sock;	    	    /* Socket on which to call */
    struct sockaddr_in	*server;    	    /* Complete address of server.
					     * If the sin_addr field is
					     * INADDR_ANY, broadcast to all
					     * attached networks. */
    Rpc_Proc 	  	procNum;    	    /* Procedure number to call */
    int	    	  	inLength;   	    /* Length of data for call */
    Rpc_Opaque 	  	inData;	    	    /* Data for call */
    int	    	  	outLength;  	    /* Expected length of results. If
					     * 0, call will be acknowledged
					     * before it is handled on remote
					     * side. */
    Rpc_Opaque 	  	outData;    	    /* Place to store results of
					     * call */
    int	    	  	numRetries; 	    /* Number of times to try the call
					     * before timing out */
    struct timeval	*retry;	    	    /* Interval at which to retry */
    Boolean    	  	(*handleProc)();    /* Function to handle responses */
    Rpc_Opaque	    	handleData; 	    /* Extra data to pass to
					     * handleProc */
{
    struct sockaddr_in 	networks[MAXNETS];  /* Addresses to which to send */
    int	    	    	numNets;    	    /* Number of entries in above */
    
    /*
     * If the server isn't indicated (its address is INADDR_ANY), we fetch
     * the addresses of all the networks on which this host resides (up to
     * MAXNETS).
     */
    if (server->sin_addr.s_addr == htonl(INADDR_ANY)) {
	unsigned    i;

	Rpc_GetNetworks(sock, MAXNETS, networks, &numNets);
	for (i = 0; i < numNets; i++) {
	    /*
	     * Copy family and destination port from the server record we were
	     * given. The sin_addr field is filled in by Rpc_GetNetworks
	     */
	    networks[i].sin_family =    	    server->sin_family;
	    networks[i].sin_port =	    	    server->sin_port;
	}
    } else {
	/*
	 * Server given -- only broadcast to one place.
	 */
	networks[0] = *server;
	numNets = 1;
    }
    
    return Rpc_BroadcastToNets(sock, networks, numNets, procNum,
			       inLength, inData, outLength, outData,
			       numRetries, retry, handleProc, handleData);
    
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
Rpc_Run()
{
    while(1) {
	Rpc_Wait();
    }
}

static jmp_buf	  acceptBuf;

/*-
 *-----------------------------------------------------------------------
 * RpcTcpTimeout --
 *	An accept on a stream has timed out -- don't keep us waiting.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Performs a longjmp through acceptBuf.
 *	
 *-----------------------------------------------------------------------
 */
static void
RpcTcpTimeout()
{
    longjmp(acceptBuf, 1);
}

/*-
 *-----------------------------------------------------------------------
 * RpcTcpAccept --
 *	Accept on a passive TCP stream, duplicating all servers on the
 *	passive stream to the active one.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A new stream is opened and rpcServer structures allocated to hold
 *	those of the passive stream.
 *
 *-----------------------------------------------------------------------
 */
static void
RpcTcpAccept(stream)
    int	    	  	stream;	    /* Passive stream with connection pending */
{
    register int  	newStream;  /* New active stream */
    register RpcServer	*serv;	    /* Original server record */
    register RpcServer	*newServ;   /* Duplicate server record */
    register RpcServer	**prevServ; /* Previous duplicate's next field */
    struct sockaddr_in	remote;
    int	    	  	len;

    signal(SIGALRM, RpcTcpTimeout);

    alarm(5);
    if (setjmp(acceptBuf) == 0) {
	len = sizeof(remote);
	newStream = accept(stream, (struct sockaddr *)&remote, &len);
    } else {
	newStream = -1;
    }
    alarm(0);
    signal(SIGALRM, SIG_DFL);

    if (newStream < 0) {
	if (rpcDebug) {
	    perror("accept");
	}
	return;
    }
    /*
     * First set to handle the new stream when it becomes readable, then
     * duplicate the list of RpcServers attached to the passive stream. This
     * is faster than calling Rpc_ServerCreate because it doesn't have to check
     * down the list for each server -- it just duplicates it.
     */
    Rpc_Watch(newStream, RPC_READABLE, RpcHandleStream, (Rpc_Opaque)0);
    for (serv = rpcServers[stream], prevServ = &rpcServers[newStream];
	 serv != (RpcServer *)0;
	 serv = serv->next) {
	     newServ = (RpcServer *)malloc(sizeof(RpcServer));
	     newServ->procNum = serv->procNum;
	     newServ->serverProc = serv->serverProc;
	     newServ->swapArgsProc = serv->swapArgsProc;
	     newServ->swapReplyProc = serv->swapReplyProc;
	     newServ->data = serv->data;
	     bzero((char *)newServ->cache, sizeof(newServ->cache));
	     *prevServ = newServ;
	     prevServ = &newServ->next;
    }
    *prevServ = (RpcServer *)0;
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_TcpCreate --
 *	Create a tcp socket for rpc. The socket will be a passive service
 *	socket ready for connections if 'service' is True. If 'service'
 *	is False, the socket remains unbound and unconnected. It will be
 *	bound and connected when the first Rpc_Call is made on it.
 *
 * Results:
 *	The file descriptor of the open socket.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Rpc_TcpCreate(service, port)
    Boolean 	  	service;    /* True if socket will be used for handling
				     * rpc calls */
    unsigned short	port;	    /* Port number to use if socket is a
				     * service socket. */
{
    register int  	s;

    s = socket(AF_INET, SOCK_STREAM, 0);
    if (s < 0) {
	return (-1);
    }
    if (service) {
	struct sockaddr_in  sin;

	/*
	 * The address has a sin_zero field that must be zero, for some reason
	 * known only to the demented engineers who wrote the code.
	 */
	bzero(&sin, sizeof(sin));

	sin.sin_family = AF_INET;
	sin.sin_port = htons(port);
	sin.sin_addr.s_addr = htonl(INADDR_ANY);
	if (bind(s, (struct sockaddr *)&sin, sizeof(sin)) < 0) {
	    if (rpcDebug) {
		perror("bind");
	    }
	    (void)close(s);
	    return (-1);
	}
	if (listen(s, 5) < 0) {
	    if (rpcDebug) {
		perror("listen");
	    }
	    (void)close(s);
	    return(-1);
	}
    }
    return(s);
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_UdpCreate --
 *	Create a UDP socket that may be used for service or calling.
 *
 * Results:
 *	The socket created.
 *
 * Side Effects:
 *	A socket is created and its address bound. If service is True,
 *	the given port is used for its address, otherwise it is assigned
 *	one by the system. Note each UDP socket used for calling must
 *	have a port bound to it or the call will never receive a reply,
 *	as the port will be assigned when the sendto() call is issued and
 *	forgotten immediately thereafter.
 *
 *-----------------------------------------------------------------------
 */
int
Rpc_UdpCreate(service, port)
    Boolean 	  	service;    	/* True if socket will be used to
					 * service rpc calls */
    unsigned short	port;	    	/* Port number to use for socket, if
					 * service is True */
{
    register int  	s;
    struct sockaddr_in	sin;

    s = socket(AF_INET, SOCK_DGRAM, 0);
    if (s < 0) {
	return(-1);
    }

    /*
     * The ISI has a sin_zero field that must be zero, for some reason
     * known only to the demented engineers who programmed the thing.
     */
    bzero(&sin, sizeof(sin));

    sin.sin_family = AF_INET;
    sin.sin_port = htons(service ? port : 0);
    sin.sin_addr.s_addr = htonl(INADDR_ANY);
    if (bind(s, (struct sockaddr *)&sin, sizeof(sin)) < 0) {
	(void)close(s);
	return(-1);
    }
    return (s);
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
Rpc_Debug(debug)
    Boolean 	  	debug;
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
Rpc_ErrorMessage(stat)
    Rpc_Stat	  	stat;
{
    static char   	*messages[] = {
	"Call was successful",
	"Couldn't send message",
        "Call timed out",
        "Arguments/results too big",
        "No such procedure",
        "Access denied",
        "Invalid argument(s)",
        "Remote system error",
    };
    int	    	  	index = (int)stat;

    if (index > sizeof(messages)/sizeof(char *)) {
	return ("Unknown error");
    } else {
	return (messages[index]);
    }
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
Rpc_Reset()
{
    register int  	stream;
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
	     call = call->next) {
		 call->replied = True;
		 call->status = RPC_TIMEDOUT;
	}
	for (server = rpcServers[stream];
	     server != (RpcServer *)0;
	     server = server->next) {
		 RpcCacheDestroy(server);
		 free((char *)server);
	}
    }

    for (event = events; event != (RpcEvent *)0; event = events) {
	events = event->next;
	free((char *)event);
    }
}


/***********************************************************************
 *				RpcCheckLocal
 ***********************************************************************
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
 *	ardeb	3/ 4/94		Initial Revision
 *
 ***********************************************************************/
static Boolean
RpcCheckLocal(addrPtr, checkHost)
    struct sockaddr_in	*addrPtr;
    Boolean 	    	checkHost;
{
    static struct sockaddr_in	locals[MAXNETS];
    static struct sockaddr_in	masks[MAXNETS];
    static int	    	    	numLocals = 0;
    int	    	    	    	i;

    if (numLocals == 0) {
	/*
	 * Need to find all the local address. Do this only once.
	 * Note that the socket we use needn't be bound to anything --
	 * it's just a focal point for an ioctl or two.
	 */
	struct ifconf 	ifc;	    /* Record of all known network
					 * interfaces */
	struct ifreq  	ifreq,	    /* Current network interface */
			*ifr;	    /* Pointer into ifc of current interface */
	int	    	n;  	    /* Number of interfaces left to check */
	char    	buf[1024];  /* Buffer for fetching interface info */
	int 		s = socket(AF_INET, SOCK_DGRAM, 0);

	ifc.ifc_len = sizeof(buf);
	ifc.ifc_buf = buf;

	if (ioctl(s, SIOCGIFCONF, (char *)&ifc) >= 0) {
	    /*
	     * First fetch info for all the networks known
	     */
	    ifr = ifc.ifc_req;

	    /*
	     * Step through each network known, looking for those that are up.
	     */
	    for (n = ifc.ifc_len/sizeof (struct ifreq);
		 (numLocals < MAXNETS) && (n > 0);
		 n--, ifr++)
	    {
		/*
		 * Copy so we can mangle the address to get the interface flags
		 */
		ifreq = *ifr;

		/*
		 * Find the state of the interface
		 */
		if (ioctl(s, SIOCGIFFLAGS, (char *)&ifreq) < 0) {
		    if (rpcDebug) {
			perror("Rpc_IsLocal: ioctl (get interface flags)");
		    }
		    continue;
		}

		if ((ifreq.ifr_flags & IFF_UP) &&
		    (ifr->ifr_addr.sa_family == AF_INET))
		{
		    /*
		     * Good stuff, Maynard. It's up and using INET addressing
		     */
		    locals[numLocals] = *(struct sockaddr_in *)&ifr->ifr_addr;
		    if (ioctl(s, SIOCGIFNETMASK, (char *)&ifreq) == 0) {
			masks[numLocals] =
			    *(struct sockaddr_in *)&ifreq.ifr_addr;
		    } else {
			if (IN_CLASSA(locals[numLocals].sin_addr.s_addr))
			{
			    masks[numLocals].sin_addr.s_addr = IN_CLASSA_NET;
			}
			else if (IN_CLASSB(locals[numLocals].sin_addr.s_addr))
			{
			    masks[numLocals].sin_addr.s_addr = IN_CLASSB_NET;
			}
			else
			{
			    masks[numLocals].sin_addr.s_addr = IN_CLASSC_NET;
			}
		    }
		    numLocals++;
		}
	    }
	}

	(void)close(s);
    }

    /*
     * Check all known local addresses against the passed one, returning
     * True on first match. This handles localhost too, since we've got
     * the address for interface lo0.
     */
    if (checkHost) {
	for (i = 0; i < numLocals; i++) {
	    if (addrPtr->sin_addr.s_addr == locals[i].sin_addr.s_addr) {
		return(True);
	    }
	}
    } else {
	for (i = 0; i < numLocals; i++) {
	    if ((addrPtr->sin_addr.s_addr & masks[i].sin_addr.s_addr) ==
		(locals[i].sin_addr.s_addr & masks[i].sin_addr.s_addr))
	    {
		return(True);
	    }
	}
    }
    /*
     * T'ain't one of ours.
     */
    return(False);
}
/*-
 *-----------------------------------------------------------------------
 * Rpc_IsLocal --
 *	See if passed address originated with the local machine.
 *	
 * Results:
 *	True if it did, False if it didn't
 *	
 *
 * Side Effects:
 *	None
 *	
 *-----------------------------------------------------------------------
 */
Boolean
Rpc_IsLocal(addrPtr)
    struct sockaddr_in	*addrPtr;
{
    return RpcCheckLocal(addrPtr, True);
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_IsLocal --
 *	See if passed address originated with the local machine.
 *	
 * Results:
 *	True if it did, False if it didn't
 *	
 *
 * Side Effects:
 *	None
 *	
 *-----------------------------------------------------------------------
 */
Boolean
Rpc_IsLocalNet(addrPtr)
    struct sockaddr_in	*addrPtr;
{
    return RpcCheckLocal(addrPtr, False);
}
/*-
 *-----------------------------------------------------------------------
 * Rpc_SwapLong --
 *	Swap a single longword.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The longword is overwritten.
 *
 *-----------------------------------------------------------------------
 */
void
Rpc_SwapLong (length, data)
    int	    length;	/* Length of data (UNUSED) */
    long    *data;	/* Pointer to long to be swapped */
{
    union {
	unsigned char	bytes[4];
	unsigned long	l;
    }	swap;
    register unsigned char *cp = (unsigned char *)data;

    swap.bytes[0] = cp[3];
    swap.bytes[1] = cp[2];
    swap.bytes[2] = cp[1];
    swap.bytes[3] = cp[0];
    *data = swap.l;
}

/*-
 *-----------------------------------------------------------------------
 * Rpc_SwapShort --
 *	Swap a single short word (two bytes).
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The shortword is overwritten.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Rpc_SwapShort (length, data)
    int	    	  	length;
    unsigned short	*data;
{
    union {
	unsigned char	bytes[2];
	unsigned short	s;
    }	    swap;
    register unsigned char *cp;

    cp = (unsigned char *)data;
    swap.bytes[0] = cp[1];
    swap.bytes[1] = cp[0];
    *data = swap.s;
}
#endif /* defined(unix) */
