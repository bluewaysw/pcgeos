COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Vis
FILE:		visContentClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VisContentClass		Top Visible object inside of a "view"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of visContent.asm

DESCRIPTION:
	This file contains routines to implement the VisContentClass.

	$Id: visContentClass.asm,v 1.1 97/04/07 11:44:34 newdeal Exp $

------------------------------------------------------------------------------@

;see documentation in /staff/pcgeos/Library/User/Doc/VisContent.doc

UserClassStructures	segment resource

; Declare the class record

	VisContentClass		mask CLASSF_DISCARD_ON_SAVE


; NOTE:  LOOK AT END OF THIS FILE FOR ADDITIONAL MESSAGE TABLE ENTRIES.
; Had to move them there because esp is complaining about the functions
; not being defined yet!  (They are defined lower in this file)

UserClassStructures	ends

;
; -----------
;

VisConstruct segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentInitialize -- MSG_META_INITIALIZE for VisContentClass

DESCRIPTION:	Initialize a VisContentClass object.  This does parent class
	initialization, followed by init of the Content part

PASS:
	*ds:si - instance data (offset through Vis_offset)
	es - segment of VisContentClass
	ax - MSG_META_INITIALIZE

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@


VisContentInitialize	method	dynamic VisContentClass, MSG_META_INITIALIZE
	;
	; First do parent class initialization
	;
	mov	di, offset UserClassStructures:VisContentClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]	; get pointer to instance data
	add	di, ds:[di].Vis_offset			;ds:di = VisInstance
				; Set opitimization flag to show as being
				; a content
	or	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or \
				      mask VTF_IS_WIN_GROUP or \
				      mask VTF_IS_CONTENT or \
				      mask VTF_IS_INPUT_NODE

 	; Under the new non-expand-to-fit rules, a content needs these bits
 	; to be able to expand to fill the view size.
 	or	ds:[di].VCI_geoDimensionAttrs, \
 				mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
 				mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT

	; Start w/Vertical alignment
	or	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY
	
	; Initialize implied grab flags
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VCNI_impliedMouseGrab.VMG_flags, mask VIFGF_MOUSE or \
			mask VIFGF_PTR
	ret

VisContentInitialize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSetView --
		MSG_META_CONTENT_SET_VIEW for VisContentClass

DESCRIPTION:	Sets the view OD for the content object.  Otherwise, we don't
		know what view we are the contents of.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_CONTENT_SET_VIEW
		cx:dx	- OD of View that this object sits under

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 5/89		Initial version

------------------------------------------------------------------------------@

VisContentSetView	method	dynamic VisContentClass, \
			MSG_META_CONTENT_SET_VIEW
						; Store away View we're being
						; used with
EC <	push	bx					>
EC <	push	si					>
EC <	mov	bx, cx					>
EC <	mov	si, dx					>
EC <	call	ECCheckLMemOD				>
EC <	pop	si					>
EC <	pop	bx					>

	mov	ds:[di].VCNI_view.handle, cx
	mov	ds:[di].VCNI_view.chunk, dx
	
	call	ViewUpdateContentTargetInfo	; Then, update view's targetInfo
	Destroy	ax, cx, dx, bp
	ret

VisContentSetView	endm



COMMENT @-----------------------------------------------------------------------

METHOD:		VisContentReloc

DESCRIPTION:	Deal with GCN lists, on unrelocate.

PASS:	*ds:si	- object

	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

	cx - handle of block containing relocation
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:
	carry - set if error
	bp - unchanged

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/18/92		Initial version

-------------------------------------------------------------------------------@

VisContentReloc	method VisContentClass, reloc
	cmp	ax, MSG_META_RELOCATE
	je	done			; nothing to do for relocate, our lists
					; aren't saved and if some other class
					; has lists that are saved, it must
					; handle this in its relocation handler
	;
	; Clear out focus and target here since nothing should have
	; focus/target when we shut down. - Joon (6/29/94)
	;
	clr	ax
	movdw	ds:[di].VCNI_focusExcl.FTVMC_OD, axax
	movdw	ds:[di].VCNI_targetExcl.FTVMC_OD, axax
	movdw	ds:[di].VCNI_view, axax

	;
	; unrelocate any GCN lists (will do all GCN lists stored in
	; TEMP_META_GCN even non-GAGCNLT types.  This is okay as other classes
	; that do this will check if it is necessary before unrelocating.)
	;
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData			; get ptr to TempGenAppGCNList
	jnc	done
	test	ds:[bx].TMGCND_flags, mask TMGCNF_RELOCATED
	jz	done				; already unrelocated
						; indicate unrelocated
	andnf	ds:[bx].TMGCND_flags, not mask TMGCNF_RELOCATED
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists
	mov	dx, ds:[LMBH_handle]
	call	GCNListUnRelocateBlock		; unrelocate all the lists we've
						;	been using
	jnc	done				; lists saved to state, leave
						;	var data element
	mov	ax, TEMP_META_GCN
	call	ObjVarDeleteData		; else, remove var data element
done:
	mov	di, offset VisContentClass
	call	ObjRelocOrUnRelocSuper
	ret
VisContentReloc	endm


COMMENT @-----------------------------------------------------------------------

METHOD:		VisContentFinalObjFree

DESCRIPTION:	Intercept message normally handled at MetaClass to add
		behavior of freeing the chunks that a VisContentClass object
		references.
		Free chunks unless any of these chunks came from a resource,
		in which case we mark dirty & resize to zero.

PASS:	*ds:si	- object
	ax	- MSG_META_FINAL_OBJ_FREE

