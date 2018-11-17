COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		VisClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VisClass		General purpose Visible object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	5/89		Improved documentation

DESCRIPTION:
	This file contains routines to implement the Visible class, which
	is subclassed to generate VisCompClass.

	$Id: visClass.asm,v 1.1 97/04/07 11:44:24 newdeal Exp $

------------------------------------------------------------------------------@
;see documentation in /staff/pcgeos/Library/User/Doc/VisClass.doc

UserClassStructures	segment resource

;
; Define the class record.
;
	VisClass	mask CLASSF_DISCARD_ON_SAVE

;
; NOTE:  ADD ANY OTHER VUP QUERIES CREATED HERE.
; VUP Query messages - send all to visible parent.
; 
    method VisGotoParentTailRecurse, VisClass, 
				MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
    method VisGotoParentTailRecurse, VisClass, 
				MSG_VIS_VUP_SET_MOUSE_INTERACTION_BOUNDS
    method VisGotoParentTailRecurse, VisClass, 
				MSG_VIS_VUP_GET_MOUSE_STATUS
    method VisGotoParentTailRecurse, VisClass, 
				MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION
    method VisGotoParentTailRecurse, VisClass, 
				MSG_VIS_VUP_BUMP_MOUSE
;
; Messages handled by VisClass routines
;
    method MetaGrabFocusExclLow,	VisClass, MSG_META_GRAB_FOCUS_EXCL
    method MetaReleaseFocusExclLow,	VisClass, MSG_META_RELEASE_FOCUS_EXCL
    method MetaGrabTargetExclLow,	VisClass, MSG_META_GRAB_TARGET_EXCL
    method MetaReleaseTargetExclLow,	VisClass, MSG_META_RELEASE_TARGET_EXCL
    method MetaGrabModelExclLow,	VisClass, MSG_META_GRAB_MODEL_EXCL
    method MetaReleaseModelExclLow,	VisClass, MSG_META_RELEASE_MODEL_EXCL
    method MetaReleaseFTExclLow, 	VisClass, MSG_META_RELEASE_FT_EXCL
    method VisRemove, 			VisClass, MSG_VIS_REMOVE
;
; Messages handled by non-VisClass routines
;
    method VisCallParentEnsureStack, VisClass, MSG_META_FUP_KBD_CHAR    
    method VisCallParentEnsureStack, VisClass, MSG_META_BRING_UP_HELP
;    
; Messages which should be handled only in EC version:
;
if	ERROR_CHECK
    method VisCallParentEnsureStack, VisClass, 
				MSG_VIS_VUP_EC_ENSURE_WINDOW_NOT_REFERENCED
    method VisCallParentEnsureStack, VisClass, 
				MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED
    method VisCallParentEnsureStack, VisClass, 
				MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED
endif

UserClassStructures	ends

;---------------------------------------------------

VisConstruct segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisInitialize -- MSG_META_INITIALIZE for VisClass

