/* jseTypes.h     Recognized types for jse code
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

#ifndef _JSETYPES_H
#define _JSETYPES_H

#if !defined(JSE_FLOATING_POINT)
   /* unless specifically defined elsewhere, assume floating point */
#  define JSE_FLOATING_POINT 1
#endif

#include "jsedef.h"

#if defined(__JSE_GEOS__)
#include "resource.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif


/************************************
 *** MUST HAVE DEFINED THE TARGET ***
 ************************************/
#if   defined(__JSE_DOS16__)
#elif defined(__JSE_DOS32__)
#elif defined(__JSE_OS2TEXT__)
#elif defined(__JSE_OS2PM__)
#elif defined(__JSE_WIN16__)
#elif defined(__JSE_WIN32__)
#elif defined(__JSE_CON32__)
#elif defined(__JSE_NWNLM__)
#elif defined(__JSE_UNIX__)
#elif defined(__JSE_390__)
#elif defined(__JSE_MAC__)
#elif defined(__JSE_PALMOS__)
#elif defined(__JSE_PSX__)
#elif defined(__JSE_EPOC32__)
#elif defined(__JSE_GEOS__)
#else
#  error UNDEFINED TARGET ENVIRONMENT
#endif

/**************************************
 *** MUST HAVE DEFINED THE COMPILER ***
 **************************************/
#if   defined(__BORLANDC__)
#elif defined(__WATCOMC__)
#elif defined(_MSC_VER)
#elif defined(__GNUC__)
#elif defined(__MWERKS__)
#elif defined(__IBMCPP__)
#elif defined(__IBMC__)
#elif defined(__sun)
#else
#  error UNDEFINED COMPILER
#endif

#if defined(_MSC_VER) || defined(__BORLANDC__)
#  define __near    _near
#  define __far     _far
#  define __huge    _huge
#  define __pascal  _pascal
#  define __cdecl   _cdecl
#endif

#if defined(_MSC_VER)
#  define inline    _inline
#endif

	
#if defined(__JSE_GEOS__) && defined(__BORLANDC__)
/* GeoComment: pragma to get rid of "Variable is never used" warnings.
               Note that this turns off all compile warnings for the file. */
#pragma Off(Warn)
#endif


/* not all systems agree on the meaning of NULL always reflecting a full
 * pointer size.  On such system the following macros can be used.
 */
#ifndef NULLPTR
#  define NULLPTR ((void *)0)
#endif
#ifndef NULLCAST
#  define NULLCAST(DATATYPE) ((DATATYPE)0)
#endif

#if defined(__sun) && !defined(__GNUC__)
#  define signed
#endif

typedef signed char     sbyte;
typedef unsigned char   ubyte;
typedef signed int      sint;
#if !defined(__JSE_UNIX__) || defined(__JSE_PALMOS__)
   /* already typedefed in system headers, don't do it again */
   typedef unsigned int    uint;
#else
#  include <sys/types.h>
#endif
#if !defined(_AIX) && !defined(__linux__) && !defined(__sgi__) \
 && !defined(__osf__) && !defined(__JSE_BEOS__) \
 && (!defined(__sun__) || (!defined(__svr4__) && !defined(__sun))) /* solaris */ \
 && !defined(__JSE_IOS__)
   typedef unsigned long   ulong;
#endif
typedef signed long     slong;

#define MAX_SBYTE       ((sbyte)0x7F)
#define MIN_SBYTE       ((sbyte)0x80)
#define MAX_UBYTE       ((ubyte)0xFF)
#if defined(__JSE_DOS16__) || defined(__JSE_DOS32__) \
 || defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
 || defined(__JSE_WIN16__) || defined(__JSE_390__) \
 || defined(__JSE_WIN32__) || defined(__JSE_CON32__) \
 || defined(__JSE_NWNLM__) || defined(__JSE_UNIX__) \
 || defined(__JSE_MAC__) || defined(__JSE_PSX__) \
 || defined(__JSE_PALMOS__) || defined(__JSE_EPOC32__) \
 || defined(__JSE_GEOS__)
#  if (0==JSE_FLOATING_POINT)
#     define MAX_SLONG    ((slong)0x7FFFFFFDL)
#     define MIN_SLONG    ((slong)0x80000004L)
#  else
#     define MAX_SLONG    ((slong)0x7FFFFFFFL)
#     define MIN_SLONG    ((slong)0x80000000L)
#  endif
#  define MAX_ULONG       ((ulong)0xFFFFFFFFL)
#else
#  error Must define MAX_SLONG, MIN_SLONG, and MAX_ULONG
#endif

#if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
 || defined(__JSE_DOS32__) \
 || defined(__JSE_WIN32__) || defined(__JSE_CON32__) \
 || defined(__JSE_NWNLM__) || defined(__JSE_UNIX__) \
 || defined(__JSE_MAC__) || defined(__JSE_PSX__) \
 || defined(__JSE_PALMOS__) || defined(__JSE_EPOC32__) \
 || defined(__JSE_GEOS__)
