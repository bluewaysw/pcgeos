/* jselib.h    Main defines for the ScriptEase ISDK API
 */

/* (c) COPYRIGHT 1993-2000         NOMBAS, INC.
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

#ifndef _JSELIB_H
#define _JSELIB_H

#if !defined(__JSE_UNIX__) && !defined(__JSE_MAC__) \
 && !defined(__JSE_PSX__) && !defined(__JSE_PALMOS__)
#  if defined(__BORLANDC__)
#     pragma option -a1
#  else
#     pragma pack( 1 )
#  endif
#endif /*!defined(__JSE_UNIX__) && !define(__JSE_MAC__) ... */

#ifdef __cplusplus
   extern "C" {
#endif

/*****************************************
 *** MUST HAVE DEFINED THE LINK METHOD ***
 *****************************************/
/* don't put the comments on the same line as the #if - confuses makedepend */
#if   defined(__JSE_DLLLOAD__)
   /* linking DLL at load time */
#elif defined(__JSE_DLLRUN__)
   /* linking DLL at run time */
#elif defined(__JSE_LIB__)
   /* linking with the jse library */
#else
#  error UNDEFINED JSE LINK METHOD
#endif  /* defined(__JSE_DLLLOAD__) */

/*****************************************************
 *** MUST HAVE DEFINED WHETHER APPLICATION OR CORE ***
 *****************************************************/
#if !defined(JSETOOLKIT_APP) && !defined(JSETOOLKIT_CORE) && !defined(JSETOOLKIT_LINK)
   /* for the customers ease lets assume a toolkit application */
#  define JSETOOLKIT_APP
#endif
#if defined(JSETOOLKIT_APP) && defined(JSETOOLKIT_CORE)
#  error Must not define both JSETOOLKIT_APP and JSETOOLKIT_CORE
#endif /* !JSETOOLKIT_APP && !JSETOOLKIT_CORE ... */

/******************************************************************************
 *** DEFAULT OPTIONS; TOOLKIT ASSUMES THESE OPTIONS; DO NOT UNDEFINE ANY OF ***
 *** THESE OPTIONS WITHOUT RECOMPILING ALL OF THE TOOLKIT SOURCE CODE;      ***
 *** UNDEFINING ANY OF THESE OPTIONS WILL MAKE USELESS ANY #LINK'S NOT      ***
 *** COMPILED WITH THE SAME OPTIONS.                                        ***
 ******************************************************************************/
#if !defined(JSE_MEM_DEBUG)
   /* JSE_MEM_DEBUG determines of jsemem allocation validation code is
    * included.  If this is turned on it should be in both the core
    * and the application.  JSE_MEM_DEBUG will slow the code down a lot
    * and so is only recommended for debug-time development.
    */
#  if defined(NDEBUG)
#     define JSE_MEM_DEBUG 0
#  else
#     define JSE_MEM_DEBUG 1
#  endif
#endif

/* The compiler can be turned off, so this can only play tokens. Without
 * the compiler this cannot read source code from string or from file
 */
#if !defined(JSE_COMPILER)
#  define JSE_COMPILER 1
#endif
#if (0 == JSE_COMPILER)
   /* if compiler is off then many other options don't make sense either */
#  if defined(JSE_TOKENSRC)
#     if 0 != JSE_TOKENSRC
#        error JSE_TOKENSRC invalid if not JSE_COMPILER
#     endif
#  else
#     define JSE_TOKENSRC 0
#  endif
#  if defined(JSE_TOKENDST)
#     if 0 == JSE_TOKENDST
#        error JSE_COMPILER=0 requires that JSE_TOKENDST also be set
#     endif
#  else
#     define JSE_TOKENDST 1
#  endif
#  if defined(JSE_INCLUDE)
#     if 0 != JSE_INCLUDE
#        error JSE_COMPILER=0 does not allow for JSE_INCLUDE
#     endif
#  else
#     define JSE_INCLUDE 0
#  endif
#  if defined(JSE_DEFINE)
#     if 0 != JSE_DEFINE
#        error JSE_COMPILER=0 does not allow for JSE_DEFINE
#     endif
#  else
#     define JSE_DEFINE 0
#  endif
#  if defined(JSE_CONDITIONAL_COMPILE)
#     if 0 != JSE_CONDITIONAL_COMPILE
#        error JSE_COMPILER=0 does not allow for JSE_CONDITIONAL_COMPILE
#     endif
#  else
#     define JSE_CONDITIONAL_COMPILE 0
#  endif
#  if defined(JSE_TOOLKIT_APPSOURCE)
#     if 0 != JSE_TOOLKIT_APPSOURCE
#        error JSE_COMPILER=0 does not allow for JSE_TOOLKIT_APPSOURCE
#     endif
#  else
#     define JSE_TOOLKIT_APPSOURCE 0
#  endif
#  if !defined(JSE_SECUREJSE)
#     define JSE_SECUREJSE 0
#  endif
#endif

#if !defined(JSE_TOKENSRC)
#     if defined(_MSC_VER) && _MSC_VER == 800
         /* msvc 1.52 grows too big */
#        define JSE_TOKENSRC 0
#     else
#        define JSE_TOKENSRC 1
#     endif
#endif
#if !defined(JSE_TOKENDST)
#     if defined(_MSC_VER) && _MSC_VER == 800
         /* msvc 1.52 grows too big */
#        define JSE_TOKENDST 0
#     else
#        define JSE_TOKENDST 1
#     endif
#endif
#if !defined(JSE_SECUREJSE)
#  if defined(__JSE_DOS16__)
#     define JSE_SECUREJSE 0
#  elif defined(__JSE_EPOC32__)
#     define JSE_SECUREJSE 0
#  elif defined(__JSE_WINCE__)
#     define JSE_SECUREJSE 0
#  else
#     define JSE_SECUREJSE 1
#  endif
#endif
#if !defined(JSE_C_EXTENSIONS)
#  define JSE_C_EXTENSIONS    1
#endif
#if !defined(JSE_LINK)
#  if defined(__JSE_DOS16__) || defined(__JSE_DOS32__) \
   || defined(__JSE_PSX__) || defined(__JSE_EPOC32__) \
   || defined(__JSE_390__) || defined(__JSE_PALMOS__) \
   || defined(__JSE_IOS__)
#     define JSE_LINK  0
#  else
#     define JSE_LINK  1
#  endif
#endif
#if !defined(JSE_INCLUDE)
#  if defined(__JSE_IOS__)
#     define JSE_INCLUDE 0
#  else
#     define JSE_INCLUDE 1
#  endif
#endif
#if !defined(JSE_DEFINE)
#  define JSE_DEFINE 1
#endif
#if !defined(JSE_CONDITIONAL_COMPILE)
#  define JSE_CONDITIONAL_COMPILE 1
#endif
#if !defined(JSE_TOOLKIT_APPSOURCE)
#  if defined(__JSE_IOS__)
#     define JSE_TOOLKIT_APPSOURCE 0
#  else
#     define JSE_TOOLKIT_APPSOURCE 1
#  endif
#endif
#if !defined(JSE_TOOLKIT_APPSOURCE) || (0==JSE_TOOLKIT_APPSOURCE)
#  if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
#     error cannot define JSE_INCLUDE without JSE_TOOLKIT_APPSOURCE
#  endif
#endif

/* Prototypes allow jse classes to inherit from other classes */
#if !defined(JSE_PROTOYPES)
#  define JSE_PROTOTYPES 1
#endif
/* Dynamic Objects allow overwritting of _get, _put, _delete, and
 * other methods of objects.
 */
#if !defined(JSE_DYNAMIC_OBJS)
#  define JSE_DYNAMIC_OBJS 1
#endif

#if !defined(JSE_OPERATOR_OVERLOADING) && \
    defined(JSE_DYNAMIC_OBJS) && (0!=JSE_DYNAMIC_OBJS)
#  define JSE_OPERATOR_OVERLOADING  1
#endif

#if !defined(JSE_DYNAMIC_OBJ_INHERIT)
   /* if have dynamic objs, then by default inherit them
    * through the _prototype
    */
#  define JSE_DYNAMIC_OBJ_INHERIT JSE_DYNAMIC_OBJS
#endif

#if !defined(JSE_NUMTOSTRING_ROUNDING)
#  define JSE_NUMTOSTRING_ROUNDING 1
   /* many script users will not want numbers as strings to print out with
    * a lot of final characters to indicate they are "very close" to some
    * decimal number.  For example, they may want (3.3).toString() to
    * be "3.3" and not "3.300000000001" or "3.299999999999".  If
    * JSE_NUMTOSTRING_ROUNDING is set to 0 at compilation time then
    * this rounding will not occur.  Pure ECMAScript implementations will
    * not want this rounding.
    */
#endif

/*********************************************************************
 * Error messages define the level and type of API messages available
 * from the API (see jseGetLastApiError, jseClearLastApiError, and
 * jseApiOK).  If these default levels are change then you must also
 * change the core API.  Error Level 0 corresponds to no error
 * reporting, Error Level 1 is for simple error messages such as
 * checks against NULL values where NULL is not allowed.  Error Level
 * 2 provides a finer validation on all parameters that are of the
 * common types (jseContext,jseVariable,jseCallStack).  Setting
 * JSE_API_ASSERTNAMES to 0 means that errors will not be
 * accompanied with function names, else they will have funciton names.
 */
#if !defined(JSE_API_ASSERTLEVEL)
#  if defined(__JSE_DOS16__) || defined(__JSE_WINCE__) || defined (__JSE_GEOS__)
#     define JSE_API_ASSERTLEVEL 0
#  else
#     define JSE_API_ASSERTLEVEL 2
#  endif
#endif
#if !defined(JSE_API_ASSERTNAMES)
#  if defined(__JSE_DOS16__) || defined(__JSE_WINCE__) || defined (__JSE_GEOS__)
#     define JSE_API_ASSERTNAMES 0
#  else
#     define JSE_API_ASSERTNAMES 1
#  endif
#endif
#if ( JSE_API_ASSERTLEVEL < 1 ) && (JSE_API_ASSERTNAMES == 1)
#  error cannot define JSE_API_ASSERTNAMES if JSE_API_ASSERTLEVEL is zero
#endif

/* Resource strings are often the error messages that report on a problem.
 * To save memory you may want to revert to the compact resource strings
 * which may only be an error number
 */
#if !defined(JSE_SHORT_RESOURCE)
#  if defined(__JSE_DOS16__)
#     define JSE_SHORT_RESOURCE 0
#  else
#     define JSE_SHORT_RESOURCE 0
#  endif
#endif

#if !defined(JSE_MIN_MEMORY)
#  if defined(__JSE_DOS16__) || defined(__JSE_WINCE__) || defined(__JSE_IOS__)
#     define JSE_MIN_MEMORY 1
#  else
#     define JSE_MIN_MEMORY 0
#  endif
#endif

/* JSE_INLINES can let some functions be compiled in-line, via
 * macros. This can improve performance but uses more memory
 */
#if !defined(JSE_INLINES)
   /* by default, JSE_INLINES will have the opposite setting of JSE_MIN_MEMORY */
#  if 0 == JSE_MIN_MEMORY
#     define JSE_INLINES 1
#  else
#     define JSE_INLINES 0
#  endif
#endif

#if !defined(JSE_MULTIPLE_GLOBAL)
   /* multiple globals allows for the global variable to be changed, and
    * for each script function to remember and restore it's global
    * variable while executing
    */
#  define JSE_MULTIPLE_GLOBAL 1
#endif


#if defined(JSETOOLKIT_APP)
#  define JSE_WIN32_DECL             __declspec(dllimport)
#else /* defined(JSETOOLKIT_CORE) */
#  define JSE_WIN32_DECL             __declspec(dllexport)
#endif

#if defined(__JSE_UNIX__) || defined(__JSE_NWNLM__) \
 || defined(__JSE_390__) \
 || defined(__DJGPP__) || defined(__JSE_PSX__) \
 || defined(__JSE_PALMOS__)
#  define JSE_CFUNC
#  define JSE_PFUNC
#elif defined (__JSE_MAC__)
#  define JSE_CFUNC
#  define JSE_PFUNC        pascal
#else
#  define JSE_CFUNC        __cdecl
#  define JSE_PFUNC        __pascal
#endif
 
#if defined(__JSE_LIB__)
   /* the interpreter is a static library */
#  if   defined(__JSE_DOS16__)
#     define JSECALLSEQ(type)         type __far __cdecl
#  elif defined(__JSE_DOS32__) && !defined(__DJGPP__)
#     define JSECALLSEQ(type)         type __cdecl
#  elif defined(__JSE_OS2TEXT__)
#     define JSECALLSEQ(type)         type __cdecl
#  elif defined(__JSE_OS2PM__)
#     define JSECALLSEQ(type)         type __cdecl
#  elif defined(__JSE_WIN16__)
#     define JSECALLSEQ(type)         type __far __cdecl
#  elif defined(__JSE_WIN32__)
#     define JSECALLSEQ(type)         type __cdecl
#  elif defined(__JSE_CON32__)
#     define JSECALLSEQ(type)         type __cdecl
#  elif defined(__JSE_NWNLM__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_UNIX__) || defined(__DJGPP__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_MAC__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_PSX__) || defined(__JSE_PALMOS__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_EPOC32__)
#     define JSECALLSEQ(type)         type
#  else
#     error platform not defined
#  endif
#else
   /* the interpreter is a dynamic-linked library */
#  if   defined (__JSE_GEOS__)
#     define JSECALLSEQ(type)         type __far __export __pascal
#     define JSECALLSEQ_CFUNC(type)   type __far __export __cdecl
#  elif defined(__JSE_DOS16__)
#     define JSECALLSEQ(type)         type __far __cdecl
#  elif defined(__JSE_DOS32__)
#     define JSECALLSEQ(type)         type __cdecl
#  elif defined(__JSE_OS2TEXT__)
#     define JSECALLSEQ(type)         type __export __cdecl
#  elif defined(__JSE_OS2PM__)
#     define JSECALLSEQ(type)         type __export __cdecl
#  elif defined(__JSE_WIN16__)
#     define JSECALLSEQ(type)         type __export __far __cdecl
#  elif defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#     if defined(__BORLANDC__) || defined(__WATCOMC__)
#        define JSECALLSEQ(type)         type __export __cdecl
#     else
#        define JSECALLSEQ(type)         JSE_WIN32_DECL type __cdecl
#     endif
#  elif defined(__JSE_NWNLM__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_UNIX__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_390__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_MAC__)
#     define JSECALLSEQ(type)         type
#  elif defined(__JSE_PSX__) || defined(__JSE_PALMOS__)
#     define JSECALLSEQ(type)         type
#  else
#     error platform not defined
#  endif
#endif

/* These are needed to set up dgroup in external functions */
#if !defined(__JSE_GEOS__)
#  define JSECALLSEQ_CFUNC(type) JSECALLSEQ(type)
#endif

/*********************************
 *** ENUMERATED VARIABLE TYPES ***
 *********************************/
#if !defined(JSE_TYPE_BUFFER)
#  define JSE_TYPE_BUFFER 1
#endif

/* enumerate all possible type of jse variables */
typedef uword8 jseDataType;
#  define  jseTypeUndefined  0
#  define  jseTypeNull       1
#  define  jseTypeBoolean    2
#  define  jseTypeObject     3
#  define  jseTypeString     4
#  define  jseTypeNumber     5
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
#  define  jseTypeBuffer     6
#endif

/* enumerate treatment of variables returned from jse library functions */
typedef int jseReturnAction;
#  define jseRetTempVar       0
      /* This is a temporary variable and may be removed when it is popped */
#  define jseRetCopyToTempVar 1
      /* Create a temp var and copy to that; don't remove this variable */
#  define jseRetKeepLVar      2
      /* This LVar cannot be popped */


/* These correspond to ToBoolean(), et al in section 9 of the
 * ECMAScript document
 */
typedef int jseConversionTarget;
#  define jseToPrimitive  0
#  define jseToBoolean    1
#  define jseToNumber     2
#  define jseToInteger    3
#  define jseToInt32      4
#  define jseToUint32     5
#  define jseToUint16     6
#  define jseToString     7
#  define jseToObject     8

#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
#  define jseToBytes      9  /* Converts to a buffer type, the buffer
                              * containing the ra bytes (i.e. a number is the
                              * 80 bits of the number, NULL is a pointer (4
                              * bytes), etc.) Objects just give you the same
                              * as their ToString value, not the bytes it
                              * represents
                              */
#  define jseToBuffer    10  /* Converts to a string just like ToString, but
                              * the string i  0 in ascii (i.e. the number 10
                              * gives you "10"), and for unicode string
                              * characters, the upper byte is ignored. It IS
                              * null-terminated.
                              */
#endif

/***************************************************************
 *** HANDLES (ABSTRACTIONS) TO INTERNAL DATA REPRESENTATIONS ***
 ***************************************************************/

#if !defined(JSE_TRACKVARS)
#  if !defined(NDEBUG)
#     define JSE_TRACKVARS 1
#  else
#     define JSE_TRACKVARS 0
#  endif
#endif


/* define some classes to use for stronger typechecking */
#if defined(__MWERKS__) && !defined(NDEBUG) && defined(JSETOOLKIT_APP)
   /* We cannot debug properly with blank structures */
   typedef void * jseContext;
   typedef void * jseStack;
   typedef void * jseVariable;
#else
#  if defined(JSETOOLKIT_APP)
#   if !defined(__JSE_GEOS__)
      struct Call { int call_unused; };
      struct seCallStack { int jsecallstack_unused; };
      struct seAPIVar { int var_unused; };
#   endif
#  endif
   typedef struct Call * jseContext;
   /* Calling context for parameters, returns, re-entrancy, and multitasking */
   typedef struct seCallStack * jseStack;
   /* temporary variables, and parameter passing */
   typedef struct seAPIVar * jseVariable;
#endif


/***********************************************************
 *** JSE VARIABLE CREATION, DEFINITIONS, AND DESTRUCTION ***
 ***********************************************************/

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseCreateVariable(jseContext jsecontext,
                                             jseDataType VType);
   JSECALLSEQ(jseVariable) jseCreateSiblingVariable(jseContext jsecontext,
      jseVariable olderSiblingVar,
      JSE_POINTER_SINDEX elementOffsetFromOlderSibling);
   JSECALLSEQ(jseVariable) jseCreateConvertedVariable(jseContext jsecontext,
      jseVariable variableToConvert,jseConversionTarget targetType);
   JSECALLSEQ(jseVariable) jseCreateLongVariable(jseContext jsecontext,
                                                 slong value);  /* shortcut */
   JSECALLSEQ(jseVariable)  jseFindVariable(jseContext jsecontext,
                                            const jsecharptr name, ulong flags);
      /* NOTE: the only flag current used should be 'jseCreateVar' */
#endif
JSECALLSEQ(void) jseDestroyVariable(jseContext jsecontext,jseVariable variable);
JSECALLSEQ(jsebool) jseGetVariableName(jseContext jsecontext,
   jseVariable variableToFind, jsecharptr const buffer, uint bufferSize);

#if !defined(JSE_CREATEFUNCTIONTEXTVARIABLE)
#  if (0==JSE_COMPILER) || (0!=JSE_MIN_MEMORY)
#     define JSE_CREATEFUNCTIONTEXTVARIABLE  0
#  else
#     define JSE_CREATEFUNCTIONTEXTVARIABLE  1
#  endif
#endif
#if (0!=JSE_CREATEFUNCTIONTEXTVARIABLE)
#  if (0==JSE_COMPILER)
#     error JSE_CREATEFUNCTIONTEXTVARIABLE is incompatible if not JSE_COMPILER
#  endif
#  if defined(NDEBUG) || JSE_TRACKVARS==0
      JSECALLSEQ( jseVariable ) jseCreateFunctionTextVariable(jseContext jsecontext,
                                                              jseVariable FuncVar);
         /* Returns a jseVariable of type jseTypeString that contains the text of the
          * function (ex: "function foo(a) { a=4; }") The variable provided must be
          * a function
          */
#  endif
#endif

JSECALLSEQ(JSE_POINTER_UINDEX) jseGetArrayLength(jseContext jsecontext,
   jseVariable variable,JSE_POINTER_SINDEX *MinIndex);
   /* return Length, set MinIndex if not NULL */
JSECALLSEQ(void) jseSetArrayLength(jseContext jsecontext,jseVariable variable,
   JSE_POINTER_SINDEX MinIndex,JSE_POINTER_UINDEX Length);
   /* grow or shrink to this size */

/* Members of objects have the following properties */

typedef uword8 jseVarAttributes;
#  define  jseDefaultAttr       0x00
      /* Do nothing special */
#  define  jseDontEnum          0x01
      /* Don't enumerate(list when all are requested) this item. */
#  define  jseDontDelete        0x02
      /* Don't allow deletes on this element */
#  define  jseReadOnly          0x04
      /* Make this Read Only */
   /* These two only apply to functions */
#  define  jseImplicitThis      0x08
      /* add this to the scoping chain */
#  define  jseImplicitParents   0x10
      /* also add the prototype chain of this */


#  define  jseEcmaArray         0x20
      /* once you mark an object as an ecmaarray, it always is,
       * but it is 'removed' from the attributes - this only applies
       * to 'jseSetAttributes'
       */
#  define jseDynamicOnUndefined 0x40
      /* Once marked, the object stays this way. Dynamic functions
       * will only be called on this object if the member doesn't
       * already exist in the object's internal structure.
       */

JSECALLSEQ(void) jseSetAttributes(jseContext jsecontext,jseVariable variable,
                                  jseVarAttributes attr);
JSECALLSEQ(jseVarAttributes) jseGetAttributes(jseContext jsecontext,
                                              jseVariable variable);

#if !defined(JSE_OBJECTDATA)
   /* by default turn these functions on, otherwise they are handled
    * externally in SEOBJFUN.C
    */
#  define JSE_OBJECTDATA 1
#endif
#if JSE_OBJECTDATA != 0
   JSECALLSEQ(void) jseSetObjectData(jseContext jsecontext,
                                     jseVariable objectVariable,
                                     void _FAR_ *data);
      /* set data pointer associated with this object variable */
   JSECALLSEQ(void _FAR_ *) jseGetObjectData(jseContext jsecontext,
                                             jseVariable objectVariable);
      /* get data pointer associated with this object variable */
#endif

/********************************
 *** JSE VARIABLE DATA ACCESS ***
 ********************************/

JSECALLSEQ(jseDataType) jseGetType(jseContext jsecontext,jseVariable variable);
JSECALLSEQ(void) jseConvert(jseContext jsecontext,jseVariable variable,
                            jseDataType dType);
   /* False and print error and LibError is set; else True */
JSECALLSEQ(jsebool) jseAssign(jseContext jsecontext,jseVariable destVar,
                              jseVariable srcVar);
   /* False and print error; else True */

JSECALLSEQ(slong) jseGetLong(jseContext jsecontext,jseVariable variable);
JSECALLSEQ(void) jsePutLong(jseContext jsecontext,jseVariable variable,
                            slong longValue);

#define jseGetByte(jsecontext,variable) \
        (ubyte)jseGetLong(jsecontext,variable)
#define jsePutByte(jsecontext,variable,ubyteValue) \
        jsePutLong(jsecontext,variable,(slong)ubyteValue)

JSECALLSEQ(jsebool) jseGetBoolean(jseContext jsecontext,jseVariable variable);
JSECALLSEQ(void) jsePutBoolean(jseContext jsecontext,jseVariable variable,jsebool boolValue);

JSECALLSEQ(void) jsePutNumber(jseContext jsecontext,jseVariable variable,
                              jsenumber number);

/* because we cannot be assured that all compilers and link methods return
 * floats in the same way, we'll return them indirectly and let a local
 * version of the call in globldat.c handle it
 */
JSECALLSEQ(void) jseGetFloatIndirect(jseContext jsecontext,
                                     jseVariable variable,
                                     jsenumber *GetFloat);

#if (0!=JSE_FLOATING_POINT)
   jsenumber jseGetNumber(jseContext jsecontext,jseVariable variable);
#else
   /* if floating point is off then getnumber is the same as getlong */
#  define jseGetNumber(JSECONTEXT,JSEVARIABLE) jseGetLong(JSECONTEXT,JSEVARIABLE)
#endif

typedef void _HUGE_ * jseHugeRetPtr;

JSECALLSEQ( const jsecharhugeptr ) \
   jseGetString(jseContext jsecontext,jseVariable variable,
                JSE_POINTER_UINDEX *filled);
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
   JSECALLSEQ( const void _HUGE_ * ) \
      jseGetBuffer(jseContext jsecontext,jseVariable variable,
                   JSE_POINTER_UINDEX *filled);
   JSECALLSEQ( void _HUGE_ * ) jseGetWriteableBuffer(jseContext jsecontext,
      jseVariable variable,JSE_POINTER_UINDEX *filled);
   JSECALLSEQ( void ) jsePutBuffer(jseContext jsecontext,
      jseVariable variable,const void _HUGE_ *data,
      JSE_POINTER_UINDEX size);
   JSECALLSEQ( JSE_POINTER_UINDEX ) jseCopyBuffer(jseContext jsecontext,
      jseVariable variable,void _HUGE_ *buffer,
      JSE_POINTER_UINDEX start,JSE_POINTER_UINDEX length);
#endif
JSECALLSEQ( jsecharhugeptr ) jseGetWriteableString(jseContext jsecontext,
   jseVariable variable,JSE_POINTER_UINDEX *filled);
JSECALLSEQ( void ) jsePutString(jseContext jsecontext,
   jseVariable variable,const jsecharhugeptr data);
JSECALLSEQ( void ) jsePutStringLength(jseContext jsecontext,
   jseVariable variable,const jsecharhugeptr data,
   JSE_POINTER_UINDEX length);
JSECALLSEQ( JSE_POINTER_UINDEX ) jseCopyString(jseContext jsecontext,
   jseVariable variable,jsecharhugeptr buffer,
   JSE_POINTER_UINDEX start,JSE_POINTER_UINDEX length);

/* The jseSetErrno API function has been rendered obsolete.  This macro
 * is kept for backwards compatibility
 */
#define jseSetErrno(jsecontext,errno_val)  \
   errno = (int) errno_val

JSECALLSEQ(jsebool) jseEvaluateBoolean(jseContext jsecontext,
                                       jseVariable variable);
   /* return boolean True or False */

JSECALLSEQ(jsebool) jseCompare(jseContext jsecontext,
   jseVariable variable1,jseVariable variable2,
   slong *CompareResult /* negative, zero, or positive long returned */);
   /* if error (comparing incomparable types) then error will have printed
    * and return False, else return True.
    *
    * The possible results of 'CompareResult' are as follows:
    *   -1 - incomparable types, such as with NaN when the
    *        'warn on bad math' flag is on.
    *    0 - comparison returns False.
    *    1 - comparison returns True.
    */


/* We have extended the jseCompare() function to act like the old function
 * but also be able to mimic two new functions which handle ECMA compares
 * much better. All old code will still work. You ought not to call
 * jseCompare() directly in this new way, instead using the new functions
 * jseCompareEquality() and jseCompareLess().
 */
#define JSE_COMPEQUAL ((slong *)-1)
#define JSE_COMPLESS  ((slong *)-3)

/* When the API returns a variable, it returns a handle to the variable
 * which is mapped internally so the engine knows you've used it. If you
 * get the same variable again, probably a different pointer will be
 * returned, even if they refer underneath to the same variable. This
 * flag simply tests if the two variables refer to the same underlying
 * variable. For instance, jseFuncVar(jsecontext,0)!=jseFuncVar(jsecontext,0)
 * but jseCompare(jsecontext,jseFuncVar(jsecontext,0),jseFuncVar(jsecontext,0),JSE_COMPVAR)
 * will return True.
 */
#define JSE_COMPVAR   ((slong *)-5)

/* Test to see if the first variable is less than the second in the
 * ECMA definition. It is more than twice as fast as using jseCompare().
 * Note that you can do any relation in this way (greater than is less
 * with parameters swapped, greater than or equal is !less, etc.)
 *
 * Relational (<,>,<=,>=) are done differently than equality comparisons
 * in ECMAScript. Please see the ECMA document section 11.8.5 and 11.9.3
 * for the algorithms used.
 */
#define jseCompareLess(c,v1,v2) (jseCompare((c),(v1),(v2),JSE_COMPLESS))


/* In ECMAscript, equality is tested differently than relations. This
 * routine allows you test is two variables to see if they are the same
 * by this definition. jseCompare() will always give you an answer based
 * on the relational algorithm (see jseCompareLess() for a description
 * of the difference.) If you want to test if they are the same, use this
 * routine. This routine will test to see if two objects are the same
 * the way you would expect (i.e. do they point to the same object) whereas
 * jseCompare() tries to convert them to primitives and compare that way
 * as per ECMA relational comparisons.
 */
#define jseCompareEquality(c,v1,v2) (jseCompare((c),(v1),(v2),JSE_COMPEQUAL))


/******************************************************
 *** OBJECT VARIABLES AND THEIR MEMBER VARIABLES ***
 ******************************************************/

/* The above four functions are also available in an Ex form, where the extra
 * flags define more control over the variables returned.  If the
 * jseCreateVar flag is not set then the variable references are automatially
 * cleaned up when the current context (or callback function) returns.  The
 * above four functions are identical to these with the last parameter set to
 * jseDefault (i.e. 0).  The jseCreateVar can be used with either (or neither),
 * but jseLockRead or jseLockWrite are mutually exclusive. The LOCK flags lock
 * the variable reference for the given state until the variable is deleted
 * (either through jseDestroyVariable on jseCreateVar or through implicit
 * auto-cleanup delete when the local context is exited).
 */
typedef uword16 jseActionFlags;
#define jseActionDefault       0x0
#define jseCreateVar 0x1    /* ISDK user must explicitly jseDeleteVariable */
#define jseLockRead  0x4000 /* lock variable state for reading */
#define jseLockWrite 0x8000 /* lock variable state for writing */
#define jseDontCreateMember    0x08
#define jseDontSearchPrototype 0x10
#define jseCheckHasProperty    0x20

#define jseGetMember(jsecontext,objectVariable,Name) \
        jseMemberInternal(jsecontext ,objectVariable,Name,jseTypeUndefined,jseDontCreateMember|jseCheckHasProperty)
#define jseGetMemberEx(jsecontext,objectVar,Name,flags) \
        jseMemberInternal(jsecontext,objectVar,Name,jseTypeUndefined, \
                    ((jseActionFlags)((flags)|jseDontCreateMember|jseCheckHasProperty)))
#define jseMember(jsecontext,objectVar,Name,DType) \
        jseMemberInternal(jsecontext,objectVar,Name,DType,jseDontSearchPrototype)
#define jseMemberEx(jsecontext,objectVar,Name,DType,flags) \
        jseMemberInternal(jsecontext,objectVar,Name,DType,(flags)|jseDontSearchPrototype)

#define jseGetIndexMember(jsecontext,objectVariable,index) \
        jseGetIndexMemberEx(jsecontext,objectVariable,index,jseDontCreateMember|jseCheckHasProperty)
#define jseGetIndexMemberEx(jsecontext,objectVar,index,flags) \
        jseIndexMemberEx(jsecontext,objectVar,index,jseTypeUndefined, \
                        ((jseActionFlags)((flags)|jseDontCreateMember|jseCheckHasProperty)))
#define jseIndexMember(jsecontext,objectVar,index,DType) \
        jseIndexMemberEx(jsecontext,objectVar,index,DType,jseDontSearchPrototype)

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseMemberInternal(jseContext jsecontext,
         jseVariable objectVar,
         const jsecharptr Name,jseDataType DType,jseActionFlags flags);
   JSECALLSEQ(jseVariable) jseIndexMemberEx(jseContext jsecontext,
         jseVariable objectVar,
         JSE_POINTER_SINDEX index,jseDataType DType,jseActionFlags flags);
#endif

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseGetNextMember(jseContext jsecontext,
      jseVariable objectVariable,jseVariable prevMemberVariable,
      const jsecharptr * name);
      /* return next object member after PrevVariable.  If PrevVariable is NULL
       * then return first member.  Name will point to the variable name; DO NOT
       * ALTER NAME DATA
       */
#endif
JSECALLSEQ(void) jseDeleteMember(jseContext jsecontext,
   jseVariable objectVariable,const jsecharptr name);
   /* remove the member of this object variable with the given name.  If name
    * is NULL then delete all members.  It is not an error to pass in a Name
    * that does not exist, in which case this function just returns without
    * doing anything.
    */

/******************************
 *** GLOBAL VARIABLE OBJECT ***
 ******************************/

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseGlobalObjectEx(jseContext jsecontext,
                              jseActionFlags flags/* 0 or jseCreateVar */);
#endif
#define jseGlobalObject(CONTEXT) jseGlobalObjectEx(CONTEXT,0)

JSECALLSEQ(void) jseSetGlobalObject(jseContext jsecontext,jseVariable newGlobal);

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseActivationObject(jseContext jsecontext);
      /* return the local object for function being called; or NULL if
       * in global code area
       */
#endif

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseGetCurrentThisVariable(jseContext jsecontext);
      /* get current var referred to by "this" in function calls; the var passed
       * to jseCallFunction or the global
       */
#endif



/*********************
 *** THE JSE STACK ***
 *********************/

JSECALLSEQ(jseStack) jseCreateStack(jseContext jsecontext);
JSECALLSEQ(void) jseDestroyStack(jseContext jsecontext,jseStack stack);
JSECALLSEQ(void) jsePush(jseContext jsecontext,jseStack jsestack,
                         jseVariable var,jsebool DeleteVariableWhenFinished);
#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable)  jsePop(jseContext jsecontext, jseStack jsestack);
#endif


/***************************************************************
 *** ACCESS INPUT PARAMETERS FROM EXTERNAL LIBRARY FUNCTIONS ***
 ***************************************************************/

/* function parameter type-checking; specify type if input variable;
 * or dimension with the NEED type
 */
typedef uword32 jseVarNeeded;

#define JSE_VN_UNDEFINED   ( (jseVarNeeded)(1 << jseTypeUndefined) )
#define JSE_VN_NULL        ( (jseVarNeeded)(1 << jseTypeNull) )
#define JSE_VN_BOOLEAN     ( (jseVarNeeded)(1 << jseTypeBoolean) )
#define JSE_VN_OBJECT      ( (jseVarNeeded)(1 << jseTypeObject) )
#define JSE_VN_STRING      ( (jseVarNeeded)(1 << jseTypeString) )
#define JSE_VN_NUMBER      ( (jseVarNeeded)(1 << jseTypeNumber) )
#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
# define JSE_VN_BUFFER     ( (jseVarNeeded)(1 << jseTypeBuffer) )
#endif

#define JSE_VN_FUNCTION    ( (jseVarNeeded) 0x0080 )
   /* special test of object type AND callable function */
#define JSE_VN_BYTE        ( (jseVarNeeded) 0x0100 )
   /* special case of VN_NUMBER, not used for PREFER or CONVERT */
#define JSE_VN_INT         ( (jseVarNeeded) 0x0200 )
   /* special case of VN_NUMBER, not used for PREFER or CONVERT */
#define JSE_VN_COPYCONVERT ( (jseVarNeeded) 0x0400 )
   /* special flag to create a copy of this variable if it has to be
    * converted; might also add an auto-temp variable unless
    * JSE_VN_CREATEVAR is set
    */
#define JSE_VN_LOCKREAD    ( (jseVarNeeded) 0x1000 )
   /* var will be used only for reading. An auto-temp var unless JSE_VN_CREATEVAR */
#define JSE_VN_LOCKWRITE   ( (jseVarNeeded) 0x2000 )
   /* var will be used only for writing. An auto-temp var unless JSE_VN_CREATEVAR */
#define JSE_VN_CREATEVAR   ( (jseVarNeeded) 0x0800 )
   /* if JSE_VN_LOCKREAD or JSE_VN_LOCKWRITE then this puts the caller
    * in charge of destroying this variable reference, else it will
    * be destroyed automatically when wrapper function returns
    */

#if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
#  define JSE_VN_ANY \
      (JSE_VN_UNDEFINED|JSE_VN_NULL|JSE_VN_BOOLEAN|JSE_VN_OBJECT\
       |JSE_VN_STRING|JSE_VN_BUFFER|JSE_VN_NUMBER)
#else
#  define JSE_VN_ANY \
      (JSE_VN_UNDEFINED|JSE_VN_NULL|JSE_VN_BOOLEAN|JSE_VN_OBJECT\
       |JSE_VN_STRING|JSE_VN_NUMBER)
#endif
#define JSE_VN_NOT(UNWANTED_TYPES)  ((JSE_VN_ANY)&(~(UNWANTED_TYPES)))

#define JSE_VN_CONVERT(VN_FROM_TYPES,VN_TO_TYPE) \
   (VN_TO_TYPE|(((uword32)VN_TO_TYPE)<<16)|(((uword32)VN_FROM_TYPES)<<24))

JSECALLSEQ(uint) jseFuncVarCount(jseContext jsecontext);
#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseFuncVar(jseContext jsecontext,uint ParameterOffset);
      /* return NULL for error; message already printed and error flag already set
       * will only return NULL if ParameterOffset is invalid, and so if you
       * know offset is valid (e.g., by FunctionList min and max) then you
       * don't need to check for NULL.
       */
   JSECALLSEQ(jseVariable) jseFuncVarNeed(jseContext jsecontext,
                                          uint parameterOffset,
                                          jseVarNeeded need);
      /* return NULL for error; message already printed and error flag already
       * set; no data tying, not even dimension, is checked if need==0 (i.e.,
       * no bits set in need)
       */
#endif
JSECALLSEQ(jsebool) jseVarNeed(jseContext jsecontext,
                               jseVariable variable,jseVarNeeded need);
   /* similar to FuncVarNeed but already have variable */

/* The macro below is convenient when initializing library functions
 * to get the variables from the stack.  If there is an error then it
 * automatically sets error flags and then return from the function.
 * CAUTION! If there is an error then the statements following these
 * macros are not executed, and so don't use these if you need to perform
 * cleanup. Note that the 'C' version must have already declared the variable
 * uses as the first parameter.
 */
#define JSE_FUNC_VAR_NEED(varname,context,ParameterOffset,need) \
   if ( NULL == (varname = jseFuncVarNeed(context,ParameterOffset,need)) ) \
      return

/*****************************************************************
 *** METHODS TO RETURN VARIABLE FROM EXTERNAL LIBRARY FUNCTION ***
 *****************************************************************/

JSECALLSEQ(void) jseReturnVar(jseContext jsecontext,jseVariable variable,
                              jseReturnAction RetAction);
JSECALLSEQ(void) jseReturnLong(jseContext jsecontext,slong longValue);
JSECALLSEQ(void) jseReturnNumber(jseContext jsecontext,jsenumber number);

/**********************************************************
 *** ENGINE: INITIALIZE AND TERMINATE ENGINE ONLY ONCE. ***
 *** GLOBALY CALL BEFORE/AFTER *ANY OTHER* CALLS        ***
 **********************************************************/
#if defined(JSE_MEM_DEBUG) && (0!=JSE_MEM_DEBUG) && defined(__JSE_LIB__)
   /* alter version so core-debug doesn't link with non-core debug */
#  define JSE_ENGINE_VERSION_ID    (440 | 0x8000)
#  define JSE_VERSION_STRING       UNISTR("A - JSE_MEM_DEBUG")
#else
#  define JSE_ENGINE_VERSION_ID    440
#  define JSE_VERSION_STRING       UNISTR("A")   /* Minor version string */
#endif

JSECALLSEQ(uint) jseInitializeEngine(void);
   /* Call this before any other call in the jse toolkit. Return ID of engine
    * for version # verification.
    */
JSECALLSEQ(void) jseTerminateEngine(void);
   /* this must be that absolute last call. No more toolkit functions may be
    * called after this one.
    */



/***********************************************************
 *** EXTERNAL LINK: FOR ANY CREATED TOP-LEVEL JSECONTEXT ***
 *** INITIALIZE EXTERNAL LINK MUST BE THE FIRST CALL AND ***
 *** TERMINATE EXTERNAL LINK MUST BE THE LAST TO USE THE ***
 *** JSECONTEXT..  LINKDATA IS ALWAYS AVAILABLE          ***
 ***********************************************************/

/* Error Handling
 *
 * An error can be generated in a number of ways. A code error
 * can happen, like trying to read an undefined variable. An
 * API wrapper function can use jseLibErrorPrintf to generate
 * an error. The script can have a 'throw' statement.
 *
 * In any case, your 'jseAtErrorFunc' is immediately called.
 * A structure is passed to it that has information about
 * the error. This structure can be extended in future
 * releases. The first member is 'errorVariable'. This is
 * the error being generated. It is possible for this not
 * to be an object, but it usually is. For instance,
 * 'throw "foo";' will have the error variable be the
 * string "foo". All error objects can be transformed into
 * strings using 'jseCreateConvertedVariable(...,jseToString)'.
 *
 * The second parameter, trapped, determines whether or
 * not the error will be trapped. Simply, if it is not trapped,
 * your PrintError function (see below) will be called immediately
 * after the AtError function. It means that no 'try/catch'
 * handlers are in effect that could possibly catch the
 * error. At any rate, you are free to examine the state of
 * the interpreter, check the line number, read variables,
 * and so forth. If you are a debugger, for instance, you
 * can check the kind of error object to determine if you
 * want to halt for the user, probably based on menu checks
 * he has made.
 *
 * The ErrorMessageFunc is called to deliver an error message
 * to the user. Usually, you will print this to the screen or
 * pop up a dialog box with the information. You can check
 * variables, and so forth. However, note that this function
 * is not called until the error is no longer trapped. For
 * instance, if you are in a try block, then no error message
 * will be printed at the point of the error, instead the
 * code will unwind and the 'catch' handler gets to decide
 * what to do with the message.
 *
 * In a simple script, that uses no try/catch handling,
 * the error function will print at the point of the error.
 * In this case, the AtError func will be called first if
 * it exists. 'trapped' in the AtErrorStruct will be False.
 * When this function returns, the ErrorMessageFunc will
 * be called immediately after.
 */
struct AtErrorStruct
{
   jseVariable errorVariable;
   jsebool trapped;
};

typedef void    (JSE_CFUNC FAR_CALL *jseErrorMessageFunc)\
   (jseContext jsecontext,const jsecharptr ErrorString);
typedef void    (JSE_CFUNC FAR_CALL *jseAtErrorFunc)\
   (jseContext jsecontext,struct AtErrorStruct *info);

typedef jsebool (JSE_CFUNC FAR_CALL *jseMayIContinueFunc)(jseContext);
typedef jsebool (JSE_CFUNC FAR_CALL *jseFileFindFunc)(jseContext,
   const jsecharptr FileSpec, jsecharptr FilePathResults,
   uint FilePathLen,jsebool FindLink);
   /* FindLink is True for finding file from #link statement */
typedef jseContext (JSE_CFUNC FAR_CALL *jseAppLinkFunc)\
   (jseContext jsecontext,jsebool Initialize);
   /* can be used to let the application create a new context initialized wih
    * globas, libs, defines, etc.., maybe in new thread
    */

   /* enumerate all possible type of jse variables */
   typedef int jseToolkitAppSourceFlags;
#   define  jseNewOpen      1
#   define  jseGetNext      2
#   define  jseClose        3

   struct jseToolkitAppSource
   {
      jsecharptr         code;      /* toolkit app sets this value */
      const jsecharptr const name;  /* toolkit app cannot write to this value */
      uint               lineNumber;/* app and core both can read/write */
      void *             userdata;  /* toolkit app uses this as it pleases */
#     if defined(__cplusplus)
         /* C++ demands constructor for the const field */
         jseToolkitAppSource() : name((const jsecharptr const)0) { }
         ~jseToolkitAppSource() { }
#     endif
   };

   typedef jsebool (JSE_CFUNC FAR_CALL *jseGetSourceFunc)\
      (jseContext jsecontext,struct jseToolkitAppSource * ToolkitAppSource,\
       jseToolkitAppSourceFlags flag);

#  if defined(__JSE_GEOS__)
   typedef jsebool (JSE_CFUNC FAR_CALL pcfm_jseGetSourceFunc)\
      (jseContext jsecontext,struct jseToolkitAppSource * ToolkitAppSource,\
       jseToolkitAppSourceFlags flag, void *pf);
#  endif

      /* This callback function is called from the core/libraries to get a
       * locale-dependent string corresponding to an error ID.  It is up
       * to the application to provide a method for getting this string.
       * If no function is supplied, then the builtin English default
       * strings will be used.  buflen is the size of buf in logical characters.
       * Return False if no translation was made.
       */
   typedef jsebool (JSE_CFUNC FAR_CALL *jseGetResourceFunc) \
      (jseContext jsecontext, sint id, jsecharptr buf, uint buflen);

typedef uword32  jseLinkOptions;

struct jseExternalLinkParameters {
  /* required: */
   jseErrorMessageFunc          PrintErrorFunc;

  /* for optional file I/O */
     jseFileFindFunc              FileFindFunc;
     jseGetSourceFunc             GetSourceFunc;

  /* For getting library strings */
     jseGetResourceFunc           GetResourceFunc;

  /* optional: set to NULL if not wanted */
   jseMayIContinueFunc          MayIContinue;
   jseAppLinkFunc               AppLinkFunc;
   jseAtErrorFunc               AtErrorFunc;

   /* These variables exactly correspond to the same SE:DESK security
    * variables. If any of the functions are NULL, they are not called
    * (and if it is jseSecurityGuard, that is considered failure.
    *
    * If the variable is NULL, a new object is created.
    *
    * just set these up and include jseNewSecurity. For compatibility
    * older versions, if all 3 functions are NULL, jseNewSecurity is
    * ignored.
    */
   jseVariable                  jseSecurityInit;
   jseVariable                  jseSecurityTerm;
   jseVariable                  jseSecurityGuard;
   jseVariable                  securityVariable;


   jseLinkOptions  options; /* flags for different behaviors */

   /* hashtable size refers to number of hash entries in table for strings
    * representing variable names (objects, properties).  use 0 for default.
    * if underlying interpreter was built without the hash option then
    * this field will be ignored.
    */
   uint        hashTableSize;
};
#define jseOptDefault               0
   /* all default behavior */
#define jseOptReqVarKeyword      0x01
   /* "var" keyword required for all variables */
#define jseOptDefaultLocalVars   0x02
   /* default local vars if not global */
      /* #define jseOptReqFunctionKeyword 0x04
       * "function" or "cfunction" keyword required
       * This option is not longer an option.  The
       * function keyword is now always required in
       * order to support that parsing changes needed
       * to support nested functions.
       */
#if defined(JSE_C_EXTENSIONS) && (0!=JSE_C_EXTENSIONS)
#  define jseOptDefaultCBehavior   0x08
   /* C function behavior by default */
#endif
#define jseOptWarnBadMath        0x10
   /* treat NaN results and div-by-0 as errors */
#define jseOptLenientConversion  0x20
   /* Convert any type of parameter with JSE_VN_CONVERT
    * Allow getting of any data type from any type of var
    */
#define jseOptIgnoreExtraParameters 0x40
   /* Ignore extra parameters to library functions */
#define jseOptToBooleanObjectEval   0x80
   /* without this flag, an object converted to a boolean
    * will always return true, even if that object represents
    * a false value (e.g. new Boolean(false).  With this
    * flag set objects will be converted to boolean with
    * this logic: ToBoolean(ToPrimitive(object)).
    */

#define jseSecureReject 0
#define jseSecureAllow 1
#define jseSecureGuard  2


JSECALLSEQ(jseContext) jseInitializeExternalLink(
#if defined(JSETOOLKIT_LINK)
              jseContext jsecontext,
#endif
              void _FAR_ *LinkData,
              struct jseExternalLinkParameters * LinkParms,
              const jsecharptr globalVarName,
              const char * AccessKey
          );
   /* First call to get the initial top-level context.  This may be
    * called multiple times after jseInitializeEngine for various
    * contexts in threads or multiple levels of interpretation.
    * GlobalObjectName is the name of the global object.
    * AccessKey is your Nombas-supplied string for identification with
    * this library.
    */
JSECALLSEQ(void) jseTerminateExternalLink(jseContext jsecontext);
   /* Final call. No calls available after this.  Any context valid in
    * this function is valid for this call.
    */
JSECALLSEQ(void _FAR_ *) jseGetLinkData(jseContext jsecontext);
   /* get the arbitrary data element available to your link */
JSECALLSEQ( struct jseExternalLinkParameters * )\
   jseGetExternalLinkParameters(jseContext jsecontext);
  /* Get the current set of User specified parameters */

JSECALLSEQ(jseContext) jseAppExternalLinkRequest(jseContext jsecontext,
                                                 jsebool Initialize);
   /* Get a new jsecontext from the toolkit application, initialized
    * as the toolkit application chooses to initialize apps, with its
    * own calls to jseInitializeExternalLink, initializing libraries, etc...
    * If Initialize is False then this is to terminate a link create with
    * earlier call, and jsecontext is context returned from that earlier call.
    * PreviousLinkContext Application can return NULL if it won't support this
    * Engine will return NULL if AppInitLinkFunc in jseExternalLinkParameters
    * is null for PreviousLinkContext
    */

/*******************************************
 *** DEFINING EXTERNAL LIBRARY FUNCTIONS ***
 *******************************************/

/* define extra var attributes for function definition table */
typedef uword16  jseFuncAttributes;
#  define jseFunc_Default          0x00
      /* want default ECMAScript behaviour */
#  define jseFunc_PassByReference  0x80
      /* want to pass all lvalue variables by reference */
#  define jseFunc_CBehavior        jseFunc_PassByReference
      /* this flag is now deprecated, but it must be kept for backwards
       * compatibility.  Use jseFunc_PassByReference instead
       */
#  define jseFunc_Secure           0x40
      /* this function is safe to call; else is a security risk; this is
       * only used if JSE_SECUREJSE but must always be defined so that
       * external links have the right number of charactrs
       */
#  define jseFunc_ArgvStyle        0x20
      /* This function is a new-style wrapper function */
#  define jseFunc_NoGlobalSwitch   0x10
      /* when JSE_MULTIPLE_GLOBAL is defined this will prevent the
       * global variable from switching when this context is called.
       */


   /* the following values are wrapped into the JSE_FUNC macros - you don't
    * need to use them explicitly; these types tell just what type of entry
    * this is in the object table (note that these cannot be ORed together)
    */
#  define jseFunc_FuncObject       1
      /* this is a function object */
#  define jseFunc_ObjectMethod     2
      /* this is an object of previously-defined function object */
#  define jseFunc_PrototypeMethod  3
      /* method of the .prototype of previously-defined function object */
#  define jseFunc_AssignToVariable 4
      /* specify "string.something.other" to assign to an existing object */
#  define jseFunc_LiteralValue     5
      /* function pointer is really a literal string to assign as property */
#  define jseFunc_LiteralNumberPtr 6
      /* function pointer is really a literal string to assign as property */
#  define jseFunc_SetAttributes    7
      /* only set the attributes on this object */

typedef void (JSE_CFUNC FAR_CALL *jseLibraryFunction)(jseContext jsecontext);

typedef jseVariable (JSE_CFUNC FAR_CALL *jseArgvLibraryFunction)(jseContext jsecontext,
                                                                 uint argc,jseVariable *argv);

struct jseFunctionDescription {
   /* define jse function that can be called by interpreted jse code */
   const jsecharptr FunctionName;  /* list ends when this is NULL */
   jseLibraryFunction FuncPtr;
   sword8 MinVariableCount, MaxVariableCount; /*-1 for no max */
   jseVarAttributes VarAttributes;   /* bitwise-OR jseVarAttributes */
   jseFuncAttributes FuncAttributes;  /* bitwise-OR */
};

/* OLD TEMPORARY MACROS - MAKE THESE GO AWAY */
#define JSE_FUNC_DESC(NAME,ADDR,MINCT,MAXCT,PASS_BY_REF,SAFE) \
   { NAME, ADDR, MINCT, MAXCT, jseDontEnum, \
     ( (PASS_BY_REF) ? jseFunc_PassByReference : 0 ) \
     | ( (SAFE) ? jseFunc_Secure : 0 ) \
     | jseFunc_ObjectMethod }
#define JSE_FUNC_DESC_END  JSE_FUNC(NULL,NULL,0,0,0,0)

#define JSE_FUNC(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, ADDR, MINCT, MAXCT, VARATTR, FUNCATTR }
#define JSE_LIBOBJECT(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, ADDR, MINCT, MAXCT, VARATTR, FUNCATTR | jseFunc_FuncObject }
#define JSE_LIBMETHOD(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, ADDR, MINCT, MAXCT, VARATTR, FUNCATTR | jseFunc_ObjectMethod }
#define JSE_PROTOMETH(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, ADDR, MINCT, MAXCT, VARATTR, FUNCATTR | jseFunc_PrototypeMethod }

   /* New WML-style argc/argv, return variable wrapper format */
#define JSE_ARGVFUNC(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, (jseLibraryFunction)ADDR, MINCT, MAXCT, VARATTR, FUNCATTR | jseFunc_ArgvStyle }
#define JSE_ARGVLIBOBJECT(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, (jseLibraryFunction)ADDR, MINCT, MAXCT, VARATTR, \
     FUNCATTR | jseFunc_FuncObject | jseFunc_ArgvStyle }
