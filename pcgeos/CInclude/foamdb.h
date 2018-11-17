/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	Foam library
 * FILE:	foamdb.h
 *
 *
 * REVISION HISTORY:
 *	
 *	Name	Date		Description
 *	----	----		-----------
 *	atw	11/ 2/94		Initial revision
 *
 *
 * DESCRIPTION:
 *	Contains descriptions of external routines for the Foam DB.
 *	The FoamDB is a general-purpose database engine, upon which
 * 	other databases (such as the Contact database) are built.
 *
 *	Overview:
 *
 *	There are three ways to access record data:
 *
 *	1) FoamDBCreateEmptyRecord, which creates an empty record
 *	2) FoamDBGetRecordFromID, which, given an ID, finds the associated
 *	    record in the database
 *	3) FoamDBGetVisibleRecord, which returns the Nth visible record
 *	    in the database
 *
 *	These routines create in-memory representations of record data,
 *	which can then be passed to the other FoamDB routines. These
 *	in-memory representations should never be freed, but should instead
 *	be destroyed using FoamDBDiscardRecord, FoamDBDeleteRecord, or
 *	FoamDBSaveRecord, as appropriate.
 *
 *	Operations on database records are never actually performed on the
 * 	database file itself, and no changes are stored to the file
 *	until/unless FoamDBSaveRecord is called.
 *
 *	File format:
 *
 *	Each record consists of a RecordHeader structure, followed by an
 *	array of contiguous variable-length fields. Each field consists of a
 *	FieldHeader structure, followed by any data for the field (the data
 *	is not null terminated). The records are stored in two huge arrays, one
 *	for visible records, and one for invisible records (records with the
 *	FDBRF_INVISIBLE flag set). The huge arrays are sorted according to
 *	the data in the records.
 *
 *	The field names are stored in an element array which lies in an lmem
 *	block in the DB file. Each field contains a token which refers to an
 *	item in this field name element array.
 *
 *	Each record has a unique identifier in it, and each field in the
 *	record will have an ID that is unique among all fields in that
 *	record.
 *	
 *	$Id: foamdb.h,v 1.1 97/04/04 15:56:22 newdeal Exp $
 *
 ***********************************************************************/

#ifndef __FOAMDB_H
#define	__FOAMDB_H

@deflib foamdb

typedef dword RecordID;
typedef word FieldID;

/*
 * Notification information sent out when changes occur in the database
 */

typedef enum {
    FDBAT_ENTRY_ADDED,
    /* Indicates that a record was added to the database */
    
    FDBAT_ENTRY_CHANGED,
    /* Indicates that a record changed */
    
    FDBAT_ENTRY_DELETED,
    /* Indicates that a record was deleted */
    
    FDBAT_DB_CHANGED,
    /*
     * Indicates that there were large-scale changes to the database (restored
     * from backup, or whatever), so the database may need to be rescanned
     */
    
    FDBAT_DB_CLOSED
    /*
     * Indicates that the database was closed
     */
	
} FoamDBActionType;

typedef struct {
    /*
     * This is the information sent out with the GWNT_FOAM_DB_CHANGE
     * notification
     */

    VMFileHandle    FDBCN_fileHan;
    /* The handle of the database that has been changed */

    FoamDBActionType	FDBCN_action;
    /* The type of modification that just occurred */

/*
 *	The following fields are only filled in if FDBCN_action is
 *	FDBAT_ENTRY_DELETED, FDBAT_ENTRY_CHANGED, or FDBAT_ENTRY_ADDED
 */
    
    dword   FDBCN_entry;
#define INVISIBLE_RECORD    (-1)	
    /*
     * The record number that was just modified/deleted/added (this is an index
     * into the visible array, or INVISIBLE_RECORD if the item was invisible)
     */

    RecordID	FDBCN_id;
    /* The ID of the record that was just added/modified/deleted */
    
} FoamDBChangeNotification;

typedef WordFlags FoamDBFlags;
/*
 * Data stored in the map block for the database.
 */
