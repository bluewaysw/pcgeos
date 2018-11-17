COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpHistory.asm

AUTHOR:		Gene Anderson, Oct 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/25/92	Initial revision


DESCRIPTION:
	Routines for managing the history of where the user has been

	$Id: helpHistory.asm,v 1.1 97/04/07 11:47:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGetHistoryListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for history list

CALLED BY:	MSG_HC_GET_HISTORY_LIST_MONIKER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
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
HelpControlGetHistoryListMoniker		method dynamic HelpControlClass,
						MSG_HC_GET_HISTORY_LIST_MONIKER
	pushdw	cxdx
	push	bp
	;
	; Lock the history array
	;
	call	HHLockHistoryArray
	;
	; Get the text for the bp-th entry FROM THE END.
	; This is so the most recent history is at the top.
	;
	call	ChunkArrayGetCount		;cx <- # of entries
EC <	tst	cx				;>
EC <	ERROR_Z	HELP_NO_HISTORY			;>
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
	mov	di, ds:[di].HHE_title		;*ds:si <- text for history
	mov	cx, ds
	mov	dx, ds:[di]			;cx:dx <- ptr to text
	;
	; Set the entry in the list
	;
	pop	bp				;bp <- position of entry
	popdw	bxsi				;^lbx:si <- OD of list
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	;
	; Unlock the history array
	;
	call	HHUnlockHistoryArray
	ret
HelpControlGetHistoryListMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGotoHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to a particular history entry

CALLED BY:	MSG_HC_GOTO_HISTORY
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		cx - position of list entry to go

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGotoHistory		method dynamic HelpControlClass,
						MSG_HC_GOTO_HISTORY

HELP_LOCALS

	.enter

	;
	; Init various useful things
	;
	call	HUGetChildBlockAndFeaturesLocals
	;
	; Get the for the bp-th entry from the end.
	; This is because the most recent history is displayed at the
	; top of the list, but is stored last in the array.
	;
	mov	ax, cx				;ax <- entry to get
	call	HHGetHistoryCount		;cx <- # entries
EC <	tst	cx				;>
EC <	ERROR_Z	HELP_NO_HISTORY			;>
	dec	cx
	sub	cx, ax				;cx <- # from end
	;
	; Get the context & file
	;
	call	HHGetHistoryEntry
	;
	; Display the text
	;
	call	HLDisplayText
EC <	ERROR_C HELP_RECORDED_HELP_MISSING	;>
	;
	; Update various things for history
	;
	call	HHUpdateHistoryForLink
done::
	.leave
	ret
HelpControlGotoHistory		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGetCurrentContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get current context

CALLED BY:	MSG_HELP_CONTROL_GET_CURRENT_CONTEXT
PASS:		*ds:si	= HelpControlClass object
		ds:di	= HelpControlClass instance data
		ds:bx	= HelpControlClass object (same as *ds:si)
		es 	= segment of HelpControlClass
		ax	= message #
		cx:dx	= GetCurrentContextParams
RETURN:		GetCurrentContextParams filled
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGetCurrentContext	method dynamic HelpControlClass, 
					MSG_HELP_CONTROL_GET_CURRENT_CONTEXT
HELP_LOCALS
	.enter
	;
	; Init, in case no history
	;
	movdw	esdi, cxdx		; es:di = GetCurrentContextParams
	mov	{word} es:[di].GCCP_fileName, 0
	mov	{word} es:[di].GCCP_contextName, 0
	;
	; Get the handle of the child block and the features for later
	;
	call	HUGetChildBlockAndFeaturesLocals
	;
	; get current element (i.e. current context)
	;
	call	HHGetHistoryCurrent		;cx <- current element #
	jcxz	done				;if none, we're done
	dec	cx
	call	HHGetHistoryEntry
	;
	; copy for return
	;	es:di = GetCurrentContextParams
	;
	segmov	ds, ss
	lea	si, context
	lea	di, es:[di].GCCP_contextName
	mov	cx, size GCCP_contextName
	rep movsb
	lea	si, filename
