COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		GeoCalc
FILE:		spreadsheetRuler.asm

AUTHOR:		Gene Anderson, Sep 12, 1991

ROUTINES:
	Name				Description
	----				-----------
	CallSpreadsheet			Call associated spreadsheet
	RulerScreenSetup		Common setup for ruler drawing on screen
	RulerPrintSetup			Common setup for ruler printing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/12/91		Initial revision

DESCRIPTION:
	Common code for spreadsheet's subclass of the VisRuler object

	$Id: rulerCommon.asm,v 1.1 97/04/07 11:13:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetHorizRulerDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle expose for drawing horizontal spreadsheet ruler
CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetRulerClass
		ax - the method

		bp - handle of GState

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetRulerDraw	method dynamic SpreadsheetRulerClass, \
						MSG_VIS_DRAW

	;
	; Are we drawing a standard ruler or a spreadsheet ruler?
	;
	cmp	ds:[di].VRI_type, VRT_CUSTOM
	jne	callSuper			;call superclass for drawing

	;
	; Call the appropriate draw routine
	;
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	mov	di, bp				;di <- handle of GState
	jnz	isHorizontal
	GOTO	DrawVerticalRuler

isHorizontal:
	GOTO	DrawHorizontalRuler

	;
	; We're not a custom ruler, so assume our superclass
	; will handle the drawing
	;
callSuper:
	mov	di, offset SpreadsheetRulerClass
	GOTO	ObjCallSuperNoLock
SpreadsheetRulerDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetRulerDrawRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a range of spreadsheet ruler
CALLED BY:	MSG_SPREADSHEET_RULER_DRAW_RANGE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetRulerClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetRulerDrawRange	method dynamic SpreadsheetRulerClass, \
						MSG_SPREADSHEET_RULER_DRAW_RANGE
	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	isHorizontal
	call	PrintVerticalRuler
callSlave:
	movdw	bxsi, ds:[di].VRI_slave
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ret

isHorizontal:
	call	PrintHorizontalRuler
	jmp	callSlave
SpreadsheetRulerDrawRange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSpreadsheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call our associated spreadsheet object
CALLED BY:	UTILITY

PASS:		ax - method to send
		*ds:si - VisRuler object
		cx, dx, bp - data for methd
RETURN:		cx, dx, bp - return values from method
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallSpreadsheet	proc	far
	class	SpreadsheetRulerClass
	uses	bx, si, di
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset	;ds:si <- ptr to instance data
	movdw	bxsi, ds:[si].SRI_spreadsheet
	mov	di,  mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
CallSpreadsheet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerScreenSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up GState for drawing to the screen
CALLED BY:	SpreadsheetHorizRulerDraw(), SpreadsheetVertRulerDraw()

PASS:		di - handle of GState
		ss:bp.winBounds - inherited locals
		*ds:si - VisRuler object
RETURN:		ss:bp.winBounds - Window bounds
		dx:cx - ruler offset (window coordinates, scaled dword)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerScreenSetup	proc	near
	uses	ax, bx, di
	class	VisRulerClass
winBounds	local	RectDWord
	.enter	inherit

	;
	; Set the font and pointsize
	;
if  _USE_UI_DEFAULT_FOR_RULER_FONT_AND_SIZE
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisRuler_offset
	test	ds:[bx].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	doneSize
	tst	ds:[bx].VRI_scale.WWF_int
	jnz	doneSize
endif		
	mov	cx, RULER_SCREEN_FONT		;cx <- FontID
	mov	dx, RULER_SCREEN_POINTSIZE
	clr	ah				;dx.ah <- pointsize (WBFixed)
	call	GrSetFont
doneSize::

	;
	; Set the line width to be 0 so that it will never scale
	; beyond 1 pixel wide, to match behavior of grid lines
	;
	clr	ax, dx				;dx.ax <- 0.0
	call	GrSetLineWidth

	;
	; Get the Window bounds
	;
	push	ds, si
	segmov	ds, ss
	lea	si, ss:winBounds		;ds:si <- ptr to RectDWord
	call	GrGetWinBoundsDWord
	pop	ds, si

	.leave
	ret
RulerScreenSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRulerOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the origin for the ruler

CALLED BY:	DrawHorizontalRuler(), DrawVerticalRuler()
PASS:		*ds:si - ruler object
RETURN:		bx:ax - origin (dword)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRulerOrigin		proc	near
	uses	si
	class	SpreadsheetRulerClass
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset	;ds:si <- ptr to instance data
EC <	cmp	ds:[si].VRI_origin.DWF_int.high, -1>
EC <	je	originOK			;>
EC <	cmp	ds:[si].VRI_origin.DWF_int.high, 0>
EC <	je	originOK			;>
EC <	cmp	ds:[si].VRI_origin.DWF_frac, 0	;>
EC <	je	originOK			;>
EC <	ERROR	RULER_ORIGIN_TOO_LARGE		;>
EC <originOK:					;>
	movdw	bxax, ds:[si].VRI_origin.DWF_int

	.leave
	ret
GetRulerOrigin		endp

RulerCode	ends

RulerPrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerPrintSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common setup for spreadsheet 
CALLED BY:	SpreadsheetHorizRulerDrawRange(), SpreadsheetVertRulerDrawRange

PASS:		ss:bp - SpreadsheetDrawParams
RETURN:		di - handle of GState
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerPrintSetup	proc	near
	.enter

	;
	; Get the GState handle and save the current settings
	;
	mov	di, ss:[bp].SDP_gstate
	call	GrSaveState
	;
	; Set the font and pointsize for printing, line pattern to solid
	;
	mov	cx, RULER_PRINT_FONT		;cx <- FontID
	mov	dx, RULER_PRINT_POINTSIZE
	mov	ax, SDM_100			;dx.ah <- pointsize (WBFixed)
						;al <- SysDrawMask
	call	GrSetFont
	call	GrSetLineMask
	;
	; Draw from the top of the character box
	;
	mov	ax, (mask TM_DRAW_BASE or mask TM_DRAW_BOTTOM \
			or mask TM_DRAW_ACCENT) shl 8
	call	GrSetTextMode

	.leave
	ret
RulerPrintSetup	endp

RulerPrintCode	ends
