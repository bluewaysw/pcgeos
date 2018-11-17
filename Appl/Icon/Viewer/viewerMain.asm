COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Viewer
FILE:		viewerMain.asm

AUTHOR:		Steve Yegge, Jun 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT AddVisIcon		Adds a vis-icon to the database viewer

    INT ViewerHandleMoveCopy	Provide feedback during MSG_META_PTR

    INT ViewerDrawRubberBand	Draws an inverted rectangle

    INT SeeIfIconSelected	Asks a vis-icon if it's selected (utility
				routine)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/17/94		Initial revision

DESCRIPTION:

	

	$Id: viewerMain.asm,v 1.1 97/04/04 16:07:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ViewerCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerRescanDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes all children and rescans database.

CALLED BY:	MSG_DB_VIEWER_RESCAN_DATABASE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- remove any existing children
	- get the count of icons in the database
	- add that many children
	- redraw the window

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerRescanDatabase	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter

		clr	ds:[di].DBVI_numSelected
	;
	;  Remove any existing vis-icons.  (This also calls the title bar)
	;
		mov	ax, MSG_DB_VIEWER_INVALIDATE
		call	ObjCallInstanceNoLock
		
		push	ds:[LMBH_handle], si		; save block, chunk
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
	;
	;  For each database icon, add a child
	;
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetIconCount			; ax = count
		tst	ax
		jz	doneLoop			; don't add any children
		clr	cx				; cx = counter
iconLoop:
		call	AddVisIcon
		
		inc	cx
		cmp	cx, ax
		jl	iconLoop
doneLoop:
		pop	bx, si				; pop block, chunk
		call	MemDerefDS			; *ds:si = us

		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

		.leave
		ret
DBViewerRescanDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the handle of the viewer's database file.

CALLED BY:	MSG_DB_VIEWER_GET_DATABASE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		bp	= database file handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetDatabase	proc	far
		class	DBViewerClass
		
		mov	bp, ds:[di].GDI_fileHandle
		
		ret
DBViewerGetDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns GDI_display.

CALLED BY:	MSG_DB_VIEWER_GET_DISPLAY

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		bp	= display
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetDisplay	proc	far
		class	DBViewerClass
		
		mov	bp, ds:[di].GDI_display
		
		ret
DBViewerGetDisplay	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddVisIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a vis-icon to the database viewer

CALLED BY:	DBViewerRescanDatabase

PASS:		es = dgroup (segment of VisIconClass)
		*ds:si = DBViewer object
		cx = icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- instantiate a new VisIcon
	- add it to the vis tree
	- tell the child its number

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddVisIcon	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		push	cx				; save icon number
		push	si				; our chunk
		
		mov	bx, ds:[LMBH_handle]		; our block
		mov	di, offset es:VisIconClass
		call	ObjInstantiate			; si = new object
		mov	ax, si				; *ds:ax = vis-icon
		
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bp, CCO_LAST
		pop	si				; *ds:si = content
		
		push	ax				; save vis-icon chunk
		mov	ax, MSG_VIS_ADD_CHILD
		call	ObjCallInstanceNoLock
		
		pop	si				; *ds:si = vis-icon
		pop	cx				; restore icon number
		mov	ax, MSG_VIS_ICON_INITIALIZE
		call	ObjCallInstanceNoLock
		
		.leave
		ret
AddVisIcon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes all the vis-icon children.

CALLED BY:	MSG_DB_VIEWER_INVALIDATE

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- record a MSG_VIS_REMOVE classed event and send it to
	  each child
	- fix up ds to point to the same block as on entry
	- invalidate the trigger-bar

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerInvalidate	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
	;
	;  Send a destroy event to each child.
	;
		push	ds:[LMBH_handle], si
		GetResourceSegmentNS	VisIconClass, es
		mov	bx, es
		mov	si, offset	VisIconClass
		mov	di, mask MF_RECORD
		mov	ax, MSG_VIS_REMOVE
		mov	dl, VUM_NOW
		call	ObjMessage
		
		pop	bx, si
		call	MemDerefDS			; *ds:si = DBViewer
		mov	cx, di				; ^hcx = classed event
		mov	ax, MSG_VIS_SEND_TO_CHILDREN
		call	ObjCallInstanceNoLock
	;
	;  This is sort-of a hack. I added this to erase the dotted rectangle 
	;  around the current VisIcon. The dotted rectange sometimes does not
	;  get erased when the VisIcon is removed above because the dotted
	;  rectange is outside of the vis bounds of the VIsIcon. 
	;  -Tom Lester    14 Jan 94
	;
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	;  Update the appropriate triggers for no selections.
	;
		clr	cx				; no selections
		mov	ax, MSG_DB_VIEWER_ENABLE_UI
		call	ObjCallInstanceNoLock

		.leave
		ret
