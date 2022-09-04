COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainHWRGrid.asm

AUTHOR:		Andrew Wilson, Oct 12, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92	Initial revision
	dlitwin	4/12/94		Moved to SPUI from UI, renamed from
				uiHWRGrid.asm to cmainHWRGrid.asm
	IP	05/16/94	changed to handle new hwr api

DESCRIPTION:
	Contains code to implement the VisHWRGrid class

	$Id: cmainHWRGrid.asm,v 1.9 95/01/10 22:40:42 brianc Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not _GRAFFITI_UI)

CommonUIClassStructures segment resource

	VisHWRGridClass
	HWRGridContextTextClass

	method	VisObjectHandlesInkReply, VisHWRGridClass, 
					MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK
CommonUIClassStructures ends


udata	segment
	gestureBounds		Rectangle
	; holds the bounding rectangle for the current gesture

	savedContext		HWRContext<>
	; We save the position, etc of the grid to be used for the HWR context,
	; so we can use it in our gesture callback
udata	ends

HWRGridCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed message to the GenControl

CALLED BY:	GLOBAL
PASS:		*ds:si - vis object under GenControl
		ax, cx, dx, bp - message params
RETURN:		nada
DESTROYED:	ax, bx, cx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToControl	proc	near
	.enter
	push	si
	mov	bx, segment GenControlClass
	mov	si, offset GenControlClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di			;CX - classed event
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
SendToControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler registers the object to receive
		context updates when the focused text object changes.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridOpen	method	VisHWRGridClass, MSG_VIS_OPEN
	.enter
	mov	di, offset VisHWRGridClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisCachedGState_offset
	mov	ds:[di].VHGI_status, HWRS_VIEWING_TEXT

	mov	di, ds:[di].VCGSI_gstate
	call	SetupHWRGridGState

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	UserRegisterForTextContext

;	Record an event to get the context

	mov	cx, CL_CENTERED_AROUND_SELECTION_START
	call	GetContext

	.leave
	ret
VisHWRGridOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes a context notification to be generated

CALLED BY:	GLOBAL
PASS:		cx - ContextLocation
		dx.ax - position
		*ds:si - object under a controller
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContext	proc	near
	.enter
	push	si
	sub	sp, size GetContextParams
	mov	bp, sp
	mov	ss:[bp].GCP_numCharsToGet, MAX_CONTEXT_CHARS
	mov	ss:[bp].GCP_location, cx
	movdw	ss:[bp].GCP_position, dxax
	mov	dx, size GetContextParams
	mov	ax, MSG_META_GENERATE_CONTEXT_NOTIFICATION
	mov	di, mask MF_RECORD or mask MF_STACK
	clrdw	bxsi	
	call	ObjMessage
	add	sp, dx
	pop	si

;	Cause the controller to output this event.

	mov	bp, di
	mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
	call	SendToControl
	.leave
	ret
GetContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler unregisters the object so it no longer
		gets context updates when the focused text object changes.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridClose	method	VisHWRGridClass, MSG_VIS_CLOSE
	.enter
	mov	di, offset VisHWRGridClass
	call	ObjCallSuperNoLock
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	UserUnregisterForTextContext

;	Nuke any context block

	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	ds:[di].VHGI_status, HWRS_NOT_ON_SCREEN
	clr	bx
	clrdw	ds:[di].VHGI_object, bx
	xchg	ds:[di].VHGI_context, bx
	tst	bx
	jz	exit
	call	MemDecRefCount
exit:
	.leave
	ret
VisHWRGridClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfGestureCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed code is a gesture or not.

CALLED BY:	GLOBAL
PASS:		pass params on stack
RETURN:		ax - non-zero if is a gesture
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/18/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
CheckIfGestureCallback	proc	far	points:fptr,
					numPoints:word,
					numStrokes:word
	uses	es, bx, cx, di
	.enter
;	If this is not the first call to the gesture callback routine, just
;	exit, because if it wasn't a gesture before, it sure won't be one
;	now...
	clr	ax

	test	numStrokes,  mask GCF_FIRST_CALL
	jnz	cont
	
	cmp	numStrokes, 1
	jne	exit

cont:
	les	di, ss:[points]
	mov	cx, ss:[numPoints]
	call	StrokeEnum
	mov	ax, bx

exit:
	.leave
	ret

CheckIfGestureCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokeEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enumerate throught the strokes

CALLED BY:	CheckIfTextGesture
PASS:		es:di 	- ptr to buffer of points
		cx	- num points total
RETURN:		bx	- total number of points recognized as part of
			- a gesture
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
    while all strokes not checked
	while not the last point in a stroke 
		inc the number of points in this stroke
		goto the next point
	call routine to deal with this stroke and check to see if it
		is a gesture
	If it is not a gesture then quit
	If it is a gesture add the number of points in this stroke to
		the total of all points that are part of a stroke

    return the total of all points that were part of a stroke 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StrokeEnum	proc	near
	uses	ax,cx,dx,si,bp,ds
	.enter

	mov	si, di			
	sub	si, size Point
	clr	bx

loopStrokes:
	; set the initial bounds for this stroke
	; should eliminate this when HWRR_GET_GESTURE_BOUNDS is
	; implemented
	;
	LoadVarSeg ds, ax
	mov	ax, mask IXC_X_COORD
	and	ax, es:[di].P_x
	mov	ds:[gestureBounds].R_left, ax
	mov	ds:[gestureBounds].R_right, ax
	mov	ax, es:[di].P_y
	mov	ds:[gestureBounds].R_top, ax
	mov	ds:[gestureBounds].R_bottom, ax
		
	clr	dx		
loopPoints:
	jcxz	exit
	dec	cx
	inc	dx			; # of points in stroke
	add	si, size Point

	; this code is just to keep track of the bounds of this gesture it can
	; be eliminated when HWRR_GET_GESTURE_BOUNDS is added
	;
	mov	ax, mask IXC_X_COORD
	and	ax, es:[si].P_x
	cmp	ax, ds:[gestureBounds].R_left
	jg	cont1
	mov	ds:[gestureBounds].R_left, ax
cont1:
	cmp	ax, ds:[gestureBounds].R_right
	jl	cont2
	mov	ds:[gestureBounds].R_right, ax
cont2:
	mov	ax, es:[si].P_y
	cmp	ax, ds:[gestureBounds].R_top
	jg	cont3
	mov	ds:[gestureBounds].R_top, ax
cont3:
	cmp	ax, ds:[gestureBounds].R_bottom
	jl	cont4
	mov	ds:[gestureBounds].R_bottom, ax
cont4:


	mov	ax, mask IXC_TERMINATE_STROKE
	and	ax, es:[si].P_x
	jz	loopPoints
endLoopPoints::
	;
	; found end of stroke, call function
	;
	push	bx, cx, dx
	mov	cx, dx
	call	CheckIfGesture
	pop	bx, cx, dx
	;
	; if this stroke is not a gesture then leave
	;
	tst	ax
	jz	endLoopStrokes

	add	bx, dx			; bx += num points in this
					; stroke 
	mov	di, si
	jmp 	loopStrokes

endLoopStrokes:
exit:
	.leave
	ret

StrokeEnum	endp

PrintMessage<IAN: remove when HWRR_GET_GESTURE_BOUNDS implemented in hwr>
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGestureBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a handle to the bounds of the Rectangle.
		should be eliminated when HWRR_GET_GESTURE_BOUNDS is
		implemented. 

CALLED BY:	(PRIVATE) HandleGesture...
PASS:		nothing
RETURN:		cx 	= handle to new rectangle
DESTROYED:	si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGestureBounds	proc	near
	uses	ax,bx,di,ds,es
	.enter
	mov	si, offset gestureBounds

	mov	ax, size GestureHeader
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	mov	es, ax
	clr	di
	
	LoadVarSeg	ds, ax
	;
	; copy the rectangle from the rectangle gestureBounds stored
	; in the dgroup... To our allocated rectangle
	;
	mov	cx, size Rectangle
	shr	cx, 1
	rep	movsw

	call	MemUnlock
	mov	cx, bx
	
	.leave
	ret
GetGestureBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed ink is any sort of gesture.

CALLED BY:	GLOBAL
PASS:		es:di - ptr to stroke
		cx - # points
