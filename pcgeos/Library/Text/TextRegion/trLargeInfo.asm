COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeInfo.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Misc information about regions in large objects.

	$Id: trLargeInfo.asm,v 1.1 97/04/07 11:21:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisLargeTextPurgeRegionCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Purge the cache used with regions stored in huge arrays

CALLED BY:	via MSG_VIS_LARGE_TEXT_PURGE_REGION_CACHE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	9/3/99			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisLargeTextPurgeRegionCache	method dynamic	VisLargeTextClass, 
			MSG_VIS_LARGE_TEXT_PURGE_REGION_CACHE
	mov	cx, -1
	call	PointAtRegionElement
	ret

VisLargeTextPurgeRegionCache	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisLargeTextPurgeCachedInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Purge the cache used to record previously calculated
		region walking calculations.

CALLED BY:	via MSG_VIS_LARGE_TEXT_PURGE_CACHED_INFO
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	 Date		Description
	----	 ----		-----------
	lshields 4/19/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisLargeTextPurgeCachedInfo method dynamic VisLargeTextClass,
			MSG_VIS_LARGE_TEXT_PURGE_CACHED_INFO
	mov	cx, 0
	call	ResetCachedLineIfLower
	ret
VisLargeTextPurgeCachedInfo	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionLinesInClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of lines in a region that fall inside a 
		given rectangle.

CALLED BY:	TR_LinesInClipRect via CallRegionHandlers
PASS:		*ds:si	= Instance
		ss:bp	= TextRegionEnumParameters
		ss:bx	= VisTextRange to fill in
RETURN:		VisTextRange holds the range of lines
		carry set if no lines appear in the region
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionLinesInClipRect	proc	near
	uses	ax, dx
	.enter
	mov	ax, ss:[bp].TREP_regionWidth	; ax <- width

	movdw	dsdi, ss:[bp].TREP_regionPtr	; ds:di <- region
	ceilwbf	ds:[di].VLTRAE_calcHeight, dx	; dx <- height

	call	LinesInClipCommon
	.leave
	ret

LargeRegionLinesInClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionNextSegmentTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next segment of a region.

CALLED BY:	TR_NextSegmentTop via CallRegionHandler
PASS:		*ds:si	= Instance
		bx	= non-zero to get the next segment top for blt purposes
		cx	= Region number
		dx	= Y position within that region
RETURN:		dx	= Y position of the top of the next segment
			= Region bottom if there are no more segments
		carry set if there are no more segments
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionNextSegmentTop	proc	near
	class	VisLargeTextClass
	uses	ax
	.enter
EC <	call	T_AssertIsVisLargeText					>

	call	GetFillRegion				;axdi = region
	jc	regionExists

	tst	bx				;if not for blt then return
	jz	useTrueHeight			; true height

	; we're getting the height for blt-ing -- return calcHeight unless
	; we are in galley mode, in which case we want to return something
	; very large

	mov	dx, di				;dx = calc height
	call	TextRegion_DerefVis_DI
	cmp	ds:[di].VLTI_displayMode, VLTDM_CONDENSED
	jbe	checkReturnNull
	mov	dx, LARGEST_BLT_VALUE
returnNull:
	stc
done:
	.leave
	ret


checkReturnNull:
	;
	; We want to return the *minimum* of the calculated height and the
	; true height.
	;
	mov	bx, dx				; bx <- calculated height
	call	LargeRegionGetTrueHeight
	ceilwbf	dxal, dx			; dx <- true height
	
	;
	; Return the minimum in dx.
	;
	cmp	dx, bx
	jbe	returnNull
	mov	dx, bx
	jmp	returnNull

unlockPopDSSIuseTrueHeight:
	call	DBUnlockDS

	pop	si, ds				; Restore instance

useTrueHeight:
	call	LargeRegionGetTrueHeight
	ceilwbf	dxal, dx			; dx <- height
	jmp	returnNull

	; region exists -- scan it

regionExists:
	push	si, ds
	call	DBLockToDSSI			;ds:si = region

yloop:
	; search for correct swath -- ds:si points at y pos

	lodsw					;ax <- y position of swath
	
	;
	; It is possible that the position passed may be below the bottom
	; of the object. If that is the case, then the first word of the
	; line will be EOREGREC. If we find that, we return the computed
	; height (for lack of anything better to do).
	;
	cmp	ax, EOREGREC
	je	unlockPopDSSIuseTrueHeight

	; skip to the next swath

	push	ax				;save position of 1st swath

skiploop:
	lodsw					;skip on/off points
	cmp	ax, EOREGREC
	jnz	skiploop

	pop	ax				;ax <- Y pos of current swath

	cmp	ax, dx				;check for reached requested pos
	jle	yloop				;branch if we haven't

	; found the swath after the position passed in dx, return the y position

	mov_tr	dx, ax				;dx <- top of next swath

	lodsw					;ax <- left edge of swath
	cmp	ax, EOREGREC			;check for end of region
	jz	unlockPopDSSIuseTrueHeight	;branch if it is
	
	call	DBUnlockDS
	pop	si, ds
	clc
	jmp	done

LargeRegionNextSegmentTop	endp

TextRegion	ends

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetRegionTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top/left edge of a region.

CALLED BY:	TR_GetRegionTopLeft via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number
		ss:bp	= PointDWord to fill in
RETURN:		PointDWord contains the top-left corner of the region
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetRegionTopLeft	proc	near
	class	VisLargeTextClass
	uses	ax, bx
	.enter
EC <	call	T_AssertIsVisLargeText					>

	call	TextFixed_DerefVis_DI
	mov	ax, ds:[di].VLTI_displayMode
	cmp	ax, VLTDM_PAGE
	jz	pageMode

	push	cx, dx, si

	;
	; load callback based on mode
	;
	mov	bx, offset addCondensed
	cmp	ax, VLTDM_CONDENSED
	jz	gotCallback
	mov	bx, offset addGalleyOrDraft
gotCallback:

	clr	ax
	clrdw	ss:[bp].PD_x, ax
	clrdw	ss:[bp].PD_y, ax

	jcxz	done				;if region 0 then done

if 0	; no need for this one yet OPTIMIZE_REGIONS_IN_HUGE_ARRAY
	mov	di, ds:[di].VLTI_regionSpacing	;di = region spacing
	push	di, ds, es
	push	bx				;save callback
	mov_tr	ax, cx				;ax = region number
	call	NewSetupForRegionScan
regionLoop:
	pop	ax
	push	ax				;get callback from stack
	call	ax				;ax = region height
	add	ax, di				;add spacing
	add	ss:[bp].PD_y.low, ax
	adc	ss:[bp].PD_y.high, 0
	add	si, dx
	loop	regionLoop
	sub	si, dx
	call	NewScanToNextRegion
	jnz	regionLoop
	call	NewFinishRegionScan
	pop	bx				;discard callback
	pop	di, ds, es

else
	mov_tr	ax, cx				;ax = region number
	call	SetupForRegionScan
	mov_tr	cx, ax				;cx = count
