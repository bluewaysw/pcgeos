/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Tools
MODULE:		Unix compatibility library
FILE:		bzero.c

AUTHOR:		Jacob A. Gabrielson, May 24, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	5/24/96   	Initial version.

DESCRIPTION:
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#ifndef HAVE_BZERO

#ifdef __HIGHC__


/***********************************************************************
 *				bzero
 ***********************************************************************
 * SYNOPSIS:	zero an array of bytes
 * CALLED BY:	GLOBAL
 * RETURN:	nothing
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
void
bzero(void *dst, unsigned len)
{
    genptr dst0 = (genptr) dst;

    _fill_char(dst0, len, 0);
}

#endif /* __HIGHC__ */

#endif /* !HAVE_BZERO */
