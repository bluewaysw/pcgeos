COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ruler
FILE:		rulerDraw.asm

AUTHOR:		Gene Anderson, Jun 14, 1991

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/14/91		Initial revision
	jon	Oct 91		Revised for 32 bit documents

DESCRIPTION:
	Drawing routines for visual ruler object

	$Id: rulerDraw.asm,v 1.1 97/04/07 10:43:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerSetupCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do common setup for vertical or horizontal rulers
CALLED BY:	VisHorizRulerDraw(), VisVertRulerDraw()

PASS:		*ds:si - VisRuler object
		di - handle of GState
		ss:bp - inherited RulerLocals
RETURN:		ss:bp - inherited RulerLocals
			RL_minTick - minimum tick size to draw
			RL_winBounds - bounds of Window
			RL_curInverval - current interval #
			RL_curOffset - current drawing offset
			RL_lastTextOffset - end of last tick number
			RL_tickSize - size of each minor tick
			RL_intervalValue - value for major tick
			RL_intervalMin - minimum interval to label
			RL_intervalMult - current interval multiple
			RL_prefSize - preferred height of a horizontal ruler,
					or width of vertical ruler
		cs:bx - ptr to RulerScale entry to use
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	V2.0 CHANGE: deal with translating 32-bit coordinate to 16-bit
	drawable space and calculating corresponding starting offset
	for drawing.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerSetupCommon	proc	near
	class	VisRulerClass
	uses	ax, cx, dx, si, di
rulerLocals	local	RulerLocals
	.enter	inherit

	;
	;  clear the line width
	;
	clr	ax, dx
	call	GrSetLineWidth

	;
	;	save the gstate
	;
	mov	ss:rulerLocals.RL_gstate, di

	push	ds, si
	;
	; See if there is anything to draw
	;
	segmov	ds, ss
	lea	si, ss:rulerLocals

CheckHack <offset RL_winBounds eq 0>

	call	GrGetWinBoundsDWord

	pop	ds, si

	;
	; Set the line color for drawing tick marks, et al.
	;
	mov	ax, C_BLACK
	call	GrSetLineColor
	;
	; Set the font for drawing the measurement units
	;
	mov	cx, RULER_FONT			;cx <- FontID
	mov	dx, RULER_POINTSIZE
	clr	ax				;dx.ah <- pointsize (WBFixed)
	call	GrSetFont

	;
	;  clear the line width
	;
	cwd					;clear dx
	call	GrSetLineWidth

	;
	; Scale the tick size
	;
	call	GetRulerTable			;cs:bx <- ptr to RulerScale
	clr	dx				;dx:cx.ax <- point to scale
	mov	ax, cs:[bx].RS_intervalValue
	mov	ss:rulerLocals.RL_intervalValue, ax
	mov	cx, cs:[bx].RS_tickSize.WWF_int
	mov	ax, cs:[bx].RS_tickSize.WWF_frac
	call	RulerScaleDocToWinCoords	;scale me jesus
	mov	ss:rulerLocals.RL_tickSize.WWF_frac, ax
	mov	ss:rulerLocals.RL_tickSize.WWF_int, cx
	call	SetMinTick			;dl <- minimum tick
	mov	ss:rulerLocals.RL_minTick, dl	;save minimum tick size
	mov	ss:rulerLocals.RL_intervalMin, ax
	mov	ss:rulerLocals.RL_intervalMult, ax

	;
	;	Scale the offset by the view factor and use it as the
	;	offset
	;
	push	bx
	clrdwf	dxcxax				;transform 0
	call	RulerTransformDocToWin
	movdwf	ss:rulerLocals.RL_origin, dxcxax
	pop	bx

	mov	ax, MSG_VIS_RULER_GET_DESIRED_SIZE
	call	ObjCallInstanceNoLock
	mov	ss:rulerLocals.RL_prefSize, cx

	.leave
	ret
RulerSetupCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatTickNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format number for major tick (inch, centimeter, 100 points)
CALLED BY:	DrawHorizTickNumber(), DrawVertTickNumber()

PASS:		ss:bp - inherited RulerLocals
			RL_curInterval - # of current major tick
RETURN:		ss:bp - inherited RulerLocals
			RL_buffer - ASCII string for number
		carry clear:
			draw interval label
		carry set:
			don't draw label
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatTickNumber	proc	near
	uses	ax, cx, dx, di, es
