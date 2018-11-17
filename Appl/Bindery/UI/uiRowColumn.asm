COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PCGEOS/J -- pizza
MODULE:		Studio/J
FILE:		uiRowColumn.asm

AUTHOR:		Brian Witt, Sep  7, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 7/93   	Initial revision


DESCRIPTION:
	This file contains the backing code for the line/column position
	controller.  This controller is read-only, and only exists in a
	toolbox/toolbar form.  The GenValue objects for line and columnn
	can only display values up to 32,767.  If larger values are needed,
	then might be changed into GenText and UtilHex32ToAscii convert
	of value into them.


	$Id: uiRowColumn.asm,v 1.1 97/04/04 14:40:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


UseLib	Objects/gValueC.def


;-------------------------------------------------------------------------
;		Variables
;-------------------------------------------------------------------------

	ForceRef  RowColumnName   	; (UI) picked up by client user.

idata	segment
	RowColumnDisplayControlClass
idata	ends

;-------------------------------------------------------------------------
;		Startup Code for RowColumnDisplayControl
;-------------------------------------------------------------------------

ControlCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowColGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Answers the generic portion of the controller's code for
		mode information about the specific controller that we are.
		Copies local data structure into buffer provided by caller.

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= RowColumnDisplayControlClass object
		ds:di	= RowColumnDisplayControlClass instance data
		es 	= segment of RowColumnDisplayControlClass
		cx:dx	= GenControlBuildInfo struct to be filled in.
RETURN:		cx:dx	= (filled in)
DESTROYED:	ax, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		(Based on code from Library/Text/UI/uiLineSpacing.asm)
		(Code is basically 'CopyDupInfoCommon')
		Code choosen to be fast.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowColGetInfo	method dynamic RowColumnDisplayControlClass, 
					MSG_GEN_CONTROL_GET_INFO
	.enter

	mov	si, offset RCD_dupInfo
	segmov	ds, cs, ax		; ds:si = source (local)

	mov	es, cx
	mov	di, dx			; es:si = dest (caller space)

	mov	cx, size GenControlBuildInfo
	rep	movsb

	.leave
	ret
RowColGetInfo	endm


RCD_dupInfo	GenControlBuildInfo	<
	0,				    ; GCBI_flags
	RCD_IniFileKey,				; _initFileKey
	RCD_gcnList,				; _gcnList
	length RCD_gcnList,			; _gcnCount
	RCD_notificationList,			; _notificationList
	length RCD_notificationList,		; _notificationCount
	RCDName, 				; _controlName

	0,					; _dupBlock
	0,					; _childList
	0,					; _childCount
	0,					; _featuresList
	0,					; _featuresCount
	RCD_DEFAULT_FEATURES,			; _features

	handle RowColumnControlToolboxUI,	; _toolBlock
	RCD_toolList,				; _toolList
	length RCD_toolList,			; _toolCount
	RCD_toolFeaturesList,			; _toolFeaturesList
	length RCD_toolFeaturesList,		; _toolFeaturesCount
	RCD_DEFAULT_TOOLBOX_FEATURES,		; _toolFeatures

	0 >				    ; GCBI_helpContext


RCD_IniFileKey	char	"lineColDisp", C_NULL


RCD_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS,GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS,GAGCNLT_APP_TARGET_NOTIFY_CURSOR_POSITION_CHANGE>


RCD_notificationList	NotificationType  \
	<MANUFACTURER_ID_GEOWORKS,GWNT_PAGE_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS,GWNT_CURSOR_POSITION_CHANGE>

; - - - - -


RCD_toolList	GenControlChildInfo  \
	<offset LineValue, 	mask RCDTF_LINE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ColumnValue, 	mask RCDTF_COLUMN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PageValue, 	mask RCDTF_PAGE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ArticleValue, 	mask RCDTF_ARTICLE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

;	Watch out, these are *reverse* order of features record!
;	The assembler allocates bits in a record from high bit to low..
RCD_toolFeaturesList	GenControlFeaturesInfo  \
	<offset ArticleValue,	 ArticlePositionName,	0>,
	<offset PageValue,	 PagePositionName,	0>,
	<offset ColumnValue,	 ColumnPositionName,	0>,
	<offset LineValue,	 RowPositionName,	0>

