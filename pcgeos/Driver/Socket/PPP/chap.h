/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  chap.h
 *
 * AUTHOR:  	  Jennifer Wu: May 11, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/11/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Challenge Handshake Authentication Protocol definitions.
 *
 *
 * 	$Id: chap.h,v 1.2 95/07/25 17:48:50 jwu Exp $
 *
 ***********************************************************************/
#ifndef _CHAP_H_
#define _CHAP_H_

/*
 * Packet header = Code (1 byte), id (1 byte), length (2 bytes).
 */
# define CHAP_HEADERLEN	    	4

# define CHAP_VALUE_SIZE    	16  	    /* used by MD5 */

#ifdef MSCHAP
# define MSCHAP_VALUE_SIZE	49	    /* MS_ChapResponse in chap_ms.h */
#endif

/*
 *	CHAP message codes.
 */
# define CHAP_CHALLENGE	1	/* Challenge */
# define CHAP_RESPONSE	2	/* Response */
# define CHAP_SUCCESS	3	/* Success */
# define CHAP_FAILURE	4	/* Failure */

typedef struct chap_state 
{
    int us_unit;    	    	/* Interface unit number */
    Handle us_myname;	    	/* Block for My Name */
    int us_mynamelen;	    	/* My Name length */
    Handle us_secret;	    	
    int us_secretlen;	    	
#ifdef LOGGING_ENABLED
    Handle us_hername;	    	/* Her Name */
    int us_hernamelen;	    	/* Her Name length */
#endif
    char us_mychallenge[CHAP_VALUE_SIZE];	/* The challenge I sent */
#ifdef MSCHAP
    char us_myresponse[MSCHAP_VALUE_SIZE];
    int us_myresponse_len;	/* number of bytes in above response */
#else
    char us_myresponse[CHAP_VALUE_SIZE]; 	/* The response I sent */
#endif
    byte us_server_state;   	/* Server (authenticator) state */
    byte us_client_state;   	/* Client state */
    byte us_flags;  	    	/* Flags */
    unsigned char us_id;    	/* Current server id */
    unsigned char us_client_id; /* ID of most recently received Challenge */
    int us_server_retransmits;	/* Number of Challenge retransmissions */
    int us_client_retransmits;	/* Number of Response retransmissions */
    int us_rechap_period;    	/* Reauthentication time in timer intervals */
    int us_timeouttime;	    	/* Timeout time in timer intervals */
    word client_timer;	     	/* CHAP timeout counter for the client */
    word server_timer;	    	/* CHAP timeout counter for the server */
    word rechap_timer;	    	/* CHAP timer for reauthentications */
#ifdef MSCHAP
    byte us_use_ms_chap;	/* use MSCHAP */
#endif
} chap_state;

/*
 * 	Server (authenticator) or Client states.
 */
# define CHAP_CLOSED	1	/* Connection down */
# define CHAP_WAITING	2	/* Waiting for Response or Ack */
# define CHAP_OPEN	3	/* Up and authenticated */

/*
 *	Flags
 */
# define CHAP_LOWERUP	    	1	/* The lower level is UP */
# define CHAP_IN_AUTH_PHASE 	2   	/* In authentication phase */


/*
 *	Timeouts.  
 */
# define CHAP_DEFTIMEOUT 6	/* 3 seconds (time in timer intervals) */


extern chap_state chap[];

extern void chap_init ();
extern void chap_authwithpeer ();
extern void chap_authpeer ();
extern void chap_lowerup ();
extern void chap_lowerdown ();
extern byte chap_input ();
extern void chap_protrej ();

extern void chap_servertimeout ();
extern void chap_clienttimeout ();

#endif /* _CHAP_H_ */
