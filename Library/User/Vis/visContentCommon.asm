COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Library/User/Vis
FILE:		visContentCommon.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
				Handles notification that subview we're in
				has lost the gadget exclusive, meaning
				someone took it away or the view is
				closing.  In either case, force loss of
				gadget exclusive here.

    INT VisContentSendToLargeDocumentLayers
				Send a message to the vis children of a
				Large VisContent -- children are assumed to
				be "layers". If VCNA_LARGE_DOCUMENT_MODEL
				flag isn't set, then do nothing.

    MTD MSG_META_IMPLIED_WIN_CHANGE
				Handles notification that the implied
				window, or window that the mouse is in,
				when interacting with this IsoContent, has
				changed.

    MTD MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN
				Tests to see if the window handle passed is
				the same as the active or implied window
				being used to translate button & ptr
				events.  Used by OLPortWindow, in a call to
				the isocontent at the app object, to see if
				mouse was in actual port window, or whether
				it was just over the port border.

    MTD MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
				Handles notification of document origin
				changing by storing the new location into
				instance data for later use

    MTD MSG_VIS_VUP_ALTER_INPUT_FLOW
				Grab/Release input for a certain object
				which is a child of ours.

    INT AllocateGrabList        Allocate new chunk for passive grab list
				within a VisContent object

    INT ChangeGrab              Change grab within VisContent object

    INT CopyVupAlterInputFlowDataToVisMouseGrab
				Copies data passed in
				MSG_VIS_VUP_ALTER_INPUT_FLOW into
				VisMouseGrab structure.  Leaves VMG_object
				& VMG_gWin unchanged.

    INT FindPassiveGrabElement  Search passive VisMouseGrab list, looking
				for VMG_object passed

    INT FindPassiveGrabElementCallBack
				Search passive VisMouseGrab list, looking
				for VMG_object passed

    INT SendToVisParent         Send EC message on to VisParent, via queue
				so as not to provide synchronous behavior
				where apps normally don't get it.

    MTD MSG_META_NOTIFY_WITH_DATA_BLOCK
				This method handler queries all the vis
				children to find one that accepts ink.

    INT VisContentCheckOnInputHoldUpLow
				Implement UI-hold up scheme.

    INT CombineMouseEvent       Implement UI-hold up scheme.

    INT VisContentGetQueue      Return hold up input queue (create if not
				yet existing)

    INT ECVisContentEnsureEventsNotOutOfOrder
				Make sure the hold-up queue is empty

    INT VisSendMouseDataToPassiveGrab
				Send mouse event to passive grab

    INT SendMouseToPassiveGrabElementCallBack
				Send mouse event to passive grab

    INT VisSendMouseDataToActiveOrImpliedGrab
				Send mouse event to Active/Implied grab

    GLB VisContentTransformCoords
				This routine transforms a point from the
				IsoContent's coordinate system to the
				destination coordinate system.

    INT VisSendMouseDataToGrab  Send mouse event to VisMouseGrab passed

    INT ConvertSmallMouseEventToLarge
				Convert incoming mouse location to 32-bit
				integer, 16 bit fractional, translated
				document coordinates

    INT ConvertSmallMouseMethodToLarge
				Convert incoming mouse location to 32-bit
				integer, 16 bit fractional, translated
				document coordinates

    INT ConvertSmallWinMouseEventToSmallDoc
				Convert incoming mouse location to 16-bit
				translated document coordinates

    INT ConvertWinToDWFixed     Convert 16-bit coord to 32-bit integer,
				16-bit fractional translated document
				coordinates

    MTD MSG_VIS_CONTENT_DISABLE_HOLD_UP
				Change input state to force allowance of
				input data to flow

    MTD MSG_VIS_CONTENT_ENABLE_HOLD_UP
				Change input state to allow hold-up mode

    MTD MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW
				Start holding up all UI input events, in a
				separate queue, until VisContentResumeInput
				is called (A count is kept, so multiple
				patients can use)

    MTD MSG_VIS_CONTENT_RESUME_INPUT_FLOW
				Allow UI input to flow again.

    INT VisContentFlushHoldUpInputQueue
				Flush the hold-up input queue by moving all
				events in it to the front of the UI queue,
				in order.

    MTD MSG_META_LOST_FOCUS_EXCL
				Provide standard behavior for focus node

				Handled specially here so we can just
				ignore them if no one has the focus yet.
				If we let the messages through, the system
				will die since an object that doesn't have
				the focus can't be losing or gaining it,
				but the view sends these messages down with
				no knowledge of whether anything has the
				focus here.

    INT ViewUpdateContentTargetInfo
				Find a block of memory of the given size
				and type.

    MTD MSG_META_GET_FOCUS_EXCL Returns the current focus exclusive

    GLB CallTargetOrFirstChild  Call w/the passed method/data to either the
				target, the first child, or else returns...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of visContent.asm

DESCRIPTION:
	This file contains routines to implement the VisContentClass.

	$Id: visContentCommon.asm,v 1.1 97/04/07 11:44:29 newdeal Exp $

------------------------------------------------------------------------------@
VisCommon	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisContentInvalidate -- MSG_VIS_INVALIDATE for VisContentClass

DESCRIPTION:	Invalidate the content

PASS:
	*ds:si - instance data
	es - segment of VisContentClass

	ax - The message

RETURN:
	none

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/ 8/92		Initial version

------------------------------------------------------------------------------@
VisContentInvalidate	method VisContentClass, MSG_VIS_INVALIDATE
					uses si, ds
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset			;static handler
	mov	di, ds:[di].VCI_window
	tst	di
	jz	exit

	call	GrCreateState
	sub	sp, size RectDWord
	segmov	ds, ss
	mov	si, sp
	call	GrGetWinBoundsDWord
	call	GrInvalRectDWord
	call	GrDestroyState
	add	sp, size RectDWord

exit:
	.leave
	ret

VisContentInvalidate	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentObjFlushInputQueue

DESCRIPTION:	Extends default window death mechanism by making sure that
		the hold-up input queue is flushed out as well, before the
		superclass is called.


PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_OBJ_FLUSH_INPUT_QUEUE
		cx	- Event
		dx	- Block handle
		bp	- ObjFlushInputQueueNextStop

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/18/90		Initial version

------------------------------------------------------------------------------@

; NOTE:  This is in VisCommon because it needs to perform a near call
; to VisContentCheckOnInputHoldUpLow.
;
VisContentObjFlushInputQueue	method VisContentClass, \
					MSG_META_OBJ_FLUSH_INPUT_QUEUE
	; If holding up UI input, send event to HoldUpInputQueue, to be
	; processed later
	;
	call	VisContentCheckOnInputHoldUpLow
	jc	done			; If held up, all done.

	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock
done:
	Destroy	ax, cx, dx, bp
	ret

VisContentObjFlushInputQueue	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSubviewLostGadgetExcl --

DESCRIPTION:	Handles notification that subview we're in has lost the
		gadget exclusive, meaning someone took it away or the view
		is closing.  In either case, force loss of gadget exclusive
		here.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/90		Initial version

------------------------------------------------------------------------------@

VisContentSubviewLostGadgetExcl	method	dynamic VisContentClass, \
					MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
				    	; Force release of any active element
				    	; within the view
	clr	cx
	clr	dx
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	GOTO	ObjCallInstanceNoLock

VisContentSubviewLostGadgetExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSetInteractionBounds --
		MSG_VIS_VUP_SET_INTERACTION_BOUNDS for VisContentClass

DESCRIPTION:	Sends bounds up to the view so it can constrain any dragging.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_VUP_SET_INTERACTION_BOUNDS
		ss:bp	- {Rect} visible bounds
		dx	- size Rect

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
	Chris	5/ 3/91		Initial version

------------------------------------------------------------------------------@

VisContentSetInteractionBounds	method VisContentClass, \
			MSG_VIS_VUP_SET_MOUSE_INTERACTION_BOUNDS
	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom		;extract bounds

	sub	sp, size RectDWord
	mov	bp, sp
	mov	ss:[bp].RD_left.low, ax
	mov	ss:[bp].RD_top.low, bx
	mov	ss:[bp].RD_right.low, cx
	mov	ss:[bp].RD_bottom.low, dx
	clr	dx
	mov	ss:[bp].RD_left.high, dx
	mov	ss:[bp].RD_top.high, dx
	mov	ss:[bp].RD_right.high, dx
	mov	ss:[bp].RD_bottom.high, dx

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	mov	bx, ds:[di].VCNI_view.handle
	mov	si, ds:[di].VCNI_view.chunk	;get generic view OD
	tst	si				;no view, get out
	jz	exit

	mov	dx, size RectDWord
	mov	ax, MSG_GEN_VIEW_SET_DRAG_BOUNDS
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
exit:
	add	sp, size RectDWord
	Destroy	ax, cx, dx, bp
	ret
VisContentSetInteractionBounds	endm





COMMENT @-------------------------------------------------------------
		VisContentSendToLargeDocumentLayers
----------------------------------------------------------------------

SYNOPSIS:	Send a message to the vis children of a Large
		VisContent -- children are assumed to be "layers".
		If VCNA_LARGE_DOCUMENT_MODEL flag isn't set, then
		do nothing.

CALLED BY:	VisContentOriginChanged, etc.

PASS:		*ds:si - VisContent object
		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned (destroyed) by called methods

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/18/91	Initial version.

---------------------------------------------------------------------@
VisContentSendToLargeDocumentLayers	proc far
	class	VisContentClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL
	jz	done

	call	VisSendToChildren

done:

	.leave
	ret
VisContentSendToLargeDocumentLayers	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentImpliedWinChange

DESCRIPTION:	Handles notification that the implied window, or window that
		the mouse is in, when interacting with this IsoContent,
		has changed.

PASS:
	*ds:si - instance data
	es - segment of FlowClass

	ax - MSG_META_IMPLIED_WIN_CHANGE
        cx:dx	- Input OD of implied window, or 0 if no window has the
		  implied grab.
	bp      - window that ptr is in



RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@

VisContentImpliedWinChange	method dynamic	VisContentClass,
					MSG_META_IMPLIED_WIN_CHANGE

if	(0)	; Should no longer be needed, as PTR events are always sent
		; from IM (no more pointer ignore/all/enterleave modes)
		; Doug 3/92
					; SEE if implied
					;	grab window is
					;	changing
	cmp	bp, ds:[di].VCNI_impliedMouseGrab.VMG_gWin
	je	SIG_20			; skip if not changing

	call	ImForcePtrMethod	; Make IM generate a PTR METHOD,
					; so window changes are
					; noticed, even if current grab is
					; requesting other than full ptr
					; reporting
SIG_20:
endif
					; store implied window

	mov	ds:[di].VCNI_impliedMouseGrab.VMG_gWin, bp

	; If implied window is the same as the window this content sits on,
	; then ignore passed object & use this one.  Why?  In the case of
	; View/Content, the object passed will be the View.  We'd blow up
	; trying to call the view w/an input message.  We're really just
	; sharing the window.  So.. instead, we want ourselves to the be
	; implied object.		-- Doug 3/92
	;
	; P.S.  This may prove to be a small problem when the UI itself
	; becomes an application object -- the UI's GenApplication may
	; legitimately be told the implied window is the field that the UI's
	; GenApp happens to sit on.
	;
	cmp	bp, ds:[di].VCNI_window
	jne	storeObj
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
storeObj:
	mov	ds:[di].VCNI_impliedMouseGrab.VMG_object.handle, cx
	mov	ds:[di].VCNI_impliedMouseGrab.VMG_object.chunk, dx
	ret

