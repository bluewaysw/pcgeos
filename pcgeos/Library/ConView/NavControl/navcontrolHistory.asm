COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		navigation controller
FILE:		navcontrolHistory.asm

AUTHOR:		Jonathan Magasin, May 11, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/11/94   	Initial revision


DESCRIPTION:
	History list code for the navigation controller.
		

	$Id: navcontrolHistory.asm,v 1.1 97/04/04 17:49:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentNavControlCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCInitiateHistoryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the history list's interaction

CALLED BY:	MSG_CNC_INITIATE_HISTORY_LIST
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentNavControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCInitiateHistoryList		method dynamic ContentNavControlClass,
					MSG_CNC_INITIATE_HISTORY_LIST
		mov	bx, ds:[di].CNCI_historyBlock
		mov	si, offset ContentNavHistoryGroup
EC <		call ECCheckOD					>
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		GOTO	ObjMessage
CNCInitiateHistoryList		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCFreeHistoryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get rid of the history list array and
		reinitialize the field gobackIndex.

CALLED BY:	MSG_CNC_FREE_HISTORY_LIST
PASS:		*ds:si	= ContentNavControlClass object
		ds:di	= ContentNavControlClass instance data
		es 	= segment of ContentNavControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCFreeHistoryList			method  ContentNavControlClass, 
					MSG_CNC_FREE_HISTORY_LIST

		mov	bx, -1
		call	NCHSetGoBackIndex
		call	NCHFreeHistoryArray
		ret
CNCFreeHistoryList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CNCGetStateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the handle of the history list, 
		and sets CNCI_historyList to 0 (null).
		
CALLED BY:	MSG_CNC_GET_STATE_BLOCK
		Application calls this message from MSG_GEN_PROCESS_
		CLOSE_APPLICATION when app is being exited directly
		to DOS.  CNCI_historyList is needed by the app so
		that it can save the history list to state.
		CNCI_historyList needs to be cleared so that
		we don't come back up with an invalid handle.

PASS:		*ds:si	= ContentNavControlClass object
		ds:di	= ContentNavControlClass instance data
		es 	= segment of ContentNavControlClass
		ax	= message #
RETURN:		cx	= MemHandle of history list (0 if none)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNCGetStateBlock	method dynamic ContentNavControlClass, 
					MSG_CNC_GET_STATE_BLOCK

	clr	cx
	xchg	cx, ds:[di].CNCI_historyList	;cx <- handle of history array

EC <	jcxz	ecDone						>
EC <	xchg	cx, bx						>
EC <	call	ECCheckMemHandleNS				>
EC <	xchg	cx, bx						>
EC < ecDone:							>

	ret
CNCGetStateBlock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGetHistoryListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for history list

CALLED BY:	MSG_HC_GET_HISTORY_LIST_MONIKER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentNavControlClass
		ax - the message

		^lcx:dx - OD of list requesting
		bp - position of list entry

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHContentNavGetHistoryListMoniker	method dynamic ContentNavControlClass,
					MSG_CNC_GET_HISTORY_LIST_MONIKER

	pushdw	cxdx
	push	bp
	;
	; Lock the history array
	;
	call	NCHLockHistoryArray
	;
	; Get the text for the bp-th entry FROM THE END.
	; This is so the most recent history is at the top.
	;
	call	ChunkArrayGetCount		;cx <- # of entries
EC <	tst	cx				;>
EC <	ERROR_Z	CONTENT_NO_HISTORY		;>
	dec	cx
	sub	cx, bp				;cx <- # from end
	;
	; could get stray messages for previous history list
	;
	jns	okay
	pop	bp				;bp <- position of entry
	popdw	bxsi				;^lbx:si <- OD of list
	jmp	done

okay:
	mov	ax, cx				;ax <- entry # to get
	call	ChunkArrayElementToPtr		;ds:di <- ptr to element
