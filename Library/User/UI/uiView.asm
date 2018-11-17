COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		genEdit.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenViewControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement GenViewControlClass

	$Id: uiView.asm,v 1.1 97/04/07 11:47:04 newdeal Exp $

------------------------------------------------------------------------------@

;---------------------------------------------------

UserClassStructures	segment resource

	GenViewControlClass		;declare the class record

UserClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

ControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GenViewControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
GenViewControlGetInfo	method dynamic	GenViewControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GVC_dupInfo
	GOTO	CopyDupInfoCommon

GenViewControlGetInfo	endm

GVC_dupInfo	GenControlBuildInfo	<
					; GCBI_flags
	mask GCBF_IS_ON_ACTIVE_LIST or mask GCBF_ALWAYS_ON_GCN_LIST,
	GVC_IniFileKey,			; GCBI_initFileKey
	GVC_gcnList,			; GCBI_gcnList
	length GVC_gcnList,		; GCBI_gcnCount
	GVC_notifyTypeList,		; GCBI_notificationList
	length GVC_notifyTypeList,	; GCBI_notificationCount
	GVCName,			; GCBI_controllerName

	handle GenViewControlUI,	; GCBI_dupBlock
	GVC_childList,			; GCBI_childList
	length GVC_childList,		; GCBI_childCount
	GVC_featuresList,		; GCBI_featuresList
	length GVC_featuresList,	; GCBI_featuresCount
	GVC_DEFAULT_FEATURES,		; GCBI_features

	handle GenViewControlToolboxUI,	; GCBI_toolBlock
	GVC_toolList,			; GCBI_toolList
	length GVC_toolList,		; GCBI_toolCount
	GVC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GVC_toolFeaturesList,	; GCBI_toolFeaturesCount
	GVC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif

GVC_IniFileKey	char	"viewControl", 0

GVC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_VIEW_STATE_CHANGE>

GVC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_VIEW_STATE_CHANGE>

;---

GVC_childList	GenControlChildInfo	\
	<offset ZoomOutTrigger, mask GVCF_ZOOM_OUT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ZoomInTrigger, mask GVCF_ZOOM_IN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset MainScaleList, mask GVCF_MAIN_100 or \
			       mask GVCF_MAIN_SCALE_TO_FIT, 0>,
	<offset StandardScaleSubMenu, mask GVCF_REDUCE or mask GVCF_ENLARGE \
			   or mask GVCF_BIG_ENLARGE \
			   or mask GVCF_SCALE_TO_FIT \
			   or mask GVCF_CUSTOM_SCALE, 0>,
	<offset OptionsSubMenu, mask GVCF_ADJUST_ASPECT_RATIO or \
			       mask GVCF_APPLY_TO_ALL or \
			       mask GVCF_SHOW_HORIZONTAL or \
			       mask GVCF_SHOW_VERTICAL, 0>,
	<offset RedrawSubGroup, mask GVCF_REDRAW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GVC_featuresList	GenControlFeaturesInfo	\
	<offset RedrawTrigger, RedrawName>,
	<offset CustomScaleBox, CustomScaleName>,
	<offset ShowVerticalEntry, ShowVerticalName>,
	<offset ShowHorizontalEntry, ShowHorizontalName>,
	<offset ApplyToAllEntry, ApplyToAllName>,
	<offset AdjustForAspectRatioEntry, AdjustForAspectRatioName>,
	<offset ScaleToFitEntry, ScaleToFitName>,
	<offset Zoom300Entry, BigEnlargeName>,
	<offset Zoom125Entry, EnlargeName>,
	<offset Zoom100Entry, Zoom100Name>,
	<offset Zoom25Entry, ReduceName>,
	<offset ZoomOutTrigger, ZoomOutName>,
	<offset ZoomInTrigger, ZoomInName>,
	<offset MainScaleToFitEntry, ScaleToFitName>,
	<offset Main100Entry, Zoom100Name>

;---

