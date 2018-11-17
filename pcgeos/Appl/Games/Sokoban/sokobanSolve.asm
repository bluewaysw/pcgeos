COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		sokobanSolve.asm

AUTHOR:		Steve Yegge, Dec 18, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/18/93	Initial revision

DESCRIPTION:

	Routines for making the little guy move automatically.

	$Id: sokobanSolve.asm,v 1.1 97/04/04 15:13:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
;  More constants & type declarations...
;

BADMOVE		equ	MAX_ROWS * MAX_COLUMNS

;
; Maximum recursive depth on FindTarget is BADMOVE+1, each recursion
; adds two bytes two the stack.  
;
SEARCHSTACK	equ	(BADMOVE+1)*2

Row	struct
R_columns		word		MAX_COLUMNS	dup (0)
Row	ends

;
;  Global variables to assist our efforts.
;
udata	segment

mapOffset	word		; chunk handle of MapContent object

findMap		Row	MAX_ROWS	dup (<>)

udata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveMan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds shortest path & moves little guy there.

CALLED BY:	MapStartSelect

PASS:		*ds:si	= MapContent instance
		es	= dgroup
		(cx,dx)	= target

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveMan	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Check that we're in bounds.
	;
		movdw	bxax, cxdx

		test	bx, 8000h			; negative?
		LONG	jnz	done
		test	ax, 8000h			; negative?
		LONG	jnz	done

		cmp	bx, MAX_COLUMNS			; off-scale right?
		LONG	jae	done
		cmp	ax, MAX_ROWS			; off-scale bottom?
		LONG	jae	done
	;
	;  Return if this isn't a legal place to click.
	;
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]

		cmp	al, SST_GROUND			; ground?
		je	legalTarget
		cmp	al, SST_SAFE			; safe?
		jne	notFound
legalTarget:
	;
	;  This is a legal place to click, so set it up by filling
	;  the trace map with all impossible values.
	;
		push	cx
		mov	di, offset findMap
		mov	ax, BADMOVE
CheckHack < (size findMap and 1) eq 0 >
		mov	cx, (size findMap)/2
		rep	stosw
		pop	cx
	;
	;  Make sure we have enough stack space for the search
	;
		mov	di, SEARCHSTACK
		call	ThreadBorrowStackSpace		; di = token
	;
	;  Flood-fill search to find any shortest path.
	;
		mov	es:[mapOffset], si		; save chunk handle
		clr	si				; initial length = 0
		call	FindTarget			; destroys ax,bx
	;
	;  Give the stack space back
	;
		call	ThreadReturnStackSpace
	;
	;  If we didn't make it back to the player's position, there
	;  is no valid path to that place.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		call	ConvertArrayCoordinates		; bx = byte offset
		shl	bx				; bx = word offset

		mov	di, offset findMap
		cmp	{word}es:[findMap][bx], BADMOVE
		je	notFound
walkMan::
	;
	;  We made it back, so let's walk the path we just built up.
	;
		call	WalkPath
		call	UpdateMan			; at Adam's behest...
		jmp	done
notFound:
	;
	;  Beep at them.  Well, OK...don't.  It gets annoying if
	;  they're holding down the mouse button & trying to run
	;  to an illegal location.  Beeeeeeeeeeeeeeeeeeeeeeeeeeeeep.
	;
if 0
		mov	ax, SST_ERROR
		call	UserStandardSound
endif
done:
		.leave
		ret
MoveMan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WalkPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move little guy along path to target.

CALLED BY:	MoveMan

PASS:		es = dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

Here's the original code, from the X-windows version.

    /* we made it back, so let's walk the path we just built up */
    cx = ppos.x;
    cy = ppos.y;
    while(findmap[cx][cy]) {
      if(findmap[cx - 1][cy] == (findmap[cx][cy] - 1)) {
	MakeMove(XK_Up);
	cx--;
      } else if(findmap[cx + 1][cy] == (findmap[cx][cy] - 1)) {
	MakeMove(XK_Down);
	cx++;
      } else if(findmap[cx][cy - 1] == (findmap[cx][cy] - 1)) {
	MakeMove(XK_Left);
	cy--;
      } else if(findmap[cx][cy + 1] == (findmap[cx][cy] - 1)) {
	MakeMove(XK_Right);
	cy++;
      } else {
	/* if we get here, something is SERIOUSLY wrong, so we should abort */
	abort();
      }
    }

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WalkPath	proc	near
		uses	ax, bx, cx, si, di
		.enter
	;
	;  Walk the path we built up.  The starting (x,y) coordinates
	;  are the current player's position.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
