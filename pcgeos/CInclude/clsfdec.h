#ifndef _CLSFDEC_H
#define _CLSFDEC_H

#include <tif.h>

/* status constants */
#define IMAGE_DATA_UNAVAILABLE 0x01
#define IMAGE_DATA_FOUND       0x02
#define FILE_READ_ERROR        0x03
#define BAD_IFD_NUMBER         0x04
#define DECOMPRESSION_OK       0x05
#define DECOMPRESSION_ERROR    0x06
#define OUT_OF_MEMORY          0x07
#define NOT_TIF_FILE           0x08

/* other constants */
#define STRIP_READ_BUFFER_SIZE 8192
#define ONE_DIMENSIONAL        0x01
#define TWO_DIMENSIONAL        0x02

/* Fatal errors for EC code */
typedef enum {
    SYSTEM_ERROR_CODES,
    ERROR_CANT_GET_IFD_LIST,
    ERROR_UNKNOWN_CCITT_DECODE_TYPE,
} FatalErrors;

/* exported prototypes for ClsFDec library */
optr _pascal _far ClassFGetImageList(FileHandle tifFile);
word _pascal _far ClassFReadIFD(Image* image, FileHandle tifFile, dword fileOffset);
optr _pascal _far ClassFGetIFDList(FileHandle tifFile);
int _pascal _far ClassFGetInfo(FileHandle tifFile, int IFDNum, Image* image);
int _pascal _far ClassFDecompressTIFF(FileHandle tifFile, int ifdNum,				      
				      VMFileHandle *destBufFile, 
				      char         *destBufFileName,
				      optr* bitmapSliceList);
int  _pascal _far ClassFDecompressStrip(FileHandle tifFile, STRIP* strip, int stripIndex, Image* image,
					VMFileHandle destBufFile, optr* bitmapSliceList,
					int *scanLineStart, int* currBitmapSlice, int* currBitmapSliceLine);
void _pascal _far ClassFDecompressScanline(FileHandle tifFile, Image* image, char* srcBuffer,
					   dword* srcOffPos, int* srcBitPos, char* destBuffer);
#endif   /* _CLSFDEC_H */




