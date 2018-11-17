COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsEC.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/17/92   	Initial version.

DESCRIPTION:
	

	$Id: utilsEC.asm,v 1.1 97/04/04 17:47:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ife FULL_EXECUTE_IN_PLACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSrcDestBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check the source-dest bounds for a string copy

CALLED BY:	THROUGHOUT CHART

PASS:		ds:si - source
		es:di - dest
		cx - # bytes to move

RETURN:		nothing 

DESTROYED:	nothing , flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSrcDestBounds	proc far
	uses	ds, si
	.enter

	pushf

	call	ECCheckBounds
	add	si, cx
	dec	si
	call	ECCheckBounds
	segmov	ds, es, si
	mov	si, di
	call	ECCheckBounds
	add	si, cx
	dec	si
	call	ECCheckBounds

	popf

	.leave
	ret
ECCheckSrcDestBounds	endp
endif
