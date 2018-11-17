
COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mine
FILE:           input.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik   1/92		Initial program

DESCRIPTION:
        This code handles the output routines of the game Minesweeper


RCS STAMP:
	$Id: output.asm,v 1.1 97/04/04 14:52:05 newdeal Exp $

------------------------------------------------------------------------------@

CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToHMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the passed value to Hours/Minutes/Seconds

CALLED BY:	GLOBAL
PASS:		dx.ax - value
RETURN:		ch - hours
		dl - minutes
		dh - seconds
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NUM_SECONDS_PER_MINUTE	equ	60
NUM_MINUTES_PER_HOUR	equ	60
ConvertToHMS	proc	near	uses	ax, bx
	.enter
	mov	bx, NUM_SECONDS_PER_MINUTE * NUM_MINUTES_PER_HOUR
	div	bx
EC <	tst	ah							>
EC <	ERROR_NZ	-1						>
	mov	ch, al		;CL <- hours

	mov_tr	ax, dx		;AX <- # minutes/seconds (remainder)
	mov	bl, NUM_SECONDS_PER_MINUTE
	div	bl

	mov_tr	dx, ax		;DL <- minutes
				;DH <- seconds		
	.leave
	ret
ConvertToHMS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatAsElapsedTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the passed data as an elapsed time

CALLED BY:	GLOBAL
PASS:		dx.ax - elapsed time in seconds
		es:di - dest buffer
RETURN:		nada
DESTROYED:	ax, dx, cx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatAsElapsedTime	proc	near
	.enter
	call	ConvertToHMS
;
;	CH <- Hours
;	DL <- Minutes
;	DH <- Seconds
;
	mov	si, DTF_HMS_24HOUR
	tst	ch
	jnz	format
	mov	si, DTF_MS
	tst	dl
	jz	justAScore
format:
	call	LocalFormatDateTime
exit:
	.leave
	ret

justAScore:
	mov	al, dh
	clr	ah
	clr	dx
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	jmp	exit
FormatAsElapsedTime	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MineFieldUpdateClock

DESCRIPTION:	This method is sent by the timer to increment the clock

PASS:		*ds:si	= instance data of the object

RETURN:		ds,si	= same

CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		initial version

------------------------------------------------------------------------------@

MineFieldUpdateClock	method	MineFieldClass, MSG_MINE_CLOCK
	buffer	local	SCORE_BUFFER_SIZE dup (char)
	.enter
	incdw	es:[Time]			;increment timer
	movdw	dxax, es:[Time]

;
;	Convert the # seconds into an HMS display.
;
	lea	di, buffer
	segmov	es, ss
	call	FormatAsElapsedTime
	
	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	movdw	cxdx, esdi
	GetResourceHandleNS	TimeGlyph, bx
	mov	si, offset TimeGlyph
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	.leave
	ret
MineFieldUpdateClock	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateMineDisplay

DESCRIPTION:	This method called to update mines left display

PASS:		al = # of mines 
		ds = data segment

RETURN:		

CAN DESTROY:	ax,cx,dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	2/3/92		initial version

------------------------------------------------------------------------------@

UpdateMineDisplay	proc	near	uses	bx, si, di, bp
	.enter
	
	clr	ah
	mov_tr	cx, ax
	GetResourceHandleNS	MineCount,bx		
	mov	si,offset MineCount
	mov	ax,MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp
	clr	di
	call	ObjMessage
	.leave
	ret

UpdateMineDisplay	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MineFieldDraw

DESCRIPTION:	This method is sent by the VisIsoContent object (MSG_META_EXPOSED)

PASS:		*ds:si	= instance data of the object
		^hbp	= Handle of GState to draw with
		cl	= DrawFlags structure

RETURN:		ds,si,bp	= same

CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		initial version

------------------------------------------------------------------------------@

