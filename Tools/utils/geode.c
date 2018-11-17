/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		geodeUtils.c

AUTHOR:		Chris Boyke, Jan 12, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/94   	Initial version.

DESCRIPTION:
	

	$Id: geode.c,v 1.2 95/12/08 09:07:43 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>
#include <stdio.h>
#include <compat/string.h>
#include <bswap.h>
#include <time.h>
#include <compat/file.h>
#include <assert.h>
#include <geode.h>
#include <geodeUt.h>

#include "malloc.h"

/*********************************************************************
 *			GeodeGetSizeOfNthResource
 *********************************************************************
 * SYNOPSIS: 	    Fetch the size of a resource.
 *
 * CALLED BY:	    global
 * RETURN:  	    size of Nth resource
 * SIDE EFFECTS:    moves file pointer position
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/12/92	Initial version			     
 * 
 *********************************************************************/
word
GeodeGetSizeOfNthResource(GeodeHeader2 *gh, FILE *fp, int resourceId)
{
    dword   pos;
    word    size;

    pos = sizeof(GeodeHeader2) + 
	      GHLibCount(gh)*sizeof(ImportedLibraryEntry) +
	      GHExportEntryCount(gh)*sizeof(dword) + resourceId*sizeof(word);

    fseek(fp, pos, SEEK_SET);
    fread(&size, 1, sizeof(word), fp);
    return (swaps(size));
}

/*********************************************************************
 *			GeodeGetPositionOfNthResource
 *********************************************************************
 * SYNOPSIS: 	    Return the position of a resource
 * CALLED BY:	    global
 * RETURN:  	    position of Nth resource
 * SIDE EFFECTS:    moves file pointer position
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/12/92	Initial version			     
 * 
 *********************************************************************/
dword
GeodeGetPositionOfNthResource(GeodeHeader2 *gh, FILE *fp, 
			      int resourceId)
{
    dword   pos;
    dword   size;

    pos = sizeof(GeodeHeader2) + 
	GHLibCount(gh)*sizeof(ImportedLibraryEntry) +
        GHExportEntryCount(gh)*sizeof(dword) + 
	GHResCount(gh)*sizeof(word) + resourceId*sizeof(dword);

    fseek(fp, pos, SEEK_SET);
    fread(&size, 1, sizeof(dword), fp);
    return(Segment(size) * 65536 + Offset(size) + 256);

}

/*********************************************************************
 *			GeodeRelocationTableSizeOfNthResource
 *********************************************************************
 * SYNOPSIS: 	    Fetch the size of a resource's relocation table.
 * CALLED BY:	    global
 * RETURN:  	    Relocation table size
 * SIDE EFFECTS:    moves file pointer position
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/12/92	Initial version			     
 * 
 *********************************************************************/
word
GeodeGetRelocationTableSizeOfNthResource(GeodeHeader2 *gh, FILE *fp, 
					 int resourceId)
{
    dword   pos;
    word    size;

    pos = sizeof(GeodeHeader2) + 
	  GHLibCount(gh)*sizeof(ImportedLibraryEntry) +
	  GHExportEntryCount(gh)*sizeof(dword) + 
	  GHResCount(gh)*(sizeof(word) + sizeof(dword)) +
	  resourceId*sizeof(word);

    fseek(fp, pos, SEEK_SET);
    fread(&size, 1, sizeof(word), fp);
    return(swaps(size));
}


/*********************************************************************
 *			GeodeGetAllocationFlagsOfNthResource
 *********************************************************************
 * SYNOPSIS: 	    Fetch a resource's allocation flags.
 * CALLED BY:	    global
 * RETURN:  	    allocation flags of Nth resource
 * SIDE EFFECTS:    moves file pointer position
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	11/12/92		Initial version			     
 * 
 *********************************************************************/
word
GeodeGetAllocationFlagsOfNthResource(GeodeHeader2 *gh, FILE *fp, 
				     int resourceId)
{
    dword   pos;
    word    flags;

    pos = sizeof(GeodeHeader2) + 
	  GHLibCount(gh)*sizeof(ImportedLibraryEntry) +
	  GHExportEntryCount(gh)*sizeof(dword) + 
	  GHResCount(gh)*(sizeof(word) + sizeof(dword) + sizeof(word)) +
	  resourceId*sizeof(word);

    fseek(fp, pos, SEEK_SET);
    fread(&flags, 1, sizeof(word), fp);
    return(swaps(flags));
}



/***********************************************************************
 *			GeodeReadResource
 ***********************************************************************
 * SYNOPSIS:	    Read a resource
 * RETURN:	    pointer to resource (must be freed by caller)
 * SIDE EFFECTS:    positions file at the resource's relocation table.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description

 *	----	----		-----------
 *     chrisb	12/30/93   	Initial Revision
 *
 ***********************************************************************/
byte *
GeodeReadResource (GeodeHeader2 *gh, FILE *fp, int size, int resourceId)
{
    dword pos;
    void *resource;
    int alignedSize = ParagraphAlign(size);
    pos = GeodeGetPositionOfNthResource(gh, fp, resourceId);
    fseek(fp, pos, SEEK_SET);
    resource = (byte *) malloc(alignedSize);

    fread(resource, alignedSize, 1, fp);
    return resource;

}	/* End of GeodeReadResource.	*/
