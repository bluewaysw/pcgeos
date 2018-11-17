
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiDefineName.asm

AUTHOR:		Cheng, 7/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/92		Initial revision

DESCRIPTION:
		
	$Id: uiDefineName.asm,v 1.1 97/04/07 11:13:07 newdeal Exp $

-------------------------------------------------------------------------------@


;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSDefineNameControlClass		;declare the class record
	SSDNTextClass
SpreadsheetClassStructures	ends

;---------------------------------------------------

DefineNameControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSDNGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSDefineNameControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
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

SSDNGetInfo	method dynamic SSDefineNameControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSDN_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSDNGetInfo	endm

SSDN_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSDN_IniFileKey,		; GCBI_initFileKey
	SSDN_gcnList,			; GCBI_gcnList
	length SSDN_gcnList,		; GCBI_gcnCount
	SSDN_notifyTypeList,		; GCBI_notificationList
	length SSDN_notifyTypeList,	; GCBI_notificationCount
	SSDNName,			; GCBI_controllerName

	handle SSDefineNameControlUI,		; GCBI_dupBlock
	SSDN_childList,			; GCBI_childList
	length SSDN_childList,		; GCBI_childCount
	SSDN_featuresList,		; GCBI_featuresList
	length SSDN_featuresList,	; GCBI_featuresCount
	SSDN_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SSDN_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSDN_helpContext	char	"dbDefName", 0

SSDN_IniFileKey	char	"ssDefineName", 0

ifdef GPC
SSDN_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>

SSDN_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_SELECTION_CHANGE>
else
SSDN_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_NAME_CHANGE>

SSDN_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_NAME_CHANGE>
endif

;---

SSDN_childList	GenControlChildInfo	\
    <offset DefineNameDB, mask SSDNF_DEFINE_NAME, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSDN_featuresList	GenControlFeaturesInfo	\
	<offset DefineNameList, DefineNameName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSDNUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSDefineNameControl
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
		ax - the message
		ss:bp - GenControlUpdateUIParams
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp, si (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSDNUpdateUI	method dynamic SSDefineNameControlClass, \
				MSG_GEN_CONTROL_UPDATE_UI

ifdef GPC
	cmp	ss:[bp].GCUUIP_changeType, GWNT_SPREADSHEET_SELECTION_CHANGE
	jne	notSelection
	;
	; selection change, update cell ref in add name DB and change name DB
	;
	sub	sp, MAX_CELL_REF_SIZE + (size TCHAR)*2 + MAX_CELL_REF_SIZE
	mov	di, sp
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	dx, es:[NSSSC_selection].CR_end.CR_row
	mov	si, es:[NSSSC_selection].CR_end.CR_column
	push	dx, si
	mov	ax, es:[NSSSC_selection].CR_start.CR_row
	mov	cx, es:[NSSSC_selection].CR_start.CR_column
	call	MemUnlock
	segmov	es, ss
	cmp	ax, dx				; compare start/end row
	jne	storeRange
	cmp	cx, si				; compare start/end column
	je	storeEnd
storeRange:
	call	ParserFormatCellReference
	add	di, cx
	mov	{TCHAR}es:[di], C_COLON
	LocalNextChar	esdi
storeEnd:
	pop	ax, cx
	call	ParserFormatCellReference
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	bp, sp
	mov	si, offset NameAddCellRef
	call	setText
	mov	bp, sp
	mov	si, offset NameChangeCellRef
	call	setText
	add	sp, MAX_CELL_REF_SIZE + (size TCHAR)*2 + MAX_CELL_REF_SIZE
	ret
	
notSelection:
endif

	mov	ax, MSG_SPREADSHEET_INIT_NAME_LIST
	mov	cx, ds:LMBH_handle
	mov	dx, si
	call	SSCSendToSpreadsheet

	call	SSCGetChildBlockAndFeatures
	mov	cx, bx
	mov	dx, offset NameDefText		; ^lcx:dx <- text object
	mov	bp, -1				; clear the definition
	mov	ax, MSG_SPREADSHEET_NAME_UPDATE_DEFINITION
	call	SSCSendToSpreadsheet

	ret

ifdef GPC
setText	label	near
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	retn
endif
SSDNUpdateUI	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNUpdateUIWithNumNames

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_UPDATE_UI_WITH_NUM_NAMES)

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

