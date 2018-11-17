/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Customs -- BSD UNIX dependencies
 * FILE:	  os-bsd.c
 *
 * AUTHOR:  	  Adam de Boor: Sep  9, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	OS_Init	    	    Initialize module and return mask of criteria
 *	    	    	    to be considered in determination.
 *	OS_Idle	    	    Return machine idle time, in seconds
 *	OS_Load	    	    Return machine load factor
 *	OS_Swap	    	    Return free swap space
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/ 9/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	OS-dependent functions for BSD-related systems. This includes:
 *	    SunOS 3.x
 *	    Ultrix
 *	    BSD 4.2 and 4.3
 *
 *	These functions are responsible for the determination of the
 *	current state of the system, returning it as a set of numbers
 *	in a customs-standard form, whatever form they may be in in the
 *	system itself.
 *
 *	The format used is the same as that transmitted for the AVAIL_SET
 *	RPC.
 *
 * 	Copyright (c) Berkeley Softworks 1989
 * 	Copyright (c) Adam de Boor 1989
 *
 * 	Permission to use, copy, modify, and distribute this
 * 	software and its documentation for any non-commercial purpose
 *	and without fee is hereby granted, provided that the above copyright
 * 	notice appears in all copies.  Neither Berkeley Softworks nor
 * 	Adam de Boor makes any representations about the suitability of this
 * 	software for any purpose.  It is provided "as is" without
 * 	express or implied warranty.
 *
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: os-bsd.c,v 1.1 89/09/11 11:07:20 adam Exp $";
#endif lint

#include    "customsInt.h"

#undef NULL

#include    <sys/param.h>
#include    <sys/stat.h>
#include    <sys/conf.h>
#include    <sys/map.h>
#include    <nlist.h>
#include    <sys/file.h>
/*#include    <sys/time.h>*/
#include    <stdio.h>

#ifndef mapstart
/*
 * Apparently, Ultrix doesn't have these macros...
 */
#define mapstart(X)	(struct mapent *)((X)+1)
#define mapfree(X)	(X)->m_free
#define mapwant(X)	(X)->m_want
#define mapname(X)	((struct maplast *)(X))->m_nam
#endif /* mapstart */

static struct nlist kAddrs[] = {
{	"_nswapmap"	},   	/* Number of swap resource maps */
#define NSWAPMAP  	0
{	"_nswdev" 	},   	/* Number of swap devices   	*/
#define NSWDEV	  	1
{	"_swapmap"	},   	/* The swap resource maps   	*/
#define SWAPMAP	  	2
{	"_swdevt" 	},   	/* The swap devices 	    	*/
#define SWDEVT	  	3
{	"_avenrun"	},   	/* Load averages    	    	*/
#define AVENRUN	  	4
{	""  	  	}
};

static int  	  	kmem;	    	/* Descriptor to /dev/kmem */
static int  	  	kbd;	    	/* Descriptor to /dev/kbd */

/*
 * The existence of the constant FSCALE is used to determine in what format
 * the system's load average is stored. If FSCALE is defined, it indicates
 * a 32-bit fixed-point number is being used. The number is divided by
 * FSCALE using floating point arithmetic to obtain the actual load
 * average.
 *
 * If FSCALE isn't defined (standard BSD), the calculations are performed using
 * double floating point math.
 */
#ifdef FSCALE
static long 	  	avenrun[3];	/* Load averages */
#else
static double		avenrun[3];	/* Load averages */
#endif /* FSCALE */

static int  	  	swblocks; 	/* Total swap space available */
static int  	  	nSwapMap; 	/* Number of entries in the swap map */
static off_t	  	swapMapAddr;	/* Address in sysspace of the map */
static struct map 	*swapMap; 	/* Space for swap map */
static int  	  	swapMapSize;	/* Size of the swap map (bytes) */



/***********************************************************************
 *				OS_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module
 * CALLED BY:	    Avail_Init
 * RETURN:	    Mask of AVAIL_* bits indicating what criteria are
 *	    	    to be examined.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 9/89		Initial Revision
 *
 ***********************************************************************/
