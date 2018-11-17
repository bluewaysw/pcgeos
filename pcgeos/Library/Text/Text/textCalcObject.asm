COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textCalcObject.asm

AUTHOR:		John Wedgwood, Oct 26, 1989

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/26/89	Initial revision

DESCRIPTION:

	$Id: textCalcObject.asm,v 1.1 97/04/07 11:18:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

TextFixed segment resource

AssertIsLargeObject	proc	far
	class	VisTextClass

	pushf
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	ERROR_Z	VIS_TEXT_REQUIRES_LARGE_TEXT_OBJECT
	pop	di
	popf
	ret
AssertIsLargeObject	endp

TextFixed ends

endif

;-----------

Text	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a single object.

CALLED BY:	TextRecalcInternal
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_var structure with:
				LICL_range set
				LICL_startPos set
		bx.di	= Line to start calculating from
		cx	= Flags for previous line
RETURN:		LICL_vars filled in
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateObject	proc	near
	.enter

	; Mark this object as dirty

	call	ObjMarkDirty
	;
	; Do some stack frame initialization.
	;
	mov	ss:[bp].LICL_calcFlags, mask CF_SAVE_RESULTS
	movdw	LICL_paraAttrStart, -1		; Force init of paraAttr
	mov	ss:[bp].LICL_linesToDraw, 0

	;
	; cx	= Flags for previously calculated line
	; bx.di	= Line to start calculating at
	; ss:bp	= LICL_vars initialized correctly
	;
	call	CalculateRegions		; Calculate the regions
	
	call	ObjMarkDirty			; Dirty the text object

EC <	call	ECCheckParaAttrPositions				>
BEC <	call	CheckRunPositions					>
	.leave
	ProfilePoint 7
	ret
CalculateObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateRegions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate as many regions as we need to region

CALLED BY:	CalculateObject
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars initialized correctly
		cx	= Flags for previous line
		bx.di	= Line to start calculating at
RETURN:		carry set if there is more calculating to do in the next region
		LICL_firstLine* set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
*****************************************************************************
At each breaking point it would be nice to have the region heights for the
entire object be up to date. The problem with this is that doing partial
updates isn't really reasonable since an update implies that you may be doing
a BitBlt on an area of the screen. We would like to minimize these operations
where possible.

So we try something else. That is to make sure that at each break point
the current region is entirely up to date. We keep track of the amount
of change to the next region so that when we start on that region we can
do an update and be back in the "home" position with the current region
up to date and the keeping track of the information for the next region.

The information we need for the next region is the amount of text that has
been pulled from it or pushed into it.

This is accumulated by adding up the heights of lines from that region which
are computed in the context of the current region. This includes lines which
actually come from regions beyond the next one.

The height of a region is defined as its original height plus any accumulated
change from calculating that region.

All height updates happen when stuff is rippled so that we can isolate these
routines along with the other code which ripples text and lines.

A breaking point is any change in the current segment or the current region.

There is a bit of additional code which looks like:
	if (line is from later region) {
	    nextRegionChange -= lineHeight
	    regionChange += lineHeight
	}

This is executed before calculation on that line has occurred. If it turns
out that the line does not belong in the current region, then the value
of nextRegionChange is modified to handle the change in the line height:
	nextRegionChange += newLineHeight
	regionChange -= newLineHeight

When a break is encountered, the current region is updated (possibly by
BitBlt) to account for any insert/delete of space within the current
region.

When we move to a new region, if space has been removed (nextRegionChange
is less than zero) then regionChange is set to the lesser of the old
calculated region height and the nextRegionChange. NextRegionChange is set
to the remainder.

If space has been inserted, nextRegionChange is zero and the regionChange
is set to indicate the inserted space.
*****************************************************************************

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateRegions	proc	near
	class	VisTextClass
	ProfilePoint 50
	uses	ax, bx, cx, dx, di
	.enter
EC <	call	ECValidateRegionAndLineHeights		>
EC <	call	ECValidateRegionCounts			>
	;
	; Cache a few values into the LICL_vars so we don't need to make
	; significant calls in order to use them.
	;
	call	GetCachedValues

	;
	; Compute the bottom of the previous line and the region in which
	; to start calculating.
	;
	ProfilePoint 51
	call	CalcLineBottomAndRegion

	clr	ax
	clrdwf	ss:[bp].LICL_rippleHeight, ax
	clrdw	ss:[bp].LICL_lineStartChange, ax
	clrdw	ss:[bp].LICL_rippleCount, ax
	clrdwf	ss:[bp].LICL_totalChange, ax

clearInsDelAndCalc:
	;
	; Initialize the variables which indicate the amount of space that
	; has been inserted/deleted as part of calculation.
	;
	clr	ax
	clrdwf	ss:[bp].LICL_insertedSpace, ax

	stc					; 1st line must exist

calcMore:
	;
	; Carry set if the line in bx.di was not just created
	;
	clrdwf	ss:[bp].LICL_deletedSpace	; Doesn't nuke carry

EC <	call	ECValidateTotals				>
EC <	call	ECValidatePreviousRegion			>

;-----------------------------------------------------------------------------
CR_lineLoop label near
EC <	call	ECValidateTotals				>
	ProfilePoint 52
	;
	; *ds:si= Instance ptr
	; bx.di	= Line to start calculating at
	; cx	= Flags for previous line
	;
	; ss:bp	= LICL_vars
	; carry clear if the line is a new one (and so has no start).
	;
	; Save the previously computed line-flags
	;
	mov	ss:[bp].LICL_prevLineFlags, cx

	movdw	ss:[bp].LICL_line, bxdi		; Save current line
	jnc	CR_calcLineInfo			; Branch if line didn't exist
	
	;
	; Add or remove lines as necessary in an attempt to get stuff to line up
	;
	ProfilePoint 53
	call	InsertOrDeleteLines		; Insert or delete some lines.
	jnc	checkLaterRegion		; Branch if not lined up

	;
	; The line lines up perfectly...
	; If this line comes from a later region then we need to add the current
	; height of the line to the insertedSpace *and* recalculate the line.
	;
	ProfilePoint 54
	call	AddHeightIfFromLaterRegion	; carry set if from later region
	LONG jnc CR_almostPerfect		; Branch if all appears OK
	jmp	CR_calcLineInfo

checkLaterRegion:
	;
	; We must calculate the line, but we also want to account for the line
	; height if it's from a later region.
	;
	ProfilePoint 55
	call	AddHeightIfFromLaterRegion	; We ignore the return flag

CR_calcLineInfo	label near
	;
	; If we get here then we need to compute this line. Either the line
	; is new (we inserted it) or else it didn't start in exactly the right
	; place.
	;
	; ss:bp	= LICL_vars
	; cx	= Flags for previous line
	;
	call	GetFlags			; cx <- Flags for current line

	ProfilePoint 56
	call	CalculateLine			; Calculate the single line

CR_afterCalc	label	near
	;
	; Check to make sure that the height of the line doesn't cause it to
	; extend outside the bottom of the region.
	;
	ProfilePoint 57
	call	CheckLineInRegion
	LONG jnc CR_rippleToNextRegion		; Branch if line out of region
afterRippleCheck:

	;
	; Check for breaking before this line
	;
	test	ss:[bp].LICL_lineFlags, mask LF_STARTS_PARAGRAPH
	LONG jnz checkColumnBreakBefore
afterColumnBreakBeforeCheck:

	;
	; Check for an orphan
	;
	test	ss:[bp].LICL_lineFlags, mask LF_ENDS_PARAGRAPH
	LONG jnz checkOrphan
afterOrphanCheck:

	;
	; Check for end of region.
	;
	test	ss:[bp].LICL_lineFlags, mask LF_ENDS_IN_COLUMN_BREAK
	LONG jnz CR_calcFromNextColumn		; Branch if column-break

	test	ss:[bp].LICL_lineFlags, mask LF_ENDS_IN_SECTION_BREAK
	LONG jnz CR_calcFromNextSection		; Branch if section-break

	;
	; Check for end of document
	;
	test	ss:[bp].LICL_lineFlags, mask LF_ENDS_IN_NULL
	jnz	CR_reachedLastLine		; Branch if end of document

	ProfilePoint 58
	call	NextLineCreateIfNeeded		; bx.di <- next line
						; carry set if line existed
	ProfilePoint 59
	jmp	CR_lineLoop			; Loop to process it
;-----------------------------------------------------------------------------

CR_quit label near
EC <	call	ECValidateRegionAndLineHeights		>
EC <	call	ECValidateRegionCounts			>
EC <	call	ECValidateLineStructures		>
EC <	call	ECValidateRegionAndLineCounts		>
if _REGION_LIMIT
	clc
quit:	
endif
	.leave
	ProfilePoint 8
	ret

if _REGION_LIMIT

abort:
	call	WarnUserRevert
	jmp	quit

endif		

		
;-----------------------------------------------------------------------------
CR_reachedLastLine label near
	;
	; If we have reached the last line then we can remove all line 
	; structures which follow the current one. 
	;
	; The sum of the heights of the nuked lines may prove to be useful
	; to someone...
	;
	ProfilePoint 60
	call	TruncateLines			; cx.dx.ax <- hgt of nuked lines
	movdwf	ss:[bp].LICL_deletedSpace, cxdxax
EC <	call	ECValidateTotals			>
	
	;
	; Update the line counts
	;
	ProfilePoint 61
	call	HandleRippledLines		; Do the right thing

	;
	; Notify the region code that some regions may be empty.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	ProfilePoint 62
	call	TR_RegionIsLast			; Tell someone this is last one
						; bx.dx.ax <- hgt of nuked regs
						; cx <- # of deleted regions
	;
	; Check for nuked any regions.
	;
	tstdwf	bxdxax
	jz	noNukedRegions
	
	;
	; We nuked a region, force a redraw
	;
	mov	ss:[bp].LICL_linesToDraw, 2	; force a redraw

noNukedRegions:
	push	dx
	mov	cx, ss:[bp].LICL_region
	mov	dx, ss:[bp].LICL_lineFlags
	ProfilePoint 63
	call	UpdateRegionBreakFlags		; Update the flags
	pop	dx

	;
	; The deleted space (set by truncating lines) accounts for lines which
	; may have been in later regions. To offset this we remove the heights
	; of the nuked regions from the deleted space.
	;
	subdwf	ss:[bp].LICL_deletedSpace, bxdxax ; Account for region space
	
	;
	; You would think that would be enough, but it's not. We may have
	; rippled lines from a later region into the current region. Since
	; we have subsequently nuked these regions, this ripple-height
	; has already been accounted for. This means we need to remove
	; the rippled height from the inserted space, lest we add this
	; height twice.
	;
	adddwf	ss:[bp].LICL_insertedSpace, ss:[bp].LICL_rippleHeight, ax

	ProfilePoint 64
	call	UpdateSegment			; Set the region height
	ProfilePoint 65
	call	ClearToRegionBottom		; Clear to the bottom
	jmp	CR_quit



;-----------------------------------------------------------------------------
CR_almostPerfect label near
	;
	; A state of perfection is remarkably hard to achieve.
	;
	ProfilePoint 66
	call	UpdateSegment			; Update the current segment
	ProfilePoint 67
	call	CheckRecalcFromNextSegment	; Check for more to do
	LONG jnc clearInsDelAndCalc		; Branch if all done
	
	;
	; We are all done, clear out anything that needs it...
	;
	ProfilePoint 68
	call	ClearToRegionBottom		; Clear to the bottom
	jmp	CR_quit				; Else loop to do more

;-----------------------------------------------------------------------------
CR_calcFromNextColumn label near
	;
	; Calculate the next line, but do it in the context of the next
	; column (region). What we are doing is fooling the rippling code
	; into believing that the next line was actually computed and
	; caused an overflow.
	;
	; Fooling the rippling code requires a bit of effort since it
	; assumes so many things.
	;
	; Here are a list of variables and the assumptions it makes about them:
	;   LICL_line -
	;	This is the line which overflowed
	;
	;   LICL_insertedSpace -
	;	This is the amount of space inserted into the current region
	;	including the height of the line which overflowed.
	;
	;   LICL_rippleHeight -
	;	This is the amount of space which has rippled backwards into
	;	the current region, including the current line.
	;
	;   LICL_calcFlags -
	;	CF_LINE_CHANGED bit set if the last line computed was
	;	changed.
	;
	;   LICL_lineStart -
	;	Set to the start of the current line.
	;
	; In order to fool the code into doing the ripple correctly we need
	; to stop it from using the wrong line-height values (set by the
	; calculation code for the last line computed). We also want to
	; mark the line as not changed so we don't do anything silly like
	; add it to the list of lines to redraw since it hasn't been computed
	; yet.
	;
	movdw	bxdi, ss:[bp].LICL_line		; Save current line in bx.di

	incdw	ss:[bp].LICL_line		; Move to next line, sort of
	clrwbf	ss:[bp].LICL_lineHeight
	clrwbf	ss:[bp].LICL_oldLineHeight
	and	ss:[bp].LICL_calcFlags, not mask CF_LINE_CHANGED

	;
	; Set the line-start to the start of the new line
	;
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	movdw	ss:[bp].LICL_lineStart, dxax
	
	ProfilePoint 69
	call	RippleAndUpdateBreakFlags
if _REGION_LIMIT		
	LONG	jc	abort
endif		
	;
	; Since we are calculating from another region, we can zero out
	; the total-change for the region.
	;
	clrdwf	ss:[bp].LICL_totalChange
	
	;
	; Actually create the line which we pretended had caused the overflow.
	;
						; bx.di already holds old line
	ProfilePoint 70
	call	NextLineCreateIfNeeded		; bx.di <- next line
						; carry set if line existed
	movdw	ss:[bp].LICL_line, bxdi		; Save the line
	jmp	calcMore

;-----------------------------------------------------------------------------
CR_rippleToNextRegion label near
	;
	; Check to see if this line is the only one in the region. If it is
	; then we need to start computing in the next region.
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	jne	finishRipple
	
	;
	; This is the only line in this region. We want to compute the next
	; line in the next region... But wait :-)  If this is the last line
	; (ie: ends in null) then we want to branch back up into the loop
	; and allow the correct action to happen.
	;
	test	ss:[bp].LICL_lineFlags, mask LF_ENDS_IN_NULL
	LONG jnz afterRippleCheck		; Branch if end of document
	
	;
	; There is more after this line. Go compute it in the next column.
	;
	jmp	CR_calcFromNextColumn

finishRipple:
	;
	; Handle any widow/orphan control, or "keep paragraphs together".
	;
	ProfilePoint 71
	call	CheckGroupedLines
	
	;
	; There is no way that the line which ends this region could contain
	; a column or section break. If it did, then we wouldn't have calculated
	; the current line in this region.
	;
	and	ss:[bp].LICL_lineFlags, not (mask LF_ENDS_IN_SECTION_BREAK or \
					     mask LF_ENDS_IN_COLUMN_BREAK)

	ProfilePoint 72
	call	RippleAndUpdateBreakFlags
if _REGION_LIMIT		
	LONG	jc	abort	
endif
	;
	; Since we are calculating from another region, we can zero out
	; the total-change for the region.
	;
	clrdwf	ss:[bp].LICL_totalChange
	
	stc					; Signal: line did exist
	jmp	calcMore

;-----------------------------------------------------------------------------
CR_calcFromNextSection label near
	;
	; Calculate the next line, but do it in the context of the next
	; section.
	;
	
	;
	; Notify the region code that some regions may be empty.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	ProfilePoint 73
	call	TR_RegionIsLast			; Tell someone this is last one
						; bx.dx.ax <- hgt of nuked regs
						; cx <- # of deleted regions
	;
	; If we are in galley or draft mode, we may need to move later regions
	; up since we just deleted some.
	;
	ProfilePoint 74
	call	BltStuffForDeletedRegions	; Update the later regions

	;
	; This height has not been accumulated into the current region, even
	; though the lines and characters have. This means that we need to 
	; account for these new lines before we go off to ripple stuff.
	;
	adddwf	ss:[bp].LICL_insertedSpace, bxdxax

	;
	; You would think that would be enough, but it's not. We may have
	; rippled lines from a later region into the current region. Since
	; we have subsequently nuked these regions, this portion of the
	; ripple-height has already been accounted for.
	;
	; This means that we need to account for this extra height which
	; by now has been accumulated twice. We subtract from the inserted
	; space the minimum of nukedRegionSpace and rippleHeight.
	;
	ProfilePoint 75
	call	ComputeMinimumOfRippleHeightOrDeletedRegionSpace
	subdwf	ss:[bp].LICL_insertedSpace, bxdxax
	
	;
	; bxdxax= Amount of space which rippled into the current region from
	;	  regions which have been nuked.
	;
	; Since LICL_rippleHeight indicates how much has been rippled out
	; of the regions after the current one, and since some regions
	; have been nuked, rippleHeight needs to be adjusted. Conveniently
	; the amount to adjust is contained in bx.dx.ax
	;
	adddwf	ss:[bp].LICL_rippleHeight, bxdxax

	;
	; Since deleting regions can cause lines to be moved around, our
	; concept of the "next regions top line" may be incorrect. We need
	; to recalculate this value.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	ProfilePoint 76
	call	GetNextTopLine
	jmp	CR_calcFromNextColumn