SSDNUpdateUIWithNumNames	method dynamic SSDefineNameControlClass, \
				MSG_DNC_UPDATE_UI_WITH_NUM_NAMES
	call	SSDNEnableDisableUI

ifdef GPC
	push	cx, si
endif
	call	SSCGetChildBlockAndFeatures
	mov	si, offset DefineNameList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	di
	call	ObjMessage
ifdef GPC
	pop	cx, si
	jcxz	done
	push	si
	mov	si, offset DefineNameList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	ax, GIGS_NONE
	pop	si
	jne	done
	push	si
	mov	si, offset DefineNameList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	cx, dx				; select first
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	mov	ax, MSG_DNC_NAME_UPDATE_DEFINITION
	clr	cx
	mov	dl, -1
	call	ObjCallInstanceNoLock
done:
endif
	ret
SSDNUpdateUIWithNumNames	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNRequestMoniker

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

SSDNRequestMoniker	method dynamic SSDefineNameControlClass,
			MSG_DNC_REQUEST_MONIKER
	.enter

	call	SSCGetChildBlockAndFeatures
	mov	cx, bx
	mov	ax, MSG_SPREADSHEET_NAME_REQUEST_ENTRY_MONIKER
	mov	dx, offset DefineNameList	;^lcx:dx <- OD of list
	call	SSCSendToSpreadsheet

	.leave
	ret
SSDNRequestMoniker	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNInitAddName

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_INIT_ADD_NAME)

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
		ax - the message

RETURN:		

DESTROYED:	cx, dx, bp, bx, si, (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@
if FULL_EXECUTE_IN_PLACE

idata	segment
	global	nullString:byte
idata	ends

else

LocalDefNLString   nullString, 0

endif

SSDNInitAddName	method dynamic SSDefineNameControlClass, MSG_DNC_INIT_ADD_NAME

	call	SSCGetChildBlockAndFeatures

	;
	; null out name and defn
	;
	push	si
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset NameAddNameEdit
NOFXIP<	mov	dx, cs							>
NOFXIP<	mov	bp, offset cs:nullString	; dx:bp <- null string	>
FXIP<	push	ds							>
FXIP<	mov	bp, bx				; save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			; ds = dgroup		>
FXIP<	mov	dx, ds				; dx = dgroup		>
FXIP<	pop	ds							>
FXIP<	push	dx				; save dgroup value	>
FXIP<	mov	bx, offset nullString		; dx:bx = null str	>
FXIP<	xchg	bx, bp				; restore bx value	>
	clr	cx				; specify null terminated
	call	SSDNObjMessageCall

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset NameAddNameDefEdit
NOFXIP<	mov	dx, cs							>
NOFXIP<	mov	bp, offset cs:nullString	; dx:bp <- null string	>
FXIP<	pop	dx				; dx = dgroup		>
FXIP<	mov	bp, offset nullString		; dx:bp = null str	>
	clr	cx				; specify null terminated
	call	SSDNObjMessageCall
	pop	si

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	si, offset NameAddNameDB
	mov	dl, VUM_NOW
	call	SSDNObjMessageSend
	ret
SSDNInitAddName	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNAllowRelativeStatus

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_ALLOW_RELATIVE_STATUS)

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
		ax - the message

RETURN:		

DESTROYED:	cx, dx, bp, bx, si, (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/20/99		Initial version

-------------------------------------------------------------------------------@

SSDNAllowRelativeStatus	method dynamic SSDefineNameControlClass,
					MSG_DNC_ADD_ALLOW_RELATIVE_STATUS,
					MSG_DNC_CHANGE_ALLOW_RELATIVE_STATUS
	;
	; disable cell indicator if no relative
	;
	push	ax
	push	ax
	call	SSCGetChildBlockAndFeatures
	pop	ax
	mov	si, offset NameAddAllowRelative
	cmp	ax, MSG_DNC_ADD_ALLOW_RELATIVE_STATUS
	je	haveItem
	mov	si, offset NameChangeAllowRelative
haveItem:
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	ax, 1
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	haveState
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveState:
	pop	dx
	mov	si, offset NameAddCellRef
	cmp	dx, MSG_DNC_ADD_ALLOW_RELATIVE_STATUS
	je	haveRef
	mov	si, offset NameChangeCellRef
haveRef:
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
SSDNAllowRelativeStatus	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNAddName

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_ADD_NAME)

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
		ax - the message

