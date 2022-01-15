/* This file is *not* part of the FreeType project, because the team    */
/* lacks the necessary expertise to support it.                         */

/* freetype.c for MacOS */
/* single object library component for MacOS */

/* Written by Dave Willis <dwilliss@microimages.com> on 1998-07-30.     */
/* Modified by Antoine Leca for the 1.3 release, but untested.          */

#define TT_MAKE_OPTION_SINGLE_OBJECT

/* Note, you should define the EXPORT_DEF and EXPORT_FUNC macros here */
/* if you want  to build a DLL. If undefined, the macros are defined  */
/* as "export" and "" (i.e. nothing), which is the normal behaviour.  */
/* The macros are placed before each high-level API function          */
/* declaration. You can then use them to take any compiler-specific   */
/* pragma for DLL-exported symbols. See 'ttconfig.h' for details.     */


/* first include common core components */

#define MAC_MAIN_OBJECT
#include "ttapi.c"
#include "ttcache.c"
#include "ttcalc.c"
#include "ttcmap.c"
#include "ttdebug.c"
#include "ttgload.c"
#include "ttinterp.c"
#include "ttload.c"
#include "ttobjs.c"
#include "ttobjs.c"
#include "ttraster.c"

/* then system-specific (or ANSI) components */

#include "ttmmap.c"		/* Was "ttfile.c" */
#include "ttmemory.c"
#include "ttmutex.c"

/* finally, add some extensions */

#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
#include "ttextend.c"
#endif


/* END */
