/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  Unix compatibility library
 * FILE:	  config.h
 *
 * AUTHOR:  	  Jacob A. Gabrielson: May  2, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	5/ 2/96   	Initial version
 *
 * USAGE:
 *	Every .c file under Tools should include <config.h> before
 *	anything else (or if there's a global header file for the 
 *	tool, like "esp.h", then <config.h> should be included
 *	there.)
 *
 *	Do not include any of the following .h files in any .c
 *	or .h files:
 *
 *	#include <stdlib.h>
 *	#include <strings.h>
 *	#include <string.h>
 *	#include <dirent.h>
 *	#include <windows.h>
 *
 *	Instead include the following, where needed:
 *
 *	#include <compat/stdlib.h>
 *	#include <compat/string.h>
 *	#include <compat/dirent.h>
 *	#include <compat/windows.h>
 *
 *	Always include 'em after <config.h>
 *
 *      Similarly, use #include <compat/file.h> instead of any and 
 *	all of the following:
 *
 *        sys/file.h
 *        io.h
 *        fcntl.h
 *        sys/stat.h
 *        stat.h
 *        dos.h (if you're including compat/file.h anyway)
 *
 * DESCRIPTION:
 *	Including this file gets you the following things:
 *
 *	- Prototypes for functions that are not already supported
 *	  by your system (e.g., in Windows NT, you'll get a prototype 
 *	  for getopt()).  These functions are implemented in the
 *	  compatibility library (compat.dll under Windows NT).
 *
 *	- Defines or undefines a constant for every Unix routine 
 *	  that might possibly be missing from your system (e.g., HAVE_FFS 
 *	  will be defined if your system already supports it, undefined
 *	  otherwise).
 *	  
 *	- Defines macros if your system supports a routine but has it
 *	  under a different name (e.g., it #define's bcopy to to
 *	  memcpy under Windows NT).
 *
 * 	- Defines the directory separator (/ or \) and a macro to
 *        recognize directory separators.  OS-dependent.
 *
 *	- Defines how to declare labels in structs.  It's either
 *	  char foo[] or char foo[0].  We define LABEL_IN_STRUCT
 *	  to be either nothing or 0.  Compiler-dependent.
 *
 *      Some of these features are directly provided by this file,
 *	and some are provided by whichever .h files it includes.
 *
 * ORGANIZATION:
 *	This file is split up into several parts, in order:
 *
 *	- #define's all the routines that the library has
 *	  emulation versions of (e.g. #define HAVE_GETOPT), under
 *	  the assumption that your OS already supports the
 *	  routine.
 *
 *	- #include's the file cm-xxx.h based on which compiler
 *	  you're using (e.g., cm-bor.h if __BORLANDC__ is 
 *	  defined).
 *	
 *	- #include's the file os-xxx.h based on which OS
 *	  you're compiling under (e.g., if _WIN32 is defined, then
 *	  it includes os-win32.h).
 *
 *	- Both the cm-xxx.h and os-xxx.h are responsible for either
 *	  #define'ing HAVE_<whatever> for each routine the compiler
 *	  or OS supports, or else #define'ing a macro that maps
 *	  f'rinstance, bcopy() to memcpy().
 *	   
 *	- After including the os-dependent .h file, we include
 *	  prototypes for any routines that have not been #define'd.
 *	
 *	  The source code for these routines is found in Tools/compat.
 *
 * 	$Id: config.h,v 1.1 96/05/18 14:51:25 jacob Exp $
 *
 ***********************************************************************/
#ifndef _CONFIG_H_
#define _CONFIG_H_

/***********************************************************************
 *
 * List possible #define's for all the routines we can support.
 *
 * NOTES: KEEP THIS LIST SORTED IN ALPHABETICAL ORDER!
 *
 *	  This is just a list of all the possible routines your
 *	  compiler/OS *may* support.  It's up to your cm-xxx.h
 *	  and os-xxx.h to #define these as appropriate.
 *
 *	  The os-unix.h file doesn't need to #define these,
 *	  since we define 'em here.
 *
 ***********************************************************************/

#if defined(unix)

#define HAVE_BCMP

#define HAVE_BCOPY

#define HAVE_BZERO

#define HAVE_DIRENT /* opendir, readdir, rewinddir, closedir  */

#define HAVE_FFS

#define HAVE_GETOPT

#define HAVE_GETPAGESIZE

#define HAVE_ISINF

#define HAVE_INDEX /* index, rindex */

#define HAVE_MKSTEMP

#define HAVE_QUEUE /* insque, remque */

#define HAVE_STRCASECMP

/*
 * Argh, SunOS doesn't have strerror(), so we can't define
 * HAVE_STRERROR here.
 */
/* #define HAVE_STRERROR */
 

#define HAVE_STRNCASECMP

#define HAVE_TIMELOCAL

#endif /* unix */

/***********************************************************************
 *
 * #include compiler-specific header file
 *
 * NOTES: These files define:
 *
 *	  - How to do labels in structs.
 *
 *	  - genptr: a generic pointer type upon which arithmetic
 *	    can be done at the byte level
 *
 *	  - #defines inline to nothing if inline is not supported,
 *	    or else #defines it to whatever that compiler expects
 *	    (i.e. _Inline in HighC).
 *
 *	  - #define HAVE_<whatever> where appropriate, if the
 *	    compiler's runtime library is known to support the
 *	    routine(s)
 *
 ************************************************************************/

