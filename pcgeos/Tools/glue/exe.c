/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- DOS Exe file manipulation
 * FILE:	  exe.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 16, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	PrepareExe  	    Set up to write a .exe file.
 *
 * REVISION HISTORY:
 *	Date	    Name    Description
 *	----	    ----    -----------
 *	10/16/89    ardeb    Initial version
 *
 * DESCRIPTION:
 *	Functions for manipulating a .exe file as our output.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: exe.c,v 2.6 91/04/26 12:38:03 adam Exp $";
#endif lint

#include <config.h>
#include    "glue.h"
#include    "output.h"
#include <compat/file.h>

/* Goddamn HighC won't let me use my nice typedefs... */
static int ExePrepare(char *, char *, char *);
static int ExeReloc(int, SegDesc *, void *, SegDesc *, int, word *);
static void ExeWrite(void *, int, char *);
static int ExeCheckFixed(SegDesc *);
static void ExeSetEntry(SegDesc	*, word);

FileOps	    exeOps = {
    ExePrepare,	    /* prepare function */
    4,	    	    /* Runtime relocation size */
    ExeReloc,	    /* Convert runtime relocation */
    ExeWrite, 	    /* Write exe header and the rest of the file. */
    ExeCheckFixed,  /* See if a segment is in fixed memory */
    ExeSetEntry,    /* Set the entry point for the executable */
    FILE_NOCALL,    /* Calls are statically relocated */
    "exe",  	    /* File suffix */
    NULL,   	    /* No extra options here */
};

static struct ExeHeader {
    byte  	  sig1;	    	/* First signature byte */
    byte  	  sig2;	    	/* Second signature byte */
    word 	  imageLenRem;	/* Number of bytes in last 512-byte block */
    word 	  fileSize; 	/* Size of entire file (512-byte increments) */
    word 	  numItems; 	/* Number of relocation items */
    word 	  headerSize;	/* Size of header, in paragraphs. */
    word 	  minExtra; 	/* Minimum number of paragraphs needed */
    word 	  maxExtra; 	/* Max number of paragraphs needed */
    word	  stackDisp;	/* Offset of stack segment in load module */
    word	  initSP;   	/* Initial stack pointer w/in that segment */
    word	  checksum; 	/* Checksum of all words in file */
    word	  initIP;   	/* Offset of entry point */
    word	  codeDisp; 	/* Initial code segment */
    word	  relDisp;  	/* File offset to relocation table */
    word	  overlayNum;	/* Overlay number */
} 	    exeHeader;	    /* Header from .exe file */

static int  	imgBase;

/***********************************************************************
 *				ExePrepare
 ***********************************************************************
 * SYNOPSIS:	    Prepare the output file as a .exe
 * CALLED BY:	    InterPass
 * RETURN:	    Total size of file.
 * SIDE EFFECTS:    The .exe header is set up.
 *	    	    foff and roff fields for all segments are filled in.
 *
 * STRATEGY:
 *
 *	count # of runtime relocations
 *	store in header
 *	figure header size and load-image base
 *	rbase = EOH
 *	cbase = image base
 *	foreach segment:
 *	    s->roff = rbase
 *	    rbase += nrel * sizeof(rel)
 *	    if align > para {
 *	    	align cbase properly
 *	    } else {
 *	    	para-align cbase
 *	    }
 *	    s->foff = cbase
 *	    if segment the stack segment {
 *	    	hdr.ss = cbase - image base
 *	    	hdr.sp = segment size
 *	    }
 *	    if entry point in segment {
 *	    	hdr.cs = cbase - image base
 *	    	hdr.ip = entry offset
 *	    }
 *	    cbase += segment size
 *	hcaerof
 *	hdr.flen = (cbase + 511) / 512
 *	hdr.fmod = cbase & 511
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/12/89	Initial Revision
 *
 ***********************************************************************/
