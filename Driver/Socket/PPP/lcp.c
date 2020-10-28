/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  lcp.c
 *
 * AUTHOR:  	  Jennifer Wu: May  4, 1995
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	lcp_init
 *	lcp_open
 *	lcp_close
 *	lcp_lowerup
 *	lcp_lowerdown
 *	lcp_client_timeout
 *
 *	lcp_input   	    Process a received LCP packet
 *	lcp_protrej 	    Process a received Protocol-Reject
 *	lcp_sprotrej	    Send a Protocol-Reject for some protocol
 *
 *	lcp_resetci 	    Reset our configuration information
 *	lcp_cilen   	    Return the size of our configuration information
 *	lcp_addci   	    Add our configuration info to the packet
 *
 *	lcp_ackci   	    Process a received Configure-Ack
 *	lcp_nakci   	    Process a received Configure-Nak
 *	lcp_rejci   	    Process a received Configure-Reject
 *	lcp_reqci   	    Process a received Configure-Request
 *
 *	lcp_up	    	    LCP has come UP
 *	lcp_down    	    LCP has gone DOWN
 *	lcp_closed  	    LCP has CLOSED
 *
 *	lqm_protrej 	    Process a received Protocol-Reject for LQM
 *	lqm_lowerup
 *	lqm_lowerdown
 *	lqm_start
 *	lqm_set_lqr_status  Update status and check if link is bad
 *	lqm_threshold
 *	lcp_echorequest	    Process received LCP echo request
 *	lqm_failure 	    PPP link should be shutdown
 *	lqm_send_lqr	    Send an LQR
 *	lcp_echo_reply	    Process received LCP echo reply
 *	lqm_input   	    Process a received LQR packet
 *	lqm_send_echo	    Send an LCP echo request.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 4/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP Link Control Protocol and Link Quality Monitoring.
 *
 * 	$Id: lcp.c,v 1.17 98/07/01 13:28:59 jwu Exp $
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

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

#include <ppp.h>

/*
 * Forward declarations.
 */
void lcp_resetci(); 	    	/* Reset our Configuration Information */
int lcp_cilen();    	    	/* Return length of our CI */
void lcp_addci();   	    	/* Add our CIs */
int lcp_ackci();		/* Ack some CIs */
void lcp_nakci();		/* Nak some CIs */
void lcp_rejci();		/* Reject some CIs */
unsigned char lcp_reqci();	/* Check the requested CIs */
void lcp_up();			/* We're UP */
void lcp_down();		/* We're DOWN */
void lcp_closed();		/* We're CLOSED */

void lqm_lowerup();
void lqm_lowerdown();
void lqm_start(int unit, unsigned long lqrinterval, unsigned char echolqm,
	       int k, int n);

unsigned char lcp_echorequest();
void lcp_echoreply();

/*
 * Variables for generating far pointers to the callback routines.
 */
static VoidCallback *lcp_resetci_vfptr = lcp_resetci;
static IntCallback *lcp_cilen_vfptr = lcp_cilen;
static VoidCallback *lcp_addci_vfptr = lcp_addci;
static IntCallback *lcp_ackci_vfptr = lcp_ackci;
static VoidCallback *lcp_nakci_vfptr = lcp_nakci;
static VoidCallback *lcp_rejci_vfptr = lcp_rejci;
static ByteCallback *lcp_reqci_vfptr = lcp_reqci;
static VoidCallback *lcp_up_vfptr = lcp_up;
static VoidCallback *lcp_down_vfptr = lcp_down;
static VoidCallback *lcp_closed_vfptr = lcp_closed;
static ByteCallback *lcp_echorequest_vfptr = lcp_echorequest;
static VoidCallback *lcp_echoreply_vfptr = lcp_echoreply;

fsm_callbacks lcp_callbacks;

#ifdef __HIGHC__
#pragma Code("LCPINIT");
#endif
#ifdef __BORLANDC__
#pragma codeseg LCPINIT
#endif
#ifdef __WATCOMC__
#pragma code_seg("LCPINIT")
#endif


/***********************************************************************
 *				lcp_init
 ***********************************************************************
 * SYNOPSIS:	Initialize LCP.
 * CALLED BY:	PPPSetup using prottbl entry
 * RETURN:	nothing
 *
 * NOTES:   	Commented out lines initializing defaults to zero
 *	    	because they are already zero (dgroup).  The lines
 *	    	now server as comments.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_init (int unit)
{
    fsm *f = &lcp_fsm[unit];
    lcp_options *wo = &lcp_wantoptions[unit];
    lcp_options *ao = &lcp_allowoptions[unit];

    /*
     * Fill callback structure.
     */
    lcp_callbacks.resetci = lcp_resetci_vfptr;
    lcp_callbacks.cilen = lcp_cilen_vfptr;
    lcp_callbacks.addci = lcp_addci_vfptr;
    lcp_callbacks.ackci = lcp_ackci_vfptr;
    lcp_callbacks.nakci = lcp_nakci_vfptr;
    lcp_callbacks.rejci = lcp_rejci_vfptr;
    lcp_callbacks.reqci = lcp_reqci_vfptr;
    lcp_callbacks.up = lcp_up_vfptr;
    lcp_callbacks.down = lcp_down_vfptr;
    lcp_callbacks.closed = lcp_closed_vfptr;
    lcp_callbacks.echorequest = lcp_echorequest_vfptr;
    lcp_callbacks.echoreply = lcp_echoreply_vfptr;
    lcp_callbacks.protreject = lcp_callbacks.retransmit =
	lcp_callbacks.lqreport = (VoidCallback *)NULL;
#ifdef USE_CCP
    lcp_callbacks.resetrequest = lcp_callbacks.resetack = (VoidCallback *)NULL;
#endif
    /*
     * Initialize the FSM values.
     */
    f -> unit = unit;
    f -> protocol = LCP;
    f -> timeouttime = DEFTIMEOUT;
    f -> max_configure = MAX_CONFIGURE;
    f -> max_terminate = MAX_TERMINATE;
    f -> max_failure = MAX_FAILURE;
    f -> max_rx_failure = MAX_RX_FAILURE;
/*  f -> tx_naks = 0;	    	*/
/*  f -> rx_naks = 0;	    	*/
    f -> code_mask = 0xffe; 	/* CONFIGURE-REQUEST thru DISCARD-REQUEST */

    f -> callbacks = &lcp_callbacks;

    /*
     * Initialize want options.  Default is to escape ^Q and ^S for
     * xon/xoff.
     */

    wo -> lcp_neg = ( CI_N_MRU | CI_N_ASYNCMAP | CI_N_MAGICNUMBER |
		     CI_N_LQM | CI_N_PCOMPRESSION | CI_N_ACCOMPRESSION);

    wo -> mru = DEFMRU;
    wo -> asyncmap = (1L << C_CTRL_S) | (1L << C_CTRL_Q);

    wo -> lcp_flags = LF_ECHO_LQM;
    wo -> lqm_k = 1;
    wo -> lqm_n = 5;
    wo -> lqrinterval = DEFAULT_LQR_INTERVAL;

    /*
     * Initialize allow options -- allow everything.
     */
      ao -> lcp_neg = (CI_N_MRU | CI_N_ASYNCMAP | CI_N_PAP | CI_N_CHAP |
                    CI_N_AUTHTYPE | CI_N_MAGICNUMBER | CI_N_LQM |
                    CI_N_PCOMPRESSION | CI_N_ACCOMPRESSION);

    /*
     * Initialize rest of FSM and then set percentages to perfect.
     */
    fsm_init(f);
    DOLOG(rx_percent = tx_percent = 100;)
}


/***********************************************************************
 *				lcp_open
 ***********************************************************************
 * SYNOPSIS:	Open LCP.
 * CALLED BY:	PPPOpenLink
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_open (int unit)
{
    fsm_open(&lcp_fsm[unit]);
}


/***********************************************************************
 *				lcp_close
 ***********************************************************************
 * SYNOPSIS:	Close LCP.
 * CALLED BY:	chap_servertimeout
 *	    	chap_clienttimeout
 *	    	chap_rresponse
 *	    	chap_rfailure
 *	    	ipcp_nakci
 *	    	lcp_nakci
 *	    	lcp_up
 *	    	lqm_failure
 *	    	pap_timeout
 *	    	pap_rauth
 *	    	pap_rauthnak
 *	    	PPPHandleTimeout
 *	    	PPPCloseLink
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_close (int unit)
{
    fsm_close(&lcp_fsm[unit]);
}


/***********************************************************************
 *				lcp_lowerup
 ***********************************************************************
 * SYNOPSIS:	The lower layer is up.  Lower layer is physical layer.
 * CALLED BY:	PPPOpenLink
 *	    	PPPProcessInput
 * RETURN:	nothing
 *
 * STRATEGY:	Reset some global variables used by code that
 *	    	reads/writes data from the serial line.  Let FSM
 * 	    	take care of the rest.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_lowerup (int unit)
{

    DOLOG(lcp_loopback_warned = 0;)

    /*
     * Reset escape and discard maps to the defaults (escape everything),
     * reset compressions to none and then let FSM take care of the rest.
     */
    SetEscapeMap(unit, 0xffffffff, 0xffffffff);
    SetProtoCompression(unit, 0, 0);
    SetACCompression(unit, 0, 0);
    fsm_lowerup(&lcp_fsm[unit]);
}


/***********************************************************************
 *				lcp_lowerdown
 ***********************************************************************
 * SYNOPSIS:	The lower layer is down.
 * CALLED BY:	lcp_client_timeout
 *	    	lcp_closed
 *	        PPPCallTerminated
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_lowerdown (int unit)
{
    /*
     * Remember line is lost.
     */
    lcp_wantoptions[unit].lcp_flags |= LF_LOST_LINE;
    fsm_lowerdown(&lcp_fsm[unit]);
}


/***********************************************************************
 *				lcp_client_timeout
 ***********************************************************************
 * SYNOPSIS:	Process client timer expiring when attemting to open
 *	    	PPP connection.
 * CALLED BY:	PPPTimeout
 * RETURN:	nothing
 *
 * STRATEGY:   	Set link_error to SDE_CONNECTION_TIMEOUT
 *	    	call lcp_lowerdown
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	6/ 8/95		Initial Revision
 *
 ***********************************************************************/
void lcp_client_timeout ()
{
    LOG3(LOG_NEG, (LOG_CLIENT_TIMER));
    link_error = SDE_CONNECTION_TIMEOUT;
    lcp_lowerdown(0);
}


/***********************************************************************
 *				lcp_protrej
 ***********************************************************************
 * SYNOPSIS:	Process receiving a Protocol-Reject.
 * CALLED BY:	demuxprotrej using prottbl entry
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_protrej (int unit)
{
    /*
     * Can't reject LCP!
     */
    LOG3(LOG_NEG, (LOG_LCP_REJ));
}



