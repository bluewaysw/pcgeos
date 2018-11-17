COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		rulerMethods.asm

AUTHOR:		Gene Anderson, Jul  1, 1991

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/ 1/91		Initial revision

DESCRIPTION:
	Miscellaneous methods for VisRuler class.

	$Id: rulerMethods.asm,v 1.1 97/04/07 10:43:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerGetConstrainStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_GET_CONSTRAIN_STRATEGY

Pass:		*ds:si = ds:di = VisRuler instance

Return:		cx = VisRulerConstrainStrategy

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	26 may 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerGetConstrainStrategy	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_GET_CONSTRAIN_STRATEGY
	.enter

	mov	cx, ds:[di].VRI_constrainStrategy

	.leave
	ret
VisRulerGetConstrainStrategy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetConstrainStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_CONSTRAIN_STRATEGY

Pass:		*ds:si = ds:di = VisRuler instance
		cx = VisRulerConstrainStrategy bits to set
		dx = VisRulerConstrainStrategy bits to clear

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetConstrainStrategy	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_SET_CONSTRAIN_STRATEGY
	.enter

	ornf	ds:[di].VRI_constrainStrategy, cx
	not	dx
	andnf	ds:[di].VRI_constrainStrategy, dx
	not	dx

	.leave
	ret
VisRulerSetConstrainStrategy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle relocation and unrelocation of an object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of VisRulerClass

		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	
		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		In the most common uses of the ruler, it is in
		a document and the content it is under is not.
		So if the ruler is being relocated after
		being read from a file, it needs to clear
		its parent linkage.
		


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerReloc	method dynamic VisRulerClass, reloc
	.enter

	cmp	dx,VMRT_RELOCATE_AFTER_READ
	jne	done

	clr	ax
	mov	ds:[di].VI_link.LP_next.handle,ax
	mov	ds:[di].VI_link.LP_next.chunk,ax
	mov	ds:[di].VRI_window,ax
	mov	ds:[di].VRI_transformGState,ax
	clrdw	ds:[di].VRI_invalOD,ax
	andnf	ds:[di].VI_attrs,not mask VA_REALIZED

done:
	Destroy	ax,cx,dx

	.leave
	mov	di, offset VisRulerClass
	call	ObjRelocOrUnRelocSuper
	ret
VisRulerReloc		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_OPEN

Pass:		*ds:si - VisRuler object
		ds:di - VisRuler instance
		es - segment of VisRulerClass

		bp - window handle

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerVisOpen		method dynamic	VisRulerClass, MSG_VIS_OPEN

	mov	ds:[di].VRI_window, bp

	mov	di, offset VisRulerClass
	call	ObjCallSuperNoLock
	ret
VisRulerVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_ORIGIN

Pass:		dx:cx.bp - origin

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 25, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetOrigin	method	dynamic	VisRulerClass, MSG_VIS_RULER_SET_ORIGIN
	cmpdwf	ds:[di].VRI_origin, dxcxbp
	jz	done
	movdwf	ds:[di].VRI_origin, dxcxbp
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	done
	call	InvalRuler

	call	RulerSendInvalADIfGridShowing
done:
	ret
VisRulerSetOrigin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerGetOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_GET_ORIGIN

Pass:		nothing

Return:		dx:cx.bp - origin

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 25, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerGetOrigin	method	dynamic	VisRulerClass, MSG_VIS_RULER_GET_ORIGIN
	movdwf	dxcxbp, ds:[di].VRI_origin
	ret
VisRulerGetOrigin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerShowMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SHOW_MOUSE

		Sets a bit indicating that the ruler should draw the mouse
		tick whenever it gets a ptr event

Pass:		nothing

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerShowMouse	method	dynamic	VisRulerClass, MSG_VIS_RULER_SHOW_MOUSE
	.enter

	BitSet	ds:[di].VRI_rulerAttrs, VRA_SHOW_MOUSE

	.leave
	ret
