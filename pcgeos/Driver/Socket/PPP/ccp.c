/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ccp.c
 *
 * AUTHOR:  	  Jennifer Wu: Aug 20, 1996
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 *	ccp_select_comp_type	Choose a compression type to negotiate.
 *
 *	ccp_init    	    
 *	ccp_open    	    Open CCP.
 *	ccp_close   	    Close CCP.
 *
 *	ccp_lowerup 	    LCP is up.
 *	ccp_lowerdown	    LCP is down.
 *
 *	ccp_input   	    Process received CCP packet.
 *	ccp_protrej 	    Process a received protocol reject for CCP.
 *
 *	ccp_resetopt	    Reset our CCP options.
 *	ccp_optlen  	    Return length of our options.
 *	ccp_addopts 	    Add our desired options to a packet.
 * 	ccp_ackopts 	    Process a received Configure-Ack.
 *	ccp_nakopts 	    Process a received Configure-Nak.
 *	ccp_rejopts 	    Process a received Configure-Reject.
 *	ccp_reqopts 	    Process a received Configure-Request.
 *
 *	ccp_up	    	    CCP has come UP.
 *	ccp_down    	    CCP has gone DOWN.
 *
 *	ccp_resettimeout    Process timeout for a Reset-Request.
 *	ccp_resetrequest    Process a received Reset-Request.
 *	ccp_resetack	    Process a received Reset-Ack.
 *	ccp_reset   	    Reset our decompressor and peer's compressor.
 *
 *	compress_input	    Process a received compressed packet.
 * 
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/20/96	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP Compression Control Protocol.
 *
 *	Ported from MorningStar code, but much has been changed, 
 *	especially anything to do with Stac LZS negotiation.
 *
 * 	$Id: ccp.c,v 1.10 98/06/03 19:08:15 jwu Exp $
 *
 ***********************************************************************/

#ifdef USE_CCP

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>

#ifdef __HIGHC__
#pragma Code("CCPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg CCPCODE
#endif


extern void lcp_sprotrej();

/*
 * Forward declarations.
 */
void ccp_resetopt();		/* Reset our Configuration Information */
int ccp_optlen();		/* Return length of our options */
void ccp_addopts();		/* Add our options */
int ccp_ackopts();		/* Ack some options */
void ccp_nakopts();		/* Nak some options */
void ccp_rejopts();		/* Reject some options */
unsigned char ccp_reqopts();	/* Check the requested options */
void ccp_up();			/* We're UP */
void ccp_down();		/* We're DOWN */
void ccp_resetrequest();	/* We received a Reset-Request */
void ccp_resetack();		/* We received a Reset-Ack */

/*
 * Variables for generating far pointers to the callback routines.
 */
static VoidCallback *ccp_resetopt_vfptr = ccp_resetopt;
static IntCallback *ccp_optlen_vfptr = ccp_optlen;
static VoidCallback *ccp_addopts_vfptr = ccp_addopts;
static IntCallback *ccp_ackopts_vfptr = ccp_ackopts;
static VoidCallback *ccp_nakopts_vfptr = ccp_nakopts;
static VoidCallback *ccp_rejopts_vfptr = ccp_rejopts;
static ByteCallback *ccp_reqopts_vfptr = ccp_reqopts;
static VoidCallback *ccp_up_vfptr = ccp_up;
static VoidCallback *ccp_down_vfptr = ccp_down;
static VoidCallback *ccp_resetrequest_vfptr = ccp_resetrequest;
static VoidCallback *ccp_resetack_vfptr = ccp_resetack;

fsm_callbacks ccp_callbacks;

/*
 * Variables for generating far pointers to the compressor routines.
 */
#ifdef PRED_1
static IntCallback *predictor1_comp_vfptr = predictor1_comp;
static IntCallback *predictor1_resetcomp_vfptr = predictor1_resetcomp;
static IntCallback *predictor1_decomp_vfptr = predictor1_decomp;
static VoidCallback *predictor1_resetdecomp_vfptr = predictor1_resetdecomp;
#endif /* PRED_1 */

#ifdef STAC_LZS
static IntCallback *stac_comp_vfptr = stac_comp;
static IntCallback *stac_resetcomp_vfptr = stac_resetcomp;
static IntCallback *stac_decomp_vfptr = stac_decomp;
static VoidCallback *stac_resetdecomp_vfptr = stac_resetdecomp;
#endif /* STAC_LZS */

#ifdef MPPC
static IntCallback *mppc_comp_vfptr = mppc_comp;
static IntCallback *mppc_resetcomp_vfptr = mppc_resetcomp;
static IntCallback *mppc_decomp_vfptr = mppc_decomp;
static VoidCallback *mppc_resetdecomp_vfptr = mppc_resetdecomp;
#endif /* MPPC */


/***********************************************************************
 *			ccp_select_comp_type
 ***********************************************************************
 * SYNOPSIS:	Choose a compression type to negotiate.
 * CALLED BY:	PPPConfigDataCompression
 *	    	ccp_init
 *	    	ccp_nakopts
 *	    	ccp_rejopts
 *
 * RETURN:	nothing
 *
 * STRATEGY:	Out of all the options allowed for negotiation, select
 *	    	our favorite.  If we end up with nothing to negotiate,
 *	    	then we will not be decompressing anything.
 *	    
 *	    	Our preferences start with MPPC, Stac LZS, then predictor.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/29/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_select_comp_type (ccp_options *opts)
{
    WordFlags	negTypes = opts -> ccp_neg;

#ifdef MPPC
    if (negTypes & COMPRESS_MPPC) {
	opts -> ccp_comp_type = COMPRESS_MPPC;
	return;
    }
#endif /* MPPC */

#ifdef STAC_LZS
    if (negTypes & COMPRESS_STAC) {
	opts -> ccp_comp_type = COMPRESS_STAC;
	return;
    }
#endif /* STAC_LZS */

#ifdef PRED_1
    if (negTypes & COMPRESS_PRED1) {
	opts -> ccp_comp_type = COMPRESS_PRED1;
	return;
    }
#endif /* PRED_1 */

    /*
     * Nothing allowed so set to no compression type.
     */
    opts -> ccp_comp_type = 0;
}



