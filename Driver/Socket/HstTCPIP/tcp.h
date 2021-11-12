/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  tcp.h
 * FILE:	  tcp.h
 *
 * AUTHOR:  	  Jennifer Wu: Jul  6, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 6/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for TCP.
 *
 *
 * 	$Id: tcp.h,v 1.1 97/04/18 11:57:06 newdeal Exp $
 *
 ***********************************************************************/
/*
 * Copyright (c) 1982, 1986, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */

#ifndef _TCP_H_
#define _TCP_H_

typedef dword tcp_seq;	    	/* sequence number */

/* ---------------------------------------------------------------------------
 *
 *	Structure of TCP header.
 *
 -------------------------------------------------------------------------- */
struct tcphdr {
    	    	    /* src and dst port numbers (which are no longer needed
		     * once we've located the connection) are overlaid with 
		     * optr of buffer when in reassembly queue 
		     */
    	word	th_sport;   	    /* source port */	
	word	th_dport;   	    /* destination port */
	tcp_seq	th_seq;	    	    /* sequence number */
	tcp_seq	th_ack;	    	    /* acknowledgment number */
	byte   	th_x2:4,    	    /* (unused) */
	    	th_off:4;    	    /* data offset (a.k.a. header length) */
	byte 	th_flags;
	word	th_win;	    	    /* window size */
	word	th_cksum;	    /* checksum */
	word	th_urp;	    	    /* urgent pointer */
};

/* ---------------------------------------------------------------------------
 *	TCP Flags 
 * ------------------------------------------------------------------------- */
#define	TH_FIN	    0x01
#define	TH_SYN	    0x02
#define	TH_RST	    0x04
#define	TH_PUSH	    0x08
#define	TH_ACK	    0x10
#define	TH_URG	    0x20

/* --------------------------------------------------------------------------
 *	TCP Options
 * ----------------------------------------------------------------------- */
#define	TCPOPT_EOL  	0
#define	TCPOPT_NOP  	1
#define	TCPOPT_MAXSEG	2
#define	    TCPOLEN_MAXSEG  	4
#define	TCPOPT_WINDOW	3
#define	    TCPOLEN_WINDOW  	3
#define	TIMESTAMP   	8
#define	    TCPOLEN_TIMESTAMP	10
#define	    TCPOLEN_TSTAMP_APPA	    (TCPLOEN_TIMESTAMP+2)   
                                         /* appendix A of RFC 1323*/

#define	TCPOPT_TSTAMP_HDR   \
    (TCPOPT_NOP<<24|TCPOPT_NOP<<16|TCPOPT_TIMESTAMP<<8|TCPOLEN_TIMESTAMP)

/* -------------------------------------------------------------------------
 * Defaults for TCP.
 ------------------------------------------------------------------------- */
#define	TCP_MSS	512 	    	/* default maximum segment size */

#define	TCP_MAXWIN  65535   	/* largest value for window */

#define TCP_RECV_WIN  4096    	/* default value for receive window */

           /* some defines to make accessing tcpiphdr fields easier */
#define	ti_next		ti_i.ih_next
#define	ti_prev		ti_i.ih_prev
#define	ti_x1		ti_i.ih_x1
#define	ti_pr		ti_i.ih_pr
#define	ti_len		ti_i.ih_len
#define	ti_src		ti_i.ih_src
#define	ti_dst		ti_i.ih_dst
#define	ti_sport	ti_t.th_sport
#define	ti_dport	ti_t.th_dport
#define	ti_seq		ti_t.th_seq
#define	ti_ack		ti_t.th_ack
#define	ti_x2		ti_t.th_x2
#define	ti_off		ti_t.th_off
#define	ti_flags	ti_t.th_flags
#define	ti_win		ti_t.th_win
#define	ti_cksum	ti_t.th_cksum
#define	ti_urp		ti_t.th_urp

#define ti_bufMH    ti_t.th_sport   	/* handle of data buffer */
#define ti_bufCH    ti_t.th_dport   	/* chunk of data buffer */


