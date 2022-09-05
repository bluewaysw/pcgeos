COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988-1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		OpenLook/Open
FILE:		openUtils.asm

ROUTINES:
	Name				Description
	----				-----------
	OpenGetLineBounds		Returns object bounds for drawing lines
	SpecGetDisplayScheme		Fetch default display scheme
	OpenDrawObject			Redraws an open look object
	VupCreateState			Creates a gstate, according
					to MSG_VIS_VUP_CREATE_GSTATE
					conventions
	ViewCreateDrawGState		Creates a gstate for drawing
	ViewCreateCalcGState		Creates a gstate for calculations
	ViewCreateGState		Creates a gstate for calculations
	OpenSetCtrlOrientation		Sets the orientation of a control
	OpenSaveNavigationChar		Save keyboard character as nav. starts
	OpenEndNavigationChar		Get saved kbd char to see if navigating
	OpenTestIfFocusOnTextEditObject	Tests if the focus exclusive in this
					    WIN_GROUP is on a text-edit object
	OpenDrawRect			Special specific-UI rect drawing
	OpenSetInsetRectColors		With OpenDrawRect, draws inset rects

	OpenCreateObject		Creates a new instance of an object,
					optionally adds it into a tree, will
					add hints/attributes to it.  Basically
					a MSG_GEN_COPY_TREE replacement.
	OpenNavigateIfLosingFocus	Navigates if losing the focus.

	Utility routines for saving bytes:
	----------------------------------
	ObjCallSpecNoLock
	CF_SendToTarget

	Utility routines for saving bytes:
	----------------------------------
	ObjCallPreserveRegs
	Build_DerefVisSpecDI
	Build_DerefGenDI
	Build_CallCopyTreeSameBlockNoAddNoFlags
	Build_CallCopyTreeSameBlockNoFlags
	Build_CallCopyTreeSameBlock
	Build_ObjMessageCallFixupDS
	Build_ObjMessage
	Build_CallGenSetUsableViaUIQueue
	Build_ObjCallInstanceNoLock
	Build_CallSpecBuild
	CF_DerefVisSpecDI
	CF_DerefGenDI
	CF_ObjCallInstanceNoLock
	Res_DerefVisDI
	Res_DerefGenDI
	Res_ObjCallInstanceNoLock
	Geo_DerefVisDI
	Geo_DerefGenDI
	Geo_ObjCallInstanceNoLock
	OpenSetGenByte
	OpenSetGenWord
	OpenSetGenDWord

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:

	$Id: copenUtils.asm,v 2.172 97/04/02 21:35:31 brianc Exp $

-------------------------------------------------------------------------------@

Resident segment resource

				

COMMENT @----------------------------------------------------------------------

FUNCTION:	Res_DerefVisDI

DESCRIPTION:	utility routine to dereference *ds:si to find the VisSpec
		instance data in an object.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same
		ds:di	= VisSpec instance data

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version (adapted from Tony's version)

------------------------------------------------------------------------------@

Res_DerefVisDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
Res_DerefVisDI	endp

Res_DerefGenDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
Res_DerefGenDI	endp

;This saves bytes because it can be called with a near call, which is fewer
;bytes that a far-call.

Res_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
Res_ObjCallInstanceNoLock	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetLineBounds

SYNOPSIS:	Returns object bounds, suitable for drawing lines.  The
		problem is that lines with the new graphics system draw exactly
		the same as a line with the same args under the old system,
		but the definition of bounds have changed.  A framed rect
		drawn on the object's bounds actually draws below and to the
		right of the object's area.

CALLED BY:	utility

PASS:		*ds:si -- object
		cl     - CompBoundsFlags (needed for composites only)
		   mask CBF_INSIDE_COMP_MARGINS:  Returns the area where the
		   	composite's children will go, inside the bounds of
			the composite.

RETURN:		ax, bx, cx, dx -- object's bounds, suitable for line drawing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/19/91		Initial version

------------------------------------------------------------------------------@

OpenGetLineBounds	proc	far
	call	VisGetBounds		;get literal bounds
	dec	cx			;adjust for lines
	dec	dx
	ret
OpenGetLineBounds	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecGetDisplayScheme

DESCRIPTION:	Return display scheme -- this routine is possible in this
		specific UI because it will only work on one display & in
		one font style at a time.  Not exactly flexible, but darn
		fast.  Allows us to compete with the big guys on low-end
		systems.

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	al - DS_colorScheme	
	ah - DS_displayType
	bx - unused
	cx - fontID
	dx - point size

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version

------------------------------------------------------------------------------@
DS_unused	equ	<{word}DS_lightColor>
global SpecGetDisplayScheme:far
SpecGetDisplayScheme	proc	far		uses ds
	.enter
	mov	ax, segment specDisplayScheme
	mov	ds, ax
	mov	ax, {word} ds:[specDisplayScheme.DS_colorScheme]
	mov	bx, {word} ds:[specDisplayScheme.DS_unused]
	mov	cx, ds:[specDisplayScheme.DS_fontID]
	mov	dx, ds:[specDisplayScheme.DS_pointSize]
	.leave
	ret

SpecGetDisplayScheme	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenSaveNavigationChar
FUNCTION:	OpenGetNavigationChar

DESCRIPTION:	Call this routine when you are handling a MSG_META_KBD_CHAR
		or MSG_META_FUP_KBD_CHAR, and have decided to execute some
		keyboard navigation function which will move the focus or
		target exclusives. The gainer of the focus/target can then
		call OpenGetNavigationChar to see 1) if the exclusive is
		moving from a keyboard navigation or mouse event, and
		2) which keyboard key was used.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx	= character value from MSG_META_KBD_CHAR data.

RETURN:		ds, si, cx = same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	see how these routines are used and you will understand them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

OpenSaveNavigationChar	proc	far
	push	ds, bp
	mov	bp, segment idata
	segmov	ds, bp
	mov	ds:[lastKbdCharCX], cx
	pop	ds, bp
	ret
OpenSaveNavigationChar	endp

OpenGetNavigationChar	proc	far
	push	ds, bp
	mov	bp, segment idata
	segmov	ds, bp
	mov	cx, ds:[lastKbdCharCX]
	pop	ds, bp
	ret
OpenGetNavigationChar	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjCallSpecNoLock

DESCRIPTION:	Send method to a locked object, when the method needn't be
		sent through the generic or any application master class
		layers.  ASSUMES that the object has a visible master part,
		which is grown (used to test if is a generic object or not)

CALLED BY:	INTERNAL

PASS:
	ax - method
	cx, dx, bp - data to send


RETURN:
	ax, cx, dx, bp - data returned from method call

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
------------------------------------------------------------------------------@

ObjCallSpecNoLock	proc	far
	uses	di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	oldWay			; if not generic, have to do old way

	push	es
	mov	di, segment GenClass
	mov	es, di
	mov	di, offset GenClass
	call	ObjCallSuperNoLock	; call superclass of GenClass
	pop	es
	jmp	short done

oldWay:
	call	ObjCallInstanceNoLock	; Do it the slow way, since not generic,
					; probably doesn't even have other 
					; master parts
done:
	.leave
	ret
ObjCallSpecNoLock	endp

ObjCallPreserveRegs	proc	far	uses cx, dx, bp
	.enter
	call	ObjCallInstanceNoLock
	.leave
	ret
ObjCallPreserveRegs	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VupCreateGState

DESCRIPTION:	Handler for MSG_VIS_VUP_CREATE_GSTATE, this routine is
		stored directly in the class table as the handler for this
		method in all of the specific UI composite object classes.
		Creates a GState based on window current object is in.
		Note that the behavior of this routine is somewhat different
		that ViewCreateDrawGState or ViewCreateCalcGState.

		We intercept this method in order to store
		a DisplayScheme in the private data of the GState, & to
		change the default state to SPUI standards.  Note also that
		we intercept this method at the composite level, as
		opposed to WIN_GROUP level, for speed, since 32-bit
		support in UI areas is not an issue, as it is with the
		default vis behavior.

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisClass
	ax - MSG_VIS_VUP_CREATE_GSTATE

RETURN:
	carry	- set if VUP method found routine to process request
	bp 	- handle of GState
		  Note that in all cases a GState is created, & therefore will
		  have to be destroyed (Using GrDestroyState)

DESTROYED:	
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version

------------------------------------------------------------------------------@
VupCreateGState	proc	far
	call	VisQueryWindow	; Fetch window handle in di
	mov	bp, di		; Pass window in bp to
	GOTO	ViewCreateGState ; Create GState, set attributes according
				; to specific UI, return in bp

VupCreateGState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ViewCreateCalcGState

DESCRIPTION:	Create a graphics state for the current open look object,
		useful for calculation image size, etc. but which has
		no window associated with it

CALLED BY:	OLGlyphDisplayRecalcSize (Open/openGlyphDisplay.asm,
							??? resource)
		OpenWinCalcMinWidth (Open/openGauge.asm, ??? resource)
			(near proc called by OpenWinRecalcSize method handler)

PASS:
	*ds:si	- object to create graphics state for

RETURN:
	carry set	- since used in VUP query
	di, bp - graphics state

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
------------------------------------------------------------------------------@
ViewCreateCalcGState	proc far
	clr	bp			; specify NO window
	FALL_THRU	ViewCreateGState
ViewCreateCalcGState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ViewCreateGState

DESCRIPTION:	Create a graphics state for the current open look object,
		attaching it to the window value passed.

CALLED BY:	ViewCreateCalcGState (see above)
		ViewCreateDrawGState (see below)

PASS:
	*ds:si	- object to create graphics state for
	bp	- window to attach graphics state to

RETURN:
	carry set	- since used in VUP query
	di, bp 	- GState

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@
ViewCreateGState	proc	far
	uses	ax, bx, cx, dx
	.enter

EC <	call	ECCheckLMemObject					>

	mov	di, bp
	call	GrCreateState ; make a graphics state for it (even if no
	mov	bp, di		;	window)

	call	SpecGetDisplayScheme
	call	GrSetPrivateData	; set private data

	; set up the font and style

	clr	ah			; no fractional pointsize
	call	GrSetFont
	mov	al, LE_SQUARECAP	;this will be the default for UI
	call	GrSetLineEnd		;   objects
	.leave
	stc
	ret
ViewCreateGState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ViewCreateDrawGState

DESCRIPTION:	Create a graphics state for the current open look object,
		which uses the current window & current display scheme, &
		is appropriate for drawing through.   Note that the
		behavior of this routine is somewhat different than the
		behavior of MSG_VIS_VUP_CREATE_GSTATE.

CALLED BY:
		OLButtonRedraw (Open/open.asm, ??? resource)
			(called by OLButtonLostActiveExcl, CF resource)
		OLGlyphDisplayDraw (Open/openGlyphDisplay.asm)
			(called by MSG_VIS_DRAW)
		OLSettingRedraw (Open/openSetting.asm)
			(called by OLSettingLostActiveExcl)
		RedrawScrollbar (View/viewScrollbar.asm)
			(called by OLScrollbarScroll)

PASS:
	*ds:si	- object to create graphics state for

RETURN:
	carry set	- since used in VUP query
	di, bp 	- graphics state, or 0 if object not realized

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
------------------------------------------------------------------------------@

ViewCreateDrawGState	proc far
	class	VisClass
				; If object is not realized, then force
				; return of NULL gstate handle (shouldn't
				; be drawing!)

EC <	call	ECCheckLMemObject					>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	OCGSFD_10
	clr	di
	jmp	short OCGSFD_90

OCGSFD_10:
	call	VisQueryWindow	; get window handle that this object is
				;	displayed in
	tst	di
	jz	OCGSFD_90	; if not visible, quit
	mov	bp, di		; pass in bp
	GOTO	ViewCreateGState

OCGSFD_90:
	mov	bp, di		; return GState in bp
	stc
	ret

ViewCreateDrawGState	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLCountStayUpModeMenus

DESCRIPTION:	This routine is called when a UI component decides that
		all of the menus in stay-up-mode should be closed.
		We send a request to the active list to broadcast a method
		to all objects on the application's active list.
		When the method arrives at OLMenuWinClass,
		it forces the dismissal of the menu. As of 6/90, this is
		sufficient to close menus.
		New: 1/30/92 - as menus are not added to the application
		active list, but the primary's active list, this routine has
		been changed accordingly.

CALLED BY:	

PASS:		*ds:si	= instance data for object

RETURN:		bp = the number of menus released

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		We have to use TPD_stackBot as both OLProcessAppStayUpModeMenus
		and GCNListSend borrow stack space.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/92		Added to return a count of menus released.

------------------------------------------------------------------------------@

OLCountStayUpModeMenus	proc	far
	mov	bp, ss:[TPD_stackBot]
	add	ss:[TPD_stackBot], (size EnsureNoMenusInStayUpModeParams)
	push	bp
	clr	ss:[bp].ENMISUMP_menuCount	;initialize menu count
	mov	dx, bp
	mov	cx, ss
	call	OLProcessAppStayUpModeMenus	;process the menus
	call	ReleaseExpressMenu		;and express menus
	pop	bp
	mov	bp, ss:[bp].ENMISUMP_menuCount
	sub	ss:[TPD_stackBot], (size EnsureNoMenusInStayUpModeParams)
	ret
OLCountStayUpModeMenus	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLReleaseAllStayUpModeMenus

DESCRIPTION:	This routine is called when a UI component decides that
		all of the menus in stay-up-mode should be closed.
		We send a request to the active list to broadcast a method
		to all objects on the application's active list.
		When the method arrives at OLMenuWinClass,
		it forces the dismissal of the menu. As of 6/90, this is
		sufficient to close menus.
		New: 1/30/92 - as menus are not added to the application
		active list, but the primary's active list, this routine has
		been changed accordingly.

CALLED BY:	

PASS:		*ds:si	= instance data for object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/92		Broken into pieces.

------------------------------------------------------------------------------@

OLReleaseAllStayUpModeMenus	proc	far
	clr	cx, dx
	call	OLProcessAppStayUpModeMenus
	call	ReleaseExpressMenu
	ret
OLReleaseAllStayUpModeMenus	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLProcessAppStayUpModeMenus

DESCRIPTION:	This routine is called when a UI component decides that
		all of the menus in stay-up-mode should be closed.
		We send a request to the active list to broadcast a method
		to all objects on the application's active list.
		When the method arrives at OLMenuWinClass,
		it forces the dismissal of the menu. As of 6/90, this is
		sufficient to close menus.
		New: 1/30/92 - as menus are not added to the application
		active list, but the primary's active list, this routine has
		been changed accordingly.

CALLED BY:	

PASS:		*ds:si	= instance data for object
		cx:dx = buffer to pass if counting, or null if not counting.

RETURN:		nothing (value in cx:dx updated as needed)

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version
	Doug	6/91		No longer goes through flow, instead is sent
				to application's active list
	brianc	1/92		change to primary's active list
	chris	12/92		Changed to return a count of menus released,
				and also to get my name in here.  I was feeling
				left out. :)

------------------------------------------------------------------------------@

OLProcessAppStayUpModeMenus	proc	far
	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

	push	cx, dx
;	clr	bp				; normal ensure-no-menus
;						;  (born cbh 11/25/92)
;						;  (died cbh 3/17/93)
	push	si
	mov	ax, MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE
	clr	bx, si				; any object on list
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	pop	si
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	call	OpenCallApplicationWithStack
	add	sp, size GCNListMessageParams
	pop	cx, dx
	pop	di
	call	ThreadReturnStackSpace
	ret
OLProcessAppStayUpModeMenus	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	ReleaseExpressMenu

SYNOPSIS:	Nuke any express menus lying around

CALLED BY:	OLCountAllStayUpModeMenus, OLReleaseAllStayUpModeMenus

PASS:		cx:dx -- zero if not counting, else:
			pointer to a word menu count

RETURN:		nothing (value in cx:dx possibly updated)

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/17/93       	Pulled out of DoAllStayUpModeMenus

