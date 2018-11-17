COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/LMem
FILE:		lmChunkArray.asm

AUTHOR:		Doug Fults

GLOBAL ROUTINES:
	Name			Description
	----			-----------

LOCAL ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/90		Moved here from Write

IMPLEMENTATION:

DESCRIPTION:

	This file contains the front-end routines for calling the ChunkArray
routines in KLib.

	$Id: lmemChunkArray.asm,v 1.1 97/04/05 01:14:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayElementToPtr

DESCRIPTION:	Return a pointer to a given element

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	ax - element number to find

RETURN:
	carry - set if element number out of bounds (ds:di will be the last
		element in the array)
	cx - element size (if variable sized elements)
	ds:di - element

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	EC version fatal-errors if an element number of
	CA_NULL_ELEMENT (0xffff) is passed in ax.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
ChunkArrayElementToPtr	proc	far	uses ax, dx
	.enter

EC <	call	ECCheckChunkArray					>

EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	; make sure that element number is in range

	mov	di, ds:[si]		;ds:di = array
	mov	dx, ds:[di].CAH_elementSize

	cmp	ax, ds:[di].CAH_count
	cmc
	jae	common			;really a "jb", but inverted so that
					;we branch with the carry set

	; carry is clear

	mov	ax, ds:[di].CAH_count
	dec	ax
	stc
	jns	common			;=> elements in the array, so ok

	; element size is 0, return CAH_offset (done specially so that it
	; works for variable sized elements)

	add	di, ds:[di].CAH_offset	;ds:di = first element
	tst	dx
	jnz	emptyDone
	clr	cx
emptyDone:
	stc
	jmp	done

common:
	pushf
	tst	dx
	jz	var
	mul	dx
	add	di, ds:[di].CAH_offset		;ds:di = first element
	add	di, ax

donePop:
	popf
done:
EC <	call	ECCheckChunkArray					>
	.leave
	ret

	; variable sized elements

var:
	push	bx
	mov	bx, ax
	shl	bx
	add	bx, ds:[di].CAH_offset		;ds:bx = offset to element
	add	bx, di
	inc	ax
	cmp	ax, ds:[di].CAH_count
	jz	lastElement

	mov	cx, ds:[bx][2]			;cx = offset of next element
	jmp	varCommon

	; last element - use size of chunk as offset to next

lastElement:
	ChunkSizePtr	ds, di, cx

varCommon:
	sub	cx, ds:[bx]			;cx = size
	add	di, ds:[bx]
	pop	bx
	jmp	donePop

ChunkArrayElementToPtr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayGetCount

DESCRIPTION:	Get the number of elements in an array

CALLED BY:	GLOBAL

PASS:
	*ds:si - array

RETURN:
	cx - number of elements

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	3/90		Converted for KLib use

------------------------------------------------------------------------------@
ChunkArrayGetCount	proc	far	uses	si
	.enter

EC <	call	ECCheckChunkArray					>

	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count

	.leave
	ret

ChunkArrayGetCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayEnumRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate elements in a chunk-array, starting with a
		given element.

CALLED BY:	Global
PASS:		*ds:si	= Chunk array
		bx:di	= fptr to Callback routine
				See ChunkArrayEnumCommon for details.
				Can be vfptr for XIP'ed geode.
		ax	= Element to start calling back for
		cx	= Number of elements to process (-1 for all)
		dx, bp, es = Data to pass to callback
RETURN:		ax, cx, dx, bp, es = Set by callback
		carry set if callback aborted
DESTROYED:	bx

WARNING:	The following operations MAY NOT be run simultaneously
		on the same ChunkArray in different threads:

			ChunkArrayEnum		(even if callback
			ChunkArrayEnumRange	 is non-destructive)
			ChunkArrayAppend
			ChunkArrayInsertAt
			ChunkArrayDelete
			ChunkArrayDeleteRange

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkArrayEnumRange	proc	far
	pushdw	bxdi			; Pass callback on stack
	push	ax			; Pass starting element on stack
	push	cx

	call	ChunkArrayEnumCommon
	ret
ChunkArrayEnumRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all elements in a chunk-array.

CALLED BY:	Global
PASS:		*ds:si	= Chunk array
		bx:di	= fptr to Callback routine
				See ChunkArrayEnumCommon for details
				Can be vfptr for XIP'ed geodes
	fixed size elements:
		    ax, cx, dx, bp, es  = Data to pass to callback
	variable sized elements:
		    cx, dx, bp, es 	= Data to pass to callback

RETURN:		ax, cx, dx, bp, es = Set by callback
		carry set if callback aborted
DESTROYED:	bx

WARNING:	The following operations MAY NOT be run simultaneously
		on the same ChunkArray in different threads:

			ChunkArrayEnum		(even if callback
			ChunkArrayEnumRange	 is non-destructive)
			ChunkArrayAppend
			ChunkArrayInsertAt
			ChunkArrayDelete
			ChunkArrayDeleteRange

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkArrayEnum	proc	far
	pushdw	bxdi			; Pass callback on stack
	clr	bx			; Start at the first element
	push	bx			; Pass starting element on stack
	dec	bx
	push	bx			; Process all elements
	
	call	ChunkArrayEnumCommon
	ret
ChunkArrayEnum	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayEnumCommon

DESCRIPTION:	Enumerate all elements in a general array

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	On stack:
		Pushed 1st:	Callback routine		dword
				Starting element		word
				Number of elements to do	word
	ax, cx, dx, bp, es - data to pass to callback

RETURN:
	ax, cx, dx, bp, es - modified by callbacks
	carry - set if the callback returned the carry set

DESTROYED:
	bx

  ** WARNING
	If you are resizing elements larger as part of your callback
	then chunks on the lmem heap may move. This means that all 
	direct pointers into the lmem heap are not valid after a call 
	to this routine.
	
	In addition to this, if you are resizing an element larger
	then the lmem-heap itself may move on the global heap. This
	means that any segment registers or stored segments which
	refer to the heap are not valid after a call to this routine.

	If you are resizing the element smaller then all pointers
	and segments are still valid after the call.
	
	Callback:
	Pass:
		*ds:si - array
		ds:di - array element being enumerated
		fixed size elements:
		    ax, cx, dx, bp, es - data passed to GArrayEnum
		variable sized elements:
		    ax - element size
		    cx, dx, bp, es - data passed to GArrayEnum
	Return:
		carry	- set to end enumeration
		ax, cx, dx, bp, es - data to pass to next
	Destroyed:
		bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	The way ChunkArrayEnum() handles nested calls, inserting or
	deleting is by saving a linked list of stack frames that
	show where each call is in the enumeration.  Insert and delete
	operations walk down this list to fix things up if necessary.

	Previously, this linked list was done as a local variable.
	This runs into problems with ThreadBorrowStackSpace(), as
	any given item of the list may have be in a borrowed block.
	This can happen if a callback function does borrows space or
	calls something that does.

	The way it is handled now is by using the bottom of the stack
	in a way similar to how ResourceCallInt() uses it as a secondary
	stack that isn't part of the stack that is borrowed or otherwise
	mutilated by normal operations.  -- eca 11/16/92

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The following operations can be used in the callback routine to
	modify the array while enumerating (but see below for warning):
		ChunkArrayInsertAt (also covers ChunkArrayAppend)
		ChunkArrayDelete
		ChunkArrayEnum (nested)
	ChunkArrayEnum will ensure that no item in the array is missed
	and that no item in the array will be enumerated more than once
	because of these operations.

	* If you insert an item before the current element,
	it WILL NOT be enumerated.

	* If you insert an item at or after the current element,
	it WILL be enumerated.

	* If you append an item (ie. an insert after the last
	element), it WILL be enumerated.

	* If you remove the current element and put a new element in
	its place, the new element WILL be enumerated (this is a delete
	followed by an insert at the current element).

	WARNING: Simultaneous calls to ChunkArrayInsert, ChunkArrayDelete,
	or ChunkArrayEnum on multiple threads are not allowed, because
	of this shared data structure.  Even if both ChunkArrayEnum's
	are non-destructive, they will still both try to manipulate
	this ChunkArrayEnum nested call chain.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	3/90		Converted for KLib use

------------------------------------------------------------------------------@

ChunkArrayEnumCommon	proc	near	\
			elementCount:word,
			startElement:word,
			callback:dword
	uses	di
	;
	; NOTE: passedBP is the real passed bp -- not a separate copy.
	; Normally this would be a bad thing, except in this
	; case, we want to return the modified bp from whatever
	; the callback did to it.
	;
passedBP	local	word	push	bp
curSavedOffset	local	nptr.SaveCurOffsetStruct	;offset of saved struct
	.enter

EC <	call	ECCheckChunkArray					>

EC <	push	ds, si						>

