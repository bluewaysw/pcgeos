COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		vobjContent.asm

AUTHOR:		John Wedgwood, Jun 27, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 6/27/92	Initial revision

DESCRIPTION:
	Implementation of VObjContent class.

	$Id: vobjContent.asm,v 1.1 97/04/04 16:33:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	;
	; There must be a class structure for every class you
	; intend to use somewhere in idata.
	;
idata	segment
	VObjContentClass
idata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjContentStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start-select in our content.

CALLED BY:	via MSG_META_START_SELECT
PASS:		*ds:si	= Instance
		ds:di	= Instance
		es	= dgroup (segment containing class)
RETURN:		ax	= MRF_PROCESSED if we shuffled the color, otherwise
			  whatever our superclass returns.
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjContentStartSelect	method	dynamic VObjContentClass, MSG_META_START_SELECT
	;
	; Check for working with the "shuffle-color" tool.
	;
		cmp	ds:[di].VOCI_tool, VCT_SHUFFLE_COLOR
		je	shuffleColor
	
	;
	; We aren't shuffling the color, so we must be creating something.
	;

	;
	; Signal that we are creating something
	;
		mov	ds:[di].VOCI_creating, 1

	;
	; Initialize the start position and last position
	;
		mov	ds:[di].VOCI_startPos.P_x, cx
		mov	ds:[di].VOCI_startPos.P_y, dx

		mov	ds:[di].VOCI_lastPos.P_x, cx
		mov	ds:[di].VOCI_lastPos.P_y, dx
	
	;
	; Draw something appropriate for the current tool.
	;
		call	DrawRubberBand

	;
	; Let the caller know that we've actually handled something
	;
		mov	ax, mask MRF_PROCESSED
quit:
	ret


shuffleColor:
	;
	; Let our superclass pass the 'start-select' on to whatever child is
	; under us (if any).
	;
		mov	di, offset es:VObjContentClass
		call	ObjCallSuperNoLock
		jmp	quit
VObjContentStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjContentPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle ptr events.

CALLED BY:	via MSG_META_PTR
PASS:		*ds:si	= Instance
		ds:di	= Instance
		es	= dgroup (segment containing class)
		cx	= X position of event
		dx	= Y position of event
RETURN:		ax	= MRF_PROCESSED
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjContentPtr	method	dynamic VObjContentClass, MSG_META_PTR
	;
	; Check to see if we are actually creating something.
	;
		tst	ds:[di].VOCI_creating
		jz	quit				; Branch if we're not

	;
	; Erase the old rubber band.
	;
		call	DrawRubberBand
	
	;
	; Set the new "last" position
	;
		mov	ds:[di].VOCI_lastPos.P_x, cx
		mov	ds:[di].VOCI_lastPos.P_y, dx

	;
	; Draw the new one
	;
		call	DrawRubberBand

quit:
	;
	; Tell the caller we handled the event
	;
		mov	ax, mask MRF_PROCESSED
		ret
VObjContentPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjContentEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an end-select.

CALLED BY:	via MSG_META_END_SELECT
PASS:		*ds:si	= Instance
		ds:di	= Instance
		es	= dgroup (segment containing class)
		cx	= X position of event
		dx	= Y position of event
RETURN:		ax	= MRF_PROCESSED
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjContentEndSelect	method	VObjContentClass, MSG_META_END_SELECT
	;
	; Check to see if we are actually creating something.
	;
		tst	ds:[di].VOCI_creating
		jz	quit			; Branch if we're not

	;
	; Erase the old rubber band.
	;
		call	DrawRubberBand
	
	;
	; Create the new object.
	;
		call	CreateObject

	;
	; Signal that we are no longer creating anything
	;
		Assert	objectPtr, dssi, VObjContentClass

		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		clr	ds:[di].VOCI_creating

quit:
	;
	; Let the caller know that we've actually handled something
	;
		mov	ax, mask MRF_PROCESSED
		ret
VObjContentEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRubberBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rubber-banding image suitable for the current tool.

