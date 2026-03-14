COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Windowing System
FILE:		Win/winWindows.asm

AUTHOR:		Jim DeFrisco, Doug Fults

ROUTINES:
	Name			Description
	----			-----------
GLB	WinScroll		scroll document in window
GLB	WinMove			Move a window relative to its parent
GLB	WinResize		Resize a window and possibly move it.
GLB	WinChangePriority	Change a window's priority on screen
GLB	WinLocatePoint		find out what window's under a point

INT	WinSetMaskReg		Set up a mask region for Blt operation
INT	ShiftRegion		shift the coordinates of a region
INT	WinMoveHere		Move all child windows of curr window
INT	WinTInsert		Search sibling chain for new desired priority
				location, and add window, connecting it
				into the tree.
INT	WinTRemove		Remove window from chain.
INT	WinTValidateHere	Validate tree, starting at this window
INT	WinTValidateSuperior	Validate parent of window
INT	WinTReleaseSuperior	Release parent of window
INT	WinTValidate		Validate this window & children
INT	WinPerformVis		Calculates visible region, depending on flags,
				to deal correctly with save under areas.
				Invalidates exposed areas in new visible
				region, sending MSG_META_EXPOSED events.
INT	WinTReleaseIfChange	Performs a HandleV operation on a window, &
				all its children, if it matches change window
INT	WinTRelease		Performs a HandleV operation on all children
				of passed window
INT	WinCalcChildReg		Calculate sum of child windows
INT	WinCalcSibReg		Calcualte sum of sibling windows
INT	ClearSibReg		Nullify es:W_childReg
INT	AddWinRegToParentChildReg
INT	WinTValidateOpen	Validates window & all inferiors, patches
				siblings & their
INT	WinTObscureSuperior	Validates (re-calculates) W_visReg for
				superior window.
INT	WinTObscure		Validates window & all inferiors.
INT	WinPerformObscure
INT	WinCalcUnivReg		Calculates new W_univReg




REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jad	6/88		Initial version
	doug	9/21/88		Added window tree manipulation, & region
				recalculation logic
	doug	10/12/88	Changed files to win*, broke out into smaller
				files
	doug	10/28/88	Finished w/pass 1 of windowing system
	doug	11/88		Combined WinTOpen & Close into WinOpen & Close
	jim	8/89		added WinSetMaskReg to be used with win bitblt
				operations, added some documentation



DESCRIPTION:
	This file contains all library functions of the PC GEOS Window Manager.


	$Id: winWindows.asm,v 1.1 97/04/05 01:16:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrWinBlt segment resource


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll document in window

CALLED BY:	GLOBAL

PASS: 		di	- handle of GState or window
		dx.cx	- x move value	(WWFixed)
		bx.ax	- y move value	(WWFixed)

RETURN:		dx.cx	- actual x translation applied
		bx.ax	- actual y translation applied

		NOTE: These values may be different than the requested 
		amounts for scaled windows, since the window system needs to 
		blt on integer pixel boundaries.

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		change window transformation matrix;
		do the blt;
		invalidate the portion of the window not affected by blt;

		FOR VERSION 2.0:

		1. multiply scroll amounts by window scale factor.
		2. subtract that amount from window top/left device coord
		3. round result
		4. difference between rounded result and top/left = blt amount
		5. divide difference (integer) by scale factors
		6. apply result as translation to tmatrix

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: This routine will not work for rotated windows.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version
	Jim	3/89		changed to use new transformation matrix stuff.
	Jim	4/89		changed to use blt routine
	Jim	7/91		fixed greebles under 2.0. (again)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinScroll	proc	far
		uses	si, di, ds, es
srcX		local	word
srcY		local	word
tempX		local	WWFixed		; some scratch area
tempY		local	WWFixed
		.enter			

		; lock window and check to see if we should be doing this

		call	FarWinLockFromDI	; get window locked
		LONG jc	wsExit
EC <		call	CheckDeathVigil		; Fatal err if closed	>

		; first, multiply the scroll amounts by the scale factor in
		; the window.  Check for 1.0...
		; Do x first.  Make sure it's not rotated.

EC <		test	ds:[W_TMatrix].TM_flags, TM_ROTATED 	>
EC <		ERROR_NZ WIN_SCROLL_WITH_ROTATED_WINDOW		>

		; to try and exorcise the rounding errors inherent with fixed
		; point math, we turn all numbers positive.

		mov	tempX.WWF_int, dx	; init scroll amounts
		mov	tempX.WWF_frac, cx
		mov	tempY.WWF_int, bx
		mov	tempY.WWF_frac, ax
		test	ds:[W_TMatrix].TM_flags, TM_SCALED ; check for scale
		jz	haveScaledOffsets

		; window has some scale factor.  do multiplies.

		mov	ax, ds:[W_TMatrix].TM_11.WWF_frac
		mov	bx, ds:[W_TMatrix].TM_11.WWF_int
		call	GrMulWWFixed		; dx.cx = scaled x offset
		mov	tempX.WWF_frac, cx
		mov	tempX.WWF_int, dx
		mov	dx, tempY.WWF_int	; restore y scroll offset
		mov	cx, tempY.WWF_frac
		mov	ax, ds:[W_TMatrix].TM_22.WWF_frac
		mov	bx, ds:[W_TMatrix].TM_22.WWF_int
		call	GrMulWWFixed
		mov	tempY.WWF_frac, cx
		mov	tempY.WWF_int, dx

		; have scaled (dev coord) amount to scroll window.  Calc
		; source position of blt
haveScaledOffsets:
		mov	dx, ds:[W_winRect].R_left ; blt dest
		clr	cx
		mov	bx, ds:[W_winRect].R_top 
		clr	ax
		sub	cx, tempX.WWF_frac	; calc source x pos, fixed
		sbb	dx, tempX.WWF_int	;   then round result
		shl	cx, 1
		adc	dx, 0
		mov	srcX, dx		; save source x position
		sub	ax, tempY.WWF_frac	; calc source y pos, fixed
		sbb	bx, tempY.WWF_int	;   then round result
		shl	ax, 1
		adc	bx, 0
		mov	srcY, bx		; save source y position

		; calc integer difference between source and dest coords

		sub	dx, ds:[W_winRect].R_left 
		neg	dx
		sub	bx, ds:[W_winRect].R_top 
		neg	bx
		mov	cx, bx			; check for zero blt
		or	cx, dx
		tst	cx
		LONG jz	wsAlldone

		; divide by scale factor to back out the appropriate translation

		push	dx, bx			; save x/y trans amounts
		mov	tempX.WWF_int, dx	; assume 1.0 scale, init result
		clr	cx
		mov	tempX.WWF_frac, cx
		mov	tempY.WWF_int, bx	; assume 1.0 scale, init result
		mov	tempY.WWF_frac, cx
		test	ds:[W_TMatrix].TM_flags, TM_SCALED ; check for scale
		jz	haveTranslation
		mov	ax, ds:[W_TMatrix].TM_11.WWF_frac ; divide by scale
		mov	bx, ds:[W_TMatrix].TM_11.WWF_int  ;   do x first
		call	GrSDivWWFixed
		mov	tempX.WWF_frac, cx	; store result
		mov	tempX.WWF_int, dx
		mov	dx, tempY.WWF_int	; restore y info
		clr	cx
		mov	ax, ds:[W_TMatrix].TM_22.WWF_frac ; divide by scale
		mov	bx, ds:[W_TMatrix].TM_22.WWF_int  ;   do y
		call	GrSDivWWFixed
		mov	tempY.WWF_frac, cx	; store result
		mov	tempY.WWF_int, dx

		; have appropriate WWFixed translation to apply...
haveTranslation:
		mov	cx, tempX.WWF_frac	; load up translations
		mov	dx, tempX.WWF_int
		mov	ax, tempY.WWF_frac	; load up translations
		mov	bx, tempY.WWF_int
		call	WinApplyTransCommon	; do the matrix thing

		; restore translation amounts so we can shift regions...

		pop	cx, dx			; dx = deltaY;  cx = deltaX

		; Shift other valid regions in window.  If we are translating
		; in the positive direction, it means that these regions will
		; be moving in the negative direction, so reverse the signs

		ornf	ds:[W_TMatrix].TM_flags, TM_TRANSLATED ; 
		andnf	ds:[W_grFlags], not mask WGF_XFORM_VALID
		test	ds:[W_regFlags], mask WRF_CLOSED	; alive?
		jnz	wsAlldone		; if not, done
;PrintMessage <JIM: verify this change to WinScroll>
; Jim isn't ever going to verify this, this change was made 3 years ago,
; and it seems to work, so commenting out this PrintMessage - atw 3/26/96

;
; commented out to fix bugs #11588, #11773 & #12424
; Why is the mask region already where it should be? (ie. why does
; shifting it here cause it to be shifted twice as far as it should?)
; This suggests that it isn't being calculated correctly somewhere,
; because this code hasn't changed substantially since V1.X.
;
;;;		mov	si, ds:[W_invalReg]
;;;		mov	di, si			; end up in same chunk
;;;		call	ShiftRegion
		mov	si, ds:[W_updateReg]
		mov	di, si			; end up in same chunk
		call	ShiftRegion

		; since we don't call EnterGraphics, calc our own maskReg

		segmov	es, ds			; set up es -> window
		call	WinSetMaskReg		; set our region
		segmov	ds, es			; reset seg ptr

		; Blit moved portion of image if OK (check passed flag)

		mov	cx, ds:[W_winRect].R_left ; blt dest
		mov	dx, ds:[W_winRect].R_top 
		mov	ax, ds:[W_winRect].R_right ; get doc crds of win bounds
		mov	bx, ds:[W_winRect].R_bottom
		sub	ax, cx			; get width
		sub	bx, dx			; get height
		inc	ax			; plus one
		inc	bx
		mov_tr	si, ax			; save width in si

		; call BltCommon routine, setting new mask region first

		push	bx			; pass height on stack
		mov	ax, BLTM_MOVE		; pass invalidation flag
		push	ax
		mov	ax, ss:[srcX]		; restore parameters
		mov	bx, ss:[srcY]
		call	BltCommon		; call blt routine

	; set the maskReg to be invalid, so it's recalced
	; invalidate GState clip rectangle
	; invalidate Window clip rectangle

	andnf	{word}es:[W_grFlags], not (mask WGF_MASK_VALID or \
				  	   mask WGRF_PATH_VALID shl 8 or \
				  	   mask WGRF_WIN_PATH_VALID shl 8)

		; all done, unlock window and leave
wsAlldone:
		mov	bx,  ds:[W_header].LMBH_handle	; get window handle
		call	MemUnlockV		; unlock-disown window
		mov	cx, tempX.WWF_frac	; load up actual translations
		mov	dx, tempX.WWF_int
		mov	ax, tempY.WWF_frac
		mov	bx, tempY.WWF_int
wsExit:
		.leave
		ret
WinScroll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSetMaskReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a new mask region, without the help from a gstate.
		Obviously, does not include an app clip region

CALLED BY:	INTERNAL
		WinScroll, WinBitBlt

PASS:		es		- window struct

RETURN:		es		- new window segment (may have changed)
		es:W_maskReg 	- set to visReg AND updateReg AND NOT(invalReg)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do the region manipulations:

			temp1Reg = NOT(invalReg)
			maskReg  = temp1Reg AND visReg

		then fix the optimizaiton flags in the window struct;

		also, rounds up the usual optimizations, like checking
		for NULL regions before doing expensive operations...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	08/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinSetMaskReg	proc	near
		call	PushAllFar			; OK To use PushAll if
							;  saved ES is corrected
							;  in the PushAllFrame
							;  -- ardeb
		;uses	ds, si, di, bx, ax, cx, dx	; DON'T USE PUSHALL
		;.enter					;  HERE
						
		; set up ds -> window for region operations
		; and check for null inval reg

		segmov	ds, es
		mov	si, ds:[W_invalReg]		; check for null region
		mov	di, ds:[si]			; get pointer to chunk
		cmp	{word} ds:[di], EOREGREC	; NULL region ?
		jne	WSMR_invalValid			;  no, handle it

		; if no inval region, just use visReg

		mov	si, ds:[W_visReg]		; just use visReg
		mov	di, ds:[W_maskReg]		;  copy to maskReg
		call	FarWinCopyLocReg

		; all done, clean up and leave
WSMR_done:
		call	SetupMaskFlags			; set new opt flags

		mov	bp, sp				; ss:bp <- PushAllFrame
		mov	ss:[bp].PAF_es, es
		call	PopAllFar
		;.leave
		ret

;-------------------------------------------------------

		; handle non-NULL invalReg
		;   si = W_invalReg
WSMR_invalValid:
		mov	di, ds:[W_temp1Reg]		; set up region handle
		call	FarWinNOTReg			; form NOT(invalReg)
		mov	si, ds:[W_temp1Reg]		; supply handle
		mov	bx, ds:[W_visReg]		;  yes, AND w/vis
		mov	di, ds:[W_maskReg]		; destination
		call	FarWinANDReg			; perform first AND
		jmp	WSMR_done

WinSetMaskReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift a window region, and clip to VisRegion

CALLED BY:	WinScroll

PASS:		cx	- amount to shift in x direction
		dx	- amount to shift in y direction
		si	- handle of chunk holding region to shift
		di	- handle of chunk to store shifted region
		ds	- window segment

RETURN:		nothing

DESTROYED:	ax,bx,si,di,es

