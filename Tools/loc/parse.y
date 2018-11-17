%{
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Tools
MODULE:		Localization (.vm) file generation
FILE:		parse.y

AUTHOR:		Josh Putnam, Nov 19, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JHP	11/19/92   	Initial version.
	jacob   9/9/96		Ported to Win32.

DESCRIPTION:
	Takes .rsc file(s) and turns them into a single .vm file
	for use by ResEdit.

	$Id: parse.y,v 1.17 95/01/03 12:35:30 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#ifdef __BORLANDC__
/* 
 * !@#!@#!@ Borland hoses us by not defining this unless you pass -A,
 * which we don't want to do because it's too restrictive.  But if _STDC_
 * isn't defined, then bison.simple will #define "const" to nothing.
 *
 * XXX: maybe move this to cm-bor.h?
 */
#define __STDC__ 1
#endif

#include <stdio.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <compat/file.h>
#include <errno.h>
#include <ctype.h>
#include <stdarg.h>

#include <hash.h>
#include <malloc.h>		/* utils version of malloc */
#include <vm.h>
#include <lmem.h>
#include <bswap.h>

/******************************************************************************
 *
 *			  OUTPUT FILE FORMAT
 *
 *****************************************************************************/
#define LOC_TOKEN_CHARS	"LOCL"

#define LOC_PROTO_MAJOR	1
#define LOC_PROTO_MINOR	0

/* The extra map item block NameArray header info for localization files. */
typedef struct {
    NameArrayHeader 	LMH_meta;
    ProtocolNumber	LMH_protocol;
    char    	    	LMH_geodeName[GFH_LONGNAME_BUFFER_SIZE];
} LocMapHeader;

/* The data that goes in the NameArrayElement for each resource. */
typedef struct {
    word		LMD_item;   /* item # of NameArray of chunks */
    word		LMD_group;  /* resource group */
    word		LMD_number; /* resource number */
    /* char 	    	LMD_name[0];		; resource name */
} LocMapData;

/* The structure of the element.
 * Not actually defined, owing to the alignment restrictions on the Sparc
 * (pad byte added after WordAndAHalf structure to align following word)
;
LocMapElement		struct
    LME_meta		NameArrayElement
    LME_data		LocMapData
LocMapElement		ends
 */

/* The data that goes in the NameArrayElement for each chunk */
typedef struct {
    word    	LAD_number; 	    /* chunk number */
    word	LAD_instItem; 	    /* instruction text item # */
    word	LAD_chunkType; 	    /* chunk type */
    word	LAD_minSize; 	    /* min string length */
    word	LAD_maxSize; 	    /* max string length */
    word	LAD_flags;  	    /* user supplied flags */
    /* char	  LAD_name[0];		; chunk name*/
} LocArrayData;

/* The structure of the element.
 * Not actually defined, owing to the alignment restrictions on th
 * (pad byte added after WordAndAHalf structure to align following word)
;
LocArrayElement		struct
    LAE_meta		NameArrayElement
    LAE_data		LocArrayData
LocArrayElement		ends
 */

/******************************************************************************
 *
 *		    INTERNAL STRUCTURE DEFINITIONS
 *
 *****************************************************************************/

typedef struct _locinfo {
    struct _locinfo	*next;	    	/* Next chunk in the resource */
    char 		*chunkName; 	/* Name of this chunk */
    int 		num;	    	/* Number of this chunk */
    int 		hint;	    	/* Type of data in the chunk */
    char 		*instructions;	/* Localization instructions */
    int 		min;	    	/* Minimum data length */
    int 		max;	    	/* Maximum data length */
    int 		flags;	    	/* Maximum data length */
    word    	    	item;	    	/* Item containing the instructions */
} LocalizeInfo;

typedef struct 	{
    char		*name;	    /* Name of the resource */
    int 		num;	    /* Resource number */
    VMBlockHandle   	group;	    /* Group holding data */
    word    	    	item;	    /* Map item for resource */
    LocalizeInfo 	*locHead;   /* Info for first chunk */
    LocalizeInfo 	*locTail;   /* Info for last chunk */
    unsigned int 	count;	    /* Number of chunks in the resource */
} ResourceSym;

/******************************************************************************
 *
 *			   GLOBAL VARIABLES
 *
 *****************************************************************************/

static int 	    	yylineno;
static int	    	errors = 0;
static FILE 	    	*yyin;
static const char   	*curFile;
static ProtocolNumber	proto;
static Hash_Table   	locHash;		/* all resources    */
static ResourceSym  	*currentResource;
static char 	    	*longName = "UNKNOWN";
int	    	    	geosRelease = 2; /* Create 2.0 VM file */
int			dbcsRelease = 0; /* non-zero: create DBCS file */

#define DUMP_LOC_INFO(loc) do{                                   \
		if (loc->instructions[1] == '"') {          \
		    printf("\tchar 0\n");                        \
		} else {                                         \
		    printf("\tchar %s, 0\n", loc->instructions); \
		}                                                      \
        } while (0)

#define DUMP_LOC_ITEM(res, loc)                 \
    do{                        \
	DBPRINTF((";localization info START\n"));               \
	printf("\tDefDBItem %s %s\n", UNIQUE(res), UNIQUE(loc));  \
        DUMP_LOC_INFO(loc);                                     \
	printf("\tEndDBItem %s %s\n", UNIQUE(res), UNIQUE(loc));  \
	DBPRINTF((";localization info END\n"));		        \
    }                                                           \
    while (0)





