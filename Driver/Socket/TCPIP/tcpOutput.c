/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  TCP/IP driver
 * FILE:	  tcpOutput.c
 *
 * AUTHOR:  	  Jennifer Wu: Jul 26, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	TcpOutput   	    Main TCP output routine.
 *	TcpRespond  	    Send a single message to the TCP.  Used
 *	    	    	    to force keep alive messages out using TCP
 *	    	    	    template.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/26/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Output routines for TCP protocol.  Implementation based on BSD.
 *
 *	$Id: tcpOutput.c,v 1.1 97/04/18 11:57:06 newdeal Exp $
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

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

#include <geos.h>
#include <resource.h>
#include <Ansi/string.h>
#include <lmem.h>
#include <timer.h>
#include <timedate.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <tcp.h>
#include <tcpip.h>
#include <tcpipLog.h>

#ifdef __HIGHC__
#pragma Code("TCPOUTCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg TCPOUTCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("TCPOUTCODE")
#endif

#define MAX_TCPOPTLEN 32    	    /* max # bytes that go in options */


/***********************************************************************
 *				TcpOutput
 ***********************************************************************
 * SYNOPSIS:	TCP output routine:  figure out what should be sent
 *	    	and send it.
 * CALLED BY:	EXTERNAL
 * PASS:    	tp  	= optr of TCB for connection
 *	    	socket	= connection handle
 * RETURN:	0 if no error, else SocketDrError
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    	Only the max seg option is supported.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/26/94		Initial Revision
 *
 ***********************************************************************/
