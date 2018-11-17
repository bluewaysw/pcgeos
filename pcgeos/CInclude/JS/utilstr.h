/* utilstr.h  string handling utility functions
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

#ifndef _UTILSTR_H
#define _UTILSTR_H

#include "jsemem.h"
#include "jseopt.h"
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

#define IS_WHITESPACE(C)               (NULL != strchr_jsechar((jsecharptr)WhiteSpace,C))
#define IS_SAMELINE_WHITESPACE(C)      (NULL != strchr_jsechar((jsecharptr)SameLineWhiteSpace,C))
#define SKIP_WHITESPACE(C)    \
   while( 0 != JSECHARPTR_GETC(C)  &&  IS_WHITESPACE(JSECHARPTR_GETC(C)) ) { JSECHARPTR_INC(C); }
#define SKIP_SAMELINE_WHITESPACE(C)    \
   while( 0 != JSECHARPTR_GETC(C)  &&  IS_SAMELINE_WHITESPACE(JSECHARPTR_GETC(C)) ) { JSECHARPTR_INC(C); }
#define IS_NEWLINE(C)                  (NULL != strchr_jsechar((jsecharptr)NewLine,C))

extern CONST_DATA(jsecharptrdatum) WhiteSpace[];
extern CONST_DATA(jsecharptrdatum) SameLineWhiteSpace[]; /* doesn't include new line */
extern CONST_DATA(jsecharptrdatum) NewLine[]; /* any of these characters say it's a new
                                      line */

const jsecharptr jseGetResource( jseContext jsecontext, const jsecharptr string );

#if ((defined(__WATCOMC__) || defined(__BORLANDC__)) && !defined(__JSE_GEOS__)) \
 || (defined(_MSC_VER) && !defined(__JSE_EPOC32__))
#  define long_to_string(LNUM,BUF)  ltoa_jsechar(LNUM,BUF,10)
#else
   void NEAR_CALL long_to_string(long i,jsecharptr StringBuffer);
   /* assume that string buffer will be big enough to hold the integer */
#endif

void RemoveWhitespaceFromHeadAndTail(const jsecharptr buf);
  /* memmoves from beyond whitespace to buffer, then truncates whitespace
     at end */

jsecharptr StrCpyMallocLen(const jsecharptr Src,size_t len);

#define StrCpyMalloc(s) StrCpyMallocLen(s,strlen_jsechar(s))
#define FreeIfNotNull(ptr) if( ptr!=NULL ) jseMustFree((void *)ptr);

#if (defined(__JSE_MAC__) && defined(__MWERKS__) && !defined(__JSE_PALMOS__)) \
 || defined(__JSE_UNIX__) || defined(__JSE_390__) || defined(__JSE_EPOC32__)

   int strnicmp(const jsecharptr str1,const jsecharptr str2,size_t len);
   int stricmp(const jsecharptr str1,const jsecharptr str2);
   jsecharptr strupr(jsecharptr string);
   jsecharptr strlwr(jsecharptr string);

#endif /* [...] __JSE_MAC__ || __JSE_UNIX__ || __JSE_390__ */


/* common stuff for all versions */

#if defined(__JSE_PALMOS__) /* well, maybe not all cases...*/
#define strtol MY_strtol
#endif

sint jsecharCompare(const jsecharhugeptr str1,JSE_POINTER_UINDEX len1,
                    const jsecharhugeptr str2,JSE_POINTER_UINDEX len2);
   /* acts a lot like strcmp, but with unicode and length and possibly
    * embedded null characters.  returns 0, >0, or <0
    */


   /* CharsUsed==NULL if you don't care */
jsenumber MY_strtol(const jsecharptr s,jsecharptr *endptr,int radix);
   /* it is wrong to return an slong - JavaScript deals with jsenumbers,
    * not 'int's - a conversion that can fit in a jsenumber, but not an
    * int is legal in JavaScript and should not be truncated to an int
    */
   /* because Borland's was failing with big hex numbers */

#if (0==JSE_FLOATING_POINT) || \
    defined(__JSE_PSX__)
   /* simplified sprintf taking only these types:
    *  %s,  %d,  %u,  %X,  %ld,  %lu,  %lX,  %c
    */
   void jse_vsprintf(jsecharptr buf,const jsecharptr FormatString,va_list arglist);
   void jse_sprintf(jsecharptr buf,const jsecharptr FormatString,...);
#else
#  define jse_vsprintf vsprintf_jsechar
#  define jse_sprintf  sprintf_jsechar
#endif

void EcmaNumberToString(jsechar buffer[ECMA_NUMTOSTRING_MAX],jsenumber theNum);
   /* convert to string using the ecma rules */


#ifdef __cplusplus
}
#endif
#endif
