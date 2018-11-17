/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ipcp.c
 *
 * AUTHOR:  	  Jennifer Wu: May  5, 1995
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	ipcp_init   	       
 *	ipcp_open
 *	ipcp_lowerup
 *	ipcp_lowerdown
 *
 *	ipcp_input  	    Process a received IPCP packet
 *	ipcp_protrej
 *
 *	ipcp_resetci	    Reset configuration information
 *	ipcp_cilen  	    Return size of our configuration information
 *	ipcp_addci  	    Add our configuration info to the packet
 *	ipcp_ackci  	    Process a received Configure-Ack
 *	ipcp_nakci  	    Process a received Configure-Nak
 *	ipcp_rejci  	    Process a received Configure-Reject
 *	ipcp_reqci  	    Process a received Configure-Request
 *
 *	ipcp_up	    	    IPCP has come UP
 *	ipcp_down   	    IPCP has gone DOWN
 *
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 5/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP IP Control Protocol code.
 *
 * 	$Id: ipcp.c,v 1.13 98/06/03 19:07:22 jwu Exp $
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

# include <ppp.h>

#ifdef __HIGHC__
# pragma Code("IPCPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg IPCPCODE
#endif

/*
 * 	Forward declarations
 */
void ipcp_resetci();		/* Reset our Configuration Information */
int ipcp_cilen();		/* Return length of our CI */
void ipcp_addci();		/* Add our CIs */
int ipcp_ackci();		/* Ack some CIs */
void ipcp_nakci();		/* Nak some CIs */
void ipcp_rejci();		/* Reject some CIs */
unsigned char ipcp_reqci();		/* Check the requested CIs */
void ipcp_up();			/* We're UP */
void ipcp_down();		/* We're DOWN */

/*
 * Variables for generating far pointers to the callback routines.
 */
static VoidCallback *ipcp_resetci_vfptr = ipcp_resetci;
static IntCallback *ipcp_cilen_vfptr = ipcp_cilen;
static VoidCallback *ipcp_addci_vfptr = ipcp_addci;
static IntCallback *ipcp_ackci_vfptr = ipcp_ackci;	
static VoidCallback *ipcp_nakci_vfptr = ipcp_nakci;	
static VoidCallback *ipcp_rejci_vfptr = ipcp_rejci;
static ByteCallback *ipcp_reqci_vfptr = ipcp_reqci;	
static VoidCallback *ipcp_up_vfptr = ipcp_up;
static VoidCallback *ipcp_down_vfptr = ipcp_down;	

fsm_callbacks ipcp_callbacks; 	/* IPCP callback routines */


/***********************************************************************
 *				ipcp_init
 ***********************************************************************
 * SYNOPSIS:	Initialize IPCP
 * CALLED BY:	PPPSetup using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	Initialize values in IPCP fsm, want optoins and allow 
 *	    	options.
 *
 * NOTES:   	Commented out lines initializing defaults to zero 
 *	    	because they are already zero (dgroup).  The lines
 *	    	now serve as comments.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
void ipcp_init (int unit)
{
    fsm *f = &ipcp_fsm[unit];
    ipcp_options *wo = &ipcp_wantoptions[unit];
    ipcp_options *ao = &ipcp_allowoptions[unit];

    /*
     * Fill callback structure.
     */
    ipcp_callbacks.resetci = ipcp_resetci_vfptr;
    ipcp_callbacks.cilen = ipcp_cilen_vfptr;
    ipcp_callbacks.addci = ipcp_addci_vfptr;
    ipcp_callbacks.ackci = ipcp_ackci_vfptr;
    ipcp_callbacks.nakci = ipcp_nakci_vfptr;
    ipcp_callbacks.rejci = ipcp_rejci_vfptr; 
    ipcp_callbacks.reqci = ipcp_reqci_vfptr;
    ipcp_callbacks.up = ipcp_up_vfptr;
    ipcp_callbacks.down = ipcp_down_vfptr;
    ipcp_callbacks.closed = ipcp_callbacks.protreject = 
	ipcp_callbacks.retransmit = ipcp_callbacks.echoreply = 
	    ipcp_callbacks.lqreport = (VoidCallback *)NULL;
    ipcp_callbacks.echorequest = (ByteCallback *)NULL;

#ifdef USE_CCP  
    ipcp_callbacks.resetrequest = ipcp_callbacks.resetack = (VoidCallback *)NULL;
#endif 

    /*
     * Initialize FSM defaults and maximums for IPCP.
     */
    f -> unit = unit;
    f -> protocol = IPCP;
    f -> timeouttime = DEFTIMEOUT;
    f -> max_configure = MAX_CONFIGURE;
    f -> max_terminate = MAX_TERMINATE;
    f -> max_failure = MAX_FAILURE;
    f -> max_rx_failure = MAX_RX_FAILURE;
/*  f -> tx_naks = 0;	    	*/
/*  f -> rx_naks = 0; 	    	*/
    f -> code_mask = 0xfe;		/* Configure-Request through */
					/* Code-Reject */
    f -> callbacks = &ipcp_callbacks;


    /*
     * Initialize want options.
     */
    wo -> ipcp_neg = (IN_NEG_ADDRS | IN_NEG_VJ);
    wo -> vj_maxslot = DEF_VJ_SLOTS - 1;
    wo -> vj_cid = 1;

#if 0
   wo -> ouraddr = 0;     	    
   wo -> heraddr = 0;     	    
   wo -> soft_ouraddr = 0; 	    
   wo -> soft_heraddr = 0;
   wo -> dns1 = 0;	    	    
   wo -> dns2 = 0;	    	    
#endif

    /*
     * Initialize options we are allowing the peer to negotiate.
     */
    ao -> ipcp_neg = (IN_NEG_ADDRS | IN_NEG_VJ);

    /*
     * Let the FSM intialize itself.
     */
    fsm_init(&ipcp_fsm[unit]);
}


