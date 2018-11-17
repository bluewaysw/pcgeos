
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
        This code handles the input routines of the game Minesweeper


RCS STAMP:
	$Id: input.asm,v 1.1 97/04/04 14:51:57 newdeal Exp $

------------------------------------------------------------------------------@

CommonCode	segment	resource	;start of code resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetGameLevel

DESCRIPTION:	sent when a game level is changed from previous 
		level. Changes size of minefield and calls
		MSG_MINE_START_NEW_GAME, then draws new minefield.

PASS:		*ds:si	= instance data of the object
		cx	= level to set to (0 - 3)

RETURN:		ds,si = same
 
CAN DESTROY:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		initial version

------------------------------------------------------------------------------@

X_Level		byte	10,16,30,36
Y_Level		byte	10,16,16,24
Mines_at_Level	byte	10,40,99,180
Tiles_to_Clear	word	90,216,381,684

SetGameLevel	method	MineFieldClass, MSG_MINE_SET_LEVEL

	mov	bx,cx
	shl	bx,1
	mov	bx,cx
	mov	al,cs:[Mines_at_Level][bx]	
	mov	ds:[di].MF_Mines, al		;set Total Mine #
	mov	ds:[di].MF_MinesLeft, al	;set Mines left
	mov	al,cs:[X_Level][bx]	
	mov	ds:[di].MF_Width, al		;MineField width
	sub	ah,ah
; again, we take advantage of the 16x16 bitmap size and shift Minefield
; coordinate 4 times to the left to get the document coordinate
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	ds:[di].VI_bounds.R_right,ax	;document sizing
	sub	ah,ah
	mov	al,cs:[Y_Level][bx]
	mov	ds:[di].MF_Height, al
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov 	ds:[di].VI_bounds.R_bottom, ax
	shl	bx,1
	mov	ax,cs:[Tiles_to_Clear][bx]
	mov	es:[TotTilesLeft],ax		;set tiles left 
	mov	es:[TilesLeft], ax		;set tiles left to clear
	mov 	al, ds:[di].MF_Width		
	mul 	ds:[di].MF_Height		;ax = Width X Height
	mov	es:[MineArraySize],ax

; Since the minefield attributes have been changed, we must now initialize
; a new minefield.  so send MSG_MINE_INITIALIZE to ourself.

	mov	ax, MSG_MINE_INITIALIZE
	call	ObjCallInstanceNoLock

; a new game is started, but we still have the old minefield on the screen
; so we must invalidate the geometry of the
; VisContent, and force a redraw

	mov	si, offset MineVisContent
	mov	ax, MSG_VIS_MARK_INVALID
	sub	ch,ch
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjCallInstanceNoLock

	GetResourceHandleNS	MineView,bx
	mov	si, offset MinePrimary
	mov 	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call 	ObjMessage

	ret

SetGameLevel	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	MineFieldLButtonClick

DESCRIPTION:	This method handles user input during game

PASS:		cx - Xposition of mouse
		dx - Yposition of mouse
		
RETURN:		ax - MouseReturnFlags
			mask MRF_PROCESSED
		ds,si,bp - same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		Initial Version
	jfh	5/16/00	added sound on/off check
------------------------------------------------------------------------------@

MineFieldLButtonClick	method	MineFieldClass, MSG_META_START_SELECT

	mov	bl,ds:[di].MF_GameState
	test	bl,GAME_OVER		;if game_over, no inputs allowed
	jz	1$
	jmp	99$
1$:	test	bl,NEW_GAME		;if new game, start timer
	jz	11$
	push	cx
	push	dx
	push	di
	mov	al,TIMER_EVENT_CONTINUAL
	mov	bx,ds:[LMBH_handle]
	mov	si,offset TheMineField
	mov	cx,60
	mov	dx,MSG_MINE_CLOCK
	mov	di,60
	call	TimerStart
	mov	es:[TimerID],ax		;store timer ID and Handle
	mov	es:[TimerHandle],bx
	pop	di
	pop	dx
	pop	cx
	mov	ds:[di].MF_GameState, GAME_ON	; turn game ON
