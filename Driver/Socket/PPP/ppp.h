/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  ppp.h
 *
 * AUTHOR:  	  Jennifer Wu: May  3, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 3/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	PPP global declarations.
 *
 * 	$Id: ppp.h,v 1.16 98/06/08 14:50:39 jwu Exp $
 *
 ***********************************************************************/

#ifndef _PPP_H_
#define _PPP_H_

/*
 * Old-style function declarations (used by MST) may not compile
 * correctly under BORLANDC.
 */
#ifdef __BORLANDC__
/* a few changes and it seems okay */
#endif

/*
 * DELAYED_BACKOFF_TIMER: true to use a delayed backoff timer when
 *	                  retransmitting configure-request packets
 */
#ifdef PRODUCT_RESPONDER
#define DELAYED_BACKOFF_TIMER	TRUE
#else
#define DELAYED_BACKOFF_TIMER 	FALSE
#endif


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

#include <geos.h>
#include <geode.h>
#include <resource.h>
#include <lmem.h>
#include <timer.h>
#include <timedate.h>
#include <heap.h>
#include <file.h>
#include <ec.h>
#include <char.h>
#include <Internal/socketDr.h>
#include <Ansi/string.h>
#include <Ansi/stdio.h>
#ifdef DO_DBCS
/* use SBCS string routines for logging, network data, etc. */
#include <Ansi/sbcs.h>
#endif

#include <pppLog.h>

#include <ip.h>
#include <slcompress.h>
#include <fsm.h>
#include <lcp.h>
#include <lqm.h>
#include <pap.h>
#include <chap.h>
#include <ipcp.h>
#include <Internal/netutils.h>

#ifdef USE_CCP
#include <ccp.h>

#ifdef STAC_LZS
#include <lzs.h>
#endif /* STAC_LZS */

#ifdef MPPC
#include <mppc.h>
#endif /* MPPC */

#endif /* USE_CCP */

#ifdef DO_DBCS
#define C_CTRL_Q   0x11	/* <ctrl>-Q */
#define C_CTRL_S   0x13	/* <ctrl>-S */
#endif


/*
 *	Important FCS values.
 */
# define	PPP_INITFCS	0xFFFF	/* Initial FCS value */
# define	PPP_GOODFCS	0xF0B8	/* Good final FCS value */
# define	PPP_FCS(fcs, c)	(((fcs) >> 8) ^ fcstab[((fcs) ^ (c)) & 0xff])

extern unsigned short fcstab[];
extern unsigned short pppfcs();

/*
 *	Async HDLC values
 */
# define	PPP_ALLSTATIONS	0xFF	/* All-Stations broadcast address */
# define	PPP_UI		0x03	/* Unnumbered Information */
# define	PPP_FLAG	0x7E	/* Flag Sequence */
# define	PPP_ESCAPE	0x7D	/* Asynchronous Control Escape */
# define	PPP_TRANS	0x20	/* Async transparency modifier */

/*
 *	Inline versions of {get,put}{char,short,long}.  Pointer is
 *	advanced; we assume that both arguments are lvalues and will
 *	already be in registers.  cp MUST be unsigned char *.
 *
 *	These macros get a value from cp, convert it to host format,
 * 	and advance cp accordingly.  (MST's trick to avoid ntoh code.)
 */
#if ERROR_CHECK

#define GETCHAR(c, cp) { ECCheckBounds(cp); (c) = *(cp)++; }

#define	PUTCHAR(c, cp) { ECCheckBounds(cp); *(cp)++ = (c); }

#define GETSHORT(s, cp) { \
			 ECCheckBounds(cp); \
			(s) = *(cp)++ << 8; \
			 ECCheckBounds(cp); \
			(s) |= *(cp)++; \
			}

# define PUTSHORT(s, cp) { \
			 ECCheckBounds(cp); \
			*(cp)++ = (s) >> 8; \
			 ECCheckBounds(cp); \
			*(cp)++ = (s); \
			}

# define GETLONG(l, cp)	{ \
			 ECCheckBounds(cp); \
			(l) = *(cp)++ << 8; \
			(l) |= *(cp)++; (l) <<= 8; \
			(l) |= *(cp)++; (l) <<= 8; \
			 ECCheckBounds(cp); \
			(l) |= *(cp)++; \
			}

# define PUTLONG(l, cp)	{ \
			 ECCheckBounds(cp); \
			*(cp)++ = (l) >> 24; \
			*(cp)++ = (l) >> 16; \
			*(cp)++ = (l) >> 8; \
			 ECCheckBounds(cp); \
			*(cp)++ = (l); \
			}

# define INCPTR(n, cp)	((cp) += (n))
# define DECPTR(n, cp)	((cp) -= (n))

#else /* not ERROR_CHECK */

