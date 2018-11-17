COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Bitmap Library
FILE:		drawRectTool.asm

AUTHOR:		Steve Yegge, Oct  6, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SY	10/ 6/92		Initial revision


DESCRIPTION:

	This file implements a non-filled rectangle tool.

	$Id: drawRectTool.asm,v 1.1 97/04/04 17:43:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapClassStructures	segment resource
	DrawRectToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource

DrawRectToolDraw	method	DrawRectToolClass, MSG_TOOL_DRAW
	uses	cx, dx
	.enter
	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	call	DragToolAdjustCoordsBeforeGrRoutine

	EditBitmap	DrawRectToolFillRect
	.leave
	ret
DrawRectToolDraw	endm

DrawRectToolFillRect	proc	far

	;
	;  make sure the lower-right corner is moved up, because
	;  we're only interested in pixel-oriented rectangles.
	;  (so we want the frame to be drawn TO the lower right
	;  pixel, not PAST it, as is the norm in the graphics
	;  system).
	;

	cmp	ax, cx
	jl	decCX
	
	dec	ax
	jmp	short	bottom

decCX:
	dec	cx
bottom:
	cmp	bx, dx
	jl	decDX

	dec	bx
	jmp	short	doIt

decDX:
	dec	dx
doIt:

	call	GrDrawRect
	ret
DrawRectToolFillRect	endp
	
BitmapToolCodeResource	ends			;end of tool code resource

