
/*******************************************************************************

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ssmeta.def

AUTHOR:		Cheng, 8/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial revision

DESCRIPTION:
	Definitions for the Spreadsheet Meta library. This library manages
	the meta file for the spreadsheet.

	$Id: ssmeta.h,v 1.1 97/04/04 15:58:50 newdeal Exp $

*******************************************************************************/

#ifndef __SSMETA_H
#define __SSMETA_H

/*******************************************************************************

    SSMETA DATA ARRAY STRUCTURES

    Use by the spreadsheet's cut/copy/paste code as well as for the spreadsheet
    translation library.

    NAMES OF THINGS:

	The clipboard transfer item header will have a handle to a SSMETA
	HEADER BLOCK.

	The ssmeta header block is a VM blk containing the size of the scrap
	(number of rows and columns) and five SSMETA DATA ARRAY RECORDS.
	
	Each ssmeta data typedef ByteWordFlags array;

	One data array is used to store the cell data, one for the styles, one
	for the formats, and another for the names. The fifth data array is
	for use by the database. Any data array can be empty.

	A data array is an array of SSMETA ENTRIES.

	Each ssmeta entry will have an ENTRY HEADER which is followed by the
	ENTRY DATA. The entry header will contain a field for a token, and
	fields for the coordinate (row, column) that the cell data processing
	code needs. Entry tokens are optional. You may use them if you XXXX
	to use them to search for entries.

    NOTES:
	The VM file handle is stored in the SSMetaHeader and each of the
	SSMetaDataArrayRecords. This duplication is for convenience - it
	lessens the amount of separate data that needs to be passed around.

*******************************************************************************/

typedef ByteEnum DataArraySpecifier;
#define		DAS_CELL	0
#define		DAS_STYLE	1
#define		DAS_FORMAT	2
#define		DAS_NAME	3
#define		DAS_FIELD	4

typedef ByteEnum SSMetaAddEntryFlags;
#define		SSMAEF_ADD_IN_TOKEN_ORDER	0
#define		SSMAEF_ADD_IN_ROW_ORDER		1
#define		SSMETA_ADD_TO_END		2
#define		SSMAEF_ENTRY_POS_PASSED		3

/*
 * SSMetaDataArrayRecord:
 * used to track a data array
 */
typedef struct {
    word	SSMDAR_signature;
    word	SSMDAR_numEntries;	/* num entries in the data array */
    word	SSMDAR_dataArrayLinkOffset;
} SSMetaDataArrayRecord;

/*
 *    	SSMetaHeaderBlock;
 */
typedef	struct {
    VMChainTree			SSMHB_vmChainTree;
    dword			SSMHB_cellLink;
    dword			SSMHB_styleLink;
    dword			SSMHB_formatLink;
    dword			SSMHB_nameLink;
    dword			SSMHB_fieldLink;
    SSMetaDataArrayRecord	SSMHB_cellData;
    SSMetaDataArrayRecord	SSMHB_styleData;
    SSMetaDataArrayRecord	SSMHB_formatData;
    SSMetaDataArrayRecord	SSMHB_nameData;
    SSMetaDataArrayRecord	SSMHB_fieldData;
    word			SSMHB_scrapRows;
    word			SSMHB_scrapCols;
} SSMetaHeaderBlock;

/*
 * SSMetaEntry
 */
typedef struct {
    word	SSME_signature;		/* sig for error checking */
    word	SSME_entryDataSize;	/* size of entry data */
    word	SSME_token;		/* token (if there is one) */
    word	SSME_coordRow;
    word	SSME_coordCol;
    word	SSME_newToken;		/* for use when pasting */
} SSMetaEntry;

typedef struct {
    dword	SSMED_ptr;
    word	SSMED_size;
} SSMetaEntryDescriptor;

/*
 * SSMetaStruc:
 */
