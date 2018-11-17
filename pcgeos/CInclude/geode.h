/***********************************************************************

 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	geode.h
 * AUTHOR:	Tony Requist: February 12, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines geode structures and routines.
 *
 *	$Id: geode.h,v 1.1 97/04/04 15:56:48 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__GEODE_H
#define __GEODE_H


/* Geode file attributes */

typedef WordFlags GeodeAttrs;
#define GA_PROCESS			0x8000
#define GA_LIBRARY			0x4000
#define GA_DRIVER			0x2000
#define GA_KEEP_FILE_OPEN		0x1000
#define GA_SYSTEM			0x0800
#define GA_MULTI_LAUNCHABLE		0x0400
#define GA_APPLICATION			0x0200
#define GA_DRIVER_INITIALIZED		0x0100
#define GA_LIBRARY_INITIALIZED		0x0080
#define GA_GEODE_INITIALIZED		0x0040
#define GA_USES_COPROC			0x0020
#define GA_REQUIRES_COPROC		0x0010
#define GA_HAS_GENERAL_CONSUMER_MODE	0x0008
#define GA_ENTRY_POINTS_IN_C		0x0004

/* Errors returned by GeodeLoad() */

typedef enum /* word */ {
    GLE_PROTOCOL_IMPORTER_TOO_RECENT,
    GLE_PROTOCOL_IMPORTER_TOO_OLD,
    GLE_FILE_NOT_FOUND,
    GLE_LIBRARY_NOT_FOUND,
    GLE_FILE_READ_ERROR,
    GLE_NOT_GEOS_FILE,
    GLE_NOT_GEOS_EXECUTABLE_FILE,
    GLE_ATTRIBUTE_MISMATCH,
    GLE_MEMORY_ALLOCATION_ERROR,
    GLE_NOT_MULTI_LAUNCHABLE,
    GLE_LIBRARY_PROTOCOL_ERROR,
    GLE_LIBRARY_LOAD_ERROR,
    GLE_DRIVER_INIT_ERROR,
    GLE_LIBRARY_INIT_ERROR,
    GLE_DISK_TOO_FULL,
    GLE_FIELD_DETACHING,
    GLE_INSUFFICIENT_HEAP_SPACE,
    GLE_LAST_GEODE_LOAD_ERROR	/* for iacp.goh... */
} GeodeLoadError;

/***/

extern GeodeHandle			/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal GeodeLoad(const char *name, GeodeAttrs attrMatch, GeodeAttrs attrNoMatch,
			   word priority, dword appInfo, GeodeLoadError *err);

/***/

extern void
    _pascal GeodeAddReference(GeodeHandle gh);


/***/
extern Boolean
    _pascal GeodeRemoveReference(GeodeHandle gh);

/***/
extern GeodeHandle	/*XXX*/
    _pascal GeodeFind(const char *name, word numChars, GeodeAttrs attrMatch,
						GeodeAttrs attrNoMatch);

/***/

extern word 		/*XXX*/
    _pascal GeodeFindResource(FileHandle file, word resNum, word resOffset, 
		      dword *base);

/***/

extern MemHandle        /*XXX*/
    _pascal GeodeSnatchResource(FileHandle file, word resNum, word resOffset);

/***/

extern Boolean 		/*XXX*/
    _pascal GeodeSetGeneralPatchPath();

/***/

extern Boolean 	        /*XXX*/
    _pascal GeodeSetLanguagePatchPath();

/***/

extern Boolean 		/*XXX*/
    _pascal IsMultiLanguageModeOn();

/***/

typedef enum /* word */ {
    GGIT_ATTRIBUTES=0,
    GGIT_TYPE=2,
    GGIT_GEODE_RELEASE=4,
    GGIT_GEODE_PROTOCOL=6,
    GGIT_TOKEN_ID=8,
    GGIT_PERM_NAME_AND_EXT=10,
    GGIT_PERM_NAME_ONLY=12,
#ifdef DO_DBCS
    GGIT_PERM_NAME_AND_EXT_DBCS=14,
    GGIT_PERM_NAME_ONLY_DBCS=16,
    GGIT_GEODE_REF_COUNT=18,
#else
    GGIT_GEODE_REF_COUNT=14,
#endif
} GeodeGetInfoType;

