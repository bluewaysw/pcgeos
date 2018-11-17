COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipChange.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetGetStyle

	$Id: manipChange.asm,v 1.1 97/04/07 11:15:26 newdeal Exp $

------------------------------------------------------------------------------@

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeStyle

DESCRIPTION:	Change a style from one set of attributes to another.  This
		routine can be called recusrively.

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	styleToChange - style to change
	changeAttrs - attribute tokens to change to

	changeAttrs have already been modified.

	*WARNING*
	This routine does not change the referreence counts either for the
	new elements or for the old elements.  The caller must do this.

RETURN:
	changeAttrs - old attribute tokens for style

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
ChangeStyle	proc	near
STYLE_MANIP_LOCALS
	.enter inherit far

	mov	ax, styleToChange
	call	Load_dssi_styleArray
	call	ObjMarkDirty
	call	ChunkArrayElementToPtr		;ds:di = style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	movdw	dxax, ds:[di].SEH_privateData
	movdw	privateData, dxax

	; loop through the attributes

attrLoop:
	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = change element

	lea	di, changeAttrs
	add	di, attrCounter2
	mov	ax, ss:[di]			;ax = new element
	mov	newElement, ax

	push	ax
	call	Load_dssi_styleArray
	mov	ax, styleToChange
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	add	di, attrCounter2
	pop	ax
	xchg	ax, ds:[di].SEH_attrTokens	;ax = oldElement, store new
	mov	oldElement, ax

	lea	di, changeAttrs
	add	di, attrCounter2
	mov	ss:[di], ax			;save old element

	cmp	ax, newElement
	jz	skipCallback

	; go through the elements and change those based on this style

	call	Load_dssi_attrArray
	mov	bx, cs
	mov	di, offset ChangeElementCallback
	call	ChunkArrayEnum

	mov	cx, oldElement
	mov	dx, newElement
	cmp	dx, CA_NULL_ELEMENT
	jz	skipCallback
	mov	di, 1				;update reference counts
	call	SubstituteToken

skipCallback:

	; unlock attribute array

	call	UnlockLoopAttrArray
	jnz	attrLoop

	; enumerate all styles to find any that are based on this style

	call	Load_dssi_styleArray
	mov	bx, cs
	mov	di, offset ChangeStyleCallback
	call	ChunkArrayEnum

	.leave
	ret

ChangeStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeStyleCallback

DESCRIPTION:	Callback to handle an element in a style array

CALLED BY:	StyleSheetDeleteStyle (via ChunkArrayEnum)

PASS:
	*ds:si - array
	ds:di - element
	ss:bp - inherited variables

RETURN:
	carry clear (continue enumeration)

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/92		Initial version

------------------------------------------------------------------------------@
ChangeStyleCallback	proc	far
STYLE_MANIP_LOCALS
	.enter inherit far

CSC_PUSH_SIZE	=	(size styleToChange) + (size changeAttrs) + \
			(size privateData)

	; skip free elements

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	LONG jz	done

	; is this style derived from the style that we are deleting ?

	mov	ax, styleToChange
	cmp	ax, ds:[di].SEH_baseStyle
	LONG jnz done

	; push stuff we want to preserve

	lea	bx, privateData
	mov	cx, CSC_PUSH_SIZE / 2
pushLoop:
	push	ss:[bx]
	add	bx, 2
	loop	pushLoop

	; this style is based on the style being changed -- do our stuff

	movdw	privateData, ds:[di].SEH_privateData, ax
	call	ChunkArrayPtrToElement		;ax = old
	mov	enumElement, ax

	; calculate new element values

	; changeAttrs - old value for old base token (OLD)
	; enumElement - target
	; styleToChange - new

