COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991, 1990 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		VisDoc
FILE:		visdoc.asm

AUTHOR:		Eric E. Del Sesto, June 20, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds     06/20/91        Initial revision (lifted lots of code
				    from Roger Flores' co-op trivia project)

DESCRIPTION:
	This file contains source code for the VisDoc application, which
	shows how VisClass objects can be used within a VisIsoContent,
	to represent the contents of a document page.

	This code will be assembled by ESP, and then linked by the GLUE
	linker to produce a runnable .geo application file.

IMPORTANT:
	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
	we have new ObjectAssembly and Object-C versions.

KNOWN BUGS:
	There are drawing glitches if two object overlap,
	or if you force a drag-scroll operation.

RCS STAMP:
	$Id: visdoc.asm,v 1.1 97/04/04 16:35:06 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------
;some of the include files contain conditional assembly, to (for example)
;prevent application code from calling certain system routines.


include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def

include Objects/winC.def
include Objects/inputC.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

DOCUMENT_WIDTH	= 8*72		;document width in points (8 inches)
DOCUMENT_HEIGHT	= 5*72		;document height in points (5 inches)

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "VisDocProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of this class
;will be created, and will handle all application-related events (messages).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

VisDocProcessClass	class	GenProcessClass

;define messages for this class here.

VisDocProcessClass	endc	;end of class definition

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.


;------------------------------------------------------------------------------
;			MyVisSquareClass Definitions
;------------------------------------------------------------------------------

;Here we define MyVisSquareClass, for the sake of the ESP assembler.
;This is necessary so that ESP can create a class definition structure for
;this class in our "idata" segment (see below).
;
;NOTE: in cases where you specify a class definition in both ESP and UIC,
;be sure that the definitions match, or your pre-instantiated objects
;that you list in your .ui file will not be built correctly.

MyVisSquareClass	class	VisClass

;instance data for this class

    MVS_graphicsState	hptr.GState	;when this object is being moved,
					;we store the GState to use when
					;drawing here.

    MVS_newXPosition	word	(?)	;this position information is updated
    MVS_newYPosition	word	(?)	;as the object is dragged on the page.

    MVS_xOffset		word	(?)	;When a drag operation begins, the
    MVS_yOffset		word	(?)	;offset from the mouse to the top-left
					;corner of the object is saved.

;methods defined for this class

MyVisSquareClass	endc

;This class definition must be stored in memory at runtime, so that
;the PC/GEOS messaging system can examine it. We will place it in this
;application's idata (initialized data) area, which is part of
;the "DGroup" resource.


;------------------------------------------------------------------------------
;			DGroup: idata and udata definitions
;------------------------------------------------------------------------------
;Now we place all of our initialized variables in the DGroup resource.
;The first data that we place into the idata section are the actual
;class definition structures that we defined above.

idata	segment

	VisDocProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects, which are
				;not part of the UI, and never saved
				;to the state file.

	MyVisSquareClass

;Note that we are not listing a method table here. See the
;VisDocExposed procedure for an example of how you can build
;a method table just by creating the associated method handlers.

idata	ends


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "visdoc.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;visdoc.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		visdoc.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for MyVisSquareClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	MyVisSquareDraw

DESCRIPTION:	This message is sent from the VisIsoContent object,
		as it is processing a MSG_META_EXPOSED which was sent from
		the GenView.

PASS:		*ds:si	= instance data for this object

		^hbp	= handle of GState to draw with (the GState structure
			  contains the handle of the window to draw into.)

		cl	= DrawFlags structure (see ui.def)

RETURN:		ds, si, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version

------------------------------------------------------------------------------@

MyVisSquareDraw	method	MyVisSquareClass, MSG_VIS_DRAW

	;first, let's make sure that the user is not dragging this object.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;set ds:di = Vis instance data
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	90$			;skip to end if not drawable...

	;set the color to BLUE

	push	bp
	mov	di, bp			;set ^hdi = GState
	mov	ah, CF_INDEX
	mov	al, C_LIGHT_BLUE
	call	GrSetAreaColor
	call	VisGetBounds		;returns (ax, bx) -> (cx, dx) = bounds
					;for this VisClass object.
	call	GrFillRect
	pop	bp

90$:
	ret
MyVisSquareDraw	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	MyVisSquareStartSelect -- MSG_META_START_SELECT handler.

DESCRIPTION:	This message is sent from the VisIsoContent object,
		as it is processing a MSG_META_START_SELECT which was sent from
		the GenView.

		This message means that the user has pressed the left mouse
		button, while the mouse was positioned over this object.

		This is the first stage of a select/move operation. As we
		don't yet know if this is really a move operation, we don't
		really start moving the object yet. See MyVisSquareDragSelect
		for more info.

PASS:		*ds:si	= instance data for this object
		cx, dx	= position of mouse, in document coordinates
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ds, si, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version

------------------------------------------------------------------------------@

MyVisSquareStartSelect	method	MyVisSquareClass, MSG_META_START_SELECT

	;First, we call a utility routine in the Generic UI library,
	;indicating that we want to be continually notified of mouse
	;events, even if the mouse leaves the GenView area.

	call	VisGrabMouse

	;as a well-behaved mouse event handler, we need to return
	;a MouseReturnFlags record in the AX register. This provides
	;information to our caller (the visible parent of this object)
	;about whether or not we handled this mouse event. In some cases,
	;we might ignore a mouse event, such that it could be passed
	;onwards to the next visible object in this family, which might
	;overlap this object.

	mov	ax, mask MRF_PROCESSED
	ret
MyVisSquareStartSelect	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	MyVisSquareDragSelect -- MSG_META_DRAG_SELECT handler.

DESCRIPTION:	This message is sent from the VisIsoContent object,
		which is passing it on from the GenView object.

		This message means that:
		
			a) the user has pressed the SELECT mouse button
			   on this object, and moved the mouse a
			   certain distance.
			   
			- or -

			b) the user has pressed the SELECT mouse button
			   on this object, and held that button down for a
			   certain length of time.

		If either of these conditions is true, then we initiate
		a drag operation.

