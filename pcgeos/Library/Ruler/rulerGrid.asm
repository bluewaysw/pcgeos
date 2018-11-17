COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ruler Library
FILE:		rulerGrid.asm

AUTHOR:		Jon Witort, 14 October 1991

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	14OCT1991	Initial revision

DESCRIPTION:
	Grid-related methods for VisRuler class.

	$Id: rulerGrid.asm,v 1.1 97/04/07 10:43:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerGetStrategicGridSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_GET_STRATEGIC_GRID_SPACING

		Returns a horizontal and vertical grid spacing that will
		"look good" when drawn at the current scale factor, etc.

Pass:		*ds:si - VisRuler object
		ds:di - VisRuler instance

Return:		dx:cx - WWFixed horizontal grid spacing
		bp:ax - WWFixed vertical grid spacing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerGetStrategicGridSpacing	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_GET_STRATEGIC_GRID_SPACING,
				MSG_VIS_RULER_GET_GRID_SPACING

	movwwf	dxcx, ds:[di].VRI_grid.G_x
	movwwf	bpax, ds:[di].VRI_grid.G_y

	ret
VisRulerGetStrategicGridSpacing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerDrawGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_DRAW_GRID

Called by:	MSG_VIS_RULER_DRAW_GRID

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

		^hbp - GState

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 19, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDrawGrid	method dynamic	VisRulerClass, MSG_VIS_RULER_DRAW_GRID
	uses	cx,dx,bp
	.enter

	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_GRID
	jz	done

	mov	di, bp

	mov	ax, MSG_VIS_RULER_GET_STRATEGIC_GRID_SPACING
	call	ObjCallInstanceNoLock

	tst	dx
	jnz	drawIt
	tst	bp
	jnz	drawIt
	tst	cx
	jnz	drawIt
	tst	ax
	jz	done

drawIt:
	mov	bx, bp
	call	DrawGridWork
	
done:
	.leave
	ret
VisRulerDrawGrid	endm

RulerBasicCode	ends

RulerGridGuideConstrainCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerTurnGridSnappingOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_TURN_GRID_ON

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerTurnGridSnappingOn	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_TURN_GRID_SNAPPING_ON
	.enter

	ornf	ds:[di].VRI_constrainStrategy, \
					mask VRCS_SNAP_TO_GRID_X_ABSOLUTE or \
					mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE or \
					mask VRCS_SNAP_TO_GRID_X_RELATIVE or \
					mask VRCS_SNAP_TO_GRID_Y_RELATIVE

	mov	ax, MSG_VIS_RULER_UPDATE_GRID_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret
VisRulerTurnGridSnappingOn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerTurnGridSnappingOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_TURN_GRID_OFF

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerTurnGridSnappingOff	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_TURN_GRID_SNAPPING_OFF
	.enter

	andnf	ds:[di].VRI_constrainStrategy, \
				not (mask VRCS_SNAP_TO_GRID_X_ABSOLUTE or \
				     mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE or \
				     mask VRCS_SNAP_TO_GRID_X_RELATIVE or \
				     mask VRCS_SNAP_TO_GRID_Y_RELATIVE)

	mov	ax, MSG_VIS_RULER_UPDATE_GRID_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret
VisRulerTurnGridSnappingOff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerShowGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SHOW_GRID

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	22 mar 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerShowGrid	method	dynamic	VisRulerClass, MSG_VIS_RULER_SHOW_GRID
	.enter

	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_GRID
	pushf

	BitSet	ds:[di].VRI_rulerAttrs, VRA_SHOW_GRID

	mov	ax, MSG_VIS_RULER_UPDATE_GRID_CONTROLLER
	call	ObjCallInstanceNoLock

	popf
	jnz	done

	call	ObjMarkDirty
	call	RulerSendInvalAD

done:

	.leave
	ret
VisRulerShowGrid	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerHideGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SHOW_GRID

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	22 mar 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerHideGrid	method	dynamic	VisRulerClass, MSG_VIS_RULER_HIDE_GRID
	.enter

	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_GRID
	pushf

	BitClr	ds:[di].VRI_rulerAttrs, VRA_SHOW_GRID

	mov	ax, MSG_VIS_RULER_UPDATE_GRID_CONTROLLER
	call	ObjCallInstanceNoLock

	popf
	jz	done

	call	ObjMarkDirty
	call	RulerSendInvalAD
done:
	.leave
	ret
