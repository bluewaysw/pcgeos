/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Sun RPC Implementation
 * FILE:	  sunrpc.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	SunRpc_ServerCreate Register a server for a <socket,prog,vers,proc>
 *	    	    	    4-tuple
 *	SunRpc_ServerDelete Unregister a server
 *	SunRpc_Call 	    Issue a call to a Sun RPC procedure in another
 *	    	    	    server.
 *	SunRpc_MsgStream    Return stream over which call arrived
 *	SunRpc_MsgProg	    Return program called by message
 *	SunRpc_MsgProc	    Return procedure called by message
 *	SunRpc_MsgVers	    Return version desired by caller
 *	SunRpc_MsgRawCred   Return raw credentials passed with message
 *	SunRpc_MsgCred	    Return converted credentials passed with
 * 	    	    	    message.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Implementation of the Sun RPC protocol (UDP transport) on top
 *	of the customs RPC code.
 *
 *	This doesn't use the CLIENT and SVCXPRT things normally
 *	associated with the Sun RPC -- just the XDR things.
 *	
 *	Note that this is not a complete implementation of the Sun RPC.
 *	It is not intended as a standalone, as it uses functions in the
 *	Sun RPC code, including a couple (_authenticate, _seterr_reply)
 *	that are internal and undocumented. The reason for this thing's
 *	existence is to allow the normal multi-threading and real call
 *	caching for the Sun RPC servers, as well as to allow the use of
 *	the explicit acknowledge for sockets serving Customs RPC.
 *
 * 	Copyright (c) Berkeley Softworks 1989
 * 	Copyright (c) Adam de Boor 1989
 *
 * 	Permission to use, copy, modify, and distribute this
 * 	software and its documentation for any non-commercial purpose
 *	and without fee is hereby granted, provided that the above copyright
 * 	notice appears in all copies.  Neither Berkeley Softworks nor
 * 	Adam de Boor makes any representations about the suitability of this
 * 	software for any purpose.  It is provided "as is" without
 * 	express or implied warranty.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: sunrpc.c,v 1.3 89/10/10 00:38:33 adam Exp Locker: adam $";
#endif lint

#include    <sys/time.h>
#include    <sys/ioctl.h>
#include    <sys/types.h>
#include    <sys/socket.h>
#include    <sys/file.h>
#include    <rpc/rpc.h>
#include    <rpc/pmap_prot.h>
#include    <net/if.h>
#include    <arpa/inet.h>
#include    <sys/uio.h>
#include    <errno.h>
#include    <stdio.h>
#include    <setjmp.h>
#include    <sys/signal.h>

extern int  errno;

#define NO_RPC_STAT	/* Don't define customs RPC codes -- we use the
			 * Sun ones here */
#include    "rpc.h"
#include    "sunrpc.h"

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

#define SUN_MAX_DATA_SIZE   8192
#define	RQCRED_SIZE	400		/* this size is excessive */


#define SunRpcHash(id)	    	(((id) ^ (id >> 3) ^ (id >> 9)) & \
				 (CACHE_THREADS-1))

/*
 * RPC CACHE DEFINITIONS
 */
/*
 * The cache is kept as a table of doubly-linked lists, hashed on the ID of the
 * message, hanging from the SunRpcServer structure for the procedure call. The
 * 'prev' pointer of the first entry in the chain points to the pointer in
 * the table for that chain (i.e. *e->prev == e). Cache entries are flushed 10
 * seconds after their last reference.
 *
 * A cache entry may be in one of two states: replied-to or reply-pending.
 * If a call comes in that maps to an entry for which a reply is still
 * pending, the call is dropped, as Sun RPC has no "I'm working on it"
 * response as the PMake RPC does.
 *
 * If a call comes in that maps to an entry that has been replied-to, the
 * reply is resent and the call dropped.
 */
typedef struct CacheLink {
    struct SunCacheEntry    *next;
    struct SunCacheEntry    *prev;
} CacheLink;

typedef struct SunCacheEntry {
    CacheLink	    	link;	    /* Link in cache chain */
    enum {
	REPLY_PENDING,	    	    	/* Service of call is in progress */
	REPLY_SENT,	    	    	/* Reply has been sent already */
    }	    	  	status;	    /* Status of call */
    unsigned long  	id; 	    /* ID of call */
    struct sockaddr_in	from;	    /* Where call came from */
    Rpc_Event	  	flushEvent; /* Event to flush cache entry */
    enum clnt_stat  	error;	    /* If not RPC_SUCCESS, contains the
				     * error code returned for the call */
    Rpc_Opaque	  	replyData;  /* Data for reply */
    struct rpc_msg  	reply;	    /* Reply message */
    char    	    	verf[MAX_AUTH_BYTES];	/* Room for verifier for
						 * authentication */
} SunCacheEntry;

#define CACHE_THREADS	8  	/* The number of chains in each server
				 * cache. NOTE: dependence on this value
				 * in SunRpcHash() -- must be (2^n) */
/*
 * Structure describing an RPC server on a socket. The server is called
 *
 * enum clnt_stat
 * serverProc(from, msg, argp, resp, datum, respPtr)
 *	struct sockaddr_in *from;
 *	Rpc_Message msg;
 *	Rpc_Opaque  argp;
 *	Rpc_Opaque  resp;
 *	Rpc_Opaque  datum;
 *	Rpc_Opaque  *respPtr;
 *
 * msg is a token that may be used to obtain other info about the call (see
 * the SunRpc_Msg* functions).
 *
 * argp points to a buffer of the size indicated when the server was created
 * into which the arguments were decoded (the buffer is initially zero-inited
 * so the xdr function will allocate whatever memory is required). The
 * arguments will be automatically freed when the call is complete.
 *
 * resp points to a buffer for the response of the size indicated when the
 * server was created. The results will be encoded with the registered
 * response procedure if the server procedure returns RPC_SUCCESS.
 *
 * respPtr points to the pointer to the results in the call cache -- the
 * procedure can use it to store the correct address of the results should
 * the passed size be insufficient (this can happen with things that return
 * a variable-sized reply, especially since the data have to hang around until
 * the entry is flushed from the cache).
 *
 * If the server procedure returns non-zero, it is taken to be an error code
 * to be returned to the caller.
 */