------------------------------------------------------------------------------@
ReleaseExpressMenu	proc	near
	;
	; Go release the express menu.  The menus will be on the fields (i.e.
	; UI's active list.)
	;
	push	si
	mov	ax, MSG_OL_FIELD_RELEASE_EXPRESS_MENU
	mov	bx, segment OLFieldClass	; for OLFieldClass
	mov	si, offset OLFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	pop	si				; *ds:si = this object
	call	ObjCallInstanceNoLock
	ret
ReleaseExpressMenu	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenCallApplicationWithStack

DESCRIPTION:	Send message to GenApplication object with stack frame
		(possibly crossing from app thread to app's ui thread)

CALLED BY:	GLOBAL (utility)

PASS:		*ds:si	= instance data for object whose GenApplication we
				wish to call with a stack frame
		ax - Method to send to application
		ss:bp - stack data
		dx - size of stack data
		ds - segment of any object block, for fixup

RETURN:		ax, cx, dx, bp - return values
		carry - clear if no call/method not handled
			else, whatever routine is.
		ds - updated to point at segment of same block as on entry

DESTROYED:
		nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/15/92		initial version

------------------------------------------------------------------------------@
OpenCallApplicationWithStack	proc	far
	uses	bx, si, di
	.enter
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	tst	bx				; any?
	clc					; assume not
	jz	noAppObj
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
noAppObj:
	.leave
	ret
OpenCallApplicationWithStack	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenMinimizeIfCGA

SYNOPSIS:	Checks to see if we're on a CGA.

CALLED BY:	utility, OpenCheckIfCGA

PASS:		ax -- value to minimize

RETURN:		ax -- zero if CGA, original value if not.
		carry set if CGA

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@

OpenMinimizeIfCGA	proc	far
	call	OpenCheckIfCGA
	jnc	exit
	mov	ax, 0				;else return zero (no clr!)
exit:
	ret
OpenMinimizeIfCGA	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfCGA

SYNOPSIS:	Checks to see if we're on a CGA without minimizing AX.
		Actually, it's not really CGA, it's both squished and tiny 
		screens.  (See side effects comment below).

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if CGA

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine doesn't REALLY check for very-squished AND tiny.
	It checks for either one being set.  This routine is used
	by two types of callers:  callers that want to know if we're
	on a genuine CGA screen, and callers that want to know if
	we're small (like the Zoomer).

	When we're back on the trunk, and installs are easier, we
	should change this routine to be called OpenCheckIfCGAOrTiny,
	and fix all the calls to it.  Then, the ones that explicitly
	are referring to CGA screens instead of Zoomer/PDA screens
	can be changed to call OpenCheckIfCGA, which would do the
	right thing (test each bit separately).  -stevey 8/10/94

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@
OpenCheckIfCGA	proc	far
	uses ax, ds
	.enter

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	test	ds:[moCS_flags], mask CSF_VERY_SQUISHED	or mask CSF_TINY
	jz	exit				;no, exit with carry clear
	stc
exit:
	.leave
	ret
OpenCheckIfCGA	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfNarrow

SYNOPSIS:	Checks to see if we're on a Narrow without minimizing AX.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if Narrow

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@
if _JEDIMOTIF
OpenCheckIfNarrow	proc	far

	clc

	ret
OpenCheckIfNarrow	endp
else
OpenCheckIfNarrow	proc	far
	uses ax, ds
	.enter
	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	test	ds:[moCS_flags], mask CSF_VERY_NARROW
	jz	exit				;neither, exit with carry clear
	stc
exit:

	.leave
	ret
OpenCheckIfNarrow	endp
endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfLimitedLength

SYNOPSIS:	Checks to see if there's limited length for this composite.

CALLED BY:	utility

PASS:		*ds:si -- a composite

RETURN:		carry set if CGA

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@
OpenCheckIfLimitedLength	proc	far
	uses ax, ds, bx
	.enter
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Vis_offset
	mov	bl, ds:[bx].VCI_geoAttrs

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	mov	al, mask CSF_VERY_SQUISHED or mask CSF_TINY

	test	bl, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	jnz	10$				;vertical, branch
	mov	al, mask CSF_VERY_NARROW
10$:
	test	ds:[moCS_flags], al		;see if flag is set
	jz	exit				;no, exit with carry clear
	stc
exit:
	.leave
	ret
OpenCheckIfLimitedLength	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfBW

SYNOPSIS:	Checks to see if we're on a black-and-white display.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if BW, clear in color

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@
if _ASSUME_BW_ONLY
OpenCheckIfBW	proc	far
	stc
	ret
OpenCheckIfBW	endp

else	; not _ASSUME_BW_ONLY

OpenCheckIfBW	proc	far
	uses ax, ds
	.enter

	mov	ax, segment dgroup
	mov	ds, ax
	test	ds:[moCS_flags], mask CSF_BW
	jz	exit				;skip if not B&W...
	stc
exit:
	.leave
	ret
OpenCheckIfBW	endp

endif	; _ASSUME_BW_ONLY


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfDefaultRings

SYNOPSIS:	Returns carry set if we're allowing default rings to be
		drawn around triggers.

CALLED BY:	utility

PASS:		nothing

RETURN:		zero flag set if allowed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/93       	Initial version

------------------------------------------------------------------------------@

OpenCheckDefaultRings	proc	far
	push	ds, ax	   
	mov	ax, segment olNoDefaultRing 
	mov	ds, ax
	tst	ds:olNoDefaultRing		;sets c=0
	pop	ds, ax
	jnz	exit				;not allowing rings, c=0
	stc
exit:
	ret
OpenCheckDefaultRings	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfMenusTakeFocus

SYNOPSIS:	See if menus should take focus.  This only happens if we're
		in pen-only mode, and there's no keyboard around.

CALLED BY:	FAR

PASS:		nothing

RETURN:		carry set if menus can grab focus away from another object on
		the primary.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/92       	Initial version

------------------------------------------------------------------------------@

OpenCheckIfMenusTakeFocus	proc	far		uses	ax
	.enter
if	PRESERVE_FOCUS_IF_PEN_ONLY and (not _DUI)
	call	SysGetPenMode
	tst	ax
	stc					
	jz	exit				;not penBased, branch

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jnz	canTakeFocus			;kbdOnly, can take focus
	test	al, mask UIBF_NO_KEYBOARD	
	jnz	exit				;noKeyboard set, branch, c=0

canTakeFocus:
	stc
exit:

else
	clc
endif
	.leave
	ret
OpenCheckIfMenusTakeFocus	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfKeyboard

SYNOPSIS:	Checks if noKeyboard is clear or keyboardOnly is set.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if keyboard exists

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 8/93       	Initial version

------------------------------------------------------------------------------@
OpenCheckIfKeyboard	proc	far
	uses	ax
	.enter

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jnz	canTakeFocus			;kbdOnly, can take focus
	test	al, mask UIBF_NO_KEYBOARD	
	jnz	exit				;noKeyboard set, branch, c=0

canTakeFocus:
	stc
exit:
	.leave
	ret
OpenCheckIfKeyboard	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfTiny

SYNOPSIS:	Checks to see if we're on a Tiny without minimizing AX.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if Tiny

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@
OpenCheckIfTiny	proc	far
	uses ax, ds
	.enter

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	test	ds:[moCS_flags], mask CSF_TINY
	jz	exit				;neither, exit with carry clear
	stc
exit:
	.leave
	ret
OpenCheckIfTiny	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckMenusInHeaderOnMax

SYNOPSIS:	Checks to see if we're on a CGA without minimizing AX.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if menus should go in header on maximized windows

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/17/90		Initial version

------------------------------------------------------------------------------@
OpenCheckMenusInHeaderOnMax	proc	far
	uses ax, ds
	.enter

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	test	ds:[olWindowOptions], mask UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS
	jz	exit				;no, exit with carry clear
	stc
exit:
	.leave
	ret
OpenCheckMenusInHeaderOnMax	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckPopOutMenuBar

SYNOPSIS:	Checks to see if we allow pop out menu bar

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if menu bars can pop out

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/18/92		Initial version

------------------------------------------------------------------------------@

OpenCheckPopOutMenuBar	proc	far	uses ax, ds
	.enter

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	test	ds:[olWindowOptions], mask UIWO_POPOUT_MENU_BAR
	jz	exit				;no, exit with carry clear
	stc
exit:
	.leave
	ret
OpenCheckPopOutMenuBar	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfKeyboardOnly

SYNOPSIS:	Checks to see if we're on keyboard only system.

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if keyboard only

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/1/92		Initial version

------------------------------------------------------------------------------@

OpenCheckIfKeyboardOnly	proc	far	uses ax
	.enter

	call	FlowGetUIButtonFlags		;al = UIBF_*
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	exit				;no, exit with carry clear
	stc
exit:
	.leave
	ret
OpenCheckIfKeyboardOnly	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfKeyboardNavigation

SYNOPSIS:	Checks to see providing keyboard navigation

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if providing keyboard navigation

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	8/92		Initial version

------------------------------------------------------------------------------@
OpenCheckIfKeyboardNavigation	proc	far
	uses	ax, ds
	.enter

	mov	ax, segment olWindowOptions
	mov	ds, ax
	test	ds:[olWindowOptions], mask UIWO_KBD_NAVIGATION
	jz	noNavigation
	stc					; set carry if allowing kbd nav
noNavigation:

	.leave
	ret
OpenCheckIfKeyboardNavigation	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfPDA

SYNOPSIS:	Checks to see if we're on a PDA

CALLED BY:	utility

PASS:		nothing

RETURN:		carry set if PDA

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/7/93		Initial version

------------------------------------------------------------------------------@

OpenCheckIfPDA	proc	far
	push	ds, ax	   
	mov	ax, segment olPDA 
	mov	ds, ax
	tst_clc	ds:olPDA		;sets c=0
	pop	ds, ax
	jz	exit			;isn't PDA
	stc				;else is PDA
exit:
	ret
OpenCheckIfPDA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenGetHelpOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get help options

CALLED BY:	UTILITY
PASS:		none
RETURN:		ax - UIHelpOptions
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenGetHelpOptions		proc	far
	uses	ds
	.enter

	mov	ax, segment olHelpOptions
	mov	ds, ax
	mov	ax, ds:olHelpOptions

	.leave
	ret
OpenGetHelpOptions		endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenDoClickSound

SYNOPSIS:	Ensures a click sound, if we're doing that sort of thing.

CALLED BY:	utility

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/11/93		Initial version

------------------------------------------------------------------------------@

OpenDoClickSound	proc	far
	uses	ds, ax
	.enter

	mov	ax, segment specDoClickSound
	mov	ds, ax
	tst	ds:specDoClickSound
	jz	exit
	mov	ax, SST_KEY_CLICK		
	call	UserStandardSound		
exit:
	.leave
	ret
OpenDoClickSound	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenSetGenByte

DESCRIPTION:	Stores a byte of data into generic instance data

CALLED BY:	INTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group
	cl	- byte to store into instance data

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@

OpenSetGenByte	proc	far
	class	GenClass
	push	si
	mov	si, ds:[si]		; point at instance
	add	si, ds:[si].Gen_offset	; get offset to Gen master part
	add	si, bx			; add in offset into gen part
	mov	ds:[si], cl
	pop	si
	GOTO	ObjMarkDirty

OpenSetGenByte	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenSetGenWord

DESCRIPTION:	Store word of data into generic instance data

CALLED BY:	INTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group
	cx	- word to store into instance data

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@
OpenSetGenWord	proc	far
	class	GenClass
	push	si
	mov	si, ds:[si]		; point at instance
	add	si, ds:[si].Gen_offset	; get offset to Gen master part
	add	si, bx			; add in offset into gen part
	mov	ds:[si], cx
	pop	si
	GOTO	ObjMarkDirty

OpenSetGenWord	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenSetDWord

DESCRIPTION:	Stores dword of data into generic instance data,
		marks object as dirty
		(seg:offset, handle:chunk)

CALLED BY:	INTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group
	cx:dx	- dword

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@
OpenSetGenDWord	proc	far
	class	GenClass
	push	si
	mov	si, ds:[si]		; point at instance
	add	si, ds:[si].Gen_offset	; get offset to Gen master part
	add	si, bx			; add in offset into gen part
	mov	ds:[si].handle, cx	; high word
	mov	ds:[si].chunk, dx	; low word
	pop	si
	GOTO	ObjMarkDirty

OpenSetGenDWord	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisCheckIfFullyEnabled

SYNOPSIS:	Looks at some things to figure out if an object is fully 
		enabled. If the object is specifically built, the routine will 
		return the state of the VA_FULLY_ENABLED flag.
		Otherwise it calls the generic routine to look up the entire
		linkage.

CALLED BY:	UTILITY

PASS:		*ds:si -- object in question

RETURN:		carry set if fully enabled

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/14/90		Initial version

------------------------------------------------------------------------------@
VisCheckIfFullyEnabled	proc	far
	class	VisClass
	push	di
	call	VisCheckIfSpecBuilt		;are we specifically built?
	jz	hardWay				;nope, do it the hard way

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	clc					;assume not enabled
	jz	exit				;not enabled, branch
	stc					;else return carry set
exit:
	pop	di
	ret

hardWay	:
	push	cx
	mov	cx, -1				;optimization didn't work, so
						;take no shortcuts this time.
	call	GenCheckIfFullyEnabled		;else call generic routine
	pop	cx
	pop	di
	ret

VisCheckIfFullyEnabled	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetScreenDimensions

SYNOPSIS:	Returns current screen dimensions.

CALLED BY:	UTILITY

PASS:		*ds - object block (fixup-able)

RETURN:		cx -- screen width
		dx -- screen height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/6/92		Initial version

------------------------------------------------------------------------------@
OpenGetScreenDimensions	proc	far
	uses	ax, bx, di, si, bp
	.enter
	push	ds
	mov	ax, segment screenWidth
	mov	ds, ax
	mov	cx, ds:[screenWidth]
	mov	dx, ds:[screenHeight]
	pop	ds
	tst	dx				; cached yet?
	jnz	done				; yes, use it
						; else, fetch and cache
	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN
	call	UserCallSystem			; (needs fixup-able DS)
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_VIS_GET_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cx = width, dx = height
	push	ds
	mov	ax, segment screenWidth
	mov	ds, ax
	mov	ds:[screenWidth], cx
	mov	ds:[screenHeight], dx
	pop	ds
done:
	.leave
	ret
OpenGetScreenDimensions	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCheckIfVerticalScreen

SYNOPSIS:	Checks if screen is taller than wide.

CALLED BY:	UTILITY

PASS:		*ds - object block (fixup-able)

RETURN:		carry set if screen is vertically oriented (taller than wide)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/6/92		Initial version

------------------------------------------------------------------------------@
OpenCheckIfVerticalScreen	proc	far
	uses	cx, dx
	.enter
	call	OpenGetScreenDimensions		; cx = W, dx = H
	cmp	cx, dx				; set C if W < H
	.leave
	ret
OpenCheckIfVerticalScreen	endp




Resident ends

;--------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	SpecSetFlagsOnAllCtrlParents

SYNOPSIS:	Goes up the visual tree, setting the OLCOF_CANT_OVERLAP_KIDS 
		flag in all OLCtrl parents until a win group is hit or the
		flag is found already set.  Could be easily made more general.

CALLED BY:	utility:
		OLGlyphDisplaySpecBuild
		OLTextSpecBuild
		OLPaneSpecBuild

PASS:		*ds:si -- object whose parent we'll check first

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/21/93       	Initial version

------------------------------------------------------------------------------@

SpecSetFlagsOnAllCtrlParents	proc	far
	push	si
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	call	VisSwapLockParent
	push	bx
	
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass
	jnc	done

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_moreFlags, mask OLCOF_CANT_OVERLAP_KIDS
	jnz	done				;already set, done us and parent
						;  already, exit
	
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	done				;at win group, done

	ornf	ds:[di].OLCI_moreFlags, mask OLCOF_CANT_OVERLAP_KIDS
	call	SpecSetFlagsOnAllCtrlParents	;call on parent
	
done:
	pop	bx
	call	ObjSwapUnlock
	
	pop	di
	call	ThreadReturnStackSpace
	pop	si
	ret

SpecSetFlagsOnAllCtrlParents	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ScanFocusTargetHintHandlers

DESCRIPTION:	Process HINT_DEFAULT_FOCUS/TARGET by sending
		MSG_GEN_MAKE_FOCUS/TARGET to the object

CALLED BY:	INTERNAL/GLOBAL/EXTERNAL
		DoAlloc, MemInfoHeap

PASS:		*ds:si	- Generic object to process hints for

RETURN:		cx = 0 if no focus hint, cx non-zero if there is one.

DESTROYED:
	ax, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------- 
	Doug	9/91		Initial version
	brianc	1/8/93		only grab focus/target if fully enabled,
					still return cx, though
------------------------------------------------------------------------------@
ScanFocusTargetHintHandlers	proc	far

	call	ScanTargetHintHandler

	jcxz	afterFocus
EC <	call	VisCheckVisAssumption					>
	call	Build_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	afterFocus
	push	cx
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	pop	cx
afterFocus:
	ret
ScanFocusTargetHintHandlers	endp

; Scan for focus/target hints but only deal with target.
; (Split out from ScanFocusTargetHintHandlers so non-focusable GenView's
; can just do default target.) - Joon (7/12/94)
;
; Pass:		same as ScanFocusTargetHintHandlers
; Return:	same as ScanFocusTargetHintHandlers
;
ScanTargetHintHandler	proc	far
	push	es
	clr	cx, dx			;no focus hint
					;no target hint
					;es:di = hint table
	segmov	es, cs
	mov	di, offset (cs:FocusTargetHintHandlers)
	mov	ax, length FocusTargetHintHandlers
	call	ObjVarScanData
	pop	es

	tst	dx
	jz	afterTarget
EC <	call	VisCheckVisAssumption					>
	call	Build_DerefVisSpecDI
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	afterTarget
	push	cx
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock
	pop	cx
afterTarget:
	ret
ScanTargetHintHandler	endp

;------------------------------------------------------------------------------
; Hint handler table -- Converts default focus & target hints into methods sent
; to the object at *ds:si.
;------------------------------------------------------------------------------

FocusTargetHintHandlers	VarDataHandler \
	<HINT_DEFAULT_FOCUS, offset Build:FocusHintPresent>,
	<HINT_DEFAULT_TARGET, offset Build:TargetHintPresent>

FocusHintPresent	proc	far
	dec	cx
	ret
FocusHintPresent	endp

TargetHintPresent	proc	far
	dec	dx
	ret
TargetHintPresent	endp

if	(0)
FocusTargetMakeFocus	proc	far
	mov	ax, MSG_GEN_MAKE_FOCUS
	call	ObjCallInstanceNoLock
	mov	cx, 0ffh			;say focus found
	ret
FocusTargetMakeFocus	endp

FocusTargetMakeTarget	proc	far
	mov	ax, MSG_GEN_MAKE_TARGET
	push	cx
	call	ObjCallInstanceNoLock
	pop	cx
	ret
FocusTargetMakeTarget	endp
endif

Build ends

MenuSepQuery	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ForwardMenuSepQueryToNextSiblingOrParent

DESCRIPTION:	This procedure forwards the MSG_SPEC_MENU_SEP_QUERY
		method to the next object in the menu.

CALLED BY:	OLButtonMenuSepQuery, OLMenuItemGroupMenuSepQuery

PASS:		*ds:si	= instance data for object
		ch	= MenuSepFlags

RETURN:		*ds:si	= same
		ch	= MenuSepFlags (updated)

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	send this method on to the next node, using the visible tree.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

ForwardMenuSepQueryToNextSiblingOrParent	proc	near	uses	di
	class	VisClass

	.enter

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	;must use visible tree. First try to send to next sibling
	call	VisCallNextSibling	;returns carry set if handled
	jc	done

sendToParent:
	;send to parent, indicating that we want the parent to send this
	;method on to its visible sibling

	ORNF	ch, mask MSF_FROM_CHILD
	call	VisCallParent		;returns carry set if handled

done:
	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
ForwardMenuSepQueryToNextSiblingOrParent	endp

MenuSepQuery ends

;---------------------

Utils segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenDrawObject

SYNOPSIS:	Redraws an open look object.  Useful for when you want to
		redraw your object outside the draw method.

CALLED BY:	FAR

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/89	Initial version

------------------------------------------------------------------------------@
OpenDrawObject	proc	far
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT	;tell it to draw
	call	ObjCallInstanceNoLock

	.leave
	ret
OpenDrawObject	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenGetPtrImage

DESCRIPTION:	Get standard OL ptr image

CALLED BY:

PASS:	cl	- image to use.  Current one of:
			OLPI_NONE
			OLPI_BASIC
			...		(Depends on specific UI, see
					 cConstant.def)
		(See cConstant.def for latest list.)

RETURN: cx:dx	- optr to PointerDef

DESTROYED:
	Nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@
OpenGetPtrImage	proc	far

	cmp	cl, OLPI_NONE	; requesting no pointer?
	jne	realPointer	; if not, continue
	clr	cx, dx			; else pass NULL
	jmp	short done

realPointer:
	push	bx
	mov	bl, cl
	clr	bh
	shl	bx, 1		; * 2 for word table
	mov	dx, cs:[bx].pointerTable	; fetch chunk offset
if ANIMATED_BUSY_CURSOR
	cmp	dx, offset pBusy
	jne	notBusy
	push	ds
	mov	ax, segment dgroup
	mov	ds, ax
	call	TimerGetCount
if (NUM_BUSY_CURSOR_FRAMES eq 4)
	andnf	ax, (NUM_BUSY_CURSOR_FRAMES-1) shl 4
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
elseif (NUM_BUSY_CURSOR_FRAMES eq 8)
	andnf	ax, (NUM_BUSY_CURSOR_FRAMES-1) shl 3
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
else
	ErrMessage	"Define time base for busy cursor animation"
endif
	pop	ds
	shl	ax, 1		; ax = index into one of busy cursors frames
if (not (_MOTIF or _PM)) or _JEDIMOTIF
	ErrMessage	"Please define busy cursor animation frames in cutilsVariable.def"
endif
	add	dx, ax
notBusy:
endif
	mov	cx, handle PointerImages	; & handle
	pop	bx

done:
	ret
OpenGetPtrImage	endp


;
;	Tables for which cursor to use for each OLPtrImage constant.
;	Values are offsets to chunks within the PointerImages resource
;	(Currently in cutilsVariable.def file)
;
;	NOTE:  If this is changed, corresponding table in cConstant.def
;	must be changed.
;

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

pointerTable	label	word
	word	0			; OLPI_NONE
	word	offset pBasic		; OLPI_BASIC
	word	offset pBusy		; OLPI_BUSY
	word	offset pModal		; OLPI_MODAL
	word	offset pScroll		; OLPI_SCROLL

endif		;END of OPEN LOOK specific code -------------------------------


if _CUA_STYLE and (not _MOTIF) and (not _PM)	;-------------------------------

pointerTable	label	word
	word	0			; OLPI_NONE
	word	offset pBasic		; OLPI_BASIC
	word	offset pBusy		; OLPI_BUSY
	word	offset pModal		; OLPI_MODAL
	word	offset pResizeHoriz	; OLPI_RESIZE_HORIZ
	word	offset pResizeVert	; OLPI_RESIZE_VERT
	word	offset pResizeUpDiag	; OLPI_RESIZE_UP_DIAG
	word	offset pResizeDownDiag	; OLPI_RESIZE_DOWN_DIAG

endif		;--------------------------------------------------------------


if _MOTIF or _PM	;-------------------------------------------------------

pointerTable	label	word
	word	0			; OLPI_NONE
	word	offset pBasic		; OLPI_BASIC
	word	offset pX		; OLPI_X
	word	offset pCrosshairs	; OLPI_CROSSHAIRS
	word	offset pBusy		; OLPI_BUSY
	word	offset pModal		; OLPI_MODAL
	word	offset pMove		; OLPI_MOVE
	word	offset pResizeLeft	; OLPI_RESIZE_LEFT
	word	offset pResizeRight	; OLPI_RESIZE_RIGHT
	word	offset pResizeUp	; OLPI_RESIZE_UP
	word	offset pResizeDown	; OLPI_RESIZE_DOWN
	word	offset pResizeUpLeftDiag	; OLPI_UPL_DIAG
	word	offset pResizeUpRightDiag	; OLPI_UPR_DIAG
	word	offset pResizeDownLeftDiag	; OLPI_DOWNL_DIAG
	word	offset pResizeDownRightDiag	; OLPI_DOWNR_DIAG

endif		;--------------------------------------------------------------

if _MAC and FALSE;-------------------------------------------------------------

pointerTable	label	word
	word	0			; OLPI_NONE
	word	offset pBasic		; OLPI_BASIC
	word	offset pBusy		; OLPI_BUSY

endif		;--------------------------------------------------------------




COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenSetPtrImage

DESCRIPTION:	Set ptr image to an OPEN LOOK standard ptr

CALLED BY:

PASS:	cl	- image to use.  Current one of:
			OLPI_NONE
			OLPI_BASIC
			...		(Depends on specific UI, see
					 cConstant.def)
		(See cConstant.def for latest list.)

	ch	- PtrImageLevel  (see Include/Internal/im.def)
	di	- If PtrImageLevel is PIL_GADGET or PIL_WINDOW,
		  window to set ptr image on

RETURN:
	Nothing

DESTROYED:
	Nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OpenSetPtrImage	proc	far
	uses	cx, dx, bp
	.enter
	mov	dl, ch
	clr	dh
	mov	bp, dx		; Pass PtrImageLevel value in bp

	call	OpenGetPtrImage	; Call above routine to get image to use

	cmp	bp, PIL_GADGET
	je	setInWindow
	cmp	bp, PIL_WINDOW
	jne	setInIM

setInWindow:
	tst	di		; if null window, skip
	jz	afterWin
	call	WinSetPtrImage
afterWin:
	jmp	short done

setInIM:
	call	ImSetPtrImage	; set the pointer image
done:
	.leave
	ret
OpenSetPtrImage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenTestIfFocusOnTextEditObject

DESCRIPTION:	Tests if the focus exclusive in this WIN_GROUP is on a
		text-edit object.

CALLED BY:	OLButtonMouse, etc.

PASS:		*ds:si	= instance data for object

RETURN:		carry set if not on text object, and gadget can request the 
		focus.

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version

------------------------------------------------------------------------------@

OpenTestIfFocusOnTextEditObject	proc	far	
if TAKE_FOCUS_FROM_TEXT_OBJECT
	;
	; indicate that we can take focus
	;
	stc
else
	class	GenViewClass		;can deal with view instance data

	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	call	VisCallParent
EC <	ERROR_NC OL_ERROR		;abort if query not answered	>

	tst	cx			;is focus on anything?
	LONG jz	returnComplementedCarry	;skip if not (cy=0)...

	test	ax, mask MAEF_OD_IS_WINDOW
	LONG jnz returnComplementedCarry	;skip if is window: TAKE FOCUS (cy=0)...

	;if is subclass of VisTextClass, then DO NOT grab focus!

	push	bx, si, ds
	mov	bx, cx
	call	ObjLockObjBlock
	push	bx
	mov	ds, ax
	mov	si, dx			;*ds:si = focused object
	mov	di, segment VisTextClass
	mov	es, di
	mov	di, offset  VisTextClass
	call	ObjIsObjectInClass
	jc	returnComplementedCarryAndUnlock  ;skip if is member of class...

	;if is GenViewClass, can grab focus unless it's running a text object
	;or it's non-generic.

	mov	di, segment GenViewClass
	mov	es, di
	mov	di, offset  GenViewClass
	call	ObjIsObjectInClass
	jnc	returnComplementedCarryAndUnlock    ;not a view, branch, is OK

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS
;	stc
; This is wrong, if there aren't generic contents, we want
; to allow the calling gadget to be able to take the focus
; - brianc 4/25/95
	clc
	jz	returnComplementedCarryAndUnlock	;not generic, branch,
							;can't take focus

	movdw	bxsi, ds:[di].GVI_content
EC <	tst	bx							>
EC <	jz	noContent						>
EC <	call	ObjTestIfObjBlockRunByCurThread				>
EC <	ERROR_NZ	OL_ERROR					>
EC <noContent:								>
	clr	cx
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;content's child in ^lcx:dx
	cmc					;flip: carry clear if no child
	jnc	returnComplementedCarryAndUnlock	;no first child, exit,
							;  can take focus
	movdw	bxsi, cxdx
	mov	cx, segment VisTextClass
	mov	dx, offset  VisTextClass
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjMessage			;returns carry set if text disp
						;  so we can't grab focus.

returnComplementedCarryAndUnlock:
	pop	bx
	call	MemUnlock
	pop	bx, si, ds

returnComplementedCarry: ;return carry set if in not in either class,
			 ;and so can grab focus

	cmc
endif	; TAKE_FOCUS_FROM_TEXT_OBJECT
	ret
OpenTestIfFocusOnTextEditObject	endp

				
				
			


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenSetInsetRectColors

SYNOPSIS:	Sets typical motif inset rect colors, depending on display.

CALLED BY:	OLTextDisplayDraw, DrawColorPortWindow

PASS:		nothing

RETURN:		bp low 	-- top/left color to use
		bp high -- right/bottom color to use
		gstate's area color -- color to fill inside of rect with

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/21/91		Initial version

------------------------------------------------------------------------------@

if	_MOTIF or _PM		;currently only used by motif and pm
	
OpenSetInsetRectColors	proc	far		uses ax, es
	.enter
	mov	bp, segment moCS_flags
	mov	es, bp
	mov	bp, (C_BLACK shl 8) or C_BLACK	; assume B/W, TLRB are all black
	mov	ax, C_WHITE			; fill color
	test	es:[moCS_flags], mask CSF_BW
	jnz	setFillColor			; not color, exit
	mov	ah, C_WHITE			; right/bottom color
	mov	al, es:[moCS_dsDarkColor]	; right/bottom color
	mov	bp, ax
	
	clr	ax				; assume we want to clear out
	mov	al, es:[moCS_dsLightColor]	;   the inside of the text with
	
setFillColor:
	call	GrSetAreaColor			;   the background color
	.leave
	ret
OpenSetInsetRectColors	endp

endif
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenDrawRect

SYNOPSIS:	Draws an motif inset rectangle, using the colors specified.
		If you want typical colors, call SetInsetRectColors
		before calling this routine.  Will be drawn in 50% pattern
		if disabled visually.  Does not fill inside of rectangle.

CALLED BY:	OLTextDisplayDraw, DrawColorPortWinodw

PASS:		*ds:si 		-- object (used to test VA_FULLY_ENABLED bit)
		di     		-- gstate
		ax, bx, cx, dx  -- rectangle bounds, as if doing GrFillRect
		bp low		-- top/left color to use
		bp high		-- right/bottom color to use

RETURN:		nothing

DESTROYED:	ax, bx, bp, until someone needs them preserved...

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/21/91		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if	_MOTIF or _PM
	
OpenDrawRect	proc	far		uses	si
	.enter
	call 	SetupDraw
	call	DrawFrame
	.leave
	ret
OpenDrawRect	endp
	
endif
	

COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenDrawAndFillRect

SYNOPSIS:	Draws an motif inset rectangle, using the colors specified.
		If you want typical colors, call SetInsetRectColors
		before calling this routine.  Will be drawn in 50% pattern
		if disabled visually.  Also clears the inside of the frame
		in the color previously set in GrSetAreaColor.

CALLED BY:	OLTextDisplayDraw, DrawColorPortWinodw

PASS:		*ds:si 		-- object (used to test VA_FULLY_ENABLED bit)
		di     		-- gstate
		ax, bx, cx, dx  -- rectangle bounds, as if doing GrFillRect
		bp low		-- top/left color to use
		bp high		-- right/bottom color to use
		cur area color  -- color to use to fill inside with

RETURN:		nothing

DESTROYED:	ax, bx, bp, until someone needs them preserved...

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/21/91		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if	_MOTIF or _PM
	
OpenDrawAndFillRect	proc	far	uses	si
	.enter
	call	SetupDraw			;sets up 50% pattern, etc.
	call	GrFillRect			;fill inside with current color
	call	DrawFrame			;draws the frame
	.leave
	ret
OpenDrawAndFillRect	endp
				
endif

				

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenDrawInsetAndFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw frame and inset

CALLED BY:	EXTERNAL
			OLTextDraw
PASS:		*ds:si = object
		ax, bx, cx, dx = bounds to start with
		pushed on stack in this order:
			high byte		low byte
			---------		--------
		1)	(DrawInsetAndFrameFlags)(DrawStyle)
		2)	(frame width)		(inset width)
		di = gstate
		wash color set in gstate
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DRAW_STYLES