VisRulerHideGrid	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetGridSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_GRID_SPACING
		Sets horizontal *and* vertical grid increments to the passed
		values. If you want the horizontal and vertical spacings to
		be different, use MSG_VIS_RULER_SET_HORIZONTAL_GRID_SPACING and
		MSG_VIS_RULER_SET_VERTICAL_GRID_SPACING.

Pass:		dx:cx = WWFixed grid spacing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct  9, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetGridSpacing		method	dynamic	VisRulerClass,
				MSG_VIS_RULER_SET_GRID_SPACING

	mov	ax, MSG_VIS_RULER_SET_HORIZONTAL_GRID_SPACING
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_SET_VERTICAL_GRID_SPACING
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_UPDATE_GRID_CONTROLLER
	call	ObjCallInstanceNoLock

	call	RulerSendInvalAD

	ret
VisRulerSetGridSpacing	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetHorizontalGridSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_HORIZONTAL_GRID_SPACING
		Sets horizontal grid increments to the passed
		values. Vertical spacings are unchanged.

Pass:		dx:cx = WWFixed grid spacing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct  9, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetHorizontalGridSpacing	method	dynamic	VisRulerClass, \
				MSG_VIS_RULER_SET_HORIZONTAL_GRID_SPACING

	cmpwwf	ds:[di].VRI_grid.G_x, dxcx
	je	done

	movwwf	ds:[di].VRI_grid.G_x, dxcx
	call	ObjMarkDirty

done:
	ret
VisRulerSetHorizontalGridSpacing	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetVerticalGridSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_VERTICAL_GRID
		Sets vertical grid spacings to the passed
		values. Horizontal grid spacings are unchanged.

Pass:		dx:cx = WWFixed grid spacing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct  9, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetVerticalGridSpacing	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_SET_VERTICAL_GRID_SPACING

	cmpwwf	ds:[di].VRI_grid.G_y, dxcx
	je	done

	movwwf	ds:[di].VRI_grid.G_y, dxcx
	call	ObjMarkDirty

done:
	ret
VisRulerSetVerticalGridSpacing	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapToGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_TO_GRID

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance
		ss:bp = PointDWFixed

Return:		ss:bp = snapped PointDWFixed

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 14, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapToGrid	method	VisRulerClass, MSG_VIS_RULER_SNAP_TO_GRID
	call	VisRulerSnapToGridX
	call	VisRulerSnapToGridY
	ret
VisRulerSnapToGrid	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapToGridX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_TO_GRID_X

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance
		ss:bp = DWFixed

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapToGridX	method	VisRulerClass, MSG_VIS_RULER_SNAP_TO_GRID_X
	uses	ax, cx, dx
	.enter

	;
	;  Adjust for any offset
	;
	push	bp						;save DWF ptr
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	subOurs

	clr	cx, dx, bp
	mov	ax, MSG_VIS_RULER_GET_ORIGIN
	call	RulerCallSlave
	jmp	doSub

subOurs:
	movdwf	dxcxbp, ds:[di].VRI_origin
doSub:
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jz	noIgnore
	clrdwf	dxcxbp
noIgnore:
	mov_tr	ax, bp
	pop	bp						;bp <- DWF ptr
	push	dx, cx, ax
	subdwf	ss:[bp].PDF_x, dxcxax

	add	di, offset VRI_grid + offset G_x
	add	bp, offset PDF_x
	call	SnapCommon
	sub	bp, offset PDF_x
	sub	di, offset VRI_grid + offset G_x

	pop	dx, cx, ax
	adddwf	ss:[bp].PDF_x, dxcxax

	.leave
	ret
VisRulerSnapToGridX	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapToGridY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_TO_GRID_Y

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance
		ss:bp = DWFixed

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapToGridY	method	VisRulerClass, MSG_VIS_RULER_SNAP_TO_GRID_Y

	uses	ax, cx, dx

	.enter

	;
	;  Adjust for any offset
	;
	push	bp						;save DWF ptr
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	subOurs

	clr	cx, dx, bp
	mov	ax, MSG_VIS_RULER_GET_ORIGIN
	call	RulerCallSlave
	jmp	doSub

subOurs:
	movdwf	dxcxbp, ds:[di].VRI_origin
doSub:
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jz	noIgnore
	clrdwf	dxcxbp