int
OS_Init()
{
    struct swdevt   *swapDevices,
		    *sw;
    int	    	    numSwapDevices;
    int	    	    retMask;

    /*
     * Default to everything.
     */
    retMask = AVAIL_EVERYTHING;

    /*
     * Extract the addresses for the various data structures that we examine.
     * XXX: Perhaps this thing should allow some other name than /vmunix?
     */
    if (nlist ("/vmunix", kAddrs) < 0) {
	printf ("/vmunix: could not read symbol table\n");
	exit(1);
    }
    /*
     * Open a stream to the kernel's memory so we can actually look at the
     * data structures.
     */
    if ((kmem = open ("/dev/kmem", O_RDONLY, 0)) < 0) {
	printf ("Could not open /dev/kmem\n");
	exit(1);
    }
#ifdef sun
    /*
     * Try for a keyboard device. It's ok if we can't open this thing. It
     * just means we're not on a workstation and so can't determine idle time.
     */
    if ((kbd = open ("/dev/kbd", O_RDONLY, 0)) < 0) {
	/*
	 * If couldn't open keyboard, we can't tell how long the machine's
	 * been idle.
	 */
	retMask &= ~AVAIL_IDLE;
    }
#else
    retMask &= ~AVAIL_IDLE;
#endif

    /*
     * Find the total number of swap blocks available to the machine
     * by summing the amounts in the swdevt descriptors
     */
    lseek (kmem, (off_t)kAddrs[NSWDEV].n_value, L_SET);
    read (kmem, (char *)&numSwapDevices, sizeof (numSwapDevices));

    swapDevices =
	(struct swdevt *)malloc (numSwapDevices * sizeof (struct swdevt));

    lseek (kmem, (off_t)kAddrs[SWDEVT].n_value, L_SET);
    read (kmem, (char *)swapDevices, numSwapDevices*sizeof(struct swdevt));

    for (swblocks=0, sw=swapDevices; numSwapDevices!=0; sw++, numSwapDevices--)
    {
	if (sw->sw_freed) {
	    swblocks += sw->sw_nblks;
	}
    }
    free ((Address) swapDevices);

    /*
     * Find and save the number and location of the swap maps for
     * the local machine, then allocate enough room to hold them
     * all, pointing 'swapMap' to the space.
     */
    lseek (kmem, (off_t) kAddrs[NSWAPMAP].n_value, L_SET);
    read (kmem, (char *)&nSwapMap, sizeof (nSwapMap));
    lseek (kmem, (off_t) kAddrs[SWAPMAP].n_value, L_SET);
    read (kmem, (char *)&swapMapAddr, sizeof(swapMapAddr));
    
    printf ("%d swap blocks total allocated among %d maps at 0x%08x\n",
	    swblocks, nSwapMap, swapMapAddr);
    swapMapSize = nSwapMap * sizeof (struct map);

    swapMap = (struct map *) malloc (swapMapSize);

    return(retMask);
}


/***********************************************************************
 *				OS_Idle
 ***********************************************************************
 * SYNOPSIS:	    Find the idle time of the machine
 * CALLED BY:	    Avail_Local
 * RETURN:	    The number of seconds for which the machine has been
 *	    	    idle.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Locate the access time for the keyboard device and subtract it
 *	from the current time to obtain the number of seconds the
 *	keyboard has been idle. The assumption is that the keyboard
 *	device's idle time reflects that of the machine. This does not
 *	take into account rlogin connections, or non-Sun systems that
 *	are workstations but don't have a keyboard device.
 *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
int
OS_Idle()
{
    struct stat	    kbStat;
    struct timeval  now;

    fstat (kbd, &kbStat);
    gettimeofday (&now, (struct timezone *)0);
	
    return (now.tv_sec - kbStat.st_atime);
}


/***********************************************************************
 *				OS_Swap
 ***********************************************************************
 * SYNOPSIS:	    Find the percentage of the system's swap space that
 *	    	    isn't being used.
 * CALLED BY:	    Avail_Local
 * RETURN:	    The percentage of free swap space
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	The number of free blocks is simple the number of blocks described
 *	by the system's swap maps, whose address we've got in swapMapAddr.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
int
OS_Swap()
{
    int	    		free;		/* Number of free blocks so far */
    struct mapent	*mapEnd;	/* End of swap maps */
    struct mapent	*mapEntry;	/* Current map */
    
    lseek (kmem, swapMapAddr, L_SET);
    read (kmem, (char *)swapMap, swapMapSize);
	
    mapEnd = (struct mapent *) &swapMap[nSwapMap];
    free = 0;
    for (mapEntry = mapstart(swapMap); mapEntry < mapEnd; mapEntry++) {
	free += mapEntry->m_size;
    }
    return ((free * 100) / swblocks);
}


/***********************************************************************
 *				OS_Load
 ***********************************************************************
 * SYNOPSIS:	    Return the current load average in standard form
 * CALLED BY:	    Avail_Local
 * RETURN:	    The current load as a 32-bit fixed-point number
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
unsigned long
OS_Load()
{
    unsigned long   result;

    lseek (kmem, (off_t) kAddrs[AVENRUN].n_value, L_SET);
    read (kmem, (char *)avenrun, sizeof (avenrun));
    
#ifdef FSCALE
#define CVT(v)	((double)(v)/FSCALE)*LOADSCALE
#else
#define CVT(v)	((v) * LOADSCALE)
#endif /* FSCALE */

#ifdef ALL_LOAD
    /*
     * Find largest of the three averages and return that
     */
    if (avenrun[0] > avenrun[1]) {
	if (avenrun[0] > avenrun[2]) {
	    result = CVT(avenrun[0]);
	} else {
	    result = CVT(avenrun[2]);
	}
    } else if (avenrun[1] > avenrun[2]) {
	result = CVT(avenrun[1]);
    } else {
	result = CVT(avenrun[2]);
    }
#else
    /*
     * Just return the 1-minute average.
     */
    result = CVT(avenrun[0]);
#endif

    return(result);
}
