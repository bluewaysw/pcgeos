/* seliball.c
 *
 * This file contains the function LoadLibrary_All, which calls
 * all the appropriate initialization functions based on the settings the
 * user has defined.
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

   jsebool _export
LoadLibrary_All(jseContext jsecontext)
{
#  ifdef JSE_LANG_ANY
      if ( !LoadLibrary_Lang(jsecontext) )
         return False;
#  endif

#  if defined(JSE_ARRAY_ANY)    \
   || defined(JSE_BOOLEAN_ANY)  \
   || defined(JSE_FUNCTION_ANY) \
   || defined(JSE_NUMBER_ANY)   \
   || defined(JSE_OBJECT_ANY)   \
   || defined(JSE_ECMAMISC_ANY) \
   || defined(JSE_STRING_ANY)   \
   || defined(JSE_REGEXP_ANY)
      if ( !LoadLibrary_Ecma(jsecontext) )
         return False;
#   endif

#  if defined(JSE_SELIB_BLOB_GET)    || \
      defined(JSE_SELIB_BLOB_PUT)    || \
      defined(JSE_SELIB_BLOB_SIZE)   || \
      defined(JSE_CLIB_FREAD)        || \
      defined(JSE_CLIB_FWRITE)       || \
      defined(JSE_SELIB_PEEK)        || \
      defined(JSE_SELIB_POKE)        || \
      defined(JSE_SOCKET_READ)       || \
      defined(JSE_SOCKET_WRITE)      || \
      defined(JSE_SELIB_DYNAMICLINK)
         InitializeLibrary_Blob(jsecontext);
#  endif

#  ifdef JSE_SELIB_ANY
      if ( !LoadLibrary_SElib(jsecontext) )
         return False;
#  endif

#  ifdef JSE_CLIB_ANY
      if ( !LoadLibrary_Clib(jsecontext) )
         return False;
#  endif

#  ifdef JSE_MAC_ANY
      if ( !LoadLibrary_Mac(jsecontext) )
         return False;
#  endif

#  ifdef JSE_UNIX_ANY
      if ( !LoadLibrary_Unix(jsecontext) )
         return False;
#  endif

#  ifdef JSE_DOS_ANY
      if ( !LoadLibrary_Dos(jsecontext) )
         return False;
#  endif

#  ifdef JSE_WIN_ANY
      if ( !LoadLibrary_Win(jsecontext) )
         return False;
#  endif

#  ifdef JSE_OS2_ANY
      if ( !LoadLibrary_OS2(jsecontext) )
         return False;
#  endif

#  ifdef JSE_NLM_ANY
      if ( !LoadLibrary_NLM(jsecontext) )
         return False;
#  endif

#  ifdef JSE_TEST_ANY
      if ( !LoadLibrary_Test(jsecontext) )
         return False;
#  endif

#  ifdef JSE_MD5_ANY
      if ( !LoadLibrary_MD5(jsecontext) )
         return False;
#  endif

#  ifdef JSE_COMOBJ_ANY
      if ( ! LoadLibrary_Comobj(jsecontext) )
         return False;
#  endif

#  ifdef JSE_UUCODE_ANY
      if ( !LoadLibrary_uucode(jsecontext) )
         return False;
#  endif

#  ifdef JSE_GD_ANY
      if ( !LoadLibrary_gd(jsecontext) )
         return False;
#  endif

#  ifdef JSE_SOCKET_ANY
      if ( !LoadLibrary_Socket(jsecontext) )
         return False;
#  endif

#  ifdef JSE_DSP_ANY
      if ( !LoadLibrary_dsp(jsecontext) )
         return False;
#  endif

#  ifdef JSE_SEDBC_ANY
      if ( !LoadLibrary_Socket(jsecontext) )
         return False;
#  endif

#  if defined(__NPEXE__)
      if ( !LoadLibrary_Mercury(jsecontext) )
         return False;
#  endif

   return True;
}
