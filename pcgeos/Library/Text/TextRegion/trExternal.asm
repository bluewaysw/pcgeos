COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trExternal.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	All of the externally callable routines.

	$Id: trExternal.asm,v 1.1 97/04/07 11:21:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextRegion	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of the region at a given y position.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number
		dx	= Y position within that region
		bx	= Integer height of the line at that position
RETURN:		ax	= Width of the region at that point.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionWidth	proc	far	uses bx
	.enter

	call	TR_RegionLeftRight
	sub	bx, ax
	mov_tr	ax, bx

	.leave
	ret
TR_RegionWidth	endp

;--------------

MakeRegionHandler	macro	rout, const
rout	proc	far
	push	di
	mov	di, const
	GOTO	RegionHandlerCommon, di
rout	endp
endm

;--------------

RegionHandlerCommon	proc	far
	call	CallRegionHandler
	FALL_THRU_POP	di
	ret
RegionHandlerCommon	endp

;--------------

MakeRegionHandler	TR_RegionGetTrueWidth, TRV_REGION_GET_TRUE_WIDTH
MakeRegionHandler	TR_RegionLeftRight, TRV_REGION_LEFT_RIGHT
MakeRegionHandler	TR_RegionNextSegmentTop, TRV_NEXT_SEGMENT_TOP
MakeRegionHandler	TR_RegionAdjustForReplacement, TRV_ADJUST_FOR_REPLACEMENT
MakeRegionHandler	TR_RegionSetStartOffset, TRV_SET_START_OFFSET
MakeRegionHandler	TR_RegionGetStartOffset, TRV_GET_START_OFFSET
MakeRegionHandler	TR_RegionAdjustHeight, TRV_ADJUST_HEIGHT
MakeRegionHandler	TR_RegionGetHeight, TRV_GET_HEIGHT
MakeRegionHandler	TR_RegionGetTrueHeight, TRV_GET_TRUE_HEIGHT
MakeRegionHandler	TR_RegionMakeNextRegion, TRV_MAKE_NEXT_REGION
MakeRegionHandler	TR_RegionGetLineCount, TRV_GET_LINE_COUNT
MakeRegionHandler	TR_RegionGetCharCount, TRV_GET_CHAR_COUNT
MakeRegionHandler	TR_RegionFromOffset, TRV_REGION_FROM_OFFSET
MakeRegionHandler	TR_RegionFromPoint, TRV_REGION_FROM_POINT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionLinesInClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of lines in a region that fall inside a 
		given rectangle.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number
		ss:bp	= TextRegionEnumParameters
		ss:bx	= VisTextRange to fill in
RETURN:		VisTextRange holds the range of lines
		carry set if no lines appear in the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionLinesInClipRect	proc	far
	tst	ss:[bp].TREP_clipRect.RD_right.high
	stc
	js	done
	tst	ss:[bp].TREP_clipRect.RD_bottom.high
	stc
	js	done

	push	di
	mov	di, TRV_LINES_IN_CLIP_RECT
	GOTO	RegionHandlerCommon, di

done:
	ret
TR_RegionLinesInClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionSetTopLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the top-line associated with a given region.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number
		bx.di	= Line at the top of that region
		ax	= "Previous" region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionSetTopLine	proc	far
	uses	dx, di
	.enter
	mov	dx, di			; bx.dx <- line
	mov	di, TRV_SET_TOP_LINE
	call	CallRegionHandler
	.leave
	ret
TR_RegionSetTopLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionGetTopLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top-line associated with a given region.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number
RETURN:		bx.di	= Line at the top of that region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionGetTopLine	proc	far
	mov	di, TRV_GET_TOP_LINE
	call	CallRegionHandler
	ret
TR_RegionGetTopLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionFromOffsetGetStartLineAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an offset, return the start offset and line of the region
		in which the offset falls.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		dx.ax	= Offset
RETURN:		dx.ax	= Start offset of the region
		bx.di	= Start line of the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionFromOffsetGetStartLineAndOffset	proc	far
	mov	di, TRV_REGION_FROM_OFFSET_GET_START_LINE_AND_OFFSET
	call	CallRegionHandler
	ret
TR_RegionFromOffsetGetStartLineAndOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionFromLineGetStartLineAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a line, return the start offset and line of the region
		in which the line falls.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		bx.di	= Line
RETURN:		dx.ax	= Start offset of the region
		bx.di	= Start line of the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionFromLineGetStartLineAndOffset	proc	far
	mov	dx, di			; bx.dx <- line
	mov	di, TRV_REGION_FROM_LINE_GET_START_LINE_AND_OFFSET
	call	CallRegionHandler
	ret
TR_RegionFromLineGetStartLineAndOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionAdjustNumberOfLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the number of lines in a region.

CALLED BY:	External
PASS:		cx	= Region
		bx.di	= First line where adjustment happened
		dx.ax	= Number inserted/deleted
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionAdjustNumberOfLines	proc	far
	uses	ax, dx, di, bp
	.enter
	;
	; Quick check to make sure we are actually doing anything.
	;
	tstdw	dxax
	jz	quit

	;
	; Allocate a stack frame.
	;
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp				; ss:bp <- stack frame

	;
	; Initialize the stack frame
	;
	movdw	ss:[bp].VTRP_range.VTR_start, bxdi
	
	;
	; Assume inserting.
	;
	movdw	ss:[bp].VTRP_insCount, dxax
	movdw	ss:[bp].VTRP_range.VTR_end, bxdi
	
	tst	dx				; Check for inserting
	jns	gotFrame			; Branch if we are
	
	;
	; Deleting... Change stuff around
	;
	negdw	dxax				; dx.ax <- number deleted
	adddw	dxax, bxdi			; dx.ax <- last line
	movdw	ss:[bp].VTRP_range.VTR_end, dxax
	clrdw	ss:[bp].VTRP_insCount		; Not inserting

gotFrame:
	

	;
	; Call the handler
	;
	mov	di, TRV_ADJUST_NUMBER_OF_LINES
	call	CallRegionHandler
	
	;
	; Restore stack and quit.
	;
	add	sp, size VisTextReplaceParameters

quit:
	.leave
	ret
TR_RegionAdjustNumberOfLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionInsertLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert lines into a region.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
		dx.ax	= Number to insert
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionInsertLines	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextRegion_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;;; Do nothing for a small region
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionInsertLines
	jmp	quit
TR_RegionInsertLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionClearToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear to region bottom

CALLED BY:	Global
PASS:		*ds:si	= Instance
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
TR_RegionClearToBottom	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextRegion_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	call	SmallRegionClearToBottom
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionClearToBottom
	jmp	quit
TR_RegionClearToBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionClearSegments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear an area, taking into account the region boundaries.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
		ax	= Top of area
		bx	= Bottom of area
		dx	= Left edge to clear from 
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionClearSegments	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextRegion_DerefVis_DI	; ds:di <- instance
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	call	SmallRegionClearSegments
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionClearSegments
	jmp	quit
TR_RegionClearSegments	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionIsLastInSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a region is the last in its section.

CALLED BY:	External
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry set if the region is the last in the section
		    zero set if the region is the last non-empty region
		       in the last section of the object.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionIsLastInSection	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextRegion_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	clr	di			; Set the zero flag
	stc				; Is last in section
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionIsLastInSection
	jmp	quit
TR_RegionIsLastInSection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRegionHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the handler appropriate for the type of object.

CALLED BY:	TR_*
PASS:		*ds:si	= Instance ptr
		di	= TextRegionVariant
		Other registers set for the handler
RETURN:		Registers set by the handler
		Flags set by the handler
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallRegionHandler	proc	near
	class	VisTextClass
	.enter
	;
	; Choose the routine to call based on the 
	;
	push	ax, si				; Save parameter, chunk
	call	TextRegion_DerefVis_SI
	
	;
	; Choose a table to use for calling the appropriate handler
	;
	; ds:si = Instance ptr.
	;
	mov	ax, offset cs:SmallRegionHandlers
	test	ds:[si].VTI_storageFlags, mask VTSF_LARGE
	jz	gotHandlerTableOffset		; Branch if small format
	mov	ax, offset cs:LargeRegionHandlers

