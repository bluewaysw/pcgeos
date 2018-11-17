

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferClearBand.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	9/93	initial version

DESCRIPTION:

	$Id: bufferClearBand.asm,v 1.1 97/04/18 11:50:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrClearBandBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	clear the band buffer for the routines that need zeros in it.

CALLED BY:	PrintSwath

PASS:
		es	=	PState
		buffer must be dereferenced and locked
RETURN:	
DESTROYED:	
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrClearBandBuffer	proc	near
	uses	ax,cx,di,es
	.enter
	mov	ax,es:[PS_bandBWidth]	;byte width
	mov	cx,PRINTHEAD_HEIGHT/2	;x scanlines/2
	mul	cx
	mov	cx,ax			;= word count
	mov	di,offset GPB_bandBuffer
	mov	es,es:[PS_bufSeg]	;address to start clearing es:di
	clr	ax
	rep stosw
	.leave
	ret
PrClearBandBuffer	endp
