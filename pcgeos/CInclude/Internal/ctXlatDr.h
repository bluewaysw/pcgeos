/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 * PROJECT:	  PC GEOS
 * MODULE:	  Desktop Connectivity
 * FILE:	  ctXlatDr.h
 *
 * AUTHOR:  	  Thomas E Lester: May 30, 1995
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	lester	5/30/95   	Initial version
 *
 * DESCRIPTION:
 *	Interface definition for Connect Translation drivers.
 *
 *
 * 	$Id: ctXlatDr.h,v 1.1 97/04/04 15:53:45 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _CTXLATDR_H_
#define _CTXLATDR_H_

#include <driver.h>

/*
 * Protocol number for this interface. 
 */
#define CTLATE_PROTO_MAJOR	(DRIVER_PROTO_MAJOR+1)
#define CTLATE_PROTO_MINOR	(DRIVER_PROTO_MAJOR+0)

/*----------------------------------------------------------------------------
 *		Structures and Constants
 *--------------------------------------------------------------------------*/

typedef enum {
CTLDE_NO_ERROR,					
CTLDE_ERROR,					
CTLDE_TRANSLATION_NOT_SUPPORTED,			
CTLDE_INVALID_FORMAT,
CTLDE_SOURCE_FILE_EMPTY,
CTLDE_FILE_OPEN,				
CTLDE_FILE_READ,					
CTLDE_FILE_WRITE,				
CTLDE_FILE_CREATE,				
CTLDE_FILE_TOO_LARGE,				
CTLDE_DISK_FULL,					
CTLDE_OUT_OF_MEMORY,				
CTLDE_CANCELED,

} ConnectTranslateDriverError;


/*
 * Maximum length of a format name string, including null.
 * The format name string is always SBCS so its length = its size.
 */
#define CTLD_FORMAT_NAME_SIZE		16

/*
 * Structure to pass with DR_CTLD_TRANSLATE.
 */
typedef struct {
    DiskHandle	CTLDA_sourceDiskHandle;
    char       	CTLDA_sourceFilePath[PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE];

    DiskHandle	CTLDA_destDiskHandle;
    char       	CTLDA_destFilePath[PATH_BUFFER_SIZE+FILE_LONGNAME_BUFFER_SIZE];

    char	CTLDA_sourceFormat[CTLD_FORMAT_NAME_SIZE];
    char 	CTLDA_destFormat[CTLD_FORMAT_NAME_SIZE];

} ConnectTranslateDriverArgs;			


/*----------------------------------------------------------------------------
 *		Driver Function Calls
 *--------------------------------------------------------------------------*/

/* enum ConnectTranslateDriverFunction */
typedef enum {
    DR_CTLD_TRANSLATE = 8,
    DR_CTLD_CANCEL = 10,

} ConnectTranslateDriverFunction;

#endif /* _CTXLATDR_H_ */
