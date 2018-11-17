COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiLineSpacingControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	LineSpacingControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement LineSpacingControlClass

	$Id: uiLineSpacing.asm,v 1.1 97/04/07 11:17:23 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	LineSpacingControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

LeadingTypes	etype word
LT_AUTOMATIC		enum LeadingTypes
LT_MANUAL		enum LeadingTypes

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	LineSpacingControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for LineSpacingControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of LineSpacingControlClass

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
LineSpacingControlGetInfo	method dynamic	LineSpacingControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset LASC_dupInfo
	GOTO	CopyDupInfoCommon

LineSpacingControlGetInfo	endm

LASC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	LASC_IniFileKey,		; GCBI_initFileKey
	LASC_gcnList,			; GCBI_gcnList
	length LASC_gcnList,		; GCBI_gcnCount
	LASC_notifyTypeList,		; GCBI_notificationList
	length LASC_notifyTypeList,	; GCBI_notificationCount
	LASCName,			; GCBI_controllerName

	handle LineSpacingControlUI,	; GCBI_dupBlock
	LASC_childList,			; GCBI_childList
	length LASC_childList,		; GCBI_childCount
	LASC_featuresList,		; GCBI_featuresList
	length LASC_featuresList,	; GCBI_featuresCount
	LASC_DEFAULT_FEATURES,		; GCBI_features

	handle LineSpacingControlToolboxUI,	; GCBI_toolBlock
	LASC_toolList,			; GCBI_toolList
	length LASC_toolList,		; GCBI_toolCount
	LASC_toolFeaturesList,		; GCBI_toolFeaturesList
	length LASC_toolFeaturesList,	; GCBI_toolFeaturesCount
	LASC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment resource
endif

LASC_IniFileKey	char	"paraSpacing", 0

LASC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

LASC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

LASC_childList	GenControlChildInfo	\
	<offset LineSpacingList, mask LASCF_SINGLE or
				 mask LASCF_ONE_AND_A_HALF or
				 mask LASCF_DOUBLE or mask LASCF_TRIPLE, 0>,
	<offset LineSpacingDialog, mask LASCF_CUSTOM,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

LASC_featuresList	GenControlFeaturesInfo	\
	<offset LineSpacingDialog, LineSpacingName, 0>,
	<offset TripleSpaceEntry, TripleName, 0>,
	<offset DoubleSpaceEntry, DoubleName, 0>,
	<offset OneAndAHalfSpaceEntry, OneAndAHalfName, 0>,
	<offset SingleSpaceEntry, SingleName, 0>

;---

LASC_toolList	GenControlChildInfo	\
	<offset LineSpacingToolList, mask LASCTF_SINGLE or
				mask LASCTF_ONE_AND_A_HALF or
				mask LASCTF_DOUBLE or mask LASCTF_TRIPLE, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

LASC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset TripleSpaceToolEntry, TripleName, 0>,
	<offset DoubleSpaceToolEntry, DoubleName, 0>,
	<offset OneAndAHalfSpaceToolEntry, OneAndAHalfName, 0>,
	<offset SingleSpaceToolEntry, SingleName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	LineSpacingControlSetLeadingType --
		MSG_LASC_SET_LEADING_TYPE for LineSpacingControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of LineSpacingControlClass

	ax - The message

	cx - LeadingTypes

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
LineSpacingControlSetLeadingType	method dynamic	LineSpacingControlClass,
					MSG_LASC_SET_LEADING_TYPE

	; if "automatic" then set line spacing to 1 and leading indeterminate

	call	GetFeaturesAndChildBlock	;ax = features, bx = child block

	cmp	cx, LT_AUTOMATIC
	jnz	manual

	mov	dx, 1				;indeterminate
	mov	si, offset ManualLeadingDistance
	call	SendRangeSetValue

	mov	cx, 1
	clr	dx
	mov	si, offset LineSpacingBBFixed
	call	SendRangeSetValue
	mov	cx, 1
	mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
	call	ObjMessageSend

	mov	ax, MSG_GEN_SET_ENABLED		;ax = for line spacing spin
	mov	cx, MSG_GEN_SET_NOT_ENABLED	;cx = for manual leading spin

	jmp	common

	; if "manual" then set leading to the point size and line spacing to
	; indeterminate

manual:
	mov	cx, 12				;we can't get the point size...
	clr	dx
	mov	si, offset ManualLeadingDistance
	call	SendRangeSetValue
	mov	cx, 1
	mov	ax, MSG_GEN_VALUE_SET_MODIFIED_STATE
	call	ObjMessageSend

	mov	dx, 1				;indeterminate
	mov	si, offset LineSpacingBBFixed
	call	SendRangeSetValue

	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax = for line spacing spin
	mov	cx, MSG_GEN_SET_ENABLED		;cx = for manual leading spin

common:
	push	cx
	mov	dl, VUM_NOW
	mov	si, offset LineSpacingBBFixed
	call	ObjMessageSend
	pop	ax
	mov	dl, VUM_NOW
	mov	si, offset ManualLeadingDistance
	call	ObjMessageSend
	ret

LineSpacingControlSetLeadingType	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LineSpacingControlSetLineSpacing -- MSG_LASC_SET_LINE_SPACING
						for LineSpacingControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of LineSpacingControlClass

	ax - The message

	cx - line spacing (BBFixed)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