RETURN:		

DESTROYED:	cx, dx, bp, bx, si, (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNAddName	method dynamic SSDefineNameControlClass, MSG_DNC_ADD_NAME
	;
	; allocate block for SpreadsheetNameParameters
	;
	mov	ax, size SpreadsheetNameParameters
	mov	cx, (mask HAF_LOCK shl 8) or mask HF_SWAPABLE
	call	MemAlloc
	mov	es, ax
	push	bx			; save mem han

	;
	; grab the text of the name
	;
	mov	di, offset SNP_text	; es:di <- ptr to destination buffer
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	si, offset NameAddNameEdit
	call	GetTextFromObject	; cx <- length of the text
	mov	es:SNP_textLength, cx
	pop	si

	;
	; grab the text of the definition
	;
	mov	di, offset SNP_definition
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	si, offset NameAddNameDefEdit
	call	GetTextFromObject	; cx <- length of the text
	mov	es:SNP_defLength, cx
	pop	si

	;
	; if requested, make absolute
	;
ifdef GPC
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	si, offset NameAddAllowRelative
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	ax, 1
	mov	es:SNP_nameFlags, 0
	jnz	allowRelative
	mov	es:SNP_nameFlags, -1
allowRelative:
	pop	si
endif

	pop	bx			; retrieve mem han of blk
	call	MemUnlock

	;
	; call the spreadsheet to define the name
	;
	mov	ax, MSG_SPREADSHEET_ADD_NAME_WITH_PARAM_BLK
	mov	cx, ds:LMBH_handle
	mov	dx, si			; cx:dx <- controller OD
	mov	bp, bx			; bp <- mem han
	call	SSCSendToSpreadsheet	; define the name

	ret
SSDNAddName	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNInitChangeName

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_INIT_CHANGE_NAME)

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
		ax - the message

RETURN:		

DESTROYED:	cx, dx, bp, bx, si, (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNInitChangeName	method dynamic SSDefineNameControlClass, \
						MSG_DNC_INIT_CHANGE_NAME
	call	SSDNGetNameSelected	; bx <- child block, ax <- selection
	mov	cx, bx
	jc	done

	mov	bp, ax				; bp <- selection

	;
	; stuff name
	;
	push	cx,bp,si
	mov	ax, MSG_SPREADSHEET_NAME_UPDATE_NAME
	mov	dx, offset NameChangeNameEdit
	call	SSCSendToSpreadsheet
	pop	cx,bp,si

	;
	; stuff definition
	;
	push	cx
	mov	ax, MSG_SPREADSHEET_NAME_UPDATE_DEFINITION
	mov	dx, offset NameChangeNameDefEdit
	call	SSCSendToSpreadsheet
	pop	bx

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	si, offset NameChangeNameDB
	mov	dl, VUM_NOW
	call	SSDNObjMessageSend

done:
	ret
SSDNInitChangeName	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNChangeName

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_CHANGE_NAME)

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDefineNameControlClass
		ax - the message

RETURN:		

