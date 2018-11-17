/* seuni.h     Handle Unicode, ASCII, MBCS, and such translations.
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

/*****************************************************************************
 * The non-ASCII routines within this file are designed to work with
 * Microsoft's Win32 MBCS / Unicode API.  If you are going to write your own
 * string handling functions, you must provide the following functions
 *****************************************************************************
 *
 * Functions to manipulate strings:
 *
 * The following functions are unicode versions of the standard C library
 * versions:
 *
 * stricmp_jsechar, strcpy_jsechar, etc...
 *
 * For a complete list of these fucntions, look at one of the sections
 * below.
 *
 *
 * UNISTR(x)
 *
 *    Provides a Unicode/Mbcs/Adcii string constant (x must be a string
 *    literal such as "hi")
 *
 * UNICHR(x)
 *
 *      Provides a Unicode/MBCS/Ascii character constant
 *
 * jsechar
 *
 *      A data type which represents the largest possible data size for any
 *      character (almost always 2 for MBCS and Unicode)
 *
 * jsecharptr
 *
 *      A data type which represents a pointer to a string of jsechar's.  Note
 *      that this may be different than simple (jsechar *).  For MBCS, this
 *      is defined as a (void *) to prevent bad accesses.
 *
 * jsecharptrdatum
 *
 *      A data type which represents the individual elements of a jsecharptr
 *      string.  Note that this may be different than a jsechar.  On MBCS
 *      systems, a jsechar will be 2 bytes, but the actual strings are still
 *      arrays of single characters.
 *
 * JSECHARPTR_INC(jsecharptr ptr)
 *
 *      Increments the data pointer by one logical character.
 *
 * jsechar JSECHARPTR_GETC(const jsecharptr ptr)
 *
 *      Gets a single logical character from this location.
 *
 * JSECHARPTR_PUTC(jsecharptr ptr, jsechar char)
 *
 *      Inserts the specified character at the specified location.  Note that
 *      for MBCS systems, the character may be of any size.
 *
 * jsecharptr JSECHARPTR_OFFSET(const jsecharptr ptr, size_t offset)
 *
 *      Finds the pointer offset within the string after the specified number
 *      of logical characters.  For unicode and ASCII, this simply performs
 *      a pointer addition, although for MBCS it is necessary to walk through
 *      the string until the appropriate offset is found.
 *
 * size_t JSECHARPTR_DIFF(const jsecharptr s1, const jsecharptr s2)
 *
 *      Finds the difference between s1 and s2 in logical characters.  s1 is
 *      guaranteed to be larger than s2 and to be situated on a character
 *      boundary.
 * jsecharptr JSECHARPTR_NEXT(const jsecharptr ptr)
 *
 *      Returns the location of the next character of the string.  This is
 *      similar to JSECHARPTR_OFFSET(ptr,1), except that for MBCS systems it
 *      can be accomplished in a single function call.
 *
 * size_t sizeof_jsechar(jsechar c)
 *
 *      Returns the size (in bytes) of the specified character.  For Unicode
 *      and ASCII, this will simply map to a constant sizeof(jsechar).  For
 *      MBCS, this function should return the actual size of the logical
 *      character.
 *
 * size_t bytestrlen_jsechar(const jsecharptr ptr)
 *
 *      Returns the length of the string, in bytes.
 *
 * size_t bytestrsize_jsechar(const jsecharptr ptr)
 *
 *      Returns the size of the string in bytes, including the terminating
 *      NULL character.
 *
 * STRCPYLEN_JSECHAR(jsecharptr dest, const jsecharptr src, size_t len )
 *
 *      This copies 'len' logical characters from 'src' to 'dest'.  The
 *      difference between this and a regular strncpy is that this
 *      function must take into account embedded NULLs and copy 'len'
 *      bytes total.
 *
 * int memcmp_jsechar(const jsecharptr s1, const jsecharptr s2, size_t len )
 *
 *      This function is exactly the same as strcmp_jsechar, except that
 *      it takes into account embedded NULLs and will always compare
 *      'len' logical characters between s1 and s2.
 *
 * size_t BYTECOUNT_FROM_STRLEN(const jsecharptr str, size_t len);
 *
 *      Given the length of the string in logical characters, this function
 *      will return the number of bytes in the string.  The difference
 *      between this function and bytestrlen_jsechar() is that this
 *      function takes into account embedded NULLs and will always return
 *      the total number of bytes needed for 'len' characters.
 *
 * CONST_STRING(name,string)
 *
 *      This is a simple macro which defines a string in this way:
 *      CONST_STRING(NAME,STRING)  CONST_DATA(jsecharptrdatum) NAME[] = STRING
 *
 * const char *JsecharToAscii(jsecharptr unistring)
 *
 *      Translates the given unicode/mbcs/ascii string into ascii and
 *      returns a buffer describing it. When you are finished with it,
 *      you must use 'FreeAsciiString().'
 *
 *
 * const jsecharptr AsciiToJsechar(char *asciistring)
 *
 *      Translates the given ascii string into unicode/mbcs/ascii and
 *      returns a buffer describing it. When you are finished with it,
 *      you must use 'FreeJsecharString().'
 *
 *
 * const jsecharptr AsciiLenToJsechar(char *asciistring,uword32 length)
 *
 *      Translates the given ascii string into unicode/mbcs/ascii (max of length
 *      chars) and returns a buffer describing it. When you are finished with it,
 *      you must use 'FreeJsecharString().'
 *
 *
 * void FreeAsciiString(const char *asciistring)
 *
 *      Frees up an ascii string returned from one of the other functions.
 *
 *
 * void FreeJsecharString(const jsecharptr asciistring)
 *
 *      Frees up an ascii string returned from one of the other functions.
 */

