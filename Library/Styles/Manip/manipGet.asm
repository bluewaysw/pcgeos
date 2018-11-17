COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library/Styles
FILE:		Manip/manipGet.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

DESCRIPTION:
	This file contains code for StyleSheetGetStyle

	$Id: manipGet.asm,v 1.1 97/04/07 11:15:32 newdeal Exp $

------------------------------------------------------------------------------@

idata	segment

notifyCounter	word	0

idata	ends

;---

CommonCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetGetNotifyCounter

DESCRIPTION:	Get the counter value to send out with GWNT_STYLE_SHEET
		notifications

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - counter

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/16/92		Initial version

------------------------------------------------------------------------------@
StyleSheetGetNotifyCounter	proc	far	uses ds
	.enter

	mov	ax, seg notifyCounter
	mov	ds, ax
	mov	ax, ds:notifyCounter

	.leave	
	ret

StyleSheetGetNotifyCounter	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetGetStyle

DESCRIPTION:	Get a style from a style array

CALLED BY:	GLOBAL

PASS:
	es:di - buffer (size NameArrayMaxElement)
	ss:bx - StyleChunkDesc for style array
	ax - style token
	
RETURN:
	ax - element size
	bx - used index
	cx - used tool index

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetGetStyle	proc	far	uses dx, si, ds
	.enter

	call	StyleSheetLockStyleChunk	;*ds:si = style array
	pushf

	cmp	ax, CA_NULL_ELEMENT
	jz	indeterminate

	push	di
	push	ax
	mov	bx, 1
	call	LoadCallbackFlagBX		;bx:di <- callback routine
	call	ElementArrayTokenToUsedIndex
	mov	cx, ax				;cx = used tool index

	;convert back to see if we get the same thing, if not then the
	; token is not displayed in the tool list

	call	ElementArrayUsedIndexToToken
	mov_tr	bx, ax
	pop	ax
	cmp	ax, bx
	jz	existsInToolList		;the token is not displayed in
	mov	cx, CA_NULL_ELEMENT		;the tool list
existsInToolList:

	push	ax
	clr	bx
	call	ElementArrayTokenToUsedIndex
	mov_tr	bx, ax				;bx = used index
	pop	ax
	pop	di

	push	cx
	movdw	cxdx, esdi
	call	ChunkArrayGetElement		;ax = size
	pop	cx

done:
	popf
	call	StyleSheetUnlockStyleChunk

	.leave
	ret

indeterminate:
	mov	bx, CA_NULL_ELEMENT
	mov	cx, bx
	jmp	done

StyleSheetGetStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetGetStyleCounts

DESCRIPTION:	Get the number of styles

CALLED BY:	GLOBAL

PASS:
	ss:bx - StyleChunkDesc for style array
	
RETURN:
	ax - number of styles
	bx - number of toolbox styles

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetGetStyleCounts	proc	far	uses si, di, ds
	.enter

	call	StyleSheetLockStyleChunk	;*ds:si = style array
	pushf

	clr	bx
	call	ElementArrayGetUsedCount
	push	ax

	dec	bx
	call	LoadCallbackFlagBX		;bx:di <- callback routine
	call	ElementArrayGetUsedCount
	mov_tr	bx, ax				;bx = toolbox count
	pop	ax

	popf
	call	StyleSheetUnlockStyleChunk

	.leave
	ret

StyleSheetGetStyleCounts	endp

;---

LoadCallbackFlagBX	proc	near
	tst	bx
	jz	notToolbox
	mov	bx, SEGMENT_CS			; bx <- vptr if XIP'ed
	mov	di, offset IndexTokenCallback
notToolbox:
	ret

LoadCallbackFlagBX	endp

;---

	; ds:di = element

IndexTokenCallback	proc	far
	test	ds:[di].SEH_flags, mask SEF_DISPLAY_IN_TOOLBOX
	clc
	jz	done
	stc
done:
	ret

IndexTokenCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetRequestEntryMoniker

DESCRIPTION:	Handle request for the number of entries from a GenList
		displaying the list of styles.

CALLED BY:	GLOBAL

PASS:
	ss:bx - StyleChunkDesc for style array
	ss:bp - SSCListInteractionParams
	
RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetRequestEntryMoniker	proc	far	uses si
params	local	ReplaceItemMonikerFrame
	mov	di, bp			;ss:di = SSCListInteractionParams
	.enter

	mov	ax, ss:[di].SSCLIP_entryNumber
	mov	cx, ax
	add	cx, ss:[di].SSCLIP_defaultEntries
	mov	params.RIMF_item, cx
	mov	params.RIMF_sourceType, VMST_FPTR
	mov	params.RIMF_dataType, VMDT_TEXT
	mov	params.RIMF_itemFlags, 0

	push	ds:[LMBH_handle]
	call	StyleSheetLockStyleChunk	;*ds:si = style array
	pushf

	mov	bx, ss:[di].SSCLIP_toolboxFlag
	call	LoadCallbackFlagBX		;bx:di <- callback
	call	ElementArrayUsedIndexToToken	;ax = token

	; a wierd case can happen here where the element is free because things
	; have happened too fast

	mov	params.RIMF_source.segment, SEGMENT_CS	;assume screwy case
	mov	params.RIMF_source.offset, offset NullString
	mov	params.RIMF_length, 0

	cmp	ax, CA_NULL_ELEMENT
	jz	gotMoniker
	call	ChunkArrayElementToPtr		;ds:di = data, cx = size
	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT
	jz	gotMoniker
	mov	si, ds:[si]
	mov	ax, ds:[si].NAH_dataSize
	add	ax, size NameArrayElement
	add	di, ax				;ds:di = name
	sub	cx, ax
	movdw	params.RIMF_source, dsdi
	mov	params.RIMF_length, cx

gotMoniker:
	push	bp
	mov	di, ss:[bp]
	movdw	bxsi, ss:[di].SSCLIP_list
	lea	bp, params
	mov	dx, size ReplaceItemMonikerFrame
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	ObjMessage
	pop	bp

	popf
	call	StyleSheetUnlockStyleChunk
	pop	bx
	call	MemDerefDS

	.leave
	ret

StyleSheetRequestEntryMoniker	endp

SBCS <NullString	char	0					>
DBCS <NullString	wchar	0					>

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetGenerateChecksum

DESCRIPTION:	Generate a checksum for a block.  This is useful for generating
		the NotifyStyleChange structure, which contains checksums to
		force updating when any of the underlying attribute structures
		have changed

CALLED BY:	GLOBAL

PASS:
	ds:si - structure
	cx - size

RETURN:
	dxax - checksum

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 8/92		Initial version

------------------------------------------------------------------------------@
StyleSheetGenerateChecksum	proc	far	uses bx, cx, si
	.enter

if FULL_EXECUTE_IN_PLACE
EC<	mov	bx, ds					>
EC<	call	ECAssertValidFarPointerXIP		>
endif

	clrdw	dxbx			;dxbx = result
	shr	cx
calcLoop:

	; result = ((result + word) << 3) | word
	lodsw
	add	bx, ax
	adc	dx, 0
	rol	bx
	rcl	dx
	rol	bx
	rcl	dx
	rol	bx
	rcl	dx
	xor	bx, ax
	loop	calcLoop

	mov_tr	ax, bx			;dxax = result

	.leave
	ret

StyleSheetGenerateChecksum	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetGetStyleToApply

DESCRIPTION:	Get the token of the style to apply

CALLED BY:	GLOBAL

PASS:
	*ds:si - style array
	ss:bp - SSCApplyDeleteStyleParams

RETURN:
	ax - token

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/13/92		Initial version

------------------------------------------------------------------------------@
StyleSheetGetStyleToApply	proc	far	uses bx, di
	.enter

	mov_tr	ax, ss:[bp].SSCADSP_token
	test	ss:[bp].SSCADSP_flags, mask SSCADSF_TOKEN_IS_USED_INDEX
	jz	done

	clr	bx
	test	ss:[bp].SSCADSP_flags, mask SSCADSF_TOOLBOX_STYLE
	jz	10$
	inc	bx
10$:
	call	LoadCallbackFlagBX			; bx:si <- callback
	call	ElementArrayUsedIndexToToken
done:
	.leave
	ret

StyleSheetGetStyleToApply	endp

CommonCode	ends

ManipCode	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StyleSheetIncNotifyCounter

DESCRIPTION:	Increment the counter value to send out with GWNT_STYLE_SHEET
		notifications.

CALLED BY:	INTERNAL

PASS:
	none

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
	Tony	1/16/92		Initial version

------------------------------------------------------------------------------@
StyleSheetIncNotifyCounter	proc	far	uses ax, ds
	.enter

	mov	ax, seg notifyCounter
	mov	ds, ax
	inc	ds:notifyCounter

	.leave	
	ret

StyleSheetIncNotifyCounter	endp

ManipCode ends