EC <	ERROR_C	CONTENT_HISTORY_ILLEGAL_NUMBER	;>
	mov	di, ds:[di].CNHE_context	;*ds:si <- text for history
	mov	cx, ds
	mov	dx, ds:[di]			;cx:dx <- ptr to text
	;
	; Set the entry in the list
	;
	pop	bp				;bp <- position of entry
	popdw	bxsi				;^lbx:si <- OD of list
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	;
	; Unlock the history array
	;
	call	NCHUnlockHistoryArray
	ret
NCHContentNavGetHistoryListMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHContentNavPreviousPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to previous page.

CALLED BY:	MSG_CNC_PREVIOUS_PAGE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentNavControlClass
		ax - the message
RETURN:		none
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	Just tell the ContentGenView to display the previous page in
	the current file. This will result in a NotifyNavContextChange
	notification being sent out, and we update history/goback then.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHContentNavPreviousPage	method dynamic ContentNavControlClass,
						MSG_CNC_PREVIOUS_PAGE

	mov	cx, CNCGPT_PREVIOUS_PAGE
	mov	ax, MSG_CGV_GOTO_PAGE_FOR_NAV
	call	NCUSendToOutputRegs
	ret
NCHContentNavPreviousPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHContentNavNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to next page.

CALLED BY:	MSG_CNC_NEXT_PAGE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentNavControlClass
		ax - the message
RETURN:		none
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	Just tell the ContentGenView to display the next page in
	the current file. This will result in a NotifyNavContextChange
	notification being sent out, and we update history/goback then.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHContentNavNextPage		method dynamic ContentNavControlClass,
						MSG_CNC_NEXT_PAGE

	mov	cx, CNCGPT_NEXT_PAGE
	mov	ax, MSG_CGV_GOTO_PAGE_FOR_NAV
	call	NCUSendToOutputRegs
	ret
NCHContentNavNextPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHContentNavGotoTOC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the TOC (or main page) of the loaded
		content.

CALLED BY:	MSG_CNC_GOTO_TOC
PASS:		*ds:si	= ContentNavControlClass object
		ds:di	= ContentNavControlClass instance data
		ds:bx	= ContentNavControlClass object (same as *ds:si)
		es 	= segment of ContentNavControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax (method)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Just tell the ContentGenView to display the main page (TOC)
	of the file specified by FILENAME_TOC.  This will result in
	a NotifyNavContextChange notification being sent out, and we
	update history/goback then.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHContentNavGotoTOC	method dynamic ContentNavControlClass, 
					MSG_CNC_GOTO_TOC

	mov	ax, MSG_CGV_DISPLAY_TOC
	call	NCUSendToOutputRegs
	ret
NCHContentNavGotoTOC	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHContentNavGotoHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the currently selected history entry

CALLED BY:	MSG_CNC_GOTO_HISTORY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ContentNavControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)
		ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHContentNavGotoHistory		method dynamic ContentNavControlClass,
						MSG_CNC_GOTO_HISTORY
CONTENT_NAV_LOCALS
		.enter

		mov	bx, ds:[di].CNCI_historyBlock
	;
	; Init various useful things
	;
		call	NCUGetToolBlockAndToolFeaturesLocals
		call	NCUGetChildBlockAndFeaturesLocals
	;
	; Get selected history entry's number.
	;
		push	bp, si	
		mov	si, offset ContentNavHistoryList
		mov	di, offset ContentNavHistoryGroup

		push	di
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			;ax <- entry #
EC <		ERROR_C NOTHING_SELECTED_IN_HISTORY_LIST		>
		pop	si
	;
	; Restore focus to text object
	;
		push	ax
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		clr	di
		call	ObjMessage
		pop	ax		

		pop	bp, si
	;
	; Get the entry for the bp-th entry from the end.
	; This is because the most recent history is displayed at the
	; top of the list, but is stored last in the array.
	;
		call	NCHGetHistoryCount		;cx <- # entries
EC <		tst	cx				;>
EC <		ERROR_Z	CONTENT_NO_HISTORY		;>
		dec	cx
