/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	driver.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines driver structures and routines.
 *
 *	$Id: driver.h,v 1.1 97/04/04 15:57:54 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__DRIVER_H
#define __DRIVER_H

#include <lmem.h>	/* LMemBlockHeader */
#include <geode.h>
/*
 * Driver info structure
 */


/* Geode driver types */

typedef enum /* word */ {
    DRIVER_TYPE_VIDEO=1,
    DRIVER_TYPE_INPUT,
    DRIVER_TYPE_MASS_STORAGE,
    DRIVER_TYPE_STREAM,
    DRIVER_TYPE_FONT,
    DRIVER_TYPE_OUTPUT,
    DRIVER_TYPE_LOCALIZATION,
    DRIVER_TYPE_FILE_SYSTEM,
    DRIVER_TYPE_PRINTER,
    DRIVER_TYPE_SWAP,
    DRIVER_TYPE_POWER_MANAGEMENT,
    DRIVER_TYPE_TASK_SWITCH,
    DRIVER_TYPE_NETWORK,
    DRIVER_TYPE_SOUND,
    DRIVER_TYPE_PAGER,
    DRIVER_TYPE_PCMCIA,
    DRIVER_TYPE_FEP,
    DRIVER_TYPE_MAILBOX_DATA,
    DRIVER_TYPE_MAILBOX_TRANSPORT,
    DRIVER_TYPE_SOCKET,
    DRIVER_TYPE_SCAN,
    DRIVER_TYPE_OTHER_PROCESSOR,
    DRIVER_TYPE_MAILBOX_RECEIVE,
    DRIVER_TYPE_MODEM,
    DRIVER_TYPE_CONNECT_TRANSLATE,
    DRIVER_TYPE_CONNECT_TRANSFER,
    DRIVER_TYPE_FIDO_INPUT
} DriverType;

/* Geode driver attributes */

typedef WordFlags DriverAttrs;
#define DA_FILE_SYSTEM		0x8000
#define DA_CHARACTER		0x4000
#define DA_HAS_EXTENDED_INFO	0x2000

/* Structure of a driver info table */

typedef struct {
    void		(*DIS_strategy)();
    DriverAttrs		DIS_driverAttributes;
    DriverType		DIS_driverType;
} DriverInfoStruct;

/***/

extern GeodeHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal GeodeUseDriver(const char *name, word protoMajor, word protoMinor,
		    	    GeodeLoadError *err);

/***/

extern GeodeHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal GeodeUseDriverPermName(const char *pname, word protoMajor, 
				word protoMinor, GeodeLoadError	*err);

/***/

extern void	/*XXX*/
    _pascal GeodeFreeDriver(GeodeHandle gh);

/***/

extern DriverInfoStruct *	/*XXX*/
    _pascal GeodeInfoDriver(GeodeHandle gh);

/***/

typedef enum /* word */ {
    GDDT_FILE_SYSTEM=0,
    GDDT_KEYBOARD=2,
    GDDT_MOUSE=4,
    GDDT_VIDEO=6,
    GDDT_MEMORY_VIDEO=8,
    GDDT_POWER_MANAGEMENT=10,
    GDDT_TASK=12
} GeodeDefaultDriverType;

extern GeodeHandle	/*XXX*/
    _pascal GeodeGetDefaultDriver(GeodeDefaultDriverType type);

/***/

extern void	/*XXX*/
    _pascal GeodeSetDefaultDriver(GeodeDefaultDriverType type, GeodeHandle gh);

/*
 * Driver function calls
 */

#define DR_INIT		0
#define DR_EXIT		2
#define DR_SUSPEND  	4
#define DR_UNSUSPEND	6

#define DRIVER_SUSPEND_ERROR_BUFFER_SIZE 128

#define DRIVER_PROTO_MAJOR	2
#define DRIVER_PROTO_MINOR	0

/*
 *	Extended driver definitions
 */

#define DRIVER_EXT_PROTO_MAJOR	(DRIVER_PROTO_MAJOR+1)
#define DRIVER_EXT_PROTO_MINOR	(DRIVER_PROTO_MINOR+0)

typedef enum /* word */ {
    DP_NOT_PRESENT=0xffff,
    DP_CANT_TELL=0,
    DP_PRESENT=1,
    DP_INVALID_DEVICE=0xfffe
} DevicePresent;

#define DRE_TEST_DEVICE	8
#define DRE_SET_DEVICE	10

/* Structure of an extended driver info table */

typedef struct {
    DriverInfoStruct	DEIS_common;
    MemHandle		DEIS_resource;
} DriverExtendedInfoStruct;

/* Maximum size of device name strings (see DEIT_nameTable, below). */

#define GEODE_MAX_DEVICE_NAME_LENGTH	64
#define GEODE_MAX_DEVICE_NAME_SIZE GEODE_MAX_DEVICE_NAME_LENGTH * sizeof(TCHAR)

typedef struct {
    LMemBlockHeader	DEIT_common;
    word		DEIT_numDevices;
    ChunkHandle		DEIT_ChunkHandle;
    word		DEIT_infoTable;
} DriverExtendedInfoTable;

/*
 *	Driver standard escape codes
 */

#define DRV_ESC_QUERY_ESC	0x8000

#ifdef __HIGHC__
pragma Alias(GeodeUseDriver, "GEODEUSEDRIVER");
pragma Alias(GeodeFreeDriver, "GEODEFREEDRIVER");
pragma Alias(GeodeInfoDriver, "GEODEINFODRIVER");
pragma Alias(GeodeGetDefaultDriver, "GEODEGETDEFAULTDRIVER");
pragma Alias(GeodeSetDefaultDriver, "GEODESETDEFAULTDRIVER");
#endif

#endif