/***********************************************************************
 *				lcp_sprotrej
 ***********************************************************************
 * SYNOPSIS:	Send a Protocol-Reject for some protocol.
 * CALLED BY:	lqm_input
 *	        PPPInput
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_sprotrej (int unit,
		   PACKET *p,
		   int len)
{

    /*
     * Back up the data pointer by 2 bytes to include the received
     * protocol in the data, so all fsm_sdata has to do is prepend
     * the PPP header.
     */
    p -> MH_dataOffset -= 2;
    len += 2;

    /*
     * Check to see if rejected packet needs to be truncated so as
     * not to exceed peer's established MRU.
     */
    if (len > lcp_heroptions[unit].mru - HEADERLEN) {
	len = lcp_heroptions[unit].mru - HEADERLEN;
	LOG3(LOG_NEG, (LOG_LCP_TRUNC_REJ));
    }

    p -> MH_dataSize = len;

    fsm_sdata(&lcp_fsm[unit], PROTOCOL_REJECT, ++lcp_fsm[unit].id,
	      PACKET_DATA(p), p, len);
}


/***********************************************************************
 *				lcp_resetci
 ***********************************************************************
 * SYNOPSIS:	Reset our configuration information. (FSM callback routine)
 * CALLED BY:	fsm_open
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_resetci (fsm *f)
{
    int i;
    lcp_wantoptions[f -> unit].magicnumber = NetGenerateRandom32();

    for (i = 0; i <= LCP_MAXCI; i++)
	lcp_wantoptions[f -> unit].rxnaks[i] = 0;

    lcp_wantoptions[f -> unit].lcp_flags &= ~LF_LOST_LINE;
    lcp_gotoptions[f -> unit] = lcp_wantoptions[f -> unit];
}



/***********************************************************************
 *				lcp_cilen
 ***********************************************************************
 * SYNOPSIS:	Return the size of our configuration information.
 *	    	(FSM callback routine)
 * CALLED BY:	scr 	= Send Configure Request
 * RETURN:	length of our configuration information
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
int lcp_cilen (fsm *f)
{
    lcp_options *go = &lcp_gotoptions[f -> unit];

#define LENCIVOID(neg) ((neg) ? 2 : 0)
#define LENCISHORT(neg) ((neg) ? 4 : 0)
#define LENCILONG(neg) ((neg) ? 6 : 0)

    return (LENCISHORT(go -> lcp_neg & CI_N_MRU) +
	    LENCILONG(go -> lcp_neg & CI_N_ASYNCMAP) +
	    ((go -> lcp_neg & CI_N_AUTHTYPE) ?
	    	(go -> auth_prot == PAP ? 4 : 5) : 0) +
	    LENCILONG(go -> lcp_neg & CI_N_MAGICNUMBER) +
	    ((go -> lcp_neg & CI_N_LQM) ? 8 : 0) +
	    LENCIVOID(go -> lcp_neg & CI_N_PCOMPRESSION) +
	    LENCIVOID(go -> lcp_neg & CI_N_ACCOMPRESSION));

}


/***********************************************************************
 *				lcp_addci
 ***********************************************************************
 * SYNOPSIS:	Add our desired configuration information to the packet.
 *	    	(FSM callback routine)
 * CALLED BY:	scr 	= Send Configure Request
 * RETURN:	nothing
 *
 * STRATEGY:	Add options we want to negotiate into the buffer pointed
 *	    	to by ucp.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_addci (fsm *f,
		unsigned char *ucp)
{
    lcp_options *go = &lcp_gotoptions[f -> unit];
    DOLOG(char map[SHORT_STR_LEN];)

#define ADDCIVOID(opt, neg, code) \
    if (neg) { \
	PUTCHAR(opt, ucp); \
	PUTCHAR(2, ucp); \
	code \
    }
#define ADDCISHORT(opt, neg, val, code) \
    if (neg) { \
	PUTCHAR(opt, ucp); \
	PUTCHAR(2 + sizeof (short), ucp); \
	PUTSHORT(val, ucp); \
	code \
    }
#define ADDCILONG(opt, neg, val, code) \
    if (neg) { \
	PUTCHAR(opt, ucp); \
	PUTCHAR(2 + sizeof (long), ucp); \
	PUTLONG(val, ucp); \
        code \
    }

    /*
     * The code in the following will leave a ";" when LOGGING_ENABLED
     * is not defined, allowing the above macros to work.
     */
    ADDCISHORT(CI_MRU, go -> lcp_neg & CI_N_MRU, go -> mru,
	       LOG3(LOG_NEG, (LOG_LCP_SEND_MRU, go -> mru));
	       )

    ADDCILONG(CI_ASYNCMAP, go -> lcp_neg & CI_N_ASYNCMAP, go -> asyncmap,
	      LOG3(LOG_NEG, (LOG_LCP_SEND_AMAP,
			    go -> asyncmap));
	      DOLOG(asyncmap_name(map, go -> asyncmap);)
	      DOLOG(if (map[0] != '\0'))
	      	  LOG3(LOG_NEG, (LOG_FORMAT_STRING, map));
	      LOG3(LOG_NEG, (LOG_NEWLINE));
	      )

    if (go -> lcp_neg & CI_N_AUTHTYPE)
	if (go -> auth_prot == PAP) {
	    /* Watch out!  ADDCISHORT() needs {} around it. Already checked */
	    /* that this option is negotiated so pass 1 to save some work. */
	    ADDCISHORT(CI_AUTHTYPE, 1, PAP,
		       LOG3(LOG_NEG, (LOG_LCP_SEND_AUTH, "PAP"));
		      )
	}
    	else {      	   	    /* else CHAP */
	    PUTCHAR(CI_AUTHTYPE, ucp);
	    PUTCHAR(5, ucp);	    	    /* CHAP length */
	    PUTSHORT(CHAP, ucp);
	    PUTCHAR(5, ucp);	    	    /* Use MD5 algorithm */
	    LOG3(LOG_NEG, (LOG_LCP_SEND_AUTH, "CHAP, MD5"));
	}

    ADDCILONG(CI_MAGICNUMBER, go -> lcp_neg & CI_N_MAGICNUMBER,
	      go -> magicnumber,
	      LOG3(LOG_NEG, (LOG_LCP_SEND_MAGIC,
			    go -> magicnumber));
	      )

    if (go -> lcp_neg & CI_N_LQM) {
	PUTCHAR(CI_LQM, ucp);
	PUTCHAR(8, ucp);    	    	/* LQM length */
	PUTSHORT(LQM, ucp);
	PUTLONG(go -> lqrinterval, ucp);
	LOG3(LOG_NEG, (LOG_LCP_SEND_LQM));

#ifdef LOGGING_ENABLED
	if (go -> lqrinterval) {
	    LOG3(LOG_NEG, (LOG_REPORT_PERIOD,
			  go -> lqrinterval / 100L, go -> lqrinterval % 100L));
	    LOG3(LOG_NEG, (LOG_NEWLINE));
	}
	else {
	    LOG3(LOG_NEG, (LOG_RESPONSE_ONLY));
	    LOG3(LOG_NEG, (LOG_NEWLINE));
	}
#endif /* LOGGING_ENABLED */
    }

    ADDCIVOID(CI_PCOMPRESSION, go -> lcp_neg & CI_N_PCOMPRESSION,
	      LOG3(LOG_NEG, (LOG_LCP_SEND_PCOMP));
	      )

    ADDCIVOID(CI_ACCOMPRESSION, go -> lcp_neg & CI_N_ACCOMPRESSION,
	      LOG3(LOG_NEG, (LOG_LCP_SEND_ACOMP));
	      )
}


/***********************************************************************
 *				lcp_ackci
 ***********************************************************************
 * SYNOPSIS:	Process an ACK for our configuration information.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	0 if Ack was bad.
 *	    	1 if Ack was good.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
int lcp_ackci (fsm *f,
	       unsigned char *p,
	       int len)
{
    lcp_options *go = &lcp_gotoptions[f -> unit];
    unsigned char cilen, citype, cichar;
    unsigned short cishort;
    unsigned long cilong;

    /*
     * CIs must be in exactly the same order that we sent.
     * Check packet length and CI length at each step.
     * If we find any deviations, then this packet is bad.
     */
#define ACKCIVOID(opt, neg) \
    if (neg) { \
	if ((len -= 2) < 0) \
	    goto bad; \
	GETCHAR(citype, p); \
	GETCHAR(cilen, p); \
	if (cilen != 2 || \
	    citype != opt) \
	    goto bad; \
    }
#define ACKCISHORT(opt, neg, val) \
    if (neg) { \
	if ((len -= 2 + sizeof (short)) < 0) \
	    goto bad; \
	GETCHAR(citype, p); \
	GETCHAR(cilen, p); \
	if (cilen != 2 + sizeof (short) || \
	    citype != opt) \
	    goto bad; \
	GETSHORT(cishort, p); \
	if (cishort != val) \
	    goto bad; \
    }
#define ACKCILONG(opt, neg, val) \
    if (neg) { \
	if ((len -= 2 + sizeof (long)) < 0) \
	    goto bad; \
	GETCHAR(citype, p); \
	GETCHAR(cilen, p); \
	if (cilen != 2 + sizeof (long) || \
	    citype != opt) \
	    goto bad; \
	GETLONG(cilong, p); \
	if (cilong != val) \
	    goto bad; \
    }

    ACKCISHORT(CI_MRU, go -> lcp_neg & CI_N_MRU, go -> mru)

    ACKCILONG(CI_ASYNCMAP, go -> lcp_neg & CI_N_ASYNCMAP, go -> asyncmap)

    if (go -> lcp_neg & CI_N_AUTHTYPE) {
	if (go -> auth_prot == PAP) {
	    /*
	     * We already checked that authentication is negotiated so
	     * pass a 1 to save some work.
	     */
	    ACKCISHORT(CI_AUTHTYPE, 1, PAP)
	}
    	else {
	    if ((len -= 5) < 0)	   /* make sure packet length is long enough */
		goto bad;

	    GETCHAR(citype, p);
	    GETCHAR(cilen, p);

	    if (cilen != 5) 	   /* check transmitted length */
		goto bad;

	    GETSHORT(cishort, p);   /* check auth protocol */
	    if (cishort != CHAP)
		goto bad;

	    GETCHAR(cichar, p);

	    if (cichar != 5)	   /* only do MD5 */
		goto bad;
	}
    }

    ACKCILONG(CI_MAGICNUMBER, go -> lcp_neg & CI_N_MAGICNUMBER,
	      go -> magicnumber)

    if (go -> lcp_neg & CI_N_LQM) {
	if ((len -= 8) < 0) 	    /* check packet length */
	    goto bad;

	GETCHAR(citype, p);
	GETCHAR(cilen, p);

	if (cilen != 8 ||   	    /* check transmitted length */
	    citype != CI_LQM)	    /* check option type */
	    goto bad;

	GETSHORT(cishort, p);

	if (cishort != LQM) 	    /* check quality protocol is LQM */
	    goto bad;

	GETLONG(cilong, p);

	if (cilong != go -> lqrinterval)   /* check reporting interval */
	    goto bad;
    }

    ACKCIVOID(CI_PCOMPRESSION, go -> lcp_neg & CI_N_PCOMPRESSION)
    ACKCIVOID(CI_ACCOMPRESSION, go -> lcp_neg & CI_N_ACCOMPRESSION)

    /*
     * If there are any remaining CIs, then this packet is bad.
     */
    if (len != 0)
	goto bad;

    return(1);

