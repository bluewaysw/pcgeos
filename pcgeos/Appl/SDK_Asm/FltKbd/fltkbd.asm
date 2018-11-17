COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Floating Keyboard Sample App
MODULE:		
FILE:		fltkbd.asm

AUTHOR:		Allen Yuen, Jun 26, 1996

ROUTINES:
	Name			Description
	----			-----------
    INT FKDrawOneKey		Draw the background of a key and its
				character.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	6/26/96   	Initial revision


DESCRIPTION:
	Sample app to demonstrate how to implement a floating keyboard outside
	of the UI.

	$Id: fltkbd.asm,v 1.1 97/04/04 16:35:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include	assert.def
include	Objects/inputC.def
include	timer.def
include	Internal/fepDr.def
include	geode.def
include	initfile.def
UseLib	ark.def

include	fltkbd.def
include	fltkbd.rdef

idata	segment
	FltKbdApplicationClass
	FltKbdProcessClass	mask CLASSF_NEVER_SAVED
	FltKbdContentClass
	FltKbdTextClass

	fepDriver	fptr

	firstKey	word FIRST_KEY_A
	lastKey		word LAST_KEY_A
idata	ends

KbdCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKPGenProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the Temp Text optr to the FEP driver.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds	= dgroup of process
		es 	= segment of FltKbdProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	7/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
fepCategory	char	"fep",0
fepDriverKey	char	"driver",0
fepDir		TCHAR	"FEP",0

FKPGenProcessOpenApplication	method dynamic FltKbdProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
	uses	ax, cx, dx, bp, ds, es
	.enter
	;
	; Call the superclass
	;
	mov	di, offset FltKbdProcessClass
	call	ObjCallSuperNoLock
	;
	; Get the name of the FEP driver from the .ini file
	;
	segmov	ds, cs, cx
	mov	si, offset fepCategory		;ds:si = category string
	mov	dx, offset fepDriverKey		;cx:dx = key string
	clr	bp				;buffer created for us
	call	InitFileReadString		;carry set if none
	jc	noFEP
	;
	; Go to the SYSTEM\FEP directory
	;
	push	bx				;bx = buffer handle
	call	FilePushDir			;save current dir
	mov	bx, SP_SYSTEM
	segmov	ds, cs
	mov	dx, offset fepDir		;ds:bx = path
	call	FileSetCurrentPath
	jc	noFEPPop			;jump if no FEP directory
	pop	bx				;bx = buffer handle
	push	bx
	;
	; Load the driver
	;
	call	MemLock
	mov	ds, ax
	clr	si, ax, bx			;ds:si = geode name
	call	GeodeUseDriver			;bx = driver handle
	call	FilePopDir
	jc	noFEPPop
	;
	; Get the address of the Strategy Routine
	;
	call	GeodeInfoDriver			; ds:si = driver info
	mov	dx, ds:[si].DIS_strategy.segment
	mov	si, ds:[si].DIS_strategy.offset
	segmov	ds, dgroup, ax
	mov	ds:[fepDriver.high], dx
	mov	ds:[fepDriver.low], si

	mov	dx, handle FltKbdTempText
	mov	bp, offset FltKbdTempText	; ^ldx:bp = Temp Text
	mov	di, DR_FEP_ANNOUNCE_TEMP_TEXT
	call	ds:[fepDriver]
noFEPPop:
	pop	bx
	call	MemFree
noFEP:
	.leave
	ret
FKPGenProcessOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a character to the flow, emulating both PRESS and
		RELEASE.