;-----------------------------------------------------------------------------
checkOrphan:
	;
	; Check to see if this paragraph has some sort of orphan control.
	; If it does, check to see if we need to ripple from somewhere.
	;
	test	ss:[bp].LICL_lineFlags, mask LF_STARTS_PARAGRAPH
	LONG jnz afterOrphanCheck
				   
	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_KEEP_LINES
	LONG jz	afterOrphanCheck

	;
	; Figure out how many lines we want to keep together at the bottom
	;
	ExtractField byte, LICL_paraAttr.VTPA_keepInfo, VTKI_BOTTOM_LINES, al
	inc	al
	
	;
	; OK... We do need to do some sort of orphan control check.
	;
	ProfilePoint 77
	call	CheckAndHandleOrphanProblem
	LONG jnc afterOrphanCheck
	
	;
	; Everything is set up to ripple the start of the paragraph forward.
	;
	ProfilePoint 78
	jmp	CR_rippleToNextRegion

;-----------------------------------------------------------------------------
checkColumnBreakBefore:
	;
	; Check to see if this paragraph should have a break before it.
	;
	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_COLUMN_BREAK_BEFORE
	jz	abortColumnBreak
	
	;
	; We do want to break before this paragraph. Make sure it's not the
	; first line in the column though.
	;
	movdw	bxdi, ss:[bp].LICL_line
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	je	abortColumnBreak
	
	;
	; It's not the first line in the region, so we do want to ripple
	; it forward as though it were on the boundary of the region.
	;
	ProfilePoint 79
	jmp	CR_rippleToNextRegion

abortColumnBreak:
	jmp	afterColumnBreakBeforeCheck

CalculateRegions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMinimumOfRippleHeightOrDeletedRegionSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the minimum of the ripple height or the amount
		of space deleted when regions were nuked.

CALLED BY:	CalculateRegions
PASS:		ss:bp	= LICL_vars
		bx.dx.ax= Amount of space nuked by removing regions.
RETURN:		bx.dx.ax= Minimum of that value and ripple height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMinimumOfRippleHeightOrDeletedRegionSpace	proc	near
	negdwf	bxdxax				; bx.dx.ax <- nuked space
	jgedwf	bxdxax, ss:[bp].LICL_rippleHeight, gotMin

	movdwf	bxdxax, ss:[bp].LICL_rippleHeight
gotMin:
	negdwf	bxdxax				; bx.dx.ax <- minimum value
	ret
ComputeMinimumOfRippleHeightOrDeletedRegionSpace	endp

	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RippleAndUpdateBreakFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine some common code.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
RETURN:		stuff updated
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	Ripple stuff, saving the current region and LineFlags first
	
	Update the region-break flags for the old region and LineFlags

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RippleAndUpdateBreakFlags	proc	near
	ProfilePoint 48
	mov	ax, ss:[bp].LICL_region		; ax <- current region
	mov	dx, ss:[bp].LICL_lineFlags	; dx <- flags for last line

	call	RippleLinesToNextRegion		; Do the rippling
if _REGION_LIMIT		
	jc	done
endif
	;
	; Update the region flags after the ripple, so the height will
	; be correct.
	;
	; ax	= Region
	; dx	= Flags for last line in region
	;
	xchg	cx, ax				; cx <- region that changed
						; ax <- LineFlags
	call	UpdateRegionBreakFlags		; Update the flags
	mov	cx, ax				; Restore LineFlags

if _REGION_LIMIT		
	clc	
done:
endif
	ProfilePoint 47
	ret
RippleAndUpdateBreakFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RippleLinesToNextRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ripple some lines to the next region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
RETURN:		Lots of stuff updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Ripple such that the value in LICL_line is rippled forward to the
	next region.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RippleLinesToNextRegion	proc	near
	uses	ax, dx
	ProfilePoint 46
	.enter
	;
	; If we are rippling lines forward we need to remove the heights
	; of those lines from the insertedSpace.
	;
	call	RemoveHeightOfRippledLines
	
	;
	; We need to ripple the last line calculated into the next region.
	;
	call	UpdateSegment			; Set the region height
	
	;
	; Clear from lineBottom-lineHeight to the region bottom.
	;
	subwbf	ss:[bp].LICL_lineBottom, ss:[bp].LICL_lineHeight, cx
	call	ClearToRegionBottom		; Clear to the bottom

	call	RippleToNextRegion		; Ripple some more stuff
if _REGION_LIMIT		
	jc	done
endif
		
	clr	ax
	clrwbf	ss:[bp].LICL_lineBottom, ax	; Set previous line top
	clrdw	ss:[bp].LICL_rippleCount, ax
	
	call	FigureNextRegionChangeAndComputeRippleHeight

if _REGION_LIMIT
	clc
done:		
endif
	.leave
	ProfilePoint 45
	ret
RippleLinesToNextRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureNextRegionChangeAndComputeRippleHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the amount inserted/removed from the next region
		and figure the rippleHeight to use in the next region.
		
		This routine is only called if stuff has been rippled
		backwards.

CALLED BY:	RippleLinesToNextRegion
PASS:		ss:bp	= LICL_vars
		*ds:si	= Instance
RETURN:		LICL_insertedSpace set for next region
		LICL_rippleHeight set for next region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureNextRegionChangeAndComputeRippleHeight	proc	near
	uses	ax, bx, cx, dx, di
	.enter

	;
	; Check for nothing rippled.
	;
	tst	ss:[bp].LICL_rippleHeight.DWF_int.high
	js	rippleBack
	LONG jnz rippleForward
	
	tst	ss:[bp].LICL_rippleHeight.DWF_int.low
	LONG jnz rippleForward

	;
	; The integer part is zero... We're either rippling forward, or doing
	; nothing.
	;
	tst	ss:[bp].LICL_rippleHeight.DWF_frac
	LONG jnz rippleForward
	jmp	quitNoRippleOrInsert

rippleBack:

	;
	; Stuff did ripple. The new values look like this:
	;	insSp = MIN(oldRH, region.calcHeight)
	;	newRH = oldRH - insSp
	;
	; Since in fact both of these will be negative, it is best to
	; negate the RH values, do the computation, then put it all back
	; together again.
	;
	negdwf	ss:[bp].LICL_rippleHeight	; rh <- amount taken out

	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionGetHeight		; dx.al <- computed height
	clr	ah
	xchg	al, ah				; dx.ax <- computed height
	clr	bx				; bx.dx.ax <- computed height
	
;----------------------------------------------------------------------
	;
	; This code handles a particularly strange special case.
	;		 3/23/93 -jw
	;
	; At any given moment LICL_insertedSpace indicates the amount of
	; change in the current region and LICL_rippleHeight indicates the
	; amount of change in later regions.
	;
	; When we arrive here we are trying to use the value of 
	; LICL_rippleHeight computed for the previous region to generate the
	; values for LICL_insertedSpace and LICL_rippleHeight for the next
	; region we want to compute in.
	;
	; Normally this would be a fairly simple operation. Here are the
	; basic cases:
	;	No Change	(LICL_rippleHeight = 0)
	;	- Simple... do nothing
	;
	;	Ripple Forward	(LICL_rippleHeight > 0)
	;	- We set LICL_insertedSpace to the current value of
	;	  LICL_rippleHeight to indicate how much space has been
	;	  inserted at the start of the region. We set LICL_rippleHeight
	;	  to zero to indicate that no change has occurred in later
	;	  regions.
	;
	;	Ripple Backward (LICL_rippleHeight < 0)
	;	- This case is a bit more complex. We can't possibly ripple
	;	  more out of a region than existed there in the first place.
	;	  This means we set:
	;		LICL_insertedSpace = -1 * MIN(rippleHgt, region.hgt)
	;	  We set LICL_rippleHeight to be the remainder.
	;	
	;	  In the case where LICL_rippleHeight is smaller than the
	;	  height of the region, we just indicate how much was
	;	  removed from the front of the region and then set
	;	  LICL_rippleHeight to zero, indicating that nothing was taken
	;	  from later regions.
	;
	;	  In the case where LICL_rippleHeight is larger than the
	;	  height of the region, we take as much as the region has
	;	  to offer (set LICL_insertedSpace to -1 * region height)
	;	  and set LICL_rippleHeight to the remainder, indicating
	;	  that this space will be taken from later regions.
	;
	; Now for the special case... It is possible for us to arrive at
	; this point having rippled all the lines out of the next region,
	; but having LICL_rippleHeight being less than the region height.
	;
	; You would think this wouldn't be possible, but in the very special
	; situation where the last line calculated in the previous region 
	; was the first line of the region after this one (so LICL_rippleHeight
	; is set to the size of this region) and if that line grew taller
	; as part of recalculation, we will have mistakenly adjusted
	; LICL_rippleHeight to compensate for the change in line-height.
	;
	; If the constellations are all in the right positions, this can result
	; in LICL_rippleHeight being smaller than the region height. We
	; compound this mistake by coming in here and deciding that we really
	; didn't take everything out of this region, and everything goes to
	; hell from there.
	;
	; While it is possible to avoid making this change to LICL_rippleHeight,
	; doing so would mean making some more significant changes than I
	; really want to do, and given that I can make another fix (here) that
	; is very simple, I choose to do that.
	;
	; The fix is to make a special check to see if we've removed all the
	; lines from the next region. We would normally do this by checking
	; LICL_rippleHeight and finding it larger than the region height.
	; As I already said, this won't work.
	;
	; The other check we can make is to see if the top line of the current
	; region is the same as the top line of the next region. If they
	; are the same, then this region clearly does not contain any lines.
	;
	; In that situation we note that we do not choose the minimum of
	; LICL_rippleHeight and the region height, instead we use the
	; value of the region height, since we know we've rippled that much.
	;
	
	;
	; Check to see if this region is empty.
	;
	push	ax
	cmpdw	ss:[bp].LICL_regionTopLine, ss:[bp].LICL_nextRegionTopLine, ax
	pop	ax
	jne	skipHackFromHell

EC <	WARNING WARNING_SPECIAL_CASE_FOR_LARGE_DELETE_INVOKED		>
	
hackFromHell::
	;
	; The region is empty, use the region height (already in bx.dx.ax)
	;
	jmp	gotMin

skipHackFromHell:
;----------------------------------------------------------------------

	;
	; Compute the minimum of the region height and the ripple height
	; in order to figure out how much we've taken from this region.
	;
	cmpdwf	bxdxax, ss:[bp].LICL_rippleHeight
	jbe	gotMin
	movdwf	bxdxax, ss:[bp].LICL_rippleHeight

gotMin:
	;
	; bx.dx.ax = Amount we've taken out of this region.
	;
	movdwf	ss:[bp].LICL_insertedSpace, bxdxax
	
	subdwf	ss:[bp].LICL_rippleHeight, bxdxax; Compute new rippleHeight
	
	;
	; Turn things around again...
	;
	negdwf	ss:[bp].LICL_insertedSpace
	negdwf	ss:[bp].LICL_rippleHeight

quit:
	.leave
	ret

rippleForward:
	;
	; Getting here indicates we are rippling space forward. We put the
	; space into the insertedSpace and zero the rippleHeight.
	;
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	;
	; Not so fast... Here's a really "special" case for you...
	;		 4/18/93 -jw
	;
	; It is possible for us to be rippling lines forward that were never
	; really part of the region we'll be rippling into. That is to say
	; the region we're setting up to calculate next might have been empty.
	; If we rippled lines backwards, and if these lines became taller,
	; and we are now rippling them forward, then we will have a positive 
	; rippleHeight at this point.
	;
	; Unfortunately it does not make sense to simply include this in the
	; new insertedSpace value, since this space is not really being 
	; inserted in the next region, but has instead been inserted in an
	; even later region.
	;
	; So how do we handle this? Great question... The only way I can think
	; to handle this is to simply leave the rippleHeight alone (indicating
	; that the change occurred in a later region) and make the insertedSpace
	; zero. Of course if we rippled several lines backwards, and are now
	; rippling them all forward, and if some of them came from this region
	; and some of them came from later regions, we may well run into the
	; same problem... But I'm not sure how the heck to handle that.
	;
	cmpdw	ss:[bp].LICL_regionTopLine, ss:[bp].LICL_nextRegionTopLine, ax
	jne	normalStuff
	
	;
	; Region is empty, check for line coming from a later region.
	;
	cmpdw	ss:[bp].LICL_line, ss:[bp].LICL_regionTopLine, ax
	jb	normalStuff

moreHacksFromHell::
	;
	; The rippleHeight should not be put into the insertedSpace because the
	; lines in question came from an even later region. Doing this will
	; cause the line heights to be handled incorrectly later on (we will
	; compensate for the line-height twice in the insertedSpace and the
	; rippleHeight, producing two incorrect values).
	;
EC <	WARNING WARNING_SPECIAL_CASE_FOR_FORWARD_RIPPLE_INVOKED		>
	
	jmp	quit

normalStuff:
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	movdwf	ss:[bp].LICL_insertedSpace, ss:[bp].LICL_rippleHeight, ax


quitNoRippleHeight:
	;
	; If the old rippleHeight is positive (or zero) then there will be
	; no rippleHeight in the next region.
	;
	clrdwf	ss:[bp].LICL_rippleHeight
	jmp	quit


quitNoRippleOrInsert:
	clrdwf	ss:[bp].LICL_insertedSpace
	jmp	quitNoRippleHeight

FigureNextRegionChangeAndComputeRippleHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLineInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the current line really does fall in the
		current region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars right after computing the current line
				LICL_lineBottom set
RETURN:		carry set if the line is in the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLineInRegion	proc	near
	uses	ax
	.enter
	cmpwbf	ss:[bp].LICL_lineBottom, ss:[bp].LICL_regionTrueHeight, ax
	ja	notInRegion			; Branch if not in region

isInRegion::
	stc					; Signal: is in region

quit:
	.leave
	ret

notInRegion:
	clc					; Signal: not in region
	jmp	quit
CheckLineInRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckRecalcFromNextSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to recalculate from the next segment
		in the region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars set correctly
		LICL_line = last line calculated
RETURN:		carry set if no more calculation is needed
		carry clear otherwise
			bx.di	= Line to calculate
			cx	= Flags for previous line
			LICL_line = Line to start calculating at
			LICL_lineBottom set
			LICL_range.VTR_start set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckRecalcFromNextSegment	proc	near
	uses	ax, dx
	.enter
	;
	; We only calculate in the next segment if the current segment changed
	; (insertedSpace) or if the entire object has changed (totalChange).
	;
	tstdwf	ss:[bp].LICL_insertedSpace	; Check for change in segment
	jnz	doCalculation			; Branch if there was some

	tstdwf	ss:[bp].LICL_totalChange	; Check for change in region
	jz	noMoreCalculation		; Branch if none

doCalculation:
	;
	; We do need to calculate in the next segment (if there is one).
	; Figure out the top of the next segment, and if there is no next
	; segment, arrange to calculate from the bottom of the region.
	;

	;
	; Get the next segment top that follows the current line bottom.
	;
	ceilwbf	ss:[bp].LICL_lineBottom, dx	; dx <- line bottom
	mov	cx, ss:[bp].LICL_region		; cx <- region
	clr	bx				; get for calculation
	call	TR_RegionNextSegmentTop		; dx <- Next segment top
						; carry set if none
	jc	calcLineFromRegionBottom	; Branch if no more segments
	
	;
	; The big problem here is that we need to calculate *all* lines that
	; fall in the range of lines that fall between the line which
	; used to occupy the position at the start of the next segment and
	; the line which now occupies that position.
	;
	; Next segment top is one end of range we want to compute.
	; NST + insertedSpace is the other end of the range.
	;
	call	ComputeLineRangeToCover

	;
	; There is another segment and we want to compute either at the bottom
	; of the current segment or else at the start of the next one depending
	; on whether we inserted or deleted space.
	;
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed,  4/21/93 -jw
; Unfortunately LICL_insertedSpace is not a reflection of the total change to
; this segment, it is only a reflection of the additional change to the segment
; as a result of calculation in the segment. If we really want to know what
; happened here, we need to reflect on the total change (LICL_totalChange)
;
;	tst	ss:[bp].LICL_insertedSpace.DWF_int.high
	tst	ss:[bp].LICL_totalChange.DWF_int.high
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	jns	gotPosition			; Branch if inserting
	
	;
	; We deleted. We can't use nextSegTop as the position for getting the
	; line. Instead we need to use (nextSegTop+insertedSpace).
	;
	; We assume here that the inserted space, being negative, is not more
	; than a word in size.
	;
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Same change and logic as above, 4/21/93 -jw
;
;	lea	ax, ss:[bp].LICL_insertedSpace	; ss:ax <- DWFixed value
	lea	ax, ss:[bp].LICL_totalChange	; ss:ax <- DWFixed value
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	call	CeilingDWFixed			; ax <- ceiling
	add	dx, ax				; dx <- final position