RETURN:	nothing
	ax, cx, dx, bp - destroyed

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

-------------------------------------------------------------------------------@

VisContentFinalObjFree	method VisContentClass, MSG_META_FINAL_OBJ_FREE

    	push	ds:[di].VCNI_holdUpInputQueue
    	push	ds:[di].VCNI_postPassiveMouseGrabList
    	mov	ax, ds:[di].VCNI_prePassiveMouseGrabList

	tst	ax
	jz	afterPre
	call	ObjFreeChunk
afterPre:

	pop	ax
	tst	ax
	jz	afterPost
	call	ObjFreeChunk
afterPost:

	pop	bx
	tst	bx
	jz	afterHoldUpInputQueue
	call	GeodeFreeQueue
afterHoldUpInputQueue:

	mov	ax, MSG_META_FINAL_OBJ_FREE
	FALL_THRU	VisContentBlockFree

VisContentFinalObjFree	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisContentBlockFree -- MSG_META_BLOCK_FREE for VisContentClass

DESCRIPTION:	We our freeing the block that we are in -- nuke any
		associated GCN lists

PASS:
	*ds:si - instance data
	es - segment of VisContentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/ 5/93		Initial version

------------------------------------------------------------------------------@
VisContentBlockFree	method VisContentClass, MSG_META_BLOCK_FREE
	
	; Free GCN list of lists chunk, & list chunks, if in use here
	;
	push	ax
	mov	ax, MSG_META_GCN_LIST_DESTROY
	mov	di, offset VisContentClass
	call	ObjCallSuperNoLock
	pop	ax
	
				; Finish up w/nuking the object itself
	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock

VisContentBlockFree	endm


VisConstruct ends
VisUpdate	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentViewOpening
		MSG_META_CONTENT_VIEW_OPENING

DESCRIPTION:	View is opening. Setup an upward-only visible link to the
		content object, so that VUP queries get across the boundary,
		& make content visible by setting flags & updating.
		If object is generic, set REALIZABLE instead of VISIBLE


PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_CONTENT_VIEW_OPENING
		cx:dx	- OD of the view

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

VisContentViewOpening	method	dynamic VisContentClass, \
				MSG_META_CONTENT_VIEW_OPENING

EC <	tst	cx					>
EC <	ERROR_Z	UI_CX_DX_MUST_BE_VALID_VIEW_OBJECT	>
EC <	push	bx					>
EC <	push	si					>
EC <	mov	bx, cx					>
EC <	mov	si, dx					>
EC <	call	ECCheckLMemOD				>
EC <	pop	si					>
EC <	pop	bx					>

	; Update stored viewOD (In case this object is part of a VM file, which
	; may have been discarded & reloaded since the last MSG_META_CONTENT_SET_VIEW)
	;
	mov	ds:[di].VCNI_view.handle, cx
	mov	ds:[di].VCNI_view.chunk, dx

	;
	; Set visual upward-only link. DO NOT add as a visual child, just
	; set up a parent link only.
	;
	or	dx, 1				;make it a parent link!
	mov	ds:[di].VI_link.LP_next.handle, cx
	mov	ds:[di].VI_link.LP_next.chunk, dx

					; Is this a generic object?
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jnz	VCVO_OpenGeneric	; branch if so.
					; Make sure attr set for visibility
	mov	cl, mask VA_VISIBLE
	mov	ax, MSG_VIS_SET_ATTRS
	jmp	short VCVO_Update

VCVO_OpenGeneric:
					; Make sure attr set for realizing
					; Update the window, make sure it's
					;	up.  Do it NOW.
	mov	cl, mask SA_REALIZABLE
	mov	ax, MSG_SPEC_SET_ATTRS

VCVO_Update:
	clr	ch
	call	VisContentGetVUM
	GOTO	ObjCallInstanceNoLock

VisContentViewOpening	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentViewClosing
		MSG_META_CONTENT_VIEW_CLOSING

DESCRIPTION:	View is closing.  Make content objects not visible.
		If object is generic, clear REALIZABLE instead of VISIBLE.
		After content is no longer visible, null out the visible
		parent link, if it is not already nulled out.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_CONTENT_VIEW_CLOSING

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

VisContentViewClosing	method	dynamic VisContentClass, \
			MSG_META_CONTENT_VIEW_CLOSING
					; Is this a generic object?
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jnz	VCVC_CloseGeneric	; branch if so.

					; Make sure attr set for non visibility
	mov	ch, mask VA_VISIBLE
	mov	ax, MSG_VIS_SET_ATTRS
	jmp	short VCVC_Update

VCVC_CloseGeneric:
					; Make sure attr set for non visibility
					; Update the window, make sure it's
					;	up.  Do it NOW.
	mov	ch, mask SA_REALIZABLE
	mov	ax, MSG_SPEC_SET_ATTRS

VCVC_Update:
	clr	cl
	call	VisContentGetVUM
	call	ObjCallInstanceNoLock

					; NULL out visible one-way parent link
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Vis_offset	; ds:[di] -- VisInstance
	clr	ax
	mov	ds:[di].VI_link.LP_next.handle, ax
	mov	ds:[di].VI_link.LP_next.chunk, ax
	Destroy	ax, cx, dx, bp
	ret


VisContentViewClosing	endm

			


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentOpenWin --
		MSG_VIS_OPEN_WIN for VisContentClass

DESCRIPTION:	We "Open" a window by copying in the handle of the first
		port window we heard about opening.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_OPEN_WIN
		bp	- 0

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