CALLED BY:	INTERNAL
PASS:		SBCS	ch = CharacterSet
			cl = Chars
		DBCS
			cx = Chars
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	7/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendChar	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Send the key-press event
	;
	mov	ax, MSG_META_KBD_CHAR
	mov	dx, (0 shl 8) or mask CF_FIRST_PRESS
	clr	bp					; Toggle State
	clr	di					; just Send
	call	UserCallFlow
	;
	; Sleep for the duration of invert.  (Other threads can process the
	; keyboard event while we're sleeping.)
	;
	mov	ax, KEY_INVERT_DURATION
	call	TimerSleep
	;
	; Send the key-release event
	;
	mov	ax, MSG_META_KBD_CHAR
	mov	dl, mask CF_RELEASE
	clr	di
	call	UserCallFlow

	.leave
	ret
SendChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKPProcessButtonPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the pressing of one of the functional buttons
		by sending the vardata character to the flow.

CALLED BY:	MSG_FKP_PROCESS_CONVERT
PASS:		ds	= dgroup of process
		es 	= segment of FltKbdProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	7/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FKPProcessButtonPress	method dynamic FltKbdProcessClass, 
					MSG_FKP_PROCESS_BUTTON_PRESS
	uses	ax, cx, dx, bp
	.enter
	;
	; Send the convert key to the flow
	;
	call	SendChar

	.leave
	ret
FKPProcessButtonPress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKPProcessSetCharGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_FKP_SET_CHAR_GROUP
PASS:		*ds:si	= FltKbdProcessClass object
		ds:di	= FltKbdProcessClass instance data
		ds:bx	= FltKbdProcessClass object (same as *ds:si)
		es 	= segment of FltKbdProcessClass
		ax	= message #
		cx	= char group that is selected
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ian	12/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FKPSetCharGroup	method dynamic FltKbdProcessClass, 
					MSG_FKP_SET_CHAR_GROUP
	uses	ax, cx, dx, bp
	.enter

	segmov	ds, dgroup, ax

	cmp	cx, GROUP_A
	jne	notGroupA

	mov	ds:[firstKey], FIRST_KEY_A
	mov	ds:[lastKey], LAST_KEY_A + 1
	jmp	done

notGroupA:
	cmp	cx, GROUP_B
	jne	notGroupB

	mov	ds:[firstKey], FIRST_KEY_B
	mov	ds:[lastKey],  LAST_KEY_B + 1
	jmp	done

notGroupB:

	cmp	cx, GROUP_C
	jne	notGroupC

	mov	ds:[firstKey], FIRST_KEY_C
	mov	ds:[lastKey],  LAST_KEY_C + 1
	jmp	done

notGroupC:	
	mov	ds:[firstKey], FIRST_KEY_D
	mov	ds:[lastKey],  LAST_KEY_D + 1
	
done:

	mov	ax, MSG_VIS_MARK_INVALID
	mov	bx, handle Keyboard
	mov	si, offset Keyboard
	clr	di
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call 	ObjMessage

	.leave
	ret
FKPSetCharGroup	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKCVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the whole keyboard.

CALLED BY:	MSG_VIS_DRAW
PASS:		cl	= DrawFlags
		^hbp	= GState to draw thru
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Loop through each key and draw it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	6/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FKCVisDraw	method dynamic FltKbdContentClass, 
					MSG_VIS_DRAW

	segmov	ds, dgroup, dx
	mov	di, bp
	clr	si			; don't invert
	mov	dx, ds:[firstKey]

	mov	bx, VERT_MARGIN		; bx = y co-ordinate of first row

rowLoop:
	;
	; Draw one row of keys.
	;
	mov	ax, HORIZ_MARGIN	; ax = x co-ordinate of first column
	mov	cx, NUM_KEYS_PER_ROW

columnLoop:
	;
	; Draw one key in this row.
	;
	call	FKDrawOneKey
	add	ax, KEY_WIDTH
	inc	dx			; dx = next key to draw
	cmp	dx, ds:[lastKey]
	loopne	columnLoop

	;
	; Either we have drawn the last key in this row or we have drawn the
	; last key in the keyboard.
	;
	; See if we should loop to next row.
	;
	add	bx, KEY_HEIGHT
	cmp	bx, KEYBOARD_HEIGHT - VERT_MARGIN
	jb	rowLoop

	ret
FKCVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKDrawOneKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the background of a key and its character.

CALLED BY:	(INTERNAL) FKCVisDraw, FKCMetaStartSelect
PASS:		dx	= key to draw (Chars)
		ax, bx	= co-ordinates of top left corner
		^hdi	= GState
		si	= non-zero if invert
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	6/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FKDrawOneKey	proc	near
	uses	ax, bx, cx, dx, si
	.enter

SBCS <	Assert	e, dh, 0						>

	;
	; Set background color to black if invert, white otherwise.
	;
	push	ax			; save top co-ordinate
		CheckHack <CF_INDEX eq 0 and C_BLACK eq 0>
	clr	ax			; ah = CF_INDEX, al = CF_BLACK
	tst	si
	jnz	hasAreaColor
	mov	al, C_WHITE
hasAreaColor:
	call	GrSetAreaColor
	pop	ax			; ax = top co-ordinate

	push	dx			; save Chars to draw

	;
	; Draw background.
	;
	mov	cx, ax
	add	cx, KEY_WIDTH - 1
	lea	dx, [bx + KEY_HEIGHT - 1] ; (cx, dx) = bottom right corner
	call	GrFillRect

	push	ax

	;
	; Set border and text color to white if invert, black otherwise.
	;
		CheckHack <CF_INDEX eq 0 and C_BLACK eq 0>
	clr	ax			; ah = CF_INDEX, al = CF_BLACK
	tst	si
	jz	hasLineColor
	mov	al, C_WHITE
hasLineColor:
	call	GrSetLineColor
	call	GrSetTextColor

	pop	ax

	;
	; Draw border.
	;
	call	GrDrawRect

	;
	; Calculate the left edge of the character:
	; left edge of char = left edge of key + (key width - char width) / 2
	;
	mov_tr	cx, ax			; cx = left co-ordidate of key
	pop	ax			; ax = Chars to draw
	push	ax			; save Chars again

	call	GrCharWidth		; dx.ah = width
	sub	dx, KEY_WIDTH - 1	; "- 1" for rounding.  dx = - (key
					;  width - char width)
	sar	dx			; divide by 2 and round off

	mov_tr	ax, cx			; ax = left co-ordinate of key
	sub	ax, dx			; ax = left co-ordinate of char

	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics		; dx = font height
	sub	dx, KEY_HEIGHT - 1	; "- 1" for rounding.  dx = - (key
					;  height - char height)
	sar	dx			; divide by 2 and round off

	sub	bx, dx			; bx = top co-ordinate of char

	pop	dx			; dx = Chars to draw
	call	GrDrawChar

	.leave
	ret
FKDrawOneKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKCMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flash the key that is clicked, and send MSG_META_KBD_CHAR's.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= FltKbdContentClass object
		cx	= X position of mouse
		dx	= Y position of mouse
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive
RETURN:		ax	= mask MRF_PROCESSED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	A possible optimization is to check if there is any pending
	MSG_META_START_SELECT (for any object) in the event queue.  If so,
	don't sleep.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	6/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FKCMetaStartSelect	method dynamic FltKbdContentClass, 
					MSG_META_START_SELECT
	uses	cx, dx, bp
	.enter

	;
	; Calculate the column # of the key.
	;
	mov	ax, cx
	sub	ax, HORIZ_MARGIN
	jb	done			; do nothing if too far left

	cmp	ax, NUM_KEYS_PER_ROW * KEY_WIDTH
					; avoid divide overflow
	jae	done			; do nothing if too far right

		.assert NUM_KEYS_PER_ROW lt 256
	mov	bl, KEY_WIDTH
	div	bl
	clr	ah			; ax = 0-based column #
	mov_tr	bp, ax			; bp = column # < 256

	;
	; Calculate the row # of the key.
	;
	mov_tr	ax, dx
	sub	ax, VERT_MARGIN
	jb	done			; do nothing if too far up

	cmp	ax, NUM_ROWS * KEY_HEIGHT
					; avoid divide overflow
	jae	done			; do nothing if too far down

		.assert NUM_ROWS lt 256
	mov	bl, KEY_HEIGHT
	div	bl			; al = 0-based row #
	mov	di, ax			; di.low = row #

	;
	; Calculate the Chars that this key represents.
	;
	mov	bl, NUM_KEYS_PER_ROW
	mul	bl

	push	ds
	segmov	ds, dgroup, dx
	add	bp, ds:[firstKey]
	lea	dx, [bp]
	sub	bp, ds:[firstKey]


	add	dx, ax			; dx = Chars to draw

	;
	; Do nothing if this character is past the character at the last key.
	;
;	cmp	dx, LAST_KEY
	cmp	dx, ds:[lastKey]
	pop	ds

	ja	done

	;
	; Calculate the left co-ordinate of this key.
	;
	mov_tr	ax, bp			; al = column #
	mov	ah, KEY_WIDTH
	mul	ah
	add	ax, HORIZ_MARGIN	; ax = left co-ordinate of key

	;
	; Calculate the top co-ordinate of this key.
	;
	xchg	ax, di			; al = row #, di = left co-ordinate
	mov	ah, KEY_HEIGHT
	mul	ah
	add	ax, VERT_MARGIN		; ax = top co-ordinate of key
	mov_tr	bx, ax			; bx = top co-ordinate of key

	;
	; Keyclick.
	;
	mov	ax, SST_KEY_CLICK
	call	UserStandardSound

	;
	; Invert the key.
	;
	push	dx			; save Chars
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock	; ^hbp = GState
	pop	dx			; dx = Chars
	mov_tr	ax, di			; (ax, bx) = top left of key
	mov	si, sp			; si = non-zero to invert
	mov	di, bp			; ^hdi = GState
	call	FKDrawOneKey

	push	ax, dx, di		; save left co-ordinate, Chars, GState

	;
	; Send the key-press event to the flow object, so that it will go to
	; whichever app having the focus.
	;
if 0
	mov	ax, MSG_META_KBD_CHAR
endif
DBCS <	mov	cx, dx			; cx = Chars			>
SBCS <	mov	cl, dl			; cl = Chars			>
	call	SendChar
if 0
SBCS <	mov	ch, CS_BSW		; ch = CharacterSet		>
PrintMessage <A real floating keyboard should handle shift state.>

	mov	dx, (0 shl 8) or mask CF_FIRST_PRESS
					; dh = 0, no shift key in this keyboard
PrintMessage <Figure out how to determine ToggleState and scan code later.>
	clr	bp			; just set ToggleState and scan code\
					;  to 0 for now
	clr	di			; no need to call or fixup
	call	UserCallFlow
	;
	; Sleep for the duration of invert.  (Other threads can process the
	; keyboard event while we're sleeping.)
	;
	mov	ax, KEY_INVERT_DURATION
	call	TimerSleep

	;
	; Send the key-release event
	;
	mov	ax, MSG_META_KBD_CHAR
	mov	dl, mask CF_RELEASE
	clr	di
	call	UserCallFlow
endif
	pop	ax, dx, di		; ax = left co-ordinate of key, dx =
					;  Chars, ^hdi = GState

	;
	; Un-invert the key.
	;
	clr	si			; si = zero to not invert
	call	FKDrawOneKey

	call	GrDestroyState	

done:
	mov	ax, mask MRF_PROCESSED

	.leave
	ret
FKCMetaStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the text object's cursor

CALLED BY:	INTERNAL
PASS:		*ds:si	= instance data of FltKbdTextClass
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	7/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCursor	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Draw the cursor
	;
	mov	ax, MSG_VIS_CREATE_CACHED_GSTATES
	call	ObjCallInstanceNoLock

.warn -private
	mov	ax, MSG_VIS_TEXT_FLASH_CURSOR_OFF
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_TEXT_FLASH_CURSOR_ON
	call	ObjCallInstanceNoLock
.warn @private

	mov	ax, MSG_VIS_DESTROY_CACHED_GSTATES
	call	ObjCallInstanceNoLock

	.leave
	ret
DrawCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FKTVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the cursor is always drawn.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= FltKbdTextClass object
		ds:di	= FltKbdTextClass instance data
		ds:bx	= FltKbdTextClass object (same as *ds:si)
		es 	= segment of FltKbdTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	7/23/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FKTVisDraw	method dynamic FltKbdTextClass, 
					MSG_VIS_DRAW
	uses	ax, cx, dx, bp
	.enter

	;
	; Pass along to superclass so it can do the drawing
	;
	mov	di, offset FltKbdTextClass
	call	ObjCallSuperNoLock

	call	DrawCursor

	.leave
	ret
FKTVisDraw	endm
KbdCode	ends
