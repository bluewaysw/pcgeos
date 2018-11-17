/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  slcompress.c
 *
 * AUTHOR:  	  Jennifer Wu: May 12, 1995
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	sl_compress_init
 *	sl_compress_tcp
 *	sl_uncompress_tcp
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/12/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Van Jacobson TCP header compression.
 *	Routines to compress and uncomopress TCP packets (for 
 *	transmission over low speed serial lines).  The code is
 *	basically taken straight from the RFC for compressing TCP/IP
 *      headers.
 *
 * 	$Id: slcompress.c,v 1.7 97/04/10 18:37:49 jwu Exp $
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

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <ppp.h>

/* 
 * Handle of memory block holding compression data.  
 * Block must be locked before use.  10/25/95 - jwu
 */
Handle sc_comp = 0;


/***********************************************************************
 *				sl_compress_init
 ***********************************************************************
 * SYNOPSIS:	Initialize compression.
 * CALLED BY:	SetVJCompression
 * RETURN:  	nothing	
 * 
 * STRATEGY:	If data block exists, free it.
 *	    	If rx_slots and tx_slots are both zero, then return.
 *	    	Else
 *	    	  allocate data block with enough room for rx_slots
 *	    	    for the receiving state
 *	    	  if no memory, log reason and call lcp_close.
 *	    	    (if we're this low on memory, can't have a decent
 *	    	     connection, anyways.)
 *	    	  else store block handle and initialize slcompress 
 *	    	    header in block
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
void sl_compress_init (int rx_slots, 
		       int tx_slots, 
		       unsigned char cid)
{
    struct slcompress *comp;
    unsigned short compSize;

     /*
      * Free old data block, if any.
      */
    PPPFreeBlock(sc_comp);
    sc_comp = 0;

     /*
      * Only initialize if compression is being used.  Allocate the
      * memory block for storing all the compression state data.
      * Called from driver's thread so we will own the data block.
      */
    if (rx_slots || tx_slots) {

	compSize = rx_slots * sizeof(struct cstate_r) + 
	    	    sizeof(struct slcompress);
	sc_comp = MemAlloc(compSize, HF_DYNAMIC, HAF_ZERO_INIT | HAF_LOCK);

	if (sc_comp) {
	     /*
	      * Initialize compression header information.  Block zeroed
	      * during allocation so only need to set non-zero fields.
	      * Set last_cs to point to what will be the first transmit
	      * slot when it is allocated.
	      */
	    comp = (struct slcompress *)MemDeref(sc_comp);
	    comp -> sl_size = comp -> last_cs = compSize;
	    comp -> rx_slots = rx_slots;
	    comp -> max_tx_slots = tx_slots;
	    comp -> flags = SLF_TOSS | (cid ? SLF_CID : 0);
	    MemUnlock(sc_comp);
	}
	else {
	    link_error = SDE_INSUFFICIENT_MEMORY;
	    LOG3(LOG_IF, (LOG_NO_MEM_COMP));
	    DOLOG(shutdown_reason = "VJCOMP: Insufficient memory";)
	    lcp_close(0);
	}
    }
}


/* ENCODE encodes a number that is known to be non-zero.  ENCODEZ
 * checks for zero (since zero has to be encoded in the long, 3 byte
 * form).
 */
#define ENCODE(n) { \
	if ((unsigned short)(n) >= 256) { \
		*cp++ = 0; \
		cp[1] = (n); \
		cp[0] = (n) >> 8; \
		cp += 2; \
	} else { \
		*cp++ = (n); \
	} \
}

#define ENCODEZ(n) { \
	if ((unsigned short)(n) >= 256 || (unsigned short)(n) == 0) { \
		*cp++ = 0; \
		cp[1] = (n); \
		cp[0] = (n) >> 8; \
		cp += 2; \
	} else { \
		*cp++ = (n); \
	} \
}

/*
 * Decode a long value.
 */
