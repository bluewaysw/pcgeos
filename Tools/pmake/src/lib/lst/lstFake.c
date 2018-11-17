/*-
 * lstFake.c --
 *	This is a file whose sole purpose is to force ranlib to
 *	place enough entries in the library's table of contents to
 *	prevent it (the table of contents) from looking like an object
 *	file. As of this writing, the table had 0410 (shared text) entries
 *	in it, so we define five junk variables to up the number beyond
 *	the range of the magic numbers.
 *
 * Copyright (c) 1988 by the Regents of the University of California
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California nor
 * Adam de Boor makes any representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 *
 *
 */
#include <config.h>

#ifndef lint
static char *rcsid =
"$Id: lstFake.c,v 1.1 91/03/22 11:19:25 adam Exp $ SPRITE (Berkeley)";
#endif lint

int _junk_one__ = 1;
int _junk_two__ = 2;
int _junk_three__ = 3;
int _junk_four__ = 4;
int _junk_five__ = 5;
