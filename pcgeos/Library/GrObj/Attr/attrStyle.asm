COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj/Attr
FILE:		attrStyle.asm

AUTHOR:		jon

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision
	jon	20 apr 1992	adapted for GrObj

DESCRIPTION:
	$Id: attrStyle.asm,v 1.1 97/04/04 18:07:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjStyleSheetCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjCheckStyledClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tests whether the MSG_META_STYLED_OBJECT_* message
		is intended for a GrObjClass object

Pass:		ss:[bp] - styled class

Return:		carry set if styled class is grobj

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckStyledClass	proc	near
	.enter

	push	di, es
	movdw	esdi, ss:[bp]
	call	ObjIsObjectInClass
	jc	done

	cmp	ax, MSG_META_STYLED_OBJECT_RECALL_STYLE
	jnz	notRecall
	xchg	bx, cx
	call	MemIncRefCount
	xchg	bx, cx
notRecall:
	clr	di
	call	GrObjAttributeManagerMessageToText
	clc
done:
	pop	di, es
	.leave
	ret
GrObjCheckStyledClass	endp

;---

GrObjRequestEntryMoniker	proc	far
				;MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER

	.enter

	call	GrObjCheckStyledClass
	jnc	done

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GrObjGetStyleArray
	call	StyleSheetRequestEntryMoniker
	add	sp, size StyleChunkDesc
done:
	.leave
	ret
GrObjRequestEntryMoniker	endp

;---

GrObjUpdateModifyBox		proc	far
				;MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX

	.enter


	call	GrObjCheckStyledClass
	jnc	done

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GrObjGetStyleArray
	mov	ax, vsegment UpdateGrObjStyleAttributeList
	mov	di, offset UpdateGrObjStyleAttributeList
	call	StyleSheetUpdateModifyBox
	add	sp, size StyleChunkDesc
done:


	.leave
	ret
GrObjUpdateModifyBox	endp

;---

GrObjModifyStyle		proc	far
				;MSG_META_STYLED_OBJECT_MODIFY_STYLE

	.enter


	call	GrObjCheckStyledClass
	jnc	done

	call	ObjMarkDirty

	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GrObjGetStyleArray
	mov	ax, vsegment ModifyGrObjStyleAttributeList
	mov	di, offset ModifyGrObjStyleAttributeList
	call	StyleSheetModifyStyle
	add	sp, size StyleChunkDesc
done:
	; Send notification to the controller to update the description,
	; etc, if necessary.
	mov	cx, mask GOUINT_STYLE_SHEET or mask GOUINT_STYLE or \
		    mask GOUINT_AREA or mask GOUINT_LINE
	call	GrObjOptSendUINotification

	.leave
	ret

GrObjModifyStyle	endp

;---

GrObjDefineStyle		proc	far
				;MSG_META_STYLED_OBJECT_DEFINE_STYLE

	.enter


	call	GrObjCheckStyledClass
	jnc	done

	call	ObjMarkDirty
	mov	cx, bp
	mov	bp, offset CallDefine
	mov	ax, vsegment ModifyGrObjStyleAttributeList
	mov	di, offset ModifyGrObjStyleAttributeList
	call	LoadAndCallStyleSheet

	mov	ax, MSG_GO_SEND_UI_NOTIFICATION
	mov	cx, mask GOUINT_STYLE or mask GOUINT_STYLE_SHEET
	call	ObjCallInstanceNoLock
done:


	.leave
	ret

GrObjDefineStyle	endp



CallDefine	proc	near
	call	StyleSheetDefineStyle
	ret
CallDefine	endp


;---

GrObjRedefineStyle		proc	far
				;MSG_META_STYLED_OBJECT_REDEFINE_STYLE

	.enter


	call	GrObjCheckStyledClass
	jnc	done

	call	ObjMarkDirty
	mov	cx, bp
	mov	bp, offset CallRedefine
	mov	ax, vsegment ModifyGrObjStyleAttributeList
	mov	di, offset ModifyGrObjStyleAttributeList
	call	LoadAndCallStyleSheet

	;
	;  I don't know when a recalc is necessary, so just do it
	;
if 0
	tst	ax
	jz	noRecalc
endif
	call	RecalcAll