typedef struct SunRpcServer {
    struct SunRpcServer	*next;
    unsigned long   	prog;	    /* Program being served */
    unsigned long   	vers;	    /* Version of same */
    unsigned long   	proc;	    /* Procedure being served */
    xdrproc_t	    	argproc;    /* Procedure to decode arguments */
    int	    	    	argsize;    /* Size of arguments */
    xdrproc_t	    	resproc;    /* Procedure to encode results */
    int	    	    	ressize;    /* Size of results */
    enum clnt_stat    	(*serverProc)();
    Rpc_Opaque	    	datum;
    CacheLink   	cache[CACHE_THREADS];
} SunRpcServer;

static SunRpcServer *sunRpcServers[FD_SETSIZE];

/*
 * Message record from which we provide extra info for the called server
 */
typedef struct {
    SunRpcServer    	*server;
    struct rpc_msg  	*msg;
    Rpc_Opaque	    	cred;
    int	    	    	stream;
} SunRpcMessage;

/*
 * Structure describing a pending call. The protocol-related structures are
 * predefined, of course, but...
 *
 */
typedef struct SunRpcCall {
    struct SunRpcCall	*next;
    unsigned long   	id; 	    /* Copy of ID number of message */

    /*
     * Information for receiving replies
     */
    enum clnt_stat  	status;	    /* Status of call */
    struct sockaddr_in	remote;	    /* Address of responder */
    int	    	    	replied;    /* Non-zero if reply received */
    Rpc_Opaque	    	reply;	    /* Place to store reply data */
    xdrproc_t	    	resproc;    /* Procedure to decode response if
				     * call succeeds */
    AUTH    	    	*auth;	    /* Authenticator used in call */

    /*
     * Information for issuing the call
     */
    int	    	    	sock;	    /* Socket over which to make the call */
    struct msghdr   	message;    /* Outgoing message */
    int	    	    	numRetries; /* Number of resends left */
    Rpc_Event	    	resend;	    /* Event used for resending */
} SunRpcCall;

static SunRpcCall   *sunRpcCalls[FD_SETSIZE];


/*
 * Interval for flushing a call entry from the cache
 */
static struct timeval	flushTimeOut = {
    10, 0
};
static int  	    	sunRpcDebug = 0;    /* Non-zero to turn on debugging
					     * output */

/***********************************************************************
 *				SunRpcUniqueID
 ***********************************************************************
 * SYNOPSIS:	    Return an unique identifier for a message.
 *	    	    Potential clashes between hosts are reduced by using
 *	    	    a random number on startup.
 * CALLED BY:	    SunRpc_Call
 * RETURN:	    The identifier
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
static unsigned long
SunRpcUniqueID()
{
    static unsigned long  nextID = 0;

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
 * SunRpcCacheFlushEntry --
 *	Flush an entry from a server's cache when it hasn't been
 *	referenced in a while.
 *
 * Results:
 *	False -- no need to stay awake.
 *
 * Side Effects:
 *	The SunCacheEntry structure is removed from the server's cache
 *	and freed.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
SunRpcCacheFlushEntry(e, ev)
    register SunCacheEntry  *e; 	/* Entry to flush */
    Rpc_Event	  	    ev; 	/* Event that caused this call */
{
    if (sunRpcDebug) {
	printf("Flushing entry for %u\n", e->id);
    }
    
    if (e->status == REPLY_PENDING) {
	/*
	 * Do *not* flush the entry until the reply has been sent, dimwit.
	 */
	if (sunRpcDebug) {
	    printf("...reply still pending, so timer reset\n");
	}
	Rpc_EventReset(ev, &flushTimeOut);
    } else {
	if ((e->flushEvent != ev) /* && sunRpcDebug */) {
	    printf("SunRpcCacheFlushEntry: flushEvent (%x) != ev (%x)\n",
		   e->flushEvent, ev);
	}
	Rpc_EventDelete(ev);
	remque(&e->link);
	if (e->replyData != (Rpc_Opaque)0) {
	    free((char *)e->replyData);
	}
	free((char *)e);
    }
    return (False);
}