.assert (offset GCCP_fileName eq \
			(offset GCCP_contextName + size GCCP_contextName))
	mov	cx, size GCCP_fileName
	rep movsb
done:
	.leave
	ret
HelpControlGetCurrentContext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGetCurrentTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current title from the help history.

CALLED BY:	MSG_HELP_CONTROL_GET_CURRENT_TITLE
PASS:		*ds:si	= HelpControlClass object
		ds:di	= HelpControlClass instance data
		ds:bx	= HelpControlClass object (same as *ds:si)
		es 	= segment of HelpControlClass
		ax	= message #
		^hcx	= block in which to allocate text chunk
RETURN:		^lcx:dx	= title text (cx = 0 if no help history)
		
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGetCurrentTitle	method dynamic HelpControlClass, 
					MSG_HELP_CONTROL_GET_CURRENT_TITLE
	uses	bx,cx,ds,si,es,di
	.enter
	mov	bx, cx				;^hbx = passed block

	call	HHLockHistoryArray		;*ds:si = history array

	clr	dx				;assume no history
	mov	cx, ds:[HHBH_current]		;cx = current entry # + 1
	jcxz	unlockAndExit

	dec	cx				;cx = actual entry #
	call	ChunkArrayElementToPtr		;ds:di = HelpHistoryElement
	mov	di, ds:[di].HHE_title		;*ds:di = title
	mov	si, ds:[di]			;ds:si = title
	segmov	es, ds				;es:si = title
	ChunkSizePtr	es, si, cx		;cx = size of title
	inc	cx				; include null
DBCS <	inc	cx							>
	;
	; Alloc a chunk in the passed block to hold the title text
	;
	call	ObjLockObjBlock
	mov	ds, ax
	mov	al, mask OCF_DIRTY
	call	LMemAlloc			;*ds:ax = new chunk
	mov	dx, ax				;dx = lptr new chunk
	mov	di, ax
	mov	di, ds:[di]			;ds:di = new chunk
	segxchg	ds, es				;es:di = new chunk
						;ds:si = title
	rep	movsb
	call	MemUnlock

unlockAndExit:
	call	HHUnlockHistoryArray	

	.leave
	ret
HelpControlGetCurrentTitle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHGotoHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to go to a history entry

CALLED BY:	HelpControlGotoHistory(), HelpControlGoBack()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			childBlock - handle of child block
		cx - history # to go to
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHGotoHistory		proc	near
HELP_LOCALS
	.enter	inherit

	;
	; Get the context & file
	;
	call	HHGetHistoryEntry
	;
	; Display the text
	;
	call	HLDisplayText
EC <	ERROR_C HELP_RECORDED_HELP_MISSING	;>
	;
	; Record the "new" history entry
	;
	call	HHRecordHistory
done::
	.leave
	ret
HHGotoHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go Back to previous help entry we've linked from

CALLED BY:	MSG_HC_GO_BACK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGoBack		method dynamic HelpControlClass,
						MSG_HC_GO_BACK
HELP_LOCALS

	.enter

	call	HUGetChildBlockAndFeaturesLocals
	;
	; Get and delete the last go back entry
	;
	call	HHGetDeleteGoBack		;cx <- history entry #
	;
	; If no go back entries left, disable "Go Back"
	;
	tst	ax				;any entries left?
	jnz	noDisable			;branch if still entries
	mov	bx, ss:childBlock
	mov	di, offset HelpGoBackTrigger	;^lbx:di <- OD of feature
	call	HUDisableFeature
noDisable:
	;
	; Go to that history element
	;
	call	HHGotoHistory

	.leave
	ret
HelpControlGoBack		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHRecordHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the current filename & context for history

CALLED BY:	HelpControlFollowLink()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			filename - name of help file
			context - name of context
			childBlock - handle of child block
			features - features that are on
RETURN:		cx - # of items in history
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHRecordHistory		proc	near
	uses	di, es
