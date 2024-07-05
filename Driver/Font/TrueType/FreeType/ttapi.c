/*******************************************************************
 *
 *  ttapi.c
 *
 *    High-level interface implementation
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used,
 *  modified, and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  Notes:
 *
 *    This file is used to implement most of the functions that are
 *    defined in the file "freetype.h". However, two functions are
 *    implemented elsewhere :
 *
 *     TT_MulDiv and TT_MulFix  are in ttcalc.h/ttcalc.c
 *
 ******************************************************************/

#include "ttconfig.h"

#include "freetype.h"
#include "ttengine.h"
#include "ttcalc.h"
#include "ttmemory.h"
#include "ttcache.h"
#include "ttfile.h"
#include "ttobjs.h"
#include "ttload.h"
#include "ttgload.h"
#include "ttraster.h"
#include "ttextend.h"
#include <geos.h>


/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_api

#ifdef __GEOS__
extern TEngine_Instance engineInstance;
#endif  /* __GEOS__ */


#ifdef TT_STATIC_RASTER
#define RAS_OPS  /* void */
#else
#define RAS_OPS  ((TRaster_Instance*)_engine->raster_component),
#endif /* TT_STATIC_RASTER */


#define RENDER_Glyph( glyph, target ) \
          Render_Glyph( RAS_OPS  glyph, target )

#define RENDER_Gray_Glyph( glyph, target, palette ) \
          Render_Gray_Glyph( RAS_OPS  glyph, target, palette )

#define RENDER_Region_Glyph( glyph, target ) \
          Render_Region_Glyph( RAS_OPS glyph, target )



/*******************************************************************
 *
 *  Function    : TT_Init_FreeType
 *
 *  Description : The library's engine initializer.  This function
 *                must be called prior to any call.
 *
 *  Input  :  void
 *
 *  Output :  Error code.
 *
 *  MT-Note : This function should be called each time you want
 *            to create an TEngine_Instance. It is not necessarily 
 *            thread safe depending on the implementations of ttmemory,
 *            ttfile and ttmutex, so take care.  Their default
 *            implementations are safe, however.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Init_FreeType( void )
  {
    PEngine_Instance  _engine = &engineInstance;
    TT_Error          error;


    /* first of all, initialize memory sub-system */
    error = TTMemory_Init();
    if ( error )
      return error;

#undef  TT_FAIL
#define TT_FAIL( x )  ( error = x (_engine) ) != TT_Err_Ok

    /* Initalize components */
    if ( TT_FAIL( TTFile_Init  )  ||
         TT_FAIL( TTCache_Init )  ||
#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
         TT_FAIL( TTExtend_Init ) ||
#endif
         TT_FAIL( TTObjs_Init )   ||
         TT_FAIL( TTRaster_Init ) )
       goto Fail;

#undef TT_FAIL

    return TT_Err_Ok;

  Fail:
    TT_Done_FreeType();
    return error;
  }


/*******************************************************************
 *
 *  Function    : TT_Done_FreeType
 *
 *  Description : The library's engine finalizer.  This function
 *                will discard all active face and glyph objects
 *                from the heap.
 *
 *  Input  :  void
 *
 *  Output :  Error code.
 *
 *  MT-Note : Destroys an engine.  Not necessarily thread-safe
 *            depending on the implementations of ttmemory,
 *            ttfile and ttmutex.  The default implementations
 *            are safe, however.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Done_FreeType( void )
  {
    PEngine_Instance  _engine = &engineInstance;


    TTRaster_Done( _engine );
    TTObjs_Done  ( _engine );
#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
    TTExtend_Done( _engine );
#endif
    TTCache_Done ( _engine );
    TTFile_Done  ( _engine );

    TTMemory_Done();

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Open_Face
 *
 *  Description :  Creates a new face object from a given font file.
 *
 *  Input  :  fontPathName  the font file's pathname
 *            face          adress of returned face handle
 *
 *  Output :  Error code.
 *
 *  Note :    The face handle is set to NULL in case of failure.
 *
 *  MT-Note : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Open_Face( const FileHandle  file,
                          TT_Face*          face )
  {
    PEngine_Instance  _engine = &engineInstance;

    TFont_Input  input;
    TT_Error     error;
    TT_Stream    stream;
    PFace        _face;


    /* open the file */
    error = TT_Open_Stream( file, &stream );
    if ( error )
      return error;

    input.stream    = stream;
    input.engine    = _engine;

    /* Create and load the new face object - this is thread-safe */
    error = CACHE_New( _engine->objs_face_cache,
                       _face,
                       &input );

    /* Set the handle */
    HANDLE_Set( *face, _face );

    if ( error )
      goto Fail;

    return TT_Err_Ok;

  Fail:
    TT_Close_Stream( &stream );
    return error;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Face_Properties
 *
 *  Description :  Returns face properties.
 *
 *  Input  :  face          the face handle
 *            properties    address of target properties record
 *
 *  Output :  Error code.
 *
 *  Note :    Currently, max_Faces is always set to 0.
 *
 *  MT-Note : YES!  Reads only permanent data.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Face_Properties( TT_Face              face,
                                    TT_Face_Properties*  properties )
  {
    PFace _face = HANDLE_Face( face );


    if ( !_face )
      return TT_Err_Invalid_Face_Handle;

    properties->num_Glyphs   = _face->numGlyphs;
    properties->max_Points   = _face->maxPoints;
    properties->max_Contours = _face->maxContours;
    properties->num_CharMaps = _face->numCMaps;
    properties->num_Names    = _face->nameTable.numNameRecords;

    properties->header       = &_face->fontHeader;
    properties->horizontal   = &_face->horizontalHeader;

#ifdef TT_CONFIG_OPTION_PROCESS_VMTX
    if ( _face->verticalInfo )
      properties->vertical   = &_face->verticalHeader;
    else
      properties->vertical   = NULL;
#endif

    properties->os2          = &_face->os2;
    properties->postscript   = &_face->postscript;

  #ifdef TT_CONFIG_OPTION_PROCESS_HDMX
    properties->hdmx         = &_face->hdmx;
  #endif

    return TT_Err_Ok;
  }