PSEUDO CODE/STRATEGY:
		copy the region to a temp space;
		shift the temp region;
		AND the temp region with VisRegion and store to dest;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	a while ago	initial revision
	Jim	4/89		Documented and fixed (added check for WHOLE_REG
				before calling GrMoveReg)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShiftRegion	proc	near
		push	cx			; save shift amount
		push	dx
		push	di			; save dest chunk handle
		push	cx			; save change amount
		push	dx
		segmov	es, ds			; move window seg to es
		mov	di, ds:[W_temp1Reg]	; copy source to W_temp1Reg
		call	FarWinCopyLocReg
		pop	dx			; restore shift amounts
		pop	cx
		mov	si, ds:[W_temp1Reg]	; shift W_temp1Reg
		mov	si, ds:[si]
		mov	ax, ds:[si]		; check for WHOLE_REG
		cmp	ax, WHOLE_REG		; if whole, then don't shift
		je	SR_10
		call	GrMoveReg		; move region
		;segmov	es, ds			; move window seg to es
		;				;  Already there -- ardeb

		; dest region = VisRegion AND Temp1Reg
SR_10:
		mov	bx, es:[W_visReg]	; bx = VisRegion handle
		mov	si, es:[W_temp1Reg]	; si = Temp1Reg handle
		pop	di			; di = dest region handle
		call	FarWinANDLocReg		; perform AND operation
		pop	dx			; restore shift amounts
		pop	cx
		ret
ShiftRegion	endp

GrWinBlt ends

WinMovable segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinMove

DESCRIPTION:	Moves a window, either relative to current position, or
		absolute (relative to parent).

CALLED BY:	GLOBAL

PASS:
	ax - x move value (nature depends on mask WPF_ABS)
	bx - y move value (nature depends on mask WPF_ABS)
	si - flags:
		mask WPF_ABS: clear for move relative to current position
			(signed), or set for new position (relative to
			parent windown)
	di - handle of graphics state OR window

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version (Broke out from WinMoveResize)
	doug	5/91		Updated documentation

------------------------------------------------------------------------------@

WinMove	proc	far
	call	PushAllFar

EC <	test	si, not mask WPF_ABS					>
EC <	ERROR_NZ WIN_MOVE_BAD_FLAGS					>

	; NOTE: When this routine change to use bitblt it must offset
	;	the update region and the invalid region by the move amount

	push	si
	push	ax
	push	bx

	call	WinChangeEnter		; Get winTreeSem, lock win & parent
	jnc	WMR_90			; If unsuccessful, quit
					; (Quits if window dying)

	clr	ds:[W_curState]		; clear out any tied GState
	call	WinChangePrep		; Clear any save-under THIS window has,
					; & init change bounds

	pop	dx
	pop	cx
	pop	ax

	test	ah, mask WPF_ABS shr 8	; See if relative move
	jz	WM_10			; branch if relative move
					; Convert from parent relative to abs.
	add	cx, es:[W_winRect.R_left]
	add	dx, es:[W_winRect.R_top]
					; subtract out current window abs. pos,
					; to make relative change value
	sub	cx, ds:[W_winRect.R_left]
	sub	dx, ds:[W_winRect.R_top]
WM_10:

	push	si
	mov	si, ds:[W_winReg]	; point to region
	mov	si, ds:[si]
	call	GrMoveReg		; Move the region by amount in cx, dx
	pop	si

				; HERE TO FINISH OFF W/CHILDREN
	call	WinMoveHere		; Move window reg of this window &
					;	all children by (cx, dx) amount
					; Get new window bounds
					; expand change bounds to be MAX of
					;	two rectangles
	call	LoadWinExpandChangeBounds

					; If there are any save-unders in the
					; area of our parent window, remove
					; those save-under areas & punch
					; through a hole in all underlying
					; windows.
	call	WinClearSaveUndersOverlappingParent

	mov	ax, WIN_V_PASSED_LAST
	call	WinTValidateHere	; Validate it.

WMR_90:
	call	FarVWinTree		; es <- idata

	call	PopAllFar
	ret

WinMove	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinResize

DESCRIPTION:	Resize a window and possibly move it.

CALLED BY:	GLOBAL

PASS:
	ax, bx, cx, dx	- paramters to region (or bounds, if rectangular)
	    The region/rectangle passed is in screen pixels to offset
	    from the parent window.  Remember, if passing a rectangle as a
	    region, you're passing offset pixel values for the right and
	    bottom, not document coord values.  The width of your rectangle
	    should be (right - left + 1) if your parameters are correct.
	    Ditto the height.
	bp:si		- region (0 for rectangular)
	di		- handle of graphics state OR window
	on stack	- WinPassFlags
		   	  mask WPF_ABS bit set to move/resize absolute

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Doug	4/91		Clarified coordinate doc

------------------------------------------------------------------------------@

WR_stack	struct
    WR_parentWin	hptr.Window
    WR_win		hptr.Window
    WR_origTop		word
    WR_origLeft		word
    WR_AX_PARAM	word
    WR_BX_PARAM	word
    WR_CX_PARAM	word
    WR_DX_PARAM	word
    WR_si		word
    WR_di		word
    WR_bp		word
    WR_ds		word
    WR_es		word
    WR_retAddr	fptr.far
    WR_flags	WinPassFlags
WR_stack	ends

WinResize	proc	far
	
if	FULL_EXECUTE_IN_PLACE
EC <	tst	bp						>
EC <	jz	continue					>
EC <	xchg	bx, bp						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	xchg	bx, bp						>
continue::
endif

	push	es
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax

	; NOTE: When this routine change to use bitblt it must offset
	;	the update region and the invalid region by the move amount

	call	WinChangeEnter		; Get winTreeSem, lock win & parent
	jnc	WR_90			; if not successful, quit
					; (Quits if window dying)

	clr	ds:[W_curState]		; clear out any tied GState
	call	WinChangePrep		; Clear any save-under THIS window has
					; & init change bounds

	push	ds:[W_winRect].R_left	; Save original left, top
	push	ds:[W_winRect].R_top

	push	si			; save win handle, parent handle
	push	di
	mov	bp,sp
	; if setting absolute position then set W_winRect.R_left and W_winRect.R_top to
	; parent's left and top

	test	ss:[bp].WR_flags,mask WPF_ABS
	jz	WR_relative
	segmov	ax, es
	tst	ax
	jz	WR_parentIsRoot
	mov	ax,es:[W_winRect].R_left
	mov	ds:[W_winRect].R_left,ax
	mov	ax,es:[W_winRect].R_top
	mov	ds:[W_winRect].R_top,ax
	jmp	WR_relative
WR_parentIsRoot:
	mov	ds:[W_winRect].R_left,ax
	mov	ds:[W_winRect].R_top,ax

WR_relative:

	mov	dx,ss			; pass dx:cx = paramters
	lea	cx,[bp].WR_AX_PARAM
	mov	di,ss:[bp].WR_si	; region to pass
	mov	bp,ss:[bp].WR_bp
	call	SetupWinReg		; Copy region definition to W_winReg
	call	WinCalcWinBounds	; Generate wWinBounds

					; Get new window bounds
					; expand change bounds to be MAX of
					;	two rectangles
	call	LoadWinExpandChangeBounds

	; CAUSE WINDOW TO BE REDRAWN COMPLETELY
	push	es
	segmov	es, ds
	call	WinNULLVisReg		; init visible region to NULL
	pop	es

	pop	di
	pop	si
					; Get new left & top
	mov	cx, ds:[W_winRect].R_left
	mov	dx, ds:[W_winRect].R_top
	pop	bx			; get original left, top
	pop	ax
	sub	cx, ax			; get delta movement of window
	sub	dx, bx
	call	WinMoveHere		; Move window reg of this window &
					;	all children by (cx, dx) amount

					; If there are any save-unders in the
					; area of our parent window, remove
					; those save-under areas & punch
					; through a hole in all underlying
					; windows.
	call	WinClearSaveUndersOverlappingParent

	mov	ax, WIN_V_PASSED_LAST
	call	WinTValidateHere	; Validate it.

WR_90:
	call	FarVWinTree		; es <- idata

	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es
	ret	2

WinResize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinNULLVisReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	NULL the visible region (and inval the application regions)
CALLED BY:	WinResize()

PASS:		ds,es - seg addr of Window
RETURN:		ds,es - seg addr of Window (may have moved)
DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinNULLVisReg	proc	near
	.enter

	andnf	ds:[W_grRegFlags], not (mask WGRF_PATH_VALID or \
				        mask WGRF_WIN_PATH_VALID)
	mov	di, ds:[W_visReg]
	call	FarWinNULLReg		; init W_visReg to NULL

	.leave
	ret
WinNULLVisReg	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinMoveHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves all child windows of current window by some amount

CALLED BY:	WinMoveResize

PASS:		cx	- x amount to move (signed)
		dx	- y amount to move (signed)
		si	- handle of current window
		ds	- segment of locked window block whose children we
				should move
RETURN:		Windows below this one moved

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/28/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinMoveHere	proc	near
				; si = handle of original window
	push	es		; save parent seg
	segmov	es, ds		; set ds & es both segment of window

	push	cx
	push	dx
	push	si
	push	di
	cmp	si, ds:[W_header.LMBH_handle]	; Don't move if original window
					;	(already moved)
	je	WMH_10
				; MOVE THIS window's region
	mov	ax, cx
	or	ax, dx
	jz	WMH_10			; if no movement, don't bother
	mov	si, ds:[W_winReg]	; point to region
	mov	si, ds:[si]
	call	GrMoveReg		; Move the region
WMH_10:
				; GET NEW WINDOW BOUNDS
	call	WinCalcWinBounds	; Correct wWinBounds
				; NULL VIS REGION
; MORE TO DO
; REMOVE clear of vis region.  Instead:
;	Shift W_winReg & W_visReg for this window & all children.
;	Do WinTValidateHere --  For this window only,
;	after new W_univReg is calculated,  bitblit OLD W_univReg, shifted
;	by amount of movement using NEW W_univReg as a mask.
	call	WinNULLVisReg		; init W_visReg to NULL

	pop	di
	pop	si
	pop	dx
	pop	cx

				; Fetch handle of first child
	mov	bx, ds:[W_firstChild]

WMH_20:
	tst	bx		; no more children?
	je	WMH_70		; if done w/children, exit
				; if so, lock it!
	call	WinPLockDS
	push	bx		; save window handle
	call	WinMoveHere	; YES, IT'S RECURSIVE!
				; Get handle of the next sibling
	pop	bx		; Free up the window
	push	cx		; but don't destroy cx in process
	mov	cx, ds:[W_nextSibling]
	call	WinUnlockV
	mov	bx, cx		; Put handle of next sibling into bx
	pop	cx
	jmp	WMH_20	; loop to do them all

WMH_70:
	mov	ax, es		; make parent our child again
	mov	ds, ax
	pop	es		; restore parent's segment
	ret
WinMoveHere	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinChangePriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change a window's priority on screen

CALLED BY:	GLOBAL

PASS:
		ax	- flags:
			mask WPF_LAYER - set to perform a layer priority
				change.  Affects all child windows
				of this window, which have layerID
				equal to the one passed in dx.  Only the
				WPD_LAYER priority value is used.
			mask WPF_PLACE_BEHIND - set if to place in BACK of other
				windows in same priority group, clear
				if in FRONT
				(Valid ONLY if WPF_LAYER passed FALSE)
			mask WPF_PLACE_LAYER_BEHIND - set if to place layer
				in BACK of other layers of same
				priority group, clear if in FRONT
				(Valid ONLY if WPF_LAYER passed TRUE)

			Bits 7-0	- priority (or 0 to keep current
					  priority)
		dx	- LayerID.  If WPF_LAYER passed TRUE, is layer of
			  windows to raise/lower.  If WPF_LAYER passed FALSE,
			  is optional new LayerID for window (pass 0 to keep
			  current priority)

		di	- handle of graphics state OR window
				REMEMBER: If WPF_LAYER is set, this should be the
				parent window of the window that is to be moved.

RETURN:

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		Lock parent of window;
		Remove window from sibling chain -- if at end of chain,
			adjust parent's sibling connections;
		Search sibling chain for new desired priority location;
		Add window back into new position in chain;
		call WinTValidateChildren for each window between this one and
			the one to the right of the old position.
		Mark superior as having invalid W_maskRegion (we've munched it)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK
	Doug	6/23/92		Added ability to pass new LayerID

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinChangePriority	proc	far
	call	PushAllFar

EC <	test	ax, not (mask WPF_PLACE_BEHIND or mask WPF_LAYER or mask WPF_PLACE_LAYER_BEHIND or mask WPF_PRIORITY)	>
EC <	jz	WCP_2							>
EC <	ERROR	WIN_CHANGE_PRIO_BAD_FLAGS				>
EC <WCP_2:								>

	mov	cx, ax			; Keep priority change flags in cx
	call	WinChangeEnter
	LONG	jnc	done		; if unsuccesful, quit from this win
					; (Quits if window dying)

; Optimization for bringing window to top when already there {
	tst	cx
	jnz	skipOptimization	; skip if not bringing window
	tst	ds:[W_prevSibling]	;	to front
	LONG jz	unlockDone		; if already at front, done
skipOptimization:
;}

	push	cx, dx
	call	LoadWinSetChangeBounds	; Init change area to size of original
					;	window, in case not doing layer
	pop	cx, dx

	mov	ax, ds:[LMBH_handle]	; Assume one window
	test	cx, mask WPF_LAYER	; doing layer operation?
	jnz	layerPriorityChange

;windowPriorityChange:
	tst	dx			; If NULL LayerID passed, no change
	jz	continuePriorityChange
	mov	ds:[W_layerID], dx	; Store new LayerID
	jmp	short continuePriorityChange

layerPriorityChange:
	and	cl, mask WPD_LAYER	; make sure only layer priority passed

	; Find windows in Layer
	;
	push	cx
	call	WinFindWindowsInLayer	; Returns si = first win, bp = last)
	pop	cx

	tst	si			; any windows found to do?
	jz	unlockDone		; if not, unlock & get out of here
	mov	bx, si			; setup ds to be seg of first one
	call	WinPLockDS
	mov	ax, bp			; pass last window to do in ax