/*-
 *-----------------------------------------------------------------------
 * SunRpcCacheDestroy --
 *	Clean out the cache for a SunRpcServer.
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
SunRpcCacheDestroy(s)
    SunRpcServer  	*s;    /* The server whose cache should be destroyed */
{
    register int  	    i;
    register SunCacheEntry  *e;
    
    for (i = 0; i < CACHE_THREADS; i++) {
	for (e = s->cache[i].next;
	     e != (SunCacheEntry *)&s->cache[i];
	     e = e->link.next)
	{
	    if (e->replyData != (Rpc_Opaque)0) {
		free((char *)e->replyData);
	    }
	    Rpc_EventDelete(e->flushEvent);
	    free((char *)e);	/* XXX */
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * SunRpcCacheFind --
 *	Find an RPC call in a server's cache. If it's not there and
 *	create is True, the entry is created and *entryNewPtr is set
 *	True. If the entry cannot be created, or doesn't exist and
 *	create is False, NULL is returned.
 *
 * Results:
 *	The SunCacheEntry for the call, or NULL if none.
 *
 * Side Effects:
 *	A SunCacheEntry structure may be created and linked into the cache
 *	for the server.
 *
 *-----------------------------------------------------------------------
 */
static SunCacheEntry *
SunRpcCacheFind(server, from, id, create, entryNewPtr)
    SunRpcServer  	*server;    	/* Server in whose cache the call
					 * should be sought */
    register struct sockaddr_in	*from; 	/* Origin of the call */
    unsigned long  	id; 	    	/* ID number of the call */
    Boolean 	  	create;	    	/* True if should create an entry
					 * if we don't find it */
    Boolean 	  	*entryNewPtr;	/* Set True if a new entry was
					 * created */
{
    register SunCacheEntry *e;
    register int  	chain;

    chain = SunRpcHash(id);
    e = server->cache[chain].next;
 
    /*
     * Look for existing cache entry.
     */
    if (sunRpcDebug) {
	printf("SunRpcCacheFind: seeking %d@%s #%u...",
	       ntohs(from->sin_port),
	       InetNtoA(from->sin_addr),
	       id);
    }
    while (e != (SunCacheEntry *)&server->cache[chain]) {
	if ((e->from.sin_addr.s_addr == from->sin_addr.s_addr) &&
	    (e->from.sin_port == from->sin_port) &&
	    (id == e->id))
	{
	    break;
	} else {
	    e = e->link.next;
	}
    }

    if (e == (SunCacheEntry *)&server->cache[chain]) {
	if (create) {
	    /*
	     * Create new entry and link it at the head of its chain,
	     * setting *entryNewPtr as necessary.
	     */
	    if (sunRpcDebug) {
		printf("creating new entry\n");
	    }
	    e = (SunCacheEntry *)malloc(sizeof(SunCacheEntry));
	    e->id = 	    id;
	    e->from =	    *from;
	    e->status =     REPLY_PENDING;
	    e->flushEvent = Rpc_EventCreate(&flushTimeOut,
					    SunRpcCacheFlushEntry,
					    (Rpc_Opaque)e);
	    e->error =	    RPC_SUCCESS;
	    e->replyData =  (Rpc_Opaque)0;

	    insque(&e->link, &server->cache[chain]);

	    if (entryNewPtr != (Boolean *)NULL) {
		*entryNewPtr = True;
	    }
	} else {
	    if (sunRpcDebug) {
		printf("returning NULL\n");
	    }
	    return ((SunCacheEntry *)NULL);
	}
    } else if (entryNewPtr != (Boolean *)NULL) {
	/*
	 * No new entry created -- mark *entryNewPtr false to indicate this
	 */
	if (sunRpcDebug) {
	    printf("found it\n");
	}
	*entryNewPtr = False;
    }
    
    /*
     * The entry was referenced, so reset the flush timer for it.
     */
    Rpc_EventReset(e->flushEvent, &flushTimeOut);
    return (e);
}


/***********************************************************************
 *				SunRpcHandleStream
 ***********************************************************************
 * SYNOPSIS:	    Deal with the readiness of a stream in which
 *	    	    we've registered interest.
 * CALLED BY:	    Rpc_Wait
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The packet is read from the socket.
 *
 * STRATEGY:
 *	Because of the way the XDR routines for the RPC protocol are
 *	set up, we have to go through a little bit of rigamarole before
 *	we can actually decode the message. The trouble is, both
 *	xdr_callmsg and xdr_replymsg expect to have the xdr routine for
 *	the args/results, along with a pointer to them, stored in the
 *	message so the routine can be called at the right point. We're
 *	not like the Sun RPC, in that we don't know what kind of packet
 *	might be arriving here, so we have to kludge the decision a bit.
 *	Once we know what type of packet it is, we can do as the romans
 *	do...sort of.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
/*ARGSUSED*/
static void
SunRpcHandleStream(stream, data, what)
    int	    	stream;	    /* Stream that's ready */
    Rpc_Opaque	data;	    /* Data we stored (UNUSED) */
    int	    	what;	    /* For what it's ready (UNUSED) */
{
    struct sockaddr_in	remote;	    /* Address of sender */
    int	    	    	remotelen;  /* Size of 'remote' (for recvfrom) */
    unsigned char   	buf[SUN_MAX_DATA_SIZE];
    int	    	    	msgLen;	    /* Length of received datagram */
    XDR    	    	xdr;	    /* XDR stream to 'buf' */
    struct rpc_msg  	msg;	    /* Received message */
    unsigned long	xid;	    /* ID of same */
    enum msg_type   	direction;  /* Direction message is going */

    if (sunRpcDebug) {
	printf("%d ready: ", stream);
    }
    
    /*
     * Keep trying to read the message as long as the recvfrom call is
     * interrupted.
     */
    do {
	remote.sin_addr.s_addr = 0;
	remotelen = sizeof(remote);
	msgLen = recvfrom(stream, buf, sizeof(buf), 0,
			  (struct sockaddr *)&remote, &remotelen);
    } while ((msgLen < 0) && (errno == EINTR));

    /*
     * Error-check results.
     */
    if (msgLen < 0) {
	perror("recvfrom");
	return;
    }

    if (msgLen < 4 * sizeof(unsigned long)) {
	if (sunRpcDebug) {
	    fprintf(stderr,
		    "SunRpcHandleStream: msgLen = %d (too short...)\n",
		    msgLen);
	}
	return;
    }
    
    /*
     * Set up a memory stream to decode the packet and for use in encoding
     * things into buf once the packet has been dealt with.
     */
    xdrmem_create(&xdr, buf, sizeof(buf), XDR_DECODE);

    /*
     * Fetch the message ID and direction so we know what to do.
     */
    XDR_GETLONG(&xdr, &xid);
    xdr_enum(&xdr, &direction);
	
    switch(direction) {
	case CALL:
	{
	    SunRpcMessage   srpcmsg;	/* Message token for server */
	    SunRpcServer    *s;	    	/* Server found */
	    unsigned long   low,    	/* Lowest version for program so far */
			    high;   	/* Highest version for prog so far */
	    enum accept_stat status;	/* Status to return. Set to
					 * PROG_MISMATCH if a server for
					 * the (prog,proc) pair is found,
					 * but the version number is wrong */
	    int	    	    slen;   	/* Stream length for reply message */
	    /*
	     * Space for decoding credentials. Size comes from Sun RPC code.
	     */
	    char    	    cred_area[2*MAX_AUTH_BYTES + RQCRED_SIZE];

	    /*
	     * Set up fields of call message required by decode.
	     */
	    msg.rm_call.cb_cred.oa_base = cred_area;
	    msg.rm_call.cb_verf.oa_base = &cred_area[MAX_AUTH_BYTES];

	    XDR_SETPOS(&xdr, 0);
	    if (!xdr_callmsg(&xdr, &msg)) {
		if (sunRpcDebug) {
		    fprintf(stderr, "Couldn't decode call message\n");
		}
		return;
	    }

	    /*
	     * Locate a server for the call. At the end, s points to the
	     * proper server record, if any. If none, it will be NULL,
	     * status will be the proper return status and low & high will
	     * contain the range of program versions for the (prog,proc)
	     * requested, if any such version is available.
	     */
	    low = 0 - 1;
	    high = 0;

	    status = PROG_UNAVAIL;
	    
	    for (s = sunRpcServers[stream]; s != NULL; s = s->next) {
		if (s->prog == msg.rm_call.cb_prog) {
		    /*
		     * Switch to "procedure unavailable" if still on
		     * "program unavailable" since we've found *something*
		     * for the program.
		     */
		    if (status == PROG_UNAVAIL) {
			status = PROC_UNAVAIL;
		    }

		    if (s->proc == msg.rm_call.cb_proc) {
			if (s->vers == msg.rm_call.cb_vers) {
			    break;
			} else {
			    /*
			     * Wrong version of (prog,proc) pair -- switch
			     * from "procedure unavailable" error to
			     * "version mismatch" error and keep track of
			     * the version range that's available for return.
			     */
			    status = PROG_MISMATCH;
			    if (s->vers < low) {
				low = s->vers;
			    }
			    if (s->vers > high) {
				high = s->vers;
			    }
			}
		    }
		}
	    }

	    if (s != NULL) {
		/*
		 * Have a server -- see if the call was cached and enter it
		 * into the cache if not.
		 */
		SunCacheEntry	*e;
		Boolean	    	isNew;

		e = SunRpcCacheFind(s, &remote, xid, TRUE, &isNew);

		if (isNew) {
		    /*
		     * Brand-new call -- authenticate the message,
		     * allocate room for and decode the args,
		     * allocate room for the results and call out to the server
		     * procedure.
		     */
		    Rpc_Opaque	    args;   /* Pointer to allocated args */
		    Rpc_Opaque	    res;    /* Pointer to allocated results */
		    enum clnt_stat  stat;   /* Status to return */
		    struct svc_req  r;	    /* "Request" for authentication */
		    SVCXPRT 	    xprt;   /* "Transport" for obtaining
					     * verifier */
		    enum auth_stat  why;    /* Result of authentication */

		    /*
		     * Set direction and ID of reply message.
		     */
		    e->reply.rm_xid = msg.rm_xid;
		    e->reply.rm_direction = REPLY;
		    
		    /*
		     * Set up request and attempt to authenticate the
		     * message.
		     */
		    xprt.xp_verf.oa_base = e->verf;
		    r.rq_xprt = &xprt;
		    r.rq_prog = msg.rm_call.cb_prog;
		    r.rq_vers = msg.rm_call.cb_vers;
		    r.rq_proc = msg.rm_call.cb_proc;
		    r.rq_cred = msg.rm_call.cb_cred;
		    r.rq_clntcred = &(cred_area[2*MAX_AUTH_BYTES]);

		    why = _authenticate(&r, &msg);
		    if (why != AUTH_OK) {
			e->reply.rm_reply.rp_stat = MSG_DENIED;
			e->reply.rjcted_rply.rj_stat = AUTH_ERROR;
			e->reply.rjcted_rply.rj_why = why;
		    } else {
			/*
			 * Message has been accepted -- record that and the
			 * verifier returned by the authentication system.
			 */
			e->reply.rm_reply.rp_stat = MSG_ACCEPTED;
			e->reply.acpted_rply.ar_verf = xprt.xp_verf;
			
#ifdef MEM_TRACE
			args = (Rpc_Opaque)calloc_tagged(s->argsize, 1, 1);
#else
			args = (Rpc_Opaque)calloc(s->argsize, 1);
#endif
			if (!(*s->argproc)(&xdr, args)) {
			    /*
			     * Couldn't decode the arguments -- choke
			     */
			    stat = RPC_CANTDECODEARGS;
			} else {
			    /*
			     * Allocate and record reply data in cache entry.
			     */
#ifdef MEM_TRACE
			    res = (Rpc_Opaque)calloc_tagged(s->ressize, 1, 2);
#else
			    res = (Rpc_Opaque)calloc(s->ressize, 1);
#endif
			    e->replyData = res;
			    
			    /*
			     * Set up message token by which server can acquire
			     * more info.
			     */
			    srpcmsg.server = s;
			    srpcmsg.msg = &msg;
			    srpcmsg.cred = r.rq_clntcred;
			    srpcmsg.stream = stream;
			    
			    /*
			     * Call out to the server. It should fill in resp
			     * and return a status.
			     */
			    stat = (*s->serverProc)(&remote,
						    (Rpc_Message)&srpcmsg,
						    args,
						    res,
						    s->datum,
						    &e->replyData);
			}
			
			if (stat != RPC_SUCCESS) {
			    /*
			     * Failure -- encode clnt_stat into wire status.
			     * This is pretty easy.
			     */
			    if (stat == RPC_AUTHERROR) {
				e->reply.rm_reply.rp_stat = MSG_DENIED;
				e->reply.rjcted_rply.rj_stat = AUTH_ERROR;
				e->reply.rjcted_rply.rj_why = AUTH_TOOWEAK;
			    } else if (stat == RPC_CANTDECODEARGS) {
				e->reply.acpted_rply.ar_stat = GARBAGE_ARGS;
			    } else {
				/*
				 * Anything else is a "system error"
				 */
				e->reply.acpted_rply.ar_stat = SYSTEM_ERR;
			    }
			    /*
			     * Free the results, which are likely to be
			     * garbage, and shouldn't be returned in any case.
			     */
			    free(e->replyData);
			    e->replyData = NULL;
			} else {
			    /*
			     * Set up the where and proc fields of the reply
			     * message so the results get encoded properly.
			     * Set the reply status to SUCCESS because we were.
			     */
			    e->reply.acpted_rply.ar_stat = SUCCESS;
			    e->reply.acpted_rply.ar_results.proc = s->resproc;
			    e->reply.acpted_rply.ar_results.where =
				e->replyData;
			}

			/*
			 * Free up the arguments
			 */
			if (stat != RPC_CANTDECODEARGS) {
			    xdr.x_op = XDR_FREE;
			    (* s->argproc) (&xdr, args);
			}
			free(args);

			/*
			 * If status is special "drop this" code, nuke
			 * the entry (so the resend will be handled -- the
			 * only thing this is used for so far is getting
			 * a mount request while trying to mount something,
			 * in which case we want the resend to get through)
			 * and return now.
			 */
			if (stat == SUNRPC_DONTRESPOND) {
			    SunRpcCacheFlushEntry(e, e->flushEvent);
			    return;
			}
		    }
		    
		    /*
		     * Pretend a reply has been sent so code below will
		     * actually "resend" the reply we've built.
		     */
		    e->status = REPLY_SENT;
		}

		if (e->status == REPLY_SENT) {
		    /*
		     * A reply has been sent before (or needs to be). Put
		     * together a message from the rpc_msg and the
		     * reply data and ship the thing off to the caller.
		     */
		    xdr.x_op = XDR_ENCODE;
		    XDR_SETPOS(&xdr, 0);
		    if (!xdr_replymsg(&xdr, &e->reply)) {
			return;
		    }
		} else {
		    /*
		     * Pending replies can't be dealt with, since Sun RPC
		     * has no explicit acknowledge as Customs RPC does.
		     */
		    return;
		}
	    } else {
		/*
		 * Can't find server -- reply with whatever status we've
		 * determined is appropriate. First, we need to fetch
		 * a verifier for the credentials and authenticate the message.
		 *
		 * Note we can't do this above, as it relies on having a
		 * cache entry. Other possibility is to fake a cache entry.
		 */
		struct svc_req  r;	/* "Request" for authentication */
		SVCXPRT 	xprt;   /* "Transport" for obtaining
					 * verifier */
		enum auth_stat  why;    /* Result of authentication */
		char	    	verf[MAX_AUTH_BYTES];
		struct rpc_msg	reply;

		/*
		 * Set up ID and direction of message
		 */
		reply.rm_xid = msg.rm_xid;
		reply.rm_direction = REPLY;

		/*
		 * Set up request and attempt to authenticate the
		 * message.
		 */
		xprt.xp_verf.oa_base = verf;
		r.rq_xprt = &xprt;
		r.rq_prog = msg.rm_call.cb_prog;
		r.rq_vers = msg.rm_call.cb_vers;
		r.rq_proc = msg.rm_call.cb_proc;
		r.rq_cred = msg.rm_call.cb_cred;
		r.rq_clntcred = &(cred_area[2*MAX_AUTH_BYTES]);
		
		why = _authenticate(&r, &msg);
		if (why != AUTH_OK) {
		    reply.rm_reply.rp_stat = MSG_DENIED;
		    reply.rjcted_rply.rj_stat = AUTH_ERROR;
		    reply.rjcted_rply.rj_why = why;
		} else {
		    /*
		     * Message is kosher, but we still can't handle
		     * the request -- set up an accepted_reply with
		     * the status and verifier we've worked out.
		     */
		    reply.rm_reply.rp_stat = MSG_ACCEPTED;
		    reply.acpted_rply.ar_stat = status;
		    reply.acpted_rply.ar_verf = xprt.xp_verf;
		    if (status == PROG_MISMATCH) {
			reply.acpted_rply.ar_vers.low = low;
			reply.acpted_rply.ar_vers.high = high;
		    }
		}
		/*
		 * Encode the whole message into buf.
		 */
		xdr.x_op = XDR_ENCODE;
		XDR_SETPOS(&xdr, 0);
		if (!xdr_replymsg(&xdr, &reply)) {
		    return;
		}
	    }

	    /*
	     * Buf now contains the message to be transmitted back to
	     * the caller.
	     */
	    slen = (int)XDR_GETPOS(&xdr);
	    
	    /*
	     * Try and send the datagram while we keep getting
	     * interrupted..
	     */
	    while ((sendto(stream, buf, slen, 0,
			   &remote, sizeof(remote)) != slen) &&
		   (errno == EINTR))
	    {
		;
	    }
	    break;
	}
	case REPLY:
	{
	    /*
	     * Reset the stream to its start again and attempt to decode
	     * it as a reply.
	     */
	    SunRpcCall      *call,
			    **prev;
	    struct rpc_err  err;
	    
	    
	    XDR_SETPOS(&xdr, 0);
	    bzero(&msg, sizeof(msg));
	    
	    /*
	     * Try and locate a call with the ID, since we need to store the
	     * proc and buffer location in the rpc_msg before calling
	     * xdr_replymsg...
	     */
	    
	    prev = &sunRpcCalls[stream];
	    for (call = sunRpcCalls[stream]; call != 0; call = call->next) {
		if (xid == call->id) {
		    break;
		} else {
		    prev = &call->next;
		}
	    }
	    
	    if (call == (SunRpcCall *)0) {
		if (sunRpcDebug) {
		    printf("unknown packet (no pending call of id %u)", xid);
		}
		return;
	    } else {
		/*
		 * Set up to decode successful reply.
		 */
		msg.acpted_rply.ar_results.where = call->reply;
		msg.acpted_rply.ar_results.proc = call->resproc;
		msg.acpted_rply.ar_verf = _null_auth;
		
		if (!xdr_replymsg(&xdr, &msg)) {
		    /*
		     * Nope -- no idea what it could be. Just discard the
		     * packet.
		     */
		    if (sunRpcDebug) {
			fprintf(stderr, "Couldn't decode reply message");
		    }
		    return;
		}
	    }
	    
	    if (sunRpcDebug) {
		printf("Reply to %u: ", msg.rm_xid);
	    }
	    
	    /*
	     * Mark the call as replied, then figure out how successful we
	     * were.
	     */
	    call->replied = True;
	    
	    /*
	     * Decode wire result into more manageable error code, passing that
	     * back to caller.
	     */
	    _seterr_reply(&msg, &err);
	    call->status = err.re_status;
	    call->remote = remote;
	    
	    if (err.re_status == RPC_SUCCESS) {
		/*
		 * Successful completion -- verify the responder is OK.
		 */
		if (!AUTH_VALIDATE(call->auth, &msg.acpted_rply.ar_verf)) {
		    /*
		     * Nope -- return an authentication error.
		     */
		    call->status = RPC_AUTHERROR;
		}
		if(msg.acpted_rply.ar_verf.oa_base != NULL) {
		    /*
		     * Had credentials -- free any memory allocated for them
		     */
		    xdr.x_op = XDR_FREE;
		    (void)xdr_opaque_auth(&xdr, &msg.acpted_rply.ar_verf);
		}
	    }
	    /*
	     * Unlink call from chain.
	     */
	    *prev = call->next;
	    break;
	}
	default:
	    if (sunRpcDebug) {
		fprintf(stderr, "Unknown direction: %d\n", direction);
	    }
	    break;
    }

    /*
     * No need to destroy the stream, since it's all allocated locally.
     */
}


/***********************************************************************
 *				SunRpc_MsgStream
 ***********************************************************************
 * SYNOPSIS:	    Return the stream over which a message arrived
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The stream
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
int
SunRpc_MsgStream(msg)
    Rpc_Message	msg;
{
    return ((SunRpcMessage *)msg)->stream;
}

/***********************************************************************
 *				SunRpc_MsgProg
 ***********************************************************************
 * SYNOPSIS:	    Return the program for which message arrived
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The program number
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
unsigned long
SunRpc_MsgProg(msg)
    Rpc_Message	msg;
{
    return ((SunRpcMessage *)msg)->server->prog;
}

/***********************************************************************
 *				SunRpc_MsgVers
 ***********************************************************************
 * SYNOPSIS:	    Return the version number for which message arrived
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The version number
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
unsigned long
SunRpc_MsgVers(msg)
    Rpc_Message	msg;
{
    return ((SunRpcMessage *)msg)->server->vers;
}

/***********************************************************************
 *				SunRpc_MsgProc
 ***********************************************************************
 * SYNOPSIS:	    Return the procedure for which message arrived
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The procedure number
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
unsigned long
SunRpc_MsgProc(msg)
    Rpc_Message	msg;
{
    return ((SunRpcMessage *)msg)->server->proc;
}

/***********************************************************************
 *				SunRpc_MsgRawCred
 ***********************************************************************
 * SYNOPSIS:	    Return the address of the raw credentials for the
 *	    	    message
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The raw credentials
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
struct opaque_auth *
SunRpc_MsgRawCred(msg)
    Rpc_Message	msg;
{
    return &((SunRpcMessage *)msg)->msg->rm_call.cb_cred;
}

/***********************************************************************
 *				SunRpc_MsgCred
 ***********************************************************************
 * SYNOPSIS:	    Return the processed credentials for the message
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The processed credentials
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/23/89		Initial Revision
 *
 ***********************************************************************/
caddr_t
SunRpc_MsgCred(msg)
    Rpc_Message	msg;
{
    return ((SunRpcMessage *)msg)->cred;
}


/***********************************************************************
 *				SunRpcResend
 ***********************************************************************
 * SYNOPSIS:	    Resend a registered call.
 * CALLED BY:	    SunRpc_Call and Rpc_Wait (resend event)
 * RETURN:	    TRUE if call timed out -- causes Rpc_Wait to return
 *	    	    immediately rather than going to sleep.
 * SIDE EFFECTS:    call->replied will be set True on timeout
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
SunRpcResend(call)
    SunRpcCall	    *call;  	/* Record for message to be sent */
{
    register SunRpcCall	*c; 	    /* Current call in list */
    register SunRpcCall	**prev;	    /* Pointer to next field of previous call*/
    int	    	  	numBytes;   /* Number of bytes in message */
    enum clnt_stat  	status;	    /* Status of call */
    
    if (!call->replied) {
	if (sunRpcDebug) {
	    printf("Resending %u: ", call->id);
	}
	if (call->numRetries != 0) {
	    call->numRetries -= 1;
	    if (sunRpcDebug) {
		printf("%d left\n", call->numRetries);
	    }
	send_again:
	    do {
		numBytes = sendmsg (call->sock, &call->message, 0);
	    } while ((numBytes < 0) && (errno == EINTR));

	    if (numBytes < 0) {
		if (sunRpcDebug) {
		    perror("RpcResend");
		}
		switch(errno) {
		    case EMSGSIZE:
			status = RPC_CANTSEND;
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
			    if (sunRpcDebug) {
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
	    if (sunRpcDebug) {
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
	    
	    prev = &sunRpcCalls[call->sock];
	    for (c = sunRpcCalls[call->sock]; c != 0; c = c->next) {
		if (c == call) {
		    break;
		} else {
		    prev = &c->next;
		}
	    }
	    if (c != 0) {
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
	if(sunRpcDebug) {
	    printf("Resend on replied-to message %u\n", call->id);
	}
	return(True);
    }
}

/***********************************************************************
 *				SunRpc_Call
 ***********************************************************************
 * SYNOPSIS:	    Perform a call to a remote service
 * CALLED BY:	    EXTERNAL and recursive (if no port given for call)
 * RETURN:	    status of call
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
enum clnt_stat
SunRpc_Call(sock, server, auth, progNum, procNum, versNum, inProc, inData,
	    outProc, outData, numRetries, retry)
    int	    	    	sock;       /* Socket on which to call */
    struct sockaddr_in	*server;    /* Location of server. If port is 0,
				     * we will contact port mapper to find
				     * the proper port */
    AUTH    	    	*auth;	    /* Credentials for call */
    int	    	    	progNum;    /* Program to call */
    int	    	    	procNum;    /* Procedure within same */
    int	    	    	versNum;    /* Versionof same */
    xdrproc_t	    	inProc;	    /* Procedure to encode args */
    caddr_t 	    	inData;	    /* Data to pass */
    xdrproc_t	    	outProc;    /* Procedure to decode results */
    caddr_t 	    	outData;    /* Place to store results */
    int	    	    	numRetries; /* Number of times to retry call */
    struct timeval  	*retry;	    /* Interval between retries */
{
    SunRpcCall	    	call;	    /* Call descriptor for Resend and
				     * HandleStream */
    struct iovec    	iov[1];	    /* Vector for sendmsg */
    struct rpc_msg    	message;    /* Message to be sent */
    char    	    	msgbuf[SUN_MAX_DATA_SIZE];
    XDR	    	    	xdr;	    /* Stream for encoding message into
				     * msgbuf */
    int	    	    	nrefreshes; /* Number of times to refresh old
				     * credentials */

    if (server->sin_port == 0) {
	struct sockaddr_in  pmap;   /* Address of portmapper */
	unsigned short	    port;   /* Value returned by same */
	struct pmap 	    arg;    /* Args to GETPORT call */
	struct timeval	    timeout;/* Resend interval */
	enum clnt_stat 	    result; /* Result of call */

	/*
	 * Set up address of portmapper on server's machine
	 */
	pmap.sin_family = AF_INET;
	pmap.sin_port = htons(PMAPPORT);
	pmap.sin_addr = server->sin_addr;
	/*
	 * Set up parameters for query of remote side.
	 * XXX: always looks for UDP mapping.
	 */
	arg.pm_prog = progNum;
	arg.pm_vers = versNum;
	arg.pm_prot = IPPROTO_UDP;
	arg.pm_port = 0;    	    /* Not needed or used, but init anyway */
	/*
	 * Resend at 2.5 second interval
	 */
	timeout.tv_sec = 2;
	timeout.tv_usec = 500000;

	/*
	 * Recurse to issue call to portmapper
	 */
	result = SunRpc_Call(sock, &pmap, authnone_create(),
			     PMAPPROG, PMAPPROC_GETPORT, PMAPVERS,
			     xdr_pmap, &arg, xdr_u_short, &port,
			     3, &timeout);
	if (result != RPC_SUCCESS) {
	    return(result);
	} else if (port == 0) {
	    /*
	     * If not registered, return PROGUNAVAIL error
	     */
	    return (RPC_PROGUNAVAIL);
	}
	/*
	 * Set port in passed address, both for now and later.
	 */
	server->sin_port = htons(port);
    }

    /*
     * Set up the message for sendmsg first
     */
    call.message.msg_name = 	    (caddr_t)server;
    call.message.msg_namelen =	    sizeof(*server);
    call.message.msg_iov =  	    iov;
    call.message.msg_iovlen =	    1;
    call.message.msg_accrights =    (caddr_t)0;
    call.message.msg_accrightslen = 0;

    /*
     * Set up the constant portion of the call record.
     */
    call.sock =	    	    	    sock;
    call.numRetries =		    numRetries;
    call.reply =    	    	    (Rpc_Opaque)outData;
    call.resproc =		    outProc;
    call.auth =	    	    	    auth;
    call.resend =   	    	    Rpc_EventCreate(retry,
						    SunRpcResend,
						    (Rpc_Opaque)&call);

    message.rm_direction =	    CALL;
    message.rm_call.cb_rpcvers=     RPC_MSG_VERSION;
    message.rm_call.cb_prog =       progNum;
    message.rm_call.cb_vers =       versNum;
    message.rm_call.cb_proc =       procNum;
    
    /*
     * Open an XDR memory stream to encode the call into msgbuf. The io vector
     * gets pointed at msgbuf as well -- the length will be set once things
     * are encoded.
     */
    xdrmem_create(&xdr, msgbuf, sizeof(msgbuf), XDR_ENCODE);
    iov[0].iov_base = msgbuf;

    for (nrefreshes = 2; nrefreshes > 0; nrefreshes -= 1) {
	/*
	 * Set the ID and link the call into the list of calls for the socket.
	 * The 'replied' field gets set False so we know when a reply has
	 * come in or the call has timed out.
	 */
	message.rm_xid = call.id = SunRpcUniqueID();
	call.replied =  	   False;
	call.next =		   sunRpcCalls[sock];
	sunRpcCalls[sock] =	   &call;

	/*
	 * Encode the header, procedure number, credentials and arguments
	 * into the msgbuf buffer.
	 */
	if (!xdr_callhdr(&xdr, &message) ||
	    ! XDR_PUTLONG(&xdr, &message.rm_call.cb_proc) ||
	    ! AUTH_MARSHALL(auth, &xdr) ||
	    ! (*inProc)(&xdr, inData))
	{
	    /*
	     * Remove the call from the call chain by hand and set the status
	     * to be CANTENCODEARGS, then break out to finish up other
	     * cleanup.
	     */
	    sunRpcCalls[sock] = call.next;
	    call.status = RPC_CANTENCODEARGS;
	    break;
	}
	/*
	 * Record size of message in the io vector.
	 */
	iov[0].iov_len = XDR_GETPOS(&xdr);

	/*
	 * Pay attention to the socket if wasn't doing so before, then call
	 * SunRpcResend to send the initial call.
	 */
	Rpc_Watch(sock, RPC_READABLE, SunRpcHandleStream, (Rpc_Opaque)0);
	(void)SunRpcResend(&call);

	/*
	 * Wait for some sort of reply
	 */
	while (!call.replied) {
	    Rpc_Wait();
	}

	/*
	 * If no-one else interested in the socket, ignore it.
	 */
	if ((sunRpcCalls[sock] == 0) && (sunRpcServers[sock] == 0)) {
	    Rpc_Ignore(sock);
	}
	
	/*
	 * The only time we loop is if (1) the call failed due to bad
	 * authentication and (2) AUTH_REFRESH indicates there was something
	 * that could be done (i.e. our credentials might have been stale.
	 */
	if ((call.status != RPC_AUTHERROR) || !AUTH_REFRESH(auth)) {
	    break;
	}
    }

    /*
     * Now we know we're done, nuke the resend event.
     */
    Rpc_EventDelete(call.resend);

    /*
     * Return the status we got from the other side.
     */
    return(call.status);
}



/***********************************************************************
 *				SunRpc_ServerCreate
 ***********************************************************************
 * SYNOPSIS:	    Bind a procedure to a <program,version,procedure,socket>
 *	    	    tuple.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing.
 * SIDE EFFECTS:    A SunRpcServer record is created and the socket's
 *	    	    handling procedure is set to SunRpcHandleStream,
 *	    	    nuking any previous handler.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
void
SunRpc_ServerCreate(sock, progNum, procNum, versNum, proc, data,
		    argSize, argProc, resSize, resProc)
    int	    	    sock;	/* Socket over which calls will come */
    unsigned long   progNum;	/* Program number to serve */
    unsigned long   procNum;	/* Procedure number in same */
    unsigned long   versNum;	/* Version of same */
    enum clnt_stat  (*proc)();	/* Procedure to call */
    Rpc_Opaque	    data;   	/* Data to pass it */
    int	    	    argSize;	/* Space to allocate for args */
    xdrproc_t	    argProc;	/* Argument decode procedure */
    int	    	    resSize;	/* Space to allocate for results */
    xdrproc_t	    resProc;	/* Results encode procedure */
{
    SunRpcServer    *server;
    CacheLink	    *c;
    int	    	    i;

    server = (SunRpcServer *)malloc(sizeof(SunRpcServer));
    server->prog    	= progNum;
    server->proc    	= procNum;
    server->vers    	= versNum;
    server->argproc 	= argProc;
    server->argsize 	= argSize;
    server->resproc 	= resProc;
    server->ressize 	= resSize;
    server->serverProc	= proc;
    server->datum   	= data;
    server->next    	= sunRpcServers[sock];
    sunRpcServers[sock]	= server;

    /*
     * Initialize cache links to point to themselves.
     */
    for (i = CACHE_THREADS, c = server->cache; i > 0; i--, c++) {
	c->next = c->prev = (struct SunCacheEntry *)c;
    }

    Rpc_Watch(sock, RPC_READABLE, SunRpcHandleStream, (Rpc_Opaque)0);
}

/***********************************************************************
 *				SunRpc_ServerDelete
 ***********************************************************************
 * SYNOPSIS:	    Remove a binding to a procedure.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If no servers or calls left on the socket, the
 *	    	    socket is ignored.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
void
SunRpc_ServerDelete(sock, progNum, procNum, versNum)
    int	    	    sock;	/* Socket over which calls will come */
    unsigned long   progNum;	/* Program number to serve */
    unsigned long   procNum;	/* Procedure number in same */
    unsigned long   versNum;	/* Version of same */
{
    SunRpcServer    *s, **prev;

    prev = &sunRpcServers[sock];

    for (s = *prev; s != 0; s = *prev) {
	if ((s->prog==progNum) && (s->proc==procNum) && (s->vers==versNum)) {
	    break;
	} else {
	    prev = &s->next;
	}
    }
    if (s) {
	*prev = s->next;

	SunRpcCacheDestroy(s);
	free((char *)s);
    }

    if (sunRpcServers[sock] == 0 && sunRpcCalls[sock] == 0) {
	Rpc_Ignore(sock);
    }
}