#ifndef __GEOS__
/*******************************************************************
 *
 *  Function    :  TT_Get_Face_Metrics
 *
 *  Description :  This function returns the original horizontal AND
 *                 vertical metrics as found in the "hmtx" and "vmtx"
 *                 tables.  These are the glyphs' left-side-bearings
 *                 and advance widths (horizontal), as well as top
 *                 side bearings and advance heights (vertical).
 *
 *                 All are expressed in FONT UNITS, a.k.a. EM
 *                 units.
 *
 *  Input  :     face  The given face handle.
 *              first  Index of first glyph in table.
 *               last  Index of last glyph in table.
 *
 *       leftBearings  A pointer to an array of TT_Shorts where the
 *                     left side bearings for the glyphs 'first'
 *                     to 'last' will be returned.  If these metrics
 *                     don't interest you, simply set it to NULL.
 *
 *             widths  A pointer to an array of TT_UShorts
 *                     where the advance widths for the glyphs
 *                     'first' to 'last' will be returned.  If these
 *                     metrics don't interest you, simply set it
 *                     to NULL.
 *
 *        topBearings  A pointer to an array of TT_Shorts where the
 *                     top side bearings for the glyphs 'first'
 *                     to 'last' will be returned.  If these metrics
 *                     don't interest you, simply set it to NULL.
 *
 *            heights  A pointer to an array of TT_UShorts
 *                     where the advance heights for the glyphs
 *                     'first' to 'last' will be returned.  If these
 *                     metrics don't interest you, simply set it
 *                     to NULL.
 *
 *  Output :  Error code.
 *
 *  IMPORTANT NOTE :
 *
 *  As vertical metrics are optional in a TrueType font, this
 *  function will return an error ( TT_Err_No_Vertical_Data )
 *  whenever this function is called on such a face with non-NULL
 *  'topBearings' or 'heights' arguments.
 *
 *  When a font has no vertical data, the 'vertical' field in its
 *  properties structure is set to NULL.
 *
 *  MT-Note : YES!  Reads only permanent data.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Face_Metrics( TT_Face     face,
                                 TT_UShort   firstGlyph,
                                 TT_UShort   lastGlyph,
                                 TT_Short*   leftBearings,
                                 TT_UShort*  widths,
                                 TT_Short*   topBearings,
                                 TT_UShort*  heights )
  {
    PFace   _face = HANDLE_Face( face );
    UShort  num;


    if ( !_face )
      return TT_Err_Invalid_Face_Handle;

    // Check the glyph range
    if ( lastGlyph >= _face->numGlyphs || firstGlyph > lastGlyph )
      return TT_Err_Invalid_Argument;

    num = lastGlyph - firstGlyph;   // number of elements-1 in each array

    // store the left side bearings and advance widths first
    {
      UShort  n;
      Short   left_bearing;
      UShort  advance_width;


      for ( n = 0; n <= num; ++n )
      {
        TT_Get_Metrics( &_face->horizontalHeader,
                        firstGlyph + n, &left_bearing, &advance_width );

        if ( leftBearings )  leftBearings[n] = left_bearing;
        if ( widths )        widths[n]       = advance_width;
      }
    }

    // check for vertical data if topBearings or heights is non-NULL
    if ( !topBearings && !heights )
      return TT_Err_Ok;

    if ( !_face->verticalInfo )
      return TT_Err_No_Vertical_Data;

    // store the top side bearings
    {
      UShort  n;
      Short   top_bearing;
      UShort  advance_height;

      for ( n = 0; n <= num; ++n )
      {
        TT_Get_Metrics( (TT_Horizontal_Header*)&_face->verticalHeader,
                        firstGlyph + n, &top_bearing, &advance_height );

        if ( topBearings )  topBearings[n] = top_bearing;
        if ( heights )      heights[n]     = advance_height;
      }
    }

    return TT_Err_Ok;
  }
#endif  /* __GEOS__ */


