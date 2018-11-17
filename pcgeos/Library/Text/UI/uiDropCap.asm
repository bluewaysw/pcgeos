COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiDropCapControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	DropCapControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement DropCapControlClass

	$Id: uiDropCap.asm,v 1.1 97/04/07 11:16:48 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	DropCapControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DropCapControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for DropCapControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of DropCapControlClass

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
DropCapControlGetInfo	method dynamic	DropCapControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset DCC_dupInfo

	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret

DropCapControlGetInfo	endm

DCC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	DCC_IniFileKey,			; GCBI_initFileKey
	DCC_gcnList,			; GCBI_gcnList
	length DCC_gcnList,		; GCBI_gcnCount
	DCC_notifyTypeList,		; GCBI_notificationList
	length DCC_notifyTypeList,	; GCBI_notificationCount
	DCCName,			; GCBI_controllerName

	handle DropCapControlUI,	; GCBI_dupBlock
	DCC_childList,			; GCBI_childList
	length DCC_childList,		; GCBI_childCount
	DCC_featuresList,		; GCBI_featuresList
	length DCC_featuresList,	; GCBI_featuresCount
	DCC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	DCC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	DCC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

DCC_helpContext	char	"dbDropCap", 0


DCC_IniFileKey	char	"dropCap", 0

DCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

DCC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

DCC_childList	GenControlChildInfo	\
	<offset DropCapGroup, mask DCCF_DROP_CAP,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

DCC_featuresList	GenControlFeaturesInfo	\
	<offset DropCapGroup, DropCapName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	DropCapControlSetDropCap -- MSG_DCC_SET_DROP_CAP
						for DropCapControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of DropCapControlClass

	ax - The message

	cx - spacing

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
SET
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
DropCapControlSetDropCap	method DropCapControlClass, MSG_DCC_SET_DROP_CAP
	GOTO	SetParaAttrCommon
DropCapControlSetDropCap	endm

DropCapControlUserChangedDropCap	method DropCapControlClass, \
					MSG_DCC_USER_CHANGED_DROP_CAP
	call	GetFeaturesAndChildBlock
	clr	dx
	call	EnableDisableDrop
	ret
DropCapControlUserChangedDropCap	endm

	; cx = bits to set, bp = bits changed

SetParaAttrCommon	proc	far
	mov	dx, cx				;cx & dx = selectedBooleans

	;Bits to clear = ~selectedBooleans & changedBooleans
	not	dx
	and	dx, bp

	;Bits to set = selectedBooleans & changedBooleans
	and	cx, bp

	; cx = bits to set, dx = bits to clear

	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTRIBUTES
	call	SendMeta_AX_DXCX_Common
	ret

SetParaAttrCommon	endp

	; bx = block, cx = flag

EnableDisableDrop	proc	near
	mov	si, offset DropCapCustomGroup
	FALL_THRU	EnableDisableCommon
EnableDisableDrop	endp

EnableDisableCommon	proc	near	uses dx
	.enter

	tst	dx
	jnz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	common
10$:
	mov	ax, MSG_GEN_SET_ENABLED
common:
	mov	dl, VUM_NOW
	call	ObjMessageSend

	.leave
	ret

EnableDisableCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	DropCapControlSetDropChars -- MSG_DCC_SET_DROP_CHARS
						for DropCapControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of DropCapControlClass
	ax - The message

	dx - integer value to set

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/16/91		Initial version

------------------------------------------------------------------------------@
DropCapControlSetDropChars	method dynamic	DropCapControlClass,
						MSG_DCC_SET_DROP_CHARS

	mov	al, offset VTDCI_CHAR_COUNT
	GOTO	DropCommon

DropCapControlSetDropChars	endm

;---

DropCapControlSetDropLines	method dynamic	DropCapControlClass,
						MSG_DCC_SET_DROP_LINES

	mov	al, offset VTDCI_LINE_COUNT
	GOTO	DropCommon

DropCapControlSetDropLines	endm

;---

DropCapControlSetDropPosition	method dynamic	DropCapControlClass,
						MSG_DCC_SET_DROP_POSITION

	mov	al, offset VTDCI_POSITION
	FALL_THRU	DropCommon

DropCapControlSetDropPosition	endm

;---

DropCommon	proc	far
	mov	cx, dx
	dec	cx
	xchg	ax, cx			;ax = val, cx = count
	shl	ax, cl
	mov_tr	bx, ax			;bx = mask
	mov	ax, 0x000f
	shl	ax, cl
	mov_tr	dx, ax			;dx = bits to clear
	mov	cx, bx

	mov	ax, MSG_VIS_TEXT_SET_DROP_CAP_PARAMS
	GOTO	SendVisText_AX_DXCX_Common

DropCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	DropCapControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for DropCapControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of DropCapControlClass

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
DropCapControlUpdateUI	method dynamic DropCapControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	test	ss:[bp].GCUUIP_features, mask DCCF_DROP_CAP
	jz	noDropCap

	; set list

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_attributes
	and	cx, mask VTPAA_DROP_CAP
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_attributes
	and	dx, mask VTPAA_DROP_CAP
	mov	si, offset DropCapList
	call	SendListSetExcl

	; enable or disable ranges

	call	EnableDisableDrop

	; set ranges

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_dropCapInfo
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_dropCapInfo

	mov	al, offset VTDCI_CHAR_COUNT
	mov	si, offset DropCapCharsRange
	call	SetNibbleRange

	mov	al, offset VTDCI_LINE_COUNT
	mov	si, offset DropCapLinesRange
	call	SetNibbleRange

	mov	al, offset VTDCI_POSITION
	mov	si, offset DropCapPositionRange
	call	SetNibbleRange

noDropCap:
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

DropCapControlUpdateUI	endm

;---

SetNibbleRange	proc	near	uses cx, dx
	.enter

	xchg	ax, cx				;ax = value
	shr	ax, cl
	and	ax, 0x000f
	xchg	ax, dx				;dx = value, ax = mask
	shr	ax, cl
	and	ax, 0x000f
	mov	cx, dx
	mov_tr	dx, ax

	inc	cx
	call	SendRangeSetValue

	.leave
	ret
SetNibbleRange	endp

TextControlCode ends

endif		; not NO_CONTROLLERS
