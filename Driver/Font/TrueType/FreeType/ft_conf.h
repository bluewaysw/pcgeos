/* This file is part of the FreeType project */

/* ft_conf.h for FreeGEOS build */


/* we need the following because there are some typedefs in this file */

#ifndef FT_CONF_H
#define FT_CONF_H

/* Under FreeGEOS we need some special includes. */
#include <geos.h>
#include <file.h>
#include <resource.h>
#include <graphics.h>
#include <heap.h>
#include <lmem.h>
#include <ec.h>


/* Define to empty if the keyword does not work.  */
/* #undef const */

/* Define if you have a working `mmap' system call.  */
#undef HAVE_MMAP

/* Define if you have the <stdlib.h> header file.  */
#define HAVE_STDLIB_H

/* Define if you have the getpagesize function.  */
#undef HAVE_GETPAGESIZE

/* Define if you have the memcpy function.  */
#define HAVE_MEMCPY

/* Define if you have the memmove function.  */
#define HAVE_MEMMOVE

/* Define if you have the valloc function.  */
#undef HAVE_VALLOC

/* Define if you have the <fcntl.h> header file.  */
#define HAVE_FCNTL_H

/* command.com can't pipe stderr into a file; any message would be */
/* written into the graphics screen.                               */
#define HAVE_PRINT_FUNCTION 1

#define Print( format, ap )  vfprintf( stdout, (format), (ap) )


/* The number of bytes in a int. We use the ANSI header file limits.h */
/* for determining it since there is no easy way to guess.            */
/*                                                                    */
#include <limits.h>
#if   UINT_MAX == 0xFFFF
#define SIZEOF_INT  2
#elif UINT_MAX == 0xFFFFFFFF
#define SIZEOF_INT  4
#else
#error "Unsupported number of bytes in `int' type!"
#endif

/* We now try to guess the size of longs in the same way */
/*                                                       */
#if   ULONG_MAX == 0xFFFFFFFF
#define SIZEOF_LONG 4
#elif ULONG_MAX == 0xFFFFFFFFFFFFFFFF
#define SIZEOF_LONG 8
#else
#error "Unsupported number of bytes in `long' type!"
#endif


/**********************************************************************/
/*                                                                    */
/*  The following configuration macros can be tweaked manually by     */
/*  a developer to turn on or off certain features or options in the  */
/*  TrueType engine. This may be useful to tune it for specific       */
/*  purposes..                                                        */
/*                                                                    */
/**********************************************************************/


/*************************************************************************/
/* Define this if the underlying operating system uses a different       */
/* character width than 8bit for file names.  You must then also supply  */
/* a typedef declaration for defining 'TT_Text'.  Default is off.        */

/* #define HAVE_TT_TEXT */


/*************************************************************************/
/* Define this if you want to generate code to support engine extensions */
/* Default is on, but if you're satisfied by the basic services provided */
/* by the engine and need no extensions, undefine this configuration     */
/* macro to save a few more bytes.                                       */

#define  TT_CONFIG_OPTION_EXTEND_ENGINE


/*************************************************************************/
/* Define this if you want to generate code to support gray-scaling,     */
/* a.k.a. font-smoothing or anti-aliasing. Default is on, but you can    */
/* disable it if you don't need it.                                      */

#undef  TT_CONFIG_OPTION_GRAY_SCALING


/*************************************************************************/
/* Define this if you want to completely disable the use of the bytecode */
/* interpreter.  Doing so will produce a much smaller library, but the   */
/* quality of the rendered glyphs will enormously suffer from this.      */
/*                                                                       */
/* This switch was introduced due to the Apple patents issue which       */
/* emerged recently on the FreeType lists.  We still do not have Apple's */
/* opinion on the subject and will change this as soon as we have.       */

#define   TT_CONFIG_OPTION_NO_INTERPRETER


/*************************************************************************/
/* Define this if you want to use a big 'switch' statement within the    */
/* bytecode interpreter. Because some non-optimizing compilers are not   */
/* able to produce jump tables from such statements, undefining this     */
/* configuration macro will generate the appropriate C jump table in     */
/* ttinterp.c. If you use an optimizing compiler, you should leave it    */
/* defined for better performance and code compactness..                 */

#define  TT_CONFIG_OPTION_INTERPRETER_SWITCH


/*************************************************************************/
/* Define this if you want to build a 'static' version of the TrueType   */
/* bytecode interpreter. This will produce much bigger code, which       */
/* _may_ be faster on some architectures..                               */
/*                                                                       */
/* Do NOT DEFINE THIS is you build a thread-safe version of the engine   */
/*                                                                       */
#undef TT_CONFIG_OPTION_STATIC_INTERPRETER


/*************************************************************************/
/* Define this if you want to build a 'static' version of the scan-line  */
/* converter (the component which in charge of converting outlines into  */
/* bitmaps). This will produce a bigger object file for "ttraster.c",    */
/* which _may_ be faster on some architectures..                         */
/*                                                                       */
/* Do NOT DEFINE THIS is you build a thread-safe version of the engine   */
/*                                                                       */
#undef  TT_CONFIG_OPTION_STATIC_RASTER


