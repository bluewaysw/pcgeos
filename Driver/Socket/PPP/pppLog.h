/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  pppLog.h
 *
 * AUTHOR:  	  Jennifer Wu: May  3, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 3/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for logging.
 *
 *
 * 	$Id: pppLog.h,v 1.8 98/06/15 14:00:04 jwu Exp $
 *
 ***********************************************************************/
#ifndef _PPPLOG_H_
#define _PPPLOG_H_

#ifdef LOGGING_ENABLED

/*
 * 	LOG() levels
 */
# define	LOG_BASE	1	/* Link status, calling attempts */
# define	LOG_DIAL	2	/* Dial chat conversations */
# define	LOG_NEG		3	/* LCP, IPCP, PAP, CHAP negotiation */
# define	LOG_LQSTAT	4	/* LQM status summaries */
# define	LOG_IF		5	/* IP interface changes */
# define	LOG_IP		6	/* IP message summaries */
# define	LOG_LQMSGS	7	/* LQM messages */
# define	LOG_MSGS	8	/* All PPP messages w/o framing */
# define	LOG_CHARS	9	/* Characters read or written */ 
# define	LOG_MISC	10	/* Procedure call messages */
# define	LOG_TIMER	11	/* Timers */

# define    	LOG(n, x)   	debug >= (n) && log x
# define    	LOG2(n, x)  	debug >= (n) && log2 x
# define    	LOG3(n, x)  	debug >= (n) && log3 x
# define    	PRINTMSG(m, l)	if (l) { m[l] = 0; LOG(1, ("%s\n", m)); }
# define    	DOLOG(code) 	code

/* 
 * Arbitrary static buffer length for log strings.
 */
# define MAX_STR_LEN	256
# define LONG_STR_LEN   128    	
# define SHORT_STR_LEN	64

# define BITS_PER_BYTE 	8

/*
 * Log string entries in logStringTable (in pppLog.goc).
 * Pass these values to the log3 routine from .c files, allowing them to
 * refer to log strings without including pppLog.goh.
 */
enum logStringTableIndex /*word*/ {
    /* general */
    LOG_ACK,
    LOG_CLIENT_TIMER,
    LOG_COLON,
    LOG_CONNECTED,
    LOG_CLOSED,
    LOG_DISCONNECTED,
    LOG_DOWN,
    LOG_FORMAT_CHAR,
    LOG_FORMAT_DEC,
    LOG_FORMAT_HEX,
    LOG_FORMAT_LONG,
    LOG_FORMAT_MIXED,
    LOG_FORMAT_STRING,
    LOG_NAK_HEX,
    LOG_NAK_VALUE,
    LOG_NEWLINE,
    LOG_NEWLINE_QUOTED,
    LOG_NEWLINE_STRING,
    LOG_NO_MEM_COMP,
    LOG_REJ,
    LOG_REPORT_PERIOD,
    LOG_RESPONSE_ONLY,
    LOG_UP,
    LOG_WARN_LOOP,

    /* LCP */
    LOG_LCP_ACOMP_NAK,
    LOG_LCP_ACOMP_REJ,
    LOG_LCP_AMAP_NAK,
    LOG_LCP_AMAP_NAK_SIMPLE,
    LOG_LCP_AMAP_REJ,
    LOG_LCP_AUTH_NAK,
    LOG_LCP_AUTH_NAK_HEX,
    LOG_LCP_AUTH_REJ,
    LOG_LCP_BAD,
    LOG_LCP_CANT_AUTH,
    LOG_LCP_CANT_MAGIC,
    LOG_LCP_CANT_MRU,
    LOG_LCP_EMPTY,
    LOG_LCP_GIVE_UP,
    LOG_LCP_GIVE_UP_AUTH,
    LOG_LCP_LQM_NAK,
    LOG_LCP_LQM_NAK_HEX,
    LOG_LCP_LQM_NAK_SIMPLE,
    LOG_LCP_LQM_REJ,
    LOG_LCP_MAGIC_NAK,
    LOG_LCP_MAGIC_NAK_SIMPLE,
    LOG_LCP_MAGIC_REJ,
    LOG_LCP_MRU_NAK,
    LOG_LCP_MRU_NAK_SIMPLE,
    LOG_LCP_MRU_REJ,
    LOG_LCP_NAK_CHAP,
    LOG_LCP_NAK_LQM,
    LOG_LCP_NAK_PAP,
    LOG_LCP_NO_AMAP,
    LOG_LCP_NO_AUTH, 
    LOG_LCP_NO_LQM,
    LOG_LCP_NO_MRU,
    LOG_LCP_PCOMP_NAK,
    LOG_LCP_PCOMP_REJ,
    LOG_LCP_RECV_ACOMP,
    LOG_LCP_RECV_AMAP,
    LOG_LCP_RECV_AUTH,
    LOG_LCP_RECV_LQM,
    LOG_LCP_RECV_MAGIC,
    LOG_LCP_RECV_MRU,
    LOG_LCP_RECV_PCOMP,
    LOG_LCP_REJ,
    LOG_LCP_REPLY,
    LOG_LCP_SEND_ACOMP,
    LOG_LCP_SEND_AMAP,
    LOG_LCP_SEND_AUTH,
    LOG_LCP_SEND_LQM,
    LOG_LCP_SEND_MAGIC,
    LOG_LCP_SEND_MRU,
    LOG_LCP_SEND_PCOMP,
    LOG_LCP_TRUNC_REJ,
    LOG_LCP_UNKNOWN_NAK,
    LOG_LCP_UNKNOWN_OPT,

