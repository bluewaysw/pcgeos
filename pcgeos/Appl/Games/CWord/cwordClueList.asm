COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		ClueList
FILE:		cwordClueList.asm

AUTHOR:		Peter Trinh, May 11, 1994

ROUTINES:
	Name			Description
	----			-----------
	METHODS
	-------
	ClueListInitializeObject Method handler for initalize msg.
	ClueListCleanUp		Free up used data and other cleaning
	ClueListApplyMsg	Will be sent whenever changes in
				selection, etc.
	ClueListQueryMsg	Will start process of displaying an item.
	ClueListDisplayItem	Displays the given item, ClueToken.
	ClueListGetNthSplit	Gets the nth portion of a split str
	ClueListToggleVisibility Toggles between USABLE and NOT_USABLE
	CCLGenDynamicListNumVisibleItemsChanged

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	ClueListBuildMap	Creates a map which is a ChunkArray.
	ClueListInitMap		Initializes the Map
	ClueListAppendToMap	Appends a ClueTokenType to the map.
	ClueListGetNthItemFromMap	Gets an the nth item from the map.
	ClueListSearchMap	Searches the map for given key.
	ClueListSearchCallback	Determine if an item matches the key.
	ClueListTrackCell	Tells the Board to make cell visible.
	ClueListHighlightClue	Highlight the given clue.
	ClueListSelectClueItems	Highlight the given clue list items.
	ClueListGetMostRecentSelection  From the list object.

	ClueListSplitTextString	Divide a given string into two lines.
	ClueListGetIndentationWidth
	ClueListIndentString
	ClueListGetHyphenWidth
	ClueListStripTildeAndHyphenate
	ClueListCopyStringsGivenDelimiter
	ClueListCopyStrToBlock
	ClueListGetItemNumber
	ClueListSendMessageToSelf
	ClueListRecalcSize	Recalculates the width of the list.

*	TestStringRoutines

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/11/94   	Initial revision


DESCRIPTION:
	This file contains the routines to the ClueList Module.
		

	$Id: cwordClueList.asm,v 1.1 97/04/04 15:14:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordClueListCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListInitializeObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes a clue list object.

CALLED BY:	MSG_CWORD_CLUE_LIST_INITIALIZE_OBJECT
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

		ss:[bp]	= ClueListInitParams

RETURN:		ax	= InitReturnValue

DESTROYED:	nothing
SIDE EFFECTS:
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

	Note:	In the case of an initialization failure, CCLI_map will
	     	be cleared.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListInitializeObject	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_INITIALIZE_OBJECT
	uses	cx, dx, bp
	.enter

;;; Verify argument(s)
	Assert	ClueListInitParams	ssbp
;;;;;;;;

;	call	TestStringRoutines

	call	ClueListBuildMap
	LONG jc	err

	; Initialize our instance data
	GetInstanceDataPtrDSDI	CwordClueList_offset
	mov	ds:[di].CCLI_numWrapRows, CLUE_DEF_NUM_WRAP_ROWS
	mov	ax, ss:[bp].CLIP_direction
	mov	ds:[di].CCLI_direction, ax

	;
	; Now initialize the parameters to pass to ClueListInitMap
	;
	push	bp			; CLIP structure
	mov	bx, bp			; CLIP structure
	BoardAllocStructOnStack		ClueListInitMapParams

	; Determine the routines and data that corresponds to this
	; clue list's.
	mov	cx, offset EngineGetFirstClueTokenAcross
	mov	ss:[bp].CLIMP_getNextClueToken, offset EngineGetNextClueTokenAcross
	mov	dx, ss:[bx].CLIP_acrossClue
	cmp	ax, ACROSS
	je	madeChoice
	mov	cx, offset EngineGetFirstClueTokenDown
	mov	ss:[bp].CLIMP_getNextClueToken, offset EngineGetNextClueTokenDown
	mov	dx, ss:[bx].CLIP_downClue
madeChoice:
	mov	ax, ss:[bx].CLIP_gState
	mov_tr	ss:[bp].CLIMP_gState, ax

	push	dx			; save the selected clueToken

	; Find the first cell token in the corresponding direction of
	; this clue list.
	mov	dx, ss:[bx].CLIP_engine
	call	cx			; getFirstClueToken: bx - 1st
	mov_tr	ax, bx			; first clue token
EC <	mov	cx, ds:[di].CCLI_direction			>
	call	ClueListInitMap		; if NOT error: ax = numItems
	pop	di			; selected clueToken
	jc	cleanUp

if ERROR_CHECK
	pushf
	GetInstanceDataPtrDSBX	CwordClueList_offset
	SetECVarClueListLength ss:[bp].CLIMP_numItems, ds:[bx].CCLI_direction
	popf
endif

	; Tell the list that it has numItems
	mov	cx, ss:[bp].CLIMP_numItems	; numItems
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	ClueListSendMessageToSelf

	BoardDeAllocStructOnStack	ClueListInitMapParams
	pop	bp			; CLIP_STRUCTURE

	; Makes sure the selected clue is hi-lited and displayed
	mov	cx, di			; selected clueToken
	mov	dx,ss:[bp].CLIP_listToHighlight
	mov	ax, MSG_CWORD_CLUE_LIST_DISPLAY_ITEM
	call	ClueListSendMessageToSelf

	mov	ax, IRV_SUCCESS

exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cleanUp:
	BoardDeAllocStructOnStack	ClueListInitMapParams
	mov	ax, MSG_CWORD_CLUE_LIST_CLEAN_UP
	call	ClueListSendMessageToSelf
err:
	mov	ax, IRV_FAILURE
	jmp	exit

ClueListInitializeObject	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free's up the map and other cleaing chores.  Basically
		invalidate self and be prepare to quit or re-initialize.

CALLED BY:	MSG_CWORD_CLUE_LIST_CLEAN_UP
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListCleanUp	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_CLEAN_UP
	uses	ax
	.enter

	tst	ds:[di].CCLI_map
	jz	alreadyClean

	mov	ax, ds:[di].CCLI_map
	call	LMemFree
	clr	ds:[di].CCLI_map

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	cx				; no items in list
	call	ClueListSendMessageToSelf

alreadyClean:

	.leave
	ret
