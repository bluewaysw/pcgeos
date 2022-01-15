/*******************************************************************
 *
 *  hugefile.c
 *
 *    File I/O Component (body) for dealing with "huge" objects under
 *    MS-DOS. Relies on the "default" version, with a small hook.
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

/* Here we include <stdio.h>, to have the proper definition of fread */
#include <stdio.h>

/* Then, we divert the use of fread to our version */
#undef  fread
#define fread(ptr, size, n, stream)  huge_fread(ptr, size, n, stream)

  LOCAL_FUNC
  Long huge_fread ( void *ptr, size_t size, Long n, FILE *stream );

/* Now, we include the "normal" version of ttfile.c                 */
/* The ANSI/ISO standard mandates that the include of <stdio.h>     */
/* there have no bad effects.                                       */
#include "ttfile.c"

/* Then, we define our implementation of fread that makes use of    */
/* "huge"-allocated memory.                                         */

/*******************************************************************
 *
 *  Function    : huge_fread
 *
 *  Description : replacement version of fread that handles
 *                "huge"-allocated memory.
 *
 *  Input  : See the reference for the runtime library function fread
 *
 *  Output : See the reference for the runtime library function fread
 *
 *  Notes  :
 *
 ******************************************************************/

  LOCAL_DEF
  Long huge_fread ( void *ptr, size_t size, Long n, FILE *stream )
  {
    char TT_HUGE_PTR * p = (char TT_HUGE_PTR *) ptr;
    ULong        left = (ULong)n * size;
    size_t       toRead;

    while ( left )
    {
      toRead = (left > 0x8000) ? 0x8000 : left;
      if ( (fread)( p, 1, toRead, stream ) != toRead)
        return -1;
      else
      {
        left -= (ULong) toRead;
        p    += toRead;
      }
    }
    return n * size;
  }


/* END */
