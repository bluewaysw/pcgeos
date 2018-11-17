
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992-1995.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Sokoban
FILE:		sokoban.asm

AUTHOR:		Steve Yegge, June 30, 1992

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_KBD_CHAR       Handles various keyboard characters.

    INT SeeIfPlayerMoved        Check if the keypress entailed a move, and
				deal with it.

    MTD MSG_MAP_SHIFT_MOVE      User did a shift+direction.

    MTD MSG_MAP_CONTROL_MOVE    User did a ctrl+direction.

    MTD MSG_VIS_DRAW            Draws the currentMap on the screen.

    INT ConvertTextMap          Update currentMap based on the default map
				for this level

    INT ReadMapCommon           Given a pointer to a text map, process and
				use it.

    INT DetermineWallType       Figure out what kind of wall we're looking
				at.

    MTD MSG_SOKOBAN_ADVANCE_LEVEL 
				Moves to the next level

    INT UpdateContentSize       Make the content match the size of the
				board and force the view to match it or
				become scrollable

    MTD MSG_SOKOBAN_REPLAY_LEVEL 
				User wants to replay a level.

    MTD MSG_SOKOBAN_PLAY_EXTERNAL_LEVEL 
				User wants to play an external level

    MTD MSG_SOKOBAN_PLAY_INTERNAL_LEVEL 
				Return to playing internal levels

    MTD MSG_META_START_SELECT   User is trying to move the little dude.

    INT ConvertDocCoordsToMapIndices 
				Convert an (x, y) pixel position in the
				document to an (x, y) location in the map.

    INT CheckIfMovingMan        See if they clicked on the little guy &
				handle it.

    INT CheckIfMovingBag        See if they clicked a bag right next to
				them.

    MTD MSG_META_END_SELECT     Quit moving the man.

    MTD MSG_META_PTR            User's dragging the mouse around.

    INT CenterIcon              Center the player in the middle of the
				screen.

    MTD MSG_MAP_VIEW_MAINTAIN_CONTEXT 
				Scroll the view to show the player.

    MTD MSG_VIS_OPEN            Create a gstate for drawing.

    MTD MSG_VIS_CLOSE           Destroy our drawing gstate.

    INT CreateUsefulGState      Create a gstate for drawing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/10/92	initial revision

DESCRIPTION:

	High-level routines for playing the game.  Should really
	be called "sokobanPlay.asm".

	$Id: sokoban.asm,v 1.1 97/04/04 15:13:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;		initialized data
;-----------------------------------------------------------------------------

idata	segment

currentMap		Map
saveMap			Map

idata	ends

;-----------------------------------------------------------------------------
;		uninitialized Data
;----------------------------------------------------------------------------	

udata	segment

level			word		; current level
internalLevel		word		; last internal level played
moves 			word		; current moves
pushes			word		; current pushes
; packets		byte		; bags on this level
; saved			byte		; current saved bags

gameState		SokobanGameState
gstate			hptr.GState

; position		Point
nextPosition		Point
nextNextPosition	Point

tempSave		TempSaveStruct
undoInfo		UndoStruct

colorOption		word
soundOption		word

if HIGH_SCORES
;
;  These 3 variables save the last level achieved by the user
;  during this session, if any, and the numbers of moves and
;  pushes they used on that level.  When the file is closed,
;  the high score code will check these values, and if they
;  are nonzero, attempt to add the score to the list.
;
scoreLevel		word
scoreMoves		word
scorePushes		word
endif

;
;  These variables are used for drawing the bitmaps.
;
bitmapWidth		word
bitmapHeight		word

udata	ends

;-----------------------------------------------------------------------------
;			Code 'n' stuff
;-----------------------------------------------------------------------------

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles various keyboard characters.

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- if they're releasing the key, quit
	- if it's left, right, up or down arrow, call the move handler

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapKbdChar	method dynamic MapContentClass, 
						MSG_META_KBD_CHAR
	;
	;  If they're releasing the key do nothing.
	;
		test	dl, mask CF_RELEASE
		jnz	fup
	;
	;  If we don't have a drawing gstate, bail.
	;
		tst	es:[gstate]
		jz	fup
	;
	;  See if they did some sort of movement. If so, we're done
	;
		call	SeeIfPlayerMoved	; carry set if moved, so
		jc	done			; ...we swallow the keypress
	;
	;  At this point, they've hit a key, and it's not a
	;  movement key.  The only other ones we deal with are
	;  the standard sokoban shortcuts.  If the character is not
	;  a plain vanilla character, pass it to the superclass
	;
		tst	ch
		jnz	fup
	;
	;  User typed in a regular ascii character (presumably)
	;
		mov	ax, MSG_MAP_UNDO_MOVE
		cmp	cl, 'u'
		je	sendMessage

		mov	ax, MSG_MAP_UNDO_LEVEL
		cmp	cl, 'U'
		je	sendMessage

		mov	ax, MSG_MAP_SAVE_POSITION
		cmp	cl, 's'
		je	sendMessage
		
		mov	ax, MSG_MAP_RESTORE_POSITION
		cmp	cl, 'r'
		je	sendMessage
	;
	;  The following shortcuts have not been implemented
	;
if	0
		mov	ax, MSG_MAP_SAVE_GAME
		cmp	cl, 'S'
		je	sendMessage

		mov	ax, MSG_MAP_RESTORE_GAME
		cmp	cl, 'R'
		je	sendMessage

		mov	ax, MSG_MAP_NEW_GAME
		cmp	cl, 'N'
		je	sendMessage
endif
	;
	;  We don't handle this keypress.  Let someone else deal with it.
	;
fup:
		mov	ax, MSG_META_FUP_KBD_CHAR
		call	ObjCallInstanceNoLock
done:
		ret

sendMessage:
		GOTO	ObjCallInstanceNoLock
MapKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfPlayerMoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the keypress entailed a move, and deal with it.

CALLED BY:	MapKbdChar

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		carry set if they moved, clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if it's one of hjkl (vi movement keys) or an arrow key,
	  unmodified by control or shift, then it's a simple move
	  in that direction.

	- if the control or shift key is down, it's a special type
	  of move.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	7/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeeIfPlayerMoved	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  First find out which direction it was, if any, and
	;  save a MovementDirection enumeration.
	;
		cmp	ch, CS_CONTROL
		je	checkControlSet

		cmp	cl, 'h'			; vi 'left'
		je	movedLeft
		cmp	cl, 'j'			; vi 'down'
		je	movedDown
		cmp	cl, 'k'			; vi 'up'
		je	movedUp
		cmp	cl, 'l'			; vi 'right'
		je	movedRight

	;
	;  See if it was a shift move.
	;
		cmp	cl, 'H'
		je	shiftLeft
		cmp	cl, 'J'
		je	shiftDown
		cmp	cl, 'K'
		je	shiftUp
		cmp	cl, 'L'
		je	shiftRight
		jmp	didntMove

