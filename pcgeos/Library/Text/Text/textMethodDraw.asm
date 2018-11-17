COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textMethodDraw.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 6/89	Initial revision

DESCRIPTION:
	Text object drawing code.

	$Id: textMethodDraw.asm,v 1.1 97/04/07 11:18:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode segment resource

TextDraw_DerefVis_DI	proc	near
	class	VisTextClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextDraw_DerefVis_DI	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an edit object.

CALLED BY:	via MSG_VIS_DRAW
PASS:		*ds:si	= Instance ptr
		bp	= GState
		cl	= DF_EXPOSED if we are doing an update
			  DF_PRINT if printing
			  DF_OBJECT_SPECIFIC if every line should be redrawn
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12-Jun-89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDraw	method dynamic	VisTextClass, MSG_VIS_DRAW

EC <	call	ECCheckParaAttrPositions				>

	mov	di, bp				; di <- passed gstate.

	;
	; We make quite a bit of changes to the gstate (such as setting the
	; clipping region).  Therefore, we save and restore the gstate since
	; we are not supposed to muck with it.
	;
	call	GrSaveState

	;
	; For our routines to work, we must set this gstate as the gstate
	; cached with the instance.  The real cached gstate is recovered later.
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset		; ds:bx <- ptr to instance.

	push	ds:[bx].VTI_gstate		; Save gstate
	push	{word} ds:[bx].VTI_gsRefCount	; Save reference count
	push	ds:[bx].VTI_gstateRegion	; Save region

	mov	ds:[bx].VTI_gstate, di		; Use update gstate.
	andnf	ds:[bx].VTI_gsRefCount, not mask GSRCAF_REF_COUNT
	ornf	ds:[bx].VTI_gsRefCount, 1	; Don't want this one nuked.
	mov	ds:[bx].VTI_gstateRegion, -1	; No region for this gstate

	;
	; Now clear and draw it...
	;
	test	cl, mask DF_PRINT
	jnz	printing

	;
	; We must set the gstate to have all our expected defaults
	;
	call	TextInitGState

	mov	al, mask TCBF_MSG_DRAW

	test	cl, mask DF_OBJECT_SPECIFIC
	jz	5$
	or	al, mask TCBF_DRAW_ALL_LINES
5$:
	call	TextDraw
	mov	ax, MSG_VIS_TEXT_EDIT_DRAW
	call	ObjCallInstanceNoLock		; Let sub-classes do their work

	;
	; If we have a cursor on the screen, it will get redrawn by EditHilite.
	; Unfortunately EditHilite calls CursorPosition, which disables the
	; cursor (to erase it from its old position) and then re-enables it
	; in its new position. This isn't all that great, given that the cursor
	; might not even be drawn yet (first time up). What we do here is to
	; force the cursor on before calling EditHilite.
	;
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr.
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	doHilite			; Carry set if is selection.

	;
	; Force the cursor on.
	;
	call	CheckNotEditable		; ds:di = instance ptr.
	jc	common				; Skip hilite if not editable.
	call	TSL_CursorDrawIfOn		; Turn it on.
	call	TSL_DrawOverstrikeModeHilite
	jmp	common
doHilite:
	test	ds:[di].VTI_state, mask VTS_SELECTABLE
	jz	common				; Skip this if we aren't
	call	TSL_DrawHilite			;   selectable.
	jmp	common

printing:

	; if we are printing we need to check for the special case of having
	; variable graphics that need to be recalculated

	clr	cx
	test	ds:[bx].VTI_storageFlags, mask VTSF_GRAPHICS
	jz	doPrinting
	test	ds:[bx].VTI_storageFlags, mask VTSF_LARGE
	jnz	doPrinting
	call	TG_IfVariableGraphicsThenRecalc		;cx = old chunk
doPrinting:
	call	TextInitModeAndBorder
	mov	al, mask TCBF_MSG_DRAW or mask TCBF_PRINT
	call	TextDraw
	jcxz	common
	call	TG_RecalcAfterPrint