attrLoop:
	mov	ax, enumElement
	call	Load_dssi_styleArray
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = target

	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = target element

	; we must make a copy of the element that we're about to change

	mov	ax, cx				;ax = size
	push	cx
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			;bx = handle, ax = segment
	pop	cx

	push	cx, si
	mov	si, di				;ds:si = source
	mov	es, ax
	clr	di				;es:di = dest
	rep movsb
	pop	cx, si
	mov	es:SSEH_style, CA_NULL_ELEMENT	;to differentiate it
	mov_tr	ax, cx				; ax = size
	mov	cx, es
	clr	dx				;cx:dx = element to add
	clr	bx				;no callback
	call	ElementArrayAddElement		;ax = new element
	call	DerefStyleLocals

	push	ax
	call	Load_dssi_styleArray
	mov	ax, enumElement
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	add	di, attrCounter2
	pop	ax
	xchg	ax, ds:[di].SEH_attrTokens	;ax = target token
	mov	bx, ax

	lea	di, changeAttrs
	add	di, attrCounter2
	xchg	ax, ss:[di]
	push	ax				;push OLD

	call	Load_dssi_styleArray
	mov	ax, styleToChange
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	add	di, attrCounter2
	mov	cx, ds:[di].SEH_attrTokens	;cx = NEW

	pop	ax				;ax = OLD

	call	MergeToken

	call	UnlockLoopAttrArray
	LONG jnz attrLoop

	; change the sucker

	mov	ax, enumElement
	mov	styleToChange, ax

	call	ChangeStyle

	; pop stuff that we pushed earlier

	lea	di, privateData + CSC_PUSH_SIZE - 2
	mov	cx, CSC_PUSH_SIZE / 2
popLoop:
	pop	ss:[di]
	sub	di, 2
	loop	popLoop

done:
	clc

	.leave
	ret

ChangeStyleCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeElementCallback

DESCRIPTION:	Callback to handle an element in an attribute array

CALLED BY:	ChangeStyle (via ChunkArrayEnum)

PASS:
	*ds:si - array
	ds:di - element
	ss:bp - inherited variables

RETURN:
	carry clear (continue enumeration)

DESTROYED:
	ax, bx, cx, dx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		attrElement.style = newStyle
		if (revertToBase) {
		    recalcFlag = TRUE
		    mergeCallback[attr](attrElement, oldElement, newElement)
		}
		newElement = ElementArrayElementChanged(attrElement)
		if (newElement != attrElement) {
		    substCallback(attrElement, newElement)
		}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/92		Initial version

------------------------------------------------------------------------------@
ChangeElementCallback	proc	far
STYLE_MANIP_LOCALS
	.enter inherit far

	; skip free elements

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	done

	call	ChunkArrayPtrToElement
	mov	enumElement, ax

	; don't change newElement (its already changed)

	cmp	ax, oldElement
	jz	done
	cmp	ax, newElement
	jz	done

	; is this element derived from the element that we are deleting ?

	mov	ax, styleToChange
	cmp	ax, ds:[di].SSEH_style
	jnz	done

	cmp	newElement, CA_NULL_ELEMENT
	jz	noRevert

	mov	ax, oldElement			;OLD
	mov	bx, enumElement			;TARGET
	mov	cx, newElement			;NEW
	call	MergeToken
noRevert:

	; see if this element should be folded in

	mov	ax, enumElement			;ax = old token
	mov	cx, ax				;cx = old token
	clr	bx				;no callback
	call	ElementArrayElementChanged	;ax = new token
	cmp	ax, cx
	jz	noFold

	; element went away

	mov_tr	dx, ax				;dx = new token
	clr	di				;don't update reference counts
	call	SubstituteToken
noFold:

done:
	clc
	.leave
	ret

ChangeElementCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MergeToken

DESCRIPTION:	Merge token changes

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	ax - OLD token (old base element)
	bx - TARGET token
	cx - NEW token (new base element)

RETURN:
	*ds:si - attribute array

DESTROYED:
	dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Before call		After call
	-----------		----------

	OLD <- TARGET		NEW <- TARGET

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
MergeToken	proc	near	uses ax, bx, cx, es
STYLE_MANIP_LOCALS
	.enter inherit far

	call	Load_dssi_attrArray

	; if OLD = NEW then there is not a whole lot to do...

	cmp	ax, cx
	LONG jz	done

	mov	recalcFlag, 1

	; we're reverting this to the base, we must calculate
	;	element = newElement + (element - oldElement)

	; allocate a buffer for the result

	sub	sp, STYLE_SHEET_MAX_ELEMENT_SIZE
