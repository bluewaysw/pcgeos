/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ipcp.h
 *
 * AUTHOR:  	  Jennifer Wu: May  5, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 5/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	IP Control Protocol definitions.
 *
 *
 * 	$Id: ipcp.h,v 1.6 96/01/18 16:58:23 jwu Exp $
 *
 ***********************************************************************/
/* 
 *
 * Copyright (c) 1989 Carnegie Mellon University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by Carnegie Mellon University.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#ifndef _IPCP_H_
#define _IPCP_H_

/*
 *	Configuration options
 */
# define    CI_ADDRS	    	1	/* IP Addresses (deprecated) */
# define    CI_COMPRESSTYPE    	2	/* Compression Type */
# define    CI_ADDR	    	3	/* IP Address */

# define    CI_MS_DNS1    	129 	/* MS-IPCP primary DNS address */
# define    CI_MS_DNS2 	    	131 	/* MS-IPCP secondary DNS address */

# define	IPCP_MAXCI	5	/* Number of supported conf. option */
                                        /* Note: this used to be "largest"
					   supported option */

/*
 * 	Configuration option lengths.
 */
# define CI_ADDRS_LEN	    	10
# define CI_VJ_COMP_LEN	    	6
# define CI_ADDR_LEN	    	6
# define CI_MS_DNS_LEN	    	6

/*
 * 	Values in ipcp_neg.
 */
# define    	IN_NEG_ADDRS  	0x01	/* Negotiate IP Addresses */
# define    	IN_NEG_VJ 	0x02	/* Van Jacobson TCP hdr compression */
# define    	IN_OLD_ADDRS	0X04	/* Peer can only speak IP-Addresses */

# define    	IN_MS_DNS1   	0x08	/* MS-IPCP primary DNS address */
# define    	IN_MS_DNS2  	0x10	/* MS-IPCP secondary DNS address */

typedef struct ipcp_options
{
    ByteFlags	ipcp_neg;   

    unsigned long ouraddr, heraddr;	/* Addresses in HOST BYTE ORDER */
    unsigned char soft_ouraddr;	        /* Let peer override our ouraddr 
					   setting.  */
    unsigned char soft_heraddr;	    	/* Allow peer to override our heraddr
					   setting. */

    unsigned char vj_maxslot;		/* 2**n-1, values from 3 to 127 */    
    unsigned char vj_cid;   	    	/* Compress VJ slot IDs */

    unsigned long dns1, dns2;	    	/* MS-IPCP negotiated DNS addresses 
					   in HOST BYTE ORDER */

    int rxnaks[IPCP_MAXCI + 1];		/* No. of Configure-Naks peer sent */
} ipcp_options;


/*
 * Macro for breaking up a 4-byte IP address in host format into the
 * value for each byte for use in logging format strings of form: 
 * "%lu.%lu.%lu.%lu".
 */
#define BREAKDOWN_ADDR(addr) \
    ((addr) >> 24) & 0x00ff, ((addr) >> 16) & 0x00ff, \
    ((addr) >> 8) & 0x00ff, (addr) & 0x00ff

extern fsm ipcp_fsm[];
extern ipcp_options ipcp_wantoptions[];
extern ipcp_options ipcp_gotoptions[];
extern ipcp_options ipcp_allowoptions[];
extern ipcp_options ipcp_heroptions[];

extern void ipcp_init ();
extern void ipcp_open ();
extern void ipcp_close ();
extern void ipcp_lowerup ();
extern void ipcp_lowerdown ();
extern byte ipcp_input ();
extern void ipcp_protrej ();

#ifdef LOGGING_ENABLED
#define IPCP_DEFWARNNAKS 8	/* Print a warning every 8 Naks received */
#endif /* LOGGING_ENABLED */

#endif /* _IPCP_H_ */



