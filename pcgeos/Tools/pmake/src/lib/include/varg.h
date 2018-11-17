/*
 * varargs.h --
 *
 *	Declarations used by procedures to deal gracefully (and
 *	in a portable fashion) with variable numbers of arguments.
 *	See the man page for detailed documentation of what's in here.
 *
 * Copyright (C) 1985 Regents of the University of California
 * All rights reserved.
 *
 *
 * $Id: varg.h,v 1.1 96/06/24 14:57:36 tbradley Exp $ SPRITE (Berkeley)
 */

#ifndef _VARARGS
#define _VARARGS

typedef struct {
    char *vl_first;			/* Pointer to first arg in list. */
    char *vl_next;			/* Pointer to next to traverse. */
} Varg_List;

#define Varg_Decl int Varg_Args

#define Varg_Start(list) \
    (list).vl_first = (char *) &Varg_Args; \
    (list).vl_next = (list).vl_first

#define Varg_Restart(list) \
    (list).vl_next = (list).vl_first

#define Varg_Next(list, type) \
    ((list).vl_next += sizeof(type), \
     ((type *) (list).vl_next)[-1])

#endif _VARARGS
