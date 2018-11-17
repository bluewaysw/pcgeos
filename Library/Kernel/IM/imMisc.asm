COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		imMisc.asm

AUTHOR:		Adam de Boor, Jan 28, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/28/91		Initial revision


DESCRIPTION:
	Miscellaneous exported functions for the IM
		

	$Id: imMisc.asm,v 1.1 97/04/05 01:17:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImGrabInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows grabbing of all input data coming from
		Input manager

CALLED BY:	EXTERNAL

PASS:		<bx><si>- OD to send input data to

RETURN:		carry - set if successful (if clear, then already grabbed)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		This is intended to be used only by the UI library.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/14/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImGrabInput	proc	far
	push	ax,ds
	mov	ax, segment idata
	mov	ds, ax
	INT_OFF
	cmp	ds:[outputOD.handle], 0
	clc
	jne	110$			; quit if already grabbed
	mov	ds:[outputOD.handle], bx
	mov	ds:[outputOD.chunk], si
	stc
110$:
	INT_ON
	pop	ax, ds
	ret

ImGrabInput	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImReleaseInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows grabbing of all input data coming from
		Input manager

CALLED BY:	EXTERNAL

PASS:		<bx><si>- OD to release from having input grab

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/14/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImReleaseInput	proc	far
	push	ax,ds
	mov	ax, segment idata
	mov	ds, ax
	INT_OFF
	cmp	ds:[outputOD.handle], bx
	jne	110$			; quit if not grab
	cmp	ds:[outputOD.chunk], si
	jne	110$			; quit if not grab
				; clear grab
	clr	ax
	mov	ds:[outputOD.handle], ax
	mov	ds:[outputOD.chunk], ax
110$:
	INT_ON
	pop	ax, ds
	ret

ImReleaseInput	endp


ObscureInitExit ends

IMResident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImInfoInputProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns handle of Input Manager thread

CALLED BY:	EXTERNAL

PASS:		Nothing

RETURN:		bx - handle of input process

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImInfoInputProcess	proc	far
	push	ds
	LoadVarSeg	ds, bx
	mov	bx, ds:[imThread]
	pop	ds
	ret
ImInfoInputProcess	endp

IMResident ends

IMMoveResize segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImStartMoveResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a region (usually rectangular) which will follow 
		the mouse movement used by moving and resizing window(s).

CALLED BY:	EXTERNAL