11$:	and	cx,0ff0h		;shave off least significant bits
	and	dx,0ff0h
	push	cx
	push	dx			;save for invalidating 
	shr	cx,1			;convert Document coordinates to
	shr	cx,1			;mine coordinates
	shr	cx,1
	shr	cx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1			;cx and dx are Mine coordinates
	mov	es:[tmp_X],cl
	mov	es:[tmp_Y],dl
	sub	ah,ah
	mov	al,ds:[di].MF_Width	
	mov	es:[b_temp1],al		;temp1 = total width
	mul	dl			;width*height
	add	cx,ax			;now we have the mine index in CX
	sub	ah,ah
	mov	al,ds:[di].MF_Height	
	mov	es:[b_temp2],al		;temp2 = total height
	mov	bx,es:[MineArray]	
	call	MemLock			;Lock mine array
	push	ds
	mov	ds,ax
	mov	si,cx			;si points to Mine index
	test	{byte} ds:[si],MINE_EXPOSED	;exposed?
	jnz	2$			;exposed...  unlock and quit
	test	{byte} ds:[si],MINE_FLAGGED	;flagged?
	jnz	2$			;flagged...  unlock and quit
	jmp	3$

2$:	pop 	ax
	pop 	ax
	pop 	ax
	mov	bx, es:[MineArray]	;unlock memory
	call	MemUnlock
	jmp 	99$

; first, let's see if this one is a mine...

3$:	test	{byte} ds:[si],MINE_MASK1
	jz	6$
	test	{byte} ds:[si],MINE_MASK2
	jz	6$			

; Mine Hit! 	expose, play music - game over, man

	push dx
	push di
	push si
	push ds
	call MineCheckIfSoundOn
     pop  ds
	pop  si
	pop  di
	pop  dx
	jnc	NoHitSound
	mov	ax, SST_CUSTOM_SOUND
	mov	cx, es:[mineHitSoundHandle]
	call	UserStandardSound

NoHitSound:
	clr	ah
	mov	al,es:[b_temp1]
	mul	es:[b_temp2]
	mov	si,ax				; si = highest index 

4$:	dec	si				; loop thru all tiles

;all sorts of test here, see if flagged, see if mine underneath flag, etc!

	test	{byte} ds:[si],MINE_EXPOSED
	jnz	5$
	test	{byte} ds:[si],MINE_FLAGGED
	jnz	13$		
	test	{byte} ds:[si],MINE_MASK1
	jz	5$
	test	{byte} ds:[si],MINE_MASK2
	jz	5$
; if we have a flagged space or a mine, we want to expose it to the user

13$:	add	{byte} ds:[si],MINE_EXPOSED	
5$:	cmp	si,0
	jnz	4$

	pop	ds
	mov	bx,es:[MineArray]
	call	MemUnlock
	mov	ds:[di].MF_GameState, GAME_OVER	; set game status.

	mov	ax,MSG_VIS_VUP_CREATE_GSTATE	; get gstate of minefield
	mov	si,offset TheMineField	
	call 	ObjCallInstanceNoLock
	push	bp
	mov	ax,MSG_VIS_DRAW			; draw minefield
	call	ObjCallInstanceNoLock	
	pop	di
 	call	GrDestroyState
	clr	bx
	xchg	bx, es:[TimerHandle]
	mov	ax, es:[TimerID]
	call	TimerStop			; stop timer
	pop	ax
	pop	ax
	jmp	99$


; here below, we did not hit a mine

6$:	add	{byte} ds:[si],MINE_EXPOSED	;unexposed -> expose it
	mov	es:[counter],0		; count neighbors that are mines 
	mov	dl,2			;y offset
	sub	ah,ah
	sub	bh,bh

; We visit all our neighbor tiles and check to see whether they hold mines

