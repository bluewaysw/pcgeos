COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		vobj.asm

AUTHOR:		John Wedgwood, Jun 27, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 6/27/92	Initial revision

DESCRIPTION:
	Implementation of the VObj class

	$Id: vobj.asm,v 1.1 97/04/04 16:33:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
	VObjClass		; have to put the class definition somewhere...
idata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjShuffleColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shuffle the color to be something else.

CALLED BY:	via MSG_VOBJ_SHUFFLE_COLOR
PASS:		*ds:si	= Instance
		ds:di	= Instance
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjShuffleColor	method	dynamic VObjClass, MSG_VOBJ_SHUFFLE_COLOR
	;
	; Increment the color by taking the old color and adding one.
	; If the new value is too large (larger than the largest member of
	; the "Color" enumerated type) then we start again at zero.
	;
		mov	cl, ds:[di].VOI_color
		Assert	etype, cl, Color	; Make sure the color is valid

		inc	cl			; Move to next one

		cmp	cl, Color		; Check for in range
		jb	colorOK			; Branch if it is
		clr	cl			; Otherwise wrap to zero

colorOK:
	;
	; We now have the new color, so we save it back in our instance data
	;
		Assert	etype, cl, Color	; Make sure the color is valid
		mov	ds:[di].VOI_color, cl	; Save new color

	;
	; Force the object to redraw.
	;
		call	ForceVObjRedraw
		ret
VObjShuffleColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color of an objct.

CALLED BY:	via MSG_VOBJ_SET_COLOR
PASS:		*ds:si	= Instance
		ds:di	= Instance
		cl	= New color
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjSetColor	method	dynamic VObjClass, MSG_VOBJ_SET_COLOR
	;
	; Save the new color in our instance data and force the object to
	; redraw itself.
	;
		Assert	etype, cl, Color	; Make sure new color is valid

		mov	ds:[di].VOI_color, cl	; Save new color
		call	ForceVObjRedraw
		ret
VObjSetColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the type of the object.

CALLED BY:	via MSG_VOBJ_SET_TYPE
PASS:		*ds:si	= Instance
		ds:di	= Instance
		cx	= VObjType
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjSetType	method	dynamic VObjClass, MSG_VOBJ_SET_TYPE
	;
	; Save the new type into our instance data and then force a redraw
	;
		Assert	etype, cx, VObjType	; Make sure new type is valid

		mov	ds:[di].VOI_type, cx	; Save new type
		call	ForceVObjRedraw
		ret
VObjSetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceVObjRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force an object to redraw.

CALLED BY:	Utility
PASS:		*ds:si	= Instance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceVObjRedraw	proc	near
	;
	; Force a redraw by invalidating the area occupied by the object.
	;
		Assert	objectPtr, dssi, VObjClass

		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		ret
ForceVObjRedraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an object

CALLED BY:	via MSG_VIS_DRAW
PASS:		*ds:si	= Instance
		ds:di	= Instance
		bp	= GState to use
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjDraw	method	dynamic VObjClass, MSG_VIS_DRAW
	;
	; Make sure we got passed a valid gstate to use.
	;
		Assert	gstate, bp

	;
	; Set up registers in more useful places.
	;
		mov	si, di			; ds:si <- our instance data
		mov	di, bp			; di <- gstate to use

	;
	; Set the appropriate color
	;
		clr	ah			; ax <- color
		mov	al, ds:[si].VOI_color

		Assert	etype, al, Color	; Ensure the color is valid
		call	GrSetAreaColor		; Set the new color

	;
	; Load up the coordinates for drawing.
	;
		mov	ax, ds:[si].VI_bounds.R_left
		mov	bx, ds:[si].VI_bounds.R_top
		mov	cx, ds:[si].VI_bounds.R_right
		mov	dx, ds:[si].VI_bounds.R_bottom
	
	;
	; Call the handler appropriate for the tool-type
	;
		mov	bp, ds:[si].VOI_type
		Assert	etype, bp, VObjType	; Ensure the type is valid

	;
	; Call a handler, choosing it from a table that is indexed by the
	; record type.
	;
		call	cs:vobjDrawHandlerTable[bp]	; Call the handler

		ret

;
; List of handlers for each drawing tool.
;
vobjDrawHandlerTable	word	\
	offset	cs:DrawRectangleObject,		; VOT_RECTANGLE
	offset	cs:DrawEllipseObject		; VOT_ELLIPSE

VObjDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRectangleObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle object.

CALLED BY:	VObjDraw
PASS:		ax...dx	= Bounds to draw to
		di	= GState to draw with (color already set)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRectangleObject	proc	near
	;
	; Fill a rectangle...
	;
		Assert	gstate, di
		call	GrFillRect
		ret
DrawRectangleObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawEllipseObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an ellipse object.

CALLED BY:	VObjDraw
PASS:		ax...dx	= Bounds to draw to
		di	= GState to draw with (color already set)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawEllipseObject	proc	near
	;
	; Fill an ellipse
	;
		Assert	gstate, di
		call	GrFillEllipse
		ret
DrawEllipseObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the object.

CALLED BY:	via MSG_META_INITIALIZE
PASS:		*ds:si	= Instance
		ds:di	= Instance
		es	= Segment containing class
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjInitialize	method	dynamic VObjClass, MSG_META_INITIALIZE
	;
	; Our class is stored in dgroup.
	;
		Assert	dgroup, es

	;
	; Call superclass to do initialization.
	;
		mov	di, offset es:VObjClass
		call	ObjCallSuperNoLock
	
	;
	; Clear some bits so our object will come up in the way that the
	; system expects...
	;
	; Yeah, this is mystery-bits stuff.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
	
		and	ds:[di].VI_attrs, not mask VA_REALIZED
		and	ds:[di].VI_optFlags, not mask VOF_IMAGE_INVALID

	;
	; Make sure the flags are valid.
	;
		Assert	record, ds:[di].VI_attrs, VisAttrs
		Assert	record, ds:[di].VI_optFlags, VisOptFlags
		ret
VObjInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VObjStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start-select

CALLED BY:	via MSG_META_START_SELECT
PASS:		*ds:si	= Instance
		ds:di	= Instance
		cx	= X position of event
		dx	= Y position of event
RETURN:		ax	= mask MRF_PROCESSED, to signal that the mouse event
			  was handled.
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VObjStartSelect	method	dynamic VObjClass, MSG_META_START_SELECT
	;
	; Shuffle the color when we're clicked on
	;
		mov	ax, MSG_VOBJ_SHUFFLE_COLOR
		call	ObjCallInstanceNoLock
	
	;
	; Tell the caller that we handled this event
	;
		mov	ax, mask MRF_PROCESSED
		ret
VObjStartSelect	endm

CommonCode	ends