bad:
    LOG3(LOG_NEG, (LOG_LCP_BAD, "Ack"));
    return(0);

}



/***********************************************************************
 *				lcp_nakci
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Nak message.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_nakci (fsm *f,
		unsigned char *p,
		int len)
{
    lcp_options *go = &lcp_gotoptions[f -> unit];
    lcp_options *wo = &lcp_wantoptions[f -> unit];
    lcp_options *ao = &lcp_allowoptions[f -> unit];
    unsigned short cishort;
    unsigned long cilong;

    /*
     * If received too many naks, give up.
     * Set generic error to reset.  Will be changed to link_open_failed
     * by api code if connection hasn't been established yet.
     */
    if (f -> rx_naks > f -> max_rx_failure) {
	link_error = SSDE_NEG_FAILED | SDE_CONNECTION_RESET;
	LOG3(LOG_BASE, (LOG_LCP_GIVE_UP));
	lcp_close(0);
    }

    while (len > 0) {
	unsigned char *p1 = p + 2;  	/* p1 points to option protocol */
	int l = p[1];	    	    	/* get transmitted option length */

	/*
	 * Make sure transmitted length is less than remaining length and
	 * that the length is reasonable.
	 */
	if (l > len || l < 2)
	    goto bad;

	switch (p[0])	    	    	/* by packet type */
	    {
	    case CI_MRU:
		if (l == 4 && (ao -> lcp_neg & CI_N_MRU)) {
		    GETSHORT(cishort, p1);

		    LOG3(LOG_NEG, (LOG_LCP_MRU_NAK, cishort));

/*		    if (cishort <= wo -> mru) {*/
		    if ((cishort <= MAXMRU) && (cishort >= MINMRU)) {
			go -> lcp_neg |= CI_N_MRU;
			go -> mru = cishort;
		    }

		    ++go -> rxnaks[CI_MRU];
#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_MRU] % lcp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_LCP_NO_MRU,
				       wo -> mru, cishort));
			negotiation_problem = "Negotiation failed";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_LCP_MRU_NAK_SIMPLE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_ASYNCMAP:
		if (l == 6 && (ao -> lcp_neg & CI_N_ASYNCMAP)) {
		    GETLONG(cilong, p1);

	    	    LOG3(LOG_NEG, (LOG_LCP_AMAP_NAK, cilong));

		    go -> lcp_neg |= CI_N_ASYNCMAP;
		    go -> asyncmap |= cilong;

		    ++go -> rxnaks[CI_ASYNCMAP];
#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_ASYNCMAP] % lcp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_LCP_NO_AMAP));
			negotiation_problem = "Negotiation failed";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_LCP_AMAP_NAK_SIMPLE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_AUTHTYPE:
		if (ao -> lcp_neg & CI_N_AUTHTYPE && l >= 4) {
		    GETSHORT(cishort, p1);

		    if (cishort == PAP && wo -> lcp_neg & CI_N_PAP) {
			LOG3(LOG_NEG, (LOG_LCP_AUTH_NAK, "PAP"));
			go -> lcp_neg |= (CI_N_AUTHTYPE | CI_N_PAP);
			go -> lcp_neg &= ~CI_N_CHAP;
			go -> auth_prot = PAP;
		    }
		    else if(cishort == CHAP && wo -> lcp_neg & CI_N_CHAP) {
			LOG3(LOG_NEG, (LOG_LCP_AUTH_NAK, "CHAP"));
			go -> lcp_neg |= (CI_N_AUTHTYPE | CI_N_CHAP);
			go -> lcp_neg &= ~CI_N_PAP;
			go -> auth_prot = CHAP;
		    }
#ifdef LOGGING_ENABLED
		    else {
			LOG3(LOG_NEG, (LOG_LCP_AUTH_NAK_HEX,
				      cishort));
		    }
#endif /* LOGGING_ENABLED */

		    if (cishort != go -> auth_prot) {
			link_error = SSDE_NEG_FAILED;
			LOG3(LOG_BASE, (LOG_LCP_NO_AUTH));
			DOLOG(negotiation_problem = "Negotiation failed";)
		    }
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_LCP_AUTH_NAK, ""));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_MAGICNUMBER:
		if (l == 6 && ao -> lcp_neg & CI_N_MAGICNUMBER) {
		    GETLONG(cilong, p1);
		    LOG3(LOG_NEG, (LOG_LCP_MAGIC_NAK, cilong));
		    go -> lcp_neg |= CI_N_MAGICNUMBER;
		    go -> magicnumber = NetGenerateRandom32();

		    ++go -> rxnaks[CI_MAGICNUMBER];
#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_MAGICNUMBER] % lcp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_WARN_LOOP));
		    	negotiation_problem = "The line may be looped back";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_LCP_MAGIC_NAK_SIMPLE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_LQM:
		if (l == 8 && ao -> lcp_neg & CI_N_LQM) {
		    GETSHORT(cishort, p1);
		    GETLONG(cilong, p1);

		    if (cishort == LQM) {
			LOG3(LOG_NEG, (LOG_LCP_LQM_NAK,
			     cilong / 100L, cilong % 100L));
			go -> lcp_neg |= CI_N_LQM;
			go -> lqrinterval = cilong;
		    }
#ifdef LOGGING_ENABLED
		    else {
			LOG3(LOG_NEG, (LOG_LCP_LQM_NAK_HEX, cishort));
		    }
#endif /* LOGGING_ENABLED */

		    ++go -> rxnaks[CI_LQM];
#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_LQM] % lcp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_LCP_NO_LQM));
			negotiation_problem = "Negotiation failed";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_LCP_LQM_NAK_SIMPLE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_PCOMPRESSION:
		if (l == 2 && ao -> lcp_neg & CI_N_PCOMPRESSION)
		    go -> lcp_neg &= ~CI_N_PCOMPRESSION;

		LOG3(LOG_NEG, (LOG_LCP_PCOMP_NAK));

		break;

	    case CI_ACCOMPRESSION:
		if (l == 2 && ao -> lcp_neg & CI_N_ACCOMPRESSION)
		    go -> lcp_neg &= ~CI_N_ACCOMPRESSION;

		LOG3(LOG_NEG, (LOG_LCP_ACOMP_NAK));

		break;

	    default:
		LOG3(LOG_NEG,  (LOG_LCP_UNKNOWN_NAK, p[0]));
	    }

	/*
	 * Set things up for the next option in the nak packet.
	 */
	len -= l;
	p += l;
    }

    /*
     * All options this PPP understands has been processed.  If
     * there is anything left, then this nak is bad.
     */
    if (len == 0)
	return;

bad:
    LOG3(LOG_NEG, (LOG_LCP_BAD, "Nak"));
}


/***********************************************************************
 *				lcp_rejci
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Reject. (FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_rejci (fsm *f,
		unsigned char *p,
		int len)
{
    lcp_options *go = &lcp_gotoptions[f -> unit];
    unsigned short cishort;
    unsigned long cilong;
    unsigned char cichar;

    /*
     * Any Rejected CIs must be in exactly the same order that we sent.
     * Check packet length and CI length at each step.
     * If we find any deviations, then this packet is bad.
     */
#define REJCIVOID(opt, neg, code) \
    if ((go -> lcp_neg & neg) && \
	len >= 2 && \
	p[1] == 2 && \
	p[0] == opt) { \
	len -= 2; \
	INCPTR(2, p); \
	go -> lcp_neg &= ~neg; \
	code \
    }
#define REJCISHORT(opt, neg, val, code) \
    if ((go -> lcp_neg & neg) && \
	len >= 2 + sizeof (short) && \
	p[1] == 2 + sizeof (short) && \
	p[0] == opt) { \
	len -= 2 + sizeof (short); \
	INCPTR(2, p); \
	GETSHORT(cishort, p); \
	/* Check rejected value. */ \
	if (cishort != val) \
	    goto bad; \
	go -> lcp_neg &= ~neg; \
	code \
    }
#define REJCICHAP(opt, neg, short1, char1, char2, code) \
    if ((go -> lcp_neg & neg) && \
	len >= 5 && \
	p[1] == 5 && \
	p[0] == opt) { \
	len -= 5; \
	INCPTR(2, p); \
	GETSHORT(cishort, p); \
	/* Check rejected value. */ \
	if (cishort != short1) \
	    goto bad; \
	GETCHAR(cichar, p); \
	if (cichar != char1) \
	    goto bad; \
	go -> lcp_neg &= ~neg; \
	code \
    }
#define REJCILONG(opt, neg, val, code) \
    if ((go -> lcp_neg & neg) && \
	len >= 2 + sizeof (long) && \
	p[1] == 2 + sizeof (long) && \
	p[0] == opt) { \
	len -= 2 + sizeof (long); \
	INCPTR(2, p); \
	GETLONG(cilong, p); \
	/* Check rejected value. */ \
	if (cilong != val) \
	    goto bad; \
	go -> lcp_neg &= ~neg; \
	code \
    }

    REJCISHORT(CI_MRU, CI_N_MRU, go -> mru,
	       LOG3(LOG_NEG, (LOG_LCP_MRU_REJ));
	      )

    REJCILONG(CI_ASYNCMAP, CI_N_ASYNCMAP, go -> asyncmap,
	      LOG3(LOG_NEG, (LOG_LCP_AMAP_REJ));
	      )

    if (go -> lcp_neg & CI_N_AUTHTYPE)
	if (go -> auth_prot == PAP) {
	    REJCISHORT(CI_AUTHTYPE, CI_N_AUTHTYPE, go -> auth_prot,
		       link_error = SSDE_AUTH_REFUSED;
		       LOG3(LOG_NEG, (LOG_LCP_AUTH_REJ));
		       LOG3(LOG_BASE, (LOG_LCP_NO_AUTH));
	       DOLOG(negotiation_problem = "Peer refuses to authenticate";)
		       )
	}
	else {	/* else CHAP */
	    REJCICHAP(CI_AUTHTYPE, CI_N_AUTHTYPE, go -> auth_prot, 5, 0,
		      link_error = SSDE_AUTH_REFUSED;
		      LOG3(LOG_NEG, (LOG_LCP_AUTH_REJ));
		      LOG3(LOG_BASE, (LOG_LCP_NO_AUTH));
	           DOLOG(negotiation_problem = "Peer refuses to authenticate";)
		      )
	}

    REJCILONG(CI_MAGICNUMBER, CI_N_MAGICNUMBER, go -> magicnumber,
	      LOG3(LOG_NEG, (LOG_LCP_MAGIC_REJ));
	      )

    if (go -> lcp_neg & CI_N_LQM && len >= 8 && p[1] == 8 && p[0] == CI_LQM) {
	len -= 8;
	INCPTR(2, p);
	GETSHORT(cishort, p);
	GETLONG(cilong, p);

	if (cishort != LQM ||
	    cilong != go -> lqrinterval)
	    goto bad;

	LOG3(LOG_NEG, (LOG_LCP_LQM_REJ));

	go -> lcp_neg &= ~CI_N_LQM;
    }

    REJCIVOID(CI_PCOMPRESSION, CI_N_PCOMPRESSION,
	      LOG3(LOG_NEG, (LOG_LCP_PCOMP_REJ));
	     )

    REJCIVOID(CI_ACCOMPRESSION, CI_N_ACCOMPRESSION,
	      LOG3(LOG_NEG, (LOG_LCP_ACOMP_REJ));
	     )
    /*
     * If there are any remaining CIs, then this packet is bad.
     */
    if (len == 0)
	return;