VisContentImpliedWinChange	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentTestIfActiveOrImpliedWin

DESCRIPTION:	Tests to see if the window handle passed is the same as the
		active or implied window being used to translate button & ptr
		events.  Used by OLPortWindow, in a call to the isocontent
		at the app object, to see if mouse was in actual
		port window, or whether it was just over the port border.

CALLED BY:	INTERNAL

PASS:		*ds:si	- flow object
		ax 	- MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN

		bp	- Window to test against

RETURN:
		carry	- clear if match, set if no match.
		ax, cx, dx, bp - destroyed

DESTROYED:
		Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
	Doug	5/91		Changed to message, carry returned
	Doug	6/91		Moved from flow to VisContent
------------------------------------------------------------------------------@

VisContentTestIfActiveOrImpliedWin	method dynamic VisContentClass, \
		MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN
				; Assume that we'll use active grab
	add	di, offset VCNI_activeMouseGrab
				; Make sure active grab exists
	cmp	ds:[di].VMG_object.handle, 0
	jne	useThisGrab	; if it does, use it.
				; if it doesn't, use implied mouse grab instead
	add	di, offset VCNI_impliedMouseGrab - offset VCNI_activeMouseGrab

useThisGrab:
				; Return comparison result
	cmp	bp, ds:[di].VMG_gWin
	je	match
;noMatch:
	stc			; Doesn't match
	ret

match:
	clc			; A Match!
	Destroy	ax, cx, dx, bp
	ret

VisContentTestIfActiveOrImpliedWin	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentOriginChanged

DESCRIPTION:	Handles notification of document origin changing by
		storing the new location into instance data for later use

PASS:		*ds:si 	- instance data
		ds:di	- ptr to VisContentInstance
		es     	- segment of VisContentClass
		ax 	- MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
		ss:bp	- ptr to OriginChangedParams
 		dx	- size OriginChangedParams

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
	CDB	11/91		Added call to large document layers

------------------------------------------------------------------------------@

VisContentOriginChanged	method	dynamic VisContentClass, \
				MSG_META_CONTENT_VIEW_ORIGIN_CHANGED

	push	ax
	mov	cx, size PointDWord/2			; Structure to copy

	push	bp					; Added 3/19/93 cbh
copyLoop:
	mov	ax, word ptr ss:[bp].OCP_origin		; from stack
	mov	word ptr ds:[di].VCNI_docOrigin, ax	; to instance data

	inc	bp					; inc ptrs
	inc	bp
	inc	di
	inc	di
	loop	copyLoop				; until done
	pop	bp					; Added 3/19/93 cbh

	; Now call children if LARGE_DOCUMENT_MODEL
	;
	pop	ax					; message #
	call	VisContentSendToLargeDocumentLayers


	Destroy	ax, cx, dx, bp
	ret

VisContentOriginChanged	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentDraw

DESCRIPTION:	If Large document model, send MSG_VIS_DRAW to ALL children,
		not just those whose bounds overlap invalid area.  This is
		necessary because it is not possible to test the bounds of
		32-bit objects.

PASS:		*ds:si 	- instance data
		ds:di	- VisContentInstance
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_DRAW

		cx, dx, bp - MSG_VIS_DRAW data
				(not used here, but passed on)

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version, required for 32-bit contents

------------------------------------------------------------------------------@

VisContentDraw 	method VisContentClass, MSG_VIS_DRAW

	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL
	jnz	largeModel
					; if standard model, process normally
	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock

largeModel:
	; Before asking all our children to draw, make sure we've got a
	; non-NULL mask region here.
	;
	sub	sp, size RectDWord	; create frame for return data
	mov	bx, sp

	push	si, ds
	mov	si, ss
	mov	ds, si
	mov	si, bx
	mov	di, bp			; get GState in di
	call	GrGetMaskBoundsDWord
	pop	si, ds
	jc	afterChildrenDraw

	call	VisSendToChildren	; if large model, send to all children

afterChildrenDraw:

	add	sp, size RectDWord	; fix stack
	ret

VisContentDraw	endm





COMMENT @----------------------------------------------------------------------

METHOD:		VisContentGrab
		MSG_VIS_VUP_ALTER_INPUT_FLOW

DESCRIPTION:	Grab/Release input for a certain object which is a child
		of ours.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_VUP_ALTER_INPUT_FLOW
		dx	- size VupAlterInputFlowData
		ss:bp	- ptr to VupAlterInputFlowData structure one stack

VupAlterInputFlowData	struct
	VAIFD_flags		VisInputFlowGrabFlags
	VAIFD_type		VisInputFlowGrabType
	VAIFD_object		optr
	VAIFD_gWin		hptr.Window
	VAIFD_translation	PointDWord
VupAlterInputFlowData	ends

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
	Doug	5/91		Revised to handle 32-bit stuff

------------------------------------------------------------------------------@

VisContentVupAlterInputFlow	method	dynamic VisContentClass,
					MSG_VIS_VUP_ALTER_INPUT_FLOW


	test	ss:[bp].VAIFD_flags, mask VIFGF_NOT_HERE
EC <	ERROR_NZ	UI_VIS_CONTENT_CAN_NOT_GRAB_OR_RELEASE_THIS_EXCL >
NEC<	LONG jnz exit							>

	; Save current active window, so we test to see if it has
	; changed at end
	;
	push	ds:[di].VCNI_activeMouseGrab.VMG_gWin

	mov	cx, ss:[bp].VAIFD_object.handle	; Fetch object optr
	mov	dx, ss:[bp].VAIFD_object.chunk

EC <	; Make sure a valid object				>
EC <	tst	cx						>
EC <	jz	okObj						>
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>
EC <	call	ECCheckOD					>
EC <	xchg	bx, cx						>
EC <	xchg	si, dx						>
EC <okObj:							>

EC <	; Make sure a valid window				>
EC <	push	bx						>
EC < 	mov	bx, ss:[bp].VAIFD_gWin				>
EC <	tst	bx						>
EC <	jz	okWin						>
EC <	call	ECCheckWindowHandle				>
EC <okWin:							>
EC <	pop	bx						>

EC <	; Make sure data structures intact before starting	>
EC <	call	EnsureGrabsValid				>

	mov	al, ss:[bp].VAIFD_flags		; & flags

	cmp	ss:[bp].VAIFD_grabType, VIFGT_ACTIVE
	LONG	jne	passive

;------------------------------------------------------------------------------
;	Active grab handling
;------------------------------------------------------------------------------
;active:
	test	al, mask VIFGF_MOUSE	; doing mouse?
	jz	notMouse

	test	al, mask VIFGF_GRAB	; if release, just do FlowReleaseGrab
	jz	doChangeGrab

	add	di, offset VCNI_activeMouseGrab
	cmp	cx, ds:[di].VMG_object.handle
	jne	differentOD
	cmp	dx, ds:[di].VMG_object.chunk
	je	doUpdate		; if OD same as grab, just update data

differentOD:
	tst	ds:[di].VMG_object.handle	; see if something alread has
	jz	afterOldGrabForcedOff		; grab -- if not, just grab new

	test	al, mask VIFGF_FORCE	; see if force grab
	jz	done			; if not, done -- grab won't change

	push	ax, cx, dx, bp
	mov	bx, offset Vis_offset
	mov	di, offset VCNI_activeMouseGrab
	clr	cx
	clr	dx
	clr	bp
	mov	ax, MSG_META_GAINED_MOUSE_EXCL
	call	FlowForceGrab		; Force off current grab
	pop	ax, cx, dx, bp

afterOldGrabForcedOff:
					; Copy data into grab (all but OD)
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, offset VCNI_activeMouseGrab
	call	CopyVupAlterInputFlowDataToVisMouseGrab

					; Then do the force grab
doChangeGrab:
	push	bp
	mov	bp, ss:[bp].VAIFD_gWin	; extra data word
;EC <	tst	bp						>
;EC <	jz	afterWinCheck					>
;EC <	xchg	bx, bp						>
;EC <	call	ECCheckWindowHandle				>
;EC <	xchg	bx, bp						>
;EC <afterWinCheck:						>
	mov	di, offset VCNI_activeMouseGrab
	mov	bx, MSG_META_GAINED_MOUSE_EXCL
	call	ChangeGrab		; Change mouse grab
	pop	bp
	jmp	short done

doUpdate:
	call	CopyVupAlterInputFlowDataToVisMouseGrab
	jmp	short done

notMouse:

	test	al, mask VIFGF_KBD	; doing kbd?
	jz	done
	mov	di, offset VCNI_kbdGrab
	clr	bp			; extra data word
	mov	bx, MSG_META_GAINED_KBD_EXCL
	call	ChangeGrab		; Change kbd grab
done:
	pop	ax			; get VMG_gWin saved at start
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VCNI_activeMouseGrab.VMG_gWin
	cmp	ax, cx
	je	exit

	; Notify ourselves that the active window has changed.  This
	; info is needed by the specific UI's implementation of
	; GenApplicationClass which is responsible for keeping the window
	; system abreast as to the current active window within the
	; application.
	;
	mov	ax, MSG_VIS_CONTENT_NOTIFY_ACTIVE_MOUSE_GRAB_WIN_CHANGED
	GOTO	ObjCallInstanceNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret

;------------------------------------------------------------------------------
;	Passive grab handling
;------------------------------------------------------------------------------

passive:
	test	ss:[bp].VAIFD_flags, mask VIFGF_MOUSE	; doing mouse?
	jz	done					; only passive types
							; available are MOUSE

	; Fetch chunk handle of passive grab list being referenced
	;
	mov	bx, offset VCNI_prePassiveMouseGrabList
	cmp	ss:[bp].VAIFD_grabType, VIFGT_PRE_PASSIVE
	je	havePassiveGrabList
	mov	bx, offset VCNI_postPassiveMouseGrabList
havePassiveGrabList:

	test	ss:[bp].VAIFD_flags, mask VIFGF_GRAB
	jnz	addPassiveGrab

;releasePassiveGrab:
	add	di, bx
	cmp	word ptr ds:[di], 0	; see if chunk exists
	jz	done			; if not, done.

	push	si
	mov	si, ds:[di]		; fetch chunk
	call	FindPassiveGrabElement
	jnc	gone			; if not found, done
	call	ChunkArrayDelete	; if found, delete it.
gone:
	pop	si
	jmp	done

addPassiveGrab:
	add	di, bx
	cmp	word ptr ds:[di], 0	; see if chunk exists
	jnz	doSearch		; if so, search it

	; If chunk does not yet exist, create one, as we're about to
	; add in a new passive grab
	;
	call	AllocateGrabList
	add	di, bx
	mov	ds:[di], ax		; store new chunk here

doSearch:
	push	si
	mov	si, ds:[di]		; fetch chunk
	call	FindPassiveGrabElement	; if already on list, update
	jc	updateHere
					; otherwise add new entry
	push	ax
	clr	ax
	call	ChunkArrayElementToPtr	; point at first element
	call	ChunkArrayInsertAt	; insert new element at front
					; copy over grab data
	pop	ax
