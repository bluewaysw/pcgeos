/*******************************************************************
 *
 *  ttconfig.h                                                1.0
 *
 *    Configuration settings header file (spec only).
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  Notes:
 *
 *    All the configuration #define statements have been gathered in
 *    this file to allow easy check and modification.
 *
 ******************************************************************/

#ifndef TTCONFIG_H
#define TTCONFIG_H



/* ------------ auto configuration ------------------------------------- */


/*************************************************************************/
/* Here we include the file ft_conf.h for system dependent stuff.        */
/* The specific makefile is responsible for providing the right path to  */
/* this file.                                                            */

#include "ft_conf.h"


/**************************************************************************/
/* Define TT_CONFIG_THREAD_SAFE if you want to build a thread-safe        */
/* version of the library.                                                */

/* #define TT_CONFIG_OPTION_THREAD_SAFE */



/* ------------ general debugging -------------------------------------- */


/*************************************************************************
 *
 *  There are now three debugging modes:
 *
 *  - trace mode:
 *
 *       Error and trace messages are sent to the log file
 *       (which can be the standard error output).  Define
 *       DEBUG_LEVEL_TRACE to enable this mode.
 *
 *  - error mode:
 *
 *       Only error messages are generated.  Define
 *       DEBUG_LEVEL_ERROR to enable this mode.
 *
 *  - release mode:
 *
 *       Error messages are neither sent nor generated. The code is
 *       free from any debugging parts.
 *
 *
 * Note that you should link the engine with the 'ttdebug' component.
 * in case either DEBUG_LEVEL_TRACE or DEBUG_LEVEL_ERROR is defined.
 *
 * Please consult ttdebug.h for more details.                           */

/* #define DEBUG_LEVEL_TRACE */
/* #define DEBUG_LEVEL_ERROR */



/* ------------ special debugging -------------------------------------- */


/*************************************************************************/
/* Define this if you want to generate a special debug version of the    */
/* rasterizer.  This will progressively draw the glyphs while the        */
/* computations are done directly on the graphics screen... (with        */
/* inverted glyphs).                                                     */
/*                                                                       */
/* Use it at your own risk!  It is not maintained currently.             */
/*                                                                       */
/* IMPORTANT: This is reserved to developers willing to debug the        */
/*            rasterizer, which seems working very well in its           */
/*            current state...                                           */

/* #define DEBUG_RASTER */


/*************************************************************************/
/* Define this to have a simple debugger version of RunIns().            */
/*                                                                       */
/* Use it at your own risk!  It is not maintained currently.             */

/* #define DEBUG_INTERPRETER */


/*************************************************************************/
/* Define this to have some housekeeping of allocation and deallocation. */
/*                                                                       */
/* Please note that probably not all OS-specific versions of ttmemory.c  */
/* provide this functionality.                                           */

#define DEBUG_MEMORY


/*************************************************************************/
/* Define this to have bounds checking for file buffer frames.           */
/*                                                                       */
/* Please note that probably not all OS-specific versions of ttfile.c    */
/* provide this functionality.                                           */

/* #define DEBUG_FILE */



/* ------------ arithmetic and processor support ----------------------- */


/*************************************************************************/
/* Define TT_USE_LONG_LONG if you want to enable the use of the          */
/* 'long long' 64-bit type provided by gcc and other compilers. Note     */
/* that :                                                                */
/*                                                                       */
/*   1. The type isn't ANSI, and thus will produce many warnings         */
/*      during library compilation.                                      */
/*                                                                       */
/*   2. Though the generated object files are slightly smaller, the      */
/*      resulting executables are bigger of about 4Kb! gcc must be       */
/*      linking some extra code in there!                                */
/*                                                                       */
/*   3. There is really no speed gain in doing so (but it may help       */
/*      debug the ttcalc component).                                     */
/*                                                                       */
/* IMPORTANT NOTE: You don't need to define it on 64-bits machines!      */
/*                                                                       */
/* NOTE 2 : This flag used to be _GNUC_LONG64_                           */

/* #define TT_USE_LONG_LONG */