common:
	;
	; Done drawing, we must restore the old cached gstate
	;
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr.
	pop	ds:[di].VTI_gstateRegion	; Restore region
	pop	ax
	mov	ds:[di].VTI_gsRefCount,al	; Restore count (and flags)
	pop	ax				; ax = gstate
	xchg	ax,ds:[di].VTI_gstate		; Restore gstate.
	mov_trash	di, ax
	call	GrRestoreState			; Restore passed gstate.

	ret
VisTextDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextRecalcAndDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the text object and force it to redraw.

CALLED BY:	via MSG_VIS_TEXT_RECALC_AND_DRAW
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextRecalcAndDraw	method dynamic	VisTextClass, 
					MSG_VIS_TEXT_RECALC_AND_DRAW,
					MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE

	call	TextGStateCreate		; Make a gstate
	call	EditUnHilite			; Remove the cursor/selection
	call	TextCompleteRecalc		; Recalculate
	clr	ax				; No flags
	call	TextDraw			; Draw everything
	call	EditHilite			; Restore cursor/selection
	call	TextGStateDestroy		; Nuke gstate

	ret

VisTextRecalcAndDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the text.

CALLED BY:	VisTextDraw(2), VisTextRecalcAndDraw
PASS:		*ds:si	= Instance ptr
		ax	= TextClearBehindFlags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Foreach region
	    Redraw affected lines

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/23/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextDraw	proc	far

	push	di
	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

	class	VisLargeTextClass
	uses	ax, cx, dx
	.enter

	;
	; If we're printing then there's no point in checking if we *can* draw,
	; we just have to do it.
	;
	test	ax, mask TCBF_PRINT
	jnz	drawRegions
	
	;
	; We're not printing. Check to see if drawing is possible.
	;
	call	TextCheckCanDraw
	jc	quit				; Quit if we can't draw.

drawRegions:
	;
	; Draw each region
	;
	sub	sp, size TextRegionEnumParameters
	mov	bp, sp				; ss:bp <- stack frame
	
	mov	ss:[bp].TREP_flags, al
	movcb	ss:[bp].TREP_callback, TextDrawRegionCallback
	call	TR_RegionEnumRegionsInClipRect	; Do the drawing
	
	add	sp, size TextRegionEnumParameters

quit:
	.leave

	pop	di
	call	ThreadReturnStackSpace
	pop	di
	ret

TextDraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextDrawRegionCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for the region-enum code.

CALLED BY:	via TR_RegionEnumRegionsInClipRect
PASS:		*ds:si	= Instance
		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_flags
				TREP_region
				TREP_regionTopLeft
				TREP_regionHeight
				TREP_regionWidth
				TREP_regionPtr (if has a special region)
				TREP_clipRect, relative to current region
				TREP_displayMode
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextDrawRegionCallback	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter

	mov	ax, ATTR_VIS_LARGE_TEXT_ONLY_DRAW_X_REGIONS
	call	ObjVarFindData
	jnc	noLimit
	mov	ax, ds:[bx]
	cmp	ax, ss:[bp].TREP_region
	jbe	quit
noLimit:
	;
	; Transform the gstate so that all drawing is done relative to the
	; current region and set the clip region if not printing
	;
	clr	dl
	test	ss:[bp].TREP_flags, mask TCBF_PRINT
	jz	20$
	mov	dl, mask DF_PRINT
20$:
	mov	cx, ss:[bp].TREP_region		; cx <- current region
	call	TR_RegionTransformGState

	;
	; Check to see if we need to draw all the lines or if we can clip
	; the lines we draw to the current window.
	;
	test	ss:[bp].TREP_flags, mask TCBF_DRAW_ALL_LINES
	jz	useMask

	;
	; Don't use the mask, draw all lines.
	;
	call	TR_RegionGetTopLine		; bx.di <- top line of region
	call	TR_RegionGetLineCount		; cx <- # of lines
	jmp	gotLineAndCount

useMask:
	call	TextDrawCheckMask		; bx.di <- first line to draw
						; cx <- # of lines to draw
	LONG jc drawBreak