if FULL_EXECUTE_IN_PLACE
EC <	; Since ECCheckBounds blows up when passed a vseg and	>
EC <	; "ec segment" is on, we have to check vseg separately.	>
EC <	movdw	bxsi, ss:[callback]				>
EC <	cmp	bh, high MAX_SEGMENT				>
EC <	jae	checkVfptr		; jump if bx is vseg	>
EC <	mov	ds, bx			; ds:si = fptr		>
EC <	call	ECCheckBounds		; check fptr		>
EC <	jmp	EC_done						>
EC <checkVfptr:							>
EC <	call	ECAssertValidFarPointerXIP	; check vfptr	>
EC <EC_done:							>
else
EC <	lds	si, callback					>
EC <	call	ECCheckBounds					>
endif

EC <	pop	ds, si						>


	; Make sure the start element is LESS THAN the array count.
	; Also, prevent enumeration of an empty array.

	mov	bx, ds:[si]
	push	bx			
	mov	bx, ds:[bx].CAH_count
	cmp	startElement, bx
	pop	bx			
	jb	ok
	jmp	done			; carry is clear 
ok:	
	; ds:bx - array header

	;
	; Initialize things for saving the chain of SaveCurOffsetStruct
	; elements on the bottom of the stack.
	;
	mov	di, ss:[TPD_stackBot]		;di <- current stack bottom
	add	ss:[TPD_stackBot], (size SaveCurOffsetStruct)
	mov	ss:curSavedOffset, di
	;
	; SCOS_curOffset holds different values depending on what sort
	; of chunk-array we are processing.
	;
	; For fixed-size element arrays, SCOS_curOffset holds the offset to
	; the current element. It is adjusted at the bottom of the loop by
	; adding in the element size.
	;
	; For variable-sized element arrays, SCOS_curOffset holds the offset
	; into the "size list" and is used to grab the size of the current
	; element. 
	;
	; We initialize the value differently depending on the type.
	;
	
	tst	ds:[bx].CAH_elementSize		;variable or fixed?
	jz	variableSized

	;
	; It's fixed size. We need to compute the offset to the current element
	;
	;
	push	ax, cx				; Save passed values
	mov	ax, startElement		; ax <- first element
	call	ChunkArrayElementToPtr		; ds:di <- ptr to 1st element
						; cx <- size
	sub	di, bx				; di <- offset to element
	mov	bx, ss:curSavedOffset		; ss:bx <- saved frame
	mov	ss:[bx].SCOS_curOffset, di
	pop	ax, cx				; Restore passed values
	jmp	enumLoop
	
variableSized:
	;
	; For variable sized elements we want SCOS_curOffset to hold the
	; offset to the size for the current element.
	;
	push	ax
	mov	ax, startElement		; ax <- start element
	shl	ax, 1				; ax <- offset in table
	add	ax, ds:[bx].CAH_offset		; ax <- offset to entry

	mov	bx, ss:curSavedOffset		; ss:bx <- saved frame
	mov	ss:[bx].SCOS_curOffset, ax
	pop	ax

enumLoop:
	;
	; loop: *ds:si = array,
	;	savedOffsetInfo.SCOS_curOffset = offset into array
	;
	tst	elementCount			; Clears the carry
	LONG jz	donePop				; Branch if no more

	;
	; before calling the callback routine, add our GAE_curOffset to
	; the front of the CAH_curOffset linked list, in case ChunkArray
	; operations are done by the callback routine
	;
	push	ax, si
EC <	call	ECCheckCurOffsetChain					>
	mov	si, ds:[si]
	mov	ax, ds:[si].CAH_curOffset		; ax = head of list
	mov	bx, ss:curSavedOffset
EC <	push	ss:[TPD_threadHandle]					>
EC <	pop	ss:[bx].SCOS_thread					>
	mov	ss:[bx].SCOS_next, ax			; attach at end
	mov	ds:[si].CAH_curOffset, bx		; make us the list head
	pop	ax, si

	mov	di, ds:[si]			; ds:di = array
	mov	bx, ss:curSavedOffset		; ss:bx <- saved frame
	cmp	ds:[di].CAH_elementSize, 0
	jnz	notVarSized

	mov	bx, ss:[bx].SCOS_curOffset	; bx <- current offset
	call	GetVarElementSize		;ds:bx = offset to element
	add	di, ds:[bx]
	jmp	enumCommon

notVarSized:
	add	di, ss:[bx].SCOS_curOffset	; di = element

enumCommon:
	push	si, bp
;-----------------------------------
EC <	;								>
EC <  	; if LMF_IS_VM is set we do not want to check the handle, as the>
EC <  	; block could be unlocked during the callback, discarded and    >
EC <  	; locked again before the callback returns, in which case the   >
EC <  	; handle likely will have changed, but DS will be correct       >
EC <	;								>
EC <	clr	bx							>
EC <	test	ds:[LMBH_flags], mask LMF_IS_VM				>
EC <	jnz	haveTestValue						>
EC <	mov	bx, ds:[LMBH_handle]					>
EC < haveTestValue:							>
EC <	push	bx							>

	lea	bx, callback				; ss:bx <- callback
	mov	bp, passedBP				; bp <- bp to pass
FXIP <	cmp	ss:[bx].segment.high, high MAX_SEGMENT			>
FXIP <	ja	callMovable						>
caeCallCallback::
	call	{dword} ss:[bx]				; call routine
afterCall::
	mov	bx, bp					; bx <- returned bp

EC <	pop	bp							>
EC <	pushf								>
EC <	;								>
EC <	; if bp is 0, make sure LMF_IS_VM is still set			>
EC <	; otherwise check that the handle is the same			>
EC <	;								>
EC <	tst	bp							>
EC <	jz	checkFlags						>
EC <									>
EC <	cmp	bp, ds:[LMBH_handle]					>
EC <	je	noHandleError						>
EC <	ERROR CHUNK_ARRAY_ENUM_CALLBACK_TRASHED_DS			>
EC <									>
EC < checkFlags:							>
EC <	test	ds:[LMBH_flags], mask LMF_IS_VM				>
EC <	ERROR_Z CHUNK_ARRAY_ENUM_CALLBACK_TRASHED_DS			>
EC <									>
EC < noHandleError:							>
EC <	popf								>
;-----------------------------------
	pop	si, bp
	mov	passedBP, bx				; Save returned value

	;
	; after calling the callback routine, remove our GAE_curOffset from
	; the front of the CAH_curOffset linked list
	;
	push	ax, si
	mov	bx, ss:curSavedOffset
	mov	ax, ss:[bx].SCOS_next		; ax = previous head
EC <	call	ECCheckCurOffsetChain					>
	mov	si, ds:[si]
	mov	ds:[si].CAH_curOffset, ax		; restore prev. head
	pop	ax, si

	jc	donePop				; if carry returned set, then
						; done
	push	ax, cx
	mov	di, ds:[si]			; ds:di = array
	ChunkSizePtr	ds, di, cx		; cx = end offset
	mov	ax, ds:[di].CAH_elementSize
	tst	ax
	jnz	notZero
	mov	cx, ds:[di].CAH_count
	shl	cx
	add	cx, ds:[di].CAH_offset		;cx = end offset
	mov	ax, 2
notZero:

			; (if we deleted first item in callback routine,
			;  this may go from negative to positive here)
	dec	elementCount
	mov	bx, ss:curSavedOffset
	add	ss:[bx].SCOS_curOffset, ax
	cmp	cx, ss:[bx].SCOS_curOffset
	pop	ax, cx
	LONG ja	enumLoop

EC <	call	ECCheckChunkArray					>

	clc

	;
	; Clean up our private stack allocation
	;
donePop:
	pushf
	sub	ss:TPD_stackBot, (size SaveCurOffsetStruct)
	popf
done:
EC <	call	ECCheckChunkArray					>

	.leave
	ret	@ArgSize

if	FULL_EXECUTE_IN_PLACE		
callMovable:
	pushdw	ss:[bx]
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	jmp	afterCall
endif
ChunkArrayEnumCommon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetVarElementSize

DESCRIPTION:	Get the size of a variable sized element

CALLED BY:	GLOBAL

PASS:
	ds:di - array
	ds:bx - element (offset from start of chunk)
			(This is actually the offset from the start of the
			 chunk into the array of offsets to the elements, NOT
			 an offset to the element itself)

RETURN:
	ds:bx - element (offset in block)
	ax - element size

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/17/91		Initial version

------------------------------------------------------------------------------@

GetVarElementSize	proc	near	uses cx
	.enter

	mov	cx, ds:[di].CAH_count
	dec	cx
	shl	cx
	add	cx, ds:[di].CAH_offset
	cmp	bx, cx
	jnz	notLastElement
	ChunkSizePtr	ds, di, ax		;ax = chunk size
	add	bx, di
	jmp	varCommon
