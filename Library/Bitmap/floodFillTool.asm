COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		FloodFillTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the FloodFillToolClass.

RCS STAMP:
$Id: floodFillTool.asm,v 1.1 97/04/04 17:43:44 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	FloodFillToolClass
BitmapClassStructures	ends

INITIAL_FLOOD_FILL_STACK_SIZE	equ	2000
FLOOD_FILL_STACK_DANGER_LEVEL	equ	1900

FFStackElement	struct
	FFSE_myX		word
	FFSE_myY		word
	FFSE_dadLx		word
	FFSE_dadRx		word
	FFSE_myDirection	word
FFStackElement	ends


FF_PUSH	macro	trashreg
ifnb	<trashreg>
	mov	trashreg, LFFSE1.FFSE_myX
	mov	es:[si].FFSE_myX, trashreg	

	mov	trashreg, LFFSE1.FFSE_myY
	mov	es:[si].FFSE_myY, trashreg

	mov	trashreg, LFFSE1.FFSE_dadLx
	mov	es:[si].FFSE_dadLx, trashreg

	mov	trashreg, LFFSE1.FFSE_dadRx
	mov	es:[si].FFSE_dadRx, trashreg

	mov	trashreg, LFFSE1.FFSE_myDirection
	mov	es:[si].FFSE_myDirection, trashreg
else
	push	ax

	mov	ax, LFFSE1.FFSE_myX
	mov	es:[si].FFSE_myX, ax	

	mov	ax, LFFSE1.FFSE_myY
	mov	es:[si].FFSE_myY, ax

	mov	ax, LFFSE1.FFSE_dadLx
	mov	es:[si].FFSE_dadLx, ax

	mov	ax, LFFSE1.FFSE_dadRx
	mov	es:[si].FFSE_dadRx, ax

	mov	ax, LFFSE1.FFSE_myDirection
	mov	es:[si].FFSE_myDirection, ax

	pop	ax
endif
	add	si, size FFStackElement
endm

FF_POP	macro	trashreg
	sub	si, size FFStackElement
ifnb	<trashreg>
	mov	trashreg, es:[si].FFSE_myX
	mov	LFFSE2.FFSE_myX, trashreg

	mov	trashreg, es:[si].FFSE_myY
	mov	LFFSE2.FFSE_myY, trashreg

	mov	trashreg, es:[si].FFSE_dadLx
	mov	LFFSE2.FFSE_dadLx, trashreg

	mov	trashreg, es:[si].FFSE_dadRx
	mov	LFFSE2.FFSE_dadRx, trashreg

	mov	trashreg, es:[si].FFSE_myDirection
	mov	LFFSE2.FFSE_myDirection, trashreg
else
	push	ax

	mov	ax, es:[si].FFSE_myX
	mov	LFFSE2.FFSE_myX, ax

	mov	ax, es:[si].FFSE_myY
	mov	LFFSE2.FFSE_myY, ax

	mov	ax, es:[si].FFSE_dadLx
	mov	LFFSE2.FFSE_dadLx, ax

	mov	ax, es:[si].FFSE_dadRx
	mov	LFFSE2.FFSE_dadRx, ax

	mov	ax, es:[si].FFSE_myDirection
	mov	LFFSE2.FFSE_myDirection, ax

	pop	ax
endif
endm

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloodFillToolGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	FloodFillTool method for MSG_TOOL_GET_POINTER_IMAGE

Called by:	MSG_TOOL_GET_POINTER_IMAGE

Pass:		*ds:si = FloodFillTool object
		ds:di = FloodFillTool instance

Return:		ax = MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
		^lcx:dx - "cross hairs" image

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloodFillToolGetPointerImage	method dynamic	FloodFillToolClass,
				MSG_TOOL_GET_POINTER_IMAGE
	.enter

	mov	ax, mask MRF_SET_POINTER_IMAGE
	mov	cx, handle paintBucket
	mov	dx, offset paintBucket

	.leave
	ret
FloodFillToolGetPointerImage	endm


FloodFillStart	method	FloodFillToolClass,	MSG_META_START_SELECT