rulerLocals	local	RulerLocals
	.enter	inherit

	mov	ax, ss:rulerLocals.RL_intervalMult
	cmp	ax, ss:rulerLocals.RL_intervalMin
	mov	ax, ss:rulerLocals.RL_intervalValue
	jb	noDraw				;branch if too small

	;
	;	Check to see if text would overlap. If so, don't draw.
	;
	add	cx, ss:rulerLocals.RL_curOffset.WWF_int
	sub	cx, MINIMUM_POINTS_BETWEEN_TICK_NUMBERS
	cmp	cx, ss:rulerLocals.RL_lastTextOffset	;overlap?
	jl	noDraw

	mov	ss:rulerLocals.RL_intervalMult, ax

	segmov	es, ss
	lea	di, ss:rulerLocals.RL_buffer	;es:di <- ptr to buffer
	mov	cx, mask UHTAF_NULL_TERMINATE	;cx <- UtilHextToAsciiFlags
	mov	dx, ss:rulerLocals.RL_curInterval.high
	mov	ax, ss:rulerLocals.RL_curInterval.low
	tst	dx
	js	negate
write:
	call	UtilHex32ToAscii
	clc					;carry clear <- draw me
done:
	.leave
	ret

noDraw:
	add	ss:rulerLocals.RL_intervalMult, ax
	stc					;carry set <- don't draw me
	jmp	done

negate:
	;
	;	dx:ax is a negative number.
	;	get the absolute value for UtilHex32ToAscii
	;
	negdw	dxax
	jmp	write
FormatTickNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHorizRulerDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a horizontal ruler
CALLED BY:	METHOD_DRAW

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	V2.0 CHANGE: 32-bit window bounds!
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

rulerTables	nptr \
	inchScaleTable,				;VRT_INCHES
	metricScaleTable,			;VRT_CENTIMETERS
	pointsScaleTable,			;VRT_POINTS
	picasScaleTable				;VRT_PICAS

VisRulerDraw	method dynamic VisRulerClass, MSG_VIS_DRAW

	;
	; Should we draw?  If this is a custom ruler, presumably
	; there exists a subclass of VisRulerType which is doing
	; its own special drawing.
	;
	cmp	ds:[di].VRI_type, VRT_NONE
	jz	done
	cmp	ds:[di].VRI_type, VRT_CUSTOM
	jz	done

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	doItHere

	;
	;	Ruler is vertically oriented, so 
	call	VisVertRulerDraw
done:
	ret

doItHere:
	mov	di, bp				;di <- handle of GState

	uses	ds, si, ax

rulerLocals	local	RulerLocals

	.enter

	;
	; Do common setup
	;
	call	RulerSetupCommon
	push	bx				;save table index

	;
	;	bx:ax <- points/interval
	;
	mov	ax, ss:rulerLocals.RL_tickSize.WWF_int
	mov	cx, cs:[bx].RS_numTicks
	mul	cx
	mov_tr	bx, ax

	mov	ax, ss:rulerLocals.RL_tickSize.WWF_frac
	mul	cx
	add	bx, dx

	;
	;	dx:cx <- left edge of window (in points)
	;
	movdwf	dxcxdi, ss:rulerLocals.RL_origin
	rnddwf	dxcxdi
	negdw	dxcx
	adddw	dxcx, ss:rulerLocals.RL_winBounds.RD_left

	;
	;	dx:cx <- interval # that contains the left edge of the window
	;

	call	GrSDivWWFixed
	decdw	dxcx					;what the hell

;afterLeftCorrect:
	;
	;	scale the current interval by the interval value to
	;	get the interval value at the left eddge of the screen
	;
	push	dx, cx, ax				;save # of intervals,
							;points/interval frac
	tst	dx
	jns	doMul
	negdw	dxcx
doMul:
	push	dx					;save #vals high
	mov	ax, ss:rulerLocals.RL_intervalValue
	xchg	ax, cx					;cx <- interval value,
							;ax <- #vals low
	mul	cx

	movdw	ss:rulerLocals.RL_curInterval, dxax

	pop	ax					;ax <- #vals high
	mul	cx

	add	ss:rulerLocals.RL_curInterval.high, ax

	pop	di, dx, ax				;dx:cx <- # intervals,
							;ax <- points/intval f
	tst	di
	jns	doneMul

	negdw	ss:rulerLocals.RL_curInterval