RETURN:		carry set if gesture (AX = GestureType)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfGesture	proc	near	uses	bx, cx, dx, bp, di, si, es
	numPoints	local	word	push	cx	
	libHandle	local	hptr		;Used by CallHWRLibrary macro
	points		local	fptr
	.enter

	movdw	points, esdi
	call	UserGetHWRLibraryHandle
	tst	ax				;Exit if no HWR library
	LONG jz	error
	mov	libHandle, ax

	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax
	jnz 	error				;If error, exit

	CallHWRLibrary	HWRR_RESET

;	Send the ink points to the HWR recognizer

	push	numPoints
	pushdw	points
	CallHWRLibrary	HWRR_ADD_POINTS

	CallHWRLibrary	HWRR_DO_GESTURE_RECOGNITION
	;Returns AX = GestureType
	;Returns dx = extra gesture info

	cmp	ax, GT_NO_GESTURE
	jz	cont
	push	ax

; 	can not do this until the library supports it
;	CallHWRLibrary	HWRR_GET_GESTURE_BOUNDS
;	mov	cx, ax

	pop	ax
cont:
	push	ax, dx
	CallHWRLibrary	HWRR_END_INTERACTION
	pop	ax, dx
	
	cmp	ax, GT_NO_GESTURE
	jnz	isGesture
error:
	clc
exit:
	.leave
	ret

isGesture:
	mov	bx, ax
	push	ax
EC <	cmp	bx, GestureType				>
EC <	ERROR_A	ERROR_HWR_GRID_INVALID_GESTURE		>
	shl	bx, 1			; index into our nptr table
	call	cs:[handleGestureTable][bx]
	stc
	pop	ax
	jmp	exit

CheckIfGesture	endp

;
; these procedures can destroy the following registers:
; ax, bx, cx, dx, si, di
;
handleGestureTable	nptr	\
	HandleGestureNull,		; GT_NO_GESTURE
	HandleGestureDelete,		; GT_DELETE_CHARS
	HandleGestureNull,		; GT_SELECT_CHARS
	HandleGestureDelete,		; GT_V_CROSSOUT
	HandleGestureDelete,		; GT_H_CROSSOUT
	HandleGestureNull,		; GT_BACKSPACE
	HandleGestureChar,		; GT_CHAR
	HandleGestureAbort,		; GT_STRING_MACRO
	HandleGestureNull,		; GT_IGNORE_GESTURE
	HandleGestureNull,		; GT_COPY
	HandleGestureNull,		; GT_PASTE
	HandleGestureNull,		; GT_CUT
	HandleGestureModeChar,		; GT_MODE_CHAR
	HandleGestureReplaceLastChar	; GT_REPLACE_LAST_CHAR

.assert( (length handleGestureTable) eq GestureType )


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place holder for gesture handlers not yet implemented

CALLED BY:	
PASS:		nothing
RETURN:
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureNull	proc	near
	.enter
	.leave
	ret
HandleGestureNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AbortHWRMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort HWR macro in progress

CALLED BY:	(PRIVATE)
PASS:		nothing
RETURN:		ax	= handle to string macro if cleanup is
			neccessary
		dx	= non zero if need to clean up a mode char

DESTROYED:	bx, cx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AbortHWRMacro	proc	near
libHandle	local	hptr
	.enter
	call	UserGetHWRLibraryHandle
	tst	ax
	jz	exit
	mov	ss:[libHandle], ax

	CallHWRLibrary	HWRR_BEGIN_INTERACTION
	tst	ax
	jnz 	exit				;If error, exit

	CallHWRLibrary	HWRR_RESET_MACRO
	
	push	ax, dx
	CallHWRLibrary	HWRR_END_INTERACTION	
	pop	ax, dx
exit:
	.leave
	ret
AbortHWRMacro	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This will delete a mode char in the text object, if
		the user entered a mode char, and then a gesture that
		we do not deal with.

CALLED BY:	(PRIVATE)CheckIfGesture
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureAbort	proc	near
	.enter
	call	AbortHWRMacro
	.leave
	ret	
HandleGestureAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends delete gesture to the flow object

CALLED BY:	(PRIVATE)CheckIfGesture
PASS:		cx - handle to Rectangle which is the bounds of the
			delete gesture
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	sends MSG_META_NOTIFY_WITH_DATA_BLOCK, notification type
	GWNT_INK_GESTURE to the flow object, which should bring it back
	to this object.  The message is sent with the following data

	GestureHeader	type	GT_DELETE_CHARS
			Rectangle - contains the bounds of the delete gesture

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureDelete	proc	near
	uses	bp
	.enter
	call	GetGestureBounds
	mov	si, cx			;si - handle to bounds
					;Rectangle
	mov	ax, size GestureHeader
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	jc	exit
	mov	es, ax
	mov	es:[GH_gestureType], GT_DELETE_CHARS
	
	call	SendGesture		
exit:
	.leave
	ret
HandleGestureDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends GT_CHAR gesture to the flow object

CALLED BY:	(PRIVATE)CheckIfGesture
PASS:		dx - character recognized
		cx - handle of bounds of char
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
	MSG_META_NOTIFY_WITH_DATA_BLOCK, notification type
	GWNT_INK_GESTURE to the flow object, which should bring it back
	to this object.  The message is sent with the following data
	
	GestureHeader	type		GT_CHAR
			Rectangle	bounds of gesture
			data		{word}character
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureChar	proc	near
	uses	bp, es
	.enter
	call	GetGestureBounds
	mov	si, cx	
	
	mov	ax, size GestureHeader + size word
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	jc	exit
	mov	es, ax
	mov	es:[GH_gestureType], GT_CHAR
	;
	; put the character to be returned in the gesture struct
	;
	mov	es:[GH_data], dx
	call 	SendGesture
exit:
	.leave
	ret
HandleGestureChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureModeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send GT_MODE_CHAR to the flow object

CALLED BY:	(PRIVATE)CheckIfGesture
PASS:		dx - character recognized
RETURN:		cx - handle of bounds of char
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureModeChar	proc	near
	uses 	bp
	.enter
	call	GetGestureBounds
	mov	si, cx	
	
	mov	ax, size GestureHeader + size word
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	jc	exit
	mov	es, ax
	mov	es:[GH_gestureType], GT_MODE_CHAR
	;
	; put the character to be returned in the gesture struct
	;
	mov	es:[GH_data], dx
	call 	SendGesture
exit:
	.leave
	ret
HandleGestureModeChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleGestureReplaceLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send GT_REPLACE_LAST_CHAR to the flow object

CALLED BY:	(PRIVATE)CheckIfGesture
PASS:		dx - character recognized
RETURN:		cx - handle of bounds of char
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleGestureReplaceLastChar	proc	near
	uses 	bp
	.enter
	call	GetGestureBounds
	mov	si, cx	
	
	mov	ax, size GestureHeader + size word
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc
	jc	exit
	mov	es, ax
	mov	es:[GH_gestureType], GT_REPLACE_LAST_CHAR
	;
	; put the character to be returned in the gesture struct
	;
	mov	es:[GH_data], dx
	call 	SendGesture
exit:
	.leave
	ret
HandleGestureReplaceLastChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send GWNT_INK_GESTURE to the flow object, including
		the bounds.

CALLED BY:	(PRIVATE)HandleGestureChar, HandleGestureDelete 
PASS:		bx	= handle to GestureHeader
		si	= handle to Rectangle which is the bounds of
			this gesture., this will be freed.
		es:0	= ptr to Gesture Header
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di	
SIDE EFFECTS:	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendGesture	proc	near
	.enter
	push	bx
	tst 	si
	jz	noRectangle

	mov	bx, si			; lock the bounds Rectangle
	call	MemLock
	mov	ds, ax			; ds:si ptr to bounds rectangle
	clr	si

	mov	di, offset GH_rectangle

	CheckHack <((((size Rectangle)/2)*2) eq (size Rectangle))>
	mov	cx, (size Rectangle)/2
	rep 	movsw

	call	MemFree			; Free the original Rectangle
noRectangle:
	
	pop	bx			; GestureHeader
	call	MemUnlock

	mov	ax, 1
	call 	MemInitRefCount
	
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK_GESTURE
	mov	bp, bx
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	UserCallFlow

	.leave
	ret
