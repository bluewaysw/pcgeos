/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Simple MS-DOS executable functions
 * FILE:	  com.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 20, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/20/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Output-related functions for creating a .com file (simple
 *	MS-DOS executable).
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: com.c,v 2.5 91/12/12 12:10:59 adam Exp $";
#endif lint

#include <config.h>
#include    "glue.h"
#include    "output.h"
#include <compat/file.h>

/* Goddamn HighC won't let me use my nice typedefs... */
static int ComPrepare(char *, char *, char *);
static int ComReloc(int, SegDesc *, void *, SegDesc *, int, word *);
static void ComWrite(void *, int, char *);
static int ComCheckFixed(SegDesc *);
static void ComSetEntry(SegDesc	*, word);

FileOps	    comOps = {
    ComPrepare,	    /* prepare function */
    0,	    	    /* Runtime relocation size (no runtime relocations) */
    ComReloc,	    /* Convert runtime relocation */
    ComWrite, 	    /* Write com header and the rest of the file. */
    ComCheckFixed,  /* See if a segment is in fixed memory */
    ComSetEntry,    /* So we can error-check */
    FILE_NOCALL,    /* Calls not special */
    "com",  	    /* File suffix */
    NULL,   	    /* No extra options here */
};


/***********************************************************************
 *				ComPrepare
 ***********************************************************************
 * SYNOPSIS:	    Prepare the data structures for creating a .com file
 * CALLED BY:	    InterPass
 * RETURN:	    The size of the resulting file
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Make certain the thing can be made into a .com file:
 *	    - no runtime relocations
 *	    - only one data-bearing segment or all segments in a single
 *	      group.
 *	If one of the segments is a STACK segment, a warning is generated
 *	to indicate SS:SP will not be set to point to it. Perhaps this
 *	should be an error, as exe2bin will make it.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
ComPrepare(char	    *outfile,
	   char	    *paramfile,
	   char	    *mapfile)
{
    int	    cbase;
    int	    i;
    SegDesc *sd;
    
    /*
     * See if there are any runtime relocations around.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	sd = seg_Segments[i];
	if (sd->nrel != 0) {
	    Notify(NOTIFY_ERROR,
		   "cannot create .com file: %i requires relocation when loaded",
		   sd->name);
	    return(0);
	}
    }

    /*
     * Makes sure all the code is in one group or segment. We have to account
     * for the global segment, of course, hence the search for only 2 segments
     * and the single group containing seg_NumSegs-1 segments.
     */
    if (seg_NumSegs != 2) {
	int numRealSegs = 0;

	for (i = 0; i < seg_NumSegs; i++) {
	    if ((seg_Segments[i]->combine != SEG_GLOBAL) &&
		(seg_Segments[i]->combine != SEG_ABSOLUTE) &&
		((seg_NumGroups != 1) ||
		 (seg_Segments[i]->group != seg_Groups[0])))
	    {
		/*
		 * Segment is neither the global one nor absolute, and
		 * it's not in the single group we allow, so count it as
		 * a real segment.
		 */
		numRealSegs += 1;
		
	    }
	}

	if ((numRealSegs != 1) || (seg_NumGroups > 1)) {
	    Notify(NOTIFY_ERROR,
		   "cannot create .com file: all code and data must be in a single segment or group");
	    return(0);
	}
    }

    /*
     * Assign file position(s) to the segment(s) so we can see if the
     * entry point is properly positioned.
     */
    for (cbase = 0, i = 0; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];

	/*
	 * Align code base appropriately. We can't get away with just
	 * paragraph-aligning everything because lmem segments rely
	 * on the heap segment being dword-aligned and no more.
	 */
	cbase = (cbase + sd->alignment) & ~sd->alignment;

	if (cbase & 0xf) {
	    /*
	     * Yuck. We get to modify all the symbols to take into account
	     * the offset from the base of the paragraph. What fun.
	     */
	    Out_ExtraReloc(sd, cbase&0xf);
	}

	sd->foff = sd->nextOff = cbase;
	sd->roff = 0;
	sd->pdata.frame = 0;

	if (sd->combine == SEG_STACK) {
	    Notify(NOTIFY_WARNING,
		   "stack segment %i won't be used automatically by DOS",
		   sd->name);
	}
	
	cbase += sd->size;
    }

    if (cbase > 65535) {
	Notify(NOTIFY_ERROR,
	       "cannot create .com file: combined segments larger than 64k");
	return(0);
    }
    
    /*
     * Print out a map file, if requested.
     */
    if (mapfile) {
	Out_DosMap(mapfile, 0);
    }
    
    /*
     * Looks ok so far...Return the size of the file including the
     * PSP, since there's data from object files that need to go there.
     * We'll biff it in ComWrite...
     */
    return(cbase);
}