ClueListCleanUp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListApplyMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The state of the ClueList is modified in some way,
		usually by the user selecting an item in the group.
		This method handler will decide what to do based on
		the GenItemGroupStateFlags.

CALLED BY:	MSG_CWORD_CLUE_LIST_APPLY_MSG
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

		cx	= current selection, or first selection in
 			item group, if more than one selection, or
 			GIGS_NONE of no selection 
		bp	= number of selections
		dl	= GenItemGroupStateFlags
		
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListApplyMsg	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_APPLY_MSG
	uses	ax, cx, dx, bp
	.enter

	cmp	cx, GIGS_NONE
	je	itsADeselect

;;; Verify argument(s)
	Assert	ValidPosInList	cx, ds:[di].CCLI_direction
;;;;;;;;

	; If we have more than 4 items selected, we're just gonna take
	; the current item that is selected and ignore the rest.  The
	; current item will not be the most recent item.
	cmp	bp, 4
	mov_tr	ax, cx				; current item
	jg	gotItem

	call	ClueListGetMostRecentSelection
	jc	exit

gotItem:
	push	si				; CCLC object

	mov	si, ds:[di].CCLI_map
	mov	bx, ds:[di].CCLI_direction	; GetItem uses for EC
						; TrackCell needs also
	call	ClueListGetNthItemFromMap
EC <	ERROR_C	CLUE_LIST_ITEM_NOT_IN_MAP			>

	call	ClueListTrackCell

	pop	si				; CCLC object

	call	ClueListHighlightClue

exit:
	;
	;  Let the Board to have the key exclusive
	;
	GetResourceHandleNS	CwordView, bx
	mov	si, offset CwordView
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
EC <	Destroy	ax, cx, dx, bp					>
	ret

itsADeselect:
	;    The user has deselected a clue. Which really means they have
	;    selected an already selected clue and are probably trying
	;    to change the selecte word direction. Beside we don't like
	;    having no clue selected.
	;

	mov	dx,ds:[di].CCLI_direction
	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_CWORD_BOARD_SET_DIRECTION
	call	ObjMessage
	jmp	exit

ClueListApplyMsg	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListQueryMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Is the starting message to a chain of messages that
		will get the necessary moniker and display it in the
		ClueList. 

CALLED BY:	MSG_CWORD_CLUE_LIST_QUERY_MSG
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

		^lcx:dx	= the ClueList requesting the moniker
		bp	= the position of the item requested

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	targetClueToken = retrieve from map with targetItem
	firstItem = search map for first item that's equal to targetClueToken
	if targetItem = firstItem {
		nextItem = firstItem + 1;
		nextClueToken = retrieve from map with nextItem;
		if nextClueToken = targetClueToken {
			splitLineNumber = 1;
			splitLineNmber bitOr mask SPLIT;
		} else {
			not a SPLIT
		}
	} else if targetItem < firstItem {
		ERROR
	} else {
		splitLineNumber = targetItem - firstItem + 1;
		splitLineNumber bitOr mask SPLIT
	}
		

General Mechanism to get the clue list to display the appropriate
clue text. 

	Will look for the corresponding ClueToken to the given
		item position in the its Map.  
	Then tell the Board to retrieve the string corresponding to
		the given position from the Engine.
	The Board will then send the string back to the ClueList via
		MSG_CWORD_CLUE_LIST_DISPLAY_ITEM.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListQueryMsg	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_QUERY_MSG
	uses	ax, dx
	.enter

;;; Verify argument(s)
	Assert	ObjectClueList	dssi
	Assert	objectOD	cxdx, CwordClueListClass, fixup
	Assert	ValidPosInList	bp, ds:[di].CCLI_direction
;;;;;;;;

EC <	push	si			; lptr to CCLC obj>

	mov	si, ds:[di].CCLI_map
	tst	si
	jz	finish

	; targetClueToken = ClueListGetNthItemFromMap( targetItem)
	mov	ax, bp			; item number
EC <	mov	bx, ds:[di].CCLI_direction				>
	call	ClueListGetNthItemFromMap	; cx - target clue token
EC <	ERROR_C	CLUE_LIST_ITEM_NOT_IN_MAP			>

	;
	; Assuming this clue token has a text that splits, find out
	; which split line that the given item number corresponds to
	;

	; firstItem = ClueListSearchMap( targetClueToken)
	call	ClueListSearchMap	; ax - first item of this clue

	; assume splitNumber = 1
	mov	dh, 1			; assume is first split line
	cmp	ax, bp
	je	verifyIsFirstSplitLine
EC <	ERROR_G	CLUE_LIST_ITEM_ORDER_IS_IMPOSSIBLE
	sub	ax, bp
	Assert	l	ax, bp
	neg	ax			; difference between ax, bp
	inc	ax			; splitNumber
	mov	dh, al
	or	dh, mask LII_SPLIT	; is a split

	mov	ax, bp			; target item number
	mov	dl, al			; target item number

gotFlags:
	; dx - packaged item number with split number, cx - target clue token
	; There has yet to be a list that would contain more than 256
	; items.  If so, then need to modify how ListItemInfo is
	; passed to BoardUpdateClueList.
	mov	bp, ds:[di].CCLI_direction	; id of ClueList

	mov	bx, handle Board	; single-launchable
	mov	si, offset Board
	mov	di, mask MF_FIXUP_DS	; SEND don't CALL
	mov	ax, MSG_CWORD_BOARD_UPDATE_CLUE_LIST
	call	ObjMessage	

finish:

EC <	pop	si			; lptr to List obj	>
	Assert	ObjectClueList	dssi
EC <	pushf							>
EC <	Destroy	ax, cx, dx, bp					>
EC <	popf							>

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
verifyIsFirstSplitLine:
	; We know that the given item number is equal to the first
	; item number of the clue token, but we still don't know if
	; the clue token splits.  Thus checking the next item in the
	; map for duplicity in the clue token will determine if it
	; splits or not.

	; bp - target item number, cx - target clue token 
	; ax - first item corresponding to target clue token 
	; dh - 1, implying that this is first line of a split
	; *ds:si - map, bx - direction (EC version)
	Assert	e	bp, ax
	
	mov	bp, cx			; target clue token
	inc	ax			; nextItem
	call	ClueListGetNthItemFromMap
	jc	notSplit		; end of list
	cmp	bp, cx			; targetClueToken, nextClueToken
	jne	notSplit		; jmp if not duplicate
	or	dh, mask LII_SPLIT	; found duplicate so is a split
