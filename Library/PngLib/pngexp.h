#ifndef __PNGEXPORT_H
#define __PNGEXPORT_H

#include "pnglib.h"

// returns FALSE on error
#define FILE_WRITE_CHECKED(file, buffer, size) (FileWrite((file), (buffer), (size), FALSE) == (size))

// Chunk Writing Functions
Boolean _pascal writePngHeader(FileHandle file);
Boolean _pascal writeIHDRChunk(FileHandle file, pngIHDRData* ihdrData);
Boolean _pascal writePLTEChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, BMType bmptype, BMFormat bitform);
Boolean _pascal writeIDATChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, pngIHDRData* ihdrData);
Boolean _pascal writeIENDChunk(FileHandle file);

// Processing Functions
dword _pascal calculateScanlineBufferSize(dword width, BMFormat bitform);
word _pascal calcBytesPerPixel(pngIHDRData* ihdrData);
void _pascal filterScanline(byte* scanlinePtr, byte* filteredScanlinePtr, byte *prevScanlinePtr, word scanlineSize, word bytesPerPixel);
Boolean _pascal deflateScanline(void *filteredScanlinePtr, word scanlineSize, z_stream *zstrm, FileHandle file, dword *idatChunkSize, dword *crc);

// Utility Functions
word _pascal mapGEOSToPNGColorType(BMType bmptype);

#endif // __PNGEXPORT_H
