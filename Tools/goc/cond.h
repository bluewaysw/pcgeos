/*	constants for Cond module
 *
 * Copyright (c) 1988, 1989 by the Regents of the University of California
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any non-commercial purpose
 * and without fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California,
 * Berkeley Softworks and Adam de Boor make no representations about
 * the suitability of this software for any purpose.  It is provided
 * "as is" without express or implied warranty.
 *
 *  $Id$
 */

/* 
 * These are the return values from Cond_Eval, the only entrypoint of the 
 * Cond module.
 */


#define COND_PARSE	0   	/* Parse the next lines */
#define COND_SKIP 	1   	/* Skip the next lines */
#define COND_INVALID	2   	/* Not a conditional statement */
#define DEBUG_COND	0x00000040


extern int Cond_Eval(char *line);    /* Line to parse */

extern void Cond_End(void);

