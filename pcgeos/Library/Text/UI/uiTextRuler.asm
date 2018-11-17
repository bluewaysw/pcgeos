COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiTextRulerControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	TextRulerControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement TextRulerControlClass

	$Id: uiTextRuler.asm,v 1.1 97/04/07 11:17:16 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	TextRulerControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for TextRulerControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of TextRulerControlClass

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
TextRulerControlGetInfo	method dynamic	TextRulerControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TRCC_dupInfo
	GOTO	CopyDupInfoCommon

TextRulerControlGetInfo	endm

TRCC_dupInfo	GenControlBuildInfo	<
	mask GCBF_IS_ON_ACTIVE_LIST,	; GCBI_flags
	TRCC_IniFileKey,		; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	TRCCName,			; GCBI_controllerName

	handle TextRulerControlUI,	; GCBI_dupBlock
	TRCC_childList,			; GCBI_childList
	length TRCC_childList,		; GCBI_childCount
	TRCC_featuresList,		; GCBI_featuresList
	length TRCC_featuresList,	; GCBI_featuresCount
	TRCC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	TRCC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

TRCC_IniFileKey	char	"textRulerOptions", 0

;---

TRCC_childList	GenControlChildInfo	\
	<offset TextRulerAttrList, mask TRCCF_ROUND or \
				   mask TRCCF_IGNORE_ORIGIN, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TRCC_featuresList	GenControlFeaturesInfo	\
	<offset IgnoreOriginEntry, IgnoreName, 0>,
	<offset RoundEntry, RoundName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerControlSetState -- MSG_TRCC_CHANGE_STATE
						for TextRulerControlClass

DESCRIPTION:	Handle change in the ruler state

PASS:
	*ds:si - instance data
	es - segment of TextRulerControlClass

	ax - The message

	cx - selected booleans
	bp - changed booleans

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
TextRulerControlSetState	method dynamic TextRulerControlClass,
						MSG_TRCC_CHANGE_STATE

	mov	ds:[di].TRCI_attrs, cx
	call	UpdateAllRulers
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication
	ret

TextRulerControlSetState	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerControlGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for TextRulerControlClass

DESCRIPTION:	Generate the UI for the text ruler control

PASS:
	*ds:si - instance data
	es - segment of TextRulerControlClass

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
	Tony	5/21/92		Initial version

------------------------------------------------------------------------------@
TextRulerControlGenerateUI	method dynamic	TextRulerControlClass,
						MSG_GEN_CONTROL_GENERATE_UI

	push	ds:[di].TRCI_attrs

	mov	di, offset TextRulerControlClass
	call	ObjCallSuperNoLock

	pop	cx
	call	GetFeaturesAndChildBlock
	test	ax, mask TRCCF_ROUND or mask TRCCF_IGNORE_ORIGIN
	jz	done
	mov	si, offset TextRulerAttrList
	clr	dx
	call	SendListSetViaData
done:
	ret

TextRulerControlGenerateUI	endm

TextControlCode ends

;---

TextControlInit segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerControlLoadOptions -- MSG_META_LOAD_OPTIONS for
			TextRulerControlClass

DESCRIPTION:	Load options from .ini file

PASS:
	*ds:si - instance data
	es - segment of TextRulerControlClass

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
TextRulerControlLoadOptions	method dynamic	TextRulerControlClass,
							MSG_META_LOAD_OPTIONS

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	mov	bp, sp

	push	ax
	push	ds:[LMBH_handle], es, si
	call	PrepForOptions
	call	InitFileReadInteger
	pop	bx, es, si
	call	MemDerefDS
	jc	noData
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].TRCI_attrs, ax
noData:
	pop	ax

	add	sp, INI_CATEGORY_BUFFER_SIZE

	mov	di, offset TextRulerControlClass
	GOTO	ObjCallSuperNoLock

TextRulerControlLoadOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerControlSaveOptions -- MSG_META_SAVE_OPTIONS for
			TextRulerControlClass

DESCRIPTION:	Save options from .ini file

PASS:
	*ds:si - instance data
	es - segment of TextRulerControlClass

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
TextRulerControlSaveOptions	method dynamic	TextRulerControlClass,
							MSG_META_SAVE_OPTIONS

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	mov	bp, sp

	push	ax, ds:[LMBH_handle], es, si
	push	ds:[di].TRCI_attrs
	call	PrepForOptions
	pop	bp
	call	InitFileWriteInteger
	pop	ax, bx, es, si
	call	MemDerefDS

	add	sp, INI_CATEGORY_BUFFER_SIZE

	mov	di, offset TextRulerControlClass
	GOTO	ObjCallSuperNoLock

TextRulerControlSaveOptions	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	PrepForOptions

DESCRIPTION:	Prepare for load/save options

CALLED BY:	INTERNAL

PASS:	*ds:si - object
	ss:bp - buffer for category

RETURN:
	category - loaded
	ds:si - pointing at category
	cx:dx - pointing at key

DESTROYED:
	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/30/92	Initial version

------------------------------------------------------------------------------@
PrepForOptions	proc	near
	mov	cx, ss
	mov	dx, bp
	call	UserGetInitFileCategory
	mov	ds, cx
	mov	si, dx

	mov	cx, cs
	mov	dx, offset textRulerControlKey	;cx:dx = key
	ret

PrepForOptions	endp

textRulerControlKey	char	"textRulerAttrs", 0

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerControlAttach -- MSG_META_ATTACH
						for TextRulerControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TextRulerControlClass

	ax - The message

	cx, dx, bp - attach data

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/92		Initial version

------------------------------------------------------------------------------@
TextRulerControlAttach	method dynamic	TextRulerControlClass, MSG_META_ATTACH

	mov	di, offset TextRulerControlClass
	call	ObjCallSuperNoLock

	FALL_THRU	UpdateAllRulers

TextRulerControlAttach	endm

;---

UpdateAllRulers	proc	far
	class	TextRulerControlClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].TRCI_attrs

	push	si
	mov	bx, segment TextRulerClass
	mov	si, offset TextRulerClass
	mov	ax, MSG_TEXT_RULER_SET_CONTROLLED_ATTRS
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_TEXT_RULER_OBJECTS
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS

	clr	bx
	call	GeodeGetAppObject
	mov	dx, size GCNListMessageParams
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, size GCNListMessageParams

	ret

UpdateAllRulers	endp

TextControlInit ends

endif		; not NO_CONTROLLERS
