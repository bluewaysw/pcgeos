COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiHelp.asm
FILE:		uiHelp.asm

AUTHOR:		Gene Anderson, Apr 20, 1992

ROUTINES:
	Name			Description
	----			-----------
MSG_GEN_CONTROL_GET_INFO	Get GenControlBuildInfo for controller
MSG_GEN_CONTROL_UPDATE_UI	Update UI for controller

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/20/92		Initial revision

DESCRIPTION:
	Code for Text Help controller

	$Id: uiHelp.asm,v 1.1 97/04/07 11:17:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SET_LIST_NUM_ENTRIES		equ	6
SET_LIST_WIDTH			equ	25
DEFINE_LIST_NUM_ENTRIES		equ	6
HLINK_LIST_NUM_ENTRIES		equ	6
HLINK_LIST_WIDTH		equ	25

;---------------------------------------------------

TextClassStructures	segment	resource
	TextHelpControlClass		;declare the class record
TextClassStructures	ends

if not NO_CONTROLLERS

idata segment
	currentDisplayNum	word	;what it says
idata ends

;---------------------------------------------------

TextHelpControlCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GenControlBuildInfo for Help Context Controller
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpContextControlClass
		ax - the method

RETURN:		cx:dx - list of children

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

THelpControlGetInfo	method dynamic TextHelpControlClass, \
						MSG_GEN_CONTROL_GET_INFO

	segmov	ds, cs
	mov	si, offset THC_dupInfo		;ds:si <- source
	mov	es, cx
	mov	di, dx				;es:di <- dest
	mov	cx, size GenControlBuildInfo
	rep	movsb
	ret
THelpControlGetInfo	endm

THC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	THC_initFileKey,		; GCBI_initFileKey
	THC_gcnList,			; GCBI_gcnList
	length THC_gcnList,		; GCBI_gcnCount
	THC_notifyTypeList,		; GCBI_notificationList
	length THC_notifyTypeList,	; GCBI_notificationCount
	THCName,			; GCBI_controllerName

	handle TextHelpControlUI,	; GCBI_dupBlock
	THC_childList,			; GCBI_childList
	length THC_childList,		; GCBI_childCount
	THC_featuresList,		; GCBI_featuresList
	length THC_featuresList,	; GCBI_featuresCount
	THC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	THC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

THC_initFileKey	char	"TextHelp", 0

THC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_TYPE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE>

THC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_NAME_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_TYPE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_DISPLAY_CHANGE>

;---

THC_childList	GenControlChildInfo	\
	<offset TextHelpDefineContextBox, mask THCF_DEFINE_CONTEXT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextHelpDefineFileBox, mask THCF_DEFINE_FILE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextHelpSetContextBox, mask THCF_SET_CONTEXT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextHelpSetHyperlinkBox, mask THCF_SET_HYPERLINK,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextHelpClearAllContextsTrigger, mask THCF_CLEAR_ALL_CONTEXTS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextHelpClearAllHyperlinksTrigger, mask THCF_CLEAR_ALL_HYPERLINKS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TextHelpFollowHyperlinkTrigger, mask THCF_FOLLOW_HYPERLINK,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

THC_featuresList	GenControlFeaturesInfo	\
	<offset TextHelpDefineContextBox, DefineContextName, 0>,
	<offset TextHelpDefineFileBox, DefineFileName, 0>,
	<offset TextHelpSetContextBox, SetContextName, 0>,
	<offset TextHelpSetHyperlinkBox, SetHyperlinkName, 0>,
	<offset TextHelpClearAllContextsTrigger, ClearContextsName, 0>,
	<offset TextHelpClearAllHyperlinksTrigger, ClearHyperlinksName, 0>,
	<offset TextHelpFollowHyperlinkTrigger, FollowHyperlinkName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for TextHelpControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		ss:bp - GenControlUpdateUIParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/92		Initial version
	Edwin	2/23/94		Display has changed to a different
				file.  Re-initialize lists to 0 to
				display *same file* when switching to
				a new file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

THelpControlUpdateUI	method dynamic TextHelpControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	cmp	ss:[bp].GCUUIP_changeType, GWNT_DISPLAY_CHANGE
	LONG je resetTHCI_file

	cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_NAME_CHANGE
	LONG je	updateForNameChange
	;
	; Selected context and/or hyperlink has changed
	;
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	dx, ds:VTNTC_index.VTT_context	;dx <- context
	mov	cx, ds:VTNTC_index.VTT_hyperlinkName
	mov	di, ds:VTNTC_index.VTT_hyperlinkFile
	mov	ax, ds:VTNTC_typeDiffs		;ax <- VisTextTypeDiffs
	call	MemUnlock
	pop	ds
	push	cx, ax
	push	di, ax
	push	dx, ax
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; Set the selection in the context list
	;
	pop	dx				;dx <- diffs
	andnf	dx, mask VTTD_MULTIPLE_CONTEXTS
	pop	cx				;cx <- context list #
	mov	di, offset THSCContextList	;^lbx:di <- context list
	call	HC_SetListSelection		;set selection
	;
	; For convienence, we try to keep the last thing the user was
	; looking at as the visible item.
	;
	push	ax, bx
	mov	ax, TEMP_CURRENT_CONTEXT_INDEX
	cmp	cx, GIGS_NONE			;any selection?
	je	isNoSelection			;branch if no selection
	push	cx
	mov	cx, (size word)			;cx <- size of data
	call	ObjVarAddData
	pop	ds:[bx]				;save last selection
	jmp	noPreviousSelection
