COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlExternal.asm

AUTHOR:		John Wedgwood, Dec 20, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/20/91	Initial revision

DESCRIPTION:
	All of the externally callable routines.

	$Id: tlExternal.asm,v 1.1 97/04/07 11:21:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextLineCalc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert some number of lines.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line to insert before (-1 to append lines)
		dx.ax	= Number of lines to insert
		cx	= Region to add the line to
RETURN:		bx.di	= First new line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineInsert	proc	far
	cmpdw	bxdi, -1
	jne	gotLine

	movdw	bxdi, dxax		; Save old value of dx and ax
	call	TL_LineGetCount		; dx.ax <- past last line
	xchgdw	dxax, bxdi		; Restore dx.ax
					; bx.di <- past last line

gotLine:
	push	ax, cx, dx, di		; Save line.low, count
	mov	cx, di			; bx.cx <- line
	mov	di, TLV_LINE_INSERT
	call	CallLineHandler
	pop	ax, cx, dx, di		; Restore line.low, count
adjustRegion::	
	;
	; When lines are inserted we must update the line-count associated 
	; with the region containing the new lines.
	;
	call	TR_RegionInsertLines
	.leave
	ret
TL_LineInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete some number of lines.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= First line to delete
		dx.ax	= Number of lines to delete
			= -1 to delete all lines starting at bx.di
RETURN:		cx.dx.ax= Cumulative height of deleted lines
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineDelete	proc	far
	uses	di, bp
hgtSum	local	DWFixed
	.enter
	;
	; Figure the count (if we need to)
	;
	cmpdw	dxax, -1
	jne	gotCount
	
	call	TL_LineGetCount		; dx.ax <- total number of lines
	subdw	dxax, bxdi		; dx.ax <- Number to delete

gotCount:
;-------------------------------------------------------------------------
	;
	; When lines are inserted we must update the line-count associated 
	; with the region containing the new lines.
	;
	call	TR_RegionFromLine	; cx <- region
	negdw	dxax			; dx.ax <- Amount of change
	call	TR_RegionAdjustNumberOfLines
	negdw	dxax			; Restore count
	
;-------------------------------------------------------------------------
	;
	; Sum up the line heights for lines
	;
	pushdw	dxax			; Save count
	adddw	dxax, bxdi		; dx.ax <- last line
	clr	cx			; cx <- flags to set (none)
	
	call	TL_LineSumAndMarkRange	; cx.dx.ax <- sum of heights

	movdw	hgtSum.DWF_int, cxdx	; Save the result
	mov	hgtSum.DWF_frac, ax
	popdw	dxax			; Restore count

;-------------------------------------------------------------------------
	;
	; Now do the actual deletion.
	;
	mov	cx, di			; bx.cx <- line
	mov	di, TLV_LINE_DELETE
	call	CallLineHandler

;-------------------------------------------------------------------------
	;
	; Get the result
	;
	movdw	cxdx, hgtSum.DWF_int
	mov	ax, hgtSum.DWF_frac
	.leave
	ret
TL_LineDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineAdjustForReplacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust line offsets after a replacement

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		bx.di	= First line that changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineAdjustForReplacement	proc	far
	mov	di, TLV_LINE_ADJUST_FOR_REPLACEMENT
	call	CallLineHandler
	ret
TL_LineAdjustForReplacement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a line after a change.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line we are calculating
		cx	= LineFlags for line
		ss:bp	= LICL_vars
RETURN:		Various fields of the LICL_vars updated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineCalculate	proc	far
	uses	cx, dx, di
	.enter
	mov	dx, cx			; dx <- LineFlags
	mov	cx, di			; bx.cx <- line
	mov	di, TLV_LINE_CALCULATE
	call	CallLineHandler
	.leave
	ret
TL_LineCalculate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_CommonLineCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the common line-calculation code. This routine is only
		intended to be used by VisTextCalcHeight().

CALLED BY:	VisTextCalcHeight
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars with among other things:
				LICL_range.VTR_start = line start
				Paragraph attributes set
		es:di	= Pointer to the line
		cx	= Size of line/field data
		ax	= LineFlags for current line
RETURN:		LICL_range.VTR_start = start of next line
		LICL_calcFlags updated
		Line pointed at by es:di set correctly
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_CommonLineCalculate	proc	far
	call	CommonLineCalculate
	ret
TL_CommonLineCalculate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineToExtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the extended position of the left edge of a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		cx.bx	= 32 bit left edge of line
		dx.ax	= 32 bit top edge of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineToExtPosition	proc	far
	uses	bp
regTopLeft	local	PointDWord
	.enter
	;
	; Get the region.
	;
	call	TR_RegionFromLine		; cx <- region line is in
	
	;
	; Get the top-left of the region.
	;
	push	bp				; Save frame ptr
	lea	bp, regTopLeft			; ss:bp <- PointDWord
	call	TR_RegionGetTopLeft		; Fill in regTopLeft
	pop	bp				; Restore frame ptr
	
	;
	; Get position of line in the region
	;
	call	TL_LineToPosition		; cx/dx <- position
	
	mov	bx, cx				; cx.bx <- X position
	clr	cx
	
	mov	ax, dx				; dx.ax <- Y position
	clr	dx
	
	;
	; Adjust for region top-left
	;
	adddw	cxbx, regTopLeft.PD_x
	adddw	dxax, regTopLeft.PD_y
	.leave
	ret
