/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Geode Creation Functions
 * FILE:	  geo.c
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
 *	Output-related functions for creating geodes. Actual functionality
 *	split across the files geo.c, parse.y and library.c
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: geo.c,v 3.60 96/07/08 17:27:25 tbradley Exp $";
#endif lint

#include    <config.h>
#include    "glue.h"
#include    "output.h"
#include    "geo.h"
#include    <compat/file.h>
#include    <compat/string.h>

#include    <stddef.h>
#include    <ctype.h>
#include    <time.h>

/* Goddamn HighC won't let me use my nice typedefs... */
static int GeoPrepare(char *, char *, char *);
static int GeoReloc(int, SegDesc *, void *, SegDesc *, int, word *);
static void GeoWrite(void *, int, char *);
static int GeoCheckFixed(SegDesc *);

typedef int (*CmpCallback)(const void *, const void*);

extern	word 	serialNumber;
int	    	isEC = 0;
static char    	*release = "0.0.0.0";
static char    	*protocol = "0.0";
int	    	type;		/* File type (determined by makefile) */
int	    	makeLDF = 0;
Boolean		localizationWanted = FALSE;

#define LOC_PATH "rsc.rsc"

static FileOption geoOpts[] = {
    {'E',    OPT_NOARG,	    (void *)&isEC,  	NULL},
    {'R',    OPT_STRARG,	    (void *)&release,	"release number"},
    {'P',    OPT_STRARG,	    (void *)&protocol,	"protocol number"},
    {'T',    OPT_INTARG,	    (void *)&type,  	"geode type"},
    {'l',    OPT_NOARG,	    (void *)&makeLDF,	NULL},
    {0,	    OPT_NOARG,	    (void *)NULL,   	NULL}
};

FileOps	    geoOps = {
    GeoPrepare,	    /* prepare function */
    4,	    	    /* Runtime relocation size */
    GeoReloc,	    /* Convert runtime relocation */
    GeoWrite, 	    /* Write geo header and the rest of the file. */
    GeoCheckFixed,  /* See if a resource is fixed */
    (SetEntryProc *)0,
    FILE_NEEDPARAM|FILE_USES_GEODE_PARAMS|FILE_AUTO_LINK_LIBS|FILE_PROTO_RELS,
    "geo",  	    /* File suffix */
    geoOpts,	    /* Extra options required */
};

GeodeHeaders   	geoHeader;
int	    	stackSize = PROCESS_DEF_STACK_SIZE; /* Size of stack for
						     * initial thread */
Boolean      stackSpecified = FALSE; /* True if stack size directive found in
				      * .gp file */

static int  	resCount;
static int  	bssStart;	    /* Index of first segment w/in dgroup
				     * of class BSS (uninitialized data) */

typedef struct {
    word    TPD_blockHandle;
    word    TPD_processHandle;
    word    TPD_processSegment;
    word    TPD_threadHandle;
    dword   TPD_classPointer;
    dword   TPD_callVector;
    word    TPD_callTemporary;
    word    TPD_stackBot;   	/* Lowest address in stack */
} ThreadPrivateData;

typedef struct {
    word    TPD_blockHandle;
    word    TPD_processHandle;
    word    TPD_processSegment;
    word    TPD_threadHandle;
    dword   TPD_classPointer;
    dword   TPD_callVector;
    word    TPD_callTemporary;
    word    TPD_vmFile;
    word    TPD_stackBot;   	/* Lowest address in stack */
} ThreadPrivateData1X;

#define TPD_SIZE    64	    /* Size of the thread-private data required at
			     * the base of dgroup if geode is a process */


/***********************************************************************
 *				Geo_DecodeRP
 ***********************************************************************
 * SYNOPSIS:	    Decode a release or protocol number
 * CALLED BY:	    GeoPrepare, KernelPrepare.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    maxNums words at wp are filled with native-order
 *	    	    numbers from the string.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/89	Initial Revision
 *
 ***********************************************************************/
void
Geo_DecodeRP(char   	*num,	    /* Number to decode */
	     int    	maxNums,    /* Max number of components (non-existent
				     * ones are zeroed) */
	     word   	*wp)	    /* Place to store resulting numbers (in
				     * native byte-order) */
{
    char	*cp;	    	/* Pointer into number string */
    int 	n;  	    	/* Accumulator for current component */
    int 	numNums;    	/* Number of components left to go */

    cp = num;

    for (numNums = maxNums; numNums > 0; numNums--) {
	if (isdigit(*cp)) {
	    for (n = 0; *cp != '.' && *cp != '\0'; cp++) {
		n *= 10;
		n += *cp - '0';
	    }
	} else {
	    char    *endp = (char *)index(cp, '.');
	    char    savec;

	    if (endp == NULL) {
		endp = cp + strlen(cp);
	    }
	    savec = *endp;
	    *endp = '\0';
	    if (!Out_FindConstSym(cp, &n)) {
		Notify(NOTIFY_ERROR,
		       "Release/protocol constant \"%s\" not defined -- perhaps defined with '=' instead of 'equ'?",
		       cp);
	    }
	    *endp = savec;
	    cp = endp;
	}

	*wp++ = n;
	if (*cp != '\0') {
	    cp++;
	}
    }

    if (*cp != '\0') {
	Notify(NOTIFY_WARNING,
	       "Too many numbers given for \"%s\" -- only %d supported",
	       num, maxNums);
    }
}

/***********************************************************************
 *				GeoCompareResources
 ***********************************************************************
 * SYNOPSIS:	    Compare two resources for sorting purposes.
 * CALLED BY:	    GeoPrepare via qsort
 * RETURN:	    <0, 0, >0 depending on whether resource 1 should be
 *	    	    before, in the same group, or after resource 2
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *	We want the resources to end up ordered in such a way that the
 *	system can load the resources in efficiently. To this end, we
 *	place resources into four groups and put them in the file in
 *	this order:
 *	    - fixed resources
 *	    - swappable pre-loaded resources
 *	    - non-swappable pre-loaded resources (i.e. init resources)
 *	    - everything else
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/27/92		Initial Revision
 *
 ***********************************************************************/
int
GeoCompareResources(SegDesc **r1, SegDesc **r2)
{
    int	f1, f2;

    if ((*r1)->combine != SEG_LIBRARY && (*r1)->combine != SEG_ABSOLUTE &&
	(*r1)->combine != SEG_GLOBAL)
    {
	f1 = (*r1)->flags;
    } else {
	f1 = RESF_DISCARDED;
    }

    if ((*r2)->combine != SEG_LIBRARY && (*r2)->combine != SEG_ABSOLUTE &&
	(*r2)->combine != SEG_GLOBAL)
    {
	f2 = (*r2)->flags;
    } else {
	f2 = RESF_DISCARDED;
    }

    if (f1 & RESF_FIXED) {
	/* r1 comes before (r2 not fixed) or in the same group (r2 is fixed) */
	return ((f2 & RESF_FIXED) ? 0 : -1);
    } else if (f2 & RESF_FIXED) {
	/* r1 comes after r2 */
	return (1);
    } else if (!(f1 & RESF_DISCARDED)) {
	/* r1 is preloaded */
	if (f1 & RESF_SWAPABLE) {
	    /* r1 not an init resource */
	    return ((f2 & (RESF_DISCARDED|RESF_SWAPABLE)) == RESF_SWAPABLE ?
		    0 : /* r2 also preloaded non-init */
		    -1);/* else r2 comes after */
	} else {
	    /* r1 an init resource.
	     * r2 comes first if it's pre-loaded non-init */

	    if (f2 & RESF_DISCARDED) {
		return(-1);	/* r2 not pre-loaded, so r1 comes first */
	    } else if (f2 & RESF_SWAPABLE) {
		return(1);	/* r2 pre-loaded non-init, so it comes first */
	    } else {
		return(0);
	    }
	}
    } else if (!(f2 & RESF_DISCARDED)) {
	/* r2 is pre-loaded, so it comes before r1, which isn't */
	return(1);
    } else {
	/*
	 * Neither resource is preloaded or fixed, so the order doesn't
	 * matter.
	 */
	return(0);
    }
}