#  define MAX_SINT        MAX_SLONG
#  define MIN_SINT        MIN_SLONG
#  define MAX_UINT        MAX_ULONG
#elif defined(__JSE_DOS16__) || defined(__JSE_WIN16__) \
   || defined(__JSE_390__)
#  define MAX_SINT        ((sint)0x7FFF)
#  define MIN_SINT        ((sint)0x8000)
#  define MAX_UINT        ((uint)0xFFFF)
#else
#  error Must define MAX_SINT, MIN_SINT, and MAX_UINT
#endif

typedef sbyte           sword8;
typedef ubyte           uword8;
typedef signed short    sword16;
typedef unsigned short  uword16;
#if defined(__osf__)
   typedef signed int      sword32;
   typedef unsigned int    uword32;
#else
   typedef slong           sword32;
   typedef ulong           uword32;
#endif

#define MAX_SWORD8      ((sword8)0x7F)
#define MIN_SWORD8      ((sword8)0x80)
#define MAX_UWORD8      ((uword8)0xFF)
#define MAX_SWORD16     ((sword16)0x7FFF)
#define MIN_SWORD16     ((sword16)0x8000)
#define MAX_UWORD16     ((uword16)0xFFFF)
#define MAX_SSHORT      MAX_SWORD16
#define MIN_SSHORT      MIN_SWORD16
#define MAX_USHORT      MAX_UWORD16
#if (0==JSE_FLOATING_POINT)
#  define MAX_SWORD32   ((slong)0x7FFFFFFDL)
#  define MIN_SWORD32   ((slong)0x80000004L)
#else
#  define MAX_SWORD32   ((sword32)0x7FFFFFFF)
#  define MIN_SWORD32   ((sword32)0x80000000)
#endif
#define MAX_UWORD32     ((uword32)0xFFFFFFFF)


typedef sint   jsebool;
#if defined(__JSE_390__)
   typedef sint jsetinybool;
#else
   typedef uword8 jsetinybool;
#endif
#if !defined(False) || !defined(True)
#  define  False 0
#  define  True  1
#endif
#if !defined(FALSE) || !defined(TRUE)
#  define FALSE 0
#  define TRUE 1
#endif

#if defined(__linux__)
#  include <endian.h>
#endif
#if defined(__FreeBSD__)
#  include <machine/endian.h>
#endif
#if defined(_AIX)
#  include <sys/machine.h>
#endif
#if defined(__osf__)
#  include <alpha/endian.h>
#endif
#if defined(__sgi__)
#  include <sys/endian.h>
#elif defined(__sun__)
#  include <sys/byteorder.h>
#endif

/* define the Endianness of this system; define False if not
 * BIG_ENDIAN, else True
 */
#if defined(__BYTE_ORDER)
#  if __BYTE_ORDER==__BIG_ENDIAN
#     define SE_BIG_ENDIAN True
#  else
#     define SE_BIG_ENDIAN False
#   endif
#elif defined(BYTE_ORDER)
#   if BYTE_ORDER==BIG_ENDIAN
#     define SE_BIG_ENDIAN True
#   else
#     define SE_BIG_ENDIAN False
#   endif
#elif defined(_BIG_ENDIAN)
#   define SE_BIG_ENDIAN True
#elif defined(__JSE_DOS16__) || defined(__JSE_DOS32__) \
 || defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
 || defined(__JSE_WIN16__) || defined(__JSE_390__) \
 || defined(__JSE_WIN32__) || defined(__JSE_CON32__) \
 || defined(__JSE_NWNLM__) || defined(__JSE_PSX__) \
 || defined(__JSE_GEOS__)
#  define SE_BIG_ENDIAN False
#elif defined(__JSE_MAC__) || defined(__JSE_PALMOS__)
#  define SE_BIG_ENDIAN True
#elif defined(__hpux__)
#  define SE_BIG_ENDIAN True
#elif defined(__JSE_EPOC32__)
#  if defined(__WINS__)
#     define SE_BIG_ENDIAN False
#  else
#     define SE_BIG_ENDIAN True
#  endif
#else
#  error cant figure byte order for this machine
#endif

#if !defined(JSE_POINTER_SIZE)
   /* if pointer size not defined, assume 32 bits */
#  if defined(__osf__)
#     define JSE_POINTER_SIZE  64
#  else
#     define JSE_POINTER_SIZE  32
#  endif
#endif
#if JSE_POINTER_SIZE == 64
#  define JSE_POINTER_SINT    slong
#  define JSE_POINTER_UINT    ulong
#elif JSE_POINTER_SIZE == 32
#  define JSE_POINTER_SINT    sword32
#  define JSE_POINTER_UINT    uword32
#elif JSE_POINTER_SIZE == 16
#  define JSE_POINTER_SINT    sword16
#  define JSE_POINTER_UINT    uword16
#elif JSE_POINTER_SIZE == 8
#  define JSE_POINTER_SINT    sword8
#  define JSE_POINTER_UINT    uword8
#else
#  error JSE_POINTER_SIZE not understood on this system
#endif

