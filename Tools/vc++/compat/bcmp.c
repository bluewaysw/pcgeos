/*
 * Copyright (c) 1987, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <config.h>		/* always include this before anything else */

#ifndef HAVE_BCMP

#if !defined(lint)
static char rcsid[] = "$Id$";
#endif

#ifdef __HIGHC__


/***********************************************************************
 *				bcmp
 ***********************************************************************
 * SYNOPSIS:	compare one array of bytes to another
 * CALLED BY:	GLOBAL
 * RETURN:	0 if the two arrays are equal, non-zero if not
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/18/91		Initial Revision
 *
 ***********************************************************************/
int
bcmp(genptr p1, genptr p2, unsigned len)
{
    return _compare(p1, p2, len);
}

#else /* !__HIGHC__ */

/*
 * bcmp -- vax cmpc3 instruction
 */
int
bcmp(genptr b1, genptr b2, unsigned length)
{
	register char *p1, *p2;

	if (length == 0)
		return(0);
	p1 = (char *)b1;
	p2 = (char *)b2;
	do
		if (*p1++ != *p2++)
			break;
	while (--length);
	return(length);
}

#endif

#endif /* !HAVE_BCMP */