DESTROYED:	cx, dx, bp, bx, si, (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNChangeName	method dynamic SSDefineNameControlClass, MSG_DNC_CHANGE_NAME
	;
	; allocate block for SpreadsheetNameParameters
	;
	mov	ax, size SpreadsheetNameParameters
	mov	cx, (mask HAF_LOCK shl 8) or mask HF_SWAPABLE
	call	MemAlloc
	mov	es, ax
	push	bx			; save mem han

	;
	; grab the text of the name
	;
	mov	di, offset SNP_text	; es:di <- ptr to destination buffer
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	si, offset NameChangeNameEdit
	call	GetTextFromObject	; cx <- length of the text
	mov	es:SNP_textLength, cx
	pop	si

	;
	; grab the text of the definition
	;
	mov	di, offset SNP_definition
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	si, offset NameChangeNameDefEdit
	call	GetTextFromObject	; cx <- length of the text
	mov	es:SNP_defLength, cx
	pop	si

	mov	es:SNP_flags, mask NAF_NAME or mask NAF_DEFINITION
	call	SSDNGetNameSelected	; bx <- child block, ax <- selection
	mov	es:SNP_listEntry, ax

	;
	; if requested, make absolute
	;
ifdef GPC
	push	si
	call	SSCGetChildBlockAndFeatures
	mov	si, offset NameChangeAllowRelative
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	ax, 1
	mov	es:SNP_nameFlags, 0
	jnz	allowRelative
	mov	es:SNP_nameFlags, -1
allowRelative:
	pop	si
endif

	pop	bx			; retrieve mem han of blk
	call	MemUnlock

	;
	; call the spreadsheet to change the name
	;
	mov	ax, MSG_SPREADSHEET_CHANGE_NAME_WITH_PARAM_BLK
	mov	cx, ds:LMBH_handle
	mov	dx, si			; cx:dx <- controller OD
	mov	bp, bx			; bp <- mem han
	call	SSCSendToSpreadsheet	; define the name

	ret
SSDNChangeName	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNNameOpError

DESCRIPTION:	

CALLED BY:	EXTERNAL (MSG_DNC_NAME_OP_ERROR)

PASS:		dh - non zero if adding name, 0 if changing name
		dl - ParserScannerEvaluatorError

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

SSDNNameOpError	method	dynamic SSDefineNameControlClass,
		MSG_DNC_NAME_OP_ERROR

	mov	bx, handle nameOpErrMsg
	push	bx
	call	MemLock
	push	ds
	mov	ds, ax
	mov	di, offset nameOpErrMsg
	mov	bx, ds:[di]

	mov	di, offset addingStr
	tst	dh
	jne	10$			; branch if adding name
	mov	di, offset changingStr
10$:
	mov	cx, ds:[di]

	call	SSDNGetErrDescription
	mov	dx, ds:[di]
	pop	ds

	sub	sp, size GenAppDoDialogParams
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, mask CDBF_SYSTEM_MODAL or\
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or\
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)

	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, bx

	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.offset, cx

	mov	ss:[bp].GADDP_dialog.SDP_stringArg2.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_stringArg2.offset, dx

	mov	ss:[bp].GADDP_finishOD.high, 0
	mov	ss:[bp].GADDP_finishOD.low, 0
	mov	ss:[bp].GADDP_message, MSG_META_DUMMY
	; string arg 2 and custom triggers not needed
	; params passed on stack
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication	; Query the user
	add	sp, size GenAppDoDialogParams

	pop	bx
	call	MemUnlock

	.leave
	ret
SSDNNameOpError	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNGetErrDescription

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		dl - ParserScannerEvaluatorError

RETURN:		di - offset to string describing error (possibly null)

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNGetErrDescription	proc	near
	uses	ax, cx, es
	.enter

	;
	; Scan the table of known errors
	;
	mov	di, offset defineNameErrors
	segmov	es, cs				;es:di <- ptr to table
	mov	cx, (length defineNameErrors)
	mov	al, dl				;al <- error to search for
	repne	scasb
	jne	notFound			;branch if not found
	;
	; Map the error to an enlightening message
	;
	sub	di, offset defineNameErrors+1
	shl	di, 1				;di <- table of words
	mov	di, cs:defineNameStrings[di]
done:

	.leave
	ret

	;
	; If nothing is found, return the unenlightening default error
	;
notFound:
	mov	di, offset nullStr		;di <- in case of failure
	jmp	done

defineNameErrors	ParserScannerEvaluatorError \
	PSEE_ILLEGAL_TOKEN,
	PSEE_BAD_CELL_REFERENCE,
	PSEE_COLUMN_TOO_LARGE,
	PSEE_ROW_TOO_LARGE,
	PSEE_NO_NAME_GIVEN,
	PSEE_NO_DEFINITION_GIVEN,
	PSEE_NAME_ALREADY_DEFINED,
	PSEE_BAD_NAME_DEFINITION,
	PSEE_NOT_ENOUGH_NAME_SPACE

defineNameStrings	lptr \
	offset badNameStr,		; text chunks in UI file..
	offset badCellRefStr,
	offset badColStr,
	offset badRowStr,
	offset noNameStr,
	offset noDefStr,
	offset nameAlreadyDefinedStr,
	offset badDefStr,
	offset tooManyNamesStr
