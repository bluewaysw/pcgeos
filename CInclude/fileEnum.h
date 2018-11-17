/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	fileEnum.h
 * AUTHOR:	Tony Requist: February 12, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines structures and routines for FileEnum.
 *
 *	$Id: fileEnum.h,v 1.1 97/04/04 15:58:21 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__FILE_ENUM_H
#define __FILE_ENUM_H

#include <file.h>

/*
 *	Parameters passed to FileEnum()
 */

typedef ByteFlags FileEnumSearchFlags;
#define FESF_DIRS   	    	0x80
#define FESF_NON_GEOS	    	0x40
#define FESF_GEOS_EXECS	    	0x20
#define FESF_GEOS_NON_EXECS 	0x10
#define FESF_REAL_SKIP	    	0x08
#define FESF_CALLBACK	    	0x04
#define FESF_LOCK_CB_DATA   	0x02
#define FESF_LEAVE_HEADER   	0x01

#define FILE_ENUM_ALL_FILE_TYPES	(FESF_NON_GEOS|FESF_GEOS_EXECS \
							|FESF_GEOS_NON_EXECS)

#define FILE_ENUM_ALL_FILE_DIR_TYPES     (FILE_ENUM_ALL_FILE_TYPES|FESF_DIRS)

#define FE_BUFSIZE_UNLIMITED	0xffff      /* Value for FEP_bufSize to place
					     * no limit on the number of files
					     * for which to return data */


typedef enum /* word */ {
    FESRT_COUNT_ONLY,
    FESRT_DOS_INFO,
    FESRT_NAME,
    FESRT_NAME_AND_ATTR
} FileEnumStandardReturnType;

typedef enum /* word */ {
    FESC_WILDCARD
} FileEnumStandardCallback;

/*
 *	Structures returned by FileEnum
 */

typedef struct {
    FileAttrs		DFIS_attributes;
    FileDateAndTime	DFIS_modTimeDate;
    dword		DFIS_fileSize;
    FileLongName	DFIS_name;
    DirPathInfo		DFIS_pathInfo;
} FEDosInfo;

typedef struct {
    FileAttrs	    	FENAA_attr;
    FileLongName    	FENAA_name;
} FENameAndAttr;

typedef struct _FileEnumCallbackData {
    FileExtAttrDesc 	FECD_attrs[1];
} FileEnumCallbackData;

typedef struct _FileEnumParams {
    FileEnumSearchFlags	FEP_searchFlags;
    FileExtAttrDesc 	*FEP_returnAttrs;
    word    	    	FEP_returnSize;
    FileExtAttrDesc 	*FEP_matchAttrs;
    word    	    	FEP_bufSize;
    word    	    	FEP_skipCount;

    PCB(word, 		FEP_callback, (struct _FileEnumParams *params,
					 FileEnumCallbackData *fecd,
					 word frame));

    FileExtAttrDesc 	*FEP_callbackAttrs;
    dword   	    	FEP_cbData1;
    dword   	    	FEP_cbData2;
    word    	    	FEP_headerSize;
} FileEnumParams;

/***/

extern word				/* Sets value for ThreadGetError() */	/*XXX*/
    _pascal FileEnum(FileEnumParams *params, MemHandle *bufCreated, word *numNoFit);

extern void *    /* NULL if attr not found */ /*XXX*/
    _pascal FileEnumLocateAttr(FileEnumCallbackData *fecd,
		       FileExtendedAttribute attr,
		       const char *name);   /* Only if attr is FEA_CUSTOM */

extern Boolean
    _pascal FileEnumWildcard(FileEnumCallbackData *fecd, word frame);

#ifdef __HIGHC__
pragma Alias(FileEnum, "FILEENUM");
pragma Alias(FileEnumLocateAttr, "FILEENUMLOCATEATTR");
pragma Alias(FileEnumWildcard, "FILEENUMWILDCARD");
#endif

#endif
