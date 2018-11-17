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

/*
	$Log: eph_read.c,v $
	Revision 2.7  1999/08/01 21:36:54  crosser
	Modify source to suit ansi2knr
	(I hate the style that ansi2knr requires but you don't expect me
	to write another smarter ansi2knr implementation, right?)

	Revision 2.6  1999/03/06 13:37:08  crosser
	Convert to autoconf-style

	Revision 2.5  1998/10/18 13:18:27  crosser
	Put RCS logs and I.D. into the source

	Revision 2.4  1998/08/01 13:12:41  lightner
	change Windows logic and timeouts
	
	Revision 2.3  1998/01/18 02:16:45  crosser
	DOS support
	
	Revision 2.2  1998/01/05 19:49:14  lightner
	Win32 syntax error fixed: fd changed to iob->fd
	
	Revision 2.1  1998/01/03 19:57:13  crosser
	Fix Windows things, improve error reporting
	
	Revision 2.0  1998/01/02 19:20:11  crosser
	Added support for Win32
	
	Revision 1.1  1997/08/17 08:59:54  crosser
	Initial revision
	
*/

#include "config.h"
#include <streamC.h>

#include "eph_io.h"

/*
	Platform-dependant implementation of read with timeout
*/

 /***********************************************************************
 *
 * FUNCTION:	eph_readt
 *
 * CALLED BY:	eph_readpkt, eph_flushinput, eph_waitchar
 *
 * STRATEGY:
 *		         Returns number of bytes read or -1 if error
 *
 ***********************************************************************/
size_t eph_readt(eph_iob *iob, byte *buf, size_t length, long timeout_usec, int *rc)
{
 word		numread = 0, rlen = 0;
 word		ticks/*, bytesAvail, lastBytes*/;
 dword	start;
 word		err = 0;
// Boolean	keepWaiting;
 byte		dataByte;

	/* bad input */
	if (length == 0)
		 return 0;

	start = TimerGetCount();

	/* set the timeout in ticks  Hmmm, what's the deal when timeout_usec is
		0 as when this routine is called from eph_flushinput.  Looks like ticks
		stays zero. */
	ticks = (word)(timeout_usec * 3L / 50000L);
	if (ticks == 0 && timeout_usec != 0)
	    ticks = 1;		// round up to at least one tick

#ifdef DEBUG
	printf(" Read timeout in ticks: %d\r\n", ticks);
	printf(" Reading %d byte(s).\r\n", length);
#endif

	while ((word)(TimerGetCount() - start) <= ticks && !err && length) {
		/* When getting pix data we're reading the serial port as it fills up
			doing the SerialRead several times to get all 2048 bytes.  Could
			this be part of the CRC problem?  To see let's make sure the serial
			port has accumulated the number of bytes we're expecting to read. */
		/* Well it generally has 80 - 100 more bytes in WinNT - which throws
			off the CRC and bombs us out - 11/6/03 jfh */
/*		if (length > 8) {
			keepWaiting = TRUE;
			lastBytes = 0;
			while (keepWaiting) {
				SerialQuery (iob->driver, iob->fd, STREAM_ROLES_READER, &bytesAvail);
/*#ifdef DEBUG
	printf(" SerialQuery() says %d bytes avaliable.\r\n", bytesAvail);
/*#endif
				if (bytesAvail == lastBytes) keepWaiting = FALSE;
				lastBytes = bytesAvail;
				TimerSleep(2);
				}
			} */
		err = SerialRead(iob->driver, iob->fd, STREAM_NO_BLOCK, length,
							  buf, &numread);
		if (!err) {
			if (numread != 0) {
				buf += numread;
				rlen += numread;
				length -= numread;
				}
			else
				TimerSleep(1);
			}
		}

	*rc = rlen ? 1 : 0;

	if (err) {
		iob->lastError = err;
		return (size_t)-1;
	} else {
		return (size_t)rlen;
	}
}
