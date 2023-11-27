/*******************************************************************
 *
 *  ttcmap.c                                                    1.0
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
 ******************************************************************/

#include "ttobjs.h"
#include "ttfile.h"
#include "ttmemory.h"
#include "ttload.h"
#include "ttcmap.h"

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT      trace_cmap


/*******************************************************************
 *
 *  Function    :  CharMap_Load
 *
 *  Description :  Loads a given charmap into memory.
 *
 *  Input  :  cmap  pointer to cmap table
 *
 *  Output :  Error code.
 *
 *  Notes  :  - Assumes the the stream is already used (opened).
 *
 *            - In case of error, releases all partially allocated
 *              tables.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  CharMap_Load( PCMapTable  cmap,
                          TT_Stream   input )
  {
    DEFINE_LOAD_LOCALS( input );

    UShort  num_SH, num_Seg, i;

    UShort  u, l;

    PCMap0  cmap0;
    PCMap2  cmap2;
    PCMap4  cmap4;
    PCMap6  cmap6;

    PCMap2SubHeader cmap2sub;
    PCMap4Segment   segments;


    if ( cmap->loaded )
      return TT_Err_Ok;

    if ( FILE_Seek( cmap->offset ) )
      return error;

    switch ( cmap->format )
    {
    case 0:
      cmap0 = &cmap->c.cmap0;

      if ( ALLOC( cmap0->glyphIdArray, 256L )            ||
           FILE_Read( (void*)cmap0->glyphIdArray, 256L ) )
         goto Fail;

      break;

    case 2:
      num_SH = 0;
      cmap2  = &cmap->c.cmap2;

      /* allocate subheader keys */

      if ( ALLOC_ARRAY( cmap2->subHeaderKeys, 256, UShort ) ||
           ACCESS_Frame( 512L )                             )
        goto Fail;

      for ( i = 0; i < 256; i++ )
      {
        u = GET_UShort() / 8;
        cmap2->subHeaderKeys[i] = u;

        if ( num_SH < u )
          num_SH = u;
      }

      FORGET_Frame();

      /* load subheaders */

      cmap2->numGlyphId = l =
        ( ( cmap->length - 2L * (256 + 3) - num_SH * 8L ) & 0xffff) / 2;

      if ( ALLOC_ARRAY( cmap2->subHeaders,
                        num_SH + 1,
                        TCMap2SubHeader )     ||
           ACCESS_Frame( ( num_SH + 1 ) * 8L ) )
        goto Fail;

      cmap2sub = cmap2->subHeaders;

      for ( i = 0; i <= num_SH; i++ )
      {
        cmap2sub->firstCode     = GET_UShort();
        cmap2sub->entryCount    = GET_UShort();
        cmap2sub->idDelta       = GET_Short();
        /* we apply the location offset immediately */
        cmap2sub->idRangeOffset = GET_UShort() - ( num_SH - i ) * 8 - 2;

        cmap2sub++;
      }

      FORGET_Frame();

      /* load glyph ids */

      if ( ALLOC_ARRAY( cmap2->glyphIdArray, l, UShort ) ||
           ACCESS_Frame( l * 2L ) )
        goto Fail;

      for ( i = 0; i < l; i++ )
        cmap2->glyphIdArray[i] = GET_UShort();

      FORGET_Frame();
      break;

    case 4:
      cmap4 = &cmap->c.cmap4;

      /* load header */

      if ( ACCESS_Frame( 8L ) )
        goto Fail;

      cmap4->segCountX2    = GET_UShort();
      cmap4->searchRange   = GET_UShort();
      cmap4->entrySelector = GET_UShort();
      cmap4->rangeShift    = GET_UShort();

      num_Seg = cmap4->segCountX2 / 2;

      FORGET_Frame();

      /* load segments */

      if ( ALLOC_ARRAY( cmap4->segments,
                        num_Seg,
                        TCMap4Segment )           ||
           ACCESS_Frame( (num_Seg * 4 + 1) * 2L ) )
        goto Fail;

      segments = cmap4->segments;

      for ( i = 0; i < num_Seg; i++ )
        segments[i].endCount      = GET_UShort();

      (void)GET_UShort();

      for ( i = 0; i < num_Seg; i++ )
        segments[i].startCount    = GET_UShort();

      for ( i = 0; i < num_Seg; i++ )
        segments[i].idDelta       = GET_Short();

      for ( i = 0; i < num_Seg; i++ )
        segments[i].idRangeOffset = GET_UShort();

      FORGET_Frame();

      cmap4->numGlyphId = l =
        ( ( cmap->length - ( 16L + 8L * num_Seg ) ) & 0xffff ) / 2;

      /* load ids */

      if ( ALLOC_ARRAY( cmap4->glyphIdArray, l , UShort ) ||
           ACCESS_Frame( l * 2L ) )
        goto Fail;

      for ( i = 0; i < l; i++ )
        cmap4->glyphIdArray[i] = GET_UShort();

      FORGET_Frame();
      break;

    case 6:
      cmap6 = &cmap->c.cmap6;

      if ( ACCESS_Frame( 4L ) )
        goto Fail;

      cmap6->firstCode  = GET_UShort();
      cmap6->entryCount = GET_UShort();

      FORGET_Frame();

      l = cmap6->entryCount;

      if ( ALLOC_ARRAY( cmap6->glyphIdArray,
                        cmap6->entryCount,
                        Short )   ||
           ACCESS_Frame( l * 2L ) )
        goto Fail;

      for ( i = 0; i < l; i++ )
        cmap6->glyphIdArray[i] = GET_UShort();

      FORGET_Frame();
      break;

    default:   /* corrupt character mapping table */
      return TT_Err_Invalid_CharMap_Format;

    }
    return TT_Err_Ok;

  Fail:
    CharMap_Free( cmap );
    return error;
  }


