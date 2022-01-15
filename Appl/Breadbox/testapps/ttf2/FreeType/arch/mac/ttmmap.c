/*******************************************************************
 *
 *  ttmmap.c                                                     2.0
 *
 *    Memory-Mapped file component ( replaces ttfile.c ).
 *
 *  Copyright 1996-1998 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT. By continuing to use, modify or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  Changes between 2.0 and 1.3 :
 *
 *  - adopted new design/separation introduced in ttfile.c 2.0
 *
 ******************************************************************/

#include "ttconfig.h"

#include <stdio.h>
#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif


#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif

#include <folders.h>
#include <resources.h>


#include "freetype.h"
#include "tttypes.h"
#include "ttdebug.h"
#include "ttengine.h"
#include "ttmutex.h"
#include "ttmemory.h"
#include "ttfile.h"     /* our prototypes */

  /* This definition is mandatory for each file component! */
  EXPORT_FUNC
  const TFileFrame  TT_Null_FileFrame = { NULL, 0, 0 };
  
  /* It has proven useful to do some bounds checks during   */
  /* development phase.  Define DEBUG_FILE when compiling   */
  /* this component to enable them.                         */

#ifdef DEBUG_FILE
#define CHECK_FRAME( frame, n )                        \
  do {                                                 \
    if ( frame.cursor+n > frame.address + frame.size ) \
      Panic( "Frame boundary error!\n" );              \
  } while ( 0 )
#else
#define CHECK_FRAME( frame, n ) \
  do {                          \
  } while( 0 )
#endif

  struct _TFileMap
  {
    String*  base;       /* base address of mapped file       */
    Int      refcount;   /* reference count for handle region */
    Long     size;       /* stream size in file               */
    Long     offset;     /* offset in file                    */
    Handle   handle;     /* Macintosh style handle to lock/unlock */
    short    resid;      /* Id of resource file to close when done */
  };

  typedef struct _TFileMap  TFileMap;

#define MAP_Address( map )  (Byte*)( (map)->base + (map)->offset )

  /* The stream record structure */
  typedef struct _TStream_Rec
  {
    TFileMap*  map;     /* mapped file description */
    Long       pos ;    /* cursor in mapped file   */
  } TStream_Rec;

  typedef TStream_Rec*  PStream_Rec;

#define STREAM2REC( x )  ( (TStream_Rec*)HANDLE_Val( x ) )


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

  /* The TFile_Component structure holds all the data that was */
  /* previously declared static or global in this component.   */
  /*                                                           */
  /* It is accessible through the 'engine.file_component'      */
  /* variable in re-entrant builds, or directly through the    */
  /* static 'files' variable in other builds.                  */

  struct _TFile_Component
  {
    TMutex       lock;        /* used by the thread-safe build only */
    PStream_Rec  stream;      /* current stream  */
    TFileFrame   frame;       /* current frame   */
  };

  typedef struct _TFile_Component  TFile_Component;

/* The macro CUR_Stream denotes the current input stream              */
/* Note that for the re-entrant version, the 'stream' name has been   */
/* chosen according to the macro STREAM_ARGS.                         */

/* The macro CUR_Frame denotes the current file frame               */
/* Note that for the re-entrant version, the 'frame' name has been  */
/* chosen according to the macro FRAME_ARGS.                        */

/* The macro STREAM_VAR is used when calling public functions */
/* that need an 'optional' stream argument.                   */

#define CUR_Stream   files.stream            /* thread-safe macros */
#define CUR_Frame    files.frame

