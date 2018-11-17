COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiGuideControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	RulerGuideControlClass		Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement RulerGuideControlClass

	$Id: uiRulerGuideControl.asm,v 1.1 97/04/07 10:43:00 newdeal Exp $

------------------------------------------------------------------------------@

;---------------------------------------------------

RulerUICode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGuideControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for RulerGuideControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of RulerGuideControlClass

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
RulerGuideControlGetInfo	method dynamic	RulerGuideControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset RGuideC_dupInfo
	call	CopyDupInfoCommon
	ret

RulerGuideControlGetInfo	endm

RGuideC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	RGuideC_IniFileKey,			; GCBI_initFileKey
	RGuideC_gcnList,			; GCBI_gcnList
	length RGuideC_gcnList,		; GCBI_gcnCount
	RGuideC_notifyTypeList,		; GCBI_notificationList
	length RGuideC_notifyTypeList,	; GCBI_notificationCount
	RulerGuideControlName,		; GCBI_controllerName

	handle RulerGuideControlUI,		; GCBI_dupBlock
	RGuideC_childList,			; GCBI_childList
	length RGuideC_childList,		; GCBI_childCount
	RGuideC_featuresList,		; GCBI_featuresList
	length RGuideC_featuresList,		; GCBI_featuresCount
	RULER_GUIDE_CONTROL_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	RGuideC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	segment resource
endif

RGuideC_helpContext	char	"dbRulerGuide", 0

RGuideC_IniFileKey	char	"guides", 0

RGuideC_gcnList	GCNListType \
<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE>,
<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_RULER_GUIDE_CHANGE>

RGuideC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_RULER_TYPE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_RULER_GUIDE_CHANGE>

;---

RGuideC_childList	GenControlChildInfo	\
	<offset HorVGuidelineList, mask RGCF_HV, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GuideList, mask RGCF_LIST, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GuidePositionValue, mask RGCF_POSITION,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeleteGuideTrigger, mask RGCF_DELETE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

RGuideC_featuresList	GenControlFeaturesInfo	\
	<offset DeleteGuideTrigger, DeleteGuideName, 0>,
	<offset GuidePositionValue, GuidePositionName, 0>,
	<offset GuideList, GuideListName, 0>,
	<offset HorVGuidelineList, GuideHorVListName, 0>

if FULL_EXECUTE_IN_PLACE
RulerControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GuideControlSelectGuide -- MSG_RGC_SELECT_GUIDE for GuideControlClass

DESCRIPTION:	Handle a guide being selected

PASS:
	*ds:si - instance data
	es - segment of GuideControlClass

	ax - The message

	cx - current selection
	dx - GenItemGroupStateFlags
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
	Tony	4/ 9/92		Initial version

------------------------------------------------------------------------------@
RulerGuideControlSelectGuide	method dynamic	RulerGuideControlClass,
				MSG_RGC_SELECT_GUIDE
	.enter

	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass

	jcxz	deselect

	mov_tr	ax, cx
	dec	ax
	call	GetGuideLocation

	pushdwf	dxaxcx
	mov	bp, sp

	mov	ax, MSG_VIS_RULER_SELECT_HORIZONTAL_GUIDE
	jnc	haveMsgCommon
	mov	ax, MSG_VIS_RULER_SELECT_VERTICAL_GUIDE

haveMsgCommon:
	mov	dx, size DWFixed
	call	GenControlSendToOutputStack
	add	sp, size DWFixed

done:
	.leave
	ret

deselect:
	mov	ax, MSG_VIS_RULER_DESELECT_ALL_HORIZONTAL_GUIDES
	call	CheckHorizOrVert
	jnc	haveDeselect
	mov	ax, MSG_VIS_RULER_DESELECT_ALL_VERTICAL_GUIDES
haveDeselect:
	call	GenControlSendToOutputRegs
	jmp	done
RulerGuideControlSelectGuide	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GuideControlDeleteGuide -- MSG_RGC_DELETE_GUIDE for GuideControlClass

DESCRIPTION:	Handle a guide being deleteed

PASS:
	*ds:si - instance data
	es - segment of GuideControlClass

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
	Tony	4/ 9/92		Initial version

------------------------------------------------------------------------------@
RulerGuideControlDeleteGuide	method dynamic	RulerGuideControlClass,
				MSG_RGC_DELETE_GUIDE
	.enter

	call	GetSelectedGuide
	cmp	ax, CA_NULL_ELEMENT
	je	done
	call	GetGuideLocation

	pushdwf	dxaxcx
	mov	bp, sp

	mov	ax, MSG_VIS_RULER_DELETE_HORIZONTAL_GUIDE
	jnc	haveMsgCommon
	mov	ax, MSG_VIS_RULER_DELETE_VERTICAL_GUIDE

haveMsgCommon:
	mov	dx, size DWFixed
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlSendToOutputStack
	add	sp, size DWFixed

done:
	.leave
	ret