EC <		cmp	cx, ax						>
EC <		ERROR_L	CONTENT_HISTORY_ILLEGAL_NUMBER			>
		sub	cx, ax				;cx <- # from end
	;
	; Go to that history entry and delete all others forward
	; from it in the list.
	;
		push	cx
		call	NCHGotoHistory		; tell view to display text
		pop	bx
		call	NCHSetGoBackIndex
		call	NCHDeleteHistory
	;
	; Update GenDynamicList UI
	;
		call	NCHRedrawHistoryList

		.leave
		ret
NCHContentNavGotoHistory		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHContentNavGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go Back to previous help entry we've linked from

vCALLED BY:	MSG_CNC_GO_BACK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	ax, cx, dx
		bx, si, di, ds, es 

PSEUDO CODE/STRATEGY:
	If current goback index is 0, we're displaying the first
	entry in the history list, so can't go back any further.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 3/94		Initial version
	cassie	2/ 8/95		Don't go back if current index is 0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHContentNavGoBack		method dynamic ContentNavControlClass,
						MSG_CNC_GO_BACK
CONTENT_NAV_LOCALS
	.enter

	call	NCUGetToolBlockAndToolFeaturesLocals
	call	NCUGetChildBlockAndFeaturesLocals
	;
	; Get index into history array for context we're
	; switching to.
	;
	mov	cx, 0				;DON'T dec goback index
	call	NCHGetGoBackHistoryIndex	;cx <- history entry #
	jcxz	done				;if already at first entry,
						; can't go back any more
	mov	cx, 1				;DO dec goback index
	call	NCHGetGoBackHistoryIndex	;cx <- history entry #
	;
	; Go to that history element
	;
	call	NCHGotoHistory
done:
	.leave
	ret
NCHContentNavGoBack		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHGotoHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to go to a history entry

CALLED BY:	NCHContentNavGoBack, NCHContentNavGotoHistory
PASS:		*ds:si - controller
		ss:bp - inherited locals
			childBlock - handle of child block
		cx - history # to go to
RETURN:		none
DESTROYED:	ax, bx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHGotoHistory		proc	near
CONTENT_NAV_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>
	;
	; Get the context & file
	;
	call	NCHGetHistoryEntry
	;
	; Display the text
	;
	call	NCHAskViewDisplayText

	.leave
	ret
NCHGotoHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHGetGoBackHistoryIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the history array index corresponding
		to the context we're switching to if the
		user pressed "go back."  ALSO decrements the
		goback array index iff cx<>0.

CALLED BY:	NCHContentNavGoBack,
		NCHRedrawHistoryList
PASS:		*ds:si - navigation controller
		cx     - 0 if should NOT dec goback index
		       - not zero if should dec goback index
RETURN:		cx     - history index
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	It used to be that this wouldn't be called if you were at the
	first page in the history list, because the Go Back tool/feature
	would be disabled.  However, MSG_CNC_GO_BACK can now be called
	from ContentGenView when handling a special link, so may be called
	when already at the first page in the history list. So don't fatal
	error any more, just issue a warning in EC code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/19/94    	Initial version
	cassie	2/8/95		Remove fatal error

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHGetGoBackHistoryIndex	proc	near
	uses	bx
	.enter
EC <	call	AssertIsNavController			>

	call	NCHGetGoBackIndex		;bx <- gobackIndex

EC <	jcxz	ecDone						>
EC <	cmp	bx, 0						>
EC <	WARNING_LE CANNOT_GO_BACK				>
EC <	ecDone:							>

	jcxz	afterDec
	cmp	bx, 0				; play it safe
	je	afterDec
	dec	bx
	call	NCHSetGoBackIndex
	
afterDec:
	mov	cx, bx
	.leave
	ret
NCHGetGoBackHistoryIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHRecordHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the current filename & context for history

CALLED BY:	NCHUpdateHistoryForLink
PASS:		*ds:si - controller
		ss:bp - inherited locals
			filename - name of help file
			context - name of context
			childBlock - handle of child block
			features - features that are on
RETURN:		cx - element number of new history item
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHRecordHistory		proc	near
	uses	di, es
