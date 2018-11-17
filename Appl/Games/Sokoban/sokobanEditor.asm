COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC/GEOS
MODULE:		Sokoban
FILE:		editor.asm

AUTHOR:		Eric Weber, Feb  3, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT UpdateEditorSize	Make the content match the size of the
				board and force the view to match it or
				become scrollable

    INT EditContentUpdateRegion Update the square which changed, as well as
				any surrounding wall spaces.

    INT EditContentUpdateSquare Redraw one square of the map

    INT ChangeDirtyFlag		change the editor's dirty flag

    INT EditorPurge		Check with user before replacing editor
				contents

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 3/94   	Initial revision


DESCRIPTION:
	
		

	$Id: sokobanEditor.asm,v 1.1 97/04/04 15:13:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata segment

EditContentClass

currentTool	SokobanSquareType SST_WALL

idata ends

udata	segment

editorMap	Map

udata	ends

CommonCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanCreateLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new level and edit it

CALLED BY:	MSG_SOKOBAN_CREATE_LEVEL
PASS:		es 	= segment of SokobanProcessClass
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanCreateLevel	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_CREATE_LEVEL
		uses	ax, cx, dx, bp
		.enter
	;
	; remove the size dialog
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		GetResourceHandleNS CreateDialog, bx
		mov	si, offset CreateDialog
		clr	di
		call	ObjMessage
	;
	; dump whatever's in the editor
	;
		call	EditorPurge
	LONG	jc	done
	;
	; get the map size
	;
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS YSizeValue, bx
		mov	si, offset YSizeValue
		mov	di, mask MF_CALL
		call	ObjMessage			; dx.cx = value
		mov	es:[editorMap].M_header.MH_rows, dl

		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	si, offset XSizeValue
		mov	di, mask MF_CALL
		call	ObjMessage			; dx.cx = value
		mov	es:[editorMap].M_header.MH_columns, dl
	;
	; clear out the map
	;
		clr	es:[editorMap].M_header.MH_packets
		clr	es:[editorMap].M_header.MH_saved
		mov	es:[editorMap].M_header.MH_position.P_x, -1
		mov	es:[editorMap].M_header.MH_position.P_y, -1
		lea	di, es:[editorMap].M_data
		mov	al, SST_GROUND
		mov	cx, size MapArray
		rep	stosb				; write cx times
	;
	; resize the content
	;
		call	UpdateEditorSize
	;
	; dirty the editor
	;
		mov	cx, BW_TRUE
		call	ChangeDirtyFlag
	;
	; set level number to first unused level
	;
		call	SokobanFindEmptyLevel		; cx = level number
		clr	bp				; not indeterminate
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		GetResourceHandleNS EditorLevel, bx
		mov	si, offset EditorLevel
		clr	di
		call	ObjMessage
	;
	; bring up the editor dialog
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		GetResourceHandleNS EditorDialog, bx
		mov	si, offset EditorDialog
		clr	di
		call	ObjMessage
done:		
		.leave
		ret
SokobanCreateLevel	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SokobanEditLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a level into the editor

CALLED BY:	MSG_SOKOBAN_EDIT_LEVEL
PASS:		es 	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SokobanEditLevel	method dynamic SokobanProcessClass, 
					MSG_SOKOBAN_EDIT_LEVEL
		uses	ax, cx, dx, bp
		.enter
	;
	; remove the level dialog
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		GetResourceHandleNS EditDialog, bx
		mov	si, offset EditDialog
		clr	di
		call	ObjMessage
	;
	; dump whatever's in the editor
	;
		call	EditorPurge
		jc	done
	;
	; get the level number
	;
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS EditLevel, bx
		mov	si, offset EditLevel
		mov	di, mask MF_CALL
		call	ObjMessage		; dx.cx = value
		mov	cx,dx			; cx = integer value
	;
	; load the level into the map
	;
		mov	di, offset es:[editorMap]
		call	LoadUserLevel
		jc	done
	;
	; update EditorLevel
	;
		clr	bp			; cx not indeterminate
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		GetResourceHandleNS EditorLevel, bx
		mov	si, offset EditorLevel
		clr	di
		call	ObjMessage
	;
	; update the content size
	; also forces the content to refresh
	;
		call	UpdateEditorSize
	;
	; clean the editor
	;
		mov	cx, BW_FALSE
		call	ChangeDirtyFlag
	;
	; bring up the editor dialog
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		GetResourceHandleNS EditorDialog, bx
		mov	si, offset EditorDialog
		clr	di
		call	ObjMessage
