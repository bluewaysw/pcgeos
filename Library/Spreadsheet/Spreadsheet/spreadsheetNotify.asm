COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		spreadsheetNotify.asm
FILE:		spreadsheetNotify.asm

AUTHOR:		Gene Anderson, Dec 20, 1991

ROUTINES:
	Name				Description
	----				-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/20/91		Initial revision

DESCRIPTION:
	

	$Id: spreadsheetNotify.asm,v 1.1 97/04/07 11:13:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NotifStruct	struct
    NS_routine	nptr.near
    NS_size	word				;0 to not allocate
    NS_gcnType	GeoWorksNotificationType
    NS_appType	GeoWorksGenAppGCNListType
NotifStruct	ends

DrawCode	segment	resource

SS_SendNotificationSelectChange	proc	near
	uses	ax
	class	SpreadsheetClass
	.enter

	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	noNotify
	mov	ax, SNFLAGS_SELECTION_CHANGE
	call	SS_SendNotification
noNotify:

	.leave
	ret
SS_SendNotificationSelectChange	endp

SS_SendNotificationSelectAdd	proc	near
	uses	ax
	class	SpreadsheetClass
	.enter

	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	noNotify
	mov	ax, SNFLAGS_SELECTION_ADD
	call	SS_SendNotification
noNotify:

	.leave
	ret
SS_SendNotificationSelectAdd	endp

DrawCode	ends

AttrCode	segment	resource

SS_SendNotificationBogusWidth	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	mov	ax, size NotifySSheetCellWidthHeightChange
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	jc	done				; allocation error, bail
	push	ds
	mov	ds, ax
						; indeterminate
	mov	ds:NSSCWHC_flags, mask SSWHF_MULTIPLE_HEIGHTS or \
				mask SSWHF_MULTIPLE_WIDTHS
	mov	ds:NSSCWHC_height, 0
	mov	ds:NSSCWHC_width, 0
	pop	ds
	lea	di, cs:bogusWidthNotif
	call	SendNotification
done:
	.leave
	ret
SS_SendNotificationBogusWidth	endp

bogusWidthNotif	NotifStruct	\
	<GenCellWidthHeightNotify,
		size NotifySSheetCellWidthHeightChange,
		GWNT_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE>

SS_SendNullParaAttrNotification	proc	far
	uses	ax, bx, cx, dx, di
	.enter

	clr	bx				;bx <- NULL event
	mov	di, offset nullParaNotif
	call	SendNotification
done:
	.leave
	ret
SS_SendNullParaAttrNotification	endp

nullParaNotif	NotifStruct	\
	<GenCellWidthHeightNotify,
		size VisTextNotifyParaAttrChange,
		GWNT_TEXT_PARA_ATTR_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SS_SendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out various notification(s)
CALLED BY:	UTILITY

PASS:		ds:si - Spreadsheet instance data
		ax - SpreadsheetNotifyFlags for notification(s) to send
		   - 0 to clear out status events on all TARGET GCN Lists only
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SS_Quit	proc	far
	ret
SS_Quit	endp

SS_SendNotification	proc	far
	class	SpreadsheetClass
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	SS_Quit
	FALL_THRU	SS_ForceNotification
SS_SendNotification	endp

SS_ForceNotification	proc	far
	uses	ax, bx, cx, di, es
notifyFlags	local	SpreadsheetNotifyFlags	push	ax

	.enter

EC <	call	ECCheckInstancePtr		;>

	;
	; Are we sending a Spreadsheet attribute notification?
	;
	clr	bx				;bx <- assume spreadsheet
	test	ax, SNFLAGS_REQUIRE_SPREADSHEET_NOTIFY_BLOCK
	jz	noSpreadsheetCreate
	call	CreateSSNotify
	jnc	noSpreadsheetCreate		;branch if no error
	andnf	ax, not (SNFLAGS_REQUIRE_SPREADSHEET_NOTIFY_BLOCK)
noSpreadsheetCreate:
	push	bx
	;
	; Loop through the entries
	;
	mov	di, offset notificationTable
	mov	cx, length notificationTable
notifyLoop:
	clr	bx				;bx <- assume NULL status
	tst	ss:notifyFlags			;NULL status event?
	jz	nullStatus			;branch if NULL status
	ror	ax, 1
	jnc	noNotify
	push	ax, cx, ds
	;
	; Allocate and initialize notification block
	;
	mov	ax, cs:[di].NS_size
	tst	ax				;any size?
	jz	noAlloc				;branch if no size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	jc	errorAlloc			;branch if error
	push	bx
	mov	bx, ds				;bx:si <- ptr to spreadsheet
	mov	ds, ax				;ds <- seg addr of block
	clr	cx				;cx <- flags o'plenty
	call	cs:[di].NS_routine
	pop	bx				;bx <- handle of notification
sendStatus:
	pop	ax, cx, ds
nullStatus:
	call	SendNotification
noNotify:
	add	di, (size NotifStruct)
	loop	notifyLoop

	;
	; Did we create a SpreadsheetStyleChange block?  If so, free it
	;
errorPop:
	pop	bx				;bx <- block handle
	tst	bx				;any block?
	jz	noSpreadsheetFree		;branch if no block
	call	MemFree
noSpreadsheetFree:

	.leave
	ret

	;
	; The table specified no size, so the generation routine
	; will do the allocation itself.
	;
noAlloc:
	mov	bx, ds				;bx:si <- ptr to spreadsheet
	call	cs:[di].NS_routine
	jmp	sendStatus

	;
	; An error occurred while allocating a notification block...bail.
	;
errorAlloc:
	pop	ax, cx, ds
	jmp	errorPop
SS_ForceNotification	endp