typedef struct {
    RecordID   FDBM_recordID;
    /* The ID of the next record that will be allocated */
    
    VMBlockHandle   FDBM_fieldNameElementArray;
    /* The VM handle of the block containing the element array with the field
     * names */

    VMBlockHandle   FDBM_mainArray;
    VMBlockHandle   FDBM_secretArray;
    /* The handles of the huge arrays that contain visible and invisible
     * records */

    FoamDBFlags	    FDBM_flags;
    /* Internal flags for the map block */

    word    	    FDBM_reserved;
    /* Reserved for future use */
    
} FoamDBMap;

typedef ByteFlags FoamDBRecordFlags;
#define FDBRF_INVISIBLE	0x80
#define FDBRF_TEMPORARILY_VISIBLE   0x40
#define FDBRF_NOT_YET_SAVED   0x20
/*
 * The structure at the start of each record in the database
 */
typedef struct {
    RecordID   RH_id;
    /* The unique ID of this record */

    FieldID    RH_fieldID;
    /* The ID that will be assigned to the next field that is created in this
     * record */

    word    RH_fieldCount;
    /* The # fields in this record */

    FoamDBRecordFlags	RH_flags;
    /* Flags for the record */

} RecordHeader;


/*
 * The structure at the start of each field in the database
 */
typedef	struct {
    FieldID	FH_id;
    /* The ID for this field */

    word    	FH_nameToken;
    /* The token for the field name */

    word    	FH_size;
    /* The # bytes in the field, not counting the FieldHeader (0 if no data) */

    byte    	FH_type;
    /* The type of the field, used to insert the field in the correct place in
     * the record */  
} FieldHeader;



extern VMFileHandle 
    _pascal FoamDBOpen(char *filename, word mapBlockSize, word majorProtocol, word minorProtocol);
/*
 * Opens an existing database file, or creates a new one if it does not
 * currently exist. Returns the handle of the database file, or 0 if the
 * file could not be opened. ThreadGetError() can be called to return the
 * error type, which is the error returned from VMOpen, or -1 if there was
 * a protocol mismatch.
 *
 * mapBlockSize is used to specify the size of the map block for the database.
 * The default (minimum) size is "sizeof(FoamDBMap)", but more space can
 * be allocated if the application needs to store extra data in the map block.
 *
 * When creating a new file, the new file will be assigned the protocol number
 * passed in majorProtocol and minorProtocol. When opening an existing file,
 * the protocol number of the file is compared against the protocol number
 * passed in majorProtocol and minorProtocol, and if they do not match, an
 * error of -1 is returned.
 */



extern word 
    _pascal FoamDBClose(VMFileHandle file);
/*
 * Closes the file (same as VMClose)
 */



extern MemHandle    
    _pascal FoamDBCreateEmptyRecord(VMFileHandle file);
/*
 * Creates a new record in the database, gives it a unique ID, and returns
 * the handle of the record data. This record will contain no fields/data.
 * This record does not get saved to the database unless FoamDBSaveRecord()
 * is called. Clients should never call MemFree() on records, but should call
 * FoamDBDiscardRecord() or FoamDBSaveRecord() to discard any record changes
 * or commit them to the database.
 */



extern MemHandle
    _pascal FoamDBDuplicateRecord(VMFileHandle file, MemHandle record);
/*
 * Duplicates an existing record, assigns a new ID to it, and returns the
 * handle of the duplicate.
 * As with FoamDBCreateEmptyRecord, the record must eventually be saved or
 * destroyed by calling FoamDBDiscardRecord() or FoamDBSaveRecord().
 */



extern RecordID
    _pascal FoamDBGetRecordID(MemHandle record);
/*
 * Given a record handle, returns the RH_id field from the record
 */

extern FieldID	
    _pascal FoamDBAddFieldToRecord(VMFileHandle file, MemHandle record, char *fieldName, word fieldType);
/*
 * Adds a field to the passed record, and gives it the specified name. A unique
 * FieldID is assigned to the new field, and returned to the caller.
 *
 * The "fieldType" is used by the database to determine the sort order of the
 * records (i.e. a field of type "3" will be inserted after all the existing
 * fields of type "3", but before the fields of type "4"). The Contdb library
 * defines what each field type is for contact databases.
 */



