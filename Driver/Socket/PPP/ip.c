/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ip.c
 *
 * AUTHOR:  	  Jennifer Wu: May  8, 1995
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	ntohs
 *	ntohl
 *
 *	ip_print    	    Log an IP header
 * 	log_buffer  	    Log data in buffer in hex and ascii format
 *	
 *	ppp_ip_input	    Process received IP packet
 *	ip_vj_comp_input    Process received VJ TCP compressed IP packet
 *	ip_vj_uncomp_input  Process received VJ TCP uncompressed IP packet
 *
 *	ppp_ip_output	    Prepare an IP packet for transmission.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 8/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP IP Protocol.
 *
 * 	$Id: ip.c,v 1.6 98/06/02 18:20:40 jwu Exp $
 *
 ***********************************************************************/

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>

#ifdef __HIGHC__
#pragma Code("IPCODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg IPCODE
#endif

unsigned short ntohs (unsigned short t) 
{
    return ((t << 8) | ((t >> 8) & 0x00ff));
}

unsigned long ntohl (unsigned long l)
{
    return (((l >> 24) & 0x000000ff) | ((l & 0x00ff0000) >> 8) | 
	    ((l & 0x0000ff00) << 8) | (l << 24));
}

#ifdef LOGGING_ENABLED


/***********************************************************************
 *				ip_print
 ***********************************************************************
 * SYNOPSIS:	Log an IP header.
 * CALLED BY:	ppp_ip_print
 *	    	ip_vj_comp_input
 *	    	ip_vj_uncomp_input
 *	    	ppp_ip_output
 *
 * RETURN:	buffer filled in with string logging IP header
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 8/95		Initial Revision
 *
 ***********************************************************************/
void ip_print (struct iphdr *iph,  	
		int len,    	    	/* length of packet */
		byte send,  	    	/* non-zero if outgoing packet */
		char *logbuf)	    	/* buffer for log string */
{
    unsigned short port[2];
    unsigned long addr[2];
    unsigned char type[2], *prot_hdr;
    char protobuf[20], *proto = protobuf, addr1[20], addr2[20],
    	*addr_string[2], *frag = "";
    unsigned long *tcpseq, *tcpack;
    unsigned short *tcpwin;
#ifdef LOGGING_ENABLED
    TCHAR logbuf2[50];
#endif

    /*
     * Find start of sub protocol header.  Copy port, source address and 
     * type.
     */
    prot_hdr = (unsigned char *)&((dword *)iph)[iph -> ip_hl];
    memcpy(port, prot_hdr, sizeof port);
    memcpy(addr, &iph -> ip_src, sizeof addr);
    memcpy(type, prot_hdr, sizeof type);

    /*
     * Determine if this is a fragment.
     */
    if (len >= 8 &&
	(ntohs(iph -> ip_off) & (IP_MF | IP_OFFMASK)))
	frag = " frag";
    

    /*
     * Determine the protocol of the IP datagram.
     */
    if (len < 10)
	proto = (char *)0;
    else if (iph -> ip_p == IPPROTO_TCP)
	proto = "tcp";
    else if (iph -> ip_p == IPPROTO_ICMP) {
	if (ntohs(iph -> ip_off) & IP_OFFMASK)
	    proto = "icmp";
	else if (len >= (int)(4 * iph -> ip_hl) + 2)
	    sprintf(proto = protobuf, "%d/%d/icmp", (int)type[0], 
		    (int)type[1]);
	else if (len >= (int)(4 * iph -> ip_hl) + 1)
	    sprintf(proto = protobuf, "%d/?/icmp", (int)type[0]);
	else
	    proto = "?/?/icmp";
    }
    else if (iph -> ip_p == IPPROTO_UDP)
	proto = "udp";
    else 
	sprintf(proto = protobuf, "%d", (int)iph -> ip_p);

    /*
     * Get address into strings.  Address is in network order.
     */
    if (len >= 16) {
	sprintf(addr_string[0] = addr1, "%lu.%lu.%lu.%lu", 
		addr[0] & 0x00ff, (addr[0] >> 8) & 0x00ff,
		(addr[0] >> 16) & 0x00ff, (addr[0] >> 24) & 0x00ff);
    }
    else
	addr_string[0] = "?";

    if (len >= 20)
	sprintf(addr_string[1] = addr2, "%lu.%lu.%lu.%lu",
		addr[1] & 0x00ff, (addr[1] >> 8) & 0x00ff,
		(addr[1] >> 16) & 0x00ff, (addr[1] >> 24) & 0x00ff);
    else
	addr_string[1] = "?";

    if (! proto)
	sprintf(logbuf, "? ? %s ? %d", send ? "->" : "<-", len);
    else if ((iph -> ip_p == IPPROTO_TCP || iph -> ip_p == IPPROTO_UDP) &&
	     (ntohs(iph -> ip_off) & 0x1fff) == 0) {
	sprintf(logbuf, "%s %s/%u %s %s/%u %u%s%s%s%s",
		proto,
		addr_string[! send],
		ntohs(port[! send]),
		send ? "->" : "<-",
		addr_string[send],
		ntohs(port[ send]),
		len,
		frag,
		(iph -> ip_p == IPPROTO_TCP &&
		 len >= (int)(4 * iph -> ip_hl) + 14 &&
		 (prot_hdr[13] & 0x02) == 0x02) ? " syn" : "",
		(iph -> ip_p == IPPROTO_TCP &&
		 len >= (int)(4 * iph -> ip_hl) + 14 &&
		 (prot_hdr[13] & 0x01) == 0x01) ? " fin" : "",
		(iph -> ip_p == IPPROTO_TCP &&
		 len >= (int)(4 * iph -> ip_hl) + 14 &&
		 (prot_hdr[13] & 0x04) == 0x04) ? " rst" : "");
	if (iph -> ip_p == IPPROTO_TCP && 
	    len >= (int)(4 * iph -> ip_hl) + 16) {
	    tcpseq = (unsigned long *)&prot_hdr[4];
	    tcpack = (unsigned long *)&prot_hdr[8];
	    tcpwin = (unsigned short *)&prot_hdr[14];
	    sprintf((char*) logbuf2, "\n\t\tseq %lu ack %lu win %u",
		    ntohl(*tcpseq), ntohl(*tcpack), ntohs(*tcpwin));
	    strcat((char*) logbuf, (const char*) logbuf2);
	}
    }
    else sprintf(logbuf, "%s %s %s %s %d%s",
		 proto,
		 addr_string[! send],
		 send ? "->" : "<-",
		 addr_string[send],
		 len,
		 frag);

}