/*** revision history ***/
/*** revision history ***/

#ifndef _SEUNI_H
#define _SEUNI_H

#if defined(__JSE_NWNLM__)
#  include <nwlocale.h>
#  if defined JSE_NLM_WATCOM_HEADERS
      int NWstrlen(const char *string);
#  endif
#endif

/* JavaScript by default uses unicode character.  But some
 * implementations may wish to be more compact, faster, or
 * back-dated and will instead choose ascii.  In either case
 * if jsechar is used to represent characters then JSE_UNICODE
 * only needs to be redefined.  The other alternative is
 * JSE_MBCS, which can represent any number of multi-byte
 * character sets.  See SEUNI.H for more information.
 */
#if !defined(JSE_UNICODE)
#  if defined(JSE_MBCS) && (0!=JSE_MBCS)
#     define JSE_UNICODE 0 /* JSE_UNICODE and JSE_MBCS are incompatible */
#  else
#     if defined(__JSE_WINCE__)
#        define JSE_UNICODE 1
#     elif defined(__JSE_EPOC32__)
#        if defined(_UNICODE)
#           define JSE_UNICODE 1
#        else
#           define JSE_UNICODE 0
#        endif
#     else
#        define JSE_UNICODE 0
#     endif
#  endif
#endif
#if !defined(JSE_MBCS)
#  define JSE_MBCS 0 /* default no MBCS */
#endif
/* JSE_UNICODE and JSE_MBCS are incompatible */
#if (0!=JSE_UNICODE) && (0!=JSE_MBCS)
#  error JSE_UNICODE and JSE_MBCS are mutually exclusive
#endif

#if (defined(JSE_UNICODE) &&  (0!=JSE_UNICODE)) || \
    (defined(JSE_MBCS) && (0!=JSE_MBCS))

/********************************
 **** START UNICODE VERSIONS ****
 ********************************/

/*****************************
 **** START MBCS VERSIONS ****
 *****************************/

     /* These use the same functions */

#  if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
#     ifndef UNICODE
#        define UNICODE
#     endif
#     ifndef __UNICODE__
#        define __UNICODE__
#     endif
#     ifndef _UNICODE
#        define _UNICODE
#     endif
#  else
#     ifndef _MBCS
#        define _MBCS
#     endif
#  endif
#  if !defined(__JSE_NWNLM__)
#     include <tchar.h>
#  endif

#  if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
      typedef wchar_t   jsechar;
      typedef wchar_t   ujsechar;

#     define jsecharptr jsechar *
#     define jsecharhugeptr jsechar _HUGE_ *
#     define jsecharptrdatum  jsechar
#  else
      typedef uword16     jsechar;
      typedef uword16     ujsechar;

/********           TEMPRORARY DEBUGGING HELP          *********/
/******** Casting to void * assists conversion to MBCS *********/

