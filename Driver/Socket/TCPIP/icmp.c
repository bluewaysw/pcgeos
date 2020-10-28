/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  icmp.c
 * FILE:	  icmp.c
 *
 * AUTHOR:  	  Jennifer Wu: Jul 18, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	IcmpError   	    Generate an ICMP error packet in response
 *	    	    	    to a bad IP packet
 *	IcmpReflect 	    Reflect an IP packet back to the source
 *	IcmpSend    	    Send an ICMP packet back to the IP level
 *	IcmpInput   	    Process a received ICMP message
 *	IcmpTime    	    Compute the number of milliseconds since
 *	    	    	    midnight
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/18/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Implementation based on BSD.
 *
 *	$Id: icmp.c,v 1.1 97/04/18 11:57:08 newdeal Exp $
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
#include <Ansi/string.h>
#include <timer.h>
#include <lmem.h>
#include <timedate.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <tcp.h>
#include <icmp.h>
#include <udp.h>
#include <rawIp.h>
#include <tcpip.h>
#include <tcpipLog.h>

#ifdef __HIGHC__
#pragma Code("ICMPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg ICMPCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("ICMPCODE")
#endif

#ifdef LOG_STATS
struct icmpstat icmpstat;
#endif


/***********************************************************************
 *				IcmpTime
 ***********************************************************************
 * SYNOPSIS:	Compute the number of milliseconds since midnight.
 * CALLED BY:	IcmpInput
 * RETURN:	number of milliseconds since midnight
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    TimerGetDateAndTime is only accurate up to seconds so
 *	    this is not very accurate...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/94		Initial Revision
 *
 ***********************************************************************/
word
IcmpTime()
{
    TimerDateAndTime dateTime;

    TimerGetDateAndTime(&dateTime);

    return ((word)(1000 * (60 * (60 * dateTime.TDAT_hours + dateTime.TDAT_minutes) + dateTime.TDAT_seconds)));
}


/***********************************************************************
 *				IcmpError
 ***********************************************************************
 * SYNOPSIS:	Generate an ICMP error packet of type error in response
 *	    	to a bad IP packet.  IP header length has been deducted
 * 	    	from ip_len in IP header of bad packet.
 * CALLED BY:	IpDoOptions, UdpInput
 * PASS:    	n   	= pointer to MbufHeader of bad packet
 *	    	type 	= ICMP message type
 *	    	code	= ICMP sub code for the message type
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/94		Initial Revision
 *
 ***********************************************************************/
void
IcmpError(MbufHeader *n, word type, word code)
{
    struct ip *oip = (struct ip *)mtod(n), *nip;
    word oiplen = oip->ip_hl << 2;
    struct icmp *icp;
    optr icmpBuf;
    MbufHeader *m;
    word icmplen;

    /*
     *	RFC 1122 :  A host SHOULD NOT send an ICMP Redirect message.
     */
    if (type == ICMP_REDIRECT)
	return;
#ifdef LOG_STATS
    else
	icmpstat.icps_error++;
#endif

     /*
      * Don't send error if the packet is not the first fragment of a
      * message.  Don't send error if the old packet protocol was ICMP
      * error message.  Only known informational types can cause
      * an ICMP error message to be generated.
      */
    if (oip->ip_off &~ (IP_MF|IP_DF))
	return;
    if (oip->ip_p == IPPROTO_ICMP &&
	n->MH_dataSize >= oiplen + ICMP_MINLEN &&
	!ICMP_INFOTYPE(((struct icmp *)((byte *)oip + oiplen))->icmp_type)) {
	LOG_STAT(icmpstat.icps_oldicmp++;)
	return;
    }

     /*
      * Don't send error in response to a multicast or broadcast packet.
      */
    if (n->MH_flags & (IF_BCAST | IF_MCAST))
	    return;

     /*
      * Don't send error if source does not define a single host --
      * e.g. a zero address or a class E address.
      */
    if (oip->ip_src == 0 ||
	IN_EXPERIMENTAL(NetworkToHostDWord(oip->ip_src)))
	return;

     /*
      * Formulate ICMP message.
      */
    icmplen = min(ICMP_MAXDATA, oip->ip_len) + oiplen;
    icmpBuf = TcpipAllocDataBuffer(icmplen + ICMP_MINLEN + sizeof(struct ip),
				   n->MH_domain);
    if (icmpBuf == 0)
	return;
    TcpipLock(OptrToHandle(icmpBuf));
    m = (MbufHeader *)LMemDeref(icmpBuf);

    nip = (struct ip *)mtod(m);
    icp = (struct icmp *)((byte *)(nip + 1));     /* increment ptr by  IP hdr */

    LOG_STAT(icmpstat.icps_outhist[type]++;)

    icp->icmp_type = type;

    icp->icmp_void = 0;
    /*
     * The following assignments assume an overlay with the
     * zeroed icmp_void field.
     */
    if (type == ICMP_PARAMPROB) {
	icp->icmp_pptr = code;  	    /* points to bad parameter */
	code = 0;
    }

    icp->icmp_code = code;

     /*
      * Copy IP header of bad packet and at most 64 bits of data into
      * ICMP message body.
      */
    memcpy((byte *)&icp->icmp_ip, (byte *)oip, icmplen);

     /*
      * Add header length back into the original IP header.  (Was
      * removed before IcmpError was called.)
      */
    icp->icmp_ip.ip_len = HostToNetworkWord(icp->icmp_ip.ip_len + oiplen);

     /*
      * Now copy old IP header (without options) in front of ICMP message.
      * Adjust fields of copied IP header.
      */
    memcpy((byte *)nip, (byte *)oip, sizeof (struct ip));
    nip->ip_len = m->MH_dataSize;
    nip->ip_hl = sizeof (struct ip) >> 2;
    nip->ip_p = IPPROTO_ICMP;
    nip->ip_tos = 0;	    	    	    /* use normal (zero) TOS */
    IcmpReflect (m, icmpBuf);
}