GVC_toolList	GenControlChildInfo	\
	<offset ScaleToolList, mask GVCTF_100 or mask GVCTF_SCALE_TO_FIT, 0>,
	<offset ZoomInToolTrigger, mask GVCTF_ZOOM_IN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ZoomOutToolTrigger, mask GVCTF_ZOOM_OUT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset RedrawToolTrigger, mask GVCTF_REDRAW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PageLeftToolTrigger, mask GVCTF_PAGE_LEFT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PageRightToolTrigger, mask GVCTF_PAGE_RIGHT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PageUpToolTrigger, mask GVCTF_PAGE_UP,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PageDownToolTrigger, mask GVCTF_PAGE_DOWN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ViewAttrsToolList, mask GVCTF_ADJUST_ASPECT_RATIO or \
			       mask GVCTF_APPLY_TO_ALL or \
			       mask GVCTF_SHOW_HORIZONTAL or \
			       mask GVCTF_SHOW_VERTICAL, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GVC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset ShowVerticalToolEntry, ShowVerticalName>,
	<offset ShowHorizontalToolEntry, ShowHorizontalName>,
	<offset ApplyToAllToolEntry, ApplyToAllName>,
	<offset AdjustForAspectRatioToolEntry, AdjustForAspectRatioName>,
	<offset PageDownToolTrigger, PageDownName>,
	<offset PageUpToolTrigger, PageUpName>,
	<offset PageRightToolTrigger, PageRightName>,
	<offset PageLeftToolTrigger, PageLeftName>,
	<offset RedrawToolTrigger, RedrawName>,
	<offset ZoomOutToolTrigger, ZoomOutName>,
	<offset ZoomInToolTrigger, ZoomInName>,
	<offset ScaleToFitToolEntry, ScaleToFitName>,
	<offset Zoom100ToolEntry, Zoom100Name>

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlAttach -- MSG_META_ATTACH for GenViewControlClass

DESCRIPTION:	Handle ATTACH by sending out data to the GCN list

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
	Tony	8/19/92		Initial version

------------------------------------------------------------------------------@
GenViewControlAttach	method dynamic	GenViewControlClass, MSG_META_ATTACH
	mov	di, offset GenViewControlClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVCI_attrs, mask GVCA_APPLY_TO_ALL
	jz	done
	call	UpdateTargetViewOrGCN
done:
	ret

GenViewControlAttach	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlLoadOptions -- MSG_META_LOAD_OPTIONS for
			GenViewControlClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
GenViewControlLoadOptions	method dynamic	GenViewControlClass,
							MSG_META_LOAD_OPTIONS
category	local	INI_CATEGORY_BUFFER_SIZE dup (char)
	ForceRef category

	.enter

	push	bp

	push	ds:[LMBH_handle]
	push	ax, es, si
	call	LoadInitAttrs
	call	InitFileReadData
	pop	ax, es, si
	pop	bx
	call	MemDerefDS

	mov	di, offset GenViewControlClass
	call	ObjCallSuperNoLock

	pop	bp

	.leave

	ret

GenViewControlLoadOptions	endm

LoadInitAttrs	proc	near
	class	GenViewControlClass
category	local	INI_CATEGORY_BUFFER_SIZE dup (char)
	.enter inherit far

	mov	cx, ss
	lea	dx, category			;cx:dx = buffer
	call	UserGetInitFileCategory

	CheckHack <(offset GVCI_attrs) eq (offset GVCI_scale)+2>
	CheckHack <(size GVCI_scale) eq 2>
	CheckHack <(size GVCI_attrs) eq 2>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	segmov	es, ds
	lea	di, ds:[di].GVCI_scale		;es:di = buffer to read into

	segmov	ds, ss
	lea	si, category			;ds:si = category
	mov	cx, cs
	mov	dx, offset viewControlKey	;cx:dx = key
	mov	bp, 4				;buffer size (two words)
	.leave
	ret
LoadInitAttrs	endp

viewControlKey	char	"viewControlExtra", 0

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlSaveOptions -- MSG_META_SAVE_OPTIONS
						for GenViewControlClass

DESCRIPTION:	Save options to .ini file

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
GenViewControlSaveOptions	method dynamic	GenViewControlClass,
						MSG_META_SAVE_OPTIONS
