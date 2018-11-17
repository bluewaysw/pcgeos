/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  tcpUtils.c
 * FILE:	  tcpUtils.c
 *
 * AUTHOR:  	  Jennifer Wu: Jul 20, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	TcpInitTCB  	    Initialize the fields of a TCB
 *	TcpInitTemplate	    Initialize the TCP template header
 *	TcpFreeTCB  	    Free up all memory used by the TCB, including
 *	    	    	    the TCB itself
 *	TcpError    	    Process an ICMP error for a connection
 *	TcpDrop	    	    Drop a connection, reporting the specified 
 *	    	    	    error to the socket level
 *	TcpTimeoutHandler   Process TCP timeouts for a connection
 *	TcpSetPersist	    Set the persist timer
 *	TcpXmitTimer	    Collect new round trip time estimate and update
 *	    	    	    averages and current timeout
 *	TcpCancelTimers	    Cancel all timers for a TCB
 *	TcpMSS	    	    Determine a reasonable value for maxseg size
 *	TcpRemoveQueue	    Remove an element from the TCB's reassembly queue.
 *
 *	TcpSetOption	    Set an option for a connection.
 *	TcpGetOption	    Get an option for a connection.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/20/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Implementation based on BSD.
 *
 *	$Id: tcpUtils.c,v 1.1 97/04/18 11:57:10 newdeal Exp $
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

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

#include <geos.h>
#include <resource.h>
#include <geode.h>
#include <Ansi/string.h>
#include <lmem.h>
#include <timer.h>
#include <timedate.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <tcp.h>
#include <icmp.h>
#include <tcpip.h>
#include <tcpipLog.h>

#ifdef __HIGHC__
#pragma Code("TCPCODE"); 
#endif
#ifdef __BORLANDC__
#pragma codeseg TCPCODE
#endif

word tcp_maxrxt = TCP_MAXRXTSHIFT;  	/* maximum # of retransmissions */
word tcp_minRxmt = TCPTV_MIN;           /* minimum retransmit interval */


/***********************************************************************
 *				TcpInitTCB
 ***********************************************************************
 * SYNOPSIS:	Initialize the fields in a TCB.
 * CALLED BY:	SocketCreateTCB
 * PASS:    	tcb = ptr to TCB to initialize (zero-ed out already)
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    No window scaling or timestamp options.
 *	    Initialized:  sequencing queue, maxseg to default, state
 *	    	set to CLOSED, no flags, round trip time values,
 *	    	current retransmission time, congestion avoidance,
 *	    	slow start and source quench values, default ttl.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/20/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
TcpInitTCB (struct tcpcb *tcb, 
	    dword src, 
	    dword dst, 
	    word lport, 
	    word rport)
{
    GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */
    
    tcb->seg_next = tcb->seg_prev = 0;
    tcb->t_maxseg = tcp_mssdflt;

    tcb->rqueue_size = 0;   	    

    tcb->t_state = TCPS_CLOSED;
    tcb->t_flags = 0;	    	    /* no window scaling or timestamp */
    tcb->t_inline = 0;	    	    /* extract urgent data */

     /*
      * Start with defaults for the receive window until connection
      * is established, at which time, socket library will tell us 
      * the actual size of the receive buffer.
      */
    tcb->t_maxwin = TCP_RECV_WIN;	
    tcb->rcv_buf = TCP_RECV_WIN;
     
     /*
      * Init srtt to TCPTV_SRTTBASE (0), so we can tell that we have no
      * rtt estimate.  Set rttvar so that srtt + 2 * rttvar gives
      * reasonable initial retransmit time.
      */
    tcb->t_srtt = TCPTV_SRTTBASE;
    tcb->t_rttvar = tcp_rttdflt << TCP_RTTVAR_SHIFT;
    tcb->t_rttmin = tcp_minRxmt;
     
     /* 
      * Set the current retransmit value.
      */
    TCPT_RANGESET(tcb->t_rxtcur,
		  ((TCPTV_SRTTBASE >> 2) + (tcp_rttdflt << 2)) >> 1,
		  tcp_minRxmt, TCPTV_REXMTMAX);
     
     /*
      * Initialize congestion avoidance and slow start variables
      * to largest possible window.
      */
    tcb->snd_cwnd = tcp_maxwin;
    tcb->snd_ssthresh = tcp_maxwin;

    tcb->t_ttl = ip_defttl;

    /*
     * Initialize the template in the TCB.
     */
    TcpInitTemplate(tcb, src, dst, lport, rport);
}


