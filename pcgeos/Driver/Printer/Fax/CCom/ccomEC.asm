COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccomEC.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/30/93   	Initial version.

DESCRIPTION:
	

	$Id: ccomEC.asm,v 1.1 97/04/18 11:52:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBoundsESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as ECCheckBounds, but for ES:DI

CALLED BY:	

PASS:		es:di - pointer to check

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/30/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckBoundsESDI	proc far
		uses	ds, si
		.enter
		segmov	ds, es
		mov	si, di
		call	ECCheckBounds
		.leave
		ret
ECCheckBoundsESDI	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSrcDestMoveBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that we ain't scribbling

CALLED BY:	?

PASS:		ds:si - source
		es:di - dest
		cx - # bytes to move

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSrcDestMoveBounds	proc far
		uses	si, di
		.enter
		
		pushf
		call	ECCheckBounds
		add	si, cx
		dec	si
		call	ECCheckBounds

		call	ECCheckBoundsESDI
		add	di, cx
		dec	di
		call	ECCheckBoundsESDI
		popf
		
		.leave
		ret
CheckSrcDestMoveBounds	endp

