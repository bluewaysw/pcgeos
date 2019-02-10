#ifndef __IMPPCX_H
#define __IMPPCX_H

#include <geos.h>
#include "IMPBMP/ibcommon.h"

typedef struct
{
  byte     IPFH_sign;
  byte     IPFH_version;
  byte     IPFH_compression;
  byte     IPFH_bitsPixel;
  word     IPFH_minx;
  word     IPFH_miny;
  word     IPFH_maxx;
  word     IPFH_maxy;
  word     IPFH_xRes;
  word     IPFH_yRes;
  RGBValue IPFH_palette[16];
  byte     IPFH_reserved;
  byte     IPFH_planes;
  word     IPFH_bytesPerLine;
  word     IPFH_palType;
  byte     IPFH_free[58];
} ImpPCXFileHeader;

typedef struct
{
  byte     IPS_byte;
  byte     IPS_count;
  word     IPS_width;
  word     IPS_size;
  byte     IPS_pack;
  BMFormat IPS_format;
  byte     IPS_planes;
} ImpPCXStream;

ImpBmpStatus _pascal ImpPCXProcessFile(ImpBmpParams *params);

ImpBmpStatus _pascal ImpPCXTestFile(FileHandle file);

#endif