SendGesture	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HWRGridContextTextQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just passes this to the VisHWRGrid object.

CALLED BY:	GLOBAL
PASS:		ax, cx, dx, bp - method args
RETURN:		whatever from VisHWRGridQueryIfPressIsInk
DESTROYED:	whatever from VisHWRGridQueryIfPressIsInk
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HWRGridContextTextQueryIfPressIsInk	method	HWRGridContextTextClass,
					MSG_META_QUERY_IF_PRESS_IS_INK
	mov	si, offset HWRGridObj
	FALL_THRU	VisHWRGridQueryIfPressIsInk
HWRGridContextTextQueryIfPressIsInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler informs the system that all presses in
		the bounds of this object should be ink.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridQueryIfPressIsInk	method	VisHWRGridClass, 
				MSG_META_QUERY_IF_PRESS_IS_INK

;	Save the context here, so we can use it in the gesture
;	callback routine 

	LoadVarSeg es, di
	mov	di, offset savedContext
	call	FillInHWRContext

	clr	bp			;No GState
	clr	ax			;Use default brush size
	mov	cx, ds:[LMBH_handle]	;Set destination for the ink
	mov	dx, si

	mov	bx, vseg CheckIfGestureCallback
	mov	di, offset CheckIfGestureCallback
	call	UserCreateInkDestinationInfo
	mov	ax, IRV_DESIRES_INK
	tst	bp
	jnz	exit
	mov	ax, IRV_NO_INK
exit:
	ret
VisHWRGridQueryIfPressIsInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the data for the HWR grid.

CALLED BY:	GLOBAL
PASS:		bp - gstate
		cl - draw flags
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridDraw	method	VisHWRGridClass, MSG_VIS_DRAW
	.enter
	mov	di, bp			;DI <- GState
	call	SetupHWRGridGState
	call	UpdateHWRDisplay
	.leave
	ret
VisHWRGridDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupHWRGridGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a gstate for drawing.

CALLED BY:	GLOBAL
PASS:		di - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupHWRGridGState	proc	near
	.enter

	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor

	mov	cx, HWR_FONT
	mov	dx, HWR_POINT_SIZE
	clr	ah
	call	GrSetFont

	mov	al, SDM_100
	call	CheckIfFullyEnabled
	jnz	setMask
	mov	al, SDM_50
setMask:
	call	GrSetLineMask
	call	GrSetAreaMask
	call	GrSetTextMask

	.leave
	ret
SetupHWRGridGState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateHWRDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws the HWR display.

CALLED BY:	GLOBAL
PASS:		di - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateHWRDisplay	proc	near	uses	cx
	.enter

;	Draw the grid areas.
	
	clr	cx
loopTop:

	call	DrawHWRBox
	inc	cx
	cmp	cx, NUM_HWR_BOXES
	jne	loopTop
	.leave
	ret
UpdateHWRDisplay	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapCharAndDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a character, after mapping invisible characters.

CALLED BY:	GLOBAL
PASS:		same as GrDrawChar
		(dx = char to draw)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapCharAndDraw	proc	near
	.enter
	cmp	dx, C_SECTION_BREAK
	jz	sectionBreak
	cmp	dx, C_PAGE_BREAK
	jz	pageBreak
	cmp	dx, C_TAB
	jz	tab
	cmp	dx, C_ENTER
	jz	isEnter
	cmp	dx, C_GRAPHIC
	jz	graphic
drawChar:
	call	GrDrawChar
	.leave
	ret


pageBreak:
SBCS <	mov	dx, C_SECTION						>
DBCS <	mov	dx, C_SECTION_SIGN					>
	jmp	drawChar
sectionBreak:
SBCS <	mov	dx, C_SECTION						>
DBCS <	mov	dx, C_SECTION_SIGN					>
	jmp	drawChar
graphic:
SBCS <	mov	dx, C_CURRENCY						>
DBCS <	mov	dx, C_CURRENCY_SIGN					>
	jmp	drawChar
isEnter:
SBCS <	mov	dx, C_PARAGRAPH						>
DBCS <	mov	dx, C_PARAGRAPH_SIGN					>
	jmp	drawChar
tab:
SBCS <	mov	dx, C_LOGICAL_NOT					>
DBCS <	mov	dx, C_NOT_SIGN						>
	jmp	drawChar

MapCharAndDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHWRBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws an HWR box.

CALLED BY:	GLOBAL
PASS:		di - gstate to draw through
		cx - index of box to draw
		*ds:si - VisHWRGridClass
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHWRBox	proc	near	uses	ax, bx, cx, dx, si
	class	VisHWRGridClass
	gridLeft	local	word
	.enter		

EC <	cmp	cx, NUM_HWR_BOXES					>
EC <	ERROR_AE	-1						>

	push	cx

;	Draw white boxes, starting at HWR_GRID_HORIZONTAL_MARGIN+1, each
;	HWR_GRID_WIDTH wide
;	

IKBD <	LoadVarSeg es, ax						>
IKBD <	mov	ax, es:[hwrGridWidth]					>
NOTIKBD<mov	ax, KEYBOARD_HWR_GRID_WIDTH				>
	mul	cl
IKBD <	add	ax, es:[hwrGridHorizontalMargin]			>
IKBD <	inc	ax							>
NOTIKBD<add	ax, KEYBOARD_HWR_GRID_HORIZONTAL_MARGIN+1		>

	mov	cx, ax
IKBD <	add	cx, es:[hwrGridWidth]					>
IKBD <	dec	cx							>
NOTIKBD<add	cx, KEYBOARD_HWR_GRID_WIDTH-1				>

IKBD <	mov	bx, es:[hwrGridVerticalMargin]				>
NOTIKBD<mov	bx, KEYBOARD_HWR_GRID_VERTICAL_MARGIN			>

IKBD <	mov	dx, es:[hwrGridVerticalMargin]				>
IKBD <	add	dx, es:[hwrGridHeight]					>
NOTIKBD<mov	dx, KEYBOARD_HWR_GRID_VERTICAL_MARGIN+KEYBOARD_HWR_GRID_HEIGHT>
	call	GrFillRect

	dec	ax
	dec	bx
	mov	gridLeft, ax
	call	GrDrawRect
	pop	cx				;CX <- index of box we are 
						; drawing

;	Draw whatever character belongs there
	
	mov	si, ds:[si]
	add	si, ds:[si].VisHWRGrid_offset
	mov	bx, ds:[si].VHGI_context
	tst	bx				;Branch if no context block
	LONG jz	tooBig
	call	MemLock
	mov	es, ax				;ES <- block of context data

	movdw	dxax, ds:[si].VHGI_position
	add	ax, cx
	adc	dx, 0				;DX.AX <- index of position to
						; draw
	cmpdw	dxax, es:[CD_numChars]		;Branch if it is beyond the end
	LONG 	jae	tooBig			; of the text

EC <	cmpdw	dxax, es:[CD_range].VTR_end				>
EC <	ERROR_AE	CONTROLLER_OBJECT_INTERNAL_ERROR		>

	subdw	dxax, es:[CD_range].VTR_start
EC <	tst	dx							>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>

;	Draw the character centered in the grid (we get the height of the
;	font box, and the width of the character, and do the appropriate
;	manipulations to determine where to draw the critter)

	push	bx
	mov_tr	bx, ax
	add	bx, offset CD_contextData
	mov	cl, es:[bx]			;CX <- char to draw
	clr	ch

	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			;DX <- height of font box
IKBD <	LoadVarSeg es, ax						>
IKBD <	mov	bx, es:[hwrGridHeight]					>
NOTIKBD<mov	bx, KEYBOARD_HWR_GRID_HEIGHT				>
	sub	bx, dx
EC <	ERROR_C		CONTROLLER_OBJECT_INTERNAL_ERROR		>
	shr	bx				;BX <- Y position
IKBD <	add	bx, es:[hwrGridVerticalMargin]				>
NOTIKBD<add	bx, KEYBOARD_HWR_GRID_VERTICAL_MARGIN			>
	mov	ax, cx
	call	GrCharWidth			;DX <- width of char
