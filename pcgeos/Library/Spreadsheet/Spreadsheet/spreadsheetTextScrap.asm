COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetTextScrap.asm

AUTHOR:		Gene Anderson, Mar  8, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 8/93		Initial revision


DESCRIPTION:
	Code for generating text-object compatible transfer items

	$Id: spreadsheetTextScrap.asm,v 1.1 97/04/07 11:14:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutPasteCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCopyInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize stuff for creating a text scrap

CALLED BY:	CutCopyDoCopy()
PASS:		ss:bp - inherited locals
		ds:si - ptr to SpreadsheetInstance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCopyInit		proc	near
	uses	ax, bx
	class	SpreadsheetClass
	.enter	inherit	CutCopyDoCopy

EC <	call	ECCheckInstancePtr		;>
	;
	; Initialize the starting row & column
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	mov	ss:CCSF_local.CCSF_prevTextCell.CR_column, ax
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	ss:CCSF_local.CCSF_prevTextCell.CR_row, ax
	;
	; Allocate a text object associated with the clipboard
	;
	push	si
	mov	ax, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS ;ah <- no regions
	clr	bx				;bx <- attach to clipboard
	call	TextAllocClipboardObject
	movdw	ss:CCSF_local.CCSF_textObject, bxsi
	pop	si
	;
	; Indicate we haven't set any style yet
	;
	mov	ss:CCSF_local.CCSF_prevTextStyle, INVALID_STYLE_TOKEN
	;
	; Set up tabs to correspond to the column widths in the selection.
	;
	call	TEmitTabsForColumns

	.leave
	ret
TextCopyInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCopyFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up stuff after creating a text scrap

CALLED BY:	CutCopyDoCopy()
PASS:		ss:bp - inherited locals
			CCSF_local.CCSF_textObject - our text object
			SSM_local.SSMDAS_tferItemHdrVMHan - VM handle of header
			SSM_local.SSMDAS_vmFileHan - file handle of transfer
		ds:si - ptr to SpreadsheetInstance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCopyFinish		proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter	inherit	CutCopyDoCopy

EC <	call	ECCheckInstancePtr		;>

	;
	; If only one cell is selected then don't emit a final tab so
	; that cut/copy/paste can work with single line GenText objects
	;
	call	SingleCell?
	jc	oneCellSelected
		
	;
	; Emit a final tab to handle the special case of the last
	; cell in the last row, in the event it had a background
	; color.
	;
	clr	bx				;bx <- # emitted so far
	mov	cx, 1				;cx <- # to emit
	mov	dx, C_TAB			;dx <- char to emit
	call	TEmitCharToText

oneCellSelected:

	;
	; Finish up with text object
	;
	movdw	bxsi, ss:CCSF_local.CCSF_textObject
EC <	call	ECCheckOD			;>
	clrdw	cxdx				;cx:dx <- no owner
	mov	ax, TCO_RETURN_TRANSFER_FORMAT	;ax <- TextClipboardOption
	mov	di, -1				;di <- use default name
	call	TextFinishWithClipboardObject
	mov	dx, ax				;dx <- VM handle of text shme
	;
	; Add our transfer shme to the clipboard item as the 2nd item
	;
	mov	bx, ss:SSM_local.SSMDAS_vmFileHan
	mov	ax, ss:SSM_local.SSMDAS_tferItemHdrVMHan
	call	VMLock
	mov	ds, ax				;ds <- seg addr of CIH
	mov	ds:CIH_formatCount, 2
	;
	; specify text scrap
	;
	mov	bx, (size ClipboardItemFormatInfo)
	mov	ds:CIH_formats[bx].CIFI_format.CIFID_manufacturer, \
		MANUFACTURER_ID_GEOWORKS
	mov	ds:CIH_formats.[bx].CIFI_format.CIFID_type, CIF_TEXT
	mov	ds:CIH_formats.[bx].CIFI_vmChain.high, dx
	clr	ds:CIH_formats.[bx].CIFI_vmChain.low

	call	VMDirty
	call	VMUnlock

	.leave
	ret
TextCopyFinish		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCopyCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one cell to the text scrap

CALLED BY:	CutCopyCopyCell()
PASS:		ss:bp - inherited locals
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		*es:di - ptr to cell data, if any

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCopyCell		proc	near
	uses	bx, dx, di
	class	SpreadsheetClass
	.enter	inherit	CutCopyCopyCell

