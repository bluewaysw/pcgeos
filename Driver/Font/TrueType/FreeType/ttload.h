/*******************************************************************
 *
 *  ttload.h                                                    1.1
 *
 *    TrueType Tables Loader.
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
 *
 *  Changes between 1.1 and 1.0 :
 *
 *  - add function Load_TrueType_Any used by TT_Get_Font_Data
 *
 ******************************************************************/

#ifndef TTLOAD_H
#define TTLOAD_H

#include "ttconfig.h"
#include "tttypes.h"
#include "ttobjs.h"

#ifdef __cplusplus
  extern "C" {
#endif

  EXPORT_DEF
  Short  TT_LookUp_Table( PFace  face, ULong  tag  );

  LOCAL_DEF TT_Error  Load_TrueType_Directory        ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_MaxProfile       ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_Gasp             ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_Header           ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_Locations        ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_Names            ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_CVT              ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_CMap             ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_Programs         ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_OS2              ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_PostScript       ( PFace  face );
  LOCAL_DEF TT_Error  Load_TrueType_Hdmx             ( PFace  face );

  LOCAL_DEF TT_Error  Load_TrueType_Metrics_Header( PFace  face,
                                                    Bool   vertical );
/*
  LOCAL_DEF TT_Error  Load_TrueType_Any( PFace  face,
                                         ULong  tag,
                                         Long   offset,
                                         void*  buffer,
                                         Long*  length );
*/
  LOCAL_DEF TT_Error  Free_TrueType_Names( PFace  face );
  LOCAL_DEF TT_Error  Free_TrueType_Hdmx ( PFace  face );


/* The following macros are defined to simplify the writing of */
/* the various table and glyph loaders.                        */

/* For examples see the code in ttload.c, ttgload.c etc.       */

#define USE_Stream( original, duplicate ) \
          ( (error = TT_Use_Stream( original, &duplicate )) != TT_Err_Ok )

#define DONE_Stream( _stream ) \
          TT_Done_Stream( &_stream )

/* Define a file frame -- use it only when needed */
#define DEFINE_A_FRAME   TFileFrame  frame = TT_Null_FileFrame

/* Define a stream -- use it only when needed */
#define DEFINE_A_STREAM  TT_Stream   stream


#ifdef TT_CONFIG_OPTION_THREAD_SAFE  /* re-entrant implementation */

/* The following macros define the necessary local */
/* variables used to access streams and frames.    */

/* Define stream locals with frame */
#define DEFINE_STREAM_LOCALS  \
          TT_Error  error;    \
          DEFINE_A_STREAM;    \
          DEFINE_A_FRAME

/* Define stream locals without frame */
#define DEFINE_STREAM_LOCALS_WO_FRAME  \
          TT_Error  error;             \
          DEFINE_A_STREAM

/* Define locals with a predefined stream in reentrant mode -- see ttload.c */
#define DEFINE_LOAD_LOCALS( STREAM )  \
          TT_Error  error;            \
          DEFINE_A_STREAM = (STREAM); \
          DEFINE_A_FRAME

/* Define locals without frame with a predefined stream - see ttload.c */
#define DEFINE_LOAD_LOCALS_WO_FRAME( STREAM ) \
          TT_Error      error;                \
          DEFINE_A_STREAM = (STREAM)

/* Define all locals necessary to access a font file */
#define DEFINE_ALL_LOCALS  \
          TT_Error  error; \
          DEFINE_A_STREAM; \
          DEFINE_A_FRAME


#define ACCESS_Frame( _size_ ) \
          ( (error = TT_Access_Frame( stream, \
                                      &frame, \
                                      _size_ )) != TT_Err_Ok )
#define CHECK_ACCESS_Frame( _size_ ) \
          ( (error = TT_Check_And_Access_Frame( stream, \
                                                &frame, \
                                                _size_ )) != TT_Err_Ok )
#define FORGET_Frame() \
          ( (void)TT_Forget_Frame( &frame ) )

#if defined(__GEOS__) && !DEBUG_FILE

  #define GET_Byte()    (Byte)  (*frame.cursor++)
  #define GET_Char()    (Char)  (*frame.cursor++)
  #define GET_UShort()  (UShort)(frame.cursor += 2, \
                                 (frame.cursor[-2] << 8) | \
                                  frame.cursor[-1])
  #define GET_Short()   (Short) (frame.cursor += 2, \
                                 (frame.cursor[-2] << 8) | \
                                  frame.cursor[-1])
  
