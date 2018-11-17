COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		tool.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	5/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the ToolClass, the
	generic tool object class for the bitmap library.

RCS STAMP:
$Id: tool.asm,v 1.1 97/04/04 17:43:11 newdeal Exp $

------------------------------------------------------------------------------@
BitmapClassStructures	segment resource
	ToolClass
BitmapClassStructures	ends

BitmapToolCodeResource	segment	resource	;start of tool code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tool method for MSG_TOOL_GET_POINTER_IMAGE

Called by:	MSG_TOOL_GET_POINTER_IMAGE

Pass:		*ds:si = Tool object
		ds:di = Tool instance


Return:		ax = mask MRF_SET_POINTER_IMAGE
		^lcx:dx - "cross hairs" image

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolGetPointerImage	method dynamic	ToolClass, MSG_TOOL_GET_POINTER_IMAGE
	.enter

	mov	ax, mask MRF_SET_POINTER_IMAGE
	mov	cx, handle crossHairs
	mov	dx, offset crossHairs

	.leave
	ret
ToolGetPointerImage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				ToolStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_START_* handler for ToolClass

CALLED BY:	UI

PASS:		*ds:si = Tool object
		ds:di = Tool instance
		cx, dx = mouse location
		bp high = UIFunctionsActive
		bp low = ButtonInfo
		
CHANGES:	

RETURN:		ax - mask MRF_PROCESSED

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolStart	method	ToolClass,	MSG_META_START_SELECT

	.enter

	;
	;	Set up the constrain strategy
	;
;	mov	ax, ds:[di].TI_constrainStrategy
;	mov	ds:[di].TI_tempConstrainStrategy, ax

	;
	;	Store the initial coordinates
	;
	mov	ds:[di].TI_initialX, cx
	mov	ds:[di].TI_initialY, dx
	mov	ds:[di].TI_previousX, cx
	mov	ds:[di].TI_previousY, dx

	mov	ax, mask MRF_PROCESSED
	.leave
	ret
ToolStart	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolRequestEditingKit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	MSG_TOOL_REQUEST_EDITING_KIT handler for ToolClass
		Queries for a number of gstates from the VisBitmap;
		any non-nil gstates returned are to be included in any edits.
		The gstates are recorded into the object's instance data

PASS:		ds:si 	= ToolClass object
		ds:di 	= ToolClass instance

		cx:dx - optr to undo string

RETURN:		bp = screen gstate
		cx,dx = other gstates (possibly null)

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8/13/91 		Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolRequestEditingKit	method	ToolClass, MSG_TOOL_REQUEST_EDITING_KIT

	.enter
	;
	;	Get a GState to write changes to from the VisBitmap,
	;	and store it away in our instance data.
	;

	pushdw	cxdx
	mov	ax, MSG_TOOL_FINISH_EDITING
	push	ax
	push	ds:[LMBH_handle], si

	mov	bp, sp

	mov	ax, MSG_VIS_BITMAP_GET_EDITING_GSTATES
	call	ToolCallBitmap

	add	sp, size VisBitmapGetEditingGStatesParams

	ToolDeref	di,ds,si
	mov	ds:[di].TI_editToken, cx

	.leave
	ret
ToolRequestEditingKit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				ToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_PTR handler for ToolClass

CALLED BY:	UI

PASS:		*ds:si = Tool object
		ds:di = Tool instance
		cx, dx = location of mouse event
		bp high = UIFunctionsActive (for UIFA_CONSTRAIN bit)
		bp low = ButtonInfo
		
RETURN:		if the tool is active and processed this method
			ax - mask MRF_PROCESSED
		if inactive (has no screen gstate)
			ax - 0

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolPtr	method	ToolClass, MSG_META_PTR

	.enter

	;
	;	If we have a gstate, then we are editing; otherwise the
	;	mouse should just pass overhead.
	;
	clr	ax
	cmp	ds:[di].TI_editToken, ax
	jnz	done
	mov	ax, mask MRF_PROCESSED
done:
	.leave
	ret
ToolPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				ToolEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_END_SELECT handler for ToolClass

CALLED BY:	UI

PASS:		*ds:si = Tool object
		ds:di = Tool instance
		cx, dx = location of mouse event
		bp high = UIFunctionsActive (for UIFA_CONSTRAIN bit)
		bp low = ButtonInfo
		
RETURN:		ax - mask MRF_PROCESSED

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolEndSelect	method dynamic	ToolClass,	MSG_META_END_SELECT

	.enter

	mov	ax, MSG_TOOL_FINISH_EDITING
	call	ObjCallInstanceNoLock

	mov	ax, mask MRF_PROCESSED
	.leave
	ret
ToolEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				ToolAfterCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TOOL_AFTER_CREATE handler for ToolClass
		Points object's vis linkage to the passed OD. This is
		used in creating the one-way upward visual linkage between
		the tool and the VisBitmap. Any other initialization stuff
		can go here as well.

CALLED BY:	

PASS:		^lcx:dx = OD of VisBitmap OR'd with LP_IS_PARENT to indicate
		parental linkage
		
CHANGES:	

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolAfterCreate	method dynamic	ToolClass, MSG_TOOL_AFTER_CREATE
	.enter

	movdw	ds:[di].TI_bitmap, cxdx

	.leave
	ret