/*******************************************************************
 *
 *  Function    :  TT_Flush_Face
 *
 *  Description :  This function is used to close an active face's
 *                 file handle or descriptor.  This is useful to save
 *                 system resources, if your application uses tons
 *                 of fonts.
 *
 *  Input  :  face    the given face handle
 *
 *  Output :  Error code.
 *
 *  MT-Note : YES!  (If ttfile is.)
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Flush_Face( TT_Face  face )
  {
    PFace  faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;
    else
      return TT_Flush_Stream( &faze->stream );
  }
*/

/*******************************************************************
 *
 *  Function    :  TT_Close_Face
 *
 *  Description :  Closes an opened face object.  This function
 *                 will destroy all objects associated to the
 *                 face, except the glyphs.
 *
 *  Input  :  face    the given face handle
 *
 *  Output :  Error code.
 *
 *  NOTE   :  The handle is set to NULL on exit.
 *
 *  MT-Note : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Close_Face( TT_Face  face )
  {
    PFace  _face = HANDLE_Face( face );


    if ( !_face )
      return TT_Err_Invalid_Face_Handle;

    TT_Close_Stream( &_face->stream );

    /* delete the face object -- this is thread-safe */
    return CACHE_Done( _face->engine->objs_face_cache, _face );
  }


/*******************************************************************
 *
 *  Function    :  TT_New_Instance
 *
 *  Description :  Creates a new instance from a given face.
 *
 *  Input  :  face        parent face handle
 *            instance    address of instance handle
 *
 *  Output :  Error code.
 *
 *  Note   :  The handle is set to NULL in case of failure.
 *
 *  MT-Note : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_New_Instance( TT_Face       face,
                             TT_Instance*  instance )
  {
    TT_Error   error;
    PFace      _face = HANDLE_Face( face );
    PInstance  _ins;


    if ( !_face )
      return TT_Err_Invalid_Face_Handle;

    /* get a new instance from the face's cache -- this is thread-safe */
    error = CACHE_New( &_face->instances, _ins, _face );

    HANDLE_Set( *instance, _ins );

    if ( !error )
    {
      error = Instance_Init( _ins );
      if ( error )
      {
        HANDLE_Set( *instance, NULL );
        CACHE_Done( &_face->instances, _ins );
      }
    }

    return error;
  }


/*******************************************************************
 *
 *  Function    :  TT_Set_Instance_Resolutions
 *
 *  Description :  Resets an instance to a new device resolution.
 *
 *  Input  :  instance      the instance handle
 *            xResolution   new horizontal device resolution in dpi
 *            yResolution   new vertical device resolution in dpi
 *
 *  Output :  Error code.
 *
 *  Note :    There is no check for overflow; with other words,
 *            the product of glyph dimensions times the device
 *            resolutions must have reasonable values.
 *
 *  MT-Note : You should set the charsize or pixel size immediately
 *            after this call in multi-threaded programs.  This will
 *            force the instance data to be resetted.  Otherwise, you
 *            may encounter corruption when loading two glyphs from
 *            the same instance concurrently!
 *
 *            Happily, 99.99% will do just that :-)
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Set_Instance_Resolutions( TT_Instance  instance,
                                         TT_UShort    xResolution,
                                         TT_UShort    yResolution )
  {
    PInstance  ins = HANDLE_Instance( instance );


    if ( !ins )
      return TT_Err_Invalid_Instance_Handle;

    ins->metrics.x_resolution = xResolution;
    ins->metrics.y_resolution = yResolution;
    ins->valid                = FALSE; */

    /* In the case of a thread-safe implementation, we immediately    */
    /* call Instance_Reset in order to change the instance's variable */

    /* In the case of a non-threaded build, we simply set the 'valid' */
    /* flag to FALSE, which will force the instance's resetting at    */
    /* the next glyph loading                                         */

/*    return TT_Err_Ok;
  } */


