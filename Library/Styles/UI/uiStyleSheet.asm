COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiStyleSheetControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	StyleSheetControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement StyleSheetControlClass

	$Id: uiStyleSheet.asm,v 1.1 97/04/07 11:15:17 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

idata segment

	StyleSheetControlClass		;declare the class record

idata ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

StyleSheetControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for StyleSheetControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

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
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
StyleSheetControlGetInfo	method dynamic	StyleSheetControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SSC_dupInfo

	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret

StyleSheetControlGetInfo	endm

SSC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SSC_IniFileKey,			; GCBI_initFileKey
	0,				; GCBI_gcnList -- filled in by subclass
	0,				; GCBI_gcnCount -- filled in by subclass
	SSC_notifyTypeList,		; GCBI_notificationList
	length SSC_notifyTypeList,	; GCBI_notificationCount
	SSCName,			; GCBI_controllerName

	handle StyleSheetControlUI,	; GCBI_dupBlock
	SSC_childList,			; GCBI_childList
	length SSC_childList,		; GCBI_childCount
	SSC_featuresList,		; GCBI_featuresList
	length SSC_featuresList,	; GCBI_featuresCount
	SSC_DEFAULT_FEATURES,		; GCBI_features

	handle StyleSheetControlToolboxUI,	; GCBI_toolBlock
	SSC_toolList,			; GCBI_toolList
	length SSC_toolList,		; GCBI_toolCount
	SSC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SSC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SSC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

SSC_IniFileKey	char	"styleSheet", 0

SSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_STYLE_SHEET_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_STYLE_CHANGE>

;---

SSC_childList	GenControlChildInfo	\
	<offset ApplyStyleBox, mask SSCF_APPLY,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DefineNewStyleBox, mask SSCF_DEFINE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset RedefineTrigger, mask SSCF_REDEFINE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ReturnToBaseStyleTrigger, mask SSCF_RETURN_TO_BASE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ManageStylesBox, mask SSCF_MANAGE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LoadStyleSheetBox, mask SSCF_LOAD,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SaveRecallGroup, mask SSCF_SAVE_STYLE or \
				 mask SSCF_RECALL_STYLE, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSC_featuresList	GenControlFeaturesInfo	\
	<offset RecallStyleTrigger, RecallStyleName, 0>,
	<offset SaveStyleTrigger, SaveStyleName, 0>,
	<offset LoadStyleSheetBox, LoadStyleSheetName, 0>,
	<offset ManageStylesBox, ManageStylesName, 0>,
	<offset ApplyStyleBox, ApplyStyleName, 0>,
	<offset ReturnToBaseStyleTrigger, ReturnToBaseStyleName, 0>,
	<offset RedefineTrigger, RedefineStyleName, 0>,
	<offset DefineNewStyleBox, DefineNewStyleName, 0>

;---

SSC_toolList	GenControlChildInfo	\
	<offset RedefineStyleToolTrigger, mask SSCTF_REDEFINE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ReturnToBaseStyleToolTrigger, mask SSCTF_RETURN_TO_BASE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SaveStyleToolTrigger, mask SSCTF_SAVE_STYLE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset RecallStyleToolTrigger, mask SSCTF_RECALL_STYLE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset StylesToolList, mask SSCTF_STYLE_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset RecallStyleToolTrigger, RecallStyleName, 0>,
	<offset SaveStyleToolTrigger, SaveStyleName, 0>,
	<offset StylesToolList, PopupStyleListName, 0>,
	<offset ReturnToBaseStyleToolTrigger, ReturnToBaseStyleName, 0>,
	<offset RedefineStyleToolTrigger, RedefineStyleName, 0>

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlQueryStyle -- MSG_SSC_QUERY_STYLE
					for StyleSheetControlClass

DESCRIPTION:	Update a moniker in the main style list

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	cx:dx - GenDynamicList
	bp - entry number

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
	Tony	12/19/91		Initial version

------------------------------------------------------------------------------@
StyleSheetControlQueryStyle	method dynamic	StyleSheetControlClass,
						MSG_SSC_QUERY_STYLE

	mov	ax, MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER
	FALL_THRU	ListInteractionCommon

StyleSheetControlQueryStyle	endm

;---

	; ax - message
	; cx:dx - list
	; bp - item

ListInteractionCommon	proc	far
	mov	bx, bp
	sub	sp, size SSCListInteractionParams
	mov	bp, sp

	movdw	ss:[bp].SSCLIP_list, cxdx
	mov	ss:[bp].SSCLIP_entryNumber, bx

	; special case BaseStyleList, which has an extra entry

	clr	bx
	cmp	dx, offset BaseStyleList
	jnz	10$
	inc	bx
10$:
	mov	ss:[bp].SSCLIP_defaultEntries, bx

	; special case toolbox list

	push	ax
	call	GetChildBlockAndFeatures
	pop	ax
	clr	di
	cmp	bx, cx
	jz	notToolbox
	inc	di
notToolbox:
	mov	ss:[bp].SSCLIP_toolboxFlag, di

	; pass this off to the target to deal with

	mov	dx, size SSCListInteractionParams
	call	SendToOutputStackWithClass

	add	sp, dx
	ret