VisRulerShowMouse	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerHideMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_HIDE_MOUSE

		Sets a bit indicating that the ruler shouldn't draw the mouse
		tick whenever it gets a ptr event

Pass:		nothing

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerHideMouse	method	dynamic	VisRulerClass, MSG_VIS_RULER_HIDE_MOUSE
	.enter

	BitClr	ds:[di].VRI_rulerAttrs, VRA_SHOW_MOUSE

	.leave
	ret
VisRulerHideMouse	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the ruler
CALLED BY:	UTILITY

PASS:		*ds:si - VisRuler object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvalRuler	proc	near
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret
InvalRuler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RulerSendInvalAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Ruler sends its inval message to its inval object.

Pass:		*ds:si = VisRuler

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerSendInvalAD	proc	far
	class	VisRulerClass
	uses	ax, bx, di, si

	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	mov	bx, ds:[di].VRI_invalOD.handle
	tst	bx
	jz	done
	mov	si, ds:[di].VRI_invalOD.chunk
	mov	ax, MSG_VIS_INVALIDATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
RulerSendInvalAD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RulerSendInvalADIfGridShowing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Ruler sends its inval message to its inval object.

Pass:		*ds:si = VisRuler

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerSendInvalADIfGridShowing	proc	far
	class	VisRulerClass
	uses	ax, bx, di, si

	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_GRID
	jz	done

	mov	ax, ds:[di].VRI_grid.G_x.WWF_int
	or	ax, ds:[di].VRI_grid.G_x.WWF_frac
	or	ax, ds:[di].VRI_grid.G_y.WWF_int
	or	ax, ds:[di].VRI_grid.G_y.WWF_frac
	jz	done

	call	RulerSendInvalAD

done:
	.leave
	ret
RulerSendInvalADIfGridShowing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RulerCallSlave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sends a message to slave ruler, if any

Pass:		*ds:si = VisRuler
		ax = message #
		cx, dx, bp = data

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerCallSlave	proc	far
	class	VisRulerClass
	uses	bx, si, di

	.enter

	;
	;	Check for existence of slave
	;
	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	mov	bx, ds:[si].VRI_slave.handle
	tst	bx
	jz	done

	;
	;	Slave exists, so send message
	;
	mov	si, ds:[si].VRI_slave.offset
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
done:
	.leave
	ret
RulerCallSlave	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerInvalidateWithSlaves
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_INVALIDATE_WITH_SLAVES

	Invalidates the ruler and its slave. This is provided 'cause
	if this were done via MSG_VIS_INVALIDATE, multiple invalidations
	would pile up for the slave on other messages that also call
	MSG_VIS_INVALIDATE.

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerInvalidateWithSlaves	method dynamic	VisRulerClass,
				MSG_VIS_RULER_INVALIDATE_WITH_SLAVES
	.enter

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_INVALIDATE_WITH_SLAVES
	call	RulerCallSlave	

	.leave
	ret
VisRulerInvalidateWithSlaves	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the ruler window.
CALLED BY:	MSG_VIS_INVALIDATE

PASS:		*ds:si - instance data
		es - seg addr of VisRulerClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerInvalidate	method dynamic VisRulerClass, MSG_VIS_INVALIDATE

winBounds	local	RectDWord
	;
	; invalidate everything
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	quit				;do nothing if not realized

	.enter

	call	CreateGState
	segmov	ds, ss
	lea	si, ds:winBounds		;ds:si <- ptr to buffer
	call	GrGetWinBoundsDWord
	call	GrInvalRectDWord
	call	DestroyGState

	.leave
quit:
	ret
VisRulerInvalidate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_REFERENCE

Context:	Called before caller wants to send a
		MSG_VIS_RULER_SNAP_RELATIVE_TO_REFEREN

Source:		

Destination:	a VisRuler with reference functionality (VisRuler will be
		separated into a purely visual ruler, with a subclass that
		does constrain/grids/etc. This method is for the latter).

Pass:		ss:bp = PointDWFixed reference