gotPosition:
	call	TL_LineFromPosition		; bx.di <- line to compute
	movdw	ss:[bp].LICL_line, bxdi		; Save line to compute
	
	push	bx				; Save line.top
	call	TL_LineGetTop			; dx.bl <- line top
	movwbf	ss:[bp].LICL_lineBottom, dxbl	; Save previous line bottom
	pop	bx				; Restore line.top
	
	call	TL_LineToOffsetStart		; dx.ax <- start of line
	movdw	ss:[bp].LICL_range.VTR_start, dxax
	
moreCalculation:
	;
	; We can't just use the current lines flags here because the idea
	; is to *figure* the current lines flags based on the previous lines.
	;
	; If the current line hasn't been calculated its flags may not be
	; correct here, but the previous lines will always be.
	;
	pushdw	bxdi				; Save current line

	; *** At this point we must call TL_LinePrevious (instead of using
	; *** the TL_LinePrevSkipCheck macro) because (it at least one case)
	; *** the line number is zero.  I don't understand why, but John is
	; *** on vacation, and this fixes bug #17747 -- tony

	call	TL_LinePrevious			; bx.di <- previous line

	call	TL_LineGetFlags			; ax <- Previous LineFlags
	mov	cx, ax				; cx <- Previous LineFlags
	popdw	bxdi				; Restore current line
	
	;
	; The current line *must* be calculated and unfortunately must also
	; be drawn.
	;
	or	ss:[bp].LICL_calcFlags, mask CF_FORCE_CHANGED
	
	clc					; Signal: Compute from this line

quit:
	;
	; Carry set to quit calculating
	; Carry clear to continue calculating
	;	LICL_line, LICL_lineBottom, LICL_range.VTR_start set
	;	cx = LineFlags for previous line
	;
	.leave
	ret


noMoreCalculation:
	;
	; There is no more calculation to be done.
	;
	stc					; Signal: no more
	jmp	quit

;-----------------------------------------------------------------------------

calcLineFromRegionBottom:
	;
	; One of two cases here... We either want to compute what *used* to
	; be the last line in this region or we want to compute what *is* the
	; first line in the next region.
	;
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed this line, 4/21/93 -jw
;
;;;	tst	ss:[bp].LICL_insertedSpace.DWF_int.high
	tst	ss:[bp].LICL_totalChange.DWF_int.high
;
; The problem is that LICL_insertedSpace is a reflection of the additional
; change resulting from calculation in the current segment. LICL_totalChange
; is a reflection on the region as a whole. It is quite possible for the
; change in the current segment to be positive or zero when the total change
; for the region is negative (or vice versa). In the past we've just gotten
; lucky and this has worked most of the time, but it really isn't correct.
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	jns	regionGotTaller

	;
	; The region is shorter. We want to compute new lines at the bottom of
	; this current region.
	;
	; We want to start computing from the first line in the
	; next region, but we want to calculate it in the current
	; region.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	
	;
	; Check to see if the current region ends in a break. If it does
	; then we don't need to do any more calculation.
	;
	call	TR_RegionGetFlags		; ax <- VisTextRegionFlags
	test	ax, mask VLTRF_ENDED_BY_COLUMN_BREAK
	jnz	noMoreCalculation		; Branch if ends in a break
	
	call	TR_RegionIsLastInSection	; We can stop if it's the last
						;   in the section too
	jc	noMoreCalculation

	call	TR_RegionNext			; cx <- next region
	jc	noMoreCalculation		; Branch if no more regions
	jnz	noMoreCalculation		; Branch if region is empty
	
	;
	; There is a next region.
	;
	call	TR_RegionGetTopLine		; bx.di <- starting line
	movdw	ss:[bp].LICL_line, bxdi		; Save line to compute from

	call	TR_RegionGetStartOffset		; dx.ax <- starting offset
	movdw	ss:[bp].LICL_range.VTR_start, dxax
	
	;
	; Compute the position of the bottom of the region.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	call	GetRegionHeight			; dx.al <- height
	movwbf	ss:[bp].LICL_lineBottom, dxal	; Save prev line bottom
	jmp	moreCalculation


regionGotTaller:
	;
	; The region got taller. We want to re-compute whatever line
	; currently intersects the bottom of the region.
	;
	; Conveniently we have all the right values to use.
	;
	; We don't have to do this computation if the computed height of
	; the region is not greater than the regions absolute height.
	;
	call	TR_RegionGetHeight		; dx.al <- computed height
	cmpwbf	dxal, ss:[bp].LICL_regionTrueHeight
	jbe	noMoreCalculation

	ceilwbf	ss:[bp].LICL_regionTrueHeight, dx
	jmp	gotPosition

CheckRecalcFromNextSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeLineRangeToCover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the range of lines that need recomputing.

CALLED BY:	CheckRecalcFromNextSegment
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		dx	= Top of next segment
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Figure line at NST
	Figure line at NST + insertedSpace
	Order them
	Mark them all as needing redraw

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeLineRangeToCover	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	;
	; Get line at next segment top
	;
	call	TL_LineFromPosition		; bx.di <- line at NST
	pushdw	bxdi				; Save line at NST
	
	;
	; Get line at other end
	;
	lea	ax, ss:[bp].LICL_totalChange
	call	CeilingDWFixed			; ax <- insertedSpace
	add	dx, ax				; dx <- other end of range
	call	TL_LineFromPosition		; bx.di <- line at other end

	popdw	dxax				; dx.ax <- line at NST
	
	;
	; Order the range of lines
	;
	cmpdw	bxdi, dxax
	jbe	ordered
	xchgdw	bxdi, dxax
ordered:
	
	;
	; Mark them all.
	;
	incdw	dxax				; Include the last line

	mov	cx, mask LF_NEEDS_DRAW or mask LF_NEEDS_CALC
	call	TL_LineSumAndMarkRange		; cx.dx.ax <- sum of heights
	.leave
	ret
ComputeLineRangeToCover	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a single line.

CALLED BY:	CalculateSegment
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars set correctly
		cx	= Flags for this line
RETURN:		LICL_firstLine* set
		cx	= Flags for this line
		LICL_lineBottom updated for the line height if either of:
			line changed
			line needed calculation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateLine	proc	near
	uses	ax, bx, dx, di
	.enter
	movdw	bxdi, ss:[bp].LICL_line		; Get current line

	;
	; Make sure that the paragraph attributes are up to date for this line.
	;
	clrwbf	ss:[bp].LICL_lineHeight		; No height yet
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	call	T_EnsureCorrectParaAttr		; Force ruler to be up to date

	;
	; Get the appropriate flags and calculate the current line.
	;
	call	TL_LineCalculate		; Calculate the line

	;
	; Check for line changed, up the count if it has.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED or \
					mask CF_FORCE_CHANGED
	jz	quit

	;
	; Clear the "force changed" flag if it was set.
	;
	and	ss:[bp].LICL_calcFlags, not mask CF_FORCE_CHANGED

	;
	; Up the number of lines that need redrawing.
	;
	inc	ss:[bp].LICL_linesToDraw
	
	;
	; Update all the "firstLine" stuff
	;
	movdw	ss:[bp].LICL_firstLine, bxdi	; Save first line
	
	movdw	ss:[bp].LICL_firstLineStartOffset, dxax
	movdw	ss:[bp].LICL_firstLineEndOffset, ss:[bp].LICL_range.VTR_start, ax

	mov	ax, ss:[bp].LICL_lineFlags
	mov	ss:[bp].LICL_firstLineFlags, ax
	
	mov	ax, ss:[bp].LICL_oldLineFlags
	mov	ss:[bp].LICL_firstLineOldFlags, ax
	
	movwbf	ss:[bp].LICL_firstLineTop, ss:[bp].LICL_lineBottom, ax

	movwbf	ss:[bp].LICL_firstLineHeight, ss:[bp].LICL_lineHeight, ax

	mov	ax, LICL_paraAttr.VTPA_attributes
	mov	ss:[bp].LICL_firstLineParaAttrs, ax
	
if CHAR_JUSTIFICATION
	;
	; If we are doing character level justification, force the
	; stored justification to be right-justified so that the
	; line is re-drawn non-optimized.
	;
	test	LICL_paraAttr.VTPA_miscMode, mask TMMF_CHARACTER_JUSTIFICATION
	jz	justOK
	andnf	ax, not (mask VTPAA_JUSTIFICATION)
	ornf	ax, J_RIGHT shl (offset VTPAA_JUSTIFICATION)
	mov	ss:[bp].LICL_firstLineParaAttrs, ax
justOK:
endif
	mov	ax, ss:[bp].LICL_lineEnd
	mov	ss:[bp].LICL_firstLineEnd, ax
	
	mov	ax, ss:[bp].LICL_region
	mov	ss:[bp].LICL_firstLineRegion, ax
	
	mov	al, ss:[bp].LICL_lastFieldTabType
	mov	ss:[bp].LICL_firstLineLastFieldTabType, al
	
	;
	; If the LineFlags have made the transition from:
	;	old:	interactsAbove
	;	new:   ~interactsAbove
	; Then we need to redraw the line above in order to get rid of any
	; trash left over from the current line.
	;
	; The same holds for the transition for interactsBelow.
	;
	test	ss:[bp].LICL_oldLineFlags, mask LF_INTERACTS_ABOVE or \
					   mask LF_INTERACTS_BELOW
	jz	quit
	call	CheckInteractionChange

quit:
	;
	; Adjust the line-bottom by adding in the line-height
	;
	movwbf	dxah, ss:[bp].LICL_lineHeight
	addwbf	ss:[bp].LICL_lineBottom, dxah

	mov	cx, ss:[bp].LICL_lineFlags
	.leave
	ret
CalculateLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRegionBreakFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the flags that tell if a region ends in a break.

CALLED BY:	
PASS:		*ds:si	= Instance
		dx	= LineFlags to use for figuring
		cx	= Region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRegionBreakFlags	proc	near
	uses	ax, dx
	.enter
	;
	; Set the flags in the current region.
	;
	clr	ax				; Initialize flags
	test	dx, mask LF_ENDS_IN_COLUMN_BREAK
	jz	checkedColumn
	or	ax, mask VLTRF_ENDED_BY_COLUMN_BREAK
checkedColumn:

	mov	dx, ax				; dx <- bits to clear
	not	dx
	and	dx, mask VLTRF_ENDED_BY_COLUMN_BREAK

	call	TR_RegionAlterFlags
	.leave
	ret
UpdateRegionBreakFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInteractionChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a change in the way the line interacts with the
		lines around it that might require a full update.

CALLED BY:	CalculateLine
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckInteractionChange	proc	near
	uses	ax, bx, dx, di
	.enter
	;
	; If we've made a transition from interacting with another line
	; to not interacting with another line then we need to force the
	; line we used to interact with to be redrawn so we can get rid
	; of any futz left over on that line.
	;
	test	ss:[bp].LICL_oldLineFlags, mask LF_INTERACTS_ABOVE
	jz	checkBelow
	
	;
	; We used to interact above.
	;
	test	ss:[bp].LICL_lineFlags, mask LF_INTERACTS_ABOVE
	jnz	checkBelow
	
	;
	; We used to interact above, and now we don't. Force the previous
	; line to be drawn and force an update since an optimized redraw
	; isn't possible now.
	;
	movdw	bxdi, ss:[bp].LICL_line
	call	TL_LinePrevious			; bx.di <- previous line
	jc	checkBelow
	
	mov	ax, mask LF_NEEDS_DRAW
	clr	dx
	call	TL_LineAlterFlags		; Force previous to draw
	
	mov	ss:[bp].LICL_linesToDraw, 2	; Force update

checkBelow:
	;
	; Check for interacting below
	;
	test	ss:[bp].LICL_oldLineFlags, mask LF_INTERACTS_BELOW
	jz	quit
	
	;
	; We used to interact below
	;
	test	ss:[bp].LICL_lineFlags, mask LF_INTERACTS_BELOW
	jnz	quit
	
	;
	; We used to interact below, and now we don't. Force the next
	; line to be drawn and force an update since an optimized redraw
	; isn't possible now.
	;
	movdw	bxdi, ss:[bp].LICL_line
	call	CalcLineNext			; bx.di <- next line
	jc	quit				; Branch if no next line
	
	mov	ax, mask LF_NEEDS_DRAW
	clr	dx
	call	TL_LineAlterFlags		; Force next to draw
	
	mov	ss:[bp].LICL_linesToDraw, 2	; Force update

quit:
	.leave
	ret
CheckInteractionChange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get flags for calculation.

CALLED BY:	CalculateObject
PASS:		*ds:si	= Instance ptr
		cx	= LineFlags for previous line
RETURN:		cx	= Flags for this line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFlags	proc	near
	test	cx, mask LF_ENDS_PARAGRAPH	; Check for old line ends para
	mov	cx, 0				; No flags
	jz	notParaStart

	mov	cx, mask LF_STARTS_PARAGRAPH

notParaStart:
	ret
GetFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertOrDeleteLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert or delete line so that the following condition is met:
			Current line starts before ss:bp.LICL_range.VTR_start
			Next line starts after ss:bp.LICL_range.VTR_start

CALLED BY:	CalculateObject
PASS:		*ds:si	= Instance ptr
		bx.di	= Current line
		ss:bp	= LICL_vars with:
				LICL_range.VTR_start -
					Where current line starts
				LICL_range.VTR_end -
					Offset past inserted text