gotLineAndCount:
	;
	; We have the first line to draw and the number to draw.
	;
	; *ds:si= Instance
	; bx.di	= First line to draw
	; cx	= Number of lines to draw in this region
	; ss:bp	= TextRegionEnumParameters
	;
	; Make a stack frame for TextClearBehindLine()
	;
	mov	al, ss:[bp].TREP_flags		; ax <- TextClearBehindLineFlags
	mov	dx, ss:[bp].TREP_region		; dx <- current region

	push	bp				; Save frame ptr
	sub	sp, size LICL_vars		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	movdw	LICL_paraAttrStart,-1		; Init paragraph attributes
	mov	ss:[bp].LICL_region, dx		; Save current region
	
	push	ax, bx
	call	TL_LineToOffsetStart		; dx.ax <- start offset
	movdw	ss:[bp].LICL_lineStart, dxax

	call	TL_LineGetTop			; dx.bl <- top of line
	movwbf	ss:[bp].LICL_lineBottom, dxbl	; Save as bottom of prev line
	pop	ax, bx

	;
	; Use the calcFlags to indicate whether or not we've drawn the
	; previous line and whether or not we have already marked a
	; line as needing to be drawn because the line above it interacted
	; below...
	;
	; We haven't drawn the previous line
	;
	clr	ss:[bp].LICL_calcFlags

	;
	; Grab the flag in the instance data that says an update is pending.
	;
	push	bx				; Save line.low
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	dl, ds:[bx].VTI_intFlags	; dl <- flags
	and	dl, mask VTIF_UPDATE_PENDING	; dl <- Boolean: update pending
	pop	bx				; Restore line.low

	;
	; if printing then ignore VTIF_UPDATE_PENDING
	;
	test	ax, mask TCBF_PRINT		; Check for printing
	jz	notPrinting			; Branch if not printing
	
	;
	; We are printing. This means that the fact that an update might be
	; pending is meaningless. We clear the flag that says an update is
	; pending so that we can pretend that it isn't.
	;
	clr	dl
notPrinting:
	jcxz	endLoop				; Branch if only drawing break

;-----------------------------------------------------------------------------
lineLoop:
	;
	; *ds:si= Instance ptr
	; ss:bp	= LICL_vars
	; bx.di	= Line to draw
	; dl	= Non-zero if an update is pending
	; cx	= Number of lines left to draw
	; ax	= TextClearBehindFlags
	;

	push	bx, dx				; Save line.high, flag
	call	TL_LineGetHeight		; dx.bl <- line height
	movwbf	ss:[bp].LICL_lineHeight, dxbl	; Save line height
	pop	bx, dx				; Restore line.high, dx

	push	ax				; Save TextClearBehindFlags
	mov	ax, mask LF_NEEDS_DRAW
	call	TL_LineTestFlags		; Check for needs to be drawn
	pop	ax				; Restore TextClearBehindFlags
	jz	drawLine			; Branch if not waiting for draw

	;
	; Line has changed. If an update is pending, then don't bother drawing
	; the line, it will get drawn when the update comes in.
	;
	tst	dl				; Check for update pending
	jnz	nextLine

drawLine:
	;
	; ax	= TextClearBehindFlags
	; ss:bp	= LICL_vars
	;
	call	TL_LineDraw			; Draw the text

	or	ss:[bp].LICL_calcFlags, mask CF_HAVE_DRAWN

nextLine:
	push	ax
	;
	; Update LICL_lineStart to contain the start of the next line
	;
	call	TL_LineGetCharCount		; dx.ax <- # of chars on line
	adddw	ss:[bp].LICL_lineStart, dxax	; Update line start
	
	;
	; Update LICL_lineBottom to contain the top of the next line
	;
	addwbf	ss:[bp].LICL_lineBottom, ss:[bp].LICL_lineHeight, ax
	pop	ax

	;
	; Advance to the next line and loop to handle it.
	;
	call	TL_LineNext			; bx.di <- next line
EC <	jnc	notLastLine						>
EC <	cmp	cx, 1							>
EC <	ERROR_NZ TEXT_DRAW_BAD_LINE_NUMBER_ASSUMPTION			>
EC <notLastLine:							>
	loop	lineLoop			; Loop until done