IKBD <	mov	ax, es:[hwrGridWidth]					>
NOTIKBD<mov	ax, KEYBOARD_HWR_GRID_WIDTH				>
	sub	ax, dx			
	shr	ax				;AX <- X position
	add	ax, gridLeft
	mov	dx, cx				;DX <- char to draw
	call	MapCharAndDraw
	pop	bx

doUnlock:
	call	MemUnlock
exit:

	.leave
	ret
tooBig:
	call	GrSaveState
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	mov	al, SDM_12_5
	call	GrSetAreaMask

	push	bx
IKBD <	LoadVarSeg es, ax						>
IKBD <	mov	bx, es:[hwrGridVerticalMargin]				>
NOTIKBD<mov	bx, KEYBOARD_HWR_GRID_VERTICAL_MARGIN			>

IKBD <	mov	dx, bx							>
IKBD <	add	dx, es:[hwrGridHeight]					>
NOTIKBD<mov	dx, KEYBOARD_HWR_GRID_VERTICAL_MARGIN+KEYBOARD_HWR_GRID_HEIGHT>
	mov	ax, gridLeft
	mov	cx, ax
IKBD <	add	cx, es:[hwrGridWidth]					>
NOTIKBD<add	cx, KEYBOARD_HWR_GRID_WIDTH				>
	call	GrFillRect
	pop	bx

	call	GrRestoreState
	tst	bx
	jnz	doUnlock
	jmp	exit

DrawHWRBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallContextTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Sends a message to the HWRContext object

CALLED BY:	GLOBAL
PASS:		ds - obj block containing the HWRContext object
		ax, cx, dx, bp - args for ObjCallInstanceNoLock
RETURN:		ax, cx, dx, bp - return from ObjCallInstanceNoLock
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallContextTextObject	proc	near	uses	si
	.enter
	mov	si, offset HWRContextObj
	call	ObjCallInstanceNoLock
	.leave
	ret
CallContextTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendEllipsis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends an ellipsis char to the passed text object

CALLED BY:	GLOBAL
PASS:		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendEllipsis	proc	near	uses	ax, cx, dx, bp
	.enter
SBCS <	mov	ax, C_ELLIPSIS						>
DBCS <	mov	ax, C_HORIZONTAL_ELLIPSIS				>
	push	ax
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	cx, 1		;CX <- 
	mov	dx, ss
	mov	bp, sp		;DX:BP <- ptr to ellipsis char
	call	CallContextTextObject
	add	sp, size word
	.leave
	ret
AppendEllipsis	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetermineRangeOfTextToDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines what range of the original text object we should
		be displaying - a range centered as much as possible around
		the visible range.

CALLED BY:	GLOBAL
PASS:		es - segment of ContextData
		*ds:si - VisHWRGridClass
RETURN:		dx.ax, cx.bx <- range to display
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw     10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetermineRangeOfTextToDisplay	proc	near	uses	di
	class	VisHWRGridClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	movdw	cxbx, ds:[di].VHGI_position

;	We want to get a range centered around the currently visible text,
;	unless there aren't enough characters available (i.e. the position
;	is close to the start/end of the text, in which case we'll get as
;	large of an area as possible).

	add	bx, (MAX_CHARS_IN_CONTEXT_OBJECT-NUM_HWR_BOXES)/2 + NUM_HWR_BOXES
	adc	cx, 0
	cmpdw	cxbx, es:[CD_numChars]
	jbe	10$
	movdw	cxbx, es:[CD_numChars]
10$:

;	We have a end range that is centered around the position (or
;	else is at the end of the text). Subtract the # chars we can
;	show, to get the start range

	movdw	dxax, cxbx
	subdw	dxax, MAX_CHARS_IN_CONTEXT_OBJECT
	jnc	exit

;	The start of the range is before the beginning of the text, so
;	adjust the range to start at the beginning and extend as far
;	as possible.

	clrdw	dxax
	movdw	cxbx, MAX_CHARS_IN_CONTEXT_OBJECT
	cmpdw	cxbx, es:[CD_numChars]
	jbe	exit
	movdw	cxbx, es:[CD_numChars]
exit:
	.leave
	ret
DetermineRangeOfTextToDisplay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendTextToContextTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds this text to the context object, after stripping out
		any weird characters.

CALLED BY:	GLOBAL
PASS:		es:di - text string
		cx - # chars
RETURN:		nada
DESTROYED:	ax, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendTextToContextTextObject	proc	near
	.enter
	jcxz	exit
	sub	sp, cx
	mov	ax, sp
	push	cx, es, ds, si
	segmov	ds, es
	mov	si, di
	segmov	es, ss
	mov	di, ax
	push	di
top:
	lodsb
	cmp	al, C_SPACE
	jae	justAdd
	mov	al, C_SPACE
justAdd:
	stosb
	loop	top
	pop	bp
	mov	dx, es			;DX.BP <- ptr to string
	pop	cx, es, ds, si
	push	cx
	mov	ax, MSG_VIS_TEXT_APPEND
	call	CallContextTextObject
	pop	cx
	add	sp, cx
exit:
	.leave
	ret
AppendTextToContextTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetContextText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the context text object to contain the appropriate text

CALLED BY:	GLOBAL
PASS:		*ds:si - VisHWRGridClass object
		bx - block of context data
		dx.ax - position of first char being displayed on screen.
RETURN:		dx.ax, cx.bx - range of text being displayed
DESTROYED:	es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetContextText	proc	near	uses	bp
	.enter
	push	bx
	call	MemLock
	mov	es, ax

;	Determine what range of the context we will display, and replace
;	the text in the HWRContextObj object with this range. Then, underline
;	the portion that is visible.

	call	DetermineRangeOfTextToDisplay	;Returns DX.AX, CX.BX 
						; ranges of text to display
						; 

	push	ax, cx, dx					
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	CallContextTextObject
	pop	ax, cx, dx
	tstdw	dxax
	jz	atStart
	call	AppendEllipsis
atStart:

	push	ax, bx, cx, dx
	subdw	cxbx, dxax			;BX <- # chars to add
EC < 	tst	cx							>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>
	subdw	dxax, es:[CD_range].VTR_start
EC <	tst	dx							>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>
	mov_tr	di, ax
	add	di, offset CD_contextData
	mov	cx, bx			;CX <- # chars to add
	call	AppendTextToContextTextObject
	pop	ax, bx, cx, dx
	
	cmpdw	cxbx, es:[CD_numChars]
	jz	atEnd
	call	AppendEllipsis
atEnd:
	mov	bp, bx
	pop	bx
	call	MemUnlock
	mov	bx, bp
	.leave
	ret
SetContextText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighlightVisibleChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Highlights the characters in the context object that are
		visible in the HWR Grid area

CALLED BY:	GLOBAL
PASS:		*ds:si - VisHWRGridClass
		dx.ax, cx.bx - range of text in the context area
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighlightVisibleChars	proc	near
	class	VisHWRGridClass
	params	local	VisTextSetTextStyleParams
	start	local	dword
	.enter
	movdw	start, dxax

;	Nuke all of the old style stuff

	clr	di
	clrdw	params.VTSTSP_range.VTR_start, di
	movdw	params.VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	params.VTSTSP_styleBitsToSet, di
	mov	params.VTSTSP_styleBitsToClear, mask TextStyle
	mov	params.VTSTSP_extendedBitsToSet, di
	mov	params.VTSTSP_extendedBitsToClear, mask VisTextExtendedStyles
	call	SetStyle

	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	movdw	dxax, ds:[di].VHGI_position
	subdw	dxax, start
	subdw	cxbx, start
	movdw	params.VTSTSP_range.VTR_start, dxax
	add	ax, NUM_HWR_BOXES
	adc	dx, 0
	cmpdw	dxax, cxbx
	jbe	doReplace
	movdw	dxax, cxbx
doReplace:
	movdw	params.VTSTSP_range.VTR_end, dxax

;	Adjust the range for any ellipsis that we may have added

	tstdw	start
	jz	atStart
	incdw	params.VTSTSP_range.VTR_start
	incdw	params.VTSTSP_range.VTR_end
atStart:
EC <	tst	dx							>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>

	mov	params.VTSTSP_styleBitsToSet, mask TS_UNDERLINE
	mov	params.VTSTSP_styleBitsToClear, dx
	mov	params.VTSTSP_extendedBitsToSet, dx
	mov	params.VTSTSP_extendedBitsToClear, dx
	call	SetStyle
	.leave
	ret
