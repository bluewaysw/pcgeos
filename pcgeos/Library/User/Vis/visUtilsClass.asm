COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visUtilsClass.asm

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

	$Id: visUtilsClass.asm,v 1.1 97/04/07 11:44:35 newdeal Exp $

------------------------------------------------------------------------------@


JustECCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckVisCoords

DESCRIPTION:	Make sure cx & dx are valid graphics coordinates.
		Fatal errors if either is invalid.		

CALLED BY:	EXTERNAL

PASS:
	cx, dx	- coordinates

RETURN:
	nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@


ECCheckVisCoords	proc	far
if	ERROR_CHECK
	pushf
	cmp	cx, MAX_COORD
	jg	cx_BAD
	cmp	cx, MIN_COORD
	jge	cx_GOOD
cx_BAD:
	ERROR	UI_BAD_COORDINATE
cx_GOOD:
	cmp	dx, MAX_COORD
	jg	dx_BAD
	cmp	dx, MIN_COORD
	jge	dx_GOOD
dx_BAD:
	ERROR	UI_BAD_COORDINATE
dx_GOOD:
	popf
endif
	ret
ECCheckVisCoords	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckVisFlags

DESCRIPTION:	Validate vis instance data to make sure it contains legal
		TypeFlags, SpecAttrs, and VisAttrs.  Fatal errors if there
		is an illegal flag combination.

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- a vis object

RETURN:
	nothing

DESTROYED:
	nothing
	
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version
------------------------------------------------------------------------------@


if	ERROR_CHECK

ECCheckVisFlags	proc	far	uses di
	class	VisClass
	.enter
	pushf
	call	VisCheckIfVisGrown
	LONG jnc	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	notWinGroup
					; If win group, MUST be composite
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	ERROR_Z	UI_BAD_VIS_TYPE_FLAGS
					; If win group, MUST be window
	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW
	ERROR_Z	UI_BAD_VIS_TYPE_FLAGS
					; If win group, MUST NOT be portal
	test	ds:[di].VI_typeFlags, mask VTF_IS_PORTAL
	ERROR_NZ	UI_BAD_VIS_TYPE_FLAGS
	jmp	short afterWinGroup
notWinGroup:
					; If not win group, shouldn't be
					; marked as VISIBLE
	test	ds:[di].VI_attrs, mask VA_VISIBLE
	ERROR_NZ	UI_BAD_VIS_ATTRIBUTES
					; If not win group, none of these bits
					; should be set.
	test	ds:[di].VI_specAttrs, mask SA_REALIZABLE or \
			mask SA_USES_DUAL_BUILD or \
			mask SA_TREE_BUILT_BUT_NOT_REALIZED
	ERROR_NZ	UI_BAD_VIS_SPEC_ATTRIBUTES

afterWinGroup:
	test	ds:[di].VI_typeFlags, mask VTF_IS_PORTAL
	jz	afterPortal
afterPortal:
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jz	afterContent
					; If content, MUST be win group
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	ERROR_Z	UI_BAD_VIS_TYPE_FLAGS
afterContent:

done:
	popf
	.leave
	ret
ECCheckVisFlags	endp

else

ECCheckVisFlags	proc	far
	ret
ECCheckVisFlags	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisCheckVisAssumption

SYNOPSIS:	Error routine to check if specifically built.  Fatal errors
		if not.

CALLED BY:	utility

PASS:		*ds:si -- handle of object

RETURN:		nothing
		flags preserved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 2/89	Initial version

------------------------------------------------------------------------------@

VisCheckVisAssumption	proc	far
	class	VisClass
if	ERROR_CHECK

	call	ECCheckLMemObject

	pushf
	push	di
	mov	di, ds:[si]
	cmp	ds:[di].Vis_offset, 0		;fixed CBH 5/16/89	
	jnz	CVA_90
	ERROR	UI_VIS_USED_BEFORE_GROWN
CVA_90:
	pop	di
	popf
endif
	ret
VisCheckVisAssumption	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckVisMoniker

DESCRIPTION:	This is an error-checking procedure.

CALLED BY:	utility

PASS:		*es:di	- VisMoniker
		if di=0, no VisMoniker!

RETURN:		if OK

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	10/89		initial version

------------------------------------------------------------------------------@

;Make sure that *es:di is a single VisMoniker, NOT a VisMonikerList

if	ERROR_CHECK	;Start of ERROR_CHECK code ----------------------------

CheckVisMoniker	proc	far
	pushf
	tst	di				;Is there a VisMoniker?
	je	exit				;Exit if not.

	push	si
	push	ds							
	segmov	ds, es							
	mov	si, di							
	call	ECLMemValidateHandle					
	pop	ds							

	mov	si, es:[di]			;es:si = VisMoniker

	;whether this is a VisMoniker or VisMonikerListEntry, we know
	;that the first byte is the lower byte of the VisMonikerListEntryType word
	;-length record. Let's test some flags.

	test	es:[si].VM_type, mask VMT_MONIKER_LIST
	ERROR_NZ UI_VIS_MONIKER_IS_STILL_VIS_MONIKER_LIST

;more tests: could check integrity of GString, etc...

	pop	si
exit:
	popf
	ret
CheckVisMoniker	endp

endif			;End of ERROR_CHECK code ------------------------------

JustECCode	ends

;
;---------------
;
		
VisCommon	segment	resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisAddButtonPrePassive

DESCRIPTION:	This can be used to allow any subsequent button events anywhere
		in the system to be sent to this object BEFORE they are sent to 
		their normal destination.  This object will receive the monitor
		message in the form of a MSG_META_PRE_PASSIVE_BUTTON, and will be 
		passed the same position and flags as the destination object 
		will receive.  The flag MRF_PREVENT_PASS_THROUGH can be 
		returned in ax to prevent the destination from receiving the 
		button event. The pre-passive button events can be stopped by 
		sending a MSG_VIS_REMOVE_BUTTON_PRE_PASSIVE to the object.  

		NOTE:   If called on object which implements a passive grab
			node, results in object having a passive grab within
			itself.

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

PASSED IN MSG_META_POST_PASSIVE_BUTTON:
	Pass:	
		cx - 		pointer x position
		dx -		pointer y position
		bp low -	ButtonInfo
		bp high - 	ShiftState
 	Return:
		ax - 		MouseReturnFlags: MRF_PREVENT_PASS_THROUGH
				can be passed to keep destination object
				from receiving the message.
		cx, dx, bp - destroyed
		
DESTROYED:	nothing
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

VisAddButtonPrePassive	method VisClass, MSG_VIS_ADD_BUTTON_PRE_PASSIVE
	push	ax
	mov	al, mask VIFGF_MOUSE or mask VIFGF_GRAB
	mov	ah, VIFGT_PRE_PASSIVE
	GOTO	VisAlterInputFlowCommon, ax

VisAddButtonPrePassive	endm
	
	

COMMENT @----------------------------------------------------------------------

ROUTINE:	VisRemoveButtonPrePassive 