/***********************************************************************
 *				ccp_init
 ***********************************************************************
 * SYNOPSIS:	Initialize CCP.
 * CALLED BY:	PPPSetup using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	Fill callback structure with vfptrs.
 *	    	Initialize FSM values.
 *	    	Initialize wanted and allowed compression types,
 *	    	    along with the parameters for that type.
 *	    	Select a type to negotiate.
 *	    	Let FSM code take care of the rest.
 *
 * NOTES:   	Commented out lines initializing defaults to zero 
 *	    	because they are already zero (dgroup).  The lines
 *	    	now server as comments.
 *
 *	    	Compression types initialized here may be overridden
 *	    	by user configurations.

 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/20/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_init (int unit)
{
    fsm *f = &ccp_fsm[unit];
    ccp_options *wo = &ccp_wantoptions[unit];
    ccp_options *ao = &ccp_allowoptions[unit];

    /*
     * Fill in callback structure.
     */
    ccp_callbacks.resetci = ccp_resetopt_vfptr;
    ccp_callbacks.cilen = ccp_optlen_vfptr;
    ccp_callbacks.addci = ccp_addopts_vfptr;
    ccp_callbacks.ackci = ccp_ackopts_vfptr;
    ccp_callbacks.nakci = ccp_nakopts_vfptr;
    ccp_callbacks.rejci = ccp_rejopts_vfptr;
    ccp_callbacks.reqci = ccp_reqopts_vfptr;
    ccp_callbacks.up = ccp_up_vfptr;
    ccp_callbacks.down = ccp_down_vfptr;
    ccp_callbacks.resetrequest = ccp_resetrequest_vfptr;
    ccp_callbacks.resetack = ccp_resetack_vfptr;

    ccp_callbacks.echorequest = (ByteCallback *)NULL;
    ccp_callbacks.closed = ccp_callbacks.echoreply =
	ccp_callbacks.protreject = ccp_callbacks.retransmit = 
	    ccp_callbacks.lqreport = (VoidCallback *)NULL;

    /*
     * Initialize the FSM values.
     */
    f -> unit = unit;
    f -> protocol = CCP;
    f -> timeouttime = DEFTIMEOUT;
    f -> max_configure = MAX_CONFIGURE;
    f -> max_terminate = MAX_TERMINATE;
    f -> max_failure = MAX_FAILURE;
    f -> max_rx_failure = MAX_RX_FAILURE;    
/*  f -> tx_naks = 0;	*/
/*  f -> rx_naks = 0;	*/

    f -> code_mask = 0xc0fe;		/* Configure-Request through */
					/* Code-Reject, plus Reset-Request */
					/* and Reset-Ack */
    f -> callbacks = &ccp_callbacks;

    /*
     * Initialize want and allow options.  Want and allow all 
     * supported compression types by default.
     */
#ifdef PRED_1
    wo -> ccp_neg |= COMPRESS_PRED1;
    ao -> ccp_neg |= COMPRESS_PRED1;
#endif /* PRED_1 */

#ifdef STAC_LZS
    /* 
     * Start off with extended check mode.
     */
    wo -> ccp_neg |= COMPRESS_STAC;    
    ao -> ccp_neg |= COMPRESS_STAC;

    wo -> ccp_stac_check_mode = ao -> ccp_stac_check_mode = 
	STAC_CHECK_EXTENDED;
#endif /* STAC_LZS */

#ifdef MPPC
    wo -> ccp_neg |= COMPRESS_MPPC;
    ao -> ccp_neg |= COMPRESS_MPPC;
#endif /* MPPC */

    /*
     * Pick a compression type to start negotiations with.
     */
    ccp_select_comp_type(wo);

    /*
     * Let the FSM initialize the rest by itself.
     */
    fsm_init(f);

}


/***********************************************************************
 *				ccp_open
 ***********************************************************************
 * SYNOPSIS:	Open CCP.
 * CALLED BY:	BeginNetworkPhase
 * RETURN:	nothing
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/20/96		Initial Revision
 *
 ***********************************************************************/
void ccp_open (int unit)
{
    fsm_open(&ccp_fsm[unit]);

    /*
     *  If no compression is configured, don't initiate CCP.
     */
    if (ccp_gotoptions[unit].ccp_comp_type == 0)
	active_compress = FALSE;
}


/***********************************************************************
 *				ccp_close
 ***********************************************************************
 * SYNOPSIS:	Close CCP.
 * CALLED BY:	ccp_nakopts
 * 	        ccp_up
 *	    	ccp_resettimeout
 *	
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/20/96		Initial Revision
 *
 ***********************************************************************/
void ccp_close (int unit)
{
    fsm_close(&ccp_fsm[unit]);
}



/***********************************************************************
 *				ccp_lowerup
 ***********************************************************************
 * SYNOPSIS:	The lower layer (LCP) is up.
 * CALLED BY:	BeginNetworkPhase
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_lowerup (int unit)
{
    fsm_lowerup(&ccp_fsm[unit]);
}


/***********************************************************************
 *				ccp_lowerdown
 ***********************************************************************
 * SYNOPSIS:	The lower layer (LCP) is down.
 * CALLED BY:	EndNetworkPhase
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_lowerdown (int unit)
{
    fsm_lowerdown(&ccp_fsm[unit]);
}


/***********************************************************************
 *				ccp_input
 ***********************************************************************
 * SYNOPSIS:	Process a received CCP packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects the idle time
 *	    	
 * STRATEGY:	Process the CCP packet if we either allow or 
 *	    	want compression.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
byte ccp_input (int unit, PACKET *p, int len)
{
    /*
     * If doing compression, process based on packet type.	
     * Else reject CCP protocol.
     */

    if ( ccp_allowoptions[0].ccp_neg || ccp_wantoptions[0].ccp_neg) {
	return (fsm_input(&ccp_fsm[unit], p, len));
    }
    	
    lcp_sprotrej(unit, p, len);
    return (1);
    
}