regionLoop:
	call	bx				;ax = region height
	add	ax, ds:[di].VLTI_regionSpacing
	add	ss:[bp].PD_y.low, ax
	adc	ss:[bp].PD_y.high, 0
	dec	cx
	jz	done
	call	ScanToNextRegion		; ds:si <- ptr to next region
	jmp	regionLoop

endif

done:
	pop	cx, dx, si

	jmp	quit

pageMode:
	call	PointAtRegionElement		;ds:di = data
	movdw	ss:[bp].PD_x, ds:[di].VLTRAE_spatialPosition.PD_x, ax
	movdw	ss:[bp].PD_y, ds:[di].VLTRAE_spatialPosition.PD_y, ax
	
	;
	; Adjust for the region.
	;
	call	GetFillRegion			; axdi = region
	jnc	quit				; Branch if no region
	
	;
	; A region exists. Adjust the position for the region rectangle.
	;
	push	ds, si				; Save nuked registers
	call	DBLockToDSSI			; ds:si <- ptr to region

	sub	si, size Rectangle		; ds:si <- ptr to rectangle
	mov	ax, ds:[si].R_top		; ax <- top of rectangle

	call	DBUnlockDS			; Release the region
	pop	ds, si				; Restore nuked registers

	;
	; Account for the region rectangle.
	;
	add	ss:[bp].PD_y.low, ax
	adc	ss:[bp].PD_y.high, 0

quit:
	.leave
	ProfilePoint 18
	ret

;---

addCondensed:
	;
	; Adjust for the region.
	;
	push	di				; Save nuked registers...
	mov	di, si				; ds:di <- ptr to region
	call	NotDraftModeGetRegionInfo	; axdi <- region
	jnc	noCondensedRegion		; Branch if no region
	
	;
	; A region exists. Adjust the position for the region rectangle.
	;
	push	ds, si				; Save nuked registers
	call	DBLockToDSSI			; ds:si <- ptr to region

	sub	si, size Rectangle		; ds:si <- ptr to rectangle
	mov	ax, ds:[si].R_bottom		; ax <- height of rectangle
	sub	ax, ds:[si].R_top

	call	DBUnlockDS			; Release the region
	pop	ds, si				; Restore nuked registers
	pop	di
	retn


noCondensedRegion:
	mov	ax, ds:[si].VLTRAE_size.XYS_height
	pop	di
	retn

;---

addGalleyOrDraft:
	ceilwbf	ds:[si].VLTRAE_calcHeight, ax
	retn

LargeRegionGetRegionTopLeft	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFillRegion

DESCRIPTION:	Get a region's fill region

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance
	cx - region number

RETURN:
	carry - set if region
			axdi - region DB item
		clear if not region
			ax - region width
			di - region calc height

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/27/92		Initial version

------------------------------------------------------------------------------@
GetFillRegion	proc	far
	class	VisLargeTextClass
EC <	call	T_AssertIsVisLargeText					>

	call	TextFixed_DerefVis_DI
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jb	notDraftMode
	mov	ax, ds:[di].VLTI_draftRegionSize.XYS_width
	mov	di, ds:[di].VLTI_draftRegionSize.XYS_height
	jmp	doneNoRegion

notDraftMode:
	call	PointAtRegionElement

NotDraftModeGetRegionInfo	label	far
	;
	; Make sure there aren't any pushes or pops above this...
	;
	mov	ax, ds:[di].VLTRAE_region.high
	tst	ax
	jnz	regionExists
	ceilwbf	ds:[di].VLTRAE_calcHeight, ax
	mov	di, ds:[di].VLTRAE_size.XYS_width
	xchg	ax, di
doneNoRegion:
	clc
	ret

regionExists:
	mov	di, ds:[di].VLTRAE_region.low
	stc
	ret

GetFillRegion	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DBLockToDSSI

DESCRIPTION:	Lock a DB item containing a region's path

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance
	axdi - region DB item

RETURN:
	ds:si - pointer to region path (after Rectangle bounds)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

------------------------------------------------------------------------------@
DBLockToDSSI	proc	far
	push	bx, es
	
	; Assume that DB item with path is in the same file as
	; the rest of the data. If VTI_vmFile is zero, we assume
	; that it is in our own file (in accordance with the
	; way T_GetVMFile determines the file for other operations).
	; [mg, 02/26/00]
	call	T_GetVMFile			; bx <- handle of our file

	call	DBLock
	segmov	ds, es
	mov	si, ds:[di]			;ds:si = region
	add	si, size Rectangle		;point past bounds
	pop	bx, es
	ret
DBLockToDSSI	endp

DBUnlockDS	proc	far
	push	es
	segmov	es, ds
	call	DBUnlock
	pop	es
	ret
DBUnlockDS	endp

TextFixed	ends

TextRegion	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetLineCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of lines in a region.

CALLED BY:	TR_RegionGetLineCount via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		cx	= Number of lines
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetLineCount	proc	near
	uses	ax, dx
	class	VisTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

	call	PointAtRegionElement		;ds:di = data, z set if last
	mov	cx, ds:[di].VLTRAE_lineCount.low

	.leave
	ret

LargeRegionGetLineCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of characters in a region.

CALLED BY:	TR_RegionGetCharCount via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		dx.ax	= Number of lines
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetCharCount	proc	near
	class	VisTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

	call	PointAtRegionElement		;ds:di = data, z set if last
	movdw	dxax, ds:[di].VLTRAE_charCount

	.leave
	ret

LargeRegionGetCharCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionLeftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds of the region at a given y position.

CALLED BY:	TR_RegionLeftRight via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region number
		dx	= Y position within that region
		bx	= Integer height of the line at that position
RETURN:		ax	= Left edge of the region at that point.
		bx	= Right edge of the region at that point.
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionLeftRight	proc	near
	.enter

	call	GetFillRegion
	jc	regionExists

	; no region -- just return width (in ax)

	mov_tr	bx, ax
	clr	ax
done:
	.leave
	ret

	; region exists -- scan it

regionExists:
	push	cx, dx, si, ds
	call	DBLockToDSSI		;ds:si = region
	add	bx, dx			;bx = bottom

yloop:
	; search for correct swath -- ds:si points at y pos

	lodsw
	cmp	ax, dx
	jg	foundY
	cmp	ax, EOREGREC
	jz	returnNull

	; skip to the next swath

skiploop:
	lodsw
	cmp	ax, EOREGREC
	jnz	skiploop
	jmp	yloop

	; found the swath, return the width

foundY:
	mov_tr	cx, ax			;cx <- swath bottom
	lodsw				;ax <- left
	cmp	ax, EOREGREC		;Check for no swath at all
	jz	returnNull

	push	cx			;Save swath bottom
	mov_tr	cx, ax			;cx <- left
	lodsw
	mov_tr	dx, ax			;dx <- right

