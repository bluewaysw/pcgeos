COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		EC Module
FILE:		cwordEC.asm

AUTHOR:		Peter Trinh, May  6, 1994

ROUTINES:
	Name			Description
	----			-----------
	ECVerifyTextQueueBlock	Verifies a TextQueueBlock
	ECTextQueueEnumCallback	To check ea. element of TextQueue
	ECVerifyTextInfo	Verifies a given TextInfo
	ECVerifyObjectBoard	Verifies a Board object
	ECVerifyObjectClueList	Verifies a ClueList object
	ECVerifyBufferSize	Verifies the buffer is of given size
	ECVerifyValidPosInList	Verifies position is in list.
	ECVerifyClueListInitParams

	ECVerifyCellTokenType	Verifies is a 	CellTokenType
	ECVerifyClueTokenType	    "	  " "	ClueTokenType
	ECVerifyDirectionType	    "	  " "	DirectionType
	ECVerifyEngineTokenType	    "	  " "	EngineTokenType
	ECVerifySystemType	    "	  " "	SystemType
	ECVerifyVerifyModeType	    "	  " "	VerifyModeType
*	ECVerifyInitReturnValue	    "	  " "	InitReturnValue
	ECVerifyDrawOptions	    "	  " "	DrawOptions
	ECVerifyHighlightStatus	    "	  " "	HighlightStatus
	ECVerifyListItemInfo	    "	  " "	ListItemInfo
	ECVerifyCellFlags	    "	  " "	CellFlags
	ECVerifyClueListSplitStatus "	  " "	ClueListSplitStatus

	ECVerifyAGC		Verify if is valid AGC
	ECVerifyInBoard		Verify within bound of the board
	ECVerifyInDoc		    "     "     "    "  "  doc
	ECVerifyInGrid		    "     "     "    "  "  grid

	ECVerifyUserLetter	Verify in the engine module if the
				user letter is between A-Z.
	ECCheckIfCwordChar	Checks if the character is a Cword char.

	--------	EC data segment routines	----------------
	ECSetClueCountsInDgroup Sets ECnumAcrossClues and ECnumDownClues
	ECSetClueListLength	Sets ECacrossListLen and ECdownListLen


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94   	Initial revision


DESCRIPTION:
	This file contains the routines used in error checking for the
	Crossword project.
		
<<<<<<< 1.1.1.11+mods
	$Id: cwordEC.asm,v 1.1 97/04/04 15:13:56 newdeal Exp $
=======
	$Id: cwordEC.asm,v 1.1 97/04/04 15:13:56 newdeal Exp $
>>>>>>> 1.11

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

CwordECCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyTextQueueBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a block handle, will verify that:
		1) it is a valid handle to an lmem block
		2) the block is a TextQueueBlock

CALLED BY:	global - routines in the Crossword project

PASS:		bx	= block handle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	In order to verify condition 2, we will need to derefence the
	handle and access the data inside the block.
	a) Will verify that TQH_textQueueHandle is a handle to a
	   ChunkArray. 
	b) The contents of the ChunkArray are TextInfo structures
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyTextQueueBlock	proc	far
	uses	ax,cx,di,si,ds
	.enter

	Assert	lmem	bx		; lmem block handle?

	call	MemLock
	mov	ds, ax			; segment of block

	mov	si, ds:[TQBH_textQueueHandle]
	Assert ChunkArray dssi		; geniuine ChunkArray?

	push	bx			; TextQueueBlock
	; verify each element of the Chunkarray are actually TextInfo
	; structures 
	mov	bx, cs
	mov	di, offset ECTextQueueEnumCallback
	call	ChunkArrayEnum

	pop	bx			; TextQueueBlock
	call	MemUnlock

	.leave
	ret
ECVerifyTextQueueBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECTextQueueEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the callback routine that will verify each
		element of the TextQueue.

CALLED BY:	ChunkArrayEnum
PASS:		*ds:si	= TextQueue
		ds:di	= element being enumerated

RETURN:		carry	- always CLEAR

DESTROYED:	bx, si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECTextQueueEnumCallback	proc	far
	.enter

	call	ECVerifyTextInfo

	Destroy	bx,si,di

	clc

	.leave
	ret
ECTextQueueEnumCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyTextInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies a TextInfo structure given its pointer.

CALLED BY:	global - routines of Crossword project

