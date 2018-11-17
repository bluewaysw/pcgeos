COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Message
FILE:		messageList.asm

AUTHOR:		Adam de Boor, May 17, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/17/94		Initial revision


DESCRIPTION:
	Implementation of the MessageListClass
		

	$Id: messageList.asm,v 1.1 97/04/05 01:20:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

	MessageListClass

MailboxClassStructures	ends

MessageList	segment	resource

MessageListDerefGen	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
MessageListDerefGen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSetCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the criteria for the messages we're displaying and rescan

CALLED BY:	MSG_ML_SET_CRITERIA
PASS:		*ds:si	= MessageList object
		ds:di	= MessageListInstance
		*ds:dx	= primary MessageControlPanelCriteria
		*ds:bp	= secondary MessageControlPanelCriteria (if primary
			  is MDPT_BY_TRANSPORT, else 0)
RETURN:		carry set if list is empty
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	list is rescanned

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS

MLSetCriteria	method dynamic MessageListClass, MSG_ML_SET_CRITERIA
		.enter
EC <		tst	dx						>
EC <		jnz	checkPrimary					>
EC <		Assert	e, bp, 0		; secondary must also be 0>
EC <		jmp	argsOK						>
EC <checkPrimary:							>
		Assert	chunk, dx, ds
EC <		tst	bp						>
EC <		jz	argsOK						>
		Assert	chunk, bp, ds
EC <argsOK:								>
		
		mov	ds:[di].MLI_primaryCriteria, dx
		mov	ds:[di].MLI_secondaryCriteria, bp

	;
	; Reset minimum size, in case we're switching from a two-line to a one-
	; line format.
	;
		call	MLSetInitialMinimumSize
		
		mov	ax, MSG_ML_RESCAN
		call	ObjCallInstanceNoLock
		.leave
		ret
MLSetCriteria	endm

endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECMLValidateCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Make sure the criteria chunks stored with the object
		are rational

CALLED BY:	(INTERNAL)
PASS:		ds:di	= MessageListInstance
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECMLValidateCriteria proc	near
if	_CONTROL_PANELS
		class	MessageListClass
		.enter
		mov	bx, ds:[di].MLI_primaryCriteria
		tst	bx
		jnz	checkCrit
checkSecondZero:
		tst	ds:[di].MLI_secondaryCriteria
		ERROR_NZ SECONDARY_CRITERIA_SHOULD_NOT_EXIST
		jmp	secondOK
checkCrit:
		Assert	chunk, bx, ds
		mov	bx, ds:[bx]
		cmp	ds:[bx].MCPC_type, MDPT_BY_TRANSPORT
		jne	checkSecondZero
		Assert	chunk, ds:[di].MLI_secondaryCriteria, ds
secondOK:
		.leave
endif	; _CONTROL_PANELS
		ret
ECMLValidateCriteria endp
endif ; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rebuild the list of messages we display

CALLED BY:	MSG_ML_RESCAN
PASS:		*ds:si	= messageList object
		ds:di	= MessageListInstance
RETURN:		carry set if list is empty
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	old array is freed, dynamic list is reinitialized

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLRescan	method dynamic MessageListClass, MSG_ML_RESCAN
	;
	; NOTE: THESE DECLARATIONS MUST MATCH THOSE IN MLUpdateList
	; 
scanRoutines	local	MLScanRoutines
listObj		local	fptr
curSelection	local	MLMessage
skipSorting	local	byte
	ForceRef	scanRoutines	; used in MLGetRoutines and others
	ForceRef	listObj		; used in MLSelectMessages
	ForceRef	skipSorting	; used in MLUpdateList
		.enter
EC <		call	ECMLValidateCriteria				>
		push	si

		mov	ax, MSG_ML_RELEASE_MESSAGES
		call	ObjCallInstanceNoLock
		
	;
	; Flag no current selection.
	;
		mov	ss:[curSelection].MLM_message.high, 0
	;
	; Create a new array for storing the messages & addresses to display.
	; 
		mov	bx, size MLMessage
		clr	cx, si
		mov	al, mask OCF_DIRTY
		call	ChunkArrayCreate
		mov_tr	ax, si

		pop	si			; *ds:si <- message list
		DerefDI	MessageList
		mov	ds:[di].MLI_messages, ax
	;
	; Fetch the handle for the DBQ we use as our source.
	; 
		call	MLGetQueue		; ^vbx:di <- DBQ
	;
	; Call our subclass to get the routines to use in the scan.
	; 
		call	MLGetRoutines
	;
	; Use the select routine to build up the array.
	; 
		call	MLSelectMessages
	;
	; Use the sort routine to sort the array.
	; 