HELP_LOCALS
	.enter	inherit

	pushdw	dssi
	;
	; Get the type of the text, if required
	;
	mov	dl, VTCT_TEXT			;dl <- assume default type
	test	ss:features, mask HPCF_FIRST_AID
	jz	skipGetType
	call	HTGetTypeForHistory
skipGetType:
	push	dx				;save text type
	;
	; Lock the history array
	;
	call	HHLockHistoryArray
	;
	; Check for a duplicate entry. If one is found, then make
	; sure we select the duplicate entry. Also, remember that
	; the list as displayed to the user is exactly opposite the
	; order in which the history elements are stored.
	;
	call	HHCheckForDuplicateHistoryEntry
	jnc	addEntry
	call	HHUnlockHistoryArray
	pop	ax				;clear the stack
	popdw	dssi				;restore optr
	mov	cx, dx
	call	HHSetHistoryCurrent
	call	HHGetHistoryCount		;cx <- # of elements
	sub	dx, cx
	neg	dx				;dx <- list entry to select

	test	ss:features, mask HPCF_HISTORY
	jnz	setSelection
	jmp	noHistory
	;
	; Add a new entry
	;
addEntry:
	mov	ax, (size HelpHistoryElement)
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
	;
	; Get the first line of text to use for history, if required
	;
	clr	bx				;bx <- assume no history
	test	ss:features, mask HPCF_HISTORY
	jz	skipGetHistory
	call	HTGetTextForHistory
skipGetHistory:


	call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
	mov	ds:[di].HHE_filename, dx
	mov	ds:[di].HHE_context, cx
	mov	ds:[di].HHE_title, bx
	pop	dx
	mov	ds:[di].HHE_type, dl
	;
	; Get the (new) number of items in history
	;
	call	ChunkArrayGetCount		;cx <- # of items
	;
	; Unlock the history array
	;
	call	HHUnlockHistoryArray
	popdw	dssi
	call	HHSetHistoryCurrent
	;
	; If there is any "History" list, update it
	;
	test	ss:features, mask HPCF_HISTORY
	jz	noHistory
	;
	; Set the item # of items in our history list
	;
	call	HHInitList
	clr	dx				;select the 1st list item
	;
	; Set the selection to the first item
	;
setSelection:
	push	cx, si
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, dx				;cx <- list item to select
	clr	dx				;dx <- not indeterminate
	mov	bx, ss:childBlock
	mov	si, offset HelpHistoryList	;^lbx:si <- OD of list
	call	HUObjMessageSend
	pop	cx, si
noHistory:

	.leave
	ret

	;
	; allocate a chunk and copy a name into it
	;
	; PASS:
	;	ds - seg addr of block
	;	ss:di - ptr to name
	; RETURN:
	;	ax - chunk of name
	;
allocCopy:
	push	si, cx
	segmov	es, ss				;es:di <- ptr to name
	call	LocalStringSize			;cx <- size of string (w/o NULL)
	LocalNextChar	escx			;cx <- advance 1 char for NULL
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
HHRecordHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHInitList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the history popup list

CALLED BY:	HHRecordHistory(), HelpControlUpdateUI()
PASS:		*ds:si - controller
		ss:bp - inherit locals
		cx - # of items in history list
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHInitList		proc	near
	uses	cx, si
HELP_LOCALS
	.enter	inherit

	test	ss:features, mask HPCF_HISTORY
	jz	noHistory
	;
	; To keep this list from getting too large, we max out at
	;
	cmp	cx, MAXIMUM_HISTORY_ENTRIES	;too many entries?
	jbe	lengthOK
	mov	cx, MAXIMUM_HISTORY_ENTRIES	;cx <- set to maximum
lengthOK:
	mov	bx, ss:childBlock
	mov	si, offset HelpHistoryList	;^lbx:si <- OD of list
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	HUObjMessageSend
noHistory:

	.leave
	ret
