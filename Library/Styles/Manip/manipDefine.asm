COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipDefine.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetDefineStyle

	$Id: manipDefine.asm,v 1.1 97/04/07 11:15:34 newdeal Exp $

------------------------------------------------------------------------------@

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetDefineStyle

DESCRIPTION:	Define a new style

CALLED BY:	GLOBAL

PASS:
	*ds:si - styled object (this object will receive a
		 MSG_META_STYLED_OBJECT_APPLY_STYLE message)
	ss:bp - StyleSheetParams
	ss:cx - SSCDefineStyleParams
	ax:di - callback routine for setting custom stuff
		(must be vfptr for XIP'ed geodes)
	Callback:
	Pass:
		cx:di - UI to update
		ds:si - style structure
		ds:dx - base style structure (dx = 0 if none)
	Return:
		none
	Destroyed:
		ax, bx, cx, dx, si, di, bp, ds, es
	
RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@

NameOrElement	union
SBCS <NOE_name	char NAME_ARRAY_MAX_NAME_LENGTH+2 dup (?) ;even-sized null>
DBCS <NOE_name	wchar NAME_ARRAY_MAX_NAME_LENGTH+1 dup (?)		>
    NOE_element	byte STYLE_SHEET_MAX_ELEMENT_SIZE dup (?)
NameOrElement	end

StyleSheetDefineStyle	proc	far
STYLE_LOCALS
newStyle	local	word
buffer		local	NameOrElement

	; if no style array was passed then bail out

	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jnz	1$
	ret
1$:

	.enter

	mov	newStyle, CA_NULL_ELEMENT

	call	IgnoreUndoAndFlush

	call	EnterStyleSheet

	; don't define if indeterminate

	mov	cx, attrTotal
	push	es
	segmov	es, ss
	mov	di, saved_cxdx.high		;es:di = attr tokens
	add	di, offset SSCDSP_attrTokens
	mov	ax, CA_NULL_ELEMENT
	repne scasw
	pop	es
	LONG je	skipDefine

	; calculate the size

	push	bp
	mov	di, saved_cxdx.high
	movdw	bxsi, ss:[di].SSCDSP_textObject
	mov	dx, ss
	lea	bp, buffer			;dx:bp = buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;cx = size (not counting null)
	pop	bp
	tst	cx
	LONG jz	skipDefine
	;
	;	Clear out the text field now that we have the name
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_EVERYTHING
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, dx, bp

	call	Load_dssi_styleArray
	segmov	es, ss
	lea	di, buffer			;es:di = name
	clr	dx				;no data (we'll add it later)
	clr	bx				;no flags
	call	NameArrayAdd			;ax = token
	call	DerefStyleLocals
	jc	nameAdded
	mov	ax, offset NameAlreadyExistsString
	call	DisplayError
	jmp	skipDefine			;if already present then abort
nameAdded:
	call	StyleSheetIncNotifyCounter	;mark styles changed

	; set the attributes

	push	ax, si, bp
	mov	di, saved_cxdx.high
	movdw	bxsi, ss:[di].SSCDSP_attrList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax = attrs
	mov_tr	cx, ax
	pop	ax, si, bp

	push	cx
	mov	newStyle, ax
	call	ChunkArrayElementToPtr		;ds:di = array
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	pop	ds:[di].SEH_flags
	clr	ax
	clrdw	ds:[di].SEH_privateData, ax
	mov	bx, saved_cxdx.high
	mov	ax, ss:[bx].SSCDSP_baseStyle
	mov	ds:[di].SEH_baseStyle, ax

			CheckHack <(size SEH_reserved) eq 6>
	mov	ax, {word} ss:[bx].SSCDSP_reserved
	mov	{word} ds:[di].SEH_reserved, ax
	mov	ax, {word} ss:[bx].SSCDSP_reserved+2
	mov	{word} ds:[di].SEH_reserved+2, ax
	mov	ax, {word} ss:[bx].SSCDSP_reserved+4
	mov	{word} ds:[di].SEH_reserved+4, ax

	; loop through the attributes, making a new element for each attribute
	; structure that points at our new style

attrLoop:

	; lock appropriate attribute array

	mov	si, saved_cxdx.high
	lea	si, ss:[si].SSCDSP_attrTokens
	add	si, attrCounter2
	mov	ax, ss:[si]
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = attr token

	; get the element

	mov	cx, ss
	lea	dx, buffer
	call	ChunkArrayGetElement		;ax = size
	mov	bx, newStyle
	mov	({StyleSheetElementHeader} buffer).SSEH_style, bx
	clr	bx
	call	ElementArrayAddElement		;ax = new element
	call	DerefStyleLocals
	push	ax
	call	Load_dssi_styleArray
	mov	ax, newStyle
	call	ChunkArrayElementToPtr		;ds:di = style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	add	di, attrCounter2
	pop	ds:[di].SEH_attrTokens

	; unlock attribute array

	call	UnlockLoopAttrArray
	jnz	attrLoop

	; set the custom stuff

	call	Load_dssi_styleArray
	mov	ax, newStyle
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	push	di
	mov	ax, ds:[di].SEH_baseStyle
	call	ElementToPtrCheckNull
	mov	dx, di
	pop	si

	; ds:si = style, ds:dx = base style

	; set stuff from extra UI by calling callback

	mov	bx, saved_ax
	mov	ax, saved_esdi.low		;bxax = callback
	tst	bx
	jz	noCallback
	push	bp
	mov	di, saved_cxdx.high
	movdw	cxdi, ss:[di].SSCDSP_extraUI
	call	ProcCallFixedOrMovable
	pop	bp
noCallback:

skipDefine:
	call	LeaveStyleSheet

	cmp	newStyle, CA_NULL_ELEMENT
	jz	99$

	push	ax, cx, dx, bx, bp
	mov	bx, cx
	mov	cx, newStyle
	sub	sp, size SSCApplyDeleteStyleParams
	mov	bp, sp
	mov	ax, ss:[bx].SSCDSP_defineStyledClasss.segment
	mov	ss:[bp].SSCADSP_deleteStyledClass.segment, ax
	mov	ax, ss:[bx].SSCDSP_defineStyledClasss.offset
	mov	ss:[bp].SSCADSP_deleteStyledClass.offset, ax
	clr	ss:[bp].SSCADSP_flags
	mov	ss:[bp].SSCADSP_token, cx
	mov	ax, MSG_META_STYLED_OBJECT_APPLY_STYLE
	call	ObjCallInstanceNoLock
	add	sp, size SSCApplyDeleteStyleParams
	pop	ax, cx, dx, bx, bp

99$:

	call	AcceptUndo

	.leave
	ret

StyleSheetDefineStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetRedefineStyle

DESCRIPTION:	Redefine a style

CALLED BY:	GLOBAL

PASS:
	ss:bp - StyleSheetParams
	ss:cx - SSCDefineStyleParams
	ax:di - callback routine for setting custom stuff
		(must be vfptr for XIP'ed geodes)

	Callback:
	Pass:
		cx:di - UI to update
		ds:si - style structure
		ds:dx - base style structure (dx = 0 if none)
	Return:
		none
	Destroyed:
		ax, bx, cx, dx, si, di, bp, ds, es
	
RETURN:
	ax - non-zero if recalculation needed

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetRedefineStyle	proc	far
STYLE_MANIP_LOCALS
	.enter

	call	IgnoreUndoAndFlush

	ENTER_FULL_EC

	call	EnterStyleSheet

	clr	recalcFlag
	mov	substituteFlag, 1

	mov	di, saved_cxdx.high	;ss:di = SSCDefineStyleParams
	mov	ax, ss:[di].SSCDSP_baseStyle
	cmp	ax, CA_NULL_ELEMENT
	jz	done

	mov	styleToChange, ax

	; copy the tokens to change (changeAttrs)

copyLoop:
	mov	bx, attrCounter2		;get the element for this
	mov	di, saved_cxdx.high		;ss:di = SSCDefineStyleParams
	mov	ax, ss:[di][bx].SSCDSP_attrTokens ;attr array
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = attr token

	; if this attribute is not based on the style that we are redefining
	; then use the attribute that this style is based on (this is important
	; for character only text styles)

	mov	cx, styleToChange
	cmp	cx, ds:[di].SSEH_style
	jz	gotElementToUseForThisAttrArray

	mov_tr	ax, cx
	call	Load_dssi_styleArray
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	ax, ds:[di].SEH_attrTokens[bx]

gotElementToUseForThisAttrArray:
	push	bp
	add	bp, bx
	mov	changeAttrs, ax			;actually index via add above
	pop	bp
	call	UnlockLoopAttrArray
	jnz	copyLoop

	; add a reference to each of the change attrs

	mov	dx, 1
	call	ModifyChangeAttrRef

	; change the style

	call	ChangeStyle

	mov	dx, -1
	call	ModifyChangeAttrRef

done:
	call	LeaveStyleSheet

	mov	ax, recalcFlag

	LEAVE_FULL_EC

	call	AcceptUndo

	.leave
	ret

StyleSheetRedefineStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ModifyChangeAttrRef

DESCRIPTION:	Change the reference count for changeAttrs

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables
	dx - positive to increment ref count, negative to decrement it

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/21/92		Initial version

------------------------------------------------------------------------------@
ModifyChangeAttrRef	proc	near
STYLE_MANIP_LOCALS
	.enter inherit far

attrLoop:
	mov	ax, CA_NULL_ELEMENT
	call	LockLoopAttrArray		;ds:si = attr array
						;ds:di = element, cx = size
						;ax = attr token

	lea	di, changeAttrs
	add	di, attrCounter2
	mov	ax, ss:[di]
	tst	dx
	js	10$
	call	ElementArrayAddReference
	jmp	20$
10$:
	clr	bx
	call	ElementArrayRemoveReference
20$:

	call	UnlockLoopAttrArray
	jnz	attrLoop

	.leave
	ret

ModifyChangeAttrRef	endp

ManipCode	ends