/* -----------------------------------------------------------------------
 *	TCP TIMERS
 * 
 * Definitions of the TCP timers.  These timers are counters that get
 * decremented whenever the timer goes off.
 *
 * The TCPT_REXMT timer is used to force retransmissions.
 * The TCP has the TCPT_REXMT timer set whenever segments
 * have been sent for which ACKs are expected but not yet
 * received.  If an ACK is received which advances tp->snd_una,
 * then the retransmit timer is cleared (if there are no more
 * outstanding segments) or reset to the base value (if there
 * are more ACKs expected).  Whenever the retransmit timer goes off,
 * we retransmit one unacknowledged segment, and do a backoff
 * on the retransmit timer.
 *
 * The TCPT_PERSIST timer is used to keep window size information
 * flowing even if the window goes shut.  If all previous transmissions
 * have been acknowledged (so that there are no retransmissions in progress),
 * and the window is too small to bother sending anything, then we start
 * the TCPT_PERSIST timer.  When it expires, if the window is nonzero,
 * we go to transmit state.  Otherwise, at intervals send a single byte
 * into the peer's window to force him to update our window information.
 * We do this at most as often as TCPT_PERSMIN time intervals,
 * but no more frequently than the current estimate of round-trip
 * packet time.  The TCPT_PERSIST timer is cleared whenever we receive
 * a window update from the peer.
 *
 * The TCPT_KEEP timer is used to keep connections alive.  If an
 * connection is idle (no segments received) for TCPTV_KEEP_INIT amount of time,
 * but not yet established, then we drop the connection.  Once the connection
 * is established, if the connection is idle for TCPTV_KEEP_IDLE time
 * (and keepalives have been enabled on the socket), we begin to probe
 * the connection.  We force the peer to send us a segment by sending:
 *	<SEQ=SND.UNA-1><ACK=RCV.NXT><CTL=ACK>
 * This segment is (deliberately) outside the window, and should elicit
 * an ack segment in response from the peer.  If, despite the TCPT_KEEP
 * initiated segments we cannot elicit a response from a peer in TCPT_MAXIDLE
 * amount of time probing, then we drop the connection.
 *
 ---------------------------------------------------------------------- */
#define	TCPT_NTIMERS	4

#define	TCPT_REXMT	0		/* retransmit */
#define	TCPT_PERSIST	1		/* retransmit persistance */
#define	TCPT_KEEP	2		/* keep alive */
#define	TCPT_2MSL	3		/* 2*msl quiet time timer */

/*
 * Time constants.  All TCPTV values are counters which get decremented
 * every timeout.  TIMEOUT_INTERVAL is the interval between timeouts for the
 * timer.
 */
#define TCPIP_TIMEOUT_INTERVAL  30     	    /* 30 ticks is half a second */
#define TCPIP_TIMEOUT_PER_SEC	2

#define	TCPTV_MSL	 60 	    		/* max seg lifetime (hah!) */
    	    	    	    	    	    	/*   about 30 seconds */
#define	TCPTV_SRTTBASE	0			/* base roundtrip time;
						   if 0, no idea yet */
#define	TCPTV_SRTTDFLT	 6  	    		/* assumed RTT if no info */

#define	TCPTV_PERSMIN	10  	    		/* retransmit persistance */
#define	TCPTV_PERSMAX	120 	    		/* maximum persist interval */

#define	TCPTV_KEEP_INIT	150 	    		/* initial connect keep alive */

#define	TCPTV_KEEP_IDLE	(120*60*2)  		/* dflt time before probing */
                                                /* 2 hours */
 
#define	TCPTV_KEEPINTVL	150 	    		/* default probe interval */
                                                /* 75 seconds */
#define	TCPTV_KEEPCNT	8			/* max probes before drop */

#define TCPTV_MIN	10   	    	    	/* min rexmt interval: 1 sec */
#define	TCPTV_REXMTMAX	128 	    		/* max allowable REXMT value */

#define	TCP_LINGERTIME	120*2			/* linger at most 2 minutes */

#define	TCP_MAXRXTSHIFT	12			/* maximum retransmits */

/*
 * Force a time value to be in a certain range.
 */
#define	TCPT_RANGESET(tv, value, tvmin, tvmax) { \
	(tv) = (value); \
	if ((tv) < (tvmin)) \
		(tv) = (tvmin); \
	else if ((tv) > (tvmax)) \
		(tv) = (tvmax); \
}

extern word tcprexmtthresh; 	/* maximum duplicate acks for a fast rexmt */
extern word tcp_keepidle;	/* time before keepalive probes begin */
extern word tcp_keepintvl;	/* time between keepalive  probes */
extern word tcp_maxidle;        /* time to drop after starting probes */
extern word tcp_maxrxt;	        /* maximum # of retransmissions */
extern word tcp_minRxmt;    	/* minimum restransmit interval */

