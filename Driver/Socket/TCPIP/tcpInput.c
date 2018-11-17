/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  TCP/IP driver
 * FILE:	  tcpInput.c
 *
 * AUTHOR:  	  Jennifer Wu: Jul 20, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	TcpReassemble	    Insert segment into reassembly queue of TCP
 *	TcpDropHeaders	    Strip IP and TCP headers and TCP options
 *	    	    	    from data buffer
 *	TcpInput    	    Main input handler for TCP protocol
 *	TcpPullOutOfBand    Pull out of band data out of a segment 
 *	TcpDoOptions	    Process TCP options
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/20/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Input routines for TCP protocol.  Implementation based on BSD.
 *
 *	$Id: tcpInput.c,v 1.1 97/04/18 11:57:11 newdeal Exp $
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
#pragma Code("TCPINCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg TCPINCODE
#endif

byte 	tcp_keeplen = 1;  	    	/* length of keepalive probes */

word	tcprexmtthresh = 3;
word tcp_keepidle = TCPTV_KEEP_IDLE;	/* time til keepalive probes begin */
word tcp_keepintvl = TCPTV_KEEPINTVL;	/* time between keepalive  probes */
word tcp_maxidle = TCPTV_KEEPCNT * TCPTV_KEEPINTVL;
                                      /* time to drop after starting probes */

word tcp_backoff[TCP_MAXRXTSHIFT+1] = 
    {1, 2, 4, 8, 16, 32, 64, 64, 64, 64, 64, 64, 64};

/* Default mss and round trip time estimates. */
word	tcp_mssdflt = TCP_MSS;	    	
word	tcp_rttdflt = TCPTV_SRTTDFLT;	    

/* Default maximum TCP window size. */
dword 	tcp_maxwin  = TCP_MAXWIN;

byte	tcp_outflags[TCP_NSTATES] = {
    TH_RST|TH_ACK, 0, TH_SYN, TH_SYN|TH_ACK,
    TH_ACK, TH_ACK,
    TH_FIN|TH_ACK, TH_FIN|TH_ACK, TH_FIN|TH_ACK, TH_ACK, TH_ACK,
};

word	rttShift = TCP_DFLT_RTT_SHIFT;
word	rttvarShift = TCP_DFLT_RTT_VAR_SHIFT;  	    	

#ifdef LOG_STATS
struct tcpstat tcpstat;
#endif


/***********************************************************************
 *				TcpReassemble
 ***********************************************************************
 * SYNOPSIS:	Insert segment into reassembly queue of tcp.
 * CALLED BY:	TcpInput 
 * PASS:    	tcb 	= TCB of connection
 *	    	ti  	= pointing to tcp/ip hdr of segment
 *	    	dataBuf	= optr of locked buffer containing segment
 *	    	socket	= connection handle
 * RETURN:	TH_FIN if reassembly now includes a segment with FIN
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/21/94		Initial Revision
 *	jwu 	3/05/96	    	Keep running total of reassembly queue size
 *
 ***********************************************************************/
