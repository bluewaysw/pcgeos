COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/LMem
FILE:		lmemNotifyList.asm

AUTHOR:		Brian Chin

GLOBAL ROUTINES:
	Name			Description
	----			-----------
	GCNListAdd		add optr to kernel GCN list
	GCNListRemove		remove optr from kernel GCN list
	GCNListSend		send message to kernel GCN list

	GCNListCreateBlock	create list of lists in given block
	GCNListAddToBlock	add to gcn list given list of lists chunk
	GCNListRemoveFromBlock	remove from gcn list given list of lists chunk
	GCNListSendToBlock	send message to gcn list given list of lists
	GCNListFindListInBlock	find gcn list in list-of-lists
	GCNListDestroyBlock	free gcn list of lists & all lists it references
				(useful when freeing an object having its own
				GCN system)

	GCNListCreateList	create emtpy gcn list
	GCNListAddToList	add to gcn list given list chunk
	GCNListRemoveFromList	remove from gcn list given list chunk
	GCNListSendToList	send message to gcn list given list chunk
	GCNListFindItemInList	find item in gcn list
	GCNListDestroyList

	GCNListRelocateBlock	relocate a GCN list block
	GCNListUnRelocateBlock	unrelocate a GCN list block
	GCNListRelocateList	relocate a single GCN list
	GCNListUnRelocateList	unrelocate a single GCN list


LOCAL ROUTINES:
	Name			Description
	----			-----------

INTERNAL ROUTINES:
	Name			Description
	----			-----------
	FindGCNList		find gcn list in gcn list block
	GCNFindItemCallback	callback routine for GCNListFindItemInList
	GCNLSendCallback	callback routine for GCNListSendToList
	FindListCallback	callback routine for FindGCNList
	LockGCNBlock		lock gcn list block
	UnlockGCNBlock		unlock gcn list block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/91		Initial revision
	doug	12/91		Added passage of GCNListSendFlags to send
					routines

IMPLEMENTATION:

DESCRIPTION:

	This file contains notification list primitives.

	$Id: lmemGCNList.asm,v 1.1 97/04/05 01:14:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; Block for system-wide GCN lists
; 
GCNListBlock	segment lmem LMEM_TYPE_GENERAL
GCNListBlockHeader <
	{},			; Esp fills this in
	gcnListOfLists		; GCNLBH_listOfLists
>

gcnListOfLists	chunk.GCNListOfListsHeader <
	<
		0,				; CAH_count
		size GCNListOfListsElement,	; CAH_elementSize
		0,				; CAH_curOffset
		size GCNListOfListsHeader
	>
>
GCNListBlock	ends

;---------------------------------------

ChunkCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListSendToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to each element of general change notification
		list

CALLED BY:	GLOBAL

PASS:		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
		^hcx - classed event to send
			destination class is ignored
		if sending extra data block:
			dx - handle of extra data block
				NOTE: handle is also stored in classed event
				      according to the parameters of the
				      message in the classed event
		else:
			dx - 0
		bp - GCNListSendFlags
			GCNLSF_SET_STATUS:1
			Sends message to each optr of a particular
			notification list per GCNListSendToBlock, but
			additionally saves the message as the list's
			current "status".  The "status" message is
			automatically sent to any object adding itself to the
			list at a later point in time.

			GCNLSF_IGNORE_IF_STATUS_TRANSITIONING:1
			Has no effect here.  See GenApplicationClass for
			its extension.

		ds - segment of block containing GCN lists
		di - chunk handle of list of lists

		NOTE:  If data block w/reference count is passed in, its in-use
		       count should be incremented by one before the call
		       to this routine, as this routine decrements the count
		       by one upon completion (and destroys the block if
		       count reaches zero)

RETURN:		cx	= # messages sent, if !GCNLSF_SET_STATUS
		(event handle freed, data block freed when notification optrs
		 have processed it)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/01/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCNListSendToBlock	proc	far
	push	si
EC <	call	ECCheckGCNSend						>
EC <	mov	si, di							>
EC <	call	ECCheckChunkArray					>

	test	bp, mask GCNLSF_SET_STATUS		; clears carry
	jz	goAheadAndFind		; if not caching, do not create list
	stc				; otherwise, force list to exist
goAheadAndFind:
	call	GCNListFindListInBlock	; *ds:si - desired gcn list
	jnc	noList			; list not found, do nothing

	call	GCNListSendToList
exit:
	pop	si
	ret

noList:
	xchg	bx, cx
	call	ObjFreeMessage
	mov	bx, dx
	call	MemDecRefCount
	mov	bx, cx
	clr	cx
	jmp	exit
GCNListSendToBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListSendToList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to each element of general change notification
		list

CALLED BY:	GLOBAL
			GCNListSend, GCNListSendToBlock

PASS:		*ds:si - gcn list to send message to
		^hcx - classed event to send
			destination class is ignored
		if sending extra data block:
			dx - handle of extra data block
				NOTE: handle is also stored in classed event
				      according to the parameters of the
				      message in the classed event
		else:
			dx - 0

		bp - GCNListSendFlags
			GCNLSF_SET_STATUS:1
			Sends message to each optr of a particular
			notification list per GCNListSendToBlock, but
			additionally saves the message as the list's
			current "status".  The "status" message is
			automatically sent to any object adding itself to the
			list at a later point in time.

			GCNLSF_IGNORE_IF_STATUS_TRANSITIONING:1
			Has no effect here.  See GenApplicationClass for
			its extension.

		NOTE:  If data block w/reference count is passed in, its in-use
		       count should be incremented by one before the call
		       to this routine, as this routine decrements the count
		       by one upon completion (and destroys the block if
		       count reaches zero)

