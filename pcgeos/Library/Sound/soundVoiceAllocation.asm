COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System	
MODULE:		Sound Library Voice Manager
FILE:		soundVoiceAllocation.asm

AUTHOR:		Todd Stumpf, Sep 10, 1992

ROUTINES:
	Name				Description
	----				-----------
GLOBAL	SoundVoiceInitilaize		Set up voice manager for system
GLOBAL	SoundVoiceDetach		Remove voice from system

GLOBAL	SoundVoiceGetFree		Request a free or lower priority voice
GLOBAL	SoundVoiceFree			Place voice on free list
GLOBAL	SoundVoiceActivate		Place voice on active list
GLOBAL	SoundVoiceDeactivate		Remove voice from active list
GLOBAL	SoundVoiceAssign		Associate a voice with a sound

GLOBAL	SoundDACGetFree			Request a free or lower priority DAC
GLOBAL	SoundDACFree			Place DAC on free list
GLOBAL	SoundDACActivate		Place DAC on active list
GLOBAL	SoundDACDeactivate		Remove a DAC from active list
GLOBAL	SoundDACAssign			Associate a DAC with a sound

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/10/92		Initial revision


DESCRIPTION:
	These are all the routines which are need to allow the
	library to dynamically allocate voices and DACS to the
	various streams as needed.

	Basically, the scheme goes something like this:

		The library maintains two linked lists.  The first
	list contains the voices which are currently free.  When a
	voice is needed, it is removed from the front of the
	list.  When a voice is freed up, it is placed on the
	end of the list.  This means that a voice will have the longest
	possible chance for the release section of its envelope to
	finish.

		For DACs, a similar list is kept, but DACs are
	added to the front and removed from the front since a
	free DAC is a quiet DAC.

		The second list contains those voices which are
	currently sounding.  The list is sorted according to the
	priority of the note, any voice will equal or more priority
	than any voice coming after it.  When a voice gets allocated
	to a stream and begins sounding, it is added to the list
	at the head of all the other voices sounding at its priority.
	This allows a stream which finds all the voices used up to
	examine the end of the sounding list.  If the note is of
	less urgency that the stream, it can take the voice and use it.

		In this case, the DAC list is structured the same,
	most important to the front, oldest DAC first.

		This ensures that only the "oldest" note gets ursurped.
	And should the last note be of more priority, the stream need
	not do any more looking.


	$Id: soundVoiceAllocation.asm,v 1.1 97/04/07 10:46:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------
;		Dynamic Voice Allocation Structures
;-----------------------------------------------------------------------------
	;	1) The stream ID currently using the voice.
	;	2) The priority of the stream using the voice.
	;	3) Which stream voice is currently using this voice
VoiceStatusNode		struct
	VSN_next	word		; offset of next node in list
	VSN_priority	word		; priority
	VSN_owner	word		; segment of sound which owns voice
	VSN_voice	word		; Stream's voice #
VoiceStatusNode		ends

	;
	;  When dealing with the linked lists of voices, we need to be
	;  able to determine, at a glance, what the status of the voice is.
	;  For a voice in use, this is easy, but for a voice not in use,
	;  we need some special constants.
END_OF_LIST		equ	0ffffh		; marks no next voice
NO_STREAM		equ	0		; marks un-used voice
NO_PRIORITY		equ	0ffffh		; marks un-used voice
NO_TONE			equ	0		; marks un-used voice
NO_VOICE		equ	0ffh		; marks un-used voice

	;
ListHeadTail		struct
	LHT_head	word			; offset to head of list
	LHT_tail	word			; offset to tail of list
ListHeadTail		ends


idata		segment
	;
	;  The two linked lists previously mentioned.
	voiceHandle	word			; handle for voiceBlock
	voiceBlock	word			; fixed block for voice lists
	voiceActiveList	ListHeadTail	<END_OF_LIST,
					 END_OF_LIST>	; active list of voices
	DACActiveList	ListHeadTail	<END_OF_LIST,
					 END_OF_LIST>	; active list of DACs
idata		ends

udata		segment
	voiceFreeList	ListHeadTail		; free list of voices
	DACFreeList	ListHeadTail		; free list of DACs
udata		ends


InitCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceInitialize, SoundVoiceInitializeFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes voice allocation/deallocation of sound library

CALLED BY:	SoundEntry
PASS:		nothing
RETURN:		carry clear if ok,
		carry set and library mutEx grabbed on error.
DESTROYED:	nothing
SIDE EFFECTS:	
		allocates a block on the global heap.

PSEUDO CODE/STRATEGY:
		allocate a block.
		Init all the voices.
		return		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode	eq	8
SoundVoiceInitialize	proc	near
	uses	ax, bx, cx, es, ds, si
	.enter
	;
	;  get our hands on the dgroup
	mov	ax, segment dgroup		; ax <- dgroup of lib
	mov	ds, ax				; ds <- dgroup of lib

	;
	;  allocate enough space to hold all our nodes
	mov	ax, ds:[driverVoices]		; ax <- # of voices
	add	ax, ds:[driverDACs]		; ax <- + # of DACs

	;
	;  Do we even have any voices?
	LONG jz	done

	shl	ax, 1				; ax <- ax * 2
	shl	ax, 1				; ax <- ax * 4
	shl	ax, 1				; ax <- ax * 8 (size VSN)

	mov	cx, mask HF_FIXED or (mask HAF_ZERO_INIT) shl 8
	call	MemAlloc
	jc	error

	mov	ds:[voiceHandle], bx		; save handle
	mov	ds:[voiceBlock], ax		; save segment

	segmov	es, ds, ax			; es <- dgroup