OpenDrawInsetAndFrame	proc	far	frameInsetWidths:word,
					frameAndStyle:word

	.enter
	;
	; if frame or not flat, wash
	;
	test	frameAndStyle.high, mask DIAFF_NO_WASH
	jnz	noWash
	test	frameAndStyle.high, mask DIAFF_FRAME
	jnz	washBG
;wash when flat, I don't remember why we didn't before -- brianc 9/20/96
;	cmp	frameAndStyle.low, DS_FLAT
;	je	noWash
washBG:
	call	GrFillRect
noWash:
	;
	; if frame and (flat or raised), draw frame
	;
	test	frameAndStyle.high, mask DIAFF_FRAME
	jz	noOuterFrame
	test	frameAndStyle.high, mask DIAFF_FRAME_OUTSIDE
	jnz	outerFrame
	cmp	frameAndStyle.low, DS_LOWERED
	je	noOuterFrame
outerFrame:
	call	drawBlackFrame
	dec	frameInsetWidths.high
	jnz	outerFrame
noOuterFrame:
	;
	; draw inset (lowered) or outset (raised)
	;
	cmp	frameAndStyle.low, DS_FLAT
	je	noInset
drawInset:
	push	bp
	push	ax
	call	getDarkColor		; al = dark color
	mov	ah, al			; raised -> dark bottom/right
	mov	al, C_WHITE		; raised -> white top/left
	cmp	frameAndStyle.low, DS_RAISED
	je	haveInsetColor
	xchg	al, ah			; lowered colors
haveInsetColor:
	mov	bp, ax
	pop	ax
	call	drawFrame
	call	insetBounds
	pop	bp
	dec	frameInsetWidths.low
	jnz	drawInset
noInset:
	;
	; if frame and lowered, draw frame
	;
	test	frameAndStyle.high, mask DIAFF_FRAME
	jz	noInnerFrame
	test	frameAndStyle.high, mask DIAFF_FRAME_OUTSIDE
	jnz	noInnerFrame
	cmp	frameAndStyle.low, DS_LOWERED
	jne	noInnerFrame
innerFrame:
	call	drawBlackFrame
	dec	frameInsetWidths.high
	jnz	innerFrame
noInnerFrame:
	.leave
	ret	@ArgSize

drawFrame	label	near
	push	ax, bx, bp
	call	OpenDrawRect
	pop	ax, bx, bp
	retn

drawBlackFrame	label	near
	push	bp
	mov	bp, (C_BLACK shl 8) or C_BLACK		; black frame
	call	drawFrame
	call	insetBounds
	pop	bp
	retn

insetBounds	label	near
	inc	ax
	inc	bx
	dec	cx
	dec	dx
	retn

getDarkColor	label	near
	push	es
	mov	ax, dgroup
	mov	es, ax
	mov	al, es:[moCS_dsDarkColor]
	pop	es
	retn
OpenDrawInsetAndFrame	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDraw

SYNOPSIS:	Sets up 50% pattern if necessary, clears some bits in frame.

CALLED BY:	OpenDrawAndFillRect, OpenDrawRect

PASS:		*ds:si 		-- object (used to test VA_FULLY_ENABLED bit)
		di     		-- gstate
		ax, bx, cx, dx  -- rectangle bounds, for a GrFillRect
		bp low		-- top/left color to use
		bp high		-- right/bottom color to use
		cur area color  -- color to use to fill inside with

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/22/91		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if	_MOTIF or _PM
	
SetupDraw	proc	near
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	test	ds:[si].VI_attrs, mask VA_FULLY_ENABLED
	jnz	10$				; text is enabled, branch
	;
	; Clear a one pixel swath around the outside in case we're making the
	; transition from enabled to disabled.
	;
	push	ax
	push	es
	mov	ax, segment moCS_dsLightColor
	mov	es, ax
	clr	ax
	mov	al, es:[moCS_dsLightColor]	; get light color
	call	GrSetLineColor			; clear area around text
	mov	al, SDM_50 or mask SDM_INVERSE	; clear out offending pixels
	call	GrSetLineMask
	pop	es
	pop	ax
	dec	cx				; adjust for line drawing
	dec	dx
	call	GrDrawRect			; clear frame around the outside
	inc	cx				; restore 
	inc	dx
	;
	; The new lines will be drawn in a 50% pattern.
	;
	push	ax
	mov	al, SDM_50			; else draw everything 50%
	call	GrSetLineMask
	pop	ax
10$:
	push	ax
	mov	ax, bp				; set up left/top line color
	clr	ah
	call	GrSetLineColor
	pop	ax
	ret
SetupDraw	endp

endif				


COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawFrame

SYNOPSIS:	Draws the frame.

CALLED BY:	OpenDrawRect, OpenDrawAndFillRect

PASS:		*ds:si 		-- object (used to test VA_FULLY_ENABLED bit)
		di     		-- gstate
		ax, bx, cx, dx  -- rectangle bounds, for a GrFillRect
		bp low		-- top/left color to use
		bp high		-- right/bottom color to use

RETURN:		nothing

DESTROYED:	ax, bx, bp, until someone carea

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/22/91		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions


------------------------------------------------------------------------------@
	
if	_MOTIF	;---------------------------------------------------------------

DrawFrame	proc	near
if _ODIE
	push	si
	mov	si, bp				; si high = right/bottom color
endif
	dec	cx				; adjust for line drawing
	dec	dx		
	call	GrDrawVLine			; draws left line
	call	GrDrawHLine			; draws top line
	
	push	ax				; save left edge
	mov	ax, bp				; get right/bottom color
	mov	al, ah
	clr	ah
	call	GrSetLineColor			; set as line color
	
	cmp	al, C_WHITE			; are we about to draw white?
	mov	ax, cx				; (doing right edge)
	jne	20$				; no, branch
	inc	bx				; else back off at top
	pop	bp				;   and left edge
	inc	bp				;   to prevent excessive 
	push	bp				;   bleeding
20$:
if _ODIE
	push	bx
	test	si, (3 shl 8)			; bad hack: (white & !dk gray)?
	jnz	30$				; yes, don't adjust
	inc	bx				; allow top line precedence
30$:
	call	GrDrawVLine
	pop	bx
else
	call	GrDrawVLine
endif
	pop	ax				; restore left edge
	mov	bx, dx				; doing bottom  line
if _ODIE
	push	ax
	test	si, (3 shl 8)			; bad hack: (white & !dk gray)?
	jnz	40$				; yes, don't adjust
	inc	ax				; allow left line precedence
40$:
	call	GrDrawHLine			;
	pop	ax
else
	call	GrDrawHLine			;
endif
	
	push	ax
	mov	al, SDM_100			; fix up everything
	call	GrSetLineMask
	pop	ax
	inc	cx
	inc	dx
if _ODIE
	pop	si
endif
	.leave
	ret
DrawFrame	endp

endif		; if _MOTIF ----------------------------------------------------
	
if _PM		;---------------------------------------------------------------

DrawFrame	proc	near
	dec	cx				; adjust for line drawing
	dec	dx		
	call	GrDrawVLine			; draws left line
	call	GrDrawHLine			; draws top line
	
	push	ax				; save left edge
	mov	ax, bp				; get right/bottom color
	mov	al, ah
	clr	ah
	call	GrSetLineColor			; set as line color

	mov	ax, cx				; (doing right edge)
	inc	bx				; back off at top
	call	GrDrawVLine

	pop	ax				; (doing bottom edge)
	mov	bx, dx
	call	GrDrawHLine

	mov	al, SDM_100			; fix up everything
	call	GrSetLineMask
	inc	cx
	inc	dx
	.leave
	ret
DrawFrame	endp

endif		; if _PM -------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenEnsureGenParentIsOLWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC-only utility routine to check assumption that generic
		parent is an OLWin object.

CALLED BY:	EXTERNAL (HINT_SEEK_TITLE_BAR_{LEFT,RIGHT} things)
			OLButtonInitialize
			OLButtonVisUnbuildBranch

PASS:		*ds:si = object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
OpenEnsureGenParentIsOLWin	proc	far
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	;
	; force to build out (the OLWin message we will send will force this
	; anyway)
	;
	call	GenFindParent			; ^lbx:si = parent
	tst	bx
	ERROR_Z	SEEK_TITLE_BAR_PARENT_MUST_BE_DIRECT_CHILD_OF_WINDOW
	mov	ax, MSG_META_DUMMY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, segment OLWinClass
	mov	dx, offset OLWinClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ERROR_NC	SEEK_TITLE_BAR_PARENT_MUST_BE_DIRECT_CHILD_OF_WINDOW
	.leave
	ret
OpenEnsureGenParentIsOLWin	endp
endif

Utils ends

;==============================================================================
;		TINY UTILITY ROUTINES
;==============================================================================

Build	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	Build_DerefVisSpecDI

