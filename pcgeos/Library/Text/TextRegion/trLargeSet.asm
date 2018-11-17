COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeSet.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Code for setting region variables.

	$Id: trLargeSet.asm,v 1.1 97/04/07 11:21:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	LargeAdjustForReplacement

DESCRIPTION:	Adjust the text positions for a replacement

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextReplaceParameters

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
LargeAdjustForReplacement	proc	near
	uses	bx
	.enter
	mov	bx, offset VLTRAE_charCount	; bx <- dword to adjust
	call	AdjustRegionDWord		; Adjust that dword
	.leave
	ret
LargeAdjustForReplacement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustRegionDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a dword field of a region.

CALLED BY:	LargeAdjustForReplacement, LargeAdjustNumberOfLines
PASS:		*ds:si	= Instance
		ss:bp	= VisTextReplaceParameters
		bx	= Offset into VisTextRegionArrayElement to the field
			  to adjust. The field is assumed to be a count
			  and a dword.
RETURN:		fields in all relevant regions adjusted.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The right thing depends on the situation. There are a few
	situations that must be handled. These are (not suprisingly)
	identical to the cases we handle for CommonLineAdjustForReplacement:
		1) Region falls before range
				     |---range---|
			|--region--|
			Test:	(region.end < range.start)
			Action:	nothing
		
		2) Region crosses range start
					|---range---|
			|------region--------|
			Test:	(region.start < range.start) &&
				(region.end   >= range.start)
			Action:	region.count = range.start - region.start +
					       insCount

		3) Region is contained in range
			|-----range-----|
			   |-region-|
			Test:	(region.start > range.start) &&
				(region.end   < range.end)
			Action:	region.count = 0

		4) Region contains range
			   |-range-|
			|------region--------|
			Test:	(region.start <= range.start) &&
				(region.end   >= range.end)
			Action:	region.count += (range.start - range.end) + 
						 insCnt
				quit

		5) Region crosses range end
			|-------range------|
				|------region--------|
			Test:	(region.start >= range.start) &&
				(region.start <= range.end)   &&
				(region.end > range.end)
			Action:	region.count = region.end - range.end
				quit

		6) Region falls after the range
			|---range---|
					|------region--------|
			Test:	(region.start > range.end)
			Action:	nothing
				quit

If the range is right at a region end, then we want to make the change
at the second region, not the first.
   
So here's the problem... For adjusting lines, we start our update with the
appropriate line based on the offset. For regions we try to do the same
thing by including case (1). The problem is when we get an offset that
logically falls right between regions. We always want to choose the
second region, but only if the first region is not the last one.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustRegionDWord	proc	near
	uses	ax, bx, cx, dx, bp, di
vtrp		local	word		push	bp
fieldOffset	local	word		push	bx
regPtr		local	word
regStart	local	dword
regEnd		local	dword
lowRegion	local	word
region		local	word
	.enter
	push	si
	clr	region
	mov	cx, 0xFFFF
	mov	lowRegion, cx

	call	SetupForRegionScan		; Get pointer to first region
	LONG jc	quit				; abort if no regions
	;
	; ds:si = first region
	; cx	= region count
	; dx	= element size
	;

;-----------------------------------------------------------------------------
	mov	bx, vtrp			; ss:bx <- parameters
	clrdw	regStart
regionLoop:
	;
	; ds:si	= Current region
	; dx	= Size of a region
	; cx	= Number of regions left to process
	; ss:bx	= VisTextReplaceParameters
	;
	mov	regPtr, si
	add	si, fieldOffset			; ds:si <- ptr to field

	movdw	diax, regStart			; di.ax <- region start
	adddw	diax, ds:[si]			; di.ax <- region end
	movdw	regEnd, diax

	push	si
	sub	si, fieldOffset
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
	pop	si
	LONG jnz nextRegion

	;
	; Check for the easy stuff... Line before start of range.
	;
	cmpdw	regEnd, ss:[bx].VTRP_range.VTR_start, ax
	jb	nextRegion			; Branch if line before range

	cmpdw	regStart, ss:[bx].VTRP_range.VTR_end, ax
	ja	quit				; Branch if line after range
	
	;
	; Now for the harder stuff... Check for the case of a null-range
	; which falls right at a region boundary.
	;
	cmpdw	regEnd, ss:[bx].VTRP_range.VTR_start, ax
	LONG je	checkWhichRegion
	cmpdw	ss:[bx].VTRP_range.VTR_start, ss:[bx].VTRP_range.VTR_end, ax
	jne	checkCases