TL_LineToExtPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineFromExtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an extended position, find the line it falls on.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		cx.bx	= 32 bit X event position
		dx.ax	= 32 bit Y event position
RETURN:		bx.di	= Line
		carry set if the position is below the last line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineFromExtPosition	proc	far
	class	VisTextClass
	uses	ax, cx, dx, bp
regTopLeft	local	PointDWord
region		local	word
ourPoint	local	PointDWFixed
	.enter
	;
	; Save the position so we can pass it to TR_RegionFromPoint
	;
	movdw	ourPoint.PDF_x.DWF_int, cxbx	; Save X position
	movdw	ourPoint.PDF_y.DWF_int, dxax	; Save Y position

	;
	; Get the region.
	;
	push	bp, dx, ax			; Save frame ptr, Y position
	lea	bp, ourPoint			; ss:bp <- PointDWFixed
	call	TR_RegionFromPoint		; cx <- region line is in
						; dx <- relative Y
						; ax <- relative X
	pop	bp, dx, ax			; Restore frame ptr, Y position

	cmp	cx, CA_NULL_ELEMENT		; Check for found a region
	jne	gotRegion			; Branch if we did
	call	Text_DerefVis_DI		; ds:di <- instance
	mov	cx, ds:[di].VTI_cursorRegion	; Use cursor region if none else
gotRegion:

	mov	region, cx			; Save region

	;
	; Get the top-left of the region.
	;
	push	bp				; Save frame ptr
	lea	bp, regTopLeft			; ss:bp <- PointDWord
	call	TR_RegionGetTopLeft		; Fill in regTopLeft
	pop	bp				; Restore frame ptr
	
	;
	; Restore the X.high
	;
	mov	cx, ourPoint.PDF_x.DWF_int.high
	
	;
	; Adjust the positions. If they go negative, set them to zero.
	;
	subdw	cxbx, regTopLeft.PD_x		; cx.bx <- X offset
	tst	cx				; Check for <0
	jns	gotXValue
	clr	bx				; Force to zero
gotXValue:
	
	tst	cx				; Check for >64K
	jz	xInRange
	mov	bx, -1				; Force to large value
xInRange:

	;
	; Do the Y position next.
	;
	subdw	dxax, regTopLeft.PD_y		; dx.ax <- Y offset
	tst	dx				; Check for <0
	jns	gotYValue
	clr	ax				; Force to zero
gotYValue:
	
	tst	dx				; Check for >64K
	jz	yInRange
	mov	ax, -1				; Force to large value
yInRange:

	;
	; bx	= X position
	; ax	= Y position
	; ss:bp	= Frame ptr
	;
	; Get position of line in the region
	;
	mov	cx, region			; cx <- region
	mov	dx, ax				; dx <- y position
	mov	ax, bx				; ax <- x position
	call	TL_LineFromPosition		; bx.di <- line
	.leave
	ret
TL_LineFromExtPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bottom of a line as an offset from the top of the
		region.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.bl	= Bottom of the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetBottom	proc	far	uses	ax, cx
	.enter

	push	bx
	call	TL_LineGetTop		; dx.bl <- top of line
	movwbf	axcl, dxbl		; Save top of line
	pop	bx
	call	TL_LineGetHeight	; dx.bl <- line height
	
	addwbf	dxbl, axcl		; Add it up...

	.leave
	ret
TL_LineGetBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetLeftEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the left edge of a line as an offset from the left edge
		of the region.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		ax	= Left edge of line as offset from left of region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetLeftEdge	proc	far
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line
	mov	di, TLV_LINE_GET_LEFT_EDGE
	call	CallLineHandler
	.leave
	ret
TL_LineGetLeftEdge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallLineHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the handler appropriate for the type of object.

CALLED BY:	TL_*
PASS:		*ds:si	= Instance ptr
		di	= TextLineVariant
		Other registers set for the handler
RETURN:		Registers set by the handler
		Flags set by the handler
DESTROYED:	di if not returned by handler

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallLineHandler	proc	near
	class	VisTextClass
	;
	; Choose the routine to call based on the 
	;
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset		; ds:si <- instance ptr
	
	;
	; Choose a table to use for calling the appropriate handler
	;
	; ds:si = Instance ptr.
	;
	test	ds:[si].VTI_storageFlags, mask VTSF_LARGE
	pop	si
	jz	smallObject			; Branch if small format
	
	add	di, offset cs:LargeLineHandlers
	jmp	di

smallObject:
	add	di, offset cs:SmallLineHandlers
	jmp	di

;-----------------------------------------------------------------------------

SmallLineHandlers:
    DefTextCall	SmallLineInsert			; LINE_INSERT
    DefTextCall	SmallLineDelete			; LINE_DELETE
    DefTextCall	SmallLineAdjustForReplacement	; LINE_ADJUST_FOR_REPLACEMENT
    DefTextCall	SmallLineCalculate		; LINE_CALCULATE
    DefTextCall	SmallLineGetLeftEdge		; LINE_GET_LEFT_EDGE