VisContentOpenWin	method	dynamic VisContentClass, MSG_VIS_OPEN_WIN
	mov	ax, ds:[di].VCNI_window		; fetch window to use
EC <	tst	ax				; can't be NULL	gWin	>
EC <	ERROR_Z	UI_VIS_CONTENT_OPEN_WIN_WITH_NO_WIN			>
	mov	ds:[di].VCI_window, ax		; store window handle here

	; Invalidate the whole window, since we don't use WinOpen like
	; normal VisComp's, & can't count on the window automatically
	; getting invalidated.  Also covers case that MSG_META_EXPOSED has
	; already gone by us, before we were "opened"
	; (Moved to view, since an invalidation here following an invalidation
	;  in the old content's MSG_VIS_CLOSE_WIN caused a single MSG_META_EXPOSED
	;  to go to the *old* content, which was not good.  cbh 10/ 9/91)
	;
	; (Blah -- adding back in, in the hope that the problem was not
	;  having it here, but having this come before the exposureOD was 
	;  changed, which would have been fixed by FORCE_QUEUE.) -cbh 12/ 5/91
	;
	call	VisContentInvalidate

	; Set up this object, on opened window, as the implied grab
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCNI_window	; get window
	mov	ax, MSG_META_IMPLIED_WIN_CHANGE
	call	ObjCallInstanceNoLock

					; If large document model...
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL
	jz	doneWithImpliedGrab
					; request large mouse events for
					; implied grab
	or	ds:[di].VCNI_impliedMouseGrab.VMG_flags, mask VIFGF_LARGE
doneWithImpliedGrab:

	Destroy	ax, cx, dx, bp
	ret

VisContentOpenWin	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentWindowAboutToBeClosed

DESCRIPTION:	Stop deviant superclass behavior

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_WIN_ABOUT_TO_BE_CLOSED

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@

VisContentWindowAboutToBeClosed	method VisContentClass,
				MSG_VIS_WIN_ABOUT_TO_BE_CLOSED

	; Do nothing, other than to prevent the mischevious behavior of the
	; default handler -- this isn't really our window!  (Belongs to 
	; GenView).  Necessary to prevent application from moving Field window
	; off-screen when closing (ouch!)

	Destroy	ax, cx, dx, bp
	ret

VisContentWindowAboutToBeClosed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisContentVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler nukes the gadget exclusive (in case 
		anyone has it).

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisContentVisClose	method	VisContentClass, MSG_VIS_CLOSE
	mov	di, offset VisContentClass
	call	ObjCallSuperNoLock

				    	; Force release of any active element
				    	; within the view
	clr	cx
	clr	dx
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	GOTO	ObjCallInstanceNoLock
VisContentVisClose	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentCloseWin --
		MSG_VIS_CLOSE_WIN for VisContentClass

DESCRIPTION:	We "Close" a window by nuking the window handling in VCI_window

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_CLOSE_WIN
		^hbp	- view window
		cx, dx	- width, height of subview

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

VisContentCloseWin	method VisContentClass, MSG_VIS_CLOSE_WIN
	; Invalidate the whole window, since we don't use WinOpen like
	; normal VisComp's, & can't count on the window automatically
	; getting invalidated.  Also covers case that MSG_META_EXPOSED has
	; already gone by us, before we were "opened"
	; (Moved to view, since an invalidation here followed by an invalidation
	;  in the new content's MSG_VIS_OPEN_WIN caused a single MSG_META_EXPOSED
	;  to go to the *old* content, which was not good.  cbh 10/ 9/91)
	;
	; (Blah -- adding back in, in the hope that the problem was not
	;  having it here, but having this come before the exposureOD was 
	;  changed, which would have been fixed by FORCE_QUEUE.) -cbh 12/ 5/91
	;
	call	VisContentInvalidate

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VCI_window, 0		;NULL out window handle here

	; Then null out the implied grab, this object, since it no longer
	; has a window associated with it.
	;
	clr	cx
	clr	dx
	clr	bp
	mov	ax, MSG_META_IMPLIED_WIN_CHANGE
	GOTO	ObjCallInstanceNoLock

VisContentCloseWin	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentViewWinOpened

DESCRIPTION:	Sets the window for a content object.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_CONTENT_VIEW_WIN_OPENED

		bp	- gwin
		cx, dx	- width, height of subview

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      		This will not work until WinOpen unmapped is written!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

VisContentViewWinOpened	method	dynamic VisContentClass, \
					MSG_META_CONTENT_VIEW_WIN_OPENED
						; STORE HERE FOR ACCESS LATER
	mov	ds:[di].VCNI_window, bp		;set the current window

	mov	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
	GOTO	ObjCallInstanceNoLock		;set the document size now

VisContentViewWinOpened	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentViewWinClosed

DESCRIPTION:	Sent out by the view when the view is destroyed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_WIN_CLOSED
		^hbp	- view window 

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
	Chris	7/24/91		Initial version

------------------------------------------------------------------------------@

VisContentViewWinClosed	method dynamic	VisContentClass, \
				MSG_META_CONTENT_VIEW_WIN_CLOSED
	clr	ds:[di].VCNI_window
	Destroy	ax, cx, dx, bp
	ret
VisContentViewWinClosed	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSubviewSizeChanged
		MSG_META_CONTENT_VIEW_SIZE_CHANGED

DESCRIPTION:	Subview's size has changed.  Do visual update.
		Also send the document size up to the view.
		In the Large Document model, send this message to
		all visible children (layers).

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_SIZE_CHANGED
		cx, dx  - size of window the content is in

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version