category	local	INI_CATEGORY_BUFFER_SIZE dup (char)
	ForceRef category
	.enter

	push	ax, si, bp, ds, es
	call	LoadInitAttrs
	call	InitFileWriteData
	pop	ax, si, bp, ds, es

	.leave

	mov	di, offset GenViewControlClass
	GOTO	ObjCallSuperNoLock

GenViewControlSaveOptions	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateTargetViewOrGCN

DESCRIPTION:	Update the target view or the GCN list (depending or whether
		APPLY_TO_ALL mode is in effect)

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenViewControl object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/18/92		Initial version

------------------------------------------------------------------------------@
UpdateTargetViewOrGCN	proc	far
	class	GenViewControlClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GVCI_attrs
	mov	dx, ds:[di].GVCI_scale

	; we just need to send the message to the GCN list.  If the
	; APPLY_TO_ALL bit is set then all views will respond.  If not,
	; only the target view will respond

	mov	ax, MSG_GEN_VIEW_SET_CONTROLLED_ATTRS
	mov	di, mask GCNLSF_SET_STATUS
	FALL_THRU	ToGCNCommon

UpdateTargetViewOrGCN	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ToGCNCommon

DESCRIPTION:	Send a message to the GCN list of controlled views

CALLED BY:	INTERNAL

PASS:
	ax - message
	cx, dx, bp - data
	di - GCNListSendFlags

RETURN:
	none

DESTROYED:
	all

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/18/92		Initial version

------------------------------------------------------------------------------@
ToGCNCommon	proc	far
	push	di
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	ax

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type,
					GAGCNLT_CONTROLLED_GEN_VIEW_OBJECTS
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_META_GCN_LIST_SEND
	call	GenCallApplication
	add	sp, size GCNListMessageParams

	ret

ToGCNCommon	endp

ControlCommon ends

;---

ControlCode segment resource


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlTweakDuplicatedUI --
		MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI for GenViewControlClass

DESCRIPTION:	Tweak Duplicated UI for controller

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message
	cx	- block
	dx	- features

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version
	Doug	1/93		Converted to TWEAK message

------------------------------------------------------------------------------@
GenViewControlTweakDuplicatedUI	method dynamic	GenViewControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI

	; now adjust the range

	mov	ax, dx			;ax = features, bx = child block
	mov	bx, cx

	test	ax, mask GVCF_CUSTOM_SCALE
	jz	noCustomScale

	push	ax
	push	ds:[di].GVCI_maxZoom
	clr	cx
	mov	dx, ds:[di].GVCI_minZoom
	mov	si, offset CustomScaleSpin
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	call	ObjMessageSend
	pop	dx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	call	ObjMessageSend
	pop	ax
noCustomScale:

	; Get the aspect ratio so we can use it when we need it.

	test	ax, mask GVCF_ADJUST_ASPECT_RATIO
	jz	noAdjust
	mov	si, offset AdjustForAspectRatioEntry
	call	SetAdjustCommon
noAdjust:

	ret

GenViewControlTweakDuplicatedUI	endm

;---

SetAdjustCommon	proc	near
	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, GUQT_FIELD
	call	UserCallApplication		; cx:dx = field, bp = window
	mov	di, bp				; di = window
	call	ComputeAspectRatio
	;
	; Now enable or disable the "Correct for Aspect Ratio" option.
	;
	jnz	notSquare
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageSend
notSquare:
	ret

SetAdjustCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlTweakDuplicatedToolboxUI --
		MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI for
		GenViewControlClass

DESCRIPTION:	TweakDuplicated UI for controller

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message
	cx	- block
	dx	- features

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version
	Doug	1/93		Converted to TWEAK message

------------------------------------------------------------------------------@
GenViewControlTweakDuplicatedToolboxUI	method dynamic	GenViewControlClass,
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI

	test	dx, mask GVCTF_ADJUST_ASPECT_RATIO
	jz	noAdjust

	mov	bx, cx
	mov	si, offset AdjustForAspectRatioToolEntry
	call	SetAdjustCommon
noAdjust:

	ret

GenViewControlTweakDuplicatedToolboxUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlSetScale -- MSG_GVC_SET_SCALE
						for GenViewControlClass