done:
		.leave
		ret
SokobanEditLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateEditorSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the content match the size of the board and force the
		view to match it or become scrollable

CALLED BY:	(INTERNAL)
PASS:		es     = dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateEditorSize proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Compute the size of the board.
	; 
		mov	ax, es:[bitmapWidth]
		mul	es:[editorMap].M_header.MH_columns
		mov_tr	cx, ax
		mov	ax, es:[bitmapHeight]
		mul	es:[editorMap].M_header.MH_rows
		mov_tr	dx, ax
	;
	; Set that as the size of the content.
	; 
		GetResourceHandleNS EditorContent, bx
		mov	si, offset EditorContent
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
		clr	di
		call	ObjMessage

		.leave
		ret
UpdateEditorSize endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentSelectTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the current tool

CALLED BY:	MSG_EDIT_CONTENT_SELECT_TOOL
PASS:		es	= dgroup
		cl	= new tool (SokobanSquareType)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentSelectTool	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_SELECT_TOOL
		mov	es:[currentTool], cl
		ret
EditContentSelectTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the editorMap on the screen.

CALLED BY:	MSG_VIS_DRAW

PASS:		es = dgroup
		^hbp = GState to draw through

RETURN:		nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentVisDraw	method dynamic EditContentClass, 
							MSG_VIS_DRAW
		uses	ax
		
		drawState	local	hptr.GState	push	bp
		startX		local	word
		xPos		local	word
		yPos		local	word
		column		local	byte
		
		.enter
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
		lea	di, es:[editorMap].M_data	; es:di = map array
		clr	column
		

		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax
mapLoop:
		clr	bh
		mov	bl, {byte} es:[di]		; get next byte
		push	di				; save pointer into map
		
		call	GetUnanimatedBitmapFromCharacter ; ds:si = bitmap
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
		
		.leave
		ret
EditContentVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the curent map object

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= EditContentClass object
		es 	= dgroup
		cx,dx	= position of mouse (x,y)
		bp low	= ButtonInfo
RETURN:		ax	= MRF_PROCESSED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditContentStartSelect	method dynamic EditContentClass, 
					MSG_META_START_SELECT,
					MSG_META_PTR
		uses	cx, dx, bp
		.enter
	;
	; if button1 isn't down, bail
	;
		test	bp, mask BI_B0_DOWN
		jz	done
down::
	;
	; convert window coordinate to map indices
	;
		call	ConvertDocCoordsToMapIndices	; (cx,dx) = map index
		jc	done
		cmp	dl, es:[editorMap].M_header.MH_rows
		jae	done
		cmp	cl, es:[editorMap].M_header.MH_columns
		jae	done
	;
	; get the 1d offset to the map location
	;
		mov	bx, cx
		mov	ax, dx
		call	ConvertArrayCoordinates		; bx = array offset
	;
	; don't do anything if the square is already the appropriate type
	; otherwise update the map
	;
		mov	al, es:[editorMap].M_data[bx]
		cmp	al, SST_WALL_NSEW
		ja	notWall
		mov	al, SST_WALL
notWall:
		cmp	al, es:[currentTool]
		je	done
change::
	;
	; update the current square
	;
		mov	al, es:[currentTool]
		xchg	al, es:[editorMap].M_data[bx]
		push	ax,bx,cx,dx
	;
	; dirty the editor
	;
		mov	cx, BW_TRUE
		call	ChangeDirtyFlag
	;
	; create a gstate for redraw work
	;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		mov	di,bp
	;
	; set the current background color
	;
		mov	ax, es:[colorOption]
		mov	ah, CF_INDEX
		call	GrSetAreaColor
	;
	; lock the bitmaps
	;
		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax
		pop	ax,bx,cx,dx
	;
	; now do the visual update
	;
		call	EditContentUpdateRegion
	;
	; cleanup
	;
		mov	bx, handle Bitmaps
		call	MemUnlock
		call	GrDestroyState

done:
		mov	ax, mask MRF_PROCESSED
		.leave
		ret
EditContentStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentUpdateRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the square which changed, as well as any surrounding
		wall spaces.

