#ifndef __PNGEXPORT_H
#define __PNGEXPORT_H

#include "pnglib.h"

// returns FALSE on error
#define FILE_WRITE_CHECKED(file, buffer, size) (FileWrite((file), (buffer), (size), FALSE) == (size))

// Chunk Writing Functions
PngError _pascal writePngHeader(FileHandle file);
PngError _pascal writeIHDRChunk(FileHandle file, pngIHDRData* ihdrData);
PngError _pascal writePLTEChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, BMType bmptype, BMFormat bitform, pngIHDRData* ihdrData);
PngError _pascal writeIDATChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, pngIHDRData* ihdrData, BMType bmptype, BMFormat bitform);
PngError _pascal writeIENDChunk(FileHandle file);

// Processing Functions
dword _pascal calculateScanlineBufferSize(dword width, BMFormat bitform);
word _pascal calcBytesPerPixel(pngIHDRData* ihdrData);
byte _pascal getFilterForScanline(byte* scanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel, word bitDepth);
void _pascal filterScanline(byte* scanlinePtr, byte* filteredScanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel, word bitDepth);
Boolean _pascal deflateScanline(void *filteredScanlinePtr, word scanlineSize, z_stream *zstrm, FileHandle file, dword *idatChunkSize, dword *crc);

// Utility Functions
word _pascal mapGEOSToPNGColorType(BMType bmptype);

#endif // __PNGEXPORT_H