/***********************************************************************
 *				ccp_protrej
 ***********************************************************************
 * SYNOPSIS:	Process a received Protocol-Reject for CCP.
 * CALLED BY:	demuxprotrej using prottbl entry
 * RETURN:	nothing
 *
 * STRATEGY:	Simply pretend that CCP went down.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_protrej (int unit)
{
    fsm_lowerdown(&ccp_fsm[unit]);
}


/***********************************************************************
 *				ccp_resetopt
 ***********************************************************************
 * SYNOPSIS:	Reset our CCP options. (FSM callback routine)
 * CALLED BY:	fsm_open
 * RETURN:	nothing
 *
 * STRATEGY:	Clear out nak table in wantoptions.
 *	    	Set gotoptions to wantoptions.
 *	    	Set heroptions to allowoptions.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_resetopt (fsm *f)
{
    int i;
    for (i = 0; i <= CCP_MAXCI; i++)
	ccp_wantoptions[f -> unit].rxnaks[i] = 0;

    ccp_gotoptions[f -> unit] = ccp_wantoptions[f -> unit];
    ccp_heroptions[f -> unit] = ccp_allowoptions[f -> unit];
}


/***********************************************************************
 *				ccp_optlen
 ***********************************************************************
 * SYNOPSIS:	Return the length of our options.
 *	    	(FSM callback routine)
 * CALLED BY:	scr 
 * RETURN:	length of our CCP options
 *
 * STRATEGY:   	We're only sending one option at a time so return 
 *	    	the length of the option we'll be asking for.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC 
 *
 ***********************************************************************/
int ccp_optlen (fsm *f)
{
 
#ifdef MPPC
    if (ccp_gotoptions[0].ccp_comp_type == COMPRESS_MPPC)
	return (CI_MPPC_LEN);
#endif /* MPPC */

#ifdef STAC_LZS
    if (ccp_gotoptions[0].ccp_comp_type == COMPRESS_STAC)
	return (CI_STAC_LEN);
#endif /* STAC_LZS */

#ifdef PRED_1
    if (ccp_gotoptions[0].ccp_comp_type == COMPRESS_PRED1)
	return (CI_PRED1_LEN);
#endif /* PRED_1 */

    return (0);

}


/***********************************************************************
 *				ccp_addopts
 ***********************************************************************
 * SYNOPSIS:	Add our desired options to a packet.
 *	    	(FSM callback routine)
 * CALLED BY:	scr
 * RETURN:	nothing
 *
 * STRATEGY:	Send the compression type we wish to negotiate.
 *     	    	Only send one option at a time to make life 
 *	    	easier for the peer.
 *
 * NOTES:   	The CCP option is an announcement of what method 
 *	    	we are willing to decompress with.  
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_addopts (fsm *f, 
		  unsigned char *ucp)	 /* pointer to where info is added */
{
    ccp_options *go = &ccp_gotoptions[f -> unit];

#ifdef MPPC
    if (go -> ccp_comp_type == COMPRESS_MPPC) {
	PUTCHAR(CI_MICROSOFT_PPC, ucp);
	PUTCHAR(CI_MPPC_LEN, ucp);
	PUTLONG(MPPC_SUPPORTED_BITS, ucp);

	LOG3(LOG_NEG, (LOG_CCP_SEND_MPPC));

	return;
    }
#endif /* MPPC */

#ifdef STAC_LZS
    if (go -> ccp_comp_type == COMPRESS_STAC) {
	PUTCHAR(CI_STAC_LZS, ucp);
	PUTCHAR(CI_STAC_LEN, ucp);  
	PUTSHORT(STAC_HISTORY_COUNT, ucp);   	
	PUTCHAR(go -> ccp_stac_check_mode, ucp);    

	LOG3(LOG_NEG, (LOG_CCP_SEND_STAC,
		      STAC_HISTORY_COUNT, go -> ccp_stac_check_mode));
	return;
    }
#endif /* STAC_LZS */

#ifdef PRED_1
    if (go -> ccp_comp_type == COMPRESS_PRED1) {
	PUTCHAR(CI_PREDICTOR1, ucp);
	PUTCHAR(CI_PRED1_LEN, ucp);   

	LOG3(LOG_NEG, (LOG_CCP_SEND_PRED1));
	return;
    }
#endif /* PRED_1 */


}


/***********************************************************************
 *				ccp_ackopts
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Ack.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	0 if ack was bad
 *	    	1 if ack was good
 *
 * STRATEGY:	A good ack MUST contain only the one option we
 *	    	sent without any modifications.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
int ccp_ackopts (fsm *f, 
		 unsigned char *p,  	/* pointer to packet data */
		 int len)   	    	/* length of packet data */
{
    ccp_options *go = &ccp_gotoptions[f -> unit];
    unsigned short optlen, opttype;
#ifdef STAC_LZS
    unsigned short optshort;
    unsigned char optchar1;
#endif /* STAC_LZS */

#ifdef MPPC
    unsigned long optlong;
#endif /* MPPC */

    /*
     * There must be only one option in the packet.  After getting
     * the option we expect to be in the ack, check the length.  
     * If there are any remaining options, then this packet is bad.
     * The option length and parameters MUST match exactly what
     * we sent or the packet is bad.
     */
    
#ifdef MPPC
    if (go -> ccp_comp_type == COMPRESS_MPPC) {
	
	len -= CI_MPPC_LEN;
	if (len < 0)
	    goto bad;

	GETCHAR(opttype, p);
	GETCHAR(optlen, p);

	if (optlen != CI_MPPC_LEN ||
	    opttype != CI_MICROSOFT_PPC)
	    goto bad;

	GETLONG(optlong, p);
	if (optlong != MPPC_SUPPORTED_BITS)
	    goto bad;

	goto checkLen;
    }
#endif /* MPPC */

#ifdef STAC_LZS
    if (go -> ccp_comp_type == COMPRESS_STAC) {

	len -= CI_STAC_LEN;
	if (len < 0) 
	    goto bad;

	GETCHAR(opttype, p);
	GETCHAR(optlen, p);

	if (optlen != CI_STAC_LEN ||
	    opttype != CI_STAC_LZS)
	    goto bad;

	GETSHORT(optshort, p);	    	    /* History-Count */
	GETCHAR(optchar1, p);	    	    /* Check-Mode */

	if (optshort != STAC_HISTORY_COUNT ||
	    optchar1 != go -> ccp_stac_check_mode) 
	    goto bad;

	goto checkLen;
    }
#endif /* STAC_LZS */


#ifdef PRED_1
    if (go -> ccp_comp_type == COMPRESS_PRED1) {

	len -= CI_PRED1_LEN;	   
	if (len < 0)
	    goto bad;
	
	GETCHAR(opttype, p);
	GETCHAR(optlen, p);

	if (optlen != CI_PRED1_LEN ||
	    opttype != CI_PREDICTOR1)
	    goto bad;

	goto checkLen;

    }
#endif /* PRED_1 */

checkLen:
    /*
     * If there are any remaining options, then this packet is bad.
     */
    if (len != 0)
	goto bad;

    return (1);

bad:
    LOG3(LOG_NEG, (LOG_CCP_BAD, "Ack"));
    return (0);
}


