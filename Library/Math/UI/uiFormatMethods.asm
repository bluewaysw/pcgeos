
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiFormatMain.asm

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial revision

DESCRIPTION:

NOTES:
    Sequence of events:

	MSG_GEN_CONTROL_GET_INFO:
	    handled entirely by controller

	MSG_GEN_CONTROL_UPDATE_UI:
	    controller sends message to output
	    app initializes FormatInfoStruc
		with FIS_userDefFmtArrayFileHan and FIS_userDefFmtArrayBlkHan
	    app calls FloatFormatInitFormatList
	    FloatFormatInitFormatList will:
		get number of list items
		initialize the dynamic list
	    app SHOULD NOT call FloatFormatProcessFormatSelected

	dynamic list requests:
	    controller will send info to app
	    app will bundle info and user def array and call a routine in
		the controller to do the right thing
	
	User changes selection in the format list:
	    if selection is within the pre-defined list then
		update the sample area
	    else
		get app to update the sample area
	    endif
	    (write routine that packages message for app to send back to the
	    controller)

	User clicks on "New Format" button:
	    app calls controller with FormatInfoStruc to initialize the DB
	
	User edits an existing format:
	    app calls controller with FormatInfoStruc to initialize the DB
	
	User deletes an existing format:
	    app calls controller with FormatInfoStruc to update strucs
	    app needs to send both FloatFormat notifications to update UI

	User defines a new format or changes a format and clicks on OK:
	    get info from DB and create a FormatInfoStruc
	    pass FormatInfoStruc to app
	    app calls controller with FormatInfoStruc to add new format
	    app needs to send both FloatFormat notifications to update UI
		
	$Id: uiFormatMethods.asm,v 1.1 97/04/05 01:23:29 newdeal Exp $

-------------------------------------------------------------------------------@

MathClassStructures	segment	resource
	FloatFormatClass
MathClassStructures	ends

FloatFormatCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetInfo

DESCRIPTION:	The GenControl object calls the message to get information about
		the controller.  The structure returned allows GenControlClass
		to implement a wide range of default behavior.

CALLED BY:	Many default GenControlClass methods as well as methods from
		other objects (such as the toolbox).

PASS:		*ds:si - instance data
		es - segment of FloatFormatClass
		ax - the message
		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		none

DESTROYED:	bx,di,si,ds,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	copy FC_dupInfo data into cx:dx

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetInfo	method dynamic	FloatFormatClass,
			MSG_GEN_CONTROL_GET_INFO
	mov	si, offset FC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep	movsb
	ret
FloatFormatGetInfo	endm

FC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	FC_iniFileKey,				; GCBI_initFileKey
	FC_gcnList,				; GCBI_gcnList
	length FC_gcnList,			; GCBI_gcnCount
	FC_notifyTypeList,			; GCBI_notificationList
	length FC_notifyTypeList,		; GCBI_notificationCount
	FCName,					; GCBI_controllerName

	handle FloatFormatUI,			; GCBI_dupBlock
	FC_childList,				; GCBI_childList
	length FC_childList,			; GCBI_childCount
	FC_featuresList,			; GCBI_featuresList
	length FC_featuresList,			; GCBI_featuresCount
	FLOAT_CTRL_DEFAULT_FEATURES,		; GCBI_features

	0,					; GCBI_toolBlock
	0,					; GCBI_toolList
	0,					; GCBI_toolCount
	0,					; GCBI_toolFeaturesList
	0,					; GCBI_toolFeaturesCount
	0,
	FC_helpContext>				; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
MathControlInfoXIP	segment	resource
endif

FC_helpContext	char	"dbNumFormat", 0

FC_iniFileKey	char	"floatFormat", 0

FC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_FLOAT_FORMAT_INIT>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_FLOAT_FORMAT_CHANGE>

FC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_FLOAT_FORMAT_INIT>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_FLOAT_FORMAT_CHANGE>

ifdef GPC_ONLY
FC_childList	GenControlChildInfo	\
	<offset ChooseFormatDB, mask FCF_FORMAT_LIST or mask FCF_DEFINE_FORMATS, mask GCCF_IS_DIRECTLY_A_FEATURE>
