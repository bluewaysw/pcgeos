/* This file is part of the FreeType project */

/* Single object library component for 16-bit Windows.                  */
/* Note that low-optimizing compilers (such as Borland ones) cannot     */
/* successfully compile this file, because it exceeds 64K of code size. */
#define TT_MAKE_OPTION_SINGLE_OBJECT

/* first include common core components */

#include "ttapi.c"
#include "ttcache.c"
#include "ttcalc.c"
#include "ttcmap.c"
#include "ttdebug.c"
#include "ttgload.c"
#include "ttinterp.c"
#include "ttload.c"
#include "ttobjs.c"
#include "ttraster.c"

/* then system-specific (or ANSI) components */

#ifdef TT_HUGE_PTR
#include "arch/win16/hugefile.c"
#include "arch/win16/hugemem.c"
#else
#include "ttfile.c"
#include "ttmemory.c"
#endif
#include "ttmutex.c"

/* finally, add some extensions */

#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
#include "ttextend.c"
#endif


/* END */