/***********************************************************************
 *				GeoPrepare
 ***********************************************************************
 * SYNOPSIS:	    Prepare the data structures for creating a geode
 * CALLED BY:	    InterPass
 * RETURN:	    The size of the resulting file
 * SIDE EFFECTS:    geoHeader is filled in.
 *
 * STRATEGY:
 *	Make all groups into segments, merging all symbol and line data
 *	into the new segment. The individual segments continue to exist,
 *	but are handled specially (placed in seg_SubSegs) where they can
 *	be found for purposes of figuring where in the executable the
 *	data are to be put, but are otherwise unused.
 *
 *	Parse the parameter file.
 *
 *	Layout the executable:
 *	    size of udata placed in header and udata marked as uninitialized
 *	    	(nodata == true, foff==0)
 *	    if process, 32 bytes left at base of dgroup for TPD, stack
 *	    	size added to udata size.
 *	    space allocated for library export table.
 *	    space allocated for para-aligned and -padded segments with
 *	    	relocations following immediately after.
 *	    space for imported library table
 *	    space for resource position, size and relsize tables.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
GeoPrepare(char	    *outfile,
	   char	    *paramfile,
	   char	    *mapfile)
{
    ID	    	    dgroup, BSS, CODE, udata;
    int	    	    i;
    SegDesc 	    *sd;
    int	    	    resid;
    GroupDesc	    *gd;
    int	    	    cbase;

    bzero(&geoHeader, sizeof(geoHeader));

    /*
     * Initialize core fields of the header.
     */
    if (geosRelease >= 2) {
	struct tm   *tm;
	time_t	    now;

	geoHeader.v2x.execHeader.geosFileHeader.signature[0] = 'G' | 0x80;
	geoHeader.v2x.execHeader.geosFileHeader.signature[1] = 'E';
	geoHeader.v2x.execHeader.geosFileHeader.signature[2] = 'A' | 0x80;
	geoHeader.v2x.execHeader.geosFileHeader.signature[3] = 'S';
	geoHeader.v2x.execHeader.geosFileHeader.type = GFT_EXECUTABLE;
	/*
	 * Fill in creator for all geodes as 'GEOS'
	 */
	geoHeader.v2x.execHeader.geosFileHeader.creator.chars[0] = 'G';
	geoHeader.v2x.execHeader.geosFileHeader.creator.chars[1] = 'E';
	geoHeader.v2x.execHeader.geosFileHeader.creator.chars[2] = 'O';
	geoHeader.v2x.execHeader.geosFileHeader.creator.chars[3] = 'S';
	geoHeader.v2x.execHeader.geosFileHeader.creator.manufID = 0; /* BSW */

	/*
	 * Install the copyright notice.
	 */
	strncpy(geoHeader.v2x.execHeader.geosFileHeader.notice,
		copyright, COPYRIGHT_SIZE);

	/*
	 * Decode protocol and release numbers - they default to 0 if not
	 * given.
	 */
	Geo_DecodeRP(release, 4,
		     (word *)&geoHeader.v2x.execHeader.geosFileHeader.release);

	Geo_DecodeRP(protocol, 2,
		     (word *)&geoHeader.v2x.execHeader.geosFileHeader.protocol);

	/*
	 * Store the current time as the creation stamp.
	 */
	now = time(0);
	tm = localtime(&now);
	geoHeader.v2x.execHeader.geosFileHeader.createdTime =
	    (tm->tm_hour << FT_HOUR_OFFSET) |
		(tm->tm_min << FT_MINUTE_OFFSET) |
		    (tm->tm_sec >> 1);
	geoHeader.v2x.execHeader.geosFileHeader.createdDate =
	    ((tm->tm_year - (FD_BASE_YEAR-1900)) << FD_YEAR_OFFSET) |
		((tm->tm_mon+1) << FD_MONTH_OFFSET) |
		    tm->tm_mday;
	/*
	 * Mark as DBCS if appropriate
	 */
	if (dbcsRelease) {
	    geoHeader.v2x.execHeader.geosFileHeader.flags |= GFHF_DBCS;
	}
    } else {
	geoHeader.v1x.execHeader.geosFileHeader.core.signature[0] = 'G' | 0x80;
	geoHeader.v1x.execHeader.geosFileHeader.core.signature[1] = 'E';
	geoHeader.v1x.execHeader.geosFileHeader.core.signature[2] = 'O' | 0x80;
	geoHeader.v1x.execHeader.geosFileHeader.core.signature[3] = 'S';
	geoHeader.v1x.execHeader.geosFileHeader.core.type = GFT_EXECUTABLE -
	    GFT_RELEASE_1_OFFSET;
	/*
	 * Fill in creator for all geodes as 'GEOS'
	 */
	geoHeader.v1x.execHeader.geosFileHeader.core.creator.chars[0] = 'G';
	geoHeader.v1x.execHeader.geosFileHeader.core.creator.chars[1] = 'E';
	geoHeader.v1x.execHeader.geosFileHeader.core.creator.chars[2] = 'O';
	geoHeader.v1x.execHeader.geosFileHeader.core.creator.chars[3] = 'S';
	geoHeader.v1x.execHeader.geosFileHeader.core.creator.manufID = 0; /* BSW */

	/*
	 * Install the copyright notice.
	 */
	strncpy(geoHeader.v1x.execHeader.geosFileHeader.reserved,
		copyright, COPYRIGHT_SIZE);

	/*
	 * Decode protocol and release numbers - they default to 0 if not
	 * given.
	 */
	Geo_DecodeRP(release, 4,
		     (word *)&geoHeader.v1x.execHeader.geosFileHeader.core.release);

	Geo_DecodeRP(protocol, 2,
		     (word *)&geoHeader.v1x.execHeader.geosFileHeader.core.protocol);

    }


    /*
     * Make sure udata is last segment in dgroup. We do this before promoting
     * any groups to make sure we lay out the file correctly, with the
     * kernel providing zero-filled memory after the initialized data in
     * dgroup.
     */
    dgroup = ST_LookupNoLen(symbols, strings, "dgroup");
    if (dgroup == NullID) {
	Notify(NOTIFY_ERROR, "dgroup not defined -- cannot create geode");
	return(0);
    }
    for (i = 0; i < seg_NumGroups; i++) {
	if (seg_Groups[i]->name == dgroup) {
	    break;
	}
    }
    if (i == seg_NumGroups) {
	Notify(NOTIFY_ERROR, "dgroup not a group -- cannot create geode");
	return(0);
    }
    gd = seg_Groups[i];
    if (gd->numSegs == 0) {
	Notify(NOTIFY_ERROR, "dgroup has no segments in it -- cannot create geode");
	return(0);
    }

    /*
     * Find empty code segments that haven't been added to a group yet
     * and move them into dgroup to make them disappear from the geode.
     */
    CODE = ST_LookupNoLen(symbols, strings, "CODE");
    if(CODE)                    /* No CODE segments at all: don't bother... */
    {
      sd = 0;	                /* Be quiet, GCC */
      for (i = 0; i < seg_NumSegs; i++) {
	  sd = seg_Segments[i];

	  if (sd->size == 0 && sd->group == NULL && sd->class == CODE) {
              char *segName;

              if(sd->name)
              {
                segName = ST_Lock(symbols, sd->name);
                printf("*** Empty segment: %s\n", segName);
                ST_Unlock(symbols, sd->name);
              }
              else
                printf("*** Empty segment: (unnamed)\n");

              Seg_EnterGroupMember(outfile, gd, sd);
	  }
      }
    }

    /*
     * Shift all BSS-class or udata-named segments to the end of dgroup, so
     * we can not include them in the executable file, except as
     * execHeader.udataSize.
     */
    udata = ST_LookupNoLen(symbols, strings, "udata");
    BSS = ST_LookupNoLen(symbols, strings, "BSS");

    bssStart = gd->numSegs;
    for (i = gd->numSegs - 1; i >= 0; i--) {
	if ((udata && gd->segs[i]->name == udata) ||
	    (BSS && gd->segs[i]->class == BSS))
	{
	    SegDesc *tmp;

	    bssStart -= 1;
	    tmp = gd->segs[bssStart];
	    gd->segs[bssStart] = gd->segs[i];
	    gd->segs[i] = tmp;
	}
    }

    /*
     * Promote all groups to be segments, demoting the segments they contain
     * to be subsegments.
     */
    Out_PromoteGroups();

    seg_NumGroups = 0;

    /*
     * Dgroup must be resource #1 (global is resource 0 == the core block)
     */
    sd = 0;			/* Be quiet, GCC */
    for (i = 0; i < seg_NumSegs; i++) {
	sd = seg_Segments[i];

	if (sd->name == dgroup) {
	    break;
	}
    }
    assert(i < seg_NumSegs);

    if (i != 1) {
	SegDesc	*tsd = seg_Segments[1];

	seg_Segments[1] = sd;
	seg_Segments[i] = tsd;
    }

    /*
     * The global segment (aka the core block) must be resource 0.
     */
    if (seg_Segments[0] != globalSeg) {
	for (i = 1; i < seg_NumSegs; i++) {
	    if (seg_Segments[i] == globalSeg) {
		SegDesc *tsd = seg_Segments[0];

		seg_Segments[0] = globalSeg;
		seg_Segments[i] = tsd;
		break;
	    }
	}
	assert(i < seg_NumSegs);
    }

    /*
     * Assign resource IDs to all the non-library segments that are around,
     * setting them by default to be read-only, discarded code segments.
     * Note that resid starts at 0 b/c the global segment takes on the
     * resource ID and persona of the core block.
     */
    for (resid = 0, i = 0; i < seg_NumSegs; i++) {
	if ((seg_Segments[i]->combine != SEG_ABSOLUTE) &&
	    (seg_Segments[i]->combine != SEG_LIBRARY))
	{
	    /*
	     * Give the group the same resource ID so we can continue to
	     * fake out pass2 into thinking the group is a living
	     * entity rather than the puppet we know it to be...
	     */
	    if (seg_Segments[i]->group) {
		seg_Segments[i]->group->pdata.resid = resid;
	    }
	    seg_Segments[i]->pdata.resid = resid++;
	    if (seg_Segments[i]->name == dgroup) {
		seg_Segments[i]->flags = RESF_FIXED;
	    } else if (seg_Segments[i]->combine == SEG_LMEM) {
		if (seg_Segments[i]->isObjSeg) {
		    seg_Segments[i]->flags =
			RESF_SWAPABLE|RESF_DISCARDED|RESF_LMEM|RESF_OBJECT;
		} else {
		    seg_Segments[i]->flags =
			RESF_SWAPABLE|RESF_DISCARDED|RESF_LMEM;
		}
	    } else if (seg_Segments[i]->combine == SEG_GLOBAL) {
		seg_Segments[i]->flags = RESF_FIXED|RESF_READ_ONLY;
	    } else if (seg_Segments[i]->hasProfileMark) {
		seg_Segments[i]->flags =
		    (RESF_STANDARD&~RESF_DISCARDABLE)|RESF_SHARED|RESF_CODE;
	    } else {
		seg_Segments[i]->flags =
		    RESF_STANDARD|RESF_SHARED|RESF_CODE|RESF_READ_ONLY;
	    }
	}
    }

    resCount = resid;

    if (geosRelease >= 2) {
	geoHeader.v2x.resCount =
	    geoHeader.v2x.execHeader.resourceCount = resCount;
    } else {
	geoHeader.v1x.resCount =
	    geoHeader.v1x.execHeader.resourceCount = resCount;
    }

    for (resid = 0, i = 0; i < seg_NumSegs; i++)
    {
	if ((seg_Segments[i]->combine != SEG_ABSOLUTE) &&
	    (seg_Segments[i]->combine != SEG_LIBRARY))
	{
	}
    }

    if (bssStart != sd->group->numSegs) {
	gd = sd->group;

	GHEQ(execHeader.udataSize, (sd->size - gd->segs[bssStart]->grpOff));

	/*
	 * Adjust the size of the dgroup resource to match the beginning of
	 * the udata segment -- this ensures udata gets allocated in the
	 * right place by the kernel.
	 */
	sd->size = gd->segs[bssStart]->grpOff;

	/*
	 * Mark udata as not wanting its data copied out.
	 */
	for (i = bssStart; i < gd->numSegs; i++) {
	    gd->segs[i]->foff = gd->segs[i]->nextOff = 0;
	    gd->segs[i]->nodata = TRUE;
	}
    }

    /*
     * Make sure any subsegments get the resource ID's of their containing
     * group-segments.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	if (seg_Segments[i]->group) {
	    int	    j;

	    gd = seg_Segments[i]->group;
	    for (j = 0; j < gd->numSegs; j++) {
		gd->segs[j]->pdata.resid = seg_Segments[i]->pdata.resid;
	    }
	}
    }

    /*
     * Now read the parameter file to load any libraries and determine
     * other things for the header.
     */
    if (!Parse_GeodeParams(paramfile, outfile, FALSE)) {
	return(0);
    }

    /* we also need to make sure the order of the segments is arranged
     * according to how they are listed in the gp file
     * do a simple n^2 sort (with optimization of j going from i to n)
     * start at i = 2 as 0 = core block and 1 = dgroup
     * note that we only bother doing this if the nosort flag is set
     * (this sound like a misnomer, but what the nosort flag is for is
     * for glue to sort the stuff anyways it pleases for optimizations as
     * opposed to sorting things the way the user specifies in the gp
     * file)
     */
    if (noSort)
    {
    	for(i = 2; i < seg_NumSegs; i++)
	{
	    int j;
	    int myID = seg_Info[i].segID;

	    for (j = 2; j < seg_NumSegs; j++)
	    {
		if (seg_Segments[j]->name == myID)
		{
		    SegDesc	*tsd = seg_Segments[j];

		    seg_Segments[j] = seg_Segments[i];
		    seg_Segments[i] = tsd;
		    break;
		}
	    }
	}
    }

    /*
     * Make sure a type is specified for the geode.
     */
    if ((GH(geodeAttr) & (GA_PROCESS|GA_LIBRARY|GA_DRIVER)) == 0)
    {
	Notify(NOTIFY_ERROR, "Geode type not specified");
	return(0);
    }
    /*
     * Make sure the thing has a token, else GeoManager will hang after
     * launching the thing.
     */
    if (GH(geodeToken.chars[0]) == 0) {
	Notify(NOTIFY_ERROR, "You must provide a token with the tokenChars directive in the .gp file");
	return(0);
    }

    GHEQ(geodeFileType, type);
    GHEQ(execHeader.fileType, type);
    GHEQ(geodeSerial, serialNumber);
    /*
     * If appropriate, sort the resources in this order:
     *	- fixed
     *	- swappable pre-loaded
     *	- non-swappable pre-loaded (i.e. init resources)
     *	- everything else.
     */
    if (geosRelease >= 2 && seg_NumSegs > 2) {
	int fixedUp = 0;
#define FU_CLASS    0x0001
#define FU_LIBENT   0x0002
#define FU_DRIVTAB  0x0004
#define FU_APPOBJ   0x0008

	/* if nosort, then we sorted by the order specified in the gp file */
	if (!noSort)
	{
	    qsort(&seg_Segments[2], seg_NumSegs-2, sizeof(seg_Segments[0]),
	    	  (CmpCallback) GeoCompareResources);
	}
	/*
	 * Wheeeee. Having done that, of course, we now have to adjust the
	 * resource IDs of everything, including various things that are in
	 * the header. Oh joy.
	 */
	for (resid = 0, i = 0; i < seg_NumSegs; i++) {
	    if ((seg_Segments[i]->combine != SEG_ABSOLUTE) &&
		(seg_Segments[i]->combine != SEG_LIBRARY))
	    {
		/*
		 * Just set the group's resid straight out, along with that
		 * of any subsegments.
		 */
		if (seg_Segments[i]->group) {
		    int	j;

		    gd = seg_Segments[i]->group;

		    gd->pdata.resid = resid;
		    for (j = 0; j < gd->numSegs; j++) {
			gd->segs[j]->pdata.resid = resid;
		    }
		}
		if (seg_Segments[i]->pdata.resid != resid) {
		    /*
		     * New resid is different from the old, so adjust anything
		     * referring to this resource in the header.
		     */
		    int	old = seg_Segments[i]->pdata.resid;

		    if (!(fixedUp & FU_CLASS) &&
			(GH(execHeader.classResource) == old))
		    {
			GHEQ(execHeader.classResource, resid);
			fixedUp |= FU_CLASS;
		    }
		    if (!(fixedUp & FU_LIBENT) &&
			(GH(libEntryResource) == old))
		    {
			GHEQ(libEntryResource, resid);
			fixedUp |= FU_LIBENT;
		    }
		    if (!(fixedUp & FU_DRIVTAB) &&
			(GH(driverTabResource) == old))
		    {
			GHEQ(driverTabResource, resid);
			fixedUp |= FU_DRIVTAB;
		    }

		    if (!(fixedUp & FU_APPOBJ) &&
			(GH(execHeader.appObjResource) == old))
		    {
			GHEQ(execHeader.appObjResource, resid);
			fixedUp |= FU_APPOBJ;
		    }
		}
		seg_Segments[i]->pdata.resid = resid++;
	    }
	}
    }

    /*
     * See if any resources are discardable or initially discarded so we can
     * set the KEEP_FILE_OPEN flag properly.
     */
    for (i = 1; i < seg_NumSegs; i++) {
	if ((seg_Segments[i]->combine != SEG_ABSOLUTE) &&
	    (seg_Segments[i]->combine != SEG_LIBRARY))
	{
	   /*
	    * If the application object is run by the first thread, then up the
	    * size of the stack (unless the size has been specified), to match
	    * that done by the UI library itself when it creates UI threads
	    * for multi-threaded apps -- Doug 8/25/92
	    */
	    if ((GH(execHeader.appObjResource) == seg_Segments[i]->pdata.resid)
		&& (!(seg_Segments[i]->flags & RESF_UI)) && !stackSpecified)
	    {
		stackSize = INTERFACE_THREAD_DEF_STACK_SIZE;
	    }

	    if (seg_Segments[i]->flags & (RESF_DISCARDABLE|RESF_DISCARDED))
	    {
	        if (geosRelease >= 2) {
	    	    geoHeader.v2x.geodeAttr |= GA_KEEP_FILE_OPEN;
		    geoHeader.v2x.execHeader.attributes |= GA_KEEP_FILE_OPEN;
		} else {
		    geoHeader.v1x.geodeAttr |= GA_KEEP_FILE_OPEN;
		    geoHeader.v1x.execHeader.attributes |= GA_KEEP_FILE_OPEN;
		}
	    }
	}
	/*
	 * Pass the allocation flags on to the old group descriptor too.
	 */
	if (seg_Segments[i]->group) {
	    seg_Segments[i]->group->flags = seg_Segments[i]->flags;
	}
    }


    /*
     * Complain if the library entry point, process class, or driver table
     * is in dgroup, and the user wants a discardable dgroup
     */
    if (discardableDgroup) {
	if (GH(execHeader.classResource) == 1) {
	    Notify(NOTIFY_ERROR, "process class is in dgroup\n");
	    Notify(NOTIFY_ERROR, "geode cannot have a discardable dgroup\n");
	}
	if (GH(libEntryResource) == 1) {
	    Notify(NOTIFY_ERROR, "library entry point is in dgroup\n");
	    Notify(NOTIFY_ERROR, "geode cannot have a discardable dgroup\n");
	}
	if (GH(driverTabResource) == 1) {
	    Notify(NOTIFY_ERROR, "DriverTable is in dgroup\n");
	    Notify(NOTIFY_ERROR, "geode cannot have a discardable dgroup\n");
	}
	if (errors) {
	    return(0);
	}
    }
    /*
     * Deal with size of process stack and the thread-private data that
     * must go at the base of dgroup.
     */
    if (GH(geodeAttr) & GA_PROCESS) {
	Out_ExtraReloc(seg_Segments[1], TPD_SIZE);
	/*
	 * Deal with header fields that could be in dgroup. We can ignore
	 * the application object, as dgroup cannot possibly be an object
	 * resource.
	 */
	if (GH(execHeader.classResource) == 1) {
	    if (geosRelease >= 2) {
		geoHeader.v2x.execHeader.classOffset += TPD_SIZE;
	    } else {
		geoHeader.v1x.execHeader.classOffset += TPD_SIZE;
	    }
	}
	if (GH(libEntryResource) == 1) {
	    if (geosRelease >= 2) {
		geoHeader.v2x.libEntryOff += TPD_SIZE;
	    } else {
		geoHeader.v1x.libEntryOff += TPD_SIZE;
	    }
	}
	if (GH(driverTabResource) == 1) {
	    if (geosRelease >= 2) {
		geoHeader.v2x.driverTabOff += TPD_SIZE;
	    } else {
		geoHeader.v1x.driverTabOff += TPD_SIZE;
	    }
	}

	seg_Segments[1]->size += TPD_SIZE;
	if (geosRelease >= 2) {
	    geoHeader.v2x.execHeader.udataSize += stackSize;
	} else {
	    geoHeader.v1x.execHeader.udataSize += stackSize;
	}
	/*
	 * Adjust grpOff's for all segments in dgroup to account for TPD.
	 */
	gd = seg_Segments[1]->group;
	for (i = 0; i < gd->numSegs; i++) {
	    gd->segs[i]->grpOff += TPD_SIZE;
	}
	/*
	 * Warn the user if there's no defined class for the initial thread.
	 */
	if (GH(execHeader.classResource) == 0) {
	    Notify(NOTIFY_WARNING, "class for initial thread not defined");
	}
    }

    /*
     * Copy the release and protocol numbers into the geodeHeaderStruc
     * for use by the kernel.
     */
    if (geosRelease >= 2) {
	geoHeader.v2x.geodeRelease =
	    geoHeader.v2x.execHeader.geosFileHeader.release;
	geoHeader.v2x.geodeProtocol =
	    geoHeader.v2x.execHeader.geosFileHeader.protocol;
    } else {
	geoHeader.v1x.geodeRelease =
	    geoHeader.v1x.execHeader.geosFileHeader.core.release;
	geoHeader.v1x.geodeProtocol =
	    geoHeader.v1x.execHeader.geosFileHeader.core.protocol;
    }

    if (GH(geodeAttr) & GA_DRIVER) {
	/*
	 * Locate the DriverTable variable for the header.
	 */
	Parse_FindSym("DriverTable", OSYM_VAR, "variable",
		      GHA(driverTabResource),
		      GHA(driverTabOff));
	if (discardableDgroup) {
	    if (GH(driverTabResource) == 1) {
		Notify(NOTIFY_ERROR, "DriverTable is in dgroup\n");
		Notify(NOTIFY_ERROR, "geode cannot have a discardable dgroup\n");
	    }
	}
    }

    GHEQ(libCount, numImport);
    GHEQ(execHeader.importLibraryCount, numImport);
