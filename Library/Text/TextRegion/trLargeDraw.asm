COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeDraw.asm

AUTHOR:		John Wedgwood, Dec 23, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/23/92	Initial revision

DESCRIPTION:
	Code for drawing stuff.

	$Id: trLargeDraw.asm,v 1.1 97/04/07 11:21:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeEnumRegionsInClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the regions in a clip rectangle.

CALLED BY:	TR_RegionEnumRegionsInClipRect
PASS:		*ds:si	= Instance
		ds:di	= Instance
		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_flags
				TREP_callback
				TREP_region
				TREP_globalClipRect
				TREP_object
				TREP_displayMode
				TREP_regionSpacing
				TREP_draftRegionSize
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version
	mg	03/31/00	Added check for null masks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeEnumRegionsInClipRect	proc	near
	class	VisLargeTextClass
	uses	ax, bx, cx, dx, si, ds
	.enter
	;
	; Get the clip-rectangle.
	;
	push	ds, si, di			; Save instance
	mov	di, ds:[di].VTI_gstate		; di <- gstate
	
	call	GrSaveState			; Save old gstate...

	call	GrSetDefaultTransform		; No translation

	segmov	ds, ss, si			; ds:si <- ptr to rect
	lea	si, ss:[bp].TREP_globalClipRect
	call	GrGetMaskBoundsDWord		; Get the mask bounds

	pushf
	call	GrRestoreState			; Restore old gstate...
	popf

	pop	ds, si, di			; Restore instance
	jc	quit				; Null path: all regions fail

	;
	; Copy some things from the instance data...
	;
	mov	ax, ds:[di].VLTI_displayMode	; Set the display mode
	mov	ss:[bp].TREP_displayMode, ax
	
	mov	ax, ds:[di].VLTI_regionSpacing
	mov	ss:[bp].TREP_regionSpacing, ax

	mov	ax, ds:[di].VLTI_draftRegionSize.XYS_width
	mov	ss:[bp].TREP_draftRegionSize.XYS_width, ax

	mov	ax, ds:[di].VLTI_draftRegionSize.XYS_height
	mov	ss:[bp].TREP_draftRegionSize.XYS_height, ax

	;
	; The first region has a starting line/character of zero.
	;
	clrdw	ss:[bp].TREP_regionFirstLine
	clrdw	ss:[bp].TREP_regionFirstChar

	;
	; Set up for skipping through the region list.
	;
	call	SetupForRegionScan		; carry set if no regions
						; ds:si	= First region
						; cx	= Number of regions
						; dx	= Size of region
	;
	; Initialize the TREP_regionTopLeft field, which will depend on our
	; display mode.
	;
	call	InitRegionTopLeft

regionLoop:
	;
	; ds:si	= Current region
	; cx	= Number of regions remaining
	; dx	= Size of region structure
	; ss:bp	= TextRegionEnumParameters
	;
	movdw	ss:[bp].TREP_regionCharCount, ds:[si].VLTRAE_charCount, ax
	movdw	ss:[bp].TREP_regionLineCount, ds:[si].VLTRAE_lineCount, ax

	;
	; Check for current region being empty.
	;
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
	jnz	nextRegion
	
	;
	; Save ptr to the region so other people can use it
	;
	movdw	ss:[bp].TREP_regionPtr, dssi
	
	;
	; Make clipRect be relative to the current region.
	;
	call	MakeClipRectRelative

	;
	; If we are not in page-mode and the bottom edge of the clipRect
	; is negative, then there is no way we will need to do any more work.
	;
	cmp	ss:[bp].TREP_displayMode, VLTDM_PAGE
	je	processRegion
	
	;
	; We're not in page mode, check the bottom edge of the clipRect.
	;
	tst	ss:[bp].TREP_clipRect.RD_bottom.high
	js	quit				; Branch if above this region

processRegion:
	;
	; Compute the height and width and check to see if we need to process
	; this one.
	;
	call	ComputeHeightAndWidth		; ax <- width
						; bx <- height
	call	CommonCheckRegionAndCallback	; Check for callback
						; Sets TREP_regionHeight/Width
						; carry set for "abort"
	jc	quit