isNoSelection:
	call	ObjVarFindData
	jnc	noPreviousSelection		;branch if no previous selection
	push	cx, dx, bp
	mov	cx, ds:[bx]			;cx <- last valid selection
	mov	bx, ss:[bp].GCUUIP_childBlock	;^lbx:di <- list
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	call	HC_SendEventViaOutput
	pop	cx, dx, bp
noPreviousSelection:
	pop	ax, bx
	;
	; Set the selection in the file list
	;
	pop	dx				;dx <- diffs
	andnf	dx, mask VTTD_MULTIPLE_HYPERLINKS
	pop	cx				;cx <- file list #
	mov	di, offset THSHFileList		;^lbx:di <- file list
	call	HC_SetListSelection		;set selection
	;
	; Update the list of corresponding contexts
	;
	mov	dx, cx				;dx <- file list #
	mov	bp, cx
	call	UpdateHyperlinkContextList
	;
	; Set the selection in the context list
	;
	pop	dx				;dx <- diffs
	andnf	dx, mask VTTD_MULTIPLE_HYPERLINKS
	pop	cx				;cx <- context list #
	mov	di, offset THSHContextList	;^lbx:di <- context list
	call	HC_SetListSelection
	;
	; Enable or disable the "Follow Hyperlink" trigger as needed
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	cx, GIGS_NONE			;no selection?
	je	doED				;branch if no selection
	test	dx, mask VTTD_MULTIPLE_HYPERLINKS
	jnz	doED				;branch if indeterminate
	tst	bp				;same file?
	jnz	doED				;branch if not same file
	mov	ax, MSG_GEN_SET_ENABLED
doED:
	mov	si, offset TextHelpFollowHyperlinkTrigger
	mov	dl, VUM_NOW
	call	HC_ObjMessageSend
	ret

	;
	; Names have changed
	;
updateForNameChange:
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	call	ForceUpdateUI
	mov	ax, TEMP_CURRENT_CONTEXT_INDEX
	call	ObjVarDeleteData
	ret

	; reset THCI_file to 0 because of file switching
resetTHCI_file:
	mov	ds:[di].THCI_file, 0

	;
	; Get the display number of the display we've switched to.
	; If it matches the currentDisplayNum, the file being viewed
	; hasn't actually changes, it's just been renamed, and we
	; don't need to reinitialize all the lists.
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax				; ds <- NotifyDisplayChange
	mov	ax, ds:[NDC_displayNum]
	call	MemUnlock

	segmov	es, dgroup, cx			; SH 06.01.94
	cmp	es:[currentDisplayNum], ax
	je	noDisplayChange
	mov	es:[currentDisplayNum], ax	; save the new display number
		
	mov	cx, 0
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset THDCFileList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	cx, 0
	mov	si, offset THDFFileList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	cx, 0
	mov	si, offset THDCContextList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage

noDisplayChange:
	ret
THelpControlUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for the TextHelpController

CALLED BY:	THelpControlUpdateUI()
PASS:		*ds:si - controller
		ax - features mask
		bx - hptr of child block
RETURN:		none
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version
	JM	3/18/94		use cx as flag; 
				added UpdateHyperlinkContextList

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ForceUpdateUI	proc	near
	.enter

	call	UpdateDefineFileUI
	;
	; Now set cx=1 to tell UpdateUIForFileChange that
	; it SHOULD update THDCFileList.
	;
	mov	cx, 1
	call	UpdateUIForFileChange
	call	UpdateSetContextUI
	call	UpdateSetHyperlinkUI
	call	UpdateHyperlinkContextList

	.leave
	ret
ForceUpdateUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetContextUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for "Set Context"

CALLED BY:	ForceUpdateUI()
PASS:		*ds:si - controller
		ax - features mask
		bx - hptr of child block
RETURN:		none
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSetContextUI		proc	near
	.enter

	test	ax, mask THCF_SET_CONTEXT
	jz	noSetContextUI
	mov	di, offset THSCContextList	;di <- chunk of list
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	mov	dx, 0				;dx <- use current file
	call	HC_UpdateNameList
noSetContextUI:

	.leave
	ret
UpdateSetContextUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDefineContextUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for "Define Context"

CALLED BY:	ForceUpdateUI()
PASS:		*ds:si - controller
		ax - features mask
		bx - hptr of child block
		cx - 1 if THDCFileList should be updated
		   - 0 if THDCFileList should not be updated