CALLED BY:	EditContentStartSelect
PASS:		ds	= segment of bitmaps
		es	= dgroup
		di	= gstate
		cx,dx   = (x,y) array coordinates
		bx	= lineal offset to (cl,dl)
		al	= old value of square at (cl,dl)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if the current square was a wall and no longer is
		for each surrounding wall square
			clear bit indicating a wall at original square
			redraw this square
	if the current square was not a wall but is now
		for each surrounding wall square
			set bit indicating a wall at original square
			set bit in original square indicating this wall
			redraw this square
	if the current square was a man and isn't now
		set position to -1,-1
	if the current square wasn't a man, but is now
		set position to current position
		replace square at old position by ground
	redraw original square

NOTES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentUpdateRegion	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; check for player state transitions
	;
		mov	bp,bx
		cmp	al, SST_PLAYER
		jne	wasntPlayer
		cmp	{byte}es:[editorMap].M_data[bp], SST_PLAYER
		je	checkWall
	;
	; we changed a player to a non-player
	;
		mov	es:[editorMap].M_header.MH_position.P_x, -1
		mov	es:[editorMap].M_header.MH_position.P_y, -1
		jmp	checkWall
	;
	; didn't used to be a player, is it now?
	;
wasntPlayer:
		cmp	{byte}es:[editorMap].M_data[bp], SST_PLAYER
		jne	checkWall
	;
	; changed non-player to player
	;
		push	ax,bx,cx,dx
		movdw	axbx, es:[editorMap].M_header.MH_position
		cmp	bx,-1
		je	noPrevious
		mov	cl,bl
		mov	dl,al
	;
	; change old player into ground
	;
		call	ConvertArrayCoordinates		; bx = offset
		mov	es:[editorMap].M_data[bx], SST_GROUND
		mov	bl, SST_GROUND
		call	EditContentUpdateSquare
	;
	; update position
	;
noPrevious:
		pop	ax,bx,cx,dx
		movdw	es:[editorMap].M_header.MH_position, dxcx
	;
	; check for wall state transitions
	;
checkWall:
		cmp	al, SST_WALL_NSEW
	LONG	ja	wasntWall
		cmp	{byte}es:[editorMap].M_data[bp], SST_WALL_NSEW
	LONG	jbe	draw
	;
	; we changed a wall to a non-wall
	; clear the appropriate bit in each surrounding space
	;
		tst	cl
		jz	clearEast
		mov	bl, es:[editorMap].M_data[bp][-1]
		cmp	bl,  SST_WALL_NSEW	; West
		ja	clearEast
		andnf	bl, not EAST
		mov	es:[editorMap].M_data[bp][-1], bl
		dec	cl
		call	EditContentUpdateSquare
		inc	cl
clearEast:
		cmp	cl, MAX_COLUMNS-1
		jae	clearNorth
		mov	bl, es:[editorMap].M_data[bp][1]
		cmp	bl,  SST_WALL_NSEW	; East
		ja	clearNorth
		andnf	bl, not WEST
		mov	es:[editorMap].M_data[bp][1], bl
		inc	cl
		call	EditContentUpdateSquare
		dec	cl
clearNorth:
		tst	dl
		jz	clearSouth
		mov	bl, es:[editorMap].M_data[bp][-MAX_COLUMNS]
		cmp	bl,  SST_WALL_NSEW
		ja	clearSouth
		andnf	bl, not SOUTH
		mov	es:[editorMap].M_data[bp][-MAX_COLUMNS], bl
		dec	dl
		call	EditContentUpdateSquare
		inc	dl
clearSouth:
		cmp	dl, MAX_ROWS-1
	LONG	jae	draw
		mov	bl, es:[editorMap].M_data[bp][MAX_COLUMNS]
		cmp	bl,  SST_WALL_NSEW
	LONG	ja	draw
		andnf	bl, not NORTH
		mov	es:[editorMap].M_data[bp][MAX_COLUMNS], bl
		inc	dl
		call	EditContentUpdateSquare
		dec	dl
		jmp	draw
	;
	; the current square used to be a non-wall
	;
