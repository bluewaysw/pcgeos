COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visComp.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VisCompClass		General purpose Visible composite object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the VisCompClass.

	$Id: visComp.asm,v 1.1 97/04/07 11:44:22 newdeal Exp $

------------------------------------------------------------------------------@
;see documentation in /staff/pcgeos/Library/User/Doc/VisComp.doc

UserClassStructures	segment resource

;
; Declare the class record.
;
	VisCompClass	mask CLASSF_DISCARD_ON_SAVE

	method	VisCompMakePressesNotInk, VisCompClass,
				MSG_META_QUERY_IF_PRESS_IS_INK

	method	VisCallChildrenInBounds, VisCompClass, 
				MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK

;
; "Mouse" events, which should be sent on to child under point.
; NOTE:  IF YOU CHANGE THIS LIST, please update VisContentClass as well.
;
	
	method	VisCallChildUnderPoint, VisCompClass, MSG_META_PTR, \
				      MSG_META_START_SELECT, \
				      MSG_META_END_SELECT, \
				      MSG_META_DRAG_SELECT, \
				      MSG_META_START_MOVE_COPY, \
				      MSG_META_END_MOVE_COPY, \
				      MSG_META_DRAG_MOVE_COPY, \
				      MSG_META_START_FEATURES, \
				      MSG_META_END_FEATURES, \
				      MSG_META_DRAG_FEATURES, \
				      MSG_META_START_OTHER, \
				      MSG_META_END_OTHER, \
				      MSG_META_DRAG_OTHER

UserClassStructures	ends

;---------------------------------------------------

VisConstruct segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompInitialize -- MSG_META_INITIALIZE for VisCompClass

DESCRIPTION:	Initialize a VisCompClass object.  This does parent class
	initialization, followed by init of the Comp part:  Initializes
	composite linkage, marks visible object as a composite. 

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass

	ax, bx	-- DON'T CARE (may safely be called using CallMod)

RETURN:
	nothing
	ax, cx, dx, bp -- destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

VisCompInitialize	method static	VisCompClass, MSG_META_INITIALIZE
	uses di
	.enter

	call	VisInitialize

	mov	di, ds:[si]	; get pointer to instance data
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
				; Set opitimization flag to show as being
				; a composite
	ornf	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	
	.leave
	Destroy	ax, cx, dx, bp
	ret

VisCompInitialize	endm


VisConstruct	ends
;
;-------------------
;
VisOpenClose	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompCloseWin -- MSG_VIS_CLOSE_WIN for VisCompClass

DESCRIPTION:	DEFAULT routine to close the window
	in a composite windowed object.  Calls WinClose, stuff 0 into VCI_window.

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_CLOSE_WIN

RETURN:
	nothing
	ax, cx, dx, bp -- destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

VisCompCloseWin	method	dynamic VisCompClass, MSG_VIS_CLOSE_WIN
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset			;ds:di = VisInstance
	clr	di
	xchg	di, ds:[bx].VCI_window	; get window handle, store 0
	tst	di
	jz	done			; if already closed, done

	call	WinClose		; close the window
done:
	Destroy	ax, cx, dx, bp
	ret

VisCompCloseWin	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisCompAddChild -- MSG_VIS_ADD_CHILD for VisCompClass

DESCRIPTION:	Add a child object to a composite

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_ADD_CHILD

	^lcx:dx  - object to add
	bp - CompChildFlags

RETURN:
	cx, dx -- preserved
	ax, bp -- destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


; NOTE:  Placed in VisUpdate instead of VisConstruct because is needed to
; bring up already-constructed menu.
;
VisCompAddChild	method dynamic VisCompClass, MSG_VIS_ADD_CHILD 
			uses	cx, dx
	.enter

EC <	test	bp, mask CCF_MARK_DIRTY					>
EC <	jz	10$							>
EC <	push	di							>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_NZ	VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS		>
EC <	pop	di							>
EC <10$:	 							>

	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompAddChild

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

	.leave
	Destroy	ax, bp
	ret

VisCompAddChild	endm

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompRemoveVisChild
			-- MSG_VIS_REMOVE_CHILD for VisCompClass

DESCRIPTION:	Remove a child object from a composite

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_REMOVE_CHILD
	bp - mask CCF_MARK_DIRTY set if parent and siblings should be dirtied
	     appropriately

	^lcx:dx - child to remove

RETURN:
	cx, dx -- preserved
	ax, bp -- destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


; NOTE:  Placed in VisUpdate instead of VisConstruct because is needed to
; bring down already-constructed menu.

VisCompRemoveVisChild	method	VisCompClass, MSG_VIS_REMOVE_CHILD
					uses 	cx, dx
	.enter
EC <	test	bp, not mask CCF_MARK_DIRTY				>
EC <	ERROR_NZ	VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS		>
   
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	clr	bp
	call	ObjCompRemoveChild
	.leave
	Destroy	ax, bp
	ret

VisCompRemoveVisChild	endm
	

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompAddNonDiscardableVMChild --

DESCRIPTION:	Add a child object to a composite using MSG_VIS_ADD_CHILD
		and increment the in use
		count of the child so that it won't get discarded and
		lose its parent pointer

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_ADD_CHILD

	^lcx:dx  - object to add
	bp - CompChildFlags, CCF_MARK_DIRTY ignored

RETURN:
	cx, dx -- preserved
	ax, bp -- destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@
VisCompAddNonDiscardableVMChild	method dynamic VisCompClass, 
					MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD 
	.enter

	;   Increment the in use count of the child and clear the child's
	;   parent pointer which invariably ends up in the file from
	;   the last time the document was opened and will cause death
	;   in MSG_VIS_ADD_CHILD.
	;


	mov	bx,cx					;child handle
	xchg	si,dx					;child chunk, comp chunk
	call	ObjSwapLock
	call	ObjIncInUseCount
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	clr	ds:[di].VI_link.LP_next.handle
	clr	ds:[di].VI_link.LP_next.chunk
	call	ObjSwapUnlock
	xchg	dx,si					;child chunk, comp chunk

	mov	ax,MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock

	.leave
	Destroy	ax, bp
	ret

VisCompAddNonDiscardableVMChild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompRemoveNonDiscardableVMChild --

DESCRIPTION:	Remove a child object from a composite using MSG_VIS_REMOVE_CHILD
		and decrement the in use count of the child

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_REMOVE_NON_DISCARDABLE_VM_CHILD

	^lcx:dx  - object to remove

RETURN:
	cx, dx -- preserved
	ax, bp -- destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@
VisCompRemoveNonDiscardableVMChild	method dynamic VisCompClass, 
					MSG_VIS_REMOVE_NON_DISCARDABLE_VM_CHILD 
	.enter

	mov	bp,0					;flags
	mov	ax,MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock

	mov	bx,cx					;child handle
	mov	si,dx					;child chunk
	call	ObjSwapLock
	call	ObjDecInUseCount
	call	ObjSwapUnlock

	.leave
	Destroy	ax, bp
	ret

