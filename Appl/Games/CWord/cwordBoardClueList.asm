COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		
FILE:		cwordBoardClueList.asm

AUTHOR:		Peter Trinh, Aug 30, 1994

ROUTINES:
	Name			Description
	----			-----------

	METHODS
	-------
	BoardUpdateClueList	Tells the clue list to change
	BoardToggleClueList	Toggles the current visible ClueList.

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardUpdateClueListGetText	Gets the text of given list item


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/30/94   	Initial revision


DESCRIPTION:
	
	Board routines that are related to the ClueList.


	$Id: cwordBoardClueList.asm,v 1.1 97/04/04 15:14:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CwordClueListCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardUpdateClueList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is sent by the ClueListQueryMsg to handle
		the updating of the ClueList.  This routine will send
		MSG_DYNAMIC_LIST_RPLACE_ITEM_TEXT to the ClueList that
		sent this message.

CALLED BY:	MSG_CWORD_BOARD_UPDATE_CLUE_LIST
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= ClueToken of item to be displayed
		dh	= ListItemInfo
		dl	= item position needing the update
		bp	= DirectionType indentifying the sender

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardUpdateClueList	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_UPDATE_CLUE_LIST
direction	local	DirectionType	push	bp
engineToken	local	EngineTokenType
gStateHandle	local	hptr.GState
clueStrHandle	local	hptr

	uses	ax, cx, dx
	.enter

	ForceRef	direction
	ForceRef	engineToken

;;; Verify argument(s)
	Assert	DirectionType	ss:[direction]
	Assert	ClueTokenType	cx, ss:[direction]
	Assert	ValidPosInList	dx, ss:[direction]
	Assert	ListItemInfo	dx
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_engine
	tst	ax
	jz	exit	

	mov	ss:[engineToken], ax
	mov_tr	ax, cx				; clue token

	call	BoardGetGStateDI
	mov	ss:[gStateHandle], di

	; Decide which list we're dealing with, and update the 
	; selected clue instance data.
	mov	bx, handle AcrossClueList	; single-launchable
	mov	si, offset AcrossClueList	; dest object
	cmp	ss:[direction], ACROSS
	je	gotClueListObject
	mov	bx, handle DownClueList		; single-launchable
	mov	si, offset DownClueList		; dest object
gotClueListObject:

	; Allocate a character buffer on the stack
	sub	sp, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
	segmov	es, ss, di
	mov	di, sp				; es:di - fptr to charBuffer

	push	dx				; ClueListInfo/item num
	call	BoardUpdateClueListGetText
	pop	ax				; ClueListInfo/item num
	jc	exit				; error, no string

	; Got the correct string to be displayed.
	; Can NOT use MF_STACK.  MUST use MF_CALL because passing fptr
	; into the stack.
	push	bp				; local stack frame
	clr	ah				; remove ClueListInfo
	mov	bp, ax				; item number
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	call	ObjMessage
	pop	bp				; local stack frame

	tst	ss:[clueStrHandle]
	jz	exit				; don't free NULL handle
	mov	bx, ss:[clueStrHandle]
	call	MemFree
	
exit:
	; Deallocate char buffer
	add	sp, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT

	.leave
	ret
BoardUpdateClueList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardUpdateClueListGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PRIVATE! Gets the text corresponding to the given clue
		token.  

CALLED BY:	BoardUpdateClueList

PASS:		*ds:si	- CwordClueList object
		^lbx:si	- CwordClueList object
		es:di	- fptr to char buffer of size 
				ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
		*es can NOT be pointing to LMem block.
		ax	- ClueToken
		bp	- inherited stack frame
		dh	- ListItemInfo
		dl	- item position needing the update

RETURN:		cx:dx	- fptr to a null-terminated string stored in a
			  locked block.
		CF	- SET if error, and cx:dx is invalid

DESTROYED:	nothing
SIDE EFFECTS:

	A handle to the block containing the null-terminated string is
	stored in the clueStrHandle on the stack.  This block has been
	locked down so that we can return cx:dx, and it needs to be
	freed after sending the fptr to the target ClueList.

	If clueStrHandle is 0, then that implies the whole clue text
	fits on one line and thus no split happened.  Then we didn't
	allocate a block to store the text, because the buffer passed
	in is sufficient.

	This version doesn't support DBCS.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardUpdateClueListGetText	proc	near
	uses	ax,bx,di,es
	.enter	inherit BoardUpdateClueList

;;; Verify argument(s)
	Assert	ClueTokenType	ax, ss:[direction]
	Assert	ValidPosInList	dx, ss:[direction]
	Assert	ListItemInfo	dx
	Assert	objectOD	bxsi, CwordClueListClass, fixup
;;;;;;;;

	clr	ss:[clueStrHandle]		; assume no split

	mov	cx, ss:[direction]
	push	dx				; ClueListInfo/item num
	mov	dx, ss:[engineToken]
	call	EngineGetClueText
	pop	ax				; ClueListInfo/item num

	; Null-terminate the received string.
	add	di, cx				; ptr to 1 past last char
	clr	{byte}es:[di]
	sub	di, cx				; ptr to first character

	; Get the appropriate portion of the split
	; bx:si is the optr to the destination object

	push	bp				; inherited stack frame
	mov	cx, ss:[gStateHandle]

	BoardAllocStructOnStack		ClueListGetSplitParams
	mov	ss:[bp].CLGSP_gState, cx
	mov	ss:[bp].CLGSP_splitNumber, ah
	movdw	ss:[bp].CLGSP_strPtr, esdi

	mov	ax, MSG_CWORD_CLUE_LIST_GET_NTH_SPLIT
	mov	dx, size ClueListGetSplitParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
gotStrHandle::
	mov	di, ss:[bp].CLGSP_gState
	call	GrDestroyState
	Assert	ClueListSplitStatus	cx

	cmp	cx, CLSS_NO_SPLIT
	je	noSplit

	BoardDeAllocStructOnStack	ClueListGetSplitParams
	pop	bp				; inherited stack frame

	tst	ax				; ^h clue string
	jz	err

	mov	ss:[clueStrHandle], ax
	mov_tr	bx, ax
	call	MemLock
	mov_tr	cx, ax
	clr	dx				; cx:dx - fptr to clue str

gotString:

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	stc
	Assert	e	ss:[clueStrHandle], 0
	jmp	gotString

noSplit:
	movdw	cxdx, ss:[bp].CLGSP_strPtr	; fptr to clue str
	BoardDeAllocStructOnStack	ClueListGetSplitParams
	pop	bp				; inherited stack frame
	Assert	e	ss:[clueStrHandle], 0
	jmp	gotString
	
BoardUpdateClueListGetText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardToggleClueList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In the _SINGLE_CLUE_LIST mode, will toggle which
		ClueList is seen.

CALLED BY:	MSG_CWORD_BOARD_TOGGLE_CLUE_LIST
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardToggleClueList	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_TOGGLE_CLUE_LIST
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_CWORD_CLUE_LIST_TOGGLE_VISIBILITY
	mov	bx, handle AcrossClueList
	mov	si, offset AcrossClueList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_CWORD_CLUE_LIST_TOGGLE_VISIBILITY
	mov	bx, handle DownClueList
	mov	si, offset DownClueList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
BoardToggleClueList	endm


CwordClueListCode	ends