noIgnore:
	mov_tr	ax, bp						;ax <- frac
	pop	bp						;bp <- DWF ptr
	push	dx, cx, ax
	subdwf	ss:[bp].PDF_y, dxcxax

	add	di, offset VRI_grid + offset G_y
	add	bp, offset PDF_y
	call	SnapCommon
	sub	bp, offset PDF_y
	sub	di, offset VRI_grid + offset G_y

	pop	dx, cx, ax
	adddwf	ss:[bp].PDF_y, dxcxax

	.leave
	ret
VisRulerSnapToGridY	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SnapCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ds:di = WWFixed grid spacing
		ss:bp = DWFixed location

Return:		ss:bp = DWFixed closest grid line

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SnapCommon	proc	near
	uses	ax, bx, cx, dx, si
	.enter
	;
	;	bx:ax <- WWFixed horizontal grid spacing
	;
	mov	bx, ds:[di].WWF_int
	mov	ax, ds:[di].WWF_frac

	;
	;	If ax = bx = 0, no grid
	;
	tst	bx
	jnz	snap
	tst	ax
	jz	done

snap:
	;
	;	Get number of grid units in point's int
	;
	push	bp
	movdwf	dxcxbp, ss:[bp]
	call	GrSDivDWFbyWWF			;dx:cx:bp <- quotient
	rnddwf	dxcxbp
	pop	bp

	;
	;	di:dx:cx <- DWFixed # grid units
	;	si:bx:ax <- DWFixed grid size
	;
	push	bx, ax				;save grid spacing

	push	di				;save instance ptr
	mov	di, dx
	mov	dx, cx
	clr	cx, si

	;
	;	dx:cx:bx <- nearest grid point towards the origin
	;
	call	GrMulDWFixed

	pop	di					;ds:di = VisRuler inst

	pop	si, ax					;si:ax <- grid spacing

	;
	;	dx:cx:bx <- passed point
	;	ss:[bp].PDF_x <- first gridline towards the origin
	;
	xchgdwf	dxcxbx, ss:[bp]

	;
	;	See if we're more than 1/2 a grid spacing from that point
	;
	subdwf	dxcxbx, ss:[bp]
	jns	gotDistance

	negwwf	cxbx

gotDistance:
		
	shl	bx
	rcl	cx
	jc	oneGridOver

	cmp	cx, si
	jb	done
	ja	oneGridOver
	cmp	bx, ax
	jbe	done

	;
	;	Take the first gridline *away* from the origin, as
	;	its closer.
	;
oneGridOver:
	clr	cx
	tst	dx
	js	negative

	adddwf	ss:[bp], cxsiax
	jmp	done

negative:
	subdwf	ss:[bp], cxsiax
done:
	.leave
	ret
SnapCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapRelativeToReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_RELATIVE_TO_REFERENCE

Pass:		ss:bp = PointDWFixed

Return:		ss:bp = PointDWFixed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 15, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapRelativeToReference	method	dynamic	VisRulerClass, MSG_VIS_RULER_SNAP_RELATIVE_TO_REFERENCE

	;
	;	Subtract the reference point from the passed point
	;
	subdwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax
	subdwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax

	;
	;	Snap our translated point to the grid
	;
	mov	ax, MSG_VIS_RULER_SNAP_TO_GRID
	call	ObjCallInstanceNoLock

	;
	;	Add the reference point from the passed point
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	adddwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax
	adddwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax
	ret
VisRulerSnapRelativeToReference	endm

VisRulerSnapRelativeToReferenceX	method	dynamic	VisRulerClass, MSG_VIS_RULER_SNAP_RELATIVE_TO_REFERENCE_X

	;
	;	Subtract the reference point from the passed point
	;
	subdwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax

	;
	;	Temporarily set the IGNORE ORIGIN bit, cause we're
	;	not doing things relative to the origin now...
	;
	push	{word} ds:[di].VRI_rulerAttrs
	BitSet	ds:[di].VRI_rulerAttrs, VRA_IGNORE_ORIGIN

	;
	;	Snap our translated point to the grid
	;
	mov	ax, MSG_VIS_RULER_SNAP_TO_GRID_X
	call	ObjCallInstanceNoLock

	;
	;	Add the reference point from the passed point
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset

	;
	;	Restore the ignore origin bit
	;
	pop	ax
	mov	ds:[di].VRI_rulerAttrs, al

	adddwf	ss:[bp].PDF_x, ds:[di].VRI_reference.PDF_x, ax
	ret
VisRulerSnapRelativeToReferenceX	endm