SetStyle:
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	mov	dx, size params
	lea	bp, params
	call	CallContextTextObject
	pop	ax, cx, dx, bp
	retn
HighlightVisibleChars	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateContextArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the context area.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateContextArea	proc	near
	class	VisHWRGridClass
	.enter
	mov	ax, MSG_META_SUSPEND
	call	CallContextTextObject
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	bx, ds:[di].VHGI_context
	movdw	dxax, ds:[di].VHGI_position	
	call	SetContextText
	call	HighlightVisibleChars
	mov	ax, MSG_META_UNSUSPEND
	call	CallContextTextObject
	.leave
	ret
UpdateContextArea	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjCallInstanceNoLock_SaveAXCXDXBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save as ObjCallInstanceNoLock, but saves registers

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		ax, cx, dx, bp - args for ObjCallInstanceNoLock
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjCallInstanceNoLock_SaveAXCXDXBP	proc	near	uses	ax, cx, dx, bp
	.enter
	call	ObjCallInstanceNoLock
	.leave
	ret
ObjCallInstanceNoLock_SaveAXCXDXBP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableDisableScrollTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable and disable the scroll tools

CALLED BY:	GLOBAL
PASS:		*ds:si - VisHWRGrid object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisableScrollTools	proc	near	uses	ax, bx, dx, di, si, es
	class	VisHWRGridClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	ax, MSG_GEN_SET_ENABLED
	tstdw	ds:[di].VHGI_position
	jnz	notAtStart
	mov	ax, MSG_GEN_SET_NOT_ENABLED
notAtStart:
	push	si
	mov	si, offset HWRStartTrigger
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock_SaveAXCXDXBP
	mov	si, offset HWRFastBackTrigger
	call	ObjCallInstanceNoLock_SaveAXCXDXBP
	mov	si, offset HWRBackTrigger
	call	ObjCallInstanceNoLock_SaveAXCXDXBP
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	bx, ds:[di].VHGI_context
	tst	bx
	jz	disable
	call	MemLock
	mov	es, ax
	movdw	dxax, ds:[di].VHGI_position
	incdw	dxax
	cmpdw	dxax, es:[CD_numChars]
	call	MemUnlock
	mov	ax, MSG_GEN_SET_ENABLED
	jb	notAtEnd
disable:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
notAtEnd:
	mov	si, offset HWRForwardTrigger
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock_SaveAXCXDXBP
	mov	si, offset HWRFastForwardTrigger
	call	ObjCallInstanceNoLock_SaveAXCXDXBP
	mov	si, offset HWREndTrigger
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock_SaveAXCXDXBP
	.leave
	ret
EnableDisableScrollTools	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNewContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws the screen with the new context

CALLED BY:	GLOBAL
PASS:		bx - new context
		*ds:si - VisHWRGrid object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNewContext	proc	near	uses	ax, bx, cx, dx, bp, di, es
	class	VisHWRGridClass
	.enter

;	If a UserDoDialog is on screen, then the text objects will send their
;	context notifications directly to us (not via the process queue),
;	as the process could be blocked.
;
;	This has the problem that we could get notifications out-of-sequence
;	(the process thread could send us bogus context updates), so if a 
;	UserDoDialog is onscreen, we ignore context updates from all text
;	objects that aren't run by the app's UI thread.
;
	call	MemLock
	mov	es, ax

	mov	ax, MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG
	call	UserCallApplication
	tst	ax
	jz	noDialogUp

	push	bx
	mov	bx, es:[CD_object].handle
	call	ObjTestIfObjBlockRunByCurThread
	pop	bx			;Ignore all context updates from 
	jz	noDialogUp		; objects run from other threads
					; while a UserDoDialog is onscreen.
	call	MemUnlock
	call	MemDecRefCount
	jmp	exit


noDialogUp:
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	xchg	ds:[di].VHGI_context, bx
	tst	bx
	jz	10$
	call	MemDecRefCount
10$:
	mov	bx, ds:[di].VHGI_context

;	If the object is the same as the old object, and we are waiting
;	for the result of HWR, then redraw the text at the same position
;	that we already had (after making sure it is in bounds). Otherwise,
;	draw starting at the beginning of the selection.

	cmp	ds:[di].VHGI_status, HWRS_WAITING_FOR_CONTEXT_UPDATE
	jz	waitingForContext
displaySelection:
	movdw	ds:[di].VHGI_position, es:[CD_selection].VTR_start, ax
	cmpdw	es:[CD_selection].VTR_start, es:[CD_selection].VTR_end, ax
	jnz	unlock

;	We just have a cursor - put the cursor in the middle of the
;	box.

	subdw	ds:[di].VHGI_position, (NUM_HWR_BOXES/2)
	jnc	unlock
	clrdw	ds:[di].VHGI_position
unlock:
	movdw	ds:[di].VHGI_object, es:[CD_object], ax
	mov	ds:[di].VHGI_status, HWRS_VIEWING_TEXT
	call	MemUnlock

	mov	di, ds:[di].VCGSI_gstate
	call	SetupHWRGridGState
	call	UpdateHWRDisplay

	call	UpdateContextArea
	call	EnableDisableScrollTools
exit:
	.leave
	ret
waitingForContext:

;	If this is a context notification from the object we are waiting on,
;	use our old position, after ensuring it is in range.

	cmpdw	ds:[di].VHGI_object, es:[CD_object], ax
	jne	displaySelection
	cmpdw	ds:[di].VHGI_position, es:[CD_numChars], ax
	jb	unlock
	movdw	dxax, es:[CD_numChars]
	tstdw	dxax
	jz	noDec
	decdw	dxax
noDec:
	movdw	ds:[di].VHGI_position, dxax
	jmp	unlock
	

HandleNewContext	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPositionToCharOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an offset from the left edge of the
		HWR area into a character offset

CALLED BY:	GLOBAL
PASS:		ax - offset from left edge of HWR area
		*ds:si - object
RETURN:		dx.ax - char position
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPositionToCharOffset	proc	near	uses	di, cx, es
	class	VisHWRGridClass
	.enter

	tst	ax
	js	negVal

IKBD <	LoadVarSeg es, cx						>
IKBD <	mov	cl, {byte} es:[hwrGridWidth]				>
NOTIKBD<mov	cl, KEYBOARD_HWR_GRID_WIDTH				>
	div	cl
	cmp	al, NUM_HWR_BOXES
	jbe	10$
	mov	al, NUM_HWR_BOXES
10$:
	clr	ah
	clr	dx			;DX.AX <- char offset from start of
					; grid.
exit:
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	adddw	dxax, ds:[di].VHGI_position
	.leave
	ret
negVal:
	clrdw	dxax
	jmp	exit
ConvertPositionToCharOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfInserting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if in insert mode.

CALLED BY:	GLOBAL
PASS:		ds - obj block with HWRInsertList
RETURN:		carry set if in insert mode
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfInserting	proc	near	uses	ax, cx, dx, bp, si
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset HWRInsertList
	call	ObjCallInstanceNoLock	;Returns AX=0 if Insert not selected
	tst_clc	ax
	jnz	notInsert
	stc
notInsert:
	.leave
	ret
CheckIfInserting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInHWRContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills in the HWRContext for the object

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		es:di - HWRContext structure to fill in
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInHWRContext	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter
	mov	es:[di].HWRC_grid.HWRGD_mode, HM_GRID
IKBD < 	push 	es							>
IKBD < 	LoadVarSeg	es, ax						>
IKBD <	mov	ax, es:[hwrGridWidth]					>
IKBD <	dec	ax							>
IKBD <	pop	es							>
IKBD <	mov	es:[di].HWRC_grid.HWRGD_xOffset, ax			>
NOTIKBD<mov	es:[di].HWRC_grid.HWRGD_xOffset, KEYBOARD_HWR_GRID_WIDTH - 1>

IKBD < 	push 	es							>
IKBD < 	LoadVarSeg	es, ax						>
IKBD <	mov	ax, es:[hwrGridHeight]					>
IKBD < 	pop 	es							>
IKBD <	mov	es:[di].HWRC_grid.HWRGD_yOffset, ax			>
NOTIKBD<mov	es:[di].HWRC_grid.HWRGD_yOffset, KEYBOARD_HWR_GRID_HEIGHT >

	mov	bp, di			;ES:BP <- HWRContext structure
	call	VisQueryWindow
