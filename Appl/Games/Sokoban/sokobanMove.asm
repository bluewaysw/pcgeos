COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Sokoban
FILE:		sokobanMove.asm

AUTHOR:		Steve Yegge, Jan  7, 1994

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_MAP_PLAYER_MOVE     Player moved using an arrow key or vi
				movement key.

    INT MovePlayerCommon        Figure out what kind of move it was.

    INT SetNextAndNextNextPositions 
				Set up nextPosition and nextNextPosition

    INT MoveBag                 Player moved a bag (saved or otherwise)

    INT MovePlayer              Player moved without pushing a bag.

    INT DoScreenUpdate          Draw the 3 squares on the screen that (may)
				have changed as a result of the move.

    INT ConvertPositionToPixels Given a map coordinate (in row, column
				form), return the pixel offsets for drawing
				the bitmap.  Note that they trade (ax <- x,
				bx <- y).

    INT SaveUndoStuff           saves some stuff in undoInfo so we can undo
				the move later

    INT ConvertArrayCoordinates Pass X & Y position in the array, returns
				an offset from the beginning of the array
				(viewed as 1d).

    INT ToggleLegs              Inverts the LEGS bit in the walkInfo
				variable.

    INT SetSafeFlag             Set WS_SAFE in es:[walkInfo]

    INT GetCorrectBitmapFromCharacter 
				Given a character, returns a bitmap

    INT GetUnanimatedBitmapFromCharacter 
				Given a character, returns a bitmap

    INT GetCorrectBitmapFromCharacterLow 
				Given a character, returns a bitmap

    INT GetPlayerBitmap         Get the appropriate player bitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 7/94		Initial revision

DESCRIPTION:

	Routines for moving & drawing the little man.

	$Id: sokobanMove.asm,v 1.1 97/04/04 15:12:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

;
;  Animation stuff.
;

videoMode	word
walkInfo	WalkState

udata	ends


CommonCode	segment	resource
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapPlayerMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Player moved using an arrow key or vi movement key.

CALLED BY:	MSG_MAP_PLAYER_MOVE

PASS:		*ds:si  = instance data
		es 	= dgroup
		cx	= MovementDirection

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapPlayerMove	method dynamic MapContentClass, 
					MSG_MAP_PLAYER_MOVE
	;		
	;  The actual code for moving the little guy is used by
	;  so many other routines that it's been moved into a
	;  common utility routine.
	;
		call	MovePlayerCommon

		ret
MapPlayerMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MovePlayerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out what kind of move it was.

CALLED BY:	MapPlayerMove, MapControlMove, MapShiftMove, MoveTheGuy

PASS:		*ds:si  = instance data
		es 	= dgroup
		cx	= MovementDirection

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

We have to handle the following cases:

	* bumped a wall					(no move)
	* tried to push a bag into a wall		(no move)
	* tried to push a bag into a bag		(no move)
	* tried to push a bag into a saved bag		(no move)
	* moved onto a regular ground spot
	* moved onto a safe spot
	* pushed a bag onto a ground spot
	* pushed a bag onto a safe spot
	* pushed a saved bag onto a safe spot
	* pushed a saved bag off of a safe spot

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	7/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovePlayerCommon	proc	near
		class	MapContentClass
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  Set up the walkInfo for animation purposes.
	;
CheckHack < offset WS_DIR eq 0 >

		andnf	es:[walkInfo], not mask WS_DIR	; clear it out first
		ornf	es:[walkInfo], cl		; set WS_DIR

		cmp	cx, MD_RIGHT
		jne	notRight

		ornf	es:[walkInfo], mask WS_FACE	; set the bit
		jmp	doneWalkInfo
notRight:
		cmp	cx, MD_LEFT
		jne	doneWalkInfo

		andnf	es:[walkInfo], not mask WS_FACE	; clear the bit
doneWalkInfo:
		call	ToggleLegs
	;
	;  Figure out what's happening with the squares that they're
	;  moving/pushing onto.
	;
		call	SetNextAndNextNextPositions
		LONG	jc	exit			; bumped a wall!
	;
	;  Finish updating the animation info by checking to see
	;  if the 1-away square is a safe spot.
	;
		call	SetSafeFlag			; nukes ax
	;
	;  Get the 1-away and 2-away bytes into al & dl respectively.
	;
		mov	al, {byte} es:[currentMap+(size MapHeader)][bx]
		mov	dl, {byte} es:[currentMap+(size MapHeader)][bp]
	;
	;  Now check if they're moving a bag into something.
	;  Note:  if we jump to done here, the carry will be clear
	;  as a result of the compare (operands were equal).
	;
		cmp	al, SST_BAG			; check 1-away square
		jne	noBag
		
		cmp	dl, SST_BAG
		je	done				; double-bag
		
		cmp	dl, SST_WALL_NSEW		; wall?
		ja	notWall				; bag-wall

		clc					; sigh.
		jmp	done
notWall:		
		cmp	dl, SST_SAFE_BAG
		je	done				; bag-savedbag
		
		cmp	dl, SST_SAFE			; bag-ground
		je	saveBag
	;
	;  First case of moving a bag:  just moving it.
	;
		call	MoveBag
		jmp	done
