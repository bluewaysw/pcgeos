/* jseengin.h     Initialize and terminate jse Engine
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

#ifndef _JSEENGIN_H
#define _JSEENGIN_H
#if defined(__cplusplus)
   extern "C" {
#endif

void InitializejseEngine(void);
void TerminatejseEngine(void);

#if ( 0 < JSE_API_ASSERTLEVEL )
   void JSE_CFUNC SetLastApiError(const jsecharptr formatS,...);
#endif

#if ( 1 == JSE_API_ASSERTNAMES )
#  define JSE_API_STRING(varname,value)\
      static CONST_STRING(varname,value)
   void ApiParameterError(const jsecharptr funcname,uint ParameterIndex);
#  define jseApiParameterError(funcname,ParameterIndex)\
      ApiParameterError(funcname,ParameterIndex);
#else
#  define JSE_API_STRING(varname,value); /* nothing */
   void ApiParameterError(uint ParameterIndex);
#  define jseApiParameterError(funcname,ParameterIndex)\
      ApiParameterError(ParameterIndex);
#endif

#if ( 0 == JSE_API_ASSERTLEVEL )
#  define JSE_API_ASSERT_(P,PI,FN,ER)  assert( NULL != P )
#  define JSE_API_ASSERT_C(P,PI,SC,FN,ER)  assert( NULL != P )
#elif ( 1 == JSE_API_ASSERTLEVEL )
#  define JSE_API_ASSERT_(Param,ParamIdx,FuncName,ErrorReturn) \
     { if ( NULL == Param ) \
        { jseApiParameterError(FuncName,ParamIdx); ErrorReturn; } }
#  define JSE_API_ASSERT_C(Param,ParamIdx,Cookie,FuncName,ErrorReturn) \
     { if ( NULL == Param ) \
        { jseApiParameterError(FuncName,ParamIdx); ErrorReturn; } }
#elif ( 2 == JSE_API_ASSERTLEVEL )
#  define JSE_API_ASSERT_(Param,ParamIdx,FuncName,ErrorReturn) \
      { if ((NULL==Param) ) \
         { jseApiParameterError(FuncName,ParamIdx); ErrorReturn; } }
#  define JSE_API_ASSERT_C(Param,ParamIdx,Cookie,FuncName,ErrorReturn) \
      { if ((NULL==Param) || (((ubyte)Cookie)!=((ubyte)((ubyte *)Param)[4])))\
         { jseApiParameterError(FuncName,ParamIdx); ErrorReturn; } }
#  define jseContext_cookie   ((ubyte)'\xCA')
#  define jseStack_cookie     ((ubyte)'\xAF')
#else
#  error unknown JSE_API_ASSERTLEVEL
#endif


#if defined(__cplusplus)
   }
#endif
#endif
