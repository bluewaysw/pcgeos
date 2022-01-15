/*******************************************************************
 *
 *  os2file.c (OS2 version)                                      2.1
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
 *   This implementation relies on the OS/2 file API. It was provided
 *   by the PM FreeType DLL author, Michal Necasek.
 *
 ******************************************************************/

#include "ttconfig.h"

#include <os2.h>   /* !Mike! */

#include <stdio.h>
#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "freetype.h"
#include "tttypes.h"
#include "ttdebug.h"
#include "ttengine.h"
#include "ttmutex.h"
#include "ttmemory.h"
#include "ttfile.h"     /* our prototypes */


/* For now, we don't define additional error messages in the core library  */
/* to report open-on demand errors.  Define these errors as standard ones. */

#define TT_Err_Could_Not_ReOpen_File  TT_Err_Could_Not_Open_File
#define TT_Err_Could_Not_ReSeek_File  TT_Err_Could_Not_Open_File


  /* This definition is mandatory for each file component! */
  EXPORT_FUNC
  const TFileFrame  TT_Null_FileFrame = { NULL, 0, 0 };


/* It has proven useful to do some bounds checks during development phase. */
/* They should probably be undefined for speed reasons in a later release. */

#if 0
#define CHECK_FRAME( frame, n )                          \
  do {                                                   \
    if ( frame.cursor + n > frame.address + frame.size ) \
      Panic( "Frame boundary error!\n" );                \
  } while ( 0 )
#else
#define CHECK_FRAME( frame, n )  \
  do {                           \
  } while ( 0 )
#endif


  /* Because a stream can be flushed, i.e., its file handle can be     */
  /* closed to save system resources, we must keep the stream's file   */
  /* pathname to be able to re-open it on demand when it is flushed.   */

  struct  _TStream_Rec
  {
    Bool     opened;                     /* is the stream handle opened ? */
    String*  name;                       /* the file's pathname           */
    Long     position;                   /* current pos. within the file  */

    HFILE    file;                       /* file handle         !Mike!    */
    Long     base;                       /* stream base in file           */
    Long     size;                       /* stream size in file           */
  };

  typedef struct _TStream_Rec  TStream_Rec;
  typedef TStream_Rec*         PStream_Rec;


  /* We support embedded TrueType files by allowing them to be         */
  /* inside any file, at any location, hence the 'base' argument.      */
  /* Note, however, that the current implementation does not allow you */
  /* to specify a 'base' index when opening a file.                    */
  /* (will come later)                                                 */
  /* I still don't know if this will turn out useful...   - DavidT     */

#define STREAM2REC( x )  ( (TStream_Rec*)HANDLE_Val( x ) )

  static  TT_Error  Stream_Activate  ( PStream_Rec  stream );
  static  TT_Error  Stream_Deactivate( PStream_Rec  stream );


#ifndef TT_CONFIG_OPTION_THREAD_SAFE

  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/
  /****                                                           ****/
  /****  N O N   R E E N T R A N T   I M P L E M E N T A T I O N  ****/
  /****                                                           ****/
  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/

  /* In non-reentrant builds, we allocate a single block where we'll */
  /* place all the frames smaller than FRAME_CACHE_SIZE, rather than */
  /* allocating a new block on each access.  Bigger frames will be   */
  /* malloced normally in the heap.                                  */
  /*                                                                 */
  /* See TT_Access_Frame() and TT_Forget_Frame() for details.        */

#define FRAME_CACHE_SIZE  2048

  /* The TFile_Component structure holds all the data that was */
  /* previously declared static or global in this component.   */
  /*                                                           */
  /* It is accessible through the 'engine.file_component'      */
  /* variable in re-entrant builds, or directly through the    */
  /* static 'files' variable in other builds.                  */

  struct  _TFile_Component
  {
    TMutex       lock;        /* used by the thread-safe build only */
    Byte*        frame_cache; /* frame cache     */
    PStream_Rec  stream;      /* current stream  */
    TFileFrame   frame;       /* current frame   */
  };

  typedef struct _TFile_Component  TFile_Component;

  static TFile_Component  files;

#define CUR_Stream  files.stream
#define CUR_Frame   files.frame

