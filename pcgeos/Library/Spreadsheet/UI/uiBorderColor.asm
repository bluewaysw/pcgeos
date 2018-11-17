COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiBorderColor.asm
FILE:		uiBorderColor.asm

AUTHOR:		Gene Anderson, Jul 30, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/30/92		Initial revision

DESCRIPTION:
	

	$Id: uiBorderColor.asm,v 1.1 97/04/07 11:12:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GC_Data	union
    GCD_dword	dword
    GCD_optr	optr
GC_Data	end

GC_NewField	struct
    GCNF_offset	byte
    GCNF_size	byte
    GCNF_data	GC_Data
GC_NewField	ends

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSBorderColorControlClass		;declare the class record
SpreadsheetClassStructures	ends


;---------------------------------------------------

BorderControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSBorderColorControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderColorControlClass
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

SSBorderColorGetInfo	method dynamic SSBorderColorControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	;
	; first call our superclass to get the color selector's stuff
	;
	pushdw	cxdx
	mov	di, offset SSBorderColorControlClass
	call	ObjCallSuperNoLock
	popdw	esdi
	;
	; Now fill in our parts of it
	;
	mov	si, offset SSBCC_newFields
	mov	cx, length SSBCC_newFields
	call	CopyFieldsToBuildInfo
	ret

SSBorderColorGetInfo	endm

SSBCC_newFields	GC_NewField	\
	<offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
	<offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword SSBCC_IniFileKey>>,
	<offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword SSBCC_gcnList>>,
	<offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword size SSBCC_gcnList>>,
	<offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword SSBCC_notifyList>>,
	<offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size SSBCC_notifyList>>,
	<offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr SSBCCName>>,
	<offset GCBI_features, size GCBI_features,
				<GCD_dword SSBCC_DEFAULT_FEATURES>>,
	<offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword SSBCC_helpContext>>

SSBCC_helpContext	char	"dbSSBrdrColor", 0

SSBCC_IniFileKey	char	"borderColor", 0

SSBCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_ATTR_CHANGE>

SSBCC_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_CELL_ATTR_CHANGE>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyFieldsToBuildInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy fields from a table of GC_NewField structures to
		a GenControlBuildInfo structure
CALLED BY:	SSBCCGetInfo()

PASS:		es:di - ptr to GenControlBuildInfo
		cs:si - table of GC_NewField structures
		cx - length of table
RETURN:		none
DESTROYED:	ax, cx, si, di, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version
	eca	7/30/92		copied for spreadsheet

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyFieldsToBuildInfo	proc	near

	segmov	ds, cs				;ds:si <- source

copyLoop:
	push	cx, si, di
	clr	ax
	lodsb					;ax <- offset
	add	di, ax
	clr	ax
	lodsb
	mov_tr	cx, ax				;cx <- # bytes
	rep movsb

	pop	cx, si, di
	add	si, size GC_NewField		;ds:si <- next GC_NewField
	loop	copyLoop

	ret

CopyFieldsToBuildInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCOutputAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	MSG_GEN_OUTPUT_ACTION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderColorControlClass
		ax - the message

		cx:dx - destination (or travel option)
		bp - event

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCOutputAction	method dynamic SSBorderColorControlClass, \
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset SSBorderColorControlClass
	FALL_THRU	ColorInterceptAction
SSBCOutputAction	endm

;---

ColorInterceptAction	proc	far
	push	cx, si
	mov	bx, bp
	call	ObjGetMessageInfo			;ax = message
	pop	cx, si

	cmp	ax, MSG_META_COLORED_OBJECT_SET_COLOR
	jz	handleOurself
	cmp	ax, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	jz	handleOurself
	cmp	ax, MSG_META_COLORED_OBJECT_SET_PATTERN
	jz	handleOurself

	mov	ax, MSG_GEN_OUTPUT_ACTION
	GOTO	ObjCallSuperNoLock

