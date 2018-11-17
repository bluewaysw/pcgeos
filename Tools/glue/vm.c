/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- VM file creation
 * FILE:	  vm.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 24, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/24/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Output-related functions for creating a VM file.
 *
 *	Each segment or group in the file gets its own VM block, with
 *	the exception of segments in groups, which go into the block
 *	allocated for the group.
 *
 *	HANDLE and SEGMENT relocations yield the VM block handle of the
 *	segment or group. RESID relocations yield the index of the VM
 *	block (the index is (the block handle - 32)/12, i.e. the index of
 *	the block within the block array in the header).
 *
 *	For a given segment or group <name>, three constants are looked for
 *	within the segment:
 *	    - <name>ID is the user ID with which the block should be allocated.
 *	    - <name>PRESERVE indicates the preserve flag for the block
 *	      should be set
 *	    - <name>LMEM indicates whether the block should be marked as
 *	      lmem. This overrides the segment's combine type.
 *
 *	The compaction threshold can be specified in one of two ways:
 *	    * by defining the constant COMPACTION in some segment in the
 *	    file.
 *	    * by using the -C <n> argument
 *	The attributes for the file can be specified in one of two ways:
 *	    * by defining the constant ATTRIBUTES, in some segment in the
 *	      file, to contain the desired attribute bits.
 *	    * by using the -A <n> argument.
 *	The map block for the file is a segment named "MapBlock", by
 *	default. The name sought may, however, be changed with the
 *	-M <name> flag.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vm.c,v 2.18 96/07/08 17:31:14 tbradley Exp $";
#endif lint

#include    "glue.h"
#include    "output.h"
#include    "geo.h"

#include    <config.h>
#include    <compat/file.h>


#include    <stddef.h>

#include    <vm.h>

#ifdef sparc
#include    <alloca.h>
#endif

/* Goddamn HighC won't let me use my nice typedefs... */
static int VmPrepare(char *, char *, char *);
static int VmReloc(int, SegDesc *, void *, SegDesc *, int, word *);
static void VmWrite(void *, int, char *);
static int VmCheckFixed(SegDesc *);

static int  attributes = -1;
static int  compaction = -1;
static char *mapName = "MapBlock";
static char *protocol = "0.0";
static char *release = "0.0.0.0";
static char *token = NULL;
static char *creator = NULL;
static char *longname = NULL;
static char *libtabGeode = NULL;
static char *userNotes = "";

static FileOption   vmOpts[] = {
    {'A',    OPT_INTARG, (void *)&attributes, 	"attributes"},
    {'C',    OPT_INTARG, (void *)&compaction,   "compaction threshold"},
    {'M',    OPT_STRARG, (void *)&mapName,   	"map segment"},
    {'P',    OPT_STRARG, (void *)&protocol,  	"protocol number"},
    {'R',    OPT_STRARG, (void *)&release,   	"release number"},
    {'t',    OPT_STRARG, (void *)&token,	"file's token"},
    {'c',    OPT_STRARG, (void *)&creator,   	"creator's token"},
    {'l',    OPT_STRARG, (void *)&longname,  	"long name"},
    {'i',    OPT_STRARG, (void *)&libtabGeode,	"geode with library table"},
    {'u',    OPT_STRARG, (void *)&userNotes, 	"user notes"},
    {'\0',   OPT_NOARG,	 (void *)NULL,	    	NULL}
};

FileOps	    vmOps = {
    VmPrepare,	    /* prepare function */
    0,	    	    /* Runtime relocation size */
    VmReloc,	    /* Convert runtime relocation */
    VmWrite, 	    /* Write vm header and the rest of the file. */
    VmCheckFixed,   /* See if a segment is in fixed memory */
    (SetEntryProc *)0,
    FILE_NOCALL,    /* Should be no call relocations here */
    "vm",  	    /* File suffix */
    vmOpts, 	    /* Extra options required */
};

static VMHandle	    outFile;	    /* Output file, opened during preparation
				     * as we need the block handles */


/***********************************************************************
 *				VmSwapArea
 ***********************************************************************
 * SYNOPSIS:	    Swap an area of shortwords.
 * CALLED BY:	    VmPrepare
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All the words in the area are byte-swapped.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 3/89	Initial Revision
 *
 ***********************************************************************/
static inline void
VmSwapArea(word    *s,	    /* Start of area to swap */
	   int     i)	    /* Number of bytes to swap */
{
   while (i > 0) {
      swapsp(s);
      s++;
      i -= 2;
   }
}