extern word	/*XXX*/
    _pascal GeodeGetInfo(GeodeHandle gh, GeodeGetInfoType info, void *buf);

/***/

extern GeodeHandle	/*XXX*/
    _pascal GeodeGetProcessHandle(void);

/***/

extern GeodeHandle
    _pascal GeodeGetCodeProcessHandle(void);

/***/

extern optr
    _pascal GeodeGetAppObject(GeodeHandle gh);

/***/

extern word	/*XXX*/
    _pascal GeodeGetUIData(GeodeHandle gh);

/***/

extern void	/*XXX*/
    _pascal GeodeSetUIData(GeodeHandle gh, word data);

/***/

extern ThreadHandle	/*XXX*/
    _pascal ProcInfo(GeodeHandle gh);

/***/

extern QueueHandle	/*XXX*/
    _pascal GeodeAllocQueue(void);

/***/

extern void	/*XXX*/
    _pascal GeodeFreeQueue(QueueHandle qh);

/***/

extern word	/*XXX*/
    _pascal GeodeInfoQueue(QueueHandle qh);

/***/

/* 
 * Note: The messageFlags passed to GeodeFlushQueue are of type
 * MessageFlags, defined in object.h. They cannot be so specified
 * in this function declaration because object.h depends on this
 * file, geode.h, and so cannot be included by it.
 */
extern void	/*XXX*/
    _pascal GeodeFlushQueue(QueueHandle source, QueueHandle dest, optr obj,
		    word messageFlags);

/***/

extern word 	/*XXX*/
    _pascal GeodePrivAlloc(GeodeHandle gh, word numWords);

/***/

extern void 	/*XXX*/
    _pascal GeodePrivFree(word offset, word numWords);

/***/

extern void 	/*XXX*/
    _pascal GeodePrivRead(GeodeHandle gh, word offset, word numWords, word *dest);

/***/

/*
 * GeodePrivWrite returns TRUE if the write succeeded and FALSE otherwise.
 */
extern Boolean 	/*XXX*/
    _pascal GeodePrivWrite(GeodeHandle gh, word offset, word numWords, word *src);    

extern EventHandle /*XXX*/
    _pascal QueueGetMessage(QueueHandle qh);

extern void	/*XXX*/
    _pascal QueuePostMessage(QueueHandle qh, EventHandle event, word flags);

extern ReservationHandle
    _pascal GeodeRequestSpace(int amount, GeodeHandle gh);

extern void
    _pascal GeodeReturnSpace(ReservationHandle resv);

/*
 *	Constants for Geodes
 */

/* Sizes */

#define GEODE_NAME_SIZE		8
#define GEODE_NAME_EXT_SIZE	4

/*
 *	Tokens
 */

#define TOKEN_CHARS_LENGTH	4
typedef char TokenChars[TOKEN_CHARS_LENGTH];

/* manufacturer's id in token */

typedef word ManufacturerID;
#define MANUFACTURER_ID_GEOWORKS    	    0
#define MANUFACTURER_ID_APP_LOCAL   	    1
#define MANUFACTURER_ID_PALM_COMPUTING	    2
#define MANUFACTURER_ID_WIZARD	    	    3
#define MANUFACTURER_ID_CREATIVE_LABS	    4
#define MANUFACTURER_ID_DOS_LAUNCHER	    5
#define MANUFACTURER_ID_AMERICA_ONLINE	    6
#define	MANUFACTURER_ID_INTUIT	    	    7
#define MANUFACTURER_ID_SDK		    8
#define MANUFACTURER_ID_SHAREWARE	    9
#define MANUFACTURER_ID_GENERIC             10
#define MANUFACTURER_ID_NOKIA               11
#define MANUFACTURER_ID_SOCKET_16BIT_PORT   12
#define MANUFACTURER_ID_LEGOS               13
#define MANUFACTURER_ID_TLC                 14
#define MANUFACTURER_ID_CENDANT             15
#define MANUFACTURER_ID_NEW_DEAL            16
#define MANUFACTURER_ID_GLOBAL_PC           17
#define MANUFACTURER_ID_PENNY_PRESS         18
#define MANUFACTURER_ID_DESIGNS_IN_LIGHT    99

