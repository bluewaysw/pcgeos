/*******************************************************************
 *
 *  ttfile.c (extended version)                                 2.1
 *
 *    File I/O Component (body).
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  NOTES:
 *
 *   This implementation relies on the ANSI libc.  You may wish to
 *   modify it to get rid of libc and go straight to the your
 *   platform's stream routines.
 *
 *   The same source code can be used for thread-safe and re-entrant
 *   builds of the library.
 *
 ******************************************************************/

#include "ttconfig.h"

#include <stdio.h>
#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "freetype.h"
#include "tttypes.h"
#include "ttengine.h"
#include "ttmemory.h"
#include "ttfile.h"     /* our prototypes */


/* For now, we don't define additional error messages in the core library */
/* to report open-on demand errors. Define these error as standard ones   */


  /* This definition is mandatory for each file component! */
  EXPORT_FUNC
  const TFileFrame  TT_Null_FileFrame = { NULL, 0 };

/* It has proven useful to do some bounds checks during development phase. */
/* They should probably be undefined for speed reasons in a later release. */

#if DEBUG_FILE
#define CHECK_FRAME( frame, n )                          \
  do {                                                   \
    if ( frame.cursor + n > frame.address + frame.size ) \
      Panic( "Frame boundary error!\n" );                \
  } while ( 0 )
#else
#define CHECK_FRAME( frame, n )  /* nothing */
#endif

  /* Because a stream can be flushed, i.e. its file handle can be      */
  /* closed to save system resources, we must keep the stream's file   */
  /* pathname to be able to re-open it on demand when it is flushed    */

  struct  TStream_Rec_;
  typedef struct TStream_Rec_  TStream_Rec;
  typedef TStream_Rec*         PStream_Rec;

  struct  TStream_Rec_
  {
    FileHandle  file;                    /* file handle                      */
    Long        size;                    /* stream size in file              */
  };

  /* We support embedded TrueType files by allowing them to be       */
  /* inside any file, at any location, hence the 'base' argument.    */
  /* Note however that the current implementation does not allow you */
  /* to specify a 'base' index when opening a file.                  */
  /* (will come later)                                               */
  /* I still don't know if this will turn out useful ??   - DavidT   */

#define STREAM2REC( x )  ( (TStream_Rec*)HANDLE_Val( x ) )



  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/
  /********                                                   ********/
  /********  R E E N T R A N T   I M P L E M E N T A T I O N  ********/
  /********                                                   ********/
  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/

#define CUR_Stream   STREAM2REC( stream )    /* re-entrant macros */
#define CUR_Frame    (*frame)

#define STREAM_VARS  stream,
#define STREAM_VAR   stream



/*******************************************************************
 *
 *  Function    :  TT_Access_Frame
 *
 *  Description :  Notifies the component that we're going to read
 *                 'size' bytes from the current file position.
 *                 This function should load/cache/map these bytes
 *                 so that they will be addressed by the GET_xxx
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  SUCCESS on success. FAILURE on error.
 *
 *  Notes:    The function fails if the byte range is not within the
 *            the file, or if there is not enough memory to cache
 *            the bytes properly (which usually means that `size' is
 *            too big in both cases).
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Access_Frame( STREAM_ARGS FRAME_ARGS Short  size )
  {
    TT_Error  error;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( ALLOC( CUR_Frame.address, size ) )
      return error;

    error = TT_Read_File( STREAM_VARS (void*)CUR_Frame.address, size );
    if ( error )
    {
      FREE( CUR_Frame.address );
    }

    CUR_Frame.cursor = CUR_Frame.address;
    return error;
  } 


/*******************************************************************
 *
 *  Function    :  TT_Check_And_Access_Frame
 *
 *  Description :  Notifies the component that we're going to read
 *                 `size' bytes from the current file position.
 *                 This function should load/cache/map these bytes
 *                 so that they will be addressed by the GET_xxx
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  SUCCESS on success. FAILURE on error.
 *
 *  Notes:    The function truncates `size' if the byte range is not
 *            within the file.
 *
 *            It will fail if there is not enough memory to cache
 *            the bytes properly (which usually means that `size' is
 *            too big).
 *
 *            It will fail if you make two consecutive calls
 *            to TT_Access_Frame(), without a TT_Forget_Frame() between
 *            them.
 *
 *            The only difference with TT_Access_Frame() is that we
 *            check that the frame is within the current file.  We
 *            otherwise truncate it.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Check_And_Access_Frame( STREAM_ARGS FRAME_ARGS Short  size )
  {
    TT_Error  error;
    Long      readBytes;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( ALLOC( CUR_Frame.address, size ) )
      return error;

    readBytes = CUR_Stream->size - TT_File_Pos( STREAM_VAR );
    if ( size > readBytes )
      size = readBytes;

    error = TT_Read_File( STREAM_VARS (void*)CUR_Frame.address, size );
    if ( error )
    {
      FREE( CUR_Frame.address );
    }

    CUR_Frame.cursor = CUR_Frame.address;
    return error;
  }


/*******************************************************************
 *
 *  Function    :  TT_Forget_Frame
 *
 *  Description :  Releases a cached frame after reading.
 *
 *  Input  :  None
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Forget_Frame( FRAME_ARG )
  {
    if ( CUR_Frame.address == NULL )
      return TT_Err_Nested_Frame_Access;

    FREE( CUR_Frame.address );
    CUR_Frame.cursor = NULL;

    return TT_Err_Ok;
  }


  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/
  /***********                                             ***********/
  /***********  C O M M O N   I M P L E M E N T A T I O N  ***********/
  /***********                                             ***********/
  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/