updateHere:
	; copy optr into VisMouseGrab
	;
	mov	ds:[di].VMG_object.handle, cx
	mov	ds:[di].VMG_object.chunk, dx

	; copy all other data into VisMouseGrab
	;
	call	CopyVupAlterInputFlowDataToVisMouseGrab
	pop	si
	Destroy	ax, cx, dx, bp
	jmp	done

VisContentVupAlterInputFlow	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocateGrabList

DESCRIPTION:	Allocate new chunk for passive grab list within a
		VisContent object

CALLED BY:	INTERNAL
		VisContentInitializeWorkingVars
		VisContentViewWinCreated	(to catch pre-instantiated
						 objects from .ui file)

PASS:	*ds:si	- VisContentInstance

RETURN:
	ax	- chunk handle of ChunkArray created

	*ds:si	- VisContentInstance
	ds:di	- VisContentInstance

DESTROYED:
	nothing

------------------------------------------------------------------------------@

AllocateGrabList	proc	near	uses	bx
	class	VisContentClass
	.enter

	; Figure out which ObjChunkFlags to use for new chunk.   (Changed
	; to use IGNORE_DIRTY for all generic VisContents. 5/26/93 cbh)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	10$
	mov	al, mask OCF_IGNORE_DIRTY	; Mark dirty, since newly
	jmp	short 20$			; created
10$:
	mov	ax, si				; Pass chunk of VisContent
	call	ObjGetFlags			; Get current state flags for
						; VisContent
	and	al, mask OCF_IGNORE_DIRTY	; Copy over ignore dirty
						; request, if there.
	or	al, mask OCF_DIRTY		; Mark dirty, since newly
						; created
20$:
	; & create the new chunk, in same block, for storing grab list
	;
	push	cx, si
	mov	bx, size VisMouseGrab
	clr	cx
	clr	si
	call	ChunkArrayCreate
	mov_trash	ax, si
	pop	cx, si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	.leave
	ret

AllocateGrabList	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeGrab

DESCRIPTION:	Change grab within VisContent object

CALLED BY:	INTERNAL
		VisContentGrab

PASS:		*ds:si 	- instance data
		al	- VisInputFlowGrabFlags
		bx	- "GAINED" message to be sent out if object gains
			  grab by virtue of this method getting called.
			  ax+1 must equal "LOST" message
		cx:dx	- optr of object requesting grab/release
		bp	- extra data word accompanying grab
		di	- offset within master part to BasicGrab

RETURN:
		carry	- set if grab OD changes

DESTROYED:	nothing


------------------------------------------------------------------------------@

ChangeGrab	proc	near	uses	ax, bx, cx, dx, bp
	class	VisContentClass
	.enter

	push	bx				; save "GAINED" message
	mov	bx, offset Vis_offset
						; Grab, or release?
	test	al, mask VIFGF_GRAB
	jnz	CG_Grab

;CG_Release:
						; no data passed in bp
	pop	ax
	call	FlowReleaseGrab			; Release the grab
	jmp	short done

CG_Grab:
						; Force grab?
	test	al, mask VIFGF_FORCE
	jnz	CG_ForceGrab

	pop	ax
	call	FlowRequestGrab			; Do regular grab
	jmp	short done

CG_ForceGrab:					; otherwise, OK, force grab
	pop	ax
	call	FlowForceGrab			; Force the grab

done:
	.leave
	ret

ChangeGrab	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyVupAlterInputFlowDataToVisMouseGrab

DESCRIPTION:	Copies data passed in MSG_VIS_VUP_ALTER_INPUT_FLOW into
		VisMouseGrab structure.  Leaves VMG_object & VMG_gWin
		unchanged.

CALLED BY:	INTERNAL
		VisContentGrab

PASS:		ds:di 	- ptr to VisMouseGrab to stuff
		ss:bp	- ptr to VupAlterInputFlowData structure one stack

RETURN:		nothing

DESTROYED:	nothing

------------------------------------------------------------------------------@

CopyVupAlterInputFlowDataToVisMouseGrab	proc	near	uses	ax, cx, di, bp
	class	VisContentClass
	.enter

	; copy gWin into VisMouseGrab
	;
	mov	ax, word ptr ss:[bp].VAIFD_gWin		; from stack
	mov	ds:[di].VMG_gWin, ax			; to instance data

	; copy VisMouseGrabFlags into VisMouseGrab
	;
	mov	al, ss:[bp].VAIFD_flags			; from stack
	mov	ds:[di].VMG_flags, al			; to instance data

	; Copy 32-bit translation values into VisContent instance data
	; for reference when sending out mouse events
	;
	mov	cx, (size PointDWord)/2
copyLoop:
	mov	ax, word ptr ss:[bp].VAIFD_translation	; from stack
	mov	word ptr ds:[di].VMG_translation, ax	; to instance data
	inc	bp
	inc	bp
	inc	di
	inc	di
	loop	copyLoop

	; di, bp - destroyed

	.leave
	ret

CopyVupAlterInputFlowDataToVisMouseGrab	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	FindPassiveGrabElement

DESCRIPTION:	Search passive VisMouseGrab list, looking for VMG_object passed

CALLED BY:	INTERNAL
		VisContentGrab

PASS:		*ds:si	- ChunkArray of VisMouseGrab's
		cx:dx	- VMG_object to look for

RETURN:		if found:
			carry set
			ds:di	- ptr to VisMouseGrab
		else:
			carry clear
			di	- destroyed

DESTROYED:	nothing

------------------------------------------------------------------------------@

FindPassiveGrabElement	proc	near	uses	ax, bx, cx, dx, si, bp
	class	VisContentClass
	.enter
	mov	bx, cs
	mov	di, offset FindPassiveGrabElementCallBack
	call	ChunkArrayEnum
	mov	di, ax
	.leave
	ret

FindPassiveGrabElement	endp


FindPassiveGrabElementCallBack	proc	far
	class	VisContentClass
EC <	; As long as we're here, make sure valid		>
EC <	push	bx						>
EC <	push	si						>
EC <	mov	bx, ds:[di].VMG_object.handle			>
EC <	tst	bx						>
EC <	jz	ok						>
EC <	mov	si, ds:[di].VMG_object.chunk			>
EC <	call	ECCheckOD					>
EC <ok:								>
EC <	mov	bx, ds:[di].VMG_gWin				>
EC <	tst	bx						>
EC <	jz	ok2						>
EC <	call	ECCheckWindowHandle				>
EC <ok2:							>
EC <	pop	si						>
EC <	pop	bx						>

	cmp	cx, ds:[di].VMG_object.handle
	jne	notFound
	cmp	dx, ds:[di].VMG_object.chunk
	jne	notFound

	mov	ax, di		; return pointer to found element
	stc			; quit search
	ret

notFound:
	clc			; keep looking...
	ret

FindPassiveGrabElementCallBack	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToVisParent

DESCRIPTION:	Send EC message on to VisParent, via queue so as not to
		provide synchronous behavior where apps normally don't get it.

CALLED BY:	INTERNAL

PASS:		*ds:si	- VisContentInstance
		ds:di	- pointer to VisContentInstance
		ax	- message to send on
		cx, dx, bp	- data to send on

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

SendToVisParent	proc	far	uses	bx, si, di
	class	VisContentClass
	.enter
	call	VisFindParent
	tst	bx
	jz	done

	; Don't force synchronized behavior, as apps can't normally rely
	; on it.  Instead, send via queue
	;
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
SendToVisParent	endp

endif




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentKbdChar
		MSG_META_KBD_CHAR

DESCRIPTION:	Handle kbd char sent to content

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_KBD_CHAR
		cx, dx, bp	- kbd data

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

VisContentKbdChar	method	VisContentClass, MSG_META_KBD_CHAR

	; If holding up UI input, send event to HoldUpInputQueue, to be
	; processed later
	;
	call	VisContentCheckOnInputHoldUpLow
	jc	done		; If held up, all done.

; MORE TO DO - update of constrain/move/copy status (?)
				; Send all kbd char's on to current kbd grab,
				; unless there is none, in which case we send
				; them to the current focus object
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VCNI_kbdGrab.KG_OD.handle
	tst	bx
	jz	noGrab		; if no grab, send to super class

	mov	si, ds:[di].VCNI_kbdGrab.KG_OD.chunk
	jmp	short sendOn

noGrab:
	mov	bx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	tst	bx
	jz	noFocus
	mov	si, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
sendOn:
	GOTO	ObjMessageCallFromHandler

noFocus:
	; If no destination OD, send message to ourselves (to allow
	; interception), to deal with the character (the default action is
	; to FUP the character up.)

	mov	ax, MSG_VIS_CONTENT_UNWANTED_KBD_EVENT
	GOTO	ObjCallInstanceNoLock
done:
	ret

VisContentKbdChar	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentMouseEvent

DESCRIPTION:	Send mouse events on to grab, if there is any.  If not,
		send to superclass, which will presumably pass them on to
		visible child under point.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_PTR, MSG_META_START_SELECT, etc
		cx, dx, bp	- mouse data

RETURN:		ax	- mask MRF_PROCESSED
		cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if LARGE_DOC_MODEL:

		implied: SMALL WIN -> LARGE DOC events, send to self
		active:  SMALL WIN -> LARGE DOC if LARGE events requested, else
			 	      SMALL DOC

	if not LARGE_DOC_MODEL:
		implied: SMALL WIN/DOC -> SMALL DOC.  send to self
		active:  SMALL WIN/DOC -> LARGE DOC if LARGE events requested,
					  else SMALL DOC. send to active grab


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
	Doug	5/91		Revised to handle 32-bit contents
	MeyerK	09/2021		Add wheel events

------------------------------------------------------------------------------@

VisContentMouseEvent	method	VisContentClass, MSG_META_PTR, \
						 MSG_META_MOUSE_WHEEL_VERTICAL, \
						 MSG_META_START_SELECT, \
						 MSG_META_START_MOVE_COPY, \
						 MSG_META_START_FEATURES, \
						 MSG_META_START_OTHER, \
						 MSG_META_DRAG_SELECT, \
						 MSG_META_DRAG_MOVE_COPY, \
						 MSG_META_DRAG_FEATURES, \
						 MSG_META_DRAG_OTHER, \
						 MSG_META_END_SELECT, \
						 MSG_META_END_MOVE_COPY, \
						 MSG_META_END_FEATURES, \
						 MSG_META_END_OTHER

	; If holding up UI input, send event to HoldUpInputQueue, to be
	; processed later
	;
	call	VisContentCheckOnInputHoldUpLow
	jc	done		; If held up, all done.

; MORE TO DO -- Adjust for mouse bump

	cmp	ax, MSG_META_PTR		; If ptr, send straight to active/imp
	je	sendLoop

	push	ds:[di].VCNI_postPassiveMouseGrabList	; save for later

	; First, send to pre-passive grab list
	;
	push	ax
	mov	ax, MSG_META_PRE_PASSIVE_BUTTON
					; pass *ds:di = ChunkArray
	mov	di, ds:[di].VCNI_prePassiveMouseGrabList
	call	VisSendMouseDataToPassiveGrab
	pop	ax

; MORE TO DO -- active message may have changed (Due to termination of
; active function), so we shouldn't just push & pop ax.  Instead, use
; activeMouseMethod.

	test	bx, mask MRF_PREVENT_PASS_THROUGH	; see if we should
							; skip active/implied
	jnz	sendToPostPassiveGrab			; if so, skip

					; send mouse to active/implied grab

	; Send mouse data to active/implied mouse grab, loop if REPLAY
	; requested & granted
	;
