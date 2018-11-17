/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  ip.h
 * FILE:	  ip.h
 *
 * AUTHOR:  	  Jennifer Wu: Jul  6, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 6/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for IP protocol.
 *
 *
 * 	$Id: ip.h,v 1.1 97/04/18 11:57:06 newdeal Exp $
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

#ifndef _IP_H_
#define _IP_H_

/* 
 * Definitions for internet protocol based on BSD version 4.
 */
#define IPVERSION   4

/* ------------------------------------------------------------------------
 *
 * Structure of IP header without any options.
 *
 * ---------------------------------------------------------------------- */
struct ip {
    	byte    ip_hl:4, 	/* header length */
    	        ip_v:4;	    	    	/* version */
    	byte    ip_tos; 	    	/* type of service */
    	sword    ip_len;			/* total length */
	word	ip_id;			/* identification */
	sword	ip_off;			/* fragment offset field */
#define	IP_DF 0x4000			/* dont fragment flag */
#define	IP_MF 0x2000			/* more fragments flag */
#define	IP_OFFMASK 0x1fff		/* mask for fragmenting bits */
	byte	ip_ttl;			/* time to live */
	byte	ip_p;			/* protocol */
	word	ip_cksum;		/* checksum */
	dword   ip_src;	    	    	/* source address */
	dword 	ip_dst;	    	    	/* dest address */
};

/*
 * Definitions for IP output flags.
 */
#define IP_RAWOUTPUT	0x01

#define	IP_MAXPACKET	65535		/* maximum packet size */

/* 
 * Definitions for protocol numbers.
 */
#define	IPPROTO_IP		0		/* dummy for IP */
#define	IPPROTO_ICMP		1		/* control message protocol */
#define	IPPROTO_TCP		6		/* tcp */
#define IPPROTO_UDP 	    	17  	    	/* udp */
#define IPPROTO_RAW 	    	255 	    	/* raw IP packet */

/*
 * Definitions for IP type of service (ip_tos)
 */
#define	IPTOS_LOWDELAY		0x10
#define	IPTOS_THROUGHPUT	0x08
#define	IPTOS_RELIABILITY	0x04

/*
 * Definitions for IP precedence (also in ip_tos) (hopefully unused)
 */
#define	IPTOS_PREC_NETCONTROL		0xe0
#define	IPTOS_PREC_INTERNETCONTROL	0xc0
#define	IPTOS_PREC_CRITIC_ECP		0xa0
#define	IPTOS_PREC_FLASHOVERRIDE	0x80
#define	IPTOS_PREC_FLASH		0x60
#define	IPTOS_PREC_IMMEDIATE		0x40
#define	IPTOS_PREC_PRIORITY		0x20
#define	IPTOS_PREC_ROUTINE		0x10

/*
 * Definitions for options.
 */
#define	IPOPT_COPIED(o)		((o)&0x80)
#define	IPOPT_CLASS(o)		((o)&0x60)
#define	IPOPT_NUMBER(o)		((o)&0x1f)

#define	IPOPT_CONTROL		0x00
#define	IPOPT_RESERVED1		0x20
#define	IPOPT_DEBMEAS		0x40
#define	IPOPT_RESERVED2		0x60

#define	IPOPT_EOL		0		/* end of option list */
#define	IPOPT_NOP		1		/* no operation */

#define	IPOPT_RR		7		/* record packet route */
#define	IPOPT_TS		68		/* timestamp */
#define	IPOPT_SECURITY		130		/* provide s,c,h,tcc */
#define	IPOPT_LSRR		131		/* loose source route */
#define	IPOPT_SATID		136		/* satnet id */
#define	IPOPT_SSRR		137		/* strict source route */

/*
 * Offsets to fields in options other than EOL and NOP.
 */
#define	IPOPT_OPTVAL		0		/* option ID */
#define	IPOPT_OLEN		1		/* option length */
#define IPOPT_OFFSET		2		/* offset within option */
#define	IPOPT_MINOFF		4		/* min value of above */

/*
 * Time stamp option structure.
 */
