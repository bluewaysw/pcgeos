COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonCalc.asm

AUTHOR:		John Wedgwood, Jan  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 8/92	Initial revision

DESCRIPTION:
	Common calculation code.

	$Id: tlCommonCalc.asm,v 1.1 97/04/07 11:21:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextLineCalc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a line.

CALLED BY:	SmallLineCalculate, LargeLineCalculate
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars set
		es:di	= Pointer to the line
		cx	= Size of current line/field data
		ax	= LineFlags for current line
RETURN:		LICL_range.VTR_start = start of next line
		LICL_calcFlags updated
		Line marked as needing redraw if it changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineCalculate	proc	far
	uses	bx, cx, dx
	.enter
	;
	; Allocate the stack frame for the kernel.
	;
	sub	sp, size TOC_vars		; Make space on the stack
	mov	bx, sp				; ss:bx = kernel stack frame
	
	;
	; Mark that the field does not contain any extended styles (so far)
	;
	mov	ss:[bp].LICL_extStylePos, -1

	;
	; Save new line flags
	;
	mov	ss:[bx].TOCV_ext.TOCE_lineFlags, ax

	;
	; Get started
	;
	andnf	ss:[bp].LICL_calcFlags, not mask CF_LINE_CHANGED

	mov	ss:[bx].TOCV_ext.TOCE_otherFlags, mask TOCOF_IS_FIRST_FIELD
	;
	; set TOCOF_WRAP_AFTER_OVERFLOW if HINT_VIS_TEXT_WRAP_AFTER_OVERFLOW
	;
	push	ax
	push	bx
	mov	ax, ATTR_VIS_TEXT_WRAP_AFTER_OVERFLOW
	call	ObjVarFindData
	mov	ax, bx
	pop	bx
	jnc	noOverflow
	push	si
	mov	si, ax
	VarDataSizePtr	ds, si, ax		; if no width, store 0 as width
	tst	ax
	jz	haveWidth
	mov	ax, ds:[si]			; get specified width
haveWidth:
	pop	si
	ornf	ss:[bx].TOCV_ext.TOCE_otherFlags, mask TOCOF_WRAP_AFTER_OVERFLOW
	mov	ss:[bx].TOCV_ext.TOCE_wrapAfterOverflowWidth, ax
noOverflow:
	pop	ax
	clrwbf	ss:[bx].TOCV_ext.TOCE_lineHeight
	clrwbf	ss:[bx].TOCV_ext.TOCE_lineBLO

	movdw	ss:[bp].LICL_lineStart, ss:[bp].LICL_range.VTR_start, ax
	movwbf	ss:[bp].LICL_oldLineHeight, es:[di].LI_hgt, ax
	add	cx, di				; cx <- ptr past field data
	lea	dx, es:[di].LI_firstField	; es:dx <- first field
	
;-----------------------------------------------------------------------------
fieldLoop:
	;
	; *ds:si= Instance ptr
	; ss:bp	= LICL_vars
	; ss:bx	= TOC_vars
	; es:di	= Pointer to the line
	; cx	= Pointer past the line/field data
	; es:dx	= Pointer to the current field
	;
	; We need to save the instance pointer each time through because adding
	; fields may cause the object block to move on the heap.
	; 
	movdw	ss:[bp].LICL_object, dssi	; Save instance ptr
	mov	ss:[bp].LICL_tabReference, RULER_TAB_TO_LINE_LEFT

	call	FindFieldEnd			; Calculate this one field
	LONG jnc removeField			; Branch if no field

	call	CalcFieldPosition		; Set FI_position
	call	SaveNewFieldValues		; Set the rest of it

	;
	; Set the start of the next field.
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_nChars
	add	ss:[bp].LICL_range.VTR_start.low, ax
	adc	ss:[bp].LICL_range.VTR_start.high, 0

	;
	; Check for more fields after the current one.
	;
	test	ss:[bx].TOCV_ext.TOCE_flags, mask TOCF_LINE_TERMINATED
	jnz	endLoop				; Branch if line terminated
	
	;
	; Make space for the next field
	;
	add	dx, size FieldInfo		; es:dx <- ptr to next field
	call	AddFieldToLine			; Make a new field

	and	ss:[bx].TOCV_ext.TOCE_otherFlags, not mask TOCOF_IS_FIRST_FIELD
	jmp	fieldLoop			; Loop to compute it
	
;-----------------------------------------------------------------------------
endLoop:
	;
	; *ds:si= Instance ptr
	; ss:bp	= LICL_vars
	; ss:bx	= TOC_vars
	; es:di	= Line
	; es:dx	= Pointer to the last field we want to keep
	; cx	= Size of current line/field data
	;
	call	TruncateLineAtPosition		; Truncate the line/field data

	;
	; Adjust the line height and baseline offset for stuff like 
	; extra leading, line spacing, borders, etc...
	;
	; We need to copy the line-flags so that the border code will know
	; what borders are appropriate.
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_lineFlags
	mov	ss:[bp].LICL_lineFlags, ax
	call	AdjustLineHeight

	;
	; All the previous calculations have been done assuming that the line
	; is left justified. This routine will adjust the field positions
	; (and possibly the width of the last field) to account for left, center,
	; right, or full justification.
	;
	call	HandleJustification
	
	;
	; Copy the old line-flags into the stack frame so our caller knows
	; what changed.
	;
	mov	ax, es:[di].LI_flags
	mov	ss:[bp].LICL_oldLineFlags, ax

	;
	; Check to see if we need to draw the line.
	;
	call	CheckForceDraw
	
	;
	; If the line is the first one in the region, then it can never
	; interact with the line above it.
	;
	cmpdw	ss:[bp].LICL_line, ss:[bp].LICL_regionTopLine, ax
	jne	flagsOK
	and	ss:[bx].TOCV_ext.TOCE_lineFlags, not (mask LF_INTERACTS_ABOVE)
flagsOK:

	;
	; Save the new LineInfo values.
	;
	call	SaveNewLineValues

	;
	; Copy the final line-flags into the LICL_vars so that our caller
	; knows what went on.
	;
	mov	ax, es:[di].LI_flags
	mov	ss:[bp].LICL_lineFlags, ax
	
	;
	; Save the line-height.
	;
	movwbf	dxah, ss:[bx].TOCV_ext.TOCE_lineHeight
	movwbf	ss:[bp].LICL_lineHeight, dxah

	;
	; Adjust the line-end to include any adjustment due to justification.
	;
	mov	ax, es:[di].LI_adjustment
	add	ss:[bp].LICL_lineEnd, ax

	mov	ax, ss:[bp].LICL_lineJustEnd
	add	ax, es:[di].LI_adjustment
	call	SaveNewLineEnd

	add	sp, size TOC_vars		; Restore stack
	
	;
	; Save the new character count
	;
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	subdw	dxax, ss:[bp].LICL_lineStart	; dx.ax <- # of characters
	call	SaveNewLineCharCount		; Save new count
	
	;
	; Check for a dirty line and call the callback if we find one.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED or \
					mask CF_FORCE_CHANGED
	jz	noChange
	or	es:[di].LI_flags, mask LF_NEEDS_DRAW

if ERROR_CHECK
	;
	;  If not vfptr check if the segment passed is same as current
	;  code segment.  Since it is allowed to pass a fptr to the 
	;  callback if you are calling from the same segment.
	;
FXIP<	push	ax, bx							>
FXIP<	mov	ax, ss:[bp].LICL_dirtyLineCallback.segment		>
FXIP<	cmp	ah, 0xf0						>
FXIP<	jae	isVirtual						>
FXIP<	mov	bx, cs
FXIP<	cmp	ax, bx							>
FXIP<	ERROR_NE  TEXT_FAR_POINTER_TO_MOVABLE_XIP_RESORCE		>
FXIP<isVirtual:								>
FXIP<	pop	ax, bx							>
endif

NOFXIP<	call	ss:[bp].LICL_dirtyLineCallback				>
FXIP<	push	ax, bx							>
FXIP<	movdw	bxax, ss:[bp].LICL_dirtyLineCallback			>
FXIP<	call	ProcCallFixedOrMovable					>
FXIP<	pop	ax, bx

noChange:
	.leave
	ret

removeField:
	;
	; We attempted to calculate a field but it turned out that the
	; field we wanted to compute wouldn't fit on this line. This can't
	; happen for the first field on the line. We want to truncate
	; the line/field data at the current field.
	;
	; Since we do the same thing when we are done with the loop in order
	; to remove extra fields we can just shuffle the "current field" pointer
	; backwards one field and then let the 'endLoop' code fix everything.
	;
	sub	dx, size FieldInfo		; es:dx <- last field to keep
	jmp	endLoop				; Go to remove extras
CommonLineCalculate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForceDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to force a line to be drawn.

CALLED BY:	CommonLineCalculate
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		es:di	= Line
		ss:bx	= TOC_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Cases to check for:
	      1 - Line is being "forced" to be changed
	      2 - Changed range intersects start/end of line

	It's #2 that's the problem. The cases are these:
		1) ls <  cs <  le	(change is after line start)
			     +---change---->
			+---line---+
		2) ls <  ce <  le	(change is before line end)
			<---change----+
				+---line---+
		3) cs <  ls <  ce	(change crosses line start)
			+---change----+
				+---line--->
		4) cs <  le <  ce	(change crosses line end)
			    +---change----+
			<---line---+
		5) cs <= ls && ce >= le	(change contains line)
			+---change----+
			  +---line---+
		6) ls <= cs && le >= ce	(line contains change)
			 +-change-+
			+---line---+

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForceDraw	proc	near
	uses	ax, cx, dx, di
	.enter
	;
	; Load up the start and end.
	;
	movdw	dxax, ss:[bp].LICL_startPos
	movdw	cxdi, ss:[bp].LICL_range.VTR_end

	;
	; Check the cases of mystery...
	;
	cmpdw	ss:[bp].LICL_lineStart, dxax
	jb	checkCase1

checkCasesAfter1:
	cmpdw	ss:[bp].LICL_lineStart, cxdi
	jb	checkCase2

checkCasesAfter2:
	cmpdw	dxax, ss:[bp].LICL_lineStart
	jb	checkCase3

checkCasesAfter3:
	cmpdw	dxax, ss:[bp].LICL_range.VTR_start
	jb	checkCase4

checkCasesAfter4:
	cmpdw	dxax, ss:[bp].LICL_lineStart
	jbe	checkCase5

checkCasesAfter5:
	cmpdw	ss:[bp].LICL_lineStart, dxax
	jbe	checkCase6

quit:
	.leave
	ret


checkCase1:
	cmpdw	dxax, ss:[bp].LICL_range.VTR_start
	jbe	forceDraw
	jmp	checkCasesAfter1


checkCase2:
	cmpdw	cxdi, ss:[bp].LICL_range.VTR_start
	jbe	forceDraw
	jmp	checkCasesAfter2


checkCase3:
	cmpdw	ss:[bp].LICL_lineStart, cxdi
	jbe	forceDraw
	jmp	checkCasesAfter3


checkCase4:
	cmpdw	ss:[bp].LICL_range.VTR_start, cxdi
	jbe	forceDraw
	jmp	checkCasesAfter4

checkCase5:
	cmpdw	cxdi, ss:[bp].LICL_range.VTR_start
	jae	forceDraw
	jmp	checkCasesAfter5

checkCase6:
	cmpdw	ss:[bp].LICL_range.VTR_start, cxdi
	jae	forceDraw
	jmp	quit


forceDraw:
	or	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_NEEDS_DRAW
	jmp	quit
CheckForceDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFieldEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the end of a field.

CALLED BY:	CommonLineCalculate
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		es:dx	= Field
		cx	= Pointer past line/field data
RETURN:		carry clear if there are no more fields
DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 1/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFieldEnd	proc	near
	class	VisTextClass
	uses	ax, cx, di
	.enter
	;
	; We need to pass some flags to the kernel calculation code. These
	; flags are stored in our instance data.
	;
	push	di				; Save line ptr
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	call	SetKernelCalculationFlags	; Set TOCV_ext.TOCE_flags
	mov	cx, ds:[di].VTI_gstate		; cx <- gstate to use.
	pop	di				; Restore line ptr

	;
	; Set the callback routines.
	;
	movcb	ss:[bx].TOCV_int.TOCI_style.TMS_styleCallBack, \
				CalculateCharAttrCallback

	movcb	ss:[bx].TOCV_int.TOCI_style.TMS_graphicCallBack, \
				CalculateGraphicCallback

	movcb	ss:[bx].TOCV_ext.TOCE_hyphenCallback, CalculateHyphenCallback
	movcb	ss:[bx].TOCV_ext.TOCE_tabCallback,    CalculateTabCallback
	movcb	ss:[bx].TOCV_ext.TOCE_heightCallback, CalculateHeightCallback

	mov	ss:[bx].TOCV_ext.TOCE_passBack, bp

	;
	; The maximum area that the field can fit in is the distance from the
	; end of the previous field to the right margin.
	;
	call	ComputeAreaToFill

	;
	; Set up some other stuff -- if this is the first field then pass
	; 0 for the height and baseline offset
	;
	clr	ss:[bx].TOCV_ext.TOCE_anchorChar

	movdw	ss:[bp].LICL_linePtr, esdi	; Pass the pointer to the line
	mov	ss:[bp].LICL_fieldPtr, dx	; Pass the pointer to the field
	
	;
	; Mark that we haven't locked any text yet.
	;
	and	ss:[bp].LICL_calcFlags, not mask CF_TEXT_LOCKED

	;
	; Do the calculation.
	;
	push	bp, di, ds			; Save frame, line, instance
	mov	di, cx				; di <- gstate to use
	mov	bp, bx				; Pass this structure pointer
	call	GrTextObjCalc			; Do the work
	mov	ax, ds				; ax <- segment of last text
	pop	bp, di, ds			; Restore frame, line, instance

	;
	; ax	= Segment of last lump of text
	;
	test	ss:[bp].LICL_calcFlags, mask CF_TEXT_LOCKED
	jz	skipUnlock			; Branch if nothing locked
	call	TS_UnlockTextPtr		; Release the text
skipUnlock:

	;
	; Check to see if the field contains an extended style.
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_nChars
	cmp	ax, ss:[bp].LICL_extStylePos
	jbe	noExtStyle
	
	;
	; The field contains an extended style, mark the line
	;
	or	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_CONTAINS_EXTENDED_STYLE

