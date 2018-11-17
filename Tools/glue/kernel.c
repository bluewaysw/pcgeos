/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Kernel executable file manipulation
 * FILE:	  kernel.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 16, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	    Name    Description
 *	----	    ----    -----------
 *	10/16/89    ardeb    Initial version
 *
 * DESCRIPTION:
 *	Functions for manipulating a kernel executable file as our output.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: kernel.c,v 3.5 92/03/25 19:33:53 adam Exp $";
#endif lint

#include    "glue.h"
#include    "output.h"
#include    "geo.h"
#include    "sym.h"

#if defined(unix)
# include <sys/file.h>
#elif defined(_MSDOS)
# include <io.h>
# include <dos.h>
# include <fcntl.h>
# define L_SET SEEK_SET
# define L_XTND SEEK_END
# define L_INCR SEEK_CUR
# define F_OK 0
#elif defined(__WATCOMC__)
# define L_SET SEEK_SET
# define L_XTND SEEK_END
# define L_INCR SEEK_CUR
#endif

/* Goddamn HighC won't let me use my nice typedefs... */
static int KernelPrepare(char *, char *, char *);
static int KernelReloc(int, SegDesc *, void *, SegDesc *, int, word *);
static void KernelWrite(void *, int, char *);
static int KernelCheckFixed(SegDesc *);
static void KernelSetEntry(SegDesc *, word);

static char	    	*release = "0.0.0.0";
static char	    	*protocol = "0.0";
extern int  	    	makeLDF;

static FileOption kernelOpts[] = {
    {'R',    OPT_STRARG,	    (void *)&release,	"release number"},
    {'P',    OPT_STRARG,	    (void *)&protocol,	"protocol number"},
    {'l',    OPT_NOARG,	    (void *)&makeLDF,	NULL},
    {0,	    OPT_NOARG,	    (void *)NULL,   	NULL}
};

FileOps	    kernelOps = {
    KernelPrepare,    /* prepare function */
    4,	    	    /* Runtime relocation size */
    KernelReloc,    /* Convert runtime relocation */
    KernelWrite,    /* Write kernel header and the rest of the file. */
    KernelCheckFixed,	/* See if a segment is in fixed memory */
    KernelSetEntry, /* Set the entry point for the kernel */
    FILE_NOCALL|FILE_NEEDPARAM|FILE_USES_GEODE_PARAMS,  /* Calls are staticly
							 * relocated */
    "exe",  	    /* File suffix */
    kernelOpts,	    /* Extra options required */
};
/*
 * Data for rearranging things to suit our evil purposes. For each
 * entry, "group" is the name of a group in the kernel and "pseg" is
 * the name of the principal segment in that group under which the entire
 * group should be known, when this is all done.
 */
static struct {
    char	    *group;	/* Name of group */
    char	    *pseg;	/* Principal segment */
    GroupDesc       *gd;    	/* Located group descriptor */
    int	    	    psegIdx;	/* Index of principal segment in group */
}	    	mushsegs[] = {
    {"cgroup",	    	"kcode",    NULL,   0},
    {"dgroup",   	"kdata",    NULL,   0},
    {"initGroup",	"kinit",    NULL,   0}
};
#define NUM_MUSH (sizeof(mushsegs)/sizeof(mushsegs[0]))
static SegDesc	*krout;

/*
 * Data for arranging the kernel resources as Swat would like to see them.
 * Each entry is a name and ID in ascending order of resource ID. Note that
 * the global segment is always id 0.
 */
static struct {
    char    	    *name;
    ID	    	    id;
} 	    	kernelSegs[] = {
    {"global",	    NullID}, 	/* Not filled in... */
    {"kdata",	    NullID},
    {"kcode",	    NullID},
    {"krout",	    NullID},
    {"kinit",	    NullID},
    {"DOSSeg",	    NullID},
    {"SwatSeg",	    NullID},
    {"BIOSSeg",	    NullID},
    {"PSP",  	    NullID}
};
#define NUM_KSEGS    (sizeof(kernelSegs)/sizeof(kernelSegs[0]))

/*
 * Data for arranging the kernel resources as they need to be for
 * execution.
 */
static struct {
    char    	    *name;
    ID	    	    id;
}	    	execSegs[] = {
    {"global",	    NullID}, 	/* Not filled in... */
    {"kcode",	    NullID},
    {"krout",	    NullID},
    {"kdata",	    NullID},
    {"kinit",	    NullID},
    {"DOSSeg",	    NullID},
    {"SwatSeg",	    NullID},
    {"BIOSSeg",	    NullID},
    {"PSP",  	    NullID}
};
#define NUM_ESEGS    (sizeof(execSegs)/sizeof(execSegs[0]))