SSDNGetErrDescription	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNDeleteName

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_DELETE_NAME)

PASS:		*ds:si - instance

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

SSDNDeleteName	method	dynamic SSDefineNameControlClass, MSG_DNC_DELETE_NAME

	call	SSDNGetNameSelected	; ax <- cur selection, changes bx,bp,di
	jc	err

	push	ax			; save selection
	mov	ax, size SSDNCommand
	mov	cx, (mask HAF_LOCK shl 8) or mask HF_SWAPABLE
	call	MemAlloc
	mov	es, ax
	mov	cx, bx
	pop	es:SSDNC_listEntry	; store selection
	mov	ax, ds:LMBH_handle
	mov	es:SSDNC_controllerOD.high, ax
	mov	es:SSDNC_controllerOD.low, si
	mov	es:SSDNC_msgToSendBack, MSG_DNC_QUERY_NAME_DELETE
	call	MemUnlock

	mov	ax, MSG_SPREADSHEET_GET_NAME_WITH_LIST_ENTRY
	call	SSCSendToSpreadsheet

done:
	ret

err:
	jmp	short done

SSDNDeleteName	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNQueryNameDelete

DESCRIPTION:	Ask the user if they really want to delete a name entry.

CALLED BY:	INTERNAL ()

PASS:		cx - mem han containing SSDNCommand structure with these
		    fields filled in:
		    SSDNC_dataBlk

RETURN:		SSDNC_dataBlk freed

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNQueryNameDelete	method	dynamic	SSDefineNameControlClass,
			MSG_DNC_QUERY_NAME_DELETE
	mov	bx, cx			; bx <- mem han
	push	bx
	call	MemLock
	mov	es, ax
	mov	bx, es:SSDNC_dataBlk
	push	bx
	call	MemLock
	mov	cx, ax
	clr	dx

	mov	bx, handle deleteNameMessage
	push	bx
	call	MemLock
	push	ds
	mov	ds, ax
	mov	di, offset deleteNameMessage	; ax:di = string
	mov	di, ds:[di]
	pop	ds

	;
	; OK, we have the name and the message, put up the dialog box.
	;
	sub	sp, size GenAppDoDialogParams
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, mask CDBF_SYSTEM_MODAL or\
			(CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or\
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, di
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.segment, cx
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.offset, dx
	mov	ax, ds:LMBH_handle
	mov	ss:[bp].GADDP_finishOD.high, ax
	mov	ss:[bp].GADDP_finishOD.low, si
	mov	ss:[bp].GADDP_message, MSG_DNC_QUERY_NAME_DELETE_DONE
	; string arg 2 and custom triggers not needed
	; params passed on stack
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication	; Query the user
	add	sp, size GenAppDoDialogParams	

	pop	bx			; bx <- StringsUI
	call	MemUnlock
	pop	bx			; bx <- SSDNC_dataBlk han
	call	MemFree
	pop	bx			; bx <- SSDNCommand han
	call	MemFree
	ret

SSDNQueryNameDelete	endm


SSDNQueryNameDeleteDone	method	dynamic	SSDefineNameControlClass,
			MSG_DNC_QUERY_NAME_DELETE_DONE
	cmp	cx, IC_YES		; Check for user selected YES
	jne	done

	call	SSDNGetNameSelected
	mov	bp, ax
	mov	cx, ds:LMBH_handle
	mov	dx, si			; cx:dx <- controller OD
	mov	ax, MSG_SPREADSHEET_DELETE_NAME_WITH_LIST_ENTRY
	call	SSCSendToSpreadsheet

done::
	ret
SSDNQueryNameDeleteDone	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNNameOpDone

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_NAME_OP_DONE)

PASS:		dx - number of names

RETURN:		

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNNameOpDone	method dynamic SSDefineNameControlClass, MSG_DNC_NAME_OP_DONE

	call	SSDNGetNameSelected	; bx <- child block, ax <- selection
	push	ax			; save selection

	mov	cx, dx			; cx <- number of entries
	dec	dx			; dx = entry to display

	call	NameRedisplayList

	pop	cx			; retrieve selection

	cmp	cx, dx
	jle	10$
	mov	cx, dx