#     if defined(__JSE_NWNLM__)
#        define jsecharptr       char *
#        define jsecharhugeptr   char *
#        define jsecharptrdatum  char
#        define real_jsecharptrdatum  char
#     else
#        if defined(__cplusplus)
#           define jsecharptr       char *
#           define jsecharhugeptr   char *
#        else
            /* for compiler warnings when used wrong */
#           define jsecharptr       void *
#           define jsecharhugeptr   void *
#        endif
#        define jsecharptrdatum  TCHAR
#        define real_jsecharptrdatum  TCHAR
#     endif
#     define real_jsecharptr       jsecharptrdatum *
#     define real_jsecharhugeptr   jsecharptrdatum _HUGE_ *

#  endif



#  if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
#     define JSECHARPTR_INC(JSECHAR)        ((JSECHAR)++)
#     define JSECHARPTR_GETC(JSECHAR)       (*((jsecharptr)(JSECHAR)))
#     define JSECHARPTR_PUTC(JSECHAR,C)     (*((jsecharptr)(JSECHAR))=C)
#     define JSECHARPTR_OFFSET(JSECHAR,OFF) (((jsecharptr)(JSECHAR))+(OFF))
#     define JSECHARPTR_NEXT(JSECHAR)       (((jsecharptr)(JSECHAR))+1)
#  if defined(__JSE_WINCE__) && defined(NDEBUG)
      /* Release version doesn't evaluate ASSERT*/
#     define JSECHARPTR_DIFF(S1,S2)         (S1-S2)
#  else
#     define JSECHARPTR_DIFF(S1,S2)         (assert(S1>=S2),(S1-S2))
#  endif
#     define int_jsechar         wint_t

#     define sizeofnext_jsechar(JSECHARPTR)  sizeof(jsechar)
#     define sizeof_jsechar(CHR)       sizeof(jsechar)
#     define bytestrlen_jsechar(STR)   (strlen_jsechar(STR)*sizeof(jsechar))
#     define bytestrsize_jsechar(STR)  ((strlen_jsechar(STR)+1)*sizeof(jsechar))
#     define STRCPYLEN_JSECHAR(DST,SRC,LEN)  memcpy(DST,SRC,(LEN)*sizeof(jsechar)), DST[LEN] = '\0'
#     define memcmp_jsechar(STR1,STR2,LEN)   memcmp(STR1,STR2,(LEN)*sizeof(jsechar))
#     define BYTECOUNT_FROM_STRLEN(STR,LEN)  ((LEN) * sizeof(jsechar))

#     define  CONST_STRING(NAME,STRING)  CONST_DATA(jsecharptrdatum) NAME[] = UNISTR(STRING)


#  else

      /**** MBCS Versions ***/
#     if defined(__JSE_NWNLM__)
#        define JSECHARPTR_GETC(JSECHAR)     NWCharVal(JSECHAR)
#        define JSECHARPTR_PUTC(STR,C);       { jsechar temp=C; NWstrncpy(STR,(jsecharptr)(&temp),1); }
         char *JSECHARPTR_OFFSET(const char *str, size_t offset);
#        define JSECHARPTR_NEXT(JSECHAR)     \
            (('\0'==*((char *)JSECHAR))?(jsecharptr)(JSECHAR+1):NWNextChar((jsecharptr)JSECHAR))
#        define JSECHARPTR_INC(JSECHAR)   JSECHAR = JSECHARPTR_NEXT(JSECHAR)
         size_t JSECHARPTR_DIFF(const char *s1, const char *s2);
#        define int_jsechar                  int
#        define sizeofnext_jsechar(JSECHARPTR)  sizeof_jsechar(JSECHARPTR_GETC(JSECHARPTR))
#        define sizeof_jsechar(C)            NWCharType(C)
#        define bytestrlen_jsechar(STR)      NWstrlen(STR)
#        define bytestrsize_jsechar(STR)     (NWstrlen(STR) + 1)
#     else
#        define JSECHARPTR_INC(JSECHAR)      ((JSECHAR) = _tcsinc((real_jsecharptr)JSECHAR))
#        define JSECHARPTR_GETC(JSECHAR)     ((jsechar)_tcsnextc((real_jsecharptr)(JSECHAR)))
         void JSECHARPTR_PUTC(jsecharptr ptr, jsechar c);
         real_jsecharptr JSECHARPTR_OFFSET(const jsecharptr str, size_t offset);