VisCompRemoveNonDiscardableVMChild	endm

VisOpenClose	ends
;
;-------------------
;
VisConstruct	segment resource
	

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompMoveVisChild -- MSG_VIS_MOVE_CHILD for VisCompClass

DESCRIPTION:	Move a child object in the composite, to reside in another
		location among its siblings

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_MOVE_CHILD

	cx:dx - child to move
	bp - flags for how to move child (CompChildFlags)

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


VisCompMoveVisChild	method	VisCompClass, MSG_VIS_MOVE_CHILD
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	GOTO	ObjCompMoveChild

VisCompMoveVisChild	endm

VisConstruct	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCompFindChild

DESCRIPTION:	Determine the position of a visible child of this object

CALLED BY:	EXTERNAL

PASS:
	*ds:si  - instance data of composite
	^lcx:dx - child

RETURN:
	carry set if not found
	bp - child position (0 = first child, -1 if not found)
	cx, dx, - preserved
	ax, destroyed
		
DESTROYED:	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


VisCompFindVisChild	method	VisCompClass, MSG_VIS_FIND_CHILD
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompFindChild
	jnc	10$			;child found, branch
	mov	bp, -1			;else signal not found
10$:
	Destroy	ax
	ret

VisCompFindVisChild	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCompGetChildAtPosition

DESCRIPTION:	Determine the position of a visible child of this object

CALLED BY:	EXTERNAL

PASS:
	*ds:si  - instance data of composite
	cx - position of child to look for

RETURN:
	carry set if not found
	^lcx:dx - child found, or null if none
	ax, bp destroyed
		
DESTROYED:	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


VisCompGetChildAtPosition method VisCompClass, MSG_VIS_FIND_CHILD_AT_POSITION
	mov	dx, cx
	clr	cx
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompFindChild
	jnc	10$			;child found, branch
	mov	cx, 0			;else clear cx and dx
	mov	dx, cx
10$:
	Destroy	ax, bp
	ret

VisCompGetChildAtPosition	endm

VisCommon	ends
;
;-------------------
;
VisOpenClose	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCompUpdateWindow

DESCRIPTION:	This is the generic equivalent of VisCompUpdateWinGroup.
	In the visible world, the VA_VISIBLE flag is set or cleared in order
	to bring a WIN_GROUP up or down.  In the generic world, the
	decision for visibility is a joint one, shared between the application,
	the generic UI, & the specific UI.  This routine arbeitrates between
	the three, checking state flags which are combined to determine
	the visible status of the WIN_GROUP.
	
	IMPORTANT:  THIS IS THE ONLY ROUTINE allowed to set or clear
	VA_VISIBLE for a generic WIN_GROUP object.  No other routine, be it
	generic UI, specific UI, or application process/subclassing of a
	gneric object, should attempt to do this.  Visible control of generic
	objects must be handled by changing USABLE, ATTACHED, REALIZABLE,
	& BRANCH_MINIZED attributes (See Spec/visual.doc)

PASS:
	*ds:si - instance data (offset through Vis_offset)

	cx - UpdateWindowFlags
	dl - VisUpdateMode

RETURN:
	ax, cx, dx, bp - destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	The following logic should be executed for any WIN_GROUP in
which the USABLE, ATTACHED, or REALIZABLE bit changes:

VisCompUpdateWindow(UpdateWindowFlags, VisUpdateMode) {
	if GS_USABLE & (all parents GS_USABLE) &
			VA_ATTACHED & VA_REALIZABLE
	{ 
	    SetGenWinGroupVisible
	} else {
	    SetGenWinGroupNotVisible
	}
}


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version

------------------------------------------------------------------------------@


VisCompUpdateWindow	method	VisCompClass, MSG_META_UPDATE_WINDOW

EC <	test	cx, not mask UpdateWindowFlags				>
EC <	ERROR_NZ	UI_BAD_UPDATE_WINDOW_FLAGS			>

	push	dx
	push	si
EC <	call	GenCheckGenAssumption					>
EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN			>
EC <	ERROR_Z	UI_EXPECTED_VIS_TYPE_VTF_IS_GEN				>
					; First, make sure we're in the
					; 	right place
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jz	Done			; if not, get out of here

					; Next, see if fully USABLE or not.
	call	VisGetGenBranchInfo
	test	ax, mask GBI_USABLE
	jnz	AfterUsable		; if so, continue with checks
					; otherwise, force clear REALIZABLE bit
					; & make not visible
	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
	and	ds:[di].VI_specAttrs, not mask SA_REALIZABLE
	jmp	short NotVisible

AfterUsable:

					; If not any of Usable, Realizable,
					; Attached, or IS Branch Minimized,
					; MAKE NOT VISIBLE.
	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance

					; See if ATTACHED
	test	ds:[di].VI_specAttrs, mask SA_ATTACHED
	jz	NotVisible
					; ax = GenBranchInfo
					; See if branch is minimized
	test	ax, mask GBI_BRANCH_MINIMIZED 
	jnz	NotVisible		; if so, then make not VISIBLE

					; If app is detaching, make not visible
;;	push	ax, dx
;	mov	ax, MSG_GEN_APPLICATION_GET_STATE
;	call	GenCallApplication
;;	call	QuickGenAppGetState
;;	mov	cl, al			; get result in cl
;;	pop	ax, dx			; VISIBLE
;;	jnc	continue		; If no reply, can't use this to
;;					; make not visible
;;
;;	test	cl, mask AS_DETACHING	; If detaching, branch to make
	test	cx, mask UWF_DETACHING
	jne	NotVisible		; not visible

;;continue:

					; If all of the above has been met,
					; AND the specific UI has marked the
					; object realizable, make VISIBLE.
	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
	test	ds:[di].VI_specAttrs, mask SA_REALIZABLE
	jnz	Visible

					; Before just making sure this non-
					; realized WIN_GROUP is not visible,
					; let's put in one last check to
					; see if this might be something like
					; a display wishing to have its menus
					; adopted even when it is not on 
					; screen
;	test	ds:[di].VI_specAttrs, mask SA_SPEC_BUILD_ALWAYS
;	jz	NotVisible		; If not, just make not visible

					; If this object IS one of these
					; special beasts, then we have to
					; make sure that it is specifically built
					; anyway.
;	push	ax,dx
;	call	EnsureGenWinGroupSpecBuilt
;	DoPop	ax,dx

NotVisible:
					; Call subroutine to get window in
					; not visible state.

					; AX still = VisGetGenBranchInfo flags.
	call	SetGenWinGroupNotVisible
	jmp	short Done