doneMul:

	;
	;	calculate document location to begin drawing first tick
	;
	;	di:dx.cx <- # of intervals
	;	si:bx.ax <- points/interval
	;
	clr	cx, si

	;
	;	dx:cx.bx <- document location to begin drawing
	;
	call	GrMulDWFixed

	adddwf	dxcxbx, ss:rulerLocals.RL_origin

	mov	ss:rulerLocals.RL_curOffset.WWF_frac, bx

	push	cx					;save location int.low

	;
	;	dx:cx <- center of window
	;
	movdw	dxcx, ss:rulerLocals.RL_winBounds.RD_right
	adddw	dxcx, ss:rulerLocals.RL_winBounds.RD_left
	sardw	dxcx

	;
	;	Apply a translation to the center of the window
	;
	clr	ax, bx
	mov	di, ss:rulerLocals.RL_gstate
	call	GrSaveState
	call	GrApplyTranslationDWord

	pop	ax					;bx,ax <- location.low
	
	sub	ax, cx
	mov	ss:rulerLocals.RL_curOffset.WWF_int, ax

	sub	ax, MINIMUM_POINTS_BETWEEN_TICK_NUMBERS
	mov	ss:rulerLocals.RL_lastTextOffset, ax

	;
	; draw bottom dividing line
	;
	mov	ax, ss:rulerLocals.RL_winBounds.RD_left.low
	mov	cx, ss:rulerLocals.RL_winBounds.RD_right.low
	sub	cx, ax
	shr	cx
	inc	cx
	mov	ss:rulerLocals.RL_winBounds.RD_right.low, cx
	mov	ax, cx
	neg	ax
	mov	bx, ss:rulerLocals.RL_prefSize
	call	GrDrawHLine
	pop	bx				;bx <- table index

	;
	; Draw major tick intervals until the right side of the window
	;
	mov	cx, cs:[bx].RS_numTicks		;cx <- # of entries in table
	mov	bx, cs:[bx].RS_table		;cx:bx <- ptr to RulerTick table
pointLoop:
	call	DrawHorizTickIncrement
	mov	dx, ss:rulerLocals.RL_intervalValue
	add	ss:rulerLocals.RL_curInterval.low, dx
	adc	ss:rulerLocals.RL_curInterval.high, 0

	cmp	ax, ss:rulerLocals.RL_winBounds.RD_right.low
	jle	pointLoop			;branch while more to draw

	call	GrRestoreState

	.leave

	;
	;	Draw in our guidelines
	;
	mov	ax, MSG_VIS_RULER_DRAW_GUIDE_INDICATORS
	call	ObjCallInstanceNoLock

	;
	;	Draw in our mouse tick
	;

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisRuler_offset
	test	ds:[bx].VRI_rulerAttrs, mask VRA_SHOW_MOUSE
	LONG jz	done

	call	GrSaveState
	push	bp
	sub	sp, size DWFixed
	mov	bp, sp
	movdw	ss:[bp].DWF_int, ds:[bx].VRI_mouseMark, ax

	;
	;  Store an offscreen value in VRI_mouseMark so that when drawn,
	;  nothing'll happen. This'll get fixed up in DrawHorizMouseTickCommon
	;

	mov	ax, -30000
	movdw	ds:[bx].VRI_mouseMark, axax

	clr	ss:[bp].DWF_frac
	stc					; already scaled
	call	DrawHorizMouseTickCommon
	add	sp, size DWFixed
	pop	bp
	call	GrRestoreState
	jmp	done
VisRulerDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHorizTickIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw ticks for one increment (1 inch, 1 mm, 100 points)
CALLED BY:	VisHorizRulerDraw()

PASS:		di - gstate handle
		cs:bx - ptr to RulerTick table
		cx - # of entries in RulerTick table
		ss:bp - inherited RulerLocals
			RL_curInterval - interval #
			RL_curOffset - offset to draw interval
			RL_intervalSize - size of interval (WWFixed)
			RL_tickSize - size of each minor tick
			RL_minTick - minimum tick size to draw
RETURN:		ax - last x postion drawn
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawHorizTickIncrement	proc	near
	uses	bx, cx, si
	class	VisRulerClass
rulerLocals	local	RulerLocals
	.enter	inherit

	;
	; Draw number for increment
	;
	push	bx
	mov	ax, ss:rulerLocals.RL_curOffset.WWF_int
	mov	bx, ss:rulerLocals.RL_curOffset.WWF_frac
	rndwwf	axbx				;ax <- rounded x position
	clr	bx				;bx <- y position
	call	DrawHorizTickNumber
	pop	bx
	;
	; Draw one major interval
	;
	mov	dl, ss:rulerLocals.RL_minTick	;dl <- minimum tick size
