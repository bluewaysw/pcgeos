/*
	Copyright (c) 1997-1999 Eugene G. Crosser
	Copyright (c) 1998,1999 Bruce D. Lightner (DOS/Windows support)

	You may distribute and/or use for any purpose modified or unmodified
	copies of this software if you preserve the copyright notice above.

	THIS SOFTWARE IS PROVIDED AS IS AND COME WITH NO WARRANTY OF ANY
	KIND, EITHER EXPRESSED OR IMPLIED.  IN NO EVENT WILL THE
	COPYRIGHT HOLDER BE LIABLE FOR ANY DAMAGES RESULTING FROM THE
	USE OF THIS SOFTWARE.
*/

#include "config.h"
#include <Ansi/stdio.h>
#include <streamC.h>

#include "eph_io.h"
#include "eph_priv.h"

#ifdef INT16
typedef unsigned INT16 uint16;
#endif

#define ERRNO (iob->lastError)

#if !defined(BYTE_BY_BYTE_WRITE) && !defined(SINGLE_BURST_WRITE)
static struct _chunk {
	size_t offset;
	size_t size;
	unsigned long delay;
} chunk[] = {
	{	0L,	1L,	WRTPKTDELAY	},
	{	1L,	3L,	WRTCMDDELAY	},
	{	4L,	0L,	WRTPRMDELAY	}
};
#define MAXCHUNK 3
#endif

/*
	System-specific WRITE implementation
*/

 /***********************************************************************
 *
 * FUNCTION:	WRITE
 *
 * CALLED BY:	several in this file
 *
 * STRATEGY:	write thru the Geos serial driver
 *             returns 0 on success
 *
 ***********************************************************************/
int WRITE(eph_iob *iob, void *buf, int length)
{
 word				written;
 StreamError	err;


	/* try this flush */
	SerialFlush (iob->driver, iob->fd, STREAM_ROLES_BOTH);

	if ((err = SerialWrite(iob->driver, iob->fd, STREAM_BLOCK, length, buf,
				&written)) != STREAM_NO_ERROR || written != length) {
		iob->lastError = err;
		return 1;
		}
	else
		return 0;
}
		
 /***********************************************************************
 *
 * FUNCTION:	eph_writepkt
 *
 * CALLED BY:	various
 *
 * STRATEGY:   writes the passed buffer
 *
 *					returns 0 on success
 *
 ***********************************************************************/
int eph_writepkt(eph_iob *iob, int typ, int seq, byte *data, size_t length)
{
 uint16		crc=0;
 byte			buf[136];
 int			i=0, j;


	/* make sure we're not writing too large a packet */
	if (length > (sizeof(buf) - 6)) {
#ifdef EPH_ERROR
		eph_error(iob,ERR_DATA_TOO_LONG,
			"trying to write %ld in one pkt",(long)length);
		return -1;
#endif
		}

   /* set up the packet buffer */
	buf[i++] = typ;
	buf[i++] = seq;
	buf[i++] = length & 0xff;
	buf[i++] = length >> 8;
	for (j = 0; j < length; j++) {
		crc += (byte)data[j];
		buf[i++] = data[j];
		}
	buf[i++] = crc & 0xff;
	buf[i++] = crc >> 8;
#ifdef DEBUG
	if (iob->debug > 1) {
		printf("> (%d)",i);
		for (j=0; j<i ;j++) {
			printf(" %02x", buf[j]);
			}
		printf("\r\n");
		}
#endif

	/* and write it using SMART CHUNKED WRITE */
	for (j=0; j < MAXCHUNK; j++) {
		size_t sz = (chunk[j].size) ? (chunk[j].size)
						:(i - chunk[j].offset);
		shortsleep(chunk[j].delay);
		if (WRITE(iob, buf + chunk[j].offset, sz)) {
#ifdef EPH_ERROR
			eph_error(iob, ERRNO, "pkt write chunk %d(%d) error %s",
						 j, (int)sz, strerror(ERRNO));
#endif
			return -1;
			}
		}

	return 0;

}

 /***********************************************************************
 *
 * FUNCTION:	eph_writeinit
 *
 * CALLED BY:	eph_open
 *
 * STRATEGY:	write a 0 to the serial driver
 *
 *
 ***********************************************************************/
