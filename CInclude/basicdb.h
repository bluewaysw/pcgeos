/***************************************************************************

                Copyright (c) Breadbox Computer Company 1998
                         -- All Rights Reserved --

  PROJECT:      Generic Database System
  MODULE:       Basic Database System
  FILE:         basicDB.h

  AUTHOR:       Gerd Boerrigter

  $Header: /Home Bulletin Board/Includes/BASICDB.H 24    7/21/97 18:25 Gerdb $

  DESCRIPTION:
    This file contains the description of external structures and routines
    for the Basic Database library.

***************************************************************************/

#ifndef __BASICDB_H
#define __BASICDB_H


/** maximum size of a field name. */
#define BASICDB_MAX_NAME_SIZE 255



/*
 * Some new types.
 */

/** An unique identifier for a record in a database. */
typedef dword       BasicDBRecordID;

/** An unique identifier for a field in a record. */
typedef word        BasicDBFieldID;

/** A special Name can be assigned to each field.  This is its token.
    The name is stored in an ElementArray in the same VM file. */
typedef word        NameToken;


/**
   A word representing the categorie the field belongs to.  For example
   Phone, Email, Name, ...  The value is application specific.
 */
typedef word        BasicDBFieldCategory;   /* email, name, ... */

/**
   A word representing the type of the data contained in this field
   like Integer, String.  The value is application specific.
 */
typedef word        BasicDBFieldType;


/** field header elements to search for. */
typedef enum {
    BDBFHE_CATEGORY = 1,
    BDBFHE_TYPE,
    BDBFHE_NAME_TOKEN
} BasicDBFieldHeaderElement;



/*
 *  The record header which contains information for this record.
 *  !!! should go into internal.h !!!
 */
typedef struct {
    /** An unique ID which identifies the record in the database.
        Only valid after the first call to C<BasicDBSaveRecord>.*/
    BasicDBRecordID     BDBRH_id;

    /** Size of this record including the record header. */
    word                BDBRH_size;

    /** ID which is assigned to the next field in this record.  This ID
       is unique to this record. */
    BasicDBFieldID      BDBRH_nextFieldID;

    /** Number of fields in this record. */
    word                BDBRH_fieldCount;

    /** The user ID of the record owner.  It is not used by the database
        itself -- it must be handled by an higher level. */
    dword               BDBRH_userID;

    /** Flags, unused by the library. */
    word                BDBRH_flags;

    /** The first field header follows the record header. */
} BasicDBRecordHeader;



/** Our callback function for the index. */
typedef sword _pascal (*BasicDBCallback) (
                                    MemHandle	block1,
                                    MemHandle	block2,
                                    word    valueForCallback );


typedef byte BasicDBIndexListFlags;
#define BDBILF_AUTO_UPDATE       0x80



/** Error values */
typedef enum {
    BDBE_NO_ERROR = 0,

    /** The VMGrabExclusive on the database timed out. */
    BDBE_TIMEOUT,

    /** The requested record ID could not be found. */
    BDBE_RECORD_NOT_FOUND,

    /** The requested field could not be found. */
    BDBE_FIELD_NOT_FOUND,

    /** There is no index with the given handle. */
    BDBE_INDEX_HANDLE_NOT_FOUND,

    /** A index is used with the database, but no callback routine was given
        with the function call. */
    BDBE_INDEX_NO_CALLBACK,

    /** We tried to find a record in the index, but it is not sorted. */
    BDBE_INDEX_UNSORTED,

    /** An existing record should be saved, but was was deleted. */
    BDBE_SAVED_DELETED_RECORD,

    /** A HugeArrayLock could not be done succesful.  A ID or index might
        be out of range. */
    BDBE_UNSUCCESSFUL_HUGE_ARRAY_LOCK,

    /** We had a problem during memory allocation.  Normal that should
        mean, that we are out of memory. */
    BDBE_MEMORY_ALLOCATION_ERROR,

    /** This operation is not possible for record already stored
        in the database. */
    BDBE_RECORD_ALREADY_SAVED_ERROR

} BasicDBError;