/***********************************************************************
 *				VmFindSegSym
 ***********************************************************************
 * SYNOPSIS:	    Find a constant specific to the given segment
 * CALLED BY:	    (INTERNAL) VmPrepare
 * RETURN:	    TRUE if found the symbol, *valPtr filled in
 *		    FALSE if didn't find the symbol, *valPtr == 0
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 9/94	Initial Revision
 *
 ***********************************************************************/
static int
VmFindSegSym(ID	segName,
	     const char *suffix,
	     int *valPtr)
{
    const char *sname;
    char *idname;
    int result;
    
    /*
     * Allocate a buffer for the name.
     */
    sname = ST_Lock(symbols, segName);
    idname = (char *)malloc(strlen(sname)+strlen(suffix)+1);

    /*
     * Create the name, please, and release the segment name
     */
    strcpy(idname, sname);
    strcat(idname, suffix);
    ST_Unlock(symbols, segName);
	    
    /*
     * Look for the silly thing.
     */
    result = Out_FindConstSym(idname, valPtr);

    /*
     * Set the value to something consistent, if symbol not found.
     */
    if (!result) {
	*valPtr = 0;
    }

    free(idname);

    return(result);
}


/***********************************************************************
 *				VmPrepare
 ***********************************************************************
 * SYNOPSIS:	    Prepare the data structures for creating a vm file
 * CALLED BY:	    InterPass
 * RETURN:	    The size of the resulting file
 * SIDE EFFECTS:    vmHeader is filled in.
 *
 * STRATEGY:
 *	Make all groups into segments, merging all symbol and line data
 *	into the new segment. The individual segments continue to exist,
 *	but are handled specially (placed in seg_SubSegs) where they can
 *	be found for purposes of figuring where in the executable the
 *	data are to be put, but are otherwise unused.
 *
 *	The positions assigned to segments/groups are only for positioning
 *	in the output buffer, from which the data are copied into the
 *	blocks in the output VM file.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
VmPrepare(char	    *outfile,
	  char	    *paramfile,
	  char	    *mapfile)
{
    int	    cbase;
    int	    i, j;
    short   status;

    if (libtabGeode != NULL) {
	/*
	 * Link in the ldf files for the libraries imported by the given geode,
	 * so object blocks in this file can be properly relocated when loaded
	 * by the geode.
	 */
	word	    	    	libCount;
	ImportedLibraryEntry	*ile;
	FILE	    	    	*geode;
	
	geode = fopen(libtabGeode, "rb");
	if (geode == NULL) {
	    Notify(NOTIFY_ERROR, "%s: cannot open", libtabGeode);
	    return(0);
	}

	if (geosRelease >= 2) {
	    fseek(geode, offsetof(GeodeHeader2, libCount), L_SET);
	    libCount = getc(geode) | (getc(geode) << 8);
	    fseek(geode, sizeof(GeodeHeader2), L_SET);
	} else {
	    fseek(geode, offsetof(GeodeHeader, libCount), L_SET);
	    libCount = getc(geode) | (getc(geode) << 8);
	    fseek(geode, sizeof(GeodeHeader), L_SET);
	}
	/*
	 * File is positioned at the library table. Alloc room for it and read
	 * it in.
	 */
	ile = (ImportedLibraryEntry *)malloc(libCount *
					     sizeof(ImportedLibraryEntry));
	if (fread(ile, sizeof(ImportedLibraryEntry), libCount, geode) !=
	    libCount)
	{
	    Notify(NOTIFY_ERROR,
		   "%s: unable to read entire imported library table",
		   libtabGeode);
	    (void)fclose(geode);
	    free((malloc_t)ile);
	    return(0);
	}
	(void)fclose(geode);

	/*
	 * Now link in the symbols for the libraries one at a time.
	 */
	for (i = 0; i < libCount; i++) {
	    char    libname[GEODE_NAME_SIZE+1];
	    char    *cp;
	    char    *cp2;

	    for (cp = ile[i].name, cp2 = libname, j = GEODE_NAME_SIZE;
		 j > 0 && *cp != ' ';
		 *cp2++ = *cp++)
	    {
		;
	    }
	    *cp2 = '\0';
	    Library_Link(libname, LLT_DYNAMIC, swaps(ile[i].geodeAttrs));
	}
	free((malloc_t)ile);
    }

    /*
     * Promote groups to be segments so we can just use the array of segments
     * as the list of blocks to create.
     */
    Out_PromoteGroups();

    /*
     * Look for COMPACTION and ATTRIBUTES symbols.
     */
    if (compaction == -1) {
	(void)Out_FindConstSym("COMPACTION", &compaction);
	/*
	 * If level still not determined, set to 0 so VM functions
	 * can set the default.
	 */
	if (compaction == -1) {
	    compaction = 0;
	}
    }
    if (attributes == -1) {
	(void)Out_FindConstSym("ATTRIBUTES", &attributes);
	if (attributes == -1) {
	    attributes = 0;
	}
    }
    
    /*
     * Remove and recreate the output file now, as we need to get block
     * handles.
     */
    (void)unlink(outfile);
    outFile = VMOpen(VMO_CREATE_ONLY|FILE_DENY_W|FILE_ACCESS_RW,
		     compaction, outfile, &status);

    if (outFile == NULL) {
	Notify(NOTIFY_ERROR, "%s: cannot open", outfile);
	return(0);
    }
    
    /*
     * Set the various pieces of the file header that aren't set automatically
     * by VMOpen.
     */
    if (geosRelease > 1) {
	GeosFileHeader2	gfh;

	VMGetHeader(outFile, (char *)&gfh);
	
	Geo_DecodeRP(release, 4, (word *)&gfh.release);
	VmSwapArea((word *)&gfh.release, sizeof(gfh.release));
	
	Geo_DecodeRP(protocol, 2, (word *)&gfh.protocol);
	VmSwapArea((word *)&gfh.protocol, sizeof(gfh.protocol));
	
	if (!longname) {
	    longname = outfile;
	}
	if (dbcsRelease) {
	    VMCopyToDBCSString(gfh.longName, longname, sizeof(gfh.longName)-1);
	} else {
	    strncpy(gfh.longName, longname, sizeof(gfh.longName)-1);
	}
	
	if (creator) {
	    if (strlen(creator) < TOKEN_CHARS_SIZE) {
		Notify(NOTIFY_ERROR,
		       "creator's token too small (must be %d chars minimum)",
		       TOKEN_CHARS_SIZE);
		VMClose(outFile);
		unlink(outfile);
		return(0);
	    } else {
		bcopy(creator, gfh.creator.chars, TOKEN_CHARS_SIZE);
	    }
	}
	
	if (token) {
	    if (strlen(token) < TOKEN_CHARS_SIZE) {
		Notify(NOTIFY_ERROR,
		       "file's token too small (must be %d chars minimum)",
		       TOKEN_CHARS_SIZE);
		VMClose(outFile);
		unlink(outfile);
		return(0);
	    } else {
		bcopy(token, gfh.token.chars, TOKEN_CHARS_SIZE);
	    }
	}
	/*
	 * Install the copyright notice.
	 */
	strncpy(gfh.notice, copyright, COPYRIGHT_SIZE);

	/*
	 * Install any user notes.
	 */
	strncpy(gfh.userNotes, userNotes, GFH_USER_NOTES_SIZE);

	/* XXX: NEED TO SUPPORT {token,creator}.manufID AS WELL */
	
	VMSetHeader(outFile, (char *)&gfh);
	
    } else {
	GeosFileHeader	gfh;

	VMGetHeader(outFile, (char *)&gfh);
	
	Geo_DecodeRP(release, 4, (word *)&gfh.core.release);
	VmSwapArea((word *)&gfh.core.release, sizeof(gfh.core.release));
	
	Geo_DecodeRP(protocol, 2, (word *)&gfh.core.protocol);
	VmSwapArea((word *)&gfh.core.protocol, sizeof(gfh.core.protocol));
	
	if (!longname) {
	    longname = outfile;
	}
	strncpy(gfh.core.longName, longname, sizeof(gfh.core.longName)-1);
	
	if (creator) {
	    if (strlen(creator) < TOKEN_CHARS_SIZE) {
		Notify(NOTIFY_ERROR,
		       "creator's token too small (must be %d chars minimum)",
		       TOKEN_CHARS_SIZE);
		VMClose(outFile);
		unlink(outfile);
		return(0);
	    } else {
		bcopy(creator, gfh.core.creator.chars, TOKEN_CHARS_SIZE);
	    }
	}
	
	if (token) {
	    if (strlen(token) < TOKEN_CHARS_SIZE) {
		Notify(NOTIFY_ERROR,
		       "file's token too small (must be %d chars minimum)",
		       TOKEN_CHARS_SIZE);
		VMClose(outFile);
		unlink(outfile);
		return(0);
	    } else {
		bcopy(token, gfh.core.token.chars, TOKEN_CHARS_SIZE);
	    }
	}
	/*
	 * Install the copyright notice.
	 */
	strncpy(gfh.reserved, copyright, COPYRIGHT_SIZE);
	
	/*
	 * Install any user notes.
	 */
	strncpy(gfh.userNotes, userNotes, GFH_USER_NOTES_SIZE);

	/* XXX: NEED TO SUPPORT {token,creator}.manufID AS WELL */
	
	VMSetHeader(outFile, (char *)&gfh);
    }

    VMSetAttributes(outFile, attributes, -1);
    
    /*
     * Assign buffer positions for all the blocks and allocate handles as
     * well (for relocation purposes). NOTE WE SKIP OVER SEGMENT 0, WHICH
     * IS THE GLOBAL SCOPE.
     */
    cbase = 0;

    for (i = 1; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];
	int 	    vmid = 0;

	if (sd->combine != SEG_LIBRARY) {
	    sd->foff = sd->nextOff = cbase;
	    /*
	     * Tack "ID" onto the end of the segment so we can try and find the
	     * desired ID for the block.
	     */
	    (void)VmFindSegSym(sd->name, "ID", &vmid);

	    sd->pdata.block = VMAlloc(outFile, sd->size, vmid);

	    if (VmFindSegSym(sd->name, "LMEM", &vmid)) {
		if (vmid) {
		    VMSetLMemFlag(outFile, sd->pdata.block);
		}
	    } else if (sd->combine == SEG_LMEM) {
		VMSetLMemFlag(outFile, sd->pdata.block);
	    }

	    if (VmFindSegSym(sd->name, "PRESERVE", &vmid)) {
		if (vmid) {
		    VMSetPreserveFlag(outFile, sd->pdata.block);
		}
	    } else if (sd->isObjSeg) {
		VMSetPreserveFlag(outFile, sd->pdata.block);
	    }

	    cbase += sd->size;
	}
    }

    /*
     * Now set the offsets for all the sub-segments.
     */
    for (i = 0; i < seg_NumSubSegs; i++) {
	SegDesc	    *sd = seg_SubSegs[i];
	
	for (j = 0; j < seg_NumSegs; j++) {
	    if ((seg_Segments[j]->name == sd->group->name) &&
		(seg_Segments[j]->class ==  NullID))
	    {
		sd->foff = sd->nextOff = seg_Segments[j]->foff + sd->grpOff;
		sd->pdata.block = seg_Segments[j]->pdata.block;
		/*
		 * No further relocation is required for symbols in this
		 * segment when the group is the frame.
		 */
		sd->grpOff = 0;
		break;
	    }
	}
    }

    /*
     * All done with the group descriptors.
     */
    seg_NumGroups = 0;

    if (mapfile) {
	/*
	 * We always print the map to stdout...
	 */
	printf("Name                          VM Block  Size\n");
	printf("--------------------------------------------\n");
	for (i = 1; i < seg_NumSegs; i++) {
	    SegDesc *sd = seg_Segments[i];
	    
	    if (sd->combine != SEG_LIBRARY) {
		printf("%-30.30i  %04xh  %5d\n",
		       sd->name, sd->pdata.block, sd->size);
	    }
	}

	fflush(stdout);
    }
    return(cbase);
}