HHInitList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHGetHistoryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Nth history command

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ss:bp - inherited locals
		cx - # of history command to get
RETURN:		ss:bp - inherited locals
			filename - name of help file
			context - name of context
			nameData.VTND_contextType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHGetHistoryEntry		proc	near
	uses	ds, si, es, di, ax, cx
HELP_LOCALS
	.enter	inherit

	call	HHLockHistoryArray

	mov	ax, cx				;ax <- history #
	call	ChunkArrayElementToPtr		;ds:di <- ptr HelpHistoryElement
EC <	ERROR_C	HELP_HISTORY_ILLEGAL_NUMBER	;>
	mov	si, di				;ds:si <- ptr to element

	segmov	es, ss

	lea	di, ss:filename			;es:di <- ptr to dest
	mov	cx, ds:[si].HHE_filename	;cx <- chunk of name
	call	getHistoryName
	lea	di, ss:context			;es:di <- ptr to dest
	mov	cx, ds:[si].HHE_context		;cx <- chunk of name
	call	getHistoryName
	mov	al, ds:[si].HHE_type		;cl <- VisTextContextType
	mov	ss:nameData.HFND_text.VTND_contextType, al

	call	HHUnlockHistoryArray

	.leave
	ret

	;
	; PASS:
	;	*ds:cx - name to copy
	;	es:di - dest buffer
	;
getHistoryName:
	push	si
	mov	si, cx				;*ds:si <- name
	mov	si, ds:[si]			;ds:si <- ptr to name
	ChunkSizePtr ds, si, cx			;cx <- # of bytes
	rep	movsb				;copy me jesus
	pop	si
	retn
HHGetHistoryEntry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHSameFile?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current file (ie. the last item in history)
		is the same as the file we're about to open

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ss:bp - inherited locals
			filename - name of help file
RETURN:		z flag - set (jz) if same file
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHSameFile?		proc	near
	uses	cx, dx, ds, si, es, di
HELP_LOCALS
	.enter	inherit

	;
	; See if we've got a file open
	;
	call	HFGetFile
	tst	bx				;any file?
	jz	noFile				;branch if no file open
	;
	; Lock the history array
	;
	call	HHLockHistoryArray
	;
	; Get a pointer to the last element, if any
	;
	mov	cx, ds:[HHBH_current]		;cx = current entry # + 1
	jcxz	noHistory			;branch if no current entry
	mov	ax, cx
	dec	ax				;ax <- index of last entry
	call	ChunkArrayElementToPtr
	;
	; See if it's the same filename
	;
	mov	si, ds:[di].HHE_filename	;si <- chunk of filename
	mov	si, ds:[si]			;ds:si <- ptr to filename
	segmov	es, ss
	lea	di, ss:filename			;es:di <- ptr to name to check
	clr	cx				;cx <- NULL-terminated
	call	LocalCmpStrings			;set Z flag if equal
doneClose:
	call	HHUnlockHistoryArray
quit:

	.leave
	ret

	;
	; There is no file open, so fail the comparison
	;
noFile:
	inc	bx				;clear Z flag (bx == 0)
	jmp	quit

	;
	; There are no history entries, so there is no file to compare
	;
noHistory:
	inc	cx				;clear Z flag (cx == 0)
	jmp	doneClose
HHSameFile?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHLockHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the history array, allocating it if necessary

CALLED BY:	HHRecordHistory()
PASS:		*ds:si - controller
RETURN:		*ds:si - history array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHLockHistoryArray		proc	near
	uses	ax, bx, cx, dx
	class	HelpControlClass
	.enter

	;
	; See if there is already an array
	;
	mov	si, ds:[si]
	add	si, ds:[si].HelpControl_offset
	mov	bx, ds:[si].HCI_historyBuf	;bx <- handle of history array
	tst	bx				;any history array?
	jnz	gotHistory			;branch if array exists
	;
	; Allocate a block for the history array
	;
	mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
	mov	cx, size HelpHistoryBlockHeader	;cx <- header size
	call	MemAllocLMem
	mov	ds:[si].HCI_historyBuf, bx
	;
	; Create the history array
	;
	call	MemLock
	mov	ds, ax				;ds <- seg addr of block
	clr	ds:[HHBH_current]
	mov	bx, (size HelpHistoryElement)	;bx <- element size
	clr	cx				;cx <- no extra space
	clr	si				;si <- alloc chunk
	call	ChunkArrayCreate