void eph_writeinit(eph_iob *iob)
{
 byte		init = 0;

#ifdef DEBUG
	if (iob->debug > 1) printf("> INIT 00\r\n");
#endif
	shortsleep(WRTDELAY);
	if (WRITE(iob, &init, 1)) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "init write error %s", strerror(ERRNO));
#endif
		}
}

 /***********************************************************************
 *
 * FUNCTION:	eph_writeack
 *
 * CALLED BY:	various
 *
 * STRATEGY:
 *
 *
 *
 ***********************************************************************/
void eph_writeack(eph_iob *iob)
{
 byte		ack = ACK;


	shortsleep(WRTDELAY);
	if (WRITE(iob, &ack, 1)) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "ack write errot %s", strerror(ERRNO));
#endif
		}

#ifdef DEBUG
	if (iob->debug > 1) printf("> ACK (06)\r\n");
#endif

}

 /***********************************************************************
 *
 * FUNCTION:	eph_writenak
 *
 * CALLED BY:	various
 *
 * STRATEGY:
 *
 *
 *
 ***********************************************************************/
void eph_writenak(eph_iob *iob)
{
 byte		nak = NAK;


	shortsleep(WRTDELAY);
	if (WRITE(iob, &nak, 1)) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "nak write error %s", strerror(ERRNO));
#endif
		}

#ifdef DEBUG
	if (iob->debug > 1) printf("> NAK (15)\r\n");
#endif

}

 /***********************************************************************
 *
 * FUNCTION:	eph_readpkt
 *
 * CALLED BY:	eph_getint, eph_getvar
 *
 * STRATEGY:   - read the first byte returned from the camera to check
 *               if it is a valid response
 *             - read the remaining 3 bytes of the header (seq & size of pkt)
 *             - read in the rest of the packet (the data)
 *             - read the crc and compare with our computed crc
 *
 *
 ***********************************************************************/
int eph_readpkt(eph_iob *iob, eph_pkthdr *pkthdr, byte *buffer,
					size_t *bufsize, long timeout_usec)
{
 uint16		length, got;
 uint16		crc1 = 0, crc2;
 byte			buf[4];
 int			i, rc;


	/* read the first character */
	i = eph_readt(iob, buf, 1, timeout_usec, &rc);
#ifdef DEBUG
	if (iob->debug > 1)
		printf ("pktstart: i=%d rc=%d char=0x%02x\r\n", i, rc, *buf);
#endif

	/* report any errors in the read */
	if (i < 0) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "pkt start read error %s", strerror(ERRNO));
#endif
		return -1;
		}
	else if ((i == 0) && (rc == 0)) {
#ifdef EPH_ERROR
		eph_error(iob, ERR_TIMEOUT, "pkt start read timeout (%ld)", timeout_usec);
#endif
		return -2;
		}
	else if (i != 1) {
#ifdef EPH_ERROR
		eph_error(iob, ERR_BADREAD, "pkt start read %d, expected 1", i);
#endif
		return -1;
		}

	/* make sure it's a good packet */
	pkthdr->typ = buf[0];
	if ((*buf != PKT_DATA) && (*buf != PKT_LAST)) {
		if ((*buf != NAK) && (*buf != DC1))
#ifdef EPH_ERROR
			eph_error(iob, ERR_BADDATA, "pkt start got 0x%02x", *buf);
#endif
		return *buf;
		}

	/* read the rest of the packet header */
	got = 0;
	/* not sure why this is in a while loop - jfh */
	while ((i = eph_readt(iob, buf+1+got, 3-got, DATATIMEOUT, &rc)) > 0) {
		got += i;
		}
	/* report a packet header read error */
	if (got != 3) {
		if (i < 0) {
#ifdef EPH_ERROR
			eph_error(iob, ERRNO, "pkt hdr read error %s (got %d)",
																 strerror(ERRNO), got);
#endif
			return -1;
			}
		else if ((i == 0) && (rc == 0)) {
#ifdef EPH_ERROR
			eph_error(iob, ERR_TIMEOUT, "pkt hdr read timeout (%ld)", DATATIMEOUT);
#endif
			return -2;
			}
		else {
#ifdef EPH_ERROR
			eph_error(iob, ERR_BADREAD, "pkt hdr read return %d rc %d", i, rc);
#endif
			return -1;
			}
		}
