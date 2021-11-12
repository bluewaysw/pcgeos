/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  tcpipLog.c
 * FILE:	  tcpipLog.c
 *
 * AUTHOR:  	  Jennifer Wu: Nov 21, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	LogIpHeader
 *	LogTcpHeader
 *	LogUdpHeader
 *	LogIcmpHeader
 *	LogPacket
 *
 *	LogIpStats
 *	LogTcpStats
 *	LogUdpStats
 *	LogIcmpStats
 *	LogWriteStats
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/21/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Code for logging packets.
 * 	
 *	$Id: tcpipLog.c,v 1.1 97/04/18 11:57:18 newdeal Exp $
 ***********************************************************************/

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

#ifdef WRITE_LOG_FILE

#include <geos.h>
#include <resource.h>
#include <geode.h>
#include <Ansi/string.h>
#include <Ansi/stdio.h>
#include <file.h>
#include <ec.h>
#include <Internal/socketDr.h>
#include <ip.h>
#include <tcp.h>
#include <icmp.h>
#include <udp.h>
#include <tcpip.h>
#include <tcpipLog.h>
#ifdef DO_DBCS
/* use SBCS string routines for logging */
#include <Ansi/sbcs.h>
#endif

#ifdef __HIGHC__
#pragma Code("TCPCODE"); 
#endif
#ifdef __BORLANDC__
#pragma codeseg TCPCODE
#endif

#ifdef LOG_HDRS


/***********************************************************************
 *				LogIpHeader
 ***********************************************************************
 * SYNOPSIS:	Log the addresses and IP protocol of this packet.
 * CALLED BY:	LogPacket
 * PASS:    	log 	= file handle of log file
 *	    	dataPtr = pointer to beginning of IP header in data
 *	    	proto	= for returning IP protocol 
 *	    	dataSize = for returning total size of data in packet
 *	    	    	        
 * RETURN:	number of bytes in the IP header, including IP options
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/21/94		Initial Revision
 *
 ***********************************************************************/
word
LogIpHeader(FileHandle log, 
	    byte *dataPtr, 
	    byte *proto, 
	    word *dataSize)
{
    word cnt, hdrSize, ipId, fragOff;
    dword src, dst;
    TCHAR logBuf[MAX_LOG_STRING];
    
    *proto = ((struct ip *)dataPtr)->ip_p;
    *dataSize = NetworkToHostWord(((struct ip *)dataPtr)->ip_len);
    src = ((struct ip *)dataPtr)->ip_src;
    dst = ((struct ip *)dataPtr)->ip_dst;
    hdrSize = ((struct ip *)dataPtr)->ip_hl << 2;
    ipId = NetworkToHostWord(((struct ip *)dataPtr)->ip_id);
    fragOff = NetworkToHostWord(((struct ip *)dataPtr)->ip_off);
    
    /*
     * Write addresses and IP identification to log file.
     */
    cnt = sprintf(logBuf, "  IP Source Addr: %lu.%lu.%lu.%lu\tIP Destination Addr: %lu.%lu.%lu.%lu\n  Identification: %u\t",
		  src & 0x00ff, (src >> 8) & 0x00ff,
		  (src >> 16) & 0x00ff, (src >> 24) & 0x00ff, 
		  dst & 0x00ff, (dst >> 8) & 0x00ff, 
		  (dst >> 16) & 0x00ff, (dst >> 24) & 0x00ff,
		  ipId);
    FileWrite(log, logBuf, cnt, FALSE);

    /* 
     * Write the IP protocol to the log file.
     */
    switch (*proto) {
	case IPPROTO_TCP:
	    cnt = sprintf(logBuf, "  IP Protocol: TCP\n");
	    break;
	case IPPROTO_UDP:
	    cnt = sprintf(logBuf, "  IP Protocol: UDP\n");
	    break;
	case IPPROTO_ICMP:
	    cnt = sprintf(logBuf, "  IP Protocol: ICMP\n");
	    break;
	case IPPROTO_RAW:
	    cnt = sprintf(logBuf, "  IP Protocol: Raw IP\n");
	    break;
	case IPPROTO_IP:
	    cnt = sprintf(logBuf, "  IP Protocol: Dummy IP\n");
	    break;
	default:
	    cnt = sprintf(logBuf, "  Unknown IP Protocol\n");
	    *proto = 0;	    	/* so IP options will not be processed */
	    break;
    }
    FileWrite(log, logBuf, cnt, FALSE);    

    /*
     * If this is a fragment -- offset is nonzero or IP_MF is set --
     * then log it.  Do not log the sub-protocol's header if this 
     * fragment is not the first, because it doesn't exist.  Make
     * sure bit 0 of the flags part of the offset is zero.
     */
    if (fragOff & ~IP_DF) {
	if (fragOff & 0x8000) {
	    cnt = sprintf(logBuf, "Error:  Bit 0 of IP flags is nonzero.\n");
	    FileWrite(log, logBuf, cnt, FALSE);
	}
	fragOff <<= 3;	    	    
	cnt = sprintf(logBuf, "  Datagram is IP fragment.  Offset = %u\n",
		       fragOff);
	FileWrite(log, logBuf, cnt, FALSE);
    	if (fragOff)
	    *proto = 0;	    	/* do not log sub-proto's header */
    }

    /*
     * Log IP options, if any.
     */
    if (hdrSize > sizeof (struct ip) && (*proto != 0)) {
	byte optCode, optLen, optSize = hdrSize - sizeof(struct ip);
	dataPtr += sizeof(struct ip);  	    /* now points to options */
	
	cnt = sprintf(logBuf, "  IP Options: ");
	
	for (; optSize > 0; optSize -= optLen, dataPtr += optLen) {
	    optCode = dataPtr[0];
	    if (optCode == 0)
		break;
	    else {
		(optLen = dataPtr[1]);
	    	if (optLen <= 0)
		    break;
	    }
	    
	    switch (optCode) {
	    	case IPOPT_RR:	    	
		    cnt += sprintf(&logBuf[cnt], "\tRecord routing");
		    break;
		case IPOPT_TS:	    	
		    cnt += sprintf(&logBuf[cnt], "\tTimestamp");
		    break;
	    	case IPOPT_SECURITY:	
		    cnt += sprintf(&logBuf[cnt], "\tSecurity");
		    break;
		case IPOPT_LSRR:    	
		    cnt += sprintf(&logBuf[cnt], "\tLoose source routing");
		    break;
		case IPOPT_SSRR:    	
		    cnt += sprintf(&logBuf[cnt], "\tStrict source routing");
		    break;		
	    	default:
		    cnt += sprintf(&logBuf[cnt], "\tUnknown option");
		    continue;
	    }
	}
	
	cnt += sprintf(&logBuf[cnt], "\n");
	FileWrite(log, logBuf, cnt, FALSE);
    }

    return (hdrSize);
}


