COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		utilsTextObject.asm

AUTHOR:		John Wedgwood, Oct 22, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/22/91	Initial revision
	witt	11/12/93	DBCS-ized some comments.

DESCRIPTION:
	Text object related utilities.

	$Id: utilsText.asm,v 1.1 97/04/04 17:47:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetGrObjTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the bounds needed for this grobj so that all
		its text will fit on a single line.

CALLED BY:	SetTextCustomBounds

PASS:		^lcx:dx - text guardian
		ds - fixupable object block

RETURN:		(cx, dx) - text object bounds

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetGrObjTextBounds	proc far
	uses	ax,bx,si,di,bp
	.enter
	movdw	bxsi, cxdx
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ^lcx:dx - text object

	;
	; First, see how wide it wants to be to fit all its text on
	; one line.
	;

	movdw	bxsi, cxdx
	clr	cx
	mov	ax, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx - width
	push	cx

	;
	; see how tall it wants to be.
	;

	mov	ax, MSG_VIS_TEXT_GET_LINE_HEIGHT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	dx, ax
	pop	cx			; cx, dx - width, height


	;
	; HACK! Figure out from steve what I should really do here...
	;

	add	cx, 4
	add	dx, 4

	;
	; Constrain the bounds
	;

	call	UtilConstrainTextBounds

	.leave
	ret
UtilGetGrObjTextBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilConstrainTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the text object no larger than 1/3 of the entire
		chart's width/height

CALLED BY:	UtilGetGrObjTextBounds, PieGetMaxTextSizexo

PASS:		cx, dx - current bounds
		ds - segment of chart objects
	
RETURN:		cx, dx - new bounds

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilConstrainTextBounds	proc far
		uses	ax,bx,bp
		.enter

		push	cx, dx
		mov	ax, MSG_CHART_OBJECT_GET_SIZE
		call	UtilCallChartGroup

		mov	bx, dx			; bx <- chart height
		clr	dx
		mov_tr	ax, cx			; dx:ax <- chart width
		mov	cx, 3
		div	cx			; ax <- chart width / 3

		xchg	ax, bx			; bx <- chart width / 3
		clr	dx			; dx:ax <- chart height
		div	cx			; ax <- chart height / 3
		pop	cx, dx

		Min	cx, bx
		Min	dx, ax

		.leave
		ret
UtilConstrainTextBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the size of the passed text using any
		associated text object

CALLED BY:	UTILITY

PASS:		*ds:si - chart object
		es:di - text

RETURN:		cx, dx - width/height of text

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetTextSize	proc far

		uses	ax,bx,si,bp,di

		.enter

		call	UtilCreateGStateForTextCalculations ; ^hbp - gstate

		push	ds			; chart block
		segmov	ds, es
		mov	si, di
		clr	cx
		mov	di, bp
		call	GrTextWidth
		mov	cx, dx

		mov	si, GFMI_MAX_ADJUSTED_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics		; dx - height
		pop	ds			; chart block

		call	GrDestroyState

		call	UtilConstrainTextBounds

		.leave
		ret
UtilGetTextSize	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilFloatToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a floating-point number to text

CALLED BY:

PASS:		FP stack: number to convert
		ss:bp - pointer to text buffer of length (char/wchar count)
			MAX_CHART_TEXT_LENGTH

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilFloatToAscii	proc	far
	uses	ax,bx,cx,dx,es,di
	.enter
	mov	ax, mask FFAF_USE_COMMAS or mask FFAF_NO_TRAIL_ZEROS
	mov	bx, (MAX_DIGITS shl 8) or DECIMAL_DIGITS

	call	UtilGetChartAttributes
	test	dx, mask CF_PERCENT
	jz	gotFlags
	ornf	ax, mask FFAF_PERCENT
	clr	bl		; no decimal digits for percent.
gotFlags:
	segmov	es, ss
	mov	di, bp
	call	FloatFloatToAscii_StdFormat	; Do the conversion
	.leave
	ret
UtilFloatToAscii	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCreateGStateForTextCalculations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate, and set the attributes of the text
		object associated with this chart object to the
		gstate, so that text calculations will yield valid
		results.  The text is assumed to be single-attr

CALLED BY:	Utility

PASS:		*ds:si - chart object

RETURN:		^hbp - gstate

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextAttrStruct	struct
	GTAS_getAttrParams	VisTextGetAttrParams
	GTAS_attr		VisTextCharAttr
GetTextAttrStruct	ends

UtilCreateGStateForTextCalculations	proc far

	uses	ax,bx,cx,dx,di,si

	.enter


EC <	call	ECCheckChartObjectDSSI		>


	sub	sp, size GetTextAttrStruct
	mov	bp, sp

	clrdw	ss:[bp].GTAS_getAttrParams.VTGAP_range.VTR_start
	movdw	ss:[bp].GTAS_getAttrParams.VTGAP_range.VTR_end, \
						TEXT_ADDRESS_PAST_END
	mov	ss:[bp].GTAS_getAttrParams.VTGAP_attr.segment, ss
	mov	ss:[bp].GTAS_getAttrParams.VTGAP_return.segment, ss
	lea	ax, ss:[bp][GTAS_attr]
	mov	ss:[bp].GTAS_getAttrParams.VTGAP_attr.offset, ax
	mov	ss:[bp].GTAS_getAttrParams.VTGAP_return.offset, ax
	clr	ss:[bp].GTAS_getAttrParams.VTGAP_flags

	mov	ax, MSG_CHART_OBJECT_GET_GROBJ_TEXT
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx

	mov	dx, size VisTextGetAttrParams
	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage


	clr	di
	call	GrCreateState

	;
	; Set the font and point size
	;

	mov	cx, ss:[bp].GTAS_attr.VTCA_fontID
	movwbf	dxah, ss:[bp].GTAS_attr.VTCA_pointSize
	call	GrSetFont

	mov	al, ss:[bp].GTAS_attr.VTCA_textStyles
	clr	ah
	call	GrSetTextStyle

	mov	al, ss:[bp].GTAS_attr.VTCA_fontWeight
	call	GrSetFontWeight

	mov	al, ss:[bp].GTAS_attr.VTCA_fontWidth
	call	GrSetFontWidth

	add	sp, size GetTextAttrStruct

	mov	bp, di			; gstate handle

	.leave
	ret
UtilCreateGStateForTextCalculations	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetTextLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the text height of the grobj text, using
		MSG_CHART_OBJECT_GET_GROBJ_TEXT 

CALLED BY:	UTILITY

PASS:		*ds:si - axis

RETURN:		ax - text height

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetTextLineHeight	proc far
	uses	bx,cx,dx,si,di,bp

	.enter
	mov	ax, MSG_CHART_OBJECT_GET_GROBJ_TEXT
	call	ObjCallInstanceNoLock

	movOD	bxsi, cxdx
	mov	ax, MSG_VIS_TEXT_GET_LINE_HEIGHT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
UtilGetTextLineHeight	endp

ChartCompCode	ends