continuePriorityChange:
	push	ax

	push	ax			; last window to do
	call	WinFindChildNumber	; dx = child # of window
	pop	ax			; handle of last window to be removed
	push	dx			; save old position #
	call	WinTRemove		; Remove window from list
					; bx = original right sibling
	push	bx			; Preserve original right sibling
	call	WinTLocateInsertionPoint; Locate new position, given priority
	mov	bp, cx			; Keep placement flags, in bp
	pop	cx			; Place original right sibling into cx
					; bx = new right sibling
					; dx = insertion position #
	pop	ax
					; skip if other windows in same layer
					; (Don't have to do special check if
					; so)
	jnz	afterCheckForMovingSingleWinWithinLayer
	test	bp, mask WPF_LAYER	; doing layer operation?
					; if so, doesn't matter whether there
					; was just one window there or not.
	jnz	afterCheckForMovingSingleWinWithinLayer
	mov	bx, cx			; If moving a window within its layer,
	mov	dx, ax			; & the layer contains only one
					; window, don't move it anywhere.
afterCheckForMovingSingleWinWithinLayer:
					; See if inserted back in same position
	cmp	dx, ax			; see if moved at all
	pop	ax			; but first, restore handle of last
					; window inserted
	jne	winMoved

	call	WinTInsertHere		; Insert the sequence back where was
					; in the first place
unlockDone:
					; if not, just 
	call	WinUnlockVBoth		; Unlock win & parent
	jmp	short done		; & we're done.

winMoved:
	; HANDLE MOVEMENT OF WINDOW(S) TO NEW LOCATION IN LINKAGE HERE
					; wChangeBounds is expanded bounds
	pushf				; save flags saying which way moved
	push	cx			; save orig right sibling for validate

	push	bx
	mov	bx, cx			; First, insert back into old location
	call	WinTInsertHere
	push	ax
					; If there are any save-unders in the
					; area of our parent window, remove
					; those save-under areas & punch
					; through a hole in all underlying
					; windows.
					; Note that the windows are still
					; in original order within the tree,
					; so this function will do the
					; correct thing.
	call	WinClearSaveUndersOverlappingParent

	pop	ax			; fetch end of chain to remove
	call	WinTRemove
	pop	bx			; fetch new right sibling into bx
	call	WinTInsertHere		; Insert the sequence into its new
					; location
	pop	cx			; orig sibling to right
	popf				; flag indicating which way moved
	jbe	movingForward

;movingBackward:
	; HANDLE CASE OF WINDOW MOVING BACKWARDS HERE
	;
	call	WinUnlockVBoth		; unlock first window being moved

EC <	tst	cx			; If no windows to the right, death  >
EC <	ERROR_Z	WIN_ERROR_MOVING_WINDOW_ALREADY_IN_BACK_TO_BACK		     >

	mov	bx, cx			; Start at the first window to right
	call	WinLockWinAndParent	; of orig group before move

					; Set bounds to full graphics space
					; so ALL windows are done.  This has
					; to be done, as the optimization of
					; stopping as soon as a window enclosing
					; the change bounds is done doesn't
					; work here -- the windows moved to
					; the back ALWAYS need to be updated,
					; & must'nt be skipped.
	mov	ax, MIN_COORD
	mov	bx, ax
	mov	cx, MAX_COORD
	mov	dx, cx
	call	SetChangeBounds

	mov	ax, WIN_NO_PARENT_AFFECT or WIN_V_PASSED_LAST
	call	WinTValidateHere	; Validate everything.
	jmp	short done


movingForward:
	; HANDLE CASE OF WINDOW MOVING FORWARD HERE

validateLoop:
	push	ax			; save handle of last window to validate

	call	WinChangePrep		; Init change bounds

					; Because we might be moving to the
					; front, we will temporarily have
					; overlapping universes & vises, so
					; used "V_PASSED_LAST" option to 
					; prevent drawing glitches

	push	ds:[W_nextSibling]	; save handle of next sibling to do,
					; in case validating multiple windows

	mov	ax, WIN_NO_PARENT_AFFECT OR WIN_V_PASSED_LAST

;	If we are doing a layer priority change, then multiple windows are
;	moving at once, so set the flag to avoid doing the
;	CheckIfChangeCompletelyInWin optimization - since we are moving
;	multiple windows, we have to validate all the windows beneath us,
;	even if one of the windows entirely overlaps this window, because
;	that window may have just moved to the foreground also. Otherwise,
;	there is a period of time between when the uppermost window in a layer
;	is validated and when the bottommost window in the layer is validated,
;	where windows under the bottommost window will not have valid visible
;	regions.
;	

	test	bp, mask WPF_LAYER
	jz	notLayer
	ornf	ax, mask WVF_LAYER_CHANGE
notLayer:
	push	si
	call	WinTValidateOpen	; Validate window moving towards front,
	pop	si			; or moving twoards back w/a little
					; extra work of doing siblings to
					; right which didn't need it, but
					; this doesn't hurt anything.

	pop	bx			; pop handle of NEXT window to do,
					; if doing multiple windows

	pop	ax			; restore handle of last window to 
					; validate.
	cmp	si, ax			; done w/last window?
	je	done		; if so, branch, done w/windows changed

	; Validate NEXT window in list
	;
	push	ax			; save LAST window to do
	call	WinLockWinAndParent	; lock window & parent of next window to
	pop	ax			; do
	jmp	short validateLoop


done:
	call	FarVWinTree 		; Release tree
	call	PopAllFar
	ret

WinChangePriority	endp

;
;----------------------
;

WinUnlockVBoth	proc	near	uses	ax, bx
	.enter
	mov	bx, si
	tst	bx
	je	AfterSI
	call	WinUnlockV
AfterSI:
	mov	bx, di
	tst	bx
	je	AfterDI
	call	WinUnlockV
AfterDI:
	.leave
	ret
WinUnlockVBoth	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinFindWindowsInLayer

DESCRIPTION:	Find all windows in the given layer.  At the same time, 
		substitutes a new LayerID.

CALLED BY:	INTERNAL
		WinChangePriority

PASS:
	si	- handle of window
	di	- handle of window's parent
			OR NUL if no parent
	ds	- segment of window
	es	- segment of window's parent (or NULL if no parent)

	cx	- WinPassFlags
	dx	- LayerID of window to look for

RETURN:	
	si	- first window in layer (or 0 if none)
	bp	- last window in layer

	di	- handle of passed window
	ds	- segment of first window in layer (N/A if none)
	es	- segment of passed window

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Split out for clarity 
------------------------------------------------------------------------------@

WinFindWindowsInLayer	proc	near
	push	si			; Save handle of window passed in for
					; end, to return in di

					; First, unlock parent window, as
					; won't be used

	mov	bx, di
	tst	bx
	jz	afterParentUnlocked
	call	WinUnlockV
afterParentUnlocked:

					; move down a layer in win tree -
	segmov	es, ds			; passed window is now parent
	clr	si			; haven't found first win of layer yet
	clr	bp			; nor last
	mov	ax, es:[W_firstChild]	; start at first child
layerLoop:
	mov	bx, ax
	tst	bx
	jz	noMoreWindowsInLayer
	call	WinPLockDS
	cmp	dx, ds:[W_layerID]	; of correct layer?
	jne	afterWindowHandled
	tst	si
	jnz	handleNextWindow

	push	bx, cx, dx
	call	LoadWinSetChangeBounds	; Init change area to size of original
					; window
	pop	bx, cx, dx

	mov	si, bx			; Store first window of layer to change
					; Now that we have first window of
					; layer, fetch current layer priority
					; from it if we were passed "0" as
					; a layer priority for change
	mov	bp, bx			; Storelast window of layer to change
	tst	cl
	jnz	10$
	mov	al, ds:[W_priority]	; if passed layer prio of 0, use current
	and	al, mask WPD_LAYER
	mov	cl, al
10$:
	jmp	short afterWindowHandled

handleNextWindow:
	push	bx, cx, dx
					; Init change area to size of original
					; expand change bounds to include this
					;	window
	call	LoadWinExpandChangeBounds
	pop	bx, cx, dx

	mov	bp, bx			; Store new "last" window to change
	mov	al, ds:[W_priority]	; Change layer priority of window to
					; that passed.
	and	al, not mask WPD_LAYER
	or	al, cl
	mov	ds:[W_priority], al
afterWindowHandled:
	mov	ax, ds:[W_nextSibling]	; get next sibling for next loop
	call	WinUnlockV
	jmp	short layerLoop		; keep going, until last win of layer
					; found.

noMoreWindowsInLayer:
	pop	di
	ret
WinFindWindowsInLayer	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinFindChildNumber
DESCRIPTION:	Determine child # of a given window.  Window may be currently
		PLock'd, without deadlock occurring
PASS:
	es	- locked segment of window's parent win
	si	- handle of window to determine child # of
RETURN:
	dx	- child #
DESTROYED:
	Nothing

------------------------------------------------------------------------------@

WinFindChildNumber	proc	near	uses ax, bx, ds
	.enter
	mov	ax, es:[W_firstChild]	; start at first child
	clr	dx			; init counter
countLoop:
	cmp	ax, si			; a match?
	je	done			; if so, done
	inc	dx			; else inc counter
	mov_tr	bx, ax
	call	WinPLockDS		; Lock next window in list to search
	mov	ax, ds:[W_nextSibling]	; fetch sibling for next round
	call	WinUnlockV
	jmp	short countLoop
done:
	.leave
	ret
WinFindChildNumber	endp





COMMENT @----------------------------------------------------------------------

FUNCTION:	WinChangeEnter

DESCRIPTION:	Does a few things common to the beginnings of WinMove,
		WinResize & WinChangePriority:  Gets winTreeSem, & locks
		the passed window & its parent

CALLED BY:	INTERNAL
		WinMove, WinResize, WinChangePriority

PASS:
	di	- gstate or window handle

RETURN:
	Carry	- set if successful, continue operation.  clear if neither
		  block locked.  Generally clear only if window is marked
		  as dying.
	si	- handle of new window
	di	- handle of parent
			OR NULL_WINDOW if opening root window
	ds	- segment of window
	es	- segment of parent (or NULL_WINDOW if window is root)


DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

WinChangeEnter	proc	near
	push	es
	call	FarPWinTree
	pop	es

	call	FarWinHandleFromDI	; get window handle in di
	mov	bx, di			; pass in bx
	call	WinLockWinAndParent	; lock window & parent
	ret

WinChangeEnter	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinChangePrep

DESCRIPTION:	Does a few things common to the middle of WinMove,
		WinResize & WinChangePriority:  Gets the bounds of the
		window (before the operation) & inits the wChange bounds
		variable with that.  Then clears any save-under the 
		window may have, to clear the path for a larger change.

CALLED BY:	INTERNAL
		WinMove, WinResize, WinChangePriority

PASS:
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


RETURN:
	ax, bx, cx, dx, - bounds of window

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	doug	3/93		Bug fix described below
------------------------------------------------------------------------------@

WinChangePrep	proc	near
	; Changed to load change bounds FIRST, since WinTValidateOpen for
	; save-under case actually depends on this for deciding whether 
	; the OBSCURE may be terminated early or not. -- Doug 3/17/93
	;
	call	LoadWinSetChangeBounds	; Init change area to size of original
					;	window.
	cmp	ds:[W_saveUnder], 0	; does window have save under area?
	jz	AfterSaveUnder		; skip if not

EC <	push	ax, bx, cx, dx		; save bounds for test		>

	push	ds:[LMBH_handle]	; save handle of our window
					; REMOVE any save-under area this
					; 	window is using
	mov	ax, WIN_V_PASSED_LAST OR WIN_CLEAR_SAVE_UNDER
	call	WinTValidateOpen
	pop	bx			; get handle of window back, in bx

					; re-lock window & parent
	call	WinLockWinAndParent	; setup si, di, ds & es for window to
					;	clear save under for

EC <	; Blow up if window bounds have changed, as we're not	>
EC <	; expecting that to be able to happen			>
EC <	;							>
EC <	pop	ax						>
EC <	cmp	ax, ds:[W_winRect].R_bottom			>
EC <	ERROR_NE	WIN_BAD_ASSUMPTION			>
EC <	pop	ax						>
EC <	cmp	ax, ds:[W_winRect].R_right			>
EC <	ERROR_NE	WIN_BAD_ASSUMPTION			>
EC <	pop	ax						>
EC <	cmp	ax, ds:[W_winRect].R_top			>
EC <	ERROR_NE	WIN_BAD_ASSUMPTION			>
EC <	pop	ax						>
EC <	cmp	ax, ds:[W_winRect].R_left			>
EC <	ERROR_NE	WIN_BAD_ASSUMPTION			>

	call	LoadWinBounds		; get window bounds back in regs

AfterSaveUnder:
	ret

WinChangePrep	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinGetOverlyingSaveUnders

DESCRIPTION:	Get mask of any save-under areas which are AT OR ABOVE this
		window.  This idea is to try find only the save-unders which
		would be effected by even the opening of a window having 
		save under.

		NOTE:  This routine could actually just clear ALL save unders
		overlapping the bounds passed, without causing any bugs,
		other than having the effect of nuking save unders that it
		didn't need to.  Because of this, and because of the general
		problem of determining whether a window is above or below
		another window, this routine will only leave intact overlapping
		save-unders which belong to siblings to the right of the passed
		window.

CALLED BY:	INTERNAL

PASS:
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


RETURN:
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

WinGetOverlyingSaveUnders	proc	near
	call	GetChangeBounds		; fetch wChange bounds in ax, bx, cx, dx
	push	di
	mov	di,DR_VID_CHECK_UNDER	; See if any overlaps w/save under
					;	areas.
	call	WinCallVidDriver
	pop	di
	tst	al
	jz	done
					; Now, see if any of these save under
					; areas belong to siblings to our
					; right -- if so, leave them alone,
					; they are below this window & therefore
					; unaffected.
	push	ds
	mov	bx, ds:[W_nextSibling]	; start w/first sibling to right