RETURN:		none
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version
	JM	3/18/94		added cx as flag parameter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDefineContextUI		proc	near
	class	TextHelpControlClass
	.enter

	test	ax, mask THCF_DEFINE_CONTEXT
	jz	noDefineContextUI
	push	cx			; save our flag!!!
	;
	; Clear the context name field
	;
	mov	di, offset THDCNameEdit
	call	ClearNameField
	;
	; Update the context list
	;
	call	HC_GetCurFile			;dx <- current file
	mov	di, offset THDCContextList
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	HC_UpdateNameList
	;
	; Check if we should modify THDCFileList.
	; We don't need to if this routine is being run just
	; because the user selected a new file.
	;
	pop	cx			; get our flag!!!
	jcxz	noDefineContextUI
	;
	; Update the file list
	;
	mov	di, offset THDCFileList
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	mov	dx, -1				;dx <- file name list
	call	HC_UpdateNameList
noDefineContextUI:

	.leave
	ret
UpdateDefineContextUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDefineFileUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for "Define File"

CALLED BY:	ForceUpdateUI()
PASS:		*ds:si - controller
		ax - features mask
		bx - hptr of child block
RETURN:		none
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDefineFileUI		proc	near
	.enter

	test	ax, mask THCF_DEFINE_FILE
	jz	noDefineFileUI
	;
	; Clear the file name field
	;
	mov	di, offset THDFFileNameEdit
	call	ClearNameField
	;
	; Update the file list
	;
	mov	di, offset THDFFileList
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	mov	dx, -1				;dx <- file name list
	call	HC_UpdateNameList
noDefineFileUI:

	.leave
	ret
UpdateDefineFileUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSetHyperlinkUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the file list UI for "Set Hyperlink"

CALLED BY:	ForceUpdateUI()
PASS:		*ds:si - controller
		ax - features mask
		bx - hptr of child block
RETURN:		none
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSetHyperlinkUI		proc	near
	.enter

	test	ax, mask THCF_SET_HYPERLINK
	jz	noSetHyperlink
	;
	; Update the list of files
	;
	mov	di, offset THSHFileList		;di <- chunk of list
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	mov	dx, -1				;dx <- file name list
	call	HC_UpdateNameList
	;
	; (re)set the selection, since the update above will clear it
	;
	clr	cx				;cx <- set to first item
	call	HC_SetListSelectionNoIndeterminates
noSetHyperlink:

	.leave
	ret
UpdateSetHyperlinkUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateHyperlinkContextList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the the context list in the "Set Hyperlink" DB

CALLED BY:	ForceUpdateUI()
PASS:		*ds:si - controller
		ax - features mask
		bx - hptr of child block
		dx - file list index #
RETURN:		none
DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateHyperlinkContextList		proc	near
	class	TextHelpControlClass
	.enter

	test	ax, mask THCF_SET_HYPERLINK
	jz	noSetHyperlink
	;
	; Update the corresponding list of contexts
	;
	mov	di, offset THSHContextList	;di <- chunk of list
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	HC_UpdateNameList
noSetHyperlink:

	.leave
	ret
UpdateHyperlinkContextList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Empty status of our text object changed
CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpContextControlClass
		ax - the message

		bp - non-zero if becoming non-empty
		^lcx:dx - OD of text object

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

THelpControlEmptyStatusChanged	method dynamic TextHelpControlClass, \
					MSG_META_TEXT_EMPTY_STATUS_CHANGED

	;
	; Common setup
	;
	call	HC_GetChildBlockAndFeatures

	;
	; Is this the Define Context Name Edit?
	;
	cmp	dx, offset THDCNameEdit
	jne	notDefineContext
	mov	si, offset THDCContextAddTrigger
	call	DoEnableDisable
	mov	di, offset THDCContextList
	mov	si, offset THDCContextRenameTrigger
	call	DoEnableDisableRename
	;
	; "Delete Context" is enabled in the opposite state
	;
	push	bp
	;
	; Make sure there is something selected
	;
	call	flipBP
	push	ax, cx, dx, bp, di
	mov	si, offset THDCContextList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	ax, GIGS_NONE			;any selection?
	pop	ax, cx, dx, bp, di
	jne	gotSelection			;branch if there is selection
	clr	bp				;bp <- force disabled
gotSelection:
	mov	si, offset THDCContextDeleteTrigger
	call	DoEnableDisable
	pop	bp

	;
	; Is this the Define File Name Edit?
	;
notDefineContext:
	cmp	dx, offset THDFFileNameEdit
	jne	notDefineFile
	mov	si, offset THDFFileAddTrigger
	call	DoEnableDisable
	;
	; Don't enable "Delete File" or "Rename File" if the
	; selection is the current file
	;
	cmp	ds:[di].THCI_file, 0		;current file?
	je	notDefineFile			;branch if current file
	mov	di, offset THDFFileList
	mov	si, offset THDFFileRenameTrigger
	call	DoEnableDisableRename
	;
	; "Delete File" is enabled in the opposite state
	;
	push	bp
	call	flipBP
	mov	si, offset THDFFileDeleteTrigger
	call	DoEnableDisable
	pop	bp