gotHandlerTableOffset:
	;
	; Get a pointer to the routine to call.
	; di	= TextRegionVariant
	; ax	= Offset to the table to use
	;
	add	di, ax				; di <- ptr to routine to use
	pop	ax, si				; Restore parameter, chunk

	call	cs:[di]				; Call the handler
	.leave
	ret					; Return to the routine to call
CallRegionHandler	endp



SmallRegionHandlers	word	\
	offset SmallRegionGetTrueWidth,		; TRV_REGION_GET_TRUE_WIDTH
	offset SmallRegionLeftRight,		; TRV_REGION_LEFT_RIGHT
	offset SmallRegionLinesInClipRect,	; TRV_LINES_IN_CLIP_RECT
	offset SmallRegionNextSegmentTop,	; TRV_NEXT_SEGMENT_TOP
;;;	offset SmallRegionNext,			; TRV_REGION_NEXT
	0,
;;;	offset SmallRegionPrevious,		; TRV_REGION_PREV
	0,
	offset SmallAdjustForReplacement,	; TRV_ADJUST_FOR_REPLACEMENT
	offset SmallRegionSetStartOffset,	; TRV_SET_START_OFFSET
	offset SmallAdjustNumberOfLines,	; TRV_ADJUST_FOR_REPLACEMENT
	offset SmallRegionSetTopLine,		; TRV_SET_TOP_LINE

	offset SmallRegionGetTopLine,		; TRV_GET_TOP_LINE
	offset SmallRegionGetStartOffset,	; TRV_GET_START_OFFSET
	offset SmallRegionAdjustHeight,		; TRV_ADJUST_HEIGHT
	offset SmallRegionGetHeight,		; TRV_GET_HEIGHT
	offset SmallRegionGetTrueHeight,	; TRV_GET_TRUE_HEIGHT
	offset SmallRegionMakeNextRegion,	; TRV_MAKE_NEXT_REGION
;;;	offset SmallRegionRegionIsLast,		; TRV_REGION_IS_LAST
	0,
;;;	offset SmallRegionGetRegionTopLeft,	; TRV_GET_REGION_TOP_LEFT
	0,
;;;	offset SmallRegionClearToBottom,	; TRV_CLEAR_TO_BOTTOM
	0,
	offset SmallRegionGetLineCount,		; TRV_GET_LINE_COUNT
	offset SmallRegionGetCharCount,		; TRV_GET_CHAR_COUNT
;;;	offset SmallRegionTransformGState,	; TRV_TRANSFORM_GSTATE
	0,
	offset SmallRegionFromOffset,		; TRV_REGION_FROM_OFFSET
	offset SmallRegionFromOffsetGetStartLineAndOffset,
	offset SmallRegionFromOffsetGetStartLineAndOffset,
    ;;; ^^^ This is not a misprint. The same routine handles both calls
;;;	offset SmallRegionFromLine,		; TRV_REGION_FROM_LINE
	0,
	offset SmallRegionFromPoint		; TRV_REGION_FROM_POINT

LargeRegionHandlers	word	\
	offset LargeRegionGetTrueWidth,		; TRV_REGION_GET_TRUE_WIDTH
	offset LargeRegionLeftRight,		; TRV_REGION_LEFT_RIGHT
	offset LargeRegionLinesInClipRect,	; TRV_LINES_IN_CLIP_RECT
	offset LargeRegionNextSegmentTop,	; TRV_NEXT_SEGMENT_TOP
;;;	offset LargeRegionNext,			; TRV_REGION_NEXT
	0,
;;;	offset LargeRegionPrevious,		; TRV_REGION_PREV
	0,
	offset LargeAdjustForReplacement,	; TRV_ADJUST_FOR_REPLACEMENT
	offset LargeRegionSetStartOffset,	; TRV_SET_START_OFFSET
	offset LargeAdjustNumberOfLines,	; TRV_ADJUST_FOR_REPLACEMENT
	offset LargeRegionSetTopLine,		; TRV_SET_TOP_LINE

	offset LargeRegionGetTopLine,		; TRV_GET_TOP_LINE
	offset LargeRegionGetStartOffset,	; TRV_GET_START_OFFSET
	offset LargeRegionAdjustHeight,		; TRV_ADJUST_HEIGHT
	offset LargeRegionGetHeight,		; TRV_GET_HEIGHT
	offset LargeRegionGetTrueHeight,	; TRV_GET_TRUE_HEIGHT
	offset LargeRegionMakeNextRegion,	; TRV_MAKE_NEXT_REGION