extern word tcp_backoff[TCP_MAXRXTSHIFT+1]; 

extern word	tcp_mssdflt;	/* default maximum segment size */
extern word	tcp_rttdflt;	/* default roundtrip time estimate */
                                /*  (in intervals) */

extern dword	tcp_maxwin; 	/* maximum TCP window size */

extern byte 	tcp_keeplen;	/* length of keepalive probe */

/* ------------------------------------------------------------------------
 *
 * Structure of TCP control block.
 *
 * --------------------------------------------------------------------- */
struct tcpcb {
	struct	tcpiphdr *seg_next;	/* sequencing/reassembly queue */
	struct	tcpiphdr *seg_prev;
	sdword	rqueue_size;      	/* amount of data in sequencing queue */

	word	t_state;		/* state of this connection */
	word	t_timer[TCPT_NTIMERS];	/* tcp timers */
	word	t_rxtshift;		/* log(2) of rexmt exp. backoff */
	word	t_rxtcur;		/* current retransmit value */
	word	t_dupacks;		/* consecutive dup acks recd */
	word	t_maxseg;		/* maximum segment size we can send */
	word	t_maxwin;   	    	/* maximum receive buffer */
	byte	t_force;		/* 1 if forcing out a byte */
	word	t_flags;    	    	
#define	TF_ACKNOW	0x0001		/* ack peer immediately */
#define	TF_DELACK	0x0002		/* ack, but try to delay it */
#define	TF_NODELAY	0x0004		/* don't delay packets to coalesce */
#define	TF_NOOPT	0x0008		/* don't use tcp options */
#define	TF_SENTFIN	0x0010		/* have sent FIN */
#define	TF_REQ_SCALE	0x0020		/* have/will request window scaling */
#define	TF_RCVD_SCALE	0x0040		/* other side has requested scaling */
#define	TF_REQ_TSTMP	0x0080		/* have/will request timestamps */
#define	TF_RCVD_TSTMP	0x0100		/* a timestamp was received in SYN */
#define	TF_SACK_PERMIT	0x0200		/* other side said I could SACK */
	
	struct	tcpiphdr t_template;	/* skeletal header for transmit */

/* send sequence variables */
	tcp_seq	snd_una;		/* send unacknowledged */
	tcp_seq	snd_nxt;		/* send next */
	tcp_seq	snd_up;			/* send urgent pointer */
	tcp_seq	snd_wl1;		/* seg seq # used for last win update */
	tcp_seq	snd_wl2;		/* seg ack # used for last window */
	tcp_seq	iss;			/* initial send sequence number */
	dword	snd_wnd;		/* send window */

/* receive sequence variables */
	dword	rcv_wnd;		/* receive window */
	tcp_seq	rcv_nxt;		/* receive next */
	tcp_seq	rcv_up;			/* receive urgent pointer */
	tcp_seq	irs;			/* initial receive sequence number */
	tcp_seq	rcv_adv;		/* advertised window */
 	sdword	rcv_buf;   	    	/* space in socket lib's recv buffer, 
					   adjusted for link connections and
					   data in reassembly queue*/

/* retransmit variables */
	tcp_seq	snd_max;		/* highest sequence number sent;
					 * used to recognize retransmits
					 */
/* congestion control (for slow start, source quench, retransmit after loss) */
	dword	snd_cwnd;		/* congestion-controlled window */
	dword	snd_ssthresh;		/* snd_cwnd size threshhold for
					 * for slow start exponential to
					 * linear switch
					 */
/*
 * transmit timing stuff.  See below for scale of srtt and rttvar.
 * "Variance" is actually smoothed difference.
 */
	word	t_idle;			/* inactivity time */
	word	t_rtt;			/* round trip time */
	tcp_seq	t_rtseq;		/* sequence number being timed */
	word	t_srtt;			/* smoothed round-trip time */
	word	t_rttvar;		/* variance in round-trip time */
	word	t_rttmin;		/* minimum rtt allowed */
	dword	max_sndwnd;		/* largest window peer has offered */

	word	t_ttl;	    	    	/* time to live of ip packets */
	byte	t_inline;   	    	/* keep urgent byte in data stream */
	word	t_softerror;		/* possible error not yet reported */