/*******************************************************************
 *
 *  Function    :  TT_Set_Instance_CharSize
 *
 *  Description :  Resets an instance to new point size.
 *
 *  Input  :  instance      the instance handle
 *            charSize      the new character size in 26.6 char points
 *
 *  Output :  Error code.
 *
 *  Note :    There is no check for overflow; with other words,
 *            the product of glyph dimensions times the device
 *            resolution must have reasonable values.
 *
 *  MT-Note : NO!  This should be called only when setting/resetting
 *            instances, so there is no need to protect.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Set_Instance_CharSize( TT_Instance  instance,
                                       TT_F26Dot6   charSize )
  {
    PInstance  ins = HANDLE_Instance( instance );


    if ( !ins )
      return TT_Err_Invalid_Instance_Handle;

    if ( charSize < 1 * 64 )
      charSize = 1 * 64;

    ins->metrics.x_scale1 = ( charSize * ins->metrics.x_resolution ) / 72;
    ins->metrics.x_scale2 = ins->owner->fontHeader.Units_Per_EM;

    ins->metrics.y_scale1 = ( charSize * ins->metrics.y_resolution ) / 72;
    ins->metrics.y_scale2 = ins->owner->fontHeader.Units_Per_EM;

    if ( ins->owner->fontHeader.Flags & 8 )
    {
      ins->metrics.x_scale1 = (ins->metrics.x_scale1+32) & -64;
      ins->metrics.y_scale1 = (ins->metrics.y_scale1+32) & -64;
    }

    ins->metrics.x_ppem = ins->metrics.x_scale1 >> 6;
    ins->metrics.y_ppem = ins->metrics.y_scale1 >> 6;
    ins->metrics.pointSize = charSize;

    ins->valid  = FALSE;

    return Instance_Reset( ins );
  }


/*******************************************************************
 *
 *  Function    :  TT_Set_Instance_CharSize
 *
 *  Description :  Resets an instance to new point size.
 *
 *  Input  :  instance      the instance handle
 *            charSize      the new character size in 26.6 char points
 *
 *  Output :  Error code.
 *
 *  Note :    There is no check for overflow; with other words,
 *            the product of glyph dimensions times the device
 *            resolution must have reasonable values.
 *
 *  MT-Note : NO!  This should be called only when setting/resetting
 *            instances, so there is no need to protect.
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Set_Instance_CharSize( TT_Instance  instance,
                                      TT_F26Dot6   charSize )
  {
    return TT_Set_Instance_CharSizes( instance, charSize, charSize );
  }
*/

/*******************************************************************
 *
 *  Function    :  TT_Set_Instance_PixelSizes
 *
 *  Description :  Resets an instance to new pixel sizes
 *
 *  Input  :  instance      the instance handle
 *            pixelWidth    the new width in pixels
 *            pixelHeight   the new height in pixels
 *
 *  Output :  Error code.
 *
 *  Note :    There is no check for overflow; with other words,
 *            the product of glyph dimensions times the device
 *            resolution must have reasonable values.
 *
 *  MT-Note : NO!  This should be called only when setting/resetting
 *            instances, so there is no need to protect.
 *
 ******************************************************************/
 /*
  EXPORT_FUNC
  TT_Error  TT_Set_Instance_PixelSizes( TT_Instance  instance,
                                        TT_UShort    pixelWidth,
                                        TT_UShort    pixelHeight,
                                        TT_F26Dot6   pointSize )
  {
    PInstance  ins = HANDLE_Instance( instance );

    if ( !ins )
      return TT_Err_Invalid_Instance_Handle;

    if ( pixelWidth  < 1 ) pixelWidth = 1;
    if ( pixelHeight < 1 ) pixelHeight = 1;

    ins->metrics.x_ppem    = pixelWidth;
    ins->metrics.y_ppem    = pixelHeight;
    ins->metrics.pointSize = pointSize;

    ins->metrics.x_scale1 = ins->metrics.x_ppem * 64L;
    ins->metrics.x_scale2 = ins->owner->fontHeader.Units_Per_EM;
    ins->metrics.y_scale1 = ins->metrics.y_ppem * 64L;
    ins->metrics.y_scale2 = ins->owner->fontHeader.Units_Per_EM;

    ins->valid = FALSE;

    return Instance_Reset( ins );
  }
*/

/*******************************************************************
 *
 *  Function    :  TT_Set_Instance_Transform_Flags
 *
 *  Description :  Informs the interpreter about the transformations
 *                 that will be applied to the rendered glyphs.
 *
 *  Input  :  instance      the instance handle
 *            rotated       set to TRUE if the glyph are rotated
 *            stretched     set to TRUE if the glyph are stretched
 *
 *  Output :  Error code.
 *
 *  Note :    This function is deprecated!  It's much better to
 *            control hinting manually when calling TT_Load_Glyph
 *            than relying on the font programs...
 *
 *            Never use it, unless calling for trouble ;-)
 *
 *  MT-Note : NO!  This should be called only when setting/resetting
 *            instances, so there is no need to protect.
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Set_Instance_Transform_Flags( TT_Instance  instance,
                                             TT_Bool      rotated,
                                             TT_Bool      stretched )
  {
    PInstance  ins = HANDLE_Instance( instance );


    if ( !ins )
      return TT_Err_Invalid_Instance_Handle;

    ins->metrics.rotated   = rotated;
    ins->metrics.stretched = stretched;
    ins->valid             = FALSE;

    return TT_Err_Ok;
  }*/