word
TcpOutput(optr tp, word socket)
{
    struct tcpcb *tcb;
    sdword len, win;
    word off, flags, error;
    struct tcpiphdr *ti;
    byte opt[MAX_TCPOPTLEN];
    word optlen, hdrlen, idle, sendalot, totalLen = 0;
    optr dataBuf;
    MbufHeader *m;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */

     TcpipLock(OptrToHandle(tp));
     tcb = (struct tcpcb *)LMemDeref(tp);

     /*
      * Determine length of data that should be transmitted, and flags
      * that will be used.
      */
    idle = (tcb->snd_max == tcb->snd_una);  	/* true if no unacked data */
    if (idle && tcb->t_idle >= tcb->t_rxtcur)
	 /*
	  * We have been idle for "a while" and no acks are expected
	  * to clock out any data we send -- slow start to get ack
	  * "clock" running again.
	  */
	tcb->snd_cwnd = tcb->t_maxseg;

again:
    sendalot = 0;
    off = tcb->snd_nxt - tcb->snd_una;
    win = min(tcb->snd_wnd, tcb->snd_cwnd); 	    /* send win */

    flags = tcp_outflags[tcb->t_state];

     /*
      * If in persist timeout with window of 0, send 1 byte.
      * Otherwise, if window is small but nonzero and timer
      * expired, we will send what we can and go to transmit state.
      */
    totalLen = TSocketGetOutputSize(socket);
    if (tcb->t_force) {
	if (win == 0) {
	    /*
	     * If we still have some data to send, then clear the FIN bit.
	     */
	    if (off < totalLen)
		flags &= ~TH_FIN;
	    win = 1;	    	    	    	    /* send win */
	} else {
	    tcb->t_timer[TCPT_PERSIST] = 0;
	    tcb->t_rxtshift = 0;
	}
    }

    len = min(totalLen, win) - off;

    if (len < 0) {
	/*
	 * If FIN has been sent but not acked, but we haven't been
	 * called to retransmit, len will be -1.  Otherwise, window
	 * shrank after we sent into it.  If window shrank to 0,
	 * cancel pending retransmit and pull snd_nxt back to (closed)
	 * window.  We will enter persist state below.  If the window
	 * didn't close completely, just wait for an ACK.
	 */
	len = 0;
	if (win == 0) {
	    tcb->t_timer[TCPT_REXMT] = 0;
	    tcb->snd_nxt = tcb->snd_una;
	}
    }

    if (len > tcb->t_maxseg) {
	len = tcb->t_maxseg;
	sendalot = 1;
    }

    /*
     * If we are not sending all the data, then clear the FIN.
     */
    if (SEQ_LT(tcb->snd_nxt + len, tcb->snd_una + totalLen))
	flags &= ~TH_FIN;

    /*
     * Determine the receive window.  If we think the amount of
     * space is less than a maximum segment, query the socket library
     * to see if the window has opened up since then.  Update our
     * value for the current receive window with the new value.
     *
     * Note: We used to only query if our idea of the window is zero,
     * but if the available space is less than the maximum segment size,
     * the advertised window will be zero to avoid silly window syndrome.
     * This caused us to always advertise a zero window without ever
     * querying the socket library for an update on available space.
     *      	    	    	    	    - jwu 3/29/96
     */
    if (tcb->rcv_buf < tcb->t_maxseg &&
	tcb->t_state != TCPS_TIME_WAIT) {
	    /*
	     * Don't call the socket library if in TIME_WAIT state because
	     * we just told the socket library to destroy the connection
	     * in TcpInput when we processed the FIN.  Most cases, the
	     * receive window will no longer be zero so we wouldn't even
	     * get here, but let's check the state to be safe.  --jwu  2/29/96
	     */
    	tcb->rcv_buf = TSocketGetRecvWin(socket) - tcb->rqueue_size;
	if (tcb->rcv_buf < 0)
	    tcb->rcv_buf = 0;
    }

    win = tcb->rcv_buf;

    /*
     * Sender silly window avoidance.  If connection is idle and
     * can send all data, a maximum segment, at least a maximum
     * default-size segment, do it.  If we are forcing output, do it.
     * Otherwise don't bother.  If peer's buffer is tiny, then send
     * when window is at least half open.  If retransmitting (possibly
     * after persist timer forced us to send into a small window),
     * then must resend.
     */
    if (len) {
	if (len == tcb->t_maxseg)
	    goto send;
	if ((idle || tcb->t_flags & TF_NODELAY) &&
	    len + off >= totalLen)
	    goto send;
	if (tcb->t_force)
	    goto send;
	if (len >= tcb->max_sndwnd / 2)     	    /* not a small segment */
	    goto send;
	if (SEQ_LT(tcb->snd_nxt, tcb->snd_max))	    /* retransmitting */
	    goto send;
    }

    /*
     * Compare available window to amount of window known to peer
     * (as advertised window less next expected input).  If the
     * difference is at least 2 max size segments, or at least 50%
     * of the maximum possible window, then want to send a window
     * update to peer.
     */
    if (win > 0) {
	/*
	 * "adv" is the amount we can increase the window, taking
	 * into account that we are limited by the maximum TCP window size.
	 */
	sdword adv = min(win, tcp_maxwin) - (tcb->rcv_adv - tcb->rcv_nxt);
	if (adv >= (dword)(2 * tcb->t_maxseg))
	    goto send;
	if (2 * adv >= tcp_maxwin)
	    goto send;
    }

    /*
     * Send if we owe peer an ACK, if we have control flags (SYN or RST)
     * or if we have urgent data.
     */
    if (tcb->t_flags & TF_ACKNOW)
	goto send;

    if (flags & (TH_SYN|TH_RST))
	goto send;

    if (SEQ_GT(tcb->snd_up, tcb->snd_una))
	goto send;

    /*
     * If our state indicates that FIN should be sent and we have
     * not yet done so, or we're retransmitting the FIN, then send.
     */
    if (flags & TH_FIN &&
	((tcb->t_flags & TF_SENTFIN) == 0 || tcb->snd_nxt == tcb->snd_una))
	goto send;

    /*
     * TCP window updates are not reliable, rather a polling protocol
     * using "persist" packets is used to insure receipt of window
     * updates.  The three "states" for the output side are:
     * 	idle	    	    not doing retransmits or persists
     * 	persisting  	    to move a small or zero window
     * 	(re)transmitting
     *
     * tcb->t_timer[TCPT_PERSIST] is set when in persist state
     * tcb->t_force is set when we are called to send a persist packet
     * tcb->t_timer[TCPT_REXMT] is set when retransmitting
     * The output side is idle when both timers are zero.
     *
     * If send window is too small, there is data to transmit, and
     * no retransmit or persist is pending, then go to persist state.
     * If nothing happens soon, send when timer expires:
     * if window is nonzero, transmit when we can, otherwise force out
     * a byte.
     */
    if (totalLen && tcb->t_timer[TCPT_REXMT] == 0 &&
	tcb->t_timer[TCPT_PERSIST] == 0) {
	tcb->t_rxtshift = 0;
	TcpSetPersist(tcb);
    }

    /*
     * No reason to send a segment, just return.
     */
    TcpipUnlock(OptrToHandle(tp));
    return (0);


send:

    /*
     * Before ESTABLISHED, force sending of initial options unless
     * TCP set not to do any options.
     */
    optlen = 0;
    hdrlen = sizeof (struct tcpiphdr);
    if (flags & TH_SYN) {
	tcb->snd_nxt = tcb->iss;
	if ((tcb->t_flags & TF_NOOPT) == 0) {
	    word mss;
	    opt[0] = TCPOPT_MAXSEG;
	    opt[1] = 4;
	    mss = HostToNetworkWord(TcpMSS(tcb, 0, TSocketGetLink(socket)));
	    memcpy((char *)(opt + 2), (char *)&mss, sizeof (mss));
	    optlen = 4;
	}
    }

    hdrlen += optlen;

    /*
     * Adjust data length if insertion of options will bump
     * the packet length beyond the t_maxseg length.
     */
    if (len > tcb->t_maxseg - optlen) {
	len = tcb->t_maxseg - optlen;
	sendalot = 1;
    }

    /*
     * Allocate a data buffer for the output.
     */
    dataBuf = TcpipAllocDataBuffer(len + hdrlen,
				   TSocketGetLink(socket));
    if (dataBuf == 0) {
	error = SDE_INSUFFICIENT_MEMORY;
	goto out;
    }

    TcpipLock(OptrToHandle(dataBuf));
    m = (MbufHeader *)LMemDeref(dataBuf);

     /*
      * If there is data, copy the data to be transmitted to the buffer.
      */
    if (len) {

#ifdef LOG_STATS
	if (tcb->t_force && len == 1)
	    tcpstat.tcps_sndprobe++;
	else if (SEQ_LT(tcb->snd_nxt, tcb->snd_max)) {
	    tcpstat.tcps_sndrexmitpack++;
	    tcpstat.tcps_sndrexmitbyte += len;
	} else {
	    tcpstat.tcps_sndpack++;
	    tcpstat.tcps_sndbyte += len;
	}
#endif

	TSocketGetOutputData((byte *)mtod(m) + hdrlen, off,
				  (word)len, socket);
	/*
	 * If we're sending everything we've got, set PUSH.
	 * (This will keep happy those implementations which only
	 * give data to the user when a buffer fills or a PUSH comes in.)
	 */
	if (off + len == totalLen)
	    flags |= TH_PUSH;
    }

#ifdef LOG_STATS
    else {
	if (tcb->t_flags & TF_ACKNOW)
	    tcpstat.tcps_sndacks++;
	else if (flags & (TH_SYN|TH_FIN|TH_RST))
	    tcpstat.tcps_sndctrl++;
	else if (SEQ_GT(tcb->snd_up, tcb->snd_una))
	    tcpstat.tcps_sndurg++;
	else
	    tcpstat.tcps_sndwinup++;
    }
#endif

     /*
      * Initialize the header from the template for sends on this connection.
      */
    ti = (struct tcpiphdr *)mtod(m);
    *ti = tcb->t_template;

    /*
     * Fill in fields, remembering maximum advertised window for use
     * in delaying messages about window sizes.  If resending a FIN,
     * be sure not to use a new sequence number.
     */
    if (flags & TH_FIN && tcb->t_flags & TF_SENTFIN &&
	tcb->snd_nxt == tcb->snd_max)
	tcb->snd_nxt--;

    /*
     * If we are doing retransmissions, then snd_nxt will reflect
     * oldest unacked seq #.  For ACK only packets, we do not want
     * the sequence number of the retransmitted packet, we want the
     * sequence number of the next unsent byte.  So, if there is no data
     * (and no SYN or FIN), use snd_max instead of snd_nxt when filling
     * in ti_seq.  But if we are in persist state, snd_max might reflect
     * one byte beyond the right edge of the window, so use snd_nxt in
     * that case, since we know we aren't doing a retransmission.
     * (retransmit and persist are mutually exclusive...)
     */
    if (len || (flags & (TH_SYN|TH_FIN)) || tcb->t_timer[TCPT_PERSIST])
	ti->ti_seq = HostToNetworkDWord(tcb->snd_nxt);
    else
	ti->ti_seq = HostToNetworkDWord(tcb->snd_max);
    ti->ti_ack = HostToNetworkDWord(tcb->rcv_nxt);

     /*
      * Copy options to buffer.
      */
    if (optlen) {
	memcpy((char *)(ti + 1), (char *)opt, optlen);
    	ti->ti_off = (sizeof(struct tcphdr) + optlen) >> 2;
    }

    ti->ti_flags = flags;

     /*
      * Calculate the receive window.  Don't shrink window, but avoid
      * silly window syndrome.
      */
    if (win < (dword)tcb->t_maxseg)
	win = 0;
    if (win > tcp_maxwin)
	win = tcp_maxwin;
    if (win < (sdword)(tcb->rcv_adv - tcb->rcv_nxt))
	win = (sdword)(tcb->rcv_adv - tcb->rcv_nxt);

    ti->ti_win = HostToNetworkWord((word)win);

     /*
      * Set urgent pointer in TCP header.
      */
    if (SEQ_GT(tcb->snd_up, tcb->snd_nxt)) {
	ti->ti_urp = HostToNetworkWord((word)(tcb->snd_up - tcb->snd_nxt));
	ti->ti_flags |= TH_URG;
    } else if (SEQ_LT(tcb->snd_up, tcb->snd_una))
	/*
	 * If no urgent pointer to send, then we pull the urgent pointer
	 * to the left edge of the send window so that it doesn't drift
	 * into the send window on sequence number wraparound.  WARNING:
	 * Do NOT adjust the urgent pointer if it is to the right of the left
	 * edge of the send window or the urgent pointer will be lost
	 * during retransmission if regular data was sent after the
	 * urgent byte causing snd_up to be less than snd_nxt.
	 */
	tcb->snd_up = tcb->snd_una;

    /*
     * Put TCP length in extended header, and then checksum extended
     * header and data.
     */
    if (len + optlen)
	ti->ti_len = HostToNetworkWord((word)(sizeof (struct tcphdr) +
					      optlen + len));
    ti->ti_cksum = Checksum((word *)ti, hdrlen + len);

     /*
      * In transmit state, time the transmission and arrange for the
      * retransmit.  In persist state, just set snd_max.
      */
    if (tcb->t_force == 0 || tcb->t_timer[TCPT_PERSIST] == 0) {
	tcp_seq startseq = tcb->snd_nxt;

	/*
	 * Advance snd_nxt over sequence space of this segment.
	 */
	if (flags & TH_SYN)
	    tcb->snd_nxt++;
	if (flags & TH_FIN) {
	    tcb->snd_nxt++;
	    tcb->t_flags |= TF_SENTFIN;
	}
	tcb->snd_nxt += len;

	if (SEQ_GT(tcb->snd_nxt, tcb->snd_max)) {
	    tcb->snd_max = tcb->snd_nxt;
	     /*
	      * Time this transmission if not a retransmission and not
	      * currently timing anything.
	      */
	    if (tcb->t_rtt == 0) {
		tcb->t_rtt = 1;
		tcb->t_rtseq = startseq;
	    	LOG_STAT(tcpstat.tcps_segstimed++;)
	    }
	}

	 /*
	  * Set retransmit timer if not currently set, and not doing
	  * an ack or a keep-alive probe.  Initial value for retransmit
	  * timer is smoothed round-trip time + 2 * round-trip time variance.
	  * Initialize shift counter which is used for backoff of retransmit
	  * time.
	  */
	if (tcb->t_timer[TCPT_REXMT] == 0 &&
	    tcb->snd_nxt != tcb->snd_una) {
	    tcb->t_timer[TCPT_REXMT] = tcb->t_rxtcur;
	    if (tcb->t_timer[TCPT_PERSIST]) {
		tcb->t_timer[TCPT_PERSIST] = 0;
		tcb->t_rxtshift = 0;
	    }
	}
    } else
	if (SEQ_GT(tcb->snd_nxt + len, tcb->snd_max))
	    tcb->snd_max = tcb->snd_nxt + len;

     /*
      * Fill in IP length and desired time to live and send to IP level.
      */
    ((struct ip*)ti)->ip_len = hdrlen + len;
    ((struct ip*)ti)->ip_ttl = tcb->t_ttl;
    ((struct ip*)ti)->ip_tos = 0;   	    	/* TCP uses default TOS */

    TcpipUnlock(OptrToHandle(dataBuf));
    error = IpOutput(dataBuf, TSocketGetLink(socket), 0);

out:
    if (error) {
	 if (error == SDE_INSUFFICIENT_MEMORY) {
	     tcb->snd_cwnd = tcb->t_maxseg;
	     error = 0;
	 }
	 else if (error == SDE_DESTINATION_UNREACHABLE &&
	     TCPS_HAVERCVDSYN(tcb->t_state)) {
	     tcb->t_softerror = error;
	     error = 0;
	 }

	 TcpipUnlock(OptrToHandle(tp));
	 return (error);
     }

    LOG_STAT(tcpstat.tcps_sndtotal++;)

     /*
      * Data sent (as far as we can tell).  If this advertises a larger
      * window than any other segment, then remember the size of the
      * advertised window.  Any pending ACK has now been sent.
      */
    if (win > 0 && SEQ_GT(tcb->rcv_nxt + win, tcb->rcv_adv))
	tcb->rcv_adv = tcb->rcv_nxt + win;
    tcb->last_ack_sent = tcb->rcv_nxt;
    tcb->t_flags &= ~(TF_ACKNOW|TF_DELACK);
    if (sendalot)
	goto again;

    TcpipUnlock(OptrToHandle(tp));
    return (0);

}