/***********************************************************************
 *				VmReloc
 ***********************************************************************
 * SYNOPSIS:	    Enter another runtime relocation
 * CALLED BY:	    Pass2_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Maybe.
 *
 * STRATEGY:
 *	For OREL_CALL, the routine number (if library) or offset (if in
 *	vmde) is stored at *val.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
VmReloc(int  	type,	/* Relocation type (from obj file) */
	SegDesc *frame, /* Descriptor of relocation frame */
	void    *rbuf,  /* Place to store runtime relocation */
	SegDesc *targ,  /* Target segment */
	int     off,	/* Offset w/in segment of relocation */
	word    *val)   /* Word being relocated. Store
			 * value needed at runtime in
			 * PC byte-order */
{
    Library 	*lib;

    /*
     * If frame is a group (through the wonders of Pass 2), map it into its
     * proper segment descriptor so we don't get confused below.
     */
    if (frame->type == S_GROUP) {
	int 	i;

	for (i = 0; i < seg_NumSegs; i++) {
	    if ((seg_Segments[i]->name == frame->name) &&
		(seg_Segments[i]->class == NullID))
	    {
		frame = seg_Segments[i];
		break;
	    }
	}
    }

    /*
     * If relocation to a library, fetch the library descriptor pointer and
     * make sure it exists. If it's still NULL, the library wasn't linked in
     * and we declare an error. We also set up 'info' and 'extra' properly
     * based on the library number as most of the things below require this if
     * the segment is a library.
     */
    if (frame->combine == SEG_LIBRARY) {
	lib = &libs[frame->pdata.library];
    } else {
	lib = 0;		/* Be quiet, GCC (only used if frame->
				 * combine is SEG_LIBRARY, & that doesn't
				 * change...) */
    }
    
    if (type == OREL_SEGMENT || type == OREL_HANDLE) {
	/*
	 * Segment relocations get replaced with the VM block handle of
	 * the frame, but we still don't register any sort of runtime
	 * relocation.
	 */
	byte	*bp = (byte *)val;

	if (frame->combine == SEG_LIBRARY) {
	    Notify(NOTIFY_ERROR,
		   "cannot have segment reference to library segment %i in a VM file",
		   frame->name);
	} else {
	    *bp++ = frame->pdata.block;
	    *bp = frame->pdata.block >> 8;
	}
    } else if (type == OREL_RESID) {
	/*
	 * This is something we handle. Note we have to add the thing
	 * in, rather than storing it, to support the object system
	 * that uses this to generate object relocations as
	 *	dw  ORS_OWNING_GEODE+resid foo
	 *
	 * Note also that for a similar reason, we count RESID
	 * relocations to library segments as desiring their library
	 * numbers...
	 */
	word    w;
	byte	*bp = (byte *)val;
	
	if (frame->combine == SEG_ABSOLUTE) {
	    Pass2_RelocError(targ,off,
			     "cannot get resource ID of %i -- not part of geode",
			     frame->name);
	    return(0);
	}
	w = (*bp | (bp[1] << 8));
	if (frame->combine == SEG_LIBRARY) {
	    /*
	     * Add in the library number
	     */
	    w += lib->lnum;
	} else {
	    /*
	     * Add in the segment's index, which is simply the
	     * block handle, minus 32 (offset VMH_blockTable) divided
	     * by 12 (size VMBlockHandle).
	     */
	    w += (frame->pdata.block - 32)/12;
	}
	
	*bp++ = w;
	*bp = w >> 8;
    }
    /*
     * Non-SEGMENT, non-RESID relocations are completely ignored.
     */
    return(0);
}