RulerGuideControlDeleteGuide	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGuideControlQueryGuide -- MSG_RGC_QUERY_GUIDE for RulerGuideControlClass

DESCRIPTION:	Return list item monikers

PASS:
	*ds:si - instance data
	es - segment of RulerGuideControlClass

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
RulerGuideControlQueryGuide	method dynamic	RulerGuideControlClass, MSG_RGC_QUERY_GUIDE
	mov_tr	ax, bp
buf	local	LOCAL_DISTANCE_BUFFER_SIZE dup (char)
params	local	ReplaceItemMonikerFrame
	.enter

	pushdw	cxdx
	mov	params.RIMF_item, ax

	; if this is item zero then pass "new guide"

	tst	ax
	jnz	notNewGuide

	mov	bx, handle NewGuideString
	call	MemLock
	mov	es, ax
assume es:nothing
	mov	di, es:[NewGuideString]
assume es:dgroup
	clr	cx				; null-terminated
	jmp	common

notNewGuide:
	dec	ax
	call	GetGuideLocation		;dxaxcx <- guide location

	pushwwf	axcx

	push	bp
	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication
	pop	bp
	mov	ch, al				;ah = measurement type

	mov	di, ds:[si]
	add	di, ds:[di].RulerGuideControl_offset
	mov	cl, ds:[di].RGCI_rulerType
	call	ConvertVisRulerTypeToDistanceUnit

	segmov	es, ss
	lea	di, buf				;es:di = buffer
	clr	bx
	popwwf	dxax
	call	LocalDistanceToAscii		;cx = length
common:
	mov	params.RIMF_length, cx
	movdw	params.RIMF_source, esdi
	mov	params.RIMF_sourceType, VMST_FPTR
	mov	params.RIMF_dataType, VMDT_TEXT
	mov	params.RIMF_itemFlags, 0

	popdw	axsi				;axsi = list
	push	bx, bp				;save handle
	mov_tr	bx, ax
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	dx, size ReplaceItemMonikerFrame
	lea	bp, params
	mov	di, mask MF_STACK
	call	ObjMessage
	pop	bx, bp

	tst	bx
	jz	noUnlock
	call	MemUnlock
noUnlock:

	.leave
	ret
RulerGuideControlQueryGuide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGuideLocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - rulerGuideControl
		ax - guide index

Return:		dx:ax.cx - Guide location
		carry set as from CheckHorizOrVert

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGuideLocation	proc	near
	class	RulerGuideControlClass
	uses	bx, di, si, ds
	.enter

	mov_tr	cx, ax				;cx <- element
	mov	bx, ds:[si]
	add	bx, ds:[bx].RulerGuideControl_offset
	mov	bx, ds:[bx].RGCI_dataBlock
	mov	di, offset VRNGCBH_vertGuideArray
	call	CheckHorizOrVert
	pushf
	jnc	haveOffset
	mov	di, offset VRNGCBH_horizGuideArray
haveOffset:
	call	MemLock
	mov	ds, ax
	mov_tr	ax, cx				;ax <- element #
	mov	si, ds:[di]				;ds:si <- chunk
	tst	si
	jz	outOfBounds
	call	ChunkArrayElementToPtr
	jc	outOfBounds

	movdwf	dxaxcx, ds:[di].Guide_location

unlockBlock:
	call	MemUnlock
	popf

	.leave
	ret

outOfBounds:
	clr	ax, cx, dx
	jmp	unlockBlock
GetGuideLocation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNumGuides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - rulerGuideControl

Return:		ax - # of guide in the array

		carry set as from CheckHorizOrVert

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNumGuides	proc	near
	class	RulerGuideControlClass
	uses	bx, cx, di, si, ds
	.enter


	mov	bx, ds:[si]
	add	bx, ds:[bx].RulerGuideControl_offset
	mov	bx, ds:[bx].RGCI_dataBlock
	mov	di, offset VRNGCBH_vertGuideArray
	call	CheckHorizOrVert
	pushf
	jnc	haveOffset
	mov	di, offset VRNGCBH_horizGuideArray
haveOffset:
	call	MemLock
	mov	ds, ax
	mov_tr	ax, cx				;ax <- element #
	mov	cx, ds:[di]				;si <- chunk handle
	jcxz	noArray	
	mov	si, cx
	call	ChunkArrayGetCount

noArray:
	mov_tr	ax, cx
	call	MemUnlock
	popf

	.leave
	ret
GetNumGuides	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - RulerGuideControl

Return:		ax - index of selected guide
		carry set as from CheckHorizOrVert

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectedGuide	proc	near
	class	RulerGuideControlClass
	uses	bx, di, si, ds
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].RulerGuideControl_offset
	mov	bx, ds:[bx].RGCI_dataBlock
	mov	di, offset VRNGCBH_vertGuideArray
	call	CheckHorizOrVert
	pushf
	jnc	haveOffset
	mov	di, offset VRNGCBH_horizGuideArray