EC <	cmp	si, HELP_HISTORY_CHUNK		;1st handle?>
EC <	ERROR_NE HELP_HISTORY_BUFFER_NOT_EMPTY	;>
	push	si				;save history handle
	mov	bx, (size HelpGoBackElement)	;bx <- element size
	clr	cx				;cx <- no extra space
	clr	si				;si <- alloc chunk
	call	ChunkArrayCreate
EC <	cmp	si, HELP_GO_BACK_CHUNK		;2nd handle?>
EC <	ERROR_NE HELP_HISTORY_BUFFER_NOT_EMPTY	;>
	pop	si
	jmp	afterLock

gotHistory:
	call	MemLock
	mov	ds, ax
	mov	si, HELP_HISTORY_CHUNK		;si <- 1st handle
afterLock:

	.leave
	ret
HHLockHistoryArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHUnlockHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the history array

CALLED BY:	HHRecordHistory()
PASS:		ds - seg addr of history array
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHUnlockHistoryArray		proc	near
	uses	bx
	.enter

	mov	bx, ds:LMBH_handle
	call	MemUnlock

	.leave
	ret
HHUnlockHistoryArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHFreeHistoryArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the history array, if any

CALLED BY:	HelpControlExit()
PASS:		*ds:si - controller
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHFreeHistoryArray		proc	near
	uses	di
	class	HelpControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	clr	bx
	xchg	bx, ds:[di].HCI_historyBuf	;bx <- handle of history array
	tst	bx				;any history array?
	jz	noFree				;branch if no history array
	call	MemFree
noFree:

	.leave
	ret
HHFreeHistoryArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHGetHistoryCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of items in the history array

CALLED BY:	UTILITY
PASS:		*ds:si - controller
RETURN:		cx - # of items in history
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: This simply locks the history array, does a ChunkArrayGetCount(),
	and unlocks the history array.  If you have the history array locked,
	you can simply call ChunkArrayGetCount() directly.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHGetHistoryCount		proc	near
	uses	ds, si
	.enter

	call	HHLockHistoryArray		;*ds:si <- history array

	call	ChunkArrayGetCount

	call	HHUnlockHistoryArray

	.leave
	ret
HHGetHistoryCount		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHRecordGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record information for going back

CALLED BY:	HHRecordHistory()
PASS:		*ds:si - controller
		cx - entry # of history
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	ASSUMES: assumes history & go back arrays are in the same block
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHRecordGoBack		proc	near
	uses	ds, si, di
	.enter

	call	HHLockHistoryArray
	mov	si, HELP_GO_BACK_CHUNK		;*ds:si <- go back array

	mov	ax, (size HelpGoBackElement)	;ax <- element size
	call	ChunkArrayAppend
	mov	ds:[di].HGBE_history, cx	;set history #

	call	HHUnlockHistoryArray

	.leave
	ret
HHRecordGoBack		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHGetDeleteGoBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get and delete the last go back entry

CALLED BY:	HelpGoBack()
PASS:		*ds:si - controller
RETURN:		cx - history # of go back entry
		ax - # of entries left in go back list
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHGetDeleteGoBack		proc	near
	uses	ds, si, di
	.enter

	call	HHLockHistoryArray
	mov	si, HELP_GO_BACK_CHUNK		;*ds:si <- go back array

	call	ChunkArrayGetCount		;cx <- # of go back entries