/***************************************************************************
    Functions
***************************************************************************/

/*==========================================================================
    Working on the whole database.
==========================================================================*/

/**
    Does a VMGrabExclusive.
    !!! Should be sends a general change notification (someday).
*/
extern
VMStartExclusiveReturnValue _pascal
BasicDBGrabExclusive(
    VMFileHandle    file,           /* contains our database. */
    VMOperation     operation
    );

/**
    Does a VMReleaseExclusive.
*/
extern
void _pascal
BasicDBReleaseExclusive(
    VMFileHandle    file        /* contains our database. */
    );


/**
    Performs a string search on the database.
*/
extern
BasicDBError _pascal
BasicDBStringSearch(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    TCHAR *         searchString
    );

/**
    Creates a new empty database in a given VMFile.
    Returns the handle of the database directory block, if the creation
    was successful.
*/
extern
/* jfhtest */
BasicDBError _pascal
//dword _pascal
BasicDBCreate(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle*  dirBlock,       /* database directory block. */
    Boolean isShared                /* Flag telling if grabs are necessary */
    ) ;



/*==========================================================================
    Working with records:
==========================================================================*/

/**
    Create a new empty record in memory.  It is not added to a database,
    this happens only with C<BasicDBSaveRecord>.
    The recordID is also assigned during saving.
*/
extern
MemHandle _pascal                   /* Working handle to the record. */
BasicDBCreateRecord(
    void
    );

/**
    Duplicate a record and returns the handle to the newly created
    record.  A recordID is assigned during saving.
    Useful if template records are used.
*/
extern
MemHandle _pascal                   /* record handle to new record. */
BasicDBDuplicateRecord(
    MemHandle       recordHandle    /* Record handle of the record
                                        to be duplicated. */
    );

/**
    Saves the record in the memory to the database file and
    frees the memory block.  If the recordID is C<0>, then a new unique
    recordID is assigned to this record.  If the record was deleted
    meanwhile, it will be saved into the DB again.
*/
extern
BasicDBError _pascal
BasicDBSaveRecord(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    MemHandle       recordHandle,   /* Record handle of the record
                                        to be saved. */
    BasicDBCallback Callback,                     /* Callback function for sorting indices. */
    BasicDBRecordID*    recordID
    );


/**
    Frees the memory block without saving it to the database.  The
    database is completly unchanged.
*/
extern
void _pascal
BasicDBDiscardRecord(
    MemHandle       recordHandle
    );


/**
    Get a record -- given its ID -- from the database into memory.
    The record is copied into a memory block, which handle is returned.
*/
extern
BasicDBError _pascal
BasicDBGetRecord(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    BasicDBRecordID recordID,       /* ID of the record. */
    MemHandle *     returnHandle    /* handle of record */
    );

/**
    Get a record -- given its element number in the HugeArray -- from the
    database into memory.
    The record is copied into a memory block, which handle is returned.
*/
extern
BasicDBError _pascal
BasicDBGetRecordByElemNum(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    dword           elemNum,        /* index in HugeArray of the record. */
    MemHandle *     recordHandle    /* handle of record */
    );

/**
    Get a record -- given a position in an index -- from the database into
    memory.
    The record is copied into a memory block, which handle is returned.
*/
extern
BasicDBError _pascal
BasicDBGetRecordByIndex(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    VMBlockHandle   indexArray,     /* HugeArray of the index array to use. */
    dword           elemNum,        /* element to get from the index. */
    MemHandle *     returnHandle    /* handle of record. */
    );

/**
    Get a record id -- given a position in an index -- from the database 
	intomemory.
*/
extern
BasicDBError _pascal
BasicDBGetRecordIDByIndex(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   indexArray,     /* HugeArray of the index array to use. */
    dword           elemNum,        /* element to get from the index. */
    BasicDBRecordID *returnID		/* id of record. */
	);