typedef struct {
    /*
     *    user	library; usually passes info in these fields:
     */
    ClipboardItemFlags	SSMDAS_transferItemFlags;
    DataArraySpecifier	SSMDAS_dataArraySpecifier;
    word	SSMDAS_row;
    word	SSMDAS_col;
    word	SSMDAS_token;
    word	SSMDAS_handle;	 	/* for routines that need it, */
					/* handle to a mem block */
    /*
     * Library user gets info back in these fields:
     */
    word	SSMDAS_newEntrySeg;
    word	SSMDAS_vmFileHan;	/* transfer VM file han */
    word	SSMDAS_hdrBlkVMHan;	/* SSMetaHeaderBlock VM blk han */

    /*
     * Fields containing info about the scrap (initialized by
     * SSMetaInitForPaste)
     * Once initialized, library users should not change these.
     */
    word	SSMDAS_tferItemHdrVMHan;/* TransferItemHeader VM blk han */
    word	SSMDAS_tferItemMemHan;	/* TransferItemHeader mem han */
    word	SSMDAS_hdrBlkMemHan;	/* SSMetaHeaderBlock mem han */
    dword	SSMDAS_sourceID;	/* sourceID of transfer item */
    word	SSMDAS_scrapRows;	/* number of rows */
    word	SSMDAS_scrapCols;	/* number of columns */

    /*
     * fields for library's own use - don't touch these
     */
    word	SSMDAS_signature;	/* for error checking */
    dword	SSMDAS_dataArrayRecordPtr; 
    word	SSMDAS_dataArrayBlkHan;	/* huge array handle for data array */

    /*
    * SSMDAS_dataArrayEntryTable - tracks the position of the last accessed
    * entry in each of the data arrays.
    */

    SSMetaEntryDescriptor	SSMDAS_cellEntry;
    SSMetaEntryDescriptor	SSMDAS_styleEntry;
    SSMetaEntryDescriptor	SSMDAS_formatEntry;
    SSMetaEntryDescriptor	SSMDAS_nameEntry;
    SSMetaEntryDescriptor	SSMDAS_fieldEntry;

    dword	SSMDAS_entryDataAddr;	/* user passes this to library */
    word	SSMDAS_entryDataSize;	/* user passes this to library */
    word	SSMDAS_entryMemHan;
    byte	SSMDAS_flag;		/* user passes this to library */
    dword	SSMDAS_entryPos;	/* tracks array traversal */

    /* 
     * used for binary search in AddEntryBinarySearch, touch these not
     */
    word    	SSMDAS_startIndex;
    word	SSMDAS_endIndex;
    word	SSMDAS_checkIndex;
    byte    	SSMDAS_compFlag;	/* SSMetaBinSearchConditionType */

} SSMetaStruc;

/*
 * initialization routines
 */
extern void
		_pascal SSMetaInitForStorage(SSMetaStruc *ssmStruc,
		VMFileHandle vmFileHan,
		dword sourceID);				/* XXX */
extern void
		_pascal SSMetaInitForRetrieval(SSMetaStruc *ssmStruc,
		VMFileHandle vmFileHan,
		word ssmHdr);					/* XXX */
extern void
		_pascal SSMetaInitForCutCopy(SSMetaStruc *ssmStruc,
		ClipboardItemFlags flags,
		dword sourceID);				/* XXX */
extern void
		_pascal SSMetaDoneWithCutCopy(SSMetaStruc *ssmStruc);	/* XXX */
extern void
		_pascal SSMetaDoneWithCutCopyNoRegister(SSMetaStruc *ssmStruc);

extern Boolean
		_pascal SSMetaInitForPaste(SSMetaStruc *ssmStruc,
		ClipboardItemFlags flags);			/* XXX */
extern void
		_pascal SSMetaDoneWithPaste(SSMetaStruc *ssmStruc);		/* XXX */
/*
 * storage routines
 */
extern void _pascal SSMetaSetScrapSize(SSMetaStruc *ssmStruc,
		word numRows,
		word numCols); /* XXX 1/23/05 jfh - rows & cols was backwards */
extern Boolean
		_pascal SSMetaDataArrayLocateOrAddEntry(SSMetaStruc *ssmStruc,
		word token,
		word entryDataSize,
		void *entryData);				/* XXX */
extern void
		_pascal SSMetaDataArrayAddEntry(SSMetaStruc *ssmStruc,
		SSMetaAddEntryFlags flag,
		word entryDataSize,
		void *entryData);				/* XXX */
/*
 * retrieval routines
 */
extern Boolean
		_pascal SSMetaSeeIfScrapPresent(ClipboardItemFlags flags); /* XXX */
extern void
		_pascal SSMetaGetScrapSize(SSMetaStruc *ssmStruc);	/* XXX */
extern word
		_pascal SSMetaDataArrayGetNumEntries(SSMetaStruc *ssmStruc); /* XXX */

extern void	_pascal SSMetaDataArrayResetEntryPointer(SSMetaStruc *ssmStruc);

extern SSMetaEntry
		*_pascal SSMetaDataArrayGetFirstEntry(SSMetaStruc *ssmStruc); /* XXX */
extern SSMetaEntry
		*_pascal SSMetaDataArrayGetNextEntry(SSMetaStruc *ssmStruc);

extern SSMetaEntry
		*_pascal SSMetaDataArrayGetEntryByToken(SSMetaStruc *ssmStruc,
		word token);					/* XXX */