/***********************************************************************
 *				TcpInitTemplate
 ***********************************************************************
 * SYNOPSIS:	Initialize the TCP template header to make future sends
 *	    	faster.
 * CALLED BY:	handler for open/accept connection
 * PASS:    	tcb = ptr to TCB control block
 *	    	src = local IP address
 *	    	dst = remote IP address
 *	    	lport = local port number
 *	    	rport = remote port number
 *
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 * NOTE:    	Socket info block must not be locked exclusive when 
 *	    	this is called.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/21/94		Initial Revision
 *
 ***********************************************************************/
void
TcpInitTemplate(struct tcpcb *tcb, 
		dword src, 
		dword dst, 
		word lport, 
		word rport)
{
	/*
	 * Initialize the TCP template header.
	 */
	tcb->t_template.ti_next = tcb->t_template.ti_prev = 0;
	tcb->t_template.ti_x1 = 0;
	tcb->t_template.ti_pr = IPPROTO_TCP;
	tcb->t_template.ti_len = HostToNetworkWord(sizeof(struct tcphdr));
	
	tcb->t_template.ti_src = src;
	tcb->t_template.ti_dst = dst;
	tcb->t_template.ti_sport = HostToNetworkWord(lport);
	tcb->t_template.ti_dport = HostToNetworkWord(rport);

	tcb->t_template.ti_seq = 0;
	tcb->t_template.ti_ack = 0;
	tcb->t_template.ti_x2 = 0;
	tcb->t_template.ti_off = 5;		/* num 32 bit words in hdr */
	tcb->t_template.ti_flags = 0;
	tcb->t_template.ti_win = 0;
	tcb->t_template.ti_cksum = 0;
	tcb->t_template.ti_urp = 0;

}


/***********************************************************************
 *				TcpFreeTCB
 ***********************************************************************
 * SYNOPSIS:	Free up all memory used by the TCB, including the TCB
 *	    	itself.
 * CALLED BY:	SocketDestroyTCB
 * PASS:    	tp  = optr to TCB
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/20/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV	
TcpFreeTCB (optr tp) 
{
    struct tcpcb *tcb;
    struct tcpiphdr *t, *p;
    optr obuf;

    GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */
    
    TcpipLock(OptrToHandle(tp));
    tcb = (struct tcpcb *)LMemDeref(tp);

    /*
     * Free the reassembly queue, if any.
     */
    t = tcb->seg_next;

#ifdef LOG_EVENTS	
	if (t)
	    LOG_EVENT(LM_TCP_FREEING_ELEMENT_IN_REASSEMBLY_QUEUE);
#endif
    
    while (t != 0) {
	p = (struct tcpiphdr *)t->ti_next;
	obuf = ConstructOptr(t->ti_bufMH, t->ti_bufCH);
	TcpipUnlock(t->ti_bufMH);
	TcpipFreeDataBuffer(obuf);
    	t = p;
    }
    
    TcpipUnlock(OptrToHandle(tp));
    TcpipFreeDataBuffer(tp);
    
    LOG_STAT(tcpstat.tcps_closed++;)
}


