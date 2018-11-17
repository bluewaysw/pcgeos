COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taStyle.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------
	SendCharAttrParaAttrChange

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: taStyle.asm,v 1.1 97/04/07 11:18:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextRequestEntryMoniker --
		MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER for VisTextClass

DESCRIPTION:	Get a moniker for a style list

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - SSCListInteractionParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/29/92		Initial version

------------------------------------------------------------------------------@
VisTextRequestEntryMoniker	proc	far
				; MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
;EC <	ERROR_NC	VIS_TEXT_MESSAGE_REQUIRES_ATTR_STYLE_ARRAY	>
	;
	;   Some text objects don't use styles, such as GeoFile
	; FFText, so if the Style array doesn't exist then just
	; ignore everything and exit the handler.
	;
	jnc	ignore
	call	StyleSheetRequestEntryMoniker
ignore:
	add	sp, size StyleChunkDesc
	ret

VisTextRequestEntryMoniker	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetStyleArray

DESCRIPTION:	Load a StyleChunkDesc with a pointer to the style sheet info

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bx - StyleChunkDesc to fill

RETURN:
	carry - set if styles exist
	ss:bx - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@
GetStyleArray	proc	far	uses ax, bx, cx, bp
	class	VisTextClass
	.enter

	mov	bp, bx
	mov	ss:[bp].SCD_chunk, 0		;assume none
	mov	ax, ATTR_VIS_TEXT_STYLE_ARRAY
	call	ObjVarFindData
	jnc	done

	mov	ax, ds:[bx]

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	large

	; this is a small object -- it *might* still have VM blocks for the
	; attribute arrays, we have to look and see

	mov	bx, ds:[di].VTI_charAttrRuns
	mov	bx, ds:[bx]			;ds:bx = TextRunArrayHeader
	tst	ds:[bx].TRAH_elementVMBlock
	jnz	large
	clr	bx				;no file
	mov	cx, ds:[LMBH_handle]		;this block
	jmp	common
large:
	call	T_GetVMFile			;bx = file
	mov_tr	cx, ax
	mov	ax, VM_ELEMENT_ARRAY_CHUNK

common:
	; ax = chunk, bx = file, cx = handle

	mov	ss:[bp].SCD_chunk, ax
	mov	ss:[bp].SCD_vmFile, bx
	mov	ss:[bp].SCD_vmBlockOrMemHandle, cx
	stc
done:
	.leave
	ret

GetStyleArray	endp

TextControlCommon ends

;---

TextStyleSheet segment resource

VisTextUpdateModifyBox	proc	far
				; MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
	mov	ax, vsegment UpdateModifyTextStyleAttributeList
	mov	di, offset UpdateModifyTextStyleAttributeList
	call	StyleSheetUpdateModifyBox
	add	sp, size StyleChunkDesc
	ret

VisTextUpdateModifyBox	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextModifyStyle -- MSG_META_STYLED_OBJECT_MODIFY_STYLE
							for VisTextClass

DESCRIPTION:	Modify a style

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - SSCUpdateModifyParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/92		Initial version

------------------------------------------------------------------------------@
VisTextModifyStyle	proc	far
				; MSG_META_STYLED_OBJECT_MODIFY_STYLE

	; It is illegal to change a non-character only style to be based on
	; a character only style -- We must test for this case

	push	ds:[LMBH_handle], si
	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
	jc	haveStyle
	add	sp, size StyleChunkDesc
	pop	bx, si
	ret