checkCases:
	cmpdw	regStart, ss:[bx].VTRP_range.VTR_start, ax
	jbe	case2or4
	
	;
	; Cases 3 or 5
	;
	cmpdw	regEnd, ss:[bx].VTRP_range.VTR_end, ax
	jae	case5
	
	;
	; Case 3
	;
	clrdw	ds:[si]
	push	ax
	mov	ax, region
	cmp	ax, lowRegion
	jae	noReplace1
	mov	lowRegion, ax
noReplace1:
	pop	ax

nextRegion:
	;
	; Process the next region.
	;
	movdw	regStart, regEnd, ax
	sub	si, fieldOffset			; ds:si <- ptr to region
	dec	cx
	jz	quit
	inc	region
	call	ScanToNextRegion
	jmp	regionLoop
;-----------------------------------------------------------------------------
quit:
	; Reset the cache based on the lowest modified region
	pop	si
	push	cx
	mov	cx, lowRegion
	call	ResetCachedLineIfLower
	pop cx

	.leave
	ProfilePoint 16
	ret

case5:
	movdw	diax, regEnd
	subdw	diax, ss:[bx].VTRP_range.VTR_end
	movdw	ds:[si], diax
	push	ax
	mov	ax, region
	cmp	ax, lowRegion
	jae	noReplace2
	mov	lowRegion, ax
noReplace2:
	pop	ax
	jmp	quit


case2or4:
	cmpdw	regEnd, ss:[bx].VTRP_range.VTR_end, ax
	jae	case4
	
	;
	; Case 2
	;
	movdw	diax, regStart
	subdw	diax, ss:[bx].VTRP_range.VTR_start
	negdw	diax
	adddw	diax, ss:[bx].VTRP_insCount
	movdw	ds:[si], diax
	push	ax
	mov	ax, region
	cmp	ax, lowRegion
	jae	noReplace3
	mov	lowRegion, ax
noReplace3:
	pop	ax
	jmp	nextRegion


case4:
	movdw	diax, ds:[si]			; di.ax <- old count
	subdw	diax, ss:[bx].VTRP_range.VTR_end
	adddw	diax, ss:[bx].VTRP_range.VTR_start
	adddw	diax, ss:[bx].VTRP_insCount
	movdw	ds:[si], diax

	push	ax
	mov	ax, region
	cmp	ax, lowRegion
	jae	noReplace4
	mov	lowRegion, ax
noReplace4:
	pop	ax
	jmp	quit

checkWhichRegion:
	;
	; We are right on the boundary between regions...
	; If this is the last region, do the adjustment here.
	;
	cmp	cx, 1
	LONG je	checkCases
	
	;
	; We are right on the boundary between two perfectly reasonable regions.
	; We could adjust in either one.

	;
	; If the current region ends with a section/column break, then we 
	; want to adjust in a later region.
	;
	push	si
	sub	si, fieldOffset			; ds:si <- ptr to region
	test	ds:[si].VLTRAE_flags, mask VLTRF_ENDED_BY_COLUMN_BREAK
	pop	si
	LONG jnz nextRegion

	;
	; The current region does not end in a column break. 
	;
	; If this region is the last one in the section and it is not in the
	; last section, then we want to the insert in the next region.
	;
	; If this region is the last one in the section and it is in the
	; last section, then we want to do the insert here.
	;
	; If the current region is not the last in its section, we want to
	; do the insert in the next region anyway because that handles the
	; case of having a paragraph-ending line in the previous region and
	; also the text will be wrapped back if it needs to be.
	;
	push	si
	sub	si, fieldOffset			; ds:si <- ptr to region
	call	IsLastRegionInSection		; carry set if last in section
						;    zero set if last in object
	pop	si
	LONG jnc nextRegion			; Branch if not last in section
	
	;
	; It's the last region in the section, check to see if it's the last
	; region in the object.
	; 
	LONG jz	checkCases			; Branch if last in object

	;
	; It's not the last region in the object, so do the change in the
	; next region.
	;
	jmp	nextRegion