/***********************************************************************
 *				TcpError
 ***********************************************************************
 * SYNOPSIS:	Process an icmp error for a connection.
 * CALLED BY:	SocketDoError
 * PASS:    	socket	= ptr to TcpSocket
 *	    	tp 	= optr of TCB (unlocked)
 *	    	code	= icmp error code 
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    if the error is ICMP_SOURCEQUENCH, close congestion
 *	    	    window to one segment
 *	    If connection is established, ignore the unreachable error.
 *	    ignore time exeeded or parameter problem errors.
 * 	    else if connection has not been established yet and 
 *	    	have retransmitted several times and this is not
 *	    	the first error, set the tcp state to CLOSED,
 *	    	and wakeup the socket waiter, returning 
 *	    	SDE_DESTINATION_UNREACHABLE as the error.
 *	    else just store the error unreachable error.
 *	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/20/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
TcpError(dword tcpSocket, optr tp, word code)
{
	struct tcpcb *tcb;
	
        GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */
	
	TcpipLock(OptrToHandle(tp));
	tcb = (struct tcpcb *)LMemDeref(tp);

	if (code == ICMP_SOURCEQUENCH) 
		tcb->snd_cwnd = tcb->t_maxseg;
	
	else if (tcb->t_state < TCPS_ESTABLISHED && 
	        tcb->t_rxtshift > 3 && tcb->t_softerror && 
		 code == ICMP_UNREACH) {
		    LOG_STATE(TCPS_CLOSED);
	    	    tcb->t_state = TCPS_CLOSED;
		    TSocketWakeWaiter(tcpSocket, SDE_DESTINATION_UNREACHABLE);
	}
	else if ((tcb->t_state != TCPS_ESTABLISHED || code != ICMP_UNREACH) &&
		 code != ICMP_TIMXCEED && code != ICMP_PARAMPROB)
	    tcb->t_softerror = SDE_DESTINATION_UNREACHABLE;

	TcpipUnlock(OptrToHandle(tp));

}


/***********************************************************************
 *				TcpDrop
 ***********************************************************************
 * SYNOPSIS:	Drop a connection, reporting the specified error to
 *	    	the socket level.
 * CALLED BY:	TcpInput, TcpTimeoutHandler
 * PASS:    	socket	= connection handle
 *	    	tcbChunk = optr to TCB
 *	    	error	= error code to report to socket level
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    If a connection is synchronized, then send a RST to 
 *	    the peer.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/20/94		Initial Revision
 *
 ***********************************************************************/
void	
TcpDrop(word socket, optr tp, word error)
{
    struct tcpcb *tcb;

    GeodeLoadDGroup(0);	    /* should be in driver's thread */
    
    TcpipLock(OptrToHandle(tp));
    tcb = (struct tcpcb *)LMemDeref(tp);
    
    if (TCPS_HAVERCVDSYN(tcb->t_state)) {
	LOG_STATE(TCPS_CLOSED);
	tcb->t_state = TCPS_CLOSED;
	(void) TcpOutput(tp, socket);
    	LOG_STAT(tcpstat.tcps_drops++;)
    } 
#ifdef LOG_STATS    
    else
 	tcpstat.tcps_conndrops++;
#endif

     LOG_EVENT(LM_TCP_DROPPING_CONNECTION);

     /*
      * If connection timed out and there is a more explicit reason,
      * return that error instead.
      */
    if (error == SDE_CONNECTION_TIMEOUT && tcb->t_softerror)  
	error = tcb->t_softerror;

    TcpipUnlock(OptrToHandle(tp));
    TSocketIsDisconnected(socket, error, SCT_FULL, TRUE);
}