/**
    Deletes the record from the database.  If the record was actually
    never saved to the database, it frees the memory block without
    saving it to the database and the database is completly unchanged.
*/
extern
BasicDBError _pascal
BasicDBDeleteRecord(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    MemHandle       recordHandle,   /* Record in memory. */
    BasicDBCallback Callback                      /* Callback function for sorting indices. */
    );

/**
    Deletes the record given by its record ID from the database.
*/
extern
BasicDBError _pascal
BasicDBDeleteRecordByID(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    BasicDBRecordID recordID,       /* record ID of record to delete. */
    BasicDBCallback Callback                      /* Callback function for sorting indices. */
    );

/**
    Returns the recordID of the current record.  If the return value is
    C<0> the record is not yet saved into the database.
*/
extern
BasicDBRecordID _pascal
BasicDBGetRecordID(
    MemHandle       recordHandle
    );

/**
    Get the index in the data HugeArray for a record given its ID.  If
    the ID can not be found, C<BDBE_RECORD_NOT_FOUND> is returned and index
    is set to C<ID_NOT_FOUND>.
*/
extern
BasicDBError _pascal
BasicDBGetElemNumFromID(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    BasicDBRecordID recordID,       /* record ID of record to delete. */
    dword           *elemNum        /* ElemNum of record with given ID. */
    );

/**
    Get the user ID of the record given.
*/
extern
dword _pascal
BasicDBGetRecordUserID(
    MemHandle recordHandle,               /* handle of record to get the 
                                     * user ID from */
    BasicDBError *error             /* place to store a error return code */       
    );

/**
    Set the user ID of the record given.
    This is only possible for a record never saved before.
*/
extern
BasicDBError _pascal
BasicDBSetRecordUserID(
    MemHandle recordHandle,         /* handle of record to get the 
                                     * user ID from */
    dword userID                    /* the user ID to set */       
    );

/**
    Get a record from the record HugeArray into memory.
    The record is copied into a memory block, which handle is returned.

    Note: Be sure to call C<VMGrabExclusive()> befor this function is
          called!
*/
extern
BasicDBError _pascal
GetRecordByRecordID(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   recordArray,    /* HugeArray of the records. */
    BasicDBRecordID recordID,       /* ID of the record. */
    MemHandle *     returnHandle    /* handle of record */
    );

/**
    Get a record from the record HugeArray into memory.
    The record is copied into a memory block, which handle is returned.

    Note: Be sure to call C<VMGrabExclusive()> befor this function is
          called!
*/
extern
MemHandle _pascal
GetRecordByElemNum(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   recordArray,    /* HugeArray of the records. */
    dword           elemNum         /* index of record in HugeArray. */
    );

/**
    Get the index in the data HugeArray for a record given its ID.

    Note: Be sure to call C<VMGrabExclusive()> befor this function is
          called!
*/
extern
BasicDBError _pascal
GetElemNumFromID(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   recordArray,    /* HugeArray of the records. */
    BasicDBRecordID recordID,       /* ID of the record. */
    dword *         elemNum         /* Index in the HugeArray. */
    );



/*==========================================================================
    Working with fields:
==========================================================================*/

BasicDBError _pascal 
BasicDBGetFieldCount(
	MemHandle record, 
	word *fieldCount);

/**
    Adds a new (empty) field to the record.  The returned BasicDBFieldID
    is the unique ID to identify this field in this record.
    For simplicity we add every new field to the end of the record.
*/
extern
BasicDBError _pascal
BasicDBAddField(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    MemHandle       recordHandle,
    BasicDBFieldCategory    fieldCategory,
    BasicDBFieldType        fieldType,
    TCHAR *         fieldName,      /* Namestring of the field. */
    BasicDBFieldID* fieldID         /* ID assigned to that field. */
    );

/**
    Deletes the field with the given field ID from the record.
*/
extern
BasicDBError _pascal
BasicDBDeleteField(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    MemHandle       recordHandle,
    BasicDBFieldID  fieldID
    );