wasntWall:
		cmp	{byte}es:[editorMap].M_data[bp], SST_WALL_NSEW
	LONG	ja	draw
	;
	; we changed a non-wall to a wall
	; set the apropriate bit in each surrounding square
	; simultaneously build the appropriate moniker for this square
	;
		clr	es:[editorMap].M_data[bp]
		
		tst	cl
		jz	setEast
		mov	bl, es:[editorMap].M_data[bp][-1]
		cmp	bl,  SST_WALL_NSEW	; West
		ja	setEast
		ornf	bl, EAST
		mov	{byte} es:[editorMap].M_data[bp][-1], bl
		ornf	{byte} es:[editorMap].M_data[bp], WEST
		dec	cl
		call	EditContentUpdateSquare
		inc	cl
setEast:
		cmp	cl, MAX_COLUMNS-1
		jae	setNorth
		mov	bl, es:[editorMap].M_data[bp][1]
		cmp	bl,  SST_WALL_NSEW	; East
		ja	setNorth
		ornf	bl, WEST
		mov	es:[editorMap].M_data[bp][1], bl
		ornf	{byte} es:[editorMap].M_data[bp], EAST
		inc	cl
		call	EditContentUpdateSquare
		dec	cl
setNorth:
		tst	dl
		jz	setSouth
		mov	bl, es:[editorMap].M_data[bp][-MAX_COLUMNS]
		cmp	bl,  SST_WALL_NSEW
		ja	setSouth
		ornf	bl, SOUTH
		mov	es:[editorMap].M_data[bp][-MAX_COLUMNS], bl
		ornf	{byte} es:[editorMap].M_data[bp], NORTH
		dec	dl
		call	EditContentUpdateSquare
		inc	dl
setSouth:
		cmp	dl, MAX_ROWS-1
		jae	draw
		mov	bl, es:[editorMap].M_data[bp][MAX_COLUMNS]
		cmp	bl,  SST_WALL_NSEW
		ja	draw
		ornf	bl, NORTH
		mov	es:[editorMap].M_data[bp][MAX_COLUMNS], bl
		ornf	{byte} es:[editorMap].M_data[bp], SOUTH
		inc	dl
		call	EditContentUpdateSquare
		dec	dl
draw:
		mov	bl, es:[editorMap].M_data[bp]
		call	EditContentUpdateSquare
		.leave
		ret
EditContentUpdateRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentUpdateSquare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw one square of the map

CALLED BY:	EditContentStartSelect
PASS:		di - gstate for content
		cl,dl = (x,y) map index being updated
		bl    = symbol to draw (SokobanSquareType)
		ds    = segment of bitmaps
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentUpdateSquare	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; handle grass specially
	;
		cmp	bl, SST_GRASS
		je	grass
	;
	; get an appropriate bitmap
	;
		call	GetUnanimatedBitmapFromCharacter ; ds:si = bitmap
		jc	doneDrawing			; don't crash.
	;
	; convert coordinates
	;
		mov	bl, cl
		mov	al, dl
		call	ConvertPositionToPixels	; (ax,bx) = pixel position
	;
	; draw the bitmap
	;
		clr	dx				; no callback
		call	GrDrawBitmap
doneDrawing:
		.leave
		ret
grass:
	;
	; for grass, just draw a blank square
	; note that view's background color is already in gstate
	;
		mov	bl, cl
		mov	al, dl
		call	ConvertPositionToPixels	; (ax,bx) = pixel position
		mov	cx,ax
		mov	dx,bx
		add	cx, es:[bitmapWidth]
		add	dx, es:[bitmapHeight]
		call	GrFillRect
		jmp	doneDrawing
		
EditContentUpdateSquare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentSaveLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current level to disk

CALLED BY:	MSG_EDIT_CONTENT_SAVE_LEVEL
PASS:		es 	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentSaveLevel	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_SAVE_LEVEL
		uses	ax, cx, dx, bp
		.enter
	;
	; get the level number
	;
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS EditorLevel, bx
		mov	si, offset EditorLevel
		mov	di, mask MF_CALL
		call	ObjMessage			; dx.cx = value
		mov	cx,dx
	;
	; pass level to the edit dialog
	;
		clr	bp				; not indeterminate
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		GetResourceHandleNS EditorLevel, bx
		mov	si, offset EditorLevel
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; actually save the level
	;
		segmov	ds,es
		mov	si, offset ds:[editorMap]
		mov	cx,dx				; cx = level
		call	SaveUserLevel
		jc	skipClean
	;
	; clean the editor
	;
		mov	cx, BW_FALSE
		call	ChangeDirtyFlag
	;
	; invalidate the content, so updated grass/ground will show
	;