VisRulerSnapRelativeToReferenceY	method	dynamic	VisRulerClass, MSG_VIS_RULER_SNAP_RELATIVE_TO_REFERENCE_Y

	;
	;	Subtract the reference point from the passed point
	;
	subdwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax

	;
	;	Temporarily set the IGNORE ORIGIN bit, cause we're
	;	not doing things relative to the origin now...
	;
	push	{word} ds:[di].VRI_rulerAttrs
	BitSet	ds:[di].VRI_rulerAttrs, VRA_IGNORE_ORIGIN

	;
	;	Snap our translated point to the grid
	;
	mov	ax, MSG_VIS_RULER_SNAP_TO_GRID_Y
	call	ObjCallInstanceNoLock

	;
	;	Add the reference point from the passed point
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset

	;
	;	Restore the ignore origin bit
	;
	pop	ax
	mov	ds:[di].VRI_rulerAttrs, al

	adddwf	ss:[bp].PDF_y, ds:[di].VRI_reference.PDF_y, ax
	ret
VisRulerSnapRelativeToReferenceY	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DrawGridWork
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Does the real work of drawing the grid

Pass:		*ds:si - VisRuler
		dx:cx <- WWFixed horizontal spacing
		bx:ax <- WWFixed vertical spacing
		di - gstate

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct  9, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGridWork	proc	far
	uses	ax,cx,dx,bp

winBounds	local	RectDWord
centerWindow	local	PointDWord
topLeftGrid	local	PointDWFixed
theGState	local	hptr.GState
temp		local	word
strategicGrid	local	Grid

	.enter

	mov	theGState, di

	;
	;	Figure out the "proper" grid spacing, based on the
	;	true grid and the scale factor
	;
	;	dx:cx <- WWFixed horizontal spacing
	;	bp:ax <- WWFixed vertical spacing
	;	
	push	si				;save obj ptr

	movdw	strategicGrid.G_x, dxcx
	movdw	strategicGrid.G_y, bxax

	;
	;	es <- VisRuler segment
	;	ds:si <- winBounds
	;
	push	ds
	push	ss
	pop	ds
	pop	es
	lea	si, ss:winBounds

	;
	;	load the passed gstate's extended window bounds into
	;	winBounds
	;
	call	GrGetWinBoundsDWord

	;
	;	Find the center of the win bounds
	;
	movdw	bxax, ds:[si].RD_right
	adddw	bxax, ds:[si].RD_left
	sardw	bxax
	movdw	centerWindow.PD_x, bxax

	movdw	bxax, ds:[si].RD_bottom
	adddw	bxax, ds:[si].RD_top
	sardw	bxax
	movdw	centerWindow.PD_y, bxax

	;
	;	Find the upper-left-most grid point
	;

if 1	;  funky grid sizes caused off by one errors, so we'll cheat and
	;  take an extra grid space up & left
	;

	movdw	topLeftGrid.PDF_x.DWF_int, ds:[si].RD_left, ax
	movdw	topLeftGrid.PDF_y.DWF_int, ds:[si].RD_top, ax
	clr	ax
	mov	topLeftGrid.PDF_x.DWF_frac, ax
	mov	topLeftGrid.PDF_y.DWF_frac, ax

else
	movdw	bxax, strategicGrid.G_x
	shrdw	bxax

	mov	topLeftGrid.PDF_x.DWF_frac, ax
	mov	ax, ds:[si].RD_left.high
	add	bx, ds:[si].RD_left.low
	adc	ax, 0
	mov	topLeftGrid.PDF_x.DWF_int.low, bx
	mov	topLeftGrid.PDF_x.DWF_int.high, ax

	movdw	bxax, strategicGrid.G_y
	shrdw	bxax

	mov	topLeftGrid.PDF_y.DWF_frac, ax
	mov	ax, ds:[si].RD_top.high
	add	bx, ds:[si].RD_top.low
	adc	ax, 0
	mov	topLeftGrid.PDF_y.DWF_int.low, bx
	mov	topLeftGrid.PDF_y.DWF_int.high, ax