sendLoop:
	call	VisSendMouseDataToActiveOrImpliedGrab
	test	bx, mask MRF_REPLAY
	jnz	sendLoop

	cmp	ax, MSG_META_PTR		; If ptr, done
	je	done

sendToPostPassiveGrab:
	; Last, send to post-passive mouse grab list
	;
	pop	di			; fetch chunk of post-passive list

	mov	ax, MSG_META_POST_PASSIVE_BUTTON
	call	VisSendMouseDataToPassiveGrab

; MORE TO DO -- nuke CS_UI_FUNCS since no longer used, fix bug introduced.
					; return processed, always.
done:
	mov	ax, mask MRF_PROCESSED
	Destroy	cx, dx, bp
	ret

VisContentMouseEvent	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentQueryIfPressIsInk

DESCRIPTION:	Send query event on to grab, if there is any.  If not,
		say that the press should be ink.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_QUERY_IF_PRESS_IS_INK
		cx, dx	- press position

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version
	Doug	5/91		Revised to handle 32-bit contents

------------------------------------------------------------------------------@
VisContentQueryIfPressIsInk	method	VisContentClass,
					MSG_META_QUERY_IF_PRESS_IS_INK

	mov	bx, IRV_NO_INK	; If no mouse grabs, then press is not ink
	;
	; Get active/implied VisMouseGrab ptr in ds:di

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

if _GRAFFITI_ANYWHERE	;---------------------------------------------
	;
	;  If we have a view associated with us, we want to send the
	;  query to the focus, since VisSendDataToGrab will call
	;  VisCallChildUnderPoint, and most gestures will be rejected.

	tst	ds:[di].VCNI_view.handle
	jz	sendToGrab

	;
	; We can have a no-grab situation if there's a multi-line text
	; object under a GenContent, evidently, so we make sure the
	; query gets through by sending it to the focus, if any.

	push	ax, cx, dx
	mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
	call	ObjCallInstanceNoLock		; ^lcx:dx = obj
	movdw	bxbp, cxdx			; save object
	pop	ax, cx, dx			; passed args

	;
	;  Don't call self in infinite loop, or try to call an object
	;  that isn't there.

	tst	bx				; found anything?
	jz	sendToGrab			; nope, do normal thing
checkSame:
	cmp	bx, ds:[LMBH_handle]		; same obj block?
	jne	doCall
	cmp	bp, si				; same obj?
	je	sendToGrab			; yep, do normal thing
doCall:
	;
	;  Send to focused object.

	mov	si, bp				; ^lbx:si = obj
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, bp = returned
	mov	bx, ax
	jmp	isNonZero			; continue normally...
endif	; _GRAFFITI_ANYWHERE -----------------------------------------

sendToGrab::
	add	di, offset VCNI_activeMouseGrab
	tst	ds:[di].VMG_object.handle
	jnz	sendToThisMouseGrab

	add	di, offset VCNI_impliedMouseGrab - offset VCNI_activeMouseGrab

	tst	ds:[di].VMG_object.handle
	jz	sendReply

sendToThisMouseGrab:

	;
	; If there is an active or implied mouse grab, then send
	; ink query to it.
	;
	call	VisSendMouseDataToGrab

	tst	bx			;If the method was not handled
	jnz	isNonZero		; by an object, or if the grab was the
	mov	bx, IRV_NO_INK		; VisContent itself, then make the
					; press be non-ink...
isNonZero:
EC <	cmp	bx, InkReturnValue					>
EC <	ERROR_AE	UI_INVALID_INK_RETURN_VALUE			>

	;
	; If IRV_WAIT has been passed, then for some reason the app needs to
	; check something that lies in another thread (or maybe it just wants
	; to hooey with the user by holding up input a bit). If this is the
	; case, then just exit (a MSG_GEN_APPLICATION_INK_QUERY_REPLY will
	; be sent by the app later).
	;

	cmp	bx, IRV_WAIT
	jz	exit

sendReply:
	mov	cx, bx

	;
	; CX = InkReturnValue (whether or not the press should be ink or not)
	; Send it to the application.
	;
	mov	ax, MSG_GEN_APPLICATION_INK_QUERY_REPLY
	clr	bx
	call	GeodeGetAppObject
EC <	tst	bx							>
EC <	ERROR_Z	UI_VIS_CONTENT_MUST_BE_OWNED_BY_AN_APPLICATION		>
	clr	di
	call	ObjMessage
exit:
	ret

VisContentQueryIfPressIsInk	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisContentInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler queries all the vis children to find
		one that accepts ink.

CALLED BY:	GLOBAL
PASS:		same as MSG_META_NOTIFY_WITH_DATA_BLOCK
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisContentInk	method	dynamic VisContentClass, MSG_META_NOTIFY_WITH_DATA_BLOCK
	cmp	dx, GWNT_INK
	jne	gotoSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	je	isInk
gotoSuper:
	jmp	callSuper
isInk:

	test	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL
	LONG	jnz	doLargeDocument


	call	VisQueryWindow

;	Lock the ink data to get the bounds.

	push	cx, dx, bp, es
	mov	bx, bp
	call	MemLock
	mov	es, ax


	sub	sp, size VisCallChildrenInBoundsFrame
	mov	bp, sp
	push	bx

;	Transform the raw screen bounds into our window coords

	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	call	WinUntransform
	mov	ss:[bp].VCCIBF_bounds.R_left, ax
	mov	ss:[bp].VCCIBF_bounds.R_top, bx

	mov	ax, es:[IH_bounds].R_right
	mov	bx, es:[IH_bounds].R_bottom
	call	WinUntransform
	mov	ss:[bp].VCCIBF_bounds.R_right, ax
	mov	ss:[bp].VCCIBF_bounds.R_bottom, bx

	pop	bx
	call	MemUnlock

;	Call all the objects within the ink bounds to find one that wanted
;	the ink.

	clr	ss:[bp].VCCIBF_data1
	mov	ax, MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK
	call	VisCallChildrenInBounds
	mov	bx, ss:[bp].VCCIBF_data1
	tst	bx
	jz	freeInk
	mov	si, ss:[bp].VCCIBF_data2

if 0
;
;	Transform the ink bounds (and points?) to the destination window
;
;	Don't do this! If the object needs it, let them do it (most won't,
;	and converting several hundred points seems as if it could be
;	some serious work)
;
;
;	mov	di, ss:[bp].VCCIBF_data4		;Get GWin
;
;	mov	cx, es:[IH_bounds].R_left
;	mov	dx, es:[IH_bounds].R_top
;	call	VisContentTransformCoords
;	jc	freeInk
;	mov	es:[IH_bounds].R_left, cx
;	mov	es:[IH_bounds].R_top, dx
;
;	mov	cx, es:[IH_bounds].R_right
;	mov	dx, es:[IH_bounds].R_bottom
;	call	VisContentTransformCoords
;	jc	freeInk
;	mov	es:[IH_bounds].R_right, cx
;	mov	es:[IH_bounds].R_bottom, dx
endif

	add	sp, size VisCallChildrenInBoundsFrame
	pop	cx, dx, bp, es

;	Send the ink off to the object that wanted it...

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	clr	di
	GOTO	ObjMessage

freeInk:
	add	sp, size VisCallChildrenInBoundsFrame
	pop	cx, dx, bp, es

	mov	ax, SST_NO_INPUT		;Give a sound to tell the user
	call	UserStandardSound		; his ink was eaten...

callSuper:
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock

doLargeDocument:
	push	cx, dx, bp
	call	CallTargetOrFirstChild
	pop	cx, dx, bp
	jc	callSuper			;If method isn't handled,
						; branch
	ret
VisContentInk	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisIsoCheckOnInputHoldUpLow

DESCRIPTION:	Implement UI-hold up scheme.

CALLED BY:	INTERNAL

PASS:
	*ds:si	- VisContent object
	ds:di	- VisContent object

RETURN:
	carry	- set if input held up in uiHoldUpInputQueue

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/91		Broken out from CheckOnInputHoldUp
------------------------------------------------------------------------------@

VisContentCheckOnInputHoldUpLow	proc	near
	class	VisContentClass

				; Test for HOLD UP mode
	test	ds:[di].VCNI_holdUpInputFlags, mask HUIF_HOLD_UP_MODE_DISABLED
	jnz	passInput
	tst	ds:[di].VCNI_holdUpInputCount
	jnz	holdUpInput
passInput:

EC <	call	ECVisContentEnsureEventsNotOutOfOrder		>
	clc
	ret

holdUpInput:
	push	bx
	push	di

	cmp	ax, MSG_META_PTR
	jne	nonPtrMethod

	; SEND EVENT FOR PTR
	;
	push	cs		; push custom vector on stack
	mov	di, offset CombineMouseEvent
	push	di
	mov	di, mask MF_FORCE_QUEUE or \
		    mask MF_CHECK_DUPLICATE or \
		    mask MF_CUSTOM or mask MF_CHECK_LAST_ONLY
	jmp	short doObjMessage

nonPtrMethod:
	mov	di, mask MF_FORCE_QUEUE
doObjMessage:
				; fetch queue to send events to
	call	VisContentGetQueue
	call	ObjMessage
	pop	di
	pop	bx
	stc			; Indicate input held up (eaten by queue)
	ret

VisContentCheckOnInputHoldUpLow	endp


;
; Custom combination routine for ptr events, called by ObjMessage in
; OutputMonitor above.
;
CombineMouseEvent	proc	far
	class	VisContentClass

	cmp	ds:[bx].HE_method, MSG_META_PTR
	jne	cantUpdate

	cmp	ds:[bx].HE_bp, bp	; different button flags?
	jne	cantUpdate		; yes!, can't combine

	mov	ds:[bx].HE_cx, cx	; update event
	mov	ds:[bx].HE_dx, dx	; update event
	mov	di, PROC_SE_EXIT	; show we're done
	ret

cantUpdate:
	mov	di, PROC_SE_STORE_AT_BACK	; just put at the back.
	ret
CombineMouseEvent	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	VisContentGetQueue

DESCRIPTION:	Return hold up input queue (create if not yet existing)

CALLED BY:	INTERNAL

PASS:		*ds:si	- VisContent

RETURN:		bx	- Handle of hold up input queue

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version
------------------------------------------------------------------------------@

VisContentGetQueue	proc	near	uses	di
	class	VisContentClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VCNI_holdUpInputQueue
	tst	bx
	jnz	done
	call	GeodeAllocQueue
	mov	ds:[di].VCNI_holdUpInputQueue, bx
done:
	.leave
	ret

VisContentGetQueue	endp





COMMENT @----------------------------------------------------------------------

FUNCTION:	ECVisContentEnsureEventsNotOutOfOrder

DESCRIPTION:	Make sure the hold-up queue is empty

CALLED BY:	INTERNAL

PASS:	*ds:si	- instance data

RETURN:	nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial header
------------------------------------------------------------------------------@

if	ERROR_CHECK
ECVisContentEnsureEventsNotOutOfOrder	proc	near
	class	VisContentClass
	uses	ax, bx, di
	.enter
	; Make sure nothing is backed up
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VCNI_holdUpInputQueue
	tst	bx
	jz	done
	call	GeodeInfoQueue		; see if we've got any events in queue
	tst	ax
	ERROR_NZ    UI_NEW_INPUT_EVENT_PROCESSED_BEFORE_HOLD_UP_QUEUE_FLUSHED
