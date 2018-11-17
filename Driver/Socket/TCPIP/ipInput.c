/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  TCP/IP Driver
 * FILE:	  ipInput.c
 *
 * AUTHOR:  	  Jennifer Wu: Jul 13, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	IpInit	    	    Initialize IP protocol
 *	IpExit	    	    Free up memory used by IP protocol
 *	IpInput	    	    Input handler for IP protocol
 *	IpReassemble	    Reassemble incoming fragments
 *	IpDequeueFrag	    Dequeue an element from its fragment queue
 *	IpEnqueueFrag	    Insert a fragment into the fragment queue
 * 	IpFreeFragmentQueue Free a reassembly header and all associated
 *	    	    	    datagrams in the fragment queue
 *	IpTimeoutHandler    Check if a timer expires on a reassembly queue.
 *	IpDoOptions 	    Do option processing on an IP datagram
 *	IpStripOptions	    Strip out IP options from the data buffer
 *
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/13/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Implementation based on BSD.
 *
 *	$Id: ipInput.c,v 1.1 97/04/18 11:57:04 newdeal Exp $
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

#ifdef __HIGHC__
#pragma Code("IPCODE"); 
#endif
#ifdef __BORLANDC__
#pragma codeseg IPCODE
#endif

#include <geos.h>
#include <resource.h>
#include <geode.h>
#include <Ansi/string.h>
#include <timer.h>
#include <heap.h>
#include <lmem.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <tcp.h>
#include <icmp.h>
#include <udp.h>
#include <rawIp.h>
#include <tcpip.h>
#include <tcpipLog.h>

word	ip_defttl = IPDEFTTL;  	    	/* default IP ttl */
struct  ipq ipq;    	    	    	/* IP reassembly queue */
word 	ip_id;	    	    	    	/* IP packet counter, for IDs */

dword	ip_net_host;	    	    	/* complement of netmask for
					   recognizing {sub}net broadcasts */

#ifdef LOG_STATS
struct 	ipstat ipstat;	    	    	    	
#endif


/***********************************************************************
 *				IpInit
 ***********************************************************************
 * SYNOPSIS:	Initialize the IP protocol
 * CALLED BY:	TcpipInit
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	
 * STRATEGY:
 *	Initialize reassembly queue.
 *	Initialize ID value.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/13/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
IpInit()
{
	GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */

    	ipq.next = ipq.prev = &ipq;
	ip_id = (word) TimerGetCount();
}    


/***********************************************************************
 *				IpExit
 ***********************************************************************
 * SYNOPSIS:	Free up memory used by IP protocol.
 * CALLED BY:	TcpipExit
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	   Free the reassembly queue.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
IpExit()
{
    struct ipq *p, *q;
    
    GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */
    
    for (q = ipq.next; q != &ipq; q = p) {
	p = q->next;
	IpFreeFragmentQueue(q);
    }
}



/***********************************************************************
 *				IpInput
 ***********************************************************************
 * SYNOPSIS:	IP input routine.  Checksum and byte swap header.  If
 *	    	fragmented, try to reassemble.  Process options and
 *	    	pass complete datagrams to the next level.
 *
 * CALLED BY:	method handler for MSG_TCPIP_RECEIVE_DATA
 * PASS:    	dataBuffer	= optr to MbufHeader
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	    The data buffer is locked in this routine.  If there is
 *	    something wrong with the datagram, it will be freed, 
 *	    otherwise, it will be freed by the socket library when 
 * 	    it has been delivered, or by the higher level protocols
 *	    in case of an error.
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/14/94		Initial Revision
 *
 ***********************************************************************/