/***********************************************************************
 *				log_buffer
 ***********************************************************************
 * SYNOPSIS:	Log data in buffer in hex and ascii format.
 * CALLED BY:	PPPSendPacket
 *	    	PPPProcessInput
 * RETURN:	nothing
 * SIDE EFFECTS:
 *	    	info is written directly to log file
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 8/95		Initial Revision
 *
 ***********************************************************************/
void log_buffer (unsigned char *buf,
		 int len)
{
# define	N_COLUMNS	16

    int column;
    char hex[3 * N_COLUMNS + 1], ascii[N_COLUMNS + 1], *hexp, *ascp;

    /*
     * For each character, if it's not printable, then make it's    
     * ascii form a "." 
     */
    for (column = 0, hexp = hex, ascp = ascii; 
	 len; 
	 --len, (++column == N_COLUMNS ? column = 0 : 0)) {
	*ascp++ = ((int)(*buf & 0x7f)) >= ' ' && ((int)(*buf & 0x7f)) <= '~' ?
	    (*buf & 0x7f) : '.';
	
	/*
	 * Add a space between every 4 bytes of hex output.
	 */
	if ((column & 0x03) == 0)
	    *hexp++ = ' ';

	*hexp++ = "0123456789ABCDEF"[(*buf >> 4) & 0x0F];
	*hexp++ = "0123456789ABCDEF"[*buf++ & 0x0F];

	/*
	 * Write out each full line.
	 */
	if (column == N_COLUMNS - 1) {
	    *hexp = *ascp = '\0';
	    log("%s \"%s\"\n", hex, ascii);
	    hexp = hex;
	    ascp = ascii;
	}
    }

    /*
     * Write our any remaining partial columns.  Padding the end of the 
     * hex output with spaces to align the ascii part.
     */
    if (column > 0) {
	for ( ; column < N_COLUMNS; ++column) {
	    if ((column & 0x03) == 0)
		*hexp++ = ' ';

	    *hexp++ = ' ';
	    *hexp++ = ' ';
	}

	*hexp = *ascp = '\0';
	log("%s \"%s\"\n", hex, ascii);
    }
}

