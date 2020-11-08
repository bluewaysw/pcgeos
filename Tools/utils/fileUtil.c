/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tool Utilities
 * FILE:	  FileUtil.c
 *
 * AUTHOR:  	  Dan Baumann, Sep 26, 1996
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	FileStuf_FileOpen
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	dbaumann	9/26/96   	Initial version

 *
 * DESCRIPTION:
 *	Cross platform interface to files.
 *
 *      _WIN32 note: Although Borland C supports fopen() and open() there
 *      is a hardcoded limit of 50 filehandles that trips up swat.
 *      Thus, the WIN32 file functions are used here.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: fileUtil.c,v 1.4 97/05/27 16:40:45 dbaumann Exp $";
#endif lint

#include <config.h>
#include <compat/file.h>
#include <fileUtil.h>
#include <compat/windows.h>
#include <errno.h>
#include <stdarg.h>
#ifdef _LINUX
#include <stdlib.h>
#endif

#if defined(ISSWAT)
extern void 	(*MessageFlush)(const char *fmt, ...);
#endif

#if defined(unix) || defined(_LINUX)
# define FILE_OPEN_ERROR             ((FileType)NULL)
#elif defined(_MSDOS)
# define FILE_OPEN_ERROR             ((FileType *)-1)
#elif defined(_WIN32)
# define FILE_OPEN_ERROR             ((FileType)INVALID_HANDLE_VALUE)
#endif


/***********************************************************************
 *				FileUtil_Open
 ***********************************************************************
 *
 * SYNOPSIS:	    Opens a file
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    (success)TRUE or (failure)FALSE
 * SIDE EFFECTS:    file is assigned
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_Open(FileType *file, const char *path, int oflags, int sflags,
	      int mode)
{
#if defined(unix) || defined(_LINUX)
    char flags[5];

    switch (oflags & 0x7) {
    case O_RDONLY:
	sprintf(flags, "r");
	break;
    case O_WRONLY:
	if (oflags & O_TRUNC) {
	    sprintf(flags, "w");
	} else {
	    sprintf(flags, "a");
	}
	break;
    case O_RDWR:
    default:
#if defined(_LINUX)
	if ((oflags & (O_CREAT | O_EXCL)) == (O_CREAT | O_EXCL)) {
	    sprintf(flags, "w+");
	}else if (oflags & O_TRUNC) {
	    sprintf(flags, "w+");
    	} else {
	    sprintf(flags, "a+");
	}
#else
	sprintf(flags, "a+");
#endif
	break;
    }

    /* check if we have a text or binary file */
    if (oflags & O_TEXT) {
	strcat(flags, "t");
    } else {
	strcat(flags, "b");
    }

    *file = fopen(path, flags);
#elif defined(_MSDOS)
    int dosMode = mode/(10*10) *(8*8);
    *file = _sopen(path, oflags, sflags, dosMode);
#elif defined(_WIN32)
    DWORD winOFlags;
    DWORD winSFlags;
    DWORD winCreate;

    switch (oflags & 0x7) {
    case O_RDONLY:
	winOFlags = GENERIC_READ;
	winCreate = OPEN_EXISTING;
	break;
    case O_WRONLY:
	winOFlags = GENERIC_WRITE;
	if (oflags & O_CREAT) {
	    winCreate = OPEN_ALWAYS;
	} else {
	    winCreate = OPEN_EXISTING;
	}
	break;
    case O_RDWR:
    default:
	winOFlags = GENERIC_READ|GENERIC_WRITE;
	if (oflags & O_CREAT) {
	    winCreate = OPEN_ALWAYS;
	} else {
	    winCreate = OPEN_EXISTING;
	}
	break;
    }

    if (oflags & O_TRUNC) {
	winCreate = CREATE_ALWAYS;
    }

    switch (sflags & 0xff) {
    case SH_DENYRW:
	winSFlags = 0;
	break;
    case SH_DENYNO:    /* same as     SH_DENYNONE */
	winSFlags = FILE_SHARE_READ|FILE_SHARE_WRITE;
	break;
    case SH_DENYRD:
	winSFlags = FILE_SHARE_WRITE;
	break;
    case SH_DENYWR:
    default:
	winSFlags = FILE_SHARE_READ;
	break;
    }

    *file = (HANDLE) CreateFile(path,
		       winOFlags,
		       winSFlags,
		       NULL,
		       winCreate,
		       0,
		       NULL);

#endif
    if (*file == FILE_OPEN_ERROR) {
	 *file = (FileType)NULL;
	return FALSE;
    }
    return TRUE;
}	/* End of FileUtil_Open.	*/