EC <	tst	cx				;>
EC <	ERROR_Z HELP_NO_HISTORY			;>
	mov	ax, cx
	dec	ax				;ax <- # of last entry
	call	ChunkArrayElementToPtr		;ds:di <- ptr to last entry
	mov	cx, ds:[di].HGBE_history	;cx <- corresponding history
	call	ChunkArrayDelete		;delete the last entry

	call	HHUnlockHistoryArray

	.leave
	ret
HHGetDeleteGoBack		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHDeleteHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get and delete the last history entry

CALLED BY:	HelpControlChooseFirstAid()
PASS:		*ds:si - controller
		cx - history entry to get
RETURN:		cx - # of entries left in history
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHDeleteHistory		proc	near
	uses	ax, ds, si, di
	.enter

	call	HHLockHistoryArray

	mov	ax, cx				;ax <- entry # to get
	call	ChunkArrayElementToPtr		;ds:di <- ptr to entry
	;
	; Delete any associated data
	;
	mov	ax, ds:[di].HHE_filename
	call	deleteChunk
	mov	ax, ds:[di].HHE_context
	call	deleteChunk
	mov	ax, ds:[di].HHE_title
	call	deleteChunk
	;
	; Delete the entry itself
	;
	call	ChunkArrayDelete		;delete the last entry
	;
	; Get the number of entries left
	;
	call	ChunkArrayGetCount
	mov	ax, cx				;ax <- # of entries left

	call	HHUnlockHistoryArray

	.leave
	ret

deleteChunk:
	tst	ax				;any chunk?
	jz	skipDelete			;branch if no chunk
	call	LMemFree
skipDelete:
	retn
HHDeleteHistory		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHUpdateHistoryForLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to update history after a link

CALLED BY:	HelpControlFollowLink()
PASS:		*ds:si - controller
		ss:bp - inherited locals
			filename - filename we're linking to
			context - context name we're linking to
			childBlock - handle of child block
			features - features that are on
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHUpdateHistoryForLink		proc	near
HELP_LOCALS
	.enter	inherit

	test	ss:features, mask HPCF_GO_BACK
	jz	noGoBack
	;
	; Record history for going back
	;
	call	HHGetHistoryCurrent		;cx <- current history entry
	jcxz	noGoBack			;branch if this is the 1st
	dec	cx
	call	HHRecordGoBack
noGoBack:
	;
	; Record it for history
	;
	call	HHRecordHistory
	;
	; Update UI based on history
	;
	call	HHUpdateHistoryUI

	.leave
	ret
HHUpdateHistoryForLink		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHUpdateHistoryUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for history

CALLED BY:	HHUpdateHistoryForLink()
PASS:		ss:bp - inherited locals
			childBlock - handle of child block
			features - features that are on
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHUpdateHistoryUI		proc	near
	uses	di
HELP_LOCALS
	.enter	inherit

	;
	; Enable "Go Back" if it exists & there is something to go back to
	;
	test	ss:features, mask HPCF_GO_BACK
	jz	noGoBack
	call	HHGetHistoryCount		;cx <- # entries
	cmp	cx, 1				;anything to go back to?
	jbe	noGoBack			;branch if no going back
	mov	bx, ss:childBlock
	mov	di, offset HelpGoBackTrigger	;^lbx:di <- OD of feature
	call	HUEnableFeature
noGoBack:
	;
	; Update the First Aid list
	;
	test	ss:features, mask HPCF_FIRST_AID
	jz	noFirstAidList
	call	HFAUpdateForMode
noFirstAidList:

	.leave
	ret
HHUpdateHistoryUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHAtTOC?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're at the TOC

CALLED BY:	UTILITY
PASS:		*ds:si - controller
		ss:bp - inherited locals
			context - name to check
			filename - file to check
RETURN:		z flag - set (jz) if at TOC
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHAtTOC?		proc	near
	uses	es, si, di