/*************************************************************************/
/* define ALIGNMENT to your processor/environment preferred alignment    */
/* size. A value of 8 should work on all current processors, even        */
/* 64-bits ones.                                                         */

#define ALIGNMENT 8



/* --------------- miscellaneous ----------------------------------- */


/*********************************************************************/
/* The number of extensions available.  Don't change this value      */
/* except if you add new extensions to the engine.                   */

#define TT_MAX_EXTENSIONS  2



/* --------------- automatic setup -- don't touch ------------------ */


/*********************************************************************/
/* If HAVE_TT_TEXT is defined we don't provide a default typedef for */
/* defining TT_Text.                                                 */

#ifndef HAVE_TT_TEXT
#define HAVE_TT_TEXT
  typedef char  TT_Text;
#endif


/*********************************************************************/
/* We define NULL in case it's not defined yet.  The default         */
/* location is stdlib.h.                                             */

#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif


/*********************************************************************/
/* Some systems can't use vfprintf for error messages on stderr; if  */
/* HAVE_PRINT_FUNCTION is defined, the Print macro must be supplied  */
/* externally (having the same parameters).                          */
/*                                                                   */
/* This is only used by the "ttdebug" component, which should be     */
/* linked to the engine only in debug mode.                          */

#if defined( DEBUG_LEVEL_TRACE ) || defined( DEBUG_LEVEL_ERROR )
#ifndef HAVE_PRINT_FUNCTION
#define Print( format, ap )  vfprintf( stderr, (format), (ap) )
#endif
#endif


/********************************************************************/
/*                                                                  */
/* I have added the ability to compile the library into a single    */
/* object file. This gets rids of all the external symbols defined  */
/* in each  component interface, and de-pollutes the name-space.    */
/*                                                                  */
/* I use two macros, namely LOCAL_FUNC and LOCAL_DEF, which only    */
/* apply to functions that are internal to the engine, and          */
/* should never be seen or linked by a client application.          */
/*                                                                  */
/*  LOCAL_DEF   used in header (.h) files, to define a function     */
/*              that will be seen by other components. This         */
/*              translates to "extern" in normal mode, and to       */
/*              "static" in single-object mode.                     */
/*                                                                  */
/*  LOCAL_FUNC  used in implementation (.c) files, just before      */
/*              the function body. This translates to nothing       */
/*              in normal mode, and to "static" in single-object    */
/*              mode.                                               */
/*                                                                  */
/*  Getting rid of un-necessary symbols makes the "ttcommon"        */
/*  renaming macros hack unnecessary. Moreover, the stripped        */
/*  single object file (freetype.o) is 52 Kb, instead of the        */
/*  previous 57 Kb (size of all combined .o files), and gives       */
/*  a better idea of the engine's real code size.                   */
/*                                                                  */
/*  It is called a "MAKE_OPTION" because the macro must be          */
/*  defined in the Makefile, rather than this one. It allows        */
/*  any developer to quickly switch from one mode to the other      */
/*  without messing with "ttconfig.h" each time.                    */
/*                                                                  */
//#ifndef TT_MAKE_OPTION_SINGLE_OBJECT
#define LOCAL_FUNC  /* void */
#define LOCAL_DEF   extern
// #else
// #define LOCAL_FUNC  static
// #define LOCAL_DEF   static
// #endif


/*************************************************************************/
/* Define EXPORT_DEF and EXPORT_FUNC as needed to build e.g. a DLL.  All */
/* variables and functions visible from outside have these prefixes.     */

#ifndef EXPORT_DEF
#define EXPORT_DEF  extern
#endif

#ifndef EXPORT_FUNC
#define EXPORT_FUNC  /* void */
#endif



/* -------------- internal (developer) configuration toggles ------------ */


#undef TT_STATIC_INTERPRETER
/* Do not undefine this configuration macro. It is now a default that */
/* must be kept in all release builds.                                */


#undef TT_STATIC_RASTER
/* Define this if you want to generate a static raster.  This makes */
/* a non re-entrant version of the scan-line converter, which is    */
/* about 10% faster and 50% bigger than an indirect one!            */


#endif /* TTCONFIG_H */


/* END */