haveOffset:
	call	MemLock
	mov	ds, ax
	mov	si, ds:[di]				;si <- chunk handle
	mov	ax, CA_NULL_ELEMENT
	tst	si
	jz	popfDone
	mov	si, ds:[si]				;ds:si <- ChunkArray
	mov	ax, ds:[si].GCAH_selectedElement
	call	MemUnlock
popfDone:
	popf

	.leave
	ret
GetSelectedGuide	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHorizOrVert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - RulerGuideControl

Return:		carry set if we're dealing with horizontal guidelines

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHorizOrVert	proc	near
	uses	ax, bx, cx, dx, bp, si, di
	.enter

	call	GetChildBlock
	mov	si, offset HorVGuidelineList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	tst_clc	ax			;vertical?
	jz	done

	stc

done:
	.leave
	ret
CheckHorizOrVert	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGuideControlApply -- MSG_GEN_APPLY for RulerGuideControlClass

DESCRIPTION:	Apply changes

PASS:
	*ds:si - instance data
	es - segment of RulerGuideControlClass

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
	jon	23 sept 92	initial uncommented revision
------------------------------------------------------------------------------@
RulerGuideControlApply	method dynamic	RulerGuideControlClass, MSG_GEN_APPLY

	uses	cx, dx, bp
	.enter

	call	GetChildBlock

	push	si
	
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	si, offset GuidePositionValue
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	pushwwf	dxcx

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset GuideList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	popwwf	bxdi
	pop	si

	tst	ax
	jz	afterDelete
	dec	ax
	call	GetGuideLocation

	tst	dx
	jnz	doDelete
	cmp	bx, ax
	jne	doDelete
	cmp	di, cx
	je	done

doDelete:
	mov_tr	bp, ax
	mov	ax, MSG_VIS_RULER_DELETE_HORIZONTAL_GUIDE
	call	CheckHorizOrVert
	jnc	deleteGuide
	mov	ax, MSG_VIS_RULER_DELETE_VERTICAL_GUIDE

deleteGuide:
	pushwwf	bxdi

	push	dx
	push	bp
	push	cx
	mov	bp, sp
	mov	dx, size DWFixed
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionStack
	add	sp, size DWFixed
	popwwf	bxdi

afterDelete:
	

	mov_tr	ax, bx
	cwd

	push	dx
	push	ax
	push	di
	mov	bp, sp

	mov	ax, MSG_VIS_RULER_ADD_HORIZONTAL_GUIDE
	call	CheckHorizOrVert
	jnc	addGuide
	mov	ax, MSG_VIS_RULER_ADD_VERTICAL_GUIDE
addGuide:
	mov	dx, size DWFixed
	mov	bx, segment VisRulerClass
	mov	di, offset VisRulerClass
	call	GenControlOutputActionStack
	add	sp, size DWFixed

done:
	.leave
	ret
RulerGuideControlApply	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerGuideControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for RulerGuideControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of RulerGuideControlClass

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
RulerGuideControlUpdateUI	method dynamic RulerGuideControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	.enter

	cmp	ss:[bp].GCUUIP_changeType, GWNT_RULER_TYPE_CHANGE
	jne	notType

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	cl, es:[RTNB_type]
	call	MemUnlock

	mov	ds:[di].RGCI_rulerType, cl
	call	ConvertVisRulerTypeToDisplayFormat

	push	si
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GuidePositionValue
	mov	ax, MSG_GEN_VALUE_SET_DISPLAY_FORMAT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jmp	done

notType:
	;
	;  Free "old" block
	;
	mov	bx, ds:[di].RGCI_dataBlock
	tst	bx
	jz	storeNew

	call	MemDecRefCount

storeNew:
	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemIncRefCount
	mov	ds:[di].RGCI_dataBlock, bx

	mov	ax, MSG_RGC_UPDATE_UI
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
RulerGuideControlUpdateUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RGCUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for RulerGuideControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of RulerGuideControlClass

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
RGCUpdateUI	method dynamic RulerGuideControlClass,
				MSG_RGC_UPDATE_UI
	uses	cx, dx, bp
	.enter

	call	GetChildBlock

	call	GetNumGuides
	mov_tr	cx, ax
	inc	cx				;plus one for "new guide"
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	push	si
	mov	si, offset GuideList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	call	GetSelectedGuide
	inc	ax
	mov_tr	cx, ax
	clr	dx
	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset GuideList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_MAKE_APPLYABLE
	jcxz	5$
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
5$:
	push	cx
	call	ObjCallInstanceNoLock
	pop	cx

	jcxz	afterValue

	push	cx, si

	mov_tr	ax, cx
	dec	ax
	call	GetGuideLocation

	mov_tr	dx, ax
	mov	si, offset GuidePositionValue
	clr	bp
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	cx, si

afterValue:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	10$
	mov	ax, MSG_GEN_SET_ENABLED
10$:
	mov	dl, VUM_NOW
	mov	si, offset DeleteGuideTrigger
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
RGCUpdateUI	endm

RulerUICode ends