#define JSE_ARGVLIBMETHOD(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, (jseLibraryFunction)ADDR, MINCT, MAXCT, VARATTR, \
     FUNCATTR | jseFunc_ObjectMethod | jseFunc_ArgvStyle }
#define JSE_ARGVPROTOMETH(NAME,ADDR,MINCT,MAXCT,VARATTR,FUNCATTR) \
   { NAME, (jseLibraryFunction)ADDR, MINCT, MAXCT, VARATTR, \
     FUNCATTR | jseFunc_PrototypeMethod | jseFunc_ArgvStyle }

#define JSE_VARASSIGN(NAME,CONST_VARNAME,VARATTR) \
   { NAME, (jseLibraryFunction)CONST_VARNAME, 0, 0, VARATTR, \
     jseFunc_AssignToVariable }
#define JSE_VARSTRING(NAME,CONST_VAR_STRING,VARATTR) \
   { NAME, (jseLibraryFunction)CONST_VAR_STRING, 0, 0, VARATTR, \
     jseFunc_LiteralValue }
#define JSE_VARNUMBER(NAME,CONST_VAR_NUMBER,VARATTR) \
   { NAME, (jseLibraryFunction)CONST_VAR_NUMBER, 0, 0, VARATTR, \
     jseFunc_LiteralNumberPtr }
