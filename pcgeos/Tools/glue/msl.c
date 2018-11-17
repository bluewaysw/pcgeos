/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  msl.c
 * FILE:	  msl.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 10, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/10/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to read Microsoft Libraries during both pass 1 and
 *	pass 2. This is different from the other object-code readers, as
 *	we don't really do any reading ourselves. Our job is to keep
 *	looking up currently-undefined symbols in the library until we
 *	don't find any more publicly defined in the library. Once that's
 *	complete, we're done.
 *
 *	The only trick is, we have to recall the offsets of the object
 *	modules we cause Pass1MS to read in so Pass2MSL has something
 *	to go on...
 *	
 *	A Microsoft Library is laid out as a succession of object modules
 *	aligned on page boundaries, where a page is defined by the length
 *	of the initial header record, followed by a dictionary in the
 *	form of a hash table that's split into 512-byte blocks with 37
 *	buckets in each block. The number of blocks is always a prime
 *	number, as the method of conflict resolution used is linear open
 *	addressing, where a delta is applied to the initial bucket number
 *	until all the buckets in the block have been checked for the
 *	symbol, then a block delta is applied to the initial block and the
 *	search begins again. A prime number of blocks ensures that all
 *	blocks are searched before failure is declared.
 *	
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: msl.c,v 1.7 93/08/13 19:00:49 jon Exp $";
#endif lint

#include    <config.h>
#include    "glue.h"
#include    "msobj.h"
#include    "obj.h"
#include    "output.h"
#include    "sym.h"
#include    <objfmt.h>
#include    <compat/file.h>

/*
 * Structure describing what's been loaded from a library. The thing
 * is expanded for each object file read in.
 */
typedef struct _MSLib {
    const char 	    *name;  	/* The filename of the library. We assume
				 * that the addresses of file names we get
				 * passed remain constant from pass 1 to
				 * pass 2 */
    Vector  	    offsets;	/* Table of offsets from which modules were
				 * read during pass 1 */
} MSLib;

static MSLib	*libs = NULL;	/* Table of libraries seen during pass 1 */
static int	numLibs = 0;   	/* Number of libraries known */

#define MSL_NUM_BUCKETS	    37	/* Number of buckets in a block */
#define MSL_BLOCK_FULL	    255	/* Value placed in byte after the last bucket
				 * pointer (which holds the index of the
				 * first free word in the block) to indicate
				 * the block is full. If we find an empty
				 * bucket in a block with this value for the
				 * first free word, we immediately apply the
				 * block delta and begin searching in the
				 * next block, on the assumption the symbol
				 * couldn't be stored in the current one due
				 * to lack of space. */
#define MSL_FIRST_FREE	    37	/* Offset of the first-free-word index in the
				 * block */
#define MSL_BLOCK_SIZE	    512	/* Size of a dictionary block. This is different
				 * from the page size of the library, of
				 * course */

#define MSL_USE_HASH	FALSE	/* Define TRUE if we ever find the right
				 * hash function. */


/***********************************************************************
 *				Pass1MSL_Load
 ***********************************************************************
 * SYNOPSIS:	    Load object code from a library.
 * CALLED BY:	    Pass1Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    libs will be expanded to hold a record for this
 *	    	    	library.
 *	    	    modules from the library may be read in.
 *
 * STRATEGY:
 *	Foreach symbol in the undefined-symbol list, see if it's defined
 *	in this library. If so,
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/10/91		Initial Revision
 *
 ***********************************************************************/
