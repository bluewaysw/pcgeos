COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		pencilTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the PencilToolClass.

RCS STAMP:
$Id: pencilTool.asm,v 1.1 97/04/04 17:43:02 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	PencilToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PencilToolStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	PencilTool method for MSG_META_START_SELECT

Called by:	

Pass:		*ds:si = PencilTool object
		ds:di = PencilTool instance

		cx, dx - coords

Return:		ax - mask MRF_PROCESSED

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PencilToolStartSelect	method dynamic	PencilToolClass, MSG_META_START_SELECT

	.enter

	;
	;	Call the super class
	;
	push	cx, dx
	mov	di, offset PencilToolClass
	call	ObjCallSuperNoLock

	;
	;  Clear out the initial[XY] fields to indicate that we haven't
	;  been constraining
	;
	clr	ax
	ToolDeref	di, ds, si
	mov	ds:[di].TI_initialX, ax
	mov	ds:[di].TI_initialY, ax

	mov	cx, handle BitmapUndoStrings
	mov	dx, offset undoPaintingString
	mov	ax, MSG_TOOL_REQUEST_EDITING_KIT
	call	ObjCallInstanceNoLock

	call	ToolGrabMouse
	call	ToolSendAllPtrEvents

	pop	cx, dx
	mov	ax, cx
	mov	bx, dx
	EditBitmap	PencilDrawLine

	mov	ax, mask MRF_PROCESSED

	.leave
	ret
PencilToolStartSelect	endm

PencilDrawLine	proc	far
	call	GrDrawLine
	ret
PencilDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PencilToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	PencilTool method for MSG_META_PTR

Called by:	

Pass:		*ds:si = PencilTool object
		ds:di = PencilTool instance

		cx, dx - coords

Return:		ax - mask MRF_PROCESSED

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PencilPtr	method dynamic	PencilToolClass, MSG_META_PTR

	.enter

	;
	;	Call the super class
	;
	mov	di, offset PencilToolClass
	call	ObjCallSuperNoLock
	test	ax, mask MRF_PROCESSED
	jnz	done
	
	;
	;	Draw the new line to the screen
	;

	test	bp, mask UIFA_CONSTRAIN shl 8
	jnz	doConstrain

	;
	;  There's no constraining, so clear out the initial X,Y fields
	;  to indicate that
	;

	ToolDeref	di,ds,si
	clr	ds:[di].TI_initialX
	clr	ds:[di].TI_initialY

checkLineInc:

	movdw	axbx, cxdx

	push	cx
	push	dx

	cmp	cx, ds:[di].TI_previousX
	jle	checkY
	inc	cx

checkY:
	cmp	dx, ds:[di].TI_previousY
	jle	editBitmap
	inc	dx

editBitmap:

	call	PencilEditBitmap

	ToolDeref	di, ds, si
	pop	ds:[di].TI_previousY
	pop	ds:[di].TI_previousX

	mov	ax, mask MRF_PROCESSED

done:
	.leave
	ret

doConstrain:
	ToolDeref	di,ds,si
	call	ToolContrainMouseEventLikePencil
	jmp	checkLineInc
PencilPtr	endm

PencilDrawLineTo	proc	far
	call	GrDrawLineTo
	call	GrMoveTo
	ret
PencilDrawLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolContrainMouseEventLikePencil
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
ToolContrainMouseEventLikePencil	proc	near
	class	ToolClass
	uses	ax, bx, di
	.enter

	ToolDeref	di,ds,si

	tst	ds:[di].TI_initialX
	jnz	constrainX
	tst	ds:[di].TI_initialY
	jnz	constrainY

	mov	ax, cx
	sub	ax, ds:[di].TI_previousX
	jns	haveAbsX
	neg	ax				;ax <- abs x dif
haveAbsX:
	mov	bx, dx
	sub	bx, ds:[di].TI_previousY
	jns	haveAbsY
	neg	bx				;bx <- abs y diff
haveAbsY:
	cmp	bx, ax
	ja	constrainingX

;constrainingY:
	mov	ds:[di].TI_initialY, 0xffff
	clr	ds:[di].TI_initialX
constrainY:
	mov	dx, ds:[di].TI_previousY
	jmp	done

constrainingX:
	mov	ds:[di].TI_initialX, 0xffff
	clr	ds:[di].TI_initialY
constrainX:
	mov	cx, ds:[di].TI_previousX

done:
	.leave
	ret
ToolContrainMouseEventLikePencil	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PencilEditBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets up a MSG_VIS_BITMAP_EDIT_BITMAP to the pencil's bitmap

Pass:		*ds:si - Pencil object

		ax,bx -	document coords of current pencil location
		cx,dx - pixel-wise coords of current pencil location
			(different 'cause drawing a line from A -> B
			 only fills in pixels A -> B-1)

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
	sh	Apr 26, 1994	XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PencilEditBitmap	proc	near
	class	PencilToolClass
if FULL_EXECUTE_IN_PLACE
	uses	ax, bp, es
else
	uses	ax, bp
endif
	.enter

FXIP<	segmov	es, SEGMENT_CS, bp	>
	mov	bp, offset PencilDrawLineTo
FXIP<	pushdw	esbp			>
FXIP<	pushdw	esbp			>
NOFXIP<	pushdw	csbp			>	;mask callback
NOFXIP<	pushdw	csbp			>	;normal callback
	mov	bp, C_BLACK
	push	bp

	;
	;	Inval rect is TI_previous[X,Y] and cx,dx
	;
	push	dx
	push	cx

	ToolDeref	bp,ds,si
	push	ds:[bp].TI_previousY
	push	ds:[bp].TI_previousX

	push	dx
	push	cx
	push	bx
	push	ax

	push	ds:[bp].TI_editToken

	mov	bp, sp
	
	mov	ax, MSG_VIS_BITMAP_EDIT_BITMAP
	call	ToolCallBitmap

	add	sp, size VisBitmapEditBitmapParams

	.leave
	ret
PencilEditBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PencilToolEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	PencilTool method for MSG_META_END_SELECT

Called by:	

Pass:		*ds:si = PencilTool object
		ds:di = PencilTool instance

		cx, dx - coords

Return:		ax - mask MRF_PROCESSED

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PencilToolEndSelect	method dynamic	PencilToolClass, MSG_META_END_SELECT

	.enter

	;
	;	Call super class
	;
	mov	di, offset PencilToolClass
	call	ObjCallSuperNoLock

	call	ToolReleaseMouse

	mov	ax, mask MRF_PROCESSED

	.leave
	ret
PencilToolEndSelect	endm	
BitmapToolCodeResource	ends			;end of tool code resource