#define JSE_ATTRIBUTE(NAME,VARATTR) \
   { NAME, NULL, 0, 0, VARATTR, jseFunc_SetAttributes }
#define JSE_FUNC_END  JSE_FUNC(NULL,NULL,0,0,0,0)

typedef void _FAR_ * (JSE_CFUNC FAR_CALL *jseLibraryInitFunction)\
   (jseContext jsecontext,void _FAR_ *PreviousInstanceLibraryData);
   /* PreviousInstanceLibraryData was returned by a previous instance of
    * initializing this library (sub-instances may be created with new
    * calls to interpret()), or was the object used in jseAddLibrary if
    * this is the first call.
    */
typedef void (JSE_CFUNC FAR_CALL *jseLibraryTermFunction)(
   jseContext jsecontext,void _FAR_ *InstanceLibraryData);
JSECALLSEQ(void _FAR_ *) jseLibraryData(jseContext jsecontext);
   /* following call to LibraryInitFunction this will always
    * return the value returned by LibraryInitFunction.
    */
#if defined(__JSE_GEOS__)
	typedef void _FAR_ * (JSE_CFUNC FAR_CALL pcfm_jseLibraryInitFunction)\
	   (jseContext jsecontext,void _FAR_ *PreviousInstanceLibraryData, void *pf);
	typedef void (JSE_CFUNC FAR_CALL pcfm_jseLibraryTermFunction)(
	   jseContext jsecontext,void _FAR_ *InstanceLibraryData, void *pf);