10$:	dec	dl
	mov	cl,2			;x offset
20$:	dec	cl

; Heinous code to determine our neighbors (taking account of situations like
; whether we hit a corner tile, etc)

	mov	bl,es:[tmp_Y]
	add	bl,dl
	cmp	bl,-1
	jz	30$
	cmp	bl,es:[b_temp2]
	jz	30$			
	mov	bl,es:[tmp_X]
	add	bl,cl
	cmp	bl,-1
	jz	30$
	cmp	bl,es:[b_temp1]
	jz	30$
	mov	al,dl
	mul	es:[b_temp1]
	add	al,cl
	cbw	
	mov	bx,ax
	test	{byte} ds:[si][bx],MINE_MASK1
	jz	30$
	test	{byte} ds:[si][bx],MINE_MASK2
	jz	30$
	inc	es:[counter]		;neighbor is a mine, increment count
30$:	sub	bh,bh
	sub	ah,ah
	cmp	cl,-1
	jnz	20$
	cmp	dl,-1
	jnz	10$

; phew!  now store that count into our mine structure.

	mov	bx,es:[counter]
	add	ds:[si],bx
	pop	bx
	push	ds:[si]				;we only want to push byte
	mov	ds,bx
	mov	si, offset TheMineField
	mov	bx,es:[MineArray]
	call	MemUnlock

; if 0 mines nearby, expose all neighbors (recursion time)

	cmp	es:[counter],0
	jnz	85$

	mov	bx,2			;y offset
	sub	ah,ah
60$:	dec	bl
	mov	al,2			;x offset
70$:	dec	al

;again, heinous code to see whether we are on the edge or corner of field

	mov	cl,es:[tmp_Y]
	add	cl,bl
	cmp	cl,-1
	jz	80$
	cmp	cl,es:[b_temp2]
	jz	80$			
	mov	cl,es:[tmp_X]
	add	cl,al
	cmp	cl,-1
	jz	80$
	cmp	cl,es:[b_temp1]
	jz	80$
	push	ax
	add	al,es:[tmp_X]
;this time, we need to change to Document coordinates to call ourself
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	cx,ax
	mov	ax,bx
	add	al,es:[tmp_Y]
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	dx,ax
	push	bx
	sub	bh,bh
	mov	bl,es:[tmp_X]
	push	bx
	mov	bl,es:[tmp_Y]
	push	bx

	push	di
	mov	di, 700
	call	ThreadBorrowStackSpace
	mov	ax,MSG_META_START_SELECT
	call	ObjCallInstanceNoLock		;recursive call!
	call	ThreadReturnStackSpace
	pop	di

	pop	bx
	mov	es:[tmp_Y],bl			;restore state
	pop	bx
	mov	es:[tmp_X],bl
	pop	bx
	pop	ax
80$:	cmp	al,-1
	jnz	70$
	cmp	bl,-1
	jnz	60$

85$:	dec	es:[TilesLeft]			; check if game won
	cmp	es:[TilesLeft],0
	jnz	86$
	clr	bx
	xchg	bx,es:[TimerHandle]		; game won! Stop Timer
	mov	ax,es:[TimerID]
	call	TimerStop


	push dx
	push di
	push si
	push ds
	call MineCheckIfSoundOn
     pop  ds
	pop  si
	pop  di
	pop  dx
	jnc	NoWonSound
	mov	ax, SST_CUSTOM_SOUND
	mov	cx, es:[mineGameWonSoundHandle]
	call	UserStandardSound

NoWonSound:
	clr	ah
	mov	al,es:[b_temp1]
	mul	es:[b_temp2]
	mov	si,ax				; si = highest index 
	mov	bx,es:[MineArray]
	call	MemLock
	push	ds
	mov	ds,ax
90$:	dec	si				; loop thru all tiles
	test	{byte} ds:[si],MINE_MASK1
	jz	92$
	test	{byte} ds:[si],MINE_MASK2
	jz	92$
	test	{byte} ds:[si],MINE_FLAGGED
	jnz	92$		
	add	{byte} ds:[si],MINE_FLAGGED	; Flag the sucker!