void
IpInput (optr dataBuffer)
{
    struct ip *ip;
    struct ipq *fp;
    word hlen;
    byte proto;
    MbufHeader *m;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    LOG_STAT(ipstat.ips_total++;)
    
     /*
      * Lock down the data buffer so we can access the data.
      */
    TcpipLock(OptrToHandle(dataBuffer));
    m = (MbufHeader *)LMemDeref(dataBuffer);
    
    EC_ERROR_IF( m -> MH_domain > 1, -1);

    LOG_PKT(LogPacket(TRUE, m));
     
     /*
      * Packet must be at least the size of an IP header. 
      */
    if (m->MH_dataSize < sizeof (struct ip)) {
	LOG_STAT(ipstat.ips_toosmall++;)
	LOG_EVENT(LM_TCPIP_PACKET_TOO_SHORT);
	goto bad;
    }

     /*
      * Get the IP header and check the version.
      */
    ip = (struct ip *)mtod(m);
    if (ip->ip_v != IPVERSION) {
        LOG_STAT(ipstat.ips_badvers++;)
	LOG_EVENT(LM_IP_DATAGRAM_HAS_BAD_VERSION);
	goto bad;
    }

     /* 
      * Ensure the header length is at least the size of an IP header.
      */
    hlen = ip->ip_hl << 2;
    if (hlen < sizeof(struct ip)) {
        LOG_STAT(ipstat.ips_badhlen++;)
	LOG_EVENT(LM_IP_HEADER_LENGTH_TOO_SHORT);
        goto bad;
    }
    
     /* 
      * Make sure header length does not exceed size of data in buffer.
      */
    if (hlen > m->MH_dataSize) {
	LOG_STAT(ipstat.ips_badhlen++;)
	LOG_EVENT(LM_IP_HEADER_LENGTH_EXCEEDS_DATA_BUFFER_SIZE);
        goto bad;
    }

     /*
      * Verify the checksum of the IP header.
      */
    ip->ip_cksum = Checksum((word *)ip, hlen);
    if (ip->ip_cksum) {
	LOG_STAT(ipstat.ips_badsum++;)
	LOG_EVENT(LM_IP_DATAGRAM_HAS_BAD_CHECKSUM);
        goto bad;
    }

     /*
      * Convert fields to host representation.  Verify that the total
      * length exceeds the header length.
      */
    ip->ip_len = NetworkToHostWord(ip->ip_len);
    if (ip->ip_len < hlen) {
	LOG_STAT(ipstat.ips_badlen++;)
	LOG_EVENT(LM_IP_LENGTH_SHORTER_THAN_IP_HEADER_LENGTH);
        goto bad;
    }
    ip->ip_id = NetworkToHostWord(ip->ip_id);
    ip->ip_off = NetworkToHostWord(ip->ip_off);

     /* 
      * Check that the amount of data in the buffer is at least as
      * much as the IP header would have us expect.  Drop any extra
      * padding that may be at the end of the data buffer.
      */
    if (m->MH_dataSize < ip->ip_len) {
	LOG_STAT(ipstat.ips_tooshort++;)
	LOG_EVENT(LM_IP_LENGTH_EXCEEDS_DATA_BUFFER_SIZE);
        goto bad;
    }

    m->MH_dataSize = ip->ip_len;
    m->MH_flags = 0;
     
     /*
      * Verify that the source address is valid and that the packet is for us.
      */
  {
    dword addr = NetworkToHostDWord(ip->ip_src);
    if (IN_BROADCAST(addr) || IN_MULTICAST(addr)) {
	LOG_EVENT(LM_IP_DATAGRAM_BAD_SOURCE_ADDRESS);
	goto bad;
    }
    
    addr = NetworkToHostDWord(ip->ip_dst);
    if (IN_BROADCAST(addr))
	m->MH_flags |= IF_BCAST;
    else if (IN_MULTICAST(addr)) 
	m->MH_flags |= IF_MCAST;
    else if (! (IN_LOOPBACK(NetworkToHostDWord(ip->ip_src)) || 
		ip->ip_src == ip->ip_dst) && 
	     LinkCheckLocalAddr (m->MH_domain, ip->ip_dst)) {
	LOG_EVENT(LM_IP_DATAGRAM_NOT_FOR_US);
	goto bad;
    }
  }
     
     /*
      * If the header length is greater than a standard IP header,
      * it contains options.  Process them.  IpDoOptions returns 1 
      * when an error was detected.
      */     
    if (hlen > sizeof (struct ip) && IpDoOptions(m)) 
	    goto bad;
     
     /* 
      * If offset is nonzero or IP_MF is set, then this is a fragment
      * and reassembly is needed.  Otherwise, nothing needs to be done.
      * (BSD comment:  We could look in the reassembly queue to see if
      * the packet was previously fragmented, but it's not worth the
      * time; just let them time out.)
      */
    if (ip->ip_off &~IP_DF) {
	/*
         * Look for queue of fragments of this datagram.
         */
	for (fp = ipq.next; fp != &ipq; fp = fp->next) {
	    if (ip->ip_id == fp->ipq_id &&  	    /* match ID */
		ip->ip_src == fp->ipq_src &&	    /* match src addr */
		ip->ip_dst == fp->ipq_dst &&	    /* match dst addr */
		ip->ip_p == fp->ipq_p)	{    	    /* match protocol */
		    LOG_EVENT(LM_IP_RECEIVED_ANOTHER_FRAGMENT);
		    goto found;
		}
	}
	fp = 0;
	LOG_EVENT(LM_IP_RECEIVED_FIRST_FRAGMENT);
found:
    	/*
 	 * Adjust ip_len to not reflect the IP header,
	 * set ip_mff if more fragments are expected,
	 * convert offset of this to bytes.
	 */
	ip->ip_len -= hlen;
	((struct ipasfrag *)ip)->ipf_mff &= ~1;
	if (ip->ip_off & IP_MF)
	    ((struct ipasfrag *)ip)->ipf_mff |= 1;
	ip->ip_off <<= 3;   

	/*
	 * If datagram marked as having more fragments or if
	 * this is not the first fragment, attempt reassembly.
	 * Store the optr of the data buffer in the fragment header.
	 * If reassembly succeeds, proceed.
	 */
	if (((struct ipasfrag *)ip)->ipf_mff & 1 || ip->ip_off) {
	    LOG_STAT(ipstat.ips_fragments++;)
	    ip = IpReassemble((struct ipasfrag *)ip, fp, dataBuffer,
			      &dataBuffer);
	    if (ip == 0)
		 return;
	    LOG_STAT(ipstat.ips_reassembled++;)
	    LOG_EVENT(LM_IP_DATAGRAM_REASSEMBLED);
	} else 
	    if (fp) 
	    	IpFreeFragmentQueue(fp);
    } else
	ip->ip_len -= hlen;

     /*
      * Call the appropriate input routine to process the data based 
      * on the datagram's protocol.  The data buffer will be freed
      * by the socket library when delivered or by the input routines
      * if an error occurs.
      */
    LOG_STAT(ipstat.ips_delivered++;)
    
    proto = ip->ip_p;
    TcpipUnlock(OptrToHandle(dataBuffer));
    
    switch (proto) {
	case IPPROTO_ICMP:
	    IcmpInput(dataBuffer, hlen);    	    
	    return;
	case IPPROTO_TCP:
	    TcpInput(dataBuffer, hlen);
	    return;	    
        case IPPROTO_UDP:
	    UdpInput(dataBuffer, hlen);
	    return;
	case IPPROTO_RAW:
	    RawIpInput(dataBuffer, hlen);
	    return;
    	default:
	    LOG_STAT(ipstat.ips_noproto++;)
	    LOG_EVENT(LM_IP_UNSUPPORTED_PROTOCOL);
	    goto freeBuffer;	    	    	    /* already unlocked! */
    }
bad:
     /*
      * Something is wrong with received packet so free it.
      */
      TcpipUnlock(OptrToHandle(dataBuffer));
freeBuffer:
      TcpipFreeDataBuffer(dataBuffer);
      LOG_EVENT(LM_IP_DROPPING_DATAGRAM);
      return;
}



