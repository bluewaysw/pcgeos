/* dbgprntf.c
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

#include "jseopt.h"
#include "jsetypes.h"
#include "jselib.h"
#include "utilstr.h"
#if (defined(__WATCOMC__) || defined(__BORLANDC__) \
 || (defined(__JSE_WIN32__) && !defined(__JSE_WINCE__))) && !defined(__JSE_GEOS__)
#  include "share.h"
#endif


#if !defined(NDEBUG)

#if defined(__JSE_GEOS__)
#pragma argsused
void GeosDebugPrintf(jsechar *buffer) {
    /* dummy code */
    if (*buffer) {
	asm {nop};
    }
}
#endif

   void JSE_CFUNC
DebugPrintf(jsecharptr Fmt,...)
{
#if !defined(__JSE_GEOS__)
   FILE *fp;
   va_list ap;
#if defined(__JSE_WINCE__)
   jsechar buffer[1000];
#endif

   va_start(ap,Fmt);

#if defined(__JSE_WINCE__)
   jse_vsprintf((jsecharptr)buffer,Fmt,ap);
   while ( NULL == (fp = fopen_jsechar(UNISTR("\\jseDebug.log"),UNISTR("at"))) ) ;
      fprintf_jsechar(fp,buffer);
      fprintf_jsechar(fp,UNISTR("\n"));
#else
   /* prevent two threads writing at same time */
#  if defined(__JSE_MAC__)
      while ( NULL == (fp = fopen_jsechar(UNISTR("jseDebug.log"),UNISTR("at"))) ) ;
#  elif defined(__JSE_NWNLM__)
      while ( NULL == (fp = fopen_jsechar(UNISTR("SYS:/jseDebug.log"),UNISTR("at"))) ) ;
#  elif defined(__JSE_UNIX__)
      while ( NULL == (fp = fopen_jsechar(UNISTR("jsedebug.log"),UNISTR("at"))) ) ;
#  elif defined(__WATCOMC__) || defined(__BORLANDC__)
#     if defined(JSE_UNICODE) && (0!=JSE_UNICODE)
         while ( NULL == (fp = fopen_jsechar(UNISTR("C:\\jseDebug.log"),UNISTR("at"))) ) ;
#     else
         while ( NULL == (fp = _fsopen_jsechar(UNISTR("C:\\jseDebug.log"),UNISTR("at"),SH_DENYRW)) ) ;
#     endif
#  elif defined(__JSE_WIN32__)
      while ( NULL == (fp = _fsopen_jsechar(UNISTR("C:\\jseDebug.log"),UNISTR("at"),_SH_DENYRW)) ) ;
#  else
      while ( NULL == (fp = fopen_jsechar(UNISTR("C:\\jseDebug.log"),UNISTR("at"))) ) ;
#  endif
   vfprintf_jsechar(fp,Fmt,ap);
#endif

   fclose(fp);
   va_end(ap);
#else /* GEOS */
   va_list ap;
   jsechar buffer[1000];

   va_start(ap,Fmt);
   vsprintf_jsechar((jsecharptr)buffer,Fmt,ap);
   va_end(ap);

   GeosDebugPrintf(buffer);
#endif /* !defined(__JSE_GEOS__) */
}


#if (defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)) \
 && !defined(__JSE_NUCLEUS__)
   void JSE_CFUNC
WinDebug(jsecharptr format,...)
{
   va_list ap;
   jsechar buffer[1000];
   va_start(ap,format);
   jse_vsprintf((jsecharptr)buffer,format,ap);
   if ( IDOK != MessageBox((HWND)0,(jsecharptr)buffer,NULL,
                           MB_TASKMODAL|MB_ICONHAND|MB_OKCANCEL) )
      exit(EXIT_FAILURE);
   va_end(ap);
}
#endif

#else
   void JSE_CFUNC
DebugPrintf(jsecharptr Fmt,...)
{
#  if !defined(__BORLANDC__)
     Fmt = Fmt;  /* ignored parameter */
#  endif
  /* nothing */
}
#endif
