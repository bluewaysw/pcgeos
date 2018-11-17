COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Cards Library 
FILE:		uiCardBackSelector.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 oct 1992	initial revision

DESCRIPTION:
	This file contains routines to implement CardBackSelectorClass

	$Id: uiCardBackSelector.asm,v 1.1 97/04/04 17:44:28 newdeal Exp $

------------------------------------------------------------------------------@

CardBackListItemClass	class	GenItemClass
CardBackListItemClass	endc

CardsClassStructures	segment	resource
	CardBackSelectorClass
	CardBackDynamicListClass
	CardBackListItemClass
CardsClassStructures	ends

CardBackSelectorCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	CardBackSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for CardBackSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of CardBackSelectorClass

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
CardBackSelectorGetInfo	method dynamic	CardBackSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset CBS_dupInfo
	call	CopyDupInfoCommon
	ret

CardBackSelectorGetInfo	endm

CopyDupInfoCommon	proc	near
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo / 2
	rep movsw
	ret
CopyDupInfoCommon	endp

CBS_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	CBS_IniFileKey,			; GCBI_initFileKey
	CBS_gcnList,			; GCBI_gcnList
	length CBS_gcnList,		; GCBI_gcnCount
	CBS_notifyTypeList,		; GCBI_notificationList
	length CBS_notifyTypeList,	; GCBI_notificationCount
	CardBackSelectorName,		; GCBI_controllerName

	handle CardBackSelectorUI,		; GCBI_dupBlock
	CBS_childList,			; GCBI_childList
	length CBS_childList,		; GCBI_childCount
	CBS_featuresList,		; GCBI_featuresList
	length CBS_featuresList,		; GCBI_featuresCount
	CARD_BACK_SELECTOR_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	CBS_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
CardsControlInfoXIP	segment	resource
endif

CBS_helpContext	char	"dbCardBacks", 0

CBS_IniFileKey	char	"CardBackSelector", 0

CBS_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_CARD_BACK_CHANGE>

CBS_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CARD_BACK_CHANGE>

;---

CBS_childList	GenControlChildInfo	\
	<offset CardBackList, mask CBSF_CARD_BACK_LIST, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

CBS_featuresList	GenControlFeaturesInfo	\
	<offset CardBackList, CardBackListName, 0>

if FULL_EXECUTE_IN_PLACE
CardsControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	CardBackSelectorSetCardBack -- MSG_CBS_SET_CARD_BACK for
					      CardBackSelectorClass

DESCRIPTION:	Return list item monikers

PASS:
	*ds:si - instance data
	es - segment of CardBackSelectorClass

	ax - The message

	cx - which card back
	bp - item number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 9/92		Initial version

------------------------------------------------------------------------------@
CardBackSelectorSetCardBack	method dynamic	CardBackSelectorClass,
				MSG_CBS_SET_CARD_BACK
	.enter

	mov	bx, segment GameClass
	mov	di, offset GameClass
	mov	ax, MSG_GAME_CHOOSE_BACK
	call	GenControlOutputActionRegs

	.leave
	ret
CardBackSelectorSetCardBack	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	CardBackSelectorQueryCardBack -- MSG_CBS_QUERY_CARD_BACK for
					      CardBackSelectorClass

DESCRIPTION:	Return list item monikers

PASS:
	*ds:si - instance data
	es - segment of CardBackSelectorClass

	ax - The message

	cxdx - requesting list
	bp - item number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 9/92		Initial version

