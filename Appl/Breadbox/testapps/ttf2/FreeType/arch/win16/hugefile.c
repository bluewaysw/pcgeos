/*******************************************************************
 *
 *  hugefile.c
 *
 *    File I/O Component (body) for dealing with "huge" objects
 *    under 16-bit Windows. Relies on the "default" version, with
 *    a small hook.  Requires Windows 3.1+.
 *
 *  Written by Antoine Leca based on ideas from Dave Hoo.
 *  Copyright 1999 by Dave Hoo, Antoine Leca,
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *  NOTE
 *
 *    This file #includes the normal version, to avoid discrepancies
 *    between versions.  It uses only ANSI-mandated "tricks", so
 *    any ANSI-compliant compiler should be able to compile this file.
 *
 ******************************************************************/

#include "ttconfig.h"
#include "tttypes.h"

#include <windows.h>

  /* Here we include <stdio.h>, to have the proper definition of fread */
#include <stdio.h>

  /*  Some compilers define fileno(), some define _fileno()...      */
#ifndef _fileno
#define _fileno(stream)  fileno(stream)
#endif

  /* Then, we divert the use of fread to the Windows version */
#undef fread
#define fread(ptr, size, n, stream)                             \
    _hread( _fileno(stream), (char TT_HUGE_PTR *) ptr, (ULong)n * size )


  /* Now, we include the "normal" version of `ttfile.c'             */
  /* The ANSI/ISO standard mandates that the include of <stdio.h>   */
  /* there have no bad effects.                                     */
#include "ttfile.c"

/* END */