/***********************************************************************
 *				LogTcpHeader
 ***********************************************************************
 * SYNOPSIS:	Log info about the tcp header and tcp options in packet.
 * CALLED BY:	LogPacket
 * PASS:    	log 	= file handle of log file
 *	    	dataPtr = points to start of TCP header in data
 * RETURN:	number of bytes in the TCP header, including options
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/21/94		Initial Revision
 *
 ***********************************************************************/
word
LogTcpHeader (FileHandle log, byte *dataPtr)
{
    byte flags;
    word cnt, mss, hdrSize;
    TCHAR logBuf[MAX_LOG_STRING]; 	

    hdrSize = ((struct tcphdr *)dataPtr)->th_off << 2;
    flags = ((struct tcphdr *)dataPtr)->th_flags;

    /*
     * Write port numbers, seq, ack and win to log file.
     */     
    cnt = sprintf(logBuf, "  Source Port: %u\tDestination Port: %u\n  Seq: %lu\t Ack: %lu\t Window: %u\n", 
		  NetworkToHostWord(((struct tcphdr *)dataPtr)->th_sport), 
		  NetworkToHostWord(((struct tcphdr *)dataPtr)->th_dport),
		  NetworkToHostDWord(((struct tcphdr *)dataPtr)->th_seq), 
		  NetworkToHostDWord(((struct tcphdr *)dataPtr)->th_ack),
		  NetworkToHostWord(((struct tcphdr *)dataPtr)->th_win));
    FileWrite(log, logBuf, cnt, FALSE);

    /*
     * Determine which flags were used and write them to the log file.
     */
    cnt = sprintf(logBuf, "  Flags: ");
    if (flags & TH_FIN)
    	cnt += sprintf(&logBuf[cnt], "FIN ");
    if (flags & TH_SYN)
	cnt += sprintf(&logBuf[cnt], "SYN ");
    if (flags & TH_RST)
	cnt += sprintf(&logBuf[cnt], "RST ");	
    if (flags & TH_ACK)
	cnt += sprintf(&logBuf[cnt], "ACK ");	
    if (flags & TH_URG)
	cnt += sprintf(&logBuf[cnt], "URG ");	
    cnt += sprintf(&logBuf[cnt], "\n");
    FileWrite(log, logBuf, cnt, FALSE);

    /*
     * Write urgent pointer to log file, if URG set.
     */
    if (flags & TH_URG) {
	cnt = sprintf(logBuf, "  Urgent Pointer: %u\n", 
		      NetworkToHostWord(((struct tcphdr *)dataPtr)->th_urp));
	FileWrite(log, logBuf, cnt, FALSE);
    }

    /*
     * Write TCP options to log file if any.
     */
    if (hdrSize > sizeof(struct tcphdr)) {
	byte optCode, optLen, optSize = hdrSize - sizeof(struct tcphdr);
	dataPtr += sizeof(struct tcphdr); 	/* now points at options */
	
	cnt = sprintf(logBuf, "  TCP Options: ");
	for (; optSize > 0; optSize -= optLen, dataPtr += optLen) {
	    optCode = dataPtr[0];   
	    if (optCode == TCPOPT_EOL)
		break;
	    if (optCode == TCPOPT_NOP)
		optLen = 1;
	    else {
		optLen = dataPtr[1];
		if (optLen <= 0)
		    break;
	    }

	    switch (optCode) {
		default: 
		    cnt += sprintf(&logBuf[cnt], "\tUnknown option");
		    continue;
		case TCPOPT_MAXSEG:
		    memcpy((char *)&mss, (char *)dataPtr + 2, sizeof(mss));
		    cnt += sprintf(&logBuf[cnt], "\tMaximum Segment Size of %u",
				   NetworkToHostWord(mss));
	    }
	}

	cnt += sprintf(&logBuf[cnt], "\n");
	FileWrite(log, logBuf, cnt, FALSE);
    }	
	return (hdrSize);
}



