
#ifndef __IMPGIF_H
#define __IMPGIF_H

#include <geos.h>
#include "xlat\ibcommon.h"

#define IG_HEADER_LEN 13
#define IG_PICDESC_LEN 10

typedef char ImpGIFSignString[3];

typedef struct
{
  ImpGIFSignString IGFH_sign;
  ImpGIFSignString IGFH_version;
  int              IGFH_srcWidth;
  int              IGFH_srcHeight;
  byte             IGFH_info;
  byte             IGFH_backColor;
  byte             IGFH_terminator;

  Boolean          IGFH_globPal;
  byte             IGFH_rgbBits;
  byte             IGFH_bitsPerPix;
  int              IGFH_colMapSize;
  word             IGFH_transparent;
} ImpGIFFileHeader;

typedef struct
{
  char    IGPD_sign;
  int     IGPD_left;
  int     IGPD_top;
  int     IGPD_width;
  int     IGPD_height;
  byte    IGPD_flags;

  Boolean IGPD_interlace;
  Boolean IGPD_localPal;
  byte    IGPD_pixSize;
  int     IGPD_colMapSize;
} ImpGIFPicDescriptor;

typedef union
{
  long int val;
  word single[2];
} ImpGIFInBuffer;

typedef struct
{
  byte           IGST_blockCount;
  byte           IGST_inCount;
  ImpGIFInBuffer IGST_inBuffer;
  byte           IGST_max;
} ImpGIFStream;

typedef struct
{
  word Prefix[4097];
  byte Suffix[4097];
  byte Outcode[1025];
} ImpGIFTables;

ImpBmpStatus _pascal ImpGIFProcessFile(ImpBmpParams *params);

ImpBmpStatus _pascal ImpGIFTestFile(FileHandle file);

#endif