#ifdef DEBUG
	/* show the header we read */
	if (iob->debug > 1) printf("header: %02x %02x %02x %02x\r\n",
				buf[0], buf[1], buf[2], buf[3]);
#endif

	/* get the packet seq and packet length */
	pkthdr->seq = buf[1];
	length = ((uint16)buf[3] << 8) | buf[2];
#ifdef DEBUG
	if (iob->debug > 1) printf("length: %d\r\n", (unsigned int)length);
#endif
	if (length > *bufsize) {
#ifdef EPH_ERROR
		eph_error(iob, ERR_DATA_TOO_LONG,
			"length in pkt header %lu bigger than buffer size %lu",
			(unsigned long)length, (unsigned long)*bufsize);
#endif
		return -1;
		}

	/* read the packet data */
	got = 0;
	/* as above, not sure why this is in a loop - jfh */
	while ((i = eph_readt(iob, buffer+got, length-got, iob->timeout, &rc)) > 0) {
		got+=i;
		}
	/* report any problems */
	if (got != length) {
		if (i < 0) {
#ifdef EPH_ERROR
			eph_error(iob, ERRNO, "pkt data read error %s", strerror(ERRNO));
#endif
			return -1;
			}
		else if ((i == 0) && (rc == 0)) {
#ifdef EPH_ERROR
			eph_error(iob, ERR_TIMEOUT, "pkt data read timeout (%ld)", iob->timeout);
#endif
			return -2;
			}
		else {
#ifdef EPH_ERROR
			eph_error(iob, ERR_BADREAD, "pkt read return %d, rc %d, got %d", i, rc, got);
#endif
			return -1;
			}
		}

	/* calculate crc of what we received */
	for (i = 0; i < length; i++) {
		crc1 += (byte)buffer[i];
		}

	/* get crc from camera */
	got = 0;
	while ((i = eph_readt(iob, buf+got, 2-got, DATATIMEOUT, &rc)) > 0) {
		got += i;
		}
#ifdef DEBUG
	if (iob->debug > 1)
		printf ("crc: %02x %02x i=%d rc=%d\r\n", buf[0], buf[1], i, rc);
#endif
	if (got != 2) {
		if (i < 0) {
#ifdef EPH_ERROR
			eph_error(iob, ERRNO,"pkt crc read error %s", strerror(ERRNO));
#endif
			return -1;
			}
		else if ((i == 0) && (rc == 0)) {
#ifdef EPH_ERROR
			eph_error(iob, ERR_TIMEOUT, "pkt crc read timeout (%ld)", DATATIMEOUT);
#endif
			return -2;
			}
		else {
#ifdef EPH_ERROR
			eph_error(iob, ERR_BADREAD, "pkt crc read return %d rc %d", i, rc);
#endif
			return -1;
			}
		}

#ifdef DEBUG
	/* show the packet data */
	if (iob->debug > 1) {
		int j, k;
		/* in hex */
		printf("< %d,%d (%d)\r\n", pkthdr->typ, pkthdr->seq, length);
		k = 4;
		/*if (iob->debug > 2) */for (j=0; j<length; j++) {
			printf(" %02x", (byte)buffer[j]);
         /* let's make lines of 16 bytes */
			k++;
			if (k == 16) {
				printf("\r\n");
				k = 0;
				}
			}
	 //	else printf(" ...");
		printf("\r\n");
		/* and ascii */
/*		printf("< %d,%d (%d)", pkthdr->typ, pkthdr->seq, length);
		if (iob->debug > 2) for (j=0; j<length; j++) {
			printf(" %c ", (buffer[j] >= ' ' && buffer[j] < 127) ? buffer[j] : '.');
			}
		else printf(" ...");
		printf("\r\n"); */
		}
#endif

	/* compare the two crcs */
	crc2 = ((uint16)buf[1]<<8) | buf[0];
	if (crc1 != crc2) {
#ifdef DEBUG
		if (iob->debug) printf("crc %04x != %04x\r\n", crc1, crc2);
#endif
#ifdef EPH_ERROR
		eph_error(iob, ERR_BADCRC, "crc received=0x%04x counted=0x%04x", crc2, crc1);
#endif
		return -1;
		}

	(*bufsize) = length;
	return 0;
}

 /***********************************************************************
 *
 * FUNCTION:	eph_flushinput
 *
 * CALLED BY:	eph_open
 *
 * STRATEGY:   Reads one byte from the serial port
 *		         Returns 0 on success
 *
 ***********************************************************************/