DESCRIPTION:	Set the scale factor

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message

	cx - scale factor

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
GenViewControlSetScaleViaList	method dynamic	GenViewControlClass,
						MSG_GVC_SET_SCALE_VIA_LIST
	mov	dx, cx
	FALL_THRU GenViewControlSetScale
GenViewControlSetScaleViaList	endm

;---

	; dx = scale

GenViewControlSetScale	method GenViewControlClass, MSG_GVC_SET_SCALE
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	dx
	jz	20$
	cmp	dx, ds:[di].GVCI_minZoom
	jae	10$
	mov	dx, ds:[di].GVCI_minZoom
10$:
	cmp	dx, ds:[di].GVCI_maxZoom
	jbe	20$
	mov	dx, ds:[di].GVCI_maxZoom
20$:

	; store the new scale factor

	mov	ds:[di].GVCI_scale, dx
	call	UpdateTargetViewOrGCN

;don't log these as changes as it "scares" users -- brianc 2/23/99
;	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
;	call	UserCallApplication
		
	ret

GenViewControlSetScale	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlExtSetAttrs --
		MSG_GEN_VIEW_CONTROL_SET_ATTRS for GenViewControlClass

DESCRIPTION:	External interface for setting attributes

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message

	cx - attributes to set
	dx - attributes to clear

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/18/92		Initial version

------------------------------------------------------------------------------@
GenViewControlExtSetAttrs	method dynamic	GenViewControlClass,
					MSG_GEN_VIEW_CONTROL_SET_ATTRS

	not	dx
	and	ds:[di].GVCI_attrs, dx		;mask out
	or	ds:[di].GVCI_attrs, cx		;mask in
	call	UpdateTargetViewOrGCN
	ret

GenViewControlExtSetAttrs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlSetAttrs -- MSG_GVC_SET_ATTRS
						for GenViewControlClass

DESCRIPTION:	Set the attributes

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message

	cx - attributes
	bp - changed attributes

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
GenViewControlSetAttrs	method dynamic	GenViewControlClass, MSG_GVC_SET_ATTRS

	mov	ds:[di].GVCI_attrs, cx
	push	ds:[LMBH_handle], cx, si, bp
	call	UpdateTargetViewOrGCN
	pop	bx, cx, si, bp
	call	MemDerefDS

	test	bp, mask GVCA_APPLY_TO_ALL
	jz	20$
	mov	dx, cx
	and	dx, mask GVCA_APPLY_TO_ALL
	mov	cx, mask GVCA_APPLY_TO_ALL

	call	GetFeaturesAndChildBlock
	test	ax, mask GVCF_APPLY_TO_ALL
	jz	10$
	push	si
	mov	si, offset ViewAttrsList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	call	ObjMessageSend
	pop	si
10$:

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	test	ds:[bx].TGCI_toolboxFeatures, mask GVCTF_APPLY_TO_ALL
	jz	20$
	mov	bx, ds:[bx].TGCI_toolBlock
	mov	si, offset ViewAttrsToolList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	call	ObjMessageSend
20$:
	ret

GenViewControlSetAttrs	endm

;---

GenViewControlRedraw	method dynamic	GenViewControlClass, MSG_GVC_REDRAW
	mov	ax, MSG_GEN_VIEW_REDRAW_CONTENT
	clr	di
	call	ToGCNCommon
	ret

GenViewControlRedraw	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlPageLeft -- MSG_GVC_PAGE_LEFT for
						GenViewControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
GenViewControlPageLeft	method dynamic	GenViewControlClass, MSG_GVC_PAGE_LEFT
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_LEFT
	FALL_THRU	OutputRegsCommon
GenViewControlPageLeft	endm

;---

OutputRegsCommon	proc	far
	class	GenViewControlClass

	mov	bx, segment GenViewClass
	mov	di, offset GenViewClass
	call	GenControlOutputActionRegs
	ret

OutputRegsCommon	endp

;---

GenViewControlPageRight	method dynamic	GenViewControlClass, MSG_GVC_PAGE_RIGHT
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_RIGHT
	GOTO	OutputRegsCommon
GenViewControlPageRight	endm

;---

