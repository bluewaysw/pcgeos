COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipCopy.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetGetStyle

	$Id: manipCopy.asm,v 1.1 97/04/07 11:15:27 newdeal Exp $

------------------------------------------------------------------------------@

OPTIMIZE_STYLE_COPY	=	TRUE


OPT_STYLE_ARRAY_CHUNK	=	size LMemBlockHeader
OPT_ATTR_ARRAY_CHUNK	=	OPT_STYLE_ARRAY_CHUNK+2

OptEntry	struct
    OE_sourceToken	word
    OE_destToken	word
    OE_sourceRef	word
OptEntry	ends

STYLE_COPY_LOCALS	equ	<\
STYLE_MANIP_LOCALS\
.warn -unref_local\
styleFlags	local	word\
destStyle	local	word\
destCopyFromStyle local	word\
fromTransfer	local	byte\
changeDestStyles local	byte\
optBlock	local	word\
createdNew	local	word\
oldBaseStyle	local	word\
.warn @unref_local\
>


ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyStyle

DESCRIPTION:	Copy a style from one attribute space to another.  This
		routine can be called recusrively.

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	ax - style to move
	fromTransfer - set if copying *from* transfer space
	changeDestStyles - set to force the source's definition of a style
			   to the destination
	optBlock - optimization block

RETURN:
	ax - style token in destination space

DESTROYED:
	bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
CopyStyle	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	push	styleToChange, destStyle, createdNew, oldBaseStyle

	;*** base case: null element is the same everywhere

	cmp	ax, CA_NULL_ELEMENT
	jnz	1$
toDone:
	jmp	done
1$:

	clr	createdNew

	mov	bx, OPT_STYLE_ARRAY_CHUNK
	clr	dx
	call	LookupOpt
	jc	toDone

	;*** try to locate the style in the destination space

	mov	styleToChange, ax
	call	Load_dssi_sourceStyle
	call	ChunkArrayElementToPtr		;ds:di = element, cx = size
	mov	ax, ds:[di].SEH_baseStyle
	mov	oldBaseStyle, ax
	mov	ax, ds:[di].SEH_flags
	mov	styleFlags, ax
	movdw	privateData, ds:[di].SEH_privateData, ax
			CheckHack <(size SEH_reserved) eq 6>
	mov	ax, {word} ds:[di].SEH_reserved
	mov	{word} reserved, ax
	mov	ax, {word} ds:[di].SEH_reserved+2
	mov	{word} reserved+2, ax
	mov	ax, {word} ds:[di].SEH_reserved+4
	mov	{word} reserved+4, ax

	segmov	es, ds
	mov	si, ds:[si]
	mov	bx, ds:[si].NAH_dataSize
	add	bx, NameArrayElement
	add	di, bx				;es:di = name
	sub	cx, bx				;cx = name size
DBCS <	shr	cx, 1				;cx <- name length	>

	call	Load_dssi_destStyle
	clr	dx
	call	NameArrayFind			;ax = token found
	cmp	ax, CA_NULL_ELEMENT
	jz	doesNotExistInDest

	;*** The style exists in the destination space -- if we are not
	;    forcing the source's view of the world then we're done,
	;    otherwise we have to change the destination to our view of the
	;    world
	;    Also, if we are copying to the transfer space then we can assume
	;    that the spaces have the same definition of styles

	tst	fromTransfer
	jz	skipMerge
	tst	changeDestStyles
	jnz	common
skipMerge:
	jmp	addOpt

	;*** The style does not exist in the destination space -- create it

doesNotExistInDest:
	inc	createdNew
	tst	fromTransfer
	jz	afterInc
	call	StyleSheetIncNotifyCounter
afterInc:
	clr	bx
	call	NameArrayAdd			;ax = token
EC <	ERROR_NC STYLE_SHOULD_NOT_HAVE_EXISTED				>
	call	DerefStyleLocals
	call	ChunkArrayElementToPtr
	movdw	ds:[di].SEH_privateData, privateData, cx
			CheckHack <(size SEH_reserved) eq 6>
	mov	cx, {word} reserved
	mov	{word} ds:[di].SEH_reserved, cx
	mov	cx, {word} reserved+2
	mov	{word} ds:[di].SEH_reserved+2, cx
	mov	cx, {word} reserved+4
	mov	{word} ds:[di].SEH_reserved+4, cx
	mov	cx, styleFlags
	mov	ds:[di].SEH_flags, cx

