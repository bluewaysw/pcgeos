/* seliball.h
 *
 * This header file will include all the necessary headers depending on what
 * Libraries the user has defined.  This takes the place of including every
 * one separately, like #include "seclib.h" #include "seecma.h" etc.  It
 * also defines the function LoadLibrary_All, which will initialize
 * all of the appropriate libraries depending on the settings.  It should be
 * included after selibdef.h
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

#ifndef __SELIBALL_H
#define __SELIBALL_H

/* Lang */
#ifdef JSE_LANG_ANY
#  if defined(__JSE_UNIX__)
#     include "lang/selang.h"
#  elif defined(__JSE_MAC__)
#     include "selang.h"
#  elif defined(__JSE_390__)
#     include "SELANGH"
#  else
#     include "lang\selang.h"
#  endif
#endif
/* ECMA */
#if defined(JSE_ARRAY_ANY)    \
 || defined(JSE_BOOLEAN_ANY)  \
 || defined(JSE_FUNCTION_ANY) \
 || defined(JSE_NUMBER_ANY)   \
 || defined(JSE_OBJECT_ANY)   \
 || defined(JSE_ECMAMISC_ANY) \
 || defined(JSE_STRING_ANY)   \
 || defined(JSE_DATE_ANY)     \
 || defined(JSE_REGEXP_ANY)
#  if defined(__JSE_UNIX__)
#     include "ecma/seecma.h"
#  elif defined(__JSE_MAC__) || defined(__JSE_GEOS__)
#     include "seecma.h"
#  elif defined(__JSE_390__)
#     include "SEECMAH"
#  else
#     include "ecma\seecma.h"
#  endif
#endif
/* SElib */
#ifdef JSE_SELIB_ANY
#  if defined(__JSE_UNIX__)
#     include "selib/selib.h"
#  elif defined(__JSE_MAC__)
#     include "selib.h"
#  elif defined(__JSE_390__)
#     include "SELIBH"
#  else
#     include "selib\selib.h"
#  endif
#endif
/* Clib */
#ifdef JSE_CLIB_ANY
#  if defined(__JSE_UNIX__)
#     include "clib/seclib.h"
#  elif defined(__JSE_MAC__)
#     include "seclib.h"
#  elif defined(__JSE_390__)
#     include "SECLIBH"
#  else
#     include "clib\seclib.h"
#  endif
#endif
/* Unix */
#ifdef JSE_UNIX_ANY
#  include "unix/seunix.h"
#endif
/* Win */
#ifdef JSE_WIN_ANY
#  include "win/sewin.h"
#endif
/* OS2 */
#ifdef JSE_OS2_ANY
#  include "os2\seos2.h"
#endif
/* Mac */
#ifdef JSE_MAC_ANY
#  include "semac.h"
#endif
/* Dos */
#ifdef JSE_DOS_ANY
#  include "dos\sedos.h"
#endif
/* NLM */
#ifdef __JSE_NWNLM__
#  include "nlm\senetwar.h"
#endif
/* Screen */
#ifdef JSE_SCREEN_ANY
#  include "sescreen.h"
#endif
/* Test */
#ifdef JSE_TEST_ANY
#  if defined(__JSE_UNIX__)
#     include "test/setest.h"
#  elif defined(__JSE_MAC__) || defined(__JSE_GEOS__)
#     include "setest.h"
#  elif defined(__JSE_390__)
#     include "SETESTH"
#  else
#     include "test\setest.h"
#  endif
#endif
/* MD5 */
#ifdef JSE_MD5_ANY
#  if defined(__JSE_UNIX__)
#     include "md5/semd5.h"
#  elif defined(__JSE_MAC__)
#     include "semd5.h"
#  elif defined(__JSE_390__)
#     include "SEMD5H"
#  else
#     include "md5\semd5.h"
#  endif
#endif

/* Comobj */
#ifdef JSE_COMOBJ_ANY
#  if defined(__JSE_UNIX__)
#     include "comobj/comobj.h"
#  elif defined(__JSE_MAC__)
#     include "comobj.h"
#  elif defined(__JSE_390__)
#     include "COMOBJH"
#  else
#     include "comobj\comobj.h"
#  endif
#endif
/* UUcode */
#ifdef JSE_UUCODE_ANY
#  if defined(__JSE_UNIX__)
#     include "uucode/seuucode.h"
#  elif defined(__JSE_MAC__)
#     include "seuucode.h"
#  elif defined(__JSE_390__)
#     include "SEUUCODH"
#  else
#     include "uucode\seuucode.h"
#  endif
#endif
/* GD */
#ifdef JSE_GD_ANY
#  if defined(__JSE_UNIX__)
#     include "gd/segd.h"
#  elif defined(__JSE_MAC__)
#     include "segd.h"
#  elif defined(__JSE_390__)
#     include "SEGDH"
#  else
#     include "gd\segd.h"
#  endif
#endif
/* Socket */
#ifdef JSE_SOCKET_ANY
#  if defined(__JSE_UNIX__)
#     include "socket/sesocket.h"
#  elif defined(__JSE_MAC__)
#     include "sesocket.h"
#  else
#     include "socket\sesocket.h"
#  endif
#endif
/* DSP */
#ifdef JSE_DSP_ANY
#  if defined(__JSE_UNIX__)
#     include "dsp/sedsp.h"
#  elif defined(__JSE_MAC__)
#     include "sedsp.h"
#  else
#     include "dsp\sedsp.h"
#  endif
#endif

/* SEDBC */
#ifdef JSE_SEDBC_ANY
#  if defined(__JSE_UNIX__)
#     include "sedbc/sedbc.h"
#  elif defined(__JSE_MAC__)
#     include "sedbc.h"
#  else
#     include "sedbc\sedbc.h"
#  endif
#endif

/* PLUGIN */
#if defined(__NPEXE__)
#  include "nplugin.h"
#endif

/* Common header for all libraries */
#if defined(__JSE_UNIX__)
#  include "common/selibcom.h"
#elif defined(__JSE_MAC__) || defined(__JSE_GEOS__)
#  include "selibcom.h"
#elif defined(__JSE_390__)
#  include "SELIBCOH"
#else
#  include "common\selibcom.h"
#endif

/* define macro that will flush all buffers (used before system() calls, or when all files need get in synch) */
#if defined(JSE_CLIB_ANY) || defined(JSE_SELIB_SPAWN)
#  if defined(__sun__)
#    define FlushAllBuffers(); /* doesn't work */
#  elif defined(__WATCOMC__)
#    define FlushAllBuffers();    flushall();
#  else
#    define FlushAllBuffers();    fflush(NULL);
#  endif
#endif

#ifdef __cplusplus
   extern "C" {
#endif
jsebool LoadLibrary_All(jseContext jsecontext);
#ifdef __cplusplus
   }
#endif


#endif /* __SELIBALL_H */