GenViewControlPageUp	method dynamic	GenViewControlClass, MSG_GVC_PAGE_UP
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_UP
	GOTO	OutputRegsCommon
GenViewControlPageUp	endm

;---

GenViewControlPageDown	method dynamic	GenViewControlClass, MSG_GVC_PAGE_DOWN
	mov	ax, MSG_GEN_VIEW_SCROLL_PAGE_DOWN
	GOTO	OutputRegsCommon
GenViewControlPageDown	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlZoomIn -- MSG_GVC_ZOOM_IN for GenViewControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
GenViewControlZoomIn	method dynamic	GenViewControlClass, MSG_GVC_ZOOM_IN
	mov	ax, ds:[di].GVCI_scale
	mov	dx, 100
	tst	ax				;in scale to fit always go
	jz	common				;to 100%

	mov	dx, ax
	add	dx, 100				;if more than or eqal to 400%
	cmp	ax, 400				;then go up by 100% (unusual)
	jae	common
	add	dx, 5-100			;if less than or equal 20% then
	cmp	ax, 20				;go down by 5% (unusual)
	jbe	common
	call	LoadScaleTable
theLoop:
	scasw
	ja	theLoop

	; if exact match -> es:[di] = larger scale factor
	; if not exact match -> es:[di-2] = larger scale factor

	mov	dx, es:[di]
	jz	common
	mov	dx, es:[di-2]
common:
	GOTO	GenViewControlSetScale

GenViewControlZoomIn	endm

;---

LoadScaleTable	proc	near	uses ax, bx
	.enter

	segmov	es, cs
	mov	di, offset scaleTable
	mov	ax, ATR_GEN_VIEW_CONTROL_LARGE_ZOOM
	call	ObjVarFindData
	jnc	done
	mov	di, offset largeScaleTable
done:
	.leave
	ret
LoadScaleTable	endp

scaleTable	word	25, 50, 75, 100, 125, 150, 175, 200, 300, 400

largeScaleTable	word	25, 50, 100, 200, 400

;---

GenViewControlZoomOut	method dynamic	GenViewControlClass, MSG_GVC_ZOOM_OUT
	mov	ax, ds:[di].GVCI_scale
	mov	dx, ax
	sub	dx, 5
	cmp	ax, 25
	jbe	common
	sub	dx, 100-5
	cmp	ax, 500
	jae	common
	call	LoadScaleTable
theLoop:
	scasw
	ja	theLoop

	; if exact match -> es:[di-4] = smaller scale factor
	; if not exact match -> es:[di-4] = smaller scale factor

	mov	dx, es:[di-4]
common:
	GOTO	GenViewControlSetScale

GenViewControlZoomOut	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GenViewControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

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
GenViewControlUpdateUI	method dynamic GenViewControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	; if we're in "apply to all" mode then ignore passed attributes

	test	ds:[di].GVCI_attrs, mask GVCA_APPLY_TO_ALL
	jnz	common

	clr	ax				;new attributes
	test	es:NVSC_attrs, mask GVA_ADJUST_FOR_ASPECT_RATIO
	jz	10$
	ornf	ax, mask GVCA_ADJUST_ASPECT_RATIO
10$:
	test	es:NVSC_horizAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	20$				;reverse logic!
	ornf	ax, mask GVCA_SHOW_HORIZONTAL
20$:
	test	es:NVSC_vertAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	30$				;reverse logic!
	ornf	ax, mask GVCA_SHOW_VERTICAL
30$:
	mov	ds:[di].GVCI_attrs, ax

	call	GetOurScaleValue		;ax = our scale value
	mov	ds:[di].GVCI_scale, ax

common:
	push	ds:[di].GVCI_attrs
	push	ds:[di].GVCI_maxZoom
	push	ds:[di].GVCI_minZoom

	; Convert the scale factor to our scale value

	mov	cx, ds:[di].GVCI_scale
	clr	dx				;no indeterminate

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	ax, ss:[bp].GCUUIP_features
	test	ax, mask GVCF_MAIN_100 or mask GVCF_MAIN_SCALE_TO_FIT
	jz	noMainScaleList
	mov	si, offset MainScaleList
	call	SendListSetExcl