common:
	mov	destStyle, ax

	;*** copy the base style

	mov	ax, oldBaseStyle		;ax = base style
	call	CopyStyle			;ax = base style (in dest)
	mov_tr	bx, ax

	call	Load_dssi_destStyle
	call	ObjMarkDirty
	mov	ax, destStyle
	call	ChunkArrayElementToPtr
	mov	ds:[di].SEH_baseStyle, bx
	mov	destCopyFromStyle, bx

	;*** copy attributes from source to dest

attrLoop:
	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray

	call	Load_dssi_sourceStyle
	mov	ax, styleToChange
	call	ChunkArrayElementToPtr
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = source element

	; pass base style of style being copied as old base style

	push	styleToChange
	mov	dx, oldBaseStyle
	mov	styleToChange, dx
	clr	dx
	call	CopyElement			;ax = element in dest space
	pop	styleToChange

	lea	di, changeAttrs
	add	di, attrCounter2
	mov	ss:[di], ax

	call	UnlockLoopAttrArray
	jnz	attrLoop

	; We have now copied the attribute elements to the destination space.
	; If the destination space and the attribute elements are different
	; then we need to change the style

	call	Load_dssi_destStyle
	mov	ax, destStyle
	call	ChunkArrayElementToPtr		;ds:di = dest style

	mov	cx, attrTotal
	clr	dx				;dx = differ flag
	lea	bx, changeAttrs
copyOrCompareLoop:
	mov	ax, ss:[bx]
	tst	createdNew
	jnz	storeAttr
	tst	fromTransfer
	jnz	compare

	; going to transfer, just copy the tokens

storeAttr:
	mov	ds:[di].SEH_attrTokens, ax
	jmp	common2

	; going to object, store the tokens in changeAttrs

compare:
	cmp	ax, ds:[di].SEH_attrTokens
	jz	common2
	inc	dx
common2:
	add	bx, size word
	add	di, size word
	loop	copyOrCompareLoop

	tst	fromTransfer
	jz	afterChangeStyle
	tst	createdNew
	jnz	afterChangeStyle
	tst	dx
	jz	decRefCountLoop

	; we're copying from the transfer -- set the sucker

	mov	ax, destStyle
	xchg	ax, styleToChange
	push	ax
	call	ChangeStyle
	pop	styleToChange

decRefCountLoop:
	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = change element

	lea	di, changeAttrs
	add	di, attrCounter2
	mov	ax, ss:[di]			;ax = old attribute token
	call	Load_dssi_destAttr
	clr	bx
	call	ElementArrayRemoveReference

	call	UnlockLoopAttrArray
	jnz	decRefCountLoop

afterChangeStyle:
	mov	ax, destStyle

addOpt:
	mov	bx, OPT_STYLE_ARRAY_CHUNK
	mov	cx, styleToChange
	clr	dx
	call	AddOpt

done:
	pop	styleToChange, destStyle, createdNew, oldBaseStyle
	.leave
	ret

CopyStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyElement

DESCRIPTION:	Copy an style from one attribute space to another.  This
		*IS NOT* called recusrively.

		This adds a reference for the element in the destination
		space.

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	ax - element # to copy (source space)
	dx - non-zero if styleToChange actually holds an attribute token
	styleToChange - style element to be based on in source space
	destStyle - style for element to be based on in destination space
	destCopyFromStyle - style to copy elements from in destination space
	attrCounter2 - offset of attribute array to work on

	fromTransfer - set if copying *from* transfer space
	changeDestStyles - set to force the source's definition of a style
			   to the destination
	optBlock - optimization block

RETURN:
	ax - element token in destination space

DESTROYED:
	bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
