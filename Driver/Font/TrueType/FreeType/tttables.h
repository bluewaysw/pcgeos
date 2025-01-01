/*******************************************************************
 *
 *  tttables.h                                                  1.1
 *
 *    TrueType Tables structures and handling (specification).
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
 ******************************************************************/

#ifndef TTTABLES_H
#define TTTABLES_H

#include "ttconfig.h"
#include "tttypes.h"

#ifdef __cplusplus
  extern "C" {
#endif

  /***********************************************************************/
  /*                                                                     */
  /*                      TrueType Table Types                           */
  /*                                                                     */
  /***********************************************************************/

  /* TrueType Table Directory type */

  struct  TTableDir_
  {
    TT_Fixed  version;      /* should be 0x10000 */
    UShort    numTables;    /* number of tables  */

    UShort  searchRange;    /* These parameters are only used  */
    UShort  entrySelector;  /* for a dichotomy search in the   */
    UShort  rangeShift;     /* directory. We ignore them.      */
  };

  typedef struct TTableDir_  TTableDir;
  typedef TTableDir*         PTableDir;


  /* The 'TableDir' is followed by 'numTables' TableDirEntries */

  struct  TTableDirEntry_
  {
    ULong  Tag;        /*        table type */
    ULong  CheckSum;   /*    table checksum */
    ULong  Offset;     /* table file offset */
    ULong  Length;     /*      table length */
  };

  typedef struct TTableDirEntry_  TTableDirEntry;
  typedef TTableDirEntry*         PTableDirEntry;


  /* 'cmap' tables */

  struct  TCMapDir_
  {
    UShort  tableVersionNumber;
    UShort  numCMaps;
  };

  typedef struct TCMapDir_  TCMapDir;
  typedef TCMapDir*         PCMapDir;

  struct  TCMapDirEntry_
  {
    UShort  platformID;
    UShort  platformEncodingID;
    Long    offset;
  };

  typedef struct TCMapDirEntry_  TCMapDirEntry;
  typedef TCMapDirEntry*         PCMapDirEntries;


  /* 'maxp' Maximum Profiles table */

  struct  TMaxProfile_
  {
#ifdef TT_CONFIG_OPTION_SUPPORT_OPTIONAL_FIELDS
    TT_Fixed  version;
#endif
    UShort    numGlyphs,
              maxPoints,
              maxContours,
              maxCompositePoints,
              maxCompositeContours,
              maxZones,
              maxTwilightPoints,
              maxStorage,
              maxFunctionDefs,
              maxInstructionDefs,
              maxStackElements,
              maxSizeOfInstructions,
              maxComponentElements,
              maxComponentDepth;
  };

  typedef struct TMaxProfile_  TMaxProfile;
  typedef TMaxProfile*         PMaxProfile;


  /* table "gasp" */

#define GASP_GRIDFIT  0x01
#define GASP_DOGRAY   0x02

  struct  GaspRange_
  {
    UShort  maxPPEM;
    UShort  gaspFlag;
  };

  typedef struct GaspRange_  GaspRange;


  struct  TGasp_
  {
    UShort      version;
    UShort      numRanges;
    GaspRange*  gaspRanges;
  };

  typedef struct TGasp_  TGasp;


  /* table "head" - now defined in freetype.h */
  /* table "hhea" - now defined in freetype.h */


  /* tables "HMTX" and "VMTX" */

  struct  TLongMetrics_
  {
    UShort  advance;
    Short   bearing;
  };

  typedef struct TLongMetrics_  TLongMetrics, *PLongMetrics;

  typedef Short  TShortMetrics, *PShortMetrics;

  /* 'loca' location table type */

  struct  TLoca_
  {
    UShort    Size;
    PStorage  Table;
  };

  typedef struct TLoca_  TLoca;


  /* table "name" */

  struct  TNameRec_
  {
    UShort  platformID;
    UShort  encodingID;
    UShort  languageID;
    UShort  nameID;
    UShort  stringLength;
    UShort  stringOffset;

    /* this last field is not defined in the spec */
    /* but used by the FreeType engine            */

    PByte   string;
  };

  typedef struct TNameRec_  TNameRec;


  struct  TName_Table_
  {
    UShort     format;
    UShort     numNameRecords;
    UShort     storageOffset;
    TNameRec*  names;
    PByte      storage;
  };

  typedef struct TName_Table_  TName_Table;


#ifdef __cplusplus
  }
#endif

#endif /* TTTABLES_H */


/* END */