static SegDesc	    **unorderedSegs;	/* Array of segments as used by the
					 * .exe prepare routine. Temporarily
					 * replaces seg_Segments while we
					 * call the .exe write routine so
					 * it can zero inter-segment gaps
					 * correctly */


/***********************************************************************
 *				KernelPrepare
 ***********************************************************************
 * SYNOPSIS:	    Prepare the output file as a .kernel
 * CALLED BY:	    InterPass
 * RETURN:	    Total size of file.
 * SIDE EFFECTS:    The .kernel header is set up.
 *	    	    foff and roff fields for all segments are filled in.
 *
 * STRATEGY:
 *	Merge groups into segments and call exe preparation.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/12/89	Initial Revision
 *
 ***********************************************************************/
static int
KernelPrepare(char	*outfile,   	/* UNUSED */
	      char  	*paramfile, 	/* Geode parameter file containing
					 * interface definition. */
	      char	*mapfile)   	/* Place to store address map */
{
    int	    	i;  	    /* General index */
    int	    	res;	    /* Result from ExePrepare */
    int	    	oldng;	    /* Saved number of groups during ExePrepare */
    int	    	j;  	    /* Colonel index */
    ID	    	kroutID;

    /*
     * Decode protocol and release numbers - they default to 0 if not
     * given. We decode them into the "geoHeader" because that's where
     * the Library module expects them to be -- this is the only thing besides
     * a geode that needs to build a .ldf file, so...
     */
    if (geosRelease >= 2) {
	Geo_DecodeRP(release,4,
		     (word *)&geoHeader.v2x.execHeader.geosFileHeader.release);

	Geo_DecodeRP(protocol, 2,
		     (word *)&geoHeader.v2x.execHeader.geosFileHeader.protocol);
    } else {
	Geo_DecodeRP(release,4,
		     (word *)&geoHeader.v1x.execHeader.geosFileHeader.core.release);

	Geo_DecodeRP(protocol, 2,
		     (word *)&geoHeader.v1x.execHeader.geosFileHeader.core.protocol);
    }

    /*
     * Make the principal segment for each group be the first segment
     * for each group. This ensures it's at the right location (i.e. first)
     * in the executable and makes it easier to find later.
     */
    for (i = 0; i < NUM_MUSH; i++) {
	ID	    	id; 	    /* Identifier for principal segment */
	ID	    	gid;	    /* Identifier for group */
	GroupDesc	*gd;	    /* Descriptor for group */
	
	id = ST_LookupNoLen(symbols, strings, mushsegs[i].pseg);
	gid = ST_LookupNoLen(symbols, strings, mushsegs[i].group);

	for (j = 0; j < seg_NumGroups; j++) {
	    if (seg_Groups[j]->name == gid) {
		break;
	    }
	}
	assert(j != seg_NumGroups);
	mushsegs[i].gd = gd = seg_Groups[j];
	for (j = 0; j < gd->numSegs; j++) {
	    if (gd->segs[j]->name == id) {
		mushsegs[i].psegIdx = j;
		break;
	    }
	}
	assert(j != gd->numSegs);
    }

    /*
     * Mark all segments as fixed so Library module knows
     */
    for (i = 0; i < seg_NumSegs; i++) {
	seg_Segments[i]->flags = RESF_FIXED;
    }
    
    /*
     * Build up the library definition file.
     */
    if (!Parse_GeodeParams(paramfile, outfile, FALSE)) {
	return(0);
    }

    /*
     * Set the size of the krout segment wherein we place the routine
     * table. We do this before promoting the groups so it gets the sizing
     * right.
     */
    kroutID = ST_LookupNoLen(symbols, strings, "krout");
    if (kroutID == NullID) {
	Notify(NOTIFY_ERROR, "krout not defined -- cannot make kernel");
	return(0);
    }
    for (i = 0; i < seg_NumSegs; i++) {
	if (seg_Segments[i]->name == kroutID) {
	    krout = seg_Segments[i];
	    break;
	}
    }
    if (krout == NULL) {
	Notify(NOTIFY_ERROR, "krout not a segment -- cannot make kernel");
	return(0);
    }
    krout->size = numEPs * 2;
    
    /*
     * It makes life much easier if we promote all groups to be
     * segments in their own right.
     */
    Out_PromoteGroups();

    /*
     * Set the name and class of the promoted group-segments to match those
     * of their principal segment, replacing the old principal segment
     * slot in the old group descriptor with the new group-segment descriptor,
     * allowing us to find the group-segment easily when we have to adjust
     * the data for the subsegments. Note that all promoted groups end up
     * at the end of seg_Segments and there are NUM_MUSH of them, so...
     */
    for (i = 0; i < NUM_MUSH; i++) {
	SegDesc	*sd = seg_Segments[(seg_NumSegs-NUM_MUSH)+i];

	sd->class = sd->group->segs[mushsegs[i].psegIdx]->class;
	sd->name = sd->group->segs[mushsegs[i].psegIdx]->name;
    }
	
    /*
     * Arrange all the segments in their proper order for execution, based on
     * execSegs.
     */
    if (seg_NumSegs != NUM_ESEGS) {
	Notify(NOTIFY_ERROR, "improper number of segments (have %d, want %d) -- cannot make kernel",
	       seg_NumSegs, NUM_ESEGS);
    }
    
    for (i = 1; i < NUM_ESEGS; i++) {
	execSegs[i].id = ST_LookupNoLen(symbols, strings, execSegs[i].name);
    }

    unorderedSegs = seg_Segments;
    seg_Segments = (SegDesc **)malloc(seg_NumSegs * sizeof(SegDesc *));
    
    for (i = 0; i < NUM_ESEGS; i++) {
	int 	j;

	for (j = 0; j < NUM_ESEGS; j++) {
	    if (unorderedSegs[j]->name == execSegs[i].id) {
		seg_Segments[i] = unorderedSegs[j];
		break;
	    }
	}
    }
    free((char *)unorderedSegs);

	
    /*
     * Make sure ExePrepare doesn't dick with groups at all.
     */
    oldng = seg_NumGroups;
    seg_NumGroups = 0;
    
    res = (*exeOps.prepare)(outfile, paramfile, mapfile);

    seg_NumGroups = oldng;
    
    /*
     * Set the file and relocation offsets for all the sub-segments and the
     * (ex-)groups.
     */
    for (i = 0; i < seg_NumSubSegs; i++) {
	SegDesc	*group, *sd;
	int 	j;

	sd = seg_SubSegs[i];

	/*
	 * Locate the promoted group
	 */
	for (j = 0; j < seg_NumSegs; j++) {
	    if (seg_Segments[j]->group == sd->group) {
		break;
	    }
	}
	assert(j != seg_NumSegs);
	
	group = seg_Segments[j];
	
	sd->nextOff = sd->foff = group->foff + sd->grpOff;
	sd->roff += group->roff;
	/*
	 * Subsegment must have own frame! (kernel uses this, e.g.)
	 */
	sd->pdata.frame = group->pdata.frame + (sd->grpOff >> 4);

	sd->grpOff = 0;
    }

    for (i = 0; i < seg_NumGroups; i++) {
	GroupDesc   *gd;

	gd = seg_Groups[i];
	gd->pdata.frame = gd->segs[0]->pdata.frame;
	gd->foff = gd->segs[0]->foff;
    }
    
    /*
     * To make sure the data from the segment end up in the same place
     * during the second pass, set the alignment for the group to match
     * that of the main segment. Any data in other segments (e.g. kstack)
     * will maintain its alignment since that was determined during the
     * layout and pass2 will use the group-segment alignment left over from
     * when the thing was a real segment.
     *
     * NOTE: Out_PromoteGroups initially makes all promoted groups have
     * paragraph alignment and it is this value that ExePrepare uses for
     * laying out the groups in the file. We need to reset it, however, for
     * the actual layout of the subsegment's data.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	SegDesc	*sd = seg_Segments[i];
	int 	j;

	for (j = 0; j < seg_NumSubSegs; j++) {
	    if (seg_SubSegs[j]->name == sd->name) {
		sd->alignment = seg_SubSegs[j]->alignment;
		sd->nextOff = seg_SubSegs[j]->foff;
		sd->roff = seg_SubSegs[j]->roff;
		break;
	    }
	}
    }
	
    /*
     * Arrange all the segments in their proper order for Swat, based on
     * kernelSegs.
     */
    if (seg_NumSegs != NUM_KSEGS) {
	Notify(NOTIFY_ERROR, "improper number of segments (have %d, want %d) -- cannot make kernel",
	       seg_NumSegs, NUM_KSEGS);
    }
    
    for (i = 1; i < NUM_KSEGS; i++) {
	kernelSegs[i].id = ST_LookupNoLen(symbols, strings, kernelSegs[i].name);
    }

    unorderedSegs = seg_Segments;
    seg_Segments = (SegDesc **)malloc(seg_NumSegs * sizeof(SegDesc *));
    
    for (i = 0; i < NUM_KSEGS; i++) {
	int 	j;

	for (j = 0; j < NUM_KSEGS; j++) {
	    if (unorderedSegs[j]->name == kernelSegs[i].id) {
		seg_Segments[i] = unorderedSegs[j];
		break;
	    }
	}
    }
	
    return(res);
}

	

