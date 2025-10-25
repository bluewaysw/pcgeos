#include <geos.h>
#include <heap.h>
#include <gstring.h>
#include <Ansi/string.h>
#include <lmem.h>
#include <color.h>
#include <vm.h>

#include "extgraph.h"

/*========================================================================*/

/* local structures */

typedef struct
{
  word     PT_size;
  word     PT_used;
  RGBValue PT_entry[1];
} palTable;

/* local prototypes */

Boolean
palAddColor(MemHandle mem, RGBValue  *entry);

Boolean
palAddColorRange(MemHandle mem, RGBValue  *entry, word count);

Boolean
palAddBitmapPal(MemHandle mem, byte *ptr);

Boolean
palAddColorQuad(MemHandle mem, RGBColorAsDWord color);

Boolean _far _pascal
palGStringColElement(byte *elm, GStateHandle gstate, MemHandle mem);

void _pascal _export
My_GrParseGString(GStateHandle gstate,GStateHandle gstring,
		  word flags,MemHandle h_global);

/*------------------------------------------------------------------------*/

/* local structures */

typedef byte palRGBValue[3];

typedef struct
{
  RGBValue *PQLE_palette;
  word      PQLE_count;
} palQuantListEntry;

typedef struct
{
  word              PQM_size;
  palQuantListEntry PQM_table[512];
} palQuantMgr;

/* local prototypes */

byte
palCompactQuantBox(RGBValue *pal, word size);

void
palSortQuant(RGBValue *pal, word size, byte sortentry);

word
palSplitQuantBox(palQuantMgr *manager, word entry);

void
palSplitQuantBoxes(palQuantMgr *manager, word max);

void
palQuantEntry(RGBValue *boxpal, word boxsize, RGBValue *newcol);

void
palCalcQuant(palQuantMgr *manager, RGBValue *dest);

/*========================================================================*/

/* This fuction is a callback for each output element in the gstring
   and records used colors */

Boolean _far _pascal
palGStringColElement(byte *elm, GStateHandle gstate, MemHandle mem)
{
	Boolean stat;
	RGBColorAsDWord col2;
	byte *ptr;
	optr obj;

	stat = FALSE;

	if(((*elm >= 0x20) && (*elm <= 0x39)) || (*elm == 0x41))
	{
	/* line color used */
	col2 = GrGetLineColor(gstate);
	stat = palAddColorQuad(mem, col2);
	}
	else
	if((*elm >= 0x3a) && (*elm <= 0x40))
	{
		/* text color */
		col2 = GrGetTextColor(gstate);
		stat = palAddColorQuad(mem, col2);
	}
	else
		if((*elm >= 0x42) && (*elm <= 0x4F))
		{
		/* area color */
		col2 = GrGetAreaColor(gstate);
		stat = palAddColorQuad(mem, col2);
		}
		else
		if(*elm == 0x50)
		{
			/* bitmap with position */
			ptr = &elm[7];
			stat = palAddBitmapPal(mem, ptr);
		}
		else
			if(*elm == 0x51)
			{
			/* bitmap without pos */
			ptr = &elm[3];
			stat = palAddBitmapPal(mem, ptr);
			}
			else
			if(*elm == 0x52)
			{
				/* bitmap at optr */
				obj = (dword) *(&elm[5]);
				ptr = MemLock(HandleOf(obj));

				if(ptr == 0)
				stat = TRUE;
				else
				{
				ptr = LMemDeref(obj);
				stat = palAddBitmapPal(mem, ptr);
				MemUnlock(HandleOf(obj));
				}
			}
			else
				if(*elm == 0x53)
				{
				/* bitmap at ptr */
				ptr = (byte*) *(&elm[5]);
				stat = palAddBitmapPal(mem, ptr);
				}

	return stat;   /* FALSE if no error accures */
}

/*========================================================================*/

/* utility functions for building up an palette table */

Boolean
palAddColor(MemHandle mem, RGBValue  *entry)
{
	MemHandle mem2;
	palTable *pal;
    Boolean colorFound = FALSE ;
    word loopCount ;

	pal = MemLock(mem);

	if(pal == 0)
	return(TRUE);

    /* check if the color is already in there */
    loopCount = 0 ;
    while(loopCount < pal->PT_used) {

        if( (entry->RGB_red == pal->PT_entry[loopCount].RGB_red) &&
            (entry->RGB_green == pal->PT_entry[loopCount].RGB_green) &&
            (entry->RGB_blue == pal->PT_entry[loopCount].RGB_blue)    ) {

            colorFound = TRUE ;
            break ;
        }

        loopCount++ ;
    }

    if(colorFound) {

		MemUnlock(mem);
		return(FALSE);
    }

	if(pal->PT_size == pal->PT_used)
	{
	    if(pal->PT_size > 3000)
	    {
		    MemUnlock(mem);
		    return(TRUE);
	    }

	    mem2 = MemReAlloc(mem, 4+(pal->PT_size+32)*3, 0);

	    if(mem2 == 0)
	    {
		    MemUnlock(mem);
		    return(TRUE);
	    }

	    mem = mem2;
	    pal = MemDeref(mem);
	    pal->PT_size+=32;
	}

	pal->PT_entry[pal->PT_used] = *entry;
	pal->PT_used++;

	MemUnlock(mem);

	return(FALSE);
}