LineSpacingControlSetLineSpacing	method dynamic	LineSpacingControlClass,
					MSG_LASC_SET_LINE_SPACING

	push	cx

	mov	ax, MSG_META_SUSPEND
	call	toOutput

	mov	ax, MSG_VIS_TEXT_SET_LEADING
	clr	cx
	call	SendVisText_AX_CX_Common

	pop	cx				;cx <- BBFixed line spacing

	mov	ax, MSG_VIS_TEXT_SET_LINE_SPACING
	call	SendVisText_AX_CX_Common

	mov	ax, MSG_META_UNSUSPEND
	call	toOutput
	ret

;---

toOutput:
	clrdw	bxdi
	call	GenControlSendToOutputRegs
	retn

LineSpacingControlSetLineSpacing	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LineSpacingControlSetLineSpacingWWFixed --
				MSG_LASC_SET_LINE_SPACING_WW_FIXED
						for LineSpacingControlClass

DESCRIPTION:	Set the line spacing

PASS:
	*ds:si - instance data
	es - segment of LineSpacingControlClass

	ax - The message

	dx.cx - line spacing

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
LineSpacingControlSetLineSpacingWWFixed	method dynamic	LineSpacingControlClass,
					MSG_LASC_SET_LINE_SPACING_WW_FIXED

	; convert to BB fixed

	mov	cl, ch
	mov	ch, dl
	mov	ax, MSG_LASC_SET_LINE_SPACING
	GOTO	ObjCallInstanceNoLock

LineSpacingControlSetLineSpacingWWFixed	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LineSpacingControlSetManualLeading --
		MSG_LASC_SET_MANUAL_LEADING for LineSpacingControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of LineSpacingControlClass

	ax - The message

	cx - leading

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91		Initial version

------------------------------------------------------------------------------@
LineSpacingControlSetManualLeading	method dynamic	LineSpacingControlClass,
					MSG_LASC_SET_MANUAL_LEADING

	; it is overkill to allocate a stack frame, but so what ?

	push	dx

	mov	ax, MSG_VIS_TEXT_SET_LINE_SPACING
	mov	cx, 0x100
	call	SendVisText_AX_CX_Common

	pop	cx				;cx = leading
	shl	cx
	shl	cx
	shl	cx

	mov	ax, MSG_VIS_TEXT_SET_LEADING
	GOTO	SendVisText_AX_CX_Common

LineSpacingControlSetManualLeading	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LineSpacingControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for LineSpacingControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of LineSpacingControlClass

	ax - The message

	ss:bp - GenControlUpdateUILinems

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
LineSpacingControlUpdateUI	method dynamic LineSpacingControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_diffs

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask LASCF_SINGLE or mask LASCF_ONE_AND_A_HALF \
			or mask LASCF_DOUBLE or mask LASCF_TRIPLE
	jz	noLineSpacing
	push	dx
	mov	cx, {word} es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_lineSpacing
	and	dx, mask VTPAF_MULTIPLE_LINE_SPACINGS or \
		    mask VTPAF_MULTIPLE_LEADINGS
	or	dx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_leading
	mov	si, offset LineSpacingList
	call	SendListSetExcl
	pop	dx
noLineSpacing:

	; set leading

	test	ax, mask LASCF_CUSTOM
	jz	noLeading

	; set correct group enabled

	push	dx
						;assume automatic
	mov	ax, MSG_GEN_SET_ENABLED		;ax = for line spacing spin
	mov	cx, MSG_GEN_SET_NOT_ENABLED	;cx = for manual leading spin
	cmp	es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_leading, 0
	mov	di, LT_AUTOMATIC		;exclusive
	jz	groupCommon
						;must be manual
	xchg	ax, cx
	mov	di, LT_MANUAL			;exclusive

groupCommon:
	push	cx
	mov	dl, VUM_NOW
	mov	si, offset LineSpacingBBFixed
	call	ObjMessageSend
	pop	ax
	mov	dl, VUM_NOW
	mov	si, offset ManualLeadingDistance
	call	ObjMessageSend

	mov	cx, di
	clr	dx
	mov	si, offset LeadingList
	call	SendListSetExcl
	pop	dx

	; update correct sub-group

	push	dx
	cmp	cx, LT_AUTOMATIC
	jnz	manual

	; update line spacing spin

	mov	cx, {word} es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_lineSpacing
	and	dx, mask VTPAF_MULTIPLE_LINE_SPACINGS
	mov	si, offset LineSpacingBBFixed
	call	SendRangeSetBBFixedValue

	mov	dx, 1				;indeterminate
	mov	si, offset ManualLeadingDistance
	call	SendRangeSetValueTimes8
	jmp	common2

	; update manual leading spin

manual:

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_leading
	and	dx, mask VTPAF_MULTIPLE_LEADINGS
	mov	si, offset ManualLeadingDistance
	call	SendRangeSetValueTimes8

	mov	dx, 1				;indeterminate
	mov	si, offset LineSpacingBBFixed
	call	SendRangeSetBBFixedValue

common2:
	pop	dx

noLeading:

	test	ss:[bp].GCUUIP_toolboxFeatures,
			mask LASCTF_SINGLE or mask LASCTF_ONE_AND_A_HALF \
			or mask LASCTF_DOUBLE or mask LASCTF_TRIPLE
	jz	noToolLineSpacing
	mov	cx, {word} es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_lineSpacing
	and	dx, mask VTPAF_MULTIPLE_LINE_SPACINGS or \
		    mask VTPAF_MULTIPLE_LEADINGS
	or	dx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_leading
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset LineSpacingToolList
	call	SendListSetExcl
noToolLineSpacing:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

LineSpacingControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
