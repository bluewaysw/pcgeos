COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visGeometry.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/89		Initial version

DESCRIPTION:
	This file contains geometry management routines for VisClass.
	
	$Id: visGeometry.asm,v 1.1 97/04/07 11:44:18 newdeal Exp $

-------------------------------------------------------------------------------@

VisUpdate segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisUpdateGeometry -- MSG_VIS_UPDATE_GEOMETRY for VisClass

DESCRIPTION:	Checks for invalid geometry for all objects below, and updates.
		The geometry is re-done for the object's parent if the object's
		geometry is out-of-date.  This is because a change in the
		object's size will affect its siblings.  If the composite the
		object is in has changed size as a result, we will set the
		geometry-invalid flag of the parent as well, forcing its
		composite's geometry to be re-done as well.

PASS:		*ds:si 	- instance data
		es     	- segment of VisClass
		di 	- MSG_VIS_UPDATE_GEOMETRY

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       		if not GEOMETRY_INVALID
       		     send to children recursively (may cause our object's 
		         out-of-date flag to be set if it isn't set already)
		if GEOMETRY_INVALID
		        save current size
		        call GET_SIZE message, passing current size (if 
				UPDATE_USING_DESIRED_SIZE is set, we'll pass
				desired size)
			call RESIZE message with what is returned
			call POSITION message with left and top (0,0 if window)
		        if bounds changed as a result
			    call MARK_INVALID message to set invalid geo for
			        parent
		clear GEOMETRY_INVALID and GEO_UPDATE_PATH flags
		    

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/22/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


VisUpdateGeometry	method	VisClass, MSG_VIS_UPDATE_GEOMETRY

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID  
	jnz	startUpdate			;geometry invalid, branch
	
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	done				;not composite, nothing to do

	mov	dl, mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH
	call	VisIfFlagSetCallVisChildren   	;visit all the children first
	
	mov	di, ds:[si]			;point at instance
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID  ;valid geometry?
	jz	done				;yes, exit without invalidating
	
startUpdate:
	;
	; Object's geometry is invalid.  Pick a starting size for this object.
	; We'll use the current size sitting around, unless the object has a 
	; zero size or it has VGF_UPDATE_USING_DESIRED_SIZE set, in which case
	; we'll start with desired size.
	;
	call	VisGetSize			;get current size of object
	tst	cx				;is width zero?
	jnz	startWithCurrent		;no, branch
	tst	dx				;is height zero?
	jnz	startWithCurrent		;no, start with current size
	
;startWithDesired:
	mov	cx, mask RSA_CHOOSE_OWN_SIZE	;pass desired dimensions
	mov	dx, mask RSA_CHOOSE_OWN_SIZE
	
startWithCurrent:
EC <	call	StartGeometry			;for showcalls -g	>
   	call	VisRecalcSizeAndInvalIfNeeded		;do optimized calc new size
EC <	call	EndGeometry			;for showcalls -g	>
        call	VisSetSize			;resize it
	clr	cl				;normal bounds
	call	VisGetBounds			;get the current bounds
	mov	cx, ax				;put left in cx
	mov	dx, bx				;and top in dx
	call	VisSendPositionAndInvalIfNeeded			;do optimized move
	jnc	done				;if bounds didn't change, exit

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:si -- VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP  ;at the top?
	jnz	done				;yes, don't go up
	
	;
	; Bounds of parent have changed, so set the geometry of the parent
	; to be invalid.  This will cause the composite the parent is in to
	; have its geometry recalculated.   Also, let's get the path bits set
	; at this point so that things are sure to get updated.
	;
	mov	cx, mask VOF_GEOMETRY_INVALID 
	mov	dl, VUM_MANUAL
	call	VisMarkInvalidOnParent
done:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
EC <	call	VisCheckOptFlags					>

	pop	di
	call	ThreadReturnStackSpace

   	Destroy	ax, cx, dx, bp
	ret

VisUpdateGeometry	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisResetToInitialSize
		MSG_VIS_RESET_TO_INITIAL_SIZE for VisClass

DESCRIPTION:	Resets geometry for an object and all of its children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RESET_TO_INITIAL_SIZE
		dl	- VisUpdateMode (VUM_NOW, VUM_MANUAL, etc.)

RETURN:		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
        Nothing can be passed in cx.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/14/90		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions
	Chris	7/29/91		Rewritten

------------------------------------------------------------------------------@

VisResetToInitialSize	method VisClass, MSG_VIS_RESET_TO_INITIAL_SIZE,
					 MSG_SPEC_RESET_SIZE_TO_STAY_ONSCREEN

	test	ds:[di].VI_attrs, mask VA_MANAGED	
	jz	exit				;not managed, forget it

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di
	push	ax
	call	SaveOldBounds			; We'll save the old bounds.
	pop	ax				; Usually this would happen
						; during geometry calculations,
						; But not when VGA_GEOMETRY_
						; CALCULATED is clear.
	;
	; Reset the geometry-calculated flag, so that initial size can be
	; used in generic objects.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	and	ds:[di].VI_geoAttrs, not mask VGA_GEOMETRY_CALCULATED
	
	push	dx				;save update mode
	push	bp				;save flag
	mov	cl, VUM_MANUAL			;don't update down below.
	clr	dl				;send to all children
	call	VisIfFlagSetCallVisChildren	;invalidate children, if any
	pop	bp				;restore flag
	pop	ax				;restore update mode
	
	;
	; Ensure that this thing is entirely re-done, regardless of bounds
	; changes.  -cbh 2/10/92
	; 
	mov	dl, al				;use update mode passed
	mov	cl, mask VOF_GEOMETRY_INVALID or \
		    mask VOF_IMAGE_INVALID or \
		    mask VOF_WINDOW_INVALID
	call	VisMarkInvalid			
	pop	di
	call	ThreadReturnStackSpace
exit:
	ret
VisResetToInitialSize	endm

			
			


COMMENT @----------------------------------------------------------------------

METHOD:		VisSetGeoAttrs -- 
		MSG_VIS_SET_GEO_ATTRS for VisClass

DESCRIPTION:	Sets non-composite geometry attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_SET_GEO_ATTRS
		cl	- flags to set
		ch	- flags to clear
		dl	- update mode (for VGA_NO_SIZE_HINTS or 
				           VGA_DONT_CENTER)

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/10/91		Initial version

------------------------------------------------------------------------------@

VisSetGeoAttrs	method dynamic	VisClass, MSG_VIS_SET_GEO_ATTRS
	mov	al, cl				;check for a couple of flags
	or	al, ch
	
	or	ds:[di].VI_geoAttrs, cl
	not	ch
	and	ds:[di].VI_geoAttrs, ch
	
	test	al, mask VGA_DONT_CENTER or mask VGA_NO_SIZE_HINTS
	jz	exit
	mov	cl, mask VOF_GEOMETRY_INVALID
	call	VisMarkInvalid			;mark geometry invalid
exit:
	Destroy	ax, cx, dx, bp
	ret
VisSetGeoAttrs	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisGetGeoAttrs -- 
		MSG_VIS_GET_GEO_ATTRS for VisClass

DESCRIPTION:	Returns non-composite geometry attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_GEO_ATTRS

RETURN:		cl	- VisGeoAttrs
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/10/91		Initial version

------------------------------------------------------------------------------@

VisGetGeoAttrs	method dynamic	VisClass, MSG_VIS_GET_GEO_ATTRS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].VI_geoAttrs
	ret