Return:		nothing

Destroyed:	ds, es, si, di, cx

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 15, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetReference	method	dynamic	VisRulerClass, MSG_VIS_RULER_SET_REFERENCE
	add	di, offset VRI_reference
	call	SetInstancePointCommon
	ret
VisRulerSetReference	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SetInstancePointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Copies a PointDWFixed from ss:bp to ds:di

Context:	

Source:		

Destination:	

Pass:		ss:bp - source PointDWFixed
		ds:di - dest PointDWFixed

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetInstancePointCommon	proc	near
	uses	ds, es, si, cx
	.enter
	;
	;	Copy the point at ss:[bp] into our instance data
	;
	;					;total bytes = 14
	push	ds				;1
	push	ss				;1
	pop	ds				;1
	pop	es				;1
	mov	si, bp				;2
CheckHack	<(size PointDWFixed AND 1) eq 0>
	mov	cx, size PointDWFixed / 2	;3
	rep	movsw				;2
	.leave
	ret
SetInstancePointCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the type of the ruler
CALLED BY:	MSG_VIS_RULER_SET_TYPE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method

		cl - RulerType

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetType	method dynamic VisRulerClass, MSG_VIS_RULER_SET_TYPE
	cmp	cl, ds:[di].VRI_type
	je	done				;branch if no change

	call	ObjMarkDirty

	mov	ds:[di].VRI_type, cl
	call	InvalRuler

	call	RulerCallSlave

	mov	ax, MSG_VIS_RULER_UPDATE_TYPE_CONTROLLER
	call	ObjCallInstanceNoLock

done:
	ret
VisRulerSetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerSetIgnoreOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "ignore origin" state
CALLED BY:	MSG_VIS_RULER_SET_IGNORE_ORIGIN

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method

		cx - non-zero to ignore the origin

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetIgnoreOrigin	method dynamic VisRulerClass,
					MSG_VIS_RULER_SET_IGNORE_ORIGIN

	mov	al, ds:[di].VRI_rulerAttrs
	jcxz	clear
	or	al, mask VRA_IGNORE_ORIGIN
	jmp	common
clear:
	and	al, not mask VRA_IGNORE_ORIGIN
common:
	cmp	al, ds:[di].VRI_rulerAttrs
	jz	done
	mov	ds:[di].VRI_rulerAttrs, al

	call	InvalRuler

	call	RulerCallSlave

	mov	ax, MSG_VIS_RULER_UPDATE_CONTROLLERS
	call	ObjCallInstanceNoLock
done:
	ret
VisRulerSetIgnoreOrigin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type of the ruler
CALLED BY:	MSG_VIS_RULER_GET_TYPE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method

RETURN:		cl - RulerType

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisRulerGetType	method dynamic VisRulerClass, MSG_VIS_RULER_GET_TYPE
	mov	cl, ds:[di].VRI_type
	ret
VisRulerGetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerGetDesiredSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_GET_DESIRED_SIZE
		Returns the position at which to draw the dividing line for
		the ruler.

Subclassing:	This method should be subclassed if the subclassed ruler's size
		needs to vary w/respect to scale factor, whether the ruler is
		horizontal or vertical, etc., etc., or simply some other
		constant than DIVIDING_LINE_POS.

Context:	Called when drawing something inside the ruler that depends on
		the position of the dividing line.

Source:		VisRulerDraw, for one.

Destination:	Any VisRuler object

Pass:		ds:si = VisRuler object
		ds:di = *ds:si = VisRuler instance

Return:		cx = preferred size

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 31, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerGetDesiredSize	method	dynamic	VisRulerClass, MSG_VIS_RULER_GET_DESIRED_SIZE
	mov	cx, ds:[di].VRI_desiredSize
	ret
VisRulerGetDesiredSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerSetMinIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	MSG_VIS_RULER_SET_MIN_INCREMENT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method

		cl - MinIncrementType

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisRulerSetMinIncrement		method dynamic VisRulerClass,
				MSG_VIS_RULER_SET_MIN_INCREMENT
	cmp	cl, ds:[di].VRI_minIncrement
	je	done				;branch if no change
	mov	ds:[di].VRI_minIncrement, cl
	call	InvalRuler
