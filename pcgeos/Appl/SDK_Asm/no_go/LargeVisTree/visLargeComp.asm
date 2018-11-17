COMMENT @-----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Large Vis Tree Sample Application
FILE:		visLargeComp.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VisLargeCompClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

DESCRIPTION:
	This file contains routines to implement the VisLargeCompClass.

	$Id: visLargeComp.asm,v 1.1 97/04/04 16:34:15 newdeal Exp $

-------------------------------------------------------------------------------@


VisLargeCompClass	class	VisCompClass

;------------------------------------------------------------------------------
;	Methods
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;	Constants & Structures
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;	Instance data
;------------------------------------------------------------------------------

VLCI_translation	PointDWord

VisLargeCompClass	endc



idata segment

; Declare the class record

	VisLargeCompClass		mask CLASSF_DISCARD_ON_SAVE

idata ends

;---------------------------------------------------

VisLargeComp segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		VisLargeCompVupCreateGState

DESCRIPTION:	Intercept METHOD_VUP_CREATE_GSTATE, so as to apply this
		large composite's 32-bit translation to it.  This way,
		should a child object request a GState, it will get one
		with a transformation matrix which shifts it into the 32-bit
		document space.

PASS:
		*ds:si - instance data
		ds:di	- ptr to VisLargeCompInstance
		es - segment of VisLargeCompClass
		ax - METHOD_VUP_CREATE_GSTATE

RETURN:	 	carry	- set, to indicate method handled
		bp 	- handle of GState,
		  	  which references window that object is realized under,
		  	  if any, otherwise references a NULL window.
		  	  Note that in all cases a GState is created, &
			  therefore will have to be destroyed by the caller
			  (Using GrDestroyState)

DESTROYED:	
	ax, bx, cx, dx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

VisLargeCompVupCreateGState	method	VisLargeCompClass, \
						METHOD_VUP_CREATE_GSTATE

	; First, call superclass to fetch the GState
	;
	mov	di, offset VisLargeCompClass
	call	ObjCallSuperNoLock

	; Then, apply our 32-bit translation to it.
	;
	call	ApplyTranslation

	stc
	ret

VisLargeCompVupCreateGState	endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisLargeCompDraw

DESCRIPTION:	Intercept METHOD_DRAW, so as to apply this large composite's
		32-bit translation to the GState passed, before it reaches
		the children..  This way, child objects will draw through a
		transformation matrix which shifts it into the 32-bit
		document space.

PASS:		*ds:si 	- instance data
		ds:di	- ptr to VisLargeCompInstance
		es     	- segment of VisLargeCompClass
		ax 	- METHOD_DRAW

		cl	- DrawFlags:  DF_EXPOSED set if GState is set to
			  update window
		bp	- GState to draw through.
		
RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

VisLargeCompDraw 	method VisLargeCompClass, METHOD_DRAW

	; Translate the GState passed by the 32-bit offset that this
	; LargeComposite resides at
	call	ApplyTranslation

	push	bp			; Preserve GState around call

if	(0)
; DOES NOT WORK YET, BECAUSE default METHOD_DRAW handler still uses
; WinGetMaskBounds.  This will need to change to use GrGetMaskBounds, once
; it exists.  Until then, we'll just send to all children.
;
;	; Call superclass, which will pass METHOD_DRAW on down to visible
;	; children.
;	mov	di, offset VisLargeCompClass
;	call	ObjCallSuperNoLock
else
	call	VisCallChildren
endif

	pop	bp

	; Undo the eariler translation, before returning GState to caller.
	call	UnApplyTranslation

	ret

VisLargeCompDraw	endm


ApplyTranslation	proc	near	uses	ax, bx, cx, dx, di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; Fetch 32-bit offset for this Large Composite, & apply as a translation
	; to the GState passed
	mov	dx, ds:[di].VLCI_translation.PD_x.high
	mov	cx, ds:[di].VLCI_translation.PD_x.low
	mov	bx, ds:[di].VLCI_translation.PD_y.high
	mov	ax, ds:[di].VLCI_translation.PD_y.low

	mov	di, bp
	call	GrApplyTranslationDWord
	mov	bp, di
	.leave
	ret

ApplyTranslation	endp

UnApplyTranslation	proc	near	uses	ax, bx, cx, dx, di
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; Fetch -(32-bit offset for this Large Composite), & apply as a
	; translation to the GState passed
	clr	ax
	clr	bx
	clr	cx
	clr	dx
	sub	dx, ds:[di].VLCI_translation.PD_x.high
	sbb	cx, ds:[di].VLCI_translation.PD_x.low
	sub	bx, ds:[di].VLCI_translation.PD_y.high
	sbb	ax, ds:[di].VLCI_translation.PD_y.low

	mov	di, bp
	call	GrApplyTranslationDWord
	mov	bp, di
	.leave
	ret

