COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		dragTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the dragToolClass, the
	generic drag tool object class for the bitmap library.

RCS STAMP:
$Id: dragTool.asm,v 1.1 97/04/04 17:43:03 newdeal Exp $
------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	DragToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolDrag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		
CHANGES:	

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DragToolStart	method	DragToolClass, MSG_META_START_SELECT
	mov	di, offset DragToolClass
	call	ObjCallSuperNoLock

	call	ToolGrabMouse

	ret
DragToolStart	endm

DragToolDrag	method	DragToolClass,	MSG_META_DRAG_SELECT
	mov	ds:[di].TI_previousX, cx
	mov	ds:[di].TI_previousY, dx

	;
	;	Get an editing kit
	;
	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoPaintingString
	mov	ax, MSG_TOOL_REQUEST_EDITING_KIT
	call	ObjCallInstanceNoLock

	call	ToolSendAllPtrEvents

	mov	ax, MSG_DRAG_TOOL_DRAW_OUTLINE
	call	ObjCallInstanceNoLock
	ret
DragToolDrag	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		*ds:si - Tool
		cx, dx - mouse event
		bp high = UIFunctionsActive (for UIFA_CONSTRAIN bit)
		bp low = ButtonInfo
		
RETURN:		ax - MouseReturnFlags

DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DragToolPtr	method	DragToolClass, MSG_META_PTR

	;
	;	Call the superclass with MSG_META_PTR
	;
	mov	di, offset DragToolClass
	call	ObjCallSuperNoLock
	test	ax, mask MRF_PROCESSED
	jnz	setPtrImage

	;
	;	Erase the old thing
	;
	mov	ax, MSG_DRAG_TOOL_DRAW_OUTLINE
	call	ObjCallInstanceNoLock

	;
	;	Draw the new thing
	;

	test	bp, mask UIFA_CONSTRAIN shl 8
	jz	afterContrain

	mov	ax, MSG_TOOL_CONSTRAIN_MOUSE
	call	ObjCallInstanceNoLock

afterContrain:
	ToolDeref	di,ds,si
	mov	ds:[di].TI_previousX, cx
	mov	ds:[di].TI_previousY, dx

	mov	ax, MSG_DRAG_TOOL_DRAW_OUTLINE
	call	ObjCallInstanceNoLock

setPtrImage:
	mov	cx, mask MRF_PROCESSED
	mov	ax, MSG_TOOL_GET_POINTER_IMAGE
	GOTO	ObjGotoInstanceTailRecurse
DragToolPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolContrainMouse
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
DragToolContrainMouse	method dynamic	DragToolClass, MSG_TOOL_CONSTRAIN_MOUSE

	.enter

	sub	cx, ds:[di].TI_initialX
	mov	ax, cx				;ax <- x diff
	jns	haveAbsX
	neg	cx				;cx <- abs x diff
haveAbsX:
	sub	dx, ds:[di].TI_initialY
	mov	bx, dx				;bx <- y diff
	jns	haveAbsY
	neg	dx				;dx <- abs y diff
haveAbsY:
	cmp	cx, dx
	ja	xBigger

	;
	;  We've dragged more vertical than horizontal, so we
	;  want to set the horizontal abs diff = vertical abs diff
	;
	tst	ax
	jns	haveNewXDiff

	;
	; the x diff was negative, so make the amount we're gonna add negative
	;
	neg	dx

haveNewXDiff:
	mov	cx, dx
	add	cx, ds:[di].TI_initialX
	mov	dx, bx
	add	dx, ds:[di].TI_initialY

done:
	.leave
	ret

xBigger:
	;
	;  We've dragged more horizontal than vertical, so we
	;  want to set the vertical abs diff = horizontal abs diff
	;
	tst	bx
	jns	haveNewYDiff

	;
	; the y diff was negative, so make the amount we're gonna add negative
	;
	neg	cx

haveNewYDiff:
	mov	dx, cx
	add	dx, ds:[di].TI_initialY
	mov_tr	cx, ax
	add	cx, ds:[di].TI_initialX
	jmp	done
DragToolContrainMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		
CHANGES:	

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DragToolEndSelect	method dynamic	DragToolClass, MSG_META_END_SELECT

	.enter

	call	ToolReleaseMouse

	;
	;	Erase the last thing drawn to the screen
	;
	ToolDeref	di,ds,si
	tst	ds:[di].TI_editToken
	jz	callSuper
	
	;
	;	May want to take this out, since the real draw will usually
	;	obscure the outline
	;
	mov	ax, MSG_DRAG_TOOL_DRAW_OUTLINE
	call	ObjCallInstanceNoLock

	;
	;	Restore the GState to normal so that we can make a
	;	real edit
	;
	mov	ax, MSG_TOOL_DRAW
	call	ObjCallInstanceNoLock

callSuper:
	;
	;	Call the super class
	;
	mov	di, segment DragToolClass
	mov	es, di
	mov	di, offset DragToolClass
	mov	ax, MSG_META_END_SELECT
	call	ObjCallSuperNoLock

	.leave
	ret
DragToolEndSelect	endm	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TOOL_DRAW handler for DragToolClass.

CALLED BY:	

PASS:		*ds:si = DragTool object
		ds:di = DragTool instance

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
DragToolDraw	method dynamic	DragToolClass,	MSG_TOOL_DRAW
	uses	cx, dx
	.enter

	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	call	DragToolAdjustCoordsBeforeGrRoutine

	EditBitmap	DragToolFillRect

	.leave
	ret
DragToolDraw	endm

DragToolFillRect	proc	far
	call	GrFillRect
	ret
DragToolFillRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolCleanupAfterExpose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DRAG_TOOL_DRAW_OUTLINE handler for DragToolClass.

CALLED BY:	

PASS:		*ds:si = DragTool object
		ds:di = DragTool instance

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
DragToolCleanupAfterExpose	method dynamic	DragToolClass,
				MSG_TOOL_CLEANUP_AFTER_EXPOSE
	.enter

	tst	ds:[di].TI_editToken
	jz	done

	mov	ax, MSG_DRAG_TOOL_DRAW_OUTLINE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
DragToolCleanupAfterExpose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DragToolDrawOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_DRAG_TOOL_DRAW_OUTLINE handler for DragToolClass.

CALLED BY:	

PASS:		*ds:si = DragTool object
		ds:di = DragTool instance

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
DragToolDrawOutline	method dynamic	DragToolClass,
			MSG_DRAG_TOOL_DRAW_OUTLINE
	uses	cx, dx
	.enter

	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	DisplayResizeFeedback	DragToolDrawFeedback

	.leave
	ret
DragToolDrawOutline	endm

DragToolDrawFeedback	proc	far
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

	call	GrDrawRect

	popdw	dxax
	call	GrSetLineWidth
	pop	ax
	call	GrSetMixMode

	.leave
	ret
DragToolDrawFeedback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DragToolDisplayInteractiveFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets up a MSG_VIS_BITMAP_EDIT_BITMAP to the tool's bitmap

Pass:		*ds:si - Tool object

		es:di - fptr to callback graphics routine
			(vfptr ig XIP'ed)

			* ToolEditBitmap will not work for graphics
			  routines that depend upon  ds, es, di, or si
			  as parameters!

		ax,bx,cx,dx - params to callback routine

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DragToolDisplayInteractiveFeedback	proc	far
	class	ToolClass
	uses	ax, bp
	.enter

	pushdw	esdi
	pushdw	esdi
	mov	bp, C_BLACK
	push	bp

	;
	;	Assume inval rect is ax,bx,cx,dx
	;
	push	dx
	push	cx
	push	bx
	push	ax

	push	dx
	push	cx
	push	bx
	push	ax

	mov	bp, ds:[si]
	push	ds:[bp].TI_editToken

	mov	bp, sp
	
	mov	ax, MSG_VIS_BITMAP_DISPLAY_INTERACTIVE_FEEDBACK
	call	ToolCallBitmap

	add	sp, size VisBitmapEditBitmapParams

	.leave
	ret
DragToolDisplayInteractiveFeedback	endp



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
DragToolAdjustCoordsBeforeGrRoutine	proc	near
	.enter

	cmp	ax, cx
	jge	incAx

	inc	cx

checkVert:
	cmp	bx, dx
	jge	incBx

	inc	dx

done:
	.leave
	ret

incAx:
	inc	ax
	jmp	checkVert

incBx:
	inc	bx
	jmp	done
DragToolAdjustCoordsBeforeGrRoutine	endp



BitmapToolCodeResource	ends			;end of tool code resource
				   