#define DECODEL(f) { \
	if (*cp == 0) {\
		(f) = htonl(ntohl(f) + ((cp[1] << 8) | cp[2])); \
		cp += 3; \
	} else { \
		(f) = htonl(ntohl(f) + (unsigned long)*cp++); \
	} \
}

#define DECODES(f) { \
	if (*cp == 0) {\
		(f) = htons(ntohs(f) + ((cp[1] << 8) | cp[2])); \
		cp += 3; \
	} else { \
		(f) = htons(ntohs(f) + (unsigned long)*cp++); \
	} \
}


#define DECODEU(f) { \
	if (*cp == 0) {\
		(f) = htons((cp[1] << 8) | cp[2]); \
		cp += 3; \
	} else { \
		(f) = htons((unsigned long)*cp++); \
	} \
}




/***********************************************************************
 *				sl_compress_tcp
 ***********************************************************************
 * SYNOPSIS:	    Compress a TCP header.
 * CALLED BY:	    ppp_ip_output
 * RETURN:	    packet type
 *
 * STRATEGY:	    If  packet is not compressible, return TYPE_IP.
 *	    	    If no transmit slots exist, 
 *	    	    	create one, returning TYPE_IP if no memory
 *	    	    else search for it, starting at first transmit slot
 *	    	    	(last points to first)
 *	    	    	if not found
 *	    	    	    if not at max slots, alloc one and insert in
 *	    	    	    	front of list
 *	    	    	    do uncompressed_tcp if successful else
 *	    	    	    reuse oldest slot and do uncompressed_tcp
 *	    	    	else move slot to front of list
 *	    	    	    compress header
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
int sl_compress_tcp (PACKET *p, struct iphdr *iph)
     /*PACKET *p;*/  	    	    /* old-style function declaration needed here */
     /*struct iphdr *iph;*/
{
    unsigned int hlen = iph -> ip_hl;
    struct tcphdr *oth;
    struct tcphdr *th;
    unsigned long deltaS, deltaA;
    unsigned int changes = 0;
    unsigned char new_seq[16];
    unsigned char *cp = new_seq;
    struct slcompress *comp;
    struct cstate_t *c, *lastcs;
    int result = TYPE_IP;

    /*
     * Bail if this is an IP fragment or if the TCP packet isn't
     * `compressible' (i.e. ACK isn't set or some other control bit
     * is set).  (We assume the caller has already made sure the 
     * packet is IP proto TCP).
     */
    if ((iph -> ip_off & htons(0x3ffff)) || p -> MH_dataSize < 40)
	return (TYPE_IP);

    th = (struct tcphdr *)&((dword *)iph)[hlen];
    if ((th -> th_flags & (TH_SYN|TH_FIN|TH_RST|TH_ACK)) != TH_ACK)
	return (TYPE_IP);

    /*
     * Packet is compressible -- we're going to send either a 
     * COMPRESSED_TCP or UNCOMPRESSED_TCP packet.  Either way we need
     * to locate (or create) the connection state.  Special case the
     * most recently used connection since it's most likely to be used
     * again & we don't have to do any reordering if it's used.
     */
    MemLock(sc_comp);
    comp = (struct slcompress *)MemDeref(sc_comp);
    if (comp -> tx_slots == 0) {
	unsigned short newSize = comp -> sl_size + sizeof(struct cstate_t);

	if (MemReAlloc(sc_comp, newSize, HAF_ZERO_INIT)) {
	    comp = (struct slcompress *)MemDeref(sc_comp);
	    c = (struct cstate_t *)((byte *)comp + comp -> sl_size); 
	    c -> cst_next = comp -> last_cs;
	    c -> cst_id = comp -> tx_slots++;	    
	    comp -> sl_size = newSize;	    	    
	    goto hlenThenUncomp;
	}
	else 
	    goto unlockAndReturn;  	/* no memory for any slots :( */
    }
    
     /*
      * Find the connection slot by searching through the circular list,
      * starting with the first slot (pointed to by the last slot).
      * The third line of the "if" statement checks both ports at once.
      */
    lastcs = (struct cstate_t *)((byte *)comp + comp -> last_cs);
    c = (struct cstate_t *)((byte *)comp + lastcs -> cst_next);  

    if (iph -> ip_src != c -> cst_ip.ip_src ||
	iph -> ip_dst != c -> cst_ip.ip_dst ||
	*(dword *)th != ((dword *)&c -> cst_ip)[c -> cst_ip.ip_hl]) {
	    /*
	     * Wasn't the first -- search for it.
	     *
	     * States are kept in a circularly linked list with
	     * last_cs pointing to the end of the list.  The
	     * list is kept in lru order by moving a state to the
	     * head of the list whenever it is referenced.  Since
	     * the list is short and, empirically, the connection
	     * we want is almost always near the front, we locate
	     * states via linear search.  If we don't find a state
	     * for the datagram, the oldest state is (re-)used.
	     */
	struct cstate_t *lcs;

	do {
	    lcs = c; 
	    c = (struct cstate_t *)((byte *)comp + c -> cst_next);
	    
	    if (iph -> ip_src == c -> cst_ip.ip_src &&
		iph -> ip_dst == c -> cst_ip.ip_dst &&
		*(dword *)th == ((dword *)&c -> cst_ip)[c -> cst_ip.ip_hl]) 
		goto found;
	} while (c != lastcs);

	/*
	 * Didn't find it -- re-use oldest cstate, unless we
	 * are able to allocate a new transmit slot.  Send an
	 * uncompressed packet that tells the other side what
	 * connection number we're using for this conversation.
	 * Note that since the state list is circular, the oldest
	 * state points to the newest and we only need to set
	 * last_cs to update the lru linkage.
	 */	     
	if (comp -> tx_slots < comp -> max_tx_slots) {
	    unsigned short newSize = comp -> sl_size + sizeof(struct cstate_t);

	    if (MemReAlloc(sc_comp, newSize, HAF_ZERO_INIT)) {
		comp = (struct slcompress *)MemDeref(sc_comp);
		lastcs = (struct cstate_t *)((byte *)comp + comp -> last_cs);
		c = (struct cstate_t *)((byte *)comp + comp -> sl_size);
		c -> cst_next = lastcs -> cst_next;   	/* points to first */
		lastcs -> cst_next = comp -> sl_size;	/* points to new */
		c -> cst_id = comp -> tx_slots++;
		comp -> sl_size = newSize;
		goto hlenThenUncomp;
	    }
	    /* else fall through to reuse oldest slot */
	}

	 /*
	  * Re-use oldest cstate. (transmit slot)
	  */
	comp -> last_cs = (byte *)lcs - (byte *)comp; 	/* offset in bytes */
hlenThenUncomp:
	/*
	 * Adjust hlen to include TCP header and convert to bytes.
	 */
	hlen += th -> th_off;
	hlen <<= 2;
	if (hlen > p -> MH_dataSize) 
	    goto unlockAndReturn;
	else 
	    goto uncompressed;
found:
	/*
	 * Found it -- move to the front on the connection list.
	 */
	if (c == lastcs)
	    comp -> last_cs = (byte *)lcs - (byte *)comp;
	else {
	    lcs -> cst_next = c -> cst_next;
	    c -> cst_next = lastcs -> cst_next;
	    lastcs -> cst_next = (byte *)c - (byte *)comp;
	}
    }

    /*
     * Make sure that only what we expect to change changed. The first
     * line of the `if' checks the IP protocol version, header length &
     * type of service.  The 2nd line checks the "Don't fragment" bit.
     * The 3rd line checks the time-to-live and protocol (the protocol
     * check is unnecessary but costless).  The 4th line checks the TCP
     * header length.  The 5th line checks IP options, if any.  The 6th
     * line checks TCP options, if any.  If any of these things are
     * different between the previous & current datagram, we send the
     * current datagram `uncompressed'.
     */
    oth = (struct tcphdr *)&((dword *)&c -> cst_ip)[hlen];
    deltaS = hlen;
    hlen += th -> th_off;
    hlen <<= 2;
    if (hlen > p -> MH_dataSize) 
	goto unlockAndReturn;

    if (((unsigned short *)iph)[0] != ((unsigned short *)&c -> cst_ip)[0] ||
	((unsigned short *)iph)[3] != ((unsigned short *)&c -> cst_ip)[3] ||
	((unsigned short *)iph)[4] != ((unsigned short *)&c -> cst_ip)[4] ||
	th -> th_off != oth -> th_off ||
	(deltaS > 5 &&
	 memcmp(iph + 1, &c -> cst_ip + 1, (deltaS - 5) << 2)) ||
	(th -> th_off > 5 &&
	 memcmp(th + 1, oth + 1, (th -> th_off - 5) << 2)))
	goto uncompressed;

    /*
     * Figure out which of the changing fields changed.  The
     * receiver expects changes in the order: urgent, window,
     * ack, seq (the order minimizes the number of temporaries
     * needed in this section of code).
     */
    if (th -> th_flags & TH_URG) {
	deltaS = ntohs(th -> th_urp);
	ENCODEZ(deltaS);
	changes |= NEW_U;
    } else if (th -> th_urp != oth -> th_urp)
	/* argh! URG not set but urp changed -- a sensible 
	 * implementation should never do this but RFC793
	 * doesn't prohibit the change so we have to deal 
	 * with it. */
	goto uncompressed;

    if ((deltaS = (unsigned short)(ntohs(th -> th_win) - 
				  ntohs(oth -> th_win))) != 0) {
    	ENCODE(deltaS);
	changes |= NEW_W;
    }

    if ((deltaA = ntohl(th -> th_ack) - ntohl(oth -> th_ack)) != 0) {
	if (deltaA > 0x0000ffff)
	    goto uncompressed;
	ENCODE(deltaA);
	changes |= NEW_A;
    }

    if ((deltaS = ntohl(th -> th_seq) - ntohl(oth -> th_seq)) != 0) {
	if (deltaS > 0x0000ffff)
	    goto uncompressed;
	ENCODE(deltaS);
	changes |= NEW_S;
    }

    switch (changes) 
	{
	case 0:
		/*
		 * Nothing changed. If this packet contains data and the
		 * last one didn't, this is probably a data packet following
		 * an ack (normal on an interactive connection) and we send
		 * it compressed.  Otherwise it's probably a retransmit,
		 * retransmitted ack or window probe.  Send it uncompressed
		 * in case the other side missed the compressed version.
		 */
	    if (iph -> ip_len != c -> cst_ip.ip_len &&
		ntohs(c -> cst_ip.ip_len) == hlen)
		break;

	    /* (fall through) */

	case SPECIAL_I:
	case SPECIAL_D:
		/*
		 * actual changes match one of our special case encodings --
		 * send packet uncompressed.
		 */
	    goto uncompressed;

	case NEW_S|NEW_A:
	    if (deltaS == deltaA &&
		deltaS == ntohs(c -> cst_ip.ip_len) - hlen) {
		    /* special case for echoed terminal traffic */
		changes = SPECIAL_I;
		cp = new_seq;
	    }
	    break;

	case NEW_S:
	    if (deltaS == ntohs(c -> cst_ip.ip_len) - hlen) {
		    /* special case for data xfer */
		changes = SPECIAL_D;
		cp = new_seq;
	    }
	    break;
	}

    deltaS = ntohs(iph -> ip_id) - ntohs(c -> cst_ip.ip_id);
    if (deltaS != 1) {
	ENCODEZ(deltaS);
	changes |= NEW_I;
    }

    if (th -> th_flags & TH_PUSH)
	changes |= TCP_PUSH_BIT;

    /*
     * Grab the cksum before we overwrite it below.  Then update our
     * state with this packet's header.
     */
    deltaA = ntohs(th -> th_cksum);
    memcpy(&c -> cst_ip, iph, hlen);

    /*
     * We want to use the original packet as our compressed packet.
     * (cp - new_seq) is the number of bytes we need for compressed
     * sequence numbers.  In addition we need one byte for the change
     * mask, one for the connection id and two for the tcp checksum.
     * So, (cp - new_seq) + 4 bytes of header are needed.  hlen is how
     * many bytes of the original packet to toss so subtract the two to
     * get the new packet size.
     */
    deltaS = cp - new_seq;
    cp = (unsigned char *)iph;
    if ((comp -> flags & SLF_CID) == 0 || comp -> last_xmit != c -> cst_id) {
	comp -> last_xmit = c -> cst_id;
	hlen -= deltaS + 4;
	cp += hlen;
	*cp++ = changes | NEW_C;
	*cp++ = c -> cst_id;
    } else {
	hlen -= deltaS + 3;
	cp += hlen;
	*cp++ = changes;
    }
    p -> MH_dataSize -= hlen;
    p -> MH_dataOffset += hlen;

    *cp++ = deltaA >> 8;
    *cp++ = deltaA;
    memcpy(cp, new_seq, deltaS);
    result = TYPE_COMPRESSED_TCP;
    goto unlockAndReturn;

uncompressed:
    /*
     * Update connection state c & send uncompressed packet ('uncompressed'
     * means a regular ip/tcp packet but with the 'conversation id' we hope
     * to use on future compressed packets in the protocol field).
     */
    memcpy(&c -> cst_ip, iph, hlen);
    iph -> ip_p = c -> cst_id;
    comp -> last_xmit = c -> cst_id;
    result = TYPE_UNCOMPRESSED_TCP;

unlockAndReturn:
    MemUnlock(sc_comp);
    return(result);

}


