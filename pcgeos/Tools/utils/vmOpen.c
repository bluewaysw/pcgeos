/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  VM Utilities -- Open/Initialization of files
 * FILE:	  vmOpen.c
 *
 * AUTHOR:  	  Adam de Boor: Aug  1, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Open a VM file
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vmOpen.c,v 1.32 96/05/20 18:58:32 dbaumann Exp $";
#endif lint

#include <config.h>
#include "vmInt.h"

#include <os90File.h>
#include <compat/file.h>
#include <compat/string.h>
#include <stdio.h>
#include "malloc.h"

extern int geosRelease;	    /* Variable defined by user of this library. It
			     * contains the major number of the version of
			     * PC/GEOS for which this VM file is destined.
			     * Used only when creating a new file to decide
			     * what sort of file header to create. Otherwise
			     * we just deal with the version of the file
			     * we get... */
extern int dbcsRelease;	    /* non-zero if compiling for DBCS.
			       Means munge the FileLongName */

#include    <time.h>
#include    <errno.h>


/***********************************************************************
 *				VMInitFile
 ***********************************************************************
 * SYNOPSIS:	    Initialize a newly-opened VM file.
 * CALLED BY:	    VMOpen
 * RETURN:	    1 if successful
 * SIDE EFFECTS:    A header is created and initialized.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/19/89		Initial Revision
 *
 ***********************************************************************/