finalloop:
	;
	; See if the region is any smaller further down
	;
	; bx	= Bottom of area we're interested in
	; cx	= left edge so far, including current swath
	; dx	= right edge so far, including current swath
	; ds:si	= Pointer into current swath
	; On stack:
	;	Bottom of current swath
	;
	pop	ax			;ax <- bottom of swath
	cmp	ax, bx			;Check for swath contains area
	jg	regionDone		;Branch if it does
	
	;
	; The swath does not completely contain the area we're interested in.
	; We need to check the actual data.
	;
	; Since the information we have includes this swath, we need to skip
	; to the end of this swath.
	;
skiploop2:
	lodsw
	cmp	ax, EOREGREC
	jnz	skiploop2		;Loop until done with swath

	lodsw				;ax <- Bottom of next swath
	
	;
	; Check for no more region, which we figure is sort of the same
	; thing as no more restrictions.
	;
	cmp	ax, EOREGREC
	je	regionDone

	;
	; So here we are... We have a real swath and we need to factor
	; in the left/right edges of this swath into our left/right edges
	; for the entire swath.
	;
	; We're only interested in the left edge moving in or the right
	; edge moving in.
	;
	; There is the chance that the left edge of this swath will be
	; larger than our current right edge, or that the right edge of
	; this swath will be less than the left edge of our current swath.
	;
	; Neither of these cases is really acceptable. It indicates a type
	; of region which we don't handle well. For the purposes of calculation
	; or drawing, it is sort of a discontinuity. In all cases we need
	; to leave the line in the original segment, so it is unreasonable
	; to create a situation where left > right...
	;
	; Anyway, we do two quick checks here. If either of the following
	; is true, we figure "good enough" and quit out of here.
	;	newLeft  > curRight
	;	newRight < curLeft
	;
	; cx	= curLeft
	; dx	= curRight
	; ds:si	= Left edge of current swath, followed by right edge
	;
	cmp	{word} ds:[si], dx	;Compare newLeft, curRight
	jge	regionDone
	cmp	{word} ds:[si+2], cx	;Compare newRight, curLeft
	jle	regionDone

	;
	; We're safe... go on as usual.
	;
	push	ax			;Save bottom of next swath
	lodsw				;ax <- Left edge of next swath
	cmp	ax, cx
	jle	noLeftRestriction
	mov_tr	cx, ax
noLeftRestriction:

	lodsw				;load new right
	cmp	ax, dx
	jge	noRightRestriction
	mov_tr	dx, ax
noRightRestriction:

	jmp	finalloop

regionDone:
	mov_tr	ax, cx			;ax = left
	mov	bx, dx			;dx = right
	call	DBUnlockDS
	pop	cx, dx, si, ds
	jmp	done

returnNull:
	clr	ax
	clr	bx
	jmp	regionDone

LargeRegionLeftRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given offset.

CALLED BY:	TR_RegionFromOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		dx.ax	= Offset
RETURN:		cx	= Region
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionFromOffset	proc	near	uses si
	.enter

	call	FindRegionByOffset

	.leave
	ret

LargeRegionFromOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionFromOffsetGetStartLineAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get info about the region associated with a given offset.

CALLED BY:	TR_RegionFromOffsetGetStartLineAndOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		dx.ax	= Offset
RETURN:		dx.ax	= Region start offset
		bx.di	= Region start line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionFromOffsetGetStartLineAndOffset	proc	near
	uses	cx, si, bp
offsetToFind	local	dword		push	dx, ax
regStartLine	local	dword
region		local	word
	ProfilePoint 39
	.enter
	; If zero, then return 0s (this avoids messing up our cache)
	tstdw	dxax
	jne	notZero
	clrdw	dxax
	clrdw	bxdi
	jmp	exit
notZero:
	push	si
	; dx.ax = offset to find
	; ds.si = object
	call	FetchCachedRegionFromOffset

	; ax.di = start char of region
	; bx.cx = start line of region
	; dx	= region index
	movdw	regStartLine, bxcx
	mov	region, dx

	call	VisLargeTextGetRegionCount
	sub	cx, dx
	; cx    = number of regions to follow

	; Point at the first region
	push	ax, cx, di
	mov	cx, dx
	call	PointAtRegionElement
	; ds:di = region data
	; ax    = element size
	mov	si, di
	mov	dx, ax
	pop	ax, cx, di

;-----------------------------------------------------------------------------
findLoop:
	;
	; ds:si	= Current region
	; dx	= Amount to add to get to next region
	; cx	= Number of regions after ds:si
	; ax.di	= Starting offset of current region
	; ss:bp	= Stack frame
	;
	adddw	axdi, ds:[si].VLTRAE_charCount

	cmpdw	offsetToFind, axdi
	jb	gotRegion
	ja	checkNext

	;
	; Screw it... We always return the first region in which the offset 
	; falls. This makes some stuff work, but slows down some other
	; operations. Thankfully those other operations are things like
	; typing the first character in a new region.
	;
	jmp	gotRegion

checkNext:
	adddw	regStartLine, ds:[si].VLTRAE_lineCount, bx

	dec	cx
	jz	gotRegion
	inc	region
	call	ScanToNextRegion		; ds:si <- ptr to next region
	jmp	findLoop
gotRegion:
	;
	; ds:si	= Pointer to current region
	; regStartLine = First line in this region
	; ax.di	= Starting offset of next region
	;
	subdw	axdi, ds:[si].VLTRAE_charCount	; ax.di <- offset to current reg

gotOffsetAndLine::
	;
	; regStartLine = First line of this region
	; ax.di	= Offset to start of region
	;
	mov	dx, ax				; dx.ax <- Start offset
	mov	ax, di
	
	movdw	bxdi, regStartLine		; bx.di <- Start line
	mov	cx, region
	pop	si
	call	StoreCachedRegionFromOffset
exit:
	.leave
	ProfilePoint 36
	ret
LargeRegionFromOffsetGetStartLineAndOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNextSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the first region in the next section.

CALLED BY:	HasNextSection
PASS:		ds:si	= Current region
		dx	= Size of region data
		cx	= Number of regions after ds:si
RETURN:		carry set if there is a next section
		    ds:si  = First region in next section
		    ax	   = Number of regions after current one to next section
DESTROYED:	ax, si, if no next section

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNextSection	proc	near
	uses	bp
	.enter
	clr	bp				; bp <- number after current
	mov	ax, ds:[si].VLTRAE_section	; ax <- current section

regionLoop:
	dec	cx				; One less to process
	jcxz	noNextSection			; Branch if no next section

	call	ScanToNextRegion
	inc	bp				; bp <- one more processed

	cmp	ax, ds:[si].VLTRAE_section	; Check for in same section
	jne	hasNextSection			; Branch if it has one

	jmp	regionLoop			; Loop to do the next one

hasNextSection:
	;
	; Not so fast... If the section doesn't contain any lines (ie: if the
	; line-count for this region is zero) then the section is a new one
	; and really shouldn't be counted.
	;
	tstdw	ds:[si].VLTRAE_lineCount
	jz	noNextSection

	stc					; Signal: has next section

quit:
	mov	ax, bp				; ax <- # processed
	.leave
	ret