/***********************************************************************
 *				LogUdpHeader
 ***********************************************************************
 * SYNOPSIS:	Log info about the udp header in packet.
 * CALLED BY:	LogPacket
 * PASS:	log 	= file handle of log file
 * 	    	dataPtr = points to start of UDP header in data
 * RETURN:  	number of bytes in UDP header
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/21/94		Initial Revision
 *
 ***********************************************************************/
word
LogUdpHeader (FileHandle log, byte *dataPtr)
{
    word cnt;
    TCHAR logBuf[MAX_LOG_STRING]; 	    
    
    cnt = sprintf(logBuf, "  Source Port: %u\t Destination Port: %u\n", 
		  NetworkToHostWord(((struct udphdr *)dataPtr)->uh_sport),
		  NetworkToHostWord(((struct udphdr *)dataPtr)->uh_dport));
    FileWrite(log, logBuf, cnt, FALSE);

    return (sizeof (struct udphdr));
}



/***********************************************************************
 *				LogIcmpHeader
 ***********************************************************************
 * SYNOPSIS:	Log info about the Icmp packet.
 * CALLED BY:	LogPacket
 * PASS:    	log 	= file handle of log file
 *	    	dataPtr = points to start of ICMP header in data
 * RETURN:	number of bytes in Icmp headers
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/21/94		Initial Revision
 *
 ***********************************************************************/
word
LogIcmpHeader (FileHandle log, byte *dataPtr)
{

    word cnt, hdrSize, id, seq;
    byte icmpType, icmpCode;
    TCHAR logBuf[MAX_LOG_STRING]; 	    
    
    hdrSize  = 4;       	/* size of type, code and checksum part */
    icmpType = dataPtr[0];
    icmpCode = dataPtr[1];
    id = (dataPtr[4] << 8) + dataPtr[5];
    seq = (dataPtr[6] << 8) + dataPtr[7];

    switch (icmpType) {
	case ICMP_ECHOREPLY:
	    cnt = sprintf(logBuf, "  Icmp echo reply\n  ID: %u\t Seq: %u\n",
			  id, seq);
	    hdrSize = 8;
	    break;
	case ICMP_UNREACH:
	    cnt = sprintf(logBuf, "  Icmp destination unreachable, code: %u\n",
			  icmpCode);
	    hdrSize = 8;
	    break;
	case ICMP_SOURCEQUENCH:
	    cnt = sprintf(logBuf, "  Icmp source quench\n");
	    break;
	case ICMP_REDIRECT:
	    cnt = sprintf(logBuf, "  Icmp redirect, code: %u\n  Router IP address to use:  %u.%u.%u.%u\n", icmpCode, dataPtr[4], dataPtr[5], dataPtr[6], 
			  dataPtr[7]);
	    hdrSize = 8;
	    break;
	case ICMP_ECHO:
	    cnt = sprintf(logBuf, "  Icmp echo request\n  ID: %u\t Seq: %u\n",
			  id, seq);
	    hdrSize = 8;    	
	    break;
	case ICMP_ROUTERADVERT:
	    cnt = sprintf(logBuf, "  Icmp router advertisement\n  Number of addresses: %u\n", dataPtr[4]);
	    
	    break;
	case ICMP_ROUTERSOLICIT:
	    cnt = sprintf(logBuf, "  Icmp router solicitation\n");
	    hdrSize = 8;
	    break;
	case ICMP_TIMXCEED:
	    cnt = sprintf(logBuf, "  Icmp time exceeded, code: %u\n", icmpCode);
	    hdrSize = 8;
	    break;
	case ICMP_PARAMPROB:
	    cnt = sprintf(logBuf, "  Icmp parameter problem, code: %u\n", 
			  icmpCode);
	    break;
	case ICMP_TSTAMP:
	    cnt = sprintf(logBuf, "  Icmp timestamp request\n  ID: %u\t Seq: %u\n", id, seq);
	    hdrSize = 20;
	    break;
	case ICMP_TSTAMPREPLY:
	    cnt = sprintf(logBuf, "  Icmp timestamp reply\n  ID: %u\t Seq: %u\n", id, seq);
	    hdrSize = 20;
	    break;
	case ICMP_IREQ:
	    cnt = sprintf(logBuf, "  Icmp information request\n");
	    break;
	case ICMP_IREQREPLY:
	    cnt = sprintf(logBuf, "  Icmp information reply\n");
	    break;
	case ICMP_MASKREQ:
	    cnt = sprintf(logBuf, "  Icmp address mask request\n  ID: %u\t Seq: %u\t Subnet mask:  %u.%u.%u.%u\n", id, seq, dataPtr[8], dataPtr[9], 
			  dataPtr[10], dataPtr[11]);
	    hdrSize = 12;
	    break;
	case ICMP_MASKREPLY:
	    cnt = sprintf(logBuf, "  Icmp address mask reply\n  ID: %u\t Seq: %u\t Subnet mask:  %u.%u.%u.%u\n", id, seq, dataPtr[8], dataPtr[9],
			  dataPtr[10], dataPtr[11]);
	    hdrSize = 12;
	    break;
	default:
    	    cnt = sprintf(logBuf, "  Unknown icmp type %u and code %u\n",
			  icmpType, icmpCode);
	    break;
    }
    
    FileWrite(log, logBuf, cnt, FALSE);
    return (hdrSize);	
}