#endif

JSECALLSEQ(jsebool) jseAddLibrary(jseContext jsecontext,
   const jsecharptr object_var_name/*NULL for global object*/,
   const struct jseFunctionDescription *FunctionList,
   void _FAR_ *InitLibData,
   jseLibraryInitFunction LibInit,jseLibraryTermFunction LibTerm);
   /* if LibInit or LibTerm are NULL then not called.
    * Boolean indicates success. Currently can only fail if
    * we run out of memory.
    */



/**********************************************************
 *** WORKING WITH OTHER INTERNAL AND EXTERNAL FUNCTIONS ***
 **********************************************************/

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseGetFunction(jseContext jsecontext,
      jseVariable object,const jsecharptr functionName,
      jsebool errorIfNotFound);
      /* Return NULL if not found; If ErrorIfNotFound then also
       * call Oops() to print error;
       */
#endif

#define JSE_FUNC_DEFAULT      0x00
#define JSE_FUNC_TRAP_ERRORS  0x01
   /* Exactly analogous to JSE_INTERPRET_TRAP_ERRORS. */
#define JSE_FUNC_CONSTRUCT    0x02
   /* See jseCallFunctionEx() below for details */


JSECALLSEQ(jsebool) jseIsFunction(jseContext jsecontext,
                                  jseVariable functionVariable);
   /* Return False if this variable is not a valid callable function object. */
