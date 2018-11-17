COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeClear.asm

AUTHOR:		John Wedgwood, Feb 18, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/18/92	Initial revision

DESCRIPTION:
	Code for clearing in regions.

	$Id: trLargeClear.asm,v 1.1 97/04/07 11:21:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionClearToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear from the bottom of a line to the bottom of the 
		region containing that line.

CALLED BY:	TR_RegionClearToBottom via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionClearToBottom	proc	far
	class	VisLargeTextClass
	uses	ax, bx, cx, dx

	call	TextRegion_DerefVis_DI
region		local	word	push	cx
displayMode	local	VisLargeTextDisplayModes	\
				push	ds:[di].VLTI_displayMode

	.enter
	mov	cx, region			; cx <- region to clear

	call	LargeRegionGetHeight		; dx.al <- height
						; Nukes di
	ceilwbf	dxal, bx			; bx <- calc height
	inc	bx				; start 1 point beyond bottom
						;  of line

	;
	; Condensed-mode and page-mode require a clear since they include
	; the space between the actual regions.
	;
	cmp	displayMode, VLTDM_CONDENSED
	jbe	clear

	;
	; We are in a compressed mode of some sort. We only clear to the
	; bottom if we are in the last region, since it is allowed to be
	; page-sized.
	;
	call	OurLargeRegionIsLastRegionInLastSection
	jnc	afterClear			; Branch if not last region

clear:
	;
	; Clearing isn't as simple as just clearing to the bottom of the
	; region. We need to clear each segment individually. For a region
	; that may be shaped like a rectangle, this can result in one
	; call to GrFillRect for each point between the current position
	; and the bottom of the region.
	;
	mov	ax, bx				; ax <- top of area
	mov	bx, -1				; bx <- "use bottom of region"
	clr	dx				; Use region left
	call	LargeRegionClearSegments	; Clear the area out
	mov	bx, ax				; Restore the Y pos for break

afterClear:

	;
	; Draw any break marker
	;
	call	PointAtRegionElement		; ds:di <- pointer to region
						; ax <- element size
	
	;
	; We do a quick check for empty here because it is possible for
	; a region to be the last in its section, but also be empty. This
	; is true during the transitional phase of recalculation when
	; we have determined that a region is now empty, but we want
	; to clear it out.
	;
	test	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY
	jnz	done				; Branch if empty

	;
	; Not drawing either a column or section break, check for drawing
	; a break due to DRAFT or GALLEY mode. In these modes we draw a
	; break between the pages since there is no other visual indication.
	; If VTF_DONT_SHOW_SOFT_PAGE_BREAKS is set, use background wash and
	; a 100% mask.
	;
	cmp	displayMode, VLTDM_CONDENSED
	jbe	afterBreak			; Branch if no region breaks

	call	TextRegion_DerefVis_DI		; ds:di <- instance
	mov	ax, SDM_50			; mask for region break
	clr	dx				; assume drawing in black
	test	{word}ds:[di].VTI_features, mask VTF_DONT_SHOW_SOFT_PAGE_BREAKS
	jz	drawBreakCommon
	not	dx				; use background wash
	mov	ax, SDM_100			; and fill it all in

drawBreakCommon::
	call	DrawBreakCommon			; draw the region/column/section
						;    break

	;
	; If we're in condensed mode then we may need to draw a region
	; seperator in addition to the break. And you thought this stuff
	; was easy :-)
	;
afterBreak:
	cmp	displayMode, VLTDM_CONDENSED
	jnz	done				; Branch if no region break

	call	LargeRegionGetTrueHeight	; dx.al <- place to draw break
	mov	bx, dx				; bx <- place to draw break
	clr	dx				; don't use bg wash
	mov	ax, SDM_50			; region break mask
	call	DrawBreakCommon			; Draw this break

done:
	.leave
	ret

LargeRegionClearToBottom	endp

;---

OurLargeRegionIsLastRegionInLastSection	proc	near	uses cx, dx, si
	.enter
	call	PointAtRegionElementAsScanDoes
	call	LargeRegionIsLastRegionInLastSection
	.leave
	ret

OurLargeRegionIsLastRegionInLastSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionClearSegments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all segments between two vertical positions.

CALLED BY:	TR_RegionClearSegments
PASS:		*ds:si	= Instance
		ax	= Top of area
		bx	= Bottom of area	(-1 to use bottom of region)
		dx	= Left edge of area	(0 for use region-left)
		cx	= Region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionClearSegments	proc	near
	uses	ax, bx, cx, dx, si, bp, ds
areaTop		local	word		push	ax
areaBottom	local	word		push	bx
areaLeft	local	word		push	dx
	.enter
	;
	; Start clearing out the segments one by one...
	;
	call	GetFillRegion		; carry set if has region
					;	axdi = region
					; carry clear otherwise
					;	ax = width
					;	di = calc-height
	jc	regionExists		; Branch if region exists

;-----------------------------------------------------------------------------
;			      No Region
;-----------------------------------------------------------------------------
	;
	; There's no region, so we want to clear the area passed to us.
	;
	push	ax			; Save width
					; bx holds top of area

	call	LargeRegionGetTrueHeight ; dx.al <- Bottom of area
	ceilwbf	dxal, dx		; dx <- bottom of area

	pop	cx			; cx <- right edge
	mov	ax, areaLeft		; ax <- left edge
	mov	bx, areaTop		; bx <- top edge
	
	;
	; Use the minimum bottom value.
	;
	cmp	dx, areaBottom
	jbe	gotBottom
	mov	dx, areaBottom
gotBottom:

	;
	; *ds:si= Object
	; ax	= Left
	; cx	= Right edge
	; bx	= Top
	; dx	= Bottom
	;
	call	ClearRectCommon		; Clear the area

done:
	.leave
	ret


;-----------------------------------------------------------------------------
;			      Has Region
;-----------------------------------------------------------------------------
regionExists:
	;
	; There is a region. We need to advance through it a bit at a time
	; clearing each rectangle as we find it. Sort of like a video driver.
	;
	push	ds, si			; Save instance ptr
	call	DBLockToDSSI		; ds:si <- ptr to region
	pop	es, di			; *es:di <- instance ptr
	
	mov	dx, areaTop		; dx <- Y position of first swath

clearLoop:
	;
	; dx	= Y position of swath we want to clear
	; ds:si	= Pointer to last swath cleared
	;
	push	dx			; Save bottom of last area
	call	PointAtSwath		; carry set if swath exists
					; ds:si <- start of swath at that Y pos
					; bx <- top of swath
					; dx <- bottom of swath
					; ax <- left edge
					; cx <- right edge
	pop	bx			; bx <- top of area to clear
	jnc	unlockQuit		; Branch if no such swath

	;
	; Make sure we don't clear below the appointed area.
	;
	cmp	dx, areaBottom		; Use minimum of swath and area bottom
	jbe	gotClearBottom		; Branch if swath bottom is less
	mov	dx, areaBottom		; Use area bottom if it's less
gotClearBottom:

	;
	; Use the passed left edge if it's available.
	;
	tst	areaLeft
	jz	gotLeft
	mov	ax, areaLeft		; ax <- left edge passed in
gotLeft:

	;
	; Clear this first swath
	;
	; ax	= Left edge of area to clear
	; cx	= Right edge of swath
	; bx	= Top of swath
	; dx	= Bottom of area to clear
	;
	push	ds, si, es, di		; Save swath ptr

	segmov	ds, es, si		; *ds:si <- instance
	mov	si, di
	call	ClearRectCommon		; Clear the area

	pop	ds, si, es, di		; ds:si <- swath ptr
					; *es:di <- instance

	cmp	dx, areaBottom		; Check for finished the area
	jne	clearLoop		; If not, loop to clear next swath

unlockQuit:
	call	DBUnlockDS		; Release the region
	jmp	done

LargeRegionClearSegments	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointAtSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point at a particular swath of a region, given a Y position.

CALLED BY:	ClearSegments
PASS:		ds:si	= Pointer to the start of some swath in the region.
		dx	= Y position of swath to find