noExtStyle:
	;
	; Check for field with only a NULL in it. In this case we want
	; to mark that a field does exists (it's just real small).
	;
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_ENDS_IN_NULL
	jz	notNull
	stc					; Mark this is a field
	jmp	quit
notNull:

	;
	; Check for nothing fit.
	;
	clr	ax				; This will set carry correctly
	sub	ax,  ss:[bx].TOCV_ext.TOCE_nChars ;    clear if nChars == 0.

quit:
	.leave
	ret
FindFieldEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetKernelCalculationFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the TOCV_ext.TOCE_flags field in the stack frame based
		on the text objects features flags.

CALLED BY:	FindFieldEnd
PASS:		ds:di	= Instance ptr
		ss:bx	= TOC_vars
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetKernelCalculationFlags	proc	near
	class	VisTextClass
	uses	ax
	.enter
	clr	al

	;
	; Set the flag which tells GrTextObjCalc() whether or not to word
	; wrap text.
	;
	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_DISABLE_WORD_WRAP
	jnz	setNoWordWrap

	test	ds:[di].VTI_features, mask VTF_NO_WORD_WRAPPING
	jz	gotWordWrapFlag

setNoWordWrap:
	or	al, mask TOCF_NO_WORD_WRAP

gotWordWrapFlag:
	;
	; Set the flag which tells GrTextObjCalc() whether or not to attempt
	; hyphenation.
	;
	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_ALLOW_AUTO_HYPHENATION
	jnz	setAutoHyphenate

	test	ds:[di].VTI_features, mask VTF_AUTO_HYPHENATE
	jz	gotHyphenFlag

setAutoHyphenate:
	or	al, mask TOCF_AUTO_HYPHENATE

gotHyphenFlag:
	mov	ss:[bx].TOCV_ext.TOCE_flags, al
	.leave
	ret
SetKernelCalculationFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeAreaToFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the TOCE_areaToFill field.

CALLED BY:	FindFieldEnd
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		es:dx	= Current field
RETURN:		ss:bx.TOCE_areaToFill set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (first field) {
	    if (line.flags & LF_STARTS_PARAGRAPH) {
	        leftEdge = ruler.paraMargin
	    } else {
	        leftEdge = ruler.leftMargin
	    }
	} else {
	    prev = field - size FieldInfo
	    leftEdge = prev.FI_position + prev.FI_width
	}
	area = realRightMargin - leftEdge
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeAreaToFill	proc	near
	uses	ax, dx
	.enter
	call	ComputeEndPrevField		; ax <- end of prev field
	mov	dx, LICL_realRightMargin	; dx <- right edge
	sub	dx, ax				; dx <- width
	mov	ss:[bx].TOCV_ext.TOCE_areaToFill, dx
	.leave
	ret
ComputeAreaToFill	endp

TextLineCalc		ends
TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeEndPrevField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the end of the previous field.

CALLED BY:	ComputeAreaToFill, others
PASS:		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		es:dx	= Field
RETURN:		ax	= End of previous field or else appropriate margin
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeEndPrevField	proc	far
	uses	cx, dx, di
	.enter
	clr	cx				; Assume first field

	lea	ax, es:[di].LI_firstField	; ax <- offset to first field
	cmp	ax, dx				; Check for on first field
	je	addMargin			; Branch if on first field

	;
	; We aren't on the first field.
	;
	sub	dx, size FieldInfo		; es:dx <- previous field
	mov	di, dx				; es:di <- previous field
	mov	cx, es:[di].FI_position		; ax <- end of previous field
	add	cx, es:[di].FI_width

addMargin:
	;
	; cx	= End of previous field, not counting margin
	;
	; It's the first field on the line. For paragraph starts we use the
	; paraMargin. Otherwise we use the left margin.
	;
	mov	ax, LICL_paraAttr.VTPA_leftMargin

	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_STARTS_PARAGRAPH
	jz	quit			; Branch if not para-start
	
	;
	; It's the start of the paragraph. Use the paragraph margin.
	;
	mov	ax, LICL_paraAttr.VTPA_paraMargin

quit:
	;
	; cx	= End of previous field, not counting margin
	; ax	= Margin to add
	;
	add	ax, cx				; ax <- end of prev field
	.leave
	ret
ComputeEndPrevField	endp

TextFixed	ends
TextLineCalc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineLeftFromTOCV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the left edge of the line

CALLED BY:	ComputeEndPrevField
PASS:		ss:bp	= LICL_vars with ruler set
		ss:bx	= TOC_vars
RETURN:		ax	= Left edge of the line (para-margin or left-margin)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineLeftFromTOCV	proc	near
	;
	; Assume not para-start
	;
	mov	ax, LICL_paraAttr.VTPA_leftMargin

	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_STARTS_PARAGRAPH
	jz	quit			; Branch if not para-start
	
	;
	; It's the start of the paragraph. Use the paragraph margin.
	;
	mov	ax, LICL_paraAttr.VTPA_paraMargin
quit:
	ret
GetLineLeftFromTOCV	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFieldPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the position of a field.

CALLED BY:	CommonLineCalculate
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_locals
		ss:bx	= TOC_vars
		es:di	= Line
		es:dx	= Current field
RETURN:		es:[dx].FI_position set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 1/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcFieldPosition	proc	near
	uses	ax, cx, di
	.enter
	;
	; We will call a handler routine that depends on the tab-type.
	; We need to get the tab type from the ruler.
	;
	call	GetLineLeftFromTOCV		; ax <- left edge of line
	push	ax				; Save left edge of line

	push	bx
	mov	al, ss:[bp].LICL_tabReference	; al <- TabReference
	call	TabGetPositionAndAttributes	; cx <- position of tab
						; al <- TabAttributes
						; bx <- tab spacing
	pop	bx

	ExtractField	byte, al, TA_TYPE, al	; al <- Tab type
	mov	ss:[bp].LICL_lastFieldTabType, al
	clr	ah				; ax <- tab type
	shl	ax, 1				; ax <- index into table
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Replaced the commented out code, 3/29/93 -jw
; This was necessary because the routines I am calling expect to have
; es:di pointing at the line structure. None of them expect anything in ax.
;
;	mov	di, ax				; di <- index
;
;	call	cs:fieldPositionHandlers[di]	; ax <- position of field
;
	push	di				; Save line pointer
	mov	di, ax				; di <- index
	mov	ax, cs:fieldPositionHandlers[di]; ax <- routine to call
	pop	di				; Restore line pointer
	
	call	ax				; Call the handler
						; ax <- position of the field
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	pop	cx				; cx <- left edge of line
	sub	ax, cx				; ax <- relative to line-left

	call	SaveNewFieldPosition		; Save the final field position
	
	;
	; Figure the end of the line (if justified)
	;
	mov	cx, ss:[bx].TOCV_ext.TOCE_justWidth
	add	cx, ax				; Add field-start
	mov	ss:[bp].LICL_lineJustEnd, cx

	;
	; Save the end of the line. This value depends on a few things...
	;	- <cr> terminated line ==> justWidth
	;	- Everything else      ==> fieldWidth
	;
	; Assume line was terminated.
	;
	mov	cx, ss:[bx].TOCV_ext.TOCE_justWidth
	mov	ss:[bp].LICL_lastFieldJustWidth, cx

	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_ENDS_IN_CR or \
						 mask LF_ENDS_IN_AUTO_HYPHEN
	jnz	setEnd
	
	;
	; Line wasn't terminated. Use field width.
	;
	rndwbf	ss:[bx].TOCV_ext.TOCE_fieldWidth, cx

setEnd:
	add	ax, cx				; Add field-start
	mov	ss:[bp].LICL_lineEnd, ax	; Save line end
	.leave
	ret
CalcFieldPosition	endp

fieldPositionHandlers	label	word
	word	offset cs:LeftJustifyField	; TT_LEFT
	word	offset cs:CenterJustifyField	; TT_CENTER
	word	offset cs:RightJustifyField	; TT_RIGHT
	word	offset cs:AnchorJustifyField	; TT_ANCHORED



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LeftJustifyField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Left justify a field.

CALLED BY:	CalcFieldPosition
PASS:		*ds:si	= Instance ptr
		ss:bx	= TOC_vars
		ss:bp	= LICL_vars
		es:di	= Line
		es:dx	= Field
		cx	= Position of the tab
RETURN:		ax	= Position for field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LeftJustifyField	proc	near
	;
	; For left justified fields the left edge of the field goes at
	; the position of the tab.
	;
	mov	ax, cx
	ret
LeftJustifyField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterJustifyField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Center justify a field.

CALLED BY:	CalcFieldPosition
PASS:		*ds:si	= Instance ptr
		ss:bx	= TOC_vars
		ss:bp	= LICL_vars
		es:di	= Line
		es:dx	= Field
		cx	= Position of the tab
RETURN:		ax	= Position for field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CenterJustifyField	proc	near
	uses	cx, dx, di
	.enter
	;
	; Set up:
	;	ax = Position where field would go if left justified
	;	dx = 1/2 width of the field to consider when justifying
	;
	call	ComputeEndPrevField		; ax <- end of previous fied
	mov	di, cx				; Save position of tab in di

	mov	dx, cx				; dx <- position of tab
	mov	cx, ax				; Save previous field end in cx

	sub	dx, ax				; dx <- Space left of tab
	mov	ax, dx				; ax <- Space left of tab

	mov	dx, ss:[bx].TOCV_ext.TOCE_justWidth
	shr	dx, 1

	;
	; The logic here is a bit complex...
	;
	; If the field cannot be centered because it would collide with the
	; right margin, then we want to "right justify" it at the margin.
	;
	; If the field cannot be centered because it would collide with the
	; end of the previous field, then we want to left justify it at the
	; end of the previous field.
	;
	; First we check for a collision with the end of the previous field.
	; If there is one, we left justify at that point.
	; Then we check the case of collision with the right margin.
	;
	cmp	ax, dx				; Check for not enough
	jb	setToPrevFieldEnd		; Left justify if no space

	;
	; There is enough space to our left to allow us to center justify the
	; field. We need to make sure there is also enough space to our right.
	;
	mov	ax, LICL_realRightMargin	; ax <- Space right of tab
	sub	ax, di

	cmp	ax, dx				; Check for not enough
	jbe	rightJustify			; Right justify if no space

	;
	; The field can be centered inside both boundaries without any problem
	;
	mov	ax, di
	sub	ax, dx

quit:
	;
	; ax = Position for the field
	;
	.leave
	ret

setToPrevFieldEnd:
	;
	; Field is too wide to center. There is not enough space on the left
	; side. We butt the field up against the previous field in order to
	; make it fit.
	; cx	= End of previous field
	;
	mov	ax, cx
	jmp	quit

rightJustify:
	;
	; Field collides with right margin, align it at the right margin.
	;
	mov	ax, LICL_realRightMargin
	sub	ax, ss:[bx].TOCV_ext.TOCE_justWidth
	jmp	quit
CenterJustifyField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RightJustifyField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Right justify a field.

CALLED BY:	CalcFieldPosition
PASS:		*ds:si	= Instance ptr
		ss:bx	= TOC_vars
		ss:bp	= LICL_vars
		es:di	= Line
		es:dx	= Field
		cx	= Position of the tab
RETURN:		ax	= Position for field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RightJustifyField	proc	near
	uses	dx
	.enter
	call	ComputeEndPrevField		; ax <- end of previous field
	mov	dx, ax				; dx <- end of previous field

	mov	ax, cx				; cx <- tab position
	sub	ax, dx				; ax <- space left of field

	;
	; Check to see if the entire field will fit in the space between the
	; end of the previous field and the position of the tabstop.
	;
	; If it will, then we can right justify the field, if not, then we
	; position the field at the end of the previous field, and the
	; tab character occupies no space.
	;
	cmp	ss:[bx].TOCV_ext.TOCE_justWidth, ax
	ja	setToPrevFieldEnd

	;
	; It fits, the position is at tabStop.position - justWidth.
	; ax = tabStop.position
	;
	mov	ax, cx				; ax <- tab position
	sub	ax, ss:[bx].TOCV_ext.TOCE_justWidth	; ax <- new position

quit:
	;
	; ax	= Position for the field
	;
	.leave
	ret

setToPrevFieldEnd:
	;
	; The field is too wide to right justify on the tabstop. We need
	; to make it butt up against the previous field.
	;
	mov	ax, dx
	jmp	quit
RightJustifyField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AnchorJustifyField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Anchor a field to a position.

CALLED BY:	CalcFieldPosition
PASS:		*ds:si	= Instance ptr
		ss:bx	= TOC_vars
		ss:bp	= LICL_vars
		es:di	= Line
		es:dx	= Field
		cx	= Position of the tab
RETURN:		ax	= Position for field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The calculation code has found and stored the offset into the field
	at which the anchor character was found.

	If the field cannot be anchored because it would collide with the
	right margin, then we want to "right justify" it at the margin.

	If the field cannot be anchored because it would collide with the
	end of the previous field, then we want to left justify it at the
	end of the previous field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AnchorJustifyField	proc	near
	uses	cx, dx, di
	.enter
;	mov	di, cx				; Save tab position in di
	push	cx				; Save tab pos without nuking
						;  line info, which is 
						;  passed to ComputeEndPrev-
						;  Field(cbh 4/18/94)
	;
	; Compute:
	; ax	= Space to the left of the tabstop
	;
	call	ComputeEndPrevField		; ax <- end of prev field
	mov	cx, ax				; Save previous field end in cx

	pop	di				; di <- tab pos (4/18/94 cbh)
	mov	ax, di				; ax <- tab position

	sub	ax, cx				; ax <- space left of tab

	;
	; Make sure there is enough space to hold the text to the left
	; of the anchor.
	;
	cmp	ax, ss:[bx].TOCV_ext.TOCE_widthToAnchor
	jb	setToPrevFieldEnd		; Branch if there isn't

	;
	; There is no collision with the previous field.
	;
	; Make sure there is enough space after the tabstop to hold the
	; text after the anchor character.
	;
	; Compute:
	; ax	= Distance to right margin from tabstop
	; dx	= Size of the text after the anchor character
	;
	mov	ax, LICL_realRightMargin
	sub	ax, di

	mov	dx, ss:[bx].TOCV_ext.TOCE_justWidth
	sub	dx, ss:[bx].TOCV_ext.TOCE_widthToAnchor

	cmp	ax, dx				; Check for not enough space
	jb	alignRight			; Branch if not enough space

	;
	; The field fits both on the left and on the right.
	;
	mov	ax, di
	sub	ax, ss:[bx].TOCV_ext.TOCE_widthToAnchor

quit:
	;
	; ax	= Position for the field
	;
	.leave
	ret

setToPrevFieldEnd:
	;
	; There isn't enough space to the left of the tabstop to hold all the
	; text we want to put there. We need to butt the field up against
	; the end of the previous field.
	;
	mov	ax, cx
	jmp	quit

alignRight:
	;
	; There isn't enough space to the right of the tabstop to hold all the
	; text after the anchor character. We need to right justify the field
	; against the right-margin.
	;
	mov	ax, LICL_realRightMargin
	sub	ax, ss:[bx].TOCV_ext.TOCE_justWidth
	jmp	quit
AnchorJustifyField	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	AdjustLineHeight

DESCRIPTION:	Adjust line height and baseline offset to account for 
		things like leading, line-spacing, and space added to the
		tops and bottoms of paragraphs.

CALLED BY:	LineInfoCalcLine

PASS:
	*ds:si - text object
	ss:bx - TOC_vars
	ss:bp - LICL_vars structure
		LICL_paraAttr - set
		LICL_line - set

RETURN:
	LICL_line - updated

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (leading != 0) {
	    /* Leading is the space between baselines */
	    if (line == firstLine) {
		BLO = oldBLO + leading - height
	    } else {
		prevBLO = LineInfoGetBLO( prevLine )
		prevHeight = LineInfoGetHeight( prevLine )
		/* need the size of the descender */
		descender = prevHeight - prevBLO
		BLO = leading - descender
	    }
	    height = leading
	}
	if (line spacing != 1) {
	    height = height * lineSpacing
	}
	if (top line of paragraph) {
	    height, BLO += space on top
	    height, BLO += border space for top
	}
	if (bottom line of paragraph) {
	    height += space on bottom
	    height += border space for bottom
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@
AdjustLineHeight	proc	near
	uses	ax, bx, cx, dx
	.enter
	;
	; if bordered top or bottom then set LICL_line.LI_{next,prev}LineBorder
	;
	test	LICL_paraAttr.VTPA_borderFlags, mask VTPBF_TOP or mask VTPBF_BOTTOM
	jz	noGetInfo			;Skip if no top/bottom border.
	call	GetPrevNextLineBorderInfo
noGetInfo:

	;
	; Account for leading.
	;
	; If there is leading, then we need to set the distance between the
	; baseline for this line and the baseline for the previous line to
	; the leading value.
	;
	; If this is the first line in a paragraph then we need to set the
	; line height to the leading value.
	;
	mov	ax, LICL_paraAttr.VTPA_leading	; Check for no leading at all.
	tst	ax
	jz	noLeading
	call	AdjustForLeading
noLeading:

	;
	; Account for line spacing. The line spacing is a multiplier and is
	; applied to the "natural" height of the line to generate the
	; height used for display. The line spacing is computed after the
	; leading has been applied so that things like double spacing will
	; work even on leaded lines.
	;
	cmp	{word} LICL_paraAttr.VTPA_lineSpacing, 0x0100
	je	noLineSpacing
	call	AdjustForLineSpacing
noLineSpacing:

	;
	; Check top line of PP. Top line of a paragraph may call for adjustments
	; based on the border thickness. (If the thing has a border at all).
	;
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_STARTS_PARAGRAPH
	jz	noPPStart
	call	AdjustParagraphStart
noPPStart:

	;
	; Check bottom line of PP. Bottom line of a paragraph may also call for
	; adjustments due to borders.
	;
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_ENDS_PARAGRAPH
	jz	noPPEnd
	call	AdjustParagraphEnd
noPPEnd:

	;
	; If this is a single line text object, then we need to adjust
	; the baseline and height to compensate for accent characters.
	;
	; In multi-line text objects we just let lines with accents interact
	; with the lines above them. We can't do that with one-line objects
	; because the accents just vanish under the clip-region.
	; 
	; A single line object can only be have one charAttr (that's all that
	; is allowed).
	;
	call	AdjustSingleLineObject

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added,  9/ 9/93 -jw
; Check for the object having the ATTR_ that implies adjusting the line height
; by adding space at the top of all lines.
	push	ax
	push	bx

	mov	ax, ATTR_VIS_TEXT_ADD_SPACE_TO_ALL_LINES
	call	ObjVarFindData			; carry set if found
						; ds:bx <- ptr to data
	jnc	noLineSpaceOnTop		; Branch if not found
	
	;
	; There object requires that space be added to the top of every line.
	; Make the adjustment.
	;
	mov	ax, ds:[bx]			; ax <- extra space in points
	
	;
	; Restore pointer to stack frame, then push it again so that
	; we don't get stack nukage later.
	;
	pop	bx
	push	bx

	;
	; Compute and save the new height and baseline
	;
	add	ss:[bx].TOCV_ext.TOCE_lineHeight.WBF_int, ax
	add	ss:[bx].TOCV_ext.TOCE_lineBLO.WBF_int, ax

noLineSpaceOnTop:
	pop	bx
;
; Now, deal with the text object getting too large...
;
MAXIMUM_HEIGHT_FOR_TEXT_OBJECT	equ	32700	;Must be < 0x7fff

	mov	ax, ss:[bp].LICL_lineBottom.WBF_int
	add	ax, ss:[bx].TOCV_ext.TOCE_lineHeight.WBF_int
	cmp	ax, MAXIMUM_HEIGHT_FOR_TEXT_OBJECT
	jbe	heightInBounds

;	The text object is getting too large, so set this line height to 0

	clrwbf	ss:[bx].TOCV_ext.TOCE_lineHeight
	clrwbf	ss:[bx].TOCV_ext.TOCE_lineBLO
heightInBounds:
	pop	ax
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



;;quit:
	.leave
	ret
AdjustLineHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrevNextLineBorderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get border info for the previous and next lines.

CALLED BY:	AdjustLineHeight
PASS:		*ds:si	= Instance ptr
		ss:bx	= TOC_vars
		ss:bp	= LICL_vars
		es:di	= Pointer to line we're calculating
RETURN:		Border information for next and previous lines set in
		the LICL_vars
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextLineCalc ends
TextBorder segment resource

GetPrevNextLineBorderInfo	proc	far
	uses	ax, bx, di
	.enter
	;
	; if CF_SAVE_RESULTS is not set, assume the caller is taking care of
	; saving the previous-lines border attributes
	;
	test	ss:[bp].LICL_calcFlags, mask CF_SAVE_RESULTS
	jz	afterPrevLineBorder
	
	;
	; Get border information for previous line.
	;
	push	bx, di				; Save frame ptr, line
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- current line
	call	GetPrevBorder
	pop	bx, di				; Restore frame ptr, line
afterPrevLineBorder:
	
	clr	ax				; Assume current is last line
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_ENDS_IN_NULL
	jnz	gotCurrentBorderFlags		; Branch if last line
	
	;
	; Get the paragraph attributes for the next line.
	; dx.ax <- offset into the text where next line starts
	;
	push	bx				; Save frame ptr
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	call	T_GetBorderInfo			; ax <- BorderFlags
						; bx, nuked
	pop	bx				; Restore frame ptr
gotCurrentBorderFlags:

	;
	; Save margins and border attributes for various things
	; ax	= Border flags for next line
	;
	mov	LICL_nextLineBorder, ax
	.leave
	ret
GetPrevNextLineBorderInfo	endp

TextBorder ends
TextLineCalc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForLeading
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust for line leading.

CALLED BY:	LICLAdjustLineHeight
PASS:		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		ax	= leading (assumed to be non-zero)
RETURN:		line height and baseline adjusted correctly.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
    if (saving results) {
	if (line == firstLine) {
	    BLO = oldBLO + leading - height
	} else {
	    prevBLO = LineInfoGetBLO( prevLine )
	    prevHeight = LineInfoGetHeight( prevLine )
	    /* need the size of the descender */
	    descender = prevHeight - prevBLO
	    BLO = (leading + (ENDS_PARAGRAPH ? end paragraph spacing : 0))
			- descender 
	}
    }
    height = leading

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustForLeading	proc	near	uses	cx, dx, di
	.enter
	;
	; The first line of a region shouldn't be leaded, since there is no
	; line above it.
	; 
	cmpdw	ss:[bp].LICL_line, ss:[bp].LICL_regionTopLine, cx
	jne	notFirst

exit:
	.leave
	ret

notFirst:
if 0	;No, we really want to use manual leading in the first line of
	;a paragraph.  Otherwise it tend to not be very useful.
	;		 -- tony -- 5/10/93
	;
	; The first line of a paragraph is never leaded.
	;
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_STARTS_PARAGRAPH
	jnz	quit
endif

	;
	; ax is 13 bits of integer and 3 bits of fraction.
	; For now just round it to an integer.
	;
	add	ax, (1 shl (offset TITF_INT - 1))
	ExtractField	word, ax, TITF_INT, ax

	test	ss:[bp].LICL_calcFlags, mask CF_SAVE_RESULTS
	jz	setHeight			; Set height if not saving

	;
	; Want to set the baseline of this line to a fixed distance
	; from the previous lines baseline.
	;
	push	bx, di				; Save frame ptr, line
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- current line

	call	TL_LinePrevious			; bx.di <- previous line

	;
	; If the previous line is the end of a paragraph, and there
	; is spacing added to the end of the paragraph. Then add
	; that extra space to the leading value, for the purposes of
	; calculating the baseline of the current line of text.
	;	
	mov_tr	cx, ax
	mov	ax, mask LF_ENDS_PARAGRAPH
	call	TL_LineTestFlags
	mov_tr	ax, cx
	push	ax				; save original leading value
	jz	dontAddEndParagraphSpacing

	mov	cx, LICL_paraAttr.VTPA_spaceOnBottom
	ExtractField	word, cx, TITF_INT, dx	; dx <- integer part
	ExtractField	word, cx, TITF_FRAC, cx	; cx <- fraction
	add	ax, dx				; ax <- adjustment integer
	rnduwbf	axcl, ax

dontAddEndParagraphSpacing:

	push	bx				; Save high word of line
	call	TL_LineGetBLO			; dx.bl <- prev baseline
	rnduwbf	dxbl, cx			; cx <- rounded baseline
	pop	bx				; Restore high word of line

	call	TL_LineGetHeight		; dx.bl <- prev line height
	rnduwbf	dxbl, dx			; dx <- rounded height

	;
	; cx	= Rounded baseline
	; dx	= Rounded height
	; ax	= Rounded leading value
	;
	sub	dx, cx				; dx <- prev line descender

	mov	cx, ax				; cx <- leading value
	pop	ax				; restore original leading
	sub	cx, dx				; cx <- new baseline
	pop	bx, di				; Restore frame ptr, line

	;
	; Set the new baseline (cx).
	;
	clr	dl
	movwbf	ss:[bx].TOCV_ext.TOCE_lineBLO, cxdl

setHeight:
	;
	; Set the new height (ax).
	;
	clr	dl
	movwbf	ss:[bx].TOCV_ext.TOCE_lineHeight, axdl
	jmp	exit

AdjustForLeading	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForLineSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the line height and baseline for line-spacing

CALLED BY:	AdjustLineHeight
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Current line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	 Line spacing is BBFixed. Line height is WBFixed.
	 Here is the general algorithm...
		AB.C		<- line height.
	    *   D.E		<- line spacing.
	   ----------
	   (AB * D.E) + (.C * D.E)
	
	 We can guarantee that (AB * D.E) will not result in a three byte
	 integer portion. If it does, we fatal error (ha ha ha ha ha).
	
	 We do this multiplication in portions:
		   ax <- AB
		dx.ax <- AB * D.E	(We discard highest integer portion).
		cx.bl <- dl.ah.al
		   ax <- B.C
		dx.ax <- B.C * D.E	(We discard lowest fractional portion)
		dx.ah <- dx.ah + cx.bl	(Save the new line height).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustForLineSpacing	proc	near
	uses	ax, cx, dx, si
	.enter
	mov	si, {word} LICL_paraAttr.VTPA_lineSpacing
	cmp	si, 0x100			;Special case of multiplier = 1
	jz	quit				;Skip if multiplier = 1

	push	bx				;Save frame ptr
	;
	; Do first multiply.
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_lineHeight.WBF_int
	mul	si				;dx.ax = result of 1st part
EC <	tst	dh							>
EC <	ERROR_NZ VIS_TEXT_LINE_SPACING_CAUSED_OVERFLOW			>

	;
	; Save fractional line height in dh
	;
	mov	dh, ss:[bx].TOCV_ext.TOCE_lineHeight.WBF_frac
	mov	ch, dl				;cx.bl <- useful part of result
	mov	cl, ah
	mov	bl, al

	;
	; Do second multiply.
	;
	mov	al, dh
	clr	ah
	mul	si				;dx.ax <- result of second part
	add	ah, bl
	adc	dx, cx				;dx.ah <- new line height

	pop	bx				;Restore frame ptr
	
	movwbf	ss:[bx].TOCV_ext.TOCE_lineHeight, dxah
quit:
	.leave
	ret
AdjustForLineSpacing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustParagraphStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the line height for being the first line in a 
		paragraph.

CALLED BY:	AdjustLineHeight
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustParagraphStart	proc	near
	uses	ax, cx, dx
	.enter
	clr	ax				;assume no border
	mov	cx, mask VTPBF_TOP
	test	LICL_paraAttr.VTPA_borderFlags, cx
	jz	10$

	push	bx				;Save frame ptr
	call	CalcBorderSpacing		;ax <- border width
	pop	bx				;Restore frame ptr
10$:
	;
	; ax	= Spacing for border
	; ss:bp	= LICL_vars
	; ss:bx	= TOC_vars
	;
	; The spaceOnTop field is stored as a 13.3 value.
	;
	;
	; The first line of a region shouldn't be leaded, since there is no
	; line above it.
	; 
	tst	ax				; Check for has border
	jnz	useSpace

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed,  9/ 1/93 -jw
	;
	; If this is not the first line of the region, all spacing applies.
	;
	cmpdw	ss:[bp].LICL_line, ss:[bp].LICL_regionTopLine, cx
	jne	useSpace
	
	;
	; This is the first line of the region. Check to see if the user
	; wants additional spacing.
	;
	push	bx
	mov	ax, ATTR_VIS_TEXT_ADD_SPACE_ON_TOP_TO_FIRST_LINE_OF_REGION
	call	ObjVarFindData			; carry set if found
						; ds:bx <- ptr to data
	mov	ax, 0				; Assume not found
	jnc	gotExtra			; Branch if not found
	mov	ax, ds:[bx]			; ax <- extra space in points
gotExtra:
	pop	bx
	
	;
	; ax is the amount of extra space we need given the previous hint.
	;
	;
	tst	ax
	jz	quit				; Branch if no space.
	
useSpace:
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	mov	cx, LICL_paraAttr.VTPA_spaceOnTop
	ExtractField	word, cx, TITF_INT, dx	; dx <- integer part
	ExtractField	word, cx, TITF_FRAC, cx	; cx <- fraction
	add	ax, dx				; ax <- adjustment integer

	;
	; ax.cl = Amount to add to both the height and the baseline
	;

	;
	; Compute and save the new height
	;
	addwbf	ss:[bx].TOCV_ext.TOCE_lineHeight, axcl

	;
	; Compute and save the new baseline
	;
	addwbf	ss:[bx].TOCV_ext.TOCE_lineBLO, axcl
quit::
	.leave
	ret
AdjustParagraphStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustParagraphEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a line height for a line being the last line in a
		paragraph

CALLED BY:	AdjustLineHeight
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustParagraphEnd	proc	near
	uses	ax, cx, dx
	.enter
	clr	ax				; assume no border
	mov	cx, mask VTPBF_BOTTOM
	test	LICL_paraAttr.VTPA_borderFlags, cx
	jz	10$

	push	bx				;Save frame ptr
	call	CalcBorderSpacing		; ax <- border width.
	pop	bx				;Restore frame ptr
10$:
	;
	; ax	= Spacing for border
	; ss:bp	= LICL_vars
	; ss:bx	= TOC_vars
	;
	; The spaceOnBottom field is stored as a 13.3 value.
	;
	mov	cx, LICL_paraAttr.VTPA_spaceOnBottom
	ExtractField	word, cx, TITF_INT, dx	; dx <- integer part
	ExtractField	word, cx, TITF_FRAC, cx	; cx <- fraction
	add	ax, dx				; ax <- adjustment integer

	;
	; Adjust line height by ax.cl
	;
	addwbf	ss:[bx].TOCV_ext.TOCE_lineHeight, axcl
	.leave
	ret
AdjustParagraphEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSingleLineObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the height and baseline of a single line object

CALLED BY:	AdjustLineHeight
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSingleLineObject	proc	near
	class	VisTextClass

	push	di
	call	Text_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jz	done				; Branch if not 1 line object

	uses	ax, cx, dx, si
	minHeight	local	WBFixed
	.enter

	clrwbf	minHeight
	push	bx
	mov	ax, ATTR_VIS_TEXT_MINIMUM_SINGLE_LINE_HEIGHT
	call	ObjVarFindData
	jnc	noMinHeight
	movwbf	minHeight, ds:[bx], ax
noMinHeight:
	pop	bx

	;
	; Get accent height and add it to the baseline of the line.
	; The gstate must be created at this point, it just must :-)
	;

	mov	di, ds:[di].VTI_gstate		; di <- gstate
	mov	si, GFMI_ABOVE_BOX
	call	GrFontMetrics			; dx.ah <- aboveBox height

	;
	; Adjust the baseline.
	;
	addwbf	ss:[bx].TOCV_ext.TOCE_lineBLO, dxah
	
	;
	; Compute the line height, and make sure it lies within the maximum
	;
	mov	si, GFMI_MAX_ADJUSTED_HEIGHT
	call	GrFontMetrics			; dx.ah <- total height
	cmpwbf	dxah,minHeight
	jae	10$
	movwbf	dxah, minHeight
10$:
	
	movwbf	ss:[bx].TOCV_ext.TOCE_lineHeight, dxah

	
	.leave
done:
	pop	di
	ret
AdjustSingleLineObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleJustification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle justification of a line.

CALLED BY:	CommonLineCalculate
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		cx	= Pointer past line/field data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	extra	   = areaToFill - fieldJustWidth
	spacePad   = 0
	adjustment = 0
	if (justification == LEFT) {
	    /* Do nothing, defaults are OK */
	} else if (justification == FULL) {
	    if (line ends in word-wrap) {
		spacePad = extra / nSpaces
	    }
	} else {
	    adjustment = extra
	    if (justification == CENTER) {
		adjustment /= 2
	    }
	}
	line.adjustment = adjustment
	lastField.spacePad = spacePad

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleJustification	proc	near
	uses	ax, cx, dx
	.enter
	;
	; If we aren't saving the results then all these calculations are
	; meaningless. They have no affect on where things are word-wrapped.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_SAVE_RESULTS
	jz	quit

	;
	; There are two special cases to consider:
	;	1) A single character being wider than the entire field.
	;	2) The text fits exactly into the field with no leftover space.
	;
	; In both of these cases we left-justify the line.
	;
	call	FigureLastFieldEndForJustification
						; dx <- end of last field for
						;    justification purposes

	push	bx				; Save frame ptr
	mov	bx, J_LEFT			; Assume special case

	mov	ax, LICL_realRightMargin	; ax <- space after last field
	sub	ax, dx
	jle	gotJustification		; Branch if special case

	;
	; Text fits inside the field area with some space to spare.
	; We can do some sort of justification.
	;
	ExtractField word,LICL_paraAttr.VTPA_attributes,VTPAA_JUSTIFICATION,bx

