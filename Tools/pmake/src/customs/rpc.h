/*-
 * rpc.h --
 *	Declarations required by users of the rpc module.
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
 *	"$Id: rpc.h,v 1.3 96/08/02 15:29:08 jacob Exp $ SPRITE (Berkeley)"
 */
#ifndef _RPC_H_
#define _RPC_H_

/*
 * Beware! Some systems are brain-dead when it comes to sys/types...
 */
#include    <sys/types.h>
#include    <netinet/in.h>
#include    <sys/time.h>

/*
 * Boolean arguments
 */
#define True	  1
#define False	  0

#ifndef Boolean
#define Boolean	  int
#endif Boolean

/*
 * Define macros for select bitmap manipulation. What this will do on
 * systems that don't allow this many open descriptors, I don't know.
 */
#ifndef FD_SET

#define	NBBY	8		/* number of bits in a byte */
/*
 * Select uses bit masks of file descriptors in longs.
 * These macros manipulate such bit fields (the filesystem macros use chars).
 * FD_SETSIZE may be defined by the user, but the default here
 * should be >= NOFILE (param.h).
 */
#ifndef	FD_SETSIZE
#define	FD_SETSIZE	256
#endif

typedef long	fd_mask;
#define NFDBITS	(sizeof(fd_mask) * NBBY)	/* bits per mask */
#ifndef howmany
#define	howmany(x, y)	((unsigned int)(((x)+((y)-1)))/(unsigned int)(y))
#endif

typedef	struct fd_set {
	fd_mask	fds_bits[howmany(FD_SETSIZE, NFDBITS)];
} fd_set;

#define	FD_SET(n, p)	((p)->fds_bits[(n)/NFDBITS] |= (1 << ((n) % NFDBITS)))
#define	FD_CLR(n, p)	((p)->fds_bits[(n)/NFDBITS] &= ~(1 << ((n) % NFDBITS)))
#define	FD_ISSET(n, p)	((p)->fds_bits[(n)/NFDBITS] & (1 << ((n) % NFDBITS)))
#define FD_ZERO(p)	bzero((char *)(p), sizeof(*(p)))

#endif /* FD_SET */

/*
 * Flags for Rpc_Watch
 */
#define RPC_READABLE	1
#define RPC_WRITABLE	2
#define RPC_EXCEPTABLE	4

typedef unsigned short 	Rpc_Proc;
typedef void 	       *Rpc_Opaque;

typedef Rpc_Opaque  	Rpc_Event;  	/* Type returned by Rpc_EventCreate */
typedef Rpc_Opaque  	Rpc_Message;	/* Handle for replying to a call */

/* These are the callback function prototypes for the various exported
 * routines */

typedef void    RpcWatchCallback     ();
typedef void    RpcCallHandler       ();
typedef void    RpcSwapHandler       ();
typedef Boolean RpcEventCallback     ();
typedef Boolean RpcBroadcastCallback ();

/*
 * For prefix's sunrpc module, we need to avoid defining this thing as an
 * enumerated type, since Sun RPC uses these same names (funny how that works)
 */
#ifndef NO_RPC_STAT
typedef enum {
    RPC_SUCCESS,	    /* Call succeeded, here's reply data */
    RPC_CANTSEND, 	    /* Couldn't send message, for some reason */
    RPC_TIMEDOUT,  	    /* Message timed out */
    RPC_TOOBIG,	  	    /* Results (or message) too big */
    RPC_NOPROC,	  	    /* No such procedure on remote machine */
    RPC_ACCESS,	  	    /* Permission denied */
    RPC_BADARGS,  	    /* Arguments were improper */
    RPC_SYSTEMERR,	    /* Undefined system error */
} Rpc_Stat;
#else
typedef int Rpc_Stat;
#endif

/*
 * Swapping definitions
 */
#define Rpc_SwapNull	((void (*)())0)	  /* Constant for no swapping */
extern void	  Rpc_SwapShort();  	  /* Swap a short integer (two bytes) */
extern void	  Rpc_SwapLong ();  	  /* Swap a long integer (four bytes) */

/*
 * Other definitions
 */
extern void	  Rpc_ServerCreate    (int sock, Rpc_Proc procNum,
                                       RpcCallHandler serverProc,
                                       RpcSwapHandler swapArgsProc,
                                       void (*swapReplyProc)(void),
                                       Rpc_Opaque serverData);
                                          /* Create a service on a socket */