extern void 
    _pascal FoamDBDeleteFieldFromRecord(VMFileHandle file, MemHandle record, FieldID id);
/*
 * Deletes a field from the record - FieldID is the ID of the field as returned
 * from FoamDBAddFieldToRecord().
 */



extern void 
    _pascal FoamDBSetFieldName(VMFileHandle file, MemHandle record, FieldID id, char *name);
/*
 * Changes the name of the specified field. "name" is a null-terminated string
 */



extern void 
    _pascal FoamDBSetFieldData(VMFileHandle file, MemHandle record, FieldID id, char *data, word dataSize);
/*
 * Stores data in the specified field.
 *
 * When storing ASCII data (strings), the strings should *not* be null
 * terminated. For example, if you want to store the string "ABCD", then
 * pass a pointer to the string, and dataSize=4.
 */



extern Boolean 
    _pascal FoamDBGetFieldName(VMFileHandle file, MemHandle record, FieldID id, TCHAR *dest, word maxBytesToGet);
/*
 * Copies the null-terminated name of the specified field into the passed
 * buffer.
 */


extern Boolean
    _pascal FoamDBGetFieldType(VMFileHandle file, MemHandle record, FieldID id, byte *type);
/*
 * Gets the type of the specified field - returns non-zero if the field did not
 * exist.
 */

extern word 
    _pascal FoamDBGetFieldData(VMFileHandle file, MemHandle record, FieldID id, char *dest, word maxBytesToGet);
/*
 * Gets the data for the passed field, and returns the number of bytes of data
 * associated with that field.
 *
 * Remember that the standard (most efficient) way to store string data is
 * *without* a null terminator, so callers will need to use the returned
 * data size.
 */



extern Boolean	
    _pascal FoamDBFieldEnum(MemHandle record, void *enumData,
			    PCB(Boolean, callback, /* TRUE to stop enum */
				(FieldHeader *field, void *enumData)));
/*
 * Calls a callback routine for each field in a record. The callback routine
 * can return non-zero to stop the enumeration. enumData is a pointer to
 * data that you can pass to the callback routine, and that the callback
 * routine can modify.
 *
 * Declaration of callback routine:
 *
 * Boolean _pascal CallBackRoutine(FieldHeader *field, void *enumData);
 */

extern Boolean
    _pascal FoamDBLockedRecordEnum(RecordHeader *record, void *enumData,
				 PCB(Boolean, callback, /* TRUE to stop enum */
				       (FieldHeader *field, void *enumData)));
/*
 * Calls a callback routine for each field in a locked down record. The
 * callback routine can return non-zero to stop the enumeration. enumData is
 * a pointer to data that you can pass to the callback routine, and that
 * the callback routine can modify.
 *
 * Declaration of callback routine:
 *
 * Boolean _pascal CallBackRoutine(FieldHeader *field, void *enumData);
 */

extern dword
    _pascal FoamDBSaveRecord(VMFileHandle file, MemHandle record,
			       PCB(sword, callback,
				   (RecordHeader *record1,
				    RecordHeader *record2)));
/*
 * Saves a record in the database file, and frees up the passed memory
 * block containing the record data. The callback routine determines where
 * in the database the record should be stored. The Contdb library provides
 * a front-end to this routine, which should be used when saving records
 * to a contact database.
 *
 * Declaration of callback routine:
 *
 * sword _pascal CallBackRoutine(RecordHeader *record1, RecordHeader *record2)
 *
 * The callback routine should return -1 if record1 should come before record2,
 * or +1 if record1 should come after record2 in the database
 */



extern void   
    _pascal FoamDBDiscardRecord(VMFileHandle file, MemHandle record);
/*
 * Discards any changes to the passed record, and frees up the record
 * data stored in the passed handle, but does nothing to the data stored
 * in the database file.
 */



extern Boolean	/* XXX */
    _pascal FoamDBDeleteRecord(VMFileHandle file, MemHandle record);
/*
 * Frees up the passed record data, and, if the record exists in the
 * database, deletes it from the database as well.
 *
 * Returns non-zero if the record did not exist in the database.
 */



