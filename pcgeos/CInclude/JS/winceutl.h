/* winceutl.h
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#if defined(__JSE_WINCE__) && !defined(_WINCEUTL_H)
#define _WINCEUTL_H

#include "cestdio.h"

#include <tchar.h>
#include <ctype.h>
#include <wtypes.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <windows.h>
#include <commdlg.h>
#include <commctrl.h>
#include <Ndis.h>
#include <winreg.h>
#include <winuser.h>
#include <winbase.h>
#include <wingdi.h>
#include <ntcompat.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(JSE_WIN_ASM)
#   undef JSE_WIN_ASM
#endif

#if defined(__SEISDKSAMPLES__) && defined(JSE_WIN_ANY)
#   undef JSE_WIN_ANY
#endif

/* <string.h> */

char *strerror( int errnum );

/* <stdio.h> */

#define _TEOF       WEOF
#define _ltot       _ltow
#define _tcsclen    _tcslen
#define _tcsnccpy   _tcsncpy
#define _tcsnccmp   _tcsncmp
#define _tcsncicmp  _tcsnicmp
#define _tcsnccat   _tcsncat

#include "jsetypes.h"
#include "jselib.h"
#include "seuni.h"

extern jsecharptr * _tenviron;
jsebool UniFileFlag;

#define stdin  (FILE *)1
#define stdout (FILE *)2
#define stderr (FILE *)3

#define _tfopen(s,t)       fopen((LPWSTR)s,(LPWSTR)t)
#define fputws(s,t)        fputs((LPWSTR)s,t)
#define fputwc(c,t)        fputc((LPWSTR)c,t)
#define fgetws             fgets
#define fgetwc             fgetc
#define fwprintf           fprintf

FILE *_tfreopen( const jsecharptr path, const jsecharptr mode, FILE *stream );
/*int fseek( FILE *stream, long offset, int origin ); */
/*int fclose( FILE *stream ); */
int fflush( FILE *stream );
int vfwprintf( FILE *stream, const jsecharptr format, va_list argptr );
FILE *tmpfile( void );
wint_t _ungettc( wint_t c, FILE *stream );
int _tremove( const jsecharptr FileName );
int _trename( const jsecharptr oldname, const jsecharptr newname );
jsecharptr _ttmpnam( jsecharptr string );
#define L_tmpnam 200
void _tperror( const jsecharptr string );

typedef long int fpos_t;

int fgetpos( FILE *stream, fpos_t *pos );
int fsetpos( FILE *stream, const fpos_t *pos );
void rewind( FILE *stream );
void clearerr( FILE *stream );
int ferror( FILE *stream );
int feof( FILE *stream );

jsecharptr getenv( const jsecharptr varname );

int _fileno( FILE *stream );
#define fileno _fileno


/* <conio.h> */
int getch( void );

/* <stdlib.h> */
void exit( int status );
int _tsystem( const jsecharptr command );
void abort(void);
jsecharptr _tfullpath( jsecharptr absPath, const jsecharptr relPath, size_t maxLength );

const jsecharptr
MakeCompletePath( jseContext jsecontext, const jsecharptr partial );
jsebool isDir( const jsecharptr partial );


/* <stddef.h> */
typedef unsigned int size_t;

/* <sys\stat.h> */
int _tstat( const jsecharptr path, struct _stat *buffer );

/* <direct.h> */
int _tchdir( const jsecharptr dirname );
jsecharptr _tgetcwd( jsecharptr buffer, int maxlen );
int _tmkdir( const jsecharptr dirname );
int _trmdir( const jsecharptr dirname );

/* <math.h> */
double atof( const char *string );

/* <search.h> */
void *bsearch( const void *key, const void *base, size_t num, size_t width,
               int ( __cdecl *compare ) ( const void *elem1, const void *elem2 ) );

/* <time.h> */

typedef long clock_t;

 double NEAR_CALL DayFromYear(slong y);
 long NEAR_CALL DaysInYear(long y);
 int NEAR_CALL SetDayLightSavingTime(long year, time_t thetime);


struct tm {
        int tm_sec;     /* seconds after the minute - [0,59] */
        int tm_min;     /* minutes after the hour - [0,59] */
        int tm_hour;    /* hours since midnight - [0,23] */
        int tm_mday;    /* day of the month - [1,31] */
        int tm_mon;     /* months since January - [0,11] */
        int tm_year;    /* years since 1900 */
        int tm_wday;    /* days since Sunday - [0,6] */
        int tm_yday;    /* days since January 1 - [0,365] */
        int tm_isdst;   /* daylight savings time flag */
        };

#define CLOCKS_PER_SEC  1000

time_t time( time_t *timer );
clock_t clock( void );
jsecharptr _tctime( const time_t *timer );
time_t mktime( struct tm *timeptr );
jsecharptr _tasctime( const struct tm *timeptr );
struct tm *gmtime( const time_t *timer );
struct tm *localtime( const time_t *timer );
size_t _tcsftime( jsecharptr string, size_t maxsize, const jsecharptr format, const struct tm *timeptr );