/***********************************************************************
 *				ipcp_open
 ***********************************************************************
 * SYNOPSIS:	Bring IPCP to the OPEN state.
 * CALLED BY:	BeginNetworkPhase
 * RETURN:	nothing
 * STRATEGY:	FSM can handle it for us.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
void ipcp_open (int unit)
{
    fsm_open(&ipcp_fsm[unit]);
}


/***********************************************************************
 *				ipcp_lowerup
 ***********************************************************************
 * SYNOPSIS:	The lower layer is up.  (LCP has reached network phase.)
 * CALLED BY:	BeginNetworkPhase
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
void ipcp_lowerup (int unit)
{
    fsm_lowerup(&ipcp_fsm[unit]);
}


/***********************************************************************
 *				ipcp_lowerdown
 ***********************************************************************
 * SYNOPSIS:	The lower layer is down.  (LCP is leaving network phase.)
 * CALLED BY:	EndNetworkPhase
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
void ipcp_lowerdown (int unit)
{
    fsm_lowerdown(&ipcp_fsm[unit]);
}


/***********************************************************************
 *				ipcp_input
 ***********************************************************************
 * SYNOPSIS:	Receive an IPCP input packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet should affect idle timer
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
 byte ipcp_input (int unit,
		  PACKET *p,
		  int len)
{
    return (fsm_input(&ipcp_fsm[unit], p, len));

}


/***********************************************************************
 *				ipcp_protrej
 ***********************************************************************
 * SYNOPSIS:	Process a received Protocol-Reject for IPCP.
 * CALLED BY:	demuxprotrej using prottbl entries
 * RETURN:	nothing
 *
 * STRATEGY:	Simply pretend that LCP went down because we can't do
 *	    	anything if the peer does not understand IPCP.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
void ipcp_protrej (int unit)
{
    fsm_lowerdown(&ipcp_fsm[unit]);
}



/***********************************************************************
 *				ipcp_resetci
 ***********************************************************************
 * SYNOPSIS:	Reset our configuration information. (FSM callback)
 * CALLED BY:	fsm_open 
 * RETURN:	nothing
 *
 * STRATEGY:	Clear Nak counts and reset got options to desired
 *	    	options.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
void ipcp_resetci (fsm *f)
{
    int i;

    for (i = 0; i <= IPCP_MAXCI; i++)
	ipcp_wantoptions[f -> unit].rxnaks[i] = 0;

    ipcp_gotoptions[f -> unit] = ipcp_wantoptions[f -> unit];
}



/***********************************************************************
 *				ipcp_cilen
 ***********************************************************************
 * SYNOPSIS:	Return the size of our configuration information. 
 *	    	(FSM callback)
 * CALLED BY:	scr 	= Send Configure Request 
 * RETURN:	nothing
 *
 * STRATEGY:	If an option will be negotiated, include its length.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
int ipcp_cilen (fsm *f)
{
    ipcp_options *go = &ipcp_gotoptions[f -> unit];

    /*
     * If negotiating address, insert the proper length for new
     * or old style address option.  If negotiating MS-IPCP DNS 
     * addresses, add length for both secondary and primary DNS 
     * option.
     */
    return ((go -> ipcp_neg & IN_NEG_ADDRS ? 
	     (go -> ipcp_neg & IN_OLD_ADDRS ? CI_ADDRS_LEN : CI_ADDR_LEN) : 0)
	    + (go -> ipcp_neg & IN_NEG_VJ ? CI_VJ_COMP_LEN : 0)
	    + (go -> ipcp_neg & IN_MS_DNS1 ? CI_MS_DNS_LEN : 0)
	    + (go -> ipcp_neg & IN_MS_DNS2 ? CI_MS_DNS_LEN : 0));
}


/***********************************************************************
 *				ipcp_addci
 ***********************************************************************
 * SYNOPSIS:	Add our desired configuration information to the packet.
 *	    	(FSM callback)
 * CALLED BY:	scr 	= Send Configure Request 
 * RETURN:	nothing
 *
 * STRATEGY:	If negotiating address and doing old style, add old style
 *	    	option, else add new style option
 *	    	If negotiating vj compression, add the option
 *	    	If negotiating ms-ipcp dns extensions, add the options
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
void ipcp_addci (fsm *f,
		 unsigned char *ucp)	/* pointer to where info is added */
{
    ipcp_options *go = &ipcp_gotoptions[f -> unit];

    /*
     * If negotiating address, add option for old or new style address.
     */
    if (go -> ipcp_neg & IN_NEG_ADDRS) {
	
	if (go -> ipcp_neg & IN_OLD_ADDRS) {
	    PUTCHAR(CI_ADDRS, ucp);
	    PUTCHAR(CI_ADDRS_LEN, ucp);	    	/* insert option length */
	    PUTLONG(go -> ouraddr, ucp);
	    PUTLONG(go -> heraddr, ucp);

	    LOG3(LOG_NEG, (LOG_IPCP_SEND_ADDRS, 
			  BREAKDOWN_ADDR(go -> ouraddr), 
			  BREAKDOWN_ADDR(go -> heraddr)));

	}
	else {
	    PUTCHAR(CI_ADDR, ucp);
	    PUTCHAR(CI_ADDR_LEN, ucp);	    	/* insert option length */
	    PUTLONG(go -> ouraddr, ucp);
	    LOG3(LOG_NEG, (LOG_IPCP_SEND_ADDR,
			  BREAKDOWN_ADDR(go -> ouraddr)));
	}
    }

    /*
     * If negotiating VJ TCP header compression, add the option for it.
     */
    if (go -> ipcp_neg & IN_NEG_VJ) {
	
	PUTCHAR(CI_COMPRESSTYPE, ucp);
	PUTCHAR(CI_VJ_COMP_LEN, ucp);	    	    
	PUTSHORT(IP_VJ_COMP, ucp);	    /* insert compression type */
	LOG3(LOG_NEG, (LOG_IPCP_SEND_COMP));

	PUTCHAR(go -> vj_maxslot, ucp); 
	PUTCHAR(go -> vj_cid, ucp);
	LOG3(LOG_NEG, (LOG_IPCP_SLOTS,
 		      go -> vj_maxslot, go -> vj_cid));
    }

    /*
     * If negotiating MS-IPCP DNS options, add options for primary
     * and secondary DNS addresses.
     */
    if (go -> ipcp_neg & IN_MS_DNS1) {

	PUTCHAR(CI_MS_DNS1, ucp);
	PUTCHAR(CI_MS_DNS_LEN, ucp);
	PUTLONG(go -> dns1, ucp);

	LOG3(LOG_NEG, (LOG_IPCP_SEND_DNS,
		      BREAKDOWN_ADDR(go -> dns1)));

	if (go -> ipcp_neg & IN_MS_DNS2) {
	    PUTCHAR(CI_MS_DNS2, ucp);
	    PUTCHAR(CI_MS_DNS_LEN, ucp);
	    PUTLONG(go -> dns2, ucp);

	    LOG3(LOG_NEG, (LOG_IPCP_ADDR, BREAKDOWN_ADDR(go -> dns2)));
	}

	LOG3(LOG_NEG, (LOG_NEWLINE));
    }

}