whileLoop:
	;
	;  To make this a valid test-at-top loop, we test at the
	;  top (what a concept).
	;
		call	GetFindMapEntry			; si = FM[x][y]
		tst	si				; done yet?
		jz	done
	;
	;  One value used throughout the loop is (findMap[x][y] - 1).
	;  We already have findMap[x][y] ... just decrement & save it.
	;
		dec	si				; si = FM[x][y] - 1
		mov	di, si				; di = loop invariant
	;
	;  Check for a move left.  Needs findMap[x-1][y].
	;
		dec	bx				; bx = x-1
		call	GetFindMapEntry			; si = FM[x-1][y]
		inc	bx				; bx = x
		cmp	si, di				; equal?
		jne	notMoveLeft

		dec	bx				; X = X-1 (moved left)
		mov	cx, MD_LEFT			; move little guy left
		jmp	doMove				; do move & loop
notMoveLeft:
	;
	;  Check for a move right.  Needs findMap[x+1][y].
	;
		inc	bx				; bx = x+1
		call	GetFindMapEntry			; si = FM[x+1][y]
		dec	bx				; bx = x
		cmp	si, di				; equal?
		jne	notMoveRight

		inc	bx				; X = X+1 (moved right)
		mov	cx, MD_RIGHT			; move him right!
		jmp	doMove				; do move & loop
notMoveRight:
	;
	;  Check for a move up.  Needs findMap[x][y-1].
	;
		dec	ax				; ax = y-1
		call	GetFindMapEntry			; si = FM[x][y-1]
		inc	ax
		cmp	si, di
		jne	notMoveUp

		dec	ax				; Y = Y-1 (moved up)
		mov	cx, MD_UP
		jmp	doMove
notMoveUp:
	;
	;  Check for a move down.  Needs findMap[x][y+1]
	;
		inc	ax				; ax = y+1
		call	GetFindMapEntry			; si = FM[x][y+1]
		dec	ax				; ax = y
		cmp	si, di
		jne	error

		inc	ax				; Y = Y+1
		mov	cx, MD_DOWN
		jmp	doMove
error:
	;
	;  If we got here, the findMap was screwed up.  Abort
	;  the motion.
	;
		jmp	done				; error!
doMove:
		call	MovePlayerCommon
nextMove::
	;
	;  bx & ax are set up to hold the next position to check
	;  already.  Just jump to the top.
	;
		jmp	whileLoop
done:
		.leave
		ret
WalkPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFindMapEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an entry out of the findMap.

CALLED BY:	WalkPath

PASS:		bx = x to look at
		ax = y to look at

RETURN:		si = findMap[x][y]

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/ 5/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFindMapEntry	proc	near
		uses	ax,bx,di
		.enter

		call	ConvertArrayCoordinates		; bx = byte offset
		shl	bx				; es:di:bx = location

		mov	si, {word}es:[findMap][bx]

		.leave
		ret
GetFindMapEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the shortest path to the target via a fill search
		algorithm.  Stolen from the X version & rewritten in
		assembly.

CALLED BY:	MoveMan, FindTarget

PASS:		cx = x
		dx = y
		si = path length
		es = dgroup

RETURN:		nothing

DESTROYED:	ax,bx

NOTES:	The recusive depth could theoreticly be as much as
	MAX_ROWS*MAX_COLUMNS, so we'd better have enough stack space
	for that.  To reduce stack usage, nothing is pushed.

PSEUDO CODE/STRATEGY:

Here's the original relevant code:

    ...
    for(i = 0; i < MAXROW + 1; i++)
      for (j = 0; j < MAXCOL + 1; j++)
	findmap[i][j] = BADMOVE;
    /* flood fill search to find any shortest path. */
    FindTarget(x, y, 0);
    ...

  /* find the shortest path to the target via a fill search algorithm */
  void FindTarget(int px, int py, int pathlen)
  {
    if(!(ISCLEAR(px, py) || ISPLAYER(px, py)))
      return;
    if(findmap[px][py] <= pathlen)
      return;

    findmap[px][py] = pathlen++;

    if((px == ppos.x) && (py == ppos.y))
      return;

    FindTarget(px - 1, py, pathlen);
    FindTarget(px + 1, py, pathlen);
    FindTarget(px, py - 1, pathlen);
    FindTarget(px, py + 1, pathlen);
  }

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTarget	proc	near
	;
	;  If (cx,dx) isn't a clear/ground or player/safeplayer, quit.
	;
		movdw	bxax, cxdx
		call	ConvertArrayCoordinates		; bx <- offset
		mov	al, {byte} es:[currentMap + (size MapHeader)][bx]

		cmp	al, SST_GROUND
		je	spotOK

		cmp	al, SST_SAFE
		je	spotOK

		cmp	al, SST_PLAYER
		je	spotOK

		cmp	al, SST_SAFE_PLAYER
		jne	exit