EC <	tst	di							>
EC <	ERROR_Z	CONTROLLER_OBJECT_INTERNAL_ERROR			>


	call	VisGetBounds
IKBD < 	push 	es							>
IKBD < 	LoadVarSeg	es, cx						>
IKBD <	add	ax, es:[hwrGridHorizontalMargin]			>
IKBD <	add	bx, es:[hwrGridVerticalMargin]				>
IKBD < 	pop 	es							>
NOTIKBD<add	ax, KEYBOARD_HWR_GRID_HORIZONTAL_MARGIN			>
NOTIKBD<add	bx, KEYBOARD_HWR_GRID_VERTICAL_MARGIN			>

	mov	cx, ax
	mov	dx, bx
	call	WinTransform
	mov	es:[bp].HWRC_grid.HWRGD_bounds.R_left, ax
	mov	es:[bp].HWRC_grid.HWRGD_bounds.R_top, bx
	mov	ax, cx
	mov	bx, dx


;	AX <- left offset + (HWR_GRID_WIDTH-1) * NUM_HWR_BOXES

IKBD < 	push 	es							>
IKBD < 	LoadVarSeg	es, dx						>
IKBD <	mov	dx, es:[hwrGridWidth]					>
.assert NUM_HWR_BOXES eq 7
IKBD <	shl	dx, 1							>
IKBD <	shl	dx, 1							>
IKBD <	shl	dx, 1							>
IKBD <  sub	dx, es:[hwrGridWidth]					>
IKBD <	sub	dx, NUM_HWR_BOXES					>
IKBD <	add	ax, dx							>
IKBD <	add	bx, es:[hwrGridHeight]					>
IKBD < 	pop 	es							>
NOTIKBD<add	ax, (KEYBOARD_HWR_GRID_WIDTH-1) * NUM_HWR_BOXES		>
NOTIKBD<add	bx, KEYBOARD_HWR_GRID_HEIGHT				>


	call	WinTransform
	mov	es:[bp].HWRC_grid.HWRGD_bounds.R_right, ax
	mov	es:[bp].HWRC_grid.HWRGD_bounds.R_bottom, bx
	.leave
	ret
FillInHWRContext	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInReplaceWithHWRData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the "ReplaceWithHWRData" structure

CALLED BY:	GLOBAL
PASS:	        es:0 - InkHeader
		es:di - ptr to ReplaceWithHWRData
		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInReplaceWithHWRData	proc	near	uses	ax, bx, cx, dx, bp, di
	class	VisHWRGridClass
	.enter
	mov	bp, di
	add	di, offset RWHWRD_context
	call	FillInHWRContext

;	Figure out what "range" of characters the text corresponds to
;	Note, this does not work for scaled/rotated views, as we assume
;	that the width of each grid box is HWR_GRID_WIDTH, not some scaled
;	version of same.

;	
;	This "FUDGE_FACTOR" code looks like a hack, but it isn't. Basically,
;	what we are trying to do is allow the user to write his characters
;	so that they slightly overlap the cells to either side of the cells
;	he is trying to overwrite. We force the ink to be at least
;	HWR_GRID_FUDGE_FACTOR pixels into a cell before we decide that the
;	user is trying to overwrite the cell.
;
	mov	ax, es:[IH_bounds].R_left
	add	ax, HWR_GRID_FUDGE_FACTOR
	sub	ax, es:[bp].RWHWRD_context.HWRC_grid.HWRGD_bounds.R_left

;	AX = left bound of ink in relation to left edge of object

	call	ConvertPositionToCharOffset
	movdw	es:[bp].RWHWRD_range.VTR_start, dxax

	call	CheckIfInserting
	jc	setEnd				;Branch if inserting

	mov	ax, es:[IH_bounds].R_right
	sub	ax, es:[bp].RWHWRD_context.HWRC_grid.HWRGD_bounds.R_left
	sub	ax, HWR_GRID_FUDGE_FACTOR	;See comment above

;	AX = right bound of ink in relation to left edge of object

	call	ConvertPositionToCharOffset
	incdw	dxax

;
;	If the range is beyond the end of the text, just make it be *equal*
;	to the end of the text (or the start of the replace range,
;	whichever is greater).
;

	push	es
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	bx, ds:[di].VHGI_context
	push	ax
	call	MemLock
	mov	es, ax
	pop	ax
	cmpdw	dxax, es:[CD_numChars]
	jbe	beforeEndOfText
	movdw	dxax, es:[CD_numChars]
beforeEndOfText:
	call	MemUnlock
	pop	es
	cmpdw	dxax, es:[bp].RWHWRD_range.VTR_start
	jae	setEnd
	movdw	dxax, es:[bp].RWHWRD_range.VTR_start
setEnd:
	movdw	es:[bp].RWHWRD_range.VTR_end, dxax

;	Make sure start is not after end
;
EC <	cmpdw	es:[bp].RWHWRD_range.VTR_start, dxax			>
EC <	ERROR_A	CONTROLLER_OBJECT_INTERNAL_ERROR			>


	.leave
	ret
FillInReplaceWithHWRData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendInkReplaceNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends off an ink replace notification.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		es - dgroup
		bx - handle of ink data
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendInkReplaceNotification	proc	near	uses	ax, bx, cx, dx, bp, di, si, es
	class	VisHWRGridClass
	.enter

;	Resize the ink block to be large enough to hold a ReplaceWithHWRData
;	struct at the end.

	call	MemLock
	mov	es, ax
	mov	di, offset IH_data		;ES:DI <- ptr to points

	mov	ax, es:[IH_count]
.assert	size InkPoint	eq	4
	shl	ax
	shl	ax
	add	ax, size InkHeader
	mov	di, ax			;ES:DI <- ptr to end of ink data
	add	ax, size ReplaceWithHWRData
	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc
	LONG jc	memError

	mov	es, ax			;ES:DI <- ptr to ReplaceWithHWRData

	call	FillInReplaceWithHWRData

	call	MemUnlock

;	Record an event and send it off to the output of the control...

	push	si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_TEXT_REPLACE_WITH_HWR
	mov	bp, bx
	mov	di, mask MF_RECORD
	clrdw	bxsi
	call	ObjMessage
	pop	si

sendEventToOutput:
	mov	bp, di		;BP <- action to send to the output
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	ds:[di].VHGI_status, HWRS_WAITING_FOR_CONTEXT_UPDATE
	push	bp
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	GenCallApplication
	pop	bp

	mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
	call	SendToControl

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserSendToApplicationViaProcess
exit:
	.leave
	ret
memError:
	call	MemUnlock
	call	MemDecRefCount
	jmp	exit

SendInkReplaceNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls the appropriate gesture function to deal with
		the gesture recieved
CALLED BY:	
PASS:		bp - handle to gesture information block
		*ds:si - VisHWRGrid object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertGesture	proc	near
	uses	ax, bx, cx, dx, si, di, bp, es
	.enter
	mov	bx, bp
	cmp	dx, GWNT_INK_GESTURE
	jne	exit

	call	MemLock	
	jc	exit
	mov	es, ax
	mov	dx,es:[GH_gestureType]
	call	MemUnlock
	mov	ax, bx
	mov	bx, dx
EC <	cmp	bx, GestureType			>
EC <	ERROR_A	ERROR_HWR_GRID_INVALID_GESTURE	>
	shl	bx, 1			; index into our nptr table
	mov	dx, bp
	call	cs:[gestureTable][bx]
exit:
	.leave
	ret
InsertGesture	endp

gestureTable	nptr	\
		GestureNull,		; GT_NO_GESTURE
		GestureDelete,		; GT_DELETE_CHARS
		GestureNull,		; GT_SELECT_CHARS
		GestureNull,		; GT_V_CROSSOUT
		GestureNull,		; GT_H_CROSSOUT
		GestureBackspace,	; GT_BACKSPACE
		GestureChar,		; GT_CHAR
		GestureNull,		; GT_STRING_MACRO
		GestureNull,		; GT_IGNORE_GESTURE
		GestureNull,		; GT_COPY
		GestureNull,		; GT_PASTE
		GestureNull,		; GT_CUT
		GestureChar,		; GT_MODE_CHAR
		GestureChar		; GT_REPLACE_LAST_CHAR

