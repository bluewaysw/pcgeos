/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Customs -- SunOS 4.0 dependencies
 * FILE:	  os-sunos4.c
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
 *	OS-dependent functions for SunOS 4.0.
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
"$Id: os-sunos4.c,v 1.2 91/10/27 15:07:51 adam Exp $";
#endif lint

#include    "customsInt.h"

#undef NULL

#include    <sys/types.h>
#include    <sys/param.h>
#include    <nlist.h>
#include    <fcntl.h>
#include    <sys/stat.h>
#include    <stdio.h>
#include    <vm/anon.h>
#include    <kvm.h>

static struct nlist kAddrs[] = {
{	"_avenrun"  },	    /* Load averages	    	    	*/
#define AVENRUN	    0
{	"_anoninfo" },	    /* Swap space stats	    	    	*/
#define ANONINFO    1
{	""  	    }
};

static kvm_t	    *kmem;  /* Token for referencing the kernel stuff */
static int  	    kbd;    /* Stream open to keyboard device (idle time) */

static u_long	    avenrun[3];	/* Load averages */


/***********************************************************************
 *				OS_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module
 * CALLED BY:	    Avail_Init
 * RETURN:	    Mask of bits indicating what things we can check
 * SIDE EFFECTS:    kmem and kbd are set. kAddrs filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/10/89		Initial Revision
 *
 ***********************************************************************/
int
OS_Init()
{
    int	retMask = AVAIL_EVERYTHING;

    /*
     * Open the kernel. If that fails, kvm_open will have given the
     * error for us, so we can just exit.
     */
    kmem = kvm_open(NULL, NULL, NULL, O_RDONLY, "customs");
    if (kmem == NULL) {
	exit(1);
    }

    /*
     * Locate the other structures in the kernel that we need.
     */
    switch (kvm_nlist(kmem, kAddrs)) {
	case -1:
	    printf("couldn't locate kernel symbols\n");
	    exit(1);
	case 0:
	    /*
	     * No symbols unfound -- this is good.
	     */
	    break;
	default:
	    if (kAddrs[AVENRUN].n_type == 0) {
		/*
		 * Couldn't find _avenrun symbol, so can't determine load
		 * average.
		 */
		retMask &= ~AVAIL_LOAD;
	    }
	    if (kAddrs[ANONINFO].n_type == 0) {
		/*
		 * If couldn't find _anoninfo, we can't figure out the
		 * swap space situation.
		 */
		retMask &= ~AVAIL_SWAP;
	    }
	    break;
    }
    
    /*
     * Try and open the keyboad so we can just do an fstat on it (rather
     * than a full stat). This also tells us if the thing exists.
     */
    kbd = open("/dev/kbd", O_RDONLY, 0);
    if (kbd < 0) {
	/*
	 * No keyboard, no idle time.
	 */
	retMask &= ~AVAIL_IDLE;
    }

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
 *	The number of blocks is kept in the "anoninfo" structure in the
 *	kernel. The numbers are actually given in pages, but we only
 *	deal with percentages, so we don't care.
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
    struct anoninfo ani;

    if (kvm_read(kmem,
		 kAddrs[ANONINFO].n_value,
		 &ani,
		 sizeof(ani)) != sizeof(ani))
    {
	/*
	 * Couldn't find out -- assume worst case.
	 */
	return(0);
    } else {
	/*
	 * Convert free to percentage and return it.
	 * 10/27/91: apparently, ani_resv+ani_free != ani_max, and it's
	 * when ani_resv == ani_max that the system stops allowing
	 * memory allocations, so base the percentage on the amount
	 * left over after the reserved pages are taken out, rather than
	 * on the pages actually free. -- ardeb
	 */
	return(((ani.ani_max - ani.ani_resv) * 100) / ani.ani_max);
    }
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
    unsigned long   avenrun[3];

    if (kvm_read(kmem,
		 kAddrs[AVENRUN].n_value,
		 avenrun,
		 sizeof(avenrun)) != sizeof(avenrun))
    {
	return(0);
    }

#define CVT(v)	((double)(v)/FSCALE)*LOADSCALE

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