threadHandle	local	hptr
vmFile		local	hptr
copyBlock	local	word
	.enter

	push	si					;save obj chunk

	push	cx, dx					;mouse location

	call	ToolMarkBusy

	mov	ax, MSG_VIS_BITMAP_GET_BITMAP_SIZE_IN_PIXELS
	call	ToolCallBitmap

	push	cx, dx					;save dims

	;
	;	Get an editing kit
	;
	push	bp
	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoFloodFillString
	mov	ax, MSG_TOOL_REQUEST_EDITING_KIT
	call	ObjCallInstanceNoLock

	mov	di, bp
	call	GrGetAreaColor
	pop	bp

	push	di					;save screen gstate

	push	ax, bx					;save area color

	;
	;  Copy the main bitmap so we can hooey with it
	;
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ToolCallBitmap

	mov	ss:[vmFile], cx
	mov	bx, cx					;bx <- vm file
	mov_tr	ax, dx					;ax <- vm block handle
	push	bp
	clr	bp					;not a db item
	mov	dx, bx					;copy in same file
	call	VMCopyVMChain				;ax <- new block handle
	pop	bp
	mov	ss:[copyBlock], ax
	mov_tr	di, ax					;di <- vm block handle
	mov     ax,TGIT_THREAD_HANDLE			;get thread handle
	clr     bx					;the current thread
	call    ThreadGetInfo				;ax = thread handle
	mov	ss:[threadHandle], ax
	xchg 	di,ax					;di = thread handle
							;ax <- vm block handle
	mov	bx, ss:[vmFile]
	call	GrEditBitmap				;di <- gstate handle

	call	HackAroundWinScale

	pop	ax, bx
	mov	ah, CF_RGB
	call	GrSetLineColor

	mov	si, bp					;si <- locals
	pop	bp					;bp <- screen gstate

	;
	;  Set the line color of the screen gstate
	;
	xchg	bp, di					;di <- screen gstate
	call	GrSaveState
	call	GrSetLineColor

	;
	;  Set the line width to 0
	;
	clr	ax, dx
	call	GrSetLineWidth

	xchg	bp, di

	pop	ax, bx					;ax,bx <- width,height
	pop	cx, dx					;cx,dx <- mouse loc.
	call	DoFloodFill

	xchg	bp, di					;di <- screen gstate
	call	GrRestoreState
	mov	di, bp					;di <- main gstate
	mov	bp, si					;bp <- locals
	pop	si					;*ds:si <- flood fill

	mov	dx, ss:[vmFile]
	mov	cx, ss:[copyBlock]

	push	di					;save gstate
	mov	ax, INVALIDATE_ENTIRE_FATBITS_WINDOW
	EditBitmap	DrawFloodFillBitmapToGState, DrawFloodFillBitmapToMask

	mov	ax, MSG_TOOL_FINISH_EDITING
	call	ObjCallInstanceNoLock

	pop	di					;di <- gstate
	call	GrDestroyState

	push	bp
	mov	bx, dx					;bx <- vm file handle
	mov	ax, cx					;ax <- bitmap block han
	clr	bp
	call	VMFreeVMChain
	pop	bp

	call	ToolMarkNotBusy

	.leave
	ret
FloodFillStart	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFloodFillBitmapToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		dx - vm file handle of flood fill bitmap
		cx - vm block handle of flood fill bitmap

		di - gstate

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFloodFillBitmapToGState	proc	far
	.enter

	call	GrSaveTransform
	
	;
	;  OK, here's the deal. We cleaned the window scale factor
	;  out of the bitmap, so we have to scale up the damn thing here
	;  by bitmap res/72. Aren't hacks fun?
	;

	pushdw	dxcx				;save bitmap

	mov	bx, dx
	mov_tr	ax, cx
	call	VMLock
	mov	ds, ax

	mov	dx, ds:[(size HugeArrayDirectory)].CB_yres
	clr	cx

	mov	bx, 72
	clr	ax
	call	GrUDivWWFixed

	pushwwf	dxcx				;save y scale

	mov	dx, ds:[(size HugeArrayDirectory)].CB_xres
	clr	cx
	call	GrUDivWWFixed

	popwwf	bxax
	call	GrApplyScale

	call	VMUnlock

	popdw	dxcx				;restore bitmap
	clr	ax,bx				;at 0,0
	call	GrDrawHugeBitmap

	call	GrRestoreTransform

	.leave
	ret
DrawFloodFillBitmapToGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFloodFillBitmapToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		dx - vm file handle of flood fill bitmap
		cx - vm block handle of flood fill bitmap

		di - gstate

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFloodFillBitmapToMask	proc	far
	.enter

	clr	ax,bx				;at 0,0
	call	GrFillHugeBitmap

	.leave
	ret
DrawFloodFillBitmapToMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFloodFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Takes a bitmap and fills the color-contiguous area containing
		the passed location with the gstate's line color.

Pass:		di - gstate to bitmap w/ mask
		cx,dx - "seed" location
		ax,bx - width, height of bitmap (for bounds checking)

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoFloodFill	proc	far

screenGState	local	hptr	push	bp
	ForceRef	screenGState
bitmapWidth	local	word	push	ax
	ForceRef	bitmapWidth
bitmapHeight	local	word	push	bx
	ForceRef	bitmapHeight


LFFSE1		local	FFStackElement
LFFSE2		local	FFStackElement
seedMask	local	byte				;the source mask bit
curMask		local	byte				;the current mask bit
seedR		local	byte
curR		local	byte
seedGB		local	word
curGB		local	word
EC<	maxStack	local	word		>

	uses	ax, bx, cx, dx, bp, si, di, es, ds

	.enter
EC<	mov	maxStack, 0			>

	push	cx, dx					;save x,y

	;
	;  Get the mask and color of the source point
	;
	call	GetCurPoint

	mov	al, ss:[curMask]
	mov	ss:[seedMask], al

	mov	al, ss:[curR]
	mov	ss:[seedR], al

	mov	ax, ss:[curGB]
	mov	ss:[seedGB], ax

	;
	;	Create our block. The current flags being passed are:
	;
	;	cl = HeapFlags = 0
	;
	;	ch = HeapAllocFlags = HAF_NO_ERR
	;
	mov	ax, INITIAL_FLOOD_FILL_STACK_SIZE
	mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8)		
	call	MemAlloc		; create the block
	mov	es, ax					;es:si = our fill stack
	clr	si

	pop	cx, dx					;get x,y

	push	bx					;save mem handle

	call	GetFillBounds
	call	EraseScanLine

	;
	;	Push the shadow below us to our stack
	;
	mov	LFFSE1.FFSE_myX, ax
	mov	LFFSE1.FFSE_dadLx, ax
	mov	LFFSE1.FFSE_dadRx, bx
	inc	dx					;one scanline down
	mov	LFFSE1.FFSE_myY, dx
	dec	dx
	mov	LFFSE1.FFSE_myDirection, 1

	FF_PUSH	ax					;push this element
							;onto our stack, trash
							;ax if you like
	;
	;	Push the shadow above us to our stack
	;
	dec	dx
	mov	LFFSE1.FFSE_myY, dx
	mov	LFFSE1.FFSE_myDirection, -1

	FF_PUSH	ax

outerLoop:
	tst	si
	jz	doneShort

if	ERROR_CHECK

	cmp	si, maxStack
	jle	checkOverFlow
	mov	maxStack, si
checkOverFlow:

endif	;ERROR_CHECK

	cmp	si, FLOOD_FILL_STACK_DANGER_LEVEL
	jle	afterCheckOverFlow
doneShort:
	jmp	done