/***********************************************************************
 *				KernelReloc
 ***********************************************************************
 * SYNOPSIS:	    Perform a runtime relocation
 * CALLED BY:	    Pass2_Load
 * RETURN:	    Non-zero if a relocation was actually entered
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/17/89	Initial Revision
 *
 ***********************************************************************/
static int
KernelReloc(int      type,  /* Relocation type (from obj file) */
	    SegDesc  *frame,/* Descriptor of relocation frame */
	    void     *rbuf, /* Place to store runtime relocation */
	    SegDesc  *targ, /* Target segment */
	    int      off,   /* Offset w/in segment of relocation */
	    word     *val)  /* Word being relocated. Store
			     * value needed at runtime in
			     * PC byte-order */
{
    /*
     * Pass these w/o complaint for default window/gstate segments in kdata
     */
    if (type == OREL_HANDLE) {
	return(0);
    }
    return (*exeOps.maprel)(type, frame, rbuf, targ, off, val);
}


/***********************************************************************
 *				KernelSetEntry
 ***********************************************************************
 * SYNOPSIS:	    Set the kernel's entry point
 * CALLED BY:	    Pass 2 functions
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/20/90		Initial Revision
 *
 ***********************************************************************/
static void
KernelSetEntry(SegDesc	*sd,
	       word 	off)
{
    (*exeOps.setEntry) (sd, off);
}


