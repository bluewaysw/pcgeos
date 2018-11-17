/*
        SSTOR.H

        Structured Storage access for Geos

        by Marcus Groeber 1999
*/

#ifndef __SSTOR_H
#define __SSTOR_H

/*
   Opaque handle types used for refering to an entire docfile, a storage
   ("subdirectory"), or a stream ("file"). These should only be passed around
   by the application, but not relied upon to have any further "meaning".
 */
typedef MemHandle StgDocfile;   // Handle to an open docfile
typedef MemHandle StgStorage;   // Handle to a storage in a docfile
typedef MemHandle StgStream;    // Handle to an open stream in a docfile

typedef enum {
  STGERR_NONE = 0,              // No error
  STGERR_FILE_NOT_STORAGE,      // The file is not a storage
  STGERR_FORMAT_ERROR,          // The file is malformed
  STGERR_FILE_ERROR,            // A general file I/O error occurred
  STGERR_MEMORY_ERROR,          // A memory allocation error occurred
  STGERR_NAME_NOT_FOUND,        // The storage or stream was not found
  STGERR_NAME_WRONG_TYPE,       // The named object was of the wrong type
  STGERR_SEEK_ERROR,            // Tried to seek beyond the end of stream
} StgError;

/*
 * Opens a docfile with the given file. If successful (return value is
 * STGERR_NONE), the following two handles are returned:
 *
 *      *sdf    Handle to the entire docfile, used primarily for closing it.
 *      *root   Storage handle to the "root" storage within the docfile.
 *
 */
StgError StgOpenDocfile(FileHandle file, StgDocfile *sdf, StgStorage *root);

/*
 * Closes a docfile opened with StgOpenDocfile(). All StgStorage and StgStream
 * handles become invalid. All StgStream handles should be closed before
 * performing this call on an open docfile. (The only exception is the
 * StgStorage created by the call to StgOpenDocfile, which is automatically
 * closed by this call.)
 */
void StgCloseDocfile(StgDocfile sdf);

/*
 * Open a storage that is contained within another (equivalent
 * to a "cd subdir" in a file system). You pass it the handle of the parent
 * storage and the name of the child storage. If successful, it returns a
 * handle that can be used for accessing the child storage in *child. This
 * function only works for stream names containing no non-ASCII characters.
 */
StgError StgStorageOpen(StgStorage parent, char *name, StgStorage *child);

/*
 * Closes a storage opened with StgStorageOpen and frees
 * all associated resources.
 */
void StgStorageClose(StgStorage);

/*
 * Opens a stream ("file") within the given storage for reading. Open streams
 * must be closed with StgStreamClose when done with to free resources. If
 * succesful, *stream returns a handle to the stream that can be used for
 * accessing its contents. The same stream can be referenced multiple times
 * for accessing it with multiple stream pointers (see StgStreamClone).
 * This function only works for stream names containing no non-ASCII characters.
 */
StgError StgStreamOpen(StgStorage stg, char *name, StgStream *stream);

/*
 * Creates a duplicate StgStream object that uses the same stream as the source
 * stream but maintains an independent stream pointer. This is useful for
 * sequentially accessing different parts of the same stream simultaneously.
 */
StgStream StgStreamClone(StgStream source);

/*
 * Reads up to the requested amount of data from the specified open stream
 * into the given buffer. Returns the number of bytes that have been read.
 * Sequential reads can assumed to be buffered internally by the library.
 */
word StgStreamRead(StgStream stream, void *buf, word size);

/*
 * Moves the stream pointer of the given stream handle to the specified
 * offset.
 */
typedef ByteEnum StgPosMode;
#define STG_POS_START 0
#define STG_POS_RELATIVE 1
#define STG_POS_END 2

StgError StgStreamSeek(StgStream stream, dword pos, StgPosMode mode);

/*
 * Gets the current position of the stream pointer of the given stream handle.
 */
dword StgStreamPos(StgStream stream);

/*
 * Returns the code of the last error that occurred on the stream as of the
 * last operation.  This routine will return the same value until the next
 * read or seek operation.
 */
StgError StgStreamGetLastError(StgStream stream);

/*
 * Closes a stream opened with StgStreamOpen or StgStreamClone and frees all
 * resources.
 */
void StgStreamClose(StgStream stream);

#endif /* __SSTOR_H */