notDefineFile:

	ret

flipBP:
	tst	bp				;zero or non-zero?
	mov	bp, -1				;bp <- assume zero
	jz	isZero				;branch if zero
	clr	bp				;bp <- was non-zero
isZero:
	retn
THelpControlEmptyStatusChanged	endm

DoEnableDisableRename	proc	near
	uses	bp, ax, cx, dx
	.enter

	;
	; For "Rename", make sure there is something selected
	;
	push	si, bp
	mov	si, di
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessage
	pop	si, bp
	cmp	ax, GIGS_NONE			;any selection?
	jne	gotSelection			;branch if selection
	clr	bp				;bp <- disable if no selection
gotSelection:
	call	DoEnableDisable

	.leave
	ret
DoEnableDisableRename	endp

DoEnableDisable	proc	near
	uses	ax, dx
	.enter

	;
	; Decide whether to enable or disable
	;
	mov	dl, VUM_NOW			;dl <- VisUpdateMode

	mov	ax, MSG_GEN_SET_ENABLED		;ax <- assume define
	tst	bp
	jnz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax <- redefine
10$:
	call	HC_ObjMessageSend

	.leave
	ret
DoEnableDisable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HC_SetListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set selection in one of our lists

CALLED BY:	UTILITY
PASS:		^lbx:di - OD of list
		*ds:si - controller object
		cx - list entry #
		dx - non-zero for indeterminates
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HC_SetListSelectionNoIndeterminates	proc	near
	clr	dx				;dx <- not indeterminate
	FALL_THRU HC_SetListSelection
HC_SetListSelectionNoIndeterminates		endp

HC_SetListSelection		proc	near
	uses	ax
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	HC_SendEventViaOutput

	.leave
	ret
HC_SetListSelection		endp

HC_SendEventViaOutput	proc	near
	uses	cx, dx, si, di
	.enter
	;
	; We need to mess around a bit here so things stay synchronized.
	; We record the MSG...SET...SELECTION with the list as the
	; destination.  Then we record that message with
	; MSG_META_DISPATCH_EVENT and the output (usually the target text
	; object) as the destination.
	;
	push	si
	mov	si, di				;^lbx:si <- OD of list
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	cx, di				;cx <- recorded message
	clr	dx				;dx <- MessageFlags for event
	call	HC_SendToOutput

	.leave
	ret
HC_SendEventViaOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HC_GetListSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current selection of a list

CALLED BY:	UTILITY
PASS:		di - chunk of list
		*ds:si - controller
RETURN:		ax - list entry # of selection or GIGS_NONE for none
		carry - set if none selected
		bx - hptr of child block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HC_GetListSelection		proc	near
	uses	di, cx, dx, bp, si
	.enter

	call	HC_GetChildBlockAndFeatures
	mov	si, di				;^lbx:si <- OD of list
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HC_GetListSelection		endp

HC_GetChildBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
HC_GetChildBlockAndFeatures	endp

HC_ObjMessageSend	proc	near
	uses	ax, cx, dx, bp, di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
HC_ObjMessageSend	endp

HC_UpdateNameList	proc	near
	uses	ax, dx, bp
	.enter
	;
	; *ds:si - controller
	; ^lbx:di - OD of list
	; cl - VisTextNameType
	; dx - file token (-1 if file name)
	;
	sub	sp, (size VisTextNameCommonParams)
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ss:[bp].VTNCP_object.handle, bx
	mov	ss:[bp].VTNCP_object.chunk, di
	mov	ss:[bp].VTNCP_data.VTND_type, cl
	mov	ss:[bp].VTNCP_data.VTND_file, dx
	mov	dx, (size VisTextNameCommonParams)
	mov	ax, MSG_VIS_TEXT_UPDATE_NAME_LIST
	call	HC_SendToOutputStack
	add	sp, (size VisTextNameCommonParams)

	.leave
	ret
HC_UpdateNameList	endp

HC_GetNameMoniker	proc	near
	uses	ax, dx, bp
	.enter

	;
	; *ds:si - controller
	; ^lbx:di - OD of list
	; cl - VisTextNameType
	; dx - file token (-1 if file name)
	; ax - physical list index
	;
	sub	sp, (size VisTextNameCommonParams)
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ss:[bp].VTNCP_message, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	ss:[bp].VTNCP_object.handle, bx
	mov	ss:[bp].VTNCP_object.chunk, di
	mov	ss:[bp].VTNCP_index, ax
	mov	ss:[bp].VTNCP_data.VTND_type, cl
	mov	ss:[bp].VTNCP_data.VTND_file, dx
	mov	dx, (size VisTextNameCommonParams)
	mov	ax, MSG_VIS_TEXT_GET_NAME_LIST_MONIKER
	call	HC_SendToOutputStack
	add	sp, (size VisTextNameCommonParams)

	.leave
	ret
HC_GetNameMoniker	endp

HC_SendToOutputStack	proc	near
	uses	bx, dx, di
	.enter

	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass		;bx:di <- class ptr
	call	GenControlSendToOutputStack

	.leave
	ret
