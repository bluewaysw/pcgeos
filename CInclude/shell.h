/***********************************************************************
 *
 *	Copyright (c) 1997 New Deal, Inc. -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * MODULE:	Shell Library
 * FILE:	shell.h
 *
 * AUTHOR:	Martin Turon, Dec  17, 1997
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	martin	12/17/1997	Initial version
 *
 * DESCRIPTION:
 *	This file defines structures and routines 
 *	for the Shell Library.
 *
 * RCS STAMP:		
 *	$Id$
 *
 ***********************************************************************/

#ifndef _SHELL_H_
#define _SHELL_H_

/*-------------------------------------------------------*/
/* 	Types, Constants & Structures			 */
/*-------------------------------------------------------*/

/*-------------------------------------------------------*/
/*	SHELL BUFFER STRUCTURES and CONSTANTS		 */
/*-------------------------------------------------------*/
#define 	SHELL_BUFFER_MAX_LINE_LENGTH	500

/*-------------------------------------------------------*
 *  The ShellBuffer is essentially a memory block        *
 *   with a ShellBuffer structure as its header.         *
 *   The portion of the file that is desired to be read  *
 *   is copied into the SB_buffer offset.                *
 *   Future expansions: add linkage for multiple blocks. *
 *-------------------------------------------------------*/
typedef struct {
	FileHandle		 SB_fileHandle;
	MemHandle  	         SB_bufferHandle;  /* MemHandle.ShellBuffer */
	char _near		*SB_offset;
	char _near		*SB_nextLine;
	char _near		*SB_bufferEnd;
  /*
 SB_buffer		char	SHELL_BUFFER_MAX_LINE_LENGTH dup (??)
 */
} ShellBuffer;

/*-------------------------------------------------------*/
/* 	Structures for dealing with Error Dialogs	 */
/*-------------------------------------------------------*/
typedef	enum ByteEnum {
	REEST_NONE,
	REEST_FPTR,
	REEST_HPTR,
	REEST_OPTR
} ReportErrorExtraStringType;

typedef ByteFlags ReportErrorFlags; 
#define REF_GENERIC_ERROR_AVAILABLE	0x01

typedef WordFlags ErrorTableEntryFlags; 
#define ETF_SHOW_EXTRA_STRING		0x0001
#define ETF_NO_CANCEL			0x0002
#define ETF_NOTICE			0x0004
#define ETF_PROMPT			0x0008
#define ETF_SYS_MODAL			0x0016

typedef struct {
	word 			ETE_error;	
	optr  		        ETE_string;    /* optr.char */	
	ErrorTableEntryFlags	ETE_flags;	
} ErrorTableEntry;

#define ERROR_TABLE_LAST_ENTRY	 -1
#define REPORT_GENERIC_NO_STRING (REF_GENERIC_ERROR_AVAILABLE << 8)+REEST_NONE
#define REPORT_GENERIC_FPTR 	 (REF_GENERIC_ERROR_AVAILABLE << 8)+REEST_FPTR
#define REPORT_GENERIC_HPTR 	 (REF_GENERIC_ERROR_AVAILABLE << 8)+REEST_HPTR
#define REPORT_GENERIC_OPTR 	 (REF_GENERIC_ERROR_AVAILABLE << 8)+REEST_OPTR

/*-------------------------------------------------------*/
/* 	Structures for dealing with paths	         */
/*-------------------------------------------------------*/
typedef struct {
	MemHandle        PB_handle;    // hptr.PathBuffer */	
	PathName         PB_path;
} PathBuffer;

typedef struct {
	MemHandle        PB2_handle;   /* hptr.PathBuffer2 */
	PathName         PB2_path1;
	PathName         PB2_path2;
} PathBuffer2;

/*-------------------------------------------------------*/
/* 	Structures for dealing with tokens and icons     */
/*-------------------------------------------------------*/
typedef struct {
	TokenChars     TM_token;	
	optr           TM_moniker;	/* pointer to MonikerList */
} TokenMoniker;

#define TOKEN_MONIKER_END_OF_LIST	-1

typedef WordFlags ShellDefineTokenFlags;
#define SDTF_FORCE_OVERWRITE    0x0001	/* define every token in list,
					   even if they already exist */
#define	SDTF_CALLBACK_DEFINED   0x0002	/* call a callback routine for
					   each token defined */
#define	SDTF_CALLBACK_PROCESSED 0x0004 	/* call a callback routine for
					   each token processed */

typedef	struct {
	word             ILTH_tableSize;       /* size of icon lookup table */
  /*    GeodeToken label ILTH_table;           /* start of table */
} IconLookupTableHeader;