bad:
    LOG3(LOG_NEG, (LOG_LCP_BAD, "Reject"));

}


/***********************************************************************
 *				lcp_reqci
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Request packet. (FSM callback)
 * CALLED BY:	fsm_input
 * RETURN:	0 if no reply should be sent
 *	    	else CONFIGURE_ACK, CONFIGURE_NAK or CONFIGURE_REJECT
 * SIDE EFFECTS: Input packet is modified appropriately.
 *
 * STRATEGY:  Check the peer's requested Configuration Options
 *	    and formulate the appropriate response.
 *
 *	    A new packet is allocated for building the reply.  After
 *	    the reply has been fully constructed, the data is copied
 *	    to the passed in pointer, overwriting the received options.
 *	    The packet allocated here is then freed.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
unsigned char lcp_reqci (fsm *f,
			 unsigned char *inp,	/* Requested options */
			 int *len)  	        /* Len of req. options */
{
    lcp_options *go = &lcp_gotoptions[f -> unit];
    lcp_options *ho = &lcp_heroptions[f -> unit];
    lcp_options *ao = &lcp_allowoptions[f -> unit];
    lcp_options *wo = &lcp_wantoptions[f -> unit];

    PACKET *reply_pkt;
    unsigned char *reply_p; 	    	    /* Ptr to head of reply */

    unsigned char *outoptp; 		    /* Ptr to current output option */
    unsigned char *outp;    	  	    /* Ptr to current output char */
    unsigned char *optp = inp;	    	    /* Ptr to current recvd option */

    unsigned char optlen, opttype;  	    /* option len, option type */
    unsigned short tmpshort;	    	    /* Parsed short value */
    unsigned long tmplong;	    	    /* Parsed long value */

    int rc = CONFIGURE_ACK;	    	    /* Final reply code */
    int orc;			    	    /* Return code of current option */

    unsigned char *p;	    	    	/* Ptr to next input char to parse */
    int l = *len;   	    	    	/* remaining length of recvd packet */
    int not_converging = f -> tx_naks >= f -> max_failure;

    DOLOG(char map[SHORT_STR_LEN];)    	/* asyncmap_name() output */

    reply_pkt = PACKET_ALLOC(MAX_MTU);
    if (reply_pkt == 0)     	    /* no memory, oh well.. */
	return (0);
    reply_p = outoptp = outp = PACKET_DATA(reply_pkt);

# define NAK(len)	{ \
			orc = CONFIGURE_NAK; \
			if (rc != CONFIGURE_REJECT) \
			    { \
			    if (rc != CONFIGURE_NAK) \
				outoptp = reply_p; \
			    rc = CONFIGURE_NAK; \
			    outp = outoptp; \
			    PUTCHAR(opttype, outp); \
			    PUTCHAR(len, outp); \
			    } \
			}

# define REJECT()	{ \
			LOG3(LOG_NEG, (LOG_REJ)); \
			orc = CONFIGURE_REJECT; \
			if (rc != CONFIGURE_REJECT) \
			    outoptp = reply_p; \
			rc = CONFIGURE_REJECT; \
			outp = outoptp; \
			memcpy(outp, optp, optlen); \
			outp += optlen; \
			}
#ifdef LOGGING_ENABLED
    /*
     * Log a warning if configure-request does not contain any options.
     */
    if (l == 0) {
	LOG3(LOG_NEG, (LOG_LCP_EMPTY));
    }