/***********************************************************************
 *				ccp_nakopts
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Nak message.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 * STRATEGY:	If peer gives us a choice, pick the desired 
 *	    	compression method.  If nothing left, stop CCP.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_nakopts (fsm *f,
		  unsigned char *p, 	    /* pointer to packet data */
		  int len)  	    	    /* length of packet data */
{
    ccp_options *go = &ccp_gotoptions[f -> unit];
    ccp_options *wo = &ccp_wantoptions[f -> unit];
    byte needChange = 1;
    
#ifdef STAC_LZS
    unsigned short optshort;
    unsigned char optchar1;
#endif /* STAC_LZS */

    /*
     * Give up if too many Configure-Naks have been received.
     */
    if (f -> rx_naks > f -> max_rx_failure) {
	LOG3(LOG_BASE, (LOG_CCP_GIVE_UP));
	ccp_close(0);
    }

    /*
     * Clear what we will be negotiating and let the peer tell us
     * which compression types we may use.
     */
    go -> ccp_neg = 0;

    /*
     * Process each option.  If option is what we asked for, then peer
     * is probably modifying the option params.  Use the params suggested
     * by the peer if we understand them.  No need to change the
     * compression type being negotiated.
     */
    while (len > 0) {

#ifdef STAC_LZS
	unsigned char *p1 = p + 2;  	/* p1 points after opt type and len */
#endif /* STAC_LZS */

	int optlen = p[1];	      	

	if (optlen > len || optlen < 2)
	    goto bad;

	switch (p[0]) {

#ifdef PRED_1
	    case CI_PREDICTOR1:
	    	if (optlen == CI_PRED1_LEN && wo -> ccp_neg & COMPRESS_PRED1) {

		    if (go -> ccp_comp_type == COMPRESS_PRED1)
			needChange = 0;
		    go -> ccp_neg |= COMPRESS_PRED1;
		    ++go -> rxnaks[CI_PREDICTOR1];

#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_PREDICTOR1] % ccp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_CCP_PEER_NO_PRED1));
		    }
#endif /* LOGGING_ENABLED */
		}

		LOG3(LOG_NEG, (LOG_CCP_PEER_NAK_PRED1));

		break;
#endif /* PRED_1 */
		
#ifdef STAC_LZS
	    case CI_STAC_LZS:
		if (optlen == CI_STAC_LEN && wo -> ccp_neg & COMPRESS_STAC) {
		    GETSHORT(optshort, p1); 	    /* History-Count */
		    GETCHAR(optchar1, p1);  	    /* Check-Mode */

		    LOG3(LOG_NEG, (LOG_CCP_PEER_NAK_STAC, 
				   optshort, optchar1));

		    if (go -> ccp_comp_type == COMPRESS_STAC)
			needChange = 0;
		    go -> ccp_neg |= COMPRESS_STAC;

		    /*
		     * Only listen if peer suggests a single history
		     * count and a valid check mode.  
		     */
		    if (optshort == STAC_HISTORY_COUNT &&
			(optchar1 > 0 && optchar1 <= STAC_CHECK_EXTENDED)) {

			/*
			 * Use check mode suggested by peer.  
			 */
			if (optchar1 != go -> ccp_stac_check_mode) {
			    go -> ccp_stac_check_mode = optchar1;
			}
			else {
			    /* 
			     * Some peers will nak the check mode 
			     * without suggesting an alternative. 
			     * Try all modes until one works, starting
			     * from extended, then crc, then lcb, then 
			     * sequenced.  Unfortunately these are numbered
			     * 4, 2, 1, 3.  We can shift right by 1 until
			     * we get to 0, then reset to 3.  If we start
			     * with 3, give up.
			     */
			    if (optchar1 == STAC_CHECK_SEQ) {
				go -> ccp_stac_check_mode = 0; /* no others */
			    }
			    else if (optchar1) {
				go -> ccp_stac_check_mode >>= 1;
				if (go -> ccp_stac_check_mode == 0)
				    go -> ccp_stac_check_mode = STAC_CHECK_SEQ;
			    }
			}
		    }

		    ++go -> rxnaks[CI_STAC_LZS];

#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_STAC_LZS] % ccp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_CCP_PEER_NO_STAC));
		    }
		}
		else {
		    LOG3(LOG_NEG, (LOG_CCP_PEER_NAK_STAC_SIMPLE));
#endif /* LOGGING_ENABLED */

		}
		break;
#endif /* STAC_LZS */


#ifdef MPPC
	    case CI_MICROSOFT_PPC:
		/*
		 * No need to check supported bits because RFC says it
		 * can only have one value.
		 */
		if (optlen == CI_MPPC_LEN && wo -> ccp_neg & COMPRESS_MPPC) {

		    if (go -> ccp_comp_type == COMPRESS_MPPC)
			needChange = 0;
		    go -> ccp_neg |= COMPRESS_MPPC;

		    ++go -> rxnaks[CI_MICROSOFT_PPC];
#ifdef LOGGING_ENABLED
		    if (go -> rxnaks[CI_MICROSOFT_PPC] % ccp_warnnaks == 0) {
			LOG3(LOG_BASE, (LOG_CCP_PEER_NO_MPPC));
		    }
#endif /* LOGGING_ENABLED */
		}

		LOG3(LOG_NEG, (LOG_CCP_PEER_NAK_MPPC));

		break;
#endif /* MPPC */

	    default:
		LOG3(LOG_NEG, (LOG_CCP_UNKNOWN_NAK,
			      p[0]));
	    }

	len -= optlen;
	p += optlen;
    }

    if (len == 0) {
	if (needChange) {
	    /*
	     * Peer has give us her alternatives; choose our favorite.
	     * If nothing left, stop CCP.
	     */
	    ccp_select_comp_type(go);

	    if (go -> ccp_comp_type == 0)
	       ccp_close(f -> unit);
	}
	return;
    }