initVoices::
	clr	si				; si <- 1st voice
	mov	cx, ds:[driverVoices]		; cx <- # of voices
	mov	ds:[voiceFreeList].LHT_head, END_OF_LIST
	mov	ds:[voiceFreeList].LHT_tail, END_OF_LIST

	tst	cx
	jz	initDACs

	mov	ds:[voiceFreeList].LHT_head, si	; set to last node

	mov	ds, ds:[voiceBlock]		; ds <- voice segment

topOfVoiceLoop:
	mov	bx, si				; bx <- prev node
	add	si, size VoiceStatusNode	; si <- next node
	mov	ds:[bx].VSN_next, si		; save next field
	loop	topOfVoiceLoop
	mov	ds:[bx].VSN_next, END_OF_LIST	; mark end of list

	mov	es:[voiceFreeList].LHT_tail, bx	; mark last node

EC<	call	SoundVoiceVerifyListsFar			>

initDACs:
	mov	cx, es:[driverDACs]		; cx <- # of DACs
	mov	es:[DACFreeList].LHT_head, END_OF_LIST
	mov	es:[DACFreeList].LHT_tail, END_OF_LIST

	tst	cx
	jz	done

	mov	es:[DACFreeList].LHT_head, si	; set to last node
topOfDACLoop:
	mov	bx, si				; bx <- prev node
	add	si, size VoiceStatusNode	; si <- next node
	mov	ds:[bx].VSN_next, si		; save next field
	loop	topOfDACLoop
	mov	ds:[bx].VSN_next, END_OF_LIST	; mark end of list

	mov	es:[DACFreeList].LHT_tail, bx	; mark last node

EC<	call	SoundDACVerifyListsFar				>

	clc					; carry is clear
done:
	.leave
	ret
error:
	;
	;  Erk.  We tried to allocate space and we couldn't.
	;  mark sound semaphore as unavailable and return with carry set

	clr	ds:[exclusiveSemaphore].Sem_value
	mov	ds:[exclusiveAccess], 1
	clr	ds:[voiceHandle]

	stc					; can use the library
	jmp	short	done
SoundVoiceInitialize	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceDetach, SoundVoiceDetachFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up the block

CALLED BY:	SoundEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		frees up a block from global memory

PSEUDO CODE/STRATEGY:
		load in block handle and call MemFree		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundVoiceDetach	proc	near
	uses	ax, bx, ds
	.enter
	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	ds, ax				; ds <- dgroup of library

	mov	bx, ds:[voiceHandle]		; bx <- handle of block

	tst	bx				; do we have voiceBlock?
	jz	done

	call	MemFree				; free up the block
done:
	.leave
	ret
SoundVoiceDetach	endp

InitCode	ends

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceGetFree, SoundVoiceGetFreeFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the next available voice from either list

CALLED BY:	INTERNAL

PASS:		ax	-> priority for new voice
		INTERRUPTS OFF

RETURN:		cx	<- physical voice # allocated
				- or -
		carry set on no voice available

DESTROYED:	nothing
SIDE EFFECTS:
		removes either the lead node from the free list, or
		if the free list is empty, from the active list.

PSEUDO CODE/STRATEGY:
		check free list, if not empty, take head of node.
		if empty, check active list, if head node of less
		priority, take it, otherwise, set carry and return.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode	eq	8
	.assert size SoundVoiceStatus	eq	8
SoundVoiceGetFreeFar	proc	far
	call	SoundVoiceGetFree
	ret
SoundVoiceGetFreeFar	endp
public	SoundVoiceGetFreeFar

SoundVoiceGetFree	proc	near
	uses	ax, bx, si, di, ds, es
	.enter
EC<	pushf				; bx <- current flags	>
EC<	pop	bx						>
EC<	test	bx, mask CPU_INTERRUPT	; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED	>

EC<	call	SoundVoiceVerifyLists				>

	mov	bx, segment dgroup		; bx <- dgroup of library
	mov	ds, bx				; ds <- dgroup of library

	mov	es, ds:[voiceBlock]		; es <- voice block segment

EC<	tst	ds:[voiceBlock]					>
EC<	ERROR_Z	SOUND_VOICE_MANAGER_CALLED_WITH_NO_VOICES	>

	mov	si, offset voiceFreeList	; si <- free list

	mov	di, ds:[si].LHT_head		; di <- head of free list

	cmp	di, END_OF_LIST			; is free list empty?
	je	checkActiveList

updateNodes:
	mov	es:[di].VSN_priority, ax	; assign priority to node
	mov	ax, es:[di].VSN_next		; ax <- next node in free list
	mov	ds:[si].LHT_head, ax		; update free list header
	mov	es:[di].VSN_next, END_OF_LIST	; remove new node from list

	cmp	ds:[si].LHT_tail, di		; is this node, the last node?
	je	cleanUpEndOfList

calculateVoiceNumber:
	shr	di, 1				; di <- di / 2
	shr	di, 1				; di <- di / 4
	shr	di, 1				; di <- di / size VoiceStatusN.
	mov	cx, di				; cx <- physical voice #
done:
	.leave
	ret

checkActiveList:
	mov	si, offset voiceActiveList
	mov	di, ds:[si].LHT_head		; es:di <- least priority voice
	cmp	di, END_OF_LIST
	je	activeListEmpty

	cmp	ax, es:[di].VSN_priority	; how do we stack up?
	jb	notifyOldOwner