#endif /* LOGGING_ENABLED */

    /*
     * Reset all her options, clearing out everything except for
     * CI_N_AUTHTYPE.  [XXX: Only do this if we are getting new options
     * to avoid bug in Annex PPP server which sends empty requests after
     * negotiating other options. -jwu 2/2/96]
     */
    if (l) {
	ho -> lcp_neg &= CI_N_AUTHTYPE;
    }

    /*
     * Process each Configuration Option in this Configure-Request
     * message.
     */
    while (l) {
	orc = CONFIGURE_ACK;	    /* Assume success for this option */
	p = optp;   	    	    /* p points to beginning of this option */

	/*
	 * If not enough data for option header or option length too small
	 * or option length too big, then give up without sending a reply.
	 */
	if (l < 2 || p[1] < 2 || (int)p[1] > l) {
	    LOG3(LOG_NEG, (LOG_LCP_BAD, "Request (bad option length)"));
	    PACKET_FREE(reply_pkt);
	    return (0);
	}

	GETCHAR(opttype, p);	    	/* Parse option type */
	GETCHAR(optlen, p); 	    	/* and option length */
	l -= optlen;	    	    	/* Adjust remaining length */

	switch (opttype)		/* Check Configuration Option type */
	    {
	    case CI_MRU:
		LOG3(LOG_NEG, (LOG_LCP_RECV_MRU));

		/*
		 * If not allowing negotiation of option, reject it.
		 */
		if ((ao -> lcp_neg & CI_N_MRU) == 0)	{
		    REJECT();
		    break;
		}

		/*
		 * If option length is bad, Nak with the default MRU.
		 * Don't stick desired values in packet if we're sending
		 * a reject!
		 */
		if (optlen != 4) {
		    NAK(optlen);
		    if (rc != CONFIGURE_REJECT) {
			PUTSHORT(DEFMRU, outp);
		    }
		    LOG3(LOG_NEG, (LOG_NAK_VALUE, DEFMRU));
		    break;
		}

		/*
		 * Get requested MRU and verify it.  The peer must
		 * be able to receive at least our minimum.  No need
		 * to check a maximum.  If she sends a large number,
		 * we'll just ignore it.  We don't want to use anything
		 * bigger than our maximum.
		 */
		GETSHORT(tmpshort, p);
		LOG3(LOG_NEG, (LOG_FORMAT_DEC, tmpshort));
		if (tmpshort < MINMRU || tmpshort > MAX_MTU) {
		    if (not_converging) {
			REJECT();
			link_error = SSDE_NEG_FAILED;

			LOG3(LOG_BASE, (LOG_LCP_CANT_MRU));
			DOLOG(negotiation_problem = "Negotiation failed";)
		    }
		    else {
			NAK(optlen);
			/*
			 * Nak with desired MRU only if packet is
			 * not a reject!
			 */
			if (rc != CONFIGURE_REJECT) {
			    if (tmpshort < MINMRU) {
				PUTSHORT(MINMRU, outp);  /* Suggest minimum */
				LOG3(LOG_NEG, (LOG_NAK_VALUE, MINMRU));
			    }
			    else {
				PUTSHORT(MAX_MTU, outp);
				LOG3(LOG_NEG, (LOG_NAK_VALUE, MAX_MTU));
			    }
			}
			DOLOG(else LOG3(LOG_NEG, (LOG_NEWLINE));)
		    }
		}
		else {
		    /*
		     * Remember peer negotiated MRU and the value.
		     */
		    ho -> lcp_neg |= CI_N_MRU;
		    ho -> mru = tmpshort;
		}

		break;

	    case CI_ASYNCMAP:
		LOG3(LOG_NEG, (LOG_LCP_RECV_AMAP));

		/*
		 * If not allowing negotiation of ACCM, reject option.
		 */
		if ((ao -> lcp_neg & CI_N_ASYNCMAP) == 0) {
		    REJECT();
		    break;
		}

		/*
		 * If bad option length, Nak it and suggest default ACCM.
		 * Only put desired value in packet if not rejecting!
		 */
		if (optlen != 6) {
		    NAK(optlen);
		    if (rc != CONFIGURE_REJECT) {
			PUTLONG(0xffffffff, outp);
		    }
		    LOG3(LOG_NEG, (LOG_NAK_VALUE, 0xffffffff));
		    break;
		}

		GETLONG(tmplong, p);
		LOG3(LOG_NEG, (LOG_FORMAT_LONG, tmplong));

#ifdef LOGGING_ENABLED
		asyncmap_name(map, tmplong);
		if (map[0] != '\0')
		    LOG3(LOG_NEG, (LOG_FORMAT_STRING, map));
#endif /* LOGGING_ENABLED */

		ho -> lcp_neg |= CI_N_ASYNCMAP;
		ho -> asyncmap = tmplong;
		break;

	    case CI_AUTHTYPE:
		LOG3(LOG_NEG, (LOG_LCP_RECV_AUTH));

		/*
		 * If not allowing authentication to be negotiated or
		 * if the option length is way too short, reject it.
		 */
		if ((ao -> lcp_neg & CI_N_AUTHTYPE) == 0 || optlen < 4) {
		    REJECT();
		    break;
		}

		GETSHORT(tmpshort, p);
		LOG3(LOG_NEG, (LOG_FORMAT_MIXED, tmpshort,
			      tmpshort == CHAP ? " (CHAP)"
			      	    : (tmpshort == PAP ? " (PAP)" : ""),
			      optlen));

		/*
		 * Authentication type must be PAP or CHAP.
		 */
		if (tmpshort == PAP) {
		    /*
		     * Allow PAP if negotiating it and option length is good.
		     */
		    if (ao -> lcp_neg & CI_N_PAP)
			if (optlen != 4) {
			    REJECT();
			}
		    	else {
			    ho -> lcp_neg |= CI_N_PAP;
			    ho -> lcp_neg &= ~CI_N_CHAP;
			}
		    /*
		     * If not allowing CHAP negotiation and not converging
		     * don't allow authentication.  Else suggest CHAP.
		     * Don't suggest anything if packet if rejecting!
		     */
		    else if ((ao -> lcp_neg & CHAP) == 0 || not_converging) {
			REJECT();
		    }
		    else {
			NAK(5);
			LOG3(LOG_NEG, (LOG_LCP_NAK_CHAP));
			if (rc != CONFIGURE_REJECT) {
			    PUTSHORT(CHAP, outp);
			    PUTCHAR(5, outp);	    	/* MD5 */
			}
			ho -> lcp_neg &= ~CI_N_PAP;
			ho -> lcp_neg |= CI_N_CHAP;
		    }
		}
		else if (tmpshort == CHAP) {
		    /*
		     * Allow CHAP if negotiating it as long as MD5 is
		     * the algorithm used.
		     */
		    if (ao -> lcp_neg & CI_N_CHAP) {
			if (optlen == 5)
			    if (p[0] == 5) {	    /* MD5 */
				ho -> lcp_neg |= CI_N_CHAP;
#ifdef MSCHAP
				ho -> lcp_neg &= ~CI_N_MSCHAP;
				LOG3(LOG_NEG, (LOG_FORMAT_STRING, "MD5"));
#endif
				ho -> lcp_neg &= ~CI_N_PAP;
			    }
#ifdef MSCHAP
			    else if (p[0] == 0x80) {	/* MSCHAP */
				ho -> lcp_neg |= CI_N_MSCHAP | CI_N_CHAP;
				ho -> lcp_neg &= ~CI_N_PAP;
				LOG3(LOG_NEG, (LOG_FORMAT_STRING, "MSCHAP"));
			    }
#endif
			    else if (not_converging) {
				REJECT();
			    }
			    else {
				/*
				 * Suggest MD5 only if not rejecting!
				 */
				NAK(5);
				LOG3(LOG_NEG, (LOG_LCP_NAK_CHAP));
				if (rc != CONFIGURE_REJECT) {
				    PUTSHORT(CHAP, outp);
				    PUTCHAR(5, outp);	    /* MD5 */
				}
				ho -> lcp_neg &= ~CI_N_PAP;
				ho -> lcp_neg |= CI_N_CHAP;
			    }
			else {
			    REJECT();
			}
		    }
		    else if ((ao -> lcp_neg & CI_N_PAP) == 0 ||
			     not_converging) {
			REJECT();
		    }
		    else {
			/*
			 * Suggest PAP only if not rejecting!
			 */
			NAK(4);
			LOG3(LOG_NEG, (LOG_LCP_NAK_PAP));
			if (rc != CONFIGURE_REJECT) {
			    PUTSHORT(PAP, outp);
			}
			ho -> lcp_neg |= CI_N_PAP;
			ho -> lcp_neg &= ~CI_N_CHAP;
		    }
		}
		/*
		 * If not PAP nor CHAP and we're not converging, then
		 * reject it.  Else, suggest CHAP only if not rejecting!
		 */
		else if (not_converging) {
		    REJECT();
		}
		else {
		    NAK(5);
		    LOG3(LOG_NEG, (LOG_LCP_NAK_CHAP));
		    if (rc != CONFIGURE_REJECT) {
			PUTSHORT(CHAP, outp);
			PUTCHAR(5, outp);	    	/* MD5 */
		    }
		    ho -> lcp_neg &= ~CI_N_PAP;
		    ho -> lcp_neg |= CI_N_CHAP;
		}

		if (orc == CONFIGURE_REJECT && not_converging) {
		    link_error = SSDE_NEG_FAILED;
		    LOG3(LOG_BASE, (LOG_LCP_CANT_AUTH));
		    DOLOG(negotiation_problem = "Negotiation failed";)
		}

		break;

	    case CI_MAGICNUMBER:
		LOG3(LOG_NEG, (LOG_LCP_RECV_MAGIC));

		/*
		 * If not negotiating magic number, reject it.
		 */
		if ((ao -> lcp_neg & CI_N_MAGICNUMBER) == 0) {
		    REJECT();
		    break;
		}

		/*
		 * If option length is correct, parse the magic number
		 * else use zero.
		 */
		if (optlen == 6) {
		    GETLONG(tmplong, p);
		    LOG3(LOG_NEG, (LOG_FORMAT_LONG, tmplong));
		}
		else tmplong = 0;

		/*
		 * She must have a different magic number than us.
		 */
		if (go -> lcp_neg & CI_N_MAGICNUMBER &&
		    (tmplong == 0 || tmplong == go -> magicnumber))
		    if (not_converging) {
			REJECT();
			link_error = SSDE_NEG_FAILED;

			LOG3(LOG_BASE, (LOG_LCP_CANT_MAGIC));
			DOLOG(negotiation_problem = "Negotiation failed";)

			break;
		    }
		    else {
			NAK(optlen);
			if (rc != CONFIGURE_REJECT) {
			    tmplong = NetGenerateRandom32();
			    LOG3(LOG_NEG, (LOG_LCP_LQM_NAK_HEX, tmplong));
			    PUTLONG(tmplong, outp);
			}
			DOLOG(else LOG3(LOG_NEG, (LOG_NEWLINE));)
		    }
		else {
		    ho -> lcp_neg |= CI_N_MAGICNUMBER;
		    ho -> magicnumber = tmplong;
		}

		break;

	    case CI_LQM:
		LOG3(LOG_NEG, (LOG_LCP_RECV_LQM));

		if ((ao -> lcp_neg & CI_N_LQM) == 0 || optlen < 4) {
		    REJECT();
		    break;
		}

		GETSHORT(tmpshort, p);
		LOG3(LOG_NEG, (LOG_FORMAT_MIXED, tmpshort,
			      tmpshort == LQM ? " (LQM)" : "", optlen));

		if (tmpshort == LQM)
		    if (optlen == 8) {
			GETLONG(tmplong, p);

#ifdef LOGGING_ENABLED
			if (tmplong) {
			    LOG3(LOG_NEG, (LOG_REPORT_PERIOD,
					  tmplong / 100L, tmplong % 100L));
			}
			else {
			    LOG3(LOG_NEG, (LOG_RESPONSE_ONLY));
			}
#endif /* LOGGING_ENABLED */

			 /*
			  * Must nak zero interval if we want zero
			  * interval.  RFC 1333 - LQM.
			  */
			if (tmplong || go -> lqrinterval) {
			    /*
			    * Go ahead and do what she says.
			    */
			    ho -> lcp_neg |= CI_N_LQM;
			    ho -> lqrinterval = tmplong;
			}
			else {
			    NAK(8);
			    LOG3(LOG_NEG, (LOG_LCP_NAK_LQM));
			    if (rc != CONFIGURE_REJECT) {
				PUTSHORT(LQM, outp);
				PUTLONG(DEFAULT_LQR_INTERVAL, outp);
			    }
			}
		    }
		    else {
			REJECT();
		    }
		else if ((wo -> lcp_neg & CI_N_LQM) == 0 || not_converging) {
		    REJECT();
		}
		else {
		     /*
		      * Suggest LQM protocol for monitoring link.
		      */
		    NAK(8);
		    LOG3(LOG_NEG, (LOG_LCP_NAK_LQM));
		    if (rc != CONFIGURE_REJECT) {
			PUTSHORT(LQM, outp);
			PUTLONG(wo -> lqrinterval, outp);
		    }
		}

		break;

	    case CI_PCOMPRESSION:
		LOG3(LOG_NEG, (LOG_LCP_RECV_PCOMP));

		if ((ao -> lcp_neg & CI_N_PCOMPRESSION) == 0 || optlen != 2) {
		    REJECT();
		}
		else
		    ho -> lcp_neg |= CI_N_PCOMPRESSION;

		break;

	    case CI_ACCOMPRESSION:
		LOG3(LOG_NEG, (LOG_LCP_RECV_ACOMP));

		if ((ao -> lcp_neg & CI_N_ACCOMPRESSION) == 0 || optlen != 2) {
		    REJECT();
		}
		else
		    ho -> lcp_neg |= CI_N_ACCOMPRESSION;

		break;

	    default:
		LOG3(LOG_NEG, (LOG_LCP_UNKNOWN_OPT, opttype));
		REJECT();
		break;
	    }

	/*
	 * If still acking, copy option to reply packet and advance
	 * reply data pointer.
	 */
	if (orc == CONFIGURE_ACK) {
	    LOG3(LOG_NEG, (LOG_ACK));
	    if (rc == CONFIGURE_ACK) {
		memcpy(outp, optp, optlen);
		outp += optlen;
	    }
	}

	/*
	 * Advance configuration option pointer to next option and
	 * set output option to the next option.
	 */
	optp += optlen;
	outoptp = outp;
    }

    /*
     * If we wanted to send additional NAKs (for unsent CIs), the
     * code would go here.  This must be done with care since it
     * might require a longer packet than we received.
     */

    /*
     * Compute output length and copy the reply packet's data to the
     * original buffer.  Then free the reply buffer.
     */
    *len = outp - reply_p;
    memcpy(inp, reply_p, *len);
    PACKET_FREE(reply_pkt);

    LOG3(LOG_NEG, (LOG_LCP_REPLY,
		  rc == CONFIGURE_ACK ? "Configure-Ack" :
		  rc == CONFIGURE_NAK ? "Configure-Nak" : "Configure-Reject"));

    /*
     * Return final result code.
     */
    return (rc);

}


/***********************************************************************
 *				lcp_up
 ***********************************************************************
 * SYNOPSIS:	LCP has come up. (FSM callback)
 * CALLED BY:	tlu 	= This Layer Up
 * RETURN:	nothing
 *
 * STRATEGY:	Start PAP, IPCP, CHAP, etc.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_up (fsm *f)
{
    lcp_options *ho = &lcp_heroptions[f -> unit];
    lcp_options *wo = &lcp_wantoptions[f -> unit];
    lcp_options *go = &lcp_gotoptions[f -> unit];
    int auth = 0;

    /*
     * If we wanted to negotiate authentication but didn't get it,
     * then shut down LCP.
     */
    if (wo -> lcp_neg & CI_N_AUTHTYPE &&
	(go -> lcp_neg & CI_N_AUTHTYPE) == 0) {
	link_error = SSDE_AUTH_REFUSED | SDE_CONNECTION_RESET;
	LOG3(LOG_BASE, (LOG_LCP_GIVE_UP_AUTH));
	lcp_close(0);
	return;
    }

    /*
     * If configured MRU, set the interface MRU to the new value.
     */
    if (f -> state == OPENED && ho -> lcp_neg & CI_N_MRU) {
	SetInterfaceMTU(ho -> mru);
    } else {
	SetInterfaceMTU(DEFMRU);
    }


    /*
     * If we got ACCM or peer got ACCM, set the escape and discard
     * character maps.
     */
    if (go -> lcp_neg & CI_N_ASYNCMAP || ho -> lcp_neg & CI_N_ASYNCMAP)
	SetEscapeMap(f -> unit,
	     (go -> lcp_neg & CI_N_ASYNCMAP) ? go -> asyncmap : 0xffffffff,
             (ho -> lcp_neg & CI_N_ASYNCMAP) ? ho -> asyncmap : 0xffffffff);

    /*
     * Set compression if negotiated.
     */
    if (go -> lcp_neg & CI_N_PCOMPRESSION ||
	ho -> lcp_neg & CI_N_PCOMPRESSION)
	SetProtoCompression(f -> unit, go -> lcp_neg & CI_N_PCOMPRESSION,
			    ho -> lcp_neg & CI_N_PCOMPRESSION);

    if (go -> lcp_neg & CI_N_ACCOMPRESSION ||
	ho -> lcp_neg & CI_N_ACCOMPRESSION)
	SetACCompression(f -> unit, go -> lcp_neg & CI_N_ACCOMPRESSION,
			 ho -> lcp_neg & CI_N_ACCOMPRESSION);

    /*
     * Enable LQM, PAP, CHAP.
     */
    lqm_lowerup(f -> unit);
    pap_lowerup(f -> unit);
    chap_lowerup(f -> unit);

    /*
     * If the peer agreed to send LQRs, then she must also process
     * received LQRs.
     *
     * If the peer asked us to send LQRs, then we must send LQRs.
     */
    lqm[f -> unit].magicnumber =
	(go -> lcp_neg & CI_N_MAGICNUMBER) ? go -> magicnumber : 0;

    if (go -> lcp_neg & CI_N_LQM || ho -> lcp_neg & CI_N_LQM) {
	int interval;

	/*
	 * Use the peer's interval if theirs is shorter.
	 */
	interval = go -> lcp_neg & CI_N_LQM ? go -> lqrinterval : 0;

	if (ho -> lcp_neg & CI_N_LQM && ho -> lqrinterval &&
	    ho -> lqrinterval < interval)
	    interval = ho -> lqrinterval;

	lqm_start(f -> unit, interval, 0, go -> lqm_k, go -> lqm_n);
    }
    else if (wo -> lcp_flags & LF_ECHO_LQM)
	lqm_start(f -> unit, wo -> lqrinterval, 1, wo -> lqm_k, wo -> lqm_n);

    /*
     * Start up PAP if negotiated.
     */
    if (go -> lcp_neg & CI_N_PAP) {
	pap_authpeer(f -> unit);
	auth = 1;
    }

    if (ho -> lcp_neg & CI_N_PAP) {
	pap_authwithpeer(f -> unit);
	auth = 1;
    }

    /*
     * Start up CHAP if negotiated.
     */
    if (go -> lcp_neg & CI_N_CHAP) {
	chap_authpeer(f -> unit);
	auth = 1;
    }

    if (ho -> lcp_neg & CI_N_CHAP) {
	chap_authwithpeer(f -> unit);
	auth = 1;
    }

    /*
     * If not doing authentication, then ready for network traffic.
     */
    if (!auth)
	BeginNetworkPhase(f -> unit);

}  /* End of lcp_up */



