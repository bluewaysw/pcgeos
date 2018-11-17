/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	mouseDr.h
 *
 *
 * REVISION HISTORY:
 *	
 *	Name	Date		Description
 *	----	----		-----------
 *	atw	9/23/92		Initial revision
 *
 *
 * DESCRIPTION:
 *	This file defines mouse driver information.
 *		
 *	$Id: mouseDr.h,v 1.1 97/04/04 15:59:16 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__MOUSEDR_H
#define __MOUSEDR_H

#include <driver.h>

#define	MOUSE_PROTO_MAJOR   (DRIVER_PROTO_MAJOR+1)
#define	MOUSE_PROTO_MINOR   (DRIVER_PROTO_MINOR+0)

typedef struct {
    DriverExtendedInfoStruct	MDIS_common;
    word    MDIS_numButtons;

    /*
     *	MDIS_xRes/MDIS_yRes are the resolution (in points per inch) of the
     *  points collected by the digitizer. Mouse drivers have this word set
     *	to 0.
     */
    
    word    MDIS_xRes;
    word    MDIS_yRes;
} MouseDriverInfoStruct;


#endif