/***********************************************************************
 *				TcpRespond
 ***********************************************************************
 * SYNOPSIS:	Send a single message to the TCP at address specified by
 *	    	the given TCP/IP header.  Used to force keep alive
 *	    	messages out using the TCP template. Ack and sequence
 *	    	numbers are as specified.
 * CALLED BY:	TcpInput
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/27/94		Initial Revision
 *
 ***********************************************************************/
void
TcpRespond(struct tcpcb *tcb,
	   struct tcpiphdr *ti,
	   MbufHeader *m,
	   tcp_seq ack,
	   tcp_seq seq,
	   word flags,
	   word link)
{
    word tlen;
    word win = 0;
    optr dataBuf;
    MbufHeader *m2;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */

    if (tcb) {
	win = tcb->t_maxwin;
    }

    if (tcp_keeplen)
	tlen = 1;
    else
	tlen = 0;

    dataBuf = TcpipAllocDataBuffer(sizeof (struct tcpiphdr) + tlen, link);
    if (dataBuf == 0)
	return;

     /*
      * Make a copy of the tcpiphdr at ti.
      */
    TcpipLock(OptrToHandle(dataBuf));
    m2 = (MbufHeader *)LMemDeref(dataBuf);
    memcpy((char *)mtod(m2), (char *)ti, sizeof(struct tcpiphdr));
    ti = (struct tcpiphdr *)mtod(m2);

     /*
      * Send directly to addressed host.
      */
    if (m == 0) {
	flags = TH_ACK;
    } else {
	/*
	 * Return to TCP which originated the segment ti.  Converting
	 * port numbers back to network format.
	 */
#define xchg(a, b, type) {type t; t=a; a=b; b=t;}
	xchg(ti->ti_dst, ti->ti_src, dword);
	xchg(ti->ti_dport, ti->ti_sport, word);
	ti->ti_dport = HostToNetworkWord(ti->ti_dport);
	ti->ti_sport = HostToNetworkWord(ti->ti_sport);
#undef xchg
    }

    ti->ti_len = HostToNetworkWord((word)(sizeof (struct tcphdr) + tlen));
    tlen += sizeof (struct tcpiphdr);
    ti->ti_next = ti->ti_prev = 0;
    ti->ti_x1 = 0;
    ti->ti_seq = HostToNetworkDWord(seq);
    ti->ti_ack = HostToNetworkDWord(ack);
    ti->ti_x2 = 0;
    ti->ti_off = sizeof (struct tcphdr) >> 2;
    ti->ti_flags = flags;
    ti->ti_win = HostToNetworkWord((word)win);
    ti->ti_urp = 0;
    ti->ti_cksum = 0;
    ti->ti_cksum = Checksum((word *)ti, tlen);
    ((struct ip *)ti)->ip_len = tlen;
    ((struct ip *)ti)->ip_ttl = ip_defttl;

    TcpipUnlock(OptrToHandle(dataBuf));
    (void) IpOutput(dataBuf, link, 0);

}
