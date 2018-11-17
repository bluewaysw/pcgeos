/* globldat.h
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

#ifndef _GLOBLDAT_H
#define _GLOBLDAT_H

/* The various 'standard' JS properties we have to work with. */

#ifdef __cplusplus
extern "C" {
#endif


#if defined(JSE_PROTOTYPES) && (0!=JSE_PROTOTYPES)
   extern CONST_DATA(jsecharptrdatum) PROTOTYPE_PROPERTY[];
#endif
#if defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
   extern CONST_DATA(jsecharptrdatum) DELETE_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) PUT_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) CANPUT_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) GET_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) HASPROPERTY_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) CALL_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) DYN_DEFAULT_PROPERTY[];
#endif
#if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
   extern CONST_DATA(jsecharptrdatum) OPERATOR_PROPERTY[];
   extern CONST_DATA(jsecharptrdatum) OP_NOT_SUPPORTED_PROPERTY[];
#endif
extern CONST_DATA(jsecharptrdatum) CLASS_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) ORIG_PROTOTYPE_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) VALUE_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) CONSTRUCT_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) CONSTRUCTOR_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) LENGTH_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) DEFAULT_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) PREFERRED_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) ARGUMENTS_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) CALLEE_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) VALUEOF_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) TOSTRING_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) TOSOURCE_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) PARENT_PROPERTY[];

/* Standard object names */
extern CONST_DATA(jsecharptrdatum) ARRAY_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) REGEXP_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) DATE_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) OBJECT_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) FUNCTION_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) NUMBER_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) BUFFER_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) STRING_PROPERTY[];
extern CONST_DATA(jsecharptrdatum) BOOLEAN_PROPERTY[];

/* Exception names */
extern CONST_DATA(jsecharptrdatum) EXCEPTION_PROPERTY[];
/* Note that the following are defines, so the user cannot redefine them
 * without rebuilding the core as well
 */
#define EXCEPTION_EXCEPTION   UNISTR("Error")
#define SYNTAX_EXCEPTION      UNISTR("SyntaxError")
#define REFERENCE_EXCEPTION   UNISTR("ReferenceError")
#define CONVERSION_EXCEPTION  UNISTR("ConversionError")
#define ARRAYLENGTH_EXCEPTION UNISTR("RangeError")
#define TYPE_EXCEPTION        UNISTR("TypeError")
#define EVAL_EXCEPTION        UNISTR("EvalError")
#define URI_EXCEPTION         UNISTR("URIError")
#define REGEXP_EXCEPTION      UNISTR("RegExpError")
   /* Nombas types */
#define INTERNAL_EXCEPTION    UNISTR("InternalError")
#define SOURCE_EXCEPTION      UNISTR("SourceError")
#define MATH_EXCEPTION        UNISTR("MathError")
#define SECURITY_EXCEPTION    UNISTR("SecurityError")
#define MEMORY_EXCEPTION      UNISTR("MemoryError")
#define SYSTEM_EXCEPTION      UNISTR("SystemError")
#define DSP_EXCEPTION         UNISTR("DSPError")
#define DEBUGGER_EXCEPTION    UNISTR("DebuggerError")

extern CONST_DATA(jsecharptrdatum) PROTOCLASS_PROPERTIES[];
extern CONST_DATA(jsecharptrdatum) PROTOPROTO_PROPERTIES[];

#ifdef __cplusplus
}
#endif

#endif
