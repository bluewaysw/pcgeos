COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		eraserTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the EraserToolClass.

RCS STAMP:
$Id: eraserTool.asm,v 1.1 97/04/04 17:43:07 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	EraserToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraserToolGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	EraserTool method for MSG_TOOL_GET_POINTER_IMAGE

Called by:	MSG_TOOL_GET_POINTER_IMAGE

Pass:		*ds:si = EraserTool object
		ds:di = EraserTool instance

Return:		ax = MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
		^lcx:dx - "cross hairs" image

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraserToolGetPointerImage	method dynamic	EraserToolClass,
				MSG_TOOL_GET_POINTER_IMAGE
	.enter

	mov	ax, mask MRF_SET_POINTER_IMAGE
	mov	cx, handle eraserPointer
	mov	dx, offset eraserPointer

	.leave
	ret
EraserToolGetPointerImage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EraserToolStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	EraserTool method for MSG_META_START_SELECT

Called by:	

Pass:		*ds:si = EraserTool object
		ds:di = EraserTool instance

		cx, dx - coords

Return:		ax - mask MRF_PROCESSED

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
	sh	Apr 26, 1994	XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraserToolStartSelect	method dynamic	EraserToolClass, MSG_META_START_SELECT

	.enter

	;
	;	Call the super class
	;
	push	cx, dx
	mov	di, offset EraserToolClass
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
	mov	dx, offset undoEraseString
	mov	ax, MSG_TOOL_REQUEST_EDITING_KIT
	call	ObjCallInstanceNoLock

	call	ToolGrabMouse
	call	ToolSendAllPtrEvents

	pop	cx, dx

	segmov	es, SEGMENT_CS, di		; es <- vseg if XIP'ed
	mov	di, offset EraserDrawLine
	call	EraserEraseBitmap

	mov	ax, mask MRF_PROCESSED

	.leave
	ret
EraserToolStartSelect	endm

EraserDrawLine	proc	far
	mov	bx, dx			;bx <- y
	push	ax			;save radius
	mov_tr	dx, ax

	mov	ax, C_WHITE
	call	GrSetAreaColor
	call	GrSetLineColor

	mov	al, MM_COPY
	call	GrSetMixMode

	shl	dx
	inc	dx			;dx <- 2 * radius + 1
	clr	ax
	call	GrSetLineWidth

	pop	ax			;ax <- radius
	mov	dx, bx			;dx <- y
	push	cx, dx
	sub	bx, ax
	add	dx, ax
	inc	dx
	mov	bp, cx
	add	cx, ax
	inc	cx
	sub	bp, ax
	mov_tr	ax, bp
	call	GrFillRect

	push	ax
	mov	al, MM_NOP		;the erase part
	call	GrSetMixMode
	pop	ax

	call	GrFillRect

	mov	al, MM_COPY
	call	GrSetMixMode

	pop	ax, bx
	call	GrMoveTo

	ret
EraserDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EraserEraseBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets up a MSG_VIS_BITMAP_EDIT_BITMAP to the tool's bitmap