HC_SendToOutputStack	endp

HC_SendToOutput	proc	near
	uses	bx, dx, di
	.enter

	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass		;bx:di <- class ptr
	call	GenControlSendToOutputRegs

	.leave
	ret
HC_SendToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HC_GetCurFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the entry # of the current file

CALLED BY:	UTILITY
PASS:		*ds:si - controller
RETURN:		dx - entry # of currently selected file
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HC_GetCurFile		proc	near
	class	TextHelpControlClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di <- instance data
	mov	dx, ds:[di].THCI_file		;dx <- current file token

	.leave
	ret
HC_GetCurFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearNameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear a name field
CALLED BY:	UTILITY

PASS:		bx - handle of controller UI
		di - chunk of edit field
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClearNameField	proc	near
	uses	ax, cx, si
	.enter

	mov	si, di
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_DELETE_EVERYTHING
	call	HC_ObjMessageSend

	.leave
	ret
ClearNameField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlAddContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a new context
CALLED BY:	MSG_THCC_ADD_CONTEXT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpContextControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

THelpAddContext	method dynamic TextHelpControlClass, \
						MSG_THC_ADD_CONTEXT
	;
	; Get the type of the context
	;
	mov	di, offset THDCContextTypeList	;di <- chunk of list
	call	HC_GetListSelection
	mov	ch, al				;ch <- VisTextContextType
	;
	; Define the new name, if possible
	;
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	HC_GetCurFile			;dx <- file token
	mov	di, offset THDCNameEdit		;di <- chunk of name edit
	GOTO	DefineNameCommon
THelpAddContext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlAddFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a new file
CALLED BY:	MSG_THCC_ADD_CONTEXT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpContextControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

THelpAddFile	method dynamic TextHelpControlClass, \
						MSG_THC_ADD_FILE

	mov	di, offset THDFFileNameEdit	;di <- chunk of name edit
	mov	cx, VTNT_FILE or (VTCT_FILE shl 8)
	mov	dx, -1				;dx <- define file
	FALL_THRU	DefineNameCommon
THelpAddFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefineNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to define a new name
CALLED BY:	THelpAddContext(), THelpAddFile()

PASS:		*ds:si - instance data
		di - chunk of name field
		cl - VisTextNameType
		ch - VisTextContextType
		dx - file token (-1 if file)
RETURN:		none
DESTROYED:	bp, ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefineNameCommon	proc	far
	.enter

	call	HC_GetChildBlockAndFeatures
	;
	; Define the file
	;
	sub	sp, (size VisTextNameCommonParams)
	mov	bp, sp				;ss:bp <- ptr to params
	movdw	ss:[bp].VTNCP_object, bxdi
	mov	ss:[bp].VTNCP_data.VTND_type, cl
	mov	ss:[bp].VTNCP_data.VTND_contextType, ch
	mov	ss:[bp].VTNCP_data.VTND_file, dx
	mov	ax, MSG_VIS_TEXT_DEFINE_NAME
	mov	dx, (size VisTextNameCommonParams)
	call	HC_SendToOutputStack
	add	sp, dx

	.leave
	ret
DefineNameCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpSHGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for "Set Hyperlink"

CALLED BY:	MSG_THC_SH_GET_MONIKER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		^lcx:dx - list requesting the moniker

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpSHGetMoniker		method dynamic TextHelpControlClass,
						MSG_THC_SH_GET_MONIKER
	mov	di, offset THSHFileList
	call	HC_GetListSelection
	mov	di, dx				;^lbx:di <- list to set moniker
	mov	dx, ax				;dx <- current file
	mov	ax, bp				;ax <- list index of item
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	HC_GetNameMoniker
	ret
THelpSHGetMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpSCGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for "Set Context" list

CALLED BY:	MSG_THC_SC_GET_MONIKER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		^lcx:dx - list requesting the moniker

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpSCGetMoniker		method dynamic TextHelpControlClass,
						MSG_THC_SC_GET_MONIKER
	mov	di, dx				;di <- chunk of list
	mov	dx, 0				;dx <- use current file
	call	HC_GetChildBlockAndFeatures
	mov	ax, bp				;ax <- index
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	HC_GetNameMoniker
	ret
THelpSCGetMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpDCGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for "Define Context" list

CALLED BY:	MSG_THC_DC_GET_MONIKER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		^lcx:dx - list requesting the moniker

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpDCGetMoniker		method dynamic TextHelpControlClass,
						MSG_THC_DC_GET_MONIKER
	mov	di, ds:[di].THCI_file		;di <- file token
	xchg	di, dx				;di <- chunk of list
	call	HC_GetChildBlockAndFeatures
	mov	ax, bp				;ax <- index
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	call	HC_GetNameMoniker
	ret
THelpDCGetMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpDFGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get moniker for "Define File" list

