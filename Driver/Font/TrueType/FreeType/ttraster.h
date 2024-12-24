/*******************************************************************
 *
 *  ttraster.h                                                 v 1.4
 *
 *  The FreeType glyph rasterizer.
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT. By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  NOTES:
 *
 *  This version supports the following:
 *
 *    - direct grayscaling
 *    - sub-banding
 *    - drop-out modes 4 and 5
 *    - second pass for complete drop-out control (bitmap only)
 *    - variable precision
 *
 *
 *   Changes between 1.4 and 1.3:
 *
 *   Mainly performance tunings:
 *
 *   - Line_Down() and Bezier_Down() now use the functions Line_Up()
 *     and Bezier_Up() to do their work.
 *   - optimized Split_Bezier()
 *   - optimized linked lists used during sweeps
 *
 *   Changes between 1.2 and 1.3:
 *
 *     - made the engine optionaly re-entrant.  Saves a lot
 *       of code for a moderate performance hit.
 *
 ******************************************************************/

#ifndef TTRASTER_H
#define TTRASTER_H

#include "ttconfig.h"
#include "freetype.h"  /* for TT_Outline */
#include "ttengine.h"

#ifdef __cplusplus
extern "C" {
#endif

  /* We provide two different builds of the scan-line converter  */
  /* The static build uses global variables and isn't            */
  /* re-entrant.                                                 */
  /* The indirect build is re-entrant but accesses all variables */
  /* indirectly.                                                 */
  /*                                                             */
  /* As a consequence, the indirect build is about 10% slower    */
  /* than the static one on a _Pentium_ (this could get worse    */
  /* on older processors), but the code size is reduced by       */
  /* more than 30% !                                             */
  /*                                                             */
  /* The indirect build is now the default, defined in           */
  /* ttconfig.h.  Be careful if you experiment with this.        */

  /* Note also that, though its code can be re-entrant, the      */
  /* component is always used in thread-safe mode.  This is      */
  /* simply due to the fact that we want to use a single         */
  /* render pool (of 64 Kb), and not to waste memory.            */

#ifdef TT_STATIC_RASTER

#define  RAS_ARGS  /* void */
#define  RAS_ARG   /* void */

#define  RAS_VARS  /* void */
#define  RAS_VAR   /* void */

#else

#define  RAS_ARGS  TRaster_Instance*  raster,
#define  RAS_ARG   TRaster_Instance*  raster

#define  RAS_VARS  raster,
#define  RAS_VAR   raster

#endif


  struct  TRaster_Instance_;
  typedef struct TRaster_Instance_  TRaster_Instance;

  /* Render one glyph in the target bitmap, using drop-out control */
  /* mode 'scan'.                                                  */
  LOCAL_DEF
  TT_Error  Render_Bitmap_Glyph( RAS_ARGS TT_Outline*     glyph,
                                   TT_Raster_Map*  target );

#ifdef TT_CONFIG_OPTION_GRAY_SCALING
  /* Render one gray-level glyph in the target pixmap.              */
  /* Palette points to an array of 5 colors used for the rendering. */
  /* Use NULL to reuse the last palette. Default is VGA graylevels. */
  LOCAL_DEF
  TT_Error  Render_Gray_Glyph( RAS_ARGS TT_Outline*     glyph,
                                        TT_Raster_Map*  target,
                                        Byte*           palette );
#endif

#ifdef __GEOS__
  /* Render one glyph in the target region, using drop-out control */
  /* mode 'scan'.                                                  */
  LOCAL_DEF
  TT_Error  Render_Region_Glyph( RAS_ARGS TT_Outline*     glyph,
                                          TT_Raster_Map*  target );
                                          
#endif  /* __GEOS__ */

  /* Initialize rasterizer */
  LOCAL_DEF
  TT_Error  TTRaster_Init( );

  /* Finalize it */
  LOCAL_DEF
  TT_Error  TTRaster_Done( );


#ifdef __cplusplus
}
#endif

#endif /* TTRASTER_H */


/* END */