int
eph_flushinput(eph_iob *iob)
{
 byte		buf;
 int		i, rc;


	/* read one byte from the serial port */
	i = eph_readt(iob, &buf, 1, 0L, &rc);
#ifdef DEBUG
	if (iob->debug > 1)
		printf ("< %02x amount=%d rc=%d\r\n", buf, i, rc);
#endif

	if (i < 0) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "flushinput read error %s", strerror(ERRNO));
#endif
		return -1;
		}
	else if ((i == 0) && (rc == 0)) {
#ifdef DEBUG
		if (iob->debug)
			printf ("flushed: read %d amount=%d rc=%d\r\n", buf, i, rc);
#endif
		return 0;
		}
	else {
#ifdef EPH_ERROR
		eph_error(iob, ERR_BADREAD, "flushinput read %d expected 0", i);
#endif
		return -1;
		}

}

 /***********************************************************************
 *
 * FUNCTION:	eph_waitchar
 *
 * CALLED BY:	various
 *
 * STRATEGY:
 *
 *
 ***********************************************************************/
int
eph_waitchar(eph_iob *iob, unsigned long timeout_usec)
{
 byte		buf;
 int		i, rc;


 	buf = 0xff;
	/* read one byte from the serial port */
	i = eph_readt(iob, &buf, 1, timeout_usec, &rc);
#ifdef DEBUG
	if (iob->debug > 1)
		printf ("< %02x amount=%d rc=%d\r\n", buf, i, rc);
#endif
	if (i < 0) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "waitchar read error %s", strerror(ERRNO));
#endif
		return -1;
		}
	else if ((i == 0) && (rc == 0)) {
#ifdef EPH_ERROR
		eph_error(iob, ERR_TIMEOUT, "waitchar read timeout (%ld)", timeout_usec);
#endif
		return -2;
		}
	else if (i != 1) {
#ifdef EPH_ERROR
		eph_error(iob, ERR_BADREAD, "waitchar read %d expected 1", i);
#endif
		return -1;
		}

	return buf;
}

 /***********************************************************************
 *
 * FUNCTION:	eph_waitack
 *
 * CALLED BY:	various
 *
 * STRATEGY:
 *
 *
 ***********************************************************************/
int eph_waitack(eph_iob *iob, long timeout_usec)
{
 int rc;


	if ((rc = eph_waitchar(iob, timeout_usec)) == ACK) return 0;
#ifdef EPH_ERROR
	if ((rc != DC1) && (rc != NAK))
		eph_error(iob,ERR_BADREAD,"eph_waitack got %d",rc);
#endif
	return rc;
}

int
eph_waitcomplete(eph_iob *iob)
{
	int rc;
	if ((rc=eph_waitchar(iob,CMDTIMEOUT)) == 0x05) return 0;
#ifdef EPH_ERROR
	if ((rc != DC1) && (rc != NAK))
		eph_error(iob,ERR_BADREAD,"eph_waitcomplete got %d",rc);
#endif
	return rc;
}

 /***********************************************************************
 *
 * FUNCTION:	eph_waitsig
 *
 * CALLED BY:	eph_open
 *
 * STRATEGY:	Read one byte at a time (in the while) from the camera
 *
 *
 ***********************************************************************/
int
eph_waitsig(eph_iob *iob)
{
 int rc, count = SKIPNULS;


	while (((rc = eph_waitchar(iob, INITTIMEOUT)) == 0) && (count-- > 0)) ;
	if (rc == 0x15) // Camera signature
		return 0;
#ifdef EPH_ERROR
	eph_error(iob, ERR_BADREAD, "eph_waitsig got %d", rc);
#endif
	return rc;
}


#if 0 /* No longer used */
int
eph_waiteot(eph_iob *iob)
{
	int rc;
	if ((rc=eph_waitchar(iob,EODTIMEOUT)) == 0xff) return 0;
#ifdef EPH_ERROR
	if ((rc != DC1) && (rc != NAK))
		eph_error(iob,ERR_BADREAD,"eph_waiteot got %d",rc);
#endif
	return rc;
}
#endif
