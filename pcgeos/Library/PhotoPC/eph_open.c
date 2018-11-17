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

#include "config.h"
#include "eph_io.h"
#include "eph_priv.h"
#include <Ansi/stdio.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>
#include <streamC.h>

#define ERRNO (iob->lastError)

#define DEFSPEED SB_19200

int CLOSE(eph_iob *iob)
{
	StreamError err = SerialClose(iob->driver,iob->fd,STREAM_DISCARD);
	GeodeFreeDriver(iob->driver);

	return (int)err;
}

 /***********************************************************************
 *
 * FUNCTION:	eph_open
 *
 * CALLED BY:	PPCOpen
 *
 * STRATEGY:	Open a serial connection with the camera
 *
 *             speed = 0 as passed in from PPCOpen
 *					speed is real, tell it to the camera.  portBaud is what we have
 *				   to tell to the Geos serial driver to make it set real speed
 *
 *		         Return 0 on success
 *
 *
 ***********************************************************************/
int
eph_open(eph_iob *iob, SerialPortNum devname, long speed)
{
 long		ephspeed; /* representation of speed sutable for camera command */
 int		rc;
 int		count = 0;
 word		errno;
 SerialBaud		portBaud;
 dword	toSpeed;


   /* set camera and port speeds based on speed arg */
//	if (speed == 0) speed = MAX_SPEED;   // 115200
	/* TESTING */
//	speed = 57600;
	switch (speed) {
		case 1:
			ephspeed = 1;
			portBaud = SB_9600;
			toSpeed = 9600;
			break;
		case 2:
			ephspeed = 2;
			portBaud = SB_19200;
			toSpeed = 19200;
			break;
		case 3:
			ephspeed = 3;
			portBaud = SB_38400;
			toSpeed = 38400;
			break;
		case 4:
			ephspeed = 4;
			portBaud = SB_57600;
			toSpeed = 57600;
			break;
		case 5:
			ephspeed = 5;
			portBaud = SB_115200;
			toSpeed = 115200;
			break;
		default:
#ifdef EPH_ERROR
			eph_error(iob, ERR_BADSPEED, "specified speed %ld invalid", speed);
#endif
			return -1;
		}  /* end of speed switch */

	/* set the timeout (this is only used in eph_readpkt) based on speed */
	iob->timeout = DATATIMEOUT + ((2048000000L)/toSpeed)*10;
#ifdef DEBUG
	if (iob->debug) printf("set iob timeout to %lu\r\n", iob->timeout);
#endif

	/* set the port as passed in */
	iob->fd = devname;
	/* load the Geos serial driver */
	if ((iob->driver = SerialLoadDriver()) == NullHandle ||
		 (errno = SerialOpen(iob->driver, iob->fd, STREAM_OPEN_NO_BLOCK, 2048+255, //bump up buffer
				128, 0)) != STREAM_NO_ERROR) {
		if (iob->driver != NullHandle)
			/* if we couldn't open the serial port */
			GeodeFreeDriver(iob->driver);
		return -1;
		}
	/* OK - the driver is loaded and the port is open ...
		set the serial port format at the initial speed. */
	if ((errno = SerialSetFormat(iob->driver, iob->fd, 
			(SERIAL_PARITY_NONE << SERIAL_FORMAT_PARITY_OFFSET) |
			(SERIAL_LENGTH_8 << SERIAL_FORMAT_LENGTH_OFFSET),
			SERIAL_MODE_RAW, DEFSPEED)) != STREAM_NO_ERROR) {
#ifdef EPH_ERROR
		eph_error(iob, errno, "SerialSetFormat error %s", strerror(errno));
		CLOSE(iob);
#endif
		return -1;
		}

	/* initiate comms with the camera */
	do {
		/* read one byte from the serial port */
		if (eph_flushinput(iob)) {
#ifdef EPH_ERROR
			eph_error(iob, ERRNO, "error flushing input: %s", strerror(ERRNO));
#endif
			CLOSE(iob);
			return -1;
			}
		/* write one 0 to the serial driver */
		eph_writeinit(iob);
		/* read a byte returned from the camera. If it's the camera signature
			byte (0x15) rc will be 0 and all will be well */
		rc = eph_waitsig(iob);
		if (rc) shortsleep(3000000L);
	} while (rc && (count++ < RETRIES));

	if (rc) {
		CLOSE(iob);
		return -1;
	}

	/* set the xfer speed for the camera */
	if (eph_setispeed(iob, ephspeed)) {
#ifdef EPH_ERROR
		eph_error(iob, ERRNO, "could not switch camera speed %d: %s",
				ephspeed, strerror(ERRNO));
#endif
		CLOSE(iob);
		return -1;
	}
   /* and the serial port's speed */
	if ((errno = SerialSetFormat(iob->driver, iob->fd, 
			(SERIAL_PARITY_NONE << SERIAL_FORMAT_PARITY_OFFSET) |
			(SERIAL_LENGTH_8 << SERIAL_FORMAT_LENGTH_OFFSET),
			SERIAL_MODE_RAW, portBaud)) != STREAM_NO_ERROR) {
#ifdef EPH_ERROR
		eph_error(iob, errno, "could not switch port speed %d: %s",
			  portBaud, strerror(errno));
#endif
		CLOSE(iob);
		return -1;
	}

	shortsleep(SPEEDCHGDELAY);
//	SerialFlush(iob->driver, iob->fd, STREAM_ROLES_READER);

	return 0;
}

int
eph_close(eph_iob *iob,int switchoff)
{

	if (switchoff) {
		byte zero=0;

		eph_action(iob,4,&zero,1);
		/* Oly 600 does not send EOT if switched off by command
		eph_waiteot(iob); */
	} else {
		eph_setispeed(iob,0L);
	}

	return CLOSE(iob);
}