/***********************************************************************
 *				IcmpReflect
 ***********************************************************************
 * SYNOPSIS:	Reflect an IP packet back to the source.
 * CALLED BY:	IcmpError, IcmpInput
 * PASS:    	m      = ptr to MbufHeader of IP packet
 *	    	icmpBuf = optr of locked hugeLMem chunk holding IP packet
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    	IP option handling removed from BSD code.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/94		Initial Revision
 *
 ***********************************************************************/
void
IcmpReflect(MbufHeader *m, optr icmpBuf)
{
    struct ip *ip = (struct ip *)mtod(m);
    dword taddr;

     /*
      * If the incoming packet was addressed directly to us,
      * use dst as the src for the reply.  Otherwise (broadcast
      * or anonymous), use the address which corresponds to the
      * incoming interface.
      */
    taddr = ip->ip_dst;
    ip->ip_dst = ip->ip_src;

    if (m->MH_flags & (IF_BCAST | IF_MCAST))
	taddr = LinkGetLocalAddr(m->MH_domain);

    ip->ip_src = taddr;
    IcmpSend(m, icmpBuf);

}


/***********************************************************************
 *				IcmpSend
 ***********************************************************************
 * SYNOPSIS:	Send an ICMP packet back to the IP level.
 * CALLED BY:	IcmpReflect
 * PASS:    	m      = ptr to MbufHeader of IP packet
 *	    	icmpBuf = optr of locked hugeLMem chunk holding IP packet
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/94		Initial Revision
 *
 ***********************************************************************/
void
IcmpSend (MbufHeader *m, optr icmpBuf)
{
    struct ip *ip = (struct ip *)mtod(m);
    word hlen;
    struct icmp *icp;
    word link = m->MH_domain;

    LOG_STAT(icmpstat.icps_packets++;)

     /*
      * Compute ICMP checksum and then pass the message to the IP level.
      */
    hlen = ip->ip_hl << 2;
    icp = (struct icmp *)((byte *)(ip +1));
    icp->icmp_cksum = 0;
    icp->icmp_cksum = Checksum((word *)icp, ip->ip_len - hlen);

    TcpipUnlock(OptrToHandle(icmpBuf));
    (void) IpOutput(icmpBuf, link, 0);
}



/***********************************************************************
 *				IcmpInput
 ***********************************************************************
 * SYNOPSIS:	Process a received ICMP message.
 * CALLED BY:	IpInput
 * PASS:    	dataBuffer  = optr of data buffer of message
 *	    	hlen 	    = length of IP header
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	    	dataBuffer is freed unless it is reflected back to source
 * STRATEGY:
 *	    	Length of IP header has been removed from total len
 *	    	field in IP header by IpInput.
 *
 *	    	These are not processed because we're not a router or
 *	    	else we don't have to do anything:
 *	    	mask requests, redirects, router advertisement,
 *	    	router solicitation, info request,
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	7/19/94		Initial Revision
 *
 ***********************************************************************/