#        define JSECHARPTR_NEXT(JSECHAR)     _tcsinc((real_jsecharptr)(JSECHAR))
         size_t JSECHARPTR_DIFF(const jsecharptr s1, const jsecharptr s2);
#        define int_jsechar                  int
         /* This is faster than going a sizeof_jsechar(JSECHARPTR_GETC(ptr)) which does extra
          * calls which can be accomplished in just one call to _tclen.
          */
#        define sizeofnext_jsechar(JSECHARPTR)  _tclen((JSECHARPTR))
         size_t sizeof_jsechar(jsechar c);
#        define bytestrlen_jsechar(STR)      _tcslen(STR)
#        define bytestrsize_jsechar(STR)     (_tcslen(STR) + 1) /* All NULLs are 1 byte */
#     endif

      void STRCPYLEN_JSECHAR(jsecharptr dest, const jsecharptr src, size_t len);
      int memcmp_jsechar(const jsecharptr s1, const jsecharptr s2, size_t len );
      size_t BYTECOUNT_FROM_STRLEN(const jsecharptr str, size_t len);

#     define  CONST_STRING(NAME,STRING)  CONST_DATA(jsecharptrdatum) NAME[] = STRING

#  endif


#  if defined(__JSE_NWNLM__)
#     define UNISTR(x) x
#     define UNICHR(x) x
#     define stricmp_jsechar     NWLstricmp
#     define vsprintf_jsechar    NWvsprintf
#     define sprintf_jsechar     NWsprintf
#     define strstr_jsechar      NWLstrstr
#     define strspn_jsechar      NWLstrspn
#     define strcspn_jsechar     NWLstrcspn
#     define strtol_jsechar      strtol
#     define strtod_jsechar      strtod
#     define strpbrk_jsechar     NWLstrpbrk
#     define strrchr_jsechar     NWLstrrchr
#     define strchr_jsechar      NWLstrchr
#     define strlwr_jsechar      strlwr/*NWLstrlwr*/
#     define strupr_jsechar      NWLstrupr
#     define strnicmp_jsechar    strnicmp
#     define strncmp_jsechar     strncmp
#     define sscanf_jsechar      sscanf
      extern int NWLatoi(char *string);
#     define atoi_jsechar        NWLatoi

      extern int NWLisalnum(unsigned int ch);
#     define isalnum_jsechar     NWLisalnum
      extern int NWLisalpha(unsigned int ch);
#     define isalpha_jsechar     NWLisalpha
#     define isascii_jsechar     isascii
#     define iscntrl_jsechar     iscntrl
      extern int NWLisdigit(unsigned int ch);
#     define isdigit_jsechar     NWLisdigit
#     define isgraph_jsechar     isgraph
#     define islower_jsechar     islower
#     define isprint_jsechar     isprint
#     define ispunct_jsechar     ispunct
#     define isspace_jsechar     isspace
#     define isupper_jsechar     isupper
#     define isxdigit_jsechar    isxdigit
#     define toascii_jsechar     NWLtoascii
#     define tolower_jsechar     tolower
#     define toupper_jsechar     toupper

#     define strcmpi_jsechar     NWLstrcmpi
#     define strcpy_jsechar      strcpy
#     define strncpy_jsechar     NWstrncpy
#     define strcat_jsechar      strcat
#     define strncat_jsechar     strncat
#     define strcmp_jsechar      strcmp
      extern size_t strlen_jsechar(const jsecharptr str);
#     if !defined(JSE_THREADSAFE_POSIX_CRTL) || (0==JSE_THREADSAFE_POSIX_CRTL)
#        define strtok_jsechar      NWLstrtok
#     endif

#     define ltoa_jsechar        ltoa/*NWltoa*/
#     define atol_jsechar        atol
#     define atof_jsechar        NWatof
#     define perror_jsechar      NWperror
#     define system_jsechar      system

#     define fread_jsechar       fread
#     define fopen_jsechar       fopen
#     define freopen_jsechar     freopen
#     define _fsopen_jsechar     _fsopen
#     define gets_jsechar        gets
#     define fgets_jsechar       fgets
#     define fputs_jsechar       fputs
#     define fgetc_jsechar       fgetc
#     define fputc_jsechar       fputc
#     define fprintf_jsechar     /*NW*/fprintf
#     define printf_jsechar      NWprintf
#     define vfprintf_jsechar    /*NW*/vfprintf
#     define ungetc_jsechar      ungetc
#     define EOF_jsechar         EOF
#     define puts_jsechar        NWputs