#define GETCHAR(c, cp) { (c) = *(cp)++; }

#define	PUTCHAR(c, cp) { *(cp)++ = (c); }

#define GETSHORT(s, cp) { \
			(s) = *(cp)++ << 8; \
			(s) |= *(cp)++; \
			}

# define PUTSHORT(s, cp) { \
			*(cp)++ = (s) >> 8; \
			*(cp)++ = (s); \
			}

# define GETLONG(l, cp)	{ \
			(l) = *(cp)++ << 8; \
			(l) |= *(cp)++; (l) <<= 8; \
			(l) |= *(cp)++; (l) <<= 8; \
			(l) |= *(cp)++; \
			}

# define PUTLONG(l, cp)	{ \
			*(cp)++ = (l) >> 24; \
			*(cp)++ = (l) >> 16; \
			*(cp)++ = (l) >> 8; \
			*(cp)++ = (l); \
			}

# define INCPTR(n, cp)	((cp) += (n))
# define DECPTR(n, cp)	((cp) -= (n))

#endif /* not ERROR_CHECK */


/*
 * 	Data Link Layer header: Address, Control, Protocol.
 */
# define ALLSTATIONS	0xff	/* All-Stations Address */
# define UI		0x03	/* Unnumbered Information */
# define LCP		0xc021	/* Link Control Protocol */
# define IPCP		0x8021	/* IP Control Protocol */
# define PAP		0xc023	/* Password Authentication Protocol */
# define LQM		0xc025	/* Link Quality Monitoring */
# define CHAP		0xc223	/* Cryptographic Handshake Auth. Protocol */
# define IP		0x0021	/* IP Itself */
# define IP_VJ_COMP	0x002d	/* VJ TCP compressed IP packet */
# define IP_VJ_UNCOMP	0x002f	/* VJ TCP uncompressed IP packet */
# define CCP		0x80fd	/* Compression Control Protocol */
# define CCP_LINK	0x80fb	/* Individual link CCP */
# define COMPRESS	0x00fd	/* Compressed datagram */
# define COMPRESS_LINK	0x00fb	/* Individual link compressed datagram */

/*
 *  Address = 1 byte, Control = 1 byte, Protocol = 2 bytes.
 */
# define DLLHEADERLEN	4
# define MAX_FCS_LEN	4

# define MAX_MTU	    	2048	/* Max MTU */
# define MRU_MARGIN_OF_ERROR	50	/* accept packets which do not exceed
					   the negotiated MTU by more than
					   this amount. */

# define DEF_VJ_SLOTS	16	/* Default # of VJ compress slots */
# define MIN_VJ_SLOTS	3	/* Minimum # of VJ compress slots */
# define MAX_VJ_SLOTS	250	/* Maximum # of VJ compress slots */
                                /*  Any more slots would exceed 64K */
/*
 * 	Values in ppp_mode_flags:
 *
 *  Used for building PPP frames out of the input data.
 */
# define	SC_ESCAPED	0x1	/* PPP_ESCAPE seen */
# define	SC_FLUSH	0x2	/* Flush input until next flag */
# define	SC_RX_COMPAC	0x4	/* HDLC address/protocol compression */
# define	SC_TX_COMPAC	0x8	/* HDLC address/protocol compression */
# define	SC_RX_COMPPROT	0x10	/* PPP protocol field compression */
# define	SC_TX_COMPPROT	0x20	/* PPP protocol field compression */
# define	SC_RX_VJ_COMP	0x40	/* VJ TCP header compression */
# define	SC_TX_VJ_COMP	0x80	/* VJ TCP header compression */

/*
 * 	Define these macros rather than changing all the MST code
 *	to use GEOS buffer code.
 */
# define PACKET     	    	MbufHeader
# define PACKET_DATA(p)	    	(unsigned char *)mtod(p)
# define PACKET_FREE(p)	    	PPPFreeBuffer(p)
# define PACKET_ALLOC(size)    	PPPAllocBuffer(size)

# define PACKET_LOCK(pOptr) 	HugeLMemLock(OptrToHandle(pOptr))
# define PACKET_UNLOCK(pOptr)   HugeLMemUnlock(OptrToHandle(pOptr))
# define PACKET_FREE_UNLOCKED(pOptr)	HugeLMemFree(pOptr)
# define PACKET_POINTER(pOptr)	(MbufHeader *)LMemDeref(pOptr)
# define PACKET_OPTR(p)	    	PPPGetBufferOptr(p)

# define NPPP	    	1   	    	/* # of interfaces PPP supports. */


/* # of protocols PPP knows about */
#ifdef USE_CCP
# define NUM_PROTOS    	10	    	/* include CCP and COMPRESS */
#else
# define NUM_PROTOS 	8
#endif /* USE_CCP */

