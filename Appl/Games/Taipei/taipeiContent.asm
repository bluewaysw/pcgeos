COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taipeiContent.asm

AUTHOR:		Jason Ho, Jan 23, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/23/95		Initial revision

DESCRIPTION:
	Implementation of TaipeiContent class.

RCS Stamp:
	$Id: taipeiContent.asm,v 1.1 97/04/04 15:14:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	;
	; There must be a class structure for every class you
	; intend to use somewhere in idata.
	;
TaipeiClassStructures	segment resource
	TaipeiContentClass
TaipeiClassStructures	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize all the instance data, and remove all vobjs.

CALLED BY:	MSG_TAIPEI_CONTENT_INITIALIZE, by process

PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	mem block might move

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentInitialize	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_INITIALIZE
	;
	; initialize Instance data
	;
		mov	ds:[di].TCI_tilesLeft, INITIAL_NUMBER_OF_TILES
		mov	cx, INITIAL_NUMBER_OF_TILES
		clr	bx
iniOne:		mov	ds:[di].TCI_stillIn[bx], 1
		inc	bx
		loop	iniOne
	;
	; Start the timer that might be stopped.
	;
		mov	ax, MSG_TAIPEI_CONTENT_START_TIMER
		call	ObjCallInstanceNoLock
		
		clr	ax
		czr	ax, ds:[di].TCI_selectedTileHandle
		czr	ax, ds:[di].TCI_selectedTileType
		czr	ah, ds:[di].TCI_miscFlags
		czr	ax, ds:[di].TCI_lastRemovedTile1Handle
		czr	ax, ds:[di].TCI_lastRemovedTile2Handle
		czr	ax, ds:[di].TCI_time
		
	;
	; destroy all the old children
	;
	;	mov	ax, MSG_VIS_DESTROY
	;	mov	dl, VUM_NOW
	;	call	VisSendToChildren		; ax, bx, di destroyed 
							; block may move
	;
	; Redraw
	;
	;	mov	ax, MSG_VIS_INVALIDATE
	;	call	ObjCallInstanceNoLock		; nothing destroyed

	;
	; change the value of TileCount GenValue
	; TaipeiTilesCount sits in Interface
	;
		GetResourceHandleNS Interface, bx    
		mov     si, offset TaipeiTilesCount	; ^lbx:si <- object
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		mov	cx, INITIAL_NUMBER_OF_TILES
		mov     di, mask MF_CALL                ; or mask MF_FIXUP_DS
		clr	bp
		call	ObjMessage			; ax, cx, dx destroyed
							; Block moves
	;
	; disable undo
	;
		GetResourceHandleNS	UndoMoveTrigger, bx
		mov     si, offset UndoMoveTrigger
		mov     ax, MSG_GEN_SET_NOT_ENABLED
		mov     dl, VUM_NOW
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage

		ret
TaipeiContentInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentCreateTiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create 144 tiles as Vobjs. Called by the OpenApplication
		message handler.

CALLED BY:	MSG_TAIPEI_CREATE_TILES
PASS:		*ds:si	= TaipeiContentClass object (TaipeiViewContent)
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	Block moves

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentCreateTiles	method dynamic TaipeiContentClass,
					MSG_TAIPEI_CONTENT_CREATE_TILES

		mov	cx, INITIAL_NUMBER_OF_TILES 
makeOne:
		mov	ax, MSG_TAIPEI_CONTENT_MAKE_ONE_TILE
		call	ObjCallInstanceNoLock		; ax, dx destroyed
							; block moved
		loop	makeOne
		ret
TaipeiContentCreateTiles	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentMakeOneTile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create one vobj tile

CALLED BY:	TaipeiContentCreateTiles
PASS:		*ds:si	= Instance
		ds:si	= Instance
		es	= Class segment
		cx <- tile index (zero based) + 1
RETURN:		nothing
DESTROYED:	everything except cx, bp
SIDE EFFECTS:	
		cx _CANNOT_ get trashed. It is the tile index counter.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Much of this is copied from VObj by John.
	kho	1/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentMakeOneTile	method dynamic TaipeiContentClass,
					MSG_TAIPEI_CONTENT_MAKE_ONE_TILE

		uses	cx, bp
		
		infoBlock	local	BoardConfigBlock
		
		.enter
	;
	; Ensure that our pointer is valid.
	;
EC <		Assert	fptr, dsdi					>
EC <		Assert	segment es					>

		push	si			; Save our chunk handle

	;
	; Find the tile info element and fill the local variable
	;
		push	ds:[LMBH_handle]
		GetResourceHandleNS DataResource, bx	; bx <- handle of
							; DataResource 
		call	MemLock				; ax <- segment of
							; lmem block
		mov_tr	ds, ax				; ds <- segment lmem
		mov	si, offset BoardInfo		; *ds:si <- chunk
							; array 

		mov	ax, cx				; 
		dec	ax				; ax <- index
		mov	cx, ss
		lea	dx, ss:[infoBlock]
		call	ChunkArrayGetElement		; cx:dx <- element
							; caray set
							; if out of bound
		call	MemUnlock

	;
	; Create a new VObj object.
	;
		pop	bx			; bx <- block handle
		call	MemDerefDS		; ds <- segment
		
EC <		Assert	handle, bx					>
		mov	di, offset TaipeiTileClass
						; es:di <- class pointer
		call	ObjInstantiate		; Create new TT object
						; si <- chunk of new object
		
EC <		Assert	objectPtr, dssi, TaipeiTileClass		>
	;
	; Since ObjInstantiate allocates a chunk on the LMem heap which
	; contains our content object, the pointer we had in ds:di may
	; not be valid (if the chunks were moved around as part of allocating
	; the new object). We need to re-dereference the chunk handle to get
	; a pointer to the objects instance data so we can scarf stuff from
	; it.
	;
	; On the stack right now is our chunk handle (saved above).
	;
		pop	di				; di <- chunk handle