/***********************************************************************
 *				TcpTimeoutHandler
 ***********************************************************************
 * SYNOPSIS:	Process TCP timeouts for a connection
 * CALLED BY:	SocketTimeoutHandler
 * PASS:    	tcb 	= optr of TCB for connection
 *	    	socket	= connection handle
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	    	Connection may be destroyed.
 * STRATEGY:
 *	    	If delayed ack is set, send it.
 *	    	For each active timer in the connection:
 *	    	     decrement it
 *	    	    If it reaches zero, process that timeout.
 * 	        Update idle timer and rtt timer
 * NOTE:    	
 *	    	Socket info block must not be locked when this is 
 *	    	called or deadlock will result.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/21/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
TcpTimeoutHandler(optr tp, word socket)
{
    word i, rexmt;
    struct tcpcb *tcb;

    GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */
    
    TcpipLock(OptrToHandle(tp));
    tcb = (struct tcpcb *)LMemDeref(tp);
    
    tcb->t_idle++;
    if (tcb->t_rtt)
	tcb->t_rtt++;
    
     /*
      * If delayed ack flag is set, send the ack now.
      */
    if (tcb->t_flags & TF_DELACK) {
	tcb->t_flags &= ~TF_DELACK;
	tcb->t_flags |= TF_ACKNOW;
	TcpipUnlock(OptrToHandle(tp));
	(void) TcpOutput(tp, socket);
	LOG_STAT(tcpstat.tcps_delack++;)
    	return;
    }
    
     /*
      * Decrement all the timers and process any expirations.
      */
    for (i = 0; i < TCPT_NTIMERS; i++) {
	   if (tcb->t_timer[i] && --tcb->t_timer[i] == 0) {
	        /*
		 * Process the expired timer.  
		 */
	       switch (i) {
		   case TCPT_2MSL:
		    	if (tcb->t_state != TCPS_TIME_WAIT &&
			    tcb->t_idle <= tcp_maxidle)
			    tcb->t_timer[TCPT_2MSL] = tcp_keepintvl;
			else {
			    TcpipUnlock(OptrToHandle(tp));
			    TSocketIsDisconnected(socket, SDE_NO_ERROR, 
						  SCT_FULL, TRUE);
			    return;
			}
	       
		    case TCPT_PERSIST:
			LOG_STAT(tcpstat.tcps_persisttimeo++;)
		    	TcpSetPersist(tcb);
			tcb->t_force = 1;
			TcpipUnlock(OptrToHandle(tp));
			(void) TcpOutput(tp, socket);
			
			TcpipLock(OptrToHandle(tp));
			tcb = (struct tcpcb *)LMemDeref(tp);
	       	    	break;

		    case TCPT_REXMT:
	       	    	if (++tcb->t_rxtshift > tcp_maxrxt) {
			    tcb->t_rxtshift = tcp_maxrxt;
			    TcpipUnlock(OptrToHandle(tp));
			    LOG_STAT(tcpstat.tcps_timeoutdrop++;)
			    LOG_EVENT(LM_TCP_REXMT_TIMEOUT);
			    TcpDrop(socket, tp, SDE_CONNECTION_TIMEOUT);
			    return;
			}
			
			LOG_STAT(tcpstat.tcps_rexmttimeo++;)
			rexmt = TCP_REXMTVAL(tcb) * 
			    	tcp_backoff[tcb->t_rxtshift];
	       	    	TCPT_RANGESET (tcb->t_rxtcur, rexmt, tcb->t_rttmin,
				       TCPTV_REXMTMAX);
			tcb->t_timer[TCPT_REXMT] = tcb->t_rxtcur;

			/*
			 * If we backed off this far, our srtt estimate is
			 * probably bogus.  Clobber it so we'll take the next
			 * rtt measurement as our srtt; move the current srtt
			 * into rttvar to keep the current retransmit times
			 * until then.
			 */
			if (tcb->t_rxtshift > TCP_MAXRXTSHIFT / 4) {
			    tcb->t_rttvar += (tcb->t_srtt >> TCP_RTT_SHIFT);
			    tcb->t_srtt = 0;
			}

			tcb->snd_nxt = tcb->snd_una;

			/*
			 * If timing a segment in this window, stop the timer.
			 */
			tcb->t_rtt = 0;
	       
			 /*
			  * Close the congestion window down to one segment.
			  */
		       {
	       	    	 word win = min(tcb->snd_wnd, tcb->snd_cwnd) / 2 / 
			     	    tcb->t_maxseg;
			 if (win < 2)
			     win = 2;	
			 tcb->snd_cwnd = tcb->t_maxseg;
			 tcb->snd_ssthresh = win * tcb->t_maxseg;
			 tcb->t_dupacks = 0;
		       }
			TcpipUnlock(OptrToHandle(tp));
	       	    	(void) TcpOutput(tp, socket);
			
			TcpipLock(OptrToHandle(tp));
			tcb = (struct tcpcb *)LMemDeref(tp);
	       	    	break;
			
		case TCPT_KEEP:
			LOG_STAT(tcpstat.tcps_keeptimeo++;)
	    	    	if (tcb->t_state < TCPS_ESTABLISHED)
			    goto dropit;
			
			if (tcb->t_state <= TCPS_CLOSE_WAIT) {
			    if (tcb->t_idle >= tcp_keepidle + tcp_maxidle)
				goto dropit;

			     /*
			      * Send a packet designed to force a response
			      * if the peer is up and reachable:
			      * either an ACK if the connection is still alive
			      * or a RST if the peer has closed the connection.
			      * Using seq # tcb->snd_una - 1 causes the 
			      * transmitted zero-length segment to lie outside
			      * the receive window, causing the peer to respond.
			      */
			    LOG_STAT(tcpstat.tcps_keepprobe++;)
			    if (tcp_keeplen) 
				/* 
				 * The keepalive packet must have nonzero length
				 * to get a BSD 4.2 host to respond.
				 */
				TcpRespond(tcb, &tcb->t_template, 
					   (MbufHeader *)0,
					   tcb->rcv_nxt-1, tcb->snd_una-1, 0,
					   TSocketGetLink(socket));
			    else
				TcpRespond(tcb, &tcb->t_template, 
					   (MbufHeader *)0,
					   tcb->rcv_nxt, tcb->snd_una-1, 0,
					   TSocketGetLink(socket));

			    tcb->t_timer[TCPT_KEEP] = tcp_keepintvl;
			} else
			    tcb->t_timer[TCPT_KEEP] = tcp_keepidle;
			break;
		
		dropit:
			LOG_STAT(tcpstat.tcps_keepdrops++;)
			LOG_EVENT(LM_TCP_KEEPALIVE_TIMEOUT);
			TcpipUnlock(OptrToHandle(tp));
			TcpDrop(socket, tp, SDE_CONNECTION_TIMEOUT);
			return;
	    }
	}
   }
    
    TcpipUnlock(OptrToHandle(tp));
}


