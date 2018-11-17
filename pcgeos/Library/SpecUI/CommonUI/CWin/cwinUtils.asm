COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/CWin (common code for several specific ui's)
FILE:		cwinUtils.asm (utility routines for windowed UI objects)

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

DESCRIPTION:

	$Id: cwinUtils.asm,v 1.2 98/03/11 06:08:26 joon Exp $

-------------------------------------------------------------------------------@

Resident segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCallParentWithSelf

DESCRIPTION:	Does a VisCallParent, passing this object's OD in cx:dx

CALLED BY:	INTERNAL

PASS:		*ds:si	- this object
		ax	- method
		bp	- any extra data to pass, if any

RETURN:		ax, cx, dx, bp	- returned from handler

DESTROYED:	di

------------------------------------------------------------------------------@

VisCallParentWithSelf	proc	far
	mov	cx, ds:[LMBH_handle]	; Get handle of current object's block
	mov	dx, si
	GOTO	VisCallParent

VisCallParentWithSelf	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCallParentWithSelf

DESCRIPTION:	Does a GenCallParent, passing this object's OD in cx:dx

CALLED BY:	INTERNAL

PASS:		*ds:si	- this object
		ax	- method
		bp	- any extra data to pass, if any

RETURN:		ax, cx, dx, bp	- returned from handler

DESTROYED:	di

------------------------------------------------------------------------------@

GenCallParentWithSelf	proc	far
	mov	cx, ds:[LMBH_handle]	; Get handle of current object's block
	mov	dx, si
	GOTO	GenCallParent

GenCallParentWithSelf	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjMessageCallPreserveCXDXWithSelf

DESCRIPTION:	Performs an ObjMessage to the OD in cx:dx, passing the
		current object's OD in cx:dx.  Preserves bx, si, cx & dx.

CALLED BY:	INTERNAL

PASS:		*ds:si	- object doing the call (to be passed in cx:dx)
		cx:dx	- OD to call
		ax	- method
		bp	- any extra data to pass, if any

RETURN:		ax, bp	- returned from handler

DESTROYED:	di

------------------------------------------------------------------------------@

ObjMessageCallPreserveCXDXWithSelf	proc	far	uses	bx, si, cx, dx
	.enter
	mov	bx, ds:[LMBH_handle]	; Get handle of current object's block
	xchg	bx, cx
	xchg	si, dx
	call	ObjMessageCallFixupDS
	.leave
	ret
ObjMessageCallPreserveCXDXWithSelf	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjMessageCallFixupDS

DESCRIPTION:	Perform an ObjMessage, doing a MF_CALL & MF_FIXUP_DS

CALLED BY:	INTERNAL

PASS:		Same as ObjMessage, minus di params

RETURN:		Same as ObjMessage

DESTROYED:	di

------------------------------------------------------------------------------@

ObjMessageCallFixupDS	proc	far
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage
ObjMessageCallFixupDS	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCallSpecObject

DESCRIPTION:	This is a byte-saving routine used by the specific UI to send
		a method to a related object in the same ObjectBlock.

	*NOTE* - this routine is only called from one place in the
	entire CommonUI (SendToObjectAndItsChildren).  It doesn't
	save bytes at all.  -stevey 4/29/95

PASS:		*ds:si	= instance data for object
		di	= offset into specific instance data to field which
				holds chunk handle of related object.
		cx, dx, bp = data to pass

RETURN:		*ds:si	= same
		cx, dx, bp, carry = data returned from method call

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

if _MENUS_PINNABLE and _CUA_STYLE

OLCallSpecObject	proc	far
	push	si

	;set ds:di = pointer to field which has chunk handle

	push	bp
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset	;set ds:bp = specific instance data
	add	di, bp			;set ds:di = field which holds chunk
	pop	bp

	mov	si, ds:[di]		;set *ds:si = object
					;(must be in same ObjectBlock)
	tst	si
	jz	30$			;skip if no pin trigger object...

	call	ObjCallInstanceNoLock

30$:
	pop	si
	ret
OLCallSpecObject	endp

endif	; _MENUS_PINNABLE and _CUA_STYLE


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinSetObjVisOptFlags

DESCRIPTION:	This routine is used to set/reset specific flags in the
		Visible part of an object. This routine is only called
		in situations where VisMarkInvalid cannot be used.

		DO NOT USE THIS UNLESS YOU KNOW WHAT YOU ARE DOING!

PASS:		carry set if ^lbx:si = OD of object to mark flags for
		carry clear if *ds:si = OD of object to mark flags for

RETURN:		ds, si, bx = same

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OpenWinSetObjVisOptFlags	proc	far
	class	OLCtrlClass

	push	ds
	pushf
	jnc	updateFlags

	call	ObjLockObjBlock
	mov	ds, ax

updateFlags:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ORNF	ds:[di].VI_optFlags, cl
	not	ch
	ANDNF	ds:[di].VI_optFlags, ch
EC <	call	VisCheckOptFlags	;let's make policeman doug happy >
	popf
	jnc	done

	call	MemUnlock
done:
	pop	ds
	ret
OpenWinSetObjVisOptFlags	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	FindOLWin

DESCRIPTION:	Searches up visible tree for first OLWinClass object, & 
		returns it.  Will return NULL if a thread boundary encountered.

CALLED BY:	INTERNAL

PASS:		*ds:si	- visible object

RETURN:		^lbx:si	- OLWinClass object (or NULL, if not found)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version
------------------------------------------------------------------------------@

FindOLWin	proc	far
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	pop	di
	jz	goUp
	push	di, es
	mov	di, segment OLWinClass 
	mov	es, di
	mov	di, offset OLWinClass 
	call	ObjIsObjectInClass
	pop	di, es
	jnc	goUp
					; Found it!
	mov	bx, ds:[LMBH_handle]
	ret

goUp:
	call	VisFindParent
	tst	bx
	jz	noParent
	cmp	bx, ds:[LMBH_handle]	; quick test -- if parent in same block,
	je	sameThread		;	then run by same thread.
	call	ObjTestIfObjBlockRunByCurThread
	jne	noParent		; if parent run by different thread,
					;	bail.
sameThread:
	call	ObjSwapLock

	push	ax
	push	bx
	call	FindOLWin
	mov	ax, bx
	pop	bx
	call	ObjSwapUnlock
	mov	bx, ax
	pop	ax
	ret

noParent:
	clr	bx			; OLWinClass object not found.
	clr	si
	ret

FindOLWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SwapLockOLWin

DESCRIPTION:	Locks OLWin object up visible tree for access

CALLED BY:	INTERNAL

PASS:		*ds:si	- visible object

RETURN:		carry	- set if successful (clear if no parent)
		*ds:si	- OLWinClass object, if found, else ds unchanged.
		bx	- ds:[0], suitable for passing to ObjSwapUnlock

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version
------------------------------------------------------------------------------@

SwapLockOLWin	proc	far
	call	FindOLWin
	tst	bx
	jz	notFound
	stc				; return carry set, to indicate found
	GOTO	ObjSwapLock

notFound:
	mov	bx, ds:[LMBH_handle]
	clr	si
	clc
	ret
	
SwapLockOLWin	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CallOLWin

DESCRIPTION:	Calls first OLWin object up visible tree w/message & data passed

CALLED BY:	INTERNAL

PASS:		*ds:si	- visible object
		ax	- message to call on OLWinClass object
		cx, dx, bp	- data to pass

RETURN:		ax, cx, dx, bp 	- per message

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version
------------------------------------------------------------------------------@

CallOLWin	proc	far
	push	bx, si
	call	SwapLockOLWin
	jnc	done
	call	ObjCallInstanceNoLock
	call	ObjSwapUnlock
done:
	pop	bx, si
	ret
CallOLWin	endp


Resident ends
;
;-------------------------
;
Build segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinDuplicateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This procedure duplicates an entire UI template block of the
		specific UI.  A one-way link is set up from the head object
		of that block passed in, to the OLWinClass object passed in.
		The "ObjBlock output" of the new block will be set to
		the OLWinClass object itself, allowing gadgets in the template
		to send messages directly to the window using
		"TO_OBJ_BLOCK_OUTPUT".   Since the new objects ARE created
		w/one-way link only, they will need to be directly vis built,
		or set USABLE, so that they become visible.

		This routine is being used to create all the CUA title 
		bar stuff, such as system-menu items, minimize, maximize,
		popup-menus for primary & command windows, & even
		EXIT & HELP icons for GCM.
		
PASS:		*ds:si = OLWinClass object
		ax = offset to field in OLWinInstance structure, where the
			handle of the new UI block will be stored.
		^lbx:dx = OD of head object of branch in UI resource to be
		      copied

RETURN:		*ds:si = same
		^lcx:dx = new object

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenWinDuplicateBlock	proc	far	uses	ax, bx, bp
	.enter

	push	ax			; save offset into instance data
	push	bx
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	ax, bx			; have owned by same as owner of OLWin
	clr	cx			; have current thread run block
	pop	bx
	call	ObjDuplicateResource	; bx = handle of new block

	; Set ObjBlock output to be OLWinClass object
	;
	call	ObjSwapLock
	call	ObjBlockSetOutput
	call	ObjSwapUnlock

	mov	cx, bx			; ^lcx:dx is now new block, object
	pop	ax			; get offset into instance data

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, ax				;point to field
	mov	ds:[di], cx			;save handle of new object

	; Now set generic parent link for child to be OLWinClass obj.
	; We don't want this to be a legitimate generic child of the OLWinClass
	; object, because that might confuse applications.
	;	*ds:si = OLWinClass (parent)
	;	cx:dx = new child
	;
	call	GenAddChildUpwardLinkOnly

	.leave
	ret

OpenWinDuplicateBlock	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetVisParentForDialog

DESCRIPTION:	Returns visible parent to use for the WIN_GROUP part of 
		a dialog box (independently displayable interaction or
		GenSummons)

CALLED BY:	GLOBAL
		Window spec build routines, Gen -> spec mapping routines

PASS:
	*ds:si	- GenInteraction or GenSummons object

RETURN:
	cx:dx	- Visible parent to use.

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

GetVisParentForDialog	proc	far	uses di, bp
	class	OLWinClass

	.enter
EC <	; MAKE sure that this is an interaction			>
EC <	push	es						>
EC <	mov	di, segment GenInteractionClass			>
EC <	mov	es, di						>
EC <	mov	di, offset GenInteractionClass			>
EC <	call	ObjIsObjectInClass				>
EC <	ERROR_NC	OL_ERROR				>
EC <	pop	es						>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, SQT_VIS_PARENT_FOR_POPUP
	test	ds:[di].GII_attrs, mask GIA_SYS_MODAL
	jz	afterModalityTest
	mov	cx, SQT_VIS_PARENT_FOR_SYS_MODAL
afterModalityTest:
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	call	GenCallParent
EC <	ERROR_NC	OL_WINDOWED_GEN_OBJECT_NOT_IN_GEN_TREE		>
	.leave
	ret
GetVisParentForDialog	endp


Build ends
;-------------------------
WinCommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureWindowInParentWin

DESCRIPTION:	This procedure ensures that this windowed object is
		still visible within the parent window.

CALLED BY:	OLWinGlyphDisplayMove
		OpenWinMoveResizeWin

PASS:		ds:*si	- instance data for windowed object
		cx, dx	- minimum width and height of window to keep visible
			(pass width and height of window to keep it
			entirely visible on the screen.)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
	query to find parentWidth and parentHeight
	TEST FOR TOO FAR TO THE RIGHT:
		newX = parentWidth - MARGIN
		if currentLeft > newX then currentLeft = newX
	TEST FOR TOO FAR TO THE LEFT:
		newX = MARGIN - currentRight
		if currentLeft < newX then currentLeft = newX
	TEST FOR TOO FAR TO THE BOTTOM:
		newY = parentHeight - MARGIN
		if currentTop > newY then currentTop = newY
	TEST FOR TOO FAR TO THE TOP:
		newY = MARGIN - currentBottom
		if currentTop < newY then currentTop = newY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version (adapted from C.H. 3/89 version)
	Doug	11/89		Is now called from subclass of _MOVE_RESIZE_WIN,
				instead of MSG_VIS_MOVE.
	Eric	11/89		Adapted to new window positioning/resizing
				scheme, and to use VisSetPosition instead of just
				stuffing bounds.
				(nuked OpenWinKeepInParentWin procedure)
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@
EnsureWindowInParentWin	proc	far
	class	VisClass

	push	cx, dx				;save minimum width and height
						;to keep visible
	call	OpenGetParentWinSize
	pop	bp, bx				;bp = min width, bx = min height
	jnc	EWIPW_90			;If no response, don't care...
if TOOL_AREA_IS_TASK_BAR
	; If taskbar is at the bottom of the screen, subtract off the
	; height of the tool area (taskbar) from parent window size so
	; maximized windows don't extend below the taskbar.
	call	GetTaskBarSizeAdjustment
	sub	dx, di			; subtract off taskbar adjustment
endif ; TOOL_AREA_IS_TASK_BAR

	;FIRST CHECK X POSITION

	push	bx				;save min height to keep visible
	call	WinCommon_DerefVisSpec_DI

	;TEST FOR TOO FAR TO THE RIGHT:
	;	newX = parentWidth - MARGIN
	;	if currentLeft > newX then currentLeft = newX

	mov	ax, ds:[di].VI_bounds.R_left	;get current left
	tst	ax				;to left of parent?
	js	EWIPW_10			;skip if so...

	sub	cx, bp				;subtract MARGIN-1
	inc	cx

	cmp	ax, cx				;compare current left to MAX
	jg	EWIPW_50			;skip if to the right of MAX...
						;(cx = new position)

EWIPW_10:
	;TEST FOR TOO FAR TO THE LEFT:
	;	newX = MARGIN - currentRight
	;	if currentLeft < newX the currentLeft = newX

						;ax = current left
;	tst	ax				;to right of parent?
;	jns	EWIPW_20			;skip if so...

	mov	cx, bp				;get MARGIN
	sub	cx, ds:[di].VI_bounds.R_right	;subtract WIDTH
	add	cx, ds:[di].VI_bounds.R_left
	cmp	ax, cx
	jle	EWIPW_50			;skip if left of MIN...
						;(cx = new position)

;EWIPW_20: ;X position is OK
	mov	cx, ax				;set new pos = current pos

EWIPW_50: ;NOW CHECK Y POSITION (dx = parentHeight)
	pop	bp				;bp = min height to keep visible

	;TEST FOR TOO FAR TO THE BOTTOM:
	;	newY = parentHeight - MARGIN
	;	if currentTop < 0 then (is higher than parent), skip ahead...
	;	if new < 0 then (window is larger than parent) currentTop = 0
	;	else if currentTop > newY the currentTop = newY

	mov	bx, ds:[di].VI_bounds.R_top	;get current top
	tst	bx				;above parent?
	js	EWIPW_60			;skip if so...

	sub	dx, bp				;subtract MARGIN-1
	inc	dx
	tst	dx				;above top of window?
	jns	EWIPW_55			;skip if is not big window...

	;hack for big windows: align top with top of screen

	clr	dx
	jmp	EWIPW_80

EWIPW_55:
	cmp	bx, dx
	jg	EWIPW_80			;skip if below MAX...
						;(dx = new position)

EWIPW_60:
	;TEST FOR TOO FAR TO THE TOP:
	;	newY = MARGIN - currentBottom
	;	if currentTop < newY the currentTop = newY

;	tst	bx				;below parent?
;	jns	EWIPW_70			;skip if so...

	mov	dx, bp				;get MARGIN
	sub	dx, ds:[di].VI_bounds.R_bottom	;subtract height
	add	dx, ds:[di].VI_bounds.R_top
	cmp	bx, dx
	jle	EWIPW_80			;skip if above MIN...
						;(dx = new position)

;EWIPW_70: ;Y position is OK
	mov	dx, bx				;set new pos = current pos

EWIPW_80:
	;now move window to new position (in cx, dx)
	call	VisSetPosition

EWIPW_90: ;all done. Return with new bounds for window
	ret

EnsureWindowInParentWin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureTitleBarInParentWin

DESCRIPTION:	This procedure ensures that this OLWinClass object's title bar
		is still visible within the parent window.

CALLED BY:	OpenWinMoveResizeWin

PASS:		ds:*si	- instance data for windowed object

RETURN:		

DESTROYED:	di, bp, ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	query to find parentWidth and Height
	TEST FOR TOO FAR TO THE RIGHT:
		newX = parentWidth - titleLeftX - MARGIN
		if currentLeft > newX then currentLeft = newX
	TEST FOR TOO FAR TO THE LEFT:
		newX = MARGIN - titleRight
		if currentLeft < newX then currentLeft = newX
	TEST FOR TOO FAR TO THE BOTTOM:
		newY = parentHeight - titleTop - MARGIN
		if currentTop > newY then currentTop = newY
	TEST FOR TOO FAR TO THE TOP:
		newY = MARGIN - titleBottom
		if currentTop < newY then currentTop = newY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@

if _CUA_STYLE	;START of CUA/MOTIF specific code -----

;Minimum amount of window (or title bar in window) that we want on the screen

MIN_WIN_TITLE_BAR_ONSCREEN_DIST	=	10	;just enough to grab

EnsureTitleBarInParentWin	proc	near
	class	OLWinClass

	;does this OLWinClass object have a title bar?

	call	WinCommon_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_TITLED
	jz	ETBIPW_90			;skip adjustment if not...

	call	OpenGetParentWinSize		;get size of window we're on
	jnc	ETBIPW_90			;If no response, don't care...
if TOOL_AREA_IS_TASK_BAR
	; If taskbar is at the bottom of the screen, subtract off the
	; height of the tool area (taskbar) from parent window size so
	; maximized windows don't extend below the taskbar.
	call	GetTaskBarSizeAdjustment
	sub	dx, di			; subtract off taskbar adjustment
endif ; TOOL_AREA_IS_TASK_BAR

	;FIRST CHECK X POSITION

	push	dx				;save parent height - 1
	call	WinCommon_DerefVisSpec_DI

	;TEST FOR TOO FAR TO THE RIGHT:
	;	newX = parentWidth - titleLeftX - MARGIN
	;	if currentLeft > newX then currentLeft = newX

	mov	ax, ds:[di].VI_bounds.R_left	;get current left
	tst	ax				;to left of parent?
	js	ETBIPW_10			;skip if so...

	sub	cx, ds:[di].OLWI_titleBarBounds.R_left
	sub	cx, MIN_WIN_TITLE_BAR_ONSCREEN_DIST-1

						;ax = current left
	cmp	ax, cx
	jg	ETBIPW_50			;skip if to the right of MAX...
						;(cx = new position)

ETBIPW_10:
	;TEST FOR TOO FAR TO THE LEFT:
	;	newX = MARGIN - titleRight
	;	if currentLeft < newX the currentLeft = newX

						;ax = current left
;	tst	ax				;to right of parent?
;	jns	ETBIPW_20			;skip if so...

	mov	cx, MIN_WIN_TITLE_BAR_ONSCREEN_DIST
	sub	cx, ds:[di].OLWI_titleBarBounds.R_right
	cmp	ax, cx
	jle	ETBIPW_50			;skip if to the left of MIN...
						;(cx = new position)

;ETBIPW_20: ;X position is OK
	mov	cx, ax				;set new pos = current pos

ETBIPW_50: ;NOW CHECK Y POSITION
	pop	dx				;get parent height - 1

	;TEST FOR TOO FAR TO THE BOTTOM:
	;	newY = parentHeight - titleTop - MARGIN
	;	if currentTop > newY the currentTop = newY

	mov	bx, ds:[di].VI_bounds.R_top	;get current top
	tst	bx				;above parent?
	js	ETBIPW_60			;skip if so...

	sub	dx, ds:[di].OLWI_titleBarBounds.R_top
	sub	dx, MIN_WIN_TITLE_BAR_ONSCREEN_DIST-1

	cmp	bx, dx
	jg	ETBIPW_80			;skip if to the below MAX...
						;(dx = new position)

ETBIPW_60:
	;TEST FOR TOO FAR TO THE TOP:
	;	newY = MARGIN - titleBottom
	;	if currentTop < newY the currentTop = newY

;	tst	bx				;below parent?
;	jns	ETBIPW_70			;skip if so...

	mov	dx, MIN_WIN_TITLE_BAR_ONSCREEN_DIST
	sub	dx, ds:[di].OLWI_titleBarBounds.R_bottom
	cmp	bx, dx
	jle	ETBIPW_80			;skip if above MIN...
						;(dx = new position)

;ETBIPW_70: ;Y position is OK
	mov	dx, bx				;set new pos = current pos

ETBIPW_80:
	;now move window to new position (in cx, dx)

	call	VisSetPosition

ETBIPW_90: ;all done. Return with new bounds for window
	ret

EnsureTitleBarInParentWin	endp

endif			;END of CUA/MOTIF specific code ---------------


WinCommon ends

;==============================================================================
;		OPTIMIZATION ROUTINES
;==============================================================================

WinMethods	segment resource

WinMethods_ObjCallSuperNoLock_OLWinClass_Far	proc	far
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock
WinMethods_ObjCallSuperNoLock_OLWinClass_Far	endp

WinMethods	ends

WinCommon	segment resource

WinCommon_DerefGen_DI	proc	near
	class	GenClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
WinCommon_DerefGen_DI	endp

;---

WinCommon_DerefVisSpec_DI	proc	near
	class	VisClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
WinCommon_DerefVisSpec_DI	endp

WinCommon_Deref_Load_FocusExcl_CXDX	proc	near
	class	OLWinClass
	mov	di, offset OLWI_focusExcl.FTVMC_OD
	FALL_THRU	WinCommon_Deref_Load_OD_CXDX
WinCommon_Deref_Load_FocusExcl_CXDX	endp

WinCommon_Deref_Load_OD_CXDX	proc	near
	push	bx
	mov	bx, di
	call	WinCommon_DerefVisSpec_DI
	mov	cx, ds:[di][bx].handle
	mov	dx, ds:[di][bx].chunk
	pop	bx
	ret
WinCommon_Deref_Load_OD_CXDX	endp

;---

WinCommon_Deref_Load_FocusExcl_BXSI	proc	near
	class	OLWinClass
	mov	bx, offset OLWI_focusExcl.FTVMC_OD
	FALL_THRU	WinCommon_Deref_Load_OD_BXSI
WinCommon_Deref_Load_FocusExcl_BXSI	endp

WinCommon_Deref_Load_OD_BXSI	proc	near
	call	WinCommon_DerefVisSpec_DI
	mov	si, ds:[di][bx].chunk
	mov	bx, ds:[di][bx].handle
	ret
WinCommon_Deref_Load_OD_BXSI	endp

;---

if	0
WinCommon_GenCallParent_PassSelf	proc	near
	call	WinCommon_Mov_CXDX_Self
	FALL_THRU	WinCommon_GenCallParent
WinCommon_GenCallParent_PassSelf	endp
WinCommon_GenCallParent	proc	near
	call	GenCallParent
	ret
WinCommon_GenCallParent	endp
endif

;---

WinCommon_ObjMessageForceQueue	proc	near
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	WinCommon_ObjMessage
WinCommon_ObjMessageForceQueue	endp

if 0
WinCommon_ObjMessageSendFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS
	GOTO	WinCommon_ObjMessage
WinCommon_ObjMessageSendFixupDS	endp
endif

WinCommon_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	WinCommon_ObjMessage
WinCommon_ObjMessageCallFixupDS	endp

WinCommon_ObjMessage	proc	near
	call	ObjMessage
	ret
WinCommon_ObjMessage	endp

;---

WinCommon_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW	proc	near
	mov	dl, VUM_NOW
	FALL_THRU	WinCommon_CallSelf_SET_VIS_SPEC_ATTR
WinCommon_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW	endp

WinCommon_CallSelf_SET_VIS_SPEC_ATTR	proc	near
	mov	ax, MSG_SPEC_SET_ATTRS
	FALL_THRU	WinCommon_ObjCallInstanceNoLock
WinCommon_CallSelf_SET_VIS_SPEC_ATTR	endp

WinCommon_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
WinCommon_ObjCallInstanceNoLock	endp

;---

WinCommon_ObjCallSuperNoLock_OLWinClass	proc	near
	mov	di, offset OLWinClass
	FALL_THRU	WinCommon_ObjCallSuperNoLock
WinCommon_ObjCallSuperNoLock_OLWinClass	endp

WinCommon_ObjCallSuperNoLock	proc	near
	call	ObjCallSuperNoLock
	ret
WinCommon_ObjCallSuperNoLock	endp

;---

WinCommon_Mov_CXDX_Self	proc	near
EC <	call	ECCheckLMemObject					>
	mov	cx, ds:[LMBH_handle]	;set ^lcx:dx = this root object
	mov	dx, si
	ret
WinCommon_Mov_CXDX_Self	endp

;---

WinCommon_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL	proc	near
	mov	cl, mask VOF_WINDOW_INVALID
	FALL_THRU	WinCommon_VisMarkInvalid_MANUAL
WinCommon_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL	endp

WinCommon_VisMarkInvalid_MANUAL	proc	near
	mov	dl, VUM_MANUAL
	FALL_THRU	WinCommon_VisMarkInvalid
WinCommon_VisMarkInvalid_MANUAL	endp

WinCommon_VisMarkInvalid	proc	near
	call	VisMarkInvalid
	ret
WinCommon_VisMarkInvalid	endp

;---

WinCommon_VisCallParent_VUP_QUERY	proc	near
	mov	ax, MSG_VIS_VUP_QUERY
	FALL_THRU	WinCommon_VisCallParent
WinCommon_VisCallParent_VUP_QUERY	endp

WinCommon_VisCallParent	proc	near
	call	VisCallParent
	ret
WinCommon_VisCallParent	endp

WinCommon_ClrAXandOLWIFocusExcl	proc	near
	clr	ax
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.handle, ax
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.chunk, ax
	ret
WinCommon_ClrAXandOLWIFocusExcl	endp

;---

WinCommon	ends

;------------------------------------------------------------------------------

WinOther	segment resource

if	0
WinOther_DerefGen_DI	proc	near
	class	GenClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
WinOther_DerefGen_DI	endp
endif

;---

WinOther_DerefVisSpec_DI	proc	near
	class	VisClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
WinOther_DerefVisSpec_DI	endp

if	0
WinOther_Deref_Load_FocusExcl_CXDX	proc	near
	class	OLWinClass
	mov	di, offset OLWI_focusExcl.FTVMC_OD
	FALL_THRU	WinOther_Deref_Load_OD_CXDX
WinOther_Deref_Load_FocusExcl_CXDX	endp
endif

if	0
WinOther_Deref_Load_OD_CXDX	proc	near
	push	bx
	mov	bx, di
	call	WinOther_DerefVisSpec_DI
	mov	cx, ds:[di][bx].handle
	mov	dx, ds:[di][bx].chunk
	pop	bx
	ret
WinOther_Deref_Load_OD_CXDX	endp
endif

;---

if	0
WinOther_Deref_Load_FocusExcl_BXSI	proc	near
	class	OLWinClass
	mov	bx, offset OLWI_focusExcl.FTVMC_OD
	FALL_THRU	WinOther_Deref_Load_OD_BXSI
Deref_Load_FocusExcl_BXSI	endp
endif

if	0
WinOther_Deref_Load_OD_BXSI	proc	near
	call	WinOther_DerefVisSpec_DI
	mov	si, ds:[di][bx].chunk
	mov	bx, ds:[di][bx].handle
	ret
WinOther_Deref_Load_OD_BXSI	endp
endif

;---

if	0
WinOther_GenCallParent_PassSelf	proc	near
	call	WinOther_Mov_CXDX_Self
	FALL_THRU	WinOther_GenCallParent
WinOther_GenCallParent_PassSelf	endp
endif
if	0
WinOther_GenCallParent	proc	near
	call	GenCallParent
	ret
WinOther_GenCallParent	endp
endif
;---

if	0
WinOther_ObjMessageForceQueue	proc	near
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	WinOther_ObjMessage
WinOther_ObjMessageForceQueue	endp

WinOther_ObjMessageSendFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS
	GOTO	WinOther_ObjMessage
WinOther_ObjMessageSendFixupDS	endp

WinOther_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	WinOther_ObjMessage
WinOther_ObjMessageCallFixupDS	endp

WinOther_ObjMessage	proc	near
	call	ObjMessage
	ret
WinOther_ObjMessage	endp
endif

;---

if	0
WinOther_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW	proc	near
	mov	dl, VUM_NOW
	FALL_THRU	WinOther_CallSelf_SET_VIS_SPEC_ATTR
WinOther_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW	endp

WinOther_CallSelf_SET_VIS_SPEC_ATTR	proc	near
	mov	ax, MSG_SPEC_SET_ATTRS
	FALL_THRU	WinOther_ObjCallInstanceNoLock
WinOther_CallSelf_SET_VIS_SPEC_ATTR	endp

endif

WinOther_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
WinOther_ObjCallInstanceNoLock	endp

;---
WinOther_ObjCallSuperNoLock_OLWinClass_Far	proc	far
	mov	di, offset OLWinClass
	call	WinOther_ObjCallSuperNoLock_OLWinClass
	ret
WinOther_ObjCallSuperNoLock_OLWinClass_Far	endp

WinOther_ObjCallSuperNoLock_OLWinClass	proc	near
	mov	di, offset OLWinClass
	FALL_THRU	WinOther_ObjCallSuperNoLock
WinOther_ObjCallSuperNoLock_OLWinClass	endp

WinOther_ObjCallSuperNoLock	proc	near
	call	ObjCallSuperNoLock
	ret
WinOther_ObjCallSuperNoLock	endp

;---

if	0
WinOther_Mov_CXDX_Self	proc	near
EC <	call	ECCheckLMemObject					>
	mov	cx, ds:[LMBH_handle]	;set ^lcx:dx = this root object
	mov	dx, si
	ret
WinOther_Mov_CXDX_Self	endp
endif

;---

if	0
WinOther_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL	proc	near
	mov	cl, mask VOF_WINDOW_INVALID
	FALL_THRU	WinOther_VisMarkInvalid_MANUAL
WinOther_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL	endp

WinOther_VisMarkInvalid_MANUAL	proc	near
	mov	dl, VUM_MANUAL
	FALL_THRU	WinOther_VisMarkInvalid
WinOther_VisMarkInvalid_MANUAL	endp

WinOther_VisMarkInvalid	proc	near
	call	VisMarkInvalid
	ret
WinOther_VisMarkInvalid	endp
endif

;---

WinOther_VisCallParent_VUP_QUERY	proc	near
	mov	ax, MSG_VIS_VUP_QUERY
	FALL_THRU	WinOther_VisCallParent
WinOther_VisCallParent_VUP_QUERY	endp

WinOther_VisCallParent	proc	near
	call	VisCallParent
	ret
WinOther_VisCallParent	endp

;---

WinOther_ClrAXandOLWIFocusExcl	proc	near
	clr	ax
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.handle, ax
	mov	ds:[di].OLWI_focusExcl.FTVMC_OD.chunk, ax
	ret
WinOther_ClrAXandOLWIFocusExcl	endp

WinOther	ends

;------------------------------------------------------------------------------

WinClasses	segment resource

WinClasses_DerefGen_DI	proc	near
	class	GenClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
WinClasses_DerefGen_DI	endp

;---

WinClasses_DerefVisSpec_DI	proc	near
	class	VisClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
WinClasses_DerefVisSpec_DI	endp

;---

WinClasses_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
WinClasses_ObjMessageCallFixupDS	endp

;---

WinClasses_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW	proc	near
	mov	dl, VUM_NOW
	mov	ax, MSG_SPEC_SET_ATTRS
	FALL_THRU	WinClasses_ObjCallInstanceNoLock
WinClasses_CallSelf_SET_VIS_SPEC_ATTR_VUM_NOW	endp

WinClasses_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
WinClasses_ObjCallInstanceNoLock	endp

WinClasses_ObjCallInstanceNoLock_Far	proc	far
	call	WinClasses_ObjCallInstanceNoLock
	ret
WinClasses_ObjCallInstanceNoLock_Far	endp

;---

WinClasses_ObjCallSuperNoLock_OLBaseWinClass	proc	near
	mov	di, offset OLBaseWinClass
	GOTO	WinClasses_ObjCallSuperNoLock
WinClasses_ObjCallSuperNoLock_OLBaseWinClass	endp

WinClasses_ObjCallSuperNoLock_OLMenuedWinClass	proc	near
	mov	di, offset OLMenuedWinClass
	GOTO	WinClasses_ObjCallSuperNoLock
WinClasses_ObjCallSuperNoLock_OLMenuedWinClass	endp

WinClasses_ObjCallSuperNoLock_OLDialogWinClass	proc	near
	mov	di, offset OLDialogWinClass
	GOTO	WinClasses_ObjCallSuperNoLock
WinClasses_ObjCallSuperNoLock_OLDialogWinClass	endp

WinClasses_ObjCallSuperNoLock_OLMenuWinClass	proc	near
	mov	di, offset OLMenuWinClass
	GOTO	WinClasses_ObjCallSuperNoLock
WinClasses_ObjCallSuperNoLock_OLMenuWinClass	endp

WinClasses_ObjCallSuperNoLock_OLPopupWinClass	proc	near
	mov	di, offset OLPopupWinClass
	GOTO	WinClasses_ObjCallSuperNoLock
WinClasses_ObjCallSuperNoLock_OLPopupWinClass	endp

WinClasses_ObjCallSuperNoLock	proc	near
	call	ObjCallSuperNoLock
	ret
WinClasses_ObjCallSuperNoLock	endp

;---

WinClasses_Mov_CXDX_Self	proc	near
EC <	call	ECCheckLMemObject					>
	mov	cx, ds:[LMBH_handle]	;set ^lcx:dx = this root object
	mov	dx, si
	ret
WinClasses_Mov_CXDX_Self	endp

;---

if _MENUS_PINNABLE
WinClasses_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL	proc	near
	mov	cl, mask VOF_WINDOW_INVALID
	FALL_THRU	WinClasses_VisMarkInvalid_MANUAL
WinClasses_VisMarkInvalid_VOF_WINDOW_INVALID_MANUAL	endp

WinClasses_VisMarkInvalid_MANUAL	proc	near
	mov	dl, VUM_MANUAL
	FALL_THRU	WinClasses_VisMarkInvalid
WinClasses_VisMarkInvalid_MANUAL	endp
endif

WinClasses_VisMarkInvalid	proc	near
	call	VisMarkInvalid
	ret
WinClasses_VisMarkInvalid	endp

WinClasses	ends


;------------------------------------------------------------------------------

KbdNavigation	segment resource

KN_DerefVisSpec_DI	proc	near
	class	VisClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
KN_DerefVisSpec_DI	endp

KbdNavigation	ends


ActionObscure	segment resource

AO_DerefVisSpec_DI	proc	near
	class	VisClass
EC <	call	ECCheckLMemObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
AO_DerefVisSpec_DI	endp

ActionObscure	ends

;---

WinCommon	segment resource

if	(0)	; written, but not tested.

COMMENT @----------------------------------------------------------------------

FUNCTION:	WinOpenFromStruct

DESCRIPTION:	Call WinOpen with passed parameters

CALLED BY:	INTERNAL
		Utility routine, makes it easier to calculate parameters for
		call.

PASS:		ss:bp	- WinOpenParams

RETURN:		bx	- handle to allocated & opened window
		di	- handle to allocated & opened graphic state (if any)

DESTROYED:	ax, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

WinOpenParams	struct
    ; group passed in registers
	WOP_red		byte		; al
	WOP_colorFlags	WinColorFlags	; ah
	WOP_green	byte		; bl
	WOP_blue	byte		; bh
	WOP_inputOD	optr		; cx:dx
	WOP_exposureOD	optr		; di:bp
	WOP_flags	WinPassFlags	; si

    ; Start of group passed on stack
	WOP_rectangle	Rectangle
	WOP_region	fptr
	WOP_parent	hptr
	WOP_owner	hptr
	WOP_layerID	hptr
WinOpenParams	ends

WinOpenFromStruct	proc	far	uses	ds, es
	.enter
	mov	ax, ss		; get ptr in ds:si
	mov	ds, ax
	mov	si, bp

				; create space for WinOpen "on stac" params
	mov	cx, size WinOpenParams - offset WOP_rectangle
	sub	sp, cx
	mov	di, sp
	mov	ax, ss
	mov	es, ax
	push	si
	add	si, offset WOP_rectangle
	rep	movsb		; copy onto stack
	pop	si
	lodsw			; now get params passed in registers
	push	ax
	lodsw
	mov	bx, ax
	lodsw
	mov	dx, ax
	lodsw
	mov	cx, ax
	lodsw
	mov	bp, ax
	lodsw
	mov	di, ax
	lodsw
	mov	si, ax
	call	WinOpen
	.leave
	ret

WinOpenFromStruct	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinCheckIfMinMaxRestoreControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns flag indicating whether or not the user should be
		allowed to min/max/restore the current OLWinClass object
		at all.

CALLED BY:	INTERNAL
PASS:		*ds:si	- OLWinClass object
RETURN:		carry	- set if min/max/restore capability is being offered
			  in general for this type of window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenWinCheckIfMinMaxRestoreControls	proc	near	uses	ax, di, es
	.enter
	mov	ax, segment olWindowOptions
	mov	es, ax

	call	WinCommon_DerefVisSpec_DI
CUAS <	cmp     ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
OLS <	cmp     ds:[di].OLWI_type, OLWT_DISPLAY_WINDOW			>
	je	exitYes
CUAS <	cmp     ds:[di].OLWI_type, MOWT_PRIMARY_WINDOW			>
OLS <	cmp     ds:[di].OLWI_type, OLWT_BASE_WINDOW			>
	je	primaryCheck
ISU <	cmp	ds:[di].OLWI_type, MOWT_COMMAND_WINDOW			>
ISU <	je	exitYes							>
	clc				; if not display or primary, then NO,
					; no min/max restore capability
	jmp	exit

primaryCheck:
	test	es:[olWindowOptions], mask UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS
	jz	exit			; no, exit with carry clear

exitYes:
	stc
exit:
	.leave
	ret
OpenWinCheckIfMinMaxRestoreControls	endp

WinCommon	ends

;-------------------------------------------------------------------------