EC <		Assert	objectPtr, dsdi, TaipeiContentClass		>
		
		mov	di, ds:[di]			; ds:di <- our
							; instance data 
		add	di, ds:[di].Vis_offset

	;
	; Set the grid position, AND VIS position (pixels)
	;
		mov	cx, ss:[infoBlock].BCT_position.P_x
		mov	dx, ss:[infoBlock].BCT_position.P_y
		mov	bx, ss:[infoBlock].BCT_level		
		call	TaipeiContentGetCorner		; cx <- left
							; dx <- top
							; ax trashed
		mov	ax, MSG_VIS_SET_POSITION
		call	ObjCallInstanceNoLock		; nothing destroyed
	;	call	VisSetPosition
	;
	; Set the VIS size
	;
		mov	cx, TILE_WIDTH_WITH_SHADOW
		mov	dx, TILE_HEIGHT_WITH_SHADOW
	;	mov	ax, MSG_VIS_SET_SIZE
	;	call	ObjCallInstanceNoLock
		call	VisSetSize
	;
	; Set the level of tile (0 = on the ground), type, index and
	; position on the game grid.
	;
		push	bp
		sub	sp, size BoardConfigBlock	; allocate space
							; for argument
		mov	dx, size BoardConfigBlock

	; ss:[sp] (BlockConfigBlock) <- ss:[infoBlock] (BlockConfigBlock)
	; except that left, right and top tiles are not assigned,
	; because a TaipeiTile does not need those info.
		mov	di, sp
		mov	ax, ss:[infoBlock].BCT_type
		mov	ss:[di].BCT_type, ax
		mov	ax, ss:[infoBlock].BCT_index
		mov	ss:[di].BCT_index, ax
		mov	ax, ss:[infoBlock].BCT_top1
		mov	ss:[di].BCT_top1, ax
		mov	ax, ss:[infoBlock].BCT_top2
		mov	ss:[di].BCT_top2, ax
		mov	ax, ss:[infoBlock].BCT_level
		mov	ss:[di].BCT_level, ax
		mov	ax, ss:[infoBlock].BCT_position.P_x
		mov	ss:[di].BCT_position.P_x, ax
		mov	ax, ss:[infoBlock].BCT_position.P_y
		mov	ss:[di].BCT_position.P_y, ax
		
		mov	ax, MSG_TAIPEI_TILE_SET_INFO
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		mov	bp, sp
		call	ObjMessage
		add	sp, size BoardConfigBlock
		pop	bp
	;
	; Add the object as a child of the content.
	;
		mov	cx, ds:[LMBH_handle]	
		mov	dx, si			; ^lcx:dx <- object to add
		mov	si, offset TaipeiViewContent
						; *ds:si <- object to add to

		call	TaipeiContentAddAsChild	; ax, cx, dx, si destroyed
		
		.leave
		ret
TaipeiContentMakeOneTile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentAddAsChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a tile as a child of TaipeiViewContent
		The Content and the tile has to be in same block

CALLED BY:	INTERNAL
PASS:		*ds:si		= instance
		^lcx:dx		= object to be added

RETURN:		nothing
DESTROYED:	ax, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Call MSG_VIS_ADD_CHILD to add the object
		Send MSG_VIS_MARK_INVALID to the new object so that it will
		get updated correctly
		Invalidate the area covered by the new object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentAddAsChild	proc	near
		class	TaipeiContentClass
		uses	bp
		.enter
EC <		Assert	objectOD, cxdx, TaipeiTileClass, ds		>
EC <		Assert	objectPtr, dssi, TaipeiContentClass		>
		
		mov	bp, mask CCF_MARK_DIRTY or CCO_FIRST 
						; This puts the object
						; on bottom
		mov	ax, MSG_VIS_ADD_CHILD
		call	ObjCallInstanceNoLock	; Add the child
						; Nukes ax, bp
	;
	; The documentation for add-child says we *must* send a 
	; MSG_VIS_MARK_INVALID to the object so that it will get updated
	; correctly.
	;
		mov_tr	si, dx			; si <- object to invalidate
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_WINDOW_INVALID
		mov	dl, VUM_NOW		; VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
	;
	; Invalidate the area covered by the object so that it will redraw
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock	; Force it to redraw
		
		.leave
		ret
TaipeiContentAddAsChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentGetCorner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the left corner of a tile

CALLED BY:	TaipeiContentMakeOneTile
PASS:		bx <- BCT_level
		cx <- BCT_position.P_x
		dx <- BCT_position.P_y
RETURN:		cx (to be) VI_bounds.left 
		dx (to be) VI_bounds.top
		bx _has_ to stay the same
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentGetCorner	proc	near
	class	TaipeiContentClass

		uses	bx
		.enter

	; Here I assume that one register is big enough to hold any
	; position. In any multiplication, dx in result dx:ax is ignored.
	; cx <- X_OFFSET + P_X * TILE_WIDTH / 2

		push	dx
		mov_tr	ax, cx
		CheckHack <TILE_WIDTH lt 255>
		mov	dl, TILE_WIDTH	
		mul	dl				; dx zapped
		shr	ax				; ax <- P_X*HT/2

EC <		Assert	etype, bx, TaipeiLevelType			>
		shl	bx				; word offset
		add	ax, cs:[xOffsetTable][bx]
		mov_tr	cx, ax

	; dx <- Y_OFFSET + P_Y * TILE_HEIGHT / 2

		pop	ax				; ax <- P_Y
		CheckHack <TILE_HEIGHT lt 255>
		mov	dl, TILE_HEIGHT
		mul	dl
		shr	ax
		add	ax, cs:yOffsetTable[bx]
		mov_tr	dx, ax				; ax trashed
		.leave
		ret

