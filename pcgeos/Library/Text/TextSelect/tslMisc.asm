COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslMisc.asm

AUTHOR:		John Wedgwood, Nov 22, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/22/91	Initial revision

DESCRIPTION:
	Misc stuff from the old version of textSelect.asm

	$Id: tslMisc.asm,v 1.1 97/04/07 11:20:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_ConvertOffsetToRegionAndCoordinate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an address to a coordinate.

CALLED BY:	EditHilite, SelectGetCursorCoord, TextCallShowSelection,
		VisTextScrollOneLine

PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset into text stream
RETURN:		ax	= Region
		cx	= X pos as offset from left edge of line
		dx	= Y pos as offset from top of associated region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_ConvertOffsetToRegionAndCoordinate	proc	far
	uses	bx, di, bp
	.enter
	;
	; If the position passed could be the end of one line or the start of
	; the next we want to be at the start of the next line.
	;
	clc					; Use second line
	call	TL_LineFromOffset		; bx.di <- Line

	call	TR_RegionFromLine		; cx <- region

	push	cx				; Save region
	push	dx, ax, bx			; Save offset, line.low
	call	TL_LineToPosition		; dx <- Top of line
						; cx <- Left of line
	
	mov	bp, dx				; bp <- 16 bit Y position
	pop	dx, ax, bx			; Restore offset, line.low

	push	cx				; Save left edge of line
	push	bp				; Save y position
	mov	bp, 0x7fff			; Compute forever
	call	TL_LineTextPosition		; bx <- Pixel offset (X position)
	mov	cx, bx				; cx <- Pixel offset (X position)
	pop	dx				; dx <- Y position
	pop	bp				; bp <- left edge of line
	pop	ax				; ax <- Region
	
	add	cx, bp				; cx <- *real* left edge
	.leave
	ret
TSL_ConvertOffsetToRegionAndCoordinate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a range of characters.

CALLED BY:	DrawHilite, DrawOverstrikeModeHilite, UpdateSelectedArea(2)

PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start selection
		cx.bx	= Offset to end selection
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertRange	proc	far
	uses	ax, bx, cx, dx, bp

	push	di
	mov	di, 1500
	call	ThreadBorrowStackSpace
	push	di

	.enter
	;
	; Allocate and initialize the TextRegionEnumParameters frame.
	;
	sub	sp, size TextRegionEnumParameters
	mov	bp, sp
	
	movcb	ss:[bp].TREP_callback, InvertRangeCallback
	clr	ss:[bp].TREP_flags

	;
	; Order the passed offsets
	;
	cmpdw	dxax, cxbx			; We want dx.ax < cx.bx
	jbe	ordered
	xchgdw	dxax, cxbx
ordered:

	;
	; Save the offsets into the stack frame.
	;
	movdw	ss:[bp].TREP_charRange.VTR_start, dxax
	movdw	ss:[bp].TREP_charRange.VTR_end,   cxbx

	;
	; Figure the range of lines covered
	;
	pushdw	dxax				; Save start of range
	movdw	dxax, cxbx			; dx.ax <- offset to range end
	stc					; Use first line if at end
	call	TL_LineFromOffset		; bx.di <- end line
	movdw	ss:[bp].TREP_selectLines.VTR_end, bxdi

	popdw	dxax				; dx.ax <- offset to range start
	clc					; Use second line if at end
	call	TL_LineFromOffset		; bx.di <- start line
	movdw	ss:[bp].TREP_selectLines.VTR_start, bxdi
	
	;
	; Invert the range of lines
	;
	call	TR_RegionEnumRegionsInClipRect
	
	;
	; Restore the stack.
	;
	add	sp, size TextRegionEnumParameters

	.leave

	pop	di
	call	ThreadReturnStackSpace
	pop	di

	ret
InvertRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertRangeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for inverting a range of a document.

CALLED BY:	InvertRange via TR_RegionEnumRegionsInClipRect
PASS:		*ds:si	= Instance
		ss:bp	= TextRegionEnumParameters
RETURN:		carry set if we can abort
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/29/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertRangeCallback	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter
	;
	; Quick Check #1:
	;	If the first line of the region is after the end of the
	;	range of selected lines we can totally quit.
	;
	; NOTE: This used to branch to abort instead on quitContinue
	; Changed 8/26/99 by Tony.  Just because this region is completely
	; after the selection does not mean that are visible regions
	; are (in the browser case)
	;
	movdw	dxax, ss:[bp].TREP_regionFirstLine
	cmpdw	dxax, ss:[bp].TREP_selectLines.VTR_end
	LONG ja	quitContinue
	
	;
	; Quick Check #2:
	;	If the last line of the region is before the start of the
	;	range of selected lines, we can skip this call.
	;
	adddw	dxax, ss:[bp].TREP_regionLineCount
	cmpdw	dxax, ss:[bp].TREP_selectLines.VTR_start
	LONG jbe quitContinue

