COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textCalc.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name			Description
	----			-----------
	InvalidateRange		Invalidate a range of lines
	TextRangeChanged	Signal that a range of text has changed
	MarkRangeChanged	Mark a range of lines as having changed
	SendUpdateShowSelection	Queue a text-update and display the cursor
	TextCompleteRecalc	Completely recalculate a text object
	TextRecalc		Recalculate only what needs recalculating
	FindLineToCalcFrom	Find the line to calculate from

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 6/89	Initial revision

DESCRIPTION:
	Routines for handling recalculation for the text object.

	$Id: textCalc.asm,v 1.1 97/04/07 11:17:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Text segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCompleteRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a complete recalc of the text object.

CALLED BY:	VisTextNotifyGeometryValid, VisTextRecalcAndDraw,
		VisTextEnableDocObj
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCompleteRecalc	proc	far
	call	Text_PushAll

	sub	sp, size VisTextRange		; Create a stack frame
	mov	bp, sp				; ss:bp <- frame ptr

	clr	ax
	clrdw	ss:[bp].VTR_start, ax
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END

	clrdw	bxdi				; Start on this line
	movdw	dxax, -1			; dx.ax <- # chars inserted

	call	TextRecalc

	add	sp, size VisTextRange		; Restore stack

	Text_PopAll_ret
TextCompleteRecalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextInvalidateRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate a range of the object.

CALLED BY:	via MSG_VIS_TEXT_INVALIDATE_RANGE
PASS:		*ds:si	= Instance ptr
		dx:bp	= Range to invalidate
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextInvalidateRange	method dynamic	VisTextClass,
						MSG_VIS_TEXT_INVALIDATE_RANGE

	ProfilePoint 0
if ERROR_CHECK
	;
	; Validate that the region is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, dx							>
FXIP<	mov	si, bp							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	call	TextGStateCreate	

	
	movdw	esdi, dxbp			; es:di <- source range

	;
	; Allocate the stack frame
	;
	sub	sp, size VisTextRange		; Allocate frame
	mov	bp, sp				; ss:bp <- stack frame
	
	;
	; Copy the range.
	;
	movdw	ss:[bp].VTR_start, es:[di].VTR_start, ax
	movdw	ss:[bp].VTR_end,   es:[di].VTR_end,   ax

	;
	; Convert the range to something meaningful
	;
	clr	bx				; No context
	call	TA_GetTextRange			; Convert range

	; find the first line

	movdw	dxax, ss:[bp].VTR_start
	stc
	call	TL_LineFromOffset		; bx.di = line

	;
	; Figure the number of characters affected
	;
	movdw	dxax, ss:[bp].VTR_end		; dx.ax <- range affected
	subdw	dxax, ss:[bp].VTR_start

	call	TextRecalc			; Do the recalc/invalidate
	
	;
	; Force an update, and redisplay the selection.
	;
	call	TextSendUpdate			; Send an update.
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	clr	bp
	call	TextCallShowSelection		; Else show cursor.

	add	sp, size VisTextRange		; Restore the stack

	call	TextGStateDestroy
	ProfilePoint 29
	ret

VisTextInvalidateRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate line information.

CALLED BY:	UTILITY
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextRange w/ VTR_start containing the start of
			  the affected range
		dx.ax	= Number of characters after VTR_start which need
			  to be recalculated
		bx.di	= Line on which change occurred
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/23/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRecalc	proc	far
	uses	ax, bx, cx, dx, bp, es
	.enter
	ProfilePoint 4
	;
	; dx.ax	= # of affected characters after the change position
	; bx.di	= line on which change occurred
	; ss:bp	= VisTextRange containing range of text that changed
	;
	call	TextCheckCanCalcWithRange
	jc	quit				; quit if we can't calculate

	; at this point we need to ensure that we have enough stack space
	; this involves saving the VisTextRange so that we can copy it to
	; the new stack

	mov	cx, size VisTextRange
	push	cx
	call	SwitchStackWithData		;trashes es

	mov	cx, bx				; cx <- line.high

	sub	sp, size LICL_vars		; Allocate stack frame
	mov	bx, sp				; ss:bx <- LICL_vars

	adddw	dxax, ss:[bp].VTR_start		; dx.ax <- end of change
	movdw	ss:[bx].LICL_range.VTR_end, dxax

	movdw	ss:[bx].LICL_range.VTR_start, ss:[bp].VTR_start, ax

	call	TextRecalcInternal		; Fill in LICL_vars

	add	sp, size LICL_vars		; Restore stack

	mov	cx, di
	pop	di
	add	sp, size VisTextRange
	call	ThreadReturnStackSpace
	mov	di, cx