/* macro to iterate through the hash table and run 'code' with res=resource */
#define FOR_ALL_RESOURCES_WITH_CHUNKS(__res, code)        \
do{ 	        					 \
    Hash_Entry	*__ent;					 \
    ResourceSym *__res;					 \
    Hash_Search 	hashSearch;                      \
	        					 \
    for (__ent = Hash_EnumFirst(&locHash, &hashSearch);	 \
	 __ent;						 \
	 __ent = Hash_EnumNext(&hashSearch)) {		 \
	__res = (ResourceSym *)Hash_GetValue(__ent);	 \
	if (!(__res)->locHead){                          \
           continue;                                     \
	}                                                \
	code    					 \
    }	        					 \
} while (0)

#define FOR_ALL_LOCINFOS_IN_RESOURCE(__res, __locinfo, __code)     \
    do{	        					         \
	LocalizeInfo	*__locinfo;			         \
	for (__locinfo = (__res)->locHead;		         \
	    __locinfo;					         \
	    __locinfo = (__locinfo)->next){		         \
                __code                                           \
	}                                                        \
    } while (0)


/* Create a resource */
/* This becomes the implicit resource for chunks.	*/
/* If the resource exists already, the resource becomes */
/* the current resource. 				*/

static void  EnterResource(char *name);

static void DumpResource (ResourceSym *res, VMHandle output);

/* create a new chunk in the current resource     		*/
/* the data given is the localization information. 		*/
/* another chunk may be defined with the same name later, 	*/
/* but they'll be distinct.					*/
static void EnterChunk(char *name,
		       int num,
		       int hint,
		       char *instructions,
		       int min,
		       int max,
		       int flags);

static void DumpMapBlock(VMHandle output);


static void yyerror(const char *fmt, ...);

%}

%union{
    char 	tok;
    char 	*string;
}

%token 		RESOURCE GEODE_LONG_NAME PROTOCOL
%token <string>	THING

%%

file		:	/* NOTHING */
		| file line '\n'
		;

line		: RESOURCE THING	   
		{
		    EnterResource($2);
		}
		| RESOURCE THING THING
		{
		    EnterResource($2);
		    currentResource->num = atoi($3);
		    free($3);
		}
		| GEODE_LONG_NAME THING
		{
		    longName = $2;
		}
		| THING THING THING THING THING THING THING
		{
		    EnterChunk($1, atoi($2), atoi($3), $4, 
			       atoi($5), atoi($6), atoi($7));
		    free($2);
		    free($3);
		    free($5);
		    free($6);
		    free($7);
		}
		| PROTOCOL THING THING
		{
		    proto.major = atoi($2);
		    proto.minor = atoi($3);
		    free($2);
		    free($3);
		}
		| /* empty line */
		;


%%


/***********************************************************************
 *				EnterResource
 ***********************************************************************
 * SYNOPSIS:	Make the passed resource the current one, creating a
 *	    	symbol for the beast if we've never seen it before.
 * CALLED BY:	(INTERNAL) yyparse
 * RETURN:	nothing
 * SIDE EFFECTS:    currentResource is set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void
EnterResource(char *name)
{
    Hash_Entry	*ent;	/* entry for this resource in the hash table */
    Boolean   	new; 	/* needed for Hash_CreateEntry */

    ent = Hash_CreateEntry(&locHash, name, &new);

    if (new) {
	/* if the thing is new, init the values (zero for all others) */
	ResourceSym	*res = (ResourceSym *)calloc(1, sizeof(ResourceSym));

	Hash_SetValue(ent, res);
	res->name = name;
    }
    currentResource = (ResourceSym *)Hash_GetValue(ent);
}