RETURN:		carry set if the swath exists
		ds:si	= Pointer to the swath containing the Y position
		ax	= Left edge of swath
		bx	= Top of this swath
		cx	= Right edge of swath
		dx	= Bottom of this swath
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointAtSwath	proc	near
	uses	bp, di
	.enter
	;
	; Search until we find the segment containing the offset we
	; were passed. If we don't find it, we can just quit.
	;
findSegmentLoop:
	mov	di, si			; ds:di <- current swath
	lodsw				; ax <- y pos of next swath
	
	;
	; It is possible that the position passed may be below the bottom
	; of the object. If that is the case, then the first word of the
	; line will be EOREGREC. If we find that, we just quit.
	;
	cmp	ax, EOREGREC
	je	quitNoSwath

	;
	; Advance to the next swath
	;
	push	ax			; save position of 1st swath
skipSwathLoop:
	lodsw				; skip on/off points
	cmp	ax, EOREGREC		; check for end of swath
	jnz	skipSwathLoop		; loop while there is more swath
	pop	ax			; restore position of 1st swath

	;
	; ds:di	= Pointer to the previous swath
	; ax	= Bottom of previous swath
	;
	; ds:si	= Pointer to current swath
	; dx	= Position we requested
	;
	; Check to see if the current swath contains the region.
	;
	cmp	dx, {word} ds:[si]	; Check for pos >= current.bottom
	jge	findSegmentLoop		; branch if we haven't

	;
	; We have found a swath where the top of the swath is contains the Y
	; position. The swath is the one at ds:di.
	;
	; ds:di	= Swath containing the Y position passed.
	; ds:si	= Next swath
	;
	; Load up the left/right edges and return the top of the previous
	; swath and the current swath position.
	;
	mov	bx, {word} ds:[di]	; bx <- bottom of last swath
	mov	dx, {word} ds:[si]	; dx <- bottom of swath
	
	call	ComputeSwathLeftRight	; ax <- left, cx <- right

	stc				; Signal: swath exists

quit:
	.leave
	ret


quitNoSwath:
	clc				; Signal: no such swath
	jmp	quit
PointAtSwath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeSwathLeftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the widest available area for a given swath.

CALLED BY:	PointAtSwath
PASS:		ds:si	= Swath we're interested in.
RETURN:		ax	= Left edge of widest area
		cx	= Right edge of widest area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Swaths are stored as pairs of on/off points. The first
	entry in the swath is where it turns on.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeSwathLeftRight	proc	near
	uses	bx, dx, si
	.enter
	;
	; ds:si	= Pointer to next section
	;
	lodsw				; ax <- Y pos of swath
	cmp	ax, EOREGREC		; Check for empty swath
	jz	returnNull		; Branch if empty

	;
	; There is another on/off pair
	; ax	= On point
	; ds:si	= Pointer to off point
	;
	lodsw				; ax <- left
	cmp	ax, EOREGREC		; Check for empty swath
	jz	returnNull		; Branch if empty

	mov	cx, ax			; cx <- left
	lodsw				; ax <- right
	xchg	ax, cx			; ax <- left
					; cx <- right
done:
	.leave
	ret

returnNull:
	clr	ax
	clr	cx
	jmp	done
ComputeSwathLeftRight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBreakCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a break indicator

CALLED BY:	DrawColumnBreak, DrawSectionBreak
PASS:		*ds:si	= Instance
		ax	= Draw mask for the break
		bx	= calc height (place to draw the break)
		cx	= region
		dx	= non-zero to use wash color instead
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBreakCommon	proc	near
	class	VisLargeTextClass
	uses	cx, dx
	useWash		local	word	push	dx
	.enter