tickLoop:
	cmp	cs:[bx].RT_increment, dl	;large enough to draw?
	jb	nextTick			;branch if too small
	push	bx, dx
	mov	ax, ss:rulerLocals.RL_curOffset.WWF_int
	mov	dx, ss:rulerLocals.RL_curOffset.WWF_frac
	rndwwf	axdx				;ax <- rounded x position
	mov	dx, ss:rulerLocals.RL_prefSize
	push	dx
	sub	dl, cs:[bx].RT_height
	sbb	dh, 0				;dx <- top of tick
	pop	bx
	call	GrDrawVLine
	pop	bx, dx
nextTick:
	add	bx, (size RulerTick)		;bx <- next tick entry
	push	ax
	mov	ax, ss:rulerLocals.RL_tickSize.WWF_frac
	add	ss:rulerLocals.RL_curOffset.WWF_frac, ax
	mov	ax, ss:rulerLocals.RL_tickSize.WWF_int
	adc	ss:rulerLocals.RL_curOffset.WWF_int, ax
	pop	ax
	loop	tickLoop			;loop while more ticks

	.leave
	ret
DrawHorizTickIncrement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHorizTickNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw tick number for horizontal ruler
CALLED BY:	DrawHorizTickIncrement()

PASS:		di - handle of GState
		ax - x position
		bx - y position
		ss:bp - inherited RulerLocals
			RL_curInterval - # of current major tick
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawHorizTickNumber	proc	near
	uses	ds, si, ax, bx, cx, dx
rulerLocals	local	RulerLocals
	.enter	inherit

	mov	cx, INCREMENT_X_INSET
	call	FormatTickNumber
	jc	done				;branch if not drawing

	segmov	ds, ss
	lea	si, ss:rulerLocals.RL_buffer	;ds:si <- ptr to text

	add	ax, cx
	add	bx, INCREMENT_Y_INSET
	clr	cx				;cx <- NULL-terminated
	call	GrDrawText
	dec	cx				;cx <- ffffh = max chars checkd
	call	GrTextWidth
	add	ax, dx
	mov	ss:rulerLocals.RL_lastTextOffset, ax
done:
	.leave
	ret
DrawHorizTickNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisVertRulerDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a vertical ruler
CALLED BY:	METHOD_DRAW

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of VisRulerClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	V2.0 CHANGE: 32-bit window bounds!
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisVertRulerDraw	proc	near
	class	VisRulerClass

rulerLocals	local	RulerLocals

	;
	; Should we draw?  If this is a custom ruler, presumably
	; there exists a subclass of VisRulerType which is doing
	; its own special drawing.
	;
	mov	di, bp				;di <- handle of GState
	.enter

	push	si

	;
	; Do common setup
	;
	call	RulerSetupCommon
	push	bx				;save table index

	;
	;	bx:ax <- points/interval
	;
	mov	ax, ss:rulerLocals.RL_tickSize.WWF_int
	mov	cx, cs:[bx].RS_numTicks
	mul	cx
	mov_tr	bx, ax

	mov	ax, ss:rulerLocals.RL_tickSize.WWF_frac
	mul	cx
	add	bx, dx

	;
	;	dx:cx <- top edge of window (in points)
	;
	movdwf	dxcxdi, ss:rulerLocals.RL_origin
	rnddwf	dxcxdi
	negdw	dxcx
	adddw	dxcx, ss:rulerLocals.RL_winBounds.RD_top

	;
	;	dx:cx <- interval # that contains the left edge of the window
	;

	call	GrSDivWWFixed
	decdw	dxcx					;what the hell

;afterTopCorrect:
	;
	;	scale the current interval by the interval value to
	;	get the interval value at the left eddge of the screen
	;
	push	dx, cx, ax				;save # of intervals,
							;points/interval frac
	tst	dx
	jns	doMul
	negdw	dxcx
doMul:
	push	dx					;save #vals high
	mov	ax, ss:rulerLocals.RL_intervalValue
	xchg	ax, cx					;cx <- interval value,
							;ax <- #vals low
	mul	cx

	movdw	ss:rulerLocals.RL_curInterval, dxax

	pop	ax					;ax <- #vals high
	mul	cx

	add	ss:rulerLocals.RL_curInterval.high, ax

	pop	di, dx, ax				;dx:cx <- # intervals,
							;ax <- points/intval f
	tst	di
	jns	doneMul

	negdw	ss:rulerLocals.RL_curInterval