CheckHack <offset SNF_EDIT_ENABLE eq 0>
CheckHack <offset SNF_CHAR_ATTR eq 1>
CheckHack <offset SNF_JUSTIFICATION eq 2>
CheckHack <offset SNF_EDIT_BAR eq 3>
CheckHack <offset SNF_SELECTION eq 4>
CheckHack <offset SNF_ACTIVE_CELL eq 5>
CheckHack <offset SNF_CELL_WIDTH_HEIGHT eq 6>
CheckHack <offset SNF_DOC_ATTRS eq 7>
CheckHack <offset SNF_CELL_ATTRS eq 8>
CheckHack <offset SNF_CELL_NOTES eq 9>
CheckHack <offset SNF_NAME_CHANGE eq 10>
CheckHack <offset SNF_FORMAT_INIT eq 11>
CheckHack <offset SNF_FORMAT_CHANGE eq 12>
CheckHack <offset SNF_DATA_RANGE eq 13>

;	CMT -- The "MAX_CELL_TEXT_SIZE+2" accomodates DBCS and SBCS -- too
;		difficult to plug in proper constants here. (witt)
;
notificationTable	NotifStruct	\
	<GenSelectStateNotify, size NotifySelectStateChange,
			GWNT_SELECT_STATE_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>,
	<GenCharAttrNotify, size VisTextNotifyCharAttrChange,
			GWNT_TEXT_CHAR_ATTR_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<GenJustificationNotify, size NotifyJustificationChange,
			GWNT_JUSTIFICATION_CHANGE,
			GAGCNLT_APP_TARGET_NOTIFY_JUSTIFICATION_CHANGE>,
	<GenEditBarNotify, size NotifySSheetEditBarChange + (MAX_CELL_TEXT_SIZE+2),
		GWNT_SPREADSHEET_EDIT_BAR_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_EDIT_BAR_CHANGE>,
	<GenSelectionNotify, size NotifySSheetSelectionChange,
		GWNT_SPREADSHEET_SELECTION_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>,
	<GenActiveCellNotify,
		size NotifySSheetActiveCellChange + (MAX_CELL_GOTO_TEXT_SIZE+2),
		GWNT_SPREADSHEET_ACTIVE_CELL_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_ACTIVE_CELL_CHANGE>,
	<GenCellWidthHeightNotify,
		size NotifySSheetCellWidthHeightChange,
		GWNT_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE>,
	<GenDocAttrsNotify,
		size NotifySSheetDocAttrsChange,
		GWNT_SPREADSHEET_DOC_ATTR_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DOC_ATTR_CHANGE>,
	<GenCellAttrsNotify,
		size NotifySSheetCellAttrsChange,
		GWNT_SPREADSHEET_CELL_ATTR_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_ATTR_CHANGE>,
	<GenCellNotesNotify,
		0,
		GWNT_SPREADSHEET_CELL_NOTES_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_NOTES_CHANGE>,
	<GenNameChangeNotify,
		size NotifySSheetNameChange,
		GWNT_SPREADSHEET_NAME_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_NAME_CHANGE>,
	<GenFormatInitNotify,
		size NotifyFloatFormatChange,
		GWNT_FLOAT_FORMAT_INIT,
		GAGCNLT_FLOAT_FORMAT_INIT>,
	<GenFormatNotify,
		size NotifyFloatFormatChange,
		GWNT_FLOAT_FORMAT_CHANGE,
		GAGCNLT_FLOAT_FORMAT_CHANGE>,
	<GenDataRangeNotify,
		size NotifySSheetDataRangeChange,
		GWNT_SPREADSHEET_DATA_RANGE_CHANGE,
		GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DATA_RANGE_CHANGE>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenSelectStateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send NotifySelectStateChange (GenEditControl notification)
CALLED BY:	SS_SendNotification

PASS:		ds - seg addr of NotifySelectStateChange block
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenSelectStateNotify	proc	near
	uses	bp
	.enter

	mov	ax, BB_TRUE or (BB_FALSE shl 8)
	mov	ds:[NSSC_selectionType], SDT_SPREADSHEET
	mov	ds:[NSSC_selectAllAvailable], al
	mov	ds:[NSSC_clipboardableSelection], al
	mov	ds:[NSSC_deleteableSelection], al	;can delete
	mov	ds:[NSSC_pasteable], ah			;assume can't paste
	;
	; See if the clipboard has stuff we can deal with
	;
	clr	bp				;normal transfer
	call	ClipboardQueryItem		;fill our buffer with formats
	;
	; does CIF_SPREADSHEET format exist ?
	;
	tst	bp
	jz	cleanUp				;branch if no transfer item
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET		;dx <- format to search for
	call	ClipboardTestItemFormat
	jnc	canPaste			;jump if can paste

	;
	; Hack for Wizard to allow GeoCalc to paste text items
	; into the edit bar and graphics into the graphics layer.
	;
		clr	bp				;bp <- not CIF_QUICK
CHART <		call	GrObjTestSupportedTransferFormats		>
CHART <		jnc	cleanUp			;branch if can't paste	>
NOCHART <	jmp	cleanUp			; if can't paste	>


canPaste:
	mov	ds:[NSSC_pasteable], BB_TRUE	;mark as pasteable
	;
	; Done with transfer item
	;
cleanUp:
	call	ClipboardDoneWithItem

	.leave
	ret
GenSelectStateNotify	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenCharAttrNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a VisTextNotifyCharAttrChange 
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of VisTextNotifyCharAttrChange block
		es - seg addr of SpreadsheetStyleChange block
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Currently deals with:
		TextStyle
		FontID
		pointsize
		Text FG Color
		Text BG Color
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenCharAttrNotify	proc	near
	uses	bx, di
	.enter

	;
	; Convert CellAttrs to VisTextCharAttr structure
	;