saveBag:
	;
	; If we got here, we were moving a bag onto a safe spot (which
	; is handled by MoveBag). 
	;
		call	MoveBag			; carry set if finished level
if PLAY_SOUNDS
	;
	;  If we finished the level, play a diddle, else play a doodle.
	;
		pushf
		jc	playLevel
		mov	cx, SS_SAVE_BAG
		jmp	playSound
playLevel:
		mov	cx, SS_FINISH_LEVEL
playSound:
		CallMod	SoundPlaySound
		popf
endif
		jmp	done
noBag:
	;
	;  They're not moving a bag.  Are they moving a saved bag?
	;
		cmp	al, SST_SAFE_BAG
		jne	reallyNoBag
		
		cmp	dl, SST_BAG
		je	done				; double-bag
		
		cmp	dl, SST_WALL_NSEW
		ja	notWall2			; bag-wall

		clc					; sigh.
		jmp	done
notWall2:
		cmp	dl, SST_SAFE_BAG
		je	done				; bag-savedbag
		
		cmp	dl, SST_SAFE			; bag-ground
		je	saveSavedBag
	;
	;  If we got here, we're moving a bag off of a safe spot (which
	;  is handled by MoveBag)
	;
		call	MoveBag				; destroys gstate
		jmp	done
saveSavedBag:
	;
	;  Second case of moving a saved bag:  moving onto safe spot
	;  (also handled by MoveBag)
	;
		call	MoveBag				; destroys gstate
		jmp	done
reallyNoBag:
	;
	;  They're not moving a bag, saved or otherwise.
	;
		call	MovePlayer			; nukes gstate
done:
	;
	;  If they finished the level, go to the next one.
	;  (carry flag will be set if they finished)
	;
		jnc	exit				; didn't finish level
		
		call	GeodeGetProcessHandle		; returns in bx
		mov	di, mask MF_CALL
		mov	ax, MSG_SOKOBAN_ADVANCE_LEVEL
		call	ObjMessage
exit:	
		.leave
		ret
MovePlayerCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNextAndNextNextPositions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up nextPosition and nextNextPosition

CALLED BY:	MovePlayerCommon

PASS:		es = dgroup
		cx = MovementDir

RETURN:		bx = offset into currentMap of next-position
		bp = offset into currentMap of next-next-position
		carry set if they hit a wall, clear if they didn't

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/13/94			extracted from MovePlayerCommon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNextAndNextNextPositions	proc	near
		uses	ax
		.enter
		
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
	;
	;  Depending on which way they moved, we have to inc or dec
	;  the x- or y-position to find the square they're trying to
	;  move to (i.e. nextPosition).
	;
		mov	bp, cx				; bp = MovementDir
		shl	bp
		mov	bp, cs:[dirTable1][bp]
		jmp	bp

dirTable1	nptr	\
		offset	up,
		offset	down,
		offset	right,
		offset	left
up:
		dec	ax
		jmp	fixedFirstCoordinates
down:
		inc	ax
		jmp	fixedFirstCoordinates
left:
		dec	bx
		jmp	fixedFirstCoordinates
right:
		inc	bx
		
fixedFirstCoordinates:
	;
	;  First save the computed next-position for later routines.
	;  Then convert to an offset into the map to get the byte.
	;
		mov	es:[nextPosition].P_x, bx
		mov	es:[nextPosition].P_y, ax
		call	ConvertArrayCoordinates		; bx = offset
	;
	;  Check if they bumped into a wall, and if so, quit.
	;
		mov	al, {byte} es:[currentMap+(size MapHeader)][bx]
		cmp	al, SST_WALL_NSEW		; a wall?
		ja	noBump				; didn't bump a wall

		stc					; skip adv-level check
		jmp	exit
noBump:
	;
	;  To check the other no-move possibilities, we have to know
	;  what the next-next position is.  We do the same checking
	;  as before, but starting with nextPosition, not position.
	;
		push	bx				; save 1-away offset
		mov	bx, es:[nextPosition].P_x
		mov	ax, es:[nextPosition].P_y
		
		mov	bp, cx
		shl	bp
		mov	bp, cs:[dirTable2][bp]		; bp = table index
		jmp	bp

dirTable2	nptr	\
		offset	up2,
		offset	down2,
		offset	right2,
		offset	left2
left2:
		dec	bx				; decrement x-value
		jmp	fixedSecondCoordinates
right2:
		inc	bx				; increment x-value
		jmp	fixedSecondCoordinates
up2:
		dec	ax				; decrememt y-value
		jmp	fixedSecondCoordinates
down2:
		inc	ax				; increment y-value
		
fixedSecondCoordinates:
	;
	;  Save the nextNextPosition, as we did with nextPosition before.
	;
		mov	es:[nextNextPosition].P_x, bx
		mov	es:[nextNextPosition].P_y, ax
		call	ConvertArrayCoordinates		; bx = offset 2
	;
	;  Return the offsets in the promised registers.
	;
		mov	bp, bx				; bp = 2-away offset
		pop	bx				; bx = 1-away offset

		clc					; return no walls hit
exit:
		.leave
		ret
SetNextAndNextNextPositions	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveBag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Player moved a bag (saved or otherwise)

CALLED BY:	MapPlayerMove

PASS:		es = dgroup
		si = gstate to draw through

		es:[currentMap].M_header.MH_position, es:[nextPosition] and es:[nextNextPosition]
		must all be pre-initialized.