DESCRIPTION:	Removes the pre-passive grab for this object.

		NOTE:   If called on object which implements a passive grab
			node, results in object releasing any passive grab
			it has within itself.

PASS:		*ds:si -- object to release passive grab for

RETURN:		Carry set if element found & removed, clear if wasn't in list

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisRemoveButtonPrePassive method VisClass, MSG_VIS_REMOVE_BUTTON_PRE_PASSIVE
	push	ax
	mov	al, mask VIFGF_MOUSE
	mov	ah, VIFGT_PRE_PASSIVE
	GOTO	VisAlterInputFlowCommon, ax

VisRemoveButtonPrePassive	endm
	
	

COMMENT @----------------------------------------------------------------------

ROUTINE:	VisAddButtonPostPassive

DESCRIPTION:	This can be used to allow any subsequent button events anywhere
		in the system to be sent to this object AFTER they are sent to 
		their normal destination.  This object will receive the monitor
		message in the form of a MSG_META_POST_PASSIVE_BUTTON, and will be 
		passed the same position and flags as the destination object 
		received.  The post-passive button events can be stopped by 
		calling VisRemoveButtonPostPassive. 

		NOTE:   If called on object which implements a passive grab
			node, results in object having a passive grab within
			itself.

PASS:		*ds:si -- object

RETURN:		ds - updated to point at segment of same block as on entry

PASSED IN MSG_META_POST_PASSIVE_BUTTON:
	Pass:	
		cx - 		pointer x position
		dx -		pointer y position
		bp low -	ButtonInfo
		bp high - 	ShiftState
 	Return:
		ax, cx, dx, bp - destroyed


DESTROYED:	nothing
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
	
VisAddButtonPostPassive	method VisClass, MSG_VIS_ADD_BUTTON_POST_PASSIVE
	push	ax
	mov	al, mask VIFGF_MOUSE or mask VIFGF_GRAB
	mov	ah, VIFGT_POST_PASSIVE
	GOTO	VisAlterInputFlowCommon, ax

VisAddButtonPostPassive	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	VisRemoveButtonPostPassive

DESCRIPTION:	Removes the post-passive grab for this object.

		NOTE:   If called on object which implements a passive grab
			node, results in object releasing any passive grab
			it has within itself.

PASS:		*ds:si -- object to release passive grab for

RETURN:		Carry set if element found & removed, clear if wasn't in list

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisRemoveButtonPostPassive method VisClass, MSG_VIS_REMOVE_BUTTON_POST_PASSIVE
	push	ax
	mov	al, mask VIFGF_MOUSE
	mov	ah, VIFGT_POST_PASSIVE
	GOTO	VisAlterInputFlowCommon, ax

VisRemoveButtonPostPassive	endm

VisCommon	ends

;------------
	
VisOpenClose segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisExecute

DESCRIPTION:	Allows a way to execute a far routine on an object in another
		block or thread, rather than via a method call.  Can be useful
		for speed reasons.

CALLED BY:	EXTERNAL

PASS:		bx:si		- OD of object to execute "Vis" message on
		cx, dx, bp	- data to pass to "message handler"
		ax:di		- far routine to call (the "message hander")
		(ax:di is the vfptr in XIP version.)

	ROUTINE CALLED:

	    Pass:
		es		- segment of VisClass
		*ds:si		- object
		cx, dx, bp	- data

	    Return:
		ax, cx, dx, bp	- data


RETURN:		ax, cx, dx, bp	- data

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	If block is owned by running thread {
		push	bx
		ObjSwapLock
		push	bx
		mov	ds, ax
		call	routine passed
		pop	bx
		ObjSwapUnlock
		pop	bx
	} else {
		push on stack:  cx, dx, bp, ax, es
		setup bp as pointer to stack entry, dx = # of entries
		ObjMessage (MSG_VIS_CALL_ROUTINE, ^lbx:si)
		Fix stack	
	}


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@
VisExecute	proc	far
					; Before just locking next block,
					; see if run by same thread...
	call	ObjTestIfObjBlockRunByCurThread
	je	VE_SameThread		; branch if so.

	push	cx			; Pass cx, dx, bp args on stack
	push	dx
	push	bp
					; Push call back routine on stack
	push	ax			; 	segment first
	push	di			; 	then offset

	mov	bp, sp			; Setup bp & dx for stack-passing
	mov	dx, size VCR_param
					; Send routine-calling message to
					; our parent's VisClass handler
	mov	ax, MSG_VIS_CALL_ROUTINE
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; send message to our visible parent
					; Now, fix stack & return, preserving
					; the carry flag
	jc	VE_carrySet
	add	sp, size VCR_param	; Finally, fix stack
	clc
	ret
VE_carrySet:
	add	sp, size VCR_param	; Finally, fix stack
	stc
	ret

VE_SameThread:
	call	ObjSwapLock
	push	bx

if	FULL_EXECUTE_IN_PLACE
	mov_tr	bx, ax			;BX:AX <- routine to call
	mov_tr	ax, di
	call	ProcCallFixedOrMovable
		;FALLs THRU to VisExecuteContinue
else
					; Push routine to return to on stack
	mov	bx, cs
	push	bx
	mov	bx, offset VisExecuteContinue
	push	bx

	push	ax			; Push routine to call on stack
	push	di
	ret				; & do JUMP to it:  a far return
VisExecuteContinue	label	far	; Continues HERE
endif
	pop	bx
	GOTO	ObjSwapUnlock

VisExecute	endp

VisOpenClose	ends
;
;-------------------
;
VisConstruct	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisInsertChild

DESCRIPTION:	Add a child object to a composite.  Similar to the default
	vis handler for MSG_VIS_ADD_CHILD, except it allows caller to pass
	the handle and offset of the reference child rather than the reference
	child position.  If the caller is able to call this routine directly,
	it saves having to convert a

PASS:
	*ds:si - instance data (offset through Vis_offset)
	cx:dx  - object to add
	ax:bx  - reference child
	bp - flags for how to add child (InsertChildFlags)

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, cx, dx, di, bp
	
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

------------------------------------------------------------------------------@


VisInsertChild	proc	far
	class	VisCompClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.
EC <	call	VisCheckVisAssumption	; Make sure vis data exists >
EC <	push	bp							>
		;Test for any extraneous bits set
EC <	test	bp, not mask InsertChildFlags				>
EC <	ERROR_NZ VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS			>
EC <	and	bp, mask ICF_OPTIONS					>
EC <	cmp	bp, InsertChildOption					>
EC <	ERROR_AE VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS			>
EC <	pop	bp							>
EC <	test	bp, mask ICF_MARK_DIRTY					>
EC <	jz	10$							>
EC <	push	di							>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_NZ	VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS			>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_REQUIRES_VISUAL_COMPOSITE				>
EC <	pop	di							>
EC <10$:								>

	push	cx, dx
	mov	cx, ax			;pass reference child in cx:dx
	mov	dx, bx
	
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp	;
	test	bp, mask ICF_MARK_DIRTY	;
	pushf				;
	and	bp, mask ICF_OPTIONS	;
	cmp	bp, ICO_FIRST		;
	je	VIC_noRef		;
	cmp	bp, ICO_LAST		;
	je	VIC_last
	push	bp			;save flags
	call	ObjCompFindChild
	pop	dx			;restore flags
	jc	VIC_last		;if can't find ref, just add as last
	cmp	dx, ICO_BEFORE_REFERENCE;If before reference, branch
	je	VIC_noRef		;
	inc	bp
	jmp	VIC_noRef