ListInteractionCommon	endp

;---

SendToOutputStackWithClass	proc	far	uses bx, di
	class	StyleSheetControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].StyleSheetControl_offset

	movdw	ss:[bp], ds:[di].SSCI_styledClass, bx

	movdw	bxdi, ds:[di].SSCI_targetClass

	call	GenControlSendToOutputStack

	.leave
	ret
SendToOutputStackWithClass	endp

;---

GetChildBlockAndFeatures	proc	far
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret

GetChildBlockAndFeatures	endp

;---

StyleSheetControlApplyToolboxStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_APPLY_TOOLBOX_STYLE

	mov	dx, size SSCApplyDeleteStyleParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].SSCADSP_token, cx
	mov	ss:[bp].SSCADSP_flags,	mask SSCADSF_TOOLBOX_STYLE or \
					mask SSCADSF_TOKEN_IS_USED_INDEX

	mov	ax, MSG_META_STYLED_OBJECT_APPLY_STYLE
	call	SendToOutputStackWithClass
	add	sp, dx
	ret
StyleSheetControlApplyToolboxStyle	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for StyleSheetControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
StyleSheetControlUpdateUI	method dynamic StyleSheetControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock

	cmp	ss:[bp].GCUUIP_changeType, GWNT_STYLE_CHANGE
	LONG jnz styleSheetChange

	; The current style changed.  We must update any lists that are
	; visible

	; save tokens in vardata

	push	ax, bx
	push	si
	mov	ax, TEMP_SYTLE_SHEET_ATTR_TOKENS
	call	ObjVarFindData
	jc	gotData
	mov	cx, size SSCTempAttrInfo
	call	ObjVarAddData
gotData:
	segxchg	ds, es				;ds:... = source, es:bx = dest
	mov	si, offset NSC_attrTokens
	mov	di, bx
	mov	cx, MAX_STYLE_SHEET_ATTRS
	rep movsw
	mov	ax, ({StyleElementHeader} ds:NSC_style).SEH_flags
	mov	es:[bx].SSCTAI_styleFlags, ax
	mov	ax, ds:NSC_styleToken
	mov	es:[bx].SSCTAI_baseStyle, ax
	mov	al, ds:NSC_canRedefine
	mov	es:[bx].SSCTAI_canRedefine, al
	mov	al, ds:NSC_indeterminate
	mov	es:[bx].SSCTAI_indeterminate, al
	segxchg	ds, es
	pop	si

	pop	ax, bx
	mov	cx, es:NSC_usedIndex
	test	ax, mask SSCF_APPLY
	jz	noApply

	push	si
	mov	si, offset ApplyList
	call	SendSetExcl
	pop	si

noApply:

	test	ax, mask SSCF_MANAGE
	jz	noManage
	push	si
	mov	si, offset MSList
	call	SendSetExcl
	pop	si
	call	UpdateManageDescription
noManage:

	test	ax, mask SSCF_DEFINE
	jz	noDefine
	call	UpdateDefineBox
noDefine:

	test	ax, mask SSCF_REDEFINE
	jz	noRedefine
	push	ax
	stc
	mov	ax, MSG_GEN_SET_ENABLED
	mov	di, offset RedefineTrigger
	call	UpdateTriggerCommon
	pop	ax
noRedefine:

	; update "recall style" trigger

	mov	dx, MSG_GEN_SET_ENABLED
	push	ax, bx
	mov	ax, TEMP_SYTLE_SHEET_SAVED_STYLE
	call	ObjVarFindData
	pop	ax, bx
	jc	35$
	mov	dx, MSG_GEN_SET_NOT_ENABLED
35$:
	test	ax, mask SSCF_RECALL_STYLE
	jz	noRecall
	push	ax, si
	mov	si, offset RecallStyleTrigger
	mov	ax, dx
	call	SSC_ObjMessageFixupDS_VUM_NOW
	pop	ax, si
noRecall:

	; dx = state for "recall style" trigger

	; calculate state for "return to base" trigger

	mov	cx, MSG_GEN_SET_ENABLED
	tst	es:NSC_canReturnToBase
	jnz	40$
	mov	cx, MSG_GEN_SET_NOT_ENABLED
40$:

	test	ax, mask SSCF_RETURN_TO_BASE
	jz	noReturnToBase
	push	ax, dx, si
	mov	si, offset ReturnToBaseStyleTrigger
	mov	ax, cx
	call	SSC_ObjMessageFixupDS_VUM_NOW
	pop	ax, dx, si
noReturnToBase:

	; cx = message for "return to base" trigger
	; dx = state for "recall style" trigger

;---

	mov	ax, ss:[bp].GCUUIP_toolboxFeatures
	mov	bx, ss:[bp].GCUUIP_toolBlock
	push	si

	test	ax, mask SSCTF_RETURN_TO_BASE
	jz	noReturnToBaseTool
	push	ax, dx
	mov	si, offset ReturnToBaseStyleToolTrigger
	mov	ax, cx
	call	SSC_ObjMessageFixupDS_VUM_NOW
	pop	ax, dx
