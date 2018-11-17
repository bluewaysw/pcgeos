COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipDelete.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetGetStyle

	$Id: manipDelete.asm,v 1.1 97/04/07 11:15:33 newdeal Exp $

------------------------------------------------------------------------------@

STYLE_DELETE_LOCALS	equ	<\
STYLE_MANIP_LOCALS\
.warn -unref_local\
baseStyle	local	word\
.warn @unref_local\
>

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDeleteStyle

DESCRIPTION:	Apply a style

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
	cx - used index
	dx - non-zero to revert to base style
	
RETURN:
	ax - non-zero if recalculation is necessary

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

    recalcFlag = FALSE
    newStyle = styleToChange->baseStyle
    foreach (attrArray in style) {
	changeElement = styleToChange.elements[attrArray]
	newElement = newStyle.elements[attrArray]
	foreach (attrElement in attrArray) {
	    if (attrElement.style == styleToChange) {
		/*
		 * We've found an element referring to the style to delete
		 */
		attrElement.style = newStyle
		if (revertToBase) {
		    recalcFlag = TRUE
		    mergeCallback[attr](attrElement, changeElement, newElement)
		}
		newElement = ElementArrayElementChanged(attrElement)
		if (newElement != attrElement) {
		    substCallback(attrElement, newElement)
		}
	    }
	}
    }
    ElementArrayDelete(styleToChange)
    return(recalcFlag)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetDeleteStyle	proc	far
STYLE_DELETE_LOCALS

	; if no style array was passed then bail out

	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:

	.enter

	call	IgnoreUndoAndFlush

	ENTER_FULL_EC

	call	EnterStyleSheet
	call	StyleSheetIncNotifyCounter	;mark styles changed

	clr	recalcFlag
	mov	substituteFlag, 1

	; get the token to delete (convert from used index)

	mov	ax, saved_cxdx.high	;ax = used index to delete
	call	Load_dssi_styleArray
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = style to delete
	mov	styleToChange, ax
	cmp	ax, CA_NULL_ELEMENT
	LONG je	nothingToDelete

	; get the attribute tokens for the base style

	call	ChunkArrayElementToPtr		;ds:di = style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
;EC <	test	ds:[di].SEH_flags, mask SEF_PROTECTED			>
;EC <	ERROR_NZ STYLE_SHEET_ATTEMPT_TO_DELETE_PROTECTED_STYLE		>
;could happen if click on Delete quickly - brianc 9/23/94
	test	ds:[di].SEH_flags, mask SEF_PROTECTED
	LONG jnz	nothingToDelete
	mov	ax, ds:[di].SEH_baseStyle
	mov	baseStyle, ax
	call	ElementToPtrCheckNull

	clr	bx
copyLoop:
	mov	ax, CA_NULL_ELEMENT
	tst	di
	jz	10$
	mov	ax, ds:[di][bx].SEH_attrTokens	;ax = newElement
10$:
	push	bp
	add	bp, bx
	mov	changeAttrs, ax		;actually index via add above
	pop	bp
	add	bx, 2
	cmp	bx, MAX_STYLE_SHEET_ATTRS * (size word)
	jnz	copyLoop

	; change the style

	tst	saved_cxdx.low		;test revert flag
	jz	noRevert
	call	ChangeStyle
noRevert:

	; change any styles based on this style to be based on this style's
	; base

	call	Load_dssi_styleArray
	mov	bx, cs
	mov	di, offset DeleteStyleCallback
	call	ChunkArrayEnum

	; loop through the attribute structures to change any elements
	; based on this style to be based on this style's base style
	; and remove a reference from all elements pointed to by this style

attrLoop2:
	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = change element

	tst	saved_cxdx.low		;test revert flag
	jz	noDecRef
	lea	di, changeAttrs
	add	di, attrCounter2
	mov	ax, ss:[di]			;ax = old attribute token

	clr	bx
	call	ElementArrayRemoveReference
noDecRef:

	mov	bx, cs
	mov	di, offset DeleteElementCallback
	call	ChunkArrayEnum

	call	UnlockLoopAttrArray
	jnz	attrLoop2

	; delete the style

	call	Load_dssi_styleArray
	mov	ax, styleToChange
	call	ElementArrayDelete
nothingToDelete:
	call	LeaveStyleSheet

	mov	ax, recalcFlag

	LEAVE_FULL_EC

	call	AcceptUndo

	.leave
	ret

StyleSheetDeleteStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteStyleCallback

DESCRIPTION:	Callback to handle an element in a style array when a style
		is being deleted

CALLED BY:	StyleSheetDeleteStyle (via ChunkArrayEnum)

PASS:
	*ds:si - array
	ds:di - style
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
DeleteStyleCallback	proc	far
STYLE_DELETE_LOCALS
	.enter inherit far

	; skip free elements

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	done

	; is this style derived from the style that we are deleting ?

	mov	ax, styleToChange
	cmp	ax, ds:[di].SEH_baseStyle
	jnz	done

	; it is -- change the style

	mov	ax, baseStyle
	mov	ds:[di].SEH_baseStyle, ax

done:
	clc

	.leave
	ret

DeleteStyleCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteElementCallback

DESCRIPTION:	Callback to handle an element in an attribute array
		during delete

CALLED BY:	StyleSheetDeleteStyle (via ChunkArrayEnum)

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

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/92		Initial version

------------------------------------------------------------------------------@
DeleteElementCallback	proc	far
STYLE_DELETE_LOCALS
	.enter inherit far

	; skip free elements

	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	done

	; is this element derived from the element that we are deleting ?

	mov	ax, styleToChange
	cmp	ax, ds:[di].SSEH_style
	jnz	done

	; it is -- change the style

	mov	ax, baseStyle
	mov	ds:[di].SSEH_style, ax
	;
	; Don't forget to mark the block dirty, otherwise we can't
	; revert when discard changes is selected.
	;
	call	ObjMarkDirty

	; see if this element should be folded in

	call	ChunkArrayPtrToElement		;ax = element
	mov	cx, ax				;cx = old token
	clr	bx				;no callback
	call	ElementArrayElementChanged	;ax = new token
	cmp	ax, cx
	jz	done

	; element went away

	mov_tr	dx, ax				;dx = new token
	clr	di				;don't update reference counts
	call	SubstituteToken

done:
	clc

	.leave
	ret

DeleteElementCallback	endp

ManipCode	ends