/***********************************************************************
 *				VmWrite
 ***********************************************************************
 * SYNOPSIS:	    Finish with the header and flush all data to disk
 * CALLED BY:	    Out_Final
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static void
VmWrite(void	    *base,  	/* Base of file buffer */
	 int	    len,    	/* Length of same */
	 char	    *outfile)	/* Name of output file */
{
    void    	*block;
    int	    	i;
    ID	    	map = ST_LookupNoLen(symbols, strings, mapName);
    ID	    	dbMap = ST_LookupNoLen(symbols, strings, "__DBMapBlock");

    /*
     * For each segment, lock its block down and copy the data from the
     * output buffer to the actual block, the mark the block dirty and
     * release it.
     */
    for (i = 1; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];
	
	if (sd->combine != SEG_LIBRARY) {
	    /*
	     * If segment has the same name as the map block, set the
	     * handle as the map block handle...
	     */
	    if (sd->name == map) {
		VMSetMapBlock(outFile, sd->pdata.block);
	    } else if (sd->name == dbMap) {
		VMSetDBMap(outFile, sd->pdata.block);
	    }
	    
	    block = VMLock(outFile, sd->pdata.block, (MemHandle *)NULL);
	    bcopy((genptr)base+sd->foff, block, sd->size);
	    
	    VMUnlockDirty(outFile, sd->pdata.block);
	}
    }

    /*
     * Flush all the data to the output file. That's all we need to do.
     */
    VMClose(outFile);
}

/***********************************************************************
 *				VmCheckFixed
 ***********************************************************************
 * SYNOPSIS:	    Make sure a resource isn't movable
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Non-zero if resource is fixed
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/18/89	Initial Revision
 *
 ***********************************************************************/
static int
VmCheckFixed(SegDesc	*targ)
{
    return(1);			/* All segments here are in fixed memory */
}
