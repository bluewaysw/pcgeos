/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  pap.h
 *
 * AUTHOR:  	  Jennifer Wu: May 11, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/11/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Password Authentication Protocol definitions.
 *
 *
 * 	$Id: pap.h,v 1.1 95/07/11 15:32:44 jwu Exp $
 *
 ***********************************************************************/
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


#ifndef _PAP_H_
#define _PAP_H_

/*
 * 	Packet header = Code (1 byte), id (1 byte), length (2 bytes).
 */
# define PAP_HEADERLEN 	    4

/*
 * 	PAP codes
 */
# define PAP_AUTH   	1   	    /* Authenticate */
# define PAP_AUTHACK	2   	    /* Authenticate Ack */
# define PAP_AUTHNAK	3   	    /* Authenticate Nak */

/*
 * Each interface is described by a pap structure.
 */
typedef struct pap_state 
{
    int us_unit;    	    	/* Interface unit number */

    Handle us_user;	    	/* Block holding user name */
    int us_userlen; 	    	/* User name length */
    Handle us_passwd;	    	/* Block holding user password */
    int us_passwdlen;	    	/* Password length */
    Handle us_peerid;	    	/* Block holding Peer-ID */
    int us_peeridlen;	    	/* Length of Peer-ID */

    byte us_clientstate;    	/* Client state */
    byte us_serverstate;    	/* Server state */
    byte us_flags;  	    	/* Flags */
    unsigned char us_id;    	/* Current id */
    int	us_retransmits;	    	/* Number of retransmissions */
    word us_timeouttime;    	/* Timeout time in timer intervals */
    word timer;	    	    	/* Pap timeout counter */
} pap_state;

/*
 *	Client states
 */
#define PAPCS_CLOSED	1	/* Connection down */
#define PAPCS_AUTHSENT	2	/* We've sent an Authenticate */
#define PAPCS_OPEN	3	/* We've received an Ack */

/*
 *	Server states
 */
# define PAPSS_CLOSED	1	/* Connection down */
# define PAPSS_LISTEN	2	/* Listening for an Authenticate */
# define PAPSS_OPEN	3	/* We've sent an Ack */


/*
 *	Flags
 */
# define PAPF_LOWERUP	1	/* The lower level is UP */
# define PAPF_AWPPENDING 2	/* Auth with peer pending */
# define PAPF_APPENDING	4	/* Auth peer pending */

/*
 * Timeouts.  Timeout time in timer intervals.
 */
#define PAP_DEFTIMEOUT	6	/* 3 seconds */


extern pap_state pap[];

extern void pap_init ();
extern void pap_authwithpeer ();
extern void pap_authpeer ();
extern void pap_lowerup ();
extern void pap_lowerdown ();
extern byte pap_input ();
extern void pap_protrej ();
extern void pap_timeout ();

#endif /* _PAP_H_ */


