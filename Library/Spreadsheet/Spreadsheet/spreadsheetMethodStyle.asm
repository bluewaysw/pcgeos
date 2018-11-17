COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetMethodStyle.asm

AUTHOR:		Gene Anderson, Mar  2, 1991

ROUTINES:
	Name				Description
	----				-----------
MSG_VIS_TEXT_SET_FONT			Set the font for the current selection
MSG_VIS_TEXT_SET_STYLE			Set the style for the current selection
MSG_VIS_TEXT_SET_POINT_SIZE		Set the pointsize for the selection
MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE	Set the next smaller pointsize
MSG_VIS_TEXT_SET_LARGER_POINT_SIZE	Set the next larger pointsize
MSG_VIS_TEXT_SET_PARA_ATTRIBUTES	Set the justification for the selection
MSG_VIS_TEXT_SET_COLOR			Set the text color
MSG_VIS_TEXT_SET_GRAY_SCREEN		Set the text hatch pattern
MSG_VIS_TEXT_SET_CHAR_BG_COLOR		Set the background color
MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN	Set the background hatch pattern
MSG_VIS_TEXT_SET_TRACK_KERNING		Set track kerning
MSG_VIS_TEXT_SET_FONT_WIDTH		Set font width
MSG_VIS_TEXT_SET_FONT_WEIGHT		Set font weight

MSG_SPREADSHEET_SET_NUM_FORMAT		Set the numeric format for selection

INT	SetAttrsCommon			Common attribute setting, part I
INT	SetAttrsFinish			Common attribute setting, part II


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 2/91		Initial revision

DESCRIPTION:
	Method handlers for setting style/cell attributes.

	$Id: spreadsheetMethodStyle.asm,v 1.2 98/03/14 21:55:02 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AttrCode	segment	resource

;
; NOTE: -1 for SAS_columnCallback or SAS_wholeCallback means that
; paritcular optimization cannot be used.
; NOTE: note that SAS_wholeCallback is just the offset of the routine;
; it must be a far routine, but in the AttrCode segment.
;
SetAttrStruct	struct
    SAS_cellCallback	nptr.near		;callback for single cell
    SAS_columnCallback	nptr.near		;callback for column
    SAS_wholeCallback	nptr			;offset of callback for whole
    SAS_attrOff		word			;offset in CellAttrs
    SAS_notifyRoutine	nptr.near		;routine for notification
    SAS_notifyFlags	SpreadsheetNotifyFlags	;flags for update
SetAttrStruct	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetTrackKerning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set track kerning for selected cells

CALLED BY:	MSG_VIS_TEXT_SET_TRACK_KERNING
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - VisTextSetTrackKerningParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSetTrackKerning		method dynamic SpreadsheetClass,
						MSG_VIS_TEXT_SET_TRACK_KERNING
	mov	ax, {word}ss:[bp].VTSTKP_trackKerning
	mov	bx, offset setTrackKernParams
	GOTO	SetSpreadsheetAttrs

setTrackKernParams SetAttrStruct <
	SetWordAttr,				;cell
	SetWordAttr,				;column
	offset ChangeWordAttrCallback,		;spreadsheet
	offset CA_trackKern,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetTrackKerning		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetFontWeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set font weight for selected cells

CALLED BY:	MSG_VIS_TEXT_SET_FONT_WEIGHT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - VisTextSetFontWeightParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSetFontWeight		method dynamic SpreadsheetClass,
						MSG_VIS_TEXT_SET_FONT_WEIGHT
	mov	al, ss:[bp].VTSFWP_fontWeight
	mov	bx, offset setFontWeightParams
	GOTO	SetSpreadsheetAttrs

setFontWeightParams SetAttrStruct <
	SetByteAttr,				;cell
	SetByteAttr,				;column
	offset ChangeByteAttrCallback,		;spreadsheet
	offset CA_fontWeight,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetFontWeight		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetFontWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set font width for selected cells

CALLED BY:	MSG_VIS_TEXT_SET_FONT_WIDTH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ss:bp - VisTextSetFontWidthParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSetFontWidth		method dynamic SpreadsheetClass,
						MSG_VIS_TEXT_SET_FONT_WIDTH
	mov	al, ss:[bp].VTSFWIP_fontWidth
	mov	bx, offset setFontWidthParams
	GOTO	SetSpreadsheetAttrs

setFontWidthParams SetAttrStruct <
	SetByteAttr,				;cell
	SetByteAttr,				;column
	offset ChangeByteAttrCallback,		;spreadsheet
	offset CA_fontWidth,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetFontWidth		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetJustification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set justification for current selection.
CALLED BY:	MSG_VIS_TEXT_SET_PARA_ATTRIBUTES

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - VisTextSetParaAttrAttributesParams
			VTSPAAP_bitsToSet - VisTextParaAttrAttributes
			VTSPAAP_bitsToClear - VisTextParaAttrAttributes

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetJustification	method dynamic SpreadsheetClass, \
				MSG_VIS_TEXT_SET_PARA_ATTRIBUTES
	mov	ax, ss:[bp].VTSPAAP_bitsToSet
	andnf	ax, mask VTPAA_JUSTIFICATION
if (offset VTPAA_JUSTIFICATION ne 0)
	mov	cl, offset VTPAA_JUSTIFICATION
	shr	ax, cl				;al <- Justification
endif

	mov	bx, offset setJustificationParams
	GOTO	SetSpreadsheetAttrs

setJustificationParams SetAttrStruct <
	SetByteAttr,				;cell
	SetByteAttr,				;column
	offset ChangeByteAttrCallback,		;spreadsheet
	offset CA_justification,
	AttrUpdateUIRedrawSelection,
	mask SNF_JUSTIFICATION