10$:
	;
	; reselect the item
	;
	push	si
	mov	si, offset DefineNameList
	push	cx
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION

	cmp	cx, -1			; no selection?
	jne	20$			; branch if so
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED

20$:
	call	SSDNObjMessageCall
	pop	cx
	pop	si

	mov	ax, MSG_DNC_NAME_UPDATE_DEFINITION
	mov	dl, -1
	call	ObjCallInstanceNoLock

	ret
SSDNNameOpDone	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNUpdateNameDefinition

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_DNC_NAME_UPDATE_DEFINITION via
		ATTR_GEN_ITEM_GROUP_STATUS_MSG)

PASS:		cx - current selection
		dl - GenItemGroupStateFlags

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

SSDNUpdateNameDefinition	method dynamic SSDefineNameControlClass, \
				MSG_DNC_NAME_UPDATE_DEFINITION
	tst	dl				; redundant change?
	je	done				; ignore if so

	;
	; get definition info
	;
	mov	bp, cx				; bp <- selection
	call	SSCGetChildBlockAndFeatures
	mov	cx, bx
	mov	ax, MSG_SPREADSHEET_NAME_UPDATE_DEFINITION
	mov	dx, offset NameDefText		;^lcx:dx <- OD of text object
	call	SSCSendToSpreadsheet

done:
	ret
SSDNUpdateNameDefinition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextFromObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get text from a text object

CALLED BY:	GetName
PASS:		es:di	= Place to put the text
		^lbx:si	= Object to get it from.
RETURN:		cx	= Length of the text
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	It is assumed that the buffer is large enough. I suggest you use
	the 'maxLength' field of the gen (and vis) text edit object to
	force the length to something that will fit in your buffer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTextFromObject	proc	near	uses ax,dx,bp,di
	.enter
	LocalClrChar	es:[di]		; Init to a NULL string

	mov	dx, es			; dx:bp <- address for text
	mov	bp, di

	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
GetTextFromObject	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NameRedisplayList

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx - number of entries in the defined name list
		dx - entry to display

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

NameRedisplayList	proc	near	uses ax,bx,cx,dx,bp,di,si
	.enter
	;
	; If the entry to display is too large, set it to the end.
	;
	cmp	dx, cx			; Check for past end
	jb	entryOK

	mov	dx, cx			; Force to end of the list
	dec	dx			; Force it to something reasonable

entryOK:

	push	cx,si			; save regs
	call	SSCGetChildBlockAndFeatures
	mov	si, offset DefineNameList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx,si			; restore regs
	
	call	SSDNEnableDisableUI
	jcxz	redisplayChooseList	; Quit if nothing in the list

redisplayChooseList:
	;
	; Now redisplay the ChooseName list. We don't want to change the 
	; entry that the ChooseName list has selected.
	; cx = # of entries in the list
	;
	push	cx,si			; save regs
	call	SSCGetChildBlockAndFeatures
	mov	si, offset ChooseNameList
	call	SSDNGetSelection
	jnc	10$

	clr	ax

10$:
	mov	dx, ax			; dx <- Selected entry
	pop	cx,si			; restore regs
	
	cmp	dx, cx			; Check for past end
	jb	entryOK2

	mov	dx, cx			; Force to end of the list
	dec	dx			; Force it to something reasonable

entryOK2:
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
NameRedisplayList	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNGetNameSelected

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - instance

RETURN:		bx - child block
		ax - cur selection (-1 if none)
		carry - set if (ax = -1)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNGetNameSelected	proc	near	uses	si
	.enter

	call	SSCGetChildBlockAndFeatures
	mov	si, offset DefineNameList
	call	SSDNGetSelection	; ax <- cur selection

	.leave
	ret
SSDNGetNameSelected	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNEnableDisableUI

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

SSDNEnableDisableUI	proc	near	uses	ax,bx,cx,dx,di,si,bp
	.enter

	call	SSCGetChildBlockAndFeatures	; bx <- child block

	;
	; We want to enable/disable the Change and Delete triggers
	; depending on whether or not there are any items
	;
	mov	ax, MSG_GEN_SET_ENABLED
	tst	cx			; Check for items
	jnz	enableDisable		; Branch if has items

	mov	ax, MSG_GEN_SET_NOT_ENABLED