/***********************************************************************
 *				IpReassemble
 ***********************************************************************
 * SYNOPSIS:	Take incoming datagram fragments and try to reassemble
 *	    	it into a whole datagram.  If a chain for reassembly
 *	    	of this datagram already exists, then it is given in 
 * 	    	fp; otherwise have to make a chain.
 *	    
 * CALLED BY:	IpInput
 * PASS:    	ip  = IP fragment
 *	    	fp  = fragment queue, or 0 if one needs to be created
 *	    	dataBuffer = optr of locked data buffer for IP fragment
 *	    	newBuffer = place to return optr of new data buffer
 *
 * RETURN:	ip hdr of whole datagram if reassembly successful, 0 if not
 *	    	newBuffer = optr of new data buffer if reassembled
 *	    	    	    
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
struct ip *
IpReassemble(struct ipasfrag *ip, 
	     struct ipq *fp, 
	     optr dataBuffer,	    	    
	     optr *newBuffer)
{
    struct ipasfrag *q;
    word i, next, hlen;
    MemHandle queueHandle;
    MbufHeader *m;
    struct ip *newip;
    byte *p;

     /*
      * Create the reassembly queue if this is the first fragment to arrive.
      */
    if (fp == (struct ipq *)0) {
	queueHandle = MemAlloc(sizeof (struct ipq), HF_SWAPABLE, HAF_LOCK);
	fp = (struct ipq *)MemDeref(queueHandle);
	InsertQueue(fp, &ipq);
	fp->ipq_block = queueHandle;	    	
	fp->ipq_ttl = IPFRAGTTL;
	fp->ipq_p = ((struct ip *)ip)->ip_p;
	fp->ipq_id = ip->ip_id;
	fp->ipq_next = fp->ipq_prev = (struct ipasfrag *)fp;
	fp->ipq_src = ((struct ip *)ip)->ip_src;
	fp->ipq_dst = ((struct ip *)ip)->ip_dst;
	q = (struct ipasfrag *)fp;
	goto insert;
    }

     /*
      * Find a segment which begins after this one does.
      */
    for (q = fp->ipq_next; q != (struct ipasfrag *)fp; q = q->ipf_next)
	 if (q->ip_off > ip->ip_off)
	     break;

     /*
      * If there is a preceding segment, it may provide some of our data
      * already.  If so, drop the data from the incoming segment.  If it
      * provides all of our data, drop the entire incoming segment.
      */
    if (q->ipf_prev != (struct ipasfrag *)fp) {
	i = q->ipf_prev->ip_off + q->ipf_prev->ip_len - ip->ip_off;
	if (i > 0) {
	    if (i >= ip->ip_len)
		 goto dropfrag;
	    ip->ip_off += i;
	    ip->ip_len -= i;
	    LOG_EVENT(LM_IP_DROPPING_OVERLAPPING_BYTES);
	}
    }

     /*
      * While we overlap succeeding segments, trim them or if they
      * are completely covered, dequeue them.
      */
    while (q != (struct ipasfrag *)fp && 
	   ip->ip_off + ip->ip_len > q->ip_off) {
	   
	   i = (ip->ip_off + ip->ip_len) - q->ip_off;
	   if (i < q->ip_len) {
	       q->ip_len -= i;
	       q->ip_off += i;
	       LOG_EVENT(LM_IP_DROPPING_OVERLAPPING_BYTES);
	       break;
	   }
	   LOG_EVENT(LM_IP_DROPPING_COMPLETELY_OVERLAPPED_FRAGMENT);
	   q = q->ipf_next;
	   IpDequeueFrag(q->ipf_prev);
    }