>
SpreadsheetSetJustification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text color for the selection
CALLED BY:	MSG_VIS_TEXT_SET_COLOR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - VisTextSetColorParams
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetTextColor	method dynamic SpreadsheetClass, \
					MSG_VIS_TEXT_SET_COLOR

	mov	ax, {word}ss:[bp].VTSCP_color.CQ_redOrIndex
	mov	dx, {word}ss:[bp].VTSCP_color.CQ_green
						;dl <- index/red dh <- ColorFlag
						;al <- green ah <- blue

	mov	bx, offset setTextColorParams
	GOTO	SetSpreadsheetAttrs

setTextColorParams SetAttrStruct <
	SetDWordAttr,				;cell
	SetDWordAttr,				;column
	offset ChangeDWordAttrCallback,		;spreadsheet
	offset CA_textAttrs.AI_color,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetTextColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetTextGrayScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text color for the selection
CALLED BY:	MSG_VIS_TEXT_SET_GRAY_SCREEN

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - VisTextSetGrayScreenParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetTextGrayScreen	method dynamic SpreadsheetClass, \
					MSG_VIS_TEXT_SET_GRAY_SCREEN

	mov	al, ss:[bp].VTSGSP_grayScreen	;al <- hatch pattern
	mov	bx, offset setTextGrayScreenParams
	GOTO	SetSpreadsheetAttrs

setTextGrayScreenParams SetAttrStruct <
	SetByteAttr,				;cell
	SetByteAttr,				;column
	offset ChangeByteAttrCallback,		;spreadsheet
	offset CA_textAttrs.AI_grayScreen,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetTextGrayScreen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the background color for the selection
CALLED BY:	MSG_VIS_TEXT_SET_CHAR_BG_COLOR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - VisTextSetColorParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: this cannot be optimized the same as the other attribute
	setting routines because empty cells are not drawn, and a
	background color requires drawing even on an empty cell.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetBackgroundColor	method dynamic SpreadsheetClass, \
					MSG_VIS_TEXT_SET_CHAR_BG_COLOR

	mov	ax, {word}ss:[bp].VTSCP_color.CQ_redOrIndex
	mov	dx, {word}ss:[bp].VTSCP_color.CQ_green
						;al <- index/red ah <- ColorFlag
						;dl <- green dh <- blue
	mov	bx, offset setBackgroundColorParams
	GOTO	SetSpreadsheetAttrs

setBackgroundColorParams SetAttrStruct <
	SetDWordAttr,				;cell
	-1,					;can't optimize columns
	-1,					;can't optimize whole ssheet
	offset CA_bgAttrs.AI_color,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetBackgroundColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetCharBGGrayScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text color for the selection
CALLED BY:	MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - VisTextSetGrayScreenParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: unlike background color, this *can* be optimized in the
	standard fashion, because if a cell doesn't exist, it's background
	color is white, and therefore is unaffected by grayscreen.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetCharBGGrayScreen	method dynamic SpreadsheetClass, \
					MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN

	mov	al, ss:[bp].VTSGSP_grayScreen	;al <- hatch pattern
	mov	bx, offset setBGGrayScreenParams
	GOTO	SetSpreadsheetAttrs

setBGGrayScreenParams SetAttrStruct <
	SetByteAttr,				;cell
	SetByteAttr,				;column
	offset ChangeByteAttrCallback,		;spreadsheet
	offset CA_bgAttrs.AI_grayScreen,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetCharBGGrayScreen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetNumFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the number format for the selected range
CALLED BY:	MSG_SPREADSHEET_SET_NUM_FORMAT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - format token

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetNumFormat	method	SpreadsheetClass, \
					MSG_SPREADSHEET_SET_NUM_FORMAT
	mov	ax, cx				;pass format token to callback
	mov	bx, offset setNumFormatParams
	GOTO	SetSpreadsheetAttrs

setNumFormatParams SetAttrStruct <
	SetWordAttr,				;cell
	SetWordAttr,				;column
	offset ChangeWordAttrCallback,		;spreadsheet
	offset CA_format,
	AttrUpdateUIRedrawSelection,
	mask SNF_FORMAT_CHANGE
>
SpreadsheetSetNumFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the font for the current selection
CALLED BY:	MSG_VIS_TEXT_SET_FONT_ID

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
		ss:bp - VisTextSetFontIDParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetFont	method dynamic SpreadsheetClass, \
					MSG_VIS_TEXT_SET_FONT_ID

	mov	ax, ss:[bp].VTSFIDP_fontID	;ax <- FontID
	mov	bx, offset setFontParams
	GOTO	SetSpreadsheetAttrs

setFontParams SetAttrStruct <
	SetWordAttr,				;cell
	SetWordAttr,				;column
	offset ChangeWordAttrCallback,		;spreadsheet
	offset CA_font,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetFont	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the pointsize for the current selection
CALLED BY:	MSG_SPREADSHEET_SET_POINTSIZE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
		ss:bp - VisTextSetPointSizeParams
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: we cannot optimize setting the pointsize for column operations
	because empty cells in a column with a non-default pointsize need
	to exist as the new pointsize affects the row height.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetPointsize	method dynamic SpreadsheetClass, \
				MSG_VIS_TEXT_SET_POINT_SIZE

	mov	ax, ss:[bp].VTSPSP_pointSize.WWF_int
	mov	cx, ss:[bp].VTSPSP_pointSize.WWF_frac
	shlwbf	axch
	shlwbf	axch
	shlwbf	axch				;ax <- pointsize * 8

	mov	bx, offset setPointsizeParams
	GOTO	SetSpreadsheetAttrs

setPointsizeParams SetAttrStruct <
	SetWordAttr,				;cell
	-1,					;can't optimize columns (yet)
	offset ChangeWordAttrCallback,		;spreadsheet
	offset CA_pointsize,
	SetPointsizeRecalc,
	mask SNF_CHAR_ATTR or mask SNF_CELL_WIDTH_HEIGHT
>
SpreadsheetSetPointsize		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointsizeRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate and redraw after setting the pointsize
CALLED BY:	SpreadsheetSet{,Smaller,Larger}Pointsize(),