/***********************************************************************
 *				EnterChunk
 ***********************************************************************
 * SYNOPSIS:	    Define a chunk for the current resource.
 * CALLED BY:	    (INTERNAL) yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    currentResource->count is increased by 1.
 *	    	    currentResource->locIns is definitely set
 *	    	    currentResource->loc
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void
EnterChunk(char *name,
	   int num,
	   int hint,
	   char *instructions,
	   int min,
	   int max,
	   int flags)
{
    LocalizeInfo *loc = (LocalizeInfo *)calloc(1, sizeof(LocalizeInfo));

    loc->chunkName	= name;
    loc->num 		= num;
    loc->hint 		= hint;
    loc->instructions 	= instructions;
    loc->min 		= min;
    loc->max 		= max;
    loc->flags 		= flags;
    loc->next 	    	= NULL;

    if (currentResource->locTail == NULL) {
	currentResource->locTail = currentResource->locHead = loc;
    } else {
	currentResource->locTail->next = loc;
	currentResource->locTail = loc;
    }
    
    currentResource->count++;
}


/***********************************************************************
 *				DBAllocGroup
 ***********************************************************************
 * SYNOPSIS:	    Create a group in the passed file.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    VMBlockHandle for new group
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static VMBlockHandle
DBAllocGroup(VMHandle	file)
{
    VMBlockHandle   result;
    DBGroupHeader   *hdr;

    result = VMAlloc(file, sizeof(DBGroupHeader), SVMID_DB_GROUP);

    hdr = (DBGroupHeader *)VMLock(file, result, (MemHandle *)NULL);
    hdr->DBGH_vmemHandle = swaps(result);
    hdr->DBGH_handle = 0;
    hdr->DBGH_flags = 0;
    hdr->DBGH_itemBlocks = 0;
    hdr->DBGH_itemFreeList = 0;
    hdr->DBGH_blockFreeList = 0;
    hdr->DBGH_blockSize = swaps(sizeof(DBGroupHeader));

    VMUnlockDirty(file, result);
    return(result);
}


/***********************************************************************
 *				DBEnlargeGroup
 ***********************************************************************
 * SYNOPSIS:	    Enlarge a group block to contain the indicated number
 *	    	    of additional bytes, returning a pointer to those bytes.
 * CALLED BY:	    (INTERNAL) DBAlloc
 * RETURN:	    pointer to the newly-allocated bytes
 * SIDE EFFECTS:    DBGH_blockSize is increased. Group block may move
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void *
DBEnlargeGroup (MemHandle   	mem,
		unsigned    	newBytes,
		DBGroupHeader	**hdrPtr)
{
    DBGroupHeader   *hdr = *hdrPtr;
    word	    size;

    size = swaps(hdr->DBGH_blockSize) + newBytes;
	
    MemReAlloc(mem, size, 0);
    MemInfo(mem, (genptr *)&hdr, (word *)NULL);
    hdr->DBGH_blockSize = swaps(size);

    *hdrPtr = hdr;
    
    return ((void *)((genptr)hdr + size - newBytes));
}


/***********************************************************************
 *				DBAlloc
 ***********************************************************************
 * SYNOPSIS:	    Allocate an item within a particular group.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    item offset
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static word
DBAlloc(VMHandle    	file,
	VMBlockHandle	group,
	unsigned    	itemSize)	    /* Size of item */
{
    DBGroupHeader   *hdr;   	    	/* Data for the group */
    DBItemBlockInfo *ibi;   	    	/* Data for the item block being used */
    DBItemInfo	    *ii;    	    	/* Data for the item being created */
    MemHandle	    mem;    	    	/* Handle for enlarging *hdr */
    VMBlockHandle   itemBlock = 0;  	/* VM handle of item block being used */
    DBItemBlockHeader   *ibh;	    	/* Header of locked item block */
    MemHandle	    imem;   	    	/* Handle for enlarging *ibh */
    word    	    *chunk; 	    	/* Place to store data offset in
					 * item block */
    word    	    *dataPtr;	    	/* Place to store size word in item
					 * block (pointed to by *chunk) */
    word    	    result; 	    	/* Value to return, of course */
    unsigned	    csize;

    /*
     * Lock down the group and see if the first item block is suitable.
     */
    hdr = (DBGroupHeader *)VMLock(file, group, &mem);

    if (hdr->DBGH_itemBlocks != 0) {
	word	ibSize;
	
	ibi = (DBItemBlockInfo *)((genptr)hdr + swaps(hdr->DBGH_itemBlocks));
	VMInfo(file, swaps(ibi->DBIBI_block), &ibSize, (MemHandle *)NULL,
	       (VMID *)NULL);

	if (ibSize + itemSize > 8192) {
	    /*
	     * Allocate a new one instead of using this one, as this one would
	     * put the existing head block over the edge of respectability.
	     */
	    itemBlock = 0;
	} else {
	    /*
	     * It'll fit here, so use it
	     */
	    itemBlock = swaps(ibi->DBIBI_block);
	}
    }

    if (itemBlock == 0) {
	/*
	 * Allocate a new item block.
	 */
	word	size = (sizeof(DBItemBlockHeader) + 3) & ~3;

	itemBlock = VMAlloc(file, size, SVMID_DB_ITEM);

	/*
	 * Be sure to mark it as lmem, please, lest LMBH_handle not get set
	 * right when it's locked down...
	 */
	VMSetLMemFlag(file, itemBlock);
	
	/*
	 * First make room for and initialize the DBItemBlockInfo structure in
	 * the group.
	 */
	ibi = (DBItemBlockInfo *)DBEnlargeGroup(mem, sizeof(DBItemBlockInfo),
						&hdr);
	ibi->DBIBI_next = hdr->DBGH_itemBlocks;
	ibi->DBIBI_refCount = 0;
	ibi->DBIBI_block = swaps(itemBlock);

	/*
	 * Now initialize the freshly-minted item block.
	 */
	ibh = (DBItemBlockHeader *)VMLock(file, itemBlock, &imem);

	ibh->DBIBH_standard.LMBH_handle = swaps(itemBlock);
	ibh->DBIBH_standard.LMBH_offset = swaps(size);
	ibh->DBIBH_standard.LMBH_flags = swaps(LMF_IS_VM);
	ibh->DBIBH_standard.LMBH_lmemType = swaps(LMEM_TYPE_DB_ITEMS);
	ibh->DBIBH_standard.LMBH_blockSize = ibh->DBIBH_standard.LMBH_offset;
	ibh->DBIBH_standard.LMBH_nHandles = 0;
	ibh->DBIBH_standard.LMBH_freeList = 0;
	ibh->DBIBH_standard.LMBH_totalFree = 0;
	ibh->DBIBH_vmHandle = swaps(itemBlock);

	hdr->DBGH_itemBlocks =
	    ibh->DBIBH_infoStruct =
		swaps((genptr)ibi - (genptr)hdr);
    } else {
	/*
	 * Lock down the item block to use.
	 */
	ibh = (DBItemBlockHeader *)VMLock(file, itemBlock, &imem);
    }

    /*
     * Up the reference count for the chosen item block, while ibi is still
     * valid.
     */
    ibi->DBIBI_refCount = swaps(swaps(ibi->DBIBI_refCount) + 1);

    /*
     * Allocate the DBItemInfo structure. INVALIDATES "ibi"
     */
    ii = (DBItemInfo *)DBEnlargeGroup(mem, sizeof(DBItemInfo), &hdr);
    ii->DBII_block = ibh->DBIBH_infoStruct;

    /*
     * Compute the actual size of the chunk, including the size word and
     * rounding that up to a dword boundary.
     */
    csize = (itemSize + 2 + 3) & ~3;

    /*
     * Chunk handles are always allocated in pairs, and they aren't allocated
     * until one of them is about to be used, so point "chunk" to the last
     * handle in the existing table so we can see if it's free.
     */
    chunk = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_offset) +
		     2 * (swaps(ibh->DBIBH_standard.LMBH_nHandles) - 1));

    if ((ibh->DBIBH_standard.LMBH_nHandles == 0) || (*chunk != 0)) {
	/*
	 * Need to add a chunk to the beast (block either has no handles yet,
	 * or final one is non-zero => in-use).
	 */
	word	*tchunk;

	/*
	 * Make room for the chunk and the additional handle-pair at the
	 * same time.
	 */
	MemReAlloc(imem, swaps(ibh->DBIBH_standard.LMBH_blockSize) + 4 + csize,
		   0);
	MemInfo(imem, (genptr *)&ibh, (word *)NULL);

	/*
	 * Copy all the chunk data up 4 bytes to make room for the two new
	 * chunk handles.
	 */
	chunk = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_offset) +
			 2 * swaps(ibh->DBIBH_standard.LMBH_nHandles));

	bcopy(chunk, chunk+2,
	      (swaps(ibh->DBIBH_standard.LMBH_blockSize) -
	       ((genptr)chunk-(genptr)ibh)));

	/*
	 * Adjust all the existing chunk handles to account for the extra
	 * four bytes between themselves and their data.
	 */
	for (tchunk = (word *)((genptr)ibh +
			       swaps(ibh->DBIBH_standard.LMBH_offset));
	     tchunk < chunk;
	     tchunk++)
	{
	    *tchunk = swaps(swaps(*tchunk) + 4);
	}

	/*
	 * Mark second handle of the allocated pair as free (first handle will
	 * be overwritten in a moment, so no point in changing it now.
	 */
	chunk[1] = 0;

	/*
	 * Adjust header data for the two new handles just allocated. Leave
	 * the additional size for the chunk out of LMBH_blockSize until
	 * we hit the common code, below.
	 */
	ibh->DBIBH_standard.LMBH_blockSize =
	    swaps(swaps(ibh->DBIBH_standard.LMBH_blockSize) + 4);
	ibh->DBIBH_standard.LMBH_nHandles =
	    swaps(swaps(ibh->DBIBH_standard.LMBH_nHandles) + 2);
    } else {
	/*
	 * The handle is available, so just make room for the data. No
	 * adjustment of existing handles required.
	 */
	MemReAlloc(imem, swaps(ibh->DBIBH_standard.LMBH_blockSize) + csize, 0);
	MemInfo(imem, (genptr *)&ibh, (word *)NULL);
	
	/*
	 * The block may move, however, so we have to recompute "chunk"
	 */
	chunk = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_offset) +
			 2 * (swaps(ibh->DBIBH_standard.LMBH_nHandles) - 1));
	
    }
	
    /*
     * Point the chosen chunk handle at the data allocated at the end of the
     * block.
     */
    *chunk = swaps(swaps(ibh->DBIBH_standard.LMBH_blockSize) + 2);

    /*
     * Set the size word of the chunk to be that requested, plus the size of
     * the size word itself.
     */
    dataPtr = (word *)((genptr)ibh + swaps(ibh->DBIBH_standard.LMBH_blockSize));
    *dataPtr = swaps(itemSize + 2);

    /*
     * Increase the block size by the rounded size of the chunk.
     */
    ibh->DBIBH_standard.LMBH_blockSize = 
	swaps(swaps(ibh->DBIBH_standard.LMBH_blockSize) + csize);

    /*
     * Record the chunk handle in the DBItemInfo structure.
     */
    ii->DBII_chunk = swaps((genptr)chunk - (genptr)ibh);

    VMUnlockDirty(file, itemBlock);

    /*
     * Compute the item's offset.
     */
    result = (genptr)ii - (genptr)hdr;

    VMUnlockDirty(file, group);

    return(result);
}
	

