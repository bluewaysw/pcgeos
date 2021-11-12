/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  tcpipLog.h
 * FILE:	  tcpipLog.h
 *
 * AUTHOR:  	  Jennifer Wu: Nov 21, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/21/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for logging.
 *
 *
 * 	$Id: tcpipLog.h,v 1.1 97/04/18 11:57:17 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _TCPIPLOG_H_
#define _TCPIPLOG_H_

#define MAX_LOG_STRING	200  	    /* should be long enough */

/*
 * Logging statistics.
 */

#ifdef LOG_STATS

/* 
 * Number of stats for each protocol that are logged only if non-zero. 
 */
#define NUM_IP_STATS	16
#define NUM_TCP_STATS	46
#define NUM_UDP_STATS	7
#define NUM_ICMP_STATS	7

#define LOG_STAT(line)    	line

#else

#define LOG_STAT(line)    

#endif

/* 
 * Logging packet headers and data.
 */

#ifdef LOG_HDRS

#define LOG_PKT(line)	    	line
extern void CALLCONV LogPacket(Boolean input, MbufHeader *m);

#else

#define LOG_PKT(line)

#endif


/*
 * Logging events.
 */
#ifdef LOG_EVENTS

typedef enum {
	    	    /* these messages indicate a problem */
    LM_TCPIP_DROPPING_RECEIVED_PACKET,
    LM_TCPIP_PACKET_TOO_SHORT,
    
    LM_IP_DATAGRAM_TOO_BIG_BUT_CANT_FRAGMENT,
    LM_IP_DATAGRAM_HAS_BAD_VERSION,
    LM_IP_HEADER_LENGTH_TOO_SHORT,
    LM_IP_HEADER_LENGTH_EXCEEDS_DATA_BUFFER_SIZE,
    LM_IP_DATAGRAM_BAD_SOURCE_ADDRESS,
    LM_IP_DATAGRAM_HAS_BAD_CHECKSUM,
    LM_IP_LENGTH_SHORTER_THAN_IP_HEADER_LENGTH,
    LM_IP_LENGTH_EXCEEDS_DATA_BUFFER_SIZE,
    LM_IP_DATAGRAM_NOT_FOR_US,
    LM_IP_UNSUPPORTED_PROTOCOL,
    LM_IP_DROPPING_DATAGRAM,
    
    LM_TCP_BAD_CHECKSUM,
    LM_TCP_BAD_OFFSET,
    LM_TCP_SEGMENT_TOO_SHORT,
    LM_TCP_SYN_REJECTED_BY_SOCKET_LIBRARY,
    LM_TCP_SEGMENT_RECEIVED_AFTER_CLOSE,
    LM_TCP_BAD_ACK_VALUE,
    LM_TCP_SEGMENT_MISSING_SYN,
    LM_TCP_SYN_RECEIVED_IN_WINDOW,
    LM_TCP_SEGMENT_MISSING_ACK,
    LM_TCP_SEGMENT_HAS_NO_CONNECTION,
    
    LM_UDP_DROPPING_DATAGRAM,
    LM_UDP_HEADER_LENGTH_TOO_SHORT,
    LM_UDP_HEADER_LENGTH_EXCEEDS_IP_LENGTH,
    LM_UDP_DATAGRAM_HAS_BAD_CHECKSUM,
    LM_UDP_RECEIVED_UNDELIVERABLE_DATAGRAM,
		    
    LM_ICMP_BAD_CHECKSUM,
    LM_ICMP_BAD_CODE,
		    /* these messages indicate events in Ip layer */
    LM_IP_RECEIVED_FIRST_FRAGMENT,
    LM_IP_RECEIVED_ANOTHER_FRAGMENT,
    LM_IP_DROPPING_OVERLAPPING_BYTES,
    LM_IP_DROPPING_COMPLETELY_OVERLAPPED_FRAGMENT,
    LM_IP_DATAGRAM_REASSEMBLED,
    LM_IP_DISCARDING_FRAGMENT_FROM_QUEUE,
    LM_IP_DISCARDING_FRAGMENT_QUEUE,
    LM_IP_FRAGMENTED_DATAGRAM,

 	    	    /*  these messages indicate events in Tcp layer */
    LM_TCP_USING_REASSEMBLY_QUEUE,
    LM_TCP_DROPPING_OVERLAPPING_BYTES,   	    	    
#ifdef MERGE_TCP_SEGMENTS
    LM_TCP_MERGING_SEGMENTS_IN_REASSEMBLY_QUEUE,
#endif
    LM_TCP_INSERTING_SEGMENT_IN_REASSEMBLY_QUEUE,
    LM_TCP_DELIVERING_SEGMENTS_FROM_REASSEMBLY_QUEUE,
    LM_TCP_DROPPING_COMPLETELY_OVERLAPPED_SEGMENT,
    LM_TCP_FREEING_ELEMENT_IN_REASSEMBLY_QUEUE,
    LM_TCP_DROPPING_CONNECTION,
    LM_TCP_REXMT_TIMEOUT,
    LM_TCP_KEEPALIVE_TIMEOUT
	
} LogMessage;

extern void LogWriteMessage(LogMessage msgCode);
extern void LogTcpStateChange(word oldState, word newState);
#define LOG_EVENT(code)     	LogWriteMessage(code)
#define LOG_STATE(newState)	LogTcpStateChange(tcb->t_state, newState)

#else

#define LOG_EVENT(code)    	
#define LOG_STATE(newState) 

#endif

#endif /* _TCPIPLOG_H_ */