PASS:		ds:si - ptr to spreadsheet instance
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPointsizeRecalc	proc	near
	.enter
	;
	; Recalculate row heights
	;
	call	RecalcRowHeightsFar
	;
	; Recalcuate the document size for the view, update the UI,
	; and redraw
	;
	mov	ax, mask SNF_CHAR_ATTR or mask SNF_CELL_WIDTH_HEIGHT
	call	UpdateDocUIRedrawAll

	.leave
	ret
SetPointsizeRecalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetSmallerPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set next smaller pointsize for current selection
CALLED BY:	MSG_SPREADSHEET_SET_SMALLER_POINTSIZE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: we cannot optimize setting the pointsize for column operations
	because empty cells in a column with a non-default pointsize need
	to exist as the new pointsize affects the row height.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

pointSizeTable	word \
	4*8, 6*8, 8*8, 9*8, 10*8, 12*8, 14*8, 18*8, 24*8, 36*8, \
	54*8, 72*8, 144*8, 180*8, 216*8

MIN_TABLE_POINTSIZE	equ	4*8
MAX_TABLE_POINTSIZE	equ	216*8
TABLE_POINTSIZE_INC	equ	72*8

SpreadsheetSetSmallerPointsize	method dynamic SpreadsheetClass, \
				MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE
	mov	bx, offset setPointsizeSmallerParams
	GOTO	SetSpreadsheetAttrs

setPointsizeSmallerParams SetAttrStruct <
	SetSmallerPointsize,			;cell
	-1,					;can't optimize columns (yet)
	offset ChangeSmallerPointsizeCallback,	;spreadsheet
	offset CA_pointsize,
	SetPointsizeRecalc,
	mask SNF_CHAR_ATTR or mask SNF_CELL_WIDTH_HEIGHT
>
SpreadsheetSetSmallerPointsize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeSmallerPointsizeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change pointsize to smaller entry for all CellAttrs

CALLED BY:	SpreadsheetSetSmallerPointsize() via StyleTokenChangeAttr()
PASS:		ds:di - ptr to CellAttrs structure
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeSmallerPointsizeCallback		proc	far
	uses	ax
	.enter

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

	mov	ax, ds:[di].CA_pointsize
	call	FindSmallerPointsize
	mov	ds:[di].CA_pointsize, ax
EC <done:					;>
	clc					;carry <- don't abort
	.leave
	ret
ChangeSmallerPointsizeCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSmallerPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set next smaller pointsize for a cell
CALLED BY:	SpreadsheetSetSmallerPointsize() via RangeEnum()

PASS:		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSmallerPointsize	proc	near
locals	local	CellLocals
	.enter	inherit

	mov	ax, ss:locals.CL_cellAttrs.CA_pointsize
	call	FindSmallerPointsize
	mov	ss:locals.CL_cellAttrs.CA_pointsize, ax

	.leave
	ret
SetSmallerPointsize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSmallerPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next smaller pointsize

CALLED BY:	SetSmallerPointsize()
PASS:		ax - current pointsize
RETURN:		ax - next smaller pointsize
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindSmallerPointsize		proc	near
	uses	si
	.enter

	;
	; Before start of table?
	;
	cmp	ax, MIN_TABLE_POINTSIZE
	je	setSize
	;
	; After end of table?
	;
	cmp	ax, MAX_TABLE_POINTSIZE
	ja	bigPointsize
	clr	si
sizeLoop:
	cmp	ax, cs:pointSizeTable[si]
	jbe	foundSize
	add	si, (size word)
	jmp	sizeLoop

bigPointsize:
	;
	; See if it is just past the end of the table
	;
	cmp	ax, MAX_TABLE_POINTSIZE + TABLE_POINTSIZE_INC
	jb	useLast
	sub	ax, (TABLE_POINTSIZE_INC)
	jmp	setSize

	;
	; If just past the end of the table, use the last value
	;
useLast:
	mov	ax, MAX_TABLE_POINTSIZE
	jmp	setSize

foundSize:
	mov	ax, cs:pointSizeTable[si][-2]
setSize:

	.leave
	ret
FindSmallerPointsize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetLargerPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set next larger pointsize for current selection
CALLED BY:	MSG_SPREADSHEET_SET_LARGER_POINTSIZE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: we cannot optimize setting the pointsize for column operations
	because empty cells in a column with a non-default pointsize need
	to exist as the new pointsize affects the row height.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetLargerPointsize	method dynamic SpreadsheetClass, \
				MSG_VIS_TEXT_SET_LARGER_POINT_SIZE
	mov	bx, offset setPointsizeLargerParams
	GOTO	SetSpreadsheetAttrs

setPointsizeLargerParams SetAttrStruct <
	SetLargerPointsize,			;cell
	-1,					;can't optimize columns (yet)
	offset ChangeLargerPointsizeCallback,	;spreadsheet
	offset CA_pointsize,
	SetPointsizeRecalc,
	mask SNF_CHAR_ATTR or mask SNF_CELL_WIDTH_HEIGHT
>
SpreadsheetSetLargerPointsize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeLargerPointsizeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change pointsize to larger entry for all CellAttrs

CALLED BY:	SpreadsheetSetLargerPointsize() via StyleTokenChangeAttr()
PASS:		ds:di - ptr to CellAttrs structure
RETURN:		carry - set to abort
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeLargerPointsizeCallback		proc	far
	uses	ax
	.enter

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

	mov	ax, ds:[di].CA_pointsize
	call	FindLargerPointsize
	mov	ds:[di].CA_pointsize, ax
EC <done:					;>
	clc					;carry <- don't abort
	.leave
	ret
ChangeLargerPointsizeCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLargerPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set next larger pointsize for a cell
CALLED BY:	SetAttrs()

PASS:		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetLargerPointsize	proc	near
locals		local	CellLocals
	.enter	inherit

	mov	ax, ss:locals.CL_cellAttrs.CA_pointsize
	call	FindLargerPointsize
	mov	ss:locals.CL_cellAttrs.CA_pointsize, ax

	.leave
	ret
SetLargerPointsize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLargerPointsize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next larger pointsize