;-----------------------------------------------------------------------------
endLoop:
	add	sp, size LICL_vars		; Restore stack
	pop	bp				; Restore local frame

	;
	; Clear the the bottom of the region (unless we are printing)
	;
drawBreak:
	test	ss:[bp].TREP_flags, mask TCBF_PRINT
	jnz	quit				; Branch if printing

	test	ss:[bp].TREP_flags, mask TCBF_MSG_DRAW
	jz	clearBehind

	call	TextDraw_DerefVis_DI		; if transparent then don't
	test	ds:[di].VTI_features, mask VTF_TRANSPARENT ;clear to bottom
	jnz	quit				; on DRAW (do for editing)

clearBehind:
	mov	cx, ss:[bp].TREP_region		; cx <- region to clear in
	call	TR_RegionClearToBottom		; Clear to bottom of region

quit:
	clc					; Signal: keep calling back
	.leave
	ret
TextDrawRegionCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the screen after an editing change.

CALLED BY:	VisTextScreenUpdate
PASS:		*ds:si = ptr to VisTextInstance.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This code uses the LICL_range field of the LICL_vars.
	This means that it cannot peacefully co-exist with the calculation
	code which also makes use of this field.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextScreenUpdate	proc	near
	call	TextCheckCanDraw
	jnc	10$
	ret
10$:

	push	di
	mov	di, 1400
	call	ThreadBorrowStackSpace
	push	di
;-----------------------------------------------------------------------------
	uses	ax, bx, cx, dx, bp
	.enter
	
	;
	; Allocate and initialize the stack frame.
	;
	sub	sp, size TextRegionEnumParameters
	mov	bp, sp				; ss:bp <- stack frame

	clr	ss:[bp].TREP_flags		; No TextClearBehindFlags
	movcb	ss:[bp].TREP_callback, TextScreenUpdateCallback

	;
	; Unhilite the selection if it's a cursor, otherwise get the range
	; of lines that the selection covers.
	;
	call	TSL_SelectGetSelection		; dx.ax <- start
						; cx.bx <- end
	jc	isRange				; If selection is a cursor
	
	;
	; The selection is not a range (it is a cursor). Rather than figuring
	; out later if we need to blink the cursor we just do it now.
	;
	; carry is clear signalling  that selection is a cursor
	;
	call	UnHiliteSavingGState		; Remove cursor
	movdw	ss:[bp].TREP_selectLines.VTR_start, -1
						; Show that unhilite is done
	jmp	afterRangeSet

isRange:
	;
	; The selection is a range. Rather than blinking it on and off (which
	; can look funny to a user) we save the range of lines which the
	; selection covers. If we go to draw one of these lines, then we remove
	; the entire selection before drawing and turn it on later.
	;
	push	bx				; Save select-end.low
	call	TL_LineFromOffset		; bx.di <- select-start line
	movdw	ss:[bp].TREP_selectLines.VTR_start, bxdi
	pop	bx				; Restore select-end.low

	movdw	dxax, cxbx			; dx.ax <- select-end offset
	call	TL_LineFromOffset		; bx.di <- select-end line
	movdw	ss:[bp].TREP_selectLines.VTR_end, bxdi

afterRangeSet:

	;
	; Update each region
	;
	call	TR_RegionEnumRegionsInClipRect	; Do the drawing
	
	;
	; Check to see if we removed the selection range. If we did then we 
	; need to replace it.
	;
	cmpdw	ss:[bp].TREP_selectLines.VTR_start, -1
	jne	noReHilite
	call	EditHilite
noReHilite:

	add	sp, size TextRegionEnumParameters

	.leave
;-----------------------------------------------------------------------------
	pop	di
	call	ThreadReturnStackSpace
	pop	di
	ret

TextScreenUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextScreenUpdateCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for range-enum

CALLED BY:	via TR_RegionEnumRegionsInClipRect
PASS:		*ds:si	= Instance
		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_flags
				TREP_region
				TREP_regionTopLeft
				TREP_regionHeight
				TREP_regionWidth
				TREP_regionPtr (if has a special region)
				TREP_clipRect, relative to current region
				TREP_displayMode
				TREP_selectLines