else
FC_childList	GenControlChildInfo	\
	<offset ChooseFormatDB, mask FCF_FORMAT_LIST, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset UIFmtMainTriggersGroup, mask FCF_DEFINE_FORMATS, mask GCCF_IS_DIRECTLY_A_FEATURE>
endif

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

FC_featuresList	GenControlFeaturesInfo	\
	<offset UIFmtMainTriggersGroup, DefineFormatName, 0>,
	<offset ChooseFormatDB, ChooseFormatName, 0>

if FULL_EXECUTE_IN_PLACE
MathControlInfoXIP	ends
endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatUpdateUI

DESCRIPTION:	Handle notification of attributes change.

CALLED BY:	Sent by GenControlClass in the default handler for
		MSG_META_NOTIFY_WITH_DATA_BLOCK.

PASS:		*ds:si - instance data
		ss:bp - GenControlUpdateUIParams
		data blk - UpdateUIDataBlk

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si,bp,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NotifyFloatFormatChange      struc
		NFFC_vmFileHan   word
		NFFC_vmBlkHan    word
		NFFC_format      word
		NFFC_count	 word
	NotifyFloatFormatChange      ends

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatUpdateUI	method dynamic	FloatFormatClass,
			MSG_GEN_CONTROL_UPDATE_UI
	.enter
	
	mov	bx, ss:[bp].GCUUIP_dataBlock	; bx <- data blk han
	call	MemLock
	mov	es, ax				; es:0<-NotifyFloatFormatChange
	push	bx				; save data blk han
	mov	cx, es:NFFC_format

EC<	cmp	cx, FORMAT_ID_INDETERMINATE >
EC<	je	formatOK >
EC<	cmp	cx, FORMAT_ID_PREDEF >
EC<	jb	formatOK >
EC<	cmp	cx, FORMAT_ID_TIME_HM_24HR >
EC<	ERROR_A	FLOAT_FORMAT_BAD_PARAMS >
EC< formatOK: >

	;
	; create a FormatInfoStruc in case format is user defined
	; push/pulls intentionally indented
	;
    push	si
	call	GetChildBlock
      push	bx
	mov	di, es:NFFC_vmFileHan		; di <- file han
	mov	si, es:NFFC_vmBlkHan		; si <- blk han

	mov	ax, size FormatInfoStruc
	push	cx				; save token
	mov	cx, mask HF_SWAPABLE or ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8)
	call	MemAlloc
	pop	cx				; retrieve token
	mov	es, ax
	mov	es:FIS_signature, FORMAT_INFO_STRUC_ID
      pop	es:FIS_childBlk
	mov	es:FIS_chooseFmtListChunk, offset FormatsList
	mov	es:FIS_userDefFmtArrayFileHan, di
	mov	es:FIS_userDefFmtArrayBlkHan, si
	mov	es:FIS_curToken, cx
    pop		si
    push	bx				; save FIS handle

	;-----------------------------------------------------------------------
	; branch depending of type
	;
	cmp	ss:[bp].GCUUIP_changeType, GWNT_FLOAT_FORMAT_INIT
	je	forceReinit
 
	;
	; intercept indeterminate states
	;
	cmp	cx, FORMAT_ID_INDETERMINATE
	jne	determinate
	call	IndeterminateStateDisableGadgets
	jmp	short done

determinate:
	;
	; else GCUUIP_changeType = GWNT_FLOAT_FORMAT_CHANGE
	; change the selection
	;
	call	FloatFormatGetListEntryWithToken	; cx <- list entry num
	mov	es:FIS_curSelection, cx
	call	GetChildBlockAndFeatures
	mov	es:FIS_features, ax			; ax <- feature set
	mov	di, offset FormatsList			; ^lbx:di <- list
	clr	dx					; not indeterminate
	call	SetEntryPosViaOutput
	call	FloatFormatProcessFormatSelected
	jmp	short done
	
forceReinit:
	;
	; GCUUIP_changeType = GWNT_FLOAT_FORMAT_INIT
	; get target to reinit the FormatsList
	;
	call	FloatFormatGetListEntryWithToken	; cx <- list entry num
	mov	es:FIS_curSelection, cx

	mov	ax, MSG_FLOAT_CTRL_UPDATE_UI
	mov	bx, ss:[bp].GCUUIP_childBlock
	call	FISSendToOutput