notLastElement:
	add	bx, di
	mov	ax, ds:[bx][2]
varCommon:
	sub	ax, ds:[bx]

	.leave
	ret

GetVarElementSize	endp

kcode ends

;-------------------------------------------------------------------------

ChunkCommon segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayAppend

DESCRIPTION:	Append an element to an array

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	ax - element size (if variable)

RETURN:
	carry set if LMF_RETURN_ERRORS & couldn't append
		di - destroyed
	carry clear if appended:
		ds:di - new element, all zeroed (block possibly moved)

DESTROYED:
	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

WARNING:	The following operations MAY NOT be run simultaneously
		on the same ChunkArray in different threads:

			ChunkArrayEnum		(even if callback
			ChunkArrayEnumRange	 is non-destructive)
			ChunkArrayAppend
			ChunkArrayInsertAt
			ChunkArrayDelete
			ChunkArrayDeleteRange


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	3/90		Converted for KLib use

------------------------------------------------------------------------------@

ChunkArrayAppend	proc	far

	; calculate position to add

	push	ax
	mov	di, ds:[si]
	ChunkSizePtr	ds, di, ax		;position to insert
	add	di, ax
	pop	ax	
	FALL_THRU	ChunkArrayInsertAt

ChunkArrayAppend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayInsertAt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an element at a position in the array.

CALLED BY:	
PASS:		*ds:si	= array.
		ds:di	= element to insert before.
		ax	= element size to insert (if variable)
RETURN:		carry set if LMF_RETURN_ERRORS and couldn't insert:
			di	= destroyed
		carry clear if element inserted:
			ds:di	= points to new element, all zeroed (block
				  may move).
DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

WARNING:	The following operations MAY NOT be run simultaneously
		on the same ChunkArray in different threads:

			ChunkArrayEnum		(even if callback
			ChunkArrayEnumRange	 is non-destructive)
			ChunkArrayAppend
			ChunkArrayInsertAt
			ChunkArrayDelete
			ChunkArrayDeleteRange


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkArrayInsertAt	proc	far	uses	ax, bx, cx, dx, bp
	.enter
	InsertGenericProfileEntry PET_LMEM, 1, PMF_LMEM, ax		;
EC <	call	ECCheckChunkArray					>

	mov	bx, di
	mov	di, ds:[si]
	sub	bx, di				;bx = offset to add at
	mov	bp, bx				;bp = offset for enum check
	mov	cx, ds:[di].CAH_elementSize	;# bytes to insert
	mov	dx, cx				;dx = # bytes to adjust by
	tst	cx
	jnz	notVariableSized

	; variable sized element -- insert an offset word

	push	bx				;save element offset
	push	ax, di
	add	di, bx				;ds:di = element
	call	ChunkArrayPtrToElement		;ax = element number
	mov_trash	bx, ax			;bx = element number
	pop	ax, di
	shl	bx
	add	bx, ds:[di].CAH_offset		;bx = offset to add word

	mov	cx, 2
	xchg	ax, si				;ax = chunk, si = element size
	call	LMemInsertAt
	xchg	ax, si				;ax = element size, si = chunk
	pop	bp				;bp = offset for new element
	jc	done

	inc	bp
	inc	bp				;adjust for word added
	mov	di, ds:[si]
	add	bx, di				;ds:bx = new word
	mov	ds:[bx], bp			;save offset to new element

	; ds:di - array
	; bx - offset of element being worked on
	; dx - amount to update all offsets by
	; ax - amount to update offsets after bx by

	inc	ds:[di].CAH_count		;so that UpdateVarOffsets sees
						;the correct number of elements
	mov	dx, 2
	call	UpdateVarOffsets
	mov_trash	cx, ax			;cx = size
	xchg	bx, bp				;bx = offset to insert element
	sub	bp, di				;bp = offset for Enum check
	jmp	common

notVariableSized:
	inc	ds:[di].CAH_count

common:

	; *ds:si = ds:di = array, bx = offset to insert at
	; cx = # bytes to insert, bp = offset for ChunkEnumArray check (offset
	; in *chunk* where element will be inserted or where variable offset
	; was inserted)
	; dx = # bytes to adjust Enum data by (enum data tracks the variable
	; offset or the actual element offset, so this is either 2 or the
	; size of an element)

	; If we are inserting from a ChunkArrayEnum callback routine, we want
	; to adjust the CAH_curOffset list so that we don't process an element
	; twice.  We need to do this if the insertion point is at or before the
	; current position.  This means that adding an item at the position
	; currently being processed will result in the new item not being
	; processed.  To have a new item processed, it must be added after the
	; current item.  If we are not in a ChunkArrayEnum, this does nothing
	; as CAH_curOffset will be empty.
	;
EC <	call	ECCheckCurOffsetChain					>
	mov	di, ds:[di].CAH_curOffset	; ss:di = first SaveCurOffset
	xchg	di, bp				; ss:bp = first SaveCurOffset
						;    di = offset to check
adjustLoop:
	tst	bp
	jz	finishAdjustment		; none to do
	cmp	di, ss:[bp].SCOS_curOffset	; need adjustment?
	ja	noAdjustment			; nope
	add	ss:[bp].SCOS_curOffset, dx	; update curOffset
noAdjustment:
	mov	bp, ss:[bp].SCOS_next		; bp = next curOffset
	jmp	adjustLoop