skipClean:
		pushf
		mov	ax, MSG_VIS_INVALIDATE
		GetResourceHandleNS EditorContent, bx
		mov	si, offset EditorContent
		clr	di
		call	ObjMessage
		popf

		.leave
		ret
EditContentSaveLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeDirtyFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change the editor's dirty flag

CALLED BY:	EditContentSaveLevel
PASS:		cx = dirty status (BooleanWord)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeDirtyFlag	proc	near
		uses	ax,bx,si,di
		.enter
	;
	; set the dirty bit
	;
		mov	ax, MSG_EDIT_CONTENT_SET_DIRTY_FLAG
		GetResourceHandleNS EditorContent, bx
		mov	si, offset EditorContent
		clr	di
		call	ObjMessage
		.leave
		ret
ChangeDirtyFlag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentLevelChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The level spinner has been changed

CALLED BY:	MSG_EDIT_CONTENT_LEVEL_CHANGED
PASS:		*ds:si	= EditContentClass object
RETURN:		nothing
DESTROYED:	ax,cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentLevelChanged	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_LEVEL_CHANGED

		mov	ax, MSG_EDIT_CONTENT_SET_DIRTY_FLAG
		mov	cl, BB_TRUE
		GOTO	ObjCallInstanceNoLock
EditContentLevelChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentSetDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the dirty flag

CALLED BY:	MSG_EDIT_CONTENT_SET_DIRTY_FLAG
PASS:		*ds:si	= EditContentClass object
		ds:di	= EditContentClass instance data
		cl	= new value of dirty flag (BooleanByte)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentSetDirtyFlag	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_SET_DIRTY_FLAG
		uses	ax, cx, dx, bp
		.enter
	;
	; do nothing unless we are changing state
	;
		cmp	cl, ds:[di].ECI_dirty
		je	done
	;
	; update the flag itself
	;
		mov	ds:[di].ECI_dirty, cl
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jcxz	enableDisable
		mov	ax, MSG_GEN_SET_ENABLED
	;
	; enable or disable the "save" the trigger
	;
enableDisable:
		mov	dl, VUM_NOW
		GetResourceHandleNS EditorSave, bx
		mov	si, offset EditorSave
		clr	di
		call	ObjMessage
done:
		.leave
		ret
EditContentSetDirtyFlag	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentGetDirtyFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the dirty flag

CALLED BY:	MSG_EDIT_CONTENT_GET_DIRTY_FLAG
PASS:		ds:di	= EditContentClass instance data
RETURN:		cl	= BB_TRUE if dirty, BB_FALSE if clean
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentGetDirtyFlag	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_GET_DIRTY_FLAG
		mov	cl, ds:[di].ECI_dirty
		ret
EditContentGetDirtyFlag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditorPurge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check with user before discarding editor contents

CALLED BY:	SokobanCreateLevel, SokobanEditLevel, EditContentQuit
PASS:		es = dgroup
RETURN:		carry - set to abort operation
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

triggerTable	StandardDialogResponseTriggerTable <3>
		StandardDialogResponseTriggerEntry <0, IC_YES>
		StandardDialogResponseTriggerEntry <0, IC_NO>
		StandardDialogResponseTriggerEntry <0, IC_DISMISS>