/***********************************************************************
 *				lcp_down
 ***********************************************************************
 * SYNOPSIS:	LCP has gone DOWN. (FSM callback)
 * CALLED BY:	tld 	    = This Layer Down
 * RETURN:  	nothing
 *
 * STRATEGY:	Alert other protocols.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_down (fsm *f)
{
    /*
     * Reset escape and discard maps, compression.
     */
    SetEscapeMap(f -> unit, 0xffffffff, 0xffffffff);
    SetProtoCompression(f -> unit, 0, 0);
    SetACCompression(f -> unit, 0, 0);

    /*
     * Alert other protocols.
     */
    lqm_lowerdown(f -> unit);
    pap_lowerdown(f -> unit);
    chap_lowerdown(f -> unit);

    EndNetworkPhase(f -> unit);

}  /* End 0f lcp_down */



/***********************************************************************
 *				lcp_closed
 ***********************************************************************
 * SYNOPSIS:	LCP has CLOSED.  (FSM callback routine.)
 * CALLED BY:	fsm_lowerdown
 *	    	tlf 	= This Layer Finished
 * RETURN:	nothing
 *
 * STRATEGY:	Clean up state and close up physical connection.
 *	    	Notify TCP/IP client link has closed.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
void lcp_closed (fsm *f)
{
    /*
     * MUST NOT execute this code if already closed device or
     * will infinite loop!
     */
    if (PPPDeviceClose()) {
	 /*
	  * Bring LCP to INITIAL or STARTING state so CLOSE event
	  * will not generate terminate request packets.  After all,
	  * we just closed the physical connection.
	  */
	if (! passive_waiting)
	    lcp_lowerdown(0);
	lcp_close(0);

#ifdef LOGGING_ENABLED
	if (ip_connected) {
	    LOG3(LOG_IF, (LOG_DOWN));

	    log_state("disconnected");
	    LOG3(LOG_BASE, (LOG_DISCONNECTED,
			   shutdown_reason ? " (" : "",
			   shutdown_reason ? shutdown_reason : "",
			   shutdown_reason ? ")" : ""));

	    if (logfile)
		print_acct();

	    rx_bps = tx_bps = rx_pps = tx_pps = 0;
	}

	LOG3(LOG_MISC, (LOG_CLOSED));

	if (authentication_failure) {
	    sprintf(fail_state, "off (%s)", authentication_failure);
	    log_state(fail_state);
	}
	else if (negotiation_problem) {
	    sprintf(fail_state, "off (%s)", negotiation_problem);
	    log_state(fail_state);
	}
	else if (shutdown_reason) {
	    sprintf(fail_state, "off (%s)", shutdown_reason);
	    log_state(fail_state);
	}
	else
	    log_state("off");
#endif /* LOGGING_ENABLED */

	 /*
	  * Finally, tell TCP/IP client the link is closed.
	  */
	ip_connected = 0;
	PPPLinkClosed(link_error);
	link_error = SDE_NO_ERROR;	    	/* reset error */
    }
}

#ifdef __HIGHC__
#pragma Code("LQMINIT");
#endif
#ifdef __BORLANDC__
#pragma codeseg LQMINIT
#endif
#ifdef __WATCOMC__
#pragma code_seg("LQMINIT")
#endif

/* -------------------------------------------------------------------------
 * 	    	Link Quality Monitoring Code
 ------------------------------------------------------------------------ */


/***********************************************************************
 *				lqm_protrej
 ***********************************************************************
 * SYNOPSIS:	Process a received Protocol-Reject for LQM.
 * CALLED BY:	demuxprotrej using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	Stop LQR timer and reset percentages.  If sending LQRs,
 *	    	send one now using echo request because peer doesn't
 *	    	understand LQM.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_protrej (int unit)
{
    lqm_t *lq = &lqm[unit];

    LOG3(LOG_NEG, (LOG_LQM_REJ));

    lq -> timer = 0;
    DOLOG(rx_percent = tx_percent = 100;)

    if (lq -> interval)
	lqm_send_echo(lq);

}  /* End Of lqm_protrej */



/***********************************************************************
 *				lqm_lowerup
 ***********************************************************************
 * SYNOPSIS:	The lower layer has gone up.
 * CALLED BY:	lcp_up
 * RETURN:	nothing
 *
 * STRATEGY:	Make sure previous LQM session stops.  Reset history.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_lowerup (int unit)
{
    lqm_t *lq = &lqm[unit];
    int i;

    lq -> unit = unit;
    lqm_lowerdown(unit);

    for (i = 0; i < 256; ++i)
	lq -> lqr_history[i] = 0;

    lq -> history_index = 0;
    lq -> timed_out = 0;
}


/***********************************************************************
 *				lqm_lowerdown
 ***********************************************************************
 * SYNOPSIS:	The lower layer has gone down.
 * CALLED BY:	lqm_lowerup
 *	    	lcp_down
 * RETURN:	nothing
 *
 * STRATEGY:	Stop LQR timer, remember LQR is not running, clear LQR
 *	    	interval and reset percentages.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_lowerdown (int unit)
{
    lqm_t *lq = &lqm[unit];

    lq -> timer = 0;
    lq -> running = 0;
    lq -> interval = 0;
    DOLOG(rx_percent = tx_percent = 100;)

}


/***********************************************************************
 *				lqm_start
 ***********************************************************************
 * SYNOPSIS:	Start up LQM with the given LQR interval, using LQRs or
 *	    	LCP echos for the report as dictated by caller.
 * CALLED BY:	lcp_up
 * RETURN:	nothing
 *
 * STRATEGY:    Setting LQR running mode, interval, k and n as requested
 *	    	Initialize in/out counts.
 *	    	If sending reports, send one using the appropriate method
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_start (int unit,
		unsigned long lqrinterval,  	/* in 100ths of a second */
		unsigned char echolqm,	    	/* non-zero to use LCP echo */
		int k,	    	    	    	/* k/n LQRs must be received */
		int n)	    	    	    	/* or else connection drops */
{
    lqm_t *lq = &lqm[unit];

    lq -> running = echolqm ? LQ_ECHO : LQ_LQR;
    lq -> interval = lqrinterval;
    lq -> k = k;
    lq -> n = n;

    /*
     * Reset all LQM counters to make a clean start.
     */

    lq -> received_lqrs = 0;
    lq -> OutLQRs = lq -> InLQRs = lq -> InGoodOctets = 0;
    lq -> ifOutUniPackets = lq -> ifOutNUniPackets = 0;
    lq -> ifOutOctets = lq -> ifOutDiscards = 0;
    lq -> ifInUniPackets = lq -> ifInNUniPackets = 0;
    lq -> ifInDiscards = lq -> ifInErrors = 0;

    /*
     * Also reset saved lastlqr values.  LastOut values can be
     * indeterminate as long as PeerInLQR is 0, however, to keep
     * our implementation clean, we will.  PeerIn values get set
     * only when we receive a LQR.
     */
    lq -> lastlqr.LastOutLQRs = lq -> lastlqr.LastOutPackets =
	lq -> lastlqr.LastOutOctets = 0;

    lq -> lastlqr.PeerOutLQRs = lq -> lastlqr.PeerOutPackets =
	lq -> lastlqr.PeerOutOctets = 0;

    lq -> lastlqr.SaveInLQRs = lq -> lastlqr.SaveInPackets = 0;
    lq -> lastlqr.SaveInDiscards = lq -> lastlqr.SaveInErrors = 0;
    lq -> lastlqr.SaveInOctets = 0;

    if (lq -> interval)
	if (echolqm)
	    lqm_send_echo(lq);
    	else
	    lqm_send_lqr(lq);

}  /* End Of lqm_start */


/***********************************************************************
 *				lqm_failure
 ***********************************************************************
 * SYNOPSIS:	LQM detected a bad PPP link.  Shut down LCP.
 * CALLED BY:	lqm_send_lqr
 *	    	lcp_echoreply
 *	    	lqm_input
 *	    	lqm_send_echo
 * RETURN:	nothing
 *
 * STRATEGY:	Shut down LCP.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_failure (lqm_t *lq)
{
    lcp_wantoptions[lq -> unit].lcp_flags |= LF_LOST_LINE;

    link_error = SSDE_LQM_FAILURE | SDE_CONNECTION_RESET;
    DOLOG(shutdown_reason = "LQM failure";)

    lcp_close(lq -> unit);
}

#ifdef __HIGHC__
#pragma Code("LCPLQMCOMMON");
#endif
#ifdef __BORLANDC__
#pragma codeseg LCPLQMCOMMON
#endif
#ifdef __WATCOMC__
#pragma code_seg("LCPLQMCOMMON")
#endif


/***********************************************************************
 *				lcp_input
 ***********************************************************************
 * SYNOPSIS:	Receive LCP input packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if the packet affects the idle time
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 4/95		Initial Revision
 *
 ***********************************************************************/
byte lcp_input (int unit,
		PACKET *p,
		int len)
{
    return (fsm_input(&lcp_fsm[unit], p, len));
}


