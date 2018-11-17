COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiWidth.asm
FILE:		uiWidth.asm

AUTHOR:		Gene Anderson, Jul  6, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/ 6/92		Initial revision

DESCRIPTION:
	Column Width controller

	$Id: uiWidth.asm,v 1.1 97/04/07 11:12:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSColumnWidthControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

WidthControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSWCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSColumnWidthControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSColumnWidthControlClass
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

SSWCGetInfo	method dynamic SSColumnWidthControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSWC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSWCGetInfo	endm

SSWC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSWC_IniFileKey,		; GCBI_initFileKey
	SSWC_gcnList,			; GCBI_gcnList
	length SSWC_gcnList,		; GCBI_gcnCount
	SSWC_notifyTypeList,		; GCBI_notificationList
	length SSWC_notifyTypeList,	; GCBI_notificationCount
	SSWCName,			; GCBI_controllerName

	handle SSColumnWidthUI,		; GCBI_dupBlock
	SSWC_childList,			; GCBI_childList
	length SSWC_childList,		; GCBI_childCount
	SSWC_featuresList,		; GCBI_featuresList
	length SSWC_featuresList,	; GCBI_featuresCount
	SSCWC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif


SSWC_IniFileKey	char	"ssWidth", 0

SSWC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE>

SSWC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE>

;---

SSWC_childList	GenControlChildInfo	\
	<offset ColumnNarrowerTrigger, mask SSCWCF_NARROWER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ColumnWiderTrigger, mask SSCWCF_WIDER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ColumnBestFitTrigger, mask SSCWCF_BEST_FIT,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ColumnWidthDB, mask SSCWCF_CUSTOM,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSWC_featuresList	GenControlFeaturesInfo	\
	<offset ColumnWidthDB, SSWCCustomName, 0>,
	<offset ColumnBestFitTrigger, SSWCBestFitName, 0>,
	<offset ColumnWiderTrigger, SSWCWiderName, 0>,
	<offset ColumnNarrowerTrigger, SSWCNarrowerName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSWCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSColumnWidthControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSColumnWidthControlClass
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

SSWCUpdateUI	method dynamic SSColumnWidthControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	dl, ds:NSSCWHC_flags		;dl <- SSheetWidthHeightFlags
	mov	cx, ds:NSSCWHC_width		;cx <- column width
	call	MemUnlock
	pop	ds
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; Is there a custom width DB?
	;
	test	ax, mask SSCWCF_CUSTOM
	jz	noCustom
	;
	; Is the width indeterminate?
	;
	clr	bp				;bp <- assume has value
	test	dl, mask SSWHF_MULTIPLE_WIDTHS	;multiple widths?
	jz	noMultWidths			;branch if not multiple widths
	dec	bp				;bp <- indeterminate value
noMultWidths:
	push	ax
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	si, offset CWRange		;^lbx:si <- OD of range
	call	SSWC_ObjMessageSend
	pop	ax
noCustom:
	;
	; Is there a narrower trigger?
	;
	test	ax, mask SSCWCF_NARROWER
	jz	noNarrow
	;
	; If we're at the minimum width, disable the narrower trigger,
	; otherwise make sure it is enabled.
	;
	push	ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	cx, SS_COLUMN_WIDTH_MIN		;at minimum width?
	je	gotNarrowMsg			;branch if at minimum
CheckHack <MSG_GEN_SET_ENABLED eq MSG_GEN_SET_NOT_ENABLED-1>
	dec	ax
gotNarrowMsg:
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	mov	si, offset ColumnNarrowerTrigger
	call	SSWC_ObjMessageSend
	pop	ax
noNarrow:
	;
	; Is there a wider trigger?
	;
	test	ax, mask SSCWCF_WIDER
	jz	noWide
	;
	; If we're at the minimum width, disable the narrower trigger,
	; otherwise make sure it is enabled.
	;
	push	ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	cx, SS_COLUMN_WIDTH_MAX		;at minimum width?
	je	gotWideMsg				;branch if at minimum
CheckHack <MSG_GEN_SET_ENABLED eq MSG_GEN_SET_NOT_ENABLED-1>
	dec	ax
gotWideMsg:
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	mov	si, offset ColumnWiderTrigger	;^lbx:si <- OD of trigger
	call	SSWC_ObjMessageSend
	pop	ax
noWide:

	ret
SSWCUpdateUI	endm

SSWC_ObjMessageSend	proc	near
	uses	di, cx, dx, bp
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
SSWC_ObjMessageSend	endp

SSWC_ObjMessageCall	proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
SSWC_ObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSWCChangeWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the selected columns wider or narrower
CALLED BY:	MSG_SSCWC_CHANGE_COLUMN_WIDTHS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSColumnWidthControlClass
		ax - the message

		cx - change in column widths

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSWCChangeWidths	method dynamic SSColumnWidthControlClass, \
						MSG_SSCWC_CHANGE_COLUMN_WIDTHS
	mov	ax, MSG_SPREADSHEET_CHANGE_COLUMN_WIDTH
	mov	dx, SPREADSHEET_ADDRESS_USE_SELECTION
	call	SSCSendToSpreadsheet
	ret
SSWCChangeWidths	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSWCSetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the width (from the spin gadget)
CALLED BY:	MSG_SSWC_SET_COLUMN_WIDTH

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSColumnWidthControlClass
		ax - the message

		dx.cx - current value
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSWCSetWidth	method dynamic SSColumnWidthControlClass, \
						MSG_SSCWC_SET_COLUMN_WIDTH
	mov	ax, MSG_SPREADSHEET_SET_COLUMN_WIDTH
	mov	cx, dx				;cx <- column width
	mov	dx, SPREADSHEET_ADDRESS_USE_SELECTION
	call	SSCSendToSpreadsheet
	ret
SSWCSetWidth	endm

WidthControlCode	ends
