COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Spreadsheet
FILE:		uiFill.asm

AUTHOR:		Gene Anderson, Aug  6, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/ 6/92		Initial revision


DESCRIPTION:
	Code for SSFillControl
		

	$Id: uiFill.asm,v 1.1 97/04/07 11:12:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSFillControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

FillControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSFCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSFillControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSFillControlClass
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

SSFCGetInfo	method dynamic SSFillControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSFC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSFCGetInfo	endm

SSFC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSFC_IniFileKey,		; GCBI_initFileKey
	SSFC_gcnList,			; GCBI_gcnList
	length SSFC_gcnList,		; GCBI_gcnCount
	SSFC_notifyTypeList,		; GCBI_notificationList
	length SSFC_notifyTypeList,	; GCBI_notificationCount
	SSFCName,			; GCBI_controllerName

	handle SSFillUI,		; GCBI_dupBlock
	SSFC_childList,			; GCBI_childList
	length SSFC_childList,		; GCBI_childCount
	SSFC_featuresList,		; GCBI_featuresList
	length SSFC_featuresList,	; GCBI_featuresCount
	SSFC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSFC_IniFileKey	char	"ssFill", 0

ifdef GPC
SSFC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_FLOAT_FORMAT_CHANGE>


SSFC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_SELECTION_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_FLOAT_FORMAT_CHANGE>
else
SSFC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>


SSFC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_SELECTION_CHANGE>
endif

;---

SSFC_childList	GenControlChildInfo	\
	<offset FillRightTrigger, mask SSFCF_FILL_RIGHT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset FillDownTrigger, mask SSFCF_FILL_DOWN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset FillSeriesDB, mask SSFCF_FILL_SERIES, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSFC_featuresList	GenControlFeaturesInfo	\
	<offset FillSeriesDB, SSFCFillSeriesName, 0>,
	<offset FillDownTrigger, SSFCFillDownName, 0>,
	<offset FillRightTrigger, SSFCFillRightName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSFCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSFillControlClass
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

SSFCUpdateUI	method dynamic SSFillControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; Get the notification block
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	ds
	call	MemLock
	mov	ds, ax
ifdef GPC
	cmp	ss:[bp].GCUUIP_changeType, GWNT_FLOAT_FORMAT_CHANGE
	je	floatFormatChange
endif
	mov	dx, ds:NSSSC_flags		;dx <- SSheetSelectionFlags
	call	MemUnlock
	pop	ds
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	ax, ss:[bp].GCUUIP_features
	;
	; Update "Fill Right", if it exists
	;
	mov	cx, mask SSFCF_FILL_RIGHT
	mov	di, mask SSSF_SINGLE_CELL or mask SSSF_SINGLE_COLUMN
	mov	si, offset FillRightTrigger
	call	FillEnableDisable
	;
	; Update "Fill Down", if it exists
	;
	mov	cx, mask SSFCF_FILL_DOWN
	mov	di, mask SSSF_SINGLE_CELL or mask SSSF_SINGLE_ROW
	mov	si, offset FillDownTrigger
	call	FillEnableDisable
	;
	; Update "Fill Series", if it exists
	;
	mov	cx, mask SSFCF_FILL_SERIES
	test	ax, cx
	jz	done				;branch if DB doesn't exist
	mov	di, mask SSSF_SINGLE_CELL
ifdef GPC
	mov	si, offset FillSeriesDB		;disable menu button also
else
	mov	si, offset FillSeriesStuff
endif
	call	FillEnableDisable
	test	dx, mask SSSF_SINGLE_CELL	;single cell selected?
	jnz	done				;if single cell, we're done
	;
	; Update the "Fill By" list
	;
	mov	cx, mask SSFCF_FILL_SERIES
	mov	di, mask SSSF_SINGLE_CELL or mask SSSF_SINGLE_COLUMN
	mov	si, offset FillByColumnsEntry
	call	FillEnableDisable
	mov	cx, mask SSFCF_FILL_SERIES
	mov	di, mask SSSF_SINGLE_CELL or mask SSSF_SINGLE_ROW
	mov	si, offset FillByRowsEntry
	call	FillEnableDisable
	;
	; If we've disabled one or the other of "Rows" and "Columns",
	; set the non-disabled one to be on.
	;
	mov	cx, mask SSFF_ROWS		;cx <- assume setting "by rows"
	test	dx, mask SSSF_SINGLE_ROW
	jz	setByList
	clr	cx				;cx <- setting "by columns"
