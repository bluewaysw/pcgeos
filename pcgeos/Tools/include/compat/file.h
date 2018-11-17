/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  file.h
 *
 * AUTHOR:  	  Ron Braunstein: Jul 09, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ron	7/09/96   	Initial version
 *
 * DESCRIPTION:
 *	Things to be done to get file access to work seamlessly across
 *      platforms.
 *
 *
 * 	$Id: file.h,v 1.4 1997/04/10 00:17:45 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _COMPATFILE_H_
#define _COMPATFILE_H_

#if defined(unix)
# include <sys/file.h>
# include <unistd.h>
#elif defined(_LINUX)
/*# include <sys/file.h>*/
# include <unistd.h>
# include <fcntl.h>
#elif defined(_MSDOS) || defined(_WIN32)
# include <io.h>
# include <stdio.h>
# include <fcntl.h>
# include <share.h>
# include <direct.h>
# if defined(_MSDOS)
#  include <stat.h>
# else  /* _WIN32 specific */
#  include <sys/stat.h>
# endif
# define F_OK 0
# define W_OK 2
# define R_OK 4
#endif

#if defined(unix) || defined(_MSDOS)
# if !defined(SEEK_SET)
#  define SEEK_SET L_SET
# endif

# if !defined(SEEK_CUR)
#  define SEEK_CUR L_INCR
# endif

# if !defined(SEEK_END)
#  define SEEK_END L_XTND
# endif
#endif

#if defined(unix) || defined(_LINUX)
# define SH_DENYWR	0
# define SH_DENYRD	0
# define SH_DENYRW	0
# define SH_DENYNO	0
#if !defined(_LINUX)
# define SH_DENYNONE	0
#endif
#endif

#if defined(_MSDOS)
# include <dos.h>
# include <stat.h>
#endif

#ifndef S_IRUSR
#define S_IRUSR 0
#endif

#ifndef S_IWUSR
#define S_IWUSR 0
#endif

#ifndef S_IROTH
#define S_IROTH 0
#endif

#ifndef S_IWOTH
#define S_IWOTH 0
#endif

#ifdef unix
#define O_BINARY 0
#define O_TEXT   0
#endif

#if defined(_MSC_VER) || defined(__WATCOMC__)
#define L_SET SEEK_SET
#define L_INCR SEEK_CUR
#define L_XTND SEEK_END
#define SH_DENYNONE SH_DENYNO
#endif /* defined _MSC_VER */

#endif /* _COMPATFILE_H_ */