/***********************************************************************
 *				LogPacket
 ***********************************************************************
 * SYNOPSIS:	Log a packet.
 * CALLED BY:	IpInput, IpOutput
 * PASS:    	input	= TRUE if incoming packet
 *	        m	= MbufHeader of packet to log
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/19/94		Initial Revision
 *
 ***********************************************************************/

void CALLCONV
LogPacket (Boolean input, MbufHeader *m)
{
    FileHandle log;
    byte *dataPtr;
    word dataSize, hdrSize, cnt;
    byte proto;
    
    TCHAR logBuf[20];	    	/* should be plenty */
    const TCHAR recvStr[] = "Receiving:\n";
    const TCHAR sendStr[] = "Sending:\n";

    if ((log = LogGetLogFile()) == 0)
	return;

    /*
     * Log whether this is an incoming or outgoing packet.
     */
    if (input)
	FileWrite(log, recvStr, strlen(recvStr), FALSE);
    else
	FileWrite(log, sendStr, strlen(sendStr), FALSE);

    /*
     * Log info about the IP header:  source IP addr, dest IP addr, 
     * and IP protocol.
     */
    dataPtr = mtod(m);
    hdrSize = LogIpHeader(log, dataPtr, &proto, &dataSize);
    dataPtr += hdrSize;
    dataSize -= hdrSize;

    /*
     * Log info about the specific sub-protocol.
     */
    switch (proto) {
	case IPPROTO_TCP:
	    hdrSize = LogTcpHeader(log, dataPtr);
	    goto ptrAndSize;
	case IPPROTO_UDP:
	    hdrSize = LogUdpHeader(log, dataPtr);
	    goto ptrAndSize;
	case IPPROTO_ICMP:
	    hdrSize = LogIcmpHeader(log, dataPtr);
ptrAndSize:
   	    dataPtr += hdrSize;
	    dataSize -= hdrSize;
	default:    	    
	    break;
    }

    /*
     * Write data size to log file.
     */
    cnt = sprintf(logBuf, "  Data Size: %u\n", dataSize);
    FileWrite(log, logBuf, cnt, FALSE);

#ifdef LOG_DATA
    if (dataSize) { 	    	/* don't bother if no data! */
	/*
	 * In case the headers were wrong, we want to limit the 
	 * amount of garbage written to the log file.  The buffer
	 * size will still give us some garbage as protocol headers
	 * are included in that size.
	 */
	if (dataSize > m->MH_dataSize)  {
	    dataSize = m->MH_dataSize;	
	    cnt = sprintf (logBuf, "  Data size adjusted to: %u\n", dataSize);
	    FileWrite (log, logBuf, cnt, FALSE);
	}

	FileWrite (log, dataPtr, dataSize, FALSE);
	FileWrite(log, "\n", 1, FALSE);   /* separate data from log info */
    }
#endif	/* LOG_DATA */

    FileWrite(log, "\n", 1, FALSE); 	   /* makes output easier to read */
    FileCommit(log, FALSE); 	    	    

}

#endif /* LOG_HDRS */

#ifdef LOG_STATS


