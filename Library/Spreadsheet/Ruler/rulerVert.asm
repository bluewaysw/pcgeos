COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		rulerVert.asm
FILE:		rulerVert.asm

AUTHOR:		Gene Anderson, Sep 23, 1991

ROUTINES:
	Name				Description
	----				-----------
	DrawVerticalRuler		Draw vertical spreadsheet ruler
	DrawRowDividingLine		Draw dividing line for row
	DrawRowHeader			Draw header for row

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/23/91		Initial revision

DESCRIPTION:
	code for SpreadsheetRuler class

	$Id: rulerVert.asm,v 1.1 97/04/07 11:13:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawVerticalRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle expose for drawing vertical spreadsheet ruler
CALLED BY:	Draw

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetVertRulerClass
		ax - the method

		di - handle of GState

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <ROW_HEIGHT_MAX lt 0x8000>
CheckHack <SS_COLUMN_WIDTH_MAX lt 0x8000>

DrawVerticalRuler	proc	far
winBounds	local	RectDWord
	.enter

	call	RulerScreenSetup
	;
	; Apply a translation in the GState so we can draw
	;
	movdw	bxax, ss:winBounds.RD_top
	clrdw	dxcx				;dx:cx <- x translation
	call	GrApplyTranslationDWord
	subdw	ss:winBounds.RD_bottom, bxax
	;
	; Scale the ruler offset into document coords
	;
	xchgdw	dxcx, bxax			;dx:cx <- y offset
	call	RulerScaleWinToDocCoords	;scale me jesus
	call	GetRulerOrigin			;bx:ax <- origin
	subdw	dxcx, bxax
	;
	; Get start row to draw
	;
	push	ax				;save ruler origin
	push	bp
	mov	ax, MSG_SPREADSHEET_GET_ROW_AT_POSITION
	call	CallSpreadsheet			;ax <- row #
	pop	bp
	clr	cx
	pop	bx				;bx.cx <- y offset
rowLoop:
	;
	; Get the height of the current row
	;
	push	ax				;row #
	push	cx				;fractional y offset
	push	ax				;row #
	mov_tr	cx, ax				;cx <- row #
	mov	ax, MSG_SPREADSHEET_GET_ROW_HEIGHT
	call	CallSpreadsheet
	cmp	dx, -1				;does row exist?
	je	endRuler			;branch if no such row
	mov	cx, dx				;cx <- integer row height
	clr	ax, dx				;dx:cx.ax <- row height
	call	RulerScaleDocToWinCoords
	mov	dx, cx
	mov_tr	cx, ax				;dx.cx <- scaled height
	;
	; Format and draw the row header
	;
	pop	ax				;ax <- row #
	call	DrawRowDividingLine
	call	DrawRowLabel
	;
	; Done yet?
	;
	pop	ax				;ax <- current fraction
	add	cx, ax
	adc	bx, dx				;bx.cx <- new y position
	pop	ax
	inc	ax				;ax <- next row
	cmp	bx, ss:winBounds.RD_bottom.low
	jbe	rowLoop				;loop until bottom edge
endLoop:

	.leave
	ret

	;
	; End of the line -- draw the last dividing line
	;
endRuler:
	pop	ax				;clean up stack
	call	DrawRowDividingLine
	jmp	endLoop
DrawVerticalRuler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRowDividingLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the row dividing line for a row ruler
CALLED BY:	SpreadsheetVertRulerDraw()

PASS:		di - handle of GState
		dx - height of row (window coordinates)
		bx - current y position (window coordinates)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRowDividingLine	proc	near
	uses	ax, cx
	.enter

	clr	ax				;ax <- x1
	mov	cx, SPREADSHEET_RULER_WIDTH	;cx <- x2
	call	GrDrawHLine

	.leave
	ret
DrawRowDividingLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRowLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a row header label
CALLED BY:	SpreadsheetVertRulerDraw()

PASS:		di - handle of GState
		ax - row #
		bx - current y position (window coordinates)
		dx - height of row (window coordinates)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(size JustifyTextParams) eq 8>

DrawRowLabel	proc	far
	rulerWidth	local	word
	class	SpreadsheetRulerClass
	uses	ax, bx, cx, dx, ds, es, si
	.enter

	tst	dx				;row hidden?
	jz	done				;branch if hidden

if	not _USE_UI_DEFAULT_FOR_RULER_FONT_AND_SIZE
	;
	; See if the row height is very short -- if so, we might
	; not draw this label so that adjacent labels don't
	; obscure each other.
	;
	cmp	dx, RULER_SHORT_HEIGHT		;short row height?
	ja	doFormat
	test	ax, 0x1				;even or odd row #?
	jz	done				;branch if odd (row 1 = 0)
	;
	; If very short, don't draw at all
	;
	cmp	dx, RULER_VERY_SHORT_HEIGHT	;very short?
	jbe	done
endif
	;
	; format the row number
	;
