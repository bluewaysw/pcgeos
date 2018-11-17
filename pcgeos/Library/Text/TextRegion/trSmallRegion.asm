COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trSmallRegion.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Region create/nuke notification stuff.

	$Id: trSmallRegion.asm,v 1.1 97/04/07 11:22:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionMakeNextRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the creation of another region.

CALLED BY:	TR_MakeNextRegion via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number to create
RETURN:		carry set if we can't make another region. If this
		is the case then we try to make the current region
		taller. (ie: small object)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionMakeNextRegion	proc	near
EC <	call	ECSmallCheckRegionNumber			>

if _REGION_LIMIT
	;
	; Caller will revert the document if we return carry set,
	; so I'll clear it instead.  It was never checked, anyways.
	;
	clc			; need carry clear!
else		
	stc			; Can't make another region
endif		
	ret
SmallRegionMakeNextRegion	endp

TextRegion	ends