/*------------------------------------------------------------------------*/

Boolean
palAddColorRange(MemHandle mem, RGBValue  *entry, word count)
{
	word count2;
	Boolean stat;
	palTable *pal;

	pal = MemLock(mem);
	if(pal == 0)
	return(TRUE);

	count2 = 0;
	stat = FALSE;

	while((count != count2)&(stat == FALSE))
	{
	stat = palAddColor(mem, &entry[count2]);
	count2++;
	}

	MemUnlock(mem);

	return(stat);
}

/*------------------------------------------------------------------------*/

Boolean
palAddBitmapPal(MemHandle mem, byte *ptr)
{
	byte type;
	word offset;
    RGBValue white = {255, 255, 255}, black = {0, 0, 0} ;

	type = ptr[5];

	if((type && BMT_FORMAT) == BMF_MONO)
	{
	    /* black and white */
        palAddColor(mem, &white) ;
        palAddColor(mem, &black) ;
	}
	else
	if( ((type & BMT_COMPLEX) == 0)||
		((type & BMT_PALETTE) == 0)||
		((type & BMT_FORMAT) == BMF_24BIT))
	{
        GStateHandle gstate ;

        gstate = GrCreateState(0) ;

        if(gstate) {

            MemHandle palmem ;
            word numEntries ;

            palmem = GrGetPalette(gstate, GPT_DEFAULT) ;

            GrDestroyState(0) ;

            if(palmem) {

                numEntries = (*((word*) MemLock(palmem))) ;

                /* user system palette */
                if(((type & BMT_FORMAT) == BMF_4BIT) || (numEntries < 256)) {

                    if(numEntries >= 16) {

                        palAddColorRange(mem, (RGBValue*) MemDeref(palmem) + 2, 16);
                    }

                } else {

                    if(numEntries >= 256) {

                        palAddColorRange(mem, (RGBValue*) MemDeref(palmem) + 2, 256);
                    }
                }

                MemFree(palmem) ;
            }
        }

	}
	else
	{
		/* user bitmap palette */
		offset = ptr[14]+256*(ptr[15]);

		if((type & BMT_FORMAT) == BMF_4BIT)
		palAddColorRange(mem, (RGBValue *) &ptr[offset], 16);
		else
		palAddColorRange(mem, (RGBValue *) &ptr[offset], 256);
	}

	return(FALSE);
}

/*------------------------------------------------------------------------*/

Boolean
palAddColorQuad(MemHandle mem, RGBColorAsDWord color)
{
	RGBValue value;

	value.RGB_red = RGB_RED(color);
	value.RGB_green = RGB_GREEN(color);
	value.RGB_blue = RGB_BLUE(color);

	return(palAddColor(mem, &value));
}

/*========================================================================*/

/* */

byte
palCompactQuantBox(RGBValue *pal, word size)
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
	}

	if(((rmax - rmin) > (gmax - gmin)) && ((rmax - rmin) > (bmax - bmin)))
	return(0);

	if(((gmax - gmin) > (rmax - rmin)) && ((gmax - gmin) > (bmax - bmin)))
	return(1);

	return(2);
}

/*------------------------------------------------------------------------*/

