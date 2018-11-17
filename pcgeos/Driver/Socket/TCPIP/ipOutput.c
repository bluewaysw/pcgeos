/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  TCP/IP Driver
 * FILE:	  ipOutput.c
 *
 * AUTHOR:  	  Jennifer Wu: Jul 15, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	IpOutput    	    Output routine for IP protocol
 *	IpLoopback  	    Loopback an outgoing packet
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/15/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Implementation based on BSD.
 *
 *	$Id: ipOutput.c,v 1.1 97/04/18 11:57:08 newdeal Exp $
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
#include <Ansi/string.h>
#include <timer.h>
#include <lmem.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <tcp.h>
#include <icmp.h>
#include <tcpip.h>
#include <tcpipLog.h>


/***********************************************************************
 *				IpLoopback
 ***********************************************************************
 * SYNOPSIS:	Loop back a copy of an IP packet to the input queue.
 * CALLED BY:	IpOutput
 * PASS:    	dataBuffer = optr of _locked_ data buffer
 * 	    	link 	   = link used for packet
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    The src and dst addrs are exchanged because TCP will treat
 *	    the packet's src addr as the receiver's dst addr, and the 
 *	    packet's dst addr as the receiver's addr when looking for
 *	    the connection the packet belongs to.  
 *
 *	    Loopback connections opened by the application will have 
 *	    the loopback addr as the dst addr, so TCP does not need
 *	    to handle loopback connections as a special case.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/18/94		Initial Revision
 *
 ***********************************************************************/
void
IpLoopback(optr dataBuffer) 
{

     struct ip *ip;
     MbufHeader *m;
     dword taddr;

     GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
     /*
      * Set MH_domain field to loopback link's domain if loopback.
      * and swap source and destination addresses so that TCP will
      * not have to treat loopback addresses as a special case.
      */
     m = (MbufHeader *)LMemDeref(dataBuffer);
     ip = (struct ip *)mtod(m);

     if (ip->ip_src != ip->ip_dst) {
	 m->MH_domain = LOOPBACK_LINK_DOMAIN_HANDLE;
	 taddr = ip->ip_src;
	 ip->ip_src = ip->ip_dst;
	 ip->ip_dst = taddr;
     }

     /* 
      * Convert to network format and compute checksum for IP header.
      */
    ip->ip_len = HostToNetworkWord(ip->ip_len);
    ip->ip_off = HostToNetworkWord(ip->ip_off);
    ip->ip_cksum = 0;
    ip->ip_cksum = Checksum((word *)ip, ip->ip_hl << 2);

     /*
      * Pass it to input handler for driver.
      */
    LOG_PKT(LogPacket(FALSE, m));
    TcpipUnlock(OptrToHandle(dataBuffer));
    TcpipReceivePacket(dataBuffer);

}




/***********************************************************************
 *				IpOutput
 ***********************************************************************
 * SYNOPSIS:	Output routine for IP protocol.  The data buffer contains
 * 	    	a skeletal IP header (with len, ttl, off, proto, tos, src,
 *	    	 dst). 	The buffer will be freed by the link driver.
 * CALLED BY:	Higher protocol output routines.
 * PASS:    	dataBuffer  = optr to data buffer (unlocked)
 *	    	link	    = domain handle of link driver to use
 * RETURN:	nonzero if error, 0 for no error
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    	Routing, forwarding, multicast, and IP options left out 
 *	    	of BSD code.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/18/94		Initial Revision
 *
 ***********************************************************************/