noNextSection:
	clc					; Signal: no next section
	jmp	quit
FindNextSection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionFromLineGetStartLineAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get info about the region associated with a given line.

CALLED BY:	TR_RegionFromLineGetStartLineAndOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		bx.dx	= Line
RETURN:		dx.ax	= Region start offset
		bx.di	= Region start line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	It is important to return the *first* region that could contain
	a given line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionFromLineGetStartLineAndOffset	proc	near
	uses	cx, bp
offsetToFind	local	dword		push	bx, dx
region		local	word
	.enter

	; If zero, then return 0s (this avoids messing up our cache)
	tstdw	bxdx
	jne	notZero
	clrdw	dxax
	clrdw	bxdi
	jmp	exit
notZero:
	push	si

	; Get previously located stack element and point to its region
	; (or initialize it all)
	call	FetchCachedRegionFromLine
	mov	region, dx
	push	ax, cx, di
	mov	cx, dx
	call	PointAtRegionElement
	mov	si, di
	mov	dx, ax 
	pop	ax, cx, di

;-----------------------------------------------------------------------------
findLoop:
	;
	; ds:si	= Current region
	; dx	= Amount to add to get to next region
	; bx.cx	= Starting offset of current region
	; ax.di	= Starting line of current region
	; ss:bp	= Stack frame
	;
	adddw	axdi, ds:[si].VLTRAE_lineCount	; ax.di <- offset to next region

	cmpdw	offsetToFind, axdi
	jb	gotRegion
	ja	checkNext

checkNext:
	adddw	bxcx, ds:[si].VLTRAE_charCount

	inc	region
	call	ScanToNextRegion		; ds:si <- ptr to next region
	jmp	findLoop
;-----------------------------------------------------------------------------

gotRegion:
	;
	; ds:si	= Pointer to current region
	; bx.cx	= Offset to start of next region
	; ax.di	= First line in this region
	;
	subdw	axdi, ds:[si].VLTRAE_lineCount	; ax.di <- offset to current reg

gotRegionAndLine::
	xchg	ax, bx				; ax.cx <- offset to current reg

						; bx.di <- first line in reg
	mov	dx, ax				; dx.ax <- start offset
	mov	ax, cx
	pop	si
	push	cx
	mov	cx, region
	call	StoreCachedRegionFromLine
	pop	cx
exit:
	.leave
	ProfilePoint 37
	ret
LargeRegionFromLineGetStartLineAndOffset	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindRegionByOffset

DESCRIPTION:	Find a region given its offset

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	dxax - position

RETURN:
	ds:si - region data
	cx - region number

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
FindRegionByOffset	proc	near
	uses	ax, bx, dx, bp, di
	.enter

	mov	bx, dx				;bx.ax = position

	call	SetupForRegionScan
EC <	ERROR_C	VIS_TEXT_LARGE_OBJECT_MUST_HAVE_REGION_ARRAY		>

	; ds:si = first region
	; cx = region count
	; dx = element size

	clr	bp

lloop:
	subdw	bxax, ds:[si].VLTRAE_charCount
	
	tst	bx				; Check for edge conditions
	js	gotRegion			; Branch if negative
	jnz	checkNext			; Branch if more to do
	
	tst	ax
	jnz	checkNext			; Branch if there's more to do

	;
	; The offset falls at the end of this region. Check to see if this
	; is the last region.
	;
	call	IsLastRegionInSection
	jc	checkLastRegion			; Branch if is last region

checkNext:
	inc	bp
	dec	cx
	jz	loopEnd
	call	ScanToNextRegion		; ds:si <- ptr to next region
	jmp	lloop

loopEnd:
	dec	bp

gotRegion:
	mov	cx, bp

	.leave
	ProfilePoint 19
	ret


checkLastRegion:
	;
	; If this is the last region in this section then we want to return
	; the first region in the next section, unless of course there is no
	; next section... In that case we return this region.
	;
	call	SaveCachedRegion		; bx = token for current region
	
	call	FindNextSection			; carry set if there's another
						; ds:si <- region in next section
						; ax <- # processed
	jnc	returnCached			; Branch if no next section
	
	add	bp, ax				; bp <- region to return
	jmp	gotRegion

returnCached:
	call	RestoreCachedRegion
	jmp	gotRegion
	
FindRegionByOffset	endp

TextRegion	ends

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionFromLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given line.

CALLED BY:	TR_RegionFromOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		bx.dx	= Line
RETURN:		cx	= Region
DESTROYED:	di

PSEUDO CODE/STRATEGY:
	It is important to return the *first* region that could contain
	a given line. Since a region can legally contain no lines this is
	not quite as simple as it seems...

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionFromLine	proc	near	uses bx, dx, bp, ax
lineLimit   local	dword 
region	    local	word
total	    local	dword
numRegions  local	word
current	    local	word
	ProfilePoint 32
	.enter

	push	si
	call	VisLargeTextGetRegionCount
	mov	numRegions, cx

	mov	di, dx
	movdw	lineLimit, bxdi

	; bx.di = line
	; ds.si = object

	call	FetchCachedLineToRegionIfLower

	; cx = last region (or zero)
	; bx.di = matching line for region (or zero)

	push	di
	call	PointAtRegionElement
	mov	si, di
	mov	dx, ax
	pop	di
	; bx.di = lines remaining
	; dx = element size
	; ds:si = first region

	mov	current, cx
	; cx = number of current region

	sub	cx, numRegions
	neg	cx
	; cx = region count (of remaining)
		
	; ds:si = first region
	; cx = region count
	; dx = element size

lloop:
	; Remember what we got up to
	movdw	total, bxdi
	push	ax
	mov	ax, current
	mov	region, ax
	pop	ax

	;
	; bx.di	= Number of lines ahead of current region we need to go.
	;

	adddw	bxdi, ds:[si].VLTRAE_lineCount
	cmpdw	bxdi, lineLimit
	ja	gotRegion			; Branch if gone negative
	jz	scanToRealRegion

;nextRegion:
	inc	current
	dec	cx
	jz	usePrevRegion
	call	ScanToNextRegion		; ds:si <- ptr to next region
	jmp	lloop

usePrevRegion:
	dec	current

gotRegion:
	movdw	bxdi, total
	mov	cx, region
	pop	si
	call	StoreCachedLineToRegion
	mov	cx, current

	.leave
	ProfilePoint 20
	ret


scanToRealRegion:
	;
	; If the current region ends with a column break, then we 
	; want to return the next region.
	;
	; ds:si	= Region
	; cx	= Number of regions after ds:si
	; current	= Current region number
	; dx	= Size of region elements
	;
	inc	current
	test	ds:[si].VLTRAE_flags, mask VLTRF_ENDED_BY_COLUMN_BREAK
	jnz	gotRegion

	;
	; Check for the last region in the list
	;
	cmp	cx, 1
	je	usePrevRegion
	
	;
	; One more special check: If the current region has a line-count
	; of zero, then we return this region. This is the case of either
	; a new region that has just been inserted or else an empty region.
	;
	; Fortunately the current region *can't* be empty. If it is, then
	; we would have branched here when we saw the previous region.
	;
	tstdw	ds:[si].VLTRAE_lineCount
	jz	usePrevRegion
	
	;
	; If the current region ends with a section break, then we want
	; to return the first region in the next section.
	;
	call	IsLastRegionInSection
	jc	scanToNextSection

	;
	; We are just right on the boundary... If the next region is not
	; empty then return it.
	;
	call	ScanToNextRegion		; ds:si <- next region
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
	jz	gotRegion
	jmp	usePrevRegion

