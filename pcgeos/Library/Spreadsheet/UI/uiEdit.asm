COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiEdit.asm
FILE:		uiEdit.asm

AUTHOR:		Gene Anderson, Jul 20, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/20/92		Initial revision

DESCRIPTION:
	Routines for Spreadsheet edit controller

	$Id: uiEdit.asm,v 1.1 97/04/07 11:12:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSEditControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

EditControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSECGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSEditControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSECGetInfo	method dynamic SSEditControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSEC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSECGetInfo	endm

SSEC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSEC_IniFileKey,		; GCBI_initFileKey
	SSEC_gcnList,			; GCBI_gcnList
	length SSEC_gcnList,		; GCBI_gcnCount
	SSEC_notifyTypeList,		; GCBI_notificationList
	length SSEC_notifyTypeList,	; GCBI_notificationCount
	SSECName,			; GCBI_controllerName

	handle SSEditUI,		; GCBI_dupBlock
	SSEC_childList,			; GCBI_childList
	length SSEC_childList,		; GCBI_childCount
	SSEC_featuresList,		; GCBI_featuresList
	length SSEC_featuresList,	; GCBI_featuresCount
	SSEC_DEFAULT_FEATURES,		; GCBI_features

	handle SSEditToolUI,		; GCBI_toolBlock
	SSEC_toolList,			; GCBI_toolList
	length SSEC_toolList,		; GCBI_toolCount
	SSEC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SSEC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SSEC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSEC_IniFileKey	char	"ssEdit", 0

SSEC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>

SSEC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_SELECTION_CHANGE>

;---

ifdef GPC
SSEC_childList	GenControlChildInfo	\
	<offset ClearDB, mask SSECF_CLEAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset InsertGroup, mask SSECF_INSERT, 0>,
	<offset DeleteGroup, mask SSECF_DELETE, 0>
else
SSEC_childList	GenControlChildInfo	\
	<offset ClearDB, mask SSECF_CLEAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset InsertDB, mask SSECF_INSERT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeleteDB, mask SSECF_DELETE, mask GCCF_IS_DIRECTLY_A_FEATURE>
endif

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

ifdef GPC
SSEC_featuresList	GenControlFeaturesInfo	\
	<offset ClearDB, SSECClearName, 0>,
	<offset InsertGroup, SSECInsertName, 0>,
	<offset DeleteGroup, SSECDeleteName, 0>
else
SSEC_featuresList	GenControlFeaturesInfo	\
	<offset ClearDB, SSECClearName, 0>,
	<offset InsertDB, SSECInsertName, 0>,
	<offset DeleteDB, SSECDeleteName, 0>
endif

;---

SSEC_toolList	GenControlChildInfo	\
	<offset InsertRowTrigger, mask SSECTF_INSERT_ROW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset InsertColumnTrigger, mask SSECTF_INSERT_COLUMN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeleteRowTrigger, mask SSECTF_DELETE_ROW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DeleteColumnTrigger, mask SSECTF_DELETE_COLUMN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSEC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset InsertRowTrigger, SSECInsertRowName, 0>,
	<offset InsertColumnTrigger, SSECInsertColumnName, 0>,
	<offset DeleteRowTrigger, SSECDeleteRowName, 0>,
	<offset DeleteColumnTrigger, SSECDeleteColumnName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSECUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSEditControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSFillControlClass
		ax - the message

		ss:bp - GenControlUpdateUIParams
			GCUUIP_manufacturer
			GCUUIP_changeType
			GCUUIP_dataBlock
			GCUUIP_features
			GCUUIP_childBlock

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC ; not needed for separate buttons

SSECUpdateUI	method dynamic SSEditControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; Get the notification block
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	ds
	call	MemLock
	mov	ds, ax
	mov	dx, ds:NSSSC_flags		;dx <- SSheetSelectionFlags
	call	MemUnlock
	pop	ds
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	ax, ss:[bp].GCUUIP_features
	;
	; See if selecting rows or columns
	;
	mov	cx, mask SIF_COMPLETE		;cx <- assume rows
	test	dx, mask SSSF_ENTIRE_COLUMN
	jz	isRows
	mov	cx, mask SIF_COMPLETE or mask SIF_COLUMNS
isRows:
	;
	; Update the "Insert" list if it exists
	;
	test	ax, mask SSECF_INSERT
	jz	noInsert
	push	ax, cx, dx
	mov	si, offset InsertOptions	;^lbx:si <- OD of list
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				;dx <- no indeterminate
	call	ObjMessageCall_SSECC
	pop	ax, cx, dx
noInsert::
	;
	; Update the "Delete" list if it exists
	;
	test	ax, mask SSECF_DELETE
	jz	noDelete
	ornf	cx, mask SIF_DELETE		;cx <- mark for delete list
	mov	si, offset DeleteOptions	;^lbx:si <- OD of list
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				;dx <- no indeterminate
	call	ObjMessageCall_SSECC
noDelete::

	ret
SSECUpdateUI	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSECClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send clear message to output
CALLED BY:	MSG_SSEC_CLEAR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSECClear	method dynamic SSEditControlClass, \
						MSG_SSEC_CLEAR
	;
	; Get the current list entries
	;
	call	SSCGetChildBlockAndFeatures
	push	si
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	si, offset ClearOptionsList
	call	ObjMessageCall_SSECC		;ax <- selected booleans
	pop	si
	;
	; Send the results to the spreadsheet
	;
	mov	cx, ax				;cx <- SpreadsheetClearFlags
	jcxz	done				;branch if none selected
	mov	ax, MSG_SPREADSHEET_CLEAR_SELECTED
	call	SSCSendToSpreadsheet
done:
	ret
SSECClear	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSECInsertDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle insert or delete
CALLED BY:	MSG_SSEC_INSERT_DELETE_ROW_COLUMN

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditControlClass
		ax - the message

		cx - SpreadsheetInsertFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSECInsertDelete	method SSEditControlClass,
					MSG_SSEC_INSERT_DELETE_ROW_COLUMN
	mov	ax, MSG_SPREADSHEET_INSERT_SPACE
	call	SSCSendToSpreadsheet
	ret
SSECInsertDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSECDoInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle insert from DB

CALLED BY:	MSG_SSEC_DO_INSERT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC

SSECDoInsert		method dynamic SSEditControlClass,
						MSG_SSEC_DO_INSERT
	call	SSCGetChildBlockAndFeatures
	mov	di, offset InsertOptions
	call	GetSelected_SSEC_di
	GOTO	SSECInsertDelete
SSECDoInsert		endm

endif ; GPC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSECDoDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle Delete from DB

CALLED BY:	MSG_SSEC_DO_DELETE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSEditControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC

SSECDoDelete		method dynamic SSEditControlClass,
						MSG_SSEC_DO_DELETE
	call	SSCGetChildBlockAndFeatures
	mov	di, offset DeleteOptions
	call	GetSelected_SSEC_di
	GOTO	SSECInsertDelete
SSECDoDelete		endm

endif ; GPC

ObjMessageCall_SSECC	proc	near
	uses	di
	.enter

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
ObjMessageCall_SSECC	endp

ifndef GPC

GetSelected_SSEC_di	proc	near
	uses	ax, si
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, di				;^lbx:si <- OD of list
	call	ObjMessageCall_SSECC
	mov	cx, ax				;cx <- selection

	.leave
	ret
GetSelected_SSEC_di	endp

endif ; GPC

EditControlCode	ends