haveStyle:
	call	StyleSheetLockStyleChunk	; *ds:si = style, carry = flag
	pushf

	; get the new base style

	push	si, bp
	movdw	bxsi, ss:[bp].SSCUMP_baseList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;ax = position
	pop	si, bp
	dec	ax
	clc
	js	baseStyleStatusKnown		;based on none is always OK
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = new base style

	call	ChunkArrayElementToPtr		;ds:di = new base style
	test	ds:[di].TSEH_privateData.TSPD_flags,
					mask TSF_APPLY_TO_SELECTION_ONLY
	jz	baseStyleStatusKnown		;carry is clear

	; the base style is a character only style, is the style to
	; modify a character only style ? (it better be :)

	mov	ax, ss:[bp].SSCUMP_usedIndex
	clr	bx
	call	ElementArrayUsedIndexToToken	;ax = style to change

	call	ChunkArrayElementToPtr		;ds:di = new base style
	test	ds:[di].TSEH_privateData.TSPD_flags,
					mask TSF_APPLY_TO_SELECTION_ONLY
	jnz	baseStyleStatusKnown		;carry is clear

	stc					;error!

baseStyleStatusKnown:

	; carry set if error

	lahf
	popf
	call	StyleSheetUnlockStyleChunk
	add	sp, size StyleChunkDesc
	pop	bx, si
	call	MemDerefDS
	sahf
	jnc	baseStyleIsOK

	; nope, wrong, sorry, you tried to do it, but it was a bad idea

	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
			CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>
	mov	ss:[bp].SDOP_customString.handle, handle BadModifyStyleString
	mov	ss:[bp].SDOP_customString.chunk, offset BadModifyStyleString
	clr	ss:[bp].SDOP_stringArg1.handle
	clr	ss:[bp].SDOP_stringArg2.handle
	clr	ss:[bp].SDOP_customTriggers.handle
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialogOptr
	jmp	done

baseStyleIsOK:
	call	TextMarkUserModified

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
	mov	ax, vsegment ModifyTextStyleAttributeList
	mov	di, offset ModifyTextStyleAttributeList
	call	StyleSheetModifyStyle
	add	sp, size StyleChunkDesc
done:
	call	StyleSendNotification
	ret

VisTextModifyStyle	endp

;---

VisTextDefineStyle	proc	far
				; MSG_META_STYLED_OBJECT_DEFINE_STYLE

	; we need to suspend and unsuspend the object around the definition
	; of the new style to allow the notifications to arrive in the
	; right order (since StyleSheetDefineStyle calls APPLY_STYLE)

	call	TextSuspend

	call	TextMarkUserModified
	mov	cx, bp
	mov	bp, offset CallDefine
	mov	ax, vsegment ModifyTextStyleAttributeList
	mov	di, offset ModifyTextStyleAttributeList
	call	LoadAndCallStyleSheet

	call	StyleSendNotification

	call	TextUnsuspend

	ret

VisTextDefineStyle	endp

CallDefine	proc	near
	call	StyleSheetDefineStyle
	ret
CallDefine	endp

;---

VisTextRedefineStyle	proc	far
				; MSG_META_STYLED_OBJECT_DEFINE_STYLE
	call	TextMarkUserModified
	mov	cx, bp
	mov	bp, offset CallRedefine
	mov	ax, vsegment ModifyTextStyleAttributeList
	mov	di, offset ModifyTextStyleAttributeList
	call	LoadAndCallStyleSheet

	call	RecalcAllIfAX
	ret

VisTextRedefineStyle	endp

CallRedefine	proc	near
	call	StyleSheetRedefineStyle
	ret
CallRedefine	endp

;---

VisTextSaveStyle	proc	far
				; MSG_META_STYLED_OBJECT_SAVE_STYLE
	mov_tr	ax, bp				;ss:ax = SSCDefineParams
	mov	bp, offset CallSave
	call	LoadAndCallStyleSheet
	ret

VisTextSaveStyle	endp

CallSave	proc	near
	call	StyleSheetSaveStyle
	ret
CallSave	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextStyledObjectLoadStyleSheet --
			MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET for VisTextClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	dx - size SSCLoadStyleSheetParams
	ss:bp - SSCLoadStyleSheetParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@
VisTextStyledObjectLoadStyleSheet	proc	far
				; MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET

	; by default try to send this to a document object

	push	si
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage			;di = message
	pop	si

	mov	cx, di
	mov	dx, TO_APP_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GOTO	ObjCallInstanceNoLock