EC <	call	ECCheckInstancePtr		;>
	;
	; Copying to text?
	;
	tst	ss:CCSF_local.CCSF_textObject.handle
	jz	done				;branch if not doing text
	;
	; Emit the appopriate number of tabs and CRs to get us
	; to a reasonable starting point.  If we're in the same row,
	; we only need to worry about tabs.
	;
	clr	bx				;bx <- no chars so far
	mov	dx, ss:CCSF_local.CCSF_prevTextCell.CR_column
	cmp	ax, ss:CCSF_local.CCSF_prevTextCell.CR_row
	je	emitTabs			;branch if same row
	;
	; We're in a different row -- emit CRs to get to the correct row.
	; First emit tabs to finish out this row, though, so that
	; if the last cell had background color, it will get a trailing
	; tab and end in the right place.  This doesn't deal with the
	; last row with data, which is special-cased at the end.
	;
	push	cx
	;
	; Emit tabs to end of row
	;
	sub	cx, ds:[si].SSI_selected.CR_end.CR_column
	neg	cx				;cx <- # of columns
	mov	dx, C_TAB			;dx <- character to emit
	;
	; However, to handle the above case of background color, we only
	; really need one tab, so to more gracefully handle the case of
	; Select All followed by a copy, we max out at one tab for this.
	;
	jcxz	noTabs				;branch if no tabs
	mov	cx, 1				;cx <- # of tabs
	call	TEmitCharToText
noTabs:
	;
	; Emit CRs
	;
	mov	cx, ax				;cx <- current row
	sub	cx, ss:CCSF_local.CCSF_prevTextCell.CR_row
	mov	dx, C_CR			;dx <- character to emit
	call	TEmitCharToText
	pop	cx
	;
	; If we changed rows, we need to go from the first column
	; rather than the previous column, since the CR will take
	; us to the start of the next row.
	;
	mov	dx, ds:[si].SSI_selected.CR_start.CR_column
	;
	; We're now in the same row -- emit tabs to get to the correct column
	;
emitTabs:
	push	cx
	sub	cx, dx				;cx <- # of tabs to emit
	mov	dx, C_TAB			;dx <- character to emit
	call	TEmitCharToText
	pop	cx
	;
	; See if the cell attributes have changed, and set new styles
	; in the text object if so.
	;
	mov	di, es:[di]			;es:di <- ptr to cell data
	mov	dx, es:[di].CC_attrs		;dx <- style token
	cmp	dx, ss:CCSF_local.CCSF_prevTextStyle
	je	gotStyle			;branch if same style
	call	TEmitStylesToText
	mov	ss:CCSF_local.CCSF_prevTextStyle, dx
gotStyle:
	;
	; Emit the actual text
	;
	call	TEmitCellDataToText
	;
	; Save the cell for next time
	;
	mov	ss:CCSF_local.CCSF_prevTextCell.CR_row, ax
	mov	ss:CCSF_local.CCSF_prevTextCell.CR_column, cx
done:

	.leave
	ret
TextCopyCell		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTextObjectPastEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the text object, assuming a range is involved and
		set it to the ever-popular TEXT_ADDRESS_PAST_END.

CALLED BY:	UTILITY
PASS:		same as CallTextObject
		ss:bx - assumed to be VisTextRange
RETURN:		same as CallTextObject
DESTROYED:	same as CallTextObject

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTextObjectPastEnd		proc	near
	.enter	inherit	TextCopyCell

	movdw	ss:[bx].VTR_start,TEXT_ADDRESS_PAST_END
	movdw	ss:[bx].VTR_end, TEXT_ADDRESS_PAST_END

	.leave
	FALL_THRU	CallTextObject
CallTextObjectPastEnd		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the text object we attached to the clipboard

CALLED BY:	UTILITY
PASS:		ss:bp - inherited locals
		ax - message to send to text
		bx - bp to pass to message
		cx, dx - data for message
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTextObject		proc	near
	uses	bx, cx, dx, bp, si, di
	.enter	inherit	TextCopyCell

	push	bx
	movdw	bxsi, ss:CCSF_local.CCSF_textObject
	pop	bp				;bp <- pass to message