Pass:		*ds:si - Tool object

		es:di - fptr to callback graphics routine
			(vfptr if XIP'ed)

			* ToolEditBitmap will not work for graphics
			  routines that depend upon  ds, es, di, or si
			  as parameters!

		cx, dx - new location

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraserEraseBitmap	proc	near
	class	EraserToolClass
	uses	ax, bx, cx, dx, bp, di
	.enter

	pushdw	esdi			;mask callback
	pushdw	esdi			;normal callback
	mov	bp, C_WHITE
	push	bp

	;
	;  We want to invalidate the rectangle defined by the previous
	;  location and the new location, bumped out by the eraser's
	;  radius in either direction
	;

	ToolDeref	bp,ds,si

	mov	ax, ds:[bp].ETI_radius
	inc	ax				;fudge a little

	mov	bx, dx
	mov	di, ds:[bp].TI_previousY

	cmp	bx, di
	jle	bxSmallerY
	xchg	bx, di

bxSmallerY:

	sub	bx, ax
	add	di, ax

	push	di				;save bottom inval

	mov	di, ds:[bp].TI_previousX
	mov	bp, cx

	cmp	bp, di
	jle	bpSmallerX

	xchg	bp, di

bpSmallerX:

	sub	bp, ax
	add	di, ax

	push	di				;save right inval
	push	bx				;save top inval
	push	bp				;save left inval

	dec	ax				;unfudge

	push	dx
	push	cx
	push	ax
	push	ax

	mov	bp, ds:[si]
	push	ds:[bp].TI_editToken

	mov	bp, sp
	
	mov	ax, MSG_VIS_BITMAP_EDIT_BITMAP
	call	ToolCallBitmap

	add	sp, size VisBitmapEditBitmapParams

	.leave
	ret
EraserEraseBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EraserToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	EraserTool method for MSG_META_PTR

Called by:	

Pass:		*ds:si = EraserTool object
		ds:di = EraserTool instance

		cx, dx - coords

Return:		ax - mask MRF_PROCESSED

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
	sh	Apr 26, 1994	XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraserPtr	method dynamic	EraserToolClass, MSG_META_PTR

	;
	;	Call the super class
	;
	mov	di, offset EraserToolClass
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

afterConstrain:

	segmov	es, SEGMENT_CS, di		; es <- vseg if XIP'ed
	mov	di, offset EraserDrawLineTo
	call	EraserEraseBitmap

	ToolDeref	di,ds,si
	mov	ds:[di].TI_previousY, dx
	mov	ds:[di].TI_previousX, cx

	mov	ax, mask MRF_PROCESSED

done:
	.leave
	ret	

doConstrain:
	ToolDeref	di,ds,si
	call	ToolContrainMouseEventLikePencil
	jmp	afterConstrain

EraserPtr	endm

EraserDrawLineTo	proc	far

	push	ax				;save width

	call	GrGetCurPos
	call	GrDrawLine
	call	GrMoveTo

	mov	al, MM_NOP
	call	GrSetMixMode

	call	GrDrawLineTo

	pop	ax				;ax <- radius

	push	cx, dx				;save location
	movdw	bpbx, cxdx			;bp,bx <- center
	add	cx, ax				
	inc	cx
	add	dx, ax
	inc	dx
	sub	bx, ax
	sub	bp, ax
	mov_tr	ax, bp

	push	ax
	mov	al, MM_COPY
	call	GrSetMixMode
	pop	ax

	call	GrFillRect

	push	ax
	mov	al, MM_NOP
	call	GrSetMixMode
	pop	ax

	call	GrFillRect

	mov	al, MM_COPY
	call	GrSetMixMode

	pop	ax, bx				;restore location
	call	GrMoveTo

	ret
EraserDrawLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EraserToolEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	EraserTool method for MSG_META_END_SELECT

Called by:	

Pass:		*ds:si = EraserTool object
		ds:di = EraserTool instance

		cx, dx - coords

Return:		ax - mask MRF_PROCESSED

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraserToolEndSelect	method dynamic	EraserToolClass, MSG_META_END_SELECT

	.enter

	;
	;	Call super class
	;
	mov	di, offset EraserToolClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_BITMAP_INVALIDATE_IF_TRANSPARENT
	call	ToolCallBitmap

	call	ToolReleaseMouse

	mov	ax, mask MRF_PROCESSED

	.leave
	ret
EraserToolEndSelect	endm	

EraserInitialize	method	EraserToolClass, MSG_META_INITIALIZE

	mov	ds:[di].ETI_radius, DEFAULT_ERASER_RADIUS

	mov	di, offset EraserToolClass
	call	ObjCallSuperNoLock

	ret
EraserInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraserToolSetFatbitsMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Eraser method for MSG_TOOL_SET_FATBITS_MODE

Called by:	MSG_TOOL_SET_FATBITS_MODE

Pass:		*ds:si = Eraser object
		ds:di = Eraser instance

		cx - nonzero for fatbits

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraserToolSetFatbitsMode	method dynamic	EraserToolClass,
				MSG_TOOL_SET_FATBITS_MODE
	uses	cx,dx,bp
	.enter

	jcxz	noFatbits

	;
	;  Fatbits!
	;

	clr	ds:[di].ETI_radius

done:
	.leave
	ret

noFatbits:
	mov	ds:[di].ETI_radius, DEFAULT_ERASER_RADIUS
	jmp	done
EraserToolSetFatbitsMode	endm



BitmapToolCodeResource	ends			;end of tool code resource