AdjustRegionDWord	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LargeAdjustNumberOfLines

DESCRIPTION:	Adjust the number of lines for a region

CALLED BY:	INTERNAL

PASS:
	*ds:si	- text object
	cx	- region
	ss:bp	- VisTextReplaceParameters w/
			VTRP_range    = Range of lines deleted
			VTRP_insCount = Number of lines inserted

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	This isn't as simple as it sounds. If the count is larger than what
	is contained in this region we need to loop back and remove lines
	from the next region.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
LargeAdjustNumberOfLines	proc	near
	uses	bx
	.enter
	mov	bx, offset VLTRAE_lineCount
	call	AdjustRegionDWord
	.leave
	ProfilePoint 15
	ret
LargeAdjustNumberOfLines	endp

ResetCachedLineIfLower proc far
	uses ax, bx
	.enter
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound
	mov	ax, -1
	cmp 	cx, ds:[bx].VLTCLACC_lineRegionIndex
	jae	notAffected
	mov	ds:[bx].VLTCLACC_lineRegionIndex, ax
notAffected:
	cmp 	cx, ds:[bx].VLTCLACC_prevLineRegionIndex
	jae	notAffected4
	mov	ds:[bx].VLTCLACC_prevLineRegionIndex, ax
notAffected4:
	cmp 	cx, ds:[bx].VLTCLACC_lineToRegionRegionIndex
	jae	notAffected2
	mov	ds:[bx].VLTCLACC_lineToRegionRegionIndex, ax
notAffected2:
	cmp	cx, ds:[bx].VLTCLACC_regionFromLineRegionIndex
	jae	notAffected3
	mov	ds:[bx].VLTCLACC_regionFromLineRegionIndex, ax
notAffected3:
notFound:
	.leave
	ret
ResetCachedLineIfLower endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionInsertLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert lines into a region.

CALLED BY:	TR_RegionInsertLines
PASS:		*ds:si	= Instance
		cx	= Region
		dx.ax	= Count
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionInsertLines	proc	far
	uses	di
	.enter
	push	ax				; Save count.low
	call	PointAtRegionElement		; ds:di <- data
						; ax <- element size
	pop	ax				; Restore count.low

	adddw	ds:[di].VLTRAE_lineCount, dxax
	call	ResetCachedLineIfLower
	.leave
	ProfilePoint 14
	ret
LargeRegionInsertLines	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionSetStartOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the starting offset of a region in a large object.

CALLED BY:	TR_SetTopLine
PASS:		*ds:si	= Instance ptr
		cx	= Region
		dx.ax	= Starting offset
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionSetStartOffset	proc	near
	uses	ax, bx, cx, dx, si, bp
	class	VisLargeTextClass

newStart	local	dword	push	dx, ax
regionsBackedUp	local	word		; used by LargeRegionSetTopSomething
	ForceRef newStart
	.enter

	push	cx, si
	call	FindOffsetByRegion		; ds:si <- reg
						; dx.ax <- old start
	push	dx
	call	PointAtRegionElementAsScanDoes
	mov	cx, dx				; cx <- region size
	pop	dx

	mov	bx, offset VLTRAE_charCount	; bx <- Field to adjust
	call	LargeRegionSetTopSomething	; Do the adjustment
						; ax = number regions rolled back
	pop	cx, si
	sub	cx, ax				; adjust first region affected
	call	ResetCachedLineIfLower
	.leave
	ProfilePoint 13
	ret
LargeRegionSetStartOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionSetTopLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the top line of a region in a large object.

CALLED BY:	TR_SetTopLine
PASS:		*ds:si	= Instance ptr
		cx	= Region
		bx.dx	= Top line
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionSetTopLine	proc	near
	class	VisLargeTextClass

	uses	ax, bx, cx, dx, di, si, bp
newStart	local	dword	push	bx, dx
	ForceRef newStart
	ProfilePoint 39
	.enter

	push	cx, si
	call	FindLineByRegion		; bx.di <- old start
	call	PointAtRegionElementAsScanDoes
	mov	cx, dx				; cx <- region size

	movdw	dxax, bxdi			; dx.ax <- old start

	mov	bx, offset VLTRAE_lineCount	; bx <- offset to the field
	call	LargeRegionSetTopSomething	; Do the adjustment
						; ax <- number regions affected
	pop	cx, si
	sub	cx, ax
	call	ResetCachedLineIfLower
	.leave
	ProfilePoint 12
	ret
LargeRegionSetTopLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionSetTopSomething
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the top line/offset

CALLED BY:	LargeRegionSetTopLine, LargeRegionSetStartOffset
PASS:		ds:si	= Region whose start we are setting
		dx.ax	= Old top line/start offset
		bx	= Offset to the field in the region to adjust
		cx	= Size of region structure
		ss:bp	= Inheritable stack frame
RETURN:		ax	= Number of regions went backwards fixing up
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The implication is that lines are being taken from one region and
	placed into another. Consider adjacent regions:
		r1 --text-flows-this-way-> r2
	
	This routine gets called to set the top line of r2. This means that
	we are either moving lines from r1 to r2 or we are moving lines the
	other way.
	
	If we are moving lines forward from r1 to r2, then we do something
	like this:
		diff = r2.start - newStart
		r2.count += diff

		ptr  = &r2;
		do {
		    ptr--;			/* point to prev region */
		    if (ptr->count < diff) {
			diff -= ptr->count;
		        ptr->count = 0;
		    } else {
		    	ptr->count -= diff;
			diff = 0;
		    }
		} while (diff != 0);

	If we are moving lines from r2 to r1 (rippling backwards) then
	we have a somewhat different situation. It is possible that the
	lines we want to ripple backwards don't all reside in r2. In fact
	those lines may fall across several regions starting at r2.
	
	If that's the case, the algorithm looks like:
		diff     = newStart - r2.start
		r1.count = r1.count + diff
		
		for (r = r2; r.count < diff; r = r.next) {
		    diff   -= r.count;
		    r.count = 0;
		}
		r.count -= diff;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/29/92	Initial version
	les     05/05/00	Modified to tell how many regions were
				touched going backwards to help the fast
				region caching system reset correctly.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionSetTopSomething	proc	near
	uses	bx, cx, dx, di
	.enter	inherit	LargeRegionSetStartOffset

	clr	regionsBackedUp
	push	bx
	xchg	cx, dx
	call	SaveCachedRegion		;bx = token
	xchg	cx, dx
	mov	di, bx
	pop	bx
	push	di
	;
	; Figure the difference so we know if we're rippling forward or
	; backward.
	;
	subdw	dxax, newStart			; dx.ax <- difference
	
	tst	dx				; Check for rippling backward
	js	rippleBack			; Branch if old < new

	;
	; We're rippling forward...
	; dx.ax	= Difference
	;
	adddw	ds:[si][bx], dxax		; Adjust r2
	xchg	cx, dx
	call	ScanToPrevRegion
	inc	regionsBackedUp
	xchg	cx, dx

forwardLoop:
	;
	; ds:si	= Current region
	; cx	= Size of region data
	; bx	= Offset to field to adjust
	; dx.ax	= Amount of lines/text we have rippled forward
	; 

	cmpdw	ds:[si][bx], dxax		; Check for count < diff
	jae	endForwardLoop
	
	subdw	dxax, ds:[si][bx]		; Update difference
	clrdw	ds:[si][bx]			; Nuke count

	xchg	cx, dx
	call	ScanToPrevRegion
	inc	regionsBackedUp
	xchg	cx, dx
	jmp	forwardLoop			; Loop to do more

endForwardLoop:
	;
	; We finally found a region where we can extract all that we need...
	;
	subdw	ds:[si][bx], dxax		; Update count

quit:
	pop	bx
	xchg	cx, dx
	call	RestoreCachedRegion
	xchg	cx, dx
	
	mov	ax, regionsBackedUp
	.leave
	ProfilePoint 11
	ret

;-----------------------------------------------------------------------------

rippleBack:
	;
	; Ripple counts backwards from subsequent regions.
	;
	negdw	dxax				; dx.ax <- amount of change
	