CALLED BY:	SetLargerPointsize()
PASS:		ax - pointsize
RETURN:		ax - next larger pointsize
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLargerPointsize		proc	near
	uses	si
	.enter

	;
	; After end of table?
	;
	cmp	ax, MAX_TABLE_POINTSIZE
	jae	bigPointsize
	clr	si
sizeLoop:
	cmp	ax, cs:pointSizeTable[si]
	jb	foundSize
	add	si, (size word)
	jmp	sizeLoop

bigPointsize:
	add	ax, TABLE_POINTSIZE_INC
	cmp	ax, MAX_POINT_SIZE*8
	jbe	setSize
	mov	ax, MAX_POINT_SIZE*8
	jmp	setSize

foundSize:
	mov	ax, cs:pointSizeTable[si]
setSize:

	.leave
	ret
FindLargerPointsize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text style for the current selection
CALLED BY:	MSG_SPREADSHEET_SET_STYLE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		ss:bp - VisTextSetTextStyleParams
			VTSTSP_styleBitsToSet (TextStyle)
			VTSTSP_styleBitsToClear (TextStyle)
		dx - size (VisTextSetTextStyleParams)

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetTextStyle	method dynamic SpreadsheetClass, \
						MSG_VIS_TEXT_SET_TEXT_STYLE
	mov	ah, {byte}ss:[bp].VTSTSP_styleBitsToSet
	mov	al, {byte}ss:[bp].VTSTSP_styleBitsToClear
EC <	tst	{byte}ss:[bp].VTSTSP_styleBitsToSet.high >
EC <	ERROR_NZ UNUSED_STYLE_BITS_NON_ZERO >
EC <	tst	{byte}ss:[bp].VTSTSP_styleBitsToClear.high >
EC <	ERROR_NZ UNUSED_STYLE_BITS_NON_ZERO >
	mov	bx, offset setTextStyleParams
	GOTO	SetSpreadsheetAttrs

setTextStyleParams SetAttrStruct <
	SetTextStyle,				;cell
	SetTextStyle,				;column
	offset ChangeTextStyleCallback,		;spreadsheet
	offset CA_style,
	AttrUpdateUIRedrawSelection,
	mask SNF_CHAR_ATTR
>
SpreadsheetSetTextStyle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeTextStyleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the TextStyle for all cells

CALLED BY:	SpreadsheetSetStyle() via StyleTokenChangeAttr()
PASS:		ds:di - ptr to CellAttrs
		ss:bp - inherited locals
			CL_data1.low - TextStyle to clear
			CL_data1.high - TextStyle to set
RETURN:		carry - set to abort
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeTextStyleCallback		proc	far
locals	local	CellLocals
	.enter	inherit

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

	mov	ax, ss:locals.CL_data1		;al <- set, ah <- clear
	not	al				;al <- bits to keep
	andnf	ds:[di].CA_style, al		;clear other bits
	ornf	ds:[di].CA_style, ah		;set specified bits
EC <done:					;>
	clc					;carry <- don't abort

	.leave
	ret
ChangeTextStyleCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/Clear style bits for a cell
CALLED BY:	CellSetAttrs()

PASS:		ss:bp - inherited locals
			CL_data1.low - TextStyle to clear
			CL_data1.high - TextStyle to set
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTextStyle	proc	near
locals		local	CellLocals

	.enter	inherit

	mov	ax, ss:locals.CL_data1		;al, ah <- TextStyle
	not	al				;al <- bits to keep
	andnf	ss:locals.CL_cellAttrs.CA_style, al
	ornf	ss:locals.CL_cellAttrs.CA_style, ah

	.leave
	ret
SetTextStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAttrsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common cell attribute setting
CALLED BY:	CellSetAttrs()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - SpreadsheetInstance ptr
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any
RETURN:		*es:di - ptr to cell data
		ss:bp.CL_cellAttrs - current cell attributes
		carry - unchanged
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetAttrsCommon	proc	near
	uses	ax, dx
locals		local	CellLocals

	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	pushf					;preserve carry
	push	es, di

	jnc	noData				;branch if cell empty

	mov	di, es:[di]			;es:di <- ptr to cell
	mov	ax, es:[di].CC_attrs		;ax <- style token
	lea	di, locals.CL_cellAttrs
	segmov	es, ss				;es:di <- ptr to cellAttrs
	call	StyleGetStyleByTokenFar		;get styles for cell
	call	StyleDeleteStyleByToken		;one less reference to old
done:
	pop	es, di
	popf					;recover carry

	.leave
	ret

	;
	; The cell doesn't exist yet -- get the default attrs for it
	;
noData:
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- new style token
	lea	di, locals.CL_cellAttrs
	segmov	es, ss				;es:di <- ptr to cellAttrs
	call	StyleGetStyleByTokenFar
	jmp	done
SetAttrsCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAttrsFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish setting cell attributes -- may create cell
CALLED BY:	CellSetAttrs()

PASS:		ss:bp - ptr to CallRangeEnum() local variables
			CL_cellAttrs - set for cell
		ds:si - ptr to Spreadsheet instance data
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data
RETURN:		*es:di - updated if cell created
		dl - RangeEnumFlags with:
			 REF_ALLOCATED bit set if we've allocated a cell
			 REF_FREED if we've freed a cell
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	assumes CL_cellAttrs is set
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetAttrsFinish	proc	near
	uses	ax, bx
	class	SpreadsheetClass

locals		local	CellLocals

	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	jc	hasData				;branch if cell exists
	;
	; The cell doesn't exist -- allocate one using the attributes
	; we've got.
	;
	lea	bx, locals.CL_cellAttrs		;ss:bx <- use passed attrs
	call	AllocEmptyCell
	SpreadsheetCellLock			;*es:di <- ptr to the cell
	mov	dl, mask REF_CELL_ALLOCATED	;dl <- allocated a cell
	jmp	done

	;
	; The cell does exist.  Make sure it should bother...
	;