void
palSortQuant(RGBValue *pal, word size, byte sortentry)
{
  word i, j;
  RGBValue swap;
  palRGBValue *isrc, *jsrc;

  i = 0;
  do
  {
	 isrc = (palRGBValue *)&(pal[i]);
	 j = i;
	 do
	 {
	jsrc = (palRGBValue *)&(pal[j]);
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

/*------------------------------------------------------------------------*/

word
palSplitQuantBox(palQuantMgr *manager, word entry)
{
  byte len;
  word startentry, size;

  startentry = manager->PQM_size;

  size = manager->PQM_table[entry].PQLE_count;

  if(size != 1)
  {
	 len = palCompactQuantBox(manager->PQM_table[entry].PQLE_palette,
		  manager->PQM_table[entry].PQLE_count);
	 palSortQuant(manager->PQM_table[entry].PQLE_palette,
		  manager->PQM_table[entry].PQLE_count, len);

	 manager->PQM_table[startentry].PQLE_palette =
		  manager->PQM_table[entry].PQLE_palette;
	 manager->PQM_table[startentry].PQLE_count = size / 2;

	 manager->PQM_table[startentry + 1].PQLE_palette =
		  (manager->PQM_table[entry].PQLE_palette + size / 2);
	 manager->PQM_table[startentry + 1].PQLE_count = size - size / 2;

	 manager->PQM_size += 2;
	 return(2);
  }
  else
  {
	 manager->PQM_table[startentry].PQLE_palette =
		  manager->PQM_table[entry].PQLE_palette;
	 manager->PQM_table[startentry].PQLE_count = size;
	 manager->PQM_size ++;
	 return(1);

  };
};

/*------------------------------------------------------------------------*/

void
palSplitQuantBoxes(palQuantMgr *manager, word max)
{
  word startsize, count, newboxes;

  startsize = manager->PQM_size;

  count = 0;
  newboxes = 0;

  while((count != startsize) && (newboxes < max))
  {
	 newboxes += palSplitQuantBox(manager, count);
	 count++;
  };
  memcpy(manager->PQM_table, &(manager->PQM_table[startsize]),
		  sizeof(palQuantListEntry) * newboxes);
  manager->PQM_size = newboxes;
};

/*------------------------------------------------------------------------*/

void
palQuantEntry(RGBValue *boxpal, word boxsize, RGBValue *newcol)
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

/*------------------------------------------------------------------------*/

void
palCalcQuant(palQuantMgr *manager, RGBValue *dest)
{
	word count;

	count = 0;
	while(count != manager->PQM_size)
	{
	palQuantEntry(manager->PQM_table[count].PQLE_palette,
		manager->PQM_table[count].PQLE_count,
		&(dest[count]));
	count++;
	}
}

/*========================================================================*/

/* exported functions */

/* parsing gstring and create needed palette */

MemHandle _pascal _export
PalParseGString(GStateHandle gstring, word palsize)
{
	MemHandle mem, mem2;
	GStateHandle gstate;
	palTable *pal;
	byte *pal2;

	/* allocation palette for the start with 32 entries */
	mem = MemAlloc(32*3+4,HF_SWAPABLE,0);
	if(mem == 0)
	return(0);

	/* init palette memory */
	pal = MemLock(mem);
	if(pal == 0)
	{
	MemFree(mem);
	return(0);
	}
	pal->PT_size = 32;
	pal->PT_used = 16;
	MemUnlock(mem);

	/* create gstate in memory*/
	gstate = GrCreateState(0);

	if(gstate == 0)
		return(0);
	else
	{
		/* parsing gstrings palette */
		My_GrParseGString(gstate, gstring, GSC_OUTPUT, mem);
	}

	GrDestroyState(gstate);

	/* downsizing or copying palette */
	mem2 = MemAlloc(palsize*3, HF_SWAPABLE, 0);
	if(mem2 != 0)
	{
		pal = MemLock(mem);
		if(pal == 0)
		{
			MemFree(mem2);
			MemFree(mem);
			return(0);
		}

		pal2 = MemLock(mem2);
		if(pal2 == 0)
		{
			MemUnlock(mem);
			MemFree(mem2);
			MemFree(mem);
			return(0);
		}

		if(pal->PT_used > palsize)
			PalQuantPalette((RGBValue *) &pal->PT_entry, pal->PT_used,
				(RGBValue *) pal2, palsize);
		else
			memcpy(pal2, &pal->PT_entry, 3*pal->PT_used);

		MemUnlock(mem2);
		MemUnlock(mem);
	}
	MemFree(mem);

	return(mem2);
}

/*------------------------------------------------------------------------*/

/* quantarize palette table */

void _pascal _export
PalQuantPalette(RGBValue *srcpal, word srcsize,
		RGBValue *destpal, word destsize)
{
  palQuantMgr *manager;
  MemHandle mem;

  mem = MemAlloc(sizeof(palQuantMgr), 0, 0);
  manager = (palQuantMgr *)MemLock(mem);
  manager->PQM_size = 1;
  manager->PQM_table[0].PQLE_palette = srcpal;
  manager->PQM_table[0].PQLE_count = srcsize;

  while(manager->PQM_size != destsize)
	 palSplitQuantBoxes(manager, destsize);

  palCalcQuant(manager, destpal);
  MemUnlock(mem);
  MemFree(mem);
};

/***************************************************************************/

EGError _pascal _export
PalGStateCreateBmpPalette(GStateHandle gstate,
	VMFileHandle bmfile, VMBlockHandle bmblock)
{
	EGError stat = EGE_NO_ERROR;
	MemHandle bmmem;
	byte *bmptr;
	word offset;
	word palsize;
	BMType bmtype;
	RGBValue *bmpalptr;
	word gspalsize;

	bmptr = VMLock(bmfile, bmblock, &bmmem);

	if(bmptr)
	{
		bmtype = bmptr[0x1f];

		if((((bmtype & BMT_FORMAT) > BMF_MONO)
			&& ((bmtype & BMT_FORMAT) < BMF_24BIT)) &&
			(bmtype & BMT_PALETTE))
		{
			offset = *((word*)(&bmptr[0x28]));
			palsize = *((word*)(&bmptr[offset + 0x1a]));
			bmpalptr = (RGBValue*) (&bmptr[offset + 0x1a]);

			gspalsize = GrCreatePalette(gstate);

			if(gspalsize >= palsize)
			{
				GrSetPalette(gstate, bmpalptr, 0, palsize);
			}
			else
			{
				if(gspalsize)
					GrDestroyPalette(gstate);

				stat = EGE_PALETTE_INCOMPATIBLE;
			}
		}
		else
			stat = EGE_BITMAP_NO_PALETTE;

		VMUnlock(bmmem);
	}
	else
		stat = EGE_BLOCK_LOCKING_FAILURE;

	return(stat);
}

/***************************************************************************/