CONTENT_NAV_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>

	push	ds:[LMBH_handle], si
	;
	; Delete a history entry if necessary, to make room for this entry
	;
	call	NCHDeleteHistory
	;
	; Add a new entry
	;
	call	NCHLockHistoryArray
	mov	ax, (size ContentNavHistoryElement)
	call	ChunkArrayAppend		;ds:di <- ptr to new entry
	call	ChunkArrayPtrToElement		;ax <- entry #
	push	ax
	;
	; Allocate chunks for the names and copy them in
	;
	lea	di, ss:filename			;ss:di <- ptr to filename
	call	allocCopy
	mov	dx, ax				;dx <- chunk of filename
	lea	di, ss:context			;ss:di <- ptr to context
	call	allocCopy
	mov	cx, ax				;cx <- chunk of context
	pop	ax				;ax <- entry #

	call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
EC <	ERROR_C	CONTENT_HISTORY_ILLEGAL_NUMBER	;>
	mov	ds:[di].CNHE_filename, dx
	mov	ds:[di].CNHE_context, cx
	mov	cx, ax				;return entry # in cx
	;
	; Unlock the history array
	;
	call	NCHUnlockHistoryArray
	pop	bx, si
	call	MemDerefDS

	.leave
EC <	call	AssertIsNavController			>
	ret

	;
	; allocate a chunk and copy a name into it
	;
	; pass:
	;	ds - seg addr of block
	;	ss:di - ptr to name
	; return:
	;	ax - chunk of name
	;
allocCopy:
	push	si, cx
	segmov	es, ss				;es:di <- ptr to name
	call	LocalStringSize			;cx <- size of string (w/o null)
	LocalNextChar	escx			;cx <- advance 1 char
						;for null
	mov	al, mask OCF_DIRTY		;JM6/7: set the ObjChunkFlags
	call	LMemAlloc
	segxchg	ds, es
	mov	si, di				;ds:si <- ptr to name
	mov	di, ax				;*es:di <- new chunk
	mov	di, es:[di]			;es:di <- ptr to chunk
	rep	movsb				;copy cx bytes
	pop	si, cx
	segmov	ds, es				;ds <- (new) seg addr of array
EC <	push	ax				;>
EC <	mov	ax, 0xa000			;>
EC <	mov	es, ax				;>
EC <	pop	ax				;>
	retn
NCHRecordHistory		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHDeleteHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all entries after go back index if the go back
		index is not at the top. Also delete the oldest history 
		entry (first one in array) if history array is full.

CALLED BY:	(INTERNAL) NCHRecordHistory, NCHGotoHistory
PASS:		*ds:si - controller
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY::
	name	date		description
	----	----		-----------
	gene	12/14/92	initial version
	lester	10/31/94  	delete oldest entry if we need to make room

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHDeleteHistory		proc	near
		uses	ax, bx, cx, di
		.enter

EC <		call	AssertIsNavController				>
		push	ds:[LMBH_handle], si

	; Check if the go back index is somewhere down the history
	; list.  If so, we want to delete all entries after that, so
	; that it is the most recent entry.
		
		call	NCHGetGoBackIndex		;bx <- gobackIndex

		call	NCHLockHistoryArray
		call	ChunkArrayGetCount		;cx <- # entries
		jcxz	done				;no entries? nothing
							; to delete
		dec	cx				;count from 0
		mov	dx, cx				;save count in dx
		cmp	bx, cx				;are we at most recent?
		je	noDelete			;yes, don't delete any
		sub	cx, bx				;cx <- # to delete
EC <		ERROR_C -1				;error if bx > cx >

delete:		
		mov	ax, dx				;element # to delete
		call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
EC <		ERROR_C	CONTENT_HISTORY_ILLEGAL_NUMBER	;>
	;
	; delete any associated data
	;
		mov	ax, ds:[di].CNHE_filename
		call	deleteChunk
		mov	ax, ds:[di].CNHE_context
		call	deleteChunk
	;
	; delete the entry itself
	;
		call	ChunkArrayDelete
		dec	dx
		loop	delete
		
done:
		call	NCHUnlockHistoryArray
		pop	bx, si
		call	MemDerefDS
EC <		call	AssertIsNavController			>

		.leave
		ret