------------------------------------------------------------------------------@

VisContentSubviewSizeChanged	method	dynamic VisContentClass, \
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

	push	cx, dx
					
	; Let's see if the subview size is different from the one currently
	; stored.  If it is, we'll invalidate its geometry.
	;
	cmp	ds:[di].VCNI_viewHeight, dx	;see if same height
	jne	invalGeo			;nope, go invalidate
	cmp	ds:[di].VCNI_viewWidth, cx	;see if same width
	je	storeViewSize			;yes, skip invalidation

invalGeo:
	push	cx, dx
	mov	cl, mask VOF_GEOMETRY_INVALID	;else set the geometry invalid
	mov	dl, VUM_MANUAL			;we'll update below
	call	VisMarkInvalid
	DoPop	dx, cx
	
storeViewSize:
	mov	ds:[di].VCNI_viewHeight, dx	;save new window dimensions
	mov	ds:[di].VCNI_viewWidth, cx
	
	;
	; Send size to children no matter what.  Makes life easier.
	;
	pop	cx, dx				;restore view size
	mov	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
	call	VisSendToChildren

	;
	; Update this content visually
	;
	call	VisContentGetVUM
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	call	ObjCallInstanceNoLock

	call	SetViewDocBounds		;set document size in the view
	Destroy	ax, cx, dx, bp 
	ret

VisContentSubviewSizeChanged	endm



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetViewDocBounds

SYNOPSIS:	Sets simple doc bounds in the content's view.  Will not do
		anything if running a large document, since the content's
		instance data isn't used.

CALLED BY:	VisContentSubviewSizeChanged, VisContentUpdateGeometry

PASS:		*ds:si -- content

RETURN:		nothing (ds fixed up properly)

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/91		Initial version

------------------------------------------------------------------------------@

SetViewDocBounds	proc	far		uses	si
	class	VisContentClass
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL or \
				    mask VCNA_VIEW_DOC_BOUNDS_SET_MANUALLY
	jnz	exit					
	call	VisGetBounds				;get content's bounds
	mov	di, ds:[si]				;point to instance
	add	di, ds:[di].Vis_offset			;ds:[di] -- SpecInstance
	mov	si, ds:[di].VCNI_view.chunk
	tst	si					;no window, get out
	jz	exit
	mov	di, ds:[di].VCNI_view.handle

	sub	sp, size RectDWord			;set up parameters
	mov	bp, sp
	push	di					;save view handle

	mov	di, offset RD_left
	call	SetViewBound

	mov	di, offset RD_top
	mov	ax, bx
	call	SetViewBound

	mov	di, offset RD_right
	mov	ax, cx
	call	SetViewBound

	mov	di, offset RD_bottom
	mov	ax, dx
	call	SetViewBound
	
	mov	dx, size RectDWord
	pop	bx					;view handle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS	;set new document size
	call	ObjMessage
	add	sp, size RectDWord

exit:
	.leave
	ret
SetViewDocBounds	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetViewBound

SYNOPSIS:	Sets a view bound, sign extending if needed.

CALLED BY:	SetViewDocBounds

PASS:		ss:[bp] -- RectDWord
		di -- offset to bound to set (RD_left, etc)
		ax -- value to set

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/19/93       	Initial version

------------------------------------------------------------------------------@

SetViewBound	proc	near		uses	bp
	.enter
	add	bp, di
	mov	({dword} ss:[bp]).low, ax
	tst	ax
	mov	ax, 0
	jns	10$
	dec	ax
10$:
	mov	({dword} ss:[bp]).high, ax
	.leave
	ret
SetViewBound	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentDoNothing

DESCRIPTION:	
		Does precisely nothing.  Allows class to "eat"
	certain methods coming through, to prevent them from going
	to our superclass, the VisCompClass.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_OPEN_WIN, MSG_VIS_MOVE_RESIZE_WIN

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

VisContentDoNothing	proc	far
	class	VisContentClass	; Function is friend of VisContentClass
	Destroy	ax, cx, dx, bp
	ret

VisContentDoNothing	endp




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentPositionBranch -- 
		MSG_VIS_POSITION_BRANCH for VisContentClass

DESCRIPTION:	Positions the branch.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_POSITION_BRANCH
		cx, dx 	- position arguments

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
	chris	6/21/93         Initial Version

------------------------------------------------------------------------------@

VisContentPositionBranch	method dynamic	VisContentClass, \
				MSG_VIS_POSITION_BRANCH
	;
	; This position is probably coming from the view.  If VOF_GEOMETRY_-
	; INVALID is set, it's probably not ready for positioning, so we'll
	; ignore the message.  We'll also avoid doing anything if update-pending
	; is set.  This means some object below the content has been marked
	; invalid, and will get updated.  (I could check VOF_GEO_UPDATE_PATH,
	; but I feel more comfortable with VOF_UPDATE_PENDING for now.)
	;

	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID or \
				     mask VOF_UPDATE_PENDING
	jnz	exit
	
	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock
exit:
	ret
VisContentPositionBranch	endm


	

COMMENT @----------------------------------------------------------------------

METHOD:		VisContentGetWinSize -- 
		MSG_VIS_CONTENT_GET_WIN_SIZE for VisContentClass

DESCRIPTION:	Returns size of content's window.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_CONTENT_GET_WIN_SIZE

RETURN:		cx, dx	- size of content's window
		ax, bp  - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/18/90	Initial version

------------------------------------------------------------------------------@

