/* seecma.h   Header file for ECMA library
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

#if !defined(__SEECMA_H)
#define __SEECMA_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(JSE_ECMAMISC_NAN) || defined(JSE_NUMBER_NAN)
   extern VAR_DATA(jsenumber) seNaN;
#endif
#if defined(JSE_ECMAMISC_INFINITY) || defined(JSE_NUMBER_POSITIVE_INFINITY)
   extern VAR_DATA(jsenumber) seInfinity;
#endif

#ifdef JSE_DATE_ANY
   void NEAR_CALL InitializeLibrary_Ecma_Date(jseContext jsecontext);
#endif
#ifdef JSE_MATH_ANY
   void NEAR_CALL InitializeLibrary_Ecma_Math(jseContext jsecontext);
#endif
#ifdef JSE_BUFFER_ANY
   void NEAR_CALL InitializeLibrary_Ecma_Buffer(jseContext jsecontext);
#endif
#if defined(JSE_ARRAY_ANY)    \
 || defined(JSE_BOOLEAN_ANY)  \
 || defined(JSE_FUNCTION_ANY) \
 || defined(JSE_NUMBER_ANY)   \
 || defined(JSE_OBJECT_ANY)   \
 || defined(JSE_EXCEPTION_ANY)
   void NEAR_CALL InitializeLibrary_Ecma_Objects(jseContext jsecontext);
#endif
#if defined(JSE_ECMAMISC_ANY)
   void NEAR_CALL InitializeLibrary_Ecma_Misc(jseContext jsecontext);
#endif
#if defined(JSE_STRING_ANY)
   void NEAR_CALL InitializeLibrary_Ecma_String(jseContext jsecontext);
#endif
#if defined(JSE_REGEXP_ANY)
   void NEAR_CALL InitializeLibrary_Ecma_RegExp(jseContext jsecontext);
#endif

#if defined(JSE_ARRAY_ANY)    \
 || defined(JSE_BOOLEAN_ANY)  \
 || defined(JSE_FUNCTION_ANY) \
 || defined(JSE_NUMBER_ANY)   \
 || defined(JSE_OBJECT_ANY)   \
 || defined(JSE_ECMAMISC_ANY) \
 || defined(JSE_STRING_ANY)   \
 || defined(JSE_REGEXP_ANY)
   jsebool LoadLibrary_Ecma(jseContext jsecontext);
#endif

extern CONST_DATA(jsecharptrdatum) InsufficientMemory[];

#if defined(JSE_ARRAY_ANY)     \
 || defined(JSE_BOOLEAN_ANY)  \
 || defined(JSE_BUFFER_ANY)    \
 || defined(JSE_DATE_ANY)     \
 || defined(JSE_FUNCTION_ANY) \
 || defined(JSE_NUMBER_ANY)   \
 || defined(JSE_OBJECT_ANY)   \
 || defined(JSE_STRING_ANY)
   jseVariable CreateNewObject(jseContext jsecontext,const jsecharptr objname);
#endif
#if defined(JSE_ARRAY_ANY)      \
 || defined(JSE_DATE_ANY)
   jseVariable MyjseMember(jseContext jsecontext,jseVariable obj,const jsecharptr name,jseDataType t);
#endif
#if defined(JSE_DATE_ANY)    \
 || defined(JSE_BOOLEAN_ANY) \
 || defined(JSE_STRING_ANY)   \
 || defined(JSE_NUMBER_ANY)
   jsebool ensure_type(jseContext jsecontext,jseVariable what,const jsecharptr type);
#endif

#ifdef JSE_REGEXP_OBJECT
#  include "regex.h"
   extern CONST_DATA(jsecharptrdatum) exec_MEMBER[];
   extern CONST_DATA(jsecharptrdatum) global_MEMBER[];
   extern CONST_DATA(jsecharptrdatum) index_MEMBER[];
   extern CONST_DATA(jsecharptrdatum) input_MEMBER[];
   extern CONST_DATA(jsecharptrdatum) lastIndex_MEMBER[];
#endif

#ifdef __cplusplus
}
#endif
#endif