siblingLoop:
	tst	bx
	jz	noMoreSiblingsToRight
	push	ax
	call	WinPLockDS		; Lock next sibling to right
	pop	ax
	mov	ah, ds:[W_saveUnder]	; fetch save under mask, if any, for 
	not	ah			;	window, & get AND mask to clear
	and	al, ah			;	this bit out of our list
	mov	dx, ds:[W_nextSibling]	; Get handle of next sibling to right
	call	WinUnlockV
	mov	bx, dx
	jmp	short siblingLoop

noMoreSiblingsToRight:
	pop	ds
done:
	ret

WinGetOverlyingSaveUnders	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinClearSaveUndersOverlappingParent

DESCRIPTION:	If there ANY save under areas which overlap the current
		wChange bounds, then CLEAR them (mark them as invalid)

CALLED BY:	INTERNAL

PASS:
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


RETURN:
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

WinClearSaveUndersOverlappingParent	proc	near

	; If not at root, fetch Parent window's bounds.  If at root, will
	; have to settle for Root window's bounds.
	;
	push	ds, es
	mov	ax, es			; special case root window
	tst	ax
	jz	root
	segxchg	ds, es			; if parent exists, switch segment to DS
root:
	call	LoadWinBounds		; fetch bounds of window at ds:0
	pop	ds, es

	push	di
	mov	di,DR_VID_CHECK_UNDER	; See if any overlaps w/save under
					;	areas.
	call	WinCallVidDriver
	pop	di

	FALL_THRU	WinClearSaveUnders	; Clear these save under areas

WinClearSaveUndersOverlappingParent	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinClearSaveUnders

DESCRIPTION:	Clear save unders passed

CALLED BY:	INTERNAL

PASS:
	winTreeSem	- P'd
	al		- bit mask of save under areas to remove
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


RETURN:
	winTreeSem	- P'd
	window, parent window, locked & owned
	si		- handle of window
	ds		- segment of window
	di		- handle of parent's window
	es		- segment of parent's window
			OR NULL_WINDOW if at root


DESTROYED:
	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

WinClearSaveUnders	proc	near
	tst	al			; if none, then we're all done
	jz	Done
					; Otherwise, have to remove save
					; under from each of these.
	call	WinUnlockVBoth		; release the window & its parent.
	mov	bx, si			; pass handle in bx
	push	bx			; Save handle of our window
	call	WinClearSaveUndersLow	; Clear these save-under areas
	pop	bx			; get handle of window back, in bx
					; re-lock window & parent
	call	WinLockWinAndParent	; setup si, di, ds & es for window to
					;	clear save under for
Done:
	ret
WinClearSaveUnders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search sibling chain for new desired priority location,
		and add window, connecting it into the tree.

CALLED BY:	INTERNAL
		WinChangePriority
		WinOpen

PASS:
		es	- seg of Parent window (locked)
		ds	- seg of window to add (locked)
		si	- handle of new window
		di	- handle of parent

		cl	- placement priority (to be compared w/W_priority
			  of sibling windows to determine where to
			  open the window).  This value is stored in the
			  window's W_priority field.  Either layer or
			  window priority may be 0, in which case the current
			  priority value is used.

		ch	- mask WPF_PLACE_BEHIND shr 8 set if window should be
			  placed in back of other windows within priority
			  group, or if no other windows of same layer, then
			  mask WPF_PLACE_LAYER_BEHIND shr 8 is set if
			  layer should be placed in back of other
			  layers with same priority

		ax	- handle of LAST window to be inserted.  If the
			  same as ds:[0], then only one window is being
			  inserted.  If different, then several already linked
			  windows are to be inserted, based on the priority
			  of the top (first) window.  The other windows should
			  already have had their W_priority field updated,
			  BEFORE calling this routine, as this routine only
			  updates the first window.  To be used for changing
			  a layer's priority, or bringing a layer to front
			  or back.  Also, only the first window has the
			  W_parent link stuff in it, so any others that
			  would need this would have to be done before this
			  routine is called as well.
RETURN:
		dx	- child # of window once inserted

		ds, es, si, di	- unchanged
		ax, bx, cx, bp	- unchanged
		Window structure links updated to remove window



DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTInsert	proc	near	uses bx
	.enter
	call	WinTLocateInsertionPoint
	call	WinTInsertHere
	.leave
	ret
WinTInsert	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTLocateInsertionPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search sibling chain for new desired priority location

CALLED BY:	INTERNAL
		WinTInsert

PASS:
		es	- seg of Parent window (locked)
		ds	- seg of window to add (locked)
		si	- handle of new window
		di	- handle of parent

		cl	- placement priority (to be compared w/W_priority
			  of sibling windows to determine where to
			  open the window).  This value is stored in the
			  window's W_priority field.  Either layer or
			  window priority may be 0, in which case the current
			  priority value is used.

		ch	- mask WPF_PLACE_BEHIND shr 8 set if window should be
			  placed in back of other windows within priority
			  group, or if no other windows of same layer, then
			  mask WPF_PLACE_LAYER_BEHIND shr 8 is set if
			  layer should be placed in back of other
			  layers with same priority



RETURN:
		Zero flag	- non-zero if at least one window having the
				  same layerID as that passed was found
		dx	- child # of insert point window
		bx 	- handle of sibling to insert before, or 0 to insert at
		     	  end.

		ds, es, si, di	- unchanged
		ax, cx, bp	- unchanged
		Window structure links updated to insert window



DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version
	Doug	2/90		Split out from WinTInsert

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTLocateInsertionPoint	proc	near	uses	ax, cx, bp, ds
	.enter

EC <	call	CheckDeathVigil		; Fatal err if win closed	>
EC <	call	WinCheckRegPtr					>

	test	cl, mask WPD_LAYER
	jnz	10$
	mov	al, ds:[W_priority]	; if passed layer prio of 0, use current
	and	al, mask WPD_LAYER
	or	cl, al
10$:
	test	cl, mask WPD_WIN
	jnz	20$
	mov	al, ds:[W_priority]	; if passed win prio of 0, use current
	and	al, mask WPD_WIN
	or	cl, al
20$:
	mov	ds:[W_priority], cl	; store new priority level in window

	; First, look to see if there are other windows in the same layer
	; or not.
	;
	mov	ax, es:[W_firstChild]	; start at first child
	mov	dx, ds:[W_layerID]	; get layerID to find
	clr	bp			; init child counter
	call	FindExistingLayer	; look for a window w/same layerID &
					; layer priority

	tst	bx			; if match found, insert in layer
	pushf				; Save flags for whether layer was
					; 	found or not
	jnz	insertInLayer

					; Otherwise, insert new layer
;insertNewLayer:
	mov	ax, es:[W_firstChild]	; start at first child
	clr	bp			; start counting over again
	call	FindLayerInsertPos	; find position to insert new layer
	jmp	short done

insertInLayer:
					; cl = priorities of first window
					; in layer.  We don't allow different
					; layer priorities for the same
					; layerID, so EC could be added here
					; to make sure of this
;MORE TO DO:  Add EC here (explained      ^^^)
	mov	ax, bx			; start at first window in layer
	call	FindWindowInsertPos	; find position to insert within layer
done:
	popf				; Return flags for whether layer was
					;	found
	mov	dx, bp
	.leave
	ret

WinTLocateInsertionPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTInsertHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a chain into a window branch, at a particular spot

CALLED BY:	INTERNAL
		WinTInsert

PASS:
		es	- seg of Parent window (locked)
		ds	- seg of window to add (locked)
		si	- handle of new window
		di	- handle of parent

		bx	- handle of sibling to insert before, or 0 to insert at
		     	  end.
		ax	- handle of LAST window to be inserted.  If the
			  same as ds:[0], then only one window is being
			  inserted.  If different, then several already linked
			  windows are to be inserted, based on the priority
			  of the top (first) window.  The other windows should
			  already have had their W_priority field updated,
			  BEFORE calling this routine, as this routine only
			  updates the first window.  To be used for changing
			  a layer's priority, or bringing a layer to front
			  or back.  Also, only the first window has the
			  W_parent link stuff in it, so any others that
			  would need this would have to be done before this
			  routine is called as well.
RETURN:
		ds, es, si, di	- unchanged
		ax, bx, cx, bp	- unchanged
		Window structure links updated to remove window



DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTInsertHere	proc	near	uses ax, bx, dx
	.enter
	push	di
	push	ds
	mov	di, ax			; keep LAST window in di
			; HAVE FOUND insertion point:
			; bx = handle of window to insert in front of, or 0
			; to insert at end.

	tst	bx			; are we adding at end?
	jz	InsertAtEnd		; branch if so
	call	WinPLockDS		; Lock next sibling
	mov	dx, ds:[W_prevSibling]	; fetch old previous sibling
	mov	ds:[W_prevSibling], di	; store the LAST window being added
					; into next child's prev
					; release to-be next sibling.
	call	WinUnlockV
	jmp	afterNextSiblingUpdated

InsertAtEnd:
	mov	dx, es:[W_lastChild]	; fetch handle of old last child
	mov	es:[W_lastChild], di	; else store as last child to
					;	parent window
afterNextSiblingUpdated:
	xchg	bx, dx
			; bx = handle of previous sibling
			; dx = handle of next sibling

	tst	bx			; are we adding at beginning?
	jz	InsertAtBeginning			; branch if so
	call	WinPLockDS
	mov	ds:[W_nextSibling], si	; store next sibling pointer
	call	WinUnlockV
	jmp	short afterPrevSiblingUpdated

InsertAtBeginning:
	mov	es:[W_firstChild], si	; else store as first child to
					;	parent window
afterPrevSiblingUpdated:
	pop	ds			; get seg to window to add
	mov	ds:[W_prevSibling], bx	; hook into chain

	cmp	di, ds:[LMBH_handle]	; inserting one window?
	je	insertingOne
	mov	bx, di			; if more than one, have to fix 
					; nextSibling link of LAST window.
	push	ds
	call	WinPLockDS
	mov	ds:[W_nextSibling], dx
	call	WinUnlockV
	pop	ds
	jmp	short afterNextSiblingLink

insertingOne:
	mov	ds:[W_nextSibling], dx

afterNextSiblingLink:
	pop	di
	mov	ds:[W_parent], di	; store handle of parent
	.leave
	ret

WinTInsertHere	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	FindExistingLayer
DESCRIPTION:	Looks for first window at or to the right of the window passed
		which has the same LayerID as that passed.
PASS:
	ax	- handle of first window to start search at
	dx	- layerID to look for.
	bp	- starting count #
RETURN:
	al	- W_priority of matching window, if found
	bx	- first matching window, or 0 if not found.
	bp	- count incremented by # of children passed up
DESTROYED:
	ax

------------------------------------------------------------------------------@

FindExistingLayer	proc	near	uses	cx, dx, ds
	.enter
	dec	bp			; correct for inc at start of loop
findLoop:
	inc	bp			; count one more child
	mov_tr	bx, ax
	tst	bx			; if end of list, quit
	jz	done

	call	WinPLockDS		; Lock next window in list to search
	mov	ax, ds:[W_nextSibling]	; fetch sibling for next round
	mov	cl, ds:[W_priority]	; fetch priorities, in case layer found
	cmp	dx, ds:[W_layerID]	; compare layer ID
	call	WinUnlockV
	jne	findLoop		; keep looking
	mov	al, cl			; return priorities in al
done:
	.leave
	ret
FindExistingLayer	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindLayerInsertPos
DESCRIPTION:	Looks for first window at or to the right of the window passed
		which has the same or higher layer priority than the value
		passed.  Used when there is no window at this level in the
		window tree which has the same layerID & layer priority as
		this window.
PASS:
	ax	- handle of first window to start search at
	cl	- WinPriorityData (Has LayerPriority to compare with)
	ch	- mask WPF_PLACE_BEHIND shr 8 set if window should be
			  placed in back of other windows within priority
			  group, or if no other windows of same layer, then
			  mask WPF_PLACE_LAYER_BEHIND shr 8 is set if
			  layer should be placed in back of other
			  layers with same priority

	bp	- starting count #
RETURN:
	bx	- first window to match criteria, or 0 for end of list
	bp	- count incremented by # of children passed up
DESTROYED:
	ax

------------------------------------------------------------------------------@

FindLayerInsertPos	proc	near	uses	dx, ds
	.enter
	dec	bp			; correct for inc at start of loop
findLoop:
	inc	bp			; count one more child
	mov_tr	bx, ax
	tst	bx			; if end of list, quit
	jz	done

	call	WinPLockDS		; Lock next window in list to search
	mov	ax, ds:[W_nextSibling]	; fetch sibling for next round
	mov	dh, ds:[W_priority]	; & fetch priority value
	call	WinUnlockV

	and	dh, mask WPD_LAYER
	mov	dl, cl
	and	dl, mask WPD_LAYER
	cmp	dh, dl
	jb	findLoop		; if window has lower priority value,
					; can't insert here, loop

	ja	done			; if window has higher, insert here,
					; done.

					; For the border line case, see if
					; placing in front or behind

	test	ch, mask WPF_PLACE_LAYER_BEHIND shr 8
	jnz	findLoop		; if behind, loop & keep going.
done:
	.leave
	ret
FindLayerInsertPos	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindWindowInsertPos
DESCRIPTION:	Looks for first window at or to the right of the window passed
		which has the same or higher layer priority than the value
		passed, AND is in the same LayerID group.
PASS:
	ax	- handle of first window to start search at
	cl	- WinPriorityData (Has WinPriority to compare with)
	ch	- mask WPF_PLACE_BEHIND shr 8 set if window should be
			  placed in back of other windows within priority
			  group, or if no other windows of same layer, then
			  mask WPF_PLACE_LAYER_BEHIND shr 8 is set if
			  layer should be placed in back of other
			  layers with same priority

	dx	- layerID to look for.
	bp	- starting count #
RETURN:
	bx	- first window to match criteria, or 0 for end of list
	bp	- count incremented by # of children passed up
DESTROYED:
	ax

------------------------------------------------------------------------------@

FindWindowInsertPos	proc	near	uses	dx, si, di, ds
	.enter
	mov	si, dx			; keep layerID in si
	dec	bp			; correct for inc at start of loop