doneMul:

	;
	;	calculate document location to begin drawing first tick
	;
	;	di:dx.cx <- # of intervals
	;	si:bx.ax <- points/interval
	;
	clr	cx, si

	;
	;	dx:cx.bx <- document location to begin drawing
	;
	call	GrMulDWFixed

	adddwf	dxcxbx, ss:rulerLocals.RL_origin

	mov	ss:rulerLocals.RL_curOffset.WWF_frac, bx

	push	cx					;save location int.low

	;
	;	dx:cx <- center of window
	;
	movdw	dxcx, ss:rulerLocals.RL_winBounds.RD_bottom
	adddw	dxcx, ss:rulerLocals.RL_winBounds.RD_top
	sardw	dxcx

	;
	;	Apply a translation to the center of the window
	;
	mov	bx, dx
	mov_tr	ax, cx
	clr	cx, dx
	mov	di, ss:rulerLocals.RL_gstate
	call	GrSaveState
	call	GrApplyTranslationDWord

	mov	dx, bx
	mov_tr	cx, ax

	pop	ax					;bx,ax <- location.low
	
	sub	ax, cx
	mov	ss:rulerLocals.RL_curOffset.WWF_int, ax

	sub	ax, MINIMUM_POINTS_BETWEEN_TICK_NUMBERS
	mov	ss:rulerLocals.RL_lastTextOffset, ax

	;
	; draw bottom dividing line
	;
	mov	bx, ss:rulerLocals.RL_winBounds.RD_top.low
	mov	dx, ss:rulerLocals.RL_winBounds.RD_bottom.low
	sub	dx, bx
	shr	dx
	inc	dx
	mov	ss:rulerLocals.RL_winBounds.RD_bottom.low, dx
	mov	bx, dx
	neg	bx
	mov	ax, ss:rulerLocals.RL_prefSize
	call	GrDrawVLine
	pop	bx				;bx <- table index

	;
	; Draw major tick intervals until the right side of the window
	;
	mov	cx, cs:[bx].RS_numTicks		;cx <- # of entries in table
	mov	bx, cs:[bx].RS_table		;cx:bx <- ptr to RulerTick table
pointLoop:
	call	DrawVertTickIncrement
	mov	dx, ss:rulerLocals.RL_intervalValue
	add	ss:rulerLocals.RL_curInterval.low, dx
	adc	ss:rulerLocals.RL_curInterval.high, 0

	cmp	ax, ss:rulerLocals.RL_winBounds.RD_bottom.low
	jle	pointLoop			;branch while more to draw

	call	GrRestoreState

	;
	;	Draw in our guidelines
	;
	pop	si
	mov	ax, MSG_VIS_RULER_DRAW_GUIDE_INDICATORS
	call	ObjCallInstanceNoLock

	;
	;	Draw in our mouse tick
	;

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisRuler_offset
	test	ds:[bx].VRI_rulerAttrs, mask VRA_SHOW_MOUSE
	jz	done

	call	GrSaveState
	push	bp
	sub	sp, size DWFixed
	mov	bp, sp
	movdw	ss:[bp].DWF_int, ds:[bx].VRI_mouseMark, ax

	;
	;  Store an offscreen value in VRI_mouseMark so that when drawn,
	;  nothing'll happen. This'll get fixed up in DrawVertMouseTickCommon
	;

	mov	ax, -30000
	movdw	ds:[bx].VRI_mouseMark, axax

	clr	ss:[bp].DWF_frac
	stc					; already scaled
	call	DrawVertMouseTickCommon
	add	sp, size DWFixed
	pop	bp
	call	GrRestoreState

done:
	.leave
	ret
VisVertRulerDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerShowMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SHOW_MOUSE

Pass:		ss:[bp] = PointDWFixed

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 15, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDrawMouseTick	method	dynamic	VisRulerClass,
			MSG_VIS_RULER_DRAW_MOUSE_TICK

	uses	cx, dx, bp
	.enter

	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_MOUSE
	jz	done

	mov	di, bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	xchg	di, bp

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisRuler_offset
	test	ds:[bx].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	doItHere

	add	bp, offset PDF_y
	clc				; not scaled yet
	call	DrawVertMouseTickCommon
	sub	bp, offset PDF_y