#     define stat_struct         stat
#     define stat_jsechar        stat
#     define chdir_jsechar       chdir
#     define getcwd_jsechar      getcwd
#     define tmpnam_jsechar      tmpnam
#     define remove_jsechar      remove
#     define rename_jsechar      rename
#     define mkdir_jsechar       mkdir
#     define rmdir_jsechar       rmdir

#     if !defined(JSE_THREADSAFE_POSIX_CRTL) || (0==JSE_THREADSAFE_POSIX_CRTL)
#        define ctime_jsechar       ctime
#        define asctime_jsechar     asctime
#     endif
#     define strftime_jsechar    strftime
#     define _fullpath_jsechar   NW_fullpath
#     define access_jsechar      access

#     define environ_jsechar     environ
#  else

#     define UNISTR(x) _T(##x)
#     define UNICHR(x) ((jsechar)_T(##x))

#     define strstr_jsechar      _tcsstr
#     define strspn_jsechar      _tcsspn
#     define strcspn_jsechar     _tcscspn
#     define vsprintf_jsechar    _vstprintf
#     define sprintf_jsechar     _stprintf
#     define stricmp_jsechar     _tcsicmp
#     define strcat_jsechar      _tcscat
#     define strncat_jsechar     _tcsnccat
#     define strcmp_jsechar      _tcscmp
#     define strlen_jsechar      _tcsclen

#     define strnicmp_jsechar    _tcsncicmp
#     define strncmp_jsechar     _tcsnccmp
#     define sscanf_jsechar      _stscanf
#     define strtol_jsechar      _tcstol
#     define strtod_jsechar      _tcstod
#     define strpbrk_jsechar     _tcspbrk
#     define strrchr_jsechar     _tcsrchr
#     define strchr_jsechar      _tcschr
#     define strlwr_jsechar      _tcslwr
#     define strupr_jsechar      _tcsupr
#     if defined(JSE_THREADSAFE_POSIX_CRTL) && (0!=JSE_THREADSAFE_POSIX_CRTL)
#        define strtok_r_jsechar _tcstok_r
#     else
#        define strtok_jsechar   _tcstok
#     endif

#     define atoi_jsechar        _ttoi

#     define isalnum_jsechar     _istalnum
#     define isalpha_jsechar     _istalpha
#     define isascii_jsechar     _istascii
#     define iscntrl_jsechar     _istcntrl
#     define isdigit_jsechar     _istdigit
#     define isgraph_jsechar     _istgraph
#     define islower_jsechar     _istlower
#     define isprint_jsechar     _istprint
#     define ispunct_jsechar     _istpunct
#     define isspace_jsechar     _istspace
#     define isupper_jsechar     _istupper
#     define isxdigit_jsechar    _istxdigit
#     define toascii_jsechar     __toascii
#     define tolower_jsechar     _totlower
#     define toupper_jsechar     _totupper

#     define strcpy_jsechar      _tcscpy
#     define strncpy_jsechar     _tcsnccpy

#     define ltoa_jsechar        _ltot
#     define atol_jsechar        _ttol
#     define atof_jsechar        atof
#     define perror_jsechar      _tperror

#     define system_jsechar      _tsystem

#     define fopen_jsechar       _tfopen
#     define freopen_jsechar     _tfreopen
#     define _fsopen_jsechar     _tfsopen
#     define gets_jsechar        _getts
#     define fgets_jsechar       _fgetts
#     define fputs_jsechar       _fputts
#     define fgetc_jsechar       _fgettc
#     define fputc_jsechar       _fputtc
#     define fprintf_jsechar     _ftprintf
#     define printf_jsechar      _tprintf
#     define vfprintf_jsechar    _vftprintf
#     define ungetc_jsechar      _ungettc
#     define chdir_jsechar       _tchdir
#     define getcwd_jsechar      _tgetcwd
#     define EOF_jsechar         EOF
#     define puts_jsechar        _putts