CopyElement	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	; if we are not forcing the source's views to the destination then
	; we need to merge stuff

	tst	fromTransfer
	jz	noMerge
	tst	changeDestStyles
	jnz	noMerge
	cmp	destCopyFromStyle, CA_NULL_ELEMENT
	jz	noMerge

	; copy the element to transfer

	mov	bx, -2				;fake base style for element
	call	LowLevelCopyElement		;ax = style in dest (TARGET)

	; get the OLD base element and temporarily add it to the destination

	push	ax				;save TARGET
	mov	ax, styleToChange
	tst	dx
	jnz	10$
	call	Load_dssi_sourceStyle
	call	ElementToPtrCheckNull
	jnc	20$
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = old element in source
10$:
	mov	bx, destCopyFromStyle		;base style for element
	call	LowLevelCopyElement		;ax = old element in dest
20$:
	push	ax				;push OLD

	call	Load_dssi_destStyle
	mov	ax, destCopyFromStyle
	call	ChunkArrayElementToPtr
	add	di, attrCounter2
	mov	ax, ds:[di].SEH_attrTokens	;ax = NEW

	mov_tr	cx, ax				;cx = NEW
	pop	ax				;ax = OLD
	pop	bx				;bx = TARGET

	call	MergeToken

	; remove OLD (which we temporarily added)

	push	bx
	call	Load_dssi_destAttr
	clr	bx
	cmp	ax, CA_NULL_ELEMENT
	jz	noRemoveOld
	call	ElementArrayRemoveReference
noRemoveOld:
	pop	ax

	; change target to have the correct base element

	call	ChunkArrayElementToPtr
	mov	bx, destStyle
	mov	ds:[di].SEH_baseStyle, bx
	clr	bx				;no callback
	call	ElementArrayElementChanged	;ax possibly changed

done:
	.leave
	ret

noMerge:
	mov	bx, destStyle
	call	LowLevelCopyElement		;ax = style in dest
	jmp	done

CopyElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LowLevelCopyElement

DESCRIPTION:	Copy an element

		This adds a reference for the element in the destination
		space.

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	ax - element # to copy (source space)
	bx - style for element
	attrCounter2 - offset of attribute array to work on

RETURN:
	ax - element token in destination space

DESTROYED:
	bx, cx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/15/92		Initial version

------------------------------------------------------------------------------@
LowLevelCopyElement	proc	near	uses dx
STYLE_COPY_LOCALS
	.enter inherit far

	; get the source element into a buffer

	call	Load_dssi_destAttr		;dssi = dest
	movdw	cxdx, dssi			;cxdx = dest
	call	Load_dssi_sourceAttr		;dssi = source

	mov	di, STYLE_SHEET_MAX_ELEMENT_SIZE + 200
	call	ThreadBorrowStackSpace
	push	di

	push	bp
	sub	sp, STYLE_SHEET_MAX_ELEMENT_SIZE
	mov	bp, sp

	pushdw	cxdx				;save dest array
EC <	cmp	ax, CA_NULL_ELEMENT					>
EC <	ERROR_Z	STYLE_SHEET_CANNOT_COPY_NULL_ELEMENT			>
	call	ElementToPtrCheckNull		;cx = size
EC <	cmp	cx, STYLE_SHEET_MAX_ELEMENT_SIZE			>
EC <	ERROR_A	STYLE_SHEET_ELEMENT_IS_TOO_LARGE			>
	mov	si, di				;ds:si = source
	segmov	es, ss
	mov	di, bp				;es:di = dest
	push	cx
	rep movsb
	pop	ax				;ax = size

	; add the element in the destination (after setting the style)

	mov	es:[bp].SSEH_style, bx

	popdw	dssi				;dssi = dest array
	movdw	cxdx, ssbp			;cx:dx = element
	clr	bx
	call	ElementArrayAddElement		;ax = token

	add	sp, STYLE_SHEET_MAX_ELEMENT_SIZE
	pop	bp

	pop	di
	call	ThreadReturnStackSpace

	call	DerefStyleLocals

	.leave
	ret

LowLevelCopyElement	endp

;---

Load_dssi_sourceStyle	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	tst	fromTransfer
	jnz	from
	GOTO	Load_dssi_styleArray
from:
	.leave
	FALL_THRU	Load_dssi_xferStyleArray

Load_dssi_sourceStyle	endp

;---

Load_dssi_xferStyleArray	proc	near
STYLE_LOCALS
	.enter inherit far
	movdw	dssi, xferStyleArray
	.leave
	ret