findPrevNonEmpty:
	;
	; Find the previous non-empty region (one must exist)
	;
	xchg	cx, dx
	call	ScanToPrevRegion		; ds:si <- r1
	inc	regionsBackedUp
	xchg	cx, dx
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
	jnz	findPrevNonEmpty

	adddw	ds:[si][bx], dxax		; Adjust r1 count
	
	;
	; Now start looping through the regions ahead of us making adjustments
	;
	xchg	cx, dx
	call	ScanToNextRegion		; ds:si <- r2
	xchg	cx, dx

regionLoop:
	;
	; ds:si	= Current region
	; cx	= Size of region data
	; bx	= Offset to field to adjust
	; dx.ax	= Amount of lines/text that we have rippled back
	; 
	;

	cmpdw	ds:[si][bx], dxax		; Check for all in one
	jae	endLoop
	
	;
	; We are rippling back more than this region can hold.
	; We knock the total-count down by the amount in this region and we
	; set the region count to zero.
	;
	subdw	dxax, ds:[si][bx]		; Adjust count
	clrdw	ds:[si][bx]			; This region is empty

	xchg	cx, dx
	call	ScanToNextRegion		; ds:si <- r2
	xchg	cx, dx
	jmp	regionLoop			; Loop to do the next one

endLoop:
	;
	; We finally found a region where we can extract all that we need...
	;
	subdw	ds:[si][bx], dxax		; Adjust last region count
	jmp	quit

LargeRegionSetTopSomething	endp


TextRegion	ends


ifdef PROFILE_TIMES
TextProfile	segment resource

profileName	byte "textprof.log", 0
profileFile	word 0
profileLastTime	word 0
profileSpace1	word 0
profileSpace2	word 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_ProfilePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Profile at a particular code point.

CALLED BY:	Anything
PASS:		ax	= point identifier (any unique number)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The concept is simple.  Keep track of the amount of time between
	calls to TR_ProfilePoint (via macro ProfilePoint).  The goal is
	to know how long routines are taking and which are hot spots.  If
	less than a timer tick (TimerGetCount) goes by, then nothing
	happens.  Otherwise, record in the log file how much time has gone
	by (opening the file if necessary).  

	The log file that is produced is a binary file put in the document
	directory.  All data are 4 byte samples with the first 16 bit word
	being the profile id and the next 16 bit value being the time.
	The DOS utility program TEXTPROF will convert the log into a text
	file that can be summarized with Excel or some other advanced tool.

	Of course, placing profiling points wisely is a different issue
	(aim for the *end* of each routine for accurate timings).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The log file is never closed
	(one irritation of this system, but could be done by detecting
	a detach of the text library -- but currently, I don't care since
	the file output is not buffered and this is only a debugging tool).

	Also, the directory changes to the document directory and it doesn't
	put it back when opening the file.

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/17/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_ProfilePoint proc far
	pushf
	push	bx, cx, dx
	push	ax
	mov	ax, cs:profileFile
	tst	ax
	jnz	started

	; Open a new file
	mov	ax, SP_DOCUMENT
	call	FileSetStandardPath
	jc	done

	mov	ah, mask FCF_NATIVE or FILE_CREATE_TRUNCATE
        mov     al, FileAccessFlags <FE_NONE, FA_READ_WRITE>
	clr	cx
	push	ds
	segmov	ds, cs
	mov	dx, offset profileName
	clr	cx
	call	FileCreate
	pop	ds
	jc	done

	mov	cs:profileFile, ax
	push	bx
	call	TimerGetCount
	pop	bx
	mov	cs:profileLastTime, ax
	jmp	done

started:
	; Has enough time gone by to need to output a profile point?
	push	bx
	call	TimerGetCount
	pop	bx
	mov	cx, cs:profileLastTime
	cmp	cx, ax
	jz	done
	sub	cx, ax
	mov	cs:profileLastTime, ax
	pop	ax
	push	ax
	mov	cs:profileSpace1, ax
	neg	cx
	mov	cs:profileSpace2, cx
	push	ds
	mov	ax, cs
	mov	ds, ax
	mov	al, 0
	mov	bx, cs:profileFile
	mov	cx, 4
	mov	dx, offset profileSpace1
	call	FileWrite
	pop	ds
done:
	pop	ax
	pop	bx, cx, dx
	popf
	ret
TR_ProfilePoint endp


TextProfile	ends
endif ; PROFILE_TIMES