activeListEmpty:
	;
	;  The free list was empty, and the lowest priority voice is
	;  still more important than the new one.  Sorry.
	stc
	jmp	short	done

notifyOldOwner:
	;	
	;  We are going to ursurp the oldest, least urgent voice
	;  around.  To ensure he does not play on our voice, we
	;  re-set his voice setting to NO_VOICE
	mov	cx, ds				; cx <- dgroup
	mov	ds, es:[di].VSN_owner		; ds <- segment of owner
	mov	bx, es:[di].VSN_voice		; bx <- owner's voice #
	shl	bx, 1				; bx <- bx * 2
	shl	bx, 1				; bx <- bx * 4
	shl	bx, 1				; bx <- bx * 8 (size SVS)
	add	bx, offset SC_voice		; bx <- voice's offset
						; set voice to no-voice
	mov	ds:[bx].SVS_physicalVoice, NO_VOICE
	mov	ds, cx				; ds <- dgroup
	jmp	short	updateNodes

cleanUpEndOfList:	
	mov	ds:[si].LHT_tail, END_OF_LIST	; mark list as empty
	jmp	short calculateVoiceNumber

SoundVoiceGetFree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceFree, SoundVoiceFreeFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move an unatached node to the end of the free list

CALLED BY:	INTERNAL

PASS:		cx	-> physical voice to add to free list
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		connects the node to the end of the free list

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode		eq	8
SoundVoiceFreeFar	proc	far
	call	SoundVoiceFree
	ret
SoundVoiceFreeFar	endp
public	SoundVoiceFreeFar

SoundVoiceFree	proc	near
	uses	ax,cx,di,ds,es
	.enter
EC<	pushf				; ax <- current flags	>
EC<	pop	ax						>
EC<	test	ax, mask CPU_INTERRUPT	; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED	>

EC<	call	SoundVoiceVerifyLists				>

	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	ds, ax				; ds <- dgroup of library

EC<	cmp	cx, ds:[driverVoices]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	mov	es, ds:[voiceBlock]		; es <- voice block segment
	mov	di, ds:[voiceFreeList].LHT_tail	; di <- last node in list

	shl	cx, 1				; cx <- cx * 2
	shl	cx, 1				; cx <- cx * 4
	shl	cx, 1				; cx <- cx * (size VSN)

	cmp	di, END_OF_LIST			; is free list empty?
	jne	addToEndOfList			; if not, jump

	;
	;  mark node as first and last node
	mov	ds:[voiceFreeList].LHT_tail, cx	; mark as last node
	mov	ds:[voiceFreeList].LHT_head, cx	; mark as next node
done:
	.leave
	ret

addToEndOfList:
	mov	es:[di].VSN_next, cx		; last.next = new node
	mov	ds:[voiceFreeList].LHT_tail, cx	; free.tail = new node
	jmp	short done

SoundVoiceFree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceActivate, SoundVoiceActivateFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place a free node on to the active list in the right place

CALLED BY:	INTERNAL

PASS:		cx	-> voice # of free node
		ax	-> priority for voice
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		adds node to the active list.

PSEUDO CODE/STRATEGY:
		traverse list until we see that the next node will
		be of higher priority.  Then we add in the voice there.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode		eq	8
SoundVoiceActivateFar	proc	far
	call	SoundVoiceActivate
	ret
SoundVoiceActivateFar	endp
public	SoundVoiceActivateFar

SoundVoiceActivate	proc	near
	uses	ax,bx,si,di,ds,es
	.enter
	push	ax
EC<	pushf				; ax <- current flags	>
EC<	pop	ax						>
EC<	test	ax, mask CPU_INTERRUPT		; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED	>

EC<	call	SoundVoiceVerifyLists				>

	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	es, ax				; es <- dgroup of library

EC<	cmp	cx, es:[driverVoices]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	mov	di, cx				; si <- voice #
	shl	di, 1				; si <- si * 2
	shl	di, 1				; si <- si * 4
	shl	di, 1				; si <- si * 8 (size VSN)

	mov	ds, es:[voiceBlock]		; ds <- segment of voice block

	pop	ds:[di].VSN_priority

	mov	si, es:[voiceActiveList].LHT_head; si <- 1st active node

	cmp	si, END_OF_LIST			; is list empty?
	je	addToEmptyList

	;
	;  See if we add to the head of the list
	mov	bx, si				; bx <- current head of list
	cmp	ax, ds:[si].VSN_priority
	jb	addToHeadOfList

topOfLoop:
	mov	bx, si				; bx <- node in front of slot
	mov	si, ds:[si].VSN_next		; si <- next node

	cmp	si, END_OF_LIST			; have we reach the end?
	je	addToEndOfList

	cmp	ax, ds:[si].VSN_priority	; is next node more important?
	jae	insertBetweenBXAndSI

	mov	bx, si				; bx <- previous node
	jmp	short topOfLoop

insertBetweenBXAndSI:
	mov	ds:[bx].VSN_next, di		; place our node next
	mov	ds:[di].VSN_next, si		; hook up list structure
done:
	.leave
	ret

addToEndOfList:
	mov	es:[voiceActiveList].LHT_tail, di	; mark as last node
	jmp	short insertBetweenBXAndSI

addToHeadOfList:
	mov	es:[voiceActiveList].LHT_head, di	; mark as first node
	mov	ds:[di].VSN_next, bx		; connect with oldhead
	jmp	short done

