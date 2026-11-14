#ifndef __WEBPLIB_H
#define __WEBPLIB_H

#include <geos.h>
#include <file.h>
#include <vm.h>

typedef MemHandle WebPImportHandle;

typedef enum {
    WEBP_RESULT_OK = 0,
    WEBP_RESULT_DONE,
    WEBP_ERROR_WRONG_FORMAT,
    WEBP_ERROR_UNSUPPORTED,
    WEBP_ERROR_CORRUPT,
    WEBP_ERROR_READ,
    WEBP_ERROR_OUT_OF_MEMORY,
    WEBP_ERROR_IMAGE_TOO_LARGE,
    WEBP_ERROR_BAD_STATE
} WebPResult;

typedef struct {
    word width;
    word height;
} WebPImageInfo;

/*
 * source and destination remain caller-owned. On a successful Begin, bitmap
 * becomes caller-owned and must be freed with VMFreeVMChain if it is unwanted.
 * source must remain open and unused until decoder is destroyed.
 */
extern WebPResult _pascal _export
WebPImportBegin(FileHandle source, VMFileHandle destination,
                WebPImportHandle *decoder, VMBlockHandle *bitmap,
                WebPImageInfo *info);

/*
 * Decodes one macroblock row. Each OK result describes the exact newly
 * finalized scanline range. The call after the final range returns DONE.
 */
extern WebPResult _pascal _export
WebPImportNext(WebPImportHandle decoder, word *firstLine, word *lineCount);

/*
 * Safe for NullHandle. Does not close source or free a caller-owned bitmap.
 */
extern void _pascal _export
WebPImportDestroy(WebPImportHandle decoder);

#endif
