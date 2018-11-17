COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		rulerHoriz.asm
FILE:		rulerHoriz.asm

AUTHOR:		Gene Anderson, Sep 23, 1991

ROUTINES:
	Name				Description
	----				-----------
	DrawHorizontalRuler		Draw horizontal ruler
	DrawColumnDividingLine		Draw dividing line for column
	DrawColumnHeader		Draw header for column

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/23/91		Initial revision

DESCRIPTION:
	code for SpreadsheetRulerClass

	$Id: rulerHoriz.asm,v 1.1 97/04/07 11:13:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHorizontalRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a horizontal ruler
CALLED BY:	SpreadsheetRulerDraw()

PASS:		di - handle of GState
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawHorizontalRuler	proc	far
winBounds	local	RectDWord
	.enter

	call	RulerScreenSetup
	;
	; Apply a translation in the GState so we can draw
	;
	movdw	dxcx, ss:winBounds.RD_left
	clr	ax, bx				;bx:ax <- y translation
	call	GrApplyTranslationDWord
	subdw	ss:winBounds.RD_bottom, dxcx
	;
	; Scale the ruler offset into document coords
	;
	call	RulerScaleWinToDocCoords	;scale me jesus
	call	GetRulerOrigin			;bx:ax <- origin
	subdw	dxcx, bxax
	;
	; Get start column to draw
	;
	push	ax				;save ruler origin
	push	bp
	mov	ax, MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
	call	CallSpreadsheet			;ax <- column #
	pop	bp
	clr	cx
	pop	bx				;bx.cx <- offset
columnLoop:
	;
	; Get the width of the current column
	;
	push	ax
	push	cx
	mov_tr	cx, ax				;cx <- column #
	mov	ax, MSG_SPREADSHEET_GET_COLUMN_WIDTH
	call	CallSpreadsheet
	mov_tr	ax, cx				;ax <- column #
	cmp	dx, -1				;does column exist?
	je	endRuler			;branch if no such column
	push	ax
	mov	cx, dx				;cx <- integer column width
	clr	ax, dx				;dx:cx.ax <- column width
	call	RulerScaleDocToWinCoords
	mov	dx, cx
	mov_tr	cx, ax				;dx.cx <- scaled width
	pop	ax
	;
	; Format and draw the column header
	;
	call	DrawColumnDividingLine
	call	DrawColumnLabel
	;
	; Update the x position (integer)
	;
	pop	ax				;ax <- current fraction
	add	cx, ax
	adc	bx, dx				;bx.cx <- new x position
	pop	ax
	inc	ax				;ax <- next column
	cmp	bx, ss:winBounds.RD_right.low
	jbe	columnLoop			;loop until right edge
endLoop:

	.leave
	ret

	;
	; End of the line -- draw the last dividing line
endRuler:
	pop	ax				;clean up stack
	call	DrawColumnDividingLine
	jmp	endLoop
DrawHorizontalRuler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawColumnDividingLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the dividing line for a column header
CALLED BY:	DrawHorizontalRuler()

PASS:		di - handle of GState
		dx - width of column (window coordinates)
		bx - current x position (window coordinates)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawColumnDividingLine	proc	near
	uses	ax, dx
	.enter

	mov_tr	ax, bx				;ax <- left x position
	clr	bx				;bx <- y1
ifdef GPC
	push	ax, bx, cx
	call	VisGetBounds			;dx = bottom
	inc	dx
	pop	ax, bx, cx
else
	mov	dx, VIS_RULER_HEIGHT+1		;dx <- y2
endif
	call	GrDrawVLine
	mov_tr	bx, ax				;bx <- left x position

	.leave
	ret
DrawColumnDividingLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawColumnLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a column header
CALLED BY:	DrawHorizontalRuler()

PASS:		di - handle of GState
		ax - column #
		dx - width of column (window coordinates)
		bx - current x position (window coordinates)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(size JustifyTextParams) eq 8>