Load_dssi_xferStyleArray	endp

;---

Load_dssi_destStyle	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	tst	fromTransfer
	jnz	from
	GOTO	Load_dssi_xferStyleArray
from:
	.leave
	GOTO	Load_dssi_styleArray

Load_dssi_destStyle	endp

;---

Load_dssi_sourceAttr	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	tst	fromTransfer
	jnz	from
	GOTO	Load_dssi_attrArray
from:
	.leave
	FALL_THRU	Load_dssi_xferAttrArray

Load_dssi_sourceAttr	endp

;---

Load_dssi_xferAttrArray	proc	near
STYLE_LOCALS
	.enter inherit far
	movdw	dssi, xferAttrArray
	.leave
	ret
Load_dssi_xferAttrArray	endp

;---

Load_dssi_destAttr	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

	tst	fromTransfer
	jnz	from
	GOTO	Load_dssi_xferAttrArray
from:
	.leave
	GOTO	Load_dssi_attrArray

Load_dssi_destAttr	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LookupOpt

DESCRIPTION:	Look for a specific entry in the optimization block

CALLED BY:	INTERNAL

PASS:
	ax - source token to look for
	bx - chunk to look in
	dx - source reference
	ss:bp - inherited variables

RETURN:
	carry - set if found
	ax - token in destination space (in found) else unchanged

DESTROYED:
	cx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/14/92		Initial version

------------------------------------------------------------------------------@
LookupOpt	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

if	OPTIMIZE_STYLE_COPY

	mov	di, bx
	mov	bx, optBlock
	tst	bx
	jz	exit
	push	ax
	call	MemLock
	mov	es, ax				;*es:di = chunk
	pop	ax
	mov	di, es:[di]
	cmp	di, -1
	jz	notFound
	ChunkSizePtr	es, di, cx

searchLoop:
	scasw
	jz	maybeFound
next:
	add	di, (size OptEntry) - (size word)
	sub	cx, size OptEntry
	jnz	searchLoop
notFound:
	clc
	jmp	done

maybeFound:
	cmp	dx, es:[di-2].OE_sourceRef
	jnz	next
	mov	ax, es:[di-2].OE_destToken
	stc
done:
	call	MemUnlock
exit:

else
	clc
endif

	.leave
	ret

LookupOpt	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddOpt

DESCRIPTION:	Add a source-dest pair to the optimization block

CALLED BY:	INTERNAL

PASS:
	ax - destination token
	bx - chunk to look in
	cx - source token
	dx - source reference
	ss:bp - inherited variables

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/14/92		Initial version

------------------------------------------------------------------------------@
AddOpt	proc	near
STYLE_COPY_LOCALS
	.enter inherit far

if	OPTIMIZE_STYLE_COPY

	push	ax, cx

	mov	si, bx
	mov	bx, optBlock
	tst	bx
	jnz	haveOptBlock

	; allocate an optimization block

	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	mov	optBlock, bx
	call	MemLock
	mov	ds, ax
	call	LMemAlloc
EC <	cmp	ax, OPT_STYLE_ARRAY_CHUNK				>
EC <	ERROR_NZ STYLE_SHEET_WRONG_CHUNK_ALLOCATED			>
	call	LMemAlloc
EC <	cmp	ax, OPT_ATTR_ARRAY_CHUNK				>
EC <	ERROR_NZ STYLE_SHEET_WRONG_CHUNK_ALLOCATED			>
	call	LMemAlloc
	call	LMemAlloc
	call	LMemAlloc
	jmp	common

haveOptBlock:
	call	MemLock
	mov	ds, ax

common:
	; insert an entry at the front

	mov	ax, si					;ax = chunk
	clr	bx
	mov	cx, size OptEntry
	call	LMemInsertAt

	; fill it in

	mov	si, ds:[si]
	pop	ax, cx
	mov	ds:[si].OE_destToken, ax
	mov	ds:[si].OE_sourceRef, dx
	mov	ds:[si].OE_sourceToken, cx

	mov	bx, optBlock
	call	MemUnlock

endif

	.leave
	ret

AddOpt	endp

ManipCode	ends