setByList:
	mov	si, offset FillByList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				;dx <- not indeterminate
	call	SSFC_ObjMessageCall
done:
	ret

ifdef GPC
floatFormatChange:
	mov	ax, ds:[NFFC_format]
	call	MemUnlock
	pop	ds
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; set default unit based on cell formatting
	;
	mov	cx, length formatMappings
	clr	di, dx
checkMappings:
	mov	dl, cs:formatMappings[di].FUMI_unit	; assume found
	cmp	ax, cs:formatMappings[di].FUMI_format
	je	foundMapping
nextMapping:
	add	di, size FormatUnitMapItem
	loop	checkMappings
	mov	dx, SSFT_NUMBER			; default to number
foundMapping:
	mov	cx, dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	si, offset FillTypeList
	call	SSFC_ObjMessageCall
	ret
endif
SSFCUpdateUI	endm

ifdef GPC
FormatUnitMapItem	struct
	FUMI_format	FormatIdType
	FUMI_unit	SpreadsheetSeriesFillType
FormatUnitMapItem	ends

formatMappings	FormatUnitMapItem \
	<FORMAT_ID_DATE_LONG, SSFT_DAY>,
	<FORMAT_ID_DATE_LONG_CONDENSED, SSFT_DAY>,
	<FORMAT_ID_DATE_LONG_NO_WKDAY, SSFT_DAY>,
	<FORMAT_ID_DATE_LONG_NO_WKDAY_CONDENSED, SSFT_DAY>,
	<FORMAT_ID_DATE_SHORT, SSFT_DAY>,
	<FORMAT_ID_DATE_SHORT_ZERO_PADDED, SSFT_DAY>,
	<FORMAT_ID_DATE_LONG_MD, SSFT_DAY>,
	<FORMAT_ID_DATE_LONG_MD_NO_WKDAY, SSFT_DAY>,
	<FORMAT_ID_DATE_SHORT_MD, SSFT_DAY>,
	<FORMAT_ID_DATE_LONG_MY, SSFT_MONTH>,
	<FORMAT_ID_DATE_SHORT_MY, SSFT_MONTH>,
	<FORMAT_ID_DATE_YEAR, SSFT_YEAR>,
	<FORMAT_ID_DATE_MONTH, SSFT_MONTH>,
	<FORMAT_ID_DATE_DAY, SSFT_DAY>,
	<FORMAT_ID_DATE_WEEKDAY, SSFT_WEEKDAY>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable fill features based on selection

CALLED BY:	SSFCUpdateUI()
PASS:		^lbx:si - OD of object to enable/disable
		ax - current features
		dx - current SSheetSelectionFlags
		cx - feature to test for
		di - SSheetSelectionFlags *not* allowed
RETURN:		none
DESTROYED:	cx, di, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillEnableDisable		proc	near
	uses	ax, dx, bp
	.enter

	test	ax, cx				;does feature exist?
	jz	noFeature			;branch if feature doesn't exist
	mov	ax, MSG_GEN_SET_ENABLED		;ax <- assume enabling
	test	dx, di				;any flags we don't allow?
	jz	doEnable			;branch if flags OK
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;ax <- disabling
doEnable:
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	SSFC_ObjMessageCall
noFeature:
	.leave
	ret
FillEnableDisable		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSFCSetUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle user change "Units"