enableDisable:
	;
	; If there are no entries in the list we disable the Change and
	; Delete triggers
	;
	push	ax,bx			; save method
	mov	si, offset NameChangeTrigger
	mov	di, mask MF_CALL
	mov	dl, VUM_NOW
	call	ObjMessage
	pop	ax,bx			; restore method

	push	ax			; save method
	mov	si, offset NameDeleteTrigger
	mov	di, mask MF_CALL
	mov	dl, VUM_NOW
	call	ObjMessage
	pop	ax			; restore method

	.leave
	ret
SSDNEnableDisableUI	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNGetSelection

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		si - chunk of list object

RETURN:		ax - cur selection (-1 if none)
		carry - set if (ax = -1)

DESTROYED:	bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

SSDNGetSelection	proc	near	uses	cx,dx
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax <- current selection, or GIGS_NONE
	cmp	ax, -1
	stc
	je	done

	clc
done:
	.leave
	ret
SSDNGetSelection	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSDNObjMessageSend, SSDNObjMessageCall

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - method
		bx:si - OD
		cx,dx,bp - arguments

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

SSDNObjMessageSend	proc	near
	uses	di
	.enter
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SSDNObjMessageSend	endp

SSDNObjMessageCall	proc	near
	uses	di
	.enter
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SSDNObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSDNFilterChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide whether to allow a character or not

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_CHARACTER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSDNTextClass
		ax - the message

		cx - character to filter
RETURN:		cx - character, filtered

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSDNFilterChar		method dynamic SSDNTextClass,
					MSG_VIS_TEXT_FILTER_VIA_CHARACTER
	mov	ax, cx				;ax <- character
	;
	; Underscores are OK, and we map space to underscore
	;
SBCS<	cmp	ax, C_UNDERSCORE				>
DBCS<	cmp	ax, C_SPACING_UNDERSCORE			>
	je	isUnderscore
	cmp	ax, C_SPACE
	je	isUnderscore
	;
	; If this is alphabetic, it is OK
	;
if PZ_PCGEOS
	push	ax
	call	LocalGetWordPartType
	cmp	ax, WPT_ALPHA_NUMERIC
	je	checkAlpha
	cmp	ax, WPT_HIRAGANA
	je	charOK
	cmp	ax, WPT_KATAKANA
	je	charOK
	cmp	ax, WPT_KANJI
	je	charOK
	cmp	ax, WPT_FULLWIDTH_ALPHA_NUMERIC
	je	charOK
	cmp	ax, WPT_HALFWIDTH_KATAKANA
	je	charOK
	;
	;	The character is an alphanumeric.  Only Alphas will be
	;	accepted, so if numeric, don't allow it.
	;
checkAlpha:
	pop	ax
	call	LocalIsAlpha
	jnz	done
	clr	cx
	jmp	done
else
	call	LocalIsAlpha
	jnz	done				;branch if alpha (ie. OK)
	clr	cx				;cx <- dont' allow character
endif
if PZ_PCGEOS
charOK:
	pop	ax				;cleanup stack
endif
done:
	ret

isUnderscore:
SBCS<	mov	cx, C_UNDERSCORE				>
DBCS<	mov	cx, C_SPACING_UNDERSCORE			>
	jmp	done
SSDNFilterChar		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSDNCGenControlUnbuildNormalUiIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	don't unbuild 'cause there's bad things going on in this
		controller

CALLED BY:	MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE
PASS:		*ds:si	= SSDefineNameControlClass object
		ds:di	= SSDefineNameControlClass instance data
		ds:bx	= SSDefineNameControlClass object (same as *ds:si)
		es 	= segment of SSDefineNameControlClass
		ax	= message #
		cx	= child block
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSDNCGenControlUnbuildNormalUiIfPossible	method dynamic SSDefineNameControlClass, 
					MSG_GEN_CONTROL_UNBUILD_NORMAL_UI_IF_POSSIBLE
	;
	; don't call superclass to unbuild
	;
	ret
SSDNCGenControlUnbuildNormalUiIfPossible	endm

DefineNameControlCode	ends
