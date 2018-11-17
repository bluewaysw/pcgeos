COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KLib/Graphics/RegionAppl
FILE:		graphicsRegionAppl.asm

AUTHOR:		Gene Anderson, Apr  6, 1990

ROUTINES:
	Name			Description
	----			-----------
EXT	LibRegionCalcComplex	Generate a scaled/rotated clip region
INT	ScaleRectRegion		Scale a rectangular region
INT	RotateRectRegion	Rotate a rectangular region

EXT	LibGSSetClipRect	Output opcode & data for clip rect GString

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/ 6/90		Initial revision

DESCRIPTION:
	Routines for dealing with application clip regions.
	
	$Id: graphicsRegionAppl.asm,v 1.1 97/04/05 01:12:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0

GraphicsRegionAppl segment Resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibRegionCalcComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a scaled and/or rotated region.

CALLED BY:	UpdateAppClip()

PASS:		ES	= Segment address of GState
		DS	= Segment address of Window
		CL	= WinGrFlags for region
		CH	= TransFlags for corresponding TMatrix

RETURN:		DS, ES	= Segment address of Window (may have moved)
		DS:[W_appReg] - transformed region
			- or -
		DS:[W_docReg] - transformed region
		AL	= WinGrRegFlags for region

DESTROYED:	AH, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibRegionCalcComplex	proc	far
transRoutine	local	nptr.routine
sourceRect	local	lptr.Region
destRegion	local	lptr.Region
visBounds	local	Rectangle
	.enter

	push	cx

	test	cl, mask WGRF_APP_VALID		;doc or app?
	jnz	isAppReg			;branch if app
	mov	transRoutine, offset DoWinTrans
;;;	mov	ax, es:GS_docRect		;ax <- ^l(source rectangle)
	mov	bx, ds:W_docReg			;bx <- ^l(dest region)
afterSetup:
	mov	sourceRect, ax
	mov	destRegion, bx

	mov	si, ds:[W_visReg]
	mov	si, ds:[si]			;ds:si <- ptr to vis region
	cmp	ds:[si], EOREGREC		;any visible region?
	je	noVisRegion
	push	cx
	call	GrGetPtrRegBounds		;get bounds of visible region
	dec	bx
	mov	visBounds.R_left, ax
	mov	visBounds.R_top, bx 
	mov	visBounds.R_right, cx
	mov	visBounds.R_bottom, dx
	pop	ax				;ah <- TransFlags for TMatrix

	test	ah, TM_ROTATED			;rotated or scaled?
	jnz	rotated
	;
	; The Window and GState are only scaled. We only need to
	; transform (scale) the bounds to make a new rectanglular
	; region.
	;
	call	ScaleRectRegion			;scale me jesus
	jc	noVisRegion			;branch if NULL region
done:
	pop	ax				;al <- WinGrRegFlags

	.leave
	ret

isAppReg:
	mov	transRoutine, offset DoFullTrans
;;;	mov	ax, es:GS_appRect		;ax <- ^l(source rectangle)
	mov	bx, ds:W_appReg			;bx <- ^l(dest region)
	jmp	afterSetup

