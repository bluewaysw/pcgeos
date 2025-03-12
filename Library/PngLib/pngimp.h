#ifndef __PNGIMPORT_H
#define __PNGIMPORT_H

#include "pnglib.h"

// some internal functions
int nextIDATChunk(pngIDATState* state);
static void unfilterRow(unsigned char *data, unsigned char *previousRow, unsigned long bytesPerPixel, unsigned long rowBytes);

#endif // __PNGIMPORT_H
