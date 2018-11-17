COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextAttr
FILE:		taRange.asm

ROUTINES:

	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/91		Initial version

DESCRIPTION:

This file contains routines that have to look directly at the text

	$Id: taRange.asm,v 1.1 97/04/07 11:18:42 newdeal Exp $

------------------------------------------------------------------------------@

TextFixed segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TA_GetTextRange

DESCRIPTION:	Given a virtual text range, return the physical range

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextRange
	bx - VisTextRangeContext

RETURN:
	ss:bp - range modified

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

TA_GetTextRange	proc	far	uses ax, dx
	.enter

EC <	call	T_AssertIsVisText					>

	;make sure range is legal

EC <	cmp	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_SELECTION	>
EC <	jz	ok							>
EC <	cmp	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_PARAGRAPH_SELECTION >
EC <	jz	ok							>

EC <	cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax			>
EC <	ERROR_A	VIS_TEXT_RANGE_END_BEFORE_START				>

EC <	cmpdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END		>
EC <	je	ok							>

EC <	pushdw	dxax							>
EC <	call	TS_GetTextSize			; dx.ax <- last pos	>
EC <	cmpdw	ss:[bp].VTR_end, dxax					>
EC <	ERROR_A	VIS_TEXT_ILLEGAL_TEXT_POSITION				>
EC <	popdw	dxax							>

EC <ok:									>

EC <	test	bx, not VisTextRangeContext				>
EC <	ERROR_NZ	ILLEGAL_TEXT_RANGE_CONTEXT			>

	; test for changing selected area

	cmp	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_PARAGRAPH_SELECTION
	jnz	notParaSelection
	ornf	bx, mask VTRC_PARAGRAPH_CHANGE
	jmp	getSelection
notParaSelection:
	cmp	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_SELECTION
	jnz	notSelection
getSelection:
	call	T_FarGetSelectionFrame
notSelection:

	;
	; test for TEXT_ADDRESS_PAST_END passed
	;
	cmp	ss:[bp].VTR_start.high, TEXT_ADDRESS_PAST_END_HIGH
	jnz	10$
	call	TS_GetTextSize
	movdw	ss:[bp].VTR_start, dxax
10$:
	cmp	ss:[bp].VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH
	jnz	20$
	call	TS_GetTextSize
	movdw	ss:[bp].VTR_end, dxax
20$:

	;
	; do any special adjustments that are necessary
	;

	; in a paragraph context we want to extend VTR_start back to the
	; start of the paragraph and VTR_end to the end of the paragraph
	; (including the CR at the end).

	; in a border context (used only to figure the extent to recalculate)
	; we want to include the first character of the next line to force
	; it to be recalculated

	test	bx, mask VTRC_PARAGRAPH_CHANGE
	LONG jz	noPPAdjust

	movdw	dxax, ss:[bp].VTR_start
	stc					;return position passed
						;if it is a para start
	call	TSL_FindParagraphStart
	movdw	ss:[bp].VTR_start, dxax

	movdw	dxax, ss:[bp].VTR_end
	tstdw	dxax
	jz	30$
	cmpdw	dxax, ss:[bp].VTR_start
	jz	30$
	decdw	dxax
30$:
	call	TSL_FindParagraphEnd
	jc	noParaAttrBorderAdjust
	incdw	dxax				;point past CR
	test	bx, mask VTRC_PARA_ATTR_BORDER_CHANGE
	jz	noParaAttrBorderAdjust
	incdw	dxax				;cause next line to be recalc'ed
noParaAttrBorderAdjust:
	movdw	ss:[bp].VTR_end, dxax
EC <	cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax			>
EC <	jnz	paraRangeOK						>
EC <	tstdw	ss:[bp].VTR_start					>
EC <	jz	paraRangeOK						>
EC <	call	TS_GetTextSize						>
EC <	cmpdw	dxax, ss:[bp].VTR_start					>
EC <	ERROR_NZ VIS_TEXT_ILLEGAL_TEXT_POSITION				>
EC <paraRangeOK:							>
noPPAdjust:

	test	bx, mask VTRC_CHAR_ATTR_CHANGE
	jz	noCharAttrAdjust

	; in a character context we want to include the next CR if we
	; are at the end of a paragraph but we do the want to include the
	; previous CR if we are at the start of a paragraph.

	movdw	dxax, ss:[bp].VTR_end
	cmpdw	dxax, ss:[bp].VTR_start
	jz	noCharAttrAdjust
	call	TSL_IsParagraphEnd
	jz	noCharAttrAdjust		;if eof then no adjust
	jnc	noCharAttrAdjust		;if not end of para then none
	tstdw	dxax
	jz	doCharAttrAdjust
	decdw	dxax
	call	TSL_IsParagraphEnd
	jc	noCharAttrAdjust
doCharAttrAdjust:
	incdw	ss:[bp].VTR_end
noCharAttrAdjust:

	.leave
	ret

TA_GetTextRange	endp

TextFixed ends

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextGetRange -- MSG_VIS_TEXT_GET_RANGE for VisTextClass

DESCRIPTION:	Map a virtual range to a physical range

PASS:
	*ds:si - instance data (VisTextInstance)
	cx - VisTextRangeContext
	dx:bp - VisTextRange

RETURN:
	range filled in

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
VisTextGetRange		proc	far	; MSG_VIS_TEXT_GET_RANGE
	class	VisTextClass

	mov	bx, cx				;bx = context

	movdw	esdi, dxbp
	pushdw	es:[di].VTR_end
	pushdw	es:[di].VTR_start
	mov	bp, sp

	call	TA_GetTextRange

	popdw	es:[di].VTR_start
	popdw	es:[di].VTR_end

	ret

VisTextGetRange	endp

TextAttributes ends