/***********************************************************************
 *				ipcp_ackci
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Ack. (FSM callback)
 * CALLED BY:	fsm_input
 * RETURN:	0 if ack was bad
 *	    	1 if ack was good
 *
 * STRATEGY:	If negotiated address
 * 	    	    If old address, check packet length
 *	    	    	get option type and option length and verify
 *	    	    	get our address
 *	    	    	    if we have our own address, this must match
 *	    	    	    else use the recvd address
 *	    	    	get her address
 *	    	    	    do same as for our address
 *	    	    else (new style address), check packet length
 *	    	    	get option type and option length and verify
 *	    	    	get our address
 *	    	    	    same as above for addresses
 *	    	 If negotiated vj compression, check packet length
 *	    	    get option type and length and verify 
 *	    	    get compression protocol and verify
 *	    	    get maxslot and cid and verify
 *	    	If negotiated ms-ipcp dns, check packet length
 *	    	    get option type and length and verify
 *	    	    get primary dns address
 *	    	    	use the recvd address
 *	    	    get option type and length and verify
 *	    	    get secondary dns address
 *	    	    	use the recvd address
 *	    	If there is anything left in packet, then ack is bad.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
int ipcp_ackci (fsm *f,
		unsigned char *p,   	/* pointer to packet data */
		int len)    	    	/* length of packet data */
{
    ipcp_options *go = &ipcp_gotoptions[f -> unit];
    unsigned short cilen, citype, cishort;
    unsigned long cilong;
    unsigned char cichar;

    /* 
     * Configuration options must be in exactly the same order that
     * we sent or else packet is bad.  Code should process options in
     * same order as code that added the options to a Configure-Request.
     * Check packet length and option length at each step.  If we find
     * any deviation, then this packet is bad.
     */

    if (go -> ipcp_neg & IN_NEG_ADDRS) {
	/*
	 * If negotiating address, figure out old style or new style.
	 */
	if (go -> ipcp_neg & IN_OLD_ADDRS) {

	    if ((len -= CI_ADDRS_LEN) < 0)     /* adjusts remaining length */
		goto bad;

	    GETCHAR(citype, p);
	    GETCHAR(cilen, p);

	    if (cilen != CI_ADDRS_LEN || citype != CI_ADDRS)
		goto bad;

	    GETLONG(cilong, p);
	    if (go -> ouraddr) {
		if (go -> ouraddr != cilong)
		    goto bad;
	    }
	    else
		go -> ouraddr = cilong;

	    GETLONG(cilong, p);
	    if (go -> heraddr) {
		if (go -> heraddr != cilong)
		    goto bad;
	    }
	    else 
		go -> heraddr = cilong;
	}
	else {	    	/* new style IP Address option */
	    if ((len -= CI_ADDR_LEN) < 0)    /* adjusts remaining length */
		goto bad;

	    GETCHAR(citype, p);
	    GETCHAR(cilen, p);

	    if (cilen != CI_ADDR_LEN || citype != CI_ADDR)
		goto bad;

	    GETLONG(cilong, p);
	    if (go -> ouraddr) {
		if (go -> ouraddr != cilong)
		    goto bad;
	    }
	    else
		go -> ouraddr = cilong;
	}
    }

    /*
     * If doing VJ Tcp header compression, check ack for option is
     * exactly what we sent.
     */
    if (go -> ipcp_neg & IN_NEG_VJ) {
	
	if ((len -= CI_VJ_COMP_LEN) < 0)       /* adjusts remaining length */
	    goto bad;

	GETCHAR(citype, p);
	GETCHAR(cilen, p);

	if (cilen != CI_VJ_COMP_LEN || citype != CI_COMPRESSTYPE)
	    goto bad;

	/*
	 * Verify compression protocol, max slot and comp-id.
	 */
	GETSHORT(cishort, p);	    	    
	if (cishort != IP_VJ_COMP)
	    goto bad;
	
	GETCHAR(cichar, p);
	if (cichar != go -> vj_maxslot)
	    goto bad;

	GETCHAR(cichar, p);
	if (cichar != go -> vj_cid)
	    goto bad;
    }

    /*
     * If doing MS-IPCP DNS negotiation, check ack for DNS addresses
     * options.  
     */
    if (go -> ipcp_neg & IN_MS_DNS1) {

	if ((len -= CI_MS_DNS_LEN) < 0) 	/* adjusts remaining length */
	    goto bad;

	GETCHAR(citype, p);
	GETCHAR(cilen, p);

	if (cilen != CI_MS_DNS_LEN || citype != CI_MS_DNS1)
	    goto bad;

	GETLONG(cilong, p);
	go -> dns1 = cilong;

	if (go -> ipcp_neg & IN_MS_DNS2) {
	    
	    if ((len -= CI_MS_DNS_LEN) < 0)
		goto bad;

	    GETCHAR(citype, p);
	    GETCHAR(cilen, p);

	    if (cilen != CI_MS_DNS_LEN || citype != CI_MS_DNS2)
		goto bad;

	    GETLONG(cilong, p);
	    go -> dns2 = cilong;
	}
    }

    /*
     * If there are any remaining options in the packet, then this packet
     * is bad.
     */
    if (len != 0)
	goto bad;
    return (1);

bad:
    LOG3(LOG_NEG, (LOG_IPCP_BAD, "Ack"));
    return (0);    
}