RETURN:		carry set if the current line starts at exactly the right place.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine is trying to insert or delete lines in the hope that
	creating/deleting line structures will reduce the number of lines
	that need recalculation.
	
	Here's the concept...
	
	Part of this is figuring out if the new line start is more than
	the old line start. In this case we insert a line in the hope that
	after calculating the next line, the lines after that point will
	match up.
	
	This is somewhat complexified by the fact that we don't store the
	line starts, but instead store only the number of characters on
	each line.

	The old line start isn't easily available since lines before the
	current one may have been calculated already and therefore will
	have had their charCounts changed.
	
	Conveniently we have a variable which tells us the difference between
	the current concept of the line-start and the value that this line
	start would have had previously.
	
	The best way to think about this is that lineStartChange contains
	the number of characters that have been inserted in front of the
	current line.
	
	This is tremendously useful because what that means is that if the
	lineStartChange is positive, then the new line-start for a line
	is guaranteed to be larger than the next one.

	On the other side of this, if the lineStartChange is less than zero
	we want to delete lines.
    ----------------------
	if (lineStartChange == 0) {
	    return
	}
	
	if (lineStart > 0) {
	    InsertLine(line)
	} else {
	    delCount = 0
	    origLine = line
	    nlsc     = lineStartChange + LineGetCharCount(line)
	    while (nlsc < 0) {
		nlsc += LineGetCharCount(line)
		delCount++
		line = LineNext(line)
	    }
	    if (delCount) {
	        DeleteLines(origLine, delCount)
	    }
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertOrDeleteLines	proc	near
	uses	ax, cx, dx
	.enter
	;
	; Check to see if the amount of change in the start of the lines
	; is positive (insert), negative (delete), or zero (do nothing).
	;
	movdw	dxax, ss:[bp].LICL_lineStartChange
	tstdw	dxax
	jz	deleteOrQuit
	
	tst	dx
	js	deleteLines

	;
	; We want to insert a line.
	; New line should be marked as "changed".
	;
	
	;
	; But wait... If we have been rippling lines backwards into the
	; current region, we can't insert a line. Doing so would give the
	; current region credit for the line, when in fact it really comes
	; from a later region.
	;
	tstdw	ss:[bp].LICL_rippleCount	; Have we been rippling?
	LONG jnz calculateLineAndDraw		; Branch if we have

IODL_insert	label	near
	call	InsertOneLine			; bx.di <- first new line

	jmp	calculateLineAndDraw

deleteOrQuit:
	;
	; If we get here it means that we want to see if we can delete lines,
	; unless of course we were inserting text (and not deleting it). In
	; that case we don't need to worry about deleting lines.
	;
	tstdw	ss:[bp].LICL_charDelCount	; Check for having deleted
	jz	afterDelete			; Branch if no characters nuked

deleteLines:
	;
	; *ds:si= Instance ptr
	; ss:bp	= LICL_vars
	; bx.di	= Current line
	; dx.ax	= lineStartChange
	;
	; We delete as many lines as can be covered by the lineStartChange,
	; but we don't allow ourselves to nuke lines which are beyond the end
	; of the current region. There really isn't much point in doing this
	; since we will have to calculate any lines which come in from the
	; next region anyway.
	;
	; As soon as we find a line that isn't covered by lineStartChange we
	; stop counting.
	;
	pushdw	bxdi				; Save line
	clrdw	ss:[bp].LICL_delCount		; No lines to nuke yet...

deleteLoop:
	cmpdw	bxdi, ss:[bp].LICL_nextRegionTopLine
	jae	IODL_endDeleteLoop		; Branch if at next region

	call	TL_LineAddCharCount		; dx.ax <- "new" lsc

	jgdw	dxax, 0, deleteUpToThisLine	; Check lineStartChange
						; positive, branch if it is

	call	CalcLineNext			; bx.di <- next line
	jc	IODL_endDeleteLoop

	incdw	ss:[bp].LICL_delCount		; One more to nuke
	jmp	deleteLoop

deleteUpToThisLine:
	call	TL_LineSubtractCharCount	; dx.ax <- Correct value for lsc

IODL_endDeleteLoop label near
	popdw	bxdi				; Restore line

	;
	; We now have:
	; bx.di	= Starting line
	; dx.ax	= New value for LICL_lineStartChange
	; ss:bp	= LICL_vars w/ LICL_delCount set
	;
	movdw	ss:[bp].LICL_lineStartChange, dxax

	movdw	dxax, ss:[bp].LICL_delCount	; dx.ax <- # of lines to nuke

	tstdw	dxax				; Check for nothing to delete
	jz	afterDelete			; Branch if nothing to nuke

	;
	; Nuke the number of lines in LICL_delCount starting at bx.di
	;
	subdw	ss:[bp].LICL_lineCount, dxax	; Update the count
	subdw	ss:[bp].LICL_nextRegionTopLine, dxax

	call	TL_LineDelete			; cx.dx.ax <- cumulative height
	
	;
	; Update the amount of "inserted" space that results from calculation.
	; We subtract the height of the deleted lines from the "inserted" space
	; since this is really an accumulation of the net change in the position
	; of the line that follows the last line calculated.
	;
	subdwf	ss:[bp].LICL_insertedSpace,cxdxax ; Save nuked space

afterDelete:
IODL_afterDelete	label	near

	;
	; We have deleted as many lines as we need to.
	;
	; If the old start of the current line is the same as the new line
	; start then we can stop calculating.
	;
	; We can't stop calculating if we haven't computed beyond the
	; affected area.
	;
	tstdw	ss:[bp].LICL_lineStartChange
	jnz	calculateLineAndDraw		; Branch if oldStart != newStart

	;
	; If we are "forcing" the line to be recalculated because this line
	; has been rippled from the previous region into the current one
	; then we can't just abort now.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_FORCE_CHANGED
	jnz	calculateLineAndDraw

	;
	; If the current line start falls before the position of the change
	; we want to recalculate the line, but we don't need to force it to
	; be drawn.
	;
	cmpdw	ss:[bp].LICL_range.VTR_start, ss:[bp].LICL_startPos, ax
	jb	justCalculate

	;
	; Check for the current line start not being beyond the end of the
	; range to compute.
	;
	cmpdw	ss:[bp].LICL_range.VTR_start, ss:[bp].LICL_range.VTR_end, ax
	jbe	calculateLineAndDraw

	;
	; The line starts are the same. We can quit calculating as long as the
	; current line is beyond the affected area.
	;
	call	TL_LineGetFlags			; ax <- LineFlags
	test	ax, mask LF_NEEDS_CALC		; Check for line needs calc
	jnz	calculateLineAndDraw		; Calculate if line has changed
	
	;
	; One last check. If the line used to interact with the line above it,
	; and if the line is the first in the region, then we need to mark
	; it as not interacting with the line above it.
	;
	test	ax, mask LF_INTERACTS_ABOVE
	jz	quitNoCalc

	;
	; It does interact with the previous line. If it's the first line in
	; the region then we mark it as not interacting above.
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	jne	quitNoCalc
	
	;
	; It interacts above *and* is the first line of the region. This can't
	; be allowed...
	;
	clr	ax				; Bits to set
	mov	dx, mask LF_INTERACTS_ABOVE	; Bits to clear
	call	TL_LineAlterFlags		; No longer interacts

quitNoCalc:
	;
	; The line is not in the affected area. It isn't marked as needing
	; calculation. It already starts at the right place. We can stop now.
	;
	stc					; Signal: Can stop calculating
	jmp	quit

calculateLineAndDraw:
	;
	; Setting the "force changed" bit will cause the calculation code
	; to set the "needs draw" bit associated with this line.
	;
	or	ss:[bp].LICL_calcFlags, mask CF_FORCE_CHANGED

justCalculate:
	clc					; Signal: calculate this line

quit:
	.leave
	ret
InsertOrDeleteLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NextLineCreateIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next line in the object creating it if it doesn't
		already exist.

CALLED BY:	CalculateObject
PASS:		*ds:si	= Instance ptr
		bx.di	= Current line
RETURN:		bx.di	= Next line
		carry set if line already existed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NextLineCreateIfNeeded	proc	near
	call	CalcLineNext		; bx.di <- next line
	jnc	lineExists		; Branch if it exists
	
	;
	; There is no next line. We need to insert one.
	;
	movdw	bxdi, -1		; Insert at the end
	call	InsertOneLine		; bx.di <- first new line

	clc				; Signal: line didn't exist
quit:
	ret

lineExists:
	stc				; Signal: line exists
	jmp	quit

NextLineCreateIfNeeded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertOneLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a single line and update stuff

CALLED BY:	NextLineCreateIfNeeded, InsertOrDeleteLines
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		bx.di	= Line to insert before
RETURN:		bx.di	= First new line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertOneLine	proc	near
	uses	ax, cx, dx
	.enter
	mov	cx, ss:[bp].LICL_region	; Region to adjust
	movdw	dxax, 1			; Insert one line
	call	TL_LineInsert		; bx.di <- first new line

	incdw	ss:[bp].LICL_lineCount		; Update the count
	incdw	ss:[bp].LICL_nextRegionTopLine	; Update the next top line
	.leave
	ret
InsertOneLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TruncateLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Truncate the object by removing unused line structures at
		the end.

CALLED BY:	CalculateObject
PASS:		*ds:si	= Instance ptr
		bx.di	= Last line to keep
RETURN:		cx.dx.ax = Height of nuked lines that fall in the current
			  region.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TruncateLines	proc	near
	uses	bx, di
	.enter
	clrdwf	cxdxax			; Assume nothing to delete

	call	CalcLineNext		; bx.di <- next line
	jc	truncated		; Branch if no more

	movdw	dxax, -1		; Delete to end

	call	TL_LineDelete		; cx.dx.ax <- total amount nuked

	;
	; Force an update since we have deleted some lines
	;
	mov	ss:[bp].LICL_linesToDraw, 2
truncated:
	.leave
	ret
TruncateLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineBottomAndRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the position of the bottom of the previous line
		and the region it is in.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		bx.di	= First line to compute
		ss:bp	= LICL_vars w/ LICL_line set
RETURN:		LICL_lineBottom, LICL_region set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This sounds like a really simple operation but it is actually somewhat
	complex. The problem in calculation is that you can't just use the
	current region and line-top as you might expect. The change could
	have resulted in the current line growing shorter and therefore
	rippling backwards to the previous region.
	
	So... We have to do a little logic here:
		if (line is first in region) {
		    if (has previous region) {
			lineBottom = prevRegion.height
			region	   = prevRegion
		    } else {
		        lineBottom = 0
			region	   = region
		    }
		} else {
		   lineBottom = line.top
		   region     = region
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLineBottomAndRegion	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	movdw	ss:[bp].LICL_line, bxdi		; Save first line

	;
	; We need to get the top line of the current region, but there are
	; also some really useful values we can get that we'll want to keep
	; around, so we stuff them into our cache here.
	;
	call	TR_RegionFromLine		; cx <- region containing line
	call	GetTopLines			; Set LICL_regionTopLine and
						;     LICL_nextRegionTopLine
						; bx.di <- region top line
	
	cmpdw	ss:[bp].LICL_line, bxdi		; Check for line at region start
	jne	useLineTop
	
	;
	; The more complex case... We need to see if there is a previous region
	; and if there is, use that as the place to start calculating.
	;
	mov	dx, cx				; dx <- old region

	call	TR_RegionPrevSkipEmpty		; cx <- previous region
	jc	noPrevRegion
	
	;
	; If the previous region ends in a column/section break then we 
	; use the old region.
	;
	call	TR_RegionGetFlags		; ax <- VisTextRegionFlags
	test	ax, mask VLTRF_ENDED_BY_COLUMN_BREAK
	jnz	useNextRegion			; Branch if ends in a break
	
	call	TR_RegionIsLastInSection
	jc	useNextRegion

	;
	; There is a previous region...
	;
	mov	ss:[bp].LICL_region, cx		; Use previous region
	call	GetRegionHeight			; dx.al <- height
	movwbf	ss:[bp].LICL_lineBottom, dxal	; Save prev line bottom

	;
	; Update the cached "region top line" value.
	;
	call	GetTopLines			; Update the cached values

quit:
	;
	; Get the current regions true height.
	;
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	call	TR_RegionGetTrueHeight		; dx.al <- region height
	movwbf	ss:[bp].LICL_regionTrueHeight, dxal
	.leave
	ret


useNextRegion:
	mov	cx, dx				; Restore region
	
	;;; fall through

useLineTop:
	;
	; The simple case... The line is in the interior of a region so we
	; can just calculate it in place...
	;
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- current line
	mov	ss:[bp].LICL_region, cx		; Save current region

	call	TL_LineGetTop			; dx.bl <- line top
	movwbf	ss:[bp].LICL_lineBottom, dxbl	; Save line top
	jmp	quit


noPrevRegion:
	;
	; There is no previous region (this must be the first line in the
	; object).
	;
	mov	ss:[bp].LICL_region, dx		; Use current region
	clrwbf	ss:[bp].LICL_lineBottom		; And assume top is at 0
	jmp	quit

CalcLineBottomAndRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTopLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top line for the current and next region.

CALLED BY:	CalcLineBottomAndRegion, RippleToNextRegion
PASS:		*ds:si	= Instance
		cx	= Current region
		ss:bp	= LICL_vars
RETURN:		LICL_regionTopLine, LICL_nextRegionTopLine set
		bx.di	= Regions top line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTopLines	proc	near
	call	TR_RegionGetTopLine		; bx.di <- starting line
	movdw	ss:[bp].LICL_regionTopLine, bxdi
	
	call	GetNextTopLine
	ret
GetTopLines	endp

GetNextTopLine	proc	near
	uses	bx, cx, di
	.enter
	movdw	bxdi, ss:[bp].LICL_lineCount	; Assume no next region
	incdw	bxdi				; Make it one-based
	
	call	TR_RegionNext			; cx <- next region
	jc	gotNextTop
	call	TR_RegionGetTopLine		; bx.di <- next starting line
gotNextTop:
	movdw	ss:[bp].LICL_nextRegionTopLine, bxdi
	.leave
	ret
GetNextTopLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a segment by using bit-blt and clearing rectangles.
		Also update the height of the region containing the segment
		if any space was inserted or deleted.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (insertedSpace > 0) {
	    /* Move stuff down */
	} else if (insertedSpace < 0) {
	    /* Move stuff up */
	}
	AdjustRegionHeight(region, insertedSpace)
	
	
  NOTE:	Since small objects do not have multiple segments this routine will
	never be called from a small routine.

  NOTE TO THE ABOVE NOTE: This is wrong!  This routine is called on small
			  objects all the time.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSegment	proc	near	uses	ax, bx, cx, dx, di
	class	VisLargeTextClass
	.enter
	call	TextCheckCanDraw
	jc	updateHeightThenDone

	; First transform the gstate

	clr	dl				; No DrawFlags
	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionTransformGState	; Update the gstate

	movdwf  bxdxax, ss:[bp].LICL_insertedSpace
	adddwf  bxdxax, ss:[bp].LICL_totalChange
	movdwf  ss:[bp].LICL_bltChange, bxdxax	; Save the total change

	tstdwf	bxdxax
	jz	updateHeightDealWithEndSpace
	
	;
	; If the bottom of the last line we calculated is beyond the bottom
	; of the region, then there is no reason to do a BitBlt call.
	;
	call	CheckLineInRegion
	jnc	updateHeightDealWithEndSpace	; Branch if beyond region bottom

	;
	; Check for fractional amount of space inserted, or for a scale
	; applied to our window that is non-integer, or the disable-optimized
	; redraw attr.  In any of these cases we need to update the lines in
	; the window rather than using bit-blt to redraw them.
	;
	tst	ax				; Check for fractional move
	jnz	forceRedraw			; Branch if it is
			
	call	CheckFractionalYScale		; Check for fractional scale
	jc	forceRedraw			; Branch if it is

	push 	ax, bx
	mov	ax, ATTR_VIS_TEXT_DISABLE_OPTIMIZED_REDRAW
	call	ObjVarFindData
	pop	ax, bx
	jc	forceRedraw


		
	; if we are inserting then update the region height first,
	; otherwise do it last

	tst	bx				; Check for deleting space
	js	deletingSpace

	call	UpdateRegionHeight		; Update the height
	call	BltStuff			; Shift the data on the screen
	jmp	dealWithSpaceAtEnd

deletingSpace:
	call	BltStuff			; Shift the data on the screen

updateHeightDealWithEndSpace:
	call	UpdateRegionHeight		; Update the height

dealWithSpaceAtEnd:

	;
	; we now need to deal with blt-ing for space inserted/deleted at
	; the end of the region *if* we are in GALLEY or DRAFT mode
	;
	call	Text_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	done
	cmp	ds:[di].VLTI_displayMode, VLTDM_GALLEY
	jb	done

	call	BltStuffForDeletedSpace

done:
	.leave
	ret


updateHeightThenDone:
	call	UpdateRegionHeight		; Update the height
	jmp	done


forceRedraw:
	;
	; For some reason we can't use bit-blt to update the screen. Instead
	; we need to cause every line in the region below the first one to
	; redraw.
	;
	call	ForceRedrawOfLinesInRegion
	jmp	updateHeightThenDone

UpdateSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Blt a range of data up or down.

CALLED BY:	UpdateSegment
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		gstate	= transformed for this region
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	sourceX	= 0
	destX	= 0
	width	= RegionWidth(region)
	sourceY	= lineBottom - insertedSpace
	destY	= lineBottom
	height	= NextSegmentTop(region, lineBottom) - lineBottom
	BitBlt(source*, dest*)
	
*** Important Note ***
	LICL_insertedSpace only indicates the amount of space which was
	inserted in this segment. It does not indicate the amount of
	space inserted before this segment. 
	
	LICL_bltChange contains the value we need to use.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltStuff	proc	near
	class	VisTextClass
	.enter
	;
	; Compute the height of the area to move and pass it on the stack.
	;
	ceilwbf	ss:[bp].LICL_lineBottom, dx	; dx <- line bottom
	mov	ax, dx				; Save line bottom in ax
	mov	bx, 1				; get for blt-ing
	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionNextSegmentTop		; dx <- next segment top
	mov	bx, dx				; Save next-seg top in bx
	sub	dx, ax				; dx <- height
	jbe	10$
	inc	dx				; include boundary pixel
10$:
	push	si				; Save instance ptr
	push	bx				; Save next segment top

	;
	; It is possible for dx to be negative here. What this means is that
	; the bottom of the last computed line is below the bottom of the 
	; region. When that happens, there is nothing to blt so we can just
	; quit.
	;
	tst	dx
	LONG js	quitPop
	
	;
	; It is also possible for the destination of the bit-blt to be beyond
	; the next segment. This isn't good because it will cause greebles.
	;
	; The height we have calculated (dx) is the distance from the bottom
	; of the last line calculated to the top of the next segment.
	;
	; The source is actually at lineBottom-insSpace and the destination
	; is at lineBottom. We really want to use the minimum of the
	; following two heights:
	;	nextSegTop - lineBottom
	;	nextSegTop - (lineBottom - insSpace)
	;
	; Since we already computed the first value, we need only compute
	; the second value and then use it if it is less than what we already
	; have.
	;
	; We hope to god that the bltChange amount isn't a dword :-)
	;
	lea	ax, ss:[bp].LICL_bltChange	; ss:ax <- DWFixed value
	call	CeilingDWFixed			; ax <- ceiling
	
	mov	bx, dx				; bx <- second value to check
	add	bx, ax
	
	;
	; Use the smaller height
	;
	cmp	dx, bx				; dx <- MIN( height choices )
	jle	gotHeight
	mov	dx, bx
gotHeight:
	
	;
	; Check again to make sure that the height isn't negative.
	;
	tst	dx
	js	quitPop

	push	dx				; Pass height on stack

	;
	;	Source = lineBottom-insSpace
	;	Dest   = lineBottom
	;
	mov	cx, ss:[bp].LICL_bltChange.DWF_frac
	movwbf	dxcl, ss:[bp].LICL_lineBottom	; dx.cl <- source Y
	sub	cl, ch
	sub	dx, ss:[bp].LICL_bltChange.DWF_int.low
	
	ceilwbf	dxcl, dx			; cx <- source Y
	mov	cx, dx

	ceilwbf	ss:[bp].LICL_lineBottom, dx	; dx <- destination Y

	;
	; Compute the width of the segment and the left/right.
	;
	call	ComputeBltAreaLeftRight		; ax <- left edge
						; bx <- right edge
	;
	; Grab the gstate
	;
	call	Text_DerefVis_DI		; ds:di <- instance
	mov	di, ds:[di].VTI_gstate		; di <- gstate

	;
	; Pass flags on the stack
	;
	mov	si, BLTM_COPY			; si <- flags
	push	si				; Pass flags

	;
	; ax	= Left
	; bx	= Right
	; cx	= Source Y
	; dx	= Dest Y
	; di	= GState
	; On stack:
	;	Height, Flags
	;
	mov	si, bx				; si <- width
	sub	si, ax

	mov	bx, cx				; bx <- source Y

						; ax already holds source X
	mov	cx, ax				; cx <- dest X
doBlt::
	;
	; ax	= Source X
	; bx	= Source Y
	; cx	= Dest X
	; dx	= Dest Y
	; di	= GState
	; si	= Width
	; On stack:
	;	Height, Flags
	;
	call	GrBitBlt

;-----------------------------------------------------------------------------
;		     Clearing the empty space out
;-----------------------------------------------------------------------------
clearEmptySpace::
	; 
	; We need to clear from the bottom of the segment to the top of
	; the next segment. This clears out any gunk left around by the
	; bit-blt.
	;
	; ax	= Left edge of area
	; si	= Width of area
	;
	mov	cx, si				; cx <- width
	add	cx, ax				; cx <- right
	pop	dx				; dx <- bottom of area to clear
	pop	si				; si <- instance ptr
	
;;;	call	ClearEmptySpaceAfterBlt
quit:
	.leave
	ret


quitPop:
	pop	bx
	pop	si
	jmp	quit
BltStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeBltAreaLeftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the left and right edges of the area to blt.

CALLED BY:	BltStuff
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		cx	= Source Y
		dx	= Destination Y
RETURN:		ax	= Left edge of area to blt
		bx	= Right edge of area to blt
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeBltAreaLeftRight	proc	near
	uses	cx, dx
	.enter
	;
	; We need:
	;	cx = region number
	;	dx = Y position
	;	bx = Integer height at that position
	;
	; The problem is that the Y position needs to be the minimum of the
	; source/dest Y positions.
	;
	; Likewise the height needs to be the distance from the minimum Y
	; position to the bottom of the area we're moving.
	;
	
	;
	; Figure the minimum and maximum Y positions.
	;
	cmp	cx, dx
	jbe	gotYPositions
	xchg	cx, dx
gotYPositions:
	
	;
	; cx	= Minimum Y position
	; dx	= Maximum Y position
	;
	; Figure the bottom of the area.
	;
	lea	ax, ss:[bp].LICL_bltChange	; ss:ax <- DWFixed value
	call	CeilingDWFixed			; ax <- ceiling
	mov	bx, ax				; bx <- amount to move
	add	dx, bx				; dx <- bottom of total area
	
	sub	dx, cx				; dx <- height of area

	;
	; dx	= Distance from minimum Y to maximum affected Y position
	; cx	= Minimum Y position
	;
	mov	bx, dx				; bx <- height of area
	mov	dx, cx				; dx <- top of area

	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionLeftRight		; ax <- left edge
						; bx <- right edge
	.leave
	ret
ComputeBltAreaLeftRight	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	BltStuffForDeletedSpace

DESCRIPTION:	Blt a range of data to account for space deleted at the bottom
		of the region in GALLEY or DRAFT mode

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ds:di - vis data
	ss:bp - LICL_vars
	gstate - translated for this region

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	This is called *after* the region height is adjusted

	sourceX	= 0
	destX	= 0
	width	= LARGE
	sourceY	= GetTrueHeight(region) + LICL_deletedSpace
	destY	= GetTrueHeight(region)
	height	= LARGE
	BitBlt(source*, dest*)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 3/92		Initial version

------------------------------------------------------------------------------@
BltStuffForDeletedSpace	proc	near	uses si
	class	VisTextClass
	.enter

	lea	ax, ss:[bp].LICL_deletedSpace	; ss:ax <- DWFixed value
	call	CeilingDWFixed			; ax <- ceiling of deleted space
	mov	bx, ax				; bx <- ceiling of del-space

	tst	bx
	jz	done

	mov	di, ds:[di].VTI_gstate		; di <- gstate

	mov	ax, LARGEST_BLT_VALUE
	push	ax				; Pass height
	mov	ax, BLTM_COPY
	push	ax				; Pass flags

	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionGetHeight		; dxal = calcHeight
	ceilwbf	dxal, dx			; dx = true height (destY)
	add	bx, dx				; bx = source Y

	mov	si, LARGEST_BLT_VALUE		; si <- width
	clr	ax				; ax <- source X
	clr	cx				; cx <- dest X

	call	GrBitBlt
done:
	.leave
	ret

BltStuffForDeletedSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltStuffForDeletedRegions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuffle data in galley or draft mode to account for
		deleted regions.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		dx.ah	= Amount of space removed
		cx	= Number of deleted regions
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	This routine is only called when there are in fact more regions
	beyond the current one.
	
	We find the bottom of the current region. This is the destination
	Y-position. The amount-removed tells us where the source is.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltStuffForDeletedRegions	proc	near
	class	VisLargeTextClass
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	;
	; First check to see if we're in galley or draft mode.
	;
	call	Text_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	done
	cmp	ds:[di].VLTI_displayMode, VLTDM_GALLEY
	jb	done

	;
	; We are in galley or draft mode. Do the change.
	;
	call	TextCheckCanDraw		; Can we draw
	jc	done				; Branch if we can't

	;
	; Compute the amount of height due to region separators.
	;
	pushdw	dxax				; Save amount deleted
	mov	ax, cx				; ax <- # of nuked regions
	mul	ds:[di].VLTI_regionSpacing	; ax <- total height
	mov	cx, ax				; cx <- total height
	popdw	dxax				; Restore amount deleted
	add	dx, cx				; Account for region spacing

	;
	; Transform the gstate
	;
	pushdw	dxax				; Save amount of change
	clr	dl				; No DrawFlags
	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionTransformGState	; Update the gstate

	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionGetHeight		; dxal <- calcHeight
	popdw	cxbx				; cx.bh <- amount of change
	
	;
	; Update the display area.
	;
	; dx.al	= Dest for move.
	; cx.bh	= Amount of space deleted.
	;
	ceilwbf	cxbh, cx			; cx <- Deleted space
	jcxz	done				; Branch if none
	
	ceilwbf	dxal, dx			; dx <- Dest for move

	mov	di, ds:[di].VTI_gstate		; di <- gstate

	mov	ax, LARGEST_BLT_VALUE		; ax <- height to move
	push	ax				; Pass height
	mov	ax, BLTM_COPY			; ax <- flags
	push	ax				; Pass flags

						; dx holds dest Y
	mov	bx, dx				; bx <- source Y
	add	bx, cx

	mov	si, LARGEST_BLT_VALUE		; si <- width
	clr	ax				; ax <- source X
	clr	cx				; cx <- dest X

	call	GrBitBlt
done:
	.leave
	ret
BltStuffForDeletedRegions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRegionHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the height of a region by adding the inserted space
		to it.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		gstate	= transformed for this region
RETURN:		nothing
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRegionHeight	proc	near
	uses	ax, bx
	.enter
	movdwf	bxdxax, ss:[bp].LICL_insertedSpace
	subdwf	bxdxax, ss:[bp].LICL_deletedSpace
						; bx.dx.ax <- ins - del
	
	tstdwf	bxdxax				; Check for no change
	jz	quit				; Branch if none

	;
	; Update the "totalChange"
	;
	adddwf	ss:[bp].LICL_totalChange, bxdxax

	;
	; Update the region height
	;
	mov	al, ah				; dx.al <- adjustment
	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionAdjustHeight		; Update the height
	
	;
	; Force an update if the size of the object has changed.
	;
	mov	ss:[bp].LICL_linesToDraw, 2	; This will force an update
quit:
	.leave
	ret
UpdateRegionHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearToRegionBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear to the bottom of a region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearToRegionBottom	proc	near
	uses	ax, cx, dx
	.enter
	;
	; We get here in one of two ways. Either we have computed the last line
	; and have therefore deleted any line remnants (in which case the
	; LICL_deletedSpace will be non-zero) or else we are rippling, and the
	; LICL_totalChange will be non-zero.
	;
	; In either case we need to do the clear.
	;
	tstdwf	ss:[bp].LICL_deletedSpace
	jnz	clearArea

	tstdwf	ss:[bp].LICL_totalChange
	jz	quit

clearArea:
	;
	; First transform the gstate
	;
	call	TextCheckCanDraw
	jc	quit

	clr	dl				; No DrawFlags
	mov	cx, ss:[bp].LICL_region		; cx <- region
	call	TR_RegionTransformGState	; Update the gstate
	
	call	TR_RegionClearToBottom		; Clear the area
quit:
	.leave
	ret
ClearToRegionBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RippleToNextRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ripple the current line to the next region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
RETURN:		cx	= Previous lines flags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RippleToNextRegion	proc	near
	uses	ax, bx, dx, di
	ProfilePoint 44
	.enter
	;
	; Move to next region.
	;
	mov	dx, ss:[bp].LICL_lineFlags	; dx <- non-zero for next section
	and	dx, mask LF_ENDS_IN_SECTION_BREAK

	mov	cx, ss:[bp].LICL_region		; cx <- current region
	call	TR_RegionMakeNextRegion		; cx <- next region
if _REGION_LIMIT
	jc	done
endif
		
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- new first line
	call	TR_RegionSetTopLine		; Save new first line
	
	movdw	dxax, ss:[bp].LICL_lineStart
	call	TR_RegionSetStartOffset		; Save new start offset
	
	movdw	ss:[bp].LICL_range.VTR_start, dxax
	mov	ss:[bp].LICL_region, cx		; Save new region

	;
	; Save the cached region values.
	;
	movdw	ss:[bp].LICL_regionTopLine, bxdi
	call	GetNextTopLine			; Update cached value

	call	TR_RegionGetTrueHeight		; dx.al <- region height
	movwbf	ss:[bp].LICL_regionTrueHeight, dxal
	
	;
	; If the line that we just computed has changed, since we will be
	; computing it again for the next region, we want to remove it from
	; the count of lines that changed.
	;
	test	ss:[bp].LICL_calcFlags, mask CF_LINE_CHANGED
	jz	noCountChange

	or	ss:[bp].LICL_calcFlags, mask CF_FORCE_CHANGED
	dec	ss:[bp].LICL_linesToDraw
noCountChange:
	
	;
	; Get the flags for the previous line.
	;
	TL_LinePrevSkipCheck			; bx.di <- previous line
	call	TL_LineGetFlags			; ax <- Previous LineFlags
	mov	cx, ax				; cx <- Previous LineFlags

if _REGION_LIMIT		

	clc
done:

endif 
	.leave
	ProfilePoint 43
	ret
RippleToNextRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFractionalYScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the window we are drawing to has a y-scaling
		factor that is not an integer.

CALLED BY:	TextMakeSpace
PASS:		*ds:si	= instance ptr.
RETURN:		carry set if the y scaling is not an integer.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFractionalYScale	proc	near
	call	Text_PushAll
	push	ds

	call	TextCheckCanDraw	; Skip this step if we can't draw anyway
	jc	quit

	call	Text_GState_DI		; di <- gstate
	sub	sp, size TransMatrix	; That's how much space we need
	mov	si, sp
	segmov	ds, ss			; ds:si <- place to put matrix info
	call	WinGetTransform		; Get the transformation matrix

	;
	; Now that we have the scaling in Y on the stack we want to look at
	; it and see if there is any fraction.
	;
	tst	ds:[si].TM_e22.WWF_frac	; Clears the carry
	jz	done			; Quit with carry clear if no fraction
	stc				; There was a fraction, return flag

done:
	lahf				; Save carry
	add	sp, size TransMatrix	; Restore stack
	sahf				; Restore carry

quit:
	pop	ds
	call	Text_PopAll
	ret
CheckFractionalYScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddHeightIfFromLaterRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the height of the current line if the line is from a
		region beyond the current one.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
RETURN:		carry set if line came from later region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddHeightIfFromLaterRegion	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	movdw	bxdi, ss:[bp].LICL_line		; Compare to next region top
	cmpdw	bxdi, ss:[bp].LICL_nextRegionTopLine
	jb	quitNotFromLater		; Branch if not in later region
	
	;
	; The line is from a later region. Add the height to insertedSpace.
	;
	call	TL_LineGetHeight		; dx.bl <- height
	clr	bh
	xchg	bl, bh				; dx.bx <- height
	clr	ax				; ax.dx.bx <- height

	adddwf	ss:[bp].LICL_insertedSpace, axdxbx

	incdw	ss:[bp].LICL_rippleCount
	subdwf	ss:[bp].LICL_rippleHeight, axdxbx ; Update the rippled line hgts

	;
	; We don't need to force a change if this line falls before the
	; change.
	;
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	cmpdw	dxax, ss:[bp].LICL_startPos
	jb	quitWithRecalc			; Branch if before change

	or	ss:[bp].LICL_calcFlags, mask CF_FORCE_CHANGED

quitWithRecalc:
	stc					; Signal: from later region

quit:
	.leave
	ret

quitNotFromLater:
	clc					; Signal: not from later region
	jmp	quit
AddHeightIfFromLaterRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next line, using cached values.

CALLED BY:	InsertOrDeleteLines, NextLineCreateIfNeeded, TruncateLines
PASS:		ss:bp	= LICL_vars
		bx.di	= Line
RETURN:		carry clear if the line exists
		    bx.di = Next line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLineNext	proc	near
	cmpdw	bxdi, ss:[bp].LICL_lineCount
	jae	noNextLine

	incdw	bxdi				; Move to next line
	clc					; Signal: line does exist

quit:
	ret

noNextLine:
	stc					; Signal: line doesn't exist
	jmp	quit
CalcLineNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCachedValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff some values into the LICL_vars so we don't make
		redundant calls in order to get them.

CALLED BY:	CalculateRegions
PASS:		ss:bp	= LICL_vars
		*ds:si	= Instance
RETURN:		Set:	LICL_lineCount
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCachedValues	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	;
	; Get the total number of lines so we can implement our own "line-next"
	; function.
	;
	call	TL_LineGetCount			; dx.ax <- line count
	decdw	dxax				; Make it zero based
	movdw	ss:[bp].LICL_lineCount, dxax	; Save the count
	.leave
	ret
GetCachedValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGroupedLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle lines/paragraphs which are grouped together.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		bx.di	= Last line calculated
RETURN:		bx.di	= Line to ripple (among other things)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Setup everything necessary if lines are being grouped due to
	widow/orphan control and any options to keep paragraphs together.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGroupedLines	proc	near
	;
	; Check for rippling the first line of a paragraph. If we are then
	; we need to check/handle the case where the previous paragraph needs
	; to be kept with this one.
	;
	test	ss:[bp].LICL_lineFlags, mask LF_STARTS_PARAGRAPH
	jnz	handleGroup

	;
	; Check for any of the explicit things we need to deal with.
	;
	test LICL_paraAttr.VTPA_attributes, mask VTPAA_KEEP_PARA_TOGETHER \
					 or mask VTPAA_KEEP_LINES
	jz	quit

handleGroup:
	;
	; Pop into a different resource to actually handle this stuff.
	;
	call	HandleGroupedLines
quit:
	ret
CheckGroupedLines	endp

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateTotals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the various totals...

CALLED BY:	CalculateRegions
PASS:		*ds:si	= instance
		ss:bp	= Stack frame
RETURN:		nothing (flags preserved)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The assumption is that the sum of the following values:
		cached region heights
		inserted space
		deleted space
		ripple height

	will be the same as the sum of all the line heights. The reasoning
	works like this...
	
	When we start out, the inserted/deleted/rippled heights are all
	zero. At this point we do know that:
		sum of cached region heights == sum of line heights
	In fact we check this.
	
	As time goes on we accumulate changes in the line-heights into
	the insertedSpace. We accumulate deletions into deletedSpace.
	This means that before we update the cached heights
		sum cached heights + insertedSpace - deletedSpace
				==
		sum of line heights

	The only special situation is where insertedSpace reflects lines
	which have been rippled backwards. In this case those lines have
	been inserted in the current region, but removed from a later
	region. We handle this by factoring in the rippleHeight.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateTotals	proc	far
	uses	ax, bx, cx, dx, di, bp
	pushf
sumCachedHeights	local	DWFixed
sumLineHeights		local	DWFixed
totalOfStuff		local	DWFixed
	.enter
	
	call	ECCheckTextEC		; Check for doing text EC code
	LONG jnc quit			; Branch if not

	;
	; Compute the total of all the cached region heights
	;
	clrdwf	sumCachedHeights	; No height so far
	clr	cx			; cx <- current region
regionLoop:
	call	TR_RegionGetHeight	; dx.al <- computed height
	mov	al, ah			; dx.ax <- computed height
	clr	al
	clr	bx			; bx.dx.ax <- computed height
	
	adddwf	sumCachedHeights, bxdxax

	call	TR_RegionNext		; cx <- next region
	jnc	regionLoop		; Loop if there is another

;----------------------------------------
	;
	; Compute the sum of the line heights
	;
	clrdw	bxdi			; bx.di <- first line
	call	TL_LineGetCount		; dx.ax <- # of lines
	clr	cx			; No flags
	call	TL_LineSumAndMarkRange	; cx.dx.ax <- sum of line heights
	
	movdwf	sumLineHeights, cxdxax

;----------------------------------------
	;
	; Figure:	sum cached heights + insertedSpace - deletedSpace
	;
	mov	bx, ss:[bp]		; ss:bx <- LICL_vars
	
	movdwf	totalOfStuff, sumCachedHeights, ax
	adddwf	totalOfStuff, ss:[bx].LICL_insertedSpace, ax
	subdwf	totalOfStuff, ss:[bx].LICL_deletedSpace, ax
	adddwf	totalOfStuff, ss:[bx].LICL_rippleHeight, ax

	;
	; And now the check...
	;	
	cmpdwf	totalOfStuff, sumLineHeights, ax
;;;	ERROR_NZ SUM_OF_VARIOUS_HEIGHTS_IS_NOT_RIGHT
quit:
	.leave
	popf
	ret
ECValidateTotals	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateRegionAndLineHeights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the sum of the line heights is the same as the
		sum of the region heights.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
RETURN:		nothing (even flags are preserved)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateRegionAndLineHeights	proc	far
	uses	ax, bx, cx, dx, di, bp
	pushf
	.enter
	
;;;	call	ECCheckTextEC			; Check for doing text EC code
;;;	jnc	quit				; Branch if not

	clr	cx				; cx <- current region
regionLoop:
;-----------------------------------------------------------------------------
	call	ECValidateSingleRegion		; Check this region
	call	TR_RegionNext			; cx <- next region
	jnc	regionLoop			; Loop if there is another

quit::
	.leave
	popf
	ret
ECValidateRegionAndLineHeights	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECFixupRegionAndLineHeights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the sum of the line heights is the same as the
		sum of the region heights.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
RETURN:		nothing (even flags are preserved)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECFixupRegionAndLineHeights	proc	far
	uses	ax, bx, cx, dx, di, bp
	pushf
	.enter
	
	clr	cx				; cx <- current region
regionLoop:
	call	ECFixupSingleRegion		; Fix this region
	call	TR_RegionNext			; cx <- next region
	jnc	regionLoop			; Loop if there is another

quit::
	.leave
	popf
	ret
ECFixupRegionAndLineHeights	endp

ForceRef ECFixupRegionAndLineHeights


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECFixupSingleRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixup a single region, passed in cx.

CALLED BY:	ECFixupRegionAndLineHeights
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		nothing
DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECFixupSingleRegion	proc	far
	uses	ax, bx, cx, dx, di, bp
	pushf
	.enter
	push	cx				; Save region
	call	TR_RegionGetTopLine		; bx.di <- first line
	call	TR_RegionGetLineCount		; cx <- # of lines
	jcxz	noLinesInRegion			; Branch if there are none
	
	;
	; Sum the range of lines from bx.di to (but not including) bx.di+cx
	;
	clr	dx				; dx.ax <- # of lines
	mov	ax, cx
	adddw	dxax, bxdi			; dx.ax <- end of range
	clr	cx				; No flags to set
	call	TL_LineSumAndMarkRange		; cx.dx.ax <- sum of line heights

gotLineSum:
	;
	; cx.dx.ax = Sum of line heights in this region. Since a region can't
	;	     be >64K points high, cx will always be zero here.
	;
	pop	cx				; cx <- region

	;
	; Get the regions computed height and compute the difference.
	;
	movwbf	bpbl, dxah			; Save sum of line hgts in bp.bl
	call	TR_RegionGetHeight		; dx.al <- computed height
	
	;
	; Adjust the region height...
	;
	subwbf	bpbl, dxal			; bp.bl <- difference
	movwbf	dxal, bpbl			; dx.al <- amount of change
	call	TR_RegionAdjustHeight		; Adjust the height

	.leave
	popf
	ret


noLinesInRegion:
	clr	cx				; Simulate a sum of no lines
	clr	dx
	clr	ax
	jmp	gotLineSum
ECFixupSingleRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateSingleRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a single region, passed in cx.

CALLED BY:	ECValidateRegionAndLineHeights
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		nothing
DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateSingleRegion	proc	far
	uses	ax, bx, cx, dx, di, bp
	pushf
	.enter
	push	cx				; Save region
	call	TR_RegionGetTopLine		; bx.di <- first line
	call	TR_RegionGetLineCount		; cx <- # of lines
	
	push	cx				; Save # of lines
	jcxz	noLinesInRegion			; Branch if there are none
	
	;
	; Sum the range of lines from bx.di to (but not including) bx.di+cx
	;
	clr	dx				; dx.ax <- # of lines
	mov	ax, cx
	adddw	dxax, bxdi			; dx.ax <- end of range
	clr	cx				; No flags to set
	call	TL_LineSumAndMarkRange		; cx.dx.ax <- sum of line heights

gotLineSum:
	;
	; cx.dx.ax = Sum of line heights in this region. Since a region can't
	;	     be >64K points high, cx will always be zero here.
	;
;;;
;;; This code removed,  2/21/93 -jw
;;;
;;; The problem is that there is this temporary situation that can occur
;;; where many lines are accumulated in a single page before recalculation.
;;; In this case the sum can be >64K.
;;;
;;;	tst	cx
;;;	ERROR_NZ LINE_SUM_GREATER_THAN_32_BITS_CAN_HOLD
	pop	bx				; bx <- # of lines
	pop	cx				; cx <- region

;-----------------------------------------------------------------------------
	push	bx				; Save # of lines

	;
	; Get the regions computed height and check to see if it is the same
	; as the sum of the line heights.
	;
	movwbf	bpbl, dxah			; Save sum of line hgts in bp.bl
	call	TR_RegionGetHeight		; dx.al <- computed height
	
	cmpwbf	dxal, bpbl
	ERROR_NZ SUM_OF_LINE_HGTS_IN_REGION_DOES_NOT_MATCH_STORED_COMPUTED_HGT
	
	;
	; Check to see if the computed height is greater than the region height.
	; If it is, then the region can only contain a single line.
	;
	call	TR_RegionGetTrueHeight		; dx.al <- region height
	cmpwbf	bpbl, dxal			; Compare computed against real
	pop	bx				; bx <- # of lines
	jbe	heightOK

;;;
;;; This code removed,  9/ 4/92 -jw
;;;
;;; GeoWrite, when changing the page setup, accumulates all of the line heights
;;; into a single region and then recalculates in order to ripple the text.
;;; This ec code generates a bogus error in that situation.
;;; 
if	0
	;
	; The computed height is greater than the region height. The line count
	; *must* be one.
	;
	cmp	bx, 1
	ERROR_NZ MULTIPLE_LINE_HGTS_IN_REGION_GREATER_THAN_REGION_HGT
endif
heightOK:
	
	.leave
	popf
	ret


noLinesInRegion:
	clr	cx				; Simulate a sum of no lines
	clr	dx
	clr	ax
	jmp	gotLineSum
ECValidateSingleRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidatePreviousRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the previous region, which we assume is in good shape.

CALLED BY:	CalculateRegions
PASS:		ss:bp	= LICL_vars w/ LICL_region set
RETURN:		nothing
DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidatePreviousRegion	proc	far
	pushf
	push	cx
	mov	cx, ss:[bp].LICL_region
	jcxz	quit
	dec	cx
	call	ECValidateSingleRegion
quit:
	pop	cx
	popf
	ret
ECValidatePreviousRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckTextEC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we should do text EC code.

CALLED BY:	
PASS:		nothing
RETURN:		carry set if we want to do text EC
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckTextEC	proc	far
	uses	ax, bx
	.enter
	call	SysGetECLevel			; ax <- EC flags, bx nuked
	
	test	ax, mask ECF_TEXT		; Clears the carry
	jz	quit				; Branch if not doing EC
	stc					; Signal: Do EC
quit:
	.leave
	ret
ECCheckTextEC	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateRegionCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the char/line counts associated with the regions.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
RETURN:		nothing
DESTROYED:	nothing (preserves flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateRegionCounts	proc	far
	uses	ax, bx, cx, dx, di, bp
	pushf
charSum		local	dword
lineSum		local	dword
	.enter

	call	ECCheckTextEC			; Check for doing text EC code
	LONG jnc quit				; Branch if not

	clrdw	charSum				; Initialize the counters
	clrdw	lineSum

	;
	; Sum the line and character counts
	;
	clr	cx				; cx <- current region
regionLoop:
	push	cx				; Save region
	call	TR_RegionGetCharCount		; dx.ax <- # of characters
	adddw	charSum, dxax			; Update character count
	ERROR_C	SUM_OF_REGION_CHARS_IS_GREATER_THAN_32_BITS_CAN_HOLD

	call	TR_RegionGetLineCount		; cx <- # of lines
	add	lineSum.low, cx			; Update line count
	adc	lineSum.high, 0
	ERROR_C	SUM_OF_REGION_LINES_IS_GREATER_THAN_32_BITS_CAN_HOLD
	
	pop	cx				; Restore region
	call	TR_RegionNext			; cx <- next region
	jnc	regionLoop			; Loop if there is one
	
	;
	; Make sure the counts are OK
	;
	call	TL_LineGetCount			; dx.ax <- line count
	cmpdw	lineSum, dxax
	ERROR_NZ SUM_OF_REGION_LINES_IS_NOT_SAME_AS_LINE_COUNT
	
	call	TS_GetTextSize			; dx.ax <- character count
	cmpdw	charSum, dxax
	ERROR_NZ SUM_OF_REGION_CHARS_IS_NOT_SAME_AS_CHAR_COUNT

quit:
	.leave
	popf
	ret
ECValidateRegionCounts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateRegionAndLineCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the number of characters stored in a region
		is the same as the total of the characters in the lines of
		that region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateRegionAndLineCounts	proc	far
	uses	ax, bx, cx, dx, di, bp
region		local	word
regChars	local	dword
regLineChars	local	dword
	pushf
	.enter
	call	ECCheckTextEC			; Check for doing text EC code
	LONG jnc quit				; Branch if not

	clr	region				; Current region

regionLoop:
	mov	cx, region			; cx <- region
	
	call	TR_RegionGetCharCount		; dx.ax <- # of characters
	movdw	regChars, dxax			; Save the count

	call	TR_RegionGetTopLine		; bx.di <- first line in region

	call	TR_RegionGetLineCount		; cx <- # of lines in region
	jcxz	checkForNothing			; Check for having no lines

;--------------
	clrdw	regLineChars			; Start with nothing...
regCharLoop:
	;
	; bx.di	= Current line
	; regLineChars = Total so far in this region
	; cx	= Number of lines left to process
	;
	call	TL_LineGetCharCount		; dx.ax <- # of chars in line
	adddw	regLineChars, dxax		; Update the total

	call	TL_LineNext			; bx.di <- next line
	loop	regCharLoop			; Loop until done with region
;--------------

	;
	; All done with this region.
	; regChars = Total from the region code
	; regLineChars = Total computed by adding up the line counts
	;
	cmpdw	regLineChars, regChars, ax	; Compare the total to the region
	ERROR_NZ SUM_OF_REGION_LINE_CHARS_IS_NOT_SAME_AS_REGION_CHARS

lineCharsAddUp:

	mov	cx, region
	call	TR_RegionNext			; cx <- next region
	mov	region, cx
	jnc	regionLoop			; Loop if there are more
quit:
	.leave
	popf
	ret


checkForNothing:
	;
	; A region with no lines should have no characters.
	;
	tstdw	regChars
	ERROR_NZ REGION_WITH_NO_LINES_SHOULD_HAVE_NO_CHARACTERS
	jmp	lineCharsAddUp

ECValidateRegionAndLineCounts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateLineStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that all the line structures accurately reflect
		the true contents of the line.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance pt
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateLineStructures	proc	far
	uses	bx, di
	pushf
	.enter

	call	ECCheckTextEC			; Check for doing text EC code
	jnc	quit				; Branch if not

	;
	; Start at the start and call the EC code for each line
	;
	clrdw	bxdi			; bx.di <- first line
lineLoop:
	call	ECValidateSingleLineStructure
	
	call	TL_LineNext
	jnc	lineLoop

quit::
	.leave
	popf
	ret
ECValidateLineStructures	endp



endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CeilingDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the ceiling of a DWFixed value.

CALLED BY:	Utility
PASS:		ss:ax	= Pointer to the value
RETURN:		ax	= Ceiling of the value
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if value > LARGEST_BLT_VALUE then
	    ceiling = LARGEST_BLT_VALUE
	else if value < -LARGEST_BLT_VALUE then
	    ceiling = -LARGEST_BLT_VALUE
	else
	    ceiling = ceilwwf (int.low, frac)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CeilingDWFixed	proc	near
	uses	bx, cx, bp
	.enter
	mov	bp, ax				; ss:bp <- value
	
	clr	cx
	mov	ax, LARGEST_BLT_VALUE		; cx.ax.bx <- LARGEST_BLT_VALUE
	clr	bx

	jgedwf	ss:[bp], cxaxbx, useLBV

	negdwf	cxaxbx				; cx.ax.bx <- -1 * LBV
	jledwf	ss:[bp], cxbxax, useNegLBV

	mov	ax, ss:[bp].DWF_int.low
	mov	bp, ss:[bp].DWF_frac
	
	tst	bp
	jz	quit
	inc	ax

quit:
	.leave
	ret

useLBV:
	mov	ax, LARGEST_BLT_VALUE
	jmp	quit

useNegLBV:
	mov	ax, -1 * LARGEST_BLT_VALUE
	jmp	quit
CeilingDWFixed	endp


Text ends

;-----------------------------------

TextRegion segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRegionHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the height of a region.

CALLED BY:	CalcLineBottomAndRegion
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		dx.al	= Height of the region (bottom of last line)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	There is *always* a "next" region when this routine is called.
	The current region always has at least one line in it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRegionHeight	proc	far
	uses	bx, cx, di
	.enter
EC <	call	AssertIsLargeObject					>

	call	TR_RegionGetTopLine	; bx.di <- first line
	call	TR_RegionGetLineCount	; cx <- number of lines
	
	jcxz	noLines			; Branch if no lines
	dec	cx			; Make it zero-based
	
	add	di, cx			; bx.di <- last line
	adc	bx, 0
	
	call	TL_LineGetBottom	; dx.bl <- bottom of last line
	mov	al, bl			; dx.al <- bottom of last line

quit:
	.leave
	ret

noLines:
	;
	; No lines? The height must be zero.
	;
	clrwbf	dxal
	jmp	quit
GetRegionHeight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveHeightOfRippledLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the heights of lines we are rippling forward by
		removing those heights from the insertedSpace.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
RETURN:		LICL_insertedSpace set for current region
		LICL_rippleHeight set for later regions
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We are adjusting the inserted space to account for lines which are
	being rippled. The assumption here is that the current line will
	become the first line in the next region.
	
	There are three cases to handle:
		- Lines are being rippled backwards
		- Lines are being rippled forwards
		- Nothing is being rippled

	No matter what happens, the combination of the insertedSpace and
	the rippleHeight at this moment indicate the amount of change
	in the total object during the last calculation.
	
	When this routine returns we want the insertedSpace to indicate
	the change in the current segment, while the rippleHeight indicates
	the change in future segments.
	
	1) Lines being rippled backwards
	    In this case we know that the line which overflowed (the current
	    line) came from a later region. In this case the insertedSpace
	    will have had the oldLineHeight added to it, and the difference
	    between the old and new line heights also added to it. We adjust
	    for shuffling the line forward:
		curInsSpace = insSpace - oldLH - (newLH - oldLH)
		curInsSpace = insSpace - newLH

	2) Lines being rippled forward
	    This is really easy... The inserted space doesn't change, but
	    we set the 'deletedSpace' for the bottom of the region to the
	    sum of the heights of the lines we remove.

	3) Nothing rippled
	    This really isn't "nothing rippled". It's really that the last
	    line we computed overflowed and needs to be rippled forward, except
	    that the line already came from the later region. This has the
	    same result for the current insertedSpace value:
		curInsSpace = insSpace - newLH

	For all of these, the rippleHeight (change from later regions) is
	adjusted by the difference between the original insSpace and the
	new value.

	This can always be done at the end of the routine. The new 
	rippleHeight is:
		newRH = RH + (insSpace - curInsSpace) + delSpace

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version
	JDM	93.02.15	push-/pob-wbf modifications.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveHeightOfRippledLines	proc	far
	uses	ax, bx, cx, dx, di
	.enter
	pushdwf	ss:[bp].LICL_insertedSpace

	movdw	bxdi, ss:[bp].LICL_nextRegionTopLine
	
	cmpdw	bxdi, ss:[bp].LICL_line		; Compare nr.start, line
	LONG je	rippleJustOne			; Branch if same as start
	LONG jb	rippleRangeBackwards		; Ripple backwards
	
	;
	; Rippling lines forward.
	;
	; Compute the height of the range LICL_line==>reg.topLine
	;
	movdw	dxax, ss:[bp].LICL_line		; dx.ax <- start of range
	xchgdw	bxdi, dxax			; bx.di <- start
						; dx.ax <- end
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Added  4/19/93 -jw
;
; This will ensure that we also compute the line that used to be the first
; line of the next region. This fixes a problem where we insert lines, ripple
; forward, and then don't compute the old first line of the region we ripple
; into. This would normally not be a problem, unless of course the line starts
; a paragraph, and that paragraph had "space above" (which is not applied when
; it is the first line of a region, but is when it is not).
;
; This may result in the unnecessary recalculation and redraw of a line in
; the region we're rippling into, but since we are clearly rippling other
; lines into that region, it doesn't seem like that big a deal.
;
	push	ax, bx, dx, di
	movdw	bxdi, dxax			; bx.di <- 1st line of next reg

	;
	; Check for the line not really existing...
	;
	cmpdw	bxdi, ss:[bp].LICL_lineCount	; Check for no such line
	ja	skipMark

	;
	; Line exists, mark it.
	;
	mov	ax, mask LF_NEEDS_CALC
	clr	dx
	call	TL_LineAlterFlags		; Force next to draw