done:
    pop		bx				; retrieve FIS handle
	call	MemFree

	pop	bx				; retrieve data blk han
	call	MemUnlock			; unlock data blk

	.leave
	ret
FloatFormatUpdateUI	endm



COMMENT @-----------------------------------------------------------------------

FUNCTION:	IndeterminateStateDisableGadgets

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFormatUpdateUI)

PASS:		*ds:si	- instance data

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

IndeterminateStateDisableGadgets	proc	near

	call	GetChildBlock
	;
	; disable format rep
	;
	mov	di, offset UIFmtMainFormatStr
	call	SetNotEnabled
	;
	; disable samples
	;
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample1Group
	call	SetNotEnabled
	mov	di, offset UIFmtMainSample2Group
	call	SetNotEnabled
else
	mov	di, offset UIFmtMainSample1
	call	SetNotEnabled
	mov	di, offset UIFmtMainSample2
	call	SetNotEnabled
endif

	;
	; If no FCF_DEFINE_FORMATS features are present, don't
	; try to disable them.
	;
	test	es:FIS_features, mask FCF_DEFINE_FORMATS
	jz	noTriggers

	;
	; disable user-defined format triggers
	;
	mov	di, offset UIFmtMainTriggerCreate
	call	SetNotEnabled
	mov	di, offset UIFmtMainTriggerDelete
	call	SetNotEnabled
	mov	di, offset UIFmtMainTriggerEdit
	call	SetNotEnabled

noTriggers:
	;
	; disable list selection
	;
	mov	dx, -1				; specify indeterminate
	mov	di, offset FormatsList		; ^lbx:di <- list
	call	SetEntryPosViaOutput

	ret
IndeterminateStateDisableGadgets	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatRequestMoniker

DESCRIPTION:	

CALLED BY:	EXTERNAL (MSG_FC_REQUEST_MONIKER)

PASS:		^lcx:dx - the dynamic list requesting the moniker
		bp - position of the item requested

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatRequestMoniker	method	dynamic FloatFormatClass,
				MSG_FC_REQUEST_MONIKER
	mov	ax, MSG_FLOAT_CTRL_REQUEST_MONIKER
	call	GetChildBlock		; bx <- child block
	mov	cx, bp			; no selection
	call	FISSendToOutput
	ret
FloatFormatRequestMoniker	endm

COMMENT @---------------------------------------------------------------------

FUNCTION:	FloatFormatVisOpen

DESCRIPTION:	

CALLED BY:	EXTERNAL (MSG_VIS_OPEN)

PASS:		bp - top window flag

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/98		Initial version

-----------------------------------------------------------------------------@

ifdef GPC_ONLY

FloatFormatVisOpen	method	dynamic FloatFormatClass, MSG_VIS_OPEN
	mov	di, 2000
	call	ThreadBorrowStackSpace
	push	di
	;
	; make text objects not editable/selectable
	;
	push	bp, si
	call	GetChildBlock
	mov	cx, NUM_MAIN_TEXT_OBJS
	clr	di
textLoop:
	push	cx, di
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	clr	cl				; set
	mov	ch, mask VTS_EDITABLE or mask VTS_SELECTABLE ; clear
	mov	si, cs:mainTextObjList[di]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	add	di, size lptr
	loop	textLoop

	pop	bp, si
	mov	ax, MSG_VIS_OPEN
	mov	di, offset FloatFormatClass
	call	ObjCallSuperNoLock

	pop	di
	call	ThreadReturnStackSpace
	ret
FloatFormatVisOpen	endm

mainTextObjList	label	lptr
	lptr	offset	UIFmtMainFormatStr,
		offset	UIFmtMainSample1Base,
		offset	UIFmtMainSample1Sample,
		offset	UIFmtMainSample2Base,
		offset	UIFmtMainSample2Sample
NUM_MAIN_TEXT_OBJS = ($-mainTextObjList) / (size lptr)

endif

FloatFormatCode	ends