/***********************************************************************
 *				ipcp_nakci
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Nak message. (FSM callback)
 * CALLED BY:	fsm_input 
 * RETURN:	nothing
 *
 * STRATEGY:	If received too many naks, close LCP  
 *	    	while there are options in the packet {
 *	    	    verify packet length and option length
 *	    	    switch on option type
 *	    	    	if allowing option to be negotiated, process it
 *	    	    	up nak count
 *	    	    	if too many naks, log warning else just log it
 *	    	If anything left, packet is bad
 *
 * NOTE:    Why bother processing packet if we're closing LCP? 
 *	    I don't get it...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
void ipcp_nakci (fsm *f,
		 unsigned char *p,  	/* pointer to packet data */
		 int len)   	    	/* length of packet data */
{
    ipcp_options *go = &ipcp_gotoptions[f -> unit];
    ipcp_options *ao = &ipcp_allowoptions[f -> unit];
    unsigned short ciproto;
    unsigned long ciaddr1, ciaddr2;

    /*
     * If too many naks, give up and close LCP.
     * Set generic error to reset.  Will be changed to link_open_failed
     * by api code if connection hasn't been established yet.
     */
    if (f -> rx_naks > f -> max_rx_failure) {
	link_error = SSDE_NEG_FAILED | SDE_CONNECTION_RESET;
	LOG3(LOG_BASE, (LOG_IPCP_GIVE_UP));
	lcp_close(0);
    }

    /*
     * Process options in Nak packet.
     */
    while (len > 0) {
	unsigned char *p1 = p + 2;  	    /* p1 points to option data  */
	int l = p[1];	    	    	    /* get option length */
	
	/*
	 * Verify there is enough data in the packet for the option
	 * and that the option length is reasonable.
	 */
	if (l > len || l < 2)
	    goto bad;

	/*
	 * Process option according to option type, if we're allowing
	 * an option to be negotiated.
	 */
	switch (p[0])
	    {
	    case CI_ADDRS:
		if (l == CI_ADDRS_LEN && ao -> ipcp_neg & IN_NEG_ADDRS) {
		    go -> ipcp_neg |= IN_NEG_ADDRS;
		    GETLONG(ciaddr1, p1);
		    GETLONG(ciaddr2, p1);

		    LOG3(LOG_NEG, 
			(LOG_IPCP_NAK_ADDRS,
			 BREAKDOWN_ADDR(ciaddr1), BREAKDOWN_ADDR(ciaddr2)));

		    /*
		     * If we didn't know our address or peer provided one, 
		     * and we're allowing ours to be overriden, use it.  
		     * Same for her address.
		     */
		    if (go -> ouraddr == 0 ||	/* Didn't we know our address? */
			(ciaddr1 && go -> soft_ouraddr))
		    	go -> ouraddr = ciaddr1;

		    if (go -> heraddr == 0 ||	/* Does she know hers? */
			(ciaddr2 && go -> soft_heraddr))
		    	go -> heraddr = ciaddr2;
		    
		    ++go -> rxnaks[CI_ADDRS];

#ifdef LOGGING_ENABLED		    	
		    if (go -> rxnaks[CI_ADDRS] % ipcp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_IPCP_NO_ADDRS));
			LOG3(LOG_BASE,
			    (LOG_IPCP_ADDRS_US,
			     BREAKDOWN_ADDR(go -> ouraddr),
			     BREAKDOWN_ADDR(go -> heraddr)));
			LOG3(LOG_BASE,
			    (LOG_IPCP_ADDRS_PEER,
			     BREAKDOWN_ADDR(ciaddr1),
			     BREAKDOWN_ADDR(ciaddr2)));
			negotiation_problem = "Negotiation failed";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_IPCP_NAK_ADDRS_SIMPLE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_ADDR:
		if (l == CI_ADDR_LEN && ao -> ipcp_neg & IN_NEG_ADDRS) {
		    go -> ipcp_neg |= IN_NEG_ADDRS;

		    GETLONG(ciaddr1, p1);
		    LOG3(LOG_NEG, (LOG_IPCP_NAK_ADDR));
		    LOG3(LOG_NEG,
			(LOG_IPCP_ADDR, BREAKDOWN_ADDR(ciaddr1)));
		    LOG3(LOG_NEG, (LOG_NEWLINE));

		    /*
		     * If we wanted an address assigned to us or if she
		     * provided one and we allow ours to be overridden, use it.
		     */
		    if (go -> ouraddr == 0 || 
			(ciaddr1 && go -> soft_ouraddr))
			go -> ouraddr = ciaddr1;
		    
		    ++go -> rxnaks[CI_ADDRS];

#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_ADDRS] % ipcp_warnnaks == 0) {
		    	LOG3(LOG_BASE, (LOG_IPCP_NO_ADDR));
			LOG3(LOG_BASE,
			    (LOG_IPCP_ADDRS_US,
			     BREAKDOWN_ADDR(go -> ouraddr),
			     BREAKDOWN_ADDR(go -> heraddr)));
			LOG3(LOG_BASE,
			    (LOG_IPCP_ADDR_PEER,
			     BREAKDOWN_ADDR(ciaddr1)));
			negotiation_problem = "Negotiation failed";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_IPCP_NAK_ADDR));
		    LOG3(LOG_NEG, (LOG_NEWLINE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_COMPRESSTYPE:
		if (l == CI_VJ_COMP_LEN && ao -> ipcp_neg & IN_NEG_VJ) {
		    unsigned char cimaxslot, cicid;

		    go -> ipcp_neg &= ~IN_NEG_VJ;
		    GETSHORT(ciproto, p1);
		    GETCHAR(cimaxslot, p1);
		    GETCHAR(cicid, p1);
		    LOG3(LOG_NEG, (LOG_IPCP_NAK_COMP, cimaxslot, cicid));
		    /*
		     * If compression protocol, max slot, comp-id all
		     * check out, then peer is suggesting we use these.
		     * Obey her.
		     */
		    if (ciproto == IP_VJ_COMP &&
			(cimaxslot & 0xff) >= MIN_VJ_SLOTS - 1 &&
			(cimaxslot & 0xff) <= MAX_VJ_SLOTS - 1 &&
			cicid <= 1) {
			go -> ipcp_neg |= IN_NEG_VJ;
			go -> vj_maxslot = cimaxslot;
			go -> vj_cid = cicid;
		    }

		    ++go -> rxnaks[CI_COMPRESSTYPE];
#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_COMPRESSTYPE] % ipcp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_IPCP_NO_COMP));
			negotiation_problem = "Negotiation failed";
		    }
#endif /* LOGGING_ENABLED */
		}
#ifdef LOGGING_ENABLED
		else {
		    LOG3(LOG_NEG, (LOG_IPCP_NAK_COMP_SIMPLE));
		}
#endif /* LOGGING_ENABLED */

		break;

	    case CI_MS_DNS1:
		if (l == CI_MS_DNS_LEN && ao -> ipcp_neg & IN_MS_DNS1) {
		    go -> ipcp_neg |= IN_MS_DNS1;
		    goto dnsCommon;
		}
	    	break;

	    case CI_MS_DNS2:
		if (l == CI_MS_DNS_LEN && ao -> ipcp_neg & IN_MS_DNS2) {
		    go -> ipcp_neg |= IN_MS_DNS2;
dnsCommon:
		    GETLONG(ciaddr1, p1);
		    LOG3(LOG_NEG, 
			(LOG_IPCP_NAK_DNS,
			 p[0] == CI_MS_DNS1 ? "primary" : "secondary"));
		    LOG3(LOG_NEG, 
			(LOG_IPCP_DNS_ADDR, BREAKDOWN_ADDR(ciaddr1)));
		    
		    if (ciaddr1)
			if (p[0] == CI_MS_DNS1)
			    go -> dns1 = ciaddr1;
		    	else
			    go -> dns2 = ciaddr1;
		}
		break;

	    default:
		LOG3(LOG_NEG, (LOG_IPCP_UNKNOWN_NAK, p[0]));
	    }

	/*
	 * Adjust remaining length and advance data pointer.
	 */
	len -= l;
	p += l;
    }

    /*
     * If there are remaining options, we don't understand those.
     */
    if (len == 0)
	return;

bad:
    LOG3(LOG_NEG, (LOG_IPCP_BAD, "Nak"));
}