CheckHack <(offset SSC_attrs) eq 0>
CheckHack <(offset VTNCAC_charAttr) eq 0>
	clr	bx, di				;es:di <- ptr to CellAttrs
						;ds:bx <- ptr to VisTextCharAttr
	call	ConvertCellAttrsToTextAttrs
	;
	; Handle style diffs
	;
	mov	al, es:SSC_styleIndeterminates	;al <- indeterminates
	mov	ds:[VTNCAC_charAttrDiffs.VTCAD_textStyles], al
	;
	; Store the VisTextCharAttrFlags for any other multiple attributes
	;
	mov	ax, es:SSC_textFlags
	mov	ds:[VTNCAC_charAttrDiffs.VTCAD_diffs], ax

	.leave
	ret
GenCharAttrNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCellAttrsToTextAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert CellAttrs values to VisTextCharAttr equivalents

CALLED BY:	UTILITY
PASS:		es:di - ptr to CellAttrs (source)
		ds:bx - ptr to VisTextCharAttr (dest)
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertCellAttrsToTextAttrsFar		proc	Far
	call	ConvertCellAttrsToTextAttrs
	ret
ConvertCellAttrsToTextAttrsFar		endp

ConvertCellAttrsToTextAttrs		proc	near
	uses	dx
	.enter
	;
	; TextStyle
	;
	mov	al, es:[di].CA_style		;al <- TextStyle
	mov	ds:[bx].VTCA_textStyles, al
	;
	; FontID
	;
	mov	ax, es:[di].CA_font
	mov	ds:[bx].VTCA_fontID, ax
	;
	; pointsize (WBFixed)
	;
	clr	dx
	mov	ax, es:[di].CA_pointsize
	shrwbf	axdh
	shrwbf	axdh
	shrwbf	axdh				;/8
	movwbf	ds:[bx].VTCA_pointSize, axdh
	;
	; text foreground color (ColorQuad)
	;
	mov	ax, {word}es:[di].CA_textAttrs.AI_color.CQ_redOrIndex
	mov	{word}ds:[bx].VTCA_color.CQ_redOrIndex, ax
	mov	ax, {word}es:[di].CA_textAttrs.AI_color.CQ_green
	mov	{word}ds:[bx].VTCA_color.CQ_green, ax
	mov	al, es:[di].CA_textAttrs.AI_grayScreen
	mov	ds:[bx].VTCA_grayScreen, al
CheckHack <(offset CQ_info) eq (offset CQ_redOrIndex+1)>
CheckHack <(offset CQ_blue) eq (offset CQ_green+1)>
	;
	; text background color (ColorQuad)
	;
	mov	ax, {word}es:[di].CA_bgAttrs.AI_color.CQ_redOrIndex
	mov	dx, ax				;dl <- index, dh <- flag
	mov	{word}ds:[bx].VTCA_bgColor.CQ_redOrIndex, ax
	mov	ax, {word}es:[di].CA_bgAttrs.AI_color.CQ_green
	mov	{word}ds:[bx].VTCA_bgColor.CQ_green, ax
	mov	al, es:[di].CA_bgAttrs.AI_grayScreen
	mov	ds:[bx].VTCA_bgGrayScreen, al
CheckHack <(offset CQ_info) eq (offset CQ_redOrIndex+1)>
CheckHack <(offset CQ_blue) eq (offset CQ_green+1)>
	;
	; Store track kerning, font width and font weight
	;
	mov	ax, {word}es:[di].CA_trackKern
	mov	{word}ds:[bx].VTCA_trackKerning, ax
CheckHack <(offset CA_fontWidth) eq (offset CA_fontWeight)+1>
CheckHack <(offset VTCA_fontWidth) eq (offset VTCA_fontWeight)+1>
	mov	ax, {word}es:[di].CA_fontWeight
	mov	{word}ds:[bx].VTCA_fontWeight, ax
	;
	; Set stuff we don't use to reasonable values
	;
	clr	ax
CheckHack <PT_SOLID eq 0>
	mov	ds:[bx].VTCA_bgPattern.GP_type, al
	mov	ds:[bx].VTCA_pattern.GP_type, al
	mov	ds:[bx].VTCA_extendedStyles, ax
	;
	; The one thing we do use is background color.  Set
	; the extended style bit appropriately if there is
	; a background color.
	;
	cmp	dx, C_WHITE or (CF_INDEX shl 8)
	je	noBackColor
	ornf	ds:[bx].VTCA_extendedStyles, mask VTES_BACKGROUND_COLOR
noBackColor:
	;
	; Finally, stuff we really don't use, but the text object will
	; barf on if we don't set it to something reasonable.
	;
	mov	ds:[bx].VTCA_meta.SSEH_style, CA_NULL_ELEMENT
	mov	ds:[bx].VTCA_meta.SSEH_meta.REH_refCount.WAAH_low, ax
	mov	ds:[bx].VTCA_meta.SSEH_meta.REH_refCount.WAAH_high, al
	push	cx, di, es
	segmov	es, ds
	lea	di, ds:[bx].VTCA_reserved	;es:di <- ptr to shme
	mov	cx, (size VTCA_reserved)	;cx <- # of bytes
	rep	stosb				;store me jesus (al = 0)
	pop	cx, di, es

	.leave
	ret
ConvertCellAttrsToTextAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenJustificationNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send NotifyJustificationChange to output
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifyJustificationChange block
		es - seg addr of SpreadsheetStyleChange block
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenJustificationNotify	proc	near
	mov	al, es:SSC_attrs.CA_justification
	mov	ds:[NJC_justification], al
	clr	al				;al <- FALSE
	test	es:SSC_cellFlags, mask SCF_JUSTIFICATIONS
	jz	oneJust
	inc	al				;al <- TRUE
