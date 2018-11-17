/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  fsm.h
 *
 * AUTHOR:  	  Jennifer Wu: May  3, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 3/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	{Link, IP} Control Protocol Finite State Machine definitions.
 *
 * 	$Id: fsm.h,v 1.7 97/01/24 18:58:35 jwu Exp $
 *
 ***********************************************************************/
#ifndef _FSM_H_
#define _FSM_H_

/*
 *
 * Copyright (c) 1989 Carnegie Mellon University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by Carnegie Mellon University.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * Packet header = Code, id, length.  
 * Code = 1 byte, id = 1 byte, length = 2 bytes.
 */
#define     HEADERLEN	    4


/*
 *	Message codes
 */
# define	CONFIGURE_REQUEST	1
# define	CONFIGURE_ACK		2
# define	CONFIGURE_NAK		3
# define	CONFIGURE_REJECT	4
# define	TERMINATE_REQUEST	5
# define	TERMINATE_ACK		6
# define	CODE_REJECT		7
# define	PROTOCOL_REJECT		8
# define	ECHO_REQUEST		9
# define	ECHO_REPLY		10
# define	DISCARD_REQUEST		11

/* 12 was Link-Quality-Report in an early draft */

# define	RESET_REQUEST		14	/* For CCP */
# define	RESET_ACK		15	/* For CCP */

/*
 *	Finite State Machine states
 */
# define	INITIAL			0
# define	STARTING		1
# define	CLOSED			2
# define	STOPPED			3
# define	CLOSING			4
# define	STOPPING		5
# define	REQ_SENT		6
# define	ACK_RCVD		7
# define	ACK_SENT		8
# define	OPENED			9

# define    	NUM_STATES  	    	10


/* 
 * Each FSM is described by a fsm_callbacks and a fsm structure.
 *
 * If the protocol does not support a certain operation, use 
 * (VoidCallback *)NULL.  
 *
 * Only closed, protrej, retransmit, echorequest, echoreply and lqreport 
 * may be unsupported to reduce number of checks before calling the callback.
 * If others are allowed to be unsupported, see MST source code for changes 
 * to make in fsm.goc.  (6/6/95 -- jwu)
 * 	
 * Code using fsm_callback structure has to store vfptrs unless the 
 * callback is in a fixed resource.
 *
 */

typedef void _near NearCallback();
typedef void VoidCallback();
typedef int IntCallback();
typedef unsigned char ByteCallback();

typedef struct fsm_callbacks
{
    VoidCallback *resetci;  	/* Reset our Configuration Information */
    IntCallback *cilen;		/* Length of our Configuration Information */
    VoidCallback *addci;		/* Add our Configuration Information */
    IntCallback *ackci;		/* Receive ACK for our Configuration Info */
    VoidCallback *nakci;	/* Receive NAK for our Configuration Info */
    VoidCallback *rejci;	/* Recv Reject for our Configuration Info */
    ByteCallback *reqci;	/* Recv Configure-Request from peer */
    VoidCallback *up;		/* Called when fsm reaches OPEN state */
    VoidCallback *down;		/* Called when fsm leaves OPEN state */
    VoidCallback *closed;	/* Called when fsm reaches CLOSED state */
    VoidCallback *protreject;	/* Called when Protocol-Reject received */
    VoidCallback *retransmit;	/* Retransmission is necessary */
    ByteCallback *echorequest;	/* Called when Echo-Request received */
    VoidCallback *echoreply;	/* Called when Echo-Reply received */
    VoidCallback *lqreport;	/* Called when Link-Quality-Report received */
#ifdef USE_CCP
    VoidCallback *resetrequest;	/* Called when Reset-Request received */
    VoidCallback *resetack;	/* Called when Reset-Ack received */
#endif

} fsm_callbacks;

typedef struct fsm
{
    int unit;	    	    	/* Interface unit number */
    unsigned short protocol; 	/* Data Link Layer Protocol field value */
    int state;	    	    	/* State */
#ifdef LOGGING_ENABLED
    int old_state;		/* Previous value of state */
#endif /* LOGGING_ENABLED */
    byte flags;			/* Flags */
    unsigned char id;		/* Current id */
    unsigned char reqid;	/* Current request id */
    int timeouttime;		/* Timeout time in timer intervals*/
    int retransmits;		/* Number of retransmissions */
    int max_terminate;		/* Maximum Terminate-Request transmissions */
    int max_configure;		/* Maximum Configure-Request transmissions */
    int max_failure;		/* Maximum number of sent Naks before we Rej */
    int max_rx_failure;		/* Maximum num. of rx'ed Naks before hangup */
    int tx_naks;		/* Number of Naks sent since last Ack */
    int rx_naks;		/* Number of Naks received since last Ack */
    unsigned long code_mask;	/* Bit mask of valid message codes */
    fsm_callbacks *callbacks;	/* Callback routines */    
    word timer;	        	/* Decay counter for timer */
    byte backoff;   	    	/* counter for backoff timer, 0 means off */
    byte new_id;   	    	/* use a new ID for next configure-request */
} fsm;

/*
 *	Flags
 */
# define LOWERUP	1	/* The lower level is UP */

/*
 *	Timeouts (time specified in timer intervals)
 */
# define ONE_SECOND 	    60	/* 60 tickes per second */
# define INTERVALS_PER_SEC  2  	/* timer interval is a half second */
# define DEFTIMEOUT 	    6  	/* 3 seconds */
# define RATE_TIMEOUT	    10 	/* Measure bps every 5 seconds  */

# define MAX_CONFIGURE	10	/* Maximum Configure-Request transmissions */
# define MAX_TERMINATE	2	/* Maximum Terminate-Request transmissions */
# define MAX_FAILURE	5	/* Maximum Configure-Naks sent in a row */
# define MAX_RX_FAILURE	20	/* Maximum Configure-Nak receptions */

#ifdef DELAYED_BACKOFF_TIMER
# define MIN_RX_BEFORE_BACKOFF 2 /* Minimum retransmit attempts before */
                                 /*  backing off retransmit timer.  */
                                 /*  Counter is 0 based. */
#endif

extern void fsm_init ();
extern void fsm_open ();
extern void fsm_close ();
extern void fsm_lowerup ();
extern void fsm_lowerdown ();
extern byte fsm_input ();
extern void fsm_sdata (); 
extern void fsm_timeout ();

extern void fsm_start_timer();
extern void fsm_stop_timer();


#endif /* _FSM_H_ */

