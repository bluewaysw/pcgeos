COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		imPtr.asm

AUTHOR:		Adam de Boor, Jan 28, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/28/91		Initial revision


DESCRIPTION:
	Routines dealing with the pointer image, driver, etc.
		

	$Id: imPtr.asm,v 1.1 97/04/05 01:17:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImSetPtrWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets window that mouse ptr moves on.  The mouse will be
		limited to moving within that window.

CALLED BY:	EXTERNAL

PASS:		ax	- handle of driver for window
		bx	- handle of window on which mouse moves
		cx	- x coordinate of pointer in window
		dx	- y coordinate of pointer in window

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Need to redo XOR stuff if active (get exclusive in new
		driver, create new fake root, etc.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/4/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImSetPtrWin	proc	far
	push	ax, ds, di, bx, si
	mov	di, segment idata
	mov	ds, di
	;------------------------------------------------------------
	; 		Clean up previous pointer root
	;------------------------------------------------------------
	;
	; If we had a pointer driver before, tell the thing to shut off its
	; pointer before we lose track of who it was.
	;
	tst	ds:pointerDriver.segment
	jz	10$
	mov	di, DR_VID_HIDEPTR
	call	CallPtrDriver
10$:

	;------------------------------------------------------------
	; 		Set up current pointer root
	;------------------------------------------------------------
	;
	; Save the window and driver handle we were given
	; 
	mov	ds:[pointerWin], bx
	mov	ds:[pointerDriverHandle], ax
	push	cx		; Preserve new X and Y
	push	dx
	;
	; Figure the bounding rectangle for the window
	; 
	mov	di, bx
	call	WinGetWinScreenBounds
	mov	ds:[screenXMin], ax
	mov	ds:[screenYMin], bx
	mov	ds:[screenXMax], cx
	mov	ds:[screenYMax], dx

	;
	; Find the strategy routine for the driver that's running it.
	; 
	mov	si, WIT_STRATEGY
	call	WinGetInfo
	mov	ds:pointerDriver.segment, cx
	mov	ds:pointerDriver.offset, dx

	;
	; Move the new driver's pointer to where we were told it should be.
	; Note we do *not* call DR_VID_SHOWPTR. This is b/c the pointer image
	; may very well not have been updated for the new driver yet. We leave
	; the responsibility for actually displaying the pointer up to our
	; caller.
	; 
	pop	bx
	pop	ax
	mov	ds:pointerXPos, ax
	mov	ds:pointerYPos, bx

	mov	di, DR_VID_MOVEPTR
	call	CallPtrDriver		; & move ptr on screen

	;
	; Force all related variables to be updated.
	; 
	call	RefreshPtr

	pop	ax, ds, di, bx, si
	ret

ImSetPtrWin	endp

ObscureInitExit	ends

IMResident	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ImSetPtrImage

DESCRIPTION:	Allows changing the requested PointerDef for any PtrImageLevel,
		to "no pointer requested," the default ptr, or a specific
		pointer image.  The highest priority level requesting an image
		is granted the request, & the ptr image is passed on to the 
		video driver.

CALLED BY:	GLOBAL
		May not be called by interrupt code.  (See APP NOTE below)

PASS:		bp	- Ptr Image Level value, an integer from 0 to
			  IM_IM_NUM_PTR_IMAGE_LEVELS - 1 (Currently 0 to 9).
			  The lower the #, the higher the priority.  The
			  UI provides a PtrImageLevel enumerated type which
			  maps to the 0 to 9 values -- the IM doesn't care
			  what they are, it just manages 10 slots.

		cx:dx	- optr to PointerDef in sharable memory block, OR
			  cx = 0, and dx = PtrImageValue (see Internal/im.def)

		NOTE:  if cx = 0, dx = PIV_UPDATE, bp is not used.


RETURN:	 	Nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:
	Uses instance data in idata:

    	ptrImages	byte	IM_IM_NUM_PTR_IMAGE_LEVELS * size PtrImage dup (?)
   	curPtrImage	PtrImage <>

PSEUDO CODE/STRATEGY:
	Store new far ptr to mouse image at level specified;
	Determine new current ptr based on priority levels;
	If final ptr has changed, call video driver to set it;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  This routine depends on the fact that the size of 
	PtrImage is 4.  It shifts the PtrImageLevel left 2 bits to get
	the offset into ptrImages.

	APP NOTE:  The PC/GEOS UI's GenSystemClass object provides
	MSG_GEN_SYSTEM_SET_PTR_IMAGE, which calls this routine, but
	under the UI thread.  Using ObjMessage to send this message to
	the system object is a way out for an interrupt routine to
	get the ptr image set, as it is not allowed to call this routine
	directly (Semaphores, video driver couldn't take it...)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version
	Doug	5/90		Moved from UI flow object to IM
------------------------------------------------------------------------------@


ImSetPtrImage	proc far
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

EC <	jcxz	10$		; skip if not handle			>
EC <	mov	bx, cx		; otherwise, check it..			>
EC <	call	ECCheckMemHandleFar					>
EC <10$:								>

	mov	ax, idata
	mov	ds, ax		; Set ds to point at our data segment

				; Grab routine semaphore
	PSem	ds, semPtrImage, idata

	tst	cx		; if setting real ptr image, do it.
	jnz	setNewPtr
	tst	dx
	jz	setNewPtr	; if setting NO ptr image, do it.
	cmp	dx, PIV_UPDATE
	jne	vidDriverPtr	; skip if not PIV_UPDATE
				; Invalidate current ptr image, so that it will
				; be force loaded again.
	mov	ds:[curPtrImage].handle, 0
	mov	ds:[curPtrImage].chunk, 0
	jmp	short useHighestPrioPtr

vidDriverPtr:
				; Must be default vid driver request
EC <	cmp	dx, PIV_VIDEO_DRIVER_DEFAULT			>
EC <	ERROR	IM_ERROR_BAD_PTR_IMAGE_VALUE			>

;;;	mov	cx, -1		; Store video driver default request
;;;	clr	dx		; internally with handle = -1.

setNewPtr:
				; STORE new ptr image ptr.
	shl	bp, 1		; Shift ptr level to get offset
	shl	bp, 1

				; quit if no change
	cmp	ds:[ptrImages][bp].PI_ptr.handle, cx
	jne	stuffIt
	cmp	ds:[ptrImages][bp].PI_ptr.chunk, dx
	LONG je	done
stuffIt:
	mov	ds:[ptrImages][bp].PI_ptr.handle, cx
	mov	ds:[ptrImages][bp].PI_ptr.chunk, dx

useHighestPrioPtr:
				; NOW, change ptr image in driver, if necessary
	mov	cx, IM_IM_NUM_PTR_IMAGE_LEVELS
	clr	bp

				; LOOP to find highest priority ptr image
levelLoop:
	tst	ds:[ptrImages][bp].PI_ptr.handle
	jnz	foundLevel
	add	bp, size PtrImage	; move to next
	loop	levelLoop		; try each level, in order of priority

	mov	bx, -1			; Else give up, pretend we found request
	jmp	thisHandle		; for default ptr

foundLevel:
					; Fetch the ptr image we should use
	mov	bx, ds:[ptrImages][bp].PI_ptr.handle
thisHandle:
	clr	si			; in case none, or default
	tst	bx
	jz	haveFullReference
	cmp	bx, -1
	je	haveFullReference
					; Otherwise, a real handle
					; Get the chunk
	mov	si, ds:[ptrImages][bp].PI_ptr.chunk
haveFullReference:

				; See if any change has occurred
	cmp	ds:[curPtrImage].handle, bx
	jne	setPtr
	cmp	ds:[curPtrImage].chunk, si
	je	done		; if not, skip calling video driver.

setPtr:
				; Change current ptr
	mov	ds:[curPtrImage].handle, bx
	mov	ds:[curPtrImage].chunk, si

	call	LockPtrImageCommon	; ds:si = ptr image, or si=-1 for def.
	call	SetPtrImageLow		; Change ptr image in video driver
	tst	bx
	jz	skipUnlock
	call	MemUnlock		; Unlock block having ptr image
skipUnlock:

done:					; Release routine semaphore
	mov	ax, idata		; & keep idata in es
	mov	ds, ax
	VSem	ds, semPtrImage, idata

	.leave
	ret

ImSetPtrImage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			LockPtrImageCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
PASS:		^lbx:si	- PointerDef to lock, or bx = -1 to use default
RETURN:		ds:si	- PointerDef, or si = -1 to use default
		bx	- handle of locked block, or 0 if none
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/9/93		Split out from ImSetPtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockPtrImageCommon	proc	far
	cmp	bx, -1			; check if default
	jne	afterDefaultCheck
	xchg	bx, si			; set bx=0, si=-1, for video driver
afterDefaultCheck:

	tst	bx
	jz	skipLock
	call	MemLock		; Lock block having ptr image
EC <	ERROR_C	IM_MEMLOCK_FAILURE					>
EC <	tst	ax							>
EC <	ERROR_Z	IM_MEMLOCK_FAILURE					>
	mov	ds, ax			; *ds:si is PtrDef
EC <	call	ECLMemValidateHandle					>
	mov	si, ds:[si]		; dereference
skipLock:
	ret

LockPtrImageCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPtrImageLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
		ImSetPtrImage
PASS:		ds:si	- PointerDef, or si = -1 for default pointer
		bx	- handle of PointerDef block, if locked, else 0
RETURN:		bx - preserved
DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/93		Pulled out, added show/hide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPtrImageLow	proc	near
	push	es
	mov	ax, idata		; & keep idata in es
	mov	es, ax
					; Skip if no driver to call
    	cmp	es:[pointerDriver].segment, 0
	je	afterDriver

EC <	cmp	si, -1							>
EC <	je	ok							>
EC <	push	ax							>
EC <	mov	ax, ds							>
EC <	tst	ax							>
EC <	pop	ax							>
EC <	ERROR_Z	IM_BAD_SETPTR_PARAMS					>
EC <ok:									>

	test	es:[imPtrFlags], mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	jnz	checkForHide
afterHide:

	push	bx, ds, si
	mov	di, DR_VID_SETPTR	; pass function to call
    	call	es:[pointerDriver]	; call driver strategy routine
	pop	bx, ds, si

	test	es:[imPtrFlags], mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	jnz	checkForShow
afterShow:

	;
	; don't bother if pointer is hidden
	;
	test	es:[imPtrStatus], mask PS_HIDING_PTR
	jnz	noReCenter

	; re-center pointer if auto-centering and button/pen is up
	tst	es:[buttonState]
	jnz	noReCenter		; no re-center if button/pen down

	tst	es:[autoCenterBoolean]
	jz	noReCenter

	push	bx
	call	TimerGetCount		; rtn bxax = count
	pop	bx			; just need low count
	ornf	ax, mask PI_absX or mask PI_absY  ; pen drive always uses
						  ; absolute co-ordinates
	mov_tr	bp, ax		; bp = PtrInfo

	; calculate center co-ordinates within restricted region
	mov	cx, es:screenXMax
	add	cx, es:screenXMin
	shr	cx
	mov	dx, es:screenYMax
	add	dx, es:screenYMin
	shr	dx			; (cx,dx) = center
	mov	ax, MSG_IM_PTR_CHANGE
	call	CallIM
noReCenter:

afterDriver:
	pop	es
	ret

;
;---
;

checkForShow:
	cmp	si, -1			; Don't need to show if default
	je	afterShow
	tst	bx			; Don't need to show if no cursor
	jz	afterShow
					; Skip if show not requested
	test	ds:[si].PD_width, mask PDW_ALWAYS_SHOW_PTR
	jz	afterShow

	call	ShowPtrCommon
	jmp	short afterShow

;
;---
;
checkForHide:
	call	HidePtrIfWarrantedCommon
	jmp	short afterHide

SetPtrImageLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowPtrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If hiding ptr, unhide.

CALLED BY:	INTERNAL
PASS:		es	- idata
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/9/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShowPtrCommon	proc	far
					; Skip if not hiding cursor
	test	es:[imPtrStatus], mask PS_HIDING_PTR
	jz	afterShow

	mov	di, DR_VID_SHOWPTR	; Do it -- SHOW
	push	ds
	segmov	ds, es
	call	CallPtrDriver
	pop	ds
	andnf	es:[imPtrStatus], not mask PS_HIDING_PTR

afterShow:
	ret
ShowPtrCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HidePtrIfWarrantedCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
PASS:		es	- idata
		ds:si	- PointerDef, or si =-1 for default
		bx	- handle of locked PointerDef block, else 0 if none
RETURN:		bx	- preserved
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/9/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HidePtrIfWarrantedCommon	proc	far
	cmp	si, -1			; Hide if default
	je	needHide
	tst	bx			; Hide if no cursor
	jz	needHide
					; Hide if show not requested
	test	ds:[si].PD_width, mask PDW_ALWAYS_SHOW_PTR
	jnz	afterHide

needHide:
					; Skip if already hidden
	test	es:[imPtrStatus], mask PS_HIDING_PTR
	jnz	afterHide

	mov	di, DR_VID_HIDEPTR	; Do it -- HIDE
	push	ds, es
	segmov	ds, es
	call	CallPtrDriver
	pop	ds, es
	ornf	es:[imPtrStatus], mask PS_HIDING_PTR

afterHide:
	ret
HidePtrIfWarrantedCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImSetPtrMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows setting of ptr data sending mode.

CALLED BY:	EXTERNAL

PASS:		ax	- left	 (in ptr coordinates)
		bx	- top 	 (in ptr coordinates)
		cx	- right  (in ptr coordinates)
		dx	- bottom (in ptr coordinates)

		si	- PtrMode:
			  PM_ON_ENTER_LEAVE -set if ptr method should
			  be sent only on transition from inside to
			  outside, or outside to inside, of rectangle
			  passed above.  Clear for continuous sending.

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/14/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(QUIET_PTR_SUPPORT)
ImSetPtrMode	proc	far
	push	di,ds
	mov	di, segment idata
	mov	ds, di
				; store new quiet area
	mov	ds:[quietMouseLeft], ax
	mov	ds:[quietMouseTop], bx
	mov	ds:[quietMouseRight], cx
	mov	ds:[quietMouseBottom], dx
	mov	ds:[mouseMode], si	; store flags
	test	si, mask PM_ON_ENTER_LEAVE	; enter/leave mode?
	jnz	EnterLeave
					; See if last ptr event was sent.
	test	ds:[ptrOptFlags], mask POF_UNSENT
	jnz	80$			; if it was'nt, re-send
	jmp	short 90$

EnterLeave:
	mov	cx, ds:[lastSentXPos]	; get last sent position
	mov	dx, ds:[lastSentYPos]
	call	TestForPtrChange	; get enter/leave state set to
					;    that of last sent position
	mov	al, ds:[ptrOptFlags]
	push	ax
	mov	cx, ds:[displayXPos]	; get current inside/outside status
	mov	dx, ds:[displayYPos]
	call	TestForPtrChange	; Trial run - would current mouse
					; position cause need for sending?
	pop	ax
	mov	ds:[ptrOptFlags], al	; don't actually change state
	jnc	90$			; if it wouldn't, then we're done
80$:
					; Else refresh
					;	mouse event in queue
	call	RefreshPtr
90$:
	pop	di, ds
	ret

ImSetPtrMode	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImForcePtrMethod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes a ptr event to be sent out, regardless of
		state of enter/leave, POF_UNSENT, etc.

CALLED BY:	EXTERNAL

PASS:		Nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImForcePtrMethod	proc	far
if	(QUIET_PTR_SUPPORT)
	push	ax,ds
	mov	ax, segment idata
	mov	ds, ax
				; set bit to cause next ptr to be sent
	or	ds:[ptrOptFlags], mask POF_SEND_NEXT
endif
	call	RefreshPtr	; cause PTR event to occur
if	(QUIET_PTR_SUPPORT)
	pop	ax, ds
endif
	ret
ImForcePtrMethod	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	RefreshPtr

DESCRIPTION:	Places a dummy pointer movement event in the IM queue,
		specifying no movement, but which will pass through the
		monitor list, causing the update of all ptr related info,
		ptr display, etc.


CALLED BY:	INTERNAL

PASS:	Nothing

RETURN:	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
------------------------------------------------------------------------------@

RefreshPtr	proc	far	uses	ax, bx, cx, dx, bp
	.enter
					; Refresh
					;	mouse event in queue
				; Send no-movement ptr event to ourselves
	call	TimerGetCount
	mov	bp,ax			;low word of count
	andnf	bp, not (mask PI_absX or mask PI_absY) ; relative change 0

	mov	ax, MSG_IM_PTR_CHANGE
	clr	cx			; no relative change
	clr	dx
	call	SendToIM
	.leave
	ret
RefreshPtr	endp


RefreshPtrNow	proc	far	uses	ax, bx, cx, dx, bp
	.enter
					; Refresh
					;	mouse event in queue
				; Send no-movement ptr event to ourselves
	call	TimerGetCount
	mov	bp,ax			;low word of count
	andnf	bp, not (mask PI_absX or mask PI_absY) ; relative change 0

	mov	ax, MSG_IM_PTR_CHANGE
	clr	cx			; no relative change
	clr	dx
	call	CallIM
	.leave
	ret
RefreshPtrNow	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TestForPtrChange

DESCRIPTION:	Determine whether ptr is inside or outside of Quiet rect,
		update inside/outside flag, & return whether or not a
		change has occured.

CALLED BY:	INTERNAL

PASS:
	cx, dx	- screen position
	ds - dgroup

RETURN:
	carry	- set if ptr has moved into or out of rectangle

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
------------------------------------------------------------------------------@

if	(QUIET_PTR_SUPPORT)
TestForPtrChange	proc	near
					; Determine if point in or out
	cmp	cx, ds:[quietMouseLeft]
	jl	Outside
	cmp	cx, ds:[quietMouseRight]
	jg	Outside
	cmp	dx, ds:[quietMouseTop]
	jl	Outside
	cmp	dx, ds:[quietMouseBottom]
	jg	Outside
;Inside:
					; see if was inside before
	test	ds:[ptrOptFlags], mask POF_INSIDE_RECT
	jnz	NoChange
	jmp	short Change
Outside:
					; see if was outside before
	test	ds:[ptrOptFlags], mask POF_INSIDE_RECT
	jz	NoChange
Change:
					; flip stored state
	xor	ds:[ptrOptFlags], mask POF_INSIDE_RECT
	stc				; return change
	ret
NoChange:
					; stored state is unchanged
	clc				; return no change
	ret
TestForPtrChange	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallPtrDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the current pointer driver, preserving anything it's
		likely to trash.

CALLED BY:	ImSetPtrWin, OutputMonitor
PASS:		DI	= driver routine to call
		DS	= our data segment
RETURN:		Nothing
DESTROYED:	Hopefully, nothing


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallPtrDriver	proc	far
		tstdw	ds:pointerDriver
EC <		WARNING_Z WARNING_NO_VIDEO_DRIVER_LOADED_YET		>
		jz	exit
		push	ds, es, ax, bx, cx, dx, si, bp
		call	ds:pointerDriver
		pop	ds, es, ax, bx, cx, dx, si, bp
exit:
		ret
CallPtrDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMovePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the video driver routine to move the ptr, return
		save unders overlapped in al

CALLED BY:	OutputMonitor
PASS: 		DS	= our data segment
		ax	- new x position
		bx	- new y position
RETURN:		al	- save unders that ptr overlaps
DESTROYED:	Hopefully, nothing


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	Doug	3/93		Added Disembodied ptr support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallMovePtr	proc	near
		push	ds, es, bx, cx, dx, si, di, bp

		; See if ptr image is disembodied from mouse location
		;
		test	ds:imPtrFlags, mask PF_DISEMBODIED_PTR
		jnz	disembodiedPtr		; branch if so
		mov	di, DR_VID_MOVEPTR
doGraphicsOp:
		call	ds:pointerDriver
		pop	ds, es, bx, cx, dx, si, di, bp
		ret

disembodiedPtr:
		; Disembodied, so don't move.  We still have to check
		; save-unders for the current mouse location, though,
		; for WinMovePtr.
		;
		mov	di, DR_VID_CHECK_UNDER
		mov	cx, ax		; pass rectangle at point
		mov	dx, bx
		jmp	short	doGraphicsOp
CallMovePtr	endp
	 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImGetMousePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns position of mouse relative to IM thread.
		Be careful!  This is NOT the current position relative to
		the UI thread.
			
CALLED BY:	EXTERNAL
		Used in views for auto-scroll

PASS:		di - window to reference position to (0 for none)

RETURN:		cx - x screen position for mouse
		dx - y screen position for mouse

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE DOES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImGetMousePos	proc	far
	push	ax, bx, ds
	mov	ax, segment idata
	mov	ds, ax
	PSem	ds, semMonChain, TRASH_AX_BX
	mov	ax, ds:[pointerXPos]	; Get raw pointer position
	mov	bx, ds:[pointerYPos]
	tst	di			; Convert to passed window's coords
	jz	50$			; Unless requester doesn't want us too.
	call	WinUntransform	; Change from Screen - > Doc. coords
50$:
	mov_trash	cx, ax
	mov	dx, bx
					; Release monitor chain
	VSem	ds, semMonChain, TRASH_AX_BX
	pop	ax, bx, ds
	ret
ImGetMousePos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImGetPtrWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the window and driver handle via which the pointer
		is currently moving.

CALLED BY:	EXTERNAL
PASS:		Nothing
RETURN:		di	- root window for pointer
		bx	- driver handle for pointer
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	ImGetPtrWin
ImGetPtrWin	proc	far		; MUST BE RESIDENT FOR SysNotify
		push	ds
		mov	bx, dgroup
		mov	ds, bx
		mov	di, ds:pointerWin
		mov	bx, ds:pointerDriverHandle
		pop	ds
		ret
ImGetPtrWin	endp

IMResident	ends

IMMiscInput	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImPtrJump
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the pointer position to an absolute location
			
CALLED BY:	EXTERNAL

PASS:		cx - x screen position for mouse
		dx - y screen position for mouse

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Move the mouse to an absolute location.  
		If the mouse isn't constrained/ratcheted, then 
		    Send the new position into the IM queue to be handled 
		    like a real pointer event.  (This will then alter the
		    position, if necessary.)
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	-	There could be an option where the jump would happen 
		and remove any constraining if there were any conflict.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImPtrJump	proc	far	uses	ax, bp
	.enter
					; Force the pointer event to be sent
					;   to the IM queue to process a 
					;   pointer move to an absolute 
					;   location
	mov	bp, mask PI_absX or mask PI_absY	
	mov	ax, MSG_IM_PTR_CHANGE	
	call	SendToIM
	.leave
	ret
ImPtrJump	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImBumpMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out notification of a "MOUSE_BUMP" & bump the mouse
		position, effective immediately. May be used ONLY
		by the User Interface "Flow" object.  UI components
		should call FlowBumpMouse in the UI.  To be used only in
		cases where the mouse movement must be synchronous, & all
		following mouse events must reflect the "bump", including
		those that were in the UI queue at the time (needed for
		Open Look scrollbar implementation)
			
CALLED BY:	EXTERNAL

PASS:		ax - method to be sent out the OutputOD before the pointer
		     "bump" change is made.  Used to mark end of queue
		     events which were not affected by this change.

		cx - x amount to move mouse
		dx - y amount to move mouse

RETURN:		nothing

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE DOES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImBumpMouse	proc	far	uses	di, ds
	.enter
	mov	di, segment idata
	mov	ds, di

	PSem	ds, semMonChain, idata	; Halt monitor chain

	mov	di, mask MF_FORCE_QUEUE
	call	MessageOutputOD		; Notify output OD of this change

	add	ds:[pointerXPos], cx	; Bump pointer position, effective NOW
	add	ds:[pointerYPos], dx

	VSem	ds, semMonChain, idata	; Release monitor chain

					; Make sure that ptr is updated on
					; screen, by sending a dummy ptr
					; change event through the IM.
	call	RefreshPtr		
	.leave
	ret
ImBumpMouse	endp


;Version that refreshes the ptr now, rather than after the queue is flushed.
; -cbh 1/28/93

ImBumpMouseNow	proc	far	uses	di, ds
	.enter
	mov	di, segment idata
	mov	ds, di

	PSem	ds, semMonChain, idata	; Halt monitor chain

	mov	di, mask MF_FORCE_QUEUE
	call	MessageOutputOD		; Notify output OD of this change

	add	ds:[pointerXPos], cx	; Bump pointer position, effective NOW
	add	ds:[pointerYPos], dx

	VSem	ds, semMonChain, idata	; Release monitor chain

					; Make sure that ptr is updated on
					; screen, by sending a dummy ptr
					; change event through the IM.
	call	RefreshPtrNow		
	.leave
	ret
ImBumpMouseNow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImConstrainMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Constrain the mouse to a rectangular region.  If the mouse
		is outside the region, jump it to be inside.  This routine
		may be used to set and alter the mouse constrain area.
		In order to prevent ill-timed constraining of the mouse by
		UI components in the case of a backlogged event queue, optional
		flags may be passed which specify that the constrain be
		automatically terminated should certain button(s) change state,
		which also prevent the constrain from starting should the
		specified button(s) already have changed state.


CALLED BY:	EXTERNAL

PASS:		ax - 0 to constrain regardless of button data,
		     else mask of button(s) which, if have already (relative
		     to UI) or do change state, will terminate the constrain.

		cx:dx - OD to send MSG_META_LEAVE_CONSTRAIN to , or 0 if none
		di - window handle that coordinates are in (or 0 for screen)

		ON STACK (pushed in this order):
	    		word - bottom  of constraining rectangle
	    		word - right  of constraining rectangle
	    		word - top    of constraining rectangle
	    		word - left    of constraining rectangle



RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set the constraining rectangle;
		Add the PtrPerturbabtion Monitor to the list;
		If (pointer is not already inside) then
			Jump the pointer into the constraining rect;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImConstrainMouse	proc	far	left:word, top:word, right:word,
					bottom:word
	uses	ax, bx, cx, dx, si, di, ds
	.enter
	mov	si, ax				; Pass button stuff in si

	mov	ax, segment idata
	mov	ds, ax

	tst	si				; See if always constraining
	jz	constraining

	mov	ax, si				; move button stuff back to al
	test	ds:[buttonState], al		; see if mouse is even pressed
	jz	dontConstrain			; nope, forget the whole thing
	
if	(INPUT_MESSAGE_RECEIPT)
	call	ImGetButtonBacklog		; See what buttons have changed
	test	ax, si				; see if any have changed yet
	jz	constraining			; if not, go ahead & do it.
else
	jmp	short constraining
endif
	
dontConstrain:
	call	EnsureNotConstraining		; else quit, because user's
						;	gotten ahead of us.
	jmp	short done

constraining:
	mov	ax, left
	mov	bx, top
	tst	di
	jz	20$
	call	WinTransform		; Change from Doc - > Screen
20$:
	mov	ds:[constrainXMin], ax		; set the constrain region
	mov	ds:[constrainYMin], bx

	mov	ax, right
	mov	bx, bottom
	tst	di
	jz	30$
	call	WinTransform		; Change from Doc - > Screen
30$:
	mov	ds:[constrainXMax], ax
	mov	ds:[constrainYMax], bx

	mov	ds:[constrainButtonFlags], si
						; Setup constrain OD
	mov	ds:[constrainOD].handle, cx	
	mov	ds:[constrainOD].chunk, dx

	call	EnsureConstraining		; make sure monitor is set up
	call	RefreshPtr 			; cause PTR event to occur
done:
	.leave
	ret	8

ImConstrainMouse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureConstraining
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the monitor is installed.  If not, it adds it
		to the queue.

CALLED BY:	ImConstrainMouse

PASS:		constrainFlags

RETURN:		constrainFlags: CF_MONITOR_INSTALLED & CF_CONSTRAINING set
				(pointer perturbation monitor added)

DESTROYED:	ax, bx, cx, dx, di, si, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnsureConstraining	proc	near
					; See if monitor installed
	test	ds:[constrainFlags], mask CF_MONITOR_INSTALLED
	jnz	50$			; if so, skip addition
					; ADD POINTER PERTURBATION MONITOR
	mov	bx, offset  ptrPerturbMonitor
	mov	cx, segment PtrPerturbMonitor
	mov	dx, offset PtrPerturbMonitor	; point to routine
	mov	al, ML_PTR_PERTURB		; processing LEVEL 60
	call	ImAddMonitor			; Add it.
50$:	
	ornf	ds:[constrainFlags], mask CF_MONITOR_INSTALLED or mask CF_CONSTRAINING
	ret
EnsureConstraining	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureNotConstraining
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the pointer perturbation monitor is not installed.
		If it is, it removes it from the queue.

CALLED BY:	ImUnconstrainMouse, ImConstrainMouse

PASS:		constrainFlags

RETURN:		constrainFlags: CF_MONITOR_INSTALLED & CF_CONSTRAINING cleared
				(pointer perturbation monitor removed)

DESTROYED:	ax, bx, cx, dx, di, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnsureNotConstraining	proc	near
						; See if monitor removed
	test	ds:[constrainFlags], mask CF_MONITOR_INSTALLED
	jz	50$				; if not, skip removing
					; REMOVE PtrPerturbation MONITOR
	mov	bx, offset  ptrPerturbMonitor
	mov	al, mask MF_REMOVE_IMMEDIATE	; Can remove immediate, since
						; doesn't generate any data
	call	ImRemoveMonitor			; Remove it.
50$:
						; Show no monitor, not 
						; constraining
	andnf	ds:[constrainFlags], not (mask CF_MONITOR_INSTALLED or mask CF_CONSTRAINING)
	ret
EnsureNotConstraining	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImUnconstrainMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unconstrain the mouse.  Removes the pointer perturbation
		monitor, if necessary, to avoid undue processing.

CALLED BY:	EXTERNAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If (mouse is constrained) then
			Clear the constraining rectangle values;
			Remove the PtrPerturberbation Monitor;
		Else
			Do nothing;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImUnconstrainMouse	proc	far
	push	ax, bx, cx, dx, di, es, ds
	mov	bx, segment idata
	mov	ds, bx
	call	EnsureNotConstraining
	pop	ax, bx, cx, dx, di, es, ds
	ret
ImUnconstrainMouse	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ImSetPtrFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change ImPtrFlags

CALLED BY:	EXTERNAL
PASS:		al	- PtrFlags to set
		ah	- PtrFlags to clear

RETURN:		al - previous PtrFlags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/9/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImSetPtrFlags	proc	far	uses	bx, es
	.enter
	mov	bx, segment idata
	mov	es, bx
	PSem	es, semPtrImage, idata

	mov	bl, es:[imPtrFlags]		; get old flags in bl
	mov	bh, bl				; get new flags in bh
	ornf	bh, al
	not	ah
	andnf	bh, ah
	mov	es:[imPtrFlags], bh		; store new flags
					; See if changing hide mode

	push	bx			; bl - old flags
	xor	bl, bh
	test	bl, mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	jnz	changeHideMode
done:
	pop	ax			; al - old flags
	VSem	es, semPtrImage, idata
	.leave
	ret

changeHideMode:
	test	bh, mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	jz	turnOffHideMode

;turnOnHideMode:
	push	si, di, ds
	mov	bx, es:[curPtrImage].handle
	mov	si, es:[curPtrImage].chunk
	call	LockPtrImageCommon	; Get ds:si = ptr image
	call	HidePtrIfWarrantedCommon
	tst	bx
	jz	afterUnLock
	call	MemUnlock
afterUnLock:
	pop	si, di, ds
	jmp	short done

turnOffHideMode:
	push	di
	call	ShowPtrCommon
	pop	di
	jmp	short done


ImSetPtrFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ImGetPtrFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get ImPtrFlags

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		al	= ImPtrFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImGetPtrFlags	proc	far	uses	bx, es
	.enter
	;
	; don't need to get semaphore
	;
	mov	bx, segment idata
	mov	es, bx
	mov	al, es:[imPtrFlags]		; get flags in al
	.leave
	ret
ImGetPtrFlags	endp

IMMiscInput	ends
