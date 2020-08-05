/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  lcp.h
 *
 * AUTHOR:  	  Jennifer Wu: May  4, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 4/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Link Control Protocol definitions.
 *
 * 	$Id: lcp.h,v 1.3 98/09/25 10:44:33 kho Exp $
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

#ifndef _LCP_H_
#define _LCP_H_

/*
 *	Configuration Options
 */
# define CI_MRU			1	/* Maximum Receive Unit */
# define CI_ASYNCMAP		2	/* Async Control Character Map */
# define CI_AUTHTYPE		3	/* Authentication Type */
# define CI_LQM			4	/* Link Quality Monitoring */
# define CI_MAGICNUMBER		5	/* Magic Number */
# define CI_PCOMPRESSION	7	/* Protocol Field Compression */
# define CI_ACCOMPRESSION	8	/* Address/Control Field Compression */

# define LCP_MAXCI		8	/* Highest numbered option */


/*
 * Negotiation flag values.
 */
# define CI_N_MRU   	    	0X0001
# define CI_N_ASYNCMAP	    	0X0002
# define CI_N_AUTHTYPE	    	0X0004
# define CI_N_PAP   	    	0x0008
# define CI_N_CHAP  	    	0x0010
# define CI_N_LQM   	    	0x0020
# define CI_N_MAGICNUMBER   	0x0040
# define CI_N_PCOMPRESSION 	0x0080
# define CI_N_ACCOMPRESSION 	0x0100
#ifdef MSCHAP
# define CI_N_MSCHAP		0x0200	/* requires CI_N_CHAP so we
					   don't have to clear this
					   everywhere CI_N_CHAP is
					   cleared */
#endif

/*
 * LCP flags -- is a union of boolean variables used by MST to keep
 * 	    	information about the status or behaviour of LCP.
 */
# define LF_ECHO_LQM	       	0x01	/* Use Echo-Request instead of LQR */
# define LF_LOST_LINE	    	0x02	/* line dropped or LQM said it did */
# define LF_IN_NETWORK_PHASE	0x04	/* True if we are */

/*
 * The state of options is described by an lcp_options structure
 */
typedef struct lcp_options
{
    WordFlags lcp_neg; 	       	/* flag of options to be negotiated */
    ByteFlags lcp_flags;    	/* flag indicating status/behaviour */

    unsigned short mru;	    	/* Value of MRU */
    unsigned long asyncmap;
    unsigned short auth_prot;	/* Authentication protocol */
    unsigned long magicnumber;
    unsigned long lqrinterval;	/* Hundredths of a second between sent LQRs */
    unsigned short lqm_k;	/* Must receive k of the last n LQRs */
    unsigned short lqm_n;	/* to consider the link OK */
    int rxnaks[LCP_MAXCI + 1];	/* No. of Configure-Naks peer sent */
} lcp_options;

extern fsm lcp_fsm[];
extern lcp_options lcp_wantoptions[];
extern lcp_options lcp_gotoptions[];
extern lcp_options lcp_allowoptions[];
extern lcp_options lcp_heroptions[];

/*
 * Some defaults and maximums.
 */

# define DEFMRU	    	    576    	/* Try for this */
# define MINMRU	    	    128	    	/* No MRUs below this */
# define MAXMRU	    	    MAX_MTU 	/* No MRUs above this */

#ifdef LOGGING_ENABLED
# define LCP_DEFWARNNAKS    8	    	/* Print a warning every 8 Naks */
#endif /* LOGGING_ENABLED */

extern void lcp_init ();
extern void lcp_open ();
extern void lcp_close ();
extern void lcp_lowerup ();
extern void lcp_lowerdown ();
extern byte lcp_input ();
extern void lcp_protrej ();

#endif /* _LCP_H_ */