/**
    Stores data in the specified field.

    When storing ASCII data (strings), the strings should B<not> be null
    terminated. For example, if you want to store the string "ABCD", then
    pass a pointer to the string, and dataSize = 4.
*/
extern
BasicDBError _pascal
BasicDBSetFieldData(
    MemHandle       recordHandle,
    BasicDBFieldID  fieldID,
    void *          data,
    word            dataSize
    );


/**
    Gets data of a field.  Returns the number of bytes used for the data.
    If C<0> is returned, the field does not exist or is empty.  If the
    return value is greater than C<destSize> it indicates, that not all
    data could be copied.

    Note: The standard (most efficient) way to store string data is
          B<without> a null terminator, so callers will need to use the
          returned data size.
*/
extern
word _pascal                        /* size of data */
BasicDBGetFieldData(
    MemHandle       recordHandle,
    BasicDBFieldID  fieldID,
    void *          dest,
    word            maxBytesToGet   /* size of dest buffer */
    );

/**
    Gets the pointer to the data of a field.
    If the returned pointer is C<NULL>, the requested field ID could not
    be found in this record.

    Note: The record B<must> be locked!

    Note: The standard (most efficient) way to store string data is
          B<without> a null terminator, so callers will need to use the
          returned data size.
*/
extern
word _pascal                        /* size of data */
BasicDBGetPtrToFieldData(
    BasicDBRecordHeader *   recordPtr,
    BasicDBFieldID          fieldID,
    byte **                 dataPtr
    );

/**
    Returns the number of bytes used for the data.
    If C<0> is returned, the field does not exist or is empty.
*/
extern
word _pascal                        /* size of data */
BasicDBGetFieldDataSize(
    MemHandle       recordHandle,
    BasicDBFieldID  fieldID
    );


/**
    Changes the name of the specified field.
*/
extern
BasicDBError _pascal
BasicDBSetFieldName(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,      /* database directory block. */
    MemHandle       recordHandle,
    BasicDBFieldID  fieldID,
    TCHAR *         fieldName       /* New name of the field. */
    );

/**
    Gets the name of the specified field.
*/
extern
BasicDBError _pascal
BasicDBGetFieldName(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,      /* database directory block. */
    MemHandle       recordHandle,
    BasicDBFieldID  fieldID,
    TCHAR *         fieldName,      /* buffer for name string. */
    word            maxBytesToGet   /* size of buffer for the null
                                        terminated name string. */
    );
/**
    Returns the fieldID of the field with the given C<value>
    If C<nth> is greater than 1, the fieldID of the nth found field is
    returned, otherwise the first found field is returned.

    If the return value is C<0>, the field could not be found in
    the record.
*/
extern
BasicDBFieldID _pascal
BasicDBGetFieldID(
    MemHandle       recordHandle,
    BasicDBFieldHeaderElement   searchFor,
    word                    value,      /* value to search for. */
    int                     nth
    );

/**
    Returns the fieldID of the field with the given C<value>.
    If C<nth> is greater than 1, the fieldID of the nth found field is
    returned, otherwise the first found field is returned.  This is
    necessary because more fields can belong to the same category
    or type.

    If the return value is C<0>, the field could not be found in
    the record.

    Note: The record to search in must be locked on the heap.
*/
extern
BasicDBFieldID _pascal
BasicDBGetFieldIDPtr(
    BasicDBRecordHeader *   recordPtr,  /* Pointer to the locked record. */
    BasicDBFieldHeaderElement   searchFor,  /* */
    word                    value,      /* value to search for. */
    int                     nth         /* */
    );


/**
    Returns a pointer to the field with the given ID.
    If the return value is NULL, the field could not be found in the record.

    Note: The record to search in must be locked on the heap.
*/
extern
void * _pascal            /* Pointer to the field. */
GetFieldPtr(
    BasicDBRecordHeader *   recordPtr,  /* Pointer to the locked record. */
    BasicDBFieldID          fieldID     /* ID to search for. */
    );