PASS:		ds:di	- ptr to TextInfo structure

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Will check each of its fields and ERROR on improbable values.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyTextInfo	proc	far
	uses	ax, dx
	.enter

	mov	ax, ds:[di].TI_center.P_x
	mov	dx, ds:[di].TI_center.P_y
	Assert	InGrid	axdx

	Assert	CwordChar	ds:[di].TI_character
		
	.leave
	ret
ECVerifyTextInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyObjectBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the lptr to the object, verify that it's a valid
		Board object. 

CALLED BY:	global - routines in the Crossword project

PASS:		*ds:si	= CwordBoardClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Verify that *ds:si is valid objectPtr.
	Verify the instance data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyObjectBoard	proc	far
class	CwordBoardClass
	uses	ax,bx,cx,dx,di,si,bp,es
	.enter

	Assert	objectPtr	dssi, CwordBoardClass

	; Get the instance data
	mov	di, ds:[si]
	add	di, ds:[di].CwordBoard_offset

	tst	ds:[di].CBI_engine		; uninitialized object
	LONG jz	exit

	LoadVarSeg es, ax

	Assert	urange	ds:[di].CBI_cellWidth, 0, BOARD_MAX_CELL_WIDTH
	Assert	urange	ds:[di].CBI_cellHeight, 0, BOARD_MAX_CELL_HEIGHT
	Assert	EngineTokenType	ds:[di].CBI_engine
	Assert	SystemType 	ds:[di].CBI_system

	mov	ax, ds:[di].CBI_upLeftCoord.P_x
	mov	bx, ds:[di].CBI_upLeftCoord.P_y
	Assert	e ax, es:[ECupLeftBoard].P_x
	Assert	e bx, es:[ECupLeftBoard].P_y
	mov	ax, ds:[di].CBI_lowRightCoord.P_x
	mov	bx, ds:[di].CBI_lowRightCoord.P_y
	Assert	e ax, es:[EClowRightBoard].P_x
	Assert	e bx, es:[EClowRightBoard].P_y

	Assert	CellTokenType	ds:[di].CBI_cell
	Assert	DirectionType	ds:[di].CBI_direction
	Assert	ClueTokenType	ds:[di].CBI_acrossClue, ACROSS
	Assert	ClueTokenType	ds:[di].CBI_downClue, DOWN
	Assert	VerifyModeType	ds:[di].CBI_verifyMode
	Assert	DrawOptions	ds:[di].CBI_drawOptions
	Assert	HighlightStatus	ds:[di].CBI_highlightStatus

exit:
	.leave
	ret
ECVerifyObjectBoard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyObjectClueList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an lptr, verify that its is valid, and it is an
		lptr to a valid ClueList object.

CALLED BY:	global - routines in the Crossword project

PASS:		*ds:si	= CwordClueListClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Verify that *ds:si is valid objectPtr.
	Verify the instance data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyObjectClueList	proc	far
class	CwordClueListClass

	uses	di, si, cx
	.enter

	Assert	objectPtr	dssi, CwordClueListClass

	; Get the instance data
	mov	di, ds:[si]
	add	di, ds:[di].CwordClueList_offset

	mov	si, ds:[di].CCLI_map
	tst	si
	jz	finish

	; Verify instance data
	Assert	DirectionType	ds:[di].CCLI_direction
	Assert	ChunkArray	dssi

	; Verify the map
	mov	cx, ds:[di].CCLI_direction
	call	ECVerifyClueListMap
finish:
	.leave
	ret
ECVerifyObjectClueList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyClueListMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that it is a valid map by verifying that each of
		its element is of ClueTokenType.

CALLED BY:	global - routines in the Crossword project

PASS:		*ds:si	- ChunkArray (ClueList map)
		cx	- DirectionType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyClueListMap	proc	far
	uses	bx,di
	.enter

	Assert	ChunkArray	dssi

	mov	bx, cs
	mov	di, offset cs:ECClueListEnumCallback
	call	ChunkArrayEnum

	.leave
	ret
ECVerifyClueListMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECClueListEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the callback routine that will verify each
		element of the ClueList Map

CALLED BY:	ChunkArrayEnum
PASS:		*ds:si	- ChunkArray (Map)
		ds:di	- element being enumerated
		cx	- DirectionType

RETURN:		CF	- always CLEAR

DESTROYED:	bx, si, di

SIDE EFFECTS:	none
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECClueListEnumCallback	proc	far
	.enter

	Assert	ClueTokenType	ds:[di], cx

	Destroy	bx,si,di

	clc

	.leave
	ret
ECClueListEnumCallback	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyBufferSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will determine if the given pointer points to a buffer
		that is at least as large as the given size.