DrawColumnLabel	proc	far
	uses	ax, bx, cx, dx, ds, es, si
	.enter

	tst	dx				;column hidden?
	jz	done				;branch if hidden

	;
	; Format the column number
	;
	segmov	ds, ss, cx
	mov	es, cx
	mov	cx, MAX_REFERENCE_SIZE		;cx <- size of buffer
	sub	sp, cx				;make space for text
	mov	si, sp				;ds:si <- ptr to text buffer
	xchg	si, di				;es:di <- ptr to text buffer
	call	ParserFormatColumnReference
	xchg	si, di				;ds:si <- ptr to text buffer
	;
	; Draw the formatted column number, centered
	;
	clr	ax
	push	ax				;JTP_width
	push	ax				;JTP_yPos
	add	dx, bx				;dx <- right edge
	push	dx				;JTP_rightX
	push	bx				;JTP_leftX
	mov	bx, sp				;ss:bx <- JustifyTextParams
	clr	cx				;cx <- NULL-terminated text
	mov	dl, J_CENTER			;dl <- Justification
	call	GrJustifyText
	;
	; Clean up the stack
	;
	add	sp, (size JustifyTextParams)+MAX_REFERENCE_SIZE
done:
	.leave
	ret
DrawColumnLabel	endp

RulerCode	ends

RulerPrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintHorizontalRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	print a range of a horizontal ruler
CALLED BY:	SpreadsheetRulerDrawRange()

PASS:		*ds:si - ruler object

		ss:bp - ptr to SpreadsheetDrawParams
			SDP_gstate - handle of GState
			SDP_range - range of cells to draw
			SDP_translation - translation to draw area
RETURN:		none
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: the GState is assumed to have been already translated such that
		the upper left of the drawing area is now at (0,0).
	NOTE: the GState is assumed to have been scaled appropriately for
		scale and scale-to-fit options.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintHorizontalRuler	proc	far
	uses	ax, di, si
	.enter
	;
	; Do common setup for printing, including
	;
	call	RulerPrintSetup			;do common setup
	clr	ax, bx, cx			;bx.ax <- y translation
	mov	dx, SPREADSHEET_RULER_WIDTH	;dx.cx <- x translation
	call	GrApplyTranslation
	;
	; Draw the range
	;
	clr	bx				;bx <- x position
	mov	ax, ss:[bp].SDP_range.CR_start.CR_column
columnLoop:
	push	ax
	mov_tr	cx, ax				;cx <- column #
	mov	ax, MSG_SPREADSHEET_GET_COLUMN_WIDTH
	call	CallSpreadsheet
	pop	ax
EC <	cmp	dx, -1				;does column exist?>
EC <	ERROR_E	RULER_BAD_COLUMN		;>
	call	PrintColumnHeader
	call	UpdateXPosition
	inc	ax				;ax <- next column
	cmp	ax, ss:[bp].SDP_range.CR_end.CR_column	;at the end yet?
	jbe	columnLoop
	;
	; We did a GrSaveState at the start because we have mucked with
	; the settings in the GState.  Restore the saved state now...
	;
	call	GrRestoreState			;restore GState
	.leave
	ret
PrintHorizontalRuler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateXPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the x position and ensure a legal coordinate
CALLED BY:	SpreadsheetHorizRulerDrawRange()

PASS:		bx - current x position
		dx - width of column
		di - handle of GState
RETURN:		bx - new x position
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateXPosition	proc	near
	.enter

	clr	cx
	add	bx, dx				;add column width
	adc	cx, 0				;propgate to high word
	jcxz	checkLargest
doTranslate:
	push	ax, bx
	mov	dx, cx
	mov	cx, bx				;dx:cx <- x translation
	clr	bx, ax				;bx:ax <- y translation
	call	GrApplyTranslationDWord
	pop	ax, bx
	jmp	xOK

checkLargest:
	cmp	bx, LARGEST_POSITIVE_COORDINATE	;too big?
	jae	doTranslate			;branch if small enough

xOK:
	.leave
	ret
UpdateXPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintColumnHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a column header for printout
CALLED BY:	SpreadsheetHorizRulerDrawRange()

PASS:		di - handle of GState
		ax - column #
		dx - width of column (window coordinates)
		bx - current x position (window coordinates)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintColumnHeader	proc	near
	uses	ax, bx, cx, dx
	.enter

	call	DrawColumnLabel			;draw the label
	;
	; Draw a rectangle around the label
	;
	mov_tr	ax, bx				;ax <- left
	clr	bx				;bx <- top
	mov	cx, ax
	add	cx, dx				;cx <- right
	mov	dx, SPREADSHEET_RULER_HEIGHT	;dx <- bottom
	call	GrDrawRect

	.leave
	ret
PrintColumnHeader	endp

RulerPrintCode	ends
