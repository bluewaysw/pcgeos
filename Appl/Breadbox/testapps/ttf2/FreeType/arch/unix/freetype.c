/* This file is part of the FreeType project */

/* Single object library component for Unix */

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

/* The Makefile creates proper links to following three files */

#include "file.c"
#include "memory.c"
#include "mutex.c"

#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
#include "ttextend.c"
#endif


/* END */