/***********************************************************************
 *				LogIpStats
 ***********************************************************************
 * SYNOPSIS:	Write IP statistics to log file.
 * CALLED BY:	LogWriteStats
 * RETURN:	nothing
 * STRATEGY:	Only write stat if non-zero
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/
void 
LogIpStats (FileHandle log)
{
   word cnt, i;
   TCHAR logBuf[MAX_LOG_STRING];

#ifdef __BORLANDC__
   word stats[NUM_IP_STATS];
#endif

#ifdef __HIGHC__   
   word stats[NUM_IP_STATS] = {
       ipstat.ips_badsum, 
       ipstat.ips_tooshort,
       ipstat.ips_toosmall,
       ipstat.ips_badhlen,
       ipstat.ips_badlen,
       ipstat.ips_fragments,
       ipstat.ips_fragdropped,
       ipstat.ips_fragtimeout,
       ipstat.ips_noproto,
       ipstat.ips_odropped,
       ipstat.ips_reassembled,
       ipstat.ips_fragmented,
       ipstat.ips_ofragments,
       ipstat.ips_cantfrag,
       ipstat.ips_badoptions,
       ipstat.ips_badvers
    };       
#endif

    char *statMsg[] = {
   	"Bad checksum: ",
	"Buffer size less than IP length: ",
	"Packet shorter than minimum IP header: ",
	"IP header length exceeds buffer size: ",
	"IP length less than IP header length: ",
	"Fragments received: ",
	"Fragments dropped: ",
	"Fragments timed out: ",
	"Unknown or unsupported protocol: ",
	"Packets dropped from lack of memory: ",
	"Total packets reassembled: ",
	"Datagrams successfully fragmented: ",
	"Output fragments created: ",
	"Fragmenting needed but not allowed: ",
	"Error in option processing: ",
	"IP version not equal to 4: "
    };

#ifdef __BORLANDC__   
   stats[0] = ipstat.ips_badsum;
   stats[1] = ipstat.ips_tooshort;
   stats[2] = ipstat.ips_toosmall;
   stats[3] = ipstat.ips_badhlen;
   stats[4] = ipstat.ips_badlen;
   stats[5] = ipstat.ips_fragments;
   stats[6] = ipstat.ips_fragdropped;
   stats[7] = ipstat.ips_fragtimeout;
   stats[8] = ipstat.ips_noproto;
   stats[9] = ipstat.ips_odropped;
   stats[10] = ipstat.ips_reassembled;
   stats[11] = ipstat.ips_fragmented;
   stats[12] = ipstat.ips_ofragments;
   stats[13] = ipstat.ips_cantfrag;
   stats[14] = ipstat.ips_badoptions;
   stats[15] = ipstat.ips_badvers;
#endif

   /*
    * Values that are always printed.
    */
   cnt = sprintf(logBuf, "  IP Statistics:\n\t%-40s%u\n", 
		 "Total packet received: ", ipstat.ips_total);
   cnt += sprintf(&logBuf[cnt], "\t%-40s%u\n", "Total packets sent:", 
		  ipstat.ips_out);
   cnt += sprintf(&logBuf[cnt], "\t%-40s%u\n", 
		  "Packets delivered to upper level: ", ipstat.ips_delivered);
   FileWrite(log, logBuf, cnt, FALSE);
 
   /*
    * Values that are only printed if non-zero.
    */
   for (i = 0; i < NUM_IP_STATS; i++) {
       if (stats[i] > 0) {
	   cnt = sprintf(logBuf, "\t%-45s%u\n", statMsg[i], stats[i]);
	   FileWrite  (log, logBuf, cnt, FALSE);
       }
   }
}


