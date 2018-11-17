COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiJustificationControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	JustificationControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement JustificationControlClass

	$Id: uiJustification.asm,v 1.1 97/04/07 11:17:31 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	JustificationControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	JustificationControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for JustificationControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of JustificationControlClass

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
JustificationControlGetInfo	method dynamic	JustificationControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset JC_dupInfo
	GOTO	CopyDupInfoCommon

JustificationControlGetInfo	endm

JC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	JC_IniFileKey,			; GCBI_initFileKey
	JC_gcnList,			; GCBI_gcnList
	length JC_gcnList,		; GCBI_gcnCount
	JC_notifyTypeList,		; GCBI_notificationList
	length JC_notifyTypeList,	; GCBI_notificationCount
	JCName,				; GCBI_controllerName

	handle JustificationControlUI,	; GCBI_dupBlock
	JC_childList,			; GCBI_childList
	length JC_childList,		; GCBI_childCount
	JC_featuresList,		; GCBI_featuresList
	length JC_featuresList,		; GCBI_featuresCount
	JC_DEFAULT_FEATURES,		; GCBI_features

	handle JustificationControlToolboxUI,	; GCBI_toolBlock
	JC_toolList,			; GCBI_toolList
	length JC_toolList,		; GCBI_toolCount
	JC_toolFeaturesList,		; GCBI_toolFeaturesList
	length JC_toolFeaturesList,	; GCBI_toolFeaturesCount
	JC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

JC_IniFileKey	char	"justification", 0

JC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_JUSTIFICATION_CHANGE>

JC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_JUSTIFICATION_CHANGE>

;---

if CHAR_JUSTIFICATION

JC_childList	GenControlChildInfo	\
	<offset JustificationList, mask JCF_LEFT or mask JCF_RIGHT or
				mask JCF_CENTER or mask JCF_FULL or
				mask JCF_FULL_CHAR, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

JC_featuresList	GenControlFeaturesInfo	\
	<offset FullEntry, FullName, 0>,
	<offset CenterEntry, CenterName, 0>,
	<offset RightEntry, RightName, 0>,
	<offset LeftEntry, LeftName, 0>,
	<offset FullCharEntry,  FullCharName, 0>

;---

JC_toolList	GenControlChildInfo	\
	<offset JustificationToolList, mask JCTF_LEFT or mask JCTF_RIGHT or
				mask JCTF_CENTER or mask JCTF_FULL or
				mask JCTF_FULL_CHAR, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

JC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset FullToolEntry, FullName, 0>,
	<offset CenterToolEntry, CenterName, 0>,
	<offset RightToolEntry, RightName, 0>,
	<offset LeftToolEntry, LeftName, 0>,
	<offset FullCharToolEntry, FullCharName, 0>
else

JC_childList	GenControlChildInfo	\
	<offset JustificationList, mask JCF_LEFT or mask JCF_RIGHT or
				mask JCF_CENTER or mask JCF_FULL, 0>

JC_featuresList	GenControlFeaturesInfo	\
	<offset FullEntry, FullName, 0>,
	<offset CenterEntry, CenterName, 0>,
	<offset RightEntry, RightName, 0>,
	<offset LeftEntry, LeftName, 0>

;---

JC_toolList	GenControlChildInfo	\
	<offset JustificationToolList, mask JCTF_LEFT or mask JCTF_RIGHT or
				mask JCTF_CENTER or mask JCTF_FULL, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

JC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset FullToolEntry, FullName, 0>,
	<offset CenterToolEntry, CenterName, 0>,
	<offset RightToolEntry, RightName, 0>,
	<offset LeftToolEntry, LeftName, 0>
endif

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	JustificationControlSetJustification -- MSG_JC_SET_JUSTIFICATION
						for JustificationControlClass

DESCRIPTION:	Handle a change in theee "Plain" state

PASS:
	*ds:si - instance data
	es - segment of JustificationControlClass

	ax - The message

	cx - Justification shl offset VTPAA_JUSTIFICATION

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
JustificationControlSetJustification	method JustificationControlClass,
						MSG_JC_SET_JUSTIFICATION

if CHAR_JUSTIFICATION
	;
	; Suspend the text object as we have multiple messages to send
	;
	mov	ax, MSG_META_SUSPEND
	call	SendVisText_AX_CX_Common
	;
	; Temporarily clear the TMMF_CHARACTER_JUSTIFICATION flag
	; and set the justification.
	;
	push	cx
	andnf	cx, not (mask TMMF_CHARACTER_JUSTIFICATION)
		CheckHack <(mask VTPAA_JUSTIFICATION and mask TMMF_CHARACTER_JUSTIFICATION) eq 0>