ControlCode	ends

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RowColUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles notice of attributes' change.  The result of a GCN
		we're listening to has been sent here.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si	= RowColumnDisplayControlClass object
		ds:di	= RowColumnDisplayControlClass instance data
		es 	= segment of RowColumnDisplayControlClass
		ss:bp	= GenControlUpdateUIParams structure ptr	
RETURN:		nothing
DESTROYED:	bx, si, di, es
SIDE EFFECTS:	updates the on-screen UI.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RowColUpdateUI	method dynamic RowColumnDisplayControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	.enter
	assume	es:nothing

	;  Get notification data and type:
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	push	bx			; save for later MemUnlock()

	mov	cx, ss:[bp].GCUUIP_changeType

	; ---------------------------------
	;  Registers  ;
	;   bx = data block handle, cx = change type, ss:bp = GCUUIP ptr ;
	;   ds:si = *object, ds:di = instance data, es:0 = notify block  ;
	;
;firstTry:
	cmp	cx, GWNT_PAGE_STATE_CHANGE
	jne	tryLineNumber

	;	Turning to a new page.
	;	type:	NotifyPageStateChange
	;
	mov	ax, es:[NPSC_currentPage]
	call	UpdatePageValue
	jmp	updateDone

	; ---------------------------------
tryLineNumber:
EC<	cmp	cx, GWNT_CURSOR_POSITION_CHANGE	>
EC<	jne	updateDone			>

	;	Insertation point moved to a new line.  Line/Row are dwords.
	;	type:	VisTextCursorPositionChange
	;
	mov	ax, es:[VTCPC_lineNumber].low
	inc	ax		; values are 0 based, make 1 based for human.
	call	UpdateLineValue

	mov	ax, es:[VTCPC_rowNumber].low
	inc	ax
	call	UpdateColumnValue

					; fall thru..
updateDone:
	pop	bx
	call	MemUnlock		; unlock the notify data

	.leave
	ret
RowColUpdateUI	endm


CommonCode	ends


CommonCode	segment resource

;-------------------------------------------------------------------------
;		Utility routines for RowColumnDisplayControlClass
;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePageValue
		UpdateLineValue
		UpdateColumnValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the UI feature is enabled, then update the integer
		GenValue.

CALLED BY:	RowColUpdateUI
PASS:		ax	= current page number
		ds:si	= *instance of controller.
		ss:bp	= GenControlUpdateUIParams
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	Schedules an update of GenValue UI (queued event).
		Setting a value greater than 32,767 will display a negative.

PSEUDO CODE/STRATEGY:
		get UI object offset.
		if feature is used, then
			get handle of actual UI.
			send message to update integer value when next convient.
		return.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	witt	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePageValue  proc	near
	mov	dx, offset PageValue
	mov	cx, mask RCDTF_PAGE
	GOTO	RCDUpdateValueCommon
UpdatePageValue  endp


UpdateLineValue  proc	near
	mov	dx, offset LineValue
	mov	cx, mask RCDTF_LINE
	GOTO	RCDUpdateValueCommon
UpdateLineValue  endp


UpdateColumnValue	proc	near
	mov	dx, offset ColumnValue
	mov	cx, mask RCDTF_COLUMN
	FALL_THRU	RCDUpdateValueCommon
UpdateColumnValue	endp


; ---------------------------------
;
;	PASS:	ax = integer value to store.
;		cx = feature mask
;		dx = offset of GenValue to set value into.
;		ds:si = *controller instance
;		ss:bp	= GenControlUpdateUIParams
;	RETURNS:    nothing
;	DESTORYS:   ax, bx
;
RCDUpdateValueCommon	proc	near
	uses	cx,si,di,bp
	.enter

	test	ss:[bp].GCUUIP_toolboxFeatures, cx
	jz	done			; feature unused, skip.

	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, dx			; ^lbx:si <- OD of GenValue.
	mov	cx, ax			; cx <- value to set.
	clr	bp			; bp <- not indeterminate.

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	di
	call	ObjMessage		; update when next possible

done:
	.leave
	ret
RCDUpdateValueCommon	endp


CommonCode	ends

; ((eof))