static int
ExePrepare(char	*outfile,   	/* UNUSED */
	   char *paramfile, 	/* UNUSED */
	   char	*mapfile)   	/* Place to store address map */
{
    SegDesc 	*sd;	    /* Current segment */
    int	    	i;  	    /* Segment number */
    int	    	nrel;	    /* Total number of runtime relocations */
    int	    	rbase;	    /* Relocation base for current segment */
    int	    	cbase;	    /* Code base for current segment */
    byte    	*bp;	    /* Pointer for setting header fields */
    int	    	flen;

    bzero(&exeHeader, sizeof(exeHeader));

    /*
     * Initialize signature for the header
     */
    exeHeader.sig1 = 'M';
    exeHeader.sig2 = 'Z';

    /*
     * Relocations always follow immediately after the header and the
     * copyright notice.
     */
    rbase = sizeof(exeHeader) + ((COPYRIGHT_SIZE + 1) & ~1);
    bp = (byte *)&exeHeader.relDisp;
    *bp++ = rbase;
    *bp = rbase >> 8;
    
    /*
     * We don't deal with the minExtra/maxExtra stuff. We're not intended
     * for linking DOS programs much...minExtra gets 0 (already there),
     * maxExtra gets FFFF
     */
    exeHeader.maxExtra = 0xffff;    /* Ditto */
    
    /*
     * Count the number of runtime relocations from all segments
     */
    for (nrel = i = 0; i < seg_NumSegs; i++) {
	sd = seg_Segments[i];
	nrel += sd->nrel;
    }

    /*
     * Store in header.
     */
    bp = (byte *)&exeHeader.numItems;
    *bp++ = nrel;
    *bp = nrel >> 8;

    /*
     * Figure size of header in paragraphs. Each relocation takes 4 bytes.
     */
    i = (sizeof(exeHeader) + (nrel * 4) + 15) >> 4;

    /*
     * Round up to a multiple of 512 (it's what MS-DOS likes and allows us
     * to page-align things as well). There are 32 paragraphs in 512 bytes,
     * hence the use of "31", below.
     */
    i = (i + 31) & ~31;
    
    bp = (byte *)&exeHeader.headerSize;
    *bp++ = i;
    *bp = i >> 8;

    cbase = imgBase = i << 4;

    for (i = 0; i < seg_NumSegs; i++) {
	sd = seg_Segments[i];

	if (sd->combine != SEG_ABSOLUTE) {
	    /*
	     * Set and advance offset for relocations.
	     */
	    sd->roff = rbase;
	    rbase += sd->nrel * 4;
	    
	    /*
	     * Align code base appropriately.
	     */
	    cbase = (cbase + sd->alignment) & ~sd->alignment;
	    
	    if (cbase & 0xf) {
		/*
		 * Yuck. We get to modify all the symbols to take into account
		 * the offset from the base of the paragraph. What fun.
		 */
		Out_ExtraReloc(sd, cbase&0xf);
	    }
	    
	    /*
	     * Set the private data and file offsets based on current code
	     * base.
	     */
	    sd->nextOff = sd->foff = cbase;
	    sd->pdata.frame = (cbase - imgBase) >> 4;
	}
	    
	/*
	 * If segment is the stack segment, set SS:SP in the header. SP
	 * is set to be one greater than the size of the segment so when
	 * the first word is pushed, it goes into the segment.
	 */
	if (sd->combine == SEG_STACK) {
	    bp = (byte *)&exeHeader.stackDisp;
	    /* SS first */
	    *bp++ = sd->pdata.frame;
	    *bp++ = sd->pdata.frame >> 8;

	    /* Now SP, taken from the size of the segment, which gives
	     * the requisite byte-above-end-of-stack */
	    *bp++ = sd->size;
	    *bp   = (sd->size) >> 8;
	}

	/*
	 * Shift code base ahead by the size of the segment.
	 */
	cbase += sd->size;
    }

    /*
     * Figure number of 512-byte pages in the file. This includes the final
     * partial page, hence the rounding up.
     */
    flen = (cbase + 511) / 512;
    bp = (byte *)&exeHeader.fileSize;
    *bp++ = flen;
    *bp = flen >> 8;

    /*
     * Figure actual length of final page and store in header.
     */
    bp = (byte *)&exeHeader.imageLenRem;
    *bp++ = cbase & 511;
    *bp = (cbase & 511) >> 8;

    /*
     * Fill in the frame and offset things for any groups.
     */

    for (i = 0; i < seg_NumGroups; i++) {
	GroupDesc   *gd = seg_Groups[i];
	int 	    j, k;

	/*
	 * Find the first segment in the executable from the group.
	 */
	k = 0;
	for (j = 1; j < gd->numSegs; j++) {
	    if (gd->segs[j]->foff < gd->segs[k]->foff) {
		k = j;
	    }
	}
	
	/*
	 * Set the frame, file offset and segment offset to match that
	 * of the first segment, copying in the frame number as well.
	 * XXX: Why is offset that of the segment and not of the group?
	 */
	gd->foff = gd->segs[k]->foff;
	gd->pdata.frame = gd->segs[k]->pdata.frame;
	gd->offset = gd->segs[k]->offset;

	/*
	 * Set the grpOff fields for all the contained segments.
	 */
	for (j = 0; j < gd->numSegs; j++) {
	    gd->segs[j]->grpOff = gd->segs[j]->foff - gd->segs[k]->foff;
	    /*
	     * If any segment goes more than 64K from the base of the group,
	     * give an error and break out now. We won't actually move on
	     * to pass2.
	     */
	    if ((gd->segs[j]->grpOff = gd->segs[j]->size) > 65535) {
		Notify(NOTIFY_ERROR,
		       "group %i spans more than 64K", gd->name);
		return(0);
	    }
	}
    }

    /*
     * Deal with map file silliness.
     */
    if (mapfile != NULL) {
	Out_DosMap(mapfile, imgBase);
    }

    /*
     * Return total file size.
     */
    return(cbase);
}

	