RETURN:		cx	= # messages sent, if !GCNLSF_SET_STATUS
		(event handle freed, data block freed when notification optrs
		 have processed it)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCNListSendToList	proc	far
	uses	ax, bx, di
	.enter
EC <	call	ECCheckGCNSend			; check ^hcx, dx	>
EC <	call	ECCheckChunkArray					>


	push	dx				; save block, if any, for end

	; bp is "cache flag"

	test	bp, mask GCNLSF_SET_STATUS
	jz	afterCacheTest			; see if caching new event

	mov	di, ds:[si]			; get ptr to list header
	inc	ds:[di].GCNLH_statusCount	; bump count of # of status
						; updates performed
						; (do always, regardless of
						; send optimizations)

	; Optimization -- if same status message, & same data block, if in
	; use, then we don't need to do an update at all.
	;
	mov	bx, cx				; new event in bx
						; new data in dx
	mov	ax, ds:[di].GCNLH_statusData	; old data in ax
	mov	di, ds:[di].GCNLH_statusEvent	; old event in di
	call	CompareStatusEvents		; See if status events are
						; non-null, register based &
						; identical
	jnc	afterSendNoCache		; if so, we're out of here

;nukeAndSend:
	; Nuke old cached event & data block (if any)
	;
	mov	di, ds:[si]			; get ptr to list header
	mov	bx, cx
	xchg	bx, ds:[di].GCNLH_statusEvent	; get old event, store new
	tst	bx
	jz	afterEventFreed
	call	ObjFreeMessage
afterEventFreed:
	mov	bx, dx
						; inc in-use count for data,
						; since will be referenced by
						; cache
	call	MemIncRefCount
	xchg	bx, ds:[di].GCNLH_statusData	; get old data, store new
						; don't need old anymore
	call	MemDecRefCount

afterCacheTest:
	jcxz	done				; quit if no event (this is
						; used to clear the cache, &
						; so is legit)
;
;	This code used to count the # items in the list, and increment the
;	ref count on the block depending upon how many items were in the
;	list. I changed this (GCNLSendCallback now increments the ref count)
;	as it would crash if items were added to the GCN list while we were
;	in the middle of sending an event to the list - atw 4/19/93
;
;

if 0
	mov	bx, cx				; save event
	call	ChunkArrayGetCount		; cx <- count
	xchg	bx, cx				; bx <- count, cx <- event


	;
	; If message has extra data associated with it, store count of
	; ODs to be notified -- this count is decremented once each time
	; one of ODs acknowledges the notification (via superclass to
	; ObjMetaGCNNotification).  When the count reaches zero, the extra
	; data block is freed.
	;
	tst	dx
	jz	noExtraData

	tst	bx				; anyone listening?
	jz	afterSend			; no, so don't bother

	push	ds
	LoadVarSeg	ds
	xchg	bx, dx				; bx <- handle, dx <- count
	add	ds:[bx].HM_otherInfo, dx	; up count by number of optr's
	xchg	bx, dx				; on list
	pop	ds	

	;
	; now, send the notification out
	;
noExtraData:
endif

;
;	CX <- event we are sending to the list
;	DX <- block being sent out
;
	mov	di, 500				; make sure that there is
	call	ThreadBorrowStackSpace		; enough stack space
	push	di

	clr	ax				;AX <- # items in the list
	mov	bx, cs
	mov	di, offset GCNLSendCallback	; bx:di = callback routine
	call	ChunkArrayEnum

	mov_tr	bx, ax				;BX <- # items in the list

	pop	di
	call	ThreadReturnStackSpace

EC <	call	ECCheckChunkArray					>
;afterSend:
	;
	; now that everyone who wants to be notified has the event on their
	; respective queues, free the original event
	;
				; ... unless we're caching it, in which case
				; we won't free it at this time.
	test	bp, mask GCNLSF_SET_STATUS
	jnz	afterDoneWithEvent
afterSendNoCache:
	xchg	bx, cx		; bx <- message, cx <- count
	call	ObjFreeMessage
afterDoneWithEvent:

	pop	bx
	call	MemDecRefCount
done:
EC <	call	ECCheckChunkArray					>
	.leave
	ret
GCNListSendToList	endp

;
; pass:
;	*ds:si - gcn list
;	ds:di - gcn list element
;	AX - running count of # items we've processed
;	^hcx - recorded event to send
;		destination class is ignored
;	dx - handle of block being sent
;	bp - GCNListSendFlags		
; return:
;	carry - set to end enumeration
; destroyed:
;	bx
;
GCNLSendCallback	proc	far
	uses	cx
	.enter
	mov	bx, dx
	call	MemIncRefCount

	mov	bx, cx			; bx - event handle
	mov	cx, ds:[di].GCNLE_item.handle	; ^lcx:si - destination
	mov	si, ds:[di].GCNLE_item.chunk
	call	MessageSetDestination
					; always use queue
					; don't free event
	mov	di, mask MF_RECORD or mask MF_FIXUP_DS
	test	bp, mask GCNLSF_FORCE_QUEUE
	jz	dispatch
	ornf	di, mask MF_FORCE_QUEUE
dispatch:
	call	MessageDispatch
	inc	ax			;Increment count of # items in list
	clc				; continue enumeration
	.leave
	ret
GCNLSendCallback	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	CompareStatusEvents

