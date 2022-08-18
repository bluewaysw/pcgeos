/*******************************************************************
 *
 *  ttfile.h                                                     1.3
 *
 *    File I/O Component (specification).
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  Changes between 1.3 and 1.2:
 *
 *  - all functions report error values now
 *
 *  - the stream semantics have also changed
 *
 *  Changes between 1.2 and 1.1:
 *
 *  - added macros to support re-entrant builds
 *
 *  - added the TT_Duplicate_File function to duplicate streams
 *    (re-entrant builds only)
 *
 ******************************************************************/

#ifndef TTFILE_H
#define TTFILE_H

#include "ttconfig.h"
#include "freetype.h"
#include "ttengine.h"
#include "ttdebug.h"

#ifdef __cplusplus
  extern "C" {
#endif

  /* Initialize file component */
  LOCAL_DEF
  TT_Error  TTFile_Init( TT_Engine  engine );

  /* Done with file component */
  LOCAL_DEF
  TT_Error  TTFile_Done( TT_Engine  engine );


  /**********************************************************************/
  /*                                                                    */
  /*  Stream functions.                                                 */
  /*                                                                    */
  /**********************************************************************/

  /* Open a file and return a stream handle for it.           */
  /* Should only be used for a new face object's main stream. */

  LOCAL_DEF
  TT_Error  TT_Open_Stream( FileHandle     file,
                            TT_Stream*     stream );


  /* Closes, then discards, a stream when it's no longer needed.   */
  /* Should only be used for a stream opend with TT_Open_Stream(). */

  LOCAL_DEF
  TT_Error  TT_Close_Stream( TT_Stream*  stream );


  /* Informs the component that we're going to use the file   */
  /* opened in 'org_stream', and report errors to the 'error' */
  /* variable.                                                */

  /* in non re-entrant builds, 'org_stream' is simply copied   */
  /* to 'stream'. Otherwise, the latter is a duplicate handle  */
  /* for the file opened with 'org_stream'                     */

  EXPORT_DEF
  TT_Error  TT_Use_Stream( TT_Stream   org_stream,
                           TT_Stream*  stream );

  /* Informs the component that we don't need to perform file */
  /* operations on the stream 'stream' anymore.  This must be */
  /* used with streams "opened" with TT_Use_Stream() only!    */

  /* in re-entrant builds, this will really discard the stream */

  EXPORT_DEF
  TT_Error  TT_Done_Stream( TT_Stream*  stream );

  /* Closes the stream's file handle to release system resources */
  /* The function TT_Use_Stream automatically re-activates a     */
  /* flushed stream when it uses one                             */

  EXPORT_DEF
  TT_Error  TT_Flush_Stream( TT_Stream*  stream );

/* The macros STREAM_ARGS and STREAM_ARG let us build a thread-safe */
/* or re-entrant implementation depending on a single configuration */
/*define.                                                           */

#ifdef TT_CONFIG_OPTION_THREAD_SAFE

#define STREAM_ARGS   TT_Stream  stream,
#define STREAM_ARG    TT_Stream  stream

#else

#define STREAM_ARGS   /* void */
#define STREAM_ARG    void

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */


  /****************************************************************/
  /*                                                              */
  /*  File Functions.                                             */
  /*                                                              */
  /*  The following functions perform file operations on the      */
  /*  currently 'used' stream.  In thread-safe builds, only one   */
  /*  stream can be used at a time.  Synchronisation is performed */
  /*  through the Use_Stream()/Done_Stream() functions.           */
  /*                                                              */
  /****************************************************************/

  /* Read 'count' bytes from file into 'buffer' */

  EXPORT_DEF
  TT_Error  TT_Read_File( STREAM_ARGS void*   buffer,
                                      Long    count );


  /* Seek file cursor to a given position */

  EXPORT_DEF
  TT_Error  TT_Seek_File( STREAM_ARGS Long  position );


  /* Skip the next 'distance' bytes in file */

  EXPORT_DEF
  TT_Error  TT_Skip_File( STREAM_ARGS Long  distance );


  /* Read the 'count' bytes at 'position' into 'buffer' */

  EXPORT_DEF
  TT_Error  TT_Read_At_File( STREAM_ARGS Long   position,
                                         void*  buffer,
                                         Long   count );

  /* Return current file position */

  EXPORT_DEF
  Long  TT_File_Pos( STREAM_ARG );

  /* Return length of a given stream, even if it is flushed */

  EXPORT_DEF
  Long  TT_Stream_Size( TT_Stream  stream );


  /********************************************************************/
  /*                                                                  */
  /*  Frame operations.                                               */
  /*                                                                  */
  /*  For a comprehensive explanation of frames, please refer to the  */
  /*  documentation files.                                            */
  /*                                                                  */
  /********************************************************************/

  /* Frame type declaration.*/

  struct  TFileFrame_
  {
    Byte*  address;  /* frame buffer                     */
    Byte*  cursor;   /* current cursor position in frame */
    Long   size;     /* frame size                       */
  };

  typedef struct TFileFrame_  TFileFrame;

  EXPORT_DEF
  const TFileFrame  TT_Null_FileFrame;


/* The macro ZERO_Frame is used to define and init a frame.      */
/* It is important to have a default frame of { NULL, NULL, 0 }  */
/* before a call to TT_Access_Frame().  Otherwise, the call will */
/* fail with a TT_Err_Nested_Frame_Accesses error.               */

#define ZERO_Frame( frame )     \
      {                         \
        (frame).address = NULL; \
        (frame).cursor  = NULL; \
        (frame).size    = 0;    \
      }


#define CHECK_FILE( _handle_ )  ECCheckFileHandle( _handle_ )


/* The macros FRAME_ARGS and FRAME_ARG let us build a thread-safe   */
/* or re-entrant implementation depending on a single configuration */
/* define                                                           */

#ifdef TT_CONFIG_OPTION_THREAD_SAFE

#define FRAME_ARGS   TFileFrame*  frame,
#define FRAME_ARG    TFileFrame*  frame

#else

#define FRAME_ARGS   /* void */
#define FRAME_ARG    void

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */


  /* Access the next 'size' bytes from current position. */
  /* Fails if all bytes cannot be read/accessed.         */

  EXPORT_DEF
  TT_Error  TT_Access_Frame( STREAM_ARGS FRAME_ARGS Long  size );


  /* Access the bytes located in the next 'size' bytes of the file. */
  /* Doesn't fail if less than 'size' bytes are accessible (like    */
  /* at the end of the file).                                       */

  EXPORT_DEF
  TT_Error  TT_Check_And_Access_Frame( STREAM_ARGS FRAME_ARGS Long  size );

  /* Forget frame */

  EXPORT_DEF
  TT_Error  TT_Forget_Frame( FRAME_ARG );


  /* primitive routines for data accessing */

  EXPORT_DEF
  Char   TT_Get_Char ( FRAME_ARG );
  EXPORT_DEF
  Short  TT_Get_Short( FRAME_ARG );
  EXPORT_DEF
  Long   TT_Get_Long ( FRAME_ARG );

#ifdef TT_CONFIG_OPTION_THREAD_SAFE

#define  TT_Get_Byte( frame )   ( (Byte  )TT_Get_Char ( frame ) )
#define  TT_Get_UShort( frame ) ( (UShort)TT_Get_Short( frame ) )
#define  TT_Get_ULong( frame )  ( (ULong )TT_Get_Long ( frame ) )

#else

#define  TT_Get_Byte()   ( (Byte  )TT_Get_Char () )
#define  TT_Get_UShort() ( (UShort)TT_Get_Short() )
#define  TT_Get_ULong()  ( (ULong )TT_Get_Long () )

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */


#ifdef __cplusplus
  }
#endif

#endif /* TTFILE_H */


/* END */
