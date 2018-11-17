COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		selectionTool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	6/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the SelectionToolClass.

RCS STAMP:
$Id: selectionTool.asm,v 1.1 97/04/04 17:43:30 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	SelectionToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SelectionToolInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_INITIALIZE handler for SelectionToolClass.

CALLED BY:	

PASS:		*ds:si = SelectionTool object
		ds:di = SelectionTool instance
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call superclass
		setup constrain strategy
		get initial line mask for marching ants

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0

SelectionToolInitialize	method	SelectionToolClass, MSG_META_INITIALIZE
	;
	;	call super class
	mov	di, offset SelectionToolClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]

	;
	;	The selection tool wants diagonal constraint when dragging
	;	open (so it can select perfect squares), and then pencil-
	;	like constraint when dragging around. go figure. will have
	;	to do something about this LATER
	;
	;	
	;	ACTUALLY, I think I like the way DPaint does it: constrain
	;	like the pencil (i.e. vertical or horizontal)
	;
	;	Maybe a combo with square initially, then pencil if release/
	;	reassert.
	;
	;	Whatever.
	;
	;	On with the code now...
	;
	mov	ds:[di].TI_constrainStrategy, CS_DIAGONAL_CONSTRAINT
	ret
SelectionToolInitialize	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SelectionToolDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SelectionTool method for MSG_TOOL_DRAW

Called by:	

Pass:		*ds:si = SelectionTool object
		ds:di = SelectionTool instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectionToolDraw	method dynamic	SelectionToolClass, MSG_TOOL_DRAW

	uses	cx, dx

	.enter

	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY
	mov	cx, ds:[di].TI_previousX
	mov	dx, ds:[di].TI_previousY

	EditBitmap	SelectionToolSelectRectangle

	.leave
	ret
SelectionToolDraw	endm

SelectionToolSelectRectangle	proc	far
	push	cx
	mov	cx, PCT_REPLACE
	call	GrBeginPath
	pop	cx
	call	GrDrawRect
	call	GrEndPath
	ret
SelectionToolSelectRectangle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectionToolRequestEditingKit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SelectionTool method for MSG_TOOL_REQUEST_EDITING_KIT

Called by:	MSG_TOOL_REQUEST_EDITING_KIT

Pass:		*ds:si = SelectionTool object
		ds:di = SelectionTool instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectionToolRequestEditingKit	method dynamic	SelectionToolClass,
				MSG_TOOL_REQUEST_EDITING_KIT
	uses	cx,dx
	.enter

	clr	cx
	mov	di, offset SelectionToolClass
	call	ObjCallSuperNoLock

	.leave
	ret
SelectionToolRequestEditingKit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SelectionToolEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_END_SELECT  handler for
		SelectionToolClass.

CALLED BY:	

PASS:		*ds:si = SelectionTool object
		ds:di = SelectionTool instance
		cx,dx = mouse event location
		bp low = ButtonInfo
		bp high = UIFunctionsActive
		
CHANGES:	

RETURN:		ax = MouseReturnFlags = MRF_PROCESSED

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectionToolEnd	method	SelectionToolClass,
			MSG_META_END_SELECT
	.enter
	;
	;	Erase the last thing drawn to the screen
	;
	
	; Do the test before calling the superclass because the superclass
	; will zero this value.  We only care about this value to know if it
	; is zero or not.  -JimG 7/21/94
	tst	ds:[di].TI_editToken
	pushf

	mov	ax, MSG_VIS_BITMAP_MAKE_SURE_NO_SELECTION_ANTS
	call	ToolCallBitmap

	mov	ax, MSG_META_END_SELECT
	mov	di, segment SelectionToolClass
	mov	es, di
	mov	di, offset SelectionToolClass
	call	ObjCallSuperNoLock
	
	;
	; Is there any edit token?  If not, get outta' here.  We need to be
	; sure that we called the superclass even if there is no edit token
	; because otherwise we will not release the mouse grab (bad bad).
	; That causes an EC crash.  --JimG 7/19/94
	;
	popf
	jz	clearSelection

	;
	;  Don't make this undoable to hide a bug in the undo code
	;

	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	ObjMessage

	mov	ax, MSG_VIS_BITMAP_SPAWN_SELECTION_ANTS
	call	ToolCallBitmap

	mov	ax, MSG_VIS_BITMAP_NOTIFY_SELECT_STATE_CHANGE
	call	ToolCallBitmap
done:
	mov	ax, mask MRF_PROCESSED
	.leave
	ret
clearSelection:
	jmp	done
SelectionToolEnd	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SelectionToolFinishEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TOOL_FINISH_EDITING handler for SelectionToolClass.

CALLED BY:	

PASS:		*ds:si = SelectionTool object
		ds:di = SelectionTool instance
		cx, dx = x, y offset from left, top of screen to left,top of
			VisBitmap
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
if 0

SelectionToolFinishEditing	method	SelectionToolClass, MSG_TOOL_FINISH_EDITING
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	;
	;	See if we have a partial bitmap yet.
	;
	clr	bp
	xchg	bp, ds:[di].STI_selectedGString
	tst	bp
	jnz	gotGString

	;
	;	Make sure we have a gstate
	;
	mov	bp, ds:[di].TI_editingKit.TEK_screenGState
	tst	bp
	jz	done

	;
	;	Copy a portion of the bitmap to another bitmap
	;	
	;	bx <- new bitmap handle
	;	cx,dx <- width, height of new bitmap
	;
	call	SelectionToolGetPartialBitmap

	push	bx					;save bitmap handle

	;
	;	Move selected area coords into ax,bx,cx,dx
	;
	mov	ax, ds:[di].STI_selectedInitialX
	mov	bx, ds:[di].STI_selectedInitialY
	mov	cx, ds:[di].STI_selectedPreviousX
	mov	dx, ds:[di].STI_selectedPreviousY

	xchg	bp, di					;bp <- instance ptr
							;di <- gstate handle

	;
	;	Erase the source location on screen
	;
	call	BlotRect

	mov	di, ds:[bp].TI_editingKit.TEK_gstate1
	tst	di
	jz	tryBlot2
	call	BlotRect