noRecalc::				; Conditional label

	mov	ax, MSG_GO_SEND_UI_NOTIFICATION
	mov	cx, mask GOUINT_STYLE or mask GOUINT_STYLE_SHEET
	call	ObjCallInstanceNoLock
done:

	.leave
	ret

GrObjRedefineStyle	endp


CallRedefine	proc	near
	call	StyleSheetRedefineStyle
	ret
CallRedefine	endp


;---

GrObjSaveStyle		proc	far
				;MSG_META_STYLED_OBJECT_SAVE_STYLE

	.enter

	call	GrObjCheckStyledClass
	jnc	done


	mov_tr	ax, bp				;ss:ax = SSCDefineParams
	mov	bp, offset CallSave
	call	LoadAndCallStyleSheet

done:
	.leave
	ret

GrObjSaveStyle	endp

CallSave	proc	near
	call	StyleSheetSaveStyle
	ret
CallSave	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjStyledObjectLoadStyleSheet --
			;MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET for GrObjClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

	ax - The message

	cx, dx, bp - data

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
GrObjStyledObjectLoadStyleSheet		proc	far
				 ;MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET

	; by default try to send this to a document object

	.enter

	push	si
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage			;di = message
	pop	si

	mov	cx, di
	mov	dx, TO_APP_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	GenCallApplication

	.leave
	ret
GrObjStyledObjectLoadStyleSheet	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDescribeStyle -- MSG_META_STYLED_OBJECT_DESCRIBE_STYLE
							for GrObjClass

DESCRIPTION:	Describe a style

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

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
GrObjDescribeStyle		proc	far
				;MSG_META_STYLED_OBJECT_DESCRIBE_STYLE

	.enter

	call	GrObjCheckStyledClass
	jnc	done

	mov	di, bp
	mov	bp, offset CallDescribe
	call	LoadAndCallStyleSheet

done:
	.leave
	ret

GrObjDescribeStyle	endp

CallDescribe	proc	near
	call	StyleSheetDescribeStyle
	ret
CallDescribe	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDescribeAttrs -- MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
							for GrObjClass

DESCRIPTION:	Describe a set of attributes

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

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
	Tony	12/23/91	Initial version

------------------------------------------------------------------------------@

CallDescribeAttrs	proc	near
	call	StyleSheetDescribeAttrs
	ret
CallDescribeAttrs	endp

GrObjDescribeAttrs	proc	far
			;MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
	.enter

	call	GrObjCheckStyledClass
	jnc	done

	mov	di, bp
	mov	bp, offset CallDescribeAttrs
	call	LoadAndCallStyleSheet

done:
	.leave
	ret

GrObjDescribeAttrs	endp

;---

LoadAndCallStyleSheet	proc	near

	uses	cx
	.enter

	mov_tr	bx, bp			;cs:bx = routine

	sub	sp, size StyleSheetParams
	mov	bp, sp

	push	cx
	clr	cx
	call	GrObjLoadSSParams
	pop	cx

	call	bx
	add	sp, size StyleSheetParams

	.leave
	ret
LoadAndCallStyleSheet	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GrObjLoadSSParams

DESCRIPTION:	Load a StyleSheetParams structure

CALLED BY:	INTERNAL

PASS:
	*ds:si - grobj
	ss:bp - StyleSheetParams
	cx - nonzero to preserve xfer stuff

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
	Tony	12/27/91	Initial version

------------------------------------------------------------------------------@
GrObjLoadSSParams	proc	near
	class GrObjClass
	uses ax, di
	.enter

	mov	ax, MSG_GOAM_LOAD_STYLE_SHEET_PARAMS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

	.leave
	ret
GrObjLoadSSParams	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjRecallStyle -- MSG_META_STYLED_OBJECT_RECALL_STYLE
							for GrObjClass