insert:
     /*
      * Stick the new segment in its place and check for complete
      * reassembly.
      */
    ip->ipf_buffer = dataBuffer;    	    /* store optr */
    IpEnqueueFrag(ip, q->ipf_prev);
    next = 0;
    for (q = fp->ipq_next; q != (struct ipasfrag *)fp; q = q->ipf_next) {
	if (q->ip_off != next)
	    	return (0);
	next += q->ip_len;  	    	    /* accumulate the size */
    }
    if (q->ipf_prev->ipf_mff & 1)
	return (0);
    
     /*
      * Reassembly is complete; concantenate fragments.  Allocate a 
      * new data buffer for the whole datagram.  Determine length 
      * of IP header for original datagram.
      */
    hlen = fp->ipq_next->ip_hl << 2;	    
    m = (MbufHeader *)LMemDeref(dataBuffer);

     /*
      * TcpipAllocDataBuffer sets the MH_domain field to TCP's 
      * client handle, but we want it set to the link's domain
      * handle because this packet is incoming.  
      */
    i = m->MH_domain;	    	    	
    *newBuffer = TcpipAllocDataBuffer(next + hlen, i);
    
    TcpipLock(OptrToHandle(*newBuffer));
    m = (MbufHeader *)LMemDeref(*newBuffer);	
    m->MH_domain = i;	    	    	

    newip = (struct ip *)mtod(m);

     /*
      * Go through all the fragments in the fragment queue and copy
      * the data to the new buffer.  Don't forget to save room for 
      * original datagram's IP header and any IP options it contains.
      */
    p = (byte *)newip + hlen;	 
    
    for (q = fp->ipq_next; q != (struct ipasfrag *)fp; q = q->ipf_next) {
	memcpy(p, (byte *)q + (q->ip_hl << 2), q->ip_len);
	p += q->ip_len;
    }

     /* 
      * Copy IP header and IP options from first fragment of datagram.
      * Modify the header to create the header for the reassembled IP 
      * datagram.  Restore fields which were overlaid with other data.
      * Checksum and ttl fields don't need to be restored because they 
      * aren't used by higher levels.  
      */
    memcpy((byte *)newip, (byte *)fp->ipq_next, hlen);
    newip->ip_len = next;
    newip->ip_src = fp->ipq_src;
    newip->ip_dst = fp->ipq_dst;
    newip->ip_tos &= ~1;   	/* restore low bit of tos field */
    newip->ip_p = fp->ipq_p;	/* restore protocol field */
    
      /*
       * Remove the fragment queue from the reassembly queue and free
       * it.
       */
    IpFreeFragmentQueue(fp);

    return (newip);