notSplit:
	mov	dl, al			; nextItem
	dec	dl			; targetItem
	mov	cx, bp			; targetClueToken
	jmp	gotFlags	

ClueListQueryMsg	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListDisplayItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will display and highlight the item corresponding to
		the passed ClueToken. If the passed direction is
		zero or equals the direction of the list then
		highlight the clue. Otherwise just get the clue on
		screen, but don't highlight it. 

CALLED BY:	MSG_CWORD_CLUE_LIST_DISPLAY_ITEM
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

		cx	= ClueTokenType
		dx 	- Direction

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListDisplayItem	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_DISPLAY_ITEM
	uses	ax, cx, dx, bp
	.enter

;;; Verify argument(s)
	Assert	ObjectClueList	dssi
	Assert	ClueTokenType	cx, ds:[di].CCLI_direction
;;;;;;;;

	push	dx				; Direction

	push	si				; CCLC object
	mov	si, ds:[di].CCLI_map

EC <	pushf							>
EC <	push	bx				; trash reg	>
EC <	mov	bx, ds:[di].CCLI_direction			>
	call	ClueListGetItemNumber
EC <	pop	bx				; trash reg	>
EC <	popf							>
	pop	si				; CCLC object

	; Take the min of the number of items visible and the number
	; of lines spanned by the clue.
	mov	bx, dx				; min
	cmp	dx, ds:[di].CCLI_numVisible
	jle	foundMin
	mov	bx, ds:[di].CCLI_numVisible
foundMin:
	mov	dx, bx				; num total items to
						; make visible

	mov	bx, cx				; clue token
	mov_tr	cx, ax				; item number of first line
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	dec	dx				; num visible left
	jz	oneVisibleItemLeft

	call	ClueListSendMessageToSelf	; display first line
	add	cx, dx				; dsiplay last line

oneVisibleItemLeft:
	call	ClueListSendMessageToSelf

	pop	dx				; Direction
	mov	cx, bx				; clue token
	call	ClueListHighlightClue

	.leave
	ret

ClueListDisplayItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListGetNthSplit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the the nth portion of the given text
		string that needs to be split.  If necessary, it will
		also pad it with '-' and a null-terminator. 

CALLED BY:	MSG_CLUELIST_GET_NTH_SPLIT
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

		ss:bp	= ClueListGetSplitParams

RETURN:		cx	- ClueListSplitStatus
		
		if cx = CLSS_NO_SPLIT, then ax = 0, ie. no block was
		allocated.  In this situation, the string buffer that
		was passed in will have been stripped of tilde.

		if cx = CLSS_SPLIT, then ax is as follows:
		ax = handle to block containing null-terminated clue
			string  		
			-- or --
		ax = 0 if error in allocating the block


DESTROYED:	nothing
SIDE EFFECTS:	

	Destroy portions of the passed string.  

	Allocated a block to store the returned string that needs to be
	freed by the calling routine.

PSEUDO CODE/STRATEGY:

	repeatedly split the text string until we get the split we want.
	Then do the padding.
	If the string needn't be split, then we'll 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListGetNthSplit	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_GET_NTH_SPLIT
	uses	dx
	.enter

;;; Verify argument(s)
	Assert	ObjectClueList	dssi
;;;;;;;;

	clr	ss:[bp].CLGSP_strHandle
	test	ss:[bp].CLGSP_splitNumber, mask LII_SPLIT
	jz	dontAllocateBlock

	mov	ax, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
	mov	cx, ALLOC_DYNAMIC
	callerr	MemAlloc
	mov	ss:[bp].CLGSP_strHandle, bx
dontAllocateBlock:

	; Setup and do the initial split for the first line
	clr	ax			; split counter
	mov	al, ss:[bp].CLGSP_splitNumber
	BitClr	al, LII_SPLIT
	movdw	essi, ss:[bp].CLGSP_strPtr
	mov	dx, ds:[di].CCLI_lineWidth
	mov	di, ss:[bp].CLGSP_gState
	call	ClueListGetHyphenWidth
	sub	dx, cx
	mov	cx, dx			; total line width
	call	ClueListSplitTextString
	jc	noSplit
	clr	cx			; indentation flag if jump
	dec	al			; one less time
	jz	stripAndPadEnd

	call	ClueListGetIndentationWidth
	sub	dx, cx			; account for indentation
	mov	cx, dx			; new line width

repeatSplit:
	SkipOverHyphenation	es, bx
	mov	si, bx			; new start of string
	call	ClueListSplitTextString
	dec	al
	jnz	repeatSplit
	mov	cx, TRUE

stripAndPadEnd:
	call	ClueListStripTildeAndHyphenate
	call	ClueListCopyStrToBlock
	mov	cx, CLSS_SPLIT

exit:
	mov_tr	ax, ss:[bp].CLGSP_strHandle

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
noSplit:
	call	ClueListStripTildeAndHyphenate
	mov	cx, CLSS_NO_SPLIT
	jmp	exit
	
err:
	mov	dx, WARN_N_CONT
	mov	di, CCL_LOW_MEM_WARN
	call	CwordPopUpDialogBox
	Assert	e ss:[bp].CLGSP_strHandle, 0
	mov	cx, CLSS_NO_SPLIT
	jmp	exit

ClueListGetNthSplit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListToggleVisibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will toggle between USABLE and NOT_USABLE depending on
		the current state.  If USABLE then become NOT_USABLE
		and vice versa.

CALLED BY:	MSG_CWORD_CLUE_LIST_TOGGLE_VISIBILITY
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
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
ClueListToggleVisibility	method dynamic CwordClueListClass, 
					MSG_CWORD_CLUE_LIST_TOGGLE_VISIBILITY
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_GET_USABLE
	call	ObjCallInstanceNoLock		; CF set if USABLE

	mov	ax, MSG_GEN_SET_USABLE
	jnc	gotMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