/*******************************************************************
 *
 *  Function    :  TT_Open_Stream
 *
 *  Description :  Opens the font file and saves the total file size.
 *
 *  Input  :  error          address of stream's error variable
 *                           (re-entrant build only)
 *            filepathname   pathname of the file to open
 *            stream         address of target TT_Stream structure
 *
 *  Output :  SUCCESS on sucess, FAILURE on error.
 *            The target stream is set to -1 in case of failure.
 *
 ******************************************************************/

LOCAL_FUNC
TT_Error TT_Open_Stream( const FileHandle file,
                               TT_Stream* stream )
{
  TT_Error     error;
  PStream_Rec  stream_rec;

  CHECK_FILE( file );

  if ( ALLOC( *stream, sizeof ( TStream_Rec ) ) )
    return error;

  stream_rec = STREAM2REC( *stream );

  stream_rec->file = file;

  if ( !stream_rec->file )
  {
    error = TT_Err_Could_Not_Open_File;
    goto Fail;
  }

  stream_rec->size = FileSize( file );

#ifndef TT_CONFIG_OPTION_THREAD_SAFE
  CUR_Stream = stream_rec;
#endif

  return TT_Err_Ok;

Fail:
  FREE( stream_rec );
  return error;
}

/*******************************************************************
 *
 *  Function    : TT_Close_Stream
 *
 *  Description : Closes a stream.
 *
 *  Input  :  stream         address of target TT_Stream structure
 *
 *  Output :  void.
 *
 ******************************************************************/

  LOCAL_FUNC
  void  TT_Close_Stream( TT_Stream*  stream )
  {
    PStream_Rec  rec = STREAM2REC( *stream );


    FREE( rec );

    HANDLE_Set( *stream, NULL );
  }


/*******************************************************************
 *
 *  Function    : TT_Seek_File
 *
 *  Description : Seeks the file cursor to a different position.
 *
 *  Input  :  position     new position in file
 *
 *  Output :  SUCCESS on success.  FAILURE if out of range.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Seek_File( STREAM_ARGS Long  position )
  {
    FilePos( CUR_Stream->file, position, FILE_POS_START );
    if ( ThreadGetError() != NO_ERROR_RETURNED )  
      return TT_Err_Invalid_File_Offset;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : TT_Skip_File
 *
 *  Description : Skips forward the file cursor.
 *
 *  Input  :  distance    number of bytes to skip
 *
 *  Output :  see TT_Seek_File()
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Skip_File( STREAM_ARGS Long  distance )
  {
    FilePos( CUR_Stream->file, distance, FILE_POS_RELATIVE );
    if ( ThreadGetError() != NO_ERROR_RETURNED )
      return TT_Err_Invalid_File_Offset;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : TT_Read_File
 *
 *  Description : Reads a chunk of the file and copies it to memory.
 *
 *  Input  :  buffer    target buffer
 *            count     length in bytes to read
 *
 *  Output :  SUCCESS on success.  FAILURE if out of range.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Read_File( STREAM_ARGS void*  buffer, Short  count )
  {
    if ( FileRead( CUR_Stream->file, buffer, count, FALSE ) != count )
      return TT_Err_Invalid_File_Read;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : TT_Read_At_File
 *
 *  Description : Reads file at a specified position.
 *
 *  Input  :  position  position to seek to before read
 *            buffer    target buffer
 *            count     number of bytes to read
 *
 *  Output :  SUCCESS on success.  FAILURE if error.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Read_At_File( STREAM_ARGS Long   position,
                                         void*  buffer,
                                         Short  count )
  {
    PStream_Rec streamRec = STREAM2REC( stream );


    FilePos( streamRec->file, position, FILE_POS_START );

    if( ThreadGetError() != NO_ERROR_RETURNED )
      return TT_Err_Invalid_File_Offset;

    if( FileRead( streamRec->file, buffer, count, FALSE ) != count )
      return TT_Err_Invalid_File_Read;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_File_Pos
 *
 *  Description :  Returns current file seek pointer.
 *
 *  Input  :  none
 *
 *  Output :  Current file position.
 *
 ******************************************************************/

  EXPORT_FUNC
  Long  TT_File_Pos( STREAM_ARG )
  {
    return FilePos( CUR_Stream->file, 0, FILE_POS_RELATIVE );
  }


/* END */
