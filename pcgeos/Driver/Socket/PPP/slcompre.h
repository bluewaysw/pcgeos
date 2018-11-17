/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  slcompress.h
 *
 * AUTHOR:  	  Jennifer Wu: May 12, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/12/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Definition for tcp compression routines.
 *
 *
 * 	$Id: slcompress.h,v 1.1 95/07/11 15:33:15 jwu Exp $
 *
 ***********************************************************************/
/*
 *
 * Copyright (c) 1989 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 *
 *	Van Jacobson (van@helios.ee.lbl.gov), Dec 31, 1989:
 *	- Initial distribution.
 */

#ifndef _SLCOMPRESS_H_
#define _SLCOMPRESS_H_

# define MAX_STATES 	32 	    /* must be > 2 and < 256 */
# define MAX_HDR    	128

/*
 * Compressed packet format:
 *
 * The first octet contains the packet type (top 3 bits), TCP
 * 'push' bit, and flags that indicate which of the 4 TCP sequence
 * numbers have changed (bottom 5 bits).  The next octet is a 
 * conversation number that associates a saved IP/TCP header with
 * the compressed packet.  The next two octets are the TCP checksum
 * from the original datagram.  The next 0 to 15 octets are 
 * sequence number changes, one change per bit set in the header 
 * (there may be no changes and there are two special cases where
 * the receiver implicitly knows what changed -- see below).
 *
 * There are 5 numbers which can change (they are always inserted
 * in the following order): TCP urgent pointer, window, 
 * acknowledgement, sequence number and IP ID.  (The urgent pointer
 * is different from the others in that its value is sent, not the
 * change in value.)  Since typical use is biased toward small packets 
 * (see comments on MTU/MSS below), changes use a variable length coding
 * with one octet for numbers in the range 1 - 255 and 3 octets (0, MSG, LSB) 
 * for numbers in the range 256 - 65535 or 0.  (If the change in sequence
 * number or ack is more than 65535, an uncompressed packet is sent.)
 */

/*
 * Packet types (must not conflict with IP protocol version)
 *
 * The top nibble of the first octet is the packet type.  There are
 * three possible types: IP (not proto TCP or tcp with one of the 
 * control flags set); uncompressed TCP (a normal IP/TCP packet but
 * with the 8-bit protocol field replaced by an 8-bit connection id --
 * this type of packet syncs the sender & receiver); and compressed
 * TCP (described above).
 *
 * LSB of 4-bit field is TCP "PUSH" bit (a worthless anachronism) and
 * is logically part of the 4-bit "changes" field that follows.  Top
 * three bits are actual packet type.  For backward compatibility
 * and in the interest of conserving bits, numbers are chosen so the
 * IP protocol version (4) which normally appears in this nibble
 * means "IP packet".
 */

/* 
 * 	Packet types 
 */
#define TYPE_IP     	    	0x40
#define TYPE_UNCOMPRESSED_TCP 	0x70
#define TYPE_COMPRESSED_TCP 	0x80
#define TYPE_ERROR  	    	0x00


/*
 * 	Bits in first octet of compressed packet
 */
#define NEW_C	0x40	/* flag bits for what changed in a packet */
#define NEW_I	0x20
#define NEW_S	0x08
#define NEW_A	0x04
#define NEW_W	0x02
#define NEW_U	0x01

/* reserved, special-case values of above */
#define SPECIAL_I (NEW_S|NEW_W|NEW_U)	    /* echoed interactive traffic */
#define SPECIAL_D (NEW_S|NEW_A|NEW_W|NEW_U) /* unidirectional data */
#define SPECIALS_MASK (NEW_S|NEW_A|NEW_W|NEW_U)

#define TCP_PUSH_BIT 0x10

/*
 * "state" data for each active tcp conversation on the wire.  This is
 * basically a copy of the entire IP/TCP header from the last packet
 * we saw from the conversation together with a small identifier
 * the transmit & receive ends of the line use to locate saved header.
 *
 * The union makes sure there is room for the maximum TCP/IP header
 * while the iphdr struct makes it easier to access the data as an 
 * IP header.
 *
 * Receive state does not need the connection ID because the slots
 * are in an array.  The array index will identify the ID.  The transmit
 * end needs it because the slots are dynamically allocated and are 
 * ordered in a circularly linked list.
 *
 * The "next pointers" contain offsets to the slot from the start of 
 * the memory block. The block may move when resized so we cannot 
 * store the fptr to the slot.
 */
struct cstate_t
{
    unsigned short cst_next;   /* offset to next most recently used cstate */
    unsigned char cst_id;      /* connection # associated with this state */
    union {
	char csu_hdr[MAX_HDR]; 
	struct iphdr csu_ip;   /* ip/tcp hdr from most recent packet */
    } slcst_u;
    byte cst_align;  	       /* to keep structure word aligned */
};

#define cst_ip slcst_u.csu_ip
#define cst_hdr slcst_u.csu_hdr

struct cstate_r
{
    unsigned short csr_hlen;   /* size of hdr */
    union {
	char csu_hdr[MAX_HDR];
	struct iphdr csu_ip;   /* ip/tcp hdr from most recent packet */
    } slcsr_u;
};

#define csr_ip slcsr_u.csu_ip
#define csr_hdr slcsr_u.csu_hdr

/* 
 * All the state data for one serial line.  (We need one of these
 * per line.)  
 *
 * Offsets to the transmit slots from the start of the memory block are 
 * stored, because the block may move when resized to allocate new slots.
 *
 * Receive side state slots are allocated when compression is 
 * initialized.  
 *
 * The memory block holding compression data will have slcompress 
 * struct as the header, followed by the negotiated number of receive
 * slots.  Transmit slots will be allocated after the receive slots
 * in the block.  Receive slots can be references by array index, but
 * transmit slots have to be referenced by constructing a fptr to the
 * slot using the offset and the known segment of the block.
 *
 * Transmit state slots will be allocated as needed until the maximum
 * number of slots has been allocated.  If further slots are needed,
 * the least recently used slot will be reused.
 */
struct slcompress {
    unsigned short sl_size;    	/* size of data block */
    unsigned short last_cs; 	/* offset to most recently used tstate */
    unsigned char last_recv;	/* last rcvd conn. id */
    unsigned char last_xmit;	/* last sent conn. id */
    unsigned char rx_slots; 	/* number of receive slots */
    unsigned char max_tx_slots;	/* max transmit slots possible */
    unsigned char tx_slots;	/* current number of transmit slots */
    unsigned char flags;    	
};

/* flag values */
# define SLF_TOSS    1	    /* tossing rcvd frames because of input err */
# define SLF_CID     1	    /* compressing conn. id's */

extern Handle sc_comp;

extern void sl_compress_init (int rx_slots, int tx_slots, unsigned char cid);
extern int sl_compress_tcp ();
extern int sl_uncompress_tcp ();


#endif /* _SLCOMPRESS_H_ */