/***********************************************************************
 *				DBLock
 ***********************************************************************
 * SYNOPSIS:	    Lock down an item in the file.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    void * to the data in question
 * SIDE EFFECTS:    the item block is left locked.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/93		Initial Revision
 *
 ***********************************************************************/
static void *
DBLock(VMHandle	    	file,
       VMBlockHandle	group,
       word 	    	item)
{
    genptr  	    hdr;
    DBItemBlockInfo *ibi;
    DBItemInfo	    *ii;
    void    	    *result;
    word    	    *chunk;

    /*
     * Lock down the group and point to the DBItemBlockInfo and DBItemInfo
     * structures.
     */
    hdr = (genptr)VMLock(file, group, (MemHandle *)NULL);
    ii = (DBItemInfo *)(hdr + item);
    ibi = (DBItemBlockInfo *)(hdr + swaps(ii->DBII_block));

    /*
     * Lock down the item block and find the chunk handle.
     */
    result = (void *)VMLock(file, swaps(ibi->DBIBI_block), (MemHandle *)NULL);
    chunk = (word *)((genptr)result + swaps(ii->DBII_chunk));

    /*
     * Add the offset stored in the chunk handle to the base of the item block
     * to get the final result.
     */
    result = (genptr)result + swaps(*chunk);

    VMUnlock(file, group);
    return(result);
}