gotJustification:
	shl	bx, 1				; bx <- index into table
						; bx <- handler routine
	mov	bx, cs:justificationHandlers[bx]
	mov	ax, bx				; ax <- routine to call
	pop	bx				; Restore frame ptr

	;
	; dx	= End of last field
	;
	call	ax				; Call the justification handler
	;
	; dx	= Adjustment for the line
	; ax.ch	= Space padding
	;
	push	dx				; Save adjustment

	mov	dx, ax				; dx.ah <- new space padding
	mov	ah, ch
	call	SaveNewLineSpacePad		; Save the new space padding

	pop	dx				; dx <- new adjustment
	call	GetLineLeftFromTOCV		; ax <- left edge of the line
	add	ax, dx				; ax <- final adjustment

	call	SaveNewLineAdjustment		; Save the new adjustment
quit:
	.leave
	ret
HandleJustification	endp

justificationHandlers	label	word
	word	offset cs:LeftJustifyLine	; J_LEFT
	word	offset cs:RightJustifyLine	; J_RIGHT
	word	offset cs:CenterJustifyLine	; J_CENTER
	word	offset cs:FullJustifyLine	; J_FULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LeftJustifyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Left justify a line

CALLED BY:	HandleJustification
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Pointer to the line
		cx	= Pointer past line/field data