scanToNextSection:
	;
	; Scan until we reach the first region of the next section.
	; We do this by skipping empty regions.
	;
	; current	= Region number for next region
	; ds:si	= Current region
	;
	call	ScanToNextRegion		; ds:si <- next region
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
	jz	gotRegion			; Branch if not empty
	inc	current				; bp <- next region
	jmp	scanToNextSection		; Loop to check it out
	

LargeRegionFromLine	endp

TextFixed	ends

TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionPrevSkipEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the either the immediately previous region or else
		the first in a sequence of empty regions falling before the
		passed on.

CALLED BY:	TR_RegionPrevSkipEmpty
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry set if there is no previous region
		carry clear otherwise
		   cx	= Previous region
DESTROYED:	if carry is set, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionPrevSkipEmpty	proc	far
	uses	ax, bx, dx, di
	.enter
	jcxz	quitNoPrevious

	;
	; Point at the current element
	;
	call	PointAtRegionElement		; ds:di <- current element
						; ax <- element size
	mov	bx, ds:[di].VLTRAE_section	; bx <- Current section
	call	prevRegionDIAX			; ds:di <- previous element
	
	dec	cx				; Region number of ds:di
	mov	dx, -1				; dx <- current prev region

checkLoop:
	;
	; ds:di	= Current element to check
	; cx	= Region number of ds:di
	; bx	= Section for starting element
	; dx	= Current "previous" region (or -1, if none)
	; ax	= Size of region data
	;

	;
	; Check for previous being in same section as current
	;
	cmp	bx, ds:[di].VLTRAE_section
	jne	useCurrentPrevRegion

	mov	dx, cx				; Prev region is valid

	;
	; The current one is a valid previous region. Check for not having
	; any lines. If this is the case, we try to move to the previous
	; region.
	;
	tstdw	ds:[di].VLTRAE_lineCount		; Check for empty
	jnz	useCurrentPrevRegion		; Branch if not
	
	;
	; The previous region is empty move backward
	;
	jcxz	useCurrentPrevRegion		; Branch if no previous
	
	dec	cx				; Move to previous region
	call	prevRegionDIAX			; ds:di <- previous element
	jmp	checkLoop

useCurrentPrevRegion:
	;
	; dx	= Current previous region (or -1, if none)
	;
	cmp	dx, -1
	je	quitNoPrevious
	
	mov	cx, dx				; cx <- previous region

	clc					; Signal: has previous
	
quit:
	.leave
	ret

quitNoPrevious:
	stc
	jmp	quit

prevRegionDIAX:
	xchg	si, di
	xchg	ax, dx
	call	ScanToPrevRegion
	xchg	si, di
	xchg	ax, dx				; ds:di <- previous element
	retn

LargeRegionPrevSkipEmpty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionFromPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given point.

CALLED BY:	TR_RegionFromOffset via CallRegionHandler
PASS:		*ds:si	= Instance
		ss:bp	= PointDWFixed
RETURN:		cx	= Region
		ax	= Relative X position
		dx	= Relative Y position
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionFromPoint	proc	near	uses	bx, si, es
visdata		local	nptr
vischunk	local	nptr
point		local	PointDWFixed
spatialPos	local	PointDWord
regionSize	local	XYSize
	class	VisLargeTextClass
	.enter

EC <	call	T_AssertIsVisLargeText					>
	call	TextRegion_DerefVis_DI
	mov	visdata, di
	mov	vischunk, si

	push	si, ds
	segmov	ds, ss
	mov	si, ss:[bp]			;ds:si = source
	segmov	es, ds
	lea	di, point			;es:di = dest
	mov	cx, (size PointDWFixed) / 2
	rep	movsw
	pop	si, ds

	clr	ax
	clrdw	spatialPos.PD_x, ax
	clrdw	spatialPos.PD_y, ax

	call	SetupForRegionScan
EC <	ERROR_C	VIS_TEXT_LARGE_OBJECT_MUST_HAVE_REGION_ARRAY		>
	clr	bx

	; ds:si = first region
	; cx = region count
	; dx = element size

	; for special display modes we need to keep around the spatial
	; position and update it as we go

lloop:
	push	bx				;save region number

	; get the spatial position and size

	mov	ax, ds:[si].VLTRAE_size.XYS_width
	mov	regionSize.XYS_width, ax
	mov	ax, ds:[si].VLTRAE_size.XYS_height
	mov	regionSize.XYS_height, ax

	mov	di, visdata
	mov	ax, ds:[di].VLTI_displayMode
	cmp	ax, VLTDM_PAGE
	jnz	notPage
	
	;
	; For page-mode we need to set the spatial position explicitly.
	;
	movdw	bxax, ds:[si].VLTRAE_spatialPosition.PD_x
	movdw	spatialPos.PD_x, bxax
	movdw	bxax, ds:[si].VLTRAE_spatialPosition.PD_y
	movdw	spatialPos.PD_y, bxax
	jmp	gotPos
notPage:

	cmp	ax, VLTDM_CONDENSED
	je	gotPos

	; must be galley or draft

	cmp	ax, VLTDM_DRAFT_WITH_STYLES
	jb	notDraft
	mov	ax, ds:[di].VLTI_draftRegionSize.XYS_width
	mov	regionSize.XYS_width, ax
	mov	ax, ds:[di].VLTI_draftRegionSize.XYS_height
	mov	regionSize.XYS_height, ax
notDraft:
	call	LargeRegionIsLastRegionInLastSection	;if last region then
	jc	gotPos					;use size
	ceilwbf	ds:[si].VLTRAE_calcHeight, ax
	mov	regionSize.XYS_height, ax
gotPos:

	; check for point inside rectangular bounds

.warn -jmp
	movdw	bxdi, spatialPos.PD_x
	jgdw	bxdi, point.PDF_x.DWF_int, next	; Branch if left > X
.warn @jmp

	add	di, regionSize.XYS_width
	adc	bx, 0				; bx.di <- right

	jldw	bxdi, point.PDF_x.DWF_int, next	; Branch if right < X

	movdw	bxdi, spatialPos.PD_y
	jgdw	bxdi, point.PDF_y.DWF_int, next	; Branch if top > Y

	add	di, regionSize.XYS_height
	adc	bx, 0				; bx.di <- bottom

	push	si
	mov	si, visdata			; ds:di <- ptr to instance
	add	di, ds:[si].VLTI_regionSpacing	; Account for spacing
	adc	bx, 0
	pop	si

	jledw	bxdi, point.PDF_y.DWF_int, next	; Branch if bottom < Y

	; inside rectangular bounds -- do region check if needed

	mov	di, visdata
	mov	bx, ds:[di].VLTI_displayMode

	cmp	bx, VLTDM_DRAFT_WITH_STYLES
	jae	found

	movdw	axdi, ds:[si].VLTRAE_region
	tst	ax
	jz	found