done:
	.leave
	ret

ECVisContentEnsureEventsNotOutOfOrder	endp
endif



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentUnwantedMouseEvent

DESCRIPTION:	Handler for mouse event with no destination, i.e. being
		sent to a VisMouseGrab which has a null optr stored for
		the destination object.  This happens if there is no active,
		& no implied mouse grab, most commonly if the ptr has been
		clicked outside of a modal window or outside the visual
		area of an application.  Default behavior here is to beep,
		on presses only.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- Mouse event
		cx:dx	- ptr to VisMouseGrab
		bp	- mouse event flags

RETURN:		ax	- 0
		cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@

VisContentUnwantedMouseEvent	method	VisContentClass,
				MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT
	test	bp, mask BI_PRESS	; See if press or not
	jz	afterLostInputCheck

				; Let user know that he is annoying
				; us ;)
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
afterLostInputCheck:

	clr	ax			; MouseReturnFlags = 0
	Destroy	cx, dx, bp
	ret

VisContentUnwantedMouseEvent	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSendMouseDataToPassiveGrab

DESCRIPTION:	Send mouse event to passive grab

CALLED BY:	INTERNAL
		VisContentMouseEvent

PASS:		*ds:si	- VisContent object
		*ds:di 	- ChunkArray chunk holding passive grab list
			  (or di = 0 if no list)
		ax 	- 16-bit mouse event
		cx, dx	- incoming mouse location
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN: 	bx	- OR-sum of all data returned from objects in ax

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version

------------------------------------------------------------------------------@

PassiveCallBackData	struct
	PCBD_bpData		word	; data previously passed in bp
	PCBD_isoContent		lptr	; chunk handle of iso content
	PCBD_resultORSum	word	; OR-sum result of calls
PassiveCallBackData	ends

VisSendMouseDataToPassiveGrab	proc	near	uses	si, di, bp, es
	class	VisContentClass
	clr	bx			;assume nothing there to do
	tst	di			;nope, exit
	jz	exit

	.enter
	sub	sp, size PassiveCallBackData

	mov	bx, bp
	mov	bp, sp
	mov	ss:[bp].PCBD_isoContent, si	; Put IsoContent chunk here
	mov	ss:[bp].PCBD_bpData, bx		; Pass on data passed in bp
	mov	ss:[bp].PCBD_resultORSum, 0	; Init OR-sum clear

	mov	si, di			; *ds:si = ChunkArray
EC <	tst	si						>
EC <	ERROR_Z	VIS_ERROR_PASSIVE_GRAB_CHUNK_MISSING		>

	mov	bx, cs
	mov	di, offset SendMouseToPassiveGrabElementCallBack
	call	ChunkArrayEnum
	mov	bx, ss:[bp].PCBD_resultORSum	; Return OR-sum flags in bx

	add	sp, size PassiveCallBackData
	.leave

exit:
	ret

VisSendMouseDataToPassiveGrab	endp


SendMouseToPassiveGrabElementCallBack	proc	far
	class	VisContentClass
				; *ds:si - array
				; ds:di - ptr to VisMouseGrab
				; ss:bp - ptr to PassiveCallBackData

	push	bp
	mov	si, ss:[bp].PCBD_isoContent	; Needs *ds:si = VisContent
	mov	bp, ss:[bp].PCBD_bpData		; Fetch bp data
	call	VisSendMouseDataToGrab
	pop	bp

	; OR-sum flags into es for return at end
	;
	or	ss:[bp].PCBD_resultORSum, bx	; OR-in returned flags

	clc			; send to all elements
	ret

SendMouseToPassiveGrabElementCallBack	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSendMouseDataToActiveOrImpliedGrab

DESCRIPTION:	Send mouse event to Active/Implied grab

CALLED BY:	INTERNAL
		VisContentMouseEvent

PASS:		*ds:si 	- VisContentClass object
		ax 	- 16-bit mouse event
		cx, dx	- incoming mouse location
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN: 	bx	- data returned from object in ax

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

VisSendMouseDataToActiveOrImpliedGrab	proc	near	uses	ax, di
	class	VisContentClass
	.enter

	; Get active/implied VisMouseGrab ptr in ds:di
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, offset VCNI_activeMouseGrab
	tst	ds:[di].VMG_object.handle
	jnz	sendToThisMouseGrabAndHandleEndMoveCopy

;impliedGrab:
	add	di, offset VCNI_impliedMouseGrab - offset VCNI_activeMouseGrab

					; If no active grab, then convert
					; all drag & end messages into
					; OTHER messages, so as not to confuse
					; objects that happen to be under the
					; mouse
	cmp	ax, MSG_META_DRAG_SELECT
	je	sendDragOther
	cmp	ax, MSG_META_DRAG_MOVE_COPY
	je	sendDragOther
	cmp	ax, MSG_META_DRAG_FEATURES
	je	sendDragOther
	cmp	ax, MSG_META_END_SELECT
	je	sendEndOther
	cmp	ax, MSG_META_END_FEATURES
	je	sendEndOther
	cmp	ax, MSG_META_END_MOVE_COPY
	jne	sendToThisMouseGrab	; not END or DRAG, just send it

	;
	; we've received a MSG_META_END_MOVE_COPY with no active grab, if a
	; quick transfer is in progress, we need to stop it so "no destination"
	; notification gets sent out to the source
	;
	xor	bx, bx			; force sending MSG_META_END_OTHER
					; (carry clear - don't check
					;	quick-transfer status)
	call	ClipboardHandleEndMoveCopy		; hide quick-transfer internals

sendEndOther:
	mov	ax, MSG_META_END_OTHER
	jmp	sendToThisMouseGrab

sendToThisMouseGrabAndHandleEndMoveCopy:
	;
	; we have an active grab, if MSG_META_END_MOVE_COPY, then do internal
	; clean-up for end-move-copy -- clear XOR region, clear quick-transfer
	; status cursor (immediate indication to user that quick-transfer has
	; ended, fixes weirdness in GeoManager where GM puts up modal dialog
	; when processing end-move-copy and cursor remains with XOR region)
	; - brianc 3/8/93
	;
	cmp	ax, MSG_META_END_MOVE_COPY
	jne	sendToThisMouseGrab
	mov	bx, -1			; we have an active grab
	clc				; don't check quick-transfer status
	call	ClipboardHandleEndMoveCopy	; clean-up
	jmp	sendToThisMouseGrab

sendDragOther:
	mov	ax, MSG_META_DRAG_OTHER

sendToThisMouseGrab:

	; Send the mouse data on to the appropriate object
	;
					; save destination
	push	ds:[di].VMG_object.handle
	push	ds:[di].VMG_object.chunk

	push	bp
	call	VisSendMouseDataToGrab
	pop	bp
	test	bx, mask MRF_REPLAY
	jz	done			; If no replay request, we're done.

	; Get active/implied VisMouseGrab ptr in ds:di
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, offset VCNI_activeMouseGrab
	tst	ds:[di].VMG_object.handle
	jnz	20$
	add	di, offset VCNI_impliedMouseGrab - offset VCNI_activeMouseGrab
20$:

	; REPLAY's are only allowed when destination OD changes.
	;
	push	bp
	mov	bp, sp		; get ptr to stack frame
	mov	ax, ds:[di].VMG_object.handle
	cmp	ax, ss:[bp+4]
	jne	30$		; if change, allow replay
	mov	ax, ds:[di].VMG_object.chunk
	cmp	ax, ss:[bp+2]
	jne	30$		; if change, allow replay
				; if same OD, don't replay, would be a waste
				;	& possibly causing looping
	andnf	bx, not mask MRF_REPLAY
30$:
	pop	bp

done:
	add	sp, 4			; fix stack
	.leave
	ret

VisSendMouseDataToActiveOrImpliedGrab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisContentTransformCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine transforms a point from the IsoContent's
		coordinate system to the destination coordinate system.

CALLED BY:	GLOBAL
PASS:		cx, dx - point
		di - destination window handle
RETURN:		carry set if window is being destroyed
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisContentTransformCoords	proc	near	uses	bx
	.enter
	tst	di
	jz	exit		; if no window, no adjustment

				; Convert from screen to window coords (???)
EC <	xchg	bx, di						>
EC <	call	ECCheckWindowHandle				>
EC <	xchg	bx, di						>

	push	ax		; save ax only -- OK to trash bx
	push	cx, dx		; Save pointer's screen coords
	call	WinGetWinScreenBounds
				; Returns carry set if window is being
				; destroyed
	pop	cx, dx		; Restore pointer's screen coords


	pushf
	sub	cx, ax		; And make relative to window origin
	sub	dx, bx
	popf
	pop	ax
exit:
	.leave
	ret
VisContentTransformCoords	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisSendMouseDataToGrab

DESCRIPTION:	Send mouse event to VisMouseGrab passed

CALLED BY:	INTERNAL
		VisContentMouseEvent

PASS:		*ds:si 	- VisContentClass object
		ds:di	- ptr to VisMouseGrab

		ax 	- 16-bit mouse event
		cx, dx	- incoming mouse location
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:		bx	- data returned from object in ax
		bp 	- data returned from object

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

VisSendMouseDataToGrab	proc	near
	class	VisContentClass

	tst	ds:[di].VMG_object.handle
	jne	afterNullODTest	; Make sure destination OD exists

	; If no destination OD, send message to ourselves (to allow
	; interception), to deal with an unwanted mouse event.  The default
	; action for contents is to FUP the character up; OLApplication class
	; will beep instead.

	push	ax, cx, dx
	mov	cx, ds		; Copy ptr to VisMouseGrab to cx:dx
	mov	dx, di
	mov	ax, MSG_VIS_CONTENT_UNWANTED_MOUSE_EVENT
	call	ObjCallInstanceNoLock
	mov_tr	bx, ax		; Copy return flags to bx
	pop	ax, cx, dx
	ret


afterNullODTest:

	; See if ptr event -- if so, see if grab is interested or not
	;
	cmp	ax, MSG_META_PTR
	jne	continue

	test	ds:[di].VMG_flags, mask VIFGF_PTR
	jnz	continue

	clr	bx		; exit will bx = 0 if PTR data not requested
	ret

exitWithoutSending:

	pop	di		; restore offset to grab

	pop	ax, cx, dx

	clr	bx		; exit w/ null MouseReturnFlags
	ret

;------------------------------------------------------------------------------
;	Pre-processing
;------------------------------------------------------------------------------

continue:
	push	ax, cx, dx

	; Adjust mouse position for window that grab resides in
	;
	push	di		; Save offset to grab
				; Get window that grab object sits in
	mov	di, ds:[di].VMG_gWin
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	cmp	di, ds:[bx].VCI_window
	je	afterUnTransform	; if same as IsoContent, no adjustment
					 ; necessary.

	call	VisContentTransformCoords
	jc	exitWithoutSending


afterUnTransform:
	mov	bx, di		; Copy window handle to bx...
	pop	di		; Restore offset to grab

	push	bx		; Save window handle for end of routine

	; Does the current mouse grab require LARGE mouse events?
	;
	test	ds:[di].VMG_flags, mask VIFGF_LARGE
	LONG jnz largeMouseGrab