VisTextStyledObjectLoadStyleSheet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextLoadStyleSheet -- MSG_VIS_TEXT_LOAD_STYLE_SHEET
							for VisTextClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - StyleSheetParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@
VisTextLoadStyleSheet	proc	far	; MSG_VIS_TEXT_LOAD_STYLE_SHEET

	call	TextMarkUserModified

	stc
	call	LoadSSParams
	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jz	done
	mov	cx, 1				;force changing of destination
						;styles
	call	StyleSheetImportStyles

	call	RecalcAllIfAX
	call	StyleSendNotification
done:
	ret

VisTextLoadStyleSheet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextDescribeStyle -- MSG_META_STYLED_OBJECT_DESCRIBE_STYLE
							for VisTextClass

DESCRIPTION:	Describe a style

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - SSCDescribeStyleParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@
VisTextDescribeStyle	proc	far	; MSG_META_STYLED_OBJECT_DESCRIBE_STYLE

	uses	ax, cx, dx, bp
	.enter

	mov	di, bp
	mov	bp, offset CallDescribe
	call	LoadAndCallStyleSheet

	.leave
	ret
VisTextDescribeStyle	endp

CallDescribe	proc	near
	call	StyleSheetDescribeStyle
	ret
CallDescribe	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextDescribeAttrs -- MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
							for VisTextClass

DESCRIPTION:	Describe a set of attributes

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - SSCDescribeAttrsParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@

CallDescribeAttrs	proc	near
	call	StyleSheetDescribeAttrs
	ret
CallDescribeAttrs	endp

VisTextDescribeAttrs	proc	far	; MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
	mov	di, bp
	mov	bp, offset CallDescribeAttrs
	call	LoadAndCallStyleSheet
	ret

VisTextDescribeAttrs	endp

;---

LoadAndCallStyleSheet	proc	near
	mov_tr	bx, bp			;cs:bx = routine

	sub	sp, size StyleSheetParams
	mov	bp, sp

	clc					;copy all
	call	LoadSSParams
	call	bx
	add	sp, size StyleSheetParams

	ret

LoadAndCallStyleSheet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextLoadStyleSheetParams --
		MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS handler for VisTextClass

DESCRIPTION:	Fills in the passed StyleSheetParams struct

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ss:bp - StyleSheetParams
	cx - nonzero to preserve xfer arrays

RETURN:
	ss:bp - StyleSheetParams filled in

DESTROYED:
	bx, si, di, ds, es (message handler)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 jun 1992	added to facilitate GrObj text style transfer
------------------------------------------------------------------------------@
VisTextLoadStyleSheetParams	proc	far
				; MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS

	tst_clc	cx
	jz	doLoad
	stc			;preserve transfer
doLoad:
	call	LoadSSParams

	ret

VisTextLoadStyleSheetParams	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadSSParams

DESCRIPTION:	Load a StyleSheetParams structure

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - StyleSheetParams
	carry - set to preserve xfer stuff

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
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@
LoadSSParams	proc	far		uses ax, bx, cx, dx, di, es
	class VisTextClass
	.enter

	; copy in static parameters

	mov	cx, size StyleSheetParams
	jnc	10$
	mov	cx, offset SSP_xferStyleArray
10$:
	push	si, ds
	segmov	es, ss
	lea	di, ss:[bp]
	segmov	ds, cs
	mov	si, offset ssParams
	rep movsb
	pop	si, ds

	; copy in styleArray

	lea	bx, ss:[bp].SSP_styleArray
	call	GetStyleArray
	jnc	done

	; copy in attrArrays

	call	T_GetVMFile			;bx = file
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VTI_charAttrRuns	;ax = charAttr runs
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	large

	xchg	ax, bx				;ax = file, bx = char attr chunk
	push	bp
	call	loadArray
	mov	bx, ds:[di].VTI_paraAttrRuns
	add	bp, size StyleChunkDesc
	call	loadArray
	pop	bp
	mov_tr	bx, ax				;bx = file
	jmp	common