#if 0	/* We allow this now to let a library indicate it doesn't need
	 * notification. The kernel handles it properly */
    if ((GH(geodeAttr) & GA_LIBRARY) && (GH(libEntryResource) == 0))
    {
	Notify(NOTIFY_ERROR,
	       "entry point not given for library; use \"entry\" command in %s",
	       paramfile);
	return(0);
    }
#endif

    /*
     * Record number of exported entry points.
     */
    GHEQ(exportEntryCount, numEPs);
    GHEQ(execHeader.exportEntryCount, numEPs);

    /*
     * Fetch out the kernel's protocol number and store it in the header.
     */
    for (i = 0; i < numLibs; i++) {
	if (libs[i].lnum == IS_KERNEL) {
	    bcopy(&libs[i].entry.protocol,
		  &geoHeader.v1x.execHeader.kernelProtocol,
		  sizeof(ProtocolNumber));
	    break;
	}
    }
#if 0	/* no longer appropriate, as 2.0 doesn't need this field */
    if (i == numLibs) {
	Notify(NOTIFY_ERROR,
	       "cannot find kernel to get its protocol number");
	return(0);
    }
#endif

    /*
     * Reserve space for the header, the table of imported libraries,
     * the exported entry table, and the info for the resources
     * (four bytes for code position, two for code size, two for
     * relocation table size, two for allocation flags)
     */
    cbase = (geosRelease >= 2 ? sizeof(geoHeader.v2x) : sizeof(geoHeader.v1x)) +
	(numImport*sizeof(ImportedLibraryEntry)) +
	    (numEPs * 2 * sizeof(word)) +
		(resCount * 10);

    /*
     * Assign file locations for all the segments and their relocations.
     * Any segment that is of zero size we make be 16 bytes (a paragraph)
     * instead so the kernel won't choke.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	if ((seg_Segments[i]->combine != SEG_ABSOLUTE) &&
	    (seg_Segments[i]->combine != SEG_LIBRARY))
	{
	    SegDesc *sd = seg_Segments[i];

	    /*
	     * Code goes at current position -- no alignment garbage needed
	     * at the start of the segment.
	     */
	    sd->foff = sd->nextOff = cbase;
	    sd->nodata = FALSE;
	    if (sd->group) {
		sd->group->foff = cbase;
	    }
	    /*
	     * Make sure resource non-zero length and padded to paragraph
	     * boundary.
	     */
	    if ((sd->size == 0) && (sd->pdata.resid != 0)) {
		sd->size = 16;
	    }
	    /*
	     * Make sure dgroup is padded to a paragraph boundary, as things
	     * that load it insist on this.
	     */
	    if (sd->pdata.resid == 1) {
		sd->size += 0xf;
		sd->size &= ~0xf;
	    } else if (sd->size > 65536-16) {
		Notify(NOTIFY_ERROR,
			"%i may not be larger than 65,520 bytes (%d bytes now)",
			sd->name, sd->size);
		return(0);
	    }

	    /*
	     * Relocations follow after size padded to paragraph boundary.
	     */
	    cbase += (sd->size + 0xf) & ~0xf;
	    sd->roff = cbase;
	    /*
	     * Each relocation takes four bytes, so advance cbase accordingly
	     */
	    cbase += sd->nrel * 4;
	}
    }

    /*
     * Using those file assignments, provide the same for any subsegments.
     */
    for (i = 0; i < seg_NumSubSegs; i++) {
	SegDesc	    *sd = seg_SubSegs[i];
	int 	    j;

	/*
	 * Subsegments inherit their resource allocation flags from their
	 * groups, which in turn inherited theirs from the promoted segment
	 */
	sd->flags = sd->group->flags;

	if (!sd->nodata) {
	    for (j = 0; j < seg_NumSegs; j++) {
		if ((seg_Segments[j]->name == sd->group->name) &&
		    (seg_Segments[j]->class ==  NullID))
		{
		    sd->foff = sd->nextOff = seg_Segments[j]->foff+sd->grpOff;
		    sd->roff += seg_Segments[j]->roff;
		    break;
		}
	    }
	}
    }

    if (mapfile) {
	FILE 	*localizationFile=NULL;
	int	totalSize;
	int	fixedSize=0;
#if 0
	Out_DosMap(mapfile,
		   sizeof(geoHeader) +
		   (numImport*sizeof(ImportedLibraryEntry)) +
		   (geoHeader.resCount * 10));
#endif
	printf("Resource                          Size   # Relocs\n");
	printf("-------------------------------------------------\n");
	totalSize = 0;

	if (localizationWanted) {
	    if (ldfOutputDir) {
		char	*cp, *cp2, *localizationFileName;
		localizationFileName = malloc((strlen(ldfOutputDir)+
					       	1+strlen(LOC_PATH)+1));
	    	for (cp2 = localizationFileName, cp = ldfOutputDir ;
		     	    	    	 *cp != 0 ; cp++)
	    	{
		    *cp2++ = *cp;
		}
	    	*cp2++ = '/';
	    	strcpy(cp2, LOC_PATH);
		localizationFile = fopen(localizationFileName,"wt");
		free(localizationFileName);
	    } else {
		localizationFile = fopen(LOC_PATH,"wt");
	    }
	    if (localizationFile == NULL){
		perror("fopen");
	    } else {
		fputs("resource coreblock 0\n", localizationFile);
	    }
	}
	for (i = 0; i < seg_NumSegs; i++) {
	    SegDesc *sd = seg_Segments[i];

	    if (sd->name == NullID) {
		printf("CoreBlock                            0        0\n");
	    } else if ((sd->combine != SEG_ABSOLUTE) &&
		       (sd->combine != SEG_LIBRARY))
	    {
		if (sd->flags & RESF_FIXED) {
		    fixedSize += sd->size;
		}
		printf("%-33.32li%5d    %5d\n", sd->name, sd->size, sd->nrel);
		if (sd->size > 10000) {
		    printf("Warning: %i is very large, that is a BAD thing.\n"
			   ,sd->name);
		}
		if (localizationFile) {
		    fprintf(localizationFile,"resource %i %d\n",sd->name,
			    sd->pdata.resid);
		}
		totalSize += sd->size;
	    }
	}
	if(localizationFile){
	    if (dbcsRelease) {
		fprintf(localizationFile, "GeodeLongName \"");
		for (i = 0; i < GFH_LONGNAME_SIZE; i += 2) {
		    char c;
		    c = geoHeader.v2x.execHeader.geosFileHeader.longName[i];
		    if (c) {
		    	fprintf(localizationFile, "%c", c);
		    } else {
			break;
		    }
		}
		fprintf(localizationFile, "\"\n");
	    } else {
	    	fprintf(localizationFile,"GeodeLongName \"%s\"\n",
			geoHeader.v2x.execHeader.geosFileHeader.longName);
	    }
	    fprintf(localizationFile,"Protocol %d %d\n",
		    geoHeader.v2x.execHeader.geosFileHeader.protocol.major,
		    geoHeader.v2x.execHeader.geosFileHeader.protocol.minor);
	    fclose(localizationFile);
	}


	printf("\n");
	printf("Total size: %d byte%s	    Fixed size: %d byte%s\n",
	       	    totalSize,
		    (totalSize == 1 ? "" : "s"), fixedSize,
		    (fixedSize == 1 ? "" : "s"));
	if (fixedSize > 1024) {
	    printf("Warning: Fixed size should be reduced by moving things into movable resources\n");
	}
	printf("Uninitialized data/stack: %d byte%s\n\n",
	       GH(execHeader.udataSize),
	       GH(execHeader.udataSize) == 1 ? "" : "s");


	fflush(stdout);
    }

    return(cbase);
}


