COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallLineInfo.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Misc information about lines.

	$Id: tlSmallLineInfo.asm,v 1.1 97/04/07 11:20:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of a line.

CALLED BY:	TL_LineGetHeight via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.bl	= Line height (WBFixed)
DESTROYED:	nothing (not even bh)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineGetHeight	proc	near
	uses	ax, cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference				>

	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	CommonLineGetHeight		; dx.bl <- line height
	.leave
	ret
SmallLineGetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetBLO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the baseline offset a line.

CALLED BY:	TL_LineGetHeight via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.bl	= Baseline offset (WBFixed)
DESTROYED:	nothing (not even bh)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineGetBLO	proc	near
	uses	ax, cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference				>

	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	CommonLineGetBLO		; dx.bl <- baseline
	.leave
	ret
SmallLineGetBLO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top of a line as an offset from the top of the region.

CALLED BY:	TL_LineGetTop via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.bl	= Line top (WBFixed)
DESTROYED:	nothing (not even bh)

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineGetTop	proc	far
	uses	ax, cx, di
	.enter
	call	SmallLineGetTopLeftAndStart
					; ax <- left edge
					; dx.bl <- top edge
					; di.cx <- start of line
	.leave
	ret
SmallLineGetTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetTopLeftAndStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top, left, and start of a line.

CALLED BY:	SmallLineGetTop, SmallLineToPosition, SmallLineDraw,
		SmallLineDrawLastNChars
PASS:		*ds:si	= Instance
		bx.cx	= Line
RETURN:		dx.bl	= Top edge
		ax	= Left edge
		di.cx	= Start offset of line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineGetTopLeftAndStart	proc	far
	uses	bp, si
stopLine	local	dword
topEdge		local	WBFixed
leftEdge	local	word
startOffset	local	dword
	.enter
	;
	; Initialize the stack frame
	;
	incdw	bxcx				; Make this one-based
	movdw	stopLine, bxcx			; Save it
	clrdw	startOffset			; First line offset == 0
	clrwbf	topEdge				; First line top == 0

	;
	; Set up arguments for ChunkArrayEnum
	;
	call	SmallGetLineArray		; *ds:ax <- line array
	mov	si, ax				; *ds:si <- line array
	
	mov	bx, cs				; bx.di <- callback
	mov	di, offset cs:CommonGetTopLeftAndStartCallback
	
	call	ChunkArrayEnum			; Do the enumeration

	;
	; Set up the return values
	;
	mov	ax, leftEdge
	movwbf	dxbl, topEdge
	movdw	dicx, startOffset
	.leave
	ret
SmallLineGetTopLeftAndStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonGetTopLeftAndStartCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top of a line

CALLED BY:	HugeArrayEnum & ChunkArrayEnumRange
PASS:		ds:di	= Current line
		ss:bp	= Inheritable stack frame
RETURN:		carry clear to indicate "continue"
		carry set otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonGetTopLeftAndStartCallback	proc	far
	uses	ax, bx, dx, es
	.enter	inherit	SmallLineGetTopLeftAndStart

	segmov	es, ds				; es:di <- line ptr

	decdw	stopLine			; One less line to process

	tstdw	stopLine			; Check for no more lines
	jz	lastLine			; Branch if on last line

	;
	; Add in the height of the current line
	;
	CommonLineGetHeight			; dx.bl <- line height
	addwbf	topEdge, dxbl			; Update top edge
	
	CommonLineGetCharCount			; dx.ax <- number of characters
	adddw	startOffset, dxax		; Update line start

	clc					; Signal: continue

quit:
	.leave
	ret

lastLine:
	CommonLineGetAdjustment			; ax <- left edge
	mov	leftEdge, ax			; Save it for returning

	stc					; Signal: stop
	jmp	quit
CommonGetTopLeftAndStartCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetLeftEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the left edge of a line as an offset from the left edge
		of the region containing the line.

CALLED BY:	TL_LineGetLeftEdge via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		ax	= Left edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineGetLeftEdge	proc	far
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference				>

	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	CommonLineGetAdjustment		; ax <- adjustment
	.leave
	ret
SmallLineGetLeftEdge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of lines in a small text object.

