/***************************************************************************

                Copyright (c) Breadbox Computer Company 1998
                         -- All Rights Reserved --

  PROJECT:      Generic Database System
  MODULE:       Basic Database System
  FILE:         internal.h

  AUTHOR:       Gerd Boerrigter

  $Header: /Home Bulletin Board/Library/BasicDB/INTERNAL.H 10    7/16/98 18:29 Gerdb $

  DESCRIPTION:
    This file contains the description of internal structures and routines
    for the Basic Database library.

***************************************************************************/

#ifndef __INTERN_H
#define __INTERN_H


/* Timeout value for VMGrabExclusive (in tenth of seconds) */
#define BDB_GRAB_TIMEOUT 60


/*
 * Some new types.
 */

/* Handle of an index in our database. */
typedef ChunkHandle BasicDBIndexHandle;


/*
    The directory block of a database.  This structure holds information
    about our database.
 */
typedef struct {
    LMemBlockHeader     BDBD_standardHeader;

    /* The ID of the next record that will be saved. */
    BasicDBRecordID     BDBD_nextRecordID;

    /* The VM handle of LMem heap's block containing the element array
        with the field names. */
    VMBlockHandle       BDBD_nameBlock;

    /* Handle of element array. */
    ChunkHandle         BDBD_nameArray;

    /* The handle of the HugeArray that contain the records. */
    VMBlockHandle       BDBD_recordArray;

    /* Head of the linked list of indices.  This list is also stored in
        this block. */
    BasicDBIndexHandle  BDBD_indices;

    /* Flags for the map block. */
    word                BDBD_flags;

    /* Reserved for future use. */
    dword               BDBD_reserved;

} BasicDBDirectory;

#if 0

/*
 *  The record header which contains information for this record.
 */
typedef struct {
    /* An unique ID which identifies the record in the database.
       Only valid after the first call to C<BasicDBSaveRecord>.*/
    BasicDBRecordID     BDBRH_id;

    /* Size of this record including the record header. */
    word                BDBRH_size;

    /* ID which is assigned to the next field in this record.  This ID
       is unique to this record. */
    BasicDBFieldID      BDBRH_nextFieldID;

    /* Number of fields in this record. */
    word                BDBRH_fieldCount;

    /** The user ID of the record owner.  It is not used by the database
        itself -- it must be handled by an higher level. */
    dword               BDBRH_userID;

    /* Flags, unused by the library. */
    word                BDBRH_flags;

    /* The first field header follows the record header. */
} BasicDBRecordHeader;
#endif

/*
    The field header for each field data.
*/
typedef struct {
    /* An unique ID which identifies the field in this record.  It is
       assigned through C<BasicDBAddField>. */
    BasicDBFieldID          BDBFH_id;

    /* Size of this field including the field header. */
    word                    BDBFH_size;

    /* Refers to the name of the field. */
    NameToken               BDBFH_nameToken;

    /* The category of the field.  The BasicDB does not care about
       this field, but it can be used for identification. */
    BasicDBFieldCategory    BDBFH_category;

    /* The type of the data contained in this field.  The BasicDB does
       not care about this field, but it can be used for identification. */
    BasicDBFieldType        BDBFH_type;

    /* data follows the header. */
} BasicDBFieldHeader;


typedef struct {
    ChunkHandle             BDBILE_next;
    VMBlockHandle           BDBILE_vmBlock;
    word                    BDBILE_valueForCallback;
    BasicDBIndexListFlags   BDBILE_flags;
} BasicDBIndexListNode;


/* Structure of an element in the index. */
typedef struct {
    BasicDBRecordID     BDBIE_id;
} BasicDBIndexElement;


/* Our callback function for the index. */
typedef sword _pascal (*pcfm_BasicDBCallback) (
                                    MemHandle block1,
                                    MemHandle block2,
                                    word valueForCallback,
                                    BasicDBCallback );

/* Fatal errors */
typedef enum {
    /** A flag should be set, that is nor used, yet.  To be compatible
        to future extensions it should always be clear. */
    UNUSED_FLAG_SET,

    /** MSG_DATABASE_USE_DATABASE was called, but the object still uses
        an other database. */
    DATABASE_OBJECT_ALREADY_IN_USE,

    /** MSG_DATABASE_QUIT_DATABASE was called, but the object is
        currently not used. */
    DATABASE_OBJECT_NOT_IN_USE,

    /** Tried to create or get an new record, but there was still one
        current record and only one can be there at a time. */
    CURRENT_RECORD_ALREADY_IN_USE,

    /** There is no current record where this function can work on. */
    NO_CURRENT_RECORD,

    /** This operation can not be done on the current record. */
    NOT_ALLOWED_ON_CURRENT_RECORD
} FatalErrors;


/* SWAT warnings */
typedef enum {
    /** There is no index in the database. */
    NO_INDEX_IN_DATABASE,

    /** There was no callback routine given for updating the index. */
    NO_CALLBACK_FOR_INDEX_UPDATE,

    /** There is no index with the given handle. */
    INDEX_HANDLE_INVALID,

    /** There is no index with the given handle. */
    UNKNOWN_FIELD_HEADER_ELEMENT,

    /** The pointer where to store the record ID was C<NULL>.  Therefore
        the ID can not be added to an index, which might be usefull. */
    NO_ADDRESS_TO_STORE_RECORD_ID
} Warnings;



/***************************************************************************
    Functions
***************************************************************************/


#endif /* __INTERN_H */