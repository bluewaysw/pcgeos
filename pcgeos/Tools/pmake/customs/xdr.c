/*-
 * xdr.c --
 *	Functions for encoding and decoding data between customs
 *	agents and their clients.
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
 */
#ifndef lint
static char *rcsid =
"$Id: xdr.c,v 1.10 89/11/14 13:46:23 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customs.h"
#include    "log.h"
#include    <sys/time.h>


/*-
 *-----------------------------------------------------------------------
 * xdr_exportpermit --
 *	encode/decode an ExportPermit structure.
 *
 * Results:
 *	TRUE.
 *
 * Side Effects:
 *	Of course.
 *
 *-----------------------------------------------------------------------
 */
bool_t
xdr_exportpermit (xdrs, permitPtr)
    XDR	    	  *xdrs;
    ExportPermit  *permitPtr;
{
    if (xdrs->x_op == XDR_FREE) {
	return TRUE;
    } else {
	return (xdr_in_addr (xdrs, &permitPtr->addr) &&
		xdr_u_long (xdrs, &permitPtr->id));
    }
}


/*-
 *-----------------------------------------------------------------------
 * xdr_in_addr --
 *	encode an in_addr structure.
 *
 * Results:
 *	TRUE.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
bool_t
xdr_in_addr (xdrs, addrPtr)
    XDR	    	  	*xdrs;
    struct in_addr	*addrPtr;
{
    if (xdrs->x_op == XDR_FREE) {
	return TRUE;
    } else {
	return xdr_opaque (xdrs, addrPtr, sizeof(struct in_addr));
    }
}

/*-
 *-----------------------------------------------------------------------
 * xdr_sockaddr_in --
 *	encode/decode a sockaddr_in structure.
 *
 * Results:
 *	TRUE if ok. FALSE otherwise.
 *
 * Side Effects:
 *	None....
 *
 *-----------------------------------------------------------------------
 */
bool_t
xdr_sockaddr_in (xdrs, siPtr)
    XDR	    	  	*xdrs;
    struct sockaddr_in	*siPtr;
{
    if (xdrs->x_op != XDR_FREE) {
	return (xdr_short (xdrs, &siPtr->sin_family) &&
		xdr_u_short (xdrs, &siPtr->sin_port) &&
		xdr_in_addr (xdrs, &siPtr->sin_addr));
    }
}
/*-
 *-----------------------------------------------------------------------
 * xdr_strvec --
 *	encode/decode a string vector. The address of the vector must be
 *	passed. On XDR_ENCODE, the vector must be null-terminated. On
 *	XDR_DECODE, the resulting vector will be null-terminated. That's
 *	what a vector is...
 *
 * Results:
 *	TRUE if ok. FALSE otherwise.
 *
 * Side Effects:
 *	Memory may be allocated...
 *
 *-----------------------------------------------------------------------
 */
bool_t
xdr_strvec (xdrs, vecPtr)
    XDR	    *xdrs;
    char    ***vecPtr;
{
    register short	i;
    register char 	**vec;
    short   	  	cnt;
    short   	  	len;
    bool_t  	  	rval;

    vec = *vecPtr;

    switch (xdrs->x_op) {
	case XDR_FREE:
	    if ((short *)vec < &len && vec != (char **)0) {
		free ((char *)vec);
	    }
	    return TRUE;
	case XDR_ENCODE:
	    for (i = 0; vec[i] != (char *)0; i++) {
		continue;
	    }
	    cnt = i;
	    rval = xdr_short (xdrs, &cnt);
	    for (i = 0; i < cnt; i++) {
		len = strlen (vec[i]);
		rval = rval && xdr_short (xdrs, &len);
		rval = rval && xdr_opaque (xdrs, vec[i], len);
	    }
	    return rval;
	case XDR_DECODE:
	    rval = xdr_short (xdrs, &cnt);
	    if (rval && vec == (char **)0) {
		*vecPtr = vec = (char **)malloc ((cnt + 1) * sizeof(char *));
		bzero ((char *)vec, (cnt + 1) * sizeof (char *));
	    }
	    for (i = 0; i < cnt; i++) {
		rval = rval && xdr_short (xdrs, &len);
		if (rval && vec[i] == (char *)0) {
		    vec[i] = (char *)malloc (len + 1);
		    vec[i][len] = '\0';
		}
		rval = rval && xdr_opaque (xdrs, vec[i], len);
	    }
	    return rval;
    }
    return FALSE;
}

		