.assert	( (length gestureTable) eq GestureType )


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a placeholder routine until the various gesture
		handlers can be written.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureNull	proc	near
	ret
GestureNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureBackspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the VistText object to perform
		VTKF_DELETE_BACKWARD_CHAR 

CALLED BY:	InsertGesture
PASS:		dx - handle to GestureHeader
		*ds:si - VisHWRGrid object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	calculate the range of characters to be replaced
	send a message to replace those characters to the ouput of the
	control 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureBackspace	proc	near
	.enter

	push	si
	mov	cx, VTKF_DELETE_BACKWARD_CHAR
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	di, mask MF_RECORD or mask MF_STACK
	mov	dx, size VisTextRange
	clrdw	bxsi
	call	ObjMessage
	pop	si

sendEventToOutput::
	mov	bp, di		;BP <- action to send to the output
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	ds:[di].VHGI_status, HWRS_WAITING_FOR_CONTEXT_UPDATE
	push	bp
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	GenCallApplication
	pop	bp

	mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
	call	SendToControl

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserSendToApplicationViaProcess
exit:
	.leave
	ret

GestureBackspace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts a char into the HWR grid and send it off to
		the GenControl.  Used for gesture type GT_CHAR,
		GT_MODE_CHAR, GT_REPLACE_LAST_CHAR

CALLED BY:	InsertGesture
PASS:		dx - handle to GestureHeader
		*ds:si - VisHWRGrid object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	calculate the range of characters to be replaced
	send a message to replace those characters to the ouput of the
		control 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureChar	proc	near
context		local	HWRContext
gestureType	local	GestureType
	uses	bp,ds
	.enter

	call	ECCheckStack

	segmov	es, ss
	lea	di, ss:[context]
	call	FillInHWRContext

	mov	bx, dx
	call	MemLock
	mov	es, ax
	mov	dx, es:[GH_rectangle].R_left	;cx <- left bound of
						;gesture
	mov	di, es:[GH_gestureType]		
	mov	ss:[gestureType], di
	mov	di, es:[GH_data]		;si <- char

	call	MemUnlock

	mov	ax, size ReplaceWithGestureData
	inc	ax			; make room for word of data
	inc	ax
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE	
	call	MemAlloc				
	mov	es, ax			; es <- pointer to
					; ReplaceWithGTCharData
	mov	es:[RWGD_data], di	; save the character
	mov	di, ss:[gestureType]
	mov	es:[RWGD_gestureType], di
	;
	; calculate the vistext range
	;
	mov	ax, dx
	add	ax, HWR_GRID_FUDGE_FACTOR
	sub	ax, ss:[context].HWRC_grid.HWRGD_bounds.R_left
	;
	call	ConvertPositionToCharOffset
	movdw	es:[RWGD_range].VTR_start, dxax

	call	CheckIfInserting
	jc	setEnd				;Branch if inserting
	incdw	dxax
;
;	If the range is beyond the end of the text, just make it be *equal*
;	to the end of the text (or the start of the replace range,
;	whichever is greater).
;
	push	es, bx
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	bx, ds:[di].VHGI_context
	push	ax
	call	MemLock
	mov	es, ax
	pop	ax
	cmpdw	dxax, es:[CD_numChars]
	jbe	beforeEndOfText
	movdw	dxax, es:[CD_numChars]
beforeEndOfText:
	pop 	es, bx
	cmpdw	dxax, es:[RWGD_range].VTR_start
	jae	setEnd
	movdw	dxax, es:[RWGD_range].VTR_start

setEnd:
	movdw	es:[RWGD_range].VTR_end, dxax
	call	MemUnlock			; unlock the block to send

;	Make sure start is not after end
;
EC <	cmpdw	es:[RWGD_range].VTR_start, dxax			>
EC <	ERROR_A	CONTROLLER_OBJECT_INTERNAL_ERROR			>
	
	call	SendReplaceChar

	.leave
	ret
GestureChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendReplaceChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the a message to the gencontrol to replace the
		character
CALLED BY:	GestureChar
PASS:		bx - handle to GestureHeader
		*ds:si - VisHWRGrid object
RETURN:		
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendReplaceChar	proc	near
	uses	bp
	.enter

;	Record an event and send it off to the output of the control...

	mov	ax, 1
	call	MemInitRefCount
	
	push	si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_TEXT_REPLACE_GESTURE
	mov	bp, bx
	mov	di, mask MF_RECORD
	clrdw	bxsi
	call	ObjMessage
	pop	si

	mov	bp, di		;BP <- action to send to the output
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	ds:[di].VHGI_status, HWRS_WAITING_FOR_CONTEXT_UPDATE
	push	bp
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	GenCallApplication
	pop	bp

	mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
	call	SendToControl

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserSendToApplicationViaProcess

	.leave
	ret
SendReplaceChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GestureDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete those characters covered by the delete gesture

CALLED BY:	InsertGesture
PASS:		dx - GestureHeader block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GestureDelete	proc	near
	uses	bp
	.enter

	mov	bx, dx
	call	MemLock
	mov	es, ax
	mov	di, offset GH_rectangle	;es:di <- pointer to gesture
					;bounding rectangle
doDeleteGesture:
	sub	sp, size VisTextRange
	mov	bp, sp		;SS:BP <- ptr to VisTextRange to fill in
	call	GetRangeOfCharactersToDelete
	jnc	fixupStackAndExit
;
;	Nuke the gesture info block
;
	call	MemUnlock

	push	si
	mov	ax, MSG_META_DELETE_RANGE_OF_CHARS
	mov	di, mask MF_RECORD or mask MF_STACK
	mov	dx, size VisTextRange
	clrdw	bxsi
	call	ObjMessage
	pop	si
	add	sp, dx

sendEventToOutput::
	mov	bp, di		;BP <- action to send to the output
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	ds:[di].VHGI_status, HWRS_WAITING_FOR_CONTEXT_UPDATE
	push	bp
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	GenCallApplication
	pop	bp

	mov	ax, MSG_GEN_CONTROL_OUTPUT_ACTION
	call	SendToControl

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserSendToApplicationViaProcess
exit:
	.leave
	ret

fixupStackAndExit:
	add	sp, size VisTextRange
memError:
	call	MemUnlock
	jmp	exit
	
GestureDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeOfCharactersToDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the range of characters to be deleted

CALLED BY:	GLOBAL
PASS:		cx - GestureType
		es:di - GestureDeleteInfo
		ss:bp - VisTextRange to fill in (range of chars to delete)
		*ds:si - VisHWRGrid object
RETURN:		carry clear if error (delete was outside of range of chars)
DESTROYED:	ax, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRangeOfCharactersToDelete	proc	far	uses	di, bx
	class	VisHWRGridClass
	stackFrame	local	nptr	\
			push	bp
	leftBound	local	word
	rightBound	local	word
	.enter

	push	ds
	mov	bx, segment udata
	mov	ds, bx

	cmp	cx, GT_H_CROSSOUT
	jz	deleteMultipleChars


;	For a vertical crossout or pigtail delete gesture, just nuke the
;	leftmost character overlapping the gesture.


	mov	ax, es:[di].R_left
	sub	ax, ds:[savedContext].HWRC_grid.HWRGD_bounds.R_left
	mov	leftBound, ax
	pop	ds

	call	ConvertPositionToCharOffset
	movdw	cxbx, dxax
	incdw	cxbx
	jmp	sendDeleteMessage
	
deleteMultipleChars:
	mov	ax, es:[di].R_right
	sub	ax, ds:[savedContext].HWRC_grid.HWRGD_bounds.R_left
	mov	rightBound, ax
	mov	ax, es:[di].R_left
	sub	ax, ds:[savedContext].HWRC_grid.HWRGD_bounds.R_left
	mov	leftBound, ax
	pop	ds

	mov	ax, rightBound
	call	ConvertPositionToCharOffset
	movdw	cxbx, dxax

;	If the left edge of the ink started *before* the left edge of the grid,
;	delete starting from the first char in the grid.

	tst	leftBound
	jns	computeCharOffset

	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	movdw	dxax, ds:[di].VHGI_position
	jmp	sendDeleteMessage