#define STREAM_VARS  /* void */
#define STREAM_VAR   /* void */

/* The macro CUR_Stream denotes the current input stream.            */
/* Note that for the re-entrant version, the 'stream' name has been  */
/* chosen according to the macro STREAM_ARGS.                        */

/* The macro CUR_Frame denotes the current file frame.              */
/* Note that for the re-entrant version, the 'frame' name has been  */
/* chosen according to the macro FRAME_ARGS.                        */

/* The macro STREAM_VAR is used when calling public functions */
/* that need an 'optional' stream argument.                   */


/*******************************************************************
 *
 *  Function    :  TTFile_Init
 *
 *  Description :  Initializes the File component.
 *
 ******************************************************************/

 LOCAL_FUNC
 TT_Error  TTFile_Init( PEngine_Instance  engine )
 {
   TT_Error  error;

   MUTEX_Create( files.lock );
   files.stream = NULL;
   ZERO_Frame( files.frame );

   if ( ALLOC( files.frame_cache, FRAME_CACHE_SIZE ) )
     return error;

   return TT_Err_Ok;
 }


/*******************************************************************
 *
 *  Function    :  TTFile_Done
 *
 *  Description :  Finalizes the File component.
 *
 ******************************************************************/

 LOCAL_FUNC
 TT_Error  TTFile_Done( PEngine_Instance  engine )
 {
   FREE( files.frame_cache );
   MUTEX_Destroy( files.lock );

   return TT_Err_Ok;
 }


/*******************************************************************
 *
 *  Function    : TT_Use_Stream
 *
 *  Description : Copies or duplicates a given stream.
 *
 *  Input  :  org_stream   original stream
 *            stream       target stream (copy or duplicate)
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Use_Stream( TT_Stream   org_stream,
                           TT_Stream*  stream )
  {
     MUTEX_Lock( files.lock );                /* lock file mutex    */

     *stream = org_stream;                    /* copy the stream    */
     files.stream = STREAM2REC( org_stream ); /* set current stream */

     Stream_Activate( files.stream );

     return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : TT_Done_Stream
 *
 *  Description : Releases a given stream.
 *
 *  Input  :  stream  target stream
 *
 *  Output :  Error code.
 *
 ******************************************************************/

 EXPORT_FUNC
 TT_Error  TT_Done_Stream( TT_Stream*  stream )
 {
    HANDLE_Set( *stream, NULL );
    MUTEX_Release( files.lock );

    return TT_Err_Ok;
 }


