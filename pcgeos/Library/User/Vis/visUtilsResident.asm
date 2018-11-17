COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visUtilsResident.asm

ROUTINES:
	Name			Description
	----			-----------

In Fixed resources:
-------------------
   EXT	VisIfFlagSetCallVisChildren 	Carefully call vis children
   EXT	VisIfFlagSetCallGenChildren   	Carefully call gen children
   EXT	VisCallParent		Send message to visible parent of an object
   EXT	VisSendToChildren	Send message to all children of vis composite
   EXT  VisCallFirstChild	Send message to first child of vis composite
   EXT  VisCallNextSibling	Send message to next sibling of vis object
   EXT  VisCallChildUnderPoint	Send message to first child found under point
   EXT  VisCheckIfVisGrown	Check to see if vis master part grown
   EXT  VisCheckIfSpecBuilt	See if object has been specifically built (in tree)
   EXT  VisDrawMoniker		Draw visible moniker
   EXT	VisForceGrabKbd		Force new OD to have kbd grabbed
   EXT	VisGetSize		Returns size of a visible object
   EXT	VisGetCenter
   EXT	VisGetBounds		Returns bounds of a visible object
   EXT  VisGetMonikerPos
   EXT  VisGetMonikerSize
   EXT  VisGetParentGeometry	Get geometry flags of visible parent
   EXT	VisForceGrabKbd		Force grab kbd
   EXT	VisGrabKbd		Grab kbd if no one else has it
   EXT	VisReleaseKbd		Release kbd
   EXT	VisForceGrabMouse	Force grab mouse
   EXT	VisGrabMouse		Grab mouse if no one else has it
   EXT	VisReleaseMouse		Release mouse
   EXT	VisForceGrabLargeMouse	Force grab mouse, request large events
   EXT	VisGrabLargeMouse	Grab mouse, request large events
   EXT	VisFindParent
   EXT  VisMarkInvalid		Mark a visible object invalid in some way
   EXT  VisMarkInvalidOnParent
   EXT  VisMarkFullyInvalid	Invalidate this obj, parent geometry
   EXT  VisSetPosition
   EXT	VisQueryWindow		Get window handle visible object is seen in
   EXT  VisQueryParentWin	Get window handle this object is on
   EXT	VisReleaseKbd
   EXT	VisReleaseMouse
   EXT  VisSetSize
   EXT	VisRecalcSizeAndInvalIfNeeded
   EXT	VisSendPositionAndInvalIfNeeded
   EXT	VisSwapLockParent	Set bx = ds:[0], then *ds:si = vis parent
   EXT  VisTakeGadgetExclAndGrab
   EXT  VisTestPointInBounds

EC EXT	VisCheckOptFlags	Routine to check vis opt flags up to win group
EC EXT	CheckVisMoniker		Make sure VisMoniker is not a VisMonikerList
EC EXT	VisCheckVisAssumption	Make sure visibly grown
EC EXT	ECCheckVisCoords	Make sure (cx, dx) is a valid coordinate

       
In Movable resources:
---------------------
   EXT	VisAddButtonPostPassive
   EXT	VisAddButtonPrePassive
   EXT	VisAddChildRelativeToGen
   EXT  VisConvertSpecVisSize	Converts a SpecSizeSpec value to pixels
   EXT  VisConvertCoordsToRatio	Converts a coordinate pair to SpecWinSizePair
   EXT  VisConvertRatioToCoords	Converts a SpecWinSizePair to a coordinate pair
   EXT	VisFindMoniker		Find (and copy) the specified visual moniker
   EXT	VisGetVisParent		Get visual parent to build this object on
   EXT	VisGetSpecificVisObject	Get vis version of this generic object

   EXT	VisInsertChild		Insert a child into the visible tree
   EXT	VisReleaseButtonPostPassive
   EXT	VisReleaseButtonPrePassive
   EXT	VisTestMoniker
   EXT	VisUpdateSearchSpec
   EXT  VisRemove
   EXT  VisSetNotRealized
   EXT	VisNavigateCommon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of visUtils.asm

DESCRIPTION:
	Utility routines for Vis* objects.  (Meaning these routines should
	only be called from within message handlers of an object which 
	is or is subclassed from VisClass)

	$Id: visUtilsResident.asm,v 1.1 97/04/07 11:44:37 newdeal Exp $

------------------------------------------------------------------------------@
Resident	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCheckIfVisGrown

DESCRIPTION:	Tests to see if an object's visible master part has been 
		grown yet.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data

RETURN:
	carry	- set if visually grown

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

VisCheckIfVisGrown	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	push	di
	mov	di, ds:[si]
				; Has visible part been grown yet?
	tst	ds:[di].Vis_offset	; clears carry
	jz	notGrown
	stc
notGrown:
	pop	di
	ret
VisCheckIfVisGrown	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCheckIfSpecBuilt

DESCRIPTION:	Tests to see if an object containing a visible master
		part has been visually built, checking the object's VI_link.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data

RETURN:
	carry	- set if visually built

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

VisCheckIfSpecBuilt	proc	far
	class	VisClass

	push	ax
	push	di
	mov	di, ds:[si]
				; Has visible part been grown yet?
	mov	ax, ds:[di].Vis_offset
	tst	ax		; clears carry
	je	done		; if not, then can't be visually built yet.
	
	add	di, ax		; point at vis part
				; See if part of visible composite
	tst	ds:[di].VI_link.LP_next.handle
	clc
	je	done		; if not, then not specifically built.
	stc			; else is visually built
done:
	pop	di
	pop	ax
	ret
VisCheckIfSpecBuilt	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCallChildrenInBounds

DESCRIPTION:	Call all children in a composite whose Visual bounds overlap
		the passed bounds.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data
	ax - message to pass
	cx, dx - data to pass to objects
	ss:bp - VisCallChildrenInBoundsFrame

RETURN:
	NOTE: Unlike VisCallChildUnderPoint, VisCallChildrenInBounds calls 
	      multiple children, so it does not return AX=0 to show that there
	      where no children in the bounds.

	bp - ptr to VisCallChildrenInBoundsFrame
	ds	- updated segment

DESTROYED:
	ax, bx, cx, dx, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/91		Initial version

------------------------------------------------------------------------------@

VisCallChildrenInBounds	proc	far		
	class	VisCompClass		; Indicate function is a friend
					; of VisCompClass so it can play with
					; instance data.
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
	mov	di, ds:[si]						
	add	di, ds:[di].Vis_offset
	mov	bl, ds:[di].VI_typeFlags
EC <	test	bl, mask VTF_IS_COMPOSITE				>
EC <	ERROR_Z	UI_REQUIRES_VISUAL_COMPOSITE				>

	test	bl, mask VTF_IS_WINDOW
	jnz	doWindowTransform
	test	bl, mask VTF_IS_PORTAL
	jz	noTransform
	test	bl, mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN
	jz	doTransform
noTransform:
	mov	di, offset Resident:CallChildInBoundsCallBack
	call	VisCallCommonWithRoutine
exit:
	ret
doWindowTransform:
	test	bl, mask VTF_IS_CONTENT
	jnz	noTransform
doTransform:

;	If this group lies in its own window, then transform the passed
;	bounds.

	mov	bx, ds:[di].VI_bounds.R_top
	push	bx
	sub	ss:[bp].VCCIBF_bounds.R_top, bx
	sub	ss:[bp].VCCIBF_bounds.R_bottom, bx

	mov	bx, ds:[di].VI_bounds.R_left
	push	bx
	sub	ss:[bp].VCCIBF_bounds.R_left, bx
	sub	ss:[bp].VCCIBF_bounds.R_right, bx
	
	mov	di, offset Resident:CallChildInBoundsCallBack
	call	VisCallCommonWithRoutine
	pop	bx
	add	ss:[bp].VCCIBF_bounds.R_left, bx
	add	ss:[bp].VCCIBF_bounds.R_right, bx

	pop	bx
	add	ss:[bp].VCCIBF_bounds.R_top, bx
	add	ss:[bp].VCCIBF_bounds.R_bottom, bx
	jmp	exit
VisCallChildrenInBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallIfInBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine invokes a method on the passed object if its
		bounds overlap the passed bounds.

CALLED BY:	GLOBAL
PASS:		*ds:si, ds:di - Vis object
		ax - method
		ss:bp - VisCallChildrenInBoundsFrame
RETURN:		nada
DESTROYED:	bx, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallIfInBounds	proc	near
	class	VisClass

	mov	bx, ss:[bp].VCCIBF_bounds.R_left
	cmp	bx, ds:[di].VI_bounds.R_right
	jg	exit			

	mov	bx, ss:[bp].VCCIBF_bounds.R_right
	cmp	bx, ds:[di].VI_bounds.R_left
	jl	exit			

	mov	bx, ss:[bp].VCCIBF_bounds.R_top
	cmp	bx, ds:[di].VI_bounds.R_bottom
	jg	exit			

	mov	bx, ss:[bp].VCCIBF_bounds.R_bottom
	cmp	bx, ds:[di].VI_bounds.R_top
	jl	exit

	push	ax, bp
					; Test to see if child's bounds hit
	call	ObjCallInstanceNoLock
	pop	ax, bp	
exit:
	ret
CallIfInBounds	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CallChildInBoundsCallBack

SYNOPSIS:	Checks to see if child is under current point.  Calls the
		child if so.

CALLED BY:	FAR

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ax - message to pass
		cx, dx	- data for child
		ss:bp - ptr to VisCallChildrenInBoundsFrame

RETURN:		carry clear
		cx, dx, ss:bp.VCCIBF_data -- returned from child if called

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/91		Initial Version

------------------------------------------------------------------------------@

CallChildInBoundsCallBack	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	mov	bl, ds:[di].VI_attrs

;	Make sure item is enabled, detectable, etc.

	test	bl, mask VA_FULLY_ENABLED
	jz	exit
	test	bl, mask VA_DETECTABLE or mask VA_REALIZED
	jz	exit
	jpo	exit

;	Check if the object's bounds overlap the passed bounds

	call	CallIfInBounds

exit:
	clc
	ret
CallChildInBoundsCallBack	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCallChildUnderPoint

DESCRIPTION:	Default routine for passing input message down a visible
		hierarchy.  Calls the first child of a composite that is
		realized, enabled, detectable, and whose bounds lie
		under the point passed.  Sets UIFA_IN before calling such a
		child.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data
	ax	- message
	cx, dx	- mouse position in document coordinates
	bp  	- other data to pass on (NOTE:  Bit corresponding to UIFA_IN in
		  high byte MUST be able to be set if mouse is determined to
		  be over child -- basically, bp high must either be
		  UIFunctionsActive, have a similar bit in the same position,
		  or not be used.)