computeCharOffset:
	mov	ax, leftBound
	call	ConvertPositionToCharOffset
	incdw	dxax

sendDeleteMessage:

;	Lock down the context block and ensure that the bounds of chars to
;	delete do not extend beyond the end of the object
;
;	DX.AX <- left edge of range to delete
;	CX.BX <- right edge of range to delete
;

	cmpdw	dxax, cxbx						
EC <	ERROR_A		INVALID_DELETE_RANGE				>
	jae	invalidRange		;Exit with carry clear
   	
	push	ax, bx
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	bx, ds:[di].VHGI_context
	call	MemLock
	mov	es, ax
	pop	ax, bx

	cmpdw	dxax, es:[CD_numChars]
	jae	outOfRange		;Carry is clear if jump taken
	cmpdw	cxbx, es:[CD_numChars]
	jbe	inRange
	movdw	cxbx, es:[CD_numChars]	
inRange:
	stc
outOfRange:
	push	bx
	mov	bx, ds:[di].VHGI_context
	call	MemUnlock
	pop	bx
invalidRange:
	mov	di, stackFrame
	movdw	ss:[di].VTR_start, dxax
	movdw	ss:[di].VTR_end, cxbx

	.leave
	ret
GetRangeOfCharactersToDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfFullyEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed vis object is fully enabled

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		z flag set if not enabled (jz notEnabled)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfFullyEnabled	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter

	push	si
	mov	ax, MSG_VIS_GET_ATTRS
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;CX <- classed event
	pop	si

	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent

	test	cl, mask VA_FULLY_ENABLED
	.leave
	ret
CheckIfFullyEnabled	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the context block, and updates the display

CALLED BY:	GLOBAL
PASS:		bp - datablock
		cx,dx - manuf id, notification type
		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridNotifyWithDataBlock	method	dynamic VisHWRGridClass, 
				MSG_META_NOTIFY_WITH_DATA_BLOCK

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jnz	callSuper
	cmp	dx, GWNT_TEXT_CONTEXT
	jz	isContext
	cmp	dx, GWNT_INK
	jz	cont
	cmp	dx, GWNT_INK_GESTURE
	jnz	callSuper

	mov	bx, bp			
	call	InsertGesture
	jmp	callSuper

cont:
	tst	ds:[di].VHGI_context	;Ignore ink if we have no context
	jz	callSuper		;

	mov	bx, bp			;Increment the reference count so
	call	MemIncRefCount		; the block will hang around for us

	call	SendInkReplaceNotification
	jmp	callSuper

isContext:
	cmp	ds:[di].VHGI_status, HWRS_NOT_ON_SCREEN
	jz	callSuper	;Don't update context if not on-screen

;	If we aren't enabled, ignore context notifications.

	call	CheckIfFullyEnabled
	jz	callSuper		;Exit if not enabled

	mov	bx, bp
	call	MemIncRefCount

	call	HandleNewContext
callSuper:
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, offset VisHWRGridClass
	GOTO	ObjCallSuperNoLock
VisHWRGridNotifyWithDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls to the passed position

CALLED BY:	GLOBAL
PASS:		dx.ax - position
		*ds:si - VisHWRGrid object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollToPosition	proc	near
	class	VisHWRGridClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].VisHWRGrid_offset
	mov	bx, ds:[di].VHGI_context
	push	ax
	call	MemLock
	mov	es, ax
	pop	ax

;	Ensure the passed position is not beyond the end of the text. If it
;	is, change it so it isn't.

	cmpdw	dxax, es:[CD_numChars]
	jb	10$
	movdw	dxax, es:[CD_numChars]
	decdw	dxax
10$:
	movdw	ds:[di].VHGI_position, dxax

;	Determine what range of characters will be shown, and make sure that
;	there is enough room in the data to display the context.

	call	DetermineRangeOfTextToDisplay

	cmpdw	dxax, es:[CD_range].VTR_start
	jb	forceUpdate
	cmpdw	cxbx, es:[CD_range].VTR_end
	ja	forceUpdate
	mov	bx, ds:[di].VHGI_context
	call	MemUnlock

	mov	di, ds:[di].VCGSI_gstate
	call	SetupHWRGridGState
	call	UpdateHWRDisplay
	call	UpdateContextArea
	call	EnableDisableScrollTools
exit:
	.leave
	ret

forceUpdate:

;	The current context block does not have enough information to display
;	so ask for a new one.

	mov	bx, ds:[di].VHGI_context
	call	MemUnlock

	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	GenCallApplication
	movdw	dxax, ds:[di].VHGI_position
	mov	ds:[di].VHGI_status, HWRS_WAITING_FOR_CONTEXT_UPDATE
	mov	cx, CL_CENTERED_AROUND_POSITION
	call	GetContext
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	call	UserSendToApplicationViaProcess
	jmp	exit
	
ScrollToPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridAreaGotoStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to the start of the hwr area.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridAreaGotoStart	method	VisHWRGridClass, MSG_HWR_GRID_AREA_GOTO_START
	.enter
	clrdw	dxax
	call	ScrollToPosition	
	.leave
	ret
VisHWRGridAreaGotoStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridAreaPageBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls backward a "page" of characters

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridAreaPageBack	method	VisHWRGridClass, MSG_HWR_GRID_AREA_PAGE_BACK
	.enter
	movdw	dxax, ds:[di].VHGI_position
	subdw	dxax, NUM_HWR_BOXES-1
	jnc	doScroll
	clrdw	dxax
doScroll:
	call	ScrollToPosition	
	.leave
	ret
VisHWRGridAreaPageBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridAreaStepBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls backward one character

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridAreaStepBack	method	VisHWRGridClass, MSG_HWR_GRID_AREA_STEP_BACK
	.enter
	movdw	dxax, ds:[di].VHGI_position
	subdw	dxax, 1
	jnc	doScroll
	clrdw	dxax
doScroll:
	call	ScrollToPosition	
	.leave
	ret
VisHWRGridAreaStepBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridAreaStepForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls forward one character

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridAreaStepForward	method	VisHWRGridClass, MSG_HWR_GRID_AREA_STEP_FORWARD
	.enter
	movdw	dxax, ds:[di].VHGI_position
	incdw	dxax
	call	ScrollToPosition	
	.leave
	ret
VisHWRGridAreaStepForward	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridAreaPageForward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolls forward one "page"

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridAreaPageForward	method	VisHWRGridClass, MSG_HWR_GRID_AREA_PAGE_FORWARD
	.enter
	movdw	dxax, ds:[di].VHGI_position
	adddw	dxax, NUM_HWR_BOXES-1
	call	ScrollToPosition	
	.leave
	ret
VisHWRGridAreaPageForward	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridAreaGotoEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to the end of the hwr area.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridAreaGotoEnd	method	VisHWRGridClass, MSG_HWR_GRID_AREA_GOTO_END
	.enter
	movdw	dxax, TEXT_ADDRESS_PAST_END
	call	ScrollToPosition	
	.leave
	ret
VisHWRGridAreaGotoEnd	endp
HWRGridCode	ends


if INITFILE_KEYBOARD

GenPenInputControlCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHWRGridSetToZoomerSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Configure our instance data for Zoomer keyboard size.

CALLED BY:	MSG_VIS_HWR_GRID_SET_TO_ZOOMER_SIZE
PASS:		*ds:si	= VisHWRGridClass object
		ds:di	= VisHWRGridClass instance data
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHWRGridSetToZoomerSize	method dynamic VisHWRGridClass, 
					MSG_VIS_HWR_GRID_SET_TO_ZOOMER_SIZE
	.enter

	mov	ds:[di].VI_bounds.R_right, ZOOMER_CHAR_TABLE_WIDTH
	mov	ds:[di].VI_bounds.R_bottom, \
		ZOOMER_HWR_GRID_HEIGHT + (ZOOMER_HWR_GRID_VERTICAL_MARGIN * 2)

	.leave
	ret
VisHWRGridSetToZoomerSize	endm

GenPenInputControlCode	ends

endif		; if INITFILE_KEYBOARD

endif	; if (not _GRAFFITI_UI)