word
TcpReassemble (struct tcpcb *tcb, 
	       struct tcpiphdr *ti, 
	       optr dataBuf,
	       word socket) 
{
    struct tcpiphdr *q;
    word flags;
    MbufHeader *m;
    /* for coalescing contiguous segments */
#ifdef MERGE_TCP_SEGMENTS
    MbufHeader *newSeg, *tempSeg;
    optr newBuf, tempBuf;
    struct tcpiphdr *newTI;
#endif

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
     /*
      * Call with ti == 0 after become established to force 
      * pre-ESTABLISHED data up to user socket.
      */
    if (ti == 0)
	goto present;

     /*
      * Find a segment which begins after this one does.
      */    
    for (q = tcb->seg_next; q != 0; q = (struct tcpiphdr *)q->ti_next) {
	LOG_EVENT(LM_TCP_USING_REASSEMBLY_QUEUE);
	if (SEQ_GT(q->ti_seq, ti->ti_seq))
	    break;
    }
     /*
      * If there is a preceding segment, it may provide some of our
      * data already.  If so, drop the data from the incoming segment.
      * If it provides all of our data, drop us.
      */
    /*
     * if q == 0, empty list or past end, use last one, else point to
     * previous one
     */
#ifdef MERGE_TCP_SEGMENTS
    if (q == 0) {
	q = tcb->seg_prev;
    } else {
	q = (struct tcpiphdr *)q->ti_prev;
    }
    if (q) {
#else
    if (q != 0 && (struct tcpiphdr *)q->ti_prev != 0) {
#endif
	sword i;
#ifndef MERGE_TCP_SEGMENTS
	q = (struct tcpiphdr *)q->ti_prev;
#endif
	/* conversion to word (in i) handles seq wraparound */
	i = q->ti_seq + q->ti_len - ti->ti_seq;
	if (i > 0) {
	    if (i >= ti->ti_len) {
		LOG_STAT(tcpstat.tcps_rcvduppack++;)
		LOG_STAT(tcpstat.tcps_rcvdupbyte += ti->ti_len;)
		LOG_EVENT(LM_TCP_DROPPING_COMPLETELY_OVERLAPPED_SEGMENT);
		TcpipUnlock(OptrToHandle(dataBuf));
		TcpipFreeDataBuffer(dataBuf);
		return (0);
	    }
	    LOG_EVENT(LM_TCP_DROPPING_OVERLAPPING_BYTES);
	    ti->ti_len -= i;
	    ti->ti_seq += i;

	    m = (MbufHeader *)LMemDeref(dataBuf);
	    m->MH_dataSize -= i;
	    m->MH_dataOffset += i;
	}
	/*
	 * If incoming packet is contiguous with preceding segment,
	 * allocate new incoming segment that merges incoming segment
	 * and preceding segment; dequeue preceding segment and drop
	 * incoming segment; continue processing with new incoming
	 * segment.  It'd be better to just enlarge the preceding segment
	 * and append the incoming segment, but HugeLMem doesn't support
	 * enlarging.  This change deals with a silly window syndrome-like
	 * problem where the sender sends many small packets in sequence.
	 * The problem on this end is that many small packets results in
	 * many not-so-small locked blocks on the heap.
	 * Also, only do this if the merged segment won't be too big.
	 */
#ifdef MERGE_TCP_SEGMENTS
	if ((i == 0) && (q->ti_len + ti->ti_len < TCP_RECV_WIN)) {
	    /* get pointers to preceding segment */
	    tempBuf = ConstructOptr((MemHandle)q->ti_bufMH,
				    (ChunkHandle)q->ti_bufCH);
	    tempSeg = (MbufHeader *)LMemDeref(
		ConstructOptr((MemHandle)q->ti_bufMH,
			      (ChunkHandle)q->ti_bufCH));
	    /* allocate new segment */
	    newBuf = TcpipDupDataBuffer(tempSeg, ti->ti_len);
	    if (newBuf != 0) {
		LOG_EVENT(LM_TCP_MERGING_SEGMENTS_IN_REASSEMBLY_QUEUE);
		/* set data length for new segment */
		newSeg = (MbufHeader *)LMemDeref(newBuf);
		newSeg->MH_dataSize += ti->ti_len;
		newTI = (struct tcpiphdr *)((char *)newSeg + ((char *)q-(char *)tempSeg));
		newTI->ti_len += ti->ti_len;
		/* append data from incoming segment into new segment */
		tempSeg = (MbufHeader *)LMemDeref(dataBuf);
		memcpy((char *)newSeg + newSeg->MH_dataOffset + q->ti_len,
		       (char *)tempSeg + tempSeg->MH_dataOffset,
		       ti->ti_len);
		/* dequeue preceding segment */
		tcb->rqueue_size -= q->ti_len;
		tcb->rcv_buf += q->ti_len;
		TcpRemoveQueue(q, tcb);
		q = (struct tcpiphdr *)(q->ti_next);
		TcpipUnlock(OptrToHandle(tempBuf));
		TcpipFreeDataBuffer(tempBuf);
		/* drop incoming segment */
		TcpipUnlock(OptrToHandle(dataBuf));
		TcpipFreeDataBuffer(dataBuf);
		/* continue on with new incoming segment (caller won't use
		   these again, so we can do this */
		ti = newTI;
		dataBuf = newBuf;
	    } else {
		q = (struct tcpiphdr *)(q->ti_next);
	    }
	} else {
	    q = (struct tcpiphdr *)(q->ti_next);
	}
    } else {
	/* point back to element to insert before */
	if (q != 0) {
	    q = (struct tcpiphdr *)q->ti_prev;
	} else {
	    q = tcb->seg_next;
	}
#else
	q = (struct tcpiphdr *)(q->ti_next);
#endif
    }
    LOG_STAT(tcpstat.tcps_rcvoopack++;)
    LOG_STAT(tcpstat.tcps_rcvoobyte += ti->ti_len;)
	
	/*
	 * Overlay the source and port numbers in the TCP header
	 * with the optr of the buffer.
	 */
    ti->ti_bufMH = OptrToHandle(dataBuf);
    ti->ti_bufCH = OptrToChunk(dataBuf);
	
 	/* 
	 * While we overlap succeeding segments trim them or,
	 * if they are completely covered, dequeue them.
	 */
    while (q != 0) {
	/* conversion to word (in i) handles sequence wraparound */
	sword i = (ti->ti_seq + ti->ti_len) - q->ti_seq;
	if (i <= 0)
	    break;

	tcb->rqueue_size -= i;  	    /* trim reassembly queue size */
	tcb->rcv_buf += i;

	if (i < q->ti_len) {
	    LOG_EVENT(LM_TCP_DROPPING_OVERLAPPING_BYTES);
	    q->ti_len -= i;
	    q->ti_seq += i;

	    m = LMemDeref(ConstructOptr((MemHandle)q->ti_bufMH,
					(ChunkHandle)q->ti_bufCH));
	    m->MH_dataSize -= i;
	    m->MH_dataOffset += i;

	    break;
	}
	
	LOG_EVENT(LM_TCP_DROPPING_COMPLETELY_OVERLAPPED_SEGMENT);
	
	dataBuf = ConstructOptr((MemHandle)q->ti_bufMH, 
				(ChunkHandle)q->ti_bufCH);
	TcpRemoveQueue(q, tcb);
	q = (struct tcpiphdr *)q->ti_next;
	TcpipUnlock(OptrToHandle(dataBuf));
	TcpipFreeDataBuffer(dataBuf);
    }
    
     /*
      * Stick new segment in its place.  Have to handle special cases
      * for inserting at front.  BSD uses a circular list with pointers 
      * to the TCB but our TCB is not always locked so that won't work.
      * ("q" is the element to insert the segment in front of)
      */
    LOG_EVENT(LM_TCP_INSERTING_SEGMENT_IN_REASSEMBLY_QUEUE);

    tcb->rqueue_size += ti->ti_len; 	    /* add new data to reass. queue size */
    tcb->rcv_buf -= ti->ti_len;
    if (tcb->rcv_buf < 0)
	tcb->rcv_buf = 0;

    ti->ti_next = (byte *)q;
    if (q == 0) {   	   
	ti->ti_prev = (byte *)tcb->seg_prev;
    	tcb->seg_prev = ti;
    }
    else {
	ti->ti_prev = q->ti_prev;
    	q->ti_prev = (byte *)ti;
    }
    if (ti->ti_prev == 0)	    	 
	tcb->seg_next = ti;	    	
    else	    	   
	((struct tcpiphdr *)ti->ti_prev)->ti_next = (byte *)ti;

present:
     /*
      * Present data to user, advancing rcv_nxt through completed
      * sequence space.
      */
    if (TCPS_HAVERCVDSYN(tcb->t_state) == 0)
	return (0);
    ti = tcb->seg_next;
    if (ti == 0 || ti->ti_seq != tcb->rcv_nxt ||
	(tcb->t_state == TCPS_SYN_RECEIVED && ti->ti_len))
	return (0);
    
    LOG_EVENT(LM_TCP_DELIVERING_SEGMENTS_FROM_REASSEMBLY_QUEUE);
    
    do {
	tcb->rcv_nxt += ti->ti_len;
	tcb->rqueue_size -= ti->ti_len;	  /* update reass. queue size */  

	flags = ti->ti_flags & TH_FIN;
	dataBuf = ConstructOptr((MemHandle)ti->ti_bufMH,
				(ChunkHandle)ti->ti_bufCH);
	
	TcpRemoveQueue(ti, tcb);
	ti = (struct tcpiphdr *)ti->ti_next;

	TcpipUnlock(OptrToHandle(dataBuf));
	tcb->rcv_buf = TSocketRecvInput(dataBuf, socket) - tcb->rqueue_size;
	if (tcb->rcv_buf < 0)
	    tcb->rcv_buf = 0;
    
    } while (ti != 0  && ti->ti_seq == tcb->rcv_nxt);
    
    return (flags);
}


/***********************************************************************
 *				TcpDropHeaders
 ***********************************************************************
 * SYNOPSIS:	Strip IP and TCP headers and TCP options from data buffer 
 *	    	before passing to socket library.
 * CALLED BY:	IpInput
 * PASS:    	socket	= connection handle
 *	    	dataBuf = optr of locked data buffer
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/21/94		Initial Revision
 *
 ***********************************************************************/
void 
TcpDropHeaders (word socket, optr dataBuf)
{
    MbufHeader *m;
    struct tcpiphdr *ti;
    word adj;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    m = (MbufHeader *)LMemDeref(dataBuf);
    ti = (struct tcpiphdr *)mtod(m);
    
    adj = sizeof (struct ip) + (ti->ti_off << 2);
    m->MH_dataSize -= adj;
    m->MH_dataOffset += adj;

}


/***********************************************************************
 *				TcpInput
 ***********************************************************************
 * SYNOPSIS:	Input handler for TCP protocol.
 * CALLED BY:	IpInput
 * PASS:    	dataBuf	= optr of data buffer containing segment
 *	    	iphlen	= IP header length
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	    	Data buffer will either be freed or delivered
 *	    	to the socket library.
 *	    	
 * STRATEGY:
 *
 * NOTE:    	hlen has been deducted from ip_len 
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/21/94		Initial Revision
 *
 ***********************************************************************/
void
TcpInput (optr dataBuf, word iphlen) 
{
    MbufHeader *m;
    struct tcpiphdr *ti;
    struct tcpcb *tcb = 0;
    word socket;
    optr tp;
    byte *optp;
    word tlen, len, off;
    sword optlen = 0;
    word tiflags, acked, ourfinisacked = 0, needoutput = 0;
    dword tiwin;
    sdword todrop;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    LOG_STAT(tcpstat.tcps_rcvtotal++;)

     /*
      * Get IP and TCP header together in the data buffer.
      */
    if (iphlen > sizeof(struct ip))
	IpStripOptions(dataBuf);

    TcpipLock(OptrToHandle(dataBuf));
    m = (MbufHeader *)LMemDeref(dataBuf);
    ti = (struct tcpiphdr *)mtod(m);

     /*
      * Discard if segment is too short to be valid.
      */
    if (m->MH_dataSize < sizeof(struct tcpiphdr)) {
	LOG_STAT(tcpstat.tcps_rcvshort++;)
	LOG_EVENT(LM_TCP_SEGMENT_TOO_SHORT);
	goto dropSeg;
    }

     /*
      * Checksum extended TCP header and data.
      */
    tlen = ((struct ip*)ti)->ip_len;
    len = sizeof(struct ip) + tlen;
    ti->ti_next = ti->ti_prev = 0;
    ti->ti_x1 = 0;
    ti->ti_len = HostToNetworkWord(tlen);
    if ((ti->ti_cksum = Checksum((word *)ti, len)) != 0) {
	LOG_STAT(tcpstat.tcps_rcvbadsum++;)
	LOG_EVENT(LM_TCP_BAD_CHECKSUM);
	goto dropSeg;
    }

     /*
      * Check that TCP offset makes sense, pull out TCP options and 
      * adjust length.
      */
    off = ti->ti_off << 2;
    if (off < sizeof (struct tcphdr) || off > tlen) {
	LOG_STAT(tcpstat.tcps_rcvbadoff++;)
	LOG_EVENT(LM_TCP_BAD_OFFSET);
	goto dropSeg;
    }
    
    tlen -= off;
    ti->ti_len = tlen;	    	    /* TCP header deducted from ti_len */
    
    if (off > sizeof (struct tcphdr)) {	    /* TCP options exist */
    	if (m->MH_dataSize < sizeof(struct ip) + off) {
	    LOG_STAT(tcpstat.tcps_rcvshort++;)
	    LOG_EVENT(LM_TCP_SEGMENT_TOO_SHORT);
	    goto dropSeg;   	    	    /* too short */
	}
	optlen = off - sizeof (struct tcphdr);
	optp = (byte *)(ti) + sizeof (struct tcpiphdr);
    }

    tiflags = ti->ti_flags;

     /*
      * Convert TCP protocol specific fields to host format.
      */
    ti->ti_seq = NetworkToHostDWord(ti->ti_seq);
    ti->ti_ack = NetworkToHostDWord(ti->ti_ack);
    ti->ti_win = NetworkToHostWord(ti->ti_win);
    ti->ti_urp = NetworkToHostWord(ti->ti_urp);
    ti->ti_dport = NetworkToHostWord(ti->ti_dport);
    ti->ti_sport = NetworkToHostWord(ti->ti_sport);

     /*
      * Locate the socket for the segment.  If connection does not
      * exist, then have to create a temporary connection and notify
      * socket library of connection request from peer if segment
      * contains a SYN.  Incoming SYN segments with broadcast or 
      * multicast address as the destination address must be silently 
      * discarded.
      */
findpcb:    
    socket = TSocketFindConnection(ti->ti_src, ti->ti_dst, ti->ti_dport,
				  ti->ti_sport);
    if (socket == 0) {
	
	if ((tiflags & (TH_RST|TH_ACK)) || m->MH_flags & (IF_BCAST | IF_MCAST)) {
	    LOG_EVENT(LM_TCP_SEGMENT_HAS_NO_CONNECTION);
	    goto dropSegWithReset;
	}
	if ((tiflags & TH_SYN) == 0) {
	    LOG_EVENT(LM_TCP_SEGMENT_HAS_NO_CONNECTION);
	    goto dropSeg;	
	}

    	socket = TSocketProcessConnectRequest(ti->ti_src, 
					     ti->ti_sport, 
					     ti->ti_dport,
					     m->MH_domain);
    	if (socket == 0)  {
	    LOG_EVENT(LM_TCP_SYN_REJECTED_BY_SOCKET_LIBRARY);
	    goto dropSegWithReset;
	}
    }
    else if (TSocketIsDead(socket)) {
	LOG_STAT(tcpstat.tcps_rcvafterclose++;)
	LOG_EVENT(LM_TCP_SEGMENT_RECEIVED_AFTER_CLOSE);
	goto dropSegWithReset;
    }
    tp = TSocketToTCB(socket);
    TcpipLock(OptrToHandle(tp));
    tcb = (struct tcpcb *)LMemDeref(tp);
    if (tcb->t_state == TCPS_CLOSED)
	tcb->t_state = TCPS_LISTEN;

    tiwin = ti->ti_win;
     
     /*
      * Segment received on connection.  Reset idle time and keep-alive 
      * timer.
      */
    tcb->t_idle = 0;
    tcb->t_timer[TCPT_KEEP] = tcp_keepidle;

     /*
      * Process options.
      */
    TcpDoOptions(tcb, optp, optlen, ti, m->MH_domain);

     /*
      * Header prediction:  check for the two common cases of a
      * uni-directional data xfer.  If the packet has no control
      * flags, is in-sequence, the window didn't change and we're 
      * not retransmitting, it's a candidate.  If the length is zero 
      * and the ack moved forward, we're the sender side of the xfer.
      * Just free the data acked.  If the length is non-zero and the 
      * ack didn't move, we're on the receiver side.  If we're getting
      * packets in-order (the reassembly queue is empty), pass the data
      * to the socket and note that we need a delayed ack.
      */
    if (tcb->t_state == TCPS_ESTABLISHED &&
	(tiflags & (TH_SYN|TH_FIN|TH_RST|TH_URG|TH_ACK)) == TH_ACK &&
	ti->ti_seq == tcb->rcv_nxt &&
	tiwin && tiwin == tcb->snd_wnd && 
	tcb->snd_nxt == tcb->snd_max) {
	    
	if (ti->ti_len == 0) {
	    if (SEQ_GT(ti->ti_ack, tcb->snd_una) &&
		SEQ_LEQ(ti->ti_ack, tcb->snd_max) &&
		tcb->snd_cwnd >= tcb->snd_wnd) {
		  
		  /*
	           * this is a pure ack for outstanding data
		   * Collect new round-trip time estimate 
		   */
		if (tcb->t_rtt &&
		    SEQ_GT(ti->ti_ack, tcb->t_rtseq))
		    TcpXmitTimer(tcb, tcb->t_rtt);
		  
		  /*
		   * Have socket level drop the acked data from
		   * the output queue and destroy input segment.
		   */
		acked = ti->ti_ack - tcb->snd_una;
		LOG_STAT(tcpstat.tcps_rcvackpack++;)
		LOG_STAT(tcpstat.tcps_rcvackbyte += acked;)
		(void)TSocketDropAckedData(socket, acked, &ourfinisacked);
		tcb->snd_una = ti->ti_ack;
		TcpipUnlock(OptrToHandle(dataBuf));
		TcpipFreeDataBuffer(dataBuf);
			   
		 /*
		  * If all outstanding data are acked, stop
		  * retransmit timer, otherwise restart timer using
		  * current (possibley backed-off) value.
		  * If data are ready to send, let TcpOutput decide
		  * between more output or persist.
		  */
		if (tcb->snd_una == tcb->snd_max)
		    tcb->t_timer[TCPT_REXMT] = 0;
		else if (tcb->t_timer[TCPT_PERSIST] == 0)
		    tcb->t_timer[TCPT_REXMT] = tcb->t_rxtcur;

		TcpipUnlock(OptrToHandle(tp));
		TcpOutput(tp, socket);
		return;
	    }
	} else if (ti->ti_ack == tcb->snd_una &&
		   tcb->seg_next == 0 &&
		   ti->ti_len <= tcb->rcv_buf) {
	    	/* 
		 * This is a pure, in-sequence data packet with
		 * nothing on the reassembly queue.
		 */
	    tcb->rcv_nxt += ti->ti_len;
	    LOG_STAT(tcpstat.tcps_rcvpack++;)
	    LOG_STAT(tcpstat.tcps_rcvbyte += ti->ti_len;)
	    	/*
		 * Drop TCP, IP headers and TCP options, then pass data 
		 * to socket level.
		 */
	    TcpDropHeaders(socket, dataBuf);
	    TcpipUnlock(OptrToHandle(dataBuf));
	    tcb->rcv_buf = TSocketRecvInput(dataBuf, socket) - tcb->rqueue_size;
	    if (tcb->rcv_buf < 0)
		tcb->rcv_buf = 0;

	    /*
	     * This is how NetBSD does the acknowledgements. The RFC says
	     * that we should acknowledge at least every 2nd full sized packet,
	     * or 500ms after receiving. Our old code delayed all acks.
	     * Right way is to first check if we already delayed an ack, and
	     * if so, immediately send off an ack. This has us sending off
	     * packets 1/2 as often as we would if we immediately ack
	     * everything, and we can still get full speed ethernet. Old
	     * style code limited us to ~5k/s on ethernet.
	     */
	    if (tcb->t_flags & TF_DELACK) {
		tcb->t_flags |= TF_ACKNOW;
	    }
	    else {
		tcb->t_flags |= TF_DELACK;
	    }
	    if (tcb->t_flags & TF_ACKNOW) {
		TcpOutput(tp, socket);
	    }
	    TcpipUnlock(OptrToHandle(tp));
	    return;
	}
    }

    /*
     * Drop TCP, IP headers and TCP options.
     */
    TcpDropHeaders(socket, dataBuf);

    
    /*
     * Calculate amount of space in receive window, and then do 
     * TCP input processing.  Receive space is amount of space
     * for received data, but not less than advertised window.
     */
    {
    sdword win = tcb->rcv_buf;
    tcb->rcv_wnd = max(win, (sdword)(tcb->rcv_adv - tcb->rcv_nxt));
    }
    
    switch (tcb->t_state) {

	case TCPS_LISTEN:
	    /*
	     * Temporary connection created because of an incoming 
	     * request.  Not accepted yet.
	     * Initialize sender and receiver's sequence numbers.
	     */
	    tcb->iss = ((dword)tcb ^ (word)TimerGetCount()) & 0x7fffffff;
	    tcp_sendseqinit(tcb);
	    tcb->irs = ti->ti_seq;
	    tcp_rcvseqinit(tcb);
	    goto trimThenStep6;

        case TCPS_SYN_SENT:
	    /*
	     * If the state is SYN_SENT:
	     * 	if seg contains an ACK but not for our SYN, drop the input.
	     *	if seg contains an RST, then drop the connection.
	     *	if seg does not contain SYN, then drop it.
	     * Otherwise this is an acceptable SYN segment
	     *	initialize tcb->rcv_nxt and tcb->irs
	     *	if seg contains ack then advance tcb->snd_una
	     *	if SYN has been acked change to ESTABLISHED else SYN_RCVD state
	     *	arrange for segment to be acked (eventually)
	     *	continue processing rest of data/controls, beginning with URG
	     */
	    if ((tiflags & TH_ACK) &&
		(SEQ_LEQ(ti->ti_ack, tcb->iss) ||
		 SEQ_GT(ti->ti_ack, tcb->snd_max))) {
		LOG_EVENT(LM_TCP_BAD_ACK_VALUE);
		goto dropSegWithReset;
	    }
	    if (tiflags & TH_RST) {
		if (tiflags & TH_ACK) {
		    LOG_STATE(TCPS_CLOSED);
		    tcb->t_state = TCPS_CLOSED;
		    tcb = (struct tcpcb *)0; 	    /* indicate unlocked */
		    TcpipUnlock(OptrToHandle(tp));
		    TcpDrop(socket, tp, SDE_CONNECTION_REFUSED);
		    goto dropSeg;
	    	}
	    }
	    if ((tiflags & TH_SYN) == 0) {
		LOG_EVENT(LM_TCP_SEGMENT_MISSING_SYN);
	    	goto dropSeg;
	    }
	    if (tiflags & TH_ACK) {
		tcb->snd_una = ti->ti_ack;
		if (SEQ_LT(tcb->snd_nxt, tcb->snd_una))
		    tcb->snd_nxt = tcb->snd_una;
	    }

	    tcb->t_timer[TCPT_REXMT] = 0;
	    tcb->irs = ti->ti_seq;
	    tcp_rcvseqinit(tcb);
	    tcb->t_flags |= TF_ACKNOW;
	    if (tiflags & TH_ACK && SEQ_GT(tcb->snd_una, tcb->iss)) {
		LOG_STAT(tcpstat.tcps_connects++;)
		LOG_STATE(TCPS_ESTABLISHED);
		tcb->t_state = TCPS_ESTABLISHED;
		TSocketIsConnected(socket);
		(void) TcpReassemble(tcb, (struct tcpiphdr *)0,
				     (optr)0, socket);
		/* 
		 * If we didn't have to retransmit the SYN, use its
		 * rtt as our initial srrt and rtt var.
		 */
		if (tcb->t_rtt)
		    TcpXmitTimer(tcb, tcb->t_rtt);
	    } else {
		LOG_STATE(TCPS_SYN_RECEIVED);
		tcb->t_state = TCPS_SYN_RECEIVED;
	    }

trimThenStep6:
	    /*
	     * Advance ti->ti_seq to correspond to first data byte.
	     * If data, trim to stay within window, dropping FIN if 
	     * necessary.
	     */
	    ti->ti_seq++;
	    if (ti->ti_len > tcb->rcv_wnd) {
		todrop = ti->ti_len - tcb->rcv_wnd;
		m->MH_dataSize -= todrop;
		ti->ti_len = tcb->rcv_wnd;
		tiflags &= ~TH_FIN;
	    	LOG_STAT(tcpstat.tcps_rcvpackafterwin++;)
		LOG_STAT(tcpstat.tcps_rcvbyteafterwin += todrop;)
	    }
	    tcb->snd_wl1 = ti->ti_seq - 1;
	    tcb->rcv_up = ti->ti_seq;
	    goto step6;
	}

     /*
      * States other than LISTEN or SYN_SENT.
      * If segment begins before rcv_nxt, drop leading data (and SYN); 
      * if nothing left, just ack.
      */
    
    todrop = tcb->rcv_nxt - ti->ti_seq;
    if (todrop > 0) {
	if (tiflags & TH_SYN) {
	    tiflags &= ~TH_SYN;
	    ti->ti_seq++;
	    if (ti->ti_urp > 1)
		ti->ti_urp--;
	    else
		tiflags &= ~TH_URG;
	    todrop--;
	}
	if (todrop >= ti->ti_len) {
	     LOG_STAT(tcpstat.tcps_rcvduppack++;)
	     LOG_STAT(tcpstat.tcps_rcvdupbyte += ti->ti_len;)
	     /*
	      * If segment is just one to the left of the window, check
	      * if the only thing to drop is a FIN, we can drop it,
	      *     but check the ACK or we will get into FIN wars if
	      *	    our FINs crossed (both CLOSING).
	      *	In either case, send ACK to resynchronize, but keep
	      * on processing for RST or ACK.
	      */
	    if (tiflags & TH_FIN && todrop == ti->ti_len + 1) {
		todrop = ti->ti_len;
		tiflags &= ~TH_FIN;
		tcb->t_flags |= TF_ACKNOW;
	    } else {
		/*
		 * Re-ack the duplicate bytes in case the peer dropped our
		 * ack.  Allow packets with a SYN and an ACK to continue
		 * with the processing, but make sure ACK will get sent.
		 * (BSD bug: BSD will not ACK duplicate SYN_ACKs so if
		 * remote drops ACK, their connection will timeout.)
		 */
		if (todrop != 0 || (tiflags & TH_ACK) == 0)
		    goto dropAfterAck;
		else
		    needoutput = 1; 	    
	    }
	} 
#ifdef LOG_STATS	
	else {
	    tcpstat.tcps_rcvpartduppack++;
	    tcpstat.tcps_rcvpartdupbyte += todrop;
	}
#endif
	
	 /* 
	  * Adjust data buffer to drop duplicate bytes.
	  * All TCP/IP headers have been removed so it's safe to adjust
	  * dataSize and dataOffset in the PacketHeader.
	  */
	m->MH_dataOffset += todrop;  
	m->MH_dataSize -= todrop;
	ti->ti_seq += todrop;
	ti->ti_len -= todrop;
    }
	 /*
	  * Check that at least some bytes of segment are within
	  * receive window.  If segment ends after the window, 
	  * drop trailing data (and PUSH and FIN); if nothing left, 
	  * just ACK.
	  */
    todrop = (ti->ti_seq + ti->ti_len) - (tcb->rcv_nxt + tcb->rcv_wnd);
    if (todrop > 0) {
	LOG_STAT(tcpstat.tcps_rcvpackafterwin++;)
	if (todrop >= ti->ti_len) {
	    LOG_STAT(tcpstat.tcps_rcvbyteafterwin += ti->ti_len;)
	    /*
	     * If a new connection request is received while in
	     * TIME_WAIT, drop the old connection and start over
	     * if the sequence numbers are above the previous ones.
	     */
	    if (tiflags & TH_SYN &&
		tcb->t_state == TCPS_TIME_WAIT &&
		SEQ_GT(ti->ti_seq, tcb->rcv_nxt)) {
		tcb = (struct tcpcb *)0;    	/* indicate unlocked*/
		TcpipUnlock(OptrToHandle(tp));
		TSocketIsDisconnected (socket, SDE_NO_ERROR, SCT_FULL, TRUE);
		goto findpcb;
	    }
		
	    /*
	     * If window is closed, can only take segments at 
	     * window edge, and have to drop data and PUSH from
	     * incoming segments.  Continue processing, but
	     * remember to ack.  Otherwise, drop segment and ack.
	     */
	    if (tcb->rcv_wnd == 0 && ti->ti_seq == tcb->rcv_nxt) {
		tcb->t_flags |= TF_ACKNOW;
	    	LOG_STAT(tcpstat.tcps_rcvwinprobe++;)
	    }
	    else
		goto dropAfterAck;
	} 
#ifdef LOG_STATS	
	else
	    tcpstat.tcps_rcvbyteafterwin += todrop;
#endif
	    
	/* 
	 * Adjust data buffer to trim the excess data off the end.
	 */
	m->MH_dataSize -= todrop;
	ti->ti_len -= todrop;
	tiflags &= ~(TH_PUSH|TH_FIN);
    }

    /*
     * If the RST bit is set, examine the state:
     *  	SYN_RECEIVED:
     * 	    Inform user that connectino was refused, then
     * 	    disconnect.
     * 	ESTABLISHED, FIN_WAIT_1, FIN_WAIT_2, CLOSE_WAIT states:
     * 	    Inform user that connection was reset, then disconnect.
     * 	CLOSING, LAST_ACK, TIME_WAIT states:
     * 	    Simply disconnect with no error.
     */
    if (tiflags & TH_RST)	{
	word tcbState = tcb->t_state;
	tcb = (struct tcpcb *)0;    	/* indicate unlocked*/
	TcpipUnlock(OptrToHandle(tp));
	    
	switch (tcbState) {
	    case TCPS_SYN_RECEIVED:
	        TSocketIsDisconnected (socket, SDE_CONNECTION_REFUSED, SCT_FULL,
				       TRUE);
	        goto close;
		
	    case TCPS_ESTABLISHED:
	    case TCPS_FIN_WAIT_1:
	    case TCPS_FIN_WAIT_2:
	    case TCPS_CLOSE_WAIT:
	        TSocketIsDisconnected (socket, SDE_CONNECTION_RESET_BY_PEER, 
				      SCT_FULL, TRUE);
	    close:
		LOG_STAT(tcpstat.tcps_drops++;)
	        goto dropSeg;

	    case TCPS_CLOSING:
	    case TCPS_LAST_ACK:
	    	TSocketIsDisconnected (socket, SDE_NO_ERROR, SCT_FULL, TRUE);
	    case TCPS_TIME_WAIT:
		goto dropSeg;
	}
    }

    /*
     * If a SYN is in the window, then this is an error and we
     * send a RST and drop the connection.
     */
    if (tiflags & TH_SYN) {
	LOG_STATE(TCPS_CLOSED);
	tcb->t_state = TCPS_CLOSED;	    	
	tcb = (struct tcpcb *)0;    	/* indicate unlocked*/
	TcpipUnlock(OptrToHandle(tp));
	LOG_EVENT(LM_TCP_SYN_RECEIVED_IN_WINDOW);
	TcpDrop(socket, tp, SDE_CONNECTION_RESET);
	goto dropSegWithReset;
    }
	
    /*
     * If the ACK bit is off, we drop the segment and return.
     */	
    if ((tiflags & TH_ACK) == 0) {
	LOG_EVENT(LM_TCP_SEGMENT_MISSING_ACK);
	goto dropSeg;
    }

    /*
     * Ack processing.
     */
    switch (tcb->t_state) {
	/*
	 * In SYN_RECEIVED state, if the ack ACKs our SYN, then
	 * enter ESTABLISHED state and continue processing, 
	 * otherwise send an RST.
	 */
	case TCPS_SYN_RECEIVED:
	    if (SEQ_GT(tcb->snd_una, ti->ti_ack) ||
		SEQ_GT(ti->ti_ack, tcb->snd_max)) {
		LOG_EVENT(LM_TCP_BAD_ACK_VALUE);
		goto dropSegWithReset;
	    }
	    LOG_STAT(tcpstat.tcps_connects++;)
	    LOG_STATE(TCPS_ESTABLISHED);
	    tcb->t_state = TCPS_ESTABLISHED;
	    TSocketIsConnected (socket);
	    (void) TcpReassemble(tcb, (struct tcpiphdr *)0, 
				 (optr)0, socket);
	    tcb->snd_wl1 = ti->ti_seq - 1;
	    
	    /* fall into ... */

	    /*
	     * In ESTABLISHED state: drop duplicate ACKs; ACK out of range
	     * ACKs.  If the ack is in the range   
	     *     tcb->snd_una < ti->ti_ack <= tcb->snd_max
	     * then advance tcb->snd_una to ti->ti_ack and drop data from
	     * the retransmission queue.  If this ACK reflects more
	     * up to date window information we update our window info.
	     */
	case TCPS_ESTABLISHED: 	
	case TCPS_FIN_WAIT_1:
	case TCPS_FIN_WAIT_2:
	case TCPS_CLOSE_WAIT:
    	case TCPS_CLOSING:
	case TCPS_LAST_ACK:
	case TCPS_TIME_WAIT:
	    if (SEQ_LEQ(ti->ti_ack, tcb->snd_una)) {
		if (ti->ti_len == 0 && tiwin == tcb->snd_wnd) {
		    LOG_STAT(tcpstat.tcps_rcvdupack++;)
		    /*
		     * If we have outstanding data (other than a window
		     * probe), this is a completely duplicate ack (ie,
		     * window info didn't change), the ack is the biggest
		     * we've seen and we've seen exactly our rexmt threshold
		     * of them.  So, assume a packet has been dropped and
		     * retransmit it.  Kludge snd_nxt & the congestion 
		     * window so we send only this one packet.
		     *
		     * We know we're losing at the current window size so
		     * do congestion avoidance (set ssthresh to half the
		     * current window and pull our congestion window back
		     * to the new ssthresh).
		     *
		     * Dup acks mean that packets have left the network
		     * (they're now cached at the receiver) so bump cwnd
		     * by the amount in the receiver to keep a constant cwnd
		     * packets in the network.
		     */
		    if (tcb->t_timer[TCPT_REXMT] == 0 ||
			ti->ti_ack != tcb->snd_una)
			tcb->t_dupacks = 0;
		    else if (++tcb->t_dupacks == tcprexmtthresh) {
			tcp_seq onxt = tcb->snd_nxt;
			word win = min(tcb->snd_wnd, tcb->snd_cwnd) / 2 /
			    tcb->t_maxseg;
			    
			if (win < 2)
			    win = 2;
			tcb->snd_ssthresh = win * tcb->t_maxseg;
			tcb->t_timer[TCPT_REXMT] = 0;
			tcb->t_rtt = 0;
			tcb->snd_nxt = ti->ti_ack;
			tcb->snd_cwnd = tcb->t_maxseg;
			TcpipUnlock(OptrToHandle(tp));
			(void) TcpOutput(tp, socket);
			    
			TcpipLock(OptrToHandle(tp));
			tcb = (struct tcpcb *)LMemDeref(tp);
			tcb->snd_cwnd = tcb->snd_ssthresh + tcb->t_maxseg * 
			    tcb->t_dupacks;
			if (SEQ_GT(onxt, tcb->snd_nxt))
			    tcb->snd_nxt = onxt;
			goto dropSeg;
		    } else if (tcb->t_dupacks > tcprexmtthresh) {
			tcb->snd_cwnd += tcb->t_maxseg;
			tcb = (struct tcpcb *)0;	/* unlocked */
			TcpipUnlock(OptrToHandle(tp));
			(void) TcpOutput(tp, socket);
			goto dropSeg;
		    }
		} else
		    tcb->t_dupacks = 0;
		break;
	    }

	    /*
	     * If the congestion window was inflated to account for 
	     * the other side's cached packets, retract it.
	     */
	    if (tcb->t_dupacks > tcprexmtthresh &&
		tcb->snd_cwnd > tcb->snd_ssthresh)
		tcb->snd_cwnd = tcb->snd_ssthresh;
	    tcb->t_dupacks = 0;
	    if (SEQ_GT(ti->ti_ack, tcb->snd_max)) {
		LOG_STAT(tcpstat.tcps_rcvacktoomuch++;)
		goto dropAfterAck;
	    }
	    acked = ti->ti_ack - tcb->snd_una;
	    LOG_STAT(tcpstat.tcps_rcvackpack++;)
	    LOG_STAT(tcpstat.tcps_rcvackbyte += acked;)
		
	    /*
	     * If transmit timer is running and timed sequence number 
	     * was acked, update smoothed round trip time. 
	     */
	    if (tcb->t_rtt && SEQ_GT(ti->ti_ack, tcb->t_rtseq))
		TcpXmitTimer(tcb, tcb->t_rtt);

	    /*
	     * If all outstanding data is acked, stop retransmit timer
	     * If there is more data to be acked, restart retransmit timer,
	     * using current (possibly backed-off) value.
	     */
	    if (ti->ti_ack == tcb->snd_max) {
		tcb->t_timer[TCPT_REXMT] = 0;
		needoutput = 1;
	    }
	    else if (tcb->t_timer[TCPT_PERSIST] == 0)
		tcb->t_timer[TCPT_REXMT] = tcb->t_rxtcur;

	    /*
	     * When new data is acked, open the congestion window.
	     * If the window gives us less than ssthresh packets in 
	     * flight, open exponentially (maxseg per packet).  Otherwise
	     * open linearly: maxseg per window (maxseg^2/cwnd per packet),
	     * plus a constant fraction of a packet (maxseg/8) to help 
	     * larger windows open quickly enough.
	     */
	{
	    dword cw = tcb->snd_cwnd;
	    dword incr = (dword) tcb->t_maxseg;
	    
	    if (cw > tcb->snd_ssthresh)
		incr = incr * incr / cw + incr / 8;
	    tcb->snd_cwnd = min(cw + incr, tcp_maxwin);
	}
		
	    /*
	     * Have the socket level drop the acked data and find
	     * out if our FIN was acked.
	     */
	    tcb->snd_wnd -= TSocketDropAckedData(socket, acked,
						&ourfinisacked);
		
	    tcb->snd_una = ti->ti_ack;
	    if (SEQ_LT(tcb->snd_nxt, tcb->snd_una))
		tcb->snd_nxt = tcb->snd_una;

	    /*
	     * Do some extra processing for the ESTABLISHED state 
	     * if our FIN is acked.
	     */
	    switch (tcb->t_state) {
		case TCPS_FIN_WAIT_1:
	            if (ourfinisacked) {
			LOG_STATE(TCPS_FIN_WAIT_2);
			tcb->t_state = TCPS_FIN_WAIT_2;
		    }
		    break;
		
		case TCPS_CLOSING:
		    if (ourfinisacked) {
			TSocketIsDisconnected(socket, SDE_NO_ERROR, SCT_FULL,
					      FALSE);
			LOG_STATE(TCPS_TIME_WAIT);
			tcb->t_state = TCPS_TIME_WAIT;
			TcpCancelTimers(tcb);
			tcb->t_timer[TCPT_2MSL] = 2 * TCPTV_MSL;
		    }
		    break;
		    
		case TCPS_LAST_ACK:
		    /*
		     * We may still be waiting for data to drain and/or
		     * be acked, as well as the ack of our FIN.  If our
		     * FIN is now acked, disconnect the socket and
		     * drop the segment.
		     */
		    if (ourfinisacked) {
			LOG_STATE(TCPS_CLOSED);		
			tcb->t_state = TCPS_CLOSED;
			tcb = (struct tcpcb *)0;	    /* unlocked */
			TcpipUnlock(OptrToHandle(tp));
			TSocketIsDisconnected(socket, SDE_NO_ERROR, SCT_FULL,
					      TRUE);
			goto dropSeg;
		    }
		    break;
			
		case TCPS_TIME_WAIT:
		    tcb->t_timer[TCPT_2MSL] = 2 * TCPTV_MSL;
		    goto dropAfterAck;
	    }
	}	
step6:
    /*
     * Update window information.
     * Don't look at window if no ACK:  TAC's send garbage on first SYN.
     */
    if ((tiflags & TH_ACK) && 
	(SEQ_LT(tcb->snd_wl1, ti->ti_seq) || tcb->snd_wl1 == ti->ti_seq &&
	 (SEQ_LT(tcb->snd_wl2, ti->ti_ack) ||
	  tcb->snd_wl2 == ti->ti_ack && tiwin > tcb->snd_wnd))) {

#ifdef LOG_STATS	 
	 /* keep track of pure window updates */
	if (ti->ti_len == 0 &&
	    tcb->snd_wl2 == ti->ti_ack && tiwin > tcb->snd_wnd)
	    tcpstat.tcps_rcvwinupd++;
#endif

	tcb->snd_wnd = tiwin;
	tcb->snd_wl1 = ti->ti_seq;
	tcb->snd_wl2 = ti->ti_ack;
	if (tcb->snd_wnd > tcb->max_sndwnd)
	    tcb->max_sndwnd = tcb->snd_wnd;
	needoutput = 1;
    }
	
    /*
     * Process segments with URG.
     */
    if ((tiflags & TH_URG) && ti->ti_urp &&
	TCPS_HAVERCVDFIN(tcb->t_state) == 0) {

	word urp = ti->ti_urp;

	/*
	 * If this segment advances the known urgent pointer, then
	 * mark the data stream.  This should not happen in CLOSE_WAIT,
	 * CLOSING, LAST_ACK or TIME_WAIT states since a FIN has been
	 * received from the remote side.
	 *
	 * According to RFC961 (Assigned Protocols), the urgent 
	 * pointer points to the last octet of urgent data.  BSD
	 * continues to consider it to indicate the first byte
	 * of data past the urgent section as the original spec states. 
	 * 
	 * Deliver urgent data to socket level.  Only do this when urgent
	 * pointer is within segment so retransmitted urgent data won't
	 * be delivered to the socket level again.
	 */
	if (SEQ_GT(ti->ti_seq + urp, tcb->rcv_up) && urp <= ti->ti_len) {
	    tcb->rcv_up = ti->ti_seq + urp;
	    TSocketHasUrgentData(socket, mtod(m) + urp - 1);
	}

	/*
	 * If not inline, remove out of band data so doesn't get 
	 * presented to user. This can happen independent of advancing 
	 * the URG pointer, but if two urg's are pending at once, 
	 * some out-of-band data may creep in. 
	 */   
	if (urp <= ti->ti_len && !tcb->t_inline) 
	    TcpPullOutOfBand(tcb, urp, m);

    } else
	/*
	 * If no out of band data is expected, pull receive urgent 
	 * pointer along with receive window.
	 */
	if (SEQ_GT(tcb->rcv_nxt, tcb->rcv_up))
	    tcb->rcv_up = tcb->rcv_nxt;

    /*
     * Process the segment text, merging it into the TCP sequencing queue,
     * and arranging for acknowledgement of receipt if necessary.  This
     * process logically involves adjusting tcb->rcv_wnd as data is 
     * presented to the socket level (calling output should do the right 
     * thing).
     * If a FIN has already been received on this connection, then we just
     * ignore the text.
     */
    if ((ti->ti_len || (tiflags & TH_FIN)) &&
	TCPS_HAVERCVDFIN(tcb->t_state) == 0) {
	 /*
	  * Common case: (segment is next to be received on an established
	  * connection, and the queue is empty).  Set DELACK for segments
	  * received in order.
	  */
	if (ti->ti_seq == tcb->rcv_nxt &&
	    tcb->seg_next == 0 &&
	    tcb->t_state >= TCPS_ESTABLISHED) {	    
	    tcb->t_flags |= TF_DELACK;
	    tcb->rcv_nxt += ti->ti_len;
	    tiflags = ti->ti_flags & TH_FIN;
	    LOG_STAT(tcpstat.tcps_rcvpack++;)
	    LOG_STAT(tcpstat.tcps_rcvbyte += ti->ti_len;)
	    TcpipUnlock(OptrToHandle(dataBuf));
	    tcb->rcv_buf = TSocketRecvInput(dataBuf, socket) - tcb->rqueue_size;
	    if (tcb->rcv_buf < 0)
		tcb->rcv_buf = 0;
	} else {
	     /*
	      * Insert segment into reassembly queue of TCB.  TH_FIN will
	      * be returned if reassembly now includes a segment with FIN.
	      * Ack immediately so fast retransmits can work.
	      */
	    tiflags = TcpReassemble(tcb, ti, dataBuf, socket);
	    tcb->t_flags |= TF_ACKNOW;
	}
    } else {
	TcpipUnlock(OptrToHandle(dataBuf));
	TcpipFreeDataBuffer(dataBuf);
	tiflags &= ~TH_FIN;
    }
	
    /*
     * If FIN is received ACK the FIN and transition to the appropriate
     * nex state.
     */
    if (tiflags & TH_FIN) {
	if (TCPS_HAVERCVDFIN(tcb->t_state) == 0) {
	    tcb->t_flags |= TF_ACKNOW;
	    tcb->rcv_nxt++;
	}
	switch (tcb->t_state) {
	    case TCPS_SYN_RECEIVED:
	    case TCPS_ESTABLISHED:
		LOG_STATE(TCPS_CLOSE_WAIT);
	        tcb->t_state = TCPS_CLOSE_WAIT;
		 /* 
		  * Notify socket library so it doesn't expect anymore
		  * incoming data, although it can still send data.
		  */
		TSocketIsDisconnected(socket, SDE_NO_ERROR, SCT_HALF, FALSE);   
		break;

	    case TCPS_FIN_WAIT_1:
		LOG_STATE(TCPS_CLOSING);
		tcb->t_state = TCPS_CLOSING;
		break;

	    case TCPS_FIN_WAIT_2:
		TSocketIsDisconnected(socket, SDE_NO_ERROR, SCT_FULL, FALSE);
		LOG_STATE(TCPS_TIME_WAIT);
		tcb->t_state = TCPS_TIME_WAIT;
		TcpCancelTimers(tcb);
		    	    	    /* fall thru to set MSL timer */
	    case TCPS_TIME_WAIT:
		tcb->t_timer[TCPT_2MSL] = 2 * TCPTV_MSL;
		break;
	}
    }

    /*
     * Return any desired output.
     */ 
    if (needoutput || (tcb->t_flags & TF_ACKNOW)) {
	TcpipUnlock(OptrToHandle(tp));
	(void) TcpOutput(tp, socket);
    } else {
	TcpipUnlock(OptrToHandle(tp));
    }
    return;

dropAfterAck:
    /*
     * Generate an ACK dropping incoming segment if it occupies 
     * sequence space, where the ACK reflects our state.
     */
    if (tiflags & TH_RST) 
	goto dropSeg;
    
    TcpipUnlock(OptrToHandle(dataBuf));
    TcpipFreeDataBuffer(dataBuf);
    
    tcb->t_flags |= TF_ACKNOW;
    TcpipUnlock(OptrToHandle(tp));
    
    (void) TcpOutput(tp, socket);
    return;
		
dropSegWithReset:
    /*
     * Generate a RST, dropping incoming segment.
     * Make ACK acceptable to originator of segment.
     * Don't bother to respond if destination was broadcast/multicast.
     */
    if ((tiflags & TH_RST) || (m->MH_flags & (IF_BCAST | IF_MCAST)))
	goto dropSeg;
    if (tiflags & TH_ACK) 
	TcpRespond(tcb, ti, m, (tcp_seq)0, ti->ti_ack, TH_RST, 
		   m->MH_domain);
    else {
	if (tiflags & TH_SYN) 
	    ti->ti_len++;
	TcpRespond (tcb, ti, m, ti->ti_seq + ti->ti_len, (tcp_seq)0, 
		    TH_RST|TH_ACK, m->MH_domain);
    }

dropSeg:
    TcpipUnlock(OptrToHandle(dataBuf));
    TcpipFreeDataBuffer(dataBuf);
    if (tcb)
	TcpipUnlock(OptrToHandle(tp));
    return;
}




/***********************************************************************
 *				TcpPullOutOfBand
 ***********************************************************************
 * SYNOPSIS:	Pull out of band byte out of a segment so it doesn't 
 *	    	appear in the user's data queue.  It is still reflected
 *	    	in the segment length for sequencing purposes.  Deliver
 *	    	urgent byte to socket level.
 *
 * CALLED BY:	TcpInput
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
TcpPullOutOfBand (struct tcpcb *tcb, word urp, MbufHeader *m)
{
    /*
     * Extract the urgent byte.
     */
    word cnt = urp - 1;
    char *cp = (char *)mtod(m) + cnt;   
    
    if (cnt) 
	/*
	 * Copy data following urgent byte forward in buffer.
	 */
	memcpy(cp, cp+1, (m->MH_dataSize - cnt - 1));
    else 
	/*
	 * The first byte was the urgent data byte so just 
	 * increase the dataOffset to exclude that byte.
	 */
	m->MH_dataOffset += 1;
    
    m->MH_dataSize -= 1;    
}