CALLED BY:	global

PASS:		es:di	= ptr to buffer
		cx	= size of buffer, in bytes
		al	= constant to detect

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Detection Scheme:
		This routine assumes that ClearBufferForEC was called prior to
	this routine.  ClearBufferForEC will fill a given buffer with
	its size's number of EC_CONSTANT which is a bunch of cc's.
	Then it is up to this routine to go through the buffer and
	examine the given size's number of bytes.  We will fatal error
	if we should find that the buffer is smaller than the
	anticipated size. (During our scan, we detected a
	non-EC_CONSTANT before we have scanned the given number of
	bytes.)  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyBufferSize	proc	far
	uses	di
	.enter

;;; Verify incoming arguments.
	tst	cx						
	ERROR_Z	CAN_NOT_CHECK_ZERO_SIZED_BUFFER			
	tst	al						
	ERROR_Z EC_CONSTANT_IS_NULL				
;;;;;;;;

	Assert	okForRepScasb
	repe scasb

	; The zero flag will be set if scan was completed, and
	; everything in the buffer matches al.
EC <	ERROR_NZ BUFFER_DOESNT_MATCH_THE_GIVEN_SIZE		>

	.leave
	ret
ECVerifyBufferSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyValidPosInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the given position is valid for the given list.

CALLED BY:	global - Crossword Project

PASS:		al	- listPosition
		dx	- DirectionType (ACROSS or DOWN)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyValidPosInList	proc	far
	uses	ax,cx,es
	.enter

;;;	Verify incoming arg
	Assert	DirectionType	dx
;;;;;;;;

	LoadVarSeg	es, cx				; single-launchable
	mov	cx, es:[ECacrossListLen]
	cmp	dx, ACROSS
	je	continue
	mov	cx, es:[ECdownListLen]
continue:
	clr	ah
	Assert	urange	ax, 0, cx

	.leave
	ret
ECVerifyValidPosInList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyClueListInitParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that ss:[bp] is pointing to a valid
		ClueListInitParams structure.

CALLED BY:	global

PASS:		ss:[bp]	- ClueListInitParams

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyClueListInitParams	proc	far
	.enter

	Assert	gstate		ss:[bp].CLIP_gState
	Assert	EngineTokenType	ss:[bp].CLIP_engine
	Assert	ClueTokenType	ss:[bp].CLIP_acrossClue, ACROSS
	Assert	ClueTokenType	ss:[bp].CLIP_downClue, DOWN

	.leave
	ret
ECVerifyClueListInitParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyDirectionType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for a DirectionType

CALLED BY:	global	= Crossword Project

PASS:		ax	= value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyDirectionType	proc	far
	.enter

	cmp	ax, ACROSS
	je	ok
	cmp	ax, DOWN
	ERROR_NE NOT_DIRECTION_TYPE
ok:

	.leave
	ret
ECVerifyDirectionType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyEngineTokenType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for a EngineTokenType

CALLED BY:	global	= Crossword Project

PASS:		ax	= value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyEngineTokenType	proc	far
	.enter

	Assert	lmem	ax

	.leave
	ret
ECVerifyEngineTokenType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifySystemType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for a SystemType

CALLED BY:	global	= Crossword Project

PASS:		ax	= value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifySystemType	proc	far
	.enter

	cmp	ax, ST_BAD_ETYPE
	ERROR_AE NOT_SYSTEM_TYPE

	.leave
	ret
ECVerifySystemType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyVerifyModeType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for a VerifyModeType

CALLED BY:	global	= Crossword Project

PASS:		ax	= value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyVerifyModeType	proc	far
	.enter

	cmp	ax, VMT_BAD_ETYPE
	ERROR_AE NOT_VERIFY_MODE_TYPE

	.leave
	ret
ECVerifyVerifyModeType	endp


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyInitReturnValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for an InitReturnValue.

CALLED BY:	global	= Crossword Project

PASS:		ax	= value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyInitReturnValue	proc	far
	.enter

	cmp	ax, IRV_BAD_ETYPE
	ERROR_AE NOT_INIT_RETURN_VALUE
	
	.leave
	ret
ECVerifyInitReturnValue	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyDrawOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for a DrawOptions record.

CALLED BY:	global	- Crossword Project

PASS:		al	- value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyDrawOptions	proc	far
	.enter

	test	al, not mask DrawOptions
	ERROR_NZ	NOT_DRAW_OPTION

	.leave
	ret
ECVerifyDrawOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyHighlightStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if ax is a valid value for a HighlightStatus record

CALLED BY:	global	= Crossword Project

PASS:		al	= value

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyHighlightStatus	proc	far
	.enter

	test	al, not mask HighlightStatus
	ERROR_NZ	NOT_HIGHLIGHT_STATUS

	.leave
	ret
ECVerifyHighlightStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyListItemInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the passed value in ah is a valid
		ListItemInfo.

CALLED BY:	global	= Crossword Project

PASS:		ah	= ListItemInfo record

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Verify all valid combinations of bit settings .

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyListItemInfo	proc	far
	uses	ax
	.enter

	tst	ah
	jz	fine

	test	ah, mask LII_BAD_FIELD
	jz	fine

	ERROR_NZ NOT_LIST_ITEM_INFO

fine:
	.leave
	ret
ECVerifyListItemInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyCellFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the passed value in ax is a valid
		CellFlags record.

CALLED BY:	global	= Crossword Project

PASS:		al	= CellFlags record

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Verify all valid combinations of bit settings .

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyCellFlags	proc	far
	.enter

	; If CF_NON_EXISTENT, then can't have any other flags set.
	test	al, mask CF_NON_EXISTENT
	jz	notNonExistent
	test	al, not( mask CF_NON_EXISTENT )
	ERROR_NZ NOT_CELL_FLAGS
notNonExistent:

	; If CF_HOLE, then can't have any other flags set.
	test	al, mask CF_HOLE
	jz	notHole
	test	al, not( mask CF_HOLE )
	ERROR_NZ NOT_CELL_FLAGS
notHole:	

	; If CF_EMPTY, then can have only CF_NUMBER set.
	test	al, mask CF_EMPTY
	jz	notEmpty
	test	al, not( mask CF_EMPTY or mask CF_NUMBER )
	ERROR_NZ NOT_CELL_FLAGS
notEmpty:

	; If CF_HINTED, then can have only CF_NUMBER set.
	test	al, mask CF_HINTED
	jz	notHinted
	test	al, not( mask CF_HINTED or mask CF_NUMBER )
	ERROR_NZ NOT_CELL_FLAGS
notHinted:

	; If CF_WRONG, then can have only CF_NUMBER set.
	test	al, mask CF_WRONG
	jz	notWrong
	test	al, not( mask CF_WRONG or mask CF_NUMBER )
	ERROR_NZ NOT_CELL_FLAGS
notWrong:

	.leave
	ret
ECVerifyCellFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyClueListSplitStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the passed value in ax is a valid
		ClueListSplitStatus etype.

CALLED BY:	global	= Crossword Project

PASS:		ax	= ClueListSplitStatus etype

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyClueListSplitStatus	proc	far
	.enter

	cmp	ax, CLSS_BAD_ETYPE
	ERROR_AE NOT_CLUE_LIST_SPLIT_STATUS

	.leave
	ret
ECVerifyClueListSplitStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyInBound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to make sure that the given point is within a
		specified bound.

CALLED BY:	global	= Crossword Project

PASS:		axbx	= Point

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyAGC	proc	far
	uses	es
	.enter

	push	ax
	LoadVarSeg	es, ax			; single-launchable
	pop	ax

	Assert	e	ah, 0
	Assert	e	bh, 0
	Assert	ge	al, 0
	Assert	ge	bl, 0
	Assert	l	al, es:[ECnumCol]
	Assert	l	bl, es:[ECnumRow]

	.leave
	ret
ECVerifyAGC	endp

ECVerifyInBoard	proc	far
	uses	es
	.enter

	push	ax
	LoadVarSeg	es, ax			; single-launchable
	pop	ax

	Assert	urange	ax, es:[ECupLeftBoard].P_x, es:[EClowRightBoard].P_x
	Assert	urange	bx, es:[ECupLeftBoard].P_y, es:[EClowRightBoard].P_y

	.leave
	ret
ECVerifyInBoard	endp

ECVerifyInDoc	proc	far
	uses	es
	.enter

	push	ax
	LoadVarSeg	es, ax			; single-launchable
	pop	ax

	Assert	urange	ax, es:[ECupLeftDoc].P_x, es:[EClowRightDoc].P_x
	Assert	urange	bx, es:[ECupLeftDoc].P_y, es:[EClowRightDoc].P_y

	.leave
	ret
ECVerifyInDoc	endp

