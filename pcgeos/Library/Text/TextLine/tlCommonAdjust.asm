COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlCommonAdjust.asm

AUTHOR:		John Wedgwood, Jan  2, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 2/92	Initial revision

DESCRIPTION:
	Adjust lines after a change.

	$Id: tlCommonAdjust.asm,v 1.1 97/04/07 11:20:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineAdjustForReplacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a line after a replacement.

CALLED BY:	SmallLineAdjustForReplacement, LargeLineAdjustForReplacement
PASS:		es:di	= Pointer to the line to update
		cx	= Size of the line and fields
		ss:bp	= VisTextReplaceParameters
		dx.ax	= Offset to the start of the line
RETURN:		dx.ax	= Offset to the start of the next line
		carry set if we can quit updating
		carry clear otherwise
		    zero clear (nz) if the line is before the affected area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The right thing depends on the situation. There are a few
	situations that must be handled:
		1) Line falls before range
				     |---range---|
			|---line---|
			Test:	(line.end < range.start)
			Action:	nothing
		
		2) Line crosses range start
					|---range---|
			|------line--------|
			Test:	(line.start < range.start) &&
				(line.end   >= range.start)
			Action:	line.count = range.start - line.start + insCount
				Mark line as needing recalc

		3) Line is contained in range
			|-----range-----|
			   |-line-|
			Test:	(line.start > range.start) &&
				(line.end   < range.end)
			Action:	line.count = 0
				Mark line as needing recalc

		4) Line contains range
			   |-range-|
			|------line--------|
			Test:	(line.start <= range.start) &&
				(line.end   >= range.end)
			Action:	line.count += (range.start - range.end) + insCnt
				Mark line as needing recalc
				quit

		5) Line crosses range end
			|-------range------|
				|------line--------|
			Test:	(line.start >= range.start) &&
				(line.start <= range.end)   &&
				(line.end > range.end)
			Action:	line.count = line.end - range.end
				Mark line as needing recalc
				quit

		6) Line falls after the range
			|---range---|
					|------line--------|
			Test:	(line.start > range.end)
			Action:	nothing
				quit
---------------------------------------------------------------------------
	line.end = line.start + line.nChars
	
	if (line.end < range.start) {
	    /* Case (1) */
	    retVal = continue
	} else if (line.start >= range.end) {
	    /* Case (6) */
	    retVal = quit
	} else if (line.start < range.start) {
	    /* Case (2) or (4) */
	    if (line.end >= range.end) {
	    	/* Case (4) */
		line.count = line.count - (range.end - range.start) + insCount
		line.flags |= recalc
		retVal = quit
	    } else {
	        /* Case (2) */
		line.count = range.start - line.start + insCount
		line.flags |= recalc
		retVal = continue
	    }
	} else {
	    /* Case (3) or (5) */
	    if (line.end >= range.end) {
	        /* Case (5) */
		line.count = line.end - range.end
		line.flags |= recalc
		retVal = quit
	    } else {
	        /* Case (3) */
		line.count = 0
		line.flags |= recalc
		retVal = continue
	    }
	}
	
	line.start = line.end		/* Set up for next call */
	return(retVal)			/* Return "continue" value */

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineAdjustForReplacement	proc	near
	uses	bx, cx, si
	.enter
	;
	; Compute the offset to the end of the line
	;
	movdw	cxsi, dxax			; cx.si <- line end
	add	si, es:[di].LI_count.WAAH_low
	adc	cl, es:[di].LI_count.WAAH_high
	adc	ch, 0
	
	;
	; Check for the easy stuff... Line before start of range.
	; dx.ax	= Start of range
	; cx.si	= End of range
	;
	cmpdw	cxsi, ss:[bp].VTRP_range.VTR_start
	jb	quitBeforeRange			; Branch if line before range
	jne	lineInRange
	
	;
	; The line-end is right at the start of the affected range. If the
	; line ends a paragraph and does not end in NULL then we consider
	; this line to be before the affected range.
	;
	test	es:[di].LI_flags, mask LF_ENDS_PARAGRAPH 
	jnz	checkEndsInNull
	
	;
	; The line does not end a paragraph, therefore there is another line.
	; We need to do the adjustment on the next line, but we need to
	; recalculate on this line just in case.
	;
	or	es:[di].LI_flags, mask LF_NEEDS_CALC
	clr	bx				; z = 1, is affected
						; c = 0, not finished
	jmp	quitSkipUpdate

checkEndsInNull:
	test	es:[di].LI_flags, mask LF_ENDS_IN_NULL
	jz	quitBeforeRange

lineInRange::
	cmpdw	dxax, ss:[bp].VTRP_range.VTR_end
	ja	abortSkipUpdate			; Branch if line after range
	
	;
	; Now for the harder stuff... In all cases we need to mark the line
	; as needing recalc.
	;
	or	es:[di].LI_flags, mask LF_NEEDS_CALC

	cmpdw	dxax, ss:[bp].VTRP_range.VTR_start
	jbe	case2or4
	
	;
	; Cases 3 or 5
	;
	cmpdw	cxsi, ss:[bp].VTRP_range.VTR_end
	jae	case5
	
	;
	; Case 3
	;
	clrdw	dxax
	;;; Fall thru to quitContinueIsAffected

quitContinueIsAffected:
	clr	bx				; z = 1, after affected range
						; c = 0, continue

quit:
	;
	; Carry set if we can quit adjusting lines now.
	; Zero set if the line falls before the affected range.
	; dx.ax = new line count
	; si.cx	= Start for next line
	; 
	; Set the line-start for the next line. Don't affect the carry.
	;
	mov	es:[di].LI_count.WAAH_low, ax	; Save new line count
	mov	es:[di].LI_count.WAAH_high, dl

quitSkipUpdate:
	movdw	dxax, cxsi			; Return next line start
	.leave
	ret


quitBeforeRange:
	or	bx, 1				; z = 0, before affected range
						; c = 0, continue
	jmp	quitSkipUpdate


abortSkipUpdate:
	stc
	jmp	quitSkipUpdate


case5:
	movdw	dxax, cxsi
	subdw	dxax, ss:[bp].VTRP_range.VTR_end


quitAbort:
	stc					; Signal: no more updates
	jmp	quit


case2or4:
	cmpdw	cxsi, ss:[bp].VTRP_range.VTR_end
	jae	case4
	
	;
	; Case 2
	;
	subdw	dxax, ss:[bp].VTRP_range.VTR_start
	negdw	dxax
	adddw	dxax, ss:[bp].VTRP_insCount
	jmp	quitContinueIsAffected


case4:
	clr	dh				; dx.ax <- old count
	mov	dl, es:[di].LI_count.WAAH_high
	mov	ax, es:[di].LI_count.WAAH_low
	
	subdw	dxax, ss:[bp].VTRP_range.VTR_end
	adddw	dxax, ss:[bp].VTRP_range.VTR_start
	adddw	dxax, ss:[bp].VTRP_insCount
	jmp	quitAbort

CommonLineAdjustForReplacement	endp


Text	ends