VisContentGetWinSize	method VisContentClass, MSG_VIS_CONTENT_GET_WIN_SIZE
	mov	cx, ds:[di].VCNI_viewWidth	;width of window
	mov	dx, ds:[di].VCNI_viewHeight	;height of window
	Destroy	ax, bp
	ret
VisContentGetWinSize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentUpdateGeometry -- 
		MSG_VIS_UPDATE_GEOMETRY for VisContentClass

DESCRIPTION:	Handles geometry updates.   Deals with objects inside the
		content object changing their size.  Does port stuff to 
		calculate its size, then positions the children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_UPDATE_GEOMETRY

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/16/89	Initial version

------------------------------------------------------------------------------@

VisContentUpdateGeometry	method	dynamic VisContentClass, \
						MSG_VIS_UPDATE_GEOMETRY
	call	VisGetSize			;get current size of content
	;
	; Check each dimension currently stored in the object.  We'll store 
	; the size of the view if the view isn't scrollable in that direction, 
	; since the content shouldn't be larger than the view.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	
	mov	dx, mask RSA_CHOOSE_OWN_SIZE	;assume vertically scrollable
	test	ds:[di].VCNI_attrs, mask VCNA_SAME_HEIGHT_AS_VIEW
	jz	10$				;not following subview height
	mov	dx, ds:[di].VCNI_viewHeight	;else use the subview height
10$:
	mov	cx, mask RSA_CHOOSE_OWN_SIZE	;assume horizontally scrollable
	test	ds:[di].VCNI_attrs, mask VCNA_SAME_WIDTH_AS_VIEW
	jz	20$				;not following subview width
	mov	cx, ds:[di].VCNI_viewWidth	;else use the subview width
20$:
EC <	call	StartGeometry			;for showcalls -g	>
	call	VisRecalcSizeAndInvalIfNeeded	;calc a size for this thing
EC <	call	EndGeometry			;for showcalls -g	>
	call	VisSetSize			;(should be subclassed!)
	
	call	SetViewDocBounds		;set doc size of the view

;	
;	Changed to keep whatever the current bounds are, to allow setting of
;	the content origin in a .ini file.   -cbh 2/19/93
;
;	clr	cx				;position at origin
;	clr	dx
;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VI_bounds.R_left
	mov	dx, ds:[di].VI_bounds.R_top
	call	VisSendPositionAndInvalIfNeeded
	Destroy	ax, cx, dx, bp
	ret
	
VisContentUpdateGeometry	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentScaleFactorChanged

DESCRIPTION:	Handles notification of scale factor changing
		storing the new location into instance data for later use

PASS:		*ds:si 	- instance data
		ds:di	- ptr to VisContentInstance
		es     	- segment of VisContentClass
		ax 	- MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
		ss:bp	- ptr to ScaleChangedParams
		dx	- size ScaleChangedParams

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version, required for 32-bit contents
	CDB	11/91		Added functionality for large doc model

------------------------------------------------------------------------------@

VisContentScaleFactorChanged	method	dynamic VisContentClass, \
				MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED

	push	ax,bp					; msg, stack frame
	mov	cx, (size PointWWFixed/2)		; structure to copy
copyLoop:
							; copy word
	mov	ax, word ptr ss:[bp].SCP_scaleFactor	; from stack
	mov	word ptr ds:[di].VCNI_scaleFactor, ax	; to instance data

	inc	bp					; inc ptrs
	inc	bp
	inc	di
	inc	di
	loop	copyLoop				; until done

	pop	ax,bp					; msg, stack frame

	; Call layers if large document
	;
	call	VisContentSendToLargeDocumentLayers

	; bp, di - destroyed

	Destroy	ax, cx, dx, bp
	ret

VisContentScaleFactorChanged	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSetDocBounds

DESCRIPTION:	Update all interested objects of a doc-bounds change

PASS:		*ds:si	= VisContentClass object
		ds:di - VisContent instance data
		es	= Segment of VisContentClass.
		ax 	= MSG_VIS_CONTENT_SET_DOC_BOUNDS

    	    	ss:bp	= RectDWord: new document bounds

RETURN:		nothing
	
DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/18/91	Initial version.

-----------------------------------------------------------------------------@

VisContentSetDocBounds	method	dynamic VisContentClass, 
					MSG_VIS_CONTENT_SET_DOC_BOUNDS
	.enter

	; Crash if not large-document model
	;

EC <	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL >
EC <	ERROR_Z	UI_LARGE_DOCUMENT_FLAG_NOT_SET			   >

	; Send message to the View
	;
	push	si				; save obj chunk handle
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
	mov	si, ds:[di].VCNI_view.chunk
	tst	si
	jz	afterView
	mov	bx, ds:[di].VCNI_view.handle
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	push	bp				; ss:bp - RectDWord
	call	ObjMessage
	pop	bp

afterView:
	
	; Now, send to all vis children
	;
	pop	si				; my chunk handle
	mov	ax, MSG_VIS_LAYER_SET_DOC_BOUNDS
	call	VisSendToChildren

EC <	Destroy	ax, cx, dx, bp				>	

	.leave
	ret
VisContentSetDocBounds	endm

					


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentAddRectToUpdateRegion -- 
		MSG_VIS_ADD_RECT_TO_UPDATE_REGION for VisContentClass

DESCRIPTION:	Adds an invalidation rect to the update region.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_ADD_RECT_TO_UPDATE_REGION
		ss:bp	- Rectangle: old bounds
		cl	- VisAddRectParams

RETURN:		nothing
		ax, cx, dx, bp - destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/16/91		Initial Version

------------------------------------------------------------------------------@