/***********************************************************************
 *				TcpSetPersist
 ***********************************************************************
 * SYNOPSIS:	Set the persist timer.
 * CALLED BY:	TcpTimeoutHandler	
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/25/94		Initial Revision
 *
 ***********************************************************************/
void 
TcpSetPersist (struct tcpcb *tcb)
{
    word t;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    t = ((tcb->t_srtt >> 2) + tcb->t_rttvar) >> 1;

    TCPT_RANGESET(tcb->t_timer[TCPT_PERSIST],
		  t * tcp_backoff[tcb->t_rxtshift],
		  TCPTV_PERSMIN, TCPTV_PERSMAX);

    if (tcb->t_rxtshift < tcp_maxrxt)
	tcb->t_rxtshift++;
}


/***********************************************************************
 *				TcpXmitTimer
 ***********************************************************************
 * SYNOPSIS:	Collect new round trip time estimate and update
 *	    	averages and current timeout.
 * CALLED BY:	TcpInput
 * PASS:    	tcb 	= TCB of connection
 *	    	rtt 	= round trip time
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/26/94		Initial Revision
 *
 ***********************************************************************/
void
TcpXmitTimer(struct tcpcb *tcb, 
	     word rtt)
{
    sword delta;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    

    LOG_STAT(tcpstat.tcps_rttupdated++;)
    
    if (tcb->t_srtt != 0) {
	 /*
	  * srtt is stored as fixed point with 3 bits after the 
	  * binary point (i.e. scaled by 8).  The following magic
	  * is equivalent to the smoothing algorithm in rfc793 with
	  * an alpha of .875 (srtt = rtt/8 + srtt*7/8 in fixed point).
	  * Adjust rtt to origin 0.
	  */
	delta = rtt - 1 - (tcb->t_srtt >> TCP_RTT_SHIFT);
	if ((tcb->t_srtt += delta) <= 0)
	    tcb->t_srtt = 1;

	 /*
	  * We accumulate a smoothed rtt variance (actually, a smoothed
	  * mean difference), then set the retransmit timer to smoothed
 	  * rtt + 4 times the smoothed variance.  
	  * rttvar is stored as fixed point with 2 bits after the binary
	  * point (scaled by 4).  The following is equivalent to rfc793
	  * smoothing with an alpha of .75 (rttvar = rttvar*3/4 +|delta|/4).
	  * This replaces rfc793's wired-in beta.
	  */
	if (delta < 0)
	    delta = -delta;
	delta -= (tcb->t_rttvar >> TCP_RTTVAR_SHIFT);
	if ((tcb->t_rttvar += delta) <= 0)
	    tcb->t_rttvar = 1;
    } else {
	 /*
	  * No rtt measurement yet - use the unsmoothed rtt.
	  * Set the variance to half the rtt (so our first
	  * retransmit happens at 3*rtt).
	  */
	tcb->t_srtt = rtt << TCP_RTT_SHIFT;
	tcb->t_rttvar = rtt << (TCP_RTTVAR_SHIFT - 1);
    }

    tcb->t_rtt = 0;
    tcb->t_rxtshift = 0;

     /*
      * Set the retransmit timer interval.
      */
    TCPT_RANGESET(tcb->t_rxtcur, TCP_REXMTVAL(tcb), tcb->t_rttmin,
		  TCPTV_REXMTMAX);

     /*
      * We received an ack for a packet that wasn't retransmitted;
      * BSD:  It is probably safe to discard any error indications we've
      * received recently.  This isn't quite right, but close enough
      * for now.
      */
    tcb->t_softerror = 0;
}