UnApplyTranslation	endp



COMMENT @----------------------------------------------------------------------

METHOD:		VisLargeCompVupGrabWithinView

DESCRIPTION:	Intercepts METHOD_VUP_GRAB_WITHIN_VIEW & applies 32-bit
		translation of this Large Composite for any mouse grab, then
		passes the method on to superclass.  This way, when a child
		object grabs the mouse, the VisContent object will adjust
		the mouse data to the 16-bit coordinates of the child, before
		the child gets the data.

PASS:		*ds:si 	- instance data
		ds:di	- ptr to VisLargeCompInstance
		es     	- segment of VisLargeCompClass
		ax 	- METHOD_VUP_GRAB_WITHIN_VIEW
		dx	- size VupGrabWithinViewData
		ss:bp	- ptr to VupGrabWithinViewData structure one stack

VupGrabWithinViewData	struct
	VGWVD_object		optr
	VGWVD_flags		VisContentGrabFlags
	VGWVD_translation	PointDWord
VupGrabWithinViewData	ends

VisContentGrabFlags	record
	VCGF_MOUSE:1	; set to grab/release mouse
	VCGF_KBD:1	; set to grab/release kbd
	VCGF_GRAB:1 	; set to grab, clear to release.
			;	grabbing takes affect only if no
			;	grab is currently in affect, unless
			;	FORCE bit is also set.
	VCGF_FORCE:1	; set to force grab
	VCGF_LARGE:1	; If VCGF_MOUSE, LARGE events requested
	:11
VisContentGrabFlags	end

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

VisLargeCompVupGrabWithinView method	VisLargeCompClass, \
						METHOD_VUP_GRAB_WITHIN_VIEW
	test	ss:[bp].VGWVD_flags, mask VCGF_MOUSE	; doing mouse?
	jz	done					; skip out if not
	test	ss:[bp].VGWVD_flags, mask VCGF_GRAB	; grabbing?
	jz	done					; skip out if not

	push	ax					; preserve method

	; Add in 32-bit X translation amount to the mouse translation variable
	;
	mov	ax, ds:[di].VLCI_translation.PD_x.low
	add	ss:[bp].VGWVD_translation.PD_x.low, ax
	mov	ax, ds:[di].VLCI_translation.PD_x.high
	adc	ss:[bp].VGWVD_translation.PD_x.high, ax

	; Add in 32-bit Y translation amount to the mouse translation variable
	;
	mov	ax, ds:[di].VLCI_translation.PD_y.low
	add	ss:[bp].VGWVD_translation.PD_y.low, ax
	mov	ax, ds:[di].VLCI_translation.PD_y.high
	adc	ss:[bp].VGWVD_translation.PD_y.high, ax

	pop	ax					; restore method

done:
	; Pass method, with adjusted translation data, on to superclass
	;
	mov	di, offset VisLargeCompClass
	GOTO	ObjCallSuperNoLock

VisLargeCompVupGrabWithinView endm



COMMENT @----------------------------------------------------------------------

METHOD:		VisLargeCompLargeMouseEvent

DESCRIPTION:	Handle implied mouse data (non-grabbed) by checking to see
		if mouse position is within the bounds of this large composite,
		& if so, passing on to 16-bit children as 16-bit mouse data.

PASS:		*ds:si 	- instance data
		ds:di	- ptr to VisLargeCompInstance
		es     	- segment of VisLargeCompClass
		ax 	- One of:	METHOD_LARGE_PTR
					METHOD_LARGE_START_SELECT
					METHOD_LARGE_START_MOVE_COPY
					METHOD_LARGE_START_FEATURES
					METHOD_LARGE_START_OTHER
					METHOD_LARGE_DRAG_SELECT
					METHOD_LARGE_DRAG_MOVE_COPY
					METHOD_LARGE_DRAG_FEATURES
					METHOD_LARGE_DRAG_OTHER
					METHOD_LARGE_END_SELECT
					METHOD_LARGE_END_MOVE_COPY
					METHOD_LARGE_END_FEATURES
					METHOD_LARGE_END_OTHER
		dx	- size of LargeMouseData
		ss:bp	- ptr to LargeMouseData structure on stack:

	LargeMouseData	struct
		LMD_location		PointDWFixed
		;
		; Mouse position in <32 bit integer>.<16 bit fraction> format
	
		LMD_buttonInfo		byte	; ButtonInfo

		LMD_uiFunctionsActive	UIFunctionsActive
		;
		; Additional data normally passed as part of mouse event in BP.
		; The data normally provided by the bit UIFA_IN is NOT provided
		; by PC/GEOS for LARGE mouse events.

	LargeMouseData	ends


