/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  GEOS Tools
 * MODULE:	  dirent.h
 * FILE:	  dirent.h
 *
 * AUTHOR:  	  Adam de Boor: Jul  9, 1992
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 9/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Interface to Dir functions.
 *
 *
 * 	$Id: dirent.h,v 1.2 97/04/17 17:15:17 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _COMPAT_DIRENT_H_
#define _COMPAT_DIRENT_H_

#ifdef HAVE_DIRENT
#if defined(__WATCOMC__)
#if defined(_LINUX)
# include <dirent.h>
#else
# include <direct.h>
#endif
#else
# include <dirent.h>
#endif
/*
 * Many people still use the obsolete struct direct, which isn't defined
 * by dirent.h.
 */
# define direct dirent
#else

#if defined(_MSC_VER) && defined(_WIN32)
#    define WIN32_LEAN_AND_MEAN
#    define STRICT
#    include <compat/windows.h>                /* for MAX_PATH */
#endif /* defined(_MSC_VER) && defined(_WIN32) */

#define MAXNAMLEN   13

struct direct {
    unsigned long   d_fileno;	    	/* File number of entry
					 * (index into dir, starting with 1) */
    unsigned short  d_reclen;	    	/* Length of this record */
    unsigned short  d_namlen;	    	/* Length of string in d_name */

#if defined (_MSC_VER) && defined(_WIN32)
    char            d_name[MAX_PATH + 1];
#else
    char    	    d_name[MAXNAMLEN+1];/* File name. */
#endif /* defined(_MSC_VER) && defined(_WIN32) */

};

#define d_ino d_fileno

typedef void	DIR;

extern DIR *opendir(const char *path);
extern const struct direct *readdir(DIR *dirp);
extern void rewinddir(DIR *dirp);
extern int closedir(DIR *dirp);

#endif /* !HAVE_DIRENT */

#endif /* _COMPAT_DIRENT_H_ */
