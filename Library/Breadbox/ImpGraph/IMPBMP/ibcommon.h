#ifndef __IBCOMMON_H
#define __IBCOMMON_H

#include <geos.h>
#include <product.h>

/* turn on to compress per-scanline */
#define SCANLINE_COMPRESS -1

/* turn on for LZG bitmap compression, requires new kernel library */
#define LZG_COMPRESS -1

#if PROGRESS_DISPLAY
#define __FIXES_H  /* don't want this included by htmldrv.h */
/* so we don't need to include graphics.h since we'll get warnings about
   some defines below */
#ifndef __GRAPHICS_H
typedef struct {
    sword	P_x;
    sword	P_y;
} Point;
typedef struct {
    word	XYS_width;
    word	XYS_height;
} XYSize;
typedef struct {
    sword	R_left;
    sword	R_top;
    sword	R_right;
    sword	R_bottom;
} Rectangle;
#endif
#include <htmldrv.h>
#endif

typedef enum
{
  IBF_AUTO,
  IBF_BMP,
  IBF_PCX,
  IBF_TIFF,
  IBF_JPEG,
  IBF_GIF
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
#if PROGRESS_DISPLAY
  FileHandle    IBP_animDest;  /* destination for animated GIFs */
  ImportProgressData *IBP_importProgressDataP;
#endif
  MimeStatus    *IBP_mimeStatus ;
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
  IBS_IMPORT_STOPPED
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
  Color *       IBOST_colorMap ;
} ImpBmpOutStream;

typedef RGBValue ImpBmpPalette[256];

#if SCANLINE_COMPRESS
word _pascal ImpPackBits(byte *destBits, byte *srcBits, word srcSize);
#endif

#endif
