COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeLineInfo.asm

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

	$Id: tlLargeLineInfo.asm,v 1.1 97/04/07 11:21:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of a line.

CALLED BY:	TL_LineGetHeight via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.bl	= Line height (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineGetHeight	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- ptr to element
					; cx <- size of line/field data
	CommonLineGetHeight		; dx.bl <- line height
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineGetHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetBLO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the baseline offset a line.

CALLED BY:	TL_LineGetHeight via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.bl	= Baseline offset (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineGetBLO	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- ptr to element
					; cx <- size of line/field data
	CommonLineGetBLO		; dx.bl <- baseline
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineGetBLO	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top of a line as an offset from the top of the region.

CALLED BY:	TL_LineGetTop via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.bl	= Line top (WBFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineGetTop	proc	far
	uses	ax, cx, di
	.enter
	call	LargeLineGetTopLeftAndStart
					; ax <- left edge
					; dx.bl <- top edge
					; di.cx <- start of line
	.leave
	ret
LargeLineGetTop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetTopLeftAndStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top, left, and start of a line.

CALLED BY:	LargeLineGetTop, LargeLineToPosition, LargeLineDraw,
		LargeLineDrawLastNChars
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
	jcw	 5/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineGetTopLeftAndStart	proc	far
	uses	bp
stopLine	local	dword		push	bx, cx
topEdge		local	WBFixed
leftEdge	local	word
startOffset	local	dword
	.enter
	;
	; Set up arguments for HugeArrayEnum
	;
	call	T_GetVMFile
	push	bx				; VM file
	call	LargeGetLineArray		; di <- line-array
	push	di				; Pass line-array

	push	cs				; Pass callback
	mov	di, offset cs:CommonGetTopLeftAndStartCallback
	push	di

	;
	; Figure the region containing the line
	;
	movdw	bxdi, stopLine			; bx.di <- line to stop at
	call	TR_RegionFromLineGetStartLineAndOffset
						; dx.ax <- region start offset
						; bx.di <- region start line
	movdw	startOffset, dxax
	pushdw	bxdi				; Line to start at

	;
	; Compute the line to stop at
	;
	movdw	dxax, stopLine			; dx.ax <- line to stop at
	subdw	dxax, bxdi			; dx.ax <- # to process
	incdw	dxax				; Make it one based
	movdw	stopLine, dxax			; Pass this along
	pushdw	dxax

	clrwbf	topEdge				; First line starts at zero

	call	HugeArrayEnum			; Do the enumeration
	
	;
	; Set up the return values
	;
	mov	ax, leftEdge
	movwbf	dxbl, topEdge
	movdw	dicx, startOffset
	.leave
	ret
LargeLineGetTopLeftAndStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetLeftEdge
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
LargeLineGetLeftEdge	proc	far
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- ptr to element
					; cx <- size of line/field data
	CommonLineGetAdjustment		; ax <- adjustment
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineGetLeftEdge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of lines in a large text object.

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
LargeLineGetCount	proc	near
	class	VisTextClass
	uses	bx, di
	.enter
	call	T_GetVMFile			;bx = file
	call	TextFixed_DerefVis_DI	; ds:di <- instance ptr
	mov	di, ds:[di].VTI_lines	; di <- huge-array
	clrdw	dxax
	tst	di
	jz	exit
	call	HugeArrayGetCount	; dx.ax <- number of elements
exit:
	.leave
	ret
LargeLineGetCount	endp


if	ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLargeLineValidateStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate structures for a large line.

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
ECLargeLineValidateStructures	proc	far
	uses	cx, di, es
	pushf
info	local	ECLineValidationInfo
	.enter	inherit
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- ptr to element
					; cx <- size of line/field data

	;
	; Update the stack frame
	;
	movdw	info.ECLVI_linePtr, esdi
	mov	info.ECLVI_lineSize, cx

	call	ECCommonLineValidateStructures
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	popf
	ret
ECLargeLineValidateStructures	endp

endif


TextFixed	ends

;-----------

TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineSumAndMarkRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sum the heights of a range of lines and mark the lines
		as needing to be calculated and drawn.

CALLED BY:	TL_LineSumAndMarkRange via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Start of range
		dx.ax	= End of range
		bp	= Flags to set
RETURN:		cx.dx.ax= Sum of the heights
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineSumAndMarkRange	proc	far
	uses	di
flags	local	word		push	bp
hgtSum	local	DWFixed
	.enter
ForceRef	flags
	;
	; Set up arguments.
	;
	mov	di, bx
	call	T_GetVMFile
	push	bx				; VM file
	mov	bx, di
	call	LargeGetLineArray		; di <- line-array
	push	di				; Pass line-array

	push	cs				; Pass callback
	mov	di, offset cs:CommonSumAndMarkCallback
	push	di

	pushdw	bxcx				; Line to start at

	subdw	dxax, bxcx			; dx.ax <- # to process
	pushdw	dxax				; Save number to process

	clrdw	hgtSum.DWF_int			; Set total so far
	clr	hgtSum.DWF_frac

	call	HugeArrayEnum			; Do the enumeration
	
	;
	; Return stuff
	;
	movdw	cxdx, hgtSum.DWF_int
	mov	ax, hgtSum.DWF_frac
	.leave
	ret
LargeLineSumAndMarkRange	endp

TextRegion	ends

TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeFindMaxWidth
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
LargeFindMaxWidth	proc	near
	uses	bx, cx, di, bp
	.enter
	sub	sp, size LICL_vars		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	
	call	InitVarsForFindMaxWidth		; Set up the parameters

	;
	; Set up arguments.
	;
	call	T_GetVMFile
	push	bx				; VM file
	call	LargeGetLineArray		; di <- line-array
	push	di				; Pass line-array

	mov	di, cs
	push	di				; Pass callback
	mov	di, offset cs:CommonFindMaxWidth
	push	di

	clr	di				; di.di <- 0
	push	di
	push	di				; Line to start at

	dec	di				; di.di <- -1
	push	di
	push	di				; Count

	clrwbf	dxcl				; dx.cl <- Max width so far
	call	HugeArrayEnum			; Do the enumeration
	mov	al, cl				; dx.al <- Max width
	
	add	sp, size LICL_vars		; Restore stack frame
	.leave
	ret
LargeFindMaxWidth	endp

TextInstance	ends