CALLED BY:	TL_LineGetCount
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
SmallLineGetCount	proc	far
	class	VisTextClass
	uses	cx, di, si
	.enter
	call	TextFixed_DerefVis_DI	; ds:di <- instance ptr
	mov	si, ds:[di].VTI_lines	; *ds:si <- chunk-array
	clr	ax
	tst	si
	jz	noLines
	call	ChunkArrayGetCount	; cx <- number of elements
	mov	ax, cx			; dx.ax <- number of elements
noLines:	
	clr	dx
	.leave
	ret
SmallLineGetCount	endp

if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSmallLineValidateStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate structures for a small line.

CALLED BY:	ECValidateSingleLineStructure
PASS:		*ds:si	= Instance
		bx.cx	= Line
		dx.ax	= Line start
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSmallLineValidateStructures	proc	far
	uses	cx, di, es
	pushf
info	local	ECLineValidationInfo
	.enter	inherit
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference				>

	push	ax			; Save lineStart.low
	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	pop	ax			; Save lineStart.low

	;
	; Update the stack frame
	;
	movdw	info.ECLVI_linePtr, esdi
	mov	info.ECLVI_lineSize, cx

	call	ECCommonLineValidateStructures
	.leave
	popf
	ret
ECSmallLineValidateStructures	endp

endif

TextFixed	ends

TextRegion segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineSumAndMarkRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sum the heights of a range of lines and mark them as needing
		to be calculated or drawn.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		bx.cx	= Start of range
		dx.ax	= End of range
		bp	= Flags to set
RETURN:		cx.dx.ax= Sum of heights
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineSumAndMarkRange	proc	far
	uses	bx, di, si
flags	local	word		push	bp
hgtSum	local	DWFixed
	.enter
ForceRef	flags
	;
	; Set up arguments.
	;
	push	ax
	call	SmallGetLineArray		; *ds:ax <- line-array
	mov	si, ax				; *ds:si <- line array
	pop	ax

	mov	bx, cs				; bx:di <- callback
	mov	di, offset cs:CommonSumAndMarkCallback
	
	sub	ax, cx				; ax <- Number of lines to do
	xchg	ax, cx				; ax <- first line to do
						; cx <- Number of lines to do

	clrdw	hgtSum.DWF_int			; Init height so far
	clr	hgtSum.DWF_frac

	call	ChunkArrayEnumRange		; Do the enumeration
	
	;
	; Return stuff
	;
	movdw	cxdx, hgtSum.DWF_int
	mov	ax, hgtSum.DWF_frac
	.leave
	ret
SmallLineSumAndMarkRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonSumAndMarkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the height of the line to an accumulator and mark the
		line as needing to be drawn and computed.

CALLED BY:	HugeArrayEnum & ChunkArrayEnumRange
PASS:		ds:di	= Current line
		ss:bp	= Inheritable stack frame
RETURN:		carry clear always (indicating "continue")
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonSumAndMarkCallback	proc	far
	uses	ax, bx, cx, dx, es
	.enter	inherit	SmallLineSumAndMarkRange
	;
	; Update the running total
	;
	segmov	es, ds, ax			; es:di <- line

	CommonLineGetHeight			; dx.bl <- line height

	mov	bh, bl				; dx.bx <- line height
	clr	bl

	add	hgtSum.DWF_frac, bx		; Update the total
	adc	hgtSum.DWF_int.low, dx
	adc	hgtSum.DWF_int.high, 0

	;
	; Update the flags
	;
	mov	ax, flags			; ax <- flags to set
	clr	cx				; cx <- flags to clear
	call	CommonLineAlterFlags		; Update the flags
	
	clc					; Signal: continue
	.leave
	ret
CommonSumAndMarkCallback	endp

TextRegion ends

TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallFindMaxWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the maximum width of all the lines.

CALLED BY:	TL_LineFindMaxWidth
PASS:		*ds:si	= Instance
RETURN:		dx.al	= Max width
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallFindMaxWidth	proc	near
	uses	bx, cx, di, si, bp
	.enter
	sub	sp, size LICL_vars		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	
	call	InitVarsForFindMaxWidth		; Set up stack frame

	;
	; Set up arguments.
	;
	call	SmallGetLineArray		; *ds:ax <- line-array
	mov	si, ax				; *ds:si <- line array

	mov	bx, cs				; bx:di <- callback
	mov	di, offset cs:CommonFindMaxWidth
	
	clrwbf	dxcl				; dx.cl <- Max width so far
	call	ChunkArrayEnum			; Do the enumeration
	mov	al, cl				; dx.al <- Max width
	
	add	sp, size LICL_vars		; Restore stack frame
	.leave
	ret
SmallFindMaxWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitVarsForFindMaxWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the LICL_vars for CommonFindMaxWidth

CALLED BY:	LargeFindMaxWidth, SmallFindMaxWidth
PASS:		*ds:si	= Instance
		ss:bp	= LICL_vars
RETURN:		set:
			LICL_object		(ds:si)
			LICL_paraAttrStart	(-1)
			LICL_lineStart		(0)
			LICL_region		(0)
			LICL_lineBottom		(0)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitVarsForFindMaxWidth	proc	near
	;
	; Initialize the stack frame appropriately
	;
	movdw	ss:[bp].LICL_object, dssi	; Save object

	movdw	LICL_paraAttrStart, -1		; ParaAttr aren't set
	clrdw	ss:[bp].LICL_lineStart		; First line starts at 0
	
	;
	; Since we are starting at the very first line, the lines position
	; must be at 0 and the region number must also be at zero.
	;
	clr	ss:[bp].LICL_region		; Current region
	clrwbf	ss:[bp].LICL_lineBottom		; Bottom of previous line
	ret
InitVarsForFindMaxWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonFindMaxWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a line width against the current maximum.

CALLED BY:	ChunkArrayEnum
PASS:		*ds:si	= Array
		ds:di	= Element
		ax	= Size of element
		dx.cl	= Max width so far
		ss:bp	= LICL_vars w/ these set:
			LICL_paraAttrStart/End 
			LICL_paraAttr
			LICL_lineStart
RETURN:		carry clear always
DESTROYED:	bx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonFindMaxWidth	proc	far
	class	VisTextClass
	uses	ax, ds, es
	.enter
	segmov	es, ds, si			; es:di <- ptr to line

	movdw	dssi, ss:[bp].LICL_object	; *ds:si <- instance

	;
	; Set up the paragraph attributes
	;
	push	ax, dx				; Save size, maxWidth.high
	movdw	dxax, ss:[bp].LICL_lineStart
	call	T_EnsureCorrectParaAttr		; Get the paragraph attributes

	;
	; Update the line start to point at the next line.
	;
	CommonLineGetCharCount			; dx.ax <- # of chars
	adddw	ss:[bp].LICL_lineStart, dxax	; Update the line start
	pop	ax, dx				; Restore size, maxWidth.high
	
;-----------------------------------------------------------------------------
	;
	; Compute line width by adding the position of the last field and
	; the width of the last field
	;
	mov	bx, offset LI_firstField	; es:di.bx <- first field
	
fieldLoop:
	;
	; es:di	= Line
	; es:di.bx = Field
	; ax	= Offset past last field
	; bp.ch	= Line width so far
	; dx.cl	= Maximum line width
	;
	cmp	bx, ax				; Check for done
	jae	endLoop
	
	add	bx, size FieldInfo		; bx <- offset to next field
	jmp	fieldLoop			; Loop to handle it
endLoop:

	sub	bx, size FieldInfo		; bx <- offset to last field
	mov	ax, es:[di][bx].FI_position
	add	ax, es:[di][bx].FI_width
	
	;
	; Add in the adjustment. This will account for any left or paragraph
	; margin associated with this line.
	;
	add	ax, es:[di].LI_adjustment	; Add in the adjustment
	clr	ch
	
;-----------------------------------------------------------------------------
	;
	; Account for the right margin
	; ss:bp	= LICL_vars
	; ax.ch	= Line width w/o right margin accounted for
	; dx.cl	= Max width (so far)
	;
	; adjustAmount = (object.right - rightMargin)
	;
	call	TextInstance_DerefVis_DI	; ds:di <- instance
	clr	bh				; bx <- object.right
	mov	bl, ds:[di].VTI_lrMargin

	add	ax, ds:[di].VI_bounds.R_right
	sub	ax, bx
	sub	ax, LICL_paraAttr.VTPA_rightMargin

;-----------------------------------------------------------------------------
	;
	; Compare width against the current maximum
	; ax.ch	= Line width
	; dx.cl	= Max width
	;
	cmpwbf	dxcl, axch
	jae	gotWidth			; Branch if new is less
	movwbf	dxcl, axch			; Else set new maximum
gotWidth:

	clc					; Signal: continue
	.leave
	ret
CommonFindMaxWidth	endp



TextInstance	ends