;smallMouseGrab:
;---------------
				; *ds:si is VisContent

				; Convert to SMALL DOC event
	call	ConvertSmallWinMouseEventToSmallDoc

				; Now, send mouse data to current grab
				; Fetch grab OD, in ^lbx:si

				; But watch out for sending to this object!
				; (We'd loop forever if we didn't check for
				;  this)
	mov	bx, ds:[di].VMG_object.handle
	cmp	bx, ds:[LMBH_handle]
	jne	goOn
	cmp	si, ds:[di].VMG_object.chunk
	je	specialCaseThisObject
goOn:
	push	si		; Preserve chunk of VisContent object

				; Check to see if destination is in same
				; window as the implied grab (see explanation
				; below)
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].VCNI_impliedMouseGrab.VMG_gWin
	cmp	si, ds:[di].VMG_gWin

	; zero flag now result of above test

	mov	si, ds:[di].VMG_object.chunk

	call	ObjSwapLock
EC <	pushf							>
EC <	call	VisCheckVisAssumption				>
EC <	popf							>

	pushf
				; But first, set flag if mouse is within
				; bounds of object
	and	bp, not ((mask UIFA_IN) shl 8)
	popf
	jne	outside		; If mouse is actually in a different window
				; than the window this object is in, force
				; UIFA_IN to be clear regardless of whether
				; mouse is within visible bounds or not.  This
				; case can occur when another window covers
				; part of the visible object, or the parent
				; window, in the case of the view, clips
				; the visible object.  We want to pass
				; UIFA_IN as clear, so that gadgets implementing
				; wandering grabs, such as for global quick-
				; transfers, will release the grab if the
				; mouse wanders into another window, regardless
				; of whether it is still in the visible
				; bounds of the object or not.   -- Doug 3/92

	call	VisTestPointInBounds
	jnc	outside
	or	bp,(mask UIFA_IN) shl 8
outside:
				; We can then do a straight object call
	call	ObjCallInstanceNoLock

EC <	; Make sure returned MouseReturnFlags are valid.  If code 	>
EC <	; crashes here, the object in *ds:si has returned bad flags.	>
EC <	;								>
EC <	test	ax, not mask MouseReturnFlags				>
EC <	ERROR_NZ	UI_ILLEGAL_MOUSE_RETURN_FLAGS			>

EC <	test	ax, mask MRF_SET_POINTER_IMAGE				>
EC <	jz	10$							>
EC <	tst	cx							>
EC <	jz	10$							>
EC <	xchg	bx, cx							>
EC <	call	ECCheckMemHandle					>
EC <	xchg	bx, cx							>
EC <10$:								>

	call	ObjSwapUnlock
	pop	si		; Restore chunk of VisContent object
	jmp	short done


specialCaseThisObject:
;----------------------
	; That is, unless sending passive grabs, in which case change
	; our minds back & send as usual.
	;
	cmp	ax, MSG_META_PRE_PASSIVE_BUTTON
	je	goOn
	cmp	ax, MSG_META_POST_PASSIVE_BUTTON
	je	goOn

	; If the grab object IS the IsoContent, we can't send small mouse
	; events to ourselves, or we'd loop forever.  Instead, do equivalent
	; of calling superclass:
	;
	call	VisCallChildUnderPoint

EC <	; Make sure returned MouseReturnFlags are valid.  If code 	>
EC <	; crashes here, some object below the content, & under the 	>
EC <	; mouse, has returned bad flags.				>
EC <	;								>
EC <	test	ax, not mask MouseReturnFlags				>
EC <	ERROR_NZ	UI_ILLEGAL_MOUSE_RETURN_FLAGS			>

EC <	test	ax, mask MRF_SET_POINTER_IMAGE				>
EC <	jz	20$							>
EC <	xchg	bx, cx							>
EC <	call	ECCheckMemHandle					>
EC <	xchg	bx, cx							>
EC <20$:								>
	jmp	short done

largeMouseGrab:
;--------------
				; *ds:si is VisContent
	push	si		; Preserve chunk of VisContent object
	sub	sp, size LargeMouseData		; Set up stack frame
	mov	bx, bp				; Pass flags on in bx
	mov	bp, sp
				; Convert to LARGE DOC event
	call	ConvertSmallMouseEventToLarge
				; Now, send mouse data to current grab
				; Fetch grab OD, in ^lbx:si
	mov	bx, ds:[di].VMG_object.handle
	mov	si, ds:[di].VMG_object.chunk

	call	ObjSwapLock
EC <	call	VisCheckVisAssumption				>
				; We can then do a straight object call
	call	ObjCallInstanceNoLock

EC <	; Make sure returned MouseReturnFlags are valid.  If code 	>
EC <	; crashes here, the object in *ds:si has returned bad flags.	>
EC <	;								>
EC <	test	ax, not mask MouseReturnFlags				>
EC <	ERROR_NZ	UI_ILLEGAL_MOUSE_RETURN_FLAGS			>
	call	ObjSwapUnlock

	add	sp, size LargeMouseData		; Remove stack frame
	pop	si		; Restore chunk of VisContent object

;------------------------------------------------------------------------------
;	Tail end processing
;------------------------------------------------------------------------------

done:
	pop	bx		; get window that object was on
	xchg	bx, di
	tst	di
	jz	noPointerChange

	; test for pointer image change
	;
	test	ax, mask MRF_SET_POINTER_IMAGE
	jnz	setPointer
	test	ax, mask MRF_CLEAR_POINTER_IMAGE
	jz	noPointerChange
	clr	cx			; clear pointer image
	clr	dx

setPointer:
	push	bp			; save return value from grab object
	mov	bp, PIL_GADGET
	call	WinSetPtrImage
	pop	bp

noPointerChange:

	xchg	bx, ax		; Return MouseReturnFlags in bx
	mov_tr	di, ax		; restore ptr to VisMouseGrab


	pop	ax, cx, dx	; Restore registers, to fix stack & be prepared
				; for any replay required
	ret

VisSendMouseDataToGrab	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertSmallMouseEventToLarge

DESCRIPTION:	Convert incoming mouse location to 32-bit integer, 16 bit
		fractional, translated document coordinates

CALLED BY:	INTERNAL
		VisContentMouseEvent

PASS:	*ds:si 	- VisContentClass object
	ds:di	- VisMouseGrab

	ax 	- 16-bit mouse event
	bx	- mouse flags (passed in bp in 16-bit mouse events)
	cx, dx	- incoming mouse location
	ss:bp	- ptr to empty LargeMouseData frame on stack

RETURN: ax	- equivalent LARGE mouse event
	dx	- size LargeMouseData
	ss:bp	- ptr to 32-bit LargeMouseData on stack

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version, required for 32-bit contents

------------------------------------------------------------------------------@

ConvertSmallMouseEventToLarge	proc	near	uses	bx, si
	class	VisContentClass
	.enter
	mov	si, ds:[si]			; Deref VisContentInstance
	add	si, ds:[si].Vis_offset
						; Convert std message to LARGE
						; message
	call	ConvertSmallMouseMethodToLarge
	push	ax				; preserve message
	mov	word ptr ss:[bp].LMD_buttonInfo, bx	; copy up flags

	; NOW, convert 16-bit data to 32-bit data
	;
	push	cx				; save x position

	mov	bx, offset PD_y - offset PD_x	; Do Y data
	call	ConvertWinToDWFixed		; generate the big 32.16 number
						; store into stack frame
	mov	ss:[bp].LMD_location.PDF_y.DWF_int.high, ax
	mov	ss:[bp].LMD_location.PDF_y.DWF_int.low, dx
	mov	ss:[bp].LMD_location.PDF_y.DWF_frac, cx

	pop	dx				; get x position back in dx
	clr	bx				; Do X data
	call	ConvertWinToDWFixed		; generate the big 32.16 number
						; store into stack frame
	mov	ss:[bp].LMD_location.PDF_x.DWF_int.high, ax
	mov	ss:[bp].LMD_location.PDF_x.DWF_int.low, dx
	mov	ss:[bp].LMD_location.PDF_x.DWF_frac, cx

	pop	ax				; restore message
	mov	dx, size LargeMouseData		; return dx value
	.leave
	ret

ConvertSmallMouseEventToLarge	endp



ConvertSmallMouseMethodToLarge	proc	near
	class	VisContentClass
	cmp	ax, MSG_META_QUERY_IF_PRESS_IS_INK
	je	handleInkQuery
EC <	; make sure a legal, convertible mouse event			>
EC <	cmp	ax, MSG_META_PTR						>
EC <	je	ok							>
EC <	cmp	ax, MSG_META_START_SELECT					>
EC <	jb	error							>
EC <	cmp	ax, MSG_META_DRAG_OTHER					>
EC <	jbe	ok							>
EC <error:								>
EC <	ERROR	UI_NON_MOUSE_EVENT					>
EC <ok:									>

	add	ax, MSG_META_LARGE_PTR - MSG_META_PTR	; assume ptr event
	cmp	ax, MSG_META_LARGE_PTR
	je	haveLargeEvent			; continue if correct
						; otherwise, correct mistake
						; & adjust for other events
	add	ax, MSG_META_PTR - MSG_META_LARGE_PTR + \
		    MSG_META_LARGE_START_SELECT - MSG_META_START_SELECT
haveLargeEvent:
	ret

handleInkQuery:
	mov	ax, MSG_META_LARGE_QUERY_IF_PRESS_IS_INK
	jmp	haveLargeEvent

ConvertSmallMouseMethodToLarge	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertSmallWinMouseEventToSmallDoc

DESCRIPTION:	Convert incoming mouse location to 16-bit translated
		document coordinates

CALLED BY:	INTERNAL
		VisContentMouseEvent

PASS:	*ds:si 	- VisContentClass object
	ds:di	- VisMouseGrab

	cx, dx	- incoming mouse location

RETURN: cx, dx	- 16-bit mouse location, in translated document coordinates

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version, required for 32-bit contents

------------------------------------------------------------------------------@

ConvertSmallWinMouseEventToSmallDoc	proc	near
	class	VisContentClass

	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset

	; Check to see which incoming mouse event model in use
	;
	test	ds:[si].VCNI_attrs, mask VCNA_WINDOW_COORDINATE_MOUSE_EVENTS
	jz	sourceIsInDocCoords

;sourceIsInWinCoords:
	push	ax, bx

	push	cx				; save x position
	mov	bx, offset PD_y - offset PD_x	; Do Y data
	call	ConvertWinToDWFixed		; generate the big 32.16 number
						; dx is y doc position

	pop	cx				; get back x win position

	push	dx				; preserve dx
	mov	dx, cx
	clr	bx				; Do X data
	call	ConvertWinToDWFixed		; generate the big 32.16 number
	mov	cx, dx				; put result into cx
	pop	dx				; restore dx

	pop	ax, bx

	pop	si
	ret

sourceIsInDocCoords:
	; All that must be done is to translate the 16-bit doc coords.
	; Translations must be in signed 16-bit range for small doc models,
	; so only lower word need be subtracted off.
	;
	sub	cx, ds:[di].VMG_translation.PD_x.low
	sub	dx, ds:[di].VMG_translation.PD_y.low
	pop	si
	ret

ConvertSmallWinMouseEventToSmallDoc	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertWinToDWFixed

DESCRIPTION:	Convert 16-bit coord to 32-bit integer, 16-bit fractional
		translated document coordinates