/**
    Adds a name to the name array.
*/
extern
BasicDBError _pascal
AddFieldName(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    TCHAR *         fieldName,      /* field name. */
    NameToken *     token
    );

/**
    Deletes a name from the name array.
*/
extern
BasicDBError _pascal
DeleteFieldName(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    NameToken       token           /* Token of the field name. */
    );

/**
    Changes a field name.
    It deletes the old name -- given by its NameToken -- from the array,
    and adds the new name to the array.

    If C<oldToken> is C<CA_NULL_ELEMENT>, no name will be deleted.  And if
    C<fieldName> is C<NULL> no name will be added and C<newToken> will
    be C<CA_NULL_ELEMENT>.
*/
extern
BasicDBError _pascal
ChangeFieldName(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,      /* database directory block. */
    NameToken       oldToken,       /* Token of the field name. */
    TCHAR *         fieldName,      /* field name. */
    NameToken *     newToken
    );


/**
    Get a field name.
*/
extern
BasicDBError _pascal
GetFieldNameByToken(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    NameToken       token,          /* Token of the field name. */
    TCHAR *         fieldName,      /* field name. */
    word            maxBytesToGet
    );


/*==========================================================================
    Indices:
==========================================================================*/

/**
    Creates a new index.

    If the flag C<BDBILF_AUTO_UPDATE> is set, the index will be
    automatically updated, if records are added or deleted.
*/
extern
BasicDBError _pascal
BasicDBIndexCreate(
    VMFileHandle        file,           /* contains the database. */
    VMBlockHandle       dirBlock,       /* database directory block. */
    BasicDBIndexListFlags    flags,
    word                valueForCallback,
    VMBlockHandle *     indexArray      /* HugeArray of the index array. */
    );

/**
    Destroys an index by destroying the HugeArray containing it and to free
    the element in the index list, if the index was present there.
*/
extern
BasicDBError _pascal
BasicDBIndexDestroy(
    VMFileHandle        file,           /* contains the database. */
    VMBlockHandle       dirBlock,       /* database directory block. */
    VMBlockHandle       indexToDestroy  /* HugeArray of the index array. */
    );

/**
    Adds a new record to all the indices.
    If there is no index in use by the current database, C<BDBE_NO_ERROR>
    is returned.
    But if an index is used but the pointer to the callback routine is
    C<NULL>, the index can not be updated and C<BDBE_INDEX_NO_CALLBACK>
    is returned.

    Note: Make sure, that VMGrabExclusive is already called.
*/
extern
BasicDBError _pascal
IndicesAddEntry(
    VMFileHandle        file,           /* contains our database. */
    VMBlockHandle       dirBlock,       /* database directory block. */
    MemHandle           recordHandle,   /* Record to be added. */
    BasicDBCallback     Callback        /* Callback function for sorting indices. */
    );


/**
    Adds a entry to an index.
*/
extern
BasicDBError _pascal
BasicDBIndexElementAdd (
    VMFileHandle        file,           /* contains our database. */
    VMBlockHandle       dirBlock,       /* database directory block. */
    BasicDBRecordID     recordID,       /* ID of the record. */
    VMBlockHandle       indexArray,     /* HugeArray of index. */
    word                valueForCallback,
    BasicDBCallback     Callback        /* Callback function for sorting indices. */
    );

/**
    Adds a entry to an index.
    If the callback routine is a C<NULL> pointer, this function does
    nothing but still return C<BDBE_NO_ERROR>.

    Note: Make sure, that VMGrabExclusive is already called.
*/
extern
BasicDBError _pascal
HugeIndexAdd (
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   indexBlock,     /* HugeArray of index. */
    VMBlockHandle   recordArray,    /* HugeArray of our records. */
    BasicDBRecordHeader *   newRecordPtr,   /* record to be sorted into index. */
	MemHandle		newRecordHandle,
    word            valueForCallback,
    BasicDBCallback Callback
    );

