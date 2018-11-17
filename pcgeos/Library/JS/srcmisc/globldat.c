/* globldat.c
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
#include "seuni.h"


/* All of these strings MUST be NULL-terminated. No embedded NULLs */

#if defined(JSE_PROTOTYPES) && (0!=JSE_PROTOTYPES)
   CONST_STRING(PROTOTYPE_PROPERTY,"_prototype");
#endif
#if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
   CONST_STRING(DELETE_PROPERTY,"_delete");
   CONST_STRING(PUT_PROPERTY,"_put");
   CONST_STRING(CANPUT_PROPERTY,"_canPut");
   CONST_STRING(GET_PROPERTY,"_get");
   CONST_STRING(HASPROPERTY_PROPERTY,"_hasProperty");
   CONST_STRING(CALL_PROPERTY,"_call");
   CONST_STRING(DYN_DEFAULT_PROPERTY,"DYN_DEFAULT");
#endif
#if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
   CONST_STRING(OPERATOR_PROPERTY,"_operator");
   CONST_STRING(OP_NOT_SUPPORTED_PROPERTY,"OPERATOR_DEFAULT_BEHAVIOR");
#endif

CONST_STRING(CLASS_PROPERTY,"_class");
CONST_STRING(VALUE_PROPERTY,"_value");
CONST_STRING(CONSTRUCT_PROPERTY,"_construct");
CONST_STRING(CONSTRUCTOR_PROPERTY,"constructor");
CONST_STRING(DEFAULT_PROPERTY,"_defaultValue");
CONST_STRING(PARENT_PROPERTY,"__parent__");

CONST_STRING(ORIG_PROTOTYPE_PROPERTY,"prototype");
CONST_STRING(LENGTH_PROPERTY,"length");
CONST_STRING(PREFERRED_PROPERTY,"preferredType");
CONST_STRING(ARGUMENTS_PROPERTY,"arguments");
CONST_STRING(CALLEE_PROPERTY,"callee");
CONST_STRING(VALUEOF_PROPERTY,"valueOf");
CONST_STRING(TOSTRING_PROPERTY,"toString");
CONST_STRING(TOSOURCE_PROPERTY,"toSource");

CONST_STRING(OBJECT_PROPERTY,"Object");
CONST_STRING(FUNCTION_PROPERTY,"Function");
CONST_STRING(ARRAY_PROPERTY,"Array");
CONST_STRING(NUMBER_PROPERTY,"Number");
CONST_STRING(BUFFER_PROPERTY,"Buffer");
CONST_STRING(STRING_PROPERTY,"String");
CONST_STRING(BOOLEAN_PROPERTY,"Boolean");
CONST_STRING(DATE_PROPERTY,"Date");
CONST_STRING(REGEXP_PROPERTY,"RegExp");

CONST_STRING(EXCEPTION_PROPERTY,"Error");

CONST_STRING(PROTOCLASS_PROPERTIES,"prototype._class");
CONST_STRING(PROTOPROTO_PROPERTIES,"prototype._prototype");

/* ----------------------------------------------------------------------
 * special math values
 * ---------------------------------------------------------------------- */

/* two 32-bit values per, note these are little endian so the
 * least significant long is first. These do not change among
 * threads.
 */

#if (0==JSE_FLOATING_POINT)

   /* special values for JSE_FLOATING_POINT==0 in sefp.h */
   jsenumber JSE_FP_NEGATE(jsenumber FP)
   {
      if ( jseIsPosZero(FP) )
         return jseNegZero;
      if ( jseIsNegZero(FP) )
         return jseZero;
      return -FP;
   }

#elif !defined(JSE_FP_EMULATOR) || (0==JSE_FP_EMULATOR)

   /* floating point */

#  if defined(__JSE_UNIX__)

      /* unix initialization of special_math occurs in jseengin.cpp */
      VAR_DATA(jsenumber) jse_special_math[4];

#  else

#     if SE_BIG_ENDIAN==True

         CONST_DATA(uword32) jse_special_math[8] = {
           0x80000000L, 0x00000000L, /* -0 */
           0x7FF00000L, 0x00000000L, /* infinity */
           0xFFF00000L, 0x00000000L, /* -infinity */
           0x7FF80000L, 0x00000000L  /* NaN */
         };

#     else

      /* This information can be found on the Watcom help system, using
       * 'find' type in 'infinity' and choose '32-bit: Type Double"
       */
         CONST_DATA(uword32) jse_special_math[8] = {
           0x00000000L, 0x80000000L, /* -0 */
           0x00000000L, 0x7FF00000L, /* infinity */
           0x00000000L, 0xFFF00000L, /* -infinity */
           0x00000000L, 0x7FF80000L  /* NaN */
         };

#     endif

#  endif

#endif


/* ----------------------------------------------------------------------
 * retrieving float from the core in a compiler-independent way
 * ---------------------------------------------------------------------- */

#if (0!=JSE_FLOATING_POINT) \
 && !defined(JSETOOLKIT_CORE) \
 && !defined(JSETOOLKIT_LINK)
jsenumber jseGetNumber(jseContext jsecontext ,jseVariable variable)
{
   jsenumber GetFloat;
   jseGetFloatIndirect(jsecontext,variable,&GetFloat);
   return GetFloat;
}
#endif