/***********************************************************************
 *				ipcp_rejci
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Reject. (FSM callback)
 * CALLED BY:	fsm_input 
 * RETURN:	nothing
 *
 * STRATEGY:	If got options negotiating addresses and length is long enough
 *	    	if IP Addresses, verify rejected value.
 *	    	    if rejected addresses are okay, then remember
 *	    	    	that negotiating addresses failed.
 *	    	else if IP Address
 *	    	    if rejected address okay, try old style address negotiation
 *	    	if got options negotiating vj compression and len is okay
 *	    	    if rejected value is okay, remember no vj compression
 *	    	if got options for dns and len is okay, don't attempt
 *	    	    to negotiate ms-ipcp dns anymore
 *	    	if anything left, this packet is bad so log it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
void ipcp_rejci (fsm *f,
		 unsigned char *p,  	/* pointer to packet data */
		 int len)   	    	/* length of packet data */
{
    ipcp_options *go = &ipcp_gotoptions[f -> unit];
    unsigned short cishort;
    unsigned long cilong;
    unsigned char cichar;

    /* 
     * Any rejected configuration options must be in exactly the same 
     * order that we sent.  Check packet length and option length at 
     * each step.  If we find any deviations, then this packet is bad.
     */

    /*
     * If negotiating addresses, the first option must be CI_ADDRS
     * or CI_ADDR.  Only one may be present in a configuration packet.  
     */
    if (go -> ipcp_neg & IN_NEG_ADDRS && len >= CI_ADDR_LEN) {
	/*
         * Check if IP Addresses option is being rejected. 
	 */
	if (len >= CI_ADDRS_LEN &&     	/* buffer length okay? */
	    p[1] == CI_ADDRS_LEN &&    	/* option length okay? */
	    p[0] == CI_ADDRS) {	    	/* option type okay? */
	    
	    len -= CI_ADDRS_LEN;	/* adjust remaining length */
	    INCPTR(2, p);   	    	/* advance ptr past type and length */
	    GETLONG(cilong, p);

	    LOG3(LOG_NEG, (LOG_IPCP_REJ_ADDRS));

	    /* Check rejected value */
	    if (cilong != go -> ouraddr) {
		LOG3(LOG_NEG,
		    (LOG_IPCP_WRONG_ADDR, "Source-",
		     BREAKDOWN_ADDR(cilong), BREAKDOWN_ADDR(go -> ouraddr)));
		goto bad;
	    }		

	    GETLONG(cilong, p);
	    if (cilong != go -> heraddr) {
		LOG3(LOG_NEG,
		    (LOG_IPCP_WRONG_ADDR, "Destination-",
		     BREAKDOWN_ADDR(cilong), BREAKDOWN_ADDR(go -> heraddr)));
		goto bad;
	    }

	    go -> ipcp_neg &= ~IN_NEG_ADDRS;
	}
	/*
	 * Check if IP Address option is being rejected.
	 */
	else if (len >= CI_ADDR_LEN && p[1] == CI_ADDR_LEN 
		 && p[0] == CI_ADDR) {
	    len -= CI_ADDR_LEN;	    /* adjust remaining length */
	    INCPTR(2, p);   	    /* advance ptr past length and type */
	    GETLONG(cilong, p);

	    LOG3(LOG_NEG, (LOG_IPCP_REJ_ADDR));

	    /* Check rejected value. */
	    if (cilong != go -> ouraddr) {
		LOG3(LOG_NEG,
		    (LOG_IPCP_WRONG_ADDR, "",
		     BREAKDOWN_ADDR(cilong), BREAKDOWN_ADDR(go -> ouraddr)));
		goto bad;
	    }
	    
	    /*
	     * Try the old style of address negotiation.
	     */
	    LOG3(LOG_NEG, (LOG_IPCP_REVERTING));
	    go -> ipcp_neg |= IN_OLD_ADDRS;
	}
    }

    /*
     * Process rejection of VJ compression.
     */
    if (go -> ipcp_neg & IN_NEG_VJ && 
	len >= CI_VJ_COMP_LEN && p[1] == CI_VJ_COMP_LEN 
	&& p[0] == CI_COMPRESSTYPE) {

	len -= CI_VJ_COMP_LEN; 	    /* adjust remaining length */
	INCPTR(2, p);	    	    /* advance ptr past length and type */
	GETSHORT(cishort, p);

	LOG3(LOG_NEG, (LOG_IPCP_REJ_COMP));

	/* Check rejected protocol value. */
	if (cishort != IP_VJ_COMP) {
	    LOG3(LOG_NEG, (LOG_IPCP_WRONG_COMP_TYPE, cishort));
	    goto bad;
	}
	
	/* Check maxslot and comp-id. */
	GETCHAR(cichar, p);
	if (cichar != go -> vj_maxslot) {
	    LOG3(LOG_NEG, (LOG_IPCP_WRONG_SLOT, "Max",
			   cichar, go -> vj_maxslot));
	    goto bad;
	}

	GETCHAR(cichar, p);
	if (cichar != go -> vj_cid) {
	    LOG3(LOG_NEG, (LOG_IPCP_WRONG_SLOT, "Comp",
			   cichar, go -> vj_cid));
	    goto bad;
	}
	
	go -> ipcp_neg &= ~IN_NEG_VJ;
    }

    /*
     * Process rejection of MS-IPCP DNS negotiations.
     */
    if (go -> ipcp_neg & IN_MS_DNS1 && len >= CI_MS_DNS_LEN &&
	p[1] == CI_MS_DNS_LEN && p[0] == CI_MS_DNS1) {

	len -= CI_MS_DNS_LEN;
	INCPTR(2, p);	    	/* advance past length and type */
	GETLONG(cilong, p);

	LOG3(LOG_NEG, (LOG_IPCP_REJ_DNS, "primary"));

	if (cilong != go -> dns1) {
	    LOG3(LOG_NEG, 
		(LOG_IPCP_WRONG_ADDR, "DNS ",
		 BREAKDOWN_ADDR(cilong), BREAKDOWN_ADDR(go -> dns1)));
	    goto bad;
	}
	
	go -> ipcp_neg &= ~IN_MS_DNS1;
    }

    if (go -> ipcp_neg & IN_MS_DNS2 && len >= CI_MS_DNS_LEN &&
	p[1] == CI_MS_DNS_LEN && p[0] == CI_MS_DNS2) {

	len -= CI_MS_DNS_LEN;
	INCPTR(2, p);	    	/* advance past length and type */
	GETLONG(cilong, p);

	LOG3(LOG_NEG, (LOG_IPCP_REJ_DNS, "secondary"));

	if (cilong != go -> dns2) {
	    LOG3(LOG_NEG, 
		(LOG_IPCP_WRONG_ADDR, "DNS ",
		 BREAKDOWN_ADDR(cilong), BREAKDOWN_ADDR(go -> dns2)));
	    goto bad;
	}

	go -> ipcp_neg &= ~IN_MS_DNS2;
    }

    /* 
     * If there are any remaining CIs, then this packet is bad.
     */
    if (len == 0)
	return;
bad:
	LOG3(LOG_NEG, (LOG_IPCP_BAD, "Reject"));
}




/***********************************************************************
 *				ipcp_reqci
 ***********************************************************************
 * SYNOPSIS:	Check the peer's requested configuration information 
 *	    	and send appropriate response. (FSM callback)
 * CALLED BY:	fsm_input 
 * RETURN:	0 if no response should be sent, else
 *	    	CONFIGURE_ACK, CONFIGURE_NAK or CONFIGURE_REJECT
 *
 * SIDE EFFECTS: Packet is modified to contain the appropriate response.
 *
 * STRATEGY:	Reset all her options.
 *	    	Process each option according to type, checking packet
 *	    	length and option length each time.
 *	    	Remember if peer is negotiating address or not.
 *	    	After processing all options, send a Nak if we need
 * 	    	options that weren't sent and we're not rejecting
 *	    	this packet.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	9/21/95	    	Added MS-IPCP DNS extensions
 *
 ***********************************************************************/