EC <	call	ECCheckStack						>
	segmov	es, ss
	mov	dx, sp				;es:dx = result

	push	bx				;save TARGET element #
	push	si				;save TARGET chunk handle

	push	cx				;   save NEW
	call	ElementToPtrCheckNull		;ds:di = old element
	pop	cx				;   recover NEW
	push	di				;  save OLD pointer

	mov_tr	ax, bx
	push	cx				;   save NEW
	call	ChunkArrayElementToPtr		;ds:di = target element
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	pop	ax				;   recover NEW
	push	di				;   save TARGET ptr
	push	cx				;    save TARGET size

	; deref new element and copy it to result buffer (unless it does
	; not exist in which case we can just change the base style)

	call	ElementToPtrCheckNull		;ds:di = new element, cx = size
	LONG jnc newDoesNotExist

	mov	si, di				;ds:si = source
	mov	di, dx				;es:di = dest
	rep movsb

	mov	di, dx				;es:di = result
	pop	dx				;dx = TARGET suze

	pop	si				;ds:si = TARGET ptr
	pop	cx				;ds:cx = OLD ptr

	; copy style field from target to result

	mov	ax, ds:[si].SSEH_style
	mov	es:[di].SSEH_style, ax

	; ds:si = target, es:di = result element, ds:cx = new element
	; dx = element size

EC <	cmp	ds:[si].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
EC <	xchg	bx, cx							>
EC <	cmp	ds:[bx].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
EC <	xchg	bx, cx							>
EC <	cmp	es:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>

	push	dx, di, bp, ds
	mov	bx, ss:[bp]			;ss:bx = StyleSheetParams
	add	bx, attrCounter4	;ss:bx = routine
	mov	ax, ss:[bx].SSP_mergeCallbacks[0].offset
	mov	bx, ss:[bx].SSP_mergeCallbacks[0].segment
	lea	bp, privateData
	call	ProcCallFixedOrMovable
	mov	cx, dx				;cx = size returned
	pop	dx, di, bp, ds

	pop	si				;*ds:si = array
	pop	ax				;ax = target element

	; if the element size changed then resize the element

	cmp	cx, dx
	jz	afterResize
	call	ChunkArrayElementResize
	call	DerefStyleLocals
afterResize:

	; copy the data back into the element (except reference count)

	push	si

	push	di
	call	ElementToPtrCheckNull		;ds:di = element (dest)
						;cx = size
	segxchg	ds, es				;es:di = dest
	pop	si				;ds:si = source
	add	si, size RefElementHeader
	add	di, size RefElementHeader
	sub	cx, size RefElementHeader
	rep movsb

	segmov	ds, es
	pop	si
	jmp	common

newDoesNotExist:
	pop	si				;ds:si = target
	pop	cx				;ds:cx = old
;;;	mov	ds:[si].SSEH_style, CA_NULL_ELEMENT
	pop	si				;*ds:si = array
	pop	ax				;ax = target element

common:

	add	sp, STYLE_SHEET_MAX_ELEMENT_SIZE
done:
	.leave
	ret

MergeToken	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstituteToken

DESCRIPTION:	Substitute one token with another in the host's objects
		by using the substitution callback

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	cx - old token
	dx - new token
	di - non-zero to update reference counts

RETURN:
	*ds:si - attribute array

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
SubstituteToken	proc	near
STYLE_MANIP_LOCALS
	.enter inherit far

	tst	substituteFlag
	jz	done

	; use callback to substitute

	mov	si, saved_si
	mov	bx, saved_ds_handle
	call	MemDerefDS
	mov	bx, ss:[bp]			;ss:bx = StyleSheetParams
	add	bx, attrCounter4	;ss:bx = routine
	mov	ax, ss:[bx].SSP_substitutionCallbacks[0].offset
	mov	bx, ss:[bx].SSP_substitutionCallbacks[0].segment
	push	bp
	call	ProcCallFixedOrMovable
	pop	bp
	or	recalcFlag, ax
	call	DerefStyleLocals
	call	Load_dssi_attrArray
done:
	.leave
	ret

SubstituteToken	endp

if FULL_EXECUTE_IN_PLACE

ManipCode	ends
StylesXIPCode	segment resource

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetCallMergeRoutines

DESCRIPTION:	Given a table of SSDDiffEntry structures, call the routines

CALLED BY:	INTERNAL

PASS:
	ss:bp - diff structure
	ds:si - "target" attribute structure
	es:di - "result" attribute structure
	ds:bx - "old" sttribute structure
	cx - number of entries in table
	dx - word to pass to callbacks
	on stack:
		dword - fptr to table of SSDDiffEntry structures 
			(routines must be in the same segment)

RETURN:
	none

DESTROYED:
	ax, cx, dx

	Merge routines:
	Pass:
		ds:si - "target" attribute structure
		es:di - "result" attribute structure
		ds:bx - "old" sttribute structure
		ss:ax - diff structure passed
		cx - word value from table
		dx - word value passed to StyleSheetCallMergeRoutines in dx
	Return:
		none
	Destroy:
		ax, bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/91	Initial version

------------------------------------------------------------------------------@
StyleSheetCallMergeRoutines	proc	far	table:fptr
				uses ax
routine	local	fptr
	.enter

EC <	call	ECLMemValidateHeap					>

mergeLoop:
	push	bx, cx, dx, si, di, bp, ds, es

	; test the field

	push	di, bp, es
	movdw	esdi, table
	mov	ax, es:[di].SSME_routine
	mov	routine.offset, ax
	mov	routine.segment, es
	clr	ax
	mov	al, es:[di].SSME_offset
	mov	bp, ss:[bp]
	add	bp, ax
	mov	ax, es:[di].SSME_mask
	test	ax, ss:[bp]
	mov	cx, es:[di].SSME_data
	pop	di, bp, es
	jz	next				;branch with carry clear

	; diff bit set -- call the routine

	mov	ax, ss:[bp]
	call	routine

EC <	call	ECLMemValidateHeap					>

next:
	pop	bx, cx, dx, si, di, bp, ds, es

	add	table.offset, size SSMergeEntry
	loop	mergeLoop

EC <	call	ECLMemValidateHeap					>

	.leave
	ret	@ArgSize

StyleSheetCallMergeRoutines	endp

if FULL_EXECUTE_IN_PLACE

StylesXIPCode	ends
ManipCode	segment resource

endif

;==============================================

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckStyleArray

DESCRIPTION:	...

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables

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
	Tony	1/21/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckStyleArray	proc	near	uses ax, bx, cx, dx, si, di, ds, es
STYLE_LOCALS
	.enter inherit far

	pushf

	; enumerate all styles to find any that are based on this style

	call	Load_dssi_styleArray
	mov	bx, cs
	mov	di, offset ECCheckStyleCallback
	call	ChunkArrayEnum

	popf

	.leave
	ret

ECCheckStyleArray	endp

;---

ECCheckStyleCallback	proc	far
STYLE_LOCALS
	.enter inherit far

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	done

	call	ChunkArrayPtrToElement
	mov_tr	dx, ax				;dx holds style #

	; ensire that the reserved space is 0

			CheckHack <(size SEH_reserved) eq 6>
	tst	<{word} ds:[di].SEH_reserved>
	ERROR_NZ STYLE_RESERVED_SPACE_MUST_BE_0
	tst	<{word} ds:[di].SEH_reserved+2>
	ERROR_NZ STYLE_RESERVED_SPACE_MUST_BE_0
	tst	<{word} ds:[di].SEH_reserved+4>
	ERROR_NZ STYLE_RESERVED_SPACE_MUST_BE_0

	; ensure that base style is not free

	push	di
	mov	ax, ds:[di].SEH_baseStyle
	call	ElementToPtrCheckNull
	pop	di

	push	ds
attrLoop:
	call	Load_dssi_styleArray
	mov	ax, dx
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	bx, attrCounter2
	mov	ax, ds:[di][bx].SEH_attrTokens
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = attr token

	cmp	ds:[di].SSEH_style, dx
	ERROR_NZ STYLE_SHEET_ELEMENT_HAS_WRONG_STYLE_TOKEN

	call	UnlockLoopAttrArray
	jnz	attrLoop
	pop	ds
done:
	clc
	.leave
	ret

ECCheckStyleCallback	endp

endif

ManipCode	ends