PASS:
	ax, bx, cx, dx - left, top, right, bottom of the bounding rectangle
			 of the region to be XOR'ed, in document coordinates.
			 UNLESS XF_PTR_OFF_{LEFT,TOP,RIGHT,BOTTOM} flags are
			 set, in which case these are positions relative to
			 the mouse position
	di - window handle (window that above positions are relative to)
	si - xor box flags
	    XF_RESIZE_LEFT	- If set, then the corresponding side of the
	    XF_RESIZE_TOP	  XOR region is being resized and thus should
	    XF_RESIZE_RIGHT	  move when the mouse moves.  If all clear then
	    XF_RESIZE_BOTTOM	  the region is being moved and ALL sides
				  should move with the mouse

	    XF_FLIP_HORIZONTAL	- Horizontal flipping allowed
	    XF_FLIP_VERTICAL	- Vertical flipping allowed
	    XF_END_MATCH_ACTION - End xor on button action match

	    XF_PTR_OFF_LEFT	- If set, then the corresponding position is
	    XF_PTR_OFF_TOP	  relative to the current mouse position, else
	    XF_PTR_OFF_RIGHT	  it is a window position
	    XF_PTR_OFF_BOTTOM

	    XF_RESIZE_PENDING	- If set, then don't follow mouse at all
	    XF_NO_END_MATCH_ACTION
				- If set, then no end on mouse action

	bp - button release xor screen flag
		    mask XF_END_MATCH_ACTION is set (match button action):
		        7:   set for press, clear for release
		        6:   set for double press, clear for none
		        1-0: button number for release action
			5-2: unused
		    mask XF_END_MATCH_ACTION is clear (match button state):
		        7-6: unused
		        1-0: unused
			5-2: state of the four buttons to match

	On stack (pushed in this order):
		RESIZE ONLY:
		word - minimum width of region
		word - minimum height of region
		word - maximum width of region
		word - maximum height of region
			(Each of these words can be set to zero/negative number
			if you don't wish to use a minimum/maximum)

		BOTH MOVE AND RESIZE:
		word - pointer x position (in document coords)
		word - pointer y position (in document coords)
		dword - address of region definition

RETURN:		
	carry flag - clear if screen xor started OK
		     set if nothing done (since xor=already in progress)

DESTROYED:
	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS/ISSUES:
	Regions:  Must ALWAYS specify a minimum height, since the region 
		  routines can't draw subregions that overlap.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	5/89	Initial version
	Adam	12/89	Converted to Esp, made block fixed, generally cleaned
			up.
	Doug	6/92	Changed to remote call IM process to do actual work,
			to synchronize this mess

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ImStartMoveResize	proc	far
	class	IMClass
EC <	test	si, not mask XorFlags					>
EC <	ERROR_NZ	IM_START_RESIZE_BAD_XOR_FLAGS			>
EC <	test	si, mask XF_FLIP_HORIZONTAL or mask XF_FLIP_VERTICAL	>
EC <	ERROR_NZ	IM_START_RESIZE_FLIPPING_NOT_SUPPORTED		>

	push	bp, si, di, dx, cx, bx, ax

	mov	cx, ss			; Pass pointer to data in cx:dx
	mov	dx, sp

	mov	ax, MSG_IM_START_XOR
	call	CallIM

	pop	bp, si, di, dx, cx, bx, ax

	pushf
	test	si, XOR_RESIZE_ALL
	jz	exitMove

	; Exit from a resize

	popf
	.leave
	ret	16

exitMove:

	; Exit from a move

	popf
	.leave
	ret	8				; (Return amount for moving)

ImStartMoveResize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImDoStartScreenXor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a region (usually rectangular) which will follow 
		the mouse movement used by moving and resizing window(s).

CALLED BY:	INTERNAL

PASS:		cx:dx	- fptr to StartMoveResizeParams
		
RETURN:		
	carry flag - clear if screen xor started OK
		     set if nothing done (since xor=already in progress)

DESTROYED:
	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS/ISSUES:
	Regions:  Must ALWAYS specify a minimum height, since the region 
		  routines can't draw subregions that overlap.

	NOTE:
	This code is badly in need of syncronization!  Some of it runs in the
	caller's thread (ImStartMoveResize) and some of it runs in the IM
	thread, with only one piece of hacked syncronization between the two.
	Also, there should be a semaphore controlling access to this shared
	resource.


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	5/89	Initial version
	Adam	12/89	Converted to Esp, made block fixed, generally cleaned
			up.
	Doug	6/92	Changed to remote call IM process to do actual work,
			to synchronize this mess

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartMoveResizeParams	struc
	SMRP_bounds		Rectangle
	; left, top, right, bottom of the bounding rectangle
	; of the region to be XOR'ed, in document coordinates.
	; UNLESS XF_PTR_OFF_{LEFT,TOP,RIGHT,BOTTOM} flags are
	; set, in which case these are positions relative to
	; the mouse position

	SMRP_win		hptr.Window
	; window handle (window that above positions are relative to)

	SMRP_boxFlags		XorFlags
	; xor box flags
	;    XF_RESIZE_LEFT	- If set, then the corresponding side of the
	;    XF_RESIZE_TOP	  XOR region is being resized and thus should
	;    XF_RESIZE_RIGHT	  move when the mouse moves.  If all clear then
	;    XF_RESIZE_BOTTOM	  the region is being moved and ALL sides
	;			  should move with the mouse
	;
	;    XF_FLIP_HORIZONTAL	- Horizontal flipping allowed
	;    XF_FLIP_VERTICAL	- Vertical flipping allowed
	;    XF_END_MATCH_ACTION - End xor on button action match
	;
	;    XF_PTR_OFF_LEFT	- If set, then the corresponding position is
	;    XF_PTR_OFF_TOP	  relative to the current mouse position, else
	;    XF_PTR_OFF_RIGHT	  it is a window position
	;    XF_PTR_OFF_BOTTOM
	;
	;    XF_RESIZE_PENDING	- If set, then don't follow mouse at all
	;    XF_NO_END_MATCH_ACTION
	;			- If set, no end match action

	SMRP_releaseFlags	XorFlags
	; button release xor screen flag
	;	    mask XF_END_MATCH_ACTION is set (match button action):
	;	        7:   set for press, clear for release
	;	        6:   set for double press, clear for none
	;	        1-0: button number for release action
	;		5-2: unused
	;	    mask XF_END_MATCH_ACTION is clear (match button state):
	;	        7-6: unused
	;	        1-0: unused
	;		5-2: state of the four buttons to match

	SMRP_unused		fptr
	; This is actually the return address from ImStartMoveResize

	SMRP_regionDef		dword		; handle, offset
	; Address of region definition

	SMRP_yPos		sword
	; pointer y position (in document coords)

	SMRP_xPos		sword
	; pointer x position (in document coords)

	; RESIZE ONLY:
	;	(Each of these words can be set to zero/negative number
	;	if you don't wish to use a minimum/maximum)

	SMRP_maxHeight		word
	; maximum height of region

	SMRP_maxWidth		word
	; maximum width of region

	SMRP_minHeight		word
	; minimum height of region 

	SMRP_minWidth		word
	; minimum width of region

StartMoveResizeParams	ends



ImDoStartScreenXor	method	IMClass, MSG_IM_START_XOR

passParams	local	StartMoveResizeParams
vidParams	local	VisXORParams
	.enter

	; Copy params to local stack frame where they'll be easier to access
	;
	mov	ds, cx		; ds:si = passed StartMoveResizeParams
	mov	si, dx
	mov	ax, ss
	mov	es, ax
	lea	di, passParams
	mov	cx, size StartMoveResizeParams
	rep	movsb

	; point ds at idata (our variables)

	mov	ax, segment idata
	mov	ds, ax

	; if a move or resize is already happening, exit with carry set

	test	ds:[screenXorState], mask SXS_IN_MOVE_RESIZE
	jz	start
	stc
	jmp	done

start:
	;
	; get the min/max bounds to be meaningful things we can use. If
	; max <= 0, set to max coordinate. If min < 0, set to 0
	;
	tst	passParams.SMRP_maxWidth
	jg	maxWidthOK
	mov	passParams.SMRP_maxWidth, 0x4000
maxWidthOK:
	tst	passParams.SMRP_maxHeight
	jg	maxHeightOK
	mov	passParams.SMRP_maxHeight, 0x4000
maxHeightOK:
	tst	passParams.SMRP_minWidth
	jge	minWidthOK
	mov	passParams.SMRP_minWidth, 0
minWidthOK:
	tst	passParams.SMRP_minHeight
	jge	minHeightOK
	mov	passParams.SMRP_minHeight, 0
minHeightOK:

	mov	ax, passParams.SMRP_bounds.R_left
	mov	bx, passParams.SMRP_bounds.R_top
	mov	cx, passParams.SMRP_bounds.R_right
	mov	dx, passParams.SMRP_bounds.R_bottom

	mov	si, passParams.SMRP_boxFlags
	mov	di, passParams.SMRP_win

	mov	ds:[xorBoxFlag], si		;    and the resizing flag

	; Process region parameters

	; left

	test	si, mask XF_PTR_OFF_LEFT	; Is the left edge absolute?
	call	TranslateXCoord			; Translate into screen coords
	mov	vidParams.VXP_ax, ax		; Save the left edge

	; top

	test	si, mask XF_PTR_OFF_TOP		; Is the top edge absolute?
	call	TranslateYCoord			; Translate into screen coords
	mov	vidParams.VXP_bx, bx		; Save the initial top edge

	; right

	xchg	ax, cx				; ax = right
	xchg	bx, dx				; cx = bottom
	test	si, mask XF_PTR_OFF_RIGHT	; Is the right edge absolute?
	call	TranslateXCoord			; Translate into screen coords
	mov	vidParams.VXP_cx, ax		; Save the initial right

	; bottom

	test	si, mask XF_PTR_OFF_BOTTOM	; Is the bottom edge absolute?
	call	TranslateYCoord			; Translate into screen coords
	mov	vidParams.VXP_dx, bx		; Save the initial right

	; Convert the minimum parameters into a bounding rectangle

	mov	ax, EOREGREC			; assume no bounding rect
	mov	bx, ax
	mov	cx, ax
	mov	dx, ax

	; save window handle, use di to accumulate VisXORFlags

	push	di
	clr	di
	test	si, mask XF_RESIZE_PENDING
	jnz	moveNotResize
	mov	di, mask VXF_X_POS_FOLLOWS_MOUSE or \
			mask VXF_Y_POS_FOLLOWS_MOUSE
	test	si, XOR_RESIZE_ALL
	jz	moveNotResize
	clr	di

	; if resizing left then a maximum right & minimum left exist

	test	si, mask XF_RESIZE_LEFT
	jz	notLeft
	or	di, mask VXF_AX_PARAM_FOLLOWS_MOUSE
	mov	cx, vidParams.VXP_cx		; cx = right
	mov	ax, cx
	sub	cx, passParams.SMRP_minWidth		; cx = (right - min)
	sub	ax, passParams.SMRP_maxWidth
notLeft:

	; if resizing top then a maximum bottom  & minimum top exist

	test	si, mask XF_RESIZE_TOP
	jz	notTop
	or	di, mask VXF_BX_PARAM_FOLLOWS_MOUSE
	mov	dx, vidParams.VXP_dx		; dx = bottom
	mov	bx, dx
	sub	dx, passParams.SMRP_minHeight	; dx = (bottom - min)
	sub	bx, passParams.SMRP_maxHeight
notTop:

	; if resizing right then a maximum left & right exist

	test	si, mask XF_RESIZE_RIGHT
	jz	notRight
	or	di, mask VXF_CX_PARAM_FOLLOWS_MOUSE
	mov	ax, vidParams.VXP_ax		; ax = left
	mov	cx, ax
	add	ax, passParams.SMRP_minWidth	; ax = (left + min)
	add	cx, passParams.SMRP_maxWidth
notRight:

	; if resizing bottom then a maximum top & bottom exist

	test	si, mask XF_RESIZE_BOTTOM
	jz	notBottom
	or	di, mask VXF_DX_PARAM_FOLLOWS_MOUSE
	mov	bx, vidParams.VXP_bx		; bx = top
	mov	dx, bx
	add	bx, passParams.SMRP_minHeight	; bx = (top + min)
	add	dx, passParams.SMRP_maxHeight
notBottom:

moveNotResize:

	mov	ds:[xorConstraints].R_left, ax
	mov	ds:[xorConstraints].R_top, bx
	mov	ds:[xorConstraints].R_right, cx
	mov	ds:[xorConstraints].R_bottom, dx

	mov	si, di				; si = flags to pass
	pop	di

	; Subtract off window position

	clr	ax
	clr	bx
	call	WinTransform
	sub	vidParams.VXP_ax, ax
	sub	vidParams.VXP_bx, bx
	sub	vidParams.VXP_cx, ax
	sub	vidParams.VXP_dx, bx

	; do an initial constrain  (Changed 1/28/93 cbh to completely update
	; the mouse now rather than via the queue, so the video driver will
	; be aware of the correct mouse position.  Otherwise, this bump is
	; ignored and the bad things it's supposed to prevent happen anyway.)

	mov	cx, ds:[drawnXPos]
	mov	dx, ds:[drawnYPos]
	call	XorConstrain
	sub	cx, ds:[drawnXPos]
	sub	dx, ds:[drawnYPos]
	clr	ax
	call	ImBumpMouseNow		;bump mouse NOW.

	mov	ax, passParams.SMRP_releaseFlags
	mov	{word} ds:[xorButtonFlag], ax	; Save the xor-end button flag

	mov	ax, passParams.SMRP_xPos
	mov	bx, passParams.SMRP_yPos
	call	WinTransform		; convert to screen coordinates
	mov	vidParams.VXP_mousePos.P_x, ax
	mov	vidParams.VXP_mousePos.P_y, bx

	clr	ax
	clr	bx
	call	WinTransform

	mov	dx, passParams.SMRP_regionDef.handle
	mov	cx, passParams.SMRP_regionDef.offset

EC <	tst	dx							>
EC <	ERROR_Z	IM_NULL_REGION_DEF_PASSED_TO_IM_START_MOVE_RESIZE	>

	push	bp
	lea	bp, vidParams
	mov	di, DR_VID_SET_XOR
	call	CallPtrDriver 			; start up xor'ing
	pop	bp
	clc					;   XOR started OK

	; Set the flag saying that we're doing a move/resize.

	ornf	ds:[screenXorState], mask SXS_IN_MOVE_RESIZE

done:

	.leave
	ret

ImDoStartScreenXor	endm



	; pass: z flag - set if absolute, ax = x position, di = window

TranslateXCoord	proc	near			; ax = x coord to translate
	jz	absolute			;   If so, go save it
	add	ax, ds:[drawnXPos]		; Calc left edge from mouse
	ret
absolute:
	push	bx
	call	WinTransform		; Translate the boundaries
	pop	bx
	ret
TranslateXCoord	endp

	; pass: z flag - set if absolute, bx = y position, di = window

TranslateYCoord	proc	near			; bx = y coord to translate
	jz	absolute			;   If so, go save it
	add	bx, ds:[drawnYPos]		; Calc top edge from mouse
	ret
absolute:
	push	ax
	call	WinTransform		; Translate the boundaries
	pop	ax
	ret
TranslateYCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImStopMoveResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Global routine to externally stop the screen xor.
		Usually the screen xor'ing is stopped via the button-end
		action/state flag inside the OutputMonitor.  However, this 
		routine is made external for the purpose of allowing an
		application to manually stop it.

CALLED BY:	EXTERNAL, OutputMonitor

PASS:		nothing

RETURN:		(nothing)
		ImStopMoveResize COULD return this, but there is presently
			no need for it:
		If the screen xor was resizing:
		    cx - final width
		    dx - final height
		If the screen xor was moving:
		    cx - final left edge position (in screen coords)
		    dx - final top edge position  (in screen coords)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If (have screen exclusive) then
		Undraw the screen xor;
		Release the screen exclusive;
		RETURN (appropriate parameters);

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Clayton	5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImStopMoveResize	proc	far	uses	ax
	class	IMClass
	.enter
	mov	ax, MSG_IM_STOP_XOR
	call	CallIM
	.leave
	ret
ImStopMoveResize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImDoStopScreenXor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the actual stopping of xor'ing on our own thread

CALLED BY:	MSG_STOP_XOR
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	anything I want. I'm a process method. ha ha ha ha!

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImDoStopScreenXor	method	IMClass, MSG_IM_STOP_XOR
	uses	bx, di, si, ax
	.enter

	test	ds:[screenXorState], mask SXS_IN_MOVE_RESIZE
	jz	noMoveResize

	mov	di, DR_VID_CLEAR_XOR
	call	CallPtrDriver 		; let others draw

	andnf	ds:[screenXorState], not mask SXS_IN_MOVE_RESIZE

noMoveResize:
	.leave
	ret
ImDoStopScreenXor	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	XorConstrain

DESCRIPTION:	Constrain the mouse position for the XOR box

CALLED BY:	INTERNAL

PASS:
	cx, dx - mouse position
	ds - idata

RETURN:
	cx, dx - possibly updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/90		Initial version

------------------------------------------------------------------------------@

XorConstrain	proc	near	uses ax
	.enter

	mov	ax, ds:[xorConstraints].R_left
	cmp	ax, EOREGREC
	jz	noLeftConstraint
	cmp	cx, ax
	jge	noLeftConstraint
	mov	cx, ax
noLeftConstraint:

	mov	ax, ds:[xorConstraints].R_top
	cmp	ax, EOREGREC
	jz	noTopConstraint
	cmp	dx, ax
	jge	noTopConstraint
	mov	dx, ax
noTopConstraint:

	mov	ax, ds:[xorConstraints].R_right
	cmp	ax, EOREGREC
	jz	noRightConstraint
	cmp	cx, ax
	jle	noRightConstraint
	mov	cx, ax
noRightConstraint:

	mov	ax, ds:[xorConstraints].R_bottom
	cmp	ax, EOREGREC
	jz	noBottomConstraint
	cmp	dx, ax
	jle	noBottomConstraint
	mov	dx, ax
noBottomConstraint:

	.leave
	ret

XorConstrain	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OutputUpdateScreenXor

DESCRIPTION:	Update XOR image on screen

CALLED BY:	OutputMonitor

PASS:
	ds - IM idata segment
	cx, dx - new ptr screen position
	bp - button flags
	di - MSG_META_PTR

RETURN:
	cx, dx - new mouse position
	di, bp - unchanged

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Moved here, out of OutputMonitor, fixed
				startup case

------------------------------------------------------------------------------@

OutputUpdateScreenXor	proc	far	uses	di, bp
	.enter

	; If checking for end condition, do it now

	test	ds:[xorBoxFlag], mask XF_NO_END_MATCH_ACTION
	jnz	AfterEndMatchCheck
	test	ds:[xorBoxFlag], mask XF_END_MATCH_ACTION
	jnz	AfterEndMatchCheck
	and	bp, mask BI_B3_DOWN or mask BI_B2_DOWN or \
			mask BI_B1_DOWN or mask BI_B0_DOWN
					; Match state: get just button states
					; See if this matches the xor end cond
	xor	bp, word ptr ds:[xorButtonFlag]
	jnz	AfterEndMatchCheck	;    If not, continue

	call	ImDoStopScreenXor	;    If so, stop the screen xor
	jmp	XorDone

AfterEndMatchCheck:

	; Redraw if ptr moved

	cmp	cx, ds:[drawnXPos]
	jne	RedrawXorImage		; If change, update xor image
	cmp	dx, ds:[drawnYPos]
	je	XorDone			; If no change at all, done

RedrawXorImage:

	call	XorConstrain

XorDone:

	.leave
	ret
OutputUpdateScreenXor	endp

IMMoveResize ends

;--------------
IMMiscInput segment resource			; Routines which are not used
						; in a typical MOTIF session



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImSetDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		ax	- new double click time value
		bx	- new double click distance value

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/4/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImSetDoubleClick	proc	far
	push	di, ds
	mov	di, segment idata
	mov	ds, di
	mov	ds:[doubleClickTime], ax
	mov	ds:[doubleClickDistance], bx
	pop	di, ds
	ret

ImSetDoubleClick	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImInfoDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:

RETURN:		ax	- double click time value
		bx	- double click distance value


DESTROYED:	

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/4/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImInfoDoubleClick	proc	far
	push	di, ds
	mov	di, segment idata
	mov	ds, di
				; Get variables
	mov	ax, ds:[doubleClickTime]
	mov	bx, ds:[doubleClickDistance]
	pop	di, ds
	ret

ImInfoDoubleClick	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImGetButtonState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current state of the pointer buttons

CALLED BY:	GLOBAL (written for screen dumper)
PASS:		nothing
RETURN:		ax<0:3>	= set if corresponding button is currently down
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This thing was written for the screen dump program so it
		can generate proper button change events when the screen
		is unfrozen. It is needed because the dumper likes to/needs
		to steal away all the input, so to avoid confusing the UI,
		the dumper must generate proper events when the dump is
		complete to bring the UI up-to-date on the current state
		of the mouse.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImGetButtonState proc	far	uses ds
		.enter
		segmov	ds, dgroup, ax
		mov	al, ds:buttonState
		.leave
		ret
ImGetButtonState endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImGetButtonBacklog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return current backlog of button events
			
CALLED BY:	EXTERNAL

PASS:		Nothing

RETURN:		ax	- Bits set for buttons which have unprocessed
			  events associated with them.  Use these button
			  masks for testing:

					mask IB_BUTTON_0
					mask IB_BUTTON_1
					mask IB_BUTTON_2
					mask IB_BUTTON_3

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE DOES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(INPUT_MESSAGE_RECEIPT)
ImGetButtonBacklog	proc	far
	push	ds
	mov	ax, segment idata
	mov	ds, ax

	clr	ax			; start w/no backlog
	cmp	ds:[buttonPressStatus].BPS_unprocessed + \
				(0* (size ButtonPressStatus)), 0
	jz	10$
	or	ax, mask IB_BUTTON_0
10$:
	cmp	ds:[buttonPressStatus].BPS_unprocessed + \
				(1* (size ButtonPressStatus)), 0
	jz	20$
	or	ax, mask IB_BUTTON_1
20$:
	cmp	ds:[buttonPressStatus].BPS_unprocessed + \
				(2* (size ButtonPressStatus)), 0
	jz	30$
	or	ax, mask IB_BUTTON_2
30$:
	cmp	ds:[buttonPressStatus].BPS_unprocessed + \
				(3* (size ButtonPressStatus)), 0
	jz	40$
	or	ax, mask IB_BUTTON_3
40$:
	pop	ds
	ret

ImGetButtonBacklog	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImGetKbdCharBacklog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return current backlog of kbd events
			
CALLED BY:	EXTERNAL

PASS:		Nothing

RETURN:		ax	- Bits set for kbd event types which are unprocessed:
					mask IB_KBD_PRESSES
					mask IB_KBD_RELEASES

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	THIS ROUTINE DOES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	(INPUT_MESSAGE_RECEIPT)
ImGetKbdCharBacklog	proc	far
	push	ds
	mov	ax, segment idata
	mov	ds, ax

	clr	ax			; start w/no backlog
	cmp	ds:[kbdPressesUnprocessed], 0
	jz	10$
	or	ax, mask IB_KBD_PRESSES
10$:
	cmp	ds:[kbdReleasesUnprocessed], 0
	jz	20$
	or	ax, mask IB_KBD_RELEASES
20$:
	pop	ds
	ret

ImGetKbdCharBacklog	endp
endif

IMMiscInput	ends
