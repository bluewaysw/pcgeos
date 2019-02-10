#include <Ansi/string.h>
#include "GRAPH/quant.h"
#include <heap.h>

byte QuantCompactBox(RGBValue *pal, word size)
{
  int rmax, gmax, bmax, rmin, gmin, bmin;
  word count;

  rmin = 256;
  gmin = 256;
  bmin = 256;
  rmax = -1;
  gmax = -1;
  bmax = -1;

  count = 0;

  while(count != size)
  {
    if(pal[count].RGB_red > rmax)
      rmax = pal[count].RGB_red;
    if(pal[count].RGB_green > gmax)
      gmax = pal[count].RGB_green;
    if(pal[count].RGB_blue > bmax)
		bmax = pal[count].RGB_blue;

	 if(pal[count].RGB_red < rmin)
		rmin = pal[count].RGB_red;
	 if(pal[count].RGB_green < gmin)
		gmin = pal[count].RGB_green;
	 if(pal[count].RGB_blue < bmin)
		bmin = pal[count].RGB_blue;

	 count++;
  };

  if(((rmax - rmin) > (gmax - gmin)) && ((rmax - rmin) > (bmax - bmin)))
	 return(0);

  if(((gmax - gmin) > (rmax - rmin)) && ((gmax - gmin) > (bmax - bmin)))
	 return(1);

  return(2);
};

void QuantSortPalette(RGBValue *pal, word size, byte sortentry)
{
  word i, j;
  RGBValue swap;
  NewRGBValue *isrc, *jsrc;

  i = 0;
  do
  {
	 isrc = (NewRGBValue *)&(pal[i]);
	 j = i;
	 do
	 {
		jsrc = (NewRGBValue *)&(pal[j]);
		if(isrc[0][sortentry] > jsrc[0][sortentry])
		{
		  swap = pal[i];
		  pal[i] = pal[j];
		  pal[j] = swap;
		};
		j++;
	 }
	 while(j != size);
	 i++;
  }
  while(i != (size-1));

};

word QuantSplitBox(QuantPalMgr *manager, word entry)
{
  byte len;
  word startentry, size;

  startentry = manager->QPM_size;

  size = manager->QPM_table[entry].QLE_count;

  if(size != 1)
  {
	 len = QuantCompactBox(manager->QPM_table[entry].QLE_palette,
			  manager->QPM_table[entry].QLE_count);
	 QuantSortPalette(manager->QPM_table[entry].QLE_palette,
			  manager->QPM_table[entry].QLE_count, len);

	 manager->QPM_table[startentry].QLE_palette =
			  manager->QPM_table[entry].QLE_palette;
	 manager->QPM_table[startentry].QLE_count = size / 2;

	 manager->QPM_table[startentry + 1].QLE_palette =
			  (manager->QPM_table[entry].QLE_palette + size / 2);
	 manager->QPM_table[startentry + 1].QLE_count = size - size / 2;

	 manager->QPM_size += 2;
	 return(2);
  }
  else
  {
	 manager->QPM_table[startentry].QLE_palette =
			  manager->QPM_table[entry].QLE_palette;
	 manager->QPM_table[startentry].QLE_count = size;
	 manager->QPM_size ++;
	 return(1);

  };
};

void
QuantSplitBoxes(QuantPalMgr *manager, word max)
{
  word startsize, count, newboxes;

  startsize = manager->QPM_size;

  count = 0;
  newboxes = 0;

  while((count != startsize) && (newboxes < max))
  {
	 newboxes += QuantSplitBox(manager, count);
	 count++;
  };
  memcpy(manager->QPM_table, &(manager->QPM_table[startsize]),
			  sizeof(QuantListEntry) * newboxes);
  manager->QPM_size = newboxes;
};

void QuantPalEntry(RGBValue *boxpal, word boxsize, RGBValue *newcol)
{
  word rsumme = 0, gsumme = 0, bsumme = 0;
  word count;

  count = 0;
  while(count != boxsize)
  {
    rsumme += boxpal[count].RGB_red;
    gsumme += boxpal[count].RGB_green;
    bsumme += boxpal[count].RGB_blue;
    count++;
  };

  newcol->RGB_red = rsumme / boxsize;
  newcol->RGB_green = gsumme / boxsize;
  newcol->RGB_blue = bsumme / boxsize;
};

void QuantCalcPalette(QuantPalMgr *manager, RGBValue *dest)
{
  word count;

  count = 0;
  while(count != manager->QPM_size)
  {
	 QuantPalEntry(manager->QPM_table[count].QLE_palette,
		  manager->QPM_table[count].QLE_count,
		  &(dest[count]));
	 count++;
  };
};

void QuantPalette(RGBValue *srcpal, word srcsize,
		  RGBValue *destpal, word destsize)
{
  QuantPalMgr *manager;
  MemHandle mem;

  mem = MemAlloc(sizeof(QuantPalMgr), 0, 0);
  manager = (QuantPalMgr *)MemLock(mem);
  manager->QPM_size = 1;
  manager->QPM_table[0].QLE_palette = srcpal;
  manager->QPM_table[0].QLE_count = srcsize;

  while(manager->QPM_size != destsize)
	 QuantSplitBoxes(manager, destsize);

  QuantCalcPalette(manager, destpal);
  MemUnlock(mem);
  MemFree(mem);
};