VIC_last:
	mov	bp, CCO_LAST
VIC_noRef:
	popf				;Restore mark dirty flag
	je	noMarkDirty
	or	bp, mask CCF_MARK_DIRTY
noMarkDirty:
	DoPop	dx, cx			;restore child
	call	ObjCompAddChild

; ADDED this to fix update path, in the same manner as VisCompAddVisChild
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock		; Get child in *ds:si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cl, ds:[di].VI_optFlags	; fetch optimization flags
					; & see if there are any invalid
					; or path bits set
	and	cl, VOF_PATH_BITS or VOF_INVALID_BITS
	jz	VCAVC_afterUpdatePath	; if not, we're out of here, nothing
					;	to worry about.

					; OTHERWISE, we've may have just created
					; an illegal state.  We'll need to
					; fix up the path bits.
					; To do this,
	mov	ds:[di].VI_optFlags, 0	; 	first null out current opt flags
	mov	dl, VUM_MANUAL		; Don't update now, somebodys going
					; 	to have to update this anyway
	call	VisMarkInvalid		; Re-invalidate, setup path bits
					; 	all the way to the top

VCAVC_afterUpdatePath:
	call	ObjSwapUnlock
	ret


VisInsertChild	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	VisRemove

DESCRIPTION:	Primitive function which will VIS_CLOSE a non-WIN_GROUP
		visual branch if it is REALIZED, & then remove the object
		visually from its parent, marking parent as invalid, using
		update mode passed.

		Although this routine is used by VisUnbuild for generic
		objects, it is included as an exported library routine for
		use in simple visual objects as well -- The visual branch
		is simply CLOSED & removed from the tree, cleanly.

		This does not mark the objects as dirty, since it is assumed
		this routine is being used with generic objects and is only
		built temporarily.

		NOTE:  This should only be used on generic trees as part
		of a SPEC_UNBUILD process, as lack of a visual parent may
		result in initiating a new SPEC_BUILD process, which 
		objects may not be able to process correctly if they were
		not first unbuilt via SPEC_UNBUILD.

		
CALLED BY:	EXTERNAL
		VisUnbuild
		Is message handle for MSG_VIS_REMOVE

PASS:
	*ds:si - instance data
	dl - VisUpdateMode


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
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


VisRemove	proc	far	uses ax, bx, cx, dx, di, bp
	class	VisClass
	.enter

EC <	; Make sure that instance data is not hosed			>
EC <	call	ECCheckVisFlags						>

	call	VisCheckIfSpecBuilt	; check to see if this object
	LONG jnc	Done		; is vis built.  If not, done.

					; Release gadget exclusive, should we
					; have it. (Forces release of mouse
					; grab)
	push	dx
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParent
	pop	dx

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT	
	jnz	10$			; contents don't need to release
	call	MetaReleaseFTExclLow	; Release vis-linkage exclusives -
					; Focus & Target.