;   TextCallPlaceHolder	SmallStorageCreate	; STORAGE_CREATE
;   TextCallPlaceHolder	SmallStorageDestroy	; STORAGE_DESTROY
;   TextCallPlaceHolder	SmallLineGetCount	; LINE_GET_COUNT
;   TextCallPlaceHolder	SmallLineTextPosition	; LINE_TEXT_POSITION
;   TextCallPlaceHolder	SmallLineToPosition	; LINE_TO_POSITION
;   TextCallPlaceHolder	SmallLineFromPosition	; LINE_FROM_POSITION
;   TextCallPlaceHolder	SmallLineInvertRange	; LINE_INVERT_RANGE
;   TextCallPlaceHolder	SmallLineToOffsetStart	; LINE_TO_OFFSET_START
;   TextCallPlaceHolder	SmallLineTestFlags	; LINE_TEST_FLAGS
;   TextCallPlaceHolder	SmallLineGetBLO		; LINE_GET_BLO
;   TextCallPlaceHolder	SmallLineAlterFlags	; LINE_ALTER_FLAGS
;   TextCallPlaceHolder	SmallLineClearBehind	; LINE_CLEAR_BEHIND
;   TextCallPlaceHolder	SmallLineDraw		; LINE_DRAW
;   TextCallPlaceHolder	SmallLineDrawLastNChars	; LINE_DRAW_LAST_N_CHARS
;   TextCallPlaceHolder	SmallLineClearFromEnd	; LINE_CLEAR_FROM_END
;   TextCallPlaceHolder	SmallLineGetFlags	; LINE_GET_FLAGS
;   TextCallPlaceHolder	SmallLineGetHeight	; LINE_GET_HEIGHT
;   TextCallPlaceHolder	SmallLineGetTop		; LINE_GET_TOP

;-----------------------------------------------------------------------------

LargeLineHandlers:
    DefTextCall	LargeLineInsert			; LINE_INSERT
    DefTextCall	LargeLineDelete			; LINE_DELETE
    DefTextCall	LargeLineAdjustForReplacement	; LINE_ADJUST_FOR_REPLACEMENT
    DefTextCall	LargeLineCalculate		; LINE_CALCULATE
    DefTextCall	LargeLineGetLeftEdge		; LINE_GET_LEFT_EDGE

;   TextCallPlaceHolder	LargeStorageCreate	; STORAGE_CREATE
;   TextCallPlaceHolder	LargeStorageDestroy	; STORAGE_DESTROY
;   TextCallPlaceHolder	LargeLineGetCount	; LINE_GET_COUNT
;   TextCallPlaceHolder	LargeLineTextPosition	; LINE_TEXT_POSITION
;   TextCallPlaceHolder	LargeLineToPosition	; LINE_TO_POSITION
;   TextCallPlaceHolder	LargeLineFromPosition	; LINE_FROM_POSITION
;   TextCallPlaceHolder	LargeLineInvertRange	; LINE_INVERT_RANGE
;   TextCallPlaceHolder	LargeLineToOffsetStart	; LINE_TO_OFFSET_START
;   TextCallPlaceHolder	LargeLineTestFlags	; LINE_TEST_FLAGS
;   TextCallPlaceHolder	LargeLineGetBLO		; LINE_GET_BLO
;   TextCallPlaceHolder	LargeLineAlterFlags	; LINE_ALTER_FLAGS
;   TextCallPlaceHolder	LargeLineClearBehind	; LINE_CLEAR_BEHIND
;   TextCallPlaceHolder	LargeLineDraw		; LINE_DRAW
;   TextCallPlaceHolder	LargeLineDrawLastNChars	; LINE_DRAW_LAST_N_CHARS
;   TextCallPlaceHolder	LargeLineClearFromEnd	; LINE_CLEAR_FROM_END
;   TextCallPlaceHolder	LargeLineGetFlags	; LINE_GET_FLAGS
;   TextCallPlaceHolder	LargeLineGetHeight	; LINE_GET_HEIGHT
;   TextCallPlaceHolder	LargeLineGetTop		; LINE_GET_TOP
CallLineHandler	endp

TextLineCalc	ends

;****************************************************************************
;			    Misc routines
;****************************************************************************

TextInstance	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineStorageCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create line and field storage for a text object.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineStorageCreate	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter
	call	TextInstance_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallStorageCreate

quit:	
	call	TextInstance_DerefVis_DI	; ds:di <- instance
	or	ds:[di].VTI_intFlags, mask VTIF_HAS_LINES
	
	;
	; When we create storage we are creating a single line. This means
	; that we need to set the line-count of the first region to one.
	;
	clr	cx				; First region
	clrdw	bxdi				; Insert at first line
	movdw	dxax, 1				; Insert one line
	call	TR_RegionAdjustNumberOfLines
	.leave
	ret

largeObject:
	call	LargeStorageCreate
	jmp	quit

TL_LineStorageCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineStorageDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy line and field storage.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineStorageDestroy	proc	near
	class	VisTextClass
	uses	ax, di
	.enter
	call	TextInstance_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallStorageDestroy

quit:
	call	TextInstance_DerefVis_DI	; ds:di <- instance
	and	ds:[di].VTI_intFlags, not mask VTIF_HAS_LINES
	mov	ds:[di].VTI_lines, 0
	.leave
	ret

largeObject:
	call	LargeStorageDestroy
	jmp	quit
TL_LineStorageDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineFindMaxWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the maximum width of all the lines.