#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jsebool) jseCallFunctionEx(jseContext jsecontext,
                                         jseVariable jsefunc,jseStack jsestack,
                                         jseVariable *returnVar,jseVariable thisVar,
                                         uint flags);
      /* The given 'jsefunc' is a jseTypeObject jseVariable that must be a
       * function. For all possible errors, if JSE_FUNC_TRAP_ERRORS is set,
       * an appropriate Exception object will be returned. If it isn't defined,
       * then 'returnVar' will be NULL and an error message will have been
       * printed (using the normal Error printing scheme.) The jseStack contains
       * the parameters to be passed to the given function. The 'thisVar' is
       * a jseVariable to be given to the function as the 'this' variable.
       * If it is NULL, the global object will be passed. If just calling a
       * function, use NULL. When trying to call a particular Object's member
       * function (for instance, the 'toString' method of an object), you'll
       * want to pass that Object as the 'thisVar'
       *
       * Note that even with JSE_FUNC_TRAP_ERRORS, the return can be NULL
       * if you called the function illegally (such as 'jsefunc' not being
       * a function.) Use jseGetLastApiError() to find the problem.
       *
       * The JSE_FUNC_CONSTRUCT flag will allow you to call a constructor.
       * The given 'jsefunc' must actually have a constructor associated with
       * it, else an error will be generated. In this case, the 'thisVar'
       * is ignored, since a call to a constructor generates a new Object
       * for that constructor to fill in.
       *
       * When calling an Object's member function, use jseGetMember() to get
       * the jseVariable associated with the function you'd like to call.
       * When trying to call a generic function or constructor, it is usually
       * easiest to use jseFindVariable() to look up a function you'd like to
       * call.
       *
       * As a convenience, the 'jsestack' can be NULL if there are no
       * parameters to be passed to the function.
       */
#define jseCallFunction(j,f,s,r,t) jseCallFunctionEx((j),(f),(s),(r),(t),JSE_FUNC_DEFAULT)

#endif
JSECALLSEQ(jseContext) jseCurrentContext(jseContext ancestorContext);
   /* not NULL */
   /* Return the current context for the the current thread of execution. If
    * you're being called by the jse interpreter then this will be the same
    * value passed to your function in the context parameter and this call is
    * not needed (and should be avoided because of its extra overhead) but if
    * you're in a callback function then you can use this.  If you know the
    * ancestor jsecontext, such as from InitializejseLink, then this will
    * return the context currently in use (descendat of AncestorContext).
    * This is intended only for use by callback or interrupt-like functions.
    */
#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseCreateWrapperFunction(jseContext jsecontext,
      const jsecharptr functionName,
      jseLibraryFunction funcPtr,
      sword8 minVariableCount, sword8 maxVariableCount, /* -1 for no max */
      jseVarAttributes varAttributes,   /* bitwise-OR jseVarAttributes */
      jseFuncAttributes funcAttributes,  /* bitwise-OR */
      void _FAR_ *fData);
         /* fData is available to the function through jseLibraryData() */

   JSECALLSEQ(jseVariable) jseMemberWrapperFunction(jseContext jsecontext,
      jseVariable objectVar,
         /* object to add function to (as a member), NULL for global object */
      const jsecharptr functionName,
      jseLibraryFunction funcPtr,
      sword8 minVariableCount, sword8 maxVariableCount, /* -1 for no max */
      jseVarAttributes varAttributes,   /* bitwise-OR jseVarAttributes */
      jseFuncAttributes funcAttributes,  /* bitwise-OR */
      void _FAR_ *fData);   /* available to function through jseLibraryData() */
#endif

