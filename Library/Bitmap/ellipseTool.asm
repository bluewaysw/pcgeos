COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		ellipseTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the EllipseToolClass.

RCS STAMP:
$Id: ellipseTool.asm,v 1.1 97/04/04 17:43:32 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	EllipseToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource

EllipseToolDraw	method	EllipseToolClass, MSG_TOOL_DRAW
	uses	cx, dx
	.enter
	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	; Don't adjust the coordinates, as for whatever reason, this
	; is unecessary when filling a path (I know, I really understand
	; why this is the way things are. Don't ask). -Don

;;;	call	DragToolAdjustCoordsBeforeGrRoutine

	EditBitmap	EllipseToolFillEllipse
	.leave
	ret
EllipseToolDraw	endm

EllipseToolFillEllipse	proc	far
	.enter

	; Create a path that is the ellipse, and then fill it. We do this
	; instead of just calling GrFillEllipse, as the imaging conventions
	; for a filled polygon are bizarre.
	;
	push	cx
	mov	cx, PCT_REPLACE
	call	GrBeginPath
	pop	cx
	call	GrFillEllipse
	call	GrEndPath
	mov	cl, RFR_ODD_EVEN
	call	GrFillPath

	; Delete the path we just created
	;
	push	cx
	mov	cx, PCT_NULL
	call	GrBeginPath
	pop	cx

	.leave
	ret
EllipseToolFillEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EllipseToolDrawOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DRAG_TOOL_DRAW_OUTLINE handler for EllipseToolClass.

CALLED BY:	

PASS:		*ds:si = EllipseTool object
		ds:di = EllipseTool instance

		bp - gstate

CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EllipseToolDrawOutline	method dynamic	EllipseToolClass,
			MSG_DRAG_TOOL_DRAW_OUTLINE
	uses	cx, dx
	.enter

	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	DisplayResizeFeedback	EllipseToolDrawFeedback

	.leave
	ret
EllipseToolDrawOutline	endm

EllipseToolDrawFeedback	proc	far
	uses	bp, si
	.enter

	movdw	bpsi, axdx

	call	GrGetMixMode
	push	ax
	call	GrGetLineWidth
	pushdw	dxax

	mov	al, MM_INVERT
	call	GrSetMixMode
	clr	ax, dx
	call	GrSetLineWidth

	mov	al, SDM_100
	call	GrSetLineMask

	movdw	axdx, bpsi

	call	GrDrawEllipse

	popdw	dxax
	call	GrSetLineWidth
	pop	ax
	call	GrSetMixMode

	.leave
	ret
EllipseToolDrawFeedback	endp

if 0
EllipseInitialize	method	EllipseToolClass, MSG_META_INITIALIZE
	mov	di, offset EllipseToolClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	mov	ds:[di].TI_constrainStrategy, CS_DIAGONAL_CONSTRAINT
	ret
EllipseInitialize	endm
endif
	
BitmapToolCodeResource	ends			;end of tool code resource