CALLED BY:	VisTextGetMinimumDimensions
PASS:		*ds:si	= Instance
RETURN:		dx.al	= Width of widest line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineFindMaxWidth	proc	far
	class	VisTextClass
	uses	bx, cx, di
	.enter
	call	TextInstance_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallFindMaxWidth

quit:
	;
	; It is possible for the largest line-width to be wider than the
	; object itself. This is because the line-width takes into account
	; the width of any <cr> at the end of a line. For this reason we make
	; one last check to make sure that the width we return is never wider
	; than the object.
	;
	push	dx, ax				; Save max width
	clr	cx				; cx <- region number
	clr	dx				; dx <- Y position in region

	call	TR_RegionLeftRight		; ax <- left, bx <- right
	sub	bx, ax				; bx <- region width
	pop	dx, ax				; Restore max width

	clr	ah				; bx.ah <- width
	cmpwbf	dxal, bxah
	jbe	gotWidth
	movwbf	dxal, bxah			; Return object width
gotWidth:

	.leave
	ret

largeObject:
	call	LargeFindMaxWidth
	jmp	quit
TL_LineFindMaxWidth	endp


TextInstance	ends

;****************************************************************************
;			    Drawing routines
;****************************************************************************
TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineClearBehind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the area behind a line of text.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		al	= TextClearBehindFlags
		ss:bp	= LICL_vars structure with these set:
				LICL_theParaAttr
				LICL_paraAttrStart
				LICL_paraAttrEnd
			    if paraAttr invalid
				LICL_paraAttrStart = -1

			   Also:
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		Paragraph attributes set for this line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineClearBehind	proc	far
	call	CommonLineClearBehind	; Handles both cases
	ret
TL_LineClearBehind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line of text.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		ax	= TextClearBehindFlags
		ss:bp	= LICL_vars w/ these set:
				LICL_lineStart
				LICL_paraAttrStart/End
				LICL_theParaAttr (if start != -1)

			   Also:
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	   If the TCBF_PRINT bit is *clear* (not printing) then line is
	   marked as no longer needing to be drawn

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineDraw	proc	far
	class	VisTextClass
	uses	cx, di
	.enter

	call	TextClearBehindLine

	mov	cx, di			; bx.cx <- line

	call	TextDraw_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineDraw
quit:
	.leave
	ret

largeObject:
	call	LargeLineDraw
	jmp	quit
TL_LineDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineDrawLastNChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the last <cx> characters of a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ss:bx	= LICL_vars w/ LICL_firstLine* set
		cx	= Number of characters to draw
		ax	= TextClearBehindFlags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	   If the TCBF_PRINT bit is *clear* (not printing) then line is
	   marked as no longer needing to be drawn

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineDrawLastNChars	proc	far
	class	VisTextClass
	uses	di, bp
	.enter
	mov	bp, bx				; ss:bp <- LICL_vars too

	call	TextDraw_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineDrawLastNChars
quit:
	.leave
	ret

largeObject:
	call	LargeLineDrawLastNChars
	jmp	quit
TL_LineDrawLastNChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineClearFromEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear from the end of a line to the right edge of the region.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ss:bx	= LICL_vars w/ these set:
				LICL_firstLine*
				LICL_region
				LICL_lineBottom
				LICL_lineHeight
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineClearFromEnd	proc	far
	uses	ax, bx, cx, dx, bp
	.enter

	mov	bp, bx				; ss:bp = LICL_vars
	;
	; Clear the area. This also sets the paragraph attributes
	;
	call	CommonLineClearFromEnd		; Clear the area
	
	;
	; Draw tab-lines and border
	;
	mov	bx, ss:[bx].LICL_firstLineEnd	; bx <- position to draw after
	call	DrawTabLinesAfterPos		; Draw tab lines

	test	LICL_paraAttr.VTPA_borderFlags, mask VTPBF_LEFT or \
						mask VTPBF_TOP or \
						mask VTPBF_RIGHT or \
						mask VTPBF_BOTTOM
	jz	noBorder

	;
	; We need to draw the border, but unfortunately we are bound to
	; screw up if it's a shadowed border and we try to draw with the
	; lines left edge set to the area to clear from. We need to get
	; the true left edge so we can draw the border correctly.
	;
	mov	cx, LICL_paraAttr.VTPA_leftMargin
	cmp	cx, LICL_paraAttr.VTPA_paraMargin
	jbe	gotMinOfParaAndLeft
	mov	cx, LICL_paraAttr.VTPA_paraMargin
gotMinOfParaAndLeft:
	mov	LICL_rect.R_left, cx		; Save left edge of line

	mov	cx, mask VTPBF_LEFT		; Don't draw the left side
	call	DrawBorderIfAny			; Draw the border
noBorder:
	.leave
	ret
TL_LineClearFromEnd	endp

TextDrawCode	ends

;****************************************************************************
;			    Fixed Routines
;****************************************************************************

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of lines in a text object.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
RETURN:		dx.ax	= Number of lines
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetCount	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineGetCount
quit:
	.leave
	ret

largeObject:
	call	LargeLineGetCount
	jmp	quit
TL_LineGetCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Current line
RETURN:		carry set if there is no next line (ie: bx.di is the last line)
		    bx.di = Next line if one exists