JSECALLSEQ(jsebool) jseIsLibraryFunction(jseContext jsecontext,
                                         jseVariable functionVariable);


/* See jseCallStackInfo below */
struct jseStackInfo
{
   jsebool wrapper;             /* is this a wrapper function? */
   jseVariable function;        /* currently executing function */
   const jsecharptr funcname;   /* current function's name */


   jsebool trapped;             /* would an error be trapped by try/catch
                                 * if it occured here.
                                 */

   jseVariable global;          /* global variable in effect */
   jseVariable thisvar;         /* the this variable in effect */


   /* The following are only applicable to wrapper functions */

   void _FAR_ *linkdata;        /* The data associated with the wrapper
                                 * function.
                                 */


   /* The following are only applicable to script functions, i.e.
    * if 'wrapper' is False.
    */

   const jsecharptr filename;   /* filename of the script */
   uint linenumber;             /* linenumber of the script */

   jseVariable varObj;          /* an object, the named variables, params and
                                 * locals of the script function.
                                 * The easiest way to get arguments is
                                 * to get the member "arguments" of this
                                 * object, and then in it, you can get
                                 * IndexMember 0, 1, etc up to the numeric
                                 * value in the member "length".
                                 */
   jseVariable scopeChain;      /* The scope chain that would be
                                 * searched for variables. You can
                                 * perform such a search by using
                                 * jseGetNextMember repeatedly on it.
                                 * Each returned variable will be an
                                 * object on the scope chain. If the
                                 * object has a given named member,
                                 * that would be used for the value
                                 * of the variable in the script.
                                 * The objects will be returned in the
                                 * same order a scope chain would have
                                 * been searched.
                                 */
};
/* You pass a pointer a jseStackInfo structure, the structure
 * is filled in. A boolean is returned to indicate if the
 * required info was found.
 *
 * Depth indicates how far to look back. 0 means get the info
 * for the current function (probably the wrapper function you
 * are in), 1 means the calling function, 2 means the caller of
 * that, etc.
 *
 * This function is somewhat slow as it collects a lot of data.
 * Use it in non-time critical situations, like a debugger
 * which is interacting with the user.
 *
 * see jseFreeStackInfo below
 */
   JSECALLSEQ( jsebool )
jseCallStackInfo(jseContext call,struct jseStackInfo *info,uint depth);

/* You must free the stack info structure using this call */
   JSECALLSEQ( void )
jseFreeStackInfo(jseContext call,struct jseStackInfo *info);


/************************************************
 *** #DEFINE STATEMENTS DURING INITIALIZATION ***
 ************************************************/


#if defined(JSE_DEFINE) && (0!=JSE_DEFINE)
   JSECALLSEQ(void) jsePreDefineLong(jseContext jsecontext,
                                     const jsecharptr FindString,
                                     slong ReplaceL);

   /* Should be available in NO_FLOATING_POINT builds -
    * 'jsenumber' is just not a floating point number.
    */
   JSECALLSEQ(void) jsePreDefineNumber(jseContext jsecontext,
                                       const jsecharptr findString,
                                       jsenumber replaceF);

   JSECALLSEQ(void) jsePreDefineString(jseContext jsecontext,
                                       const jsecharptr FindString,
                                       const jsecharptr ReplaceString);
#endif

/***************************
 ******** Interpret ********
 ***************************/

typedef int jseInterpretMethod;
#define JSE_INTERPRET_DEFAULT          0x00
   /* none of the following flags set; default behavior */
#define JSE_INTERPRET_NO_INHERIT       0x01
/* set the interpret up so local variables and with() scopes don't
 * apply. In se430, the LocalVariableContext is ignored.
 */
#define JSE_INTERPRET_CALL_MAIN        0x02
   /* call main(argc,argv) after running initialization code */
#define JSE_INTERPRET_LOAD             0x04
  /* this flag is deprecated. If it is on, it turns off
   * JSE_INTERPRET_NO_INHERIT and jseNewGlobalObject
   */
#define JSE_INTERPRET_KEEPTHIS         0x08
   /* the current "this" variable becomes the this for new global interpret */
#define JSE_INTERPRET_TRAP_ERRORS      0x10
   /* The interpret functions can still fail, but will always return something
    * (an Error object in the case of errors). No error messages will be
    * printed.
    */

/* The Continue function is normally called after every statement.
 * This is because a debugger, which is implemented using it, needs
 * to regain control after every statement. However, at other times,
 * this is far too often to call it. If, for instance, your continue
 * function just checks ^C or something similar, it needs only be
 * called 'occassionally'. Pass the following flag to a particular
 * call to jseInterpret() to have the continue function called
 * infrequently. If you are using jseInterpInit/Exec/Term, each
 * Exec call will process more than one statement (jseInterpret()
 * just calls these other calls internally). The define after that
 * is how many statements to wait between calls. If you change that,
 * you'll need to rebuild the core. A typical 500Mhz PIII can
 * expect to process between 100,000-1,000,000 statements per
 * second.
 */
#define JSE_INTERPRET_INFREQUENT_CONT  0x20
#if !defined(JSE_INFREQUENT_COUNT)
#  define JSE_INFREQUENT_COUNT 5000
#endif


/* Case 1: completely New,            JSE_INTERPRET_NO_INHERIT and jseAllNew
 * Case 2: new globals, but see old   JSE_INTERPRET_DEFAULT    and jseNewGlobalObject
 * Case 3: execute in same context    JSE_INTERPRET_DEFAULT    and jseNewNone
 *
 * Note, the LocalVariableContext is now ignored, it is deprecated.
 */

typedef int jseNewContextSettings;
#  define jseNewNone           0x00

#  define jseNewDefines        0x01
#  define jseNewGlobalObject   0x02
      /* a compatibility flag name, same as jseNewGlobalObject */
#  define jseNewFunctions      0x02
#  define jseNewLibrary        0x08
#  define jseNewAtExit         0x10
#  define jseNewSecurity       0x20
#  define jseNewExtensionLib   0x40

#  define jseAllNew            0x7B

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jsebool) jseInterpret(jseContext jsecontext,
      const jsecharptr SourceFile,
         /* NULL if pure text; token buffer if JSE_INTERPRET_PRETOKENIZED */
      const jsecharptr SourceText,
         /* text or options if SourceFile */
      const void * PreTokenizedSource,
         /*NULL or data is already precompiled as in jseCreateCodeTokenBuffer */
      jseNewContextSettings NewContextSettings,
      jseInterpretMethod howToInterpret,
         /* flags, may be JSE_INTERPRET_xxxx */
      jseContext unused_parameter, /* saved for future use */
      jseVariable *returnVar);
#endif

/* ----------------------------------------------------------------------
 * Interpreting in pieces:
 *
 * Once you have set up for an interpret session using jseInterpInit(),
 * you actually execute the ScriptEase statements using successive calls
 * to jseInterpExec(). Initially, you pass the context you received as a
 * result of jseInterpInit(). You will be returned a new context that you
 * pass back to execute the next statement. Continue calling this function
 * with the result of the last call as the parameter. When this function
 * returns NULL, the interpret is complete. At this time, you call the
 * jseInterpTerm() function to clean everything up and get the return
 * value.
 *
 * If you call jseInterpret(), your 'MayIContinue' function is called
 * after each statement. If you use the jseInterpXXX() functions directly,
 * your 'MayIContinue' statement is NOT called. Instead, you may execute
 * whatever code you like between successive calls to this function.
 * You may decide to discontinue executing code by calling jseInterpTerm()
 * at any time. If you do so, no return value can be given (the function
 * always returns NULL.)
 *
 * Certain functions, due to the design of the interpreter, must be completely
 * processed and so are atomic to this function. This means that if you
 * do a jseCallFunction() or access a dynamic object, the statement will
 * not be executed iteratively by your jseInterpExec() but will be handled
 * behind the scenes all at once. Thus, when you call jseInterpExec() in these
 * cases, many statements can be processed for your one call. In this case,
 * your MayIContinue() function WILL be called during these statements.
 * Thus, you should always have a valid MayIContinue() function.
 *
 *
 * jseInterpInit returns a new jsecontext. If it returns NULL, some error
 * happened (like a syntax error during parsing.) The error message will
 * have already been printed. You can trap this error by using the
 * JSE_INTERPRET_TRAP_ERROR flag in the howToInterpret settings. The returnVar
 * parameter is provided for this case. It will be filled in with the trapped
 * error object. It is only used in this case, you can ignore it if you
 * are not trapping errors. If you do trap an error (i.e. it is not NULL,
 * it must be destroyed when you are done.)
 *
 * You can trap any errors in the call to jseInterpTerm(), there being a
 * boolean flag to do so. If you don't, error messages will be printed and
 * a NULL will be returned on error. Otherwise, again, no message is printed
 * and instead the error object is returned. You can use jseQuitFlagged()
 * before calling jseInterpTerm() to determine if the result will be an
 * error. If you are cancelling the interpret as described above, this does not
 * apply.
 */

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ( jseContext )
jseInterpInit(jseContext jsecontext,
              const jsecharptr SourceFile,
              const jsecharptr SourceText,
              const void * PreTokenizedSource,
              jseNewContextSettings NewContextSettings,
              jseInterpretMethod howToInterpret,
              jseContext unused_parameter, /* saved for future use */
              jseVariable *returnVar);
#endif

#if defined(NDEBUG) || JSE_TRACKVARS==0
      JSECALLSEQ( jseVariable )
   jseInterpTerm(jseContext jsecontext,jsebool traperrors);
#endif

   JSECALLSEQ( jseContext )
jseInterpExec(jseContext jsecontext);

/********************************
 ******** Tokenized Code ********
 ********************************/

   typedef void *  jseTokenRetBuffer;
#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   JSECALLSEQ( jseTokenRetBuffer) jseCreateCodeTokenBuffer(
      jseContext jsecontext,
      const jsecharptr source,
      jsebool sourceIsFileName/*else is source string*/,
      uint *bufferLen);
       /* returns buffer or NULL if error; buffer must be freed by the
        * caller. if return non-NULL then *BufferLen is set to length
        * of data in the buffer
        */

   JSECALLSEQ( void )  jseDestroyCodeTokenBuffer(jseContext jsecontext,
                                                 jseTokenRetBuffer buffer);
#endif

/*********************
 *** MISCELLANEOUS ***
 *********************/

/* These are the possible actions for jseGarbageCollect(). They are not
 * flags, pick one. The vast majority of programs will not need to
 * garbage collect. Forcing collection is useful because it will also
 * cause any objects with destructors if they are free to have their
 * destructor called. Note that turning off collecting will slow down
 * the interpreter in addition to using lots more memory.
 */
#define JSE_GARBAGE_COLLECT       0x01
   /* perform collection now, even if collection shut off. */
#define JSE_GARBAGE_OFF           0x02
#define JSE_GARBAGE_ON            0x03
   /* These increment or decrement a 'no collection' flag. As long as
    * the flag is >0, garbage collection will not happen. If memory runs
    * out, instead of collecting to reclaim memory, more memory will
    * be allocated from the system.
    */
#ifndef NDEBUG
#  define JSE_COLLECT_AND_ANALYZE   0x04
   /* will do a garbage collection, and while collecting will write through
    * the DebugPrintf() lots and lots of information about what is
    * happening in the system.
    */
#endif
JSECALLSEQ(void) jseGarbageCollect(jseContext jsecontext,uint action);


JSE_POINTER_UINDEX  jseGetNameLength(jseContext jsecontext,
                                     const jsecharptr name );
const jsecharptr jseSetNameLength(jseContext jsecontext, const jsecharptr name,
                                 JSE_POINTER_UINDEX length);

typedef void (JSE_CFUNC FAR_CALL * jseAtExitFunc)(jseContext jsecontext,
                                                  void _FAR_ *Param);
#if defined(__JSE_GEOS__)
	typedef void (JSE_CFUNC FAR_CALL pcfm_jseAtExitFunc)(jseContext jsecontext,
                                                  void _FAR_ *Param, void *fp);
#endif
	
JSECALLSEQ(jsebool) jseCallAtExit(jseContext jsecontext,
                               jseAtExitFunc exitFunction,void _FAR_ *Param);
   /* call this function at exit time with the Param parameter */

JSECALLSEQ(void) jseLibSetErrorFlag(jseContext jsecontext);
   /* set flag that there has been an error */
