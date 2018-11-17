COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargePosition.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Position related routines for large text objects.

	$Id: tlLargePosition.asm,v 1.1 97/04/07 11:20:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineTextPosition
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
LargeLineTextPosition	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	pushdw	dxax			; Pass offset to stop at
	call	TL_LineToOffsetStart	; dx.ax <- line start

	call	LargeGetLinePointer	; es:di <- line pointer
					; cx <- size of line/field data
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
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of the top-left corner of the line

CALLED BY:	TL_LineToPosition via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		cx	= left edge of the line relative to the region
		dx	= top edge of the line relative to the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineToPosition	proc	far
	uses	ax, bx, di
	.enter
	call	LargeLineGetTopLeftAndStart
					; ax <- left edge
					; dx.bl <- top edge
					; di.cx <- start of line

	ceilwbf	dxbl, dx		; dx <- top of line
	mov	cx, ax			; cx <- left edge
	.leave
	ret
LargeLineToPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineFromPositionGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a position find the line closest to that position.

CALLED BY:	TL_LineFromPosition via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ax	= 16 bit X event position
		dx	= 16 bit Y event position
		cx	= Region
RETURN:		bx.di	= Line closest to that position
		carry set if the position is below the last line in region
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
LargeLineFromPositionGetInfo	proc	near
	uses	si, bp, es
yPosition	local	WBFixed
lineHeight	local	WBFixed
baseline	local	WBFixed
	.enter
	mov	yPosition.WBF_int, dx	; Initialize the stack frame
	mov	yPosition.WBF_frac, 0

	call	T_GetVMFile
	push	bx			; VM file
	call	LargeGetLineArray	; di <- line array
	push	di			; Pass array
	
	mov	di, cs
	push	di
	mov	di, offset cs:CommonLineFromPosCallback
	push	di			; Pass callback
	
	;
	; Get the first line in the region.
	;
	call	TR_RegionGetTopLine	; bx.di <- top line
	pushdw	bxdi			; Pass starting element
	
	mov	dx, bx			; dx <- startLine.high

	call	TR_RegionGetLineCount	; cx <- # of lines
	clr	bx
	
	pushdw	bxcx			; Pass number to process

	mov	cx, di			; dx.cx <- startLine

	call	HugeArrayEnum		; dx.cx = Line on which the event fell
	jc	quit			; Branch if we found the line

	;
	; We didn't find the line, but we did increment the line counter
	; the last time we called LineFromPosCallback(). This means that
	; we now have a line number that is one beyond the end of the
	; list of lines.
	;
	tstdw	dxcx
	jz	atStart
	decdw	dxcx			; Move back to last line
atStart:
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
LargeLineFromPositionGetInfo	endp

TextFixed	ends