done:
	ret
VisRulerSetMinIncrement	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerSetScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the scale factor for a ruler
CALLED BY:	MSG_VIS_RULER_SET_SCALE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method
		ss:bp	- ScaleChangedParams
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version
	jon	10 Oct 1991	Overhaul
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerViewScaleFactorChanged	method dynamic	VisRulerClass, 
				MSG_VIS_RULER_VIEW_SCALE_FACTOR_CHANGED

	;
	;	Save ScaleChangedParams ptr
	;
	push	bp

	;
	;	We're gonna point bp at the WWFixed that we're interested in
	;	(either PF_x or PF_y). Let's check this ugly hack will
	;	work.
	;
CheckHack <offset SCP_scaleFactor eq 0>
CheckHack <offset PF_x eq 0>

	;
	;	If we're a horizontal ruler, bp is already pointing at PF_x
	;
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	setScale

	;
	;	We want to point bp to PF_y
	;
	add	bp, offset PF_y

	;
	;	Store our new scale factor and redraw
	;
setScale:
	mov	bx, ss:[bp].WWF_int
	mov	ds:[di].VRI_scale.WWF_int, bx
	mov	bx, ss:[bp].WWF_frac
	mov	ds:[di].VRI_scale.WWF_frac, bx
	pop	bp

	call	InvalRuler
	ret
VisRulerViewScaleFactorChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerSetScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the scale factor for a ruler
CALLED BY:	MSG_VIS_RULER_SET_SCALE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method

		dx.cx - scale factor (WWFixed)
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisRulerSetScale	method dynamic VisRulerClass, MSG_VIS_RULER_SET_SCALE
	mov	ds:[di].VRI_scale.WWF_frac, cx
	mov	ds:[di].VRI_scale.WWF_int, dx
	call	InvalRuler
	ret
VisRulerSetScale	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckScrollAmount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if scroll amount is small enough for WinScroll()
CALLED BY:	VisHorizRulerSetOffset(), VisVertRulerSetOffset()

PASS:		dx:cx - scroll amount (sdword)
RETURN:		carry - set if large scroll
		z flag - zet if no scroll
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/ 9/91		Initial version
	jon	10 Oct 1991	optimized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
CheckScrollAmount	proc	near
	tst	dx
	je	checkSmallPositive
	cmp	dx, -1
	jne	bigScroll
	cmp	cx, MIN_COORD
	jb	done				;jb = jc, so no need to jmp
						;to bigScroll
	jmp	doScroll
checkSmallPositive:
	cmp	cx, MAX_COORD
	ja	bigScroll
doScroll:
	tst	cx				;clears carry; sets z flag if 0
done:
	ret

bigScroll:
	stc					;carry <- too big for WinScroll
	ret
CheckScrollAmount	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWinOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current offset of the Window
CALLED BY:	VisVertRulerSetOffset(), VisHorizRulerSetOffset()

PASS:		*ds:si - VisRuler object
		bx - offset of bound:
		    RD_left - get x offset
		      =or=
		    RD_top - get y offset
RETURN:		bx:ax - x offset of Window (sdword)
		  =or=
		bx:ax - y offset of Window (sdword)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
GetWinOffset	proc	near
	uses	ds, si, di
winBounds	local	RectDWord
	.enter

	;
	; Get the window bounds
	;
	call	CreateGState
	segmov	ds, ss
	lea	si, ss:winBounds		;ds:si <- ptr to RectDWord
	call	GrGetWinBoundsDWord
	call	DestroyGState
	;
	; Return the offset requested...
	;
	mov	ax, ds:[si][bx].low
	mov	bx, ds:[si][bx].high

	.leave
	ret
GetWinOffset	endp
endif

RulerBasicCode	ends