	tcp_seq	last_ack_sent;

};

/*--------------------------------------------------------------------------
 * The smoothed round-trip time and estimated variance are stored as fixed
 * point numbers and scaled by the values below.  For convenience, these
 * scales are used in smoothing the average 
 * (smoothed = (1/scale)sample + ((scale-1)/scale)smoothed).
 * With these scales, srtt has 3 bits to the right of the binary point,
 * and thus an "ALPHA" of 0.875.  rttvar has 2 bits to the right of the
 * binary point, and is smoothed with an ALPHA of 0.75.
 * 
 * scale = 2^shift
 * ALPHA = 1 - (1/(scale)) = ((scale -1)/scale)
 *
 * TCP_RTT_SCALE and TCP_RTTVAR_SCALE aren't actually used...  
 * ---------------------------------------------------------------------- */
extern word rttShift;
extern word rttvarShift;

#define	TCP_RTT_SCALE	    	8    	/* multiplier for srtt; 3 bits frac. */
#define TCP_DFLT_RTT_SHIFT  	3   	/* produces an alpha of 0.875 */
#define	TCP_RTT_SHIFT	    rttShift	/* shift for srtt; 3 bits frac. */
#define	TCP_RTTVAR_SCALE     	4	/* multiplier for rttvar; 2 bits */
#define TCP_DFLT_RTT_VAR_SHIFT	2   	/* produces an alpha of 0.75 */
#define	TCP_RTTVAR_SHIFT    rttvarShift	/* shift for rttvar; 2 bits */

/*
 * The initial retransmission should happen at rtt + 4 * rttvar.
 */
#define	TCP_REXMTVAL(tp) \
	(((tp)->t_srtt >> TCP_RTT_SHIFT) + \
	 4 * ((tp)->t_rttvar >> TCP_RTTVAR_SHIFT))



/* ------------------------------------------------------------------------
 *
 * TCP FSM state definitions
 * Per RFC793, September, 1981.
 *
 ---------------------------------------------------------------------- */
#define	TCP_NSTATES	11

#define	TCPS_CLOSED		0	/* closed */
#define	TCPS_LISTEN		1	/* listening for connection */
#define	TCPS_SYN_SENT		2	/* active, have sent syn */
#define	TCPS_SYN_RECEIVED	3	/* have send and received syn */
    /* states < TCPS_ESTABLISHED are those where connections not established */
#define	TCPS_ESTABLISHED	4	/* established */
#define	TCPS_CLOSE_WAIT		5	/* rcvd fin, waiting for close */
    /* states > TCPS_CLOSE_WAIT are those where user has closed */
#define	TCPS_FIN_WAIT_1		6	/* have closed, sent fin */
#define	TCPS_CLOSING		7	/* closed xchd FIN; await FIN ACK */
#define	TCPS_LAST_ACK		8	/* had fin and close; await FIN ACK */
    /* states > TCPS_CLOSE_WAIT && < TCPS_FIN_WAIT_2 await ACK of FIN */
#define	TCPS_FIN_WAIT_2		9	/* have closed, fin is acked */
#define	TCPS_TIME_WAIT		10	/* in 2*msl quiet wait after close */

#define	TCPS_HAVERCVDSYN(s)	((s) >= TCPS_SYN_RECEIVED)
#define	TCPS_HAVERCVDFIN(s)	((s) >= TCPS_TIME_WAIT)



/*-----------------------------------------------------------------------
 * Flags used when sending segments in tcp_output.
 * Basic flags (TH_RST,TH_ACK,TH_SYN,TH_FIN) are totally
 * determined by state, with the proviso that TH_FIN is sent only
 * if all data queued for output is included in the segment.
 ---------------------------------------------------------------------- */
extern byte	tcp_outflags[TCP_NSTATES]; 

/* -----------------------------------------------------------------------
 *
 *	TCP SEQUENCE NUMBERS
 * 
 * TCP sequence numbers are 32 bit integers operated on with modular 
 * arithmetic.  These macros can be used to compare such integers.
 *
 *--------------------------------------------------------------------- */

#define	SEQ_LT(a,b)	((sdword)((a)-(b)) < 0)
#define	SEQ_LEQ(a,b)	((sdword)((a)-(b)) <= 0)
#define	SEQ_GT(a,b)	((sdword)((a)-(b)) > 0)
#define	SEQ_GEQ(a,b)	((sdword)((a)-(b)) >= 0)