/***********************************************************************
 *				FileUtil_Read
 ***********************************************************************
 *
 * SYNOPSIS:	    Reads data from a file
 * CALLED BY:	    (EXTERNAL), FileUtil_Getc
 * RETURN:	    (success)TRUE or (failure)FALSE
 * SIDE EFFECTS:    buf assigned data and nRead assigned length of data
 *                  and file position affected
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_Read(FileType file, unsigned char *buf, long len, long *nRead)
{
#if defined(unix) || defined(_LINUX)
    *nRead = fread(buf, 1, len, file);
    return TRUE;
#elif defined(_MSDOS)
    *nRead = read(file, buf, len);
    if (*nRead == -1) {
	return FALSE;
    }
    return TRUE;
#elif defined(_WIN32)
    return ReadFile((HANDLE)file, buf, len, (unsigned long*) nRead, NULL);
#endif
}	/* End of FileUtil_Read.	*/


/***********************************************************************
 *				FileUtil_Write
 ***********************************************************************
 *
 * SYNOPSIS:	    Writes data to a file
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    (success)TRUE or (failure)FALSE
 * SIDE EFFECTS:    nWrit is assigned length of data written and file
 *                  position is affected
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_Write(FileType file, const unsigned char *buf, long len, long *nWrit)
{
#if defined(unix) || defined(_LINUX)
    *nWrit = fwrite(buf, 1, len, file);
    if (*nWrit == 0) {
#elif defined(_MSDOS)
    *nWrit = write(file, buf, len);
    if (*nWrit == -1) {
#elif defined(_WIN32)
    BOOL returnCode;

    returnCode = WriteFile((HANDLE)file, buf, len, (unsigned long*) nWrit, NULL);
    if (returnCode == FALSE) {
#endif
	*nWrit = 0;
	return FALSE;
    }
    return TRUE;
}	/* End of FileUtil_Write.	*/


/***********************************************************************
 *				FileUtil_Seek
 ***********************************************************************
 *
 * SYNOPSIS:	    file position is set
 * CALLED BY:	    (EXTERNAL), FileUtil_Ftell
 * RETURN:	    new position in file
 * SIDE EFFECTS:    file position is adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_Seek(FileType file, long dist, int mode)
{
#if defined(unix) || defined(_LINUX)
    fseek(file, dist, mode);
    return FileUtil_Ftell(file);
#elif defined(_MSDOS)
    return lseek(file, dist, mode);
#elif defined(_WIN32)
    DWORD winMode = 0;
    long nPos;

    switch (mode) {
    case SEEK_SET:
	winMode = FILE_BEGIN;
	break;
    case SEEK_CUR:
	winMode = FILE_CURRENT;
	break;
    case SEEK_END:
	winMode = FILE_END;
	break;
    }

    nPos = SetFilePointer((HANDLE)file, dist, NULL, winMode);
    /*
     * handle Windows error value of 0xFFFFFFFF the same as others*/
    if (nPos == 0xFFFFFFFF) {
	return (-1L);
    }
    return nPos;
#endif
}	/* End of FileUtil_Seek.	*/


/***********************************************************************
 *				FileUtil_Close
 ***********************************************************************
 *
 * SYNOPSIS:	    closes the file
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    (success)TRUE or (failure)FALSE
 * SIDE EFFECTS:    file is closed and released
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_Close(FileType file)
{
#if defined(unix) || defined(_LINUX)
    return fclose(file);
#elif defined(_MSDOS)
    int returnCode;

    returnCode = close(file);
    if (returnCode == -1) {
	return FALSE;
    }
    return TRUE;
#elif defined(_WIN32)
    return CloseHandle((HANDLE)file);
#endif
}	/* End of FileUtil_Close.	*/


/***********************************************************************
 *				FileUtil_Getc
 ***********************************************************************
 *
 * SYNOPSIS:	    Reads a character from the file - slowly
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    the character read (EOF if at end of file)
 * SIDE EFFECTS:    file position is incremented by one
 *
 * STRATEGY:	    This is much slower than the comparable getc function
 *			because it doesn't take advantage of large reads
 *			and buffering of the data.  Not recommended for
 *			reading large quantities of data.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_Getc(FileType file)
{
#if defined(unix) || defined(_LINUX)
    return getc(file);
#elif defined(_MSDOS) || defined(_WIN32)
    int returnCode;
    unsigned char c;
    long bytes = 0;

    returnCode = FileUtil_Read(file, &c, 1, &bytes);
    if ((returnCode == TRUE) && (bytes == 1)) {
	return (int)c;
    } else {
	return (int)EOF;
    }
#endif
}	/* End of FileUtil_Getc.	*/


/***********************************************************************
 *				FileUtil_Ftell
 ***********************************************************************
 *
 * SYNOPSIS:	    Get the file position of the file
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    position in the file
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
long
FileUtil_Ftell(FileType file)
{
#if defined(unix) || defined(_LINUX)
    return ftell(file);
#else
    return FileUtil_Seek(file, 0L, SEEK_CUR);
#endif
}	/* End of FileUtil_Ftell. */


