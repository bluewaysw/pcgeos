/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	drive.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines (logical) drive structures and routines.
 *
 *	$Id: drive.h,v 1.1 97/04/04 15:58:33 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__DRIVE_H
#define __DRIVE_H

#define DRIVE_MAX_DRIVES	255

typedef ByteEnum DriveType;
#define DRIVE_5_25 0
#define DRIVE_3_5 1
#define DRIVE_FIXED 2
#define DRIVE_RAM 3
#define DRIVE_CD_ROM 4
#define DRIVE_8 5
#define DRIVE_PCMCIA 6
#define DRIVE_UNKNOWN 0xf

/***/

#define DS_PRESENT		0x80
#define DS_MEDIA_REMOVABLE	0x40
#define DS_NETWORK		0x20
#define DS_TYPE			0x0f		/* DriveType */

extern word		/* 0 for error */	/*XXX*/
    _pascal DriveGetStatus(word driveNumber);

/***/

#define DES_LOCAL_ONLY	    	0x1000
#define DES_READ_ONLY	    	0x0800
#define DES_FORMATTABLE	    	0x0400
#define DES_ALIAS   	    	0x0200
#define DES_BUSY    	    	0x0100

extern word	    	/* 0 for error */  	/*XXX*/
    _pascal DriveGetExtStatus(word driveNumber);

/***/

typedef ByteEnum MediaType;
#define MEDIA_NONEXISTENT 0
#define MEDIA_160K 1
#define MEDIA_180K 2
#define MEDIA_320K 3
#define MEDIA_360K 4
#define MEDIA_720K 5
#define MEDIA_1M2 6
#define MEDIA_1M44 7
#define MEDIA_2M88 8
#define MEDIA_FIXED_DISK 9
#define MEDIA_CUSTOM 10
#define MEDIA_SRAM	11
#define MEDIA_ATA 12
#define MEDIA_FLASH	13

extern MediaType	/*XXX*/
    _pascal DriveGetDefaultMedia(word driveNumber);

/***/

extern Boolean		/* true if media supported */	/*XXX*/
    _pascal DriveTestMediaSupport(word driveNumber, MediaType media);

/***/

extern char _far *    	/* NULL if buffer too small */ /*XXX*/
    _far _pascal DriveGetName(word driveNumber, char _far *buffer,
			      word bufferSize);

#ifdef __HIGHC__
pragma Alias(DriveGetStatus, "DRIVEGETSTATUS");
pragma Alias(DriveGetExtStatus, "DRIVEGETEXTSTATUS");
pragma Alias(DriveGetDefaultMedia, "DRIVEGETDEFAULTMEDIA");
pragma Alias(DriveTestMediaSupport, "DRIVETESTMEDIASUPPORT");
pragma Alias(DriveGetName, "DRIVEGETNAME");
#endif

#endif