DESCRIPTION:	utility routine to dereference *ds:si to find the VisSpec
		instance data in an object.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same
		ds:di	= VisSpec instance data

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version (adapted from Tony's version)

------------------------------------------------------------------------------@

Build_DerefVisSpecDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
Build_DerefVisSpecDI	endp

Build_DerefGenDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
Build_DerefGenDI	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	Build_CallCopyTreeSameBlockNoAddNoFlags
		Build_CallCopyTreeSameBlockNoFlags
		Build_CallCopyTreeSameBlock

DESCRIPTION:	Call MSG_GEN_COPY_TREE to copy into same block

PASS:
	ds - block to copy into
	^lbx:si - tree to copy
	Build_CallCopyTreeSameBlockNoFlags: dx = chunk handle to add to

RETURN:
	ds - same block (possibly moved)
	^lcx:dx - handle of object

DESTROYED:
	ax, dx, di, bp

------------------------------------------------------------------------------@


Build_CallCopyTreeSameBlockNoAddNoFlags	proc	near
	clr	dx
	FALL_THRU	Build_CallCopyTreeSameBlockNoFlags
Build_CallCopyTreeSameBlockNoAddNoFlags	endp

Build_CallCopyTreeSameBlockNoFlags	proc	near
	clr	bp
	FALL_THRU	Build_CallCopyTreeSameBlock
Build_CallCopyTreeSameBlockNoFlags	endp

Build_CallCopyTreeSameBlock	proc	near
	mov	cx, ds:[LMBH_handle]	;block to copy into
	mov	ax, MSG_GEN_COPY_TREE
	FALL_THRU	Build_ObjMessageCallFixupDS
					;returns cx:dx = handle of object
Build_CallCopyTreeSameBlock	endp

;---

Build_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	Build_ObjMessage
Build_ObjMessageCallFixupDS	endp

;This saves bytes because it can be called with a near call, which is fewer
;bytes that a far-call.

Build_ObjMessage	proc	near
	call	ObjMessage
	ret
Build_ObjMessage	endp

;--------

Build_CallGenSetUsableViaUIQueue	proc	near
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	FALL_THRU	Build_ObjCallInstanceNoLock
Build_CallGenSetUsableViaUIQueue	endp

;This saves bytes because it can be called with a near call, which is fewer
;bytes that a far-call.

Build_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
Build_ObjCallInstanceNoLock	endp

;---

Build_CallSpecBuild	proc	near
	mov	ax, MSG_SPEC_BUILD
	GOTO	Build_ObjCallInstanceNoLock
Build_CallSpecBuild	endp

			



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenAddScrollbar

SYNOPSIS:	Adds a scrollbar to the passed object.  Adds it visually
		below this object, at the end of the tree, with an upward 
		generic link.  Attaches its OD to the passed object.  Sets 
		enabled flag appropriately.

CALLED BY:	utility

PASS:		*ds:si -- object to add to
		
		on stack (pushed in this order):
			(word) hint to add
			(word) action method
			(word) high word of minimum
			(word) low word of minimum
			(word) high word of maximum
			(word) low word of maximum
			(word) high word of initial value
			(word) low word of initial value
			(word) high word of increment
			(word) low word of increment
		al     -- inGenTreeFlag:  zero if we want just an upward link, 
					  non-zero if it should be in gentree
		ah     -- immediateUpdateFlag: zero if we want delayed updates
					  on drags, non-zero for immediate
			
RETURN:		dx     -- handle of new scrollbar

DESTROYED:	ax, bx, cx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/91		Initial version

------------------------------------------------------------------------------@

OpenAddScrollbar	proc	far	increment:dword, value:dword,
					maximum:dword, minimum:dword,
					actionMethod:word, 
					hintToAdd:word
	class	GenValueClass
	.enter	
	
	push	si				; save parent
	mov	dx, si				; cx:dx <- parent to add to
	mov	cx, ds:[LMBH_handle]		; 
	mov	di, segment GenValueClass
	mov	es, di
	mov	di, offset GenValueClass

						
	mov	bx, hintToAdd
	ornf	bx, mask VDF_SAVE_TO_STATE	; Dirty first hint

	push	bp
	mov	bp, CCO_LAST			; make last item in tree
	tst	al				; check our flag
	jz	2$				; not to be in gentree, nodirty
	ornf	bp, mask CCF_MARK_DIRTY		; dirty if being put in gentree
2$:
	push	ax
	mov	al, -1				; init USABLE
	clr	ah				; add to parent w/full linkage
						; (So parent will be able
						; to intercept message).  We'll
						; convert to one-way later.
	call	OpenCreateChildObject
	pop	ax				; restore flags
	pop	bp
	pop	si				; restore parent
						; *ds:si = parent
						; *ds:dx = scrollbar
	xchg	si, dx				; now switchem

	;
	; If we need immediate updates on drags, add the appropriate vardata.
	;
	tst	ah				
	jz	3$
	push	ax
	mov	ax, HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION
	clr	cx
	call	ObjVarAddData
	pop	ax
3$:

if not GEN_VALUES_ARE_TEXT_ONLY
	;
	; If a slider, copy over HINT_VALUE_DELAYED_DRAG_NOTIFICATION (if
	; sliders change to default to delayed, copy over immediate hint)
	;	*ds:si = scrollbar
	;	*ds:dx = parent
	;
	cmp	hintToAdd, HINT_SPEC_SLIDER
	jne	notSlider
	push	ax
	xchg	si, dx				; *ds:si = parent
						; *ds:dx = scrollbar
	mov	ax, HINT_VALUE_DELAYED_DRAG_NOTIFICATION
	call	ObjVarFindData
	xchg	si, dx				; *ds:si = scrollbar
						; *ds:dx = parent
	jnc	noHint
	clr	cx
	call	ObjVarAddData
noHint:
	pop	ax
notSlider:
endif

;
;	Switching to having it in the generic tree, so disabling works more
; 	readily.  A HINT_RANGE_THROW_AWAY in the scrollbar will cause it to
;	set itself not usable and free itself when visually unbuilt.
;	If InGenTreeFlag is clear, we'll still remove the downward link.
;
	tst	al				; do we want in generic tree?
	jnz	4$				; yes, branch
	
	;
	; If removing a downward link, we'll clear the dirty bit (for the
	; hell of it) and set the OCF_IGNORE_DIRTY bit, so the object doesn't
	; get saved out to state.  (Fixed 2/19/93 cbh to do this to the 
	; correct object.)
	;
	mov	ax, si				; object in ds:ax
	mov	bx, (mask OCF_DIRTY shl 8) or mask OCF_IGNORE_DIRTY
	call	ObjSetFlags

	push	bp
	clr	bp
	call	GenRemoveDownwardLink		; remove scrollbar from parent
	pop	bp
4$:
						; *ds:si = scrollbar
						; *ds:dx = parent
	mov	di, dx
	push	bp
	clr	bp				; assume parent is disabled
	mov	di, ds:[di]			; get to parent's VisInstance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	10$				; if enabled, pass flag in bp
	mov	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
10$:
	mov	ax, MSG_SPEC_BUILD
	call	ObjCallInstanceSaveDxBp		; visibly build the scrollbar
	pop	bp
	.leave
	;
	; Fall through to set scrollbar attributes (can't have FALL_THRU
	; macro due to stuff on stack, I think.)
	;
	mov	bx, si				; non-zero: can ignore null
						;   attributes in next part.
	REAL_FALL_THRU	OpenSetScrollbarAttrs

OpenAddScrollbar	endp


			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenSetScrollbarAttrs

SYNOPSIS:	Sets various scrollbar attributes, without actually building 
		the thing.

CALLED BY:	utility

PASS:		*ds:si -- scrollbar
		*ds:dx -- OD to send output to
		bx     -- create flag -- set if creating a scrollbar, and thus
					 can avoid sending messages to set
					 attributes to zero.
		
		on stack (pushed in this order):
			(word) orientation:
				-1 if vertical, 0 if horizontal
			(word) action method
			(word) high word of minimum
			(word) low word of minimum
			(word) high word of maximum
			(word) low word of maximum
			(word) high word of initial value
			(word) low word of initial value
			(word) high word of increment
			(word) low word of increment
			
RETURN:		dx     -- handle of new scrollbar

DESTROYED:	ax, bx, cx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/91		Initial version

------------------------------------------------------------------------------@

OpenSetScrollbarAttrs	proc	far	increment:dword, value:dword,
					maximum:dword, minimum:dword,
					actionMethod:word, 
					orientation:word
	.enter	

	mov	cx, ds:[LMBH_handle]		; set OD to parent
	mov	ax, MSG_GEN_VALUE_SET_DESTINATION
	call	ObjCallInstanceSaveDxBp
	
	push	bp
	mov	cx, actionMethod
	mov	ax, MSG_GEN_VALUE_SET_APPLY_MSG
	call	ObjCallInstanceSaveDxBp
	pop	bp

	mov	cx, orientation			; get vertical flag
	mov	ax, MSG_SET_ORIENTATION	; set orientation
	call	ObjCallInstanceSaveDxBp
	
	push	dx
	movdw	dxcx, maximum
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	call	ObjCallInstanceSaveDxBpNotIfZero
	
	movdw	dxcx, minimum
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	call	ObjCallInstanceSaveDxBpNotIfZero

	movdw	dxcx, value
	push	bp
	clr	bp				; not indeterminate
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	call	ObjCallInstanceSaveDxBpNotIfZero ;scroll the scrollbar if needed
	pop	bp

	movdw	dxcx, increment
	mov	dx, increment.high
	mov	ax, MSG_GEN_VALUE_SET_INCREMENT
	call	ObjCallInstanceSaveDxBpNotIfZero ; send to the scrollbar
	
	mov	di, ds:[si]			 ; VisAttrs already set, skip
	add	di, ds:[di].Vis_offset		 ;  sending message 5/17/93 cbh
	mov	dl, ds:[di].VI_attrs
	mov	cx, mask VA_DRAWABLE or mask VA_DETECTABLE or mask VA_MANAGED
	and	dl, cl
	cmp	dl, cl
	je	10$

	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_SET_ATTRS		; make sure attrs are set
	call	ObjCallInstanceSaveDxBp
10$:
	pop	dx
	xchg	si, dx				; return scrollbar in dx
	.leave
	ret	@ArgSize
	
OpenSetScrollbarAttrs	endp

			
			
ObjCallInstanceSaveDxBpNotIfZero	proc	near
	;
	; Pass cx:dx -- value to set if not zero
	;      ax    -- message
	;      bx    -- set if we can ignore zero values
	;
	tst	bx
	jz	sendMessage
	tstdw	dxcx				; zero, we can ignore
	jz	exit
sendMessage:
	call	ObjCallInstanceSaveDxBp
exit:
	ret
ObjCallInstanceSaveDxBpNotIfZero endp

			
ObjCallInstanceSaveDxBp	proc	near
	push	dx, bp
	call	ObjCallInstanceNoLock
	pop	dx, bp
	ret
ObjCallInstanceSaveDxBp endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenBuildNewParentObject

SYNOPSIS:	Called this after OpenCreateNewParentObject to place your object
		underneath it in the generic tree, building as necessary.  An 
		upward-only link is created for the new object.  If a GenView
		is specified as the object, we will create a GenContent, make
		it the output of the view, and place ourselves under the
		content rather than the view.  The new object is placed in the
		generic tree where our passed object was.  Assumes child
		object has not already been SPEC_BUILT.  You should remove
		your child from the visible tree beforehand, if necessary.

CALLED BY:	utility

PASS:		*ds:si -- our object
		*ds:di -- parent object
		ax     -- SpecBuildFlags
		bl     -- view flag -- non-zero if creating a view

RETURN:		ax     -- handle of new object

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 5/92		Initial version

------------------------------------------------------------------------------@

OpenBuildNewParentObject	proc	far
	parent		local	lptr		; created object
	child		local	lptr		; our object
	content		local	lptr		; content, if needed
	buildFlags	local	SpecBuildFlags
	viewFlag	local	byte
	unused		local	byte

	.enter

	mov	viewFlag, bl
	mov	child, si			; STORE handle of child object
	mov	buildFlags, ax
	mov	parent, di			; STORE handle of created obj in
						;   local var.

;------------------------------------------------------------------------------
;	Create object.
;
; 	Store handles of newly created generic objects in local variables
; 	so we can access them later.
;------------------------------------------------------------------------------
	
	;
	; Clear GS_ENABLED flag in parent based on child.  Also the GA_
	; TARGETABLE bit.
	;
	mov	bx, ds:[di]			
	add	bx, ds:[bx].Gen_offset

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jnz	enabled				; text enabled, branch
	and	ds:[bx].GI_states, not mask GS_ENABLED
enabled:
	and	ds:[bx].GI_attrs, not mask GA_TARGETABLE
	test	ds:[di].GI_attrs, mask GA_TARGETABLE
	jz	notTargetable
	or	ds:[bx].GI_attrs, mask GA_TARGETABLE
notTargetable:

;------------------------------------------------------------------------------
;	Create Content object.
;------------------------------------------------------------------------------

	tst	viewFlag			; creating view?
	LONG	jz	noContent		; no, branch

	mov	bx, ds:LMBH_handle		;
						; Get address of class
	mov	di, segment GenContentClass
	mov	es, di
	mov	di, offset GenContentClass
	call	GenInstantiateIgnoreDirty	; Create content.
	mov	content, si			; STORE handle of content obj
						;  in local var.
	mov	bx, offset Gen_offset		;
	call	ObjInitializePart		; Initialize generic part.
	
	mov	bx, offset Vis_offset		;
	call	ObjInitializePart		; Initialize specific part.

	;
	; Init generic data for genparent.
	;
	mov	si, parent			; Prep for View object
	mov	bx, offset Vis_offset		;
	call	ObjInitializePart		; Initialize specific part.
						;
	; Adjust visible bounds for child object here
	; Since we're in a document now, move back to origin.
	;
	push	si
	mov	si, child			; get chunk handle of child obj
	clr	cx, dx
	call	VisSetPosition			; move the text
	pop	si				; parent handle

	mov	ax, ds:LMBH_handle		; Store OD of content object
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GVI_content.handle, ax
	mov	ax, content
	mov	ds:[di].GVI_content.chunk, ax
	
	mov	si, child			; get desired width of child
	call	VisMarkFullyInvalid		; mark invalid (needs updating)
	
	push	cx, dx
	call	VisGetSize
	mov_tr	ax, cx				; keep old width in cx
	pop	cx, dx

	cmp	ax, mask SSS_DATA		; Make sure not too big for
	jbe	setHorizSize			;   SpecSizeSpec
	mov	ax, mask SSS_DATA
	
setHorizSize:
	mov	si, parent
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GVI_docBounds.RD_right.low, ax
						; Set doc width to desired

	;
	; Init data for content object.  Set its attributes
	; so that it will keep its size in line with the subparent size.
	;
	mov	si, content			;
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Gen_offset		; ds:[di] -- GenInstance
	ornf	ds:[di].GI_states, mask GS_USABLE	;set usable
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VCNI_attrs, mask VCNA_SAME_WIDTH_AS_VIEW	

noContent:	

	;
	; Time to start vis building now.
	;
	mov	si, child
	call	VisCheckIfSpecBuilt		; Check for already done.
	LONG jc	OLTDVBV_Done			;

