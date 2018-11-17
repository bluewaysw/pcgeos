/*  srccore.h
 *
 *  include file that includes everything needed to compile any scriptease
 *  source file. This is included first and get precompiled, hopefully greatly
 *  speeding compilation.
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

#if defined (__GEOS__)

/* Define GEOS here */
#define __JSE_GEOS__

#define jseVariable jseVariable_int
#define jseContext jseContext_int
#define jseStack jseStack_int
#define jseExternalLinkParameters jseExternalLinkParameters_int
#define jseStackInfo jseStackInfo_int

#endif


#ifndef _SRCCORE_H
#define _SRCCORE_H

#if defined(__sun) && !defined(__sun__)
#  define __sun__
#endif

/* Here the actual options */
#include "jseopt.h"
#define JSETOOLKIT_CORE 1

/* garbage collector debug flags, see var.h for a description */
#if defined(JSE_NEVER_FREE) && !defined(JSE_DONT_POOL)
#  define JSE_DONT_POOL 1
#endif
#if !defined(JSE_NEVER_FREE)
#  define JSE_NEVER_FREE 0
#endif
#if !defined(JSE_DONT_POOL)
#  define JSE_DONT_POOL 0
#endif
#if !defined(JSE_ALWAYS_COLLECT)
#  define JSE_ALWAYS_COLLECT 0
#endif
#if !defined(JSE_FUNCTION_LENGTHS)
#  define JSE_FUNCTION_LENGTHS 1
#endif
#if !defined(JSE_PACK_OBJECTS)
#  if !defined(JSE_MIN_MEMORY) || (0==JSE_MIN_MEMORY)
#     define JSE_PACK_OBJECTS 0
#  else
#     define JSE_PACK_OBJECTS 1
#  endif
#endif
#if !defined(JSE_COMPACT_LIBFUNCS)
#  define JSE_COMPACT_LIBFUNCS 1
#endif
#if !defined(JSE_GROWABLE_STACK) && defined(JSE_MIN_MEMORY) && JSE_MIN_MEMORY!=0
#  define JSE_GROWABLE_STACK 1
#endif
#if !defined(JSE_PACK_SECODES)
/* If we need alignment, can't pack or it will be bad */
#if defined(JSE_MIN_MEMORY) && JSE_MIN_MEMORY!=0 && \
    (!defined(JSE_ALIGN_DATA) || JSE_ALIGN_DATA==0)
#define JSE_PACK_SECODES 1
#else
#define JSE_PACK_SECODES 0
#endif
#endif

#ifndef JSE_USER_STRINGS
#define JSE_USER_STRINGS 1
#endif

#if !defined(JSE_REGEXP_LITERALS)
   /* You may want to turn off regular-expression literals in small-memory
    * situations.
    */
#  define JSE_REGEXP_LITERALS  1
#endif

#if !defined(JSE_PER_OBJECT_CACHE)
#  if JSE_MIN_MEMORY!=0 \
   || ( JSE_MEMEXT_OBJECTS!=0 && JSE_MEMEXT_READONLY!=0 )
      /* object cache is used too often in readonly-lookup to be writeable */
#     define JSE_PER_OBJECT_CACHE 0
#  else
#     define JSE_PER_OBJECT_CACHE 1
#  endif
#endif
#if JSE_PER_OBJECT_CACHE!=0 && JSE_MEMEXT_OBJECTS!=0 && JSE_MEMEXT_READONLY!=0
#  error Invalid conditions for using the per-object cache
#endif

#if !defined(JSE_CACHE_GLOBAL_VARS)
#  if (!defined(JSE_PEEPHOLE_OPTIMIZER) || (0!=JSE_PEEPHOLE_OPTIMIZER))
#     define JSE_CACHE_GLOBAL_VARS 1
#  else
      /* We turn it off by default because otherwise you can get the
       * wrong answer if you do something like 'a = 10; var a;' in
       * which case the first reference to 'a' will be a seAssignGlobal,
       * which will use the cached 'a', but that is wrong. The 'var a'
       * takes precedence. The peephole will go through and notice
       * that 'a' has since been defined and turn it into the correct
       * seAssignLocal opcode.
       */
#     define JSE_CACHE_GLOBAL_VARS 0
#  endif
#endif

#if defined(JSE_UNICODE) && (0!=JSE_UNICODE) && !defined(UNICODE)
#  define UNICODE
#endif


#ifdef __JSE_GEOS__
#include <geos.h>
#include <system.h>
#include <Ansi/stdio.h>
#include <Ansi/assert.h>
#include <math.h>
#include <Ansi/string.h>
#include <Ansi/stdlib.h>
#include <Ansi/ctype.h>
#include <geomisc.h>
#include <ProfPnt.goh>