gotMessage:
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	push	ax				; message id
	call	ObjCallInstanceNoLock
	pop	ax				; message id

	cmp	ax, MSG_GEN_SET_NOT_USABLE
	je	done

	;
	; Now, we must get the list to show the currently selected
	; item since setting USABLE causes the list to display the
	; very first item of the list.
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock

	;
	; Timing is an issue here.  We need the following message to
	; be handled after the SET_USABLE.  So record the event, and
	; FORCE_QUEUE a dispatch message which FORCE_QUEUE's the
	; event.
	;
	mov_tr	cx, ax				; item selected
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	cx, di				; ^h recorded message
	mov	dx, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_DISPATCH_EVENT
	clr	di				; no message flag
	mov	bx, handle Board
	mov	si, offset Board
	call	ObjMessage
	
done:
	.leave
	ret
ClueListToggleVisibility	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CCLGenDynamicListNumVisibleItemsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Whenever the number of visible item changes, this
		message is sent to the dynamic list.  So we're going
		to intercept this message and store value passed in cx
		into the ClueListInstance data.

CALLED BY:	MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED
PASS:		*ds:si	= CwordClueListClass object
		ds:di	= CwordClueListClass instance data
		ds:bx	= CwordClueListClass object (same as *ds:si)
		es 	= segment of CwordClueListClass
		ax	= message #

		cx	= number of items that can now be visible at one time
		bp	= current top item, if scrollable

RETURN:		nothing 
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	9/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CCLGenDynamicListNumVisibleItemsChanged	method dynamic CwordClueListClass, 
				MSG_GEN_DYNAMIC_LIST_NUM_VISIBLE_ITEMS_CHANGED
	.enter

	mov	ds:[di].CCLI_numVisible, cx

	mov	di, offset CwordClueListClass
	call	ObjCallSuperNoLock

EC <	Destroy	ax,cx,dx,bp					>
	.leave
	ret
CCLGenDynamicListNumVisibleItemsChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListBuildMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will create a ChunkArray in the given ClueList object
		block, and initialize the ClueList CCLI_map instance
		data. 

CALLED BY:	ClueListInitializeObject

PASS:		*ds:si	- CwordClueClass object

RETURN:		CLI_map	- contains chunk handle of new ChunkArray
		ds	- segment of object (might have moved)
		CF	- SET if error (not enough memory)

DESTROYED:	nothing
SIDE EFFECTS:
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListBuildMap	proc	near
class	CwordClueListClass
	uses	ax,bx,cx,dx,di,si
	.enter

;;; Verify argument(s)
	Assert	objectPtr	dssi, CwordClueListClass
;;;;;;;;

	mov	di, si			; CwordClueListClass object

	; Create a ChunkArray inside of the block
	mov	bx, size ClueTokenType	; size of each element
	clr	cx			; no extra space needed in hdr
	clr	si			; allocate a handle
	clr	ax			; not object chunk
	callerr	ChunkArrayCreate

	; Get ptr to CCLC instance data
	mov	bx, ds:[di]
	add	bx, ds:[bx].CwordClueList_offset

	mov	ds:[bx].CCLI_map, si	; save chunk handle of map

;;; Verify return value(s)
	Assert	ChunkArray	dssi
;;;;;;;;

	clc
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	; Make sure the map is cleared on an error case.
	mov	di, ds:[di]			; dereference ClueList object
	add	di, ds:[di].CwordClueList_offset
	clr	ds:[di].CCLI_map

	mov	dx, ERR_N_RESTART
	mov	di, CCL_LOW_MEM_ERR
	call	CwordPopUpDialogBox
	stc
	jmp	exit

ClueListBuildMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListInitMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the map by getting the corresponding
		text string to each ClueToken and splitting the text.
		If the text splits, then two position in the map will
		contain the same ClueToken.

CALLED BY:	ClueListInitializeObject

PASS:		*ds:si	- CwordClueListClass object
		ss:[bp]	- ClueListInitMapParams
		ax	- First Across/Down ClueToken
		dx	- EngineTokenType

		cx	- Direction Type (EC version only)

RETURN:		CF	- SET if error

DESTROYED:	ss:[bp].CLIMP_numWrapRows, ss:[bp].CLIMP_lineWidth
SIDE EFFECTS:	

	if successful, ss:[bp].CLIMP_numItems will be updated

PSEUDO CODE/STRATEGY:

	if (numWrapRows > 0 and lineWidth > 0) {
		get indentWidth
		do {	
			append an item to map
			numItems++
			numWrapRows--
			while (numWrapRows > 0 ) {
				if splitted before reduce lineWidth
				split text string
				if CF SET { break }
				append an item to map
				numItems++
				numWrapRows--
			}
			nextToken = get next clue token
		} while have valid clue token
	}


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListInitMap	proc	near
class	CwordClueListClass

;;; Verify argument(s)
	Assert	ObjectClueList	dssi
	Assert	ClueTokenType	ax, cx
	Assert	EngineTokenType	dx
;;;;;;;;

	uses	ax,cx,bx,di,si,es
	.enter

	GetInstanceDataPtrDSBX	CwordClueList_offset
	tst	ds:[bx].CCLI_numWrapRows
	LONG jz	exit
	tst	ds:[bx].CCLI_lineWidth
	LONG jz	exit

	clr	ss:[bp].CLIMP_numItems
	clr	ss:[bp].CLIMP_indentFlag	; no indent for first line
	mov	di, ss:[bp].CLIMP_gState
	call	ClueListGetIndentationWidth
	mov	ss:[bp].CLIMP_indentWidth, cx	; indentation width
	mov	ss:[bp].CLIMP_clueListObj, si	; ^h CCL object
	; Determine the width to split text with, but account for
	; hyphen at the end
	mov	cx, ds:[bx].CCLI_lineWidth
	mov	ss:[bp].CLIMP_lineWidth, cx
	call	ClueListGetHyphenWidth
	sub	ss:[bp].CLIMP_lineWidth, cx	

	; Allocate a character buffer on the stack
	sub	sp, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
	segmov	es, ss, di
	mov	ss:[bp].CLIMP_bufferPtr, sp
	
