/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  SOCKET
 * MODULE:	  udp.c
 * FILE:	  udp.c
 *
 * AUTHOR:  	  Jennifer Wu: Oct  7, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	UdpInit
 * 	UdpOutput
 *	UdpInput
 *	UdpError
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/ 7/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Implementation based on BSD.
 *
 *	$Id: udp.c,v 1.1 97/04/18 11:57:11 newdeal Exp $
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
#include <Ansi/string.h>
#include <lmem.h>
#include <initfile.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <udp.h>
#include <icmp.h>
#include <tcpip.h>
#include <tcpipLog.h>

#ifdef __HIGHC__
#pragma Code("UDPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg UDPCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("UDPCODE")
#endif

byte udpcksum	= TRUE;	    	    /* whether udp checksums should be used */

#ifdef LOG_STATS
struct udpstat udpstat;
#endif


/***********************************************************************
 *				UdpInit
 ***********************************************************************
 * SYNOPSIS:	Initialize UDP.
 * CALLED BY:	TcpipInit
 * RETURN:	nothing
 * STRATEGY:	Find out if the user wants to use checksums for UDP.
 *   	    	Udp checksums can be disabled.  Default is enabled.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/18/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
UdpInit()
{
    Boolean bool;

    if (!InitFileReadBoolean("UDP", "useChecksum", &bool)) {
	if (!bool)
	    udpcksum = FALSE;
    }
}


/***********************************************************************
 *				UdpOutput
 ***********************************************************************
 * SYNOPSIS:	UDP output routine.  Fill in UDP header and send it.
 * CALLED BY:	EXTERNAL
 * PASS:    	dataBuffer  = optr of data buffer
 *	    	laddr	    = local IP address
 *	    	link	    = domain handle of link driver to use
 * RETURN:	0 if no error, else SocketDrError
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    Fill in UDP header, computing checksum if needed.
 *	    Deliver to IP output routine.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/10/94		Initial Revision
 *
 ***********************************************************************/
word
UdpOutput (optr dataBuffer, dword laddr, word link)
{
    DatagramHeader *d;
    struct udpiphdr *uihdr;
    word len;
    word error = 0;

    GeodeLoadDGroup(0);	    	    	/* Should be in driver's thread */

    TcpipLock(OptrToHandle(dataBuffer));
    d = (DatagramHeader *)LMemDeref(dataBuffer);
    len = d->DH_common.MH_dataSize;

    /*
     * Add extended UDP header to data buffer.
     */
    d->DH_common.MH_dataOffset -= sizeof (struct udpiphdr);
    d->DH_common.MH_dataSize += sizeof (struct udpiphdr);
    uihdr = (struct udpiphdr *)mtod((MbufHeader *)d);

    /*
     * Fill in UDP and IP header info.  Copy destination address first
     * so we don't overwrite it with other data.  Skip over link address
     * when getting destination address.
     */
    uihdr->ui_dst = *((dword *)(mtoa(d) + 2 + *(word *)mtoa(d)));
    uihdr->ui_next = uihdr->ui_prev = 0;
    uihdr->ui_x1 = 0;
    uihdr->ui_pr = IPPROTO_UDP;
    uihdr->ui_len = HostToNetworkWord(len + sizeof(struct udphdr));
    uihdr->ui_src = laddr;
    uihdr->ui_sport = HostToNetworkWord(d->DH_lport);
    uihdr->ui_dport = HostToNetworkWord(d->DH_rport);
    uihdr->ui_ulen = uihdr->ui_len;

    /*
     * Stuff checksum and output datagram.  Calculated zero checksums
     * must be transmitted as all 1s.
     */
    uihdr->ui_cksum = 0;
    if (udpcksum) {
	if ((uihdr->ui_cksum = Checksum((word *)uihdr,
					sizeof(struct udpiphdr) + len)) == 0)
	    uihdr->ui_cksum = 0xffff;
    }

    /*
     * Fill in IP length, desired time to live and type of service and
     * send to IP level.
     */
    ((struct ip *)uihdr)->ip_len = len + sizeof(struct udpiphdr);
    ((struct ip *)uihdr)->ip_ttl = ip_defttl;
    ((struct ip *)uihdr)->ip_tos = IPTOS_RELIABILITY;

    LOG_STAT(udpstat.udps_opackets++;)
    TcpipUnlock(OptrToHandle(dataBuffer));
    error = IpOutput(dataBuffer, link, 0);

    return (error);
}



/***********************************************************************
 *				UdpInput
 ***********************************************************************
 * SYNOPSIS:	UDP input routine.
 * CALLED BY:	IpInput
 * PASS:    	dataBuffer  = optr of data buffer
 *	    	iphlen	    = IP header length
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	    	Data buffer will either be freed or delivered to the
 *	    	socket library.
 * STRATEGY:
 *	    	Do some basic checks on the datagram and verify
 *	    	    checksum, if used.
 *	    	Fill in datagram header and deliver to socket library.
 *
 * NOTE:    	hlen has been deducted from ip_len
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/10/94		Initial Revision
 *
 ***********************************************************************/