;------------------------------------------------------------------------------
;	Rearrange, setup linkage
;------------------------------------------------------------------------------

	;
	; Add parent object to generic tree next to child obj.
	;
	push	bp				;
						; First, find generic position
						;  of child object
	mov	si, child			; put child obj handle in dx
	call	GenSwapLockParent		; set *ds:si = parent
	push	bx				; save bx (handle
						; of child's block)
						
	pop	cx				; get handle of child
	pop	bp
	mov	dx, child			; find generic position of child
	push	bp
	push	cx				; save on stack again
	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompFindChild		; get position of child in bp
	xchg	ax, bp				; put position in ax 
	inc	ax				; 
	pop	cx				; handle of parent
	pop	bp
	mov	dx, parent			; adding parent
	push	bp
	push	cx				; (save on stack again)
	mov	bp, ax				; pass reference in bp
	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLock
	pop	bx				; restore bx
	call	ObjSwapUnlock
	pop	bp				;
	
	mov	si, parent			; set the parent usable.
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Gen_offset		; ds:[di] -- GenInstance
	or	ds:[di].GI_states, mask GS_USABLE	;set usable
	
;------------------------------------------------------------------------------
;	Visibly add child object to the content object (a little early)
;------------------------------------------------------------------------------

	mov	si, parent
	tst	viewFlag			; making a view?
	jz	dontAddToContent		; no, branch
	mov	si, content			; *ds:si is content
dontAddToContent:

	call	VisCheckIfSpecBuilt		; Check for already done.
	pop	ax				; assume so
	jc	OLTDVBV_Done			;
	
	push	ax				; put ax back on stack
	mov	cx, ds:LMBH_handle		;
	mov	dx, child			; ^lcx:dx is child object
						;
						;
	push	bp				;
	mov	bp, CCO_LAST			; add last
	mov	ax, MSG_VIS_ADD_CHILD	;
	call	ObjCallInstanceNoLock		;
	pop	bp				;
						;
;------------------------------------------------------------------------------
;	Vis Build the parent
;------------------------------------------------------------------------------
	mov	ax, buildFlags			; get SpecBuildFlags
	mov	si, parent			;
	push	bp				;
	mov	bp, ax				; setup SpecBuildFlags
						; Visibly build the parent
	mov	ax, MSG_SPEC_BUILD_BRANCH	;
	call	ObjCallInstanceNoLock		;
	pop	bp				;

	mov	si, parent			; finally, remove downward
	push	bp
	clr	bp
	call	GenRemoveDownwardLink		;   generic link
	pop	bp
	
OLTDVBV_Done:					;
	mov	si, child			; return *ds:si is child obj
	mov	ax, parent			; and *ds:ax as parent
exit:					
	.leave
	ret
OpenBuildNewParentObject	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCreateNewParentObject

SYNOPSIS:	Creates an object and copies moniker and hint over.
		Used with OpenBuildNewParentObject for creating a parent 
		view or composite for an object.  See that routine for more
		details.

CALLED BY:	CreateView, CreateComposite

PASS:		*ds:si -- object to get moniker and hint from
		*es:di  -- class of object to create

RETURN:		*ds:di -- new object

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 2/89		Initial version

------------------------------------------------------------------------------@
OpenCreateNewParentObject	proc	far
	uses 	ax, si, bp
	class	GenClass
	.enter

	mov	bx, ds:[si]			; point to instance
	add	bx, ds:[bx].Gen_offset		; ds:[di] -- GenInstance
	push	ds:[bx].GI_visMoniker		; also save moniker ptr
	
	mov	bx, ds:LMBH_handle
	push	si				; save source chunk
						; Get address of class
	call	GenInstantiateIgnoreDirty	; Create GenInteraction instance
	mov	bx, offset Gen_offset		;
	call	ObjInitializePart		;

	;
	; Copy GenClass hints over.
	;
	pop	di				; *ds:di - source object
	push	es, bp
	segmov	es, ds				; *es:si - new object
	mov	bp, si				; *es:bp - dest. object
	mov	si, di				; *ds:si - source object
	mov	cx, HINT_DUMMY			; copy all Generic hints
	mov	dx, ATTR_GEN_TEXT_STATUS_MSG-1	;  (tho some won't make sense)
	call	ObjVarCopyDataRange
	mov	si, bp				; *ds:si - new object
	pop	es, bp

	mov	ax, HINT_TOOLBOX
	call	ObjVarDeleteData
	;
	; Copy a new moniker up to the parent (don't just use the same moniker
	; chunk, causes update problems!) -cbh 11/ 5/92
	;	
	mov	cx, ds:[LMBH_handle]
	pop	dx				; restore child vis moniker
	tst	dx
	jz	exit				; no moniker, exit
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjCallInstanceNoLock
exit:
	mov	di, si				; return in di
	.leave
	ret
OpenCreateNewParentObject	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenCreateChildTrigger

DESCRIPTION:	Instantiate a GenTrigger class object for the specific UI
		in the same block we're in, marked IGNORE_DIRTY, with a 
		one-way link to the parent (optional), and SPEC_BUILD it.

CALLED BY:	INTERNAL
		OLMenuWinEnsurePinTrigger
		EnsureHeaderGCMIcons

PASS:		*ds:si	- Parent object for trigger
		ax	- actionMessage to set
		bx	- hint to add, if any
		^lcx:dx	- destination to set
		^ldi:bp	- VisMoniker/VisMonikerList for trigger
		carry	- set for one-way link to parent
			- clear for full generic linkage

RETURN:		^lcx:dx	- created trigger object

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version
------------------------------------------------------------------------------@
OpenCreateChildTrigger	proc	far
	uses	ax, bx, si, di, bp, es
	.enter

	;DON'T TRASH CARRY FLAG UNTIL USED BELOW

	;create a GenTrigger object in this block, & add below passed object

	push	di, bp				; save VisMoniker to set

	push	ax				; save action message
	push	cx				; save dest handle
	push	dx				; save dest chunk

	mov	dx, si				; Add object below passed obj
	mov	di, segment GenTriggerClass	; Create a GenTrigger object
	mov	es, di
	mov	di, offset GenTriggerClass
	mov	al, -1				; init w/GENS_USABLE bit set
	mov	ah, al				; one-way upward link
	jc	haveLink			; C set -> one-way link
	mov	ah, 0				; else, full linkage
haveLink:
						; bx = hint to add (pased in)
	mov	cx, ds:[LMBH_handle]		; place in same block
	clr	bp				; CompChildFlags -- not dirty,
						; meaning will be created
						; IGNORE_DIRTY, & thereby tossed
						; out on detach.  (one more
						; reason why a one-way link
						; is needed)
	call	OpenCreateChildObject
	mov	si, dx				; *ds:si is now button

	; Init action message, destination
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; get ptr to GenTriggerInstance
	pop	ds:[di].GTI_destination.chunk	; set dest chunk
	pop	ds:[di].GTI_destination.handle	; set dest handle
	pop	ds:[di].GTI_actionMsg		; set action message

	pop	cx, dx				; get moniker in ^lcx:dx


	; Copy in moniker list for button, & relocate
	;
	push	cx				; save block moniker came from
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjCallInstanceNoLock
	pop	dx				; get source block in dx
						;	for relocation
	; Mark new moniker as IGNORE_DIRTY (Why do we have to do this?  Why
	; doesn't MSG_GEN_REPLACE_VIS_MONIKER_OPTR copy this status from the
	; object when creating the new moniker?
	;
	mov	bl, mask OCF_IGNORE_DIRTY
	clr	bh				; none to clear
	call	ObjSetFlags

	; Send MSG_SPEC_BUILD_BRANCH onto this object, so that it will
	; SPEC_BUILD itself.   The trigger will be initialized ENABLED.
	;
	mov	bp, mask SBF_IN_UPDATE_WIN_GROUP or mask SBF_TREE_BUILD or \
		    mask SBF_VIS_PARENT_FULLY_ENABLED or VUM_NOW
	mov	ax, MSG_SPEC_BUILD_BRANCH
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]		; return object in ^lcx:dx
	mov	dx, si
	.leave
	ret
OpenCreateChildTrigger	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenUnbuildCreatedParent

SYNOPSIS:	Will unbuild an object and its created generic parent, 
		previously added in OpenBuildNewParentObject.  The generic
		parent (and its content, if it's a view) will be destroyed, 
		and the child will be readded visually to its old generic
		parent before being unbuilt itself, to make everything work	
		nicely.

CALLED BY:	utility

PASS:		*ds:si -- object
		*ds:di -- parent object
		bp -- SpecBuildFlags
		bl -- view flag -- non-zero if parent is a view
		ax -- non-zero if we should remove the parent's moniker, zero
		      if we should leave it as is (because it's being
		      shared with the child, and the child will remove it)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/14/92		Initial version

------------------------------------------------------------------------------@

OpenUnbuildCreatedParent	proc	far
	;
	; SO FAR, all vis-unbuilds happen when the object is being set
	; NOT USABLE only, at which time we know the visible & specific
	; instance data will be nuked.  The current implementation of this
	; routine assumes this, as a bunch of additional work will need to
	; go in to figure out how to nuke the composite/view stuff, but be
	; able to restore that state at SPEC_BUILD time.  At such a time
	; that a need is determined for unbuilding while still USABLE, this
	; will have to be fixed.
	;

	; If text object itself is in a visible tree, then release exclusives,
	; then remove it from tree.
	;
	clr	dl				; no update mode now.
	call	VisRemove

	push	si				; Preserve chunk of child

	; See if it is our VIS parent that is unbuilding, & not the generic
	; text object itself.  If this is the case, then we don't want to 
	; set the objects we've created (a possible View & Content arrangement)
	; UNUSABLE at this time, since the Content itself might be being
	; unbuilt at this very moment, & we want to leave it alone until
	; THIS object gets a generic VIS_UNBUILD.  So, skip messing with
	; created kids, & just perform a proper VisUnbuild of the text object.
	;
	test	bp, mask SBF_VIS_PARENT_UNBUILDING
	jnz	ForceTextObjectToBeVisuallyUnderGenericParent

	tst	di				; is there a parent?
	jz	ForceTextObjectToBeVisuallyUnderGenericParent

	tst	bl				; are we unbuilding a view?
	jz	UnbuildParent			; no, branch

	mov	si, di				; *ds:si <- parent view
	push	bp, ax				; save SpecBuildFlags, mkr flag
	mov	ax, MSG_GEN_VIEW_GET_CONTENT
	call	ObjCallInstanceNoLock
	pop	bp, ax				
	push	dx				; save chunk handle of content
	push	ax
	call	OpenDestroyGenericBranch	; Destroy the GenView
	pop	ax
	pop	di				; *ds:di <- content

UnbuildParent:
	mov	si, di
	call	OpenDestroyGenericBranch	; Destroy object in *ds:si

ForceTextObjectToBeVisuallyUnderGenericParent:

	pop	si				; Restore chunk of child

	; NOTE that the following code should cause no problems even if the
	; child itself was not specifically built on entry to this routine,
	; as it will simply be removed again.
	;
	push	bp
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, CCO_LAST
	mov	ax, MSG_VIS_ADD_CHILD
	call	GenCallParent			; Add to our generic parent
	pop	bp				; & fall through to be closed
						; down, visually 
						; removed from parent.  On
						; return to UpdateVisUnbuild,
						; instance data for Vis & Spec
						; will be shrunk back to 0.
;UnbuildJustChild:
						; Now that we have JUST the
						; text object left, visually
						; close it & remove it.
						; (Don't call
						; superclass, as it will
						; try & do the wrong object,
						; using VisGetSpecificVisObj
						; or whatever)

	clr	cx, dx				; nuke the size.  We don't need
						;  this thing invalidated since
	call	VisSetSize			;  the parent was, especially
						;  if the child was in a view
						;  (it will get it's zero-origin
						;  bounds invalidated in the 
						;  primary, which is horrible)

	mov	dx, bp				; Pass vis update mode desired
	call	VisRemove
	ret
OpenUnbuildCreatedParent	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenCreateChildObject

DESCRIPTION:	Instantiates an instance of a generic object specified.
		Will optionally:

			* Init the GS_USABLE bit to "true"
			* Add to passed parent w/full linkage
			* Add to passed parent using one-way linkage only
			* Mark object(s) dirty, or init to be IGNORE_DIRTY.

CALLED BY:	INTERNAL

PASS:		*ds:dx	- parent object (or dx = NULL if object should not
			  be added into any tree)
		es:di  - class of object to create
		al	- non-zero if object should be created and added into
			  tree w/USABLE bit set (as might be needed if 
			  constructing before SPEC_BUILD, or if SPEC_BUILD is
			  going to be sent directly)
		ah	- non-zero to make link to parent a one-way upward link
		bx	- HINT/ATTR to be added (no data), or 0 if none.
			  NOTE:  "mask VDF_SAVE_TO_STATE" should be OR'd in if
				 this hint/attr should be saved to state
		cx	- handle of block to put object in
		bp - CompChildFlags
			if CCF_MARK_DIRTY is set, created generic object
				is marked dirty (so will be saved to state file)
			if CCF_MARK_DIRTY is clear, created generic object
				is marked IGNORE_DIRTY (so that it will be
				tossed out at DETACH time, & not saved to
				state file).  If this option is used, you must
				be careful to make sure that no references to
				this new generic object are stored in
				structures that ARE being saved out to the state
				file, for at re-attach time, those references
				will be invalid.  One such reference to watch
				out for that is non-obvious is the linkage
				between objects; for instance, if you add
				an IGNORE_DIRTY child to a dirty generic parent,
				then the downward link from the parent to the
				child will be invalid if the application is
				stored to state & then re-attached later.  The
				solution is to either disconnect these before
				detach time, or to add the child with a
				one-way, i.e. upward link.  (See
				GenAddChildUpwardLinkOnly)
		     The full CompChildFlags are also passed on to
		     MSG_GEN_ADD_CHILD in the case that the new generic
		     tree is to be added onto a parent generic object (the
		     case if dx is non-zero)

RETURN:		^lcx:dx	- new object

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version
------------------------------------------------------------------------------@
OpenCreateChildObject	proc	far
	uses	ax, bx, si, bp
	.enter
	push	dx			; save parent
	push	ax			; save usable & linkage type flags
	push	bx			; save hint
	mov	bx, cx

	; Create new object
	;
        call    ObjInstantiate

	; Get ready to dinker with it
	;
	call	ObjSwapLock

	push	bx
	; Set either dirty or ignore dirty
	;
	mov	bl, mask OCF_DIRTY	; assume we'll be marking it dirty
	test	bp, mask CCF_MARK_DIRTY
	jne	10$
	mov	bl, mask OCF_IGNORE_DIRTY	; nope, ignore dirty instead
10$:
	clr	bh			; nothing to clear
	mov	ax, si
	call	ObjSetFlags

if _RUDY
	;	
	; If we're using the variant class ComplexMonikerClass,
	; we won't get much further without setting MB_class to GenTriggerClass.
	;
	cmp	di, offset ComplexMonikerClass
	jne	20$
	mov	di, es
	cmp	di, segment ComplexMonikerClass
	jne	20$
	mov	bx, offset ComplexMoniker_offset
	call	ObjInitializePart
	mov	di, ds:[si]			
	add	di, ds:[di].ComplexMoniker_offset
	mov	ds:[di].MB_class.offset, offset GenTriggerClass
	mov	ds:[di].MB_class.segment, segment GenTriggerClass
20$:
endif


	; Make sure generic part grown out, in case we later need to play
	; with instance data.   (In Rudy, we may be passing in a master class
	; here, which makes ObjInitializePart barf, so we'll grow out the
	; instance data via a (useless) generic message.)
	;
	mov	bx, offset Gen_offset
	call	ObjInitializePart
	pop	bx

	; Setup hints/attrs past in
	;
	pop	ax
	tst	ax
	jz	afterHint
        clr     cx                      ; no data
	push	bx
        call    ObjVarAddData		; add first hint
	pop	bx
afterHint:
	pop	ax			; get flags

	mov	cx, ds:[LMBH_handle]
	mov	dx, si			; ^lcx:dx is new object
	call	ObjSwapUnlock
	pop	si			; *ds:si is parent to use (or si = 0
					; for none)
	tst	si
	jz	afterLinkage		; if nothing to add to, we're done.

	push	ax, cx, dx
	tst	ah			; one-way link?
	jz	fullLinkage
;oneWayLinkage:
	mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	jmp	short thisTypeOfLinkage
fullLinkage:
	mov	ax, MSG_GEN_ADD_CHILD	; Add child object, according to flags
thisTypeOfLinkage:
	call	ObjCallInstanceNoLock	; pass in.
	pop	ax, cx, dx

afterLinkage:
	tst	al
	jz	afterUsable
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GI_states, mask GS_USABLE
	call	ObjSwapUnlock
afterUsable:
	
	.leave
	ret
OpenCreateChildObject	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenScanVarData

SYNOPSIS:	Calls ObjVarScanData, but first remove hints under 
		HINT_IF_SYSTEM_ATTRS if conditions are not met.

CALLED BY:	utility

PASS:		*ds:si -- object in question
		ax     - number of VarDataHandlers in table
		es:di  - ptr to a list of VarDataHandlers.  The handler
			routines must be far routines in the same segment
			as the handler table.
		cx, dx, bp - data to pass through variable data handlers

RETURN:		cx, dx, bp - any data after passing through handlers
		ds - updated segment address of object

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/93       	Initial version

------------------------------------------------------------------------------@
if _FXIP
Build	ends
Resident segment resource
endif

OpenScanVarData	proc	far
	push	ax, cx, dx, bp, es, di
	call	RemoveConditionalHintsIfNeeded
	pop	ax, cx, dx, bp, es, di
	call	ObjVarScanData
	ret
OpenScanVarData	endp

if _FXIP
Resident ends
Build segment resource
endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	RemoveConditionalHintsIfNeeded

SYNOPSIS:	Removes hints that are conditional on various system attributes.

CALLED BY:	OpenScanVarData

PASS:		*ds:si -- object to check

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/93       	Initial version

------------------------------------------------------------------------------@
RemoveConditionalHintsIfNeeded	proc	far

	mov	ax, HINT_IF_SYSTEM_ATTRS
	call	ObjVarFindData
	jnc	exit				;no match, exit

EC <	push	ax						>
EC <	VarDataSizePtr	ds, bx, ax				>
EC <	cmp	ax, 2						>
EC <	ERROR_B	OL_HINT_IF_SYSTEM_ATTRS_NO_CONDITIONS		>
EC <	pop	ax						>

	call	CheckIfSystemConditionsMet	;di zero if conditions met
	push	di

	call	FindConditionalHints		;ds:ax <- start of if
						;ds:bx <- end of if
						;ds:cx <- start of else (if any)
						;ds:dx <- end of else (if any)

	pop	di				;di non-zero if conditions met
	pushf					;save whether HINT_ENDIF found

	tst	di
	jz	10$				;conditions not met, branch
	mov	ax, cx				;else we'll be deleting the
	mov	bx, dx				;  "else" branch
10$:
	tst	ax				;ax zero, nothing to be done.
	jz	15$				
	;
	; Delete hints between ds:ax and ds:bx.
	;
	mov	cx, bx
	sub	cx, ax				;amount to delete
	mov	bx, ax				;ds:bx -- starting address
	mov	ax, si				;*ds:ax = object chunk
	sub	bx, ds:[si]			; bx = rel. OFFSET to delete at
	call	LMemDeleteAt
15$:
	popf					;see whether HINT_ENDIF_FOUND
	jnc	20$
	mov	ax, HINT_ENDIF
	call	ObjVarDeleteData
20$:
	mov	ax, HINT_IF_SYSTEM_ATTRS
	call	ObjVarDeleteData		;delete the original attribute

	jmp	short RemoveConditionalHintsIfNeeded	;try next one, if any
exit:
	ret
RemoveConditionalHintsIfNeeded	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfSystemConditionsMet

SYNOPSIS:	Figures out whether conditional hints are met for this object.

CALLED BY:	RemoveConditionalHintsIfNeeded

PASS:		ds:bx -- pointer to system conditions to meet

RETURN:		di -- non-zero if system conditions met

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/93       	Initial version

------------------------------------------------------------------------------@
CheckIfSystemConditionsMet	proc	near
	uses	ds, bx
	.enter

	mov	di, {SystemAttrs} ds:[bx]	;get system attrs to check

EC <	test	di, not mask SystemAttrs				>
EC <	ERROR_NZ	OL_HINT_IF_SYSTEM_ATTRS_BAD_CONDITIONS		>

	mov	ax, segment idata		;get segment of core blk
	mov	ds, ax
	mov	ax, ds:olSystemAttrs		;get system attrs
	test	di, mask SA_NOT			;see if doing NOT
	jnz	negativeCheck			;nope, branch

	and	di, ax				;check stuff we care about
	jmp	short done

negativeCheck:
	and	di, ax				;check stuff we care about
	mov	di, 0
	jnz	done				;anything set, failed (di=0)
	inc	di				;else say match
done:
	.leave
	ret
CheckIfSystemConditionsMet	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	FindConditionalHints

SYNOPSIS:	Returns range of conditional hints for this HINT_IF_.

CALLED BY:	RemoveConditionalHintsIfNeeded

PASS:		*ds:si -- object
		ds:bx -- pointer to extra data for HINT_IF...

RETURN:		ds:ax -- address of start of "if" conditional hints
		ds:bx -- address of end of "if" conditional hints
		ds:cx -- address of start of "else" conditional hints(0 if none)
		ds:dx -- address of end of "else" conditional hints(0 if none)
		carry set if HINT_ENDIF found.

DESTROYED:	bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/93       	Initial version

------------------------------------------------------------------------------@

FindConditionalHints	proc	near		uses	si
	.enter
	;
	; Have ds:si point to end of chunk (and hence end of vardata)
	;
	mov	di, ds:[si]			
	ChunkSizePtr	ds, di, si		
	add	si, di				

	;
	; Point at start of HINT_IF.
	;
	sub	bx, offset VDE_extraData	

	;
	; Set up registers:
	;	ds:bp -- pointer into vardata
	;	ds:ax -- start of "if" section
	;	ds:bx -- end of "if" section
	;	ds:cx -- start of "else" section (zero if none)
	;	ds:dx -- end of "else" section (zero if none)
	;	ds:si -- end of vardata
	;
	mov	bp, bx				;keep pointer in ds:bp
	call	AdvanceToNextHint		;next hint in di, ds:bp updated
	mov	ax, bp				;set as start of if section

EC <	tst	di				;must be one trailing hint!  >
EC <	ERROR_Z	OL_HINT_IF_SYSTEM_ATTRS_NO_HINT_FOLLOWS			     >

	clr	cx, dx				;no else section yet

	cmp	di, HINT_ELSE			;already at else hint?
	je	markDefaultIfEnd		;yes, branch
	cmp	di, HINT_ENDIF			;already at endif hint?
	je	markDefaultIfEnd		;yes, branch
	call	AdvanceToNextHint		;else advance past first hint
						;  following HINT_IF
markDefaultIfEnd:
	mov	bx, bp				;this is the end of our "if"
						;  section if nothing else found

loopEm:
	tst	di				;check out our hint (clrs carry)
	jz	done				;no more, we're all done

	cmp	di, HINT_ELSE			;else encountered?
	jne	checkEndif			;nope, move along
	
	mov	cx, bp				;mark start of else
	call	AdvanceToNextHint		;move to next hint
	mov	bx, bp				;include HINT_ELSE in "if" end
	jmp	short loopEm			;and go do another hint

checkEndif:
	cmp	di, HINT_ENDIF			;endif encountered?
	jne	advanceAndLoop			;nope, advance over hint, loop

;	tst	cx				;have we done an else yet?
;	jz	terminatingIf			;nope, go terminate "if"
	jcxz	terminatingIf
	mov	dx, bp				;else end of "else" section
	jmp	short endEndif

terminatingIf:
	mov	bx, bp				;end of "if" section

endEndif:
	stc					;found an ENDIF
	jmp	short done			;we're done
	
advanceAndLoop:
	call	AdvanceToNextHint		;move to next hint
	jmp	short loopEm			;and loop

done:

EC <	pushf								>
EC <	jcxz	EC10				;no ELSE, branch	>
EC <	tst	dx							>
EC <	ERROR_Z	OL_HINT_IF_SYSTEM_ATTRS_COULDNT_FIND_ENDIF		>
EC <EC10:								>
EC <	popf								>

	.leave
	ret
FindConditionalHints	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	AdvanceToNextHint

SYNOPSIS:	Advances to next hint, returning its type.

CALLED BY:	FindConditionalHints

PASS:		ds:bp -- pointer to current hint
		ds:si -- end of vardata

RETURN:		ds:bp -- pointing at next hint, if any
		di -- hint type, or zero if done

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/93       	Initial version

------------------------------------------------------------------------------@

AdvanceToNextHint	proc	near
	call	GetNextVarDataEntry
	jl	10$				;not past end, branch
	clr	di				;else exit, di=0
	ret
10$:
	mov	di, ds:[bp].VDE_dataType	; ax = data type
	andnf	di, not mask VarDataFlags	; clear flags
	ret
AdvanceToNextHint	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextVarDataEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset to next variable data entry.

CALLED BY:	INTERNAL
			ObjVarFindData
			ObjVarScanData
			ObjVarDeleteDataRange
			ObjVarCopyDataRange

PASS:		ds:bp - variable data entry
		ds:si - end of variable data entry

RETURN:		ds:bp - next variable data entry
		status flags - set for 'cmp entry (bx), end (bp)'
			Z set if end of variable data

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version
	doug	11/91		Optimized a tad

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextVarDataEntry	proc	far
	test	ds:[bp].VDE_dataType, mask VDF_EXTRA_DATA
	jnz	extraData

.assert (size VDE_dataType eq 2)
	inc	bp				; bump to next
	inc	bp
	cmp	bp, si				; reached end?
	ret

extraData:
	add	bp, ds:[bp].VDE_entrySize	; add total size of data entry
	cmp	bp, si				; reached end?
	ret

GetNextVarDataEntry	endp


Build	ends


Unbuild	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenDestroyGenericBranch

DESCRIPTION:	Destroy the generic branch passed.  Do NOT perform any
		visual update on the visual parent of the branch at this time.
		This is useful for destroying objects created with Open
		CreateNewParentObject.

CALLED BY:	utility
		OLScrollListVisUnbuild
		OLTextDisplayVisUnbuild

PASS:
	*ds:si	- top of generic branch to be destroyed
	ax -- non-zero if we're to destroy the parent's moniker, zero if not.

RETURN:

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version
------------------------------------------------------------------------------@
OpenDestroyGenericBranch	proc	far
	uses	bp
	.enter

	tst	si
	jz	done

	; 1) Bring down visually, without visually updating the parent

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	dl, VUM_MANUAL			; let text object itself do
						;	update later.
	; NOTE:  We skip GEN_ version to avoid EC on MANUAL mode.
	; (Hey! We're the specific UI, & we know what's going to happen
	; here..)

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GI_states, not mask GS_USABLE
	push	ax
	mov	ax, MSG_SPEC_SET_NOT_USABLE
 	call	ObjCallInstanceNoLock		; Bring the extra stuff DOWN
	pop	ax

	; 2) Nuke references to the parent's moniker (so that
	; we only end up destroying the CREATED stuff) if ax == 0.

	tst	ax
	jnz	10$
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Gen_offset		; ds:[di] -- GenInstance
	mov	ds:[di].GI_visMoniker, ax	; zero out moniker reference