92$:	cmp	si,0
	jnz	90$
	pop	ds
	mov	bx,es:[MineArray]
	call	MemUnlock
	mov	ds:[di].MF_GameState, GAME_OVER	; set game status.

	mov	ax,MSG_VIS_VUP_CREATE_GSTATE	; get gstate of minefield
	mov	si,offset TheMineField	
	call 	ObjCallInstanceNoLock
	push	bp
	mov	ax,MSG_VIS_DRAW			; draw minefield
	call	ObjCallInstanceNoLock	
	pop	di
 	call	GrDestroyState
	pop	ax
	pop	ax
	pop	ax
	movdw	dxcx,es:[Time]			; put score in dx:cx

	call	GetCurrentHighScoreControl
	mov	ax, MSG_HIGH_SCORE_ADD_SCORE
	clr	bp
	clr	di
	call	ObjMessage
	jmp	99$

; Below, we have to Draw the new tile... we do a direct draw instead of 
; invalidating the region, because it is faster and looks better...

86$:
	mov	ax,MSG_VIS_VUP_CREATE_GSTATE	;invalidation code
	mov	si,offset TheMineField
	call	ObjCallInstanceNoLock		;ax,cx,dx destroyed
	mov	di,bp			;^hdi = Gstate
	pop	bx			
	sub	bh,bh			; we popped a byte index
	shl	bx,1
	mov	si,cs:OffsetTable[bx]	
	pop	bx			; set (ax,bx) - (cx,dx) rect
	pop	ax
	push	ds
	push	cs
	pop	ds
	test	es:[GraphicsMode],VGA_COLOR	;video mode?
	jnz	91$
	mov	cx,ax				;if mono, we want to invalidate
	mov	dx,bx				;the rectangle because we need
	add	cx,16				;to clear the region first
	add	dx,16
	call	GrInvalRect
	jmp	98$
91$:	sub	dx,dx
	call	GrDrawBitmap
98$:	pop	ds
	call	GrDestroyState
99$:	mov	ax, mask MRF_PROCESSED	;return code
	ret

	
MineFieldLButtonClick 	endm


ONE_VOICE	=	1
MineGameWonSoundBuffer	segment	resource
		SimpleSoundHeader	ONE_VOICE
			ChangeEnvelope 	0, IP_DRAWBAR_ORGAN
			General		GE_SET_PRIORITY
			word		SP_GAME
			DeltaTick 	0
			VoiceOn		0, MIDDLE_C, FORTE
			DeltaTick	15
			VoiceOff	0
			DeltaTick	1
			VoiceOn		0, MIDDLE_C, FORTE
			DeltaTick	7
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, MIDDLE_G, FORTE
			DeltaTick	35
			VoiceOff	0
			DeltaTick	0
			General		GE_END_OF_SONG
MineGameWonSoundBuffer	ends

MineHitSoundBuffer	segment	resource
		SimpleSoundHeader	ONE_VOICE	
			ChangeEnvelope 	0, IP_DRAWBAR_ORGAN
			General		GE_SET_PRIORITY
			word		SP_GAME
			DeltaTick 	0
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	1
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	1
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	7
			VoiceOff	0
			DeltaTick	1
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, LOW_F, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, LOW_E, FORTE
			DeltaTick	7
			VoiceOff	0
			DeltaTick	1
			VoiceOn		0, LOW_E, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	7
			VoiceOff	0
			DeltaTick	1
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, LOW_D_b, FORTE
			DeltaTick	7
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, LOW_D, FORTE
			DeltaTick	20
			VoiceOff	0
			DeltaTick	0
			General		GE_END_OF_SONG
MineHitSoundBuffer	ends

