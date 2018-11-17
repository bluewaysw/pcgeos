COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Main
FILE:		globalErrorUtils.asm

AUTHOR:		Steve Scholl, Jan 24, 1992

ROUTINES:
	Name			Description
	----			-----------

GrObjCheckGrObjBaseAreaAttrElement
GrObjCheckGrObjBaseLineAttrElement
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/24/92		Initial revision


DESCRIPTION:
	
		

	$Id: globalErrorUtils.asm,v 1.1 97/04/04 18:05:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GlobalErrorCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckGrObjBaseAreaAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check data in GrObjBaseAreaAttrElement

CALLED BY:	INTERNAL (UTILITY)

PASS:		ds:bp - GrObjBaseAreaAttrElement

RETURN:		
		nothing

DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckGrObjBaseAreaAttrElement		proc	far
	.enter

	pushf
	tst	ds:[bp].GOBAAE_reserved
	jnz	error
	tst	ds:[bp].GOBAAE_reservedByte
	jnz	error
	cmp	ds:[bp].GOBAAE_mask, SystemDrawMask
	jae	error
	cmp	ds:[bp].GOBAAE_drawMode, MixMode
	jae	error
	popf
	.leave
	ret

error:
	ERROR	GROBJ_BAD_AREA_ATTR_ELEMENT


GrObjCheckGrObjBaseAreaAttrElement		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckGrObjBaseLineAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check data in GrObjBaseLineAttrElement

CALLED BY:	INTERNAL (UTILITY)

PASS:		ds:bp - GrObjBaseLineAttrElement

RETURN:		
		nothing

DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckGrObjBaseLineAttrElement		proc	far
	.enter

	pushf
	tst	ds:[bp].GOBLAE_reserved
	jnz	error

	;
	;  This check foiled my attempt to set SDM_INVERSE, so I'm
	;  removing it. - jon 3 nov 1994
	;
	;	cmp	ds:[bp].GOBLAE_mask, SystemDrawMask
	;	jae	error

	cmp	ds:[bp].GOBLAE_end, LineEnd
	jae	error
	cmp	ds:[bp].GOBLAE_style, LineStyle
	jae	error
	cmp	ds:[bp].GOBLAE_join, LineJoin
	jae	error
	cmp	ds:[bp].GOBLAE_width.WWF_int,100
	ja	error
	popf
	.leave
	ret

error:
	ERROR	GROBJ_BAD_LINE_ATTR_ELEMENT


GrObjCheckGrObjBaseLineAttrElement		endp


GlobalErrorCode	ends