EditorPurge	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; enable the "return to editor button"
	; this isn't logically part of this routine, but its a
	; convenient place to stick it
	;
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		GetResourceHandleNS ReturnTrigger, bx
		mov	si, offset ReturnTrigger
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; if the editor is clean, don't bother asking
	;
		mov	ax, MSG_EDIT_CONTENT_GET_DIRTY_FLAG
		GetResourceHandleNS EditorContent, bx
		mov	si, offset EditorContent
		mov	di, mask MF_CALL
		call	ObjMessage			; cl = dirty flag
		tst	cl
		clc
		jz	done
	;
	; ask if we should save the current contents
	;
		sub	sp, size StandardDialogOptrParams
		mov	bp,sp
		mov	ss:[bp].SDOP_customFlags, CustomDialogBoxFlags <0,CDT_QUESTION,GIT_MULTIPLE_RESPONSE,0>
		mov	ss:[bp].SDOP_customString.handle, handle ReplaceWarning
		mov	ss:[bp].SDOP_customString.offset, offset ReplaceWarning
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		mov	ax,cs
		mov	ss:[bp].SDOP_customTriggers.segment, ax
		mov	ss:[bp].SDOP_customTriggers.offset, offset triggerTable
		clrdw	ss:[bp].SDOP_helpContext
		call	UserStandardDialogOptr		; ax = interaction cmd
	;
	; see if we need to save
	;
		cmp	ax, IC_NO
		clc
		je	done
		cmp	ax, IC_YES
		stc
		jne	done
	;
	; get the level number to save
	;
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS EditorLevel, bx
		mov	si, offset EditorLevel
		mov	di, mask MF_CALL
		call	ObjMessage			; dx.cx = value
		mov	cx,dx
	;
	; actually save the level
	;
		segmov	ds,es
		mov	si, offset ds:[editorMap]
		mov	cx,dx				; cx = level
		call	SaveUserLevel			; carry set if failed
done:
		.leave
		ret

EditorPurge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Confirm shutdown

CALLED BY:	MSG_META_QUIT
PASS:		es 	= dgroup
		^lcx:dx   = object to receive ACK
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentQuit	method dynamic EditContentClass, 
					MSG_META_QUIT
		uses	ax, cx, dx, bp
		.enter
	;
	; set up for acknowledgement
	;
		movdw	bxsi, cxdx		; OD of receiver
		clr	cx			; continue quitting
	;
	; confirm with user
	;
		call	EditorPurge		; carry set to abort
		jnc	ack
		dec	cx			; cx = -1: abort quit
	;
	; send the acknowlegement
	;
ack:
		mov	ax, MSG_META_QUIT_ACK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
EditContentQuit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentInitiateResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the resize dialog

CALLED BY:	MSG_EDIT_CONTENT_INITIATE_RESIZE
PASS:		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentInitiateResize	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_INITIATE_RESIZE
		uses	ax, cx, dx, bp
		.enter
	;
	; set the rows spinner
	;
		clr	bp			; not indeterminate
		clr	ch
		mov	cl, es:[editorMap].M_header.MH_rows
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		GetResourceHandleNS EditorResizeRowsValue, bx
		mov	si, offset EditorResizeRowsValue
		clr	di
		call	ObjMessage
	;
	; set the columns spinner
	;
		clr	bp			; not indeterminate
		clr	ch
		mov	cl, es:[editorMap].M_header.MH_columns
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		GetResourceHandleNS EditorResizeColumnsValue, bx
		mov	si, offset EditorResizeColumnsValue
		clr	di
		call	ObjMessage
	;
	; bring up the dialog
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		GetResourceHandleNS EditorResizeDialog, bx
		mov	si, offset EditorResizeDialog
		clr	di
		call	ObjMessage
		
		.leave
		ret
EditContentInitiateResize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditContentResizeLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the level

CALLED BY:	MSG_EDIT_CONTENT_RESIZE_LEVEL
PASS:		*ds:si	= EditContentClass object
		ds:di	= EditContentClass instance data
		ds:bx	= EditContentClass object (same as *ds:si)
		es 	= segment of EditContentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditContentResizeLevel	method dynamic EditContentClass, 
					MSG_EDIT_CONTENT_RESIZE_LEVEL
		uses	ax, cx, dx, bp
		.enter
	;
	; dirty the editor
	;
		mov	cl, BB_TRUE
		call	ChangeDirtyFlag
	;
	; kill the dialog box
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		GetResourceHandleNS EditorResizeDialog, bx
		mov	si, offset EditorResizeDialog
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; get the rows spinner
	;
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS EditorResizeRowsValue, bx
		mov	si, offset EditorResizeRowsValue
		mov	di, mask MF_CALL
		call	ObjMessage		; dx = rows
	;
	; get the columns spinner
	;
		push	dx
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		GetResourceHandleNS EditorResizeColumnsValue, bx
		mov	si, offset EditorResizeColumnsValue
		mov	di, mask MF_CALL
		call	ObjMessage		; dx = columns
		pop	cx			; cx = rows
	;
	; resize the level
	;
		mov	di, offset editorMap
		call	ResizeLevel
	;
	; update the geometry
	;
		call	UpdateEditorSize
		.leave
		ret