findLoop:
	inc	bp			; count one more child
	mov_tr	bx, ax
	tst	bx			; if end of list, quit
	jz	done

	call	WinPLockDS		; Lock next window in list to search
	mov	ax, ds:[W_nextSibling]	; fetch sibling for next round
	mov	dh, ds:[W_priority]	; & priority value
	mov	di, ds:[W_layerID]	; & layer ID
	call	WinUnlockV

	cmp	si, di			; if no longer in same layer, DONE
	jne	done

					; otherwise, compare window priorities
	and	dh, mask WPD_WIN
	mov	dl, cl
	and	dl, mask WPD_WIN
	cmp	dh, dl
	jb	findLoop		; if window has lower priority value,
					; can't insert here, loop

	ja	done			; if window has higher, insert here,
					; done.

					; For the border line case, see if
					; placing in front or behind

	test	ch, mask WPF_PLACE_BEHIND shr 8
	jnz	findLoop		; if behind, loop & keep going.
done:
	.leave
	ret
FindWindowInsertPos	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove window from chain.

CALLED BY:	INTERNAL
		WinChangePriority

PASS:		ds	- seg of window (locked)
		es	- seg of Parent window (locked)
		ax	- handle of last window to remove (should be the
			  same as ds:[0] to remove just one window)
RETURN:
		bx	- handle of sibling to right of window(s) removed
		dx	- handle of sibling ot left of window(s) removed

		ax, cx, si, di, bp, ds, es - unchanged
		Window structure links updated to remove window.
		Parent, child, & sibling links within window removed are
		preserved.


DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinTRemove	proc	near	uses ax, cx, si, ds
	.enter
EC <	call	WinCheckRegPtr					>
			; es = seg of parent window
			; ds = seg of window
			; Get next & previous sibling's handles
					; if only one window being removed,
					; then fetch both next & prev sibling
					; pointers from it.
	cmp	ax, ds:[LMBH_handle]
	je	removingOnlyOne
					; otherwise, fetch next sibling of
	push	ds			; last window to be removed.
	mov_tr	bx, ax
	call	WinPLockDS
	mov	dx, ds:[W_nextSibling]
	call	WinUnlockV
	pop	ds
	jmp	short afterNextSibling

removingOnlyOne:
	mov	dx, ds:[W_nextSibling]

afterNextSibling:
	mov	bx, ds:[W_prevSibling]

	tst	bx		; are we removing at beginning?
	jz	WTRW_60		; branch if so
	call	WinPLockDS	; lock previous child
	mov	ds:[W_nextSibling], dx	; store new next sibling
					; & release previous sibling
	call	WinUnlockV
	jmp	WTRW_70
WTRW_60:
	mov	es:[W_firstChild], dx	; else store new first child to
					;	parent window
WTRW_70:
			; bx = handle of previous sibling
			; dx = handle of next sibling
	xchg	bx, dx
			; bx = handle of next sibling
			; dx = handle of previous sibling
	tst	bx			; are we removing at end?
	jz	WTRW_80			; branch if so
					; get handle to next child
	call	WinPLockDS		; lock it
	mov	ds:[W_prevSibling], dx	; store prev sibling pointer
					; & free next sibling
	call	WinUnlockV
	jmp	WTRW_90
WTRW_80:
	mov	es:[W_lastChild], dx	; else store as last child to
						;	parent window
WTRW_90:
	.leave
	ret
WinTRemove	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTValidateHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates window & all inferiors, siblings & their inferiors.

CALLED BY:

PASS:		ax		- validate flags
		wChangeBounds	- bounds of area changing

		window , parent window, locked & owned
		si		- handle of window
		ds		- segment of window
		  :[W_winReg]	- window's region definition
		  :[W_visReg]	- holds old visible region
		  :[W_invalReg]	- holds current invalid region
		di		- handle of parent's window
		es		- segment of parent's window
				OR NULL_WINDOW if at root
		  :[W_univReg]	- parent's universe region
		  :[W_visReg]	- holds old visible region
		  :[W_invalReg]	- holds current invalid region


RETURN:		All windows unlocked, unowned

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:

	For this window & all siblings to the right, WinTValidate;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		; lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTValidateHere	proc	near
EC <	call	CheckDeathVigil		; Fatal err if win closed	>
	call	SetValidateFlags
	push	si			; Save window we're starting with
EC <	call	WinCheckRegPtr					>

	push	es
	LoadVarSeg	es		; get seg to win variables
					; See if skipping passed window
	test	es:[wValidateFlags], WIN_SKIP_PASSED
	pop	es
	jz	WTVH_5			; branch if not skipping passed window
					; Are we passing up the last child of
					;	our parent?
	cmp	ds:[W_nextSibling], NULL_WINDOW
	jnz	WTVH_50			; if not, start w/next sibling
	call	WinCalcSibReg		; Ensure that p:W_childReg holds sum
					;	of our sibling's regions
	jmp	WTVH_50		; & move on to release window & do
					;	parent
WTVH_5:
	call	WinTValidate		; Validate window having change
	jmp	WTVH_20