    /* IPCP */
    LOG_IPCP_ADD_NAK_ADDR,
    LOG_IPCP_ADD_NAK_ADDRS,
    LOG_IPCP_ADDR,
    LOG_IPCP_ADDRS,
    LOG_IPCP_ADDR_PEER,
    LOG_IPCP_ADDR_PEER2,
    LOG_IPCP_ADDRS_PEER,
    LOG_IPCP_ADDRS_US,
    LOG_IPCP_BAD,
    LOG_IPCP_DNS_ADDR,
    LOG_IPCP_EMPTY,
    LOG_IPCP_GIVE_UP,
    LOG_IPCP_GIVE_UP_ADDR,
    LOG_IPCP_GIVE_UP_ADDR_NEW,
    LOG_IPCP_GIVE_UP_COMP,
    LOG_IPCP_NAK_ADDR,
    LOG_IPCP_NAK_ADDRS,
    LOG_IPCP_NAK_ADDRS_SIMPLE,
    LOG_IPCP_NAK_COMP,
    LOG_IPCP_NAK_COMP_SIMPLE,
    LOG_IPCP_NAK_DNS,
    LOG_IPCP_NO_ADDR,
    LOG_IPCP_NO_ADDRS,
    LOG_IPCP_NO_COMP,
    LOG_IPCP_RECV_ADDR,
    LOG_IPCP_RECV_ADDRS,
    LOG_IPCP_RECV_COMP,
    LOG_IPCP_RECV_DNS,

    LOG_IPCP_REJ_ADDR,
    LOG_IPCP_REJ_ADDRS,
    LOG_IPCP_REJ_COMP,
    LOG_IPCP_REJ_DNS,
    LOG_IPCP_REVERTING,
    LOG_IPCP_REPLY,
    LOG_IPCP_SEND_ADDR,
    LOG_IPCP_SEND_ADDRS,
    LOG_IPCP_SEND_COMP,
    LOG_IPCP_SEND_DNS,
    LOG_IPCP_SLOT_ID,
    LOG_IPCP_SLOTS,
    LOG_IPCP_TOO_SHORT,
    LOG_IPCP_UNKNOWN_NAK,
    LOG_IPCP_UNKNOWN_OPT,
    LOG_IPCP_WRONG_ADDR,
    LOG_IPCP_WRONG_COMP_TYPE,
    LOG_IPCP_WRONG_SLOT,


    /* IP */
    LOG_IP_NOT_OK,
    LOG_VJ_DECOMP_FAILED,
    LOG_VJ_UNEXPECTED,

    /* chap */
    LOG_CHAP_FAILED,
    LOG_CHAP_LOWER_NOT_UP,
    LOG_CHAP_MISMATCHED_LEN,
    LOG_CHAP_NO_NAME,
    LOG_CHAP_PEER,
    LOG_CHAP_RCVD,
    LOG_CHAP_SENDING,
    LOG_CHAP_SHORT_CHALLENGE,
    LOG_CHAP_SHORT_HDR,
    LOG_CHAP_SHORT_LEN,
    LOG_CHAP_SHORT_RESPONSE,
    LOG_CHAP_UNEXPECTED,

    /* pap */
    LOG_PAP_BAD,
    LOG_PAP_FAILED,
    LOG_PAP_MISMATCHED_LEN,
    LOG_PAP_NO_MEM,
    LOG_PAP_NO_NAME,
    LOG_PAP_NO_USERNAME,
    LOG_PAP_PEER_IS,
    LOG_PAP_RECV_AUTH,
    LOG_PAP_SENDING,
    LOG_PAP_SHORT,
    LOG_PAP_SHORT_HDR,
    LOG_PAP_SHORT_LEN,
    LOG_PAP_UNEXPECTED,
    LOG_PAP_UNEXPECTED_SHORT,
    LOG_PAP_WRONG_ID,