;;;	offset LargeRegionRegionIsLast,		; TRV_REGION_IS_LAST
	0,
;;;	offset LargeRegionGetRegionTopLeft,	; TRV_GET_REGION_TOP_LEFT
	0,
;;;	offset LargeRegionClearToBottom,	; TRV_CLEAR_TO_BOTTOM
	0,
	offset LargeRegionGetLineCount,		; TRV_GET_LINE_COUNT
	offset LargeRegionGetCharCount,		; TRV_GET_CHAR_COUNT
;;;	offset LargeRegionTransformGState,	; TRV_TRANSFORM_GSTATE
	0,
	offset LargeRegionFromOffset,		; TRV_REGION_FROM_OFFSET
	offset LargeRegionFromOffsetGetStartLineAndOffset,
	offset LargeRegionFromLineGetStartLineAndOffset,
;;;	offset LargeRegionFromLine,		; TRV_REGION_FROM_LINE
	0,
	offset LargeRegionFromPoint		; TRV_REGION_FROM_POINT

TextRegion	ends

;****************************************************************************
;			    Fixed Routines
;****************************************************************************

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionFromLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the region associated with a given line.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		bx.di	= Line
RETURN:		cx	= Region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionFromLine	proc	far
	class	VisTextClass
	uses	dx, di
	ProfilePoint 35
	.enter
	mov	dx, di				; bx.dx <- line

	call	TextFixed_DerefVis_DI		; ds:di <- instance
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject			; Branch if large format

	call	SmallRegionFromLine
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionFromLine
	ProfilePoint 34
	jmp	quit
TR_RegionFromLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionGetTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top/left edge of a region.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number
		ss:bp	= PointDWord to fill in
RETURN:		PointDWord contains the top-left corner of the region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionGetTopLeft	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject			; Branch if large format

	call	SmallRegionGetRegionTopLeft
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionGetRegionTopLeft
	jmp	quit
TR_RegionGetTopLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionTransformGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the gstate so that the origin falls at the 
		upper-left corner of the region.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		cx	= Region
		dl	= DrawFlags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionTransformGState	proc	far
	class	VisTextClass
	uses	di
	.enter

	; if we've already translated for this region then we can exit

	call	TextFixed_DerefVis_DI
	cmp	cx, ds:[di].VTI_gstateRegion
	jz	done
	mov	ds:[di].VTI_gstateRegion, cx

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject			; Branch if large format

	call	SmallRegionTransformGState

done:
	.leave
	ret

isLargeObject:

	call	LargeRegionTransformGState
	jmp	done

TR_RegionTransformGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next region

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry flag set if there is no next region
		carry flag clear otherwise
			zero flag clear (nz) if passed region is last
			zero flag set   (z) otherwise
			cx	= Next region number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionNext	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;
	; Small objects only have one region.
	;
	stc				; Signal: No more regions
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionNext
	jmp	quit
TR_RegionNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionPrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the previous region

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry set if there is no previous region
		carry clear otherwise
		   cx	= Previous region number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionPrev	proc	far
	jcxz	noMore

	dec	cx			; cx <- previous region
	clc				; Signal: has a previous region
quit:
	ret

noMore:
	stc				; Signal: no previous region
	jmp	quit
TR_RegionPrev	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionPrevSkipEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to either the immediately previous region, or else the
		first of a series of regions which fall before the current
		one.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry set if there is no previous region
		carry clear otherwise
		   cx	= Previous region number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionPrevSkipEmpty	proc	far
	jcxz	noMore

	;
	; Large objects are the only ones with multiple regions.
	;
	call	LargeRegionPrevSkipEmpty
quit:
	ret

noMore:
	stc				; Signal: no previous region
	jmp	quit