/***********************************************************************
 *				DumpMapBlock
 ***********************************************************************
 * SYNOPSIS:	    Create the map item for the file, pointing to all
 *		    the resources previously dumped.
 * CALLED BY:	    (INTERNAL) DumpLocalizations
 * RETURN:  	    nothing
 * SIDE EFFECTS:    the DB map block is set and the map group allocated.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/17/92   	Initial Revision
 *	dubois	3/ 3/94  	DBCS modifications
 *
 ***********************************************************************/
static void
DumpMapBlock (VMHandle	output)
{
    int     	    resourceCount;
    VMBlockHandle   group;
    word    	    item;
    VMBlockHandle   mapBlock;
    DBMapBlock	    *map;
    ResourceSym	    *res;
    Hash_Search	    search;
    Hash_Entry	    *ent;
    unsigned   	    mapItemLen;
    byte    	    *bp;
    word    	    offset;
    unsigned 	    headerLen;
    int		    maxLen;

    /*
     * Count the number of resources that actually have chunks.
     */
    mapItemLen = headerLen = sizeof(NameArrayHeader) + sizeof(ProtocolNumber) +
	((dbcsRelease != 0) ?
	 (strlen(longName) + 1) << 1 :
	 strlen(longName) + 1);

    for (ent = Hash_EnumFirst(&locHash, &search), resourceCount = 0;
	 ent != NULL;
	 ent = Hash_EnumNext(&search))
    {
	res = (ResourceSym *)Hash_GetValue(ent);
	if (res->locHead != NULL) {
	    resourceCount += 1;
	    /* 3 == sizeof(NameArrayElement) w/o padding (it's 4 on a Sparc) */
	    mapItemLen += 3 + sizeof(LocMapData) + (dbcsRelease != 0 ?
						    (strlen(res->name) << 1) :
						    strlen(res->name));
	}
    }

    /*
     * Add in the offsets to the elements
     */
    mapItemLen += 2 * resourceCount;

    /*
     * Allocate the map group and map item.
     */
    group = DBAllocGroup(output);
    item = DBAlloc(output, group, mapItemLen);

    bp = DBLock(output, group, item);
    
    /*
     * Initialize the ChunkArrayHeader
     */
    *bp++ = resourceCount;    	    /* CAH_count.low */
    *bp++ = resourceCount >> 8;	    /* CAH_count.high */
    *bp++ = 0; *bp++ = 0;    	    /* CAH_elementSize (variable) */
    *bp++ = 0; *bp++ = 0;    	    /* CAH_curOffset (used at runtime only) */
    *bp++ = headerLen;	    	    /* CAH_offset.low */
    *bp++ = headerLen >> 8;	    /* CAH_offset.high */

    /*
     * Now the ElementArrayHeader
     */
    *bp++ = 0xff; *bp++ = 0xff;	    /* EAH_freePtr (none) */

    /*
     * Now the NameArrayHeader
     */
    *bp++ = 3*2;    	    	    /* NAH_dataSize.low */
    *bp++ = (3*2) >> 8;	    	    /* NAH_dataSize.high */

    /*
     * Now the LocMapHeader
     */
    *bp++ = proto.major;    	    /* LMH_protocol.PN_major.low */
    *bp++ = proto.major >> 8;       /* LMH_protocol.PN_major.high */
    *bp++ = proto.minor;    	    /* LMH_protocol.PN_minor.low */
    *bp++ = proto.minor >> 8;       /* LMH_protocol.PN_minor.high */

    if (dbcsRelease != 0) {	    /* LMH_geodeName */
	maxLen = (strlen(longName) + 1) << 1;
	maxLen = VMCopyToDBCSString((char *)bp, longName, maxLen);
	bp += maxLen;
    } else {
	strcpy((char *) bp, longName);
	bp += strlen(longName) + 1;
    }
    
    /*
     * Next come the offsets to the elements.
     */
    offset = headerLen + 2 * resourceCount;

    for (ent = Hash_EnumFirst(&locHash, &search);
	 ent != NULL;
	 ent = Hash_EnumNext(&search))
    {
	res = (ResourceSym *)Hash_GetValue(ent);

	if (res->locHead != NULL) {
	    *bp++ = offset;
	    *bp++ = offset >> 8;

	    offset += 3 + sizeof(LocMapData) + (dbcsRelease != 0 ?
						(strlen(res->name) << 1) :
						strlen(res->name));
	}
    }
    
    /*
     * Now the elements themselves.
     */
    for (ent = Hash_EnumFirst(&locHash, &search);
	 ent != NULL;
	 ent = Hash_EnumNext(&search))
    {
	
	res = (ResourceSym *)Hash_GetValue(ent);
	if (res->locHead != NULL) {
	    int nameLen = strlen(res->name);

	    *bp++ = 1; *bp++ = 0; *bp++ = 0;	/* NAE_meta.RAH_refCount (1) */
	    *bp++ = res->item;  	    	/* LMD_item.low */
	    *bp++ = res->item >> 8;	    	/* LMD_item.high */
	    *bp++ = res->group; 	    	/* LMD_group.low */
	    *bp++ = res->group >> 8;    	/* LMD_group.high */
	    *bp++ = res->num;   	    	/* LMD_number.low */
	    *bp++ = res->num >> 8;	    	/* LMD_number.high */

	    if (dbcsRelease != 0) {
		maxLen = nameLen << 1;
		VMCopyToDBCSString((char *)bp, res->name, maxLen);
		bp += maxLen;
	    } else {
		bcopy(res->name, bp, nameLen); 	/* LMD_name (w/o null term) */
		bp += nameLen;
	    }
	}
    }

    /*
     * Allocate the map block for the DB system. (Must round the size up to
     * a paragraph to avoid EC code in the kernel).
     */
    mapBlock = VMAlloc(output, (sizeof(DBMapBlock) + 15) & ~15, SVMID_DB_MAP);
    map = (DBMapBlock *)VMLock(output, mapBlock, (MemHandle *)NULL);
    VMSetDBMap(output, mapBlock);

    /*
     * Initialize it, now we've got all the info.
     */
    map->DBMB_vmemHandle = swaps(mapBlock);
    map->DBMB_handle = 0;
    map->DBMB_mapGroup = swaps(group);
    map->DBMB_mapItem = swaps(item);
    map->DBMB_ungrouped = 0;

    VMUnlockDirty(output, mapBlock);
}	/* End of DumpMapBlock.	*/