checkSlave:
	call	GrDestroyState
	mov	ax, MSG_VIS_RULER_DRAW_MOUSE_TICK
	call	RulerCallSlave
done:
	.leave
	ret

doItHere:
	clc				; not scaled yet
	call	DrawHorizMouseTickCommon
	jmp	checkSlave
VisRulerDrawMouseTick	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHorizMouseTickCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Draws a little tick in the gstate at the passed location

Pass:		*ds:si - VisRuler
		ss:[bp] - DWFixed location
		di - gstate
		carry set if ss:[bp] already accounts for scale
		carry clear if not

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHorizMouseTickCommon	proc	near
	class	VisRulerClass
	uses	ax, bx, cx, dx, bp, di, es
	.enter

	mov_tr	ax, di				;ax <- gstate

	movdw	dxcx, ss:[bp].DWF_int
	mov	bx, ss:[bp].DWF_frac
	jc	alreadyScaled

	push	si
	segmov	es, ss

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	add	si, offset VRI_scale
	mov	di, bp

	call	MulWWFbyDWF
	pop	si

alreadyScaled:
	rnddwf	dxcxbx

	push	dx, cx

	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	xchg	dx, ds:[di].VRI_mouseMark.high
	xchg	cx, ds:[di].VRI_mouseMark.low

	push	dx, cx
	
	mov_tr	di, ax				;di <- gstate

	mov	al, MM_INVERT
	call	GrSetMixMode

	mov	al, SDM_50
	call	GrSetLineMask

	clr	ax, dx
	call	GrSetLineWidth

	pop	dx, cx
	clr	ax
	clr	bx
	call	GrSaveState
	call	GrApplyTranslationDWord

	mov	ax, MSG_VIS_RULER_GET_DESIRED_SIZE
	call	ObjCallInstanceNoLock

	clr	ax
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bx, ds:[bx].VI_bounds.R_top	
	mov	dx, bx
	add	dx, cx
	call	GrDrawVLine
	call	GrRestoreState

	mov	bp, cx					;save size in bp
	pop	dx, cx
	clr	ax
	clr	bx
	call	GrApplyTranslationDWord

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bx, ds:[bx].VI_bounds.R_top	
	mov	dx, bx
	add	dx, bp
	call	GrDrawVLine

	.leave
	ret
DrawHorizMouseTickCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawVertMouseTickCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Draws a little tick in the gstate at the passed location

Pass:		*ds:si - VisRuler
		ss:[bp] - DWFixed location
		di - gstate
		carry set if ss:[bp] already accounts for scale
		carry clear if not

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 21, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawVertMouseTickCommon		proc	near
	class	VisRulerClass
	uses	ax, bx, cx, dx, bp, di, es
	.enter

	mov_tr	ax, di				;ax <- gstate

	movdw	dxcx, ss:[bp].DWF_int
	mov	bx, ss:[bp].DWF_frac
	jc	alreadyScaled

	push	si
	segmov	es, ss

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	add	si, offset VRI_scale
	mov	di, bp

	call	MulWWFbyDWF
	pop	si

alreadyScaled:
	rnddwf	dxcxbx

	push	dx, cx

	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	xchg	dx, ds:[di].VRI_mouseMark.high
	xchg	cx, ds:[di].VRI_mouseMark.low

	push	dx, cx
	
	mov_tr	di, ax					;di <- gstate

	mov	al, MM_INVERT
	call	GrSetMixMode

	mov	al, SDM_50
	call	GrSetLineMask

	clr	ax, dx
	call	GrSetLineWidth

	pop	bx, ax
	clr	cx
	clr	dx
	call	GrSaveState
	call	GrApplyTranslationDWord

	mov	ax, MSG_VIS_RULER_GET_DESIRED_SIZE
	call	ObjCallInstanceNoLock

	mov	bp, cx					;save size in bp
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	ax, ds:[bx].VI_bounds.R_left
	mov	dx, ax
	xchg	cx, dx					;cx = left, dx = width
	add	cx, dx					;cx = right
	clr	bx
	call	GrDrawHLine
	call	GrRestoreState

	pop	bx, ax
	clr	dx
	clr	cx
	call	GrApplyTranslationDWord

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	ax, ds:[bx].VI_bounds.R_left
	mov	cx, ax
	add	cx, bp
	clr	bx
	call	GrDrawHLine

	.leave
	ret