xOffsetTable word	\
	LEVEL_0_X_OFFSET,
	LEVEL_1_X_OFFSET,
	LEVEL_2_X_OFFSET,
	LEVEL_3_X_OFFSET,
	LEVEL_4_X_OFFSET,
	LEVEL_5_X_OFFSET,
	LEVEL_6_X_OFFSET

yOffsetTable word	\
	LEVEL_0_Y_OFFSET,
	LEVEL_1_Y_OFFSET,
	LEVEL_2_Y_OFFSET,
	LEVEL_3_Y_OFFSET,
	LEVEL_4_Y_OFFSET,
	LEVEL_5_Y_OFFSET,
	LEVEL_6_Y_OFFSET

TaipeiContentGetCorner	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an start-select.

CALLED BY:	via MSG_META_START_SELECT
PASS:		*ds:si	= Instance
		ds:di	= Instance
		es	= dgroup (segment containing class)
		cx	= X position of event
		dx	= Y position of event
RETURN:		carry   - set if child was under point, clear if not
                ax      - MRF_PROCESSED

                cx, dx, bp - return values, if child called
                ds      - updated segment
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		The method calls TaipeiCallLastChildUnderPointCallBack.
		If there is a child under the event position, its
		offset will be in ax. (otherwise it will remain 0)
		So call that particular child if ax != 0.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/31/95		Modified from dlitwin's TableStartMouseEvent

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentStartSelect	method	TaipeiContentClass,
						MSG_META_START_SELECT
		clr	bx                      ; zero means start at nth
						; child 
		push	ax, bx, bx		; third push: start at first
						; child
		mov     bx, offset VI_link
		push    bx
		mov     bx, offset TaipeiCallLastChildUnderPointCallBack
		push    cs
		push    bx
		mov     bx, offset Vis_offset
		mov     di, offset VCI_comp
	;
	; preserve the MSG, and clear ax
	;
		clr	ax
		call    ObjCompProcessChildren
	;
	; if ax still == 0, no child hits
	;
		tst	ax
		jz	noHit

	;
	; at least one hit, and the last one is at ds:ax
	;
		mov	bx, ds:[LMBH_handle]
		mov_tr	si, ax
		pop	ax			; the MSG
		mov	di, mask MF_CALL or mask MF_FIXUP_DS

EC <		Assert	handle, bx					>

		call	ObjMessage
		mov	ax, mask MRF_PROCESSED
		jmp	exit
		
	; return flags clear if no children hit
noHit:		pop	ax
		cmp     ax, MSG_META_PTR
		mov     ax, mask MRF_CLEAR_POINTER_IMAGE
		je	exit                    ;Carry is clear if ax =
						;MSG_META_PTR... 

		clr     ax                      ;"clr" clears the carry 
exit:
		.leave
		ret

TaipeiContentStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                TaipeiCallLastChildUnderPointCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Checks to see if child is under current point. Return
		its handle to ax if applicable. Continue to all child.
		The last updated ax will be the right last child under
		point.

CALLED BY:      FAR

PASS:           *ds:si -- child handle
                *es:di -- composite handle
                cx, dx  - location in document coordinates
                bp - data to pass on

RETURN:         carry always cleared (st. all siblings are checked)
                ax <- offset of child if the child hits

DESTROYED:      bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

		This method is executed on every vis children in the
		content. First the content sees if the child is enable
		blah blah blah, and if it finds that particular child
		suitable, it returns ax == offset of child, RATHER THAN
		sending the MSG to the child and end the search. As
		a result, all children are searched, and ax will contain
		the offset of the last suitable child
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/31/95		Modified from dlitwin's
				TableCallChildUnderPointCallBack 

------------------------------ ----------------------------------------------@

TaipeiCallLastChildUnderPointCallBack	proc	far		
		class   VisClass

	;
	; some doubt about the usefulness of the following codes..
	; and the jpo..
	;
		mov     bx,ds:[si]
		add     bx,ds:[bx].Vis_offset
		test    ds:[bx].VI_typeFlags, mask VTF_IS_WINDOW
		jnz     noMatch
		mov     bl, ds:[bx].VI_attrs

	;       Make sure item is enabled, detectable, etc.

		test    bl, mask VA_FULLY_ENABLED
		jz      noMatch
		test    bl, mask VA_DETECTABLE or mask VA_REALIZED
		jz      noMatch
		jpo     noMatch

		call    VisTestPointInBounds
		jnc     noMatch
		or	bp,(mask UIFA_IN) shl 8

	; Test to see if child's bounds hit
	; Use ES version since *es:di is
	;       composite object

	;
	; Originally, if the child hits, sent to the child and skip the rest
	; of children. Now, just remember the offset of the "hit" child, and
	; continue. So at the end, the last "hitting" child will be stored.
	;
	;	push	ax
	;	call    ObjCallInstanceNoLock   ; if hit, send to this child
	;	pop	ax
		
		mov_tr	ax, si

noMatch:
		clc			; always clear c so that all children
					; get processed.
		ret

TaipeiCallLastChildUnderPointCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentIsTileIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query if a tile is still in the content.

CALLED BY:	MSG_TAIPEI_CONTENT_IS_TILE_IN
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
		cx	= index of tile being queried
RETURN:		ax	= TRUE if in, FALSE if not
DESTROYED:	bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentIsTileIn	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_IS_TILE_IN
		call	TaipeiContentIsTileInHelper	; carry set if in.
							; bx, cx gone
		mov	ax, TRUE
		jc	quit
		mov	ax, FALSE
quit:
		ret
TaipeiContentIsTileIn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentIsTileInHelper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query if a particular tile (in cx) is still in the
		VisContent.