------------------------------------------------------------------------------@
CardBackSelectorQueryCardBack	method dynamic	CardBackSelectorClass,
				MSG_CBS_QUERY_CARD_BACK
	.enter

	push	cx, dx, bp			;save optr, item #

	mov	bx, ds:[di].CBSI_vmFile
	mov	ax, ds:[di].CBSI_mapBlock
	mov	di, bp
	shl	di
	shl 	di
	call	VMLock
	mov	es, ax
	mov	ax, es:[DMS_backs][di].handle	;ax <- VM block handle
	mov	dx, es:[DMS_backs][di].chunk	;dx <- CBitmap offset within
						;      VM block
	call	VMUnlock

	call	VMLock
	push	ax				;save bitmap segment

	clr	cx
	mov	ax, LMEM_TYPE_GENERAL
	call	MemAllocLMem
	mov	cl, GST_CHUNK
	call	GrCreateGString			; si = chunk handle

	pop	ds
	mov	cx, bx				;save mem handle in cx
	push	si
	mov	si, dx

	lodsw
	call	GrSetAreaColor

	; edwdig - leave some space around the bitmap so it's easier to
	; tell which back is selected
	; ok this block of code is kinda messy right now
	; originally i tried manually sizing the moniker, but that wasn't it
	; leaving that code here anyway, commented out
	clr	dx ; ax, bx
	mov	ax, 4
	mov	bx, 2
	call	GrDrawBitmap
	call	VMUnlock
	;call	GrGetBitmapSize	
	;add	ax, 4		; add extra width
	;add	bx, 4		; add extra height
	;push	ax
	call	GrEndGString
	;pop	ax	
	mov	si, di
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	di

	;	edwdig - don't do this yet because we need still need ax, bx
	pop	bx, si, ax			;^lbx:si <- list
                                           	;ax <- item #
	;	Don't put any pushes or pops in here! Code relies
	;	on the positions of what's on the stack!
	sub	sp, size ReplaceItemMonikerFrame
	mov	bp, sp
	clr	dx
	mov	ss:[bp].RIMF_length, dx
	mov	ss:[bp].RIMF_width, dx	; edwdig - ax for moniker sizing method
	mov	ss:[bp].RIMF_height, dx ; edwdig - bx for moniker sizing method
	movdw	ss:[bp].RIMF_source, cxdi
	mov	ss:[bp].RIMF_sourceType, VMST_OPTR
	mov	ss:[bp].RIMF_dataType, VMDT_GSTRING
	mov	ss:[bp].RIMF_itemFlags, 0
	mov	ss:[bp].RIMF_item, ax	
if 0
	; edwdig - turns out we don't really need this
	mov	ax, ss:[bp+ size ReplaceItemMonikerFrame]	
	mov	ss:[bp].RIMF_item, ax
	mov	bx, ss:[bp + size ReplaceItemMonikerFrame + 4]
	mov	si, ss:[bp + size ReplaceItemMonikerFrame + 2]	
endif	

	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	dx, size ReplaceItemMonikerFrame
	mov	di, mask MF_STACK
	call	ObjMessage

	add	sp, size ReplaceItemMonikerFrame ;+ 6	; edwdig - to clear up the stack

	mov	bx, cx
	call	MemFree

	.leave
	ret
CardBackSelectorQueryCardBack	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CBSNotifyWithDataBlock -- MSG_META_NOTIFY_WITH_DATA_BLOCK
					for CardBackSelectorClass

DESCRIPTION:	HACK: Save notification data for GENERATE_UI

PASS:
	*ds:si - instance data
	es - segment of CardBackSelectorClass

	ax - The message

	cx.dx - change type ID
	bp - handle of data block

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/94		Initial version

------------------------------------------------------------------------------@
CBSNotifyWithDataBlock	method dynamic CardBackSelectorClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK,
					MSG_META_NOTIFY

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_CARD_BACK_CHANGE
	jne	callSuper
	push	ax, cx, es
	mov	bx, bp			; bx = NotifyCardBackChange
	call	MemLock
	mov	es, ax
	push	es:[NCBC_cardWidth]
	push	es:[NCBC_cardHeight]
	call	MemUnlock
	mov	ax, TEMP_CBS_CARD_INFO	; don't save to state
	mov	cx, size TempCBSCardInfo
	call	ObjVarAddData		; ds:bx = TempCBSCardInfo
	pop	ds:[bx].TCBSCI_cardHeight
	pop	ds:[bx].TCBSCI_cardWidth
	pop	ax, cx, es
callSuper:
	mov	di, offset CardBackSelectorClass
	GOTO	ObjCallSuperNoLock
CBSNotifyWithDataBlock	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CBSGenControlTweakDuplicatedUI --
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
					for CardBackSelectorClass