CALLED BY:	INTERNAL
		ConvertSmallMouseEventToLargeMouseEvent

PASS:		ds:si 	- instance data  (YES, a direct pointer -- no deref
					  necessary)
		ds:di	- VisMouseGrab
		es     	- segment of VisContentClass
		dx	- incoming mouse location
		bx	- 0 for X position, or
			  offset PD_y - offset PD_x for Y position

RETURN: 	ax:dx.cx	- <32-bit integer>.<16-bit fraction> result

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version, required for 32-bit contents

------------------------------------------------------------------------------@

ConvertWinToDWFixed	proc	near
	class	VisContentClass

	; Check to see which incoming mouse event model in use
	;
	test	ds:[si].VCNI_attrs, mask VCNA_WINDOW_COORDINATE_MOUSE_EVENTS
	jz	sourceIsInDocCoords

	push	si, di
	add	si, bx			; 0, or offset from X data to Y data
	add	di, bx			; 0, or offset from X data to Y data

	; First, divide 16-bit window coordinate by the scale factor
	clr	cx			; no fraction
	mov	bx, ds:[si].VCNI_scaleFactor.PF_x.WWF_int
	mov	ax, ds:[si].VCNI_scaleFactor.PF_x.WWF_frac

	cmp	bx, 1			; If dividing by 1, save a bit of time
	jne	needToDivide
	tst	ax
	jz	afterDivide
needToDivide:
	call	GrSDivWWFixed		; result in dx:cx
afterDivide:

	; Then, add in the current 32-bit document origin
	mov_trash ax, dx		; ax <- mouse position
	cwd				; sign-extend into dx:ax
	xchg	ax, dx			; want ax:dx
	add	dx, ds:[si].VCNI_docOrigin.PD_x.low
	adc	ax, ds:[si].VCNI_docOrigin.PD_x.high

	; Finally, subtract off any translation amount requested by
	; implied/active grab
	sub	dx, ds:[di].VMG_translation.PD_x.low
	sbb	ax, ds:[di].VMG_translation.PD_x.high
	pop	si, di
	ret

sourceIsInDocCoords:
	push	di
	add	di, bx			; 0, or offset from X data to Y data

	clr	cx			; return no fractional part
	clr	ax			; assume positive

	; Subtract off any translation amount requested by
	; implied/active grab (must be 16-bit sign-extended value)
	sub	dx, ds:[di].VMG_translation.PD_x.low
	jns	done
	dec	ax			; flip sign of upper word
done:
	pop	di
	ret

ConvertWinToDWFixed	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentDisableHoldUpInput

DESCRIPTION:	Change input state to force allowance of input data to flow

PASS:		*ds:si  - instance data
		ds:di   - ptr to VisContentInstance
		es      - segment of VisContentClass
		ax      - MSG_VIS_CONTENT_DISABLE_HOLD_UP

RETURN:
		Nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
	Doug	5/91		Now a method
	Doug	7/91		Moved to VisContent
------------------------------------------------------------------------------@

VisContentDisableHoldUpInput	method	dynamic VisContentClass, \
			MSG_VIS_CONTENT_DISABLE_HOLD_UP
						; Disable hold-up for awhile
	ornf	ds:[di].VCNI_holdUpInputFlags, mask HUIF_HOLD_UP_MODE_DISABLED
	call	VisContentFlushHoldUpInputQueue	; Let 'er rip
	ret

VisContentDisableHoldUpInput	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentEnableHoldUpInput

DESCRIPTION:	Change input state to allow hold-up mode

PASS:		*ds:si  - instance data
		ds:di   - ptr to VisContentInstance
		es      - segment of VisContentClass
		ax      - MSG_VIS_CONTENT_ENABLE_HOLD_UP

RETURN:
		Nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
	Doug	5/91		Now a method
	Doug	7/91		Moved to VisContent
------------------------------------------------------------------------------@

VisContentEnableHoldUpInput	method	dynamic VisContentClass, \
			MSG_VIS_CONTENT_ENABLE_HOLD_UP
						; Disable hold-up for awhile
	andnf	ds:[di].VCNI_holdUpInputFlags, not mask HUIF_HOLD_UP_MODE_DISABLED
	ret

VisContentEnableHoldUpInput	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentHoldUpInput

DESCRIPTION:	Start holding up all UI input events, in a separate queue,
		until VisContentResumeInput is called  (A count is kept, so
		multiple patients can use)

PASS:		*ds:si  - instance data
		ds:di   - ptr to VisContentInstance
		es      - segment of VisContentClass
		ax      - MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW

RETURN:
		Nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
	Doug	5/91		Now a method
	Doug	7/91		Moved to VisContent
------------------------------------------------------------------------------@

VisContentHoldUpInput	method	dynamic VisContentClass, \
			MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW
	inc	ds:[di].VCNI_holdUpInputCount	; inc hold up count -- all
	ret					; input will start to be
						; redirected to the hold-up
						; queue
VisContentHoldUpInput	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentResumeInput

DESCRIPTION:	Allow UI input to flow again.

PASS:		*ds:si  - instance data
		ds:di   - ptr to VisContentInstance
		es      - segment of VisContentClass
		ax      - MSG_VIS_CONTENT_RESUME_INPUT_FLOW

RETURN:
		Nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
	Doug	5/91		Now a method
	Doug	7/91		Moved to VisContent
------------------------------------------------------------------------------@

VisContentResumeInput	method	dynamic VisContentClass, \
			MSG_VIS_CONTENT_RESUME_INPUT_FLOW
	dec	ds:[di].VCNI_holdUpInputCount	; dec hold up count -- if
						; back to 0, flush out
						; hold up queue & allow
						; input to proceed.
EC <	ERROR_S	UI_ERROR_NEGATIVE_HOLD_UP_INPUT_COUNT			>
	jnz	done
	call	VisContentFlushHoldUpInputQueue
done:
	ret

VisContentResumeInput	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	VisContentFlushHoldUpInputQueue

DESCRIPTION:	Flush the hold-up input queue by moving all events in it
		to the front of the UI queue, in order.

CALLED BY:	INTERNAL

PASS:		*ds:si	- VisContentInstance

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
------------------------------------------------------------------------------@

VisContentFlushHoldUpInputQueue	proc	near uses ax, bx, cx, dx, si, di
	class	VisContentClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; If hold-up mode is disabled (i.e. there is a system-modal dialog
	; box up & in progress), then let the queue flow regardless of any
	; hold-up modes in progress, so that the user can interact with
	; the system-modal dialog box.
	;
	test	ds:[di].VCNI_holdUpInputFlags, mask HUIF_HOLD_UP_MODE_DISABLED
	jnz	letErRip

	; If holding up UI input, we're done -- hold up must have been turned
	; back on while we weren't looking.
	;
	tst	ds:[di].VCNI_holdUpInputCount
	jnz	done

letErRip:
					; Direct events back to this object
	mov	cx, ds:[LMBH_handle]
	mov	dx, si

					; Save queue handle on stack
	push	ds:[di].VCNI_holdUpInputQueue

					; Null out reference to queue (we'll
					; destroy when done with it)
	mov	ds:[di].VCNI_holdUpInputQueue, 0

	clr	bx			; Get queue handle for this thread
					; 	(UI thread)
	call	GeodeInfoQueue
	mov	si, bx			; Put queue handle in si, as destination
					; queue for following routine

					; Setup hold up input queue as source
	pop	bx
	tst	bx			; If no queue, done.
	jz	done
					; Move all of these events to the
					; front of the UI queue
	mov	di, mask MF_INSERT_AT_FRONT
	call	GeodeFlushQueue

	; Finally, nuke the queue.  Instance reference has already been
	; zeroed, so we're all done.
	;
	call	GeodeFreeQueue
done:
	.leave
	ret

VisContentFlushHoldUpInputQueue	endp


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentConsumeMessage

DESCRIPTION:	Consume the event so that the superclass will NOT provide
		default handling for it.  Used to nuke requests to grab/
		release kbd & mouse, as the IsoContent has these by default
		from the view that it is in, regardless of whether or not
		the IsoContent has the focus or not -- these characteristics
		may no be changed by the programmer.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- message to eat

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

VisContentConsumeMessage	method	VisContentClass, \
						MSG_META_FORCE_GRAB_KBD,
						MSG_VIS_FORCE_GRAB_LARGE_MOUSE,
						MSG_VIS_FORCE_GRAB_MOUSE,
						MSG_META_GRAB_KBD,
						MSG_VIS_GRAB_LARGE_MOUSE,
						MSG_VIS_GRAB_MOUSE,
						MSG_META_RELEASE_KBD,
						MSG_VIS_RELEASE_MOUSE
	ret

VisContentConsumeMessage	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentUpdateFocusExcl

DESCRIPTION:	Provide standard behavior for focus node

		Handled specially here so we can just ignore them if
		no one has the focus yet.  If we let the messages through,
		the system will die since an object that doesn't have the focus
		can't be losing or gaining it, but the view sends these
		messages down with no knowledge of whether anything has the
		focus here.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_GAINED_FOCUS_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version

------------------------------------------------------------------------------@

VisContentUpdateFocusExcl	method	dynamic VisContentClass, \
				MSG_META_LOST_FOCUS_EXCL,
				MSG_META_LOST_SYS_FOCUS_EXCL,
				MSG_META_GAINED_FOCUS_EXCL,
				MSG_META_GAINED_SYS_FOCUS_EXCL

	mov	bp, MSG_META_GAINED_FOCUS_EXCL	; pass base message for focus
	mov	bx, offset Vis_offset
	mov	di, offset VCNI_focusExcl
	GOTO	FlowUpdateHierarchicalGrab
VisContentUpdateFocusExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentUpdateTargetExcl

DESCRIPTION:	Provide standard behavior for target node

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_META_GAINED_TARGET_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version

------------------------------------------------------------------------------@

VisContentUpdateTargetExcl	method	VisContentClass, \
					MSG_META_GAINED_TARGET_EXCL,
					MSG_META_GAINED_SYS_TARGET_EXCL,
					MSG_META_LOST_SYS_TARGET_EXCL
	mov	bp, MSG_META_GAINED_TARGET_EXCL	; pass base message for target
	mov	bx, offset Vis_offset
	mov	di, offset VCNI_targetExcl
	GOTO	FlowUpdateHierarchicalGrab
VisContentUpdateTargetExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		VisContentLostTargetExcl -- MSG_META_LOST_TARGET_EXCL

DESCRIPTION:	Default lost target behavior plus update of view

PASS:
		*ds:si - instance data
		es - segment of MetaClass
		ax - MSG_META_LOST_TARGET_EXCL
		bp	- HierarchicalGrabFlags

RETURN:
	nothing
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@


VisContentLostTargetExcl	method	VisContentClass, \
						MSG_META_LOST_TARGET_EXCL

	call	VisContentUpdateTargetExcl	;Common node behavior

	call	ViewUpdateContentTargetInfo	;reset the target in the view
						;which was temporarily zeroed
						;by FlowLostExcl calling
						;VUP_ALTER_ (target) EXCL
	Destroy	ax, cx, dx, bp
	ret

VisContentLostTargetExcl	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentAlterFTVMCExcl

DESCRIPTION:	Grab/Release Focus/Target exclusive

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_MUP_ALTER_FTVMC_EXCL

	^cx:dx	- OD to grab/release exclusive for
	bp	- MetaAlterFTVMCExclFlags

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
	Doug	9/91		Initial version

