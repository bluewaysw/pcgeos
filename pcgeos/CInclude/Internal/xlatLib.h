/*****************************************************************************

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Translation Libraries
FILE:		xlatLib.h

AUTHOR:		Jenny Greenwood, 2 January 1992

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	1/92		Initial version

DESCRIPTION:
	Definitions for translation libraries written in C.

	$Id: xlatLib.h,v 1.1 97/04/04 15:53:57 newdeal Exp $

*****************************************************************************/

#ifndef __XLATLIB_H
#define __XLATLIB_H

/*
 * A translation library's TransImport, TransExport, and TransGetFormat
 * routines must return values of type TransError to Impex. If the
 * library is returning TE_CUSTOM, it must also return the handle of
 * a custom error message.
 */

typedef enum  {
    TE_NO_ERROR,	       	/* No error */
    TE_ERROR,	    	    	/* General error */
    TE_INVALID_FORMAT,	    	/* Format is invalid */
    TE_IMPORT_NOT_SUPPORTED,   	/* Format is not supported for export */
    TE_EXPORT_NOT_SUPPORTED,    /* Format is not supported for export */
    TE_IMPORT_ERROR,    	/* General error during import */
    TE_EXPORT_ERROR,    	/* General error during export */
    TE_FILE_ERROR,    	    	/* Generic file error */
    TE_DISK_FULL,    	    	/* The disk is full */
    TE_FILE_OPEN,    	    	/* Error in opening a file */
    TE_FILE_READ,    	    	/* Error in reading from a file */
    TE_FILE_WRITE,    	    	/* Error in writing to a file */
    TE_FILE_TOO_LARGE,	    	/* File is too large to process */
    TE_OUT_OF_MEMORY,	    	/* Insufficient memory for import/export */
    TE_METAFILE_CREATION_ERROR,	/* Error in creating the metafile */
    TE_EXPORT_FILE_EMPTY,	/* File to be exported is empty */
    TE_EXPORT_INVALID_CLIPBOARD_FORMAT, /* App Passed invalid ClipboardFormat*/
    TE_CUSTOM	    	    	/* Custom error message */
} TransError;

/*
 * All Impex routines callable from a translation library written in C
 * return a value of type TransErrorInfo to the library.
 */

typedef struct {
	TransError	transError;

	/* NOTE:
	 *   customMsgHandle will be valid only if transError is TE_CUSTOM.
	 */

	word		customMsgHandle;
} TransErrorInfo;

/*
 * Macros which operate on values of type TransErrorInfo:
 */

#define TRANS_ERROR_IS_NONE(val) ((val).transError == TE_NO_ERROR)
#define TRANS_ERROR_IS_CUSTOM(val) ((val).transError == TE_CUSTOM)
#define GET_TRANS_ERROR(val) ((val).transError)
#define GET_CUSTOM_MSG_HANDLE(val) ((val).customMsgHandle)


/* If a translation library's TransGetFormat routine cannot determine the
   file format, it returns NO_IDEA_FORMAT to Impex. */

#define NO_IDEA_FORMAT   -1

#endif