checkControlSet:
		cmp	cl, VC_RIGHT
		je	movedRight
		cmp	cl, VC_LEFT
		je	movedLeft
		cmp	cl, VC_UP
		je	movedUp
		cmp	cl, VC_DOWN
		je	movedDown

		cmp	cl, VC_JOYSTICK_0
		jb	checkNumPad
		cmp	cl, VC_JOYSTICK_315
		jbe	joystick

checkNumPad:
	;
	;  See if it was a shift move.
	;
		cmp	cl, VC_NUMPAD_4
		je	shiftLeft		
		cmp	cl, VC_NUMPAD_8
		je	shiftUp
		cmp	cl, VC_NUMPAD_6
		je	shiftRight
		cmp	cl, VC_NUMPAD_2
		je	shiftDown

		
		jmp	didntMove		; c ya
movedUp:
		mov	cx, MD_UP
		jmp	moved
movedDown:
		mov	cx, MD_DOWN
		jmp	moved
movedLeft:
		mov	cx, MD_LEFT
		jmp	moved
movedRight:
		mov	cx, MD_RIGHT
moved:
	;
	;  OK, they moved in one of the four directions.  See
	;  if it was a control move.
	;
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jnz	controlMove
	;
	;  It was a regular move.  Call the move handler and return
	;  carry set to indicate we handled the keypress.
	;
		mov	ax, MSG_MAP_PLAYER_MOVE
		call	ObjCallInstanceNoLock
		stc
		jmp	done
shiftLeft:
		mov	cx, MD_LEFT
		jmp	shiftMove
shiftRight:
		mov	cx, MD_RIGHT
		jmp	shiftMove		
shiftUp:
		mov	cx, MD_UP
		jmp	shiftMove
shiftDown:
		mov	cx, MD_DOWN
shiftMove:
	;
	;  Call the special handler for shift-move.
	;
		mov	ax, MSG_MAP_SHIFT_MOVE
		call	ObjCallInstanceNoLock
		stc
		jmp	done
controlMove:
	;
	;  Call the special handler for control-move.
	;
		mov	ax, MSG_MAP_CONTROL_MOVE
doMove:
		call	ObjCallInstanceNoLock
		stc
		jmp	done
didntMove:
		clc
done:
		.leave
		ret

joystick:
		mov	ax, MD_RIGHT
		cmp	cl, VC_JOYSTICK_0
		je	joyMods
		mov	ax, MD_LEFT
		cmp	cl, VC_JOYSTICK_180
		je	joyMods
		mov	ax, MD_UP
		cmp	cl, VC_JOYSTICK_90
		je	joyMods
		mov	ax, MD_DOWN
		cmp	cl, VC_JOYSTICK_270
		jne	didntMove
joyMods:
		mov_tr	cx, ax		; cx <- move
		mov	ax, MSG_MAP_SHIFT_MOVE
		test	dh, mask SS_FIRE_BUTTON_1
		jnz	doMove

		mov	ax, MSG_MAP_CONTROL_MOVE
		test	dh, mask SS_FIRE_BUTTON_2
		jnz	doMove

		mov	ax, MSG_MAP_PLAYER_MOVE
		jmp	doMove
		
SeeIfPlayerMoved	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapShiftMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User did a shift+direction.

CALLED BY:	MSG_MAP_SHIFT_MOVE

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		es	= dgroup
		cx	= MovementDirection

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- figure out how many times to move
	- move that many times

	This routine is more or less the same as control-move.
	The only difference is that we move left or right until
	we've hit a wall, or 2 bags (instead of a wall or 1 bag).

	I could probably figure out a clever way to combine
	these routines, since they are so similar, but I'm not
	going to.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapShiftMove	method dynamic MapContentClass, 
					MSG_MAP_SHIFT_MOVE
		.enter
	;
	;  Search the map in the direction of movement until we
	;  find a wall or bag (there has to be one or the other,
	;  since all maps are closed).  Bag can be saved.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y	;(bx,ax) = pos
		clr	bp				; counter
		clr	dh				; bag counter
searchLoop:
		cmp	cx, MD_UP
		jne	notUp
		dec	ax				; move up by 1
		jmp	gotCoords
notUp:
		cmp	cx, MD_LEFT
		jne	notLeft
		dec	bx				; move left by 1
		jmp	gotCoords
notLeft:
		cmp	cx, MD_RIGHT
		jne	notRight
		inc	bx				; move right by 1
		jmp	gotCoords
notRight:
		inc	ax				; move down by 1
gotCoords:
		push	ax, bx				; current coords
		call	ConvertArrayCoordinates		; bx <- offset
		mov	dl, {byte} es:[currentMap+(size MapHeader)][bx]
		pop	ax, bx				; current coords

		cmp	dl, SST_WALL_NSEW		; wall?
		jbe	gotCount

		cmp	dl, SST_BAG			; bag?
		jne	maybeSavedBag
checkBag:
	;
	;  They hit a bag.  If they've hit one before, dh is nonzero.
	;
		tst	dh				; hit one already?
		jnz	gotCount			; yep, start moving
		mov	dh, 1				; record the fact that
		jmp	next				;  they've hit a bag
maybeSavedBag:
		cmp	dl, SST_SAFE_BAG		; saved bag?
		jne	next
		jmp	checkBag			; see if 2nd bag
next:
	;
	;  They didn't hit anything, so try again.
	;
		inc	bp				; counter
		jmp	searchLoop
gotCount:
	;
	;  If they pushed a bag (dh >= 1), we're off by one.  This
	;  is because the loop we just went through checks the "next
	;  square" to see if we should stop.  If we're pushing a bag,
	;  we're actually one behind the "next square" and don't need
	;  to move as far to complete the run.  Trust me.
	;
		tst	dh				; pushed a bag?
		jz	noAdjust			; nope!  all is well.
adjust::
		tst	bp				; already zero?
		jz	done				; yep!  bail.
		dec	bp				; fix off-by-one
noAdjust:
	;
	;  Loop bp times, in direction cx, calling MovePlayerCommon.
	;
		tst	bp
		jz	done

		push	ds:[LMBH_handle]		; block might move
moveLoop:
		call	MovePlayerCommon
		dec	bp
		jnz	moveLoop
	;
	;  If they solved the level as a result of the last move (a
	;  distinct possibility), then the map resizes, the object block
	;  moves, and *ds:si is now garbage.  Since UpdateMan takes
	;  *ds:si = MapInstance, we need to update ds.
	;
		pop	bx
		call	MemDerefDS			; *ds:si = Map
done:
	;
	;  Put the man's legs together and make him face the nearest
	;  bag, if any.
	;
		mov	es:[mapOffset], si
		call	UpdateMan

		.leave
		ret
MapShiftMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapControlMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User did a ctrl+direction.