DESCRIPTION:	Check to see if the new status event is just like the old, 
		so that we can avoid sending out the update message to
		the GCNList.

CALLED BY:	INTERNAL
		GCNListSendToListCommon

PASS:		bx	- New status event
		dx	- New status block

		di	- Old status event
		ax	- Old status block

RETURN:		carry	- clear if safe to make the optimization & skip
			  sending out the update, set if we have to go
			  ahead & do it.

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
------------------------------------------------------------------------------@

CompareStatusEvents	proc	near
	uses	ax, bx, cx, si, di, ds, es
	.enter

	tst	bx			; Can't optimize null events, as
	LONG	jz	noOptimize	; they aren't sent anyway
	tst	di
	LONG	jz	noOptimize

	LoadVarSeg	ds, si		; ds, es <- dgroup
	mov	es, si			;  so we can compare the handles

	;
	; compare the contents of the handles from the signature through
	; the message number. exclude HE_bp as that's handled specially below
	; 
	CheckHack <HE_handleSig eq 1 and HE_cx eq 2 and HE_dx eq 4 and \
		   HE_bp eq 8 and HE_method eq 6>

	lea	si, [bx].HE_handleSig		; si <- bx+1
	inc	di				; point to HE_handleSig
	mov	cx, HE_bp-HE_handleSig
	repe	cmpsb
	jne	noOptimize
	
	;
	; The two handles match in all the important particulars. Now make
	; sure they're not SIG_EVENT_STACK, as we can't optimize events w/stack
	; frames -- we don't compare stack data (& don't have reason to do
	; so, since current use of status events revolves around around
	; notification passing data blocks)
	;
	cmp	ds:[bx].HE_handleSig, SIG_EVENT_REG
	jne	noOptimize

	; ds:si	= ds:bx.HE_bp
	; es:di = es:orig_di.HE_bp
	; ^hax	= old data block
	; ^hdx	= new data block

	; Now, the tricky stuff:
	;
	; if NewBlock=OldBlock {
	;	if new bp = old bp optimize else no optimize;
	; } else {
	;	if either NewBlock or OldBlock zero no optimize;
	; 	if NewBlock != new bp no optimize;
	; 	if OldBlock != old bp no optimize;
	;	if data blocks = optimize, else no optimize.
	; }

	cmp	dx, ax			; if blocks same...
	jne	blocksDifferent
	cmpsw				; & bp's same, optimize.
	je	done			; (carry clear)
	jmp	noOptimize		; otherwise bail, as bps are not
					; blocks, or if blocks aren't in
					; use, don't match

blocksDifferent:
	tst	dx			; If one block null, the other not,
	jz	noOptimize		; can't optimize
	tst	ax
	jz	noOptimize

	cmp	dx, ds:[si]		; Make sure bp's store block handles
	jne	noOptimize
	scasw
	jne	noOptimize

	mov_tr	si, ax			; ^hsi <- old data block
	mov	bx, dx			; If blocks different size, not same
	mov	ax, ds:[bx].HM_size
	cmp	ax, ds:[si].HM_size
	jne	noOptimize

	mov	cl, 3
	shl	ax, cl
	mov_tr	cx, ax			; cx = size (words)

	call	MemLock
	mov	ds, ax
	mov	bx, si
	call	MemLock
	mov	es, ax
					
	clr	si, di

	repe	cmpsw			; compare the masses
	call	MemUnlock		; preserves flags, thankfully
	mov	bx, dx
	call	MemUnlock
	je	done			; If block data same, opt possible
					;  (carry clear)

noOptimize:
	stc				; Bummer.  All that work for nothing.
done:
	.leave
	ret

CompareStatusEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListCreateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create empty GCN list

CALLED BY:	INTERNAL
			FindGCNList

PASS:		ds - segment of block to create new gcn list in
		bx - size of one element in list (normally GCNListElement)
		cx - size of list header (normally GCNListHeader)

RETURN:		*ds:si - new gcn list chunk

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListCreateList	proc	far	uses	ax, bx, cx
	.enter
	mov	al, mask OCF_DIRTY	; in case list is saved to state
	mov	bx, size GCNListElement	; size of one element in list
	mov	cx, size GCNListHeader	; size of list header
	clr	si
	call	ChunkArrayCreate	; *ds:si - new gcn list
	.leave
	ret
GCNListCreateList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListAddToList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds element to general change notification list

CALLED BY:	INTERNAL
			GCNListAdd
			GCNListAddToBlock

PASS:		cx:dx - optr to add
		*ds:si - gcn list to add to

RETURN:		carry set if optr added
		carry clear if optr is already there and not added
		ds - updated to keep pointing to gcn list block, if moved

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListAddToList	proc	far
	uses	di
	.enter
EC <	call	ECCheckChunkArray					>
	call	GCNListFindItemInList
	cmc					; carry clear if found,
						; carry set if not found
	jnc	afterExists				; item already there
	call	ChunkArrayAppend		; ds:di = new item
	call	ObjMarkDirty
	mov	ds:[di].GCNLE_item.handle, cx	; save optr
	mov	ds:[di].GCNLE_item.chunk, dx
	stc					; indicate item added
afterExists:
	pushf					; save added flag
	; Now, send cached event to this new optr
	;
	mov	di, ds:[si]
	tst	ds:[di].GCNLH_statusEvent	; get event handle
	jz	afterStatusUpdate
	push	bx
	push	ds:[LMBH_handle]
	mov	bx, ds:[di].GCNLH_statusData
	mov	di, ds:[di].GCNLH_statusEvent
	call	DispatchStatusMessage
	pop	bx
	call	MemDerefDS
	pop	bx