CALLED BY:	INTERNAL
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		cx	= index of tile being queried
RETURN:		carry set if child is in, otherwise carry cleared.
DESTROYED:	bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		See if the info about NO_TILE is queried. If so,
		return 0.  Otherwise check TCI_stillIn array.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentIsTileInHelper	proc near
		class TaipeiContentClass

EC <		Assert	srange	cx, 0, NO_TILE				>
		cmp	cx, NO_TILE
		clc
		je	noTile

		mov_tr	bx, cx
		tst	ds:[di].TCI_stillIn[bx]
		jz	noTile
		stc
noTile:
		ret
		
TaipeiContentIsTileInHelper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentIsChildFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query if a particular child (in cx) is free in the
		VisContent.

CALLED BY:	MSG_TAIPEI_CONTENT_IS_CHILD_FREE
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
		cx	= index of tile queried
RETURN:		ax	= 1 if child is in, 0 otherwise
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Lock down the BoardConfigBlock for left, right and top
		tiles info.
		Check Left: if Left is not free, check right.
		If left and right are not free, this tile is not free.
		Otherwise, Check top if it is cleared.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentIsTileFree	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_IS_TILE_FREE
EC <		Assert	srange	cx, 0, NO_TILE				>

		infoBlock2	local	BoardConfigBlock
		.enter
	;
	; tile info is stored in BoardInfo chunk array
	;
		push	ds:[LMBH_handle]
		GetResourceHandleNS DataResource, bx	; bx <- handle of
							; DataResource 
		call	MemLock				; ax <- segment of
							; lmem block
		mov_tr	ds, ax				; ds <- segment lmem
		mov	si, offset BoardInfo		; *ds:si <- chunk
							; array 

		mov_tr	ax, cx				; ax <- index
		mov	cx, ss
		lea	dx, ss:[infoBlock2]
		call	ChunkArrayGetElement		; cx:dx <- element
							; caray set
							; if out of bound
		call	MemUnlock
		pop	bx				; bx <- block handle
		call	MemDerefDS			; ds <- segment
	;
	; now infoBlock has the left/right tiles info
	;
		clr	ax
		mov	cx, ss:[infoBlock2].BCT_left1
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	checkRight

		mov	cx, ss:[infoBlock2].BCT_left2
		call	TaipeiContentIsTileInHelper	; carry set if in
		jnc	leftCleared
checkRight:
		mov	cx, ss:[infoBlock2].BCT_right1
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	notFree

		mov	cx, ss:[infoBlock2].BCT_right2
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	notFree

		jmp	leftCleared
notFree:
		.leave
		ret

leftCleared:
	;
	; check upper levels
	;
		mov	cx, ss:[infoBlock2].BCT_top1
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	notFree

		mov	cx, ss:[infoBlock2].BCT_top2
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	notFree

		mov	cx, ss:[infoBlock2].BCT_top3
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	notFree

		mov	cx, ss:[infoBlock2].BCT_top4
		call	TaipeiContentIsTileInHelper	; carry set if in
		jc	notFree
		mov	ax, 1
		jmp	notFree				; actually, quit

TaipeiContentIsTileFree	endm

COMMENT @-----------------------------------------------------
	;
	; check if the tiles to the left are present
	;
		mov	cx, ds:[di].TTI_tileLeft1
		mov	ax, MSG_TAIPEI_CONTENT_IS_CHILD_IN
		call	VisCallParent		; ax = 1 if child is in
						; 0 otherwise,
						; bx, cx destroyed
		tst	ax
		jnz	checkRight
	;
	; check second left
	;
		mov	cx, ds:[di].TTI_tileLeft2
		mov	ax, MSG_TAIPEI_CONTENT_IS_CHILD_IN
		call	VisCallParent		; ax = 1 if child is in
						; 0 otherwise,
						; bx, cx destroyed
		tst	ax
		jz	leftCleared
	;
	; check if the tile to the right is present
	;		
checkRight:	mov	cx, ds:[di].TTI_tileRight1
		mov	ax, MSG_TAIPEI_CONTENT_IS_CHILD_IN
		call	VisCallParent		; ax = 1 if child is in
						; 0 otherwise,
						; bx, cx destroyed 
		tst	ax
		jnz	notFree
	;
	; test second right
	;
		mov	cx, ds:[di].TTI_tileRight2
		mov	ax, MSG_TAIPEI_CONTENT_IS_CHILD_IN
		call	VisCallParent		; ax = 1 if child is in
						; 0 otherwise,
						; bx, cx destroyed 
		tst	ax
		jnz	notFree
leftCleared:
	;
	; At this point, it has no left neighbor OR right neighbor
	; Check if any other tile is above me
	;
@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentTileGone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that the passed tile is no longer in content

CALLED BY:	MSG_TAIPEI_CONTENT_TILE_GONE
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
		cx	= index of tile
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	block may move

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentTileGone	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_TILE_GONE
	;
	; Mark that there is the tile is gone
	;
		mov_tr	bx, cx
		mov	ds:[di].TCI_stillIn[bx], 0
	;
	; Mark that there is one less tile
	;
		dec	ds:[di].TCI_tilesLeft
	;
	; See if the game is cleared
	;
		tst	ds:[di].TCI_tilesLeft
		jnz	NotCleared

		mov	ax, MSG_TAIPEI_CONTENT_GAME_CLEARED
		call	ObjCallInstanceNoLock		; ax, bx, dx, di, si
							; destroyed
		
NotCleared:
	;
	; Notify the GenValue counter to decrement
	;
	; TaipeiTilesCount sits in Interface
	;
		GetResourceHandleNS Interface, bx    
		mov     si, offset TaipeiTilesCount	; ^lbx:si <- object
		mov	ax, MSG_GEN_VALUE_DECREMENT
		mov     di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp
							; <- return values
							; Block moves

		ret