RETURN:
	carry	- set if child was under point, clear if not
	ax	- Data returned by child.  If no child, is cleared to NULL,
		  unless message passed = MSG_META_PTR, in which case
		  ax is returned = MRF_CLEAR_POINTER_IMAGE.
	cx, dx, bp - return values, if child called
	ds	- updated segment

DESTROYED:
	bx, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions
	Doug	1/93		Updated doc to clearing indicate input nature

------------------------------------------------------------------------------@

VisCallChildUnderPoint	proc	far		
	class	VisCompClass		; Indicate function is a friend
					; of VisCompClass so it can play with
					; instance data.
EC <	push	di							>
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_REQUIRES_VISUAL_COMPOSITE				>
EC <	pop	di							>

	mov	di, offset CallChildUnderPointCallBack
	call	VisCallCommonWithRoutine

	jc	exit
					; return flags clear if no children hit
	cmp	ax, MSG_META_START_MOVE_COPY
	jne	notHelp
	push	ax, cx, dx, bp
	mov	bp, ax
	mov	ax, MSG_SPEC_NO_INPUT_DESTINATION
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
notHelp:
	cmp	ax, MSG_META_PTR
	mov	ax, mask MRF_CLEAR_POINTER_IMAGE
	jz	exit			;Carry is clear if ax = MSG_META_PTR...

	clr	ax			;"clr" clears the carry 
exit:
	ret
VisCallChildUnderPoint	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CallChildUnderPointCallBack

SYNOPSIS:	Checks to see if child is under current point.  Calls the
		child if so.

CALLED BY:	FAR

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ax - message to pass
		cx, dx	- location in document coordinates
		bp - data to pass on

RETURN:		carry set if child hit (to abort sending to other siblings)
		ax, cx, bp -- returned from child if called

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

CallChildUnderPointCallBack	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	
	mov	bx,ds:[si]
	add	bx,ds:[bx].Vis_offset
	test	ds:[bx].VI_typeFlags, mask VTF_IS_WINDOW
	jnz	noMatch
	mov	bl, ds:[bx].VI_attrs

;	Make sure item is enabled, detectable, etc.

;	Allow mouse events to get sent to disabled objects. - Joon (11/10/98)
;	test	bl, mask VA_FULLY_ENABLED
;	jz	noMatch
		
	test	bl, mask VA_DETECTABLE or mask VA_REALIZED
	jz	noMatch
	jpo	noMatch

	call	VisTestPointInBounds
	jnc	noMatch
	or	bp,(mask UIFA_IN) shl 8
					; Test to see if child's bounds hit
					; Use ES version since *es:di is
					; 	composite object
	call	ObjCallInstanceNoLockES	; if hit, send to this child
	stc				; & don't send to any others
	ret

noMatch:
	clc
	ret

CallChildUnderPointCallBack	endp

	

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisTestPointInBounds

DESCRIPTION:	Test whether a point is within an object's visual bounds.
		Used by mouse handlers to see what object is clicked on.

CALLED BY:	GLOBAL

PASS:
	*ds:si - object
	cx, dx - point (x, y)

RETURN:
	carry - set if poing within bounds

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisTestPointInBounds	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance

	; check for windowed object

	test	ds:[di].VI_typeFlags,mask VTF_IS_WINDOW
	jnz	VTPIB_window

	; not a windowed object, do basic bounds checking

	cmp	cx, ds:[di].VI_bounds.R_left
	jl	VTPIB_outside
	cmp	cx, ds:[di].VI_bounds.R_right
	jge	VTPIB_outside			;must be INSIDE object bounds
	cmp	dx, ds:[di].VI_bounds.R_top
	jl	VTPIB_outside
	cmp	dx, ds:[di].VI_bounds.R_bottom
	jge	VTPIB_outside			;must be INSIDE object bounds
VTPIB_inside:
	stc
	pop	di
	ret

VTPIB_outsidePop:
	pop	ax
VTPIB_outside:
	clc
	pop	di
	ret

	; a windowed object

VTPIB_window:
	tst	cx			;(0,0) are top,left coordinate
	jl	VTPIB_outside
	tst	dx
	jl	VTPIB_outside
	push	ax
	mov	ax, ds:[di].VI_bounds.R_right	;compute right
	sub	ax, ds:[di].VI_bounds.R_left
	cmp	cx, ax
	jg	VTPIB_outsidePop
	mov	ax, ds:[di].VI_bounds.R_bottom	;compute bottom
	sub	ax, ds:[di].VI_bounds.R_top
	cmp	dx, ax
	jg	VTPIB_outsidePop
	pop	ax
	jmp	short VTPIB_inside

VisTestPointInBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns size of an object by looking at its bounds instance
		data.

CALLED BY:	GLOBAL

PASS:		*ds:si	- instance data of visual object

RETURN:		cx -- width of object
		dx -- height of object

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/15/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


VisGetSize	method static	VisClass, 	MSG_VIS_RECALC_SIZE,
						MSG_VIS_GET_SIZE,
						MSG_SPEC_GET_EXTRA_SIZE
	class	VisClass
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >

	push	di
	mov	di, ds:[si]		; get ptr to object
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left
	mov	dx, ds:[di].VI_bounds.R_bottom
	sub	dx, ds:[di].VI_bounds.R_top
	pop	di
	ret

VisGetSize	endm
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetBounds

DESCRIPTION:	Return the bounds of a visual object, from its instance data.

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data of visual object

RETURN:
	ax - left
	bx - top
	cx - right
	dx - bottom

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	12/89		Rewritten for extra composite function
	Chris	4/91		Updated for new graphics, vis bounds conventions
	Chris	5/20/91		Restore to get rid of stupid composite function

------------------------------------------------------------------------------@

VisGetBounds	proc	far
	class	VisClass
EC<	call	VisCheckVisAssumption		; Make sure vis data exists >
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset		; ds:bx = VisInstance
	mov	ax, ds:[bx].VI_bounds.R_left	;add in real bounds
	mov	cx, ds:[bx].VI_bounds.R_right
	mov	dx, ds:[bx].VI_bounds.R_bottom
	mov	bx, ds:[bx].VI_bounds.R_top
	ret

VisGetBounds	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetBoundsInsideMargins

DESCRIPTION:	Return the visual bounds of a visual composite object, inside
		its margins.

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data of visual object