RETURN:		dx	= Line adjustment
		ax.ch	= Space padding
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LeftJustifyLine	proc	near
	clr	dx				; dx <- line adjustment
	clrwbf	axch				; ax.ch <- space-padding
	ret
LeftJustifyLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RightJustifyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Right justify a line

CALLED BY:	HandleJustification
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Pointer to the line
		cx	= Pointer past line/field data
		dx	= End of last field
RETURN:		dx	= Line adjustment
		ax.ch	= Space padding
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RightJustifyLine	proc	near
	mov	ax, dx				; ax <- end of last field

	mov	dx, LICL_realRightMargin	; dx <- adjustment
	sub	dx, ax

	clrwbf	axch				; ax.ch <- space padding
	ret
RightJustifyLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterJustifyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Center justify a line

CALLED BY:	HandleJustification
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Pointer to the line
		cx	= Pointer past line/field data
		dx	= End of last field on the line
RETURN:		dx	= Line adjustment
		ax.ch	= Space padding
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CenterJustifyLine	proc	near
	call	RightJustifyLine		; dx <- adjustment
						; ax.ch <- space padding
	sar	dx, 1				; Only use 1/2 the adjustment
	ret
CenterJustifyLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FullJustifyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Full justify a line

CALLED BY:	HandleJustification
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Pointer to the line
		cx	= Pointer past line/field data
		dx	= End of the last field on the line
RETURN:		dx	= Line adjustment
		ax.ch	= Space padding
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FullJustifyLine	proc	near
	uses	bx, di, si
if CHAR_JUSTIFICATION
	test	ss:[bp].LICL_theParaAttr.VTMPA_paraAttr.VTPA_miscMode, mask TMMF_CHARACTER_JUSTIFICATION
	jnz	FullCharJustifyLine
endif
	.enter
	;
	; Make sure that the line is not the last in a paragraph. If it ends
	; a paragraph then we don't full justify the line.
	;
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_ENDS_PARAGRAPH
	jnz	leftJustify

	;
	; One more special case: The field has no spaces.
	; In this case we just left justify the field.
	;
	tst	ss:[bx].TOCV_ext.TOCE_nSpaces
	jz	leftJustify

	;
	; We need to change the field width so that it occupies the entire
	; area. We do this by figuring the amount of space padding we would
	; need to make the field expand to fit the entire width available to it.
	;
	push	bx, cx				; Save frame ptr, data-end
	mov	cx, dx				; cx <- end of last field on line

	mov	dx, LICL_realRightMargin	; dx <- extra space
	call	GetLineLeftFromTOCV		; ax <- left edge of line
	mov	ss:[bp].LICL_lineJustEnd, dx	; real line end is right margin
	sub	ss:[bp].LICL_lineJustEnd, ax	; remove adjustment amount

	sub	dx, cx
	clr	cx				; dx.cx <- extra space (WWFixed)

	mov	bx, ss:[bx].TOCV_ext.TOCE_nSpaces
	clr	ax				; bx.ax <- # of spaces

	;
	; We divide the amount of space (dx.cx) by the number of spaces (bx.ax)
	;
	call	GrUDivWWFixed			; dx.cx <- space padding
	mov_tr	ax, cx				; dx.ax <- space padding
	pop	bx, cx				; Restore frame ptr, data-end

	;
	; *ds:si= Instance ptr
	; es:di	= Line/field data
	; cx	= Pointer past line/field data
	; dx.ax	= Space padding to use (WWFixed)
	;
	; Before returning the adjustment and the space padding we need to set
	; the width of the field to be the "correct" width.
	;
	; This new width is:
	;	fieldWidth + (nSpace + nExtraSpace)*spacePadding
	; Since the spacePadding is a WWFixed and the space-count is a word
	; the math looks like:
	;	part1 = spaceCount * spacePadding.low   (dx.ax = WWFixed)
	;	part2 = spaceCount * spacePadding.high  (ax    = word)
	;
	; Computation:
	;	es:di <- ptr to last field
	;	si <- total number of spaces
	;	cx.bx <- dx.ax
	;
	;	dx.ax = si * cx		; (part2) ax is significant
	;	field.width.int += dx
	;
	;	dx.ax = si * bx		; (part1) dx.ah is significant
	;	field.width += dx.ah
	;
	pushdw	dxax				; Save space padding

	mov	di, cx				; es:di <- ptr to last field
	sub	di, size FieldInfo
						; si <- total number of spaces
	mov	si, ss:[bx].TOCV_ext.TOCE_nSpaces
	add	si, ss:[bx].TOCV_ext.TOCE_nExtraSpaces

if CHAR_JUSTIFICATION
	call	UpdateFieldWidthCommon
else
	movdw	cxbx, dxax			; cx.bx <- space pad (WWFixed)
	
	;
	; Part2 calculation
	;
	mov	ax, cx				; ax <- integer part
	mul	si				; ax <- part2 (word)
	
	;
	; Part1 calculation
	;
	push	ax				; Save partial result
	mov	ax, bx				; ax <- fractional part
	mul	si				; dx.ah <- part1 (WBFixed)
	rndwbf	dxah, dx			; dx.ah <- part1 (word)
	pop	ax				; Restore partial result
	add	ax, dx				; ax <- total to add
	
	;
	; Update the field width
	;
	add	ax, es:[di].FI_width		; ax <- final width
	
	mov	dx, di				; es:dx <- field pointer
	call	SaveNewFieldWidth		; Save the new width
endif
	
	;
	; The field width is up to date. Restore the space padding to use
	; and set the adjustment to zero.
	;
	popdw	axcx				; ax.ch <- space padding
	clr	dx				; No adjustment
quit:
	;
	; dx	= Line adjustment
	; ax.ch	= Space padding
	;
	.leave
	ret

leftJustify:
	;
	; The line is the last one in the paragraph. We left justify it.
	;
	call	LeftJustifyLine
	jmp	quit
FullJustifyLine	endp

if CHAR_JUSTIFICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFieldWidthCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to update field width

CALLED BY:	FullJustifyLine(), FullCharJustifyLine()
PASS:		dx.ax - space/char pad (WWFixed)
		si - # of spaces/chars
		es:di - ptr to FieldInfo
RETURN:		FI_width - updated
DESTROYED:	ax, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFieldWidthCommon		proc	near
	.enter

	movdw	cxbx, dxax			; cx.bx <- space pad (WWFixed)
	;
	; Part2 calculation
	;
	mov	ax, cx				; ax <- integer part
	mul	si				; ax <- part2 (word)
	;
	; Part1 calculation
	;
	push	ax				; Save partial result
	mov	ax, bx				; ax <- fractional part
	mul	si				; dx.ah <- part1 (WBFixed)
	rndwbf	dxah, dx			; dx.ah <- part1 (word)
	pop	ax				; Restore partial result
	add	ax, dx				; ax <- total to add
	;
	; Update the field width
	;
	add	ax, es:[di].FI_width		; ax <- final width
	
	mov	dx, di				; es:dx <- field pointer
	call	SaveNewFieldWidth		; Save the new width

	.leave
	ret
UpdateFieldWidthCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FullCharJustifyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Full justify a line using character padding

CALLED BY:	HandleJustification
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Pointer to the line
		cx	= Pointer past line/field data
		dx	= End of the last field on the line
