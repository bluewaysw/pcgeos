#ifndef __IMPGIF_H
#define __IMPGIF_H

#include <geos.h>
#include "impbmp\ibcommon.h"
#include "awatcher.h"
#include <htmldrv.h>

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

typedef enum {
    IG_STATUS_OK,
    IG_STATUS_GIF_DONE,
    IG_STATUS_NEED_DATA,
    IG_STATUS_END_DATA,
    IG_STATUS_ERROR_NOT_GIF,
    IG_STATUS_ERROR,
    IG_STATUS_FOUND_END_OF_GIF,
    IG_STATUS_COULD_NOT_CREATE,
    IG_STATUS_NO_GRAPHIC,
    IG_STATUS_ABORTED
} ImpGIFStatus ;

typedef MemHandle GIFHandle ;

typedef byte GIFDisposalMethod ;
#define GDM_NOT_SPECIFIED                               0
#define GDM_DO_NOT_DISPOSE                              1
#define GDM_OVERWRITE_BACKGROUND_WITH_BACKGROUND_COLOR  2
#define GDM_OVERWRITE_PREVIOUS_GRAPHIC                  3

typedef struct {
    word IGI_fieldWidth ;
    word IGI_fieldHeight ;
    word IGI_bitmapWidth ;
    word IGI_bitmapHeight ;
    word IGI_bitmapX ;
    word IGI_bitmapY ;
    word IGI_delay ;
    VMBlockHandle IGI_bitmap ;
    BMType IGI_format ;
    GIFDisposalMethod IGI_removeMethod ;
    byte IGI_backgroundColor ;
    dword IGI_memoryUsed ;
    word IGI_loopCount ;   /* 0 = forever */
    RGBValue IGI_palette[256] ;
    RGBValue IGI_globalPalette[256] ;
} ImpGIFInfo ;

#if PROGRESS_DISPLAY
typedef struct {
    word IGPI_fieldWidth;
    word IGPI_fieldHeight;
    word IGPI_bitmap;
    word IGPI_yPos;
} ImpGIFProgressInfo;
#endif

#define GIF_ANIMATION_FORMAT (BMF_8BIT | \
                              BMT_HUGE | \
                              BMT_PALETTE | \
                              BMT_MASK | \
                              BMT_COMPLEX)

ImpBmpStatus _pascal ImpGIFProcessFile(
                         ImpBmpParams *params,
                         AllocWatcherHandle watcher,
                         dword *usedMem,
                         MimeRes resolution,
                         Boolean useSysPal,
                         word statusMsg) ;

ImpBmpStatus _pascal ImpGIFTestFile(FileHandle file);

ImpBmpStatus _pascal ImpGIFProcess(
                         GIFHandle impgifhandle,
                         void *inData,
                         word numDataBytes,
                         Boolean isLast) ;

void _pascal ImpGIFGetInfo(
                 GIFHandle impgifhandle,
                 ImpGIFInfo *p_info) ;

#if PROGRESS_DISPLAY
void _pascal ImpGIFGetProgressInfo(
                 GIFHandle impgifhandle,
                 ImpGIFProgressInfo *p_info) ;
#endif

GIFHandle _pascal ImpGIFCreate(
                      VMFileHandle vm,
                      AllocWatcherHandle watcher,
                      Boolean useSysPal,
                      MimeStatus *mimeStatus) ;

void _pascal ImpGIFDestroy(GIFHandle impgifhandle) ;

ImpBmpStatus _pascal ImpGIFProcessAnimationFile(
                         ImpBmpParams *params,
                         TCHAR *filename,
                         AllocWatcherHandle watcher,
                         dword *usedMem,
                         MimeRes resolution,
                         Boolean useSysPal,
                         word statusMsg,
                         Boolean *p_isAnimation,
                         Boolean *p_isComplete) ;

#endif