afterStatusUpdate:

	popf					; restore added flag

EC <	call	ECCheckChunkArray					>
	.leave
	ret
GCNListAddToList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DispatchStatusMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispatches the status message (if any) for the passed GCN list

CALLED BY:	INTERNAL - GCNListAdd and GCNListAddToList
PASS:		di - status event
		bx - block of event data
		^lcx:dx - OD to send status message to
RETURN:		nada
DESTROYED:	bx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DispatchStatusMessage	proc	far
	.enter

	push	ax, cx, dx, bp, si
	call	MemIncRefCount			; Inc in-use count for data
	mov	bx, di				; BX <- event handle
	mov	si, dx				; set ^lcx:si as destination
	call	MessageSetDestination
					; don't free event

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	mov	di, mask MF_RECORD
	call	MessageDispatch

	pop	di
	call	ThreadReturnStackSpace

	pop	ax, cx, dx, bp, si

	.leave
	ret
DispatchStatusMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListFindItemInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find optr in general change notification list

CALLED BY:	INTERNAL
			GCNListAddToList
			GCNListRemoveFromList

PASS:		cx:dx - optr to find (dx = 0 to match any chunk handle)
		*ds:si - gcn list to search

RETURN:		carry set if optr found
			ds:di - item
		carry clear if not found
		ds - updated to keep pointing to gcn list block, if moved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListFindItemInList	proc	far
	uses	ax, bx
	.enter
EC <	call	ECCheckChunkArray					>
	mov	bx, cs
	mov	di, offset GCNFindItemCallback
	call	ChunkArrayEnum
	mov	di, ax			; return item offset, in case found
	.leave
	ret
GCNListFindItemInList	endp

;
; pass:
;	*ds:si = array
;	ds:di = element
;	cx:dx = optr to find
; return:
;	carry - set to end enumeration (optr found)
;		ds:ax - offset to element found
; destroyed:
;	none
;
GCNFindItemCallback	proc	far
	mov	ax, di			; save offset, in case found
	cmp	cx, ds:[di].GCNLE_item.handle
	jne	noMatch
	tst	dx			;handle wildcard
	jz	match
	cmp	dx, ds:[di].GCNLE_item.chunk
	jne	noMatch
match:
	stc				; end enumeration
	jmp	done
noMatch:
	clc				; continue enumeration
done:
	ret
GCNFindItemCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListAddToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds element to general change notification list

CALLED BY:	GLOBAL

PASS:		cx:dx - optr to add
		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
				GCNLTF_SAVE_TO_STATE flag
		ds - segment of block containing GCN lists
		di - chunk handle of list of lists

RETURN:		carry set if optr added
		carry clear if optr is already there and not added

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/01/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListAddToBlock	proc	far
	uses	si
	.enter
EC <	xchg	si, di							>
EC <	call	ECCheckChunkArray					>
EC <	xchg	si, di							>
	stc				; create list if necessary
	call	GCNListFindListInBlock	; *ds:si - desired gcn list
	call	GCNListAddToList	; add cx:dx to *ds:si
	jnc	done			; already there, no change
	mov	si, di			; *ds:si = list of lists chunk
	call	ObjMarkDirty		; must mark list of lists as dirty
					;	since we changed one of
					;	its lists
done:
	.leave
	ret
GCNListAddToBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListFindListInBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find appropriate general change notification list in list of
		lists.  Creates new list, if necessary and desired.

CALLED BY:	GLOBAL
			FindGCNList
			GCNListAddToBlock
			GCNListRemoveFromBlock
			GCNListSendToBlock

PASS:		ds - segment of gcn list block
		di - chunk handle of list of lists
		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
		carry set to create list, if not currently existant
		carry clear to not create list

RETURN:		carry set if list found or created
			*ds:si - desired gcn list
		carry clear if list not found

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListFindListInBlock	proc	far
	uses	ax, bx, cx, dx, di, bp
	.enter
	mov	si, di			; *ds:si - list of lists
EC <	call	ECCheckChunkArray					>

	mov	cx, bx
	mov	dx, ax
	lahf				; save create-list flag
	mov	bx, cs
	mov	di, offset FindListCallback
	call	ChunkArrayEnum		; *ds:bp - list, if found
	jc	done
	sahf				; restore create-list flag
	jnc	done			; not found, do not create -> C clear
	;
	; create desired list
	;	*ds:si - list of lists array
	;	cx:dx - GCNListType
	;
	push	si			; save lists of lists array
	call	GCNListCreateList	; *ds:si - new gcn list
	mov	bp, si			; *ds:bp - new gcn list
	pop	si			; *ds:si - list of lists
	call	ChunkArrayAppend	; ds:di = new list of lists item
	call	ObjMarkDirty		; new list of lists added
	mov	ds:[di].GCNLOLE_list, bp	; save new gcn list
	mov	ds:[di].GCNLOLE_ID.GCNLT_manuf, cx	; save gcn ID
	mov	ds:[di].GCNLOLE_ID.GCNLT_type, dx
	stc				; indicate new list created
done:
	mov	si, bp			; return gcn list, in case
					;	found or created
	.leave
	ret
GCNListFindListInBlock	endp