EC <	call	ECCheckOD			;>
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
CallTextObject		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEmitCharToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emit a character to the text scrap, and include style
		changes if the character run indicates a change in cells.

CALLED BY:	TextCopyCell()
PASS:		ss:bp - inherited locals
		dx - character to emit
		cx - # of times to emit it
		bx - # of chars already emitted since previous cell
RETURN:		bx - # of chars, updated (length)
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version
	witt	11/15/93	DBCS-ized; this routine uses lengths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TEmitCharToText		proc	near
	uses	ax, dx, di, es
	.enter	inherit	TextCopyCell

EC <	cmp	cx, LARGEST_ROW+1		;>
EC <	ERROR_A SPREADSHEET_TOO_MANY_CHARS_FOR_TEXT_SCRAP >

	segmov	es, ss
charLoop:
	jcxz	done				;branch if no more chars
	;
	; See if we're in the middle of doing a run of more than one
	; character, meaning we're skipping empty cells.
	;
	cmp	bx, 1				;after one char?
	ja	afterRunChecks			;branch if already done it
	jb	noSkip				;branch if not done it yet
	;
	; We're skipping empty cells -- reset the style run to account
	; for the empty cells.
	;
	push	dx
	mov	dx, DEFAULT_STYLE_TOKEN		;dx <- style token to use
	mov	ss:CCSF_local.CCSF_prevTextStyle, dx
	call	TEmitStylesToText
	pop	dx
noSkip:
	;
	; See if we're about to do a run of more than one character.
	; If so, break it up into two parts -- one character, and
	; everything else.
	;
	mov	ax, 1				;ax <- emit only 1st char
	cmp	cx, ax 				;more than one char?
	jae	gotNumChars			;branch if so
	;
	; See if there are more characters than we can fit in our buffer
	; If so, we need to emit them in tasty bite-sized chunks that
	; we can handle.
	;
afterRunChecks:
	mov	ax, cx				;ax <- # to emit
SBCS<	cmp	ax, (size locals.CL_buffer)-1	;too many chars?	>
DBCS<	cmp	ax, ((size locals.CL_buffer)-2)/(size wchar)		>
	jb	gotNumChars			;branch if not too many
SBCS<	mov	ax, (size locals.CL_buffer)-1	;ax <- emit max #	>
DBCS<	mov	ax, ((size locals.CL_buffer)-2)/(size wchar)		>
gotNumChars:
	push	ax, cx
	mov	cx, ax				;cx <- # of chars
	mov	ax, dx				;ax <- char to store
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to buffer
SBCS<	rep	stosb				;store me jesus  	>
DBCS<	rep	stosw				;store me jesus  	>
	pop	ax, cx
	;
	; Add the char(s) to the text object
	;
	push	ax, bx, cx, dx
	mov	cx, ax				;cx <- # of chars to emit
	mov	dx, ss
	lea	bx, ss:locals.CL_buffer		;dx:bx <- ptr to text
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	call	CallTextObject
	pop	ax, bx, cx, dx
	;
	; Update # of characters so far
	;
	sub	cx, ax				;cx <- # of chars left
	add	bx, ax				;ax <- # of chars so far
	jmp	charLoop

done:

	.leave
	ret
TEmitCharToText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEmitStylesToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emit styles to the text scrap

CALLED BY:	TextCopyCell()
PASS:		ss:bp - inherited locals
		ds:si - ptr to SpreadsheetInstance
		dx - style token for styles to emit
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCharAttrParams	struct
    SCAP_params	VisTextSetCharAttrParams
    SCAP_attrs	VisTextCharAttr
SetCharAttrParams	ends

TEmitStylesToText		proc	near
	uses	ax, bx, di, es
	.enter	inherit	TextCopyCell

EC <	call	ECCheckInstancePtr		;>
	;
	; Get the styles
	;
	mov	ax, dx				;ax <- style token
	lea	di, ss:locals.CL_cellAttrs
	segmov	es, ss				;es:di <- ptr to buffer
	call	StyleGetStyleByTokenFar
	;
	; Initialize the parameters for setting in the text
	;
	sub	sp, (size SetCharAttrParams)
	mov	bx, sp				;ss:bx <- ptr to params
	lea	ax, ss:[bx].SCAP_attrs		;ss:ax <- ptr to VisTextCharAttr
	movdw	ss:[bx].SCAP_params.VTSCAP_charAttr, ssax
	push	ds
	segmov	ds, ss
	mov	bx, ax				;ds:bx <- ptr to VisTextCharAttr
	call	ConvertCellAttrsToTextAttrsFar
	pop	ds
	;
	; Set the styles in the text object
	;
	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR
	mov	bx, sp				;ss:bx <- params