ECVerifyInGrid	proc	far
	uses	es
	.enter

	push	ax
	LoadVarSeg	es, ax			; single-launchable
	pop	ax

	Assert	urange	ax, es:[ECupLeftGrid].P_x, es:[EClowRightGrid].P_x
	Assert	urange	bx, es:[ECupLeftGrid].P_y, es:[EClowRightGrid].P_y

	.leave
	ret
ECVerifyInGrid	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyUserLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if letter is between A-Z

CALLED BY:	EngineSetUserLetter
PASS:		bl	- letter

RETURN:		Fatal error if invalid

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyUserLetter	proc	far
	.enter

	cmp	bl, C_CAP_A
	ERROR_L	ENGINE_USER_LETTER_INVALID
	cmp	bl, C_CAP_Z
	ERROR_G	ENGINE_USER_LETTER_INVALID

	.leave
	ret
ECVerifyUserLetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyCellTokenType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if index is less than (rows*columns)

CALLED BY:	global
PASS:		ax	- cell token

RETURN:		Fatal errors if invalid

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyCellTokenType	proc	far
	uses	ax,bx,es
	.enter

	cmp	ax, INVALID_CELL_TOKEN
	je	exit

	push	ax				; cell token
	LoadVarSeg	es, ax			; single-launchable

	mov	al, es:[ECnumCol]
	mul	{byte} es:[ECnumRow]		; ax = rows*columns
	mov	bx, ax				; rows*columns
	pop	ax				; cell token
	
	cmp	ax, bx
	ERROR_GE	ENGINE_CELL_TOKEN_INVALID	

exit:
	.leave
	ret
ECVerifyCellTokenType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckIfCwordChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the given character is in the Cword
		character set.  The set currently consists of '-',
		'?', '.', ' ', 'A'-'Z', and 'a' - 'z'.

CALLED BY:	Globabl - routines of Crossword project.

PASS:		cx	- character

RETURN:		carry	- SET if not in the character set

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckIfCwordChar	proc	far
	.enter

	call	CheckIfCwordPunct
	jnc	exit

	call	CheckIfCwordAlpha

exit:

	.leave
	ret
ECCheckIfCwordChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECVerifyClueTokenType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if clue token is a valid index into the clue 
		header array.

CALLED BY:	
PASS:		ax	- clue token
		cx	- direction

RETURN:		Fatal errors if invalid

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECVerifyClueTokenType	proc	far
	uses	es
	.enter

	Assert	DirectionType	cx

	cmp	ax, INVALID_CLUE_TOKEN
	je	exit

	push	ax
	LoadVarSeg	es, ax			; single-launchable
	pop	ax

	cmp	cx, ACROSS
	je	across
	cmp	ax, es:[ECnumDownClues]	
	jmp	done
across:
	cmp	ax, es:[ECnumAcrossClues]
done:
	ERROR_GE	ENGINE_CLUE_TOKEN_INVALID

exit:
	.leave
	ret
ECVerifyClueTokenType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSetClueCountsInDgroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the ECnumAcrossClues and ECnumDownClues
		in dgroup.

CALLED BY:	FileReadSourceDocument
PASS:		dx	- engine token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSetClueCountsInDgroup	proc	far
	uses	bx,cx,si,ds,es
	.enter

	Assert	EngineTokenType	dx

	LoadVarSeg	es, bx		; single-launchable
	
	mov	bx, ACROSS
	EngineGetClueHeaderArrayDSSI

	call	ChunkArrayGetCount	; cx - number of elements
	mov	es:[ECnumAcrossClues], cx

	call	MemUnlock		; unlock clue header block

	mov	bx, DOWN
	EngineGetClueHeaderArrayDSSI

	call	ChunkArrayGetCount	; cx - number of elements
	mov	es:[ECnumDownClues], cx

	call	MemUnlock		; unlock clue header block

	.leave
	ret
ECSetClueCountsInDgroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSetClueListLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the length of the given clue list.

CALLED BY:	ClueListInitializeObject

PASS:		ax	- numItems
		cx	- directions

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSetClueListLength	proc	far
	uses	ax, es
	.enter

	Assert	DirectionType	cx

	push	ax
	LoadVarSeg	es, ax			; single-launchable
	pop	ax

	xchg	ax, es:[ECacrossListLen]	; old val, numItems
	cmp	cx, ACROSS
	je	doneEC
	xchg	ax, es:[ECacrossListLen]	; numItems, old val
	mov_tr	es:[ECdownListLen], ax		; numItems
doneEC:

	.leave
	ret
ECSetClueListLength	endp



CwordECCode	ends


endif




