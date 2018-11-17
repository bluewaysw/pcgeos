COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Bitmap Library
FILE:		drawEllipseTool.asm

AUTHOR:		Steve Yegge, Oct  6, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SY	10/ 6/92		Initial revision


DESCRIPTION:

	This file implements a non-filled ellipse tool.

	$Id: drawEllipseTool.asm,v 1.1 97/04/04 17:43:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapClassStructures	segment resource
	DrawEllipseToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource

DrawEllipseToolDraw	method	DrawEllipseToolClass, MSG_TOOL_DRAW
	uses	cx, dx
	.enter
	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	call	DragToolAdjustCoordsBeforeGrRoutine

	EditBitmap	DrawEllipseToolFrameEllipse
	.leave
	ret
DrawEllipseToolDraw	endm

DrawEllipseToolFrameEllipse	proc	far

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
	call	GrDrawEllipse
	ret
DrawEllipseToolFrameEllipse	endp
	
BitmapToolCodeResource	ends			;end of tool code resource

