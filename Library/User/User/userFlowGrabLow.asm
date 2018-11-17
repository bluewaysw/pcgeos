COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userFlowGrabLow.asm

ROUTINES:
	Name				Description
	----				-----------
	ForceGrabCommon
	RequestGrabCommon
	ReleaseGrabCommon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

DESCRIPTION:
	This file contains routines to handle input processing for the
	User Interface.

	$Id: userFlowGrabLow.asm,v 1.1 97/04/07 11:46:18 newdeal Exp $

-------------------------------------------------------------------------------@

FlowCommon segment resource

if	(0)

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddElementAtBeginningOfGrabList

DESCRIPTION:	Adds Grab element to the front of a grab list, unless grab
		already is in list, in which case no new grab is added.

CALLED BY:	INTERNAL

PASS:	*ds:si	- flow object
	bx	- offset from instance start to PassiveGrabList data
	cx:dx	- OD of grab to add
	di	- window for grab

RETURN:
	Nothing

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

AddElementAtBeginningOfGrabList	proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	bp

	push	bx
	push	di
	call	FindGrabElement		; See if passive grab already set up
	pop	di
	pop	bx
	jc	AEGL_80			; If so, quit, already have passive

	mov	ax, di			; put window handle (if any) in ax
	mov	di, bx			; put offset to PassiveGrabList in bx 

	add	di, ds:[si]			; get ptr to passive grab list
	mov	bx, ds:[di].PGL_chunk		; get chunk handle of list
	mov	bx, ds:[bx]			; get ptr to list
	mov	bp, bx
	add	bp, ds:[di].PGL_tailOffset	; get ptr past last element

	push	ax
	push	cx
	push	dx
	mov	cx, bp			; figure out amount of data to move
	sub	cx, bx
	jz	AEGL_60			; skip if nothing to move
AEGL_55:
	mov	al, ds:[bp - 1]
	mov	ds:[bp + size Grab -1], al
	dec	bp
	loop	AEGL_55
AEGL_60:
	pop	dx
	pop	cx
	pop	ax

	; ds:[bx] is new, first element

	mov	ds:[bx].MG_OD.handle, cx	; store new element's data
	mov	ds:[bx].MG_OD.chunk, dx	; store new element's data
	mov	ds:[bx].MG_gWin, ax
	add	ds:[di].PGL_tailOffset, size Grab	; move up tail ptr

						; If we're in the middle of
						; sending to this passive grab
						; list, then let's move up the
						; cur point to prevent sending
						; to the same element twice.
						; NOTE:  If not in the middle
						; of sending, this line will
						; have no effect, as curOffset
						; is zero'd at the start of
						; such actions.
	add	ds:[di].PGL_curOffset, size Grab

	mov	ax, ds:[di].PGL_tailOffset	; get current tail offset
	add	ax, GRAB_LIST_HEADROOM		; amount of leftover headroom
						; required
	mov	bx, ds:[di].PGL_chunk		; get chunk handle of list
	ChunkSizeHandle	ds, bx, cx		; get current size of list
	cmp	ax, cx				; see if will fit in chunk
	jbe	AEGL_80				; if will fit, then all done
						; if not, grow it
	add	ax, GRAB_LIST_GROW_SIZE-GRAB_LIST_HEADROOM
	mov	cx, ax
	mov	ax, bx
	call	LMemReAlloc
AEGL_80:
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret

AddElementAtBeginningOfGrabList	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	RemoveElementFromGrabList

DESCRIPTION:	Delete an element from a grab list

CALLED BY:	INTERNAL

PASS:	*ds:si	- flow object
	bx	- offset from instance start to PassiveGrabList data
	cx:dx	- OD of grab to remove

RETURN:
	Carry	- set if element found & removed, clear if wasn't in list

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

RemoveElementFromGrabList	proc	near
	push	ax
	push	cx
	push	dx
	push	si
	push	di
	push	bp

	call	FindGrabElement
	jnc	REGL_100		; quit if not in 

					; ds:di - ptr to PassiveGrabList struct
					; ds:bx - ptr to element
					; ds:bp - ptr past end of list

					; Delete element from list.
	mov	dx, bx			; keep offset here for later

	mov	cx, bp			; figure out amount of data to move
	sub	cx, bx
	sub	cx, size Grab
	or	cx, cx
	jz	REGL_60			; skip if nothing to move
REGL_55:				; shift down
	mov	al, ds:[bx + size Grab]
	mov	ds:[bx], al
	inc	bx
	loop	REGL_55