/*******************************************************************
 *
 *  Function    :  CharMap_Free
 *
 *  Description :  Releases a given charmap table.
 *
 *  Input  :  cmap   pointer to cmap table
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  CharMap_Free( PCMapTable  cmap )
  {
    if ( !cmap )
      return TT_Err_Ok;

    switch ( cmap->format )
    {
      case 0:
        FREE( cmap->c.cmap0.glyphIdArray );
        break;

      case 2:
        FREE( cmap->c.cmap2.subHeaderKeys );
        FREE( cmap->c.cmap2.subHeaders );
        FREE( cmap->c.cmap2.glyphIdArray );
        break;

      case 4:
        FREE( cmap->c.cmap4.segments );
        FREE( cmap->c.cmap4.glyphIdArray );
        cmap->c.cmap4.segCountX2 = 0;
        break;

      case 6:
        FREE( cmap->c.cmap6.glyphIdArray );
        cmap->c.cmap6.entryCount = 0;
        break;

      default:
        /* invalid table format, do nothing */
        ;
    }

    cmap->loaded = FALSE;
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  CharMap_Index
 *
 *  Description :  Performs charcode->glyph index translation.
 *
 *  Input  :  cmap   pointer to cmap table
 *
 *  Output :  Glyph index, 0 in case of failure.
 *
 ******************************************************************/

  static UShort  code_to_index0( UShort  charCode, PCMap0  cmap0 );
  static UShort  code_to_index2( UShort  charCode, PCMap2  cmap2 );
  static UShort  code_to_index4( UShort  charCode, PCMap4  cmap4 );
  static UShort  code_to_index6( UShort  charCode, PCMap6  cmap6 );


  LOCAL_FUNC
  UShort  CharMap_Index( PCMapTable  cmap,
                         UShort      charcode )
  {
    switch ( cmap->format )
    {
      case 0:
        return code_to_index0( charcode, &cmap->c.cmap0 );
      case 2:
        return code_to_index2( charcode, &cmap->c.cmap2 );
      case 4:
        return code_to_index4( charcode, &cmap->c.cmap4 );
      case 6:
        return code_to_index6( charcode, &cmap->c.cmap6 );
      default:
        return 0;
    }
  }


/*******************************************************************
 *
 *  Function    : code_to_index0
 *
 *  Description : Converts the character code into a glyph index.
 *                Uses format 0.
 *                charCode will be masked to get a value in the range
 *                0x00-0xFF.
 *
 *  Input  :  charCode      the wanted character code
 *            cmap0         a pointer to a cmap table in format 0
 *
 *  Output :  Glyph index into the glyphs array.
 *            0 if the glyph does not exist.
 *
 ******************************************************************/

  static UShort  code_to_index0( UShort  charCode,
                                 PCMap0  cmap0 )
  {
    if ( charCode <= 0xFF )
      return cmap0->glyphIdArray[charCode];
    else
      return 0;
  }