noReturnToBaseTool:

	test	ax, mask SSCTF_RECALL_STYLE
	jz	noRecallTool
	push	ax
	mov	si, offset RecallStyleToolTrigger
	mov	ax, dx
	call	SSC_ObjMessageFixupDS_VUM_NOW
	pop	ax
noRecallTool:

	test	ax, mask SSCTF_STYLE_LIST
	jz	noStyleListTool
	push	ax
	mov	si, offset StylesToolList
	mov	cx, es:NSC_usedToolIndex
	call	SendSetExcl
	pop	ax
noStyleListTool:
	pop	si

	test	ax, mask SSCTF_REDEFINE
	jz	noRedefineTool
	push	ax
	stc
	mov	di, offset RedefineStyleToolTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	call	UpdateTriggerCommon
	pop	ax
noRedefineTool:

	; if there are any indeterminate attributes then disable save style

	mov	di, offset NSC_attrTokens
	mov	cx, size NSC_attrTokens
	mov	ax, CA_NULL_ELEMENT
	repne	scasw
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	gotSaveStyle
	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotSaveStyle:

	test	ss:[bp].GCUUIP_toolboxFeatures, mask SSCTF_SAVE_STYLE
	jz	noSaveTool
	mov	si, offset SaveStyleToolTrigger
	call	SSC_ObjMessageFixupDS_VUM_NOW
noSaveTool:

	test	ss:[bp].GCUUIP_features, mask SSCF_SAVE_STYLE
	jz	noSave
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset SaveStyleTrigger
	call	SSC_ObjMessageFixupDS_VUM_NOW
noSave:

	jmp	done

	; The style sheet changed.  We must update any lists that are
	; visible.

styleSheetChange:
	test	ax, mask SSCF_MANAGE
	jz	noManage2

	mov	cx, es:NSSHC_styleCount
	mov	si, offset MSList
	call	forceListToUpdate
	inc	cx
	mov	si, offset BaseStyleList
	call	forceListToUpdate		;cx = entry #
noManage2:

	test	ax, mask SSCF_APPLY
	jz	noApply2
	mov	cx, es:NSSHC_styleCount
	mov	si, offset ApplyList
	call	forceListToUpdate
noApply2:

	test	ss:[bp].GCUUIP_toolboxFeatures, mask SSCTF_STYLE_LIST
	jz	noToolApply2
	mov	cx, es:NSSHC_toolStyleCount
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset StylesToolList
	call	forceListToUpdate
noToolApply2:

done:
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock
	ret

;---

	; bx:si = list, cx = # of entries

forceListToUpdate:
	push	ax, cx, bp

	push	cx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSC_ObjMessageCallFixupDS	;ax = selection
	pop	cx
	push	ax

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	call	SSC_ObjMessageFixupDS

	pop	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	SSC_ObjMessageFixupDS

	pop	ax, cx, bp
	retn

StyleSheetControlUpdateUI	endm

;----------------

SendSetExcl	proc	near	uses ax, dx
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	SSC_ObjMessageFixupDS
	.leave
	ret

SendSetExcl	endp

;---

	; ^lbx:di = object to update
	; carry - set for redefine trigger

UpdateTriggerCommon	proc	far	uses si, di
	.enter

	push	di
	push	bx
	pushf
	push	ax
	mov	ax, TEMP_SYTLE_SHEET_ATTR_TOKENS
	call	ObjVarFindData
	pop	ax
	popf

	jnc	isDefine

	; it is the redefine trigger -- must differ from base and must not
	; be based on null

	cmp	ds:[bx].SSCTAI_baseStyle, CA_NULL_ELEMENT
	jz	forceDisabled
	tst	ds:[bx].SSCTAI_canRedefine
	jz	forceDisabled
	jmp	common

isDefine:
	clr	di
checkIndeterminateLoop:
	cmp	ds:[bx][di], CA_NULL_ELEMENT
	jz	forceDisabled
	add	di, size word
	cmp	di, MAX_STYLE_SHEET_ATTRS * 2
	jnz	checkIndeterminateLoop

common:
	tst	ds:[bx].SSCTAI_indeterminate
	jz	dontForceDisabled
forceDisabled:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
dontForceDisabled:
	pop	bx
	pop	si
	call	SSC_ObjMessageFixupDS_VUM_NOW

	.leave
	ret

UpdateTriggerCommon	endp

;---

SSC_ObjMessageCallFixupDS	proc	far	uses di
	.enter
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	SSC_ObjMessage
	.leave
	ret
SSC_ObjMessageCallFixupDS	endp

;---

SSC_ObjMessageFixupDS_VUM_NOW	proc	far
	mov	dl, VUM_NOW
	FALL_THRU	SSC_ObjMessageFixupDS

SSC_ObjMessageFixupDS_VUM_NOW	endp

;---

SSC_ObjMessageFixupDS	proc	far	uses	di
	.enter
	mov	di, mask MF_FIXUP_DS
	call	SSC_ObjMessage
	.leave
	ret
SSC_ObjMessageFixupDS	endp

;---

SSC_ObjMessage	proc	near
	call	ObjMessage
	ret
SSC_ObjMessage	endp

StyleSheetControlCommon ends

;==================================================

StyleSheetControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlGenerateUI -- MSG_GEN_CONMTROL_GENERATE_UI
						for StyleSheetControlClass

DESCRIPTION:	Send a message to allow subclass to add on to our "manage
		styles" dialog box

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

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
	Tony	12/19/91		Initial version

------------------------------------------------------------------------------@
StyleSheetControlGenerateUI	method dynamic	StyleSheetControlClass,
						MSG_GEN_CONTROL_GENERATE_UI

	; let normal generation happen first

	mov	di, offset StyleSheetControlClass
	call	ObjCallSuperNoLock

	; add in UI from subclass

	mov	ax, MSG_STYLE_SHEET_GET_MODIFY_UI
	mov	di, mask SSCF_MANAGE
	mov	dx, offset MSModifyBox
	mov	bp, 3
	mov	bx, TEMP_STYLE_SHEET_MANAGE_UI
	call	AddUIComponent

	mov	ax, MSG_STYLE_SHEET_GET_DEFINE_UI
	mov	di, mask SSCF_DEFINE
	mov	dx, offset DefineNewStyleBox
	mov	bp, 2
	mov	bx, TEMP_STYLE_SHEET_DEFINE_UI
	call	AddUIComponent

	; set the path for the "load style sheet" file selector if needed

	mov	ax, ATTR_STYLE_SHEET_LOAD_STYLE_SHEET_PATH
	call	ObjVarFindData
	jnc	noLoadPath

	push	si
	VarDataSizePtr	ds, bx, cx		;cx = size
	mov	dx, bx
	call	GetChildBlockAndFeatures
	test	ax, mask SSCF_LOAD
	jz	noLoadPath
	sub	sp, size AddVarDataParams
	mov	bp, sp
	movdw	ss:[bp].AVDP_data, dsdx
	mov	ss:[bp].AVDP_dataSize, cx
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_PATH_DATA
	mov	si, offset LoadFileBox
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams
	pop	si
noLoadPath:

	; set the token match characters

	mov	ax, ATTR_STYLE_SHEET_LOAD_STYLE_SHEET_TOKEN
	call	ObjVarFindData
	jnc	noLoadToken

	mov	dx, bx
	call	GetChildBlockAndFeatures
	test	ax, mask SSCF_LOAD
	jz	noLoadToken
	sub	sp, size AddVarDataParams
	mov	bp, sp
	movdw	ss:[bp].AVDP_data, dsdx
	mov	ss:[bp].AVDP_dataSize, size GeodeToken
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_FILE_SELECTOR_TOKEN_MATCH
	mov	si, offset LoadFileBox
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams
noLoadToken:

	ret

StyleSheetControlGenerateUI	endm

;---

	; ax = message, di = feature mask, dx = parent chunk, bp = position
	; bx = vardata key

AddUIComponent	proc	near
	push	bx				;save vardata key
	push	dx				;save parent chunk
	push	bp				;save position

	; find child to add (if any)

	clr	cx
	call	ObjCallInstanceNoLock		;cx:dx = child to add
	jcxz	done

	; if the manage styles group exists then call ourself

	call	GetChildBlockAndFeatures
	test	ax, di
	jz	done
	push	bx				;save parent block

	; add the group

	clr	ax				;owned by current geode
	mov	bx, cx
	clr	cx				;run by current thread
	call	ObjDuplicateResource

	mov	cx, bx				;cx:dx = child
	pop	bx				;bx = parent block
	pop	bp				;bp = position
	pop	ax				;ax = parent
	push	si
	mov_tr	si, ax				;bx:si = parent
	mov	ax, MSG_GEN_ADD_CHILD
	call	SSC_ObjMessageCallFixupDS

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_SET_USABLE
	call	SSC_ObjMessageFixupDS_VUM_NOW

	movdw	didx, bxsi			;di:dx = new UI
	pop	si				;*ds:si = controller

	; add vardata to store the OD of the added UI

	pop	ax				;ax = vardata key
	mov	cx, size optr
	call	ObjVarAddData
	movdw	ds:[bx], didx
	ret

done:
	add	sp, 6				;bp, dx, bx
	ret

AddUIComponent	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlDestroyUI --
			MSG_GEN_CONTROL_DESTROY_UI for StyleSheetControlClass

DESCRIPTION:	Destroy the UI for this controller

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

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
	Tony	6/10/92		Initial version

------------------------------------------------------------------------------@
StyleSheetControlDestroyUI	method dynamic	StyleSheetControlClass,
						MSG_GEN_CONTROL_DESTROY_UI

	mov	di, offset StyleSheetControlClass
	call	ObjCallSuperNoLock

	; destroy added UI

	mov	ax, TEMP_STYLE_SHEET_MANAGE_UI
	call	destroy
	mov	ax, TEMP_STYLE_SHEET_DEFINE_UI
	call	destroy

	ret

;---

destroy:
	call	ObjVarFindData
	jnc	done
	push	ax, si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_META_BLOCK_FREE
	call	SSC_ObjMessageCallFixupDS
	pop	ax, si
	call	ObjVarDeleteData
done:
	retn

StyleSheetControlDestroyUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlLoadStyleSheetFileSelected --
		MSG_SSC_LOAD_STYLE_SHEET_FILE_SELECTED
					for StyleSheetControlClass

DESCRIPTION:	Handle user selection of a file

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	bp - GenFileSelectorEntryFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/22/92		Initial version

------------------------------------------------------------------------------@
StyleSheetControlLoadStyleSheetFileSelected	method dynamic	\
				StyleSheetControlClass,
				MSG_SSC_LOAD_STYLE_SHEET_FILE_SELECTED

	test	bp, mask GFSEF_OPEN
	jz	done

	and	bp, mask GFSEF_TYPE
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	jnz	done

	mov	ax, MSG_SSC_LOAD_STYLE_SHEET
	call	ObjCallInstanceNoLock

done:
	ret

StyleSheetControlLoadStyleSheetFileSelected	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlLoadStyleSheet -- MSG_SSC_LOAD_STYLE_SHEET
					for StyleSheetControlClass

DESCRIPTION:	Handle user request to load style sheet

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

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
	Tony	2/22/92		Initial version

------------------------------------------------------------------------------@
StyleSheetControlLoadStyleSheet	method dynamic	StyleSheetControlClass,
						MSG_SSC_LOAD_STYLE_SHEET

	; test for volume or directory selected

	push	si
	call	GetChildBlockAndFeatures	;bx = child block
	mov	si, offset LoadFileBox

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	cx, ax				;cx = entry # of selection
	andnf	bp, mask GFSEF_TYPE
	cmp	bp, GFSET_SUBDIR shl offset GFSEF_TYPE
	jz	volumeOrDir
	cmp	bp, GFSET_VOLUME shl offset GFSEF_TYPE
	jnz	notVolumeOrDir

volumeOrDir:
	mov_tr	cx, ax				;cx = entry # of selection
	mov	ax, MSG_GEN_FILE_SELECTOR_OPEN_ENTRY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	ret
notVolumeOrDir:

	; file opened -- do our thing

	mov	dx, bx
	mov	bp, si
	pop	si

	sub	sp, size SSCLoadStyleSheetParams
	mov_tr	ax, bp
	mov	bp, sp
	mov	ss:[bp].SSCLSSP_fileSelector.handle, dx
	mov	ss:[bp].SSCLSSP_fileSelector.chunk, ax
	mov	dx, size SSCLoadStyleSheetParams
	mov	ax, MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET
	call	SendToOutputStackWithClass
	add	sp, size SSCLoadStyleSheetParams

	call	GetChildBlockAndFeatures
	mov	si, offset LoadStyleSheetBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_INTERACTION_COMPLETE
	clr	di
	GOTO	ObjMessage

StyleSheetControlLoadStyleSheet	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlSetSavedStyle --
		MSG_STYLE_SHEET_SET_SAVED_STYLE for StyleSheetControlClass

DESCRIPTION:	Set the saved style

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	cx - block handle

RETURN:

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
StyleSheetControlSetSavedStyle	method dynamic	StyleSheetControlClass,
						MSG_STYLE_SHEET_SET_SAVED_STYLE

	; if an old saved style exists then biff it

	mov	ax, TEMP_SYTLE_SHEET_SAVED_STYLE
	call	ObjVarFindData
	jnc	noOldStyle

	mov	di, bx				;ds:di = data
	mov	bx, ds:[bx]
	call	MemDecRefCount
	jmp	common

noOldStyle:
	push	cx
	mov	cx, size hptr
	call	ObjVarAddData
	pop	cx
	mov	di, bx				;ds:di = data

common:
	mov	ds:[di], cx
	mov	bx, cx
	mov	ax, 1				;initial ref count
	call	MemInitRefCount

	ret

StyleSheetControlSetSavedStyle	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlDetach -- MSG_META_DETACH
					for StyleSheetControlClass

DESCRIPTION:	Handle detach by nuking any saved style

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	cx, dx, bp - data

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
StyleSheetControlDetach	method dynamic	StyleSheetControlClass, MSG_META_DETACH

	mov	ax, TEMP_SYTLE_SHEET_SAVED_STYLE
	call	ObjVarFindData
	jnc	noSavedStyle
	mov	bx, ds:[bx]
	call	MemDecRefCount
	call	ObjVarDeleteData
noSavedStyle:

	mov	ax, MSG_META_DETACH
	mov	di, offset StyleSheetControlClass
	GOTO	ObjCallSuperNoLock

StyleSheetControlDetach	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlInitiateModifySytle --
		MSG_SSC_INITIATE_MODIFY_STYLE for StyleSheetControlClass

DESCRIPTION:	Initiate the Modify style dialog box

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

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
	Tony	1/ 7/92		Initial version

------------------------------------------------------------------------------@
StyleSheetControlInitiateModifySytle	method dynamic	StyleSheetControlClass,
					MSG_SSC_INITIATE_MODIFY_STYLE

	mov	di, MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX
	call	ModifyCommon			;bx = block
	cmp	cx, -1
	jz	done

	mov	si, offset MSModifyBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	SSC_ObjMessageFixupDS
done:
	ret

StyleSheetControlInitiateModifySytle	endm

;---

