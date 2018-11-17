/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ip.h
 *
 * AUTHOR:  	  Jennifer Wu: May  8, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 8/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	IP Protocol definitions.
 *
 *
 * 	$Id: ip.h,v 1.1 95/07/11 15:32:22 jwu Exp $
 *
 ***********************************************************************/
#ifndef _IP_H_
#define _IP_H_

struct iphdr {
    	byte 	ip_hl:4,  	     	/* header length */
                ip_v:4;   	    	/* version */
	byte	ip_tos;	    	    	/* type of service */
    	sword   ip_len;			/* total length */
	word	ip_id;			/* identification */
	sword	ip_off;			/* fragment offset field */
#define	IP_MF 0x2000			/* more fragments flag */
#define	IP_OFFMASK 0x1fff		/* mask for fragmenting bits */
	byte	ip_ttl;	    	    	/* time to live */
	byte 	ip_p;	    	    	/* protocol */
	word 	ip_cksum;   	    	/* checksum */
	dword 	ip_src;	    	    	/* source address */
	dword	ip_dst;	    	    	/* dest address */
};

/* 
 * Definitions for protocol numbers.
 */
#define	IPPROTO_IP		0		/* dummy for IP */
#define	IPPROTO_ICMP		1		/* control message protocol */
#define	IPPROTO_TCP		6		/* tcp */
#define IPPROTO_UDP 	    	17  	    	/* udp */

struct tcphdr {
    word    th_sport;	    /* source port */
    word    th_dport;	    /* destination port */
    dword   th_seq; 	    /* sequence number */
    dword   th_ack; 	    /* acknowledgement number */
    byte    th_x2:4,	    /* (unused) */
    	    th_off:4;	    /* data offset (a.k.a. header length) */
    byte    th_flags;	    
#define TH_FIN	0x01
#define TH_SYN	0x02
#define TH_RST	0x04
#define TH_PUSH	0x08
#define TH_ACK	0x10
#define TH_URG	0x20
    word    th_win; 	    /* window size */
    word    th_cksum; 	    /* checksum */
    word    th_urp; 	    /* urgent pointer */
};

#define htons	ntohs
#define htonl	ntohl

extern unsigned short ntohs (unsigned short s);
extern unsigned long ntohl (unsigned long l);
extern byte ppp_ip_input(), ip_vj_comp_input (), ip_vj_uncomp_input ();
extern void ppp_ip_output ();

#endif /* _IP_H_ */