void
IcmpInput (optr dataBuffer, word hlen)
{
    MbufHeader *m;
    struct ip *iphdr;
    struct icmp *icp;
    word icmplen;
    word i, code;

    LOG_STAT(icmpstat.icps_packets++;)

     /*
      * Locate ICMP structure in the buffer.
      */
    TcpipLock(OptrToHandle(dataBuffer));
    m = (MbufHeader *)LMemDeref(dataBuffer);
    iphdr = (struct ip *)mtod(m);
    icp = (struct icmp *)((byte *)(iphdr) + hlen);
    icmplen = iphdr->ip_len;

     /*
      * Check that it is not corrupted and of at least the minimum length.
      */
    i = hlen + min(icmplen, ICMP_ADVLENMIN);
    if (icmplen < ICMP_MINLEN ||
	m->MH_dataSize < i) {
	LOG_STAT(icmpstat.icps_tooshort++;)
	goto freeit;
    }

    if (Checksum((word *)icp, icmplen)) {
	LOG_EVENT(LM_ICMP_BAD_CHECKSUM);
	LOG_STAT(icmpstat.icps_badsum++;)
	goto freeit;
    }

     /*
      * Message type specific processing.
      */
    LOG_STAT(icmpstat.icps_inhist[icp->icmp_type]++;)
    code = icp->icmp_code;

    switch (icp->icmp_type) {
	case ICMP_UNREACH:
	    code = ICMP_UNREACH;
	    goto deliver;

	case ICMP_TIMXCEED:
	case ICMP_PARAMPROB:
	    if (code > 1) {
		LOG_STAT(icmpstat.icps_badcode++;)
		goto freeit;
	    }
	    code = icp->icmp_type;
	    goto deliver;

        case ICMP_SOURCEQUENCH:
    	    if (code) {
		LOG_STAT(icmpstat.icps_badcode++;)
		LOG_EVENT(LM_ICMP_BAD_CODE);
	    	goto freeit;
	    }
	    code = ICMP_SOURCEQUENCH;

deliver:
    	    /*
	     * Problem with datagram.
	     */
	    if (icmplen < ICMP_ADVLENMIN || icmplen < ICMP_ADVLEN(icp) ||
		icp->icmp_ip.ip_hl < (sizeof (struct ip) >> 2)) {
		LOG_STAT(icmpstat.icps_badlen++;)
		goto freeit;
	    }

	     /*
	      * Advise higher lever protocol.
	      */
	    switch (icp->icmp_ip.ip_p) {
		case IPPROTO_TCP:
		    TSocketDoError(code, icp->icmp_ip.ip_dst);
		    break;
		case IPPROTO_UDP:
	    	    UdpError(code, &icp->icmp_ip);
		    break;
	        case IPPROTO_RAW:
		    RawIpError(code);
		default:
	    	    break;
	    }
   	    break;

        case ICMP_ECHO:
    	    icp->icmp_type = ICMP_ECHOREPLY;
	    goto reflect;

        case ICMP_TSTAMP:
    	    if (icmplen < ICMP_TSLEN) {
		LOG_STAT(icmpstat.icps_badlen++;)
		goto freeit;
	    }
	    icp->icmp_type = ICMP_TSTAMPREPLY;
	    /*
	     * Set high order bit of timestamp to indicate time value
	     * is not provided with respect to midnight UT.
	     */
	    icp->icmp_rtime = HostToNetworkWord(0x80 | IcmpTime());
	    icp->icmp_ttime = icp->icmp_rtime;
reflect:
	    iphdr->ip_len += hlen;	    /* since IpInput deducts this */
    	    LOG_STAT(icmpstat.icps_reflect++;)
	    LOG_STAT(icmpstat.icps_outhist[icp->icmp_type]++;)
	    IcmpReflect(m, dataBuffer);
	    return;

	case ICMP_ECHOREPLY:
        case ICMP_TSTAMPREPLY:
	case ICMP_MASKREPLY:
	    TcpipUnlock(OptrToHandle(dataBuffer));
	    RawIpInput(dataBuffer, hlen);
	    return;

        default:
    	    break;
    }
freeit:
	TcpipUnlock(OptrToHandle(dataBuffer));
	TcpipFreeDataBuffer(dataBuffer);

}



/***********************************************************************
 *				IcmpDecode
 ***********************************************************************
 * SYNOPSIS:	Translate an ICMP code to corresponding SocketDrException.
 * CALLED BY:	RawIpError, UdpError
 * PASS:    	code = ICMP error code
 * RETURN:	SocketDrException
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/14/94		Initial Revision
 *
 ***********************************************************************/
word
IcmpDecode (word code)
{
	switch (code) {
	    case ICMP_SOURCEQUENCH:
	    	code = SDX_SOURCE_QUENCH;
	    	break;
	    case ICMP_UNREACH:
	    	code = SDX_UNREACHABLE;
		break;
	    case ICMP_PARAMPROB:
	    	code = SDX_PARAM_PROBLEM;
		break;
	    case ICMP_TIMXCEED:
	    	code = SDX_TIME_EXCEEDED;
	    	break;
	    default:
		code = 0;
	        break;
	}

	return (code);
}