quit:
	ProfilePoint 5
	.leave
	ret
TextRecalc	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SwitchStackWithData

DESCRIPTION:	Switch stacks and copy data between them

CALLED BY:	INTERNAL

PASS:
	ss:bp - data to copy to dgroup
	pushed on stack - data size to copy

RETURN:
	on stack - stack space token

DESTROYED:
	es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/14/92		Initial version

------------------------------------------------------------------------------@
SwitchStackWithData	proc	far

	; get exclusive access

	push	ax
	mov	ax, segment stackSwitchSem
	mov	es, ax
	pop	ax
	PSem	es, stackSwitchSem

	popdw	es:[stackSwitchReturn]		;get return address
	pop	es:[stackSwitchDataSize]
	mov	es:[stackSwitchDI], di

	; copy data to our buffer

	push	cx, si, ds
	mov	cx, es:[stackSwitchDataSize]	; cx = size
	mov	di, offset stackSwitchBuffer	;es:di = dest
	segmov	ds, ss				;ds:si = source
	mov	si, bp
	rep	movsb
	pop	cx, si, ds

	mov	di, 1200			; stack space needed
	call	ThreadBorrowStackSpace		; di = token

	; allocate new stack space

	sub	sp, es:[stackSwitchDataSize]
	mov	bp, sp
	push	di				;save token on stack

	pushdw	es:[stackSwitchReturn]

	push	cx, si, ds
	segmov	ds, es
	mov	cx, ds:[stackSwitchDataSize]
	mov	si, offset stackSwitchBuffer	;ds:si = source
	segmov	es, ss				;es:di = dest
	mov	di, bp
	rep	movsb
	mov	di, ds:[stackSwitchDI]		; recover token
	VSem	ds, stackSwitchSem
	pop	cx, si, ds

	ret

SwitchStackWithData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextRecalcInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalc, assuming LICL_vars and range is available.

CALLED BY:	TextRecalc, TextReplace
PASS:		*ds:si	= Instance
		ss:bx	= Uninitialized LICL_vars w/ LICL_range set
		ss:bp	= VisTextRange
		cx.di	= First line to compute
RETURN:		LICL_vars filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	VTRP_range.VTR_start == start of inserted text
	VTRP_range.VTR_end   == end   of inserted text
		*** Note that this is different than the values passed
		    to VisTextReplaceNew. The end is *not* the end of the
		    deleted range.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRecalcInternal	proc	far
	uses	ax, bx, cx, dx, di, bp
	.enter
	;
	; Save the count of the number of characters which were deleted.
	;
	movdw	dxax, ss:[bp].VTR_end
	subdw	dxax, ss:[bp].VTR_start
	movdw	ss:[bx].LICL_charDelCount, dxax

	;
	; Save the original change position.
	;
	mov	bp, bx				; ss:bp <- LICL_vars
	mov	bx, cx				; bx.di <- line

	movdw	ss:[bp].LICL_startPos, ss:[bp].LICL_range.VTR_start, ax

	movdw	dxax, ss:[bp].LICL_range.VTR_start
	call	FindLineToCalcFrom
	movdw	ss:[bp].LICL_range.VTR_start, dxax

	;
	; *ds:si= Instance ptr
	; ss:bp	= LICL_vars
	; bx.di	= Line to calc from
	; cx	= Flags for previous line
	;
	call	CalculateObject			; Calculate this one object
	ProfilePoint 6
	.leave
	ret
TextRecalcInternal	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLineToCalcFrom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose the line to calculate from.

CALLED BY:	TextRecalc
PASS:		*ds:si	= Instance ptr
		bx.di	= Current choice for line to calc from.
		dx.ax	= Offset into text where change occurred.