/***********************************************************************
 *				TcpCancelTimers
 ***********************************************************************
 * SYNOPSIS:	Cancel all timers for this TCB.
 * CALLED BY: 	TcpInput	
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/25/94		Initial Revision
 *
 ***********************************************************************/
void
TcpCancelTimers(struct tcpcb *tcb)
{
    word i;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    for (i = 0; i < TCPT_NTIMERS; i++)
	tcb->t_timer[i] = 0;
}


/***********************************************************************
 *				TcpMSS
 ***********************************************************************
 * SYNOPSIS:	Determine a reasonable value for maxseg size.  Use a
 *	    	MSS that can be handled on the outgoing interface without
 *	    	forcing IP to fragment.  Also initialize the congestion/
 *	    	slow start window to be a single segment.
 * CALLED BY:	TcpDoOptions
 * PASS:    	tcb 	= tcb of connection
 *	    	offer	= peer's offered mss
 *	    	link	= domain handle of outgoing interface
 * RETURN:	mss computed
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/26/94		Initial Revision
 *
 ***********************************************************************/
word
TcpMSS(struct tcpcb *tcb, word offer, word link)
{
    word mss;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
     /* 
      * Find the MTU for the outgoing interface.  If none, use default.
      * Leave room for Tcp and Ip headers in MTU.
      */
    /*
     * Umm... we don't want this determined by the server; we want to
     * use our default, or something smaller.   mevissen, 11/98
     */
    /* mss	= LinkGetMTU(link) - sizeof(struct tcpiphdr);
     *							11/98 */    
    /* if (mss == 0) 					11/98 */
 	mss = tcp_mssdflt;

     /*
      * Initialize current mss to the default value.  If we compute a 
      * smaller value, reduce the current mss.  If we compute a larger
      * value, return it for use in sending a max seg size option, but
      * don't store it for use unless we received an offer at least that
      * large from the peer.
      * Do NOT accept offers under 32 bytes!
      */
    if (offer)
	mss = min(mss, offer);
    mss = max(mss, 32);	    	    
    
    if (mss < tcb->t_maxseg || offer != 0) {
	/* 
	 * If the mss is larger than the receive buffer, decrease the mss.
	 */
	if (tcb->t_maxwin < mss)
	    mss = tcb->t_maxwin;

	tcb->t_maxseg = mss;
    }

     /*
      * Initialize congestion/slow start window to one segment.
      */
    tcb->snd_cwnd = mss;
    
    return (mss);
}