/*
 * As of 10/29/93, Manufacturer ID's will be assigned automatically by
 * database, in the range indicated by the equates below.
 */

#define MANUFACTURER_ID_DATABASE_FIRST		0x4000
#define MANUFACTURER_ID_DATABASE_LAST		0x7fff

/*
 *  This is here to allow backward compatability.
 */
#define	MANUFACTURER_ID_TBD 			MANUFACTURER_ID_NOKIA

typedef struct {
    TokenChars		GT_chars;
    ManufacturerID	GT_manufID;
} GeodeToken;

typedef struct {
    word		GHV_heapSpace;
} GeodeHeapVars;

/*
 *	Version control
 */

typedef struct {
    word	RN_major;
    word	RN_minor;
    word	RN_change;
    word	RN_engineering;
} ReleaseNumber;

typedef struct {
    word	PN_major;
    word	PN_minor;
} ProtocolNumber;

#ifdef __HIGHC__
pragma Alias(GeodeLoad, "GEODELOAD");
pragma Alias(GeodeAddReference, "GEODEADDREFERENCE");
pragma Alias(GeodeRemoveReference, "GEODEREMOVEREFERENCE");
pragma Alias(GeodeFind, "GEODEFIND");
pragma Alias(GeodeFindResource, "GEODEFINDRESOURCE");
pragma Alias(GeodeGetInfo, "GEODEGETINFO");
pragma Alias(GeodeGetProcessHandle, "GEODEGETPROCESSHANDLE");
pragma Alias(GeodeGetCodeProcessHandle, "GEODEGETCODEPROCESSHANDLE");
pragma Alias(GeodeGetAppObject, "GEODEGETAPPOBJECT");
pragma Alias(GeodeGetUIData, "GEODEGETUIDATA");
pragma Alias(GeodeSetUIData, "GEODESETUIDATA");
pragma Alias(GeodeSetGeneralPatchPath, "GEODESETGENERALPATCHPATH");
pragma Alias(GeodeSetLanguagePatchPath, "GEODESETLANGUAGEPATCHPATH");
pragma Alias(GeodeSnatchResource, "GEODESNATCHRESOURCE");
pragma Alias(ProcInfo, "PROCINFO");
pragma Alias(GeodeAllocQueue, "GEODEALLOCQUEUE");
pragma Alias(GeodeFreeQueue, "GEODEFREEQUEUE");
pragma Alias(GeodeInfoQueue, "GEODEINFOQUEUE");
pragma Alias(GeodeFlushQueue, "GEODEFLUSHQUEUE");
pragma Alias(GeodePrivAlloc, "GEODEPRIVALLOC");
pragma Alias(GeodePrivFree, "GEODEPRIVFREE");
pragma Alias(GeodePrivRead, "GEODEPRIVREAD");
pragma Alias(GeodePrivWrite, "GEODEPRIVWRITE");
pragma Alias(IsMultiLanguageModeOn, "ISMULTILANGUAGEMODEON");
pragma Alias(QueuePostMessage, "QUEUEPOSTMESSAGE");
pragma Alias(QueueGetMessage, "QUEUEGETMESSAGE");
pragma Alias(GeodeRequestSpace, "GEODEREQUESTSPACE");
pragma Alias(GeodeReturnSpace, "GEODERETURNSPACE");
#endif

#endif