10$:
   	;
	; We'll invalidate the bounds of the non-win-group part of this object
	; so that the parent doesn't have to invalidate if removal of the
	; object doesn't cause geometry to be changed.  (-cbh 11/18/91)
	; (No VARF_ONLY_REDRAW_MARGINS here to ensure that the composite will
	; invalidate its *entire* bounds in MSG_VIS_ADD_RECT_TO_UPDATE_REGION.
	; We'll also assume that an update will happen as a result of this
	; removal, so that we don't need to invalidate the area just yet.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	20$			; win-groups do not add to inval region
	
	push	dx, si			; invalidate ourselves, for starters
	mov	cl, mask VARF_UPDATE_WILL_HAPPEN
	call	AddOurBoundsToUpdateRegion	;invalidate our bounds
	pop	dx, si
20$:	
	call	VisSetNotRealized	; Get objects to be NOT REALIZED
					; *ds:si = visible object to unbuild

	; NOW, need to remove the object from its visible parent.  If the
	; link is a one way link, however, we want to just zero out the link.
	; This is the case for WIN_GROUP which are TREE_BUILT_BUT_NOT_REALIZED,
	; and for CONTENT objects.
	;
	mov	bp, dx			; Keep update mode in bp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; doing a window group?
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jz	AfterWinGroupTest
					; See if fake upward link
	test	ds:[di].VI_specAttrs, mask SA_TREE_BUILT_BUT_NOT_REALIZED
	jnz	OneWayLink
AfterWinGroupTest:
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jz	RealRemove
OneWayLink:
					; NUKE the one way linkage by zeroing
					; out the instance data.
	clr	ax
	mov	ds:[di].VI_link.LP_next.handle, ax
	mov	ds:[di].VI_link.LP_next.chunk, ax

					; Clear flag, to indicate no longer
					; tree-built at this node.
	and	ds:[di].VI_specAttrs, not mask SA_TREE_BUILT_BUT_NOT_REALIZED
	jmp	short	Done		; & we're all done.  Don't have to
					; do anything to parent

RealRemove:
					; *ds:si = vis object
	push	si			; preserve vis object chunk handle
					; 	around SwapLock/Unlock calls

	mov	al, ds:[di].VI_typeFlags; save typeFlags for vis object
	mov	ah, ds:[di].VI_attrs	; save attributes for vis object
	push	ax

	mov	cx, ds:[LMBH_handle]	; cx:dx = vis object
	mov	dx, si
	call	VisFindParent		; Find visual parent
EC <	tst	bx						>
EC <	ERROR_Z	UI_VIS_REMOVE_NO_VIS_PARENT			>
					; ^lbx:si is parent
	call	ObjSwapLock		; *ds:si is now parent

					; Visually remove child
	;
	; Code added 9/17/90 to not mark things dirty, on the assumption that
	; all visual trees are built temporarily w.r.t. restoring objects from
	; state.  -chris
	;
	push	bp
	clr	bp			; else don't mark dirty
	mov	ax, MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock
	pop	bp

	pop	ax			; al typeFlags, ah attrs, for child

	push	bx			; preserve bx for ObjSwapUnlock


					; If doing top win group, then
					; don't mark parent as invalid
					; in any way (overlapping window,
					; no geometry or image to update)
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	al, mask VTF_IS_WIN_GROUP
	jnz	AfterParentInvalid
	test	ah, mask VA_MANAGED	; Child not managed, skip update,
	jz	AfterParentInvalid	;  who knows what to do.  (12/14/92 cbh)
	mov	dx, bp			; get update mode to use
					; If parent isn't realized, don't
					; mark invalid, don't bother updating
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	InvalGeometry		; parent is realized, branch
	mov	dl, VUM_MANUAL		; don't do any update if not realized
InvalGeometry:
	mov	cl, mask VOF_GEOMETRY_INVALID 
	
	;
	; New code 11/30/92 cbh to see if maybe redoing the entire win group's
	; geometry will improve things like wrapping controls inside non-
	; expand-to-fit composites, etc.   Could be a lot more processing, of
	; course.  (Not if parent doesn't manage children.  -cbh 12/14/92)
	;
;	call	VisMarkInvalid

	test	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	jnz	AfterParentInvalid
	call	VisVupInvalGeoToHere

AfterParentInvalid:

	pop	bx
	call	ObjSwapUnlock		; unlock parent object
	pop	si

Done:
	.leave
	ret

VisRemove	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VisVupInvalGeoToHere

DESCRIPTION:	Invalidates geometry of the visual tree from this object
	  	to its win group.

CALLED BY:	VisRemove

PASS:
	*ds:si - object
	dl - VisUpdateMode

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/14/93		Initial version

------------------------------------------------------------------------------@
VisVupInvalGeoToHere	proc	near
	class	VisClass

	call	checkIfGoingUpFurther
	push	dx
	jnc	invalidateNow			;not going up more, inval now
	mov	dl, VUM_MANUAL			;non win group, don't update

invalidateNow:
	mov	cl, mask VOF_GEOMETRY_INVALID
	call	VisMarkInvalid
	pop	dx

	call	checkIfGoingUpFurther
	jnc	exit

	push	si
	call	VisSwapLockParent
	jnc	noParent
	push	bx
	call	VisVupInvalGeoToHere
	pop	bx
	call	ObjSwapUnlock
noParent:
	pop	si
exit:
	ret


checkIfGoingUpFurther	label	near		;return carry set if going on
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_MANAGED
	jz	nope				;not managed, done, c=0
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP
	jnz	nope				;win group, done, c=0

	stc					;going up
nope:
	retn					

VisVupInvalGeoToHere	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompRemoveNonDiscardable --

DESCRIPTION:	Perform functionality of MSG_VIS_REMOVE and decrement the 
		object's in use count

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_REMOVE_NON_DISCARDABLE
	
	dl - VisUpdateMode

RETURN:
	nothing

DESTROYED:
	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@
VisCompRemoveNonDiscardable	method dynamic VisClass, 
					MSG_VIS_REMOVE_NON_DISCARDABLE
	.enter

	mov	ax,MSG_VIS_REMOVE
	call	ObjCallInstanceNoLock

	call	ObjDecInUseCount

	.leave
	Destroy	ax, cx,dx,bp
	ret

VisCompRemoveNonDiscardable	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisInvalAllGeometry -- 
		MSG_VIS_INVAL_ALL_GEOMETRY for VisClass

DESCRIPTION:	Invalidates the geometry of every object up to the win group.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_INVAL_ALL_GEOMETRY
		dl	- VisUpdateMode

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
	chris	11/30/92         	Initial Version

------------------------------------------------------------------------------@

VisInvalAllGeometry	method dynamic	VisClass, \
				MSG_VIS_INVAL_ALL_GEOMETRY

	test	ds:[di].VI_attrs, mask VA_MANAGED	
	jz	exit				;not managed, forget it

	mov	cl, mask VOF_GEOMETRY_INVALID

	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	doSelf

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di
	push	dx
	mov	dl, VUM_MANUAL
	call	VisSendToChildren
	pop	dx
	pop	di
	call	ThreadReturnStackSpace

doSelf:
	call	VisMarkInvalid			;mark this object invalid
exit:
	ret

VisInvalAllGeometry	endm

VisConstruct	ends
;
;-------------------
;
JustECCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckVisFindMonikerArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the args for VisFindMoniker (broken out to make routine
		smaller/easier to debug).

CALLED BY:	GLOBAL
PASS:		save as VisFindMoniker
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
CheckVisFindMonikerArgs	proc	far
	;check unused bits						
	test	bp, not VisMonikerSearchFlags			
	ERROR_NZ UI_BAD_SEARCH_SPEC_IN_VIS_FIND_MONIKER			

	;check for mutual exclusion					
	push	bp							
	and	bp, mask VMSF_COPY_CHUNK or mask VMSF_REPLACE_LIST	
	cmp	bp, mask VMSF_COPY_CHUNK or mask VMSF_REPLACE_LIST      
	pop	bp							
	ERROR_Z	UI_BAD_SEARCH_SPEC_IN_VIS_FIND_MONIKER			

	push	cx

	;check for illegal VMStyle					
	push	bp
	and	bp, mask VMSF_STYLE
	mov	cl, offset VMSF_STYLE
	shr	bp, cl
	cmp	bp, VMStyle
	pop	bp
	ERROR_AE	UI_BAD_SEARCH_SPEC_IN_VIS_FIND_MONIKER

	push	bx							
	and	bh, mask DT_DISP_SIZE
	mov	cl, offset DT_DISP_SIZE
	shr	bh, cl
	cmp	bh, DisplaySize
	pop	bx							
	ERROR_AE	UI_BAD_DISPLAY_TYPE_IN_VIS_FIND_MONIKER			

	push	bx							
	and	bh, mask DT_DISP_ASPECT_RATIO
	mov	cl, offset DT_DISP_ASPECT_RATIO
	shr	bh, cl
	cmp	bh, DisplayAspectRatio
	pop	bx							
	ERROR_AE	UI_BAD_DISPLAY_TYPE_IN_VIS_FIND_MONIKER			

	pop	cx
	ret
CheckVisFindMonikerArgs	endp
endif

JustECCode	ends
;
;-------------------
;
Build	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBestMonikerFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the best-fitting moniker from the list

CALLED BY:	GLOBAL
PASS:		ds:si - ptr into VisMonikerList
		bp - VisMonikerSearchFlags 
		bh - DisplayType 
		
RETURN:		^lcx:dx - moniker found
DESTROYED:	bx, si
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBestMonikerFromList	proc	near
	uses	ax, di, bp
	.enter

	;IS VisMonikerList (ds:si = start of list)

					;pass bh = DisplayType
	call	VisUpdateSearchSpec	;update search specification according
					;to DisplayType

	ChunkSizePtr	ds, si, cx	;set cx = size of chunk
	mov	bh, 0x80		;init best score to "none"
					;(no need to zero low byte)

looptop:	;for each moniker in the list:
	;	ds:si = pointer into VisMonikerList
	;	cx = size of MonikerList chunk remaining (6 bytes per entry)
	;	bp = VisMonikerSearchFlags (updated)
	;	bx = "score" of best moniker found so far
	;	di = offset from start of MonikerList to MonikerListEntry
	;		for "Best Moniker" so far

	mov	dx, ds:[si].VMLE_type	;get type record (word) for moniker
	call	VisTestMoniker		;set ax = score for this moniker

	tst	bx			;do we have a current best?
	js	newbest			;skip if not...

	cmp	ax, bx			;do we have a new Best Score?
	jle	next			;skip if not...

newbest:
	mov	di, si			;save offset to this ListEntry
	mov	bx, ax			;save new Best Score

next:
	add	si, size VisMonikerListEntry
	sub	cx, size VisMonikerListEntry
	jnz	looptop			;loop if more to go...

	;grab handle of best moniker (ds:di = ListEntry)

	mov	cx, ds:[di].VMLE_moniker.handle
	mov	dx, ds:[di].VMLE_moniker.chunk
	.leave
	ret
GetBestMonikerFromList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisFindMoniker

DESCRIPTION:	Find the specified moniker (or most approriate moniker) in
		this object's VisMonikerList, and optionally copy the
		Moniker into this object block, OR replace the
		VisMonikerList with the moniker.

		Note: given a legal MonikerList, this procedure will ALWAYS
		find at least one moniker in the list, even if it is really
		inappropriate. Example: when searching for a non-gstring,
		if none exist, will get a gstring which best matches.

CALLED BY:	EXTERNAL

PASS:		bh = DisplayType for application which will draw moniker
		*ds:di = VisMoniker or VisMonikerList
		bp	- VisMonikerSearchFlags (see visClass.asm)
				flags indicating what type of moniker to find
				in the VisMonikerList, and what to do with
				the Moniker when it is found.
		cx = handle of destination block (if using VMSF_COPY_CHUNK
			command to copy moniker to destination block. (must be
			run by current thread))

RETURN:		ds updated if ObjectBlock moved as a result of chunk overwrite
		^lcx:dx	- handle of VisMoniker (cx, dx = 0 if none)
		WARNING: If ES points to either of the blocks, and they move,
			 ES will *NOT* be updated.
DESTROYED:	si
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

NOTE:  If VMSF_COPY_CHUNK is passed, & the moniker selected by the
	search flags turns out to be in the same block as cx refers to,
	then the moniker is NOT copied, but instead its chunk handle is
	returned.  This may seem to be efficient, but may not yield the
	desired effect...
- No longer done - brianc 4/3/92


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version
	atw	4/90		re-write, doesn't mark chunks as dirty
------------------------------------------------------------------------------@


VisFindMoniker	proc	far
	uses	ax, bx, di, bp
	class	VisClass		; Indicate function is a friend
					; of VisClass so it can play with
					; instance data.
	.enter
EC <	call	CheckVisFindMonikerArgs					>

	xchg	ax, cx			;ax = destination ObjectBlock (1 byte)
	clr	cx			;default: return null handle
	mov	dx, cx
	tst	di			;is there a chunk handle?
	jz	exit			;skip if not...

	;There is a VisMoniker or VisMonikerList. Make ^lcx:dx point to
	;start of it. If it is just a VisMoniker, skip ahead...

	mov	cx, ds:[LMBH_handle]	;set ^lcx:dx = VisMoniker
	mov	dx, di

	mov	si, ds:[di]		;ds:si = VisMoniker
	test	ds:[si].VM_type, mask VMT_MONIKER_LIST
	jz	checkForCopyChunk	;skip ahead if is single moniker...
					;(see if need to copy to dest. block)
	call	GetBestMonikerFromList

	;we have found our VisMoniker in the list: check for special
	;instructions on what to do to it.
	;	*ds:di	= VisMonikerList
	;	^lcx:dx = VisMoniker
	;	bp	= VisMonikerSearchFlags
	;	ax	= handle of destination ObjectBlock (if copying)

	test	bp, mask VMSF_REPLACE_LIST	;Check if replacing list
	jnz	replaceList			;Branch if so...
checkForCopyChunk:	;check for special instruction:
	test	bp, mask VMSF_COPY_CHUNK
	jz	exit			;skip if not...
	clr	bx			;BX <- create new chunk 
;	cmp	cx, ax			;If source = dest, just skip copy
;	jne	doCopy			;If source != dest, do copy
;	xchg	cx, ax			;^lCX:DX <- vis Moniker (1-byte inst.)
;	jmp	exit
;no longer done - brianc 4/3/92
	jmp	doCopy

replaceList:
	mov	ax, ds:[LMBH_handle]	
	mov	bx, di			;^lAX:BX <- dest chunk
doCopy:

	;Copy the VisMoniker chunk from where it is into this object's
	;block (if there already, do nothing)
	;	ax	= handle of destination block
	;	bx 	= destination chunk (0 if we want to create a new one)
	;	*ds:di	= VisMonikerList
	;	^lcx:dx = VisMoniker
	;	(on stack) = DisplayType
	;	bp	= VisMonikerSearchFlags

	push	ax				;Save dest handle
	sub	sp, size CopyChunkOVerFrame
	mov	bp, sp
	mov	ss:[bp].CCOVF_source.handle, cx	;Set up optr to source chunk
	mov	ss:[bp].CCOVF_source.chunk, dx	;
	mov	dx, size CopyChunkOVerFrame	;
	mov	ss:[bp].CCOVF_dest.handle, ax	;Set up ptr to dest block
	mov	ss:[bp].CCOVF_dest.chunk, bx	;
						;Don't mark Dirty
	mov	ss:[bp].CCOVF_copyFlags, CCM_OPTR shl offset CCF_MODE
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo		; Get current thread in ax
	mov	bx, ax
	mov	ax, MSG_PROCESS_COPY_CHUNK_OVER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage			;Returns chunk in ax
	add	sp, size CopyChunkOVerFrame	;
	pop	cx				;
	xchg	ax,dx				;^lCX:DX <- moniker chunk
						; (1 byte inst)
exit:
	.leave
	ret

VisFindMoniker	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisUpdateSearchSpec	

DESCRIPTION:	This procedure updates the search specification passed to
		VisFindMoniker according to the passed DisplayType.

CALLED BY:	VisFindMoniker

PASS:		bh = DisplayType for application which will draw moniker
		bp	- VisMonikerSearchFlags (see visClass.asm)
				flags indicating what type of moniker to find
				in the VisMonikerList, and what to do with
				the Moniker when it is found.

RETURN:		bh - same
		bp  -updated

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version
	atw	10/90		Changed not to change the requested size if
				on HUGE/TINY displays
------------------------------------------------------------------------------@

VisUpdateSearchSpec	proc	far
	mov	ax, bp				;ax = SearchFlags
	mov	al, bh				;store DisplayType in unused
						; low 8 bits of SearchFlags
	mov	bp, ax				;return updated SearchFlags
	ret
VisUpdateSearchSpec	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisTestMoniker

DESCRIPTION:	This procedure examines one VisMoniker in a moniker list
		and returns a value indicating how good a fit this moniker
		is to the search specification.
		measure of its appropriateness.

CALLED BY:	EXTERNAL

PASS:		dx = VisMonikerListEntryType
		bp = VisMonikerSearchFlags (see visClass.asm)
				flags indicating what type of moniker to find
				in the VisMonikerList, and what to do with
				the Moniker when it is found. Have been
				updated according to DisplayType.

RETURN:		dx, bp = same
		ax = "score" for this moniker

DESTROYED:	NOTHING

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		initial version
	brianc	8/26/92		updated for new moniker flags

------------------------------------------------------------------------------@

;This structure is used to build up a score which indicates how close
;this moniker is to the search specification. In each field, we place
;a value between 0 and (2^field_size)-1 which indicates how close the
;moniker matches on that score. THEREFORE, by reordering these fields,
;you can change the priority we place on each attribute.

; changed to give GS_ASPECT_RATIO priority over GS_SIZE and GS_COLOR
; (previously had lower priority than both) - brianc 9/20/93

VisMonikerScore record
	:1,			;DO NOT USE THIS HIGHEST BIT
	:2,			;unused fields
				;highest priority - is a REQUIREMENT
	SCORE_TEXT_OR_GSTRING:1, ;TRUE if TEXT/GSTRING preference met
	SCORE_STYLE:4		;degree of style fit: 15=best, 0=worst
	SCORE_GS_ASPECT_RATIO:2, ;degree of aspect ratio fit: 3=best, 0=worst
	SCORE_GS_SIZE:2,	;degree of size fit: 3=best, 0=worst
	SCORE_GS_COLOR:4,	;degree of color-level fit: 15=best, 0=worst
VisMonikerScore end

VisTestMoniker	proc	far
	push	bx, cx			;save regs
	clr	ax			;initialize score

	;=====================================================================
	;test for TEXT/GSTRING status (bp = SearchFlags, dx = MonikerType,
	;ax = score)

	test	dx, mask VMLET_GSTRING		;is moniker a gstring?
	jz	monikerIsText			;no
	test	bp, mask VMSF_GSTRING		;else, check if looking for gs
	jz	afterTextOrGString		;unwanted gstring, don't update
updateTextOrGStringScore:
	ornf	ax, mask SCORE_TEXT_OR_GSTRING	;else, update score
	jmp	short afterTextOrGString

monikerIsText:
	test	bp, mask VMSF_GSTRING		;check if looking for text
	jz	updateTextOrGStringScore		;yes, update score
afterTextOrGString:

	;=====================================================================
	;test for STYLE
	;
	;XXX: find some efficient way to do a full suite of comparisons
	;
	;(bp = SearchFlags, dx = MonikerType, ax = score)

	push	dx, bp

	andnf	bp, mask VMSF_STYLE		;bp = requested style
	mov	cl, offset VMSF_STYLE
	shr	bp, cl

	andnf	dx, mask VMLET_STYLE		;dx = moniker style
	mov	cl, offset VMLET_STYLE
	shr	dx, cl

	cmp	bp, dx
	jne	diffStyle

	ornf	ax, mask SCORE_STYLE		;give it full style points

diffStyle:
	pop	dx, bp

	;=====================================================================
	;if is GSTRING, test for SIZE
	;(bp = SearchFlags, dx = MonikerType, ax = score)

	test	dx, mask VMLET_GSTRING 		;is it a GString?
	LONG	jz VTM_80			;skip if not (is text)...

	push	dx, bp

	andnf	dx, mask VMLET_GS_SIZE
	mov	cl, offset VMLET_GS_SIZE
	shr	dx, cl				;dx = moniker size

	andnf	bp, mask DT_DISP_SIZE
	mov	cl, offset DT_DISP_SIZE
	shr	bp, cl				;bp = requested size

	sub	bp, dx				;calculate difference between
						;requested size and
						;moniker size
	jns	VTM_35				;skip if moniker smaller...

	;moniker is bigger: convert dx from negative value to positive

	neg	bp

VTM_35:	;bx = # of sizes difference between requested size and moniker size
	;(a value between 0 and 3).

	mov	cl, offset SCORE_GS_SIZE
	shl	bp, cl				;move into correct score field

	xor	bp, mask SCORE_GS_SIZE		;translate into GOODNESS value
						;where 3=best, 0=shitty

	or	ax, bp				;add to score

	pop	dx, bp

	;=====================================================================
	;if is GSTRING, test for COLOR
	;(bp = SearchFlags, dx = MonikerType, ax = score)

	push	dx, bp

	andnf	dx, mask VMLET_GS_COLOR
	mov	cl, offset VMLET_GS_COLOR
	shr	dx, cl				;dx = moniker color

	andnf	bp, mask DT_DISP_CLASS
	mov	cl, offset DT_DISP_CLASS
	shr	bp, cl				;bp = requested color

	sub	bp, dx				;calculate difference between
						;requested color level and
						;moniker color level
	js	VTM_50				;skip if moniker requires
						;a higher-level screen...
						;(score of 0 for this field)

	mov	cl, offset SCORE_GS_COLOR
	shl	bp, cl				;move into correct score field

	xor	bp, mask SCORE_GS_COLOR		;translate into GOODNESS value
						;where 15=best, 0=shitty

	or	ax, bp				;add to score

VTM_50:
	pop	dx, bp

	;=====================================================================
	;if is GSTRING, test for ASPECT RATIO
	;(bp = SearchFlags, dx = MonikerType, ax = score)

	push	dx, bp

	andnf	dx, mask VMLET_GS_ASPECT_RATIO
	mov	cl, offset VMLET_GS_ASPECT_RATIO
	shr	dx, cl				;dx = moniker asp

	andnf	bp, mask DT_DISP_ASPECT_RATIO
	mov	cl, offset DT_DISP_ASPECT_RATIO
	shr	bp, cl				;bp = requested asp

if 0	; changed to require matching aspect ratio - brianc 9/20/93 -----------

	cmp	bp, DAR_SQUISHED
	pushf					; Save test results for later

	sub	bp, dx				;calculate difference between
						;requested ratio and
						;moniker ratio
	jns	VTM_55				;skip if moniker more normal...

	;moniker is more squished: convert bp from negative value to positive

	neg	bp

VTM_55:	;bp = # of sizes difference between requested size and moniker size
	;(a value between 0 and 3), shifted over to the field position
	;in the record.

	; At this point, the results in BP should look something like the chart
	; below.  Since BP = 0 if a match is found, you'd like to minimize BP.
	; In the first and last row, there is a clear heirarchy of priorities.
	; In the middle row, it's not clear whether you'd rather use NORMAL
	; or VERY_SQUISHED, since BP is the same value in each.  Therefore, we
	; need to special case it, and give a lower priority to VERY_SQUISHED.
	; (i.e. if it's not SQUISHED, you'd rather call it NORMAL than
	; VERY_SQUISHED.
	;		dx:	NORMAL		SQUISHED	VERY_SQUISHED
	;  bp:
	;  NORMAL		0		1		2
	;  SQUISHED		1		0		1 -> 2
	;  VERY SQUISHED	2		1		0
	popf					; Were we looking for SQUISHED?
	jne	notSpecialCase			;  If not, it's not special case
	cmp	dx, DAR_VERY_SQUISHED		; Do we have a VERY_SQUISHED?
	jne	notSpecialCase			;  If not, it's not special case
	;
	; If this is verySquished when looking for squished, then downgrade 
	; its score.
	inc	bp				; Lower its score/priority
notSpecialCase:

	mov	cl, offset SCORE_GS_ASPECT_RATIO
	shl	bp, cl				;move into correct score field

	xor	bp, mask SCORE_GS_ASPECT_RATIO	;translate into GOODNESS value
						;where 3=best, 0=shitty

	or	ax, bp				;add to score

else	;----------------------------------------------------------------------

	cmp	bp, dx
	jne	diffAspect

	ornf	ax, mask SCORE_GS_ASPECT_RATIO	;give it full aspect points
						;	if matching aspect,
						;	else no points

diffAspect:

endif	;----------------------------------------------------------------------

	pop	dx, bp

VTM_80:	;=====================================================================
	;all done
	pop	bx, cx				;restore regs
	ret
VisTestMoniker	endp


Build ends

;------------

VisUpdate segment resource




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisRecalcSizeAndInvalIfNeeded

SYNOPSIS:	Queries an object for its size in an optimal way.  Works for
		any object and takes into account optimization flags.  Clears
		the object's geometry flags and sets the image and window 
		invalid flags ONLY if the object changes size.

CALLED BY:	utility

PASS:		*ds:si -- handle of object
		cx     -- width argument
		dx     -- height argument
		
RETURN:		cx, dx -- size to use
		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/10/89	Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisRecalcSizeAndInvalIfNeeded	method VisClass, MSG_VIS_RECALC_SIZE_AND_INVAL_IF_NEEDED
	uses	bp, ax, bx
	
	.enter
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >

	mov	bp, ds:[si]			;point to child instance
	add	bp, ds:[bp].Vis_offset		;ds:bp - child VisInstance
	;
	; Get current size.  We'll keep passed size in ax, bx
	;
	mov	ax, cx				;passed stuff in ax, bx
	mov	bx, dx
	call	VisGetSize			;get the current size
	;
	; If object's geometry is invalid, call MSG_VIS_RECALC_SIZE.
	;
	test	ds:[bp].VI_optFlags, mask VOF_GEOMETRY_INVALID or \
			             mask VOF_GEO_UPDATE_PATH
	jnz	VFCNS_callMethod		;call method if geo invalid
	
	test	ds:[bp].VI_geoAttrs, mask VGA_ALWAYS_RECALC_SIZE
	jnz	VFCNS_callMethod		;send method in this case
	
	test	ds:[bp].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
	jnz	VFCNS_exit			;just use current size
	
	;
	; If passed values are the same as current, we'll return the current
	; size.  If a desired dimension is passed, we'll assume that
	; we don't need to do another RecalcSize (could be wrong, we'll see)
	; 
	tst	ax				;see if desired passed
	js	VFCNS_checkHeight		;yes, still might skip
	cmp	ax, cx				;same size passed?
	jne	VFCNS_callMethod		;different size, must calc
	
VFCNS_checkHeight:
	tst	bx				;see if desired height passed
	js	VFCNS_exit			;Yes! Use current size
	cmp	bx, dx				;same size passed?
	je	VFCNS_exit			;Yes! Use current size.
	
VFCNS_callMethod:
	mov	cx, ax				;passed arguments in cx, dx
	mov	dx, bx				
	;
	; Before getting a new size for the object, save its old bounds.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED
	jz	10$			; geometry never been calculated, branch
	call	SaveOldBounds		; we'll save the old bounds.  When 
					; VisSendPositionAndInvalIfNeeded comes
					; along, it will
					; check the new bounds against the
					; old and invalidate as necessary.
					; (cbh 11/91)
	jmp	short 20$
10$:
	;
	; Set the invalid bits in the object, so the new area will be redrawn
	; as well.    This check put in on the off chance that the IMAGE_INVALID
	; flags have gotten cleared somehow, as may happen if we allow things
	; to be VIS_OPEN'ed before geometry is done.  -cbh 2/ 1/93
	;
	push	cx, dx
	mov	cx, mask VOF_WINDOW_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid		; mark invalid
	pop	cx, dx
20$:
	mov	ax, MSG_VIS_RECALC_SIZE	;get the child's best fit
	call	ObjCallInstanceNoLock

VFCNS_exit:
	mov	bp, ds:[si]			;point to instance
	add	bp, ds:[bp].Vis_offset		;ds:[di] -- VisInstance
	and	ds:[bp].VI_optFlags, not (mask VOF_GEOMETRY_INVALID \
					 or mask VOF_GEO_UPDATE_PATH)
	.leave
	ret
VisRecalcSizeAndInvalIfNeeded	endm


	


COMMENT @----------------------------------------------------------------------

ROUTINE:	SaveOldBounds

SYNOPSIS:	Saves current bounds, for checking for later changes.

CALLED BY:	ResizeChild

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/31/91		Initial version

------------------------------------------------------------------------------@

SaveOldBounds	proc	near		uses	bp, bx, cx, dx
	class	VisClass
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_OLD_BOUNDS_SAVED
	jnz	10$			; bounds already saved, branch
	
	or	ds:[di].VI_attrs, mask VA_OLD_BOUNDS_SAVED
	
	;
	; Create a TEMP_VIS_OLD_BOUNDS structure with the appropriate arguments,
	; and save it.
	;
	mov	cx, size Rectangle
	mov	ax, TEMP_VIS_OLD_BOUNDS
	call	ObjVarAddData
	mov	bp, bx			; DS:BP <- extra data
	
	call	VisGetBounds
	mov	ds:[bp].R_left, ax
	mov	ds:[bp].R_top, bx
	mov	ds:[bp].R_right, cx
	mov	ds:[bp].R_bottom, dx
10$:
	.leave
	ret
SaveOldBounds	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSendPositionAndInvalIfNeeded

SYNOPSIS:	Sends a MSG_VIS_POSITION_BRANCH to an object, accounting for 
		any optimization flags that may speed up the process.  Also 
		will set the object's image and window invalid flags.  Will
		avoid doing anything if the object is getting the same position
		it currently has.  In general, it is a good idea for a composite
		to use this in its geometry handler for positioning a child
		branch, rather than calling MSG_VIS_POSITION_BRANCH directly.
		Also sets the VGA_GEOMETRY_CALCULATED flag and notifies the
		object that its geometry has been recalculated.

CALLED BY:	utility

PASS:		*ds:si -- handle of object
		cx, dx -- position
		
RETURN:		*ds:si	- still pointing at object
		carry set if object's bounds changed from the old bounds
			(if any, stored here or previously in VisRecalcSizeAndInvalIfNeeded)
		(ds - updated to point at segment of same block as on entry)

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/10/89	Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisSendPositionAndInvalIfNeeded	method VisClass, MSG_VIS_POSITION_AND_INVAL_IF_NEEDED
	class	VisClass	
	uses	ax, cx, dx, bp
	
	.enter
EC<	call	VisCheckVisAssumption		;make sure vis data exists >

if	0	
	;
	; Removed.  Invalidation is handled by the geometry manager.
	;
	mov	di, ds:[si]			;point to child
	add	di, ds:[di].Vis_offset		;ds:di - VisInstance
	cmp	cx, ds:[di].VI_bounds.R_left	;see if thing is moving
	jne	saveOldBounds			;yesm branch to save old bounds
	cmp	dx, ds:[di].VI_bounds.R_top	;see if thing is moving
	jz	VMF_exit			;nope, don't bother with this
saveOldBounds:
endif
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED
	jz	10$			; geometry never been calculated, branch
					; (added 5/ 4/92 cbh)
	call	SaveOldBounds		; we'll save the old bounds, if not
					; already saved in VisRecalcSizeAnd-
					; InvalIfNeeded.  
					; After positioning the object, it will
					; check the new bounds against the
					; old and invalidate as necessary.
					; (cbh 12/91)
10$:					
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_geoAttrs, mask VGA_USE_VIS_SET_POSITION  ;call VisSetPosition?
	jz	VMF_callMethod			;no, branch to do message call
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE  ;composite?
	jz	VMF_visMove			;no, go do a vis move
	push	bx, si, es
	clr	bp				;no special flags
	call	VisCompPosition			;else do a vis comp position
	DoPop	es, si, bx
	jmp	short VMF_finish
	
VMF_visMove:
	call	VisSetPosition			     ;call vis position directly
	jmp	short VMF_finish
	
VMF_callMethod:
	mov	ax, MSG_VIS_POSITION_BRANCH	     ;position branch at cx, dx
	call	ObjCallInstanceNoLock
	
VMF_finish:
	mov	di, ds:[si]		; point to child instance
	add	di, ds:[di].Vis_offset	; ds:[di] -- VisInstance
	or	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED

	;
	; Used to be below notify, moved up here so we can look at VOF_IMAGE_-
	; INVALID to see if things really changed.  -cbh 11/17/92
	; (Changed 12/ 8/92 to skip notify if no bounds change.)
	; (Changed back 12/16/92.  This is a bad idea.)
	;	
	call	CheckForBoundsChange		     ;compare new bounds with

;	jnc	VMF_exit			     ;  old (saved in VisSend
;						     ;   Position)
;
	;
	; At this point, we're finished with this object as far as geometry
	; is concerned.  Send out a notification if necessary.
	;
	pushf
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID
	jz	VMF_noNotify			; no notify necessary, branch
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLock		; send out notification
VMF_noNotify:
	popf					; restore whether bounds changed
;VMF_exit:
	.leave
	ret
VisSendPositionAndInvalIfNeeded	endm





COMMENT @----------------------------------------------------------------------

FUNCTION:	VisGetParentCenter

DESCRIPTION:	Returns the center of an object's visual parent, in an 
		optimized fashion.
		NOT INTENDED TO BE RESILIENT TO PROBLEMS -- will
		fatal error if the data is not there...

CALLED BY:	EXTERNAL

PASS:		*ds:si	- visible object 

RETURN:		cx 	- minimum amount needed left of center, in parent
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
	Chris	4/20/92		Initial version
	
------------------------------------------------------------------------------@

VisGetParentCenter	proc	far
	class	VisCompClass
	push	bx
	push	si
	push	di
	call	VisSwapLockParent
EC <	ERROR_NC	UI_VIS_GET_PARENT_GEOMETRY_NO_PARENT		>
EC <	call	VisCheckIfVisGrown					>
EC <	ERROR_NC	UI_VIS_GET_PARENT_GEOMETRY_PARENT_NOT_GROWN	>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset		; ds:di = VisInstance	>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	ERROR_Z	UI_VIS_GET_PARENT_GEOMETRY_PARENT_NOT_COMPOSITE		>

	call	VisSendCenter

	call	ObjSwapUnlock
	pop	di
	pop	si
	pop	bx
	ret

VisGetParentCenter	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	VisSendCenter

SYNOPSIS:	Figures out the center of an object.

CALLED BY:	

PASS:		*ds:si -- object to get center for

RETURN:		cx 	- minimum amount needed left of center
		dx	- minimum amount needed right of center
		ax 	- minimum amount needed above center
		bp      - minimum amount needed below center
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/13/90		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@

VisSendCenter	proc	far		uses	di
	class	VisClass
	.enter
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_geoAttrs, mask VGA_USE_VIS_CENTER	
	jz	methodCenter			;not set, use method
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	visCenter			;not composite, branch
	
;compCenter:
 	push	bx, si, es
	call	VisCompGetCenter		;do visual center
 	pop	bx, si, es
	jmp	short exit
	
visCenter:
	call	VisGetCenter			;do comp center
	jmp	short exit
	
methodCenter:
	mov	ax, MSG_VIS_GET_CENTER		;do message center
	call	ObjCallInstanceNoLock
	
exit:
	.leave
	ret
VisSendCenter	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckForBoundsChange

SYNOPSIS:	Checks for bounds changes, and sends the appropriate message.

CALLED BY:	MoveChild, VisUpdateGeometry

PASS:		*ds:si -- object to check

RETURN:		carry set if bounds changed, or none found.

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/31/91		Initial version

------------------------------------------------------------------------------@

CheckForBoundsChange	proc	near		uses	bx, bp
	class	VisClass	
	oldBounds 	local Rectangle
	.enter
	;
	; Invalidate the object if it has moved from its previous
	; position.  Really invalidate its old bounds here.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].VI_attrs, not mask VA_OLD_BOUNDS_SAVED	
	
	mov	di, cs
	mov	es, di
	mov	di, offset cs:OldBoundsTable
	mov	ax, length (cs:OldBoundsTable)
	clr	cx			;keep track of whether we find data
	call	ObjVarScanData		;stuff in temp data
	tst	cx
	stc
	jz	exit			;no old bounds found, exit
	mov	ax, TEMP_VIS_OLD_BOUNDS
	call	ObjVarDeleteData
	
	call	VisGetBounds
	cmp	ax, oldBounds.R_left
	jnz	callBoundsChanged
	cmp	bx, oldBounds.R_top
	jnz	callBoundsChanged
	cmp	cx, oldBounds.R_right
	jnz	callBoundsChanged
	cmp	dx, oldBounds.R_bottom
	jnz	callBoundsChanged
	clc				; signal no bounds change
	jmp	short exit		; nothing to change, just exit.
	
callBoundsChanged:
	push	bp			; save base pointer
	lea	bp, oldBounds	
	mov	dx, size Rectangle
	call	VisBoundsChanged
	pop	bp
	stc				; say there was a bounds change
exit:
	.leave
	ret
CheckForBoundsChange	endp

			
			
OldBoundsTable	VarDataHandler \
	<TEMP_VIS_OLD_BOUNDS, offset GetOldBounds>
	
GetOldBounds	proc	far
	oldBounds	local	Rectangle
	.enter	inherit
	mov	ax, ds:[bx].R_left
	mov	oldBounds.R_left, ax
	mov	ax, ds:[bx].R_top
	mov	oldBounds.R_top, ax
	mov	ax, ds:[bx].R_right
	mov	oldBounds.R_right, ax
	mov	ax, ds:[bx].R_bottom
	mov	oldBounds.R_bottom, ax
	inc	cx				;say we found hint
	.leave
	ret
GetOldBounds	endp


VisUpdate ends