endif

	;
	;	*ds:[si] <= VisRuler
	;
	segmov	ds, es
	pop	si

	;
	;	ss:[bp] <= topLeftGrid
	;
	push	bp				;save local ptr
	lea	bp, ss:topLeftGrid

	;
	;	Snap topLeftGrid to the grid
	;
	mov	ax, MSG_VIS_RULER_SNAP_TO_GRID
	call	ObjCallInstanceNoLock

	pop	bp				;bp <- local ptr

	;
	;	Translate to the center of the window
	;
	mov	di, theGState
	movdw	dxcx, centerWindow.PD_x
	movdw	bxax, centerWindow.PD_y

	call	GrSaveState
	call	GrApplyTranslationDWord

	;
	;	Adjust winBounds to reflect the center
	;
	subdw	winBounds.RD_left, dxcx
	subdw	winBounds.RD_right, dxcx
	subdw	winBounds.RD_top, bxax
	subdw	winBounds.RD_bottom, bxax

	;
	;	See if our strategic horizontal grid is non zero
	;
	tst	strategicGrid.G_x.WWF_int
	jnz	drawVLines
	tst	strategicGrid.G_x.WWF_frac
	jz	tryHLines

drawVLines:
	;
	;	Find the topLeftGrid point's offset from the center of
	;	the window
	;
	mov	dx, winBounds.RD_bottom.low
	sub	dx, winBounds.RD_top.low
	mov	ss:[temp], dx				;temp = bottom - top

	;
	;	dx.cx holds current x position
	;
	mov	dx, topLeftGrid.PDF_x.DWF_int.low
	sub	dx, cx
	mov	cx, topLeftGrid.PDF_x.DWF_frac
	
	push	si					;use si for tmp in loop
	clrwwf	axsi					;ax & si should stay 0
vLoop:
	;
	;	Move to top of grid line
	;	dx.cx = X position
	;	bx.ax = Y Position (ax = 0)
	;
	mov	bx, ss:[winBounds].RD_top.low
	call	GrMoveToWWFixed
	
	;
	;	See if we're past the right side of the window yet
	;
	cmp	dx, winBounds.RD_right.low
	jg	tryHLinesPopSi

	;
	;	Okay, draw grid line from top to bottom.
	;	dx.cx = X offset = 0
	;	bx.ax = Y offset = bottom-top (ax = 0)
	;
	push	dx					;store dx.cx
	xchg	cx, si					;cx=0 (since si=0)
	clr	dx					;dx.cx = 0.0
	mov	bx, ss:[temp]
	call	GrDrawRelLineTo
	xchg	cx, si					;restore dx.cx
	pop	dx

	;
	;	Move one grid space over
	;
	adddw	dxcx, strategicGrid.G_x
	jmp	vLoop

tryHLinesPopSi:
	pop	si
	
tryHLines:
	;
	;	See if our strategic horizontal grid is non zero
	;
	tst	strategicGrid.G_y.WWF_int
	jnz	drawHLines
	tst	strategicGrid.G_y.WWF_frac
	jz	restore

drawHLines:
	;
	;	Find the topLeftGrid point's offset from the center of
	;	the window
	;
	mov	cx, winBounds.RD_right.low
	sub	cx, winBounds.RD_left.low
	mov	ss:[temp], cx				;temp = right - left

	;	
	;	bx.ax holds current y position
	;
	mov	bx, topLeftGrid.PDF_y.DWF_int.low
	sub	bx, centerWindow.PD_y.low
	mov	ax, topLeftGrid.PDF_y.DWF_frac

	push	si					;use si for tmp in loop
	clrwwf	cxsi					;cx & si should stay 0
hLoop:
	;
	;	Move to top of grid line
	;	dx.cx = X position (cx = 0)
	;	bx.ax = Y Position
	;
	mov	dx, ss:[winBounds].RD_left.low
	call	GrMoveToWWFixed

	;
	;	See if we're past the right side of the window yet
	;
	cmp	bx, winBounds.RD_bottom.low
	jg	restorePopSi

	;
	;	Okay, draw grid line from top to bottom.
	;	dx.cx = X offset = right-left (cx = 0)
	;	bx.ax = Y offset = 0
	;
	push	bx					;store bx.ax
	xchg	ax, si					;ax=0 (since si=0)
	clr	bx					;bx.ax = 0.0
	mov	dx, ss:[temp]
	call	GrDrawRelLineTo
	xchg	ax, si					;restore bx.ax
	pop	bx

	;
	;	Move one grid space over
	;
	adddw	bxax, strategicGrid.G_y
	jmp	hLoop

restorePopSi:
	pop	si
	
restore:

	call	GrRestoreState

	.leave
	ret
DrawGridWork	endp

RulerGridGuideConstrainCode	ends