large:
	push	bp, ds
	push	ds:[di].VTI_paraAttrRuns
	call	VMLock
	mov	ds, ax
	mov	cx, ds:TLRAH_elementVMBlock
	call	VMUnlock
	pop	ax
	call	VMLock
	mov	ds, ax
	mov	ax, ds:TLRAH_elementVMBlock
	call	VMUnlock
	pop	bp, ds

	mov	ss:[bp].SSP_attrArrays[0].SCD_vmBlockOrMemHandle, cx
	mov	ss:[bp].SSP_attrArrays[(size StyleChunkDesc)].\
						SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].SSP_attrArrays[0].SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_attrArrays[(size StyleChunkDesc)].SCD_chunk,
						VM_ELEMENT_ARRAY_CHUNK

common:
	mov	ss:[bp].SSP_attrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].SSP_attrArrays[(size StyleChunkDesc)].SCD_vmFile, bx
done:
	.leave
	ret

;---

loadArray:
	mov	bx, ds:[bx]
	mov	cx, ds:[bx].TRAH_elementVMBlock
	mov	dx, ds:[bx].TRAH_elementArray
	jcxz	notvm
	mov	dx, VM_ELEMENT_ARRAY_CHUNK
	jmp	loadCommon
notvm:
	clr	ax				;no file
	mov	cx, ds:[LMBH_handle]
loadCommon:
	mov	ss:[bp].SSP_attrArrays[0].SCD_vmBlockOrMemHandle, cx
	mov	ss:[bp].SSP_attrArrays[0].SCD_chunk, dx
	retn

LoadSSParams	endp

ssParams	StyleSheetParams	<
    <DescribeCharAttr, DescribeParaAttr, 0, 0>,	;SSP_descriptionCallbacks
    DescribeTextStyle,				;SSP_specialDescriptionCallback
    <MergeCharAttr, MergeParaAttr, 0, 0>,	;SSP_mergeCallbacks
    <SubstCharAttr, SubstParaAttr, 0, 0>,	;SSP_substitutionCallbacks
    <>,						;SSP_styleArray
    <>,						;SSP_attrArrays
    <>,						;SSP_attrTokens
    <0, 0, VM_ELEMENT_ARRAY_CHUNK>,		;SSP_xferStyleArray
    <						;SSP_xferAttrArrays
	<0, 0, VM_ELEMENT_ARRAY_CHUNK>,
	<0, 0, VM_ELEMENT_ARRAY_CHUNK>,
	<>, <>
    >
>

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextRecallStyle -- MSG_META_STYLED_OBJECT_RECALL_STYLE
							for VisTextClass

DESCRIPTION:	Recall a style

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - block

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/26/92		Initial version

------------------------------------------------------------------------------@
VisTextRecallStyle	proc	far	; MSG_META_STYLED_OBJECT_RECALL_STYLE

	mov	cx, ss:[bp].SSCRSP_blockHandle

	sub	sp, size StyleSheetParams
	mov	bp, sp

	; cal lthe style sheet code to copy the attributes in

	clc					;copy all
	call	LoadSSParams
	tst	ss:[bp].SSP_styleArray.SCD_chunk
	jz	done
	call	StyleSheetPrepareForRecallStyle

	; get the attributes to set

	mov	ax, ss:[bp].SSP_attrTokens[0]	;ax = charAttr
	mov	bx, ss:[bp].SSP_attrTokens[2]	;bx = paraAttr
	clr	cx
	call	SetAttrsCommon
done:
	add	sp, size StyleSheetParams

	ret

VisTextRecallStyle	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextApplyStyle -- MSG_META_STYLED_OBJECT_APPLY_STYLE
							for VisTextClass