RETURN:		carry clear always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; We reuse some of the CalcFlags for other meanings here (since we're not
; calculating.
;
CFU_FORCE_NEXT_LINE_TO_DRAW		equ	mask CF_LINE_SHORTER

;-----------------

TextScreenUpdateCallback	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter
	;
	; Allocate LICL_vars stack frame
	;
	sub	sp, size LICL_vars		; ss:bx <- LICL_vars
	mov	bx, sp

	;
	; Copy some stuff from one stack frame to the other
	;
	mov	cx, ss:[bp].TREP_region
	mov	ss:[bx].LICL_region, cx

	;
	; Transform the gstate so that all drawing is done relative to the
	; current region.
	;
	clr	dl				; No flags
	call	TR_RegionTransformGState

	;
	; We need to know now many lines to draw and where to start drawing
	; at. TextDrawCheckMask() does that for us.
	;
	push	bx, bp				; Save frame ptrs
	call	TextDrawCheckMask		; bx.di <- first line to draw
						; cx <- Number of lines to draw
	pop	bp, dx				; ss:bp <- LICL_vars
						; ss:dx <- TREP vars
	LONG jc	quit				; Branch if no lines

	;
	; Initialize the liclVars.
	; Setting 'theParaAttrStart' to -1 signals that the paragraph attribute
	; haven't been set yet.
	;
	push	dx				; Save frame ptr
	movdw	ss:[bp].LICL_theParaAttrStart, -1
	
	call	TL_LineToOffsetStart		; dx.ax <- starting offset
	movdw	ss:[bp].LICL_lineStart, dxax	; Save start offset

	push	bx				; Save line.high
	call	TL_LineGetTop			; dx.bl <- top of line
	movwbf	ss:[bp].LICL_lineBottom, dxbl	; Save as bottom of prev line
	pop	bx				; Restore line.high
	pop	dx				; Restore frame ptr

	;
	; Use the calcFlags to indicate whether or not we've drawn the
	; previous line and whether or not we have already marked a
	; line as needing to be drawn because the line above it interacted
	; below...
	;
	; We haven't drawn the previous line
	;
	clr	ss:[bp].LICL_calcFlags
	
;-----------------------------------------------------------------------------
lineLoop:
	;
	; bx.di	 = First line to draw
	; cx	 = # of lines left to do
	; *ds:si = Instance ptr
	; ss:bp	 = LICL_vars
	; ss:dx	 = TextRegionEnumParameters
	;
	jcxz	quit

	call	GetLineHeight

	call	TL_LineGetFlags			; ax <- flags for this line
	test	ax, mask LF_NEEDS_DRAW		; Check for line needing to draw
	LONG jz	nextLine			; Branch if it doesn't need draw

	;
	; We need to draw this line, but we might also need to draw the line
	; above it, and the line below it. If the current line interacts with
	; the one above it, force it to be drawn. If it interacts with the line
	; below it, force that line to be drawn too.
	;
	test	ax, mask LF_INTERACTS_ABOVE	; Check for interacts above
	LONG jnz interactsAbove			; Branch if it does

checkInteractBelow:
	;
	; Check to see if the current line interacts with the one below it.
	; If it does we want to extend the range that we are drawing so that
	; it includes this next line.
	;
	test	ax, mask LF_INTERACTS_BELOW	; Check for interacts below
	LONG jnz interactsBelow			; Branch if it does

drawLine:
	;
	; Finally we can draw the line...
	; *ds:si= Instance ptr
	; bx.di	= Line to draw
	; ss:bp	= LICL_vars
	; ss:dx	= TextRegionEnumParameters
	;
	call	CheckUnHilite

	clr	ax				; No clearing flags
	call	TL_LineDraw			; Draw the text

	or	ss:[bp].LICL_calcFlags, mask CF_HAVE_DRAWN

nextLine:
	push	dx				; Save frame ptr
	call	TL_LineGetCharCount		; dx.ax <- # chars in line
	adddw	ss:[bp].LICL_lineStart, dxax	; Update the line-start
	pop	dx				; Restore frame ptr

	;
	; Update LICL_lineBottom to contain the top of the next line
	;
	addwbf	ss:[bp].LICL_lineBottom, ss:[bp].LICL_lineHeight, ax

	;
	; Update some greeble avoiding flags for next line
	;
	andnf	ss:[bp].LICL_calcFlags, not mask CF_FORCED_DRAW_VIA_INTERACT_BELOW
	test	ss:[bp].LICL_calcFlags, CFU_FORCE_NEXT_LINE_TO_DRAW
	jz	notForced

	andnf	ss:[bp].LICL_calcFlags, not CFU_FORCE_NEXT_LINE_TO_DRAW
	ornf	ss:[bp].LICL_calcFlags, mask CF_FORCED_DRAW_VIA_INTERACT_BELOW
notForced:

	call	TL_LineNext			; bx.di <- next line
	dec	cx
	jmp	lineLoop			; loop until done
;-----------------------------------------------------------------------------

quit:
	;
	; Restore stack
	;
	add	sp, size LICL_vars
	
	clc					; Signal: continue calling back
	.leave
	ret



interactsAbove:
	;
	; Check to see if we have already drawn a line.
	; This is the case where the line we were about to draw *does* interact
	; with the line above it, but that line has already been drawn earlier
	; in this loop.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_HAVE_DRAWN
	jnz	checkInteractBelow		; Branch if we've drawn it

	;
	; The line we are about to draw interacts with the line above it.
	;
	call	TL_LinePrevious			; bx.di <- Previous line
	jc	checkInteractBelow		; Skip if no previous line

	;
	; We have not drawn the line, we must adjust backwards to reach it
	;
	push	dx				; Save frame ptr
	call	TL_LineGetCharCount		; dx.ax <- # chars
	subdw	ss:[bp].LICL_lineStart, dxax
	inc	cx				; One more line to draw
	pop	dx				; Restore frame ptr
	
	;
	; Remove the line height and get the height of the previous line
	;
	subwbf	ss:[bp].LICL_lineBottom, ss:[bp].LICL_lineHeight, ax

	call	GetLineHeight			; Save line height

	jmp	drawLine



interactsBelow:
	;
	; The line we are about to draw interacts with the line below it.
	; We draw the next line, only if it isn't already marked as needing
	; to be drawn. If it is marked as needing to be drawn, we don't mark
	; it. 
	;
	; Also we only mark one un-marked line in this manner.
	;
	; We can do this because if a range has changed, only the fact that
	; the last line interacts with the one below it makes any difference.
	;
	; For later lines that interact below, they won't have changed and
	; therefore we don't need to draw the lines below them.
	;

	test	ss:[bp].LICL_calcFlags, mask CF_FORCED_DRAW_VIA_INTERACT_BELOW
	LONG	jnz	drawLine		; just draw since we already
						;  did this once before

	push	ax, bx, di, dx			; Save current line

	call	TL_LineNext			; bx.di <- next line
	jc	skipMarkLine			; Branch if no next line
	
	;
	; Check for next line needs redraw anyway.
	;
	call	TL_LineGetFlags			; ax <- flags for next line
	test	ax, mask LF_NEEDS_DRAW		; Check for needs draw anyway
	jnz	skipMarkLine

	;
	; We haven't done one of these, so this must be the first line
	; after the affected range. Force it to be redrawn.
	;
	mov	ax, mask LF_NEEDS_DRAW		; Bits to set
	clr	dx				; Bits to clear
	call	TL_LineAlterFlags		; Make the line draw

	or	ss:[bp].LICL_calcFlags, CFU_FORCE_NEXT_LINE_TO_DRAW
skipMarkLine:
	pop	ax, bx, di, dx			; Restore current line
	jmp	drawLine


;
; Local procedure...
;
GetLineHeight	label	near
	push	dx, bx
	call	TL_LineGetHeight		; dx.bl <- line height
	movwbf	ss:[bp].LICL_lineHeight, dxbl	; Save line height
	pop	dx, bx
	retn
TextScreenUpdateCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckUnHilite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to unhilite the selection

CALLED BY:	TextScreenUpdateCallback
PASS:		ss:dx	= TextRegionEnumParameters
RETURN:		TREP_selectLines updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckUnHilite	proc	near
	uses	bp
	.enter
	mov	bp, dx				; ss:bp <- frame ptr

	;
	; Check to find out if we need to erase the selection before continuing.
	; The cases are:
	;	- Selection has already been removed (LICL_range.VTR_start == -1)
	;		We can just draw the line.
	;	- Current line to draw is at or beyond the selection-start and
	;	  Current line to draw is at or before the selection-end
	;		We need to remove the selection hilite.
	;
	cmpdw	ss:[bp].TREP_selectLines.VTR_start, -1
	je	skipUnHilite			; Branch if unhilite already done

	cmpdw	bxdi, ss:[bp].TREP_selectLines.VTR_start
	jb	skipUnHilite			; Branch if before select-start

	cmpdw	bxdi, ss:[bp].TREP_selectLines.VTR_end 
	ja	skipUnHilite			; Branch if after select-end

	;
	; The line we are drawing is one on which there is part of the selection
	; hilite. We need to remove the hilite and mark that we have done this.
	;
	stc					; Signal selection is a range
	call	UnHiliteSavingGState		; UnHilite
	movdw	ss:[bp].TREP_selectLines.VTR_start, -1
						; Signal: unhilite was done
skipUnHilite:
	.leave
	ret
CheckUnHilite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnHiliteSavingGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the cursor/selection.

CALLED BY:	TextScreenUpdate
PASS:		*ds:si	= Instance
		carry set if selection is a range, clear if a cursor
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnHiliteSavingGState	proc	near
	class	VisTextClass
	uses	cx, di
	.enter
	pushf					; Save "is range" flag
	call	TextDraw_DerefVis_DI		; ds:di <- instance ptr
	popf					; Restore "is range" flag
	
	jc	saveAndRestore			; Branch if range
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- cursor region
	cmp	cx, ds:[di].VTI_gstateRegion	; See if region is correct
	jne	saveAndRestore			; Branch if not
	
	call	EditUnHilite			; Remove cursor/selection
quit:
	.leave
	ret

saveAndRestore:
	push	ds:[di].VTI_gstateRegion, di	; Save instance ptr, region
	
	mov	di, ds:[di].VTI_gstate		; di <- gstate
	call	GrSaveState			; Save it
	call	EditUnHilite			; Remove cursor/selection
	call	GrRestoreState			; Restore gstate

	pop	ds:[di].VTI_gstateRegion, di	; Restore instance ptr, region
	jmp	quit
	
UnHiliteSavingGState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextDrawCheckMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide what part of the object to draw.

CALLED BY:	ScrollPageUp, TextDraw, TextScreenUpdate
PASS:		*ds:si	= Instance ptr
		ss:bp	= TextRegionEnumParameters
RETURN:		bx.di	= First line to draw
		cx	= # of lines to draw
		carry set if there are no lines to draw
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextDrawCheckMask	proc	far
	uses	ax, dx
	.enter
	;
	; Allocate a RectDWord to hold the area exposed.
	;
	sub	sp, size VisTextRange		; Allocate range
	mov	bx, sp				; ss:bx <- VisTextRange

	call	TR_RegionLinesInClipRect	; Figure the range
	jc	quit				; Branch if none
	
	;
	; Get the first line and figure the count
	;
	movdw	dxcx, ss:[bx].VTR_end		; dx.cx <- last line
	movdw	axdi, ss:[bx].VTR_start		; ax.di <- first line
	subdw	dxcx, axdi			; dx.cx <- line count
	incdw	dxcx				; Make it one based

EC <	tst	dx						>
EC <	ERROR_NZ REGION_HAS_MORE_THAN_64K_LINES			>

	mov	bx, ax				; bx.di <- first line
						; cx holds the count
	clc					; Signal: has lines

quit:
	;
	; Restore the stack
	;
	lahf					; ah <- "has lines" flag
	add	sp, size VisTextRange
	sahf					; Restore "has lines" flag

	.leave
	ret
TextDrawCheckMask	endp


TextDrawCode ends