bad:
    LOG3(LOG_NEG, (LOG_CCP_BAD, "Nak"));
}


/***********************************************************************
 *				ccp_rejopts
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Reject.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 * STRATEGY:	A good configure reject must contain only the option
 *	    	we requested, unmodified.  Anything else is bad.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_rejopts (fsm *f,
		  unsigned char *p, 	/* pointer to packet data */
		  int len)  	    	/* length of packet data */
{
    ccp_options *go = &ccp_gotoptions[f -> unit];
#ifdef STAC_LZS
    unsigned short optshort;
    unsigned char optchar1;
#endif /* STAC_LZS */

#ifdef MPPC
    unsigned long optlong;
#endif /* MPPC */

    /*
     * Any Rejected options must be exactly the same as what we sent.
     * Check packet length and option length.  If we find any deviations, 
     * then this packet is bad.
     */

#ifdef PRED_1
    if (go -> ccp_comp_type == COMPRESS_PRED1 &&
	len >= CI_PRED1_LEN && 
	p[1] == CI_PRED1_LEN &&
	p[0] == CI_PREDICTOR1) {
	
	len -= CI_PRED1_LEN;
	INCPTR(2, p);	    	    	/* Advance ptr past opt type & len */
	go -> ccp_neg &= ~COMPRESS_PRED1;

	LOG3(LOG_NEG, (LOG_CCP_PEER_REJ_PRED1));

	goto checkLen;
    }
#endif /* PRED_1 */

#ifdef STAC_LZS
    if (go -> ccp_comp_type == COMPRESS_STAC &&
	len >= CI_STAC_LEN &&
	p[1] == CI_STAC_LEN &&
	p[0] == CI_STAC_LZS) {
	
	len -= CI_STAC_LEN;
	INCPTR(2, p);
	GETSHORT(optshort, p);	    	/* History-Count */
	GETCHAR(optchar1, p);	    	/* Check-Mode */

	LOG3(LOG_NEG, (LOG_CCP_PEER_REJ_STAC));

	if (optshort != STAC_HISTORY_COUNT) {
	    LOG3(LOG_NEG, (LOG_CCP_REJ_WRONG, "History-Count",
			  optshort, STAC_HISTORY_COUNT));
	    goto bad;
	}

	if (optchar1 != go -> ccp_stac_check_mode) {
	    LOG3(LOG_NEG, (LOG_CCP_REJ_WRONG, "Check-Mode",
			  optchar1, go -> ccp_stac_check_mode));
	    goto bad;
	}

	go -> ccp_neg &= ~COMPRESS_STAC;

	goto checkLen;
    }
#endif /* STAC_LZS */

#ifdef MPPC 
    if (go -> ccp_comp_type == COMPRESS_MPPC &&
	len >= CI_MPPC_LEN &&
	p[1] == CI_MPPC_LEN &&
	p[0] == CI_MICROSOFT_PPC) {

	len -= CI_MPPC_LEN;
	INCPTR(2, p);		/* Advance ptr past opt type & len */
	GETLONG(optlong, p);

	LOG3(LOG_NEG, (LOG_CCP_PEER_REJ_MPPC));

	if (optlong != MPPC_SUPPORTED_BITS) {
	    LOG3(LOG_NEG, (LOG_CCP_REJ_WRONG, "Supported Bits",
			   optlong, MPPC_SUPPORTED_BITS));
	    goto bad;
	}

	go -> ccp_neg &= ~COMPRESS_MPPC;

	goto checkLen;
    }
#endif /* MPPC */

    /*
     * If there are any remaining options, then this packet is bad.
     * Else select a new compression type to negotiate.
     * If nothing left, stop CCP.
     */
checkLen:
    if (len == 0) {
	ccp_select_comp_type(go);
	if (go -> ccp_comp_type == 0)
	    ccp_close(f -> unit);
	return;
    }

bad:
    LOG3(LOG_NEG, (LOG_CCP_BAD, "Rej"));

}



/***********************************************************************
 *				ccp_reqopts
 ***********************************************************************
 * SYNOPSIS:	Process a received Configure-Request.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	0 if no response should be sent, else
 *	    	CONFIGURE_ACK, CONFIGURE_NAK, or CONFIGURE_REJECT
 * 
 * SIDE EFFECTS: Packet is modified to contain the appropriate response.
 *
 * STRATEGY:	Allocate a buffer for work space
 *	    	Go through each option verifying packet is of the
 * 	    	  correct format to count the number of requested
 *	    	  compression protocols.
 *	    	Reset her options.
 *	    	If only one left, ack.
 *	    	Else nak all compression protocols that are acceptable.
 *	    	Process each option in the request, double checking length
 *	    	  again.  If acceptable, nak it.  If unacceptable, put
 *	    	  option in a reject packet.
 * 	    	Copy what we're planning to send into the original buffer
 *	    	  and free the one allocated for work space
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
unsigned char ccp_reqopts (fsm *f,
			   unsigned char *inp,	/* Requested options */
			   int *len)	    	/* Length of options */
{
    ccp_options *ao = &ccp_allowoptions[f -> unit],
    	    	*ho = &ccp_heroptions[f -> unit];

    PACKET *reply_pkt;
    unsigned char *reply_p; 	       /* Pointer to start of reply */
    unsigned char *outoptp; 	       /* Pointer to current output option */
    unsigned char *outp;               /* Pointer to current output char */
    unsigned char *optp = inp;	       /* Pointer to current input option */
    unsigned char optlen, opttype;     /* Option len, option type */
#ifdef STAC_LZS	    	
    unsigned short optshort;
    unsigned char optchar1;
    int not_converging = f -> tx_naks >= f -> max_failure;
#endif /* STAC_LZS */

#ifdef MPPC
    unsigned long optlong;
#endif /* MPPC */

    int ack;                    /* initial response for all options */
    int rc;			/* Final reply code */
    int orc;			/* Return code of current option */
    DOLOG(int real_orc;)	/* What we *wanted* to send */
    unsigned char *p;		/* Pointer to next input char to parse */
    int l = *len;		/* Length left */
    int options = 0;		/* Number of options in this Conf-Req */

    if ((reply_pkt = PACKET_ALLOC(MAX_MTU)) == 0) {
	LOG3(LOG_BASE, (LOG_CCP_NO_MEM_WARN));
	return (0);
    }
	
    reply_p = outoptp = outp = PACKET_DATA(reply_pkt);

    ack = rc = CONFIGURE_ACK;	

# define NAK(len)	{ \
			orc = CONFIGURE_NAK; \
			DOLOG(real_orc = CONFIGURE_NAK;) \
			if (rc != CONFIGURE_REJECT) \
			    { \
			    if (rc != CONFIGURE_NAK) outoptp = reply_p; \
			    rc = CONFIGURE_NAK; \
			    outp = outoptp; \
			    PUTCHAR(opttype, outp); \
			    PUTCHAR(len, outp); \
			    } \
			}