spotOK:
	;
	;  If this spot on the findMap is greater than the passed
	;  path length, return.
	;
		shl	bx				; map is array of words
		cmp	{word}es:[findMap][bx], si
		jle	exit
	;
	;  Store the current pathlength into the findMap at
	;  this location.
	;
		mov	{word}es:[findMap][bx], si
		inc	si				; increment pathlength
	;
	;  If the passed (x,y) equals the current player (x,y), we
	;  found our way back to the player.  Return.
	;
		cmp	cx, es:[currentMap].M_header.MH_position.P_x
		jne	notSame

		cmp	dx, es:[currentMap].M_header.MH_position.P_y
		je	cleanup				; both the same!!
notSame:
	;
	;  Call FindTarget recursively on our (W, E, N, S) children.
	;
		dec	cx				; (x-1, y)
		call	FindTarget

		inc	cx
		inc	cx				; (x+1, y)
		call	FindTarget

		dec	cx
		dec	dx				; (x, y-1)
		call	FindTarget

		inc	dx
		inc	dx				; (x, y+1)
		call	FindTarget
	;
	; restore dx and si
	;
		dec	dx
cleanup:
		dec	si
exit:
		ret
FindTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateMan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the guy look debonaire after his wind sprint.

CALLED BY:	MoveMan

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:

	People found it strange that when the man ran to the square
	they clicked on, he wasn't always facing the bag they were
	planning on pushing.  And his legs weren't always together.

	So we look to his left, and then his right, for a bag.  If
	there is a bag to his left, or his right, we face him that
	way, with preference arbitrarily given to the left.

	Whether there's a bag or not we make sure his legs are
	together.  Then we get the video mode and the right bitmap,
	and draw him.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateMan	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Update the walkInfo record for the draw.
	;
		andnf	es:[walkInfo], not (mask WS_LEGS)	; legs together
	;
	;  See if there's a bag to the left.
	;
		mov	bx, es:[currentMap].M_header.MH_position.P_x
		dec	bx				; x = x-1
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		call	ConvertArrayCoordinates		; bx = offset

		cmp	{byte} es:[currentMap + (size MapHeader)][bx], \
				SST_BAG
		je	bagLeft

		cmp	{byte} es:[currentMap + (size MapHeader)][bx], \
				SST_SAFE_BAG
		jne	checkRight
bagLeft:
	;
	;  Make sure he's facing to the left.
	;
		test	es:[walkInfo], mask WS_FACE	; set = RIGHT
		jz	drawBitmap			; already there

		andnf	es:[walkInfo], not (mask WS_FACE or mask WS_DIR)
		ornf	es:[walkInfo], MD_LEFT		; set direction
		jmp	drawBitmap
checkRight:
	;
	;  See if there's a bag to the right.  As long as the currentMap
	;  consists of bytes, we can simply increment bx twice here to
	;  get the offset.
	;
CheckHack <size Map eq (MAX_ROWS * MAX_COLUMNS + size MapHeader)>

		inc	bx
		inc	bx				; bx = square to right
		cmp	{byte} es:[currentMap + (size MapHeader)][bx], \
				SST_BAG
		je	bagRight

		cmp	{byte} es:[currentMap + (size MapHeader)][bx], \
				SST_SAFE_BAG
		jne	drawBitmap			; fix legs, anyway
bagRight:
	;
	;  Make sure he's facing right.
	;
		test	es:[walkInfo], mask WS_FACE	; set = RIGHT
		jnz	drawBitmap			; set legs
		
		ornf	es:[walkInfo], mask WS_FACE	; face him there
		andnf	es:[walkInfo], not (mask WS_DIR); clear direction
		ornf	es:[walkInfo], MD_RIGHT		; going right
drawBitmap:
	;
	;  Lock the bitmaps resource.
	;
		push	ds
		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax
	;
	;  Get the appropriate bitmap.
	;
		test	es:[walkInfo], mask WS_SAFE	; safe player?
		jz	player
		mov	bl, SST_SAFE_PLAYER
		jmp	getBitmap
player:
		mov	bl, SST_PLAYER
getBitmap:
		call	GetCorrectBitmapFromCharacter	; ds:si = bitmap
	;
	;  Draw it.
	;
		mov	di, es:[gstate]

EC <		tst	di						>
EC <		ERROR_Z	NO_GSTATE_AVAILABLE_FOR_DRAWING			>

		mov	bx, es:[currentMap].M_header.MH_position.P_x
		mov	ax, es:[currentMap].M_header.MH_position.P_y
		call	ConvertPositionToPixels		; ax = x, bx = y
		clr	dx				; no callback
		call	GrDrawBitmap

		mov	bx, handle Bitmaps
		call	MemUnlock
		pop	ds
done::
		.leave
		ret
UpdateMan	endp


CommonCode	ends
