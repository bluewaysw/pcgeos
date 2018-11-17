COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/LMem
FILE:		lmemElementArray.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ElementArrayCreate	Create a new element array with 0 elements
   GLB	ElementArrayGetElement	Get an element given its element number
   GLB	ElementArrayAddReference Add a reference to an element
   GLB	ElementArrayAddElement	Add an element (or add a reference to an
				existing element)
   GLB	ElementArrayRemoveReference Remove a reference to an element

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:
	This file contains routines to load a GEODE and execute it.

	$Id: lmemElementArray.asm,v 1.1 97/04/05 01:14:23 newdeal Exp $

------------------------------------------------------------------------------@

ChunkArray segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayCreate

DESCRIPTION:	Create a new element array with 0 elements

CALLED BY:	GLOBAL

PASS:
	ds - block for new array
	bx - element size (0 for variable size elements)
	cx - size for ChunkArrayHeader (this allows for reserving extra
	     space)  0 = default
	si - chunk handle to use (or 0 if we want to alloc one)
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
	Tony	7/91		Initial version

------------------------------------------------------------------------------@

ElementArrayCreate	proc	far	uses cx
	.enter

EC <	call	ECLMemValidateHeapFar					>

	tst	cx
	jnz	notZero
	mov	cx, size ElementArrayHeader
notZero:

	call	ChunkArrayCreate		;marks chunk dirty
	jc	exit
	push	si
	mov	si, ds:[si]
	mov	ds:[si].EAH_freePtr, EA_FREE_LIST_TERMINATOR
	pop	si

EC <	call	ECCheckChunkArray					>
exit:
	.leave
	ret

ElementArrayCreate	endp


COMMENT @---------
-------------------------------------------------------------

FUNCTION:	ElementArrayAddReference

DESCRIPTION:	Add a reference to an element

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	ax - element number

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
	Tony	7/91		Initial version

------------------------------------------------------------------------------@

ElementArrayAddReference	proc	far	uses cx, di
	.enter

EC <	call	ECCheckChunkArray					>

EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	call	ObjMarkDirty

	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_elementSize
	call	ChunkArrayElementToPtr	;ds:di = element, cx = size
EC <	ERROR_C ELEMENT_ARRAY_BAD_TOKEN					>
EC <	cmp	ds:[di].WAAH_high, EA_FREE_ELEMENT			>
EC <	ERROR_Z	ELEMENT_ARRAY_BAD_TOKEN					>

	inc	ds:[di].REH_refCount.WAAH_low
	jnz	done
	inc	ds:[di].REH_refCount.WAAH_high
EC <	ERROR_Z	ELEMENT_ARRAY_TOO_MANY_REFERENCES			>
done:

EC <	call	ECCheckChunkArray					>

	.leave
	ret

ElementArrayAddReference	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayAddElement

DESCRIPTION:	Add an element (or add a reference to an existing element)

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	cx:dx - element to add (vfptr if XIP'ed geode)
	ax - size of element (if variable)
	bx:di - fptr to routine to call to compare elements (0 for straight
		binary comparison) (vfptr if XIP'ed geode)
	bp - value to pass to callback in ax
			Pass:
				es:di - element to add
				ds:si - element from array
				cx - size of element (element sizes must match
				     or callback is not called)
				ax - value for callback
			Return:
				carry flag - set if elements equal
			Destroyed:
				ax, bx, cx, dx

RETURN:
	ax - element number
	carry - set if this element was newly added

DESTROYED:
	es, if pointing to ds on entry
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
	Tony	7/91		Initial version
	Todd	3/94		XIP'ed

------------------------------------------------------------------------------@

ElementArrayAddElement	proc	far	uses bx, cx, dx, si, di, es
elementSize	local	word	\
			push	ax
callback	local	fptr	\
			push	bx, di
	; EC: if ES is pointing to DS on entry, we have to return it nulled,
	; as there was no attempt made before to fix it up (as should have
	; been done for all lmem code), and it's too late to change the API
	; now -- ardeb
EC <	mov	ax, es							>
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	cmp	ax, bx							>
EC <	jne	esOK							>
EC <	mov	ax, NULL_SEGMENT					>
EC <esOK:								>
EC <	mov	es, ax							>
EC <	pop	bx							>

	ForceRef	callback
	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
	
	;
	;  Because we reside in the ChunkArray segment, and therefore are
	;  not fixed, we need to validate passed in fptrs to callback
	;  routines to make sure they are not direct fptrs to our segment
	;
EC<	tst	bx			; see if straight comparison?	>
EC<	jz	continue						>
EC<	xchg	si, di							>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	xchg	di, si							>
continue::
endif

EC <	call	ECCheckChunkArray					>

	;
	; Clear the LMF_RETURN_ERRORS flag since there is no error handle
	; code here.
	;
	push	ds:[LMBH_flags]
	andnf	ds:[LMBH_flags], not (mask LMF_RETURN_ERRORS)	;clr this flag

	call	ObjMarkDirty

	mov	es, cx
	mov	di, dx				;es:di = element to add

	call	FindElement
	jc	found

	; not found -- add a new elemennt

	mov	ax, si
	mov	bx, ds:[si]
	mov	cx, dx
	tst	dx
	jnz	gotSize
	mov	cx, elementSize
gotSize:

	; look on free list first -- if no room there then append

	mov	si, ds:[bx].EAH_freePtr
	cmp	si, EA_FREE_LIST_TERMINATOR
	LONG jz	append

	tst	dx
	jnz	noVariableResize

	; resize variable sized thing to the correct size

	xchg	ax, si				;*ds:si = chunk, ax = element #
	mov	dx, ax				;dx = element number to return
	call	ChunkArrayElementResize
	mov	bx, ds:[si]
	xchg	ax, si				;ax = chunk, si = element number
	shl	si
	add	si, ds:[bx].CAH_offset
	add	si, bx				;ds:si = element
	mov	si, ds:[si]
	add	si, bx
	jmp	afterResize

noVariableResize:
	mov_trash	ax, dx			;ax = element size
	mul	si
	mov	dx, si
	mov_trash	si, ax
	add	si, bx				;ds:si = free element
	add	si, ds:[bx].CAH_offset

afterResize:

	; we found one on the free list -- use it

	mov	ax, ds:[si].REH_refCount.WAAH_low
	mov	ds:[bx].EAH_freePtr, ax

	mov_trash	ax, dx				;ax = element # to ret

	; ds:si = new element, es:di = element passed in
	; ax = element # to return, cx = element size

common:
	mov	ds:[si].REH_refCount.WAAH_low, 1	;store ref count and
	mov	ds:[si].REH_refCount.WAAH_high, 0	;bump pointer so we
							;don't copy it
	add	si, size RefElementHeader
	add	di, size RefElementHeader
	sub	cx, size RefElementHeader

	; ds:si = new element (pointing past ref count)
	; es:di = element passed (pointing past ref count)
	; cx = bytes to copy

	push	ds
	segxchg	ds, es				;ds:si = element to add
	xchg	si, di				;es:di = destination
	rep movsb
	pop	ds
	stc
	jmp	done

	; element was found -- up the reference count
	; ds:ax = element

found:
	mov	bx, si				;*ds:si = chunk
	mov	si, ax				;ds:si = element
	mov	bx, ds:[bx]			;ds:bx = chunk
	sub	ax, bx				;ax = element offset
	sub	ax, ds:[bx].CAH_offset
	tst	dx
	jnz	notVariable2
	mov	si, ds:[si]
	add	si, bx
	shr	ax				;ax = element number
	jmp	common2

notVariable2:
	mov	cx, dx
	clr	dx
	div	cx				;ax = element number
common2:

	; ds:si points at reference count (24 bit number)

	inc	ds:[si].WAAH_low
	jnz	10$
	inc	ds:[si].WAAH_high
EC <	ERROR_Z	ELEMENT_ARRAY_TOO_MANY_REFERENCES			>
10$:

	clc					;not newly added
done:
	;
	; Restore the LM flags here
	; 
	pop	cx				;cx = original LM flags
	pushf
	andnf   cx, mask LMF_RETURN_ERRORS
	ornf    ds:[LMBH_flags], cx		;restore LM flags
	popf

	.leave
EC <	call	ECCheckChunkArray					>
	ret

;--------

	; cx = element size

append:
	mov_tr	si, ax				;*ds:si = array
	push	di
	mov	ax, cx				;ax = size (if variable)
	call	ChunkArrayAppend		;ds:di = element
	call	ChunkArrayPtrToElement		;ax = element number
	mov	si, di
	pop	di
	jmp	common

ElementArrayAddElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindElement

DESCRIPTION:	Find an element in an element array

CALLED BY:	INTERNAL

PASS:
	*ds:si - element array
	es:di - element to find
	ss:bp - inherited variables

RETURN:
	carry - set if found
	ds:ax - element found
	dx - element size if fixed or 0

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/92		Initial version

------------------------------------------------------------------------------@
FindElement	proc	near	uses bx, cx, si
elementSize	local	word
callback	local	fptr
	.enter inherit far

	; try to find the element in the list

	mov	ax, si				;ax saves chunk handle
	mov	si, ds:[si]			;ds:si = element array
	mov	dx, ds:[si].CAH_elementSize
	mov	cx, ds:[si].CAH_count
	tst_clc	cx
	LONG jz	done
	add	si, ds:[si].CAH_offset		;ds:si = first element

	; ds:si = element array, cx = count, dx = element size

theLoop:
	push	cx, si, di

	tst	dx
	jnz	noVariableCompare

	; variable sized -- get element size and dereference

	push	di
	mov	di, ax
	mov	di, ds:[di]
	cmp	cx, 1
	mov	cx, ds:[si][2]
	jnz	varCommon
	ChunkSizePtr	ds, di, cx
varCommon:
	sub	cx, ds:[si]			;cx = size
	cmp	cx, elementSize
	jnz	varToAfterCompare
	mov	si, ds:[si]			;si = offset of element
	add	si, di
	pop	di
	jmp	compareCommon

varToAfterCompare:
	pop	di
	clc
	jmp	afterCompare

noVariableCompare:

	; check for free element

	mov	cx, dx				;get size (fixed)
compareCommon:
	cmp	ds:[si].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	clc
	jz	afterCompare

	cmp	callback.segment, 0
	jz	notCustomCompare

	; call callback routine to do comparison

	push	ax, dx
	mov	ax, ss:[bp]			;value for callback
	mov	ss:[TPD_dataAX], ax
	movdw	bxax, callback
	call	ProcCallFixedOrMovable		;carry - set if equal
	pop	ax, dx
	jmp	afterCompare

notCustomCompare:
	add	si, size RefElementHeader	;skip ref count
	add	di, size RefElementHeader
	sub	cx, size RefElementHeader
	repe cmpsb
	stc
	jz	afterCompare
	clc
afterCompare:
	pop	cx, si, di
	jc	found

	; move to next element

	add	si, dx
	tst	dx
	jnz	notVariable
	inc	si
	inc	si
notVariable:

	loop	theLoop
	clc
done:
	.leave
	ret

found:
	mov_tr	ax, si
	jmp	done

FindElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayDelete

DESCRIPTION:	Delete an element regardless of its reference count

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	ax - element number

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
	Tony	7/91		Initial version

------------------------------------------------------------------------------@

ElementArrayDelete	proc	far	uses bx
	.enter
	clr	bx			;clears carry
	call	RemoveRefCommon
	.leave
	ret

ElementArrayDelete	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayRemoveReference

DESCRIPTION:	Remove a reference to an element

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	ax - element number
	bx:di - fptr to routine to call if the element will actually be removed
		(vfptr for XIP'ed geodes)
			Pass:
				ax - callback data
				ds:di - element
			Return:
				none
			Destroyed:
				ax, bx, cx, dx
	cx - value to pass to callback in ax


RETURN:
	carry - set if element actually removed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version
	Todd	3/94		XIP'ed

------------------------------------------------------------------------------@

ElementArrayRemoveReference	proc	far
	stc
	FALL_THRU	RemoveRefCommon
ElementArrayRemoveReference	endp


RemoveRefCommon	proc	far	uses ax, bx, cx, dx, si, di
callback	local	fptr	\
			push	bx, di
	.enter
if	ERROR_CHECK

	;
	;  Because we reside in the ChunkArray segment, and therefore are
	;  not fixed, we need to validate passed in fptrs to the callback
	;  routine to make sure they are not direct fptrs to the XIP segment
FXIP<	pushf								>
FXIP <	tst	bx							>
FXIP <	jz	noCheckCallback						>
FXIP<	xchg	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	xchg	si, di							>
FXIP <noCheckCallback:							>
FXIP<	popf								>

endif

	; NOTE: The carry is passed into this routine.  This only works because
	; the .enter does not trash the carry since the local variable is
	; push initiaized.
EC <	pushf								>
EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>
EC <	call	ECCheckChunkArray					>
EC <	popf								>

	pushf
	call	ObjMarkDirty

	mov	di, si

	push	cx
	call	ChunkArrayElementToPtr	;ds:di = element
EC <	ERROR_C ELEMENT_ARRAY_BAD_TOKEN					>
EC <	cmp	ds:[di].WAAH_high, EA_FREE_ELEMENT			>
EC <	ERROR_Z	ELEMENT_ARRAY_BAD_TOKEN					>
	pop	cx

	; ds:si points at reference count (24 bit number)

	popf
	jnc	removeIt

	tst	ds:[di].REH_refCount.WAAH_low
	jnz	10$
	dec	ds:[di].REH_refCount.WAAH_high
	dec	ds:[di].REH_refCount.WAAH_low
doneNoRemove:
	clc
	jmp	done
10$:
	dec	ds:[di].REH_refCount.WAAH_low
	jnz	doneNoRemove

	; we've removed the last reference, biff it

removeIt:
	tst	callback.segment
	jz	noCallback
	push	ax
	mov	ss:[TPD_dataAX], cx
	movdw	bxax, callback
	call	ProcCallFixedOrMovable
	pop	ax
noCallback:

if	ERROR_CHECK

	; fill the element with 0xcc so if we try to use an element on the
	; free list we will get hosed

	push	ax, cx, di, es
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_elementSize
	call	ChunkArrayElementToPtr	;ds:di = element
	mov	al, 0xcc
	segmov	es, ds
	rep stosb
	pop	ax, cx, di, es
endif

	mov	bx, ds:[si]
	cmp	ds:[bx].CAH_elementSize, 0
	jnz	notVariableSized
	mov	cx, size RefElementHeader
	call	ChunkArrayElementResize
	mov	di, bx
	shl	ax
	add	di, ds:[di].CAH_offset
	add	di, ax
	shr	ax
	mov	di, ds:[di]
	add	di, bx
notVariableSized:

	; remove element by placing it on the free list

	mov	si, ds:[si]
	mov	cx, ds:[si].EAH_freePtr
	mov	ds:[di].REH_refCount.WAAH_low, cx
	mov	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
					;marks free element
	mov	ds:[si].EAH_freePtr, ax	;put the element being removed on the
					;front of the list
	stc
done:

	.leave
EC <	call	ECCheckChunkArray					>
	ret

RemoveRefCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayElementChanged

DESCRIPTION:	Check to see if an element (which has just changed) is now
		equal to another element and needs to be combined with that
		other element.

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	ax - element number
	bx:di - fptr to routine to call to compare elements
		 (0 for straight binary comparison)
		 (vfptr if XIP'ed geode)
	bp - value to pass to callback in ax
			Pass:
				es:di - element to add
				ds:si - element from array
				cx - size of element (element sizes must match
				     or callback is not called)
				ax - value for callback
			Return:
				carry flag - set if elements equal
			Destroyed:
				ax, bx, cx, dx

RETURN:
	ax - new element number

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version
	Todd	3/94		XIP'ed

------------------------------------------------------------------------------@
ElementArrayElementChanged	proc	far	uses bx, cx, dx, di, es
elementSize	local	word	\
			push	ax		;dummy value
callback	local	fptr	\
			push	bx, di
	ForceRef	callback
	.enter

	;
	;  Because we reside in the ChunkArray segment, and therefore are
	;  not fixed, we need to validate passed in fptrs to callback
	;  routines to make sure they are not direct fptrs to the XIP segment
if ERROR_CHECK

FXIP<	tst	bx			; see if straight comparison?	>
FXIP<	jz	findElement						>
FXIP<	push	si							>
FXIP<	mov	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	si							>
findElement::

endif
EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	push	ax				;save token passed
	call	ChunkArrayElementToPtr
	mov	elementSize, cx

	; temporarily mark the element as free so that we don't find it

	push	{word} ds:[di].REH_refCount.WAAH_high
	mov	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	segmov	es, ds				;es:di = element to find

	call	FindElement
	pop	{word} ds:[di].REH_refCount.WAAH_high

	jnc	notFound

	; found a match -- substitute

	mov	bl, ds:[di].REH_refCount.WAAH_high	;bl.cx = ref count
	mov	cx, ds:[di].REH_refCount.WAAH_low
	mov	di, ax					;ds:di = ele found
	tst	dx
	jnz	notVariable
	mov	di, ds:[di]				;convert to element
	add	di, ds:[si]
notVariable:
	add	ds:[di].REH_refCount.WAAH_low, cx
	adc	ds:[di].REH_refCount.WAAH_high, bl

	pop	bx					;cx = token passed
	call	ChunkArrayPtrToElement			;ax = token to return
	push	ax

	mov_tr	ax, bx
	call	ElementArrayDelete

	pop	ax
	jmp	done

notFound:
	pop	ax

done:
	.leave
	ret

ElementArrayElementChanged	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayGetUsedCount

DESCRIPTION:	Get the number of elements in the array that actually hold data

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	bx:di - fptr to callback routine to further qualify elements
		(bx = 0 for none)
		(vfptr if geode XIP'ed)
	cx, dx - data for callback

RETURN:
	ax - number of used elements

DESTROYED:
	none

	Callback:
	Pass:
		*ds:si - array
		ds:di - array element being enumerated
		cx:dx - data for callback
	Return:
		carry - set if element qualifies
	Destroyed:
		ax, bx, cx, dx, si, di - destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version
	Todd	3/94		XIP'ed

------------------------------------------------------------------------------@

ElementArrayGetUsedCount	proc	far	uses bx, cx, dx, di
callback	local	fptr	\
			push	bx, di
callbackData	local	dword	\
			push	cx, dx
	ForceRef callback
	ForceRef callbackData
	.enter

if ERROR_CHECK

FXIP<	tst	bx			; see if no comparison?		>
FXIP<	jz	doEnum							>
FXIP<	push	si							>
FXIP<	mov	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	si							>
doEnum::	

endif

NOFXIP<	mov	bx, cs							>
FXIP<	mov	bx, cs		; pass fptr to ChunkArrayEnum		>
	mov	di, offset GetUsedCountCallback
	clr	cx				;count
	call	ChunkArrayEnum
	mov_tr	ax, cx

	.leave
	ret

ElementArrayGetUsedCount	endp

;---

	; ds:di = element
	; cx = count

GetUsedCountCallback	proc	far
callback	local	fptr
callbackData	local	dword
	.enter inherit far

	call	CallIndexTokenCallback
	jnc	noMatch
	inc	cx
noMatch:
	clc

	.leave
	ret

GetUsedCountCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayUsedIndexToToken

DESCRIPTION:	Get the token of an element given its index *with respect to
		used elements* in the array.

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	ax - index
	bx:di - fptr to callback routine to further qualify elements
		 (bx = 0 for none)
		 (vfptr if goede XIP'ed)
	cx, dx - data for callback

RETURN:
	carry - set if token found
	    ax - token
	else:
	    ax - CA_NULL_ELEMENT

DESTROYED:
	none

	Callback:
	Pass:
		*ds:si - array
		ds:di - array element being enumerated
		cx:dx - data for callback
	Return:
		carry - set if element qualifies
	Destroyed:
		ax, bx, cx, dx, si, di - destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version
	Todd	3/94		XIP'ed

------------------------------------------------------------------------------@

ElementArrayUsedIndexToToken	proc	far	uses bx, cx, dx, di
callback	local	fptr	\
			push	bx, di
callbackData	local	dword	\
			push	cx, dx
	ForceRef callback
	ForceRef callbackData
	.enter
if ERROR_CHECK

FXIP<	tst	bx			; see if no comparison?		>
FXIP<	jz	doEnum							>
FXIP<	push	si							>
FXIP<	mov	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	si							>
doEnum::

endif

EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	mov	bx, cs
	mov	di, offset IndexToTokenCallback
	mov_tr	cx, ax				;used index (counter)
	clr	dx				;token (result)
	call	ChunkArrayEnum
	mov_tr	ax, dx
	jc	found				;branch if found
	mov	ax, CA_NULL_ELEMENT		;ax <- indicate not found
found:

	.leave
	ret

ElementArrayUsedIndexToToken	endp

;---

	; ds:di = element
	; cx = used index'es left to find
	; dx = token (result)

IndexToTokenCallback	proc	far
callback	local	fptr
callbackData	local	dword
	.enter inherit far

	call	CallIndexTokenCallback
	jnc	noMatch
	jcxz	done
	dec	cx
noMatch:
	inc	dx
	clc
done:
	.leave
	ret

IndexToTokenCallback	endp

;---

CallIndexTokenCallback	proc	near
callback	local	fptr
callbackData	local	dword
	.enter inherit far

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	done		;Branch with carry clear if equal
	tst	callback.segment
	stc
	jz	done
	push	cx, dx
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, callback
	movdw	cxdx, callbackData
	call	ProcCallFixedOrMovable
	pop	cx, dx
done:
	.leave
	ret

CallIndexTokenCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ElementArrayTokenToUsedIndex

DESCRIPTION:	Get the index of an element *with respect to used elements*
		given its token in the array.

CALLED BY:	GLOBAL

PASS:
	*ds:si - element array
	ax - token
	bx:di - fptr to callback routine to further qualify elements
		 (bx = 0 for none)
		 (vfptr if goede XIP'ed)
	cx, dx - data for callback

RETURN:
	ax - index

DESTROYED:
	none

	Callback:
	Pass:
		*ds:si - array
		ds:di - array element being enumerated
		cx:dx - data for callback
	Return:
		carry - set if element qualifies
	Destroyed:
		ax, bx, cx, dx, si, di - destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version
	Todd	3/94		XIP'ed

------------------------------------------------------------------------------@

ElementArrayTokenToUsedIndex	proc	far	uses bx, cx, dx, di
callback	local	fptr	\
			push	bx, di
callbackData	local	dword	\
			push	cx, dx
	ForceRef callback
	ForceRef callbackData
	.enter

if ERROR_CHECK

FXIP<	tst	bx			; see if no comparison?		>
FXIP<	jz	doEnum							>
FXIP<	push	si							>
FXIP<	mov	si, di							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	si							>
doEnum::

endif

EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	NULL_ELEMENT_PASSED_TO_CHUNK_ARRAY_ROUTINE		>

	mov	bx, cs
	mov	di, offset TokenToIndexCallback
	mov_tr	cx, ax				;token (counter)
	clr	dx				;used index (result)
	jcxz	10$
	call	ChunkArrayEnum
10$:
	mov_tr	ax, dx

	.leave
	ret

ElementArrayTokenToUsedIndex	endp

;---

	; ds:di = element
	; cx = tokens left to count
	; dx = used index (result)

TokenToIndexCallback	proc	far
callback	local	fptr
callbackData	local	dword
	.enter inherit far

	call	CallIndexTokenCallback
	jnc	noMatch
	inc	dx
noMatch:
	clc
	loop	done
	stc
done:
	.leave
	ret

TokenToIndexCallback	endp

ChunkArray ends