noMainScaleList:
	test	ax, mask GVCF_REDUCE or mask GVCF_ENLARGE or \
			mask GVCF_BIG_ENLARGE or mask GVCF_SCALE_TO_FIT
	jz	noStandardScaleList
	mov	si, offset StandardScaleList
	call	SendListSetExcl
noStandardScaleList:

	test	ax, mask GVCF_CUSTOM_SCALE
	jz	noCustomScale
	clr	dx
	cmp	cx, GVCSSF_TO_FIT
	jnz	gotScaleIndeterminate
	inc	dx
gotScaleIndeterminate:
	mov	si, offset CustomScaleSpin
	call	SendRangeSetValue
noCustomScale:

	clr	dx
	test	ss:[bp].GCUUIP_toolboxFeatures,
				mask GVCTF_100 or mask GVCTF_SCALE_TO_FIT
	jz	noScaleToolList
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset ScaleToolList
	call	SendListSetExcl
noScaleToolList:

	; update zoom in and zoom out tool triggers

	pop	ax				;min zoom
	mov	dx, mask GVCF_ZOOM_OUT
	mov	bx, offset ZoomOutTrigger
	mov	di, mask GVCTF_ZOOM_OUT
	mov	si, offset ZoomOutToolTrigger
	call	GVC_EnableOrDisableZoom
	pop	ax				;max zoom
	mov	dx, mask GVCF_ZOOM_IN
	mov	bx, offset ZoomInTrigger
	mov	di, mask GVCTF_ZOOM_IN
	mov	si, offset ZoomInToolTrigger
	call	GVC_EnableOrDisableZoom

	; set attributes list

	pop	cx
	clr	dx
	test	ss:[bp].GCUUIP_features, mask GVCF_ADJUST_ASPECT_RATIO \
			or mask GVCF_APPLY_TO_ALL \
			or mask GVCF_SHOW_HORIZONTAL or mask GVCF_SHOW_VERTICAL
	jz	noAttrList
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset ViewAttrsList
	call	SendListSetViaData
noAttrList:

	mov	bx, ss:[bp].GCUUIP_toolBlock
	test	ss:[bp].GCUUIP_toolboxFeatures,
				mask GVCTF_ADJUST_ASPECT_RATIO \
				or mask GVCTF_APPLY_TO_ALL \
				or mask GVCTF_SHOW_HORIZONTAL \
				or mask GVCTF_SHOW_VERTICAL
	jz	noAttrToolList
	mov	si, offset ViewAttrsToolList
	call	SendListSetViaData
noAttrToolList:

	; update page left

	tstdw	es:NVSC_originRelative.PD_x
	mov	di, mask GVCTF_PAGE_LEFT
	mov	si, offset PageLeftToolTrigger
	call	GVC_EnableOrDisablePage

	; update page right

	movdw	dxax, es:NVSC_originRelative.PD_x
	add	ax, es:NVSC_contentSize.XYS_width
	adc	dx, 0
	cmpdw	dxax, es:NVSC_documentSize.PD_x
	mov	di, mask GVCTF_PAGE_RIGHT
	mov	si, offset PageRightToolTrigger
	call	GVC_EnableOrDisablePage

	; update page up

	tstdw	es:NVSC_originRelative.PD_y
	mov	di, mask GVCTF_PAGE_UP
	mov	si, offset PageUpToolTrigger
	call	GVC_EnableOrDisablePage

	; update page down

	movdw	dxax, es:NVSC_originRelative.PD_y
	add	ax, es:NVSC_contentSize.XYS_height
	adc	dx, 0
	cmpdw	dxax, es:NVSC_documentSize.PD_y
	mov	di, mask GVCTF_PAGE_DOWN
	mov	si, offset PageDownToolTrigger
	call	GVC_EnableOrDisablePage

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

GenViewControlUpdateUI	endm

;---

	;dx = normal flags
	;di = toolbox flags
	;bx = normal obj
	;si = toolbox obj
	;cx = zoom
	;ax = limit value