RETURN:
	ax - left edge of object, after the composite's left margin
	bx - top edge, below the composite's top margin
	cx - right edge, before the composite`s right margin
	dx - bottom, above the composites's bottom margin
	ds - updated to point at segment of same block as on entry

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	12/89		Rewritten for extra composite function
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisGetBoundsInsideMargins	proc	far
	class	VisCompClass
EC<	call	VisCheckVisAssumption		; Make sure vis data exists >
	
EC <	mov	bx, ds:[si]						>
EC <	add	bx, ds:[bx].Vis_offset		; ds:bx = VisInstance	>
EC <	test	ds:[bx].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_MUST_BE_VIS_COMP_TO_HAVE_MARGINS			>
	;
	; Get composite margins and set them up as offsets from the real bounds.
	;
	push	bp
	mov	ax, MSG_VIS_COMP_GET_MARGINS	;get control margins
	call	ObjCallInstanceNoLock		;  in ax/bp/cx/dx
	mov	bx, bp
	neg	cx				;negate right, bottom
	neg	dx
	mov	bp, ds:[si]			;deref again
	add	bp, ds:[bp].Vis_offset
	add	ax, ds:[bp].VI_bounds.R_left	;add in real bounds
	add	bx, ds:[bp].VI_bounds.R_top
	add	cx, ds:[bp].VI_bounds.R_right
	add	dx, ds:[bp].VI_bounds.R_bottom
	pop	bp
	ret

VisGetBoundsInsideMargins	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCallParentEnsureStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call VisCallParent, but ensures that there is around 600
		bytes of stack space.

CALLED BY:	GLOBAL
PASS:		same as VisCallParent
RETURN:		same as VisCallParent
DESTROYED:	same as VisCallParent
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCallParentEnsureStack	proc	far	uses	di
	.enter
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	call	VisCallParent
	call	ThreadReturnStackSpace
	.leave
	ret
VisCallParentEnsureStack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCallParent

DESCRIPTION:	Call the visual parent of a visual object.  If no visual parent,
		does nothing.

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object starting query

	cx, dx, bp - data to send along
	ax - Message to send to visible parent

RETURN:
	carry		- clear if null parent link, else set by message called.
	ax, cx, dx, bp	- returned data
	si		- unchanged
	ds		- updated segment of object

DESTROYED:	
	nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	
------------------------------------------------------------------------------@

VisCallParent	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	push	bx, di
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	mov	bx, offset Vis_offset
	mov	di, offset VI_link
	call	ObjLinkCallParent
	pop	bx, di
	ret
VisCallParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisGotoParentTailRecurse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Method handler to do nothing but VisCallParent.  May ONLY
		be used to replace:

			GOTO	VisCallParent

		from within a method handler, ast the non-EC version
		optimally falls through to VisGotoParentTailRecurse.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- method

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisGotoParentTailRecurse                proc    far
        class   VisClass

        call    VisFindParent           ; Find parent object
	GOTO	ObjMessageCallFromHandler

VisGotoParentTailRecurse                endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisFindParent

DESCRIPTION:	Return the visual parent of an object.  

CALLED BY:	EXTERNAL

PASS:		*ds:si - instance data

RETURN:		^lbx:si - parent (or null if none)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

VisFindParent	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	push	di
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	mov	bx, offset Vis_offset	; Call visual parent
	mov	di, offset VI_link	; Pass visual linkage
	call	ObjLinkFindParent
	pop	di
	ret

VisFindParent	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSwapLockParent

DESCRIPTION:	Utility routine to setup *ds:si to be the visual parent of
		the current object.  To be used in cases where you want
		to get access to a visual parent's instance data, or 
		prepare to call a routine where *ds:si much be the object,
		or for cases where you otherwise might be doing a
		series of VisCallParent's, which can be somewhat expensive.

		USAGE:

							; *ds:si is our object
			push	si			; save chunk offset
			call	VisSwapLockParent	; set *ds:si = parent
			push	bx			; save bx (handle
							; of child's block)


			pop	bx			; restore bx
			call	ObjSwapUnlock
			pop	si			; restore chunk offset


CALLED BY:	EXTERNAL

PASS:		*ds:si - instance data of object

RETURN:		carry	- set if succesful (clear if no parent)
		*ds:si	- instance data of parent object  (si = 0 if no parent)
		bx	- block handle of child object, which is
			  still locked.

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

VisSwapLockParent	proc	far
	class	VisClass
	push	di

EC<	call	VisCheckVisAssumption	; Make sure gen data exists >

	mov	bx, offset Vis_offset	; Call generic parent
	mov	di, offset VI_link	; Pass generic linkage

	call	ObjSwapLockParent
	pop	di
	ret

VisSwapLockParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCallCommonWithRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a method, data, and offset to a callback
		routine

CALLED BY:	INTERNAL
PASS:		cs:di - ptr to callback routine
RETURN:		args from ObjCompProcessChildren
DESTROYED:	bx, di, whatever ObjCompProcessChildren dorks
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCallCommonWithRoutine	proc	near
	class	VisClass	
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
EC <	push	di
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_REQUIRES_VISUAL_COMPOSITE				>
EC <	pop	di

	clr	bx			;start with initial child (first
	push	bx			;child of composite)
	push	bx
	mov	bx, offset VI_link
	push	bx			;push offset to LinkPart
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	push	di

	mov	bx,offset Vis_offset
	mov	di,offset VCI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret
VisCallCommonWithRoutine	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSendToChildren

DESCRIPTION:	Sends message to all children of visible composite.  Arguments 
		will be passed identically to each visible child.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data
	ax - method to pass
	cx, dx, bp - data for message

RETURN:
	cx, dx, bp - unchanged

	bx, si	- unchanged
	ds	- updated segment

DESTROYED:
	ax, bx
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisSendToChildren	proc	far
	class	VisClass
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	FALL_THRU	VisCallCommon
VisSendToChildren endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCallCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used to call ObjCompProcessChildren with
		args appropriate for processing all vis children.

CALLED BY:	GLOBAL
       
PASS:		di - ObjCompCallType
		
RETURN:		args from ObjCompProcessChildren
		
DESTROYED:	bx,di, whatever ObjCompProcessChildren dorks
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCallCommon	proc	far
	class	VisCompClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
EC <	push	di
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_REQUIRES_VISUAL_COMPOSITE				>
EC <	pop	di
	
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	push	di
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp

	;DO NOT CHANGE THIS TO A GOTO!  We are passing stuff on the stack.
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack

	ret

VisCallCommon	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisCallFirstChild

SYNOPSIS:	Sends message to first child of a composite.  Does nothing if
		composite has no children.  Does not allow for passing stuff 
		on the stack.

CALLED BY:	utility

PASS:		*ds:si -- handle of composite
		ax -- message
		cx, dx, bp -- message args

RETURN:		ax, cx, dx, bp -- return args
		ds - updated to point at segment of same block as on entry

DESTROYED:	
	nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/22/89	Initial version

------------------------------------------------------------------------------@

VisCallFirstChild	proc	far
	class	VisCompClass
	push	si, bx

EC <	push	di							>
EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_REQUIRES_VISUAL_COMPOSITE				>
EC <	pop	di							>

	mov	si, ds:[si]			;point to instance
	add	si, ds:[si].Vis_offset		;ds:[di] -- VisInstance
	mov	bx, ds:[si].VCI_comp.CP_firstChild.handle
	mov	si, ds:[si].VCI_comp.CP_firstChild.chunk
	tst	si
	jz	exit
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	DoPop	bx, si
	ret
VisCallFirstChild	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCallNextSibling

DESCRIPTION:	Call next sibling of a visible object.  Does nothing if object
		has no sibling (i.e. the parent is null).

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data
	ax - message to pass
	cx, dx, bp - data for message

RETURN:
	cx, dx, bp - unchanged
	ds	- updated segment
	carry	- may be set by message handler, will be clear if no next
		sibling is found.

DESTROYED:
	bx, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		Initial version

------------------------------------------------------------------------------@

VisCallNextSibling	proc	far
	class	VisClass
	push	bx, di
EC<	call	VisCheckVisAssumption	; Make sure gen data exists >
	mov	bx, offset Vis_offset	; Call visible sibling
	mov	di, offset VI_link	; Pass visible linkage
	call	ObjLinkCallNextSibling
	pop	bx, di
	ret
VisCallNextSibling	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisQueryWindow

DESCRIPTION:	Returns window handle that this object is visible in.  If
		object is a window, returns that handle.

		NOTE: if you need a window handle because you wish to attach
		a GState to it, consider using MSG_VIS_VUP_CREATE_GSTATE
		instead -- this message normally travels up to the WIN_GROUP
		object, & creates a GState attached to the WIN_GROUP's window
		handle.  Though slower than using VisQueryWindow, it allows
		large (32-bit) composites & layers to intercept the message
		& apply a 32-bit translation to the GState, so that 16-bit
		visible objects below that point can reside in a 32-bit
		document space.

CALLED BY:	EXTERNAL

PASS:		*ds:si	- visible object 

RETURN:		di - window handle (0 if not realized)
		ds - updated to point at segment of same block as on entry

DESTROYED:	
	nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version
	
------------------------------------------------------------------------------@

VisQueryWindow	proc	far
	class	VisCompClass

	clr	di				; assume not built
	
	;
	; Check to see if the object is specifically built yet.  Unfortunately,
	; VisCheckIfSpecBuilt checks to see if the object is specifically
	; grown.  This object doesn't have to be a specific object!
	;
	push	ax
	push	di
	mov	di, ds:[si]
				; Has visible part been grown yet?
	mov	ax, ds:[di].Vis_offset
	tst	ax
	je	VCIVB_notBuilt	; if not, then can't be visually built yet.
				; See if visible master part has any data
				; allocated for it (Visible world used?)
	add	di, ax		; point at vis part
				; See if part of visible composite
	tst	ds:[di].VI_link.LP_next.handle
	je	VCIVB_notBuilt	; if not, then not specifically built.
	stc			; else is visually built
	jmp	short VCIVB_done

VCIVB_notBuilt:
	clc
VCIVB_done:
	pop	di
	pop	ax
	
	jnc	VQW_notBuilt			; nope, exit
	mov	di, ds:[si]			; get ptr to instance
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance

	; if object is not a composite use VisQueryParentWin

	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	VQW_notComposite

	mov	di, ds:[di].VCI_window		; fetch window handle

EC <	tst	di				; null is allowed	>
EC <	jz	VQW_100							>
EC <	xchg	bx, di							>
EC <	call	ECCheckWindowHandle		; make sure win handle	>
EC <	xchg	bx, di							>
EC <VQW_100:								>
	
VQW_notBuilt:
	ret

VQW_notComposite:
	FALL_THRU	VisQueryParentWin

VisQueryWindow	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisQueryParentWin

DESCRIPTION:	Returns window handle of parent of this object.

		NOTE: if you need a window handle because you wish to attach
		a GState to it, consider using MSG_VIS_VUP_CREATE_GSTATE
		instead -- this message normally travels up to the WIN_GROUP
		object, & creates a GState attached to the WIN_GROUP's window
		handle.  Though slower than using VisQueryParentWin, it allows
		large (32-bit) composites & layers to intercept the message
		& apply a 32-bit translation to the GState, so that 16-bit
		visible objects below that point can reside in a 32-bit
		document space.

CALLED BY:	EXTERNAL

PASS:		*ds:si	- visible object 

RETURN:		di - window handle (0 if not realized)
		ds - updated to point at segment of same block as on entry

DESTROYED:	
	nothing
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version
	
------------------------------------------------------------------------------@

VisQueryParentWin	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.
	push	bx

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >

	clr	di			; assume no window
	push	si
	call	VisSwapLockParent	; setup *ds:si = parent
	jnc	VQPGW_30		; if no parent, return null win handle

	call	VisQueryWindow		; Fetch window handle, if built

VQPGW_30:
	call	ObjSwapUnlock		; restore ds
	pop	si
	pop	bx
	ret

VisQueryParentWin	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetParentGeometry

DESCRIPTION:	Returns the geometry flags of the visible parent of this
		objects. NOT INTENDED TO BE RESILIENT TO PROBLEMS -- will
		fatal error if the data is not there...

CALLED BY:	EXTERNAL

PASS:		*ds:si	- visible object 

RETURN:		cl -- GeoAttrs
		ch -- GeoDimensionAttrs

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version
	
------------------------------------------------------------------------------@

VisGetParentGeometry	proc	far
	class	VisCompClass
	push	bx
	push	si
	push	di
	call	VisSwapLockParent
EC <	ERROR_NC	UI_VIS_GET_PARENT_GEOMETRY_NO_PARENT		>

EC <	call	VisCheckIfVisGrown					>
EC <	ERROR_NC	UI_VIS_GET_PARENT_GEOMETRY_PARENT_NOT_GROWN	>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_VIS_GET_PARENT_GEOMETRY_PARENT_NOT_COMPOSITE		>
	mov	cx, word ptr ds:[di].VCI_geoAttrs

	call	ObjSwapUnlock
	pop	di
	pop	si
	pop	bx
	ret

VisGetParentGeometry	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisMarkInvalidOnParent

DESCRIPTION:	Marks object's visible parent as being invalid in some way.

PASS:		*ds:si 	- instance data
		cl -- flags:
			mask VOF_BUILD_INVALID	  (causes spec build update)
			mask VOF_GEOMETRY_INVALID (causes geometry update)
			mask VOF_WINDOW_INVALID   (causes win move/resize)
			mask VOF_IMAGE_INVALID    (causes region inval)

		dl -- flags:
			VisUpdateMode

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	
	cx
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

VisMarkInvalidOnParent	proc	far	uses	bx, si
	.enter
	call	VisFindParent		; Set ^lbx:si = vis parent
	tst	bx
	jz	done			; If NO vis parent, done

					; See if parent is run by same thread
					; or not
	call	ObjTestIfObjBlockRunByCurThread
	je	sameThread

					; If run by different thread, have
					; to use ObjMessage
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jmp	short done

sameThread:
	call	ObjSwapLock
	call	VisMarkInvalid
	call	ObjSwapUnlock
done:
	.leave
	ret
VisMarkInvalidOnParent	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisMarkInvalid -- MSG_VIS_MARK_INVALID for VisClass

DESCRIPTION:	Marks objects as having invalid geometry, image, or view.
		Sets the invalid flags for the object according to what is
		passed.  Sets path flags up the tree to the ui-window
		accordingly.   Use VOF_IMAGE_INVALID when you've changed how 
		the object is drawn, so that it will redraw correctly.  Use
		VOF_GEOMETRY_INVALID if you want the object to be a different
		size and need its (and other vis objects around it) geometry
		redone.  Use VOF_WINDOW_INVALID if you need to open a new window
		for the object, or if the object's bounds have changed and
		a window must be moved or resized accordingly.

PASS:		*ds:si 	- instance data
		cl -- flags:
			mask VOF_BUILD_INVALID	  (causes spec build update)
			mask VOF_GEOMETRY_INVALID (causes geometry update)
			mask VOF_WINDOW_INVALID   (causes win move/resize)
			mask VOF_IMAGE_INVALID    (causes region inval)

		dl -- flags:
			VisUpdateMode

RETURN:		nothing
		ds - updated to point at segment of same block as on entry

DESTROYED:	
	cx
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		save passed flags
		;
		; if any invalid bits set, set the corresponding path bit
		; also clear path flags that are already set in the object
		;
		flags = flags or ((flags and INVALID_BITS) >>1) and
		       (not (optFlags and PATH_BITS))
	        optFlags = optFlags or flags
		;
		; now run up the tree, setting path bits where necessary.
		;
		flags = flags and PATH_BITS
		
		if flags and not IS_WIN_GROUP
		     CallParent(flags)
		else
		     restore original passed flags
		     if not VUM_MANUAL	call MSG_VIS_UPDATE_WIN_GROUP
		endif
		

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/24/89		Initial version
	Doug	10/89		Now recurses up tree w/o using messages

------------------------------------------------------------------------------@


VisMarkInvalid	method static	VisClass, MSG_VIS_MARK_INVALID
	class	VisClass
	push	ax
	push	bx
	push	dx					
	push	di

EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

EC <	call	VisCheckVisAssumption	; Make sure vis data exists	>
EC <	call	VisCheckOptFlags		; Check VI_optFlags	>

	push	dx				; save update mode
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance

	tst	cl				; any bits set?
	jz	VMI70				; no, branch

	mov	dl, ds:[di].VI_optFlags		; save original optFlags here
	or	ds:[di].VI_optFlags, cl		; or in new flags
						; NOW, merge inval & path into
						;	path bits, to carry
						;	forward.

	; Now go up the tree with any path bits, to set a path to the top.
	;
						; If WIN_GROUP, stop, at top.
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	VMI70
						; Else calc path bits needed
	mov	ch, cl				; copy to ch
	and	ch, VOF_INVALID_BITS		; take invalid bits
	shr	ch, 1				; turn into path bits
	or	cl, ch				; and "or" back in
	and	cl, VOF_PATH_BITS		; keep only resulting path bits

						; Do the same for original val
	mov	dh, dl				; copy to dh
	and	dh, VOF_INVALID_BITS		; take invalid bits
	shr	dh, 1				; turn into path bits
	or	dl, dh				; and "or" back in
	and	dl, VOF_PATH_BITS		; keep only resulting path bits

	not	dl				; Any bits which where already
	and	cl, dl				; marked as invalid or as
						; path bits need not be carried
						; forward.
	jz	VMI70				; if nothing more to do, done

	mov	dl, VUM_MANUAL			; for operations recursively
						;	 upward, do manually
						;	of branch from above
	; NOW, recursively call parent, without using messages, to save time.

	push	si
	call	VisSwapLockParent		; setup *ds:si = parent
	jnc	VMI_doneWithParent		; if no parent, skip

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	call	VisMarkInvalid			; Mark parent invalid as
	call	ThreadReturnStackSpace		;	appropriate
VMI_doneWithParent:
	call	ObjSwapUnlock			; restore ds
	pop	si

VMI70:
	pop	dx				; restore original args

EC <	call	VisCheckOptFlags		; Check VI_optFlags	>

	tst	dl				; check for VUM_MANUAL
	jz	VMI80
	push	bp

	call	VisVupUpdateWinGroup		; call statically
	pop	bp
VMI80:

EC <	call	VisCheckOptFlags		; Check VI_optFlags	>
   
	pop	di
	pop	dx
	pop	bx
	pop	ax
	ret
VisMarkInvalid	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisGetCenter -- MSG_VIS_GET_CENTER for VisClass

DESCRIPTION:	Returns the center of a visual object.  Usually, an object's
		center is the midpoint of the object -- this external routine
		will return exactly that if you know your object doesn't 
		handle MSG_VIS_GET_CENTER specially.

PASS:		*ds:si 	- instance data
		ax 	- MSG_VIS_GET_CENTER

RETURN:		cx 	- minimum amount needed left of center
		dx	- minimum amount needed right of center
		ax 	- minimum amount needed above center
		bp      - minimum amount needed below center

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/14/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


VisGetCenter	method	static VisClass, MSG_VIS_GET_CENTER
	class	VisClass
	push	di
EC<	call	VisCheckVisAssumption	;make sure vis data exists	>
	mov	di, ds:[si]		;point at instance data
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
	call	VisGetSize	       	;get the size of the object
	mov	bp, dx			;put height in bp
	mov	ax, bp			;and ax
	mov	dx, cx			;put width in dx as well as cx
	shr	cx, 1			;divide width by 2 for left 
	sub	dx, cx			;subtract from width for right
	shr	ax, 1			;divide height by 2 for top
	sub	bp, ax			;subtract from height for bottom
	pop	di
	ret
VisGetCenter	endm

	
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	This routine takes a normal width and height, and stores
		it in the instance data.  Should be called ONLY by the
		geometry manager unless this object or its parent
		is not managed.  The resize leaves the upper left corner
		pinned in the same location.
		
PASS:	ax	- MSG_VIS_SET_SIZE
	*ds:si	- instance data

	cx	- width of object
	dx	- height of object

RETURN:		nothing
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/88		Initial version
	Chris	2/23/89		(Hopefully) changed for the last time.
	Chris	4/91		Updated for new graphics, vis bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VisSetSize	method	static VisClass, MSG_VIS_SET_SIZE
	class	VisClass
	push	bx, di
EC<	call	VisCheckVisAssumption	; Make sure vis data exists	>
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	bx, ds:[di].VI_bounds.R_left	; set new right value
	add	bx, cx
	mov	ds:[di].VI_bounds.R_right, bx
	
	mov	bx, ds:[di].VI_bounds.R_top	; set new top value
	add	bx, dx
	mov	ds:[di].VI_bounds.R_bottom, bx
	DoPop	di, bx
	ret
VisSetSize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisSetPosition -- MSG_VIS_SET_POSITION for VisClass

DESCRIPTION:	VisClass handling routine for MSG_VIS_SET_POSITION
		Changes the bounds in an object's instance data so that the 
		object moves, preserving its width & height.  This is generally
		only called by the geometry manager, but others can call it
		to move objects that are not managed.

PASS:
	*ds:si - instance data

	ax - MSG_VIS_SET_POSITION

	cx	- new left edge, relative to parent window
	dx	- new top edge

RETURN:
	nothing

DESTROYED:
	nothing	(can be called via static binding)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisSetPosition	method	static VisClass, MSG_VIS_SET_POSITION, \
					 MSG_VIS_POSITION_BRANCH
	class	VisClass
	push	cx, di
EC<	call	VisCheckVisAssumption	; Make sure vis data exists	>
	mov	di, ds:[si]		; point to instance data
	add	di, ds:[di].Vis_offset

	sub	cx, ds:[di].VI_bounds.R_left	; make relative to current left
	add	ds:[di].VI_bounds.R_left, cx	; add left back in for new left
	add	ds:[di].VI_bounds.R_right, cx	; add rel amount for new right
	mov	cx,dx
	sub	cx, ds:[di].VI_bounds.R_top	; make relative to current top
	add	ds:[di].VI_bounds.R_top, cx	; add top back in for new top
	add	ds:[di].VI_bounds.R_bottom, cx	; add rel amt for new bottom
	pop	cx, di
	ret

VisSetPosition		endm
	
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisDrawMoniker

DESCRIPTION:	Draw a visual moniker for an object.  This is often called
		by a MSG_VIS_DRAW handler for an object.  Many things can be
		passed to control where the moniker is drawn in relation to
		the object's bounds, whether to clip the moniker, etc.
		
		If you just want to draw an object's generic moniker, in 
		GI_visMoniker, you can call GenDrawMoniker, which takes the
		same arguments as VisDrawMoniker.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data
	*es:bx - moniker to draw   (if bx = 0, then nothing drawn)
	cl     - how to draw moniker: DrawMonikerFlags
	ss:bp  - DrawMonikerArgs
	
RETURN:
	ax, bx -- position moniker was drawn at
	ss:bp  -- DrawMonikerArgs, with DMA_CLIP_TO_MAX_WIDTH still set if
			clipping was needed on the moniker, otherwise cleared.

PASSED TO MONIKER:
       
       When designing a graphics string moniker for a gadget, here's the state
       you can expect when the gstring begins drawing:
       
       		* Line color, text color, area color set to the desired moniker
		  for that gadget and specific UI, typically black.  You should
		  use these if your gstring is black and white.  If you're using
		  color, you can choose your own colors but you must be sure 
		  they look OK against all of the specific UI background colors.
		  
		* Pen position set to the upper left corner of where the moniker
		  should be drawn.  Your graphics string *must* be drawn
		  relative to this pen position.
       
       		* The moniker must return all gstate variables intact, except
		  that colors and pen position can be destroyed.
		  
DESTROYED:
	cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions
	Chris	5/25/92		Rewritten to clip in both x and y.

------------------------------------------------------------------------------@

VisDrawMoniker	proc	far	
	class	VisClass		;Indicate function is a friend
					; of VisClass so it can play with
					; instance data.
EC<	call	VisCheckVisAssumption	 ;Make sure vis data exists >
EC<	test	cl, not DrawMonikerFlags ;any bad flags?            >
EC<	ERROR_NZ UI_BAD_DRAW_MONIKER_FLAGS	 		    >
EC<	call	ECCheckLMemObject				    >	
	
	test	cl, mask DMF_CLIP_TO_MAX_WIDTH
	jz	GDM_start		;not clipping, branch
	push	cx, bp			;save flags, pointer to stuff
	mov	ax, ss:[bp].DMA_textHeight	;pass height of text, if any
	mov	bp, ss:[bp].DMA_gState	;pass gstate
	mov	di, bx			;pass moniker in *es:di
	call	VisGetMonikerSize	;get moniker size in cx, dx
	mov	bx, di			;*es:bx <- moniker again
	mov	di, dx			;height in di
	mov	dx, cx			;width in dx
	DoPop	bp, cx
	
GDM_start:	
EC <	push	di							>
EC <	mov	di, bx			;pass *es:di = VisMoniker	>
EC <	call	CheckVisMoniker		;make sure is not moniker list! >
EC <	pop	di							>

	push	si				;save si
	mov	ax, si				;also put here
	clr	si				;assume no moniker
	tst	bx
	jz	10$				;Null chunk, branch with si=0
	mov	si, es:[bx]			;es:si = visMoniker
10$:
	push	di				;save moniker height
	test	cl,mask DMF_NONE		;if drawing at pen position
	jz	GDM_notAtPen			;then do it
	mov	di, ss:[bp].DMA_gState
	call	GrGetCurPos			;(ax, bx) = pen position
	jmp	GDM_atPen
GDM_notAtPen:
	push	cx, dx				;save moniker flags
	call	GetMonikerPos			;ax,bx <-  moniker position
	pop	cx, dx				;restore moniker flags
	mov	di, ss:[bp].DMA_gState
	call	GrMoveTo
GDM_atPen:
	pop	di				;restore moniker height
	push	ds
	segmov	ds,es
	;
	; We'll set an application clip region here to clip the string to
	; the maximum width.  If the size of the moniker warrants it, anyway.
	;
	push	cx				;save draw flags
	test	cl, mask DMF_CLIP_TO_MAX_WIDTH	;see if we're clipping
	jz	GDM_draw			;no, don't clip
	cmp	dx, ss:[bp].DMA_xMaximum	;see if moniker fits
	ja	GDM_setupClip			;no, clip.
	cmp	di, ss:[bp].DMA_yMaximum	;see if moniker fits
	ja	GDM_setupClip			;no, clip.

	pop	cx				;restore draw flags
	and	cl, not mask DMF_CLIP_TO_MAX_WIDTH	
	push	cx				;clear flag, save again
	jmp	short GDM_draw			;skip clipping stuff
	
GDM_setupClip:	
	mov	di, ss:[bp].DMA_gState
	push	si, ax, bx, dx			;remove ax, bx when we draw
						; the text at the pen pos!
	call	GrSaveState			;save current clip region
	
	;
	; Get current position and calculate a clip region for the text.
	;
	call	GrGetCurPos			;get pen position in ax, bx
	mov	cx, ax				;put x pos in right edge
	add	cx, ss:[bp].DMA_xMaximum	;add max width-1 to get right
;	dec	cx				;  edge of clip region
	mov	dx, bx
	add	dx, ss:[bp].DMA_yMaximum
;	dec	dx
	mov	si, {word} ds:[si].VM_type	;get moniker type

;	Apparently, this is no longer necessary. (Or a good idea) -cbh 4/27/92
;	(Apparently it is again.  -cbh 11/19/92 :)
;	It is no longer a good idea, again - brianc 2/9/93
;(
;	test	si, mask VMT_GSTRING		;is a GString?
;	jz	GDM_clip			;skip if not
;	sub	cx, ax				;else make relative to origin
;	clr	ax				;
;	sub	dx, bx
;	clr	bx
;)
;
;GDM_clip:
	mov	si, PCT_REPLACE			;new clip region
	call	GrSetClipRect			;set it
	DoPop	dx, bx, ax, si
	
GDM_draw:
	mov	di, ss:[bp].DMA_gState
	tst	si				;see if any moniker
	jz	GDM_afterDraw			;none, skip any drawing
	mov	cl, ds:[si].VM_type		;get moniker type
	add	si, VM_data			;point at the data
	test	cl, mask VMT_GSTRING		;is a GString?
	jnz	GDM_notText			;skip if so...

	add	si, VMT_text			;get at the text
	clr	cx				;draw all characters
	call	GrDrawText			;draw the moniker
	
	pop	cx				;restore draw moniker flags	
	jmp	short GDM_afterDrawCxOK

GDM_notText:
	pop	cx				;get draw moniker flags back
	push	cx
	test	cl, mask DMF_TEXT_ONLY		;text only, skip draw
	jnz	GDM_afterDraw			;  (cbh 12/14/92)

	push	bx, dx
	call	GrSaveState
	mov	cl, GST_PTR			; pointer type
	mov	bx, ds				; bx:si -> GString
	add	si, VMGS_gstring		;
	call	GrLoadGString			; si = GString handle
	clr	dx				; no flags
	call	GrDrawGStringAtCP		; draw it
EC <	cmp	dx, GSRT_COMPLETE					>
EC <	ERROR_NZ	INVALID_MONIKER					>
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	call	GrRestoreState
	pop	bx, dx
GDM_afterDraw:
	pop	cx				;restore flags
	
GDM_afterDrawCxOK:
	test	cl, mask DMF_CLIP_TO_MAX_WIDTH	;see if we were clipping
	jz	GDM_exit			;no, exit
	call	GrRestoreState			;restore old clip region
	
GDM_exit:
	pop	ds
	pop	si				;& restore si
	ret

VisDrawMoniker	endp
		
	
COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetMonikerPos

DESCRIPTION:	Calculate position of object's visual moniker, without actually
		drawing anything.   This can be useful, along with 
		VisMonikerSize, for figuring out where the moniker will be 
		drawn.  Takes the same arguments as VisDrawMoniker.
		
CALLED BY:	EXTERNAL
       
PASS:
	*ds:si - instance data
	*es:bx - moniker to draw   (if bx = 0, then nothing drawn)
	cl - how to draw moniker: MatrixJustifications
	ss:bp  - DrawMonikerArgs

RETURN:
	ax, bx -- position moniker was drawn at (zeroes if no moniker)

DESTROYED:
	cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


VisGetMonikerPos	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

EC<	call	VisCheckVisAssumption		;Make sure vis data exists >
	clr	ax				;assume no moniker...
	tst	bx
	jz	VGMP_reallyExit			;If null chunk, all done

EC <	push	di							>
EC <	mov	di, bx			;pass *es:di = VisMoniker	>
EC <	call	CheckVisMoniker		;make sure is not moniker list! >
EC <	pop	di							>

	push	si				;save si
	mov	ax, si				;also put here
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	mov	si, es:[bx]			;es:si = visMoniker

	test	cl,mask DMF_NONE		;if drawing at pen position
	jz	VGMP_notAtPen			;then do it
	jmp	short VGMP_atPen

VGMP_notAtPen:
	call	GetMonikerPos			;ax,bx <-  moniker position
	jmp	short VGMP_exit			;and exit

VGMP_atPen:
	mov	di, ss:[bp].DMA_gState		;pass the graphics state
	call	GrGetCurPos
	
VGMP_exit:
	pop	si				;& restore si
	
VGMP_reallyExit:
	ret

VisGetMonikerPos	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetMonikerPos

SYNOPSIS:	Returns the position to draw the moniker at.  Assumes DMF_NONE
		is not set, that the position is derived from the bounds of
		the object and the size of the moniker.

CALLED BY:	VisDrawMoniker, VisGetMonikerPos

PASS:		
	*ds:ax - instance data
	*es:bx - moniker to draw   
	 es:di - moniker to draw
	cl - how to draw moniker: DrawMonikerFlags
	ss:bp - DrawMonikerArgs

RETURN:	
	ax, bx -- position (or zeroes if no moniker)

DESTROYED:	
	cx, dx, di

PSEUDO CODE/STRATEGY:
       uses ss:[bp].DMA_drawMonikerTextHeight for the cached height of the
       		object

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/89	Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

GetMonikerPos	proc	near
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	tst	si			; any moniker to draw?
	jnz	1$			; yes, branch
	clr	ax			; else return zeroes
	mov	bx, ax
	jmp	exit
1$:
	
	;DO NOT error check VisMoniker here - has already been done.

	push	ss:[bp].DMA_textHeight		;save this, we may use it
	push	ax				;save instance data ptr

	; make sure that size is correct

	mov	ax, es:[si].VM_width			;get cached size
	test	es:[si].VM_type, mask VMT_GSTRING	;is a GString?
	jz	needWidthOrHeight			;no, always need height
	
	mov	di, ({VisMonikerGString} es:[si].VM_data).VMGS_height
	mov	ss:[bp].DMA_textHeight, di	;keep calc'ed height here
	or	ax, di				;see if everything set up
	jnz	gotWidthHeight			;yes, skip GetMonikerSize
	
needWidthOrHeight:
	pop	si				;instance handle in si
	push	si
	push	cx
	mov	di, bx				;handle of moniker in di
	push	bp
	mov	ax, ss:[bp].DMA_textHeight	;pass height of text, if any
	mov	bp, ss:[bp].DMA_gState		;pass gstate handle in bp
	call	VisGetMonikerSize		;height in dx, width in cx
	pop	bp
	mov	ss:[bp].DMA_textHeight, dx	;keep calc'ed height here
	pop	cx
	mov	si,es:[bx]
	
gotWidthHeight:
	
	; compute x position for moniker

	pop	di				;restore object pointer
	push	di				;push back
	mov	di, ds:[di]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	clr	ax				;If window, left edge is 0
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jnz	10$
	mov	ax,ds:[di].VI_bounds.R_left	;ax = left bound
10$:
	mov	bx, ss:[bp].DMA_xInset		;assume left just, calc offset
	mov	ch,cl				;ch = flags for x axis
	and	ch,mask DMF_X_JUST
	jz	addOffsetX			;if left then done

	mov	bx,ds:[di].VI_bounds.R_right	;compute extra
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
						; if window, undo offset
	jz	20$
	sub	bx,ds:[di].VI_bounds.R_left
20$:
	sub	bx,ax				;bx = width
	sub	bx,es:[si].VM_width		;bx = extra
	cmp	ch,(J_RIGHT shl offset DMF_X_JUST)	; right justified ?
	jz	right
	sar	bx,1				;centered -- use half of extra
	jmp	short addOffsetX
right:
	sub	bx, ss:[bp].DMA_xInset		;subtract offset on right
	
addOffsetX:
	add	ax,bx

	; compute y position for moniker (ax = x pos)

	push	ax
	clr	ax
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
						; if window, top is 0
	jnz	30$
	mov	ax,ds:[di].VI_bounds.R_top	;ax = top bound
30$:
	mov	bx, ss:[bp].DMA_yInset		;assume top just, calc offset
	and	cl,mask DMF_Y_JUST
	jz	addOffsetY			;if left then done
	mov	bx,ds:[di].VI_bounds.R_bottom	;compute extra
						; if window, undo offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	40$
	sub	bx,ds:[di].VI_bounds.R_top
40$:
	dec	ax				;added in for new graphics --
						; matches hack below (the 
						; correct thing would be to have
						; nothing)
	sub	bx,ax				;bx = height
	sub	bx, ss:[bp].DMA_textHeight		;bx = extra
						;  to account for new graphics
	cmp	cl,(J_RIGHT shl offset DMF_Y_JUST)	; bottom justified ?
	jz	bottom
	sar	bx,1				;centered -- use half of extra
	inc	bx				;the hack has to stay now.
	jmp	short addOffsetY
bottom:
	sub	bx, ss:[bp].DMA_yInset		;subtract offset on right
addOffsetY:
	add	bx,ax
	pop	ax
	pop	di				;throw away instance data ptr
	pop	ss:[bp].DMA_textHeight		;restore this
exit:
	ret
GetMonikerPos	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetMonikerSize

DESCRIPTION:	Get the size of a visual moniker for an object.   Useful, along
		with VisMonikerPos, to determine where a moniker will be drawn.
		Also used in the MSG_VIS_RECALC_SIZE handlers for various 
		objects when the size of the moniker in some way influences
		the size of the object.

CALLED BY:	EXTERNAL

PASS:
	*ds:si - instance data for object
	*es:di - moniker (if di=0, returns size of 0)
	bp - graphics state (containing font and style) to use
	ax - the height of the font to be used for a text moniker, or zero
		to get it from the graphics state

RETURN:
	cx - moniker width
	dx - moniker height

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Chris	7/22/91		New version with cached height for gstrings
				only

------------------------------------------------------------------------------@

VisGetMonikerSize	proc	far
	push	di
	push	es
	FALL_THRU	GetMonikerSizeCommon, es, di

VisGetMonikerSize	endp

	; *ds:si = object, *ds:di = moniker, on stack - di passed

GetMonikerSizeCommon	proc	far
	class	VisClass

	tst	di
	LONG	jz	isNull

EC <	call	CheckVisMoniker		;make sure is not MonikerList	>


   	mov	dx, ax			;assume a text moniker, use passed ht
	mov	di,es:[di]				;es:di = visMoniker
	mov	cx,es:[di].VM_width		;get cached width

	test	es:[di].VM_type, mask VMT_GSTRING	;gstring, use cached ht
	jz	textMoniker
	mov	dx, ({VisMonikerGString} es:[di].VM_data).VMGS_height
	jmp	common

	; this is a text moniker -- look for a hinted case

textMoniker:
	test	cx, mask VMCW_HINTED
	jz	common

	push	dx
	push	cx
	call	UserGetDefaultMonikerFont	;cx = font ID, dx = size
NPZ <	cmp	cx, FID_BERKELEY					>
PZ <	cmp	cx, FID_PIZZA_KANJI					>
	pop	cx
	jnz	cantUseHintedValues
NPZ <	cmp	dx, 9							>
PZ <	cmp	dx, 12							>
	jz	berkeley9
NPZ <	cmp	dx, 10							>
PZ <	cmp	dx, 16							>
	jnz	cantUseHintedValues

	; it is Berkeley 10, use cached size

NPZ <			CheckHack <offset VMCW_BERKELEY_10 eq 0>	>
PZ <			CheckHack <offset VMCW_PIZZA_KANJI_16 eq 0>	>
NPZ <	andnf	cx, mask VMCW_BERKELEY_10				>
PZ <	andnf	cx, mask VMCW_PIZZA_KANJI_16				>
	jmp	storeNewCommon

cantUseHintedValues:
	clr	cx
	jmp	popCommon

	; it is Berkeley 9, use cached size

berkeley9:
NPZ <			CheckHack <offset VMCW_BERKELEY_9 eq 8>		>
PZ <			CheckHack <offset VMCW_PIZZA_KANJI_12 eq 8>	>
NPZ <	andnf	cx, mask VMCW_BERKELEY_9				>
PZ <	andnf	cx, mask VMCW_PIZZA_KANJI_12				>
	xchg	cl, ch
storeNewCommon:
	mov	es:[di].VM_width, cx

popCommon:
	pop	dx

common:
	jcxz	needSomething
	tst	dx
	LONG jnz done			;don't have height or width

needSomething:
	
	; if no GState passed then create one

	tst	bp
	pushf					;save GState passed state
	jnz	haveGState
	push	ax, cx, dx
	xchg	di,bp		;DI <- window to associate, di saved in bp
	call	GrCreateState	;Make a gstate for the window, in di
	call	UserGetDefaultMonikerFont
	clr	ah		;No fractional pt size
	call	GrSetFont

	xchg	di, bp		;BP <- gstate, di restored from bp
	pop	ax, cx, dx
	
haveGState:
	test	es:[di].VM_type, mask VMT_GSTRING
	jnz	getGraphicSize

	push	si
	push	ds
	segmov	ds,es
	lea	si,ds:[di].VM_data		;ds:si = moniker data
	xchg	di,bp				;di = GState, bp = visMoniker

	tst	cx				;do we need a width?
	jnz	ensureTextHeight

	push	dx
	clr	cx				;null terminated
	add	si, VMT_text			;point at the text
	call	GrTextWidth			;returns dx = width
	mov	cx, dx				;keep in cx
	pop	dx
	
ensureTextHeight:
	tst	dx				;do we need a height?
	jnz	gotWidthHeight
	push	cx
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED	;si <- info to return, rounded
	call	GrFontMetrics			;dx -> height
	pop	cx
	jmp	short gotWidthHeight

	; graphic moniker -- use GrGetGStringBounds

getGraphicSize:
	push	si, ds, ax, bx			; save object chunk and other
						;  registers that need saving

	mov	cl, GST_PTR
	mov	bx, es				; bx:si = gstring fptr
	lea	si, es:[di].VM_data + size VisMonikerGString
	mov	ds, bx				; ds:bp <- VisMoniker
	xchg	bp, di				;  for later...
	call	GrLoadGString			; si <- gstring handle

	; GrGetGStringBounds returns the bounds of the GString *relative*
	; to the current pen position stored in the GState. If a GString
	; contains no position-relative opcodes (like GR_DRAW_TEXT_AT_CP),
	; then the bounds are not affected by this fact. However, if
	; a GString does contain one or more of these opcodes, then the
	; values returned will be dependent upon the current position.
	; To avoid this problem, we set the pen position to be the origin,
	; and ensure we save & restore the passed pen position around this
	; work. We do not use GrSaveState & GrRestoreState as an
	; optimization. -Don 7/11/94

	call	GrGetCurPos			; get pen position & save it
	push	ax, bx
	clr	ax, bx
	call	GrMoveTo			; always start at the origin
	clr	dx				; no control flags
	call	GrGetGStringBounds		; ax, bx, cx, dx = bounds
	pop	ax, bx
	call	GrMoveTo			; restore pen position

	inc	cx
	inc	dx
	push	dx
	mov	dl, GSKT_LEAVE_DATA		; destroy the gstring
	call	GrDestroyGString
	pop	dx

	pop	ax, bx				; leave ds, si on stack

gotWidthHeight:

	; cx = width, dx = height.  Cache our calculated values, if we can.
	; ds:bp = VisMoniker, di = gstate passed (or created)

	xchg	di,bp				;di = visMoniker
	mov	ds:[di].VM_width,cx		;cache width
	
	test	ds:[di].VM_type, mask VMT_GSTRING	;is a GString?
	jz	cachedWidthHeight			;skip if not
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, dx
	
cachedWidthHeight:
	pop	ds
	pop	si
	
	; destroy GState if we created one

	popf
	jnz	noDestroy
	mov	di,bp
	call	GrDestroyState
	mov	bp, 0				;if we created one, return
						;	bp = 0 as was passed in
noDestroy:

done:
	FALL_THRU_POP	es, di
	ret

isNull:						;Here if null chunk handle
	clr	cx				;Return size of 0
	mov	dx, cx
	jmp	short done

GetMonikerSizeCommon	endp
	


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisMarkFullyInvalid

DESCRIPTION:	Mark a visual object as being invalid in all ways that it
		could possibly be invalid.  Mark its visual parent as being
		geometrically invalid, as well.  This is used by MSG_SPEC_BUILD 
		handlers to make sure things are set up right for a newly-
		added object.

CALLED BY:	EXTERNAL
		VisSpecBuild

PASS:
	*ds:si	- visual object to mark invalid

RETURN:
	*ds:si	- still pointing at object
	(ds - updated to point at segment of same block as on entry)

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE: Since we we ALWAYS mark the object as geometrically
	invalid, then in a simple visible composite tree that
	is not being managed, but instead is laid out by the application,
	we may have a lot of traversal by the geometry manager
	through the tree, looking for something to do...

	This may or may not be a problem.  It may be easy to solve,
	by having the application intercept the MSG_VIS_UPDATE_GEOMETRY
	at a high level, & then leaving it up to the app whether to
	use the lower invalid bits or just ignore them.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
------------------------------------------------------------------------------@


VisMarkFullyInvalid	proc	far	uses	ax, bx, cx, dx, di, bp
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.
	.enter
EC<	call	VisCheckVisAssumption		;Make sure vis data exists >
	

	; If we're not a WIN_GROUP, then adding in this
	; object will mess up our parent's geometry.  Mark it as invalid.

					; See if WIN_GROUP or not
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	VMFI_AfterParentInvalidation
					; Mark parent composite as having bad
					; geometry, that needs updating.
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalidOnParent

VMFI_AfterParentInvalidation:

	; Invalidate the object itself, in all ways
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID or mask VOF_IMAGE_INVALID

	; Optimization - if not a windowed object, don't need to mark
	; as VOF_WINDOW_INVALID
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
						; see if windowed object
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jnz	VMFI_afterOpt			; skip if windowed
						; Don't bother to mark a
						; non-window invalid.
	and	cl, not mask VOF_WINDOW_INVALID
VMFI_afterOpt:

	mov	dl, VUM_MANUAL
	call	VisMarkInvalid		; mark newly invalid attributes
	.leave
	ret

VisMarkFullyInvalid	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisReleaseMouse		

DESCRIPTION:	Releases mouse grab for the calling object, if it had the
		mouse grab.  If the active grab is lost, then the ptr event
		handling mode is set back to whatever it was set to the last
		time there was no active grab (basically, back to whatever
		the last impledgrab object set it too)

		The implementation for this routine varies depending on 
		whether or not the UI thread is currently running.  If it
		is, then FlowGrabMouse is called.  If it is not, then
		the MSG_VIS_VUP_ALTER_INPUT_FLOW is sent to the object,
		which will find its way up to the VisContent object which
		the current object is under.

		NOTE:   If called on object which implements mouse grabs,
			results in object releasing grab from node above the
			object (i.e can not be used to release mouse from self)

PASS:		*ds:si -- object to release the grab for

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@
	
VisReleaseMouse	method	VisClass, MSG_VIS_RELEASE_MOUSE
	push	ax

	push	bx, cx, dx, bp
	clr	ax				;no bounds limit, OK?
	mov	bx, ax
	mov	cx, ax
	mov	dx, ax
	call	SendMouseInteractionBounds	;limit view drag-scrolling
	pop	bx, cx, dx, bp

	mov	al, mask VIFGF_MOUSE or mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	FALL_THRU	VisAlterInputFlowCommon, ax

VisReleaseMouse	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisAlterInputFlowCommon		

DESCRIPTION:	Implements mouse  & kbd grabs for visible objects.
		This routine is jumped to by various other routines in
		this file (Regs are pushed on stack which this routine pops
		off)

		The implementation for this routine varies depending on 
		whether or not the UI thread is currently running.  If it
		is, then FlowGrabMouse is called.  If it is not, then
		the MSG_VIS_VUP_ALTER_INPUT_FLOW is sent to the object,
		which will find its way up to the VisContent object which
		the current object is under.

PASS:		*ds:si -- object to grab for
		al	- VisInputFlowGrabFlags
		ah	- VisInputFlowGrabType
		On stack, pushed in this order:
			value to return in ax

			

RETURN:		*ds:si	- intact
		ax	- as specified in stack arguments

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

VisAlterInputFlowCommon	proc	far
	class	VisClass

	push	cx, dx, bp
	sub	sp, size VupAlterInputFlowData	; create stack frame
	mov	bp, sp				; ss:bp points to it
	mov	cx, ds:[LMBH_handle]
	mov	ss:[bp].VAIFD_object.handle, cx	; copy object OD into frame
	mov	ss:[bp].VAIFD_object.chunk, si
	mov	ss:[bp].VAIFD_flags, al		; copy flags into frame
	mov	ss:[bp].VAIFD_grabType, ah
	mov	ss:[bp].VAIFD_gWin, 0		; assume not needed

	test	al, mask VIFGF_GRAB		; Check for mouse grab
	jz	notMouseGrab
	test	al, mask VIFGF_MOUSE
	jz	notMouseGrab

	push	di
	call	VisQueryWindow			; Fetch window handle in di
	mov	ss:[bp].VAIFD_gWin, di		; & pass in message
	pop	di

notMouseGrab:
	clr	dx				; init to no translation
	mov	ss:[bp].VAIFD_translation.PD_x.high, dx
	mov	ss:[bp].VAIFD_translation.PD_x.low, dx
	mov	ss:[bp].VAIFD_translation.PD_y.high, dx
	mov	ss:[bp].VAIFD_translation.PD_y.low, dx

	mov	dx, size VupAlterInputFlowData	; pass size of structure in dx

	test	al, mask VIFGF_GRAB		; Grab?
	jz	directCall			; if not, we can safely make
						; a direct call to the first
						; Input Node up tree
	test	al, mask VIFGF_MOUSE		; Mouse?
	jz	directCall			; if not, we can safely make
						; a direct call to the first
						; Input Node up tree

callHere:
	mov	ax, MSG_VIS_VUP_ALTER_INPUT_FLOW	; send message
	call	ObjCallInstanceNoLock

afterCall:
	add	sp, size VupAlterInputFlowData	; restore stack
	pop	cx, dx, bp

	FALL_THRU_POP	ax
	ret

directCall:
	; If it turns out this object itself is an input node (a rare case,
	; by the way, which happens thus far only in the GrObj world), then
	; just use call the MSG_VIS_VUP_ALTER_INPUT_FLOW on ourselves, with
	; on optimization even if VIFGF_NOT_HERE set.
	; This allows input nodes to deal with the case of VIFGF_NOT_HERE
	; specially, if they need to (GrObj uses this on text & other
	; objects in order to control the GrObj mouse grab mechanism)
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_INPUT_NODE
	pop	di
	jnz	callHere
						; clear "NOT_HERE" flag, since
						; we'll be calling on parent
	and	ss:[bp].VAIFD_flags, not mask VIFGF_NOT_HERE

	push	bx, si, di
	mov	al, mask VTF_IS_INPUT_NODE
	call	VisFindParentOfVisType
	mov	ax, MSG_VIS_VUP_ALTER_INPUT_FLOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; call Input Node directly
	pop	bx, si, di

	jmp	short afterCall
	
VisAlterInputFlowCommon	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisFindParentOfVisType

DESCRIPTION:	Searches up visible tree, starting at parent, for first object
		having specified VisTypeFlags set, & returns it.

CALLED BY:	INTERNAL

PASS:		*ds:si	- visible object
		al	- VisTypeFlags to look for (any of which found set will
			  satisfy the search, if mulitiple flags specified)

RETURN:		^lbx:si	- object (or NULL, if not found)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/93		Rewritten from VisFindInputNode
------------------------------------------------------------------------------@

VisFindParentOfVisType	proc	far
	class	VisClass

	call	VisSwapLockParent
	jnc	noParent

	push	cx
	push	bx

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, al
	pop	di
	jz	goUp

	mov	bx, ds:[LMBH_handle]	; Found it!

foundIt:
	mov_tr	cx, bx
	pop	bx
	call	ObjSwapUnlock
	mov_tr	bx, cx
	pop	cx
	ret

noParent:
	clr	bx			; Object not found.
	clr	si
	ret

goUp:
	call	VisFindParentOfVisType
	jmp	short foundIt

VisFindParentOfVisType	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisTakeGadgetExclAndGrab

DESCRIPTION:	Take the gadget exclsuive for the current obejct and grab the
		mouse.  This is often called by objects upon receipt of
		a mouse message such as MSG_META_START_SELECT.

		NOTE:   If called on object which implements mouse grabs,
			results in object getting grab from node above the
			object (i.e can not be used to grab mouse from self)

CALLED BY:	GLOBAL

PASS:
	*ds:si - object to grab for

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

VisTakeGadgetExclAndGrab	proc	far
	push	ax, cx, dx, bp
	mov	cx,ds:[LMBH_handle]		;^lcx:dx = object to grab for
	mov	dx,si
	mov	ax,MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent
	pop	ax, cx, dx, bp
	GOTO	VisGrabMouse

VisTakeGadgetExclAndGrab	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisForceGrabMouse		

DESCRIPTION:	Commonly used routine to grab the mouse for the current
		object.  Grabs the mouse from whoever has it.
		VisReleaseMouse should be called to release the mouse grab

		The implementation for this routine varies depending on 
		whether or not the UI thread is currently running.  If it
		is, then FlowGrabMouse is called.  If it is not, then
		the MSG_VIS_VUP_ALTER_INPUT_FLOW is sent to the object,
		which will find its way up to the VisContent object which
		the current object is under.

		NOTE:   If called on object which implements mouse grabs,
			results in object getting grab from node above the
			object (i.e can not be used to grab mouse from self)


PASS:		*ds:si -- object to grab for

RETURN:		nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	steve	1/90		Initial version

------------------------------------------------------------------------------@

VisForceGrabMouse	method  VisClass, MSG_VIS_FORCE_GRAB_MOUSE
	push	ax
	mov	al, mask VIFGF_MOUSE or mask VIFGF_GRAB or mask VIFGF_FORCE or \
		    mask VIFGF_PTR or mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisForceGrabMouse	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisGrabMouse		

DESCRIPTION:	Commonly used routine to grab the mouse for the current
		object.  Grabs the mouse if no one has the grab.
		VisReleaseMouse should be called to release the mouse grab.

		The implementation for this routine varies depending on 
		whether or not the UI thread is currently running.  If it
		is, then FlowGrabMouse is called.  If it is not, then
		the MSG_VIS_VUP_ALTER_INPUT_FLOW is sent to the object,
		which will find its way up to the VisContent object which
		the current object is under.

		NOTE:   If called on object which implements mouse grabs,
			results in object getting grab from node above the
			object (i.e can not be used to grab mouse from self)


PASS:		*ds:si -- object to grab for

RETURN:		nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisGrabMouse	method	VisClass, MSG_VIS_GRAB_MOUSE
	push	ax
	
	push	bx, cx, dx, bp
	call	VisGetBounds
	call	SendMouseInteractionBounds	;limit view drag-scrolling
	pop	bx, cx, dx, bp
	
	mov	al, mask VIFGF_MOUSE or mask VIFGF_GRAB or mask VIFGF_PTR or \
		    mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisGrabMouse	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisForceGrabLargeMouse		

DESCRIPTION:	Same as VisForceGrabMouse, but requests LARGE mouse events
		be sent to grab.  VisReleaseMouse may be used to release the
		grab.

		NOTE:   If called on object which implements mouse grabs,
			results in object getting grab from node above the
			object (i.e can not be used to grab mouse from self)

PASS:		*ds:si -- object to grab for

RETURN:		nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/91		Initial version

------------------------------------------------------------------------------@

VisForceGrabLargeMouse	method	VisClass, MSG_VIS_FORCE_GRAB_LARGE_MOUSE
	push	ax
	mov	al, mask VIFGF_MOUSE or mask VIFGF_GRAB or mask VIFGF_FORCE or \
		    mask VIFGF_LARGE or mask VIFGF_PTR or mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisForceGrabLargeMouse	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisGrabLargeMouse

DESCRIPTION:	Same as VisGrabLargeMouse, but requests LARGE mouse events
		be sent to grab.  VisReleaseMouse may be used to release the
		grab.

		NOTE:   If called on object which implements mouse grabs,
			results in object getting grab from node above the
			object (i.e can not be used to grab mouse from self)

PASS:		*ds:si -- object to grab for

RETURN:		nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/91		Initial version

------------------------------------------------------------------------------@

VisGrabLargeMouse	method VisClass, MSG_VIS_GRAB_LARGE_MOUSE
	push	ax
	mov	al, mask VIFGF_MOUSE or mask VIFGF_GRAB or mask VIFGF_LARGE or \
		    mask VIFGF_PTR or mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisGrabLargeMouse	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	SendMouseInteractionBounds

SYNOPSIS:	Send new mouse for mouse interaction.

CALLED BY:	VisGrabMouse, VisReleaseMouse

PASS:		*ds:si 		-- object
		ax, bx, cx, dx  -- bounds, or zeroed if don't want to limit
					view scrolling to any bounds.

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 3/91		Initial version

------------------------------------------------------------------------------@

SendMouseInteractionBounds	proc	near
	;
	; Send up our bounds in case we need to notify some parent view.
	;
	sub	sp, size Rectangle
	mov	bp, sp
	mov	ss:[bp].R_left, ax
	mov	ss:[bp].R_top, bx
	mov	ss:[bp].R_right, cx
	mov	ss:[bp].R_bottom, dx
	mov	dx, size Rectangle	;pass this, even though we won't
					;  ObjMessage
;	mov	ax, MSG_VIS_VUP_SET_MOUSE_INTERACTION_BOUNDS
;	call	ObjCallInstanceNoLock	;send to ourselves, so it can be 
					;  subclassed if necessary.
	add	sp, size Rectangle
	ret
SendMouseInteractionBounds	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	VisGrabKbd

DESCRIPTION:	Implements keyboard grab.  Grabs keyboard input if no one has
		the grab.

PASS:		*ds:si -- object to grab for

RETURN:		nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisGrabKbd	method	VisClass, MSG_META_GRAB_KBD
	push	ax
	mov	al, mask VIFGF_KBD or mask VIFGF_GRAB or mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisGrabKbd	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisForceGrabKbd

DESCRIPTION:	Implements keyboard grab.  Grabs keyboard input, forcing the
		the previous owner to release.

PASS:		*ds:si -- object to grab for

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisForceGrabKbd	method VisClass, MSG_META_FORCE_GRAB_KBD
	push	ax
	mov	al, mask VIFGF_KBD or mask VIFGF_GRAB or mask VIFGF_FORCE or \
		    mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisForceGrabKbd	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisReleaseKbd

DESCRIPTION:	Releases keyboard grab.  

PASS:		*ds:si -- object to release the grab for

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisReleaseKbd	method	VisClass, MSG_META_RELEASE_KBD
	push	ax
	mov	al, mask VIFGF_KBD or mask VIFGF_NOT_HERE
	mov	ah, VIFGT_ACTIVE
	GOTO	VisAlterInputFlowCommon, ax

VisReleaseKbd	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCheckOptFlags

DESCRIPTION:	EC routine to see if update path is set in a valid state

CALLED BY:	GLOBAL

PASS:
	*ds:si	- visible object to test

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/1/89		Initial version

------------------------------------------------------------------------------@

VisCheckOptFlags	proc	far
if	ERROR_CHECK
	push	ax, bx, cx
	call	SysGetECLevel
	test	ax, mask ECF_NORMAL	; As this check is pretty method-
					; intensive, skip out if less than
					; normal level of EC level requested.
	jz	done
	clr	cl		; no req'ments yet.
	call	VisEnsureUpdatePath
done:
	pop	ax, bx, cx
endif
	ret				; Leave ret here in non-EC case,
					; so we can export routine

VisCheckOptFlags	endp

if	ERROR_CHECK

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisEnsureUpdatePath

DESCRIPTION:	EC routine to see if update path is set in a valid state

CALLED BY:	GLOBAL

PASS:
	*ds:si	- visible object to test
	cl	- UPDATE bits that must be set in this object up through
		  WIN_GROUP

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/1/89		Initial version

------------------------------------------------------------------------------@


VisEnsureUpdatePath	proc	far
	class	VisCompClass

	pushf
	push	ax, bx, cx, dx, si, di, bp
					; Only do this if EC level is normal
					; or above
	call	SysGetECLevel
	test	ax, mask ECF_NORMAL
	LONG jz	exit

	call	ECCheckVisFlags		; make sure basic vis stuff OK

	call	VisCheckIfSpecBuilt		; If not vis built, skip
	LONG jnc	exit

	mov	di, 1000		; this is EC only code, so who cares...
	call	ThreadBorrowStackSpace
	push	di

	push	cx
	push	si
	mov	ax, MSG_VIS_GET_OPT_FLAGS
	mov	bx, segment VisClass
	mov	si, offset VisClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	call	ObjCallInstanceNoLock
	test	cl, mask VOF_UPDATING		; are we current in an update?
	pop	cx
	LONG	jnz 	done			; yes, skip the check
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

						; See if composite & doesn't
						; manage children
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	VEUP_10				; skip if not
	test	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	jz	VEUP_10
						; IF not managing, don't
						; require geometry update path
	and	cl, not mask VOF_GEO_UPDATE_PATH

VEUP_10:
	; FIRST, make sure req'd path bits are set
	mov	al, ds:[di].VI_optFlags		; get optFlags
	and	al, cl				; mask w/bits that must be set
	cmp	al, cl
	jz	VEUP_20
	xor	al, cl				; figure out which are bad
	test	al, mask VOF_GEO_UPDATE_PATH
	ERROR_NZ	UI_BAD_GEO_UPDATE_PATH
	test	al, mask VOF_WINDOW_UPDATE_PATH
	ERROR_NZ	UI_BAD_WINDOW_UPDATE_PATH
	test	al, mask VOF_IMAGE_UPDATE_PATH
	ERROR_NZ	UI_BAD_IMAGE_UPDATE_PATH
VEUP_20:

	; THEN, if we're at win group, we're done.
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	done

	; GET NEW PATH BITS THAT WE'LL REQUIRE
	mov	al, ds:[di].VI_optFlags		; get optFlags
	test	ds:[di].VI_attrs, mask VA_MANAGED
	jnz	VEUP_25				; managed by parent, branch
						; Else don't require update path
	and	al, not (mask VOF_GEOMETRY_INVALID or \
			 mask VOF_GEO_UPDATE_PATH)
VEUP_25:
						; Else calc path bits needed
	mov	ah, al				; copy to ch
	and	ah, VOF_INVALID_BITS		; take invalid bits
	shr	ah, 1				; turn into path bits
	or	al, ah				; and "or" back in
	and	al, VOF_PATH_BITS		; keep only resulting path bits

						; If not composite or portal,
						; ignore window invalid bits.
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE or mask VTF_IS_PORTAL
	jnz	VEUP_30
	and	al, not mask VOF_WINDOW_UPDATE_PATH
VEUP_30:
	or	cl, al				; OR in new req'd flags

	call	VisSwapLockParent
	jnc	VEUP_afterParent

	call	VisEnsureUpdatePath	; recurse up to win group

VEUP_afterParent:
	call	ObjSwapUnlock

done:
	pop	di
	call	ThreadReturnStackSpace
exit:
	pop	ax, bx, cx, dx, si, di, bp
	popf
	ret
VisEnsureUpdatePath	endp
	
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisIfFlagSetCallVisChildren

DESCRIPTION:	This routine is for calling VISIBLE children in a visible
		tree.  The object & children may or may not have generic
		parts;  this routine DOES NOT rely on that portion of the
		instance data.   All children of the object are called, if
		any of the specified flags in VI_optFlags are set, although
		no messages are sent across to WIN_GROUP children.

CALLED BY:	GLOBAL

PASS:
	ax - message to pass
	*ds:si  - instance (vis part indirect through offset Vis_offset)
	dl	- flags to compare with children's VI_optFlags
			if 0, no compare will be made.
			if -1, no compare will be made, and will abort
				after a child returns the carry flag set
				(will return CX, DX, BP from the child
				in this case).
	cx 	- data to pass on to child. Data will be passed in both cx & dx.
	bp	- flags to pass on to any children called

RETURN:
	if was checking for children that return carry set,
		carry clear if no child returned carry set
		carry set if child returned carry set,
			cx, dx, bp = data returned from that child.
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, cx, dx, bp, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

VisIfFlagSetCallVisChildren	proc	far
	class	VisCompClass

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	mov	di, ds:[si]		;make sure composite
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance

	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	done			;if not, exit

	mov	di, offset CVCWFS_callBack
	call	VisCallCommonWithRoutine

done:
	ret

VisIfFlagSetCallVisChildren	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CVCWFS_callBack

DESCRIPTION:	If current object is a composite, call all non-WIN_GROUP
		children which have any of the specified flags in
		VI_optFlags set.


CALLED BY:	VisIfFlagSetCallVisChildren

PASS:
	*ds:si - child
	*es:di - composite
	dl - flags to compare with children's VI_optFlags
			if 0, no compare will be made, message will be sent
			if -1, no compare will be made, and will abort
				after a child returns the carry flag set
				(will return CX, DX, BP from the child
				in this case).
	cx - data to pass on to child, will be passed in both cx and dx.
	bp - data to pass on to child
	ax - message

RETURN:
	carry clear: means call next child.
		cx, dx, bp - data to send to next child
	carry set: means end processing children immediately
		cx, dx, bp - data returned from child
DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Eric	2/90		Added carry testing

------------------------------------------------------------------------------@


CVCWFS_callBack	proc	far
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	push	ax
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
					; MAKE SURE THERE IS A VISIBLE PART
	mov	bx, ds:[si]		; get ptr to child instance data
	cmp	ds:[bx].Vis_offset, 0	; Has visible part been grown yet?
	jne	testFlags		; branch if so
					; Else grow it.
	mov	bx, Vis_offset
	push	es:[LMBH_handle]	; save handle of comp block
	call	ObjInitializePart	; Make sure part has been grown
	pop	bx			; get handle of comp block
	call	MemDerefES		; restore segment of comp block to ES
	mov	bx, ds:[si]		; Get pointer to instance

testFlags:
	add	bx, ds:[bx].Vis_offset	; ds:bx = VisInstance

	; Don't send to any WIN_GROUP's.
	;
	test	ds:[bx].VI_typeFlags, mask VTF_IS_WIN_GROUP
					;*** IMPORTANT: CY=0 ***
	jnz	returnCY		;if WIN_GROUP, skip calling w/message

	tst	dl			;perform tests?
	jz	callChild		;skip if not...

	cmp	dl, -1			;abort after child returns carry?
	je	callChild		;skip if so...

	test	ds:[bx].VI_optFlags, dl	;are the required flags set?
					;*** IMPORTANT: CY=0 ***
	jz	returnCY		;skip if not...

callChild:
	push	cx, bp, dx		;save DX last!
					; Use ES version since *es:di is
					;	composite object
	mov	dx, cx			; pass cx value in both cx and dx
	call	ObjCallInstanceNoLock	;send it
	jnc	popRegsAndReturnCY	;if no carry returned, skip ahead
					;to pop regs and continue (FAST!)...
					;*** IMPORTANT: CY=0 ***

	pop	bx			;get saved DX value (don't trash
	push	bx			;returned DX until sure we can)
	cmp	bl, -1			;should we be checking for carry?
	clc
	jne	popRegsAndReturnCY	;skip if not (pass CY=0)...

	;caller returned CY set and we were checking for that. Return
	;CX, DX, and BP from the routine.

	add	sp, 6			;remove 3 words from stack
	stc				;return flag: continue with next
	jmp	short returnCY		;could save time here, but code
					;conventions prevail...

popRegsAndReturnCY:
	pop	cx, bp, dx		;restore registers for next call

returnCY:
	pop	ax
	ret
CVCWFS_callBack	endp


		
Resident ends