/*----------------------------------------------------------------------
 * Macros to initialize tcp sequence numbers for
 * send and receive from initial send and receive
 * sequence numbers.
---------------------------------------------------------------------- */
#define	tcp_rcvseqinit(tp) \
	(tp)->rcv_adv = (tp)->rcv_nxt = (tp)->irs + 1

#define	tcp_sendseqinit(tp) \
	(tp)->snd_una = (tp)->snd_nxt = (tp)->snd_max = (tp)->snd_up = \
	    (tp)->iss

#define min(a, b)   ((a) < (b) ? (a) : (b))
#define max(a, b)   ((a) > (b) ? (a) : (b))



/*------------------------------------------------------------------------
 *
 * TCP statistics.
 * Many of these should be kept per connection, but that's inconvenient 
 * at the moment.
 *
 ----------------------------------------------------------------------- */
#ifdef LOG_STATS

struct	tcpstat {
	word	tcps_connattempt;	/* connections initiated */
	word	tcps_accepts;		/* connections accepted */
	word	tcps_connects;		/* connections established */
	word	tcps_drops;		/* connections dropped */
	word	tcps_conndrops;	    	/* embryonic connections dropped */
	word	tcps_closed;		/* conn. closed (includes drops) */
	word	tcps_segstimed;		/* segs where we tried to get rtt */
	word	tcps_rttupdated;	/* times we succeeded */
	word	tcps_delack;		/* delayed acks sent */
	word	tcps_timeoutdrop;	/* conn. dropped in rxmt timeout */
	word	tcps_rexmttimeo;	/* retransmit timeouts */
	word	tcps_persisttimeo;	/* persist timeouts */
	word	tcps_keeptimeo;		/* keepalive timeouts */
	word	tcps_keepprobe;		/* keepalive probes sent */
	word	tcps_keepdrops;		/* connections dropped in keepalive */

	word	tcps_sndtotal;		/* total packets sent */
	word	tcps_sndpack;		/* data packets sent */
	word	tcps_sndbyte;		/* data bytes sent */
	word	tcps_sndrexmitpack;	/* data packets retransmitted */
	word	tcps_sndrexmitbyte;	/* data bytes retransmitted */
	word	tcps_sndacks;		/* ack-only packets sent */
	word	tcps_sndprobe;		/* window probes sent */
	word	tcps_sndurg;		/* packets sent with URG only */
	word	tcps_sndwinup;		/* window update-only packets sent */
	word	tcps_sndctrl;		/* control (SYN|FIN|RST) packets sent */

	word	tcps_rcvtotal;		/* total packets received */
	word	tcps_rcvpack;		/* packets received in sequence */
	word	tcps_rcvbyte;		/* bytes received in sequence */
	word	tcps_rcvbadsum;		/* packets received with ccksum errs */
	word	tcps_rcvbadoff;		/* packets received with bad offset */
	word	tcps_rcvshort;		/* packets received too short */
	word	tcps_rcvduppack;	/* duplicate-only packets received */
	word	tcps_rcvdupbyte;	/* duplicate-only bytes received */
	word	tcps_rcvpartduppack;	/* packets with some duplicate data */
	word	tcps_rcvpartdupbyte;	/* dup. bytes in part-dup. packets */
	word	tcps_rcvoopack;		/* out-of-order packets received */
	word	tcps_rcvoobyte;		/* out-of-order bytes received */
	word	tcps_rcvpackafterwin;	/* packets with data after window */
	word	tcps_rcvbyteafterwin;	/* bytes rcvd after window */
	word	tcps_rcvafterclose;	/* packets rcvd after "close" */
	word	tcps_rcvwinprobe;	/* rcvd window probe packets */
	word	tcps_rcvdupack;		/* rcvd duplicate acks */
	word	tcps_rcvacktoomuch;	/* rcvd acks for unsent data */
	word	tcps_rcvackpack;	/* rcvd ack packets */
	word	tcps_rcvackbyte;	/* bytes acked by rcvd acks */
	word	tcps_rcvwinupd;		/* rcvd window update packets */
};

extern struct	tcpstat	tcpstat;    	/* tcp statistics */

#endif /* LOG_STATS */

#endif /* _TCP_H_ */