DESCRIPTION:	Describe a style

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - SSCApplyDeleteStyleParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@
VisTextApplyStyle	proc	far		; MSG_META_STYLED_OBJECT_APPLY_STYLE

	push	si, ds
	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GetStyleArray
	call	StyleSheetLockStyleChunk	; *ds:si = style, carry = flag
	pushf

	call	StyleSheetGetStyleToApply

	call	ChunkArrayElementToPtr		; ds:di = style
	mov	ax, ds:[di].TSEH_charAttrToken
	mov	bx, ds:[di].TSEH_paraAttrToken
	mov	cx, ds:[di].TSEH_privateData.TSPD_flags
	popf
	call	StyleSheetUnlockStyleChunk
	add	sp, size StyleChunkDesc
	pop	si, ds

	call	SetAttrsCommon

	ret

VisTextApplyStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetAttrsCommon

DESCRIPTION:	Common code to set attributes

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ax - char attr token
	bx - para attr token
	cx - TextStyleFlags

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
	Tony	3/26/92		Initial version

------------------------------------------------------------------------------@
SetAttrsCommon	proc	near
	sub	sp, size VisTextSetCharAttrByTokenParams
	mov	bp, sp

	push	cx
	push	ax

	call	TextSuspend

	pop	ss:[bp].VTSCABTP_charAttr
	pop	cx
	push	cx

	mov	ax, offset StyleString
	mov	di, VIS_TEXT_RANGE_SELECTION
	test	cx, mask TSF_APPLY_TO_SELECTION_ONLY
	jnz	selectionOnly
	mov	ax, offset FormattingString
	mov	di, VIS_TEXT_RANGE_PARAGRAPH_SELECTION
selectionOnly:
	call	TU_StartChainIfUndoable

	mov	ss:[bp].VTSCABTP_range.VTR_start.high, di

	; di also holds range to recalc

	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN
	call	ObjCallInstanceNoLock
	pop	cx

	test	cx, mask TSF_APPLY_TO_SELECTION_ONLY
	jnz	noParaAttr
	mov	ss:[bp].VTSPABTP_paraAttr, bx
	mov	ss:[bp].VTSPABTP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN
	call	ObjCallInstanceNoLock
noParaAttr:
	call	TU_EndChainIfUndoable

	call	TextUnsuspend

	add	sp, size VisTextSetCharAttrByTokenParams
	ret

SetAttrsCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextReturnToBaseStyle --
				MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE
							for VisTextClass

DESCRIPTION:	Describe a style

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@
VisTextReturnToBaseStyle	proc	far
			; MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE
	class	VisTextClass

	call	TextSuspend

	sub	sp, size VisTextSetCharAttrByTokenParams
	mov	bp, sp

	mov	ss:[bp].VTSCABTP_charAttr, CA_NULL_ELEMENT
	mov	ss:[bp].VTSCABTP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR_BY_TOKEN
	call	ObjCallInstanceNoLock

	mov	ss:[bp].VTSPABTP_paraAttr, CA_NULL_ELEMENT
	mov	ss:[bp].VTSPABTP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR_BY_TOKEN
	call	ObjCallInstanceNoLock

	call	TextUnsuspend

	add	sp, size VisTextSetCharAttrByTokenParams

	ret

VisTextReturnToBaseStyle	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextDeleteStyle -- MSG_META_STYLED_OBJECT_DELETE_STYLE
							for VisTextClass

DESCRIPTION:	Delete a style

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - SSCApplyDeleteStyleParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/23/91		Initial version

------------------------------------------------------------------------------@
VisTextDeleteStyle	proc	far	; MSG_META_STYLED_OBJECT_DELETE_STYLE

	call	TextMarkUserModified

	mov	cx, ss:[bp].SSCADSP_token
	mov	dx, ss:[bp].SSCADSP_flags
	andnf	dx, mask SSCADSF_REVERT_TO_BASE_STYLE	
	mov	bp, offset CallDelete
	call	LoadAndCallStyleSheet

	call	RecalcAllIfAX

	ret

VisTextDeleteStyle	endp

CallDelete	proc	near
	call	StyleSheetDeleteStyle
	ret
CallDelete	endp

;---

	; Recalculate the object if ax is non-zero