skipMark:
	pop	ax, bx, dx, di
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
						; Force calculation and draw
	mov	cx, mask LF_NEEDS_DRAW or mask LF_NEEDS_CALC
	call	TL_LineSumAndMarkRange		; cx.dx.ax <- sum of heights

	adddwf	ss:[bp].LICL_deletedSpace, cxdxax

forceRedraw:
	mov	ss:[bp].LICL_linesToDraw, 2
	
RHORL_quit label near
	;
	; Adjust the rippleHeight by the amount of change in the inserted
	; space.
	;
	adddwf	ss:[bp].LICL_rippleHeight, ss:[bp].LICL_deletedSpace, ax
	subdwf	ss:[bp].LICL_rippleHeight, ss:[bp].LICL_insertedSpace, ax

	popdwf	bxdxax				; bx.dx.ax <- old inserted space
	adddwf	ss:[bp].LICL_rippleHeight, bxdxax

	.leave
	ret


rippleJustOne:
	;
	; We can only arrive at this point if the line that we just computed
	; was the first line in the next region.
	;
	; This has a few implications for the insertedSpace variable:
	;	- The height was added to the inserted space in the routine
	;	  AddHeightIfFromLaterRegion. This was a mistake that we
	;	  need to correct here.
	;
	;	- The height added to the insertedSpace was the old
	;	  line height.
	;
	;	- The insertedSpace has reflected a change in the line height
	;	  and since this change really belongs to the next region
	;	  we need to remove it from the current one and supply it
	;	  as the change in the next region.
	;
	; Adjust the insertedSpace for this region.
	;	newIS = oldIS - oldLineHeight - (newLineHeight - oldLineHeight)
	;	newIS = oldIS - newLineHeight
	;
	clr	bx				; bx.dx.ax <- line height
	movwbf	dxah, ss:[bp].LICL_lineHeight
	clr	al

	subdwf	ss:[bp].LICL_insertedSpace, bxdxax
	jmp	RHORL_quit