static int
VMInitFile(VMFilePtr	file)
{
    int	    	size;	    /* Size of allocated header */
    VMHeader	*hdr;	    /* Allocated header to be filled-in */
    VMBlock 	*block;	    /* General block pointer */
    MemHandle  	hdrHandle;  /* Memory handle of header block */
    char    	*cp, *cp2;
    int		returnCode;
    long		bytesWritten = 0;

    /*
     * There's *no* point in initializing a file if the thing was opened
     * read-only -- we won't be able to write the results out.
     */
    if (file->flags & VM_READ_ONLY) {
	errno = EACCES;
	return(0);
    }

    /*
     * Allocate a new header
     *
     * 6/1/92: allocate it 64K and mark it as needing shrinking to avoid
     * awful fragmentation as the thing grows oh-so-slowly during the
     * link. -- ardeb
     */
    size = sizeof(VMHeader) + (VM_INIT_NUM_BLKS * sizeof(VMBlock));
    hdrHandle = MemAllocAndLock(size, HF_SWAPABLE|HF_SHARABLE, HAF_ZERO_INIT,
				(void **)&hdr);
    file->flags |= VM_SHRINK_HDR;
    /*
     * find the rightmost slash forwards or backwards
     */
    cp = rindex(file->name, '/');
#if defined(_WIN32) || defined(_MSDOS)
    cp2 = rindex(file->name, '\\');
    cp = (cp2 > cp) ? cp2 : cp;
#endif
    if (cp == NULL) {
	cp = file->name;
    } else {
	cp++;
    }

    /*
     * Make the file header be zero so we know to allocate space in the file
     * (necessary? We've got the handle for the header, after all...)
     */
    if (geosRelease > 1 ) {
	time_t	clock;
	struct tm *now;

	file->flags |= VM_2_0;
	bzero(&file->fileHdr.v2, sizeof(file->fileHdr.v2));
	if (dbcsRelease) {
	    VMCopyToDBCSString(file->fileHdr.v2.VMFH_gfh.longName, cp,
			       GFH_LONGNAME_SIZE);
	} else {
	    strcpy(file->fileHdr.v2.VMFH_gfh.longName, cp);
	}
	file->fileHdr.v2.VMFH_headerPos = 0;
	file->fileHdr.v2.VMFH_headerSize = 0;
	file->fileHdr.v2.VMFH_signature = swapword(VMFH_SIG);
	file->fileHdr.v2.VMFH_gfh.signature[0] = 'G' | 0x80;
	file->fileHdr.v2.VMFH_gfh.signature[1] = 'E';
	file->fileHdr.v2.VMFH_gfh.signature[2] = 'A' | 0x80;
	file->fileHdr.v2.VMFH_gfh.signature[3] = 'S';
	file->fileHdr.v2.VMFH_gfh.type = swapword(GFT_VM);

	time(&clock);
	now = localtime(&clock);

	file->fileHdr.v2.VMFH_gfh.createdDate =
	    swapword(((now->tm_year-80) << FD_YEAR_OFFSET) |
		     ((now->tm_mon+1) << FD_MONTH_OFFSET) |
		     (now->tm_mday << FD_DAY_OFFSET));
	file->fileHdr.v2.VMFH_gfh.createdTime =
	    swapword((now->tm_hour << FT_HOUR_OFFSET) |
		     (now->tm_min << FT_MINUTE_OFFSET) |
		     ((now->tm_sec >> 1) << FT_2SECOND_OFFSET));
	/*
	 * Mark as DBCS
	 */
	if (dbcsRelease) {
   	    file->fileHdr.v2.VMFH_gfh.flags |= swapword(GFHF_DBCS);
 	}
    } else {
	strcpy(file->fileHdr.v1.VMFH_gfh.core.longName, cp);
	file->fileHdr.v1.VMFH_headerPos = 0;
	file->fileHdr.v1.VMFH_headerSize = 0;
	file->fileHdr.v1.VMFH_signature = swapword(VMFH_SIG);
	file->fileHdr.v1.VMFH_gfh.core.signature[0] = (char) ('G' | 0x80);
	file->fileHdr.v1.VMFH_gfh.core.signature[1] = 'E';
	file->fileHdr.v1.VMFH_gfh.core.signature[2] = (char) ('O' | 0x80);
	file->fileHdr.v1.VMFH_gfh.core.signature[3] = 'S';
	file->fileHdr.v1.VMFH_gfh.core.type =
	    swapword(GFT_VM-GFT_RELEASE_1_OFFSET);
    }

    /*
     * Initialize the fields of the header. Most are set to zero, taken care
     * of by the HAF_ZERO_INIT passed to MemAllocAndLock.
     *	- signature gets proper thing
     *	- unassigned chain starts with second handle, since first is dedicated
     *	  to the header, and encompasses all the remaining handles.
     *	- there are no assigned blocks (the file remains empty)
     *	- one handle is used.
     *	- one handle (the header) is resident.
     *	- we need no extra unassigned handles.
     *	- there is no map block yet.
     *	- we set the compaction threshold, in case this file actually gets
     *	  used on the PC (or we later support compaction).
     *	- the file contains nothing.
     *  - attributes are left at 0 (asynchronous update, no backup, no
     *    object relocation, don't preserve handles)
     *  - extra map word left at 0.
     */
    hdr->VMH_signature	    = VM_HEADER_SIG;
    hdr->VMH_lastHandle	    = (VMBlockHandle)size;
    hdr->VMH_numUsed	    = 1;
    hdr->VMH_numResident    = 1;
    hdr->VMH_compactThresh  = VM_DEF_COMPACT_THRESH;

    /*
     * Initialize the remaining handles, linking them all into the unassigned
     * chain.
     */
    VMLinkNewBlocks(hdr, &hdr->VMH_blockTable[1], VM_INIT_NUM_BLKS - 1);
    /*
     * Set up first handle for the header
     */
    block = hdr->VMH_blockTable;

    block->VMB_memHandle    = hdrHandle;
    block->VMB_sig  	    = VM_DIRTY_BLK_SIG;
    block->VMB_uid  	    = (VMID)0;
    block->VMB_size 	    = 0;
    block->VMB_pos  	    = (long)0;

    MemUnlock(hdrHandle);

    file->blkHdr = hdr;

    /*
     * Write out the zeroed file header so later file allocations don't
     * have to worry about a zero-length file.
     */
    file->fsize = ((geosRelease > 1) ? sizeof(file->fileHdr.v2) :
		   sizeof(file->fileHdr.v1));
    returnCode = FileUtil_Write(file->fd, (unsigned char *)&file->fileHdr,
				file->fsize, &bytesWritten);
    if (returnCode == FALSE) {
	char errmsg[512];

	FileUtil_SprintError(errmsg, "Problem writing to %s", file->name);
	fprintf(stderr, "%s", errmsg);
	return(0);
    } else {
	/*
	 * Successful -- tell caller this.
	 */
	return(1);
    }
}