/***********************************************************************
 *				lqm_set_lqr_status
 ***********************************************************************
 * SYNOPSIS:	Update LQR status and return new LQR status.
 * CALLED BY:	lqm_send_lqr
 *	    	lcp_echoreply
 *	    	lqm_input
 *	    	lqm_send_echo
 * RETURN:	non-zero if too many LQR packets have been lost
 *
 * STRATEGY:	Set status.
 *	    	Count the number of lost packets
 *	    	If lost more than n - k of the last packets, return bad
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
unsigned char lqm_set_lqr_status (lqm_t *lq,
				  unsigned char status)
{
    int i, lost = 0;
    unsigned char lqr_index;

    lq -> lqr_history[++lq -> history_index] = status;

    for (i = 0, lqr_index = lq -> history_index; i < lq -> n; ++i)
	if (lq -> lqr_history[lqr_index--] == LQR_LOST)
	    ++lost;

    if (lost > lq -> n - lq -> k)
	return (1);
    else
	return (0);

}



/***********************************************************************
 *				lqm_threshold
 ***********************************************************************
 * SYNOPSIS:	Print out the lqm threshold in the passed buffer.
 * CALLED BY:	lqm_send_lqr
 *	    	lcp_echoreply
 * 	    	lqm_input
 *	    	lqm_send_echo
 * RETURN:	nothing
 * SIDE EFFECTS: buffer filled with formatted string for threshold, if
 *	    	 a threshold has been set.
 *
 * STRATEGY:	Count the total number of packets and the total number
 *	    	of received packets.
 *	    	Format result into a string.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
#ifdef LOGGING_ENABLED

void lqm_threshold (lqm_t *lq, char *buffer)
{
    int i, k, n;

    if (lq -> k == 0 || lq -> n == 0) {
	buffer[0] = '\0';
    }

    for (i = k = n = 0; i < lq -> n; ++i)
	switch (lq -> lqr_history[(lq -> history_index - i) & 255])
	    {
	    case LQR_FOUND: 	++n; ++k; break;
	    case LQR_LOST:  	++n; break;
	    default:	    	i = lq -> n; break;
	    }

    sprintf(buffer, "%d/%d", k, n);
}

#endif /* LOGGING_ENABLED */


/***********************************************************************
 *				lcp_echorequest
 ***********************************************************************
 * SYNOPSIS:	Process a received Echo-Request message (FSM callback)
 * CALLED BY:	fsm_input
 * RETURN:	ECHO_REPLY if valid request, zero otherwise
 *
 * STRATEGY:	Check magic number and modify packet for echo reply
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
unsigned char lcp_echorequest (fsm *f, unsigned char *p, unsigned char id, int len)
     /*fsm *f;*/	    	    	/* old-style function declaration needed here */
     /*unsigned char *p;
unsigned char id;
int len;*/
{
    lqm_t *lq = &lqm[f -> unit];
    unsigned long tmp_magic_number;

    if (len >= 4) {
	/*
	 * Check the magic number before anything else.  Have to get
	 * it whether we're logging or not to keep the pointer correct.
	 */
	GETLONG(tmp_magic_number, p);

	if (lq -> magicnumber &&
	    lq -> magicnumber == tmp_magic_number) {

#ifdef LOGGING_ENABLED
	    if (! lcp_loopback_warned) {
		LOG3(LOG_BASE, (LOG_WARN_LOOP));
		++lcp_loopback_warned;
	    }
#endif /* LOGGING_ENABLED */

	    return (0);
	}

	/*
	 * Modify buffer for echo reply.
	 */
	DECPTR(4, p);
	PUTLONG(lq -> magicnumber, p);
	DECPTR(4, p);
	return (ECHO_REPLY);
    }
    else {
	return (0);
    }
}


/***********************************************************************
 *				lcp_echoreply
 ***********************************************************************
 * SYNOPSIS:	Process a received Echo-Reply message. (FSM callback)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lcp_echoreply (fsm *f, unsigned char *p, unsigned char id, int len)
     /*fsm *f;*/	    	    	    /* old-style function declaration needed here */
     /*unsigned char *p;
unsigned char id;
int len;*/
{
    lqm_t *lq = &lqm[f -> unit];
    unsigned long tmp_magic_number;

    if (len >= 4) {

	GETLONG(tmp_magic_number, p);

	/*
	 * Only process replies that have the correct ID and a magic
	 * number different from our own.
	 */
	if (id == f -> id &&
	    (! lq -> magicnumber || lq -> magicnumber != tmp_magic_number)) {

	    /*
	     * Clear timed out because we got a reply.
	     */
	    lq -> timed_out = 0;

	    /*
	     * If have a measure of what constitutes a good link, check the
	     * status. If too many packets lost, then shut down the PPP link.
	     */
	    if (lq -> k && lq -> n) {
		DOLOG(char thresh[SHORT_STR_LEN];)
		    byte lqm_failed = lqm_set_lqr_status(lq, LQR_FOUND);

		DOLOG(lqm_threshold(lq, thresh);)
		    LOG3(LOG_LQSTAT, (LOG_LQM_ECHO, thresh));

		if (lqm_failed) {
		    LOG3(LOG_BASE, (LOG_LQM_LOST_ECHO));
		    lqm_failure(lq);
		}
	    }
	}
    }
}


/***********************************************************************
 *				lqm_send_echo
 ***********************************************************************
 * SYNOPSIS:	Send an LCP echo request.
 * CALLED BY:	lqm_protrej
 *	    	lqm_start
 *	    	PPPHandleTimeout
 * RETURN:	nothing
 *
 * STRATEGY:	If we have to send LQRs,
 *	    	    Allocate space for magic number
 *	    	    if measuring link quality and haven't timed out
 *	    	    	check for link failure
 *	    	    	if failed, bring down link and return
 *	    	    remember that we timed out
 *	    	    put magic number in buffer
 *	    	    send it as an echo request
 *	    	    set timer for waiting for a response
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_send_echo (lqm_t *lq)
{
    if (lq -> interval) {
	unsigned char buf[4], *outp = buf;  /* Big enough for Magic-# */

	if (lq -> k && lq -> n && lq -> timed_out) {
	    byte lqm_failed = lqm_set_lqr_status(lq, LQR_LOST);
	    DOLOG(char thresh[SHORT_STR_LEN];)
	    DOLOG(lqm_threshold(lq, thresh);)
	    LOG3(LOG_LQSTAT, (LOG_LQM_ECHO, thresh));

	    if (lqm_failed) {
		LOG3(LOG_BASE, (LOG_LQM_LOST_ECHO));
		lqm_failure(lq);
		return;
	    }
	}

	lq -> timed_out = 1;

	/*
	 * Send an Echo-Request.  The magic number is the only data.
	 * Pass NULL as buffer so fsm_sdata will alloc one for us.
	 */
	PUTLONG(lq -> magicnumber, outp);
	fsm_sdata(&lcp_fsm[lq -> unit], ECHO_REQUEST,
		  ++lcp_fsm[lq -> unit].id, buf, (PACKET *)NULL, (int)(outp - buf));

	/*
	 * Start timer.  Be sure to convert 100ths of a second to number
	 * of timer intervals.
	 */
	lq -> timer = (lq -> interval * (long)INTERVALS_PER_SEC) / 100L;
    }
}

#ifdef __HIGHC__
#pragma Code("LQMLQR");
#endif
#ifdef __BORLANDC__
#pragma codeseg LQMLQR
#endif
#ifdef __WATCOMC__
#pragma code_seg("LQMLQR")
#endif


/***********************************************************************
 *				lqm_send_lqr
 ***********************************************************************
 * SYNOPSIS:	Send a link quality report.
 * CALLED BY:	lqm_start
 *	    	lqm_input
 *	    	PPPHandleTimeout
 * RETURN:	nothing
 *
 * STRATEGY:	Alloc buffer for LQR
 *	    	If checking status and we're timed out waiting for an LQR
 *	    	    set status and note if failed
 *	    	    if failed, free packet and bring down LCP
 *	    	Remember that we timed out
 *	    	increment number of LQRs sent
 *	    	build LQR packet in buffer
 *	    	send the LQR (PPPSendPacket)
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
void lqm_send_lqr (lqm_t *lq)
{
    PACKET *p;
    unsigned char *outp;

    p = PACKET_ALLOC(LQR_BODY_SIZE);
    if (p == 0)	    	    /* no memory, oh well...*/
	return;
    outp = PACKET_DATA(p);

    if (lq -> k && lq -> n && lq -> timed_out) {
	DOLOG(char thresh[SHORT_STR_LEN];)
	byte lqm_failed = 0;

	lqm_failed = lqm_set_lqr_status(lq, LQR_LOST);

	DOLOG(lqm_threshold(lq, thresh);)
	LOG3(LOG_LQSTAT, (LOG_LQM_LQR, thresh));

	if (lqm_failed) {
	    LOG3(LOG_BASE, (LOG_LQM_LOST));
	    PACKET_FREE(p);
	    lqm_failure(lq);
	    return;
	}
    }

    /*
     * Remembered that we timed out waiting for an LQR.  Increment the
     * number of LQRs we sent.
     */
    lq -> timed_out = 1;
    ++lq -> OutLQRs;

    /*
     * Build the LQR packet in the buffer.  When sending PeerOut values,
     * include this LQR.
     */
    PUTLONG(lq -> magicnumber, outp);
    PUTLONG(lq -> lastlqr.PeerOutLQRs, outp);	/* LastOutLQRs */
    PUTLONG(lq -> lastlqr.PeerOutPackets, outp);/* LastOutPackets */
    PUTLONG(lq -> lastlqr.PeerOutOctets, outp);	/* LastOutOctets */
    PUTLONG(lq -> lastlqr.SaveInLQRs, outp);	/* PeerInLQRs */
    PUTLONG(lq -> lastlqr.SaveInPackets, outp);	/* PeerInPackets */
    PUTLONG(lq -> lastlqr.SaveInDiscards, outp);/* PeerInDiscards */
    PUTLONG(lq -> lastlqr.SaveInErrors, outp);	/* PeerInErrors */
    PUTLONG(lq -> lastlqr.SaveInOctets, outp);	/* PeerInOctets */
    PUTLONG(lq -> OutLQRs, outp);		/* PeerOutLQRs */
    PUTLONG(lq -> ifOutUniPackets +
	    lq -> ifOutNUniPackets + 1, outp);	/* PeerOutPackets */
    PUTLONG(lq -> ifOutOctets + 1 + HEADERLEN + /* PeerOutOctets */
	    LQR_BODY_SIZE + 2, outp);	    	/*  include 1 flag and FCS */

