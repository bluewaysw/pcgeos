COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiHyphenationControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	HyphenationControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement HyphenationControlClass

	$Id: uiHyphenation.asm,v 1.1 97/04/07 11:17:04 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	HyphenationControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	HyphenationControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for HyphenationControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of HyphenationControlClass

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
HyphenationControlGetInfo	method dynamic	HyphenationControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset HC_dupInfo
	GOTO	CopyDupInfoCommon

HyphenationControlGetInfo	endm

HC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	HC_IniFileKey,			; GCBI_initFileKey
	HC_gcnList,			; GCBI_gcnList
	length HC_gcnList,		; GCBI_gcnCount
	HC_notifyTypeList,		; GCBI_notificationList
	length HC_notifyTypeList,	; GCBI_notificationCount
	HCName,				; GCBI_controllerName

	handle HyphenationControlUI,	; GCBI_dupBlock
	HC_childList,			; GCBI_childList
	length HC_childList,		; GCBI_childCount
	HC_featuresList,		; GCBI_featuresList
	length HC_featuresList,		; GCBI_featuresCount
	HC_DEFAULT_FEATURES,		; GCBI_features

	handle HyphenationControlToolboxUI, ; GCBI_toolBlock
	HC_toolList,			; GCBI_toolList
	length HC_toolList,		; GCBI_toolCount
	HC_toolFeaturesList,		; GCBI_toolFeaturesList
	length HC_toolFeaturesList,	; GCBI_toolFeaturesCount
	HC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	HC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

HC_helpContext	char	"dbHyph", 0


HC_IniFileKey	char	"hyphenation", 0

HC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

HC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

HC_childList	GenControlChildInfo	\
	<offset HyphenationGroup, mask HCF_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

HC_featuresList	GenControlFeaturesInfo	\
	<offset HyphenationGroup, HyphenationName, 0>

;---

HC_toolList	GenControlChildInfo	\
	<offset HyphenateToolList, mask HCTF_TOGGLE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

HC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset HyphenateToolList, HyphenationToolName>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HyphenationControlSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Don't set enabled if no USERDATA/DICTS directory.

PASS:		*ds:si	- HyphenationControlClass object
		ds:di	- HyphenationControlClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/18/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString dicts <"DICTS",0>

HyphenationControlSetEnabled	method	dynamic	HyphenationControlClass, 
					MSG_GEN_SET_ENABLED

	;
	; See if USERDATA/DICTS exists on this system, and if not,
	; don't enable the controller.  This is a hack, as we should
	; really rely on the spell library to tell us whether
	; hyphenation is working or not, but it's next to impossible
	; to call a routine in the spell library without jumping
	; through all kinds of hoops, so...
	;
		
		push	ds, dx, ax
		call	FilePushDir
		segmov	ds, cs
		mov	dx, offset dicts
		mov	bx, SP_USER_DATA
		call	FileSetCurrentPath
		call	FilePopDir
		pop	ds, dx, ax
		jc	notEnabled
callSuper:
		mov	di, offset HyphenationControlClass
		GOTO	ObjCallSuperNoLock
exit:
		ret
notEnabled:
		test	ds:[di].GI_states, mask GS_ENABLED
		jz	exit
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jmp	callSuper

HyphenationControlSetEnabled	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	HyphenationControlSetHyphenation -- MSG_HC_SET_HYPHENATION
						for HyphenationControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of HyphenationControlClass

	ax - The message

	cx - spacing

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
HyphenationControlSetHyphenation	method HyphenationControlClass,
						MSG_HC_SET_HYPHENATION

	mov	bp, mask VTPAA_ALLOW_AUTO_HYPHENATION	;bits changed
	GOTO	SetParaAttrCommon
HyphenationControlSetHyphenation	endm

HyphenationControlUserChangedHyphenation	method HyphenationControlClass,
						MSG_HC_USER_CHANGED_HYPHENATION
	call	GetFeaturesAndChildBlock
	clr	dx
	call	EnableDisableHyphenation
	ret

HyphenationControlUserChangedHyphenation	endm

	; bx = block, cx = flag