PASS:		*ds:si	= instance data for this object
		cx, dx	= position of mouse, in document coordinates
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ds, si, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version

------------------------------------------------------------------------------@

MyVisSquareDragSelect	method	MyVisSquareClass, MSG_META_DRAG_SELECT

	;First, create a GState that we can use to draw this object with.
	;We do this by sending a "visible upward query" -- essentially
	;just a method which will travel up the visible tree structure
	;until it reaches the VisIsoContent object. Since the VisIsoContent
	;has the handle for the Window that this document is displayed in,
	;it can create a GState structure that we can draw this object with.

	mov	bx, ds:[LMBH_handle]	;get the block handle
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;returns ^hbp = GState
	tst	bp			;did it return a GState?
	jz	90$			;skip to end if not...

	;Store the handle of the GState in this object's instance data, so we
	;can use it to draw the object as it is moved. This also signifies
	;that we are in the drag mode.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;set ds:di = Vis instance data
	mov	ds:[di].MVS_graphicsState, bp

	;In case a MSG_VIS_DRAW arrives while we are moving, do not
	;attempt to draw the object.

	ANDNF	ds:[di].VI_attrs, not (mask VA_DRAWABLE)

	;calc and save the offset to the mouse position
	;This is needed so that when the furniture is let go, the furniture
	;isn't positioned with its top left corner where the mouse is.

	;Now, calculate the offset from the mouse pointer to the top-left
	;corner of this object. We will use this offset as we try to
	;draw an outline box which follows the mouse around the view area.

	mov	ax, cx
	sub	ax, ds:[di].VI_bounds.R_left	;sub the offset between
	mov	ds:[di].MVS_xOffset, ax		;mouse and rect.

	mov	ax, dx
	sub	ax, ds:[di].VI_bounds.R_top	;sub the offset between
	mov	ds:[di].MVS_yOffset, ax		;mouse and rect.

	;Save the "new" position of this object (which is the same as exactly
	;where it is, for now). If the user starts to move the mouse,
	;this info will change, and we will move the XOR rectangle with it.

	mov	ax, ds:[di].VI_bounds.R_left
	mov	ds:[di].MVS_newXPosition, ax

	mov	ax, ds:[di].VI_bounds.R_top
	mov	ds:[di].MVS_newYPosition, ax

	;now set up the GState so that we can draw an XOR rectangle

	xchg	di, bp			;set ^hdi  = GState
					;set ds:bp = Vis instance data

	mov	al, MM_INVERT		;XOR when drawing, rather than
	call	GrSetMixMode		;setting the pixels.

	mov	ax, 3			;set border line width
	call	GrSetLineWidth

	;now draw the outline at (newXPosition, newYPosition)

	call	MyVisSquareDrawOutline	;pass ds:bp = Vis instance data
	call	GrDestroyState

90$:	;Indicate that we have processed this event; no need to send it
	;on to any more Vis objects.

	mov	ax, mask MRF_PROCESSED
	ret
MyVisSquareDragSelect	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	MyVisSquareDrawOutline

DESCRIPTION:	This routine draws the outline box at the new position
		of this object.

PASS:		*ds:si	= instance data for this object
		ds:bp	= Vis instance data for this object
		di	= GState