/* GEOS memory stuff */
#define GEOS_MAPPED_MALLOC
/* enable to do some simple memory tracking (also jseopt.h) */
// #define MEM_TRACKING

#define EXIT_FAILURE	1
#define EXIT_SUCCESS	0

#define exit(p)




#define max(a,b)    (((a) > (b)) ? (a) : (b))
#define min(a,b)    (((a) < (b)) ? (a) : (b))

#define strnicmp(a,b,n) LocalCmpStringsNoCase((a),(b),(n))
#else


#if !defined(FALSE) || !defined(TRUE)
#  define FALSE 0
#  define TRUE 1
#endif


#if !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#  include <assert.h>
#endif

#ifdef __JSE_MAC__
   /* Replace the assert macro */
#  ifndef NDEBUG
#     undef assert
#     define assert(condition) ((condition) ? ((void) 0) : \
                                my_assertion_failed(#condition, __FILE__, \
                                __LINE__))
#  endif
#endif

#if !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#  include <stdio.h>
#endif

#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>

#if !defined(__JSE_MAC__) && !defined(__JSE_UNIX__) \
 && !defined(__JSE_390__) && !defined(__JSE_EPOC32__)
#  include <malloc.h>
#endif
#if defined(__JSE_UNIX__)
#  include <stdlib.h>
#endif

#if defined(__WATCOMC__) && (defined(__JSE_DOS16__) || \
                             defined(__JSE_WIN16__) || defined(__JSE_DOS32__))
#  include <i86.h>
#endif
#if (defined(__BORLANDC__) || defined(_MSC_VER)) \
 && !defined(__JSE_EPOC32__) && !defined(__JSE_WINCE__)
#  include <dos.h>
#endif

#if !defined(__BORLANDC__) || (defined(__BORLANDC__) && \
                               defined(__JSE_OS2TEXT__))
#   ifndef max
#     define max(a,b)            (((a) > (b)) ? (a) : (b))
#   endif
#   ifndef min
#     define min(a,b)            (((a) < (b)) ? (a) : (b))
#   endif
#endif

#if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#   include <windows.h>
#endif


#if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#  define INCL_DOSDATETIME
#  define INCL_DOSERRORS
#  define INCL_DOSFILEMGR
#  define INCL_DOSMODULEMGR
#  define INCL_DOSPROCESS
#  define INCL_DOSSEMAPHORES
#  define INCL_DOSSESMGR
#  define INCL_ERRORS
#  define INCL_ORDINALS
#  define INCL_WINATOM
#  define INCL_WINSWITCHLIST
#  define INCL_DOSDEVICES
#  if defined(__JSE_OS2PM__)
#     define INCL_PM
#  else
#     define INCL_VIO
#     define INCL_KBD
#  endif
#  include <os2.h>
#  include <os2def.h>
#endif
#endif	/* __JSE_GEOS__ */


#define jseContext_ struct Call
#define jseVariable_ struct Var
#define jseFunction_ struct Function
#define jseStack_ struct jseCallStack

#include "jsetypes.h"
#include "jselib.h"

#if defined(__JSE_WINCE__)
#  include "winceutl.h"
#endif

/* possible changes to extended memory */
#include "sememext.h"

/* It is faster and code is smaller. However, for highly recursive
 * functions, it will be limiting. Either change to have
 * a growable stack (JSE_FIXEDSTACK predefined to 0) or increase
 * the limit. Basically, each function call takes about 3 + numargs
 * stack entries, plus any temporary entries it uses for expression
 * parsing and such. Probably 1 function depth per 10-12 entries.
 *
 * Don't attempt to make this realloc() growable. There are many places
 * in which you will have a variable on the stack, then push another.
 * If that push causes a realloc, the old variable is garbage
 */
#if !defined(JSE_FIXEDSTACK)
#  if defined(JSE_MIN_MEMORY) && (1==JSE_MIN_MEMORY)
#     define JSE_FIXEDSTACK  0
#  else
#     define JSE_FIXEDSTACK  1
#  endif
#  ifndef JSE_FIXEDSTACK_DEPTH
#     define JSE_FIXEDSTACK_DEPTH 10000
#  endif
/* memory usage will be 15 or 16 bytes per depth, in one block */
#endif

/* JSE_HASH_SIZE determines the default size of the hash table, or if
 * JSE_ONE_STRING_TABLE is defined, the size of the global table
 */
#if !defined(JSE_HASH_SIZE)
#  define JSE_HASH_SIZE   256
#endif


/* JSE_ONE_STRING_TABLE specifies that a single global string table should
 * be used, instead of being stored in the call global.  By default, it
 * is disabled.
 */