/*******************************************************************
 *
 *  Function    :  TT_Get_Instance_Metrics
 *
 *  Description :  Returns instance metrics.
 *
 *  Input  :  instance      the instance handle
 *            metrics       address of target instance metrics record
 *
 *  Output :  Error code.
 *
 *  MT-Note : YES!  Reads only semi-permanent data.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Instance_Metrics( TT_Instance           instance,
                                     TT_Instance_Metrics*  metrics )
  {
    PInstance  ins = HANDLE_Instance( instance );


    if ( !ins )
     return TT_Err_Invalid_Instance_Handle;

    if ( !ins->valid )
      Instance_Reset( ins );

    metrics->pointSize    = ins->metrics.pointSize;

    metrics->x_scale      = TT_MulDiv( 0x10000,
                                       ins->metrics.x_scale1,
                                       ins->metrics.x_scale2 );

    metrics->y_scale      = TT_MulDiv( 0x10000,
                                       ins->metrics.y_scale1,
                                       ins->metrics.y_scale2 );

    metrics->x_resolution = ins->metrics.x_resolution;
    metrics->y_resolution = ins->metrics.y_resolution;
    metrics->x_ppem       = ins->metrics.x_ppem;
    metrics->y_ppem       = ins->metrics.y_ppem;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Done_Instance
 *
 *  Description :  Closes a given instance.
 *
 *  Input  :  instance      address of instance handle
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Done_Instance( TT_Instance  instance )
  {
    PInstance  ins = HANDLE_Instance( instance );


    if ( !ins )
      return TT_Err_Invalid_Instance_Handle;

    /* delete the instance -- this is thread-safe */
    return CACHE_Done( &ins->owner->instances, ins );
  }


/*******************************************************************
 *
 *  Function    :  TT_New_Glyph
 *
 *  Description :  Creates a new glyph object related to a given
 *                 face.
 *
 *  Input  :  face       the face handle
 *            glyph      address of target glyph handle
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_New_Glyph( TT_Face    face,
                          TT_Glyph*  glyph )
  {
    TT_Error  error;
    PFace     _face = HANDLE_Face( face );
    PGlyph    _glyph;


    if ( !_face )
      return TT_Err_Invalid_Face_Handle;

    /* get a new glyph from the face's cache -- this is thread-safe */
    error = CACHE_New( &_face->glyphs, _glyph, _face );

    HANDLE_Set( *glyph, _glyph );

    return error;
  }


/*******************************************************************
 *
 *  Function    :  TT_Done_Glyph
 *
 *  Description :  Destroys a given glyph object.
 *
 *  Input  :  glyph  the glyph handle
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Done_Glyph( TT_Glyph  glyph )
  {
    PGlyph  _glyph = HANDLE_Glyph( glyph );


    if ( !_glyph )
      return TT_Err_Invalid_Glyph_Handle;

    /* delete the engine -- this is thread-safe */
    return CACHE_Done( &_glyph->face->glyphs, _glyph );
  }