TaipeiContentTileGone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentTileComeBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that the passed tile is coming back to the content (in
		fact, unhide within the content)

CALLED BY:	MSG_TAIPEI_CONTENT_TILE_GONE
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
		cx	= index of tile
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	block may move

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentTileComeBack	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_TILE_COME_BACK
	;
	; Mark that there is the tile is coming back
	;
		mov_tr	bx, cx
		mov	ds:[di].TCI_stillIn[bx], 1
	;
	; Mark that there is one more tile
	;
		inc	ds:[di].TCI_tilesLeft
	;
	; Notify the GenValue counter to increment
	;
	; TaipeiTilesCount sits in Interface

		GetResourceHandleNS Interface, bx    
		mov     si, offset TaipeiTilesCount	; ^lbx:si <- object
		mov	ax, MSG_GEN_VALUE_INCREMENT
		mov     di, mask MF_CALL
		call	ObjMessage			; ax, cx, dx, bp
							; <- return values
							; Block moves
		ret
TaipeiContentTileComeBack	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentOneTileSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	One tile in the content is being selected.

		If there is no other tile selected, remember the
		tile info.

		If there is one other tile selected {
			if (both are same tile) unselect
			if (they match) remove them from the content.
			if (don't match) old one is unselected
			(redraw!) new one is selected.
		}

CALLED BY:	MSG_TAIPEI_CONTENT_ONE_TILE_SELECTED
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #

		Info about the selected block:
		cx	= Chunk Handle of tile
		dx	= TTI_type
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentOneTileSelected	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_ONE_TILE_SELECTED
	;
	; Check if this is the first selected tile
	;
		cmp	ds:[di].TCI_selectedTileHandle, 0
		je	firstSelect

	;
	; Check if same tile is selected twice
	;
		cmp	ds:[di].TCI_selectedTileHandle, cx
		je	sameSelected

	;
	; Check if they are same (or compatible: flowers are
	; compatible with each other, so are seasons)
	;
		call	TaipeiContentTileEqual
		cmp	ax, 1
		je	removeTiles

	;
	; If not equal, then two different types of tile are selected,
	; and we discard the first info
	;
	; Still have to notify the first tile it is being unselected.
	;
		mov	bx, ds:[LMBH_handle]		; bx <- block
							; handle
		mov	si, ds:[di].TCI_selectedTileHandle
		mov	ds:[di].TCI_selectedTileHandle, cx
		mov	ds:[di].TCI_selectedTileType, dx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_TAIPEI_TILE_UNSELECTED
		call	ObjMessage			; ax, cx, dx, di
							; destroyed 
		jmp	quit
		
sameSelected:
	;
	; clear info
	;
		mov	ds:[di].TCI_selectedTileHandle, 0
		jmp	quit
firstSelect:
	;
	; remember info
	;
		mov	ds:[di].TCI_selectedTileHandle, cx
		mov	ds:[di].TCI_selectedTileType, dx
		jmp	quit

removeTiles:
	;
	; store info for undo
	;
		mov	ds:[di].TCI_lastRemovedTile1Handle, cx
		push	ds:[di].TCI_tilesLeft		; for checking if
							; game is cleared at
							; the end
		push	cx
	;
	; tiles and content live in same lmem
	;
		mov	bx, ds:[LMBH_handle]		; bx <- block
							; handle
EC <		Assert	handle, bx					>

		mov	si, ds:[di].TCI_selectedTileHandle
	;
	; store info for undo
	;
		mov	ds:[di].TCI_lastRemovedTile2Handle, si
	;
	; clear previous selected info so that no tiles are selected
	; now
	;
		mov	ds:[di].TCI_selectedTileHandle, 0
	;
	; remove the tile
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_TAIPEI_TILE_HIDE
		call	ObjMessage			; ax, cx, dx, di
							; destroyed 

		pop	si				; handle of
							; newly selected
	;
	; remove another tile
	;
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_TAIPEI_TILE_HIDE
		call	ObjMessage			; ax, cx, dx, di
							; destroyed 
	;
	; enable undo if there are still tiles left
	;
		pop	ax				; # of tiles before
							; removing any (2)
		cmp	ax, 2
		jz	quit
		
		GetResourceHandleNS	UndoMoveTrigger, bx
		mov     si, offset UndoMoveTrigger
		mov     ax, MSG_GEN_SET_ENABLED
		mov     dl, VUM_NOW
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage			; nothing destroyed
		
quit:		
		ret
		
TaipeiContentOneTileSelected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentTileEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two tiles and see if they are the same, or
		compatible

CALLED BY:	
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		dx	= type of the other tile
RETURN:		ax 	= 1 if same, 0 otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		check if user is cheat. If so, let go.

		The tiles type are enum, arranged in this order:

		TTT_BAMBOO_?, TTT_CRAK_?, TTT_DOT_?,
		TTT_DRAGON_?, TTT_WIND_?,

		TTT_SEASON_SP, SU, AU, WI
		TTT_FLOWER_PLUM, BAMBOO, ORCHID, MUM

		Two different seasons are considered same, and two
		different flowers are considered same.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentTileEqual	proc	near
		class TaipeiContentClass
		clr	ax
	;
	; Two different tiles are selected.
	; See if user is cheating right now. If so, let him cheat
	;
		test	ds:[di].TCI_miscFlags, mask TCF_CHEATING
		jnz	doneCheating
	;
	; Check if face values are same
	;
		cmp	ds:[di].TCI_selectedTileType, dx
		je	same
	;
	; see if both are flowers
	;
		cmp	ds:[di].TCI_selectedTileType, TTT_FLOWER_PLUM
		jl	notFlower

		cmp	dx, TTT_FLOWER_PLUM
		jl	quit			; one is flower, one
						; is not		
		jmp	same
notFlower:
		cmp	ds:[di].TCI_selectedTileType, TTT_SEASON_SP
		jl	quit			; not flower nor season

	;
	; At this point: selectedTileType is SEASON
	; but 		 dx		  can be anything
	;
		cmp	dx, TTT_SEASON_SP
		jl	quit			; first is season,
						; second is not season
						; nor or flower
		cmp	dx, TTT_FLOWER_PLUM
		jge	quit			; first is season, second
						; is flower
doneCheating:
		BitClr	ds:[di].TCI_miscFlags, TCF_CHEATING
same:
		mov	ax, 1
quit:		
		ret
TaipeiContentTileEqual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentCheatNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that user is going to cheat

CALLED BY:	MSG_TAIPEI_CONTENT_CHEAT_NOW
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentCheatNow	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_CHEAT_NOW
		ornf	ds:[di].TCI_miscFlags, mask TCF_CHEATING or \
			 mask TCF_CHEATED
		ret
TaipeiContentCheatNow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentNoCheat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User clicks on cheat. Notify him no cheat available (which is
		of course, not true.) by displaying a dialog box, if he has
		never tried to cheat before.

CALLED BY:	MSG_TAIPEI_CONTENT_NO_CHEAT
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentNoCheat	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_NO_CHEAT
	;
	; to eliminate excessive "No cheating" dialog box, test if he tried
	; to cheat before.
	;
		test	ds:[di].TCI_miscFlags, mask TCF_TRIED_TO_CHEAT
		jnz	quit
	;
	; mark that user tried to cheat, and show the dialog box
	;
		BitSet	ds:[di].TCI_miscFlags, TCF_TRIED_TO_CHEAT
		GetResourceHandleNS	TaipeiNoCheatBox, bx
		mov     si, offset TaipeiNoCheatBox
		mov     ax, MSG_GEN_INTERACTION_INITIATE
		mov     dl, VUM_NOW
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage			; nothing destroyed
	
quit:		ret

TaipeiContentNoCheat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the last 2 removed (in fact, hidden) tiles back to where
		they were. 

CALLED BY:	MSG_TAIPEI_CONTENT_UNDO
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, dx, bp, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		The handle of last 2 removed tiles are in
		ds:[di].TCI_lastRemovedTile1Handle
		ds:[di].TCI_lastRemovedTile2Handle

		Just send them a message MSG_TAIPEI_TILE_UNHIDE
		And disable the Undo trigger.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentUndo	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_UNDO


	;
	; tiles and content live in same lmem
	;
		mov	bx, ds:[LMBH_handle]		; bx <- block
							; handle
EC <		Assert	handle, bx					>

	;
	; Unselect any tile that might be selected right now.
	;
		push	si
		mov	si, ds:[di].TCI_selectedTileHandle
		tst	si
		jz	removeTiles

		clr	ds:[di].TCI_selectedTileHandle
		mov	ax, MSG_TAIPEI_TILE_UNSELECTED
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	bp
		call	ObjMessage			; all destroyed
							; except bx
removeTiles:
		
EC <		Assert	handle, bx					>
	;
	; redereference
	;
		pop	di
		mov	di, ds:[di]
		add	di, ds:[di].Vis_offset
		mov	si, ds:[di].TCI_lastRemovedTile1Handle
							; ^lbx:si <- object
							; to be added
		mov	dx, ds:[di].TCI_lastRemovedTile2Handle
		push	dx
		
		mov	ax, MSG_TAIPEI_TILE_UNHIDE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	bp
		call	ObjMessage			; all destroyed
							; except bx
	;
	; Unhide the second child
	;
EC <		Assert	handle, bx					>

		pop	si				; si <- handle of 2nd
							; tile
		mov	ax, MSG_TAIPEI_TILE_UNHIDE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; all destroyed
							; except bx
	;
	; disable undo
	;
		call	TaipeiContentDisableUndo	; ax, bx, si, dl, di
							; destroyed.
		
		ret
TaipeiContentUndo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentDisableUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable Undo Trigger in the UI.

CALLED BY:	Internal
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	ax, bx, si, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentDisableUndo	proc	near
		GetResourceHandleNS	UndoMoveTrigger, bx
		mov     si, offset UndoMoveTrigger
		mov     ax, MSG_GEN_SET_NOT_ENABLED
		mov     dl, VUM_NOW
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage			; nothing destroyed
		ret
TaipeiContentDisableUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentStartTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the timer to give a mesg every second

CALLED BY:	MSG_TAIPEI_CONTENT_START_TIMER
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 9/95   	Initial version (mostly copied from
				solitaireGame.asm) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentStartTimer	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_START_TIMER

	;
	; If there's already a timer, don't start another
	;
		tst	ds:[di].TCI_timerHandle
		jnz	done


		mov	bx, ds:[LMBH_handle]
		mov	al, TIMER_EVENT_CONTINUAL	; Timer Type
		mov	dx, MSG_TAIPEI_CONTENT_ONE_SECOND_ELAPSED
							; what method to send?
		mov	di, ONE_SECOND			; how often?
		mov	cx, di	                        ; same till first
		call	TimerStart			; ax - timer ID
							; (needed for
							; TimerStop) 
							; bx - timer handle

EC <		Assert	objectPtr, dssi, TaipeiContentClass		>

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ds:[di].TCI_timerHandle, bx
done:
		ret
TaipeiContentStartTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentStopTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the timer

CALLED BY:	MSG_TAIPEI_CONTENT_STOP_TIMER
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/ 9/95   	Initial version (mostly copied from
				solitaireGame.asm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentStopTimer	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_STOP_TIMER
	;
	; If there's no timer, don't try to stop it
	;
		clr	ax
		mov	bx, ds:[di].TCI_timerHandle
		tst	bx
		jz	done

		call	TimerStop			; ax, bx destroyed
		clr	ds:[di].TCI_timerHandle
done:
		ret
TaipeiContentStopTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentOneSecondElapsed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The message is generated by a timer every one second. We
		should increment seconds counter and update the time display
		on the screen. Revert hilighted tiles if user asked
		for hints before and it's time to take the hints back.

CALLED BY:	MSG_TAIPEI_CONTENT_ONE_SECOND_ELAPSED
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/10/95   	Initial version (mostly copied from
				solitaireGame.asm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentOneSecondElapsed	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_ONE_SECOND_ELAPSED
if _GIVE_HINT
	;
	; if user asks for hints, free and matching tiles will be hilighted,
	; and TCI_hintTimeElapsed assigned "1".
	; Now the timer has to check if time has come to un-hilight the
	; tiles.
	;
		tst	ds:[di].TCI_hintTimeElapsed
		jz	noNeedRevert
		inc	ds:[di].TCI_hintTimeElapsed
		cmp	ds:[di].TCI_hintTimeElapsed, HINT_TIME_BETWEEN_FLASH+1
		jl	noNeedRevert
		push	di
		clr	ds:[di].TCI_hintTimeElapsed
		mov	ax, MSG_TAIPEI_TILE_HINT_FLASH
		call	VisSendToChildren
		pop	di
	;
	;  Accept input.
	;
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		call	TaipeiIgnoreInput
noNeedRevert:
endif
		inc	ds:[di].TCI_time
		mov	cx, ds:[di].TCI_time
		mov	di, handle TimeValue
		mov	si, offset TimeValue
		segmov	es, ss
		call	TimeToTextObject		; write the time
							; ax, bx, cx, dx, 
							; bp destroyed
		ret
TaipeiContentOneSecondElapsed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentGameCleared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User cleared the game! Take out appropriate dialog box

CALLED BY:	MSG_TAIPEI_CONTENT_GAME_CLEARED
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, bx, dx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Turn off timer, show the appropriate dialog box, and disable
		undo trigger. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	2/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentGameCleared	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_GAME_CLEARED
		mov	ax, MSG_TAIPEI_CONTENT_STOP_TIMER
		call	ObjCallInstanceNoLock

		test	ds:[di].TCI_miscFlags, mask TCF_CHEATED
		jnz	cheater

		mov     si, offset WinGameNoCheatBox
		jmp	showBox
cheater:
		mov     si, offset WinGameWithCheatBox

showBox:	mov     ax, MSG_GEN_INTERACTION_INITIATE
	;
	; Both WinGameNoCheatBox and WinGameWithCheatBox lives in same
	; resource.
	;
		GetResourceHandleNS	WinGameNoCheatBox, bx
		mov     dl, VUM_NOW
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage			; nothing destroyed

		call	TaipeiContentDisableUndo
		ret
TaipeiContentGameCleared	endm


if _GIVE_HINT
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give hints to user, ie. flash matching free tiles

CALLED BY:	MSG_TAIPEI_CONTENT_HINT
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	ds:[di].TCI_numFreeTileOfType will be updated.
		ds:[di].TCI_hintTimeElapsed <- 1 if there are free pairs so
		that timer will flash the hilited tiles again in 4 seconds.
		(HINT_TIME_BETWEEN_FLASH)

PSEUDO CODE/STRATEGY:
		Update Free Status
		call "MSG_TAIPEI_TILE_HINT_FLASH" to children

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentHint	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_HINT
	;
	;  Game is already finished.
	;
	tst	ds:[di].TCI_tilesLeft
	jz	quit
	;
	;  Start ignoring input 
	;
		mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
		call	TaipeiIgnoreInput
	;
	;  Figure out free tiles.
	;
		push	di
		BitClr	ds:[di].TCI_miscFlags, TCF_FREE_PAIR_FOUND
		mov	ax, MSG_TAIPEI_CONTENT_UPDATE_FREE_STATUS
		call	ObjCallInstanceNoLock
	;
	; TCI_numFreeTileOfType is updated
	;
		mov	ax, MSG_TAIPEI_TILE_HINT_FLASH
		call	VisSendToChildren
	;
	; TCI_miscFlags mask TCI_FREE_PAIR_FOUND is non zero if at least one
	; free pair is found.
	; if no legal move found, send dialog box
	;
		pop	di
		mov	ds:[di].TCI_hintTimeElapsed, 1
		test	ds:[di].TCI_miscFlags, mask TCF_FREE_PAIR_FOUND
		jnz	quit
	;
	; so no free matching pairs. Don't have to keep track time and
	; revert tiles anymore. Accept input again first, turn off timer.
	;
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		call	TaipeiIgnoreInput
		
		clr	ds:[di].TCI_hintTimeElapsed

		mov	ax, MSG_TAIPEI_CONTENT_STOP_TIMER
		call	ObjCallInstanceNoLock
		
		GetResourceHandleNS	NoLegalMoveBox, bx
		mov     si, offset NoLegalMoveBox
		mov     ax, MSG_GEN_INTERACTION_INITIATE
		mov     dl, VUM_NOW
		mov     di, mask MF_FIXUP_DS
		call    ObjMessage			; nothing destroyed
		
quit:		ret
TaipeiContentHint	endm

endif	; _GIVE_HINT


if _GIVE_HINT
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentUpdateFreeStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update instance data TCI_numFreeTilesOfType
		Could be called because of: new game, two tiles taken
		away, etc.

CALLED BY:	MSG_TAIPEI_CONTENT_UPDATE_FREE_STATUS
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentUpdateFreeStatus	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_UPDATE_FREE_STATUS
	;
	; clear the instance data
	;
		mov	cx, NUM_OF_DIFF_TILE_TYPES
		dec	cx
clearOne:	mov	bx, cx
		shl	bx
		clr	ds:[di].TCI_numFreeTileOfType[bx]
		loop	clearOne
		clr	ds:[di].TCI_numFreeTileOfType[0]
		
	;
	; call all children to update free status
	;
		mov	ax, MSG_TAIPEI_TILE_CHECK_STATUS
		call	VisSendToChildren
		
		ret
TaipeiContentUpdateFreeStatus	endm

endif 	; _GIVE_HINT


if _GIVE_HINT
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentTypeFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that there is a free tile of type (passed cx)

CALLED BY:	MSG_TAIPEI_CONTENT_TYPE_FREE
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
		cx	= type of free tiles
RETURN:		Nothing
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentTypeFree	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_TYPE_FREE
EC <		Assert	etype, cx, TaipeiTileType			>
		mov_tr	bx, cx
		shl	bx				; word offset
		inc	ds:[di].TCI_numFreeTileOfType[bx]
		ret
TaipeiContentTypeFree	endm

endif		; _GIVE_HINT


if _GIVE_HINT
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentNumFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of free tiles that have the passed
		type (or compatible type)

CALLED BY:	MSG_TAIPEI_CONTENT_NUM_OF_FREE_WITH_TYPE
PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
		cx	= TileType
RETURN:		cx	= Num of tiles that are free and compatible
DESTROYED:	Everything
SIDE EFFECTS:	
		TCI_miscFlags mask TCF_FREE_PAIR_FOUND updated if two or more
		free and compatible tiles are found.

PSEUDO CODE/STRATEGY:

		The tiles type are enum, arranged in this order:

		TTT_BAMBOO_?, TTT_CRAK_?, TTT_DOT_?,
		TTT_DRAGON_?, TTT_WIND_?,

		TTT_SEASON_SP, SU, AU, WI
		TTT_FLOWER_PLUM, BAMBOO, ORCHID, MUM

		Two different seasons are considered same, and two
		different flowers are considered same.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentNumFree	method dynamic TaipeiContentClass, 
				MSG_TAIPEI_CONTENT_NUM_OF_FREE_WITH_TYPE
EC <		Assert	etype, cx, TaipeiTileType			>
		cmp	cx, TTT_SEASON_SP
		jge	complicated
		mov_tr	bx, cx
		shl	bx
		mov	cx, ds:[di].TCI_numFreeTileOfType[bx]

quit:		cmp	cx, 2
		jl	quit2
		BitSet	ds:[di].TCI_miscFlags, TCF_FREE_PAIR_FOUND
quit2:		ret
complicated:
		cmp	cx, TTT_FLOWER_PLUM
		jge	flowers
		mov	cx, ds:[di].TCI_numFreeTileOfType[TTT_SEASON_SP*2]
		add	cx, ds:[di].TCI_numFreeTileOfType[TTT_SEASON_SU*2]
		add	cx, ds:[di].TCI_numFreeTileOfType[TTT_SEASON_AU*2]
		add	cx, ds:[di].TCI_numFreeTileOfType[TTT_SEASON_WI*2]
		jmp	quit
flowers:		
		mov	cx, ds:[di].TCI_numFreeTileOfType[TTT_FLOWER_PLUM*2]
		add	cx, ds:[di].TCI_numFreeTileOfType[TTT_FLOWER_BAMBOO*2]
		add	cx, ds:[di].TCI_numFreeTileOfType[TTT_FLOWER_ORCHID*2]
		add	cx, ds:[di].TCI_numFreeTileOfType[TTT_FLOWER_MUM*2]
		jmp	quit
		
TaipeiContentNumFree	endm

endif	; _GIVE_HINT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiIgnoreInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore or accept input

CALLED BY:	UTILITY

PASS:		ax = MSG_GEN_APPLICATION_IGNORE_INPUT or
		     MSG_GEN_APPLICATION_ACCEPT_INPUT

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiIgnoreInput	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter

		mov	bx, handle TaipeiApp
		mov	si, offset TaipeiApp
		Assert	optr bxsi
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
TaipeiIgnoreInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaipeiContentNewRestartGame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A game is being played. User requests new game or
		restart game. Discard and reinitialize, with new
		random tiles if appropriate.

CALLED BY:	MSG_TAIPEI_CONTENT_ANOTHER_GAME,
		MSG_TAIPEI_CONTENT_RESTART_GAME

PASS:		*ds:si	= TaipeiContentClass object
		ds:di	= TaipeiContentClass instance data
		es 	= segment of TaipeiContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	4/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaipeiContentNewRestartGame	method dynamic TaipeiContentClass, 
					MSG_TAIPEI_CONTENT_ANOTHER_GAME,
					MSG_TAIPEI_CONTENT_RESTART_GAME
		cmp	ax, MSG_TAIPEI_CONTENT_ANOTHER_GAME
		mov	ax, MSG_TAIPEI_TILE_RESTART_GAME
		jne	restart
	;
	; Randomize Index array first: this takes a long time and we
	; don't want the tiles to disappear for too long
	;
		call	TaipeiRandomizeIndexArray	; nothing destroyed
	;
	; Call all tiles to grab their new "type" (Bamboo, etc) and
	; initialize.
	;
		mov	ax, MSG_TAIPEI_TILE_ANOTHER_GAME
restart:
		call	VisSendToChildren
	;
	; Initialize the content
	;
		mov	ax, MSG_TAIPEI_CONTENT_INITIALIZE
		call	ObjCallInstanceNoLock
	;
	; Redraw
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		
		ret
TaipeiContentNewRestartGame	endm


CommonCode	ends


