COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		textTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the TextToolClass.

RCS STAMP:
$Id: textTool.asm,v 1.1 97/04/04 17:43:35 newdeal Exp $

------------------------------------------------------------------------------@


if 0

idata	segment
	TextToolClass
idata	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource

TextInitialize	method	TextToolClass, MSG_META_INITIALIZE
	mov	di, offset TextToolClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	mov	ds:[di].TI_constrainStrategy, 	mask CS_NEVER_CONSTRAIN

	ret
TextInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TextToolAfterCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_AFTER_CREATE handler for TextToolClass.

CALLED BY:	

PASS:		*ds:si = TextTool object
		ds:di = TextTool instance

CHANGES:	

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextToolAfterCreate	method	TextToolClass, MSG_TOOL_AFTER_CREATE
	;
	;	Call superclass to create the vis link to the bitmap
	;
	mov	di, offset TextToolClass
	call	ObjCallSuperNoLock

	;
	;	Get the VTFB OD and store it away
	;
	mov	ax, MSG_VIS_BITMAP_GET_VTFB_OD
	call	ToolCallBitmap
	
	mov	di, ds:[si]
	mov	ds:[di].TTI_visText.handle, cx
	mov	ds:[di].TTI_visText.offset, dx

	ret
TextToolAfterCreate	endm

TextToolStart	method	TextToolClass,	MSG_META_START_SELECT

	mov	bx, MSG_VTFB_START_SELECT
	call	TextToolCallVTFBCommon
	jc	done

;	tst	ds:[di].TI_editingKit.TEK_screenGState
	jz	callSuper

	mov	ax, MSG_TOOL_FINISH_EDITING
	call	ObjCallInstanceNoLock

callSuper:
	mov	di, segment TextToolClass
	mov	es, di
	mov	di, offset TextToolClass
	mov	ax, MSG_META_START_SELECT
	call	ObjCallSuperNoLock
done:
	ret
TextToolStart	endm
	
TextToolDrag	method	TextToolClass,	MSG_META_DRAG_SELECT
	mov	bx, MSG_VTFB_DRAG_SELECT
	call	TextToolCallVTFBCommon
	jc	done

	mov	ax, MSG_TOOL_REQUEST_EDITING_KIT
	call	ObjCallInstanceNoLock
done:
	ret
TextToolDrag	endm
	
TextToolPtr	method	TextToolClass, MSG_META_PTR

	mov	bx, MSG_VTFB_PTR
	call	TextToolCallVTFBCommon
	jc	done

	mov	di, segment TextToolClass
	mov	es, di
	mov	di, offset TextToolClass
	call	ObjCallSuperNoLock
done:
	ret
TextToolPtr	endm

TextToolEnd	method	TextToolClass, MSG_META_END_SELECT
	mov	bx, MSG_VTFB_END_SELECT
	call	TextToolCallVTFBCommon
	jc	done

;	mov	bp, ds:[di].TI_editingKit.TEK_screenGState
	tst	bp
	jz	done

	call	ToolReleaseMouse

	mov	ax, MSG_DRAG_TOOL_DRAW_OUTLINE
	call	ObjCallInstanceNoLock

	xchg	di, bp
	call	GrRestoreState
	xchg	di, bp

	mov	cx, ds:[di].TI_initialX
	mov	bp, ds:[di].TI_previousX
	cmp	cx, bp
	jle	gotX
	xchg	cx, bp
gotX:
	mov	dx, ds:[di].TI_initialY
	cmp	dx, ds:[di].TI_previousY
	jle	gotY
	mov	dx, ds:[di].TI_previousY
gotY:
	sub	bp, cx
	mov	ax, MSG_VIS_BITMAP_PREPARE_VTFB
	call	ToolCallBitmap
done:
	ret
TextToolEnd	endm

TextToolCallVTFBCommon	proc	near
	class	TextToolClass

	uses	ax, bx, di, si
	.enter
	mov_trash	ax, bx
	mov	bx, ds:[di].TTI_visText.handle
	mov	si, ds:[di].TTI_visText.offset

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
TextToolCallVTFBCommon	endp

TextToolFinishEditing	method	TextToolClass, MSG_TOOL_FINISH_EDITING
	uses	ax, cx, dx, bp
	.enter
	clr	bp
;	xchg	bp, ds:[di].TI_editingKit.TEK_screenGState
	tst	bp
	jz	done

	push	si					;save tool offset

	push	di					;save instance ptr

	mov	bx, ds:[di].TTI_visText.handle
	mov	si, ds:[di].TTI_visText.chunk

	;
	;	If the text field is empty, then we don't want to draw anything
	;	to the screen
	;
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	tst	ax
	pop	di					;di <- instance ptr
;	mov	cx, ds:[di].TI_editingKit.TEK_gstate1
;	mov	dx, ds:[di].TI_editingKit.TEK_gstate2
	jz	afterDraw

	;
	;	Draw the text object into the screen
	;
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	if cx (= gstate 1 handle) is nonzero, draw to it
	;
	jcxz	tryGState2

	mov	bp, cx				;bp <- gstate 1
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

tryGState2:
	tst	dx
	jz	afterDraw
	mov	bp, dx				;bp <- gstate 2
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

afterDraw:
	mov	ax, MSG_VTFB_DISAPPEAR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	;	Signal that we are done with the gstate
	;
	pop	si
	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ToolCallBitmap
done:
	.leave
	ret
TextToolFinishEditing	endm

BitmapToolCodeResource	ends			;end of tool code resource

endif