DESCRIPTION:	Recall a style

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

	ax - The message

	ss:[bp] - SSCRecallStyleParams

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
GrObjRecallStyle	proc	far
			;MSG_META_STYLED_OBJECT_RECALL_STYLE

	;
	;	Increment the ref count once, 'cause it's gonna
	;	get dec'd in SetAttrsCommon and there may be more
	;	grobjies wanting to use it...
	;
	;	The block will dec'd once by the GrObjBody after all this...
	;
	
	call	GrObjCheckStyledClass
	jnc	done

	mov	cx, ss:[bp].SSCRSP_blockHandle
	mov	bx, cx
	call	MemIncRefCount

	sub	sp, size StyleSheetParams
	mov	bp, sp

	; cal lthe style sheet code to copy the attributes in

	push	cx
	clr	cx
	call	GrObjLoadSSParams
	pop	cx
	call	StyleSheetPrepareForRecallStyle

	; get the attributes to set

	mov	ax, ss:[bp].SSP_attrTokens[0]	;ax = charAttr
	mov	bx, ss:[bp].SSP_attrTokens[2]	;bx = paraAttr
	clr	cx
	call	SetAttrsCommon

	add	sp, size StyleSheetParams
done:
	ret
GrObjRecallStyle	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjApplyStyle -- MSG_META_STYLED_OBJECT_APPLY_STYLE
							for GrObjClass

DESCRIPTION:	Describe a style

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

	ax - The message

	cx - used index or token (depends on dh)
	dl - non-zero if toolbox style being applied
	dh - non-zero if cx is a used index, zero if cx is a token

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
GrObjApplyStyle		proc	far
			;MSG_META_STYLED_OBJECT_APPLY_STYLE

	.enter

	call	GrObjCheckStyledClass
	jnc	done

	push	si, ds
	sub	sp, size StyleChunkDesc
	mov	bx, sp
	call	GrObjGetStyleArray
	call	StyleSheetLockStyleChunk	; *ds:si = style, carry = flag
	pushf

	call	StyleSheetGetStyleToApply

	mov	ss:[bp].SSCADSP_token, ax
	BitClr	ss:[bp].SSCADSP_flags, SSCADSF_TOKEN_IS_USED_INDEX

	call	ChunkArrayElementToPtr		; ds:di = style
	mov	ax, ds:[di].GSE_areaAttrToken
	mov	bx, ds:[di].GSE_lineAttrToken
	mov	cx, ds:[di].GSE_privateData.GSPD_flags
	popf
	call	StyleSheetUnlockStyleChunk
	add	sp, size StyleChunkDesc
	pop	si, ds

	call	SetAttrsCommon

done:
	.leave
	ret

GrObjApplyStyle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetAttrsCommon

DESCRIPTION:	Common code to set attributes

CALLED BY:	INTERNAL

PASS:
	*ds:si - grobj
	ax - area attr token
	bx - line attr token
	cx - GrObjStyleFlags

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
SetAttrsCommon	proc	far
	class	GrObjClass
	.enter

	mov_tr	cx, ax
	mov	ax, MSG_META_SUSPEND
	clr	di
	call	GrObjOrGOAMMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGOAM

	mov	cx, bx					;cx <- line token
	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGOAM

	mov	ax, MSG_META_UNSUSPEND
	clr	di
	call	GrObjOrGOAMMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
SetAttrsCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjOrGOAMMessageToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Utility routine for grobjs *and* GOAM to send a message
		to the body (or body list if GOAM)

PASS:		ds - block with graphic objects in it
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if no body return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
				nothing

DESTROYED:	
		nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul  5, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOrGOAMMessageToBody	proc	near
	class	GrObjClass
	.enter

	push	di
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	pop	di
	jnz	sendToBodyList

	;
	;	It's just a plain old grobj, so do a normal call
	;
	call	GrObjMessageToBody

done:
	.leave
	ret

sendToBodyList:

	;
	;	It's a GOAM, so send the passed message its body list
	;
	call	GOAMMessageToBodyList
	push	ax
	ClearZeroFlagPreserveCarry	ax
	pop	ax
	jmp	done
GrObjOrGOAMMessageToBody	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjReturnToBaseStyle --
				;MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE
							for GrObjClass

DESCRIPTION:	Describe a style

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

	ax - The message

	cx - used index (if negative) or token (if positive)
	dx - non-zero if toolbox style

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
GrObjReturnToBaseStyle		proc	far
				;MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE

	.enter

	call	GrObjCheckStyledClass
	jnc	done

	mov	ax, CA_NULL_ELEMENT
	mov	bx, ax
	clr	cx
	call	SetAttrsCommon

done:
	.leave
	ret