afterCheckOverFlow:
	FF_POP	cx
	
	mov	cx, LFFSE2.FFSE_myX
	mov	dx, LFFSE2.FFSE_myY

	call	GetFillBounds
	jc	outerLoop				;loop if point was
							;out of the bitmap's
							;bounds

	cmp	cx, ax
	LONG	jl	notIn				;if left bound > source
							;point, that indicates
							;the the source point
							;is not in the fill
							;space

	;
	;	fill in this scan line
	;
	mov	cx, ax					;cx <- left scan bnd.
	call	EraseScanLine

	;
	;	Push shadow in same direction
	;
	mov	LFFSE1.FFSE_myX, cx
	mov	LFFSE1.FFSE_dadLx, cx
	mov	LFFSE1.FFSE_dadRx, bx
	add	dx, LFFSE2.FFSE_myDirection
	mov	LFFSE1.FFSE_myY, dx
	sub	dx, LFFSE2.FFSE_myDirection
	push	LFFSE2.FFSE_myDirection
	pop	LFFSE1.FFSE_myDirection

	FF_PUSH ax					;push the shadow to our
							;stack, trash ax as
							;needed

	;
	;	Check need for reverse direction shadows
	;
	mov	ax, LFFSE2.FFSE_dadLx
	dec	ax
	cmp	cx, ax
	jge	checkRightBound

	;
	;	We overlap, so we have to curl around
	;
	dec	ax
	mov	LFFSE1.FFSE_dadRx, ax
	mov	ax, LFFSE2.FFSE_myDirection
	neg	ax
	mov	LFFSE1.FFSE_myY, dx
	add	LFFSE1.FFSE_myY, ax
	mov	LFFSE1.FFSE_myDirection, ax

	FF_PUSH	ax

