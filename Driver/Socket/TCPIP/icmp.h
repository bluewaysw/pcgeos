/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  TCP/IP Driver
 * MODULE:	  ICMP
 * FILE:	  icmp.h
 *
 * AUTHOR:  	  Jennifer Wu: Jul  6, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 6/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for ICMP.
 *
 *
 * 	$Id: icmp.h,v 1.1 97/04/18 11:57:05 newdeal Exp $
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
 * Interface Control Message Protocol Definitions.
 * Per RFC 792, September 1981.
 */

#ifndef _TCPIPICMP_H_
#define _TCPIPICMP_H_


/* ---------------------------------------------------------------------------
 *
 * Structure of an ICMP message.
 *
 -------------------------------------------------------------------------- */
struct icmp {
    byte   icmp_type;	    	/* type of message */
    byte    	    icmp_code;	    	/* type of sub code */
    word    	    icmp_cksum;	    	/* ones complement checksum of msg */
    union { 	    	    	    	
	    byte    ih_pptr;	    	/* ICMP_PARAMPROB */
	    dword   ih_gwaddr;	    	/* ICMP_REDIRECT */
	    struct  ih_idseq {
		    word    icd_id;
		    word    icd_seq;
	    } ih_idseq;
	    dword   ih_void;	    	/* must be zero */
    } icmp_hun;	    	    	    	/* header for ICMP data */
    union {
	    struct  id_ts { 	    	/* timestamp option */
		    dword its_otime;	/* originate timestamp */
		    dword its_rtime;   /* receive timestamp */
		    dword its_ttime;	/* transmit timestamp */
	    } id_ts;
	    struct  id_ip { 	    	/* problem with received IP datagram */
		    struct  ip	idi_ip;
		    	/* options and then 64 bits of data */
	    } id_ip;
	    dword   id_mask;
	    char    id_data[1];
    } icmp_dun;	    	    	    	/* data portion of ICMP message */
};
		
/* 
 * some defines to simplify access to header union in ICMP struct
 */
#define	icmp_pptr	icmp_hun.ih_pptr    	
#define	icmp_gwaddr	icmp_hun.ih_gwaddr
#define	icmp_id		icmp_hun.ih_idseq.icd_id
#define	icmp_seq	icmp_hun.ih_idseq.icd_seq
#define	icmp_void	icmp_hun.ih_void
#define	icmp_pmvoid	icmp_hun.ih_pmtu.ipm_void
#define	icmp_nextmtu	icmp_hun.ih_pmtu.ipm_nextmtu

    	    	    	/* some defines to simplify access to data union */
#define	icmp_otime	icmp_dun.id_ts.its_otime
#define	icmp_rtime	icmp_dun.id_ts.its_rtime
#define	icmp_ttime	icmp_dun.id_ts.its_ttime
#define	icmp_ip		icmp_dun.id_ip.idi_ip
#define	icmp_mask	icmp_dun.id_mask
#define	icmp_data	icmp_dun.id_data	    

/* ---------------------------------------------------------------------------
 *
 * Definition of ICMP type and code field values.
 *
 --------------------------------------------------------------------------- */