CALLED BY:	VObjContentDragSelect, VObjContentPtr, VObjContentEndSelect
PASS:		ds:di	= Instance
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRubberBand	proc	near
	class	VObjContentClass
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	;
	; Make sure the pointer is valid.
	;
		Assert	fptr, dsdi

	;
	; Get the gstate to use.
	;
		mov	si, di			; ds:si <- our instance data
		call	CreateUsefulGState	; di <- gstate to use
		Assert	gstate, di

	;
	; Draw in that window
	;
		mov	al, MM_INVERT		; Invert the destination
		call	GrSetMixMode

	;
	; Load up the coordinates for drawing.
	;
		call	GetBounds		; ax...dx <- bounds of object
	
	;
	; Call the handler appropriate for the tool-type
	;
		mov	bp, ds:[si].VOCI_tool
		call	cs:rubberBandHandlerTable[bp]
	
	;
	; Nuke the gstate
	;
		call	GrDestroyState
		.leave
		ret

;
; List of handlers for each drawing tool.
;
rubberBandHandlerTable	word	\
	offset	cs:DrawRectangleRubberBand,	; VCT_RECTANGLE
	offset	cs:DrawEllipseRubberBand	; VCT_ELLIPSE

DrawRubberBand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRectangleRubberBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the rubber band for a rectangle.

CALLED BY:	DrawRubberBand
PASS:		ds:si	= Instance data
		di	= GState to use, MM_INVERT already set
		ax...dx	= Rectangle to draw into
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRectangleRubberBand	proc	near
		Assert	gstate, di
		call	GrDrawRect		; Draw the rubber-band
		ret
DrawRectangleRubberBand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawEllipseRubberBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the rubber band for an ellipse

CALLED BY:	DrawRubberBand
PASS:		ds:si	= Instance data
		di	= GState to use, MM_INVERT already set
		ax...dx	= Rectangle to draw into
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawEllipseRubberBand	proc	near
		Assert	gstate, di
		call	GrDrawEllipse
		ret
DrawEllipseRubberBand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an object of the correct type.

CALLED BY:	VObjContentEndSelect
PASS:		ds:di	= Instance
		es	= Class segment
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateObject	proc	near
	class	VObjContentClass
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	;
	; Ensure that our pointer is valid.
	;
		Assert	fptr, dsdi
		Assert	segment es

	;
	; Load up the coordinates for drawing.
	;
		push	si			; Save our chunk handle
		mov	si, di			; ds:si <- our instance data
		call	GetBounds		; ax...dx <- bounds of rectangle
	
	;
	; I extend the right and bottom bounds so that they account for the
	; fact that the frame extended below and to the right of these bounds.
	; This creates an object of the same size that the user saw on screen
	; while rubber-banding.
	;
		inc	cx
		inc	dx
	
	;
	; Create a new VObj object.
	;
		push	bx			; Save top, instance ptr
		mov	bx, ds:LMBH_handle	; bx <- block handle
		Assert	handle, bx
		mov	di, offset es:VObjClass	; es:di <- class pointer
		call	ObjInstantiate		; Create new VObj object
						; si <- chunk of new object
		pop	bx			; Restore top, instance ptr
		
		Assert	objectPtr, dssi, VObjClass

	;
	; Since ObjInstantiate allocates a chunk on the LMem heap which
	; contains our content object, the pointer we had in ds:di may
	; not be valid (if the chunks were moved around as part of allocating
	; the new object). We need to re-dereference the chunk handle to get
	; a pointer to the objects instance data so we can scarf stuff from
	; it.
	;
	; On the stack right now is our chunk handle (saved above).
	;
		pop	bp			; bp <- our chunk handle
		Assert	objectPtr, dsbp, VObjContentClass

		mov	di, ds:[bp]		; ds:di <- our instance data
		add	di, ds:[di].Vis_offset
	
	;
	; Set the bounds of the new object
	;
	; ax...dx= New bounds
	; ds:di	 = Pointer to VObjContent object
	; *ds:si = Instance ptr for new VObj object
	;
		sub	cx, ax			; cx <- width
		sub	dx, bx			; dx <- height

		push	cx, dx			; Save width, height

	;
	; Set the position
	;
		mov	cx, ax			; cx/dx <- left, top
		mov	dx, bx

		mov	ax, MSG_VIS_SET_POSITION; Set the position
		call	ObjCallInstanceNoLock
	
	;
	; Set the size
	;
		pop	cx, dx			; Restore width, height
		mov	ax, MSG_VIS_SET_SIZE	; Set the size
		call	ObjCallInstanceNoLock
	
	;
	; Set the color
	;
		clr	ch
		mov	cl, ds:[di].VOCI_color	; cx <- color
		Assert	etype, cl, Color
		mov	ax, MSG_VOBJ_SET_COLOR
		call	ObjCallInstanceNoLock
	
	;
	; Set the type
	;
		mov	bx, ds:[di].VOCI_tool
		mov	cx, cs:toolToTypeTable[bx]
		Assert	etype, cx, VObjType
		mov	ax, MSG_VOBJ_SET_TYPE
		call	ObjCallInstanceNoLock
	
	;
	; Add the object as a child of the content.
	;
		mov	cx, ds:LMBH_handle	; ^lcx:dx <- object to add
		mov	dx, si
		
		Assert	objectOD, cxdx, VObjClass, ds

		mov	bp, CCO_LAST		; This puts the object on top
	
		mov	si, offset VObjViewContent; *ds:si <- object to add to
		mov	ax, MSG_VIS_ADD_CHILD
		call	ObjCallInstanceNoLock	; Add the child
						; Nukes ax, bp
	;
	; The documentation for add-child says we *must* send a 
	; MSG_VIS_MARK_INVALID to the object so that it will get updated
	; correctly.
	;
		mov	si, dx			; si <- object to invalidate
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_WINDOW_INVALID
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

	;
	; Invalidate the area covered by the object so that it will redraw
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock	; Force it to redraw
		.leave
		ret