DrawVertMouseTickCommon	endp

MulWWFbyDWF	proc	far
		uses	ds, si, ax
temp		local	DWFixed
		.enter

		mov	ax, ds:[si].WWF_int
		mov	temp.DWF_int.low, ax
		cwd
		mov	temp.DWF_int.high, dx
		mov	ax, ds:[si].WWF_frac	; load up temp
		mov	temp.DWF_frac, ax
		segmov	ds, ss, si
		lea	si, temp
		call	GrMulDWFixedPtr

		.leave
		ret
MulWWFbyDWF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawVertTickIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw ticks for one increment (1 inch, 1 mm, 100 points)
CALLED BY:	VisVertRulerDraw()

PASS:		cs:bx - ptr to RulerTick table
		cx - # of entries in RulerTick table
		ss:bp - inherited RulerLocals
			RL_curInterval - interval #
			RL_curOffset - offset to draw interval
			RL_intervalSize - size of interval (WWFixed)
			RL_tickSize - size of each minor tick (WWFixed)
			RL_minTick - minimum tick size to draw
RETURN:		ax - last y postion drawn
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawVertTickIncrement	proc	near
	uses	bx, cx, si
	class	VisRulerClass
rulerLocals	local	RulerLocals
	.enter	inherit

	;
	; Draw number for increment
	;
	push	bx
	mov	bx, ss:rulerLocals.RL_curOffset.WWF_int
	mov	ax, ss:rulerLocals.RL_curOffset.WWF_frac
	rndwwf	bxax				;bx <- rounded y position
	clr	ax				;ax <- x position
	call	DrawVertTickNumber
	pop	bx
	;
	; Draw one major interval
	;
	mov	dl, ss:rulerLocals.RL_minTick	;dl <- minimum tick size
tickLoop:
	cmp	cs:[bx].RT_increment, dl	;large enough to draw?
	jb	nextTick			;branch if too small
	push	bx, cx
	mov	ax, ss:rulerLocals.RL_curOffset.WWF_int
	mov	cx, ss:rulerLocals.RL_curOffset.WWF_frac
	rndwwf	axcx				;ax <- rounded y position
	push	ax
	mov	ax, ss:rulerLocals.RL_prefSize
	mov	cx, ax				;cx <- right of tick
	sub	al, cs:[bx].RT_height
	sbb	ah, 0				;ax <- left of tick
	pop	bx				;bx <- y position
	call	GrDrawHLine
	mov	ax, bx				;ax <- y position drawn
	pop	bx, cx
nextTick:
	add	bx, (size RulerTick)		;bx <- next tick entry
	push	ax
	mov	ax, ss:rulerLocals.RL_tickSize.WWF_frac
	add	ss:rulerLocals.RL_curOffset.WWF_frac, ax
	mov	ax, ss:rulerLocals.RL_tickSize.WWF_int
	adc	ss:rulerLocals.RL_curOffset.WWF_int, ax
	pop	ax
	loop	tickLoop			;loop while more ticks

	.leave
	ret
DrawVertTickIncrement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawVertTickNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw tick number for vertical ruler
CALLED BY:	DrawVertTickIncrement()

PASS:		di - handle of GState
		ax - x position
		bx - y position
		ss:bp - inherited RulerLocals
			RL_curInterval - # of current major tick
RETURN:		bx - y position of end of string
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawVertTickNumber	proc	near
	uses	si, ax, cx, dx
rulerLocals	local	RulerLocals
	.enter	inherit

	mov	cx, INCREMENT_Y_INSET
	call	FormatTickNumber
	jc	done				;branch if not drawing

	lea	si, ss:rulerLocals.RL_buffer	;ss:si <- ptr to text
	add	ax, INCREMENT_X_INSET
	add	bx, cx
SBCS <	clr	dh				;dh <- high byte of char >
charLoop:
	LocalGetChar dx, sssi, NO_ADVANCE	;dx <- char of string
	LocalIsNull dx
	jz	recordOffset				;branch if NULL
	call	GrDrawChar
	LocalNextChar sssi			;ss:si <- ptr to next char
	add	bx, RULER_POINTSIZE		;bx <- next y position
	jmp	charLoop

recordOffset:
	mov	ss:rulerLocals.RL_lastTextOffset, bx
done:
	.leave
	ret
DrawVertTickNumber	endp

RulerBasicCode	ends
