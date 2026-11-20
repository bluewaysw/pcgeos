#ifndef __WEBPTEST_H
#define __WEBPTEST_H

#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#define _pascal
#define _export
#define FALSE 0
#define TRUE 1
#define NullHandle 0
#define FILE_POS_START 0
#define WEBP_INPUT_WINDOW 2048
#define WEBP_INPUT_BUFFER_SIZE 4096
#define WEBP_MAX_DIMENSION 2048
#define WEBP_MAX_PARTITIONS 8
#define HF_SWAPABLE 0
#define HAF_ZERO_INIT 0
#define BMF_24BIT 3
#define BMT_COMPLEX 0x10
#define HAL_COUNT(value) ((word)(value))

#if defined(__GNUC__)
#define WEBPTEST_UNUSED __attribute__((unused))
#else
#define WEBPTEST_UNUSED
#endif
#define WEBP_FOURCC(a, b, c, d) \
    ((dword)(byte)(a) | ((dword)(byte)(b) << 8) | \
     ((dword)(byte)(c) << 16) | ((dword)(byte)(d) << 24))

typedef uint8_t byte;
typedef int8_t sbyte;
typedef uint16_t word;
typedef uint32_t dword;
typedef int16_t sword;
typedef int32_t sdword;
typedef int Boolean;

typedef struct {
    const byte *dataP;
    dword size;
    dword position;
} TestFile;

typedef TestFile *FileHandle;
typedef void *MemHandle;
typedef void *VMFileHandle;

typedef struct {
    word width;
    word height;
    word rowBytes;
    word nextLine;
    byte *pixelsP;
} HostBitmap;

typedef HostBitmap *VMBlockHandle;
typedef MemHandle WebPImportHandle;

typedef struct {
    dword start;
    dword length;
    dword next;
    dword windowStart;
    word windowSize;
    dword value;
    byte range;
    sbyte bits;
    byte eof;
    byte ioError;
    byte token;
} WebPBoolReader;

typedef struct {
    FileHandle source;
    MemHandle inputH;
    byte *inputP;
    dword riffEnd;
    dword vp8Start;
    dword vp8Length;
    dword firstPartitionLength;
    word width;
    word height;
    word rowBytes;
    word mbWidth;
    word mbHeight;
    word mbY;
    word nextOutputLine;
    byte terminal;
    byte done;
    VMFileHandle destination;
    VMBlockHandle bitmap;
    MemHandle contextH;
    MemHandle lumaH;
    MemHandle chromaH;
    MemHandle rgbH;
    word core[2048];
} WebPDecoder;

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

#define EC_WARNING(code) ((void)(code))

typedef enum {
    WEBP_WARNING_LOSSLESS_NOT_SUPPORTED,
    WEBP_WARNING_ALPHA_NOT_SUPPORTED,
    WEBP_WARNING_ANIMATION_NOT_SUPPORTED,
    WEBP_WARNING_PREDICTED_FRAME_NOT_SUPPORTED,
    WEBP_WARNING_VP8_PROFILE_NOT_SUPPORTED,
    WEBP_WARNING_HIDDEN_FRAME_NOT_SUPPORTED,
    WEBP_WARNING_DECODER_ALLOCATION_FAILED,
    WEBP_WARNING_INPUT_BUFFER_ALLOCATION_FAILED,
    WEBP_WARNING_WORK_BUFFER_ALLOCATION_FAILED,
    WEBP_WARNING_OUTPUT_BITMAP_ALLOCATION_FAILED
} Warnings;

typedef struct {
    word width;
    word height;
} WebPImageInfo;

#define MemLock(handle) (handle)
#define MemUnlock(handle) ((void)(handle))

static dword FilePos(FileHandle fileP, dword position, word mode)
{
    (void)mode;
    fileP->position = position;
    return position;
}

static word FileRead(FileHandle fileP, void *bufferP, word size,
                     Boolean noError)
{
    (void)noError;
    if (fileP->position + size > fileP->size) {
        return 0;
    }
    memcpy(bufferP, fileP->dataP + fileP->position, size);
    fileP->position += size;
    return size;
}

#define FileSize(fileP) ((fileP)->size)

static unsigned hostMemoryBlocks WEBPTEST_UNUSED;
static int hostFailAfter WEBPTEST_UNUSED = -1;