regionExists::
	push	cx, dx, si, ds
	mov	cx, point.PDF_x.DWF_int.low
	sub	cx, spatialPos.PD_x.low		;cx = x
	mov	dx, point.PDF_y.DWF_int.low
	sub	dx, spatialPos.PD_y.low		;dx = y
	mov	si, vischunk			;needs instance [mg, 02/26/00]
	call	DBLockToDSSI
	inc	cx				;adjust coordinates for a
	inc	dx				;routine that deals with
						;device coordinates

	;
	; For condensed mode we don't actually need to compensate for the top
	; edge of the region since the data always gets pushed up toward the
	; top of the visible area.
	;
	cmp	bx, VLTDM_CONDENSED
	je	skipTopAdjust

	;
	; The coordinates are now relative to the top of the
	; bounding rectangle and not relative to the top of the actual
	; region-rectangle. We need to make one more adjustment.
	;
	sub	dx, ds:[si - size Rectangle].R_top   ;dx <- relative Y
skipTopAdjust:

	;
	; Finally... we now check to see if the point is in the region.
	;
	; ds:si	= Pointer to the region
	; cx	= X position relative to the left edge of the region
	; dx	= Y position relative to the top edge of the region-rectangle
	;
	call	GrTestPointInReg		;carry - set if in

	call	DBUnlockDS
	pop	cx, dx, si, ds
	jc	found

next:
	;
	; Advance to the next region if in draft or condensed mode.
	;
	pop	bx				; bx <- current region

	call	advanceSpatialPosition

	inc	bx
	dec	cx
	jz	notFound
	call	ScanToNextRegion		; ds:si <- ptr to next region
	jmp	lloop

notFound:
	mov	cx, CA_NULL_ELEMENT		;return not found

done:
	.leave
	ProfilePoint 21
	ret


found:
	pop	cx				;return region number

	;
	; Check for region empty and if it is, use some other region
	;
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
;;;
;;; Removed, 10/21/92 -jw
;;;	This causes problems in places where we really expect the point
;;;	to truly be over the region in question.
;;;
;;;	jnz	usePrevNonEmptyRegion		; Branch if empty
	jnz	notFound

gotRegion::
	;
	; Compute the relative X position
	;
	movdw	bxax, point.PDF_x.DWF_int
	subdw	bxax, spatialPos.PD_x

	;
	; Force position into a reasonable 16 bit value
	;
	tst	bx
	jz	gotResultX
	
	mov	ax, -1				; Assume really large
	jns	gotResultX
	clr	ax				; Else use really small
gotResultX:

	;
	; Compute the relative Y position
	;
	movdw	bxdx, point.PDF_y.DWF_int
	subdw	bxdx, spatialPos.PD_y

	;
	; Force position into a reasonable 16 bit value
	;
	tst	bx
	jz	gotResultY
	
	mov	dx, -1				; Assume really large
	jns	gotResultY
	clr	dx				; Else use really small
gotResultY:

	jmp	done



advanceSpatialPosition:
	;
	; Advance the Y part of the spatial position by adding in 
	; the appropriate height.
	;
	; We add different amounts for different display modes.
	;	PAGE		- nothing, we'll set it later anyway
	;	CONDENSED	- true height of region
	;	GALLEY		- calc height of region
	;	DRAFT w/ STYLES	- calc height of region
	;	DRAFT w/o STYLES- calc height of region
	;
	; ds:si	= Pointer to region
	;
	push	di
	mov	di, visdata			; ds:di <- ptr to instance

	;
	; For page-mode, we do nothing
	;
	cmp	ds:[di].VLTI_displayMode, VLTDM_PAGE
	je	quitAdvance
	
	;
	; For everything else except condensed, we use the calc-height
	;
	ceilwbf	ds:[si].VLTRAE_calcHeight, ax	; ax <- calcHeight

	cmp	ds:[di].VLTI_displayMode, VLTDM_CONDENSED
	jne	advanceY
	
	;
	; For condensed, we use the true height.
	;
	mov	ax, regionSize.XYS_height	; ax <- height of region

advanceY:
	;
	; ax	= Amount to add
	;
	add	ax, ds:[di].VLTI_regionSpacing	; Account for spacing

	add	spatialPos.PD_y.low, ax		; Adjust the position
	adc	spatialPos.PD_y.high, 0

quitAdvance:
	pop	di
	retn


LargeRegionFromPoint	endp

TextRegion	ends

TextFixed	segment

COMMENT @----------------------------------------------------------------------

FUNCTION:	PointAtRegionElement

DESCRIPTION:	Given a large text object, point at the region

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - region number (or -1 to clear cache)

RETURN:
	ds:di - region data
	ax - element size
	z flag - set if last region

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/16/92		Initial version

------------------------------------------------------------------------------@
PointAtRegionElement	proc	far
	class	VisLargeTextClass
	push	si
EC <	call	T_AssertIsVisLargeText					>

	call	TextFixed_DerefVis_DI
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	huge

	cmp	cx, -1
	jne	notNegOne
	clr	cx
notNegOne:
	mov	si, ds:[di].VLTI_regionArray	;*ds:si = array
EC <	call	ECLMemValidateHandle					>
	mov	ax, cx
	call	ChunkArrayElementToPtr		;ds:di = VisTextRegionArrayEl

	; test for last region

	inc	ax
	mov	si, ds:[si]
	cmp	ax, ds:[si].CAH_count

	mov	ax, ds:[si].CAH_elementSize
	pop	si
	ret

huge:
	;
	; Regions in huge array
	;
	push	bx
	
	push	dx
	mov	di, ds:[di].VLTI_regionArray
	call	T_GetVMFile
	call	HugeArrayGetCount		;dx.ax = count

	; if there are no regions we don't want to die, since the small
	; version doesn't die in this case -- just set the region
	; number (cx) to -1 so that the cache gets purged and nothing
	; else

	tst	ax
	jnz	atLeastOneRegionExists
	mov	cx, -1
atLeastOneRegionExists:
	dec	ax				;ax = last region
	cmp	cx, ax
	pop	dx
	pushf

	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_REGION
	call	ObjVarFindData			;ds:bx = data
EC <	ERROR_NC	-1						>
	cmp	cx, ds:[bx].VLTCR_num
	jz	hugeDone
	push	bx, dx, bp
	push	ds, es
	segmov	es, ds				;es:bx = local data
	mov	bp, bx				;ds:bp = local data
	call	T_GetVMFile			;bx = file

	; write back old region (if not -1)

	cmp	ds:[bp].VLTCR_num, -1
	jz	noCopyBack
	push	cx, di, ds
	mov	ax, ds:[bp].VLTCR_num		;ax = old