10$:

	; 3) Finally, destroy the generic branch.
	;
	mov	dl, VUM_NOW			; Won't actually be used,
						; since already not usable
	clr	bp				; don't mark parent dirty
	mov	ax, MSG_GEN_DESTROY
	call	ObjCallInstanceNoLock		; Destroy the generic branch
done:

	.leave
	ret
OpenDestroyGenericBranch	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenNavigateIfHaveFocus

SYNOPSIS:	Navigates away from this object if we have the focus.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/26/92       	Initial version

------------------------------------------------------------------------------@
OpenNavigateIfHaveFocus	proc	far
	uses	ax, cx, dx, bp
	.enter

	mov	cx, SVQT_QUERY_WIN_GROUP_FOR_FOCUS_EXCL
	mov	ax, MSG_VIS_VUP_QUERY
	call	VisCallParent
	jnc	exit			;skip if no visual parent

	cmp	ds:[LMBH_handle], cx	;is the focus on ourselves?
	jne	exit
	cmp	si, dx
	jne	exit			;no, exit

	mov	ax, MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
	call	VisCallParent
exit:
	.leave
	ret
OpenNavigateIfHaveFocus	endp


Unbuild	ends

;================================================

Resident segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetParentBuildFlagsIfCtrl

SYNOPSIS:	Gets parent OLCtrl build flags from the object above us.
		If the parent isn't an OLCtrl, it may do something special
		via a message.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		cx -- OLCtrlBuildFlags, or zero if can't be handled.

DESTROYED:	di, es, ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/11/92		Initial version
	Chris	4/ 9/92		New MSG_VUP_GET_BUILD_FLAGS

------------------------------------------------------------------------------@
OpenGetParentBuildFlagsIfCtrl	proc	far
	mov	ax, MSG_VUP_GET_BUILD_FLAGS
	mov	cx, offset OLCI_buildFlags
	GOTO	OpenGetFlagsIfCtrl

OpenGetParentBuildFlagsIfCtrl	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetParentMoreFlagsIfCtrl

SYNOPSIS:	Gets parent OLCtrlMoreFlags from the object above us.
		If the parent isn't an OLCtrl, it may do something special
		via a message.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		cx -- OLCtrlMoreFlags, or zero if can't be handled.

DESTROYED:	di, es, ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/12/92	Initial version

------------------------------------------------------------------------------@
OpenGetParentMoreFlagsIfCtrl	proc	far
	mov	ax, MSG_VUP_GET_MORE_FLAGS
	mov	cx, offset OLCI_moreFlags
	FALL_THRU	OpenGetFlagsIfCtrl

OpenGetParentMoreFlagsIfCtrl	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetFlagsIfCtrl

SYNOPSIS:	Gets parent OLCtrl flags if some sort from the object above us.
		If the parent isn't an OLCtrl, it may do something special
		via a message.

CALLED BY:	utility

PASS:		*ds:si -- object
		ax -- MSG_VUP_GET_BUILD_FLAGS or MSG_VUP_GET_MORE_FLAGS
		cx -- offset OLCI_buildFlags or offset OLCI_moreFlags

RETURN:		cx -- OLCtrlBuild/MoreFlags, or zero if can't be handled.

DESTROYED:	di, es, ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/11/92		Initial version
	Chris	4/ 9/92		New MSG_VUP_GET_BUILD_FLAGS
	Chris	11/12/92	Changed to allow OLCI_moreFlags as well

------------------------------------------------------------------------------@
OpenGetFlagsIfCtrl	proc	far
	uses	dx, bp, si
	.enter

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	doNothing			;a win group, return nothing

	call	VisSwapLockParent		;let`s do this directly.
	jnc	doNothing

	;
	; Not an OLCtrl, call directly.
	;
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass
	jc	isCtrl				; is an OLCtrl, branch

	clr	cx
	call	ObjCallInstanceNoLock		; send message to self
	jmp	short done
isCtrl:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	add	di, cx
	mov	cx, ds:[di]			; Get the flags
	stc					; return carry set
done:
	call	ObjSwapUnlock
	jmp	short exit			; handled, exit

doNothing:
	mov	cx, 0				
exit:
	.leave
	ret
OpenGetFlagsIfCtrl	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRightArrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the right arrow at the current position, plus
		an offset that is passed in.

CALLED BY:	OpenDrawCtrlMoniker

PASS:		*ds:si -- OLCtrl
		di -- gstate
		cl -- x offset from cur pen pos
		ch -- y offset from cur pen pos

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/17/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY

RudyDrawRightArrow	proc	far		uses	ds, ax, bx, cx, dx, si
	.enter

	mov	ax, SELECTED_TEXT_FOREGROUND
	call	GrSetAreaColor

	call	GrGetCurPos

	add	bl, ch
	mov	ch, 0
	adc	bh, ch				;add y offset to bx

	add	ax, cx				;add x offset to ax

	clr	dx				;no callback
	segmov	ds, cs, si
	mov	si, offset RightMarkBitmap
	call	GrFillBitmap
	.leave
	ret
RudyDrawRightArrow	endp


; Contains RightMarkBitmap
include Art/mkrRightMark.def

endif


Resident ends


CommonFunctional	segment resource
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenCallGenWinGroup

SYNOPSIS:	Calls the generic win group this object is under, if any, 
		with the message specified.

CALLED BY:	utility

PASS:		*ds:si -- object
		ax     -- method to call
		cx, dx, bp -- any arguments to pass

RETURN:		ax, cx, dx, bp -- return args from event

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 6/91		Initial version

------------------------------------------------------------------------------@

if	(0)		; Use quicker CallWinGroup instead!
OpenCallGenWinGroup	proc	far
	push	si
	mov	bx, segment GenClass	;win group must be a generic object
	mov	si, offset GenClass	
	mov	di, mask MF_RECORD 
	call	ObjMessage
	mov	cx, di		; Get handle to ClassedEvent in cx
	pop	si		; Get object 
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	GOTO	VisCallParent
	
OpenCallGenWinGroup	endp
endif

			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetParentWinSize

SYNOPSIS:	Returns size of the window this object is on.

CALLED BY:	utility

PASS:		*ds:si -- object

RETURN:		carry set if window found, with:
			cx, dx -- size of the window area
			bp low -- margins for icons at bottom, if any
			bp high -- margins for icons at right, if any
		carry clear if window not found

DESTROYED:	ax, bx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 6/91		Initial version

------------------------------------------------------------------------------@
OpenGetParentWinSize	proc	far

	clr	cx, dx
	mov	ax, MSG_SPEC_VUP_GET_WIN_SIZE_INFO
	call	VisCallParent
	tst	cx				;no size, exit (carry clear)
	jz	exit
	tst	dx
	jz	exit
	stc					;say window found
exit:
	ret					
OpenGetParentWinSize	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CF_DerefVisSpecDI

DESCRIPTION:	utility routine to dereference *ds:si to find the VisSpec
		instance data in an object.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same
		ds:di	= VisSpec instance data

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version (adapted from Tony's version)

------------------------------------------------------------------------------@

CF_DerefVisSpecDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
CF_DerefVisSpecDI	endp

CF_DerefGenDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
CF_DerefGenDI	endp

;This saves bytes because it can be called with a near call, which is fewer
;bytes that a far-call.

CF_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
CF_ObjCallInstanceNoLock	endp

				

if	(0)	; no one using this optimization yet


COMMENT @----------------------------------------------------------------------

ROUTINE:	CF_SendToTargetObject

DESCRIPTION:

PASS:	*ds:si 	- instance data
	es:di	- superclass

	ax	- TargetObject value that passed hierarchy represents (If
		  ax does not match dx, this routine does nothing)
	bx	- offset to master level
	di	- offset within master instance to optr of next object down
		  in hierarchy, or zero if this object is a leaf, & doesn't
		  store a child optr
	cx 	- handle of classed event.  If Class is null, event should be
	     	  sent directly on to next child in hierarchy
	dx	- TargetObject destination


RETURN:	carry	- set if event handled
	ds - updated to point at segment of same block as on entry

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@

CF_SendToTargetObject	proc	near	uses bx, di, bp
	cmp	ax, dx
	jne	exit

	.enter

	; See if we've reached the leaf or not
	;
	call	CF_FetchOD
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_FIXUP_DS
	call	FlowDispatchSendOnOrDestroyClassedEvent

	.leave

	ret

exit:
	clc
	ret

CF_SendToTargetObject	endp


CF_FetchOD	proc	near
	mov	bp, di			; Get offset
	tst	bp			; interpret offset = 0 as null OD
	jz	null
	mov	di, ds:[si]
	add	di, ds:[di][bx]		; add in master offset
	add	di, bp			; & offset within master
	mov	bx, ds:[di].handle	; fetch the OD, in bx:di
	mov	bp, ds:[di].chunk
	ret
null:
	clr	bx
	ret

CF_FetchOD	endp
endif

CommonFunctional ends

;--------------

Utils segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	SpecCheckIfSpecialUIChar

SYNOPSIS:	Checks to see if a character is one that the UI might like
		to FUP and do something special with.  This is used by the
		view and the FUP mechanism to weed out characters that aren't
		interesting to the specific UI.

CALLED BY:	FAR

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_KBD_CHAR
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState 
		bp high = scan code 

RETURN:		carry set if special character

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/15/91	Initial version

------------------------------------------------------------------------------@

SpecCheckIfSpecialUIChar	proc	far
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_LALT	;left ALT key?	>
DBCS <	cmp	cx, C_SYS_LEFT_ALT			;left ALT key?	>
	je	specialUIChar				;yes, send up
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_RALT	;right ALT key?	>
DBCS <	cmp	cx, C_SYS_RIGHT_ALT			;right ALT key?	>
	je	specialUIChar				;yes, send up
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F10	;F10 key?	>
DBCS <	cmp	cx, C_SYS_F10				;F10 key?	>
	je	specialUIChar

if _JEDIMOTIF
	cmp	cx, (CS_CONTROL shl 8) or VC_PREV_BUTTON
	je	notSpecialUIChar			;to app
	cmp	cx, (CS_CONTROL shl 8) or VC_NEXT_BUTTON
	je	notSpecialUIChar			;to app
endif

	;
if DBCS_PCGEOS
	;
	; Don't FUP FEP stuff:
	;	C_SYS_KANJI ~ C_SYS_KANA_EISUU
	;	C_SYS_ENTER ~ C_SYS_FEP_F10
	;
	cmp	ch, CS_CONTROL_HB
	jne	notFEP
	cmp	cl, C_SYS_KANJI and 0x00ff
	jae	notSpecialUIChar
	cmp	cl, C_SYS_ENTER and 0x00ff
	jb	notFEP
	cmp	cl, C_SYS_LEFT_ALT and 0x00ff
	jb	notSpecialUIChar
notFEP:
endif

	;
	; specific UI doesn't need keypad and buttons
	;
if DBCS_PCGEOS
.assert (C_SYS_JOYSTICK_0 eq C_SYS_JOYSTICK_45-1)
.assert (C_SYS_JOYSTICK_45 eq C_SYS_JOYSTICK_90-1)
.assert (C_SYS_JOYSTICK_90 eq C_SYS_JOYSTICK_135-1)
.assert (C_SYS_JOYSTICK_135 eq C_SYS_JOYSTICK_180-1)
.assert (C_SYS_JOYSTICK_180 eq C_SYS_JOYSTICK_225-1)
.assert (C_SYS_JOYSTICK_225 eq C_SYS_JOYSTICK_270-1)
.assert (C_SYS_JOYSTICK_270 eq C_SYS_JOYSTICK_315-1)
.assert (C_SYS_JOYSTICK_315 eq C_SYS_FIRE_BUTTON_1-1)
.assert (C_SYS_FIRE_BUTTON_1 eq C_SYS_FIRE_BUTTON_2-1)
else
.assert (VC_JOYSTICK_0 eq VC_JOYSTICK_45-1)
.assert (VC_JOYSTICK_45 eq VC_JOYSTICK_90-1)
.assert (VC_JOYSTICK_90 eq VC_JOYSTICK_135-1)
.assert (VC_JOYSTICK_135 eq VC_JOYSTICK_180-1)
.assert (VC_JOYSTICK_180 eq VC_JOYSTICK_225-1)
.assert (VC_JOYSTICK_225 eq VC_JOYSTICK_270-1)
.assert (VC_JOYSTICK_270 eq VC_JOYSTICK_315-1)
.assert (VC_JOYSTICK_315 eq VC_FIRE_BUTTON_1-1)
.assert (VC_FIRE_BUTTON_1 eq VC_FIRE_BUTTON_2-1)
endif
SBCS <	cmp	ch, CS_CONTROL						>
DBCS <	cmp	ch, CS_CONTROL_HB					>
	jne	notKeypad
SBCS <	cmp	cl, VC_JOYSTICK_0					>
DBCS <	cmp	cl, C_SYS_JOYSTICK_0 and 0x00ff				>
	jb	notKeypad
SBCS <	cmp	cl, VC_FIRE_BUTTON_2					>
DBCS <	cmp	cl, C_SYS_FIRE_BUTTON_2	and 0x00ff			>
	jbe	notSpecialUIChar
notKeypad:

	;
	; Only certain releases will be fupped up, to save processing time,
	; since most are unneeded.
	;
	test	dl, mask CF_RELEASE
	jz	10$				;not a release, process char
	cmp	cl, 80h				; Yes, this is gross
						; (Not as gross as putting
						; C_UA_DIERESIS, in my opinion)
	jae	specialUIChar			; FUP any releases of extended
						;   chars (and some control
						;   chars because I'm lazy.)
	jb	notSpecialUIChar		;specific UI doesn't need others
10$:
	;
	; Check to see if this is an accelerator character.  If it is, we may
	; want to send it back instead of forwarding it to the application.
	;
	call	UserCheckAcceleratorChar	;a shortcut, perhaps?
	jnc	notSpecialUIChar		;nope, send to OD
	
	call	UserCheckInsertableCtrlChar	;if insertable ctrl char,
	jc	notSpecialUIChar		;  send to application
	
checkShortcuts:	
	;
	; Reserved text shortcuts are NOT special UI chars.
	;
	push	ds, si
	mov	si, segment textKbdBindings
	mov	ds, si
	mov	si, offset textKbdBindings	;ds:si <- text bindings
	lodsw				 	;ax, bx <- # of entries.
	;				
	; Pass:				
	;  ax	= # of shortcuts in the table.
	;  ds:si	= pointer to the list of shortcuts.
	; Return:			
	;  si	= pointer to the matching shortcut
	;  carry clear if there was no matching shortcut.
	;				
	mov	bx, ax				;Save # of entries in bx.
	mov	di, si				;Save ptr to table start in di.
						;
	call	FlowCheckKbdShortcut		;See if a text shortcut
	DoPop	si, ds
	jnc	specialUIChar			;No, branch
	
notSpecialUIChar:
	clc
	ret
	
specialUIChar:
	stc
	ret
	
SpecCheckIfSpecialUIChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfPointInWinBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if passed point is within the window bounds given
		by the passed GState.

CALLED BY:	Handlers of MSG_META_GET_ACTIVATOR_BOUNDS

PASS:		di	= GState
		ax, bx	= X, Y coordinates to check (in doc coords)

RETURN:		carry:	SET if point IS within bounds
			CLEAR if point IS NOT within bounds

DESTROYED:	cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The idea here is for objects, when returning their "activator
	bounds", will check to see if the point they are returning is
	visible or not.  If it is NOT visible, then the
	MSG_META_GET_ACTIVATOR_BOUNDS handler should return carry clear.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	6/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	 BUBBLE_DIALOGS

CheckIfPointInWinBounds	proc	far
	uses	ax, bx, si
	.enter
	
	mov_tr	bp, ax		; bp, si = X, Y
	mov_tr	si, bx
	
	call	GrGetWinBounds	; AX, BX, CX, DX = win bounds
	cmp	bp, ax		; Ensure Left >= X
	jl	noBounds
	cmp	bp, cx		; Ensure X <= Right (dynamic lists extend to
	jg	noBounds	; the right edge of the window)
	cmp	si, bx		; Ensure Top >= Y
	jl	noBounds
	cmp	si, dx		; Ensure Y < Bottom
	jg	noBounds
	
	stc
done:
	.leave
	ret

noBounds:
	clc
	jmp	done
CheckIfPointInWinBounds	endp

endif	;BUBBLE_DIALOGS

Utils ends

;-----------

CommonFunctional segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenClearToggleMenuNavPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear OLWMS_TOGGLE_MENU_NAV_PENDING of OLBaseWin up the
		tree

CALLED BY:	INTERNAL
			OLDisplaySpecActivateObjectWithMnemonic (if match)
			OLPaneAllowGlobalTransfer
			OpenWinAllowGlobalTransfer

PASS:		*ds:si - object visually under OLBaseWin

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenClearToggleMenuNavPending	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter

	push	si
	mov	bx, segment OLBaseWinClass
	mov	si, offset OLBaseWinClass
	mov	ax, MSG_OL_WIN_CLEAR_TOGGLE_MENU_NAV_PENDING
	mov	di, mask MF_RECORD
	call	ObjMessage			; ^hdi = event
	pop	si
	mov	cx, di				; ^hcx = event
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

	.leave
	ret
OpenClearToggleMenuNavPending	endp
				
CommonFunctional	ends


ListGadgetCommon segment resource

LGC_ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	LGC_ObjMessage
LGC_ObjMessageCallFixupDS	endp

;This saves bytes because it can be called with a near call, which is fewer
;bytes that a far-call.

LGC_ObjMessage	proc	near
	call	ObjMessage		;do not use GOTO!
	ret
LGC_ObjMessage	endp

ListGadgetCommon ends

;==============================================================================

	
Geometry	segment	resource
	
				

COMMENT @----------------------------------------------------------------------

FUNCTION:	Geo_DerefVisDI

DESCRIPTION:	utility routine to dereference *ds:si to find the VisSpec
		instance data in an object.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object

RETURN:		ds, si	= same
		ds:di	= VisSpec instance data

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	6/90		initial version (adapted from Tony's version)

------------------------------------------------------------------------------@

Geo_DerefVisDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
Geo_DerefVisDI	endp

Geo_DerefGenDI	proc	near
EC <	call	ECCheckLMemObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
Geo_DerefGenDI	endp

;This saves bytes because it can be called with a near call, which is fewer
;bytes that a far-call.

Geo_ObjCallInstanceNoLock	proc	near
	call	ObjCallInstanceNoLock
	ret
Geo_ObjCallInstanceNoLock	endp

	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHandleDesiredResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deals with desired resize situations.  Utility for MSG_
		GET_SIZE routines to check for desired resize parameters and
		use desired size if so.

CALLED BY:	utility

PASS:	       	cx  -- width passed to object's resize routine
		dx  -- height passed to object's resize routine
		ax  -- object's desired width
		bx  -- object's desired height

RETURN:		cx  -- width to use
		dx  -- height to use

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHandleDesiredResize	proc	far
	tst	cx			; do we want desired width?
	jns	UCDS20			; no, branch
	mov	cx, ax			; else use desired width
UCDS20:
	tst	dx			; do we want desired height?
	jns	UCDS30			; no, branch
	mov	dx, bx			; else use desired height
UCDS30:
	ret

VisHandleDesiredResize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHandleMinResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps resize values above a minimum.
		Ignores desired resize;  assumes the minimum in that case.
		If your message wants to respond to desired resizes, then
		call VisHandleDesiredResize before calling this routine.
		Also checks to see if we`re passed an optional resize flag.
		If we are, then possibly we use that value (if bp <> 0)
		or the minimum.n

CALLED BY:	Utility

PASS:		ds:*si -- instance data of object
		; Passed into the object's GET_SIZE message:
		cx     -- passed resize width
		dx     -- passed resize height
		
		; Set up by the message handler:
		ax     -- minimum width
		bx     -- minimum height

RETURN:		cx     -- width to use (absolute)
		dx     -- height to use (absolute)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHandleMinResize	proc	far
	andnf	cx, not mask RSA_CHOOSE_OWN_SIZE	; ignore des. size bit
	andnf	dx, not mask RSA_CHOOSE_OWN_SIZE	; (will force minimum)
	
	cmp	cx, ax			; bigger than minimum?
	jae	10$			; yes, branch
	mov	cx, ax			; else use minimum