/*************************************************************************/
/* Define TT_CONFIG_THREAD_SAFE if you want to build a thread-safe       */
/* version of the library.                                               */

#define  TT_CONFIG_OPTION_THREAD_SAFE


/*************************************************************************/
/* Define TT_CONFIG_OPTION_PROCESS_HDMX if you want to process optional  */
/* hdmx table. The PC/Geos ttf driver does not need any information from */
/* the hdmx table.                                                       */

#undef  TT_CONFIG_OPTION_PROCESS_HDMX


/*************************************************************************/
/* Define TT_CONFIG_OPTION_PROCESS_VMTX if you want to process optional  */
/* vtmx table. The PC/Geos ttf driver does not need any information from */
/* the vtmx table.                                                       */

#undef  TT_CONFIG_OPTION_PROCESS_VMTX


/*************************************************************************/
/* Define TT_CONFIG_OPTION_SUPPORT_CMAP2 if you want to support cmap 0   */
/* char mapping. Charmapping type 0 is now out of date.                  */

#undef  TT_CONFIG_OPTION_SUPPORT_CMAP0


/*************************************************************************/
/* Define TT_CONFIG_OPTION_SUPPORT_CMAP2 if you want to support cmap 2   */
/* char mapping. Charmapping type 2 is now out of date.                  */

#undef  TT_CONFIG_OPTION_SUPPORT_CMAP2


/*************************************************************************/
/* Define TT_CONFIG_OPTION_SUPPORT_CMAP6 if you want to support cmap 6   */
/* char mapping. In ttf fonts charmap 4 is the standard for char mapping.*/

#undef  TT_CONFIG_OPTION_SUPPORT_CMAP6


/*************************************************************************/
/* Define TT_CONFIG_OPTION_SUPPORT_KERN2 if you want to support kerning  */
/* format 1. The ttf driver only supports format 0 because it is very    */
/* simple and common.                                                    */

#undef  TT_CONFIG_OPTION_SUPPORT_KERN2


/*************************************************************************/
/* Define TT_CONFIG_OPTION_SUPPORT_OPTIONAL_FIELDS if you want to hold   */
/* optional fiels in freetype structures.                                */

#undef  TT_CONFIG_OPTION_SUPPORT_OPTIONAL_FIELDS


/*************************************************************************/
/* Define TT_CONFIG_OPTION_SUPPORT_UNICODE_RANGES if you want to hold    */
/* unicode ranges in OS/2 table.                                         */

#undef TT_CONFIG_OPTION_SUPPORT_UNICODE_RANGES


/**********************************************************************/
/*                                                                    */
/*  The following macros are used to define the debug level, as well  */
/*  as individual tracing levels for each component. There are        */
/*  currently three modes of operation :                              */
/*                                                                    */
/*  - trace mode (define DEBUG_LEVEL_TRACE)                           */
/*                                                                    */
/*      The engine prints all error messages, as well as tracing      */
/*      ones, filtered by each component's level                      */
/*                                                                    */
/*  - debug mode (define DEBUG_LEVEL_ERROR)                           */
/*                                                                    */
/*      Disable tracing, but keeps error output and assertion         */
/*      checks.                                                       */
/*                                                                    */
/*  - release mode (don't define anything)                            */
/*                                                                    */
/*      Don't include error-checking or tracing code in the           */
/*      engine's code. Ideal for releases.                            */
/*                                                                    */
/* NOTE :                                                             */
/*                                                                    */
/*   Each component's tracing level is defined in its own source.     */
/*                                                                    */
/**********************************************************************/

/* Define if you want to use the tracing debug mode */
#undef  DEBUG_LEVEL_TRACE

/* Define if you want to use the error debug mode - ignored if */
/* DEBUG_LEVEL_TRACE is defined                                */
#undef  DEBUG_LEVEL_ERROR


/**************************************************************************/
/* Definition of various integer sizes. These types are used by ttcalc    */
/* and ttinterp (for the 64-bit integers) only..                          */

#if SIZEOF_INT == 4

  typedef signed int      TT_Int32;
  typedef unsigned int    TT_Word32;

#elif SIZEOF_LONG == 4

  typedef signed long     TT_Int32;
  typedef unsigned long   TT_Word32;

#else
#error "no 32bit type found"
#endif

#if SIZEOF_LONG == 8

/* LONG64 must be defined when a 64-bit type is available */
/* INT64 must then be defined to this type..              */
#define LONG64
#define INT64   long

#else

/* GCC provides the non-ANSI 'long long' 64-bit type.  You can activate    */
/* by defining the TT_USE_LONG_LONG macro in 'ft_conf.h'.  Note that this  */
/* will produce many -ansi warnings during library compilation.            */
#ifdef TT_USE_LONG_LONG

#define LONG64
#define INT64   long long

#endif /* TT_USE_LONG_LONG */
#endif

#endif /* FT_CONF_H */


/* END */