VisGetGeoAttrs	endm

		


COMMENT @----------------------------------------------------------------------

METHOD:		VisBoundsChanged -- 
		MSG_VIS_BOUNDS_CHANGED for VisClass

DESCRIPTION:	Handles bounds getting changed by the geometry manager.
		This default handler invalidates the old bounds, and 
		marks the object's image as invalid, so that the new bounds
		will also be invalidated.  Objects that don't draw themselves
		(i.e. some visComp's just have children, and don't draw) can
		subclass this message and do something different.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_BOUNDS_CHANGED
		
		ss:bp   - Rectangle: old bounds (or zeroes if no old bounds
			  to invalidate)
		dx	- size Rectangle

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/30/91		Initial version

------------------------------------------------------------------------------@

VisBoundsChanged	method static VisClass, MSG_VIS_BOUNDS_CHANGED
	uses	bx, di, es
	.enter

	;
	; If not yet realized, don't bother with any of this.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	markNewBoundsInvalid

	mov	ax, ss:[bp].R_left	; get old bounds
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom
	
	cmp	ax, cx			; old bounds were bogus, don't inval
	jz	exit
	cmp	bx, dx
	jz	exit
	test	cx, mask RSA_CHOOSE_OWN_SIZE
	jnz	exit
	test	dx, mask RSA_CHOOSE_OWN_SIZE
	jnz	exit

	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jnz	invalOld		; content, cannot afford to ignore old
					;    bounds!  -cbh 11/ 4/92

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP 
	jnz	markNewBoundsInvalid	; win group, can afford to ignore old
					;    bounds.

invalOld:	
	mov	di, mask VARF_NOT_IF_ALREADY_INVALID or \
		    mask VARF_ONLY_REDRAW_MARGINS
	call	VisInvalOldBounds	; nuke old bounds
	
markNewBoundsInvalid:
	;
	; Set the invalid bits in the object, so the new area will be redrawn
	; as well.  It is necessary to invalidate the new bounds so that the
	; object will draw at its new position.
	;
	mov	cx, mask VOF_WINDOW_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid		; mark invalid
exit:
	.leave
	ret
VisBoundsChanged	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	VisInvalOldBounds

SYNOPSIS:	Sends a MSG_VIS_ADD_RECT_TO_UPDATE_REGION to itself, if
		there's any bounds to invalidate.

CALLED BY:	VisCompBoundsChanged, VisBoundsChanged

PASS:		*ds:si -- object
		ax, bx, cx, dx -- rectangle to invalidate
		di low -- VisAddRectFlags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/31/91		Initial version

------------------------------------------------------------------------------@

VisInvalOldBounds	proc	near	uses	ax, cx, dx, bp
	.enter
	cmp	ax, cx			; any old bounds?
	je	exit			; no, just mark new image invalid
	cmp	bx, dx			
	je	exit
	
InvalOldBounds		label	near
	ForceRef	InvalOldBounds
	
	sub	sp, size VisAddRectParams
	mov	bp, sp
	mov	ss:[bp].VARP_bounds.R_left, ax	
	mov	ss:[bp].VARP_bounds.R_top, bx
	mov	ss:[bp].VARP_bounds.R_right, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx
	mov	ax, di
	mov	ss:[bp].VARP_flags, al
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams
exit:
	.leave
	ret
VisInvalOldBounds	endp


VisUpdate ends