/*-------------------------------------------------------*/
/* 	Structures for dealing with DirInfo files	 */
/*-------------------------------------------------------*/
/*
 * The DIRINFO.VM file exists in every directory which needs to
 * remember something special about itself.  It was created as a place
 * to store position information of icons, but other information could
 * be added easily.
 * - Add information about the folder 
 *	(color, placement, type) in DirInfoFileHeader 
 * - Add information about individual files in DirInfoFileEntry
 *
 * Note: Since DIRINFO.VM could potentially exist in EVERY directy,
 * 	avoid using/creating it if at all possible.
 *	If no DIRINFO.VM file is found, the Desktop will assume DOS
 *	order, and none will be created. 
 *
 * What follows are the structures that are contained in the map block
 * of the DIRINFO.VM file.  It consists of a header containing window
 * (folder) specific information, and a pointer to a chunk array of
 * file (icon) specific information. 
 *-------------------------------------------------------*/

#define DIRINFO_PROTOCOL_NUM  4
	/* protocol number of dirinfo file  */
        /* major revision number of library */
        /* should correspond: N.0.32.238    */
	/* updated to 4 to add DIFH_displayOptions - 12/24/98 */

typedef struct {
	LMemBlockHeader         DIFH_header;		
	byte                    DIFH_protocol;
	                               /* protocol number of the dirinfo file
  					* If any changes are made to the
					* format of the dirinfo file,
					* this number must be updated,
					* so old versions will be delt
					* with correctly.
					*/
	byte                    DIFH_posArray;	/* lptr to array of info */ 

	SpecWinSizePair         DIFH_winSize;		
	SpecWinSizePair         DIFH_winPosition;	
	dword			DIFH_displayOptions;
} DirInfoFileHeader;

typedef ByteFlags DirInfoFileEntryFlags;
#define  DIFEF_PERCENTAGE   0x01



typedef	struct {
	Point                 DIFE_position; /* top left corner of bounding */
					     /* box of this icon            */
	DirInfoFileEntryFlags DIFE_flags;	
	FileID                DIFE_fileID;   /* Identifier for this file,   */
	                                     /* unique within the directory */

} DirInfoFileEntry;




/*-------------------------------------------------------*/
/*		SHELL ROUTINES                           */
/*-------------------------------------------------------*/

/*-------------------------------------------------------*/
/*		File Module Routines                     */
/*-------------------------------------------------------*/
/*
global	ShellSetObjectType:far
global	ShellGetObjectType:far
global	ShellSetToken:far
global	ShellGetToken:far
global 	ShellSetFileHeaderFlags:far
global	ShellPushToRoot:far
global	ShellGetFileHeaderFlags:far
global	ShellDropFinalComponent:far
*/

/*-------------------------------------------------------*/
/*		Util Module Routines                     */
/*-------------------------------------------------------*/
/*
global	ShellBuildFullFilename:far
global	ShellCombineFileAndPath:far
global	FileComparePathsEvalLinks:far
global 	ShellAllocPathBuffer:far
global	ShellAlloc2PathBuffers:far
global  ShellFreePathBuffer:far
*/

/*-------------------------------------------------------*/
/*		Icon Module Routines                     */
/*-------------------------------------------------------*/
/*
global	ShellLoadMoniker:far
global	ShellDefineTokens:far
*/

/*-------------------------------------------------------*/
/*		DirInfo Module Routines                  */
/*-------------------------------------------------------*/
/*
global	ShellCreateDirInfo:far
global	ShellOpenDirInfo:far
global	ShellOpenDirInfoRW:far
global	ShellCloseDirInfo:far
global	ShellSearchDirInfo:far
global	ShellSetPosition:far
global	ShellGetPosition:far
global	ECCheckDirInfo:far
*/

/*-------------------------------------------------------*/
/*		Dialog Module Routines                   */
/*-------------------------------------------------------*/
/*
global	ShellReportError:far
*/


extern void  _pascal  
ShellReportFileError(FileError error, TCHAR *filename);


/*-------------------------------------------------------*/
/*		FQT Module Routines (FileQuickTransfer)  */
/*-------------------------------------------------------*/
/*
global	ShellGetTrueDiskHandleFromFQT:far
global	ShellGetRemoteFlagFromFQT:far
*/

/*-------------------------------------------------------*/
/*		HugeFile Module Routines                 */
/*-------------------------------------------------------*/
/*
global	ShellBufferOpen:far
global	ShellBufferClose:far
global	ShellBufferReadLine:far
global	ShellBufferReadNLines:far
global	ShellBufferLock:far
global	ShellBufferUnlock:far
*/

#endif