;
; pass:
;	*ds:si - array
;	ds:di - element
;	cx:dx - GCNListType
;		cx - GCNLT_manuf
;		dx - GCNLT_type
; return:
;	carry - set to end enumeration (list found)
;		ds:*bp - chunk of GCN list, in case found
; destroyed:
;	none
;
FindListCallback	proc	far	uses	ax, dx
	.enter
	cmp	cx, ds:[di].GCNLOLE_ID.GCNLT_manuf
	jne	noMatch
	mov	ax, ds:[di].GCNLOLE_ID.GCNLT_type
	andnf	ax, not mask GCNLTF_SAVE_TO_STATE
	andnf	dx, not mask GCNLTF_SAVE_TO_STATE
	cmp	ax, dx
	jne	noMatch
	stc				; end enumeration
	mov	bp, ds:[di].GCNLOLE_list	; return GCN list chunk
	jmp	done
noMatch:
	clc				; continue enumeration
done:
	.leave
	ret
FindListCallback	endp


ChunkCommon ends

;--------------------------------------------------

ChunkArray segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds element to general change notification list

CALLED BY:	GLOBAL

PASS:		cx:dx - optr to add
		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
				GCNLTF_SAVE_TO_STATE flag

RETURN:		carry set if optr added
		carry clear if optr is already there and not added

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListAdd	proc	far
	uses	ds, si, bx, di
	.enter
	call	LockGCNBlock		; ds - segment of gcn list block
	stc				; create list if necessary
	call	FindGCNList		; *ds:si - desired gcn list

;	Grab the status event out of the GCNListHeader, and set it to zero,
;	so GCNListAddToList will not send out the GCN notification. We want
;	to send out the notifications after the GCN block has been unlocked,
;	to avoid deadlocks (10/18/95 - atw)

	mov	di, ds:[si]
	clr	bx
	xchg	bx, ds:[di].GCNLH_statusEvent
	mov	di, ds:[di].GCNLH_statusData
	xchg	bx, di			;BX <- status data
					;DI <- status event

;	Add the object to the GCN list

	call	GCNListAddToList	; add cx:dx to *ds:si

;	Restore the old status event

	pushf				;Save carry returned from
					; GCNListAddToList
	mov	si, ds:[si]
	mov	ds:[si].GCNLH_statusEvent, di

;	Unlock the block containing the GCN lists

	call	UnlockGCNBlock		; (preserves flags)

;	If there was a status event, we need to dispatch the status message

	tst	di
	jz	noStatusEvent
	call	DispatchStatusMessage
noStatusEvent:
	popf
	.leave
	ret
GCNListAdd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListRemoveFromBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove optr from general change notification list

CALLED BY:	GLOBAL

PASS:		cx:dx - optr to remove
		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
		ds - segment of block containing GCN lists
		di - chunk handle of list of lists

RETURN:		carry set if OD found and removed
		carry clear if not found

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/01/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListRemoveFromBlock	proc	far	uses	si
	.enter
EC <	xchg	si, di							>
EC <	call	ECCheckChunkArray					>
EC <	xchg	si, di							>
	clc				; do not create list
	call	GCNListFindListInBlock	; *ds:si - desired gcn list
	jnc	done			; list not found, return carry clear
	call	GCNListRemoveFromList	; remove cx:dx from *ds:si
	jnc	done			; not there, no change
	mov	si, di			; *ds:si = list of lists chunk
	call	ObjMarkDirty		; must mark list of lists as dirty
					;	since we changed one of
					;	its lists
done:
	.leave
	ret
GCNListRemoveFromBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListRemoveFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove optr from general change notification list

CALLED BY:	INTERNAL
			GCNListRemove

PASS:		cx:dx - optr to remove
		*ds:si - gcn list to remove from

RETURN:		carry set if OD found and removed
		carry clear if not found
		ds - updated to keep pointing to gcn list block, if moved

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListRemoveFromList	proc	far
	uses	di
	.enter
EC <	call	ECCheckChunkArray					>

	clc
	pushf
removeLoop:
	call	GCNListFindItemInList		; ds:di = item, if found
						; carry clear if not found
	jnc	done				; item not there
	call	ChunkArrayDelete
	popf
	stc
	pushf
	tst	dx
	jz	removeLoop
done:
	popf
EC <	call	ECCheckChunkArray					>
	.leave
	ret
GCNListRemoveFromList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListRecordAndSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A system utility to make broadcasting things to a system
		GCN list easier.

CALLED BY:	GLOBAL	
PASS:		ax	= message to broadcast
		bx:si	= manuf id:gcn list over which to broadcast it
		cx, dx, bp = data for the message
		di	= GCNListSendFlags
RETURN:		cx	= number of messages sent out
DESTROYED:	dx, bp, di, ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListRecordAndSend proc	far
		.enter
		push	di
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		pop	bp
		mov_tr	ax, si
		clr	dx		; no associated data block
		call	GCNListSend
		.leave
		ret
GCNListRecordAndSend endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to each element of general change notification
		list

CALLED BY:	GLOBAL

PASS:		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
		^hcx - classed event to send
			destination class is ignored
		if sending extra data block:
			dx - handle of extra data block
				NOTE: handle is also stored in classed event
				      according to the parameters of the
				      message in the classed event
		else:
			dx - 0
		bp - GCNListSendFlags
			GCNLSF_SET_STATUS:1
			Sends message to each optr of a particular
			notification list per GCNListSendToBlock, but
			additionally saves the message as the list's
			current "status".  The "status" message is
			automatically sent to any object adding itself to the
			list at a later point in time.

			GCNLSF_IGNORE_IF_STATUS_TRANSITIONING:1
			Has no effect here.  See GenApplicationClass for
			its extension.


		NOTE:  If block w/reference count is passed in, its in-use
		       count should be incremented by one before the call
		       to this routine, as this routine decrements the count
		       by one upon completion (and destroys the block if
		       count reaches zero)

