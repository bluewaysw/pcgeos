/*******************************************************************
 *
 *  ftxkern.h                                                   1.0
 *
 *    High-Level API Kerning extension
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
 *  The kerning support is currently part of the engine extensions.
 *
 *  This file should _not_ depend on engine internal types.
 *
 ******************************************************************/

#ifndef FTXKERN_H
#define FTXKERN_H

#include "freetype.h"
#include <heap.h>

#ifdef __cplusplus
extern "C" {
#endif

  /* The kerning support in FreeType is minimal.  This means that  */
  /* we do not try to interpret the kerning data in any way to     */
  /* `cook' it for a user application.  This API lets you access   */
  /* directly the kerning tables found in the TrueType file; it's  */
  /* up to the client application to apply its own processing on   */
  /* these.                                                        */

  /* The reason for this is that we generally do not encourage     */
  /* feature-bloat of the core engine.  Moreover, not all          */
  /* libraries or font servers really need kerning data, or all    */
  /* formats of this data.                                         */

  /************** kerning error codes *****************************/

  /* we choose the class 0x0A for our errors, this should not      */
  /* match with any error code class used in any other extension   */

#define TT_Err_Invalid_Kerning_Table_Format  0x0A00
#define TT_Err_Invalid_Kerning_Table         0x0A01


  /********** structures definitions ******************************/

  /* Remember that all types and function are accessible by client */
  /* applications in this section, and thus should have the `TT_'  */
  /* prefix.                                                       */

  /* format 0 kerning pair */

  struct  TT_Kern_0_Pair_
  {
    TT_UShort  left;   /* index of left  glyph in pair */
    TT_UShort  right;  /* index of right glyph in pair */
    TT_FWord   value;  /* kerning value                */
  };

  typedef struct TT_Kern_0_Pair_  TT_Kern_0_Pair;


  /* format 0 kerning subtable */

  struct  TT_Kern_0_
  {
    TT_UShort  nPairs;          /* number of kerning pairs */

    TT_UShort  searchRange;     /* these values are defined by the TT spec */
    TT_UShort  entrySelector;   /* for table searchs.                      */
    TT_UShort  rangeShift;
    MemHandle  pairsBlock;      /* a table of nPairs `pairs' */
  };

  typedef struct TT_Kern_0_  TT_Kern_0;


  /* format 2 kerning glyph class */

  struct  TT_Kern_2_Class_
  {
    TT_UShort   firstGlyph;   /* first glyph in range                    */
    TT_UShort   nGlyphs;      /* number of glyphs in range               */
    TT_UShort*  classes;      /* a table giving for each ranged glyph    */
                              /* its class offset in the subtable pairs  */
                              /* two-dimensional array                   */
  };

  typedef struct TT_Kern_2_Class_  TT_Kern_2_Class;


  /* format 2 kerning subtable */

  struct TT_Kern_2_
  {
    TT_UShort        rowWidth;   /* length of one row in bytes         */
    TT_Kern_2_Class  leftClass;  /* left class table                   */
    TT_Kern_2_Class  rightClass; /* right class table                  */
    TT_FWord*        array;      /* 2-dimensional kerning values array */
  };

  typedef struct TT_Kern_2_  TT_Kern_2;


  /* kerning subtable */

  struct  TT_Kern_Subtable_
  {
    TT_Bool    loaded;   /* boolean; indicates whether the table is   */
                         /* loaded                                    */
    TT_UShort  version;  /* table version number                      */
    TT_Long    offset;   /* file offset of table                      */
    TT_UShort  length;   /* length of table, _excluding_ header       */
    TT_Byte    coverage; /* lower 8 bit of the coverage table entry   */
    TT_Byte    format;   /* the subtable format, as found in the      */
                         /* higher 8 bits of the coverage table entry */
    union
    {
      TT_Kern_0  kern0;
#ifdef TT_CONFIG_OPTION_SUPPORT_KERN2
      TT_Kern_2  kern2;
#endif
    } t;
  };

  typedef struct TT_Kern_Subtable_  TT_Kern_Subtable;


  struct  TT_Kerning_
  {
    TT_UShort          version;  /* kern table version number. starts at 0 */
    TT_UShort          nTables;  /* number of tables                       */

    TT_Kern_Subtable*  tables;   /* the kerning sub-tables                 */
  };

  typedef struct TT_Kerning_  TT_Kerning;



  /***************** high-level API extension **************************/

  /* Initialize Kerning extension, must be called after                 */
  /* TT_Init_FreeType(). There is no need for a finalizer               */
  EXPORT_DEF
  TT_Error  TT_Init_Kerning_Extension( void );

  /* Note on the implemented mechanism:                                 */

  /* The kerning table directory is loaded with the face through the    */
  /* extension constructor.  However, the tables will only be loaded    */
  /* on demand, as they may represent a lot of data, unnecessary to     */
  /* most applications.                                                 */

  /* Queries a pointer to the kerning directory for the face object     */
  EXPORT_DEF
  TT_Error  TT_Get_Kerning_Directory( TT_Face      face,
                                      TT_Kerning*  directory );

  /* Load the kerning table number `kern_index' in the kerning          */
  /* directory.  The table will stay in memory until the `face'         */
  /* face is destroyed.                                                 */
  EXPORT_DEF
  TT_Error  TT_Load_Kerning_Table( TT_Face    face,
                                   TT_UShort  kern_index );

#ifdef __cplusplus
}
#endif

#endif /* FTXKERN_H */


/* END */