handleOurself:
	;
	; dispatch the event to ourself
	;
	mov	cx, ds:[LMBH_handle]		;cx:si = dest
	call	MessageSetDestination
	clr	di				;no flags
	call	MessageDispatch
	ret
ColorInterceptAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	MSG_META_COLORED_OBJECT_SET_COLOR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderColorControlClass
		ax - the message

		dxcx - color

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCSetColor	method dynamic SSBorderColorControlClass, \
					MSG_META_COLORED_OBJECT_SET_COLOR
	mov	ax, MSG_SPREADSHEET_SET_CELL_BORDER_COLOR
	call	SSCSendToSpreadsheet
	ret
SSBCSetColor	endm

;---

SSBCSetDrawMask	method dynamic	SSBorderColorControlClass,
					MSG_META_COLORED_OBJECT_SET_DRAW_MASK

	mov	ax, MSG_SPREADSHEET_SET_CELL_BORDER_GRAY_SCREEN
	call	SSCSendToSpreadsheet
	ret
SSBCSetDrawMask	endm

;---

SSBCSetPattern	method dynamic	SSBorderColorControlClass,
					MSG_META_COLORED_OBJECT_SET_PATTERN

	mov	ax, MSG_SPREADSHEET_SET_CELL_BORDER_PATTERN
	call	SSCSendToSpreadsheet
	ret
SSBCSetPattern	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSBorderColorControl
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderColorControlClass
		ax - the message
		ss:bp - GenControlUpdateUIParams
			GCUUIP_manufacturer
			GCUUIP_changeType
			GCUUIP_dataBlock
			GCUUIP_toolInteraction
			GCUUIP_features
			GCUUIP_toolboxFeatures
			GCUUIP_childBlock

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBorderColorUpdateUI	method dynamic SSBorderColorControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax				;ds <- seg addr of notification
	;
	; Get border color from NotifySSheetCellAttrsChange
	;
	mov	al, ds:NSSCAC_borderGrayScreen
	movdw	dxcx, ds:NSSCAC_borderColor
	push	{word} ds:NSSCAC_borderPattern
	mov	di, ds:NSSCAC_borderColorIndeterminates
	call	MemUnlock
	pop	bx				;bx <- NSSCAC_borderPattern
	pop	ds
	;
	; dxcx - color
	; al - SystemDrawMask
	; bx - GraphicPattern
	; di - VisTextCharAttrFlags
	;	VTCAF_MULTIPLE_COLORS
	;	VTCAF_MULTIPLE_GRAY_SCREENS
	;	VTCAF_MULTIPLE_PATTERNS
	call	UpdateColorCommon
	ret
SSBorderColorUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateColorCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for a color controller
CALLED BY:	SSBCUpdateUI()

PASS: 		*ds:si - controller
		ss:bp - GenControlUpdateUIParams
		dxcx - color
		al - SystemDrawMask
		bx - GraphicPattern
		di - VisTextCharAttrFlags
			VTCAF_MULTIPLE_COLORS
			VTCAF_MULTIPLE_GRAY_SCREENS
			VTCAF_MULTIPLE_PATTERNS
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateColorCommon	proc	near
	uses	bp
	.enter

	push	bx				;save hatch
	push	ax				;save draw mask
	;
	; update color
	;
	mov	bp, di
	andnf	bp, mask SCF_BORDER_COLORS	;bp <- indeterminate
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
	call	ObjCallInstanceNoLock
	;
	; update draw mask
	;
	pop	cx
	mov	dx, di
	andnf	dx, mask SCF_BORDER_GRAY_SCREENS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_DRAW_MASK
	call	ObjCallInstanceNoLock
	;
	; update hatch
	;
	pop	cx
	mov	dx, di
	andnf	dx, mask SCF_BORDER_PATTERNS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_PATTERN
	call	ObjCallInstanceNoLock

	.leave
	ret
UpdateColorCommon	endp

BorderControlCode	ends