RETURN:		dx	= Line adjustment
		ax.ch	= Space padding
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	 5/26/94	Initial version (based on FullJustifyLine)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FullCharJustifyLine	proc	near
	uses	bx, di, si
	.enter

	;
	; We need to change the field width so that it occupies the entire
	; area. We do this by figuring the amount of char padding we would
	; need to make the field expand to fit the entire width available to it.
	;
	push	bx, cx				; Save frame ptr, data-end
	mov	cx, dx				; cx <- end of last field on line

	mov	dx, LICL_realRightMargin	; dx <- extra space
	call	GetLineLeftFromTOCV		; ax <- left edge of line
	mov	ss:[bp].LICL_lineJustEnd, dx	; real line end is right margin
	sub	ss:[bp].LICL_lineJustEnd, ax	; remove adjustment amount

	sub	dx, cx
	clr	cx				; dx.cx <- extra space (WWFixed)
	;
	; Divide the space available *between* the characters (hence the -1).
	; Handle no or only one character by left justifying the line.
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_nChars
	tst	ax				; any characters?
	jz	leftJustifyPop			; branch if no chars
	dec	ax
	jz	leftJustifyPop			; branch if only one char
	;
	; See if the line ends a paragraph, and if so don't count the CR.
	;
	test	ss:[bx].TOCV_ext.TOCE_lineFlags, mask LF_ENDS_IN_CR
	jz	noCR
	dec	ax
	jz	leftJustifyPop			; branch if only one char
noCR:
	mov	bx, ax
	clr	ax				; bx.ax <- # of chars

	;
	; We divide the amount of space (dx.cx) by the number of spaces (bx.ax)
	;
	call	GrUDivWWFixed			; dx.cx <- space padding
	mov_tr	ax, cx				; dx.ax <- space padding
	pop	bx, cx				; Restore frame ptr, data-end

	pushdw	dxax				; Save char padding

	mov	di, cx				; es:di <- ptr to last field
	sub	di, size FieldInfo

						; si <- total number of chars
	mov	si, ss:[bx].TOCV_ext.TOCE_nChars
	call	UpdateFieldWidthCommon

	;
	; The field width is up to date. Restore the char padding to use
	; and set the adjustment to zero.
	;
	popdw	axcx				; ax.ch <- space padding
	clr	dx				; No adjustment
	ornf	ah, mask TMMF_CHARACTER_JUSTIFICATION

quit:
	;
	; dx	= Line adjustment
	; ax.ch	= Space padding
	;
	.leave
	ret

leftJustifyPop:
	pop	bx, cx
	;
	; The line has only 1 character -- left justify it
	;
	call	LeftJustifyLine
	jmp	quit
FullCharJustifyLine	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureLastFieldEndForJustification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the end of the last field on the line.

CALLED BY:	HandleJustification
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		cx	= Pointer past line/field data
RETURN:		dx	= End of last field, including margin
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureLastFieldEndForJustification	proc	near
	uses	ax, di
	.enter
	mov	di, cx				; es:di <- ptr to last field
	sub	di, size FieldInfo
	
	mov	dx, es:[di].FI_position		; dx <- position of field
	
	call	GetLineLeftFromTOCV		; ax <- left edge of line
	add	dx, ax				; dx <- left edge of field
	
						; Add in justification width
	add	dx, ss:[bp].LICL_lastFieldJustWidth
	.leave
	ret
FigureLastFieldEndForJustification	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateCharAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for GrTextObjCalc. 
		Returns the character attributes for a given text offset

CALLED BY:	GrTextObjCalc from CommonLineCalculate
PASS:		ss:bx	= TOC_vars
		di	= Offset into the field
		ds	= Segment address of old text pointer
RETURN:		TMS_textAttr set
		ds:si	= Pointer to the text
		cx	= Number of characters in this style
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateCharAttrCallback	proc	far
	uses	ax, bx, dx, di, bp
	.enter
	;
	; Check to see if we need to unlock the old text pointer
	;
	mov	bx, bp				; ss:bx <- TOC_vars
	mov	bp, ss:[bp].TOCV_ext.TOCE_passBack ; ss:bp <- LICL_vars

	mov	ax, ds				; ax <- segment addr of old text
	lds	si, ss:[bp].LICL_object		; *ds:si <- text instance

	tst	di				; Branch if this is the first
	jz	firstCall			;    callback
	call	TS_UnlockTextPtr		; Release the old text
firstCall:

	;
	; Compute the offset into the text object
	;
	clr	dx				; dx.ax <- offset into field
	mov	ax, di
						; dx.ax <- offset into object
	adddw	dxax, ss:[bp].LICL_range.VTR_start

	;
	; Get a pointer to the text
	;
	push	ax				; Save low word of offset
	call	TS_LockTextPtr			; ds:si <- ptr to the text
						; ax <- # of characters
	mov	cx, ax				; cx <- # of characters
	pop	ax				; Restore low word of offset

	;
	; Mark that we've locked some text
	;
	or	ss:[bp].LICL_calcFlags, mask CF_TEXT_LOCKED

	;
	; ds:si	= Pointer to text
	; cx	= Number of characters after ds:si
	; ss:bp	= LICL_vars
	; ss:bx	= TOC_vars
	;
	; Fill in all the attributes, we need:
	;	*ds:si	= Instance
	;	bx:di	= Pointer to TextAttr structure
	;	dx.ax	= Offset into text (already set)
	;
	push	cx, ds, si			; Save:	Num chars after ds:si
	push	di				;	Offset to start of run
						;	Pointer to text
	lds	si, ss:[bp].LICL_object		; *ds:si <- text instance
	lea	di, ss:[bx].TMS_textAttr	; bx:di <- ptr to attributes
        push    bx
	mov	bx, ss

	call	TA_FarFillTextAttrForDraw	; dx.ax <- # of chars in run
						; Carry set if has ext-style
                                                ; cx has VisTextExtendedStyles
        pop     bx
	pushf					; Save "has extd style" flag

	xchg	cx, ax				; cx <- # of characters
                                                ; ax has VisTextExtendedStyles
	tst	dx				; if nChars <= 64K, then done
	jz	gotNumChars
	mov	cx, 0xffff			; else use 64K-1 chars

gotNumChars:
	popf					; Restore "has extd style" flag
	pop	di
	;
	; Extended styles are implemented in the text object, and not in the
	; kernel. For that reason we need to handle saving the position at
	; which the extended style was encountered, and after the calculation
	; is done, if the extended style is in the line, we need to set the
	; bit which signals that the line contains an extended style.
	;
        ; Actually, we normally will go to noExtStyle, but now tha we
        ; pay attention to the wrap flag, we need to make sure it is turned
        ; off unless explicitly stated.  The structure is not cleared
        ; in between callbacks.  -- lshields 10/24/2000
	jnc	eraseNoWrapFlag

        ; If we have the extended flag of wrap set, then
        ; pass it on to the TextMetricStyle structure for the kernel
        test    ax, mask VTES_NOWRAP
        jne     haveNoWrapFlag

eraseNoWrapFlag:
        and     ss:[bx].TMS_flags, not mask TMSF_NOWRAP
        jmp     doneWrapFlag
haveNoWrapFlag:
        or      ss:[bx].TMS_flags, mask TMSF_NOWRAP

doneWrapFlag:
	cmp	ss:[bp].LICL_extStylePos, -1
	jnz	noExtStyle
	mov	ss:[bp].LICL_extStylePos, di	; Save position

noExtStyle:
	pop	bp, ds, si			; Rstr:	Num chars after ds:si
						;	Offset to start of run
						;	Pointer to text

	;
	; ds:si	= Pointer to text
	; cx	= Number of characters in this style
	; bp	= # of characters after the text pointer
	;
	; We want to return the minimum of the number of characters in this
	; style and the number of characters in this hunk.
	;
	cmp	cx, bp				; Branch if more total chars
	jbe	gotCount			;    than style
	mov	cx, bp				; Else use total count
gotCount:
	.leave
	ret
CalculateCharAttrCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateGraphicCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Graphic callback routine.

CALLED BY:	GrTextObjCalc from CommonLineCalculate
PASS:		ss:bx	= LICL_vars
		di	= Offset into the field
		ds	= Segment address of text pointer
RETURN:		cx	= Height of the graphic of graphic at current position
		dx	= Width of the graphic
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateGraphicCallback	proc	far
	uses	ax, si, bp, ds
	.enter
	mov	bp, ss:[bp].TOCV_ext.TOCE_passBack ; ss:bp <- LICL_vars
	lds	si, ss:[bp].LICL_object		; *ds:si <- instance ptr

	call	TextGStateCreate		; I don't know why we need this

	clr	dx
	mov	ax, di				; dx.ax <- offset into field
						; dx.ax <- current offset
	adddw	dxax, ss:[bp].LICL_range.VTR_start

	call	TG_GraphicRunSize		; cx <- width, dx <- height.
	xchg	cx, dx				; Need them exchanged.

	call	TextGStateDestroy		; Nuke the gstate
	.leave
	ret
CalculateGraphicCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateHyphenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hyphenation callback routine.

CALLED BY:	GrTextObjCalc from CommonLineCalculate

PASS:		ss:bp	= pointer to TOC_vars structure on stack.
		di	= Offset to the place where we would split the word
		TOCI_lastWordStart -
			Offset in the text where the word to break starts
		TOCI_lastWordPos -
			Position (distance from left edge of the field) where
			the word to break starts

RETURN:		TOCI_suggestedHyphen -
			The offset to break the word at. Zero to break at the
			start of the word.
		TOCI_suggestedHyphenPos -
			The position (distance from left edge of the field)
			where the hyphen starts.
		TOCE_hyphenWidth -
			Width of the hyphen that was placed at the end of
			the line.

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateHyphenCallback	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, bp, ds, si, di
	.enter
	mov	bx, ss:[bp].TOCV_ext.TOCE_passBack	; ss:bx <- LICL_vars
	lds	si, ss:[bx].LICL_object			; *ds:si = instance ptr
	
	;
	; Assume hyphenation is not possible.
	;
	clr	ss:[bp].TOCV_int.TOCI_suggestedHyphen

	;
	; If we aren't saving the results, we can't easily do hyphenation
	; because we don't know if the previous lines were hyphenated.
	;
	test	ss:[bx].LICL_calcFlags, mask CF_SAVE_RESULTS
	jz	reallyQuit
	
	;
	; Save the gstate because we might mess with it
	;
	mov	ax, di
	mov	di, ss:[bp].TMS_gstateHandle
	call	GrSaveState
	push	di					; save the handle
	mov	di, ax

	;
	; Check to make sure we haven't hyphenated too many lines in
	; a row - as determined by VisTextHyphenationInfo, which is set by
	; the hyphenation controller.
	;
	call	CheckConsecutiveHyphenatedLines		; cx = nonzero iff OK
	jcxz	quit


setPosition:
	; *ds:si -> instance ptr
	; ss:bp = TOC_vars
	; ss:bx = LICL_vars
	; di 	= break position to try
	;
	; We now need to check di, the word break position, and see whether
	; a hyphen would also fit before the border.  
	;
	; If a hyphen fits, we proceed to check for auto-hyphenation points
	; using that word break position as our limit. 
	;
	; Otherwise if there are more characters in the current word and 
	; before the current break position we decrement the break position
	; until the hyphen will fit. If we run out of characters in the word
	; and the hyphen still won't fit, we can't hyphenate. 
	;
	clr	cx				; cx:di = offset into field
	push	ax
 	call	SetHyphenationPosition		; ax = 0 for NO hyphenation
						; cx:di = field break position
	tst	ax
	pop	ax
	jz	quit

	;
	; Compute the offset to the start of the word and the offset 
	; to where it overflows the line. Pass these off to another module 
	; which actually does the hyphenation work.
	;
	adddw	cxdi, ss:[bx].LICL_range.VTR_start ; cx.di <- offset into text
	
	clr	dx				; dx.ax <- start of the word
	mov	ax, ss:[bp].TOCV_int.TOCI_lastWordStart
	adddw	dxax, ss:[bx].LICL_range.VTR_start

	; set bx = VisTextParaAttr hyphenation info
	
	push	bx				; save ss:bx -> LICL_vars
	mov	bx,ss:[bx].LICL_theParaAttr.VTMPA_paraAttr.VTPA_hyphenationInfo

	;
	; *ds:si= Instance
	; dx.ax	= Word start
	; cx.di	= Word break position 
	; bx	= hyphenation info
	;

	call	HyphenateWord			; Do the hyphenation
						; ax = break pos in the word
	pop	bx				; restore ss:bx -> LICL_vars
	jc	quit				; carry set -> no hyphenation

	;
	; *ds:si= Instance
	; ss:bp	= TOC_vars
	; ss:bx	= LICL_vars
	; ax	= Offset into the word where we want to break
	; di.cl	= Position in the word where the hyphen character starts
	; dx.ch	= Width of the hyphen character
	;

	; 
	; Get the break position in the field so we can check if hyphen fits
	; Field break position = lastWordStart + wordBreakPosition
	;
	add	ax, ss:[bp].TOCV_int.TOCI_lastWordStart	; ax=offset into field
	call	CheckHyphenFits			; carry set -> hyphen doesn't
						; fit, so try again if possible
	jc	resetHyphenation

	;
	; The hyphenation was possible, and the hyphen does fit.
	;

	;
	; Save the hyphen position
	;
	mov	ss:[bp].TOCV_int.TOCI_suggestedHyphen, ax

	;
	; Save the hyphen width
	;
	movwbf	ss:[bp].TOCV_ext.TOCE_hyphenWidth, dxch
	
	;
	; The position where the hyphen starts is:
	;	lastWordPos + hyphenStartPos
	;
	addwbf	dicl, ss:[bp].TOCV_int.TOCI_lastWordPos
	movwbf	ss:[bp].TOCV_int.TOCI_suggestedHyphenPos, dicl

quit:	
	;
	; Restore the gstate
	;
	pop	di
	call	GrRestoreState

reallyQuit:
	.leave
	ret

resetHyphenation:
	clr	cx
	mov	di, ax					; di = break pos 
	jmp	setPosition
CalculateHyphenCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateHeightCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out if the region requires that the line get narrower
		due to a line-height change.