    /* lqm */
    LOG_LQM_ECHO,
    LOG_LQM_LAST_OUT,
    LOG_LQM_LOST,
    LOG_LQM_LOST_ECHO,
    LOG_LQM_LQR,
    LOG_LQM_MAGIC,
    LOG_LQM_PACKET,
    LOG_LQM_PEER_CHANGED,
    LOG_LQM_PEER_IN,
    LOG_LQM_PEER_IN2,
    LOG_LQM_PEER_IN3,
    LOG_LQM_PEER_OUT,
    LOG_LQM_RECVING,
    LOG_LQM_REJ,
    LOG_LQM_SAVE_IN,
    LOG_LQM_SAVE_IN2,
    LOG_LQM_SAVE_IN3,
    LOG_LQM_SENDING,
    LOG_LQM_WARN_LOOP,

    /* ccp */
    LOG_CCP_BAD,
    LOG_CCP_CANT_DO_STAC,
    LOG_CCP_GIVE_UP,
    LOG_CCP_GOT_OPT,
    LOG_CCP_HISTORY_CHECK,
    LOG_CCP_MPPC_BITS,
    LOG_CCP_NAK_HISTORY_CHECK,
    LOG_CCP_NAK_MPPC_BITS,
    LOG_CCP_NO_MEM_WARN,
    LOG_CCP_PEER_NAK_MPPC,
    LOG_CCP_PEER_NO_MPPC,
    LOG_CCP_PEER_NAK_PRED1,
    LOG_CCP_PEER_NO_PRED1,
    LOG_CCP_PEER_NAK_STAC,
    LOG_CCP_PEER_NAK_STAC_SIMPLE,
    LOG_CCP_PEER_NO_STAC,
    LOG_CCP_PEER_REJ_MPPC,
    LOG_CCP_PEER_REJ_PRED1,
    LOG_CCP_PEER_REJ_STAC,
    LOG_CCP_REJ_WRONG,
    LOG_CCP_REPLY,
    LOG_CCP_SEND_MPPC,
    LOG_CCP_SEND_PRED1,
    LOG_CCP_SEND_STAC,
    LOG_CCP_UNKNOWN_NAK,
    LOG_CCP_UNKNOWN_OPTION,

    /* stac */
    LOG_STAC_ALLOC_FAILED,
    LOG_STAC_DECOMP_FAILED,
    LOG_STAC_DECOMP_BAD,
    LOG_STAC_EXPANDED,
    LOG_STAC_NO_MEM,
    LOG_STAC_UNCOMPRESSED,
    LOG_STAC_SEND_NATIVE,

    /* pred1 */
    LOG_PRED1_COMP_ALLOC,
    LOG_PRED1_COMP_BUF_EXPANDED,
    LOG_PRED1_DECOMP_ALLOC,
    LOG_PRED1_DECOMP_BAD_LEN,
    LOG_PRED1_DECOMP_BAD_FCS,
    LOG_PRED1_DECOMP_FCS,
    LOG_PRED1_DECOMP_TOO_SHORT,

    /* MPPC */
    LOG_MPPC_ALLOC_FAILED,
    LOG_MPPC_DECOMP_BAD_COUNT,
    LOG_MPPC_DECOMP_FAILED,
    LOG_MPPC_DECOMP_FLUSHED,
    LOG_MPPC_DECOMP_HISTORY_RESTARTED,
    LOG_MPPC_DOWN,
    LOG_MPPC_EXPANDED,
    LOG_MPPC_NO_MEM,
    LOG_MPPC_RESETCOMP,
    LOG_MPPC_RESETDECOMP,
    LOG_MPPC_RESTART_HISTORY,
    LOG_MPPC_UNCOMPRESSED,

};


extern char *shutdown_reason, *authentication_failure, *negotiation_problem,
    *current_state, fail_state[];

extern int debug, rx_bps, tx_bps, rx_percent, tx_percent, rx_bits,
    tx_bits, rx_pkts, tx_pkts, rx_pps, tx_pps, idle_seconds, event, 
    lcp_warnnaks, lcp_loopback_warned, ipcp_warnnaks, need_time, rate_timer;

extern unsigned char sess_used_lqm;

extern unsigned long rate_date, discarded_map;

extern unsigned long sess_rx_octets, sess_tx_octets, sess_rx_packets,
    sess_tx_packets, sess_rx_errors, sess_tx_errors, sess_start;

extern FileHandle logfile;

/*
 * log_buffer is in ip.c.
 */
extern void log_buffer ();


/*
 * These routines are in pppLog.goc.
 */
extern void OpenLogFile (), LogTimeStamp (), new_state (), log_state (),
    elapsed_time (), print_acct (), asyncmap_name (), time_rates (),
    log_idle ();

extern int _cdecl log (const char *format, ...);
extern int _cdecl log2 (optr format, ...);
extern int _cdecl log3 (word entry, ...);

#ifdef USE_CCP
extern int ccp_warnnaks; 
#endif /* USE_CCP */


#else	/* LOGGING_ENABLED */

# define    	LOG(n, x)
# define    	LOG2(n, x)
# define    	LOG3(n, x)
# define    	PRINTMSG(m, l)
# define    	DOLOG(code)

#endif  /* LOGGING_ENABLED */

#endif /* _PPPLOG_H_ */