CALLED BY:	MSG_THC_DF_GET_MONIKER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpDFGetMoniker		method dynamic TextHelpControlClass,
						MSG_THC_DF_GET_MONIKER
	mov	di, dx				;di <- chunk of list
	call	HC_GetChildBlockAndFeatures
	mov	ax, bp				;ax <- index
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	mov	dx, -1				;dx <- file token (none)
	call	HC_GetNameMoniker
	ret
THelpDFGetMoniker		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpDFFileChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has selected a different file

CALLED BY:	MSG_THC_DF_FILE_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		cx - current selection

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version
	JM	3/18/94		use cx flag for UpdateUIForFileChange

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpDFFileChanged		method dynamic TextHelpControlClass,
						MSG_THC_DF_FILE_CHANGED
	mov	ds:[di].THCI_file, cx		;save new file
	call	HC_GetChildBlockAndFeatures
	push	cx
	;
	; Now set cx to 0, to tell UpdateUIForFileChange that
	; a new file has been selected so there's NO NEED to
	; update THDCFileList.
	;
	clr	cx
	call	UpdateUIForFileChange
	;
	; If the "current file" entry is selected, disable the "Delete File"
	; trigger, since it would be a bad idea...
	;
	pop	cx				;cx <- selection
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	isCurrent			;branch if current
	mov	ax, MSG_GEN_SET_ENABLED
isCurrent:
	mov	si, offset THDFFileDeleteTrigger
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	HC_ObjMessageSend
	ret
THelpDFFileChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateForFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI for a file change

CALLED BY:	THelpDFFileChanged(), ForceUpdateUI()
PASS:		*ds:si - controller object
		ax - features mask
		bx - child block
		cx - 1 if THDCFileList should be updated
		   - 0 if THDCFileList should not be updated
RETURN:		none
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version
	JM	3/18/94		added cx as flag parameter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateUIForFileChange		proc	near
	class	TextHelpControlClass
	.enter

	;
	; Force lists of contexts to update
	;
	call	UpdateDefineContextUI
	;
	; Make sure all the file lists specify the same file
	;
	call	HC_GetCurFile
	mov	cx, dx
	mov	di, offset THDFFileList
	call	HC_SetListSelectionNoIndeterminates
	mov	di, offset THDCFileList
	call	HC_SetListSelectionNoIndeterminates
	;
	; Set no selection in the context list
	;
	mov	cx, GIGS_NONE			;cx <- no selection
	mov	di, offset THDCContextList
	call	HC_SetListSelectionNoIndeterminates
	;
	; Set the "Delete" trigger not enabled since we have nothing selected
	;
	push	ax, si
	mov	si, offset THDCContextDeleteTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	HC_ObjMessageSend
	pop	ax, si
	;
	; Set the context type list to default to text
	;
	mov	cx, VTCT_TEXT			;cx <- VisTextContextType
	mov	di, offset THDCContextTypeList
	call	HC_SetListSelectionNoIndeterminates

	.leave
	ret
UpdateUIForFileChange		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlDeleteContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the currently selected context

CALLED BY:	MSG_THC_DELETE_CONTEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlDeleteContext		method dynamic TextHelpControlClass,
						MSG_THC_DELETE_CONTEXT
	mov	di, offset THDCContextList
	call	HC_GetListSelection		;ax <- current selection
	;
	; Delete the name
	;
	call	HC_GetCurFile			;dx <- current file
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	GOTO	DeleteNameCommon
THelpControlDeleteContext		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlDeleteFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the currently selected file

CALLED BY:	MSG_THC_DELETE_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlDeleteFile		method dynamic TextHelpControlClass,
						MSG_THC_DELETE_FILE
	;
	; Get the current selection
	;
	mov	di, offset THDFFileList
	call	HC_GetListSelection		;ax <- current selection
	;
	; Set the selection to the first list entry
	;
	push	ax
	clr	cx				;cx <- set to 1st entry
	mov	ax, MSG_THC_DF_FILE_CHANGED
	call	ObjCallInstanceNoLock
	pop	ax
	;
	; Delete the name
	;
	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	mov	dx, -1				;dx <- file name list
	call	DeleteNameCommon

	ret
THelpControlDeleteFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to delete a name (context or file)

CALLED BY:	THelpControlDeleteContext(), THelpControlDeleteFile()
PASS:		cl - VisTextNameType
		dx - file token
		ax - list entry #
		*ds:si - controller
RETURN:		none
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteNameCommon		proc	far
	.enter

	;
	; Delete the name
	;
	sub	sp, (size VisTextNameCommonParams)
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ss:[bp].VTNCP_data.VTND_type, cl
	mov	ss:[bp].VTNCP_data.VTND_file, dx
	mov	ss:[bp].VTNCP_index, ax
	mov	ax, MSG_VIS_TEXT_DELETE_NAME
	mov	dx, (size VisTextNameCommonParams)
	call	HC_SendToOutputStack
	add	sp, dx

	.leave
	ret
DeleteNameCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlRenameContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename the currently selected context