DBViewerInvalidate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds 1 VisIcon to the content

CALLED BY:	MSG_DB_VIEWER_ADD_CHILD

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		cx	= position of the new child
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- count the number of children
	- pass that number to the new icon (and add it)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerAddChild	proc	far
		class	DBViewerClass
		uses	ax, dx, bp
		.enter
		
		mov	ax, MSG_VIS_COUNT_CHILDREN	; returns in dx
		call	ObjCallInstanceNoLock
		
		mov	cx, dx				; child number
		call	AddVisIcon
		
		.leave
		ret
DBViewerAddChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts drawing a rubberband

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= x position
		dx	= y position
		bp.low	= ButtonInfo
		bp.high = UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if it's not the left mouse button, quit
	- set instance data for whether control & shift keys were down
	- send the coordinates to all the children and have them 
	  figure out whether they're selected or not

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerStartSelect	proc	far
		class	DBViewerClass
		uses	cx, dx, bp
		.enter
		
		test	bp, mask BI_B0_DOWN		; button 1?
		jz	done
	;
	;  Record the state of the control & shift keys.
	;
		mov	ax, bp
		mov	ds:[di].DBVI_flags, ah
	;
	;  If this is a double-click, send an edit-icon message to self.
	;
		test	al, mask BI_DOUBLE_PRESS
		jz	notDouble

		push	ax				; save flags
		mov	ax, MSG_DB_VIEWER_EDIT_ICON
		call	ObjCallInstanceNoLock
		pop	ax				; restore flags