#     define tmpnam_jsechar      _ttmpnam
#     define remove_jsechar      _tremove
#     define rename_jsechar      _trename
#     define mkdir_jsechar       _tmkdir
#     define rmdir_jsechar       _trmdir


#     if defined(JSE_THREADSAFE_POSIX_CRTL) && (0!=JSE_THREADSAFE_POSIX_CRTL)
#        define ctime_r_jsechar     _tctime_r
#        define asctime_r_jsechar   _tasctime_r
#     else
#        define ctime_jsechar       _tctime
#        define asctime_jsechar     _tasctime
#     endif
#     define strftime_jsechar    _tcsftime
#     define _fullpath_jsechar   _tfullpath
#     define access_jsechar      _taccess
#     if defined(__WATCOMC__) && __WATCOMC__==1100
#        define stat_struct      _wstat
#     else
#        define stat_struct       _stat
#     endif
#     define stat_jsechar        _tstat

#     define environ_jsechar     _tenviron

#  endif

#  define FreeAsciiString(x) jseMustFree((void *)x)
#  define FreeJsecharString(x) jseMustFree((void *)x)

#  if defined(__cplusplus)
      extern "C" {
#  endif
   const char * JsecharToAscii(const jsecharptr src);
   const jsecharptr AsciiLenToJsechar(const char * src,uword32 count);
   const jsecharptr AsciiToJsechar(const char * src);
#  if defined(__cplusplus)
   }
#  endif

/********************************
 **** END UNICODE VERSIONS ****
 ********************************/

#else

/******************************
 **** START ASCII VERSIONS ****
 ******************************/

   typedef char jsechar;
   typedef unsigned char ujsechar; /* sometimes a cast is needed in case system has signed char */

#  define jsecharptrdatum  jsechar
#  define jsecharptr jsechar *
#  define jsecharhugeptr jsechar _HUGE_ *

#  define UNISTR(x) x
#  define UNICHR(x) x

#  define JSECHARPTR_INC(JSECHAR)      ((JSECHAR)++)
#  define JSECHARPTR_GETC(JSECHAR)     (*(JSECHAR))
#  define JSECHARPTR_PUTC(JSECHAR,C)   (*(JSECHAR)=(C))
#  define JSECHARPTR_OFFSET(JSECHAR,N) ((JSECHAR)+(N))
#  define JSECHARPTR_NEXT(JSECHAR)     ((JSECHAR)+1)
#  define JSECHARPTR_DIFF(S1,S2)       (S1-S2)

#  define int_jsechar         int

#  define sizeof_jsechar(CHR)    1
#  define sizeofnext_jsechar(CHRPTR)  1
#  define bytestrlen_jsechar(STR)   strlen_jsechar(STR)
#  define bytestrsize_jsechar(STR)  (strlen_jsechar(STR)+1)
#  define STRCPYLEN_JSECHAR(DST,SRC,LEN)  memcpy(DST,SRC,LEN), DST[LEN] = '\0'
#  define memcmp_jsechar(STR1,STR2,LEN)   memcmp(STR1,STR2,LEN)
#  define BYTECOUNT_FROM_STRLEN(STR,LEN)  (LEN)

#ifdef DO_DBCS
#  define stricmp_jsechar     stricmp
#  define vsprintf_jsechar    vsprintfsbcs
#  define sprintf_jsechar     sprintfsbcs
#  define strstr_jsechar      strstrsbcs
#  define strspn_jsechar      strspnsbcs
#  define strcspn_jsechar     strcspnsbcs
#  define strtol_jsechar      strtol
#  define strtod_jsechar      strtod
#  define strpbrk_jsechar     strpbrksbcs
#  define strrchr_jsechar     strrchrsbcs
#  define strchr_jsechar      strchrsbcs
#  define strlwr_jsechar      strlwr
#  define strupr_jsechar      strupr
#  define strnicmp_jsechar    strnicmp
#  define strncmp_jsechar     strncmpsbcs
#  define sscanf_jsechar      sscanf
#  define atoi_jsechar        atoisbcs
#else
#  define stricmp_jsechar     stricmp
#  define vsprintf_jsechar    vsprintf
#  define sprintf_jsechar     sprintf
#  define strstr_jsechar      strstr
#  define strspn_jsechar      strspn
#  define strcspn_jsechar     strcspn
#  define strtol_jsechar      strtol
#  define strtod_jsechar      strtod
#  define strpbrk_jsechar     strpbrk
#  define strrchr_jsechar     strrchr
#  define strchr_jsechar      strchr
#  define strlwr_jsechar      strlwr
#  define strupr_jsechar      strupr
#  define strnicmp_jsechar    strnicmp
#  define strncmp_jsechar     strncmp
#  define sscanf_jsechar      sscanf
#  define atoi_jsechar        atoi
#endif