DESTROYED:	nothing
		if there is no next line even bx and di are preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineNext	proc	far
	uses	ax, dx
	.enter
	call	TL_LineGetCount		; dx.ax <- number of lines
	decdw	dxax			; dx.ax <- number of last line
	cmpdw	bxdi, dxax
EC <	ERROR_A	LINE_NUMBER_BEYOND_LAST_LINE			>
	je	lastLine
	
	incdw	bxdi			; bx.di <- next line
					; Clears carry
quit:
	.leave
	ret

lastLine:
	stc				; Signal: last line
	jmp	quit
TL_LineNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LinePrevious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the previous line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Current line
RETURN:		carry set if there is no previous line
		    bx.di = Previous line
DESTROYED:	nothing
		if there is no previous line even bx and di are preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LinePrevious	proc	far
	tstdw	bxdi			; Check for on first line
	jz	firstLine
	decdw	bxdi			; Move to previous line
					; Clears the carry
quit:
	ret

firstLine:
	stc				; Signal: no previous line
	jmp	quit
TL_LinePrevious	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineToOffsetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a line, get the offset of the start of the line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.ax	= Offset to the start of the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineToOffsetStart	proc	far
	class	VisTextClass
	uses	bx, cx, di, bp
firstLine	local	dword		push	bx, di
lineStart	local	dword
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	clrdw	lineStart
	call	SmallLineToOffsetStart
quit:
	.leave
	ret

largeObject:
	;
	; Find the region containing this line and get the start line
	; and offset
	;
	pushdw	bxcx			; Save line to find

	mov	di, cx			; bx.di <- line
	call	TR_RegionFromLineGetStartLineAndOffset
					; bx.di <- region start line
					; dx.ax <- region start offset
	movdw	firstLine, bxdi		; Save first line
	movdw	lineStart, dxax		; Save start offset
	
	popdw	bxcx			; Restore line to find
	call	LargeLineToOffsetStart	; dx.ax <- start
	jmp	quit
TL_LineToOffsetStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineToOffsetStartFromRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a line and a region, get the offset of the start of 
		the line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		cx	= Region
RETURN:		dx.ax	= Offset to the start of the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineToOffsetStartFromRegion	proc	far
	class	VisTextClass
	uses	bx, cx, di, bp
firstLine	local	dword		push	bx, di
lineStart	local	dword
	.enter
	push	di
	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	pop	di
	jnz	largeObject

	call	TL_LineToOffsetStart
quit:
	.leave
	ret

largeObject:
	;
	; Find the region containing this line and get the start line
	; and offset
	;
	pushdw	bxdi			; Save line to find

	call	TR_RegionGetStartOffset	; dx.ax <- start offset
	call	TR_RegionGetTopLine	; bx.di <- start line

	movdw	firstLine, bxdi		; Save first line
	movdw	lineStart, dxax		; Save start offset
	
	popdw	bxcx			; Restore line to find
	call	LargeLineToOffsetStart	; dx.ax <- start
	jmp	quit
TL_LineToOffsetStartFromRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineToOffsetEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a line, get the offset to the end of the line. 
		If the line ends in a <cr> or a <page-break>, return 
		the position before that character.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.ax	= Offset to the end of the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineToOffsetEnd	proc	far
	uses	cx
	.enter
	call	TL_LineToOffsetVeryEnd	; dx.ax <- Very end of line
					; cx <- LineFlags
	
	test	cx, mask LF_ENDS_IN_CR or \
		    mask LF_ENDS_IN_COLUMN_BREAK or \
		    mask LF_ENDS_IN_SECTION_BREAK
	jz	gotOffset
	decdw	dxax			; Don't count last char
gotOffset:
	.leave
	ret
TL_LineToOffsetEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineToOffsetVeryEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a line, get the offset past the last character on 
		the line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.ax	= Offset to the end of the line
		cx	= LineFlags for the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineToOffsetVeryEnd	proc	far
	class	VisTextClass
	uses	bx, di, bp
firstLine	local	dword		push	bx, di
lineStart	local	dword
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	clrdw	lineStart
	call	SmallLineToOffsetVeryEnd
quit:
	.leave
	ret

largeObject:
	;
	; Find the region containing this line and get the start line
	; and offset
	;
	pushdw	bxcx			; Save line to find
	mov	di, cx			; bx.di <- line

	call	TR_RegionFromLineGetStartLineAndOffset
					; bx.di <- first line
					; dx.ax <- start offset

	movdw	firstLine, bxdi		; Save first line
	movdw	lineStart, dxax		; Save start offset

	popdw	bxcx			; Restore line to find
	call	LargeLineToOffsetVeryEnd
	jmp	quit