/***********************************************************************
 *				VMOpen
 ***********************************************************************
 * SYNOPSIS:	    Open a vm file.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    A VMHandle for the now-open file
 * SIDE EFFECTS:    The header block is read into memory.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
VMHandle
VMOpen(short	    	flags,      /* Flags for open */
       short	    	compress,   /* Compression threshold */
       const char    	*fileName,  /* Name of file to open/create or
				     * directory in which to create temp file*/
       short	    	*status)    /* RETURN: status */
{
    VMFilePtr	    file;   	/* New structure to return */
    int	    	    oflags = O_BINARY;	/* Flags for (non-temp) open */
    MemHandle  	    memHandle;	/* Memory handle for header block */
    int	    	    sflags = 0;	/* Flags for sharing mode */
    int	    	    returnCode;
    long	        bytesRead = 0;

    file = (VMFilePtr)calloc(sizeof(VMFileRec), 1);
    file->flags = 0;
    switch(flags & VMO_OPEN_TYPE) {
	case VMO_TEMP_FILE:
	{
	    /*
	     * Allocate room for temp file name:
	     * 1 for /, 2 for vm, 6 for XXXXXX, 1 for null...
	     */
	    file->name = (char *)malloc(strlen(fileName) + 1 + 2 + 6 + 1);
#if defined(__HIGHC__)
	    sprintf(file->name, "vmXXXXXX", fileName);
#else
	    sprintf(file->name, "%s"QUOTED_SLASH"vmXXXXXX", fileName);
#endif

#if defined _WIN32
	    /*
	     * we need to tell windows to create the file if it doesn't exist
	     */
	    oflags |= (O_RDWR | O_CREAT);
#endif /* defined _WIN32 */

	    /*
	     * Find a unique name using the template created above
	     */
#if defined(_LINUX)
	  {
    	int fp = mkstemp(file->name);
    	if(fp == -1) {
      	*status = FileUtil_GetError();
	    	free((char *)file);
	    	return((VMHandle)0);
    	}
    	else {
      	file->flags |= VM_TEMP_FILE;
      	*status = 0;
				file->fd = fdopen(fp, "w+");
			}
    }
#else
	    if (mktemp(file->name) != NULL) {
		returnCode = FileUtil_Open(&(file->fd), file->name,
					   oflags, sflags, 0666);
		if (returnCode == TRUE) {
		    break;
		}
	    }
#endif
	    break;
	}
	case VMO_CREATE_TRUNCATE:
	    oflags |= O_CREAT|O_TRUNC;
	    goto decode_access;

	case VMO_CREATE_ONLY:
	    oflags |= O_EXCL;
	    /*FALLTHRU*/
	case VMO_CREATE:
	    oflags |= O_CREAT;
	    /*FALLTHRU*/
	default:
	    /*
	     * Decode the PC GEOS access type into a UNIX one
	     */
decode_access:
	    switch (flags & VMO_ACCESS_TYPE) {
		case FILE_ACCESS_R:
		    file->flags |= VM_READ_ONLY;
		    oflags |= O_RDONLY;
		    break;
		case FILE_ACCESS_RW:
		    oflags |= O_RDWR;
		    break;
		default:
		    /*
		     * Bogus access mode -- return failure.
		     */
		    *status = VM_SHARING_DENIED;
		    free((char *)file);
		    return((VMHandle)0);
	    }
	    /*
	     * Try and perform the open, using the flags we've got so far.
	     * XXX: what should the mode be when the thing is created? For
	     * now we just use 0666 and trust the user's umask is set
	     * correctly.
	     */
	    switch(flags & VMO_SHARE_MODE) {
		case FILE_DENY_RW:
		    sflags = SH_DENYRW;
		    break;
		case FILE_DENY_W:
		    sflags = SH_DENYWR;
		    break;
		case FILE_DENY_R:
		    sflags = SH_DENYRD;
		    break;
		case FILE_DENY_NONE:
		    sflags = SH_DENYNO;
		    break;
	    }
	    returnCode = FileUtil_Open(&(file->fd), fileName, oflags,
				       sflags, 0666);
	    if (returnCode == FALSE) {
		/*
		 * Couldn't open -- return the system error number and NULL
		 */
		*status = FileUtil_GetError();

		free((char *)file);
		return((VMHandle)0);
	    }
	    file->name = (char *)malloc(strlen(fileName)+1);
	    strcpy(file->name, fileName);
	    break;
    }

    /*
     * file->fd is now open to the VM file. Now need to locate and read
     * the header.
     */

#define HEADER_SIZE (sizeof(file->fileHdr.v1) > sizeof(file->fileHdr.v2) ? \
		    sizeof(file->fileHdr.v1) : sizeof(file->fileHdr.v2))
    /*
     * If file opened RW, we're positioned at the end.  Move file ptr to start.
     */
    FileUtil_Seek(file->fd, 0L, SEEK_SET);

    errno = 0;			/* In case file smaller than file header */
    FileUtil_Read(file->fd, (char *)&file->fileHdr, HEADER_SIZE, &bytesRead);
    switch (bytesRead) {
	case 0:
	    /*
	     * Read nothing, but no error -- file must be new around here...
	     * Initialize a header for it.
	     */
	    if (!VMInitFile(file)) {
		goto cleanup;
	    }
	    break;
	case sizeof(file->fileHdr.v1):
	case sizeof(file->fileHdr.v2):
	    /*
	     * File signature is in the same place for both versions, so we can
	     * safely use the .v2 one to see if the file's a valid PC/GEOS file
	     * and figure for which version of PC/GEOS it was made.
	     */
	    if ((file->fileHdr.v2.VMFH_gfh.signature[0] == ('G'|0x80)) &&
		(file->fileHdr.v2.VMFH_gfh.signature[1] == 'E') &&
		(file->fileHdr.v2.VMFH_gfh.signature[2] == ('O'|0x80)) &&
		(file->fileHdr.v2.VMFH_gfh.signature[3] == 'S'))
	    {
		/*
		 * 1.X VM file...
		 */
		if (swapword(file->fileHdr.v1.VMFH_signature) != VMFH_SIG) {
		    errno = 0;
		    goto cleanup;
		} else if (file->fileHdr.v1.VMFH_headerPos == 0) {
		    /*
		     * Deal with an empty VM file -- if the position of the
		     * header is 0 (in any byte-order), the file wasn't closed
		     * properly or something like that, so the file is empty.
		     * Initialize the file and break out of the switch.
		     * XXX: Should we give an error instead?
		     */
		    if (!VMInitFile(file))  {
			goto cleanup;
		    } else {
			break;
		    }
		} else {
		    /*
		     * Figure out the file size in case we need to
		     * allocate anything.
		     */
		    file->fsize = FileUtil_Seek(file->fd, 0L, SEEK_END);
		}

		/*
		 * Allocate room for and read in the header.
		 */
		memHandle =
		    VMAllocAndRead(file,
				   swapdword(file->fileHdr.v1.VMFH_headerPos),
				   swapword(file->fileHdr.v1.VMFH_headerSize));
	    } else if ((file->fileHdr.v2.VMFH_gfh.signature[0] == ('G'|0x80))
		       && (file->fileHdr.v2.VMFH_gfh.signature[1] == 'E') &&
		       (file->fileHdr.v2.VMFH_gfh.signature[2] == ('A'|0x80))
		       && (file->fileHdr.v2.VMFH_gfh.signature[3] == 'S'))
	    {
		/*
		 * Mark it as 2.0 now, so VMAllocAndRead knows to adjust
		 * the file position properly.
		 */
		file->flags |= VM_2_0;

		if (swapword(file->fileHdr.v2.VMFH_signature) != VMFH_SIG) {
		    errno = 0;
		    goto cleanup;
		} else if (file->fileHdr.v2.VMFH_headerPos == 0) {
		    /*
		     * Deal with an empty VM file -- if the position of the
		     * header is 0 (in any byte-order), the file wasn't closed
		     * properly or something like that, so the file is empty.
		     * Initialize the file and break out of the switch.
		     * XXX: Should we give an error instead?
		     */
		    if (!VMInitFile(file))  {
			goto cleanup;
		    } else {
			break;
		    }
		} else {
		    /*
		     * Figure out the file size in case we need to
		     * allocate anything.
		     */
		    file->fsize = FileUtil_Seek(file->fd, 0L, SEEK_END);
		}

		/*
		 * Allocate room for and read in the header.
		 */
		memHandle =
		    VMAllocAndRead(file,
				   swapdword(file->fileHdr.v2.VMFH_headerPos),
				   swapword(file->fileHdr.v2.VMFH_headerSize));
	    } else {
		/*
		 * Invalid file.
		 */
		errno = 0;
		goto cleanup;
	    }

	    file->blkHdr = (VMHeader *)MemLock(memHandle);
#ifdef SWAP
	    /*
	     * Byte-swap the header while the thing is in-core
	     */
	    VMSwapHeader(file->blkHdr,
			 swapword(file->blkHdr->VMH_blockTable[0].VMB_size));
#endif /* SWAP */

	    /*
	     * Make sure the signature is valid (i.e. it's a valid VM file).
	     */
	    if (file->blkHdr->VMH_signature == VM_HEADER_SIG) {
		/*
		 * Store the memory handle for the header block -- the
		 * rest of the fields should have been set up when the
		 * header block was written to disk.
		 */
		VMBlock	*block = file->blkHdr->VMH_blockTable;
		VMBlock	*end = VM_LAST(file);

	    	block->VMB_memHandle = memHandle;

		/*
		 * Now zero out all the other memHandle fields. VMClose
		 * won't have freed things before calling VMUpdate (with
		 * good reason) so the header block will have been
		 * written out with non-zero memHandles, even though
		 * no block has memory now...
		 */
		for (block = &file->blkHdr->VMH_blockTable[1];
		     block < end;
		     block++)
		{
		    if (block->VMB_sig == VM_USED_BLK_SIG) {
			block->VMB_memHandle = (MemHandle)0;
		    }
		}
		break;
	    } else {
		/*
		 * Ack! Choke! Gasp! Wheeze!
		 */
		errno = 0;
		MemFree(memHandle);
		/*FALLTHRU*/
	    }
	default:
	    cleanup:
	    /*
	     * Error -- file too small...or something
	     * Return system error code as result
	     */
	    *status = errno ? errno : EINVAL;
	    /*
	     * Close the stream
	     */
	    (void)FileUtil_Close(file->fd);
	    /*
	     * Free the name
	     */
	    if (file->name) {
		free(file->name);
	    }
	    /*
	     * Free the aborted handle
	     */
	    free((char *)file);
	    /*
	     * Return NULL to signal error
	     */
	    file = 0;
	    break;
    }

    if (file) {
	file->reloc = NULL;
    }

    return((VMHandle)file);
}



/***********************************************************************
 *				VMCopyToDBCSString
 ***********************************************************************
 * SYNOPSIS:	    Copy an SBCS string to a DBCS string
 * CALLED BY:	    EXTERNAL
 * RETURN:	    size of DBCS string
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	6/28/93		Initial Revision
 *
 ***********************************************************************/

int
VMCopyToDBCSString(char    *dest,
		    char    *source,
		    int	    max)
{
    int	si = 0, di = 0;

    while (di < max) {
	if (source[si]) {
	    dest[di++] = source[si++];
	} else {
	    dest[di++] = '\0';
	    dest[di++] = '\0';
	    return(di);
    	}
	dest[di++] = '\0';
    }
    return(di);
}
