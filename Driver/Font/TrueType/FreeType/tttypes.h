/*******************************************************************
 *
 *  tttypes.h
 *
 *    Freetype engine's common types specification
 *    (this spec has no associated body).
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT. By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  NOTE:
 *
 *   All these declarations are library internals, and *not* part
 *   of the high-level interface.  See also 'freetype.h'.
 *
 ******************************************************************/

#ifndef TTTYPES_H
#define TTTYPES_H

#include "ttconfig.h"
#include "freetype.h"

#ifdef __MACTYPES__
#error "<MacTypes.h> have been included, and this prevents the proper\
 compilation of this library.  Please remove the precompiled headers."
#endif

  typedef          char   String;
  typedef signed   char   Char;
  typedef unsigned char   Byte;

  typedef unsigned short  UShort;
  typedef signed   short  Short;

  typedef unsigned long   ULong;
  typedef signed   long   Long;

  typedef TT_Int32        Fixed;

  typedef int             Int;

  /* Simple access types: pointers and tables */

  typedef Byte*    PByte;
  typedef UShort*  PUShort;
  typedef Short*   PShort;
  typedef ULong*   PULong;
  typedef Long*    PLong;

  typedef Fixed*   PFixed;

  typedef Int*     PInt;

  typedef void*    Pointer;

  typedef TT_F26Dot6*     PCoordinates;
  typedef unsigned char*  PTouchTable;


#ifndef Bool
  typedef int  Bool;        /* No boolean type in C */
#endif

#ifndef TRUE
#define TRUE  1
#endif

#ifndef FALSE
#define FALSE  0
#endif

#ifndef NULL
#define NULL  (void*)0
#endif

  typedef Long      Storage;
  typedef Storage*  PStorage;


/* Rounding mode constants */

#define TT_Round_Off             5
#define TT_Round_To_Half_Grid    0
#define TT_Round_To_Grid         1
#define TT_Round_To_Double_Grid  2
#define TT_Round_Up_To_Grid      4
#define TT_Round_Down_To_Grid    3
#define TT_Round_Super           6
#define TT_Round_Super_45        7


/* Touch flag masks */

#define TT_Flag_On_Curve      1
#define TT_Flag_Touched_X     2
#define TT_Flag_Touched_Y     4
#define TT_Flag_Touched_Both  6


/* Error management constants :) */

#define SUCCESS  0
#define FAILURE  -1


/* The min and max functions missing in C.  As usual, be careful not to */
/* write things like MIN( a++, b++ ) to avoid side effects.             */

#ifndef MIN
#define MIN( a, b )  ( (a) < (b) ? (a) : (b) )
#endif

#ifndef MAX
#define MAX( a, b )  ( (a) > (b) ? (a) : (b) )
#endif

#ifndef ABS
#define ABS( a )     ( (a) < 0 ? -(a) : (a) )
#endif

/* conversion macros for the handles defined in freetype.h */

#define HANDLE_Val( handle )       ((handle).z)

#define HANDLE_Engine( handle )    ((PEngine_Instance)HANDLE_Val( handle ))

#define HANDLE_Face( handle )      ((PFace)HANDLE_Val( handle ))

#define HANDLE_Instance( handle )  ((PInstance)HANDLE_Val( handle ))

/* HANDLE_Stream( handle ) must be defined in ttfile.c */

#define HANDLE_Glyph( handle )     ((PGlyph)HANDLE_Val( handle ))

#define HANDLE_CharMap( handle )   ((PCMapTable)HANDLE_Val( handle ))

#define HANDLE_Set( handle, val )  ((handle).z = (void*)(val))


#endif /* TTTYPES_H */


/* END */