DESCRIPTION:	Initializes VisInstance data portion.  This includes setting
		the size of the object to 0 (bounds being (0,0) to (-1,-1),
		and marking the object invalid in all ways: image, window,
		& geometry.

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax, bx	-- DON'T CARE (may safely be called using CallMod)

RETURN:
	si	- intact	(For the benefit of VisCompInitialize, which
				 calls this directly)
	nothing
	ax, cx, dx, bp -- destroyed

DESTROYED:
	none (can be called via static binding)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisInitialize	method static	VisClass, MSG_META_INITIALIZE
	uses di, es		; to conform with static handler requirements
	.enter

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
				; Setup intial states of variables, from
				; constants defined above:
	mov	ds:[di].VI_attrs, VA_INITIAL_BITS
	mov	ds:[di].VI_optFlags, VOF_INITIAL_BITS
	mov	ds:[di].VI_specAttrs, SA_INITIAL_BITS

				; Check to see if this object is a member
				; of GenClass.
	push	di
	mov	di, segment GenClass
	mov	es, di
	mov	di, offset GenClass
	call	ObjIsObjectInClass
	pop	di
	jnc	VI_90		; skip if not, else
				; 	mark as being a generic object
	mov	ds:[di].VI_typeFlags, mask VTF_IS_GEN	
VI_90:
	.leave
	Destroy	ax, cx, dx, bp
	ret

VisInitialize	endm


VisConstruct	ends
;
;-------------------
;
VisOpenClose	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the VA_REALIZED bit, because vis objects 
		are not intended to be read from a file already 
		realized.


PASS:		*ds:si	= object
		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisReloc	method dynamic VisClass, reloc
	.enter

	cmp	dx,VMRT_RELOCATE_AFTER_READ
	jne	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	BitClr	ds:[di].VI_attrs, VA_REALIZED

	; If this is a composite object, clear out the window handle, which
	; can't possibly be valid, but instead must be re-created upon
	; reloading	-- Doug 4/12/93
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	afterGWin
	clr	ds:[di].VCI_window
afterGWin:

done:
	.leave
	mov	di, offset VisClass
	call	ObjRelocOrUnRelocSuper
	ret
VisReloc		endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisOpen -- MSG_VIS_OPEN for VisClass
		
	Called from within VisUpdateWinGroup, to open all non-group
	windows below this point in the tree.  Follows invalid window path
	to determine which windows need opening.


DESCRIPTION:

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisClass
	ax - MSG_VIS_OPEN
	bp - 0 if top of branch being VisOpen'ed, else window to appear on

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This message should be changed later to take advantage of a routine
	to be written into the window system which will allow multiple window
	manipulations to be done w/o validation, followed by a comprehensive
	validation, all in the name of efficiency.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@


VisOpen	method	dynamic VisClass, MSG_VIS_OPEN


	; first tell the specific UI if notification is needed

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	noNotify
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GI_attrs, mask GA_NOTIFY_VISIBILITY
	jz	noNotify
	push	bp
	mov	ax, MSG_SPEC_VIS_OPEN_NOTIFY
	call	ObjCallInstanceNoLock
	pop	bp
noNotify:

	call	ObjIncInteractibleCount	; INCREMENT INTERACTIBLE COUNT for
					; object block.  The other half of this
					; inc/dec pair is mirrored in
					; VisClose, which is one more reason
					; why these messages must be
					; symmetrical.

				; See if starting here
	tst	bp
	jnz	VCO_notTop		; branch if not

	; IF TOP BRANCH, PARENT WINDOW NEEDED
	
	; Fetch parent window to use by looking up visible tree, unless
	; this is a Content, which does it's own thing when called
	; with VIS_OPEN & bp = 0.
	;
	mov	di, ds:[si]		     	; point to instance
	add	di, ds:[di].Vis_offset	     	; ds:[di] -- VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jnz	VCO_determinedWin	     	; if content or root, don't
						; need to pass parent window.
	call	VisQueryParentWin  		; see who parent window is
						; (will return NULL if root
						; screen window)
EC <	tst	di						>
EC <	jnz	okWin						>
EC <	push	di, es						>
EC <	mov	di, segment GenScreenClass			>
EC <	mov	es, di						>
EC <	mov	di, offset GenScreenClass			>
EC <	call	ObjIsObjectInClass				>
EC <	pop	di, es						>
EC <	jc	okWin						>
EC <	ERROR	UI_NO_PARENT_WIN_FOUND				>
EC <okWin:							>
	mov	bp, di			    	; put in bp
VCO_determinedWin:

	; Now that we have the window to realize on, check to see if
	; we can go back to standard handling, which opens the window &
	; clears window & image invalid flags...

	; If this top object being opened is a window, then branch to
	; handle normally.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jnz	VCO_notTop

	; Otherwise, we have to work slightly differently - first
	; "Open" the object, then clear window invalid flags, BUT 
	; instead of clearing the image invalid flags, we must mark
	; the object as IMAGE_INVALID, because the window that this
	; object is on HAS NOT been opened, & will not be sending
	; a MSG_META_EXPOSED.
	call	OpenWindowHere			; Open this object's window,
						; if any

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance

	; Clear Window invalidation flags for object.  We will 
	; recurse to the bottom of the tree, so this will just ensure that
	; ALL are cleared.
	and	ds:[di].VI_optFlags, not (mask VOF_WINDOW_INVALID or \
					  mask VOF_WINDOW_UPDATE_PATH)

	; NOTE:  We don't need to do the EC work VisCheckOptFlags here, as
	; we can count on VisMarkInvalid just below to do this.

	; This we have to do because this routine gets called from within
	; MSG_VIS_UPDATE_WINDOWS_AND_IMAGE if the object has not been realized
	; yet.  Ensures that for non-windowed objects, the image is still
	; initialized as invalid.
	;
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_MANUAL			; In middle of update already,
						; don't update.
	call	VisMarkInvalid
	jmp	short VCO_DoChildren		; & branch to finish off
						; with children.
	


VCO_notTop:
	; IF NOT TOP BRANCH, PARENT WINDOW PASSED

	call	OpenWindowHere			; Open this object's window,
						; if any

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance

	; Clear Window & Image invalidation flags for object.  We will 
	; recurse to the bottom of the tree, so this will just ensure that
	; ALL are cleared.
	and	ds:[di].VI_optFlags, not (mask VOF_WINDOW_INVALID or \
					  mask VOF_WINDOW_UPDATE_PATH or \
					  mask VOF_IMAGE_INVALID or \
					  mask VOF_IMAGE_UPDATE_PATH)
EC <	call	VisCheckOptFlags		; Check VI_optFlags	>
	

VCO_DoChildren:
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	; CALL ALL CHILDREN, if we have any
	mov	ax, MSG_VIS_OPEN		; message to send on
	clr	dl				; no flags to test
	call	VisIfFlagSetCallVisChildren	; call all children, except

	pop	di
	call	ThreadReturnStackSpace

	Destroy	ax, cx, dx, bp			; for crossing WIN_GROUP's
	ret
	
VisOpen	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	OpenWindowHere

SYNOPSIS:	Opens this object's window.

CALLED BY:	VisOpen

PASS:		*ds:si -- handle of object
		bp -- handle of parent window

RETURN:		bp -- unchanged if no new window created, else is handle
		of new window ONLY if this is a composite object.  If this
		is NOT a composite object, then bp is trashed.

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version

------------------------------------------------------------------------------@

OpenWindowHere	proc	near
	class	VisCompClass
;	class	VisClass, VisCompClass	; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance

if	ERROR_CHECK

	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	OWH_ec10
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	ERROR_Z		UI_VIS_NON_COMPOSITE_OBJECT_MARKED_AS_IS_WINDOW
OWH_ec10:

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	OWH_ec20
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	ERROR_Z		UI_VIS_WIN_GROUP_OBJECT_MUST_BE_MARKED_AS_IS_WINDOW
	test	ds:[di].VI_typeFlags, mask VTF_IS_PORTAL
	ERROR_NZ	UI_VIS_WIN_GROUP_OBJECT_MARKED_AS_IS_PORTAL
OWH_ec20:

	test	ds:[di].VI_attrs, mask VA_REALIZED	
	ERROR_NZ	UI_VIS_OBJECT_ALREADY_OPENED
						
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	OWH_ec80		; skip test if not composite
	cmp	ds:[di].VCI_window, 0   	; see if window stored here
	ERROR_NZ	UI_VIS_COMP_OBJECT_NOT_REALIZED_YET_HAS_GWIN
OWH_ec80:

endif

					; see if windowed visual object
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	OWH_afterWin		;if not, branch

	;
	; ELSE Create the new window
	;

					; But first, inc in-use count,
					; for every case in which a window
					; is actually created.

	push	bp			; save passed window, in case we're a
					; portal  (cbh 2/20/91)
	call	ObjIncInUseCount	; INCREMENT IN-USE COUNT for object
					; block.  The other half of this
					; inc/dec pair is in the
					; message handler for MSG_VIS_CLOSE,
					; where it sends out a MSG_VIS_CLOSE_WIN
					; to cause the window to be closed.
	mov	ax, MSG_VIS_OPEN_WIN	; Open window
	call	ObjCallInstanceNoLock
	pop	bp			; restore passed window (cbh 2/20/91)

	mov	di, ds:[si]		;deref handle again
	add	di, ds:[di].Vis_offset	;ds:[di] -- VisInstance
					; If not composite object, don't
					; need to return window handle
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	OWH_Done		; branch if not a composite

					; If a portal, treat as a non-window
					; composite, using the window passed
					; in as the one we'll set as our window
					; and pass to our children. -cbh 2/20/91
	test	ds:[di].VI_typeFlags, mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN
	jnz	OWH_afterWin
	
	mov	bp, ds:[di].VCI_window	;return new window handle
EC <	tst	bp							>
EC <	ERROR_Z	UI_NULL_GWIN_RETURNED_FROM_MSG_VIS_OPEN_WIN		>
EC <	xchg	bx, bp							>
EC <	call	ECCheckWindowHandle					>
EC <	xchg	bx, bp							>

	jmp	short OWH_Done


OWH_afterWin:
					; if not a window, see if composite
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	OWH_Done		; if not, done
	;
	; Save window handle for non-win composites
	;
EC <	xchg	bx, bp							>
EC <	call	ECCheckWindowHandle					>
EC <	xchg	bx, bp							>
	mov	ds:[di].VCI_window, bp	;keep window handle in instance data

OWH_Done:
	or	ds:[di].VI_attrs, mask VA_REALIZED	; mark object
							; as realized
	ret

OpenWindowHere	endp

VisOpenClose	ends
;
;-------------------
;
VisUpdate	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisUpdateWindowsAndImage
		
	Called from within VisUpdateWinGroup, to update all non-group
	windows below this point in the tree.  Follows invalid window path
	to determine which windows need updating.  "Updating" includes 
	moving & resizing of windows to match current VI_bounds.

	ALSO!  Now follows image invalid path as well, making sure that
	the image is updated for any objects that need it.


DESCRIPTION:

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisClass
	ax - MSG_UPDATE_WINDOWS
	bp	- 0 if top window
	cl 	- VisUpdateImageFlags --
		   Message callers should always clear this flag on
		   entry.

RETURN:		cl - preserved
		ax, ch, dx, bp - destroyed


DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

       if IS_WINDOW
           clear already-invalidated flag
       if already-invalidated and VOF_IMAGE_INVALID
           VisInvalidate
	   set already-invalidated flag
       CallChildrenWithFlagSet (VOF_IMAGE_UPDATE_PATH)
       clear image invalid and path flags

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This message should be changed later to take advantage of a routine
	to be written into the window system which will allow multiple window
	manipulations to be done w/o validation, followed by a comprehensive
	validation, all in the name of efficiency.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Chris	8/27/91		Changed to keep separate inval flags, one for
				ourselves and one for our children, to keep
				portals working correctly.

------------------------------------------------------------------------------@


VisUpdateWindowsAndImage	method	dynamic VisClass, \
					MSG_VIS_UPDATE_WINDOWS_AND_IMAGE

	push	cx				; Preserve image flag so that
						; it may be returned intact

	; IF OBJECT ISN'T REALIZED, REALIZE IT.
	; IF WINDOW ISN'T UP TO DATE, FIX IT.
	;
	call	UpdateWindowHere		; Update this window, if
						; it needs it.  (ch now holds
						; VisUpdateImageFlags that the
						; parent will examin; cl holds
						; flags to pass on to children)
	; UPDATE OBJECT'S IMAGE HERE
	;
	
	test	ch, mask VUIF_ALREADY_INVALIDATED ; Test to see if the area
						; of this object has already
						; been WinInvalidated
	jnz	doneWithImage			; yes, branch

						; Otherwise, invalidate object
						; if INVALID bit set.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID
	jz	doneWithImage			; image valid, branch

;invalidate:
	;
	; Invalidate the object.  We will add our bounds to the update region,
	; either the entire area of the object (for a non-composite,or comp with
	; VCGA_ONLY_DRAWS_IN_MARGINS clear) or the margins around the object
	; (composite with VCGA_ONLY_DRAWS_IN_MARGINS set).  If the object
	; was just VIS_OPENed, then we'll definitely redraw the whole thing.
	;
	push	cx, si
	mov	cl, mask VARF_ONLY_REDRAW_MARGINS ;indicate we can just inval 
						;  margins for normal comps
	test	ch, mask VUIF_JUST_OPENED
	jz	addBounds	
	clr	cl				;this will force the routine
						;  to redraw the entire object.
addBounds:
	call	AddOurBoundsToUpdateRegion	;invalidate our bounds
	pop	cx, si

	;
	; If we're a non-composite, or a composite that draws stuff between
	; its children, we`ll set cl so we don't invalidate any children.
	; (cbh 11/ 1/91)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di = VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	setAlreadyInvalidated		; not a composite, branch
	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jz	setAlreadyInvalidated		; inval'ed entire object,
						;   children don't need
						;   invalidation
	mov	cl, mask VUIF_SEND_TO_ALL_CHILDREN	; else make sure we hit the
	clr	dl				;   children (unfortunate 
	jmp	short callChildren		;   imagery, I know.)
						
setAlreadyInvalidated:				
	mov	cl, mask VUIF_ALREADY_INVALIDATED ; Say that a WinInval has been
						; performed in the branch, and
						; thus do not need to inval
						; children.
doneWithImage:
	;
	; If always invalidating, we'll invalidate and send to all the 
	; children, regardless of their image-invalid status, preserving
	; the current flags.  This allows the children of "invalidated"
	; composites whose margins only are invalidated, to get their children
	; done as well.
	;
	test	ch, mask VUIF_SEND_TO_ALL_CHILDREN
	jz	followPathBits
	clr	dl				; we'll send to ALL children
	jmp	short callChildren

followPathBits:

	; See if we need to do children (Is either path bit set?)
	;
	mov	di, ds:[si]			;clear flags
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance
	test	ds:[di].VI_optFlags, mask VOF_WINDOW_UPDATE_PATH or \
				     mask VOF_IMAGE_UPDATE_PATH
	jz	afterChildrenDone		;skip if we don't need to do
						;	children

	; DO CHILDREN (if we have any)
	
						;Follow invalid paths only
	mov	dl, mask VOF_WINDOW_INVALID or \
		    mask VOF_WINDOW_UPDATE_PATH or \
		    mask VOF_IMAGE_INVALID or \
		    mask VOF_IMAGE_UPDATE_PATH
		    
callChildren:
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	mov	bp, -1				; Data to pass on to children
	mov	ax, MSG_VIS_UPDATE_WINDOWS_AND_IMAGE	; Method to pass on
	call	VisIfFlagSetCallVisChildren

	pop	di
	call	ThreadReturnStackSpace

afterChildrenDone:
	;
	; In any case, now that our children have cleared all of their
	; image & window invalid/update_path bits, we can clear ours as
	; well.
	;
	mov	di, ds:[si]			;clear flags
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance
	and	ds:[di].VI_optFlags, not (mask VOF_IMAGE_INVALID or \
					  mask VOF_IMAGE_UPDATE_PATH or \
					  mask VOF_WINDOW_INVALID or \
					  mask VOF_WINDOW_UPDATE_PATH)
   
   	;
   	; If this is a win-group or normal portal, we've completed invalidation
	; on this branch and need to invalidate the region that we've been
	; saving from MSG_VIS_ADD_RECT_TO_UPDATE_REGION.   
	;

;	Forget about portals.  The contents get invalidated with WIN_INVALID, 
;	the stuff around the portal needs to happen at the win group.
;	-cbh 3/ 3/93)
;	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP or \
;				      mask VTF_IS_PORTAL

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	exit

;	test	ds:[di].VI_typeFlags, mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN
;	jnz	exit
	call	InvalUpdateRegionIfNeeded
	
exit:

EC <	call	VisCheckOptFlags		; Check VI_optFlags	>
	pop	cx				; Restore cx value unscathed

	Destroy	ax, dx, bp
	ret

VisUpdateWindowsAndImage	endm

				
				



COMMENT @----------------------------------------------------------------------

ROUTINE:	InvalUpdateRegionIfNeeded

SYNOPSIS:	Invalidates the update region if there is one.

CALLED BY:	VisCompUpdateWinGroup

PASS:		*ds:si -- win group object

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/30/91	Initial version
	Chris	3/ 6/93		Rewritten to remove parameter passing to the
				region, VisContent scroll offsets included

------------------------------------------------------------------------------@

InvalUpdateRegionIfNeeded	proc	near		uses	si
	class	VisContentClass
	.enter
	mov	ax, TEMP_VIS_INVAL_REGION	;get chunk with inval region
	call	ObjVarFindData
	jnc	exit				;nothing found, exit
	mov	bx, {hptr} ds:[bx]		;in *ds:bx
	ChunkSizeHandle	ds, bx, di		;see how big the source is
	tst	di
	jz	exit				;nothing there, branch

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VCI_window		;window in ^hdi

	mov	bp, ds				;set up region in bp:si
	mov	si, bx				
	push	si
	mov	si, ds:[si]			
	
InvalUpdateRegion	label near		;for showcalls -I
	ForceRef	InvalUpdateRegion

	call	DocInvalRegion

	pop	ax
	clr	cx				;zero the region to nothing...
	call	LMemReAlloc
exit:
	.leave
	ret
InvalUpdateRegionIfNeeded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocInvalRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as WinInvalReg, but uses region in Document 
		coords instead of window coords

CALLED BY:	InvalUpdateRegionIfNeeded
PASS:
	In DOCUMENT coordinates:
		bp:si - region (0 for rectangular)
		di - handle of graphics state, or window

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Why do we do this?  The only time window and document coordinates
	differ is in Contents within scrolling views, that do _not_
	have the VCNA_VIEW_DOES_NOT_WIN_SCROLL flag set.  In that
	case, VCNI_docOrigin usually contains the difference
	between the two coordinate systems, and can be used
	to compute window coordinates when the object is marked invalid.

	But if the view win-scrolls between the time the object
	is marked invalid, and VIS_UPDATE_WINDOWS_AND_IMAGE
	comes in, that region will not have the correct window
	coordinates.  This is why we're keeping the region
	in document coords until the last minute, when the
	window's coordinate system is known for sure.

	Note that at this time, VCNI_docOrigin still
	might not be updated, so we can't depend on that
	to figure the translation.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocInvalRegion	proc	near
	uses	ds
	.enter

	;
	; Find out how far the region needs to be translated
	; to get to Window coords
	;
	push	si				; +1 : region offset
	segmov	ds, ss
	sub	sp, size TransMatrix
	mov	si, sp
	call	WinGetTransform			; winTrans filled in
	;
	; Extract x,y translation from matrix (only WWFixed portion
	; of DWFixed will be used)
	;
	add	si, offset TM_e31		; ds:si = (x,y) translation
	lodsw			
	mov_tr	dx, ax				; dx = x.frac
	lodsw					; ax = x.int.low
	rndwwf	axdx, cx			; cx = rounded X
	lodsw					; skip x.int.high
	lodsw			
	mov_tr	bx, ax				; bx = y.frac
	lodsw					; ax = y.int
	rndwwf	axbx, dx			; (cx, dx) = translation
	add	sp, size TransMatrix
	;
	; If translation = (0,0), then skip moving the region
	;
	pop	si				; -1 <- region offset
	mov	ds, bp				; ds:si = region
	tst	dx
	jnz	doTranslate
	jcxz	doInval

doTranslate:
	mov_tr	bx, si				; save region offset
	call	GrMoveReg			; ax destroyed
	mov_tr	si, bx				; ds:si = region
doInval:
	call	WinInvalReg

	.leave
	Destroy	ax, bx, cx, dx
	ret
DocInvalRegion	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateWindowHere

SYNOPSIS:	Updates this object's window.

CALLED BY:	INTERNAL
		VisUpdateWindowsAndImage

PASS:		*ds:si -- handle of object

	cl 	- VisUpdateImageFlags passed to object 

RETURN:
	cl	- VisUpdateImageFlags to send on to children:
		  IF this object is a window, then this bit is set to
		  non-zero if this object is WinInvalidated for some
		  reason (opened, resized), else cleared to indicated that
		  we're in a fresh window which hasn't been inval'ed yet.
		  (cl not set if the window is a VTF_CHILDREN_OUTSIDE_PORTAL_WIN,
		  because the children lie outside of the window area, and
		  hence are not invalidated when the window is invalidated).
		  
	ch	- VisUpdateImageFlags for the object to use itself:
		  Same as cl, except this is the flag our object looks at
		  when deciding whether to deal with VOF_IMAGE_INVALID.
		  Will be the same as cl in all cases except for portals,
		  which if WinInvalidated will pass a set cl to its children,
		  but still needs to VisInvalidate itself because it has areas
		  that it draws to outside the window.  VUIF_JUST_OPENED can
		  also be set if the object was sent a MSG_VIS_OPEN by this
		  routine.

DESTROYED:	ax, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version
	Chris	7/ 8/91		Removed seemingly ridiculous "uses cx"
	Chris	8/27/91		Changed to not return cl=TRUE if the window
				is a special portal.

------------------------------------------------------------------------------@

UpdateWindowHere	proc	near		uses	bp
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.

	
	.enter
	mov	ch, cl			; assume for now that both cl and ch
					;   will be the same.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance

					; If this is a window, then clear cl,
					; indicating an assumption that it's
					; not going to be invalidated (may
					; chang later in routine)
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	afterNewWinTest
	and	cx, not (mask VUIF_ALREADY_INVALIDATED or \
			 (mask VUIF_ALREADY_INVALIDATED shl 8))	
	
afterNewWinTest:
					; See if realized yet
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	UWH_realized		; if so, continue

	; IF NOT, then visually open this branch first.
	push	cx
	clr	bp			; Indicate top window being realized
	mov	ax, MSG_VIS_OPEN
	call	ObjCallInstanceNoLock
	pop	cx
	or	ch, mask VUIF_JUST_OPENED  ; Say that we've just been opened.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance

					; If the object was a window, then
					; it has been WinInval'd as a by-
					; product of being opened.
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	UWH_realized

	call	ReturnInvalidatedIfChildrenInWindow

UWH_realized:

	;
	; Move and resize Windows that already exist
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	noInvalHere		; if not a window, exit
	
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jnz	noInvalHere		; Can't MOVE_RESIZE content objects,
					; since they don't actually have their
					; own window...
	
	test	ds:[di].VI_optFlags, mask VOF_WINDOW_INVALID
	jz	noInvalHere		; skip if not invalid
	
	push	cx
	mov	ax, MSG_VIS_MOVE_RESIZE_WIN
	call	ObjCallInstanceNoLock
	pop	cx

	call	ReturnInvalidatedIfChildrenInWindow
					; A window which is resized is
					; completely WinInval'd
noInvalHere:
	clc				; Didn't just invalidate
	.leave
	ret
UpdateWindowHere	endp


ReturnInvalidatedIfChildrenInWindow	proc	near
	class	VisClass
	
	;
	; Assume not already invalidated.  We'll leave the always-invalidate
	; flag as it is.
	;
	and	cx, not (mask VUIF_ALREADY_INVALIDATED or \
			 (mask VUIF_ALREADY_INVALIDATED shl 8))	
	
	;
	; If this is a special portal, the children are not in the window,
	; and may not be affected at all by the moving of the window.  We'll
	; exit with VUIF_ALREADY_INVALIDATED cleared (although VUIF_ALWAYS_
	; INVALIDATE may still be set).  
	;
	test	ds:[di].VI_typeFlags, mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN
	jnz	exit			
					
					
	;
	; For any other object, we'll definitely have invalidated the window
	; the children are in, so no more invalidation is needed from that
	; point.
	;
	mov	cl, mask VUIF_ALREADY_INVALIDATED
			
	;
	; If this is a regular portal, the portal object's drawing is not
	; affected by the MOVE_RESIZE_WIN, so we still want to invalidate
	; it if needed.  We'll exit with VUIF_ALREADY_INVALIDATED cleared 
	; (although VUIF_SEND_TO_ALL_CHILDREN may still be set).
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_PORTAL
	jnz	exit			
	
	;
	; Not a portal, object's drawing area has been cleared by the window
	; change, set this flag and clear the always-invalidate.
	;
	mov	ch, mask VUIF_ALREADY_INVALIDATED
exit:
	ret
ReturnInvalidatedIfChildrenInWindow	endp

VisUpdate	ends
;
;-------------------
;
VisOpenClose	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisClose -- MSG_VIS_CLOSE for VisClass

DESCRIPTION:
		This is a recursive message which goes down the visible tree,
	stopping short at any WIN_GROUP visibles which may be in the tree.
	Any VisComps which are marked as a WINDOW or PORTAL are sent
	a MSG_WIN_CLOSE to close down the graphics windows on which they
	appear.   This message is sent down to  all visible children (except
	for WIN_GROUP's) so that they are notified that the visible tree
	they are on is coming off the screen.

	NOTE:  At this time, this is the last message that an object will
	see in the case of the application setting a WIN_GROUP not usable,
	generically removing it, and DESTROYING the object block.  Therefore,
	UI objects will want to diconnect themselves from the environment
	so that they are free to be destroyed.

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisClass
	ax - MSG_VIS_CLOSE


RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This message should be changed later to take advantage of a routine
	to be written into the window system which will allow multiple window
	manipulations to be done w/o validation, followed by a comprehensive
	validation, all in the name of efficiency.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@


VisClose	method	dynamic VisClass, MSG_VIS_CLOSE

	; first tell the specific UI if notification is needed

	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	noNotify
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GI_attrs, mask GA_NOTIFY_VISIBILITY
	jz	noNotify
	mov	ax, MSG_SPEC_VIS_CLOSE_NOTIFY
	call	ObjCallInstanceNoLock
noNotify:

	; If already unrealized, we're done.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	LONG	jz	VC_Done

	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	afterChildren

	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	afterCompositeWin

	; Send notification that this window is about to be closed.  A default
	; handler will move it off-screen if it has children, to prevent
	; unecessary window reg calculations & screen flickering.
	;
	mov	ax, MSG_VIS_WIN_ABOUT_TO_BE_CLOSED
	call	ObjCallInstanceNoLock

afterCompositeWin:

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	; CALL ALL CHILDREN, if we have any
	mov	ax, MSG_VIS_CLOSE		; message to send on
	clr	dl				; no flags to test
	call	VisIfFlagSetCallVisChildren	; call all children, except
						; for crossing WIN_GROUP's

	pop	di
	call	ThreadReturnStackSpace

afterChildren:


	; IF OBJECT HAS A WINDOW, CLOSE IT
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance

EC <	; If win closed already, ERROR		>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	jz	VC_e10							>
EC <	push	bx							>
EC <	mov	bx, ds:[di].VCI_window  		; get window handle	>
EC <	tst	bx							>
EC <	ERROR_Z	UI_VIS_COMP_OBJECT_MARKED_REALIZED_WITHOUT_GWIN		>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>
EC <VC_e10:								>

	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	VCU_notWin	; if not, skip

	mov	ax, MSG_VIS_CLOSE_WIN	; Close window
	call	ObjCallInstanceNoLock

	call	ObjDecInUseCount	; DECREMENT IN-USE COUNT for object
					; block.  The other half of this
					; inc/dec pair is in VisOpen, where
					; it sends out a MSG_VIS_OPEN_WIN to
					; cause the window to be created in
					; the first place.

						; If this is a special portal,
						; we'll zero out the gWin
						; ourselves -- it's our parent
						; win rather than our window.
						; (2/20/91 cbh)
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_PORTAL
	jz	VCU_afterClosed
	test	ds:[di].VI_typeFlags, mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN
	jz	VCU_afterClosed			
						
						
VCU_notWin:					

	; IF OBJECT IS A COMPOSITE, NULL OUT WINDOW HANDLE
				; see if composite
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	VCU_notComposite	; if not, skip to just clear bits

				; if just composite, zero out window handle
	mov	ds:[di].VCI_window, 0
	jmp	short VCU_afterClosed

VCU_notComposite:

VCU_afterClosed:

	; CLEAR INVALID FLAGS
				; Clear both bits regarding window being invalid
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance

				; Mark as no longer realized
	and	ds:[di].VI_attrs, not mask VA_REALIZED

	call	ObjDecInteractibleCount	; DECREMENT INTERACTIBLE COUNT for
					; object block.  The other half of this
					; inc/dec pair is mirrored in
					; VisOpen, which is one more reason
					; why these messages must be
					; symmetrical.

VC_Done:

;	You need to clear these flags, as it is possible that children are
;	waiting to reopen themselves (they have the WINDOW_INVALID bit set),
;	when the parent closes. If we just exit here, these children never
;	have their VOF_WINDOW_INVALID/VOF_WINDOW_UPDATE_PATH bits cleared,
;	while their parents *do* have them cleared, which is an illegal
;	state.

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
	and	ds:[di].VI_optFlags, not (mask VOF_WINDOW_INVALID or mask VOF_WINDOW_UPDATE_PATH)
EC <	call	VisCheckOptFlags		; Check VI_optFlags	>

	Destroy	ax, cx, dx, bp
	ret

VisClose	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisWindowAboutToBeClosed

DESCRIPTION:	The window stored in this visible object is about to be closed.
		Before each children is closed one by one, until this window
		itself is closed, let's move it off-screen to avoid flicker &
		unecessary window region calculations.

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisClass
	ax - MSG_VIS_WIN_ABOUT_TO_BE_CLOSED

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Moved here as message from VisUtils

------------------------------------------------------------------------------@

VisWindowAboutToBeClosed	method	dynamic VisClass, 
					MSG_VIS_WIN_ABOUT_TO_BE_CLOSED

EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW		>
EC <	ERROR_Z	UI_NO_WINDOW_TO_CLOSE					>
	mov	di, ds:[di].VCI_window	; get window handle
	or	di, di
	jz	done			; if no window, done

	mov	si, WIT_FIRST_CHILD_WIN	; see if this window has child windows
	call	WinGetInfo
	tst	ax
	jz	done			; if not, don't bother moving off
					; screen, since there will be no
					; gain over just closing the window.

	call	WinGetWinScreenBounds	; Get current bounds of window
	tst	cx			; If right edge is negative, done.
	js	done

	mov	ax, cx			; Otherwise, move right edge to left
	neg	ax			; edge of screen,
	dec	ax			; & one more to be completely off.
	clr	bx			; leave as is vertically
	clr	si			; move relative
	call	WinMove
done:
	Destroy	ax, cx, dx, bp
	ret

VisWindowAboutToBeClosed	endm


VisOpenClose ends

;-------------

VisCommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		VisVupQueryClass

DESCRIPTION:	Searches up the visible tree for an object of the class
		specified.  If found, the object is returned.

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_VIS_VUP_FIND_OBJECT_OF_CLASS

	^lcx:dx	- class of object to look for.

RETURN:
	carry	- set if object found
	^lcx:dx	- object, if found, else null
	ax, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

VisVupQueryClass method	dynamic VisClass, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	mov	es, cx
	mov	di, dx
	call	ObjIsObjectInClass	; see if object is member of class
	jc	found			; branch if so
	call	VisCallParentEnsureStack	; otherwise, pass on to parent
	jc	exit			; found our guy, branch
	clr	cx			; else zero the return value
	mov	dx, cx
	jmp	short exit

found:
	mov	cx, ds:[LMBH_handle]	; return, with THIS object, as it
	mov	dx, si			; is a member of the class passed.
	stc
exit:
	Destroy	ax, bp
	ret
VisVupQueryClass	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisVupCreateGState

DESCRIPTION:	Searchs upwards until a WIN_GROUP is found, then creates
		a GState based on its window handle.  Skips past non-WIN_GROUP
		composites, even though they have window stored in them,
		to give large (32-bit) composites a chance to intercept this
		message & apply a 32-bit translation to the GState.

		If no handler is found, a GState is created anyway, referencing
		a null window.

		Specific UI's may intercept this message in order to store
		a DisplayScheme in the private data of the GState, & to
		change the default state to SPUI standards.  Note also that
		specific UI's may wish to intercept this message at the
		composite level, as opposed to WIN_GROUP level, for speed,
		since 32-bit support in UI areas is not an issue.

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisClass
	ax - MSG_VIS_VUP_CREATE_GSTATE

RETURN: carry	- set
		  
	bp 	- handle of GState,
		  which references window that object is realized under,
		  if any, otherwise references a NULL window.
		  Note that in all cases a GState is created, & therefore will
		  have to be destroyed by the caller (Using GrDestroyState)
	ax, cx, dx - destroyed

DESTROYED:	
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Doug	4/91		Modified to keep passing up until a WIN_GROUP
				is found, for 32-bit support.

------------------------------------------------------------------------------@

VisVupCreateGState	method	dynamic VisClass, MSG_VIS_VUP_CREATE_GSTATE
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	hitWinGroup

	call	VisCallParentEnsureStack	; if not a window group, try parent
	jnc	notAnswered	; branch if not answered
	ret			; else return response

notAnswered:
	clr	di		; if not answered, create a GState that 
				; references no window.
	jmp	short createState

hitWinGroup:
				; fetch window in cx
	mov	di, ds:[di].VCI_window

createState:
	call	GrCreateState	; Assocate GState with window/null passed.
	mov	bp, di		; return in bp
	stc			; return carry, indicating GState created
	Destroy	ax, cx, dx
	ret

VisVupCreateGState	endm
	

VisCommon	ends
;
;-------------------
;
VisUpdate	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisInvalidate -- MSG_VIS_INVALIDATE for VisClass

DESCRIPTION:	Invalidate the area of this object's bounds on the window
		that it appears on.  If this is the window, makes the proper
		adjustment in the bounds before invalidating.

PASS:
	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of VisClass
	ax - MSG_VIS_INVALIDATE

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris	3/24/89		Changed to do correct thing in windows.
	Chris   11/30/89	Changed to do correct thing in contents.
	Jim   	1/10/90		Changed to use WinInvalRect, not WinInvalReg
	Chris	6/91		Updated for new graphics, vis bounds conventions


------------------------------------------------------------------------------@

VisInvalidate	method	VisClass, MSG_VIS_INVALIDATE
	mov	cl, mask VARF_ONLY_REDRAW_MARGINS ;indicate our bounds passed
	call	AddOurBoundsToUpdateRegion	;invalidate our bounds
	Destroy	ax, cx, dx, bp
	ret

VisInvalidate	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	AddOurBoundsToUpdateRegion

SYNOPSIS:	Adds our bounds to the update region, via the flag passed.
		Gets object's bounds to invalidate, then calls MSG_VIS_VUP_
		ADD_RECT_TO_UPDATE_REGION, passing the desired flags.

CALLED BY:	VisInvalidate, VisMakeNotUsable

PASS:		*ds:si -- object
		cl     -- VisAddRectFlags to pass to MSG_VIS_ADD_RECT_TO-
				UPDATE_REGION

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/18/91		Initial version

------------------------------------------------------------------------------@

AddOurBoundsToUpdateRegion	proc	far
	class	VisClass
	
	push	cx			; save VisAddRectFlags
	call	VisGetBounds
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jnz	10$			; leave contents alone
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	jz	10$			; not a window, branch
	;
	; If a window, we need coordinates to be 0,0,...
	;
	sub	cx, ax			; adjust right
	clr	ax			; and left
	sub	dx, bx			; and bottom
	clr	bx			; and top
10$:
	pop	di			; restore VisAddRectFlags
	sub	sp, size VisAddRectParams
	mov	bp, sp
	mov	ss:[bp].VARP_bounds.R_left, ax
	mov	ss:[bp].VARP_bounds.R_top, bx
	mov	ss:[bp].VARP_bounds.R_right, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx
	mov	cx, di
	mov	ss:[bp].VARP_flags, cl
	
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams
	ret
AddOurBoundsToUpdateRegion	endp




COMMENT @----------------------------------------------------------------------

METHOD:		VisSetVisAttrs -- MSG_VIS_SET_ATTRS for VisClass

DESCRIPTION:	Change visible flags for an object (record structure
		of VisFlags, which is in every visible object).  Also
		set invalid bits appropriately so the changes can be
		realized later in a MSG_VIS_VUP_UPDATE_WIN_GROUP.

PASS:
	*ds:si - instance data (vis part indirect through offset Vis_offset)
	es - segment of VisClass

	ax 	- MSG_VIS_SET_ATTRS
	cl 	- bits to set
	ch 	- bits to reset

	Bits that may be changed are:
		VA_VISIBLE		- set if should be visible, if parent
					  is.
		VA_MANAGED		- set if geometrically managed
		VA_DRAWABLE		- set if drawable (invisible)
		VA_DETECTABLE		- set if hit detectable w/mouse

	dl	- VisUpdateMode
	
RETURN:
	cx, dx, bp - preserved
	ax destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:
	dl -- contains invalid bits to pass to MSG_VIS_MARK_INVALID for child
	dh -- contains invalid bits to pass to MSG_VIS_MARK_INVALID of parent

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
        If we never add any more attr bits, this could be simplified slightly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/89		Initial version
	Chris	11/ 5/92	Changed to more cleverly check flags.

------------------------------------------------------------------------------@

VisSetVisAttrs	method	dynamic VisClass, MSG_VIS_SET_ATTRS
	uses	cx, dx, bp
	.enter
		
EC <	; Make sure that instance data is not hosed			>
EC <	call	ECCheckVisFlags						>
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

EC <	test	cl, not (mask VA_VISIBLE or mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE or mask VA_FULLY_ENABLED)
EC <	ERROR_NZ	UI_BAD_SET_VIS_ATTR_FLAGS			>
EC <	test	ch, not (mask VA_VISIBLE or mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE or mask VA_FULLY_ENABLED)
EC <	ERROR_NZ	UI_BAD_SET_VIS_ATTR_FLAGS			>
   
	push	dx				; Save update mode

	clr	bx				;no invalid bits to set yet
	mov	di, ds:[si]	       		;point to instance data
	add	di, ds:[di].Vis_offset

	mov	al, ds:[di][VI_attrs]		;get the current flags
	;
	; Figure out which invalid bits to set according to the changes
	; being made in the attr flags.
	;
	mov	dl, al				;dl <- current flags
	or	al, cl				;or in flags
	not	ch
	and	al, ch				;al <- new flags
	xor	dl, al				;see what changed

	test	dl, mask VA_MANAGED		;changing managed flag?
	jz	VSA10				;no, branch
	or	bh, mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH
						;set parent geometry invalid, 
						; and make sure we are 
						; propagating the geo path bit
						; if previously set in the 
						; child (cbh 5/ 8/91)
	
						;else set this in parent
VSA10:
	test	dl, mask VA_VISIBLE		;see if visibility change
	jz	VSA15				;skip if not
	or	bl, mask VOF_WINDOW_INVALID	;mark window as being invalid
VSA15:
	test	dl, mask VA_DRAWABLE		;see if drawability change
	jz	VSA20				;not set, branch
	or	bl, mask VOF_IMAGE_INVALID	;else set in
VSA20:
	push	ax, cx
	
	tst	bl
	jz	SA_60
	mov	cl, bl				;get bits to set
	mov	dl, VUM_MANUAL			;on this object, don't update
	push	bx
	call	VisMarkInvalid			;mask invalid bits in child
	pop	bx
SA_60:

	tst	bh
	jz	SA_70
	mov	cl, bh				;get bits to set
	mov	dl, VUM_MANUAL			;Updating manually
	call	VisMarkInvalidOnParent
SA_70:
	;
	; Set these attributes NOW, after doing the invalidation. Used to
	; be before VisMarkInvalid, but the update flag error checking bases
	; some of its decision on the state of the object (i.e. managed, etc)
	; and setting the flags before the error checking gives it the wrong
	; impression about what's going on. -cbh 5/ 7/91
	;

	pop	ax, cx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di][VI_attrs], al		;store new flags

	pop	dx			; Get update flags to use
	cmp	dl, VUM_MANUAL
	je	SA_90
					; Do update, according to update
					; flags
	call	VisVupUpdateWinGroup	; call statically

SA_90:
	.leave
	Destroy	ax
	ret

VisSetVisAttrs	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisVupUpdateWinGroup

DESCRIPTION:	Walks up tree until a WIN_GROUP is found, then calls
		VisCompVupUpdateWinGroup on it.

CALLED STATICALLY BY:

PASS:		*ds:si - instance data

		ax 	- MSG_VIS_VUP_UPDATE_WIN_GROUP
		dl	- VisualUpdateMode

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version

------------------------------------------------------------------------------@

VisVupUpdateWinGroup	method	static VisClass, MSG_VIS_VUP_UPDATE_WIN_GROUP
	tst	dl			; Just exit if VUM_MANUAL
	jz	done

EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

	push	di
	call	VisVupUpdateWinGroupLow
	pop	di
done:
	ret
VisVupUpdateWinGroup	endm


VisVupUpdateWinGroupLow	proc	near
	class	VisClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jnz	foundWinGroup

;keepLooking:
	push	bx, si
	call	VisSwapLockParent
	jnc	afterParentCalled		; if no parent, can't update.
	call	VisVupUpdateWinGroupLow		; continue up tree
	call	ObjSwapUnlock
afterParentCalled:
	pop	bx, si
	ret

foundWinGroup:
	call	VisCompVupUpdateWinGroup
	ret
VisVupUpdateWinGroupLow	endp

VisUpdate	ends
;
;-------------------
;
VisConstruct	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisDestroy

DESCRIPTION:	Destroy a visible branch, closing & unlinking as necessary.

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_VIS_DESTROY

	dl	- VisUpdateMode to use when updating parent

RETURN:
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

VisDestroy	method	dynamic VisClass, MSG_VIS_DESTROY

	; First, VISUALLY REMOVE this object
	call	VisRemove		; use static call

	; Then destroy children
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	AfterVisChildrenDone
	mov	ax, MSG_VIS_DESTROY
	call	VisSendToChildren
AfterVisChildrenDone:

if	ERROR_CHECK
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; Can not be realized
	test	ds:[di].VI_attrs, mask VA_REALIZED	
	ERROR_NZ	UI_REALIZED_VIS_OBJECT_CAN_NOT_BE_FREED

					; Can not be in visible tree
	cmp	ds:[di].VI_link.LP_next.handle, 0
	ERROR_NZ	UI_VIS_OBJECT_IN_TREE_CAN_NOT_BE_FREED

					; Can not have visible children
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	NotComposite
	cmp	ds:[di].VCI_comp.CP_firstChild.handle, 0
	ERROR_NZ	UI_VIS_OBJECT_WITH_CHILDREN_CAN_NOT_BE_FREED
NotComposite:
endif
					; Finally, destroy
	mov	ax, MSG_META_OBJ_FREE	; the visible object, after queue flush
	GOTO	ObjCallInstanceNoLock

VisDestroy	endm

VisConstruct	ends
;
;-------------------
;
VisUncommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisFindVisParent

DESCRIPTION:	Find the visible parent of this object.

PASS:	*ds:si	= instance data for object

RETURN:	^lcx:dx = parent
	ax, bp - destroyed

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		initial version

------------------------------------------------------------------------------@

VisFindVisParent	method	dynamic VisClass, MSG_VIS_FIND_PARENT
;	push	si
	call	VisFindParent		;returns ^lbx:si = parent
	mov	cx, bx
	mov	dx, si
;	pop	si
	Destroy	ax, bp
	ret

VisFindVisParent	endm

VisUncommon	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisCallRoutine
		MSG_VIS_CALL_ROUTINE for VisClass

DESCRIPTION:	Calls the specific fixed/locked subroutine

PASS:		*ds:si 	- instance data
		es     	- segment of VisClass
		ax 	- MSG_VIS_CALL_ROUTINE

		cx	- data to pass in ax
		dx	- # of bytes on stack
		bp	- pointer to stack frame

		Pushed on stack in following order:

		Word value to pass in cx
		Word value to pass in dx
		Word value to pass in bp

		Segment, then offset of routine to call (Must be in fixed
		memory, or in a locked block)
		(The callback routine is pointed by vfptr in XIP version.)
RETURN:		whatever

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

VisCallRoutine	method	dynamic VisClass, MSG_VIS_CALL_ROUTINE
if FULL_EXECUTE_IN_PLACE
		mov	ss:[TPD_dataAX], cx		; setup ax value
		mov	cx, ss:[bp+VCR_CX_param]	; Setup CX value
		mov	dx, ss:[bp+VCR_DX_param]	; Setup DX value
		mov	bx, ss:[bp+VCR_routine].segment
		mov	ax, ss:[bp+VCR_routine].offset
		mov	bp, ss:[bp+VCR_BP_param]	; Setup BP value
		call	ProcCallFixedOrMovable
	ret					; & "JUMP" to routine
else
	mov	ax, ss:[bp+VCR_routine].segment
	push	ax
	mov	ax, ss:[bp+VCR_routine].offset
	push	ax
	mov	ax, cx				; Setup AX value
	mov	cx, ss:[bp+VCR_CX_param]	; Setup CX value
	mov	dx, ss:[bp+VCR_DX_param]	; Setup DX value
	mov	bp, ss:[bp+VCR_BP_param]	; Setup BP value
	ret					; & "JUMP" to routine
endif
VisCallRoutine	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisGetBoundsMethod -- 
		MSG_VIS_GET_BOUNDS for VisClass

DESCRIPTION:	Returns the bounds of an object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_BOUNDS

RETURN:		ax -- left
		bp -- top (note this differs from library VisGetBounds)
		cx -- right
		dx -- bottom

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 1/89		Initial version

------------------------------------------------------------------------------@

VisGetBoundsMethod	method	dynamic VisClass, MSG_VIS_GET_BOUNDS
	call	VisGetBounds			;call library routine
	mov	bp, bx				;return top in bx
	ret
VisGetBoundsMethod	endm

VisCommon	ends
;
;-------------------
;
VisUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisVisGetPosition -- 
		MSG_VIS_GET_POSITION for VisClass

DESCRIPTION:	Returns an object's position.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_POSITION

RETURN:		cx, dx  - position of object
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/ 7/91		Initial Version

------------------------------------------------------------------------------@

VisVisGetPosition	method dynamic	VisClass, \
				MSG_VIS_GET_POSITION
	call	VisGetBounds			;get bounds
	mov	cx, ax
	mov	dx, bx				;return origin in cx, dx
	ret
VisVisGetPosition	endm

VisUncommon	ends

VisCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCountChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message handler counts the # of Vis children of the passed
		object.

CALLED BY:	GLOBAL
       
PASS:		*ds:si - vis object
		
RETURN:		dx <- # vis children
		ax, cx, bp - destroyed

DESTROYED:	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCountChildren	method	dynamic VisClass, MSG_VIS_COUNT_CHILDREN
	mov	di, OCCT_COUNT_CHILDREN
	clr	dx
	call	VisCallCommon
	Destroy	ax, cx, bp
	ret
VisCountChildren	endm

VisCommon	ends
;
;-------------------
;
VisConstruct	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC ONLY: 
		Intercept at final free of object to make sure it isn't
		referenced somewhere in the GenApplication object.

PASS:		nothing
RETURN:		nothing
ALLOWED TO DESTROY:	
		bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
VisFinalObjFree	method	VisClass, MSG_META_FINAL_OBJ_FREE
	push	ax, cx, dx, bp
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED
	call	GenCallApplication
	pop	ax, cx, dx, bp

	mov	di, offset VisClass
	GOTO	ObjCallSuperNoLock
VisFinalObjFree	endm
endif


if	ERROR_CHECK
					; If about to nuke a block, take the
					; opportunity to do a little EC'ing
					; around.

VisBlockFree	method	VisClass, MSG_META_BLOCK_FREE

	push	ax, cx, dx, bp
	clr	cx			; just check handles OK
	mov	ax, MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED
	call	ObjCallInstanceNoLock
	clr	cx			; just check handles OK
	mov	ax, MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED
	call	GenCallApplication
	pop	ax, cx, dx, bp

	mov	di, offset VisClass
	GOTO	ObjCallSuperNoLock
VisBlockFree	endm

endif


VisConstruct	ends
;
;-------------------
;
VisCommon	segment resource
				


COMMENT @----------------------------------------------------------------------

ROUTINE:	ShouldObjBeDrawn?

SYNOPSIS:	Sees is object could use some redrawing.

CALLED BY:	HandleEnabledStateChange, VCD_callBack

PASS:		*ds:si -- object
		cl -- DF_PRINT if we're printing
		      DF_DONT_DRAW_CHILDREN if we don't have to worry about
				drawing children who might be drawable.  

RETURN:		carry set if should be drawn, clear if not

DESTROYED:	di, ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 3/91		Initial version

------------------------------------------------------------------------------@

ShouldObjBeDrawn?	proc	near
	class	VisClass
	
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >

	mov	di, ds:[si]		; get ptr to child instance data
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
					; make sure object is drawable
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	noDraw			; if not, skip drawing it
					; make sure object is realized
	test	cl, mask DF_PRINT
	jnz	10$

	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	noDraw			; if not, skip drawing it

	;
	; If DF_DONT_DRAW_CHILDREN is clear, and we're a composite that has
	; VCGA_ONLY_DRAWS_IN_MARGINS set, then we may need to worry about
	; children who are not VOF_IMAGE_INVALID, so we'll skip this test.
	; -cbh 3/ 8/93
	;
	test	cl, mask DF_DONT_DRAW_CHILDREN
	jnz	5$			; not worry about kids, check invalid 
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	5$			; not a composite, check invalid
	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jnz	10$			; must skip invalid check in case one or
					;   more of our children are valid.

5$:
					; make sure that image is valid
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID
	jnz	noDraw			; if not, skip drawing it
10$:
					; make sure child isn't a window
					; (makes no sense. removed.cbh 12/13/91)
;	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
;	jnz	noDraw			; if it is, skip sending draw to it

	; IF bounds still in initial state, & haven't been set, don't draw

	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_right
	cmp	ax,bx
	jge	noDraw			; skip if width 0 or less
;draw:
	stc				; else draw it
	jmp	short exit
noDraw:
	clc				;don't draw
exit:
	ret
ShouldObjBeDrawn?	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisEnsureMouseNotActivelyTrespassing

DESCRIPTION:	The system is telling us that there is modal behavior going
		on somewhere, & so as a window, we should make sure that the
		mouse is not operating within us illegally.

		This handler covers the default behavior for non-WIN_GROUP
		windowed objects, by releasing the gadget exclusive for itself,
		should it have it.  This will result in a LOST_GADGET_EXCL,
		which should force the release of any mouse grab, & any
		visual interaction behavior that was in progress for this
		object or any visible child having the gadget exclusive from
		this object.  Any Window Grab should be terminated as well
		by that handler.

		NOTE that there is no standard way to terminate mouse
		interaction in a WIN_GROUP, so this message must be processed
		by such objects themselves.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

RETURN:
	ax - 0 (MouseFlags)
	cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version

------------------------------------------------------------------------------@

VisEnsureMouseNotActivelyTrespassing method	dynamic VisClass, \
				MSG_META_ENSURE_MOUSE_NOT_ACTIVELY_TRESPASSING

	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_PORTAL
	jz	done			; Non-windows should not need to 
					; respond to this.
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jnz	done			; Can't handle WIN_GROUP's

	; Call application object, see if this windowed object should be allowed
	; to have the mouse within it.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
        mov     ax, MSG_META_TEST_WIN_INTERACTIBILITY
        call    GenCallApplication
        jc     done                    ; if allowed to be here, done

	; OTHERWISE, force this gadget off the mouse -- it no longer has
	; any rights to it (Somwhere in the system is a modal window which
	; needs it to be free)
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParent
done:
	clr	ax		; return "MouseFlags" null
	Destroy	cx, dx, bp
	ret

VisEnsureMouseNotActivelyTrespassing endm


VisCommon	ends
;
;-------------------
;
VisUncommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	default handler for MSG_META_END_MOVE_COPY - clear
		current quick-transfer item

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		nothing

RETURN:		ax - MRF_PROCESSED
		cx, dx, bp -- destroyed

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisEndMoveCopy	method	dynamic VisClass, MSG_META_END_MOVE_COPY
	mov	bp, mask CQNF_NO_OPERATION
	call	ClipboardEndQuickTransfer
	mov	ax, mask MRF_PROCESSED
	Destroy	cx, dx, bp
	ret
VisEndMoveCopy	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisGetOptFlags -- 
		MSG_VIS_GET_OPT_FLAGS for VisClass

DESCRIPTION:	Returns non-composite geometry attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_OPT_FLAGS

RETURN:		cl	- VisOptFlags
		ax, ch, dx, bp - destroyed

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

VisGetOptFlags	method dynamic	VisClass, MSG_VIS_GET_OPT_FLAGS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].VI_optFlags
	ret
VisGetOptFlags	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisSetTypeFlags -- 
		MSG_VIS_SET_TYPE_FLAGS for VisClass

DESCRIPTION:	Sets type flags for an object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_SET_TYPE_FLAGS

		cl 	- VisTypeFlags to set
		ch	- VisTypeFlags to clear
		
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

VisSetTypeFlags	method dynamic	VisClass, MSG_VIS_SET_TYPE_FLAGS
		
if	0
	test	ds:[di].VI_attrs, mask VA_REALIZED
	ERROR_NZ	VIS_CANT_SET_TYPE_FLAGS_WHEN_REALIZED
endif
	
	or	ds:[di].VI_typeFlags, cl
	not	ch
	and	ds:[di].VI_typeFlags, ch
	Destroy	ax, cx, dx, bp
	ret
VisSetTypeFlags	endm

		

COMMENT @----------------------------------------------------------------------

METHOD:		VisGetTypeFlags -- 
		MSG_VIS_GET_TYPE_FLAGS for VisClass

DESCRIPTION:	Returns non-composite geometry attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_TYPE_FLAGS

RETURN:		cl	- VisTypeFlags
		ax, ch, dx, bp - destroyed

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

VisGetTypeFlags	method dynamic	VisClass, MSG_VIS_GET_TYPE_FLAGS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].VI_typeFlags
	ret
VisGetTypeFlags	endm

VisUncommon	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisMsgQueryGWin -- 
		MSG_VIS_VUP_QUERY_GWIN for VisClass

DESCRIPTION:	Returns parent window.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_VUP_QUERY_GWIN

RETURN:		^hcx	- window
		ax, dx, bp - destroyed

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

VisMsgQueryGWin	method dynamic	VisClass, MSG_VIS_QUERY_WINDOW
	call	VisQueryWindow
	mov	cx, di
	Destroy	ax, dx, bp
	ret
	
VisMsgQueryGWin	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		VisGetAttrs -- 
		MSG_VIS_GET_ATTRS for VisClass

DESCRIPTION:	Returns vis attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_ATTRS

RETURN:		cl	- VisAttrs
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

VisGetAttrs	method dynamic	VisClass, MSG_VIS_GET_ATTRS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].VI_attrs
	ret
VisGetAttrs	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisRedrawEntireObject -- 
		MSG_VIS_REDRAW_ENTIRE_OBJECT for VisClass

DESCRIPTION:	Creates a new gstate, sends a MSG_DRAW to an object, and 
		removes the gstate.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_REDRAW_ENTIRE_OBJECT

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
	Chris	8/ 2/91		Initial version

------------------------------------------------------------------------------@

VisRedrawEntireObject	method dynamic	VisClass, MSG_VIS_REDRAW_ENTIRE_OBJECT
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	exit
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	exit				;not drawable, exit

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
 	call	ObjCallInstanceNoLock		;get a gstate to work with
	tst	bp				;make sure gstate exists
	jz	done				;no, exit
	clr	cl				;not updating
	push	bp				;save gstate
	mov	ax, MSG_VIS_DRAW		;tell it to draw
	call	ObjCallInstanceNoLock
	pop	di				;restore gstate
	call	GrDestroyState 			;destroy the gstate
done:

	pop	di
	call	ThreadReturnStackSpace

exit:
	ret
VisRedrawEntireObject	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisSendClassedEvent

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax - MSG_META_SEND_CLASSED_EVENT

	^hcx	- ClassedEvent
	dx	- TravelOption

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/91		Initial version

------------------------------------------------------------------------------@

VisSendClassedEvent	method	VisClass, MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_VIS_PARENT
	je	sendToParent

	; Repeated here for non-generic objects  (This same redirection
	; code exists in the GenClass handler)
	;
	cmp	dx, TO_APP_FOCUS
	jb	send
	cmp	dx, TO_APP_MODEL
	jbe	sendToApp
	;
	cmp	dx, TO_SYS_FOCUS
	jb	send
	cmp	dx, TO_SYS_MODEL
	jbe	sendToSys
	;
send:
	mov	di, offset VisClass
	GOTO	ObjCallSuperNoLock

sendToParent:
	call	VisFindParent
	mov	ax, MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS
	clr	di
	GOTO	FlowMessageClassedEvent

sendToApp:
	sub	dx, TO_APP_FOCUS-TO_FOCUS
	GOTO	GenCallApplication

sendToSys:
	sub	dx, TO_SYS_FOCUS-TO_FOCUS
	call	UserCallSystem
	ret

VisSendClassedEvent	endm
			

COMMENT @----------------------------------------------------------------------

METHOD:		VisVupCallObjectOfClass

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax - MSG_VIS_VUP_CALL_OBJECT_OF_CLASS

	^hcx	- ClassedEvent

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

VisVupCallObjectOfClass	method	VisClass, \
				MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	VisVupObjectOfClassCommon

VisVupCallObjectOfClass	endm

;--

VisVupObjectOfClassCommon	proc	far
	push	di
	mov	bp, si
	call	VisFindParent
	xchg	si, bp
	pop	di
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

VisVupObjectOfClassCommon	endp

VisCommon	ends
;
;-------------------
;
VisUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisVupSendToObjectOfClass

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax - MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS

	^hcx	- ClassedEvent

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

VisVupSendToObjectOfClass	method	VisClass, \
				MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS
	mov	di, mask MF_FIXUP_DS
	call	VisVupObjectOfClassCommon
	ret

VisVupSendToObjectOfClass	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisVupTestForObjectOfClass

DESCRIPTION:	Searches up the viseric tree for an object of the class
		specified.  If found, the OD of the object is returned.

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax - MSG_VIS_VUP_TEST_FOR_OBJECT_OF_CLASS

	cx:dx	- class of object to look for

RETURN: carry	- set if object found
		- clear if no object found

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@

VisVupTestForObjectOfClass	method	VisClass,
					MSG_VIS_VUP_TEST_FOR_OBJECT_OF_CLASS
	mov	es, cx
	mov	di, dx
	call	ObjIsObjectInClass	; see if object is member of class
	jc	found			; branch if so
	GOTO	VisCallParent		; otherwise, pass on to parent -- turns
					; into stack-efficient version in
					; non-EC
found:
	stc
EC <	Destroy	ax, cx, dx, bp						>
	ret
VisVupTestForObjectOfClass	endm

			
VisUncommon	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisVupCallWinGroup

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax - MSG_VIS_VUP_CALL_OBJECT_OF_CLASS

	^hcx	- ClassedEvent

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

VisVupCallWinGroup	method	VisClass, \
				MSG_VIS_VUP_CALL_WIN_GROUP
				
	mov	bx, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	VisVupWinGroupCommon

VisVupCallWinGroup	endm

;--

VisVupWinGroupCommon	proc	far
	class	VisClass

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP

	mov	di, bx
	jnz	isWinGroup
	
; Use new routine to directly get next WinGroup up. -- Doug 2/93
;	call	VisFindParent
; {
	push	ax
	mov	al, mask VTF_IS_WIN_GROUP
	call	VisFindParentOfVisType
	pop	ax
; }

	GOTO	FlowMessageClassedEvent
	
isWinGroup:
	mov	bp, si
	call	VisFindParent
	xchg	si, bp
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

VisVupWinGroupCommon	endp


VisCommon	ends
;
;-------------------
;
VisUpdate	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisAddRectToUpdateRegion -- 
		MSG_VIS_ADD_RECT_TO_UPDATE_REGION for VisClass

DESCRIPTION:	Invalidates a rectangle in the object's area.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_ADD_RECT_TO_UPDATE_REGION
		
		ss:bp   - VisAddRectParams

RETURN:		nothing
		ax, cx, dx, bp - destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/31/91		Initial version

------------------------------------------------------------------------------@
			
VisAddRectToUpdateRegion	method static	VisClass, \
				MSG_VIS_ADD_RECT_TO_UPDATE_REGION

	uses	bx, es, di, si		;to conform to static requirements
	.enter

addRectAtThisObject:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	;
	; We won't invalidate a passed area if VARD_NOT_IF_ALREADY_INVALID
	; is set, we're at some other object other than the originator,
	; (VARF_ONLY_REDRAW_MARGINS is clear), and we're marked invalid, the
	; reason being our object will be invalidating itself shortly, anyway.
	; (This can only be done for non-ONLY_DRAWS_IN_MARGINS comps, since 
	; they're the only ones that completely invalidate, so I'll comment
	; the entire code out for now.)
	;
;	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
;	jz	5$		
;	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
;	jnz	10$
;5$:
;	test	ss:[bp].VARP_flags, mask VARF_ONLY_REDRAW_MARGINS
;	jnz	10$			; originating object, skip test
;	test	ss:[bp].VARP_flags, mask VARF_NOT_IF_ALREADY_INVALID
;	jz	10$
;	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID or \
;				     mask VOF_WINDOW_INVALID
;	jnz	exit		; already invalid here, skip inval
;10$:
	;
	; If a win group or a normal portal, we'll handle the message by
	; adding the rect to our local invalidation region.  
	;
;	Forget about portals.  The contents get invalidated with WIN_INVALID, 
;	the stuff around the portal needs to happen at the win group.
;	-cbh 3/ 3/93
;
;	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP or \
;				      mask VTF_IS_PORTAL
;	jz	tryParent
;	test	ds:[di].VI_typeFlags, mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN
;	jz	doInval			; children in portal window, add to
;					;   update region here

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP 
	jnz	doInval
	
;tryParent:
	;
	; We're not a win group.  We'll optimally move up to our visual parent
	; and try to do this there.
	;
	mov	cx, si			; keep old chunk in bx
	call	VisFindParent		; found a parent?
	tst	si			; no, handle it at this point -- it
	jz	doInvalOnRemovedObject	;   may be an object being removed.

	and	ss:[bp].VARP_flags, not mask VARF_ONLY_REDRAW_MARGINS

	cmp	bx, ds:[LMBH_handle]	; in same block?
	je	addRectAtThisObject	; yes, loop to handle this object.

	call	ObjSwapLock		 ; set *ds:si to be parent
	call	VisAddRectToUpdateRegion ; travel recursively up tree
	call	ObjSwapUnlock		 ; unlock the block
	jmp	short exit		 ; and we're done
	
doInvalOnRemovedObject:
	mov	si, cx			; *ds:si <- object
	and	ss:[bp].VARP_flags, not mask VARF_UPDATE_WILL_HAPPEN
					; forget about adding to update region

doInval:		
	mov	ax, ss:[bp].VARP_bounds.R_left
	mov	bx, ss:[bp].VARP_bounds.R_top
	mov	cx, ss:[bp].VARP_bounds.R_right
	mov	dx, ss:[bp].VARP_bounds.R_bottom
	
	cmp	ax, cx			; nothing to do, exit
	je	exit
	cmp	bx, dx
	je	exit
	;
	; If we're in the middle of an update, we'll add this rectangle
	; to a region we're keeping to invalidate later.  
	;
	test	ss:[bp].VARP_flags, mask VARF_UPDATE_WILL_HAPPEN
	jnz	addToRegion		; caller reassures us things will get
					;   updated, so add to update region

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_optFlags, mask VOF_UPDATING	
	jz	inval			; not updating, invalidate as usual

addToRegion:
	call	AddToInvalRegion	; else add to invalidation region
	jc	exit			; no problems adding it, exit
inval:
	call	InvalidateArea		; do the invalidation
exit:
	.leave
	Destroy	ax, cx, dx, bp
	ret
VisAddRectToUpdateRegion	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	InvalidateArea

SYNOPSIS:	Creates a gstate and invalidates an area.

CALLED BY:	VisAddRectToUpdateRegion

PASS:		*ds:si -- visual object
		ax, bx, cx, dx -- rectangle bounds to invalidate

RETURN:		nothing

DESTROYED:	di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/30/91		Initial version

------------------------------------------------------------------------------@

InvalidateArea	proc	near
	push	ax, cx, dx
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE	
	call	ObjCallInstanceNoLock	; get a gstate
	pop	ax, cx, dx
	mov	di, bp
	tst	di
	jz	exit			; if not realized, don't bother

	cmp	ax, cx
	je	10$
	dec	cx			; I guess we have to pass screen coords
10$:
	cmp	bx, dx
	je	20$
	dec	dx			;  -cbh 5/11/93
20$:
	call  	GrInvalRect		; invalidate the rectangle
	call	GrDestroyState
exit:
	ret
InvalidateArea	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	AddToInvalRegion

SYNOPSIS:	Adds an update rectangle to the invalid region of the object.

CALLED BY:	VisAddRectToUpdateRegion

PASS:		*ds:si -- object
		ax, bx, cx, dx -- rectangle to add, in doc coords

RETURN:		carry clear add failed

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/30/91	Initial version
	Chris	3/ 6/93		Changed to convert params to match content
				scrolling directly, rather than using PARAMS
				which are evaluated at WinInvalReg time.

------------------------------------------------------------------------------@

AddToInvalRegion	proc	near		uses	ax, bx, cx, dx
	.enter
	;
	; Create a rectangular region to use.
	;
	push	ax, cx
	mov	al, mask OCF_IGNORE_DIRTY
	mov	cx, 22				;need size of 22, it seems...
	call	LMemAlloc			;create a chunk for our rect
	mov	di, ax				;in *ds:di
	pop	ax, cx
	
	push	si				;object handle 
	push	di				;region handle 
	segmov	es, ds				;rect region in *es:di
	mov	di, ds:[di]
	
	dec	cx				;make into screen coords
	dec	dx

;	call	AdjustParamsIfContent		;special case for VisContents.
						;(adjustment delayed until
						; VisUpdate time. -ct 2/12/96)

	xchg	ax, bx				;top in ax, left in bx
	
	dec	ax
	stosw
	mov	ax, EOREGREC
	stosw
	mov	ax, dx				;bottom:
	stosw
	mov	ax, bx				;from left to right	
	stosw
	mov	ax, cx
	stosw
	mov	ax, EOREGREC
	stosw
	stosw					;done
	pop	di				;restore region in *es:di
	pop	si
	
	mov	ax, TEMP_VIS_INVAL_REGION	;get chunk with inval region
	call	ObjVarFindData
	jc	5$				;found chunk, branch
	mov	ax, di				;else we'll just use rect region
	jmp	short storeAsInvalRegion
5$:
	push	si				;save object handle
	mov	si, {hptr} ds:[bx]		;in *ds:dx
	
	mov	bx, di				;rect region in *es:bx
	;
	; If original region is null, then replace it with the rect region.
	;
	ChunkSizeHandle	ds, si, di		;see how big the source is
	tst	di
	jnz	10$				;there is something, branch
	mov	di, bx				;use rect as new destination
	jmp	short replaceOldRegionWithNew
10$:
	clr	cx				;place for dest region
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc			;destination goes here
	mov	di, ax				;dest region in *es:di
	
	mov	ax, 2				;or the region
	push	si, bx, di			;save region chunks
	call	GrChunkRegOp
	pop	si, bx, di
	mov	ax, bx
	call	LMemFree			;remove the rect region
	
replaceOldRegionWithNew:
	;
	; Old region in *ds:si, new region in *ds:di.
	;
	mov	ax, si	
	call	LMemFree			;remove the original region
	mov	ax, di				;new region in *ds:ax
	pop	si				;restore object handle
	
storeAsInvalRegion:
	;
	; New region in *ds:ax.
	;
	call	SaveAsInvalChunk
	stc					;say done
	.leave
	ret
AddToInvalRegion	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	AdjustParamsIfContent

SYNOPSIS:	Adjusts parameters if content is scrolled, to be relative
		to the top of the window

CALLED BY:	AddToInvalRegion

PASS:		*ds:si -- win group object
		ax, bx, cx, dx -- params, in "document" coords

RETURN:		ax, bx, cx, dx -- possibly updated, to be relative to the top
				  of the window

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 6/93       	Initial version

------------------------------------------------------------------------------@
if 0

AdjustParamsIfContent	proc	near			uses	di
	class	VisContentClass
	.enter
	;
	; If this is a content object, we'll grab the current scroll value, in
	; order to use that as an offset for the region, so that scrolled
	; contents will work.  Will only work for unscaled views, but most of
	; this stuff will only work for unscaled views.  Also if the view 
	; doesn't really scroll, we won't want this offset. 
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jz	exit
	test	ds:[di].VCNI_attrs, mask VCNA_VIEW_DOES_NOT_WIN_SCROLL
	jnz	exit
	push	bp
	mov	bp, ds:[di].VCNI_docOrigin.PD_x.low
	mov	di, ds:[di].VCNI_docOrigin.PD_y.low
	sub	ax, bp
	sub	cx, bp
	sub	bx, di
	sub	dx, di
	pop	bp
exit:
	.leave
	ret
AdjustParamsIfContent	endp
endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	SaveAsInvalChunk

SYNOPSIS:	Saves the inval chunk handle in variable data.

CALLED BY:	VisInitialize, AddToInvalRegion

PASS:		*ds:si -- object
		ax -- chunk handle

RETURN:		nothing
		note: ds may change as a result, also es, if pointing to the
		same block.

DESTROYED:	ax, bx, cx, dx 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/30/91	Initial version

------------------------------------------------------------------------------@

SaveAsInvalChunk	proc	far
	mov	dx, ax				;chunk handle in dx
	mov	cx, size word			;cx = size extra data
	mov	ax, TEMP_VIS_INVAL_REGION
	call	ObjVarAddData
	mov	{lptr} ds:[bx], dx		;save chunk handle
	ret
SaveAsInvalChunk	endp

VisUpdate	ends
;
;-------------------
;
VisUncommon	segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisVupSendToWinGroup

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of VisClass

	ax - MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS

	^hcx	- ClassedEvent

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

VisVupSendToWinGroup	method	VisClass, \
				MSG_VIS_VUP_SEND_TO_WIN_GROUP

	mov	bx, mask MF_FIXUP_DS
	call	VisVupWinGroupCommon
	ret

VisVupSendToWinGroup	endm

VisUncommon	ends
;
;-------------------
;
VisCommon	segment resource
			

COMMENT @----------------------------------------------------------------------

METHOD:		VisVisCallParent

DESCRIPTION:	Call parent of a vis object

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_VIS_CALL_PARENT

	^hcx - ClassedEvent to call on parent

RETURN: carry clear if no vis parent
	else carry returned from parent's method handler
	ax, cx, dx, bp - returned from parent's method handler

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

VisVisCallParent	method	VisClass, MSG_VIS_CALL_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU	VisParentCommon

VisVisCallParent	endm

;-

VisParentCommon	proc	far
	push	di
	call	VisFindParent		; ^lbx:si = parent
	mov	dx, TO_SELF		; no special UI handling
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	pop	di
	GOTO	FlowMessageClassedEvent

VisParentCommon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisVisSendToParent

DESCRIPTION:	Send message to parent of a viseric object

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_VIS_SEND_TO_PARENT

	^hcx - ClassedEvent to send to parent

RETURN: nothing

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

VisVisSendToParent	method	VisClass, MSG_VIS_SEND_TO_PARENT
	mov	di, mask MF_FIXUP_DS
	GOTO	VisParentCommon

VisVisSendToParent	endm

VisCommon	ends
;
;-------------------
;
VisUncommon	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		VisVisDrawMoniker -- 
		MSG_VIS_DRAW_MONIKER for VisClass

DESCRIPTION:	Draws a moniker.  Assembly language types should use the
		library routine VisDrawMoniker for speed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW_MONIKER
		ss:bp   - MonikerMessageParams
		dx	- size MonikerMessageParams

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
	Chris	8/21/91		Initial version

------------------------------------------------------------------------------@

VisVisDrawMoniker	method dynamic	VisClass, \
				MSG_VIS_DRAW_MONIKER
	CheckHack <MMP_yInset eq DMA_yInset>
	CheckHack <MMP_xInset eq DMA_xInset>
	CheckHack <MMP_xMaximum eq DMA_xMaximum>
	CheckHack <MMP_yMaximum eq DMA_yMaximum>
	CheckHack <MMP_gState eq DMA_gState>
	CheckHack <MMP_textHeight eq DMA_textHeight>
	
	segmov	es, ds
	mov	bx, ss:[bp].MMP_visMoniker	;vis moniker in *es:bx
	mov	cl, ss:[bp].MMP_monikerFlags	;moniker flags in cx
	call	VisDrawMoniker
	Destroy	ax, cx, dx, bp
	ret
VisVisDrawMoniker	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		VisVisGetMonikerPos -- 
		MSG_VIS_GET_MONIKER_POS for VisClass

DESCRIPTION:	Gets the position where the moniker would be drawn.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_MONIKER_POS
		ss:bp   - MonikerMessageParams
		dx	- size MonikerMessageParams

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
	Chris	8/21/91		Initial version

------------------------------------------------------------------------------@

VisVisGetMonikerPos	method dynamic	VisClass, MSG_VIS_GET_MONIKER_POS
	segmov	es, ds
	mov	bx, ss:[bp].MMP_visMoniker	;vis moniker in *es:bx
	mov	cl, ss:[bp].MMP_monikerFlags	;moniker flags in cx
	call	VisGetMonikerPos
	Destroy	ax, cx, dx, bp
	ret
VisVisGetMonikerPos	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		VisVisGetMonikerSize -- 
		MSG_VIS_GET_MONIKER_SIZE for VisClass

DESCRIPTION:	Gets the size of the moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_GET_MONIKER_SIZE
		
		ss:bp   - MonikerMessageParams
		dx	- size MonikerMessageParams

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
	Chris	8/21/91		Initial version

------------------------------------------------------------------------------@

VisVisGetMonikerSize	method dynamic	VisClass, MSG_VIS_GET_MONIKER_SIZE
	segmov	es, ds
	mov	di, ss:[bp].MMP_visMoniker	;vis moniker in *es:di
	mov	ax, ss:[bp].MMP_textHeight	;height of system text
	mov	bp, ss:[bp].MMP_gState		;gstate
	call	VisGetMonikerSize
	Destroy	ax, bp
	ret
VisVisGetMonikerSize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisCreateVisMoniker -- 
		MSG_VIS_CREATE_VIS_MONIKER for VisClass

DESCRIPTION:	Creates a vis moniker chunk in the object's resource block
		from various sources.

PASS:		*ds:si 	- instance data
		es     	- segment of VisClass
		ax 	- MSG_VIS_CREATE_VIS_MONIKER
		
		ss:bp	- CreateVisMonikerFrame
				CreateVisMonikerFrame	struct
					CVMF_source	dword
					CVMF_sourceType	VisMonikerSourceType
					CVMF_dataType	VisMonikerDataType
					CVMF_length	word
					CVMF_width	word
					CVMF_height	word
					CVMF_flags	CreateVisMonikerFlags
				CreateVisMonikerFrame	ends
		dx	- size CreateVisMonikerFrame

RETURN:		ax - chunk handle of new vis moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
VisCreateVisMoniker	method	dynamic	VisClass, MSG_VIS_CREATE_VIS_MONIKER
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		cmp	ss:[bp].CVMF_sourceType, VMST_FPTR		>
EC <		jne	xipSafe						>
EC <		cmp	ss:[bp].CVMF_dataType, VMDT_NULL		>
EC <		je	xipSafe						>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].CVMF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
EC < xipSafe:								>
endif
EC <	cmp	ss:[bp].CVMF_dataType, VMDT_TOKEN			>
EC <	ERROR_E	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_TOKEN	>
	clr	ax			; create new chunk
	call	VisCreateMonikerChunk	; no error possible b/c no VMDT_TOKEN
EC <	ERROR_C	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_TOKEN	>
	ret
VisCreateVisMoniker	endm


VisUncommon	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisCreateMonikerChunk

SYNOPSIS:	Create/overwrite moniker chunk in the object's resource
		block from various sources.

CALLED BY:	EXTERNAL
			VisCreateVisMoniker
			GenCreateVisMoniker
			GenReplaceVisMoniker
			GenPrimaryReplaceLongTermMoniker

PASS:		*ds:si 	- instance data
		
		ss:bp	- CreateVisMonikerFrame
				CreateVisMonikerFrame	struct
					CVMF_source	dword
					CVMF_sourceType	VisMonikerSourceType
					CVMF_dataType	VisMonikerDataType
					CVMF_length	word
					CVMF_width	word
					CVMF_height	word
					CVMF_flags	CreateVisMonikerFlags
				CreateVisMonikerFrame	ends
		ax - moniker chunk to replace, 0 to create new moniker chunk

RETURN:		carry clear if successful
			ax - chunk handle of vis moniker
				(updated to be VisMoniker, may be moniker list)
		carry set if VMDT_TOKEN and token not found
			source chunk is BOGUS (it contains GeodeToken),
			or remains null if null

DESTROYED:	bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
VisCreateMonikerChunk	proc	far
	push	ax				; save chunk to overwrite
EC <	cmp	ss:[bp].CVMF_dataType, VMDT_NULL			>
EC <	ERROR_E	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_NULL	>
	mov	al, ss:[bp].CVMF_sourceType	; al = source type
EC <	cmp	al, VisMonikerSourceType				>
EC <	ERROR_AE	UI_ERROR_CREATE_VIS_MONIKER_BAD_SOURCE_TYPE	>
	mov	di, CCM_FPTR shl offset CCF_MODE	; assume FPTR
	cmp	al, VMST_FPTR
	je	haveSourceType
	mov	di, CCM_OPTR shl offset CCF_MODE	; assume OPTR
	cmp	al, VMST_OPTR
	je	haveSourceType
	mov	di, CCM_HPTR shl offset CCF_MODE	; else, must be HPTR
EC <	cmp	al, VMST_HPTR						>
EC <	ERROR_NE	UI_ERROR_CREATE_VIS_MONIKER_BAD_SOURCE_TYPE	>
haveSourceType:
	test	ss:[bp].CVMF_flags, mask CVMF_DIRTY
	jz	notDirty
	ornf	di, mask CCF_DIRTY
notDirty:
	call	GetLengthForDataType		; cx = modified length
EC <	test	cx, not mask CCF_SIZE					>
EC <	ERROR_NZ	UI_ERROR_CREATE_VIS_MONIKER_SOURCE_TOO_LARGE	>
	ornf	cx, di				; cx = CopyChunkFlags
	mov	bx, bp				; ss:bx = CreateVisMonikerFrame
	pop	ax				; ax = chunk to overwrite
	push	bp				; save param frame
	mov	dx, size CopyChunkOVerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].CCOVF_dest.low, ax	; save chunk to overwrite
	mov	ax, ds:[LMBH_handle]		; dest block
	mov	ss:[bp].CCOVF_dest.high, ax
	mov	ax, ss:[bx].CVMF_source.high	; <cx><dx> = source
	mov	ss:[bp].CCOVF_source.high, ax
	mov	ax, ss:[bx].CVMF_source.low
	mov	ss:[bp].CCOVF_source.low, ax
	mov	ss:[bp].CCOVF_copyFlags, cx
	call	UserHaveProcessCopyChunkOver	; ax = new chunk
	add	sp, size CopyChunkOVerFrame
	pop	bp				; retrieve param frame
	call	ModifyChunkForDataType		; update chunk with
						;	VisMoniker struct
						; carry clear if successful
	ret
VisCreateMonikerChunk	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetLengthForDataType

SYNOPSIS:	Get size of source to copy.

CALLED BY:	INTERNAL
			VisCreateVisMoniker

PASS:		*ds:si	- object
		ss:bp	- CreateVisMonikerFrame

RETURN:		cx	- computed size of source

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GetLengthForDataType	proc	near
	mov	cx, ss:[bp].CVMF_length		; get passed length
	cmp	ss:[bp].CVMF_sourceType, VMST_OPTR
	jne	notOptr
	clr	cx				; always use full optr
notOptr:
	mov	al, ss:[bp].CVMF_dataType	; al = VisMonikerDataType
EC <	cmp	al, VMDT_NULL			; should be handled before >
EC <	ERROR_E	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_NULL	>
	cmp	al, VMDT_VIS_MONIKER		; full VisMoniker passed,
	je	done				;	use size passed
	cmp	al, VMDT_TEXT
	jne	notText
	tst	cx				; cx = 0 if null-terminated
	jnz	done				; not!, use passed length
	push	es, di
	call	LockSource			; es:di = source
if DBCS_PCGEOS
	LocalStrSize	INCLUDE_NULL		; cx = size (with null)
else
	clr	al				; find null-terminator
	mov	cx, -1
	repne scasb
	not	cx				; cx = length (with null)
endif
	call	UnlockSource
	pop	es, di
	jmp	short done

notText:
	cmp	al, VMDT_GSTRING
	jne	notGString
;unlikely - brianc 5/20/92
;PrintMessage <get length for gstring, if needed>
EC <	cmp	ss:[bp].CVMF_sourceType, VMST_OPTR			>
EC <	je	done							>
EC <	tst	cx							>
EC <	ERROR_Z	UI_ERROR_CREATE_VIS_MONIKER_GSTRING_SIZE_0_NOT_ALLOWED	>
	jmp	short done			; use passed length for now

notGString:
	mov	cx, size GeodeToken		; GeodeToken passed
EC <	cmp	al, VMDT_TOKEN						>
EC <	ERROR_NE	UI_ERROR_CREATE_VIS_MONIKER_BAD_DATA_TYPE	>

done:
EC <	test	cx, not mask CCF_SIZE					>
EC <	ERROR_NZ	UI_ERROR_CREATE_VIS_MONIKER_SOURCE_TOO_LARGE	>
	ret
GetLengthForDataType	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	LockSource, UnlockSource

SYNOPSIS:	Lock and unlock source.

CALLED BY:	INTERNAL
			VisCreateVisMoniker

PASS:		ss:bp	- CreateVisMonikerFrame

RETURN:		LockSource
			es:di	- ptr to source
		UnlockSource
			nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
LockSource	proc	near
	uses	ax, bx
	.enter
	cmp	ss:[bp].CVMF_sourceType, VMST_FPTR
	jne	notFptr
	les	di, ss:[bp].CVMF_source		; es:di = source
	jmp	short done

notFptr:
	mov	bx, ss:[bp].CVMF_source.handle
	mov	di, ss:[bp].CVMF_source.chunk
	cmp	ss:[bp].CVMF_sourceType, VMST_OPTR
	jne	notOptr
	call	ObjLockObjBlock				; ax = segment
	mov	es, ax
	mov	di, es:[di]				; es:di = source
	jmp	short done

notOptr:
EC <	cmp	ss:[bp].CVMF_sourceType, VMST_HPTR			>
EC <	ERROR_NE	UI_ERROR_CREATE_VIS_MONIKER_BAD_SOURCE_TYPE	>
	call	MemLock
	mov	es, ax					; es:di = source
done:
EC <	push	ds, si							>
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
	.leave
	ret
LockSource	endp

UnlockSource	proc	near
	uses	bx
	.enter
	cmp	ss:[bp].CVMF_sourceType, VMST_FPTR
	je	done
EC <	cmp	ss:[bp].CVMF_sourceType, VMST_OPTR			>
EC <	je	10$							>
EC <	cmp	ss:[bp].CVMF_sourceType, VMST_HPTR			>
EC <	ERROR_NE	UI_ERROR_CREATE_VIS_MONIKER_BAD_SOURCE_TYPE	>
EC <10$:								>
	mov	bx, ss:[bp].CVMF_source.handle
	call	MemUnlock
done:
	.leave
	ret
UnlockSource	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	ModifyChunkForDataType

SYNOPSIS:	Add VisMoniker header to new chunk.

CALLED BY:	INTERNAL
			VisCreateVisMoniker

PASS:		*ds:si	- object
		*ds:ax	- new chunk
		ss:bp	- CreateVisMonikerFrame

RETURN:		carry clear if successful
			source chunk update to be VisMoniker
		carry set if VMDT_TOKEN and token not found
			source chunk unchanged (i.e. it is bogus moniker chunk!)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
ModifyChunkForDataType	proc	near
	uses	ax, bx, cx, dx, di
	.enter
	mov	dl, ss:[bp].CVMF_dataType	; dl = VisMonikerDataType
EC <	cmp	dl, VMDT_NULL			; should be handled before >
EC <	ERROR_E	UI_ERROR_CREATE_VIS_MONIKER_CANNOT_USE_VMDT_NULL	>
	cmp	dl, VMDT_VIS_MONIKER		; full VisMoniker passed, done
	LONG je	done				; (carry clear -> success)
	cmp	dl, VMDT_TEXT
	jne	notText
	clr	bx
	mov	cx, size VisMoniker + size VisMonikerText
	call	LMemInsertAt
	mov	di, ax
	mov	di, ds:[di]
	mov	ds:[di].VM_type, 0
	mov	ds:[di].VM_width, 0
	mov	ds:[di].VM_data.VMT_mnemonicOffset, VMO_NO_MNEMONIC
	;
	; ensure null-terminated
	;
	ChunkSizePtr	ds, di, bx
SBCS <	cmp	{char} ds:[di][bx][-1], 0				>
DBCS <	cmp	{wchar} ds:[di][bx][-2], 0				>
	LONG jz	done				; have null already
						; (carry clear -> success)
SBCS <	mov	cx, 1							>
DBCS <	mov	cx, 2							>
	call	LMemInsertAt
SBCS <	mov	di, ax							>
SBCS <	mov	di, ds:[di]						>
SBCS <	mov	{char} ds:[di][bx], 0		; else, put one there	>
DBCS <		; LMemInsertAt() initializes new area to zero...	>
	clc					; indicate success
	jmp	short done

notText:
	cmp	dl, VMDT_GSTRING
	jne	notGString
	clr	bx
	mov	cx, size VisMoniker + size VisMonikerGString
	call	LMemInsertAt
	mov	cx, ax				; *ds:cx = moniker chunk
	mov	di, ax				; *ds:di = moniker chunk
	mov	di, ds:[di]
	mov	ds:[di].VM_type, mask VMT_GSTRING
	;XXX: set up VMT_GS_ASPECT_RATIO and VMT_GS_COLOR
;
; we no longer compute the gstring bounds here as VisGetMonikerSize will do
; it - brianc 12/1/92.  Has added benefit of being able to use a valid gstate
; to compute the thing, hence using the correct font info for text.
;
; NOTE: we still copy over the passed width and height as they are
; uninitialized by LMemInsertAt
;
if 0
	mov	ax, ss:[bp].CVMF_width		; must always store (for error?)
	mov	ds:[di].VM_width, ax
	tst	ax				; check width
	mov	ax, ss:[bp].CVMF_height
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, ax
	jz	compute				; width is 0, compute
	tst	ax
	jnz	afterCompute			; width/height is not 0, done
compute:
	push	si, cx				; save object, moniker chunks
	mov	cl, GST_PTR
	mov	bx, ds				; bx:si = gstring fptr
	lea	si, ds:[di].VM_data + size VisMonikerGString
	call	GrLoadGString			; si = gstring handle
	clr	di				; no gstate
	clr	dx				; no control flags
	call	GrGetGStringBounds		; ax, bx, cx, dx = bounds
						; XXX: handle overflow error?
	sub	cx, ax				; cx = width
	sub	dx, bx				; dx = height
	push	dx
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	dx
	pop	si, di				; restore object, moniker
	mov	di, ds:[di]
	mov	ds:[di].VM_width, cx
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, dx
afterCompute:
else
	mov	ax, ss:[bp].CVMF_width		; must always store (for error?)
	mov	ds:[di].VM_width, ax
	mov	ax, ss:[bp].CVMF_height
	mov	({VisMonikerGString} ds:[di].VM_data).VMGS_height, ax
endif
	clc					; indicate success
	jmp	short done

notGString:
	;
	; source is a token, let specific UI choose the right moniker from
	; the Token Database's moniker list for the source token
	;	*ds:si - object
	;	*ds:ax - the chunk for the resolved moniker, initially contains
	;			the GeodeToken
	;
EC <	cmp	dl, VMDT_TOKEN						>
EC <	ERROR_NE	UI_ERROR_CREATE_VIS_MONIKER_BAD_DATA_TYPE	>
	;
	; the object must usable, since the specific UI resolves the moniker,
	; if not usable, return error (causing moniker to be cleared)
	;
	call	GenCheckIfFullyUsable		; carry set if fully usable
	cmc					; carry set if NOT fully usable
	jc	done				; not fully usable, return error
	;
	; else, let Specific UI resolve moniker list
	;
	mov	cx, ax				; cx = moniker chunk
	mov	ax, MSG_SPEC_RESOLVE_TOKEN_MONIKER
	push	bp				; save stack frame
	call	ObjCallInstanceNoLock		; carry clear if successful
	pop	bp

done:
	.leave
	ret
ModifyChunkForDataType	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisVisVupQuery

DESCRIPTION:	Relays MSG_VIS_VUP_QUERY up tree

PASS:		*ds:si 	- instance data
		ax 	- MSG_VIS_VUP_QUERY

RETURN:		If message handled, carry, ax, cx, dx, bp returned per handler.
		If not handled, carry is returned clear, ax, cx, dx, bp = 0

ALLOWED TO DESTROY:	
		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/ 2/91		Initial Version

------------------------------------------------------------------------------@

VisVisVupQuery	method dynamic VisClass, MSG_VIS_VUP_QUERY


	call	VisCallParentEnsureStack
	jc	exit
	clr	ax		;clear all return regs if nothing returned
	mov	cx, ax
	mov	dx, ax
	mov	bp, ax
EC <	ERROR_C	-1							>
exit:
	ret
VisVisVupQuery	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisVupAlterFTVMCExcl

DESCRIPTION:	Default handler for non-node objects, just sends this
		message on up towards the node.

PASS:		*ds:si 	- instance data
		es     	- segment of class
		ax 	- MSG_META_MUP_ALTER_FTVMC_EXCL
		^lcx:dx	- object making request
		bp	- MetaAlterFTVMCExclFlags

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
	doug	10/91		Initial Version

------------------------------------------------------------------------------@

VisVupAlterFTVMCExcl	method dynamic	VisClass, MSG_META_MUP_ALTER_FTVMC_EXCL

	; clear "not here" flag, since we're safely past the first object

	and	bp, not mask MAEF_NOT_HERE

	; Special case MODEL exclusive, which really has nothing to do with
	; the Visible class hiearchy, but is handled here nonetheless since
	; we're handling this message anyway, & can avoid having to have a
	; handler also at GenClass by dealing with it here.
	;
	test	bp, mask MAEF_MODEL
	jnz	handleModelExcl

sendToVisParent:
	mov	al, mask VTF_IS_INPUT_NODE or mask VTF_IS_WIN_GROUP
	call	VisFindParentOfVisType

	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	GOTO	ObjMessageCallFromHandler

handleModelExcl:

	; Default handling sends MODEL alternation requests up generic
	; tree only
	;
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	afterModel
	push	cx, dx, bp
	and	bp, mask MAEF_GRAB or mask MAEF_MODEL
	call	GenCallParentEnsureStack
	pop	cx, dx, bp
afterModel:

	; If any more exclusives to do, send to Vis parent
	;
	and	bp, not (mask MAEF_MODEL)
	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jnz	sendToVisParent

	ret

VisVupAlterFTVMCExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisFupQueryFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	<description here>

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_VIS_FUP_QUERY_FOCUS_EXCL
			  MSG_VIS_VUP_QUERY_FOCUS_EXCL

RETURN:		^lcx:dx	- object having focus within level
		bp	- hierarchical grab flags

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/5//93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisFupQueryFocusExcl	method dynamic	VisClass, MSG_VIS_FUP_QUERY_FOCUS_EXCL,
					MSG_VIS_VUP_QUERY_FOCUS_EXCL
	push	ax
	mov	al, mask VTF_IS_INPUT_NODE or mask VTF_IS_WIN_GROUP
	call	VisFindParentOfVisType
	pop	ax
	;
	; Clear the return optr, in case the parent is NULL
	;
	clrdw	cxdx
	GOTO	ObjMessageCallFromHandler

VisFupQueryFocusExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisVupAlterInputFlow

DESCRIPTION:	Default handler for non-node objects, just sends this
		message on up towards the node.

PASS:		*ds:si 	- instance data
		es     	- segment of class
		ax 	- MSG_VIS_VUP_ALTER_INPUT_FLOW
		dx	- size VupAlterInputFlowData
		ss:bp	- ptr to VupAlterInputFlowData

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
	doug	10/91		Initial Version

------------------------------------------------------------------------------@

VisVupAlterInputFlow	method VisClass, MSG_VIS_VUP_ALTER_INPUT_FLOW

						; clear "NOT_HERE" flag, since
						; we'll be calling on parent
	and	ss:[bp].VAIFD_flags, not mask VIFGF_NOT_HERE

	push	ax
	mov	al, mask VTF_IS_INPUT_NODE
	call	VisFindParentOfVisType
	pop	ax

	GOTO	ObjMessageCallFromHandler

VisVupAlterInputFlow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Default handler for keyboard input event arriving at a 
		visible object -- as nothing has "used" this event, "FUP"
		it on up for kbd navigation purposes.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_KBD_CHAR

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisKbdChar	method dynamic	VisClass, MSG_META_KBD_CHAR
	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	ObjCallInstanceNoLock

VisKbdChar	endm


VisCommon	ends
;
;-------------------
;
Ink	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the default method handler for the
		QUERY_IF_PRESS_IS_INK message. For nearly all vis objects, 
		presses within the object bounds should *not* cause ink to
		flow.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisQueryIfPressIsInk	method	VisClass, MSG_META_QUERY_IF_PRESS_IS_INK

;	By default, vis objects do *not* want ink.

	mov	ax, IRV_NO_INK
	ret
VisQueryIfPressIsInk	endm

SetGeosConvention

VISOBJECTHANDLESINKREPLY proc far pself:optr, oself:fptr, msg:word,
				frame:fptr.VisCallChildrenInBoundsFrame
	uses	si, di, ds
	.enter
	mov	si, ss:[oself].chunk
	lds	di, ss:[pself]
	mov	ax, ss:[msg]
	mov	bp, ss:[frame].offset
	call	VisObjectHandlesInkReply
	.leave
	ret
VISOBJECTHANDLESINKREPLY endp

SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisObjectHandlesInkReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default method for MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK

CALLED BY:	GLOBAL
PASS:		*ds:si	= VisClass object
		ss:bp	= VisCallChildrenInBoundsFrame
RETURN:		ss:bp	= VisCallChildrenInBoundsFrame filled in:
				VCCIBF_data1 = object block handle
				VCCIBF_data2 = object chunk handle
				VCCIBF_data3 = top bounds of object
DESTROYED:	ax, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisObjectHandlesInkReply	proc	far
	class	VisClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VI_bounds.R_top
	cmp	ax, ss:[bp].VCCIBF_data3
	jae	exit

	mov	cx, ds:[LMBH_handle]
	mov	ss:[bp].VCCIBF_data1, cx
	mov	ss:[bp].VCCIBF_data2, si
	mov	ss:[bp].VCCIBF_data3, ax
exit:
	.leave
	ret
VisObjectHandlesInkReply	endp


Ink ends

;------------

VisUncommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisInvalTree -- MSG_VIS_INVAL_TREE for VisClass

DESCRIPTION:	Invalidates everything within the visible bounds of this object,
		inluding child windows.

PASS:
	*ds:si	- pointer to instance
	es - segment of visClass
	ax - MSG_VIS_INVAL_TREE

RETURN:		
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es
	
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions
	Doug	8/91		Moved to VisClass, gave function its own message

------------------------------------------------------------------------------@

VisInvalTree	method	dynamic VisClass, MSG_VIS_INVAL_TREE
	call	VisQueryWindow
	tst	di
	jz	VIT_90			; if no window, done
	clr	cl			; normal bounds
	call	VisGetBounds
	dec	cx			; use device coords
	dec	dx			;
	sub	cx, ax			; get window bounds in doc coords
	sub	dx, bx
	clr	ax
	clr	bx
	clr	bp			; passing a rectangle, not a region
	clr	si
	call	WinInvalTree
VIT_90:
	Destroy	ax, cx, dx, bp
	ret
			
VisInvalTree	endm

VisUncommon ends
			
