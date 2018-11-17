/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools Library -- VM File Manipulation
 * FILE:	  vmAllocAndRead.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  2, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 2/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Read a block into new memory from the file
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmAlRd.c,v 1.4 92/07/17 19:35:10 adam Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"

#include <fcntl.h>
#include <compat/file.h>
#include <errno.h>


/***********************************************************************
 *				VMAllocAndRead
 ***********************************************************************
 * SYNOPSIS:	    Allocate room for and read in a VM block.
 * CALLED BY:	    VMOpen, VMLock
 * RETURN:	    The handle for the block or 0 on error
 * SIDE EFFECTS:    A memory handle is consumed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
MemHandle
VMAllocAndRead(VMFilePtr    	file,	/* File from which to read it */
	       dword	    	pos,	/* Location in file */
	       word  	    	size)	/* Size of block to read */
{
    MemHandle  	memHandle;  	/* Memory handle for the thing */
    void    	*addr;	    	/* Place memory resides */
    int    	lastError = EINTR;
    long   	bytesRead = 0;
    char 	errmsg[512];


    /*XXX: check return */
    memHandle = MemAllocAndLock(size, HF_SWAPABLE|HF_SHARABLE, HAF_NO_ERR,
				&addr);

    if (FileUtil_Seek(file->fd, ((file->flags & VM_2_0) ?
				 pos + sizeof(GeosFileHeader2) :
				 pos),
		      SEEK_SET) == -1) 
    {
	char errmsg[512];

	FileUtil_SprintError(errmsg, "cannot seek in vmfile \"%s\"", 
			     file->name);
	fprintf(stderr, "%s", errmsg);
	exit(1);
    }

    while (lastError == EINTR) {
	FileUtil_Read(file->fd, addr, size, &bytesRead);
	if (bytesRead == size) {
	    break;
	}
#if defined(sun) || defined(isi)
	/*
	 * Couldn't seek or read -- return error
	 */
	if (errno == ESTALE) {
	    __eprintf("VM file %s has been deleted -- no longer able "
		      "to read it\n", file->name ? : "(unknown)");
	} else if (errno == EINTR) {
	    /*
	     * System call was interrupt -- just retry it.
	     */
	    lastError = errno;
	    continue;
	}
#endif
	FileUtil_SprintError(errmsg, "cannot read from vmfile \"%s\"", 
			     file->name);
	fprintf(stderr, "%s", errmsg);
	MemFree(memHandle);
	return(0);
    }

    return(memHandle);
}
	       