endif
	mov	dx, mask VTPAA_JUSTIFICATION
	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTRIBUTES
if CHAR_JUSTIFICATION
	call	SendMeta_AX_DXCX_Common
	pop	cx
	;
	; Set the justification type, too.
	;
	andnf	cx, mask TMMF_CHARACTER_JUSTIFICATION
	mov	ax, MSG_VIS_TEXT_SET_TEXT_MISC_MODE
	call	SendMeta_AX_CX_Common
	;
	; Done with everything...
	;
	mov	ax, MSG_META_UNSUSPEND
	call	SendVisText_AX_CX_Common
	ret
else
	GOTO	SendMeta_AX_DXCX_Common
endif

JustificationControlSetJustification	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	JustificationControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for JustificationControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of JustificationControlClass

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
JustificationControlUpdateUI	method dynamic JustificationControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_PARA_ATTR_CHANGE
	jz	textNotify
	clr	ax
	clr	dx
	mov	al, ds:NJC_useGeneral
	mov	di, ax				;di = general flag
	mov	al, ds:NJC_justification
	mov	cl, offset VTPAA_JUSTIFICATION
	shl	ax, cl
	mov_tr	cx, ax
	mov	dl, ds:NJC_diffs
	jmp	common
textNotify:
	mov	cx, ds:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_attributes
	mov	dx, ds:VTNPAC_paraAttrDiffs.VTPAD_attributes
	and	cx, mask VTPAA_JUSTIFICATION
	and	dx, mask VTPAA_JUSTIFICATION
if CHAR_JUSTIFICATION
	;
	; OR in the extra bit for justification type, including diffs
	;
	mov	al, ds:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_miscMode
	andnf	al, mask TMMF_CHARACTER_JUSTIFICATION
	or	cl, al
	mov	ah, ds:VTNPAC_paraAttrDiffs.VTPAD_diffs2.high
	andnf	ah, (mask VTPAF2_MULTIPLE_JUSTIFICATION_TYPES) shr 8
	or	dl, ah
		CheckHack <(mask VTPAA_JUSTIFICATION and mask TMMF_CHARACTER_JUSTIFICATION) eq 0>
endif
	clr	di				;never use general here
common:
	call	MemUnlock
	pop	ds

	; set justification list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask JCF_LEFT or mask JCF_RIGHT \
			or mask JCF_CENTER or mask JCF_FULL
	jz	noJust
	mov	si, offset JustificationList
	call	SendListSetExcl
noJust:

	; reset full/general moniker here if needed

	test	ax, mask JCF_FULL
	jz	noFull
	push	cx, dx, bp, di
	mov	ax, offset FullMoniker
	tst	di
	jz	10$
	mov	ax, offset GeneralMoniker
10$:
	push	ax
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	si, offset FullEntry
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx
	cmp	ax, cx
	jz	noSet
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
noSet:
	pop	cx, dx, bp, di
noFull:

	; set text style tool

	mov	ax, ss:[bp].GCUUIP_toolboxFeatures
	test	ax, mask JCF_LEFT or mask JCF_RIGHT or \
		    mask JCF_CENTER or mask JCF_FULL
	jz	toolsDone
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset JustificationToolList
	call	SendListSetExcl

	; reset full/general quick help text here, if needed

	test	ax, mask JCF_FULL
	jz	toolsDone
	push	cx, dx, bp
	mov	ax, offset FullHelp
	tst	di
	jz	20$
	mov	ax, offset GeneralHelp
20$:
	sub	sp, (size AddVarDataParams) + (size optr)
	mov	bp, sp
	mov	di, bp
	add	di, (size AddVarDataParams)
	movdw	ss:[bp].AVDP_data, ssdi
	mov	ss:[bp].AVDP_dataSize, (size optr)
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_FOCUS_HELP
	mov	ss:[di].handle, handle ControlStrings
	mov	ss:[di].chunk, ax
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, (size AddVarDataParams)
	mov	si, offset FullToolEntry
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, (size AddVarDataParams) + (size optr)
	pop	cx, dx, bp
toolsDone:
	ret
JustificationControlUpdateUI	endm

TextControlCommon ends

endif		; not NO_CONTROLLERS