ToolAfterCreate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolFinishEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TOOL_FINISH_EDITING handler for ToolClass
		This method is sent to the tool by the VisBitmap to get
		the tool to wrap up its edits and send in the changes.
		This is used in cases such as the text tool, where the
		initial moouse drag has nothing to do with when the changes
		have been made.

CALLED BY:	

PASS:		*ds:si = Tool object
		ds:di = Tool instance
		
RETURN:		nothing

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolFinishEditing	method dynamic	ToolClass, MSG_TOOL_FINISH_EDITING

	uses	cx
	.enter
	clr	cx
	xchg	cx, ds:[di].TI_editToken

	;
	;	Hand the changes gstate up to the VisBitmap
	;
	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_EDIT_FINISHED
	call	ToolCallBitmap

	;
	;  Release the mouse if we grabbed it
	;

	call	ToolReleaseMouse

	.leave
	ret
ToolFinishEditing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolFinishEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_TOOL_TEST_POINT_IN_BOUNDS handler for ToolClass

		Tests whether the passed point lies inside of the rectangle
		defined by the tool's TI_initial and TI_previous points

CALLED BY:	

PASS:		*ds:si = Tool object
		ds:di = Tool instance

		cx, dx - Point
		
RETURN:		carry set if point in bounds

DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolTestPointInBounds	method	ToolClass, MSG_TOOL_TEST_POINT_IN_BOUNDS
	mov	ax, ds:[di].TI_initialX
	mov	bx, ds:[di].TI_previousX
	cmp	ax, bx
	jle	gotX
	xchg	ax, bx
gotX:
	cmp	cx, ax
	jl	complementAndReturn
	cmp	bx, cx
	jl	complementAndReturn

	mov	ax, ds:[di].TI_initialY
	mov	bx, ds:[di].TI_previousY
	cmp	ax, bx
	jle	gotY
	xchg	ax, bx
gotY:
	cmp	dx, ax
	jl	complementAndReturn
	cmp	bx, dx
complementAndReturn:
	cmc
	ret
ToolTestPointInBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolEditBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets up a MSG_VIS_BITMAP_EDIT_BITMAP to the tool's bitmap

Pass:		*ds:si - Tool object

		es:di - fptr to callback graphics routine
		es:bp - fptr to callback graphics routine for bitmap mask
			(vfptr if XIP'ed)

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
ToolEditBitmap	proc	far
	class	ToolClass
	uses	ax, bp
	.enter

CheckHack <size VisBitmapEditBitmapParams eq (size word * 14)>

	pushdw	esbp			;mask callback
	pushdw	esdi			;normal callback
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
	
	mov	ax, MSG_VIS_BITMAP_EDIT_BITMAP
	call	ToolCallBitmap

	add	sp, size VisBitmapEditBitmapParams

	.leave
	ret
ToolEditBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolCallBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Utility routine for sending a message to the tool's bitmap

Pass:		*ds:si - tool
		ax - the message
		cx, dx, bp - params to the message

Return:		ax, cx, dx, bp, carry - return values from bitmap method

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolCallBitmap	proc	far
	class	ToolClass
	uses	bx, si
	.enter
	mov	si, ds:[si]
	mov	bx, ds:[si].TI_bitmap.handle
	mov	si, ds:[si].TI_bitmap.offset
	cmp	bx, ds:[LMBH_handle]
	jne	differentBlock

	call	ObjCallInstanceNoLock

done:
	.leave
	ret

differentBlock:
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	jmp	done

ToolCallBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolGrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Utility routine for grabbing the mouse for a tool.

Pass:		*ds:si - Tool

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolGrabMouse	proc	far
	uses	ax, bp
	.enter
	mov	bp, VBMMRT_GRAB_MOUSE
	mov	ax, MSG_VIS_BITMAP_MOUSE_MANAGER
	call	ToolCallBitmap
	.leave
	ret
ToolGrabMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolSendAllPtrEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Utility routine for sending all ptr events to the tool.

Pass:		*ds:si - Tool

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolSendAllPtrEvents	proc	far
	uses	ax, bp
	.enter
	mov	bp, VBMMRT_SEND_ALL_PTR_EVENTS
	mov	ax, MSG_VIS_BITMAP_MOUSE_MANAGER
	call	ToolCallBitmap
	.leave
	ret
ToolSendAllPtrEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ToolReleaseMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Tool utility routine to release the mouse grab

Pass:		*ds:si - Tool

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolReleaseMouse	proc	far
	uses	ax, bp
	.enter
	mov	bp, VBMMRT_RELEASE_MOUSE
	mov	ax, MSG_VIS_BITMAP_MOUSE_MANAGER
	call	ToolCallBitmap
	.leave
	ret
ToolReleaseMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the process that owns the block the body is in as
		busy. 

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolMarkBusy		proc	far
	uses	ax,cx,dx,bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication

	.leave
	ret
ToolMarkBusy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the process that owns the block the body is in as
		not busy. 

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolMarkNotBusy		proc	far
	uses	ax,cx,dx,bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	.leave
	ret
ToolMarkNotBusy		endp


BitmapToolCodeResource	ends			;end of tool code resource
