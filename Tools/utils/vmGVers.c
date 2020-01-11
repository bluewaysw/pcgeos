/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  vmGVers.c
 * FILE:	  vmGVers.c
 *
 * AUTHOR:  	  Adam de Boor: Jun  2, 1992
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	VMGetVersion	    Returns the major version number of PC/GEOS
 *	    	    	    for which the file was intended.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/ 2/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *
 ***********************************************************************/

#include <config.h>
#include "vmInt.h"


/***********************************************************************
 *				VMGetVersion
 ***********************************************************************
 * SYNOPSIS:	    Fetch the major version # of PC/GEOS for which the
 *	    	    file was intended.
 * CALLED BY:	    GLOBAL	
 * RETURN:	    major version #...
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/ 2/92		Initial Revision
 *
 ***********************************************************************/
int
VMGetVersion(VMHandle	vmHandle)
{
    return ((((VMFilePtr)vmHandle)->flags & VM_2_0) ? 2 : 1);
}
