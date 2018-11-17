/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	  Geos
 * MODULE:	  Medium
 * FILE:	  medium.h
 *
 * AUTHOR:  	  Chung Liu: Nov 20, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	CL	11/20/94   	Initial version
 *
 * DESCRIPTION:
 *	Medium definitions
 *
 *
 * 	$Id: medium.h,v 1.1 97/04/04 16:00:05 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _MEDIUM_H_
#define _MEDIUM_H_

typedef ByteEnum MediumUnitType;
#define MUT_NONE      	    0x0
#define MUT_INT       	    0x1
#define MUT_MEM_BLOCK 	    0x2
#define MUT_ANY       	    0x3
#define MUT_REASON_ENCLOSED 0x4

typedef enum {
    GMID_INVALID = 0x0,
    GMID_SERIAL_CABLE,
    GMID_INFRARED,
    GMID_DATA_MODEM,
    GMID_FAX_MODEM,
    GMID_PRINTER,
    GMID_PARALLEL_PORT,
    GMID_NETWORK,
    GMID_LOOPBACK,
    GMID_SM,
    GMID_CELL_MODEM
} GeoworksMediumID;

typedef struct {
    word            MET_id;
    ManufacturerID  MET_manuf;
} MediumType;

typedef struct {
    MediumType      MU_medium;
    MediumUnitType  MU_unitType;
    word            MU_unit;
} MediumAndUnit;

typedef struct {
    MediumUnitType  MUAR_type;
    word    	    MUAR_size;
} MediumUnitAndReason;

/*
 * The unit data follow immediately after the MediumUnitAndReason header
 */
#define MUAR_UNIT_DATA(muarPtr)	(void *)((muarPtr)+1)
/*
 * The reason for the status change follows immediately after the unit data
 */
#define MUAR_REASON(muarPtr) \
    (const TCHAR *)((byte *)MUAR_UNIT_DATA((muarPtr))+(muarPtr)->MUAR_size)
/*
 * SST_ Notification types
 */
typedef enum {
    MESN_MEDIUM_AVAILABLE = 0x0,
    MESN_MEDIUM_NOT_AVAILABLE,
    MESN_MEDIUM_CONNECTED,
    MESN_MEDIUM_NOT_CONNECTED,
} MediumSubsystemNotification;

#endif /* _MEDIUM_H_ */









