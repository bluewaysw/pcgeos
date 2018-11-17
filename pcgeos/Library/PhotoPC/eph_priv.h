/*
	Copyright (c) 1997,1998 Eugene G. Crosser
	Copyright (c) 1998 Bruce D. Lightner (DOS/Windows support)

	You may distribute and/or use for any purpose modified or unmodified
	copies of this software if you preserve the copyright notice above.

	THIS SOFTWARE IS PROVIDED AS IS AND COME WITH NO WARRANTY OF ANY
	KIND, EITHER EXPRESSED OR IMPLIED.  IN NO EVENT WILL THE
	COPYRIGHT HOLDER BE LIABLE FOR ANY DAMAGES RESULTING FROM THE
	USE OF THIS SOFTWARE.
*/

#ifndef _EPH_PRIV_H
#define _EPH_PRIV_H

#define RETRIES              3

#ifdef USE_VMIN_AND_VTIME
#define INITTIMEOUT    1700000L
#define DATATIMEOUT    1100000L
#define BIGDATATIMEOUT 1500000L
#define ACKTIMEOUT     1100000L
#define BIGACKTIMEOUT  1100000L
#define EODTIMEOUT     1100000L
#define CMDTIMEOUT    15000000L
#else
#define INITTIMEOUT    3000000L
#define DATATIMEOUT     200000L
#define BIGDATATIMEOUT 1500000L
#define ACKTIMEOUT      400000L
#define BIGACKTIMEOUT   800000L
#define EODTIMEOUT      400000L
#define CMDTIMEOUT    15000000L
#endif

/* Bruce and others say that adding 1ms delay before all writes is good.
   I think that they should rather be fine-tuned. */
#if 1
#define WRTPKTDELAY       1250L
#define WRTCMDDELAY       1250L
#define WRTPRMDELAY       1500L
#define WRTDELAY          2000L
#else
#define WRTPKTDELAY        250L
#define WRTCMDDELAY        250L
#define WRTPRMDELAY        500L
#define WRTDELAY          1000L
#endif
#define SPEEDCHGDELAY   100000L

#define SKIPNULS           200

#define ACK 0x06
#define DC1 0x11
#define NAK 0x15
/*#define NAK 0x11*/

#define CMD_SETINT 0
#define CMD_GETINT 1
#define CMD_ACTION 2
#define CMD_SETVAR 3
#define CMD_GETVAR 4

#define PKT_CMD 0x1b
#define PKT_DATA 0x02
#define PKT_LAST 0x03

#define SEQ_INITCMD 0x53
#define SEQ_CMD 0x43

typedef struct _eph_pkthdr {
	byte typ;
	byte seq;
} eph_pkthdr;

size_t eph_readt(eph_iob *iob,byte *buf,size_t length,long timeout_usec,int *rc);

#ifdef EPH_ERROR
char *strerror(int err);
void eph_error(eph_iob *iob,int err,char *fmt,...);
#endif

int eph_flushinput(eph_iob *iob);
void eph_writeinit(eph_iob *iob);
void eph_writeack(eph_iob *iob);
void eph_writenak(eph_iob *iob);
int eph_waitack(eph_iob *iob,long timeout_usec);
int eph_waitcomplete(eph_iob *iob);
int eph_waitsig(eph_iob *iob);
int eph_waiteot(eph_iob *iob);

int eph_writepkt(eph_iob *iob,int typ,int seq,byte *data,size_t length);
int eph_writecmd(eph_iob *iob,byte *data,size_t length);
int eph_writeicmd(eph_iob *iob,byte *data,size_t length);
int eph_readpkt(eph_iob *iob,eph_pkthdr *pkthdr,byte *buf,size_t *length,long timeout_usec);

int eph_setispeed(eph_iob *iob,long val);

#endif