hasData:
	;
	; Get the token for the specified attributes.
	;
	push	es, di, ax
	lea	di, locals.CL_cellAttrs
	segmov	es, ss				;es:di <- ptr to cellAttrs
	call	StyleGetTokenByStyleFar
	mov	bx, ax				;bx <- new style token
	pop	es, di, ax
	;
	; Is this cell around for a reason?
	;
	push	di
	mov	di, es:[di]			;es:di <- ptr to cell
	cmp	es:[di].CC_type, CT_EMPTY	;'empty' cell?
	jne	setAttrs			;branch if not empry
	tst	es:[di].CC_dependencies.high
	jnz	setAttrs			;branch if dependencies
	tst	es:[di].CC_notes.high
	jnz	setAttrs			;branch if notes
	;
	; NOTE: this uses the default column attrs, not DEFAULT_STYLE_TOKEN
	; because we want the cell to go away if it is empty except for
	; attributes and those attributes are the default for the column.
	;
	call	ColumnGetDefaultAttrs
	cmp	bx, dx				;default attributes?
	jne	setAttrs			;branch if not defaults
	;
	; Delete one reference (to the default column attributes)
	;
	push	ax
	mov	ax, bx				;ax <- attrs from cell
	call	StyleDeleteStyleByToken
	pop	ax
	;
	; The cell existed only to hold the style attributes, and we're
	; about to set those to the default.  Nuke the little bugger...
	;
	SpreadsheetCellUnlock
	clr	dx				;dx <- delete the cell
	SpreadsheetCellReplaceAll
	mov	dl, mask REF_CELL_FREED		;dl <- freed the cell
	pop	di
	jmp	done

	;
	; The cell exists, has non-default attributes or something else to
	; cause it to exist.  Set the attributes.
	;
setAttrs: 
	mov	es:[di].CC_attrs, bx		;set new attrs
	SpreadsheetCellDirty			;mark cell as dirty
	pop	di				;*es:di <- cell data
	clr	dl				;dl <- no change in cells
done:

	.leave
	ret
SetAttrsFinish	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetCellBorders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set cell borders for the selected cells
CALLED BY:	MSG_SPREADSHEET_SET_CELL_BORDERS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cl - CellBorderInfo to set

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: this cannot be optimized the same as the other attribute
	setting routines because empty cells are not drawn, and
	cell borders requires drawing even on an empty cell.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetCellBorders	method dynamic SpreadsheetClass, \
					MSG_SPREADSHEET_SET_CELL_BORDERS
	mov	al, cl				;al <- CellBorderInfo
	mov	bx, offset setCellBorderParams
	GOTO	SetSpreadsheetAttrs

setCellBorderParams SetAttrStruct <
	SetBorders,				;cell
	-1,					;can't optimize columns
	-1,					;can't optimize whole ssheet
	offset CA_border,
	AttrUpdateUIRedrawSelection,
	mask SNF_CELL_ATTRS
>
SpreadsheetSetCellBorders	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBorders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set borders for a cell
CALLED BY:	SpreadsheetSetCellBorders() via RangeEnum()

PASS:		ss:bp - inherited locals
			CL_data1.low - CellBorderInfo
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetBorders	proc	near
	uses	bx
locals		local	CellLocals

	.enter	inherit

	;
	; Are we doing outline?
	;
	mov	bl, {byte}ss:locals.CL_data1
	test	bl, mask CBI_OUTLINE
	jz	noOutline			;branch if not outline
	;
	; We're doing outline -- add the appropriate sides
	;
	clr	bl				;bl <- CellBorderInfo
	cmp	ax, ss:locals.CL_params.REP_bounds.R_top
	jne	notTop
	ornf	bl, mask CBI_TOP
notTop:
	cmp	ax, ss:locals.CL_params.REP_bounds.R_bottom
	jne	notBottom
	ornf	bl, mask CBI_BOTTOM
notBottom:
	cmp	cx, ss:locals.CL_params.REP_bounds.R_left
	jne	notLeft
	ornf	bl, mask CBI_LEFT
notLeft:
	cmp	cx, ss:locals.CL_params.REP_bounds.R_right
	jne	notRight
	ornf	bl, mask CBI_RIGHT
notRight:
	;
	; Set the CellBorderInfo flags for the cell
	;
noOutline:
	mov	ss:locals.CL_cellAttrs.CA_border, bl

	.leave
	ret
SetBorders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetBorderColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set border color for selected cells
CALLED BY:	MSG_SPREADSHEET_SET_BORDER_COLOR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		ch - ColorFlag
		CF_INDEX:
			cl - Color
		CF_RGB:
			cl - red
			dl - green
			dh - blue

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: unlike cell borders, this routine *can* be optimized because
	if a cell doesn't exist, it has no cell borders which are therefore
	unaffected by color.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetBorderColor	method dynamic SpreadsheetClass,
					MSG_SPREADSHEET_SET_CELL_BORDER_COLOR
	mov	ax, cx				;al, ah <- Color, red
	mov	bx, offset setBorderColorParams
	GOTO	SetSpreadsheetAttrs

setBorderColorParams SetAttrStruct <
	SetDWordAttr,				;cell
	SetDWordAttr,				;column
	offset ChangeDWordAttrCallback,		;spreadsheet
	offset CA_borderAttrs.AI_color,
	AttrUpdateUIRedrawSelection,
	mask SNF_CELL_ATTRS
>
SpreadsheetSetBorderColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetBorderGrayScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set border gray screen for selected cells
CALLED BY:	MSG_SPREADSHEET_SET_BORDER_GRAY_SCREEN

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cl - SystemDrawMask

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	NOTE: unlike cell borders, this routine *can* be optimized because
	if a cell doesn't exist, it has no cell borders which are therefore
	unaffected by gray screen.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetSetBorderGrayScreen	method dynamic SpreadsheetClass,
				MSG_SPREADSHEET_SET_CELL_BORDER_GRAY_SCREEN
	mov	al, cl				;al <- SystemDrawMask
	mov	bx, offset setBorderGrayScreenParams
	GOTO	SetSpreadsheetAttrs