# define REJECT()	{ \
			LOG3(LOG_NEG, (LOG_REJ)); \
			orc = CONFIGURE_REJECT; \
			DOLOG(real_orc = CONFIGURE_REJECT;) \
			if (rc != CONFIGURE_REJECT) \
			    outoptp = reply_p; \
			rc = CONFIGURE_REJECT; \
			outp = outoptp; \
			memmove(outp, optp, optlen); \
			outp += optlen; \
			}

    
    /*
     * Reset all her options.
     */
    ho -> ccp_neg = ho -> ccp_comp_type = 0;

    /*
     * Process each Configuration Option in this Configure-Request.
     */
    while (l) {

	/*
	 * If more than one option in this packet, we cannot 
	 * respond with an ack.
	 */
	++options;
	if (rc == CONFIGURE_ACK && options > 1) {
	    ack = rc = CONFIGURE_NAK;
	}

	orc = ack;
	DOLOG(real_orc = CONFIGURE_ACK;)    /* Assume success */
	p = optp;   	    	    	    /* p = current input option */

	/*
	 * Verify the lengths again.  They shouldn't have changed since
	 * the earlier check, but you can't be too careful...
	 */
	if (l < 2 || p[1] < 2 || (int)p[1] > l) {
	    LOG3(LOG_NEG, (LOG_CCP_BAD, "Request (bad option length)"));
	    PACKET_FREE(reply_pkt);
	    return (0);			/* No reply should be sent */
	}

	GETCHAR(opttype, p);	       
	GETCHAR(optlen, p);
	l -= optlen;			/* Adjust remaining length */
	
	switch (opttype) {  	    

#ifdef PRED_1
	    case CI_PREDICTOR1:
	    	LOG3(LOG_NEG, (LOG_CCP_GOT_OPT, "Predictor-1"));

		if (! (ao -> ccp_neg & COMPRESS_PRED1)  ||
		    optlen != CI_PRED1_LEN) {
		    REJECT();
		}
		else {
		    ho -> ccp_neg |= COMPRESS_PRED1;
		    if (rc == CONFIGURE_ACK)
			ho -> ccp_comp_type = COMPRESS_PRED1;
		}
		break;
#endif /* PRED_1 */


#ifdef STAC_LZS
	    case CI_STAC_LZS:
		LOG3(LOG_NEG, (LOG_CCP_GOT_OPT, "Stac"));
		
		if (! (ao -> ccp_neg & COMPRESS_STAC) ||
		    optlen != CI_STAC_LEN) {
		    REJECT();
		    break;
		}

		GETSHORT(optshort, p);			/* History-Count */
		GETCHAR(optchar1, p);			/* Check-Mode */

		LOG3(LOG_NEG, (LOG_CCP_HISTORY_CHECK, 
			      optshort, optchar1));

		/*
		 * If everything is agreeable, give her what she wants.
		 */
		if (optshort == STAC_HISTORY_COUNT &&
		    (optchar1 > 0 && optchar1 <= STAC_CHECK_EXTENDED)) {
		    ho -> ccp_neg |= COMPRESS_STAC;
		    ho -> ccp_stac_check_mode = optchar1;

		    if (rc == CONFIGURE_ACK)
			ho -> ccp_comp_type = COMPRESS_STAC;

		    break;
	    	}

		/*
		 * If we don't understand her desired check mode,
		 * suggest something we do understand.
		 */
		if ((optchar1 == 0 || optchar1 > STAC_CHECK_EXTENDED)) {
		    optchar1 = ho -> ccp_stac_check_mode;
		    /* 
		     * Store the next check mode to try.  Starting from
		     * extended, then crc, then lcb, then seq.  Unfortunately
		     * these are numbered 4, 2, 1, 3.  We can shift right 
		     * by 1 until we get to 0, then reset to 3.  If we 
		     * start with 3, give up.  
		     */
		    if (optchar1 == STAC_CHECK_SEQ) {
			ho -> ccp_stac_check_mode = 0;     /* no other modes */
		    }
		    else if (optchar1) {	
			ho -> ccp_stac_check_mode >>= 1;
			if (ho -> ccp_stac_check_mode == 0)
			    ho -> ccp_stac_check_mode = STAC_CHECK_SEQ;
		    }
		}

		/*
		 * Need to change what she wants.  If tried too many
		 * times or have no check mode left to suggest, give up now.
		 */
		if (not_converging || optchar1 == 0) {
		    REJECT();
		    LOG3(LOG_BASE, (LOG_CCP_CANT_DO_STAC));
		    break;
		}

		/*
		 * Nak the option.  If we're already rejecting,
		 * don't stick the desired params for Stac LZS
		 * in the reject packet!
		 */
		NAK(optlen);
		if (rc != CONFIGURE_REJECT) {
		    PUTSHORT(STAC_HISTORY_COUNT, outp);
		    PUTCHAR(optchar1, outp);
		}
		LOG3(LOG_NEG, (LOG_CCP_NAK_HISTORY_CHECK, 
			       STAC_HISTORY_COUNT, optchar1));
		break;
#endif /* STAC_LZS */

#ifdef MPPC
	    case CI_MICROSOFT_PPC:
		LOG3(LOG_NEG, (LOG_CCP_GOT_OPT, "MPPC"));

		if (! (ao -> ccp_neg & COMPRESS_MPPC) ||
		    optlen != CI_MPPC_LEN) {
		    REJECT();
		    break;
		}

		/* 
		 * Check the supported bits value.  If bits is correct, 
		 * give her what she wants.  Else, nak with correct bits
		 * value.
		 */
		GETLONG(optlong, p);
		
		LOG3(LOG_NEG, (LOG_CCP_MPPC_BITS, optlong));

		if (optlong == MPPC_SUPPORTED_BITS) {
		    ho -> ccp_neg |= COMPRESS_MPPC;

		    if (rc == CONFIGURE_ACK)
			ho -> ccp_comp_type = COMPRESS_MPPC;

		    break;
		} 
		
		/*
		 * Nak the option. If we're already rejecting,
		 * don't stick the desired params for MPPC in
		 * the reject packet!
		 */
		NAK(optlen);
		if (rc != CONFIGURE_REJECT) {
		    PUTLONG(MPPC_SUPPORTED_BITS, outp);
		}
		LOG3(LOG_NEG, (LOG_CCP_NAK_MPPC_BITS));

		break;
#endif /* MPPC */

	    default:
		LOG3(LOG_NEG, (LOG_CCP_UNKNOWN_OPTION, opttype));
		REJECT();
		break;
	    }

	/*
	 * If this option's result is the same as the one we're planning
	 * to send, add the option to the packet.
	 */
	if (orc == ack) {
#ifdef LOGGING_ENABLED
	    if (real_orc == CONFIGURE_ACK) {
		LOG3(LOG_NEG, (LOG_ACK));
	    }	    
#endif /* LOGGING_ENABLED */
	    if (rc == ack) {
		memmove(outp, optp, optlen);
		outp += optlen;
	    }
	}	    

	optp += optlen;
	outoptp = outp;

    }


    /*
     *	If we wanted to send additional NAKs (for unsent options), the
     *	code would go here.  This must be done with care since it
     *	might require a longer packet than we received.
     */

    *len = outp - reply_p;  	    	    /* Compute output length */
    memmove(inp, reply_p, (*len));
    PACKET_FREE(reply_pkt);

    LOG3(LOG_NEG, (LOG_CCP_REPLY,
		  rc == CONFIGURE_ACK ? "Configure-Ack" :
		  (rc == CONFIGURE_NAK ? "Configure-Nak" : "Configure-Reject")));

    return (rc);				/* Return final code */    

}


