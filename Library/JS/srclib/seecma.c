/* seecma.c  Glue for ECMA library
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

#  if defined(JSE_ARRAY_ANY)    \
   || defined(JSE_BOOLEAN_ANY)  \
   || defined(JSE_FUNCTION_ANY) \
   || defined(JSE_NUMBER_ANY)   \
   || defined(JSE_OBJECT_ANY)   \
   || defined(JSE_ECMAMISC_ANY) \
   || defined(JSE_STRING_ANY)   \
   || defined(JSE_REGEXP_ANY)

#  if defined(JSE_ECMAMISC_NAN) || defined(JSE_NUMBER_NAN)
      VAR_DATA(jsenumber) seNaN;
#  endif
#  if defined(JSE_ECMAMISC_INFINITY) || defined(JSE_NUMBER_POSITIVE_INFINITY)
      VAR_DATA(jsenumber) seInfinity;
#  endif

   jsebool
LoadLibrary_Ecma(jseContext jsecontext)
{
   /* needed because the compiler doesn't recognize constants correctly */
#  if defined(JSE_ECMAMISC_NAN) || defined(JSE_NUMBER_NAN)
      seNaN = jseNaN;
#  endif
#  if defined(JSE_ECMAMISC_INFINITY) || defined(JSE_NUMBER_POSITIVE_INFINITY)
      seInfinity = jseInfinity;
#  endif

#  if defined(JSE_ARRAY_ANY)    \
   || defined(JSE_BOOLEAN_ANY)  \
   || defined(JSE_FUNCTION_ANY) \
   || defined(JSE_NUMBER_ANY)   \
   || defined(JSE_OBJECT_ANY)   \
   || defined(JSE_EXCEPTION_ANY)
      InitializeLibrary_Ecma_Objects(jsecontext);
#  endif

#  if defined(JSE_STRING_ANY)
      InitializeLibrary_Ecma_String(jsecontext);
#  endif

#  if defined(JSE_DATE_ANY)
      InitializeLibrary_Ecma_Date(jsecontext);
#  endif

#  if defined(JSE_MATH_ANY)
      InitializeLibrary_Ecma_Math(jsecontext);
#  endif

#  if defined(JSE_BUFFER_ANY)
      InitializeLibrary_Ecma_Buffer(jsecontext);
#  endif

#  if defined(JSE_ECMAMISC_ANY)
      InitializeLibrary_Ecma_Misc(jsecontext);
#  endif

#  if defined(JSE_REGEXP_ANY)
      InitializeLibrary_Ecma_RegExp(jsecontext);
#  endif

   return True;
}

#if defined(JSETOOLKIT_LINK) && !defined(JSE_NO_AUTO_INIT)

jsebool FAR_CALL
ExtensionLoadFunc(jseContext jsecontext)
{
   return LoadLibrary_Ecma(jsecontext);
}

#endif

#endif /* any ecma option */

ALLOW_EMPTY_FILE