RETURN:		ds, si, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version

------------------------------------------------------------------------------@

MyVisSquareDrawOutline	proc	near
	mov	ax, ds:[bp].MVS_newXPosition	;(ax, bx) = position, in
	mov	bx, ds:[bp].MVS_newYPosition	;document coordinates.

	call	VisGetSize			;(cx, dx) = size of object

	add	cx, ax				;convert to coordinates
	dec	cx
	add	dx, bx
	dec	dx
	call	GrDrawRect			;XOR-draw a rectangle
	ret
MyVisSquareDrawOutline	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MyVisSquarePtr -- MSG_META_PTR handler.

DESCRIPTION:	This message is sent from the VisIsoContent object,
		which is passing it on from the GenView object.

		This message is sent when the user moves the mouse.
		As long as the user is still pressing the SELECT button,
		we want to drag out outline box across the screen.

PASS:		*ds:si	= instance data for this object
		cx, dx	= position of mouse, in document coordinates
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ds, si, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version

------------------------------------------------------------------------------@

MyVisSquarePtr	method	MyVisSquareClass, MSG_META_PTR

	test	bp, mask BI_B0_DOWN	;is the SELECT operation pending?
	jz	90$			;skip to end if not...

	;If a pointer event occurs before the drag event, then we must exit.
	;This is because certain things (like the GState) must be setup.
	;If the GState is null then we haven't started dragging.

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	mov	di, ds:[bp].MVS_graphicsState	;^hdi = GState
	tst	di
	jz	90$			;skip to end if no GState yet...

	;erase the old outline, in the position where it was drawn

	push	cx, dx
	call	MyVisSquareDrawOutline
	pop	cx, dx

	;update the (newXPosition, newYPosition) coordinate pair, to 
	;reflect our new position.

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	sub	cx, ds:[bp].MVS_xOffset	;subtract the original mouse offset,
	sub	dx, ds:[bp].MVS_yOffset	;so that we get an accurate idea
					;of where this object should appear.

	mov	ds:[bp].MVS_newXPosition, cx
	mov	ds:[bp].MVS_newYPosition, dx

	;draw this object in its new position

	call	MyVisSquareDrawOutline

90$:	;Indicate that we have processed this event; no need to send it
	;on to any more Vis objects.

	mov	ax, mask MRF_PROCESSED
	ret
MyVisSquarePtr	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	MyVisSquareEndSelect -- MSG_META_END_SELECT handler

DESCRIPTION:	This message is sent from the VisIsoContent object,
		which is passing it on from the GenView object.

		This message is sent when the user releases the SELECT
		button on the mouse. We finish up our drag sequence
		by actually moving this object on the document, and forcing
		a redraw of this object.

PASS:		*ds:si	= instance data for this object
		cx, dx	= position of mouse, in document coordinates
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ds, si, bp = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/91		initial version

------------------------------------------------------------------------------@

MyVisSquareEndSelect	method	MyVisSquareClass, MSG_META_END_SELECT
	;If a pointer event occurs before the drag event, then we must exit.
	;This is because certain things (like the GState) must be setup.
	;If the GState is null then we haven't started dragging.

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	mov	di, ds:[bp].MVS_graphicsState	;^hdi = GState
	tst	di
	jz	90$			;skip to end if no GState yet...

	;erase the old outline, in the position where it was drawn

	push	cx, dx
	call	MyVisSquareDrawOutline

	;mark the object's original location as invalid, so that a
	;MSG_META_EXPOSED will be generated, and that portion of the document
	;washed with the background color for the document.

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	cx, dx

	;now use our saved offset to determine where exactly this object
	;should be positioned.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	sub	cx, ds:[di].MVS_xOffset
	sub	dx, ds:[di].MVS_yOffset

	;reposition the object at (cx, dx). This is actually just a short
	;routine in the Generic UI library. It just updates the instance
	;data for this object.

	call	VisSetPosition

	;indicate that this object can now be redrawn, next time a
	;MSG_DRAW is sent to it.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].VI_attrs, mask VA_DRAWABLE

	;mark the object's new location as invalid, so that a MSG_META_EXPOSED
	;will be generated, and a MSG_DRAW will be sent to this object.

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	;Indicate that we no longer need to hog all of the mouse events.

	call	VisReleaseMouse

	;free the GState that we allocated for this drag sequence.

	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset
	clr	di
	xchg	di, ds:[bp].MVS_graphicsState
	call	GrDestroyState

90$:	;Indicate that we have processed this event; no need to send it
	;on to any more Vis objects.

	mov	ax, mask MRF_PROCESSED
	ret
MyVisSquareEndSelect	endm

CommonCode	ends		;end of CommonCode resource