rippleRangeBackwards:
	;
	; Rippling lines backwards. We don't actually need to mark the lines
	; as needing to be drawn since this will have already been done
	; by AddHeightIfFromLaterRegion. We also don't need to know the total
	; of the line-heights because this has already been computed.
	;
	; The inserted space has been adjusted to include the line that
	; rippled. This is not correct. We handle this in much the same
	; way that we handled it in the 'rippleJustOne' case above.
	;
	; Adjust the insertedSpace for this region.
	;	newIS = oldIS - oldLineHeight - (newLineHeight - oldLineHeight)
	;	newIS = oldIS - newLineHeight
	;
	clr	bx				; bx.dx.ax <- line height
	movwbf	dxah, ss:[bp].LICL_lineHeight
	clr	al

	subdwf	ss:[bp].LICL_insertedSpace, bxdxax
	jmp	forceRedraw

RemoveHeightOfRippledLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleRippledLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle lines which may have been rippled backwards into what
		is now the last region.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		bx.di	= Last line calculated
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleRippledLines	proc	far
	uses	ax, bx, cx, dx, di
	ProfilePoint 42
	.enter
	mov	cx, ss:[bp].LICL_region	; cx <- current region
	call	TR_RegionNext		; cx <- next region
	jc	HRL_quit		; Branch if no next region

	incdw	bxdi			; Force next region to have no lines
	call	TR_RegionSetTopLine	; Set top line of next region
	
	movdw	dxax, ss:[bp].LICL_range.VTR_start
	call	TR_RegionSetStartOffset