/***********************************************************************
 *				ComReloc
 ***********************************************************************
 * SYNOPSIS:	    Enter another runtime relocation
 * CALLED BY:	    Pass2_Load
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Maybe.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
ComReloc(int      type,	    /* Relocation type (from obj file) */
	 SegDesc  *frame,   /* Descriptor of relocation frame */
	 void     *rbuf,    /* Place to store runtime relocation */
	 SegDesc  *targ,    /* Target segment */
	 int      off,	    /* Offset w/in segment of relocation */
	 word     *val)     /* Word being relocated. Store
			     * value needed at runtime in
			     * PC byte-order */
{
    if (type != OREL_SEGMENT || frame->combine != SEG_ABSOLUTE) {
	Notify(NOTIFY_ERROR, "ComReloc called. This is a bug");
    } else {
	/*
	 * Handle segment relocation to absolute segment.
	 */
	byte	*bp = (byte *)val;

	*bp++ = frame->pdata.frame;
	*bp = frame->pdata.frame >> 8;
    }
    return(0);
}


/***********************************************************************
 *				ComWrite
 ***********************************************************************
 * SYNOPSIS:	    Finish with the header and flush all data to disk
 * CALLED BY:	    Out_Final
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    Make sure the first 256 bytes in the output buffer are all 0.
 *	    then write all but those first 256 to the output file.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static void
ComWrite(void	    *base,  	/* Base of file buffer */
	 int	    len,    	/* Length of same */
	 char	    *outfile)	/* Name of output file */
{
    long    	*lp;
    int	    	i;

    if (!entryGiven) {
	Notify(NOTIFY_ERROR,
	       "cannot create .com file: no entry point specified");
	return;
    }

    /*
     * Make sure initial 256 bytes contain no data
     */
    for (lp = (long *)base, i = 256/4; i > 0; i--) {
	if (*lp++ != 0) {
	    Notify(NOTIFY_ERROR,
		   "cannot create .com file: first 256 bytes contain non-zero data (offset %04x)",
		   (genptr)lp-(genptr)base-4);
	    return;
	}
    }
    
    /*
     * Zero out any intersegment gaps in the image.
     */
    for (i = 0; i < seg_NumSegs-1; i++) {
	SegDesc	    *sd = seg_Segments[i];
	SegDesc	    *sd2 = seg_Segments[i+1];

	if (sd->foff + sd->size != sd2->foff) {
	    bzero((genptr)base + sd->foff + sd->size,
		  sd2->foff - (sd->foff + sd->size));
	}
    }

    /*
     * Open the output file and write the entire image to it at once.
     */
    (void)unlink(outfile);
    i = open(outfile, O_BINARY|O_WRONLY|O_CREAT,
	     S_IREAD | S_IWRITE | S_IRUSR | S_IWUSR | S_IROTH | S_IWOTH);
    if (i < 0) {
	perror(outfile);
	errors++;
	return;
    }

    if (write(i, (genptr)base+256, len-256) != len-256) {
	Notify(NOTIFY_ERROR, "Couldn't write entire output file");
	/*
	 * Don't leave partial file around -- interferes with makes
	 */
	(void)unlink(outfile);
	(void)close(i);
	return;
    }

    (void)close(i);
}

/***********************************************************************
 *				ComSetEntry
 ***********************************************************************
 * SYNOPSIS:	    Make sure the entry is being set in the right place
 * CALLED BY:	    Pass 2 functions
 * RETURN:	    Nothing
 * SIDE EFFECTS:
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
ComSetEntry(SegDesc 	*sd,
	    word    	off)
{
    if (off + sd->foff != 256) {
	Notify(NOTIFY_ERROR,
	       "cannot create .com file: entry point must be 0:100h");
    }
}


/***********************************************************************
 *				ComCheckFixed
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
ComCheckFixed(SegDesc	*targ)
{
    return(1);			/* All segments here are in fixed memory */
}