/*******************************************************************
 *
 *  Function    :  TT_Access_Frame
 *
 *  Description :  Notifies the component that we're going to read
 *                 'size' bytes from the current file position.
 *                 This function should load/cache/map these bytes
 *                 so that they will be addressed by the GET_xxx()
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 *  Notes:    The function fails if the byte range is not within the
 *            the file, or if there is not enough memory to cache
 *            the bytes properly (which usually means that `size' is
 *            too big in both cases).
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Access_Frame( STREAM_ARGS FRAME_ARGS Long  size )
  {
    TT_Error  error;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( size <= FRAME_CACHE_SIZE )
    {
      /* use the cache */
      CUR_Frame.address = files.frame_cache;
      CUR_Frame.size    = FRAME_CACHE_SIZE;
    }
    else
    {
      if ( ALLOC( CUR_Frame.address, size ) )
        return error;
      CUR_Frame.size    = size;
    }

    error = TT_Read_File( STREAM_VARS (void*)CUR_Frame.address, size );
    if ( error )
    {
      if ( size > FRAME_CACHE_SIZE )
        FREE( CUR_Frame.address );
      CUR_Frame.address = NULL;
      CUR_Frame.size    = 0;
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
 *                 so that they will be addressed by the GET_xxx()
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
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
  TT_Error  TT_Check_And_Access_Frame( STREAM_ARGS FRAME_ARGS Long  size )
  {
    TT_Error  error;
    Long      readBytes, requested;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( size <= FRAME_CACHE_SIZE )
    {
      /* use the cache */
      CUR_Frame.address = files.frame_cache;
      CUR_Frame.size    = FRAME_CACHE_SIZE;
    }
    else
    {
      if ( ALLOC( CUR_Frame.address, size ) )
        return error;
      CUR_Frame.size    = size;
    }

    requested = size;
    readBytes = CUR_Stream->size - TT_File_Pos( STREAM_VAR );
    if ( size > readBytes )
      size = readBytes;

    error = TT_Read_File( STREAM_VARS (void*)CUR_Frame.address, size );
    if ( error )
    {
      if ( requested > FRAME_CACHE_SIZE )
        FREE( CUR_Frame.address );
      CUR_Frame.address = NULL;
      CUR_Frame.size    = 0;
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

    if ( CUR_Frame.size > FRAME_CACHE_SIZE )
      FREE( CUR_Frame.address );

    ZERO_Frame( CUR_Frame );

    return TT_Err_Ok;
  }


#else /* TT_CONFIG_OPTION_THREAD_SAFE */

  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/
  /********                                                   ********/
  /********  R E E N T R A N T   I M P L E M E N T A T I O N  ********/
  /********                                                   ********/
  /*******************************************************************/
  /*******************************************************************/
  /*******************************************************************/

/* a simple macro to access the file component's data */
#define files  ( *((TFile_Component*)engine.file_component) )

#define CUR_Stream   STREAM2REC( stream )    /* re-entrant macros */
#define CUR_Frame    (*frame)

#define STREAM_VARS  stream,
#define STREAM_VAR   stream


/*******************************************************************
 *
 *  Function    :  TTFile_Init
 *
 *  Description :  Initializes the File component.
 *
 ******************************************************************/

 LOCAL_FUNC
 TT_Error  TTFile_Init( PEngine_Instance  engine )
 {
   return TT_Err_Ok;
 }


/*******************************************************************
 *
 *  Function    :  TTFile_Done
 *
 *  Description :  Finalizes the File component.
 *
 ******************************************************************/

 LOCAL_FUNC
 TT_Error  TTFile_Done( PEngine_Instance  engine )
 {
   return TT_Err_Ok;
 }


/*******************************************************************
 *
 *  Function    :  TT_Use_Stream
 *
 *  Description :  Duplicates a stream for a new usage.
 *
 *  Input  :  input_stream   source stream to duplicate
 *            copy           address of target duplicate stream
 *
 *  Output :  error code.
 *            The target stream is set to NULL in case of failure.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Use_Stream( TT_Stream   input_stream,
                           TT_Stream*  copy )
  {
    PStream_Rec  rec = STREAM2REC( input_stream );

    return TT_Open_Stream( rec->name, copy );
  }


/*******************************************************************
 *
 *  Function    : TT_Done_Stream
 *
 *  Description : Releases a given stream.
 *
 *  Input  :  stream  target stream
 *
 *  Output :
 *
 ******************************************************************/

 EXPORT_FUNC
 TT_Error  TT_Done_Stream( TT_Stream*  stream )
 {
   return TT_Close_Stream( stream );
 }


/*******************************************************************
 *
 *  Function    :  TT_Access_Frame
 *
 *  Description :  Notifies the component that we're going to read
 *                 'size' bytes from the current file position.
 *                 This function should load/cache/map these bytes
 *                 so that they will be addressed by the GET_xxx()
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 *  Notes:    The function fails if the byte range is not within the
 *            the file, or if there is not enough memory to cache
 *            the bytes properly (which usually means that `size' is
 *            too big in both cases).
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Access_Frame( STREAM_ARGS FRAME_ARGS int  size )
  {
    TT_Error  error;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( ALLOC( CUR_Frame.address, size ) )
      return error;
    CUR_Frame.size    = size;

    error = TT_Read_File( STREAM_VARS (void*)CUR_Frame.address, size );
    if ( error )
    {
      FREE( CUR_Frame.address );
      CUR_Frame.size    = 0;
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
 *                 so that they will be addressed by the GET_xxx()
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
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
  TT_Error  TT_Check_And_Access_Frame( STREAM_ARGS FRAME_ARGS int  size )
  {
    TT_Error  error;
    Long      readBytes;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( ALLOC( CUR_Frame.address, size ) )
      return error;
    CUR_Frame.size    = size;

    readBytes = CUR_Stream->size - TT_File_Pos( STREAM_VAR );
    if ( size > readBytes )
      size = readBytes;

    error = TT_Read_File( STREAM_VARS (void*)CUR_Frame.address, size );
    if ( error )
    {
      FREE( CUR_Frame.address );
      CUR_Frame.size    = 0;
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
    ZERO_Frame( CUR_Frame );

    return TT_Err_Ok;
  }

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */


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
 *  Function    :  Stream_Activate
 *
 *  Description :  activates a stream, this will either:
 *                   - open a new file handle if the stream is closed
 *                   - move the stream to the head of the linked list
 *
 *  Input  :  stream   the stream to activate
 *
 *  Output :  error condition.
 *
 *  Note   :  this function is also called with fresh new streams
 *            created by TT_Open_Stream().  They have their 'size'
 *            field set to -1.
 *
 ******************************************************************/

  static  TT_Error  Stream_Activate( PStream_Rec  stream )
  {
    ULONG ulAction;  /* !Mike! */

    if ( !stream->opened )
    {
#if 0
    if ( !(stream->file = fopen( stream->name, "rb" )) )    /* !Mike! */
#endif

/* XXX : Strange.  GCC/EMX wants an (Byte*) for the file name? */
#ifdef __EMX__

      if ( DosOpen( (Byte*)stream->name, &(stream->file),
                    &ulAction, 0,
                    0, OPEN_ACTION_OPEN_IF_EXISTS,
                    OPEN_SHARE_DENYNONE | OPEN_ACCESS_READONLY, NULL ) )
        return TT_Err_Could_Not_ReOpen_File;

#else

      if ( DosOpen( stream->name, &(stream->file),
                    &ulAction, 0,
                    0, OPEN_ACTION_OPEN_IF_EXISTS,
                    OPEN_SHARE_DENYNONE | OPEN_ACCESS_READONLY, NULL ) )
        return TT_Err_Could_Not_ReOpen_File;

#endif /* __EMX__ */

      stream->opened = TRUE;

      /* A newly created stream has a size field of -1 */
      if ( stream->size < 0 )
      {
#if 0
        fseek( stream->file, 0, SEEK_END );             /* !Mike! */
        stream->size = ftell( stream->file );
#endif

        DosSetFilePtr( stream->file, 0, FILE_END, (ULONG *)&(stream->size) );
#if 0
        fseek( stream->file, 0, SEEK_SET );
#endif

        DosSetFilePtr( stream->file, 0, FILE_BEGIN, &ulAction );
      }

      /* Reset cursor in file */
      if ( stream->position )
      {
#if 0   /* !Mike! */
        if ( fseek( stream->file, stream->position, SEEK_SET ) != 0 )
#endif 

        if ( DosSetFilePtr( stream->file, stream->position,
                            FILE_BEGIN, &ulAction ) )
        {
          /* error during seek */
#if 0
          fclose( stream->file );           /* !Mike! */
#endif

          DosClose( stream->file );
          stream->opened = FALSE;
          return TT_Err_Could_Not_ReSeek_File;
        }
      }
    }
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Stream_DeActivate
 *
 *  Description :  deactivates a stream, this will:
 *                   - close its file handle if it was opened
 *                   - remove it from the opened list if necessary
 *
 *  Input  :  stream   the stream to deactivate
 *
 *  Output :  Error condition
 *
 *  Note   :  the function is called whenever a stream is deleted
 *            (_not_ when a stream handle's is closed due to an
 *            activation).  However, the stream record isn't
 *            destroyed by it...
 *
 ******************************************************************/

  static  TT_Error  Stream_Deactivate( PStream_Rec  stream )
  {
    if ( stream->opened )
    {
      /* Save its current position within the file */
#if 0
      stream->position = ftell( stream->file );     /* !Mike! */
#endif

      DosSetFilePtr( stream->file, 0, FILE_CURRENT,
                     (ULONG *)&(stream->position) );
#if 0
      fclose( stream->file );                       /* !Mike! */
#endif

      DosClose( stream->file );
      stream->file   = 0;
      stream->opened = FALSE;
    }

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Stream_Size
 *
 *  Description :  Returns the length of a given stream, even if it
 *                 is flushed.
 *
 *  Input  :  stream     the stream
 *
 *  Output :  length of stream in bytes.
 *
 ******************************************************************/

  EXPORT_FUNC
  Long  TT_Stream_Size( TT_Stream  stream )
  {
    PStream_Rec  rec = STREAM2REC( stream );


    if ( rec )
      return rec->size;
    else
      return 0;  /* invalid stream - return 0 */
  }


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
  TT_Error  TT_Open_Stream( const String*  filepathname,
                            TT_Stream*     stream )
  {
    int          len;
    TT_Error     error;
    PStream_Rec  stream_rec;


    if ( ALLOC( *stream, sizeof ( TStream_Rec ) ) )
      return error;

    stream_rec = STREAM2REC( *stream );

    stream_rec->file     = NULLHANDLE;  /* !Mike! */
    stream_rec->size     = -1;
    stream_rec->base     = 0;
    stream_rec->opened   = FALSE;
    stream_rec->position = 0;

    len = strlen( filepathname ) + 1;
    if ( ALLOC( stream_rec->name, len ) )
      goto Fail;

    strncpy( (String*)stream_rec->name, filepathname, len );

    error = Stream_Activate( stream_rec );
    if ( error )
      goto Fail_Activate;

#ifndef TT_CONFIG_OPTION_THREAD_SAFE
    CUR_Stream = stream_rec;
#endif

    return TT_Err_Ok;

  Fail_Activate:
    FREE( stream_rec->name );
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
 *  Output :  SUCCESS (always).
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  TT_Close_Stream( TT_Stream*  stream )
  {
    PStream_Rec  rec = STREAM2REC( *stream );


    Stream_Deactivate( rec );
    FREE( rec->name );
    FREE( rec );

    HANDLE_Set( *stream, NULL );

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : TT_Flush_Stream
 *
 *  Description : Flushes a stream, i.e., closes its file handle.
 *
 *  Input  :  stream         address of target TT_Stream structure
 *
 *  Output :  Error code
 *
 *  NOTE : Never flush the current opened stream.  This means that
 *         you should _never_ call this function between a
 *         TT_Use_Stream() and a TT_Done_Stream()!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Flush_Stream( TT_Stream*  stream )
  {
    PStream_Rec  rec = STREAM2REC( *stream );


    if ( rec )
    {
      Stream_Deactivate( rec );
      return TT_Err_Ok;
    }
    else
      return TT_Err_Invalid_Argument;
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
  TT_Error  TT_Seek_File( STREAM_ARGS long  position )
  {
    ULONG  ibActual;            /* !Mike! */


    position += CUR_Stream->base;

#if 0
    if ( fseek( CUR_Stream->file, position, SEEK_SET ) )    /* !Mike! */
#endif

    if ( DosSetFilePtr( CUR_Stream->file, position, FILE_BEGIN , &ibActual ) )
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
  TT_Error  TT_Skip_File( STREAM_ARGS long  distance )
  {
    ULONG ibActual;             /* !Mike! */


#if 0
    return TT_Seek_File( STREAM_VARS ftell( CUR_Stream->file ) -
                         CUR_Stream->base + distance ); /* !Mike! */
#endif

    DosSetFilePtr( CUR_Stream->file, 0, FILE_CURRENT, &ibActual );
    return TT_Seek_File( STREAM_VARS ibActual - CUR_Stream->base + distance );
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
  TT_Error  TT_Read_File( STREAM_ARGS void*  buffer, long  count )
  {
    ULONG cbActual;         /* !Mike! */

#if 0               /* !Mike! */
    if ( fread( buffer, 1, count, CUR_Stream->file ) != (unsigned long)count )
#endif

    DosRead( CUR_Stream->file, buffer, count, &cbActual );
    if ( cbActual  != (unsigned long)count )
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
  TT_Error  TT_Read_At_File( STREAM_ARGS long   position,
                                         void*  buffer,
                                         long   count )
  {
    TT_Error  error;


    if ( ( error = TT_Seek_File( STREAM_VARS position ) )      ||
         ( error = TT_Read_File( STREAM_VARS buffer, count ) ) )
      return error;

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
 *  Output :  current file position
 *
 ******************************************************************/

  EXPORT_FUNC
  Long  TT_File_Pos( STREAM_ARG )
  {
    ULONG ibActual;  /* !Mike! */


#if 0
    return ftell( CUR_Stream->file ) - CUR_Stream->base;    /* !Mike! */
#endif

    DosSetFilePtr( CUR_Stream->file, 0, FILE_CURRENT, &ibActual );
    return ibActual - CUR_Stream->base;
  }


/*******************************************************************
 *
 *  Function    :  GET_Byte
 *
 *  Description :  Extracts a byte from the current file frame.
 *
 *  Input  :  None or current frame
 *
 *  Output :  Extracted Byte.
 *
 ******************************************************************/
#if 0
  EXPORT_FUNC
  Byte  TT_Get_Byte( FRAME_ARG )
  {
    CHECK_FRAME( CUR_Frame, 1 );

    return (Byte)(*CUR_Frame.cursor++);
  }
#endif

/*******************************************************************
 *
 *  Function    :  GET_Char
 *
 *  Description :  Extracts a signed byte from the current file frame.
 *
 *  Input  :  None or current frame
 *
 *  Output :  Extracted char.
 *
 ******************************************************************/

  EXPORT_FUNC
  Char  TT_Get_Char( FRAME_ARG )
  {
    CHECK_FRAME( CUR_Frame, 1 );

    return (Char)(*CUR_Frame.cursor++);
  }


/*******************************************************************
 *
 *  Function    :  GET_Short
 *
 *  Description :  Extracts a short from the current file frame.
 *
 *  Input  :  None or current frame
 *
 *  Output :  Extracted short.
 *
 ******************************************************************/

  EXPORT_FUNC
  short  TT_Get_Short( FRAME_ARG )
  {
    short  getshort;


    CHECK_FRAME( CUR_Frame, 2 );

    getshort = ((short)CUR_Frame.cursor[0] << 8) |
                (short)CUR_Frame.cursor[1];

    CUR_Frame.cursor += 2;

    return getshort;
  }


/*******************************************************************
 *
 *  Function    :  GET_UShort
 *
 *  Description :  Extracts an unsigned short from the frame.
 *
 *  Input  :  None or current frame
 *
 *  Output :  Extracted ushort.
 *
 ******************************************************************/
#if 0
  EXPORT_FUNC
  unsigned short  TT_Get_UShort( FRAME_ARG )
  {
    unsigned short  getshort;


    CHECK_FRAME( CUR_Frame, 2 );

    getshort = ((unsigned short)CUR_Frame.cursor[0] << 8) |
                (unsigned short)CUR_Frame.cursor[1];

    CUR_Frame.cursor += 2;

    return getshort;
  }
#endif

/*******************************************************************
 *
 *  Function    :  GET_Long
 *
 *  Description :  Extracts a long from the frame.
 *
 *  Input  :  None or current frame
 *
 *  Output :  Extracted long.
 *
 ******************************************************************/

  EXPORT_FUNC
  long  TT_Get_Long( FRAME_ARG )
  {
    long  getlong;


    CHECK_FRAME( CUR_Frame, 4 );

    getlong = ((long)CUR_Frame.cursor[0] << 24) |
              ((long)CUR_Frame.cursor[1] << 16) |
              ((long)CUR_Frame.cursor[2] << 8 ) |
               (long)CUR_Frame.cursor[3];

    CUR_Frame.cursor += 4;

    return getlong;
  }


/*******************************************************************
 *
 *  Function    :  GET_ULong
 *
 *  Description :  Extracts an unsigned long from the frame.
 *
 *  Input  :  None
 *
 *  Output :  Extracted ulong.
 *
 ******************************************************************/
#if 0
  EXPORT_FUNC
  unsigned long  TT_Get_ULong( FRAME_ARG )
  {
    unsigned long  getlong;


    CHECK_FRAME( CUR_Frame, 4 );

    getlong = ( ((unsigned long)CUR_Frame.cursor[0] << 24) |
                ((unsigned long)CUR_Frame.cursor[1] << 16) |
                ((unsigned long)CUR_Frame.cursor[2] << 8 ) |
                 (unsigned long)CUR_Frame.cursor[3] );

    CUR_Frame.cursor += 4;

    return getlong;
  }
#endif


/* END */