#else

  #define GET_Byte()    TT_Get_Byte  ( &frame )
  #define GET_Char()    TT_Get_Char  ( &frame )
  #define GET_UShort()  TT_Get_UShort( &frame )
  #define GET_Short()   TT_Get_Short ( &frame )

#endif

#define GET_Long()    TT_Get_Long  ( &frame )
#define GET_ULong()   TT_Get_ULong ( &frame )
#define GET_Tag4()    TT_Get_ULong ( &frame )

#define FILE_Pos()    TT_File_Pos ( stream )

#define FILE_Seek( _position_ ) \
          ( (error = TT_Seek_File( stream, \
                                   (Long)(_position_) )) != TT_Err_Ok )
#define FILE_Skip( _distance_ ) \
          ( (error = TT_Skip_File( stream, \
                                   (Long)(_distance_) )) != TT_Err_Ok )
#define FILE_Read( buffer, count ) \
          ( (error = TT_Read_File ( stream, \
                                    buffer, \
                                    count )) != TT_Err_Ok )
#define FILE_Read_At( pos, buffer, count ) \
          ( (error = TT_Read_At_File( stream, \
                                      (Long)(pos), \
                                      buffer, \
                                      count )) != TT_Err_Ok )

#else   /* thread-safe implementation */

/* Define stream locals with frame -- nothing in thread-safe mode */
#define DEFINE_STREAM_LOCALS  \
          TT_Error  error

/* Define stream locals without frame -- nothing in thread-safe mode */
#define DEFINE_STREAM_LOCALS_WO_FRAME \
          TT_Error  error

/* Define locals with a predefined stream in reentrant mode -- see ttload.c */
#define DEFINE_LOAD_LOCALS( STREAM ) \
          TT_Error  error


/* Define locals without frame with a predefined stream - see ttload.c */
#define DEFINE_LOAD_LOCALS_WO_FRAME( STREAM ) \
          TT_Error  error

/* Define all locals necessary to access a font file */
#define DEFINE_ALL_LOCALS  \
          TT_Error  error; \
          DEFINE_A_STREAM


#define ACCESS_Frame( _size_ ) \
          ( (error = TT_Access_Frame( _size_ )) != TT_Err_Ok )
#define CHECK_ACCESS_Frame( _size_ ) \
          ( (error = TT_Check_And_Access_Frame( _size_ )) != TT_Err_Ok )
#define FORGET_Frame() \
          ( (void)TT_Forget_Frame() )

#define GET_Byte()    TT_Get_Byte  ()
#define GET_Char()    TT_Get_Char  ()
#define GET_UShort()  TT_Get_UShort()
#define GET_Short()   TT_Get_Short ()
#define GET_Long()    TT_Get_Long  ()
#define GET_ULong()   TT_Get_ULong ()
#define GET_Tag4()    TT_Get_ULong ()

#define FILE_Pos()    TT_File_Pos()

#define FILE_Seek( _position_ ) \
          ( (error = TT_Seek_File( (Long)(_position_) )) != TT_Err_Ok )
#define FILE_Skip( _distance_ ) \
          ( (error = TT_Skip_File( (Long)(_distance_) )) != TT_Err_Ok )
#define FILE_Read( buffer, count ) \
          ( (error = TT_Read_File ( buffer, \
                                    count )) != TT_Err_Ok )
#define FILE_Read_At( pos, buffer, count ) \
          ( (error = TT_Read_At_File( (Long)(pos), \
                                      buffer, \
                                      (Long)(count) )) != TT_Err_Ok )

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */

#ifdef __cplusplus
  }
#endif

#endif /* TTLOAD_H */


/* END */
