/* seclib.h  Public include file for the Clib library
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

#if defined(JSE_CLIB_ANY) && !defined(__SECLIB_H)
#  define __SECLIB_H

#  ifdef __cplusplus
   extern "C" {
#  endif

/* These are not necessarily defined, but they are conditionally called from
 * InitializeLibrary_Clib(), so we put the prototypes here just to simplify
 * things
 */
void NEAR_CALL InitializeLibrary_Clib_Exit(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Ctype(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Math(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Misc(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Stdarg(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Stdio(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Stdlib(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_String(jseContext jsecontext);
void NEAR_CALL InitializeLibrary_Clib_Time(jseContext jsecontext);

/* Kludge for systems which don't have vscanf().  Found in sestdio.c */
#if ( defined(_MSC_VER) || defined(_AIX) || defined(__sun__) || defined(__osf__) || \
      defined(__sgi__) || defined(__JSE_MAC__) || defined(__IBMCPP__) || defined(__JSE_390__))
   int vfscanf(FILE *stream,const jsecharptr format,va_list arglist,uint arglist_size_in_bytes);
   int vsscanf(const jsecharptr buffer,const jsecharptr format,va_list arglist,
               uint arglist_size_in_bytes);
#endif

/* Generic includes */
#if defined(JSE_CLIB_FWRITE) || defined(JSE_CLIB_FREAD)
#  if defined(__JSE_UNIX__)
#     include "common/seblob.h"
#  elif defined(__JSE_MAC__)
#     include "seblob.h"
#  elif defined(__JSE_390__)
#     include "SEBLOBH"
#  else
#     include "common\seblob.h"
#  endif
#endif

/* Clib includes */
#if defined(__JSE_UNIX__)
#  include "clib/sefile.h"    /* FileSystem - used in sestdio.c */
#  include "clib/sefmtio.h"   /* fmtIO, xprintf, xscanf - used in sestdio.c and sestdlib.c */
#  include "clib/sestdarg.h"  /* variableArgs - used in sefmtio.c and sestdargc.c */
#elif defined(__JSE_MAC__)
#  include "sefile.h"
#  include "sefmtio.h"
#  include "sestdarg.h"
#elif defined(__JSE_390__)
#  include "SEFILEH"
#  include "SEFMTIOH"
#  include "SESTDARH"
#else
#  include "clib\sefile.h"
#  include "clib\sefmtio.h"
#  include "clib\sestdarg.h"
#endif

/* Global initialization for Clib library */
jsebool LoadLibrary_Clib(jseContext jsecontext);

#  ifdef __cplusplus
}
#  endif

#endif