/* <timeb.h> */
struct _timeb {
   time_t time;
   unsigned short millitm;
   short timezone;
   short dstflag;
   };

void _ftime( struct _timeb *timeptr );

#define timeb     _timeb
#define ftime     _ftime

/* <io.h> */
/*int _taccess( const jsecharptr path, int mode ); */
int _chsize( int handle, long size );
int _locking( int handle, int mode, long nbytes );

#define chsize    _chsize
#define locking   _locking

/* File attribute constants for _findfirst() */

#define _A_NORMAL 0x00  /* Normal file - No read/write restrictions */
#define _A_RDONLY 0x01  /* Read only file */
#define _A_HIDDEN 0x02  /* Hidden file */
#define _A_SYSTEM 0x04  /* System file */
#define _A_SUBDIR 0x10  /* Subdirectory */
#define _A_ARCH   0x20  /* Archive file */


/* <sys\stat.h> && <sys\types> */
/* define structure for returning status information */
typedef unsigned short _ino_t;
typedef unsigned int _dev_t;
typedef long _off_t;

#define ino_t _ino_t
#define dev_t _dev_t
#define off_t _off_t

struct _stat {
   _dev_t st_dev;
   _ino_t st_ino;
   unsigned short st_mode;
   short st_nlink;
   short st_uid;
   short st_gid;
   _dev_t st_rdev;
   _off_t st_size;
   time_t st_atime;
   time_t st_mtime;
   time_t st_ctime;
   };

#define _S_IFMT   0170000  /* file type mask */
#define _S_IFDIR  0040000  /* directory */
#define _S_IFCHR  0020000  /* character special */
#define _S_IFIFO  0010000  /* pipe */
#define _S_IFREG  0100000  /* regular */
#define _S_IREAD  0000400  /* read permission, owner */
#define _S_IWRITE 0000200  /* write permission, owner */
#define _S_IEXEC  0000100  /* execute/search permission, owner */

#define S_IFMT   _S_IFMT
#define S_IFDIR  _S_IFDIR
#define S_IFCHR  _S_IFCHR
#define S_IFREG  _S_IFREG
#define S_IREAD  _S_IREAD
#define S_IWRITE _S_IWRITE
#define S_IEXEC  _S_IEXEC

/* <sys\locking> */
#define _LK_UNLCK 0  /* unlock the file region */
#define _LK_LOCK  1  /* lock the file region */
#define _LK_NBLCK 2  /* non-blocking lock */
#define _LK_RLCK  3  /* lock for writing */
#define _LK_NBRLCK   4  /* non-blocking lock for writing */

#define LK_UNLCK    _LK_UNLCK
#define LK_LOCK     _LK_LOCK
#define LK_NBLCK    _LK_NBLCK
#define LK_RLCK     _LK_RLCK
#define LK_NBRLCK   _LK_NBRLCK

/* <assert.h> */

/* ASSERT only evaluate the expressiosn passed
 * to it when the _DEBUG flag has been defined.  */

#ifndef NDEBUG

#ifdef ASSERT
#undef ASSERT
#endif

#define ASSERT(x) ((x)? 0 : (DbgPrint("Assertion %s failed at %d in %s\n",#x,__LINE__,__FILE__),DbgBreakPoint(),1))

#define ASSERTSTATUS(s) ASSERT(NT_SUCCESS((s)))
#define ASSERTOBJ(o,s) ASSERT((o) && ((o)->Signature == (s)))

#else
#define ASSERT(x)
#define ASSERTSTATUS(s)
#define ASSERTOBJ(o,s)
#endif

#define assert ASSERT



/****************************************************************************/

/* following issues are related to API calls which unsupported by Windows CE*/

#define  HDROP                    HANDLE

#define  SW_RESTORE               SW_SHOWNORMAL
#define  SM_CXFRAME               SM_CXFIXEDFRAME
#define  SM_CYFRAME               SM_CYFIXEDFRAME

#define  SIZENORMAL               SIZE_RESTORED
#define  SIZEFULLSCREEN           SIZE_MAXIMIZED
#define  SIZEZOOMSHOW             SIZE_MAXSHOW

/*#define  SYSTEM_FIXED_FONT        SYSTEM_FONT */

#define  MB_TASKMODAL             MB_APPLMODAL
#define  MB_SYSTEMMODAL           MB_APPLMODAL

#define  GCL_HBRBACKGROUND        -10

typedef struct tagMINMAXINFO {
    POINT ptReserved;
    POINT ptMaxSize;
    POINT ptMaxPosition;
    POINT ptMinTrackSize;
    POINT ptMaxTrackSize;
} MINMAXINFO, *PMINMAXINFO, *LPMINMAXINFO;

#define  WM_GETMINMAXINFO         0x0024
#define  WM_NCCREATE              0x0081
#if defined(_WIN32_WCE_EMULATION)
#  define  WM_NCDESTROY           WM_APP-1
#else
#  define  WM_NCDESTROY           0x0082
#endif
#define  WM_DROPFILES             0x0233

#ifdef __cplusplus
}
#endif
#endif