toolToTypeTable	word	\
	VOT_RECTANGLE,				; <- VCT_RECTANGLE
	VOT_ELLIPSE				; <- VCT_ELLIPSE
CreateObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateUsefulGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a useful gstate for drawing.

CALLED BY:	DrawRubberBand
PASS:		nothing
RETURN:		di	= GState to draw with
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateUsefulGState	proc	near
		uses	ax, bx, cx, dx, bp, si
		.enter
	;
	; send message to view requesting window handle
	;
		GetResourceHandleNS	VObjView, bx
		mov	si, offset VObjView		; *ds:si <- view
		mov	ax, MSG_GEN_VIEW_GET_WINDOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; cx <- window
		Assert	window, cx

		mov	di, cx				; di <- window
		call	GrCreateState			; di <- gstate
		.leave
		ret
CreateUsefulGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds for an object, ordering them correctly.

CALLED BY:	DrawRubberBand, CreateObject
PASS:		ds:si	= Instance
RETURN:		ax...dx	= Bounds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBounds	proc	near
		class	VObjContentClass
	
	;
	; Ensure that our pointer is valid
	;
		Assert	fptr, dssi
	
	;
	; Load them up...
	;
		mov	ax, ds:[si].VOCI_startPos.P_x	; ax <- start X
		mov	bx, ds:[si].VOCI_startPos.P_y	; bx <- start Y
		mov	cx, ds:[si].VOCI_lastPos.P_x	; cx <- end X
		mov	dx, ds:[si].VOCI_lastPos.P_y	; dx <- end Y
	
	;
	; Order them so ax<cx and bx<dx
	;
		cmp	ax, cx
		jle	xOK
		xchg	ax, cx
xOK:
	
		cmp	bx, dx
		jle	yOK
		xchg	bx, dx
yOK:
		ret
GetBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjContentSetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the tool for the content.

CALLED BY:	vis MSG_VOBJ_CONTENT_SET_TOOL
PASS:		*ds:si	= Instance
		ds:di	= Instance
		cx	= Tool
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjContentSetTool	method	VObjContentClass, MSG_VOBJ_CONTENT_SET_TOOL
		Assert	etype, cx, VObjContentTool
		mov	ds:[di].VOCI_tool, cx
		ret
VObjContentSetTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjContentSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color for the content

CALLED BY:	via MSG_VOBJ_CONTENT_SET_COLOR
PASS:		*ds:si	= Instance
		ds:di	= Instance
		cx	= Color
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjContentSetColor	method	VObjContentClass, MSG_VOBJ_CONTENT_SET_COLOR
		Assert	etype, cl, Color
		mov	ds:[di].VOCI_color, cl
		ret
VObjContentSetColor	endm

CommonCode	ends