extern MemHandle    
    _pascal FoamDBGetRecordFromID(VMFileHandle file, RecordID id);
/*
 * Looks for a record in the database with the specified ID, copies it
 * into memory, and returns the handle. If no record in the database had
 * the passed ID, returns 0.
 *
 * The handle returned should be freed using FoamDBDeleteRecord,
 * FoamDBDiscardRecord, or FoamDBSaveRecord.
 */



extern dword	
    _pascal FoamDBGetNumVisibleRecords(VMFileHandle file);
/*
 * Returns the count of visible records in the database. Used to provide a
 * list of records to the user
 */



extern MemHandle    
    _pascal FoamDBGetVisibleRecord(VMFileHandle file, dword index);
/*
 * Given the index of a visible record, copies the data into memory
 * and returns the handle of the block to the caller. If the index is
 * out of bounds, FoamDBGetVisibleRecord returns 0.
 *
 * The handle returned should be freed using FoamDBDeleteRecord,
 * FoamDBDiscardRecord, or FoamDBSaveRecord.
 */

extern Boolean
    _pascal FoamDBVisibleRecordEnumWithRange(VMFileHandle file, void *enumData,
					     dword startElement,
					     dword numOfRecords,
			    PCB(Boolean, callback, /* TRUE to stop enum */
				(RecordHeader *record, void *enumData)));
/*
 * Calls a callback routine for some records in the database, starting
 * with the record # (Element to start at), and process (Number to
 * process) records only. The callback routine can return non-zero to
 * stop the enumeration. enumData is a pointer to data that you can
 * pass to the callback routine, and that the callback routine can modify.
 *
 * Declaration of callback routine:
 *
 * Boolean _pascal CallBackRoutine(RecordHeader *record, void *enumData);
 */

extern Boolean
    _pascal FoamDBVisibleRecordEnum(VMFileHandle file, void *enumData,
			    PCB(Boolean, callback, /* TRUE to stop enum */
				(RecordHeader *record, void *enumData)));
/*
 * Calls a callback routine for each visible record in the database. The
 * callback routine can return non-zero to stop the enumeration. enumData
 * is a pointer to data that you can pass to the callback routine, and that
 * the callback routine can modify.
 *
 * Declaration of callback routine:
 *
 * Boolean _pascal CallBackRoutine(RecordHeader *record, void *enumData);
 */

extern Boolean
    _pascal FoamDBMapTokenToName(VMFileHandle file, word nameToken, word maxBytesToCopy, TCHAR *dest);
/*
 * Given a file handle, and a field name token, returns the field name
 * associated with the token. Returns non-zero if token was out of bounds
 */

extern void
    _pascal FoamDBSetNameForToken(VMFileHandle file, word nameToken, TCHAR *name);
/*
 * Given a field name token, changes the name associated with the token to
 * the passed name
 */

extern Boolean
    _pascal FoamDBMapNameToToken(VMFileHandle file, TCHAR *nameToLookFor, word *token);
/*
 * Given a file handle and a field name, looks the field name up in the DB,
 * to see if any fields currently have that name. If so, returns non-zero,
 * and stores the field name token in "token".
 */


extern dword
    _pascal FoamDBGetNextPrevRecord(VMFileHandle file, RecordID record,\
					word count);
/*
 * Given a file handle, a RecordID, and the number of records we want
 * to move forward or backward (negative numbers), this routine returns
 * the index in the huge array for the target record
 *
 */

extern void
    _pascal FoamDBSuspendNotifications(VMFileHandle file);
/*
 * Stop generating notifications for the passed database. Calls to this routine
 * must be matched by calls to FoamDBResumeNotifications.
 */

extern void
    _pascal FoamDBResumeNotifications(VMFileHandle file);
/*
 * Resumes generating notifications for the passed database. 
 */

extern RecordID
    _pascal FoamDBGetCurrentRecordID(VMFileHandle file);
/*
 * Returns the record ID that would be set for the next record
 */

extern void
    _pascal FoamDBSetCurrentRecordID(VMFileHandle file, RecordID id);
/*
 * Sets the record ID that would be set for the next record
 */

