#ifndef __IBCOMMON_H
#define __IBCOMMON_H

#include <geos.h>

typedef enum
{
  IBF_AUTO,
  IBF_BMP,
  IBF_PCX,
  IBF_TIFF,
  IBF_JPEG,
  IBF_GIF,
  IBF_PNG
} ImpBmpFormat;

typedef struct
{
  FileHandle    IBP_source;
  FileHandle    IBP_dest;
  optr          IBP_status;
  VMBlockHandle IBP_bitmap;
  word          IBP_width;
  word          IBP_height;
  BMType        IBP_format;
  char          IBP_impForm[31];
} ImpBmpParams;

typedef enum
{
  IBS_NO_ERROR,
  IBS_UNKNOWN_FORMAT,
  IBS_FORMAT_OK,
  IBS_WRONG_FORMAT,
  IBS_SYS_ERROR,
  IBS_WRONG_FILE,
  IBS_NO_MEMORY,
  IBS_IMPORT_STOPPED,
  IBS_UNSUPPORTED_COMPRESSION,
  IBS_OUT_OF_DATA
} ImpBmpStatus;

typedef struct
{
  byte       *IBST_mem;
  word       IBST_size;
  FileHandle IBST_file;
  word       IBST_count;
  word       IBST_index;
} ImpBmpStream;

typedef struct
{
  VMFileHandle  IBOST_file;
  VMBlockHandle IBOST_block;
  word          IBOST_width;
  word          IBOST_height;
  word          IBOST_x;
  word          IBOST_y;
  BMFormat      IBOST_format;
  byte          IBOST_outByte;
  byte          IBOST_inCount;
  word          IBOST_index;
  MemHandle     IBOST_mem;
  Boolean       IBOST_interlace;
  byte          IBOST_pass;
  word          IBOST_ycount;
  word          IBOST_maskoff;
  byte          IBOST_mask;
  byte          IBOST_maskCount;
  word          IBOST_maskIndex;
  word          IBOST_transparent;
  Boolean       IBOST_inverse;
  Boolean       IBOST_finished;
} ImpBmpOutStream;

typedef RGBValue ImpBmpPalette[256];

#endif