struct	ip_timestamp {
    	byte	ipt_code;   	    /* IPOPT_TS */
	byte	ipt_len;    	    /* size of structure (variable) */
	byte	ipt_ptr;    	    /* index of current entry */
	byte	ipt_flg:4,  	    /* flags, see below */
	    	ipt_oflw:4; 	    /* overflow counter */
	union	ipt_timestamp {
	    	dword	ipt_time[1];
		struct	ipt_ta {
		    	dword	ipt_addr;
			dword	ipt_time;
		    } ipt_ta[1];
	} ipt_timestamp;
};

/* flag bits for ipt_flg */
#define	IPOPT_TS_TSONLY		0		/* timestamps only */
#define	IPOPT_TS_TSANDADDR	1		/* timestamps and addresses */
#define	IPOPT_TS_PRESPEC	3		/* specified modules only */


/* bits for security (not byte swapped) */
#define	IPOPT_SECUR_UNCLASS	0x0000
#define	IPOPT_SECUR_CONFID	0xf135
#define	IPOPT_SECUR_EFTO	0x789a
#define	IPOPT_SECUR_MMMM	0xbc4d
#define	IPOPT_SECUR_RESTR	0xaf13
#define	IPOPT_SECUR_SECRET	0xd788
#define	IPOPT_SECUR_TOPSECRET	0x6bc5

/*
 * Internet implementation parameters.
 */
#define	MAXTTL		255		/* maximum time to live (seconds) */
#define	IPDEFTTL	64		/* default ttl, from RFC 1340 */
#define	IPFRAGTTL	60*2		/* time to live for frags, 60 secs */
#define	IPTTLDEC	1		/* subtracted when forwarding */

#define	IP_MSS		576		/* default maximum segment size */

/*----------------------------------------------------------------------
 *
 * Overlay for IP header used by other protocols (tcp).
 *
 ---------------------------------------------------------------------- */
struct	ipovly {
    	byte 	*ih_next, *ih_prev;	/* for protocol sequence q's */
	byte	ih_x1;	    	    	/* (unused) */
	byte	ih_pr;	    	    	/* protocol */
	word	ih_len;	    	    	/* protocol length */
	dword	ih_src;	    	    	/* source internet address */
	dword	ih_dst;	    	    	/* destination internet address */
};
	
/*----------------------------------------------------------------------
 *
 * IP reassembly queue structure.  Each fragment being reassembled is 
 * attached to one of these structures.  They are timed out after 
 * ipq_ttl drops to 0, and may also be reclaimed if memory becomes
 * tight.
 *
 --------------------------------------------------------------------- */
struct	ipq {
    	struct	ipq *next, *prev;   	/* to other reassembly headers */
	byte	ipq_ttl;    	    	/* time for reassembly q to live */
	byte	ipq_p;	    	    	/* protocol of this fragment */
	word	ipq_id;	    	    	/* sequence id for reassembly */
	struct	ipasfrag *ipq_next, *ipq_prev;
	    	    	    	    	/* to ip headers of fragments */
	dword	ipq_src;    	    	/* source internet address */
	dword	ipq_dst;    	    	/* destination internet address */
	MemHandle ipq_block;	    	/* handle of this locked memory block 
					 *  for freeing */
};

/*---------------------------------------------------------------------
 * 
 * IP header when holding a fragment.  Same as normal IP header except
 * ip_tos is overlaid with the more fragments flag.
 * 
 * Note:  ipf_next must be at same offset as ipq_next above
 *
 -------------------------------------------------------------------- */
struct	ipasfrag {
    	byte	ip_hl:4,
	    	ip_v:4;
	byte	ipf_mff;    	    /* XXX overlays ip_tos: use low bit
				     * to avoid destroying tos;
				     * copied from (ip_off&IP_MF) */
	word	ip_len;	    	    
	word	ip_id;
	word	ip_off;
	
	optr	ipf_buffer; 	    	/* optr of locked data buffer
	    	    	    	    	 * (overlays ttl, p and cksum) */
	
	struct	ipasfrag *ipf_next; 	/* next fragment (overlays src) */
	struct	ipasfrag *ipf_prev; 	/* previous fragment (overlays dst) */ 
};

/*
 * Definitions of bits in internet address integers.
 */
#define IN_CLASSA(i)	    	(((long)(i) & 0x80000000) == 0)
#define	IN_CLASSA_NET		0xff000000
#define	IN_CLASSA_NSHIFT	24
#define IN_CLASSA_HOST	    	0X00ffffff