TR_RegionPrevSkipEmpty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionIsLast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify someone that the current region is the last one
		in its section that contains any data.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number which is the last
RETURN:		bx.dx.ax= Sum of calc'd height of nuked regions
		cx	= Number of non-empty regions deleted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionIsLast	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;
	; Small objects only have one region.
	;
	clr	cx, bx, dx, ax
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionRegionIsLast
	jmp	quit
TR_RegionIsLast	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionIsComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a region is complex (non-rectangular)

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Region number
RETURN:		carry	= Set if complex
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionIsComplex	proc	far	uses di
	class	VisLargeTextClass
	.enter

	call	TextFixed_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE	;clear carry
	jz	done

	; large object -- check flags

	push	ax
	call	PointAtRegionElement		;ds:di = element
	mov	ax, ds:[di].VLTRAE_region.high
	or	ax, ds:[di].VLTRAE_region.low	;clears carry
	jz	10$
	stc
10$:
	pop	ax

done:
	.leave
	ret
TR_RegionIsComplex	endp

TextFixed	ends

TextLargeRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionAlterFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter flags for a region.

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
TR_RegionAlterFlags	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	Text_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;
	; Do nothing for small objects
	;
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionAlterFlags
	jmp	quit
TR_RegionAlterFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get flags for a region.

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
TR_RegionGetFlags	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	Text_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;
	; For small objects, the flags are simple...
	;
	clr	ax
quit:
	.leave
	ret

isLargeObject:
	call	LargeRegionGetFlags
	jmp	quit
TR_RegionGetFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_CheckCrossSectionChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a range crosses a section break.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		ss:bp	= VisTextRange
RETURN:		carry set if the range crosses sections
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_CheckCrossSectionChange	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	Text_DerefVis_DI	; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;
	; For small objects, it's easy...
	;
	clc				; Not deleting across a section.
quit:
	.leave
	ret

isLargeObject:
	call	LargeCheckCrossSectionChange
	jmp	quit	
TR_CheckCrossSectionChange	endp


TextLargeRegion	ends

TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionGetSectionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range of text covered by a given section.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		cx	= Section
RETURN:		dx.ax	= Start of section
		cx.bx	= End of section (start of next section)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
TR_RegionGetSectionRange	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextInstance_DerefVis_DI ; ds:di <- instance

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject		; Branch if large format
	
	;
	; For small objects, it's easy...
	;
	call	TS_GetTextSize		; dx.ax <- end
	clrdw	cxbx			; cx.bx <- start
	
	xchgdw	cxbx, dxax		; dx.ax <- start
					; cx.bx <- end
quit:
	.leave
	ret

isLargeObject:
	call	LargeGetSectionRange
	jmp	quit	
TR_RegionGetSectionRange	endp
endif


TextInstance	ends

TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TR_RegionEnumRegionsInClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the regions in the clip-rectangle associated with
		the window containing the text object.

CALLED BY:	TextDraw, TextScreenUpdate

PASS:		*ds:si	= Instance
		ss:bp	= TextRegionEnumParameters w/ at least these set:
				TREP_callback
				TREP_flags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TR_RegionEnumRegionsInClipRect	proc	far
	class	VisLargeTextClass
	uses	di
	.enter
	;
	; Initialize the stack frame.
	;
	movdw	ss:[bp].TREP_object, dssi	; Save object instance ptr
	
	clr	ss:[bp].TREP_region

	mov	di, ds:[si]			; ds:di <- instance ptr
	add	di, ds:[di].Vis_offset
	
	;
	; Now that we're all set up, enumerate the regions.
	;
	; *ds:si= Instance
	; ds:di	= Instance
	; ss:bp	= TextRegionEnumParameters w/ these set:
	;		TREP_flags
	;		TREP_callback
	;		TREP_region
	;		TREP_object
	;
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	isLargeObject
	
	call	SmallEnumRegionsInClipRect

quit:
	.leave
	ret

isLargeObject:
	call	LargeEnumRegionsInClipRect
	jmp	quit

TR_RegionEnumRegionsInClipRect	endp


TextDrawCode	ends