/***********************************************************************
 *				LogTcpStats
 ***********************************************************************
 * SYNOPSIS:	Write Tcp stats to log file.
 * CALLED BY:	LogWriteStats
 * RETURN:	nothing
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/
void
LogTcpStats(FileHandle log)
{
    word cnt, i;
    TCHAR logBuf[MAX_LOG_STRING];

#ifdef __BORLANDC__
    word stats[NUM_TCP_STATS];
#endif
#ifdef __HIGHC__    
    word stats[NUM_TCP_STATS] = {
    	tcpstat.tcps_connattempt,
    	tcpstat.tcps_accepts,
	tcpstat.tcps_connects,
	tcpstat.tcps_drops,
	tcpstat.tcps_conndrops,	    	
	tcpstat.tcps_closed,
 	tcpstat.tcps_segstimed,
	tcpstat.tcps_rttupdated,	
	tcpstat.tcps_delack,		
	tcpstat.tcps_timeoutdrop,	
	tcpstat.tcps_rexmttimeo,	
	tcpstat.tcps_persisttimeo,	
	tcpstat.tcps_keeptimeo,		
	tcpstat.tcps_keepprobe,		
	tcpstat.tcps_keepdrops,		

	tcpstat.tcps_sndtotal,		
	tcpstat.tcps_sndpack,		
	tcpstat.tcps_sndbyte,		
	tcpstat.tcps_sndrexmitpack,	
	tcpstat.tcps_sndrexmitbyte,	
	tcpstat.tcps_sndacks,		
	tcpstat.tcps_sndurg,		
	tcpstat.tcps_sndprobe,		
	tcpstat.tcps_sndwinup,		
	tcpstat.tcps_sndctrl,		

	tcpstat.tcps_rcvtotal,		
	tcpstat.tcps_rcvpack,		
	tcpstat.tcps_rcvbyte,		
	tcpstat.tcps_rcvbadsum,		
	tcpstat.tcps_rcvbadoff,		
	tcpstat.tcps_rcvshort,		
	tcpstat.tcps_rcvduppack,	
	tcpstat.tcps_rcvdupbyte,	
	tcpstat.tcps_rcvpartduppack,	
	tcpstat.tcps_rcvpartdupbyte,	
	tcpstat.tcps_rcvoopack,		
	tcpstat.tcps_rcvoobyte,		
	tcpstat.tcps_rcvpackafterwin,	
	tcpstat.tcps_rcvbyteafterwin,	
	tcpstat.tcps_rcvafterclose,	
	tcpstat.tcps_rcvdupack,		
	tcpstat.tcps_rcvacktoomuch,	
	tcpstat.tcps_rcvackpack,	
	tcpstat.tcps_rcvackbyte,	
	tcpstat.tcps_rcvwinprobe,	
	tcpstat.tcps_rcvwinupd
    };
#endif

    char *statMsg[] = {
 	"Connections initiated: ",
 	"Connections accepted: ",
    	"Connections established: ",
	"Connections dropped: ",
	"Incoming connections dropped: ",
	"Connections closed: ",
	"Segments timed: ",
	"Round trip time updates: ",
	"Delayed acks sent: ",
    	"Connections dropped by rexmt timeout: ",
 	"Retransmit timeouts: ",
   	"Persist timeouts: ",
	"Keepalive timeouts: ",
	"Keepalive probes sent: ",
	"Connections dropped by keepalive timeout: ",
	
	"Total packets sent: ",
	"Data packet sent: ",
	"Data bytes sent: ",
	"Data packets retransmitted: ",
	"Data bytes retransmitted: ",
	"Ack only packets sent: ",
	"Packets sent with URG only: ",
	"Window probes sent: ",
	"Window update-only packets sent: ",
	"Control packets sent: ",

	"Total packets received: ",
	"Packets received in sequence: ",
	"Bytes received in sequence: ",
	"Bad checksums: ",
	"Bad offsets: ",
	"Packets that were too short: ",
	"Duplicate-only packets received: ",
	"Duplicate-only bytes received: ",
	"Packets with some duplicate data: ",
	"Duplicate bytes in partly dup. packets: ",
   	"Out of order packets received: ",
	"Out of order bytes received: ",
	"Packets with data after window: ",
	"Bytes received after window: ",
	"Packets received after connection closed: ",
	"Duplicate acks received: ",
	"Acks for unsent data received: ",
	"Ack packets received: ",
	"Bytes acked by received acks: ",
	"Window probes received: ",
	"Window updates received: "
   };

#ifdef __BORLANDC__
	stats[0] = tcpstat.tcps_connattempt;
    	stats[1] = tcpstat.tcps_accepts;
	stats[2] = tcpstat.tcps_connects;
	stats[3] = tcpstat.tcps_drops;
	stats[4] = tcpstat.tcps_conndrops;
	stats[5] = tcpstat.tcps_closed;
 	stats[6] = tcpstat.tcps_segstimed;
	stats[7] = tcpstat.tcps_rttupdated;
	stats[8] = tcpstat.tcps_delack;
	stats[9] = tcpstat.tcps_timeoutdrop;
	stats[10] = tcpstat.tcps_rexmttimeo;
	stats[11] = tcpstat.tcps_persisttimeo;
	stats[12] = tcpstat.tcps_keeptimeo;
	stats[13] = tcpstat.tcps_keepprobe;
	stats[14] = tcpstat.tcps_keepdrops;

	stats[15] = tcpstat.tcps_sndtotal;
	stats[16] = tcpstat.tcps_sndpack;
	stats[17] = tcpstat.tcps_sndbyte;
	stats[18] = tcpstat.tcps_sndrexmitpack;
	stats[19] = tcpstat.tcps_sndrexmitbyte;
	stats[20] = tcpstat.tcps_sndacks;
	stats[21] = tcpstat.tcps_sndurg;
	stats[22] = tcpstat.tcps_sndprobe;
	stats[23] = tcpstat.tcps_sndwinup;
	stats[24] = tcpstat.tcps_sndctrl;

	stats[25] = tcpstat.tcps_rcvtotal;
	stats[26] = tcpstat.tcps_rcvpack;
	stats[27] = tcpstat.tcps_rcvbyte;
	stats[28] = tcpstat.tcps_rcvbadsum;
	stats[29] = tcpstat.tcps_rcvbadoff;
	stats[30] = tcpstat.tcps_rcvshort;
	stats[31] = tcpstat.tcps_rcvduppack;
	stats[32] = tcpstat.tcps_rcvdupbyte;
	stats[33] = tcpstat.tcps_rcvpartduppack;
	stats[34] = tcpstat.tcps_rcvpartdupbyte;
	stats[35] = tcpstat.tcps_rcvoopack;
	stats[36] = tcpstat.tcps_rcvoobyte;
	stats[37] = tcpstat.tcps_rcvpackafterwin;
	stats[38] = tcpstat.tcps_rcvbyteafterwin;
	stats[39] = tcpstat.tcps_rcvafterclose;
	stats[40] = tcpstat.tcps_rcvdupack;
	stats[41] = tcpstat.tcps_rcvacktoomuch;
	stats[42] = tcpstat.tcps_rcvackpack;
	stats[43] = tcpstat.tcps_rcvackbyte;
	stats[44] = tcpstat.tcps_rcvwinprobe;
	stats[45] = tcpstat.tcps_rcvwinupd;
#endif

    /*
     * Only print TCP stats if TCP was used.
     */
    if (tcpstat.tcps_sndtotal + tcpstat.tcps_rcvtotal > 0) {
	cnt = sprintf(logBuf, "  TCP Statistics:\n");
	FileWrite (log, logBuf, cnt, FALSE);
	
    	for (i = 0; i < NUM_TCP_STATS; i++) {
	    if (stats[i] > 0) {
		cnt = sprintf(logBuf, "\t%-45s%u\n", statMsg[i], stats[i]);
		FileWrite  (log, logBuf, cnt, FALSE);	    
	    }
	}
    
    }
}