CALLED BY:	MSG_THC_RENAME_CONTEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlRenameContext		method dynamic TextHelpControlClass,
						MSG_THC_RENAME_CONTEXT
	mov	di, offset THDCContextList
	call	HC_GetListSelection		;ax <- current selection

	call	HC_GetCurFile			;dx <- current file
	mov	cl, VTNT_CONTEXT		;cl <- VisTextNameType
	mov	di, offset THDCNameEdit		;di <- chunk of text object
	GOTO	RenameNameCommon
THelpControlRenameContext		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlRenameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename the currently selected file

CALLED BY:	MSG_THC_RENAME_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlRenameFile		method dynamic TextHelpControlClass,
						MSG_THC_RENAME_FILE
	mov	di, offset THDFFileList
	call	HC_GetListSelection		;ax <- current selection

	mov	cl, VTNT_FILE			;cl <- VisTextNameType
	mov	dx, -1				;dx <- file name list
	mov	di, offset THDFFileNameEdit	;di <- chunk of text object
	FALL_THRU	RenameNameCommon
THelpControlRenameFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RenameNameCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to rename a name (context or file)

CALLED BY:	THelpControlRenameContext(), THelpControlRenameFile()
PASS:		cl - VisTextNameType
		dx - file token
		ax - list entry #
		^lbx:di - chunk of text object
		*ds:si - controller
RETURN:		none
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RenameNameCommon		proc	far
	.enter

	;
	; Rename the name
	;
	sub	sp, (size VisTextNameCommonParams)
	mov	bp, sp				;ss:bp <- ptr to params
	movdw	ss:[bp].VTNCP_object, bxdi
	mov	ss:[bp].VTNCP_data.VTND_type, cl
	mov	ss:[bp].VTNCP_data.VTND_file, dx
	mov	ss:[bp].VTNCP_index, ax
	mov	ax, MSG_VIS_TEXT_RENAME_NAME
	mov	dx, (size VisTextNameCommonParams)
	call	HC_SendToOutputStack
	add	sp, dx

	.leave
	ret
RenameNameCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlSetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User did a "Set Context"

CALLED BY:	MSG_THC_SET_CONTEXT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		cx - current selection

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlSetContext		method dynamic TextHelpControlClass,
						MSG_THC_SET_CONTEXT
	mov	dx, (size VisTextSetContextParams)
	sub	sp, dx
	mov	bp, sp				;ss:bp <- params
	mov	ss:[bp].VTSCXP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTSCXP_context, cx
	clr	ss:[bp].VTSCXP_flags		;context is list index
	mov	ax, MSG_VIS_TEXT_SET_CONTEXT
	call	HC_SendToOutputStack
	add	sp, dx
	ret
THelpControlSetContext		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlUnsetAllContexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsets all word -> context mappings for the
		currently selected file.

CALLED BY:	MSG_THC_UNSET_ALL_CONTEXTS
PASS:		*ds:si	= TextHelpControlClass object
		ds:di	= TextHelpControlClass instance data
		ds:bx	= TextHelpControlClass object (same as *ds:si)
		es 	= segment of TextHelpControlClass
		ax	= message #
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set up the parameters for MSG_VIS_TEXT_UNSET_ALL_CONTEXTS.
	  - Pass the virtual range of the whole document 
	    (0-->TEXT_ADDRESS_PAST_END)
	  - Specify that no context is selected for this range.
	Call the text object.
	  - On the VisText side, the range just gets translated
	    from virtual to physical, and then MSG_VIS_TEXT_SET_
	    CONTEXT gets called for that physical range (of the
	    entire document).
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlUnsetAllContexts	method dynamic TextHelpControlClass, 
					MSG_THC_UNSET_ALL_CONTEXTS
	mov	dx, (size VisTextSetContextParams)
	sub	sp, dx
	mov	bp, sp				;ss:bp <- params
	movdw	ss:[bp].VTSCXP_range.VTR_start, 0
	movdw	ss:[bp].VTSCXP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSCXP_context, GIGS_NONE
	clr	ss:[bp].VTSCXP_flags		;context is list index
	mov	ax, MSG_VIS_TEXT_UNSET_ALL_CONTEXTS
	call	HC_SendToOutputStack
	add	sp, dx
	ret
THelpControlUnsetAllContexts	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlSHFileChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user changed the file in the "Set Hyperlink" DB

CALLED BY:	MSG_THC_SH_FILE_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		cx - current selection

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlSHFileChanged		method dynamic TextHelpControlClass,
						MSG_THC_SH_FILE_CHANGED
	call	HC_GetChildBlockAndFeatures
	;
	; Update the list of associated contexts
	;
	mov	dx, cx				;dx <- file list #
	call	UpdateHyperlinkContextList
	;
	; Set the selection to the first context
	;
	clr	cx
	mov	di, offset THSHContextList	;^lbx:di <- context list
	call	HC_SetListSelectionNoIndeterminates
	ret
THelpControlSHFileChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlSetHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User did a "Set Hyperlink"