#if !defined(JSE_ONE_STRING_TABLE)
#  define JSE_ONE_STRING_TABLE  0
#endif


/* We cheat on varnames. If it is even, it is a regular jsechar *.
 * If it is odd, it is actually a numeric name, derived as
 * (2*number)-1.
 */
typedef void * VarName;

struct Source;
#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)
   struct TokenSrc;
#endif
#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
   struct TokenDst;
#endif
struct LocalFunction;

#ifndef NDEBUG
#  include "dbgprntf.h"
#endif
#include "dirparts.h"
#include "textcore.h"
#include "utilhuge.h"
#include "jsemem.h"
#include "utilstr.h"
#include "globldat.h"

struct tok;

#if defined(JSE_MIN_MEMORY) && (0!=JSE_MIN_MEMORY)
   typedef uword16 MemCountUInt;
   /* to match the above size limit */
#ifndef HUGE_MEMORY
#  define HUGE_MEMORY 0x7fff
#endif
#else
   typedef size_t MemCountUInt;
#endif

#include "atexit.h"
#include "var.h"
#include "secode.h"

#if defined(__JSE_GEOS__)
#include "util.h"
#include "call.h"
#else
#include "call.h"
#include "util.h"
#endif


#include "function.h"
#include "jseengin.h"
#include "define.h"
#include "code.h"
#if defined(JSE_LINK) && (0!=JSE_LINK)
#  include "selink.h"
#  include "extlib.h"
#endif
#if defined(__JSE_GEOS__)
#include "jlibrary.h"
#else
#include "library.h"
#endif
#include "security.h"
#include "source.h"
#if defined(__JSE_GEOS__)
#include "jstoken.h"
#else
#include "token.h"
#endif
#include "loclfunc.h"
#include "operator.h"
#include "analyze.h"

#ifdef __JSE_UNIX__
#  include "unixfunc.h"
#endif

#if (0!=JSE_FLOATING_POINT)
#  include <math.h>
#endif

#if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__) || defined(__JSE_GEOS__)) && \
    (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
#  define callMayIContinue(call) \
      ( ((call)->Global->ExternalLinkParms.MayIContinue) ? \
            (jsebool)DispatchToClient((call)->Global->ExternalDataSegment,\
                                    (ClientFunction)((call)->Global-> \
                                    ExternalLinkParms.MayIContinue),\
                                    (void *)call) : \
       True)
#else
#  define callMayIContinue(call) \
      ( ((call)->Global->ExternalLinkParms.MayIContinue) ? \
        ( (*((call)->Global->ExternalLinkParms.MayIContinue))(call) ): \
       True)
#endif

#if (defined(__JSE_WIN16__) || defined(__JSE_DOS16__)) && \
    (defined(__JSE_DLLLOAD__) || defined(__JSE_DLLRUN__))
#  if defined(__cplusplus)
      extern "C"
#  endif
   uword16 _FAR_ * cdecl FAR_CALL Get_SS_BP();
#endif

#if (defined(__JSE_DOS16__)  ||  defined(__JSE_WIN16__)) \
   && (defined(__SMALL__) || defined(__TINY__) || defined(__MEDIUM__))
#  define  FAR_MEMCPY(d,s,l)  _fmemcpy(d,s,l)
#  define  FAR_MEMCHR(s,c,l)  _fmemchr(s,c,l)
#  define  FAR_STRLEN(s)      _fstrlen(s)
#  define  FAR_STRCPY(d,s)    _fstrcpy(d,s)
#else
#  define  FAR_MEMCPY(d,s,l)  memcpy(d,s,l)
#  define  FAR_MEMCHR(s,c,l)  memchr(s,c,l)
#  define  FAR_STRLEN(s)      strlen(s)
#  define  FAR_STRCPY(d,s)    strcpy(d,s)
#endif

#if defined(__JSE_PALMOS__)
#  define EXIT_SUCCESS   0
#  define _MAX_PATH      32
#elif defined(__JSE_PSX__) || defined(__JSE_GEOS__)
#  define EXIT_SUCCESS   0
#  define _MAX_PATH      255
#endif

#if (0!=JSE_FLOATING_POINT)
   /* wraparound values to be calculated only once */
   extern VAR_DATA(jsenumber) jseFPx10000;
   extern VAR_DATA(jsenumber) jseFPx100000000;
   extern VAR_DATA(jsenumber) jseFPx7fffffff;
#endif

#ifdef __JSE_GEOS__
#include <heap.h>
#define LFOM(x) MemLockFixedOrMovable(x)
#define UFOM(x) MemUnlockFixedOrMovable(x)
#else
#define LFOM(x) (x)
#define UFOM(x) (x)
#endif

#endif /* ifndef _SRCCORE_H */