addToEmptyList:
	mov	es:[voiceActiveList].LHT_head, di	; mark as first node
	mov	es:[voiceActiveList].LHT_tail, di	; mark as last node
	mov	ds:[di].VSN_next, END_OF_LIST	; mark end of list
	jmp	short done
SoundVoiceActivate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceDeactivate, SoundVoiceDeactivateFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a node from the active list

CALLED BY:	INTERNAL

PASS:		cx	-> physical voice #
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		removes a node from the active list

PSEUDO CODE/STRATEGY:
		traverse list until next node is the one we want, then
		remove it and clean up the rough edges
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC<	udata	segment			>
EC<		loopCount	word 0	>
EC<	udata	ends			>

SoundVoiceDeactivateFar	proc	far
	call	SoundVoiceDeactivate
	ret
SoundVoiceDeactivateFar	endp
public	SoundVoiceDeactivateFar

SoundVoiceDeactivate	proc	near
	uses	ax,bx,cx,si,ds,es
	.enter
	;
	;  Verify Interrupts are disabled
EC<	pushf					; ax <- current flags	>
EC<	pop	ax							>
EC<	test	ax, mask CPU_INTERRUPT		; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED		>

	;
	;  Verify the voice list has not been corrupted
EC<	call	SoundVoiceVerifyLists					>

	;
	;  Load up the library's dgroup
	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	es, ax				; es <- dgroup of library

	;
	;  Verify we are to act upon a legal voice
EC<	cmp	cx, es:[driverVoices]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	;
	;  Aquire a pointer to the voice
	mov	ds, es:[voiceBlock]		; ds <- segment of voice block

	shl	cx, 1				; cx <- cx * 2
	shl	cx, 1				; cx <- cx * 4
	shl	cx, 1				; cx <- cx * 8

	mov	si, es:[voiceActiveList].LHT_head ; si <- 1st node in list
	mov	bx, END_OF_LIST

	;
	;  Traverse the list until we find the
	;	voice on the active list.
EC<	clr	es:[loopCount]			; make sure we loop forever>
topOfLoop:
EC<	inc	es:[loopCount]						   >
EC<	ERROR_S	SOUND_CORRUPT_VOICE_LIST				   >

	cmp	si, END_OF_LIST			; have we reached the end?
	je	voiceNotActive

	cmp	si, cx				; is this the correct node?
	je	foundIt

	mov	bx, si				; save prev. node
	mov	si, ds:[si].VSN_next		; si <- next node
	jmp	short topOfLoop

foundIt:
	cmp	bx, END_OF_LIST			; were we the first node?
	je	removeFirstNode

	mov	ax, ds:[si].VSN_next		; ax <- node after ours
	mov	ds:[bx].VSN_next, ax		; close the gap

	mov	ds:[si].VSN_next, END_OF_LIST	; make it un-attached

checkForLastNode:
	cmp	cx, es:[voiceActiveList].LHT_tail; were we the last node?
	jne	done
	mov	es:[voiceActiveList].LHT_tail, bx; mark new end of list
done:
	.leave
	ret

voiceNotActive:
	stc					; something not right here...
	jmp	short done

removeFirstNode:
	mov	ax, ds:[si].VSN_next		; ax <- next 1st node
	mov	es:[voiceActiveList].LHT_head, ax; mark as head of list
	mov	ds:[si].VSN_next, END_OF_LIST	; make it un-attached
	mov	bx, END_OF_LIST			; "prev" node is end of list
	jmp	short checkForLastNode

SoundVoiceDeactivate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceAssign, SoundVoiceAssignFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pair up a physical voice with a stream voice

CALLED BY:	INTERNAL

PASS:		bx	-> SoundStreamStatus segment
		cx	-> physical voice #
		dx	-> stream voice #
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	modifies the voices in the sound stream status and
		modifies the voice status node

PSEUDO CODE/STRATEGY:
		Does no checking for currently active voice, priority
		or anything else.  If you use this routine to change
		the voice settings of a voice that is currently playing,
		things could get bad.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert		size VoiceStatusNode	eq	8
		.assert 	size SoundVoiceStatus	eq	8
SoundVoiceAssignFar	proc	far
	call	SoundVoiceAssign
	ret
SoundVoiceAssignFar	endp
public	SoundVoiceAssignFar

SoundVoiceAssign	proc	near
	uses	ax, si, di, es, ds
	.enter
EC<	pushf				; ax <- current flags	>
EC<	pop	ax						>
EC<	test	ax, mask CPU_INTERRUPT		; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED		>

EC<	call	SoundVoiceVerifyLists				>

	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	ds, ax				; ds <- dgroup of library

EC<	cmp	cx, ds:[driverVoices]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	mov	es, ds:[voiceBlock]		; es <- segment of voice block
	mov	ds, bx				; ds <- segment of stream
	
	mov	di, cx
	shl	di, 1				; di <- di * 2
	shl	di, 1				; di <- di * 4
	shl	di, 1				; di <- di * 8 (size VSN)

	mov	si, dx				; si <- stream voice #
	shl	si, 1				; si <- si * 2
	shl	si, 1				; si <- si * 4
	shl	si, 1				; si <- si * 8 (size SVS)

						; save physical voice
	mov	ds:SC_voice[si].SVS_physicalVoice, cx

	mov	es:[di].VSN_voice, dx		; save stream's voice
	mov	es:[di].VSN_owner, ds		; save stream's segment
	.leave
	ret
SoundVoiceAssign	endp

if ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundVoiceVerifyLists, SoundVoiceVerifyListsFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the Activate and Free lists are viable

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Verify legal head & tail pointers

		Verify no loops exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundVoiceVerifyListsFar	proc	far
	call	SoundVoiceVerifyLists
	ret
SoundVoiceVerifyListsFar	endp

SoundVoiceVerifyLists	proc	near
	uses	ax, bx, cx, si, ds, es
	.enter
	;
	;  Set up segment pointers
	mov	ax, segment dgroup
	mov	es, ax

	mov	ax, es:[voiceBlock]
	mov	ds, ax

	mov	bl, size VoiceStatusNode

	;
	;  Check for an empty free list
	mov	ax, es:[voiceFreeList].LHT_head
	cmp	ax, END_OF_LIST
	LONG je	verifyEmptyFreeList

	mov	si, es:[voiceFreeList].LHT_tail
	cmp	si, END_OF_LIST
	ERROR_E	SOUND_CORRUPT_VOICE_LIST

	cmp	ds:[si].VSN_next, END_OF_LIST
	ERROR_NE SOUND_CORRUPT_VOICE_LIST

checkActiveListHead:
	mov	ax, es:[voiceActiveList].LHT_head
	cmp	ax, END_OF_LIST
	LONG je	verifyEmptyActiveList

	mov	si, es:[voiceActiveList].LHT_tail
	ERROR_E	SOUND_CORRUPT_VOICE_LIST

	cmp	ds:[si].VSN_next, END_OF_LIST
	ERROR_NE SOUND_CORRUPT_VOICE_LIST

checkFreeListForLoop:
	mov	cx, es:[driverVoices]
	tst	cx
	jz	done

	;
	;  adjust cx so that it never falls through the
	;  loop statements unless we have traversed MORE
	;  VouceStatusNodes than we have voices
	inc	cx
	mov	si, es:[voiceFreeList].LHT_head