Visible:
	;
	; since we are updating this window, we need to make sure that our
	; parents are properly built.  This is necessary since some low-level
	; window may receive MSG_META_UPDATE_WINDOW before its parent does
	; (via the non-heirarichal nature of the GAGCNLT_WINDOWS list).
	;	cx = UpdateWindowFlags
	;	dl = VisUpdateMode
	;	ax = VisGetGenBranchInfo
	;
	push	ax			; save VisGetGenBranchInfo
	mov	ax, MSG_GEN_GUP_ENSURE_UPDATE_WINDOW
	call	GenCallParentEnsureStack ; preserves cx, dl
	pop	ax			; restore VisGetGenBranchInfo

					; Call subroutine to get window in
					; visible state.

					; AX still = VisGetGenBranchInfo flags.
	call	SetGenWinGroupVisible

Done:
	pop	si
	pop	dx
	Destroy	ax, cx, dx, bp
	ret

VisCompUpdateWindow	endm



; If app object run by same thread as current (common case), just nab what
; we're looking for right out of instance data.
;
QuickGenAppGetState	proc	near
	class	GenApplicationClass

	push	bx, si
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	noApp
	call	ObjTestIfObjBlockRunByCurThread
	jne	useMessage

	call	ObjSwapLock
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	ax, ds:[si].GAI_states
	call	ObjSwapUnlock
	stc				; got it!
done:
	pop	bx, si
	ret

noApp:
	clc
	jmp	short done

useMessage:
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	GenCallApplication
	jmp	short done

QuickGenAppGetState	endp

QuickGenAppGetStateFar	proc	far
	call	QuickGenAppGetState
	ret
QuickGenAppGetStateFar	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCompGenGupEnsureUpdateWindow

DESCRIPTION:	Handle window update.

PASS:
	*ds:si - instance data (offset through Vis_offset)

	cx - UpdateWindowFlags
	dl - VisUpdateMode