rotated:
	;
	; The Window and/or the GState are rotated. We need to transform
	; the bounds and generate an arbitrary clip region from the appl
	; clip region.
	;
	call	RotateRectRegion		;rotate me jesus
	jnc	done				;branch if region created

	;
	; The visible region is NULL. Since our regions are clipped
	; to that region (to keep the size reasonable), our regions
	; will be NULL, too. We always leave space for rectangular
	; region, since that is the most common case (the text
	; object uses it like you wouldn't believe) and just mark
	; it as a NULL region.
	;
noVisRegion:
	mov	ax, destRegion			;^lds:ax <- region chunk
	mov	di, ax
	mov	cx, size RectRegion		;cx <- size (in bytes)
	call	LMemReAlloc
	mov	di, ds:[di]			;ds:di <- ptr to region chunk
	mov	ds:[di].RR_y1M1, EOREGREC	;indicate no region
	segmov	es, ds				;ds,es <- seg addr of Window
	jmp	done
LibRegionCalcComplex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoWinTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a point by the Window transform only.
CALLED BY:	ScaleRectRegion(), RotateRectRegion()

PASS:		(ax,bx) - point to transform
		es - seg addr of Window
RETURN:		(ax,bx) - transformed point
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoWinTrans	proc	near
	uses	ds
	.enter

	segmov	ds, es				;ds <- seg addr of Window
	call	WinTransCoordFar		;transform me jesus

	.leave
	ret
DoWinTrans	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFullTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a point by both the GState and Window transforms.
CALLED BY:	ScaleRectRegion(), RotateRectRegion()

PASS:		(ax,bx) - point to transform
		es - seg addr of Window
RETURN:		(ax,bx) - transformed point
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoFullTrans	proc	near
	.enter

	call	GrTransCoordFar			;transform me jesus

	.leave
	ret
DoFullTrans	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleRectRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does scale for rectangular application clip region
CALLED BY:	LibRegionCalcComplex

PASS:		ds - seg addr of Window
		es - seg addr of GState
		inherits locals
RETURN:		ds,es - (new) seg addr of Window
		ds:W_appReg - scaled version of es:GS_appRect
			- or -
		ds:W_docReg - scaled version of es:GS_docRect
		carry - set if NULL region
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleRectRegion	proc	near
transRoutine	local	nptr.routine
sourceRect	local	lptr.Region
destRegion	local	lptr.Region
visBounds	local	Rectangle
	.enter	inherit

	mov	ax, destRegion			;ax <- chunk of dest
	mov	si, ax
	mov	cx, size RectRegion		;cx <- size to realloc
	call	LMemReAlloc			;resize for rectangular region
	mov	si, ds:[si]			;si <- ptr to lmem chunk
	mov	ax, EOREGREC
	mov	ds:[si].RR_eo1, ax
	mov	ds:[si].RR_eo2, ax
	mov	ds:[si].RR_eo3, ax		;stuff end of lines, region
	segxchg	ds, es				;ds <- GState, es <- Window
	mov	di, sourceRect			;di <- chunk of source rect
	mov	di, ds:[di]			;di <- ptr to app region
	mov	ax, ds:[di].RR_x2
	mov	bx, ds:[di].RR_y2		;(ax,bx) <- lower right
	call	transRoutine			;transform appropriately
	mov	cx, ax
	mov	dx, bx				;(cx,dx) <- lower right (doc)
	mov	ax, ds:[di].RR_x1
	mov	bx, ds:[di].RR_y1M1
	inc	bx				;(ax,bx) <- upper left
	call	transRoutine			;transform appropriately
	segmov	ds, es				;ds <- seg addr of Window
	;
	; Get the bounds of the visibile region, and clip
	; the application clip region to that region. This
	; is to avoid creating massive regions which leads
	; to massive Windows which leads to death...
	;
	dec	bx				;need (y1-1)
	;
	; Make sure the bounds are correctly ordered:
	;
	cmp	ax, cx				;see if left > right
	jl	xOK				;branch if ordered
	xchg	ax, cx
xOK:
	cmp	bx, dx				;see if top > bottom
	jl	yOK				;branch if ordered
	xchg	bx, dx
yOK:

	cmp	ax, visBounds.R_left		;check left bound
	jg	leftOK
	mov	ax, visBounds.R_left
leftOK:
	cmp	bx, visBounds.R_top		;check top bound
	jg	topOK
	mov	bx, visBounds.R_top
topOK:
	cmp	cx, visBounds.R_right		;check right bound
	jl	rightOK
	mov	cx, visBounds.R_right
rightOK:
	cmp	dx, visBounds.R_bottom		;check bottom bound
	jl	bottomOK
	mov	dx, visBounds.R_bottom
bottomOK:
	;
	; Make sure we still have a region
	;
	cmp	bx, dx				;check top w/ bottom
	jge	nullRegion			;branch if NULL region
	cmp	ax, cx				;check right w/left
	jge	nullRegion			;branch if NULL region

	mov	ds:[si].RR_x1, ax
	mov	ds:[si].RR_y1M1, bx
	mov	ds:[si].RR_x2, cx
	mov	ds:[si].RR_y2, dx		;stuff region bounds

	clc					;<- non-NULL region
done:
	.leave
	ret

nullRegion:
	stc					;<- NULL region
	jmp	done
ScaleRectRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateRectRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does rotation for rectangular application clip region.
CALLED BY:	LibRegionCalcComplex

PASS:		ds - seg addr of Window
		es - seg addr of GState
RETURN:		ds,es - (new) seg addr of Window
		ds:W_appReg - rotated version of es:GS_appRect
			- or -
		ds:W_docReg - rotated version of es:GS_docRect
		carry - set if NULL region
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RotateRectRegion	proc	near
1transRoutine	local	nptr.routine
sourceRect	local	lptr.Region
destRegion	local	lptr.Region
visBounds	local	Rectangle
	.enter	inherit

	;
	; Get the application clip region bounds:
	;
	segxchg	ds, es				;ds <- GState, es <- Window
	mov	di, sourceRect
	mov	di, ds:[di]			;es:di <- ptr to App region
	mov	ax, ds:[di].RR_x1
	mov	bx, ds:[di].RR_y1M1
	inc	bx
	mov	cx, ds:[di].RR_x2
	mov	dx, ds:[di].RR_y2		;((ax,bx),(cx,dx) <- bounds
	push	dx, ax, dx, cx			;push lower left, lower right
	push	bx, cx, bx, ax			;push upper right, upper left
	segmov	ds, ss
	mov	si, sp				;ds:si <- ptr to bounds
	mov	di, MAX_COORD			;di <- min(y)
	mov	dx, MIN_COORD			;dx <- max(y)
	mov	cx, 4
pointLoop:
	mov	ax, ds:[si].P_x
	mov	bx, ds:[si].P_y
	call	transRoutine			;transform appropriately
	mov	ds:[si].P_x, ax
	mov	ds:[si].P_y, bx
	cmp	bx, di				;new minimum?
	jg	notMin
	mov	di, bx				;di <- min(y)
notMin:
	cmp	bx, dx				;new maximum?
	jl	notMax
	mov	dx, bx				;dx <- max(y)
notMax:
	add	si, size Point			;ptr to next point
	loop	pointLoop			;loop while more points
	;
	; Clip the application clip region to the visible region.
	; This is to avoid generating massive regions, which
	; makes massive Windows, which dies a horrible death...
	;
	cmp	di, visBounds.R_top		;check w/top of vis region
	jg	topOK
	mov	di, visBounds.R_top
topOK:
	cmp	dx, visBounds.R_bottom		;check w/bottom of vis region
	jl	bottomOK
	mov	dx, visBounds.R_bottom
bottomOK:
	;
	; Make sure we still have a region left
	;
	cmp	di, dx				;check top with bottom
	jge	nullRegion			;branch if no region left
	;
	; Open a region to rasterize the rotated clip region:
	;
	push	es				;save seg addr of Window
	push	bp				;save for stack frame
	mov	bp, di				;bp <- minimum y
	clr	di				;di <- alloc new block
	mov	cx, RFR_ODD_EVEN or (2 shl 8)	;fill rule & # def on/off points
	call	GrRegionPathInit		;es == seg addr of RegionPath
	pop	bp				;recover for stack frame
	;
	; Add the rotated rectangle as a polygon:
	;
	mov	di, sp
	add	di, size word			;ds:di <- ptr to points
	mov	cx, 4				;cx <- # of points
	call	GrRegionPathAddPolygon		;add polygon
	pop	ds				;ds <- seg addr of Window
	add	sp, (size Point)*4		;nuke bounds from stack
	;
	; Remove any unused points and duplicate lines:
	;
	call	GrRegionPathClean		;clean region (cx <- size)
	;
	; Resize the Window application clip region chunk to
	; receive the new region we've created:
	;
	mov	ax, destRegion			;ax <- lmem handle of app chunk
	mov	di, ax				;di <- lmem handle of app chunk
	sub	cx, size RegionPath		;don't need this for Window
	call	LMemReAlloc			;resize W_appReg chunk
	segxchg	ds, es				;ds <- RegionPath, es <- Window
	mov	si, size RegionPath		;ds:si <- ptr to Region
	mov	di, es:[di]			;es:di <- ptr to W_appReg chunk
	shr	cx, 1				;cx <- # of words to copy
	rep	movsw				;copy region into window
	;
	; Free the RegionPath block we used:
	;
	mov	bx, ds:RP_handle		;bx <- handle of RegionPath
	call	MemFree				;free region block
	clc					;<- non-NULL region
done:
	segmov	ds, es				;ds <- seg addr of Window

	.leave
	ret

nullRegion:
	add	sp, (size Point)*4		;nuke bounds from stack
	stc					;<- NULL region
	jmp	done
RotateRectRegion	endp

GraphicsRegionAppl ends

endif

GraphicsStringStore	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibGSSetClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write GString opcode & data for GrSet{Doc,}ClipRect()
CALLED BY:	GrSetClipRect()

PASS:		ES:BP	= SCR_inline
		DS	= Segment aaddress of GState
		DI	= Handle of GString
		SI	= PathCombineType
		AX	= Left
		BX	= Top
		CX	= Right
		DX	= Bottom

RETURN:		DI	= GState handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/27/90		Initial version
	don	7/16/91		Commenting update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibGSSetClipRect	proc	far
	uses	ax, bx, cx, si, ds
	.enter

	push	dx				; R_bottom
	push	cx				; R_right
	push	bx				; R_top
	push	ax				; R_left
	push	si				; PathCombineType
	mov	al, es:[bp].SCR_opcode		; opcode to use
	mov	si, sp
	segmov	ds, ss				; ptr to params => DS:SI
	mov	cx, size OpSetClipRect - size OSCR_opcode
	mov	ah, GSSC_FLUSH			; GStringStoreControl => AH
	call	GSStore
	add	sp, cx				; clean the stack up

	.leave
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	ret
LibGSSetClipRect	endp

GraphicsStringStore	ends