doFormat:
	;
	;	for the obidemo, the left most column width is only
	;	25 pixels, since rows range from 0 to 999.  However the
	;	spreadsheet library uses a constant value,
	;	SPREADSHEET_RULER_WIDTH to center the text. So I've
	;  	added code that uses the RulerClass instance variable
	;	VRI_desiredSize to center text. If this variable = 10,
	;	the default value,it means the value is not set by the
	;	user then we use SPREADSHEET_RULER_WIDTH
	;
	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	mov	cx, ds:[si].VRI_desiredSize
	cmp	cx, 10
	jne	useDesiredSize
	mov	cx, SPREADSHEET_RULER_WIDTH
useDesiredSize:
	mov	ss:[rulerWidth], cx	

	segmov	ds, ss, cx
	mov	es, cx
	mov	cx, MAX_REFERENCE_SIZE		;cx <- size of buffer
	sub	sp, cx				;make space for text
	mov	si, sp				;ds:si <- ptr to text buffer
	xchg	si, di				;es:di <- ptr to text buffer
	call	ParserFormatRowReference
	xchg	si, di				;ds:si <- ptr to text buffer
						;di <- GState handle
	;
	; Draw the formatted row number
	;
if	_USE_UI_DEFAULT_FOR_RULER_FONT_AND_SIZE
	push	dx				;save height
	push	si				;save ptr to row label text
	mov	si, GFMI_DESCENT or GFMI_ROUNDED
	call	GrFontMetrics			;dx <- descent of font
	mov_tr	ax, dx
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			;dx <- height of font
	pop	si				;restore ptr to row label text
	sub	dx, ax				;dx <- height of a numeric char
	pop	ax
	sub	ax, dx
	sar	ax, 1				;cx <- (row height-font size)/2
	cmp	ax, -1
	jl	skipDraw			;if too much overlap, skip draw
	add	bx, ax
else
	shr	dx, 1				;dx <- adjust for centering
	sub	dx, (RULER_SCREEN_POINTSIZE+1)/2-1
	add	bx, dx
endif
	clr	ax
	push	ax				;JTP_width (= calculate!)
	push	bx				;JTP_yPos
	push	ss:[rulerWidth]			;JTP_rightX
	clr	ax
	push	ax				;JTP_leftX
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

if	_USE_UI_DEFAULT_FOR_RULER_FONT_AND_SIZE
skipDraw:
	add	sp, MAX_REFERENCE_SIZE
	jmp	done
endif
DrawRowLabel	endp

RulerCode	ends

RulerPrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetVertRulerDrawRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a range of a vertical ruler
CALLED BY:	MSG_SPREADSHEET_VERT_RULER_DRAW_RANGE

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

PrintVerticalRuler	proc	far
	uses	ax, si, di
	.enter
	;
	; Do common setup for printing, including
	;
	call	RulerPrintSetup			;do common setup
	clr	ax, dx, cx			;dx.cx <- x translation
	mov	bx, SPREADSHEET_RULER_HEIGHT	;bx.ax <- y translation
	call	GrApplyTranslation
	;
	; Draw the range
	;
	clr	bx				;bx <- y position
	mov	ax, ss:[bp].SDP_range.CR_start.CR_row
rowLoop:
	push	ax
	mov_tr	cx, ax				;cx <- row #
	mov	ax, MSG_SPREADSHEET_GET_ROW_HEIGHT
	call	CallSpreadsheet
	pop	ax
EC <	cmp	dx, -1				;does row exist?>
EC <	ERROR_E	RULER_BAD_ROW			;>
	call	PrintRowHeader
	call	UpdateYPosition
	inc	ax				;ax <- next row
	cmp	ax, ss:[bp].SDP_range.CR_end.CR_row	;at the end yet?
	jbe	rowLoop
	;
	; We did a GrSaveState at the start because we have mucked with
	; the settings in the GState.  Restore the saved state now...
	;
	call	GrRestoreState			;restore GState
	.leave
	ret
PrintVerticalRuler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateYPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the y position and ensure a legal coordinate
CALLED BY:	SpreadsheetVertRulerDrawRange()

PASS:		bx - current y position
		dx - height of column
		di - handle of GState
RETURN:		bx - new y position
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateYPosition	proc	near
	.enter

	clr	cx
	add	bx, dx				;add row height
	adc	cx, 0				;propgate to high word
	jcxz	checkLargest
doTranslate:
	push	ax
	mov_tr	ax, bx
	mov	bx, cx				;bx:ax <- y translation
	clr	dx, cx				;dx:cx <- x translation
	call	GrApplyTranslationDWord
	mov_tr	bx, ax				;bx <- new y pos
	pop	ax
	jmp	yOK

checkLargest:
	cmp	bx, LARGEST_POSITIVE_COORDINATE	;too big?
	jae	doTranslate			;branch if too big
yOK:
	.leave
	ret
UpdateYPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintRowHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a row header for printout
CALLED BY:	SpreadsheetVertRulerDrawRange()

PASS:		di - handle of GState
		ax - row #
		dx - height of row (window coordinates)
		bx - current y position (window coordinates)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintRowHeader	proc	near
	uses	ax, bx, cx, dx
	.enter

	call	DrawRowLabel			;draw the label
	;
	; Draw a rectangle around the label
	;
	clr	ax				;ax <- left
	mov	cx, SPREADSHEET_RULER_WIDTH	;cx <- right
	add	dx, bx				;dx <- bottom
	call	GrDrawRect

	.leave
	ret
PrintRowHeader	endp

RulerPrintCode	ends