/***********************************************************************
 *				GeoReloc
 ***********************************************************************
 * SYNOPSIS:	    Enter another runtime relocation
 * CALLED BY:	    Pass2_Load
 * RETURN:	    Non-zero if runtime-relocation actually entered.
 * SIDE EFFECTS:    Maybe.
 *
 * STRATEGY:
 *	For OREL_CALL, the routine number (if library) or offset (if in
 *	geode) is stored at *val.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static int
GeoReloc(int      type,	    /* Relocation type (from obj file) */
	 SegDesc  *frame,   /* Descriptor of relocation frame */
	 void     *rbuf,    /* Place to store runtime relocation */
	 SegDesc  *targ,    /* Target segment */
	 int      off,	    /* Offset w/in segment of relocation */
	 word     *val)     /* Word being relocated. Store
			     * value needed at runtime in
			     * PC byte-order */
{
    byte    	*bp = (byte *)val;
    byte    	info;
    byte    	extra = 0;
    Library 	*lib = 0;	/* Be quiet, GCC */

    info = 0;

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

    assert(frame->type != S_GROUP);

    /*
     * If relocation to a library, fetch the library descriptor pointer and
     * make sure it exists. If it's still NULL, the library wasn't linked in
     * and we declare an error. We also set up 'info' and 'extra' properly
     * based on the library number as most of the things below require this if
     * the segment is a library.
     */
    if (frame->combine == SEG_LIBRARY) {
	char    *cp;

	lib = &libs[frame->pdata.library];

	cp = ST_Lock(symbols, frame->name);
	if (strncmp(cp, lib->entry.name, strlen(cp))) {
	    Pass2_RelocError(targ,off,"driver %i not linked in", frame->name);
	    ST_Unlock(symbols, frame->name);
	    return(0);
	}
	ST_Unlock(symbols, frame->name);

	if (lib == NULL) {
	    Pass2_RelocError(targ,off,"library %i not linked in", frame->name);
	    return(0);
	} else if (lib->lnum == IS_KERNEL) {
	    info = GRS_KERNEL << 4;
	} else if (lib->lnum == NO_LOAD) {
	    Pass2_RelocError(targ,off,
			     "Cannot have relocations to unloaded library %i",
			     frame->name);
	    return(0);
	} else {
	    info = GRS_LIBRARY << 4;
	    /*
	     * Extra info required is the library number.
	     */
	    extra = lib->lnum;
	}
    }

    switch(type) {
	case OREL_RESID:
	{
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

	    if (frame->combine == SEG_ABSOLUTE) {
		Pass2_RelocError(targ,off,
		       "cannot get resource ID of %i -- not part of geode",
		       frame->name);
		return(0);
	    }
	    w = (*bp | (bp[1] << 8));
	    if (frame->combine == SEG_LIBRARY) {
		if (lib->lnum == IS_KERNEL) {
		    Pass2_RelocError(targ,off,
			   "Cannot apply RESID to the kernel");
		    return(0);
		} else if (lib->lnum == NO_LOAD) {
		    Pass2_RelocError(targ,off,
			   "Cannot have relocations to unloaded library %i",
			   frame->name);
		    return(0);
		} else {
		    /*
		     * Add in the library number
		     */
		    w += lib->lnum;
		}
	    } else {
		/*
		 * Add in the resource ID
		 */
		w += frame->pdata.resid;
	    }

	    *bp++ = w;
	    *bp = w >> 8;
	    return(0);
	}
	case OREL_HANDLE:
	    if (frame->combine == SEG_ABSOLUTE) {
		Pass2_RelocError(targ,off,
		       "cannot get handle of absolute segment %i -- it has none",
		       frame->name);
		return(0);
	    }
	    /*FALLTHRU*/
	case OREL_SEGMENT:
	{
	    if (((bp[0] | (bp[1]<<8)) == 0xffff) &&
		(frame->combine == SEG_GLOBAL)) {
		/*
		 * If the resid is 0xffff and the relocation is for the
		 * global segment, then it's a relocation for the last
		 * handle in the XIP segment.
		 */
		info |= (GRT_LAST_XIP_HANDLE | (GRS_RESOURCE << 4));
	    } else {
		/*
		 * Similar reasons for adding the resource ID/library number
		 * in as for RESID...
		 */
		info |= (type == OREL_HANDLE ? GRT_HANDLE : GRT_SEGMENT);

		/*
		 * Now work up a relocation for the kernel.
		 */
		if (frame->combine != SEG_LIBRARY) {
		    /*
		     * If the user has specified that he wants a discardable
		     * dgroup, complain if we encountered a segment relocation
		     * to dgroup.
		     */
		    if ((frame->combine != SEG_ABSOLUTE) &&
			(type == OREL_SEGMENT) &&
			(frame->pdata.resid == 1) &&
			discardableDgroup) {
			Pass2_RelocError(targ, off,
				 "segment relocation to dgroup encountered");
			Pass2_RelocError(targ, off,
				 "geode cannot have a discardable dgroup");
		    }
		    info |= GRS_RESOURCE << 4;
		    /*
		     * Store the resource ID in the word.
		     */
		    *bp++ = frame->pdata.resid;
		    *bp = frame->pdata.resid >> 8;
		    if (((frame->flags & (RESF_SHARED|RESF_READ_ONLY)) !=
			 (RESF_SHARED|RESF_READ_ONLY)) &&
			(targ->flags & RESF_READ_ONLY) &&
			(GH(geodeAttr) & GA_MULTI_LAUNCHABLE))
		    {
			if (mapSharableRelocations) {
			    /*
			     * Map relocation to resource ID -- resource ID is
			     * already stored, we just have an extra relocation
			     * do deal with
			     */
			    return(0);
			} else {
			    Pass2_RelocError(targ,off,
			     "%s relocation from shared/read-only to "
			     "unshared/writable segment %i",
			     type == OREL_HANDLE ? "handle" : "segment",
			     frame->name);
			    Pass2_RelocError(targ,off,
				     "geode cannot be multi-launchable");
#if 0
    /* Leave "multi-launchable" so all cases can be flagged */
			GH(geodeAttr) &= ~GA_MULTI_LAUNCHABLE;
			GH(execHeader.attributes) &= ~GA_MULTI_LAUNCHABLE;
#endif
			}
		    }
		} else if (lib->lnum == NO_LOAD_FIXED) {
		    /*
		     * Reduce expected # of relocations for this segment by 1,
		     * since we now know we don't need it.
		     */
		    printf("%i, %i\n", targ->name, frame->name);
		    if (targ->type == S_SUBSEGMENT) {
			Seg_FindPromotedGroup(targ)->nrel--;
		    }
		    targ->nrel--;
		    return(0);
		}
	    }
	    break;
	}
	case OREL_CALL:

	    /*
	     * Leave the offset portion alone.
	     */
	    bp += 2;

	    /*
	     * Now work up a relocation for the kernel.
	     */
	    if (frame->combine == SEG_LIBRARY) {
		if (lib->lnum >= 0) {
		    /*
		     * Calls to loaded libraries are actual GRT_CALL
		     * relocations.
		     */
		    info |= GRT_CALL;
		} else if (lib->lnum == NO_LOAD_FIXED) {
		    /*
		     * Reduce expected # of relocations for this segment by 1,
		     * since we now know we don't need it.
		     */
		    printf("%i, %i\n", targ->name, frame->name);
		    if (targ->type == S_SUBSEGMENT) {
			Seg_FindPromotedGroup(targ)->nrel--;
		    }
		    targ->nrel--;
		    return(0);
		} else {
		    /*
		     * Calls to the kernel, however, are GRT_FAR_PTR's
		     */
		    info |= GRT_FAR_PTR;
		}
		/*
		 * Zero out the segment portion so we get consistent results
		 * when we're comparing geodes to see if an install has messed
		 * with things it shouldn't have -- ardeb 9/15/94
		 */
		*bp++ = 0;
		*bp = 0;
	    } else {
		/*
		 * If the user has specified that he wants a discardable
		 * dgroup, complain if we encountered a segment relocation
		 * to dgroup.
		 */
		if ((frame->combine != SEG_ABSOLUTE) &&
		    (frame->pdata.resid == 1) &&
		    discardableDgroup) {
		    Pass2_RelocError(targ, off,
			     "call relocation to dgroup encountered");
		    Pass2_RelocError(targ, off,
			     "geode cannot have a discardable dgroup");
		}

		if (((frame->flags & (RESF_SHARED|RESF_READ_ONLY)) !=
		     (RESF_SHARED|RESF_READ_ONLY)) &&
		    (targ->flags & RESF_READ_ONLY) &&
		    (GH(geodeAttr) & GA_MULTI_LAUNCHABLE))
		{
		    Pass2_RelocError(targ,off,
			"call relocation from shared/read-only to unshared/writable segment %i",
			frame->name);
		    Pass2_RelocError(targ,off,
				    "geode cannot be multi-launchable");
#if 0
/* Leave "multi-launchable" so all cases can be flagged */
		    GH(geodeAttr) &= ~GA_MULTI_LAUNCHABLE;
		    GH(execHeader.attributes) &= ~GA_MULTI_LAUNCHABLE;
#endif
		}

		if (frame->flags & RESF_FIXED) {
		    /*
		     * Call to a fixed module. Do *not* generate a CALL
		     * relocation -- generate a SEGMENT relocation instead
		     */
		    info |= GRT_SEGMENT;
		    off += 2;
		} else {
		    /*
		     * Call to a movable module. The offset must go in
		     * the segment portion of the 5-byte area, while the
		     * resource ID goes in offset portion.
		     */
		    *bp = bp[-2]; bp[1] = bp[-1];	/* Copy offset */
		    bp -= 2;	/* Point to storage for resid */
		    info |= GRT_CALL;
		}
		/*
		 * Store the resource ID in the segment portion.
		 */
		*bp++ = frame->pdata.resid;
		*bp = frame->pdata.resid >> 8;

		info |= GRS_RESOURCE << 4;
	    }
	    break;
	case OREL_OFFSET:
	    /*
	     * Must be for a library or the kernel.
	     */
	    info |= GRT_OFFSET;

	    /*
	     * Now work up a relocation for the kernel -- all the data
	     * have been figured out up above. This is only valid for
	     * libraries or the kernel.
	     */
	    assert(frame->combine == SEG_LIBRARY);

	    if (lib->lnum == NO_LOAD_FIXED) {
		/*
		 * Reduce expected # of relocations for this segment by 1,
		 * since we now know we don't need it.
		 */
		printf("%i, %i\n", targ->name, frame->name);
		if (targ->type == S_SUBSEGMENT) {
		    Seg_FindPromotedGroup(targ)->nrel--;
		}
		targ->nrel--;
		return(0);
	    }
	    break;
	default:
	    assert(0);
    }

    /*
     * Store the relocation information in the relocation buffer, then
     * return an indication that we did this...
     */
    off += targ->nextOff - targ->foff + targ->grpOff;

    bp = (byte *)rbuf;
    *bp++ = info;
    *bp++ = extra;
    *bp++ = off;
    *bp = off >> 8;

    return(1);
}