WTVH_10:
	call	WinTValidate		; Validate this window
	jnc	WTVH_20			; skip if no change
	tst	di
	jz	WTVH_20			; if no parent, skip

	cmp	ds:[W_saveUnder], 0	; does window have save under?
	jne	WTVH_20			; if so, can't do abort test below
					; see if change area was completely
					;	inside this window
	call	CheckIfChangeCompletelyInWin
	jnc	WTVH_20			; if not, keep going
					; if so, then we don't need to update
					;	anything further from here.
	mov	bx, si			; get handle of current win
	call	WinUnlockAndMaybeV	; release window (Don't V if in change)
	jmp	WTVH_70

WTVH_20:
					; Is this the last child of our parent?
	cmp	ds:[W_nextSibling], NULL_WINDOW
	jnz	WTVH_40			; skip if not
	push	es
	LoadVarSeg	es		; get seg to win variables
					; See if change affects parent
	test	es:[wValidateFlags], WIN_NO_PARENT_AFFECT
	pop	es
	jnz	WTVH_40			; if parent not affected, don't need
					; Sum of Siblings
	call	WinCalcSibReg		; Ensure that p:W_childReg holds sum
					;	of our sibling's regions
WTVH_40:
			; ADD W_winReg into p:W_childReg IF we have a
			;	parent, & IF we're summing siblings
	call	AddWinRegToParentChildReg
WTVH_50:
	mov	bx, si			; get handle of old current win
	push	ds:[W_nextSibling]	; look to next sibling
					; release old window
	call	WinUnlockAndMaybeV	; release window (Don't V if in change)
	pop	si
					; Get ready to do new window
	mov	bx, si
	tst	bx			; is there another sibling?
	jz	WTVH_60			; if not, done
					; else lock it & do it
	call	WinPLockAndMaybeMark
	mov	ds, ax			; get segment handle in ds
	jmp	WTVH_10		; & loop to do this one
WTVH_60:
	push	es
	LoadVarSeg	es		; get seg to win variables
					; See if change affects parent
	test	es:[wValidateFlags], WIN_NO_PARENT_AFFECT
	pop	es
	jz	WTVH_80			; if so, do parent
					; if we don't, fall through
WTVH_70:
	call	WinTReleaseSuperior	; release the superior window
	jmp	WTVH_90
WTVH_80:
	call	WinTValidateSuperior	; validate the superior window
WTVH_90:
	pop	si			; Get window we started with
	call	WinTReleaseIfChange	; V window tree if change window
	ret
WinTValidateHere	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTValidateSuperior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates (re-calculates) W_visReg for superior window.

CALLED BY:	INTERNAL

PASS:		parent window locked
		di		- handle of parent window
				OR NULL_WINDOW if at root
		es		- segment of parent's window
		  :[W_univReg]	- universe region for parent window
		  :[W_visReg]	- holds old visible region
		  :[W_invalReg]	- holds current invalid region


RETURN:		parent window unlocked

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:
	WinPerformVis;
	Unlock window;


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTValidateSuperior	proc	near
	tst	di		; see if no parent to validate
	je	WTVS_90		; if not, done

	push	si		; Save orig window handle & seg
	push	ds
	segmov	ds, es
	call	WinPerformVis	; Calculate visible region , depending on flags
	segmov	es, ds
	pop	ds
	pop	si
				; Finally, release old parent
	call	WinTReleaseSuperior
WTVS_90:
	ret
WinTValidateSuperior	endp




WinTReleaseSuperior	proc	near
	tst	di		; see if no parent to validate
	jz	WTRS_90		; if not, done

	push	si
	push	di
	mov	di, es:[W_childReg]
	call	FarWinSMALLReg	; Don't need W_childReg anymore
				; Clear flags once "siblings" used
				;	as "children", no longer needed.
	and	es:[W_regFlags], not mask WRF_SIBLING_VALID
	pop	di
	pop	si
				; Finally, release old parent
	mov	bx, di		; Get handle of ORIG PARENT
	call	WinUnlockV
WTRS_90:
	ret
WinTReleaseSuperior	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTValidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates window & all inferiors.

CALLED BY:

PASS:		si		- HandleMem of top level window passed to
				  this function.  Is preserved down through
				  layers
		ds		- segment of window (locked)
		  :[W_winReg]	- window's region definition
		  :[W_visReg]	- old visible region
		  :[W_invalReg]	- current invalid region
		es		- segment of parent's window (locked)
				OR NULL_WINDOW if at root
		  :[W_univReg]	- parent window's universe region


RETURN:		si, di unchanged
		ds		- NEW segment of window (locked)
		  :[W_visReg]	- new visible region for window
		  :[W_invalReg]	- updated invalid region

		es		- NEW segment of parent's window (locked)
		  :[W_childReg]	- new wSibReg, has this window's W_winReg ORed in
		carry		- set if anything changed

DESTROYED:

PSEUDO CODE/STRATEGY:
	If parent isn't using W_childReg to hold wSibReg, call WinCalcSibReg;
	WinCalcUnivReg;
	For each child of window [
	    Point at window; Lock window;
	    If wChangeBounds intersects W_winReg of child then [
		 call WinTValidate;
	    ] else [
		es:[W_maskReg] += W_winReg;
	    ]
	    unlock window;
	]
	WinPerformVis;
	es:[W_maskReg] += W_winReg;


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTValidate	proc	near
EC <	call	CheckDeathVigil		; Fatal err if win closed	>
EC <	call	WinCheckRegPtr					>

				; SEE if this window affected by change
	call	CheckIfWinOverlapsChangeBounds
	LONG jnc	Done		; Branch if no overlap - don't need to
				; do Univ, Children, or Vis calculations.
				; (Fabricates overlap (carry set) if on branch
				; we started on & requesting delayed V)

				; See if recovering w/save under
	push	es
	LoadVarSeg	es	; get seg to win variables
	mov	al, es:[wChangeSaveUnder]
	test	es:[wValidateFlags], WIN_CLOSE_SAVE_UNDER
	pop	es
	jz	DoingUnivCalc	; if not, just do Univ calc

	; Handle validating of windows which might have been covered by the
	; window with save-under being closed here:

				; If Unaffected by the save under area
				; being closed, then we don't need
				; to do anything.
				; (Mask = 0, flags = 0)
	test	ds:[W_savedUnderMask], al
	jnz	MaskIsNonZero
	test	ds:[W_savedUnderFlags], al
	jz	AfterUnivCalc	; So, just branch to finish up if (0,0)
				; (Mask = 0, Flags =1)
				; This is the "draw collision" state.  We'll
				; have to revalidate the window because the
				; save under window is being closed
	jmp	DoingUnivCalc

MaskIsNonZero:
	test	ds:[W_savedUnderFlags], al
				; If (Mask = 1, Flags =1), we got lucky!
				; We didn't recalculate the window when
				; the save under window came up, hoping that
				; the save under window would go away before
				; anything happened to nuke the save under,
				; or any drawing happened to this window,
				; & we were right -- no calculations are
				; needed, so just finish up.
	jnz	AfterUnivCalc
				; If (Mask = 1, Flags = 0), illegal state
EC <	ERROR	ILLEGAL_WINDOW						>

DoingUnivCalc:
				; Calculate new Universe region for
				;	this window.
	call	WinCalcSibReg	; Ensure that p:W_childReg holds sum
				;	of our sibling's regions, needed in
				;	WinCalcUnivReg
	call	WinCalcUnivReg
AfterUnivCalc:

; MORE TO DO
; If W_univReg is unchanged at this point, then we don't need to do children.

	push	es		; save parent seg

; { Do same test that WinPerformVis will do.  If we're not going to calc
;   a new VisReg, then we don't need to be adding up wSibReg.
;   (See WinPerformVis to see why we might not be calculating a new VisReg)
	LoadVarSeg	es	; get seg to win variables
	mov	al, es:[wChangeSaveUnder]
	test	es:[wValidateFlags], WIN_CLOSE_SAVE_UNDER
	segmov	es, ds
	jz	DoingVisCalc	; if not doing close, then VisCalc will be
				; done, so need SibReg calculated

				; We will be doing a VisCalc only 
				; if drawing collided with the save under
				; in the window (Mask = 0, Flags =1)
	test	ds:[W_savedUnderMask], al
	jnz	StartWithFirstChild
	test	ds:[W_savedUnderFlags], al
	jz	StartWithFirstChild ; If (Mask = 0, Flags =1), doing vis calc
				; Otherwise, take shortcut:

DoingVisCalc:
; }
				; usher in new parent (our beloved
				;	window -- congratulations!)
	call	ClearSibReg	; Clear SibReg, show summing children,
				;	one child at a time as we do
				;	WinValidateWin on each.
StartWithFirstChild:
				; Fetch handle of first child
	mov	bx, es:[W_firstChild]

ChildLoop:
	tst	bx		; no more children?
	jz	WTVW_70		; if done w/children, exit
				; if so, lock it!
	call	WinPLockAndMaybeMark
	mov	ds, ax		; set up new window
	push	bx		; save window handle
	call	WinTValidate	; YES, IT'S RECURSIVE!
			; ADD W_winReg into p:W_childReg IF we have a
			;	parent.
	call	AddWinRegToParentChildReg
				; Get handle of the next sibling
	mov	cx, ds:[W_nextSibling]

	pop	bx		; Free up the window
	call	WinUnlockAndMaybeV	; release window (Don't V if in change)
	mov	bx, cx		; Put handle of next sibling into bx
	jmp	ChildLoop	; loop to do them all

WTVW_70:
	mov	ax, es		; make parent our child again
	mov	ds, ax
	pop	es

	call	WinPerformVis	; Calculate visible region, depending on flags

	stc			; return carry to show updated
Done:
	ret
WinTValidate	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinPerformVis

DESCRIPTION:	Calculates visible region, depending on flags, to deal
		correctly with save under areas.  Invalidates exposed
		areas in new visible region, sending MSG_META_EXPOSED events.

CALLED BY:	INTERNAL

PASS:
	ds	- segment of Plocked'ed window

RETURN:
	ds	- new segment of window

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	3/93		New handling of save-under regions
------------------------------------------------------------------------------@

WinPerformVis	proc	near
EC <	call	CheckDeathVigil		; Fatal err if win closed	>
	push	es
	LoadVarSeg	es	; get seg to win variables
	mov	bx, ds:[LMBH_handle]; get window we're about to change
				; let ptr handling code know about it
	call	WinChangePtrNotification
	mov	al, es:[wChangeSaveUnder]
	test	es:[wValidateFlags], WIN_CLOSE_SAVE_UNDER
	pop	es
	jz	calcVisReg	; if not, just do Vis calc

	; Handle validating of windows which might have been covered by the
	; window with save-under being closed here:

				; If Unaffected by the save under area
				; being closed, then we don't need
				; to do anything.
				; (Mask = 0, flags = 0)
	test	ds:[W_savedUnderMask], al
	jnz	maskIsNonZero
	test	ds:[W_savedUnderFlags], al
	jz	closeSaveUnderDone
				; So, just branch to finish up if (0,0)
				; (Mask = 0, Flags =1)
				; This is the "draw collision" state.  We'll
				; have to revalidate the window because the
				; save under window is being closed
	jmp	closeSaveUnderCalcVisReg

maskIsNonZero:
	test	ds:[W_savedUnderFlags], al
				; If (Mask = 1, Flags =1), we got lucky!
				; We didn't recalculate the window when
				; the save under window came up, hoping that
				; the save under window would go away before
				; anything happened to nuke the save under,
				; or any drawing happened to this window,
				; & we were right -- no calculations are
				; needed, so just finish up.
	jnz	closeSaveUnderDone
				; If (Mask = 1, Flags = 0), illegal state
EC <	ERROR	ILLEGAL_WINDOW						>

closeSaveUnderCalcVisReg:
	call	ClearSaveUnderCommon

calcVisReg:
	call	WinCalcVisReg	; calc visible region for this window

done:
				; Clear SIBLING_VALID flag
	and	ds:[W_regFlags], not mask WRF_SIBLING_VALID
	ret


closeSaveUnderDone:
	call	ClearSaveUnderCommon
	jmp	short done

WinPerformVis	endp
;
;---
;

ClearSaveUnderCommon	proc	near
	push	es
	LoadVarSeg	es	; get seg to win variables
	mov	al, es:[wChangeSaveUnder]
	not	al
	and	ds:[W_savedUnderMask], al	; clear both mask
	and	ds:[W_savedUnderFlags], al	; & flag
	pop	es
	ret
ClearSaveUnderCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTReleaseIfChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs a HandleV operation on a window, &
			all its children, if it matches change window

CALLED BY:

PASS:		si		- handle of window (unlocked)


RETURN:		si, di 		- unchanged
		es		- unchanged

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTReleaseIfChange	proc	near
	push	es
	LoadVarSeg	es		; get seg to win variables
	mov	bx, es:[wChangeWin]	; get window that was changed
	test	es:[wValidateFlags], WIN_V_PASSED_LAST
	pop	es
	jz	WTRIC_90		; if not delaying V, all done
	cmp	bx, si
	jne	WTRIC_90		; if not changed branch, all done
	call	MemLock			; lock top window
	mov	ds, ax

	push	es
	LoadVarSeg	es		; get seg to win variables
					; see if clearing save-under area
	test	es:[wValidateFlags], WIN_CLEAR_SAVE_UNDER
	pop	es
	jz	WTRIC_40		; if not clearing, skip
	mov	di, DR_VID_NUKE_UNDER	; get rid of save under area
	call	WinCallVidDriver
	mov	ds:[W_saveUnder], 0	; clear save under flags in window
	jmp	WTRIC_50		; skip V'ing of children, since we
					;	skipped them completely earlier
WTRIC_40:

	call	WinTRelease		; if it was, then V all windows in
					;	it now.
WTRIC_50:
	mov	bx, si
					; clear flag
	and	ds:[W_regFlags], not (mask WRF_DELAYED_V)
	call	WinUnlockV		; unlock & V top window
WTRIC_90:
	ret
WinTReleaseIfChange	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTRelease
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs a HandleV operation on all children of passed window

CALLED BY:

PASS:		ds		- segment of PLocked window


RETURN:		si, di 		- unchanged
		ds		- segment of window passed
		es		- unchanged

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTRelease	proc	near
				; see if delayed wash
	test	ds:[W_regFlags], mask WRF_DELAYED_WASH
	jz	WTR_10		; skip if not
	push	si
	push	di
	call	DoWashOut	; wash out window w/background color
	pop	di
	pop	si
				; clear flag, done
	and	ds:[W_regFlags], not mask WRF_DELAYED_WASH

WTR_10:
	push	es		; save parent seg
	segmov	es, ds		; usher in new parent (our beloved
				;	window -- congratulations!)
				; Fetch handle of first child
	mov	bx, es:[W_firstChild]
WTR_20:
	tst	bx		; no more children?
	jz	WTR_70		; if done w/children, exit
				; if so, lock it!

; We can do this, because we know we've already got the window P'd:
	call	MemLock
	mov	ds, ax

EC <	test	ds:[W_regFlags], mask WRF_DELAYED_V			>
EC <	ERROR_Z	WIN_BAD_ASSUMPTION					>
; Always being done in this branch...
;				; see if delayed V'ing being done
;	test	ds:[W_regFlags], mask WRF_DELAYED_V
;	jnz	WTR_30		; branch to handle normal case of delayed
;				; If not delayed, then no need to do children
;				; Get handle of the next sibling
;	mov	cx, ds:[W_nextSibling]
;	call	MemUnlock	; just unlock
;	jmp	WTR_50
;WTR_30:
	push	bx		; save window handle
	call	WinTRelease	; YES, IT'S RECURSIVE!
				; Get handle of the next sibling
	mov	cx, ds:[W_nextSibling]
					; clear flag, V accomplished
	and	ds:[W_regFlags], not (mask WRF_DELAYED_V)
	pop	bx		; Free up the window & V it
	call	WinUnlockV
;WTR_50:
	mov	bx, cx		; Put handle of next sibling into bx
	jmp	WTR_20	; loop to do them all
WTR_70:
	segmov	ds, es		; make parent our child again
	pop	es
	ret
WinTRelease	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCalcSibReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate sum of all non-save-under sibling windows to
		the left.

CALLED BY:	WinCalcWinHere

PASS:
		ds		- segment of window (locked)
		  :[W_prevSibling]	- pointer to sibling to the left
		es		- segment of parent's window (locked)
				OR NULL_WINDOW if at root



RETURN:		si, di, ds, lock status unchanged.
		ds		- NEW segment

		  :[W_childReg]	- Temporarily holding wSibReg.

DESTROYED:

PSEUDO CODE/STRATEGY:
		OR-SUM all W_winReg for all non-save-under siblings to the left
		Place into es:[W_childReg];

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		; lock OK
	Doug	3/18/93		New handling of save-under regions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinCalcSibReg	proc	near
EC <	call	WinCheckRegPtr					>

	mov	ax, es
	tst	ax			; see if at root
	jz	WCSR_90			; if so, exit, no siblings,
					;	no wSibReg.
					; See if already summing
	test	es:[W_regFlags], mask WRF_SIBLING_VALID
	jnz	WCSR_90			; if so, quit
				; Clear temp es: wSibReg
	call	ClearSibReg	; Set W_SIBLING VALID to show summing

	push	ds
	mov	bx, ds:[W_prevSibling]	; get handle to previous
					;	sibling
WCSR_10:
	tst	bx			; if no window here, done.
	jz	WCSR_80
	call	WinPLockDS
	push	bx
				; ADD W_winReg into p:wChildReg
	call	AddWinRegToParentChildReg
	pop	bx

	push	ds:[W_prevSibling]
	call	WinUnlockV		; release window
	pop	bx
	jmp	WCSR_10

WCSR_80:
	pop	ds
WCSR_90:
	ret
WinCalcSibReg	endp


ClearSibReg	proc	near
	push	si
	push	di
	mov	di, es:[W_childReg]	; Get pointer to clip reg
					; (wSibReg)
	call	FarWinNULLReg		; set region from pointer
					; Set flags to show summing of
					;	siblings
	or	es:[W_regFlags], mask WRF_SIBLING_VALID
					; Show not valid because of it
	and	es:[W_grFlags], not mask WGF_MASK_VALID
	mov	ax, EOREGREC
	mov	es:[W_clipRect.R_top], ax	; Invalidate W_clipRect.R_top & Hi
	mov	es:[W_clipRect.R_bottom], ax	;	Will cause re-calc of W_clipPtr

	pop	di
	pop	si
	ret
ClearSibReg	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddWinRegToParentChildReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add W_winReg into parent's W_childReg if this is a non-
		save-under window, & we're summing siblings

CALLED BY:	INTERNAL

PASS:		es	- segment of parent window, locked
			  (or NULL_WINDOW if no parent)
		ds	- segment of current window, locked

RETURN:		si, di, ds intact
		es	- new segment for window
		W_winReg of current window added into W_childReg of parent

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/27/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddWinRegToParentChildReg	proc	near
EC <	call	WinCheckRegPtr					>

	tst	ds:[W_saveUnder]	; if window has save under, skip --
	jnz	done			; don't add to W_child_reg.

	mov	ax, es
	tst	ax			; skip add-in if root.
	jz	done

					; See if summing yet
	test	es:[W_regFlags], mask WRF_SIBLING_VALID
	jz	done			; if NOT, don't add in

	; ADD W_winReg into W_childReg
	;
	push	si
	push	di
	mov	si, ds:[W_winReg]	; get ptr to w:W_winReg (reg1)
	mov	bx, es:[W_childReg]	; get ptr to p:W_childReg (reg2)
	mov	di, es:[W_temp1Reg]	; get ptr to p:W_temp1Reg (reg3)
	call	FarWinORReg
	mov	si, es:[W_temp1Reg]	; copy result to p:W_childReg
	mov	di, es:[W_childReg]
	mov	es:[W_childReg], si
	mov	es:[W_temp1Reg], di	; Do so by swapping handles
;	mov	di, es:[W_temp1Reg]	; Don't need temp1 anymore
	call	FarWinSMALLReg
	pop	di
	pop	si
done:
	ret

AddWinRegToParentChildReg	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTValidateOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates window & all inferiors, patches siblings & their
		inferiors, plus parent

CALLED BY:

PASS:		ax		- validate flags
		wChangeBounds	- bounds of area changing

		window, parent window, locked & owned
		si		- handle of window
		ds		- segment of window
		  :[W_winReg]	- window's region definition
		  :[W_visReg]	- holds old visible region
		  :[W_invalReg]	- holds current invalid region
		di		- handle of parent's window
		es		- segment of parent's window
				OR NULL_WINDOW if at root
		  :[W_univReg]	- parent's universe region
		  :[W_visReg]	- holds old visible region
		  :[W_invalReg]	- holds current invalid region


RETURN:		All windows unlocked & unowned

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:

	For this window & all siblings to the right, WinTValidate;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		; lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTValidateOpen	proc	far
EC <	call	CheckDeathVigil		; Fatal err if win closed	>
	call	SetValidateFlags
	push	si			; Save handle of window we're starting
					;	with
EC <	call	WinCheckRegPtr					>
;MORE TO DO
; can change summing of siblings for this function to only sum those whose
; bounds overlap change
;

	push	es
	LoadVarSeg	es		; get seg to win variables
					; See if skipping passed window,
					;	or clearing save under
	test	es:[wValidateFlags], WIN_SKIP_PASSED OR WIN_CLEAR_SAVE_UNDER
	pop	es
	jnz	WTVO_7			; branch if skipping passed window,
					;	or clearing save under
	call	WinTValidate		; Validate window having change
WTVO_7:

	push	es
	LoadVarSeg	es		; get seg to win variables
	test	es:[wValidateFlags], WIN_OPEN_SAVE_UNDER
	pop	es
	jnz	WTVO_9			; If Opening w/Save Under, then
					; we won't have to obscure anyone,
					; therefore we won't need wObscureReg.
	tst	di
	jz	WTVO_9			; if root, don't set up obscure reg,
	push	si			;	we're all done.
	push	di
	mov	si, ds:[W_winReg]
	mov	di, es:[W_childReg]
	call	FarWinNOTReg		; set parent's "child reg" to be
					;	NOT new window reg
	pop	di
	pop	si
WTVO_9:
	jmp	WTVO_20

WTVO_10:
					; Validate this window
	mov	dx, es			; pass segment of window w/obscure
					;	region
	call	WinTObscure
	mov	es, dx			; restore new segment of parent window
	jnc	WTVO_20			; skip if no change

	cmp	ds:[W_saveUnder], 0	; does window have save under?
	jne	WTVO_20			; if so, can't do abort test below
					; see if change area was completely
					;	inside this window
	call	CheckIfChangeCompletelyInWin
	jnc	WTVO_20			; if not, keep going
					; if so, then we don't need to update
					;	anything further from here.
	mov	bx, si			; get handle of current win
	call	WinUnlockAndMaybeV	; release window (Don't V if in change)
	jmp	WTVO_70

WTVO_20:
	mov	bx, si			; get handle of old current win
	push	ds:[W_nextSibling]	; look to next sibling
					; release old window
	call	WinUnlockAndMaybeV	; release window (Don't V if in change)
	pop	si
					; Get ready to do new window
	mov	bx, si
	tst	bx			; is there another sibling?
	jz	WTVO_60			; if not, done
					; else lock it & do it
	call	WinPLockAndMaybeMark
	mov	ds, ax			; get segment handle in ds
	jmp	WTVO_10		; & loop to do this one
WTVO_60:
	push	es
	LoadVarSeg	es		; get seg to win variables
					; See if change affects parent
	test	es:[wValidateFlags], WIN_NO_PARENT_AFFECT
	pop	es
	jz	WTVO_80			; if so, do parent.
					; if we don't, fall through
WTVO_70:
	call	WinTReleaseSuperior	; release the superior window
	jmp	WTVO_90
WTVO_80:
	call	WinTObscureSuperior	; validate the superior window
WTVO_90:
	pop	si			; Get window we started with
	call	WinTReleaseIfChange	; V window tree if change window
	ret
WinTValidateOpen	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTObscureSuperior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates (re-calculates) W_visReg for superior window.

CALLED BY:	INTERNAL

PASS:		parent window locked
		di		- handle of parent window
				OR NULL_WINDOW if at root
		es		- segment of parent's window
		  :[W_univReg]	- universe region for parent window
		  :[W_visReg]	- holds old visible region
		  :[W_invalReg]	- holds current invalid region


RETURN:		parent window unlocked

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:
	WinPerformObscure;
	Unlock window;


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTObscureSuperior	proc	near
	tst	di		; see if no parent to validate
	jz	done		; if not, done

	mov	dx, es		; make sure dx is segment of this
				;	parent window
	push	ds
	segmov	ds, es
	call	WinPerformObscure	; Do obscure operation
					; (But don't obscure Univ)
	segmov	es, ds
	pop	ds
				; Finally, release old parent
	call	WinTReleaseSuperior
done:
	ret
WinTObscureSuperior	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTObscure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validates window & all inferiors.

CALLED BY:

PASS:		si		- HandleMem of top level window passed to
				  this function.  Is preserved down through
				  layers

		ds		- segment of window (locked)
		  :[W_winReg]	- window's region definition
		  :[W_visReg]	- old visible region
		  :[W_invalReg]	- current invalid region
		es		- segment of parent's window (locked)
				OR NULL_WINDOW if at root
		  :[W_univReg]	- parent window's universe region

		dx		- segment of locked window containing
				obscure mask


RETURN:		si, di unchanged
		ds		- NEW segment of window (locked)
		  :[W_visReg]	- new visible region for window

		es		- NEW segment of parent's window (locked)
		dx		- NEW segment of window w/obscure mask

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/88		Initial version		lock OK
	Doug	3/18/93		New handling of save-under regions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTObscure	proc	near
EC <	call	CheckDeathVigil		; Fatal err if win closed	>
EC <	call	WinCheckRegPtr					>

				; SEE if this window affected by change
	push	dx
	call	CheckIfWinOverlapsChangeBounds
	pop	dx
	jc	WTO_10
				; if we are clearing a save under region,
	push	es		; we need to do calculations even if window
	LoadVarSeg	es	; does not overlap change bounds - Joon(6/9/94)
	test	es:[wValidateFlags], WIN_CLEAR_SAVE_UNDER
	pop	es
	jz	WTOB_80		; Branch if no overlap and not clearing save
				; under - don't need to
				; do Univ, Children, or Vis calculations.
				; (Fabricates overlap (carry set) if on branch
				; we started on & requesting delayed V)
WTO_10:

	call	WinPerformObscure	; Do obscure operation, depending
					;	on validation flags

	push	es		; save parent seg
	segmov	es, ds		; usher in new parent (our beloved
				;	window -- congratulations!)
				; Fetch handle of first child
	mov	bx, es:[W_firstChild]
WTOB_20:
	tst	bx		; no more children?
	jz	WTOB_70		; if done w/children, exit
				; if so, lock it!
	call	WinPLockAndMaybeMark
	mov	ds, ax		; set up new window
	push	bx		; save window handle
	call	WinTObscure	; YES, IT'S RECURSIVE!
				; Get handle of the next sibling
	mov	cx, ds:[W_nextSibling]

	pop	bx		; Free up the window
	call	WinUnlockAndMaybeV	; release window (Don't V if in change)
	mov	bx, cx		; Put handle of next sibling into bx
	jmp	WTOB_20	; loop to do them all

WTOB_70:
	segmov	ds, es		; make parent our child again
	pop	es
	stc			; return carry to show updated

WTOB_80:
	ret
WinTObscure	endp



WinPerformObscure	proc	near
				; dx = segment of window w/obscure region in
				;	it
				; ds = segment of window to obscure
	push	es
	LoadVarSeg	es		; get seg to win variables

	mov	bx, ds:[LMBH_handle]	; get window we're about to change
				; let ptr handling code know about it
	call	WinChangePtrNotification

	test	es:[wValidateFlags], WIN_OPEN_SAVE_UNDER
	jz	notOpeningSaveUnder	; skip if not doing open save under

	; HERE if this window is to right of, or parent of, window w/
	; save under, & therefore might be underneath the save under area,
	; which is being opened.
	; Set save under state for this window to "Window regions unaltered
	; by save-under window, in hopes that it will soon go away" state.
	; (Mask = 1, Flag = 1)
	;
	mov	al, es:[wChangeSaveUnder]	; get bit to set
	or	ds:[W_savedUnderMask], al	; show in save under area
	or	ds:[W_savedUnderFlags], al	; show recoverable
	jmp	popESDone

notOpeningSaveUnder:
	test	es:[wValidateFlags], WIN_CLEAR_SAVE_UNDER
	jz	obscure		; if not clearing save under, just do obscure

	; HERE if this window is to right of, or parent of, window w/
	; save under, & therefore might be underneath a save under area,
	; which is being cleared of its save under.
	;
	mov	al, es:[wChangeSaveUnder]	; get bit to clear
	test	al, ds:[W_savedUnderFlags]	; affected by save under?
	jz	popESDone			; nope -- get out of here

	mov	ah, al				; otherwise clear the bits
	not	ah
	and	ds:[W_savedUnderFlags], ah	; clear flag
	and	ds:[W_savedUnderMask], ah	; clear mask
						; & do full obscure
obscure:
	pop	es
				; Calculate new Universe & Visible region for
				;	this window.
	push	si
	push	di
	push	es
	segmov	es, ds		; set es to be window to obscure
	mov	ds, dx		; set ds to be window w/obscure region in
				;	W_childReg
	mov	si, ds:[W_childReg]
	mov	di, es:[W_temp1Reg]
	mov	ax, es
	cmp	ax, dx		; Is destination window same as dx window?
	jne	differentWin	; skip if not

;sameWin:
	call	FarWinCopyLocReg; use different copy routine if so
				; Calculate new W_visReg & W_univReg for window
				; Pass dx = ds if doing obscure for Parent.
				; Will cause W_univReg to be left alone.
				; (Children don't affect a parent's W_univReg)
	mov	dx, ds		; update dx
	call	WinCalcRawObscure
	mov	dx, ds		; update dx
	jmp	afterObscure

differentWin:
	push	dx
	call	FarWinCopyReg	; copy obscure region over to window to obscure
	segmov	ds, es		; move seg back to ds for window
				; Calculate new W_visReg & W_univReg for window
				; Pass dx = ds if doing obscure for Parent.
				; Will cause W_univReg to be left alone.
				; (Children don't affect a parent's W_univReg)
	call	WinCalcRawObscure
	pop	dx

afterObscure:
	pop	es
	pop	di
	pop	si
done:
	ret

popESDone:
	pop	es
	jmp	short done

WinPerformObscure	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCalcUnivReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates new W_univReg

CALLED BY:	INTERNAL

PASS:
		ds		- segment of window (locked)
		  :[W_winReg]	- window's region definition
		es		- segment of parent's window (locked)
				OR NULL_WINDOW if at root , in which case there
				is no W_parentReg or wSibReg.
		  :[W_winReg]	- parent window's region definition
		  :[W_univReg]	- holds current universe region of parent
		  :[W_maskReg]	- holding wSibReg.

RETURN:		w:W_univReg	- set to new universe region for window
		ds		- NEW segment for window

DESTROYED:	ax, bx, cx, dx
		w:W_maskReg

PSEUDO CODE/STRATEGY:
	We can calculate W_univReg by:

	w:W_univReg = w:W_winReg AND p:W_univReg AND NOT (p:W_childReg)


	UNLESS there is no parent window, in which case:

	w:W_univReg = w:W_winReg


	WE can break this down into the following:

	if parent exists [
		w:W_temp1Reg = NOT p:W_childReg;
		w:W_temp2Reg  = w:W_winReg AND p:W_univReg;
		w:W_univReg = w:W_temp1Reg AND w:W_temp2Reg;

	] else [
		w:W_univReg = w:W_winReg;
	]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/9/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinCalcUnivReg	proc	near
	push	si
	push	di
	push	es
	mov	ax, ds		; SWAP seg regs, so
	mov	bx, es
	mov	es, ax		; ES is Window seg
	mov	ds, bx		; DS is Parent seg

	tst	bx		; do we have a parent?
	jne	PURC_Parent	; branch if so

			; If no parent, universe IS our window
			; w:W_univReg = w:W_winReg;
	mov	di, es:[W_univReg]
	mov	si, es:[W_winReg]
	call	FarWinCopyLocReg	; copy region over

	jmp	PURC_CoreDone	; finish up last op


PURC_Parent:
				; See if window not obscured by parent
	mov	ax, es:[W_winRect.R_left]
	mov	bx, es:[W_winRect.R_top]
	mov	cx, es:[W_winRect.R_right]
	mov	dx, es:[W_winRect.R_bottom]
	mov	si, ds:[W_univReg]
	mov	si, ds:[si]	; change to pointer
	clc			; Pass carry clear, to indicate passing a
				; full region
	call	GrTestRectInReg	; Use Adam's routine to see if in region
				; It's supposed to be fast, & the common
				; case is that we will not be obscured by
				; our parent.  If this is true, then we won't
				; have to AND the regions (thereby doing an
				; LMem resize twice, plus the AND calculation),
				; & instead just have to copy the WinReg
				; (most commonly a rectangle, or 14 bytes)
	cmp	al, TRRT_IN	; if IN, then not obscured
	jne	PURC_10		; if obscured, do full calc

				; If IN, then result is W_winReg.
	mov	di, es:[W_temp2Reg]
	mov	si, es:[W_winReg]
	call	FarWinCopyLocReg
	jmp	PURC_15

PURC_10:
			; w:W_temp2Reg  = w:W_winReg AND p:W_univReg;
	mov	di, es:[W_temp2Reg]
	mov	bx, es:[W_winReg]
	mov	si, ds:[W_univReg]
	call	FarWinANDReg

PURC_15:
			; w:W_temp1Reg = NOT p:W_childReg;
	mov	si, ds:[W_childReg]
			; SPEED improvement:  see if NULL sibling region
	mov	di, ds:[si]
	cmp	{word} ds:[di], EOREGREC	; NULL?
	jne	PURC_20			; if not, do full calculation
				; else W_temp2Reg is result
				; Swap es:W_univReg into es:W_temp2Reg
	call	SwapESTemp2Univ
	jmp	PURC_CoreDone	; finish up last op

PURC_20:
			; w:W_temp1Reg = NOT ds:si region
	mov	di, es:[W_temp1Reg]
	call	FarWinNOTReg

			; w:W_univReg = w:W_temp1Reg AND w:W_temp2Reg;
	mov	di, es:[W_univReg]
	mov	bx, es:[W_temp1Reg]
	mov	si, es:[W_temp2Reg]
	call	FarWinANDLocReg

PURC_CoreDone:

;PURC_Complete:
	
	; Finally, just resize temp chunks to be smaller, as we don't
	; need them anymore.
	;
	call	SetTempRegsSMALL	; Don't need W_temp1Reg, temp2 anymore

				; show mask not valid
	and	es:[W_grFlags], not mask WGF_MASK_VALID

	mov	ax, es
	mov	ds, ax		; restore to new seg
	pop	es
	pop	di
	pop	si
	ret

WinCalcUnivReg	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CorrectForSaveUnder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	Since we have been forced to validate the visible region,
	we should check to see if we've screwed up the work of 
	WinMaskOutSaveUnder, which is called whenever a draw collision
	occurs with a window under a save under area.  If this
	is true for THIS window, we need to further reduce the visReg.


CALLED BY:	INTERNAL

PASS:
		es		- segment of window (locked)
		es:W_visReg	- set to new visible region for window

RETURN:		es:W_visReg	- set to new visible region for window, after
				  save under fix-ups

DESTROYED:	ax, bx, cx, dx, si, di, ds
		es:W_temp1Reg	- (the region, not the chunk)
		es:W_temp2Reg	- (the region, not the chunk)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	Doug	3/18/93		New handling of save-under regions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CorrectForSaveUnder	proc	near
	mov	al, es:[W_savedUnderMask]	; look for mask = 0,
	not	al
	and	al, es:[W_savedUnderFlags]	; Flags = 1

; This is taken care of now in WinCalcVisReg before this routine is called.
;
;	push	ds
;	LoadVarSeg	ds	; get seg to win variables
;				; BUT, if closing a save under, DON'T
;				; clip out its save under area by mistake
;	test	ds:[wValidateFlags], WIN_CLOSE_SAVE_UNDER
;	jz	AfterClosingCheck
;	mov	ah, ds:[wChangeSaveUnder]
;	not	ah
;	and	al, ah
;AfterClosingCheck:
;	pop	ds
				; al = save under areas we need to 
				; cut out of the visReg.
	tst	al
	jz	Done		; If none, ALL DONE

;ObscureFromHitSaveUnders:
	mov	ah, al		; Put all flags in ah
	mov	al, 1		; start w/this one
SaveUnderLoop:
	test	ah, al
	jz	NextSaveUnder
	push	ax		; Save save-under loop flags

				; al = single bit mask of a save under
				; whose wUnivReg we need to get at.
				; es = our window P'locked.
				; ds unknown, can trash.
	mov	di,DR_VID_INFO_UNDER
	push	es
	call	es:[W_driverStrategy]		; make call to video driver
	pop	es
				; ax, bx, cx, dx is Rectangle of save under
				; di is handle of save under window
	tst	di
	jz	DoneWithSUWindow

if USE_SAVE_UNDER_REG
	push	ds
	mov	bx, di
	call	WinSetESTemp1ToNotSaveUnderWinBX
	pop	ds
else
	call	WinSetESTemp1ToNotRect	; get NOT reg into W_temp1Reg
endif
	call	SwapESTemp2Vis		; Swap es:W_visReg into es:W_temp2Reg

				; w:W_visReg = w:W_temp1Reg AND w:W_temp2Reg;
	mov	di, es:[W_visReg]
	mov	bx, es:[W_temp1Reg]
	mov	si, es:[W_temp2Reg]
	call	FarWinANDLocReg

DoneWithSUWindow:

	pop	ax
NextSaveUnder:
	shl	al, 1
	jnc	SaveUnderLoop
Done:
	ret

CorrectForSaveUnder	endp

SwapESTemp2Vis proc    far
		; Swap W_visReg into W_temp2Reg
        mov     ax, es:[W_temp2Reg]
        xchg    es:[W_visReg], ax
        mov     es:[W_temp2Reg], ax
        ret
SwapESTemp2Vis endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinForEach

DESCRIPTION:	Call a callback function to operate on one or more windows
		in the window system.  The window tree semaphore is held
		down while this occurs, so that the callback routine may
		traverse as many windows as it wishes.

CALLED BY:	EXTERNAL

PASS:
	di	- window handle to start at
	ax, cx, dx, bp	- initial data to pass in callback
	bx:si	- far ptr to callback routine
			- or -
		  vfptr to callback routine in XIP'ed geode

RETURN:
	ax, cx, dx, bp	- as returned from last call

DESTROYED:
	Nothing

NOTE:	DS is *NOT* fixed up by this routine. You will have to do it yourself
	if you think it is necessary.

REGISTER/STACK USAGE:
        CALLBACK ROUTINE:
                Desc:   Process window
                Pass:   di	- window handle to process
                        ax, cx, dx, bp - data
                Return: carry - set to end processing, else:
			di	- next window to process
                       	ax, cx, dx, bp - data to send on.
                Destroy: bx, si


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
------------------------------------------------------------------------------@


WinForEach	proc	far	uses bx, si, di, ds

callBack	local	fptr.far	; virtual far ptr to callback routine
	.enter
	mov	callBack.segment, bx	; store ptr to callback in local var
	mov	callBack.offset, si

	; Before we do callback, make sure we are calling legal routine.
	; This means it must be on the heap, or a vfptr to an XIP resource.
	; We can not take a direct fptr to something in the XIP area because
	; we will soon be making a call to another code resource which
	; could make things puke.
	;		-- todd 03/10/94
if	FULL_EXECUTE_IN_PLACE
EC <	call	ECAssertValidFarPointerXIP			>
endif

	; Lock down the tree semaphore, as we'll be traversing linkage.
	;
	push	es
	call	FarPWinTree
	pop	es

callBackLoop:
	tst	di
	jz	done

	call	SysCallCallbackBPFar
	jnc	callBackLoop		; loop until all called, or until
					; carry returned set to abort
done:
	; Free up tree semaphore, so things can move around again,
	; windows be freed, etc.
	;
	push	es
	call	FarVWinTree 		; Free tree semaphore
	pop	es

	.leave
	ret	@ArgSize

WinForEach	endp


WinMovable ends

WinMisc segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinLocatePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	GLOBAL

PASS:		di	- handle of graphics state OR window to start search at
		cx	- x screen position
		dx	- y screen position

RETURN:		di	- handle of window visible at point
			( or NULL_WINDOW if outside original window)
		<bx><si>- Output descriptor associated w/window
		cx	- x absolute position of window
		dx	- y absolute postion of window

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		Start at given window;
		If point in W_winReg of window [
			store window as current solution, move down to 1st child
			if no child, done, else goto "If point in W_winReg"
		] else move to next sibling;
		if no sibling, done, else goto "If point in W_winReg"

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinLocatePoint	proc	far
	push	es
	call	FarPWinTree 	; Have to have tree first, to insure
				; that W_winReg & linkage doesn't change on us

	call	WinLocateCommon	; Call common routine to locate point

	call	FarVWinTree	; Free tree semaphore
	pop	es
	ret
WinLocatePoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinLocateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine for determining which is the top-most
		window under a point.  This routine will even work if there
		are save-unders going on, which results in the odd scenerio
		of overlapping universes.

CALLED BY:	GLOBAL

PASS:		di	- handle of graphics state OR window to start search at
		cx	- x screen position
		dx	- y screen position
		winTreeSem	- P'd

RETURN:		di	- handle of window visible at point
			( or NULL_WINDOW if outside original window)
		<bx><si>- Output descriptor associated w/window
		cx	- x absolute position of window
		dx	- y absolute postion of window
		winTreeSem	- unchanged

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		Start at given window;
		If point in W_winReg of window [
			store window as current solution, move down to 1st child
			if no child, done, else goto "If point in W_winReg"
		] else move to next sibling;
		if no sibling, done, else goto "If point in W_winReg"

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Split out from WinLocatePoint

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinLocateCommon	proc	far
	push	bp
	push	ds
	mov	bp, sp			; set up frame
	sub	sp, 8			; local storage

	call	FarWinHandleFromDI
	mov	bx, di
	clr	si			; NULL_WINDOW - no solution yet
	mov	[bp-2], si	; set OD to NULL_WINDOW as well
WLWAVP_10:
	tst	bx			; if no window here, done.
	je	WLWAVP_90

	call	MemPLock	; ds <- seg addr of Window
	mov	ds, ax		; Try trivial reject
	cmp	cx, ds:[W_winRect.R_left]
	jl	WLWAVP_20
	cmp	cx, ds:[W_winRect.R_right]
	jg	WLWAVP_20
	cmp	dx, ds:[W_winRect.R_top]
	jl	WLWAVP_20
	cmp	dx, ds:[W_winRect.R_bottom]
	jg	WLWAVP_20
	push	bx
	push	si
	push	di
	mov	si, ds:[W_winReg]	; get chunk handle to window region
	mov	si, ds:[si]	; get pointer to region in si
	call	GrTestPointInReg
	pop	di
	pop	si
	pop	bx
				; returns carry set if in region
	jnc	WLWAVP_20	; if not in region, skip

	mov	si, bx		; In region, so set as current solution
				; SAVE OD for window
	mov	ax, word ptr ds:[W_exposureObj] + 2	; get high word of OD
	mov	[bp-2], ax
	mov	ax, word ptr ds:[W_exposureObj] + 0	; get low word of OD
	mov	[bp-4], ax
	mov	ax, ds:[W_winRect.R_left]
	mov	[bp-6], ax	; save position of upper left corner
	mov	ax, ds:[W_winRect.R_top]
	mov	[bp-8], ax
				; move down to first child
	mov	ax, ds:[W_firstChild]
	push	ax
				; unlock window
	call	MemUnlockV
	pop	bx		; put new handle in bx
	jmp	WLWAVP_10
WLWAVP_20:
	mov	ax, ds:[W_nextSibling]	; move to next sibling
	push	ax
	call	MemUnlockV
	pop	bx		; put new handle in bx
	jmp	WLWAVP_10
WLWAVP_90:
	mov	di, si			; put window handle in di
	mov	bx, [bp-2]		; put high word of OD in bx
	mov	si, [bp-4]		; & low word of OD in si
	mov	cx, [bp-6]		; put x pos in cx
	mov	dx, [bp-8]		; put y pos in dx

	mov	sp, bp			; restore stack pointer
	pop	ds
	pop	bp			; restore frame pointer
	ret

WinLocateCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTestIfWinInBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine for determining which is the top-most
		window under a point.  This routine will even work if there
		are save-unders going on, which results in the odd scenerio
		of overlapping universes.

CALLED BY:	GLOBAL

PASS:		ds	- Plock'ed segment of Window at head of Window Branch
		bx	- A Window
		winTreeSem	- P'd

RETURN:		carry	- set if Window passed is in Window Branch passed
		winTreeSem	- unchanged

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTestIfWinInBranch	proc	far	uses	ax, dx, es
	.enter
TestLoop:
	cmp	bx, ds:[LMBH_handle]	; if same window, yes, in branch
	je	WinInBranch

				; Otherwise, walk up passed window, all
				; the way to the root, looking to see if
				; in branch.
	call	MemPLock
	mov	es, ax		; es <- seg addr of Window
	mov	dx, es:[W_parent]	; fetch handle of parent window
	call	MemUnlockV	; release the window
	mov	bx, dx
	tst	bx		; If not root window, 
	jne	TestLoop	; keep traversing tree
	clc			; If root window found, window wasn't in
	jmp	Done


WinInBranch:
	stc
Done:
	.leave
	ret

WinTestIfWinInBranch	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinClearSaveUndersLow

DESCRIPTION:	Clears save under from windows of passed save under areas,
		punching the region out of all windows underlying, so that
		they are valid with save-under gone.

CALLED BY:	INTERNAL

PASS:
	winTreeSem	- P'd
	al		- bit mask of save under areas to remove
	NO windows P'd  (Will lock up if this routine tries to P one of them)
	bx		- handle of a window on display device
			  (for access to video driver strategy routine)

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

WinClearSaveUndersLow	proc	far
	tst	al
	jz	Done

	mov	ah, al		; Put all flags in ah
	mov	al, 1		; start w/this one
SaveUnderLoop:
	test	ah, al
	jz	NextSaveUnder
	push	ax		; Save save-under loop flags
	push	bx		; save handle of reference window

				; al = single bit mask of a save under
				; whose wUnivReg we need to get at.
				; ds = our window P'locked.
				; es can trash.
	push	ax
	call	MemPLock
	mov	ds, ax
	pop	ax		; restore save under bit mask to al

	mov	di,DR_VID_INFO_UNDER
	push	bx
	call	WinCallVidDriver
	pop	bx
	call	MemUnlockV
				; di is handle of save under window
	tst	di
	jz	DoneWithSUWindow

					; Save change bounds
	call	GetChangeBounds
	push	ax, bx, cx, dx

	mov	bx, di
	call	WinLockWinAndParent	; Get ready to clear save under
					; CLEAR the save under & punch
					; 	a whole through all underlying
					;	windows
	call	LoadWinSetChangeBounds	; Setup change area as that of
					;	save under window.

	mov	ax, WIN_V_PASSED_LAST OR WIN_CLEAR_SAVE_UNDER
	call	WinTValidateOpen	; do it.

					; Restore old change bounds
	pop	ax, bx, cx, dx
	call	SetChangeBounds

DoneWithSUWindow:
	pop	bx
	pop	ax

NextSaveUnder:
	shl	al, 1
	jnc	SaveUnderLoop
Done:
	ret
WinClearSaveUndersLow	endp


WinMisc ends


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckGStateHandle

DESCRIPTION:	Check a gstate handle for validity

CALLED BY:	GLOBAL

PASS:
	di - gstate handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Jim	2/90		Changed to pass handle in di

------------------------------------------------------------------------------@


NEC <ECCheckGStateHandle	proc	far				>
NEC <	ret								>
NEC <ECCheckGStateHandle	endp					>

if	ERROR_CHECK
ECCheckGStateHandle	proc	far
	xchg	bx, di
	call	ECCheckMemHandleFar
	pushf
	push	ax, ds
	LoadVarSeg	ds
	test	ds:[bx].HM_flags,mask HF_LMEM
	ERROR_Z	ILLEGAL_GSTATE

	INT_OFF
	mov	ax,ds:[bx].HM_addr
	tst	ax
	jz	ECCGH_noCheck
	mov	ds,ax

	cmp	ds:[LMBH_lmemType],LMEM_TYPE_GSTATE
	ERROR_NZ	ILLEGAL_GSTATE

ECCGH_noCheck:
	INT_ON

	pop	ax, ds
	popf
	xchg	bx, di
	ret

ECCheckGStateHandle	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckWindowHandle

DESCRIPTION:	Check a window handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - window handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckWindowHandle	proc	far				>
NEC <	ret								>
NEC <ECCheckWindowHandle	endp					>

if	ERROR_CHECK
ECCheckWindowHandle	proc	far
	call	ECCheckMemHandleFar
	pushf
	push	ax, ds
	LoadVarSeg	ds
	test	ds:[bx].HM_flags,mask HF_LMEM
	ERROR_Z	ILLEGAL_WINDOW

	INT_OFF
	mov	ax,ds:[bx].HM_addr
	tst	ax
	jz	ECCWH_noCheck
	mov	ds,ax

	cmp	ds:[LMBH_lmemType],LMEM_TYPE_WINDOW
	ERROR_NZ	ILLEGAL_WINDOW

ECCWH_noCheck:
	INT_ON

	pop	ax, ds
	popf
	ret

ECCheckWindowHandle	endp

WinCheckRegPtr	proc	far
	push	ax
	mov	ax, ds
	tst	ax		; check for 0 and -1
	jz	error
	cmp	ax, -1
	je	error
	pop	ax
	ret
error:
	ERROR	GRAPHICS_BAD_REG_PTR
WinCheckRegPtr	endp
endif