HRL_quit label near
	.leave
	ProfilePoint 41
	ret
HandleRippledLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceRedrawOfLinesInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cause the lines that couldn't be blt'd to be redrawn.

CALLED BY:	UpdateSegment
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars structure on stack
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceRedrawOfLinesInRegion	proc	far
	class	VisLargeTextClass
	uses	ax, bx, cx, dx, di, bp
	.enter
	call	TextCheckCanDraw	; Skip this step if we can't draw anyway
	LONG jc	quit

	;
	; If we are in a large text object, and if we are in galley or
	; condensed mode, we need to invalidate the window, because there
	; are lines in other regions which will be affected by this.
	;
	call	TextRegion_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	normalStuff
	cmp	ds:[di].VLTI_displayMode, VLTDM_GALLEY
	jb	normalStuff
	
	;
	; Sigh, we need to invalidate the area below us.
	;
	clr	ax				; ax <- left
	ceilwbf	ss:[bp].LICL_lineBottom, bx	; bx <- top
	mov	cx, LARGEST_BLT_VALUE		; cx <- right
	mov	dx, LARGEST_BLT_VALUE		; dx <- bottom
	
	mov	di, ds:[di].VTI_gstate		; di <- gstate to use
	call	GrInvalRect			; Invalidate the area
	jmp	quit

normalStuff:
	ceilwbf	ss:[bp].LICL_lineBottom, bx	; bx <- Start of range

	mov	cx, ss:[bp].LICL_region		; cx <- region
	mov	dx, bx				; dx <- Start of range
	push	bx
	clr	bx				; get for blt'ing
	call	TR_RegionNextSegmentTop		; dx <- End of range
	pop	bx

	;
	; Figure the first line in the region that needs redrawing.
	;
	xchg	bx, dx			; dx <- start of range
					; bx <- end of range

	push	bx			; Save end of range
					; dx holds start of range
	clr	ax			; ax <- X position
	call	TL_LineFromPosition	; bx.di <- first line
					; carry set if position below last line
	pop	dx			; dx <- end of range
	
	jc	quit			; Branch if no lines are in range

	;
	; Figure the last line in the region that needs redrawing.
	;
	pushdw	bxdi			; Save first line in region
	call	TL_LineFromPosition	; bx.di <- last line
	movdw	dxax, bxdi		; dx.ax <- last line
	incdw	dxax			; Mark past this line
	popdw	bxdi			; dx.ax <- first line
	
	mov	cx, mask LF_NEEDS_DRAW	; Set this flag
	call	TL_LineSumAndMarkRange	; cx.dx.ax <- sum of heights
					;   (which we ignore :-)
quit:
	.leave
	ret
ForceRedrawOfLinesInRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGroupedLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle lines/paragraphs which are grouped together.

CALLED BY:	CheckGroupedLines
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
RETURN:		bx.di	= Line to ripple (if any)
		carry set if a ripple of some sort is required
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGroupedLines	proc	far
	uses	ax, cx
	.enter
	movdw	bxdi, ss:[bp].LICL_line
resolutionLoop:
	;
	; We use cx to hold a sort of cumulative flag which indicates whether
	; or not any change was made as a result of the various handlers
	;
	mov	cx, -1

	;
	; Orphan Control
	;
	call	HandleGeneratedOrphan
	jc	noOrphanChange
	clr	cx
noOrphanChange:

	;
	; Keep This Paragraph Together
	;
	call	KeepParagraphTogether

	;
	; Keep Lines Together (Widow Control)
	;
	call	KeepLinesTogether

	;
	; Keep with Next
	;
	call	HandleKeepWithNext
	jc	noKWNChange
	clr	cx
noKWNChange:

	jcxz	resolutionLoop			; Loop if anything changed

	;
	; Set up to ripple
	;
	call	FigureRippleValues		; Carry set if no ripple
	.leave
	ret
HandleGroupedLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGeneratedOrphan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an orphan generated as a result of shuffling stuff
		around to resolve line-grouping problems.

CALLED BY:	HandleGroupedLines
PASS:		*ds:si	= Instance
		bx.di	= Line to resolve from
		ss:bp	= LICL_vars w/
				Attributes set for the paragraph containing
				    this line.
				LICL_regionTopLine set
RETURN:		carry set if no ripple is required
		carry clear if a ripple is required
		    bx.di	= Line to ripple forward (if any)
		    LICL_vars w/
			Attributes set for the paragraph containing the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	An orphan can only be generated when we ripple forward the last line
	of the previous paragraph as part of keeping paragraphs together.
	
	Any other operation results in an entire paragraph being rippled forward
	and this can never result in an orphan.
	
	This means that if <bx.di> does not end a paragraph, then we don't
	need to do anything.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGeneratedOrphan	proc	near
	uses	ax, cx, dx
	.enter
	pushdw	bxdi				; Save original line

	;
	; Check to see if an orphan is even possible.
	;
	clr	ax				; ax <- orphan count
	ExtractField byte, LICL_paraAttr.VTPA_keepInfo, VTKI_BOTTOM_LINES, al
	inc	ax

	;
	; Make sure that the current line isn't the first in the region.
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	je	abort				; Branch if it is

	;
	; Check to see if we are rippling forward a paragraph ending line
	;
	call	TL_LineGetFlags			; ax <- LineFlags
	test	ax, mask LF_ENDS_PARAGRAPH
	jz	abort				; Branch if we are

	;
	; An orphan may exist. We are rippling forward a single line and the
	; orphan count is non-zero.
	;
	; If the paragraph containing the orphan is smaller than the orphan
	; count, we just ripple the whole thing forward.
	;
	clr	ax				; ax <- orphan count
	ExtractField byte, LICL_paraAttr.VTPA_keepInfo, VTKI_BOTTOM_LINES, al
	inc	ax
	
	movdw	dxcx, bxdi			; dx.cx <- Original line
	call	SkipToParaStart			; bx.di <- Start of paragraph
	
	;
	; Make sure that the paragraph is in this region so we could ripple it
	; if we wanted to.
	;
	subdw	dxcx, bxdi			; dx.cx <- # of lines in para
	tstdw	dxcx
	jz	abort

	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	jbe	ripplePartialParagraph
	
	tst	dx				; Check for >64K
	jz	ripplePartialParagraph
	cmp	cx, ax				; Compare against orphan count
	jbe	gotRippleLine			; Branch if paragraph is small

ripplePartialParagraph:
	;
	; We can't ripple the entire paragraph. We can only do part of it.
	;
	; dx.cx	= # of lines in paragraph before original line
	; bx.di	= Start of paragraph
	; ax	= Orphan count
	;
	; If para attrs for the first line of the paragraph indicates the entire
	; paragraph must remain together, then use the start of the paragraph
	; as the line to ripple -- ardeb 3/9/94
	; 
	push	ax, dx
	call	TL_LineToOffsetStart
	call	T_GetParaAttrAttributes
	test	ax, mask VTPAA_KEEP_PARA_TOGETHER
	pop	ax, dx
	jnz	maybeGotRippleLine

	adddw	bxdi, dxcx			; bx.di <- original line
	sub	di, ax				; bx.di <- Line to ripple
	sbb	bx, 0

maybeGotRippleLine:
	;
	; Make sure the line we want to ripple is in this region
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	ja	gotRippleLine			; Branch if it's possible
	
	;
	; We can't ripple as much as we want. Ripple as much as we can.
	;
	movdw	bxdi, ss:[bp].LICL_regionTopLine
	call	TL_LineNext			; bx.di <- Line to ripple

gotRippleLine:
	;
	; bx.di	= Line to ripple forward
	; On stack:
	;	Original line we were going to ripple.
	;
	; If the line to ripple hasn't changed, then we should signal that
	; no change has occurred.
	;
	popdw	dxax				; dx.ax <- original value
	cmpdw	bxdi, dxax			; Compare to original
	je	failNoChange
	
;;; THIS DOESN'T ACTUALLY *DO* ANYTHING -- ardeb 3/9/94
;;;	call	SetParaAttributesForLine	; Set para attributes
	
	clc					; Signal: Resolve not finished

;-----------------------------------------------------------------------------

quit:
	;
	; carry set if rippling isn't possible.
	; bx.di	= Line to ripple forward
	;
	.leave
	ret


abort:
	add	sp, size dword			; Restore stack

failNoChange:
	stc					; Signal: no ripple required
	jmp	quit
HandleGeneratedOrphan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeepParagraphTogether
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep this paragraph in one piece.

CALLED BY:	HandleGroupedLines
PASS:		*ds:si	= Instance
		bx.di	= Line to resolve from
		ss:bp	= LICL_vars w/
				Attributes set for the paragraph containing
				    this line
				LICL_regionTopLine set
RETURN:		carry set if no ripple is required
		carry clear if a ripple is required
		    bx.di	= Line to ripple forward (if any)
		    LICL_vars w/
			Attributes set for the paragraph containing the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	/*
	 * Find current paragraph start
	 */
	while (! line.flags & LF_STARTS_PARAGRAPH) {
	    line--
	}
	... set up stuff so that we ripple first line of current paragraph
	    forward so the paragraph stays together ...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeepParagraphTogether	proc	near
	uses	ax, dx
	.enter
	pushdw	bxdi				; Save initial line

	;
	; Check for no flag requiring this operation
	;
	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_KEEP_PARA_TOGETHER
	jz	abort

	;
	; Find current paragraph start
	;
	movdw	dxax, bxdi			; dx.ax <- current line

	call	SkipToParaStart			; bx.di <- current para start
	cmpdw	dxax, bxdi			; Check for no change
	je	abort				; Branch if at para start
	
	;
	; Check for not in this region
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	jbe	abort
	
	;
	; The start of the previous paragraph is in this region and it is not
	; the first line in this region. Ripple forward from there.
	;
	add	sp, size dword			; Restore the stack

	call	SetParaAttributesForLine	; Set para attributes
	
	clc					; Signal: ripple is required
	
quit:
	.leave
	ret


abort:
	popdw	bxdi				; Restore initial line
	stc					; Signal: no ripple required
	jmp	quit
KeepParagraphTogether	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeepLinesTogether
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep part of this paragraph in one piece.

CALLED BY:	HandleGroupedLines
PASS:		*ds:si	= Instance
		bx.di	= line
		ss:bp	= LICL_vars w/
				Attributes set for the paragraph containing
				    the line.
				LICL_regionTopLine set