topOfFreeLoop:
	cmp	si, END_OF_LIST
	je	checkActiveListForLoop

	mov	ax, si

	;
	;  Determine if the next field of the
	;	voice is a valid next field
	div	bl		; al <- voice #, ah <- remainder

	;
	;  Are we pointing to the middle of a voice?
	tst	ah			; is remainder non-zero?
	ERROR_NZ SOUND_CORRUPT_VOICE_LIST

	;
	;  Are we pointing past the legal voices?
	clr	ah			; ax <- al (the voice #)
	cmp	ax, es:[driverVoices]
	ERROR_AE SOUND_CORRUPT_VOICE_LIST

	;
	;  SI gets the next field
	mov	si, ds:[si].VSN_next
	loop	topOfFreeLoop

	;
	;  We dropped through here, so we know there is an error
	ERROR	SOUND_CORRUPT_VOICE_LIST

checkActiveListForLoop:
	mov	si, es:[voiceActiveList].LHT_head

topOfActiveLoop:
	cmp	si, END_OF_LIST
	je	done

	mov	ax, si			; ax <- next field

	;
	;  Determine if the next field of the
	;	voice is a valid next field
	div	bl		; al <- voice #, ah <- remainder

	;
	;  Are we pointing to the middle of a voice?
	tst	ah			; is remainder non-zero?
	ERROR_NZ SOUND_CORRUPT_VOICE_LIST

	;
	;  Are we pointing past the legal voices?
	clr	ah			; ax <- al (the voice #)
	cmp	ax, es:[driverVoices]
	ERROR_AE SOUND_CORRUPT_VOICE_LIST


	mov	si, ds:[si].VSN_next
	loop	topOfActiveLoop

	;
	;  We dropped through here, so we know there is an error
	ERROR	SOUND_CORRUPT_VOICE_LIST
done:
	.leave
	ret

verifyEmptyFreeList:
	cmp	ax, es:[voiceFreeList].LHT_tail
	ERROR_NE SOUND_CORRUPT_VOICE_LIST
	jmp	checkActiveListHead

verifyEmptyActiveList:
	cmp	ax, es:[voiceActiveList].LHT_tail
	ERROR_NE SOUND_CORRUPT_VOICE_LIST
	jmp	checkFreeListForLoop
SoundVoiceVerifyLists	endp

endif

;-----------------------------------------------------------------------------
;
;	DAC list manipulation routines
;
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDACGetFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the next available DAC from either list

CALLED BY:	INTERNAL

PASS:		ax	-> priority for new DAC
		INTERRUPTS OFF

RETURN:		cx	<- physical DAC # allocated
				- or -
		carry set on no DAC available

DESTROYED:	nothing
SIDE EFFECTS:
		removes either the lead node from the free list, or
		if the free list is empty, from the active list.

PSEUDO CODE/STRATEGY:
		check free list, if not empty, take head of node.
		if empty, check active list, if head node of less
		priority, take it, otherwise, set carry and return.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode	eq	8
	.assert size SoundVoiceStatus	eq	8
SoundDACGetFree	proc	far
	uses	ax,bx,si,di,ds,es
	.enter
EC<	pushf				; bx <- current flags	>
EC<	pop	bx						>
EC<	test	bx, mask CPU_INTERRUPT	; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED	>

EC<	call	SoundDACVerifyLists				>

	mov	bx, segment dgroup		; bx <- dgroup of library
	mov	ds, bx				; ds <- dgroup of library

	mov	es, ds:[voiceBlock]		; es <- voice block segment
EC<	tst	ds:[voiceBlock]					>
EC<	ERROR_Z	SOUND_VOICE_MANAGER_CALLED_WITH_NO_VOICES	>

	mov	si, offset DACFreeList	; si <- free list

	mov	di, ds:[si].LHT_head		; di <- head of free list

	cmp	di, END_OF_LIST			; is free list empty?
	je	checkActiveList

updateNodes:
	mov	es:[di].VSN_priority, ax	; assign priority to node
	mov	ax, es:[di].VSN_next		; ax <- next node in free list
	mov	ds:[si].LHT_head, ax		; update free list header
	mov	es:[di].VSN_next, END_OF_LIST	; remove new node from list

	cmp	ds:[si].LHT_tail, di		; is this node, the last node?
	je	cleanUpEndOfList

calculateDACNumber:
	shr	di, 1				; di <- di / 2
	shr	di, 1				; di <- di / 4
	shr	di, 1				; di <- di / size VoiceStatusN.
	mov	cx, di				; cx <- # of DAC in list

	;
	;  This gives us the offset to the block in the
	;	list, but voices come before DACs, so
	;	to get the DAC #, we subtract the # of
	;	FM voices...
	sub	cx, ds:[driverVoices]		; cx <- physical DAC #

done:
	.leave
	ret

checkActiveList:
	mov	si, offset DACActiveList
	mov	di, ds:[si].LHT_head		; es:di <- least priority DAC
	cmp	di, END_OF_LIST
	je	activeListEmpty

	cmp	ax, es:[di].VSN_priority	; how do we stack up?
	jb	notifyOldOwner

activeListEmpty:
	;
	;  The free list was empty, and the lowest priority DAC is
	;  still more important than the new one.  Sorry.
	stc
	jmp	short	done

notifyOldOwner:
	;	
	;  We are going to ursurp the oldest, least urgent DAC
	;  around.  To ensure he does not play on our DAC, we
	;  re-set his DAC setting to NO_VOICE
	mov	cx, ds				; cx <- dgroup
	mov	ds, es:[di].VSN_owner		; ds <- segment of owner
	mov	bx, es:[di].VSN_voice		; bx <- owner's voice #
	shl	bx, 1				; bx <- bx * 2
	shl	bx, 1				; bx <- bx * 4
	shl	bx, 1				; bx <- bx * 8 (size SVS)
	add	bx, offset SC_voice		; bx <- voice's offset
						; set voice to no-voice
	mov	ds:[bx].SVS_physicalVoice, NO_VOICE
	mov	ds, cx				; ds <- dgroup
	jmp	short	updateNodes

cleanUpEndOfList:	
	mov	ds:[si].LHT_tail, END_OF_LIST	; mark list as empty
	jmp	short calculateDACNumber

SoundDACGetFree	endp
public	SoundDACGetFree

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDACFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move an unatached node to the end of the free list

CALLED BY:	INTERNAL

PASS:		cx	-> physical DAC to add to free list
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		connects the node to the end of the free list

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode		eq	8
SoundDACFree	proc	far
	uses	ax,cx,di,ds,es
	.enter
EC<	pushf				; ax <- current flags	>
EC<	pop	ax						>
EC<	test	ax, mask CPU_INTERRUPT	; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED	>

EC<	call	SoundDACVerifyLists				>

	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	ds, ax				; ds <- dgroup of library

EC<	cmp	cx, ds:[driverDACs]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	mov	es, ds:[voiceBlock]		; es <- voice block segment
	mov	di, ds:[DACFreeList].LHT_tail	; di <- last node in list

	add	cx, ds:[driverVoices]		; cx <- our VSN #
	shl	cx, 1				; cx <- cx * 2
	shl	cx, 1				; cx <- cx * 4
	shl	cx, 1				; cx <- cx * (size VSN)

	cmp	di, END_OF_LIST			; is free list empty?
	jne	addToEndOfList			; if not, jump

	;
	;  mark node as first and last node
	mov	ds:[DACFreeList].LHT_tail, cx	; mark as last node
	mov	ds:[DACFreeList].LHT_head, cx	; mark as next node
done:
	.leave
	ret

addToEndOfList:
	mov	es:[di].VSN_next, cx		; last.next = new node
	mov	ds:[DACFreeList].LHT_tail, cx	; free.tail = new node
	jmp	short done

SoundDACFree	endp
public SoundDACFree

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDACActivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place a free node on to the active list in the right place

CALLED BY:	INTERNAL

PASS:		cx	-> DAC # of free node
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		adds node to the active list.

PSEUDO CODE/STRATEGY:
		traverse list until we see that the next node will
		be of higher priority.  Then we add in the DAC there.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert	size VoiceStatusNode		eq	8
SoundDACActivate	proc	far
	uses	ax,bx,si,di,ds,es
	.enter
EC<	pushf				; ax <- current flags	>
EC<	pop	ax						>
EC<	test	ax, mask CPU_INTERRUPT		; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED	>

EC<	call	SoundDACVerifyLists				>

	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	es, ax				; es <- dgroup of library

EC<	cmp	cx, es:[driverDACs]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	mov	di, cx				; di <- dac #
	add	di, es:[driverVoices]		; di <- our VSN #
	shl	di, 1				; di <- di * 2
	shl	di, 1				; di <- di * 4
	shl	di, 1				; di <- di * 8 (size VSN)

	mov	ds, es:[voiceBlock]		; ds <- segment of voice block

	mov	ax, ds:[di].VSN_priority	; ax <- priority of new node

	mov	si, es:[DACActiveList].LHT_head; si <- 1st active node

	cmp	si, END_OF_LIST			; is list empty?
	je	addToEmptyList

	;
	;  See if we add to the head of the list
	mov	bx, si				; bx <- current head of list
	cmp	ax, ds:[si].VSN_priority
	jb	addToHeadOfList

topOfLoop:
	mov	bx, si				; bx <- node in front of slot
	mov	si, ds:[si].VSN_next		; si <- next node

	cmp	si, END_OF_LIST			; have we reach the end?
	je	addToEndOfList

	cmp	ax, ds:[si].VSN_priority	; is next node more important?
	jae	insertBetweenBXAndSI

	mov	bx, si				; bx <- previous node
	jmp	short topOfLoop

insertBetweenBXAndSI:
	mov	ds:[bx].VSN_next, di		; place our node next
	mov	ds:[di].VSN_next, si		; hook up list structure
done:
	.leave
	ret

addToEndOfList:
	mov	es:[DACActiveList].LHT_tail, di	; mark as last node
	jmp	short insertBetweenBXAndSI

addToHeadOfList:
	mov	es:[DACActiveList].LHT_head, di	; mark as first node
	mov	ds:[di].VSN_next, bx		; connect with oldhead
	jmp	short done

addToEmptyList:
	mov	es:[DACActiveList].LHT_head, di	; mark as first node
	mov	es:[DACActiveList].LHT_tail, di	; mark as last node
	mov	ds:[di].VSN_next, END_OF_LIST	; mark end of list
	jmp	short done
SoundDACActivate	endp
public SoundDACActivate

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDACDeactivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a node from the active list

CALLED BY:	INTERNAL

PASS:		cx	-> physical dac #
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		removes a node from the active list

PSEUDO CODE/STRATEGY:
		traverse list until next node is the one we want, then
		remove it and clean up the rough edges
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC<	udata	segment			>
EC<		dacLoopCount	word 0	>
EC<	udata	ends			>

SoundDACDeactivate	proc	far
	uses	ax,bx,cx,si,ds,es
	.enter
	;
	;  Verify Interrupts are disabled
EC<	pushf					; ax <- current flags	>
EC<	pop	ax							>
EC<	test	ax, mask CPU_INTERRUPT		; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED		>

	;
	;  Verify the voice list has not been corrupted
EC<	call	SoundDACVerifyLists					>

	;
	;  Load up the library's dgroup
	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	es, ax				; es <- dgroup of library

	;
	;  Verify we are to act upon a legal voice
EC<	cmp	cx, es:[driverDACs]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	;
	;  Aquire a pointer to the voice
	mov	ds, es:[voiceBlock]		; ds <- segment of voice block

	add	cx, es:[driverVoices]		; cx <- our VSN #
	shl	cx, 1				; cx <- cx * 2
	shl	cx, 1				; cx <- cx * 4
	shl	cx, 1				; cx <- cx * 8

	mov	si, es:[DACActiveList].LHT_head ; si <- 1st node in list
	mov	bx, END_OF_LIST

	;
	;  Traverse the list until we find the
	;	voice on the active list.
EC<	clr	es:[dacLoopCount]		; make sure we loop forever>
topOfLoop:
EC<	inc	es:[dacLoopCount]					   >
EC<	ERROR_S	SOUND_CORRUPT_VOICE_LIST				   >

	cmp	si, END_OF_LIST			; have we reached the end?
	je	voiceNotActive

	cmp	si, cx				; is this the correct node?
	je	foundIt

	mov	bx, si				; save prev. node
	mov	si, ds:[si].VSN_next		; si <- next node
	jmp	short topOfLoop

foundIt:
	cmp	bx, END_OF_LIST			; were we the first node?
	je	removeFirstNode

	mov	ax, ds:[si].VSN_next		; ax <- node after ours
	mov	ds:[bx].VSN_next, ax		; close the gap

	mov	ds:[si].VSN_next, END_OF_LIST	; make it un-attached

checkForLastNode:
	cmp	cx, es:[DACActiveList].LHT_tail; were we the last node?
	jne	done
	mov	es:[DACActiveList].LHT_tail, bx; mark new end of list
done:
	.leave
	ret

voiceNotActive:
	stc					; something not right here...
	jmp	short done

removeFirstNode:
	mov	ax, ds:[si].VSN_next		; ax <- next 1st node
	mov	es:[DACActiveList].LHT_head, ax; mark as head of list
	mov	ds:[si].VSN_next, END_OF_LIST	; make it un-attached
	mov	bx, END_OF_LIST			; "prev" node is end of list
	jmp	short checkForLastNode

SoundDACDeactivate	endp
public SoundDACDeactivate

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDACAssign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pair up a physical dac with a stream voice

CALLED BY:	INTERNAL

PASS:		bx	-> SoundStreamStatus segment
		cx	-> physical DAC #
		dx	-> stream DAC #
		INTERRUPTS_OFF

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	modifies the voices in the sound stream status and
		modifies the voice status node

PSEUDO CODE/STRATEGY:
		Does no checking for currently active voice, priority
		or anything else.  If you use this routine to change
		the voice settings of a voice that is currently playing,
		things could get bad.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.assert		size VoiceStatusNode	eq	8
		.assert 	size SoundVoiceStatus	eq	8
SoundDACAssign	proc	far
	uses	ax, si, di, es, ds
	.enter
EC<	pushf				; ax <- current flags	>
EC<	pop	ax						>
EC<	test	ax, mask CPU_INTERRUPT		; are ints disabled	>
EC<	ERROR_NZ SOUND_VOICE_MANAGER_CALLED_WITH_INTS_ENABLED		>

EC<	call	SoundDACVerifyLists				>

	mov	ax, segment dgroup		; ax <- dgroup of library
	mov	ds, ax				; ds <- dgroup of library

EC<	cmp	cx, ds:[driverDACs]				>
EC<	ERROR_A	SOUND_VOICE_MANAGER_CALLED_WITH_ILLEGAL_VOICE	>

	mov	es, ds:[voiceBlock]		; es <- segment of voice block
	
	mov	di, cx
	add	di, ds:[driverVoices]		; di <- our VSN #

	mov	ds, bx				; ds <- segment of stream

	shl	di, 1				; di <- di * 2
	shl	di, 1				; di <- di * 4
	shl	di, 1				; di <- di * 8 (size VSN)

	mov	si, dx				; si <- stream voice #
	shl	si, 1				; si <- si * 2
	shl	si, 1				; si <- si * 4
	shl	si, 1				; si <- si * 8 (size SVS)

						; save physical voice
	mov	ds:SC_voice[si].SVS_physicalVoice, cx

	mov	es:[di].VSN_voice, dx		; save stream's voice
	mov	es:[di].VSN_owner, ds		; save stream's segment
	.leave
	ret
SoundDACAssign	endp
public SoundDACAssign

if ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SoundDACVerifyLists, SoundDACVerifyListsFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the Activate and Free lists are viable

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Verify legal head & tail pointers

		Verify no loops exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SoundDACVerifyListsFar	proc	far
	call	SoundVoiceVerifyLists
	ret
SoundDACVerifyListsFar	endp

SoundDACVerifyLists	proc	near
	uses	ax, bx, cx, si, ds, es
	.enter
	;
	;  Set up segment pointers
	mov	ax, segment dgroup
	mov	es, ax

	mov	ax, es:[voiceBlock]
	mov	ds, ax

	mov	bl, size VoiceStatusNode

	;
	;  Check for an empty free list
	mov	ax, es:[DACFreeList].LHT_head
	cmp	ax, END_OF_LIST
	LONG je	verifyEmptyFreeList

	mov	si, es:[DACFreeList].LHT_tail
	cmp	si, END_OF_LIST
	ERROR_E	SOUND_CORRUPT_VOICE_LIST

	cmp	ds:[si].VSN_next, END_OF_LIST
	ERROR_NE SOUND_CORRUPT_VOICE_LIST

checkActiveListHead:
	mov	ax, es:[DACActiveList].LHT_head
	cmp	ax, END_OF_LIST
	LONG je	verifyEmptyActiveList

	mov	si, es:[DACActiveList].LHT_tail
	ERROR_E	SOUND_CORRUPT_VOICE_LIST

	cmp	ds:[si].VSN_next, END_OF_LIST
	ERROR_NE SOUND_CORRUPT_VOICE_LIST

checkFreeListForLoop:
	mov	cx, es:[driverDACs]
	tst	cx
	jz	done

	;
	;  adjust cx so that it never falls through the
	;  loop statements unless we have traversed MORE
	;  VouceStatusNodes than we have voices
	inc	cx
	mov	si, es:[DACFreeList].LHT_head

topOfFreeLoop:
	cmp	si, END_OF_LIST
	je	checkActiveListForLoop

	mov	ax, si

	;
	;  Determine if the next field of the
	;	voice is a valid next field
	div	bl		; al <- voice #, ah <- remainder

	;
	;  Are we pointing to the middle of a voice?
	tst	ah			; is remainder non-zero?
	ERROR_NZ SOUND_CORRUPT_VOICE_LIST

	;
	;  Are we pointing past the legal voices?
	clr	ah			; ax <- al (the voice #)
	sub	ax, es:[driverVoices]
	cmp	ax, es:[driverDACs]
	ERROR_AE SOUND_CORRUPT_VOICE_LIST

	;
	;  SI gets the next field
	mov	si, ds:[si].VSN_next
	loop	topOfFreeLoop

	;
	;  We dropped through here, so we know there is an error
	ERROR	SOUND_CORRUPT_VOICE_LIST

checkActiveListForLoop:
	mov	si, es:[DACActiveList].LHT_head

topOfActiveLoop:
	cmp	si, END_OF_LIST
	je	done

	mov	ax, si			; ax <- next field

	;
	;  Determine if the next field of the
	;	voice is a valid next field
	div	bl		; al <- voice #, ah <- remainder

	;
	;  Are we pointing to the middle of a voice?
	tst	ah			; is remainder non-zero?
	ERROR_NZ SOUND_CORRUPT_VOICE_LIST

	;
	;  Are we pointing past the legal voices?
	clr	ah			; ax <- al (the voice #)
	sub	ax, es:[driverVoices]
	cmp	ax, es:[driverDACs]
	ERROR_AE SOUND_CORRUPT_VOICE_LIST


	mov	si, ds:[si].VSN_next
	loop	topOfActiveLoop

	;
	;  We dropped through here, so we know there is an error
	ERROR	SOUND_CORRUPT_VOICE_LIST
done:
	.leave
	ret

verifyEmptyFreeList:
	cmp	ax, es:[DACFreeList].LHT_tail
	ERROR_NE SOUND_CORRUPT_VOICE_LIST
	jmp	checkActiveListHead

verifyEmptyActiveList:
	cmp	ax, es:[DACActiveList].LHT_tail
	ERROR_NE SOUND_CORRUPT_VOICE_LIST
	jmp	checkFreeListForLoop
SoundDACVerifyLists	endp
endif
ResidentCode	ends