StyleSheetControlModifyStyle	method dynamic StyleSheetControlClass,
					MSG_SSC_MODIFY_STYLE

	mov	di, MSG_META_STYLED_OBJECT_MODIFY_STYLE
	call	ModifyCommon
	ret

StyleSheetControlModifyStyle	endm

;---

	; di = message

ModifyCommon	proc	near

	sub	sp, size SSCUpdateModifyParams
	mov	bp, sp

	; Get OD of added group (if any)

	mov	ax, TEMP_STYLE_SHEET_MANAGE_UI
	call	ObjVarFindData
	jnc	noCustom
	movdw	ss:[bp].SSCUMP_extraUI, ds:[bx], ax
noCustom:

	call	GetChildBlockAndFeatures		;bx = block

	push	si, bp
	mov	si, offset MSList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSC_ObjMessageCallFixupDS		;ax = selection
	pop	si, bp
	mov	ss:[bp].SSCUMP_usedIndex, ax
	cmp	ax, GIGS_NONE
	jz	done

	mov	ss:[bp].SSCUMP_textObject.handle, bx
	mov	ss:[bp].SSCUMP_textObject.offset, offset ModifyNameText
	mov	ss:[bp].SSCUMP_baseList.handle, bx
	mov	ss:[bp].SSCUMP_baseList.offset, offset BaseStyleList
	mov	ss:[bp].SSCUMP_attrList.handle, bx
	mov	ss:[bp].SSCUMP_attrList.offset, offset ModifyAttrList
	mov	dx, size SSCUpdateModifyParams

	mov_tr	ax, di				;ax = message
	call	SendToOutputStackWithClass
done:
	add	sp, size SSCUpdateModifyParams
	ret

ModifyCommon	endp

;--

StyleSheetControlQueryBaseStyle	method dynamic	StyleSheetControlClass,
						MSG_SSC_QUERY_BASE_STYLE

	; special case BaseStyleList, which has an extra entry

	dec	bp
	jns	notSpecialCase

	; this is the special entry

	inc	bp
	movdw	bxsi, cxdx
	mov	cx, handle NoBaseStyleMoniker
	mov	dx, offset NoBaseStyleMoniker
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
	call	SSC_ObjMessageCallFixupDS
	ret

notSpecialCase:

	; pass this off to the target to deal with

	mov	ax, MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER
	call	ListInteractionCommon
	ret

StyleSheetControlQueryBaseStyle	endm

;---

StyleSheetControlSaveStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_SAVE_STYLE

	sub	sp, size SSCSaveStyleParams
	mov	bp, sp

	mov	ax, TEMP_SYTLE_SHEET_ATTR_TOKENS
	mov	cx, size SSCTempAttrInfo
	call	ObjVarFindData
	push	si
	segmov	es, ss				;ds:bx = source, es:di = dest
	lea	di, ss:[bp].SSCSSP_attrTokens
	mov	si, bx
	mov	cx, size SSCSSP_attrTokens
	rep movsb
	pop	si

	mov	ax, ds:[LMBH_handle]		;pass our OD to respond to
	movdw	ss:[bp].SSCSSP_replyObject, axsi

	mov	ax, MSG_META_STYLED_OBJECT_SAVE_STYLE
	mov	dx, size SSCSaveStyleParams
	call	SendToOutputStackWithClass
	add	sp, size SSCSaveStyleParams

	; update the recall style triggers

	call	GetChildBlockAndFeatures
	test	ax, mask SSCF_RECALL_STYLE
	jz	noRecall
	push	si
	mov	ax, MSG_GEN_SET_ENABLED
	mov	si, offset RecallStyleTrigger
	call	SSC_ObjMessageFixupDS_VUM_NOW
	pop	si
noRecall:

	call	GetToolBlockAndFeatures
	test	ax, mask SSCTF_RECALL_STYLE
	jz	noRecallTool
	mov	si, offset RecallStyleToolTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	call	SSC_ObjMessageFixupDS_VUM_NOW
noRecallTool:

	ret

StyleSheetControlSaveStyle	endm

;---

GetToolBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_toolboxFeatures
	mov	bx, ds:[bx].TGCI_toolBlock
	ret
GetToolBlockAndFeatures	endp

;---

StyleSheetControlRecallStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_RECALL_STYLE

	mov	ax, TEMP_SYTLE_SHEET_SAVED_STYLE
	call	ObjVarFindData
	jnc	done
	mov	bx, ds:[bx]			;pass block
	call	MemIncRefCount
	mov	cx, bx
	sub	sp, size SSCRecallStyleParams
	mov	bp, sp
	mov	ss:[bp].SSCRSP_blockHandle, cx
	mov	ax, MSG_META_STYLED_OBJECT_RECALL_STYLE
	mov	dx, size SSCRecallStyleParams
	call	SendToOutputStackWithClass
	add	sp, size SSCRecallStyleParams
done:
	ret

StyleSheetControlRecallStyle	endm

;---

StyleSheetControlDeleteStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_DELETE_STYLE

	clr	dx				;don't revert
	GOTO	DeleteCommon

StyleSheetControlDeleteStyle	endm

;---

StyleSheetControlDeleteRevertStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_DELETE_REVERT_STYLE

	mov	dx, mask SSCADSF_REVERT_TO_BASE_STYLE
	FALL_THRU	DeleteCommon

StyleSheetControlDeleteRevertStyle	endm

DeleteCommon	proc	far
	mov	ax, MSG_META_STYLED_OBJECT_DELETE_STYLE
	call	ApplyDeleteCommon
	ret
DeleteCommon	endp

;---

StyleSheetControlApplyBoxStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_APPLY_BOX_STYLE

	mov	dx, size SSCApplyDeleteStyleParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].SSCADSP_token, cx
	mov	ss:[bp].SSCADSP_flags, mask SSCADSF_TOKEN_IS_USED_INDEX

	mov	ax, MSG_META_STYLED_OBJECT_APPLY_STYLE
	call	SendToOutputStackWithClass
	add	sp, dx
	ret
StyleSheetControlApplyBoxStyle	endm

;---

StyleSheetControlApplyStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_APPLY_STYLE

	mov	ax, MSG_META_STYLED_OBJECT_APPLY_STYLE
	mov	dx, mask SSCADSF_TOKEN_IS_USED_INDEX
	FALL_THRU	ApplyDeleteCommon

StyleSheetControlApplyStyle	endm

;---

ApplyDeleteCommon	proc	far
	push	ax, dx, si
	call	GetChildBlockAndFeatures
	mov	si, offset MSList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSC_ObjMessageCallFixupDS		;ax = entry #
	mov_tr	cx, ax
	pop	ax, dx, si
	cmp	cx, GIGS_NONE
	jz	done

	sub	sp, size SSCApplyDeleteStyleParams
	mov	bp, sp
	mov	ss:[bp].SSCADSP_flags, dx
	mov	ss:[bp].SSCADSP_token, cx
	mov	dx, size SSCApplyDeleteStyleParams
	call	SendToOutputStackWithClass
	add	sp, size SSCApplyDeleteStyleParams
done:
	ret

ApplyDeleteCommon	endp

;---

StyleSheetControlReturnTobaseStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_RETURN_TO_BASE_STYLE

	mov	dx, size SSCReturnToBaseStyleParams
	sub	sp, dx
	mov	bp, sp
	mov	ax, MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE
	call	SendToOutputStackWithClass
	add	sp, dx
	ret
StyleSheetControlReturnTobaseStyle	endm

;---

StyleSheetControlDefineStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_DEFINE_STYLE

	; make sure that we can define a style

	push	si
	call	GetChildBlockAndFeatures
	mov	si, offset CNDefineTrigger
	mov	ax, MSG_GEN_GET_ENABLED
	call	SSC_ObjMessageCallFixupDS
	pop	si
	jnc	done

	mov	ax, MSG_META_STYLED_OBJECT_DEFINE_STYLE
	call	DefineRedefineCommon
done:
	ret

StyleSheetControlDefineStyle	endm

;---

StyleSheetControlRedefineStyle	method dynamic StyleSheetControlClass,
						MSG_SSC_REDEFINE_STYLE

	mov	ax, MSG_META_STYLED_OBJECT_REDEFINE_STYLE
	FALL_THRU	DefineRedefineCommon

StyleSheetControlRedefineStyle	endm

;---

DefineRedefineCommon	proc	far
	sub	sp, size SSCDefineStyleParams
	mov	bp, sp
	push	ax

	; Get OD of added group (if any)

	mov	ax, TEMP_STYLE_SHEET_DEFINE_UI
	call	ObjVarFindData
	jnc	noCustom
	movdw	ss:[bp].SSCDSP_extraUI, ds:[bx], ax
noCustom:

	mov	ax, TEMP_SYTLE_SHEET_ATTR_TOKENS
	mov	cx, size SSCTempAttrInfo
	call	ObjVarFindData
	push	si
	segmov	es, ss				;ds:bx = source, es:di = dest
	lea	di, ss:[bp].SSCDSP_attrTokens
	mov	si, bx
	mov	cx, size SSCTempAttrInfo
	rep movsb
	pop	si

	call	GetChildBlockAndFeatures
	mov	ss:[bp].SSCDSP_textObject.handle, bx
	mov	ss:[bp].SSCDSP_textObject.chunk, offset CNName
	mov	ss:[bp].SSCDSP_attrList.handle, bx
	mov	ss:[bp].SSCDSP_attrList.chunk, offset CNAttrList

			CheckHack <(size SEH_reserved) eq 6>
	clr	ax
	mov	{word} ss:[bp].SSCDSP_reserved, ax
	mov	{word} ss:[bp].SSCDSP_reserved+2, ax
	mov	{word} ss:[bp].SSCDSP_reserved+4, ax

	pop	ax
	mov	dx, size SSCDefineStyleParams
	call	SendToOutputStackWithClass

	add	sp, size SSCDefineStyleParams

	; clear the name in the dialog box

	call	GetChildBlockAndFeatures
;	call	ClearDefineDescription

	ret

DefineRedefineCommon	endp

;---

ClearDefineDescription	proc	near	uses si
	.enter

	mov	si, offset CNName
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_EVERYTHING
	call	SSC_ObjMessageFixupDS

	.leave
	ret