fillInMap:
	;
	; ax - first clue token, dx - engine token, bx - instance data ptr
	;
	mov	cx, ds:[bx].CCLI_numWrapRows
	mov	ss:[bp].CLIMP_numWrapRows, cx

	mov	si, ds:[bx].CCLI_map
	mov	bx, ds:[bx].CCLI_direction
	call	ClueListAppendToMap
	LONG jc	err
	inc	ss:[bp].CLIMP_numItems		; num items in map
	dec	ss:[bp].CLIMP_numWrapRows	; remaining wrap rows

	; See if we've reached the limit on the number wrapped rows
	tst	ss:[bp].CLIMP_numWrapRows
	jz	addNextClueToMap		; no more rows

	; Get the clue text string from the engine
	mov	cx, bx				; direction
	mov	di, ss:[bp].CLIMP_bufferPtr	; es:di - buffer ptr
	call	EngineGetClueText
	mov	bx, cx				; num chars in buffer
	clr	{byte}es:[di+bx]		; null terminate

repeatSplit:
	;
	; es:di - start of null-terminated text string to split
	;
	mov	si, di				; offset to buff
	mov	di, ss:[bp].CLIMP_gState

	; Now get the width to which we would like the split
	mov	cx, ss:[bp].CLIMP_lineWidth
	cmp	ss:[bp].CLIMP_indentFlag, TRUE	; indentation flag
	jne	dontIndent
	sub	cx, ss:[bp].CLIMP_indentWidth	; indentation width
dontIndent:
	call	ClueListSplitTextString		; CF SET if no split
	jc	addNextClueToMap

	; Get beginning of next string to split
	; If the character after the split is a space or tilde, then
	; can skip it and start with next char
	mov	di, bx				; end of split str
	SkipOverHyphenation	es, di

	; ax - first clue token, dx - engine token
	mov	si, ss:[bp].CLIMP_clueListObj	; ^h CCL object
	GetInstanceDataPtrDSBX	CwordClueList_offset
	mov	si, ds:[bx].CCLI_map
	mov	bx, ds:[bx].CCLI_direction
	callerr	ClueListAppendToMap
	inc	ss:[bp].CLIMP_numItems
	dec	ss:[bp].CLIMP_numWrapRows

	mov	ss:[bp].CLIMP_indentFlag, TRUE	; acct for indentation now
	tst	ss:[bp].CLIMP_numWrapRows
	jnz	repeatSplit

addNextClueToMap:
	clr	ss:[bp].CLIMP_indentFlag	; reset indentation flag
	mov	si, ss:[bp].CLIMP_clueListObj
	call	ss:[bp].CLIMP_getNextClueToken
	mov_tr	ax, bx				; next clue token
	GetInstanceDataPtrDSBX	CwordClueList_offset
	cmp	ax, ENGINE_LAST_CLUE
	LONG jne fillInMap

	; Remove buffer
	add	sp, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
	clc
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	; Remove buffer
	add	sp, ENGINE_MAX_LENGTH_FOR_CLUE_TEXT
	stc
	jmp	exit

ClueListInitMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListAppendToMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends a ClueTokenType to the end of the map.

CALLED BY:	ClueListInitializeObject
PASS:		*ds:si	- map (ChunkArray)
		ax	- ClueTokenType

		bx	- DirectionType

RETURN:		CF	- SET if error

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListAppendToMap	proc	near
	uses	bx,di
	.enter

;;; Verify argument(s)
	Assert	ClueListMap	dssi, bx
	Assert	ClueTokenType	ax, bx
;;;;;;;;

	clr	bx				; fixed size element
	xchg	ax,bx				; 0, ClueTokenType
	callerr	ChunkArrayAppend
	xchg	ax,bx				; ClueTokenType, 0

	mov	ds:[di], ax			; copy element in
	clc
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	push	dx				; save reg
	mov	dx, ERR_N_RESTART
	mov	di, CCL_APPEND_ERR
	call	CwordPopUpDialogBox
	pop	dx				; restore reg
	stc
	jmp	exit

ClueListAppendToMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListGetNthItemFromMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will get the given nth item from the map.

CALLED BY:	ClueListQueryMsg, ClueListHighlightClue

PASS:		*ds:si	- ChunkArray (Map)
		ax	- item number

		bx	- DirectionType (EC version)

RETURN:		CF	- SET if not in map
			else
		cx	- ClueTokenType


DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListGetNthItemFromMap	proc	near
	uses	di
	.enter

;;; Verify argument(s)
	Assert	ClueListMap	dssi, bx
;;;;;;;;

	call	ChunkArrayGetCount
	cmp	ax, cx
	cmc
	jbe	exit				; really jae
	
	call	ChunkArrayElementToPtr		; ds:di = element,
EC <	ERROR_C	CHUNK_ARRAY_ELEMENT_OUT_OF_BOUNDS		>

	; Copy from the array to the buffer
	mov	cx, ds:[di]

	clc
exit:
	.leave
	ret
ClueListGetNthItemFromMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListSearchMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will search the given ClueList object for the given
		ClueToken.  

CALLED BY:	ClueListGetItemNumber, ClueListHighlightClue

PASS:		*ds:si	- ChunkArray (Map)
		cx	- ClueTokenType (target)

		bx	- DirectionType (EC Version)

RETURN:		ax	- item number of the first occurence in the map

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListSearchMap	proc	near
class	CwordClueListClass

	uses	dx,di,si
	.enter

;;; Verify argument(s)
	Assert	ClueListMap	dssi, bx
	Assert	ClueTokenType	cx, bx
;;;;;;;;

EC <	push	bx				; direction 	>

EC <	mov	dx, bx				; direction	>
	mov	bx, cs
	mov	di, offset cs:ClueListSearchCallback
	call	ChunkArrayEnum

EC <	pop	bx				; direction	>

	; Assumes that ax is in the list.
	Assert	ValidPosInList	ax, bx

	.leave
	ret
ClueListSearchMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListSearchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will compare the given element with the key and ends
		if found the key.

CALLED BY:	ChunkArrayEnum

PASS:		cx	- ClueTokenType
		dx	- DirectionType (EC version)

RETURN:		if CF is SET then
			ax - item number of this element

DESTROYED:	bx, si, di
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListSearchCallback	proc	far
	.enter

;;; Verify argument(s)
	Assert	ClueTokenType	cx, dx
;;;;;;;;

	cmp	cx, ds:[di]
	jne	exit

	call	ChunkArrayPtrToElement
	stc		

exit:
EC <	pushf							>
EC <	Destroy	bx,si,di					>
EC <	popf							>

	.leave
	ret
ClueListSearchCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListTrackCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the Board to make sure that the Cell
		corresponding to the given ClueToken is visible.

CALLED BY:	ClueListApplyMsg

PASS:		cx	- ClueTokenType
		bx	- DirectionType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListTrackCell	proc	near
	uses	ax,bx,si,di
	.enter

;;; Verify argument(s)
	Assert	ClueTokenType	cx, bx
;;;;;;;;

	mov	bp, bx				; direction
	mov	bx, handle Board		; single-launchable
	mov	si, offset Board
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_BOARD_TRACK_CELL
	call	ObjMessage

	.leave
	ret
ClueListTrackCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListHighlightClue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will highlight the given clue, meaning if the clue
		wraps, then highlight both list items. Only highlight
		clue if direction is zero or matches list

CALLED BY:	ClueListDisplayItem, ClueListApplyMsg

PASS:		*ds:si	- CwordClueListClass object
		cx	- ClueTokenType
		dx 	- Direction 

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListHighlightClue	proc	near
class	CwordClueListClass
	uses	ax,bx,cx,dx,di,bp
	.enter

	
;;; Verify argument(s)
	Assert	ObjectClueList	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordClueList_offset	

;;; Verify argument(s)
EC <	mov	bx, ds:[di].CCLI_direction		>
	Assert	ClueTokenType	cx, bx
;;;;;;;;

	tst	dx
	jz	highlight
	cmp	dx,ds:[di].CCLI_direction
	jne	unhighlight

highlight:
	; Allocate enough room for the case where all numWrapRows were
	; used.
	sub	sp, ds:[di].CCLI_numWrapRows
	mov	bp, sp				; ss:bp - bufPtr

	; For EC version, ClueListSearchMap and ClueListGetNthItemFromMap
	; expects bx to contain the direction.
EC <	push	bp				; ss:bp - bufPtr	>
	push	si				; CCLC object
	mov	si, ds:[di].CCLI_map		; *ds:si - Map
	; bx - DirectionType (EC)
	call	ClueListSearchMap		; ax - first item number


	; Now scan the rest of the map for duplicate ClueToken.  If the
	; entry is a duplicate, then add the corresponding item number
	; to the buffer of items.
	clr	dx				; number of items stored
	mov	di, cx				; target ClueToken
repeatScan:
	mov	{word}ss:[bp], ax		; store item number
	add	bp, 2				; next storage location
	inc	dx				; item count

	inc	ax				; next item number
	call	ClueListGetNthItemFromMap
	jc	dontRepeat
	cmp	di, cx
	je	repeatScan
dontRepeat:

	pop	si				; CCLC object
	; Assert sp is set correctly
EC <	pop	bp				; ss:bp - buffPtr	>
EC <	mov	ax, sp							>
EC <	Assert	e	ax, bp						>
	mov_tr	ax, dx				; item count
	movdw	cxdx, sssp			; fptr to buffer
	call	ClueListSelectClueItems

	GetInstanceDataPtrDSDI	CwordClueList_offset
	add	sp, ds:[di].CCLI_numWrapRows	; DeAllocate buffer

done:
	.leave
	ret

unhighlight:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx				; determinate
	call	ClueListSendMessageToSelf
	jmp	done

ClueListHighlightClue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListSelectClueItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will cause the ClueList to select the items passed in
		the buffer. 

CALLED BY:	ClueListHilightClue

PASS:		*ds:si	- CwordClueListClass object
		cx:dx	- fptr to buffer of word-sized items
		ax	- number of items in the buffer

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListSelectClueItems	proc	near
class	CwordClueListClass
	uses	ax,cx,dx,bp
	.enter

;;; Verify argument(s)
	Assert	fptr	cxdx
if ERROR_CHECK
	push	di
	GetInstanceDataPtrDSDI	CwordClueList_offset
	Assert	le	ax, ds:[di].CCLI_numWrapRows
	pop	di
endif
;;;;;;;;

	; Clear all other selections
	push	ax, dx			; numItems, offset bufPtr
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	clr	dx				; determinate
	call	ClueListSendMessageToSelf
	pop	bp, dx			; numItems, offset bufPtr

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MULTIPLE_SELECTIONS
	call	ClueListSendMessageToSelf

	.leave
	ret
ClueListSelectClueItems	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListGetMostRecentSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the most recent selection of a given ClueList.

CALLED BY:	ClueListApplyMsg
PASS:		*ds:si	- CwordClueListClass object

RETURN:		ax	- most recent selection
		CF	- SET if no items are selected

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListGetMostRecentSelection	proc	near
class CwordClueListClass
	uses	bx,cx,dx,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectClueList	dssi
;;;;;;;;

	; Get all of the selections
	sub	sp, 8				; room for 3 item id

	movdw	cxdx, sssp
	mov	bp, 4				; 3 items max
	mov	ax, MSG_GEN_ITEM_GROUP_GET_MULTIPLE_SELECTIONS
	call	ObjCallInstanceNoLock
	Assert	be	ax, 4

	tst	ax				; num items
	stc					; zero item
	jz	fail

	; Assumes the selections are from oldest to newest.  Want the
	; newest item selected.
	mov	bx, ax				; num items
	dec	bx				; offset of id
	shl	bx, 1				; word sized ids
	add	bx, dx
	mov	ax, ss:[bx]			; most recent selection

	add	sp, 8

;;; Verify return value(s)
if ERROR_CHECK
	pushf
	push	di
	GetInstanceDataPtrDSDI	CwordClueList_offset
	Assert	ValidPosInList	ax, ds:[di].CCLI_direction
	pop	di
	popf
endif
;;;;;;;;

	clc					; non-zero items
exit:

	.leave
	ret

fail:
	add	sp, 8
	stc
	jmp	exit

ClueListGetMostRecentSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListSplitTextString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will parse out the first clue line from the given text
		string, and the maximum width of the clue line.

CALLED BY:	ClueListInitializeObject

PASS:		es:si	- ptr to null-terminated string
		^hdi	- GState
		cx	- max width (in pixels)
			- cx > 0 else es:bx is invalid

RETURN:		es:bx	- ptr to the last character of the first clue
			  line (split line) regardless of split or
			  not, but if cx <= 0, then es:bx = es:si.

		CF	- SET if no split (the whole string fits.)