/***********************************************************************
 *				KernelWrite
 ***********************************************************************
 * SYNOPSIS:	    Write the kernel file to the output stream.
 * CALLED BY:	    Final
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Copy the header into the buffer at its start.
 *	Fill any intersegment gaps with zeroes.
 *	Calculate and store checksum
 *	Open output file and write entire image to it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/17/89	Initial Revision
 *
 ***********************************************************************/
static void
KernelWrite(void    *base,  	/* Base of file buffer */
	    int	    len,    	/* Length of same */
	    char    *outfile)	/* Name of output file */
{
    int	    	    i;
    word    	    *table = (word *)malloc(numEPs * sizeof(word));
    SegDesc 	    **segs;
    
    /*
     * Form the routine entry table for the kernel and send it to the
     * output buffer.
     */
    for (i = 0; i < numEPs; i++) {
	ObjSym  	*sym;

	if (entryPoints[i].block == 0) {
	    /*
	     * If slot is empty, try and find SysEmptyRoutine (only look for
	     * it once, though -- record the block/offset of the thing)
	     */
	    static VMBlockHandle    block;
	    static word    	    offset;

	    if (!block && !Sym_Find(symbols,
				    NULL,
				    ST_EnterNoLen(symbols,
						  strings,
						  "SysEmptyRoutine"),
				    &block,
				    &offset,
				    TRUE))
	    {
		Notify(NOTIFY_ERROR, "empty slot in routine table and SysEmptyRoutine not defined");
		goto done;
	    }
	    
	    sym = (ObjSym *)((genptr)VMLock(symbols, block, (MemHandle *)NULL)+
			     offset);
	    table[i] = swaps(sym->u.addrSym.address);
	    VMUnlock(symbols, block);
	} else {
	    /*
	     * Library module already checked symbol type and located the
	     * thing, so we can just lock it down and fetch its address out.
	     */
	    sym = (ObjSym *)((genptr)VMLock(symbols,
					    entryPoints[i].block,
					    (MemHandle *)NULL)+
			     entryPoints[i].offset);
	    table[i] = swaps(sym->u.addrSym.address);
	    VMUnlock(symbols, entryPoints[i].block);
	}
    }

    /*
     * Send the segment to the output buffer.
     */
    Out_Block(krout->foff, table, numEPs * sizeof(word));

    /*
     * Now write the thing out as a regular exe file.
     */
    segs = seg_Segments;
    seg_Segments = unorderedSegs;
    (*exeOps.write)(base, len, outfile);
    seg_Segments = segs;
done:
    free((char *)table);
}

/***********************************************************************
 *				KernelCheckFixed
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
KernelCheckFixed(SegDesc	*targ)
{
    return(1);			/* All segments here are in fixed memory */
}