setBorderGrayScreenParams SetAttrStruct <
	SetByteAttr,				;cell
	SetByteAttr,				;column
	offset ChangeByteAttrCallback,		;spreadsheet
	offset CA_borderAttrs.AI_grayScreen,
	AttrUpdateUIRedrawSelection,
	mask SNF_CELL_ATTRS
>
SpreadsheetSetBorderGrayScreen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAllSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the entire spreadsheet is selected

CALLED BY:	UTILITY
PASS:		ds:si - ptr to SpreadsheetInstance
RETURN:		carry - set if entire spreadsheet selected
		z flag - set (jz) if entire column(s) selected
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAllSelected		proc	near
	uses	ax
	class	SpreadsheetClass
	.enter

	;
	; See if there is an entire column selected
	;
	tst	ds:[si].SSI_selected.CR_start.CR_row
	jnz	notAllNoColumn
	mov	ax, ds:[si].SSI_selected.CR_end.CR_row
	cmp	ax, ds:[si].SSI_maxRow
	jb	notAllNoColumn
	;
	; See if there is an entire row selected
	;
	tst	ds:[si].SSI_selected.CR_start.CR_column
	jnz	notAll
	mov	ax, ds:[si].SSI_selected.CR_end.CR_column
	cmp	ax, ds:[si].SSI_maxCol
	jb	notAll
	;
	; The whole spreadsheet is selected (which means entire columns, too)
	;
	clr	ax				;z flag <- columns selected
	stc					;carry <- all selected
	jmp	done

	;
	; The whole spreadsheet isn't selected, and no entire columns
	;
notAllNoColumn:
	or	al, 1				;clears carry, clears z flag
	jmp	done

	;
	; The whole spreadsheet isn't selected, but entire columns are
	;
notAll:
	clr	ax				;clears carry, sets z flag
done:

	.leave
	ret
CheckAllSelected		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSpreadsheetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for setting spreadsheet attributes

CALLED BY:	UTILITY
PASS:		*ds:si - Spreadsheet object
		ax, dx - data to pass to callback
		cs:bx - ptr to SetAttrStruct
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSpreadsheetAttrs		proc	far
locals	local	CellLocals
	class	SpreadsheetClass
	.enter

	call	SpreadsheetMarkBusy
	;
	; Do common setup
	;
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset

	mov	ss:locals.CL_data1, ax		;pass data to callback
	mov	ss:locals.CL_data2, dx		;pass data to callback
	mov	ss:locals.CL_data3, bx		;pass offset of SetAttrStruct
	;
	; IMPORTANT: invalidate the attributes set in the cached GState.
	; This is because while the token may remain the same, the
	; attributes it represents no longer do.
	;
	mov	ds:[si].SSI_curAttrs, -1
	;
	; Check for special cases
	;
	call	CheckAllSelected
	jc	doAll				;branch if all selected
	jz	doColumn			;branch if column(s) selected
	;
	; Call the callback routine for all cells in the selection
	;
doEnumAll:
	mov	di, mask REF_ALL_CELLS		;di <- all cells
callEnum:
	mov	ss:locals.CL_params.REP_callback.offset, offset CellSetAttrs
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	call	CallRangeEnumSelected
doRedraw:
	;
	; Update the UI and redraw appropriatly
	;
	call	cs:[bx].SAS_notifyRoutine

	call	SpreadsheetMarkNotBusy

	.leave
	ret

	;
	; The entire spreadsheet is selected -- set the attributes for
	; everything in our ever-so-quick way if we can.
	;
doAll:
	mov	ax, cs:[bx].SAS_wholeCallback	;ax <- callback
	cmp	ax, -1				;optimization allowed?
	je	doEnumAll			;branch if no optimization
	mov	dx, cs:[bx].SAS_attrOff		;dx <- offset of attribute
	push	bx
	mov	bx, cs
	mov	di, ax				;bx:di <- callback
	call	StyleTokenChangeAttr
	pop	bx
	jmp	doRedraw

	;
	; One or more columns are selected -- optimize if we can
	;
doColumn:
	mov	ax, cs:[bx].SAS_columnCallback	;ax <- callback
	cmp	ax, -1				;optimization allowed?
	je	doEnumAll			;branch if no optimization
	;
	; Set the default attributes for the columns
	;
	call	SetColumnAttrs
	;
	; Set the attributes for any existing cells
	;
	clr	di				;di <- only existing cells
	jmp	callEnum
SetSpreadsheetAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetColumnAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set default attributes for the selected columns

CALLED BY:	SetSpreadsheetAttrs()
PASS:		ds:si - ptr to Spreadsheet instance
		cs:bx - ptr to SetAttrStruct
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetColumnAttrs		proc	near
	uses	es
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	segmov	es, ss, di
	lea	di, locals.CL_cellAttrs		;es:di <- ptr to CellAttrs
columnLoop:
	;
	; Get the current attrs
	;
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- attr token for column
	call	StyleGetStyleByTokenFar		;get associated styles
	call	StyleDeleteStyleByToken
	;
	; Modify the attrs to include what's new
	;
	call	cs:[bx].SAS_columnCallback
	;
	; Set the new default attributes
	;
	call	StyleGetTokenByStyleFar		;ax <- new attr token
	call	ColumnSetDefaultAttrs
	;
	; loop while more columns
	;
	inc	cx
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	jbe	columnLoop			;loop while more columns

	.leave
	ret
SetColumnAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AttrUpdateUIRedrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	AttrCode version of UpdateUIRedrawSelection()

CALLED BY:	UTILITY
PASS:		ds:si - ptr to Spreadsheet instance
		cs:bx - ptr to SetAttrStruct
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AttrUpdateUIRedrawSelection		proc	near
	.enter

	mov	ax, cs:[bx].SAS_notifyFlags	;ax <- SpreadsheetNotifyFlags
	call	UpdateUIRedrawSelection

	.leave
	ret
AttrUpdateUIRedrawSelection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to set attribute for a cell