/***********************************************************************
 *				sl_uncompress_tcp
 ***********************************************************************
 * SYNOPSIS:	Uncompress a TCP header.
 * CALLED BY:	ip_vj_comp_input
 *	    	ip_vj_uncomp_input
 * RETURN:  	length of uncompressed datagram	
 *	    	*bufp pointing to start of decompressed TCP/IP header
 *
 * STRATEGY:	Find start of receive slots in data block
 *	    	and proceed with uncompressing the TCP/IP header
 *	
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jwu	5/12/95		Initial Revision
 *
 ***********************************************************************/
int sl_uncompress_tcp (unsigned char **bufp,
		       int len,
		       unsigned int type)
{
    struct slcompress *comp;
    struct cstate_r *c;
    unsigned char *cp;
    unsigned int hlen, changes;
    struct tcphdr *th;
    struct iphdr *iph;
    int result = 0;
    
     /*
      * Find start of array of receive slots.
      */
    MemLock(sc_comp);
    comp = (struct slcompress *)MemDeref(sc_comp);
    c = (struct cstate_r *)((byte *)comp + sizeof(struct slcompress));

     /*
      * Verify connection id is within range.  Replace the connection
      * id in the IP header with the protocol.  Can stop tossing packets
      * now that we have received an explicit connection id.  Copy the
      * TCP/IP header into the receive slot.  Zero checksum field because
      * it needs to be zero when uncompressing compressed packets.
      */
    if (type == TYPE_UNCOMPRESSED_TCP) {
	iph = (struct iphdr *) *bufp;
	if ((int)iph -> ip_p >= comp -> rx_slots)
	    goto bad;

	c = &c[comp -> last_recv = iph -> ip_p];
	comp -> flags &= ~SLF_TOSS;
	iph -> ip_p = IPPROTO_TCP;
	hlen = iph -> ip_hl;
	hlen += ((struct tcphdr *)&((dword *)iph)[hlen]) -> th_off;
	hlen <<= 2;
	memcpy(&c -> csr_ip, iph, hlen);
	c -> csr_ip.ip_cksum = 0;
	c -> csr_hlen = hlen;
	result = len;
	goto unlockAndReturn;
    }

    if (type != TYPE_COMPRESSED_TCP)
	goto bad;

    /*
     * We've got a compressed packet.  Time to go to work.  
     */
    cp = *bufp;
    changes = *cp++;
    if (changes & NEW_C) {
	/*
	 * Make sure the state index is in range, then grab the state.
	 * If we have a good state index, clear the 'discard' flag.
	 */
	if ((int)*cp >= comp -> rx_slots)
	    goto bad;

	comp -> flags &= ~SLF_TOSS;
	comp -> last_recv = *cp++;
    } else {
	/*  
	 * This packet has an implicit state index.  If we've 
	 * had a line error since the last time we got an 
	 * explicit state index, we have to toss the packet.
	 */
	if (comp -> flags & SLF_TOSS) {
	    goto unlockAndReturn;
	}
    }

    c = &c[comp -> last_recv];
    hlen = c -> csr_ip.ip_hl << 2;
    th = (struct tcphdr *)&((unsigned char *)&c -> csr_ip)[hlen];
    th -> th_cksum = htons((*cp << 8) | cp[1]);
    cp += 2;
    if (changes & TCP_PUSH_BIT)
	th -> th_flags |= TH_PUSH;
    else
	th -> th_flags &= ~TH_PUSH;

    switch (changes & SPECIALS_MASK) 
	{
	case SPECIAL_I:
	    {
		unsigned int i = ntohs(c -> csr_ip.ip_len) - c -> csr_hlen;
		th -> th_ack = htonl(ntohl(th -> th_ack) + i);
		th -> th_seq = htonl(ntohl(th -> th_seq) + i);
	    }
	    break;

	case SPECIAL_D:
	    {
		th -> th_seq = htonl(ntohl(th -> th_seq) + 
				     ntohs(c -> csr_ip.ip_len) -
				     c -> csr_hlen);
	    }
	    break;

	default:
	    if (changes & NEW_U) {
		th -> th_flags |= TH_URG;
		DECODEU(th -> th_urp)
	    } else
		th -> th_flags &= ~TH_URG;
	    if (changes & NEW_W)
		DECODES(th -> th_win)
	    if (changes & NEW_A)
		DECODEL(th -> th_ack)
            if (changes & NEW_S)
		DECODEL(th -> th_seq)
	    break;
	}

    if (changes & NEW_I) 
	DECODES(c -> csr_ip.ip_id)
    else 
	c -> csr_ip.ip_id = htons(ntohs(c -> csr_ip.ip_id) + 1);

    /*
     * At this point, cp points to the first byte of data in the
     * packet.  If we're not aligned on a 4-byte boundary, copy the
     * data forward so the ip & tcp headers will be aligned.  Then back up
     * cp by the tcp/ip header length to make room for the reconstructed
     * header (we assume the packet we were handed has enough space to
     * prepend 128 bytes of header).  Adjust the length to account for
     * the new header & fill in the IP total length.
     */
    len -= (cp - *bufp);
    if (len < 0)
	/* we must have dropped some characters */
	goto bad;

    if ((unsigned long)cp & 3) {
	if (len > 0)
	    (void) memmove((char *)((unsigned long)cp & ~3), cp, len);
	cp = (unsigned char *)((unsigned long)cp & ~3);
    }
    
    cp -= c -> csr_hlen;
    len += c -> csr_hlen;
    c -> csr_ip.ip_len = htons(len);
    memcpy(cp, &c -> csr_ip, c -> csr_hlen);
    *bufp = cp;

    /* recompute the ip header checksum */
    {
	unsigned short *bp = (unsigned short *)cp;
	unsigned long chksum;
	for (chksum = 0; hlen > 0; hlen -= 2) 
	    chksum += *bp++;
	chksum = (chksum & 0x0000ffff) + (chksum >> 16);
	chksum = (chksum & 0x0000ffff) + (chksum >> 16);
	((struct iphdr *)cp) -> ip_cksum = ~chksum;
    }
    result = len;
    goto unlockAndReturn;

bad:
    comp -> flags |= SLF_TOSS;

unlockAndReturn:
    MemUnlock(sc_comp);
    return (result);
}
