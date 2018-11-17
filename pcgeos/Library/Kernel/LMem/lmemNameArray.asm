COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/LMem
FILE:		lmemElementArray.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	NameArrayAdd		Add a name
   GLB	NameArrayFind		Find a name

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

DESCRIPTION:
	This file contains name array routines

	$Id: lmemNameArray.asm,v 1.1 97/04/05 01:14:09 newdeal Exp $

------------------------------------------------------------------------------@

ChunkArray segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	NameArrayCreate

DESCRIPTION:	Create a new name array with 0 elements

CALLED BY:	GLOBAL

PASS:
	ds - block for new array
	bx - data size (to store with each name)
	cx - size for ChunkArrayHeader (this allows for reserving extra
	     space)  0 = default
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
	Tony	7/91		Initial version

------------------------------------------------------------------------------@

NameArrayCreate	proc	far	uses cx
	.enter

EC <	call	ECLMemValidateHeapFar					>

	tst	cx
	jnz	notZero
	mov	cx, size NameArrayHeader
notZero:

	push	bx			;save data size
	clr	bx			;element size variable
	call	ElementArrayCreate	;marks chunk dirty
	pop	bx
	jc	exit

	push	si
	mov	si, ds:[si]
	mov	ds:[si].NAH_dataSize, bx
	pop	si

EC <	call	ECCheckChunkArray					>
exit:
	.leave
	ret

NameArrayCreate	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NameArrayAdd

DESCRIPTION:	Add a name

CALLED BY:	GLOBAL

PASS:
	*ds:si - name array
	es:di - name to add
	cx - length of name (0 for null terminated)
	bx - flags (NameArrayAddFlags)
	dx:ax - data

RETURN:
	carry - set if name added 
	ax - name token

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
	Tony	10/ 1/91		Initial version

------------------------------------------------------------------------------@
NameArrayAdd	proc	far	uses bx, cx, dx, di, es
flags		local	NameArrayAddFlags	\
			push	bx
datasize	local	word
nameToAdd	local	NameArrayMaxElement
	ForceRef flags
	.enter

	call	StringLengthIfNeeded		;cx = length

	push	si, ds				;save name array
	push	di, es				;save name to add

	; copy the data

	segmov	es, ss
	lea	di, nameToAdd.NAME_data		;es:di = dest

	push	cx
	mov	si, ds:[si]
	mov	cx, ds:[si].NAH_dataSize	;cx = data size
	mov	datasize, cx
	jcxz	noData
	tst	dx
	jz	noData
	movdw	dssi, dxax			;ds:si = source for data
	rep movsb
	jmp	afterData
noData:
	clr	ax				;if no data passed to store 0's
	rep stosb
afterData:
	pop	cx
	mov	ax, cx				;ax = name size
	add	ax, datasize
	add	ax, size NameArrayElement	;ax = size of element to add

	; copy the string

	pop	si, ds				;ds:si = name
	lea	di, nameToAdd.NAME_data		;es:di = dest
	add	di, datasize
	rep movsb

	; Set up VisTextName element entry

	pop	si, ds				;ds:si = name array
	mov	cx, ss
	lea	dx, nameToAdd			; cx:dx - name to add
	mov	bx, SEGMENT_CS
	mov	di, offset AddNameCallback	; use our callback
	call	ElementArrayAddElement		; ax = token
						; marks chunk dirty

	.leave
	ret

NameArrayAdd	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddNameCallback

DESCRIPTION:	Callback routine for VisTextAddName

CALLED BY:	ElementArrayAddElement

PASS:
	es:di - element to add
	ds:si - element from array
	ss:ax - inherited variables
	cx - element size

RETURN:
	carry flag - set if elements equal

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/15/91		Initial version
	Benson	8/91		Bug fixes

------------------------------------------------------------------------------@

AddNameCallback	proc	far	uses si, di
flags		local	NameArrayAddFlags
datasize	local	word
nameToAdd	local	NameArrayMaxElement
       	.enter inherit far

	push	bp
	mov_tr	bp, ax

	mov	dx, flags

	; compare the strings

	push	si, di
	mov	bx, datasize
	add	bx, size NameArrayElement
	add	si, bx
	add	di, bx
	sub	cx, bx
	repe	cmpsb				; compare
	pop	si, di
	clc
	jnz	done				; end if not equal

	; found a match -- set data if flag says so


	test	dx, mask NAAF_SET_DATA_ON_REPLACE
	jz	afterDataCopy

	add	si, offset NAE_data
	add	di, offset NAE_data
	mov	cx, datasize
	push	ds, es
	segxchg	ds, es
	xchg	si, di
	rep movsb
	pop	ds, es

afterDataCopy:
	stc

done:
	pop	bp
	.leave
	ret

AddNameCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NameArrayFind

DESCRIPTION:	Find a name

CALLED BY:	GLOBAL

PASS:
	*ds:si - name array
	es:di - name to find
	cx - length of name (0 for null terminated)
	dx:ax - buffer to return data (dx = 0 to not return data)

RETURN:
	ax - name token (CA_NULL_ELEMENT if not found)
	carry - set if name found

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 1/91		Initial version