CALLED BY:	MSG_MAP_CONTROL_MOVE

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		es	= dgroup
		cx	= MovementDirection

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- figure out how far to move them (number of moves)
	- loop that many times, calling MovePlayer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapControlMove	method dynamic MapContentClass, 
					MSG_MAP_CONTROL_MOVE
		.enter
	;
	;  Search the map in the direction of movement until we
	;  find a wall or bag (there has to be one or the other,
	;  since all maps are closed).  Bag can be saved.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y	
							;(bx,ax) = pos
		clr	bp				; counter
searchLoop:
		cmp	cx, MD_UP
		jne	notUp
		dec	ax				; move up by 1
		jmp	gotCoords
notUp:
		cmp	cx, MD_LEFT
		jne	notLeft
		dec	bx				; move left by 1
		jmp	gotCoords
notLeft:
		cmp	cx, MD_RIGHT
		jne	notRight
		inc	bx				; move right by 1
		jmp	gotCoords
notRight:
		inc	ax				; move down by 1
gotCoords:
		push	ax, bx				; current coords
		call	ConvertArrayCoordinates		; bx <- offset
		mov	dl, {byte} es:[currentMap + (size MapHeader)][bx]
		pop	ax, bx				; current coords

		cmp	dl, SST_WALL_NSEW		; wall?
		jbe	gotCount
		cmp	dl, SST_BAG			; bag?
		je	gotCount
		cmp	dl, SST_SAFE_BAG		; saved bag?
		je	gotCount
	;
	;  They didn't hit anything, so try again.
	;
		inc	bp				; counter
		jmp	searchLoop
gotCount:
	;
	;  Loop bp times, in direction cx, calling MovePlayerCommon.
	;
		tst	bp
		jz	done
		push	ds:[LMBH_handle]

moveLoop:
		call	MovePlayerCommon
		dec	bp
		cmp	bp, 0
		ja	moveLoop
	;
	; if they solved the level, the map resizes and ds is garbage
	;
		pop	bx
		call	MemDerefDS			; *ds:si = TheMap
done:
		mov	es:[mapOffset], si
		call	UpdateMan

		.leave
		ret
MapControlMove	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapSavePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User saves a position.

CALLED BY:	MSG_MAP_SAVE_POSITION

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- copy the whole map into a temporary storage place,
	- stuff the tempSave variable(s).
	- enable the restore-position trigger

SIDE EFFECTS/IDEAS:

	You can't undo after saving/restoring position.  This
	simplifies things somewhat from a code standpoint, and
	I can't see why you'd ever want to save your position
	if you needed to undo a move, anyway.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapSavePosition		method	MapContentClass, 
						MSG_MAP_SAVE_POSITION
		uses	ax,cx,dx,bp
		.enter

		BitSet	es:[gameState], SGS_SAVED_POS
	;
	;  Move the currentMap into the saveMap.
	;
		segmov	ds, es, cx
		mov	di, offset	saveMap
		mov	si, offset	currentMap
		mov	cx, size	Map
		rep	movsb
	;
	;  Save moves and pushes
	;
		mov	ax, es:[moves]
		mov	es:[tempSave].TSS_moves, ax
		
		mov	ax, es:[pushes]
		mov	es:[tempSave].TSS_pushes, ax
	;
	;  Enable the restore-position trigger
	;
		GetResourceHandleNS	RestorePositionTrigger, bx
		mov	si, offset	RestorePositionTrigger
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjMessage
		
		.leave
		ret
MapSavePosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapRestorePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User restores a saved position.

CALLED BY:	MSG_MAP_RESTORE_POSITION

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- disable the restore-position trigger
	- move the saveMap into the currentMap
	- get the global variables set from the tempSave structure
	- redraw the screen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapRestorePosition		method	MapContentClass,
						MSG_MAP_RESTORE_POSITION
		uses	ax,cx,dx,bp
		.enter
		
		push	ds:[LMBH_handle], si
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	EnableRestoreTrigger		; disable me
		call	EnableUndoTrigger		; me too
		BitClr	es:[gameState], SGS_CAN_UNDO
	;
	;  Move the saveMap into the currentMap.
	;
		segmov	ds, es, cx
		mov	di, offset	currentMap
		mov	si, offset	saveMap
		mov	cx, size	Map
		rep	movsb
	;
	;  Recover moves, pushes, saved-bags and position.
	;
		mov	ax, es:[tempSave].TSS_moves
		mov	es:[moves], ax
		
		mov	ax, es:[tempSave].TSS_pushes
		mov	es:[pushes], ax
	;
	;  Update the animation stuff.
	;
		andnf	es:[walkInfo], not (mask WS_DIR or mask WS_FACE or \
					    mask WS_LEGS or mask WS_PUSH)
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		call	ConvertArrayCoordinates		; bx = offset
		cmp	{byte} es:[currentMap + (size MapHeader)][bx], \
						SST_SAFE_PLAYER
		jne	notSafe
		ornf	es:[walkInfo], mask WS_SAFE
		jmp	doneWalkInfo
notSafe:
		andnf	es:[walkInfo], not mask WS_SAFE	; clear it
doneWalkInfo:
	;
	;  Invalidate the map, causing it to redraw
	;
		pop	bx, si				; restore ourselves
		call	MemDerefDS
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
	;
	;  Update all the GenValues.
	;
		call	UpdateMovesData
		call	UpdatePushesData
		call	UpdateSavedData
		
		.leave
		ret
MapRestorePosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapUndoLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User frustratedly wants to start the level over (hahahaha)

CALLED BY:	MSG_MAP_UNDO_LEVEL

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapUndoLevel	method		MapContentClass,
						MSG_MAP_UNDO_LEVEL
		uses	ax,bp
		.enter

if DOCUMENT_CONTROL
		call	DirtyTheSavedGame
endif
		
		BitClr	es:[gameState], SGS_CAN_UNDO
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	EnableUndoTrigger

	;  jfh - since advancing a level clears the saved pos flag we want to
	;  save it first

		mov	ax, es:[gameState]
		push ax

	;
	;  Basically treat it like they just advanced to this level.
	;  (This message handler will invalidate the content as well).
	;
		dec	es:[level]
		call	GeodeGetProcessHandle
		mov	ax, MSG_SOKOBAN_ADVANCE_LEVEL
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	;  Howsomeever, they should be able to restore position after
	;  the undo-level, so we re-enable the restore-position trigger.
	;   
	;  jfh - but, only if there was already a saved pos on this level
	;
	;	BitSet	es:[gameState], SGS_SAVED_POS

		pop  ax
		test	ax, mask SGS_SAVED_POS
		jz   dontSet
		BitSet	es:[gameState], SGS_SAVED_POS
dontSet:
		mov	ax, MSG_GEN_SET_ENABLED
		call	EnableRestoreTrigger		; enable me
	;
	;  Update the status bar.  Level & bags shouldn't have changed.
	;
		call	UpdateSavedData
		call	UpdateMovesData
		call	UpdatePushesData
		
		.leave
		ret
MapUndoLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapContentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the currentMap on the screen.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		es = dgroup
		^hbp = GState to draw through