#endif /* LOGGING_ENABLED */




/***********************************************************************
 *				ppp_ip_input
 ***********************************************************************
 * SYNOPSIS:	Process a received IP packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects idle time.
 *
 * STRATEGY: 	If IP traffic is not allowed, free packet.
 *	    	else deliver packet to TCP/IP client.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 8/95		Initial Revision
 *
 ***********************************************************************/
byte ppp_ip_input (int unit, PACKET *packet, int len)
{
#ifdef LOGGING_ENABLED
    char logbuf[MAX_STR_LEN];
#endif
    byte important = 1;
    DOLOG(struct iphdr *iph = (struct iphdr *)PACKET_DATA(packet);)

    /*
     * If IP traffic is not yet allowed, just drop the packet.
     */
    if (ipcp_fsm[unit].state != OPENED) {
	PACKET_FREE(packet);
	LOG3(LOG_NEG, (LOG_IP_NOT_OK));
	return(0);
    }

#ifdef LOGGING_ENABLED
    if (debug >= LOG_IP)  {
	ip_print(iph, len, 0, logbuf);
	log("%s\n", logbuf);
    }
#endif /* LOGGING_ENABLED */

    /*
     * Deliver to TCP/IP client.
     */
    PPPDeliverPacket(packet, unit);

    return (important);
}



/***********************************************************************
 *				ip_vj_comp_input
 ***********************************************************************
 * SYNOPSIS:	Process received VJ TCP compressed IP packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects idle time
 *
 * STRATEGY:	Drop packet if IP traffic is not allowed.
 *	    	If allowing received packets to be compressed,
 *	    	    report any errors to the uncompressor
 *	    	    uncompress the packet
 *	    	else log error
 *	    	if there is data, deliver packet to TCP/IP client.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 8/95		Initial Revision
 *
 ***********************************************************************/
byte ip_vj_comp_input (int unit, PACKET *packet, int len) 
{
#ifdef LOGGING_ENABLED
    char logbuf[MAX_STR_LEN];
#endif
    byte important = 0;
    unsigned char *cp, *origp;
    cp = origp = PACKET_DATA(packet);

    /*
     * Drop packet if IP traffic is not allowed.
     */
    if (ipcp_fsm[unit].state != OPENED) {
	PACKET_FREE(packet);
	LOG3(LOG_NEG, (LOG_IP_NOT_OK));
	return (0);
    }

    /*
     * If allowing vj compressed packets, uncompress it.  If there
     * was an FCS error, report it to the uncompressor.
     */
    if (ppp_mode_flags & SC_RX_VJ_COMP) {
	if (fcs_error) {
	    fcs_error = FALSE;
	    sl_uncompress_tcp(&cp, 0, TYPE_ERROR);
	}

	 /*
	  * Uncompress compressed TCP header and adjust packet header
	  * data size and data offset.
	  */
	len = sl_uncompress_tcp(&cp, len, TYPE_COMPRESSED_TCP);
	packet -> MH_dataSize = len;
	packet -> MH_dataOffset -= (origp - cp);

#ifdef LOGGING_ENABLED
	if (len == 0)
	    LOG3(LOG_IP, (LOG_VJ_DECOMP_FAILED, "c"));
#endif /* LOGGING_ENABLED */

    }
#ifdef LOGGING_ENABLED
    else {
	LOG3(LOG_IP, (LOG_VJ_UNEXPECTED, "compressed"));
	len = 0;    	    	    	/* so packet won't be delivered */
    }

    if (len && debug >= LOG_IP) {
	ip_print((struct iphdr *)cp, len, 0, logbuf);
	log("%s (c)\n", logbuf);
    }
#endif /* LOGGING_ENABLED */
	  
    /*
     * Deliver packet to TCP/IP client if successfully uncompressed.
     */
    if (len) {
	important = 1;
	PPPDeliverPacket(packet, unit);
    }
    else 
	PACKET_FREE(packet);

    return (important);
}


