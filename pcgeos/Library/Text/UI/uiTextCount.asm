COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiTextCountControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	TextCountControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement TextCountControlClass

	$Id: uiTextCount.asm,v 1.1 97/04/07 11:17:06 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	TextCountControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextCountControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for TextCountControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of TextCountControlClass

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
TextCountControlGetInfo	method dynamic	TextCountControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TCC_dupInfo

	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret

TextCountControlGetInfo	endm

TCC_dupInfo	GenControlBuildInfo	<
	mask GCBF_CUSTOM_ENABLE_DISABLE, ; GCBI_flags
	TCC_IniFileKey,			; GCBI_initFileKey
	TCC_gcnList,			; GCBI_gcnList
	length TCC_gcnList,		; GCBI_gcnCount
	TCC_notifyTypeList,		; GCBI_notificationList
	length TCC_notifyTypeList,	; GCBI_notificationCount
	TCCName,			; GCBI_controllerName

	handle TextCountControlUI,	; GCBI_dupBlock
	TCC_childList,			; GCBI_childList
	length TCC_childList,		; GCBI_childCount
	TCC_featuresList,		; GCBI_featuresList
	length TCC_featuresList,	; GCBI_featuresCount
	TCC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	TCC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	TCC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

TCC_helpContext	char	"dbCount", 0


TCC_IniFileKey	char	"textCount", 0

TCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_COUNT_CHANGE>

TCC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_COUNT_CHANGE>

;---

TCC_childList	GenControlChildInfo	\
	<offset CharacterCountText, mask TCCF_CHARACTER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset WordCountText, mask TCCF_WORD,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LineCountText, mask TCCF_LINE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ParagraphCountText, mask TCCF_PARAGRAPH,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset RecalcTrigger, mask TCCF_RECALC,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TCC_featuresList	GenControlFeaturesInfo	\
	<offset RecalcTrigger, RecalcName, 0>,
	<offset ParagraphCountText, ParagraphName, 0>,
	<offset LineCountText, LineName, 0>,
	<offset WordCountText, WordName, 0>,
	<offset CharacterCountText, CharacterName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	TextCountControlRecalc -- MSG_TCC_RECALC
					for TextCountControlClass

DESCRIPTION:	Recalculate counts

PASS:
	*ds:si - instance data
	es - segment of TextCountControlClass

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
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
TextCountControlRecalc	method dynamic	TextCountControlClass, MSG_TCC_RECALC


	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication


	push	si

	;
	; Initialize all counts to zero
	;

	mov	ax, size VisTextNotifyCountChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	ax, 1
	call	MemInitRefCount

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_TEXT_COUNT_CHANGE

	push	bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_COUNT_CHANGE

	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	mov	dx, size GCNListMessageParams
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, dx
	pop	si


		
	mov	ax, MSG_META_UI_FORCE_CONTROLLER_UPDATE
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_TEXT_COUNT_CHANGE
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	GenControlSendToOutputRegs

	push	si
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si
	clr	dx
	mov	ax, MSG_META_DISPATCH_EVENT
	clr	bx			;any class -- this is a meta message
	clr	di
	call	GenControlOutputActionRegs

	ret

TextCountControlRecalc	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextCountControlInitiate --
		MSG_GEN_INTERACTION_INITIATE for TextCountControlClass

DESCRIPTION:	Notification that the dialog box has opened

PASS:
	*ds:si - instance data
	es - segment of TextCountControlClass

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
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
TextCountControlInitiate	method dynamic	TextCountControlClass,
					MSG_GEN_INTERACTION_INITIATE

	mov	di, offset TextCountControlClass
	call	ObjCallSuperNoLock
	mov	ax, MSG_TCC_RECALC
	GOTO	ObjCallInstanceNoLock

TextCountControlInitiate	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextCountControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for TextCountControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of TextCountControlClass

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
TextCountControlUpdateUI	method dynamic TextCountControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	bx
	call	MemLock
	mov	ds, ax

	mov	si, offset CharacterCountText
	mov	bx, mask TCCF_CHARACTER
	movdw	dxax, ds:VTNCC_charCount
	call	setCount

	mov	si, offset WordCountText
	mov	bx, mask TCCF_WORD
	movdw	dxax, ds:VTNCC_wordCount
	call	setCount

	mov	si, offset LineCountText
	mov	bx, mask TCCF_LINE
	movdw	dxax, ds:VTNCC_lineCount
	call	setCount

	mov	si, offset ParagraphCountText
	mov	bx, mask TCCF_PARAGRAPH
	movdw	dxax, ds:VTNCC_paraCount
	call	setCount

	pop	bx
	call	MemUnlock
	ret

;---

setCount:
	test	bx, ss:[bp].GCUUIP_features
	jz	setCountDone

	push	bp
	sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
	segmov	es, ss
	mov	di, sp				;es:di = buffer
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	mov	bx, ss:[bp].GCUUIP_childBlock
	clr	cx				;null-terminated
	movdw	dxbp, esdi			;dxbp = buffer
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	di
	call	ObjMessage
	add	sp, UHTA_NULL_TERM_BUFFER_SIZE
	pop	bp
setCountDone:
	retn

TextCountControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