oneJust:
	mov	ds:[NJC_diffs], al
	mov	ds:[NJC_useGeneral], TRUE

	ret
GenJustificationNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenEditBarNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a NotifySSheetEditBarChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetEditBarChange block
		bx:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenEditBarNotify	proc	near
	uses	bp
	.enter

	mov	dx, ds
	mov	bp, offset NSSEBC_text		;dx:bp <- ptr to buffer

	push	ds
	mov	ds, bx				;ds:si <- ptr to Spreadsheet
	call	FormatEditContents		;cx <- formatted string length
	pop	ds
DBCS<	shl	cx, 1				;cx <- size	>
	mov	ds:NSSEBC_textSize, cx		;store size of text

	.leave
	ret
GenEditBarNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenSelectionNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a NotifySSheetSelectionChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetSelectionChange block
		bx:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenSelectionNotify	proc	near
	uses	es, bp
	class	SpreadsheetClass
	.enter

	mov	es, bx				;es:si <- ptr to Spreadsheet
	clr	bp				;bp <- SSheetSelectionFlags
	;
	; Copy the range
	;
	mov	ax, es:[si].SSI_selected.CR_start.CR_column
	mov	bx, es:[si].SSI_selected.CR_start.CR_row
	mov	cx, es:[si].SSI_selected.CR_end.CR_column
	mov	dx, es:[si].SSI_selected.CR_end.CR_row
	mov	ds:NSSSC_selection.CR_start.CR_column, ax
	mov	ds:NSSSC_selection.CR_start.CR_row, bx
	mov	ds:NSSSC_selection.CR_end.CR_column, cx
	mov	ds:NSSSC_selection.CR_end.CR_row, dx
	;
	; Set any "single" flags
	;
	cmp	ax, cx
	jne	notSingleColumn
	ornf	bp, mask SSSF_SINGLE_COLUMN
notSingleColumn:
	cmp	bx, dx
	jne	notSingleRow
	ornf	bp, mask SSSF_SINGLE_ROW
	cmp	ax, cx
	jne	notSingleCell
	ornf	bp, mask SSSF_SINGLE_CELL
notSingleCell:
notSingleRow:
	;
	; Set any "entire" flags
	;
	tst	ax
	jnz	notEntireRow
	cmp	cx, es:[si].SSI_maxCol
	jb	notEntireRow
	ornf	bp, mask SSSF_ENTIRE_ROW
notEntireRow:
	tst	bx
	jnz	notEntireColumn
	cmp	dx, es:[si].SSI_maxRow
	jb	notEntireColumn
	ornf	bp, mask SSSF_ENTIRE_COLUMN
notEntireColumn:

	mov	ds:NSSSC_flags, bp		;pass SSheetSelectionFlags

	.leave
	ret
GenSelectionNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenActiveCellNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a NotifySSheetActiveCellChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetEditBarChange block
		bx:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, cx, dx, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/18/92		Initial version
	witt	11/15/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenActiveCellNotify	proc	near
	uses	bp, es, di
	class	SpreadsheetClass
	.enter

	segmov	es, ds
	mov	di, offset NSSACC_text		;es:di <- ptr to dest buffer
	mov	ds, bx				;ds:si <- ptr to Spreadsheet
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column ;(ax,cx) <- cell to format
	call	ParserFormatCellReference	;cx <- length (w/out NULL)
	mov	es:NSSACC_textSize, cx		;store length of text

	.leave
	ret
GenActiveCellNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenCellWidthHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a NotifySSheetActiveCellChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetCellWidthHeightChange block
		es - seg addr of SpreadsheetStyleChange block
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenCellWidthHeightNotify	proc	near
	uses	ax
	class	SpreadsheetClass
	.enter

	;
	; Set the flags for any indeterminates
	;
	clr	dl
	mov	cx, es:SSC_cellFlags

	test	cx, mask SCF_ROWS
	jz	noRows
	ornf	dl, mask SSWHF_MULTIPLE_HEIGHTS
noRows:
	test	cx, mask SCF_COLUMNS
	jz	noCols
	ornf	dl, mask SSWHF_MULTIPLE_WIDTHS
noCols:
	mov	ds:NSSCWHC_flags, dl
	;
	; Copy the row height and column width
	;
	mov	ax, es:SSC_rowHeight
	mov	ds:NSSCWHC_height, ax
	mov	ax, es:SSC_columnWidth
	mov	ds:NSSCWHC_width, ax

	.leave
	ret
GenCellWidthHeightNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDocAttrsNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate header/footer notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetDocAttrsChange block
		bx:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	ax, cx, dx, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenDocAttrsNotify	proc	near
	uses	ax, es, di, si
	class	SpreadsheetClass
	.enter

	segmov	es, ds				;es <- seg addr of notify
	mov	ds, bx				;ds:si <- ptr to spreadsheet
	;
	; Copy the draw flags
	;
	mov	ax, ds:[si].SSI_drawFlags	;ax <- SpreadsheetDrawFlags
	mov	es:NSSDAC_drawFlags, ax		;pass flags
	;
	; Copy the header range
	;
	mov	di, offset NSSDAC_header	;es:di <- dest
	mov	cx, (size CellRange)/(size word)
	push	si, cx
	lea	si, ds:[si].SSI_header		;ds:si <- source
	rep	movsw				;copy me jesus
	pop	si, cx
	;
	; Copy the footer range
	;
	push	si
	mov	di, offset NSSDAC_footer	;es:di <- dest
	lea	si, ds:[si].SSI_footer		;ds:si <- source
	rep	movsw				;copy me jesus
	pop	si
	;
	; Copy the recalc parameters
	;
	mov	ax, ds:[si].SSI_circCount
	mov	es:NSSDAC_circCount, ax
	mov	ax, ds:[si].SSI_flags
	mov	es:NSSDAC_calcFlags, ax
	mov	cx, (size FloatNum)/(size word)
	mov	di, offset NSSDAC_converge	;es:di <- dest
	lea	si, ds:[si].SSI_converge	;ds:si <- source
	rep	movsw				;copy me jesus

	.leave
	ret
GenDocAttrsNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenCellAttrsNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate cell attributes notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetCellAttrsChange
		es - seg addr of SpreadsheetStyleChange block
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenCellAttrsNotify	proc	near
	uses	ax
	.enter

	;
	; Copy border sides
	;
	mov	al, es:SSC_attrs.CA_border
	mov	ds:NSSCAC_borderInfo, al
	mov	al, es:SSC_borderIndeterminates
	mov	ds:NSSCAC_borderIndeterminates, al
	;
	; Copy border color
	;
	movdw	ds:NSSCAC_borderColor, es:SSC_attrs.CA_borderAttrs.AI_color, ax
	;
	; Copy border mask
	;
	mov	al, es:SSC_attrs.CA_borderAttrs.AI_grayScreen
	mov	ds:NSSCAC_borderGrayScreen, al
	;
	; Copy the flags
	;
	mov	ax, es:SSC_cellFlags
	mov	ds:NSSCAC_borderColorIndeterminates, ax

	.leave
	ret
GenCellAttrsNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenCellNotesNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate cell notes notification
CALLED BY:	SS_SendNotification()

PASS:		bx:si - ptr to Spreadsheet instance
RETURN:		bx - handle of notification (locked)
DESTROYED:	ax, cx, dx, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine allocates its own notification block.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenCellNotesNotify		proc	near
	uses	bp, si, di, es
	.enter

	mov	ds, bx				;ds:si <- ptr to spreadsheet
	mov	di, si				;ds:di <- ptr to spreadsheet
	call	SpreadsheetGetNoteForActiveCell
	;
	; We lock the notification block because code later will unlock it
	;
	mov	bx, dx				;bx <- handle of text
	call	MemLock

	.leave
	ret
GenCellNotesNotify		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDataRangeNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate data range notification

CALLED BY:	SS_SendNotification()
PASS:		bx:si - ptr to Spreadsheet instance
		ds - seg addr of NotifySSheetDataRangeChange
RETURN:		none
DESTROYED:	ax, cx, dx, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDataRangeNotify		proc	near
	uses	si, di, bp, es, ds
	class	SpreadsheetClass
	.enter

	segmov	es, ds				;es <- seg addr of notification
	;
	; Get the range of cells with data and store it
	;
	mov	ds, bx				;ds:si <- ptr to spreadsheet
	mov	di, SET_NO_EMPTY_CELLS_NO_HDR_FTR
	call	CallRangeExtentWholeSheet

	mov	es:NSSDRC_range.CR_start.CR_row, ax
	mov	es:NSSDRC_range.CR_start.CR_column, cx
	mov	es:NSSDRC_range.CR_end.CR_row, dx
	mov	es:NSSDRC_range.CR_end.CR_column, bx
	;
	; Also return the selected range, because it's convienent
	;
	mov	cx, (size CellRange)/(size word)
	lea	si, ds:[si].SSI_selected	;ds:si <- ptr to source
	mov	di, offset NSSDRC_selection	;es:di <- ptr to dest
	rep	movsw				;copy me jesus

	.leave
	ret
GenDataRangeNotify		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFormatNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a NotifyFloatFormatChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifyFloatFormatChange
		es - seg addr of SpreadsheetStyleChange block
		bx:si - ptr to spreadsheet instance
RETURN:		none
DESTROYED:	ds

PSEUDO CODE/STRATEGY:
	NotifyFloatFormatChange      struc
		NFFC_vmFileHan	word
		NFFC_vmBlkHan	word
		NFFC_format	word
		NFFC_count	word
	NotifyFloatFormatChange      ends

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenFormatNotify	proc	near	uses	es
	class	SpreadsheetClass
	.enter

	mov	ax, es:SSC_attrs.CA_format
	test	es:SSC_cellFlags, mask SCF_FORMATS
	jz	notIndeterminate

	mov	ax, FORMAT_ID_INDETERMINATE

notIndeterminate:
	segmov	es, ds
	mov	ds, bx
	mov	es:NFFC_format, ax
	mov	ax, ds:[si].SSI_cellParams.CFP_file
	mov	es:NFFC_vmFileHan, ax
	mov	ax, ds:[si].SSI_formatArray
	mov	es:NFFC_vmBlkHan, ax

	;
	; force notification, if caller wants to
	;
NOFXIP<	segmov	ds, <segment idata>, ax					>
FXIP<	mov_tr	ax, bx				;save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
FXIP<	mov_tr	bx, ax				;restore bx value	>
	mov	ax, ds:formatCount
	mov	es:NFFC_count, ax

	.leave
	ret
GenFormatNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFormatInitNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a NotifyFloatFormatChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifyFloatFormatChange
		bx:si - ptr to spreadsheet instance
RETURN:		none
DESTROYED:	ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenFormatInitNotify	proc	near	uses	es
	class	SpreadsheetClass
	.enter

	; 
	; format field not used by Init code, but set it anyways
	;
	segmov	es, ds
	mov	ds, bx
	mov	es:NFFC_format, FORMAT_ID_INDETERMINATE
	mov	ax, ds:[si].SSI_cellParams.CFP_file
	mov	es:NFFC_vmFileHan, ax
	mov	ax, ds:[si].SSI_formatArray
	mov	es:NFFC_vmBlkHan, ax

	;
	; force notification
	;