word
IpOutput (optr dataBuffer, word link, byte flags)
{
    	MbufHeader *m;
	struct ip *ip, *mhip;
	word hlen = sizeof (struct ip);
	word len, off, error = 0;
	word mtu = LinkGetMTU(link);
	
        GeodeLoadDGroup(0); 	    /* we should be in the driver's thread */    
    
     	 /* 
	  * Get to start of IP header in data buffer.
	  */
	TcpipLock(OptrToHandle(dataBuffer));
	m = (MbufHeader *)LMemDeref(dataBuffer);
	ip = (struct ip *)mtod(m);

	 /*
	  * Fill in IP header.
	  */
	if ((flags & IP_RAWOUTPUT) == 0) {
	    ip->ip_v = IPVERSION;
	    ip->ip_off &= IP_DF;
	    ip->ip_id = HostToNetworkWord(ip_id++);
	    ip->ip_hl = hlen >> 2;
        } 
	else 
	    hlen = ip->ip_hl << 2;
	
	LOG_STAT(ipstat.ips_out++;)
	    
	 /*
	  * If destination address is the loopback address or if 
	  * it is the same as the source address, then pass 
	  * data directly to input handler without putting it 
	  * on the network.  Set the domain field to the link handle
	  * so things won't crash later.
	  */
	if (IN_LOOPBACK(NetworkToHostDWord(ip->ip_dst)) ||
	    ip->ip_dst == ip->ip_src) {
	    m->MH_domain = link;
	    IpLoopback(dataBuffer);
	    return (0);
	}
	
	/* 
  	 * If the data is small enough for the interface, can just
	 * send it directly, converting to network format and 
	 * calculating the checksum.
	 */
	if (ip->ip_len <= mtu) {
	    ip->ip_len = HostToNetworkWord(ip->ip_len);
	    ip->ip_off = HostToNetworkWord(ip->ip_off);
	    ip->ip_cksum = 0;
	    ip->ip_cksum = Checksum((word *)ip, hlen);
	    
	    LOG_PKT(LogPacket(FALSE, m));
	    
	    TcpipUnlock(OptrToHandle(dataBuffer));
	    return (LinkSendData(dataBuffer, link));
	}

	 /*
	  * Too large for interface; fragment if possible.
	  * Must be able to put at least 8 bytes per fragment.
	  */
	if (ip->ip_off & IP_DF) {
	    LOG_STAT(ipstat.ips_cantfrag++;)
	    LOG_EVENT(LM_IP_DATAGRAM_TOO_BIG_BUT_CANT_FRAGMENT);
	    error = SDE_DESTINATION_UNREACHABLE;
	    goto freeBuffer;
	}
	len = (mtu - hlen) &~ 7;
	if (len < 8) 
	    goto freeBuffer;
    
    {
	optr fragBuffer;
	MbufHeader *f;
	 
	 /* 
	  * Loop through length of segment, allocate a data buffer,
	  * make new header and copy data of each part and send it.
	  * Original buffer will be freed.
	  */
	for (off = hlen; off < ip->ip_len; off += len) {
	     /*
	      * Allocate a data buffer for the fragment.  Size of data
	      * in buffer will have to be adjusted in last fragment.
	      */
	    fragBuffer = TcpipAllocDataBuffer(hlen + len, link);
	    if (fragBuffer == 0) {
		error = SDE_INSUFFICIENT_MEMORY;
		LOG_STAT(ipstat.ips_odropped++;)
		goto freeBuffer;
	    }
	    TcpipLock(OptrToHandle(fragBuffer));
	    f = (MbufHeader *)LMemDeref(fragBuffer);
	    mhip = (struct ip *)mtod(f);

	     /* 
	      * Copy the IP header and adjust off, IP_MF flag, length,
	      * checksum.  If this is the last fragment, adjust the
	      * data size in the data buffer.
	      */
	    memcpy ((byte *)mhip, (byte *)ip, hlen);
	    mhip->ip_off = ((off - hlen) >> 3) + (ip->ip_off & ~IP_MF);
	    if (ip->ip_off & IP_MF)
		mhip->ip_off |= IP_MF;
	    if (off + len >= ip->ip_len)   {		/* last fragment */
		len = ip->ip_len - off;	    	    
	    	f->MH_dataSize = len + hlen;
	    }
	    else
		mhip->ip_off |= IP_MF;
	    mhip->ip_off = HostToNetworkWord(mhip->ip_off);
	    mhip->ip_len = HostToNetworkWord(len + hlen);
	    mhip->ip_cksum = 0;
	    mhip->ip_cksum = Checksum((word *)mhip, hlen);
	    
	     /*
	      * Copy the portion of the data into the fragment, then
	      * send it off to the network.
	      */
	    memcpy((byte *)(mhip) + hlen, (byte *)(ip) + off, len);
	    
	    LOG_PKT(LogPacket(FALSE, f));

	    TcpipUnlock(OptrToHandle(fragBuffer));
	    LOG_STAT(ipstat.ips_ofragments++;)
	    error = LinkSendData(fragBuffer, link);
	}
	
    	LOG_EVENT(LM_IP_FRAGMENTED_DATAGRAM);

#ifdef LOG_STATS	
    	if (error == 0)
    	    ipstat.ips_fragmented++;
#endif
    }

freeBuffer:
	TcpipUnlock(OptrToHandle(dataBuffer));
	TcpipFreeDataBuffer(dataBuffer);
	return (error);

}