writeax::
	clr	dx
	call	HugeArrayLock			;ds:si = data
EC <	tst	ax							>
EC <	ERROR_Z	-1							>
	segxchg	ds, es
	mov	di, si				;es:di = array data
	mov	si, bp				;ds:si = local data
	mov	cx, size VisLargeTextRegionArrayElement
	rep	movsb
	segxchg	ds, es				;ds = huge array, es = local
	call	HugeArrayDirty
	call	HugeArrayUnlock
	pop	cx, di, ds			;cx = new region
noCopyBack:

	mov	ds:[bp].VLTCR_num, cx
	cmp	cx, -1
	jz	afterRead
	push	cx
	mov_tr	ax, cx
	clr	dx				;dx.ax = element
	call	HugeArrayLock			;ds:si = data
EC <	tst	ax							>
EC <	ERROR_Z	-1							>
	mov	di, bp				;es:di = local data
	mov	cx, size VisLargeTextRegionArrayElement
	rep	movsb
	call	HugeArrayUnlock
	pop	cx
afterRead:
	pop	ds, es
readcx::
	pop	bx, dx, bp
hugeDone:
	lea	di, ds:[bx].VLTCR_region	;ds:di = region data
	popf
	pop	bx
	pop	si
	mov	ax, si				;return ax = -object
	pushf
	neg	ax
	popf
	ret

PointAtRegionElement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetupForRegionScan

DESCRIPTION:	Setup registers to scan the region array

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	carry - set if regions do not exist
	ds:si - first region
	cx - region count
	dx - element size

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/17/92		Initial version

------------------------------------------------------------------------------@
SetupForRegionScan	proc	far		uses di
	class	VisLargeTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	huge
	
	mov	si, ds:[di].VLTI_regionArray	;*ds:si = array
	tst	si
	stc
	jz	done
EC <	call	ECLMemValidateHandle					>

	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	mov	dx, ds:[si].CAH_elementSize
	add	si, ds:[si].CAH_offset
	clc
	jmp	done

huge:
	call	VisLargeTextGetRegionCount	;cx = count
	push	ax, cx
	clr	cx
	call	PointAtRegionElement		;ds:di = element, ax = "size"
	mov_tr	dx, ax
	mov	si, di				;ds:si = data
	pop	ax, cx
	clc

done:
	.leave
;	ProfilePoint 3
	ret

SetupForRegionScan	endp

;---

ScanToNextRegion	proc	far
	tst	dx
	js	huge
	add	si, dx				; ds:si <- ptr to next region
	ret
huge:
	push	ax, bx, cx, di
	mov	si, dx
	neg	si
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_REGION
	call	ObjVarFindData
	mov	cx, ds:[bx].VLTCR_num
	inc	cx
	call	PointAtRegionElement
	mov	si, di
	pop	ax, bx, cx, di
	ret
ScanToNextRegion	endp

;---

ScanToPrevRegion	proc	far
	tst	dx
	js	huge
	sub	si, dx				; ds:si <- ptr to next region
	ret
huge:
	push	ax, bx, cx, di
	mov	si, dx
	neg	si
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_REGION
	call	ObjVarFindData
	mov	cx, ds:[bx].VLTCR_num
	dec	cx
EC <	ERROR_S	-1							>
	call	PointAtRegionElement
	mov	si, di
	pop	ax, bx, cx, di
	ret
ScanToPrevRegion	endp

;---

	; ds:si = region, return bx = cache token

SaveCachedRegion	proc	far
	tst	dx
	js	huge
	mov	bx, si			;just save offset
	ret
huge:
	push	ax, si
	mov	si, dx
	neg	si
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_REGION
	call	ObjVarFindData
	mov	bx, ds:[bx].VLTCR_num
	pop	ax, si
	ret

SaveCachedRegion	endp

;---

RestoreCachedRegion	proc	far
	pushf
	tst	dx
	js	huge
	mov	si, bx			;just recover
	popf
	ret
huge:
	push	ax, cx, di
	mov	si, dx
	neg	si
	mov	cx, bx
	call	PointAtRegionElement	; ds:di = data, ax = size
	mov	si, di
	pop	ax, cx, di
	popf
	ret
RestoreCachedRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NewSetupForRegionScan

DESCRIPTION:	Setup registers to scan the region array in an efficient
		manner, even if there are large regions

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - first region index

RETURN:
	carry - set if regions do not exist (same)
	ds:si - first region (same, except ds could be a different segment)
	cx - region count (IN THIS BLOCK -- not total) (similar but different)
	dx - element size (same)
	bx - token value to return to NewFinishRegionScan (NEW)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/17/92		Initial version

------------------------------------------------------------------------------@
NewSetupForRegionScan	proc	far		uses di
	class	VisLargeTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

;	ProfilePoint 2

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	huge
	
	mov	si, ds:[di].VLTI_regionArray	;*ds:si = array
	tst	si
	stc
	jz	done
EC <	call	ECLMemValidateHandle					>

	mov	si, ds:[si]
	push	ax

	mov	ax, cx				;ax = cx = first region index
	mov	dx, ds:[si].CAH_elementSize
	imul	dx

	mov	dx, ds:[si].CAH_elementSize
	mov	cx, ds:[si].CAH_count
	add	si, ds:[si].CAH_offset
	add	si, ax				;skip to the first index
	pop	ax

	clr	bx
	clc
	jmp	done

huge:
	push	ds				;save this block
	push	ax
	push	ds:[di].VLTI_regionArray	;save VM block
	push	cx				;save first region to lock
	call	T_GetVMFile			;bx = file

	mov	cx, -1				;write out cached region
	call	PointAtRegionElement		;destroys ax and di

	pop	ax
	clr	dx				;dxax = element to lock
	pop	di				;di = block
	call	HugeArrayLock			;ds:si = data
						;dx = size
	mov_tr	cx, ax				;cx = consecutive elements

	pop	ax
	pop	bx				;return bx = segment
	clc
done:
;	ProfilePoint 1

	.leave
	ret

NewSetupForRegionScan	endp

;---

	; return ds:si = next
	; return cx = regions in this block (0 if done)
	; return Z = set if done

NewScanToNextRegion	proc	far
	tst	bx
	jnz	huge
	clr	cx
	ret

huge:
	push	ax, dx
	call	HugeArrayNext
	mov	cx, ax
	pop	ax, dx
	tst	cx
	ret
NewScanToNextRegion	endp

;---

NewFinishRegionScan	proc	far
	pushf
	tst	bx
	jz	done
	call	HugeArrayUnlock
	mov	ds, bx
done:
	popf
	ret
NewFinishRegionScan	endp

TextFixed	ends

TextRegion	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	PointAtRegionElementAsScanDoes

DESCRIPTION:	Point at a region array element with the same values that
		SetupForRegionScan would have

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - region

RETURN:
	ds:si - region
	cx - region count - region #
	dx - element size

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 2/92		Initial version

