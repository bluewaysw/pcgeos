/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  lqm.h
 *
 * AUTHOR:  	  Jennifer Wu: May 10, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/10/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Link Quality Monitoring definitions.
 *
 *
 * 	$Id: lqm.h,v 1.1 95/07/11 15:32:35 jwu Exp $
 *
 ***********************************************************************/
#ifndef _LQM_H_
#define _LQM_H_

/*
 * The packet format is magicnumber through PeerOutOctets.
 */
# define LQR_BODY_SIZE	    48

struct lqr 
{
    unsigned long magicnumber;
    unsigned long LastOutLQRs;
    unsigned long LastOutPackets;
    unsigned long LastOutOctets;
    unsigned long PeerInLQRs;
    unsigned long PeerInPackets;
    unsigned long PeerInDiscards;
    unsigned long PeerInErrors;
    unsigned long PeerInOctets;
    unsigned long PeerOutLQRs;
    unsigned long PeerOutPackets;
    unsigned long PeerOutOctets;
    unsigned long SaveInLQRs;
    unsigned long SaveInPackets;
    unsigned long SaveInDiscards;
    unsigned long SaveInErrors;
    unsigned long SaveInOctets;
};

/*
 *	Values in lq -> running
 */
# define LQ_LQR			1
# define LQ_ECHO		2


/*
 *	Values in lq -> lqr_history[]
 */
# define LQR_LOST		1
# define LQR_FOUND		2

/*
 * Default LQM reporting interval. (in hundredths of seconds)
 */
# define DEFAULT_LQR_INTERVAL  	1000L	    	/* 10.00 seconds */

typedef struct lqm
{
    int unit;
    unsigned char running;
    int k;
    int n;
    unsigned char received_lqrs;	/* 1 if we have ever gotten an LQR */
    unsigned char timed_out;	    
    unsigned short timer;   	    	/* Timer for sending LQRs */
    unsigned long interval;	    	/* in 100ths of a second */
    unsigned long magicnumber;
    unsigned long OutLQRs;
    unsigned long InLQRs;
    unsigned long InGoodOctets;
    unsigned long ifOutUniPackets;
    unsigned long ifOutNUniPackets;
    unsigned long ifOutOctets;
    unsigned long ifOutDiscards;
    unsigned long ifInUniPackets;
    unsigned long ifInNUniPackets;
    unsigned long ifInDiscards;
    unsigned long ifInErrors;
    struct lqr lastlqr;

    unsigned char history_index;
    char lqr_history[256];
} lqm_t;

extern lqm_t lqm[];
extern byte lqm_input ();
extern void lqm_protrej ();
extern void lqm_send_lqr ();
extern void lqm_send_echo ();

#endif /* _LQM_H_ */