#ifdef LOGGING_ENABLED
    if (debug >= LOG_LQMSGS) {
	LOG3(LOG_LQMSGS, (LOG_LQM_SENDING));
	LOG3(LOG_LQMSGS, (LOG_LQM_MAGIC,
			 lq -> magicnumber,
			 lq -> lastlqr.PeerOutLQRs));
	LOG3(LOG_LQMSGS, (LOG_LQM_LAST_OUT,
			 lq -> lastlqr.PeerOutPackets,
			 lq -> lastlqr.PeerOutOctets));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_IN,
			 lq -> lastlqr.SaveInLQRs,
			 lq -> lastlqr.SaveInPackets));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_IN2,
			 lq -> lastlqr.SaveInDiscards,
			 lq -> lastlqr.SaveInErrors));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_IN3,
			 lq -> lastlqr.SaveInOctets,
			 lq -> OutLQRs));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_OUT,
			 lq -> ifOutUniPackets + lq -> ifOutNUniPackets + 1,
			 lq -> ifOutOctets + 1 + 4 + LQR_BODY_SIZE + 2));
    }
#endif /* LOGGING_ENABLED */

    /*
     * Send the LQR.
     */
    PPPSendPacket(lq -> unit, p, LQM);

    /*
     * Set timer for next one.  Interval is in 100ths of a second so we
     * have to convert it to number of timer intervals to get the right
     * time.
     */
    if (lq -> interval)
	lq -> timer = (lq -> interval * (long)INTERVALS_PER_SEC) / 100L;
}


/***********************************************************************
 *				lqm_input
 ***********************************************************************
 * SYNOPSIS:	Process a received Link-Quality-Report
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects idle time
 *
 * STRATEGY:	Get the contents of the LQR packet into a lqr structure.
 *	    	Increment count of received LQRs
 *	    	Set saved values in lqr by grabbing previous values
 *	    	If not doing LQR, reject the protocol and return.
 *	    	Free the LQR buffer.
 *	    	If using magic number, check for loopback or
 *	    	    incorrect magic number.  If different from negotiated
 *	    	    value, bring down the link and return.
 *	    	Update and check status of lqm
 *	    	if lost too many LQRs, bring down PPP link
 *	    	Save lqr struct as lastlqr and remember that we have
 *	    	    received LQRs
 *	    	Clear timed_out
 *	    	Send an LQR if needed
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/10/95		Initial Revision
 *
 ***********************************************************************/
unsigned char lqm_input (int unit,
			 PACKET *p,
			 int len)
{
    lqm_t *lq = &lqm[unit];
    lcp_options *ho = &lcp_heroptions[unit];
    unsigned char *ptr = PACKET_DATA(p);
    struct lqr lqr, *l = &lqr;
    byte send_lqr = lq -> interval ? 0 : 1;

    /*
     * Get the contents of the LQR packet.  Increment number of LQRs received.
     */
    GETLONG(l -> magicnumber, ptr);
    GETLONG(l -> LastOutLQRs, ptr);
    GETLONG(l -> LastOutPackets, ptr);
    GETLONG(l -> LastOutOctets, ptr);
    GETLONG(l -> PeerInLQRs, ptr);
    GETLONG(l -> PeerInPackets, ptr);
    GETLONG(l -> PeerInDiscards, ptr);
    GETLONG(l -> PeerInErrors, ptr);
    GETLONG(l -> PeerInOctets, ptr);
    GETLONG(l -> PeerOutLQRs, ptr);
    GETLONG(l -> PeerOutPackets, ptr);
    GETLONG(l -> PeerOutOctets, ptr);

    ++lq -> InLQRs;

    /*
     * Set saved values.
     */
    l -> SaveInLQRs = lq -> InLQRs;
    l -> SaveInPackets = lq -> ifInUniPackets + lq -> ifInNUniPackets;
    l -> SaveInDiscards = lq -> ifInDiscards;
    l -> SaveInErrors = lq -> ifInErrors;
    l -> SaveInOctets = lq -> InGoodOctets;

#ifdef LOGGING_ENABLED

    if (debug >= LOG_LQMSGS) {
	LOG3(LOG_LQMSGS, (LOG_LQM_RECVING));
	LOG3(LOG_LQMSGS, (LOG_LQM_MAGIC,
			 l -> magicnumber,
			 l -> LastOutLQRs));
	LOG3(LOG_LQMSGS, (LOG_LQM_LAST_OUT,
			 l -> LastOutPackets,
			 l -> LastOutOctets));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_IN,
			 l -> PeerInLQRs,
			 l -> PeerInPackets));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_IN2,
			 l -> PeerInDiscards,
			 l -> PeerInErrors));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_IN3,
			 l -> PeerInOctets,
			 l -> PeerOutLQRs));
	LOG3(LOG_LQMSGS, (LOG_LQM_PEER_OUT,
			 l -> PeerOutPackets,
			 l -> PeerOutOctets));
	LOG3(LOG_LQMSGS, (LOG_LQM_SAVE_IN,
			 l -> SaveInLQRs,
			 l -> SaveInPackets));
	LOG3(LOG_LQMSGS, (LOG_LQM_SAVE_IN2,
			 l -> SaveInDiscards,
			 l -> SaveInErrors));
	LOG3(LOG_LQMSGS, (LOG_LQM_SAVE_IN3,
			 l -> SaveInOctets));
    }
#endif /* LOGGING_ENABLED */

    /*
     * If not doing LQR, then reject LQR protocol.
     */
    if (lq -> running != LQ_LQR) {
	lcp_sprotrej(unit, p, len);
	return(0);
    }

    /*
     * Now that we got all the data, and we're not rejecting the
     * packet, we can free it.
     */
    PACKET_FREE(p);

    /*
     * Check magic number in packet is correct.
     */
    if (lq -> magicnumber)
	if (lq -> magicnumber == l -> magicnumber) {
	    LOG3(LOG_BASE, (LOG_LQM_WARN_LOOP));
	    return (0);
	}
    	else if (ho -> magicnumber != l -> magicnumber) {
	    LOG3(LOG_BASE, (LOG_LQM_PEER_CHANGED));
	    lqm_failure(lq);
	    return(0);
	}

    /*
     * Now process the received data and do computations.
     */
    if (lq -> received_lqrs) {
	long delta1, delta2, delta3;
	byte lqm_failed = 0;

	if (l -> PeerInLQRs) {
#ifdef LOGGING_ENABLED
	    char *pkt, pktbuf[50], *oct, octbuf[50], *ierr = "", ierrbuf[50],
	    	 *disc = "", discbuf[50], *lqr_string, lqrbuf[50];
	    int pktcnt, octcnt;
#endif /* LOGGING_ENABLED */

	    if (l -> PeerInLQRs == lq -> lastlqr.PeerInLQRs)
		send_lqr = 1;

#ifdef LOGGING_ENABLED
	    if (debug >= LOG_LQSTAT) {
		delta1 = l -> PeerOutPackets - lq -> lastlqr.PeerOutPackets;
		delta2 = l -> SaveInPackets - lq -> lastlqr.SaveInPackets;

		pktcnt = sprintf(pkt = pktbuf, "%lu", delta1);

		if (delta2 != delta1)
		    pktcnt += sprintf(&pkt[pktcnt], "(%lu)", delta2);

		pktcnt += sprintf(&pkt[pktcnt], "/");

		if (lq -> lastlqr.PeerInLQRs) {
		    delta1 = l -> LastOutPackets
			- lq -> lastlqr.LastOutPackets;
		    delta2 = l -> PeerInPackets
			- lq -> lastlqr.PeerInPackets;

		    pktcnt += sprintf(&pkt[pktcnt], "%lu", delta1);

		    if (delta2 != delta1)
			pktcnt += sprintf(&pkt[pktcnt], "(%lu)", delta2);
		}
	    }

	    delta1 = l -> PeerOutOctets - lq -> lastlqr.PeerOutOctets;
	    delta2 = l -> SaveInOctets - lq -> lastlqr.SaveInOctets;

	    if (delta1)
		rx_percent = (delta2 * 100L + (delta1 / 2L)) / delta1;

	    if (debug >= LOG_LQSTAT) {
		octcnt = sprintf(oct = octbuf, "%lu", delta1);

		if (delta2 != delta1)
		    octcnt += sprintf(&oct[octcnt], "(%lu)", delta2);

		octcnt += sprintf(&oct[octcnt], "/");
	    }

	    if (lq -> lastlqr.PeerInLQRs) {
		delta1 = l -> LastOutOctets - lq -> lastlqr.LastOutOctets;
		delta2 = l -> PeerInOctets - lq -> lastlqr.PeerInOctets;

		if (delta1)
		    tx_percent = (delta2 * 100L + (delta1 / 2L)) / delta1;

		if (debug >= LOG_LQSTAT) {
		   octcnt += sprintf(&oct[octcnt], "%lu", delta1);

		   if (delta2 != delta1)
		       octcnt += sprintf(&oct[octcnt], "(%lu)", delta2);
		}
	    }

	    sess_used_lqm = 1;
	    sess_tx_errors += l -> PeerInErrors - lq -> lastlqr.PeerInErrors;

	    if (debug >= LOG_LQSTAT) {
		delta1 = l -> SaveInErrors - lq -> lastlqr.SaveInErrors,
		delta2 = l -> PeerInErrors - lq -> lastlqr.PeerInErrors;

		if (delta1 || delta2)
		    sprintf(ierr = ierrbuf, " IErr: %lu/%lu", delta1, delta2);

		delta1 = l -> SaveInDiscards - lq -> lastlqr.SaveInDiscards,
		delta2 = l -> PeerInDiscards - lq -> lastlqr.PeerInDiscards;

		if (delta1 || delta2)
		    sprintf(disc = discbuf, " Disc: %lu/%lu", delta1, delta2);
	    }
#endif /* LOGGING_ENABLED */

	    if (lq -> k && lq -> n) {
		if (lq -> lastlqr.PeerInLQRs) {
		    delta1 = l -> LastOutLQRs - lq -> lastlqr.LastOutLQRs;
		    delta2 = l -> PeerInLQRs - lq -> lastlqr.PeerInLQRs;

		    if (delta2 != delta1)
			for (delta3 = delta1 - delta2; delta3 > 0; --delta3)
			    lqm_set_lqr_status(lq, LQR_LOST);
		}

		lqm_failed = lqm_set_lqr_status(lq, LQR_FOUND);

#ifdef LOGGING_ENABLED
		if (debug >= LOG_LQSTAT) {
		    char thresh[SHORT_STR_LEN];
		    lqm_threshold(lq, thresh);
		    sprintf(lqr_string = lqrbuf, " LQRs: %s", thresh);
		}
#endif /* LOGGING_ENABLED */
	    }

	    LOG3(LOG_LQSTAT, (LOG_LQM_PACKET,
			     pkt, oct, ierr, disc, lqr_string));

	    if (lqm_failed) {
		LOG3(LOG_BASE, (LOG_LQM_LOST));
		lqm_failure(lq);
		return(0);
	    }
	}
    }

    /*
     * Update some variables and send an LQR if needed.
     */
    lq -> lastlqr = lqr;
    lq -> received_lqrs = 1;
    lq -> timed_out = 0;

    if (send_lqr) {
	lqm_send_lqr(lq);
	lq -> timed_out = 0;    	/* lqm_send_lqr() sets timed_out */
    }

    return(0);	    	/* LQM packets don't count against the idle timer */

}  /* End Of lqm_input */