/***********************************************************************
 *				ip_vj_uncomp_input
 ***********************************************************************
 * SYNOPSIS:	Process received VJ TCP uncompressed IP packet.
 * CALLED BY:	PPPInput using prottbl entry
 * RETURN:	non-zero if packet affects idle time
 *
 * STRATEGY:	If IP traffic not allowed, drop packet.
 *	    	If negotiated compression, uncompress packet.
 *	    	If all is well, deliver packet to TCP/IP client.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 8/95		Initial Revision
 *
 ***********************************************************************/
byte ip_vj_uncomp_input (int unit, PACKET *packet, int len)
{
#ifdef LOGGING_ENABLED
    char logbuf[MAX_STR_LEN];
#endif
    byte important = 0;
    unsigned char *cp = PACKET_DATA(packet);

    /*
     * If IP traffic not allowed, drop packet.
     */
    if (ipcp_fsm[unit].state != OPENED) {
	PACKET_FREE(packet);
	LOG3(LOG_NEG, (LOG_IP_NOT_OK));
	return (0);
    }

    /*
     * If allowing vj compressed packets, uncompress it.  If there
     * was an FCS error, report it to the uncompressor.
     */ 
    if (ppp_mode_flags & SC_RX_VJ_COMP) {
	if (fcs_error) {
	    fcs_error = FALSE;
	    sl_uncompress_tcp(&cp, 0, TYPE_ERROR);
	}

	 /*
	  * No change in length so just pass 1 for the length.
	  */
	if (sl_uncompress_tcp(&cp, 1, TYPE_UNCOMPRESSED_TCP) != 0) {
	    important = 1;
	}
#ifdef LOGGING_ENABLED
	else {
	    LOG3(LOG_IP, (LOG_VJ_DECOMP_FAILED, "u"));
	}
#endif /* LOGGING_ENABLED */

    }
#ifdef LOGGING_ENABLED
    else {
	LOG3(LOG_IP, (LOG_VJ_UNEXPECTED, "uncompressed"));
    }

    if (len && debug >= LOG_IP) {
	ip_print((struct iphdr *)cp, len, 0, logbuf);
	log("%s (u)\n", logbuf);
    }
#endif /* LOGGING_ENABLED */

    /*
     * Deliver uncompressed packet to TCP/IP client if all went well.
     */
    if (important)
	PPPDeliverPacket(packet, unit);
    else 
	PACKET_FREE(packet);

    return(important);
}


/***********************************************************************
 *				ppp_ip_output
 ***********************************************************************
 * SYNOPSIS:	Output an IP packet.
 * CALLED BY:	PPPSendFrame
 * RETURN:	non-zero if packet affects idle time
 *
 * STRATEGY:	Compress packet if needed
 *	    	Send packet off for PPP framing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/ 8/95		Initial Revision
 *
 ***********************************************************************/
void ppp_ip_output (int unit, PACKET *packet)
{
#ifdef LOGGING_ENABLED
    char logbuf[MAX_STR_LEN];
#endif
    unsigned short protocol = IP;
    struct iphdr *iph = (struct iphdr *)PACKET_DATA(packet);
    
#ifdef LOGGING_ENABLED
    int logged = 0;
    if (debug >= LOG_IP) {
	ip_print(iph, packet -> MH_dataSize, logged = 1, logbuf);
	log("%s", logbuf);
    }
#endif /* LOGGING_ENABLED */

    /*
     * Compress packet if needed.  Length and data offset in packet
     * header will be adjusted for us by compression routine.
     */
    if ((ppp_mode_flags & SC_TX_VJ_COMP) &&
	iph -> ip_p == IPPROTO_TCP) {
	switch (sl_compress_tcp(packet, iph)) 
	    {
	    case TYPE_UNCOMPRESSED_TCP:
		protocol = IP_VJ_UNCOMP;
		break;

	    case TYPE_COMPRESSED_TCP:
		protocol = IP_VJ_COMP;
		break;
	    }
    }

#ifdef LOGGING_ENABLED
    if (logged) {
	log("%s\n", (protocol == IP_VJ_COMP ? " (c)" :
		     (protocol == IP_VJ_UNCOMP ? " (u)" : "")));
    }
#endif /* LOGGING_ENABLED */

    /*
     * Output the packet.
     */
    PPPSendPacket(unit, packet, protocol);
    idle_time = idle_timeout;
}