nextRegion:
	dec	cx				; One less region to process
	jcxz	quit				; Branch if no more to do
	
	adddw	ss:[bp].TREP_regionFirstLine, ss:[bp].TREP_regionLineCount, ax
	adddw	ss:[bp].TREP_regionFirstChar, ss:[bp].TREP_regionCharCount, ax

	inc	ss:[bp].TREP_region		; Set for next region
	call	ScanToNextRegion		; ds:si <- ptr to next region
	
	call	AdvanceToNextRegion		; ds:si <- next region
	
	jmp	regionLoop			; Loop to do next one

quit:
	.leave
	ProfilePoint 17
	ret
LargeEnumRegionsInClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRegionTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the TREP_regionTopLeft field

CALLED BY:	LargeEnumRegionsInClipRect
PASS:		ss:bp	= TextRegionEnumParameters
		ds:si	= Pointer to first region structure
RETURN:		TREP_regionTopLeft set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitRegionTopLeft	proc	near
	uses	ax
	.enter
	;
	; Assume that we're not in page-mode
	;
	clr	ax
	clrdw	ss:[bp].TREP_regionTopLeft.PD_x
	clrdw	ss:[bp].TREP_regionTopLeft.PD_y
	
	cmp	ss:[bp].TREP_displayMode, VLTDM_PAGE
	jne	quit
	
	;
	; We are in page mode, so we need to actually use the spatial position
	; of the region.
	;
	movdw	ss:[bp].TREP_regionTopLeft.PD_x, \
		ds:[si].VLTRAE_spatialPosition.PD_x, ax
	
	movdw	ss:[bp].TREP_regionTopLeft.PD_y, \
		ds:[si].VLTRAE_spatialPosition.PD_y, ax
	
	;
	; If there's a region-rectangle, we need to account for that too.
	;
	tst	ds:[si].VLTRAE_region.high	; Check for has special region
	jz	quit				; Branch if it does not
	
	;
	; Account for rectangle.
	;
	push	ds, si, di
	movdw	axdi, ds:[si].VLTRAE_region	; ax.di <- db item
	mov	si, {word}ss:[bp].TREP_object	; needs instance [mg, 02/26/00]
	call	DBLockToDSSI			; ds:si <- ptr to region
	sub	si, size Rectangle		; ds:si <- bounding rectangle

	mov	ax, ds:[si].R_top
	add	ss:[bp].TREP_regionTopLeft.PD_y.low, ax
	adc	ss:[bp].TREP_regionTopLeft.PD_y.high, 0

	call	DBUnlockDS			; Release region
	pop	ds, si, di

quit:
	.leave
	ret
InitRegionTopLeft	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeClipRectRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make TREP_clipRect be relative to the current region.

CALLED BY:	LargeEnumRegionsInClipRect
PASS:		ds:si	= Current region
		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_regionTopLeft
				TREP_globalClipRect
RETURN:		TREP_clipRect set relative to the current region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeClipRectRelative	proc	near
	uses	ax, bx
	.enter

	;
	; The top/bottom coordinates
	;
	movdw	bxax, ss:[bp].TREP_globalClipRect.RD_top
	subdw	bxax, ss:[bp].TREP_regionTopLeft.PD_y
	movdw	ss:[bp].TREP_clipRect.RD_top, bxax

	movdw	bxax, ss:[bp].TREP_globalClipRect.RD_bottom
	subdw	bxax, ss:[bp].TREP_regionTopLeft.PD_y
	movdw	ss:[bp].TREP_clipRect.RD_bottom, bxax

	;
	; The left/right coordinates
	;
	movdw	bxax, ss:[bp].TREP_globalClipRect.RD_left
	subdw	bxax, ss:[bp].TREP_regionTopLeft.PD_x
	movdw	ss:[bp].TREP_clipRect.RD_left, bxax

	movdw	bxax, ss:[bp].TREP_globalClipRect.RD_right
	subdw	bxax, ss:[bp].TREP_regionTopLeft.PD_x
	movdw	ss:[bp].TREP_clipRect.RD_right, bxax

	.leave
	ret
MakeClipRectRelative	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeHeightAndWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the height and width of the current region.

CALLED BY:	LargeEnumRegionsInClipRect
PASS:		ds:si	= Region pointer
		ss:bp	= TextRegionEnumParameters