EditContentResizeLevel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a level

CALLED BY:	EditContentResizeLevel
PASS:		es:di	= map to update
		cx	= new row count
		dx	= new column count
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeLevel	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; see if player is now out of bounds
	;
		cmp	dx, es:[di].MH_position.P_x
		jle	badPos
		cmp	cx, es:[di].MH_position.P_y
		jg	doCols
badPos:
		movdw	es:[di].MH_position, -1
	;
	; handle any wall changes
	;
		call	UpdateWallsForResize
	;
	; update the affected columns
	;
doCols:
		push	cx
		mov	si,di			; backup pointer
	;
	; determine the ordered range of columns being added or deleted
	;
		clr	ah
		mov_tr	al, es:[di].MH_columns	; ax = current column count
		mov	es:[di].MH_columns, dl	; store new count
		cmp	al, dl
		je	doRows			; no change in cols
		jb	colsOrdered		; deleting cols
		xchg	al, dl			; adding cols
	;
	; set those columns of each row to SST_GROUND
	;
colsOrdered:
		sub	dl, al			; dl = # of cols to update
		mov	bl, es:[di].MH_rows	; bl = row count
		add	di, offset M_data	; es:di = first row
		add	di, ax			; es:di = start col of 1st row
colLoop:
		mov	cx, dx			; # of bytes to write
		mov	al, SST_GROUND		; byte to be written
		push	di
		rep	stosb			; write it out
		pop	di
		add	di, MAX_COLUMNS		; skip to next row
		dec	bl		
		jnz	colLoop			; do next row
	;
	; now figure out the range of rows
	;
doRows:
		pop	dx			; dl = new row count
		mov	di, si			; es:di = Map
		mov_tr	bl, es:[di].MH_rows	; bl = current row count
		mov	es:[di].MH_rows, dl  ; store new count
		cmp	bl, dl
		je	done			; no change in rows
		jb	rowsOrdered		; deleting rows
		xchg	bl, dl
rowsOrdered:
	;
	; its easiest to clear the entire rows, rather then only the
	; columns being changed
	;
		sub	dl, bl			; dl = # of rows to update
		mov	ax, MAX_COLUMNS
		mul	bl			; ax = start offset
		add	di, offset M_data
		add	di, ax			; es:di = start row
		mov	ax, MAX_COLUMNS
		mul	dl			; ax = size of range in bytes
		mov	cx, ax			; cx = # of bytes to write
		mov	al, SST_GROUND
		rep	stosb
done:
		.leave
		ret
ResizeLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWallsForResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the wall type for walls along the new edge, if
		level is shrinking
CALLED BY:	ResizeLevel
PASS:		es:di	- level to update
		cx	- new row count
		dx	- new column count
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWallsForResize	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		segmov	ds,es
	;
	; see if we are shrinking vertically
	;
		cmp	cl, es:[di].MH_rows
		jae	doCols
	;
	; update all the walls along the new south edge
	;
		push	di
		mov	ax, MAX_COLUMNS		; ax = size of a row
		dec	cl			; cl = max row
		mul	cl			; ax = offset of last row
		mov	cl, es:[di].MH_columns	; # of columns to update
		add	di, offset M_data	; es:di = first row
		add	di, ax			; es:di = bottom row
		mov	si,di			; ds:si = bottom row
colLoop:
		lodsb
		cmp	al, SST_WALL_NSEW
		ja	nextCol
		andnf	al, not SOUTH
nextCol:
		stosb
		loop	colLoop
		pop	di			; es:di = map
	;
	; see if we are shrinking horizontally
	;
doCols:
		cmp	dl, es:[di].MH_columns
		jae	done
	;
	; update all walls along the new east edge
	;
		clr	ch
		mov	cl, es:[di].MH_rows	; number of rows to update
		add	di, offset M_data
		dec	dl
		add	di, dx			; es:di = last col of 1st row
		mov	si, di
rowLoop:
		lodsb
		cmp	al, SST_WALL_NSEW
		ja	nextRow
		andnf	al, not EAST
		stosb
nextRow:
		add	si, MAX_COLUMNS-1
		mov	di, si
		loop	rowLoop
done:
		.leave
		ret
UpdateWallsForResize	endp

CommonCode	ends