10$:
	cmp	dx, bx			; bigger than minimum?
	jae	20$			; yes, branch
	mov	dx, bx			; else use minimum
20$:
	ret

VisHandleMinResize	endp

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisHandleMaxResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps resize values below a maximum.  Won't do anything
		about special flags.

CALLED BY:	Utility

PASS:		ds:*si -- instance data of object
		; Passed into the object's GET_SIZE message:
		cx     -- passed resize width
		dx     -- passed resize height
		
		; Set up by the message handler
		ax     -- maximum width
		bx     -- maximum height

RETURN:		cx     -- width to use (absolute)
		dx     -- height to use (absolute)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisHandleMaxResize	proc	far

	cmp	cx, ax			; check against maximum width
	jbe	30$			; not bigger, branch
	mov	cx, ax			; else enforce the maximum
30$:
	cmp	dx, bx			; check against maximum height
	jbe	40$			; not bigger, branch
	mov	dx, bx			; else enforce the maximum
40$:
	ret

VisHandleMaxResize	endp

Geometry	ends


if not _ASSUME_BW_ONLY
DrawColor	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenSetCursorColorFlags
		OpenSetCursorColorFlagsFromColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get focus ring color based on gadget background color

CALLED BY:	EXTERNAL
			DrawColorButton
			ItemDrawColorItem
			DrawColorScrollableItem
PASS:		OpenSetCursorColorFlags:
			*ds:si = object
			al = zero to get unselected color, non-zero for
				selected color
			ah = zero to use object color, non-zero to use
				parent color
		OpenSetCursorColorFlagsFromColor:
			al = color
		cx = initial OLMonikerAttrs
RETURN:		cx = OLMonikerAttrs with background color flags set
			for appropriate cursor color
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CURSOR_ON_BACKGROUND_COLOR

OpenSetCursorColorFlags	proc	far
	uses	ax
	.enter

EC < 	Assert	objectPtr, dssi, GenClass				>

	test	cx, mask OLMA_DISP_SELECTION_CURSOR
	jz	done

	tst	ah
	jz	useObject
	call	OpenGetParentBackgroundColor	; al = main color
	jmp	short setFlags

useObject:
	call	OpenGetBackgroundColor		; al = main color
setFlags:
	call	OpenSetCursorColorFlagsFromColor
done:
	.leave
	ret
OpenSetCursorColorFlags	endp

OpenSetCursorColorFlagsFromColor	proc	far
	uses	bx
	.enter

	andnf	cx, not (mask OLMA_BLACK_MONOCHROME_BACKGROUND or \
			mask OLMA_DARK_COLOR_BACKGROUND or \
			mask OLMA_LIGHT_COLOR_BACKGROUND)

	;
	; 	Index	Name		Flag to Set
	;	-----	----		-----------
	;	0	C_BLACK		OLMA_BLACK_MONOCHROME_BACKGROUND
	;	1-6	darks		OLMA_DARK_COLOR_BACKGROUND
	;	7	C_LIGHT_GREY	OLMA_LIGHT_COLOR_BACKGROUND
	;	8	C_DARK_GREY	OLMA_DARK_COLOR_BACKGROUND
	;	9-14	lights		OLMA_LIGHT_COLOR_BACKGROUND
	;	15	C_WHITE		<none>
	;
	cmp	al, C_WHITE
	je	done
	mov	bx, mask OLMA_BLACK_MONOCHROME_BACKGROUND
	cmp	al, C_BLACK
	je	haveBackground
	mov	bx, mask OLMA_LIGHT_COLOR_BACKGROUND
	cmp	al, C_LIGHT_GREY
	je	haveBackground
	cmp	al, C_DARK_GREY
	ja	haveBackground
	mov	bx, mask OLMA_DARK_COLOR_BACKGROUND
haveBackground:
	ornf	cx, bx
done:
	.leave
	ret
OpenSetCursorColorFlagsFromColor	endp

endif ; CURSOR_ON_BACKGROUND_COLOR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenGetWashColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get wash colors for object

CALLED BY:	EXTERNAL
PASS:		*ds:si = object to get wash color for
RETURN:		al = main wash color
		ah = mask wash color
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CURSOR_OUTSIDE_BOUNDS or ITEM_USES_BACKGROUND_COLOR

OpenGetWashColorsFromGenParent	proc	far
	push	es, di, si, bx, cx, dx, bp
	call	GenSwapLockParent
	jmp	short washColorsCommon
	
OpenGetWashColorsFromGenParent	endp

OpenGetWashColors	proc	far
	push	es, di, si, bx, cx, dx, bp
	call	VisSwapLockParent
washColorsCommon	label	far
	tst	si
	jz	useDefault
	mov	di, segment GenContentClass
	mov	es, di
	mov	di, offset GenContentClass
	call	ObjIsObjectInClass
	jc	isContent
	mov	di, segment OLWinClass
	mov	es, di
	mov	di, offset OLWinClass
	call	ObjIsObjectInClass
	jc	isWin
	mov	ax, 0
	call	OpenGetBackgroundColor		; ax = main and mask colors
	jnc	noColor
	mov	cx, ax				; cx = colors
returnColor:
	call	ObjSwapUnlock			; preserves flags
	mov	ax, cx				; ax = found colors
done:
	pop	es, di, si, bx, cx, dx, bp
	ret

useDefault:
	mov	ax, segment moCS_dsLightColor
	mov	es, ax
	mov	al, es:[moCS_dsLightColor]	; ax = default wash colors
	mov	ah, al				; no mask color (same)
	jmp	short done

noColor:
	;
	; no color found, if OLCtrlClass, go up the vis tree
	;
;doesn't matter what class it is, just go up -- brianc 9/10/96
;	mov	di, segment OLCtrlClass
;	mov	es, di
;	mov	di, offset OLCtrlClass
;	call	ObjIsObjectInClass
;	jc	isCtrl
;	call	ObjSwapUnlock			; unlock parent
;	jmp	short useDefault

isCtrl:
	call	OpenGetWashColors
	mov	cx, ax				; cx = colors
	jmp	short returnColor

isContent:
	;
	; is content, get wash color from view
	;
	push	bx, si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxsi, ds:[di].GCI_genView
	mov	ax, MSG_GEN_VIEW_GET_COLOR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; dxcx = ColorQuad
EC <	cmp	ch, CF_INDEX						>
EC <	ERROR_NE	RGB_COLOR_NOT_SUPPORTED				>
	mov	ch, cl				; no mask color (same)
	pop	bx, si
	jmp	short returnColor

isWin:
	;
	; is OLWin, get wash color from VCI_window
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VCI_window
	call	ObjSwapUnlock
	tst	di
	jz	useDefault			; no window
	push	si
	mov	si, WIT_COLOR
	call	WinGetInfo			; ah=WinColorFlags, al=index
EC <	test	ah, mask WCF_RGB					>
EC <	ERROR_NZ	RGB_COLOR_NOT_SUPPORTED				>
	mov	ah, al				; no mask color (same)
	pop	si
	jmp	short done

OpenGetWashColors	endp

endif ; CURSOR_OUTSIDE_BOUNDS or ITEM_USES_BACKGROUND_COLOR


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetBackgroundColor

SYNOPSIS:	Returns background colors to use.  Two colors are returned,
		to be dithered together if different.

CALLED BY:	utility

PASS:		*ds:si -- object being drawn
		al     -- non-zero to get selected color, zero for unselected
		ah     -- non-zero if we're a toolbox, and should get the
			  selBkgdColor rather than the dsDarkColor.	  

RETURN:		carry set if non-standard colors found.
		al     -- color drawn at reverse 50% pattern
		ah     -- color drawn at 50% pattern

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/16/92		Initial version

------------------------------------------------------------------------------@
if _ODIE

OpenGetParentBackgroundColor	proc	far
	uses	bx, cx, dx, es
	.enter
	;
	; first, check object
	;
	mov	bx, ax				; bx = flags
	call	OpenGetBackgroundColor		; ax = colors
	jc	done				; found color, done
	mov	ax, bx				; ax = flags
	;
	; if no hint on object, check parent
	;
	push	si
	call	VisSwapLockParent
	jc	haveParent
	pop	si
	push	ax				; pass flags
	jmp	short defaultColors		; (carry clear)

haveParent:
	call	OpenGetBackgroundColor
	call	ObjSwapUnlock
	pop	si

done:
	.leave
	ret
OpenGetParentBackgroundColor	endp

OpenGetBackgroundColor	proc	far
	uses	bx, cx, dx, es
	.enter

	push	ax
	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData			;see if hint exists
	jnc	defaultColors			;no hint, try parent

	mov	cx, {word} ds:[bx].BC_unselectedColor1
	mov	dx, {word} ds:[bx].BC_selectedColor1
	stc
	jmp	short gotColors			;else return the colors

defaultColors	label	far
	mov	ax, segment moCS_dsLightColor
	mov	es, ax
	mov	cl, es:[moCS_dsLightColor]	;cx <- default light color
	mov	ch, cl

	mov	dl, es:[moCS_dsDarkColor]	;dx <- default dark color
	mov	dh, dl

gotColors:
	pop	ax
	pushf

	tst	al				;see whether selected
	jz	10$
	mov	cx, dx				;use selected color if ax!=0
10$:
	popf					;restore special color flag
	mov_tr	ax, cx

	.leave
	ret
OpenGetBackgroundColor	endp

else

OpenGetBackgroundColor	proc	near
	uses	bx, cx, dx, bp, di, si, es
	.enter

	push	ax
	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData			;see if hint exists
	jnc	tryParent			;no hint, try parent

	mov	cx, {word} ds:[bx].BC_unselectedColor1
	mov	dx, {word} ds:[bx].BC_selectedColor1
	stc
	jmp	short gotColors			;else return the colors

tryParent:
	call	VisSwapLockParent
	jnc	defaultColors			;no parent, use default colors
	call	GetCtrlColors
	call	ObjSwapUnlock			;returns unselected color in cx
						;selected color in dx
	jc	gotColors			;something found, branch

defaultColors:
	mov	ax, segment moCS_dsLightColor
	mov	es, ax
	mov	cl, es:[moCS_dsLightColor]	;cx <- default light color
	mov	ch, cl

	mov	dl, es:[moCS_selBkgdColor]	;dx <- default dark color
	mov	dh, dl

	;	
	; Not a toolbox, use dsDarkColor as the default selected color.
	; (Moved from after gotColors, so hint-defined colors are still used.
	;  -cbh 12/22/92)
	;
	pop	ax
	push	ax
	tst	ah				;see if a toolbox
	jnz	gotColors			;yes, branch (carry clear)
	mov	dl, es:[moCS_dsDarkColor]	;else use normal dark color
	mov	dh, dl

gotColors:
	pop	ax
	pushf

	tst	al				;see whether selected
	jz	10$
	mov	cx, dx				;use selected color if al!=0
10$:
	popf					;restore special color flag
	mov_tr	ax, cx

	.leave
	ret
OpenGetBackgroundColor	endp

endif	; _ODIE



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenGetExtraBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns custom background colors to use, if any.

CALLED BY:	(EXTERNAL) Utility
PASS:		*ds:si -- object being drawn
		ah     -- non-zero to get selected color, zero for unselected
		al     -- number of background color to get
			  1 for first, 2 for second, 3 for third, etc.

RETURN:		carry set if custom colors found.
		al     -- color to draw at reverse 50% pattern
		ah     -- color to draw at 50% pattern

DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	8/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ITEM_USES_BACKGROUND_COLOR

OpenGetExtraBackgroundColor	proc	near
	uses	bx, cx, dx
	.enter

	Assert	g	al, 0		; verify argument is non-zero

	mov	dx, ax			; dh = selected/unselected flag
					; dl = # of background color to get

	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData		; see if hint exists
	jnc	noColors		; no hint -> no custom colors

	;
	; Check if the hint holds the extra background colors we are
	; looking for.
	;		ds:bx - pointer to extra data
	;		al - number of background color to get
	;
	VarDataSizePtr	ds, bx, cx	; get size of extra data into cx
	mov	al, dl			; al = # of background color to get
	clr	ah			; ax = # of background color to get
	CheckHack< (size BackgroundColors) eq 4 >	
	shl	ax, 1
	shl	ax, 1			; ax = # of bytes needed
	cmp	cx, ax			; does this hint hold the desired 
					;   BC struct?
	jb	noColors		; nope -> no custom colors

	sub	ax, size BackgroundColors ; ax = offset to desired BC struct
	add	bx, ax			; ds:bx - pointer to desired BC struct 

	mov	ax, {word} ds:[bx].BC_unselectedColor1
	tst	dh			; use selected color?
	jz	useUnselectedColors	; nope, return unselected colors
	mov	ax, {word} ds:[bx].BC_selectedColor1
useUnselectedColors:
	stc				; carry set -> custom colors found

done:
	.leave
	ret
noColors:
	clc				; carry clear -> custom colors not found
	jmp	done

OpenGetExtraBackgroundColor	endp

endif ; ITEM_USES_BACKGROUND_COLOR


COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenGetTextColor

SYNOPSIS:	Returns text color to use.    

CALLED BY:	utility

PASS:		*ds:si -- object being drawn

RETURN:		carry set if non-standard colors found, with:
			al     -- unselected text color
			ah     -- selected text color

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/16/92		Initial version

------------------------------------------------------------------------------@

if _ODIE

OpenGetTextColor	proc	far
	push	bx, si
	mov	ax, HINT_GADGET_TEXT_COLOR
	call	ObjVarFindData			;see if hint exists
	jnc	done				;no hint, done
	mov	ax, {word} ds:[bx].TC_unselectedColor
done:
	pop	bx, si
	ret
OpenGetTextColor	endp

endif

if _ODIE
OpenGetParentTextColor	proc	far
else
OpenGetTextColor	proc	near	
endif
	push	bx, si
	mov	ax, HINT_GADGET_TEXT_COLOR
	call	ObjVarFindData			;see if hint exists
	jnc	tryParent			;no hint, try parent
	mov	ax, {word} ds:[bx].TC_unselectedColor
	stc
	jmp	short exit

tryParent:
	call	VisSwapLockParent
	jnc	exit				;no luck with parent, exit
	push	bx
	mov	ax, HINT_GADGET_TEXT_COLOR
	call	ObjVarFindData			;see if hint exists
	jnc	unlock				;no hint, branch
	mov	ax, {word} ds:[bx].TC_unselectedColor
	stc
unlock:
	pop	bx
	call	ObjSwapUnlock			;returns unselected color in cx

exit:
	pop	bx, si	
	ret
if _ODIE
OpenGetParentTextColor	endp
else
OpenGetTextColor	endp
endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetCtrlColors

SYNOPSIS:	Returns colors to use for children of an OLCtrl.   We will
		only continue upward, searching for the magic hint, it
		we're in a toolbox; otherwise we're done.

CALLED BY:	OpenGetBackgroundColor

PASS:		*ds:si -- OLCtrl

RETURN:		carry set if found, else:
			cx -- unselected color
			dx -- selected color

DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/16/92		Initial version

------------------------------------------------------------------------------@

if (not _ODIE)		; not needed for ODIE color scheme

GetCtrlColors	proc	near
	uses	bx
	class	OLCtrlClass

	.enter
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass
	jnc	done				;not OLCtrl, exit

	mov	ax, HINT_GADGET_BACKGROUND_COLORS
	call	ObjVarFindData			;see if hint exists
	jc	returnColors			;yes, returnColors

	;
	; This moved after the hint check so we can check the immediate
	; parent of the originating object for the hint in non-toolboxes,
	; but no further than that.  -cbh 2/15/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jz	done				;not in toolbox, check no more.

	call	VisSwapLockParent		;else call parent
	jnc	done				;no parent, done (carry clear)
	call	GetCtrlColors
	call	ObjSwapUnlock
	jmp	short done

returnColors:
	mov	cx, {word} ds:[bx].BC_unselectedColor1
	mov	dx, {word} ds:[bx].BC_selectedColor1
	stc
done:
	.leave
	ret

GetCtrlColors	endp

endif	; (not _ODIE)


DrawColor	ends
endif		; if not _ASSUME_BW_ONLY


LessUsedGeometry	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	LUG_DerefVisDI

SYNOPSIS:	Derefs.

CALLED BY:	utility

PASS:		*ds:si -- your mother

RETURN:		ds:di -- your mother's Vis instance

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/11/93		Initial version

------------------------------------------------------------------------------@
LUG_DerefVisDI	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ret
LUG_DerefVisDI	endp


LessUsedGeometry	ends

;------------------------------------

CommonFunctional segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenCreateBubbleHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create bubble help

CALLED BY:	GLOBAL
PASS:		*ds:si	= object to create bubble help/display for
		cx:dx	= bubble help text
		ax	= BubbleHelpData vardata to store info
		bx	= message to send to object when bubble help time
				expires
		bp	= time out
RETURN:		carry set if bubble help created
DESTROYED:	nothing
SIDE EFFECTS:	BubbleHelpData vardata added if successful

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_HELP

OpenCreateBubbleHelp	proc	far
	push	di
	mov	di, 500
	call	ThreadBorrowStackSpace
	call	OpenCreateBubbleHelpLow
	call	ThreadReturnStackSpace
	pop	di
	ret
OpenCreateBubbleHelp	endp

OpenCreateBubbleHelpLow	proc	near
timeOut		local	word	push	bp
timeOutMsg	local	word	push	bx
vardataTag	local	word	push	ax
textSize	local	Point
bubbleOrigin	local	Point
bubbleBounds	local	Rectangle
bubbleRegion	local	word
bubbleBorder	local	word
	uses	ax,bx,cx,si,di,bp,es
	.enter

	; calculate size of text

	push	ds, si
	clr	di
	call	GrCreateState
	movdw	dssi, cxdx
	clr	ax, bx
	mov	cx, -1
	call	GrGetTextBounds		; cx = width, dx = height
	call	GrDestroyState
	pop	ds, si
	
	add	cx, BUBBLE_HELP_TEXT_X_MARGIN * 2
	add	dx, BUBBLE_HELP_TEXT_Y_MARGIN * 2
	mov	ss:[textSize].P_x, cx
	mov	ss:[textSize].P_y, dx

	; calculate bubble help origin

	call	OpenVisGetTransformedBounds
	add	ax, cx
	shr	ax, 1
	mov	ss:[bubbleOrigin].P_x, ax
	clr	ss:[bubbleOrigin].P_y

	; figure out which set of regions we want to use

	mov	ss:[bubbleRegion], offset bubbleHelpAboveRegion
	mov	ss:[bubbleBorder], offset bubbleHelpAboveBorder
	sub	bx, BUBBLE_HELP_WEDGE_SIZE
	mov	ss:[bubbleBounds].R_bottom, bx
	sub	bx, ss:[textSize].P_y
	mov	ss:[bubbleBounds].R_top, bx
	jns	leftRight

	; bubble help doesn't fit on screen above the object, so put it below

	mov	ss:[bubbleRegion], offset bubbleHelpBelowRegion
	mov	ss:[bubbleBorder], offset bubbleHelpBelowBorder
	add	dx, BUBBLE_HELP_WEDGE_SIZE
	mov	ss:[bubbleBounds].R_top, dx
	add	dx, ss:[textSize].P_y
	mov	ss:[bubbleBounds].R_bottom, dx

	mov	ss:[bubbleOrigin].P_y, BUBBLE_HELP_WEDGE_SIZE

leftRight:
	; figure out the xpos of the bubble help window 

	mov	ax, ss:[bubbleOrigin].P_x
	mov	cx, ss:[textSize].P_x
	shr	cx, 1			; bx = 1/2 text width
	sub	ax, cx
	mov	ss:[bubbleBounds].R_left, ax
	add	ax, ss:[textSize].P_x
	mov	ss:[bubbleBounds].R_right, ax

	; and keep it onscreen

	call	OpenGetScreenDimensions	; cx = screen width
	sub	cx, ss:[bubbleBounds].R_right
	jns	checkLeft
	add	ss:[bubbleBounds].R_left, cx
	add	ss:[bubbleBounds].R_right, cx
