/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  SOCKET
 * MODULE:	  rawIp.c
 * FILE:	  rawIp.c
 *
 * AUTHOR:  	  Jennifer Wu: Oct 14, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	RawIpInput
 *	RawIpOutput
 *	RawIpError
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/14/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Implementation based on BSD.
 *
 *	$Id: rawIp.c,v 1.1 97/04/18 11:57:13 newdeal Exp $
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
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <rawIp.h>
#include <icmp.h>
#include <tcpip.h>


#ifdef __HIGHC__
#pragma Code("RAWIPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg RAWIPCODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("RAWIPCODE")
#endif


/***********************************************************************
 *				RawIpInput
 ***********************************************************************
 * SYNOPSIS:	Deliver raw ip data to client.
 * CALLED BY:	IpInput, IcmpInput
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/14/94		Initial Revision
 *
 ***********************************************************************/
void
RawIpInput (optr dataBuffer, word hlen)
{
    DatagramHeader *d;
    struct ip *iphdr;

    /*
     * Restore IP length to include IP header and then deliver it.
     */
    TcpipLock(OptrToHandle(dataBuffer));
    d = (DatagramHeader *)LMemDeref(dataBuffer);
    iphdr = (struct ip *)mtod((MbufHeader *)d);

    iphdr->ip_len += hlen;

    TcpipUnlock(OptrToHandle(dataBuffer));
    TSocketRecvRawInput(dataBuffer);

}


/***********************************************************************
 *				RawIpOutput
 ***********************************************************************
 * SYNOPSIS:	Send a raw ip packet.
 *
 * CALLED BY:	EXTERNAL
 * RETURN:	word = SocketDrError
 * STRATEGY:
 *	    	If IP header is not included, add the IP header.
 *	    	Pass to IpOutput.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/14/94		Initial Revision
 *
 ***********************************************************************/
word
RawIpOutput (optr dataBuffer, word link)
{
    DatagramHeader *d;
    byte flags = IP_RAWOUTPUT;

    TcpipLock(OptrToHandle(dataBuffer));
    d = (DatagramHeader *)LMemDeref(dataBuffer);

    /*
     * Add IP header if not included and fill in ttl, tos, protocol,
     * len and IP addresses before sending to IP level.
     */
    if ((d->DH_common.MH_flags & RIF_IP_HEADER) == 0) {
	struct ip *iphdr;
    	word len = d->DH_common.MH_dataSize;
	    	/* skip link address part when getting IP address */
	dword dstAddr = *((dword *)(mtoa(d) + 2 + *(word *)mtoa(d)));

	flags = 0;

	d->DH_common.MH_dataOffset -= sizeof (struct ip);
	d->DH_common.MH_dataSize += sizeof (struct ip);

    	iphdr = (struct ip *)mtod((MbufHeader *)d);
	iphdr->ip_p = IPPROTO_RAW;
    	iphdr->ip_src = LinkGetLocalAddr(link);
	iphdr->ip_dst = dstAddr;
	iphdr->ip_len = len + sizeof (struct ip);
	iphdr->ip_ttl = ip_defttl;
	iphdr->ip_tos = IPTOS_RELIABILITY;
    }

    TcpipUnlock(OptrToHandle(dataBuffer));
    return (IpOutput(dataBuffer, link, flags));
}


/***********************************************************************
 *				RawIpError
 ***********************************************************************
 * SYNOPSIS:	Handle an ICMP error.
 * CALLED BY:	IcmpInput
 * PASS:    	code	= ICMP code
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	10/14/94		Initial Revision
 *
 ***********************************************************************/
void
RawIpError (word code)
{
    if ((code = IcmpDecode(code)) != 0)
	TSocketNotifyError(code, 0);
}