#define	ICMP_ECHOREPLY		0		/* echo reply */
#define	ICMP_UNREACH		3		/* dest unreachable, codes: */
#define		ICMP_UNREACH_NET	0		/* bad net */
#define		ICMP_UNREACH_HOST	1		/* bad host */
#define		ICMP_UNREACH_PROTOCOL	2		/* bad protocol */
#define		ICMP_UNREACH_PORT	3		/* bad port */
#define		ICMP_UNREACH_NEEDFRAG	4		/* IP_DF caused drop */
#define		ICMP_UNREACH_SRCFAIL	5		/* src route failed */
#define		ICMP_UNREACH_NET_UNKNOWN 6		/* unknown net */
#define		ICMP_UNREACH_HOST_UNKNOWN 7		/* unknown host */
#define		ICMP_UNREACH_ISOLATED	8		/* src host isolated */
#define		ICMP_UNREACH_NET_PROHIB	9		/* prohibited access */
#define		ICMP_UNREACH_HOST_PROHIB 10		/* ditto */
#define		ICMP_UNREACH_TOSNET	11		/* bad tos for net */
#define		ICMP_UNREACH_TOSHOST	12		/* bad tos for host */
#define	ICMP_SOURCEQUENCH	4		/* packet lost, slow down */
#define	ICMP_REDIRECT		5		/* shorter route, codes: */
#define		ICMP_REDIRECT_NET	0		/* for network */
#define		ICMP_REDIRECT_HOST	1		/* for host */
#define		ICMP_REDIRECT_TOSNET	2		/* for tos and net */
#define		ICMP_REDIRECT_TOSHOST	3		/* for tos and host */
#define	ICMP_ECHO		8		/* echo service */
#define	ICMP_ROUTERADVERT	9		/* router advertisement */
#define	ICMP_ROUTERSOLICIT	10		/* router solicitation */
#define	ICMP_TIMXCEED		11		/* time exceeded, code: */
#define		ICMP_TIMXCEED_INTRANS	0		/* ttl==0 in transit */
#define		ICMP_TIMXCEED_REASS	1		/* ttl==0 in reass */
#define	ICMP_PARAMPROB		12		/* ip header bad */
#define		ICMP_PARAMPROB_OPTABSENT 1		/* req. opt. absent */
#define	ICMP_TSTAMP		13		/* timestamp request */
#define	ICMP_TSTAMPREPLY	14		/* timestamp reply */
#define	ICMP_IREQ		15		/* information request */
#define	ICMP_IREQREPLY		16		/* information reply */
#define	ICMP_MASKREQ		17		/* address mask request */
#define	ICMP_MASKREPLY		18		/* address mask reply */

#define	ICMP_MAXTYPE		18

#define	ICMP_INFOTYPE(type) \
	((type) == ICMP_ECHOREPLY || (type) == ICMP_ECHO || \
	(type) == ICMP_ROUTERADVERT || (type) == ICMP_ROUTERSOLICIT || \
	(type) == ICMP_TSTAMP || (type) == ICMP_TSTAMPREPLY || \
	(type) == ICMP_IREQ || (type) == ICMP_IREQREPLY || \
	(type) == ICMP_MASKREQ || (type) == ICMP_MASKREPLY)

/* ---------------------------------------------------------------------------
 * 
 * Lower bounds on packet lengths for various types.
 * For generating ICMP error messages in response to bad IP datagrams, 
 * we must first ensure that the datagram is large enough to contain the
 * returned IP header.  Only then can we do the check to see if 64 bits
 * of datagram data have been returned, since we need to check the returned
 * IP header length. 
 *
 --------------------------------------------------------------------------- */

#define ICMP_MAXDATA	8   	    	    	/* max data bytes to include */
#define	ICMP_MINLEN	8				/* abs minimum header */
#define	ICMP_TSLEN	(8 + 3 * sizeof (dword))	/* timestamp */
#define	ICMP_MASKLEN	12				/* address mask */
#define	ICMP_ADVLENMIN	(8 + sizeof (struct ip) + 8)	/* min */
#define	ICMP_ADVLEN(p)	(8 + ((p)->icmp_ip.ip_hl << 2) + 8)
	/* N.B.: must separately check that ip_hl >= 5 */



extern void IcmpError(MbufHeader *n, word type, word code);
extern void IcmpInput(optr dataBuffer, word hlen);
extern void IcmpReflect(MbufHeader *m, optr icmpBuf);
extern void IcmpSend(MbufHeader *m, optr icmpBuf);
extern word IcmpDecode(word code);


/*----------------------------------------------------------------------
 *
 * Variables related to this implementation of the internet control
 * message protocol. 
 --------------------------------------------------------------------- */
#ifdef LOG_STATS

struct	icmpstat {
    /* statistics related to icmp packets generated */
    	word    icps_error; 	    /* # of calls to icmp_error */
	word	icps_oldicmp;	    /* no error 'cuz old was icmp */
	word	icps_outhist[ICMP_MAXTYPE + 1];
    /* statistics related to input messages processed */
	word	icps_badcode;	    /* icmp_code out of range */
	word	icps_tooshort;	    /* packet < ICMP_MINLEN */
	word	icps_badsum;	    /* bad checksum */
	word	icps_badlen;	    /* calculated bound mismatch */
	word	icps_reflect;	    /* number of responses */
	word	icps_inhist[ICMP_MAXTYPE + 1];
	word 	icps_packets;	    /* number of icmp packets rcvd or sent */
};

extern struct	icmpstat icmpstat;

#endif /* LOG_STATS */

#endif /* _TCPIPICMP_H_ */