;-----------------------------------------------------------------------------
	;
	; Well... it appears that some part of the selection does indeed fall
	; in this region, so we actually have to do some work.
	;
	
	;
	; Transform the gstate for this region.
	;
	mov	cx, ss:[bp].TREP_region		; cx <- region
	clr	dl				; No flags
	call	TR_RegionTransformGState	; Transform to new region

	;
	; Make a stack frame for LineInfoCalcLine
	;
	mov	bx, bp				; ss:bx <- TREP values
	sub	sp, size LICL_vars		; ss:bp <- LICL values
	mov	bp, sp
	
	;
	; Save the current region.
	;
	mov	ss:[bp].LICL_region, cx

	;
	; Signal that we don't have valid paragraph attributes.
	;
	movdw	ss:[bp].LICL_theParaAttrStart, -1

	call	SetupCharacterAndLineRanges
	
	;
	; ss:bp	= LICL_vars w/
	;		paragraph attributes set reasonable
	;		LICL_range = character range to invert
	;		LICL_lineStart set
	; bx.di	= First line to invert
	; dx.ax	= Last line to invert
	;
	cmpdw	bxdi, dxax			; Compare start/end line
EC <	ERROR_A	TEXT_INVERT_RANGE_START_PAST_END_SHOULD_NOT_BE_POSSIBLE	>
	je	invertRange			; Branch if same

invertLoop:
	;
	; *ds:si= Instance ptr
	; bx.di	= Current line
	; ss:bp	= LICL_vars with LICL_range filled in
	; dx.ax	= Line to stop inverting on
	;
	movdw	ss:[bp].LICL_line, bxdi		; Save line to invert on
	call	TL_LineInvertRange		; Invert this line

	pushdw	dxax				; Save line to stop at
	call	TL_LineGetCharCount		; dx.ax <- # chars on this line
	adddw	ss:[bp].LICL_lineStart, dxax	; Update the line start
	popdw	dxax				; Restore line to stop at

	call	TL_LineNext			; bx.di <- next line
EC <	ERROR_C	TEXT_INVERT_RANGE_NO_NEXT_LINE				>

	clrdw	ss:[bp].LICL_range.VTR_start	; Invert from start of next line

	cmpdw	bxdi, dxax			; Check for on last line
	jne	invertLoop			; Loop if not

;-----------------------------------------------------------------------------
invertRange:
	;
	; *ds:si= Instance ptr
	; bx.di	= line to invert on
	; ss:bp	= LICL_vars
	; LICL_vars with LICL_range.VTR_start set to zero or else the start
	;	of the range to invert for this line.
	;
	movdw	ss:[bp].LICL_line, bxdi		; Save line to invert on
	call	TL_LineInvertRange		; Invert to the end
	
	add	sp, size LICL_vars		; Restore stack

quitContinue:
	clc					; Signal: Keep processing

;;;quit:
	.leave
	ret

;----------

;;;abort:
;;;	stc					; Signal: Stop processing
;;;	jmp	quit
InvertRangeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupCharacterAndLineRanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the character and line-ranges associated with the
		LICL_vars so that they accurately reflect the portion of
		the selection which falls in the current region.

CALLED BY:	InvertRangeCallback
PASS:		ss:bx	= TREP vars
		ss:bp	= LICL_vars
RETURN:		LICL_range set to the character range within the current region.
		bx.di	= First line to invert on
		dx.ax	= Last line to invert on
		LICL_lineStart set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/29/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupCharacterAndLineRanges	proc	near
	.enter
;-----------------------------------------------------------------------------
;		 Set up Character Range (LICL_range)
;-----------------------------------------------------------------------------
	;
	; Set the character-range start to the maximum of the range-start
	; and the region-start.
	;
	movdw	dxax, ss:[bx].TREP_regionFirstChar
	cmpdw	dxax, ss:[bx].TREP_charRange.VTR_start
	jae	gotRangeStart
	movdw	dxax, ss:[bx].TREP_charRange.VTR_start
gotRangeStart:
	movdw	ss:[bp].LICL_range.VTR_start, dxax
	
	;
	; Set the character-range end to the minimum of the range-end
	; and the region-end.
	;
	movdw	dxax, ss:[bx].TREP_regionFirstChar
	adddw	dxax, ss:[bx].TREP_regionCharCount
	cmpdw	dxax, ss:[bx].TREP_charRange.VTR_end
	jbe	gotRangeEnd
	movdw	dxax, ss:[bx].TREP_charRange.VTR_end
gotRangeEnd:
	movdw	ss:[bp].LICL_range.VTR_end, dxax

;-----------------------------------------------------------------------------
;		 Set up Line Range (LICL_line / dxax)
;-----------------------------------------------------------------------------
	;
	; Set the line-range start to the maximum of the range-star
	; and the region-start.
	;
	movdw	dxax, ss:[bx].TREP_regionFirstLine
	cmpdw	dxax, ss:[bx].TREP_selectLines.VTR_start
	jae	gotLineRangeStart
	movdw	dxax, ss:[bx].TREP_selectLines.VTR_start
gotLineRangeStart:
	movdw	ss:[bp].LICL_line, dxax
	
	;
	; Set the line-range end to the minimum of the range-end
	; and the region-end.
	;
	movdw	dxax, ss:[bx].TREP_regionFirstLine
	adddw	dxax, ss:[bx].TREP_regionLineCount
	decdw	dxax				; dx.ax <- last line in region
	cmpdw	dxax, ss:[bx].TREP_selectLines.VTR_end
	jbe	gotLineRangeEnd
	movdw	dxax, ss:[bx].TREP_selectLines.VTR_end
gotLineRangeEnd:

	;
	; Set stuff up for return...
	;
	movdw	bxdi, ss:[bp].LICL_line
	
	pushdw	dxax
	call	TL_LineToOffsetStart		; dx.ax <- line start
	movdw	ss:[bp].LICL_lineStart, dxax
	popdw	dxax
	.leave
	ret
SetupCharacterAndLineRanges	endp

TextFixed	ends
