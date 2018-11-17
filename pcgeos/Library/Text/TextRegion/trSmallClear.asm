COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trSmallClear.asm

AUTHOR:		John Wedgwood, Feb 18, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/18/92	Initial revision

DESCRIPTION:
	Code for clearing in regions.

	$Id: trSmallClear.asm,v 1.1 97/04/07 11:21:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClearRectCommon

DESCRIPTION:	Clear a rectangle

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax, bx, cx, dx - area to clear

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
ClearRectCommon	proc	near
	class	VisTextClass

	cmp	bx, dx
	jz	done

	call	TextCheckCanDraw
	jc	done				; Branch if can't draw

	call	TextRegion_DerefVis_DI		; ds:di <- instance ptr

	push	ax, bx				; Save left/top
	movdw	bxax, ds:[di].VTI_washColor	; ax/bx <- wash-color
	mov	di, ds:[di].VTI_gstate		; di <- gstate to use
	call	GrSetAreaColor			; Set the color to clear to
	mov	ax, SDM_100			; Draw it all
	call	GrSetAreaMask			; Set the mask to use
	pop	ax, bx				; Restore left/top

	call	GrFillRect			; Fill the rectangle
done:
	ret

ClearRectCommon	endp

ClearRectCommonFar proc far
	call ClearRectCommon
	ret
ClearRectCommonFar endp

;SmallRegionClearToBottom	proc	near
;	call	SmallRegionClearToBottomFar
;	ret
;SmallRegionClearToBottom	endp

;SmallRegionClearSegments	proc	near
;	call	SmallRegionClearSegments
;	ret
;SmallRegionClearSegments	endp

SmallRegionAdjustHeight	proc	near
	call	SmallRegionAdjustHeightFar
	ret
SmallRegionAdjustHeight	endp

TextRegion	ends

TextSmallRegion	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionClearToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear from the bottom of a line to the bottom of the 
		region containing that line.

CALLED BY:	TR_RegionClearToBottom via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionClearToBottom	proc	far	uses	ax, bx, cx, dx
	class	VisTextClass
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	call	TextRegion_DerefVis_DI		; ds:di <- instance ptr

	clr	ax
	mov	al, ds:[di].VTI_tbMargin
	shl	ax
	ceilwbf	ds:[di].VTI_height, bx		; bx = top (bottom of text)
	mov	dx, ds:[di].VI_bounds.R_bottom
	sub	dx, ds:[di].VI_bounds.R_top
	sub	dx, ax

	push	bx
	call	SmallRegionLeftRightFar		; ax = left, bx = right
	mov	cx, bx				; cx = right
	pop	bx

	inc	bx				; start 1 point beyond bottom
						;  of text
	call	ClearRectCommonFar
	.leave
	ret
SmallRegionClearToBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionClearSegments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all segments between two vertical positions.

CALLED BY:	TR_RegionClearSegments
PASS:		*ds:si	= Instance
		ax	= Top of area
		bx	= Bottom of area
		dx	= Left edge of area
		cx	= Region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionClearSegments	proc	far
	uses	ax, bx, cx, dx
	.enter
	xchg	ax, bx			; ax <- bottom of area
					; bx <- top of area
	xchg	ax, dx			; dx <- bottom of area
					; ax <- left edge of area

	push	ax, bx			; Save left, top
	call	SmallRegionLeftRightFar	; ax <- left, bx <- right
	mov	cx, bx			; cx <- right edge
	pop	ax, bx			; Restore left, top

	call	ClearRectCommonFar		; Clear the area
	.leave
	ret
SmallRegionClearSegments	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SmallRegionAdjustHeight

DESCRIPTION:	Adjust a region's height

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - region number
	dx.al - height change

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
SmallRegionAdjustHeightFar	proc	far	uses ax, bx, cx, dx, si, bp
	class	VisTextClass
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	; update height

	call	TextRegion_DerefVis_DI
	addwbf	ds:[di].VTI_height, dxal

	mov	ax, ds:[di].VI_bounds.R_right	; Save width for this height
	sub	ax, ds:[di].VI_bounds.R_left
	mov	ds:[di].VTI_lastWidth, ax

	movwbf	dxal, ds:[di].VTI_height	; dx.al <- pos to clear from
	
	push	di
	call	SmallRegionClearToBottom	; Nukes di
	pop	di

	ceilwbf	dxal, dx

	clr	ax				; ax <- margin spacing
	mov	al, ds:[di].VTI_tbMargin
	shl	ax, 1

	add	dx, ax				; dx <- total height

	;
	; Do the notification after the clear so that the VTI_height field
	; of the object won't have been changed when we clear.
	;
	mov	ax, TEMP_VIS_TEXT_FREEING_OBJECT
	call	ObjVarFindData
	jc	noNotify
	push	cx				; Save region number
	mov	ax, MSG_VIS_TEXT_HEIGHT_NOTIFY	; Notify subclass of change
	call	ObjCallInstanceNoLock
	pop	cx				; Restore region number
noNotify:
	call	TextRegion_DerefVis_SI
	mov	di, ds:[si].VTI_gstate
	call	SmallSetClip

	.leave
	ret

SmallRegionAdjustHeightFar	endp

TextSmallRegion	ends