------------------------------------------------------------------------------@
PointAtRegionElementAsScanDoes	proc	near	uses ax, di
	class	VisLargeTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

	mov	ax, cx
	call	TextRegion_DerefVis_DI
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	huge

	mov	si, ds:[di].VLTI_regionArray	;*ds:si = array
EC <	call	ECLMemValidateHandle					>
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	mov	dx, ds:[di].CAH_elementSize
	sub	cx, ax
	
	call	ChunkArrayElementToPtr		;ds:di = VisTextRegionArrayEl
	mov	si, di
	jmp	done

	; region is in huge array, ax = region number

huge:
	call	VisLargeTextGetRegionCount	;cx = count
	sub	cx, ax				;cx = # regions after this one
	push	cx
	mov_tr	cx, ax				;cx = region to point to
	call	PointAtRegionElement		;ds:di = element, ax = "size"
	mov_tr	dx, ax				;dx = "size"
	mov	si, di				;ds:si = data
	pop	cx

done:
	.leave
;	ProfilePoint 33
	ret

PointAtRegionElementAsScanDoes	endp

;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetTrueWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of the rectangle bounding a region.

CALLED BY:	TR_RegionGetTrueWidth
PASS:		*ds:si	= Instance ptr
		cx	= Region number
		bx	= non-zero to get value for blt-ing
RETURN:		ax	= Width of bounding rectangle
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetTrueWidth	proc	near	uses di
	class	VisLargeTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

	call	TextRegion_DerefVis_DI
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jae	useDisplayModeWidth
	tst	bx
	jz	useRegionWidth
	cmp	ds:[di].VLTI_displayMode, VLTDM_GALLEY
	jae	useDisplayModeWidth
useRegionWidth:
	call	PointAtRegionElement		; ds:di = data, z set if last
	mov	ax, ds:[di].VLTRAE_size.XYS_width
done:
	.leave
	ret

useDisplayModeWidth:
	mov	ax, ds:[di].VLTI_displayModeWidth
	jmp	done

LargeRegionGetTrueWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the computed height of a region.

CALLED BY:	TR_RegionGetHeight
PASS:		*ds:si	= Instance ptr
		cx	= Region number
RETURN:		dx.al	= Computed height of bounding rectangle
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetHeight	proc	near
	call	PointAtRegionElement		; ds:di = data, z set if last
	movwbf	dxal, ds:[di].VLTRAE_calcHeight
	ret

LargeRegionGetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetTrueHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the rectangle bounding a region.

CALLED BY:	TR_RegionGetTrueHeight
PASS:		*ds:si	= Instance ptr
		cx	= Region number
RETURN:		dx.al	= Height of bounding rectangle
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetTrueHeight	proc	near
	class	VisLargeTextClass
EC <	call	T_AssertIsVisLargeText					>

	call	TextRegion_DerefVis_DI
	mov	dx, ds:[di].VLTI_draftRegionSize.XYS_height
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jae	done

	;
	; The height of the region is one of two things:
	;    Has a Region -
	;	Height is the height of the region-rectangle
	;    Has no Region -
	;	Height is the height of the bounding rectangle
	;
	call	GetFillRegion			; axdi = region or...
						;  ax = width, di = height
	jc	regionExists
	
	call	PointAtRegionElement		; ds:di = data, z set if last
	mov	dx, ds:[di].VLTRAE_size.XYS_height
done:
	clr	ax
	ret


regionExists:
	push	ds, si				; Save nuked registers
	call	DBLockToDSSI			; ds:si <- ptr to region

	sub	si, size Rectangle		; ds:si <- ptr to rectangle
	mov	dx, ds:[si].R_bottom		; dx <- height of area
	sub	dx, ds:[si].R_top

	call	DBUnlockDS			; Release the region
	pop	ds, si				; Restore nuked registers
	jmp	done

LargeRegionGetTrueHeight	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeCheckCrossSectionChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a range crosses a section break.

CALLED BY:	TR_CheckCrossSectionChange
PASS:		*ds:si	= Instance
		ss:bp	= VisTextRange
RETURN:		carry set if the range crosses sections
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We take advantage of the fact that if an offset falls at the end
	of the last region in a section, FindRegionByOffset will return
	the first region of the next section.
	
	This means that if the user selects just the section break and
	tries to delete it, even though it appears (visually) as though
	the selected range is in a single section, FindRegionByOffset will
	treat the range as though it crosses sections.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeCheckCrossSectionChange	proc	far
	uses	ax, cx, dx, di, si
	class	VisLargeTextClass
	.enter

	; If the object has no regions then skip this check

	call	TextRegion_DerefVis_DI
	tst	ds:[di].VLTI_regionArray
	jz	quit
	;
	; Figure the start region.
	;
	mov	di, si				; Save instance ptr
	movdw	dxax, ss:[bp].VTR_start
	call	FindRegionByOffset		; ds:si <- region data
	xchg	di, si				; *ds:si <- instance
						; ds:di <- start region

	;
	; Figure the end region.
	;
	movdw	dxax, ss:[bp].VTR_end
	call	FindRegionByOffset		; ds:si <- region data
	
	;
	; ds:di	= Start region
	; ds:si	= End region
	;
	cmp	di, si				; Check for same region
	je	quit				; Carry clear if we branch
	
	;
	; The start/end regions aren't the same. Check that the sections
	; are the same.
	;
	mov	ax, ds:[di].VLTRAE_section
	cmp	ax, ds:[si].VLTRAE_section
	jne	badReplace

quit:
	.leave
	ret

badReplace:
	stc					; Signal: cross section replace
	jmp	quit
LargeCheckCrossSectionChange	endp

TextRegion	ends

TextLargeRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionAlterFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the flags for a large region.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
		ax	= Bits to set
		dx	= Bits to clear
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionAlterFlags	proc	near
	uses	dx, di
	.enter
	push	ax
	call	PointAtRegionElement		; ds:di = data, z set if last
	pop	ax
	
	push	ds:[di].VLTRAE_flags		; Save old flags
	
	not	dx
	and	ds:[di].VLTRAE_flags, dx		; Clear flags
	or	ds:[di].VLTRAE_flags, ax		; Set flags
	
	pop	dx				; dx <- old flags
	
	;
	; Check for region-break state change.
	; ax	= New flags
	; dx	= Old flags
	;
	and	ax, mask VLTRF_ENDED_BY_COLUMN_BREAK

	and	dx, mask VLTRF_ENDED_BY_COLUMN_BREAK

	xor	ax, dx
	
	;
	; ax will be non-zero if there has been a change.
	;
	tst	ax
	jz	quit				; Branch if no change
	call	TR_RegionTransformGState	; Setup the gstate
	call	LargeRegionClearToBottom	; Draw the break
quit:
	.leave
	ret
LargeRegionAlterFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the flags for a large region.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		ax	= VisTextRegionFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetFlags	proc	near
	uses	di
	.enter
	call	PointAtRegionElement		; ds:di = data, z set if last
	mov	ax, ds:[di].VLTRAE_flags
	.leave
	ret
LargeRegionGetFlags	endp

TextLargeRegion	ends