void
UdpInput (optr dataBuffer, word iphlen)
{
    DatagramHeader *d;
    struct ip *iphdr;
    struct udphdr *uh;
    word len, domain, error = 0;
    byte flags;
    struct ip save_ip;


    GeodeLoadDGroup(0);	    	/* we should be in the driver's thread */
    LOG_STAT(udpstat.udps_ipackets++;)

     /*
      * Strip IP options, if any.  Should skip this and make options
      * available to user and use on returned packets, but we can't
      * compute the checksum with options still present.
      */
    if (iphlen > sizeof(struct ip)) {
	IpStripOptions(dataBuffer);
	iphlen = sizeof(struct ip);
    }

    TcpipLock(OptrToHandle(dataBuffer));
    d = (DatagramHeader *)LMemDeref(dataBuffer);
    iphdr = (struct ip *)mtod((MbufHeader *)d);
    uh = (struct udphdr *)((byte *)iphdr + iphlen);

     /*
      * If not enough data in buffer, drop.  Remove any extra padding.
      * Length must be at least as big as the size of an UDP header.
      */
    len = NetworkToHostWord((word)uh->uh_ulen);

    if (len < sizeof(struct udphdr)) {
	LOG_STAT(udpstat.udps_hdrops++;)
	LOG_EVENT(LM_UDP_HEADER_LENGTH_TOO_SHORT);
	goto bad;
    }

    if (iphdr->ip_len != len) {
	if (len > iphdr->ip_len) {
	    LOG_STAT(udpstat.udps_badlen++;)
	    LOG_EVENT(LM_UDP_HEADER_LENGTH_EXCEEDS_IP_LENGTH);
	    goto bad;
	}
	d->DH_common.MH_dataSize -= (iphdr->ip_len - len);
    }

     /*
      * Save copy of IP header in case we need to reconstruct it
      * to send an ICMP message in response.  Get the flags, too.
      * Also save DatagramHeader.
      */
    save_ip = *iphdr;
    flags = d->DH_common.MH_flags;
    domain = d->DH_common.MH_domain;

     /*
      * Checksum extended UDP header and data, if datagram has a
      * non-zero checksum.  Host Requirements RFC requires verification
      * of received checksums even if outgoing checksums are disabled.
      */
    if (uh->uh_cksum) {
	((struct ipovly *)iphdr)->ih_next = 0;
	((struct ipovly *)iphdr)->ih_prev = 0;
	((struct ipovly *)iphdr)->ih_x1 = 0;
	((struct ipovly *)iphdr)->ih_len = uh->uh_ulen;
	if ((uh->uh_cksum = Checksum((word *)iphdr,
				     len + sizeof(struct ip))) != 0) {
	    LOG_STAT(udpstat.udps_badsum++;)
	    LOG_EVENT(LM_UDP_DATAGRAM_HAS_BAD_CHECKSUM);
	    goto bad;
	}
    }

     /*
      * Fill in DatagramHeader and drop udp and ip header from data buffer.
      */
    d->DH_addrSize = sizeof(dword);
    d->DH_addrOffset = (byte *)(&(((struct ipovly *)iphdr)->ih_src)) -
	    	    	(byte *)d;
    d->DH_lport = NetworkToHostWord(uh->uh_dport);
    d->DH_rport = NetworkToHostWord(uh->uh_sport);

    d->DH_common.MH_dataSize -= sizeof(struct udpiphdr);
    d->DH_common.MH_dataOffset += sizeof(struct udpiphdr);

    TcpipUnlock(OptrToHandle(dataBuffer));
    error = TSocketRecvUdpInput(dataBuffer);

    if (error) {
	/*
	 * No need to send ICMP if datagram was a broadcast or multicast.
	 */
	if (flags & (IF_BCAST | IF_MCAST)) {
	    LOG_STAT(udpstat.udps_noportbcast++;)
	    goto drop;
	}

	/*
	 * Generate an ICMP error message if could not deliver the datagram.
	 * Restore IP header in original packet before calling IcmpError.
	 * Restore DatagramHeader.
	 */
	LOG_STAT(udpstat.udps_noport++;)
	LOG_EVENT(LM_UDP_RECEIVED_UNDELIVERABLE_DATAGRAM);
	TcpipLock(OptrToHandle(dataBuffer));
	d = (DatagramHeader *)LMemDeref(dataBuffer);
	d->DH_common.MH_flags = flags;
	d->DH_common.MH_domain = domain;
	d->DH_common.MH_dataSize += sizeof(struct udpiphdr);
	d->DH_common.MH_dataOffset -= sizeof(struct udpiphdr);
	iphdr = (struct ip *)mtod((MbufHeader *)d);
	*iphdr = save_ip;
	IcmpError((MbufHeader *)d, ICMP_UNREACH, ICMP_UNREACH_PORT);
    	goto bad;
    }

    return;

bad:
    TcpipUnlock(OptrToHandle(dataBuffer));
drop:
    LOG_EVENT(LM_UDP_DROPPING_DATAGRAM);
    TcpipFreeDataBuffer(dataBuffer);
    return;
}


/***********************************************************************
 *				UdpError
 ***********************************************************************
 * SYNOPSIS:	Error handler for ICMP message.
 * CALLED BY:	IcmpInput
 * PASS:    	code	= ICMP code
 *	    	iphdr	= ip header, ip options plus 64 bits of data
 *	    	    	    that was in the ICMP message
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    	Parse the data in the iphdr to determine the local
 *	    	port number and notify the socket library.
 *
 *	    	codes handled:  ICMP_SOURCEQUENCH
 *	    	    	    	ICMP_UNREACH
 *	    	    	    	ICMP_PARAMPROB
 *	    	    	    	ICMP_TIMXCEED
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/10/94		Initial Revision
 *
 ***********************************************************************/
void
UdpError (word code, struct ip *iphdr)
{
    struct udphdr *uh;

    uh = (struct udphdr *)((byte *)iphdr + (iphdr->ip_hl << 2));

    if ((code = IcmpDecode(code)) != 0)
	TSocketNotifyError(code, NetworkToHostWord(uh->uh_sport));
}
