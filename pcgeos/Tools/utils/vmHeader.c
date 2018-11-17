/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  vmHeader.c
 * FILE:	  vmHeader.c
 *
 * AUTHOR:  	  Adam de Boor: Jan  2, 1990
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/ 2/90	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for manipulating the VM file's file-header (i.e. the one
 *	at which os/90 will gaze, not the one we manipulate).
 *
 *	NOTE: THE FUNCTIONS IN THIS FILE ASSUME THE HEADER IS IN THE PC'S
 *	BYTE-ORDER. THE CALLER MUST BE AWARE OF THIS.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmHeader.c,v 1.4 92/07/17 19:35:24 adam Exp $";
#endif lint

#include <config.h>

#include <fcntl.h>
#include "vmInt.h"
#include <compat/file.h>
#if defined(__HIGHC__) || defined(_WIN32) || defined(__WATCOMC__)
# include <stdio.h>
#endif


/***********************************************************************
 *				VMGetHeader
 ***********************************************************************
 * SYNOPSIS:	    Fetch the header for the VM file.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Just copy the shadow version from the VMHandle out.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/90		Initial Revision
 *
 ***********************************************************************/
void
VMGetHeader(VMHandle	    vmHandle,
	    genptr	    gfhPtr)
{
    VMFilePtr	    file = (VMFilePtr)vmHandle;

    if (file->flags & VM_2_0) {
	bcopy(&file->fileHdr.v2.VMFH_gfh, gfhPtr, sizeof(GeosFileHeader2));
    } else {
	bcopy(&file->fileHdr.v1.VMFH_gfh, gfhPtr, sizeof(GeosFileHeader));
    }
}


/***********************************************************************
 *				VMSetHeader
 ***********************************************************************
 * SYNOPSIS:	    Store the header for the VM file.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Copy the given version into the shadow header, then write just
 *	that shadow version out to the file.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 2/90		Initial Revision
 *
 ***********************************************************************/
void
VMSetHeader(VMHandle	    vmHandle,
	    genptr    	    gfhPtr)
{
    VMFilePtr	file = (VMFilePtr)vmHandle;
    long	bytesWritten = 0;
    int		seekPos = 0;

    FileUtil_Seek(file->fd, 0L, SEEK_SET);
    if (file->flags & VM_2_0) {
	bcopy(gfhPtr, &file->fileHdr.v2.VMFH_gfh, sizeof(GeosFileHeader2));
	FileUtil_Write(file->fd, (unsigned const char *)&file->fileHdr.v2.VMFH_gfh,
		       sizeof(GeosFileHeader2), &bytesWritten);
    } else {
	bcopy(gfhPtr, &file->fileHdr.v1.VMFH_gfh, sizeof(GeosFileHeader));
 	FileUtil_Write(file->fd, (unsigned const char *)&file->fileHdr.v1.VMFH_gfh,
		       sizeof(GeosFileHeader), &bytesWritten);
    }
}