DESTROYED:	nothing
SIDE EFFECTS:

	NOTE:	This version will not support DBCS.

PSEUDO CODE/STRATEGY:

	currWidth = 0;
	if currWidth <= maxWidth {
		do {
			currChar = get next char;
			if currChar == tilde char {
				currChar = get next char;
			}
			currWidth += width of currChar;
		} while (currChar != 0) and (currWidth <= maxWidth);

		scan backward from this character until the first
		space or tilde character

		return the offset of the character before this
		space/tilde 

		CLEAR carry flag;
	}
	else {
		SET carry flag;
	}
	return;


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListSplitTextString	proc	near
	uses	ax,dx,si
	.enter

;;; Verify argument(s)
	Assert	fptr	essi
	Assert	gstate	di
;;;;;;;;

	push	si			; start of string

	clr	bx			; currWidth
	cmp	bx, cx			; currWidth, maxWidth
	jge	noSplit

	; Find the last character that will fit on a clue line, given
	; the clue text.
findLastChar:
	clr	ah
	lodsb	es:			; ax - character
	tst	ax
	jz	clueWidthWideEnough

	cmp	ax, C_ASCII_TILDE
	je	dontAddWidth
	call	GrCharWidth		; dx.ah = width
	add	bx, dx			; currWidth
dontAddWidth:
	cmp	bx, cx			; currWidth, maxWidth
	jle	findLastChar

	sub	si, 2			; last char that'll fit on line
	push	si			; last char that'll fit on line

foundLastChar::
	
	; Find the first space or tilde character previous to the last
	; character that will fit on one line.
	clr	ax
	std				; scanning backward
findSpaceOrTilde:
	lodsb	es:			; ax - character
	cmp	ax, C_SPACE
	je	foundSpaceOrTilde
	cmp	ax, C_ASCII_TILDE
	jne	findSpaceOrTilde
foundSpaceOrTilde:
	cld
	pop	bx			; last char that'll fit on line
	pop	ax			; start of string

	; See if we scanned backward beyond the beginning of the
	; original text string.  If so, then that implies that we
	; didn't encounter any spaces or tilde, ie. the line is just
	; one big word without any breaks in it.
	cmp	si, ax			; end, start of split line
	jle	noHyphenation
	mov	bx, si			; last char before hyphenation
noHyphenation:

	clc

exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
clueWidthWideEnough:
	sub	si, 2			; last char in string
noSplit:
	mov	bx, si			; end of string
	pop	si			; start of string
	stc
	jmp	exit

ClueListSplitTextString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListGetIndentationWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the indented width used by the wrapped lines of a
		clue text.

CALLED BY:	ClueListInitMap

PASS:		^hdi	- GState

RETURN:		cx	- indented width (in pixels)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Get the width of CLUE_TEXT_NUM_PAD_SPACES * C_SPACE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListGetIndentationWidth	proc	near
	uses	ax,dx
	.enter

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	mov	ax, C_SPACE
	call	GrCharWidth
	mov	ax, CLUE_TEXT_NUM_PAD_SPACES

	inc	ax	; To account for space included with hyphenation

	mul	dx
	mov	cx, ax

	.leave
	ret
ClueListGetIndentationWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListIndentString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will pad the beginning of the string with
		CLUE_TEXT_NUM_PAD_SPACES of spaces.

CALLED BY:	ClueListCopyStrToBlock

PASS:		es:di	- beginning of string
		ss:bp	- ClueListGetSplitParams

RETURN:		es:di	- beginning of string after padding spaces

DESTROYED:	nothing
SIDE EFFECTS:	

	NOTE: This version does not support DBCS

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListIndentString	proc	near
	uses	ax,cx
	.enter

;;; Verify argument(s)
	Assert	fptr	esdi
;;;;;;;;

	mov	cx, CLUE_TEXT_NUM_PAD_SPACES
	mov	al, C_SPACE
	rep	stosb

	.leave
	ret
ClueListIndentString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListGetHyphenWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width of a hyphen.

CALLED BY:	ClueListInitMap,

PASS:		^hdi	- GState

RETURN:		cx	- hyphen width
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListGetHyphenWidth	proc	near
	uses	ax,dx
	.enter

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	mov	ax, C_SPACE
	call	GrCharWidth
	mov	cx, dx

	.leave
	ret
ClueListGetHyphenWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListStripTildeAndHyphenate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will remove all the tilde in the string.  And attach a
		hyphen at the end of the string.  If the string ends
		in a tilde (meaning hyphenate there), then will
		replace the tilde with a hyphen, else put the hyphen
		after a space.  Will add a null-terminator.

		If the string is the last split, ie. has a
		null-terminator at es:[bx+1], then will not hyphenate,
		but will strip the tilde.

CALLED BY:	ClueListGetNthSplit
PASS:		es:si	- start of string
		es:bx	- end of string

RETURN:		es:si	- ptr to string stripped of tilde and
			  hyphenated correctly
DESTROYED:	nothing
SIDE EFFECTS:	

	NOTE: This version doesn't support DBCX

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListStripTildeAndHyphenate	proc	near
	uses	ax,bx,cx,di
	.enter

;;; Assert parameter(s)
	Assert	fptr	essi
	Assert	fptr	esbx
	Assert	le	si, bx
;;;;;;;;

	inc	bx			; one character past end of str

	; Add hyphenation and the null-terminator to the end.
	tst	{byte}es:[bx]
	jz	noHyphenation

	cmp	{byte}es:[bx], C_SPACE
	jne	addHyphen
	inc	bx			; hyphenate after space char
addHyphen:
	mov	{byte}es:[bx], C_SPACE
	clr	{byte}es:[bx+1]

noHyphenation:
	mov	di, si			; start of str
	call	LocalStringSize		; cx - number char in string

	; Now remove all tilde prefixes
	mov	al, C_ASCII_TILDE
	repe	scasb
	dec	di
	mov	si, di			; new start of str

	; Now scan the string from the beginning and remove all the
	; tilde and shift the string fragments to form one contiguous
	; string.
	push	si			; start of str

	mov	cl, C_ASCII_TILDE	; delimiter