ClearDefineDescription	endp

;---

	; a text object changed from empty to not empty or visa versa

StyleSheetControlEmptyStatusChanged	method dynamic StyleSheetControlClass,
						MSG_META_TEXT_EMPTY_STATUS_CHANGED

	cmp	dx, offset CNName
	jnz	done

	call	GetChildBlockAndFeatures

	mov	ax, MSG_GEN_SET_ENABLED		;for define -- assume text
	tst	bp
	jnz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	di, offset CNDefineTrigger
	clc
	call	UpdateTriggerCommon
done:
	ret

StyleSheetControlEmptyStatusChanged	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StyleSheetControlSelectStyle -- MSG_SSC_SELECT_STYLE
						for StyleSheetControlClass

DESCRIPTION:	Handle a style selection

PASS:
	*ds:si - instance data
	es - segment of StyleSheetControlClass

	ax - The message

	cx - used index
	bp - number of selections

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
StyleSheetControlSelectStyle	method StyleSheetControlClass,
						MSG_SSC_SELECT_STYLE

	mov	dx, size SSCApplyDeleteStyleParams
	mov	sp, dx
	mov	bp, sp
	mov	ss:[bp].SSCADSP_token, cx
	mov	ss:[bp].SSCADSP_flags, mask SSCADSF_TOKEN_IS_USED_INDEX	
	mov	ax, MSG_META_STYLED_OBJECT_APPLY_STYLE
	call	OutputActionStackWithClass
	add	sp, dx
	ret
StyleSheetControlSelectStyle	endm

;---

StyleSheetControlStatusStyle	method StyleSheetControlClass,
						MSG_SSC_STATUS_STYLE

	call	GetChildBlockAndFeatures
	call	UpdateManageDescription
	ret

StyleSheetControlStatusStyle	endm

;---

OutputActionStackWithClass	proc	far	uses bx, di
	class	StyleSheetControlClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].StyleSheetControl_offset

	movdw	ss:[bp], ds:[di].SSCI_styledClass, bx

	movdw	bxdi, ds:[di].SSCI_targetClass

	call	GenControlOutputActionStack

	.leave
	ret

OutputActionStackWithClass	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateManageDescription

DESCRIPTION:	Update the text object containing the text description
		of the style

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	bx - UI block
	cx - index

RETURN:
	none

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 8/92		Initial version

------------------------------------------------------------------------------@
UpdateManageDescription	proc	far	uses ax, bx, bp, dx, si
	.enter

	mov	dx, size SSCDescribeStyleParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].SSCDSP_describeTextObject.handle, bx
	mov	ss:[bp].SSCDSP_describeTextObject.chunk, offset MSDescription
	mov	ss:[bp].SSCDSP_describeDeleteTrigger.handle, bx
	mov	ss:[bp].SSCDSP_describeDeleteTrigger.chunk, offset MSDeleteTrigger
	mov	ss:[bp].SSCDSP_describeDeleteRevertTrigger.handle, bx
	mov	ss:[bp].SSCDSP_describeDeleteRevertTrigger.chunk, offset MSDeleteRevertTrigger
	mov	ss:[bp].SSCDSP_usedIndex, cx
	mov	ax, MSG_META_STYLED_OBJECT_DESCRIBE_STYLE
	call	SendToOutputStackWithClass
	add	sp, dx

	.leave
	ret

UpdateManageDescription	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateDefineBox

DESCRIPTION:	Update the Define New box

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	bx - block containing UI

RETURN:
	none

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/13/92		Initial version

------------------------------------------------------------------------------@
UpdateDefineBox	proc	far	uses ax, bp
	.enter

	sub	sp, size SSCDescribeAttrsParams
	mov	bp, sp

	push	bx
	mov	ax, TEMP_SYTLE_SHEET_ATTR_TOKENS
	call	ObjVarFindData
	clr	di
copyAttrLoop:
	mov	ax, ds:[bx][di]
	tst	ds:[bx].SSCTAI_indeterminate
	jz	10$
	mov	ax, CA_NULL_ELEMENT
10$:
	mov	ss:[bp][SSCDAP_attrTokens][di], ax
	add	di, 2
	cmp	di, MAX_STYLE_SHEET_ATTRS * 2
	jnz	copyAttrLoop

	clrdw	cxdx
	mov	ax, TEMP_STYLE_SHEET_DEFINE_UI
	call	ObjVarFindData
	jnc	noData
	movdw	cxdx, ds:[bx]
noData:
	movdw	ss:[bp].SSCDAP_extraUI, cxdx
	pop	bx

	mov	ss:[bp].SSCDAP_textObject.handle, bx
	mov	ss:[bp].SSCDAP_textObject.offset, offset CNDescription
	mov	ss:[bp].SSCDAP_attrList.handle, bx
	mov	ss:[bp].SSCDAP_attrList.offset, offset CNAttrList
	mov	dx, size SSCDescribeAttrsParams

	mov	ax, MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS
	call	SendToOutputStackWithClass

	add	sp, size SSCDescribeAttrsParams

	call	ClearDefineDescription

	.leave
	ret

UpdateDefineBox	endp

StyleSheetControlCode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++