/***********************************************************************
 *				TcpDoOptions
 ***********************************************************************
 * SYNOPSIS:	Process TCP options
 * CALLED BY:	TcpInput
 * PASS:    	tcb 	= Tcp control block of connection
 *	    	cp	= pointer to the option data in the buffer
 *	    	cnt 	= number of bytes of option data
 *	    	ti  	= TCP/IP header 
 *	    	link	= domain handle of outgoing interface
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:	Only the max segment size option is currently supported.
 *	    	Window scaling and timestamp options are not.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/26/94		Initial Revision
 *
 ***********************************************************************/
void	
TcpDoOptions (struct tcpcb *tcb, 
	      byte *cp,
	      sword cnt,
	      struct tcpiphdr *ti,
	      word link)
{
    word mss;
    sword opt, optlen;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    for (; cnt > 0; cnt -= optlen, cp += optlen) {
	opt = cp[0];	
	if (opt == TCPOPT_EOL)
	    break;
	if (opt == TCPOPT_NOP)
	    optlen = 1;
	else {
	    optlen = cp[1];
	    if (optlen <= 0)
		break;
	}

	switch (opt) {
	    
	    default: 
	    	continue;
	    
	    case TCPOPT_MAXSEG:
		if (optlen != TCPOLEN_MAXSEG)
		    continue;
		if (!(ti->ti_flags & TH_SYN))
		    continue;
		memcpy((char *)&mss, (char *)cp + 2, sizeof(mss));
		mss = NetworkToHostWord(mss);
		(void) TcpMSS(tcb, mss, link);    	/* sets t_maxseg */
		break;
	
	}
    }

}

