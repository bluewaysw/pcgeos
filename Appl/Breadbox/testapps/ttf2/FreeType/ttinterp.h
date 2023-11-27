/*******************************************************************
 *
 *  ttinterp.h                                              2.2
 *
 *  TrueType bytecode intepreter.
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 *
 *  Changes between 2.2 and 2.1:
 *
 *  - a small bugfix in the Push opcodes
 *
 *  Changes between 2.1 and 2.0:
 *
 *  - created the TTExec component to take care of all execution
 *    context management.  The interpreter has now one single
 *    function.
 *
 *  - made some changes to support re-entrancy.  The re-entrant
 *    interpreter is smaller!
 *
 ******************************************************************/

#ifndef TTINTERP_H
#define TTINTERP_H

#include "ttconfig.h"
#include "ttobjs.h"


#ifdef __cplusplus
  extern "C" {
#endif

  /* Run instructions in current execution context */

  LOCAL_DEF TT_Error  RunIns( PExecution_Context  exc );

#ifdef __cplusplus
  }
#endif

#endif /* TTINTERP_H */


/* END */