RETURN:
	carry set to stop gup (we've answered)
	cx, dl - unchanged
	ax, dh, bp - destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		Initial version

------------------------------------------------------------------------------@


VisCompGenGupEnsureUpdateWindow	method	VisCompClass,
					MSG_GEN_GUP_ENSURE_UPDATE_WINDOW

EC <	test	cx, not mask UpdateWindowFlags				>
EC <	ERROR_NZ	UI_BAD_UPDATE_WINDOW_FLAGS			>

	;
	; Since the UI law states that if we are VA_REALIZED then our parents
	; must be VA_REALIZED, we only need to do this if we are not
	; VA_REALIZED.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	done				; if we are realized, we're done

	;
	; first, ensure parent windows updated
	;
	call	GenCallParentEnsureStack

	;
	; then if detaching, just update ourselves (if detaching, no update
	; will be needed)
	;
	test	cx, mask UWF_DETACHING
	jnz	done				; detaching

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jz	done				; not win group, done

	;
	; now update the window
	;
	; by the time we get here, a subclass should have tested for and used
	; UWF_FROM_WINDOWS_LIST, so we can safely clear it (as we must before
	; sending out subsequent MSG_META_UPDATE_WINDOWs).  It will be set
	; again for the new GAGCNLT_WINDOWS object, as the
	; MSG_META_GCN_LIST_SEND in GenAppAttach sends the same data to each
	; GCN list item.
	;
	andnf	cx, not mask UWF_FROM_WINDOWS_LIST
	push	cx, dx
	mov	ax, MSG_META_UPDATE_WINDOW
	call	ObjCallInstanceNoLock
	pop	cx, dx

done:
	stc					; we've built up from ourselves,
						;	stop gup
	Destroy	ax, dh, bp
	ret

VisCompGenGupEnsureUpdateWindow	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetGenWinGroupNotVisible

DESCRIPTION:	Ensures that a generic WIN_GROUP is NOT VISIBLE, & removed
		from the screen.

CALLED BY:	VisCompUpdateWindow

PASS:
	*ds:si - instance data (offset through Vis_offset)

	ax	- VisGetGenBranchInfo flags.
	dl 	- VisUpdateMode

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

    if VA_VISIBLE {
	VA_VISIBLE = FALSE;
	MSG_VIS_VUP_UPDATE_WIN_GROUP (VUM_NOW);
	Unlink top visible object;
	Store old visible parent as upward-only link;
	Set the SA_TREE_BUILT_BUT_NOT_REALIZED;
	Decrement in-use count;
    }


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Broke out from VisCompUpdateWindow

------------------------------------------------------------------------------@

SetGenWinGroupNotVisible	proc	near
	class	VisClass
					; AX still = VisGetGenBranchInfo flags.

					; See if already not visible
	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jnz	ChangeToNotVisible
					; If already not visible, check for
					; whether USABLE
	test	ax, mask GBI_USABLE	; Is object USABLE?
	jnz	Done			; If so, then really done, we're just
					; happy that the window is already
					; not visible, & are not concerned
					; about visible linkage.

					; OTHERWISE, we need to visibly
					; unbuild this thing.  Pass
					; SpecBuildFlags of WIN_GROUP, & 
					; NOT_USABLE
	jmp	short	DoVisUnbuild	; if not visible, branch to handle

ChangeToNotVisible:
					; ELSE Mark as NOT visible
	and	ds:[di].VI_attrs, not mask VA_VISIBLE

					; & Bring the window down visually
					; If closing, OVERRIDE update mode
					; & DO IT NOW.  This will make things
					; a hell of a lot simpler to deal
					; with.
	push	ax
	mov	dl, VUM_NOW
;	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
;	call	ObjCallInstanceNoLock
	call	VisCompVupUpdateWinGroup	; call statically
	pop	ax

	test	ax, mask GBI_USABLE	; Is object totally USABLE?
	jnz	ConvertToOneWayLink	; if so, branch & convert to one-way
					; link, for quick reattach later.

DoVisUnbuild:
;	mov	bp, mask SBF_WIN_GROUP or mask SBF_NOT_USABLE
					; Passed here: bp = SpecBuildFlags to use
	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
					; See if WIN_GROUP was ever visually
					; built -- if linkage is zero, then
					; was never visually built.
	tst	ds:[di].VI_link.LP_next.handle
	je	Done			; if not built, then no need to Unbuild

; IS HANDLED ONLY BY VisSetNotUsable now
;					; Otherwise, visually unbuild the
;					; window & all children
;	mov	ax, MSG_SPEC_UNBUILD_BRANCH
;	call	ObjCallInstanceNoLock
	jmp	short Done		; & we're all done.

ConvertToOneWayLink:
	; Then, change visual link to parent from a direct visual
	; linkage, to just a one-way link.

	push	si

	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	pushf
	mov	cx, ds:[LMBH_handle]	; Get WIN_GROUP in ^lcx:dx
	mov	dx, si
	call	VisFindParent		; Get Vis parent in ^bx:si
EC <	tst	bx						>
EC <	ERROR_Z	UI_WIN_GROUP_HAS_NO_VIS_PARENT			>
	popf

	push	bx			; save vis parent
	push	si
				; If content object, skip REMOVE_VIS_CHILD
	jnz	AfterRemoved
					; Remove from visible parent
	clr	bp
	mov	ax, MSG_VIS_REMOVE_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
AfterRemoved:
	pop	dx			; Get old vis parent in ^lcx:dx
	pop	cx

	pop	si
					; Store a one-way upward link only
					; in its place
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VI_link.LP_next.handle, cx
	inc	dx
	mov	ds:[di].VI_link.LP_next.chunk, dx
					; & Set flag to indicate that we've
					; done this.  A glorious way to 
					; allow the thing to appear 
					; vis-built, & yet actually have
					; no dependencies between the WIN_GROUP
					; & its parent at this point.
	or	ds:[di].VI_specAttrs, mask SA_TREE_BUILT_BUT_NOT_REALIZED
Done:
	ret

SetGenWinGroupNotVisible	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	SetGenWinGroupVisible

DESCRIPTION:	Ensures that a generic WIN_GROUP is VISIBLE, & updated
		on screen.

CALLED BY:	VisCompUpdateWindow

PASS:
	*ds:si - instance data (offset through Vis_offset)

	ax	- VisGetGenBranchInfo flags.
	dl 	- VisUpdateMode

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

    if not VA_VISIBLE {
	Increment in-use count;
	VA_VISIBLE = TRUE;
	if SA_TREE_BUILT_BUT_NOT_REALIZED {
		Re-attach object to visible parent currently
			stored as upward-only link;
		clear SA_TREE_BUILT_BUT_NOT_REALIZED;
	} else {
		MSG_SPEC_BUILD_BRANCH (VisUpdateFlags);
	}
	MSG_VIS_VUP_UPDATE_WIN_GROUP (VisUpdateFlags);
    }

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Broke out from VisCompUpdateWindow

------------------------------------------------------------------------------@


SetGenWinGroupVisible	proc	near
	class	VisClass

	; First, make sure visible linkage is built out for this branch
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance

				; Check to see if visible
	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jnz	done		; Branch if already visible


				; Vis-Build out entire branch
	push	dx
	call	EnsureGenWinGroupSpecBuilt
	pop	dx		; Retrieve update flags

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
				; Mark as visible
	or	ds:[di].VI_attrs, mask VA_VISIBLE

	; Finally, update win group
	;
;	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
;	call	ObjCallInstanceNoLock
	call	VisCompVupUpdateWinGroup	; call statically
done:
	ret

SetGenWinGroupVisible	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureGenWinGroupSpecBuilt

DESCRIPTION:	Code snippet pulled out to save bytes -- visibily builds
		a WIN_GROUP object

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data (offset through Vis_offset)

	ax	- VisGetGenBranchInfo flags.

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if SA_TREE_BUILT_BUT_NOT_REALIZED {
		Re-attach object to visible parent currently
			stored as upward-only link;
		clear SA_TREE_BUILT_BUT_NOT_REALIZED;
	} else {
		MSG_SPEC_BUILD_BRANCH (VisUpdateFlags);
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Broke out from SetGenWinGroupVisible

------------------------------------------------------------------------------@


EnsureGenWinGroupSpecBuilt	proc	near
	class	VisCompClass
				; Else build out entire branch

	; See if this WIN_GROUP has already been specifically built, but was
	; just hanging out not realized...
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_specAttrs, mask SA_TREE_BUILT_BUT_NOT_REALIZED
				; if not, then branch & do real spec build.
	jz	RequiresUpdateSpecBuild
				; Clear the mask, as we will no longer
				; be built without a real visible linkage
	and	ds:[di].VI_specAttrs, not mask SA_TREE_BUILT_BUT_NOT_REALIZED

				; If this is a CONTENT object, then we
				; don't have to do anything more, since they
				; never have anything but an upward only
				; link anyway!
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jnz	AfterAdded

	push	si
	mov	cx, ds:[LMBH_handle]	; Put this object in ^lcx:dx
	mov	dx, si
					; & fetch our visible parent, currently
					; stored as a one-way visible link,
					; in ^lbx:si
	mov	bx, ds:[di].VI_link.LP_next.handle
	mov	si, ds:[di].VI_link.LP_next.chunk
					; Clear out the VI_link field, 
					; so that MSG_VIS_ADD_CHILD won't
					; be upset at us.
	clr	ax
	mov	ds:[di].VI_link.LP_next.handle, ax
	mov	ds:[di].VI_link.LP_next.chunk, ax
	dec	si
	mov	bp, CCO_FIRST		; add to front of visible list
	mov	ax, MSG_VIS_ADD_CHILD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
AfterAdded:
					; & then skip doing SPEC_BUILD, since
					; we know that our whole tree is
					; already VIS_BUILT. (YES!  This
					; will save a traversal of the tree
					; when bringing up menus successive
					; times :)
	jmp	short done

RequiresUpdateSpecBuild:

	; If WIN_GROUP already built out, done.
	;
	call	VisCheckIfSpecBuilt
	jc	done
				; Pass flag to indicate top window, vis building
				; from update win group routine, & updating now.
                                ; Pass flag to indicate top window, vis building
                                ; from update win group routine, & updating now.
        mov     bp, mask SBF_WIN_GROUP or mask SBF_IN_UPDATE_WIN_GROUP or \
                    VUM_NOW
	mov	cx, -1		; no optimizations -- do full check
        call    GenCheckIfFullyEnabled  ; see if we're fully enabled
        jnc     doBuild                 ; no, branch
        or      bp, mask SBF_VIS_PARENT_FULLY_ENABLED
doBuild:
        mov     ax, MSG_SPEC_BUILD_BRANCH
        call    ObjCallInstanceNoLock

done:
	ret

EnsureGenWinGroupSpecBuilt	endp





COMMENT @-----------------------------------------------------------------------

METHOD:		VisCompFinalObjFree

DESCRIPTION:	Intercept method normally handled at MetaClass to add
		behavior of freeing the chunks that a VisCompClass object
		references.
		Free chunk, hints & vis moniker, unless any of these chunks
		came from a resource, in which case we mark dirty & resize
		to zero.

PASS:	*ds:si	- object
	ax	- MSG_META_FINAL_OBJ_FREE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version

-------------------------------------------------------------------------------@

VisCompFinalObjFree	method VisCompClass, MSG_META_FINAL_OBJ_FREE

	mov	ax, TEMP_VIS_INVAL_REGION	;get chunk with inval region
	call	ObjVarFindData
	jnc	noReg				;nothing found, skip
	mov	ax, {word} ds:[bx]
	call	ObjFreeChunk

noReg:
				; Finish up w/nuking the object itself
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset VisCompClass
	GOTO	ObjCallSuperNoLock

VisCompFinalObjFree	endm


VisOpenClose ends

;------------

Ink segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCompMakePressesInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is a routine handler for subclasses of 
		VisCompClass, that want to make presses that are not on a
		child to be ink.

CALLED BY:	GLOBAL
PASS:		ax - MSG_META_QUERY_IF_PRESS_IS_INK
		cx, dx - press position
RETURN:		bp - as returned from VisCallChildUnderPoint
		(or 0 if no child under point)
		ax - InkReturnValue
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCompMakePressesInk	proc	far
	call	VisCallChildUnderPoint
	tst	ax
	jnz	exit
	mov	ax, IRV_DESIRES_INK
	clr	bp
exit:
	ret
VisCompMakePressesInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCompMakePressesNotInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is a routine handler for subclasses of 
		VisCompClass, that want to make presses that are not on a
		child be treated normally (not as ink).

CALLED BY:	GLOBAL
PASS:		ax - MSG_META_QUERY_IF_PRESS_IS_INK
		cx, dx - press position
RETURN:		bp - as returned from VisCallChildUnderPoint
		ax - InkReturnValue
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCompMakePressesNotInk	proc	far
	call	VisCallChildUnderPoint
	tst	ax
	jnz	exit
	mov	ax, IRV_NO_INK
exit:
	ret
VisCompMakePressesNotInk	endp

Ink	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompTakeGadgetExcl -- MSG_VIS_TAKE_GADGET_EXCL for VisClass

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_TAKE_GADGET_EXCL

	^lcx:dx	- object to be new active object (0:0 to force release
			of current owner.)

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
	Doug	4/89		Initial version
	Doug	8/18/89		Changed name from ActiveExcl to GadgetExcl,
				from just cx to cx:dx as object descriptor

------------------------------------------------------------------------------@

VisCompTakeGadgetExcl method dynamic VisCompClass, MSG_VIS_TAKE_GADGET_EXCL
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
					; If no change, then done.
	cmp	cx, ds:[di].VCI_gadgetExcl.handle
	jne	change
	cmp	dx, ds:[di].VCI_gadgetExcl.chunk
	je	done

change:	;get old owner of exclusive, and store new owner's OD

	xchg	cx, ds:[di].VCI_gadgetExcl.handle
	xchg	dx, ds:[di].VCI_gadgetExcl.chunk

	;If we aren't a WIN_GROUP, then propogate grab uphill

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jnz	VCTAE_50		;skip if is WIN_GROUP...

	;this object is not a WIN_GROUP. Propogate grab upwards: take
	;GADGET grab from parent.

	push	cx, dx
	mov	cx, ds:[LMBH_handle]
	mov	dx, si

	;If clearing exclusive, we must clear, too

	cmp	ds:[di].VCI_gadgetExcl.handle, 0
	jnz	VCTAE_20
	clr	cx
	clr	dx

VCTAE_20:
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParentEnsureStack
	pop	cx, dx

VCTAE_50:
	tst	cx			; if no old owner, can't send lost
	jz	done
					; setup bx:si to be last object
	mov	bx, cx
	mov	si, dx
					; Send old owner notification of
					; loss.
	mov	ax, MSG_VIS_LOST_GADGET_EXCL
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	Destroy	ax, cx, dx, bp
	ret
VisCompTakeGadgetExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompReleaseGadgetExcl -- MSG_VIS_RELEASE_GADGET_EXCL
						for VisClass

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_RELEASE_GADGET_EXCL

	^lcx:dx	- object which is requesting release of Gadget Exclusive.

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
	Eric	4/90		Initial version

------------------------------------------------------------------------------@

VisCompReleaseGadgetExcl	method	dynamic VisCompClass, \
						MSG_VIS_RELEASE_GADGET_EXCL
EC <	tst	cx							>
EC <	ERROR_Z UI_RELEASE_GADGET_EXCL_NO_OBJECT_PASSED			>
EC <	tst	dx							>
EC <	ERROR_Z UI_RELEASE_GADGET_EXCL_NO_OBJECT_PASSED			>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	cx, ds:[di].VCI_gadgetExcl.handle
	jne	done			;skip if requestor is not owner...
	cmp	dx, ds:[di].VCI_gadgetExcl.chunk
	jne	done			;skip if requestor is not owner...

	;take gadget exclusive from this object.

	clr	ds:[di].VCI_gadgetExcl.handle
	clr	ds:[di].VCI_gadgetExcl.chunk

	;If we aren't a WIN_GROUP, then propogate grab uphill

	push	si
	push	cx, dx

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jnz	VCTAE_50		;skip if is WIN_GROUP...

	;this object is not a WIN_GROUP. Propogate grab upwards: release
	;GADGET grab from parent.

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParentEnsureStack

VCTAE_50:
	pop	bx, si			;set ^lbx:si = requestor
					; Send old owner notification of
					; loss.
	mov	ax, MSG_VIS_LOST_GADGET_EXCL
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

done:
	Destroy	ax, cx, dx, bp
	ret
VisCompReleaseGadgetExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:	VisCompLostGadgetExcl -- MSG_VIS_LOST_GADGET_EXCL for VisClass

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_LOST_GADGET_EXCL

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@

VisCompLostGadgetExcl	method	dynamic VisCompClass, \
					MSG_VIS_LOST_GADGET_EXCL
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = VisInstance
						; If we aren't a WIN_GROUP, then
						; Propagate loss downward
	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jnz	done
	mov	bx, ds:[di].VCI_gadgetExcl.handle
	mov	si, ds:[di].VCI_gadgetExcl.chunk	; get active exclusive
	tst	bx	
	jz	done				; if none, done
	mov	ds:[di].VCI_gadgetExcl.handle, 0	; clear out exclusive
	mov	ds:[di].VCI_gadgetExcl.chunk, 0	; clear out exclusive

					; Send old owner notification of
					; loss.
	mov	ax, MSG_VIS_LOST_GADGET_EXCL
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

done:
	Destroy	ax, cx, dx, bp
	ret
VisCompLostGadgetExcl	endm

VisCommon	ends
;
;-------------------
;
VisOpenClose	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompVupUpdateWinGroup
	This method traverses up the visible object linkage until
	the window group head object is found.  At that point, it makes
	sure that there is a method send via the UI process to do the
	actual updating for this display.

CALLED STATICALLY BY:

PASS:
	*ds:si - instance data (offset through Vis_offset)
	ax - MSG_VIS_VUP_UPDATE_WIN_GROUP

	dl - VisUpdateMode	- how update should be done

RETURN:
	carry - set to indicate accomplished

DESTROYED:
	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

VisCompVupUpdateWinGroup method	static VisCompClass, \
					MSG_VIS_VUP_UPDATE_WIN_GROUP
	uses	bx, di
	.enter

	;
	; Special code to downgrade to VUM_MANUAL in VisContents in certain
	; situations (i.e. they're not ready to be opened.) -cbh 2/18/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_CONTENT
	jz	leaveUpdateModeAlone
	cmp	dl, VUM_NOW			;has VUM_NOW been passed?
	jne	leaveUpdateModeAlone		;no, branch
	call	VisContentGetVUM		;else possibly reset to manual

leaveUpdateModeAlone:

	tst	dl			; Just exit if VUM_MANUAL
	je	VCV_Done

EC <	test	dl, 0ffh AND (not mask SBF_UPDATE_MODE)			>
EC <	ERROR_NZ	UI_BAD_VIS_UPDATE_MODE				>

	;
	; If the object is not a WIN_GROUP, move up the tree until we find
	; it.
	;
	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance

	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP	
	jz	walkUpTreeAndCall

	cmp	dl, VUM_NOW		; If update NOW, branch to do so.
	jne	VCVUWG_later

	call	VisCompUpdateWinGroup	; Do it NOW.
	jmp	short VCV_Done

VCVUWG_later:
					; is an update already pending?
	test	ds:[di].VI_optFlags, mask VOF_UPDATE_PENDING
	jnz	VCV_Done			; if so, quit
					; Mark as pending now,
	or	ds:[di].VI_optFlags, mask VOF_UPDATE_PENDING

	; Force queue a message, via queue(s) indicated  (Changed 4/20/93 cbh
	; to queue another MSG_VIS_VUP_UPDATE_WIN_GROUP(VUM_NOW), so we can
	; recheck the VisContent constraints again before moving on.  Probably
	; we should have a special VisContentUpdateWinGroup instead having
	; special code here, but better not to mess with it now.)
	;
;	mov	ax, MSG_VIS_UPDATE_WIN_GROUP
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP

	mov	bx, ds:[LMBH_handle]	; Send to this object, ^lbx:si

					; See if app queue delay requested
	cmp	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	dl, VUM_NOW		; Use VUM_NOW next time (4/20/93 cbh)

	je	VCV_AppQueue		; if so, branch to do app delay

					; ELSE do UI queue delay by default
					; & send the method which will make
					;	it happen.
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	short VCV_Done

VCV_AppQueue:
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	dx, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_DISPATCH_EVENT
	push	si
	call	MemOwner		; bx <- owner
	clr	si
	mov	di, mask MF_FORCE_QUEUE	; force via queue
	call	ObjMessage
	pop	si
	jmp	short VCV_Done

walkUpTreeAndCall:
	; Otherwise call VisClass handler, which statically walks up tree,
	; finds the REAL WIN_GROUP object, & calls this message statically
	; on it.		-- Doug 5/12/92
	;
	call	VisVupUpdateWinGroup

VCV_Done:
 	Destroy	ax, cx, dx, bp
	.leave
	ret


VisCompVupUpdateWinGroup	endm


	

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompUpdateWinGroup -- MSG_VIS_UPDATE_WIN_GROUP for
	VisClass.  This method makes 
	as many passes down the visible tree as necessary, not crossing
	any object declared as its own window group, & updates visual linkage,
	window realization, position & size, & image integrity.

CALLED STATICALLY BY:
	VisCompVupUpdateWinGroup

PASS:
	*ds:si - instance data (offset through Vis_offset)
	ax - MSG_VIS_UPDATE_WIN_GROUP
	
RETURN:
	carry - set to indicate accomplished

DESTROYED:
	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


VisCompUpdateWinGroup	method static VisCompClass, MSG_VIS_UPDATE_WIN_GROUP
	uses	bx, di
	.enter

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	mov	di, ds:[si]					
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
					; Clear update pending flag
	and	ds:[di].VI_optFlags, not mask VOF_UPDATE_PENDING

EC <	; SEE if already updating (can't do nested updates)		>
EC <	test	ds:[di].VI_optFlags, mask VOF_UPDATING			>
EC <	; Set flag to show updating					>
EC <	ERROR_NZ	UI_NESTED_VISUAL_UPDATE				>
	or	ds:[di].VI_optFlags, mask VOF_UPDATING		

					; Check to see if should be visible
	test	ds:[di].VI_attrs, mask VA_VISIBLE
	jnz	displayable


;notDisplayable:
				; See if already unrealized
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	short done	; if so, we're done.

				; Else close all windows
	clr	bp		; Pass flag to indicate top window
	mov	ax, MSG_VIS_CLOSE
	call	ObjCallInstanceNoLock
	jmp	short done

displayable:

	; Make sure geometry is up to date and the object uses the
	; geometry manager to deal with the children.  Update the geometry
	; if necessary.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID or \
				     mask VOF_GEO_UPDATE_PATH
	jz	afterGeometry
	mov	ax, MSG_VIS_UPDATE_GEOMETRY
	call	ObjCallInstanceNoLock
afterGeometry:
				; See if realized yet
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	;ds:di = VisInstance

EC <	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID		>
EC <	ERROR_NZ	UI_VIS_UPDATE_GEOMETRY_FAILED			>

	test	ds:[di].VI_attrs, mask VA_REALIZED
	jnz	updateWinAndImages	; if realized, just doing
					; update, branch.

	clr	bp			; Pass null parent window, to indicate
					; starting here.
	mov	ax, MSG_VIS_OPEN	; OPEN all windows for branch
	call	ObjCallInstanceNoLock
					; Do NOT need to update imagery,
					; since we're opening new windows
	jmp	short done

updateWinAndImages:

	; Update any windows that have changed (or create new ones).
	; Invalidate any objects whose visual appearance is invalid.
	; (Can no longer make this optimization.  There may be an invalid
	;  region created by objects being removed, etc. that needs to be dealt
	;  with in this handler.  Could check for the presence of a TEMP_VIS_-
	;  INVAL_REGION hint, but that would probably not be worth the extra
	;  cost.  -5/ 5/92 cbh)
	;
;	mov	di, ds:[si]
;	add	di, ds:[di].Vis_offset	;ds:di = VisInstance
;	test	ds:[di].VI_optFlags, mask VOF_WINDOW_INVALID or \
;				     mask VOF_WINDOW_UPDATE_PATH or \
;				     mask VOF_IMAGE_INVALID or \
;				     mask VOF_IMAGE_UPDATE_PATH
;
;	jz	done
	clr	bp			;Pass null parent window, to indicate
					;starting here.
	clr	cl			;nothing's been invalidated yet
	mov	ax, MSG_VIS_UPDATE_WINDOWS_AND_IMAGE
	call	ObjCallInstanceNoLock

done:
	; Clear flag to show not updating				
	mov	di, ds:[si]						
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance		
	and	ds:[di].VI_optFlags, not mask VOF_UPDATING		

	stc			; return showing this method hit
	Destroy	ax, cx, dx, bp

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

VisCompUpdateWinGroup	endm


VisOpenClose	ends
;
;-------------------
;
VisUpdate	segment resource

	

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompMoveResizeWin -- MSG_VIS_MOVE_RESIZE_WIN for VisCompClass

DESCRIPTION:	DEFAULT routine to move/resize a window.  Calls WinResize
		to set window to be rectangular, with offset & size as
		specified by VI_bounds

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_VIS_MOVE_RESIZE_WIN

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
	Doug	3/89		Initial version
	Chris	4/91		Updated for new graphics, vis bounds conventions

------------------------------------------------------------------------------@


VisCompMoveResizeWin	method	dynamic VisCompClass, MSG_VIS_MOVE_RESIZE_WIN
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW		>
EC <	ERROR_Z	UI_CAN_NOT_WIN_RESIZE_NON_WINDOW			>
	mov	di, ds:[di].VCI_window	; get window handle
	or	di, di
	jz	VCMRW_90		; if no window, done

	clr	cl			; normal bounds
	call	VisGetBounds
	dec	cx			; use screen pixel bounds
	dec	dx

	mov	si,mask WPF_ABS		; resize absolute (i.e. move)
	push	si
	clr	si
	clr	bp
	call	WinResize
VCMRW_90:
	Destroy	ax, cx, dx, bp
	ret
VisCompMoveResizeWin	endm
			
VisUpdate	ends
;
;-------------------
;
VisCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompExposed -- MSG_META_EXPOSED for VisCompClass

DESCRIPTION:	HandleMem redrawing the exposed window

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_META_EXPOSED

	^hcx - window that was exposed

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

------------------------------------------------------------------------------@


VisCompExposed	method	dynamic VisCompClass, MSG_META_EXPOSED
	;
	; See if the window passed in matches our internally stored window.
	; If not, then we're getting a MSG_META_EXPOSED left over from before we
	; were closed, or possibly we're a content object that has been 
	; disconnected from our view.  In any case, we'll do nothing.
	; -cbh 12/5/91
	;
	cmp	cx, ds:[di].VCI_window		;see if this is our window
	jnz	done				;no, don't bother drawing
	
EC<	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW	>
EC<	jnz	VCE_40						>
EC<	ERROR	UI_EXPOSURE_OF_NON_WINDOW_OBJECT		>
EC<VCE_40:							>

				; Is object realized?
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	skipThisExposure	; If not, skip this exposure

	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jnz	performThisUpdate  ; IMAGE_INVALID only covers margins, can't
				   ;   do optimization below -cbh 12/17/91
				   
				   ; Is a fresh invalidation already pending for
				   ; this object?  
        test    ds:[di].VI_optFlags, (mask VOF_IMAGE_INVALID or \
                                      mask VOF_WINDOW_INVALID or \
				      mask VOF_GEOMETRY_INVALID)
	jz	performThisUpdate	; if not, go ahead & do update

				; Otherwise...
skipThisExposure:
	mov	di, cx		; Prevent Update Drawing, & lock-up of "EXPOSURE
				; PENDING", by acknowledging MSG_EXPOSE
	call	WinAckUpdate
	jmp	short done

performThisUpdate:
				; Create a GState, for this object
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

EC <	; Should not be possible for this not to be answered		>
EC <	ERROR_NC	VIS_MSG_VIS_VUP_CREATE_GSTATE_NOT_ANSWERED	>
				; returns GState handle in bp
	mov	di, bp		; get handle of graphics state in di
				; pass graphics state to use, to GrBeginUpdate
	call	GrBeginUpdate	; allow update of window area through it
	mov	bp, di		; pass graphics state handle in bp
	mov	cl, mask DF_EXPOSED	; pass the fact that we're updating
				; call draw method for object
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock
				; di, holding GState, is preserved
	call	GrEndUpdate	; done w/update
	call	GrDestroyState	; free up graphics state block

done:
	Destroy	ax, cx, dx, bp
	ret
VisCompExposed	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisCompExposedForPrint -- MSG_META_EXPOSED_FOR_PRINT for
							VisCompClass

DESCRIPTION:	HandleMem redrawing the exposed window

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisCompClass
	ax - MSG_META_EXPOSED_FOR_PRINT

	^hbp - gstring 

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

------------------------------------------------------------------------------@


VisCompExposedForPrint	method	dynamic VisCompClass, MSG_META_EXPOSED_FOR_PRINT

EC <	mov	di, ds:[si]					>
EC <	add	di, ds:[di].Vis_offset				>
EC<	test	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW	>
EC<	ERROR_Z	UI_EXPOSURE_OF_NON_WINDOW_OBJECT		>

	mov	ax, MSG_VIS_DRAW
	mov	cl, mask DF_EXPOSED or mask DF_PRINT
	GOTO	ObjCallInstanceNoLock

VisCompExposedForPrint	endm
	

COMMENT @----------------------------------------------------------------------

METHOD:		VisCompDraw -- MSG_VIS_DRAW for VisCompClass

DESCRIPTION:	Draws composite object if marked as drawable.  First
		the backdrop is drawn, and then the Children are
		sent a draw method if marked drawable.

PASS:
	*ds:si - instance data (offset through Vis_offset)
	ax - MSG_VIS_DRAW

	cl - DrawFlags	- DF_EXPOSED set if updating window, clear if just
		  	  drawing
	^hbp - GState to draw with

RETURN:
	carry -  set if operation complete, clear if updating, drawing not
		 complete, & will be sending MSG_VIS_DRAW_MORE to this object
		 when done.

DESTROYED:
	none (can be called via static binding)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


VCD_frame	struct
    VCD_theRect	Rectangle <>
VCD_frame	ends

VCD_vars	equ	<ss:[bp-(size VCD_frame)]>
VCD_rect	equ	<VCD_vars.VCD_theRect>

; Defined STATICALLY not for direct message calls, but rather so that
; OLCtrlClass can do a static CallSuper here & save the overhead of
; many, many message calls.		- Doug 
;
VisCompDraw	method	static VisCompClass, MSG_VIS_DRAW
	uses	bx, si, di, es
	.enter
		
	test	cl, mask DF_DONT_DRAW_CHILDREN
	jnz	VCD_done	; not drawing children, exit
	
	mov	di, ds:[si]	; get offset to composite in si
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
				; make sure composite is drawable
	test	ds:[di][VI_attrs], mask VA_DRAWABLE
	jz	VCD_done	; if it isn't, skip drawing altogether
	
	test	cl, mask DF_PRINT
	jnz	10$
				; make sure composite is realized
	test	ds:[di][VI_attrs], mask VA_REALIZED
	jz	VCD_done	; if it isn't, skip drawing altogether

	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jnz	10$		; IMAGE_INVALID only covers margins, must
				;   continue -cbh 12/17/91
	test	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID 
	jnz	VCD_done	; if not, skip drawing it

10$:
	; allocate frame on the stack to hold update bounds

	push	bp			;save gstate
	mov	di,bp			;di = gstate
	mov	bp,sp
	sub	sp, size VCD_frame

	push	cx
	call	GrGetMaskBounds
	mov	VCD_rect.R_left,ax
	mov	VCD_rect.R_top,bx
	mov	VCD_rect.R_right,cx
	mov	VCD_rect.R_bottom,dx
	pop	cx
	jc	VCD_noDraw		; if mask null then abort
	mov	dx,di			; pass gstate in dx


	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset VI_link	;pass offset to LinkPart
	push	bx
NOFXIP <	push	cs			;pass callback routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset VCD_callBack
	push	bx

	mov	di,offset VCI_comp
	mov	bx,offset Vis_offset
	mov	ax, MSG_VIS_DRAW
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack

VCD_noDraw:
	mov	sp,bp
	pop	bp			;gstate

VCD_done:
	stc				; for now, all done
	Destroy	ax, cx, dx, bp
	.leave
	ret

VisCompDraw	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	VCD_callBack

DESCRIPTION:	Call back routine supplied by VisCompDraw when
		calling ObjCompProcessChildren

CALLED BY:	ObjCompProcessChildren (as call-back)

PASS:
	*ds:si - child
	*es:di - composite
	cx - DrawFlag
	^hdx - gstate
	ss:bp - VCD_vars structure

RETURN:
	carry - set to end processing
	cx, dx, bp - data to send to next child

DESTROYED:
	ax, bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Steve	12/89		Changed bounds check to use signed comp
	Chris	4/91		Updated for new graphics, vis bounds conventions
	
------------------------------------------------------------------------------@

VCD_callBack	proc	far
	class	VisCompClass		; Tell Esp we're a friend of VisComp
					; so we can use its instance data.

	call	ShouldObjBeDrawn?	; see if object could use a redraw
	jnc	done			; no, exit
	
	; test the bounds

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_right
	cmp	ax, VCD_rect.R_right	; if obj.left > mask.right
	jg	done
	dec	bx			; use device's right edge
	cmp	bx, VCD_rect.R_left	; if obj.right < mask.left
	jl	done
	mov	ax, ds:[di].VI_bounds.R_top
	cmp	ax, VCD_rect.R_bottom	; if obj.top > mask.bottom
	jg	done
	mov	ax, ds:[di].VI_bounds.R_bottom
	dec	ax			; use device's right edge
	cmp	ax, VCD_rect.R_top	; if obj.bottom < mask.top
	jl	done

	push	cx			; preserve DrawFlags
	push	dx			; preserve GState handle
	push	bp
	mov	bp,dx			; pass gstate in bp
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLockES	; send DRAW
	pop	bp
	pop	dx
	pop	cx

done:
	clc
	ret

VCD_callBack	endp

VisCommon	ends

;
;---------------
;
		
Navigation	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisCompNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for VisCompClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		^lcx:dx	= object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		^lcx:dx	= replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking
		al	= NavigateCommonFlags
		ah - destroyed

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	VisCompClass handler:
	    Since we have received this method at this class level, we know
	    that if this object is subclassed by something in the specific UI,
	    it is something that is never focused, and so is excluded from
	    navigation (a GenInteraction which becomes an OLCtrlClass for
	    example). So all we need to do is forward this method to the
	    to first visible child, or next sibling (hints may affect
	    how next sibling is reached.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/90		initial version

------------------------------------------------------------------------------@
;SAVE BYTES: VisClass handler could return COMPOSITE flag by looking
;at VisTypeFlags (they line up... trust me!)

VisCompNavigate	method	dynamic VisCompClass, MSG_SPEC_NAVIGATION_QUERY
	;other ERROR CHECKING is in VisNavigateCommon

	;make sure that WIN_GROUP objects (root-level of the visible tree
	;in which navigation occurs) is handled by specific UI --
	;OLWinClass for example.

EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_WIN_GROUP		>
EC <	ERROR_NZ UI_NAVIGATION_QUERY_REACHED_WIN_GROUP			>

	;call utility routine, passing flags to indicate that this is
	;a composite node in visible tree, and that this object cannot
	;get the focus (although it may have siblings that do).
	;This routine will check the passed NavigationFlags and decide
	;what to respond.

	mov	bl, mask NCF_IS_COMPOSITE ;pass flags: is composite, is not
					  ;root node, not focusable.
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	Destroy	ah
	ret
VisCompNavigate	endm

		
Navigation	ends

;
;---------------
;
		
VisCommon	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		VisCompSendToChildren -- MSG_VIS_SEND_TO_CHILDREN

DESCRIPTION:	Call all children of a visual composite object

PASS:
	*ds:si - instance data
	es - segment of VisClass
	ax - MSG_VIS_SEND_TO_CHILDREN

	^hcx - classed event (freed by this handler)

RETURN:
	nothing

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Here's how to use this method:

	; passing registers only
	mov	ax, <methodToSendToChildren>
	mov	bx, <segmentOfClassForMethod>
	mov	si, <offsetOfClassForMethod>
	mov	cx, <dataToPassToChildInCX>
	mov	dx, <dataToPassToChildInDX>
	mov	bp, <dataToPassToChildInBP>
	mov	di, mask MF_RECORD
	call	ObjMessage		; returns event handle in di
	mov	cx, di			; cx = event handle
	mov	bx, <handleOfVisComposite>
	mov	si, <chunkOfVisComposite>
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	mov	di, <MessageFlags>
	call	ObjMessage

	; passing stack data
	<setup stack data>
	mov	ax, <methodToSendToChildren>
	mov	bx, <segmentOfClassForMethod>
	mov	si, <offsetOfClassForMethod>
	mov	cx, <dataToPassToChildInCX>
	mov	dx, <sizeOfStackData>
	mov	bp, <offsetToStackData>
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage		; returns event handle in di
	mov	cx, di			; cx = event handle
	mov	bx, <handleOfVisericComposite>
	mov	si, <chunkOfVisericComposite>
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	mov	di, <MessageFlags>	; MF_STACK not needed here!
	call	ObjMessage

	Note that since a classed event needs to be created, if using stack
	data, that data should not be too large.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@

VisCompSendToChildren	method	VisCompClass, MSG_VIS_SEND_TO_CHILDREN
	push	cx			; save event
	;
	; push ObjCompProcessChildren parameters
	;
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset VI_link	; Pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS		; use our callback routines
	push	bx
	mov	bx, offset VCSTC_callback
	push	bx

	mov	bx, cx
	push	si
	call	ObjGetMessageInfo	;Get stored "class" into dx:bp
	mov	dx, cx
	mov	bp, si
	pop	si
	mov	cx, bx			;Pass event in cx

			on_stack di bx bx bx bx cx retf
EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	;
	; after calling all the appropriate children, free the classed event
	;
	pop	bx			; restore classed event
	call	ObjFreeMessage
	ret
VisCompSendToChildren	endm

VCSTC_callback	proc	far
	mov	bx, cx			; bx = classed event
	push	es
	mov	es, dx
	mov	di, bp
	call	ObjIsObjectInClass	; is child of correct class?
	pop	es
	jnc	noSend			; nope, don't send to this child

	push	ax, cx, dx, bp		; save params for next child
	mov	cx, ds:[LMBH_handle]	; cx:si = this child
	call	MessageSetDestination	; Change destination of message to self
					; preserve event for next child
	mov	di, mask MF_CALL or mask MF_RECORD or \
			mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	MessageDispatch		; dispatch event to this child
	pop	ax, cx, dx, bp		; retreive params for next child

noSend:
	clc				; continue calling children
	ret
VCSTC_callback	endp

VisCommon ends