/***********************************************************************
 *				FileUtil_GetTime
 ***********************************************************************
 *
 * SYNOPSIS:	    Get the time the file was last modified
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    last modified time as int
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
time_t
FileUtil_GetTime(FileType file)
{
#if defined(unix) || defined(_LINUX)
    int 		i;
    struct stat		stb;
#elif defined(_WIN32)
    int returnCode;
    FILETIME		ftCreation;
    FILETIME		ftLastAccess;
    FILETIME		ftLastWrite;
#elif defined(_MSDOS)
    int 		i;
    unsigned int	fdate, ftime;
#endif

#if defined(unix) || defined(_LINUX)
#if defined(_LINUX)
    i = fstat(file->_handle, &stb);
#else
    i = fstat(file->_file, &stb);
#endif
    if (i < 0) {
	return i;
    }
    return stb.st_mtime;
#elif defined(_WIN32)
    returnCode = GetFileTime((HANDLE)file,
			     &ftCreation,
			     &ftLastAccess,
			     &ftLastWrite);
    if (returnCode == TRUE) {
	long t = ftLastWrite.dwLowDateTime;
	return (t < 0) ? (t * -1) : t;
    } else {
	return (-1);
    }
#elif defined(_MSDOS)
    i = (_dos_getftime(file, &fdate, &ftime) ? -1 : 0);
    if (i < 0) {
	return i;
    }
    return (fdate << 16) | ftime;
#endif
}	/* End of FileUtil_GetTime. */


/***********************************************************************
 *				FileUtil_PrintError
 ***********************************************************************
 *
 * SYNOPSIS:	    Print the latest error after the formatted text
 *		    passed in (if fmt != NULL)
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    none
 * SIDE EFFECTS:    Outputs text to the screen.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
void
FileUtil_SprintError(char *result, char *fmt, ...)
{
#if defined(_WIN32)
    LPVOID lpMessageBuffer;
#endif

    *result = '\0';
    if (fmt != NULL) {
	va_list argList;

	va_start(argList, fmt);
	vsprintf(result, fmt, argList);
	while(*result != 0) {
	    result++;
	}
	va_end(argList);
    }
#if defined(unix) || defined(_MSDOS) || defined(_LINUX)
    if (errno < sys_nerr) {
	sprintf(result, ": %s: error #%d\n", sys_errlist[errno], errno);
    }
#elif defined(_WIN32)
    /*
     * This turns GetLastError() into a human-readable string.
     */
    (void) FormatMessage(
	FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
	NULL,
	GetLastError(),
	MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), /* user default language */
	(LPTSTR) &lpMessageBuffer,
	0,
	NULL);			/* #1 */

    sprintf(result, ": %serror #%d\n", (char *)lpMessageBuffer,
	    GetLastError());

    LocalFree(lpMessageBuffer);	/* #1 */
#endif
    while(*result != 0) {
	result++;
    }

}	/* End of FileUtil_PrintError. */


/***********************************************************************
 *				FileUtil_GetError
 ***********************************************************************
 *
 * SYNOPSIS:	    Returns the integer value of the latest error
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    error value
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_GetError(void)
{
#if defined(unix) || defined(_MSDOS) || defined(_LINUX)
    return errno;
#elif defined(_WIN32)
    return GetLastError();
#endif
}	/* End of FileUtil_GetError. */

#if defined(_WIN32)

/***********************************************************************
 *				FileUtil_TestFat
 ***********************************************************************
 *
 * SYNOPSIS:	    Detects if fileSystem is limited 8.3 file names or not
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    8.3 - TF_FAT, not 8.3 - TF_NONFAT, error - TF_ERROR
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/26/96   	Initial Revision
 *
 ***********************************************************************/
int
FileUtil_TestFat(const char *absPath)
{
    char root[10];
    BOOL success;
    DWORD mcl;

    if (absPath[1] != ':') {
	return TF_ERROR;
    } else {
	/*
	 * copy only the drive letter and the colon and then append a
	 * backslash
	 */
	strncpy(root, absPath, 2);
	root[2] = '\\';
	root[3] = '\0';
    }
    success = GetVolumeInformation(root,
				   NULL,
				   0,
				   NULL,
				   &mcl,
				   NULL,
				   NULL,
				   0);
    if (success == TRUE) {
	if (mcl > 12) {
	    return (TF_NONFAT);		/* not 8.3 */
	} else {
	    return (TF_FAT);		/* 8.3 */
	}
    } else {
	return (TF_ERROR);		/* problem */
    }
}	/* End of FileUtil_TestFat. */
#endif
