/*******************************************************************
 *
 *  ttcmap.h                                                    1.0
 *
 *    TrueType Character Mappings
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
 ******************************************************************/

#ifndef TTCMAP_H
#define TTCMAP_H

#include "ttconfig.h"
#include "tttypes.h"


#ifdef __cplusplus
  extern "C" {
#endif

  /* format 0 */

  struct  TCMap0_
  {
    PByte  glyphIdArray;
  };

  typedef struct TCMap0_  TCMap0;
  typedef TCMap0*         PCMap0;


  /* format 2 */

  struct  TCMap2SubHeader_
  {
    UShort  firstCode;      /* first valid low byte         */
    UShort  entryCount;     /* number of valid low bytes    */
    Short   idDelta;        /* delta value to glyphIndex    */
    UShort  idRangeOffset;  /* offset from here to 1st code */
  };

  typedef struct TCMap2SubHeader_  TCMap2SubHeader;
  typedef TCMap2SubHeader*         PCMap2SubHeader;

  struct  TCMap2_
  {
    PUShort subHeaderKeys;
    /* high byte mapping table     */
    /* value = subHeader index * 8 */

    PCMap2SubHeader  subHeaders;
    PUShort          glyphIdArray;
    UShort           numGlyphId;        /* control value */
  };

  typedef struct TCMap2_  TCMap2;
  typedef TCMap2*         PCMap2;


  /* format 4 */

  struct  TCMap4Segment_
  {
    UShort  endCount;
    UShort  startCount;
    Short   idDelta;        /* in the specs defined as UShort but the
                               example there gives negative values... */
    UShort  idRangeOffset;
  };

  typedef struct TCMap4Segment_  TCMap4Segment;
  typedef TCMap4Segment*         PCMap4Segment;

  struct  TCMap4_
  {
    UShort  segCountX2;     /* number of segments * 2       */
    UShort  searchRange;    /* these parameters can be used */
    UShort  entrySelector;  /* for a binary search          */
    UShort  rangeShift;

    MemHandle      segmentBlock;
    MemHandle      glyphIdBlock;
    UShort         numGlyphId;          /* control value */
  };

  typedef struct TCMap4_  TCMap4;
  typedef TCMap4*         PCMap4;


  /* format 6 */

  struct  TCMap6_
  {
    UShort   firstCode;      /* first character code of subrange      */
    UShort   entryCount;     /* number of character codes in subrange */

    PUShort  glyphIdArray;
  };

  typedef struct TCMap6_  TCMap6;
  typedef TCMap6*         PCMap6;


  /* charmap table */

  struct  TCMapTable_
  {
    UShort  platformID;
    UShort  platformEncodingID;
    UShort  format;
    UShort  length;
#ifdef TT_CONFIG_OPTION_SUPPORT_OPTIONAL_FIELDS
    UShort  version;
#endif

    Bool    loaded;
    ULong   offset;

    union
    {
      TCMap0  cmap0;
#ifdef TT_CONFIG_OPTION_SUPPORT_CMAP2
      TCMap2  cmap2;
#endif
      TCMap4  cmap4;
#ifdef TT_CONFIG_OPTION_SUPPORT_CMAP6
      TCMap6  cmap6;
#endif
    } c;
  };

  typedef struct TCMapTable_  TCMapTable;
  typedef TCMapTable*         PCMapTable;



  /* Load character mappings directory when face is loaded. */
  /* The mappings themselves are only loaded on demand.     */

  LOCAL_DEF
  TT_Error  CharMap_Load( PCMapTable  table,
                          TT_Stream  input );


  /* Destroy one character mapping table */

  LOCAL_DEF
  void      CharMap_Free( PCMapTable  table );


  /* Use character mapping table to perform mapping */

  LOCAL_DEF
  UShort  CharMap_Index( PCMapTable  cmap,
                         UShort      charCode );


  LOCAL_DEF
  TT_Error getCharMap( TT_Face              face, 
                       TT_Face_Properties*  faceProperties, 
                       TT_CharMap*          charMap );

#ifdef __cplusplus
  }
#endif

#endif /* TTCMAP_H */


/* END */
