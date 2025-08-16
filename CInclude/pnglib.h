#ifndef __PNGLIB_H
#define __PNGLIB_H

#include <geos.h>
#include <stdio.h>
#include <Ansi/stdlib.h>
#include <Ansi/string.h>
#include <graphics.h>
#include <vm.h>
#include <hugearr.h>
#include <zlib.h>
#include <file.h>
#include <heap.h>
#include <htmldrv.h>

// PNG-Chunks
#define PNG_CHUNK_IHDR 0x49484452  // "IHDR"
#define PNG_CHUNK_IDAT 0x49444154  // "IDAT"
#define PNG_CHUNK_IEND 0x49454E44  // "IEND"
#define PNG_CHUNK_PLTE 0x504C5445  // "PLTE"

// buffers for ZLIB
#define PNG_CHUNK_SIZE_IN  2048     // 2048 4096
#define PNG_CHUNK_SIZE_OUT 4096     // 4096 8192

// PNG signature
const unsigned char PNG_SIGNATURE[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

// max palette entries
#define PNG_MAX_PALETTE_ENTRIES 256

// max IDAT chunk entries
#define PNG_MAX_IDAT_CHUNKS 100

// mximum scanline size
// 8192 = 8KB limit, equals 2048px width in RGBA and 1024px in 16-bit RGBA.
// 6144 = 6KB limit, equals 1536px width in RGBA and 768px in 16-bit RGBA.
#define PNG_MAX_SCANLINE_SIZE 6144

// Structure of IHDR - Chunk
typedef struct {
    unsigned long width;
    unsigned long height;
    unsigned char bitDepth;
    unsigned char colorType;
    unsigned char compressionMethod;
    unsigned char filterMethod;
    unsigned char interlaceMethod;
} pngIHDRData;

// Structure of pngChunkHeader
typedef struct {
    unsigned long length;
    unsigned long type;
} pngChunkHeader;

// IDAT Chunk entry
typedef struct {
    unsigned long length;
    unsigned long chunkPos;
} pngIDATChunkEntry;

// IDAT parsing state struct
typedef struct {
    z_stream strm;
    MemHandle inHan;
    unsigned char *in;
    word inOff;
    MemHandle outHan;
    unsigned char *out;
    word outOff;
    unsigned long rowBufferOffset;
    MemHandle currentRowHan;
    unsigned char *currentRow;
    MemHandle previousRowHandle;
    unsigned char *previousRow;
    unsigned long lineNo;
    unsigned long rowBytes;
    unsigned long bytesPerPixel;
    unsigned long bytesToRead;
    unsigned long length;
    unsigned long have;
    unsigned long outBufferPos;

    MemHandle idatChunksHan;
    int idatNumChunks;
    int idatChunkIdx;

    FileHandle file;
    pngIHDRData ihdr;
} pngIDATState;

// PLTE Chunk entry
typedef struct {
    unsigned long length;
    unsigned long chunkPos;
} pngPLTEChunkEntry;

// Filter types according to PNG specification
#define PNG_FILTER_NONE    0
#define PNG_FILTER_SUB     1
#define PNG_FILTER_UP      2
#define PNG_FILTER_AVERAGE 3
#define PNG_FILTER_PAETH   4

// Color Types
#define PNG_COLOR_TYPE_GREY        0   /* Grayscale */
#define PNG_COLOR_TYPE_RGB         2   /* Truecolor */
#define PNG_COLOR_TYPE_PALETTE     3   /* Indexed-color */
#define PNG_COLOR_TYPE_GREY_ALPHA  4   /* Grayscale with alpha */
#define PNG_COLOR_TYPE_RGBA        6   /* Truecolor with alpha */


typedef enum {
    PNG_AT_TRESHOLD = 0,
    PNG_AT_BLEND
} pngAlphaTransformMethod;

typedef struct {
    pngAlphaTransformMethod method;
    byte alphaThreshold;
    RGBValue blendColor;
} pngAlphaTransformData;

// Errors when exporting
typedef enum {
    PE_NO_ERROR,
    PE_INVALID_BITMAP,
    PE_OUT_OF_MEMORY,
    PE_BLOCK_LOCK_FAILURE,
    PE_WRITE_PROBLEM,
    PE_PALETTE_RETRIEVAL_FAILURE,
    PE_OTHER_ERROR
} PngError;


/* Public API */
VMBlockHandle   _pascal _export pngImportConvertFile(FileHandle fileHan, VMFileHandle vmFile);

int             _pascal _export pngImportCheckHeader(FileHandle file);
int             _pascal _export pngImportProcessChunks(FileHandle file, pngIHDRData* ihdrData, MemHandle* idatChunksHan, int *idatNumChunks, pngPLTEChunkEntry* plteChunk);
BMFormat        _pascal _export pngImportWhatOutputFormat(unsigned char colorType, unsigned char bitDepth, pngAlphaTransformData* pngAlphaTransform);
VMBlockHandle   _pascal _export pngImportInitiateOutputBitmap(VMFileHandle vmFile, pngIHDRData ihdrData, BMFormat fmt);
void            _pascal _export pngImportHandlePalette(FileHandle file, pngPLTEChunkEntry plteChunk, VMFileHandle vmFile, VMBlockHandle vmBlock, unsigned char colorType, unsigned char bitDepth);
void            _pascal _export pngImportInitIDATProcessingState(pngIDATState* state, FileHandle file, MemHandle idatChunksHan, int idatNumChunks, pngIHDRData ihdr);
int             _pascal _export pngImportGetNextIDATScanline(pngIDATState* state);
void            _pascal _export pngImportIDATProcessingUnlockHandles(pngIDATState* state);
void            _pascal _export pngImportApplyGEOSFormatTransformations(pngIDATState* state, pngAlphaTransformData* pngAlphaTransform);
void            _pascal _export pngImportWriteScanlineToBitmap(VMFileHandle vmFile, VMBlockHandle bitmapHandle, unsigned long lineNo, unsigned char* rowData);
void            _pascal _export pngImportIDATProcessingLockHandles(pngIDATState* state);
void            _pascal _export pngImportCleanupIDATProcessingState(pngIDATState* state);

/* In a way internal, but sometimes helpful to access from outside */
unsigned long   _pascal _export pngCalcBytesPerRow(unsigned long width, unsigned char colorType, unsigned char bitDepth);
unsigned long   _pascal _export pngCalcBytesPerPixel(unsigned char colorType, unsigned char bitDepth);
unsigned long   _pascal _export pngCalcLineAllocSize(unsigned long width, unsigned char colorType, unsigned char bitDepth);
void            _pascal _export pngAlphaChannelBlend(unsigned char *data, unsigned long width, int colorType, RGBValue blendColor);
void            _pascal _export pngAlphaChannelToMask(unsigned char *data, unsigned long  width, int colorType, byte alphaThreshold);
void            _pascal _export pngConvert16BitLineTo8Bit(unsigned char *line, unsigned long width, unsigned char colorType, unsigned char bitDepth);
void            _pascal _export pngPad1BitTo4Bit(unsigned char *input, unsigned int width, unsigned char colorType, unsigned char bitDepth);
void            _pascal _export pngPad2BitTo4Bit(unsigned char *input, unsigned int width, unsigned char colorType, unsigned char bitDepth);

PngError        _pascal _export pngExportBitmapFHandle(VMFileHandle srcfile, VMBlockHandle bmpblock, FileHandle destfile);

#endif