static MemHandle WEBPTEST_UNUSED
MemAlloc(word size, word flags, word init)
{
    MemHandle blockH;

    (void)flags;
    (void)init;
    if (hostFailAfter == 0) {
        return NullHandle;
    }
    if (hostFailAfter > 0) {
        hostFailAfter--;
    }
    blockH = (MemHandle)calloc(1, size);
    if (blockH != NullHandle) {
        hostMemoryBlocks++;
    }
    return blockH;
}

static void WEBPTEST_UNUSED
MemFree(MemHandle handle)
{
    assert(handle != NullHandle && hostMemoryBlocks != 0);
    hostMemoryBlocks--;
    free(handle);
}

static VMBlockHandle WEBPTEST_UNUSED
GrCreateBitmapRaw(word format, word width, word height, VMFileHandle file)
{
    HostBitmap *bitmapP;

    (void)format;
    (void)file;
    bitmapP = (HostBitmap *)calloc(1, sizeof(HostBitmap));
    if (bitmapP == (void *)0) {
        return NullHandle;
    }
    bitmapP->width = width;
    bitmapP->height = height;
    bitmapP->rowBytes = width * 3;
    bitmapP->pixelsP = (byte *)calloc(height, bitmapP->rowBytes);
    if (bitmapP->pixelsP == (void *)0) {
        free(bitmapP);
        return NullHandle;
    }
    return bitmapP;
}

static dword WEBPTEST_UNUSED
HugeArrayLock(VMFileHandle file, VMBlockHandle bitmapP, dword line,
              void **rowP, word *sizeP)
{
    (void)file;
    if (line >= bitmapP->height) {
        return 0;
    }
    *rowP = bitmapP->pixelsP + line * bitmapP->rowBytes;
    *sizeP = bitmapP->rowBytes;
    return 1;
}

static dword WEBPTEST_UNUSED
HugeArrayAppend(VMFileHandle file, VMBlockHandle bitmapP, word packedSize,
                const void *packedDataP)
{
    const byte *sourceP;
    byte *destinationP;
    word source;
    word destination;
    word count;
    sbyte control;

    (void)file;
    if (bitmapP->nextLine >= bitmapP->height) {
        return 0;
    }
    sourceP = (const byte *)packedDataP;
    destinationP = bitmapP->pixelsP +
                   bitmapP->nextLine * bitmapP->rowBytes;
    source = destination = 0;
    while (source < packedSize && destination < bitmapP->rowBytes) {
        control = (sbyte)sourceP[source++];
        if (control >= 0) {
            count = (word)control + 1;
            if (source + count > packedSize ||
                destination + count > bitmapP->rowBytes) {
                return 0;
            }
            memcpy(destinationP + destination, sourceP + source, count);
            source += count;
        } else if (control != -128) {
            count = (word)(1 - control);
            if (source >= packedSize ||
                destination + count > bitmapP->rowBytes) {
                return 0;
            }
            memset(destinationP + destination, sourceP[source++], count);
        } else {
            count = 0;
        }
        destination += count;
    }
    if (source != packedSize || destination != bitmapP->rowBytes) {
        return 0;
    }
    bitmapP->nextLine++;
    return bitmapP->nextLine - 1;
}

#define HugeArrayDirty(rowP) ((void)(rowP))
#define HugeArrayUnlock(rowP) ((void)(rowP))

WebPResult _pascal WebPParseContainer(FileHandle source,
                                      WebPDecoder *decoderP);
WebPResult _pascal WebPDecodeInit(WebPDecoder *decoderP);
WebPResult _pascal WebPDecodeRow(WebPDecoder *decoderP,
                                word *firstLine, word *lineCount);
void _pascal WebPDecodeCleanup(WebPDecoder *decoderP);
void _pascal WebPBoolInit(WebPDecoder *decoderP,
                          WebPBoolReader *readerP,
                          dword start, dword length, Boolean token);
word _pascal WebPBoolGet(WebPDecoder *decoderP,
                         WebPBoolReader *readerP, word probability);
word _pascal WebPBoolGetValue(WebPDecoder *decoderP,
                              WebPBoolReader *readerP, word bitCount);
void _pascal WebPYUVToRGB(byte y, byte u, byte v, byte *rgbP);

#endif