/***********************************************************************
 *				GeoSwapArea
 ***********************************************************************
 * SYNOPSIS:	    Swap an area of shortwords.
 * CALLED BY:	    GeoWrite
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
#if defined(DOSWAP)
static inline void
GeoSwapArea(word    *s,	    /* Start of area to swap */
	    int      i)	    /* Number of bytes to swap */
{
   while (i > 0) {
      swapsp(s);
      s++;
      i -= 2;
   }
}
#else
# define GeoSwapArea(s,i)
#endif

/***********************************************************************
 *				GeoWrite
 ***********************************************************************
 * SYNOPSIS:	    Finish with the header and flush all data to disk
 * CALLED BY:	    Out_Final
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	Byte-swap the header
 *	Build out imported library table and send it to the output buffer
 *	Build out resource code, relocation and relocation size tables
 *	    and send them to the output buffer.
 *	Open the output file
 *	Write the entire buffer to it at once.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static void
GeoWrite(void	    *base,  	/* Base of file buffer */
	 int	    len,    	/* Length of same */
	 char	    *outfile)	/* Name of output file */
{
    VMBlockHandle   	map;
    ObjHeader	    	*hdr;  	    /* Header for symbol file for setting
				     * release and protocol */
    byte    	    	*rtable;    /* Table for resources */
    ImportedLibraryEntry *ltable;
    int	    	    	i;  	    /* General index */
    int	    	    	j;
    byte    	    	stackBot[2];/* Word buffer for setting TPD_stackBot
				     * if the geode is a process */
    SegDesc		*sd;	    /* General segment descriptor */
    long    	    	curOff;

    /*
     * Copy the protocol and release numbers to the .sym file for Swat.
     */
    map = VMGetMapBlock(symbols);
    hdr = (ObjHeader *)VMLock(symbols, map, (MemHandle *)NULL);

    bcopy(GHA(geodeRelease), &hdr->rev, sizeof(hdr->rev));
    bcopy(GHA(geodeProtocol), &hdr->proto, sizeof(hdr->proto));

    VMUnlockDirty(symbols, map);

    /*
     * Deal with paragraph-padding of idata and possible overlap with
     * udata. If dgroup isn't filled out (nextOff-foff doesn't match
     * the size), put out enough zero bytes to make up the difference.
     * Note that the nextOff field for the promoted group doesn't actually
     * get updated, as nothing goes into dgroup. Instead, we want to look
     * at the last segment before udata (which is the last subsegment listed
     * in the segs array of the group descriptor from which the dgroup
     * SegDesc came). We're careful to handle the pathological case of having
     * no udata, however...I think.
     */
    if (seg_Segments[1]->group->numSegs != 1) {
	sd = seg_Segments[1]->group->segs[bssStart-1];
    } else {
        sd = seg_Segments[1]->group->segs[0];
    }

    if (sd->nextOff - seg_Segments[1]->foff != seg_Segments[1]->size) {
        int  pad = seg_Segments[1]->size - (sd->nextOff-seg_Segments[1]->foff);
        byte *zeroes;

	zeroes = (byte *)calloc(pad, 1);
	Out_Block(sd->nextOff, (void *)zeroes, pad);
	free((char *)zeroes);

	/*
	 * The first part of udata was absorbed into idata, so don't
	 * tell the kernel to include it in its allocation...
	 */
	if (pad <= GH(execHeader.udataSize)) {
	    if (geosRelease >= 2) {
		geoHeader.v2x.execHeader.udataSize -= pad;
	    } else {
		geoHeader.v1x.execHeader.udataSize -= pad;
	    }
	} else {
	    GHEQ(execHeader.udataSize, 0);
	}
    }

    if (GH(geodeAttr) & GA_PROCESS) {
	/*
	 * Deal with setup of TPD_stackBot for the kernel. The bottom of the
	 * stack lies at the end of udata. Of course, we've added the stack
	 * size into udata at this point and adjusted the size of dgroup to
	 * the start of udata, so we need to take that into account.
	 */
	word	sb = seg_Segments[1]->size +
	    (GH(execHeader.udataSize) - stackSize);

	stackBot[0] = sb;
	stackBot[1] = sb >> 8;

	Out_Block(seg_Segments[1]->foff +
		  (geosRelease >= 2 ?
		   offsetof(ThreadPrivateData,TPD_stackBot) :
		   offsetof(ThreadPrivateData1X,TPD_stackBot)),
		  (void *)stackBot, sizeof(stackBot));
    }

    /*
     * Byte-swap the header and send it to the output buffer. Easiest to swap
     * the whole thing and then unswap the character portions.
     */
    GeoSwapArea((word *) &geoHeader, sizeof(geoHeader));
    if (geosRelease >= 2) {
	GeoSwapArea((word *)geoHeader.v2x.execHeader.geosFileHeader.signature,
		    sizeof(geoHeader.v2x.execHeader.geosFileHeader.signature));
	GeoSwapArea((word *)geoHeader.v2x.geodeName,
		    sizeof(geoHeader.v2x.geodeName));
	GeoSwapArea((word *)geoHeader.v2x.geodeNameExt,
		    sizeof(geoHeader.v2x.geodeNameExt));
	GeoSwapArea((word *)geoHeader.v2x.geodeToken.chars,
		    sizeof(geoHeader.v2x.geodeToken.chars));
	GeoSwapArea((word *)geoHeader.v2x.execHeader.geosFileHeader.token.chars,
		    sizeof(geoHeader.v2x.execHeader.geosFileHeader.token.chars));
	GeoSwapArea((word *)geoHeader.v2x.execHeader.geosFileHeader.creator.chars,
		    sizeof(geoHeader.v2x.execHeader.geosFileHeader.creator.chars));
	GeoSwapArea((word *)geoHeader.v2x.execHeader.geosFileHeader.longName,
		    sizeof(geoHeader.v2x.execHeader.geosFileHeader.longName));
	GeoSwapArea((word *)geoHeader.v2x.execHeader.geosFileHeader.userNotes,
		    sizeof(geoHeader.v2x.execHeader.geosFileHeader.userNotes));
	GeoSwapArea((word *)geoHeader.v2x.execHeader.geosFileHeader.notice,
		    sizeof(geoHeader.v2x.execHeader.geosFileHeader.notice));
	Out_Block(0, (void *)&geoHeader.v2x, sizeof(geoHeader.v2x));
	curOff = sizeof(geoHeader.v2x);
    } else {
	GeoSwapArea((word *)geoHeader.v1x.execHeader.geosFileHeader.core.signature,
		    sizeof(geoHeader.v1x.execHeader.geosFileHeader.core.signature));
	GeoSwapArea((word *)geoHeader.v1x.geodeName,
		    sizeof(geoHeader.v1x.geodeName));
	GeoSwapArea((word *)geoHeader.v1x.geodeNameExt,
		    sizeof(geoHeader.v1x.geodeNameExt));
	GeoSwapArea((word *)geoHeader.v1x.geodeToken.chars,
		    sizeof(geoHeader.v1x.geodeToken.chars));
	GeoSwapArea((word *)geoHeader.v1x.execHeader.geosFileHeader.core.token.chars,
		    sizeof(geoHeader.v1x.execHeader.geosFileHeader.core.token.chars));
	GeoSwapArea((word *)geoHeader.v1x.execHeader.geosFileHeader.core.creator.chars,
		    sizeof(geoHeader.v1x.execHeader.geosFileHeader.core.creator.chars));
	GeoSwapArea((word *)geoHeader.v1x.execHeader.geosFileHeader.core.longName,
		    sizeof(geoHeader.v1x.execHeader.geosFileHeader.core.longName));
	GeoSwapArea((word *)geoHeader.v1x.execHeader.geosFileHeader.userNotes,
		    sizeof(geoHeader.v1x.execHeader.geosFileHeader.userNotes));
	GeoSwapArea((word *)geoHeader.v1x.execHeader.geosFileHeader.reserved,
		    sizeof(geoHeader.v1x.execHeader.geosFileHeader.reserved));
	Out_Block(0, (void *)&geoHeader.v1x, sizeof(geoHeader.v1x));
	curOff = sizeof(geoHeader.v1x);
    }

    /*
     * Now put together the imported library table.
     */
    if (numImport != 0) {
	ltable = (ImportedLibraryEntry *)malloc(numImport*
						sizeof(ImportedLibraryEntry));

	for (j = i = 0; i < numLibs; i++) {
	    if (libs[i].lnum >= 0) {
		ltable[j] = libs[i].entry;
		/*
		 * Swap the protocol
		 */
		GeoSwapArea((word *)&ltable[j].protocol,
			    sizeof(ltable[j].protocol));
		j++;
	    }
	}

	Out_Block(curOff, (void *)ltable,
		  numImport * sizeof(ImportedLibraryEntry));

	curOff += numImport * sizeof(ImportedLibraryEntry);
	free((void *)ltable);
    }

    /*
     * Build out and write the exported library entry table. Each entry
     * is two words with the low word containing the offset and the high
     * the resource number.
     */
    if (numEPs) {
    	word   	    	*table = (word *)malloc(numEPs * 2 * sizeof(word));
	ObjHeader   	*hdr;
	VMBlockHandle	map;

	/*
	 * Lock down the header for the symbol file so we can determine the
	 * resource ID's of these symbols easily.
	 */
	map = VMGetMapBlock(symbols);
	hdr = (ObjHeader *)VMLock(symbols, map, (MemHandle *)NULL);

	for (i = 0; i < numEPs; i++) {
	    ObjSym  	*sym;

	    if (entryPoints[i].block == 0) {
		/*
		 * Let kernel know the slot is empty.
		 */
		table[2*i] = table[(2*i)+1] = 0;
	    } else {
		/*
		 * Library module already checked symbol type and located the
		 * thing, so we can just lock it down and fetch its address
		 * out.
		 */
		ObjSymHeader	*osh;
		ObjSegment    	*s;
		int 	    	resid;

		osh = (ObjSymHeader *)VMLock(symbols, entryPoints[i].block,
					     (MemHandle *)NULL);
		/*
		 * Calculate the resource ID of the segment since we haven't
		 * arranged things in the header conveniently (though this
		 * might be a good idea...).
		 */
		for (resid = 0, s = (ObjSegment *)(hdr+1);
		     ((genptr)s-(genptr)hdr) != osh->seg;
		     s++)
		{
		    if ((s->type != SEG_ABSOLUTE) && (s->type != SEG_LIBRARY)){
			resid++;
		    }
		}

		sym = (ObjSym *)((genptr)osh + entryPoints[i].offset);

		/*
		 * If we want a discardable dgroup, don't allow the geode to
		 * have any exported entry points in dgroup.
		 */
		if  (discardableDgroup && (resid == 1)) {
		    	Notify(NOTIFY_ERROR,
			       "entry point #%d is in dgroup\n", i);
			Notify(NOTIFY_ERROR,
			       "geode cannot have a discardable dgroup");
		}
		table[2*i] = swaps(sym->u.addrSym.address);
		table[(2*i)+1] = swaps(resid);

		VMUnlock(symbols, entryPoints[i].block);
	    }
	}

	VMUnlock(symbols, map);

	/*
	 * Send the segment to the output buffer.
	 */
	Out_Block(curOff, (void *)table, numEPs * 2 * sizeof(word));
	curOff += numEPs * 2 * sizeof(word);

	free((char *)table);
    }
    /*
     * If there was an error creating the exported entry table, exit now,
     * instead of continuing to generate the .geo file
     */
    if (errors) {
	return;
    }

    /*
     * Build out the resource descriptor table. This thing comes in
     * four pieces:
     *	    an array of words containing the sizes of the modules
     *	    an array of dwords containing the file positions of the modules
     *	    an array of words containing the sizes of the relocation tables
     *	    an array of words containing the allocation flags
     *
     * For V2.X, the file positions have the size of the GeosFileHeader2
     * subtracted from the positions we originally calculated, as the kernel
     * isn't allowed to see the file header.
     */
    rtable = (byte *)malloc(resCount * 10);

    for (i = 0; i < seg_NumSegs; i++) {
	sd = seg_Segments[i];

	if ((sd->combine != SEG_ABSOLUTE) && (sd->combine != SEG_LIBRARY))
	{
	    byte    *bp;
	    dword   off;

	    j = sd->pdata.resid;

	    /*
	     * First the module size.
	     */
	    bp = rtable+(2*j);
	    *bp++ = sd->size;
	    *bp = sd->size >> 8;

	    /*
	     * Now the file position.
	     */
	    bp = rtable+(2*resCount)+(4*j);
	    off = sd->foff;
	    if (geosRelease >= 2) {
		off -= sizeof(GeosFileHeader2);
	    }
	    *bp++ = off; off >>= 8;
	    *bp++ = off; off >>= 8;
	    *bp++ = off; off >>= 8;
	    *bp = off;

	    /*
	     * Now the relocation table size.
	     */
	    bp = rtable+((2+4)*resCount)+(2*j);
	    *bp++ = sd->nrel*4;
	    *bp = (sd->nrel*4) >> 8;

	    if (sd->group) {
		int q;
		SegDesc *ssd;
		int nrel = 0;

		for (q = 0; q < sd->group->numSegs; q++) {
		    ssd = sd->group->segs[q];
		    assert(ssd->nodata || ssd->roff == sd->foff +
			   ((int)(sd->size+15) & (int)~15) +
			   (nrel + ssd->nrel) * fileOps->rtrelsize);
		    nrel += ssd->nrel;
		}
	    } else {
		assert(sd->roff == sd->foff +
		       ((int)(sd->size+15) & (int)~15) +
		       sd->nrel * fileOps->rtrelsize);
	    }

	    /*
	     * Finally, the allocation flags
	     */
	    bp = rtable+((2+4+2)*resCount)+(2*j);
	    *bp++ = sd->flags;
	    *bp = sd->flags >> 8;
	}
    }

    Out_Block(curOff, (void *)rtable, resCount * 10);
    curOff += resCount * 10;
    free((void *)rtable);

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

    if (numLibs) {
	printf("Import    Number   Type      Protocol\n");
	printf("-------------------------------------\n");
	for (i = 0; i < numLibs; i++) {
	    printf("%-10.*s", GEODE_NAME_SIZE, libs[i].entry.name);
	    if (libs[i].lnum == IS_KERNEL) {
		printf("KERNEL");
	    } else if (libs[i].lnum == NO_LOAD) {
		printf("NOLOAD");
	    } else if (libs[i].lnum == NO_LOAD_FIXED) {
		printf("FIXED ");
	    } else {
		printf("%3d   ", libs[i].lnum);
	    }
	    printf("   %-10s %3d.%03d\n",
		   (swaps(libs[i].entry.geodeAttrs) & GA_LIBRARY ?
		    "library" : "driver"),
		   libs[i].entry.protocol.major,
		   libs[i].entry.protocol.minor);
	}
    }

   
    fflush(stdout);
}

/***********************************************************************
 *				GeoCheckFixed
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
GeoCheckFixed(SegDesc	*targ)
{
    return ((targ->combine == SEG_LIBRARY) || (targ->flags & RESF_FIXED));
}