/***********************************************************************
 *				TcpRemoveQueue
 ***********************************************************************
 * SYNOPSIS:	Remove an element from the TCB's reassembly queue.
 * CALLED BY:	TcpReassemble
 * PASS:    	ti  = element to remove
 *	    	tcb = TCB
 * RETURN:	nothing
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/11/94		Initial Revision
 *
 ***********************************************************************/
void
TcpRemoveQueue (struct tcpiphdr *ti, struct tcpcb *tcb)
{
    if (ti->ti_next != 0)
	((struct tcpiphdr *)ti->ti_next)->ti_prev = ti->ti_prev;
    else 
	tcb->seg_prev = (struct tcpiphdr *)ti->ti_prev;

    if (ti->ti_prev != 0)
	((struct tcpiphdr *)ti->ti_prev)->ti_next = ti->ti_next;
    else
	tcb->seg_next = (struct tcpiphdr *)ti->ti_next;

}


/***********************************************************************
 *				TcpSetOption
 ***********************************************************************
 * SYNOPSIS:	Set an option for a connection
 * CALLED BY:	TcpipSetOption
 * PASS:    	connection = connection handle of socket
 *	    	optionType = SocketGetOptionType
 *	    	optionValue = value to set option to
 *	    	
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	1/10/95		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
TcpSetOption (word connection, word optionType, word optionValue)
{
    optr tp;
    struct tcpcb *tcb;

    tp = TSocketToTCB(connection);
    TcpipLock(OptrToHandle(tp));
    tcb = (struct tcpcb *)LMemDeref(tp);

    switch (optionType) {
        case SOT_RECV_BUF:
	    tcb->t_maxwin = optionValue;
            break;
	case SOT_INLINE:
	    tcb->t_inline = (byte)optionValue;
	    break;	    
        case SOT_NODELAY:
	    tcb->t_flags &= ~TF_NODELAY;
	    tcb->t_flags |= (TF_NODELAY & optionValue);
        default:
	    break;
    }

    TcpipUnlock(OptrToHandle(tp));
}



/***********************************************************************
 *				TcpGetOption
 ***********************************************************************
 * SYNOPSIS:	Get an option for a connection
 * CALLED BY:	TcpipGetOption
 * PASS:    	connection = connection handle of socket
 *	    	optionType = SocketGetOptionType
 *	    	
 * RETURN:	value of option
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	1/10/95		Initial Revision
 *
 ***********************************************************************/
word CALLCONV
TcpGetOption (word connection, word optionType)
{
    word optionValue;
    optr tp;
    struct tcpcb *tcb;

    tp = TSocketToTCB(connection);
    TcpipLock(OptrToHandle(tp));
    tcb = (struct tcpcb *)LMemDeref(tp);

    switch (optionType) {
	case SOT_INLINE:
	    optionValue = (word)tcb->t_inline;
	    break;	    
        case SOT_NODELAY:
	    optionValue = tcb->t_flags & TF_NODELAY;
        default:
	    break;
    }    

    TcpipUnlock(OptrToHandle(tp));

    return (optionValue);
}