JSECALLSEQ_CFUNC(void) jseLibErrorPrintf(jseContext exitContext,
                                         const jsecharptr formatS,...);
   /* print error; set error flag in context */

JSECALLSEQ(void) jseLibSetExitFlag(jseContext jsecontext,
                                   jseVariable ExitVariable);
   /* Sets exit flag for this jsecontext, and saves copy of exit variable
    * (or ExitVariable may be NULL for return EXIT_SUCCESS) */

JSECALLSEQ(uint) jseQuitFlagged(jseContext jsecontext);
   /* return 0 if a call has been made on this context to Exit or for
    * one of the above error functions.  Return one of the following
    * non-0 (non-False) defines if should exit.
    */
#  define JSE_CONTEXT_ERROR  1
#  define JSE_CONTEXT_EXIT   2

JSECALLSEQ( const jsecharptr ) jseLocateSource(jseContext jsecontext,
                                              uint *lineNumber);
   /* Return pointer to the name of the source file for the code currently
    * executing, and set LineNumber to the current line number executing
    * or being parsed.
    * Do not alter the returned string.  If no current file, such as when
    * interpreting string (e.g. not INTERPRET_JSE_FILE), then return NULL.
    */
JSECALLSEQ( const jsecharptr ) jseCurrentFunctionName(jseContext jsecontext);
   /* return pointer to name of the current function; don't write into this
    * memory; NULL if no current function name
    */

     /* Shared Data functions */
#if defined(JSETOOLKIT_LINK) && defined(__JSE_WIN16__)
   typedef void (JSE_CFUNC FAR_CALL _export *jseShareCleanupFunc)(void _FAR_ *data);
#else
   typedef void (JSE_CFUNC FAR_CALL *jseShareCleanupFunc)(void _FAR_ *data);
#endif

#  if defined(__JSE_GEOS__)
   typedef void (JSE_CFUNC FAR_CALL pcfm_jseShareCleanupFunc)\
      (void _FAR_ *data, void *pf);
#  endif

JSECALLSEQ(void _FAR_ *) jseGetSharedData(jseContext jsecontext,
                                          const jsecharptr name);
JSECALLSEQ(void) jseSetSharedData(jseContext jsecontext, const jsecharptr name,
                      void _FAR_ * data,jseShareCleanupFunc cleanupFunc);

#if defined(NDEBUG) || JSE_TRACKVARS==0
   JSECALLSEQ(jseVariable) jseCurrentFunctionVariable(jseContext jsecontext);
      /* Return variable associated with current function, or NULL if there is
       * none
       */
#endif

/* Enabling or disabling a dynamic function is a tricky process, and should
 * only be handled with extreme caution.  By default, during the call of a
 * dynamic method (_get() for example) that dynamic method is turned off so
 * that within the implemented _get any call that really gets the varaible
 * will not go through the _get routine.  Without this turning off of a dynamic
 * function it would be very common to get into an infinitely recursive
 * situation.  Because of the inherent trickiness of this function it is
 * turned off by default.  To enable it set the define to 1.  Note that after
 * re-enabling a particular method (_get, for instance) that method will
 * again be temporarily disable if the method is called again.
 */
#if !defined(JSE_ENABLE_DYNAMETH)
#  define JSE_ENABLE_DYNAMETH 0  /* off by default */
#endif
#if (0!=JSE_ENABLE_DYNAMETH)
#  if (0==JSE_DYNAMIC_OBJS)
#     error Cannot have JSE_ENABLE_DYNAMETH if not JSE_DYNAMIC_OBJS
#  endif
   JSECALLSEQ(jsebool) jseEnableDynamicMethod(jseContext jsecontext,jseVariable obj,
                                              const jsecharptr methodName,jsebool enable);
      /* Enable (if enable is true) the calling of the dynamic method named methodName,
       * else disable calling of that dynamic method.  Will return previous state of that
       * method (True if was previously enabled and False if it was not.
       */
#endif


      /* This is a lengthy new addition to the API. So let's look at
       * it in parts. First, we have a new jseString type. ScriptEase
       * takes all strings internally and turns them into a pointer,
       * which it can compare quickly (i.e. it maps different strings
       * with the same value to pointers.) You can call jseInternalizeString()
       * on one of your strings to do the same. These can be compared
       * with a '==' instead of a 'strcmp' which is MUCH faster.
       *
       * You can use a jseString in the routines that take property names.
       * The documentation of those routines has been updated to
       * indicate which ones you can pass it to. Realize, those routines
       * still take normal strings as well, they recognize either one
       * and can figure out which kind you have passed to them.
       */
typedef void *jseString;

#if defined(JSE_DYNAMIC_OBJS)

      /* These object callbacks do the same thing as the current dynamic
       * functions, but they call directly into your code rather than
       * going through the more generic function mechanism, which
       * makes them much faster. Please note that they give no added
       * functionality, their purpose is speed. As a result, these
       * routines get passed jseStrings instead of full text strings.
       * You can pass these jseStrings along to our API routines that
       * are looking for a member name by casting them to (jsecharptr).
       * The engine can differentiate these from a real string in
       * those cases.
       *
       * Please note that if an object has both a callback for a
       * particular dynamic function and a old-style dynamic function
       * for the same operation, the callback takes precedence. It is
       * called and the regular one is ignored. If you return
       * the 'do the regular thing value', then it is used if it
       * exists, else the 'real' regular thing is done.
       *
       * If you wish to associate data with this object, note that
       * the object that you set the callbacks on is passed back
       * to you as the 'this' variable, you can use jseGet/SetObjectData()
       * on it to store and retrieve such data.
       */
struct jseObjectCallbacks
{
   /* The returned variable from get must be a locked object that
    * is to be unliked, i.e. treat it exactly like a RetTempVar
    * You can return NULL for the Undefined value.  callHint is set
    * true if it looks like this property is going to be used
    * as a function.  E.G. for obj.foo(...) hint will be true
    */
   jseVariable (JSE_CFUNC FAR_CALL *get)(jseContext jsecontext,jseVariable obj,jseString prop,
                                         jsebool callHint);


   /* Return False to indicate you did not process the put, and
    * do the regular thing.
    */
   jsebool (JSE_CFUNC FAR_CALL *put)(jseContext jsecontext,jseVariable obj,jseString prop,
                                     jseVariable to_put);


   /* boolean indicating can put or not.
    */
   jsebool (JSE_CFUNC FAR_CALL *canPut)(jseContext jsecontext,jseVariable obj,jseString prop);

   /* Return 1 or 3 values, 1/0 = has/does not have the property and
    * -1 means 'do the regular thing'.
    */
   int (JSE_CFUNC FAR_CALL *hasProp)(jseContext jsecontext,jseVariable obj,jseString prop);


   /* Like a put above, return False if we have not handled the
    * delete and want to do the regular thing. For a destructor
    * (i.e. prop is "_delete"), there is no regular thing, your
    * return is ignored.
    */
   jsebool (JSE_CFUNC FAR_CALL *deleteFunc)(jseContext jsecontext,jseVariable obj,
                                            jseString prop);


   /* When the object is trying to be converted to a primitive. It is
    * possible to not get a hint (i.e. it is NULL).
    */
   jseVariable (JSE_CFUNC FAR_CALL *defaultValue)(jseContext jsecontext,jseVariable obj,
                                                  jseVariable hint);

#  if defined(JSE_OPERATOR_OVERLOADING) && (0!=JSE_OPERATOR_OVERLOADING)
   /* The operator is passed two arguments. The first, op, is a string
    * of the operation being performed. If you use jseGetInternalString(),
    * you will get back the operator, such as "=" or "*". You can use
    * jseInternalizeString() before hand to get the values for these
    * operators for easy comparisons in your function.
    *
    * The second property can be NULL because some operators do not
    * have an operand. For instance, the crement operators such as ++
    * do not have an operand. In the case of '+' and '-', if you get
    * an operand, this is an addition or subtraction. If you do not,
    * this is a binary +/-. I.e. the first case is 'obj + 4' and the
    * second is '+obj'
    */
   jseVariable (JSE_CFUNC FAR_CALL *operatorFunc)(jseContext jsecontext,jseVariable obj,
                                                  jseString op,jseVariable operand);
#  endif
};

/* This routine associates a structure with the callbacks in it
 * with the given object. Please note that your pointer is saved,
 * the structure must remain valid through the life of the program.
 */
   JSECALLSEQ(void)
jseSetObjectCallbacks(jseContext jsecontext,jseVariable obj,
                      struct jseObjectCallbacks *cbs);
   JSECALLSEQ(struct jseObjectCallbacks *)
jseGetObjectCallbacks(jseContext jsecontext,jseVariable obj);

#endif

/* Get an internal representation of the original string, suitable
 * for passing to API functions that require a member name. You
 * must free that using 'jseFreeString' when finished with it
 */
   JSECALLSEQ(jseString)
jseInternalizeString(jseContext call,const jsecharptr str,
                     JSE_POINTER_UINDEX len);

   JSECALLSEQ(const jsecharptr)
jseGetInternalString(jseContext call,jseString str,
                     JSE_POINTER_UINDEX *len);
   JSECALLSEQ(void)
jseFreeInternalString(jseContext call,jseString str);

#if !defined(JSE_GETFILENAMELIST)
#  if defined(__JSE_DOS16__) || defined(__JSE_WINCE__)
#     define JSE_GETFILENAMELIST  0
#  else
#     define JSE_GETFILENAMELIST  1
#  endif
#endif
#if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
   JSECALLSEQ(jsecharptr *) jseGetFileNameList(jseContext jsecontext,
                                                int *number);
     /* Get a list of the files currently opened by the interpreter */
#endif

#if !defined(JSE_BREAKPOINT_TEST)
#  if defined(__JSE_DOS16__) || defined(__JSE_WINCE__)
#     define JSE_BREAKPOINT_TEST  0
#  else
#     define JSE_BREAKPOINT_TEST  1
#  endif
#endif
#if defined(JSE_BREAKPOINT_TEST) && (0!=JSE_BREAKPOINT_TEST)
JSECALLSEQ(jsebool) jseBreakpointTest(jseContext jsecontext,
                                      const jsecharptr FileName,
                                      uint LineNumber);
  /* To help debugger. Test if this is valid place to break. Check if
   * currently-running script thinks it has a breakpoint in this file
   * at this line number.  True if breakpoint, else False.
   */
#endif

#if ( 0 < JSE_API_ASSERTLEVEL )
   JSECALLSEQ( const jsecharptr ) jseGetLastApiError(void);
   JSECALLSEQ( void ) jseClearApiError(void);
#  define jseApiOK  ( 0 == JSECHARPTR_GETC(jseGetLastApiError()) )
   /* These API calls are for diagnostic purposes.  They need never take
    * a context - that would defeat the purpose that you can get at an
    * error to see that your context is invalid, Null etc.  The calls do
    * not protect the error buffer from being written to by multiple threads.
    * The jseApiOK macro is here for convenient placement in assert statements
    * such as:  assert( jseApiOK )
    */
#else
#  define jseApiOK True
   /* Because warnings are off this will pretend that there were no API
    * errors, and so allow "assert(jseApiOK)" to be in code that may
    * or may not check for errors.  Be warned that this does not mean
    * there were no errors, and so do not get a false sense of security
    * from this definition when warning levels are 0.
    */
#endif

#if defined(JSETOOLKIT_LINK)
#  if defined(__JSE_WIN16__)
#      define jseLibFunc(FuncName)    \
     void _FAR_ _cdecl _export FuncName(jseContext jsecontext)
#      define jseArgvLibFunc(FuncName) \
     jseVariable _FAR_ _cdecl _export FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#  elif defined(__JSE_GEOS__)
#      define jseLibFunc(FuncName)    \
     void _FAR_ _pascal _export FuncName(jseContext jsecontext)
#      define jseArgvLibFunc(FuncName) \
     jseVariable _FAR_ _pascal _export FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#  elif defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#     if !defined(_MSC_VER)
#        define jseLibFunc(FuncName)  \
     void _cdecl _export FuncName(jseContext jsecontext)
#        define jseArgvLibFunc(FuncName)  \
     jseVariable _cdecl _export FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#     else
#        define jseLibFunc(FuncName)   \
     _declspec(dllexport) void _cdecl FuncName(jseContext jsecontext)
#        define jseArgvLibFunc(FuncName)   \
     _declspec(dllexport) jseVariable _cdecl FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#     endif