MineFlagSoundBuffer	segment	resource
		SimpleSoundHeader	ONE_VOICE
			ChangeEnvelope	0, IP_TRUMPET
			General		GE_SET_PRIORITY
			word		SP_GAME
			DeltaTick	0
			VoiceOn		0, 400, FORTE
			DeltaTick	1
			VoiceOff	0
			DeltaTick	0
			VoiceOn		0, 600, FORTE
			DeltaTick	1
			VoiceOff	0
			DeltaTick	0
			General		GE_END_OF_SONG
MineFlagSoundBuffer	ends


COMMENT @----------------------------------------------------------------------

FUNCTION:	MineFieldRButtonClick

DESCRIPTION:	This method handles user input during game

PASS:		cx - Xposition of mouse
		dx - Yposition of mouse
		
RETURN:		ax - MouseReturnFlags
			mask MRF_PROCESSED
		ds,si,bp - same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	1/92		Initial Version
	jfh	5/16/00	added sound on/off check
------------------------------------------------------------------------------@
MineFieldRButtonClick	method	MineFieldClass, MSG_META_START_MOVE_COPY

	mov	bl,ds:[di].MF_GameState
	test	bl,GAME_OVER		; if game over, don't process
	jz	1$
	mov	ax,mask MRF_PROCESSED
	ret
1$:	and	cx,0fff0h		;shave off least significant bits
	and	dx,0fff0h
	push	cx
	push	dx			;save for invalidating 
	shr	cx,1			;Document coord -> Mine coord
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1
	shr	dx,1			;cx and dx are Mine coordinates
	mov	al,ds:[di].MF_Width	
	mul	dl			;width*height
	add	cx,ax			;now we have the mine index in CX
	mov	bx,es:[MineArray]	
	call	MemLock
	push	ds
	mov	ds,ax
	mov	si,cx				;si points to Mine index
	test 	{byte} ds:[si],MINE_FLAGGED	;was it already flagged?
	jnz	20$
	test	{byte} ds:[si],MINE_EXPOSED	;not flagged: exposed?
	jnz	89$				;exposed...  unlock and quit
	mov	bx,ds
	pop 	ds				;unexposed/unflagged	
	mov	al,ds:[di].MF_MinesLeft
	cmp	al,0
	jz	90$				;0 mines left displayed
	push	ds
	mov	ds,bx
	add	{byte} ds:[si],MINE_FLAGGED	
	pop	ds
	dec	ds:[di].MF_MinesLeft		;decrement mine count
	dec	al
	jmp	70$				;invalidate,unlock,and bail
20$:	sub	{byte} ds:[si],MINE_FLAGGED	;flagged -> unflag it
	pop	ds
	inc	ds:[di].MF_MinesLeft		;increment mine count
	mov	al,ds:[di].MF_MinesLeft
70$:	call 	UpdateMineDisplay		;display new count

	push dx
	push di
	push si
	push ds
	call MineCheckIfSoundOn
	pop  ds
	pop  si
	pop  di
	pop  dx
	jnc	NoFlagSound
	mov	ax, SST_CUSTOM_SOUND
	mov	cx, es:[mineFlagSoundHandle]
	call	UserStandardSound

NoFlagSound:
	mov	ax,MSG_VIS_VUP_CREATE_GSTATE	;invalidation code
	mov	si,offset TheMineField
	call	ObjCallInstanceNoLock		;ax,cx,dx destroyed
	mov	di,bp			;^hdi = Gstate
	pop	bx			; set (ax,bx) - (cx,dx) rect
	pop	ax
	mov	cx,16			;size of tile = 16x16
	mov	dx,16
	add	cx,ax
	add	dx,bx		
	call	GrInvalRect			;invalidate region
	call	GrDestroyState
	jmp	99$

89$:	pop	ds
90$:	pop	dx		
	pop	cx
99$:	mov	bx, es:[MineArray]	;unlock memory
	call	MemUnlock
	mov	ax, mask MRF_PROCESSED	;return code
	ret
	
MineFieldRButtonClick	endm

CommonCode	ends