/*******************************************************************
 *
 *  Function    :  TT_Load_Glyph
 *
 *  Description :  Loads a glyph.
 *
 *  Input  :  instance      the instance handle
 *            glyph         the glyph handle
 *            glyphIndex    the glyph index
 *            loadFlags     flags controlling how to load the glyph
 *                          (none, scaled, hinted, both)
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Load_Glyph( TT_Instance  instance,
                           TT_Glyph     glyph,
                           TT_UShort    glyphIndex,
                           TT_UShort    loadFlags   )
  {
    PInstance  _ins;
    PGlyph     _glyph;
    TT_Error   error;


    _ins = HANDLE_Instance( instance );

    if ( !_ins )
      loadFlags &= ~(TTLOAD_SCALE_GLYPH | TTLOAD_HINT_GLYPH);

    if ( (loadFlags & TTLOAD_SCALE_GLYPH) == 0 )
      _ins = 0;

    _glyph = HANDLE_Glyph( glyph );
    if ( !_glyph )
      return TT_Err_Invalid_Glyph_Handle;

    if ( _ins )
    {
      if ( _ins->owner != _glyph->face )
        return TT_Err_Invalid_Face_Handle;

      if ( !_ins->valid )
      {
        /* This code can only be called in non thread-safe builds */
        error = Instance_Reset( _ins );
        if ( error )
          return error;
      }
    }

    return Load_TrueType_Glyph( _ins, _glyph, glyphIndex, loadFlags );
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Glyph_Outline
 *
 *  Description :  Returns the glyph's outline data.
 *
 *  Input  :  glyph     the glyph handle
 *            outline   address where the glyph outline will be returned
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!  Reads only semi-permanent data.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Glyph_Outline( TT_Glyph     glyph,
                                  TT_Outline*  outline )
  {
    PGlyph  _glyph = HANDLE_Glyph( glyph );


    if ( !_glyph )
      return TT_Err_Invalid_Glyph_Handle;

    *outline = _glyph->outline;
    outline->owner = FALSE;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Glyph_Metrics
 *
 *  Description :  Extracts the glyph's horizontal metrics information.
 *
 *  Input  :  glyph       glyph object handle
 *            metrics     address where metrics will be returned
 *
 *  Output :  Error code.
 *
 *  MT-Safe : NO!  Glyph containers can't be shared.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Glyph_Metrics( TT_Glyph           glyph,
                                  TT_Glyph_Metrics*  metrics )
  {
    PGlyph  _glyph = HANDLE_Glyph( glyph );


    if ( !_glyph )
      return TT_Err_Invalid_Glyph_Handle;

    metrics->bbox     = _glyph->metrics.bbox;
    metrics->bearingX = _glyph->metrics.horiBearingX;
    metrics->bearingY = _glyph->metrics.horiBearingY;
    metrics->advance  = _glyph->metrics.horiAdvance;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Glyph_Big_Metrics
 *
 *  Description :  Extracts the glyph's big metrics information.
 *
 *  Input  :  glyph       glyph object handle
 *            metrics     address where big metrics will be returned
 *
 *  Output :  Error code.
 *
 *  MT-Safe : NO!  Glyph containers can't be shared.
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Get_Glyph_Big_Metrics( TT_Glyph               glyph,
                                      TT_Big_Glyph_Metrics*  metrics )
  {
    PGlyph  _glyph = HANDLE_Glyph( glyph );


    if ( !_glyph )
      return TT_Err_Invalid_Glyph_Handle;

    *metrics = _glyph->metrics;

    return TT_Err_Ok;
  }
*/

/*******************************************************************
 *
 *  Function    :  TT_Get_Glyph_Bitmap
 *
 *  Description :  Produces a bitmap from a glyph outline.
 *
 *  Input  :  glyph      the glyph container's handle
 *            map        target pixmap description block
 *            xOffset    x offset in fractional pixels (26.6 format)
 *            yOffset    y offset in fractional pixels (26.6 format)
 *
 *  Output :  Error code.
 *
 *  Note : Only use integer pixel offsets if you want to preserve
 *         the fine hints applied to the outline.  This means that
 *         xOffset and yOffset must be multiples of 64!
 *
 *  MT-Safe : NO!  Glyph containers can't be shared.
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Get_Glyph_Bitmap( TT_Glyph        glyph,
                                 TT_Raster_Map*  map,
                                 TT_F26Dot6      xOffset,
                                 TT_F26Dot6      yOffset )
  {
    PEngine_Instance  _engine;
    TT_Error          error;
    PGlyph            _glyph = HANDLE_Glyph( glyph );

    TT_Outline  outline;


    if ( !_glyph )
      return TT_Err_Invalid_Glyph_Handle;

    _engine = _glyph->face->engine;

    outline = _glyph->outline;
    // XXX : For now, use only dropout mode 2
    // outline.dropout_mode = _glyph->scan_type;
    outline.dropout_mode = 2;

    TT_Translate_Outline( &outline, xOffset, yOffset );
    error = TT_Get_Outline_Bitmap( &outline, map );
    TT_Translate_Outline( &outline, -xOffset, -yOffset );

    return error;
  }
*/


  static const TT_Outline  null_outline
      = { 0, 0, NULL, NULL, NULL, 0, 0, 0, 0 };


/*******************************************************************
 *
 *  Function    :  TT_New_Outline
 *
 *  Description :  Creates a new TrueType outline, reserving
 *                 array space for a given number of points and
 *                 contours.
 *
 *  Input  :  numPoints         number of points
 *            numContours       number of contours
 *            outline           address of target outline structure
 *
 *  Output :  Error code
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_New_Outline( TT_UShort    numPoints,
                            TT_Short     numContours,
                            TT_Outline*  outline )
  {
    TT_Error  error;


    if ( !outline )
      return TT_Err_Invalid_Argument;

    *outline = null_outline;

    if ( ALLOC( outline->points,   numPoints*2*sizeof ( TT_F26Dot6 ) ) ||
         ALLOC( outline->flags,    numPoints  *sizeof ( Byte )       ) ||
         ALLOC( outline->contours, numContours*sizeof ( UShort )     ) )
      goto Fail;

    outline->n_points   = numPoints;
    outline->n_contours = numContours;
    outline->owner      = TRUE;
    return TT_Err_Ok;

  Fail:
    outline->owner = TRUE;
    TT_Done_Outline( outline );
    return error;
  }


/*******************************************************************
 *
 *  Function    :  TT_Done_Outline
 *
 *  Description :  Deletes an outline created through TT_New_Outline().
 *                 Calling this function for outlines returned
 *                 by TT_Get_Glyph_Outline() yields an error.
 *
 *  Input  :  outline        address of outline
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Done_Outline( TT_Outline*  outline )
  {
    if ( outline )
    {
      if ( outline->owner )
      {
        FREE( outline->points   );
        FREE( outline->flags    );
        FREE( outline->contours );
      }
      *outline = null_outline;
      return TT_Err_Ok;
    }
    else
      return TT_Err_Invalid_Argument;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Outline_Bitmap
 *
 *  Description :  Render a TrueType outline into a bitmap.
 *                 Note that the bitmap must be created by the caller.
 *
 *  Input  :  outline        the outline to render
 *            map            the target bitmap
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Outline_Bitmap( TT_Outline*     outline,
                                   TT_Raster_Map*  map )
  {
    PEngine_Instance  _engine = &engineInstance;


    if ( !outline || !map )
      return TT_Err_Invalid_Argument;

    return RENDER_Glyph( outline, map );
  }


#ifdef __GEOS__

/*******************************************************************
 *
 *  Function    :  TT_Get_Outline_Region
 *
 *  Description :  Render a TrueType outline into a region.
 *                 Note that the region must be created by the caller.
 *
 *  Input  :  outline       the outline to render
 *            map           the target region
 *
 *  Output :  Error code
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/
EXPORT_FUNC
TT_Error  TT_Get_Outline_Region( TT_Outline*     outline,
                                 TT_Raster_Map*  map )
{
  PEngine_Instance  _engine = &engineInstance;


  if ( !outline || !map )
    return TT_Err_Invalid_Argument;

  return RENDER_Region_Glyph( outline, map );
}

#endif    /* __GEOS__ */


/*******************************************************************
 *
 *  Function    :  TT_Transform_Outline
 *
 *  Description :  Applies a simple transformation to an outline.
 *
 *  Input  :  outline     the glyph's outline.  Can be extracted
 *                        from a glyph container through
 *                        TT_Get_Glyph_Outline().
 *
 *            matrix      simple matrix with 16.16 fixed floats
 *
 *  Output :  Error code (always TT_Err_Ok).
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  void  TT_Transform_Outline( TT_Outline*  outline,
                              TT_Matrix*   matrix )
  {
    TransVecList( outline->points, outline->n_points, matrix );
  }


/*******************************************************************
 *
 *  Function    :  TT_Transform_Vector
 *
 *  Description :  Apply a simple transform to a vector
 *
 *  Input  :  x, y        the vector.
 *
 *            matrix      simple matrix with 16.16 fixed floats
 *
 *  Output :  None.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  void  TT_Transform_Vector( TT_F26Dot6*  x,
                             TT_F26Dot6*  y,
                             TT_Matrix*   matrix )
  {
    TT_F26Dot6  xz, yz;


    xz = TT_MulFix( *x, matrix->xx ) +
         TT_MulFix( *y, matrix->xy );

    yz = TT_MulFix( *x, matrix->yx ) +
         TT_MulFix( *y, matrix->yy );

    *x = xz;
    *y = yz;
  }


/*******************************************************************
 *
 *  Function    :  TT_Translate_Outline
 *
 *  Description :  Applies a simple translation.
 *
 *  Input  :  outline   no comment :)
 *            xOffset
 *            yOffset
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  void      TT_Translate_Outline( TT_Outline*  outline,
                                  TT_F26Dot6   xOffset,
                                  TT_F26Dot6   yOffset )
  {
    UShort      n;
    TT_Vector*  vec = outline->points;


    for ( n = 0; n < outline->n_points; ++n )
    {
      vec->x += xOffset;
      vec->y += yOffset;
      ++vec;
    }
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Outline_BBox
 *
 *  Description :  Returns an outline's bounding box.
 *
 *  Input  :  outline   no comment :)
 *            bbox      address where the bounding box is returned
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Outline_BBox( TT_Outline*  outline,
                                 TT_BBox*     bbox )
  {
    TT_F26Dot6  x, y;
    UShort      k;


    if ( outline && bbox )
    {
      if ( outline->n_points == 0 )
      {
        bbox->xMin = 0;
        bbox->yMin = 0;
        bbox->xMax = 0;
        bbox->yMax = 0;
      }
      else
      {
        TT_Vector*  vec = outline->points;

        bbox->xMin = bbox->xMax = vec->x;
        bbox->yMin = bbox->yMax = vec->y;
        ++vec;

        for ( k = 1; k < outline->n_points; ++k )
        {
          x = vec->x;
          if ( x < bbox->xMin ) bbox->xMin = x;
          if ( x > bbox->xMax ) bbox->xMax = x;
          y = vec->y;
          if ( y < bbox->yMin ) bbox->yMin = y;
          if ( y > bbox->yMax ) bbox->yMax = y;
          ++vec;
        }
      }
      return TT_Err_Ok;
    }
    else
      return TT_Err_Invalid_Argument;
  }



  /* ----------------- character mappings support ------------- */

/*******************************************************************
 *
 *  Function    :  TT_Get_CharMap_ID
 *
 *  Description :  Returns the ID of a given charmap.
 *
 *  Input  :  face             face object handle
 *            charmapIndex     index of charmap in directory
 *            platformID       address of returned platform ID
 *            encodingID       address of returned encoding ID
 *
 *  Output :  error code
 *
 *  MT-Safe : YES !
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_CharMap_ID( TT_Face     face,
                               TT_UShort   charmapIndex,
                               TT_UShort*  platformID,
                               TT_UShort*  encodingID )
  {
    PCMapTable  cmap;
    PFace       faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    if ( charmapIndex >= faze->numCMaps )
      return TT_Err_Invalid_Argument;

    cmap = faze->cMaps + charmapIndex;

    *platformID = cmap->platformID;
    *encodingID = cmap->platformEncodingID;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_CharMap
 *
 *  Description :  Looks up a charmap.
 *
 *  Input  :  face          face object handle
 *            charmapIndex  index of charmap in directory
 *            charMap       address of returned charmap handle
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_CharMap( TT_Face      face,
                            TT_UShort    charmapIndex,
                            TT_CharMap*  charMap )
  {
    TT_Error    error;
    TT_Stream   stream;
    PCMapTable  cmap;
    PFace       faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    if ( charmapIndex >= faze->numCMaps )
      return TT_Err_Invalid_Argument;

    cmap = faze->cMaps + charmapIndex;

    /* Load table if needed */
    error = TT_Err_Ok;

    if ( !cmap->loaded )
    {
      (void)USE_Stream( faze->stream, stream );
      if ( !error )
      {
        error = CharMap_Load( cmap, stream );
        DONE_Stream( stream );
      }

      if ( error )
        cmap = NULL;
      else
        cmap->loaded = TRUE;
    }

    HANDLE_Set( *charMap, cmap );

    return error;
  }