EnableDisableHyphenation	proc	near	uses dx
	.enter

	tst	dx
	jnz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	common
10$:
	mov	ax, MSG_GEN_SET_ENABLED
common:
	mov	dl, VUM_NOW
	mov	si, offset HyphenationCustomGroup
	call	ObjMessageSend

	.leave
	ret

EnableDisableHyphenation	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	HyphenationControlSetDropChars -- MSG_HC_SET_DROP_CHARS
						for HyphenationControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of HyphenationControlClass

	ax - The message

	dx - integer value returned by range

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

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
HyphenationControlSetMaxRange	method dynamic	HyphenationControlClass,
						MSG_HC_SET_MAX_RANGE

	mov	al, offset VTHI_HYPHEN_MAX_LINES
	GOTO	HyphenationCommon

HyphenationControlSetMaxRange	endm

;---

HyphenationControlSetMinWord	method dynamic	HyphenationControlClass,
						MSG_HC_SET_MIN_WORD

	mov	al, offset VTHI_HYPHEN_SHORTEST_WORD
	GOTO	HyphenationCommon

HyphenationControlSetMinWord	endm

;---

HyphenationControlSetMinPrefix	method dynamic	HyphenationControlClass,
						MSG_HC_SET_MIN_PREFIX

	mov	al, offset VTHI_HYPHEN_SHORTEST_PREFIX
	GOTO	HyphenationCommon

HyphenationControlSetMinPrefix	endm

;---

HyphenationControlSetMinSuffix	method dynamic	HyphenationControlClass,
						MSG_HC_SET_MIN_SUFFIX

	mov	al, offset VTHI_HYPHEN_SHORTEST_SUFFIX
	FALL_THRU	HyphenationCommon

HyphenationControlSetMinSuffix	endm

;---

HyphenationCommon	proc	far
	mov	cx, dx
	dec	cx
	xchg	ax, cx			;ax = val, cx = count
	shl	ax, cl
	mov_tr	bx, ax			;bx = mask
	mov	ax, 0x000f
	shl	ax, cl
	mov_tr	dx, ax			;dx = bits to clear
	mov	cx, bx

	mov	ax, MSG_VIS_TEXT_SET_HYPHENATION_PARAMS
	GOTO	SendVisText_AX_DXCX_Common

HyphenationCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	HyphenationControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for HyphenationControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of HyphenationControlClass

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
HyphenationControlUpdateUI	method dynamic HyphenationControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_attributes
	and	cx, mask VTPAA_ALLOW_AUTO_HYPHENATION
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_attributes
	and	dx, mask VTPAA_ALLOW_AUTO_HYPHENATION

	test	ss:[bp].GCUUIP_toolboxFeatures, mask HCTF_TOGGLE
	jz	noHyphenationTool
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset HyphenateToolList
	call	SendListSetViaData
noHyphenationTool:

	test	ss:[bp].GCUUIP_features, mask HCF_LIST
	jz	noHyphenation

	; set list

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset HyphenationList
	call	SendListSetExcl

	; enable or disable ranges

	call	EnableDisableHyphenation

	; set ranges

	mov	cx, es:VTNPAC_paraAttr.VTMPA_paraAttr.\
							VTPA_hyphenationInfo
	mov	dx, es:VTNPAC_paraAttrDiffs.VTPAD_hyphenationInfo

	mov	al, offset VTHI_HYPHEN_MAX_LINES
	mov	si, offset HyphenationMaxRange
	call	SetNibbleRange

	mov	al, offset VTHI_HYPHEN_SHORTEST_WORD
	mov	si, offset HyphenationShortestWordRange
	call	SetNibbleRange

	mov	al, offset VTHI_HYPHEN_SHORTEST_PREFIX
	mov	si, offset HyphenationShortestPrefixRange
	call	SetNibbleRange

	mov	al, offset VTHI_HYPHEN_SHORTEST_SUFFIX
	mov	si, offset HyphenationShortestSuffixRange
	call	SetNibbleRange

noHyphenation:
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

HyphenationControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
