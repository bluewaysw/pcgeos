COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipModify.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetGetStyle

	$Id: manipModify.asm,v 1.1 97/04/07 11:15:30 newdeal Exp $

------------------------------------------------------------------------------@

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetUpdateModifyBox

DESCRIPTION:	Update the modify style dialog box

CALLED BY:	GLOBAL

PASS:
	ss:bp - SSCUpdateModifyParams
	ss:bx - StyleChunkDesc for style array
	ax:di - callback routine for setting custom UI
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
StyleSheetUpdateModifyBox	proc	far	uses si
	.enter

	; if no style array was passed then bail out

	tst	ss:[bx].SCD_chunk
	jz	done

	push	ds:[LMBH_handle]
	call	StyleSheetLockStyleChunk	;*ds:si = style array
	pushf
	pushdw	axdi

	; set the base style

	mov	bx, ds:[si]
	mov	bx, ds:[bx].NAH_dataSize
	add	bx, size NameArrayElement
	push	bx
	mov	ax, ss:[bp].SSCUMP_usedIndex
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = token
	call	ChunkArrayElementToPtr		;ds:di = data, cx = size
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	push	cx				;save name size
	push	di
	clr	cx				;assume no base style
	clr	dx
	mov	bx, ds:[di].SEH_flags
	mov	ax, ds:[di].SEH_baseStyle
	cmp	ax, CA_NULL_ELEMENT
	jz	gotBaseStyle
	call	ChunkArrayElementToPtr		;ds:di = base style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	dx, di
	mov_tr	cx, ax
	inc	cx
gotBaseStyle:
	push	dx
	push	bp
	push	bx				;save flags
	movdw	bxsi, ss:[bp].SSCUMP_baseList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	cx				;cx = flags
	pop	bp
	push	bp
	movdw	bxsi, ss:[bp].SSCUMP_attrList
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	pop	dx

	pop	si
	pop	cx				;cx = element size
	pop	di				;di = offset to name

	; ds:si = style, ds:dx = base style

	; update added ui by calling callback

	popdw	bxax				;bxax = callback
	tst	bx
	jz	noCallback
	push	cx, bp, si, di, ds
	movdw	cxdi, ss:[bp].SSCUMP_extraUI
	call	ProcCallFixedOrMovable
	pop	cx, bp, si, di, ds
noCallback:

	; update name

	sub	cx, di				;cx = name size
DBCS <	shr	cx, 1				;cx = name length	>
	add	di, si				;ds:di = name
	push	bp
	movdw	bxsi, ss:[bp].SSCUMP_textObject
	movdw	dxbp, dsdi
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	popf
	call	StyleSheetUnlockStyleChunk
	pop	bx
	call	MemDerefDS

done:
	.leave
	ret

StyleSheetUpdateModifyBox	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetModifyStyle

DESCRIPTION:	Update the modify style dialog box

CALLED BY:	GLOBAL

PASS:
	ss:bp - SSCUpdateModifyParams
	ss:bx - StyleChunkDesc for style array
	ax:di - callback routine for setting custom UI
		(must be vfptr for XIP`ed geodes)

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
StyleSheetModifyStyle	proc	far	uses si
	.enter

	; if no style array was passed then bail out

	tst	ss:[bx].SCD_chunk
	jz	done

	call	IgnoreUndoAndFlush

	ENTER_FULL_EC

	push	ds:[LMBH_handle]
	call	StyleSheetLockStyleChunk	;*ds:si = style array
	pushf
	pushdw	axdi				;save the callback routine

	; set the base style

	push	si, bp
	movdw	bxsi, ss:[bp].SSCUMP_baseList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax = position
	pop	si, bp
	dec	ax
	jns	10$
	mov	ax, CA_NULL_ELEMENT
	jmp	gotNewBase
10$:
	clr	bx
	call	ElementArrayUsedIndexToToken
gotNewBase:

	push	ax
	mov	ax, ss:[bp].SSCUMP_usedIndex
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = token to change
	pop	dx

	; loop to find if we would be creating a circular reference by
	; changing the base style
	;	ax = style to change
	;	dx = proposed new base style
	;	bp = style being checked

	push	bp
	mov	bp, dx
circCheckLoop:
	cmp	ax, dx
	jz	illegalBaseStyle		;can't be based on self
	cmp	dx, CA_NULL_ELEMENT
	jz	doBaseStyleChange
	xchg	ax, dx
	call	ChunkArrayElementToPtr		;ds:di = data for base style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	ax, ds:[di].SEH_baseStyle
	xchg	ax, dx
	jmp	circCheckLoop

illegalBaseStyle:
	mov	ax, offset IllegalBaseStyleString
	call	DisplayError
	jmp	common

doBaseStyleChange:
	call	ObjMarkDirty			;mark the style array dirty
	call	StyleSheetIncNotifyCounter

	call	ChunkArrayElementToPtr		;ds:di = data, cx = size
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	ds:[di].SEH_baseStyle, bp
common:
	pop	bp

	; set the attributes

	push	si, bp
	movdw	bxsi, ss:[bp].SSCUMP_attrList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax = attrs
	pop	si, bp

	push	ax
	mov	ax, ss:[bp].SSCUMP_usedIndex
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = token to change
	call	ChunkArrayElementToPtr		;ds:di = data, cx = size
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	pop	ds:[di].SEH_flags

	; set the name

	push	bp
	sub	sp, NAME_ARRAY_MAX_NAME_SIZE
	movdw	dxcx, sssp			;dx:cx = buffer
	push	ax, si
	movdw	bxsi, ss:[bp].SSCUMP_textObject
	mov	bp, cx				;dx:bp <- buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;cx = size (not counting null)
	pop	ax, si
	jcxz	skipRename
	segmov	es, ss
	mov	di, sp				;es:di = name
	call	NameArrayChangeName
skipRename:
	add	sp, NAME_ARRAY_MAX_NAME_SIZE
	pop	bp

	; set the custom stuff

	mov	ax, ss:[bp].SSCUMP_usedIndex
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = token
	call	ChunkArrayElementToPtr		;ds:di = data, cx = size
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	push	di
	clr	dx				;assume no base style
	mov	ax, ds:[di].SEH_baseStyle
	cmp	ax, CA_NULL_ELEMENT
	jz	gotBaseStyle
	call	ChunkArrayElementToPtr		;ds:di = base style
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	STYLE_SHEET_ELEMENT_IS_FREE				>
	mov	dx, di
gotBaseStyle:

	pop	si

	; ds:si = style, ds:dx = base style

	; update added ui by calling callback

	popdw	bxax				;bxax = callback
	tst	bx
	jz	noCallback
	push	bp, ds
	movdw	cxdi, ss:[bp].SSCUMP_extraUI
	call	ProcCallFixedOrMovable
	pop	bp, ds
noCallback:

	popf
	call	StyleSheetUnlockStyleChunk
	pop	bx
	call	MemDerefDS

	LEAVE_FULL_EC

	call	AcceptUndo

done:
	.leave
	ret

StyleSheetModifyStyle	endp

if 0
illegalBaseStyleContext	char	"dbBadBase", 0
endif

ManipCode	ends