noDelete:
	;
	; We didn't delete any entries, so the list might be full.
	; Check if we need to make room for one more.
	;	cx = dx = # entries in list - 1 
	;
		cmp	cx, MAXIMUM_HISTORY_ENTRIES-1	;is list full?
		jb	done				;nope, we're done
		mov	cx, 1				;only 1x through loop
		mov	dx, 0				;delete oldest entry
		jmp	delete
		
deleteChunk:
		tst	ax				;any chunk?
		jz	skipDelete			;branch if no chunk
		call	LMemFree
skipDelete:
		retn
NCHDeleteHistory		endp


comment @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHInitList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the history popup list

CALLED BY:	
PASS:		*ds:si - controller
		cx - # of items in history list
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	name	date		description
	----	----		-----------
	gene	12/ 1/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHInitList		proc	near
		uses	cx, si
		class	ContentNavControlClass
		.enter	
EC <		call	AssertIsNavController			>

	;
	; Keep this list from getting too large.
	;
		cmp	cx, MAXIMUM_HISTORY_ENTRIES	;too many entries?
		jbe	lengthOK
		mov	cx, MAXIMUM_HISTORY_ENTRIES	;cx <- set to maximum
lengthOK:
		mov	di, ds:[si]
		add	di, ds:[di].ContentNavControl_offset
		mov	bx, ds:[di].CNCI_historyBlock
		mov	si, offset ContentNavHistoryList	;^lbx:si<-list
EC <		call	ECCheckOD					>
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	NCUObjMessageCheckAndSend
	
		.leave
		ret
NCHInitList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHGetHistoryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the nth history entry

CALLED BY:	utility
PASS:		*ds:si - controller
		ss:bp - inherited locals
		cx - # of history entry to get
RETURN:		ss:bp - inherited locals
			filename - name of help file
			context - name of context
DESTROYED:	ax, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	name	date		description
	----	----		-----------
	gene	10/26/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHGetHistoryEntry		proc	near
	uses	ds, si, cx
CONTENT_NAV_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>

	call	NCHLockHistoryArray

	mov	ax, cx				;ax <- history #
	call	ChunkArrayElementToPtr		;ds:di <- helphistoryelement
EC <	ERROR_C	CONTENT_HISTORY_ILLEGAL_NUMBER	;>
	mov	si, di				;ds:si <- ptr to element

	segmov	es, ss, ax

	lea	di, ss:filename			;es:di <- ptr to dest
	mov	cx, ds:[si].CNHE_filename	;cx <- chunk of name
	call	getHistoryName
	lea	di, ss:context			;es:di <- ptr to dest
	mov	cx, ds:[si].CNHE_context	;cx <- chunk of name
	call	getHistoryName

	call	NCHUnlockHistoryArray

	.leave
EC <	call	AssertIsNavController			>
	ret

	;
	; pass:
	;	*ds:cx - name to copy
	;	es:di - dest buffer
	;
getHistoryName:
	push	si
	mov	si, cx				;*ds:si <- name
	mov	si, ds:[si]			;ds:si <- ptr to name
	ChunkSizePtr ds, si, cx			;cx <- # of bytes
	rep	movsb				;copy me 
	pop	si
	retn
NCHGetHistoryEntry		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHLockHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock the history array, allocating it if necessary

CALLED by:	
PASS:		*ds:si - controller
RETURN:		*ds:si - history array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	name	date		description
	----	----		-----------
	gene	10/25/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHLockHistoryArray		proc	near
	uses	ax, bx, cx, dx
	class	ContentNavControlClass
	.enter
EC <	call	AssertIsNavController			>

	;
	; see if there is already an array
	;
	mov	si, ds:[si]
	add	si, ds:[si].ContentNavControl_offset
	mov	bx, ds:[si].CNCI_historyList	;bx <- handle of history array
	tst	bx				;any history array?
	jnz	gotHistory			;branch if array exists
	;
	; allocate a block for the history array
	;
	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, 0				;default header size
	call	MemAllocLMem			;^hbx <- history list block
	mov	ds:[si].CNCI_historyList, bx
	;
	; create the history array
	;
	call	MemLock
	mov	ds, ax				;ds <- seg addr of block
	mov	bx, (size ContentNavHistoryElement)
	clr	ax, cx, si			;al <- no flags
						;cx <- no extra space
						;si <- alloc chunk
	call	ChunkArrayCreate
