COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeGState.asm

AUTHOR:		John Wedgwood, Feb 25, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/25/92	Initial revision

DESCRIPTION:
	GState related stuff.

	$Id: trLargeGState.asm,v 1.1 97/04/07 11:21:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionTransformGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the gstate so that 0,0 falls at the upper-left
		corner of the region.

CALLED BY:	TR_RegionTransformGState via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region
		dl	= Draw flags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionTransformGState	proc	far	uses ax, bx, cx, dx, di, si, bp
	.enter
	class	VisTextClass

	call	TextRegion_DerefVis_DI
	mov	di, ds:[di].VTI_gstate		; di <- gstate
	call	GrSetDefaultTransform

	push	dx
	sub	sp, size PointDWord
	mov	bp, sp
	call	TR_RegionGetTopLeft
	movdw	dxcx, ss:[bp].PD_x
	movdw	bxax, ss:[bp].PD_y
	add	sp, size PointDWord

	call	GrApplyTranslationDWord
	pop	dx

	; now set the clip rectangle

if 0
	test	dl, mask DF_PRINT
	jnz	noSetClip

	push	di
	call	LargeRegionGetTrueHeight	;dx = height
	ceilwbf	dxal, dx

	mov	bx, 1				;get width for blt-ing
	call	LargeRegionGetTrueWidth		;ax = width
	pop	di
	mov_tr	cx, ax
	clr	ax
	clr	bx
	mov	si, PCT_REPLACE			; Replace old clip rect
	call	GrSetClipRect
noSetClip:
endif

if 0
;---------------------------------------
PrintMessage <TONY: Remove hack in LargeRegionTransformGState after graphics bugs are fixed>

	push	ax, bx, cx, dx
	mov	ax, -1000
	mov	bx, -1000
	mov	cx, -1000+1
	mov	dx, -1000+1
	call	GrFillRect
	pop	ax, bx, cx, dx

;---------------------------------------
endif

	.leave
	ret

LargeRegionTransformGState	endp


TextRegion	ends