notDouble:
	;
	;  Zero out the rubberband points (we're starting a new one).
	;
		mov	ds:[di].DBVI_buttonDown, 1	; true
		
		mov	ds:[di].DBVI_rubberBand.R_left, cx
		mov	ds:[di].DBVI_rubberBand.R_top, dx
		
		mov	ds:[di].DBVI_rubberBand.R_right, cx
		mov	ds:[di].DBVI_rubberBand.R_bottom, dx
		
		push	ax				; save flags
	;
	;  Find which child is selected by the mouse, if any.  Then
	;  broadcast to the children, telling them to deselect (or,
	;  for the child that was selected by the mouse, to select),
	;  and redraw.
	;
		mov	ax, MSG_VIS_ICON_GET_NUMBER
		call	VisCallChildUnderPoint		; returns in cx
		jc	foundOne
		
		mov	cx, -1				; no child will select
foundOne:
	;
	;  cx now has the child to select.  Do VisSendToChildren
	;
		pop	bp				; UIFunctionsActive
		mov	ax, MSG_VIS_ICON_SET_SELECTED_STATE
		call	VisSendToChildren
	;
	;  Update the rubberband.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		call	ViewerDrawRubberBand
	;
	;  Enable/disable the "Export to Token Database" dialog based
	;  on our selection (or lack thereof).
	;
		cmp	cx, -1
		je	noChild

		call	EnableExportTokenDBTrigger
		jmp	done
noChild:
		call	DisableExportTokenDBTrigger
done:
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
DBViewerStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a rubberband if buttonDown.

CALLED BY:	MSG_META_PTR

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= x position
		dx	= y position
		bp high = UIFunctionsActive

RETURN:		ax	= MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- handle quick-copy stuff
	- if mouse button's not down, bail
	- clear the old rubberband
	- store the new coordinates
	- draw the new rubberband

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerPtr	proc	far
		class	DBViewerClass
		uses	cx, dx, bp
		.enter
	;
	;  Check the quick-copy stuff.
	;
		call	ViewerHandleMoveCopy
	;
	;  Do the rubberbanding stuff.
	;
		tst	ds:[di].DBVI_buttonDown
		jz	done
		
		call	ViewerDrawRubberBand
		
		mov	ds:[di].DBVI_rubberBand.R_right, cx
		mov	ds:[di].DBVI_rubberBand.R_bottom, dx
		
		call	ViewerDrawRubberBand
done:
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
DBViewerPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerHandleMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide feedback during MSG_META_PTR

CALLED BY:	DBViewerPtr

PASS:		bp high = UIFunctionsActive

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/24/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerHandleMoveCopy	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  See if a quick-transfer is in progress.
	;
		call	ClipboardGetQuickTransferStatus
		jz	done		; quick-transfer not in progress
	;
	;  See if it's a format we can support.
	;
		mov	bp, mask CIF_QUICK
		call	ClipboardQueryItem

		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, CIF_ICON_LIST
		call	ClipboardTestItemFormat
		pushf
		call	ClipboardDoneWithItem
		popf
		jc	notSupported
	;
	;  We only support the copy operation.
	;
		mov	ax, CQTF_COPY
		jmp	doFeedback
notSupported:
	;
	;  We can't do it.
	;
		mov	ax, CQTF_CLEAR
doFeedback:
		call	ClipboardSetQuickTransferFeedback
done:
		.leave
		ret
ViewerHandleMoveCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops drawing rubberband, and selects icons.

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		bp high = UIFunctionsActive

RETURN:		ax	= MouseReturnFlags
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

	- if we're rubberbanding, draw the final rubberband.
	- clear the "buttonDown" bit
	- record a MSG_VIS_ICON_CHECK_IN_RECTANGLE classed event
		(we allocate extra space in the stack frame for
		 local variables in the callee's routines).
 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerEndSelect	proc	far
		class	DBViewerClass
		.enter
	;
	;  If the buttonDown flag isn't set, skip the rubberbanding
	;
		tst	ds:[di].DBVI_buttonDown
		jz	noRubberBand
		
		call	ViewerDrawRubberBand
noRubberBand:
		clr	ds:[di].DBVI_buttonDown
		
		push	ds:[LMBH_handle], si
	;
	;  Send a check-in-rectangle message to the children.
	;
		sub	sp, size CheckInRectangleStruct
		mov	bp, sp
		
		movdw	axbx, sidi			; save instance
		lea	si, ds:[di].DBVI_rubberBand	; ds:si = rubberband
		lea	di, ss:[bp].CIRS_rect
		mov	cx, size Rectangle
		rep	movsb
		movdw	sidi, axbx			; restore instance
		
		mov	al, ds:[di].DBVI_flags
		mov	ss:[bp].CIRS_flags, al
		
		mov	ax, MSG_VIS_ICON_CHECK_IN_RECTANGLE
		call	VisSendToChildren
		
		add	sp, size CheckInRectangleStruct
	;
	;  Update appropriate UI for the number of selections.
	;
		pop	bx, si
		call	MemDerefDS			; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		mov	cx, ds:[di].DBVI_numSelected
		
		mov	ax, MSG_DB_VIEWER_ENABLE_UI
		call	ObjCallInstanceNoLock
		
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
DBViewerEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stop rubberbanding

CALLED BY:	MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerLostGadgetExcl	proc	far
		class	DBViewerClass
		.enter

		clr	ds:[di].DBVI_buttonDown

		.leave
		mov	di, offset DBViewerClass
		GOTO	ObjCallSuperNoLock
DBViewerLostGadgetExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draws the rubberband (to prevent greebles)

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		^hbp	= gstate to draw through

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- let the superclass do its little thing
	- if the mouse button's not down, bail
	- draw the old rubberband (only in the invalidated part 
	  of the window)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerVisDraw	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter

		push	bp				; save gstate
		mov	di, offset DBViewerClass
		call	ObjCallSuperNoLock
		pop	bp				; restore gstate
	;
	;  Draw the rubberband if necessary
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].DBVI_buttonDown
		jz	done
	;
	;  Draw an inverted rectangle
	;
		xchg	di, bp
		
		mov	al, MM_INVERT
		call	GrSetMixMode
		
		mov	al, LS_DOTTED
		mov	bl, 1
		call	GrSetLineStyle
		
		mov	ax, ds:[bp].DBVI_rubberBand.R_left
		mov	bx, ds:[bp].DBVI_rubberBand.R_top
		mov	cx, ds:[bp].DBVI_rubberBand.R_right
		mov	dx, ds:[bp].DBVI_rubberBand.R_bottom
		
		call	GrDrawRect
done:
		.leave
		ret
DBViewerVisDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewerDrawRubberBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws an inverted rectangle

CALLED BY:	DBViewerStartSelect, etc

PASS:		ds:[di] = instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a gstate for drawing
	- draw an inverted rectangle using the stored
	  coordinates

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/9/92			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ViewerDrawRubberBand	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,di
		.enter
		
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		
		xchg	di, bp		; bp = instance data, di = gstate
	;
	;  Draw an inverted rectangle
	;
		mov	al, MM_INVERT
		call	GrSetMixMode
		
		mov	al, LS_DOTTED
		mov	bl, 1
		call	GrSetLineStyle
		
		mov	ax, ds:[bp].DBVI_rubberBand.R_left
		mov	bx, ds:[bp].DBVI_rubberBand.R_top
		mov	cx, ds:[bp].DBVI_rubberBand.R_right
		mov	dx, ds:[bp].DBVI_rubberBand.R_bottom
		
		call	GrDrawRect
		
		call	GrDestroyState
		
		.leave
		ret
ViewerDrawRubberBand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetChildSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the spacing for the children.

CALLED BY:	MSG_VIS_COMP_GET_CHILD_SPACING

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		cx 	= spacing between children
		dx	= spacing between lines of wrapping children

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return predefined constants for child spacing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetChildSpacing	proc	far
		class	DBViewerClass
		
		mov	cx, VIEWER_HORIZONTAL_CHILD_SPACING
		mov	dx, VIEWER_VERTICAL_CHILD_SPACING
		
		ret
DBViewerGetChildSpacing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the distance of the children from the edges.

CALLED BY:	MSG_VIS_COMP_GET_MARGINS

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		ax	= left margin
		bp	= top margin
		cx	= right margin
		dx	= bottom margin

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return predefined constants for margins

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetMargins	proc	far
		class	DBViewerClass
		
		mov	ax, VIEWER_MARGIN
		mov	bp, ax
		mov	cx, ax
		mov	dx, ax
		
		ret
DBViewerGetMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up some instance variables.

CALLED BY:	MSG_VIS_OPEN

PASS:		*ds:si	= DBViewerClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerVisOpen	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
	;
	;  Call the superclass
	;
		mov	di, offset DBViewerClass
		call	ObjCallSuperNoLock
	;
	;  Set up the instance data the way it was meant to be.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset		; get to vis stuff
		
		ornf	ds:[di].VCI_geoAttrs, mask VCGA_ALLOW_CHILDREN_TO_WRAP
		andnf	ds:[di].VCI_geoAttrs, not \
				(mask VCGA_CUSTOM_MANAGE_CHILDREN \
				or mask VCGA_ORIENT_CHILDREN_VERTICALLY)
		ornf	ds:[di].VCI_geoDimensionAttrs, \
				mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT or \
				mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
		ornf	ds:[di].VCNI_attrs, \
				mask VCNA_SAME_WIDTH_AS_VIEW or \
				mask VCNA_SAME_HEIGHT_AS_VIEW
		.leave
		ret
DBViewerVisOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSetSingleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects a VisIcon and deselects all the rest.

CALLED BY:	MSG_DB_VIEWER_SET_SINGLE_SELECTION

PASS:		*ds:si	= DBViewerClass object
		ds:si	= DBViewerInstance
		cx	= child number
		bp	= UIFunctionsActive (probably should be clear?)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- select one vis-icon and deselect the others
	- tell the title bar to redo its triggers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSetSingleSelection	  proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter

		mov	ax, MSG_VIS_ICON_SET_SELECTED_STATE
		call	VisSendToChildren
	;
	;  Enable the appropriate UI.
	;
		mov	cx, 1				; 1 selection
		mov	ax, MSG_DB_VIEWER_ENABLE_UI
		call	ObjCallInstanceNoLock

		.leave
		ret
DBViewerSetSingleSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Selects or deselects a child VisIcon.

CALLED BY:	MSG_DB_VIEWER_SET_SELECTION

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= child number
		dx	= nonzero if child is to be selected
			  zero if child is to be deselected

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- the icon will call us back if its state changed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSetSelection	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
		
		mov	di, dx				; save boolean
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		jc	notFound
		
		mov	bx, cx
		mov	si, dx				; ^lbx:si = VisIcon
		
		mov	dx, di				; nonzero if select
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_ICON_SET_SELECTION
		call	ObjMessage
notFound:
		.leave
		ret
DBViewerSetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetFirstSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the first (or only) selected VisIcon.

CALLED BY:	MSG_DB_VIEWER_GET_FIRST_SELECTION

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		cx	= selection (null if no selection)
		carry set if none selected

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- count the selected children
	- if none are selected, return carry set
	- if one is selected, return its position in cx
	- if more than one is selected, return the first


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetFirstSelection	proc	far
		class	DBViewerClass
		uses	ax, dx, bp
		.enter
	;
	;  Count the children & quit if there aren't any.
	;
		mov	ax, MSG_VIS_COUNT_CHILDREN
		call	ObjCallInstanceNoLock	; returns # in dx
		tst	dx
		jz	noSelection
		
		clr	cx			; counter
		clr	bp			; is-selected boolean
childLoop:
		push	cx, dx			; save counter, number
		
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock	; returns ^lcx:dx = child
		
		push	si			; save our chunk handle
		mov	bx, cx
		mov	si, dx			; ^lbx:si = VisIcon
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_ICON_GET_SELECTION
		call	ObjMessage
		
		pop	si			; restore our chunk handle
		pop	cx, dx			; restore counter & number
		
		tst	bp			; is-selected boolean
		jnz	foundSelection
		
		inc	cx
		cmp	cx, dx
		jl	childLoop
	;
	;  None was selected, apparently, so bail.
	;
		jmp	noSelection
foundSelection:
		clc
		jmp	done
noSelection:
		stc
done:
		.leave
		ret
DBViewerGetFirstSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetNumSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns number of selected icons

CALLED BY:	MSG_DB_VIEWER_GET_NUM_SELECTIONS

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		cx	= number of selected icons
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- return the number of selections from instance data

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetNumSelections	proc	far
		class	DBViewerClass
		
		mov	cx, ds:[di].DBVI_numSelected
		
		ret
DBViewerGetNumSelections	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerGetMultipleSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current list of selections.

CALLED BY:	MSG_DB_VIEWER_GET_MULTIPLE_SELECTIONS

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx:dx	= buffer into which to place the selections

RETURN:		cx:dx preserved, filled with the current selections
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- count the children
	- ask each one if it's selected
	- if so, add its number to the buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerGetMultipleSelections	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter
		
		push	cx, dx				; save buffer
		
		mov	ax, MSG_VIS_COUNT_CHILDREN
		call	ObjCallInstanceNoLock		; returns in dx
		
		pop	es, di				; es:di = buffer
		clr	cx				; counter
childLoop:
		call	SeeIfIconSelected		; cx = icon number
		jnc	skip
		
		mov	{word} es:[di], cx
		inc	di
		inc	di
skip:
		inc	cx
		cmp	cx, dx
		jl	childLoop
		
		mov	cx, es
		mov	dx, di				; cx:dx = buffer
		
		.leave
		ret
DBViewerGetMultipleSelections	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfIconSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asks a vis-icon if it's selected (utility routine)

CALLED BY:	DBViewerGetMultipleSelections

PASS:		*ds:si  = DBViewer object
		cx	= # of child to ask

RETURN:		carry set if selected, clear if not.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- find the requested child
	- ask it if it's selected and return

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeeIfIconSelected	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		
		movdw	bxsi, cxdx			; ^lbx:si = child
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_ICON_GET_SELECTION	; bp = 0 if not
		call	ObjMessage
		
		tst	bp
		jz	notSelected
		
		stc
		jmp	done
notSelected:
		clc
done:
		.leave
		ret
SeeIfIconSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerIconToggled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A VisIcon child changed state (selected or deselected)

CALLED BY:	MSG_DB_VIEWER_ICON_TOGGLED

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		cx	= nonzero if child is being selected
			  zero if child is being deselected

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- just update the numSelected instance datum to reflect the change

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerIconToggled	proc	far
		class	DBViewerClass
		
		jcxz	deselected
		
		inc	ds:[di].DBVI_numSelected
		jmp	done
deselected:
		dec	ds:[di].DBVI_numSelected
done:
		ret
DBViewerIconToggled	endp

ViewerCode	ends