/***********************************************************************
 *				ccp_up
 ***********************************************************************
 * SYNOPSIS:	CCP has come UP.
 *	    	(FSM callback routine)
 * CALLED BY:	tlu
 * RETURN:	nothing
 *
 * STRATEGY:	Store the vfptrs of the compressor and decompressor
 *	    	routines in ccp fsm structure.
 *	    	If closing ccp, do not continue with any further 
 *	    	initialization or else memory will be allocated 
 *	    	and never freed.
 *
 *	    	If nothing negotiated, close ccp.
 *
 *	    	Only one compression protocol can be used for 
 *	    	each direction of the link.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_up (fsm *f)
{
    ccp_options *go = &ccp_gotoptions[f -> unit],
    	    	*ho = &ccp_heroptions[f -> unit];

    ccp[f -> unit].ccp_orig_mtu = cf_mru;

    if (go -> ccp_comp_type == 0 && ho -> ccp_comp_type == 0)
	goto noComp;

    switch (go -> ccp_comp_type) {

#ifdef PRED_1
        case COMPRESS_PRED1:

	    ccp[f -> unit].ccp_decompressor = predictor1_decomp_vfptr;
	    ccp[f -> unit].ccp_resetdecompressor = predictor1_resetdecomp_vfptr;

	    if (predictor1_initdecomp(f -> unit, cf_mru) < 0) 
		goto noComp;

	    break;
#endif /* PRED_1 */

#ifdef STAC_LZS
        case COMPRESS_STAC:
	    ccp[f -> unit].ccp_decompressor = stac_decomp_vfptr;
	    ccp[f -> unit].ccp_resetdecompressor = stac_resetdecomp_vfptr;

	    if (stac_initdecomp(f -> unit, cf_mru, 
				go -> ccp_stac_check_mode) < 0)
		goto noComp;	    

	    break;
#endif /* STAC_LZS */

#ifdef MPPC
        case COMPRESS_MPPC:
	    ccp[f -> unit].ccp_decompressor = mppc_decomp_vfptr;
	    ccp[f -> unit].ccp_resetdecompressor = mppc_resetdecomp_vfptr;

	    if (mppc_initdecomp(f -> unit, cf_mru) < 0)
		goto noComp;

	    break;
#endif /* MPPC */

    }


    switch (ho -> ccp_comp_type) {

#ifdef PRED_1
        case COMPRESS_PRED1:

	    ccp[f -> unit].ccp_compressor = predictor1_comp_vfptr;
	    ccp[f -> unit].ccp_resetcompressor = predictor1_resetcomp_vfptr;

	    if (predictor1_initcomp(f -> unit, cf_mru) < 0)
		goto noComp;

	    break;
#endif /* PRED_1 */


#ifdef STAC_LZS
	case COMPRESS_STAC:

	    ccp[f -> unit].ccp_compressor = stac_comp_vfptr;
	    ccp[f -> unit].ccp_resetcompressor = stac_resetcomp_vfptr;

	    if (stac_initcomp(f -> unit, cf_mru, 
			      ho -> ccp_stac_check_mode) < 0)
		goto noComp;

	    break;
#endif /* STAC_LZS */

#ifdef MPPC
	case COMPRESS_MPPC:

	    ccp[f -> unit].ccp_compressor = mppc_comp_vfptr;
	    ccp[f -> unit].ccp_resetcompressor = mppc_resetcomp_vfptr;

	    if (mppc_initcomp(f -> unit, cf_mru) < 0)
		goto noComp;

	    break;
#endif /* MPPC */

    }

    return; 	    	    

noComp:
    ccp_close(f -> unit);
}



/***********************************************************************
 *				ccp_down
 ***********************************************************************
 * SYNOPSIS:	CCP has gone down.
 *	    	(FSM callback routine)
 * CALLED BY:	tld
 * RETURN:	nothing
 *
 * STRATEGY:	Clear pointers to compressor routines.
 *	    	Have compression protocols free memory used.
 *	    	Restore interface MTU to original.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu	9/23/97		Added MPPC
 *
 ***********************************************************************/