checkRightBound:
	;
	;	Check need for reverse direction shadows. This occurs when
	;	the child's right bound extends beyond the parent's right bound
	;	e.g.,
	;
	;	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	;	XXXXXXXXXX                 XXXXXX    XXXXX
	;	XXXXXXXXXX<--   parent  -->XXXXXX    XXXXX
	;	XXXXXXXXXX<----------- child ------->XXXXX
	;	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
	;
	mov	cx, LFFSE2.FFSE_dadRx
	inc	cx					;child must have right
	cmp	bx, cx					;bound > by 2 to merit
	jg	rightOverLap				;a U-turn

	;
	;	Check for underlap (i.e., child right bound less than parent's)
	;
	dec	cx					;child must have right
	dec	cx					;bound < by 2 to merit
	cmp	bx, cx					;continued search along
	jge	outerLoopShort				;same scan line

	;
	;	else, underlap
	;
	inc	bx					;bx <- child right + 2
	inc	bx					;(= next possible scan)
	inc	cx
	mov	LFFSE1.FFSE_myX, bx
	mov	LFFSE1.FFSE_dadLx, bx
	mov	LFFSE1.FFSE_dadRx, cx
	push	LFFSE2.FFSE_myY
	pop	LFFSE1.FFSE_myY
	push	LFFSE2.FFSE_myDirection
	pop	LFFSE1.FFSE_myDirection

	FF_PUSH ax
	jmp	outerLoop

rightOverLap:
	;
	;	We overlap, so we have to curl around
	;
	inc	cx
	mov	LFFSE1.FFSE_dadLx, cx
	mov	LFFSE1.FFSE_dadRx, bx

	mov	ax, LFFSE2.FFSE_myDirection
	neg	ax
	add	dx, ax
	mov	LFFSE1.FFSE_myY, dx
	mov	LFFSE1.FFSE_myDirection, ax

	FF_PUSH	ax

outerLoopShort:
	jmp	outerLoop

notIn:
	;
	;	ax = source point + 1
	;
	cmp	ax, LFFSE2.FFSE_dadRx			;was cx, trying ax
	jg	outerLoopShort

	push	LFFSE2.FFSE_dadLx
	pop	LFFSE1.FFSE_dadLx

	mov	LFFSE1.FFSE_myX, ax
	mov	LFFSE1.FFSE_myY, dx

	push	LFFSE2.FFSE_dadRx
	pop	LFFSE1.FFSE_dadRx

	push	LFFSE2.FFSE_myDirection
	pop	LFFSE1.FFSE_myDirection

	FF_PUSH ax

	jmp	outerLoop

done:
	pop	bx
	call	MemFree
	.leave
	ret
DoFloodFill	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ax - x1
		bx - x2
		dx - y

		di - gstate

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseScanLine	proc	near
	uses	ax, bx, cx, dx, si
	.enter	inherit DoFloodFill

	;
	;  Draw the line
	;
	push	ax, dx
	clr	ax, dx
	call	GrSetBitmapMode
	mov	cx, bx				;cx <- x2
	inc	cx
	pop	ax, bx
	call	GrDrawHLine

	push	di
	mov	di, ss:[screenGState]
	call	GrDrawHLine
	pop	di

	;
	;  If we're drawing to a masked portion, then there's no
	;  need to fill in the mask
	;
	tst	ss:[seedMask]
	jnz	done

	;
	;  We're drawing to an unmasked part of the bitmap, so we need
	;  to fill in the mask as well
	;

	push	ax
	mov	ax, mask BM_EDIT_MASK
	call	GrSetBitmapMode
	pop	dx
	test	ax, mask BM_EDIT_MASK
	jz	done

	mov	si, bx

	call	GrGetLineColor
	push	ax, bx

	mov	ax, C_BLACK
	call	GrSetLineColor

	mov_tr	ax, dx
	mov	bx, si
	call	GrDrawHLine

	pop	ax, bx
	mov	ah, CF_RGB
	call	GrSetLineColor	

done:
	.leave
	ret
EraseScanLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFillBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		di - gstate
		cx,dx - location

Return:		carry set if out of bounds
		ax,bx - left,right of fill bounds

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 21, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFillBounds	proc	near

	uses	cx, si

	.enter	inherit DoFloodFill

	tst	cx
	jl	outOfBounds

	tst	dx
	jl	outOfBounds

	cmp	cx, ss:[bitmapWidth]
	jge	outOfBounds

	cmp	dx, ss:[bitmapHeight]
	jge	outOfBounds

	;
	;  Get the mask bit of the point in question
	;

	call	GetCurPoint
	call	CmpCurPoint
	jnc	noSpan

	mov	si, cx		;bp <- left
findLeft:
	dec	cx		;si <- one more to the left
	jl	foundLeft

	call	GetCurPoint
	call	CmpCurPoint
	jc	findLeft

foundLeft:
	xchg	si, cx

findRight:
	inc	cx
	cmp	cx, ss:[bitmapWidth]
	jg	gotRight

	call	GetCurPoint
	call	CmpCurPoint
	jc	findRight

gotRight:
	mov	ax, si
	mov	bx, cx
	inc	ax
	dec	bx
	clc

done:
	.leave
	ret

noSpan:
	mov	ax, cx
	inc	ax			;indicate no span
	clc
	jmp	done

outOfBounds:
	stc
	jmp	done
GetFillBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  1, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurPoint	proc	near

	uses	ax, bx, dx
	.enter	inherit DoFloodFill

	;
	;  Get the mask bit
	;
	mov	ax, mask BM_EDIT_MASK
	mov	bx, dx				;bx <- y
	clr	dx				;no ColorTransfer
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	mov	ah, 1
	jz	afterMask

	push	bx
	mov	ax, cx				;ax <- x
	call	GrGetPoint
	pop	bx

afterMask:
	mov	ss:[curMask], ah

	;
	;  All unmasked pixels are equal, so if that's the case, we're done
	;
	tst	ah
	jz	done

	;
	;  Get the color of the pixel
	;
	clr	ax, dx
	call	GrSetBitmapMode

	mov	ax, cx				;ax <- x
	call	GrGetPoint

	mov	ss:[curR], al
	mov	ss:[curGB], bx
	
done:
	.leave
	ret
GetCurPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpCurPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  1, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpCurPoint	proc	near
	uses	ax
	.enter	inherit DoFloodFill

	;
	;  If we're dealing with an unmasked source, then the only
	;  requirement of the cur point is that it's unmasked
	;
	tst	ss:[seedMask]
	jz	unmasked

	;
	;  OK, the seed is masked; if cur point isn't, then no match
	;
	tst_clc	ss:[curMask]
	jz	done

	;
	;  Check the color
	;
	mov	al, ss:[seedR]
	cmp	al, ss:[curR]
	jne	fail

	mov	ax, ss:[seedGB]
	cmp	ax, ss:[curGB]
	je	success
	
fail:
	clc
done:
	.leave
	ret

unmasked:
	tst_clc	ss:[curMask]
	jnz	done

	;
	;  It's a match! Both pixels are unmasked
	;
success:
	stc
	jmp	done
CmpCurPoint	endp



BitmapToolCodeResource	ends			;end of tool code resource