/***********************************************************************
 *				DumpResource
 ***********************************************************************
 * SYNOPSIS:	    Create a group to hold the data for a resource and
 *		    define the name array that is its map item.
 * CALLED BY:	    (INTERNAL) DumpLocalizations
 * RETURN:  	    nothing
 * SIDE EFFECTS:    res->group, res->item set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/17/92   	Initial Revision
 *	dubois	3/ 3/94  	DBCS modifications
 *
 ***********************************************************************/
static void
DumpResource (ResourceSym *res,
	      VMHandle	output)
{
    byte    	    *bp;
    unsigned   	    len;
    LocalizeInfo    *loc;
    word    	    offset;
    int		    maxLen;
    
    res->group = DBAllocGroup(output);

    /*
     * Spew the instructions themselves into the group.
     */
    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	char	*inst;
	
	if (strlen(loc->instructions) == 0) {
	    loc->item = 0;
	} else if (dbcsRelease != 0) {
	    maxLen = (strlen(loc->instructions) + 1) << 1;
	    loc->item = DBAlloc(output, res->group, maxLen);
	    inst = DBLock(output, res->group, loc->item);
	    VMCopyToDBCSString(inst, loc->instructions, maxLen);
	} else {
	    loc->item = DBAlloc(output, res->group,
				strlen(loc->instructions) + 1);
	    inst = DBLock(output, res->group, loc->item);
	    strcpy(inst, loc->instructions);
	}
    }

    /*
     * Now figure how big the map item needs to be.
     */
    len = sizeof(NameArrayHeader) + 2 * res->count;

    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	/* 3 == sizeof(NameArrayElement) w/o padding (it's 4 on a Sparc) */
	len += 3 + sizeof(LocArrayData);
	len += ((dbcsRelease != 0) ?
	    	(strlen(loc->chunkName) << 1) :
		strlen(loc->chunkName));
    }
    
    res->item = DBAlloc(output, res->group, len);
    bp = DBLock(output, res->group, res->item);

    /*
     * Initialize the ChunkArrayHeader
     */
    *bp++ = res->count;	    	    /* CAH_count.low */
    *bp++ = res->count >> 8;	    /* CAH_count.high */
    *bp++ = 0; *bp++ = 0;	    /* CAH_elementSize (variable) */
    *bp++ = 0; *bp++ = 0;    	    /* CAH_curOffset (used at runtime only) */
    *bp++ = sizeof(NameArrayHeader);	/* CAH_offset.low */
    *bp++ = sizeof(NameArrayHeader)>>8;	/* CAH_offset.high */

    /*
     * Now the ElementArrayHeader
     */
    *bp++ = 0xff; *bp++ = 0xff;	    /* EAH_freePtr (none) */

    /*
     * Now the NameArrayHeader
     */
    *bp++ = 6*2;    	    	    /* NAH_dataSize.low */
    *bp++ = (6*2) >> 8;	    	    /* NAH_dataSize.high */

    /*
     * Next come the offsets to the elements.
     */
    offset = sizeof(NameArrayHeader) + 2 * res->count;
    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	*bp++ = offset;
	*bp++ = offset >> 8;

	offset += 3 + sizeof(LocArrayData);
	offset += (dbcsRelease != 0 ?
		   (strlen(loc->chunkName) << 1) :
		   strlen(loc->chunkName));
    }
    
    /*
     * Now the elements themselves.
     */
    for (loc = res->locHead; loc != NULL; loc = loc->next) {
	int nameLen = strlen(loc->chunkName);

	*bp++ = 1; *bp++ = 0; *bp++ = 0;/* NAE_meta.RAH_refCount (1) */
	*bp++ = loc->num;   	    	/* LAD_number.low */
	*bp++ = loc->num >> 8;	    	/* LAD_number.high */
	*bp++ = loc->item;  	    	/* LAD_instItem.low */
	*bp++ = loc->item >> 8;	    	/* LAD_instItem.high */
	*bp++ = loc->hint;  	    	/* LAD_chunkType.low */
	*bp++ = loc->hint >> 8;	    	/* LAD_chunkType.high */
	*bp++ = loc->min;   	    	/* LAD_minSize.low */
	*bp++ = loc->min >> 8;	    	/* LAD_minSize.high */
	*bp++ = loc->max;   	    	/* LAD_maxSize.low */
	*bp++ = loc->max >> 8;	    	/* LAD_maxSize.high */
	*bp++ = loc->flags;   	    	/* LAD_flags.low */
	*bp++ = loc->flags >> 8;    	/* LAD_flags.high */

	if (dbcsRelease != 0) {
	    maxLen = nameLen << 1;
	    VMCopyToDBCSString((char *)bp, loc->chunkName, maxLen);
	    bp += maxLen;
	} else {
	    bcopy(loc->chunkName, bp, nameLen); /* LAD_name (w/o null terminator) */
	    bp += nameLen;
	}
    }
}