#define STREAM_VARS  /* void */
#define STREAM_VAR   /* void */
  
  /* the 'files' variable is only defined in non-reentrant builds */

  static TFile_Component  files;



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
   MUTEX_Create( files.lock );
   files.stream = NULL;
   ZERO_Frame( files.frame );

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
 *  Output :  Error code
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Use_Stream( TT_Stream   org_stream,
                           TT_Stream*  stream )
  {
    MUTEX_Lock( files.lock );
    *stream = org_stream;
    files.stream = STREAM2REC( org_stream );  /* set current stream */

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : TT_Done_Stream
 *
 *  Description : Releases a given stream.
 *
 *  Input  :  stream
 *
 *  Output :  Error code
 *
 ******************************************************************/

 EXPORT_FUNC
 TT_Error  TT_Done_Stream( TT_Stream*  stream )
 {
   HANDLE_Set( *stream, NULL );
   MUTEX_Release( files.lock );

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

#define CUR_Stream   STREAM2REC( stream )      /* re-entrant macros */
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
   engine.file_component = NULL;

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
 *  Function    : TT_Use_Stream
 *
 *  Description : Copies or duplicates a given stream.
 *
 *  Input  :  org_stream   original stream
 *            stream       target stream (copy or duplicate)
 *
 *  Output :  Error code.  The output stream is set to NULL in
 *            case of Failure.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Use_Stream( TT_Stream   input_stream,
                           TT_Stream*  copy )
  {
    TT_Error     error;
    PStream_Rec  stream_rec;
    PStream_Rec  copy_rec;


    stream_rec = STREAM2REC( input_stream );

    if ( ALLOC( copy_rec, sizeof ( TStream_Rec ) ) )
      goto Fail;

    HANDLE_Set( *copy, copy_rec );

    copy_rec->map->refcount++;
    copy_rec->pos = 0;

    return TT_Err_Ok;

  Fail:
    HANDLE_Set( *copy, NULL );
    return error;
  }


/*******************************************************************
 *
 *  Function    : TT_Done_Stream
 *
 *  Description : Releases a given stream.
 *
 *  Input  :  stream
 *
 *  Output :  error code
 *
 ******************************************************************/

 EXPORT_FUNC
 TT_Error  TT_Done_Stream( TT_Stream*  stream )
 {
   return TT_Close_Stream( stream );
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
 *  Function    :  AllocateMap
 *
 *  Description :  Allocates a new map from the table.
 *
 *  Output :  Pointer to new stream rec.  NULL in case of failure.
 *
 ******************************************************************/

  static 
  TFileMap*  Allocate_Map( void )
  {
    TFileMap*  result;


    if ( MEM_Alloc( result, sizeof ( TFileMap ) ) )
      return NULL;

    result->refcount = 1;
    return result;
  }


/*******************************************************************
 *
 *  Function    :  ReleaseMap
 *
 *  Description :  Releases a used map to the table if reference i
 *                 counter reaches zero.
 *
 *  Input  :  map
 *
 *  Output :  None.
 *
 *  Note : Called by TT_Close_File()
 *
 ******************************************************************/

  static 
  void  Release_Map ( TFileMap*  map )
  {
    map->refcount--;
    if ( map->refcount <= 0 )
    {
      /* MacOS System calls */
      HUnlock(map->handle);             
      ReleaseResource(map->handle);
      CloseResFile(map->resid);

      FREE( map );
    }
  }


/* Whadda ya mean "strdup undefined"? Fine, I'll define my own! */
static char *mystrdup(const char *str) {
    char *ret;
    
    if ( TT_Alloc(strlen(str) + 1, (void**)&ret) != 0 ) return(NULL);
    strcpy(ret, str);
    return(ret);
    }

/*******************************************************************
 *
 *  Function    :  TT_Open_Stream
 *
 *  Description :  Opens the font file and saves the total file size.
 *
 *  Input  :  error          address of stream's error variable
 *                           (re-entrant build only).
 *            filepathname   pathname of the file to open
 *            stream         address of target TT_Stream structure
 *
 *  Output :  SUCCESS on success, FAILURE on error.
 *            The target stream is set to -1 in case of failure.
 *
 ******************************************************************/
/*
**  This is not a totally generic implementation.  It currently assumes the filename
**  starts with "fonts:" and uses slashes instead of colons like Mac code normally
** would.  Given a filename of the form "fonts:/filename/resname", Load the resource
** and lock the handle
**
** The "fonts:" at the beginning is just a convention I came up with to 
**  indicate the Fonts folder inside the current System folder (find via FindFolder())
*/

  LOCAL_FUNC
  TT_Error  TT_Open_Stream( const String*  filepathname, 
                            TT_Stream*     stream )
  {
    TT_Error     error;
    Int          file;
    PStream_Rec  stream_rec;
    TFileMap*    map;

    int          size, err = 0;
    short        vRefNum, res = -1;
    Str255       FontName;
    char         *cp, *p, *fname, *sep;
    Str63        myName;
    long         dirID;


    if ( ALLOC( *stream, sizeof ( TStream_Rec ) ) )
      return error;

    map = Allocate_Map();
    if ( !map )
    {
      error = TT_Err_Out_Of_Memory;
      goto Memory_Fail;
    }
    
    stream_rec = STREAM2REC( *stream );

    /* Find the dirID of the Fonts folder in the current System folder */
    if (FindFolder(kOnSystemDisk, kFontsFolderType, kDontCreateFolder, &vRefNum, &dirID)) 
        goto File_Fail;

    /* Break the name apart */
    fname = mystrdup(filepathname); /* Make a copy so we can muck with it */
    sep = ":/";     /* Things that can seperate file path componants */
    
    strtok(fname, sep);             /* Skip over "fonts:" */
    
    if ((p = strtok(NULL, sep)) == NULL)        /* Get filename */
        goto File_Fail;
    strcpy(myName + 1, p);                      /* Make this a Pascal string (Yuck!) */
    myName[0] = strlen(p);
     
    if ((p = strtok(NULL, sep)) == NULL)        /* Get res name */
        goto File_Fail;
    strcpy(FontName+1, p);                      /* Make this a Pascal string (Yuck!) */
    FontName[0] = strlen(p);
    
    FREE( fname );
    
    if ((cp = strchr(FontName, '.')) != NULL)   /* Strip off ".ttf" , if any */
        *cp = 0;
    
    /* Read the font into a buffer */
    if ((map->resid = HOpenResFile(vRefNum, dirID, myName, fsRdPerm)) == -1)
        goto File_Fail;
    
    if ((map->handle = Get1NamedResource('sfnt', FontName)) == NULL)
        goto Map_Fail;
    
    HLock(map->handle);
    map->base   = *map->handle;
    map->offset = 0;
    map->size   = GetResourceSizeOnDisk(map->handle);

    if ( map->base == NULL )
        goto Lock_Fail;

    stream_rec->map = map;
    stream_rec->pos = 0;

#ifndef TT_CONFIG_OPTION_THREAD_SAFE
    CUR_Stream = stream_rec;
#endif

    return TT_Err_Ok;

  Lock_Fail:
    ReleaseResource(map->handle);
    
  Map_Fail:
    CloseResFile(map->resid);

  File_Fail:
    error = TT_Err_Could_Not_Open_File;
    FREE( map );

  Memory_Fail:
    FREE( *stream );
    FREE( fname );
    return error;
  }


/*******************************************************************
 *
 *  Function    : TT_Close_Stream
 *
 *  Description : Closes a stream.
 *
 *  Input  :  stream
 *
 *  Output :  SUCCESS (always)
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  TT_Close_Stream( TT_Stream*  stream )
  {
    PStream_Rec  rec = STREAM2REC( *stream );


    Release_Map( rec->map );
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
    /* XXX - DUMMY IMPLEMENTATION */
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
 *  Output :  Length of stream in bytes.            
 *
 ******************************************************************/

  EXPORT_FUNC
  Long  TT_Stream_Size( TT_Stream  stream )
  {
    PStream_Rec  rec = STREAM2REC( stream );


    if ( rec )
      return rec->map->size;
    else
      return 0;  /* invalid stream - return 0 */
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
    if ( position > CUR_Stream->map->size )
      return TT_Err_Invalid_File_Offset;

    CUR_Stream->pos = position;

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
 *  Output :  see TT_Seek_File
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Skip_File( STREAM_ARGS Long  distance )
  {
    return TT_Seek_File( STREAM_VARS CUR_Stream->pos + distance );
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
  TT_Error  TT_Read_File( STREAM_ARGS void*  buffer, Long  count )
  {
    if ( CUR_Stream->pos + count > CUR_Stream->map->size )
      return TT_Err_Invalid_File_Read;

    MEM_Copy( buffer,
              MAP_Address( CUR_Stream->map ) + CUR_Stream->pos, count );
    CUR_Stream->pos += count;

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
 *  Output :  SUCCESS on success. FAILURE if error.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Read_At_File( STREAM_ARGS Long   position,
                                         void*  buffer,
                                         Long   count )
  {
    TT_Error  error;


    if ( (error = TT_Seek_File( STREAM_VARS position ))      || 
         (error = TT_Read_File( STREAM_VARS buffer, count )) )
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
    return CUR_Stream->pos;
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
 *  Output :  Error code
 *
 *  Notes:    The function fails if the byte range is not within the
 *            the file, or if there is not enough memory to cache
 *            the bytes properly (which usually means that aSize is
 *            too big in both cases).
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Access_Frame( STREAM_ARGS FRAME_ARGS Long  size )
  {
    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    if ( CUR_Stream->pos + size > CUR_Stream->map->size )
      return TT_Err_Invalid_Frame_Access;

    CUR_Frame.size    = size;
    CUR_Frame.address = MAP_Address( CUR_Stream->map ) + CUR_Stream->pos;
    CUR_Frame.cursor  = CUR_Frame.address;

    CUR_Stream->pos += size;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Check_And_Access_Frame
 *
 *  Description :  Notifies the component that we're going to read
 *                 'size' bytes from the current file position.
 *                 This function should load/cache/map these bytes
 *                 so that they will be addressed by the GET_xxx()
 *                 functions easily.
 *
 *  Input  :  size   number of bytes to access.
 *
 *  Output :  Error code
 *
 *  Notes:    The function truncates 'size' if the byte range is not 
 *            within the file.
 *
 *            It will fail if there is not enough memory to cache
 *            the bytes properly (which usually means that aSize is
 *            too big).
 *
 *            It will fail if you make two consecutive calls
 *            to TT_Access_Frame(), without a TT_Forget_Frame() between
 *            them.
 *
 *            The only difference with TT_Access_Frame() is that we
 *            check that the frame is within the current file.  We
 *            otherwise truncate it.  The 'overflow' is set to zero.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Check_And_Access_Frame( STREAM_ARGS FRAME_ARGS Long  size )
  {
    TT_Error  error;
    Long      readBytes;


    if ( CUR_Frame.address != NULL )
      return TT_Err_Nested_Frame_Access;

    readBytes = CUR_Stream->map->size - CUR_Stream->pos;
    if ( size > readBytes )
    {
      /* There is overflow, we allocate a new block then */
      if ( ALLOC( CUR_Frame.address, size ) )
        return error;

      CUR_Frame.size = size;

      /* copy the valid part */
      MEM_Copy( CUR_Frame.address, 
                MAP_Address( CUR_Stream->map ) + CUR_Stream->pos,
                readBytes );
    }
    else
    {
      CUR_Frame.size    = size;
      CUR_Frame.address = MAP_Address( CUR_Stream->map ) + CUR_Stream->pos;
    }

    CUR_Frame.cursor = CUR_Frame.address;
    return TT_Err_Ok;
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

    /* If we were using a duplicate in case of overflow, free it now */
    if ( CUR_Frame.address < (Byte*)CUR_Stream->map->base ||
         CUR_Frame.address >= (Byte*)CUR_Stream->map->base +
         CUR_Stream->map->size )
      FREE( CUR_Frame.address );

    ZERO_Frame( files.frame );

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  GET_Byte
 *
 *  Description :  Extracts a byte from the current file frame.
 *
 *  Input  :  None or current frame
 *
 *  Output :  Extracted Byte
 *
 *  NOTES : We consider that the programmer is intelligent enough
 *          not to try to get a byte that is out of the frame.  Hence,
 *          we provide no bounds check here. (A misbehaving client
 *          could easily page fault using this call.)
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
 *  Output :  Extracted char
 *
 *  NOTES : We consider that the programmer is intelligent enough
 *          not to try to get a byte that is out of the frame.  Hence,
 *          we provide no bounds check here. (A misbehaving client
 *          could easily page fault using this call.)
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
 *  Output :  Extracted short
 *
 *  NOTES : We consider that the programmer is intelligent enough
 *          not to try to get a byte that is out of the frame.  Hence,
 *          we provide no bounds check here. (A misbehaving client
 *          could easily page fault using this call.)
 *
 ******************************************************************/

  EXPORT_FUNC
  Short  TT_Get_Short( FRAME_ARG )
  {
    Short  getshort;


    CHECK_FRAME( CUR_Frame, 2 );

    getshort = ((Short)CUR_Frame.cursor[0] << 8) |
                (Short)CUR_Frame.cursor[1];

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
 *  Output :  Extracted ushort
 *
 *  NOTES : We consider that the programmer is intelligent enough
 *          not to try to get a byte that is out of the frame.  Hence,
 *          we provide no bounds check here. (A misbehaving client
 *          could easily page fault using this call.)
 *
 ******************************************************************/

#if 0

  EXPORT_FUNC
  UShort  TT_Get_UShort( FRAME_ARG )
  {
    UShort  getshort;


    CHECK_FRAME( CUR_Frame, 2 );

    getshort = ((UShort)CUR_Frame.cursor[0] << 8) |
                (UShort)CUR_Frame.cursor[1];

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
 *  Output :  Extracted long
 *
 *  NOTES : We consider that the programmer is intelligent enough
 *          not to try to get a byte that is out of the frame.  Hence,
 *          we provide no bounds check here. (A misbehaving client
 *          could easily page fault using this call.)
 *
 ******************************************************************/

  EXPORT_FUNC
  Long  TT_Get_Long( FRAME_ARG )
  {
    Long  getlong;


    CHECK_FRAME( CUR_Frame, 4 );

    getlong = ((Long)CUR_Frame.cursor[0] << 24) |
              ((Long)CUR_Frame.cursor[1] << 16) |
              ((Long)CUR_Frame.cursor[2] << 8 ) |
               (Long)CUR_Frame.cursor[3];

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
 *  Output :  Extracted ulong
 *
 *  NOTES : We consider that the programmer is intelligent enough
 *          not to try to get a byte that is out of the frame.  Hence,
 *          we provide no bounds check here. (A misbehaving client
 *          could easily page fault using this call.)
 *
 ******************************************************************/

#if 0

  EXPORT_FUNC
  ULong  TT_Get_ULong( FRAME_ARG )
  {
    ULong  getlong;


    CHECK_FRAME( CUR_Frame, 4 );

    getlong = ( ((ULong)CUR_Frame.cursor[0] << 24) |
                ((ULong)CUR_Frame.cursor[1] << 16) |
                ((ULong)CUR_Frame.cursor[2] << 8 ) |
                 (ULong)CUR_Frame.cursor[3] );

    CUR_Frame.cursor += 4;

    return getlong;
  }

#endif


/* END */