RETURN:		nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapContentVisDraw	method dynamic MapContentClass, 
							MSG_VIS_DRAW
		uses	ax
		
		drawState	local	hptr.GState	push	bp
		startX		local	word
		xPos		local	word
		yPos		local	word
		column		local	byte
		
		.enter

	;
	;  Get a GState for moving the man (different from the
	;  gstate which is passed to us in this handler, which
	;  will be destroyed.)
	;
		call	CreateUsefulGState
	;
	;  Initialize local variables.
	;
		clr	ax
		mov	xPos, ax
		mov	yPos, ax
		mov	startX, ax
	;
	;  Set up the counter (# bytes in the map)
	;
		mov	ax, MAX_ROWS
		mov	cx, MAX_COLUMNS
		mul	cx
		mov_tr	cx, ax				; cx = #bytes (data)
	;
	;  Point es:di to the first of the map-array bytes.
	;
		lea	di, es:[currentMap].M_data	; es:di = map array

	; jfh - bail out if there's nothing to draw
		mov	bl, {byte} es:[di]		; get first byte
		clr  bh
		tst  bx
		jz   dontDraw

		clr	column
		
		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax
mapLoop:
		clr	bh
		mov	bl, {byte} es:[di]		; get next byte
		push	di				; save pointer into map
		
		call	GetCorrectBitmapFromCharacter	; ds:si = bitmap
		jc	doneDrawing			; don't crash.
		
		mov	ax, xPos			; x-coordinate
		mov	bx, yPos			; y-coordinate
		mov	di, drawState			; passed gstate

		clr	dx				; no callback
		call	GrDrawBitmap
doneDrawing:
	;
	;  ss:[column] keeps track of what column we're on, so we
	;  can keep xPos and yPos up to date.
	;
		inc	column
		cmp	column, MAX_COLUMNS	; end of row?
		jl	sameRow			; nope, skip doing new row
	;
	;  start a new row.  Reset X, increment Y.
	;
		clr	column	
		mov	ax, startX
		mov	xPos, ax
		mov	dx, yPos
		add	dx, es:[bitmapHeight]
		mov	yPos, dx
		jmp	donePosition
sameRow:
		mov	dx, xPos
		add	dx, es:[bitmapWidth]
		mov	xPos, dx
donePosition:
	;
	;  now column, xPos and yPos are set.  Restore the map pointer
	;  and continue.
	;
		pop	di			; restore pointer into map
		inc	di
		
		loop	mapLoop
	;
	;  Unlock the Bitmaps resource.
	;
		mov	bx, handle Bitmaps
		call	MemUnlock

dontDraw:		
		.leave
		ret
MapContentVisDraw	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update currentMap based on the default map for this level

CALLED BY:	internal (lots of places)
PASS:		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

	Computes & sets global variables:  packets, saved, position

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 6/94		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertTextMap	proc	far
		uses	ax,bx,dx,si,di,ds
		.enter
	;
	;  Get si pointing to the right map using the offset-table.
	;
		Assert	dgroup	es
		mov	bx, es:[level]
		dec	bx				; 0-indexed table
		shl	bx				; word-sized offsets
		mov	si, cs:[screenOffsetTable][bx]	; si = screen offset
	;
	;  Lock the appropriate resource.  Screens are divided into
	;  resources of 15 screens (about 4k each), so we convert the
	;  current level into an offset into the resource table.
	;
		mov	ax, es:[level]			; ax = 1-90
		dec	ax				; ax = 0-89
		mov	bx, SCREENS_PER_RESOURCE
		clr	dx				; dx.ax = screen #
		div	bx				; ax = 0-5
		shl	ax				; ax = 0-10
		mov_tr	bx, ax				; bx = table index
		mov	bx, cs:[screenResourceTable][bx]; bx = resource handle
		jmp	gotHandle

screenResourceTable	hptr	\
		handle	Screens1To15,
		handle	Screens16To30,
		handle	Screens31To45,
		handle	Screens46To60,
		handle	Screens61To75,
		handle	Screens76To90

gotHandle:
		call	MemLock
		LONG	jc	done
		mov	ds, ax
		mov	si, ds:[si]			; ds:si <- ptr to map

		mov	di, offset es:[currentMap]
		call	ReadMapCommon			; read into currentMap
	;
	;  Unlock the screens resource.
	;
		call	MemUnlock
done:
		.leave
		ret
ConvertTextMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadMapCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a pointer to a text map, process and use it.

CALLED BY:	UTILITY

PASS:		ds:si	= source Map structure
		es:di   = target Map structure
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	Updates currentMap from the passed map and various
	  	other global variables.

PSEUDO CODE/STRATEGY:

for x = 0 to mapWidth - 1
	for y = 0 to mapLength - 1

		...handle non-wall, non-ground squares...

		;
		; Check for walls to EAST, WEST, NORTH, SOUTH
		;
		wallType = 0

		if x > 0 && isWall(map[x - 1][y])
			wallType = wallType or WEST
		endif

		if x < lastLegalXIndex && isWall(map[x + 1][y])
			wallType = wallType or EAST
		endif

		if y > 0 && isWall(map[x][y - 1])
			wallType = wallType or NORTH
		endif

		if y < lastLegalIndex && isWall(map[x][y + 1])
			walltype = wallType or SOUTH
		endif
	end
end

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/ 1/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadMapCommon	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		targetMap	local	word	push di
		packetCount	local	byte
		savedCount	local	byte
		position	local	Point
		loopBound	local	word
		.enter
	;
	;  Copy the MapHeader to the currentMap.
	;
		mov	cx, size MapHeader
		rep	movsb				; si = si + 4
	;
	;  Zero out the variables we're going to be counting.
	;
		clr	ss:[packetCount]
		clr	ss:[savedCount]
		mov	ss:[position].P_x, -1
		mov	ss:[position].P_y, -1
	;
	;  Set up the loop.  To speed things up a bit, we only read
	;  as many rows as there are rows in the map.  So for level
	;  1, which only has 11 rows, we read 11 rows.  Simple, eh?
	;
	;  bx	= keeps X-coord
	;  bp	= keeps Y-coord
	;
		mov	cx, MAX_COLUMNS
		mov	al, ds:[si-(size MapHeader)].M_header.MH_rows
		mul	cl
		mov_tr	ss:[loopBound], ax	; bound = rows * columns

		clr	bx, cx			; x = 0, y = 0
byteLoop:
		lodsb
	;
	;  Do the comparisons in the order of most-frequent
	;  occurrence:  grass, ground, wall, bag, safe, player, 
	;  safeplayer.
	;
		cmp	al, '_'
		jne	notGrass

		mov	dl, SST_GRASS
		jmp	continue
notGrass:
		cmp	al, ' '
		jne	notGround

		mov	dl, SST_GROUND
		jmp	continue
notGround:
	;
	;  The check for a wall is a little complex...
	;
		cmp	al, '#'
		jne	notWall

		call	DetermineWallType	; dl = SokobanSquareType
		jmp	continue
notWall:
		cmp	al, '$'
		jne	notBag

		inc	ss:[packetCount]	; found another one!
		mov	dl, SST_BAG
		jmp	continue
notBag:
		cmp	al, '.'
		jne	notSafe

		mov	dl, SST_SAFE
		jmp	continue
notSafe:
		cmp	al, '*'
		jne	notSavedBag
		
		inc	ss:[packetCount]	; and another!
		inc	ss:[savedCount]		; ... saved one
		mov	dl, SST_SAFE_BAG
		jmp	continue
notSavedBag:
		cmp	al, '@'
		jne	notPlayer
		
		mov	ss:[position].P_x, bx	; store player's position
		mov	ss:[position].P_y, cx
		mov	dl, SST_PLAYER
		jmp	continue
notPlayer:
		cmp	al, '&'
		jne	notSafePlayer
		
		mov	ss:[position].P_x, bx		; column
		mov	ss:[position].P_y, cx		; row

		mov	dl, SST_SAFE_PLAYER
notSafePlayer:
	;
	;  If we get here, the map is corrupted.  Display
	;  and error and get out.
	;
		jmp	done
continue:
	;
	;  Write the byte into the currentMap (it's in dl).
	;
		push	bx				; save column
		mov	al, dl
		stosb
if 0
		mov	ax, cx				; (bx,ax) = (x,y)
		call	ConvertArrayCoordinates		; bx = offset
		mov	{byte} es:[bx][currentMap + (size MapHeader)], dl
endif
		pop	bx				; restore column
	;
	;  Set up to loop.
	;
		inc	bx				; column counter
		cmp	bx, MAX_COLUMNS
		jb	sameRow
		
		clr	bx				; column counter
		inc	cx				; row counter
sameRow:
		cmp	bx, ss:[loopBound]
		jb	byteLoop
done:
	;
	; write cached info to map header
	;
		mov	di, ss:[targetMap]
		mov	al, ss:[packetCount]
		mov	bl, ss:[savedCount]
		mov	es:[di].MH_packets, al
		mov	es:[di].MH_saved, bl
		movdw	es:[di].M_header.MH_position, ss:[position], ax

		.leave
		ret
ReadMapCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetermineWallType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out what kind of wall we're looking at.

CALLED BY:	ReadMap

PASS:		ds:[si] = pointer AFTER where we're looking.
		al	= byte at ds:[si]
		cx	= row where we're looking
		bx	= column where we're looking

RETURN:		dl	= SokobanSquareType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	JAG	1/ 5/94			Initial version
	stevey	1/ 6/94			fixed N & S cases

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetermineWallType	proc	near
		uses	si
		.enter
	;
	;  dl accumulates a SokobanSquareType.
	;
EC <		cmp	al, '#'						>
EC <		ERROR_NE -1						>
CheckHack <SST_WALL eq 0>
		clr	dl			; dl <- SST_WALL (no neighbors)
		dec	si			; ds:si = our byte
	;
	; Look West
	;
	; if x > 0 && isWall(map[x - 1][y])
	;	wallType = wallType or WEST
	; endif
	;
		tst	bx			; x > 0?
		jz	noWest

		cmp	{byte} ds:[si - 1], '#'
		jne	noWest
		ornf	dl, WEST
noWest:
	;
	; Look East
	;
	; if x < MAX_COLUMNS - 1  && isWall(map[x + 1][y])
	;	wallType = wallType or EAST
	; endif
	;
		cmp	bx, MAX_COLUMNS - 1	; x < max idx?
		jz	noEast

		cmp	{byte} ds:[si + 1], '#'
		jne	noEast
		ornf	dl, EAST
noEast:
	;
	; Look North
	;
	; if y > 0 && isWall(map[x][y - 1])
	;	wallType = wallType or NORTH
	; endif
	;
		tst	cx			; y > 0?
		jz	noNorth

		cmp	{byte} ds:[si - MAX_COLUMNS], '#'
		jne	noNorth
		ornf	dl, NORTH
noNorth:
	;
	; Look South
	;
	; if y < MAX_ROWS - 1 && isWall(map[x][y + 1])
	;	wallType = wallType or SOUTH
	; endif
	;
		cmp	cx, MAX_ROWS - 1	; y < max idx?
		jz	noSouth

		cmp	{byte} ds:[si + MAX_COLUMNS], '#'
		jne	noSouth
		ornf	dl, SOUTH
noSouth:
		.leave
		ret
DetermineWallType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanAdvanceLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves to the next level

CALLED BY:	MSG_SOKOBAN_ADVANCE_LEVEL

PASS: 		es = dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanAdvanceLevel	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_ADVANCE_LEVEL
		.enter
if DOCUMENT_CONTROL
	;
	;  Save the game here (do the equivalent of an auto-save).
	;  We have auto-saving turned off because it freezes the game
	;  for a bit, causing the user to overshoot and kill people.
	;
		push	es			; dgroup
		GetResourceSegmentNS	GenDocumentClass, es
		mov	bx, es
		mov	si, offset	GenDocumentClass
		mov	ax, MSG_GEN_DOCUMENT_UPDATE
		mov	di, mask MF_RECORD
		call	ObjMessage		; ^hdi = event handle
		pop	es			; dgroup

		mov	cx, di
		GetResourceHandleNS	SokobanDocumentControl, bx
		mov	si, offset	SokobanDocumentControl
		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
else
		mov	bx, es:[vmFileHandle]
		call	SaveGameToFile
endif
		Assert	dgroup	es
	;
	;  Increment the level before reading it in.
	;
		inc	es:[level]
if EXTERNAL_LEVELS
	;
	;  Handle external levels differently
	;
		test	es:[gameState], mask SGS_EXTERNAL_LEVEL
		jz	internal
	;
	;  Read the appropriate external level
	;
		mov	cx, es:[level]
		mov	di, offset es:[currentMap]
		call	LoadUserLevel
		jnc	pastRead
	;
	;  Unable to load external level
	;
		dec	es:[level]
		jmp	done
internal:
endif	; EXTERNAL_LEVELS		

if HIGH_SCORES		
	;
	;  Save the level, moves & pushes for scoring purposes.
	;

		mov	ax, es:[level]
		mov	es:[scoreLevel], ax
		mov	ax, es:[moves]
		mov	es:[scoreMoves], ax
		mov	ax, es:[pushes]
		mov	es:[scorePushes], ax
endif
	;
	;  See if they've won, and handle it specially if they have.
	;
		cmp	es:[level], MAX_LEVELS
		jg	wonGame
	;
	;  They haven't won, so go to the next level.
	;
		call	ConvertTextMap		; does packets, saved & pos
pastRead::
	;
	;  Set/clear the necessary state bits.
	;
		clr	es:[moves]	
		clr	es:[pushes]
		andnf	es:[gameState], not (mask SGS_CAN_UNDO or \
						mask SGS_MOVED_BAG or \
						mask SGS_SAVED_BAG or \
						mask SGS_UNSAVED_BAG or \
						mask SGS_SAVED_POS)

	;  jfh - want to set savpos flag so EnableRestoreTrigger will toggle
		BitSet	es:[gameState], SGS_SAVED_POS

	;
	;  Disable the undo-move and restore-position triggers
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	EnableUndoTrigger
		call	EnableRestoreTrigger

	;  jfh - now clear savpos flag since we're at a new level
		BitClr	es:[gameState], SGS_SAVED_POS

	;
	;  Clear out the animation stuff.
	;
		andnf	es:[walkInfo], not (mask WS_DIR or mask WS_FACE or \
					    mask WS_LEGS or mask WS_PUSH or \
					    mask WS_SAFE)
	;
	;  Update the scrollbars
	;
		call	UpdateContentSize
	;
	;  Update the status bar
	;
		call	UpdateMovesData
		call	UpdatePushesData
		call	UpdateLevelData
		call	UpdateBagsData
		call	UpdateSavedData
	;
	;  Invalidate the map
	;
		GetResourceHandleNS	TheMap, bx
		mov	si, offset	TheMap
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage
done::
		.leave
		ret
wonGame:
	;
	;  Set the bit in state saying they're now in win-mode.
	;
		ornf	es:[gameState], mask SGS_WON_GAME
	;
	;  Put up a dialog telling them they've won.
	;
		GetResourceHandleNS	WonGameDialog, bx
		mov	si, offset	WonGameDialog
		call	UserDoDialog
if HIGH_SCORES
	;
	;  See if they got a high score, and then just sit there
	;  waiting for them to start a new game or whatever.
	;
		segmov	ds, es, ax		; ds = dgroup
		call	UpdateScoreList
endif
	;
	;  Set-usable the replay-level dialog.
	;
		GetResourceHandleNS	ReplayLevelDialog, bx
		mov	si, offset	ReplayLevelDialog
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage

		jmp	done

SokobanAdvanceLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateContentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the content match the size of the board and force the
		view to match it or become scrollable

CALLED BY:	(INTERNAL)
PASS:		es	= dgroup
		currentMap = set
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateContentSize proc	far
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Compute the size of the board.
	; 
		mov	ax, es:[bitmapWidth]
		mul	es:[currentMap].M_header.MH_columns
		mov_tr	cx, ax
		mov	ax, es:[bitmapHeight]
		mul	es:[currentMap].M_header.MH_rows
		mov_tr	dx, ax
	;
	; Set that as the size of the content.
	; 
		GetResourceHandleNS TheMap, bx
		mov	si, offset TheMap
		mov	ax, MSG_VIS_SET_SIZE
		clr	di
		call	ObjMessage
	;
	; Invalidate the content's geometry. This will cause the view to
	; recalculate, too.
	; 
		mov	cl, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_NOW
		mov	ax, MSG_VIS_MARK_INVALID
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
UpdateContentSize endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanReplayLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to replay a level.

CALLED BY:	MSG_SOKOBAN_REPLAY_LEVEL

PASS:		ds = es = dgroup
		dx	= level to replay
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We can just call SokobanAdvanceLevel after setting the
	global level appropriately.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanReplayLevel	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_REPLAY_LEVEL
		.enter

		dec	dx			; advance-level will increment
		mov	es:[level], dx

		call	GeodeGetProcessHandle
		mov	di, mask MF_CALL
		mov	ax, MSG_SOKOBAN_ADVANCE_LEVEL
		call	ObjMessage

		.leave
		ret
SokobanReplayLevel	endm

if EXTERNAL_LEVELS	;-----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanPlayExternalLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to play an external level

CALLED BY:	MSG_SOKOBAN_PLAY_EXTERNAL_LEVEL
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If user is currently on an internal level, save the level number
	Set the external level flag
	Set level to dx-1
	call AdvanceLevel

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanPlayExternalLevel	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_PLAY_EXTERNAL_LEVEL
		uses	ax, cx, dx, bp
		.enter
	;
	; get the desired level
	;
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS ExternalLevelValue, bx
		mov	si, offset ExternalLevelValue
		mov	di, mask MF_CALL
		call	ObjMessage		; dx = level
	;
	; save current level if appropriate
	;
		push	es:[gameState]
		push	es:[level]
		test	es:[gameState], mask SGS_EXTERNAL_LEVEL
		jnz	load
		ornf	es:[gameState], mask SGS_EXTERNAL_LEVEL
		mov	ax, es:[level]
		mov	es:[internalLevel], ax
	;
	; load the external level
	;
load:
		dec	dx
		mov	es:[level], dx
		call	GeodeGetProcessHandle
		mov	di, mask MF_CALL
		mov	ax, MSG_SOKOBAN_ADVANCE_LEVEL
		call	ObjMessage
		jnc	cleanup
	;
	; something went wrong, back out
	;
		pop	es:[level]
		pop	es:[gameState]
		jmp	done
cleanup:
		add	sp, 4		; pop garbage off stack
done:
		.leave
		ret
SokobanPlayExternalLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanPlayInternalLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return to playing internal levels

CALLED BY:	MSG_SOKOBAN_PLAY_INTERNAL_LEVEL
PASS:		es 	= dgroup
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanPlayInternalLevel	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_PLAY_INTERNAL_LEVEL
		uses	ax, cx, dx, bp
		.enter
	;
	; make sure we aren't already internal
	;
		test	es:[gameState], mask SGS_EXTERNAL_LEVEL
		jz	done
		andnf	es:[gameState], not mask SGS_EXTERNAL_LEVEL
	;
	; load up the level
	;
		mov	dx, es:[internalLevel]
		dec	dx
		mov	es:[level], dx
		call	GeodeGetProcessHandle
		mov	di, mask MF_CALL
		mov	ax, MSG_SOKOBAN_ADVANCE_LEVEL
		call	ObjMessage
done:
		.leave
		ret
SokobanPlayInternalLevel	endm

endif	; EXTERNAL_LEVELS ----------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User is trying to move the little dude.

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		es	= dgroup
		cx	= mouse x
		dx	= mouse y
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax = MouseReturnFlags
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

	- figure out whether the mouse was clicked to the left of,
	to the right of, above, below or on the dude.

	- send out the corresponding movement command, if any

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapStartSelect	method dynamic MapContentClass, 
					MSG_META_START_SELECT
		.enter
	;
	;  Convert the passed (x,y) pixel position to an (x,y) map
	;  location.
	;
		call	ConvertDocCoordsToMapIndices	; (cx,dx) = map index
		jc	done
	;
	;  Before we get carried away and try to run to the spot
	;  where they clicked, see if it's a bag that's right next
	;  to them.  If so, just do a normal move-bag in that direction.
	;
		call	CheckIfMovingBag
		jnc	notMovingBag
	;
	;  They're moving a bag adjacent to them.  Call MovePlayerCommon.
	;
		call	MovePlayerCommon
		jmp	done
notMovingBag:
	;
	;  See if they've clicked on the little man, in which case
	;  they are probably trying to move him, and we should handle
	;  it specially.
	;
		call	CheckIfMovingMan
		jc	done
	;
	;  Find shortest path & move the guy.
	;
		call	SokobanMarkBusy
		call	MoveMan
		call	SokobanMarkNotBusy
	;
	;  Just as a usability thing, set the SGS_MOVING_MAN bit,
	;  so they can immediately start pushing a bag with the mouse
	;  from here.
	;
		BitSet	es:[gameState], SGS_MOVING_MAN
done:
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
MapStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDocCoordsToMapIndices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an (x, y) pixel position in the document to
		an (x, y) location in the map.

CALLED BY:	MapStartSelect, MapDragSelect

PASS:		(cx, dx) = pixel position

RETURN:		(cx, dx) = map location
		carry set if off the map, clear if OK

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertDocCoordsToMapIndices	proc	near
		uses	ax,bx
		.enter

		tst	cx			; x <= 0?  If so, quit.
		jle	bad
		tst	dx			; y <= 0?  If so, quit.
		jle	bad
	;
	;  Subtract the map upper-left corner from the mouse position.
	;
		movdw	axbx, cxdx		; ax = x, bx = y

		mov	cx, es:[bitmapWidth]
		div	cl			; ax <- map X
		cmp	al, MAX_COLUMNS
		jae	bad			; off right edge
		clr	ah			; nuke remainder
		mov_tr	cx, ax

		mov	dx, es:[bitmapHeight]
		mov_tr	ax, bx
		div	dl			; al <- map Y
		cmp	al, MAX_ROWS
		jae	bad			; off bottom edge
		clr	ah			; nuke remainder
		mov	dx, ax
		clc
done:
		.leave
		ret
bad:
		stc
		jmp	done
ConvertDocCoordsToMapIndices	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMovingMan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if they clicked on the little guy & handle it.

CALLED BY:	MapStartSelect

PASS:		(cx,dx)	= map location where they clicked
		es	= dgroup

RETURN:		carry set if it's on the man, clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfMovingMan	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Conveniently, the current position is actually stored
	;  in dgroup.  Aren't global variables nice?
	;
		cmp	cx, es:[currentMap].M_header.MH_position.P_x
		jne	notSame

		cmp	dx, es:[currentMap].M_header.MH_position.P_y
		jne	notSame
same::
		ornf	es:[gameState], mask SGS_MOVING_MAN
		stc
		jmp	done
notSame:
		clc
done:
		.leave
		ret
CheckIfMovingMan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMovingBag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if they clicked a bag right next to them.

CALLED BY:	MapStartSelect

PASS:		(cx,dx) = map square where they clicked
		es	= dgroup

RETURN:		carry set if moved a bag; clear otherwise.
		IF they moved a bag, returns cx = MovementDirection

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/18/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfMovingBag	proc	near
		uses	ax,bx,dx
		.enter
	;
	;  See if they clicked immediately to the right.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_x
		inc	ax
		cmp	cx, ax
		jne	notRight
	;
	;  If they y-coords are the same, it's a move right.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		cmp	dx, ax
		jne	notRight
movedRight::
		mov	cx, MD_RIGHT
		stc
		jmp	done
notRight:
	;
	;  See if they clicked immediately to the left.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_x
		dec	ax
		cmp	cx, ax
		jne	notLeft
	;
	;  If y-coords are the same, it's a move left.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		cmp	dx, ax
		jne	notLeft
movedLeft::
		mov	cx, MD_LEFT
		stc
		jmp	done
notLeft:
	;
	;  See if they clicked immediately above.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		dec	ax
		cmp	dx, ax
		jne	notUp
	;
	;  If x-coords are the same, it was a move up.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_x
		cmp	cx, ax
		jne	notUp
movedUp::
		mov	cx, MD_UP
		stc
		jmp	done
notUp:
	;
	;  See if they clicked immediately below.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		inc	ax
		cmp	dx, ax
		jne	notDown
	;
	;  If x-coords are the same, it was a move down.
	;
		mov	ax, es:[currentMap].M_header.MH_position.P_x
		cmp	cx, ax
		jne	notDown
movedDown::
		mov	cx, MD_DOWN
		stc
		jmp	done
notDown:
	;
	;  It wasn't immediately right, left, up or down.
	;
		clc
done:
		.leave
		ret
CheckIfMovingBag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quit moving the man.

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapEndSelect	method dynamic MapContentClass, 
					MSG_META_END_SELECT

		andnf	es:[gameState], not mask SGS_MOVING_MAN
		mov	ax, mask MRF_PROCESSED

		ret
MapEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User's dragging the mouse around.

CALLED BY:	MSG_META_PTR

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		(cx,dx)	= mouse position

RETURN:		ax = MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapPtr		method dynamic MapContentClass, 
					MSG_META_PTR
		uses	cx, dx, bp
		.enter
	;
	;  If the mouse button isn't down, bail.
	;
		test	bp, mask BI_B0_DOWN
		LONG	jz	done
	;
	;  See if they're actually moving the man...
	;
		test	es:[gameState], mask SGS_MOVING_MAN
		LONG	jz	done
	;
	;  Figure out the coordinates of the square they're over.
	;
		call	ConvertDocCoordsToMapIndices	; (cx,dx) = map location
		LONG	jc	done			; off the map		
	;
	;  If it's on the little guy, they haven't moved the mouse
	;  off his square yet.
	;
		cmp	cx, es:[currentMap].M_header.MH_position.P_x
		jne	notSame
		cmp	dx, es:[currentMap].M_header.MH_position.P_y
		je	done				; x & y are same
notSame:
	;
	;  They clicked on a different row from the little man.
	;  Check to the left & right, and above & below, the square
	;  they're dragging over.  If we find the man in one of the
	;  neighboring squares, attempt to move him here.  Otherwise,
	;  they've dragged the mouse way away from him, so stop moving
	;  him altogether.
	;
		movdw	bxax, cxdx			; bx = x, ax = y
		dec	bx				; check left
		call	ConvertArrayCoordinates		; bx = offset
		mov	ax, MD_RIGHT			; maybe move right
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_PLAYER
		je	movePlayer
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_SAFE_PLAYER
		je	movePlayer
	;
	;  Check for player to the right...
	;
		movdw	bxax, cxdx
		inc	bx
		call	ConvertArrayCoordinates
		mov	ax, MD_LEFT			; maybe move left
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_PLAYER
		je	movePlayer
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_SAFE_PLAYER
		je	movePlayer
	;
	;  Check for player above...
	;
		movdw	bxax, cxdx
		dec	ax
		call	ConvertArrayCoordinates
		mov	ax, MD_DOWN
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_PLAYER
		je	movePlayer
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_SAFE_PLAYER
		je	movePlayer
	;
	;  Check for player below...
	;
		movdw	bxax, cxdx
		inc	ax				; y = y+1
		call	ConvertArrayCoordinates		; bx = offset
		mov	ax, MD_UP			; maybe move up
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_PLAYER
		je	movePlayer
		cmp	{byte} es:[currentMap + size MapHeader][bx], \
						SST_SAFE_PLAYER
		je	movePlayer
	;
	;  Nope!  No player near us.  We're pretty damned generous,
	;  though, so we'll just have the guy run here anyway.
	;
		call	SokobanMarkBusy
		call	MoveMan
		call	SokobanMarkNotBusy
		jmp	done
movePlayer:
	;
	;  There *is* a player near us!  MovePlayerCommon is just
	;  what we need.
	;
		mov_tr	cx, ax
		call	MovePlayerCommon
done:
		mov	ax, mask MRF_PROCESSED
		
		.leave
		ret
MapPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Center the player in the middle of the screen.

CALLED BY:	MovePlayer, MoveBag

PASS:		ax, bx	= top left of player
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	12/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CenterIcon	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Make it visible.
	;
		movdw	cxdx, axbx
		GetResourceHandleNS	TheView, bx
		mov	si, offset TheView
		mov	ax, MSG_MAP_VIEW_MAINTAIN_CONTEXT
		mov	di, mask MF_CALL
		call	ObjMessage
		
		.leave
		ret
CenterIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapViewMaintainContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll the view to show the player.

CALLED BY:	MSG_MAP_VIEW_MAINTAIN_CONTEXT
PASS:		cx, dx	= top left of player
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapViewMaintainContext method dynamic MapViewClass, MSG_MAP_VIEW_MAINTAIN_CONTEXT
top		local	word		push	dx
left		local	word		push	cx
visRect		local	RectDWord
		.enter
	;
	; Get the rectangle (in document coordinates) that is visible to the
	; user and see if the new position of the player is within a 3-brick
	; margin of any edge of the view.
	; 
		mov	cx, ss
		lea	dx, ss:[visRect]
		mov	ax, MSG_GEN_VIEW_GET_VISIBLE_RECT
		push	bp
		call	ObjCallInstanceNoLock
		
		mov	bx, ds:[si]
		add	bx, ds:[bx].GenView_offset
		mov	cx, ds:[bx].GVI_docBounds.RD_right.low
		mov	dx, ds:[bx].GVI_docBounds.RD_bottom.low
		dec	cx				; convert to coords
		dec	dx
		pop	bp
		
		mov	ax, es:[bitmapWidth]
		shl	ax
		add	ax, es:[bitmapWidth]		; ax <- 3 brick width
		
		mov	di, ss:[left]			; di <- left edge of
							;  player
		
		mov	bx, ss:[visRect].RD_left.low
		tst	bx
		jz	checkRight			; => already as far that
							;  way as possible
		add	bx, ax
		cmp	di, bx
		jl	scroll				; farther left than
							;  margin, so scroll
		
checkRight:
		add	di, es:[bitmapWidth]		; di <- right edge of
							;  player
		
		mov	bx, ss:[visRect].RD_right.low
		cmp	cx, bx
		jle	checkTop			; => as far right as
							;  possible already

		sub	bx, ax				; bx <- right margin
		cmp	bx, di
		jl	scroll

checkTop:
		mov	ax, es:[bitmapHeight]
		shl	ax
		add	ax, es:[bitmapHeight]		; ax <- 3 brick height
		
		mov	di, ss:[top]			; di <- top edge of
							;  player
		mov	bx, ss:[visRect].RD_top.low 
		tst	bx
		jz	checkBottom			; => as far up as
							;  possible already
		
		add	bx, ax				; bx <- top margin
		cmp	di, bx
		jl	scroll				; => player beyond
							;  top margin

checkBottom:
		mov	bx, ss:[visRect].RD_bottom.low
		cmp	dx, bx
		jle	done				; => as far down as
							;  possible already
		
		add	di, es:[bitmapHeight]		; di <- bottom edge of
							;  player
		
		sub	bx, ax				; bx <- bottom margin
		cmp	bx, di
		jl	scroll				; => player beyond
							;  margin
done:
		.leave
		ret

scroll:
	;
	; Player is in the verge, so scroll it to be in the center of the
	; screen instead.
	; 
		push	bp
		mov	ax, ss:[left]
		mov	bx, ss:[top]
		sub	sp, size MakeRectVisibleParams
		mov	bp, sp

		clr	dx
		movdw	ss:[bp].MRVP_bounds.RD_left, dxax
		movdw	ss:[bp].MRVP_bounds.RD_top, dxbx
		add	ax, es:[bitmapWidth]
		add	bx, es:[bitmapHeight]
		movdw	ss:[bp].MRVP_bounds.RD_right, dxax
		movdw	ss:[bp].MRVP_bounds.RD_bottom, dxbx
		mov	ss:[bp].MRVP_xMargin, MRVM_50_PERCENT
		mov	ss:[bp].MRVP_yMargin, MRVM_50_PERCENT
		mov	ss:[bp].MRVP_xFlags, mask MRVF_ALWAYS_SCROLL
		mov	ss:[bp].MRVP_yFlags, mask MRVF_ALWAYS_SCROLL

		mov	dx, size MakeRectVisibleParams
		mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
		call	ObjCallInstanceNoLock
		add	sp, size MakeRectVisibleParams
		pop	bp
		jmp	done
MapViewMaintainContext endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapContentVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate for drawing.

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapContentVisOpen	method dynamic MapContentClass, 
					MSG_VIS_OPEN
		uses	ax, cx, dx, bp
		.enter

		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock		; bp = gstate
		mov	es:[gstate], bp
		
		.leave
		mov	di, offset MapContentClass
		GOTO	ObjCallSuperNoLock
MapContentVisOpen	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapContentVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy our drawing gstate.

CALLED BY:	MSG_VIS_CLOSE

PASS:		*ds:si	= MapContentClass object
		ds:di	= MapContentClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapContentVisClose	method dynamic MapContentClass, 
					MSG_VIS_CLOSE
		.enter

		mov	di, es:[gstate]
		tst	di
		jz	done

		call	GrDestroyState
		clr	es:[gstate]
done:
		.leave
		mov	di, offset MapContentClass
		GOTO	ObjCallSuperNoLock
MapContentVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateUsefulGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate for drawing.

CALLED BY:	SokobanAdvanceLevel, SokobanAttachUIToDocument

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/25/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateUsefulGState	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Destroy the old gstate, if any.
	;
		mov	di, es:[gstate]
		tst	di
		jz	doneDestroy

		call	GrDestroyState
doneDestroy:
	;
	;  Call the content to create a new gstate.
	;
		GetResourceHandleNS	TheMap, bx
		mov	si, offset	TheMap
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjMessage

		mov	es:[gstate], bp

		.leave
		ret
CreateUsefulGState	endp


CommonCode	ends