EC <	call	T_AssertIsVisLargeText					>

	;
	; Save the region so it won't get hurt.
	;
	mov_tr	dx, ax				; dx = mask
	mov_tr	ax, cx				; ax <- region

	call	TextRegion_DerefVis_DI		; ds:di <- instance
	mov	cx, ds:[di].VLTI_regionSpacing	; width of the break
	jcxz	done				; Branch if no width at all

	;
	; There is a break to draw; set the color.
	;
	push	ax, cx, bx			; Save region, break-height,
						; region height
	mov	bx, di				; save instance data
	mov	di, ds:[di].VTI_gstate		; di <- gstate

	mov_tr	ax, dx				; ax = mask
	call	GrSetAreaMask			; Set the color to use

	mov	ax, C_BLACK			; Use black, with some mask
	tst	useWash
	jz	setColor
						; movdw moves into bx first :(
	mov	ax, ({dword}ds:[bx].VTI_washColor).low
	mov	bx, ({dword}ds:[bx].VTI_washColor).high
setColor:
	call	GrSetAreaColor
	pop	cx, ax, bx			; Restore region, break-width
						; (Yes, in opposite registers)
						; restore region height
	;
	; Draw the break.
	;
	; *ds:si= Instance
	; di	= GState (with color and mask set)
	; ax	= Height of the break
	; cx	= Region number
	; bx	= Height of region
	;
	; We need to compute the left/right edges of the region given 
	; this break height at this position.
	;
	push	di, bx, ax			; Save gstate, Y, hgt
	mov	dx, bx				; dx <- y position
	mov	bx, ax				; ax <- height of break
						; cx holds the region
	call	LargeRegionLeftRight		; ax <- left edge
						; bx <- right edge
						; di destroyed
	mov	cx, bx				; cx <- right edge
	pop	di, bx, dx			; Restore gstate, Y, hgt
	
	add	dx, bx				; dx <- bottom
	;
	; di	= GState
	; ax	= Left
	; bx	= Top
	; cx	= Right
	; dx	= Bottom
	;
	call	GrFillRect			; Draw the break

	mov	ax, SDM_100			; Restore the mask
	call	GrSetAreaMask
done:
	.leave
	ret
DrawBreakCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionAdjustHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing. Large regions don't save their heights.

CALLED BY:	TR_RegionAdjustHeight
PASS:		*ds:si	= Instance
		cx	= Region number
		dx.al	= Adjustment
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionAdjustHeight	proc	near	uses	ax, bx, dx
	class	VisLargeTextClass
	.enter
EC <	call	T_AssertIsVisLargeText					>

	pushdw	dxax				; Save adjustment
	call	PointAtRegionElement		; ds:di = data
						; ax <- element size
	popdw	dxax				; Restore adjustment

	ceilwbf	ds:[di].VLTRAE_calcHeight, bx	; bx = old height
	addwbf	ds:[di].VLTRAE_calcHeight, dxal	; Update the calculated height
	ceilwbf	ds:[di].VLTRAE_calcHeight, dx	; dx = new height
	sub	dx, bx				; dx = integer change

	; if we are in gally or draft mode then up the total size

	call	TextRegion_DerefVis_DI
	cmp	ds:[di].VLTI_displayMode, VLTDM_CONDENSED
	jbe	done				;if page or contin then done

	test	ds:[di].VLTI_attrs, mask VLTA_EXACT_HEIGHT
	jnz	adjustHeight
	call	OurLargeRegionIsLastRegionInLastSection
	jc	done

adjustHeight:
	mov_tr	ax, dx
	cwd					;dxax = change
	adddw	ds:[di].VLTI_totalHeight, dxax

	call	SendLargeHeightNotify
done:
	.leave
	ret
LargeRegionAdjustHeight	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendLargeHeightNotify

DESCRIPTION:	Send height notification about a large object

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	none

DESTROYED:
	ax, bx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/27/92		Initial version

------------------------------------------------------------------------------@
SendLargeHeightNotify	proc	near
	class	VisLargeTextClass
EC <	call	T_AssertIsVisLargeText					>

	; mark a height notify pending

	call	TextRegion_DerefVis_DI
	cmp	ds:[di].VLTI_displayMode, VLTDM_PAGE
	jz	done
	ornf	ds:[di].VLTI_flags, mask VLTF_HEIGHT_NOTIFY_PENDING
done:
	ret

SendLargeHeightNotify	endp

TextRegion	ends
