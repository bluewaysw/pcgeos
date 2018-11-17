/******************************************************
 *  platform.h                                        *
 *  When integrating the SE:ISDK, use this header to  *
 *  automatically define the platform and link method *
 *****************************************************/

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

#ifndef _PLATFORM_H
#define _PLATFORM_H

#if !defined(JSETOOLKIT_CORE) && !defined(JSETOOLKIT_APP) && \
    !defined(JSETOOLKIT_LINK)
#  define JSETOOLKIT_APP
#endif

/* if they havnt alread defined __JSE_DLLLOAD__ or __JSE_DLLRUN__
     then flag to link with the static library
 */
#if !defined(__JSE_DLLLOAD__) && !defined(__JSE_LIB__)
#  define __JSE_LIB__
#endif

#if defined(__DJGPP__)
#  if !defined(__JSE_DOS32__)
#     define __JSE_DOS32__
#  endif
#elif defined(__palmos__)
#  define __JSE_PALMOS__
#elif defined(__PSISOFT32__)
#  if !defined(__JSE_EPOC32__)
#     define __JSE_EPOC32__
#  endif
#elif defined(__psx__)
#  define __JSE_PSX__
#elif defined(__unix__) && !defined(__JSE_UNIX__)
#  if !defined(__JSE_UNIX__)
#     define __JSE_UNIX__
#  endif
#elif defined(__WATCOMC__)
   /* Watcom - All versions */
#  if defined(__DOS__) && defined(__I86__)
#     if !defined(__JSE_DOS16__)
#        define __JSE_DOS16__
#     endif
#  elif defined(__DOS__) && defined(__386__)
#     if !defined(__JSE_DOS32__)
#        define __JSE_DOS32__
#     endif
#  elif defined(__OS2__) && defined(__I86__)
#    error 16bit OS2 not supported
#  elif defined(__OS2__) && defined(__386__)
#     if !defined(__JSE_OS2TEXT__)
#        if !defined(__JSE_OS2PM__)
#           define __JSE_OS2PM__
#        endif
#     endif
#  elif defined(__QNX__)
#    error QNX currently not supported
#  elif defined(__NETWARE__)
#     if !defined(__JSE_NWNLM__)
#        define __JSE_NWNLM__
#     endif
#  elif defined(__NT__)
#     if !defined(__JSE_CON32__) && !defined(__JSE_WIN32__)
#        define __JSE_WIN32__
#     endif
#  elif defined(__WINDOWS__)
#     if !defined(__JSE_WIN16__)
#        define __JSE_WIN16__
#     endif
#  else
#     error Urecognized WATCOM target platform
#  endif
#elif defined(_MSC_VER) && _MSC_VER == 800
   /* MSVC 1.52 */
#  if defined(_MSDOS) && !defined(_WINDOWS)
#     if !defined(__JSE_DOS16__)
#        define __JSE_DOS16__
#     endif
#  elif defined(_WINDOWS)
#     if !defined(__JSE_WIN16__)
#        define __JSE_WIN16__
#     endif
#  else
#     error Unrecognized MSVC1.52 platform
#  endif
#elif defined(_MSC_VER) && _MSC_VER >= 1000
   /* MSVC 4.X and up */
#  if defined(WIN32) && defined(_WIN32_WCE)
#     if !defined(__JSE_WINCE__)
#        define __JSE_WINCE__
#     endif
#     if !defined(__JSE_WIN32__)
#        define __JSE_WIN32__
#     endif
#  elif defined(WIN32) && defined(_CONSOLE)
#     if !defined(__JSE_CON32__)
#        define __JSE_CON32__
#     endif
#  else
#     if !defined(__JSE_WIN32__)
#        define __JSE_WIN32__
#     endif
#  endif
#elif defined(__BORLANDC__) && (__BORLANDC__ >= 0x450) \
   && !defined(__JSE_DOS32__) && !defined(__JSE_DOS16__) \
   && !defined(__JSE_WIN16__)
   /* Borland 4.5 and up */
#  if defined(_Windows) && defined(__DPMI16__) /* DOS w/ 16-bit PowerPack */
#    define __JSE_DOS16__
#  elif defined(__WIN32__) && defined(__DPMI32__)/* DOS w/ 32-bit PowerPack */
#    define __JSE_DOS32__
#  elif defined(__GEOS__) /* GEOS implementation */
#	 define __JSE_GEOS__
#  elif defined(__MSDOS__) && !defined(_Windows) /* real mode DOS */
#    define __JSE_DOS16__
#  elif defined(__WIN32__) /* 32-bit Windows (95/NT) */
#    define __JSE_WIN32__
#  elif defined(_Windows) && !defined(__WIN32__) /* 16-bit Windows (3.11) */
#    define __JSE_WIN16__
#  else
#     error Unrecognized Borland target platform
#  endif
#endif
#endif

   /* Metrowerks Codewarrior */