TL_LineToOffsetVeryEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top edge of a line as an offset from the top of the
		region.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.bl	= Top of line (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetTop	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineGetTop
quit:
	.leave
	ret

largeObject:
	call	LargeLineGetTop
	jmp	quit
TL_LineGetTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetBLO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the baseline-offset of a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.bl	= Baseline offset (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetBLO	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineGetBLO
quit:
	.leave
	ret

largeObject:
	call	LargeLineGetBLO
	jmp	quit
TL_LineGetBLO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineTextPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a text offset into a line and a pixel offset, compute 
		the nearest possible valid position where the event at the 
		pixel position could occur, not to exceed the passed offset.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		dx.ax	= Offset to calculate up to
		bp	= Pixel offset from left edge of the line
RETURN:		dx.ax	= Nearest character offset
		bx	= Pixel offset of this character offset
		carry set if position is not right over the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineTextPosition	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineTextPosition
quit:
	pop	di
	call	ThreadReturnStackSpace
	.leave
	ret

largeObject:
	call	LargeLineTextPosition
	jmp	quit
TL_LineTextPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of the left edge of a line relative to the
		top-left corner of the region holding that line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		cx	= 16 bit left edge of line
		dx	= 16 bit top edge of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineToPosition	proc	far
	class	VisTextClass
	uses	bx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineToPosition
quit:
	.leave
	ret

largeObject:
	call	LargeLineToPosition
	jmp	quit
TL_LineToPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineFromPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a position and a region, find the line it falls on.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ax	= 16 bit X event position
		dx	= 16 bit Y event position
		cx	= Region
RETURN:		bx.di	= Line
		carry set if the position is below the last line in region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineFromPosition	proc	far
	uses	ax, cx, dx
	.enter
	call	LineFromPositionCommon
	.leave
	ret
TL_LineFromPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineFromPositionGetBLOAndHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a position, return the height and baseline of the
		line on which the position falls.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		ax	= X position
		dx	= Y position
		cx	= Region in which position falls
RETURN:		bx.al	= Baseline
		dx.ah	= Line height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineFromPositionGetBLOAndHeight	proc	far
	uses	cx
	.enter
	call	LineFromPositionCommon
	mov	bx, cx			; bx.al <- baseline
	.leave
	ret
TL_LineFromPositionGetBLOAndHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineFromPositionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a position, return all sorts of information about
		the line.

CALLED BY:	TL_LineFromPosition and TL_LineFromPositionGetBLOAndHeight
PASS:		*ds:si	= Instance
		ax	= 16 bit X event position
		dx	= 16 bit Y event position
		cx	= Region
RETURN:		bx.di	= Line
		carry set if the position is below the last line in region
		dx.ah	= Line height
		cx.al	= Baseline
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineFromPositionCommon	proc	near
	class	VisTextClass
	.enter
	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineFromPositionGetInfo
quit:
	.leave
	ret

largeObject:
	call	LargeLineFromPositionGetInfo
	jmp	quit
LineFromPositionCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineTestFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for flags being set in the LineFlags associated 
		with a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		ax	= LineFlags to test
RETURN:		Zero flag clear (nz) if any bits in ax are set in the LineFlags.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineTestFlags	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineTestFlags
quit:
	.leave
	ret

largeObject:
	call	LargeLineTestFlags
	jmp	quit
TL_LineTestFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineAlterFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the LineFlags associated with a given line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
		ax	= Bits to set
		dx	= Bits to clear
		if ax = dx then the bits are toggled.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineAlterFlags	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineAlterFlags
quit:
	.leave
	ret

largeObject:
	call	LargeLineAlterFlags
	jmp	quit
TL_LineAlterFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the LineFlags for a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		ax	= LineFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetFlags	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineGetFlags
quit:
	.leave
	ret

largeObject:
	call	LargeLineGetFlags
	jmp	quit
TL_LineGetFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an offset, get the line which contains that offset. 
		For word-wrapped lines, a character offset can exist on two
		lines. The caller can choose whether it wants the first or 
		second line in situations like this.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset
		carry set if the caller wants the first line that
			contains that offset. Carry clear otherwise.
RETURN:		bx.di	= Line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineFromOffset	proc	far
	uses	ax, dx
	.enter
	call	TL_LineFromOffsetGetStart
	.leave
	ret
TL_LineFromOffset	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineFromOffsetGetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an offset, get the line and start of line.

CALLED BY:	TL_LineFromOffset, Global
PASS:		*ds:si	= Instance
		dx.ax	= Offset
		carry set if the caller wants the first line that
			contains that offset. Carry clear otherwise.
RETURN:		bx.di	= Line
		dx.ax	= Start of that line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineFromOffsetGetStart	proc	far


	class	VisTextClass
	uses	cx, bp
offsetToFind	local	dword		push	dx, ax
lineStart	local	dword
firstLine	local	dword
wantFirstFlag	local	byte
	lahf				; ax <- flags
	.enter
	;
	; Set a flag indicating that we want the first line containing the 
	; offset.
	;
	clr	wantFirstFlag		; Assume we don't want the first line
	sahf				; Restore flags
	jnc	gotFlag
	dec	wantFirstFlag		; Signal: We want the first line
gotFlag:

	;
	; Find the region containing this line and get the start line
	; and offset
	;
	mov	ax, offsetToFind.low	; dx.ax <- offset to find
	call	TR_RegionFromOffsetGetStartLineAndOffset
					; dx.ax <- start of region
					; bx.di <- start line
	movdw	lineStart, dxax
	movdw	firstLine, bxdi
	;
	; *ds:si= Instance ptr
	; Stack frame filled in
	; On stack:
	;	Flags w/ carry set if the caller wants the first line
	;
	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineFromOffsetGetStart
quit:
	.leave

	ret

largeObject:
	call	LargeLineFromOffsetGetStart
	jmp	quit
TL_LineFromOffsetGetStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineInvertRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a range of text on a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars with:
			    LICL_region set
			    LICL_line  = line to invert on
			    LICL_range holds the range to invert
			       VTR_start = 0 for line start
			       VTR_end   = TEXT_ADDRESS_PAST_END for line end
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineInvertRange	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineInvertRange
quit:
	.leave
	ret

largeObject:
	call	LargeLineInvertRange
	jmp	quit
TL_LineInvertRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		dx.bl	= Line height (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetHeight	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineGetHeight
quit:
	.leave
	ret

largeObject:
	call	LargeLineGetHeight
	jmp	quit
TL_LineGetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineGetCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of characters in a line.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		bx.di	= Line
RETURN:		dx.ax	= Number of chars in line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineGetCharCount	proc	far
	class	VisTextClass
	uses	cx, di
	.enter
	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineGetCharCount
quit:
	.leave
	ret

largeObject:
	call	LargeLineGetCharCount
	jmp	quit
TL_LineGetCharCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineAddCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the line count from an offset.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		bx.di	= Line
		dx.ax	= Offset
RETURN:		dx.ax	= Offset + lineCount
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineAddCharCount	proc	far
	uses	cx, bp
	.enter
	movdw	cxbp, dxax		; cx.bp <- offset
	call	TL_LineGetCharCount	; dx.ax <- # of chars in line
	adddw	dxax, cxbp		; dx.ax <- new offset
	.leave
	ret
TL_LineAddCharCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineSubtractCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subtract the line count from an offset.

CALLED BY:	Global
PASS:		*ds:si	= Instance
		bx.di	= Line
		dx.ax	= Offset
RETURN:		dx.ax	= Offset - lineCount
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineSubtractCharCount	proc	far
	uses	cx, bp
	.enter
	movdw	cxbp, dxax		; cx.bp <- offset
	call	TL_LineGetCharCount	; dx.ax <- # of chars in line
	subdw	cxbp, dxax		; cx.bp <- new offset
	
	movdw	dxax, cxbp		; Return value in dx.ax
	.leave
	ret
TL_LineSubtractCharCount	endp


if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateSingleLineStructure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate a single line structure

CALLED BY:	External
PASS:		*ds:si	= Instance
		bx.di	= Line
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateSingleLineStructure	proc	far
	class	VisTextClass
	uses	ax, cx, dx, di, bp
	pushf
info	local	ECLineValidationInfo
	.enter
	call	TL_LineToOffsetStart	; dx.ax <- line start
	
	;
	; Initialize the stack frame
	;
	mov	cx, ds:LMBH_handle
	movdw	info.ECLVI_object, cxsi	; Save the OD of the text object
	movdw	info.ECLVI_line, bxdi	; Save the line, and size
	movdw	info.ECLVI_lineStart, dxax

	mov	cx, di			; bx.cx <- line

	call	TextFixed_DerefVis_DI
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	ECSmallLineValidateStructures
quit:
	.leave
	popf
	ret

largeObject:
	call	ECLargeLineValidateStructures
	jmp	quit
ECValidateSingleLineStructure	endp

endif

TextFixed	ends

;-------------------

TextRegion	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TL_LineSumAndMarkRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sum the heights of a range of lines and mark them as needing
		to be calculated or drawn.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.di	= Start of range
		dx.ax	= End of range
		cx	= Flags to set
RETURN:		cx.dx.ax= Sum of heights
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TL_LineSumAndMarkRange	proc	far
	class	VisTextClass
	uses	di, bp
	.enter
	mov	bp, cx			; bp <- flags to set
	mov	cx, di			; bx.cx <- line

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject

	call	SmallLineSumAndMarkRange
quit:
	.leave
	ret

largeObject:
	call	LargeLineSumAndMarkRange
	jmp	quit
TL_LineSumAndMarkRange	endp

TextRegion	ends

TextObscure	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetLineInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get line information

CALLED BY:	MSG_VIS_TEXT_GET_LINE_INFO
PASS:		dx:bp	= VisTextGetLineInfoParameters
RETURN:		Buffer filled with line info
		cx	= Number of byte actually copied
		carry set if there is no such line
DESTROYED:	bx, di, si, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/31/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetLineInfo	proc	far
	class	VisTextClass
	uses	ax, dx, di, bp
	.enter
	mov	es, dx			; es:bp <- ptr to structure
	call	TL_LineGetCount		; dx.ax <- # of lines
	cmpdw	dxax, es:[bp].VTGLIP_line
	jbe	noSuchLine		; Branch if no such line

	;
	; Line does exist
	;
	movdw	bxcx, es:[bp].VTGLIP_line	; bx.cx <- line
	mov	dx, es:[bp].VTGLIP_bsize	; dx <- size of buffer

	mov	ax, es:[bp].VTGLIP_buffer.segment
	mov	bp, es:[bp].VTGLIP_buffer.offset

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;
	; *ds:si= VisTextInstance
	; ds:di	= VisTextInstance
	;
	; bx.cx	= Line to read
	; ax:bp	= Pointer to the buffer to fill in
	; dx	= Size of buffer to write to
	;
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	largeObject
;----------------------------------------------------------------------------
;			     Small object
;----------------------------------------------------------------------------
	push	ax			; Save buffer segment
	mov	di, cx			; bx.di <- line
	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	;
	; Get the size to actually copy
	;
	cmp	cx, dx
	jbe	gotSize
	mov	cx, dx
gotSize:
	;
	; cx	= Number of bytes to copy
	; es:di	= Place to copy from
	;
	segmov	ds, es, si		; ds:si <- source for move
	mov	si, di
	pop	es			; es:di <- destination
	mov	di, bp

	;
	; Copy the data (if there is some)
	;
	jcxz	skipCopy		; Branch if not copying

	push	cx			; Save count
	rep	movsb			; Copy the data
	pop	cx			; Restore the count

skipCopy:
	clc				; Signal: line does exist

quit:
	;
	; Buffer is filled with data
	; cx	= Number of bytes actually copied
	; carry set if no such line
	;
	.leave
	ret

noSuchLine:
	stc				; Signal: no such line
	jmp	quit

largeObject:
;----------------------------------------------------------------------------
;			     Small object
;----------------------------------------------------------------------------
	;
	; *ds:si= VisTextInstance
	; bx.cx	= Line to read
	; ax:bp	= Pointer to the buffer to fill in
	; dx	= Size of buffer to write to
	;
	mov	di, cx			; bx.di <- line
	call	LargeGetLinePointer	; es:di <- ptr to element
					; cx <- size of line/field data
	push	es			; Save block segment
	;
	; Get the size to actually copy
	;
	cmp	cx, dx
	jbe	gotSize2
	mov	cx, dx
gotSize2:
	;
	; cx	= Number of bytes to copy
	; es:di	= Place to copy from
	; ax:bp	= Buffer to write to
	;
	segmov	ds, es, si		; ds:si <- source for move
	mov	si, di
	movdw	esdi, axbp		; es:di <- destination

	;
	; Copy the data (if there is some)
	;
	jcxz	skipCopy2		; Branch if not copying

	push	cx			; Save count
	rep	movsb			; Copy the data
	pop	cx			; Restore the count

skipCopy2:
	pop	es			; Restore block segment
	call	LargeReleaseLineBlock	; Release the block
	clc				; Signal: line does exist
	jmp	quit
VisTextGetLineInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetLineFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the line number, given an offset

CALLED BY:	MSG_VIS_TEXT_GET_LINE_FROM_OFFSET

PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		cx:dx	= offset 

RETURN:		dx:ax	= line #
		cx:bp	= position of start of line

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	; This is actually a method

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetLineFromOffset	proc	far

	.enter

	mov_tr	ax, dx
	mov	dx, cx
	clc
	call	TL_LineFromOffsetGetStart
	movdw	cxbp, dxax			; start of line
	movdw	dxax, bxdi			; line #


	.leave
	ret
VisTextGetLineFromOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetLineOffsetAndFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a lines starting offset and the flags for it.

CALLED BY:	via MSG_VIS_TEXT_GET_LINE_OFFSET_AND_FLAGS
PASS:		*ds:si	= Instance
		dx:bp	= VisTextGetLineOffsetAndFlagsParameters
RETURN:		Buffer filled in
		carry set if the line does not exist
		cx, dx, bp preserved
DESTROYED:	everything else

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetLineOffsetAndFlags	proc	far
	uses	cx, dx, bp
	.enter
	pushdw	dxbp				; Save buffer ptr
	movdw	esdi, dxbp

	movdw	bxdi, es:[di].VTGLOAFP_line	; bx.di <- line
	call	TL_LineToOffsetStart		; dx.ax <- offset to line start
	mov	cx, ax				; dx.cx <- offset to line start

	call	TL_LineGetFlags			; ax <- LineFlags

	popdw	dssi				; ds:si <- buffer pointer
	movdw	ds:[si].VTGLOAFP_offset, dxcx	; Save the offset
	mov	ds:[si].VTGLOAFP_flags, ax	; Save the flags
	.leave
	ret
VisTextGetLineOffsetAndFlags	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TL_LineGetParaCount

DESCRIPTION:	Get the paragraph count

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	dxax - paragraph count

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
TL_LineGetParaCount	proc	far	uses bx, cx, si, di, bp
	class	VisTextClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	large

	call	SmallGetLineArray		;*ds:ax = line array
	mov_tr	si, ax				;*ds:si = line array
	mov	bx, cs
	mov	di, offset CommonLineGetParaCountCallback
	clrdw	dxcx
	call	ChunkArrayEnum
	jmp	done

large:
	call	T_GetVMFile
	push	bx
	call	LargeGetLineArray		;di = line array
	push	di
	push	cs				;push callback
	mov	di, offset CommonLineGetParaCountCallback
	push	di
	clr	ax
	push	ax, ax				;start element
	dec	ax
	push	ax, ax				;# elements
	clrdw	dxcx
	call	HugeArrayEnum

done:
	mov_tr	ax, cx				;dxax = result.

	.leave
	ret

TL_LineGetParaCount	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CommonLineGetParaCountCallback

DESCRIPTION:	Get the paragraph count (callback)

CALLED BY:	INTERNAL

PASS:
	ds:di - LineInfo
	dxcx - current paragraph count

RETURN:
	dxcx - updated
	carry clear

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
CommonLineGetParaCountCallback	proc	far
	test	ds:[di].LI_flags, mask LF_STARTS_PARAGRAPH
	jz	done
	incdw	dxcx
done:
	clc
	ret

CommonLineGetParaCountCallback	endp

TextObscure	ends
