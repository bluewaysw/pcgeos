#ifndef __WEBPINT_H
#define __WEBPINT_H

#include <geos.h>
#include <file.h>
#include <graphics.h>
#include <heap.h>
#include <lmem.h>
#include <hugearr.h>
#include <vm.h>
#include <ec.h>
#include <Ansi/string.h>
#include <webplib.h>

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

#define WEBP_MAX_DIMENSION       2048
#define WEBP_INPUT_WINDOW        2048
#define WEBP_INPUT_BUFFER_SIZE   (WEBP_INPUT_WINDOW * 2)
#define WEBP_MAX_PARTITIONS      8
#define WEBP_CORE_WORDS          1364

#define WEBP_FOURCC(a, b, c, d) \
    ((dword)(byte)(a) | ((dword)(byte)(b) << 8) | \
     ((dword)(byte)(c) << 16) | ((dword)(byte)(d) << 24))

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
    HugeArrayDirectory directory;
    CBitmap bitmap;
} WebPBitmapHeader;

typedef struct {
    FileHandle source;
    VMFileHandle destination;
    VMBlockHandle bitmap;
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
    MemHandle inputH;
    byte *inputP;
    MemHandle contextH;
    MemHandle lumaH;
    MemHandle chromaH;
    MemHandle rgbH;
    /*
     * ATTENTION: This is the Watcom target size of WebPCore, rounded up
     * to words. WebPCoreSizeCheck fails if the core grows; remeasure and
     * increase WEBP_CORE_WORDS in that case.
     */
    word core[WEBP_CORE_WORDS];
} WebPDecoder;

WebPResult _pascal WebPParseContainer(FileHandle source, WebPDecoder *decoderP);
WebPResult _pascal WebPDecodeInit(WebPDecoder *decoderP);
WebPResult _pascal WebPDecodeRow(WebPDecoder *decoderP,
                                word *firstLine, word *lineCount);
void _pascal WebPDecodeCleanup(WebPDecoder *decoderP);

void _pascal WebPBoolInit(WebPDecoder *decoderP, WebPBoolReader *readerP,
                          dword start, dword length, Boolean token);
word _pascal WebPBoolGet(WebPDecoder *decoderP, WebPBoolReader *readerP,
                         word probability);
word _pascal WebPBoolGetValue(WebPDecoder *decoderP,
                              WebPBoolReader *readerP, word bitCount);

void _pascal WebPYUVToRGB(byte y, byte u, byte v, byte *rgbP);

/* Locked pixel buffers; acrossStep crosses an edge, alongStep follows it. */
void _pascal WebPFilterSimple(byte *pixelsP, word acrossStep, word alongStep,
                              word count, word thresh);
void _pascal WebPFilter24(byte *pixelsP, word acrossStep, word alongStep,
                          word count, word thresh, word innerThresh,
                          word hevThresh);
void _pascal WebPFilter26(byte *pixelsP, word acrossStep, word alongStep,
                          word count, word thresh, word innerThresh,
                          word hevThresh);

#endif