GrObjReturnToBaseStyle	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDeleteStyle -- MSG_META_STYLED_OBJECT_DELETE_STYLE
							for GrObjClass

DESCRIPTION:	Delete a style

PASS:
	*ds:si - instance data
	es - segment of GrObjClass

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
GrObjDeleteStyle	proc	far
			;MSG_META_STYLED_OBJECT_DELETE_STYLE

	.enter

	call	GrObjCheckStyledClass
	jnc	done

	call	ObjMarkDirty

	mov	ax, MSG_META_SUSPEND
	clr	di
	call	GrObjOrGOAMMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	mov	cx, ss:[bp].SSCADSP_token
	mov	dx, ss:[bp].SSCADSP_flags
	andnf	dx, mask SSCADSF_REVERT_TO_BASE_STYLE	
	mov	bp, offset CallDelete
	call	LoadAndCallStyleSheet

	push	ax
	mov	ax, MSG_META_UNSUSPEND
	clr	di
	call	GrObjOrGOAMMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	pop	ax

	tst	ax
	jz	noRecalc
	call	RecalcAll
noRecalc:

	mov	ax, MSG_GO_SEND_UI_NOTIFICATION
	mov	cx, mask GOUINT_STYLE or mask GOUINT_STYLE_SHEET
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

GrObjDeleteStyle	endp

CallDelete	proc	near
	call	StyleSheetDeleteStyle
	ret
CallDelete	endp

;---

RecalcAll	proc	near
	mov	ax, MSG_GOAM_INVALIDATE_BODIES
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGOAM
	ret
RecalcAll	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GrObjGetStyleArray

DESCRIPTION:	Load a StyleChunkDesc with a pointer to the style sheet info

CALLED BY:	INTERNAL

PASS:
	*ds:si - grobj
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
GrObjGetStyleArray	proc	far	uses ax, bx, cx, bp, di
	class	GrObjClass
	.enter

	mov	bp, bx
	mov	ss:[bp].SCD_chunk, 0

	mov	ax, MSG_GOAM_GET_STYLE_ARRAY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	jnc	done

	call	GrObjGlobalGetVMFile

	; cx = chunk, bx = file

	mov	ss:[bp].SCD_vmFile, bx
	mov	ss:[bp].SCD_vmBlockOrMemHandle, cx
	mov	ss:[bp].SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	stc
done:
	.leave
	ret

GrObjGetStyleArray	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SubstGrObjAreaAttr

DESCRIPTION:	Substitute old token with new token

CALLED BY:	INTERNAL

PASS:
	*ds:si - grobj object
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
SubstGrObjAreaAttr	proc	far
	class	GrObjClass

	mov	bp, di					;bp <- ref count flag
	mov	ax, MSG_GOAM_SUBST_AREA_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGOAM

	ret
SubstGrObjAreaAttr	endp

SubstGrObjLineAttr	proc	far
	class	GrObjClass

	mov	bp, di					;bp <- ref count flag
	mov	ax, MSG_GOAM_SUBST_LINE_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGOAM

	ret
SubstGrObjLineAttr	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAttributeManagerLoadStyleSheet --
		MSG_GOAM_LOAD_STYLE_SHEET for GrObjAttributeManagerClass

DESCRIPTION:	Merge data from a given style sheet

PASS:
	*ds:si - instance data
	es - segment of GrObjAttributeManagerClass

	ax - The message

	bp - StyleSheetParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
GrObjAttributeManagerLoadStyleSheet	method dynamic	\
					GrObjAttributeManagerClass,
					MSG_GOAM_LOAD_STYLE_SHEET

	mov	cx, 1			;reserve xfer stuff
	call	GrObjLoadSSParams
	mov	cx, 1			;force changing of destination styles
	call	StyleSheetImportStyles

if 0
	tst	ax
	jz	done
endif
	call	RecalcAll
;done:

	; Update the graphics controllers

	mov	ax, MSG_GO_SEND_UI_NOTIFICATION
	mov	cx, mask GOUINT_STYLE or mask GOUINT_AREA or \
		    mask GOUINT_LINE or mask GOUINT_STYLE_SHEET
	call	ObjCallInstanceNoLock

	ret

GrObjAttributeManagerLoadStyleSheet	endm

GrObjStyleSheetCode ends