REGL_60:
	sub	ds:[di].PGL_tailOffset, size Grab	; fix tail offset
	mov	bx, ds:[di].PGL_chunk
	sub	dx, ds:[bx]			; convert element ptr to offset
	cmp	dx, ds:[di].PGL_curOffset	; see if deleting at or below
						; 	current element
	jg	REGL_70				; if above, then all OK
	sub	ds:[di].PGL_curOffset, size Grab; otherwise, fix current offset
REGL_70:

	stc				; show removed
REGL_100:
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	ax
	ret

RemoveElementFromGrabList	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	FindGrabElement

DESCRIPTION:	Look for element in a grab list

CALLED BY:	INTERNAL

PASS:	*ds:si	- flow object
	bx	- offset from instance start to PassiveGrabList structure
	cx:dx	- OD of grab to find

RETURN:
	If carry set:	ds:bx is pointer to element
	If carry clear:  element not found

	ds:di	- ptr to PassiveGrabList structure
	ds:bp	- ptr to end of grab list

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

FindGrabElement	proc	near
	mov	di, bx				; Put offset into di
	add	di, ds:[si]			; get ptr to passive grab list
	mov	bx, ds:[di].PGL_chunk		; get chunk handle of list
	mov	bx, ds:[bx]			; get ptr to list
	mov	bp, bx
	add	bp, ds:[di].PGL_tailOffset	; get ptr to end of list
FGE_10:
	cmp	bx, bp				; make sure an element left to
						;	check
	jae	FGE_90				; if not, then done, not in
						;	list
	cmp	cx, ds:[bx].MG_OD.handle	; a match?
	jne	FGE_20				; if not, try next element
	cmp	dx, ds:[bx].MG_OD.chunk	; a match?
	je	FGE_50				; if so, branch out of search
FGE_20:
	add	bx, size Grab			; move to next element
	jmp	short FGE_10
FGE_50:
					; ds:bx points to matched element
	stc					; return found
	ret
FGE_90:
	clc					; return not found
	ret

FindGrabElement	endp
endif


FlowCommon ends


Resident segment resource

if	(0)

COMMENT @----------------------------------------------------------------------

FUNCTION:	ForceGrabCommon

DESCRIPTION:	Common library routine handler which
		forces old grab owner out, & new in, sending GAIN & LOST 
		exclusive methods.

CALLED BY:	INTERNAL

PASS:	di	- offset to BasicGrab struct within object
	cx:dx	- OD to match with
	bp	- extra data to store w/grab

RETURN:
	carry	- set if grab OD changed, & therefore methods were sent out

DESTROYED:
	bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
------------------------------------------------------------------------------@

ForceGrabCommon	proc	near
				; bp is offset to BasicGrab part
				; cx:dx, bx data
	push	bx
	push	si
	push	ds
	call	LockFlowObj
	clr	bx		; no Master part
	call	FlowForceGrab
	pop	ds
	pop	si
	pop	bx
	call	UnlockFlowObj
	ret

ForceGrabCommon	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	RequestGrabCommon

DESCRIPTION:	Common library routine handler which
		allows setting of new grab, if no one has it currently.
		New owner is sent GAIN method.

CALLED BY:	INTERNAL

PASS:	di	- offset to BasicGrab within flow object
	cx:dx	- OD to match with
	bp	- extra data to store w/grab

RETURN:
	carry	- set if grab OD changed, & therefore methods were sent out

DESTROYED:
	bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
------------------------------------------------------------------------------@

if	(0)
RequestGrabCommon	proc	near
	push	bx
	push	si
	push	ds
	call	LockFlowObj
	clr	bx		; no Master part
	call	FlowRequestGrab
	pop	ds
	pop	si
	pop	bx
	call	UnlockFlowObj
	ret

RequestGrabCommon	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	ReleaseGrabCommon

DESCRIPTION:	Common library routine handler which
		releases current grab, if caller's OD matches current grab.
		Owner is sent LOST method.

CALLED BY:	INTERNAL

PASS:	di	- offset to BasicGrab within flow object
	cx:dx	- OD to match with

RETURN:
	carry	- set if grab OD changed, & therefore methods were sent out

DESTROYED:
	bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
------------------------------------------------------------------------------@

if	(0)
ReleaseGrabCommon	proc	near
	push	bx
	push	si
	push	ds
	call	LockFlowObj
	clr	bx		; no Master part
	call	FlowReleaseGrab
	pop	ds
	pop	si
	pop	bx
	call	UnlockFlowObj
	ret

ReleaseGrabCommon	endp
endif

Resident ends