EC <	cmp	si, CONTENT_NAV_HISTORY_CHUNK	;1st handle?>
EC <	ERROR_NE CONTENT_HISTORY_BUFFER_NOT_EMPTY	;>
	jmp	done
		
gotHistory:
EC <	call	ECCheckMemHandleNS			>
	call	MemLock
	mov	ds, ax
	mov	si, CONTENT_NAV_HISTORY_CHUNK	;si <- 1st handle
done:
	.leave
	ret
NCHLockHistoryArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHUnlockHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlock the history array

CALLED BY:	
PASS:		ds - seg addr of history array
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	name	date		description
	----	----		-----------
	gene	10/25/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHUnlockHistoryArray		proc	near
	uses	bx
	.enter

	mov	bx, ds:LMBH_handle
	call	MemUnlock

	.leave
	ret
NCHUnlockHistoryArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHFreeHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free the history array, if any

CALLED BY:	
PASS:		*ds:si - controller
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	name	date		description
	----	----		-----------
	gene	10/25/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHFreeHistoryArray		proc	near
	uses	di
	class	ContentNavControlClass
	.enter
EC <	call	AssertIsNavController			>

	mov	di, ds:[si]
	add	di, ds:[di].ContentNavControl_offset
	clr	bx
	xchg	bx, ds:[di].CNCI_historyList	;bx <- handle of history array
	tst	bx				;any history array?
	jz	noFree				;branch if no history
						;array
EC <	call	ECCheckMemHandleNS				>
	call	MemFree
noFree:

	.leave
EC <	call	AssertIsNavController			>
	ret
NCHFreeHistoryArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHGetHistoryCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the number of items in the history array

CALLED BY:	utility
PASS:		*ds:si - controller
RETURN:		cx - # of items in history
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY::
	name	date		description
	----	----		-----------
	gene	10/26/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHGetHistoryCount		proc	near
	uses	bx
	.enter
EC <	call	AssertIsNavController			>
	push	ds:[LMBH_handle], si

	call	NCHLockHistoryArray		;*ds:si <- history array

	call	ChunkArrayGetCount

	call	NCHUnlockHistoryArray

	pop	bx, si
	call	MemDerefDS

	.leave
	ret
NCHGetHistoryCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHSetGoBackIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets CNCI_gobackIndex to bx

CALLED BY:	NCHRecordGoBack
PASS:		*ds:si	- nav controller
		bx	- index
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHSetGoBackIndex	proc	near
	uses	si
	class	ContentNavControlClass
	.enter
EC <	call	AssertIsNavController			>

	mov	si, ds:[si]
	add	si, ds:[si].ContentNavControl_offset
	mov	ds:[si].CNCI_gobackIndex, bx

	.leave
	ret
NCHSetGoBackIndex	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHGetGoBackIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets CNCI_gobackIndex into bx

CALLED BY:	
PASS:		*ds:si	- nav controller
RETURN:		bx	- index
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHGetGoBackIndex	proc	near
	class	ContentNavControlClass
EC <	call	AssertIsNavController			>

	mov	bx, ds:[si]
	add	bx, ds:[bx].ContentNavControl_offset
	mov	bx, ds:[bx].CNCI_gobackIndex
	ret
NCHGetGoBackIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHUpdateHistoryForLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to update history after a link

CALLED BY:	NCHContentNavGotoHistory, CNCGenControlUpdateUI
PASS:		*ds:si - controller
		ss:bp - inherited locals
			filename - filename we're linking to
			context - context name we're linking to
			childBlock - handle of child block
			features - features that are on
RETURN:		none
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY::
	name	date		description
	----	----		-----------
	gene	11/ 4/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHUpdateHistoryForLink		proc	near
	uses	ax
CONTENT_NAV_LOCALS
	.enter	inherit
