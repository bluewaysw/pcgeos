COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		lineTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the LineToolClass.

RCS STAMP:
$Id: lineTool.asm,v 1.1 97/04/04 17:43:42 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	LineToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			LineToolDrawOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DRAG_TOOL_DRAW_OUTLINE handler for LineToolClass.

CALLED BY:	

PASS:		*ds:si = LineTool object
		ds:di = LineTool instance

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
LineToolDrawOutline	method dynamic	LineToolClass,
			MSG_DRAG_TOOL_DRAW_OUTLINE
	uses	cx, dx
	.enter

	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

;	call	LineToolAdjustCoordsBeforeGrRoutine

	DisplayResizeFeedback	LineToolDrawFeedback

	.leave
	ret
LineToolDrawOutline	endm

LineToolDrawFeedback	proc	far
	uses	bp, si
	.enter

	movdw	bpsi, axdx

	call	GrGetMixMode
	push	ax
	call	GrGetLineWidth
	pushdw	dxax

	mov	al, GMT_ENUM
	call	GrGetLineMask
	push	ax

	mov	al, MM_INVERT
	call	GrSetMixMode
	clr	ax, dx
	call	GrSetLineWidth

	mov	al, SDM_100
	call	GrSetLineMask

	movdw	axdx, bpsi

	call	GrDrawLine

	pop	ax
	call	GrSetLineMask

	popdw	dxax
	call	GrSetLineWidth
	pop	ax
	call	GrSetMixMode

	.leave
	ret
LineToolDrawFeedback	endp


LineToolDraw	method	LineToolClass, MSG_TOOL_DRAW
	uses	cx, dx, di
	.enter
	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

;	call	LineToolAdjustCoordsBeforeGrRoutine

	EditBitmap	LineDrawLine
	.leave
	ret
LineToolDraw	endm

LineDrawLine	proc	far

	call	GrDrawLine
	ret

LineDrawLine	endp
	

if 0
LineInitialize	method	LineToolClass, MSG_META_INITIALIZE
	mov	di, offset LineToolClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	mov	ds:[di].TI_constrainStrategy, 	CS_HV_CONSTRAINT or \
						CS_DIAGONAL_CONSTRAINT
	ret
LineInitialize	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DragToolAdjustCoordsBeforeGrRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ax,bx - point #1
		cx,dx - point #2

Return:		ax,bx,cx,dx adjusted as necessary

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
LineToolAdjustCoordsBeforeGrRoutine	proc	near
	.enter

	cmp	ax, cx
	je	checkY
	jg	incAx

	inc	cx

checkY:
	cmp	bx, dx
	je	done
	jg	incBx

	inc	dx

done:
	.leave
	ret

incAx:
	inc	ax
	jmp	checkY

incBx:
	inc	bx
	jmp	done
LineToolAdjustCoordsBeforeGrRoutine	endp
endif	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			LineToolContrainMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - Tool
		cx,dx  - mouse event

Return:		cx,dx - constrained

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan  2, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineToolContrainMouse	method dynamic	LineToolClass, MSG_TOOL_CONSTRAIN_MOUSE
	uses	bp
	.enter

	mov	ax, cx
	sub	ax, ds:[di].TI_initialX
	pushf					;save X diff sign
	jns	haveAbsX
	neg	ax				;cx <- abs x diff
haveAbsX:
	mov	bx, dx
	sub	bx, ds:[di].TI_initialY
	pushf					;save Y diff sign
	jns	haveAbsY
	neg	bx				;dx <- abs y diff
haveAbsY:
	mov	bp, sp
	cmp	ax, bx
	ja	xBigger

	;
	;  We've dragged more vertical than horizontal, so we
	;  want to zero the horizontal diff
	;

	mov	cx, ds:[di].TI_initialX

	;
	; If we've dragged less than twice as much in the vertical direction,
	; settle for a 45 degree constrain by setting horiz diff to vert diff
	;
	shl	ax, 1
	cmp	bx, ax
	ja	done			;more than twice in vertical
	test	ss:[bp]+(size word), mask CPU_SIGN ;was X difference negative?
	jns	posXDiff
	neg	bx			;yes, need new diff to be neg
posXDiff:
	add	cx, bx			;adjust horiz by vert diff

done:
	pop	ax			;remove flags
	pop	ax
	.leave
	ret

xBigger:
	;
	;  We've dragged more horizontal than vertical, so we
	;  want to zero the vertical diff
	;
	mov	dx, ds:[di].TI_initialY

	;
	; If we've dragged less than twice as much in the horiz direction,
	; settle for a 45 degree constrain by setting vert diff to horiz diff
	;
	shl	bx, 1
	cmp	ax, bx
	ja	done			;more than twice in horiz
	test	ss:[bp], mask CPU_SIGN	;was Y difference negative?
	jns	posYDiff
	neg	ax			;yes, need new diff to be neg
posYDiff:
	add	dx, ax			;adjust vert by horiz diff
	jmp	done
LineToolContrainMouse	endp

BitmapToolCodeResource	ends			;end of tool code resource