GVC_EnableOrDisableZoom	proc	near

	test	dx, ss:[bp].GCUUIP_features
	jz	10$
	push	si
	mov	si, bx
	mov	bx, ss:[bp].GCUUIP_childBlock
	call	enableDisableLow
	pop	si
10$:

	test	di, ss:[bp].GCUUIP_toolboxFeatures
	jz	20$
	mov	bx, ss:[bp].GCUUIP_toolBlock
	call	enableDisableLow
20$:
	ret

;---

enableDisableLow:
	push	ax
	push	bx
	mov	bx, MSG_GEN_SET_NOT_ENABLED
	cmp	cx, GVCSSF_TO_FIT
	jnz	notScaleToFit
	test	di, mask GVCTF_ZOOM_OUT			;zoom out is disabled
	jnz	gotMessage				;on "scale to fit"
	jmp	enableIt
notScaleToFit:
	cmp	ax, cx
	jz	gotMessage
enableIt:
	mov	bx, MSG_GEN_SET_ENABLED
gotMessage:
	mov_tr	ax, bx
	pop	bx
	mov	dl, VUM_NOW
	call	ObjMessageSend
	pop	ax
	retn

GVC_EnableOrDisableZoom	endp

;---

	;di = flags
	;bx:si = obj
	;zero flag - set to disable

GVC_EnableOrDisablePage	proc	near
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	gotMessage
	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotMessage:
	test	di, ss:[bp].GCUUIP_toolboxFeatures
	jz	done
	mov	dl, VUM_NOW
	call	ObjMessageSend
done:
	ret

GVC_EnableOrDisablePage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetOurScaleValue

DESCRIPTION:	Convert a PointWWFixed to our scale value

CALLED BY:	INTERNAL

PASS:
	es - NotifyViewStateChange block

RETURN:
	ax - scale value (including scale to fit)

DESTROYED:
	bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
GetOurScaleValue	proc	near	uses di
	.enter

	; check for scale to fit

	mov	ax, GVCSSF_TO_FIT
	test	es:NVSC_attrs, mask GVA_SCALE_TO_FIT
	jnz	done

	; The GenView stores the scale factor as a WWFixed.  We want it
	; as a percentage between 0 and 100.

	movdw	dxcx, es:NVSC_scaleFactor.PF_x
	movdw	bxax, <(100 shl 16)>
	call	GrMulWWFixed
	adddw	dxcx, 0x8000			;round
	mov_tr	ax, dx

done:
	.leave
	ret

GetOurScaleValue	endp

;---

GetFeaturesAndChildBlock	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
GetFeaturesAndChildBlock	endp

;----

	; cx = value, dx = non-zero if indeterminate

SendListSetExcl	proc	near	uses	ax, cx, bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessageSend
	.leave
	ret

SendListSetExcl	endp

;---

SendListSetViaData	proc	near	uses ax, dx, bp
	.enter

	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessageSend

	.leave
	ret
SendListSetViaData	endp

;---

	; dx = non-zero for indeterminate
SendRangeSetValue	proc	near	uses ax, bp
	.enter		;takes value in cx

	mov	bp, dx
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	ObjMessageSend

	.leave
	ret

SendRangeSetValue	endp

;---

	; call ObjMessage with di = 0

ObjMessageSend	proc	near		uses di
	.enter
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
ObjMessageSend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ComputeAspectRatio

DESCRIPTION:	Compute the aspect ratio

CALLED BY:	INTERNAL

PASS:
	di - window handle

RETURN:
	dx.ax - aspect ratio
	zero flag - set if "1 to 1"

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
ComputeAspectRatio	proc	near	uses bx, cx, si, di, bp, ds
	.enter

	; Get the aspect ratio so we can use it when we need it.

	mov	si, WIT_STRATEGY
	call	WinGetInfo			; cx:dx = strategy routine
	
	push	cx				; Pass segment and offset on
	push	dx				;    the stack
	mov	bp, sp				; ss:bp points at routine
	mov	di, DR_VID_INFO
	call	{dword} ss:[bp]			; dx:si = info table
	add	sp, 4				; Restore the stack

	mov	ds, dx				; ds:si = info table

	;
	; Aspect ratio = 1 / (horiz DPI / vert DPI)
	; Compute aspect ratio. Check for the case of square pixel display.
	;
	clr	cx
	mov	dx, ds:[si].VDI_vRes		; dx.cx = v res
	clr	ax
	mov	bx, ds:[si].VDI_hRes		; bx.ax = h res
	cmp	bx, dx
	pushf					; Save "1 to 1" flag
	call	GrUDivWWFixed			; dx.cx = v/h
	mov_tr	ax, cx
	popf					; Restore "1 to 1" flag

	.leave
	ret