/***********************************************************************
 *				ExeReloc
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
ExeReloc(int      type,	    /* Relocation type (from obj file) */
	 SegDesc  *frame,   /* Descriptor of relocation frame */
	 void     *rbuf,    /* Place to store runtime relocation */
	 SegDesc  *targ,    /* Target segment */
	 int      off,	    /* Offset w/in segment of relocation */
	 word     *val)     /* Word being relocated. Store
			     * value needed at runtime in
			     * PC byte-order */
{
    byte    	*bp;	    /* For storing new value */
    
    if (type != OREL_SEGMENT) {
	Notify(NOTIFY_WARNING,
	       "ExeReloc: Can only handle SEGMENT relocations");
	return(0);
    }

    /*
     * First store the frame number for the relocation frame in the segment
     * data.
     */
    bp = (byte *)val;
    *bp++ = frame->pdata.frame;
    *bp = frame->pdata.frame >> 8;

    if (frame->combine != SEG_ABSOLUTE) {
	/*
	 * Now store the relocation, which is simply the frame and offset at
	 * which the relocation is to occur, in PC byte-order, of course. Note
	 * that "off" is unrelocated -- we need to add the offset for the base
	 * of the current segment piece into it to get the proper offset.
	 */
	off += targ->nextOff - targ->foff;
	
	bp = rbuf;
	*bp++ = off;
	*bp++ = off >> 8;
	*bp++ = targ->pdata.frame;
	*bp = targ->pdata.frame >> 8;
	return(1);
    } else {
	/*
	 * If relocation is to an absolute segment, there's no need to
	 * store a runtime relocation -- absolute values don't change much,
	 * except according to quantum physics...
	 */
	return(0);
    }
}


/***********************************************************************
 *				ExeSetEntry
 ***********************************************************************
 * SYNOPSIS:	    Record the entry point for the executable
 * CALLED BY:	    Pass 2 functions
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The CS:IP in the header are set.
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
ExeSetEntry(SegDesc 	*sd,
	    word    	off)
{
    byte    	*bp;

    bp = (byte *)&exeHeader.initIP;

    /* IP first */
    *bp++ = off;
    *bp++ = off >> 8;

    /* Now CS */
    *bp++ = sd->pdata.frame;
    *bp   = sd->pdata.frame >> 8;
}


/***********************************************************************
 *				ExeWrite
 ***********************************************************************
 * SYNOPSIS:	    Write the exe file to the output stream.
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
ExeWrite(void	    *base,  	/* Base of file buffer */
	 int	    len,    	/* Length of same */
	 char	    *outfile)	/* Name of output file */
{
    int	    i;
    word    csum;
    word    *wp;
    byte    *bp;
    
    /*
     * First copy the header and copyright into the buffer so we can figure the
     * checksum.
     */
    bcopy(&exeHeader, base, sizeof(exeHeader));
    bcopy(copyright, (genptr)base + sizeof(exeHeader), (COPYRIGHT_SIZE+1)&~1);

    /*
     * Zero out any intersegment gaps in the image.
     */
    for (i = 0; i < seg_NumSegs-1; i++) {
	SegDesc	    *sd = seg_Segments[i];
	SegDesc	    *sd2 = seg_Segments[i+1];

	if ((sd2->combine != SEG_ABSOLUTE) && (sd->combine != SEG_ABSOLUTE) &&
	    (sd->foff + sd->size != sd2->foff))
	{
	    bzero((genptr)base + sd->foff + sd->size,
		  sd2->foff - (sd->foff + sd->size));
	}
    }

    /*
     * Form 16-bit checksum. If odd number of bytes, final byte is treated
     * as low byte of a word whose high byte is 0.
     */
    for (csum = 0, i = len, wp = base;
	 i > 1;
	 csum += *wp++, i -= 2)
    {
	;
    }
    if (i != 0) {
	csum += *(byte *)wp;
    }

    /*
     * DOS wants the one's complement of this. Form it, then store the
     * result in the header now in the image.
     */
    csum = ~csum;
    bp = (byte *)&((struct ExeHeader *)base)->checksum;
    *bp++ = csum;
    *bp = csum >> 8;

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

    if (write(i, base, len) != len) {
	Notify(NOTIFY_ERROR, "Couldn't write entire output file");
	(void)close(i);
	/*
	 * Don't leave partial file around -- interferes with makes
	 */
	(void)unlink(outfile);
	return;
    }

    (void)close(i);
}

/***********************************************************************
 *				ExeCheckFixed
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
ExeCheckFixed(SegDesc	*targ)
{
    return(1);			/* All segments here are in fixed memory */
}