RETURN:		ax	- MouseReturnFlags
 			  mask MRF_PROCESSED - if event processed by gadget.
					       See def. below.

 			  mask MRF_REPLAY    - causes a replay of the button
					       to the modified implied/active
					       grab.   See def. below.

			  mask MRF_SET_POINTER_IMAGE - sets the PIL_GADGET
			  level cursor based on the value of cx:dx:
			  cx:dx	- optr to PointerDef in sharable memory block,
			  OR cx = 0, and dx = PtrImageValue (Internal/im.def)

			  mask MRF_CLEAR_POINTER_IMAGE - Causes the PIL_GADGET
						level cursor to be cleared


DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

VisLargeCompLargeMouseEvent method	VisLargeCompClass, \
				      METHOD_LARGE_PTR, \
				      METHOD_LARGE_START_SELECT, \
				      METHOD_LARGE_START_MOVE_COPY, \
				      METHOD_LARGE_START_FEATURES, \
				      METHOD_LARGE_START_OTHER, \
				      METHOD_LARGE_DRAG_SELECT, \
				      METHOD_LARGE_DRAG_MOVE_COPY, \
				      METHOD_LARGE_DRAG_FEATURES, \
				      METHOD_LARGE_DRAG_OTHER, \
				      METHOD_LARGE_END_SELECT, \
				      METHOD_LARGE_END_MOVE_COPY, \
				      METHOD_LARGE_END_FEATURES, \
				      METHOD_LARGE_END_OTHER

	
	; Convert large mouse positions to 16-bit local coordinates.
	; Place in cx, dx, as in small mouse event methods
	;

	; start with X...
					; Get 32-bit doc location
	mov	dx, ss:[bp].LMD_location.PDF_x.DWF_int.low
	mov	cx, ss:[bp].LMD_location.PDF_x.DWF_int.high
					; Subtract off location of this
					; 	LargeComposite
	sub	dx, ds:[di].VLCI_translation.PD_x.low
	sbb	cx, ds:[di].VLCI_translation.PD_x.high

	mov	bx, offset VI_bounds.R_left  ; See if within left, right bounds
	call	CheckIfInBounds
	jc	exit			; if not, exit

	push	dx			; save 16-bit X result

	; then do Y...
					; Get 32-bit doc location
	mov	dx, ss:[bp].LMD_location.PDF_y.DWF_int.low
	mov	cx, ss:[bp].LMD_location.PDF_y.DWF_int.high
					; Subtract off location of this
					; 	LargeComposite
	sub	dx, ds:[di].VLCI_translation.PD_y.low
	sbb	cx, ds:[di].VLCI_translation.PD_y.high

	mov	bx, offset VI_bounds.R_top  ; See if within top, bottom bounds
	call	CheckIfInBounds
					; dx = 16-bit Y result
	pop	cx			; restore 16-bit X result to cx

	jc	exit			; if not in bounds vertically, exit

	; Get bp = ButtonInfo & UIFunctionsActive, as in small mouse events
	;
	mov	bp, word ptr ss:[bp].LMD_buttonInfo

	; Convert Large mouse method to Small mouse method

	cmp	ax, METHOD_LARGE_PTR	; Special case for METHOD_PTR, defined
	jne	notPtr			; in mouse.def
	mov	ax, METHOD_PTR
	jmp	short haveMethod

notPtr:
	add	ax, METHOD_START_SELECT - METHOD_LARGE_START_SELECT

haveMethod:
					; Set es:di = class ptr of our class
	mov	di, offset VisLargeCompClass
	call	ObjCallSuperNoLock	; Pass method onto superclass for
					;	standard handling.
	
exit:
	ret

VisLargeCompLargeMouseEvent endm



CheckIfInBounds	proc	near
	tst	cx
	jz	positiveNumber
;negativeNumber:
	cmp	cx, -1		; If high word anything other than 0 or -1,
	jne	outOfBounds	; out of bounds
	tst	dx
	jns	outOfBounds	; high bit of low word must match high word
	jmp	short have16BitOffset

positiveNumber:
	tst	dx
	js	outOfBounds	; high bit of low word must match high word
have16BitOffset:
	cmp	dx, ds:[di][bx]	; check against left/top
	jb	outOfBounds	; if below, then out of bounds

	cmp	dx, ds:[di][bx+R_right-R_left]	; check against right/bottom
	jae	outOfBounds	; if above, or even at (graphics sys rounding)
				; then out of bounds
;inBounds:
	clc			; Return carry clear, to indicate in bounds.
	ret

outOfBounds:
	stc			; Return carry, indicating position
	ret			; was found to be out of bounds.


CheckIfInBounds	endp


VisLargeComp ends