------------------------------------------------------------------------------@
NameArrayFind	proc	far	uses bx, cx, dx, si, di, bp, ds, es
	.enter

	mov_tr	bp, ax
	call	StringLengthIfNeeded		;cx = length

	push	dx
	mov	dx, di				;es:dx = name
	mov	bx, cs
	mov	di, offset FindNameCallback	; bx:di - FindNameCallBack
	call	ChunkArrayEnum			; find it
	mov	di, dx				; ds:di = element found
	pop	dx
	mov	ax, CA_NULL_ELEMENT
	jnc	done				; jmp name not found
	;
	; element found -- copy the data (if needed)
	;
	tst	dx				;any passed buffer?
	jz	noCopyData
	push	si, di
	mov	si, ds:[si]
	mov	cx, ds:[si].NAH_dataSize	;cx = # bytes
	lea	si, ds:[di].NAE_data		;ds:si = source
	mov	es, dx
	mov	di, bp				;es:di = dest
	rep movsb
	pop	si, di
noCopyData:

	; get the element number (name token)

	call	ChunkArrayPtrToElement
	stc					; token found
done:
	.leave
	ret

NameArrayFind	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindNameCallback

DESCRIPTION:	Callback routine for NameArrayFind

CALLED BY:	ChunkArrayEnum

PASS:
	*ds:si - array
	ds:di - array element being processed
	ax - size of element
	es:dx - name to search for
	cx - length of name

RETURN:
	carry - set if match found
	dx - offset of element found

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/16/91		Initial version

------------------------------------------------------------------------------@

FindNameCallback	proc	far	uses ax, cx
	.enter

	; Check to see if the length of the strings are the same

	sub	ax, size NameArrayElement ; ax - length of element's name
	mov	si, ds:[si]
	mov	bx, ds:[si].NAH_dataSize
	sub	ax, bx			;ax = name length

	cmp	ax, cx			; length is the same?
	clc
	jnz	done			; jmp to end if not

	; Now compare the strings themselves

	push	di
	lea	si, ds:[di][bx].NAE_data ; ds:si = name
	mov	di, dx			; es:di = name to search for
	repe cmpsb			; cmp strings
	pop	di
	clc				; assume not the same
	jnz	done			; jmp if not equal
	mov	dx, di
	stc
done:
	.leave
	ret

FindNameCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StringLengthIfNeeded

DESCRIPTION:	Get the length of a string if not already given

CALLED BY:	INTERNAL

PASS:
	es:di - string
	cx - length (0 if null terminated)

RETURN:
	cx - size (bytes) (does not count the null terminator)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/91		Initial version

------------------------------------------------------------------------------@
StringLengthIfNeeded	proc	near
SBCS <	uses ax, di							>
	.enter

	tst	cx
	jnz	gotLength
if DBCS_PCGEOS
	call	LocalStringLength		;cx <- length w/o NULL
else
	clr	ax
	mov	cx, 50000
	repne	scasb				;DBCS:
	sub	cx, 50000-1
	neg	cx				;cx = length
endif
gotLength:
DBCS <	shl	cx, 1				;cx <- size		>

	.leave
	ret

StringLengthIfNeeded	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NameArrayChangeName

DESCRIPTION:	Change a name

CALLED BY:	GLOBAL

PASS:
	*ds:si - name array
	ax - name token
	es:di - new name
	cx - length of name (0 for null terminated)

RETURN:
	none

DESTROYED:
	none
	WARNING:  If the new name is longer than the old one, this
		  routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and
		  current register or stored offsets to it.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 1/91		Initial version

------------------------------------------------------------------------------@
NameArrayChangeName	proc	far	uses bx, cx, dx, si, di
	.enter
	
	;
	; Clear the LMF_RETURN_ERRORS flag  since there is no error handling
	; code here.
	;
	push	ds:[LMBH_flags]
	andnf	ds:[LMBH_flags], not (mask LMF_RETURN_ERRORS)   ;clr this flag

	call	ObjMarkDirty

	call	StringLengthIfNeeded		;cx = length

	; figure out new element size and resize the element

	push	cx				;save string size
	mov	bx, di				;es:bx = source
	mov	di, ds:[si]
	mov	dx, ds:[di].NAH_dataSize
	add	dx, size NameArrayElement	;dx = offset to name
	add	cx, dx				;cx = new element size
	call	ChunkArrayElementResize

	; copy in the new name

	call	ChunkArrayElementToPtr		;ds:di = element
	add	di, dx				;ds:di = destination
	segxchg	ds, es				;es:di = dest, ds:bx = source
	mov	si, bx				;ds:si = source
	pop	cx				;cx = size
	rep movsb

	segxchg	ds, es				;restore ds and es

	;
	; Restore the LM flags here
	;
	pop	cx				;cx = original LM flags
	pushf
	andnf	cx, mask LMF_RETURN_ERRORS
	ornf	ds:[LMBH_flags], cx		;restore LM flags
	popf

	.leave
	ret

NameArrayChangeName	endp

ChunkArray ends
