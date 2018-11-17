/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Font File creation
 * FILE:	  font.c
 *
 * AUTHOR:  	  Adam de Boor: Jan  3, 1990
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/ 3/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for producing PC/GEOS font files.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: font.c,v 1.4 91/04/26 12:38:13 adam Exp $";
#endif lint

#include    <config.h>
#include    "glue.h"
#include    "output.h"
#include    <compat/file.h>


/* Goddamn HighC won't let me use my nice typedefs... */
static int FontPrepare(char *, char *, char *);
static int FontReloc(int, SegDesc *, void *, SegDesc *, int, word *);
static void FontWrite(void *, int, char *);
static int FontCheckFixed(SegDesc *);

FileOps	    fontOps = {
    FontPrepare,	    /* prepare function */
    0,	    	    /* Runtime relocation size */
    FontReloc,	    /* Convert runtime relocation */
    FontWrite, 	    /* Write font header and the rest of the file. */
    FontCheckFixed,   /* See if a segment is in fixed memory */
    (SetEntryProc *)0,
    FILE_NOCALL|FILE_BIGGROUPS,    /* Should be no calls here, but
				    * groups may be huge */
    "fnt",  	    /* File suffix */
    NULL, 	    /* No extra options required */
};

FileOps	    rawOps = {
    FontPrepare,	    /* prepare function */
    0,	    	    /* Runtime relocation size */
    FontReloc,	    /* Convert runtime relocation */
    FontWrite, 	    /* Write font header and the rest of the file. */
    FontCheckFixed,   /* See if a segment is in fixed memory */
    (SetEntryProc *)0,
    FILE_NOCALL|FILE_BIGGROUPS,    /* Should be no calls here, but
				    * groups may be huge */
    "raw",  	    /* File suffix */
    NULL, 	    /* No extra options required */
};


/***********************************************************************
 *				FontPrepare
 ***********************************************************************
 * SYNOPSIS:	    Prepare the data structures for creating a font file
 * CALLED BY:	    InterPass
 * RETURN:	    The size of the resulting file
 * SIDE EFFECTS:    fontHeader is filled in.
 *
 * STRATEGY:
 *	All segments abut each other and together form the whole of the
 *	file -- no header or relocation information required.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
FontPrepare(char    *outfile,
	    char    *paramfile,
	    char    *mapfile)
{
    int	    cbase;
    int	    i;
    
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

	sd->grpOff = sd->foff = sd->nextOff = cbase;
	sd->roff = 0;
	sd->pdata.frame = 0;

	cbase += sd->size;
    }

    if (mapfile) {
	/*
	 * We always print the map to stdout...
	 */
	printf("%d bytes in font file %s\n", cbase, outfile);

	fflush(stdout);
    }
    return(cbase);
}


/***********************************************************************
 *				FontReloc
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
FontReloc(int  	type,	/* Relocation type (from obj file) */
	SegDesc *frame, /* Descriptor of relocation frame */
	void    *rbuf,  /* Place to store runtime relocation */
	SegDesc *targ,  /* Target segment */
	int     off,	/* Offset w/in segment of relocation */
	word    *val)   /* Word being relocated. Store
			 * value needed at runtime in
			 * PC byte-order */
{
    Notify(NOTIFY_ERROR, "FontReloc called. This should not have happened");
    return(0);
}


/***********************************************************************
 *				FontWrite
 ***********************************************************************
 * SYNOPSIS:	    Flush all data to disk
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
FontWrite(void	    *base,  	/* Base of file buffer */
	 int	    len,    	/* Length of same */
	 char	    *outfile)	/* Name of output file */
{
    int	    	i;

    /*
     * Open the output file and write the entire image to it at once.
     */
    (void)unlink(outfile);
#if defined(__HIGHC__)
    i = open(outfile, O_BINARY|O_WRONLY|O_CREAT, S_IREAD | S_IWRITE);
#else
    i = open(outfile, O_WRONLY|O_CREAT, 0666);
#endif
    if (i < 0) {
	perror(outfile);
	errors++;
	return;
    }

    if (write(i, base, len) != len) {
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
 *				FontCheckFixed
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
FontCheckFixed(SegDesc	*targ)
{
    return(1);			/* All segments here are in fixed memory */
}
