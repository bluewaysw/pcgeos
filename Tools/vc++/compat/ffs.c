/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Tools
MODULE:		Unix compatibility library
FILE:		ffs.c

AUTHOR:		Jacob A. Gabrielson, May 24, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	5/24/96   	Initial version.

DESCRIPTION:
	Finds first set bit in a word.
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>

#ifndef HAVE_FFS


/***********************************************************************
 *				ffs
 ***********************************************************************
 * SYNOPSIS:	    This isn't a byte-oriented thing, but it's in the
 *	    	    bstring(3) man page, so...
 *	    	    This function finds the index of the first set bit in
 *	    	    a longword.
 * CALLED BY:	    GLOBAL
 * RETURN:	    bit index, 1-origin, of the first set bit. 0 if
 *	    	    no bits are set.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *	    Performs a binary-search on the integer, in effect.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/91		Initial Revision
 *
 ***********************************************************************/
int
ffs(int n)
{
    if (n != 0) {
	if (n & 0x0000ffff) {
	    if (n & 0x000000ff) {
		if (n & 0x0000000f) {
		    if (n & 0x00000003) {
			if (n & 0x00000001) {
			    return(1);
			} else {
			    return(2);
			}
		    } else {
			if (n & 0x00000004) {
			    return(3);
			} else {
			    return(4);
			}
		    }
		} else {
		    if (n & 0x00000030) {
			if (n & 0x00000010) {
			    return(5);
			} else {
			    return(6);
			}
		    } else {
			if (n & 0x00000040) {
			    return(7);
			} else {
			    return(8);
			}
		    }
		}
	    } else {
		if (n & 0x00000f00) {
		    if (n & 0x00000300) {
			if (n & 0x00000100) {
			    return(9);
			} else {
			    return(10);
			}
		    } else {
			if (n & 0x00000400) {
			    return(11);
			} else {
			    return(12);
			}
		    }
		} else {
		    if (n & 0x00003000) {
			if (n & 0x00001000) {
			    return(13);
			} else {
			    return(14);
			}
		    } else {
			if (n & 0x00004000) {
			    return(15);
			} else {
			    return(16);
			}
		    }
		}
	    }
	} else {
	    if (n & 0x00ff0000) { 
		if (n & 0x000f0000) {
		    if (n & 0x00030000) {
			if (n & 0x00010000) {
			    return(17);
			} else {
			    return(18);
			}
		    } else {
			if (n & 0x00040000) {
			    return(19);
			} else {
			    return(20);
			}
		    }
		} else {
		    if (n & 0x00300000) {
			if (n & 0x00100000) {
			    return(21);
			} else {
			    return(22);
			}
		    } else {
			if (n & 0x00400000) {
			    return(23);
			} else {
			    return(24);
			}
		    }
		}
	    } else {
		if (n & 0x0f000000) {
		    if (n & 0x03000000) {
			if (n & 0x01000000) {
			    return(25);
			} else {
			    return(26);
			}
		    } else {
			if (n & 0x04000000) {
			    return(27);
			} else {
			    return(28);
			}
		    }
		} else {
		    if (n & 0x30000000) {
			if (n & 0x10000000) {
			    return(29);
			} else {
			    return(30);
			}
		    } else {
			if (n & 0x40000000) {
			    return(31);
			} else {
			    return(32);
			}
		    }
		}
	    }
	}
    } else {
	return(0);
    }
}

#endif /* !HAVE_FFS */