extern RecordID
    _pascal FoamDBBinarySearch(VMFileHandle file, MemHandle record);
/*
 * Do a binary search on the name of a record.
 */
extern void
    _pascal FoamDBSuspendUpdates(VMFileHandle file);
/*
 * Stop generating updates for the passed database. Calls to this routine
 * must be matched by calls to FoamDBResumeUpdates.
 */

extern void
    _pascal FoamDBResumeUpdates(VMFileHandle file);
/*
 * Resumes generating updates for the passed database. 
 */

extern void
    _pascal FoamDBResortDatabase(VMFileHandle file, 
			       PCB(sword, callback,
				   (RecordHeader *record1,
				    RecordHeader *record2)));
/*
 * Resorts the database
 */


#ifdef	__HIGHC__
pragma Alias(FoamDBOpen, "FOAMDBOPEN");
pragma Alias(FoamDBClose, "FOAMDBCLOSE");
pragma Alias(FoamDBCreateEmptyRecord, "FOAMDBCREATEEMPTYRECORD");
pragma Alias(FoamDBAddFieldToRecord, "FOAMDBADDFIELDTORECORD");
pragma Alias(FoamDBDeleteFieldFromRecord, "FOAMDBDELETEFIELDFROMRECORD");
pragma Alias(FoamDBSetFieldName, "FOAMDBSETFIELDNAME");
pragma Alias(FoamDBSetFieldData, "FOAMDBSETFIELDDATA");
pragma Alias(FoamDBGetFieldName, "FOAMDBGETFIELDNAME");
pragma Alias(FoamDBGetFieldData, "FOAMDBGETFIELDDATA");
pragma Alias(FoamDBFieldEnum, "FOAMDBFIELDENUM");
pragma Alias(FoamDBSaveRecord, "FOAMDBSAVERECORD");
pragma Alias(FoamDBDiscardRecord, "FOAMDBDISCARDRECORD");
pragma Alias(FoamDBDeleteRecord, "FOAMDBDELETERECORD");
pragma Alias(FoamDBGetRecordFromID, "FOAMDBGETRECORDFROMID");
pragma Alias(FoamDBGetNumVisibleRecords, "FOAMDBGETNUMVISIBLERECORDS");
pragma Alias(FoamDBGetVisibleRecord, "FOAMDBGETVISIBLERECORD");
pragma Alias(FoamDBDuplicateRecord, "FOAMDBDUPLICATERECORD");
pragma Alias(FoamDBVisibleRecordEnumWithRange, "FOAMDBVISIBLERECORDENUMWITHRANGE");
pragma Alias(FoamDBVisibleRecordEnum, "FOAMDBVISIBLERECORDENUM");
pragma Alias(FoamDBMapNameToToken, "FOAMDBMAPNAMETOTOKEN");
pragma Alias(FoamDBMapTokenToName, "FOAMDBMAPTOKENTONAME");
pragma Alias(FoamDBLockedRecordEnum, "FOAMDBLOCKEDRECORDENUM");
pragma Alias(FoamDBGetRecordID, "FOAMDBGETRECORDID");
pragma Alias(FoamDBGetNextPrevRecord, "FOAMDBGETNEXTPREVRECORD");
pragma Alias(FoamDBSuspendNotifications, "FOAMDBSUSPENDNOTIFICATIONS");
pragma Alias(FoamDBResumeNotifications, "FOAMDBRESUMENOTIFICATIONS");
pragma Alias(FoamDBGetCurrentRecordID, "FOAMDBGETCURRENTRECORDID");
pragma Alias(FoamDBSetCurrentRecordID, "FOAMDBSETCURRENTRECORDID");
pragma Alias(FoamDBBinarySearch, "FOAMDBBINARYSEARCH");
pragma Alias(FoamDBSuspendUpdates, "FOAMDBSUSPENDUPDATES");
pragma Alias(FoamDBResumeUpdates, "FOAMDBRESUMEUPDATES");
pragma Alias(FoamDBSetNameForToken, "FOAMDBSETNAMEFORTOKEN");
pragma Alias(FoamDBResortDatabase, "FOAMDBRESORTDATABASE");
#endif
@endlib
    
#endif