MineFieldDraw	method	MineFieldClass, MSG_VIS_DRAW

	mov 	dl, ds:[di].MF_Width	;dl = width
	mov 	dh, ds:[di].MF_Height	;dh = current height
	mov	bx,es:[MineArray]	;Array Handle
	call	MemLock			;Lock memory chunk
	mov	es:[temp1],ax		;temp2 = ptr to Array

	sub	ch,ch
	dec	dh
	dec	dl
	mov	cl,dh
	mov	si,es:[MineArraySize]	;si = current array index
	mov	di,bp			;^hdi = Gstate
	push	cs
	pop	ds			;set ds to code segment

HeightLoop:
	push 	cx
	mov 	cl,dl			;set cx to width
DrawLoop:
	dec	si
	push	ds
	mov	ds,es:[temp1]		;point to array
	sub 	bh,bh
	mov	bl,ds:[si]		;get mine attribute
	pop	ds
	shl	bx,1
	push	si
	test	es:[GraphicsMode],VGA_COLOR	;video mode?
	jnz	ColorVgaMode
	mov	si,cs:Mono_OffsetTable[bx]	;mono bmp
	jmp	Update
ColorVgaMode:	
	mov	si,cs:OffsetTable[bx]
Update:


; we are taking advantage of the fact that the mine bitmaps are 16x16
; therefore we shift the Mine coordinate left 4 times to get the document
; coordinate (very cheesy, but it's fast)

	mov 	ax,cx
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	sub	bh,bh
	mov	bl,dh
	shl	bx,1
	shl	bx,1
	shl	bx,1
	shl	bx,1
	push	dx
	test	es:[GraphicsMode],VGA_COLOR	;video mode?
	jnz	ColorVgaDraw
	push	cx
	push	ax
	mov	ah,CF_INDEX
	mov	al,C_WHITE
	call	GrSetAreaColor
	pop	ax
	mov	cx,ax
	mov	dx,bx				;Monochrome draw
	add	cx,16				;fill white rectangle
	add	dx,16				;to change later
	call	GrFillRect
	push	ax
	mov	ah,CF_INDEX
	mov	al,C_BLACK
	call	GrSetAreaColor
	pop	ax
	pop	cx
ColorVgaDraw:
	sub	dx,dx
	call 	GrDrawBitmap		; (ax,bx) ds:si di dx=0
	pop	dx
	pop	si
	dec	cx
	jge	DrawLoop

	pop	cx
	dec	dh
	dec	cx
	jge	HeightLoop

	mov	bx,es:[MineArray]
	call	MemUnlock

	ret	

MineFieldDraw	endm

include 	vgabmp.asm		;bitmaps belong in this segment
include		monobmp.asm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentHighScoreControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current high score object based on the current level

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentHighScoreControl	proc	near	uses	ax, cx, dx, bp, di
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GetResourceHandleNS	DifficultyList, bx
	mov	si, offset DifficultyList
	mov	di, mask MF_CALL
	call	ObjMessage
	mov_tr	si, ax
	shl	si, 1
	GetResourceHandleNS	MineLevel0HighScoreControl, bx
	mov	si, cs:[highScoreControllers][si]
	.leave
	ret
GetCurrentHighScoreControl	endp
highScoreControllers	nptr	MineLevel0HighScoreControl,
				MineLevel1HighScoreControl,
				MineLevel2HighScoreControl,
				MineLevel3HighScoreControl

COMMENT @----------------------------------------------------------------------

FUNCTION:	MineShowHighScores

DESCRIPTION:	Show high score board

PASS:		
RETURN:		
DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	2/4/92		Initial Version

------------------------------------------------------------------------------@
MineShowHighScores	method	MineProcessClass, MSG_SHOW_HIGH_SCORES

	call	GetCurrentHighScoreControl
	mov	ax, MSG_HIGH_SCORE_SHOW_SCORES
	mov	cx, -1
	clr	di
	GOTO	ObjMessage
MineShowHighScores	endm

CommonCode	ends