EC <	call	AssertIsNavController			>

	call	NCHRecordHistory		;cx <- # of new history entry
	mov	bx, cx				;bx <- history entry
	call	NCHSetGoBackIndex		;set CNCI_gobackIndex

	.leave
	ret
NCHUpdateHistoryForLink		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHAskViewDisplayText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends message to ContentGenView
		(which is the output of the controller)
		to display some text.  This routine is
		called when the user clicks on a history
		list entry or goes back.

		Note:  In these cases, since the nav knows
		       what the ContentGenView will display
		       next, it (the nav) doesn't need to be 
		       told in its (the nav's) notification
		       what context is being linked to.  It
		       only needs to know how to update the
		       previous and next triggers.

CALLED BY:	NCHContentNavGotoHistory,
		NCHGotoHistory
PASS:		ss:bp - CONTENT_NAV_LOCALS
		*ds:si - NavControl
RETURN:		nothing
DESTROYED:	ax, bx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHAskViewDisplayText	proc	near
CONTENT_NAV_LOCALS
	.enter inherit
EC <	call	AssertIsNavController			>
	;
	; First step is to set up stack params.  Will not touch CTR_pathname,
	; as the pathname will not change when a link is followed.
	;
	mov	bx, bp				; save local stack frame ptr
	sub	sp, (size ContentTextRequest)
	mov	bp, sp
	;
	;
	push	ds, si
	segmov	es, ss, ax
	mov	ds, ax
	lea	di, ss:[bp].CTR_filename
	xchg	bx, bp
	lea	si, ss:filename
	xchg	bx, bp
	call	NCUStringCopy			; copy filename

	lea	di, ss:[bp].CTR_context
	xchg	bx, bp
	lea	si, ss:context
	xchg	bx, bp
	call	NCUStringCopy			; copy context
	pop	ds, si		
	;
	; Now send the message.
	;
	clr	ss:[bp].CTR_flags
	mov	dx, (size ContentTextRequest)
	mov	ax, MSG_CGV_DISPLAY_TEXT
	call	NCUSendToOutputStack
	add	sp, (size ContentTextRequest)
	mov_tr	bp, bx

	.leave
EC <	call	AssertIsNavController			>
	ret
NCHAskViewDisplayText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHRedrawHistoryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redisplays the history list.

CALLED BY:	ContentNavReceiveNotification
PASS:		*ds:si	- nav controller
		ss:bp	- inherit locals
			    childBlock
			    toolBlock
			    features
			    toolFeatures
RETURN:		nothing
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHRedrawHistoryList	proc	near
	uses	ax
CONTENT_NAV_LOCALS
	.enter inherit
EC <	call	AssertIsNavController			>
	
		call	NCHGetHistoryCount		;cx=# entries
		call	NCHInitList
	;
	; Get the go back index - we want to select that item in the list
	;
		mov	dx, cx
		clr	cx				;Don't dec goback index
		call	NCHGetGoBackHistoryIndex	;cx <- history entry #
	;
	; calculate the list entry number from the history entry number
	;
		cmp	cx, -1				;no go back index?
		je	done				;don't select anything
		xchg	cx, dx
		sub	cx, dx
		dec	cx				;list entry to select
	;
	; Set the lists' selection.
	;
		call	NCHSetHistoryListSelection
done:
	.leave
	ret
NCHRedrawHistoryList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NCHSetHistoryListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection in the history list(s)

CALLED BY:	(INTERNAL) NCHRedrawHistoryList
PASS:		*ds:si - NavControl
		cx - list entry to select
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NCHSetHistoryListSelection		proc	near
		uses	si
		class	ContentNavControlClass
		.enter 
EC <		call	AssertIsNavController			>
	
		mov	di, ds:[si]
		add	di, ds:[di].ContentNavControl_offset
		mov	bx, ds:[di].CNCI_historyBlock
		mov	si, offset ContentNavHistoryList	;^lbx:si<-list
EC <		call	ECCheckOD					>
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			;dx <- not indeterminate
		call	NCUObjMessageCheckAndSend

		.leave
		ret
NCHSetHistoryListSelection		endp

ContentNavControlCode	ends