unsigned char ipcp_reqci (fsm *f,
			  unsigned char *inp,	/* Requested options */
			  int *len) 	    	/* Length of options */
{
    ipcp_options *wo = &ipcp_wantoptions[f -> unit];
    ipcp_options *ho = &ipcp_heroptions[f -> unit];
    ipcp_options *go = &ipcp_gotoptions[f -> unit];
    ipcp_options *ao = &ipcp_allowoptions[f -> unit];

    unsigned char *cip;	    	    	/* Pointer to current option */
    unsigned short cilen, citype;   	/* Parsed option length and type */
    unsigned short cishort;		/* Parsed short value */
    unsigned long ciaddr1, ciaddr2; 	/* Parsed address values */    
    unsigned long heraddr, ouraddr;

    int rc = CONFIGURE_ACK; 	    	/* Final packet return code. */
    int orc;	    	    	    	/* Individual option result code */

    unsigned char *p = inp;		/* Pointer to next char to parse */
    unsigned char *ucp = inp;		/* Pointer to current output char */
    
    int l = *len;			/* Length left */
    unsigned char maxslot, cid;
    int not_converging = f -> tx_naks >= f -> max_failure;
    unsigned char saw_address = 0;     	/* Recvd address option? */

#ifdef LOGGING_ENABLED
    /* 
     * Log a warning if configure-request does not contain any options.
     */
    if (l == 0) {
	LOG3(LOG_NEG, (LOG_IPCP_EMPTY));
    }
#endif /* LOGGING_ENABLED */

    /*
     * Reset all her options.
     */
    ho -> ipcp_neg = ho -> ouraddr = ho -> heraddr = 0;

    /*
     * Process requested options.
     */
    while (l) {
	orc = CONFIGURE_ACK;	    	/* Assume success */
	cip = p;    	    	    	/* Remember beginning of this option */
	
	if (l < 2 ||	    	    	/* Not enough data for option hdr or */
	    p[1] < 2 ||	    	    	/* option length too small */
	    (p[1] & 0xff) > l) {	/* option length too big? */
	    LOG3(LOG_NEG, (LOG_IPCP_BAD, "Request (bad option length)"));
	    return (0);	    	    	/* no reply should be sent */
	}

	GETCHAR(citype, p); 	    	/* Parse option type */
	GETCHAR(cilen, p);  	    	/* Parse option length */
	l -= cilen; 	    	    	/* Adjust remaining length */
	cilen -= 2; 	    	    	/* Adjust cilen to just data */

	/*
	 * Process option according to type.
	 */
	switch (citype)     	    	
	    {
	    case CI_ADDRS:
		LOG3(LOG_NEG, (LOG_IPCP_RECV_ADDRS));
		saw_address = 1;

		/*
		 * Check if option is allowed and verify length.
		 */
		if ((ao -> ipcp_neg & IN_NEG_ADDRS) == 0 ||
		    cilen != 8) {
		    INCPTR(cilen, p);	        /* skip rest of option */
		    orc = CONFIGURE_REJECT; 
		    break;
		}

		/*
		 * Parse source addr (hers) and destination addr (ours).
		 */
		GETLONG(ciaddr1, p);	
		heraddr = ciaddr1;
		GETLONG(ciaddr2, p);	    	
		ouraddr = ciaddr2;

		LOG3(LOG_NEG, (LOG_IPCP_ADDRS,
			      BREAKDOWN_ADDR(heraddr),
			      BREAKDOWN_ADDR(ouraddr)));

		/*
		 * If we want to negotiate addresses, suggest what we
		 * want her address to be if she doesn't know her own
		 * address or we are forcing her to use an address of 
		 * our choosing.
		 */
		if (wo -> ipcp_neg & IN_NEG_ADDRS && 	
		    go -> heraddr &&	    	      
		    heraddr != go -> heraddr &&	      
		    (! wo -> soft_heraddr || heraddr == 0)) {  

		    heraddr = go -> heraddr;
		    
		    if (not_converging)
			orc = CONFIGURE_REJECT;
		    else
			orc = CONFIGURE_NAK;
		}

		/*
		 * If we want to negotiate address and we know what our
		 * address should be but she's using a different one,
		 * suggest our address.
		 */
		if (wo -> ipcp_neg & IN_NEG_ADDRS && go -> ouraddr &&
		    ouraddr != go -> ouraddr) {
		    ouraddr = go -> ouraddr;

		    if (orc != CONFIGURE_REJECT)
			if (not_converging)
			    orc = CONFIGURE_REJECT;
		    	else
			    orc = CONFIGURE_NAK;
		}

		/*
		 * If nak-ing, put our suggestions for addresses in the 
		 * packet.  If ack-ing, remember negotiated addresses.
		 */
		if (orc == CONFIGURE_NAK) {
		    DECPTR(8, p);   	/* back up pointer to start of addrs */
		    PUTLONG(heraddr, p);
		    PUTLONG(ouraddr, p);
		}
		else if (orc == CONFIGURE_ACK) {
		    ho -> ipcp_neg |= IN_NEG_ADDRS;
		    ho -> heraddr = ciaddr1;
		    ho -> ouraddr = ciaddr2;
		}

		else {
		    link_error = SSDE_NEG_FAILED;
		    LOG3(LOG_BASE, (LOG_IPCP_GIVE_UP_ADDR));
		    LOG3(LOG_BASE,
			(LOG_IPCP_ADDRS_US,
			 BREAKDOWN_ADDR(ouraddr), BREAKDOWN_ADDR(heraddr)));
		    LOG3(LOG_BASE,
			(LOG_IPCP_ADDRS_PEER,
			 BREAKDOWN_ADDR(ciaddr1), BREAKDOWN_ADDR(ciaddr2)));
		    DOLOG(negotiation_problem = "Negotiation failed";)
		}

		break;

	    case CI_COMPRESSTYPE:
	       LOG3(LOG_NEG, (LOG_IPCP_RECV_COMP));

		/*
		 * If option length is too small, reject option.    
		 */
		if (cilen < 2) {
		    LOG3(LOG_NEG, (LOG_IPCP_TOO_SHORT, 2 + cilen)); 
		    INCPTR(cilen, p);
		    orc = CONFIGURE_REJECT;
		    break;
		}

		GETSHORT(cishort, p);
		LOG3(LOG_NEG, (LOG_FORMAT_HEX, cishort));

		/*
		 * If not allowing vj negotiation or option length is wrong,
		 * reject option.
		 */
		if ((ao -> ipcp_neg & IN_NEG_VJ) == 0 ||
		    cilen != 4) {
		    INCPTR(cilen - 2, p);   	/* skip rest of option */
		    orc = CONFIGURE_REJECT;
		    break;
		}

		/*
		 * Compression protocol must be IP VJ Compression.
		 * If it's not and we're still converging, suggest it.
		 */
		if (cishort != IP_VJ_COMP) 
		    if (not_converging) {
			orc = CONFIGURE_REJECT;
			INCPTR(cilen - 2, p);

			link_error = SSDE_NEG_FAILED;

			LOG3(LOG_BASE, (LOG_IPCP_GIVE_UP_COMP));
			DOLOG(negotiation_problem = "Negotiation failed";)

		    }
		    else {
			DECPTR(2, p);	    	/* make room for protocol */
			orc = CONFIGURE_NAK;
			PUTSHORT(IP_VJ_COMP, p);
			PUTCHAR(wo -> vj_maxslot, p);
			PUTCHAR(wo -> vj_cid, p);
		    }
		else {
		    /*
		     * Check maxslot and comp-id.  If okay, accept.
		     */
		    ho -> ipcp_neg |= IN_NEG_VJ;

		    GETCHAR(maxslot, p);
		    LOG3(LOG_NEG, (LOG_IPCP_SLOT_ID, "Max", maxslot));

		    /*
		     * If maxslot is too big and we're still converging, 
		     * suggest our maximum.  
		     */
		    if ((maxslot & 0xff) > MAX_VJ_SLOTS - 1) 
			if (not_converging) {
			    orc = CONFIGURE_REJECT;
			    INCPTR(1, p);   	/* skip rest of option */

			    link_error = SSDE_NEG_FAILED;
			       
			    LOG3(LOG_BASE, (LOG_IPCP_GIVE_UP_COMP));
			    DOLOG(negotiation_problem = "Negotiation failed";)

			}
		    	else {
			    DECPTR(1, p);   	/* make room for maxslot */
			    orc = CONFIGURE_NAK;
			    PUTCHAR(MAX_VJ_SLOTS - 1, p);
			    INCPTR(1, p);
			}
		    else if ((maxslot & 0xff) < MIN_VJ_SLOTS - 1)
			/*
			 * If maxslot is too small and we're still 
			 * converging, suggest our minimum. 
			 */
			if (not_converging) {
			    orc = CONFIGURE_REJECT;
			    INCPTR(1, p);   	    /* skip rest of option */

			    link_error = SSDE_NEG_FAILED;

			    LOG3(LOG_BASE, (LOG_IPCP_GIVE_UP_COMP));
			     DOLOG(negotiation_problem = "Negotiation failed";)

			}
		    	else {
			    DECPTR(1, p);   	    /* make room for maxslot */
			    orc = CONFIGURE_NAK;
			    PUTCHAR(MIN_VJ_SLOTS - 1, p);
			    INCPTR(1, p);
			}
		    else {
			/*
			 * Remember maxslot and check comp-id.
			 */
			ho -> vj_maxslot = maxslot;

			GETCHAR(cid, p);
			LOG3(LOG_NEG, (LOG_IPCP_SLOT_ID, "Comp", cid));

			if (cid > 1) 
			    if (not_converging) {
				orc = CONFIGURE_REJECT;

				link_error = SSDE_NEG_FAILED;
				   
				LOG3(LOG_BASE, (LOG_IPCP_GIVE_UP_COMP));
			     DOLOG(negotiation_problem = "Negotiation failed";)
			    }
			    else {
				/* Suggest comp-id. */
				DECPTR(1, p);
				orc = CONFIGURE_NAK;
				PUTCHAR(wo -> vj_cid, p);
			    }
			else 
			    ho -> vj_cid = cid;
		    }
		}

		break;

	    case CI_ADDR:
		LOG3(LOG_NEG, (LOG_IPCP_RECV_ADDR));
		saw_address = 1;
		
		/*
		 * If not allowing address negotiation or the option
		 * length is too short, reject the option.
		 */
		if ((ao -> ipcp_neg & IN_NEG_ADDRS) == 0 ||
		    cilen != 4) {
		    INCPTR(cilen, p);	    /* skip reset of option */
		    orc = CONFIGURE_REJECT;
		    break;
		}

		/*
		 * If negotiating her address and she had one but it 
		 * now differs and we're forcing her to use our choice 
		 * of address, or she doesn't know her address, Nak it 
		 * with our idea.   Else, let her use her address.
		 */
		GETLONG(heraddr, p);
		LOG3(LOG_NEG, (LOG_IPCP_ADDR, BREAKDOWN_ADDR(heraddr)));
		LOG3(LOG_NEG, (LOG_COLON));

		if (wo -> ipcp_neg & IN_NEG_ADDRS &&
		    go -> heraddr &&	    	    	
		    heraddr != wo -> heraddr &&	
		    (! wo -> soft_heraddr || heraddr == 0)) {
		    if (not_converging) {
			orc = CONFIGURE_REJECT;

			link_error = SSDE_NEG_FAILED;

			LOG3(LOG_BASE,
			    (LOG_IPCP_GIVE_UP_ADDR_NEW,
			     BREAKDOWN_ADDR(wo -> ouraddr),
			     BREAKDOWN_ADDR((wo -> ipcp_neg & IN_NEG_ADDRS) ?
					    wo -> heraddr : 0L)));
			LOG3(LOG_BASE,
			    (LOG_IPCP_ADDR_PEER2, 
			     BREAKDOWN_ADDR(heraddr)));
			DOLOG(negotiation_problem = "Negotiation failed";)
		    }
		    else {
			orc = CONFIGURE_NAK;
			DECPTR(4, p);
			PUTLONG(wo -> heraddr, p);
		    }
		
		}
		else {
		    ho -> ipcp_neg |= IN_NEG_ADDRS;
		    ho -> heraddr = heraddr;
		}

		break;

	    case CI_MS_DNS1:
	    case CI_MS_DNS2:
		LOG3(LOG_NEG, (LOG_IPCP_RECV_DNS,
			      citype == CI_MS_DNS1 ? "primary" : "secondary"));
		
		if ((citype == CI_MS_DNS1 && !(ao -> ipcp_neg & IN_MS_DNS1)) ||
		    (citype == CI_MS_DNS2 && !(ao -> ipcp_neg & IN_MS_DNS2)) ||
		    cilen != 4) {

		    INCPTR(cilen, p);	    /* skip rest of option */
		    orc = CONFIGURE_REJECT;
		    break;
		}

		GETLONG(ciaddr1, p);
		LOG3(LOG_NEG, (LOG_IPCP_ADDR, BREAKDOWN_ADDR(ciaddr1)));
		    /*
		     * If zero, nak with zero DNS address because we 
		     * don't have any to assign.
		     */
		if (ciaddr1 == 0) {
		    DECPTR(4, p);
		    orc = CONFIGURE_NAK;
		}

		break;

	    default:
		LOG3(LOG_NEG, (LOG_IPCP_UNKNOWN_OPT, citype));   
		INCPTR(cilen, p);
		orc = CONFIGURE_REJECT;
		break;
	    }

	cilen += 2; 	    	/* adjust cilen to include entire option */

	LOG3(LOG_NEG, (LOG_NEWLINE_STRING, orc == CONFIGURE_ACK ? "Ack" :
		      	    	 (orc == CONFIGURE_NAK ? "Nak" : "Rej")));

	/*
	 * If the option is good and prior option wasn't, go on.
	 */
	if (orc == CONFIGURE_ACK && rc != CONFIGURE_ACK)
	    continue;

	/*
	 * If naking option and rejecting prior option, go on.  Else
	 * if acking all prior options, back up pointer for where
	 * to copy the option to start of input packet.
	 */
	if (orc == CONFIGURE_NAK) {
	    if (rc == CONFIGURE_REJECT)
		continue;
	    if (rc == CONFIGURE_ACK) {
		rc = CONFIGURE_NAK;
		ucp = inp;
	    }
	}

	/*
	 * If rejecting this option but not prior ones, then backup
	 * pointer for where to copy the option to the start of the
	 * input packet.
	 */
	if (orc == CONFIGURE_REJECT && rc != CONFIGURE_REJECT) {
	    rc = CONFIGURE_REJECT;
	    ucp = inp;
	}

	/*
	 * Copy option to new place in packet if this option 
	 * needs to be moved.  Use memmove because there's a 
	 * change of overlap.
	 */
	if (ucp != cip) 
	    memmove (ucp, cip, cilen);

	INCPTR(cilen, ucp); 	    	/* update output pointer */
	    
    }

    /*
     * Send a Nak if we need configuration options that weren't sent
     * by peer.
     *
     * If we need to know her address and she didn't give us one, add
     * the address option and  nak the packet, unless we're already
     * rejecting it.
     */
    if (rc != CONFIGURE_REJECT && ! saw_address &&
	go -> ipcp_neg & IN_NEG_ADDRS && ! not_converging)
	if (go -> ipcp_neg & IN_OLD_ADDRS) {
	    /*
	     * If we know both addresses, include them.
	     */
	    if (go -> heraddr && go -> ouraddr) {
		/*
		 * If previously acking, then this will be the only  option
		 * in the Nak packet, so back up the output pointer.
		 */
		if (rc == CONFIGURE_ACK)
		    ucp = inp;

		LOG3(LOG_NEG, (LOG_IPCP_ADD_NAK_ADDRS,
			      BREAKDOWN_ADDR(go -> heraddr),
			      BREAKDOWN_ADDR(go -> ouraddr)));

		rc = CONFIGURE_NAK;
		PUTCHAR(CI_ADDRS, ucp);
		PUTCHAR(CI_ADDRS_LEN, ucp);   	    /* adding option length */
		PUTLONG(go -> heraddr, ucp);
		PUTLONG(go -> ouraddr, ucp);
	    }
	}
	else if (go -> heraddr) {
	    /*
	     * If we know her address, send it using new style address option.
	     */
	    if (rc == CONFIGURE_ACK)
		ucp = inp;

	  LOG3(LOG_NEG, (LOG_IPCP_ADD_NAK_ADDR,
			BREAKDOWN_ADDR(go -> heraddr)));

	    rc = CONFIGURE_NAK;
	    PUTCHAR(CI_ADDR, ucp);
	    PUTCHAR(CI_ADDR_LEN, ucp);	    	    /* adding option length */
	    PUTLONG(go -> heraddr, ucp);
	}

    /*
     * Compute output length (length of reply packet).  Return
     * final result code.
     */
    *len = ucp - inp;	    	    

    LOG3(LOG_NEG,
	(LOG_IPCP_REPLY,
	 rc == CONFIGURE_ACK ? "Configure-Ack" :
	 (rc == CONFIGURE_NAK ? "Configure-Nak" : "Configure-Reject")));

    return (rc);    	
}    	