RETURN:		bx.di	= Place we ought to calc from.
		dx.ax	= Start of this line.
		cx	= Flags associated with the line before the one passed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Here we do a bit of work to determine whether or not we should recalc
	the previous line too.
	Certain changes on the current line can affect the previous line:
		- Inserting a space in the first word can cause the first half
		  of the word to wrap up to the previous line.
		- Deleting characters from the first word could cause it to
		  wrap up to the previous line.
	If the line is the start of a paragraph, then nothing we could
	have done would affect the previous line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLineToCalcFrom	proc	near
	uses	bp
	.enter
	movdw	dxcx, bxdi			; Save line in dx.cx

	;
	; If the line we are on is the last line of a bordered paragraph we
	; need to start recalc'ing at the previous line. This is to handle the
	; case where we have changed the paraAttr associated with this line so
	; that the previous line now has a bottom border where before no
	; such border existed... (Hacks R Us).
	;
	;... Insert Hack Here ...
	;

	call	CheckAfterFirstWord		; Anywhere after 1st word is OK
						; dx.ax <- start of line if after
						;    first word
	jc	getPrevLineFlags

	call	TL_LinePrevious			; bx.di <- previous line
	jc	firstLine			; Branch if no previous line

	;
	; There is a previous line. Get the flags for that line.
	;
	call	TL_LineGetFlags			; ax <- prev line flags

	;
	; If the previous line does not end a paragraph then we need to 
	; calculate from that line. Otherwise we can compute from the current
	; line.
	;
	test	ax, mask LF_ENDS_PARAGRAPH
	jz	gotLineToCalcFrom		; Branch if prev no para-start
	
	;
	; The previous line does end a paragraph. We should calculate from
	; the line that was passed in.
	;
	mov	bp, cx				; dx.bp <- line passed in
	mov	cx, ax				; cx <- previous line flags

getLineStart:
	;
	; Make sure that the line we are on is marked as needing to be
	; calculated so we don't just quit before we even reach the lines
	; we really want to compute.
	;
	; dx.bp	= Line to calculate from
	; cx	= Flags for line before line to calc from
	;
	movdw	bxdi, dxbp			; bx.di <- line to calc from

	call	TL_LineToOffsetStart		; dx.ax <- calc line start

quit:
	.leave
	ret

firstLine:
	;
	; There is no previous line. We are in the first line of the object.
	; Set up some default flags for the previous line (even though there
	; isn't one).
	;
	clrdw	dxbp				; dx.bp <- line to calc from
	mov	cx, mask LF_ENDS_PARAGRAPH	; cx <- flags for prev line
	jmp	getLineStart


gotLineToCalcFrom:
	;
	; bx.di = Line to calc from.
	; This is either the line passed in or else it is the previous line.
	;
	movdw	dxbp, bxdi			; dx.bp <- line to calc from

	call	TL_LinePrevious			; bx.di <- previous line
	jc	firstLine			; Branch if no previous line

	call	TL_LineGetFlags			; ax <- prev line flags.
	mov	cx, ax				; cx <- prev line flags
	jmp	getLineStart


getPrevLineFlags:
	push	bx, di, ax			; Save passed line, offset.low
	mov	cx, mask LF_ENDS_PARAGRAPH	; Default flags
	call	TL_LinePrevious			; bx.di <- previous line
	jc	10$				; Branch if no previous line

	call	TL_LineGetFlags			; ax <- prev line flags.
	mov	cx, ax				; cx <- prev line flags
10$:
	pop	bx, di, ax			; Restore passed line, offset.low
	jmp	quit

FindLineToCalcFrom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAfterFirstWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a change in the text falls after the first
		word on a line.

CALLED BY:	FindLineToCalcFrom
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		dx.ax	= Offset into the text where change occurred
RETURN:		carry set if the change falls after the first word
		    dx.ax = Start of line
DESTROYED:	nothing (dx.ax preserved if change is in first word)

PSEUDO CODE/STRATEGY:
	Scan backwards in the text until we find a word-break
	character. If that character is after the start of the
	line then we are inserting after the first word and
	we can calculate on the current line rather than from
	the previous one.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAfterFirstWord	proc	near
	uses	cx, bp
	.enter
	;
	; dx.ax	= Position of the change
	;
	pushdw	dxax				; Save position of change

	push	bx				; Save line.high
	mov	bx, CC_WORD_WRAP_BREAK		; Find prev word-break
	call	TS_PrevCharInClass		; dx.ax <- position of break
	pop	bx				; Restore line.hight
	
	;
	; bx.di	= Line
	; dx.ax	= Position of the word-break before the change
	;
	movdw	bpcx, dxax			; bp.cx <- position of break
	call	TL_LineToOffsetStart		; dx.ax <- line start
	
	cmpdw	dxax, bpcx			; Compare line.start and break
	jbe	afterFirstWord

	popdw	dxax				; Restore position of change
	clc					; Signal: in first word
quit:
	.leave
	ret

afterFirstWord:
	add	sp, 2 * size word		; Restore stack
	stc					; Signal: after first word
	jmp	quit
CheckAfterFirstWord	endp

Text	ends
