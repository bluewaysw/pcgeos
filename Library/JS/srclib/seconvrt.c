/* seconvrt.c Copyright 1997 Nombas.  All rights reserved.
 *
 * Handles ECMAScript conversion operators.  Adds the following:
 * ToPrimitive, ToBoolean, ToNumber, ToInteger, ToInt32, ToUint32,
 * ToInt16, ToBytes, ToObject, ToString
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


/* ToPrimitive() */
#ifdef JSE_LANG_TOPRIMITIVE
static jseLibFunc(Lang_ToPrimitive)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToPrimitive);
   /* It is possible for this to fail */
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToBoolean() */
#ifdef JSE_LANG_TOBOOLEAN
static jseLibFunc(Lang_ToBoolean)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToBoolean);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToNumber() */
#ifdef JSE_LANG_TONUMBER
static jseLibFunc(Lang_ToNumber)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToNumber);

   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToIngeter() */
#ifdef JSE_LANG_TOINTEGER
static jseLibFunc(Lang_ToInteger)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToInteger);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToInt32() */
#ifdef JSE_LANG_TOINT32
static jseLibFunc(Lang_ToInt32)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToInt32);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToUint32() */
#ifdef JSE_LANG_TOUINT32
static jseLibFunc(Lang_ToUint32)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToUint32);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif

/* ToUint16() */
#ifdef JSE_LANG_TOUINT16
static jseLibFunc(Lang_ToUint16)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToUint16);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToString() */
#ifdef JSE_LANG_TOSTRING
static jseLibFunc(Lang_ToString)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToString);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif

/* ToBuffer() */
#ifdef JSE_LANG_TOBUFFER
static jseLibFunc(Lang_ToBuffer)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToBuffer);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif

/* ToBytes() */
#ifdef JSE_LANG_TOBYTES
static jseLibFunc(Lang_ToBytes)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToBytes);
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


/* ToObject() */
#ifdef JSE_LANG_TOOBJECT
static jseLibFunc(Lang_ToObject)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseCreateConvertedVariable(jsecontext,v,jseToObject);
   /* It is possible for this to fail */
   if( r != NULL )
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif

/* ToSource() */
#ifdef JSE_LANG_TOSOURCE
static jseLibFunc(Lang_ToSource)
{
   jseVariable v = jseFuncVar(jsecontext,0);
   jseVariable r = jseConvertToSource(jsecontext,v);

   if( r == NULL )
      jseReturnVar(jsecontext,jseCreateVariable(jsecontext,jseTypeNull),
                   jseRetTempVar);
   else
      jseReturnVar(jsecontext,r,jseRetTempVar);
}
#endif


#if defined(JSE_LANG_TOPRIMITIVE) || \
    defined(JSE_LANG_TOBOOLEAN)   || \
    defined(JSE_LANG_TONUMBER)    || \
    defined(JSE_LANG_TOINTEGER)   || \
    defined(JSE_LANG_TOINT32)     || \
    defined(JSE_LANG_TOUINT32)    || \
    defined(JSE_LANG_TOUINT16)    || \
    defined(JSE_LANG_TOSTRING)    || \
    defined(JSE_LANG_TOBUFFER)    || \
    defined(JSE_LANG_TOBYTES)     || \
    defined(JSE_LANG_TOOBJECT)    || \
    defined(JSE_LANG_TOSOURCE)

#ifdef __JSE_GEOS__
/* strings in code segment */
#pragma option -dc
#endif

static CONST_DATA(struct jseFunctionDescription) ConversionLibFunctionList[] =
{
#  if defined(JSE_LANG_TOPRIMITIVE)
JSE_LIBMETHOD( UNISTR("ToPrimitive"), Lang_ToPrimitive,    1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOBOOLEAN)
JSE_LIBMETHOD( UNISTR("ToBoolean"),   Lang_ToBoolean,      1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TONUMBER)
JSE_LIBMETHOD( UNISTR("ToNumber"),    Lang_ToNumber,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOINTEGER)
JSE_LIBMETHOD( UNISTR("ToInteger"),   Lang_ToInteger,      1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOINT32)
JSE_LIBMETHOD( UNISTR("ToInt32"),     Lang_ToInt32,        1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOUINT32)
JSE_LIBMETHOD( UNISTR("ToUint32"),    Lang_ToUint32,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOUINT16)
JSE_LIBMETHOD( UNISTR("ToUint16"),    Lang_ToUint16,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOSTRING)
JSE_LIBMETHOD( UNISTR("ToString"),    Lang_ToString,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOBUFFER)
JSE_LIBMETHOD( UNISTR("ToBuffer"),    Lang_ToBuffer,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOBYTES)
JSE_LIBMETHOD( UNISTR("ToBytes"),     Lang_ToBytes,        1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOOBJECT)
JSE_LIBMETHOD( UNISTR("ToObject"),    Lang_ToObject,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif
#  if defined(JSE_LANG_TOSOURCE)
JSE_LIBMETHOD( UNISTR("ToSource"),    Lang_ToSource,       1,      1,      jseDontEnum,  jseFunc_Secure ),
#  endif

JSE_FUNC_END
};

#ifdef __JSE_GEOS__
#pragma option -dc-
#endif

void NEAR_CALL
InitializeLibrary_Lang_Conversion(jseContext jsecontext)
{
   jseAddLibrary(jsecontext,NULL,ConversionLibFunctionList,NULL,NULL,NULL);
}
#endif

ALLOW_EMPTY_FILE
