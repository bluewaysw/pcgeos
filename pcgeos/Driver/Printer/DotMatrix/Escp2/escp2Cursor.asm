
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin print driver
FILE:		escp2Cursor.asm

AUTHOR:		Dave Durran, 14 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/14/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the escp2 24-pin
	print driver cursor movement support

	$Id: escp2Cursor.asm,v 1.1 97/04/18 11:54:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GetCursor loads processor registers with the cursor 
		location in points from the top left corner of the page.

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE

RETURN: 	cx	=	X position in 1/72" from the left edge of page.
		dx	=	Y position in 1/72" from the top edge of page.

DESTROYED: 	ds	- left pointing at pstate

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetCursor	proc	near
		mov	ds, bp			; get PSTATE segment
		mov	dx, ds:[PS_cursorPos].P_x
		mov	cx,dx
		mov	dx, ds:[PS_cursorPos].P_y
		call	PrTo72s
		clc				; no errors
		ret
PrintGetCursor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintHomeCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HomeCursor sets the PSTATE cursor position to zero.

CALLED BY: 	GLOBAL
		PrintStartPage

PASS: 		bp	- Segment of PSTATE

RETURN: 	nothing

DESTROYED: 	ds	- left pointing at PState

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintHomeCursor	proc	far
		uses	ds
		.enter
		mov	ds, bp		;get PSTATE segment
		mov	ds:[PS_cursorPos].P_x, 0
		mov	ds:[PS_cursorPos].P_y, 0
		clc				; no errors
		.leave
		ret
PrintHomeCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrTo360s,PrTo72s
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	SendLineFeed

PASS:
	dx	- number to convert

RETURN:
	nothing

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrTo360s	proc	near
	uses	ax,cx
	.enter
	mov	ax,dx			;get in acc.
	clr	dx			;zero extension for div later.
	mov	cx,360			;x 360/72"
	mul	cx
	mov	cx,72
	div	cx			;ax = position in 1/360".
	mov	dx,ax			;move back to dx.
	clc
	.leave
	ret
PrTo360s	endp
PrTo72s	proc	near
	uses	ax,cx
	.enter
	mov	ax,dx			;get in acc.
	clr	dx			;zero extension for div later.
	mov	cx,72			;x 72/360"
	mul	cx
	mov	cx,360
	div	cx			;ax = position in 1/72".
	mov	dx,ax			;move back to dx.
	clc
	.leave
	ret
PrTo72s	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE and moves the printhead
	to the new position.

CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
	cx	- new X position
	dx	- new Y position

RETURN:
	carry	- set if some transmission error, else OK

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The resolution for positioning the printhead is based on the current
	character pitch, as the routine uses tabs to position the printhead
	in the X direction.

	The printhead can be moved in either direction in X, but only down the
	page (increasing Y).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
	uses	ax,si,ds,es,bx,cx,dx
	.enter
	mov	ds,bp		;get PSTATE segment.
	push	cx		;save the Y position.

;Service the Y position.
	call	PrTo360s
	sub	dx, ds:[PS_cursorPos].P_y ; calc relative head movement
	clc				; need carry clear of we're leaving.
					; NOTE: "jle" does not depend on carry
	jle	doXPos			;dont update position if neg or zero.
	call	PrLineFeed		;adjust the position in PSTATE and
					;the printhead position.
	; Service the X position.

doXPos:
	pop	cx			;pop X position into cx.
	jc	doNothing		; deal with errors
	mov	ds:[PS_cursorPos].P_x,cx ;save the new X Position.
	clr	dx
	mov	ax,cx			;get in the accum.


	; use the Set Absolute Print Position function.  It takes 360ths
	; of an inch, so multiply x position by 360, then divide by 72.

	mov	bx, 360			; mutliply by 360
	mul	bx
	mov	bx, 72			; divide by 72
	div	bx			; ax = position in 360ths
	shl	dx,1			;round...
	cmp	dx,bx
	jl	yposcorrect
	inc	ax
yposcorrect:
	call	PrLinePos		;set the position on this line


doNothing:
	.leave
	ret
PrintSetCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLinePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	does not set the new cursor position in the PSTATE but moves the
	printhead to the new position.

CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
	ax	- new X position in 1/360" from left margin

RETURN:
	carry	- set if some transmission error, else OK

DESTROYED:
	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The resolution for positioning the printhead is based on the current
	units setting, as defined by the set units command (should be 1/360")
	in the X direction.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLinePos	proc	near
	uses	cx,es,si
	.enter
	push	ax			; save position for later.
	mov	si, offset pr_codes_AbsPos ; send absolute position code
	call	SendCodeOut
	mov	es, bp			; es -> pstate
	pop	cx
	jc	exit
	call	PrintStreamWriteByte	; send low byte
	jc	exit
	mov	cl, ch
	call	PrintStreamWriteByte	; send high byte
exit:
	.leave
	ret
PrLinePos	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SendLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	PrPrintABand, PrintSetCursor

PASS:
	asciiSpacing	- number of 1/72" to feed. (SendLineFeed)
	bp	- points to PState

RETURN:
	nothing

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:
	Line spacing is in points (1/72"), but Epshi 24 expects
	the number of 1/360" to move.  So need to multiply the number of
	points to get the #of 1/360" to move.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendLineFeed	proc	near
	uses	es
	.enter
	mov	es, bp			; get ds -> PState
	mov	dl,ds:PS_asciiSpacing	;get current line spacing from PSTATE.
	clr	dh
	call	PrTo360s
	call	PrLineFeed
	.leave
	ret
SendLineFeed	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Executes a vertical line feed of dx 1/360", and updates the cursor
	position accordingly.

CALLED BY:
	Jump Table

PASS:
	dx	=	length , in 1/360" units to line feed.

RETURN:
	carry	- set if some transmission error

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PrLineFeed	proc	near
	uses	cx,si,es
	.enter
	mov	es, bp

	add	es:PS_cursorPos.P_y,dx	;update the cursor position.
	cmp	dx,PR_MAX_LINE_FEED
	jb	doRem
	mov	si,offset pr_codes_DoMaxLineFeed ;code to do max/360" feed.
	call	SendCodeOut	;send the code to the stream.
	jc	exit
maxLoop:
	cmp	dx,PR_MAX_LINE_FEED
	jb	doRem
	sub	dx,PR_MAX_LINE_FEED			;save in storge reg.
	mov	cl, C_LF 
	call	PrintStreamWriteByte		;send the actual LF char.
	jc	exit
	jmp	maxLoop
	

;do remainder of distance.
doRem:
	test	dx,dx		;see if zero.
	jz	exit		;if so, exit.
	mov	si,offset pr_codes_DoLineFeed ;code to do n/360" feed.
	call	SendCodeOut	;send the code to the stream.
	jc	exit
	mov	cx,dx		;get back the remainder.
	call	PrintStreamWriteByte		;send the distance.
	jc	exit
	mov	cl, C_LF 
	call	PrintStreamWriteByte		;send the actual LF char.
exit:
	.leave
	ret
PrLineFeed	endp