finishAdjustment:

	; note that we don't need to update the CAH_curOffset list as we are
	; adding an element at the end and the new item is guaranteed to be
	; enum'ed

	; insert the bytes (and zero them)

	mov	ax, si
	call	LMemInsertAt
	jc	removeVarOff

	; return the offset

	mov	di, ds:[si]
	add	di, bx				; (can't carry)

done:
EC <	call	ECCheckChunkArray						>
	InsertGenericProfileEntry PET_LMEM, 0, PMF_LMEM, ax		;
	.leave
	ret

removeVarOff:
	;
	; Failed to insert the bytes for the element itself, so we need to
	; (a) undo the insertion of the offset, (b) remove the variable offset
	; we added for the element, (c) undo the adjustment of the Enum
	; things, and (d) reduce the element count by one.
	;
	; *ds:si = array
	; di = offset for enum check (also offset of inserted var off, if v.
	;      size)
	; dx = adjustment size for enum
	; cx = element size
	; 
	mov	bx, ds:[si]
	tst	ds:[bx].CAH_elementSize
	jnz	reduceEltCount			; => not v. sized, so no
						;  adjustment needed
	mov	bx, di
	add	bx, ds:[si]		; ds:bx <- var offset for aborted
					;  element
	mov	dx, -2			; reduce all var offsets by 2, for
					;  the size word we're going to biff
	mov	ax, cx
	neg	ax			; ax <- negative of element size for
					;  subtraction from all var offsets
					;  after ds:bx
	call	UpdateVarOffsets
	sub	bx, ds:[si]		; bx <- offset for word deletion
	mov	ax, si			; ax <- chunk
	mov	cx, 2			; cx <- # bytes to delete
	call	LMemDeleteAt
	neg	dx			; dx <- enum adjustment (1 word)

reduceEltCount:
	mov	bx, ds:[si]
	dec	ds:[bx].CAH_count
EC <	call	ECCheckCurOffsetChain					>
	mov	bp, ds:[bx].CAH_curOffset	; ss:bp = first SaveCurOffset
readjustLoop:
	tst	bp
	jz	finishReadjustment		; none to do
	cmp	di, ss:[bp].SCOS_curOffset	; need adjustment?
	ja	noReadjustment			; nope
	sub	ss:[bp].SCOS_curOffset, dx	; update curOffset
noReadjustment:
	mov	bp, ss:[bp].SCOS_next		; bp = next curOffset
	jmp	readjustLoop
finishReadjustment:
	stc
	jmp	done
ChunkArrayInsertAt	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateVarOffsets

DESCRIPTION:	Update all offsets to elements for a variabled sized chunk
		array

CALLED BY:	ChunkArrayInsertAt, ChunkArrayDelete

PASS:
	ds:di - array
	bx - offset of element being worked on (offset in block [not chunk] of
	     var ptr)
	dx - amount to update all offsets by
	ax - amount to update offsets after bx by

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/17/91		Initial version

------------------------------------------------------------------------------@

UpdateVarOffsets	proc	far	uses cx, di
	.enter

	; we must update all the offsets to reflect the two bytes that
	; we have added and all the offsets after the one being inserted
	; reflect the element size being inserted

	mov	cx, ds:[di].CAH_count
	jcxz	done				; nothing to do if no
						;  elements in the array...
	add	di, ds:[di].CAH_offset
updateLoop:
	cmp	di, bx
	jz	updateNext			;this one is already correct
	jb	notBefore
	add	ds:[di], ax
notBefore:
	add	ds:[di], dx
updateNext:
	inc	di
	inc	di
	loop	updateLoop
done:
	.leave
	ret

UpdateVarOffsets	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayDelete

DESCRIPTION:	Delete an element from an array

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	ds:di - element

RETURN:
	ds:di - pointing at the same element (if it still exists)  Note that
		this will be a different value for variable sized arrays

DESTROYED:
	none

WARNING:	The following operations MAY NOT be run simultaneously
		on the same ChunkArray in different threads:

			ChunkArrayEnum		(even if callback
			ChunkArrayEnumRange	 is non-destructive)
			ChunkArrayAppend
			ChunkArrayInsertAt
			ChunkArrayDelete
			ChunkArrayDeleteRange

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	jcw	3/90		Converted for KLib use

------------------------------------------------------------------------------@

ChunkArrayDelete	proc	far
	uses	ax, cx
	.enter
	call	ChunkArrayPtrToElement		; ax <- element number

	mov	cx, 1				; cx <- number to nuke
	call	ChunkArrayDeleteRange		; Nuke that range
	
	call	ChunkArrayElementToPtr		; Restore ds:di
	.leave
	ret
ChunkArrayDelete	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayDeleteRange

DESCRIPTION:	Delete a range of elements from an array

CALLED BY:	GLOBAL

PASS:
	*ds:si	- Array
	ax	- First element to nuke
	cx	- Number of elements to nuke (-1 to delete to end of
		  array) 

RETURN:
	nothing

DESTROYED:
	none

WARNING:	The following operations MAY NOT be run simultaneously
		on the same ChunkArray in different threads:

			ChunkArrayEnum		(even if callback
			ChunkArrayEnumRange	 is non-destructive)
			ChunkArrayAppend
			ChunkArrayInsertAt
			ChunkArrayDelete
			ChunkArrayDeleteRange

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Figure offset to element first
	Figure offset to element first+count
	Use LMemDeleteAt to nuke the range of data
	
	For variable sized elements
	    Figure offset to <offset> entry for that element
	    Nuke count*2 bytes after that point
	    amountNuked = (count*2) + (end.offset-start.offset)
	    Update offsets from first->end by -1*amountNuked

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 4/92	First version
	cdb	5/27/92		added ability to delete to end of array.
------------------------------------------------------------------------------@

ChunkArrayDeleteRange	proc	far
	uses	ax, bx, cx, dx, di, bp
	.enter
EC <	call	ECCheckChunkArray					>

	; check if first element is beyond end of list

	mov	di, ds:[si]
	mov	bx, ds:[di].CAH_count
	cmp	bx, ax
	LONG jbe done

	; adjust number of elements so that we update CAH_count
	; properly...

	sub	bx, ax			; bx <- max # nukeable elements
	cmp	cx, bx
	jbe	gotNumElements
	mov	cx, bx
gotNumElements:
	
	; ax - first element to remove
	; cx - number of elements to remove
	
	
	;
	; Compute offset to first element
	;
	push	ax				; first element
	push	cx				; count

	call	ChunkArrayElementToPtr		; ds:di <- offset to first
						; cx <- size of element
EC <	ERROR_C ELEMENT_ARRAY_BAD_TOKEN					>
	mov	bx, di				; ds:bx <- offset to first
	pop	cx				; Restore count
	
	;
	; Compute offset to last element
	;
	push	cx				; Save count
	add	ax, cx				; ax <- past last element
	call	ChunkArrayElementToPtr		; ds:di <- offset to
						; last
	jnc	gotOffset

	;
	; The element is beyond the end of the chunk. Use the chunk-size to get
	; a pointer past the end of the data.
	;
	mov	di, ds:[si]
	ChunkSizePtr	ds, di, di		; di <- offset past end
	add	di, ds:[si]			; di <- ptr past end

gotOffset:
	mov	cx, di				; cx <- Number of bytes to nuke
	sub	cx, bx
	sub	bx, ds:[si]			; bx <- offset to delete at
	mov	ax, si				; ax <- chunk of array
	
	;
	; ds	= Segment of heap
	; ax	= Chunk
	; bx	= Offset to delete at
	; cx	= Number of bytes to nuke
	;
	mov	bp, cx				; bp <- space nuked

	call	LMemDeleteAt			; Nuke the space

	pop	cx				; Restore count
	pop	ax				; Restore first
	
	;
	; Update the count of the number of elements in the array
	;
	mov	di, ds:[si]			; ds:di <- ChunkArrayHeader
	sub	ds:[di].CAH_count, cx		; Update the count
	
	;
	; Now update the array of offsets for variable sized elements
	;
	mov	dx, ds:[di].CAH_elementSize	; dx = element size
	tst	dx
	jnz	fixCurOffsets
	
	;
	; Update the offsets to the fixed size elements.
	;
	add	di, ds:[di].CAH_offset		; ds:di <- ptr to list of
						;    offsets
	;
	; First nuke the offsets starting with the one to the first element 
	; we nuked.
	;
	push	ax				; Save first entry
	shl	cx, 1				; cx <- # of bytes to nuke
	shl	ax, 1				; ax <- offset to first one
	add	di, ax				; ds:di <- place to nuke
	
	mov	bx, di				; bx <- place to nuke
	sub	bx, ds:[si]			; bx <- offset into chunk
	mov	ax, si				; ax <- chunk

	;
	; ds	= Segment of heap
	; ax	= Chunk
	; bx	= Offset to delete at
	; cx	= Number of bytes to nuke
	;
	call	LMemDeleteAt			; Nuke unused entries
	pop	ax				; ax <- number of entries nuked
	
	;
	; Now update the offsets for all elements after the place we nuked.
	;
	; Offsets to elements before the ones we nuked need to be adjusted by
	; -1 * the amount of space nuked from the offset table. This value
	; is in cx right now.
	;
	; The offset to elements at and after where we did the nuking need to
	; be adjusted by the same amount, and also by -1 * the amount of
	; space we nuked from the buffer.
	;
	; The problem is that UpdateVarOffsets is designed to do nothing
	; at the position in bx (which is where we did the nuking). What
	; we do is decrement bx. Since the entries are words this will
	; result in all entries getting updated correctly.
	;
	add	bx, ds:[si]			; bx <- ptr into offsets
	dec	bx

	mov	di, ds:[si]			; ds:di <- ChunkArrayHeader

	mov	ax, bp				; ax <- update for after bx
	neg	ax
	
	mov	dx, cx				; dx <- update for before bx
	neg	dx
	call	UpdateVarOffsets

	inc	bx				; bx = offset in offset-list
						;	we deleted at
	sub	bx, ds:[si]			; convert to chunk offset
	neg	dx				; dx = # bytes we deleted from
						;	offset-list

fixCurOffsets:

	; *ds:si = ds:di = array
	; bx = offset for ChunkArrayEnum check
	; dx = # bytes to adjust by

	; If we are deleting from a ChunkArrayEnum callback routine, we want
	; to adjust the CAH_curOffset list so that we don't skip processing an
	; element.  We need to do this if the deletion point is at or before
	; the current position.  If we are not in a ChunkArrayEnum, this does
	; nothing as CAH_curOffset will be empty.
	;
EC <	call	ECCheckCurOffsetChain					>
	mov	di, ds:[di].CAH_curOffset	; ss:di = first SaveCurOffset
	mov	bp, di				; ss:bp = first SaveCurOffset
						; bx = offset to check
adjustLoop:
	tst	bp
	jz	done				; none to do
	cmp	bx, ss:[bp].SCOS_curOffset	; need adjustment?
	ja	noAdjustment			; nope
			; (if we delete the first item, this may go
			;  from position to negative here)
	sub	ss:[bp].SCOS_curOffset,dx	; update curOffset
noAdjustment:
	mov	bp, ss:[bp].SCOS_next		; bp = next curOffset
	jmp	adjustLoop

done:

EC <	call	ECCheckChunkArray					>
	.leave
	ret
ChunkArrayDeleteRange	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayPtrToElement

DESCRIPTION:	Return a pointer to a given element

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	ds:di - element

RETURN:
	ax - element number. (from 0).

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	John	3/90		Converted for KLib use

------------------------------------------------------------------------------@

ChunkArrayPtrToElement	proc	far	uses dx, di
	.enter

EC <	call	ECCheckChunkArray					>

	mov_trash	ax, di			; ax = offset in to array
	mov	di, ds:[si]			; ds:di <- ptr to array.
	sub	ax, di				; ax <- offset into chunk.
	mov	dx, ds:[di].CAH_elementSize     ; dx <- size of an element
	tst	dx
	jz	var

	sub	ax, ds:[di].CAH_offset		;ax = offset from base of array
	mov	di, dx
	clr	dx				; dx.ax <- offset into array.

	div	di				; ax <- element #.

EC <	tst	dx				;	>
EC <	ERROR_NZ PTR_IS_NOT_POINTING_AT_AN_ELEMENT	>

done:
EC <	call	ECCheckChunkArray					>
	.leave
	ret

	; variable sized elements

var:
	push	cx, es

	; OK, the element is variable sized.  This routine can be called with
	; a bogus pointer (one that is past the end of the chunk).  
	; ChunkArrayAppend does this, and expects an element number that is
	; one greater than the last element in the chunk.  The pointer in this
	; case (which is an offset into the chunk) is the same as the size of
	; the chunk itself.  There is another case that makes this a little
	; more difficult check for.  The ChunkArray code lets you insert an
	; element of size zero (for variable sized element arrays).  If a
	; zero-sized element is the last element in a chunk array, it would
	; have the same offset into the chunk as a bogus element that was 
	; described above.  SOOOO, we need to check for a valid element first,
	; if the search fails, *then* we check to see if the offset is the
	; same as the chunk size.  Got that ?

	push	di
	mov	cx, ds:[di].CAH_count
	mov	dx, cx
	add	di, ds:[di].CAH_offset
	segmov	es, ds				;es:di = offset table
	repne scasw
	pop	di
	jnz	checkBogusElement

	; found a matching offset.  That means it's a valid element.

	inc	cx
	mov_trash	ax, dx
	sub	ax, cx
varDone:
	pop	cx, es
	jmp	done

	; the offset that we're looking for is not in the offset array.  This
	; means that either ChunkArrayAppend is screwing with our mind, or the
	; pointer passed is REALLY bad.
checkBogusElement:
	ChunkSizePtr	ds, di, cx
	cmp	ax, cx
EC <	ERROR_NZ	PTR_IS_NOT_POINTING_AT_AN_ELEMENT		>
	mov	ax, ds:[di].CAH_count
	jmp	varDone

ChunkArrayPtrToElement	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayCreate

DESCRIPTION:	Create a new general array with 0 elements.

CALLED BY:	GLOBAL

PASS:
	ds - block for new array
	bx - element size (0 for variable sized elements)
	cx - size for ChunkArrayHeader (this allows for reserving extra
	     space)  0 = default.  Extra space is initialized to zero's.
	si - chunk handle to use (or 0 if you want to alloc one)
	al - ObjChunkFlags to pass to LMemAlloc

RETURN:
	carry set if LMF_RETURN_ERRORS and couldn't allocate new chunk or
		enlarge existing chunk
	carry clear if array allocated:
		*ds:si - array (block possibly moved)

DESTROYED:
	none
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	3/90		Converted for KLib use

------------------------------------------------------------------------------@

SBCS <	MAX_CHUNK_ARRAY_HEADER_SIZE	equ	1000			>
DBCS <	MAX_CHUNK_ARRAY_HEADER_SIZE	equ	2000			>

ChunkArrayCreate	proc	far	uses ax, cx
	.enter
	InsertGenericProfileEntry PET_LMEM, 1, PMF_LMEM, ax		;
EC <	call	ECLMemValidateHeapFar					>

EC <	cmp	bx, 8000						>
EC <	WARNING_A	CHUNK_ARRAY_ELEMENT_SIZE_PROBABLY_TOO_LARGE	>
EC <	cmp	cx, MAX_CHUNK_ARRAY_HEADER_SIZE				>
EC <	ERROR_A	CHUNK_ARRAY_HEADER_SIZE_PROBABLY_TOO_LARGE		>

	tst	cx
	jnz	notZero
	mov	cx, size ChunkArrayHeader
notZero:
EC <	cmp	cx, size ChunkArrayHeader	; check size to be sure	>
EC <	ERROR_B	CHUNK_ARRAY_HEADER_SIZE_TOO_SMALL			>
	tst	si
	jnz	doReAlloc
	call	LMemAlloc
	jc	exit
	mov_tr	si, ax				;si = new array

afterAlloc:

	push	si
	mov	si, ds:[si]
	mov	ds:[si].CAH_count, 0
	mov	ds:[si].CAH_curOffset, 0
	mov	ds:[si].CAH_offset, cx
	mov	ds:[si].CAH_elementSize, bx
	pop	si

	; Zero-initialize space after ChunkArrayHeader, if any

	sub	cx, size ChunkArrayHeader
	jz	done				;(carry clear)
	push	es, di
	mov	di, ds:[si]
	add	di, size ChunkArrayHeader
	segmov	es, ds
	clr	al				;(carry clear)
	rep	stosb
	pop	es, di
done:

EC <	call	ECCheckChunkArray					>
exit:
	InsertGenericProfileEntry PET_LMEM, 0, PMF_LMEM, ax		;
	.leave
	ret

doReAlloc:
	mov	ax, si
	call	LMemReAlloc
	jc	exit
	jmp	afterAlloc
ChunkArrayCreate	endp


ChunkCommon ends

;---------------

ChunkArray segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zero a chunk array (i.e. free all elements and resize).

CALLED BY:	GLOBAL.
PASS:		*ds:si	= chunk array.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkArrayZero	proc	far	uses	cx, ax, si
	.enter

EC <	call	ECCheckChunkArray					>

	mov	ax, si

	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_offset
	mov	ds:[si].CAH_count, 0

	call	LMemReAlloc

	.leave
EC <	call	ECCheckChunkArray					>
	ret

ChunkArrayZero	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayGetElement

DESCRIPTION:	Get an element given its element number

CALLED BY:	GLOBAL

PASS:
	*ds:si - chunk array
	ax - element number
	cx:dx - buffer for element

RETURN:
	ax - element size
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version
	AY	7/22/93		use movsw and merge GetElementLow into here

------------------------------------------------------------------------------@

ChunkArrayGetElement	proc	far	uses cx, si, di, es
	.enter

EC <	call	ECCheckChunkArray					>

EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	mov	es, cx
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_elementSize
	call	ChunkArrayElementToPtr	;ds:di = element, cx = size
EC <	ERROR_C ELEMENT_ARRAY_BAD_TOKEN					>
	mov	si, di			;ds:si = element
	mov	di, dx			;es:di = buffer
	mov	ax, cx			;ax returns size

	shr	cx
	rep	movsw
	jnc	notOdd
	movsb
notOdd:

	.leave
	ret
ChunkArrayGetElement	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChunkArrayElementResize

DESCRIPTION:	Resize an element in a variable sized element array

CALLED BY:	GLOBAL

PASS:
	*ds:si - array
	ax - element number
	cx - new size

RETURN:
	carry set if LMF_RETURN_ERRORS and resize could not be performed
	carry clear if ok

DESTROYED:
	none

  ** WARNING
	If you are resizing the element larger then chunks on the
	lmem heap may move. This means that all direct pointers
	into the lmem heap are not valid after a call to this
	routine.
	
	In addition to this, if you are resizing an element larger
	then the lmem-heap itself may move on the global heap. This
	means that any segment registers or stored segments which
	refer to the heap are not valid after a call to this routine.

	If you are resizing the element smaller then all pointers
	and segments are still valid after the call.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version

------------------------------------------------------------------------------@

ChunkArrayElementResize	proc	far	uses ax, bx, cx, dx, di, bp
	.enter

EC <	mov	bx, ds:[si]						>
EC <	cmp	ds:[bx].CAH_elementSize, 0				>
EC <	ERROR_NZ	CANNOT_RESIZE_FIXED_SIZE_ELEMENT		>

EC <	call	ECCheckChunkArray					>

EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	mov	bx, cx				;bx = new size
	call	ChunkArrayElementToPtr		;cx = old size
EC <	ERROR_C	BAD_ELEMENT_PASSED_TO_CHUNK_ARRAY_RESIZE		>
NEC <	jc	done				;return C set		>
	mov	di, ds:[si]
	xchg	ax, bx				;ax = new size,
						;bx = element number
	shl	bx
	add	bx, ds:[di].CAH_offset
	mov	bp, bx				;save in case insert fails
	add	bx, di				;ds:bx = offset to element
	sub	ax, cx				;ax = size change
	clr	dx				;no change in var offset table
						; size
	call	UpdateVarOffsets

	mov	bx, ds:[bx]			;bx = offset of element
	add	bx, cx				;bx points at end of element
	tst	ax
	jns	bigger

	; making chunk smaller -- delete bytes at the end

	add	bx, ax
	mov_tr	cx, ax
	neg	cx
	mov	ax, si
	call	LMemDeleteAt
	clc					;just to be sure
	jmp	done

bigger:
	mov_tr	cx, ax
	mov	ax, si
	call	LMemInsertAt
	jnc	done
	
	; insert failed, so readjust var offsets before we return the error
	
	mov	bx, bp
	add	bx, ds:[si]			;ds:bx <- block offset of
						; pivotal var offset
	mov_tr	ax, cx
	neg	ax				;ax <- adjustment for var
						; offsets after ds:bx
						;(dx still 0)
	call	UpdateVarOffsets
	stc

done:
EC <	call	ECCheckChunkArray					>
	.leave
	ret

ChunkArrayElementResize	endp

ChunkArray ends

;----------------------------

Sort segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArraySort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort an array into ascending order

CALLED BY:	GLOBAL
PASS:		*ds:si	= array to sort
		bx = value to pass to callback (in bx)
		cx:dx	= fptr to callback routine
			  must be vfptr in XIP'ed geodes
			PASS:	    bx		= value passed to ChunkArraySort
				    ds:si	= first array element
				    es:di	= second array element
			RETURN:	    flags set so routine can jl, je or jg
				    depending as the first element is less-than,
				    equal-to, or greater-than the second.
			DESTROYED:  ax, bx, cx, dx, si, di
RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 3/90	Initial version
	don	 3/27/91	Added quicksort
	john	 8/14/91	Added parameter block
	todd	 4/23/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChunkArraySort	proc	far
	uses	ax, bx, di, si, es
params	local	QuickSortParameters
	.enter
	;
	;  Check Array for irregularities.
EC<	call	ECCheckChunkArray				>

	;
	; Initialize the stack frame.
	;
	mov	params.QSP_compareCallback.segment, cx
	mov	params.QSP_compareCallback.offset, dx
	
	mov	params.QSP_lockCallback.segment, 0
	mov	params.QSP_unlockCallback.segment, 0
	
	mov	params.QSP_insertLimit, DEFAULT_INSERTION_SORT_LIMIT
	mov	params.QSP_medianLimit, DEFAULT_MEDIAN_LIMIT
	
	;
	; Set up for sorting by getting a pointer to the array base.
	;
	mov	si, ds:[si]			; ds:si <- ptr to array header
	mov	ax, ds:[si].CAH_elementSize	; ax <- size of elements

EC <	tst	ax						>
EC <	ERROR_Z	CANNOT_SORT_VARIABLE_SIZED_CHUNK_ARRAYS		>
	
	mov	cx, ds:[si].CAH_count		; cx <- # of elements
	cmp	cx, 1				; 1 or less is already sorted
	jbe	done

	add	si, ds:[si].CAH_offset		; ds:si <- ptr to array base
	segmov	es, ds				; es <- array segment

	;
	;  Because we reside in a movable code resource, we must verify
	;  that the fptrs to the callbacks are not in the XIP area.
if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckParamBlock				>
endif

	;
	; ds,es	= Segment of the chunk array
	; si	= Offset to first elemet in the array
	; ax	= Size of each element
	; cx	= Number of elements
	; ss:bp	= Inheritable QuickSortParameters
	; bx	= Value to pass to callback
	;
	call	ChunkArrayQuickSort		; Sort the array

done:
	.leave
EC <	call	ECCheckChunkArray				>
	ret
ChunkArraySort endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArrayQuickSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sorts the passed array using a modified quicksort algorithm.

CALLED BY:	GLOBAL
	
PASS:		ds:si	= Start of array
		ax	= Size of each element
		cx	= Number of elements in the array
		ss:bp	= Inheritable QuickSortParameters (see chunkarr.def)
		bx	= Value to pass to callback (in bx)
RETURN:		Nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/30/91		Initial version
	John	8/14/91		Changed to pass parameter structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ArrayQuickSort	proc	far
	uses	bx, di, si, es
	.enter
	segmov	es, ds				; ES points at array also
	call	ChunkArrayQuickSort		; perform the sort
	.leave
	ret
ArrayQuickSort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayQuickSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Implement quicksort for chunk arrays. The array is sorted
		in ascending order. That is, the first element will be the
		smallest in the array. This code isn't actually specific
		to ChunkArray's. It actually works with any array.

CALLED BY:	Internal
	
PASS:		ds, es	= Segment of chunk array
		si	= First array element to sort
		ax	= Size of each element
		cx	= Number of elements to sort
		ss:bp	= Inheritable QuickSortParameters (see chunkarr.def)
		bx	= Value to pass to callback (in bx)

RETURN:		Nothing

DESTROYED:	BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:
	Quicksort is outlined pretty thoroughly in Knuth Volume 3, pp 114-123.
	The implementation here is fairly straightforward with the following
	additions:
	      1 - In order to avoid the worst case (n^2) behavior associated
		  with a sorted list the routine begins by choosing the
		  median of the first, middle, and last elements of the list.
		  
		  Knuth says on page 123:
			The worst case is still of order n^2, but such slow
			behavior will hardly ever occur.

	      2 - In order to minimize the amount of stack space, which can
		  be of order N in a worst case scenario, the smaller part
		  of the partitioned list is processed first. This ensures
		  that the amount of stack space is of order log2(n) and
		  never worse. This is mentioned by Knuth on page 115.

	A basic idea behind Quicksort is to generate a list that looks like
	this:
		l = left edge of the list
		r = right edge of the list

		R(l)...R(k-1) R(k) R(k+1)...R(r)
	such that:
		R(l...k-1) < R(k) < R(k+1...r)

	The first element in the list is designated as the key. To move a
	key into it's final position we do the following:
	    key = l
	    partition = l
	    for (i = l; i < r; i++) do
		if R(key) < R(i) then
		    /* Do nothing, R(i) is in the proper part of the list */
		else
		    /* R(i) is in the wrong part of the list */
		    Swap( i, partition )
		    parition += 1
		endif
	    end
	    
	    Swap( key, partition-1 )

	The 'partition' tells us where we will be finally positioning the
	key. At any given point we know:
		R(l...partition-1) < R(key) < R(partition...i)

	When we are done we swap the key with the entry before the parition to
	generate the final ordering we want.

	Then we make two recursive calls to sort the lists on the left and
	right of the correctly positioned item.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/27/91		Initial version
	John	8/8/91		Added documentation and enhancement #2 above
	John	8/14/91		Added parameter block
	todd	4/23/94		XIP'ed
	AY	4/29/96		"call" -> "jmp" to make enhancement #2 work

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChunkArrayQuickSort	proc	near
params	local	QuickSortParameters
	.enter	inherit
EC<	call	ECCheckParamBlock					>
EC<	jcxz	emptyArray						>
EC<	push	ax, dx, si						>
EC<	call	ECCheckBounds						>
EC<	mul	cx							>
EC<	tst	dx							>
EC<	ERROR_NZ	ADDRESS_OUT_OF_BOUNDS				>
EC<	dec	ax	; make sure checks are for the actual last byte	>
EC<			; not the first byte of the first non-existent	>
EC<			; element -- ardeb 4/14/94			>
EC<	add	si, ax							>
EC<	ERROR_C		ADDRESS_OUT_OF_BOUNDS				>
EC<	call	ECCheckBounds						>
EC<	pop	ax, dx, si						>
EC< emptyArray:								>

	;
	; Check to see if we should use just simple insertion sort
	; Else find median element to use as key - this evidently leads
	; to a more efficient algorithm than using the first element as
	; the key.
	;
	; ax	= Size of each element
	; cx	= # of elements in the list
	; ds,es	= Segment address of the array
	; si	= Offset of first element in the array
	; bp	= QuickSortParameters
	; bx	= Value to pass to callback
	;
	; dx, di unused
	;
	; Check to see if the list is already sorted.
	;
	cmp	cx, 1				; A single element is sorted
	LONG jbe done				; Branch if sorted

	;
	; Check to see if we want to be using the insertion sort instead
	; of quicksort. It turns out to be faster for smaller arrays.
	;
	cmp	cx, params.QSP_insertLimit	; Check count against limit
	ja	checkMedian			; Branch to use quicksort
	
	;
	; Use the insertion sort algorithm. The list is small enough.
	;
	call	ChunkArrayInsertionSort
	jmp	done

checkMedian:
	;
	; Check to see if the caller wants us to use the median of three values
	; in choosing the key to sort. In some cases it may take more time to
	; locate the median than it would to just sort the elements. This is
	; only true for very small lists where the cost of a comparison is high.
	;
	cmp	cx, params.QSP_medianLimit	; Check count against limit
	jb	quicksort			; Branch if below limit

	;
	; Quicksort has a horrible worst case performance if the list is
	; sorted. In order to avoid this case we find the median of 3 values
	;	The first, middle, and last elements
	;
	; ds:si	= Pointer to first element
	; es	= Same as ds
	; ax	= Element size
	; cx	= # of elements
	; bp	= QuickSortParameters
	; bx	= Value to pass to callback (in bx)
	;
	push	si, ax			; first element, element size
	push	ax			; Save element size again
	
	;
	; Compute the position of the middle:
	;	middlePos = (elementSize * numEntries/2) + startPos
	;
	mov	dx, cx			; dx <- numEntries
	shr	dx, 1			; dx <- numEntries / 2

	pushf				; save carry flag (indicates odd #)
	mul	dx			; ax <- elementSize * numEntries/2
EC <	ERROR_C	CHUNK_ARRAY_QUICK_SORT_OVERFLOW			>

	mov	di, ax			; di <- offset to middle

	xchg	dx, ax			; dx <- offset to middle
					; ax <- numEntries / 2
	
	add	di, dx			; di <- offset to last entry
	popf				; Restore carry flag (odd # entries)
	pop	ax			; Restore element size

	;
	; ds,es	= Segment address of the array
	; si	= Offset to first element
	; di	= Offset to the last element
	; dx	= Offset to the middle
	;
	; ax	= Size of the elements
	; cx	= # of entries in the list
	;
	; bp	= QuickSortParameters
	; bx	= Value to pass to callback (in bx)
	;
	; On stack:
	;	Element size
	;	Pointer to first element
	;
	; Carry set if the number of elements is an odd number. 
	;
	; If it's an even count (carry clear) then we want to move di backwards
	; one element. 
	;
	; The reason for this is that the array is zero based. That means that
	; the offset to the middle element that we've computed for an even
	; sized array will actually refer to the first entry in the second
	; half of the list. If we just multiply this by two (as we've done
	; already) we will have the offset past the end of the array.
	;
	jc	firstTest		; Branch if odd sized array.
	sub	di, ax			; Even count, move back one entry.

firstTest:
	;
	; Since di and dx are offsets from the start of the array we need to
	; add the base of the array to generate the pointers we need.
	;
	add	di, si			; di <- ptr to last element
	add	dx, si			; dx <- ptr to middle element

	;
	; Compare the first element (si) to the last element (di).
	; What we want to do is to put the smaller of *si and *di into si.
	;
	call	CallCallback		; compare DS:SI and ES:DI
	jl	secondTest
	xchg	di, si			; smaller => DS:SI

secondTest:
	;
	; ds:si	= Pointer to the smaller from first comparison
	; es:di = Pointer to the larger from first comparison
	; dx	= Pointer to the next element to check (middle element)
	;
	; We compare *si to *dx. If si is larger then we know that si points
	; to the median value (since dx < si < di).
	;
	xchg	dx, di			; dx <- larger of first comparison
					; di <- middle element
	call	CallCallback		; Compare DS:SI and ES:DI
	jg	partition		; Branch if median is already in si

	;
	; We've swapped a few things around, but here's what we have:
	; si	= Pointer to the smaller of the second comparison
	;	  	and the smaller of the first comparison.
	; dx	= Pointer to the larger of the first comparison
	; di	= Pointer to the larger of the second comparison
	;	(*si < *di) and (*si < *dx)
	; It should be clear that si does not point to the median. The smaller
	; of *dx and *di contains the median.
	;
	mov	si, dx			; si <- larger of 1st computation
	call	CallCallback		; compare two winners
	jl	partition		; if less, median is in SI
	mov	si, di			; si <- pointer to median

partition:
	;
	; ds,es	= Segment address of the array.
	; si	= Offset to the median (key to use for this sort).
	; On stack:
	;	Element size
	;	Pointer to first element
	;
	; We want to swap median to first position so that we can sort it.
	;
	mov	di, si			; di <- offset to the median
	pop	si, ax			; Restore ptr to 1st element, size

	call	ChunkArraySwapSIDI	; swap key to 1st

quicksort:
	;
	; Keeping ds:si as the key whose position we want to find, we now
	; setup di as the pointer to the "current" entry. That entry falls
	; right after the key.
	;
	; ds,es	= Segment address of the array
	; si	= Key to sort
	; ax	= Size of each element
	; cx	= Number of elements to sort
	; bp	= QuickSortParameters
	; bx	= Value to pass to callback (in bx)
	;
	; di will hold the "current" entry.
	;
	; dx unused
	;
	mov	di, si			; di <- pointer to array start
	add	di, ax			; di <- pointer to 2nd element

	mov	dx, di			; dx <- current partition spot
	dec	cx			; cx <- # of entries left in list

	;
	; Initialize the count which tells us how many items in the list
	; fall below the current partition and how many fall above.
	;
	mov	params.QSP_nLesser, 0
	mov	params.QSP_nGreater, 0

	;
	; Before starting the loop which finds the position for the element
	; pointed at by ds:si we call the 'locking' callback to lock the
	; element down. For data where the cost of accessing the element
	; is expensive this allows the application to do any preliminary
	; work necessary to make accessing this same element faster in the
	; heart of the loop.
	;
	tst	params.QSP_lockCallback.segment
	jz	locked			; Branch if no callback

if FULL_EXECUTE_IN_PLACE
	;
	;  In XIP system, need to do PCFOM if movable...
	cmp	params.QSP_lockCallback.segment, 0f000h
	jb	regularLock

	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, params.QSP_lockCallback
	call	ProcCallFixedOrMovable
	jmp	locked
regularLock:
endif

	call	params.QSP_lockCallback
locked:

partitionLoop:
	;	
	; Now we start the partitioning process, with key in SI
	;
	; ds,es	= Segment address of the array.
	; si	= Base of the array (discriminator)
	; di	= Current entry to check
	; ax	= Size of the elements.
	; dx	= Current partitioning position
	; cx	= # of iterations left
	; bp	= QuickSortParameters
	; bx	= Value to pass to callback (in bx)
	;
	call	CallCallback		; Compare key with current element
	jle	next			; Branch if element in right spot
	
	;
	; The element isn't in the right part of the list. We want to swap
	; it with the element at the partition position in order to put it
	; in the right part of the list.
	;
	xchg	dx, si			; si <- partition position
					; dx <- key
	call	ChunkArraySwapSIDI	; Swap current element with partition
	xchg	dx, si			; si <- key
					; dx <- partition position

	;
	; Since we've shifted an element which belongs at the lower end of the
	; list we now advance the partition position to reflect that all the
	; elements before the partition are less than the key.
	;
	add	dx, ax			; Advance the partition
	
	;
	; Since the current element is smaller than the key we increment
	; that counter. Since the default action after we fall thru is to
	; increment the number of elements that is greater than the key
	; we want to compensate here by decrementing that counter.
	;
	inc	params.QSP_nLesser
	dec	params.QSP_nGreater

next:
	;
	; Move to consider the next element in the list. At this point
	; either the current entry is known to be greater than the key
	; or else we've compensated for the fact that it is less.
	;
	inc	params.QSP_nGreater
	add	di, ax			; Advance current entry
	loop	partitionLoop		; Loop to process next entry

	;
	; We have successfully determined the position for the key, before
	; proceeding we unlock the element whose position we have determined
	; before we actually move it.
	;
	tst	params.QSP_unlockCallback.segment
	jz	unlocked		; Branch if no callback
if	FULL_EXECUTE_IN_PLACE
	;  In XIP system, need to do PCFOM if movable...
	cmp	params.QSP_lockCallback.segment, 0f000h
	jb	regularUnlock

	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, params.QSP_unlockCallback
	call	ProcCallFixedOrMovable
	jmp	unlocked
regularUnlock:
endif

	call	params.QSP_unlockCallback
unlocked:

	;
	; We swap the key with the element before the current partition
	; position to generate a list with the upper half greater than
	; the key and the lower half less.
	;
	mov	di, dx
	sub	di, ax			; Swap partition with key
	call	ChunkArraySwapSIDI
	
	;
	; Now process the two sub-lists recursively.
	;
	; ds,es	= Segment address of the list
	; ax	= Element size
	; cx will be used to hold the # of elements in the lists
	; bp	= QuickSortParameters
	; bx	= Value to pass to callback (in bx)
	;
	; si	= Pointer to the start of the lesser list
	; dx	= Offset to the start of the greater list
	;
	; di unused
	;
	mov	cx, params.QSP_nLesser
	mov	di, params.QSP_nGreater
	
	;
	; ds,es	= Segment address of the list
	; ax	= Element size
	; bp	= QuickSortParameters
	;
	; si/cx	= Pointer/size for lesser list
	; dx/di	= Pointer/size for upper list
	;
	; We want to process the smaller list first. This will ensure that
	; the amount of stack space we use will be no worse than log2(n)
	; stack frames.
	;
	cmp	cx, di			; Find smaller
	jle	gotSmaller
	xchg	si, dx			; Swap first/last list ptrs
	xchg	cx, di			; Swap first/last list sizes
gotSmaller:

	;
	; si/cx	= Pointer/size for first list to do
	; dx/di	= Pointer/size for second list to do
	;
	push	dx, di			; Save start & count of 2nd list
	call	ChunkArrayQuickSort	; Sort first list

	pop	si, cx			; si <- ptr, cx <- size of 2nd list
	;
	; Use "jmp" rather than "call" here, so that the stack space
	; optimization actually works.  Of course it is possible only because
	; we don't have ".uses" and all local variables are inherited from our
	; caller.	--- AY 4/29/96
	;
	jmp	ChunkArrayQuickSort	; sort second partition

done:
	.leave
	ret
ChunkArrayQuickSort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the sorting comparison routine.

CALLED BY:	ChunkArrayQuickSort, ChunkArrayInsertionSort
PASS:		ds:si	= First element
		es:di	= Second element
		ss:bp	= Inheritable QuickSortParameters
		bx	= Value to pass to callback (in bx)
RETURN:		Flags set so routine can jl, je or jg depending as the
		first element is less-than, equal-to, or greater-than
		the second.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Determine if we are calling a regular routine, or
		one which resides in an XIP geode.  If the segment
		of the callback is a vseg, that means we are calling
		and XIP geode, and must use ProcCallFixedOrMovable


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	 8/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallCallback	proc	near
	uses	ax, bx, cx, dx, di, si
params	local	QuickSortParameters
	.enter	inherit
	;
	;  See if segment of callback is a vseg.
FXIP<	cmp	{byte}params.QSP_compareCallback.high+1, 0f0h	>
FXIP<	jae	doProcCall	; => It is a vseg		>

	call	params.QSP_compareCallback
done::
	.leave
	ret
if	FULL_EXECUTE_IN_PLACE
doProcCall:
	;
	;  Set up call to ProcCallFixedOrMovable and call the
	;  XIP resource.
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, params.QSP_compareCallback
	call	ProcCallFixedOrMovable
	jmp	short done
endif
CallCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArrayInsertionSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort the passed chunk array using insertion sort

CALLED BY:	ChunkArrayQuickSort
	
PASS:		ds, es	= Segment of chunk array
		si	= First array element to sort
		ax	= Size of each element
		cx	= Number of elements to sort
		bp	= Inheritable QuickSortParameters (see chunkarr.def)
		bx	= Value to pass to callback (in bx)

RETURN:		Nothing

DESTROYED:	BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 3/90	Inital version
	Don	 3/27/91	Moved to different routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChunkArrayInsertionSort	proc	near
	.enter

	;
	; ds:si is now the element that we want to replace with the smallest
	; item in the array.
	;
		jcxz	done		; if no elements, don't sort
sortLoop:
		mov	dx, si		; assume first is smallest
		push	cx		; save # elements left to sort
		mov	di, si
searchNext:
		add	di, ax		; advance to next
		loop	searchLoop
		jmp	haveSmallest
searchLoop:
		push	si
		mov	si, dx		; si <- current smallest
		call	CallCallback	; compare ds:si and es:di
		pop	si
		jle	searchNext	; ds:dx still smaller
		mov	dx, di		; record di as new smallest
		jmp	searchNext

haveSmallest:
	;
	; We've located the current smallest element in the array, so swap
	; it with the first element (unless, of course, the first *is* the
	; smallest)
	;
		mov	di, dx
		call	ChunkArraySwapSIDI
		add	si, ax		; go to next element
		pop	cx		; restore # elements left to sort
		loop	sortLoop
done:
	.leave
	ret
ChunkArrayInsertionSort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChunkArraySwapSIDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap chunk array elements

CALLED BY:	INTERNAL (ChunkArrayQuickSort, ChunkArrayInsertionSort)
	
PASS:		DS, ES	= Segment of chunk array
		AX	= Size of each element
		SI	= 1st element offset
		DI	= 2nd element offset

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should this be a macro, to speed things up ??

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/27/91		Stolen from original ChunkArraySort (Adam)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChunkArraySwapSIDI	proc	near
	uses	ax, cx, di, si
	.enter

		cmp	di, si
		je	done
		xchg	cx, ax		; cx <- element size
		shr	cx		; convert to words
		jnc	swapWords	; => even so can start swapping words
		mov	al, ds:[di]	; swap initial byte
		xchg	al, ds:[si]
		stosb
		inc	si
		jcxz	done		; => swapping is done
swapWords:
		mov	ax, ds:[di]
		xchg	ax, ds:[si]
		stosw
		inc	si
		inc	si
		loop	swapWords
done:
	.leave
	ret
ChunkArraySwapSIDI	endp

Sort ends


;=============================================================================
;		Error checking
;=============================================================================

kcode segment

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckChunkArray

DESCRIPTION:	Check a general array structure for validity

CALLED BY:	INTERNAL

PASS:
	*ds:si - array

RETURN:
	non

DESTROYED:
	non

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK

ECCheckChunkArray	proc	far	uses ax, bx, cx, dx, si
	.enter
	pushf

	call	ECLMemValidateHeapFar

	xchg	ax, si
	call	ECLMemExists
	xchg	ax, si

	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx		;cx = size

	mov	ax, ds:[si].CAH_elementSize
	tst	ax
	jz	var

	mul	ds:[si].CAH_count
	tst	dx
	ERROR_NZ	CORRUPT_CHUNK_ARRAY
	add	ax, ds:[si].CAH_offset
	ERROR_C		CORRUPT_CHUNK_ARRAY
	cmp	ax, cx
	ERROR_NZ	CORRUPT_CHUNK_ARRAY
	jmp	done

var:
	mov	dx, cx				;dx = chunk size
	mov	cx, ds:[si].CAH_count
	add	si, ds:[si].CAH_offset
	jcxz	done
	dec	cx
	jcxz	lastElement
varLoop:
	mov	ax, ds:[si][2]
	cmp	ax, ds:[si]
	ERROR_B	CORRUPT_CHUNK_ARRAY
	add	si, 2
	loop	varLoop
lastElement:
	cmp	dx, ds:[si]
	ERROR_B	CORRUPT_CHUNK_ARRAY

done:
	popf
	.leave
	ret

ECCheckChunkArray	endp

else

ECCheckChunkArray	proc	far
	ret
ECCheckChunkArray	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckParamBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the QuickSortParameter block has valid entries

CALLED BY:	INTERNAL

PASS:		ss:bp	-> ptr to QSP to check
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Fatal Errors if something messed up

PSEUDO CODE/STRATEGY:
		When running under full XIP, we want to make sure that
		the fptrs being passed in as callbacks are valid.
		Since much of the code is in movable resources, this
		means that they can not point to routines in the XIP
		segment itself, since it can be swapped out.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	3/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK

ECCheckParamBlock	proc	far
if	FULL_EXECUTE_IN_PLACE

	uses	bx, si
	.enter inherit ChunkArrayQuickSort
	;
	;  Because we are in a movable code segment, we need to assert
	;  that the fptrs we are passed do not lie in the XIP
	;  segment.
	movdw	bxsi, params.QSP_compareCallback

	call	ECAssertValidFarPointerXIP

	movdw	bxsi, ss:[params].QSP_lockCallback

	tst	bx
	jz	checkUnlock

	call	ECAssertValidFarPointerXIP

checkUnlock:
	movdw	bxsi, ss:[params].QSP_unlockCallback

	tst	bx
	jz	popAndGo

	call	ECAssertValidFarPointerXIP

popAndGo:

	.leave
endif
	ret
ECCheckParamBlock	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCurOffsetChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the SavedCurOffsetStruct chain for validity.
		It could get messed up if two threads try to perform
		an operation on the chunkArray that uses this structure
		(ChunkArrayEnum, ChunkArrayInsertAt, ChunkArrayDeleteRange)

CALLED BY:	INTERNAL
			ChunkArrayEnum
			ChunkArrayInsertAt
			ChunkArrayDeleteRange

PASS:		*ds:si	= ChunkArray
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	3/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK

ECCheckCurOffsetChain	proc	far
	uses	bp, bx, ax
	pushf
	.enter

	mov	bp, ds:[si]
	mov	bp, ds:[bp].CAH_curOffset
	;
	; SavedCurOffset chain is stored below stackBot
	;
	mov	bx, ss:[TPD_stackBot]

offsetLoop:
	tst	bp
	jz	done				; none to do

	;
	; Since there can be only one of these chains per ChunkArray,
	; it had better only be manipulated by one thread at a time.
	;
	mov	ax, ss:[bp].SCOS_thread
	cmp	ax, ss:[TPD_threadHandle]
	WARNING_NE CHUNK_ARRAY_ENUM_INSERT_OR_DELETE_RUN_BY_MULTIPLE_THREADS
	;
	; This SavedCurOffsetStruct must be lower on the stack segment
	; than the last one.
	;
	cmp	bp, bx
	WARNING_NB CHUNK_ARRAY_ENUM_INSERT_OR_DELETE_RUN_BY_MULTIPLE_THREADS 
	mov	bx, bp

	mov	bp, ss:[bp].SCOS_next		; bp = next curOffset
	jmp	offsetLoop

done:
		
	.leave
	popf
	ret
ECCheckCurOffsetChain	endp

endif



kcode ends
