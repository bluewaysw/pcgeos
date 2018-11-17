COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Lights Out
MODULE:		Fades & Wipes
FILE:		saverFades.asm

AUTHOR:		Gene Anderson, Oct  1, 1991

ROUTINES:
	Name				Description
	----				-----------
EXT	SaverFadePatternFade		Fade to darker & darker patterns
EXT	SaverFadeWipe			Wipe from one or more sides

INT	SaverFadeStart			Common setup for saver fade
INT	SaverFadeEnd			Common cleanup for saver fade
INT	WipeLeft,Right,Top,Bottom	Components of SaverFadeWipe

EC	ECCheckRect			Verify valid rectangle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/ 1/91	Initial revision

DESCRIPTION:
	Various fades and wipes

	$Id: saverFades.asm,v 1.1 97/04/07 10:44:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverFadeCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverFadePatternFade
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fade with increasing pattern (SDM_12_5 --> SDM_100)

CALLED BY:	(GLOBAL)

PASS:		di - handle of GState
		(ax,bx,cx,dx) - bounds of rectangle to fade
		si - SaverFadeSpeed to use (slow, medium, or fast)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/ 1/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack <size SysDrawMask eq 1>

SaverFadePatternFade	proc	far
	uses	si

	speed		local	word
	patternStep	local	word

	.enter

	;
	; Set speed for fade
	;

	push	ax
	clr	ax
	mov	al, cs:fadeSpeeds[si]		;al <- pause between fades
	mov	ss:speed, ax			;save pause
	mov	al, cs:fadeSteps[si]		;al <- steps between patterns
	mov	ss:[patternStep], ax
	pop	ax
	mov	si, SDM_0			;si <- initial pattern

patternLoop:
	;
	; Fading away...
	;

	push	ax
	mov	ax, ss:[speed]			;ax <- pause in ticks
	call	TimerSleep			;you feel sleepy...
	mov	ax, si				;al <- SysDrawMask
	call	GrSetAreaMask			;set new draw mask
	pop	ax

	call	GrFillRect
	sub	si, ss:[patternStep]		;next pattern
	cmp	si, SDM_100			;to black?
	jae	patternLoop			;loop while more patterns

	.leave
	ret

fadeSpeeds	byte 8, 5, 1
fadeSteps	byte 1, 2, 8

CheckHack <((SDM_0-SDM_100) MOD 8) eq 0>
CheckHack <SDM_0 gt SDM_100>

SaverFadePatternFade	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverFadeWipe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear rectangle by wiping from one or more sides

CALLED BY:	GLOBAL

PASS:		di - handle of GState
		(ax,bx,cx,dx) - bounds of rectangle to fade
		si - SaverFadeSpeed to use (slow, medium, or fast)
		bp - SaverWipeTypes for sides to use

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	ASSUMES: saved bp is at ss:[bp]

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaverFadeWipe	proc	far
	uses	ax,bx,cx,dx,si

	bounds	local	Rectangle	push dx, cx, bx, ax

	.enter
	ForceRef	bounds

	;
	; Figure out how big a square to clear each time based on the start
	;

	xchg	ax, cx
	sub	ax, cx				;ax <- width of rectangle
	mov	cl, cs:wipeSizes[si]
	shr	ax, cl				;ax <- size of square
	inc	ax				;zero is truly evil
	shl	si				;table o' words
	mov	si, cs:wipeSpeeds[si]		;si <- pause between steps
	xchg	si, ax				;si <- size of square

centerLoop:
	call	TimerSleep			;you feel sleepy...
	push	ax				;save timer count

	test	{word}ss:[bp], mask SWT_LEFT
	jz	skipLeft
	call	WipeLeft
	cmp	cx, ss:bounds.R_right		;left >= right?
	jge	donePop

skipLeft:

	test	{word}ss:[bp], mask SWT_BOTTOM
	jz	skipBottom
	call	WipeBottom
	cmp	bx, ss:bounds.R_top		;bottom <= top?
	jle	donePop

skipBottom:

	test	{word}ss:[bp], mask SWT_RIGHT
	jz	skipRight
	call	WipeRight
	cmp	ax, ss:bounds.R_left		;right <= left?
	jle	donePop

skipRight:

	test	{word}ss:[bp], mask SWT_TOP
	jz	skipTop
	call	WipeTop
	cmp	dx, ss:bounds.R_bottom		;top >= bottom?
	jge	donePop

skipTop:

	pop	ax				;ax <- timer pause
	jmp	centerLoop

donePop:

	pop	ax

	.leave
	ret

wipeSizes	byte 7, 6, 4
wipeSpeeds	word 6, 4, 2

SaverFadeWipe	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WipeLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	One step of a wipe from the left

CALLED BY:	SaverFadeWipeToCenter()

PASS:		ss:bp - inherited Rectangle
		si - size of inset
		di - handle of GState

RETURN:		cx - new left of area

DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WipeLeft	proc	near

	bounds	local	Rectangle
	.enter	inherit

	mov	ax, ss:[bounds].R_left		;ax <- left
	mov	bx, ss:[bounds].R_top		;bx <- top
	mov	cx, ax
	add	cx, si				;cx <- right
	mov	dx, ss:[bounds].R_bottom		;dx <- bottom
	call	GrFillRect
	mov	ss:[bounds].R_left, cx		;store new left

	.leave
	ret
WipeLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WipeRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	One step of a wipe from the right

CALLED BY:	SaverFadeWipeToCenter()

PASS:		ss:bp - inherited Rectangle
		si - size of inset
		di - handle of GState

RETURN:		ax - new right of area

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WipeRight	proc	near

	bounds	local	Rectangle
	.enter	inherit

	mov	ax, ss:[bounds].R_right
	mov	bx, ss:[bounds].R_top		;bx <- top
	mov	cx, ax				;cx <- right
	sub	ax, si				;ax <- left
	mov	dx, ss:[bounds].R_bottom		;dx <- bottom
	call	GrFillRect
	mov	ss:[bounds].R_right, ax		;store new right

	.leave
	ret
WipeRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WipeTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	One step of a wipe from the top

CALLED BY:	SaverFadeWipeToCenter()

PASS:		ss:bp - inherited Rectangle
		si - size of inset
		di - handle of GState

RETURN:		dx - new top of area

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WipeTop	proc	near

	bounds	local	Rectangle
	.enter	inherit

	mov	ax, ss:[bounds].R_left		;ax <- left
	mov	bx, ss:[bounds].R_top		;bx <- top
	mov	cx, ss:[bounds].R_right		;cx <- right
	mov	dx, bx
	add	dx, si				;dx <- bottom
	call	GrFillRect
	mov	ss:[bounds].R_top, dx		;store new top

	.leave
	ret
WipeTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WipeBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	One step of a wipe from the bottom

CALLED BY:	SaverFadeWipeToCenter()

PASS:		ss:bp - inherited Rectangle
		si - size of inset
		di - handle of GState

RETURN:		bx - new bottom of area

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/11/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WipeBottom	proc	near
	uses	ax

	bounds	local	Rectangle

	.enter	inherit

	mov	ax, ss:[bounds].R_left		;ax <- left
	mov	cx, ss:[bounds].R_right		;cx <- right
	mov	dx, ss:[bounds].R_bottom		;dx <- bottom
	mov	bx, dx
	sub	bx, si				;bx <- top
	call	GrFillRect
	mov	ss:[bounds].R_bottom, bx		;store new bottom

	.leave
	ret
WipeBottom	endp


SaverFadeCode	ends