------------------------------------------------------------------------------@


VisContentAlterFTVMCExcl	method	VisContentClass, \
					MSG_META_MUP_ALTER_FTVMC_EXCL

	; The content is not allowed to grab grabs for itself. In
	; a sense it always hass all grab because the view sends
	; it everything. If the content did grab a grab it could
	; end up in an infinite loop sending messages to itself.
	;
EC <	test	bp, mask MAEF_FOCUS or mask MAEF_TARGET			>
EC <	jz	10$							>
EC <	test	bp, mask MAEF_NOT_HERE					>
EC <	ERROR_NZ	UI_VIS_CONTENT_CAN_NOT_GRAB_OR_RELEASE_THIS_EXCL >
EC <10$:								>

next:
	; If no requests for operations left, exit
	;
	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done

	; Check for requests we can handle
	;

	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	mov	bx, mask MAEF_FOCUS
	mov	di, offset VCNI_focusExcl
	test	bp, bx
	jnz	doHierarchy

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset VCNI_targetExcl
	test	bp, bx
	jnz	doHierarchy

;callSuper:
	; Pass message on to superclass for handling of other hierarhies
	;
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock

doHierarchy:
	push	bx, bp
	and	bp, mask MAEF_GRAB
	or	bp, bx			; or back in hierarchy flag
	mov	bx, offset Vis_offset
	call	FlowAlterHierarchicalGrab
	pop	bx, bp

	cmp	bx, mask MAEF_TARGET	; if target changed, update content
	jne	afterUpdateContentTargetInfo
	call	ViewUpdateContentTargetInfo
afterUpdateContentTargetInfo:

	not	bx			; get not mask for hierarchy
	and	bp, bx			; clear request on this hierarchy
	jmp	short next

done:
	Destroy	ax, cx, dx, bp
	ret

VisContentAlterFTVMCExcl	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	ViewUpdateContentTargetInfo

DESCRIPTION:	Find a block of memory of the given size and type.

CALLED BY:	INTERNAL
		VisContentGrabTargetExcl
		VisContentReleaseTargetExcl

PASS:
	*ds:si	- VisContent object

RETURN:
	Nothing

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

ViewUpdateContentTargetInfo	proc	far	uses ax, bx, cx, dx, di, bp
	class	VisContentClass
	.enter
					; Set up stack frame for call below
	sub	sp, size ViewTargetInfo
	mov	bp, sp

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

					; store content OD
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].VTI_content.TR_object.handle, bx
	mov	ss:[bp].VTI_content.TR_object.chunk, si

	push	di
	mov	di, ds:[si]		; store content's Class
	mov	cx, ds:[di].MB_class.segment
	mov	dx, ds:[di].MB_class.offset
	mov	ss:[bp].VTI_content.TR_class.segment, cx
	mov	ss:[bp].VTI_content.TR_class.offset, dx
	pop	di

					; Get new target OD, class
	push	si
	mov	bx, ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	mov	si, ds:[di].VCNI_targetExcl.FTVMC_OD.chunk
	mov	ss:[bp].VTI_target.TR_object.handle, bx	; store target OD
	mov	ss:[bp].VTI_target.TR_object.chunk, si	; store target OD
	clr	ax
	mov	ss:[bp].VTI_target.TR_class.handle, ax	; class not yet known
	mov	ss:[bp].VTI_target.TR_class.chunk, ax
	tst	bx
	jz	nullTarget
	mov	ax, MSG_META_GET_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	bp
	call	ObjMessage
	pop	bp
	mov	ss:[bp].VTI_target.TR_class.segment, cx	; store class
	mov	ss:[bp].VTI_target.TR_class.offset, dx
nullTarget:
	pop	si
					; Notify view of new target
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VCNI_view.handle
	mov	si, ds:[di].VCNI_view.chunk
	mov	dx, size ViewTargetInfo
	mov	ax, MSG_GEN_VIEW_UPDATE_CONTENT_TARGET_INFO
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	add	sp, size ViewTargetInfo
	.leave
	ret
ViewUpdateContentTargetInfo	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentGetFocus

DESCRIPTION:	Returns the current focus exclusive

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_GET_FOCUS_EXCL,
			  MSG_VIS_FUP_QUERY_FOCUS_EXCL

RETURN:		^lcx:dx - handle of object with focus
		bp 	- HierarchicalGrabFlags (Provided for
			  MSG_VIS_FUP_QUERY_FOCUS_EXCL only)
		carry	- set because msg has been responded to
			  (for MSG_META_GET_FOCUS_EXCL)
		ax	- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/90		Initial version

------------------------------------------------------------------------------@

VisContentGetFocus 	method dynamic VisContentClass, \
				MSG_META_GET_FOCUS_EXCL,
				MSG_VIS_VUP_QUERY_FOCUS_EXCL,
				MSG_VIS_FUP_QUERY_FOCUS_EXCL
	mov	cx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	mov	dx, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	mov	bp, ds:[di].VCNI_focusExcl.FTVMC_flags
	stc
	Destroy	ax
	ret
VisContentGetFocus	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentGetTarget

DESCRIPTION:	Returns the current target exclusive

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_GET_TARGET

RETURN:		^lcx:dx - handle of object with target
		ax, bp	- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/18/90		Initial version

------------------------------------------------------------------------------@

VisContentGetTarget 	method VisContentClass, MSG_META_GET_TARGET_EXCL
	mov	cx, ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	mov	dx, ds:[di].VCNI_targetExcl.FTVMC_OD.chunk
	Destroy	ax, bp
	ret
VisContentGetTarget	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisContentSendClassedEvent

DESCRIPTION:	Sends message to focus/target object.
		Any object (Including GenApplicationClass) that wants
		different behaviors for Focus & Target excl will have
		to intercept this method & do what they want to see done.


PASS:
	*ds:si - instance data
	es - segment of VisContentClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TravelOption

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

VisContentSendClassedEvent	method	VisContentClass, \
						MSG_META_SEND_CLASSED_EVENT

	cmp	dx, TO_FOCUS
	je	toFocus
	cmp	dx, TO_TARGET
	je	toTarget

	mov	di, offset VisContentClass
	GOTO	ObjCallSuperNoLock

toFocus:
	mov	bx, ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	mov	bp, ds:[di].VCNI_focusExcl.FTVMC_OD.chunk
	jmp	short toHere

toTarget:
	mov	bx, ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	mov	bp, ds:[di].VCNI_targetExcl.FTVMC_OD.chunk
toHere:
	clr	di
	call	FlowDispatchSendOnOrDestroyClassedEvent
	ret

VisContentSendClassedEvent	endm




COMMENT @----------------------------------------------------------------------

METHOD:		VisContentDefaultPassOnDownBehavior

DESCRIPTION:	Default behavior for misc. content MetaClass methods --
		methods listed for this handler are send on to the first
		target node/leaf below the VisContent, or if that is NULL,
		to the first visible child.   If apps need different
		behavior than this, they should subclass the method & do
		it themselves.

PASS:		*ds:si 	- instance data
		ds:di	- VisContentInstance
		es     	- segment of VisContentClass
		ax 	-

			  Track scrolling (MUST be responded to):

			  MSG_META_CONTENT_TRACK_SCROLLING

			  Large model implied mouse events.  Should go
			  to whatever layer the mouse is "over".  The default
			  behavior here is to presume that layers are
			  overlapping, & that the layer having the target is
			  the current "active" one.  If apps have side-by
			  size layers, they should intercept these messages
			  & send them to the layer that the mouse is over.

			  MSG_META_LARGE_PTR
			  MSG_META_LARGE_START_SELECT
			  MSG_META_LARGE_START_MOVE_COPY
			  MSG_META_LARGE_START_FEATURES
			  MSG_META_LARGE_START_OTHER
			  MSG_META_LARGE_DRAG_SELECT
			  MSG_META_LARGE_DRAG_MOVE_COPY
			  MSG_META_LARGE_DRAG_FEATURES
			  MSG_META_LARGE_DRAG_OTHER
			  MSG_META_LARGE_END_SELECT
			  MSG_META_LARGE_END_MOVE_COPY
			  MSG_META_LARGE_END_FEATURES
			  MSG_META_LARGE_END_OTHER

		cx, dx, bp - other message data, if any
				(not used here, but passed on)

RETURN:		?? (depends on message sent in)

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version, required for 32-bit contents

------------------------------------------------------------------------------@

VisContentDefaultPassOnDownBehavior 	method VisContentClass, \
					MSG_META_CONTENT_TRACK_SCROLLING, \
					MSG_META_LARGE_PTR, \
					MSG_META_LARGE_START_SELECT, \
				  	MSG_META_LARGE_START_MOVE_COPY, \
					MSG_META_LARGE_START_FEATURES, \
					MSG_META_LARGE_START_OTHER, \
					MSG_META_LARGE_DRAG_SELECT, \
					MSG_META_LARGE_DRAG_MOVE_COPY, \
					MSG_META_LARGE_DRAG_FEATURES, \
					MSG_META_LARGE_DRAG_OTHER, \
					MSG_META_LARGE_END_SELECT, \
					MSG_META_LARGE_END_MOVE_COPY, \
					MSG_META_LARGE_END_FEATURES, \
					MSG_META_LARGE_END_OTHER,
					MSG_META_LARGE_QUERY_IF_PRESS_IS_INK,
					MSG_META_CONTENT_ENTER,
					MSG_META_CONTENT_LEAVE

	call	CallTargetOrFirstChild
	jc	handled

EC <	; Blow up if TRACK_SCROLLING message, for it MUST be handled 	   >
EC <	cmp	ax, MSG_META_CONTENT_TRACK_SCROLLING		   	   >
EC <	ERROR_Z	UI_VIS_CONTENT_NEEDS_TO_HANDLE_TRACK_SCROLLING_BETTER  >

	; In case mouse message not handled, return NULL MouseReturnFlags
	;
	clr	ax

handled:
	ret

VisContentDefaultPassOnDownBehavior	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTargetOrFirstChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call w/the passed method/data to either the target, the first
		child, or else returns...

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to VisContent instance data
		ax - message to send
		cx, dx, bp - data for message
RETURN:		carry	= clear if no children or target
			= set if a child or target existed:
				ax, cx, dx, bp = return values of method called
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTargetOrFirstChild		proc	near
	class	VisContentClass
	uses	bx, si
	.enter

	;
	; First, see if there is a target object.  If so, send events there.
	;
	; This a reasonable thing to do for TRACK_SCROLLING, as this would be
	; the object that the user currently working with.
	;
	; LARGE mouse events arriving here are implied mouse events in a
	; LARGE vis tree,  in which case the target is normally the active
	; layer -- also reasonable default behavior
	;
	mov	bx, ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	tst	bx
	jz	noTarget
	mov	si, ds:[di].VCNI_targetExcl.FTVMC_OD.chunk
	jmp	common

	;
	; If not, send to first child so that things will work in simple,
	; one-child visible object models
	;
noTarget:
	mov	bx, ds:[di].VCI_comp.CP_firstChild.handle
	tst_clc	bx
	jz	exit

	mov	si, ds:[di].VCI_comp.CP_firstChild.chunk

common:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	stc

exit:
	.leave
	ret
CallTargetOrFirstChild		endp


VisCommon	ends