dropfrag:
    LOG_STAT(ipstat.ips_fragdropped++;)
    LOG_EVENT(LM_IP_DROPPING_COMPLETELY_OVERLAPPED_FRAGMENT);
    TcpipUnlock(OptrToHandle(dataBuffer));
    TcpipFreeDataBuffer(dataBuffer);
    return (0);
}



/***********************************************************************
 *				IpDequeueFrag
 ***********************************************************************
 * SYNOPSIS:	Dequeue the element from its fragment queue and free it.
 * CALLED BY:	IpReassemble
 * PASS:    	f = fragment in queue to remove
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
void
IpDequeueFrag (struct ipasfrag *f)
{
    optr buf = f->ipf_buffer;

    f->ipf_next->ipf_prev = f->ipf_prev;
    f->ipf_prev->ipf_next = f->ipf_next;
    
    TcpipUnlock(OptrToHandle(buf));
    TcpipFreeDataBuffer(buf);
}


/***********************************************************************
 *				IpEnqueueFrag
 ***********************************************************************
 * SYNOPSIS:	Insert a fragment into the fragment queue.
 * CALLED BY:	IpReassemble
 * PASS:    	f = fragment to insert
 *	    	prev = fragment to insert after
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
void
IpEnqueueFrag (struct ipasfrag *f, 
	       struct ipasfrag *prev)
{
    f->ipf_prev = prev;
    f->ipf_next = prev->ipf_next;
    prev->ipf_next->ipf_prev = f;
    prev->ipf_next = f;
}


/***********************************************************************
 *				IpFreeFragmentQueue
 ***********************************************************************
 * SYNOPSIS:	Free a fragment reassembly header and all associated
 * 	    	datagrams.
 * CALLED BY:	IpReassemble
 * PASS:    	fp = fragment queue
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
void
IpFreeFragmentQueue(struct ipq *fq)
{
    struct ipasfrag *q, *p;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    RemoveQueue(fq);
    for (q = fq->ipq_next; q != (struct ipasfrag *)fq; q = p) {
	LOG_EVENT(LM_IP_DISCARDING_FRAGMENT_FROM_QUEUE);
	p = q->ipf_next;
	IpDequeueFrag(q);   
    }
    MemFree(fq->ipq_block);
}

#ifdef __HIGHC__
#pragma Code("TSOCKETCODE"); 
#endif
#ifdef __BORLANDC__
#pragma codeseg TSOCKETCODE
#endif


/***********************************************************************
 *				IpTimeoutHandler
 ***********************************************************************
 * SYNOPSIS:	If a timer expires on a reassembly queue, discard it.
 * CALLED BY:	method handler for MSG_TCPIP_TIMEOUT_OCCURRED
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
void 
IpTimeoutHandler ()
{
    struct ipq *fq;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    fq = ipq.next;
    
    if (fq == 0)
	return;

    while (fq != &ipq) {
	fq->ipq_ttl--;	    	
	fq = fq->next;
	if (fq->prev->ipq_ttl == 0) {
	    LOG_STAT(ipstat.ips_fragtimeout++;)
	    LOG_EVENT(LM_IP_DISCARDING_FRAGMENT_QUEUE);
	    IpFreeFragmentQueue(fq->prev);
	}
    }
    return;
}

#ifdef __HIGHC__
#pragma Code("IPCODE"); 
#endif
#ifdef __BORLANDC__
#pragma codeseg IPCODE
#endif


/***********************************************************************
 *				IpDoOptions
 ***********************************************************************
 * SYNOPSIS:	Do option processing on an IP datagram.  
 *
 * CALLED BY:	IpInput
 * PASS:    	MbufHeader *m
 * RETURN:	1 if packet is bad
 *	    	0 if packet should be processed further
 * SIDE EFFECTS:
 *	    Icmp generates an error msg if options are bad.
 * STRATEGY:
 *	   No support for timestamp, record route, source routing
 *	   nor forwarding options.  Hmmm...there's nothing left...
 * 	   I'll leave this stub here so that support for options
 *	   can be added in the future without having to rewrite 
 *	   the Ip input routine.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/15/94		Initial Revision
 *
 ***********************************************************************/