CALLED BY:	GrTextObjCalc
PASS:		ss:bp	= TOC_vars
		ax.bl	= New line height if characters are added
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateHeightCallback	proc	far
	uses	ax, cx, dx, bp, di, ds, si
	.enter
	;
	; Get stack frame pointers that are useful.
	;
	mov	dl, bl				; ax.dl <- line height

	mov	bx, bp				; ss:bx <- TOC_vars
	mov	bp, ss:[bp].TOCV_ext.TOCE_passBack ; ss:bp <- LICL_vars

	lds	si, ss:[bp].LICL_object		; *ds:si = instance ptr
	
	;
	; Compute new values for TA_GetParaAttrForPosition
	;
	cmpwbf	axdl, ss:[bp].LICL_lineHeight	; Check for taller
	jbe	quit				; Branch if not

	;
	; The new field height is taller than the height of the rest of
	; the line.
	;
	; ax.dl	= New line height
	;
	movwbf	ss:[bp].LICL_lineHeight, axdl	; Save new line heightn

	;
	; Compute the old width of the line
	;
	mov	cx, LICL_realRightMargin	; cx <- old right edge
	call	GetLineLeftFromTOCV		; ax <- old left edge
	sub	cx, ax				; cx <- old line width
	mov	dx, cx				; dx <- old line width

	;
	; Fill in new paragraph attributes
	;
	push	dx				; Save old line width
	movdw	dxax, ss:[bp].LICL_lineStart	; dx.ax <- offset of paragraph
	call	T_GetNewParaAttr		; Get (possibly new) attributes
						;  3/28/94: do not use
						;  T_EnsureCorrectParaAttr here,
						;  as we need the attributes for
						;  *this* line (they could have
						;  changed from the margins of
						;  the first line of the
						;  paragraph, owing to wrapping
						;  around graphics) -- ardeb
	pop	dx				; Restore old line width
	
	;
	; Figure the difference in line widths
	;
	mov	cx, LICL_realRightMargin	; cx <- new right edge
	call	GetLineLeftFromTOCV		; ax <- new left edge
	sub	cx, ax				; cx <- new line width
	
	;
	; Compute the difference between the old and new line widths
	;
	sub	cx, dx				; cx <- difference in widths

	;
	; The difference can only be negative. That is to say, the old width
	; can't be less than the new width.
	;
	; If the difference is zero, then quit...
	;
;	tst	cx
;	jz	quit
;
; this can now happen as getting the new para attrs above means we could get
; a paragraph that is wider that the previous one (I have no idea what this
; really means).  (Note we nuked the above tst also, as adding zero below is
; not a problem) - brianc 5/3/94
;
;EC <	ERROR_NS	-1						>

	;
	; The new difference isn't zero, we need to adjust the area to fill
	; down by the difference.
	;
	add	ss:[bx].TOCV_ext.TOCE_areaToFill, cx
quit:
	.leave
	ret
CalculateHeightCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateTabCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for GrTextObjCalc() when it encounters a TAB
		character as the first char in a field.

CALLED BY:	GrTextObjCalc from CommonLineCalculate
PASS:		ds:si	= pointer to text
		ss:bp	= TOC_vars
		ss:bx	= LICL_vars
RETURN:		carry set if there is no tabstop within the margins.
		TOCE_areaToFill set correctly.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the field starts with a tab, then we want to choose the appropriate
	tabstop for it. This means searching for a tabstop in the paraAttr, if
	none is found, using a default tabstop, and if no tabstop is available
	then using the intrinsic width of the tab character to decide where
	the field falls. If the intrinsic width of a TAB is too large to fit
	on the line, then we return the carry set to signify that there is
	no area to fit to.

	If the tab is not a left-justified tab-stop then the space available
	to it has already been set by ComputeAreaToFill() before GrTextObjCalc
	was ever called.

	Depends on the associated tabstop.
	    Left tabstop:
		Distance from this tabstop to right margin.
	    No, Right, Center, Character anchored  tabstop:
		Distance from end of previous field to right margin.
		(Already set by ComputeAreaToFill)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateTabCallback	proc	far
	uses	ax, bx, cx, dx, di, si, bp, ds, es
	.enter
	mov	bx, bp				; ss:bx <- TOC_vars
	mov	bp, ss:[bp].TOCV_ext.TOCE_passBack ; ss:bp <- LICL_vars

	lds	si, ss:[bp].LICL_object		; *ds:si <- instance ptr
	les	di, ss:[bp].LICL_linePtr	; es:di <- line pointer
	mov	dx, ss:[bp].LICL_fieldPtr	; es:dx <- field pointer

	call	FindNextTabStop			; carry set if none found
						; dx <- position of tab
						; al <- TabAttributes

	jc	quit				; Branch if there is none
	
	;
	; There is a tabstop. Check the type of the tabstop.
	;
	ExtractField	byte, al, TA_TYPE, al	; al <- tab justification
	cmp	al, TT_LEFT
	jne	quitHasSpace

	;
	; Left justified tabstop.
	;
	mov	ax, LICL_realRightMargin	; ax <- end of area
	sub	ax, dx				; ax <- space to fill
	mov	ss:[bx].TOCV_ext.TOCE_areaToFill, ax

quitHasSpace:
	clc					; Signal there is space

quit:
	.leave
	ret
CalculateTabCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextTabStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the tabstop to associate with the next field.

CALLED BY:	TabCallBack
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		es:dx	= Field
RETURN:		carry set if there are no tabstops left on the line.
		dx	= Position of the tab
		al	= TabAttributes
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Find the first tab in the tab list whose position is greater than the
	end of the previous field.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 1/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextTabStop	proc	near
	uses	cx, si
	.enter
	call	ComputeEndPrevField		; ax <- position to search from

	mov	si, dx				; es:si <- field

DBCS <	push	di							>
	call	SearchRulerTabList		; Find a tab in the ruler
	jc	setTab				; Branch if we found one

	;
	; The current line doesn't have any user-set tabs after the current
	; position. Check to see if there are any default tabs we can use.
	;
	call	ChooseDefaultTab		; Find a default tab
	jc	setTab				; Branch if we found one

DBCS <	pop	di							>

	;
	; No suitable default tabstop see if there is a usable tabstop on the
	; next line.
	;
	; If there is then we can return 'no suitable tab' and the tab will
	; advance to the next line.
	;
	; If there isn't then we need to use the intrinsic width of a tab to
	; get a new position. If that position is beyond the right margin then
	; we want to return that no tab worked.
	;
	call	CheckNextLineHasUsableTab
	jc	done				; Branch if next has usable tab

	;
	; The current line has no more tabs and no more default tabs on it.
	; The next line doesn't have any tabs that we can tab to. Check to see
	; if a tab-character of some "intrinsic" space can fit.
	;
	call	CheckIntrinsicTabWidth
	jc	done				; Branch if intr. tab won't fit
	
	;
	; The current line has no more tabs on it. It also has no more default
	; tabs on it. The next line has no tabs on it that we can tab to.
	; The current line can hold a tab-character that has the "intrinsic"
	; width so we use that.
	;
DBCS <	push	di							>

setTab:
	;
	; dl	= TabReference
	; cx	= Position of tab
	; al	= TabAttributes
SBCS <	; ah	= Tab anchor character					>
DBCS <	; di	= Tab anchor character					>
	; ss:bx	= TOC_vars
DBCS <	; on stack = saved DI						>
	;
	mov	ss:[bp].LICL_tabReference, dl	; Save the tab-reference to use

SBCS <	mov	dl, ah				; dx <- anchor character>
SBCS <	clr	dh							>
SBCS <	mov	ss:[bx].TOCV_ext.TOCE_anchorChar, dx			>
DBCS <	mov	ss:[bx].TOCV_ext.TOCE_anchorChar, di			>

	mov	dx, cx				; dx <- position of tab
						; al already holds TabAttributes

	clc					; Signal: Usable tab found
DBCS <	pop	di							>
done:
	.leave
	ret
FindNextTabStop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchRulerTabList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the rulers tab-list looking for a suitable tab.

CALLED BY:	FindNextTabStop
PASS:		ax	= Position to search from
		ss:bp	= LICL_vars
RETURN:		carry set if we found a usable tab
		dl	= TabReference
		cx	= Position of the tab
		al	= TabAttributes
SBCS <		ah	= Tab anchor character				>
DBCS <		di	= Tab anchor character				>
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	tab = FindTabInList(pos, tabList)
	if (no tab found) {
	    if (pos < leftMargin) {
	        Use left margin as tab
	    }
	} else {
	    if (pos < leftMargin) {
	        if (tab.pos > leftMargin) {
		    Use left margin as tab
		}
	    }
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchRulerTabList	proc	near
	uses	bx
	.enter
	clr	cx				; cx <- number of tabs in line
	mov	cl, LICL_paraAttr.VTPA_numberOfTabs

	mov	dx, LICL_realRightMargin	; dx <- margin to wrap to

	lea	bx, ss:[bp][LICL_theParaAttr+VTPA_tabList]

	;
	; ax	= Position after which we want to find a tab
	; cx	= Number of tabs
	; ss:bx	= Pointer to tab list
	; dx	= Right margin we are wrapping to
	;
	; Run through the list of tabs until we run out, or we find one which
	; fits the bill.
	;
	jcxz	noneFound			; Quit if no tabs

tabLoop:
	cmp	ss:[bx].T_position, dx		; Check for beyond right-margin
	ja	noneFound			; Assume none if so

	cmp	ss:[bx].T_position, ax		; Check for after position
	ja	foundTab			; Found one if it is

	add	bx, size Tab			; Advance to next tab
	loop	tabLoop				; Loop to try next one

noneFound:
	;
	; No suitable tab was found.
	; Check for current position being less than the left margin.
	; If it is, then use the left margin value.
	;
	cmp	ax, LICL_paraAttr.VTPA_leftMargin
	jb	useLeftMargin
	
	;
	; Check for the current position being less than the para-margin.
	; If it is, then use the para margin value.
	;
	cmp	ax, LICL_paraAttr.VTPA_paraMargin
	jae	noSuitableTab
	
	mov	cx, LICL_paraAttr.VTPA_paraMargin
	mov	dl, RULER_TAB_TO_PARA_MARGIN
	mov	ax, TT_LEFT or (0 shl 8)		; al = attr (TT_LEFT)
	jmp	gotTab

useLeftMargin:
	;
	; Position is less than the left margin, tab to the left margin.
	;
	mov	cx, LICL_paraAttr.VTPA_leftMargin
	mov	dl, RULER_TAB_TO_LEFT_MARGIN
	mov	ax, TT_LEFT or (0 shl 8)		; al = attr (TT_LEFT)
							; ah = anchor (none)
	jmp	gotTab

useTab:
	mov	dl, TRT_RULER shl offset TR_TYPE
	or	dl, cl				; Save reference #

	mov	cx, ss:[bx].T_position
SBCS <	mov	ax, ss:[bx].T_anchor		; ah = anchor	>
DBCS <	mov	di, ss:[bx].T_anchor		; di = anchor	>
SBCS <	mov	ah, al				>

	mov	al, ss:[bx].T_attr		; al = attr

gotTab:
	stc					; Signal: found a tab
quit:
	;
	; carry set if we found a usable tab.
	;   cx	= Position of the tab
	;   dl	= TabReference
	;   al	= TabAttributes
SBCS <	;   ah	= Tab anchor character				>
DBCS <	;   di	= Tab anchor character				>
	;
	.leave
	ret


foundTab:
	;
	; Found a suitable tabstop.
	;
	; If the position is less than the left margin and the tab that we
	; found is greater than the left margin, we want to use the left
	; margin as the position.
	;
	; ax	= Position we started looking from
	; ss:bx	= Pointer to the tab
	;
	cmp	ax, LICL_paraAttr.VTPA_leftMargin
	jae	useTab

	mov	ax, ss:[bx].T_position
	cmp	ax, LICL_paraAttr.VTPA_leftMargin
	ja	useLeftMargin
	jmp	useTab

noSuitableTab:
	clc
	jmp	quit
SearchRulerTabList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseDefaultTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a usable default tab after a given position

CALLED BY:	FindNextTabStop
PASS:		ss:bp	= LICL_vars
		ax	= Position to find the tab after
RETURN:		carry set if the tab was found
			dl	= TabReference
			cx	= Position of tab
			al	= TabAttributes
SBCS <			ah	= Tab anchor character			>
DBCS <			di	= Tab anchor character			>
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChooseDefaultTab	proc	near
	uses	di
	.enter
	;
	; Check for no default tabs.
	;
	tst	LICL_paraAttr.VTPA_defaultTabs	; Check for no default tabs
	jz	done				; carry clear if we branch

	;
	; What we are doing here is the following:
	;   ax = the current position.
	;
	;   round ax up to the next default tab position by adding in the size
	;   of the default tab (+1) and rounding down.
	;
	;   cx = distance between tabs * 32
	;   ax = current position * 32
	;
	inc	ax				; Force to next tab
	mov	cl, 5				; cl <- # of bits of fraction
	shl	ax, cl				; ax <- position * 32

	;
	; Now ax is a 11.5 (integer.fraction) value.
	;
	; Compute the size of a default tab into cx.
	;
	mov	cx, LICL_paraAttr.VTPA_defaultTabs
	shl	cx
	shl	cx				; cx <- spacing * 32

	;
	; Get the position past the next default tab and round down to the
	; nearest default tabstop position.
	;
	clr	dx				; dx.ax <- position
	add	ax, cx				; ax <- distance past next tab
	adc	dx, 0

	push	ax				; Save position past tabstop
	div	cx				; ax <- default tab number
						; dx <- remainder
	pop	cx				; cx <- position past tabstop.
	
	;
	; cx	= Position we were looking for a default tab near
	; ax	= Default tab number (numbered from 0 on the left)
	; dx	= Remainder (distance from tabstop to position in cx)
	;
	sub	cx, dx				; cx <- position of tabstop

	;
	; The position (in cx) is an 11.5 (integer.fraction) value. Since
	; we aren't dealing with fractions here we shift right 5 times to
	; get an integer value
	;
	ExtractField	word, cx, EIFF_INT, cx	; cx <- integer position

	;
	; Almost done... We just need to get everything into the right registers
	; cx	= Position of the tabstop
	; al	= Default tab number
	;
	mov	dl, al				; dl <- default tab number
	or	dl, (TRT_OTHER shl offset TR_TYPE)
	mov	al, TT_LEFT			; Default tab <=> left justified
SBCS <	mov	ah, 0				; No anchor character	>
DBCS <	mov	di, 0				; No anchor character	>

	;
	; Now check to see if the tab position that we have established is
	; beyond the right margin of the line. If it is, then we want to
	; return the carry clear, signifying that there is no suitable default
	; tab on this line.
	;
	cmp	cx, LICL_realRightMargin
	ja	done				; (carry clear if jump taken)
	stc					; Signal tab is inside margin
done:
	.leave
	ret
ChooseDefaultTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNextLineHasUsableTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the next line has a usable tab on it.

CALLED BY:	FindNextTabStop
PASS:		ss:bp	= LICL_vars
		es:di	= Line
		es:si	= Field
RETURN:		carry set if the next line has a usable tabstop
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine is only called to check to see if we can move to the next
	line when the current line ends in a TAB.

	This means that the margins we need to consider are the left and
	right, since the next line will never be a paragraph start.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNextLineHasUsableTab	proc	near
	uses	ax, bx, cx, dx
	.enter
	;
	; If the start of this field is at the start of the line then we
	; don't want to skip to the next line. If we did it would leave this
	; line with no characters on it and that would be bad.
	;
	; We check this by seeing if the field is:
	;	a) First field on line
	;	b) Contains no characters
	; Since the tab is always encountered as the first field on the line
	; the field must be empty. This makes life easy... we just check for
	; it being the first field on the line.
	;
	lea	ax, es:[di].LI_firstField	; ax <- ptr to first field
	cmp	ax, si				; Check for first field on line
	jz	none				; Branch if not first field
	
	;
	; We know that if we move to the next line we won't leave the current
	; line completely empty. Now all we need to do is check to see if
	; there actually is a tabstop on the next line.
	;
	lea	bx, ss:[bp][LICL_theParaAttr+VTPA_tabList]

	mov	ax, LICL_paraAttr.VTPA_leftMargin	; ax <- left margin
	mov	dx, LICL_realRightMargin		; dx <- right margin

	clr	ch					; cx <- # of tabs
	mov	cl, LICL_paraAttr.VTPA_numberOfTabs
	jcxz	checkDefaultsAndOtherStuff		; Branch if no tabs

