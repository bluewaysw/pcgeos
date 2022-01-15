/* This file is part of the FreeType project */

/* Single object library component for AmigaOS */
#define TT_MAKE_OPTION_SINGLE_OBJECT

#include "ttapi.c"
#include "ttcache.c"
#include "ttcalc.c"
#include "ttcmap.c"
#include "ttdebug.c"
#include "ttfile.c"
#include "ttgload.c"
#include "ttinterp.c"
#include "ttload.c"
#include "ttmemory.c"
#include "ttmutex.c"
#include "ttobjs.c"
#include "ttraster.c"

#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
#include "ttextend.c"
#endif


/* END */