CALLED BY:	SetSpreadsheetAttrs() via RangeEnum()
PASS:		ss:bp - ptr to CallRangeEnum() local variables
		ds:si - ptr to SpreadsheetInstance data
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any

		CL_data3 - offset of SetAttrStruct
		CL_data1, CL_data2 - data for callback

RETURN:		carry - set to abort enum
		dl - RangeEnumFlags with REF_ALLOCATED bit set if we've
		     allocated a cell.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: this routine uses near callbacks and therefore must have
	any callback routines in the same segment.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CellSetAttrs		proc	far
	uses	bx, di
locals	local	CellLocals
	.enter	inherit

	call	SetAttrsCommon

	pushf
	push	ax

	mov	bx, ss:locals.CL_data3		;cs:bx <- ptr to SetAttrStruct
	call	cs:[bx].SAS_cellCallback

	pop	ax
	popf
	call	SetAttrsFinish
	clc					;carry <- don't abort

	.leave
	ret
CellSetAttrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetByteAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to set a byte attribute

CALLED BY:	CellSetAttrs()
PASS:		cs:bx - ptr to SetAttrStruct
		ss:bp - inherited locals
			CL_data1.low - attribute
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetByteAttr		proc	near
	uses	si
locals	local	CellLocals
	.enter	inherit

	mov	si, cs:[bx].SAS_attrOff
	mov	al, {byte}ss:locals.CL_data1
	mov	{byte}ss:locals.CL_cellAttrs[si], al

	.leave
	ret
SetByteAttr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWordAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to set a word attribute

CALLED BY:	CellSetAttrs()
PASS:		cs:bx - ptr to SetAttrStruct
		ss:bp - inherited locals
			CL_data1 - attribute
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWordAttr		proc	near
	uses	si
locals	local	CellLocals
	.enter	inherit

	mov	si, cs:[bx].SAS_attrOff
	mov	ax, ss:locals.CL_data1
	mov	{word}ss:locals.CL_cellAttrs[si], ax

	.leave
	ret
SetWordAttr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDWordAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to set a byte attribute

CALLED BY:	CellSetAttrs()
PASS:		cs:bx - ptr to SetAttrStruct
		ss:bp - inherited locals
			CL_data1, CL_data2 - attribute
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDWordAttr		proc	near
	uses	si
locals	local	CellLocals
	.enter	inherit

	mov	si, cs:[bx].SAS_attrOff
	mov	ax, ss:locals.CL_data1
	mov	{word}ss:locals.CL_cellAttrs[si][0], ax
	mov	ax, ss:locals.CL_data2
	mov	{word}ss:locals.CL_cellAttrs[si][2], ax

	.leave
	ret
SetDWordAttr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeByteAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to change a byte in a CellAttrs entry

CALLED BY:	SetSpreadsheetAttrs() via StyleTokenChangeAttr()
PASS:		ds:di - CellAttrs
		ss:bp - inherited locals
			CL_data1.low - new byte to set
		dx - offset of data in CellAttrs
RETURN:		carry - set to abort
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeByteAttrCallback		proc	far
	uses	di
locals	local	CellLocals
	.enter	inherit

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

EC <	push	es				;>
EC <	segmov	es, ds				;es:di <- ptr to CellAttrs
EC <	call	ECCheckCellAttrRefCount		;>
EC <	pop	es				;>
	add	di, dx				;ds:di <- ptr to data
	mov	al, ss:locals.CL_data1.low
	mov	ds:[di], al			;store new byte
EC <done:					;>
	clc					;carry <- don't abort

	.leave
	ret
ChangeByteAttrCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeWordAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to change a word in a CellAttrs entry

CALLED BY:	SetSpreadsheetAttrs() via StyleTokenChangeAttr()
PASS:		ds:di - CellAttrs
		ss:bp - inherited locals
			CL_data1 - new word to set
		dx - offset of data in CellAttrs
RETURN:		carry - set to abort
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeWordAttrCallback		proc	far
	uses	di
locals	local	CellLocals
	.enter	inherit

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

EC <	push	es				;>
EC <	segmov	es, ds				;es:di <- ptr to CellAttrs
EC <	call	ECCheckCellAttrRefCount		;>
EC <	pop	es				;>
	add	di, dx				;ds:di <- ptr to data
	mov	ax, ss:locals.CL_data1		;ax <- new word
	mov	ds:[di], ax			;store new word
EC <done:					;>
	clc					;carry <- don't abort

	.leave
	ret
ChangeWordAttrCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeDWordAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to change a dword in a CellAttrs entry

CALLED BY:	SetSpreadsheetAttrs() via StyleTokenChangeAttr()
PASS:		ds:di - ptr to CellAttrs
		ss:bp - inherited locals
			CL_data1 - low word
			CL_data2 - high word
		dx - offset in CellAttrs of data
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeDWordAttrCallback		proc	far
	uses	di
locals	local	CellLocals
	.enter	inherit

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

EC <	push	es				;>
EC <	segmov	es, ds				;es:di <- ptr to CellAttrs
EC <	call	ECCheckCellAttrRefCount		;>
EC <	pop	es				;>
	add	di, dx				;ds:di <- ptr to data
	mov	ax, ss:locals.CL_data1
	mov	ds:[di].low, ax			;store new low word
	mov	ax, ss:locals.CL_data2
	mov	ds:[di].high, ax		;store new high word
EC <done:					;>
	clc					;carry <- don't abort

	.leave
	ret
ChangeDWordAttrCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetModifyNumFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	modify number format for selected cells

CALLED BY:	MSG_SPREADSHEET_MODIFY_NUM_FORMAT
PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		ds:bx	= SpreadsheetClass object (same as *ds:si)
		es 	= segment of SpreadsheetClass
		ax	= message #
		cx	= FloatModifyFormatFlags
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetModifyNumFormat	method dynamic SpreadsheetClass, 
					MSG_SPREADSHEET_MODIFY_NUM_FORMAT