#if defined(__BORLANDC__)
#    include <compat/cm-bor.h>
#elif defined(__GNUC__)
#    include <compat/cm-gcc.h>
#elif defined(__HIGHC__)
#    include <compat/cm-highc.h>
#elif defined(_MSC_VER)
#    define __BORLANDC__                  /* define this for microsoft since
					   * almost all of the borland 
					   * conditional compiles work for
					   * microsoft as well */
#    include "compat\cm-msc.h"
#else
#    error Your compiler is not supported
#endif

/***********************************************************************
 *
 * #include OS-specific header file
 *
 * NOTES: The files we include here are responsible for the following:
 *
 *	  - #define HAVE_<whatever> where appropriate, if the
 *	    OS is known to support the routine(s)
 *
 *	  - defining macros, where possible, for routines that
 *	    exist under a different name (i.e. bcopy on NT).
 *
 *	  - defining DIR_SEP and IS_DIR_SEP
 *
 ************************************************************************/

#if defined(_WIN32) || defined(__WIN32__)

/*
 * Microsoft C defines _WIN32, Borland defines __WIN32__.  We make
 * sure _WIN32 is defined.  We'll use _WIN32 in code, since
 * it's shorter.
 */
#ifndef _WIN32
#define _WIN32 1
#endif

/* 
 * Note: Win32 means BOTH Windows 95 and Windows NT, although there
 * are some differences in practice.  Even so, we really don't want 2
 * different binaries for Win95 and NT.  For now, keep NT and Win95
 * specific code surrounded by run-time, rather than compile-time
 * checks.
 */
#include "compat\os-win32.h"

#elif defined(unix)
/*
 * For now, we're making the completely false assumption that 
 * Unix == SunOS.  If we ever support more versions of Unix, then
 * this will have to change.
 */
#include <compat/os-unix.h>

#elif defined(_MSDOS)
/*
 * Note: for now, and probably for ever, _MSDOS really means _MSDOS
 * with PharLap extender.
 */
#include <compat/os-msdos.h>

#else
#error Your OS is not yet supported
#endif

#if !defined(QUOTED_SLASH) || !defined(IS_PATHSEP)
#error Missing macro definition(s) in OS-specific header file
#endif

/***********************************************************************
 *
 * Prototypes for all the simple Unix compatibility routines we provide.  
 * Routines that take non-fundamental types as arguments have their own
 * header files.  See the comments to find out which header file.
 *
 ***********************************************************************/

#ifndef HAVE_BCMP
extern int bcmp(genptr b1, genptr b2, unsigned len);
#endif

#ifndef HAVE_BCOPY
extern void bcopy(genptr src0, genptr dst0, unsigned length);
#endif

#ifndef HAVE_BZERO
extern void bzero(void *dst, unsigned len);
#endif

#ifndef HAVE_DIRENT
/*
 * #include <compat/dirent.h> in .c files that need these, regardless
 * of whether HAVE_DIRENT is defined or not.
 */
#endif

#ifndef HAVE_FFS
extern int ffs(int n);
#endif

#ifndef HAVE_GETOPT
extern int getopt(int nargc, char **nargv, char *ostr);
extern char *optarg;
extern int optind;
extern int opterr;
#endif

#ifndef HAVE_GETPAGESIZE
extern int getpagesize(void);
#endif

#ifndef HAVE_INDEX
/*
 * I'm assuming you have strchr and strrchr, since they're
 * ANSI.
 */
#define index(s,c) strchr(s,c)
#define rindex(s,c) strrchr(s,c)
#endif

#ifndef HAVE_ISINF
extern int isinf(double x);
#endif

#ifndef HAVE_MKSTEMP
extern int mkstemp(char *template);
#endif

#ifndef HAVE_QUEUE
/*
 * #include <compat/queue.h> in .c files that need these.
 */
#endif

#ifndef HAVE_STRCASECMP
/*
 * I'm assuming you have this, everyone seems to have either one
 * or the other.
 */
#define strcasecmp strcmpi
#endif

#ifndef HAVE_STRNCASECMP
/*
 * Ditto.
 */
#define strncasecmp strncmpi
#endif

#ifndef HAVE_STRERROR
/*
 * I'm still assuming you have errno.h and that sys_errlist[] is there.
 * Also, I'm assuming this is SunOS.  SunOS doesn't put externs for sys_nerr
 * or sys_errlist in any header file that I'm aware of.
 */
extern int sys_nerr;
extern char *sys_errlist[];
#define strerror(err) ((sys_nerr > (err)) ? sys_errlist[err] : "unknown error")
#endif

#ifndef HAVE_TIMELOCAL
/*
 * Check to see if your OS supports this (it's probably called
 * mktime).  If so, add a macro to os-xxx.h.  If not, you
 * have some nasty work ahead of you :-)
 */
#endif

/***********************************************************************
 *
 * Prototypes for new routines that help you do things portably.
 * Currently, this just seems to be for manipulating filenames.
 *
 ***********************************************************************/

extern char *Compat_LastPathSep (char *path);
extern char *Compat_FirstPathSep (char *path);
extern char *Compat_GetCwd (char *cwd, int maxLength);
extern char *Compat_GetTrailingPath (char *component, char *path);
extern char *Compat_GetNextComponent (char *component, char *path);
extern void Compat_CanonicalizeFilename (char *path);
extern char *Compat_GetPathTail(char *path);

extern char *strstri(char *string, char *substring);

#endif /* _CONFIG_H_ */