DESCRIPTION:	HACK: Set initial card back selector list size with info
		saved at notification time

PASS:
	*ds:si - instance data
	es - segment of CardBackSelectorClass

	ax - The message

	none

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/94		Initial version

------------------------------------------------------------------------------@
CBSGenControlTweakDuplicatedUI	method dynamic CardBackSelectorClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI

	push	cx			; save duplicated block
	mov	di, offset CardBackSelectorClass
	call	ObjCallSuperNoLock
	pop	dx			; dx = duplicated block

	mov	ax, TEMP_CBS_CARD_INFO
	mov	cx, size TempCBSCardInfo
	call	ObjVarFindData		; ds:bx = TempCBSCardInfo, if found
	jnc	done			; not found
	mov	di, ds:[bx].TCBSCI_cardWidth
	mov	ax, ds:[bx].TCBSCI_cardHeight
	mov	bx, dx			; bx = duplicated block
	call	SetCardBackListSize
done:
	ret
CBSGenControlTweakDuplicatedUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CBSUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for CardBackSelectorClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of CardBackSelectorClass

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
CBSUpdateUI	method dynamic CardBackSelectorClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	cx, dx, bp
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	ax, es:[NCBC_cardWidth]
	mov	ds:[di].CBSI_cardWidth, ax
	push	ax					;save width
	mov	ax, es:[NCBC_cardHeight]
	mov	ds:[di].CBSI_cardHeight, ax
	push	ax					;save height

	mov	bp, es:[NCBC_vmFile]
	mov	ax, es:[NCBC_mapBlock]

	mov	ds:[di].CBSI_vmFile, bp
	mov	ds:[di].CBSI_mapBlock, ax

	call	MemUnlock

	mov	bx, bp
	call	VMLock
	mov	es, ax
	mov	cx, es:[DMS_numBacks]
	call	VMUnlock
	
	call	GetChildBlockAndFeatures
	test	ax, mask CBSF_CARD_BACK_LIST

	pop	ax					;ax <- card height
	pop	di					;di <- card width
	jz	done
	
	call	SetCardBackListSize

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
CBSUpdateUI	endm

;
; pass:
;	ds = CBS segment
;	ax = card height
;	di = card width
;	bx = CBS child block
;
SetCardBackListSize	proc	near
	mov	dx, size SetSizeArgs
	sub	sp, dx
	mov	bp, sp

	;
	;  A little fudge here, and a little fudge there...
	;

	add	di, 8	; edwdig - was 4, increased for padding space
	add	ax, 16	; edwdig - increase the height	

	shl	di
	shl	di					;di <- width * 4
	mov	ss:[bp].SSA_width, di
	mov	ss:[bp].SSA_height, ax
	mov	ss:[bp].SSA_count, 4
	mov	ss:[bp].SSA_updateMode, VUM_MANUAL
	mov	ax, MSG_GEN_SET_FIXED_SIZE
	mov	si, offset CardBackList
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx
	ret
SetCardBackListSize	endp

GetChildBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
GetChildBlockAndFeatures	endp

CardBackDynamicListGetItemClass	method	dynamic CardBackDynamicListClass, MSG_GEN_DYNAMIC_LIST_GET_ITEM_CLASS
	mov	cx, segment CardBackListItemClass
	mov	dx, offset CardBackListItemClass
	ret
CardBackDynamicListGetItemClass	endm

CardBackListItemVisDraw	method	dynamic	CardBackListItemClass, MSG_VIS_DRAW
	push	bp
	mov	di, offset CardBackListItemClass
	call	ObjCallSuperNoLock
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	GenCallParent		; ax = selection
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GII_identifier
	pop	di
	cmp	ax, cx
	je	done			; selected, leave cursor
	; else, erase cursor
	mov	ax, C_GREEN
	call	GrSetLineColor
	call	VisGetBounds		; match SPUI code for cursor bounds
	dec	cx
	dec	dx
	call	GrDrawRect		; erase cursor greebles
done:
	ret
CardBackListItemVisDraw	endm

CardBackSelectorCode ends