#  elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#     if defined(__IBMCPP__)
#        define jseLibFunc(FuncName)  \
     void _Export FuncName(jseContext jsecontext)
#        define jseArgvLibFunc(FuncName)  \
     jseVariable _Export FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#     else
#        define jseLibFunc(FuncName)   \
     void _export _cdecl FuncName(jseContext jsecontext)
#        define jseArgvLibFunc(FuncName)   \
     jseVariable _export _cdecl FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#     endif
#  elif defined(__JSE_UNIX__)
#     define jseLibFunc(FuncName)    \
    void FuncName(jseContext jsecontext)
#     define jseArgvLibFunc(FuncName)    \
    jseVariable FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#  elif defined(__JSE_NWNLM__)
#     define jseLibFunc(FuncName)    \
    void JSE_CFUNC _FAR_ FuncName(jseContext jsecontext)
#     define jseArgvLibFunc(FuncName)    \
    jseVariable JSE_CFUNC _FAR_ FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#  elif defined(__JSE_MAC__)
#     define jseLibFunc(FuncName)    \
    void FuncName(jseContext jsecontext)
#     define jseArgvLibFunc(FuncName)    \
    jseVariable FuncName(jseContext jsecontext,uint argc,jseVariable *argv)
#  else
#    error define the extension qualifiers
#  endif
#else
#  if defined(__JSE_GEOS__)
#     define jseLibFunc(FuncName) \
     void JSE_CFUNC FAR_CALL _export FuncName (jseContext jsecontext)
#      define jseArgvLibFunc(FuncName) \
     jseVariable JSE_CFUNC FAR_CALL _export FuncName (jseContext jsecontext,uint argc,jseVariable *argv)
#  else
#      define jseLibFunc(FuncName) \
     void JSE_CFUNC FAR_CALL FuncName (jseContext jsecontext)
#      define jseArgvLibFunc(FuncName) \
     jseVariable JSE_CFUNC FAR_CALL FuncName (jseContext jsecontext,uint argc,jseVariable *argv)
#  endif
#endif

/* These are kept for backwards compatibility, but they mean the same thing */
#define jseExtensionLibFunc     jseLibFunc
#define InternalLibFunc         jseLibFunc


#if defined(JSETOOLKIT_LINK) && defined(__JSE_WIN16__)
#  define jseLibInitFunc(FuncName) \
      void _FAR_ * JSE_CFUNC _export FAR_CALL FuncName \
             (jseContext jsecontext, void _FAR_ *PreviousInstanceData)
#  define jseLibTermFunc(FuncName) \
      void JSE_CFUNC _export FAR_CALL FuncName  \
             (jseContext jsecontext, void _FAR_ *InstanceLibraryData)
#else
#  define jseLibInitFunc(FuncName) \
      void _FAR_ * JSE_CFUNC FAR_CALL FuncName \
             (jseContext jsecontext, void _FAR_ *PreviousInstanceData)
#  define jseLibTermFunc(FuncName) \
      void JSE_CFUNC FAR_CALL FuncName \
             (jseContext jsecontext, void _FAR_ *InstanceLibraryData)
#endif


#ifndef UNUSED_PARAMETER
#  if defined(__BORLANDC__)
#     define UNUSED_PARAMETER(PARAMETER)     /* ignore */
#  else
#     define UNUSED_PARAMETER(PARAMETER)       PARAMETER = PARAMETER
#  endif
#endif
#ifndef UNUSED_INITIALIZER
#  if defined(__JSE_IOS__)
#     define UNUSED_INITIALIZER(INITIAL_VALUE)  =INITIAL_VALUE
#  else
#     define UNUSED_INITIALIZER(INITIAL_VALUE)  /* unused */
#  endif
#endif

#if defined(_BORLAND52_)
   #pragma warn -par
#endif

#if !defined(NDEBUG) && JSE_TRACKVARS==1

      JSECALLSEQ( jsebool )
   jseReallyCallStackInfo(jseContext call,struct jseStackInfo *info,uint depth,
                          char *FILE,int LINE);
#  define jseCallStackInfo(c,i,d) jseReallyCallStackInfo((c),(i),(d),__FILE__,__LINE__)

   JSECALLSEQ( jseVariable ) jseReallyInterpTerm(jseContext jsecontext,jsebool trap,
                                                 char *FILE,int LINE);
#  define jseInterpTerm(c,t) jseReallyInterpTerm((c),(t),__FILE__,__LINE__)
   JSECALLSEQ( jsebool ) jseReallyInterpret(jseContext jsecontext,
                   const jsecharptr SourceFile,
                   const jsecharptr SourceText,
                   const void * PreTokenizedSource,
                   jseNewContextSettings NewContextSettings,
                   int howToInterpret,
                   jseVariable *retvar,
                   char *FILE,
                   int LINE);
   JSECALLSEQ( jseContext ) jseReallyInterpInit(jseContext jsecontext,
                    const jsecharptr SourceFile,
                    const jsecharptr SourceText,
                    const void * PreTokenizedSource,
                    jseNewContextSettings NewContextSettings,
                    int howToInterpret,
                    jseVariable *retvar,
                    char *FILE,
                    int LINE);
#  define jseInterpret(c,sf,st,pts,ncs,hti,unused_parm,rv) \
              jseReallyInterpret((c),(sf),(st),(pts),(ncs),(hti),(rv),__FILE__,__LINE__)
#  define jseInterpInit(c,sf,st,pts,ncs,hti,unused_parm,rv) \
              jseReallyInterpInit((c),(sf),(st),(pts),(ncs),(hti),(rv),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyFuncVar(jseContext jsecontext,uint ParameterOffset,char *FILE,int LINE);
#  define jseFuncVar(c,p) jseReallyFuncVar((c),(p),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyFuncVarNeed(jseContext jsecontext,uint parameterOffset,jseVarNeeded need,
                     char *FILE,int LINE);
#  define jseFuncVarNeed(c,p,n) jseReallyFuncVarNeed((c),(p),(n),__FILE__,__LINE__)
   JSECALLSEQ(jseVariable) jseReallyFindVariable(jseContext jsecontext, const jsecharptr name, ulong flags,
                      char *FILE,int LINE);
#  define jseFindVariable(c,n,f) jseReallyFindVariable((c),(n),(f),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyCreateVariable(jseContext jsecontext,jseDataType VDataType,char *FILE,int LINE);
#  define jseCreateVariable(c,d) jseReallyCreateVariable((c),(d),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyCreateSiblingVariable(jseContext jsecontext,jseVariable olderSiblingVar,
                               JSE_POINTER_SINDEX elementOffsetFromOlderSibling,
                               char *FILE,int LINE);
#  define jseCreateSiblingVariable(c,o,e) jseReallyCreateSiblingVariable((c),(o),(e),__FILE__,__LINE__)
   JSECALLSEQ(jseVariable) jseReallyCreateConvertedVariable(jseContext jsecontext,jseVariable variableToConvert,
                                 jseConversionTarget targetType,char *FILE,int LINE);
#  define jseCreateConvertedVariable(c,v,t) jseReallyCreateConvertedVariable((c),(v),(t),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyCreateLongVariable(jseContext jsecontext,slong value,char *FILE,int LINE);
#  define jseCreateLongVariable(c,s) jseReallyCreateLongVariable((c),(s),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyMemberInternal(jseContext jsecontext,jseVariable objectVar,
                  const jsecharptr Name,
                  jseDataType DType,uword16 flags,char *FILE,int LINE);
#  define jseMemberInternal(c,o,n,t,f) jseReallyMemberInternal((c),(o),(n),(t),(f),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyIndexMemberEx(jseContext jsecontext,jseVariable objectVar,
                       JSE_POINTER_SINDEX index,jseDataType dType,uword16 flags,
                       char *FILE,int LINE);
#  define jseIndexMemberEx(c,o,i,t,f) jseReallyIndexMemberEx((c),(o),(i),(t),(f),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyGetNextMember(jseContext jsecontext,jseVariable objectVariable,
                       jseVariable prevMemberVariable,
                       const jsecharptr * name,char *FILE,int LINE);
#  define jseGetNextMember(c,o,p,n) jseReallyGetNextMember((c),(o),(p),(n),__FILE__,__LINE__)
   JSECALLSEQ( jsebool ) jseReallyCallFunctionEx(jseContext jsecontext,jseVariable jsefunc,jseStack jsestack,
                      jseVariable *retvar,jseVariable thisVar,uint flags,
                      char *FILE,int LINE);
#  define jseCallFunctionEx(c,f,s,r,t,fl) jseReallyCallFunctionEx((c),(f),(s),(r),(t),(fl),__FILE__,__LINE__)
#  define jseCallFunction(c,f,s,r,t) jseReallyCallFunctionEx((c),(f),(s),(r),(t),JSE_FUNC_DEFAULT,__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyActivationObject(jseContext jsecontext,char *FILE,int LINE);
#  define jseActivationObject(c) jseReallyActivationObject((c),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyGetFunction(jseContext jsecontext,jseVariable object,
                     const jsecharptr functionName,jsebool errorIfNotFound,
                     char *FILE,int LINE);
#  define jseGetFunction(c,o,f,e) jseReallyGetFunction((c),(o),(f),(e),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyCreateFunctionTextVariable(jseContext jsecontext,jseVariable FuncVar,
                                    char *FILE,int LINE);
#  define jseCreateFunctionTextVariable(c,f) jseReallyCreateFunctionTextVariable((c),(f),__FILE__,__LINE__)
   JSECALLSEQ(jseVariable) jseReallyCreateWrapperFunction(jseContext jsecontext,
      const jsecharptr functionName,
      void (JSE_CFUNC FAR_CALL *funcPtr)(jseContext jsecontext),
                sword8 minVariableCount, sword8 maxVariableCount,
      jseVarAttributes varAttributes, jseFuncAttributes funcAttributes, void _FAR_ *fData,
                                                 char *FILE,int LINE);
#  define jseCreateWrapperFunction(c,f,p,mn,mx,va,fa,fd) \
           jseReallyCreateWrapperFunction((c),(f),(p),(mn),(mx),(va),(fa),(fd),__FILE__,__LINE__)
   JSECALLSEQ(void) jseReallyMemberWrapperFunction(jseContext jsecontext,jseVariable objectVar,
      const jsecharptr functionName,
      void (JSE_CFUNC FAR_CALL *funcPtr)(jseContext jsecontext),
      sword8 minVariableCount, sword8 maxVariableCount,
      jseVarAttributes varAttributes, jseFuncAttributes funcAttributes, void _FAR_ *fData,
      char *FILE,int LINE);
#  define jseMemberWrapperFunction(c,o,f,p,mn,mx,va,fa,fd) \
           jseReallyMemberWrapperFunction((c),(o),(f),(p),(mn),(mx),(va),(fa),(fd),__FILE__,__LINE__)
   JSECALLSEQ(jseVariable) jseReallyCurrentFunctionVariable(jseContext jsecontext,char *FILE,int LINE);
#  define jseCurrentFunctionVariable(c) jseReallyCurrentFunctionVariable((c),__FILE__,__LINE__)
   JSECALLSEQ(jseVariable) jseReallyPop(jseContext jsecontext, jseStack jsestack,char *FILE,int LINE);
#  define jsePop(c,s) jseReallyPop((c),(s),__FILE__,__LINE__)
   JSECALLSEQ(jseVariable) jseReallyGetCurrentThisVariable(jseContext jsecontext,char *FILE,int LINE);
#  define jseGetCurrentThisVariable(c) jseReallyGetCurrentThisVariable((c),__FILE__,__LINE__)
   JSECALLSEQ( jseVariable ) jseReallyGlobalObjectEx(jseContext jsecontext,jseActionFlags flags,
                                char *FILE,int LINE);
#  define jseGlobalObjectEx(c,f) jseReallyGlobalObjectEx((c),(f),__FILE__,__LINE__)

#endif


#ifdef __cplusplus
   }
#endif

/* Return all struct packing to previous
*/
#if !defined(__JSE_UNIX__) && !defined(__JSE_MAC__) \
 && !defined(__JSE_PSX__) && !defined(__JSE_PALMOS__)
#  if defined(__BORLANDC__)
#     pragma option -a.
#  else
#     pragma pack( )
#  endif
#endif

#if defined(__JSE_GEOS__)
extern double strtod(const char _FAR *s, char _FAR *_FAR *endptr);
#endif

#endif
