/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tool Utilities
 * FILE:	  FileUtil.h
 *
 * AUTHOR:  	  Dan Baumann, Sep 26, 1996
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	FileUtil_Open        Opens the file
 *      FileUtil_Read        Reads from the file
 *      FileUtil_Write       Writes to the file
 *      FileUtil_Seek        Positions within file
 *      FileUtil_Close       Closes the file
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	dbaumann	9/26/96   	Initial version
 *
 * DESCRIPTION:
 *      Cross platform interface to files.
 *
 *
 * 	$Id: fileUtil.h,v 1.3 97/05/27 16:18:48 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _FILEUTIL_H_
#define _FILEUTIL_H_

#include <time.h>
#include <stdio.h>

#if defined(unix) || defined(_LINUX)
typedef FILE *		FileType;
#elif defined(_MSDOS)
typedef int		FileType;
#elif defined(_WIN32)
/*
 * FileType is a HANDLE in WIN32, but since this is done in
 * windows.h and we want to avoid including that, it is typedeffed
 * to HANDLE's type
 */
typedef unsigned int	FileType;
#endif

int FileUtil_Open(FileType *file, const char *path, int oflags,
		  int sflags, int mode);
int FileUtil_Read(FileType file, unsigned char *buf, long len, long *nRead);
int FileUtil_Write(FileType file, const unsigned char *buf, long len,
		   long *nWrit);
int FileUtil_Seek(FileType file, long dist, int mode);
int FileUtil_Close(FileType file);

int FileUtil_Getc(FileType file);
long FileUtil_Ftell(FileType file);
time_t FileUtil_GetTime(FileType file);

int FileUtil_GetError(void);
void FileUtil_SprintError(char *result, char *fmt, ...);

#if defined(_WIN32)
#define TF_ERROR 	0
#define TF_FAT 		1
#define TF_NONFAT 	2
int FileUtil_TestFat(const char *path);
#endif

#if !defined(FALSE)
# define FALSE 0
#endif
#if !defined(TRUE)
# define TRUE 1
#endif

#endif /* _FILEUTIL_H_ */
