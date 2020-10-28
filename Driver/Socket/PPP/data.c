/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  data.c
 *
 * AUTHOR:  	  Jennifer Wu: May 16, 1995
 *
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/16/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions of global variables for PPP.
 *
 * 	$Id: data.c,v 1.9 97/06/12 11:01:37 jwu Exp $
 *
 ***********************************************************************/

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

#include <ppp.h>

/* ---------------------------------------------------------------------------
 *	    	    Global Variables
 -------------------------------------------------------------------------- */

char escape_map[MAP_SIZE] = { 0 }, discard_map[MAP_SIZE] = { 0 };

unsigned char *frame_buffer_pointer = (unsigned char *)0, fsm_code,
	 fsm_reply_code, *fsm_ptr, fsm_id, ip_connected = 0,
	 passive_waiting = 0, fcs_error = FALSE;

int max_retransmits = MAX_CONFIGURE,
    cf_mru = DEFMRU,	    	   /* default interface MRU */
    ppp_mode_flags = SC_FLUSH, 	   /* require a PPP flag for first frame */
    fsm_len, link_error = SDE_NO_ERROR, compressed_bytes = 0,
    frame_len = 0, idle_timeout = 0, idle_time = 0;

unsigned short input_fcs = PPP_INITFCS;

unsigned long last_time = 0L;

PACKET *frame_buffer = 0, *fsm_packet;

optr frame_buffer_optr = NullOptr;

fsm lcp_fsm[NPPP];		/* LCP fsm structure */

lcp_options lcp_wantoptions[NPPP];  /* Options that we want to request */
lcp_options lcp_gotoptions[NPPP];   /* Options that peer ack'd */
lcp_options lcp_allowoptions[NPPP]; /* Options that we allow peer to request */
lcp_options lcp_heroptions[NPPP];   /* Options that we ack'd */

lqm_t lqm[NPPP];

fsm ipcp_fsm[NPPP];

ipcp_options ipcp_wantoptions[NPPP], ipcp_gotoptions[NPPP],
    ipcp_allowoptions[NPPP], ipcp_heroptions[NPPP];

pap_state pap[NPPP];

chap_state chap[NPPP];


#ifdef USE_CCP

byte active_compress = 0;

fsm ccp_fsm[NPPP];

ccp_options ccp_wantoptions[NPPP], ccp_gotoptions[NPPP],
    ccp_allowoptions[NPPP], ccp_heroptions[NPPP];

struct ccp ccp[NPPP];

/*
 * For storing default compression values when temporarily overridden
 * by accpnt compression setting.
 */
byte default_active_comp;
WordFlags default_allowed_comp, default_want_comp;

#ifdef STAC_LZS

unsigned short perf_mode = LZS_PERFORMANCE_MODE_2;
unsigned short perf = 255;

#endif /* STAC_LZS */

#endif /* USE_CCP */



/*---------------------------------------------------------------------------
 *	    Logging Variables
 -------------------------------------------------------------------------- */

#ifdef LOGGING_ENABLED

char *shutdown_reason = (char *)0, *authentication_failure = (char *)0,
	 *negotiation_problem = (char *)0, *current_state,
	 fail_state[SHORT_STR_LEN];

int debug = 0, rx_bps = 0, tx_bps = 0, rx_percent = 100, tx_percent = 100,
    rx_bits = 0, tx_bits = 0, rx_pkts = 0, tx_pkts = 0, rx_pps = 0, tx_pps = 0,
    idle_seconds = 0, event, lcp_warnnaks = LCP_DEFWARNNAKS,
    lcp_loopback_warned = 0, ipcp_warnnaks = IPCP_DEFWARNNAKS,
    need_time = 1, rate_timer = 0;

unsigned char sess_used_lqm = 0;

unsigned long rate_date = 0L, discarded_map = 0L;

unsigned long sess_rx_octets = 0L, sess_tx_octets = 0L, sess_rx_packets = 0L,
    sess_tx_packets = 0L, sess_rx_errors = 0L, sess_tx_errors = 0L,
    sess_start = 0L;

FileHandle logfile = 0;

#ifdef USE_CCP
int ccp_warnnaks = CCP_DEFWARNNAKS;
#endif /* USE_CCP */

#endif /* LOGGING_ENABLED */