extern void	  Rpc_ServerDelete    (int sock, Rpc_Proc procNum);
                                          /* Delete a service on a socket */
extern Rpc_Event  Rpc_EventCreate     (struct timeval *interval,
				       RpcEventCallback handler,
				       Rpc_Opaque data);
                                          /* Create a timer event */
extern void	  Rpc_EventDelete     (Rpc_Event event);
                                          /* Delete a timer event */
extern void	  Rpc_EventReset      (Rpc_Event event,
				       struct timeval *interval);
                                          /* Reset the time of an event */
extern void	  Rpc_Watch           (int stream, int state,
				       RpcWatchCallback handler,
				       Rpc_Opaque data);
                                          /* Watch a stream */
extern void	  Rpc_Ignore          (int stream);
                                          /* Ignore a stream */
extern void	  Rpc_Error           (Rpc_Message rpcMsg, Rpc_Stat stat);
                                          /* Return an error to an RPC call */
extern void	  Rpc_Return          (Rpc_Message rpcMsg, int length,
                                       Rpc_Opaque data);
                                          /* Return a reply to an RPC call */
extern Rpc_Stat   Rpc_Call            (int sock, struct sockaddr_in *server,
				       Rpc_Proc procNum, int inLength,
				       Rpc_Opaque inData, int outLength,
				       Rpc_Opaque outData, int numRetries,
				       struct timeval *retry);
                                          /* Call a remote procedure */
extern Rpc_Stat   Rpc_Broadcast       (int sock, struct sockaddr_in *server,
				       Rpc_Proc procNum, int inLength,
				       Rpc_Opaque inData, int outLength,
				       Rpc_Opaque outData, int numRetries,
				       struct timeval *retry,
				       Boolean (*handleProc)(void),
				       Rpc_Opaque handleData);
                                          /* Broadcast a call to a remote
					   * procedure */
extern Rpc_Stat	  Rpc_BroadcastToNets (int sock, struct sockaddr_in *networks,
				       unsigned numNets, Rpc_Proc procNum,
				       int inLength, Rpc_Opaque inData,
				       int outLength, Rpc_Opaque outData,
				       int numRetries, struct timeval *retry,
				       RpcBroadcastCallback handleProc,
				       Rpc_Opaque handleData);
                                          /* Broadcast a call to a remote
					   * procedure, specifying the networks
					   * on which to broadcast */
extern void 	  Rpc_GetNetworks     (int sock, int maxNets,
				       struct sockaddr_in *networks,
				       int *numNetsPtr);
                                          /* Fetch the networks, using the 
                                           * address family of the passed 
                                           * socket, to which this machine is
                                           * physically attached */
extern void	  Rpc_Wait            (void);
                                          /* Wait for something to happen */
extern void	  Rpc_Run             (void);
                                          /* Wait forever for something to
					   * happen */
extern int	  Rpc_TcpCreate       (Boolean service, unsigned short port);
                                          /* Create a TCP socket with a name */
extern int	  Rpc_UdpCreate       (Boolean service, unsigned short port);
                                          /* Create a UDP socket with a name */
extern void	  Rpc_Debug           (Boolean debug);
                                          /* Turn on debugging printouts */
extern int	  Rpc_MessageSocket   (Rpc_Message msg);
                                          /* Return the socket for a message */
extern char	  *Rpc_ErrorMessage   (Rpc_Stat stat);
                                          /* Return a string describing an
                                           * error status */
extern void	  Rpc_Reset           (void);
                                          /* Reset the module, deleting all
					   * services, timer events and watched
					   * streams */
extern Boolean	  Rpc_IsLocal         (struct sockaddr_in *addrPtr);
                                          /* See if an internet socket address
					   * is for the local machine */
extern Boolean	  Rpc_IsLocalNet      (struct sockaddr_in *addrPtr);
                                          /* See if an internet socket address
					   * is for a network to which the
					   * machine is directly connected */
 
extern fd_set	  rpc_readMask;	    	  /* Mask of streams to check for
					   * reading */
extern fd_set	  rpc_writeMask;    	  /* Mask of streams to check for
					   * writing */
extern fd_set	  rpc_exceptMask;   	  /* Mask of streams to check for an
					   * exceptional condition */
#endif _RPC_H_
