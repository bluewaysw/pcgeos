/* jseopt.h
 */
#ifndef _JSEOPT_H
#define _JSEOPT_H

#define JSE_TYPE_BUFFER 0
#define JSE_CONDITIONAL_COMPILE 0
#define JSE_DEFINE 0
#define JSE_INCLUDE 0
#define JSE_LINK 0
#define JSE_C_EXTENSIONS 0
#define JSE_SECUREJSE 0
#define JSE_TOKENSRC 0
#define JSE_TOKENDST 0
#if !defined(DO_ERROR_CHECKING)
#define JSE_SHORT_RESOURCE 0
#else
#define JSE_SHORT_RESOURCE 0
#endif
#define JSE_INLINES 1
#define JSE_MIN_MEMORY 1
#define JSE_CACHE_GLOBAL_VARS 1
#define JSE_PER_OBJECT_CACHE 1
#define JSE_CREATEFUNCTIONTEXTVARIABLE  0
#define JSE_GETFILENAMELIST  0
#define JSE_BREAKPOINT_TEST  0
#define JSE_OPERATOR_OVERLOADING 1
#define JSE_MEM_DEBUG 0
#define JSE_ENFORCE_MEMCHECK 0
#define JSE_TRACKVARS 0
#define JSE_API_ASSERTNAMES 0
#define JSE_API_ASSERTLEVEL 0
#define JSE_FLOATING_POINT 1
#define JSE_FP_EMULATOR 1
#define JSE_ENABLE_DYNAMETH 1
#define JSE_NO_HUGE 1
#define JSE_GROWABLE_STACK 0
#if !defined(DO_ERROR_CHECKING)
#  define NDEBUG
#endif

/* Compatibility with JavaScript 1.3 */
#define JSE_ECMA_ALL
#define JSE_ECMA_BUFFER 0
#define JSE_ECMA_EXCEPTIONS 0
#define JSE_ECMA_REGEXP 1  /* this is really 1.2 and used by more than one
			      page in our bug list (same with following
			      string functions) */
#define JSE_STRING_MATCH 1
#define JSE_STRING_SEARCH 1
#define JSE_STRING_REPLACE 1
#define JSE_DATE_FROMSYSTEM 0
#define JSE_DATE_TOSYSTEM 0
#define JSE_STRING_TOLOCALELOWERCASE 0
#define JSE_STRING_TOLOCALEUPPERCASE 0
#define JSE_STRING_TOLOCALECOMPARE 0
#define JSE_DATE_TODATESTRING 0
#define JSE_DATE_TOTIMESTRING 0
#define JSE_DATE_TOLOCALEDATESTRING 0
#define JSE_DATE_TOLOCALETIMESTRING 0
#define JSE_NUMBER_TOFIXED 0
#define JSE_NUMBER_TOEXPONENTIAL 0
#define JSE_NUMBER_TOPRECISION 0
#define JSE_OBJECT_ISPROTOTYPEOF 0
#define JSE_OBJECT_PROPERTYISENUMERABLE 0
#define JSE_OBJECT_HASOWNPROPERTY 0
#define JSE_OBJECT_TOLOCALESTRING 0

/* No source conversion, please. */
#define JSE_LANG_TOSOURCE 0
#define JSE_ARRAY_TOSOURCE 0
#define JSE_STRING_TOSOURCE 0
#define JSE_BOOLEAN_TOSOURCE 0
#define JSE_DATE_TOSOURCE 0
#define JSE_FUNCTION_TOSOURCE 0
#define JSE_NUMBER_TOSOURCE 0
#define JSE_OBJECT_TOSOURCE 0

/* ScriptEase is in a DLL */
#define __JSE_DLLLOAD__

/* GEOS memory stuff */
#define GEOS_MAPPED_MALLOC

/* enable to do some simple memory tracking */
#define MEM_TRACKING

/* Some memory extensions are used */
#define JSE_MEMEXT_SECODES 1
#define JSE_MEMEXT_STRINGS 1
#define JSE_MEMEXT_OBJECTS 1
#define JSE_MEMEXT_MEMBERS 1
#define JSE_MEMEXT_READONLY 0

/* Overrides of default values */
#define JSE_INFREQUENT_COUNT 1000  /* 1000 secodes between abort checking */

/* This accounts for the different use of jseopt.h in srccore.h and some
   of the library files */
#ifndef _SRCCORE_H
#  define JSETOOLKIT_APP 1
#  include "seall.h"
#endif

#endif