tabLoop:
	;
	; Make sure the tab actually falls inside the margins
	;
	cmp	ss:[bx].T_position, dx
	ja	checkDefaultsAndOtherStuff
	cmp	ss:[bx].T_position, ax
	ja	found

	add	bx, size Tab				; Check next tab
	loop	tabLoop

checkDefaultsAndOtherStuff:
	;
	; There aren't any *real* tabs on the next line, or an *real* tabs
	; that are within the margins, but there may be a default tab we can
	; use. Heck, we may even be able to use the para-margin, if the left
	; margin is less.
	;
	mov	ax, LICL_paraAttr.VTPA_leftMargin	; ax <- left margin
	cmp	ax, LICL_paraAttr.VTPA_paraMargin	; Check for <para
	jb	found					; Branch if para is tab
	
	;
	; Well, we can't use the para-margin as the tabstop, but we can use
	; a default tab, if one exists.
	;
	call	ChooseDefaultTab			; carry set if tab found
							; Nukes ax, cx, dx
	jc	found					; Jmp if default exists

none:
	;
	; There isn't a tab on the next line that we can use.
	;
	clc						; No usable tabs

done:
	;
	; Carry set if there is a tab on the next line that we can use.
	;
	.leave
	ret


found:
	;
	; There is a tab on the next line that we can use.
	;
	stc						; Has usable tabs
	jmp	done


CheckNextLineHasUsableTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIntrinsicTabWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a tab character of "intrinsic" width can
		fit on this line.

CALLED BY:	FindNextTabStop
PASS:		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
		es:di	= Line
		es:si	= Field
		ax	= End of previous field
RETURN:		carry set if an "intrinsic" tab won't fit
		carry clear otherwise
		   cx	= Tab position
		   al	= Tab anchor
		   ah	= TabAttributes
		   dl	= TabReference
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIntrinsicTabWidth	proc	near
if NO_TAB_IS_RIGHT_MARGIN
;see tlTabUtils.asm for more of this fix
	;
	; attempt better intrinsic tab behavior
	;
	mov	cx, LICL_paraAttr.VTPA_rightMargin
	dec	cx
else
	mov	cx, ax
	add	cx, TAB_INTRINSIC_WIDTH		; cx <- next tab position
endif

	cmp	cx, LICL_realRightMargin
	jae	tooFar

	;
	; The thing fits (fancy that). Set the default tab anchor/attributes.
	;
	mov	ah, TT_LEFT			; ah <- Attributes
	clr	al				; al <- anchor
						;       clears carry too
	mov	dl, OTHER_INTRINSIC_TAB or (TRT_OTHER shl offset TR_TYPE)

done:
	;
	; Carry clear if an intrinsic tab will fit
	;   cx	= Position
	;   al	= Anchor
	;   ah	= TabAttributes
	;   dl	= TabReference
	;
	ret


tooFar:
	;
	; An intrinsic tab doesn't fit. If this is the only character on the
	; line, then there is no way we can word-wrap it. This means that
	; we must use the special "zero-width" tab. 
	;
	mov	cx, ax				; cx <- position of tab
	call	GetLineLeftFromTOCV		; ax <- left edge of line
	cmp	cx, ax				; Check for starting at left
	je	tabOnlyIsTooWide		; Branch if one tab is too wide

	;
	; The tab is not the first thing on the line, go ahead and wrap it.
	;
	stc					; Signal: doesn't fit
	jmp	done

tabOnlyIsTooWide:
	mov	ah, TT_LEFT			; ah <- Attributes
	clr	al				; al <- anchor
						;       clears carry too
	mov	dl, OTHER_ZERO_WIDTH_TAB or (TRT_OTHER shl offset TR_TYPE)
	jmp	done

CheckIntrinsicTabWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddFieldToLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a field to the end of the line.

CALLED BY:	CommonLineCalculate
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars with LICL_addFieldCallback set

		es:di	= Pointer to the line
		cx	= Pointer past the line/field data
		es:dx	= Pointer to the field we want to have

RETURN:		es:di	= Pointer to the line
		cx	= Pointer past the line/field data
		es:dx	= Pointer to the field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddFieldToLine	proc	near
	.enter
	;
	; Check to see if the field doesn't already exist.
	;
	cmp	dx, cx				; Compare ptr to data-end
	jb	quit				; Branch if ptr is before end
	
	;
	; Call the callback to add a field.
	;

if ERROR_CHECK
	;
	;  If not vfptr check if the segment passed is same as current
	;  code segment.  Since it is allowed to pass a fptr to the 
	;  callback if you are calling from the same segment.
	;
FXIP<	push	ax, bx							>
FXIP<	mov	ax, ss:[bp].LICL_addFieldCallback.segment		>
FXIP<	cmp	ah, 0xf0						>
FXIP<	jae	isVirtual						>
FXIP<	mov	bx, cs
FXIP<	cmp	ax, bx							>
FXIP<	ERROR_NE  TEXT_FAR_POINTER_TO_MOVABLE_XIP_RESORCE		>
FXIP<isVirtual:								>
FXIP<	pop	ax, bx							>
endif

	;
	; Validate that the callback is not in a movable code segment
	;
NOFXIP<	call	ss:[bp].LICL_addFieldCallback	; Add me a field	>
FXIP<	push	ax, bx							>
FXIP<	movdw	bxax, ss:[bp].LICL_addFieldCallback			>
FXIP<	call	ProcCallFixedOrMovable					>
FXIP<	pop	ax, bx							>

	;
	; es:di	= Pointer to the line
	; es:dx	= Pointer to the field
	; cx	= Pointer past line/field data
	;

	;
	; If we had to add fields then we clearly have changed the line
	;
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED

quit:
	.leave
	ret
AddFieldToLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TruncateLineAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke any fields after a given position in a line.

CALLED BY:	CommonLineCalculate
PASS:		*ds:si	= Instance ptr
		es:di	= Pointer to the line
		es:dx	= Pointer to the place we want it cut off
		cx	= Pointer past the end of the line/field data
		ss:bp	= LICL_vars
RETURN:		es:di	= Pointer to the line
		cx	= Pointer past the end of the line/field data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TruncateLineAtPosition	proc	near
	uses	dx
	.enter
	add	dx, size FieldInfo
	
	cmp	dx, cx			; Check for perfect size already
	je	quit			; Branch if all is perfect
	
	;
	; Call a callback to handle this stuff.
	;
	push	dx			; Save pointer past end of data
	sub	cx, di			; cx <- size of the line/field data
	sub	dx, di			; dx <- size we want it to be

if ERROR_CHECK
	;
	;  If not vfptr check if the segment passed is same as current
	;  code segment.  Since it is allowed to pass a fptr to the 
	;  callback if you are calling from the same segment.
	;
FXIP<	push	ax, bx							>
FXIP<	mov	ax, ss:[bp].LICL_truncateFieldsCallback.segment		>
FXIP<	cmp	ah, 0xf0						>
FXIP<	jae	isVirtual						>
FXIP<	mov	bx, cs							>
FXIP<	cmp	ax, bx							>
FXIP<	ERROR_NE  TEXT_FAR_POINTER_TO_MOVABLE_XIP_RESORCE		>
FXIP<isVirtual:								>
FXIP<	pop	ax, bx							>
endif

NOFXIP<	call	ss:[bp].LICL_truncateFieldsCallback			>
FXIP<	push	ax, bx							>
FXIP<	movdw	bxax, ss:[bp].LICL_truncateFieldsCallback		>
FXIP<	call	ProcCallFixedOrMovable					>
FXIP<	pop	ax, bx							>
	pop	cx			; Restore pointer past end of data
	
	;
	; If we had to remove fields then we clearly have changed the line
	;
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED

quit:
	.leave
	ret
TruncateLineAtPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewFieldNChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the FI_nChars for a field.

CALLED BY:	FindFieldEnd
PASS:		es:dx	= Field
		ax	= Number of characters in the field
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if FI_nChars changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewFieldNChars	proc	near
	uses	di
	.enter
	mov	di, dx
	cmp	es:[di].FI_nChars, ax
	je	quit

	mov	es:[di].FI_nChars, ax
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	.leave
	ret
SaveNewFieldNChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewFieldPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the new position for a field.

CALLED BY:	CalcFieldPosition
PASS:		es:dx	= Field
		ax	= New position
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if position changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewFieldPosition	proc	near
	uses	di
	.enter
	mov	di, dx				; es:di <- field
	cmp	es:[di].FI_position, ax
	je	quit

	mov	es:[di].FI_position, ax
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	.leave
	ret
SaveNewFieldPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewFieldWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the new width for a field.

CALLED BY:	CalcFieldPosition
PASS:		es:dx	= Field
		ax	= New width
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if position changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewFieldWidth	proc	near
	uses	di
	.enter
	mov	di, dx				; es:di <- field
	cmp	es:[di].FI_width, ax
	je	quit

	mov	es:[di].FI_width, ax
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	.leave
	ret
SaveNewFieldWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewFieldTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the new tab reference for a field.

CALLED BY:	CalcFieldPosition
PASS:		es:dx	= Field
		al	= TabReference
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if position changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewFieldTab	proc	near
	uses	di
	.enter
	mov	di, dx				; es:di <- field
	
	cmp	es:[di].FI_tab, al
	je	quit

	mov	es:[di].FI_tab, al
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	.leave
	ret
SaveNewFieldTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save character count for a line.

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		dl.ax	= Line char count (WordAndAHalf)
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if count changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineCharCount	proc	near
	uses	ax, bx, cx, dx
	.enter
	mov	cx, ax				; bl.cx <- new value
	mov	bl, dl

	CommonLineGetCharCount			; dl.ax <- old value
	
	cmp	cx, ax
	jne	saveNewValue
	cmp	bl, dl
	jne	saveNewValue
quit:
	.leave
	ret

saveNewValue:
	clr	dh
	sub	ax, cx				; dx.ax <- amount of change
	sbb	dl, bl
	sbb	dh, 0
	adddw	ss:[bp].LICL_lineStartChange, dxax

	mov	dl, bl				; dl.ax <- new start
	mov	ax, cx
	CommonLineSetCharCount			; Set new start

	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
	jmp	quit

SaveNewLineCharCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save line-end

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		ax	= End of the line
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if count changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineEnd	proc	near
	.enter
	cmp	ax, es:[di].LI_lineEnd
	jne	saveNewValue
quit:
	.leave
	ret

saveNewValue:
	mov	es:[di].LI_lineEnd, ax
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
	jmp	quit

SaveNewLineEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save new flags for a line.

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		ax	= LineFlags
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if flags changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineFlags	proc	near
	uses	dx
	.enter
	;
	; Always clear the "needs calc" bit, since we calculated the line.
	;
	and	es:[di], not mask LF_NEEDS_CALC

	;
	; Now check the new flags against the old ones, not counting the
	; "needs calc" or "needs draw" flags.
	;
	mov	dx, es:[di].LI_flags
	and	dx, not (mask LF_NEEDS_DRAW or mask LF_NEEDS_CALC)

	cmp	dx, ax
	je	quit

	;
	; Set the flags in ax, preserving the "needs draw" bit.
	;
	mov	dx, es:[di].LI_flags
	and	dx, mask LF_NEEDS_DRAW
	or	ax, dx

	mov	es:[di].LI_flags, ax
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	.leave
	ret
SaveNewLineFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save new height for a line.

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		dx.ah	= Height
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if height changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineHeight	proc	near
	cmpwbf	es:[di].LI_hgt, dxah
	je	quit

	;
	; Compute the difference in height and use it to update the "inserted
	; space" field of the LICL_vars.
	;
	push	ax, dx, cx
	subwbf	dxah, es:[di].LI_hgt		; dx.ah <- amount taller
	clr	al				; dx.ax <- amount taller
	
	clr	cx				; cx.dx.ax <- amount taller
	tst	dx				; Unless of course dx is <0
	jns	gotChange			; In which case we sign-extend
	dec	cx				; cx <- 0xffff
gotChange:
	adddwf	ss:[bp].LICL_insertedSpace, cxdxax
	
	addwbf	es:[di].LI_hgt, dxah
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
	pop	ax, dx, cx
quit:
	ret
SaveNewLineHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineBLO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save new baseline for a line.

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		dx.ah	= baseline
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if height changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineBLO	proc	near
	cmpwbf	es:[di].LI_blo, dxah
	je	quit

	movwbf	es:[di].LI_blo, dxah
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	ret
SaveNewLineBLO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineAdjustment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save new adjustment for a line.

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		ax	= Adjustment
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if adjustment changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineAdjustment	proc	near
	cmp	es:[di].LI_adjustment, ax
	je	quit
	
	mov	es:[di].LI_adjustment, ax
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	ret
SaveNewLineAdjustment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineSpacePad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save new space padding for a line.