CALLED BY:	MSG_THC_SET_HYPERLINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		cx - currently selected file

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlSetHyperlink		method dynamic TextHelpControlClass,
						MSG_THC_SET_HYPERLINK
	;
	; Get the currently selected file
	;
	mov	di, offset THSHFileList
	call	HC_GetListSelection
	mov	cx, ax				;cx <- current file
	;
	; Get the currently selected context
	;
	mov	di, offset THSHContextList
	call	HC_GetListSelection

	mov	dx, (size VisTextSetHyperlinkParams)
	sub	sp, dx
	mov	bp, sp				;ss:bp <- params
	mov	ss:[bp].VTSHLP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTSHLP_file, cx
	mov	ss:[bp].VTSHLP_context, ax
	clr	ss:[bp].VTSHLP_flags		;context is list index
	mov	ax, MSG_VIS_TEXT_SET_HYPERLINK
	call	HC_SendToOutputStack
	add	sp, dx
	;
	; Send an apply off to the interaction
	;
	mov	si, offset TextHelpSetHyperlinkBox
	mov	ax, MSG_GEN_APPLY
	call	HC_ObjMessageSend
	ret
THelpControlSetHyperlink		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlDeleteAllHyperlinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes all the hyperlinks for the selected file.

CALLED BY:	MSG_THC_DELETE_ALL_HYPERLINKS
PASS:		*ds:si	= THelpControlClass object
		ds:di	= THelpControlClass instance data
		ds:bx	= THelpControlClass object (same as *ds:si)
		es 	= segment of THelpControlClass
		ax	= message #
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set up the parameters for MSG_VIS_TEXT_DELETE_ALL_HYPERLINKS.
	  - Pass the virtual range of the whole document 
	    (0-->TEXT_ADDRESS_PAST_END)
	  - Specify that no file is selected for this range.
	Call the text object.
	  - On the VisText side, the range just gets translated
	    from virtual to physical, and then MSG_VIS_TEXT_SET_
	    HYPERLINK gets called for that physical range (of the
	    entire document).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	3/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlDeleteAllHyperlinks	method dynamic TextHelpControlClass, 
					MSG_THC_DELETE_ALL_HYPERLINKS
	;
	; Delete hyperlinks for the entire range of the text.
	;
	mov	dx, (size VisTextSetHyperlinkParams)
	sub	sp, dx
	mov	bp, sp				;ss:bp <- params
	movdw	ss:[bp].VTSHLP_range.VTR_start, 0
	movdw	ss:[bp].VTSHLP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSHLP_file, GIGS_NONE
	mov	ss:[bp].VTSHLP_context, 0
	clr	ss:[bp].VTSHLP_flags		;context is list index
	mov	ax, MSG_VIS_TEXT_DELETE_ALL_HYPERLINKS
	call	HC_SendToOutputStack
	add	sp, dx
	ret
THelpControlDeleteAllHyperlinks	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlFollowHyperlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Follow the selected hyperlink

CALLED BY:	MSG_THC_FOLLOW_HYPERLINK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlFollowHyperlink		method dynamic TextHelpControlClass,
						MSG_THC_FOLLOW_HYPERLINK
	mov	dx, (size VisTextFollowHyperlinkParams)
	sub	sp, dx
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ss:[bp].VTFHLP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_FOLLOW_HYPERLINK
	call	HC_SendToOutputStack
	add	sp, dx
	ret
THelpControlFollowHyperlink		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		THelpControlContextChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User selected a different context in the define context box

CALLED BY:	MSG_THC_DC_CONTEXT_CHANGED
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of TextHelpControlClass
		ax - the message

		cx - index of current selection

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
THelpControlContextChanged		method dynamic TextHelpControlClass,
						MSG_THC_DC_CONTEXT_CHANGED
	call	HC_GetChildBlockAndFeatures
	;
	; Enable the "Delete" trigger since we now have something selected
	;
	push	si, cx
	mov	si, offset THDCContextDeleteTrigger
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	HC_ObjMessageSend
	pop	si, cx
	;
	; Ask the text object to update the context type list
	;
	mov	di, offset THDCContextTypeList	;^lbx:di <- OD of list
	call	HC_GetCurFile			;dx <- current file
	;
	; *ds:si - controller
	; ^lbx:di - OD of list
	; dx - file token
	; cx - physical list index
	;
	sub	sp, (size VisTextNameCommonParams)
	mov	bp, sp				;ss:bp <- ptr to params
	mov	ss:[bp].VTNCP_object.handle, bx
	mov	ss:[bp].VTNCP_object.chunk, di
	mov	ss:[bp].VTNCP_index, cx
	mov	ss:[bp].VTNCP_data.VTND_type, VTNT_CONTEXT
	mov	ss:[bp].VTNCP_data.VTND_file, dx
	mov	dx, (size VisTextNameCommonParams)
	mov	ax, MSG_VIS_TEXT_GET_NAME_LIST_NAME_TYPE
	call	HC_SendToOutputStack
	add	sp, (size VisTextNameCommonParams)

	ret
THelpControlContextChanged		endm

TextHelpControlCode ends

endif		; not NO_CONTROLLERS