VisContentAddRectToUpdateRegion	method static VisContentClass, \
				MSG_VIS_ADD_RECT_TO_UPDATE_REGION

	uses	es, di, bx		; to conform to static reqmts
	.enter
	test	ss:[bp].VARP_flags, mask VARF_ONLY_REDRAW_MARGINS
	jz	callSuper		; not ourselves, call superclass

	test	ds:[di].VCI_geoAttrs, mask VCGA_ONLY_DRAWS_IN_MARGINS
	jz	callSuper		; optimization not set, don't bother
					;   minimizing the invalidation.
	
	;
	; Inval the areas to the right and bottom of the content, if any of it
	; is visible.  Avoid recursive calls to this handler by clearing 
	; VARF_ONLY_REDRAW_MARGINS.
	;
	push	ax				;save message
	and	ss:[bp].VARP_flags, not mask VARF_ONLY_REDRAW_MARGINS
	
	call	VisQueryWindow
	tst	di
	jz	20$				;no window, give up on this

	; NOTE:  I changed this when WinGetWinBounds went away.  You might want
	; 	 to optimize this if you have a GState handy   -jim  3/23/92

;	call	WinGetWinBounds			; ax, bx, cx, dx = bounds

	call	GrCreateState
	call	GrGetWinBounds
	call	GrDestroyState
	;
	; end of change

	push	ax				;save left edge
	mov	ax, ss:[bp].VARP_bounds.R_right	;use left edge of invalid bounds
	cmp	ax, cx				;anything to do?
	jge	10$				;no, branch
	mov	di, {word} ss:[bp].VARP_flags
	call	VisInvalOldBounds
10$:
	pop	ax				;restore win left
	mov	bx, ss:[bp].VARP_bounds.R_bottom ;top edge of invalid bounds
	cmp	bx, dx				;anything to do?
	jge	20$				;no, branch
	mov	di, {word} ss:[bp].VARP_flags
	call	VisInvalOldBounds
20$:	
	;
	; Restore this flag (we know it was set before).
	;
	or	ss:[bp].VARP_flags, mask VARF_ONLY_REDRAW_MARGINS
	pop	ax				;restore message
	
callSuper:
	mov	di, segment VisContentClass
	mov	es, di
	mov	di, offset VisContentClass
	CallSuper	MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	.leave
	ret
	
VisContentAddRectToUpdateRegion	endm

VisUpdate ends
VisUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentVupAllowGlobalTransfer --
		MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER for VisContentClass

DESCRIPTION:	Send GEN_VIEW_ALLOW_GLOBAL_TRANSFER to associated GenView.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version

------------------------------------------------------------------------------@

VisContentVupAllowGlobalTransfer	method	VisContentClass, \
				MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	mov	bx, ds:[di].VCNI_view.handle
	mov	si, ds:[di].VCNI_view.chunk	;get generic view OD
	tst	si				;no view, get out
	jz	exit
	
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	Destroy	ax, cx, dx, bp 
	ret

VisContentVupAllowGlobalTransfer	endm

					


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentGetAttrs -- 
		MSG_VIS_CONTENT_GET_ATTRS for VisContentClass

DESCRIPTION:	Returns content attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_CONTENT_GET_ATTRS

RETURN:		cl 	- content attributes
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

VisContentGetAttrs	method dynamic	VisContentClass, \
				MSG_VIS_CONTENT_GET_ATTRS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].VCNI_attrs
	ret
VisContentGetAttrs	endm
			
			

COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSetAttrs -- 
		MSG_VIS_CONTENT_SET_ATTRS for VisContentClass

DESCRIPTION:	Sets content attributes.  It is up to the caller to mark
		things invalid if they wish to get immediate visual effects
		of this change.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_CONTENT_SET_ATTRS
		
		cl	- content attributes to set
		ch	- content attributes to clear

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

VisContentSetAttrs	method dynamic	VisContentClass, \
				MSG_VIS_CONTENT_SET_ATTRS
	or	ds:[di].VCNI_attrs, cl
	not	ch
	and	ds:[di].VCNI_attrs, ch
	ret
VisContentSetAttrs	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentUnwantedKbdEvent

DESCRIPTION:	Handler for Kbd event with no destination, i.e. no kbd grab
		has been set up.  Default behavior here is to FUP the
		character.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_CONTENT_UNWANTED_KBD_EVENT
		cx, dx, bp	- same as MSG_META_KBD_CHAR

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@

VisContentUnwantedKbdEvent	method	VisContentClass,
				MSG_VIS_CONTENT_UNWANTED_KBD_EVENT

	mov	ax, MSG_META_FUP_KBD_CHAR
	GOTO	ObjCallInstanceNoLock	

VisContentUnwantedKbdEvent	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of VisContentClass
	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- TargetLevel

RETURN:
	cx:dx	- OD of target at level requested (0 if none)
	ax:bp	- Class of target object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

VisContentGetTargetAtTargetLevel	method	VisContentClass,
					MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	ax, TL_CONTENT
	mov	bx, Vis_offset
	mov	di, offset VCNI_targetExcl
	call	FlowGetTargetAtTargetLevel
	ret
VisContentGetTargetAtTargetLevel	endm


VisUncommon	ends
;
;-------------------
;
JustECCode	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentEnsureHandleNotReferenced

DESCRIPTION:	

 	An EC message which may be called for object blocks that are about
to be destroyed & should therefore already have released any grabs they mayh
have set up earlier in life.  This includes references that are normally
cleared as part of queue-flushing before destroying a block, such as the
implied grab.

	Note that if a block has already been freed, this routine should NOT