void
Pass1MSL_Load(const char *file,
	      genptr  	 handle)
{
    FILE    	*f = (FILE *)handle;
    word    	pageSize;
    dword   	dictStart;
    word    	dictLen;
    SymUndef	*sup, **prev;
    MSLib   	cur;
#if !MSL_USE_HASH
    byte    	*dict;
#endif

    cur.name = file;
    cur.offsets = Vector_Create(sizeof(long), ADJUST_MULTIPLY, 10, 2);

    (void)getc(f);		/* Skip MO_LHEADER */
    pageSize = (byte)getc(f);
    pageSize |= (byte)getc(f) << 8;
    pageSize += 3;

    dictStart = (byte)getc(f);
    dictStart |= (byte)getc(f) << 8;
    dictStart |= (byte)getc(f) << 16;
    dictStart |= (byte)getc(f) << 24;

    dictLen = (byte)getc(f);
    dictLen |= (byte)getc(f) << 8;

#if !MSL_USE_HASH
    dict = (byte *)malloc(dictLen * MSL_BLOCK_SIZE);
    fseek(f, dictStart, L_SET);
    fread(dict, sizeof(byte), dictLen * MSL_BLOCK_SIZE, f);
    /* XXX: check return value */
#endif

    prev = &symUndefHead;
    for (sup = *prev; sup != NULL; sup = *prev) {
#if MSL_USE_HASH
	short		block;
	short		bucket;
	short		dBlock;
	short		dBucket;
	unsigned	length;
	const char 	*start, *end;
	byte    	c;
	byte    	blockBuf[MSL_BLOCK_SIZE];
	Boolean 	done;
	unsigned    	initBlock;
#else
	int 	    	bucket;
	byte	    	*blockBuf;
	int 	    	block;
#endif
	ID	    	id;
	const char    	*name;
	unsigned	nameLen;
	byte    	*bp;
	Boolean	    	found;
	
	id = sup->sym.name;
	name = ST_Lock(symbols, id);
	nameLen = strlen(name);

#if MSL_USE_HASH
	block = bucket = dBlock = dBucket = 0;
	
	length = nameLen;
	start = name;
	end = name + length;
	
	while (length--) {
	    c = *start++ | 32;	/* Convert to lower case */
	    block = (block << 2) ^ c;
	    dBucket = (dBucket >> 2) ^ c;
	    
	    c = *--end | 32;	/* Convert to lower case */
	    bucket = (bucket >> 2) ^ c;
	    dBlock = (dBlock << 2) ^ c;
	}
	
	block %= dictLen;
	
	dBlock %= dictLen;
	if (dBlock == 0) {
	    dBlock = 1;
	}
	
	bucket %= MSL_NUM_BUCKETS;
	dBucket %= MSL_NUM_BUCKETS;
	if (dBucket == 0) {
	    dBucket = 1;
	}
	
	initBlock = block;
	found = done = FALSE;
	do {
	    unsigned    initBucket = bucket;
	    
	    fseek(f, dictStart + block * MSL_BLOCK_SIZE, L_SET);
	    fread(blockBuf, sizeof(blockBuf), sizeof(blockBuf[0]), f);
	    
	    do {
		/*
		 * If the bucket is empty but the block is full, just
		 * set bucket to initBucket so the search will continue with
		 * the next block in the sequence. If the block isn't
		 * full, we stop searching right here.
		 */
		if (blockBuf[bucket] == 0) {
		    if (blockBuf[MSL_FIRST_FREE] == MSL_BLOCK_FULL) {
			bucket = initBucket;
		    } else {
			done = TRUE;
			break;
		    }
		} else {
		    /*
		     * Point to the name of the symbol and see if it matches.
		     */
		    bp = &blockBuf[blockBuf[bucket] << 1];
		    if ((*bp++ == nameLen) &&
			(strncmp(name, bp, nameLen) == 0))
		    {
			/*
			 * Got a match. Determine the proper offset and make
			 * sure we've not already loaded this thing.
			 */
			long	offset;
			long	*offsets;
			int 	numOffs;
			int 	i;
			
			offset = (bp[nameLen] | (bp[nameLen+1]<<8)) * pageSize;
			
			numOffs = Vector_Length(cur.offsets);
			offsets = Vector_Data(cur.offsets);
			
			while (numOffs-- > 0) {
			    if (offset == *offsets++) {
				break;
			    }
			}
			if (numOffs >= 0) {
			    Notify(NOTIFY_WARNING,
				   "%s: symbol %s should have been defined by previous read of module at %ld\n",
				   file, name, offset);
			    break;
			}
			Vector_Add(cur.offsets, VECTOR_END, &offset);
			fseek(f, offset, L_SET);
			Pass1MS_ProcessObject(file, (void *)f);
			/*
			 * Adjust the nextOff field for all concatenatable
			 * segments to match their current sizes. This field is
			 * used by the Pass1 functions to determine the
			 * relocation value for the symbols in the segment in
			 * the object file being loaded.
			 */
			for (i = 0; i < seg_NumSegs; i++) {
			    SegDesc	*sd = seg_Segments[i];
			    
			    if ((sd->combine != SEG_ABSOLUTE) &&
				(sd->combine != SEG_COMMON) &&
				(sd->combine != SEG_GLOBAL) &&
				(sd->combine != SEG_PRIVATE))
			    {
				sd->nextOff = sd->size;
			    }
			}
			done = found = TRUE;
		    }
		    bucket += dBucket;
		    if (bucket < 0) {
			bucket += MSL_NUM_BUCKETS;
		    } else if (bucket >= MSL_NUM_BUCKETS) {
			bucket -= MSL_NUM_BUCKETS;
		    }
		}
	    } while (bucket != initBucket);
	    
	    block += dBlock;
	    if (block < 0) {
		block += dictLen;
	    } else if (block >= dictLen) {
		block -= dictLen;
	    }
	} while (!done && (block != initBlock));
#else
	found = FALSE;

	for (block = 0, blockBuf = dict;
	     block < dictLen && !found;
	     block++, blockBuf += MSL_BLOCK_SIZE)
	{
	    for (bucket = 0; bucket < MSL_NUM_BUCKETS && !found; bucket++) {
		if (blockBuf[bucket] != 0) {
		    /*
		     * Point to the name of the symbol and see if it matches.
		     */
		    bp = &blockBuf[blockBuf[bucket] << 1];
		    if ((*bp++ == nameLen) &&
			(strncmp(name, (char *)bp, nameLen) == 0))
		    {
			/*
			 * Got a match. Determine the proper offset and make
			 * sure we've not already loaded this thing.
			 */
			long	offset;
			long	*offsets;
			int 	numOffs;
			int 	i;
			
			offset = (bp[nameLen] | (bp[nameLen+1]<<8)) * pageSize;
			
			numOffs = Vector_Length(cur.offsets);
			offsets = Vector_Data(cur.offsets);
			
			while (numOffs-- > 0) {
			    if (offset == *offsets++) {
				break;
			    }
			}
			if (numOffs >= 0) {
			    Notify(NOTIFY_WARNING,
				   "%s: symbol %s should have been defined by previous read of module at %ld\n",
				   file, name, offset);
			    break;
			}
			Vector_Add(cur.offsets, VECTOR_END, &offset);
			fseek(f, offset, L_SET);
			Pass1MS_ProcessObject(file, (void *)f);
			/*
			 * Adjust the nextOff field for all concatenatable
			 * segments to match their current sizes. This field is
			 * used by the Pass1 functions to determine the
			 * relocation value for the symbols in the segment in
			 * the object file being loaded.
			 */
			for (i = 0; i < seg_NumSegs; i++) {
			    SegDesc	*sd = seg_Segments[i];
			    
			    if ((sd->combine != SEG_ABSOLUTE) &&
				(sd->combine != SEG_COMMON) &&
				(sd->combine != SEG_GLOBAL) &&
				(sd->combine != SEG_PRIVATE))
			    {
				sd->nextOff = sd->size;
			    }
			}
			found = TRUE;
		    }
		}
	    }
	}
#endif
	/*
	 * If the symbol wasn't in the dictionary, we can safely advance to the
	 * next in the list.
	 */
	if (!found) {
	    prev = &sup->next;
	} else {
	    /*
	     * Else, we might have introduced other undefined symbols by reading
	     * the object module we just read, so start over again.
	     */
	    prev = &symUndefHead;
	}
	ST_Unlock(symbols, id);
    }

    if (Vector_Length(cur.offsets) == 0) {
	Notify(NOTIFY_WARNING, "%s: nothing needed from this library", file);
	Vector_Destroy(cur.offsets);
    } else {
	if (numLibs == 0) {
	    libs = (MSLib *)malloc(sizeof(MSLib));
	} else {
	    libs = (MSLib *)realloc((void *)libs, (numLibs + 1) * sizeof(MSLib));
	}
	libs[numLibs++] = cur;
    }

    (void)fclose(f);

#if !MSL_USE_HASH
    free((void *)dict);
#endif
}


/***********************************************************************
 *				Pass2MSL_Load
 ***********************************************************************
 * SYNOPSIS:	    Re-load the modules previously loaded from this
 *	    	    library for pass 1
 * CALLED BY:	    Pass2Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/11/91		Initial Revision
 *
 ***********************************************************************/
void
Pass2MSL_Load(const char *file,
	      genptr  	 handle)
{
    FILE    	*f = (FILE *)handle;
    MSLib   	*lib;
    int	    	n;

    for (lib = libs, n = numLibs; n > 0; lib++, n--) {
	if (lib->name == file) {
	    int	    numOffsets;
	    long    *offsets;

	    numOffsets = Vector_Length(lib->offsets);
	    offsets = Vector_Data(lib->offsets);

	    while (numOffsets-- > 0) {
		fseek(f, *offsets++, L_SET);
		Pass2MS_ProcessObject(file, (void *)f);
	    }
	}
    }
}
    