/**
    Deletes a record from all the indices.
    If there is no index in use by the current database, C<BDBE_NO_ERROR>
    is returned.
    But if an index is used but the pointer to the callback routine is
    C<NULL>, the index can not be updated and C<BDBE_INDEX_NO_CALLBACK>
    is returned.

    Note: Make sure, that VMGrabExclusive is already called.
*/
extern
BasicDBError _pascal
IndicesDeleteEntry(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    MemHandle       recordHandle,   /* Record to be added. */
    BasicDBCallback Callback                      /* Callback function for sorting indices. */
    );

/**
    Deletes an entry from an index.
*/
extern
BasicDBError _pascal
BasicDBIndexElementDelete (
    VMFileHandle        file,           /* contains our database. */
    VMBlockHandle       dirBlock,       /* database directory block. */
    BasicDBRecordID     recordID,       /* ID of the record. */
    VMBlockHandle       indexArray,     /* HugeArray of index. */
    word                valueForCallback,
    BasicDBCallback     Callback        /* Callback function for sorting indices. */
    );

/**
    Finds a record id in an index.
*/
extern
BasicDBError _pascal
BasicDBIndexElementFind (
    VMFileHandle        file,           /* contains our database. */
    VMBlockHandle       dirBlock,       /* database directory block. */
    BasicDBRecordID     recordID,       /* ID of the record. */
    VMBlockHandle       indexArray,     /* HugeArray of index. */
    word                valueForCallback,
    BasicDBCallback     Callback,        /* Callback function for sorting indices. */
    dword				*elemNum
	);

/**
    Deletes an entry from an index.
    If the callback routine is a C<NULL> pointer, this function does
    nothing but still return C<BDBE_NO_ERROR>.

    Note: Make sure, that VMGrabExclusive is already called.
*/
extern
BasicDBError _pascal
HugeIndexDelete(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   indexBlock,     /* HugeArray of index. */
    VMBlockHandle   recordArray,    /* HugeArray of our records. */
    BasicDBRecordHeader *   delRecordPtr,   /* record to be deleted from index. */
	MemHandle		delRecordHandle,
    word            valueForCallback,
    BasicDBCallback Callback
    );


/**
    Find an entry from an index.
    If the callback routine is a C<NULL> pointer, this function does
    nothing but still return C<BDBE_NO_ERROR>.

    Note: Make sure, that VMGrabExclusive is already called.
*/
extern
BasicDBError _pascal
HugeIndexFind(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   indexBlock,     /* HugeArray of index. */
    VMBlockHandle   recordArray,    /* HugeArray of our records. */
    BasicDBRecordHeader *   delRecordPtr,   /* record to be deleted from index. */
	MemHandle		delRecordHandle,
    word            valueForCallback,
    BasicDBCallback Callback,
    dword *elemNum);


/**
    Find the element number in the HugeArray, where the index element
    belongs to.
    If the callback routine is a C<NULL> pointer, this function
    FatalErrors.

    Note: Make sure, that VMGrabExclusive is already called.
*/
extern
BasicDBError _pascal                /* elemNum where the record belongs. */
HugeIndexFindPosition (
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   indexBlock,     /* HugeArray of index. */
    VMBlockHandle   recordArray,    /* HugeArray of our records. */
    BasicDBRecordHeader *   newRecordPtr,   /* record to be sorted into index. */
	MemHandle		newRecordHandle,
    word            valueForCallback,
    BasicDBCallback Callback,
    dword *         position,
    BasicDBRecordID*    id,
	Boolean			lookID
    );


/**
    Get the number of elements in the index.
*/
extern
BasicDBError _pascal
BasicDBIndexGetCount(
    VMFileHandle    file,           /* contains our database. */
    VMBlockHandle   dirBlock,       /* database directory block. */
    VMBlockHandle   indexArray,     /* HugeArray of the index array to use. */
    dword *         count           /* elements in the index. */
    );



#endif /* __BASICDB_H */
