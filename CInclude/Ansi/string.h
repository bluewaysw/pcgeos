/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:        GEOS
MODULE:         Standard C Library
FILE:           string.h

AUTHOR:         Tony Requist

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	Tony    91.02.01        Initial version.
	JDM     93.03.23        Updated.

DESCRIPTION:
	This file contains the GEOS implementation of the Standard C
	library string.h file.

	$Id: string.h,v 1.1 97/04/04 15:50:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef __STRING_H
#define __STRING_H

/* Define NULL if it hasn't been already.       */
#ifndef NULL
#define NULL    (0)
#endif

#include <geos.h>

/* Define size_t.	*/
typedef	unsigned int size_t;

extern void
  *_pascal memchr (const void *__s, int __c, size_t __n);

extern int
  _pascal memcmp (const void *__dest, const void *__src, size_t __n);

extern void
  *_pascal memcpy (void *__dest, const void *__src, size_t __n);

extern void
  *_pascal memmove (void *__dest, const void *__src, size_t __n);

extern void
  *_pascal memset (void *__dest, int __c, size_t __n);

extern word
  _pascal strlen (const TCHAR *__str);
extern word
  _pascal STRLEN (const TCHAR *__str);

extern TCHAR
  *_pascal strchr (const TCHAR *__s, int __c);

extern TCHAR
  *_pascal strrchr (const TCHAR *__s, int __c);

/*
 * WARNING: Only use "strcmp()" and "strncmp()" if:
 *
 *      a) You only want to know if the 2 strings are equal or not
 *
 *              - or -
 *
 *      b) You are sure that the 2 strings consist entirely of standard
 *         ASCII characters.
 *
 *      If you need to know the lexicographical order of the strings, and if
 *      the strings can contain extended-ASCII characters (values > 0x80), you
 *      should be calling "LocalCmpStrings()".
 *
 *      Also, you may not make any assumptions as to whether a character is
 *      a byte, or a word.
 *
 */
extern int
  _pascal strncmp (const TCHAR *__s, const TCHAR *__t, const size_t __n);

extern int
  _pascal strcmp (const TCHAR *__s, const TCHAR *__t);

extern TCHAR
  *_pascal strcat (TCHAR *__s, const TCHAR *__t);
extern TCHAR
  *_pascal strncat (TCHAR *__s, const TCHAR *__t, const size_t __n);

extern TCHAR
  *_pascal strcpy(TCHAR *__s, const TCHAR *__t);
extern TCHAR
  *_pascal strncpy (TCHAR *__s, const TCHAR *__t, const size_t __n);

extern word
  _pascal strcspn (const TCHAR *__s, const TCHAR *__set);

extern word
  _pascal strspn (const TCHAR *__s, const TCHAR *__set);

extern TCHAR
  *_pascal strpbrk (const TCHAR *__s, const TCHAR *__set);

extern TCHAR
  *_pascal strstr(const TCHAR *__s, const TCHAR *__t);

#define strcoll(s,t) LocalCmpStrings((s),(t),0)

/*
 * For DBCS, SBCS versions
 */
#ifdef DO_DBCS
extern word
  _pascal strlensbcs (const TCHAR *__str);
extern word
  _pascal STRLENSBCS (const char *__str);
extern char
  *_pascal strchrsbcs (const char *__s, int __c);
extern char
  *_pascal strrchrsbcs (const char *__s, int __c);
extern int
  _pascal strncmpsbcs (const char *__s, const char *__t, const size_t __n);
extern int
  _pascal strcmpsbcs (const char *__s, const char *__t);
extern char
  *_pascal strcatsbcs (char *__s, const char *__t);
extern char
  *_pascal strncatsbcs (char *__s, const char *__t, const size_t __n);
extern char
  *_pascal strcpysbcs(char *__s, const char *__t);
extern char
  *_pascal strncpysbcs (char *__s, const char *__t, const size_t __n);
extern word
  _pascal strcspnsbcs (const char *__s, const char *__set);
extern word
  _pascal strspnsbcs (const char *__s, const char *__set);
extern char
  *_pascal strpbrksbcs (const char *__s, const char *__set);
extern char
  *_pascal strstrsbcs(const char *__s, const char *__t);
#endif

#ifdef __HIGHC__
pragma Alias(memchr,    "MEMCHR");
pragma Alias(memcmp,    "MEMCMP");
pragma Alias(memcpy,    "MEMCPY");
pragma Alias(memmove,   "MEMMOVE");
pragma Alias(memset,    "MEMSET");
pragma Alias(strlen,    "STRLEN");
pragma Alias(strchr,    "STRCHR");
pragma Alias(strrchr,   "STRRCHR");
pragma Alias(strncmp,   "STRNCMP");
pragma Alias(strcmp,    "STRCMP");
pragma Alias(strcat,    "STRCAT");
pragma Alias(strncat,   "STRNCAT");
pragma Alias(strcpy,    "STRCPY");
pragma Alias(strncpy,   "STRNCPY");
pragma Alias(strcspn,   "STRCSPN");
pragma Alias(strspn,    "STRSPN");
pragma Alias(strpbrk,   "STRPBRK");
pragma Alias(strstr,    "STRSTR");

#endif

#endif
