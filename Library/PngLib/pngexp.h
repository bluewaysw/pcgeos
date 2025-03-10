#ifndef __PNGEXPORT_H
#define __PNGEXPORT_H

// Function Declarations
Boolean _pascal pngExportBitmap(VMFileHandle srcfile, VMBlockHandle bmpblock, FileLongName destname, FileHandle destfile);
Boolean _pascal pngExportBitmapFName(VMFileHandle srcfile, VMBlockHandle bmpblock, PathName destname);
Boolean _pascal pngExportBitmapFHandle(VMFileHandle srcfile, VMBlockHandle bmpblock, FileHandle destfile);

// Chunk Writing Functions
Boolean _pascal writePngHeader(FileHandle file);
Boolean _pascal writePLTEChunk(FileHandle file, VMFileHandle srcfile, VMBlockHandle bmpblock, BMType bmptype, BMFormat bitform);
Boolean _pascal writeIHDRChunk(FileHandle file, dword width, dword height, BMType bmptype, BMFormat bitform);
Boolean _pascal writeIDATChunk(FileHandle file, void *scanlineBuffer, void *prevLine, dword scanlineSize, dword width, dword height, VMFileHandle srcfile, VMBlockHandle bmpblock);
Boolean _pascal writeIENDChunk(FileHandle file);

// Processing Functions
dword _pascal calculateScanlineBufferSize(dword width, BMFormat bitform);
void _pascal filterScanline(void *lineptr, void *scanlineBuffer, void *prevLine, word width, word bytesPerPixel);
Boolean _pascal deflateScanline(void *scanlineBuffer, dword scanlineSize, z_stream *zstrm, FileHandle file, dword *idatChunkSize, dword *crc);

// Utility Functions
word _pascal mapGEOSToPNGColorType(BMType bmptype);
static inline byte _pascal paethPredictor(byte a, byte b, byte c);
static inline int abs(int x);
static inline unsigned long swapEndian(unsigned long val);

#endif // __PNGEXPORT_H