NOFXIP<	segmov	ds, <segment idata>, ax					>
FXIP<	mov_tr	ax, bx				;save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
FXIP<	mov_tr	bx, ax				;restore bx value	>
	inc	ds:formatCount
	mov	ax, ds:formatCount
	mov	es:NFFC_count, ax

	.leave
	ret
GenFormatInitNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenNameChangeNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SYNOPSIS:	Send a NotifySSheetNameChange notification
CALLED BY:	SS_SendNotification()

PASS:		ds - seg addr of NotifySSheetNameChange
		bx:si - ptr to spreadsheet instance
RETURN:		none
DESTROYED:	ds

PSEUDO CODE/STRATEGY:
	NotifySSheetNameChange      struc	
		NSSNC_count	word
	NotifySSheetNameChange      ends

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenNameChangeNotify	proc	near	uses	es
	class	SpreadsheetClass
	.enter

	;
	; force notification
	;
	segmov	es, ds
FXIP<	mov_tr	ax, bx				;save bx value		>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
FXIP<	mov_tr	bx, ax				;restore bx value	>
NOFXIP<	segmov	ds, <segment idata>, ax					>
	inc	ds:formatCount
	mov	ax, ds:formatCount
	mov	es:NSSNC_count, ax

	.leave
	ret
GenNameChangeNotify		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification block to output of spreadsheet
CALLED BY:	SS_SendNotification()

PASS:		ds:si - ptr to Spreadsheet instance
		bx - handle of notification block (locked)
		     or 0 for NULL status event
		di - offset of NotifStruct