tryBlot2:
	mov	di, ds:[bp].TI_editingKit.TEK_gstate2
	tst	di
	jz	doneBlotting
	call	BlotRect

doneBlotting:
	pop	bx					;bx <- bitmap handle
	;
	;	Copy the bitmap piece to the proper destination
	;
	mov	ax, ds:[bp].TI_previousX
	mov	cx, ds:[bp].TI_initialX
	cmp	cx, ax
	jle	getY
	mov_trash	cx, ax
getY:
	mov	ax, ds:[bp].TI_previousY
	mov	dx, ds:[bp].TI_initialY
	cmp	dx, ax
	jle	gotY
	mov_trash	dx, ax
gotY:
	mov_trash	ax, si				;ax <- tool offset
	clr	si					;bx:si = bitmap

	mov	di, ds:[bp].TI_editingKit.TEK_screenGState
	call	DrawBitmapToGState

	mov	di, ds:[bp].TI_editingKit.TEK_gstate1
	tst	di
	jz	tryDraw2
	call	DrawBitmapToGState

tryDraw2:
	mov	di, ds:[bp].TI_editingKit.TEK_gstate2
	tst	di
	jz	doneDrawing
	call	DrawBitmapToGState
doneDrawing:
	call	MemFree

	mov_trash	si, ax				;si <- tool offset
	mov	ax, MSG_CHECK_IN_EDITING_KIT
	call	ToolCallBitmap

done:
	.leave
	ret

gotGString:
	;
	;	Since we already have the gstring, we just need to draw it
	;	to the screen
	;
	mov	si, bp					;si <- gstring handle
	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_initialY

	push	ds:[di].TI_editingKit.TEK_gstate2
	push	ds:[di].TI_editingKit.TEK_gstate1

	mov	di, ds:[di].TI_editingKit.TEK_screenGState
	clr	dx					;no flags
	call	GrDrawGString

	pop	di
	tst	di
	jz	check2
	clr	dx
	call	GrDrawGString

check2:
	pop	di
	tst	di
	jz	killString
	clr	dx
	call	GrDrawGString	
killString:
	mov	di, si
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString
	jmp	done
SelectionToolFinishEditing	endm


BlotRect	proc	near
	call	GrSaveState
	push	ax
	mov	ax, C_WHITE
	call	GrSetAreaColor
	pop	ax
	call	GrFillRect
	call	GrRestoreState
	ret
BlotRect	endp

SelectionToolGetPartialBitmap	proc	near
	class	SelectionToolClass
	uses	ax, bp, di
	.enter
	;
	;	Get the handle of the bitmap so we can suck a piece from it.
	;
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ToolCallBitmap

	;
	;	Move selected area coords into ax,bx,cx,dx
	;
	mov	ax, ds:[di].STI_selectedInitialX
	mov	bx, ds:[di].STI_selectedInitialY
	mov	cx, ds:[di].STI_selectedPreviousX
	mov	dx, ds:[di].STI_selectedPreviousY

	;
	;	Arrange ax,bx,cx,dx so that:
	;
	;	ax,bx = left,top of selected area.
	;	cx,dx = width,height of selected area
	;
	cmp	ax, cx
	jle	gotX
	xchg	ax, cx
gotX:						;assert ax = left, cx = right
	cmp	bx, dx
	jle	gotY
	xchg	bx, dx
gotY:						;assert bx = top, dx = bottom
	sub	cx, ax				;cx <- width
	sub	dx, bx				;dx <- height

	mov	di, bp
	call	GrGetBitmap
	.leave
	ret
SelectionToolGetPartialBitmap	endp

SelectionToolCopy	method	SelectionToolClass, MSG_TOOL_COPY
	call	SelectionToolGetPartialBitmap
	call	CopyBitmapToClipboardGString
	call	MemFree
	stc
	ret
SelectionToolCopy	endm

SelectionToolPaste	method	SelectionToolClass, MSG_TOOL_PASTE
	;
	;	Get a GState to write changes to from the VisBitmap,
	;	and store it away in our instance data.
	;
	mov	ax, MSG_CHECK_OUT_EDITING_KIT
	call	ToolCallBitmap

	mov	ds:[di].TI_editingKit.TEK_screenGState, bp
	mov	ds:[di].TI_editingKit.TEK_gstate1, cx
	mov	ds:[di].TI_editingKit.TEK_gstate2, dx

	mov	ax, MSG_VIS_BITMAP_CREATE_SCRATCH_GSTRING
	call	ToolCallBitmap
	mov	ds:[di].STI_selectedGString, bp

	call	BitmapCopyClipboardToGString
	jnc	done

	mov	ax, ds:[di].TI_initialX
	mov	ds:[di].STI_selectedInitialX, ax
	add	ax, cx
	mov	ds:[di].TI_previousX, ax
	mov	ds:[di].STI_selectedPreviousX, ax

	mov	ax, ds:[di].TI_initialY
	mov	ds:[di].STI_selectedInitialY, ax
	add	ax, dx
	mov	ds:[di].TI_previousY, ax
	mov	ds:[di].STI_selectedPreviousY, ax

	mov	ax, MSG_SPAWN_ANTS
	call	ObjCallInstanceNoLock
done:
	ret

SelectionToolPaste	endm

endif



BitmapToolCodeResource	ends			;end of tool code resource
