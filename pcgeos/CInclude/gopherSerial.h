/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	Gopher Client	  
 * MODULE:	Gopher Library -- serial testing  
 * FILE:	gopherSerial.h
 *
 * AUTHOR:  	  Alvin Cham: Aug 22, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	AC	8/22/94   	Initial version
 *
 * DESCRIPTION:
 *	This file contains some definitions for the GopherSerialClass.
 *
 * 	$Id: gopherSerial.h,v 1.1 97/04/04 16:00:11 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _GOPHER_SERIAL_HEADER_FILE
#define _GOPHER_SERIAL_HEADER_FILE

#include <geos.h>

#include <Ansi/string.h>
#include <Ansi/ctype.h>
#include <Ansi/stdio.h>

#include <streamC.h>
#include <library.h>
#include <driver.h>


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* 
 * These are the default setting values for testing the serial communication.
 * You may want to change these to adjust to your settings.
 */

#define GOPHER_SERIAL_COM_PORT_DEFAULT 	(SERIAL_COM2)
#define GOPHER_SERIAL_BAUD_RATE_DEFAULT	(SERIAL_BAUD_9600)

/* 
 * Changing any of the following may possibly screw up the communicating 
 * process between the PC and the sparc.  
 */
#define GOPHER_SERIAL_LENGTH_DEFAULT	(SERIAL_LENGTH_8)
#define GOPHER_SERIAL_PARITY_DEFAULT	(SERIAL_PARITY_NONE)
#define	GOPHER_SERIAL_XSTOP_BITS_DEFAULT	(SERIAL_XSTOP_NONE)
#define GOPHER_SERIAL_MODE_DEFAULT	(SERIAL_MODE_COOKED)
#define GOPHER_SERIAL_FLOW_CONTROL_DEFAULT      (SFC_SOFTWARE)

#define	GOPHER_SERIAL_TIMER_READ_INTERVAL	(2)

#endif /* _GOPHER_SERIAL_HEADER_FILE */



