RETURN:		carry set if no ripple is required
		carry clear if a ripple is required
		    bx.di	= Line to ripple forward (if any)
		    LICL_vars w/
			Attributes set for the paragraph containing the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	/*
	 * Find current paragraph start
	 */
	curLine = line

	while (! line.flags & LF_STARTS_PARAGRAPH) {
	    line--
	}
	
	/*
	 * See if enough lines are together on this column
	 */
	if (curLine - line > togetherAmount) {
	    Abort, enough is together to allow standard rippling
	}

	... set up stuff so that we ripple first line of current paragraph
	    forward so the paragraph start stays together ...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeepLinesTogether	proc	near
	uses	ax, cx, dx
	.enter

EC <	tst	bx							>
EC <	ERROR_S	VIS_TEXT_BAD_LINE_NUMBER				>

	pushdw	bxdi				; Save initial line

	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_KEEP_LINES
	jz	abort

	;
	; Find current paragraph start
	;
	movdw	dxcx, bxdi			; Save current line

	call	SkipToParaStart			; bx.di <- current para start
	
	cmpdw	dxcx, bxdi			; Check for no change
	je	abort				; Branch if at para start
	
	;
	; Check for not in this region
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	jbe	abort
	
	;
	; Check to see if the number of lines matches what we need for widow
	; control.
	;
	clr	ax
	ExtractField byte, LICL_paraAttr.VTPA_keepInfo, VTKI_TOP_LINES, al
	inc	ax

	subdw	dxcx, bxdi			; dx.cx <- # of lines together
	tst	dx
	jnz	abort				; Branch if >64K
	cmp	cx, ax				; Check for enough
	ja	abort				; Branch if enough
	
	;
	; Rippling in the spot we want will produce an unacceptable widow.
	; We must ripple the entire paragraph forward.
	;
	add	sp, size dword			; Restore stack

	call	SetParaAttributesForLine	; Set para attributes
	
	clc					; Signal: do the ripple
	
quit:
	.leave
	ret


abort:
	popdw	bxdi				; Restore line
	stc					; Signal: no ripple required
	jmp	quit
KeepLinesTogether	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleKeepWithNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to ripple the end of the previous
		paragraph forward in order to keep it with the current one.

CALLED BY:	HandleGroupedLines
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars w/
				Attributes set for this paragraph
				LICL_regionTopLine set
RETURN:		carry set if no ripple is required
		carry clear if a ripple is required
		    bx.di	= Line to ripple forward (if any)
		    LICL_vars w/
			Attributes set for the paragraph containing the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Check the attributes for the previous paragraph. If the previous
	paragraph has the "keep with next" attribute bit set, then set up
	to ripple the last line of the previous paragraph forward.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleKeepWithNext	proc	near
	uses	ax, dx
	.enter
	pushdw	bxdi

	tstdw	bxdi				; Check for being first line
	jz	abort				; Branch if it is

	;
	; Make sure it's a paragraph start
	;
	call	TL_LineGetFlags			; ax <- flags
	test	ax, mask LF_STARTS_PARAGRAPH	; Check for starts paragraph
	jz	abort				; Branch if it doesn't
	
	;
	; If the current paragraph attributes contain the "column-break before"
	; attribute, then we can't possibly keep the previous paragraph with
	; the current one, so there's no use trying.
	;
	test	LICL_paraAttr.VTPA_attributes, mask VTPAA_COLUMN_BREAK_BEFORE
	jnz	abort

	;
	; Get attributes for previous line
	;
	call	GetLineStartOffsetBasedOnCurrentRegion
						; dx.ax <- current line start
	decdw	dxax				; dx.ax <- offset into prev para
	call	T_GetParaAttrAttributes		; ax <- attributes
	
	test	ax, mask VTPAA_KEEP_PARA_WITH_NEXT
	jz	abortRestoreAttributes
	
	;
	; We do need to keep the end of the previous paragraph with the start
	; of this line.
	;
	call	TL_LinePrevious			; bx.di <- previous line
	
	;
	; Make sure we aren't trying to ripple forward the first line of
	; the region.
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	jbe	abortRestoreAttributes		; Branch if we are
	
	;
	; bx.di holds the line to ripple forward.
	;
	add	sp, size dword			; Restore stack
	
	call	SetParaAttributesForLine

	clc					; Signal: ripple required

quit:
	.leave
	ret

abort:
	popdw	bxdi
	stc					; Signal: no ripple
	jmp	quit

abortRestoreAttributes:
	popdw	bxdi
	call	SetParaAttributesForLine
	stc					; Signal: no ripple
	jmp	quit

HandleKeepWithNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetParaAttributesForLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the paragraph attributes in the LICL_vars for a given line.

CALLED BY:	Handle*
PASS:		*ds:si	= Instance
		bx.di	= Line
		ss:bp	= LICL_vars
RETURN:		LICL_vars w/ paragraph attributes set for the line.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetParaAttributesForLine	proc	near
	uses	ax, dx
	.enter
	call	TL_LineToOffsetStart		; dx.ax <- offset to line start
	call	T_GetParaAttrAttributes		; ax <- attributes
	.leave
	ret
SetParaAttributesForLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAndHandleOrphanProblem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we have an orphan and if we do, handle it
		somehow.

CALLED BY:	CalculateRegions
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		al	= Orphan count
RETURN:		carry set if there is an orphan
		    bx.di = Line to ripple (if any)
		    LICL_* set up for the ripple
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckAndHandleOrphanProblem	proc	far
	uses	ax, cx, dx
	.enter
	clr	ah				; ax <- Orphan count

	;
	; Figure the distance from the regions top line.
	;
	movdw	dxcx, ss:[bp].LICL_line		; dx.cx <- current line
	subdw	dxcx, ss:[bp].LICL_regionTopLine
	
	;
	; If the current line is farther from the region top than the orphan
	; count, then we have an orphan that needs handling.
	;
	tst	dx				; Check for >64K
	jnz	noOrphan
	
	cmp	ax, cx				; Compare against orphan count
	jbe	noOrphan			; Branch if no orphan

	;
	; We may have an orphan, unless of course the current paragraph
	; starts in this region. If that's the case, then the whole thing
	; is in this region and therefore we can't have an orphan.
	;
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- original line
	call	SkipToParaStart			; bx.di <- start of paragraph

	cmpdw	bxdi, ss:[bp].LICL_regionTopLine; Check for start in region
	jae	noOrphan			; Branch if all in this region

;-----------------------------------------------------------------------------
	;
	; The entire paragraph is not in this region. 
	; The lines which do fall in this region qualify as an orphan.
	; We need to ripple some lines forward from the previous region.
	;
	movdw	dxcx, ss:[bp].LICL_line		; dx.cx <- starting line
	subdw	dxcx, bxdi			; dx.cx <- # of lines in para
	
	;
	; Check to see if the entire paragraph needs rippling
	;
	tst	dx				; Check for >64K
	jnz	gotRippleLine

	cmp	cx, ax				; Check for small paragraph
	jbe	gotRippleLine			; Branch if small paragraph
	
	;
	; The paragraph is small enough that we can ripple only a few lines
	;
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- starting line
	sub	di, ax				; bx.di <- line to ripple
	sbb	bx, 0

gotRippleLine:
	;
	; bx.di	= Line to ripple forward.
	;
	; The line we want to ripple (bx.di) is not in this region, it is
	; in some previous region. This poses a problem because it requires
	; us to reinitialize lots of variables. We also need to make sure
	; that we aren't trying to ripple forward too much stuff.
	;
	call	FigureRippleFromPrevRegion
	jnc	noOrphan
	
;-----------------------------------------------------------------------------

quit:
	.leave
	ret


noOrphan:
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line to ripple
	clc					; Signal: no orphan
	jmp	quit
CheckAndHandleOrphanProblem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureRippleFromPrevRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure all the various things required to make rippling
		from the previous region work.

CALLED BY:	CheckAndHandleOrphanProblem
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		bx.di	= Line we would like to ripple forward
RETURN:		carry clear if there is nothing to ripple
		carry set if we need to ripple
		    bx.di	= Line to ripple (if any)
		    LICL_* set up for the ripple
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We somehow need to set stuff up so it appears as though we were
	actually calculating in the previous region and ran into a line
	(bx.di) that needed to be rippled forward.
	
	If the line in question falls at the start of the previous region
	then we can't do this ripple and we abort.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureRippleFromPrevRegion	proc	near
	uses	ax, cx, dx
	.enter
	movdw	dxax, bxdi			; Save line in dx.ax

	mov	cx, ss:[bp].LICL_region
	call	TR_RegionPrev			; cx <- previous region
	
	call	TR_RegionGetTopLine		; bx.di <- region top line
	cmpdw	bxdi, dxax			; Check for at top
	LONG jbe notPossible
	
	;
	; We can ripple this line.
	; Set the new region, and the cached "top line" values
	;
	mov	ss:[bp].LICL_region, cx
	movdw	ss:[bp].LICL_nextRegionTopLine, ss:[bp].LICL_regionTopLine, cx
	movdw	ss:[bp].LICL_regionTopLine, bxdi
	
	movdw	bxdi, dxax			; bx.di <- Line to ripple
	
	;
	; Set line related stuff.
	;
	movdw	ss:[bp].LICL_line, bxdi
	
	call	GetLineStartOffsetBasedOnCurrentRegion
						; dx.ax <- line start
	movdw	ss:[bp].LICL_lineStart, dxax	; Save new line start

	clrwbf	ss:[bp].LICL_lineHeight
	clrwbf	ss:[bp].LICL_oldLineHeight
	
	mov	ss:[bp].LICL_linesToDraw, 2	; Force update

	;
	; Figure previous line flags
	;
	call	TL_LinePrevious			; bx.di <- previous line
	call	TL_LineGetFlags			; ax <- Previous LineFlags
	mov	ss:[bp].LICL_prevLineFlags, ax

	;
	; Clear stuff that no longer relates
	;
	clr	ax

	clrdw	ss:[bp].LICL_rippleCount, ax
	clrdwf	ss:[bp].LICL_rippleHeight, ax
	
	clrdwf	ss:[bp].LICL_insertedSpace, ax
	clrdwf	ss:[bp].LICL_deletedSpace, ax

	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line

	stc					; Signal: do the ripple

quit:
	.leave
	ret


notPossible:
	movdw	bxdi, dxax			; Restore line
	clc					; Signal: no ripple
	jmp	quit
FigureRippleFromPrevRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipToParaStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the start of the previous paragraph.

CALLED BY:	KeepWithPreviousParagraph
PASS:		*ds:si	= Instance
		bx.di	= Line to start at
RETURN:		bx.di	= Line that starts the paragraph
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	while (! line.flags & LF_STARTS_PARAGRAPH) {
	    line--
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipToParaStart	proc	near
	uses	ax
	.enter
findLoop:
	call	TL_LineGetFlags			; ax <- flags
	test	ax, mask LF_STARTS_PARAGRAPH
	jnz	gotParaStart
	
	call	TL_LinePrevious			; bx.di <- Previous line
	jmp	findLoop

gotParaStart:
	.leave
	ret
SkipToParaStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureRippleValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure rippling values for rippling a given line forward.

CALLED BY:	KeepWithPreviousParagraph
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
		bx.di	= Line to ripple forward
RETURN:		bx.di	= Line to ripple forward
		carry set if this is different than current LICL_line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureRippleValues	proc	near
	uses	ax, cx, dx
	.enter
	;
	; See if we actually rippled anything...
	;
	cmpdw	bxdi, ss:[bp].LICL_line
	LONG je	quit				; Carry clear if we branch
	
	;
	; Check to see if we are rippling all the lines from a region.
	;
	cmpdw	bxdi, ss:[bp].LICL_regionTopLine
	LONG je	quit				; Carry clear if we branch

	;
	; Check to see if we rippled any lines backwards into this column
	;
	tstdw	ss:[bp].LICL_rippleCount	; Check for any rippling
	jz	saveLineAndComputeStuff
	
	;
	; We did ripple lines backwards into this column. This means that
	; we need to figure the height of all the lines we rippled backwards
	; which we now plan on rippling forward. This height needs to be
	; removed from the 'rippleHeight' (which is intended to be the height
	; of the lines rippled backwards).
	;
	; The last line we'll be rippling forward is LICL_line.
	; The rippleCount tells us the first line we rippled back.
	; We want to start at the maximum of:
	;	bx.di (line to ripple forward)
	;	LICL_line - LICL_rippleCount
	;
	; We want to sum up all the lines from the first line to bx.di
	;
	pushdw	bxdi				; Save new top of next region

	movdw	dxax, ss:[bp].LICL_line		; dx.ax <- 1st line rippled back
	subdw	dxax, ss:[bp].LICL_rippleCount
	incdw	dxax

	cmpdw	bxdi, dxax			; Use larger
	jae	gotFirst
	movdw	bxdi, dxax			; bx.di <- first in list to sum
gotFirst:
	
	;
	; bx.di	= First line to start adding from
	;
	; Compute the number of lines to do.
	;
	movdw	dxax, ss:[bp].LICL_line		; dx.ax <- End of range
	incdw	dxax
	clr	cx				; Set no flags
	call	TL_LineSumAndMarkRange		; cx.dx.ax <- Sum of heights

	subdwf	ss:[bp].LICL_insertedSpace, cxdxax
	adddwf	ss:[bp].LICL_rippleHeight,  cxdxax
	
	popdw	bxdi				; Restore new top of next region

saveLineAndComputeStuff:
	;
	; Save the line to ripple forward and compute:
	;	line height
	;	line start
	;	lines to draw
	;	previous lines flags
	;
	; bx.di	= Line
	;
	movdw	ss:[bp].LICL_line, bxdi		; Save new line to ripple
	
	call	GetLineStartOffsetBasedOnCurrentRegion
						; dx.ax <- line start
	movdw	ss:[bp].LICL_lineStart, dxax	; Save new line start

	clrwbf	ss:[bp].LICL_lineHeight
	clrwbf	ss:[bp].LICL_oldLineHeight
	
	mov	ss:[bp].LICL_linesToDraw, 2	; Force update

	call	TL_LinePrevious			; bx.di <- previous line
	call	TL_LineGetFlags			; ax <- Previous LineFlags
	mov	ss:[bp].LICL_prevLineFlags, ax
	
	movdw	bxdi, ss:[bp].LICL_line		; bx.di <- line to return
	
	stc					; Signal: line changed

quit:
	.leave
	ret
FigureRippleValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineStartOffsetBasedOnCurrentRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the starting offset of a line, but compute it based on
		the current region, rather than the region containing the line.

CALLED BY:	FigureRippleValues, FigureRippleFromPrevRegion
PASS:		*ds:si	= Instance
		bx.di	= Line
		ss:bp	= LICL_vars w/ these set:
				LICL_region
				LICL_nextRegionTopLine
RETURN:		dx.ax	= Offset to start of LICL_line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineStartOffsetBasedOnCurrentRegion	proc	near
	uses	cx
	.enter
	mov	cx, ss:[bp].LICL_region		; cx <- current region
	call	TL_LineToOffsetStartFromRegion	; dx.ax <- start
	.leave
	ret
GetLineStartOffsetBasedOnCurrentRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WarnUserRevert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Warn user that we are about to revert the document

CALLED BY:	CalculateRegions
PASS:		*ds:si - VisLargeText 
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _REGION_LIMIT

WarnUserRevert		proc	far
	class	VisTextClass
	.enter

EC <	mov	di, ds:[si]					>
EC <	add	di, ds:[di].Vis_offset				>
EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE	>
EC <	ERROR_Z	VIS_TEXT_CANNOT_REVERT_SMALL_TEXT_OBJECT	>

;;
;;  Warning should be displayed by application when it receives
;;  MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE.
;; 
;;	mov	cx, handle RegionLimitWarningString
;;	mov	dx, offset RegionLimitWarningString
;;	call	TT_DoWarningDialog
	;
	; Find the document object
	;
	mov	cx, segment GenDocumentClass			
	mov	dx, offset GenDocumentClass			
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock				
EC <	ERROR_NC -1						>
NEC <	jnc	done						>

	push	si						
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_DOCUMENT_REVERT_TO_AUTO_SAVE
	mov	di, mask MF_RECORD			
	call	ObjMessage				
	mov	cx, di					;^hcx <- event
	pop	si					
	;
	; There may be other MSG_META_OBJ_FLUSH_INPUT_QUEUE messages
	; on the queue which will send out messages which may screw
	; up the revert if they arrive after the revert has started.
	; To make sure those are all handled before the document is
	; reverted, flush the queues first.
	;
	call	GeodeGetProcessHandle
	mov	dx, bx
	clr	bp
	mov	di, mask MF_FORCE_QUEUE	
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	call	ObjMessage
done::
	.leave
	ret
WarnUserRevert		endp
endif

;
; These are used in ptext.tcl for printing out calculation information
; as it happens.
;
ForceRef	CR_afterCalc
ForceRef	IODL_insert
ForceRef	IODL_afterDelete

TextRegion	ends