CALLED BY:	MSG_SSFC_SET_UNITS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSFillControlClass
		ax - the message

		cx - SpreadsheetSeriesFillType

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSFCSetUnits		method dynamic SSFillControlClass,
						MSG_SSFC_SET_UNITS
	call	SSCGetChildBlockAndFeatures	;bx <- child block
	;
	; If "Number" is selected, enable "Progression", otherwise
	; disable it.  This is because setting a Geometric progression
	; for a date doesn't make much sense...
	;
	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, SSFT_NUMBER
	je	doEnable
	mov	ax, MSG_GEN_SET_NOT_ENABLED
doEnable:
	mov	si, offset FillStepList		;^lbx:si <- OD of list
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	SSFC_ObjMessageCall
	ret
SSFCSetUnits		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSFCDoFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a fill, with no progression

CALLED BY:	MSG_SSFC_DO_FILL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSFillControlClass
		ax - the message

		cl - SpreadsheetSeriesFillFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSFCDoFill		method dynamic SSFillControlClass,
						MSG_SSFC_DO_FILL
	mov	ax, MSG_SPREADSHEET_FILL_RANGE
	call	SSCSendToSpreadsheet
	ret
SSFCDoFill		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSFCDoSeries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a series fill

CALLED BY:	MSG_SSFC_DO_SERIES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSFillControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 9/92		Initial version
	witt	11/11/93	DBCS-ized buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSFCDoSeries		method dynamic SSFillControlClass,
						MSG_SSFC_DO_SERIES
	call	SSCGetChildBlockAndFeatures
SBCS<	sub	sp, (size SpreadsheetSeriesFillParams)+FLOAT_TO_ASCII_NORMAL_BUF_LEN	>
DBCS<	sub	sp, (size SpreadsheetSeriesFillParams)+(FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar))	>
CheckHack <FLOAT_TO_ASCII_NORMAL_BUF_LEN gt MAX_DIGITS_FOR_NORMAL_NUMBERS+MAX_CHARS_FOR_EXPONENT-1>
	mov	bp, sp				;ss:bp <- ptr to params
	push	si
	;
	; Collect the state of the various lists
	;
	mov	si, offset FillByList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSFC_ObjMessageCall
	mov	ss:[bp].SSFP_flags, al		;store flags
	mov	si, offset FillStepList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSFC_ObjMessageCall
	ornf	ss:[bp].SSFP_flags, al		;combine flags
	mov	si, offset FillTypeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSFC_ObjMessageCall
	mov	ss:[bp].SSFP_type, al		;store type
	;
	; Get the text from the "Step Value"
	;
	push	bp
	mov	si, offset FillStepValue	;^lbx:si <- OD of text
	add	bp, (size SpreadsheetSeriesFillParams)
	mov	dx, ss				;dx:bp <- ptr to buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	SSFC_ObjMessageCall
	mov	si, bp
	pop	bp
	;
	; Attempt to parse it into a float
	;
	push	ds
	mov	es, dx
	lea	di, ss:[bp].SSFP_stepValue	;es:di <- ptr to result buffer
	mov	ds, dx				;ds:si <- ptr to text
	mov	al, mask FAF_STORE_NUMBER	;al <- FloatAsciiToFloatFlags
	call	FloatAsciiToFloat
	pop	ds
	pop	si				;*ds:si <- ourselves
	jc	quit				;branch if error
	;
	; Send the results off to the spreadsheet
	;
	mov	ax, MSG_SPREADSHEET_FILL_SERIES
	mov	dx, (size SpreadsheetSeriesFillParams)
	call	SSCSendToSpreadsheetStack
quit:
SBCS<	add	sp, (size SpreadsheetSeriesFillParams)+FLOAT_TO_ASCII_NORMAL_BUF_LEN	>
DBCS<	add	sp, (size SpreadsheetSeriesFillParams)+(FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar))	>
	ret
SSFCDoSeries		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSFC_ObjMessageCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub to call ObjMessage

CALLED BY:	UTILITY
PASS:		^lbx:si <- OD of object
		ax - message to send
		cx,dx,bp - data for message
RETURN:		depends on message (ax,cx,dx)
DESTROYED:	depends on message (ax,cx,dx)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSFC_ObjMessageCall		proc	near
	uses	bp, di
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
SSFC_ObjMessageCall		endp

FillControlCode ends