/***********************************************************************
 *				LogUdpStats
 ***********************************************************************
 * SYNOPSIS:	Write Udp statistics to log file.
 * CALLED BY:	LogWriteStats
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/
void
LogUdpStats(FileHandle log)
{
   word cnt, i;
   TCHAR logBuf[MAX_LOG_STRING];

#ifdef __BORLANDC__
   word stats[NUM_UDP_STATS];
#endif
#ifdef __HIGHC__
   word stats[NUM_UDP_STATS] = {
   	udpstat.udps_ipackets,
	udpstat.udps_opackets,
	udpstat.udps_hdrops,
	udpstat.udps_badsum,
	udpstat.udps_badlen,
	udpstat.udps_noport,
	udpstat.udps_noportbcast
   };
#endif
   
   char *statMsg[] = {
   	"Total input packets: ",
	"Total output packets: ",
	"Buffer shorter than minimum UDP header: ",
	"Bad checksums: ",
	"Data length exceeds buffer size: ",
	"Undeliverable packets: ",
	"Undeliverable broadcasts: "
   };

#ifdef __BORLANDC__
   	stats[0] = udpstat.udps_ipackets;
	stats[1] = udpstat.udps_opackets;
	stats[2] = udpstat.udps_hdrops;
	stats[3] = udpstat.udps_badsum;
	stats[4] = udpstat.udps_badlen;
	stats[5] = udpstat.udps_noport;
	stats[6] = udpstat.udps_noportbcast;
#endif

   /*
     * Only print UDP stats if UDP was used.
     */
    if (udpstat.udps_ipackets + udpstat.udps_opackets > 0) {
	cnt = sprintf(logBuf, "  UDP Statistics:\n");
	FileWrite (log, logBuf, cnt, FALSE);
	
    	for (i = 0; i < NUM_UDP_STATS; i++) {
	    if (stats[i] > 0) {
		cnt = sprintf(logBuf, "\t%-45s%u\n", statMsg[i], stats[i]);
		FileWrite  (log, logBuf, cnt, FALSE);	    
	    }
	}
    
    }
}


/***********************************************************************
 *				LogIcmpStats
 ***********************************************************************
 * SYNOPSIS:	Write ICMP statistics to log file.
 * CALLED BY:	LogWriteStats
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/
void
LogIcmpStats(FileHandle log)
{
   word cnt, i;
   TCHAR logBuf[MAX_LOG_STRING];

#ifdef __BORLANDC__
   word stats[NUM_ICMP_STATS];
#endif
#ifdef __HIGHC__
   word stats[NUM_ICMP_STATS] = {
       icmpstat.icps_error,
       icmpstat.icps_oldicmp,
       icmpstat.icps_badcode,
       icmpstat.icps_tooshort,
       icmpstat.icps_badsum,
       icmpstat.icps_badlen,
       icmpstat.icps_reflect
   };
#endif
   
   char *statMsg[] = {
       "Calls to IcmpError: ",
       "Errors not sent for icmp messages: ",
       "Bad Icmp code: ",
       "Buffer size less than minimum ICMP length: ",
       "Bad checksum: ",
       "ICMP message with bad lengths: ",
       "Responses: "
   };

#ifdef __BORLANDC__
       stats[0] = icmpstat.icps_error;
       stats[1] = icmpstat.icps_oldicmp;
       stats[2] = icmpstat.icps_badcode;
       stats[3] = icmpstat.icps_tooshort;
       stats[4] = icmpstat.icps_badsum;
       stats[5] = icmpstat.icps_badlen;
       stats[6] = icmpstat.icps_reflect;
#endif

   /*
    * Only print ICMP stats if ICMP was used.
    */
    if (icmpstat.icps_packets > 0) {
	cnt = sprintf(logBuf, "  ICMP Statistics:\n");
	FileWrite (log, logBuf, cnt, FALSE);
	
    	for (i = 0; i < NUM_ICMP_STATS; i++) {
	    if (stats[i] > 0) {
		cnt = sprintf(logBuf, "\t%-45s%u\n", statMsg[i], stats[i]);
		FileWrite  (log, logBuf, cnt, FALSE);	    
	    }
	}
    
    	for (i = 0; i < ICMP_MAXTYPE + 1; i++) {
	    if (icmpstat.icps_outhist[i] > 0) {
		cnt = sprintf(logBuf, "\t%s%u%s%u\n", 
			      "Icmp messages of type ", i, " sent: \t\t",
			      icmpstat.icps_outhist[i]);
		FileWrite  (log, logBuf, cnt, FALSE);	    
	    }
	}
	
	for (i = 0; i < ICMP_MAXTYPE + 1; i++) {
	    if (icmpstat.icps_inhist[i] > 0) {
		cnt = sprintf(logBuf, "\t%s%u%s%u\n", 
			      "Icmp messages of type ", i, " received: \t",
			      icmpstat.icps_inhist[i]);
		FileWrite  (log, logBuf, cnt, FALSE);	    
	    }
	}		
    }
}