/*******************************************************************
 *
 *  Function    : code_to_index2
 *
 *  Description : Converts the character code into a glyph index.
 *                Uses format 2.
 *
 *  Input  :  charCode      the wanted character code
 *            cmap2         a pointer to a cmap table in format 2
 *
 *  Output :  Glyph index into the glyphs array.
 *            0 if the glyph does not exist.
 *
 ******************************************************************/

  static UShort  code_to_index2( UShort  charCode,
                                 PCMap2  cmap2 )
  {
    UShort           index1, idx, offset;
    TCMap2SubHeader  sh2;


    index1 = cmap2->subHeaderKeys[charCode <= 0xFF ?
                                  charCode : (charCode >> 8)];

    if ( index1 == 0 )
    {
      if ( charCode <= 0xFF )
        return cmap2->glyphIdArray[charCode];   /* 8bit character code */
      else
        return 0;
    }
    else                                        /* 16bit character code */
    {
      if ( charCode <= 0xFF )
        return 0;

      sh2 = cmap2->subHeaders[index1];

      if ( (charCode & 0xFF) < sh2.firstCode )
        return 0;

      if ( (charCode & 0xFF) >= (sh2.firstCode + sh2.entryCount) )
        return 0;

      offset = sh2.idRangeOffset / 2 + (charCode & 0xFF) - sh2.firstCode;
      if ( offset < cmap2->numGlyphId )
        idx = cmap2->glyphIdArray[offset];
      else
        return 0;

      if ( idx )
        return (idx + sh2.idDelta) & 0xFFFF;
      else
        return 0;
    }
  }


/*******************************************************************
 *
 *  Function    : code_to_index4
 *
 *  Description : Converts the character code into a glyph index.
 *                Uses format 4.
 *
 *  Input  :  charCode      the wanted character code
 *            cmap4         a pointer to a cmap table in format 4
 *
 *  Output :  Glyph index into the glyphs array.
 *            0 if the glyph does not exist.
 *
 ******************************************************************/

  static UShort  code_to_index4( UShort  charCode,
                                 PCMap4  cmap4 )
  {
    UShort         index1, segCount;
    UShort         i;
    TCMap4Segment  seg4;


    segCount = cmap4->segCountX2 / 2;

    for ( i = 0; i < segCount; i++ )
      if ( charCode <= cmap4->segments[i].endCount )
        break;

    /* Safety check - even though the last endCount should be 0xFFFF */
    if ( i >= segCount )
      return 0;

    seg4 = cmap4->segments[i];

    if ( charCode < seg4.startCount )
      return 0;

    if ( seg4.idRangeOffset == 0 )
      return ( charCode + seg4.idDelta ) & 0xFFFF;
    else
    {
      index1 = seg4.idRangeOffset / 2 + (charCode - seg4.startCount) -
               (segCount - i);

      if ( index1 < cmap4->numGlyphId )
      {
        if ( cmap4->glyphIdArray[index1] == 0 )
          return 0;
        else
          return ( cmap4->glyphIdArray[index1] + seg4.idDelta ) & 0xFFFF;
      }
      else
        return 0;
    }
  }


/*******************************************************************
 *
 *  Function    : code_to_index6
 *
 *  Description : Converts the character code into a glyph index.
 *                Uses format 6.
 *
 *  Input  :  charCode      the wanted character code
 *            cmap6         a pointer to a cmap table in format 6
 *
 *  Output :  Glyph index into the glyphs array.
 *            0 if the glyph does not exist (`missing character glyph').
 *
 ******************************************************************/

  static UShort  code_to_index6( UShort  charCode,
                                 PCMap6  cmap6 )
  {
    UShort firstCode;


    firstCode = cmap6->firstCode;

    if ( charCode < firstCode )
      return 0;

    if ( charCode >= (firstCode + cmap6->entryCount) )
      return 0;

    return cmap6->glyphIdArray[charCode - firstCode];
  }


/* END */