HELP_LOCALS
	.enter	inherit

	segmov	es, ss
	;
	; See if we're at "TOC"
	;
	push	ds, si
	mov	bx, handle HelpControlStrings
	call	MemLock
	mov	ds, ax

	mov	di, offset TableOfContents
	mov	si, ds:[di]			;ds:si <- ptr to "TOC"
	clr	cx				;cx <- names NULL-termianted
	lea	di, ss:context			;es:di <- ptr to context
	call	LocalCmpStrings

	call	MemUnlock
	pop	ds, si
	jne	notTOC				;branch if not at TOC
	;
	; See if it is the right file
	;
	lea	di, ss:filename			;es:di <- ptr to filename
	mov	ax, TEMP_HELP_TOC_FILENAME
	call	ObjVarFindData
EC <	ERROR_NC HELP_RECORDED_HELP_MISSING	;>
	mov	si, bx				;ds:si <- ptr to TOC filename
	call	LocalCmpStrings
notTOC:

	.leave
	ret
HHAtTOC?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHSetHistoryCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a duplicate history entry

CALLED BY:	HHRecordHistory()
PASS:		*ds:si	- controller
		cx	- history element # + 1
RETURN:		nothing
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHSetHistoryCurrent	proc	near
	uses	si, ds
	.enter

	call	HHLockHistoryArray		;*ds:si <- history array
	mov	ds:[HHBH_current], cx
	call	HHUnlockHistoryArray
		
	.leave
	ret
HHSetHistoryCurrent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHGetHistoryCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a duplicate history entry

CALLED BY:	HHRecordHistory()
PASS:		*ds:si	- controller
RETURN:		cx	- history element # + 1
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHGetHistoryCurrent	proc	near
	uses	si, ds
	.enter

	call	HHLockHistoryArray		;*ds:si <- history array
	mov	cx, ds:[HHBH_current]
	call	HHUnlockHistoryArray
		
	.leave
	ret
HHGetHistoryCurrent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHCheckForDuplicateHistoryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a duplicate history entry

CALLED BY:	HHRecordHistory()
PASS:		*ds:si	- history array
		ss:bp	- inherited locals
			    filename - name of help file
			    context  - name of context
RETURN:		carry	- set if we have a match
		dx	- matching entry # (first element = 1)
			- or -
		carry	- clear (no match)
		dx	- preserved
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHCheckForDuplicateHistoryEntry		proc	near
	uses	bx, di
HELP_LOCALS
	.enter	inherit

	;
	; Enumerate through each of the entries, looking for a match
	;
	mov	bx, cs
	mov	di, offset HHCheckDuplicateCB
	clr	ax				; initialize count
	call	ChunkArrayEnum
		
	.leave
	ret
HHCheckForDuplicateHistoryEntry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HHCheckDuplicateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a duplicate history entry

CALLED BY:	HHRecordHistory()
PASS:		*ds:si	- history array
		ds:di	- HelpHistoryElement
		ss:bp	- inherited locals
			    filename - name of help file
			    context  - name of context
		ax	- previous element count
RETURN:		ax	- current element count (just passed ax + 1)
		carry	- set if we have a match
		dx	- matching entry # (if match, otherwise dx preserved)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HHCheckDuplicateCB		proc	far
	uses	bx, cx, si
HELP_LOCALS
	.enter	inherit

	;
	; First compare the context name, then the filename
	;
	inc	ax				;element count -> ax
	segmov	es, ss, bx
	mov	si, ds:[di].HHE_context
	lea	bx, context
	call	compareChunk
	jne	continue
	mov	si, ds:[di].HHE_filename
	lea	bx, filename
	call	compareChunk
	jne	continue
	stc
	mov	dx, ax				;matching element # -> dx
done:
	.leave
	ret

continue:
	clc
	jmp	done

	;
	; Compare the string in *ds:si against the string in es:bx
	;
compareChunk:
	push	di
	mov	si, ds:[si]
	mov	di, bx
	clr	cx				;strings are NULL-terminated
	call	LocalCmpStrings
	pop	di
	retn
HHCheckDuplicateCB		endp

HelpControlCode ends