RETURN:		cx	= # messages sent, if !GCNLSF_SET_STATUS
			= event handle, if GCNLSF_SET_STATUS
		(event handle freed, data block freed when notification optrs
		 have processed it)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCNListSend	proc	far
	push	si, ds
EC <	call	ECCheckGCNSend						>

	call	LockGCNBlock		; ds - segment of gcn list block
	test	bp, mask GCNLSF_SET_STATUS		; clears carry
	jz	goAheadAndFind		; if not caching, do not create list

;	Change the owner to be the kernel, in case the sending geode exits,
;	so the handle doesn't get freed out from under us.

	jcxz	noChangeOwner
	push	bx, ax
	mov	bx, cx
	mov	ax, handle 0
	call	HandleModifyOwner
	pop	bx, ax
noChangeOwner:

	stc				; otherwise, force list to exist
goAheadAndFind:
	call	FindGCNList		; *ds:si - desired gcn list
	jnc	noList			; list not found, do nothing

					; Change block to be owned by Kernel
					; if it is going to be used in the
					; system-wide GCN lists
	;
	; If sending notification message with data, change data block to
	; be owned by kernel, so it doesn't get freed when thread that
	; created it gets freed
	;
	tst	dx			; any extra data block?
	jz	noDataBlock		; nope

	mov	bx, dx
	mov	ax, handle 0		; change owner to kernel
	call	HandleModifyOwner
noDataBlock:

	call	GCNListSendToList
exit:
	call	UnlockGCNBlock
	pop	si, ds
	ret
noList:
	xchg	bx, cx			; bx <- message sent, cx <- list manuf
	call	ObjFreeMessage
	mov	bx, dx			; bx <- data block
	call	MemDecRefCount
	mov	bx, cx			; bx <- list manuf
	clr	cx
	jmp	exit
GCNListSend	endp


;
; pass:
;	^hcx - classed event to send
;	if sending extra data block:
;		dx - handle of extra data block
;			NOTE: handle is also stored in classed event
;			      according to the parameters of the
;			      message in the classed event
;	else:
;		dx - 0
; destroyed:
;	none
;
if ERROR_CHECK
ECCheckGCNSend	proc	far
	uses	ax, bx, cx, si, ds
	.enter

	test	bp, not mask GCNListSendFlags
	ERROR_NZ	BAD_FLAGS_RESERVED_MUST_BE_0

	;
	; get event info
	;
	mov	bx, cx			; bx - event
	call	ObjGetMessageInfo		; ax - method, cx:si = destination
;we won't check this since the destination is documented as being ignored
;	tst	cx
;	ERROR_NZ	GCN_SEND_DESTINATION_MUST_BE_ZERO

; NOTE that *any* message can be sent via the GCN list so no
; error checking can be done on the message
;
if	(0)
	;
	; make sure message is a MetaGCNMethod, or one of the other
	; standard messages uses
	;
	cmp	ax, MSG_META_NOTIFY
	je	afterMessageCheck
	cmp	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	je	afterMessageCheck
	cmp	ax, first MetaGCNMessages
	ERROR_B	GCN_ILLEGAL_NOTIFICATION_MESSAGE
	cmp	ax, MetaGCNMessages
	ERROR_AE	GCN_ILLEGAL_NOTIFICATION_MESSAGE
afterMessageCheck:
endif

	;
	; check to ensure that the predefined messages that are supposed
	; to have data blocks, do indeed have data blocks
	;
	cmp	ax, MSG_NOTIFY_FILE_CHANGE
	je	haveDataBlock
	cmp	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	jne	done
haveDataBlock:
	tst	dx
	jz	done
	mov	bx, dx
	mov	ax, MGIT_OTHER_INFO	; get reference count
	call	MemGetInfo
	cmp	ax, 1024
	ERROR_A		GCN_BAD_USAGE_COUNT
done:
	.leave
	ret
ECCheckGCNSend	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find appropriate general change notification list in list of
		lists.  Creates new list, if necessary and desired.

CALLED BY:	INTERNAL
			GCNListAdd
			GCNListRemove
			GCNListSend

PASS:		ds - segment of gcn list block
		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
		carry set to create list, if not currently existant
		carry clear to not create list

RETURN:		carry set if list found or created
			*ds:si - desired gcn list
		carry clear if list not found

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindGCNList	proc	far
	uses	di
	.enter
	mov	di, ds:[GCNLBH_listOfLists]	; *ds:di - list of lists
	call	GCNListFindListInBlock
	.leave
	ret
FindGCNList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListClearList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes all the ODs in the passed list

CALLED BY:	EndGeos
PASS:		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type
RETURN:		nada
DESTROYED:	ax, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListClearList	proc	far	uses	ds, si, cx
	.enter

	call	LockGCNBlock
	call	FindGCNList
	jnc	noList

;	Nuke all elements in this list

	clr	ax
	mov	cx, -1
	call	ChunkArrayDeleteRange
noList:
	call	UnlockGCNBlock
	.leave
	ret
GCNListClearList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListCreateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create list of lists in given block

CALLED BY:	GLOBAL

PASS:		ds - segment of LMem block to contain GCN list structure