#if !defined(_NEAR_)
#  if defined(__JSE_DOS16__) || defined(__JSE_WIN16__) || defined(__JSE_GEOS__)
#     define  _NEAR_   __near
#  else
#     define  _NEAR_   /* */
#  endif
#endif

#if !defined(_FAR_)
#  if defined(__JSE_DOS16__) || defined(__JSE_WIN16__) || defined(__JSE_GEOS__)
#     define  _FAR_   __far
#  else
#     define  _FAR_   /* */
#  endif
#endif

#if !defined(FAR_CALL)
#  if defined(__JSE_DOS16__) || defined(__JSE_WIN16__)
#     define  FAR_CALL   __far
#  else
#     define  FAR_CALL   /* */
#  endif
#endif

#if !defined(JSE_POINTER_SINDEX)
#  if defined(__JSE_DOS16__) || defined(__JSE_WIN16__)
#     if defined(_MSC_VER) && _MSC_VER == 800
         /* msvc1.52 grows too big */
#        define JSE_NO_HUGE
#     endif
#     if defined(JSE_NO_HUGE)
#        define  _HUGE_   /* */
#        define JSE_POINTER_SINDEX sint
#        define JSE_POINTER_UINDEX uint
#        define JSE_PTR_MAX_SINDEX MAX_SINT
#        define JSE_PTR_MIN_SINDEX MIN_SINT
#        define JSE_PTR_MAX_UINDEX MAX_UINT
#     else
#        define  _HUGE_   __huge
#        define JSE_POINTER_SINDEX slong
#        define JSE_POINTER_UINDEX ulong
#        define JSE_PTR_MAX_SINDEX MAX_SLONG
#        define JSE_PTR_MIN_SINDEX MIN_SLONG
#        define JSE_PTR_MAX_UINDEX MAX_ULONG
#     endif
#  else
#     define  _HUGE_   /* */
#     define JSE_POINTER_SINDEX slong
#     define JSE_POINTER_UINDEX ulong
#     define JSE_PTR_MAX_SINDEX MAX_SLONG
#     define JSE_PTR_MIN_SINDEX MIN_SLONG
#     define JSE_PTR_MAX_UINDEX MAX_ULONG
#  endif
#endif


#define  VAR_DATA(DATADEF) DATADEF _NEAR_
#define  CONST_DATA(DATADEF) const DATADEF _NEAR_


/* Borland DOS16 and Win16 should always be far_calls until the core
 * can fit in 64k
 */

#if defined(NEAR_CALL)
#  define NEAR_CALL_CFUNC NEAR_CALL
#else
#  if !defined(NDEBUG)
      /* for debugging make no change to NEAR_CALL */
#     define NEAR_CALL /*  */
#     define NEAR_CALL_CFUNC /*  */
#  else
#     if defined(_MSC_VER) && _MSC_VER == 800
         /* msvc1.52 grows too big */
#        define  NEAR_CALL   /*  */
#        define NEAR_CALL_CFUNC /*  */
#     elif defined(__JSE_GEOS__)
#        define  NEAR_CALL   __pascal
#        define  NEAR_CALL_CFUNC /*  */
#     elif defined(__JSE_DOS16__) && !defined(__BORLANDC__)
#        define  NEAR_CALL   /* __near */
#        define NEAR_CALL_CFUNC /* __near */
#     elif defined(__JSE_WIN16__)
#        define  NEAR_CALL   /*  */
#        define NEAR_CALL_CFUNC /*  */
#     elif (defined(_MSC_VER) && (800<_MSC_VER))
#        define  NEAR_CALL  __fastcall
#        define NEAR_CALL_CFUNC /*  */
#     else
#        define  NEAR_CALL   /*  */
#        define NEAR_CALL_CFUNC /*  */
#     endif
#  endif

#endif


#  if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#    if defined(__JSE_WIN32__) && defined(__OPEN32__)
#      define WINDOWS_CALLBACK_FUNCTION(FUNCTION_TYPE)   FUNCTION_TYPE WINAPI
#    elif (defined(__JSE_WIN32__) || defined(__JSE_CON32__)) && defined(__BORLANDC__)
#      define WINDOWS_CALLBACK_FUNCTION(FUNCTION_TYPE)   __export FUNCTION_TYPE CALLBACK
#    elif defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#      define WINDOWS_CALLBACK_FUNCTION(FUNCTION_TYPE)   __declspec(dllexport) FUNCTION_TYPE CALLBACK
#    else
#      define WINDOWS_CALLBACK_FUNCTION(FUNCTION_TYPE)   FUNCTION_TYPE __export __far __pascal
#    endif
#  endif



#ifndef NDEBUG
#  define SEDBG(x) x
#else
#  define SEDBG(x)
#endif

#ifdef __cplusplus
}
#endif

/* include the UNICODE/MBCS/ASCII options */
#include "seuni.h"
/* include the floating-point options */
#include "sefp.h"

#endif