ComputeAspectRatio	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenViewControlCommandChangeScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the scale factor based on the command

PASS:		
		*(ds:si) - instance data view control
		ds:[bx] - instance data view control
		ds:[di] - master part of object (if any)
		es - segment of GenViewClass

		cx - ViewCommandType
		dx - data dependent on ViewCommandType

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenViewControlCommandChangeScale	method dynamic GenViewControlClass, 
					MSG_META_VIEW_COMMAND_CHANGE_SCALE
	.enter

	cmp	cx,VCT_ZOOM_IN
	je	zoomIn
	cmp	cx,VCT_ZOOM_OUT
	je	zoomOut
	cmp	cx,VCT_SET_SCALE
	jne	done
	
	mov	ax,MSG_GVC_SET_SCALE

send:
	call	ObjCallInstanceNoLock
done:
	.leave
	ret

zoomIn:
	mov	ax,MSG_GVC_ZOOM_IN
	jmp	send

zoomOut:
	mov	ax,MSG_GVC_ZOOM_OUT
	jmp	send
GenViewControlCommandChangeScale		endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlSetMiniminumScaleFactor --
		MSG_GEN_VIEW_CONTROL_SET_MINIMUM_SCALE_FACTOR for
		GenViewControlClass

DESCRIPTION:	External interface for setting minimum scale factor

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message

	cx - minimum scale factor

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/92		Initial version

------------------------------------------------------------------------------@
GenViewControlSetMinimumScaleFactor	method dynamic	GenViewControlClass,
				MSG_GEN_VIEW_CONTROL_SET_MINIMUM_SCALE_FACTOR

	cmp	ds:[di].GVCI_minZoom, cx	; already set?
	je	done				; yes
	mov	ds:[di].GVCI_minZoom, cx	; else store
	cmp	cx, ds:[di].GVCI_scale		; still valid?
	jbe	update				; yes
	mov	ds:[di].GVCI_scale, cx		; else, store new scale
update:
	call	UpdateForMinMaxChange
done:
	ret

GenViewControlSetMinimumScaleFactor	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GenViewControlSetMaximinumScaleFactor --
		MSG_GEN_VIEW_CONTROL_SET_MAXIMUM_SCALE_FACTOR for
		GenViewControlClass

DESCRIPTION:	External interface for setting maximum scale factor

PASS:
	*ds:si - instance data
	es - segment of GenViewControlClass

	ax - The message

	cx - maximum scale factor

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/92		Initial version

------------------------------------------------------------------------------@
GenViewControlSetMaximumScaleFactor	method dynamic	GenViewControlClass,
				MSG_GEN_VIEW_CONTROL_SET_MAXIMUM_SCALE_FACTOR

	cmp	ds:[di].GVCI_maxZoom, cx	; already set?
	je	done				; yes
	mov	ds:[di].GVCI_maxZoom, cx	; else store
	cmp	cx, ds:[di].GVCI_scale		; still valid?
	jae	update				; yes
	mov	ds:[di].GVCI_scale, cx		; else, store new scale
update:
	call	UpdateForMinMaxChange
done:
	ret

GenViewControlSetMaximumScaleFactor	endm

UpdateForMinMaxChange	proc	near
	class	GenViewControlClass

	call	GetFeaturesAndChildBlock	; bx = child block
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	push	ds:[di].GVCI_maxZoom
	clr	cx
	mov	dx, ds:[di].GVCI_minZoom
	mov	si, offset CustomScaleSpin
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	call	ObjMessageSend
	pop	dx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	call	ObjMessageSend
	pop	si
	call	UpdateTargetViewOrGCN
	ret
UpdateForMinMaxChange	endp

ControlCode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