locals		local	CellLocals
	.enter

	call	SpreadsheetMarkBusy
	;
	; Do common setup
	;
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset

	mov	ss:locals.CL_data1, ax		;pass data to callback
	mov	ss:locals.CL_data2, cx		;pass FloatModifyFormatFlags
	;
	; IMPORTANT: invalidate the attributes set in the cached GState.
	; This is because while the token may remain the same, the
	; attributes it represents no longer do.
	;
	mov	ds:[si].SSI_curAttrs, -1
	;
	; initialize FormatInfoStruc
	;
	push	es
	mov	ax, size FormatInfoStruc
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc			; ax = segment
	mov	es, ax
	mov	es:[FIS_signature], FORMAT_INFO_STRUC_ID
	mov	ax, ds:[si].SSI_cellParams.CFP_file
	mov	es:[FIS_userDefFmtArrayFileHan], ax
	mov	ax, ds:[si].SSI_formatArray 
	mov	es:[FIS_userDefFmtArrayBlkHan], ax
	call	MemUnlock
	mov	ss:locals.CL_data3, bx		; save handle
	pop	es
	;
	; Check for special cases
	;
	call	CheckAllSelected
	jc	doAllOrColumn			;branch if all selected
	jz	doAllOrColumn			;branch if column(s) selected
	;
	; Call the callback routine for all cells in the selection
	;
	mov	di, mask REF_ALL_CELLS		;di <- all cells
callEnum:
	mov	ss:locals.CL_params.REP_callback.offset,
						offset ModifyCellNumFormat
	mov	ss:locals.CL_params.REP_callback.segment, SEGMENT_CS
	call	CallRangeEnumSelected
	;
	; Update the UI and redraw appropriatly
	;
	mov	ax, mask SNF_FORMAT_CHANGE
	call	UpdateUIRedrawSelection

	call	SpreadsheetMarkNotBusy

	.leave
	ret

	;
	; One or more columns are selected -- optimize if we can
	;
doAllOrColumn:
	;
	; Create token for modified attributes, starting from the default
	; attributes for this column
	;
	call	ModifyColumnNumFormat
	;
	; Set the attributes for any existing cells
	;
	clr	di				;di <- only existing cells
	jmp	callEnum

SpreadsheetModifyNumFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModifyCellNumFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	modify number format for cell

CALLED BY:	INTERNAL
			SpreadsheetModifyNumFormat via CallRangeEnumSelected
PASS:		ss:bp = CallRangeEnumSelected locals
		ds:si = SpreadsheetInstance data
		(ax, cx) = cell coordinates (r, c)
		carry set if cell has data
		*es:di = cell data, if any
		CL_data2 = FloatModifyFormatFlags
		CL_data3 = FIS block
RETURN:		carry set to stop enum
		dl = RangeEnumFlags with REF_ALLOCATED bit set if we've
			allocated a cell
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModifyCellNumFormat	proc	far
	uses	ax, di
locals	local	CellLocals
	.enter	inherit

	push	es, di				; save cell data ptr
	pushf					; save data flag
	push	ax				; save row
	jnc	noData

	mov	di, es:[di]			; es:di = cell data
	mov	ax, es:[di].CC_attrs		; ax = style token
	lea	di, locals.CL_cellAttrs
	segmov	es, ss				; es:di = cell attrs buffers
	call	StyleGetStyleByTokenFar		; get styles
	call	StyleDeleteStyleByToken		; delete one reference
setNumFormat:
	mov	ax, locals.CL_cellAttrs.CA_format	; ax = num format token
	call	ModifyNumFormatFromToken	; ax = new num format token
	mov	locals.CL_cellAttrs.CA_format, ax	; store new token
	pop	ax				; ax = row

	popf					; restore data flag
	pop	es, di				; restore cell data
	call	SetAttrsFinish			; finish up
	clc					; continue enumeration
	.leave
	ret

	;
	; The cell doesn't exist yet -- get the default attrs for it
	;
noData:
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- new style token
	lea	di, locals.CL_cellAttrs
	segmov	es, ss				;es:di <- ptr to cellAttrs
	call	StyleGetStyleByTokenFar
	jmp	setNumFormat

ModifyCellNumFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModifyColumnNumFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	modify default attributes for column

CALLED BY:	INTERNAL
			SpreadsheetModifyNumFormat
PASS:		ds:si = ptr to Spreadsheet instance
		ss:bp = inherited locals
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModifyColumnNumFormat	proc	near
	uses	ax, cx, dx, di, es
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	segmov	es, ss, di
	lea	di, locals.CL_cellAttrs		;es:di <- ptr to CellAttrs
columnLoop:
	;
	; Get the current attrs
	;
	call	ColumnGetDefaultAttrs
	mov	ax, dx				;ax <- attr token for column
	call	StyleGetStyleByTokenFar		;get associated styles
	call	StyleDeleteStyleByToken
	;
	; Modify the number format as desired
	;	es:di = CellAttrs
	;
	mov	ax, es:[di].CA_format		; ax = format token
	call	ModifyNumFormatFromToken	; ax = new format token
	mov	es:[di].CA_format, ax		; store new format token
	;
	; Set the new default attributes
	;
	call	StyleGetTokenByStyleFar		;ax <- new attr token
	call	ColumnSetDefaultAttrs
	;
	; loop while more columns
	;
	inc	cx
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	jbe	columnLoop			;loop while more columns

	.leave
	ret
ModifyColumnNumFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModifyNumFormatFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	modify existing format and return new format token

CALLED BY:	INTERNAL
			ModifyColumnNumFormat
PASS:		ax = format token
		ss:bp = inherited locals
RETURN:		ax = new format token
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModifyNumFormatFromToken	proc	near
	uses	bx, dx, es
locals	local	CellLocals
	.enter	inherit

	push	ax				; save token
	mov	bx, locals.CL_data3		; FIS block
	call	MemLock
	mov	es, ax				; es = FormatInfoStruc
	pop	es:[FIS_curToken]
	mov	dx, locals.CL_data2		; FloatModifyFormatFlags
	call	FloatFormatGetModifiedFormat	; ax = token
	call	MemUnlock
	.leave
	ret
ModifyNumFormatFromToken	endp

AttrCode	ends