/*******************************************************************
 *
 *  Function    :  TT_Char_Index
 *
 *  Description :  Returns the glyph index corresponding to
 *                 a given character code defined for the 'charmap'.
 *
 *  Input  :  charMap    charmap handle
 *            charcode   character code
 *
 *  Output :  glyph index.
 *
 *  Notes  :  Character code 0 is the unknown glyph, which should never
 *            be displayed.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_UShort  TT_Char_Index( TT_CharMap  charMap,
                            TT_UShort   charCode )
  {
    PCMapTable  cmap = HANDLE_CharMap( charMap );


    if ( !cmap )
      return 0;  /* we return 0 in case of invalid char map */

    return CharMap_Index( cmap, charCode );
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Name_ID
 *
 *  Description :  Returns the IDs of the string number 'nameIndex'
 *                 in the name table of a given face.
 *
 *  Input  :  face        face handle
 *            nameIndex   index of string. First is 0
 *            platformID  addresses of returned IDs
 *            encodingID
 *            languageID
 *            nameID
 *
 *  Output :  Error code.
 *
 *  Notes  :  Some files have a corrupt or unusual name table, with some
 *            entries having a platformID > 3.  These can usually
 *            be ignored by a client application.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Name_ID( TT_Face     face,
                            TT_UShort   nameIndex,
                            TT_UShort*  platformID,
                            TT_UShort*  encodingID,
                            TT_UShort*  languageID,
                            TT_UShort*  nameID )
  {
    TNameRec*  namerec;
    PFace      faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    if ( nameIndex >= faze->nameTable.numNameRecords )
      return TT_Err_Invalid_Argument;

    namerec = faze->nameTable.names + nameIndex;

    *platformID = namerec->platformID;
    *encodingID = namerec->encodingID;
    *languageID = namerec->languageID;
    *nameID     = namerec->nameID;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Name_String
 *
 *  Description :  Returns the address and length of a given
 *                 string found in the name table.
 *
 *  Input  :  face        face handle
 *            nameIndex   string index
 *            stringPtr   address of returned pointer to string
 *            length      address of returned string length
 *
 *  Output :  Error code.
 *
 *  Notes  :  If the string's platformID is invalid,
 *            stringPtr is NULL, and length is 0.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Get_Name_String( TT_Face      face,
                                TT_UShort    nameIndex,
                                TT_String**  stringPtr,
                                TT_UShort*   length )
  {
    TNameRec*  namerec;
    PFace      faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    if ( nameIndex >= faze->nameTable.numNameRecords )
      return TT_Err_Invalid_Argument;

    namerec = faze->nameTable.names + nameIndex;

    *stringPtr = (String*)namerec->string;
    *length    = namerec->stringLength;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TT_Get_Font_Data
 *
 *  Description :  Loads any font table into client memory.
 *
 *  Input  :  face     Face object to look for.
 *
 *            tag      Tag of table to load.  Use the value 0 if you
 *                     want to access the whole font file, else set
 *                     this parameter to a valid TrueType table tag
 *                     that you can forge with the MAKE_TT_TAG
 *                     macro.
 *
 *            offset   Starting offset in the table (or the file
 *                     if tag == 0).
 *
 *            buffer   Address of target buffer
 *
 *            length   Address of decision variable:
 *
 *                       if length == NULL:
 *                             Load the whole table.  Returns an
 *                             error if 'offset' != 0.
 *
 *                       if *length == 0 :
 *                             Exit immediately, returning the
 *                             length of the given table, or of
 *                             the font file, depending on the
 *                             value of 'tag'.
 *
 *                       if *length != 0 :
 *                             Load the next 'length' bytes of
 *                             table or font, starting at offset
 *                             'offset' (in table or font too).
 *
 *  Output :  Error code.
 *
 *  MT-Safe : YES!
 *
 ******************************************************************/
/*
  EXPORT_FUNC
  TT_Error  TT_Get_Font_Data( TT_Face   face,
                              TT_ULong  tag,
                              TT_Long   offset,
                              void*     buffer,
                              TT_Long*  length )
  {
    PFace faze = HANDLE_Face( face );


    if ( !faze )
      return TT_Err_Invalid_Face_Handle;

    return Load_TrueType_Any( faze, tag, offset, buffer, length );
  }
*/

/* END */