int
IpDoOptions (MbufHeader *m)
{
    struct ip *ip = (struct ip *)mtod(m);
    byte *cp;
    word opt, optlen, cnt, code, type = ICMP_PARAMPROB;
    
    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    cp = (byte *)(ip + 1);  	    /* increments cp by size of ip hdr */
    cnt = (ip->ip_hl << 2) - sizeof (struct ip);
    for (; cnt > 0; cnt -= optlen, cp += optlen) {
	opt = cp[IPOPT_OPTVAL];
	if (opt == IPOPT_EOL) 
	    break;
	if (opt == IPOPT_NOP)
	    optlen = 1;
	else {
	    optlen = cp[IPOPT_OLEN];
	    if (optlen <= 0 || optlen > cnt) {
		code = &cp[IPOPT_OLEN] - (byte *)ip;
		goto bad;
	    }
	}
    }

    return (0);

bad:
    ip->ip_len -= ip->ip_hl << 2;  /* IcmpError adds in hdr length */
    IcmpError(m, type, code);
    LOG_STAT(ipstat.ips_badoptions++;)
    return (1);
}




/***********************************************************************
 *				IpStripOptions
 ***********************************************************************
 * SYNOPSIS:	Strip out IP options from the data buffer.
 * CALLED BY:	TcpInput
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    	Copy IP header into area in buffer directly preceding
 * 	    	the next protocol level's header.  Adjust the dataSize 
 *	    	and dataOffset in the packet header to point to new start 
 *	    	of data.
 *	    NOTE:  Could copy all data after the IP header to the 
 *	    	area right after the IP header, but that is usually more
 *	    	bytes to copy since the data size is usually >  size 
 *	    	of an IP header.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/21/94		Initial Revision
 *
 ***********************************************************************/
void
IpStripOptions (optr dataBuffer)
{
    MbufHeader *m;
    struct ip *ip, *p;
    struct ip tempip;
    word hlen, optlen;

    GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
    TcpipLock(OptrToHandle(dataBuffer));
    m = (MbufHeader *)LMemDeref(dataBuffer);
    
    ip = (struct ip *)mtod(m);
    hlen = ip->ip_hl << 2;
    optlen = hlen - sizeof(struct ip);
     
     /*
      * Copy Ip header without options to a temporary ip header
      * and deduct options from length.
      */
    tempip = *ip;
    tempip.ip_hl = (hlen - optlen) >> 2;

     /*
      * Copy temp Ip header back to data buffer immediately preceding
      * the next protocol level's header.
      */
    p = (struct ip *)((byte *)(ip) + optlen);	    
    *p = tempip;

     /*
      * Now adjust dataSize and dataOffset in buffer.
      */
    m->MH_dataSize -= optlen;
    m->MH_dataOffset += optlen;
    TcpipUnlock(OptrToHandle(dataBuffer));
}