void ccp_down (fsm *f)
{
    ccp[f -> unit].ccp_decompressor = 0;
    ccp[f -> unit].ccp_compressor = 0;
    ccp[f -> unit].ccp_resetdecompressor = 0;
    ccp[f -> unit].ccp_resetcompressor = 0;
    ccp[f -> unit].ccp_resetting = 0;

#ifdef PRED_1
    predictor1_down(f -> unit);
#endif /* PRED_1 */

#ifdef STAC_LZS
    stac_down(f -> unit);
#endif /* STAC_LZS */

#ifdef MPPC
    mppc_down(f -> unit);
#endif /* MPPC */

    fsm_stop_timer(f);

    SetInterfaceMTU(ccp[f -> unit].ccp_orig_mtu);

}


/***********************************************************************
 *				ccp_resettimeout
 ***********************************************************************
 * SYNOPSIS:	Timeout expired before receiving a response to our
 *	    	Reset-Request.
 * CALLED BY:	PPPHandleTimeout 
 * RETURN:	nothing
 *
 * STRATEGY:	If retransmit counter > 0 
 *	    	    send another reset request and decrement retransmit
 *	    	    counter. 
 *	    	Else, bring down ccp.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_resettimeout (int unit)
{
    fsm *f = &ccp_fsm[unit];

    if (f -> state == OPENED) {

	/*
	 * If we haven't retransmitted too many times, send another
	 * reset-request with the same ID.
	 */
	if (f -> retransmits > 0) {
	    fsm_sdata(f, RESET_REQUEST, f -> id, (unsigned char *)NULL, 
		    (PACKET *)NULL, 0);
	    fsm_start_timer(f);
    	}
	else {
	    ccp[unit].ccp_resetting = 0;
	    ccp_close(unit);
	}

    }
}


/***********************************************************************
 *				ccp_resetrequest
 ***********************************************************************
 * SYNOPSIS:	Process a received CCP Reset-Request packet.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 * STRATEGY:	Let decompressor decide if a reset-ack is needed.  
 *	    	Predictor1 always needs to reply with an ack, but
 *	    	stac Lzs in extended mode can resynch without an ack.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_resetrequest (fsm *f, unsigned char *p, unsigned char id, int len)
     /*fsm *f;*/	    	    /* old-style function declaration needed here */
     /*unsigned char *p;*/   	        /* pointer to data */
     /*unsigned char id;*/
       /*int len;*/	    	    	/* length of packet */

{
    int ack = 1;

    /*
     * Only process reset-requests if CCP is in the OPENED state.
     */
    if (ccp_fsm[f -> unit].state == OPENED) {

	/*
	 * Reset compressor dictionary.
	 */
	EC_ERROR_IF(ccp[f -> unit].ccp_resetcompressor == 0, -1);
	ack = ProcCallFixedOrMovable_pascal(f -> unit, 
					    ccp[f -> unit].ccp_resetcompressor);
	/*
	 * Send a Reset-Ack, if needed.
	 */
	if (ack) 
	    fsm_sdata(f, RESET_ACK, id, p, (PACKET *)NULL, len);
    }
}


/***********************************************************************
 *				ccp_resetack
 ***********************************************************************
 * SYNOPSIS:	Process a received CCP Reset-Ack.
 *	    	(FSM callback routine)
 * CALLED BY:	fsm_input
 * RETURN:	nothing
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
void ccp_resetack (fsm *f, unsigned char *p, unsigned char id, int len)
     /*fsm *f;*/	    	    	/* old-style function declaration needed here */
     /*unsigned char *p;   	
unsigned char id;
int len;*/
{

    /*
     * Only process the reset-ack if CCP is in the OPENED state.
     */
    if (ccp_fsm[f -> unit].state == OPENED) {

    	fsm_stop_timer(f);

	EC_ERROR_IF(ccp[f -> unit].ccp_resetdecompressor == 0, -1);
    	ProcCallFixedOrMovable_pascal(f -> unit, 
				      ccp[f -> unit].ccp_resetdecompressor);

    	ccp[f -> unit].ccp_resetting = 0;
    }

}


/***********************************************************************
 *				ccp_reset
 ***********************************************************************
 * SYNOPSIS:	ccp_reset
 * CALLED BY:	compress_input
 * RETURN:	nothing
 *
 * STRATEGY:	Remember we are waiting for a reset-ack
 *	    	Send a reset request, incrementint the ID
 *	    	Initialize retransmit counter
 *	    	Start retransmit timer
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *	jwu 	11/18/96    	Added backoff timer
 *
 ***********************************************************************/
void ccp_reset (int unit)
{
    fsm *f = &ccp_fsm[unit];

    ccp[f -> unit].ccp_resetting = 1;

    /*
     *	Send a Reset-Request with a new ID.
     */
    fsm_sdata(f, RESET_REQUEST, ++f -> id, (unsigned char *)NULL, 
	      (PACKET *)NULL, 0);    

    /*
     * Use the maximum number of configure request transmissions
     * for the max reset-requests.  Backoff timer for retransmits.
     */
    f -> retransmits = f -> max_configure;
    f -> backoff = 1;
    fsm_start_timer(f);
}


/***********************************************************************
 *			compress_input
 ***********************************************************************
 * SYNOPSIS:	Process a received compressed packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects idle time
 *
 * STRATEGY:	Discard packet if CCP isn't opened, else deliver
 *	    	to decompressor.
 *
 * NOTES:    	Deliver packet to decompressor even if resetting 
 *	    	because the decompressor may need to update the
 *	    	sequence number.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	8/21/96		Initial Revision
 *
 ***********************************************************************/
byte compress_input (int unit, 
		     PACKET *p,
		     int len)
{
    
    int important;
    ccp_options *ao = &ccp_allowoptions[unit];

    if (ao -> ccp_neg == 0) {
	lcp_sprotrej(unit, p, len);
	return (1);
    }    

    /*
     * Discard received compressed packets if CCP isn't up.
     */
    if (ccp_fsm[unit].state != OPENED) {
	PACKET_FREE(p);
	return (0);
    }

    important = ProcCallFixedOrMovable_pascal(unit, p, len, 
					      ccp[unit].ccp_decompressor);
    /*
     * If decompression failed, send a reset-request.
     */
    if (important < 0 ) {
	if (! ccp[unit].ccp_resetting)
	    ccp_reset(unit);
	important = 1;
    }

    return ((byte)important);

}


#endif /* USE_CCP */



