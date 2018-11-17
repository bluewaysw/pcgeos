/*-
 * customsInt.h --
 *	Definitions internal to the customs daemon.
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
 *	"$Id: customsInt.h,v 1.2 91/06/09 16:00:01 adam Exp $ SPRITE (Berkeley)"
 */
#ifndef _CUSTOMSINT_H_
#define _CUSTOMSINT_H_

#include    "sprite.h"
#include    "customs.h"
#include    <sys/time.h>
#include    <arpa/inet.h>

typedef struct {
    struct in_addr	addr;  	    /* The address of the host */
    struct timeval	interval;   /* If the master doesn't get another
				     * avail packet after this interval,
				     * the host will be considered down */
    long 	  	avail;	    /* 0 if available. One of the AVAIL_*
				     * constants if not */
    long    	    	rating;	    /* Availability index (high => better) */
} Avail;

typedef struct {
    long 	  	avail;	    /* 0 if available. One of the AVAIL_*
				     * constants if not */
    long    	    	rating;	    /* Availability index (high => better) */
} AllocReply;

#define MAX_REG_SIZE	    1024

#define CUSTOMSINT_RETRY    2
#define CUSTOMSINT_URETRY   500000
#define CUSTOMSINT_NRETRY   3

/*
 * EXTERNAL DECLARATIONS
 */

#define Local(sinPtr) Rpc_IsLocal((sinPtr))

/*
 * customs.c:
 */
extern char 	  	    localhost[];    /* Name of this machine */
extern struct sockaddr_in   localAddr;	    /* Real internet address of
					     * udp socket (i.e. not 127.1) */
extern struct timeval	    retryTimeOut;   /* Timeout for each try */
extern Boolean	  	    amMaster;	    /* TRUE if acting as the MCA */
extern Boolean	    	    canBeMaster;    /* TRUE if we are allowed to be
					     * the MCA */
extern Boolean	  	    verbose;	    /* TRUE if should print lots of
					     * messages */
extern int  	  	    udpSocket;	    /* Socket we use for udp rpc
					     * calls and replies */
extern short	    	    udpPort;	    /* Local customs UDP service port*/
extern int  	  	    tcpSocket;	    /* Service socket for handing tcp
					     * rpc calls. */
extern short	    	    tcpPort;	    /* Local TCP service port */
extern char 	  	    *regPacket;	    /* Our registration packet */
extern int  	  	    regPacketLen;   /* The length of it */
extern int  	  	    numClients;	    /* Number of clients we support */
extern char 	  	    **clients;	    /* Names of clients we support */
extern unsigned long	    arch;   	    /* Architecture code */

/*
 * avail.c:
 */
void	    	  	    Avail_Init();   /* Initialize availability module*/
Boolean	    	  	    Avail_Send();   /* Send an availability packet to
					     * the master */
int	    	  	    Avail_Local();  /* Check local availability */
extern int  	    	    avail_Bias;	    /* Bias for availability "rating"*/
/*
 * import.c:
 */
void	    	  	    Import_Init();  /* Initialize importation */
int	    	  	    Import_NJobs(); /* Return the number of active */
					    /* imported jobs */

/*
 * mca.c:
 */
void	    	  	    MCA_Init();	    /* Set up to act as master */
void	    	  	    MCA_Cancel();   /* Cancel mastery */
void	    	  	    MCA_HostInt();  /* Process an internal Host req */

/*
 * election.c
 */
void	    	  	    Elect_Init();   	/* Initialization */
void	    	  	    Elect_GetMaster();	/* Find MCA */
Boolean	    	  	    Elect_InProgress();	/* See if an election is going
						 * on. */
extern struct sockaddr_in   masterAddr;     /* Address of master's socket */
extern long		    elect_Token;    /* Token to pass during
					     * elections */

/*
 * log.c
 */
void	    	  	    Log_Init();
void	    	  	    Log_Send();

/*
 * swap.c
 */
extern void 	  	    Swap_Timeval();  	/* struct tv */
extern void		    Swap_Avail();    	/* Avail_Data */
extern void		    Swap_AvailInt(); 	/* Avail */
extern void		    Swap_Host();       	/* Host_Data */
extern void		    Swap_ExportPermit();/* ExportPermit */
extern void		    Swap_WayBill();  	/* WayBill */
extern void		    Swap_Kill();	/* Kill_Data */
extern void		    Swap_RegPacket();	/* reg packet (free-form) */
extern void		    Swap_Info();    	/* Info packet (free-form) */
extern void 	    	    Swap_SockAddr();	/* Internet socket address */
#endif _CUSTOMSINT_H_