/***********************************************************************
 *				DumpLocalizations
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/16/92   	Initial Revision
 *	dubois	3/ 3/94  	DBCS modifications
 *
 ***********************************************************************/
static void
DumpLocalizations(const char *outputName)
{
    VMHandle	    output;
    short   	    status;
    Hash_Entry	    *ent;
    Hash_Search	    hashSearch;
    GeosFileHeader2 gfh;

    (void)unlink(outputName);

    output = VMOpen(VMO_CREATE_ONLY|FILE_DENY_RW|FILE_ACCESS_RW,
		    70,
		    outputName,
		    &status);

    if (output == NULL) {
	perror(outputName);
	exit(1);
    }
    

    VMGetHeader(output, (char *)&gfh);
    gfh.protocol.major = swaps(LOC_PROTO_MAJOR);
    gfh.protocol.minor = swaps(LOC_PROTO_MINOR);
    bcopy(LOC_TOKEN_CHARS, gfh.token.chars, sizeof(gfh.token.chars));
    bcopy("RSED", gfh.creator.chars, sizeof(gfh.creator.chars));
    if (dbcsRelease != 0) {
	VMCopyToDBCSString(gfh.notice, longName, GFH_RESERVED_SIZE);
    } else {
	strncpy(gfh.notice, longName, GFH_RESERVED_SIZE);
    }
    VMSetHeader(output, (char *)&gfh);

    /* now declare all groups and their chunks */
    for (ent = Hash_EnumFirst(&locHash, &hashSearch);
	 ent != NULL;
	 ent = Hash_EnumNext(&hashSearch))
    {
	ResourceSym	    *res;

	res = (ResourceSym *)Hash_GetValue(ent);

	if (res->locHead != NULL) {
	    DumpResource(res, output);
	}
    }

    DumpMapBlock(output);
    VMClose(output);
}

#if defined(_MSDOS) || defined(_WIN32)

/***********************************************************************
 *				GetNextRSCFile
 ***********************************************************************
 * SYNOPSIS:	    Enum to next .rsc file name in CWD
 * CALLED BY:	    main, GetFirstRSCFile
 * RETURN:	    char *, or NULL if none left or error
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/19/96   	Initial Revision
 *
 ***********************************************************************/
#if defined(_MSDOS)
static struct find_t	findStruct;
#elif defined(_WIN32)
#include <compat/windows.h>
static WIN32_FIND_DATA	findStruct;
static HANDLE		findHandle;
/* 
 * Pass in file attributes, get back TRUE if this is
 * not a directory or weird psuedo-file.
 */
#define IS_OKAY_FILE(attrs) (!((attrs) & (FILE_ATTRIBUTE_DIRECTORY \
					  | FILE_ATTRIBUTE_SYSTEM)))
#endif /* _WIN32 */

static char *
GetNextRSCFile(void)
{
#if defined(_MSDOS)
    if (_dos_findnext(&findStruct) == 0) {
	return findStruct.name;
    }
    return NULL;
#elif defined(_WIN32) 
    char *fileName = NULL;

    while (1) {
	if (!FindNextFile(findHandle, &findStruct)) {
	    break;
	}
	if (IS_OKAY_FILE(findStruct.dwFileAttributes)) {
	    fileName = findStruct.cFileName;
	    break;
	}
    }

    return fileName;
#endif
}	/* End of GetNextRSCFile.	*/


/***********************************************************************
 *				GetFirstRSCFile
 ***********************************************************************
 * SYNOPSIS:	    Start the ball rollin' on getting names of
 *		    .rsc files in CWD
 * CALLED BY:	    main
 * RETURN:	    char * of file name, NULL if error or none found
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/19/96   	Initial Revision
 *
 ***********************************************************************/
static char *
GetFirstRSCFile(char *path)
{
#if defined(_MSDOS)
    if (_dos_findfirst(path, _A_NORMAL, &findStruct) == 0) {
	return findStruct.name;
    }
#elif defined(_WIN32)
    findHandle = FindFirstFile(path, &findStruct);
    if (findHandle != INVALID_HANDLE_VALUE) {
	if (!IS_OKAY_FILE(findStruct.dwFileAttributes)) {
	    /*
	     * Not a plain file, skip it.
	     */  
	    return GetNextRSCFile();
	}

	return findStruct.cFileName;
    }
#endif

    return NULL;
}	/* End of GetFirstRSCFile.	*/
#endif /* _MSDOS || _WIN32 */


/***********************************************************************
 *				ConstructPath
 ***********************************************************************
 *
 * SYNOPSIS:	    Construct full path to enumerated file name
 * CALLED BY:	    main
 * RETURN:	    char * (must be free()'d)
 * SIDE EFFECTS:    
 *	Allocates space for string.
 *
 * STRATEGY:	    
 *	Lame-o FindFirstFile, when given something like FOO/*.rsc
 *      only returns names like Boot.rsc, not FOO/Boot.rsc.  
 *	So we have to manually add that back in.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jacob	10/23/96   	Initial Revision
 *
 ***********************************************************************/