RETURN:		none
DESTROYED:	bx (handle free'd), dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendNotification	proc	near
	uses	ax, cx, bp, di, si
	.enter

	push	cs:[di].NS_appType		;<- GeoWorksGenAppGCNListType
	mov	dx, cs:[di].NS_gcnType		;dx <- GeoWorksNotificationType

	tst	bx				;any block?

	jz	noHandle			;branch if NULL status event

	call	MemUnlock
	;
	; Initialize reference count for two (2) sends below
	;
	mov	ax, 1				;ax <- reference count
	call	MemInitRefCount
noHandle:

	;
	; Record the notification event
	;
	push	si, bp
	mov	bp, bx				;bp <- handle of notification
	mov	cx, MANUFACTURER_ID_GEOWORKS		;cx <- ManufacturerID
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, mask MF_RECORD		;di <- MessageFlags
	call	ObjMessage			;di <- recorded event
	pop	si, bp
	pop	ax				;ax <- GeoWorksGenAppGCNListType
	;
	; Send the recorded notification event to the application object
	;
	mov	dx, size GCNListMessageParams	;dx <- size of stack frame
	sub	sp, dx				;create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, ax
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	;
	; Set appropriate flags
	;
	mov	ax, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:
	mov	ss:[bp].GCNLMP_flags, ax
	;
	; Send the recorded event off to the GCN list in the app obj
	;
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx				;bx <- use current process
	call	GeodeGetAppObject		;^lbx:si <- OD of app object
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, dx				;clean up stack
done::
	.leave
	ret
SendNotification	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSSNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a SpreadsheetStyleChange notification block
CALLED BY:	SS_SendNotification()

PASS:		ds:si - ptr to Spreadsheet instance data
RETURN:		es - seg addr of SpreadsheetStyleChange block
		bx - handle of SpreadsheetStyleChange block
		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateSSNotify	proc	near
	uses	ax, cx, dx, di
	class	SpreadsheetClass

	.enter

	;
	; Allocate a block for the SpreadsheetStyleChange 
	; (which we send to the UI stuff)
	;
	mov	ax, (size SpreadsheetStyleChange)
	mov	cl, mask HF_SWAPABLE or mask HF_SHARABLE
	mov	ch, mask HAF_LOCK or mask HAF_ZERO_INIT
	call	MemAlloc
	mov	es, ax				;es <- seg addr of block
	LONG jc	done				;branch if error in allocation
	push	bx
	clr	bx				;bx <- no current attrs
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	call	GetCurCellAttrs			;ax <- current cell attributes
	mov	di, offset SSC_attrs		;es:di <- ptr to buffer
	call	StyleGetStyleByTokenFar		;get styles for cell
	;
	; Check row heights of selection
	;
	mov	cx, ds:[si].SSI_selected.CR_start.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_row
	call	GetRowDiffs
	mov	es:SSC_rowHeight, ax
	jnc	notMultipleRows
	ornf	es:SSC_cellFlags, mask SCF_ROWS
notMultipleRows:
	;
	; Check column widths of selection
	;
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	call	GetColumnDiffs
	mov	es:SSC_columnWidth, ax
	jnc	notMultipleColumns
	ornf	es:SSC_cellFlags, mask SCF_COLUMNS
notMultipleColumns:
	;
	; If the selection is a single cell, we're done
	;
	call	SingleCell?
	jc	singleCell			;branch if single cell
	;
	; Cycle through the selection and figure out if any
	; attributes are different than what we already have.
	;
	call	CheckSelectionStyle
singleCell:
	pop	bx				;bx <- handle of memory block
	clc					;carry <- no error
done:

	.leave
	ret
CreateSSNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSelectionStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check style of selection by cycling through each cell
CALLED BY:	NotifyStyleChange()

PASS:		ds:si - ptr to Spreadsheet instance
		es - seg addr of SpreadsheetStyleChange block
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckSelectionStyle	proc	near
	class	SpreadsheetClass

locals	local	CellLocals

	.enter

	;
	; Cycle through selection and check style of each cell.
	;
	; Previously, we just cycled through each cell in the
	; selection that actually existed, and if not all cells
	; were called back for, we added in the default attrs.
	;
	; To account for default column attributes, we need
	; to do this on a column-by-column basis.
	;
	mov	ss:locals.CL_data1, es		;pass data word #1

	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	mov	ss:locals.CL_params.REP_callback.offset, \
						offset CheckCellStyleCallback
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bx, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	;
	; We don't call CallRangeEnum() because some of the arguments
	; are constant, and we really don't want it to reinitialize
	; the CL_styleToken field each time we call it, so attributes
	; we've seen before carry over from column to column.
	;
	mov	ss:locals.CL_styleToken, -1	;no styles set yet
	mov	ss:locals.CL_params.REP_bounds.R_top, ax
	mov	ss:locals.CL_params.REP_bounds.R_bottom, bx
	mov	ss:locals.CL_instanceData.segment, ds
	mov	ss:locals.CL_instanceData.offset, si
columnLoop:
	push	dx
	;
	; Callback for current column only, only data cells
	;
	clr	ss:locals.CL_data2		;data2 <- cell count
	mov	ss:locals.CL_params.REP_bounds.R_left, cx
	mov	ss:locals.CL_params.REP_bounds.R_right, cx
	clr	dl				;dl <- RangeEnumFlags
	lea	bx, ss:locals.CL_params		;ss:bx <- ptr to args
CheckHack <offset SSI_cellParams eq 0 >
	call	RangeEnum
	;
	; Figure out if all the cells had data or not.  If so,
	; we've got all the attribute information we need.  If not,
	; we need to add the default attributes for this column.
	;
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	sub	ax, ds:[si].SSI_selected.CR_start.CR_row
	inc	ax				;ax <- # of cells in column
	cmp	ax, ss:locals.CL_data2
	je	gotAttrs
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- default attrs for column
	call	AddStyleDiffs
gotAttrs:
	;
	; Go to the next column
	;
	pop	dx
	inc	cx				;cx <- next column
	cmp	cx, dx				;done all columns?
	jbe	columnLoop			;branch while more columns

	.leave
	ret
CheckSelectionStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCellStyleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check style of cell in selected range
CALLED BY:	NotifyStyleChange() via RangeEnum()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data, if any
		ss:bp.CL_data1 - seg addr of SpreadsheetStyleChange block
		ss:bp.CL_data2 - count of cells with data
RETURN:		carry - set to abort enum
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCellStyleCallback	proc	far
	uses	ax, di
locals	local	CellLocals

	.enter	inherit

	inc	ss:locals.CL_data2		;update cell count

	mov	di, es:[di]			;es:di <- ptr to cell data
	mov	ax, es:[di].CC_attrs		;ax <- cell style token
	cmp	ax, ss:locals.CL_styleToken	;same style as before?
	je	done				;branch if already recorded

	call	AddStyleDiffs			;add differences in styles

done:
	clc					;carry <- don't abort

	.leave
	ret
CheckCellStyleCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddStyleDiffs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add differences in styles for a cell
CALLED BY:	CheckCellStyle()

PASS:		ax - style token of cell to add
		ss:bp.CL_data1 - seg addr of SpreadsheetStyleChange block
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddStyleDiffs	proc	near
	uses	ax, dx, di, es, ds
locals	local	CellLocals

	.enter	inherit

	;
	; The cell has a different style than the previous cell, so
	; get the current attribytes
	;
	mov	ss:locals.CL_styleToken, ax	;mark style as recorded
	segmov	es, ss
	lea	di, ss:locals.CL_cellAttrs	;es:di <- ptr to buffer
	call	StyleGetStyleByTokenFar
	mov	ds, ss:locals.CL_data1		;ds <- seg addr of style block
	mov	dx, ds:SSC_textFlags		;dx <- VisTextCharAttrFlags
	;
	; Compare the current cell attributes
	;
	mov	al, ds:SSC_attrs.CA_justification
	mov	ah, ss:locals.CL_cellAttrs.CA_justification
	cmp	al, ah
	je	noJustificationChange
	ornf	ds:SSC_cellFlags, mask SCF_JUSTIFICATIONS
noJustificationChange:

	mov	ax, ds:SSC_attrs.CA_format
	cmp	ax, ss:locals.CL_cellAttrs.CA_format
	je	noFormatChange
	ornf	ds:SSC_cellFlags, mask SCF_FORMATS
noFormatChange:
	mov	ax, ds:SSC_attrs.CA_pointsize
	cmp	ax, ss:locals.CL_cellAttrs.CA_pointsize
	je	noPointsizeChange
	ornf	dx, mask VTCAF_MULTIPLE_POINT_SIZES
noPointsizeChange:
	mov	ax, ds:SSC_attrs.CA_font
	cmp	ax, ss:locals.CL_cellAttrs.CA_font
	je	noFontChange
	ornf	dx, mask VTCAF_MULTIPLE_FONT_IDS
noFontChange:
	;
	; Check TextStyle
	;
	mov	al, ds:SSC_attrs.CA_style
	mov	ah, ss:locals.CL_cellAttrs.CA_style
	xor	al, ah				;al <- non-matching bits
	ornf	ds:SSC_styleIndeterminates, al	;indicate style different
	;
	; Check text color
	;
	mov	ax, {word}ds:SSC_attrs.CA_textAttrs.AI_color.CQ_redOrIndex
	cmp	ax, {word}ss:locals.CL_cellAttrs.CA_textAttrs.AI_color.CQ_redOrIndex
	jnz	textColorChange
	mov	ax, {word}ds:SSC_attrs.CA_textAttrs.AI_color.CQ_green
	cmp	ax, {word}ss:locals.CL_cellAttrs.CA_textAttrs.AI_color.CQ_green
	je	noTextColorChange
textColorChange:
	ornf	dx, mask VTCAF_MULTIPLE_COLORS
noTextColorChange:
	mov	al, ds:SSC_attrs.CA_textAttrs.AI_grayScreen
	cmp	al, ss:locals.CL_cellAttrs.CA_textAttrs.AI_grayScreen
	je	noGrayScreenChange
	ornf	dx, mask VTCAF_MULTIPLE_GRAY_SCREENS
noGrayScreenChange:
	;
	; Check background color
	;
	mov	ax, {word}ds:SSC_attrs.CA_bgAttrs.AI_color.CQ_redOrIndex
	cmp	ax, {word}ss:locals.CL_cellAttrs.CA_bgAttrs.AI_color.CQ_redOrIndex
	jnz	backColorChange
	mov	ax, {word}ds:SSC_attrs.CA_bgAttrs.AI_color.CQ_green
	cmp	ax, {word}ss:locals.CL_cellAttrs.CA_bgAttrs.AI_color.CQ_green
	je	noBackColorChange
backColorChange:
	ornf	dx, mask VTCAF_MULTIPLE_BG_COLORS
noBackColorChange:
	mov	al, ds:SSC_attrs.CA_bgAttrs.AI_grayScreen
	cmp	al, ss:locals.CL_cellAttrs.CA_bgAttrs.AI_grayScreen
	je	noBGGrayScreenChange
	ornf	dx, mask VTCAF_MULTIPLE_BG_GRAY_SCREENS
noBGGrayScreenChange:
	;
	; Deal with track kerning, font width and font weight
	;
	mov	ax, {word}ds:SSC_attrs.CA_trackKern
	cmp	ax, {word}ss:locals.CL_cellAttrs.CA_trackKern
	je	noTrackKerningChange
	ornf	dx, mask VTCAF_MULTIPLE_TRACK_KERNINGS
noTrackKerningChange:
	mov	ax, {word}ds:SSC_attrs.CA_fontWeight
CheckHack <(offset CA_fontWidth) eq (offset CA_fontWeight)+1>
	cmp	al, ss:locals.CL_cellAttrs.CA_fontWeight
	je	noFontWeightChange
	ornf	dx, mask VTCAF_MULTIPLE_FONT_WEIGHTS
noFontWeightChange:
	cmp	ah, ss:locals.CL_cellAttrs.CA_fontWidth
	je	noFontWidthChange
	ornf	dx, mask VTCAF_MULTIPLE_FONT_WIDTHS
noFontWidthChange:
	;
	; Store (new) VisTextCharAttrFlags
	;
	mov	ds:SSC_textFlags, dx
	;
	; Deal with cell borders
	;
	mov	al, ds:SSC_attrs.CA_border
	mov	ah, ss:locals.CL_cellAttrs.CA_border
	xor	al, ah				;al <- non-matching bits
	ornf	ds:SSC_borderIndeterminates, al	;indicate borders different
	not	al				;al <- matching bits
	andnf	ds:SSC_attrs.CA_border, al	;clear non-matching bits
	;
	; Deal with cell border color
	;
	cmpdw	ds:SSC_attrs.CA_borderAttrs.AI_color, \
		ss:locals.CL_cellAttrs.CA_borderAttrs.AI_color, ax
	je	noBorderColorChange
	ornf	ds:SSC_cellFlags, mask SCF_BORDER_COLORS
noBorderColorChange:
	;
	; Deal with cell border gray screen
	;
	mov	al, ds:SSC_attrs.CA_borderAttrs.AI_grayScreen
	cmp	al, ss:locals.CL_cellAttrs.CA_borderAttrs.AI_grayScreen
	je	noBorderGrayChange
	ornf	ds:SSC_cellFlags, mask SCF_BORDER_GRAY_SCREENS
noBorderGrayChange:

	.leave
	ret
AddStyleDiffs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetForceControllerUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the spreadsheet to send a notification

CALLED BY:	MSG_META_UI_FORCE_CONTROLLER_UPDATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cx - manufacturer ID
		dx - NotificationType (GeoWorksNotificationType)
		(or 0xffff:0xffff to update all)

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetForceControllerUpdate		method dynamic SpreadsheetClass,
					MSG_META_UI_FORCE_CONTROLLER_UPDATE
	mov	si, di				;ds:si <- ptr to spreadsheet
	;
	; See if we're updating everything
	;
	cmp	cx, 0xffff
	jne	notAll
	cmp	dx, 0xffff
	je	sendNotificationAll
	;
	; If it's not GeoWorks', we don't support it
	;
notAll:
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	done
	;
	; Find it in the table
	;
	mov	di, offset notificationTable
	mov	cx, length notificationTable
	mov	ax, 0x0001
CheckHack <offset SNF_EDIT_ENABLE eq 0>
searchLoop:
	cmp	dx, cs:[di].NS_gcnType		;right notification?
CheckHack <segment SpreadsheetForceControllerUpdate eq segment notificationTable>
	je	sendNotification
	shl	ax, 1				;ax <- try next bit
	add	di, (size NotifStruct)		;cs:di <- next entry
	loop	searchLoop
done:
	ret

sendNotificationAll:
	mov	ax, mask SpreadsheetNotifyFlags
sendNotification:
	call	SS_ForceNotification
	ret
SpreadsheetForceControllerUpdate		endm

AttrCode	ends