be called passing the block's handle, since it is possible for the handle to
have already been re-used legitimately.   In that case, cx should be passed as
zero, to do basic EC checking.

	Normally called from MSG_META_BLOCK_FREE interception here in VisClass.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED
	Pass:	cx	- handle to check, or zero to only check validity
			  of all block handles

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
	Doug	6/91		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK
VisContentEnsureHandleNotReferenced	method	VisContentClass, \
			MSG_VIS_VUP_EC_ENSURE_OBJ_BLOCK_NOT_REFERENCED
	tst	cx
	jz	makeSureGrabsValid

    	cmp	ds:[di].VCNI_activeMouseGrab.VMG_object.handle, cx
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_DYING_OBJECT

    	cmp	ds:[di].VCNI_impliedMouseGrab.VMG_object.handle, cx
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_DYING_OBJECT

        cmp	ds:[di].VCNI_kbdGrab.KG_OD.handle, cx
	ERROR_Z	FLOW_KBD_GRAB_NOT_RELEASED_BY_DYING_OBJECT

	; Check passive grabs
	;
    	mov	bx, offset VCNI_prePassiveMouseGrabList
	call	EnsureHandleNotOnPassiveList

    	mov	bx, offset VCNI_postPassiveMouseGrabList
	call	EnsureHandleNotOnPassiveList

makeSureGrabsValid:

	; Check to make sure all grabs are valid
	;
	call	EnsureGrabsValid

	call	SendToVisParent
	Destroy	ax, cx, dx, bp
	ret

VisContentEnsureHandleNotReferenced	endm

EnsureHandleNotOnPassiveList	proc	near
	class	VisContentClass
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	si, ds:[di][bx]
	tst	si
	jz	done
	mov	bx, cs
	mov	di, offset EnsureHandleNotOnPassiveListCallBack
	call	ChunkArrayEnum
done:
	.leave
	ret

EnsureHandleNotOnPassiveList	endp

EnsureHandleNotOnPassiveListCallBack	proc	far
	class	VisContentClass
	cmp	cx, ds:[di].VMG_object.handle
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_DYING_OBJECT
	clc			; Look through all
	ret

EnsureHandleNotOnPassiveListCallBack	endp

endif




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentEnsureODNotReferenced

DESCRIPTION:	

 	An EC method which is used to make sure the od passed is not
referenced anywhere in the IsoContent.  This includes references that
are normally cleared as part of queue-flushing before destroying an 
object.

	Normally called from MSG_META_FINAL_OBJ_FREE interception in VisClass.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED
	Pass:	cx:dx	- OD to check

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK
VisContentEnsureODNotReferenced	method	VisContentClass, \
				MSG_VIS_VUP_EC_ENSURE_OD_NOT_REFERENCED

	tst	cx
	jz	makeSureGrabsValid

	; Check active, implied & kbd grabs
	;
    	cmp	ds:[di].VCNI_activeMouseGrab.VMG_object.handle, cx
	jne	10$
    	cmp	ds:[di].VCNI_activeMouseGrab.VMG_object.chunk, dx
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_DYING_OBJECT
10$:
    	cmp	ds:[di].VCNI_impliedMouseGrab.VMG_object.handle, cx
	jne	20$
    	cmp	ds:[di].VCNI_impliedMouseGrab.VMG_object.chunk, dx
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_DYING_OBJECT
20$:

        cmp	ds:[di].VCNI_kbdGrab.KG_OD.handle, cx
	jne	30$
        cmp	ds:[di].VCNI_kbdGrab.KG_OD.chunk, dx
	ERROR_Z	FLOW_KBD_GRAB_NOT_RELEASED_BY_DYING_OBJECT
30$:

	; Check passive grabs
	;
    	mov	bx, offset VCNI_prePassiveMouseGrabList
	call	EnsureODNotOnPassiveList

    	mov	bx, offset VCNI_postPassiveMouseGrabList
	call	EnsureODNotOnPassiveList

makeSureGrabsValid:
	; Check to make sure all grabs are valid
	;
	call	EnsureGrabsValid

	call	SendToVisParent
	ret

VisContentEnsureODNotReferenced	endm

EnsureODNotOnPassiveList	proc	near
	class	VisContentClass
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	si, ds:[di][bx]
	tst	si
	jz	done
	mov	bx, cs
	mov	di, offset EnsureODNotOnPassiveListCallBack
	call	ChunkArrayEnum
done:
	.leave
	ret

EnsureODNotOnPassiveList	endp

EnsureODNotOnPassiveListCallBack	proc	far
	class	VisContentClass
	cmp	cx, ds:[di].VMG_object.handle
	jne	done
	cmp	dx, ds:[di].VMG_object.chunk
	jne	done
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_DYING_OBJECT
done:
	clc			; Look through all
	ret

EnsureODNotOnPassiveListCallBack	endp


endif




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentEnsureWinNotReferenced

DESCRIPTION:	
;
; 	An EC message which is used to make sure the win passed is not
; referenced anywhere in the flow object
;

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_VIS_VUP_EC_ENSURE_WINDOW_NOT_REFERENCED
	Pass:	cx	- window handle to check for

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK
VisContentEnsureWinNotReferenced	method	VisContentClass, \
			MSG_VIS_VUP_EC_ENSURE_WINDOW_NOT_REFERENCED

	tst	cx
	jz	makeSureGrabsValid

    	cmp	ds:[di].VCNI_activeMouseGrab.VMG_gWin, cx
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_OBJECT_IN_CLOSED_WINDOW

    	cmp	ds:[di].VCNI_impliedMouseGrab.VMG_gWin, cx
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_OBJECT_IN_CLOSED_WINDOW

	; Check passive grabs
	;
    	mov	bx, offset VCNI_prePassiveMouseGrabList
	call	EnsureWinNotOnPassiveList

    	mov	bx, offset VCNI_postPassiveMouseGrabList
	call	EnsureWinNotOnPassiveList

