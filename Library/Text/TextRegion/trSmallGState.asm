COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trSmallGState.asm

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

	$Id: trSmallGState.asm,v 1.1 97/04/07 11:21:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallRegionTransformGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the gstate so that 0,0 falls at the upper-left
		corner of the region.

CALLED BY:	TR_RegionTransformGState via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region
		dl	= DrawFlags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallRegionTransformGState	proc	near	uses	ax, bx, cx, dx, di, si
	class	VisTextClass
	.enter
EC <	call	ECSmallCheckRegionNumber			>

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si <- instance
	mov	di, ds:[si].VTI_gstate		; di <- gstate

	push	dx
	;
	; The top-left corner is at:
	;	(bounds.left + lrMargin), (bounds.top + tbMargin)
	;
	; NOTE: We do not translate by VTI_leftOffset because one line
	;	text objects are handled specially
	;
	mov	ax, ds:[si].VI_bounds.R_left	; ax <- X translation
	add	al, ds:[si].VTI_lrMargin
	adc	ah, 0
	
	;
	; Sign-extend the X translation.
	;
	cwd					; dx.ax <- X translation
	mov_tr	cx, ax
	mov	bx, dx				; bx.cx <- X translation

	clr	bx				
	mov	ax, ds:[si].VI_bounds.R_top
	add	al, ds:[si].VTI_tbMargin
	adc	ah, 0
	cwd					; dx.ax <- Y translation

	xchg	bx, dx				; dx.cx <- X  &  bx.ax <- Y
	call	GrApplyTranslationDWord		; Apply the translation

	; now set the clip rectangle

	pop	dx
	test	dl, mask DF_PRINT
	jnz	noSetClip
	call	SmallSetClip
noSetClip:
	.leave
	ret
SmallRegionTransformGState	endp

SmallSetClip	proc	far
	class	VisTextClass

	mov	cx, ds:[si].VI_bounds.R_right
	sub	cx, ds:[si].VI_bounds.R_left
	clr	ax
	mov	al, ds:[si].VTI_lrMargin
	shl	ax
	sub	cx, ax

	mov	dx, ds:[si].VI_bounds.R_bottom
	sub	dx, ds:[si].VI_bounds.R_top
	mov	al, ds:[si].VTI_tbMargin
	shl	ax
	sub	dx, ax

	clr	ax
	clr	bx
	mov	si, PCT_REPLACE			; Replace old clip rect
	call	GrSetClipRect
	ret
SmallSetClip	endp


TextFixed	ends