checkLeft:
	mov	ax, ss:[bubbleBounds].R_left
	tst	ax
	jns	createRegions
	clr	ss:[bubbleBounds].R_left
	sub	ss:[bubbleBounds].R_right, ax

createRegions:
	; create regions for bubble help

	push	bp, si
	segmov	es, cs
	mov	di, ss:[bubbleBorder]
	mov	cx, ss:[textSize].P_x
	mov	dx, ss:[textSize].P_y
	mov	ax, ss:[bubbleOrigin].P_x
	sub	ax, ss:[bubbleBounds].R_left
	mov	bp, ax
	clr	ax, bx
	mov	si, BUBBLE_HELP_BORDER_REGION_SIZE
	call	OpenCreateBubbleWindowRegion
	pop	bp, si

	mov	ss:[bubbleBorder], ax

	push	bp, si
	mov	di, ss:[bubbleRegion]
	mov	ax, ss:[bubbleBounds].R_left
	mov	bx, ss:[bubbleBounds].R_top
	mov	cx, ss:[bubbleBounds].R_right
	mov	dx, ss:[bubbleBounds].R_bottom
	mov	bp, ss:[bubbleOrigin].P_x
	mov	si, BUBBLE_HELP_REGION_SIZE
	call	OpenCreateBubbleWindowRegion
	pop	bp, si

	mov	ss:[bubbleRegion], ax

	push	bp, si
	mov	bp, ax			; bp = bubble region chunk
	mov	bp, ds:[bp]		; ds:bp = bubble region
	call	GeodeGetProcessHandle	; Get owner for window
	push	bx			; Push layer ID to use
	push	bx			; Push owner to use
	call	GetScreenWinFar
	push	di			; pass field window handle
	pushdw	dsbp			; pass region
	push	ax, ax, ax, ax		; region parameters (not used)
	mov	ax, C_WHITE
	clr	bx			; color
	mov	di, ds:[LMBH_handle]
	mov	bp, si			; expose OD
	clrdw	cxdx			; mouse OD
	clr	si			; WinOpenFlags
	call	WinOpen
	pop	bp, si

	mov	ax, ss:[bubbleRegion]
	call	LMemFree

	; xlat window so bubble border will draw correctly when pointing up

	mov	di, bx			; di = bubble help window
	mov	bx, ss:[bubbleOrigin].P_y
	tst	bx
	jz	afterXlat
	push	si
	clr	ax, cx, dx
	mov	si, WIF_DONT_INVALIDATE
	call	WinApplyTranslation
	pop	si
afterXlat:

	mov	dx, ss:[bubbleBorder]	; dx = bubble border region chunk

	;
	; store info into vardata
	;
	mov	ax, ss:[vardataTag]
	mov	cx, size BubbleHelpData
	call	ObjVarAddData
	mov	ds:[bx].BHD_window, di
	mov	ds:[bx].BHD_borderRegion, dx
	;
	; start timer
	;
	mov	ds:[bx].BHD_timer, 0	; in case no time out
	mov	cx, ss:[timeOut]	; cx = time out
	jcxz	noTimer			; no time out, done
	push	bx			; save vardata
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, ss:[timeOutMsg]
	mov	bx, ds:[LMBH_handle]	; ^lbx:si = object
	call	TimerStart
	pop	di			; ds:di = vardata
	mov	ds:[di].BHD_timer, bx	; save timer handle
	mov	ds:[di].BHD_timerID, ax	; save timer ID
noTimer:
	stc
	.leave
	ret
OpenCreateBubbleHelpLow	endp

endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenVisGetTransformedBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get transformed vis bounds

CALLED BY:	GLOBAL
PASS:		*ds:si	= VisClass object
RETURN:		ax	= left
		bx	= top
		cx	= right
		dx	= bottom
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_HELP

OpenVisGetTransformedBounds	proc	near
	uses	di
	.enter

	call	VisGetBounds
	call	VisQueryWindow
	tst	di
	jz	done

	call	WinTransform
	xchg	ax, cx
	xchg	bx, dx
	call	WinTransform
	xchg	ax, cx
	xchg	bx, dx
done:
	.leave
	ret
OpenVisGetTransformedBounds	endp

endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenCreateBubbleWindowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a bubble window region

CALLED BY:	OpenCreateBubbleHelp
PASS:		ds	= segment of lmem block
		es:di	= region definition
		si	= region size
		ax	= param0
		bx	= param1
		cx	= param2
		dx	= param3
		bp	= param4
RETURN:		ax	= region chunk
DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if BUBBLE_HELP

OpenCreateBubbleWindowRegion	proc	near
param4	local	word		push	bp
param3	local	word		push	dx
param2	local	word		push	cx
param1	local	word		push	bx
param0	local	word		push	ax
	uses	cx,si,di
	.enter

	mov	al, mask OCF_IGNORE_DIRTY
	mov	cx, si
	call	LMemAlloc

	push	ax, ds, es
	mov	si, ax
	mov	si, ds:[si]
	segxchg	ds, es
	xchg	si, di
	shr	cx, 1			; cx = number of words

	; Go through region definition and replace params with correct values
regionLoop:
	lodsw
	cmp	ax, EOREGREC
	je	store
	cmp	ax, PARAM_4_END
	ja	store
check4::
	cmp	ax, PARAM_4_START
	jb	check3
	sub	ax, PARAM_4
	add	ax, param4
	jmp	store
check3:
	cmp	ax, PARAM_3_START
	jb	check2
	sub	ax, PARAM_3
	add	ax, param3
	jmp	store
check2:
	cmp	ax, PARAM_2_START
	jb	check1
	sub	ax, PARAM_2
	add	ax, param2
	jmp	store
check1:
	cmp	ax, PARAM_1_START
	jb	check0
	sub	ax, PARAM_1
	add	ax, param1
	jmp	store
check0:
	cmp	ax, PARAM_0_START
	jb	store
	sub	ax, PARAM_0
	add	ax, param0

store:	stosw
	loop	regionLoop
	pop	ax, ds, es

	.leave
	ret
OpenCreateBubbleWindowRegion	endp

PARAM_0_START	= PARAM_0 - 01000h
PARAM_1_START	= PARAM_1 - 01000h
PARAM_2_START	= PARAM_2 - 01000h
PARAM_3_START	= PARAM_3 - 01000h
PARAM_4		= PARAM_3 + 02000h
PARAM_4_START	= PARAM_4 - 01000h
PARAM_4_END	= PARAM_4 + 00fffh

bubbleHelpAboveRegion label Region
	word	PARAM_1-1,					EOREGREC
	word	PARAM_1,	PARAM_0+4, 	PARAM_2-4,	EOREGREC
	word	PARAM_1+1,	PARAM_0+2,	PARAM_2-2,	EOREGREC
	word	PARAM_1+3,	PARAM_0+1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	PARAM_0,	PARAM_2,	EOREGREC
	word	PARAM_3-2,	PARAM_0+1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	PARAM_0+2,	PARAM_2-2,	EOREGREC
	word	PARAM_3,	PARAM_0+4,	PARAM_2-4,	EOREGREC
	word	PARAM_3+1,	PARAM_4,	PARAM_4+11,	EOREGREC
	word	PARAM_3+2,	PARAM_4,	PARAM_4+10,	EOREGREC
	word	PARAM_3+3,	PARAM_4,	PARAM_4+9,	EOREGREC
	word	PARAM_3+4,	PARAM_4,	PARAM_4+8,	EOREGREC
	word	PARAM_3+5,	PARAM_4,	PARAM_4+7,	EOREGREC
	word	PARAM_3+6,	PARAM_4,	PARAM_4+6,	EOREGREC
	word	PARAM_3+7,	PARAM_4,	PARAM_4+5,	EOREGREC
	word	PARAM_3+8,	PARAM_4,	PARAM_4+4,	EOREGREC
	word	PARAM_3+9,	PARAM_4,	PARAM_4+3,	EOREGREC
	word	PARAM_3+10,	PARAM_4,	PARAM_4+2,	EOREGREC
	word	PARAM_3+11,	PARAM_4,	PARAM_4+1,	EOREGREC
	word	PARAM_3+12,	PARAM_4,	PARAM_4,	EOREGREC
	word	EOREGREC

BUBBLE_HELP_REGION_SIZE = ($ - bubbleHelpAboveRegion)

bubbleHelpAboveBorder label Region
	word	PARAM_0, PARAM_1, PARAM_2, PARAM_3+12
	word	PARAM_1-1,					EOREGREC
	word	PARAM_1,	PARAM_0+4,	PARAM_2-4,	EOREGREC
	word	PARAM_1+1,	PARAM_0+2,	PARAM_0+3,	\
				PARAM_2-3,	PARAM_2-2,	EOREGREC
	word	PARAM_1+3,	PARAM_0+1,	PARAM_0+1,	\
				PARAM_2-1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	PARAM_0,	PARAM_0,	\
				PARAM_2,	PARAM_2,	EOREGREC
	word	PARAM_3-2,	PARAM_0+1,	PARAM_0+1,	\
				PARAM_2-1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	PARAM_0+2,	PARAM_0+3,	\
				PARAM_2-3,	PARAM_2-2,	EOREGREC
	word	PARAM_3,	PARAM_0+4,	PARAM_4,	\
				PARAM_4+12,	PARAM_2-4,	EOREGREC
	word	PARAM_3+1,	PARAM_4,	PARAM_4,	\
				PARAM_4+11,	PARAM_4+11,	EOREGREC
	word	PARAM_3+2,	PARAM_4,	PARAM_4,	\
				PARAM_4+10,	PARAM_4+10,	EOREGREC
	word	PARAM_3+3,	PARAM_4,	PARAM_4,	\
				PARAM_4+9,	PARAM_4+9,	EOREGREC
	word	PARAM_3+4,	PARAM_4,	PARAM_4,	\
				PARAM_4+8,	PARAM_4+8,	EOREGREC
	word	PARAM_3+5,	PARAM_4,	PARAM_4,	\
				PARAM_4+7,	PARAM_4+7,	EOREGREC
	word	PARAM_3+6,	PARAM_4,	PARAM_4,	\
				PARAM_4+6,	PARAM_4+6,	EOREGREC
	word	PARAM_3+7,	PARAM_4,	PARAM_4,	\
				PARAM_4+5,	PARAM_4+5,	EOREGREC
	word	PARAM_3+8,	PARAM_4,	PARAM_4,	\
				PARAM_4+4,	PARAM_4+4,	EOREGREC
	word	PARAM_3+9,	PARAM_4,	PARAM_4,	\
				PARAM_4+3,	PARAM_4+3,	EOREGREC
	word	PARAM_3+10,	PARAM_4,	PARAM_4,	\
				PARAM_4+2,	PARAM_4+2,	EOREGREC
	word	PARAM_3+11,	PARAM_4,	PARAM_4,	\
				PARAM_4+1,	PARAM_4+1,	EOREGREC
	word	PARAM_3+12,	PARAM_4,	PARAM_4,	EOREGREC
	word	EOREGREC

BUBBLE_HELP_BORDER_REGION_SIZE = ($ - bubbleHelpAboveBorder)

bubbleHelpBelowRegion label Region
	word	PARAM_1-13,					EOREGREC
	word	PARAM_1-12,	PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-11,	PARAM_4-1,	PARAM_4,	EOREGREC
	word	PARAM_1-10,	PARAM_4-2,	PARAM_4,	EOREGREC
	word	PARAM_1-9,	PARAM_4-3,	PARAM_4,	EOREGREC
	word	PARAM_1-8,	PARAM_4-4,	PARAM_4,	EOREGREC
	word	PARAM_1-7,	PARAM_4-5,	PARAM_4,	EOREGREC
	word	PARAM_1-6,	PARAM_4-6,	PARAM_4,	EOREGREC
	word	PARAM_1-5,	PARAM_4-7,	PARAM_4,	EOREGREC
	word	PARAM_1-4,	PARAM_4-8,	PARAM_4,	EOREGREC
	word	PARAM_1-3,	PARAM_4-9,	PARAM_4,	EOREGREC
	word	PARAM_1-2,	PARAM_4-10,	PARAM_4,	EOREGREC
	word	PARAM_1-1,	PARAM_4-11,	PARAM_4,	EOREGREC
	word	PARAM_1,	PARAM_0+4, 	PARAM_2-4,	EOREGREC
	word	PARAM_1+1,	PARAM_0+2,	PARAM_2-2,	EOREGREC
	word	PARAM_1+3,	PARAM_0+1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	PARAM_0,	PARAM_2,	EOREGREC
	word	PARAM_3-2,	PARAM_0+1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	PARAM_0+2,	PARAM_2-2,	EOREGREC
	word	PARAM_3,	PARAM_0+4,	PARAM_2-4,	EOREGREC
	word	EOREGREC

CheckHack <BUBBLE_HELP_REGION_SIZE eq ($ - bubbleHelpBelowRegion)>

bubbleHelpBelowBorder label Region
	word	PARAM_0, PARAM_1-12, PARAM_2, PARAM_3
	word	PARAM_1-13,					EOREGREC
	word	PARAM_1-12,	PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-11,	PARAM_4-1,	PARAM_4-1,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-10,	PARAM_4-2,	PARAM_4-2,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-9,	PARAM_4-3,	PARAM_4-3,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-8,	PARAM_4-4,	PARAM_4-4,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-7,	PARAM_4-5,	PARAM_4-5,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-6,	PARAM_4-6,	PARAM_4-6,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-5,	PARAM_4-7,	PARAM_4-7,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-4,	PARAM_4-8,	PARAM_4-8,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-3,	PARAM_4-9,	PARAM_4-9,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-2,	PARAM_4-10,	PARAM_4-10,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1-1,	PARAM_4-11,	PARAM_4-11,	\
				PARAM_4,	PARAM_4,	EOREGREC
	word	PARAM_1,	PARAM_0+4,	PARAM_4-12,	\
				PARAM_4,	PARAM_2-4,	EOREGREC
	word	PARAM_1+1,	PARAM_0+2,	PARAM_0+3,	\
				PARAM_2-3,	PARAM_2-2,	EOREGREC
	word	PARAM_1+3,	PARAM_0+1,	PARAM_0+1,	\
				PARAM_2-1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-4,	PARAM_0,	PARAM_0,	\
				PARAM_2,	PARAM_2,	EOREGREC
	word	PARAM_3-2,	PARAM_0+1,	PARAM_0+1,	\
				PARAM_2-1,	PARAM_2-1,	EOREGREC
	word	PARAM_3-1,	PARAM_0+2,	PARAM_0+3,	\
				PARAM_2-3,	PARAM_2-2,	EOREGREC
	word	PARAM_3,	PARAM_0+4,	PARAM_2-4,	EOREGREC
	word	EOREGREC

CheckHack <BUBBLE_HELP_BORDER_REGION_SIZE eq ($ - bubbleHelpBelowBorder)>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenDestroyBubbleHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close and clean up bubble help

CALLED BY:	GLOBAL
PASS:		*ds:si = object with bubble help
		ax = BubbleHelpData vardata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenDestroyBubbleHelp	proc	far
	uses	bx, di
	.enter
	call	ObjVarFindData
	jnc	done
	push	ax, bx
	mov	ax, ds:[bx].BHD_timerID
	mov	bx, ds:[bx].BHD_timer
	tst	bx
	jz	noTimer
	call	TimerStop
noTimer:
	pop	ax, bx
	mov	di, ds:[bx].BHD_window
	cmp	di, 0
EC <	jnz	continue						>
EC <	tst	ds:[bx].BHD_borderRegion				>
EC <	ERROR_NZ OL_ERROR						>
EC <	cmp	di, 0				; reset the Z flag	>
EC < continue:								>
	jz	noWindow
	call	WinClose
	push	ax
	mov	ax, ds:[bx].BHD_borderRegion
	call	LMemFree
	pop	ax
noWindow:
	call	ObjVarDeleteData
done:
	.leave
	ret
OpenDestroyBubbleHelp	endp

endif	; BUBBLE_HELP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartShortLongTouch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a short/long touch

CALLED BY:	INTERNAL
PASS:		*ds:si	= object
RETURN:		carry set if started short/long touch
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SHORT_LONG_TOUCH
StartShortLongTouch	proc	far
	uses	ax,bx,cx,si
	.enter

	mov	ax, HINT_SHORT_LONG_TOUCH
	call	ObjVarFindData
	jnc	done			; exit if no short/long messages

	push	ds:[bx].SLTP_shortMessage
	pushdw	ds:[bx].SLTP_shortDestination
	push	ds:[bx].SLTP_longMessage
	pushdw	ds:[bx].SLTP_longDestination
	mov	cx, (size ShortLongTouchParams) + (size dword)
	call	ObjVarAddData
	popdw	ds:[bx].SLTP_longDestination
	pop	ds:[bx].SLTP_longMessage
	popdw	ds:[bx].SLTP_shortDestination
	pop	ds:[bx].SLTP_shortMessage

	mov	si, bx
	call	TimerGetCount
	movdw	<ds:[si+(size ShortLongTouchParams)]>, bxax
	stc				; started short/long touch
done:
	.leave
	ret
StartShortLongTouch	endp
endif	; SHORT_LONG_TOUCH


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndShortLongTouch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a short/long touch by sending out short/long touch msg.

CALLED BY:	INTERNAL
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if SHORT_LONG_TOUCH
EndShortLongTouch	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	ax, HINT_SHORT_LONG_TOUCH
	call	ObjVarFindData
	jnc	done

	mov	di, bx
	call	TimerGetCount
	subdw	bxax, <ds:[di+(size ShortLongTouchParams)]>

	push	ds
	segmov	ds, <segment dgroup>, dx
	clr	dx
	mov	cx, ds:[olShortLongTouchTime]
	pop	ds

	cmpdw	bxax, dxcx
	jg	longTouch

	mov	ax, ds:[di].SLTP_shortMessage	; ax = short touch message
	pushdw	ds:[di].SLTP_shortDestination	; push short touch destination
	jmp	sendMessage

longTouch:
	mov	ax, ds:[di].SLTP_longMessage	; ax = long touch message
	pushdw	ds:[di].SLTP_longDestination	; push long touch destination

sendMessage:
	call	GenProcessGenAttrsBeforeAction	; process genAttrs

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; send oself as argument
	mov	di, mask MF_FIXUP_DS
	call	GenProcessAction		; process action

	call	GenProcessGenAttrsAfterAction	; process genAttrs
done:
	.leave
	ret
EndShortLongTouch	endp
endif	; SHORT_LONG_TOUCH


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetKeyboardType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set floating keyboard type for this text object

CALLED BY:	INTERNAL
			OLTextSpecBuild
			OLTextGainedSysFocusExcl
			OLSpinGadgetSpecBuild
			OLSpinGadgetGainedSysFocusExcl
PASS:		*ds:si = object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DUI

SetKeyboardType	proc	far
	uses	ax,bx,cx,dx,bp
	.enter
	;
	; set default keyboard type, or custom one
	;
	sub	sp, size KeyboardTypeParams
	mov	bp, sp
	mov	ss:[bp].KTP_displayType, mask FKT_DEFAULT
	mov	ss:[bp].KTP_disallowType, 0
	mov	ss:[bp].KTP_entryMode, mask FKEM_DEFAULT
	mov	ax, HINT_KEYBOARD_TYPE
	call	ObjVarFindData
	jnc	haveType
	;
	; found custom type, use them
	;
	mov	ax, ds:[bx].KTP_displayType
	mov	ss:[bp].KTP_displayType, ax
	mov	ax, ds:[bx].KTP_disallowType
	mov	ss:[bp].KTP_disallowType, ax
	mov	ax, ds:[bx].KTP_entryMode
	mov	ss:[bp].KTP_entryMode, ax
haveType:
	mov	dx, ss				; dx:bp = SetKeyboardTypeParams
	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, SGQT_SET_KEYBOARD_TYPE
	call	GenCallParent
	add	sp, size KeyboardTypeParams
	.leave
	ret
SetKeyboardType	endp

endif	; _DUI

CommonFunctional ends