makeSureGrabsValid:

	; Check to make sure all grabs are valid
	;
	call	EnsureGrabsValid

	call	SendToVisParent
	ret

VisContentEnsureWinNotReferenced	endm


EnsureWinNotOnPassiveList	proc	far
	class	VisContentClass
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	si, ds:[di][bx]
	tst	si
	jz	done
	mov	bx, cs
	mov	di, offset EnsureWinNotOnPassiveListCallBack
	call	ChunkArrayEnum
done:
	.leave
	ret

EnsureWinNotOnPassiveList	endp

EnsureWinNotOnPassiveListCallBack	proc	far
	class	VisContentClass
	cmp	cx, ds:[di].VMG_gWin
	ERROR_Z	FLOW_MOUSE_GRAB_NOT_RELEASED_BY_OBJECT_IN_CLOSED_WINDOW
	clc			; Look through all
	ret

EnsureWinNotOnPassiveListCallBack	endp


endif




COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureGrabsValid

DESCRIPTION:	Check all active, implied, passive & kbd grabs for
		legal values.

CALLED BY:	INTERNAL

PASS:		*ds:si	- VisContentInstance
		ds:di	- pointer to VisContentInstance

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version
------------------------------------------------------------------------------@


if	ERROR_CHECK
EnsureGrabsValid	proc	far	uses	ax, bx, si
	class	VisContentClass
	.enter

	; Check ACTIVE mouse grab
	;
        mov	bx, ds:[di].VCNI_activeMouseGrab.VMG_object.handle
	tst	bx
	jz	5$
        mov	si, ds:[di].VCNI_activeMouseGrab.VMG_object.chunk
	call	ECCheckOD
5$:
        mov	bx, ds:[di].VCNI_activeMouseGrab.VMG_gWin
	tst	bx
	jz	10$
	call	ECCheckWindowHandle	; make sure valid & not garbage
10$:

	; Check IMPLIED mouse grab
	;
        mov	bx, ds:[di].VCNI_impliedMouseGrab.VMG_object.handle
	tst	bx
	jz	15$
        mov	si, ds:[di].VCNI_impliedMouseGrab.VMG_object.chunk
	call	ECCheckOD
15$:
        mov	bx, ds:[di].VCNI_impliedMouseGrab.VMG_gWin
	tst	bx
	jz	20$
	call	ECCheckWindowHandle	; make sure valid & not garbage
20$:

	; Check KBD grab
	;
        mov	bx, ds:[di].VCNI_kbdGrab.KG_OD.handle
	tst	bx
	jz	30$
        mov	si, ds:[di].VCNI_kbdGrab.KG_OD.chunk
	call	ECCheckOD
30$:

	; Check passive grabs
	;
    	mov	bx, offset VCNI_prePassiveMouseGrabList
	call	EnsurePassiveListValid

    	mov	bx, offset VCNI_postPassiveMouseGrabList
	call	EnsurePassiveListValid
	.leave
	ret

EnsureGrabsValid	endp


EnsurePassiveListValid	proc	near
	class	VisContentClass
	uses	ax, cx, dx, di, bp
	.enter
	mov	si, ds:[di][bx]
	tst	si
	jz	done
	mov	bx, cs
	mov	di, offset EnsurePassiveListValidCallBack
	call	ChunkArrayEnum
done:
	.leave
	ret

EnsurePassiveListValid	endp

EnsurePassiveListValidCallBack	proc	far
	class	VisContentClass
	push	bx
	push	si
	mov	bx, ds:[di].VMG_object.handle
	tst	bx
	jz	ok
	mov	si, ds:[di].VMG_object.chunk
	call	ECCheckOD
ok:
	mov	bx, ds:[di].VMG_gWin
	tst	bx			
	jz	ok2			
	call	ECCheckWindowHandle
ok2:
	pop	si
	pop	bx

	clc			; Look through all
	ret

EnsurePassiveListValidCallBack	endp

endif


JustECCode	ends

;
;-------------------
;

Resident	segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisContentGetVUM

DESCRIPTION:	Fetches VisualUpdateMode to use.
		If we have a visual link to a view, & the view has a pane
		window created, go ahead & use VUM_NOW, else use VUM_MANUAL.

CALLED BY:	GLOBAL

PASS:		*ds:si	- VisContentInstance

RETURN:		dl	- VisualUpdateMode

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

VisContentGetVUM	proc	far	uses	di
	class	VisContentClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	dl, VUM_MANUAL
	tst	ds:[di].VCNI_window	; Has the subview win been created yet?
	jz	haveMode		; if not, update later

					; Has the visual link to view been set?
	tst	ds:[di].VI_link.LP_next.handle
	jz	haveMode		; if not, update later

	mov	dl, VUM_NOW		; Everything's OK, so do update NOW.

haveMode:
	.leave
	ret

VisContentGetVUM	endp

Resident	ends

;------------

UserClassStructures	segment resource
;
; Have to put here, at end, AFTER the routines referenced are defined.
;

	; Consume these events, do nothing with them.
	;
	method	VisContentDoNothing, VisContentClass, MSG_VIS_MOVE_RESIZE_WIN

UserClassStructures	ends