CALLED BY:	CommonLineCalculate
PASS:		es:di	= Line
		dx.ah	= Space padding
		ss:bp	= LICL_vars
RETURN:		LICL_calcFlags w/ CF_LINE_CHANGED bit set if padding changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineSpacePad	proc	near
	cmpwbf	es:[di].LI_spacePad, dxah
	je	quit

	movwbf	es:[di].LI_spacePad, dxah
	or	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
quit:
	ret
SaveNewLineSpacePad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewFieldValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save values computed for a field in the FieldInfo structure

CALLED BY:	FindFieldEnd
PASS:		*ds:si	= Instance ptr
		es:dx	= Field
		es:di	= Line
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewFieldValues	proc	near
	uses	ax
	.enter
	;
	; FI_position has been set already
	;

	;
	; Set FI_tab		** Problem **
	;
	mov	al, ss:[bp].LICL_tabReference
	call	SaveNewFieldTab

	;
	; Set FI_width
	;
	rndwbf	ss:[bx].TOCV_ext.TOCE_fieldWidth, ax
	call	SaveNewFieldWidth
	
	;
	; Set FI_nChars
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_nChars
	call	SaveNewFieldNChars
	.leave
	ret
SaveNewFieldValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveNewLineValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save values computed for a line in the LineInfo structure

CALLED BY:	FindFieldEnd
PASS:		*ds:si	= Instance ptr
		es:dx	= Field
		es:di	= Line
		ss:bp	= LICL_vars
		ss:bx	= TOC_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveNewLineValues	proc	near
	class	VisTextClass
	uses	ax, dx
	.enter
	;
	; Save LI_hgt
	;
	movwbf	dxah, ss:[bx].TOCV_ext.TOCE_lineHeight
	call	SaveNewLineHeight
	
	;
	; Save LI_blo
	;
	movwbf	dxah, ss:[bx].TOCV_ext.TOCE_lineBLO
	call	SaveNewLineBLO
	
	;
	; Save LI_flags
	;
	mov	ax, ss:[bx].TOCV_ext.TOCE_lineFlags

	;
	; For small objects, we map LF_ENDS_IN_COLUMN_BREAK and
	; LF_ENDS_IN_SECTION_BREAK to LF_ENDS_IN_CR so that things will
	; hopefully just work.
	;
	test	ax, mask LF_ENDS_IN_COLUMN_BREAK or \
		    mask LF_ENDS_IN_SECTION_BREAK
	jz	saveFlags
	
	push	di
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	pop	di
	jnz	saveFlags			; Branch if it's large
	
	;
	; It's a small object, re-map the flags.
	;
	and	ax, not (mask LF_ENDS_IN_COLUMN_BREAK or \
			 mask LF_ENDS_IN_SECTION_BREAK)
	or	ax, mask LF_ENDS_IN_CR
saveFlags:
	call	SaveNewLineFlags
	.leave
	ret
SaveNewLineValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckConsecutiveHyphenatedLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks whether or not the maximum number of consecutive lines
		to hyphenate happened before this line.

CALLED BY:	CalculateHyphenCallback
PASS:		ds:si = instance ptr
		ss:bx = pointer to LICL_vars on stack
RETURN:		cx = zero if too many consecutive hyphenated lines
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/ 9/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckConsecutiveHyphenatedLines	proc	near
	uses	bx, di, ax
	.enter

	; 
	; Get the maximum number of lines to hyphenate in cx. 
	;
	push	bx
	mov	bx,ss:[bx].LICL_theParaAttr.VTMPA_paraAttr.VTPA_hyphenationInfo
	mov	cl, offset VTHI_HYPHEN_MAX_LINES	; cl = amount to shift
	shr	bx, cl					; cx=bx=max consecutive
	mov	cx, bx					;  lines to hyphenate-1
	inc	cx					; cx = max lines to hyp
	pop	bx

	;
	; If we're on the first line of the text, can't be too many lines. 
	;
	movdw	axdi, ss:[bx].LICL_line		; bx:di = current line #
	mov	bx, ax
	tstdw 	bxdi
	jz	notTooMany			; first line, OK

	;
	; loop backwards through #cx previous lines, if they're all 
	; auto-hyphenated then return 0. Any other case -> return 1.
	;
lineLoop:
	decdw	bxdi				; go to previous line
	call	TL_LineGetFlags			; ax = LineFlags
	test	ax, mask LF_ENDS_IN_AUTO_HYPHEN
	jz	notTooMany			; no auto-hyphen -> OK
	test	ax, mask LF_STARTS_PARAGRAPH
	jnz	lastLineCheck			; last line to check, exit loop
	tstdw	bxdi
	jz	lastLineCheck			; last line to check, exit loop
	dec	cx
	jnz	lineLoop			; if more lines to test, loop
tooMany:
	clr	cx				; else return - too many lines
lineLoopEnd:

	.leave
	ret
notTooMany:
	mov	cx, 1
	jmp 	lineLoopEnd
lastLineCheck:
	cmp	cx, 1
	je	tooMany
	jmp	notTooMany
CheckConsecutiveHyphenatedLines	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHyphenationPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets di to a position in the word such that if it's broken
		there the hyphen will still fit on the line. Determines if
		hyphenation is possible. 

CALLED BY:	CalculateHyphenCallback
PASS:		ds:si 	= instance
		di	= position of char that overflowed the line
		ss:bp	= pointer to TOC_vars on stack
		ss:bx 	= pointer to LICL_vars on stack

RETURN:		cx:di 	= position of char where hyphenation should be tried
		ax 	= 0 if hyphen will not fit, nonzero if it might
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	;
	; We need to check the word break position, and see whether
	; a hyphen would fit before the border.  
	;
	; If a hyphen fits, we return di unchanged
	;
	; Otherwise if there are more characters in the current word and 
	; before the current break position we decrement the break position
	; until the hyphen will fit, returning that position as di. If we 
	; run out of characters in the word and the hyphen still won't fit, 
	; we can't hyphenate. 
	;

		Assumption: the character at cx:di is not the first
		character in the word.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/13/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetHyphenationPosition	proc	near
			class	VisTextClass
	uses	bx,cx,dx,si,bp
	overflowPos	local	word	push di
	.enter

	mov	di, ss:[bp]			; ss:di -> TOC_vars 

hyphenFitLoop: 
	mov	ax, overflowPos
	push	bp
	mov	bp, di
	call	CheckHyphenFits			; carry clear if hyphen fits
	pop	bp
	jnc	offsetOK

	;
	; Hyphen doesn't fit on the line yet. Check if there are still
	; at least two more characters in the word (min prefix to hyphenate). 
	; If not, return and signal no hyphenation. 
	;
	mov	ax, overflowPos
	sub	ax, 2				; axbx= pos two before overflow
	cmp	ax, ss:[di].TOCV_int.TOCI_lastWordStart
	jle	noHyphen

	; 
	; We can try breaking the word at an earlier character position. 
	; 
	dec	overflowPos			; overflowPos = previous char
	jmp	hyphenFitLoop

exit:
	.leave
	ret
noHyphen:
	;
	; The word cannot be hyphenated. Signal that, and return. 
	;
	clr	ax
	jmp	exit
offsetOK:
	;
	; The hyphen will fit on the line with the passed break position. 
	; return with di unchanged and try to hyphenate.
	;
	mov	di, overflowPos
	mov	ax, 1
	jmp 	exit
SetHyphenationPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHyphenFits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests the returned hyphen position to make sure that the
		hyphen fits on the line. 

CALLED BY:	SetHyphenationPosition, CalculateHyphenCallback
PASS:		ds:si 	= instance
		ax	= position of returned hyphen to check
		ss:bp	= pointer to TOC_vars on stack
		ss:bx 	= pointer to LICL_vars on stack
RETURN:		carry clear if hyphen fits, else carry is set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TJ	11/18/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHyphenFits	proc	near
	class	VisTextClass
	uses	es, di, cx, ax, dx
	.enter
	
	;
	; First we get the distance from the start of the field to the hyphen
	; position. We do this by calling CommonFieldTextPosition, which will
	; also set the right font and stuff for calling GrCharWidth later.
	;

	push	di

	; 
	; Param: set es:di -> current field	
	;
	movdw	esdi, ss:[bx].LICL_linePtr
	mov	di, ss:[bx].LICL_fieldPtr

	;
	; Param on stack: push offset to start of field
	;
	movdw	cxdx, ss:[bx].LICL_range.VTR_start ; offset to start of field 
	cmp	ss:[bx].LICL_tabReference, RULER_TAB_TO_LINE_LEFT  
	je	gotOffset		; If field starts with tab, skip tab
	incdw	cxdx				; Advance past TAB
gotOffset:
	pushdw	cxdx				; push start offset parameter

	;
	; Param on stack: push offset of character in the field
	;
	clr	cx				; cxdx = position of last
	mov	dx, ax				;        char in the field
	cmp	ss:[bx].LICL_tabReference, RULER_TAB_TO_LINE_LEFT  
	je	gotPosition			; if skipped tab, dec char pos.
	decdw	cxdx				; One less character
gotPosition:
	pushdw	cxdx			; this is the constraint that will be
					; used => pixel offset will be found.

	;
	; Param on stack: push pixel offset to find
	;
	mov	cx, 0x7fff			; pixel offset = big number
	push	cx				; push param

	;
	; Param on stack: push space padding
	;
	clrdw	cxdx				; space padding (none)
	pushdw	cxdx				; push param

	call	CommonFieldTextPosition		; ax = text offset
						; cx = pixel offset

	pop	di

	;
	; cx = the pixel distance to the pre-overflow character. We subtract
	; this from TOCE_areaToFill to get the space remaining on the line.
	;
	mov	dx, ss:[bp].TOCV_ext.TOCE_areaToFill	; dx = offset to border
	sub	dx, cx				; dx = dist last char to border
	mov	cx, dx				; cx = dist last char to border

	;
	; Get the hyphen width
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate	; di = handle to gstate
	mov	ax, C_HYPHEN	
	call	GrCharWidth		; dx.ah = width of hyphen
	inc	dx			; add one pixel to avoid writing over
					; the margin line itself
	mov	ax, dx			; ax = hyphen width

	; 
	; Now see if the hyphen fits.
	;
	cmp	cx, ax				; is there room for the hyphen?
	jge	offsetOK			; yes, clear carry  and exit
	stc					; else set carry and exit
exit:
	.leave
	ret
offsetOK:
	clc
	jmp	exit
CheckHyphenFits	endp


TextLineCalc		ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextCalcMinWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the maximum word width within a given piece of text

CALLED BY:	GLOBAL (the browser)
PASS:		*ds:si	= Instance ptr
		dxax	= range start
		cx	= number of characters
RETURN:		ax	= minimum width
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	8/26/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
;;; NOTE: THIS ROUTINE DOES NOT WORK YET
;;; It is partially completed in case it ever is needed for the browser


TextObscure	segment resource

VisTextCalcMinWidth	proc	far	uses si, di, ds
	clr		bx
position	local	dword	push dx, ax
object		local	optr	push ds, si
numToCheck	local	word	push cx
numThisBlock	local	word
maxWidth	local	word	push	bx
skippingWhite	local	word
gstate		local	word	push	bx, bx
gstateValidCount local	dword
	.enter

	call	TextGStateCreate
	call	T_GetVMFile			; bx = file
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = instance data
	mov	ax, ds:[di].VTI_gstate
	mov	gstate, ax
	mov	di, ds:[di].VTI_text		; di = vm block
	call	HugeArrayLock			; ds:si = data

	; ds:si = text
	; ax = # characters in this block

blockLoop:
	cmp	ax, numToCheck
	jb	10$
	mov	ax, numToCheck
10$:
	mov	numThisBlock, ax
	sub	numToCheck, ax
	mov	wordStart, si
	mov	skippingWhite, TRUE

charLoop:
	tstdw	gstateValidCount
	jnz	15$
	call	updateGState
15$:
	lodsb
	cmp    al, C_SPACE
	jz     wordEnd
	cmp    al, C_CR
	jz     wordEnd

	; character is not a word end -- if we are skipping white space,
	; store this as the start of the word

	tst	skippingWhite
	jz	nextChar
	mov	skippingWhite, FALSE
	mov	wordStart, si
	dec	wordStart
	jmp	nextChar

wordEnd:
	tst	skippingWhite
	jnz	nextChar

	; at the end of a word, calculate width for the word

	push	si
	sub	si, wordStart
	mov	cx, si
	mov	si, wordStart
	call	GrTextWidth
	pop	si
	cmp	dx, maxWidth
	jbe	30$
	mov	maxWidth, dx
30$:
	mov	skippingWhite, TRUE

nextChar:
	dec	numThisBlock
	jnz	charLoop

	tst	numToCheck
	jz	done
	dec	si
	call	HugeArrayNext
	jmp	blockLoop

done:
	call	HugeArrayUnlock
	movdw	dssi, object
	call	TextGStateDestroy
	mov	ax, maxWidth
	.leave
	ret

updateGState:
	push	si, bp, ds
	movdw	dssi, object
	movdw	dxax, position


	sub	sp, size VisTextCharAttr
	mov	bp, sp

	mov	cl, GSFPT_MANIPULATION		;get charAttr to the right
	call	TA_GetCharAttrForPosition
	pushdw	dxax				;save count

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_gstate

	; set the font and point size

	mov	cx, ss:[bp].VTCA_fontID
	mov	dx, ss:[bp].VTCA_pointSize.WBF_int
	mov	ah, ss:[bp].VTCA_pointSize.WBF_frac
	call	GrSetFont

	; set the text charAttr

	mov	al, ss:[bp].VTCA_textStyles
	mov	ah, 0xff
	call	GrSetTextStyle

	; set the track kerning
	mov	ax, {word} ss:[bp].VTCA_trackKerning
	call	GrSetTrackKern

	popdw	dxax			; count
	add	sp,size VisTextCharAttr
	pop	si, bp, ds
	movdw	gstateValidCount, dxax
	retn
	
VisTextCalcMinWidth	endp

TextObscure ends

endif