extern SSMetaEntry
		*_pascal SSMetaDataArrayGetEntryByCoord(SSMetaStruc *ssmStruc);
extern SSMetaEntry
		*_pascal SSMetaDataArrayGetNthEntry(SSMetaStruc *ssmStruc,
		word N);					/* XXX */
extern void _pascal SSMetaDataArrayUnlock(SSMetaStruc *ssmStruc);	/* XXX */
extern word _pascal SSMetaGetNumberOfDataRecords(SSMetaStruc *ssmStruc);	/* XXX */
extern void _pascal SSMetaResetForDataRecords(SSMetaStruc *ssmStruc); /* XXX */
extern char *_pascal SSMetaFieldNameLock(SSMetaStruc *ssmStruc,
					 MemHandle *mHandle,
					 word *dataLength);	/* XXX */
extern char *_pascal SSMetaDataRecordFieldLock(SSMetaStruc *ssmStruc,
					 MemHandle *mHandle,
					 word *dataLength);	/* XXX */
extern void _pascal SSMetaFieldNameUnlock(SSMetaStruc *ssmStruc,
					  word mHandle);	/* XXX */
extern void _pascal SSMetaDataRecordFieldUnlock(SSMetaStruc *ssmStruc,
						word mHandle);	/* XXX */
extern char *_pascal 		SSMetaFormatCellText(SSMetaStruc *ssmStruc, 
					 word *mHandle,
					 word *dataLength);	/* XXX 1/25/05 jfh - This prototype is incomplete.
													Needs pointer to an entry structure &
													size.  Won't fix since not needed in GOC */
#ifdef __HIGHC__

pragma Alias(SSMetaInitForStorage, "SSMETAINITFORSTORAGE");
pragma Alias(SSMetaInitForRetrieval, "SSMETAINITFORRETRIEVAL");
pragma Alias(SSMetaInitForCutCopy, "SSMETAINITFORCUTCOPY");
pragma Alias(SSMetaDoneWithCutCopy, "SSMETADONEWITHCUTCOPY");
pragma Alias(SSMetaDoneWithCutCopyNoRegister,"SSMETADONEWITHCUTCOPYNOREGISTER");
pragma Alias(SSMetaInitForPaste, "SSMETAINITFORPASTE");
pragma Alias(SSMetaDoneWithPaste, "SSMETADONEWITHPASTE");
pragma Alias(SSMetaSetScrapSize, "SSMETASETSCRAPSIZE");
pragma Alias(SSMetaDataArrayLocateOrAddEntry, "SSMETADATAARRAYLOCATEORADDENTRY");
pragma Alias(SSMetaDataArrayAddEntry, "SSMETADATAARRAYADDENTRY");
pragma Alias(SSMetaSeeIfScrapPresent, "SSMETASEEIFSCRAPPRESENT");
pragma Alias(SSMetaGetScrapSize, "SSMETAGETSCRAPSIZE");
pragma Alias(SSMetaDataArrayGetNumEntries, "SSMETADATAARRAYGETNUMENTRIES");
pragma Alias(SSMetaDataArrayResetEntryPointer, "SSMETADATAARRAYRESETENTRYPOINTER");
pragma Alias(SSMetaDataArrayGetFirstEntry, "SSMETADATAARRAYGETFIRSTENTRY");
pragma Alias(SSMetaDataArrayGetNextEntry, "SSMETADATAARRAYGETNEXTENTRY");
pragma Alias(SSMetaDataArrayGetEntryByToken, "SSMETADATAARRAYGETENTRYBYTOKEN");
pragma Alias(SSMetaDataArrayGetEntryByCoord, "SSMETADATAARRAYGETENTRYBYCOORD");
pragma Alias(SSMetaDataArrayGetNthEntry, "SSMETADATAARRAYGETNTHENTRY");
pragma Alias(SSMetaDataArrayUnlock, "SSMETADATAARRAYUNLOCK");

pragma Alias(SSMetaGetNumberOfDataRecords, "SSMETAGETNUMBEROFDATARECORDS");
pragma Alias(SSMetaResetForDataRecords, "SSMETARESETFORDATARECORDS");
pragma Alias(SSMetaFieldNameLock, "SSMETAFIELDNAMELOCK");
pragma Alias(SSMetaDataRecordFieldLock, "SSMETADATARECORDFIELDLOCK");
pragma Alias(SSMetaFieldNameUnlock, "SSMETAFIELDNAMEUNLOCK");
pragma Alias(SSMetaDataRecordFieldUnlock, "SSMETADATARECORDFIELDUNLOCK");
pragma Alias(SSMetaFormatCellText, "SSMETAFORMATCELLTEXT");

#endif
#endif
