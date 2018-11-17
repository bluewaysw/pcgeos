COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Preferences/Common
FILE:		prefPrinter.asm

AUTHOR:		Cheng, 2/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/91		Initial revision

DESCRIPTION:

	$Id: prefPrinter.asm,v 1.1 97/04/04 16:28:25 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PrintTestDrawCornerMarks

DESCRIPTION:	Gets the document name to be printed

CALLED BY:	INTERNAL

PASS:		CX:DX	= PrintControl OD
		BP	= GState

RETURN:		DI	= GState
		CX	= Paper width

DESTROYED:	AX, BX, DX, SI, BP

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/91		Initial version

-------------------------------------------------------------------------------@

CORNER_LINE_LENGTH	= 27			; 3/8 inch

PrintTestDrawCornerMarks	proc	near
	uses	ds
	.enter

	; Grab the default page size
	;
	push	bp				; save the GState
	mov	bx, cx				; PrintControl OD => BX:DX
	sub	sp, size PageSizeReport
	segmov	ds, ss
	mov	si, sp				; PageSizeReport => DS:SI
	call	SpoolGetDefaultPageSizeInfo
	mov	cx, ds:[si].PSR_width.low
	mov	si, ds:[si].PSR_height.low
	xchg	dx, si				; document dimensions -> CX,DX
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
	mov	di, mask MF_CALL
	call	ObjMessage			; set the document size
	add	sp, size PageSizeReport
	push	cx, dx				; save the page size

	; Grab the margins for this printer
	;
	mov	ax, MSG_PRINT_CONTROL_GET_PRINTER_MARGINS
	mov	dx, TRUE			; set margins at same time
	mov	di, mask MF_CALL
	call	ObjMessage			; margins => AX, CX, DX, BP

	; Translate the document by the upper-left margins
	;
	pop	bx, si				; page size => BX x SI
	pop	di				; GState => DI
	sub	bx, ax				; take off left margin
	sub	bx, dx				; take off right margin
	sub	si, cx				; take off top margin
	sub	si, bp				; take off bottom margin
	mov	bp, bx				; page width => BP
	xchg	dx, ax				; left margin => DX
	mov	bx, cx				; top margin => BX
	clr	ax				; y translation => BX:AX
	clr	cx				; x translation => DX:CX
	call	GrApplyTranslation		; move the document over

	; Draw the four corner indicators
	;
	mov	cx, bp				; page width => CX
	mov	dx, si				; page height => DX
	dec	cx
	dec	dx
	mov	ax, cx
	mov	bx, dx
	sub	ax, CORNER_LINE_LENGTH
	call	GrDrawLine			; lower-right, horizontal
	mov	ax, cx
	sub	bx, CORNER_LINE_LENGTH
	call	GrDrawLine			; lower-right, vertical

	push	cx
	clr	cx
	clr	ax
	call	GrDrawLine			; lower-left, vertical
	mov	bx, dx		
	mov	ax, CORNER_LINE_LENGTH
	call	GrDrawLine			; lower-left, horizontal

	clr	dx
	clr	bx
	call	GrDrawLine			; upper-left, horizontal
	clr	ax
	mov	bx, CORNER_LINE_LENGTH
	call	GrDrawLine			; upper-left, vertical

	pop	cx
	mov	ax, cx
	call	GrDrawLine			; upper-right, vertical
	clr	bx
	sub	ax, CORNER_LINE_LENGTH
	call	GrDrawLine			; upper-rigth, horizontal
	
	; Set the font defaults
	;
	push	cx				; save paper width
NPZ <	mov	cx, FID_DTC_URW_ROMAN					>
PZ <	mov	cx, FID_BITSTREAM_KANJI_HON_MINCHO			>
	mov	dx, 36				; font size => DX:AH
	clr	ah
	call	GrSetFont
	pop	cx				; restore paper width

	.leave
	ret
PrintTestDrawCornerMarks	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PrintTestDrawCenteredString

DESCRIPTION:	Gets the document name to be printed

CALLED BY:	INTERNAL (MSG_TEST_PRINTER)

PASS:		DX:BP	= String to draw
		DI	= GState handle
		CX	= Paper width
		AX	= Position on paper to draw string

RETURN:		Nothing

DESTROYED:	AX, DX, DS, SI

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/91		Initial version

-------------------------------------------------------------------------------@

PrintTestDrawCenteredString	proc	near
	uses	bx, cx
	.enter

	xchg	bx, ax				; page height => BX
	mov	ds, dx
	mov	si, bp				; string => DS:SI
	xchg	ax, cx				; page width => AX
	clr	cx
	call	GrTextWidth			; width => DX
	xchg	cx, ax				; document width => CX
	clr	ax
	cmp	cx, dx
	jl	drawText			; if less, cut off text on right
	sub	cx, dx
	sar	cx, 1				; else center the text
	xchg	ax, cx				; X-offset => AX
drawText:
	clr	cx				; specify null termination
	call	GrDrawText

	.leave
	ret
PrintTestDrawCenteredString	endp
