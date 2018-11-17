/* 
 * sys.c --
 *
 *	Miscellaneous user-level run-time library routines for the Sys module.
 *
 * Copyright 1986 Regents of the University of California
 * All rights reserved.
 */
#include <config.h>

#ifndef lint
static char rcsid[] = "$Id: sys.c,v 1.1 96/06/24 15:04:40 tbradley Exp $ SPRITE (Berkeley)";
#endif not lint


#include <stdio.h>
#include <stdlib.h>

#include "sprite.h"
#include "sys.h"
#include <stdarg.h>




/*
 * ----------------------------------------------------------------------------
 *
 * Sys_Panic --
 *
 *      Print a formatted string and then,depending on the panic level,
 *	abort to the debugger or continue.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The process may be put into the debug state.
 *
 * ----------------------------------------------------------------------------
 */

/*VARARGS2*/
void
Sys_Panic(
    Sys_PanicLevel      level,	/* Severity of the error. */
    char 	*format,	/* Contains literal text and format control
                                 * sequences indicating how elements of
                                 * Varg_Alist are to be printed.  See the
                                 * Io_Print manual page for details. */
    ...)                        /* Variable number of values to be formatted
                                 * and printed. */
{
    va_list args;

    va_start(format, args);

    if (level == SYS_WARNING) {
        fprintf(stderr, "Warning: ");
    } else {
        fprintf(stderr, "Fatal Error: ");
    }

    vfprintf(stderr, format, args);
    fflush(stderr);
    
    va_end(args);

    if (level == SYS_FATAL) {
	abort();
    }
}
