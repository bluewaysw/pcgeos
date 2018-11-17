/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  TCP/IP Driver
 * FILE:	  udp.h
 *
 * AUTHOR:  	  Jennifer Wu: Oct  7, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/ 7/94  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for UDP.
 *
 *
 * 	$Id: udp.h,v 1.1 97/04/18 11:57:05 newdeal Exp $
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

 /*
  * User Datagram Protocol Definitions.
  * Per RFC 768.
  */

#ifndef _UDP_H_
#define _UDP_H_

/*
 * Udp protocol header.
 */
struct udphdr {
    word    uh_sport;	    	/* source port */
    word    uh_dport;	    	/* destination port */
    sword   uh_ulen;	    	/* udp length */
    word    uh_cksum;	    	/* udp checksum */
};

struct udpiphdr {
    struct ipovly ui_i;	    	/* overlaid ip header */
    struct udphdr ui_u;	    	/* udp header */
};

    	/* some defines to make accessing udpiphdr fields easier */
#define	ui_next		ui_i.ih_next
#define	ui_prev		ui_i.ih_prev
#define	ui_x1		ui_i.ih_x1
#define	ui_pr		ui_i.ih_pr
#define	ui_len		ui_i.ih_len
#define	ui_src		ui_i.ih_src
#define	ui_dst		ui_i.ih_dst
#define	ui_sport	ui_u.uh_sport
#define	ui_dport	ui_u.uh_dport
#define	ui_ulen		ui_u.uh_ulen
#define	ui_cksum	ui_u.uh_cksum


extern word UdpOutput(optr dataBuffer, dword laddr, word link);
extern void UdpInput(optr dataBuffer, word hlen);
extern void UdpError(word code, struct ip* iphdr);

 
 /*----------------------------------------------------------------------
  * Keeping track of UDP statistics. 
  ----------------------------------------------------------------------*/
#ifdef LOG_STATS
struct udpstat {
    	    	    	/* input stats */
    sdword  udps_ipackets;  	    /* total input packets */
    sdword  udps_hdrops;    	    /* packet shorter than header */
    sdword  udps_badsum;    	    /* checksum error */
    sdword  udps_badlen;    	    /* data length larger than packet */
    sdword  udps_noport;
    sdword  udps_noportbcast;
    	    	    	/* output stats */
    sdword  udps_opackets;  	    /* total output packets */
};

extern struct	udpstat	udpstat;

#endif /* LOG_STATS */

#endif /* _UDP_H_ */