#  define isalnum_jsechar     isalnum
#  define isalpha_jsechar     isalpha
#  define isascii_jsechar     isascii
#  define iscntrl_jsechar     iscntrl
#  define isdigit_jsechar     isdigit
#  define isgraph_jsechar     isgraph
#  define islower_jsechar     islower
#  define isprint_jsechar     isprint
#  define ispunct_jsechar     ispunct
#  define isspace_jsechar     isspace
#  define isupper_jsechar     isupper
#  define isxdigit_jsechar    isxdigit
#  define toascii_jsechar     toascii
#  define tolower_jsechar     tolower
#  define toupper_jsechar     toupper

#ifdef DO_DBCS
#  define strcmpi_jsechar     strcmpi
#  define strcpy_jsechar      strcpysbcs
#  define strncpy_jsechar     strncpysbcs
#  define strcat_jsechar      strcatsbcs
#  define strncat_jsechar     strncatsbcs
#  define strcmp_jsechar      strcmpsbcs
#  define strlen_jsechar      strlensbcs
#else
#  define strcmpi_jsechar     strcmpi
#  define strcpy_jsechar      strcpy
#  define strncpy_jsechar     strncpy
#  define strcat_jsechar      strcat
#  define strncat_jsechar     strncat
#  define strcmp_jsechar      strcmp
#  define strlen_jsechar      strlen
#endif
#  if defined(JSE_THREADSAFE_POSIX_CRTL) && (0!=JSE_THREADSAFE_POSIX_CRTL)
#     define strtok_r_jsechar    strtok_r
#  else
#     define strtok_jsechar      strtok
#  endif

#  define ltoa_jsechar        ltoa
#  define atol_jsechar        atol
#  define atof_jsechar        atof
#  define perror_jsechar      perror
#  define system_jsechar      system

#  define fread_jsechar       fread
#  define fopen_jsechar       fopen
#  define freopen_jsechar     freopen
#  define _fsopen_jsechar     _fsopen
#  define gets_jsechar        gets
#  define fgets_jsechar       fgets
#  define fputs_jsechar       fputs
#  define fgetc_jsechar       fgetc
#  define fputc_jsechar       fputc
#  define fprintf_jsechar     fprintf
#  define printf_jsechar      printf
#  define vfprintf_jsechar    vfprintf
#  define ungetc_jsechar      ungetc
#  define EOF_jsechar         EOF
#  define puts_jsechar        puts

#  define stat_struct         stat
#  define stat_jsechar        stat
#  define chdir_jsechar       chdir
#  define getcwd_jsechar      getcwd
#  define tmpnam_jsechar      tmpnam
#  define remove_jsechar      remove
#  define rename_jsechar      rename
#  define mkdir_jsechar       mkdir
#  define rmdir_jsechar       rmdir

#  if defined(JSE_THREADSAFE_POSIX_CRTL) && (0!=JSE_THREADSAFE_POSIX_CRTL)
#     define ctime_r_jsechar     ctime_r
#     define asctime_r_jsechar   asctime_r
#  else
#     define ctime_jsechar       ctime
#     define asctime_jsechar     asctime
#  endif
#  define strftime_jsechar    strftime
#  define _fullpath_jsechar   _fullpath
#  define access_jsechar      access

#  define environ_jsechar     environ

  /* The following now have explicit casts in case they are used with const
     strings */
#  define JsecharToAscii(x) (char *) x
#  define AsciiLenToJsechar(x,y) (const jsecharptr ) x
#  define AsciiToJsechar(x) (const jsecharptr ) x
#  define FreeAsciiString(x)
#  define FreeJsecharString(x)

#  define  CONST_STRING(NAME,STRING)  CONST_DATA(jsecharptrdatum) NAME[] = STRING

/******************************
 **** END ASCII VERSIONS ****
 ******************************/

#endif


#endif