RETURN:		carry set if they finished the level, clear otherwise
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

	- increment moves & pushes
	- point es:[di] to the map data
	- get the byte from the current position (where they're standing
	  before the move).
	- figure out if they're moving off ground or a safe spot
	- get the byte from the next position (the bag)
	- if it's a saved bag, the player's moving onto a safe spot
	  Additionally, we store the fact that it's a saved bag in bp,
	  so that we can decide what to do with the 'saved' variable.
	- get the byte from the nextNextPosition (where the bag's going).
	- deal with 'saved':
		* if it was saved bag to safe spot, no change
		* if it was normal bag to ground, no change
		* if it was saved bag to ground, decrement 'saved'
		* if it was normal bag to safe spot, increment 'saved'
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveBag	proc	near
	;
	;  Animation stuff...
	;
		ornf	es:[walkInfo], mask WS_PUSH
	;
	;  Save the current state of things so they can undo stuff,
	;  and dirty the vm file so we can enable saving the game
	;
if DOCUMENT_CONTROL
		call	DirtyTheSavedGame
endif
		call	SaveUndoStuff
		ornf	es:[gameState], mask SGS_CAN_UNDO or \
					mask SGS_MOVED_BAG
		andnf	es:[gameState], not (mask SGS_SAVED_BAG or \
						mask SGS_UNSAVED_BAG)
		inc	es:[moves]
		inc	es:[pushes]
	;
	;  Update the status bar
	;
		call	UpdateMovesData
		call	UpdatePushesData
		
		mov	ax, MSG_GEN_SET_ENABLED
		call	EnableUndoTrigger
		call	EnableRestoreTrigger
	;
	;  Update the currentMap first (screen later).  Start by
	;  updating the space they're moving off of.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		
		cmp	al, SST_SAFE_PLAYER
		jne	notSafePlayer
		
		mov	{byte} es:[currentMap + (size MapHeader)][bx], SST_SAFE
		jmp	donePosition
notSafePlayer:
		mov	{byte} es:[currentMap+(size MapHeader)][bx], SST_GROUND
donePosition:
	;
	;  Now do the nextPosition (what they're moving onto). 
	;
		mov	bx, es:[nextPosition].P_x
		mov	ax, es:[nextPosition].P_y
		
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		
		cmp	al, SST_SAFE_BAG
		jne	notSavedBag
		
		mov	bp, 1				; pushed a saved bag
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
					SST_SAFE_PLAYER
		jmp	doneNextPosition
notSavedBag:
		mov	bp, 0				; pushed a normal bag
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
					SST_PLAYER
doneNextPosition:
	;
	;  Finally do the nextNextPosition
	;
		mov	bx, es:[nextNextPosition].P_x
		mov	ax, es:[nextNextPosition].P_y
		
		call	ConvertArrayCoordinates
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		
		cmp	al, SST_SAFE
		jne	notSafeSpot
	;
	;  We pushed the bag onto a safe spot.  Was it a saved bag?
	;
		tst	bp				; saved bag?
		jnz	noIncrement			; yep.  no change.
		
		inc	es:[currentMap].M_header.MH_saved
		BitSet	es:[gameState], SGS_SAVED_BAG
		call	UpdateSavedData			; updates the status bar
noIncrement:
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
					SST_SAFE_BAG
		jmp	doScreenUpdate	
notSafeSpot:
	;
	;  We pushed a bag onto the ground.  Was it a saved bag?
	;	
		tst	bp				; saved bag?
		jz	noDecrement			; nope.  no change.
		
		dec	es:[currentMap].M_header.MH_saved
		BitSet	es:[gameState], SGS_UNSAVED_BAG
		call	UpdateSavedData
noDecrement:
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
					SST_BAG
doScreenUpdate:
		call	DoScreenUpdate			; draw the pictures
	;
	;  Move es:[currentMap].M_header.MH_position to the new (post-move) position.
	;
		mov	ax, es:[nextPosition].P_x
		mov	es:[currentMap].M_header.MH_position.P_x, ax
		mov	ax, es:[nextPosition].P_y
		mov	es:[currentMap].M_header.MH_position.P_y, ax
	;
	;  see if they've advanced a level -- set carry if they did
	;
		mov	al, es:[currentMap].M_header.MH_packets
		cmp	al, es:[currentMap].M_header.MH_saved
		je	finishedLevel
		
		clc					; didn't finish
		jmp	done
finishedLevel:
		stc					; finished
done:
		ret
MoveBag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MovePlayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Player moved without pushing a bag.

CALLED BY:	MapPlayerMove

PASS:		es = dgroup
		si = gstate to draw through

RETURN:		carry clear (meaning they couldn't have finished a level
		just by moving...they would have had to move a bag).

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

	- this one's similar to MoveBag (see above), except that:

		* only deal with position and nextPosition
		* don't increment es:[pushes]
		* don't worry about es:[currentMap].M_header.MH_saved

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovePlayer	proc	near
		.enter
	;
	;  Setup work... (mostly for undo)
	;
		andnf	es:[walkInfo], not mask WS_PUSH
if DOCUMENT_CONTROL
		call	DirtyTheSavedGame
endif
		
	;	call	SaveUndoStuff

	;	ornf	es:[gameState], mask SGS_CAN_UNDO
		andnf	es:[gameState], not (mask SGS_MOVED_BAG or \
						mask SGS_SAVED_BAG or \
						mask SGS_UNSAVED_BAG)
		inc	es:[moves]
		
		mov	ax, MSG_GEN_SET_ENABLED
	;	call	EnableUndoTrigger
		call	EnableRestoreTrigger
	;
	;  Update the status bar
	;
		call	UpdateMovesData
	;
	;  Update the currentMap first (screen later).  Start by
	;  updating the space off which they're moving.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		
		cmp	al, SST_SAFE_PLAYER
		jne	notSafePlayer
		
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
				SST_SAFE
		jmp	donePosition		; moved off safe spot
notSafePlayer:
	;
	;  The space we're moving off of was a regular player, so it
	;  will turn into a "ground" spot.
	;
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
				SST_GROUND
donePosition:
	;
	;  Figure out where they're moving, and deal with it.
	;
		mov	bx, es:[nextPosition].P_x
		mov	ax, es:[nextPosition].P_y
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		
		cmp	al, SST_GROUND
		jne	notGround
		
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
					SST_PLAYER
		jmp	doScreenUpdate
notGround:
	;
	;  They're not moving onto a ground square, and since we've
	;  already determined that it's a legal move, they must be
	;  moving to a "safe" spot.  So put a safe-player character
	;  in the map.
	;
		mov	{byte} es:[currentMap + (size MapHeader)][bx], \
					SST_SAFE_PLAYER
doScreenUpdate:
		call	DoScreenUpdate
	;
	;  Move es:[currentMap].M_header.MH_position to the
	;  new (post-move) position.
	;
		mov	ax, es:[nextPosition].P_x
		mov	es:[currentMap].M_header.MH_position.P_x, ax
		mov	ax, es:[nextPosition].P_y
		mov	es:[currentMap].M_header.MH_position.P_y, ax

		clc					; didn't finish level

		.leave
		ret
MovePlayer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the 3 squares on the screen that (may) have changed
		as a result of the move.

CALLED BY:	MoveBag, MovePlayer

PASS:		es = dgroup

		es:[gstate]
		es:[currentMap].M_header.MH_position		
		es:[nextPosition]		= initialized
		es:[nextNextPosition]	
		es:[currentMap]

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/ 2/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoScreenUpdate	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  See if we have a gstate to draw to...
	;
		mov	di, es:[gstate]			; di <- gstate
		tst	di
EC <		ERROR_Z	NO_GSTATE_AVAILABLE_FOR_DRAWING			>
NEC <		jz	done						>

		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax				; ds = bitmap block
	;
	;  Update es:[currentMap].M_header.MH_position onscreen.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		push	ax, bx
		call	ConvertArrayCoordinates
		mov	bl, {byte} es:[currentMap + (size MapHeader)][bx]
		call	GetCorrectBitmapFromCharacter	; ds:si = bitmap
		pop	ax, bx
		call	ConvertPositionToPixels		; fixes ax & bx for draw
		clr	dx				; no callback
		call	GrDrawBitmap
	;
	;  Update es:[nextPosition] onscreen.
	;
		mov	bx, es:[nextPosition].P_x
		mov	ax, es:[nextPosition].P_y
		push	ax, bx
		call	ConvertArrayCoordinates
		mov	bl, {byte} es:[currentMap + (size MapHeader)][bx]
		call	GetCorrectBitmapFromCharacter	; ds:si = bitmap
		pop	ax, bx
		call	ConvertPositionToPixels		; fixes ax & bx for draw
		call	GrDrawBitmap
	;
	;  Update es:[nextNextPosition] onscreen.
	;
		mov	bx, es:[nextNextPosition].P_x
		mov	ax, es:[nextNextPosition].P_y
		push	ax, bx
		call	ConvertArrayCoordinates
		mov	bl, {byte} es:[currentMap + (size MapHeader)][bx]
		call	GetCorrectBitmapFromCharacter	; ds:si = bitmap
		pop	ax, bx
		call	ConvertPositionToPixels		; fixes ax & bx for draw
		call	GrDrawBitmap
		call	CenterIcon
	;
	;  Unlock the Bitmaps resource.
	;
		mov	bx, handle Bitmaps
		call	MemUnlock
done::
		.leave
		ret
DoScreenUpdate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPositionToPixels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a map coordinate (in row, column form), return the
		pixel offsets for drawing the bitmap.  Note that they
		trade (ax <- x, bx <- y).

CALLED BY:	MovePlayer, MoveBag

PASS:		bl = x (column)
		al = y (row)
		es = dgroup

RETURN:		bx = y (pixels)
		ax = x (pixels)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	x = x * bitmapWidth + startX
	y = y * bitmapHeight + startY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPositionToPixels	proc	near
		uses	cx, dx
		.enter
	;
	;  Do Y.
	;
		push	bx			; save column
		mov	dx, es:[bitmapHeight]
		mul	dl			; ax = y offset
		mov_tr	bx, ax			; bx = y offset
	;
	;  Do X.
	;
		pop	ax			; restore column
		mov	dx, es:[bitmapWidth]
		mul	dl			; ax = x offset
		
		.leave
		ret
ConvertPositionToPixels	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveUndoStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	saves some stuff in undoInfo so we can undo the move later

CALLED BY:	MovePlayer, MoveBag

PASS:		es = dgroup
		position, nextPosition and nextNextPosition initialized

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Save the position and value of the 3 bytes in the map before
	the move.  (yes, MovePlayer only results in 2 bytes being
	changed, but we're into re-using code here).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveUndoStuff	proc	near
		uses	cx,si,di,ds
		.enter
	;
	;  Save their number of moves.
	;
		mov	bx, es:[moves]
		mov	es:[undoInfo].US_moves, bx
	;
	;  Save pos1 and SokobanSquareType at that position.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	es:[undoInfo].US_pos1.P_x, bx
		
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		mov	es:[undoInfo].US_pos1.P_y, ax
		
		call	ConvertArrayCoordinates
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		mov	es:[undoInfo].US_square1, al
	;
	;  Save pos2 and SokobanSquareType at that position.
	;
		mov	bx, es:[nextPosition].P_x
		mov	es:[undoInfo].US_pos2.P_x, bx
		
		mov	ax, es:[nextPosition].P_y
		mov	es:[undoInfo].US_pos2.P_y, ax
		
		call	ConvertArrayCoordinates
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		mov	es:[undoInfo].US_square2, al
	;
	;  Save pos3 and SokobanSquareType at that position.
	;
		mov	bx, es:[nextNextPosition].P_x
		mov	es:[undoInfo].US_pos3.P_x, bx
		
		mov	ax, es:[nextNextPosition].P_y
		mov	es:[undoInfo].US_pos3.P_y, ax
		
		call	ConvertArrayCoordinates
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
		mov	es:[undoInfo].US_square3, al
		
		.leave
		ret
SaveUndoStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapUndoMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to undo their foolishness.

CALLED BY:	MSG_MAP_UNDO_MOVE

PASS:		es = dgroup
		*ds:si = MapContent object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if they can't undo from here, quit
	- get the undo-bytes and move them into the map
	- update animation record

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapUndoMove	method		MapContentClass, 
						MSG_MAP_UNDO_MOVE
		uses	ax,cx,dx,bp
		.enter
	;
	;  Just quit if they're not allowed to undo the move.
	;
		test	es:[gameState], mask SGS_CAN_UNDO
		LONG	jz	done
	;
	;  Don't allow them to undo 2 moves in a row.
	;
		BitClr	es:[gameState], SGS_CAN_UNDO
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	EnableUndoTrigger
	;
	;  Start the screen update by erasing the place where
	;  they're currently standing.
	;
		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax

		movdw	axbx, es:[currentMap].M_header.MH_position
		push	ax, bx				; save position
		call	ConvertArrayCoordinates
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]
	;
	;  If it's a player, change to a ground.  If it's a safe player,
	;  change to a safe spot.
	;
		cmp	al, SST_PLAYER
		je	player
		mov	al, SST_SAFE			; safe player
		jmp	gotType
player:
		mov	al, SST_GROUND
gotType:
		mov	{byte} es:[currentMap + (size MapHeader)][bx], al
		mov_tr	bl, al				; bl = SokobanSquareType
		call	GetCorrectBitmapFromCharacter	; ds:si = bitmap
		pop	ax, bx				; restore position
		call	ConvertPositionToPixels		; fixes ax & bx for draw
		clr	dx				; no callback
		mov	di, es:[gstate]
		tst	di
		jz	noDraw

		call	GrDrawBitmap
		mov	bx, handle Bitmaps
		call	MemUnlock
noDraw:
	;
	;  Update the currentMap.
	;
		movdw	es:[currentMap].M_header.MH_position, es:[undoInfo].US_pos1, ax
		movdw	axbx, es:[currentMap].M_header.MH_position	; bx = x, ax = y
		call	ConvertArrayCoordinates		; bx = offset
		mov	al, es:[undoInfo].US_square1	; al = SokobanSquareType
		mov	{byte} es:[currentMap + (size MapHeader)][bx], al
		
		movdw	es:[nextPosition], es:[undoInfo].US_pos2, ax
		movdw	axbx, es:[nextPosition]		; bx = x, ax = y
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, es:[undoInfo].US_square2	; al = SokobanSquareType
		mov	{byte} es:[currentMap + (size MapHeader)][bx], al
		
		movdw	es:[nextNextPosition], es:[undoInfo].US_pos3, ax
		movdw	axbx, es:[nextNextPosition]	; bx = x, ax = y
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, es:[undoInfo].US_square3	; al = SokobanSquareType
		mov	{byte} es:[currentMap + (size MapHeader)][bx], al
	;
	;  Update animation stuff.  The WS_PUSH, WS_DIR and WS_FACE
	;  bits will remain unchanged through the undo, but the WS_LEGS bit
	;  needs to invert, and the WS_SAFE bit has to be updated.
	;  We examine the SquareType at US_square1 and see if it's a player
	;  or a safe player, and set the WS_SAFE bit accordingly.
	;
		cmp	{byte} es:[undoInfo].US_square1, SST_PLAYER
		jne	setSafeBit

		andnf	es:[walkInfo], not mask WS_SAFE
		jmp	gotSafeBit
setSafeBit:
		ornf	es:[walkInfo], mask WS_SAFE
gotSafeBit:
		call	ToggleLegs
	;
	;  Finish the screen update as with a regular move.
	;
		call	DoScreenUpdate
	;
	;  Update globals & the status bar
	;
		mov	bx, es:[undoInfo].US_moves
		mov	es:[moves], bx
		call	UpdateMovesData
		
		test	es:[gameState], mask SGS_MOVED_BAG
		jz	didntMoveBag
		
		dec	es:[pushes]
		call	UpdatePushesData
didntMoveBag:
		test	es:[gameState], mask SGS_SAVED_BAG
		jz	didntSaveBag
		
		dec	es:[currentMap].M_header.MH_saved
		call	UpdateSavedData
didntSaveBag:
	;
	;  In case this one isn't clear...if we pushed a bag off of
	;  a safe spot, it got "unsaved".  We keep that information
	;  so that here, in the Undo code, if they "unsaved" the
	;  bag in the move we're undoing, we "re-save" it by incrementing
	;  the number of saved bags (and the displayed number).
	;
		test	es:[gameState], mask SGS_UNSAVED_BAG
		jz	didntUnsaveBag
		
		inc	es:[currentMap].M_header.MH_saved
		call	UpdateSavedData
didntUnsaveBag:
done:
		.leave
		ret
MapUndoMove	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertArrayCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass X & Y position in the array, returns an offset from
		the beginning of the array (viewed as 1d).

CALLED BY:	UTILITY

PASS:		bx = x
		ax = y

RETURN:		bx = offset  (as in es:[di][bx])
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

	offset	= columns * (y) + (x)		(because it's zero-indexed)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertArrayCoordinates	proc	near
		uses	cx
		.enter
		
		mov	cl, MAX_COLUMNS
		mul	cl
		add	ax, bx
		mov_tr	bx, ax
		
		.leave
		ret
ConvertArrayCoordinates		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToggleLegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts the LEGS bit in the walkInfo variable.

CALLED BY:	UTILITY

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToggleLegs	proc	near

		test	es:[walkInfo], mask WS_LEGS
		jz	set
clear::
		andnf	es:[walkInfo], not mask WS_LEGS
		jmp	done
set:
		ornf	es:[walkInfo], mask WS_LEGS
done:
		ret
ToggleLegs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSafeFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set WS_SAFE in es:[walkInfo]

CALLED BY:	MovePlayerCommon

PASS:		es = dgroup
		bx = offset to 1-away byte in currentMap

RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:
	well...

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSafeFlag	proc	near
		.enter

		mov	al, {byte} es:[currentMap+(size MapHeader)][bx]

		cmp	al, SST_SAFE
		je	safe

		cmp	al, SST_SAFE_PLAYER
		je	safe

		cmp	al, SST_SAFE_BAG
		je	safe
notSafe::
		andnf	es:[walkInfo], not mask WS_SAFE		
		jmp	done	
safe:
		ornf	es:[walkInfo], mask WS_SAFE
done:
		.leave
		ret
SetSafeFlag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCorrectBitmapFromCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a character, returns a bitmap

CALLED BY:	MapContentVisDraw

PASS:		ds = bitmaps segment
		es = dgroup
		bl = SokobanSquareType

RETURN:		si = offset of the bitmap (ffffh if invalid)
		carry set if no match found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- use the walkInfo record to index a big table if it's a
	  player bitmap.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	- if we're in CGA mode, we call a different routine, since
	  animation's not supported in CGA yet.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCorrectBitmapFromCharacter		proc	near
		mov	si, BW_TRUE		; use animation
		GOTO	GetCorrectBitmapFromCharacterLow
GetCorrectBitmapFromCharacter		endp

if LEVEL_EDITOR
GetUnanimatedBitmapFromCharacter	proc	near
		mov	si, BW_FALSE		; don't use animation
		GOTO	GetCorrectBitmapFromCharacterLow
GetUnanimatedBitmapFromCharacter	endp
endif

GetCorrectBitmapFromCharacterLow	proc	near
		uses	ax, bx, di
		.enter
	;
	;  Exit if bx is garbage.
	;
		clr	bh			; bx = SokobanSquareType
		cmp	bx, SokobanSquareType
		jbe	typeOK
		stc				; error!
		jmp	done
typeOK:
	;
	;  If it's a player, do something special (animation), if
	;  the animation flag is set.
	;
		tst	si
		jz	notPlayer
		cmp	bx, SST_PLAYER
		je	player
		cmp	bx, SST_SAFE_PLAYER
		jne	notPlayer
player:
	;
	;  If it's CGA, use the normal table (animation's not supported).
	;
		cmp	es:[videoMode], SVM_CGA
		je	notPlayer

		call	GetPlayerBitmap		; si = bitmap offset
		jmp	done
notPlayer:
	;  BX is a valid SokobanSquareType (but not a player).  To
	;  get the right offset in the table (which is a 2D array)
	;  we need (video mode) + (bx * number of "columns").  The
	;  "columns" are the entries for each video mode, so there
	;  are as many columns as entries in the video-mode etype.
	
		mov	di, es:[videoMode]

		mov	al, NUM_VIDEO_MODES * 2	; (word-sized entries)
		mul	bl			; ax = SokobanSquareType
		mov_tr	bx, ax			; use as index

		mov	si, cs:[bitmapTable][bx][di]

		clc
done:

EC <		lahf							>
EC <		cmp	si, 0ffffh					>
EC <		ERROR_E	REQUESTED_INVALID_BITMAP			>
EC <		sahf							>

		mov	si, ds:[si]			; deref chunk
		.leave
		ret

bitmapTable	word	\
	offset	cgaWallBitmap,		; cga  
	offset	wallBitmap,		; mono 
	offset	wallBitmap,		; vga  

	offset	cgaWallBitmap,		; cga  
	offset	wall_E_Bitmap,		; mono 
	offset	wall_E_Bitmap,		; vga  
	
	offset	cgaWallBitmap,		; cga  
	offset	wall_W_Bitmap,		; mono 
	offset	wall_W_Bitmap,		; vga  

	offset	cgaWallBitmap,		; cga
	offset	wall_EW_Bitmap,		; mono
	offset	wall_EW_Bitmap,		; vga
		
	offset	cgaWallBitmap,		; cga
	offset	wall_S_Bitmap,		; mono
	offset	wall_S_Bitmap,		; vga

	offset	cgaWallBitmap,		; cga
	offset	wall_SE_Bitmap,		; mono
	offset	wall_SE_Bitmap,		; vga

	offset	cgaWallBitmap,		; cga
	offset	wall_SW_Bitmap,
	offset	wall_SW_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_SEW_Bitmap,
	offset	wall_SEW_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_N_Bitmap,
	offset	wall_N_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NE_Bitmap,
	offset	wall_NE_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NW_Bitmap,
	offset	wall_NW_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NEW_Bitmap,
	offset	wall_NEW_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NS_Bitmap,
	offset	wall_NS_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NSE_Bitmap,
	offset	wall_NSE_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NSW_Bitmap,
	offset	wall_NSW_Bitmap,

	offset	cgaWallBitmap,		; cga
	offset	wall_NSEW_Bitmap,
	offset	wall_NSEW_Bitmap,

	offset	cgaPlayerBitmap,	; SVM_CGA
	offset	ml1,			; SVM_MONO
	offset	vl1,			; SVM_VGA

	offset	cgaSafePlayerBitmap,	; SVM_CGA
	offset	ml1s,			; SVM_MONO
	offset	vl1s,			; SVM_VGA

	offset	cgaPacketBitmap,	; SVM_CGA
	offset	monoPacketBitmap,	; SVM_MONO
	offset	vgaPacketBitmap,	; SVM_VGA

	offset	cgaSafePacketBitmap,	; SVM_CGA
	offset	monoSafePacketBitmap,	; SVM_MONO
	offset	vgaSafePacketBitmap,	; SVM_VGA
	
	offset	cgaGrassBitmap,		; SVM_CGA
	offset	monoGroundBitmap,	; SVM_MONO
	offset	vgaGroundBitmap,	; SVM_VGA
		
	offset	cgaGrassBitmap,		; SVM_CGA
	offset	vgaGrassBitmap,		; SVM_MONO
	offset	vgaGrassBitmap,		; SVM_VGA
		
	offset	cgaSafeBitmap,		; SVM_CGA
	offset	monoSafeBitmap,		; SVM_MONO
	offset	vgaSafeBitmap		; SVM_VGA

GetCorrectBitmapFromCharacterLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPlayerBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the appropriate player bitmap

CALLED BY:	GetCorrectBitmapFromCharacter

PASS:		es = dgroup
		bl = SokobanSquareType

RETURN:		si = offset of bitmap  (0ffffh if invalid)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

  We use semi-meaningful abbreviations for the bitmap labels.
  The abbreviations are composed of the symbols below:

	m = monochrome
	v = color
	l = facing left
	r = facing right
	1 = legs together
	2 = legs apart
	u = pushing up
	d = pushing down
	l = pushing left (in last position)
	r = pushing right (in last position)
	s = standing on safe spot

  So:

	ml1 = Monochrome Guy, facing left, legs together

	vr2us = Color Guy, facing right, legs apart, pushing up, on safe spot.

  Nothing could be simpler, eh? :-)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPlayerBitmap	proc	near
		uses	bx
		.enter
	;
	;  The record walkInfo is all set up...just shift and index.
	;
		mov	bl, es:[walkInfo]
		clr	bh
		shl	bx				; word-sized table
		mov	si, cs:[playerTable][bx]

		.leave
		ret
	;
	;  The Table.  The heirarchy goes:
	;
	;  Mono
	;
	;    Left
	;
	;      Ground
	;
	;        Together
	;
	;          NoPush
	;
	;            N, S, E, W
	;
	;	   Push
	;
	;	 Apart
	;
	;      Safe
	;
	;    Right
	;
	;  VGA
	;
	;   ...
	;
	;
	;  In each block of 8 entries, 2 are unused (they correspond
	;  to face-left push-right and face-right push-left combos),
	;  and 3 are duplicates (walking north or south uses whatever
	;  left/right-facing bitmap was used last).  So there are 128
	;  entries in the table for only 64 bitmaps, but this will
	;  change when we implement masked bitmaps and flipping the
	;  pictures.
	;
	;  The unused entries are 0ffffh's and should never be reached.
	;
					; uVFS LPwd (NSEW)
playerTable	word	\
offset ml1,				; 0000 0000 N
offset ml1,				; 0000 0001 S
0ffffh,					; 0000 0010 E
offset ml1,				; 0000 0011 W
offset ml1u,				; 0000 0100 N
offset ml1d,				; 0000 0101 S
0ffffh,					; 0000 0110 E
offset ml1l,				; 0000 0111 W

offset ml2,				; 0000 1000
offset ml2,				; 0000 1001
0ffffh,					; 0000 1010
offset ml2,				; 0000 1011
offset ml2u,				; 0000 1100
offset ml2d,				; 0000 1101
0ffffh,					; 0000 1110
offset ml2l,				; 0000 1111
 
offset ml1s,				; 0001 0000
offset ml1s,				; 0001 0001
0ffffh,					; 0001 0010
offset ml1s,				; 0001 0011
offset ml1us,				; 0001 0100
offset ml1ds,				; 0001 0101
0ffffh,					; 0001 0110
offset ml1ls,				; 0001 0111
 
offset ml2s,				; 0001 1000
offset ml2s,				; 0001 1001
0ffffh,					; 0001 1010
offset ml2s,				; 0001 1011
offset ml2us,				; 0001 1100
offset ml2ds,				; 0001 1101
0ffffh,					; 0001 1110
offset ml2ls,				; 0001 1111
					 	
offset mr1,				; 0010 0000	
offset mr1,				; 0010 0001
offset mr1,				; 0010 0010
0ffffh,					; 0010 0011
offset mr1u,				; 0010 0100
offset mr1d,				; 0010 0101
offset mr1r,				; 0010 0110
0ffffh,					; 0010 0111
 
offset mr2,				; 0010 1000
offset mr2,				; 0010 1001
offset mr2,				; 0010 1010
0ffffh,					; 0010 1011
offset mr2u,				; 0010 1100
offset mr2d,				; 0010 1101
offset mr2r,				; 0010 1110
0ffffh,					; 0010 1111
 
offset mr1s,				; 0011 0000
offset mr1s,				; 0011 0001
offset mr1s,				; 0011 0010
0ffffh,					; 0011 0011
offset mr1us,				; 0011 0100
offset mr1ds,				; 0011 0101
offset mr1rs,				; 0011 0110
0ffffh,					; 0011 0111
 
offset mr2s,				; 0011 1000
offset mr2s,				; 0011 1001
offset mr2s,				; 0011 1010
0ffffh,					; 0011 1011
offset mr2us,				; 0011 1100
offset mr2ds,				; 0011 1101
offset mr2rs,				; 0011 1110
0ffffh,					; 0011 1111
 
offset vl1,				; 0100 0000
offset vl1,				; 0100 0001
0ffffh,					; 0100 0010
offset vl1,				; 0100 0011
offset vl1u,				; 0100 0100
offset vl1d,				; 0100 0101
0ffffh,					; 0100 0110
offset vl1l,				; 0100 0111
 
offset vl2,				; 0100 1000
offset vl2,				; 0100 1001
0ffffh,					; 0100 1010
offset vl2,				; 0100 1011
offset vl2u,				; 0100 1100
offset vl2d,				; 0100 1101
0ffffh,					; 0100 1110
offset vl2l,				; 0100 1111
 
offset vl1s,				; 0101 0000
offset vl1s,				; 0101 0001
0ffffh,					; 0101 0010
offset vl1s,				; 0101 0011
offset vl1us,				; 0101 0100
offset vl1ds,				; 0101 0101
0ffffh,					; 0101 0110
offset vl1ls,				; 0101 0111
 
offset vl2s,				; 0101 1000
offset vl2s,				; 0101 1001
0ffffh,					; 0101 1010
offset vl2s,				; 0101 1011
offset vl2us,				; 0101 1100
offset vl2ds,				; 0101 1101
0ffffh,					; 0101 1110
offset vl2ls,				; 0101 1111
 
offset vr1,				; 0110 0000
offset vr1,				; 0110 0001
offset vr1,				; 0110 0010
0ffffh,					; 0110 0011
offset vr1u,				; 0110 0100
offset vr1d,				; 0110 0101
offset vr1r,				; 0110 0110
0ffffh,					; 0110 0111

offset vr2,				; 0110 1000
offset vr2,				; 0110 1001
offset vr2,				; 0110 1010
0ffffh,					; 0110 1011
offset vr2u,				; 0110 1100
offset vr2d,				; 0110 1101
offset vr2r,				; 0110 1110
0ffffh,					; 0110 1111

offset vr1s,				; 0111 0000
offset vr1s,				; 0111 0001
offset vr1s,				; 0111 0010
0ffffh,					; 0111 0011
offset vr1us,				; 0111 0100
offset vr1ds,				; 0111 0101
offset vr1rs,				; 0111 0110
0ffffh,					; 0111 0111

offset vr2s,				; 0111 1000
offset vr2s,				; 0111 1001
offset vr2s,				; 0111 1010
0ffffh,					; 0111 1011
offset vr2us,				; 0111 1100
offset vr2ds,				; 0111 1101
offset vr2rs,				; 0111 1110
0ffffh					; 0111 1111


GetPlayerBitmap	endp


CommonCode	ends