CheckHack <(offset SCAP_params.VTSCAP_range) eq 0>
	call	CallTextObjectPastEnd
	add	sp, (size SetCharAttrParams)

	.leave
	ret
TEmitStylesToText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEmitCellDataToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	TEmit cell data to the text object

CALLED BY:	TextCopyCell()
PASS:		ss:bp - inherited locals
		ds:si - ptr to SpreadsheetInstance
		es:di - ptr to cell data
		(ax,cx) - (r,c) of cell
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TEmitCellDataToText		proc	near
	uses	ax, bx, cx, dx
	.enter	inherit	TextCopyCell

EC <	call	ECCheckInstancePtr		;>
	mov	bl, es:[di].CC_type
	clr	bh				;bx <- CellType
	call	cs:cellTextRoutines[bx]
	;
	; We've got the text in CL_buffer -- go to town
	;
	mov	dx, ss
	lea	bx, ss:locals.CL_buffer		;dx:bx <- ptr to text
	clr	cx				;cx <- NULL-terminated
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	call	CallTextObject

	.leave
	ret

cellTextRoutines	nptr \
	temitTextCell,			;CT_TEXT
	temitConstantCell,		;CT_CONSTANT
	temitFormulaCell,		;CT_FORMULA
	temitBadCellType,		;CT_NAME
	temitBadCellType,		;CT_CHART
	temitEmptyCell,			;CT_EMPTY
	temitDisplayFormulaCell		;CT_DISPLAY_FORMULA
CheckHack <(size cellTextRoutines) eq CellType>

temitTextCell:
	call	GetTextCellAsTextFar
	retn

temitConstantCell:
	call	GetConstantCellAsTextFar
	retn

temitFormulaCell:
	call	GetFormulaCellAsTextFar
	retn

temitDisplayFormulaCell:
	call	GetDisplayFormulaCellAsTextFar
	retn

temitBadCellType:
EC <	ERROR	ILLEGAL_CELL_TYPE >
temitEmptyCell:
	mov	{word}ss:locals.CL_buffer, 0
	retn

TEmitCellDataToText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEmitTabsForColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emit tab stops that correspond to the column widths.

CALLED BY:	TextCopyInit()
PASS:		ss:bp - inherited locals
		ds:si - SpreadsheetInstance
RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TEmitTabsForColumns		proc	near
	uses	cx, dx
	class	SpreadsheetClass
	.enter	inherit TextCopyInit

EC <	call	ECCheckInstancePtr		;>
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	;
	; Common setup
	;
	sub	sp, (size VisTextSetTabParams)
	mov	bx, sp				;ss:bx <- params
	mov	ss:[bx].VTSTP_tab.T_grayScreen, SDM_100
	mov	ss:[bx].VTSTP_tab.T_anchor, C_PERIOD
	clr	ax
	mov	ss:[bx].VTSTP_tab.T_position, ax	;tabs relative to 0
	mov	ss:[bx].VTSTP_tab.T_attr, al		;left, no leader
	mov	ss:[bx].VTSTP_tab.T_lineWidth, al
	mov	ss:[bx].VTSTP_tab.T_lineSpacing, al
	;
	; Set tabs corresponding to each column
	;
tabLoop:
	cmp	cx, dx				;to last column?
	je	doneTabs			;branch if last column
	push	dx
	call	ColumnGetWidthFar
	jz	hiddenColumn			;branch if column hidden
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1				;dx <- width * 8
	add	ss:[bx].VTSTP_tab.T_position, dx
	jc	doneTabsPop			;quit if overflow
	mov	ax, MSG_VIS_TEXT_SET_TAB
	call	CallTextObjectPastEnd
hiddenColumn:
	pop	dx
	inc	cx				;cx <- next column
	jmp	tabLoop

doneTabsPop:
	pop	dx				;clean up stack
doneTabs:
	add	sp, (size VisTextSetTabParams)

	.leave
	ret
TEmitTabsForColumns		endp

CutPasteCode	ends
