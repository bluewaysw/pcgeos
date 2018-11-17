#ifndef __QUANT_H
#define __QUANT_H

#include <geos.h>
#include <color.h>

typedef byte NewRGBValue[3];

typedef struct
{
  RGBValue *QLE_palette;
  word     QLE_count;
} QuantListEntry;

typedef struct
{
  word           QPM_size;
  QuantListEntry QPM_table[512];
} QuantPalMgr;

void QuantPalette(RGBValue *srcpal, word srcsize,
		  RGBValue *destpal, word destsize);

#endif