#define IN_CLASSB(i)	    	(((long)(i) & 0xc0000000) == 0x80000000)
#define IN_CLASSB_NET	    	0xffff0000
#define IN_CLASSB_NSHIFT    	16
#define IN_CLASSB_HOST	    	0x0000ffff

#define IN_CLASSC(i)	    	(((long)(i) & 0xe0000000) == 0xc0000000)
#define IN_CLASSC_NET	    	0xffffff00
#define IN_CLASSC_NSHIFT    	8
#define IN_CLASSC_HOST	    	0x000000ff

#define	IN_CLASSD(i)		(((long)(i) & 0xf0000000) == 0xe0000000)
#define	IN_MULTICAST(i)		IN_CLASSD(i)

#define IN_EXPERIMENTAL(i)  	(((long)(i) & 0xf0000000) == 0xf0000000)

#define	INADDR_ANY		(dword)0x00000000
#define	INADDR_BROADCAST	(dword)0xffffffff	/* must be masked */
#define IN_BROADCAST(i) \
    ((long)(i) == INADDR_BROADCAST || (long)(i) == INADDR_ANY || \
    (ip_net_host && ((long)(i) & ip_net_host) == ip_net_host) || \
    (IN_CLASSA(i) && ((long)(i) & IN_CLASSA_HOST) == IN_CLASSA_HOST) || \
    (IN_CLASSB(i) && ((long)(i) & IN_CLASSB_HOST) == IN_CLASSB_HOST) || \
    (IN_CLASSC(i) && ((long)(i) & IN_CLASSC_HOST) == IN_CLASSC_HOST))

#define	IN_LOOPBACKNET		(dword)127		/* official! */
#define IN_LOOPBACK(i)	    	(((long)(i) & IN_CLASSA_NET) == \
    	    	    	    	(IN_LOOPBACKNET << IN_CLASSA_NSHIFT))

 
#define LOOPBACK_LINK_DOMAIN_HANDLE	0   	/* must match tcpip.def */

/* ---------------------------------------------------------------------
 * IP global variables
 -------------------------------------------------------------------- */
extern struct	ipq 	ipq;	      /* IP reassembly queue */
extern word	ip_id;	    	      /* IP packet counter, for ids */
extern word	ip_defttl;    	      /* default IP ttl */

extern dword	ip_net_host;         /* complement of netmask for
					  recognizing {sub}net broadcasts */


extern word IpOutput (optr dataBuffer, word link, byte flags);
extern void IpInput (optr dataBuffer);
extern struct ip *IpReassemble(struct ipasfrag *ip, 
			       struct ipq *fp,
			       optr dataBuffer,
			       optr *newBuffer);
extern void IpDequeueFrag(struct ipasfrag *f);
extern void IpEnqueueFrag(struct ipasfrag *f,
			  struct ipasfrag *prev);
extern void IpFreeFragmentQueue(struct ipq *fp);
extern void IpStripOptions(optr dataBuffer);


/* ---------------------------------------------------------------------
 * 
 * Keeping track of IP statistics.
 *
 -------------------------------------------------------------------- */

#ifdef LOG_STATS

struct	ipstat {
	word	ips_total;		/* total packets received */
	word	ips_badsum;		/* checksum bad */
	word	ips_tooshort;		/* packet too short */
	word	ips_toosmall;		/* not enough data */
	word	ips_badhlen;		/* ip header length < data size */
	word	ips_badlen;		/* ip length < ip header length */
	word	ips_fragments;		/* fragments received */
	word	ips_fragdropped;	/* frags dropped (dups, out of space) */
	word	ips_fragtimeout;	/* fragments timed out */
	word	ips_noproto;		/* unknown or unsupported protocol */
	word	ips_delivered;		/* datagrams delivered to upper level */
	word	ips_out;		/* total ip packets sent */
	word	ips_odropped;		/* lost packets due to nobufs, etc. */
	word	ips_reassembled;	/* total packets reassembled ok */
	word	ips_fragmented;		/* datagrams sucessfully fragmented */
	word	ips_ofragments;		/* output fragments created */
	word	ips_cantfrag;		/* don't fragment flag was set, etc. */
	word	ips_badoptions;		/* error in option processing */
	word	ips_badvers;		/* ip version != 4 */
};

extern struct	ipstat	ipstat;

#endif /* LOG_STATS */

#endif /* _IP_H_ */



