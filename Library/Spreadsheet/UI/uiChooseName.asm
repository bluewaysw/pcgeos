COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiChooseName.asm

AUTHOR:		Cheng, 7/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/92		Initial revision

DESCRIPTION:
		
	$Id: uiChooseName.asm,v 1.1 97/04/07 11:12:40 newdeal Exp $

-------------------------------------------------------------------------------@


;---------------------------------------------------


SpreadsheetClassStructures	segment	resource
	SSChooseNameControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

ChooseNameControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCNGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSChooseNameControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseNameControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCNGetInfo	method dynamic SSChooseNameControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSCN_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSCNGetInfo	endm

SSCN_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSCN_IniFileKey,		; GCBI_initFileKey
	SSCN_gcnList,			; GCBI_gcnList
	length SSCN_gcnList,		; GCBI_gcnCount
	SSCN_notifyTypeList,		; GCBI_notificationList
	length SSCN_notifyTypeList,	; GCBI_notificationCount
	SSCNName,			; GCBI_controllerName

	handle SSChooseNameControlUI,		; GCBI_dupBlock
	SSCN_childList,			; GCBI_childList
	length SSCN_childList,		; GCBI_childCount
	SSCN_featuresList,		; GCBI_featuresList
	length SSCN_featuresList,	; GCBI_featuresCount
	SSCN_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SSCN_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSCN_helpContext	char	"dbInsName", 0

SSCN_IniFileKey	char	"ssChooseName", 0

SSCN_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_NAME_CHANGE>

SSCN_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_NAME_CHANGE>

;---

SSCN_childList	GenControlChildInfo	\
    <offset ChooseNameDB, mask SSCNF_CHOOSE_NAME, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSCN_featuresList	GenControlFeaturesInfo	\
	<offset ChooseNameList, ChooseNameName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCNUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSChooseNameControl
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseNameControlClass
		ax - the message
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp, si (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCNUpdateUI	method dynamic SSChooseNameControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI

	call	SSCGetChildBlockAndFeatures
	mov	ax, MSG_SPREADSHEET_INIT_CHOOSE_NAME_LIST
	mov	cx, ds:LMBH_handle
	mov	dx, si
	call	SSCSendToSpreadsheet

	ret
SSCNUpdateUI	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSCNUpdateUIWithNumNames

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_CNC_UPDATE_UI_WITH_NUM_NAMES)

PASS:		cx - number of names

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSCNUpdateUIWithNumNames	method dynamic SSChooseNameControlClass, \
				MSG_CNC_UPDATE_UI_WITH_NUM_NAMES
	call	SSCNEnableDisableUI

	call	SSCGetChildBlockAndFeatures
	mov	si, offset ChooseNameList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	di
	call	ObjMessage
	ret
SSCNUpdateUIWithNumNames	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSCNEnableDisableUI

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx - number of names

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSCNEnableDisableUI	proc	near	uses	ax,bx,cx,dx,di,si,bp
	.enter

	call	SSCGetChildBlockAndFeatures	; bx <- child block

	;
	; We want to enable/disable the Paste trigger
	; depending on whether or not there are any items
	;
	mov	ax, MSG_GEN_SET_ENABLED
	tst	cx			; Check for items
	jnz	enableDisable		; Branch if has items

	mov	ax, MSG_GEN_SET_NOT_ENABLED

enableDisable:
	;
	; If there are no entries in the list we disable the Paste triggers
	;
	push	bx
	mov	si, offset ChooseNameTrigger
	mov	di, mask MF_CALL
	mov	dl, VUM_NOW
	call	ObjMessage
	pop	bx

	.leave
	ret
SSCNEnableDisableUI	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSCNRequestMoniker

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx:dx GenDynamicList OD
		bp - entry #

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSCNRequestMoniker	method dynamic SSChooseNameControlClass,
			MSG_CHOOSE_NAME_REQUEST_MONIKER
	.enter

	call	SSCGetChildBlockAndFeatures
	mov	ax, MSG_SPREADSHEET_NAME_REQUEST_ENTRY_MONIKER
	mov	cx, bx
	mov	dx, offset ChooseNameList	;^lcx:dx <- OD of list
	call	SSCSendToSpreadsheet

	.leave
	ret
SSCNRequestMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCNChooseName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the function that is selected

CALLED BY:	MSG_SS_CHOOSE_NAME
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChooseNameControlClass
		ax - the message

		cx - index of the function in the list

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCNChooseName		method dynamic SSChooseNameControlClass,
						MSG_SS_CHOOSE_NAME

if not KEYBOARD_ONLY_UI
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallApplication
endif
	push	si

	call	SSCGetChildBlockAndFeatures
	mov	si, offset ChooseNameList	;^lbx:si <- OD of list
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSCNObjMessageCall	; ax <- cur selection, carry if none
	jc	donePop				;branch if none selected

	mov	cx, ax				; cx <- item to get
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	call	SSCNObjMessageCall		; ^lcx:dx <- selected item
	jnc	donePop				;branch if none selected

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	call	SSCNObjMessageCall		; ^lax <- VisMoniker chunk

	;
	; allocate a block of memory for the string and copy the string over
	;
	push	bx, ds
	mov	si, ax
	call	ObjLockObjBlock
	mov	ds, ax	
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
	add	si, (offset VM_data + offset VMT_text)	; ds:si <- text string
	sub	cx, (offset VM_data + offset VMT_text)	; cx <- text size

	push	cx
	mov	ax, cx				;ax <- # bytes to allocate
	mov	cx, (mask HAF_LOCK shl 8)
	call	MemAlloc			;ax <- seg; bx <- handle
	mov	es, ax
	clr	di				;es:di <- dest
	pop	cx				;cx <- # of bytes to copy
	rep	movsb
	call	MemUnlock
	mov	dx, bx				;dx <- handle of string
	pop	bx, ds
	call	MemUnlock
	pop	si				;*ds:si <- controller

	;
	; dx = mem handle
	;
;	clr	cx				; string is null-terminated
	clr	bp				;bp.low <- offset; bp.high <- md
	mov	ax, MSG_SPREADSHEET_REPLACE_TEXT_SELECTION
	clr	bx, di
	call	GenControlOutputActionRegs
		
	ret

donePop:
	add	sp, 2				;clear si from stack
	ret
SSCNChooseName		endm


SSCNObjMessageCall	proc	near
	uses	di
	.enter
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	.leave
	ret
SSCNObjMessageCall	endp

ChooseNameControlCode	ends