/***********************************************************************
 *				ipcp_up
 ***********************************************************************
 * SYNOPSIS:	IPCP has come UP.  (FSM callback)
 * CALLED BY:	tlu 	= This Layer Up 
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY: 	Set vj compression options for interface and initialize
 *	    	vj compression.
 *
 * NOTES:
 * 	    PPP protocol does not require address to be
 * 	    negotiated before allowing link to open, thus we need
 * 	    to check if we have a local address because we cannot do 
 * 	    anything useful without one.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *	jwu 	3/20/96	    	Check for zero local address 
 *
 ***********************************************************************/
void ipcp_up (fsm *f)
{
    ipcp_options *go = &ipcp_gotoptions[f -> unit],
		 *ho = &ipcp_heroptions[f -> unit];


    if (go -> ipcp_neg & IN_NEG_ADDRS) {
	/*
	 * Initialize VJ compression.
	 */
	SetVJCompression(f -> unit,
		     go -> ipcp_neg & IN_NEG_VJ ? go -> vj_maxslot + 1 : 0,
		     go -> ipcp_neg & IN_NEG_VJ ? ho -> vj_maxslot + 1 : 0,
		     ho -> vj_cid);

	LOG3(LOG_IF, (LOG_UP));
	DOLOG(log_state("up");)

        /*
	 * Tell TCP/IP client the link is open if we haven't done
	 * so already.
	 */
	if (! ip_connected) {
	    PPPLinkOpened();
	    ip_connected = 1;
	}

	link_error = SDE_NO_ERROR;

#ifdef LOGGING_ENABLED
	LOG3(LOG_BASE, (LOG_CONNECTED));
    
	sess_start = TimerGetCount();
	sess_rx_octets = lqm[0].InGoodOctets;
	sess_tx_octets = lqm[0].ifOutOctets;
	sess_rx_packets = lqm[0].ifInUniPackets;
	sess_tx_packets = lqm[0].ifOutUniPackets;
	sess_rx_errors = lqm[0].ifInErrors;
	sess_tx_errors = 0;
	sess_used_lqm = 0;
    
	negotiation_problem = (char *)0;
	rate_timer = RATE_TIMEOUT;
#endif /* LOGGING_ENABLED */    
    }
    else {
	/*
	 * If we did not successfully negotiate a local address, 
	 * negotiation failed.  Close the link. 
	 */
	link_error = SSDE_NEG_FAILED | SDE_CONNECTION_RESET;
	lcp_close(f -> unit);
    }

}


/***********************************************************************
 *				ipcp_down
 ***********************************************************************
 * SYNOPSIS:	IPCP has gone DOWN. (FSM callback)
 * CALLED BY:	tld 	= This Layer Down 
 * RETURN:	nothing
 *
 * STRATEGY: 	do nothing
 *	
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 5/95		Initial Revision
 *
 ***********************************************************************/
void ipcp_down (fsm *f)
{

}