/***********************************************************************
 *				LogWriteStats
 ***********************************************************************
 * SYNOPSIS:	Write the statistics out to the log file.
 * CALLED BY:	LogCloseFile
 * RETURN:	nothing
 *
 * STRATEGY:
 *	    	Only non-zero stat counters are logged.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/
void CALLCONV
LogWriteStats()
{
    FileHandle log;
 
    GeodeLoadDGroup(GeodeGetCodeProcessHandle());	/* Set up dgroup */
    
     if ((log = LogGetLogFile()) != 0) {
	LogIpStats(log);
	LogTcpStats(log);   	
	LogUdpStats(log);   	
	LogIcmpStats(log);  	
	FileCommit(log, FALSE);
    }		
}

#endif  /* LOG_STATS */

#ifdef LOG_EVENTS


/***********************************************************************
 *				LogWriteMessage
 ***********************************************************************
 * SYNOPSIS:	Write a fixed message to the log file.
 * CALLED BY:	GLOBAL
 * PASS:    	msgCode	= LogMessage
 * RETURN:	nothing
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/

void
LogWriteMessage (LogMessage msgCode)
{
    word cnt;
    TCHAR logBuf[MAX_LOG_STRING];
    FileHandle log;
    
    char *logMsgs[] = {
	    	    	/* these messages indicate a problem with input */
    	"Dropping received packet.",
	"Packet is shorter than minimum IP header.",
	
	"IP datagram bigger than mtu but can't fragment.",
	"Bad IP version number.",
 	"IP header length is too short.",
	"IP header length exceeds buffer size.",
	"IP datagram has bad source address.",
	"IP datagram has bad checksum.",
	"IP total length is shorter than minimum IP header.",
	"IP total length exceeds buffer size.",
	"IP datagram has bad destination address.",
	"Unknown or unsupported IP protocol.",
	"IP dropping datagram.",
	    
	"Tcp segment has bad checksum.",
	"Tcp header has bad offset.",
	"Tcp segment is shorter than minimum Tcp header length.",
	"Tcp connect request rejected.",
	"Tcp segment received after connection closed.",
	"Tcp segment has bad ack value.",
	"Tcp segment is missing SYN.",
	"SYN received in window.",
	"Tcp segment missing ACK.",
	"Received Tcp segment which has no connection.",

	"Udp dropping datagram.",
	"Udp header length too short.",
	"Udp header length exceeds Ip length.",
	"Udp datagram has bad checksum.",
	"Udp received an undeliverable datagram.",

	"Icmp datagram has bad checksum.",
	"Icmp datagram has bad Icmp code.",

		    /* these messages indicate events in Ip layer */
	"IP received a fragment of a new datagram.",
	"IP received another fragment of same datagram.",
	"IP dropping overlapping bytes in fragment.",
	"IP dropping completely overlapped fragment.",
	"IP datagram reassembled.",
	"IP discarding fragment from fragment queue.",
	"Reassembly timer expired on IP fragment queue.",
	"Ip fragmented datagram.",

	    	    /* these messages report events in Tcp layer */
	"Using Tcp reassembly queue.",
	"Dropping overlapping bytes in Tcp reassembly queue.",
#ifdef MERGE_TCP_SEGMENTS
	"Merging Tcp segments in reassebly queue.",
#endif
	"Inserting Tcp segment in reassembly queue.",
	"Delivering segments from Tcp reassembly queue.",
	"Dropping completely overlapped segment from Tcp reassembly queue.",
	"Tcp reassembly queue not empty upon destruction.",
	"Dropping Tcp connection",
	"Retransmit timeout and max retransmits sent.",
	"Keepalive timeout expired."
	    
    };

    if ((log = LogGetLogFile()) != 0) {
	cnt = sprintf(logBuf, "%s\n\n", logMsgs[msgCode]);
	FileWrite(log, logBuf, cnt, FALSE);
	FileCommit(log, FALSE);
    }

}


/***********************************************************************
 *				LogTcpStateChange
 ***********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	11/22/94		Initial Revision
 *
 ***********************************************************************/
void
LogTcpStateChange(word oldState, word newState)
{
    FileHandle log;
    word cnt;
    TCHAR logBuf[MAX_LOG_STRING];

    char *states[] = {
	"CLOSED",
	"LISTEN",
	"SYN SENT",
	"SYN RECEIVED",
	"ESTABLISHED",
	"CLOSE WAIT",
	"FIN WAIT 1",
	"CLOSING",
	"LAST ACK",
	"FIN WAIT 2",
	"2 MSL TIME WAIT"
    };

    if ((log = LogGetLogFile()) != 0) {
	cnt = sprintf(logBuf, "Tcp state change: %s to %s.\n\n", 
		      states[oldState], states[newState]);
	FileWrite(log, logBuf, cnt, FALSE);
    	FileCommit(log, FALSE);
    }

}

#endif /* LOG_EVENTS */

#endif /* WRITE_LOG_FILE */