# define OUTPUT_BUFFER_SIZE 	64  	/* arbitrary (copied from MST) */

/*
 * A few constants to simplify coding of escape and discard maps.
 * Index indicates the byte in the map containing the bit for the value
 * and the mask is used to set the bit(s) in that byte.
 */
# define MAP_SIZE   	    32 	    	/* 256 bits */
# define PPP_FLAG_ESC_INDEX 15	    	/* PPP_FLAG and PPP_ESCAPE */
# define PPP_FLAG_ESC_MASK  0x60
# define MAP_INDEX(i)	    (i) / 8
# define MAP_MASK(i)	    1 << ((i) % 8)

extern char escape_map[MAP_SIZE], discard_map[MAP_SIZE];

extern unsigned char *frame_buffer_pointer, fsm_code, fsm_reply_code,
    *fsm_ptr, fsm_id, ip_connected, passive_waiting, fcs_error;

extern int max_retransmits, cf_mru, ppp_mode_flags, fsm_len, link_error,
    compressed_bytes, frame_len, idle_timeout, idle_time;

extern unsigned short input_fcs;

extern unsigned long last_time;

extern PACKET *frame_buffer, *fsm_packet;

extern void EndNetworkPhase (), BeginNetworkPhase (), SetEscapeMap (),
    SetProtoCompression (), PPPSendPacket (), PPPReset ();

extern void demuxprotrej (int unit, unsigned short protocol);
extern void SetVJCompression (int unit, int rx_slots, int tx_slots,
			      unsigned char cid);
extern void SetACCompression (int u, word rx_accomp, word tx_accomp);
extern void SetInterfaceMTU (unsigned short m);

extern optr frame_buffer_optr;

#ifdef USE_CCP

extern byte active_compress;

extern fsm ccp_fsm[NPPP];

extern ccp_options ccp_wantoptions[NPPP], ccp_gotoptions[NPPP],
    ccp_allowoptions[NPPP], ccp_heroptions[NPPP];

extern struct ccp ccp[NPPP];

extern byte PPPInput(unsigned short protocol, PACKET *buffer, int len);

extern unsigned short perf_mode, perf;

/*
 * For storing default compression values when temporarily overridden
 * by accpnt compression setting.
 */
extern byte default_active_comp;
extern WordFlags default_allowed_comp, default_want_comp;

#endif /* USE_CCP */

/*---------------------------------------------------------------------------
 *
 *	    	    	    C stubs
 *
 -------------------------------------------------------------------------- */

/*
 * Allocates a buffer of at least the requested size and returns the
 * pointer to it.  If unable to allocate, zero is returned.
 */
extern PACKET *
    _pascal PPPAllocBuffer (word bufSize);

/*
 * Unlocks and frees frame buffer.  Buffer MUST be locked.
 */
extern void
    _pascal PPPFreeBuffer (PACKET *p);


/*
 * Return optr of frame buffer.
 */
extern optr
    _pascal PPPGetBufferOptr (PACKET *p);

/*
 * If handle is non-zero, frees the block.
 */
extern void
    _pascal PPPFreeBlock (Handle h);

/*
 *
 */
extern void
    _pascal PPPGetPeerPasswd (unsigned char *peername,
			      Handle *passwd,
			      int *len);

#define PPPGetPeerSecret PPPGetPeerPasswd

/*
 * Deliver packet to IP client.
 */
extern void
    _pascal PPPDeliverPacket (PACKET *packet, int unit);

/*
 *
 */
extern void
    _pascal PPPLinkOpened (void);

/*
 *
 */
extern void
    _pascal PPPLinkClosed (word error);

/*
 *	Send output data to the device driver.
 */
extern void
    _pascal PPPDeviceWrite (unsigned char *data, word numBytes);

/*
 * 	Close the physical connection.
 */
extern unsigned short
    _pascal PPPDeviceClose (void);

#ifdef __HIGHC__
pragma Alias(PPPAllocBuffer, "PPPALLOCBUFFER");
pragma Alias(PPPFreeBuffer, "PPPFREEBUFFER");
pragma Alias(PPPGetBufferOptr, "PPPGETBUFFEROPTR");
pragma Alias(PPPFreeBlock, "PPPFREEBLOCK");
pragma Alias(PPPGetPeerPasswd, "PPPGETPEERPASSWD");
pragma Alias(PPPDeliverPacket, "PPPDELIVERPACKET");
pragma Alias(PPPLinkOpened, "PPPLINKOPENED");
pragma Alias(PPPLinkClosed, "PPPLINKCLOSED");
pragma Alias(PPPDeviceWrite, "PPPDEVICEWRITE");
pragma Alias(PPPDeviceClose, "PPPDEVICECLOSE");
#endif /* __HIGHC__ */

#endif /* _PPP_H_ */