RecalcAllIfAX	proc	near
	uses	cx
	.enter

	tst	ax
	jz	noRecalc
	clr	cx					;not relayed yet
	mov	ax, MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
	call	ObjCallInstanceNoLock
noRecalc:
	call	StyleSendNotification

	.leave
	ret
RecalcAllIfAX	endp

StyleSendNotification	proc	near
	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification
	ret
StyleSendNotification	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstCharAttr

DESCRIPTION:	Substitute old token with new token

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - old element token
	dx - new element token
	di - non-zero to update reference counts

RETURN:
	ax - non-zero if recalc needed

DESTROYED:
	bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@
SubstCharAttr	proc	far
	class	VisTextClass

	mov	bx, offset VTI_charAttrRuns
	FALL_THRU	SubstCommon

SubstCharAttr	endp

;---

SubstCommon	proc	far
	clr	ax
recalcFlag	local	word	push	ax
params		local	VisTextSubstAttrTokenParams
	.enter

	; send ourself a message to do the work so that GrObj (or somebody else)
	; can pass it on if needed

	mov	params.VTSATP_oldToken, cx
	mov	params.VTSATP_newToken, dx
	mov	params.VTSATP_runOffset, bx
	mov	params.VTSATP_updateRefFlag, di
	mov	params.VTSATP_relayedToLikeTextObjects, 0
	lea	ax, recalcFlag
	movdw	params.VTSATP_recalcFlag, ssax

	push	bp
	lea	bp, params
	mov	ax, MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	call	ObjCallInstanceNoLock
	pop	bp

	mov	ax, recalcFlag

	.leave
	ret

SubstCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSubstAttrToken -- MSG_VIS_TEXT_SUBST_ATTR_TOKEN
							for VisTextClass

DESCRIPTION:	Substitute attribute tokens

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	bp - VisTextSubstAttrTokenParams

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/25/92		Initial version

------------------------------------------------------------------------------@
VisTextSubstAttrToken	proc	far ;  MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	class	VisTextClass

	pushdw	dssi
	mov	bx, ss:[bp].VTSATP_runOffset
	call	FarRunArrayLock		;ds:si = first element, di = token
					;cx = count

	mov	ax, ss:[bp].VTSATP_oldToken
	mov	dx, ss:[bp].VTSATP_newToken

	clc
	pushf				;save coalesce flag

substLoop:
	cmp	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH
	jz	done
	cmp	ax, ds:[si].TRAE_token
	jnz	next
	tst	ss:[bp].VTSATP_updateRefFlag
	jz	noRefs
	mov	bx, ax
	call	RemoveElement
	mov	bx, dx
	call	ElementAddRef
noRefs:
	mov	ds:[si].TRAE_token, dx
	call	FarRunArrayMarkDirty
	les	bx, ss:[bp].VTSATP_recalcFlag
	or	{byte} es:[bx], 1
	popf
	stc
	pushf
next:
	add	si, size TextRunArrayElement
	loop	substLoop
	sub	si, size TextRunArrayElement
	xchg	ax, cx			;HugeArray code uses ax for count
	call	HugeArrayNext
	xchg	cx, ax
	jmp	substLoop

done:
	call	FarRunArrayUnlock

	popf
	popdw	dssi
	jnc	noCoalesce
	mov	bx, ss:[bp].VTSATP_runOffset
	call	CoalesceRun
	call	UpdateLastRunPositionByRunOffset
noCoalesce:

	ret

VisTextSubstAttrToken	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstParaAttr

DESCRIPTION:	Substitute old token with new token

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - old element token
	dx - new element token
	di - non-zero to update reference counts

RETURN:
	ax - non-zero if recalc needed

DESTROYED:
	bx, cx, dx, si, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/27/91		Initial version

------------------------------------------------------------------------------@
SubstParaAttr	proc	far
	class	VisTextClass

	mov	bx, offset VTI_paraAttrRuns
	GOTO	SubstCommon

SubstParaAttr	endp

TextStyleSheet ends