FXIP <		movdw	bxax, ss:[scanRoutines].MLSR_compare		>
		call	MLSortMessages
	;
	; Tell ourselves how many entries there are in the list.
	; 
		call	MLSetNumMessages
		stc
		jcxz	done
		clc
done:
		.leave
		ret
MLRescan	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSetNumMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell ourselves how many messages we've selected.

CALLED BY:	(INTERNAL) MLRescan, 
			   MLUpdateList
PASS:		*ds:si	= MessageList object
RETURN:		cx	= # messages in the list
DESTROYED:	ax, dx, di
SIDE EFFECTS:	monikers will be fetched again

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSetNumMessages proc	near
		class	MessageListClass
		uses	bx
		.enter	inherit	MLRescan
		Assert	objectPtr, dssi, MessageListClass

		push	si
		DerefDI	MessageList
		mov	si, ds:[di].MLI_messages
		call	ChunkArrayGetCount
		mov	bx, si			; save array for restoring
						;  selection
		pop	si
		
		push	bp, cx
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
		pop	bp, cx
	;
	; If any selection was current, try and find it again.
	;
		tst	ss:[curSelection].MLM_message.high
		jz	done
		
	;
	; This is a hacked in-line expansion of ChunkArrayEnum b/c we don't
	; have enough registers or the patience for doing it The Right Way
	;
	; During the loop:
	; 	siax	= MailboxMessage being sought
	; 	dx	= address # being sought
	; 	bx	= message # of current entry
	; 	ds:di	= MLMessage being checked
	; 	cx	= # messages left to check
	;
		push	cx
		push	si

		mov	di, ds:[bx]
		mov	cx, ds:[di].CAH_count
		add	di, ds:[di].CAH_offset
		jcxz	foundMsg	; (ZF=0, b/c DI can't be 0 here)
		
		movdw	siax, ss:[curSelection].MLM_message
		mov	dx, ss:[curSelection].MLM_address
		clr	bx
findLoop:
		CmpTok	ds:[di].MLM_message, si, ax, nextMsg
		cmp	ds:[di].MLM_address, dx
		je	foundMsg
nextMsg:
		inc	bx
		add	di, size MLMessage
		loop	findLoop
		inc	cx		; set non-zero to indicate not found

foundMsg:
		pop	si		; *ds:si <- ML
		jne	popDone
	;
	; Set single selection to new index of message.
	;
		mov_tr	cx, bx
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		push	bp
		call	ObjCallInstanceNoLock		
		pop	bp

popDone:
		pop	cx
done:
		.leave
		ret
MLSetNumMessages endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLReleaseMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the array of messages we've got, removing our
		references to each message in the array

CALLED BY:	MSG_ML_RELEASE_MESSAGES
PASS:		*ds:si	= MessageList object
		ds:di	= MessageListInstance
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	MLI_messages is set to 0 and the array freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLReleaseMessages method dynamic MessageListClass, MSG_ML_RELEASE_MESSAGES
		uses	cx, dx
		.enter
	;
	; Fetch the current array and zero the instance variable.
	; 
   		clr	ax
		xchg	ds:[di].MLI_messages, ax
		tst	ax
		jz	done
	;
	; Destroy the existing array, removing the reference that was added
	; to the message for each time it appeared in our list.
	; 
		mov_tr	si, ax			; *ds:si <- array
		call	MailboxGetAdminFile
		mov	cx, bx			; opt: pass admin file in cx
		mov	bx, cs
		mov	di, offset MLReleaseMessagesCallback
		call	ChunkArrayEnum

		mov_tr	ax, si
		call	LMemFree

done:
		.leave
		ret
MLReleaseMessages endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLReleaseMessagesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to remove our references to each message
		in the list.

CALLED BY:	(INTERNAL) MLReleaseMessages via ChunkArrayEnum
PASS:		ds:di	= MLMessage
		cx	= admin file
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx, dx, si, di all allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLReleaseMessagesCallback proc	far
		.enter
		movdw	dxax, ds:[di].MLM_message
		mov	bx, cx
		call	DBQDelRef
		clc
		.leave
		ret
MLReleaseMessagesCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the vptr of the DBQ that holds the messages we display

CALLED BY:	(INTERNAL) MLRescan
PASS:		ds:di	= MessageListInstance
RETURN:		^vbx:di	= vptr of source DBQ
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetQueue	proc	near
		class	MessageListClass
		.enter
			CheckHack <width MLA_SOURCE_QUEUE eq 1>
			CheckHack <MLSQ_INBOX eq 0>
		test	ds:[di].MLI_attrs, mask MLA_SOURCE_QUEUE
		jz	getInbox

		call	AdminGetOutbox
		jmp	done
getInbox:
		call	AdminGetInbox
done:
		.leave
		ret
MLGetQueue 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the subclass for the routines to use in preparing the
		message list.

CALLED BY:	(INTERNAL) MLRescan
			   MLUpdateList
PASS:		*ds:si	= MessageList object
		ss:bp	= inherited frame
RETURN:		ss:[scanRoutines] = set
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetRoutines	proc	near
		class	MessageListClass
		.enter	inherit	MLRescan
		mov	cx, ss
		lea	dx, ss:[scanRoutines]
		mov	ax, MSG_ML_GET_SCAN_ROUTINES
		call	ObjCallInstanceNoLock
		.leave
		ret
MLGetRoutines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetScanRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for the message. CONTROL SHOULD NOT REACH
		HERE.

CALLED BY:	MSG_ML_GET_SCAN_ROUTINES
PASS:		cx:dx	= fptr.MLScanRoutines to fill in
RETURN:		structure filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
MLGetScanRoutines method dynamic MessageListClass, MSG_ML_GET_SCAN_ROUTINES
		ERROR	MESSAGE_LIST_SUBCLASS_MUST_INTERCEPT_THIS
MLGetScanRoutines endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSelectMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the messages & their addresses to go into the list.

CALLED BY:	(INTERNAL) MLRescan
PASS:		*ds:si	= MessageList object
		^vbx:di	= vptr of DBQ from which the messages come
		ss:bp	= inherited frame with scan routines filled in
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We use DBQGetItem to iterate through the queue, rather than
			DBQEnum, because the subclass callback will be having
			to lock down other maps in order to figure out what
			it should do. Continuing in our manner of trying to
			not hold a lock while going for another one, we'd
			rather not have the DBQ locked while locking down
			other maps...

		The one drawback is we'll skip a message if something gets
			deleted while we're doing this. We assume we'll get
			notification of the shortening of the queue, however,
			and rescan at that point.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSelectMessages proc	near
		class	MessageListClass
		.enter	inherit	MLRescan
		movdw	ss:[listObj], dssi
		mov	cx, SEGMENT_CS
		mov	dx, offset MLSelectMessagesCallback
		call	DBQEnum
		mov	ds, ss:[listObj].segment
		.leave
		ret
MLSelectMessages endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSelectMessagesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to call the subclass callback function to
		let it add, or not, the passed message.

CALLED BY:	(INTERNAL) MLSelectMessages via DBQEnum
			   MLUpdateList
PASS:		bx	= admin file
		sidi	= MailboxMessage
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating
DESTROYED:	si, di, dx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSelectMessagesCallback proc	far
		uses	ds
		.enter	inherit	MLRescan
		movdw	dxax, sidi
		lds	si, ss:[listObj]

		pushdw	ss:[scanRoutines].MLSR_select
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		mov	ss:[listObj].segment, ds
		clc
		.leave
		ret
MLSelectMessagesCallback		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageListAddMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a message & address to the end of the list being built up

CALLED BY:	(EXTERNAL) subclass selection callback
PASS:		*ds:si	= MessageList
		bx	= admin file
		ss:bp	= MLMessage (only those fields that are used in
				comparison by subclass need to be valid,
				except MLM_message and MLM_address which have
				to be valid)
RETURN:		*ds:si	= still the MessageList (ds fixed up)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageListAddMessage proc	far
		uses	di, si, ax, cx, dx, es
		class	MessageListClass
		.enter
		Assert	objectPtr, dssi, MessageListClass
	;
	; Fetch the array handle.
	; 
		DerefDI	MessageList
		ornf	ds:[di].MLI_attrs, mask MLA_MODIFIED
		mov	si, ds:[di].MLI_messages
		Assert	chunk, si, ds
	;
	; Add an entry to the thing & stuff in the registers
	; 
		call	ChunkArrayAppend
		segmov	es, ds
		movdw	dssi, ssbp
		mov	cx, size MLMessage
		rep	movsb
		segmov	ds, es
	;
	; Add another reference to the message so long as we have it in our
	; array.
	; 
		movdw	dxax, ss:[bp].MLM_message
		call	DBQAddRef
		.leave
		ret
MessageListAddMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSortMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort the array, using the sort routine returned by our 
		subclass

CALLED BY:	(INTERNAL) MLRescan,
			   MLUpdateList
PASS:		*ds:si	= MessageList object
		if _FXIP
			bx:ax	= vfptr/fptr of movable/fixed compare callback
				  (same as MLSR_compare)
		else
			ss:bp	= inherited frame
		endif
RETURN:		*ds:si	= MessageList object
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSortMessages	proc	near
if	not _FXIP
rescanFrame	local	word	push bp
endif
sortParams	local	QuickSortParameters
		class	MessageListClass
		uses	si, di
		.enter
		Assert	objectPtr, dssi, MessageListClass
	;
	; Set the callback functions to be used for comparison.
	; 
if	_FXIP
	    ; Since the kernel must also be XIP'ed, ArrayQuickSort can handle
	    ; the vfptr callback from subclass.
		movdw	ss:[sortParams].QSP_compareCallback, bxax
else
	    ; We don't know if the kernel is XIP'ed, so ArrayQuickSort may
	    ; or may not be able to handle vfptr callbacks.  Hence we use our
	    ; callback to call the subclass callback vfptr.
		mov	ss:[sortParams].QSP_compareCallback.segment,
				cs
		mov	ss:[sortParams].QSP_compareCallback.offset,
				offset MLCompareCallback
	    ;
	    ; Pass the MLRescan frame in bx to our callback
	    ; 
		mov	bx, ss:[rescanFrame]
endif	; _FXIP
		clr	ax		; for czr
		czr	ax, ss:[sortParams].QSP_lockCallback.segment
		czr	ax, ss:[sortParams].QSP_unlockCallback.segment
	;
	; I have no idea of better values for these, so we'll just go with the
	; defaults.
	; 
		mov	ss:[sortParams].QSP_insertLimit, 
				DEFAULT_INSERTION_SORT_LIMIT
		mov	ss:[sortParams].QSP_medianLimit,
				DEFAULT_MEDIAN_LIMIT
	;
	; Get to the message array.
	; 
		DerefDI	MessageList
		mov	si, ds:[di].MLI_messages
	;
	; Load up the parameters from the ChunkArrayHeader
	; 
		mov	si, ds:[si]
		mov	ax, ds:[si].CAH_elementSize
		mov	cx, ds:[si].CAH_count
		add	si, ds:[si].CAH_offset
	;
	; Sort the thing.
	; 
		call	ArrayQuickSort
		.leave
		ret
MLSortMessages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLCompareCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two entries for sorting in ascending order.

CALLED BY:	(INTERNAL) MLSortMessages via ArrayQuickSort
PASS:		ds:si	= first element
		es:di	= second element (ds = es)
		bx	= frame inherited from MLRescan
RETURN:		flags set so caller can jl, je or jg according as the first 
			element is less than, equal to, or greater than the
			second
DESTROYED:	ax, bx, cx, dx, di, si
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		call the callback

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	not _FXIP
MLCompareCallback proc	far
		uses	bp
		.enter	inherit MLRescan
		mov	bp, bx		; ss:bp <- inherited frame
	;
	; Call the callback function as efficiently as possible.
	; 
		movdw	bxax, ss:[scanRoutines].MLSR_compare
		call	ProcCallFixedOrMovable
		.leave
		ret
MLCompareCallback endp
endif	; not _FXIP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGenDynamicListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the moniker for a list entry.

CALLED BY:	MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= MessageList
		ds:di	= MessageListInstance
		^lcx:dx	= MessageList
		bp	= index of item requested
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGenDynamicListQueryItemMoniker method dynamic MessageListClass, 
					MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		.enter
	;
	; Point to the relevant entry in the message+address array.
	; 
		mov	ax, bp			; ax <- array index
		push	si
		mov	si, ds:[di].MLI_messages
		tst	si
		jz	outOfBounds
		Assert	chunk, si, ds
		call	ChunkArrayElementToPtr
		jnc	prepareForCreate

outOfBounds:
	;
	; The requested index is beyond the number of entries in our array,
	; so just drop the request on the floor.
	; 
		pop	si
		jmp	done

prepareForCreate:
	;
	; Create a moniker for just the address (and its duplicates) in this
	; entry. If we have no search criteria, it means we're in all-view mode
	; 
		movdw	cxdx, ds:[di].MLM_message
		mov	bp, ds:[di].MLM_address
		pop	si
		push	ax				; save item #
		mov	ax, MSG_ML_GENERATE_MONIKER
		call	ObjCallInstanceNoLock		; *ds:ax <- moniker
		pop	bp				; bp <- item #
	;
	; Save the width and height for comparing to existing HINT_MINIMUM_SIZE
	; 
		mov	bx, ax
		mov	bx, ds:[bx]
		push	ds:[bx].VM_width,
			({VisMonikerGString}ds:[bx].VM_data).VMGS_height
	;
	; Set the moniker as that for the entry.
	; 
		mov_tr	dx, ax
		mov	cx, ds:[LMBH_handle]
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		push	dx
		call	ObjCallInstanceNoLock
	;
	; Free the created moniker (which, alas, will have been copied by the
	; dynamic list code)
	; 
		pop	ax
		call	LMemFree
	;
	; Adjust the HINT_MINIMUM_SIZE to be large enough to accomodate a single
	; entry of the maximum size we've seen so far.
	; 
		pop	cx, dx		; cx <- width of new moniker
					; dx <- height of new moniker
		mov	ax, HINT_MINIMUM_SIZE
		call	ObjVarFindData
		jnc	setNewSize
		cmp	ds:[bx].CSHA_width, cx
		jb	tooNarrow
		mov	cx, ds:[bx].CSHA_width	; cx <- larger width
		cmp	ds:[bx].CSHA_height, dx
		jae	done
setNewSize:
		call	MLSetMinimumSize
done:
		.leave
		ret

tooNarrow:
	;
	; List is definitely too narrow. Make sure the height is as large as
	; it needs to be.
	; 
		cmp	ds:[bx].CSHA_height, dx
		jae	setNewSize
		mov	dx, ds:[bx].CSHA_height
		jmp	setNewSize
MLGenDynamicListQueryItemMoniker endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGenerateMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the moniker for the passed message.

CALLED BY:	MSG_ML_GENERATE_MONIKER
PASS:		*ds:si	= MessageList object
		ds:di	= MessageListInstance
		cxdx	= MailboxMessage
		bp	= address #
RETURN:		*ds:ax	= moniker to use
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGenerateMoniker method dynamic MessageListClass, MSG_ML_GENERATE_MONIKER
if	_CONTROL_PANELS
		.enter

		MovMsg	dxax, cxdx			; dxax <- message
		mov	cx, bp				; cx <- talID
		ornf	cx, mask TID_ADDR_INDEX		;  ... by index
		mov	bx, mask MMF_INCLUDE_DUPS
		tst	ds:[di].MLI_primaryCriteria	; are we in ALL_VIEW
							;  mode?
		jnz	createMoniker			; => no
		ornf	bx, mask MMF_ALL_VIEW
createMoniker:
		call	MessageCreateMoniker

		.leave
		ret
else
		ERROR	MESSAGE_LIST_SUBCLASS_MUST_INTERCEPT_THIS
endif	; _CONTROL_PANELS
MLGenerateMoniker endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust our minimum size to be appropriate to the sizes used
		to create the monikers we use.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= MessageList object
		ds:di	= MessageListInstance
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	HINT_MINIMUM_SIZE is added before we call our superclass

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSpecBuild	method dynamic MessageListClass, MSG_SPEC_BUILD
		call	MLSetInitialMinimumSize

		mov	ax, MSG_SPEC_BUILD
		mov	di, offset MessageListClass
		GOTO	ObjCallSuperNoLock
MLSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSetInitialMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Specify our minimum size to be a single line-height

CALLED BY:	(INTERNAL) MLSpecBuild, MLSetCriteria
PASS:		*ds:si	= MessageList object
RETURN:		nothing
DESTROYED:	ax, di, bp, dx, cx, bx
SIDE EFFECTS:	HINT_MINIMUM_SIZE is set on the object, corresponding to
			a single line, as determined by MessageEnsureSizes

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSetInitialMinimumSize proc	near
		uses	bp
		.enter
		mov	ax, MSG_ML_GET_INITIAL_MINIMUM_SIZE
		call	ObjCallInstanceNoLock
		mov	ax, cx
		or	ax, dx
		jz	done		; => both are zero, so do nothing
	;
	; Set HINT_MINIMUM_SIZE on ourselves to match.
	; 
		call	MLSetMinimumSize
done:
		.leave
		ret
MLSetInitialMinimumSize endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLSetMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ourselves to adjust/set the HINT_MINIMUM_SIZE.

CALLED BY:	(INTERNAL) MLSetInitialMinimumSize, 
			   MLGenDynamicListQueryItemMoniker
PASS:		*ds:si	= MessageList
		cx	= width
		dx	= height
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	geometry recalculated

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLSetMinimumSize proc	near
		class	MessageListClass
		.enter
			CheckHack <SSA_updateMode eq SetSizeArgs-2>
		mov	di, VUM_NOW
		push	di
			CheckHack <SSA_count eq SetSizeArgs-4>
		mov	di, 1
		push	di
			CheckHack <SSA_height eq SetSizeArgs-6>
		push	dx
			CheckHack <SSA_width eq SetSizeArgs-8>
		push	cx
			CheckHack <SetSizeArgs eq 8>
		mov	bp, sp
		mov	dx, size SetSizeArgs
		mov	ax, MSG_GEN_SET_MINIMUM_SIZE
		call	ObjCallInstanceNoLock
		add	sp, size SetSizeArgs
		.leave
		ret
MLSetMinimumSize endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetInitialMinimumSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the default minimum size for an item in the list.

CALLED BY:	MSG_ML_GET_INITIAL_MINIMUM_SIZE
PASS:		*ds:si	= MessageList object
		ds:di	= MessageListInstance
RETURN:		cx	= default width
		dx	= default height
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetInitialMinimumSize method dynamic MessageListClass, 
					MSG_ML_GET_INITIAL_MINIMUM_SIZE
if	_CONTROL_PANELS
		.enter
	;
	; Fetch the width & line-height of the monikers.
	; 
		call	MessageEnsureSizes	; ax <- width, bx <- line height
		mov_tr	cx, ax
		mov_tr	dx, bx
		.leave
		ret
else
		ERROR	MESSAGE_LIST_SUBCLASS_MUST_INTERCEPT_THIS
endif	; _CONTROL_PANELS
MLGetInitialMinimumSize endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLGetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a message number into a message + address

CALLED BY:	MSG_ML_GET_MESSAGE
PASS:		*ds:si	= MessageList
		ds:di	= MessageListInstance
		cx	= message # (must be in-range, else fatal-error)
RETURN:		cxdx	= MailboxMessage
		bp	= address # (valid only if list is for outbox)
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLGetMessage	method dynamic MessageListClass, MSG_ML_GET_MESSAGE
		.enter
		mov	si, ds:[di].MLI_messages
		Assert	chunk, si, ds
		mov_tr	ax, cx		; ax <- message #
		call	ChunkArrayElementToPtr
EC <		ERROR_C INVALID_MESSAGE_NUMBER				>
		movdw	cxdx, ds:[di].MLM_message
		mov	bp, ds:[di].MLM_address
		.leave
		ret
MLGetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLUpdateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Include the new message, if reasonable, or remove the old
		message, if we were showing it.

CALLED BY:	MSG_ML_UPDATE_LIST
PASS:		*ds:si	= MessageList object
		ds:di	= MessageListInstance
		cxdx	= new/removed message (bit 0 of dx set if skip sorting)
		bp	= MABoxChange
RETURN:		carry set if list is newly empty
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLUpdateList	method dynamic MessageListClass, MSG_ML_UPDATE_LIST
changeType	local	MABoxChange	push bp
	;
	; NOTE: THESE DECLARATIONS MUST MATCH THOSE IN MLRescan
	; 
scanRoutines	local	MLScanRoutines
listObj		local	fptr
curSelection	local	MLMessage
skipSorting	local	byte		; bit 0 set if skip sorting
	ForceRef	scanRoutines	; used in MLGetRoutines and others
	ForceRef	listObj		; used in MLSelectMessages
		.enter
EC <		call	ECMLValidateCriteria				>
		Assert	chunk, ds:[di].MLI_messages, ds

		andnf	ds:[di].MLI_attrs, not mask MLA_MODIFIED
		
		mov	ss:[skipSorting], dl
		andnf	dl, not 0x1	; cxdx = MailboxMessage
		pushdw	cxdx		; save message to check

	;
	; Record the currently-selected message, if there is one, so it can
	; remain selected after the update.
	;
		push	bp
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jnc	haveSelection
		clr	cx		; cx <- no selection
		jmp	recordSelection
haveSelection:
		mov_tr	cx, ax
		mov	ax, MSG_ML_GET_MESSAGE
		call	ObjCallInstanceNoLock
recordSelection:
		mov	bx, bp
		pop	bp
		movdw	ss:[curSelection].MLM_message, cxdx
		mov	ss:[curSelection].MLM_address, bx
	;
	; Fetch the routines from the subclass.
	; 
		call	MLGetRoutines
	;
	; Store the list object for MLSelectMessagesCallback
	; 
		movdw	ss:[listObj], dssi
	;
	; If the change type is anything but MACT_EXISTS, we consider the
	; message to have been deleted, as we're not supposed to show messages
	; currently being transmitted. (in theory...)
	;
		mov	ax, ss:[changeType]
		andnf	ax, mask MABC_TYPE
		cmp	ax, MACT_EXISTS shl offset MABC_TYPE
		jne	removed
	;
	; Make sure the message is still in the queue it's supposed to be in.
	; When a message gets canceled, we get notification that the thing
	; exists when the talID is set back to 0, even though the thing's not
	; actually in the outbox for real...
	;
		DerefDI	MessageList
		call	MLGetQueue	; ^vbx:di <- queue
		popdw	dxax
		call	MessageCheckIfValid
		jc	checkResult	; => message gone, so do nothing.
		call	DBQCheckMember
		jnc	checkResult	; => not in the queue, so do nothing.
					;  we assume it's not in our list
					;  already...
		pushdw	dxax
	;
	; Make sure this isn't just notification that a message we already know
	; about has gone back to existing.
	;
		mov	ax, ss:[changeType]
		call	MLCheckAlreadyKnown
		popdw	sidi		; sidi <- message to check
		jc	checkResult	; => already known, so do nothing

	;
	; Call what's normally a callback routine to call the subclass's
	; callback to add any interesting addresses to the list.
	; 
		call	MailboxGetAdminFile	; bx <- file
		call	MLSelectMessagesCallback
checkResult:
	;
	; Now see if the list changed
	; 
		lds	si, ss:[listObj]
		DerefDI	MessageList

		test	ds:[di].MLI_attrs, mask MLA_MODIFIED
		jz	done
	;
	; Skip sorting if we are told to.
	;
		test	ss:[skipSorting], 0x1
		jnz	afterSort
	;
	; Resort the list, please, and tell ourselves the new number of
	; messages.
	; 
FXIP <		movdw	bxax, ss:[scanRoutines].MLSR_compare		>
		call	MLSortMessages
afterSort:
		call	MLSetNumMessages	; cx <- # messages

		stc			; assume empty
		jcxz	done
		clc
done:
		.leave
		ret

removed:
	;
	; Look through the message array, removing any element that holds
	; the message in question.
	; 
		popdw	cxdx		; cxdx <- removed message
		mov	bx, cs
		DerefDI	MessageList
		mov	si, ds:[di].MLI_messages
		mov	di, offset MLUpdateListRemovedCallback
		call	ChunkArrayEnum
		jmp	checkResult	; go check if anything removed, leaving
					;  old # entries on the stack...
MLUpdateList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLCheckAlreadyKnown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the message we've been told about is already in our
		list.

CALLED BY:	(INTERNAL) MLUpdateList
PASS:		ax	= MABoxChange
		on stack:	MailboxMessage of notification
RETURN:		carry set if already known
DESTROYED:	nothing
SIDE EFFECTS:	list is marked modified (MLA_MODIFIED) if message already 
     		known.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.model	medium, C
MLCheckAlreadyKnown proc near	msg:MailboxMessage
		uses	di, bx, cx, ax, es
		class	MessageListClass
		.enter
		DerefDI	MessageList
		push	si
		mov	si, ds:[di].MLI_messages
		mov	bx, SEGMENT_CS
		mov	di, offset checkExists
		mov	cx, ax
		andnf	cx, mask MABC_ADDRESS
		mov	dx, ss:[msg].high
		mov	bp, ss:[msg].low
		call	ChunkArrayEnum
		pop	si
		jnc	done
	;
	; Indicate already known, but also mark the list as modified so it
	; resorts, on the assumption this is a change of state for the
	; message.
	;
		DerefDI	MessageList
		ornf	ds:[di].MLI_attrs, mask MLA_MODIFIED
		stc
done:
		.leave
		ret

checkExists:
		cmp	ds:[di].MLM_message.high, dx
		jne	noMatch
		cmp	ds:[di].MLM_message.low, bp
		jne	noMatch
		cmp	cx, MABC_ALL
		je	match
		cmp	ds:[di].MLM_address, cx
		je	match
noMatch:
		clc
		retf
match:
	;
	; Update message state stored in our array.
	;
EC <		andnf	ax, mask MABC_TYPE				>
EC <		Assert	e, ax, <MACT_EXISTS shl offset MABC_TYPE>	>
		mov	ds:[di].MLM_state, MAS_EXISTS

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; There may be a new retry-time and we need to update our stored one.
	; We have to lock the message here, unfortunately.
	;
		movdw	essi, dsdi	; es:si = MLMessage
		mov	ax, bp		; dxax = MailboxMessage
		call	MessageLock
		jc	exit
		mov	di, ds:[di]
		movdw	es:[si].MLM_autoRetryTime, ds:[di].MMD_autoRetryTime,ax
		call	UtilVMUnlockDS
		segmov	ds, es
exit:
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

		stc
		retf
MLCheckAlreadyKnown endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MLUpdateListRemovedCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to see if a list entry is for a particular
		message and delete it, and our reference to the message, if
		it is.

CALLED BY:	(INTERNAL) MLUpdateList via ChunkArrayEnum
PASS:		*ds:si 	= message array
		ds:di	= MLMessage to check
		cxdx	= MailboxMessage being nuked
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx
		si, di (allowed by ChunkArrayEnum)
SIDE EFFECTS:	array elements may be deleted.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MLUpdateListRemovedCallback proc	far
		uses	cx, dx
		class	MessageListClass
		.enter	inherit	MLUpdateList
	;
	; See if it's the right message
	; 
		cmpdw	ds:[di].MLM_message, cxdx
		jne	done
	;
	; It is. See if it's the right address, handling MABC_ALL specially
	; 
		mov	ax, ss:[changeType]
		andnf	ax, mask MABC_ADDRESS
		cmp	ax, MABC_ALL shl offset MABC_ADDRESS
		je	nukeIt
		cmp	ds:[di].MLM_address, ax
		jne	done		; => not this entry
	;
	; It is. See if we need to consult the subclass before nuking the
	; entry.
	;
		mov	bx, si

		push	di
		mov	si, ss:[listObj].chunk
		DerefDI	MessageList
		test	ds:[di].MLI_attrs, mask MLA_CHECK_BEFORE_REMOVAL
		pop	di
		xchg	bx, si		; *ds:si <- array, *ds:bx <- list
		jz	nukeIt
	;
	; We must ask the subclass. Determine the current element number so
	; we can get back to the array entry after the method call.
	;
		call	ChunkArrayPtrToElement
		xchg	bx, si
	;
	; Call the subclass, please
	;
		push	bp, ax
		mov	bp, ss:[changeType]
		mov	ax, MSG_ML_CHECK_BEFORE_REMOVAL
		call	ObjCallInstanceNoLock
		mov	si, bp			; si <- new addr #
		pop	bp, ax
	;
	; Point back to the list element before checking result, as we'll need
	; it in either case.
	;
		pushf
		xchg	bx, si			; *ds:si <- message array,
						; bx <- new addr #
		call	ChunkArrayElementToPtr
		popf
		jnc	nukeIt
	;
	; Set new address & state for the entry and mark the list as modified.
	;
		mov	ds:[di].MLM_address, bx
			CheckHack <offset MABC_TYPE ge 8>
		mov	al, ss:[changeType].high
		mov	cl, offset MABC_TYPE - 8
			CheckHack <offset MABC_TYPE + width MABC_TYPE eq 16>
		shr	al, cl		; al = MAChangeType
		Assert	ne, al, MACT_EXISTS
			CheckHack <MAS_QUEUED eq MACT_QUEUED>
			CheckHack <MAS_PREPARING eq MACT_PREPARING>
			CheckHack <MAS_READY eq MACT_READY>
			CheckHack <MAS_SENDING eq MACT_SENDING>
		mov	ds:[di].MLM_state, al
		jmp	setModified
nukeIt:
	;
	; This element is for the message that just went bye-bye, so remove our
	; reference to the message.
	; 
		MovMsg	dxax, cxdx
		call	MailboxGetAdminFile
		call	MessageCheckIfValid
		jc	arrayDel		; => message already gone
		call	DBQDelRef
arrayDel:
	;
	; Nuke the element from the array.
	; 
		call	ChunkArrayDelete
setModified:
	;
	; Flag list as modified, so caller rebuilds.
	;
		mov	si, ss:[listObj].chunk
		DerefDI	MessageList
		ornf	ds:[di].MLI_attrs, mask MLA_MODIFIED
done:
		clc
		.leave
		ret
MLUpdateListRemovedCallback endp

MessageList	ends
