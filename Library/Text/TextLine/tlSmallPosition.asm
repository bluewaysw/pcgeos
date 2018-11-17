COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallPosition.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Position related routines for small text objects.

	$Id: tlSmallPosition.asm,v 1.1 97/04/07 11:20:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a text offset into a line and a pixel offset, compute
		the nearest possible valid position where the event at the
		pixel position could occur, not to exceed the passed offset.

CALLED BY:	TL_LineTextPosition via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
		dx.ax	= Offset to calculate up to
		bp	= Pixel offset from left edge of line
RETURN:		dx.ax	= Nearest character offset
		bx	= Pixel offset from left edge of the line
		carry set if the position is not right over the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineTextPosition	proc	near
	uses	cx, di, bp, es
	.enter
	mov	di, cx			; bx.di <- line
EC <	call	ECCheckSmallLineReference			>

	pushdw	dxax			; Pass offset to stop at
	call	TL_LineToOffsetStart	; dx.ax <- line start

	push	ax			; Save lineStart.low
	call	SmallGetLinePointer	; *ds:ax <- chunk array
					; es:di <- line pointer
					; cx <- size of line/field data
	pop	ax			; Restore lineStart.low

	mov	bx, bp			; bx <- pixel offset to find

	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; dx.ax	= Offset to start of the line
	; bx	= Pixel offset to find
	; On stack:
	;	Offset to stop calculating at
	;
	call	CommonLineTextPosition	; dx.ax <- nearest offset
					; bx <- pixel offset from left edge
					; carry set if not right over the line
	.leave
	ret
SmallLineTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of the top-left corner of the line

CALLED BY:	TL_LineToPosition via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		cx	= left edge of the line relative to the region
		dx.bl	= top edge of the line relative to the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineToPosition	proc	far
	uses	ax, di
	.enter
	call	SmallLineGetLeftEdge	; ax <- left edge
	call	SmallLineGetTop		; dx.bl <- top of line

	mov	cx, ax			; cx <- left edge
	.leave
	ret
SmallLineToPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineFromPositionGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a position find the line closest to that position.

CALLED BY:	TL_LineFromPosition via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ax	= 16 bit X event position
		dx	= 16 bit Y event position
		cx	= Region
RETURN:		bx.di	= Line closest to that position
		carry set if the position is below the last line
		dx.ah	= Line height
		cx.al	= Baseline
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineFromPositionGetInfo	proc	near
	uses	si, bp
yPosition	local	WBFixed
lineHeight	local	WBFixed
baseline	local	WBFixed
	.enter
	mov	yPosition.WBF_int, dx	; Initialize the stack frame
	mov	yPosition.WBF_frac, 0

	;
	; Set up for enum...
	;
	mov	bx, cs			; bx:di <- callback routine
	mov	di, offset cs:CommonLineFromPosCallback

	call	SmallGetLineArray	; *ds:ax <- line array
	mov	si, ax			; *ds:si <- line array

	clrdw	dxcx			; Start at the first line...

	call	ChunkArrayEnum		; dx.cx = Line on which the event fell
	jc	quit			; Branch if we found the line

	;
	; We didn't find the line, but we did increment the line counter
	; the last time we called LineFromPosCallback(). This means that
	; we now have a line number that is one beyond the end of the
	; list of lines.
	;
	decdw	dxcx			; Move back to last line
	clc				; Signal: didn't find the line

quit:
	;
	; Carry set if we found the line. Clear otherwise.
	;
	movdw	bxdi, dxcx		; bx.di <- line to return
	movwbf	dxah, lineHeight	; dx.ah <- line height
	movwbf	cxal, baseline		; cx.al <- line baseline
	
	cmc				; Carry set if below last line
					; Carry clear otherwise
	.leave
	ret
SmallLineFromPositionGetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineFromPosCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a position lies on a line.

CALLED BY:	SmallLineFromPosition via ChunkArrayEnum
PASS:		ds:di	= Current line
		ss:bp	= Inheritable stack frame
		dx.cx	= Current line
RETURN:		carry set if the position falls in this line
		    dx.cx  = Unchanged
		carry clear otherwise
		    dx.cx  = Next line number
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineFromPosCallback	proc	far
	uses	bx, es
	.enter	inherit	SmallLineFromPositionGetInfo
	segmov	es, ds, bx		; es:di <- line ptr

	push	dx			; Save line.high
	CommonLineGetBLO		; dx.bl <- baseline
	movwbf	baseline, dxbl		; Save baseline

	CommonLineGetHeight		; dx.bl <- line height
	movwbf	lineHeight, dxbl	; Save line height

	subwbf	yPosition, dxbl		; Modify Y position to get offset
					;    from next line
	pop	dx			; Restore line.high

	js	foundLine		; Branch if it's on this line

	;
	; The position isn't on this line
	;
	incdw	dxcx			; Else move to next line
	clc				; Signal: continue calling back
quit:
	.leave
	ret

foundLine:
	stc				; Signal: quit calling back
	jmp	quit

CommonLineFromPosCallback	endp


TextFixed	ends