RETURN:		*ds:si - GCN list of lists chunk

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/01/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListCreateBlock	proc	far	uses	ax, bx, cx
	.enter
	mov	al, mask OCF_DIRTY	; in case list is saved to state
	mov	bx, size GCNListOfListsElement	; size of element
	mov	cx, size GCNListOfListsHeader	; size of header
	clr	si
	call	ChunkArrayCreate	; *ds:si - new gcn list
	.leave
	ret
GCNListCreateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockGCNBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock general change notification list block

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		ds - segment of general change notification list block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We need to grab the semaphore as we can't have the block
		moved by other threads that might access the GCN block
		and do LMem operations.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockGCNBlock	proc	near
	uses	ax, bx
	.enter
	mov	bx, handle GCNListBlock
	call	MemPLock
	mov	ds, ax
	.leave
	ret
LockGCNBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockGCNBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlock general change notification list block

CALLED BY:	INTERNAL


PASS:		ds - segment of general change notification list block

RETURN:		nothing

DESTROYED:	nothing
		(preserves flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockGCNBlock	proc	near	uses	bx
	.enter
	mov	bx, handle GCNListBlock
	call	MemUnlockV
	.leave
	ret
UnlockGCNBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListRelocateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate general change notification lists in given block

CALLED BY:	GLOBAL

PASS:		ds - segment of block containing GCN lists
		di - chunk handle of list of lists
		dx - handle of block containing relocation

RETURN:		nothing

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListRelocateBlock	proc	far	uses	si, bp
	.enter
	mov	bp, 0				; relocate
	call	RelocateBlockCommon
	.leave
	ret
GCNListRelocateBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListUnRelocateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unrelocate general change notification lists in given block

CALLED BY:	GLOBAL

PASS:		ds - segment of block containing GCN lists
		di - chunk handle of list of lists
		dx - handle of block containing relocation

RETURN:		carry clear if list of lists has lists saved to state
		carry set if list of lists has no lists saved to state
			and is thus destroyed

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListUnRelocateBlock	proc	far	uses	ax, si, bp
	.enter
	cmp	{word} ds:[di], -1	; empty list of lists?
	je	done			; yes, don't free (assume in resource)
					;	(carry clear)
	mov	bp, 1			; unrelocate
	call	RelocateBlockCommon	; returns *ds:si = list of lists
	call	ChunkArrayGetCount	; cx = count
	tst	cx			; anything left?
					;	(clears carry)
	jnz	done			; yes, leave list of lists alone
	mov	ax, si
	call	LMemFree		; else, free list of lists chunk
	stc				; indicate list of lists destroyed
done:
	.leave
	ret
GCNListUnRelocateBlock	endp

;
; pass:
;	*ds:di - ListOfLists array
;	dx - handle of block containing relocation
;	bp - 0 for relocation, non-zero for unrelocation
; return:
;	*ds:si - ListOfLists array
; destroyed:
;	nothing
;
RelocateBlockCommon	proc	near	uses	bx, di
	.enter
	mov	si, di			; *ds:si = list of lists
	cmp	{word} ds:[si], -1	; empty list?
	je	done
EC <	call	ECCheckChunkArray					>
	mov	bx, cs
	mov	di, offset RelocateBlockCallback
	call	ChunkArrayEnum
done:
	.leave
	ret
RelocateBlockCommon	endp

;
; pass:
;	*ds:si - ListOfLists array
;	ds:di - ListsOfLists element
;	dx - handle of block containing relocation
;	bp - 0 for relocation, non-zero for unrelocation
; return:
;	carry - clear to continue enumeration
; destroyed:
;	bx, di
;
RelocateBlockCallback	proc	far	uses	ax
	.enter
	mov	bx, si			; save list of lists chunk
	mov	si, ds:[di].GCNLOLE_list	; *ds:si = GCN list
	tst	bp
	jnz	unreloc
	call	GCNListRelocateList
	jmp	short done

unreloc:
	test	ds:[di].GCNLOLE_ID.GCNLT_type, mask GCNLTF_SAVE_TO_STATE
	jz	freeList		; if not saved to state, free it

	;
	; deal with undirty resource GCN list (it will have been resized to 0
	; by CompactObjBlock).  We must NOT free the thing, and must especially
	; NOT free the list of lists entry for it.
	;
	cmp	{word} ds:[si], -1	; undirty resource list?
	je	done			; if so, leave it alone

;why might this happen?
;	call	ChunkArrayGetCount	; cx = # elements
;	jcxz	freeList		; no elements, just free list

	call	GCNListUnRelocateList
	jmp	short done

freeList:
	push	bx			; *ds:bx = list of lists
	mov	bx, ds:[bx]
	sub	di, bx			; di = offset from start
	call	GCNListDestroyList
	pop	si			; *ds:si = list of lists
	mov	bx, ds:[si]
	add	di, bx			; rederefence into element
	call	ChunkArrayDelete	; delete list of lists entry for the
					;	deleted list
	call	ObjMarkDirty

done:
	clc				; continue enumeration
	.leave
	ret
RelocateBlockCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListRelocateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate general change notification list

CALLED BY:	INTERNAL
			GCNListRelocateBlock

PASS:		*ds:si - gcn list to relocate
		dx - handle of block containing relocation

RETURN:		ds - updated to keep pointing to gcn list block, if moved

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListRelocateList	proc	far	uses	bp
	.enter
	mov	bp, 0			; signal relocate
	call	RelocateListCommon
	.leave
	ret
GCNListRelocateList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListUnRelocateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unrelocate general change notification list

CALLED BY:	INTERNAL
			GCNListUnRelocateBlock

PASS:		*ds:si - gcn list to unrelocate
		dx - handle of block containing relocation

RETURN:		ds - updated to keep pointing to gcn list block, if moved

DESTROYED:	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListUnRelocateList	proc	far	uses	bp, bx, di
	.enter
	mov	bp, 1
	call	RelocateListCommon
	call	FreeEventAndData
	.leave
	ret
GCNListUnRelocateList	endp

RelocateListCommon	proc	near	uses	ax, bx, cx, di
	.enter
	cmp	{word} ds:[si], -1	; empty list?
	je	done
EC <	call	ECCheckChunkArray					>
	mov	bx, cs
	mov	di, offset RelocateListCallback	; bx:di = callback routine
	call	ChunkArrayEnum
EC <	call	ECCheckChunkArray					>
done:
	.leave
	ret
RelocateListCommon	endp

;
; pass:
;	*ds:si - gcn list
;	ds:di - gcn list element
;	dx - handle of block containing relocation
;	bp - 0 for relocation, non-zero for unrelocation
; return:
;	carry - clear to continue enumeration
; destroyed:
;	ax, bx, cx
;
RelocateListCallback	proc	far
	mov	bx, dx			; bx = handle of block w/relocation
	mov	cx, ds:[di].GCNLE_item.handle	; cx = reloc/unreloc handle
	mov	al, RELOC_HANDLE
	tst	bp
	jnz	unreloc
	call	ObjDoRelocation		; XXX: ignore error
	jmp	short relocCommon

unreloc:

EC <	push	ax, bx							>
EC <	mov	bx, ds:[LMBH_handle]	; bx = GCN list block		>
EC <	call	MemOwnerFar		; bx = GCN list owner		>
EC <	mov	ax, bx			; ax = GCN list owner		>
EC <	mov	bx, cx			; bx = unreloc handle		>
EC <	call	MemOwnerFar		; bx = unreloc handle owner	>
EC <	cmp	bx, ax							>
EC <	ERROR_NE	GCN_UNRELOCATING_GCN_LIST_WITH_UNOWNED_OPTR	>
EC <	pop	ax, bx							>

	call	ObjDoUnRelocation	; XXX: ignore error

relocCommon:
	mov	ds:[di].GCNLE_item.handle, cx	; cx = reloc/unreloc handle
	clc				; continue enumeration
	ret
RelocateListCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove optr from general change notification list

CALLED BY:	GLOBAL

PASS:		cx:dx - optr to remove
		bx:ax - GCNListType
			bx - GCNLT_manuf
			ax - GCNLT_type

RETURN:		carry set if OD found and removed
		carry clear if not found

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListRemove	proc	far
	uses	ds, si
	.enter
	push	ax, bx
	mov	bx, handle GCNListBlock
	call	MemPLock
	mov	ds, ax
	pop	ax, bx			; ds - segment of gcn list block
	clc				; do not create list
	call	FindGCNList		; *ds:si - desired gcn list
	jnc	done			; list not found, return carry clear
	call	GCNListRemoveFromList	; remove cx:dx from *ds:si
done:
	push	bx
	mov	bx, handle GCNListBlock
	call	MemUnlockV
	pop	bx
	.leave
	ret
GCNListRemove	endp

ChunkArray ends

;-------------------

ObjectFile segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListDestroyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanly destroys a GCN lists of lists & all lists on it.

CALLED BY:	GLOBAL

PASS:		ds - segment of LMem block to contain GCN list structure

RETURN:		*ds:di - GCN list of lists chunk

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListDestroyBlock	proc	far
	uses	ax, bx, si, di
	.enter
	mov	si, di			; *ds:si - list of lists
	mov	bx, cs
	mov	di, offset FreeListCallback
	call	ChunkArrayEnum
	mov	ax, si			; nuke list of lists
	call	LMemFree
	.leave
	ret
GCNListDestroyBlock	endp

;
; pass:
;	*ds:si - array
;	ds:di - element
; return:
;	carry - set to end enumeration
; destroyed:
;	none
;
FreeListCallback	proc	far	uses	si, di
	.enter
	mov	si, ds:[di].GCNLOLE_list	; get chunk of list
	call	GCNListDestroyList
	clc					; continue enumeration
	.leave
	ret
FreeListCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNListDestroyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanly destroys a GCN list

CALLED BY:	GLOBAL

PASS:		*ds:si - GCN list to destroy

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNListDestroyList	proc	far	uses	ax, bx, di, si
	.enter
	cmp	{word} ds:[si], -1		; empty list?
	je	free

EC <	call	ECCheckChunkArray					>
	;
	; nuke cached event, dec block in-use count
	;
	call	FreeEventAndData

free:
	mov	ax, si
	call	LMemFree			; nuke the list chunk itself
	.leave
	ret
GCNListDestroyList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeEventAndData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees status event and status data for GCN list

CALLED BY:	GLOBAL

PASS:		*ds:si - GCN list

RETURN:		nothing

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/92		Broken out from GCNListDestroyList for use
				in GCNListUnRelocateList

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeEventAndData	proc	far
	mov	di, ds:[si]			; deref
	clr	bx
	xchg	bx, ds:[di].GCNLH_statusEvent
	tst	bx
	jz	afterEvent
	call	ObjFreeMessage
afterEvent:
	clr	bx
	xchg	bx, ds:[di].GCNLH_statusData	; dec data block reference
	call	MemDecRefCount
	ret
FreeEventAndData	endp

ObjectFile ends
