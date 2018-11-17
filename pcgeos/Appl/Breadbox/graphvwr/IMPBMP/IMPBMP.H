#ifndef __IMPBMP_H
#define __IMPBMP_H

#include <geos.h>
#include "impbmp\ibcommon.h"

#define IB_WIN_HEADER_SIZE 40
#define IB_OS2_12_HEADER_SIZE 12
#define IB_OS2_20_HEADER_SIZE 64

typedef struct
{
  char  IBFH_type[2];
  dword IBFH_size;
  word  IBFH_reserved1;
  word  IBFH_reserved2;
  dword IBFH_offset;
} ImpBMPFileHeader;

typedef struct
{
  dword IBBI_width;
  dword IBBI_height;
  word  IBBI_planes;
  word  IBBI_bitCount;
  dword IBBI_compression;
  dword IBBI_sizeImg;
  dword IBBI_xPels;
  dword IBBI_yPels;
  dword IBBI_colorsUsed;
  dword IBBI_colorImportant;
} ImpBMPBitmapInfo1;

typedef struct
{
  byte IBRQ_blue, IBRQ_green, IBRQ_red, IBRQ_reserved;
} ImpBMP_RGBquad;

typedef struct
{
  byte IBR_blue, IBR_green, IBR_red;
} ImpBMP_RGB;

typedef struct
{
  word  IBBI_width;
  word  IBBI_height;
  word  IBBI_planes;
  word  IBBI_bitCount;
} ImpBMPBitmapInfo2;

typedef struct
{
  dword IBBI_width;
  dword IBBI_height;
  word  IBBI_planes;
  word  IBBI_bitCount;
  dword IBBI_compression;
  dword IBBI_sizeImg;
  dword IBBI_xPels;
  dword IBBI_yPels;
  dword IBBI_colorsUsed;
  dword IBBI_colorImportant;
  byte  IBBI_reserved[24];
} ImpBMPBitmapInfo3;

typedef struct
{
  dword    IBPD_width;
  dword    IBPD_height;
  dword    IBPD_pack;
  dword    IBPD_bits;
  BMFormat IBPD_format;
  byte     IBPD_srcType;
} ImpBMPPicDesc;

typedef struct
{
  byte     IBS_byte;
  byte     IBS_count;
  word     IBS_width;
  word     IBS_size;
  byte     IBS_pack;
  BMFormat IBS_format;
} ImpBMPStream;

ImpBmpStatus _pascal ImpBMPProcessFile(ImpBmpParams *params);

ImpBmpStatus _pascal ImpBMPTestFile(FileHandle file);

#endif