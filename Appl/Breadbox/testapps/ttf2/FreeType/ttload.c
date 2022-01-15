
/*******************************************************************
 *
 *  ttload.c                                                    1.0
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
 ******************************************************************/

#include "tttypes.h"
#include "ttdebug.h"
#include "ttcalc.h"
#include "ttfile.h"

#include "tttables.h"
#include "ttobjs.h"

#include "ttmemory.h"
#include "tttags.h"
#include "ttload.h"

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT      trace_load

/* In all functions, the stream is taken from the 'face' object */
#define DEFINE_LOCALS           DEFINE_LOAD_LOCALS( face->stream )
#define DEFINE_LOCALS_WO_FRAME  DEFINE_LOAD_LOCALS_WO_FRAME( face->stream )


/*******************************************************************
 *
 *  Function    :  LookUp_TrueType_Table
 *
 *  Description :  Looks for a TrueType table by name.
 *
 *  Input  :  face       face table to look for
 *            tag        searched tag
 *
 *  Output :  Index of table if found, -1 otherwise.
 *
 ******************************************************************/

  EXPORT_FUNC
  Long  TT_LookUp_Table( PFace  face,
                         ULong  tag  )
  {
    UShort  i;


    PTRACE4(( "TT_LookUp_Table( %08lx, %c%c%c%c )\n",
                  (Long)face,
                  (Char)(tag >> 24),
                  (Char)(tag >> 16),
                  (Char)(tag >> 8),
                  (Char)(tag) ));

    for ( i = 0; i < face->numTables; i++ )
      if ( face->dirTables[i].Tag == tag )
        return i;

    PTRACE4(( "    Could not find table!\n" ));
    return -1;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Collection
 *
 *  Description :  Loads the TTC table directory into face table.
 *
 *  Input  :  face    face record to look for
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  static TT_Error  Load_TrueType_Collection( PFace  face )
  {
    DEFINE_LOCALS;

    ULong  n;


    PTRACE3(( "Load_TrueType_Collection( %08lx )\n", (long)face ));

    if ( FILE_Seek   ( 0L ) ||
         ACCESS_Frame( 12L ) )
      return error;

    face->ttcHeader.Tag      = GET_Tag4();
    face->ttcHeader.version  = GET_Long();
    face->ttcHeader.DirCount = GET_Long();

    FORGET_Frame();

    if ( face->ttcHeader.Tag != TTAG_ttcf )
    {
      face->ttcHeader.Tag      = 0;
      face->ttcHeader.version  = 0;
      face->ttcHeader.DirCount = 0;

      face->ttcHeader.TableDirectory = NULL;

      PTRACE3(("skipped.\n"));

      return TT_Err_File_Is_Not_Collection;
    }

    if ( ALLOC_ARRAY( face->ttcHeader.TableDirectory,
                      face->ttcHeader.DirCount,
                      ULong )                         ||
         ACCESS_Frame( face->ttcHeader.DirCount * 4L ) )
      return error;

    for ( n = 0; n < face->ttcHeader.DirCount; n++ )
      face->ttcHeader.TableDirectory[n] = GET_ULong();

    FORGET_Frame();

    PTRACE3(( "collections directory loaded.\n" ));
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Directory
 *
 *  Description :  Loads the table directory into face table.
 *
 *  Input  :  face       face record to look for
 *
 *            faceIndex  the index of the TrueType font, when
 *                       we're opening a collection.
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Directory( PFace  face, ULong  faceIndex )
  {
    DEFINE_LOCALS;

    UShort     n, limit;
    TTableDir  tableDir;

    PTableDirEntry  entry;


    PTRACE2(("Load_TT_Directory( %08lx, %ld )\n", (long)face, faceIndex));

    error = Load_TrueType_Collection( face );

    if ( error )
    {
      if ( error != TT_Err_File_Is_Not_Collection )
        return error;

      /* the file isn't a collection, exit if we're asking */
      /* for a collected font                              */
      if ( faceIndex != 0 )
        return error;

      /* Now skip to the beginning of the file */
      if ( FILE_Seek( 0L ) )
        return error;
    }
    else
    {
      /* The file is a collection. Check the font index */
      if ( faceIndex >= face->ttcHeader.DirCount )
        return TT_Err_Invalid_Argument;

      /* select a TrueType font in the ttc file   */
      if ( FILE_Seek( face->ttcHeader.TableDirectory[faceIndex] ) )
        return error;
    }

    if ( ACCESS_Frame( 12L ) )
      return error;

    tableDir.version   = GET_Long();
    tableDir.numTables = GET_UShort();

    tableDir.searchRange   = GET_UShort();
    tableDir.entrySelector = GET_UShort();
    tableDir.rangeShift    = GET_UShort();

    FORGET_Frame();

    PTRACE2(( "-- Tables count   : %12u\n", tableDir.numTables ));
    PTRACE2(( "-- Format version : %08lx\n", tableDir.version ));

    /* Check that we have a 'sfnt' format there */

    if ( tableDir.version != 0x00010000  &&      /* MS fonts */
         tableDir.version != 0x74727565  &&      /* Mac fonts */
         tableDir.version != 0x00000000  )       /* some Korean fonts */
    {
      PERROR(( "!! invalid file format" ));
      return TT_Err_Invalid_File_Format;
    }

    face->numTables = tableDir.numTables;

    if ( ALLOC_ARRAY( face->dirTables,
                      face->numTables,
                      TTableDirEntry ) )
      return error;

    if ( ACCESS_Frame( face->numTables * 16L ) )
      return error;

    limit = face->numTables;
    entry = face->dirTables;

    for ( n = 0; n < limit; n++ )
    {                      /* loop through the tables and get all entries */
      entry->Tag      = GET_Tag4();
      entry->CheckSum = GET_ULong();
      entry->Offset   = GET_Long();
      entry->Length   = GET_Long();

      PTRACE2(( "  %c%c%c%c  -  %08lx  -  %08lx\n",
                (Char)(entry->Tag >> 24),
                (Char)(entry->Tag >> 16),
                (Char)(entry->Tag >> 8 ),
                (Char)(entry->Tag),
                entry->Offset,
                entry->Length ));
      entry++;
    }

    FORGET_Frame();

    PTRACE2(( "Directory loaded\n\n" ));
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_MaxProfile
 *
 *  Description :  Loads the maxp table into face table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_MaxProfile( PFace  face )
  {
    DEFINE_LOCALS;

    Long         i;
    PMaxProfile  maxProfile = &face->maxProfile;


    PTRACE2(( "Load_TT_MaxProfile( %08lx )\n", (long)face ));

    if ( ( i = TT_LookUp_Table( face, TTAG_maxp ) ) < 0 )
      return TT_Err_Max_Profile_Missing;

    if ( FILE_Seek( face->dirTables[i].Offset ) )   /* seek to maxprofile */
      return error;

    if ( ACCESS_Frame( 32L ) )  /* read into frame */
      return error;

    /* read frame data into face table */
    maxProfile->version               = GET_ULong();

    maxProfile->numGlyphs             = GET_UShort();

    maxProfile->maxPoints             = GET_UShort();
    maxProfile->maxContours           = GET_UShort();
    maxProfile->maxCompositePoints    = GET_UShort();
    maxProfile->maxCompositeContours  = GET_UShort();

    maxProfile->maxZones              = GET_UShort();
    maxProfile->maxTwilightPoints     = GET_UShort();

    maxProfile->maxStorage            = GET_UShort();
    maxProfile->maxFunctionDefs       = GET_UShort();
    maxProfile->maxInstructionDefs    = GET_UShort();
    maxProfile->maxStackElements      = GET_UShort();
    maxProfile->maxSizeOfInstructions = GET_UShort();
    maxProfile->maxComponentElements  = GET_UShort();
    maxProfile->maxComponentDepth     = GET_UShort();

    FORGET_Frame();

    /* XXX : an adjustement that is necessary to load certain */
    /*       broken fonts like "Keystrokes MT" :-(            */
    /*                                                        */
    /*   We allocate 64 function entries by default when      */
    /*   the maxFunctionDefs field is null.                   */

    if (maxProfile->maxFunctionDefs == 0)
      maxProfile->maxFunctionDefs = 64;

    face->numGlyphs     = maxProfile->numGlyphs;

    face->maxPoints     = MAX( maxProfile->maxCompositePoints,
                               maxProfile->maxPoints );
    face->maxContours   = MAX( maxProfile->maxCompositeContours,
                               maxProfile->maxContours );
    face->maxComponents = maxProfile->maxComponentElements +
                          maxProfile->maxComponentDepth;

    /* XXX: Some fonts have maxComponents set to 0; we will */
    /*      then use 16 of them by default.                 */
    if ( face->maxComponents == 0 )
      face->maxComponents = 16;
     
    /* We also increase maxPoints and maxContours in order to support */
    /* some broken fonts.                                             */
    face->maxPoints   += 8;
    face->maxContours += 4;

    PTRACE2(( "GASP loaded.\n" ));
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Gasp
 *
 *  Description :  Loads the TrueType Gasp table into the face
 *                 table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Gasp( PFace  face )
  {
    DEFINE_LOCALS;

    Long        i;
    UShort      j;
    TGasp*      gas;
    GaspRange*  gaspranges;


    PTRACE2(( "Load_TT_Gasp( %08lx )\n", (long)face ));

    if ( ( i = TT_LookUp_Table( face, TTAG_gasp ) ) < 0 )
      return TT_Err_Ok; /* gasp table is not required */

    if ( FILE_Seek( face->dirTables[i].Offset ) ||
         ACCESS_Frame( 4L ) )
      return error;

    gas = &face->gasp;

    gas->version   = GET_UShort();
    gas->numRanges = GET_UShort();

    FORGET_Frame();

    PTRACE3(( "number of ranges = %d\n", gas->numRanges ));

    if ( ALLOC_ARRAY( gaspranges, gas->numRanges, GaspRange ) ||
         ACCESS_Frame( gas->numRanges * 4L ) )
      goto Fail;

    face->gasp.gaspRanges = gaspranges;

    for ( j = 0; j < gas->numRanges; j++ )
    {
      gaspranges[j].maxPPEM  = GET_UShort();
      gaspranges[j].gaspFlag = GET_UShort();

      PTRACE3(( " [max:%d flag:%d]",
                gaspranges[j].maxPPEM,
                gaspranges[j].gaspFlag ));
    }
    PTRACE3(("\n"));

    FORGET_Frame();

    PTRACE2(( "GASP loaded\n" ));
    return TT_Err_Ok;

  Fail:
    FREE( gaspranges );
    gas->numRanges = 0;
    return error;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Header
 *
 *  Description :  Loads the TrueType header table into the face
 *                 table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Header( PFace  face )
  {
    DEFINE_LOCALS;

    Long        i;
    TT_Header*  header;


    PTRACE2(( "Load_TT_Header( %08lx )\n", (long)face ));

    if ( ( i = TT_LookUp_Table( face, TTAG_head ) ) < 0 )
    {
      PTRACE0(( "Font Header is missing !!\n" ));
      return TT_Err_Header_Table_Missing;
    }

    if ( FILE_Seek( face->dirTables[i].Offset ) ||
         ACCESS_Frame( 54L ) )
      return error;

    header = &face->fontHeader;

    header->Table_Version = GET_ULong();
    header->Font_Revision = GET_ULong();

    header->CheckSum_Adjust = GET_Long();
    header->Magic_Number    = GET_Long();

    header->Flags        = GET_UShort();
    header->Units_Per_EM = GET_UShort();

    header->Created [0] = GET_Long();
    header->Created [1] = GET_Long();
    header->Modified[0] = GET_Long();
    header->Modified[1] = GET_Long();

    header->xMin = GET_Short();
    header->yMin = GET_Short();
    header->xMax = GET_Short();
    header->yMax = GET_Short();

    header->Mac_Style       = GET_UShort();
    header->Lowest_Rec_PPEM = GET_UShort();

    header->Font_Direction      = GET_Short();
    header->Index_To_Loc_Format = GET_Short();
    header->Glyph_Data_Format   = GET_Short();

    FORGET_Frame();

    PTRACE2(( "    Units per EM : %8u\n", header->Units_Per_EM ));
    PTRACE2(( "    IndexToLoc   : %8d\n", header->Index_To_Loc_Format ));
    PTRACE2(( "Font Header Loaded.\n" ));
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Metrics
 *
 *  Description :  Loads the horizontal or vertical metrics table
 *                 into face object.
 *
 *  Input  :  face
 *            vertical   set to true when loading the vmtx table,
 *                       or false for hmtx
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  static
  TT_Error  Load_TrueType_Metrics( PFace  face,
                                   Bool   vertical )
  {
    DEFINE_LOCALS;

    Long              n, num_shorts, num_shorts_checked, num_longs;

    PLongMetrics*     longs;
    PShortMetrics*    shorts;

    PLongMetrics      long_metric;


    PTRACE2(( "Load_TT_%s_Metrics( %08lx )\n",
              vertical ? "Vertical" : "Horizontal",
              (long)face ));

    if ( vertical )
    {
      /* The table is optional, quit silently if it wasn't found       */
      /* XXX : Some fonts have a valid vertical header with a non-null */
      /*       "number_of_VMetrics" fields, but no corresponding       */
      /*       'vmtx' table to get the metrics from (e.g. mingliu)     */
      /*                                                               */
      /*       For safety, we set the field to 0 !                     */
      /*                                                               */
      n = TT_LookUp_Table( face, TTAG_vmtx );
      if ( n < 0 )
      {
        /* Set the number_Of_VMetrics to 0! */
        PTRACE2(( "  no vertical header in file.\n" ));
        face->verticalHeader.number_Of_VMetrics = 0;
        return TT_Err_Ok;
      }

      num_longs = face->verticalHeader.number_Of_VMetrics;
      longs     = (PLongMetrics*)&face->verticalHeader.long_metrics;
      shorts    = (PShortMetrics*)&face->verticalHeader.short_metrics;
    }
    else
    {
      if ( ( n = TT_LookUp_Table( face, TTAG_hmtx ) ) < 0 )
      {
        PERROR(( "!! No Horizontal metrics in file !!\n" ));
        return TT_Err_Hmtx_Table_Missing;
      }

      num_longs = face->horizontalHeader.number_Of_HMetrics;
      longs     = (PLongMetrics*)&face->horizontalHeader.long_metrics;
      shorts    = (PShortMetrics*)&face->horizontalHeader.short_metrics;
    }

    /* never trust derived values! */

    num_shorts         = face->maxProfile.numGlyphs - num_longs;
    num_shorts_checked = ( face->dirTables[n].Length - num_longs * 4 ) / 2;

    if ( num_shorts < 0 )            /* sanity check */
    {
      PERROR(( "!! more metrics than glyphs!\n" ));
      if ( vertical )
        return TT_Err_Invalid_Vert_Metrics;
      else
        return TT_Err_Invalid_Horiz_Metrics;
    }

    if ( ALLOC_ARRAY( *longs,  num_longs,  TLongMetrics  ) ||
         ALLOC_ARRAY( *shorts, num_shorts, TShortMetrics ) )
      return error;

    if ( FILE_Seek( face->dirTables[n].Offset )   ||
         ACCESS_Frame( face->dirTables[n].Length ) )
      return error;

    long_metric = *longs;
    for ( n = 0; n < num_longs; n++ )
    {
      long_metric->advance = GET_UShort();
      long_metric->bearing = GET_Short();
      long_metric++;
    }

    /* do we have an inconsistent number of metric values? */

    if ( num_shorts > num_shorts_checked )
    {
      for ( n = 0; n < num_shorts_checked; n++ )
        (*shorts)[n] = GET_Short();

      /* we fill up the missing left side bearings with the    */
      /* last valid value. Since this will occur for buggy CJK */
      /* fonts usually, nothing serious will happen.           */

      for ( n = num_shorts_checked; n < num_shorts; n++ )
        (*shorts)[n] = (*shorts)[num_shorts_checked - 1];
    }
    else
    {
      for ( n = 0; n < num_shorts; n++ )
        (*shorts)[n] = GET_Short();
    }

    FORGET_Frame();

    PTRACE2(( "loaded\n" ));
    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : Load_TrueType_Metrics_Header
 *
 *  Description : Loads either the "hhea" or "vhea" table in memory
 *
 *  Input  :  face       face table to look for
 *            vertical   a boolean.  When set, queries the optional
 *                       "vhea" table.  Otherwise, load the mandatory
 *                       "hhea" horizontal header.
 *
 *  Output :  Error code.
 *
 *  Note : This function now loads the corresponding metrics table
 *         (either hmtx or vmtx) and attaches it to the header.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Metrics_Header( PFace  face,
                                          Bool   vertical )
  {
    DEFINE_LOCALS;

    Long  i;

    TT_Horizontal_Header*  header;


    PTRACE2(( vertical ? "Vertical header" : "Horizontal header " ));

    if ( vertical )
    {
      face->verticalInfo = 0;

      /* The vertical header table is optional, so return quietly if */
      /* we don't find it..                                          */
      if ( ( i = TT_LookUp_Table( face, TTAG_vhea ) ) < 0 )
        return TT_Err_Ok;

      face->verticalInfo = 1;
      header = (TT_Horizontal_Header*)&face->verticalHeader;
    }
    else
    {
      /* The orizontal header is mandatory, return an error if we */
      /* don't find it.                                           */
      if ( ( i = TT_LookUp_Table( face, TTAG_hhea ) ) < 0 )
        return TT_Err_Horiz_Header_Missing;

      header = &face->horizontalHeader;
    }

    if ( FILE_Seek( face->dirTables[i].Offset ) ||
         ACCESS_Frame( 36L ) )
      return error;

    header->Version   = GET_ULong();
    header->Ascender  = GET_Short();
    header->Descender = GET_Short();
    header->Line_Gap  = GET_Short();

    header->advance_Width_Max = GET_UShort();

    header->min_Left_Side_Bearing  = GET_Short();
    header->min_Right_Side_Bearing = GET_Short();
    header->xMax_Extent            = GET_Short();
    header->caret_Slope_Rise       = GET_Short();
    header->caret_Slope_Run        = GET_Short();

    header->Reserved0 = GET_Short();    /* this is caret_Offset for
                                           vertical headers */
    header->Reserved1 = GET_Short();
    header->Reserved2 = GET_Short();
    header->Reserved3 = GET_Short();
    header->Reserved4 = GET_Short();

    header->metric_Data_Format = GET_Short();
    header->number_Of_HMetrics = GET_UShort();

    FORGET_Frame();

    header->long_metrics  = NULL;
    header->short_metrics = NULL;

    PTRACE2(( "loaded\n" ));

    /* Now try to load the corresponding metrics */

    return Load_TrueType_Metrics( face, vertical );
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Locations
 *
 *  Description :  Loads the location table into face table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  Error code.
 *
 *  NOTE:
 *    The Font Header *must* be loaded in the leading segment
 *    calling this function.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Locations( PFace  face )
  {
    DEFINE_LOCALS;

    Long   n, limit;
    Short  LongOffsets;


    PTRACE2(( "Locations " ));

    LongOffsets = face->fontHeader.Index_To_Loc_Format;

    if ( ( n = TT_LookUp_Table( face, TTAG_loca ) ) < 0 )
      return TT_Err_Locations_Missing;

    if ( FILE_Seek( face->dirTables[n].Offset ) )
      return error;

    if ( LongOffsets != 0 )
    {
      face->numLocations = face->dirTables[n].Length >> 2;

      PTRACE2(( "(32 bit offsets): %12lu ",
                   face->numLocations ));

      if ( ALLOC_ARRAY( face->glyphLocations,
                        face->numLocations,
                        Long ) )
        return error;

      if ( ACCESS_Frame( face->numLocations * 4L ) )
        return error;

      limit = face->numLocations;

      for ( n = 0; n < limit; n++ )
        face->glyphLocations[n] = GET_Long();

      FORGET_Frame();
    }
    else
    {
      face->numLocations = face->dirTables[n].Length >> 1;

      PTRACE2(( "(16 bit offsets): %12lu ",
                   face->numLocations ));

      if ( ALLOC_ARRAY( face->glyphLocations,
                        face->numLocations,
                        Long ) )
        return error;

      if ( ACCESS_Frame( face->numLocations * 2L ) )
        return error;

      limit = face->numLocations;

      for ( n = 0; n < limit; n++ )
        face->glyphLocations[n] =
          (Long)((ULong)GET_UShort() * 2);

      FORGET_Frame();
    }

    PTRACE2(( "loaded\n" ));

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Names
 *
 *  Description :  Loads the name table into face table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Names( PFace  face )
  {
    DEFINE_LOCALS;

    UShort  i, bytes;
    Long    n;
    PByte   storage;

    TName_Table*  names;
    TNameRec*     namerec;


    PTRACE2(( "Names " ));

    if ( ( n = TT_LookUp_Table( face, TTAG_name ) ) < 0 )
    {
      /* The name table is required so indicate failure. */
      PTRACE2(( "is missing!\n" ));

      return TT_Err_Name_Table_Missing;
    }

    /* Seek to the beginning of the table and check the frame access. */
    /* The names table has a 6 byte header.                           */
    if ( FILE_Seek( face->dirTables[n].Offset ) ||
         ACCESS_Frame( 6L ) )
      return error;

    names = &face->nameTable;

    /* Load the initial names data. */
    names->format         = GET_UShort();
    names->numNameRecords = GET_UShort();
    names->storageOffset  = GET_UShort();

    FORGET_Frame();

    /* Allocate the array of name records. */
    if ( ALLOC_ARRAY( names->names,
                      names->numNameRecords,
                      TNameRec )                    ||
         ACCESS_Frame( names->numNameRecords * 12L ) )
    {
      names->numNameRecords = 0;
      goto Fail;
    }

    /* Load the name records and determine how much storage is needed */
    /* to hold the strings themselves.                                */

    for ( i = bytes = 0; i < names->numNameRecords; i++ )
    {
      namerec = names->names + i;
      namerec->platformID   = GET_UShort();
      namerec->encodingID   = GET_UShort();
      namerec->languageID   = GET_UShort();
      namerec->nameID       = GET_UShort();
      namerec->stringLength = GET_UShort();
      namerec->stringOffset = GET_UShort();

#if 0
      /* check the ids */
      if ( namerec->platformID <= 3 )
      {
#endif
        /* this test takes care of 'holes' in the names tables, as */
        /* reported by Erwin                                       */
        if ( (namerec->stringOffset + namerec->stringLength) > bytes )
          bytes = namerec->stringOffset + namerec->stringLength;
#if 0
      }
#endif
    }

    FORGET_Frame();

    /* Allocate storage for the strings if they exist. */

    names->storage = NULL;

    if ( bytes > 0 )
    {
      if ( ALLOC( storage, bytes ) ||
           FILE_Read_At( face->dirTables[n].Offset + names->storageOffset,
                         (void*)storage,
                         bytes ) )
        goto Fail_Storage;

      names->storage = storage;

      /* Go through and assign the string pointers to the name records. */

      for ( i = 0; i < names->numNameRecords; i++ )
      {
        namerec = names->names + i;
        namerec->string = storage + names->names[i].stringOffset;

/* It is possible (but rather unlikely) that a new platform ID will be */
/* added by Apple, so we can't rule out IDs > 3.                       */

#if 0
        if ( namerec->platformID <= 3 )
          namerec->string = storage + names->names[i].stringOffset;
        else
        {
          namerec->string       = NULL;
          namerec->stringLength = 0;
        }
#endif
      }
    }

#ifdef DEBUG_LEVEL_TRACE

    for ( i = 0; i < names->numNameRecords; i++ )
    {
      int  j;


      PTRACE2(( "%d %d %x %d ",
                   names->names[i].platformID,
                   names->names[i].encodingID,
                   names->names[i].languageID,
                   names->names[i].nameID ));

      /* I know that M$ encoded strings are Unicode,            */
      /* but this works reasonable well for debugging purposes. */
      for ( j = 0; j < names->names[i].stringLength; j++ )
      {
        if (names->names[i].string)
        {
          Char  c = *(names->names[i].string + j);


          if ( (Byte)c < 128 )
            PTRACE2(( "%c", c ));
        }
      }

      PTRACE2(( "\n" ));
    }

#endif /* DEBUG_LEVEL_TRACE */

    PTRACE2(( "loaded\n" ));
    return TT_Err_Ok;

  Fail_Storage:
    FREE( storage );

  Fail:
    Free_TrueType_Names( face );
    return error;
  }


/*******************************************************************
 *
 *  Function    :  Free_TrueType_Names
 *
 *  Description :  Frees a name table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  TT_Err_Ok.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Free_TrueType_Names( PFace  face )
  {
    TName_Table*  names = &face->nameTable;


    /* free strings table */
    FREE( names->names );

    /* free strings storage */
    FREE( names->storage );

    names->numNameRecords = 0;
    names->format         = 0;
    names->storageOffset  = 0;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_CVT
 *
 *  Description :  Loads cvt table into resident table.
 *
 *  Input  :  face     face table to look for
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_CVT( PFace  face )
  {
    DEFINE_LOCALS;

    Long  n, limit;


    PTRACE2(( "CVT " ));

    if ( ( n = TT_LookUp_Table( face, TTAG_cvt ) ) < 0 )
    {
      PTRACE2(( "is missing!\n" ));

      face->cvtSize = 0;
      face->cvt     = NULL;
      return TT_Err_Ok;
    }

    face->cvtSize = face->dirTables[n].Length / 2;

    if ( ALLOC_ARRAY( face->cvt,
                      face->cvtSize,
                      Short ) )
      return error;

    if ( FILE_Seek( face->dirTables[n].Offset ) ||
         ACCESS_Frame( face->cvtSize * 2L ) )
      return error;

    limit = face->cvtSize;

    for ( n = 0; n < limit; n++ )
      face->cvt[n] = GET_Short();

    FORGET_Frame();

    PTRACE2(( "loaded\n" ));

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_CMap
 *
 *  Description :  Loads the cmap directory in memory.
 *                 The cmaps themselves are loaded in ttcmap.c .
 *
 *  Input  :  face
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_CMap( PFace  face )
  {
    DEFINE_LOCALS;

    Long  off, table_start;
    Long  n, limit;

    TCMapDir       cmap_dir;
    TCMapDirEntry  entry_;
    PCMapTable     cmap;


    PTRACE2(( "CMaps " ));

    if ( ( n = TT_LookUp_Table( face, TTAG_cmap ) ) < 0 )
      return TT_Err_CMap_Table_Missing;

    table_start = face->dirTables[n].Offset;

    if ( ( FILE_Seek( table_start ) ) ||
         ( ACCESS_Frame( 4L ) ) )           /* 4 bytes cmap header */
      return error;

    cmap_dir.tableVersionNumber = GET_UShort();
    cmap_dir.numCMaps           = GET_UShort();

    FORGET_Frame();

    off = FILE_Pos();  /* save offset to cmapdir[] which follows */

    /* save space in face table for cmap tables */
    if ( ALLOC_ARRAY( face->cMaps,
                      cmap_dir.numCMaps,
                      TCMapTable ) )
      return error;

    face->numCMaps = cmap_dir.numCMaps;

    limit = face->numCMaps;
    cmap  = face->cMaps;

    for ( n = 0; n < limit; n++ )
    {
      if ( FILE_Seek( off )  ||
           ACCESS_Frame( 8L ) )
        return error;

      /* extra code using entry_ for platxxx could be cleaned up later */
      cmap->loaded             = FALSE;
      cmap->platformID         = entry_.platformID         = GET_UShort();
      cmap->platformEncodingID = entry_.platformEncodingID = GET_UShort();

      entry_.offset = GET_Long();

      FORGET_Frame();

      off = FILE_Pos();

      if ( FILE_Seek( table_start + entry_.offset ) ||
           ACCESS_Frame( 6L ) )
        return error;

      cmap->format  = GET_UShort();
      cmap->length  = GET_UShort();
      cmap->version = GET_UShort();

      FORGET_Frame();

      cmap->offset = FILE_Pos();

      cmap++;
    }

    PTRACE2(( "loaded\n" ));

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Programs
 *
 *  Description :  Loads the font (fpgm) and cvt programs into the
 *                 face table.
 *
 *  Input  :  face
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Programs( PFace  face )
  {
    DEFINE_LOCALS_WO_FRAME;

    Long  n;


    PTRACE2(( "Font program " ));

    /* The font program is optional */
    if ( ( n = TT_LookUp_Table( face, TTAG_fpgm ) ) < 0 )
    {
      face->fontProgram = NULL;
      face->fontPgmSize = 0;

      PTRACE2(( "is missing!\n" ));
    }
    else
    {
      face->fontPgmSize = face->dirTables[n].Length;

      if ( ALLOC( face->fontProgram,
                  face->fontPgmSize )              ||
           FILE_Read_At( face->dirTables[n].Offset,
                         (void*)face->fontProgram,
                         face->fontPgmSize )       )
        return error;

      PTRACE2(( "loaded, %12d bytes\n", face->fontPgmSize ));
    }

    PTRACE2(( "Prep program " ));

    if ( ( n = TT_LookUp_Table( face, TTAG_prep ) ) < 0 )
    {
      face->cvtProgram = NULL;
      face->cvtPgmSize = 0;

      PTRACE2(( "is missing!\n" ));
    }
    else
    {
      face->cvtPgmSize = face->dirTables[n].Length;

      if ( ALLOC( face->cvtProgram,
                  face->cvtPgmSize )               ||
           FILE_Read_At( face->dirTables[n].Offset,
                         (void*)face->cvtProgram,
                         face->cvtPgmSize )        )
        return error;

      PTRACE2(( "loaded, %12d bytes\n", face->cvtPgmSize ));
    }

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_OS2
 *
 *  Description :  Loads the OS2 Table.
 *
 *  Input  :  face
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_OS2( PFace  face )
  {
    DEFINE_LOCALS;

    Long     i;
    TT_OS2*  os2;


    PTRACE2(( "OS/2 Table " ));

    /* We now support old Mac fonts where the OS/2 table doesn't  */
    /* exist.  Simply put, we set the `version' field to 0xFFFF   */
    /* and test this value each time we need to access the table. */
    if ( ( i = TT_LookUp_Table( face, TTAG_OS2 ) ) < 0 )
    {
      PTRACE2(( "is missing\n!" ));
      face->os2.version = 0xFFFF;
      error = TT_Err_Ok;
      return TT_Err_Ok;
    }

    if ( FILE_Seek( face->dirTables[i].Offset ) ||
         ACCESS_Frame( 78L ) )
      return error;

    os2 = &face->os2;

    os2->version             = GET_UShort();
    os2->xAvgCharWidth       = GET_Short();
    os2->usWeightClass       = GET_UShort();
    os2->usWidthClass        = GET_UShort();
    os2->fsType              = GET_Short();
    os2->ySubscriptXSize     = GET_Short();
    os2->ySubscriptYSize     = GET_Short();
    os2->ySubscriptXOffset   = GET_Short();
    os2->ySubscriptYOffset   = GET_Short();
    os2->ySuperscriptXSize   = GET_Short();
    os2->ySuperscriptYSize   = GET_Short();
    os2->ySuperscriptXOffset = GET_Short();
    os2->ySuperscriptYOffset = GET_Short();
    os2->yStrikeoutSize      = GET_Short();
    os2->yStrikeoutPosition  = GET_Short();
    os2->sFamilyClass        = GET_Short();

    for ( i = 0; i < 10; i++ )
      os2->panose[i] = GET_Byte();

    os2->ulUnicodeRange1     = GET_ULong();
    os2->ulUnicodeRange2     = GET_ULong();
    os2->ulUnicodeRange3     = GET_ULong();
    os2->ulUnicodeRange4     = GET_ULong();

    for ( i = 0; i < 4; i++ )
      os2->achVendID[i] = GET_Byte();

    os2->fsSelection         = GET_UShort();
    os2->usFirstCharIndex    = GET_UShort();
    os2->usLastCharIndex     = GET_UShort();
    os2->sTypoAscender       = GET_Short();
    os2->sTypoDescender      = GET_Short();
    os2->sTypoLineGap        = GET_Short();
    os2->usWinAscent         = GET_UShort();
    os2->usWinDescent        = GET_UShort();

    FORGET_Frame();

    if ( os2->version >= 0x0001 )
    {
      /* only version 1 tables */

      if ( ACCESS_Frame( 8L ) )  /* read into frame */
        return error;

      os2->ulCodePageRange1 = GET_ULong();
      os2->ulCodePageRange2 = GET_ULong();

      FORGET_Frame();
    }
    else
    {
      os2->ulCodePageRange1 = 0;
      os2->ulCodePageRange2 = 0;
    }

    PTRACE2(( "loaded\n" ));

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_PostScript
 *
 *  Description :  Loads the post table into face table.
 *
 *  Input  :  face         face table to look for
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_PostScript( PFace  face )
  {
    DEFINE_LOCALS;

    Long  i;

    TT_Postscript*  post = &face->postscript;


    PTRACE2(( "PostScript " ));

    if ( ( i = TT_LookUp_Table( face, TTAG_post ) ) < 0 )
      return TT_Err_Post_Table_Missing;

    if ( FILE_Seek( face->dirTables[i].Offset ) ||
         ACCESS_Frame( 32L ) )
      return error;

    /* read frame data into face table */

    post->FormatType         = GET_ULong();
    post->italicAngle        = GET_ULong();
    post->underlinePosition  = GET_Short();
    post->underlineThickness = GET_Short();
    post->isFixedPitch       = GET_ULong();
    post->minMemType42       = GET_ULong();
    post->maxMemType42       = GET_ULong();
    post->minMemType1        = GET_ULong();
    post->maxMemType1        = GET_ULong();

    FORGET_Frame();

    /* we don't load the glyph names, we do that in a */
    /* library extension (ftxpost).                   */

    PTRACE2(( "loaded\n" ));

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Hdmx
 *
 *  Description :  Loads the horizontal device metrics table.
 *
 *  Input  :  face         face object to look for
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Hdmx( PFace  face )
  {
    DEFINE_LOCALS;

    TT_Hdmx_Record*  rec;
    TT_Hdmx          hdmx;
    Long             table;
    UShort           n, num_glyphs;
    Long             record_size;


    hdmx.version     = 0;
    hdmx.num_records = 0;
    hdmx.records     = 0;

    face->hdmx = hdmx;

    if ( ( table = TT_LookUp_Table( face, TTAG_hdmx ) ) < 0 )
      return TT_Err_Ok;

    if ( FILE_Seek( face->dirTables[table].Offset )  ||
         ACCESS_Frame( 8L ) )
      return error;

    hdmx.version     = GET_UShort();
    hdmx.num_records = GET_Short();
    record_size      = GET_Long();

    FORGET_Frame();

    /* Only recognize format 0 */

    if ( hdmx.version != 0 )
      return TT_Err_Ok;

    if ( ALLOC( hdmx.records, sizeof ( TT_Hdmx_Record ) * hdmx.num_records ) )
      return error;

    num_glyphs   = face->numGlyphs;
    record_size -= num_glyphs+2;
    rec          = hdmx.records;

    for ( n = 0; n < hdmx.num_records; n++ )
    {
      /* read record */

      if ( ACCESS_Frame( 2L ) )
        goto Fail;

      rec->ppem      = GET_Byte();
      rec->max_width = GET_Byte();

      FORGET_Frame();

      if ( ALLOC( rec->widths, num_glyphs )  ||
           FILE_Read( rec->widths, num_glyphs ) )
        goto Fail;

      /* skip padding bytes */
      if ( record_size > 0 )
        if ( FILE_Skip( record_size ) )
          goto Fail;

      rec++;
    }

    face->hdmx = hdmx;

    return TT_Err_Ok;

  Fail:
    for ( n = 0; n < hdmx.num_records; n++ )
      FREE( hdmx.records[n].widths );

    FREE( hdmx.records );
    return error;
  }


/*******************************************************************
 *
 *  Function    :  Free_TrueType_Hdmx
 *
 *  Description :  Frees the horizontal device metrics table.
 *
 *  Input  :  face         face object to look for
 *
 *  Output :  TT_Err_Ok.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Free_TrueType_Hdmx( PFace  face )
  {
    UShort  n;


    if ( !face )
      return TT_Err_Ok;

    for ( n = 0; n < face->hdmx.num_records; n++ )
      FREE( face->hdmx.records[n].widths );

    FREE( face->hdmx.records );
    face->hdmx.num_records = 0;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_TrueType_Any
 *
 *  Description :  Loads any font table into client memory. Used by
 *                 the TT_Get_Font_Data() API function.
 *
 *  Input  :  face     face object to look for
 *
 *            tag      tag of table to load. Use the value 0 if you
 *                     want to access the whole font file, else set
 *                     this parameter to a valid TrueType table tag
 *                     that you can forge with the MAKE_TT_TAG
 *                     macro.
 *
 *            offset   starting offset in the table (or the file
 *                     if tag == 0 )
 *
 *            buffer   address of target buffer
 *
 *            length   address of decision variable :
 *
 *                       if length == NULL :
 *                             load the whole table. returns an
 *                             an error if 'offset' == 0 !!
 *
 *                       if *length == 0 :
 *                             exit immediately, returning the
 *                             length of the given table, or of
 *                             the font file, depending on the
 *                             value of 'tag'
 *
 *                       if *length != 0 :
 *                             load the next 'length' bytes of
 *                             table or font, starting at offset
 *                             'offset' (in table or font too).
 *
 *  Output :  Error condition
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Load_TrueType_Any( PFace  face,
                               ULong  tag,
                               Long   offset,
                               void*  buffer,
                               Long*  length )
  {
    TT_Stream  stream;
    TT_Error   error;
    Long       table;
    ULong      size;


    if ( tag != 0 )
    {
      /* look for tag in font directory */
      table = TT_LookUp_Table( face, tag );
      if ( table < 0 )
        return TT_Err_Table_Missing;

      offset += face->dirTables[table].Offset;
      size    = face->dirTables[table].Length;
    }
    else
      /* tag = 0 -- the use want to access the font file directly */
      size = TT_Stream_Size( face->stream );

    if ( length && *length == 0 )
    {
      *length = size;
      return TT_Err_Ok;
    }

    if ( length )
      size = *length;

    if ( !USE_Stream( face->stream, stream ) )
      (void)FILE_Read_At( offset, buffer, size );
    DONE_Stream( stream );

    return error;
  }


/* END */