removeTildeLoop:
	call	ClueListCopyStringsGivenDelimiter
	pushf				; preserve returned CF
	inc	si			; src offset past delimiter
	popf
	jnc	removeTildeLoop		; jmp if didn't reach end of string

doneRemovingTilde::
	pop	si			; start of str	

	.leave
	ret
ClueListStripTildeAndHyphenate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListCopyStringsGivenDelimiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy from src to dst until we reach the given
		delimiter.  Will not copy the delimiter.  

		Will stop when encounter a null character, and will
		copy the null character.

CALLED BY:	ClueListStripTildeAndHyphenate

PASS:		es:si	- src
		es:di	- dst
		cl	- delimiter

RETURN:		si	- offset to delimiter
		di	- offset to char after last char copied
		CF	- SET if reached a null-character

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListCopyStringsGivenDelimiter	proc	near
	.enter

;;; Verify argument(s)
	Assert	fptr	essi
	Assert	fptr	esdi
;;;;;;;;

copyString:
	tst	{byte}es:[si]
	jz	endOfString
	cmp	{byte}es:[si], cl
	je	doneCopying
	movsb	es:
	jmp	copyString
doneCopying:
	clc

exit:

;;; Verify return value(s)
	Assert	fptr	essi
	Assert	fptr	esdi
;;;;;;;;
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
endOfString:
	movsb	es:
	stc				; reached end of string
	jmp	exit

ClueListCopyStringsGivenDelimiter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListCopyStrToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will copy the string pointed to by es:si, and will add
		indentation padding or not depending on cx.

CALLED BY:	ClueListGetNthSplit
PASS:		es:si	- start of null-terminated string to build
		ss:[bp]	- ClueListGetSplitParams
		cx	- TRUE if want prefix indentation

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

	String block indicated by ss:[bp].CLGSP_strHandle has a copy
	of the string pointed to by es:si with/out indentation
	padding. 


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListCopyStrToBlock	proc	near
	uses	ax,bx,cx,si,di,ds,es
	.enter

;;; Verify argument(s)
	Assert	fptr	essi
;;;;;;;;

	segmov	ds, es, bx		; segment of str
	mov	bx, ss:[bp].CLGSP_strHandle
	call	MemLock
	mov	es, ax			; segment of block
	clr	di			; offset of block

	; ds:si	- str ptr, es:di - dst ptr
	cmp	cx, TRUE
	jne	dontIndent
	call	ClueListIndentString
dontIndent:

	pushdw	esdi			; dst ptr
	movdw	esdi, dssi		; es:di - str ptr
	call	LocalStringSize		; cx - num of bytes (NULL not included)
	popdw	esdi			; seg of destination

	; ds:si	- str ptr, es:di - dst ptr
	rep	movsb
	clr	{byte}es:[di]		; null terminate dst string

	call	MemUnlock

	.leave
	ret
ClueListCopyStrToBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListGetItemNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the item number corresponding to the given
		ClueToken and the number of items the clue spanned if
		it's a split clue. 

CALLED BY:	ClueListDisplayItem

PASS:		*ds:si	- ChunkArray (Map)
		cx	- ClueTokenType (target)

		bx	- DirectionType (EC Version)

RETURN:		ax	- item number of the first occurence in the map
		dx	- number of items spanned by the clue, eg. 1
			  if the clue isn't split.

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListGetItemNumber	proc	near
	uses	cx,bp
	.enter

;;; Verify argument(s)
	Assert	ClueListMap	dssi, bx
	Assert	ClueTokenType	cx, bx
;;;;;;;;

	clr	dx				; number of items spanned
	call	ClueListSearchMap		; ax - item number

	push	ax				; 1st item number
	mov	bp, cx				; target clue token

repeatScan:
	inc	dx				; num items spanned
	inc	ax				; next item number
	call	ClueListGetNthItemFromMap
	jc	done
	cmp	cx, bp
	je	repeatScan

done:
	pop	ax				; 1st item number

	.leave
	ret
ClueListGetItemNumber	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListSendMessageToSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that a given item number is visible

CALLED BY:	ClueListDisplayItem

PASS:		*ds:si	- CwordClueListClass object
		ax	- message#
		cx,dx,bp	- passed values

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	9/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListSendMessageToSelf	proc	near
	uses	ax,cx,dx,bp
	.enter

	call	ObjCallInstanceNoLock

	.leave
	ret
ClueListSendMessageToSelf	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClueListRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the clue list width if there isn't a map yet
		or return the current clue list width if there is a map. The
		existence of the map means that the wrappings have
		already been calculated

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordClueListClass
		cx - suggested width
		dx - suggested height

RETURN:		
		cx - desired width
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClueListRecalcSize	method dynamic CwordClueListClass, 
						MSG_VIS_RECALC_SIZE
	.enter

	tst	ds:[di].CCLI_map
	jnz	useLineWidth

	sub	cx, CLUE_TEXT_DELTA		; for borders of list
	mov	ds:[di].CCLI_lineWidth,cx

callSuper:
	mov	di,offset CwordClueListClass
	call	ObjCallSuperNoLock

	.leave
	ret

useLineWidth:
	mov	cx,ds:[di].CCLI_lineWidth
	jmp	callSuper

ClueListRecalcSize		endm




if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestStringRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For debugging routines that manipulates String 

CALLED BY:	ClueListQueryMsg
PASS:		ss:[bp]	- ClueListInitParams

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TestStringRoutines	proc	near
	uses	cx,bx,di,si,es
	.enter	inherit	ClueListInitializeObject

	mov	di, ss:[bp].CLIP_gState
	mov	cx, CLUE_TEXT_WIDTH
	segmov	es, cs, si

	mov	si, offset LessThanStr
	call	ClueListSplitTextString

	mov	si, offset TextString
	call	ClueListSplitTextString

	mov	si, offset TextString2
	call	ClueListSplitTextString

	mov	si, offset TextString3
	call	ClueListSplitTextString

	.leave
	ret
TestStringRoutines	endp

LessThanStr	db	"123 5~6789 ",0
TextString	db	"37. \"To ___ their gold~en eyes\": \"Cymbeline\"",0
TextString2	db	"41. What the Big Bad Wolf did",0
TextString3	db	"53 Rhenish Sym~phony key",0


endif



CwordClueListCode	ends