RETURN:		ax	= Width
		bx	= Height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Page:
	Condensed:
	Galley:
		Use region width and calcHeight
		Use region width and calcHeight
		Use region width and calcHeight

	Draft w/  Styles:
	Draft w/o Styles:
		Use draftRegionSize stored with object

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeHeightAndWidth	proc	near
	class	VisLargeTextClass
	.enter
	cmp	ss:[bp].TREP_displayMode, VLTDM_DRAFT_WITH_STYLES
	jae	useDraftRegionSize

	;
	; It's not draft mode...
	;	
	tst	ds:[si].VLTRAE_region.high	; Check for has special region
	jnz	regionExists			; Branch if it does
	
	;
	; It's that old standard rectangular region.
	;
	ceilwbf	ds:[si].VLTRAE_calcHeight, bx	; bx <- height
	mov	ax, ds:[si].VLTRAE_size.XYS_width ; ax <- width

	;
	; In condensed mode, we need to make sure that we use the real
	; height of the region, so we can ensure that we draw the break
	; between regions.
	;
	cmp	ss:[bp].TREP_displayMode, VLTDM_CONDENSED
	jne	quit				; Branch if page or galley
	
	;
	; It's condensed mode. In order to get the area between the regions
	; to draw, we must include the entire area, not just the area covered
	; by lines.
	;
	mov	bx, ds:[si].VLTRAE_size.XYS_height

quit:
	.leave
	ret


useDraftRegionSize:
	;
	; Use the draftRegionSize stored with the instance data
	;
	mov	ax, ss:[bp].TREP_draftRegionSize.XYS_width
	mov	bx, ss:[bp].TREP_draftRegionSize.XYS_height

	jmp	quit


regionExists:
	;
	; There is a special clip-region associated with this flow-region.
	; We need to lock it down and extract the special information for it.
	;
	push	ds, si, di
	movdw	axdi, ds:[si].VLTRAE_region	; ax.di <- db item
	mov	si, {word}ss:[bp].TREP_object	; needs instance [mg, 02/26/00]
	call	DBLockToDSSI			; ds:si <- ptr to region
	sub	si, size Rectangle		; ds:si <- bounding rectangle

	mov	bx, ds:[si].R_bottom		; bx <- height
	sub	bx, ds:[si].R_top
	mov	ax, ds:[si].R_right		; ax <- width
	sub	ax, ds:[si].R_left

	call	DBUnlockDS			; Release region
	pop	ds, si, di
	jmp	quit
ComputeHeightAndWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdvanceToNextRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance to the next region.

CALLED BY:	LargeEnumRegionsInClipRect
PASS:		ds:si	= Pointer to next region
		dx	= Size of region element
		ss:bp	= TextRegionEnumParameters w/ these set:
				TREP_regionHeight
				TREP_regionWidth
RETURN:		TextRegionEnumParameters w/ these updated
				TREP_regionTopLeft
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Page:
		Use InitRegionTopLeft to set the top/left

	Condensed:
		if (previous region has region data) then
		    Adjust Y position by TREP_regionHeight
		else
		    Adjust Y position by previous region size.height
		endif
		Adjust Y position to include region spacing

	Galley/Draft:
		Adjust Y position by previous region calcHeight
		Adjust Y position to include region spacing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ds:si *must* be valid when you call this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdvanceToNextRegion	proc	near
	uses	ax, di
	.enter
	mov	di, si				; ds:di <- previous region
	sub	di, dx

	cmp	ss:[bp].TREP_displayMode, VLTDM_PAGE
	je	pageMode

	cmp	ss:[bp].TREP_displayMode, VLTDM_CONDENSED
	je	condensedMode
	
	;
	; Galley or draft...
	;
	ceilwbf	ds:[di].VLTRAE_calcHeight, ax


accountForRegionSpacing:
	;
	; Account for region spacing.
	; 
	; ax	= height of region without it
	;
	add	ax, ss:[bp].TREP_regionSpacing
	add	ss:[bp].TREP_regionTopLeft.PD_y.low, ax
	adc	ss:[bp].TREP_regionTopLeft.PD_y.high, 0

quit:
	.leave
	ret


pageMode:
	call	InitRegionTopLeft
	jmp	quit


condensedMode:
	mov	ax, ss:[bp].TREP_regionHeight	; Assume has region data
	tst	ds:[di].VLTRAE_region.high	; Check for region data
	jnz	accountForRegionSpacing
	
	;
	; It doesn't have region data.
	;
	mov	ax, ds:[di].VLTRAE_size.XYS_height
	jmp	accountForRegionSpacing

AdvanceToNextRegion	endp

TextDrawCode	ends