#if defined(__MWERKS__) && !defined(__JSE_PALMOS__)
#  if defined(macintosh)
#     define __JSE_MAC__
#  endif
#endif

   /* Try to get some processor defined */
#if defined(_SH3_)
#  define JSE_CHIP_SH3
#elif defined(_X86_)
#  define JSE_CHIP_X86
#else
#  define JSE_CHIP_UNKNOWN
#endif

   /* must non-byte data be aligned on this chip? */
#if !defined(JSE_ALIGN_DATA)
#  if defined(JSE_CHIP_SH3)
#     define JSE_ALIGN_DATA 1
#  else
#     define JSE_ALIGN_DATA 0
#  endif
#endif

   /* occasional code can be optimized differently if we know that
    * multithreading is or is not needed.
    */
#if !defined(JSE_PREEMPTIVE_THREADS)
#  if defined(JSE_THREADSAFE_POSIX_CRTL) && (0!=JSE_THREADSAFE_POSIX_CRTL)
#     define JSE_PREEMPTIVE_THREADS 1
#  else
#     if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
      || defined(__JSE_WIN32__) || defined(__JSE_CON32__) \
      || defined(__JSE_NWNLM__) \
      || defined(__JSE_UNIX__) \
      || defined(__JSE_EPOC32__) \
      || defined(__JSE_390__)
#        define JSE_PREEMPTIVE_THREADS 1
#     else
#        define JSE_PREEMPTIVE_THREADS 0
#     endif
#  endif
#endif

#if !defined(JSE_THREADSAFE_POSIX_CRTL)
#  if (0==JSE_PREEMPTIVE_THREADS)
#     define JSE_THREADSAFE_POSIX_CRTL 0
#  else
/* FreeBSD header files have the functions, but no man entries,
 * and I couldn't find them in any of the libraries to link with.
 */
#     if defined(__JSE_UNIX__) && !defined(__FreeBSD__)
#        define JSE_THREADSAFE_POSIX_CRTL 1
#     else
#        define JSE_THREADSAFE_POSIX_CRTL 0
#     endif
#  endif
#endif

#if 0!=JSE_THREADSAFE_POSIX_CRTL && (defined(__sun__) || defined(__hpux__))
#define _REENTRANT
#endif
#if 0!=JSE_THREADSAFE_POSIX_CRTL && (defined(_AIX) || defined(__FreeBSD__))
#define _THREAD_SAFE
#endif

#if 0!=JSE_THREADSAFE_POSIX_CRTL && 0==JSE_PREEMPTIVE_THREADS
#  error cannot have JSE_THREADSAFE_POSIX_CRTL without JSE_PREEMPTIVE_THREADS
#endif

   /* To combat empty files on really ANSI-C compilers */
#if defined(__MWERKS__)
#  if __option(ANSI_strict)
#     define  ALLOW_EMPTY_FILE static ubyte DummyVariable;
#  endif
#endif

#if !defined(ALLOW_EMPTY_FILE)
#  define ALLOW_EMPTY_FILE   /* this compiler allows "empty" files */
#endif

/* Static object initialization primarily for PALMOS, hopefully nowhere else */
#if !defined(DECLARE_LARGE_STATIC_ARRAY)
  #if defined(JSE_UNINIT_STATIC_DATA) && (1==JSE_UNINIT_STATIC_DATA)
     #define DECLARE_LARGE_STATIC_ARRAY(id,type,name,size) \
       extern int jseBSSInit_##name(); \
       extern CONST_DATA(type) *name
     #define DEFINE_LARGE_STATIC_ARRAY(id,type,name,size) \
       CONST_DATA(type) *name; \
       int jseBSSInit_##name() { \
           return jseBSSInit_arrayOf##type( &name, size, id);\
       }
     #define JSE_INIT_STATIC_DATA 0
  #else
     #define JSE_INIT_STATIC_DATA 1
     #define DEFINE_LARGE_STATIC_ARRAY(id,type,name,size) \
       CONST_DATA(type) name[] = {
     #define DECLARE_LARGE_STATIC_ARRAY(id,type,name,size) \
       extern CONST_DATA(type) name[];
  #endif

  #if defined(JSE_RECORD_STATIC_DATA) && (1==JSE_RECORD_STATIC_DATA)
     #undef DECLARE_LARGE_STATIC_ARRAY
     #undef DEFINE_LARGE_STATIC_ARRAY
     #undef JSE_INIT_STATIC_DATA

     #define JSE_INIT_STATIC_DATA 1
     #define DECLARE_LARGE_STATIC_ARRAY(id,type,name,size) \
       extern int jseBSSRecord_##name(); \
       extern CONST_DATA(type) _jsepersist_##name[]; \
       extern CONST_DATA(type) *name;

     #define DEFINE_LARGE_STATIC_ARRAY(id,type,name,size) \
       int jseBSSRecord_##name() { \
           return jseBSSRecord_arrayOf##type( _jsepersist_##name, size, id);\
       }\
       CONST_DATA(type) _jsepersist_##name[] = {
  #endif
#endif