char *
ConstructPath (const char *wildcard, const char *path)
{
    char *lastSlash = strrchr(wildcard, '/');
    char *lastBackSlash = strrchr(wildcard, '\\');
    char *slash;

    if (lastSlash == NULL && lastBackSlash == NULL) {
	/* 
	 * Wasn't in a subdir, just return a copy of the path.
	 */
	return strdup(path);
    } else {
	char *fullPath = (char *) malloc(strlen(path) + strlen(wildcard) + 1);

	/*
	 * Find the last slash or backslash in the pathname.
	 */
	if (lastSlash == NULL) {
	    slash = lastBackSlash;
	} else if (lastBackSlash == NULL) {
	    slash = lastSlash;
	} else {
	    slash = (lastBackSlash > lastSlash) ? lastBackSlash : lastSlash;
	}

	/*
	 * Now chop off the wildcard at the last slash.
	 */
	strcpy(fullPath, wildcard);
	*(fullPath + (slash - wildcard) + 1) = '\0';
	return strcat(fullPath, path);
    }
}	/* End of ConstructPath.	*/


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    You know
 * RETURN:	    int
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/19/96   	Initial Revision
 *
 ***********************************************************************/
void
main(int argc, char **argv)
{
    char	*outputName = "loc.vm";
    char	*rscFileNames = "*.rsc";
    int	    	i;

#if defined(unix)
    if (argc == 1) {
	exit(0);
    }
#endif
    
    Hash_InitTable(&locHash, -1, HASH_STRING_KEYS, -1);

    for (i = 1; i < argc; i++) {
	if (argv[i][0] == '-') {
	    switch (argv[i][1]) {
	    case 'o':
		if (strlen(argv[i]) == 2) {
		    if (i+1 == argc) {
		        fprintf(stderr,
				"%s: -o argument requires <output-file> "
				"argument\n",
				argv[0]);
		        exit(1);
		    } else {
		        outputName = argv[i+1];
		        i += 1;
		    }
	        } else {
		    outputName = &argv[i][2];
	        }
		break;
	    case '2':
		dbcsRelease = 1;
		break;
	    default:
		fprintf(stderr, "%s: unknown option %s\n", argv[0], argv[i]);
		exit(1);
	    }
	} else {

#if defined(unix)
	    yyin = fopen(argv[i], "rt");
	    if (yyin == NULL) {
		perror(argv[i]);
	        errors += 1;
	        break;
	    }
	    curFile = argv[i];
	    yylineno = 1;
	    if (yyparse()) {
	        (void)fclose(yyin);
	        break;
	    }
	    (void)fclose(yyin);
#else
	    /*
	     * Under NT/DOS, just grab the pattern.
	     */
	    rscFileNames = argv[i];
#endif
	}
    }

#if defined(_MSDOS) || defined(_WIN32)
    {
	curFile = GetFirstRSCFile(rscFileNames);
	if (curFile == NULL) {
	    fprintf(stderr, "loc: no .rsc files found\n");
	    errors = 1;
	} else {
	    do {
		char *fullPath = ConstructPath(rscFileNames, curFile); /* #1 */

		yyin = fopen(fullPath, "rt"); /* #1 */
		if (yyin == NULL) {
		    perror(fullPath);
		    free(fullPath);
		    errors += 1;
		    break;
		}
		free(fullPath);	/* #1 */
		yylineno = 1;
		if (yyparse()) {
		    (void)fclose(yyin);
		    break;
		}
		(void)fclose(yyin);
		
		curFile = GetNextRSCFile();
	    } while (curFile != NULL);
#if defined(_WIN32)
	    /*
	     * Free this up regardless of how we exited.
	     */
	    if (findHandle != INVALID_HANDLE_VALUE) {
		(void) FindClose(findHandle);
	    }
#endif /* _WIN32 */
	}
    }
#endif /* _MSDOS || _WIN32 */
    
    if (errors == 0) {
	DumpLocalizations(outputName);
    }

    /*
     * Free up Hash table to cut down on leaks that BoundsChecker finds.
     * I guess it would be better to iterate thru the thing and free
     * up more stuff, but that's too complicated for now.
     */
    Hash_DeleteTable(&locHash);

    exit(errors);
}	/* End of main.	*/

char lex_buf[1000];

int
yylex(void)
{
    char 	*temp = lex_buf;
    int 	c;
    static int	bumpLine = 0;

    if (bumpLine) {
	yylineno += 1;
	bumpLine = 0;
    }
    
    /*
     * Skip leading whitespace
     */
    do {
	c = getc(yyin);
    } while (isspace(c) && (c != '\n'));
    
    if (c == '\n') {
	bumpLine = 1;
	return c;
    } else if (c == EOF) {
	return 0;
    }
    
    if (c == '"') {
	/*
	 * Quoted string -- read to the matching double-quote. String is
	 * returned without the double-quotes.
	 */
	c = getc(yyin);
	while ((c != EOF) && (c != '"')) {
	    if (c == '\\'){
		c = getc(yyin);
		if (c == EOF) {
		    break;
		}
	    }
	    *temp++ = c;
	    c = getc(yyin);
	}
	*temp = '\0';
    } else {
	do {
	    *temp++ = c;
	    c = getc(yyin);
	} while (!isspace(c));
	
	*temp = '\0';

	/* Put final char back in case it's newline. */
	ungetc(c, yyin);

	if (strcmp(lex_buf, "resource") == 0) {
	    return RESOURCE;
	} else if (strcmp(lex_buf, "GeodeLongName") == 0) {
	    return GEODE_LONG_NAME;
	} else if (strcmp(lex_buf, "Protocol") == 0) {
	    return PROTOCOL;
	}
    }
    
    yylval.string = (char *)malloc(temp - lex_buf + 2);
    strcpy(yylval.string, lex_buf);
    return THING;
}

static void 
yyerror(const char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);
    fprintf(stderr, "file \"%s\", line %d ", curFile, yylineno);
    vfprintf(stderr, fmt, args);
    putc('\n', stderr);
    va_end(args);
    errors += 1;
}
