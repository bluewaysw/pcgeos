COMMENT }***********************************************************************

	Copyright (c) GeoWorks 1988 - All rights reserved

	PROJECT: 	PCGEOS
	MODULE: 	Windowing System
	FILE:		winIndividual.asm

	AUTHOR:		Jim DeFrisco, Doug Fults

	ROUTINES:
		Name		description
		----		-----------
	GLB	WinAckUpdate	Acknowledge update, without
					StartUpdate/EndUpdate
	GLB	GrBeginUpdate	Lock window to draw to
	GLB	GrEndUpdate	Unlock window; done drawing to it
	GLB	WinInvalReg	Invalidate region on particular window
	GLB	WinInvalTree	Invalidate region on whole window system
	GLB	WinMaskOutSaveUnder
	GLB	WinValClipLine	Validate clipping line info (called by driver)
	GLB	WinGenLineMask	Generate line mask from current clip line
				(called by driver)

	INT	WinCalcVisReg	Calculate visible region of window
	INT	WinAddToInvalReg	Add wTemp1Reg into wInvalReg, generate
					exposed if needed
	INT	WinWashOut	Wash out window w/background color
	INT	WinCalcRawObscure	Recalc window regions by anding out
					a region
	INT	WinValWinStruct	Validate window clipping region
				(called by EnterGraphics)
	INT	WinGenLineMask	Generate lineMaskBuffer from thew current
				clipping state


	REVISION HISTORY:
		date		name	description
		----		----	-----------
		10/12/88	doug	New file created

	NOTE:	Code to handle individual window modification, validation

	$Id: winIndividual.asm,v 1.1 97/04/05 01:16:26 newdeal Exp $

********************************************************************************
	DESCRIPTION:
*******************************************************************************}

WinMisc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinAckUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge an update.  This is the equivalent of calling
		GrBeginUpdate, then GrEndUpdate, but does not require a
		GState to do so.  To be used in respose to a MSG_META_EXPOSED
		where the application doesn't, for whatever reason, wish
		to do update drawing (An obscure case...).

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state or window

RETURN:		None

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinAckUpdate	proc	far
	call	PushAllFar

	call	FarWinLockFromDI	; Get window locked
	jc	exit
	push	di			; save handle of window

					; no more exposure pending
	and	ds:[W_regFlags], not mask WRF_EXPOSE_PENDING
					; show mask not valid
	andnf	ds:[W_grFlags], not (mask WGF_MASK_VALID)

	mov	di, ds:[W_invalReg]	; set W_invalReg to NULL
	segmov	es, ds			; set es to be seg of window
	call	FarWinNULLReg		; fixup DS
EC <	mov	ax, NULL_SEGMENT	; Indicate done with es	>
EC <	mov	es, ax							>

	call	WinSendUpdateComplete	; Let input/output handler object
					; know that drawing has been completed

	pop	bx			; retrieve window handle
	call	MemUnlockV		; Unlock window
exit:
	call	PopAllFar
	ret

WinAckUpdate	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSuspendUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to hold-off update drawing to this window.  Prevents
		the sending of new MSG_META_EXPOSED'd, causes any GrBeginUpdate
		coming in to do a fake, null-mask update, leave intact the
		invalid areas of the window for a later update (taken at
		WinUnSuspendUpdateDrawing)

		Should an update already be in progress, we just let it
		complete, & suspend thereafter.

CALLED BY:	GLOBAL

PASS:		di	- handle of graphics state/window to suspend update
			  drawing to 

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinSuspendUpdate	proc	far
	call	PushAllFar
	call	FarWinLockFromDI	; Get the window locked.
	jc	exit			; just exit for gstrings
	mov	bx, di			; put window handle in bx

					; Increment suspend count
	inc	ds:[W_suspendCount]
					; bx = window handle
	call	MemUnlockV		; unlock, release window
exit:
	call	PopAllFar
	ret

WinSuspendUpdate	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinUnSuspendUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to allow update drawing for this window.

CALLED BY:	GLOBAL

PASS:		di	- handle of graphics state/window to allow update
			  drawing to 

RETURN:		none

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinUnSuspendUpdate	proc	far
	call	PushAllFar

	call	FarWinLockFromDI	; Get the window locked.
	jc	exit			; just exit for gstrings
	push	di
					; decrement suspend count
	dec	ds:[W_suspendCount]
EC <	ERROR_S	WIN_SUSPEND_COUNT_UNDERFLOW				>
	jnz	afterResult		; if not zero yet, done.
					; Otherwise...
	call	WinSendExpEvent		; send exposure event, if needed
afterResult:

	pop	bx			; fetch window handle
	call	MemUnlockV		; unlock, release window
exit:
	call	PopAllFar
	ret

WinUnSuspendUpdate	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WinInvalTree

DESCRIPTION:	Invalidate an area in a window tree

CALLED BY:	GLOBAL

PASS:
	In SCREEN coordinates:
	ax, bx, cx, dx - parameters for region, bounds if a rectangular region
	bp:si - region (0 for rectangular)
	di - handle of graphics state, or window

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

    All Kernel versions through V1.05, V1.13:

        Trashes memory in the case that a null region is passed. The window
	structure itself will nearly always be screwed up, & the damage
	could extend to the next block.

        V1.05, V1.13 & before development work-around:  Since WinInval* of a
	null region has no effect, simply skip the call if region is null
        (first word = EOREGREC)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version
	Doug	'89, '90	Completed as part of window system

-------------------------------------------------------------------------------@

WinInvalTree	proc	far

if	FULL_EXECUTE_IN_PLACE
EC <	tst	bp						>
EC <	jz	xipOK						>
EC <	xchg	bx, bp						>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	xchg	bx, bp						>
xipOK::
endif
	
	push	di, ds, es

	call	FarPWinTree		; Need the tree semaphore, es <- idata

	call	FarWinHandleFromDI	; get window handle, in di

				; di is handle of root of tree to do general
				; invalidate on.
	call	WinInvalTreeHere	; inval tree, starting here

	call	FarVWinTree		; Release the tree semaphore (es<-idata)

	pop	di, ds, es
	ret

WinInvalTree	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinInvalTreeHere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate tree & all children

CALLED BY:	WinInvalTree

PASS:
	In SCREEN coordinates:
	ax, bx, cx, dx - parameters for region, bounds if a rectangular region
	bp:si - region (0 for rectangular)

	di - handle of window


RETURN:		di	- handle of sibling to our right

DESTROYED:	reg	- description

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

    All Kernel versions through V1.05, V1.13:

        Trashes memory in the case that a null region is passed. The window
	structure itself will nearly always be screwed up, & the damage
	could extend to the next block.

        V1.05, V1.13 & before development work-around:  Since WinInval* of a
	null region has no effect, simply skip the call if region is null
        (first word = EOREGREC)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/89		Initial version
	Doug	8/89		Fixing up munched version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinInvalTreeHere	proc	near
	push	ax
	push	bx
	mov	bx, di
	call	MemPLock
	mov	ds, ax		; ds <- seg addr of Window
	pop	bx
	pop	ax

	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	jnz	WITH_90			; if so, do nothing

	push	dx
	push	cx
	push	bx
	push	ax
	mov	dx,ss			;dx:cx = parameters
	mov	cx,sp

	push	si
	push	bp
	mov	di, si			; pass region in bp:di
	mov	si, ds:[W_temp1Reg]	; pass chunk handle

	call	SetupOtherRegLow	; Setup region W_temp1Reg
					; ds = window segment

	ornf	ds:[W_regFlags], mask WRF_INVAL_TREE

	call	WinAddToInvalReg	; Add W_temp1Reg into W_invalReg,
					;  generate MSG_WIN_EXOSED if necessary

	andnf	ds:[W_regFlags], not mask WRF_INVAL_TREE

	pop	bp
	pop	si

	pop	ax
	pop	bx
	pop	cx
	pop	dx
				; NOW do all children
	push	ds			; save block handle of parent window
	mov	di, ds:[W_firstChild]	; get window handle of first child
WITH_40:
	cmp	di, NULL_WINDOW
	je	WITH_80			; if - 1, end of chain, done
	call	WinInvalTreeHere	; YES! IT'S RECURSIVE!
	jmp	short WITH_40		; loop for all siblings
WITH_80:
	pop	ds

	mov	di, ds:[W_nextSibling]	; return handle of sibling to our
					;	right
WITH_90:
	push	bx
	mov	bx, ds:[W_header.LMBH_handle]
	call	MemUnlockV		;release window
	pop	bx
	ret
WinInvalTreeHere	endp




WinMisc ends

WinMovable segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSendUpdateComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_META_WIN_UPDATE_COMPLETE to the inputOD for
		the window.  In cases where inputOD & exposedOD are different,
		this allows the inputOD handler to know when the display
		has finished redrawing.
		This is used in the UI so that a scrollbar may
		be informed when the application has finished redrawing
		a port window.  (So that it may scroll some more).

CALLED BY:	WinAckUpdate, GrEndUpdate

PASS:		ds	- locked window block

RETURN:		ds	- unchanged

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinSendUpdateComplete	proc	far	uses	bp
	.enter

	mov	ax, MSG_META_WIN_UPDATE_COMPLETE
	mov	bx, ds:[W_inputObj].handle
	mov	si, ds:[W_inputObj].chunk
	clr	dx			; clear data not used
	clr	bp
					; pass handle of window in cx
	mov	cx, ds:[W_header.LMBH_handle]

	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	jnz	WSUC_90			; if so, do nothing
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
WSUC_90:
	.leave
	ret

WinSendUpdateComplete	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrBeginUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by application to update exposed region, on reciept
		of MSG_META_EXPOSED.   Stores the GState passed into the window
		structure for future comparisons during mask region calculation.
		Copies the W_invalReg into W_updateReg in the window structure,
		and nulls out W_invalReg.  Drawing actions using the "update"
		GState registered here will be clipped to the W_updateReg.
		Only one gstate may be used to "Update" a window.  A typical
		handling of MSG_META_EXPOSED looks like:

	SimpleContentExposed	method	SimpleContentClass, MSG_META_EXPOSED
		mov	di, cx		; move Window handle to di
		call	GrCreateState	; create GState, handle in di
		call	GrBeginUpdate	; register GState as update GState
		push	di		; preserve GState

		call	RedrawImage	; redraw the image to appear in window

		pop	di		; get back GState
		call	GrEndUpdate	; notify window sys of end of update
		call	GrDestroyState	; nuke the GState, not needed anymore.
		ret
	SimpleContentExposed	endm



CALLED BY:	GLOBAL

PASS:		di	- handle of GState which will be used to
			  update the exposed area of the window

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/20/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

if	TEST_WIN_SPEED
updateStart	word	0
updateEnd	word	0
endif

GrBeginUpdate	proc	far
	call	PushAllFar

if	TEST_WIN_SPEED
	push	ax, bx
	call	TimerGetCount			;bx.ax = count
	mov	cs:[updateStart], ax
	pop	ax, bx
endif

EC <	call	ECCheckGStateHandle	; Make sure a GState handle	>
	push	di
	call	FarWinLockFromDI	; Get the window locked.
	mov	bx, di			; put window handle in bx
	pop	di			; & gstate in di
	jc	exit			; just exit for gstrings

					; ds = segment of window

EC <	cmp	ds:[W_updateState],0					>
EC <	jz	WSU_1							>
EC <	ERROR	WIN_UPDATE_NESTED					>
EC <WSU_1:								>

	mov	ds:[W_updateState],di

	; See if update drawing is suspended
	;
	tst	ds:[W_suspendCount]
	jnz	continueUpdate		; If so, then continue update, but
					; with a NULL update region, & all
					; of the invalid stuff still left to
					; do.

				; SWAP handles, so W_updateReg <- W_invalReg,
				; W_invalReg <- W_updateReg (NULL)
	mov	si, ds:[W_invalReg]
	mov	di, ds:[W_updateReg]
	mov	ds:[W_invalReg], di
	mov	ds:[W_updateReg], si

continueUpdate:
					; no more exposure pending
	and	ds:[W_regFlags], not mask WRF_EXPOSE_PENDING


	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	jnz	WSU_90			; if so, leave current NULL mask
					; region valid.
					; mark mask region as invalid, so
					; that it will be recalculated
	andnf	ds:[W_grFlags], not (mask WGF_MASK_VALID)
WSU_90:
					; bx = window handle
	call	WinUnlockV		; unlock, release window
exit:
	call	PopAllFar
	ret

GrBeginUpdate	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEndUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks window from Update draw.  Marks W_updateReg to be
		no longer in use.  Frees process to "start" drawing to
		another window.

CALLED BY:	GLOBAL

PASS:		di	- handle of GState which was passed to GrBeginUpdate

RETURN:		none

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/20/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

GrEndUpdate	proc	far
	call	PushAllFar

EC <	call	ECCheckGStateHandle	; Make sure a GState handle	>
EC <	push	di			; preserve GState		>
	call	FarWinLockFromDI
EC <	pop	bx			; get GState in bx		>
	jc	exit

EC <	cmp	ds:[W_updateState], bx	; make sure correct GState	>
EC <	ERROR_NE	WIN_BAD_END_UPDATE				>

	mov	ds:[W_updateState], 0	; No longer doing update

	push	di			; save window handle on stack
	mov	di, ds:[W_updateReg]	; set W_updateReg to NULL
	segmov	es, ds
	call	FarWinNULLReg		; & fixup DS
EC <	mov	ax, NULL_SEGMENT	; Indicate done with es	>
EC <	mov	es, ax							>

	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	jnz	WEU_90			; if so, skip sending events, which
					; we can't have around, & leave NULL
					; mask as it is (leave valid)

	andnf	ds:[W_grFlags], not mask WGF_MASK_VALID	; show mask not valid

	call	WinSendUpdateComplete	; Let input/output handler object
					; know that drawing has been completed

	call	WinSendExpEvent		; Send new exposure event, if necessary
					; NOTE: doesn't change ds
WEU_90:
	pop	bx
	call	WinUnlockV		; unlock and V the window
exit:

if	TEST_WIN_SPEED
	push	ax, bx
	call	TimerGetCount			;bx.ax = count
	mov	cs:[updateEnd], ax
	pop	ax, bx
endif
	call	PopAllFar
	ret

GrEndUpdate	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinInvalReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidates portion of window, as indicated by region or
		rectangle passed, in window coordinates

CALLED BY:	GLOBAL

PASS:
	In WINDOW coordinates:
	ax, bx, cx, dx - parameters for region, bounds if a rectangular region
	bp:si - region (0 for rectangular)
	di - handle of graphics state, or window

RETURN:
	none

DESTROYED:
	none

PSEUDO CODE/STRATEGY:
	W_invalReg = (W_invalReg OR wUserInvalReg) AND W_visReg;
	if W_invalRegion was NULL, isn't anymore, & expose not pending,
	send EXPOSE event

KNOWN BUGS/SIDE EFFECTS/IDEAS:

    All Kernel versions through V1.05, V1.13:

        Trashes memory in the case that a null region is passed. The window
	structure itself will nearly always be screwed up, & the damage
	could extend to the next block.

        V1.05, V1.13 & before development work-around:  Since WinInval* of a
	null region has no effect, simply skip the call if region is null
        (first word = EOREGREC)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/21/88	Initial version
	Doug	5/91		Reviewed header doc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinInvalReg	proc	far
	
if	FULL_EXECUTE_IN_PLACE
EC <	tst	bp				>
EC <	jz	continue			>
EC <	xchg	bx, bp				>
EC <	call	ECAssertValidFarPointerXIP	>
EC <	xchg	bx, bp				>
continue::
endif

	call	PushAllFar

	call	FarWinLockFromDI	; get window locked
	jc	exit

	mov	dx,ss			;dx:cx = parameters
	mov	cx,sp
	add	cx, offset PAF_ax

	push	di			; save window handle

	mov	di,si			; pass region in bp:di
	mov	si, ds:[W_temp1Reg]	; pass chunk handle

	call	SetupOtherReg		; Setup region W_temp1Reg
					; ds = window segment

	call	WinAddToInvalReg	; Add W_temp1Reg into W_invalReg, generate
					;	MSG_WIN_EXOSED if necessary
	pop	bx
	call	WinUnlockV		;release window

exit:
	call	PopAllFar
	ret

WinInvalReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCalcVisReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates new W_visReg, updates W_invalReg

CALLED BY:	INTERNAL

PASS: 		ds		- segment of window (locked)
		  :[W_winReg]	- window's region definition
		  :[W_univReg]	- holds current universe region for window
		  :[W_visReg]	- previous visible region, before change
		  :[W_childReg]	- holding W_childReg


RETURN:		si, di, es unchanged
		ds		- segment of window (locked)
		  :[W_visReg]	- new visible region for window

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	W_visReg	= W_univReg AND NOT (W_childReg)
	W_visReg	-= any save-under areas we've collided with
	W_invalReg = (W_invalReg OR NOT(W_visReg(OLD)) AND W_visReg;
	If W_invalReg was NULL, isn't now, & mask WRF_EXPOSE_PENDING isn't set {
		Send EXPOSE event;
		Set W_EXPOSE_SENDING;
	}
	clear flag showing summing siblings;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK
	Doug	3/18/93		New handling of save-under regions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinCalcVisReg	proc	near
	uses	si, di, es
	.enter

EC <	call	WinCheckRegPtr					>
	segmov	es, ds				; put segment in es

	; Before we change the visible region, we'd better check to see if
	; the W_invalReg reads "WHOLE".  This really means "The WHOLE Vis
	; region has been invalidated & washed out".  Bsically, if the new vis
	; region covers new territory, it won't have been white-washed, &
	; the value WHOLE will be quite wrong.  So.  We need to set any WNOLE
	; inval reg to be just the current Vis region. -- Doug 1/93

	mov	si, ds:[W_invalReg]
	mov	di, ds:[si]
	cmp	word ptr ds:[di], WHOLE_REG
	jne	notWholeInval
	mov	si, ds:[W_visReg]
	mov	di, ds:[W_invalReg]
	call	FarWinCopyLocReg		; copy region over
notWholeInval:

	; Save old visible region in temp1Reg
	; W_temp1Reg = NOT(W_visReg(OLD))
	;
	mov	si, ds:[W_visReg]		; assume a visible region
	mov	di, ds:[W_temp1Reg]
	call	FarWinNOTLocReg

	; DIFFERENT STRATEGIES DEPENDING ON CHILDREN
	;
	mov	ax, es:[W_firstChild]		; Does window have children?
	cmp	ax, NULL_WINDOW
	jne	children			; branch if window has children

	; NO CHILDREN STRATEGY HERE
	;
	mov	si, es:[W_univReg]
	mov	di, es:[W_visReg]
	call	FarWinCopyLocReg		; copy region over
	jmp	common

	; WINDOWS WITH CHILDREN CALC VIS REGION HERE
	; Children cover us -- subtract them out
	; w:W_temp2Reg  = NOT w:W_childReg;
	;
children:
	mov	di, es:[W_temp2Reg]
	mov	si, es:[W_childReg]
	call	FarWinNOTLocReg

	; AND w/our universe
	; w:W_visReg = w:W_univReg AND w:W_temp2Reg;
	;
	mov	di, es:[W_visReg]
	mov	bx, es:[W_univReg]
	mov	si, es:[W_temp2Reg]
	call	FarWinANDLocReg
common:
						; Clear once "siblings" used as
						;    "children" no longer needed
	andnf	es:[W_regFlags], not mask WRF_SIBLING_VALID

						; Done with childReg.

	call	SwapChildTemp1			; put temp1Reg in childReg for
						; 	a moment
	call	CorrectForSaveUnder		; Subtract out any save unders
						; we've collided with.
						; destroys temp1Reg, temp2Reg

	segmov	ds, es				; put final seg back in ds

	call	SwapChildTemp1			; get Temp1 back

	mov	di, es:[W_childReg]
	call	FarWinSMALLReg			; Don't need W_childReg anymore

EC <	mov	ax, NULL_SEGMENT		; Indicate done with es	>
EC <	mov	es, ax							>

	; Now, add not(old VisReg) into W_invalReg passed in W_temp1Reg.
	; Will send exposure event if new exposure.
	;
	andnf	ds:[W_grRegFlags], not (mask WGRF_PATH_VALID or \
				        mask WGRF_WIN_PATH_VALID)
	call	WinAddToInvalReg
EC<	call	CheckDeathVigil			; Err if mask!=NULL & closed >

	.leave
	ret
WinCalcVisReg	endp


SwapChildTemp1	proc	near
	mov	ax, ds:[W_temp1Reg]
	xchg	ds:[W_invalReg], ax
	mov	ds:[W_temp1Reg], ax
	ret
SwapChildTemp1	endp


COMMENT @----------------------------------------------------------------------

FUNTION:	WinSendExpEvent

DESCRIPTION:	Sends MSG_META_EXPOSED event if not already updating or waiting
		for response to a previous MSG_META_EXPOSED sent out.

CALLED BY:	GrEndUpdate, WinAddToInvalReg

PASS:
	ds 		- segment of PLock'd window
	ds:W_updateState	- non-zero if updating
	ds:W_regFlags	- mask WRF_EXPOSE_PENDING set if exposed event sent & not
				responded to yet
	ds:W_visReg	- visible region of window
	ds:W_invalReg	- invalid region of window
	ds:W_color	- mask WCF_PLAIN set if window doesn't need to
			  receive exposed events

RETURN:
	ds		- new segment of window

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
------------------------------------------------------------------------------@

WinSendExpEvent	proc	far
					; see if window needs MSG_META_EXPOSED's
	test	ds:[W_color], mask WCF_PLAIN
	jnz	WSEE_90			; if not, if single color, then nuke
					;  inval region.

	cmp	ds:[W_updateState], 0	; Are we in the middle of updating?
	jnz	WSEE_90			; If so, don't send event.  Instead,
					; it will be sent at GrEndUpdate.

					; if exposure event pending, or update
					; drawing suspended, don't bother
	test	ds:[W_regFlags], mask WRF_EXPOSE_PENDING
	jnz	WSEE_90
	tst	ds:[W_suspendCount]
	jnz	WSEE_90


	mov	si, ds:[W_visReg]
	mov	si, ds:[si]		; get ptr to Vis region
	cmp	{word} ds:[si], EOREGREC	; See if NULL Vis region
	je	WSEE_90		; if NULL visible region, isn't exposed

	mov	si, ds:[W_invalReg]
	mov	si, ds:[si]		; get ptr to Inval region
	cmp	{word} ds:[si], EOREGREC	; See if NULL inval region
				; if is still NULL, or became NULL, don't care
	je	WSEE_90

					; Send MSG_META_EXPOSED to objecT
					; stored in OD
	mov	bx, ds:[W_exposureObj].handle
	mov	si, ds:[W_exposureObj].chunk
	tst	bx
	jz	WSEE_90			; If NULL OD, then consider this
					; a PLAIN window for now - update
					; is complete.

	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	jnz	WSEE_noSend		; if so, do nothing

	push	bp
	mov	ax, MSG_META_EXPOSED
	mov	cx, ds:[W_header.LMBH_handle]	; pass handle of window in cx
	clr	dx			; clear data not used
	clr	bp

	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bp

WSEE_noSend:
				; Set flag, showing pending
	or	ds:[W_regFlags], mask WRF_EXPOSE_PENDING
WSEE_90:
	ret
WinSendExpEvent	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinWashOut

DESCRIPTION:	Fills in window w/background color

CALLED BY:	INTERNAL

PASS:
	ds		- segment of P'locked window
	ds:W_invalReg	- region to wash out
	ds:W_color	- color flags
	ds:W_colorRGB	- RGB color value

RETURN:
	ds - new segment of window

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
------------------------------------------------------------------------------@

WinWashOut	proc	far
				; See if this window can be drawn to right now
	test	ds:[W_regFlags], mask WRF_DELAYED_V
	jz	WWO_30		; if no delayed V, then YES, draw to it.
				; else mark window as needing wash
	or	ds:[W_regFlags], mask WRF_DELAYED_WASH
	ret			; & we're done

WWO_30:
	FALL_THRU	DoWashOut
WinWashOut	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	DoWashOut

DESCRIPTION:	As long as window isn't WCF_TRANSPARENT, wipes out the region
		currently in W_invalReg with the window's background color.
		If the window is WCF_PLAIN, the W_invalReg is NULL'ed out,
		since a MSG_META_EXPOSED is not necessary

CALLED BY:	INTERNAL

PASS:
	ds		- segment of P'locked window
	ds:W_invalReg	- region to wash out  (may be NULL or WHOLE, or any
			  valid region)

RETURN:
	ds:W_invalReg	- NULL'd out if window is WCF_PLAIN
	all other ds:W_*Reg	- PRESERVED (This routine may be counted on to 
				     make no changes to the other regions)

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Added header
------------------------------------------------------------------------------@

DoWashOut	proc	far
	mov	si, ds:[W_invalReg]
	mov	si, ds:[si]	; get ptr to inval reg
	cmp	word ptr ds:[si], WHOLE_REG
	jne	DWO_50	; if not WHOLE, do was out w/W_invalReg

	call	SwapInvalVis
	call	WashOutInval	; if WHOLE invalReg, use Vis instead for wash
	call	SwapInvalVis
	jmp	short DWO_80

DWO_50:
	call	WashOutInval	; Fill invalidated area with
				; bacground color
DWO_80:
	test	ds:[W_color], mask WCF_PLAIN	; see if window needs inval reg
	jz	DWO_90			; if it does, then branch
	push	es
	segmov	es, ds
	mov	di, ds:[W_invalReg]	; Else
	call	FarWinNULLReg		; get rid of W_invalReg - it's taken
	; ds = es (WinNULLReg keeps it that way)
	pop	es
DWO_90:
	ret
DoWashOut	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WashOutInval

DESCRIPTION:	As long as window isn't WCF_TRANSPARENT, wipes out the region
		currently in W_invalReg (NOTE: may not be WHOLE) with the
		window's background color.

CALLED BY:	INTERNAL

PASS:
	ds		- segment of P'locked window
	ds:W_invalReg	- region to wash out
			  (can be NULL, But may NOT be WHOLE)

RETURN:
	ds:W_*Reg	- PRESERVED (This routine may be counted on to 
				     make no changes to the regions)

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Added header
------------------------------------------------------------------------------@

WashOutInval	proc	near
	mov	si, ds:[W_invalReg]
	mov	si, ds:[si]			; get ptr to inval reg
	cmp	{word} ds:[si], EOREGREC
	jne	WOI_10				; quit if NULL region
WOI_End:
	ret

WOI_10:
	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	jnz	WOI_End					; if so, do nothing
	test	ds:[W_color], mask WCF_MASKED		; masked?
	jnz	WOI_20					; if so, ignore transp
	test	ds:[W_color], mask WCF_TRANSPARENT	; see if transparent
	jnz	WOI_End					; if so, then done
WOI_20:
	push	es
	call	SwapInvalMask			; swap W_invalReg & W_maskReg

	push	{word}ds:[W_grFlags]		; save original mask values
	call	SetupMaskFlags			; setup mask values

if	0
	; Ensure pattern & dither offsets are valid

	mov	ax, ds:[W_winRect].R_left	; window origin -> (ax, bx)
	mov	bx, ds:[W_winRect].R_top
	mov	ds:[W_ditherX], ax		; save dither indices
	mov	ds:[W_ditherY], bx
	mov	ah, bl				; ah=y shift, al=x shift
	and	ax, 707h			; only need first 3 bits
	mov	ds:[W_pattPos], ax		; save new pattern position
endif

	segmov	es, ds				; setup es to have window seg
	mov	di, es:[0]			; get handle of block
	call	GrCreateState			; create a graphics state
	push	di
	mov	bx, di
	call	MemLock
	mov	ds, ax				; ds <- seg addr of GState

	test	es:[W_color], mask WCF_TRANSPARENT
	jnz	WOI_30				; skip wash if transparent

	mov	al, es:[W_color]		; get color flags
	push	ax
	and	al, mask WCF_MAP_MODE
	call	GrSetAreaColorMap
	pop	ax
	and	al, mask WCF_RGB		; pass on only RGB usage
	mov	ah, al
	mov	al, es:[W_colorRGB].RGB_red	; get index/red value
	mov	bl, es:[W_colorRGB].RGB_green	; get green value
	mov	bh, es:[W_colorRGB].RGB_blue	; get blue value
	call	SetAreaColorInt			; int version of GrSetAreaColor

	call	GrShiftDrawMask			; re-init mask/dither shifts

	mov	ax, es:[W_maskRect.R_left]	; get mask region left
	mov	bx, es:[W_maskRect.R_top]	; get mask region top
	mov	cx, es:[W_maskRect.R_right]	; get mask region right
	mov	dx, es:[W_maskRect.R_bottom]	; get mask region bottom

EC <	cmp	ax, cx							>
EC <	jle	WW_ERR_10						>
EC <	ERROR	GRAPHICS_BAD_COORDINATE					>
EC <WW_ERR_10:								>
EC <	cmp	bx, dx							>
EC <	jle	WW_ERR_20						>
EC <	ERROR	GRAPHICS_BAD_COORDINATE					>
EC <WW_ERR_20:								>

	push	bp
	mov	si, offset GS_areaAttr		; CommonAttrs -> ds:si
	mov	di, DR_VID_RECT			; do the rectangle
	call	es:[W_driverStrategy]		; make call to driver
	pop	bp

WOI_30:
	; If this window needs to be masked, draw the mask now.

	test	es:[W_color], mask WCF_MASKED
	jz	washDone

	pop	di
	push	di

	pusha
	mov	ax, C_BLACK
	call	SetAreaColorInt

	mov	ax, es:[W_maskRect.R_left]	; get mask region left
	mov	bx, es:[W_maskRect.R_top]	; get mask region top
	mov	cx, es:[W_maskRect.R_right]	; get mask region right
	mov	dx, es:[W_maskRect.R_bottom]	; get mask region bottom

	mov	di, DR_VID_RECT			; do the rectangle
	mov	si, offset GS_areaAttr		; CommonAttrs -> ds:si
	ornf	es:[W_color], mask WCF_DRAW_MASK
	call	es:[W_driverStrategy]		; make call to driver
	andnf	es:[W_color], not mask WCF_DRAW_MASK
	popa

washDone:
	mov	ds:[GS_window], 0
	segmov	ds, es				; put window handle back in ds
EC <	mov	ax, NULL_SEGMENT		; Indicate done with es	>
EC <	mov	es, ax							>

	pop	di
	mov	bx, di
	call	MemUnlock
	call	GrDestroyState			; dump graphics state

	mov	ax, EOREGREC			; invalidating the top & bottom
	mov	ds:[W_clipRect.R_top], ax	; ...of W_clipRect will cause
	mov	ds:[W_clipRect.R_bottom], ax	; ...the re-calc of the clipPtr
	pop	{word} ds:[W_grFlags]		; restore flags

	call	SwapInvalMask			; restore W_invalReg & W_maskReg
	pop	es
	ret
WashOutInval	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAreaColorInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal version of GrSetAreaColor, for window system

CALLED BY:	INTERNAL
		WashOutInval

PASS:		same as GrSetAreaColor, plus:
		es	- window segment

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetAreaColorInt	proc	near
		uses	ax,bx,cx,dx,si
		.enter

		; signal gstate not locked, call common routine

		clr	cl			; signal gstate not locked
		mov	si, GS_areaAttr.CA_colorIndex	; set up pointer
		call	SetColor		; set the color

		.leave
		ret
SetAreaColorInt	endp


WinMovable ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCalcRawObscure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculates W_univReg, W_visReg & W_maskReg for a window,
		obscuring these regions by ANDing them with the region in
		W_temp1Reg (Already a NOT mask of the region obscuring this
		window)

CALLED BY:	INTERNAL

PASS:		dx		- Same as ds if W_univReg should be left alone.

		ds		- segment of window (locked)
		  :[W_winReg]	- window's region definition
		  :[W_univReg]	- holds current universe region for window
		  :[W_visReg]	- previous visible region, before change
		  :[W_temp1Reg]	- holds region to obscure window with


RETURN:		si, di, es unchanged
		ds		- segment of window (locked)
		  :[W_univReg]	- new universe
		  :[W_visReg]	- new visible region for window
		  :[W_maskReg]	- new mask region

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/89		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinCalcRawObscure	proc	far
	uses	si, di, es
	.enter

	segmov	es, ds, ax		; DS => ES & AX
	cmp	dx, ax			; is dx = ds?
	je	$50			; if so, leave W_univReg unchanged

	mov	si, ds:[W_univReg]	; ds = es
	mov	bx, ds:[W_temp1Reg]
	mov	di, ds:[W_temp2Reg]
	call	WinANDLocReg		; and universe w/obscure mask
	call	SwapESTemp2Univ		; Swap es:W_univReg into es:W_temp2Reg
$50:
	mov	si, es:[W_visReg]
	mov	bx, es:[W_temp1Reg]
	mov	di, es:[W_temp2Reg]
	call	WinANDLocReg		; and visible w/obscure mask

	mov	ax, es:[W_visReg]	; swap region chunk handles
	xchg	es:[W_temp2Reg], ax
	mov	es:[W_visReg], ax

	test	es:[W_grFlags], mask WGF_MASK_VALID
	jz	$70			; if mask valid, then don't update it
	mov	si, es:[W_maskReg]
	mov	bx, es:[W_temp1Reg]
	mov	di, es:[W_temp2Reg]
	call	WinANDLocReg		; and visible w/mask mask

	mov	ax, es:[W_maskReg]	; swap region chunk handles
	xchg	es:[W_temp2Reg], ax
	mov	es:[W_maskReg], ax
$70:
	andnf	es:[W_grRegFlags], not (mask WGRF_PATH_VALID or \
					mask WGRF_WIN_PATH_VALID)
	call	SetTempRegsSMALL	; Don't need W_temp1Reg, temp2 anymore
	segmov	ds, es
EC <	mov	ax, NULL_SEGMENT	; Indicate done with es	>
EC <	mov	es, ax							>

	test	ds:[W_grFlags], mask WGF_MASK_VALID
	jz	done			; If mask valid, then don't update it
	call	SetupMaskFlags		; setup shortcut data for driver
done:
EC <	call	CheckDeathVigil		; Err if mask!=NULL & closed	>

	.leave
	ret
WinCalcRawObscure	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinValWinStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL
		EnterGraphics

PASS:		ds - graphics state structure
		es - PLock'd Window

RETURN: 	es	- new segment of locked Window structure
		if W_grFlags bit mask WGF_MASK_VALID was clear (hence, invalid),
		performs the following work:

		- New clip region generated from Visible region & application
			region
		- New bounds for clip region determined
		- Clipping optimization vars updated
		- Document conversion variables updated

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	if (different GState) {
	    InvalidateRegion(mask_reg);
	    InvalidateRegion(GS_app_reg);
	    InvalidateRegion(Win_app_reg);
	    InvalidateTransform();
	}
	if (transform invalid) {
	    ComposeMatrix();
	}
	mask_reg = (visible_reg AND NOT(invalid_reg));
	if (GS_app_reg != NULL) {
	    if (complex transform) {
		TransformRegion(GS_app_reg);
	    }
	    mask_reg = (mask_reg AND GS_app_reg);
	}
	if (Win_app_reg != NULL) {
	    if (complex transform) {
		TransformRegion(Win_app_reg);
	    }
	    mask_reg = (mask_reg AND Win_app_reg);
	}
	if (update GState) {
		mask_reg = (mask_reg AND update_reg);
	}
	UpdateFlags();
	ShiftDrawMasks();

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/26/88		Initial version
	Gene	4/90		Added transformed regions, documentation.
	jim	7/91		Added far version for GrGetWinBoundsDWord

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinValWinStrucFar proc	far
		call	WinValWinStruct
		ret
WinValWinStrucFar endp

WVWS_done2	label	near
	jmp	WVWS_flags

WinValWinStruct	proc	near
	uses	ax, bx, cx, dx, si, di
	.enter

EC <	push	bx							>
EC <	mov	bx, es:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>

	;
	; Reset XFORM_VALID, MASK_VALID and APP_VALID if the gstate we
	; are using is not the current one (W_curState).
	;
	mov	ax, ds:LMBH_handle		;ax <- GState handle
	cmp	ax, es:W_curState		;current GState?
	je	isCurrentGState
	andnf	{word}es:W_grFlags, not (mask WGF_XFORM_VALID or \
					 mask WGF_MASK_VALID or \
					 mask WGRF_PATH_VALID shl 8 or \
					 mask WGRF_WIN_PATH_VALID shl 8)
	mov	ax, 0xffff
	call	InvalidatePaths			; take them out
isCurrentGState:
	;
	; check W_grFlags to see if transformation matrix is valid
	;
	test	es:[W_grFlags], mask WGF_XFORM_VALID
	jnz	xformIsValid			;branch if xform is valid
	call	GrComposeMatrix			;updates flags, etc.
xformIsValid:
	test	es:[W_grFlags], mask WGF_MASK_VALID
	jnz	WVWS_done2			;all done if mask is valid
	;
	; Calculate W_maskReg.
	;
	; If gstate in use is update gstate:
	; 	W_maskReg = W_visReg AND W_updateReg AND(NOT W_invalReg)
	;		AND wAppReg
	;
	; If it is not:
	; 	W_maskReg = W_visReg AND (NOT W_invalReg) AND wAppReg
	;
	mov	si, es:[W_visReg]	; Assume we have a visible region

; WRONG!  The invalid region should ALWAYS be anded out of any drawing, to
; prevent drawing to an area that is white-washed out & is going to be
; updated soon anyway, via the standard Exposure mechanism.  This little
; bit of code has actually been in here since r1.9 (10/21/88, over a year ago!).
; It results in things redrawing twice on screen, when they need only be
; drawn at update time.  Affected UI window titles, probably affects other
; gadgets & apps as well.  I'm leaving this in here as a reminder not to
; "Optimize" this out of here again. -- Doug
;;	mov	ax, ds:[GS_header.LMBH_handle]
;;	cmp	ax, es:[W_updateState]
;;	jnz	GVWS_10			; If not doing update, don't bother
;;					;	w/W_invalReg

	mov	di, es:[W_invalReg]
	mov	di, es:[di]
	cmp	{word} es:[di], EOREGREC	;see if no inval region
	je	noInvalRegion			;branch if no inval region

	push	si
	mov	si, es:[W_invalReg]
	mov	di, es:[W_temp2Reg]		;W_tempReg2 = NOT(W_invalReg)
	call	WinNOTLocReg
	pop	si

	mov	bx, es:[W_temp2Reg]
	mov	di, es:[W_temp1Reg]		;W_tempReg1 = W_visReg AND
						;	NOT(W_invalReg)
	call	WinANDLocReg
	mov	si, es:[W_temp1Reg]		;si <- new source region
noInvalRegion:
	mov	di, es:W_temp2Reg		;di <- currently unused chunk
	push	bp
	;
	; Validate the GrSetClipRect() & GrSetClipPath() created Path, 
	; and AND it with the current mask region.
	;
	; SI is now either:
	; (1) W_visReg - the visible region (ie. no invalid region)
	; (2) W_temp1Reg - visible region minus the invalid region
	; DI is now:
	; (1) W_temp2Reg - unused chunk
	;
	mov	bx, ds:[GS_clipPath]		; BX <- Path handle
	tst	bx				; any clipping?
	jz	doneClipPath
	mov	al, mask WGRF_PATH_VALID	; AL <- flag to check / set
	mov	bp, es:[W_pathReg]		; BP <- chunk of xformed region
	call	UpdateClipPath
	mov	di, es:[W_temp1Reg]		; DI <- currently unused chunk
doneClipPath:
	;
	; Validate the GrSetWinClipRect() & GrSetWinClipPath() created Path,
	; and AND it with the current mask region.
	;
	; SI is now either:
	; (1) W_visReg - the visible region
	; (2) W_temp1Reg - the visible region minus the invalid region
	; (3) W_temp2Reg - visible, minus invalid, AND app region
	; DI is now either:
	; (1) W_temp2Reg - unused chunk (if case (1) or (2) above)
	; (2) W_temp1Reg - unused chunk (if case (3) above)
	;
	mov	bx, ds:[GS_winClipPath]		; BX <- Path handle
	tst	bx				; any clipping?
	jz	doneWinClipPath
	mov	al, mask WGRF_WIN_PATH_VALID	; AL <- flag to check / set
	mov	bp, es:[W_winPathReg]		; BP <- chunk of xformed region
	call	UpdateClipPath
	mov	di, es:[W_temp1Reg]		; DI <- currently unused chunk
doneWinClipPath:
	;
	; One way or another, the application clip regions have
	; been updated, and are now valid. Mark them as such.
	;
	ornf	es:W_grRegFlags, mask WGRF_PATH_VALID or \
				 mask WGRF_WIN_PATH_VALID
	pop	bp
	;
	; We're almost done. We just need to AND with the
	; update region (the area of the window that actually
	; needs redrawing) to restrict the drawing further.
	; si is now either:
	; (1) W_visReg - the visible region
	; (2) W_temp1Reg - visible region minus the invalid region
	; (3) W_temp2Reg - visible, AND app region
	; (4) W_temp2Reg - visible, AND doc region
	; (5) W_temp2Reg - visible, minus invalid, AND app region
	; (6) W_temp2Reg - visible, minus invalid, AND doc region
	; (7) W_temp1Reg - visible, minus invalid, AND app AND doc regs
	;
	mov	di, es:[W_maskReg]		;di <- destination region
	mov	ax, ds:[GS_header.LMBH_handle]	;see if doing update
	cmp	ax, es:[W_updateState]
	jnz	notUpdateRegion			;if not in use, branch
	mov	bx, es:[W_updateReg]		;bx <- region to AND with
	call	WinANDLocReg			;AND with update region
	jmp	afterUpdateRegion
notUpdateRegion:
	call	WinCopyLocReg			;copy if no update region
afterUpdateRegion:
	;
	; At this point, W_maskReg is the region to which to draw.
	; Starting with the visible region, the invalid region is
	; removed. The region is further restricted by any application
	; clip regions, one specified by WinSetClipRect(), one by
	; GrSetClipRect(). It may also be further restricted by the
	; update region.
	;
	call	SetTempRegsSMALL		;done with temp regions

WVWS_flags label near
	push	ds
	segmov	ds,es				;ds <- seg addr of Window
	call	SetupMaskFlags			;calc new mask bounds
	pop	ds

	mov	ax, ds:[GS_header.LMBH_handle]	;mark as current GState
	mov	es:[W_curState], ax
	call	GrShiftDrawMask			;align patterns to screen
	.leave
	ret
WinValWinStruct	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateClipPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update an application clip path

CALLED BY:	WinValWinStruct()

PASS:		ES	= PLock'd Window
		*DS:BX	= Chunk of source Path
		*ES:BP	= Chunk of xformed region (may be valid)
		*ES:SI	= Chunk of current draw region
		*ES:DI	= Chunk of dest region
		AL	= WinGrRegFlags to check / set

RETURN:		ES	= Segment address of Window (updated)
		DS	= Segment address of GState (updated)
		*ES:SI	= Chunk of new draw region
		transformed region validated

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:
	if (!valid) {
		if (complex(TMatrix)) {
			CallKL(TransformRegion);
		} else {
			xformed = (source * TMatrix);
		}
		valid = TRUE;
	}
	dest = current AND xformed;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The transformed region in the Window may not correspond
	to the rectangle in the GState, yet it may be marked
	valid. This will only happen if the clipping goes from
	some rectangle to no rectangle. If the rectangle is NULL,
	however, the region is not ANDed with the final draw mask,
	giving the correct results.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/29/90		Initial version
	Don	7/16/91		Changed to deal with Paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateClipPath	proc	near
	.enter

EC <	push	bx							>
EC <	mov	bx, es:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>

EC <	push	ax, ds							>
EC <	segmov	ds, es							>
EC <	mov	ax, NULL_SEGMENT		; Indicate done with es	>
EC <	mov	es, ax							>
EC <	call	ECheckWinRegions					>
EC <	segmov	es, ds							>
EC <	pop	ax, ds							>

	; Some set-up work
	;
	push	ds:[LMBH_handle]		;save GState handle
	push	si				;save current draw region
	push	bp				;save xformed region
	push	di				;save dest region

	; Is the transformed region still valid? If so, just use it.
	;
	test	es:[W_grRegFlags], al		;is region valid?
	jnz	regionValid			;branch if region valid

	; Get the window offsets & curTMatrix flags to detect type
	; of transformations used
	;
	mov	cx, es:[W_winRect].R_left	; CX <- x offset
	mov	dx, es:[W_winRect].R_top	; DX <- y offset

	; Make a copy of the clip region, and translate it
	; to convert to the correct coordinates space.
	;
	mov	si, bx				;*ds:si - source path
	mov	di, bp				;*es:di - dest region
	call	WinCopyPathToReg

	; The application clip region is now valid. AND it with
	; the current draw region to create a new draw region.
	;
regionValid:

	segmov	ds, es				;ds <- seg addr of Window
	pop	di				;*es:di <- dest region
	pop	bx				;*es:bx <- xformed region (path)
	pop	si				;*ds:si <- current draw region
	push	di
	call	WinANDReg			;calc (draw AND path)

	pop	si				;*es:si <- new draw region
	pop	bx				;GState handle => BX
	call	MemDerefDS			;fixup the GState segment

EC <	push	ds							>
EC <	segmov	ds, es							>
EC <	mov	ax, NULL_SEGMENT		; Indicate done with es	>
EC <	mov	es, ax							>
EC <	call	ECheckWinRegions					>
EC <	segmov	es, ds							>
EC <	pop	ds							>

	.leave
	ret
UpdateClipPath	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupMaskFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixes up wMaskBounds & all shortcut flags derived from the
		wMaskReg.  Used by various routines which temporarily stuff
		a new wMaskReg to draw/whatever, & then restore the wMaskReg
		when they are done.

CALLED BY:	INTERNAL

PASS:		ds		- PLock'd Window
		  :[W_maskReg]	- new mask region

RETURN:		ds		- segment of window (locked)
		  :[W_maskRect.*]	- set based on W_maskReg
		  :[W_grFlags]		- shows valid mask reg, opt flags set
		  :[W_clipRect.*]	- Invalidated

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupMaskFlags	proc	far
EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>
				; Calculate new clip region bounds & shortcuts

	mov	si, ds:[W_maskReg]	; set ds:si ptr to clipping region
	mov	si, ds:[si]
	call	GrGetPtrRegBounds	; CONVERT to rectangular bounds
					; ax = left
					; bx = top
					; cx = right
					; dx = bottom
	mov	ds:[W_maskRect.R_left], ax	; store mask region left
	mov	ds:[W_maskRect.R_top], bx	; store mask region top
	mov	ds:[W_maskRect.R_right], cx	; store mask region right
	mov	ds:[W_maskRect.R_bottom], dx	; store mask region bottom
	;
	; Set flags to initially only mask valid (WGF_MASK_VALID)
	; leaving the transform flag (WGF_XFORM_VALID) and application
	; clip region flags (WGRF_PATH_VALID and WGRF_WIN_PATH_VALID)
	; unchanged.
	;
	andnf	{word}ds:W_grFlags, mask WGF_XFORM_VALID or \
				    mask WGRF_PATH_VALID shl 8 or \
				    mask WGRF_WIN_PATH_VALID shl 8
	ornf	ds:W_grFlags, mask WGF_MASK_VALID

	mov	si, EOREGREC
	mov	ds:[W_clipRect.R_top], si	; Inval W_clipRect.R_top & Hi
	mov	ds:[W_clipRect.R_bottom], si	; Will cause re-calc of clipPtr

				; Check for simple region
	mov	si, ds:[W_maskReg]	; get handle to mask region
	mov	si, ds:[si]		; change from handle to ptr

	cmp	{word} ds:[si], EOREGREC	; see if first word NULL
	jnz	SMF_notNull			; jump if not NULL
	ornf	ds:[W_grFlags], mask WGF_MASK_NULL  ; OR in results to W_grFlags
	jmp	SMF_maskNotSimple		; rejoin other branch to quit

SMF_notNull:
	;check for mask simple
	cmp	{word} ds:[si].RR_eo2,EOREGREC
	jnz	SMF_maskNotSimple
	cmp	{word} ds:[si].RR_eo3,EOREGREC
	jnz	SMF_maskNotSimple
	ornf	ds:[W_grFlags], mask WGF_MASK_SIMPLE or mask WGF_CLIP_SIMPLE
	mov	ds:[W_clipRect].R_left,ax
	mov	ds:[W_clipRect].R_top,bx
	mov	ds:[W_clipRect].R_right,cx
	mov	ds:[W_clipRect].R_bottom,dx
	add	si,RR_x1
	mov	bx, ds:W_maskReg		; bx <- maskReg handle.
	sub	si, ds:[bx]			; make si be an offset into
	mov	ds:[W_clipPtr],si		; the mask region.
SMF_maskNotSimple:
EC<	call	CheckDeathVigil			; Err if mask!=NULL & closed >
	ret

SetupMaskFlags	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinMaskOutSaveUnder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reduces W_visReg, W_maskReg to not include save-under
		region passed

CALLED BY:	GLOBAL (graphics driver)

PASS:	ax, bx, cx, dx	- left, top, right, bottom bounds of save under reg
	si		- handle of window having save under
	bp		- handle of parent of window having save under
	di		- flag of save area collision has occured with
	es		- PLock'd window block having draw collision
				with save area

RETURN:	
	es	- new segment of block (MUST BE UNCHANGED IF ERRORS
			  ARE NOT ALLOWED IN THIS ROUTINE)  Somehow we have
			  to figure out how to write this such that the block
			  will never be resized.
	ds	- unchanged
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/89		Initial version
	Doug	3/18/93		New handling of save-under regions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinMaskOutSaveUnder	proc	far
EC <	push	bx							>
EC <	mov	bx, es:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>

	push	ds
	push	ax
	mov	ax, di

	; Set W_savedUnder... Flags/Mask state for the save under involved
	; to the "Window regions altered to be clipped by the window
	; w/Save under" state.  That is, Mask = 0 (no more collisions
	; need be tested for), & Flag = 1
	;
	or	es:[W_savedUnderFlags], al	; set flag bit
	not	al
	and	es:[W_savedUnderMask], al	; clear mask bit
	pop	ax


if USE_SAVE_UNDER_REG
	mov	bx, si
	call	WinSetESTemp1ToNotSaveUnderWinBX
else
	push	bp
	call	WinSetESTemp1ToNotRect	; get NOT reg into W_temp1Reg
	pop	bp
endif

					; NOW obscure W_univReg, W_visReg,
					;	& W_maskReg with it.
	segmov	ds, es
EC <	mov	ax, NULL_SEGMENT	; Indicate done with es	>
EC <	mov	es, ax							>

	; OK, let's punch a hole in the visible & mask region for the window
	; passed in es.
	;
	mov	dx, ds			; pass dx=ds, so that W_univReg is
					; left alone.
	call	WinCalcRawObscure
	segmov	es, ds
	pop	ds
	ret

WinMaskOutSaveUnder	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinSetESTemp1ToNotSaveUnderWinBX

DESCRIPTION:	Stores not(W_winReg of passed save under'd window) into
		temp1Reg of the window passed.

CALLED BY:	INTERNAL

PASS:	es	- locked, P'd window
	bx	- save under'd window

RETURN:
	es:[temp1Reg]	- NOT (^hbx.W_winReg)

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/21/95		Initial header
------------------------------------------------------------------------------@
if USE_SAVE_UNDER_REG
WinSetESTemp1ToNotSaveUnderWinBX	proc	far
	push	si, di
	call	MemPLock		; lock save under'd window
	push	bx
	mov	ds, ax
	mov	si, ds:[W_winReg]
	mov	di, es:[W_temp1Reg]
	call	WinNOTReg
	pop	bx
	call	MemUnlockV
	pop	si, di
	ret
WinSetESTemp1ToNotSaveUnderWinBX	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinSetESTemp1ToNotRect

DESCRIPTION:	Stores not(passed rectangle) into temp1Reg of the window
		passed.

CALLED BY:	INTERNAL

PASS:	es	- locked, P'd window
	ax, bx, cx, dx	- A rectangle

RETURN:
	es:[temp1Reg]	- NOT rectangle

DESTROYED:
	ax, bx, cx, dx, si, di, es:[temp2Reg]

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/90		Initial header
------------------------------------------------------------------------------@

if not USE_SAVE_UNDER_REG
WinSetESTemp1ToNotRect	proc	far
	push	ds
	LoadVarSeg	ds		; setup ds:si to point to underRegion
	mov	si, offset idata: underRegion
	mov	ds:[underRegionLeft],ax		;store left
	mov	ds:[underRegionRight],cx	;store right
	dec	bx				;set bx = top - 1
	mov	ds:[underRegionTopM1], bx	;store top - 1
	mov	ds:[underRegion+4], dx		;store bottom

	mov	di, es:[W_temp2Reg]
	call	WinSetReg			; copy into W_temp2Reg
	mov	si, es:[W_temp2Reg]
	mov	di, es:[W_temp1Reg]
	call	WinNOTLocReg			; get NOT reg into W_temp1Reg
	pop	ds
	ret

WinSetESTemp1ToNotRect	endp
endif


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinValClipLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	GLOBAL
		Graphics driver

PASS:		ds	- segment of PLock'd Window
		bx	- desired scan line
		Ownership of graphics semaphore

RETURN:		ds 	- unchanged (THIS ROUTINE NOT ALLOWED TO MOVE WINDOW!)
		si	- pointer to scan line info
		W_clipRect.R_top	- set to top Y line
		W_clipRect.R_bottom	- set to bottom Y line

DESTROYED:	ax, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
WVCL_CONST	=	mask WGF_CLIP_NULL or mask WGF_CLIP_SIMPLE or mask WGF_BUFFER_VALID

if	0
CheckSIInMask	proc	near
	uses	ax, di
	.enter

	mov	di, ds:W_maskReg
	mov	di, ds:[di]
	ChunkSizePtr	ds, di, ax
	cmp	si, di
	ERROR_B	-1
	add	di, ax
	cmp	si, di
	ERROR_A -1

	.leave
	ret
CheckSIInMask	endp

tonyisadorf	word	0
endif

WEC	macro	line
if	0
line
endif
endm


WinValClipLine	proc	far
EC <	xchg	ax, bx							>
EC <	call	CheckCoord						>
EC <	xchg	ax, bx							>

EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>

WEC <	mov	cs:tonyisadorf, bx					>

;;EC<	call	WinCheckClipInfo			>

	mov	ax,ds:[W_clipRect.R_bottom]	;start with current region
	mov	di,ds:[W_clipRect.R_top]
	andnf	ds:[W_grFlags], not WVCL_CONST
	cmp	di,EOREGREC		;if current region not valid
	jz	WVCL_top		;then start at top

	mov	si, ds:W_maskReg	;
	mov	si, ds:[si]		;si <- ptr to mask region.
	add	si,ds:[W_clipPtr]	;start with current region
WEC <	call	CheckSIInMask						>
	cmp	bx,di			;is bx below current region ?
	jge	WVCL_below		;if so then branch

	; clip area is above current area

	cmp	bx,ds:[W_maskRect.R_top]	;at top or above ?
	jle	WVCL_top

	std				;move backwards in string
WVCL_FS_10:
	lodsw				;loop back to find end of any line
WEC <	call	CheckSIInMask						>
	cmp	ax, EOREGREC		;if already pointing at NULL, that's OK
	jnz	WVCL_FS_10
	cmp	{word} ds:[si], EOREGREC	;if still pointing at NULL, must
	je	WVCL_FS_10		;	have been at end of region, find
					;	end of real line
WVCL_FS_15:
					;Check for at top of region
	mov	di, ds:[W_maskReg]
	mov	di, ds:[di]		;get ptr to mask region
	cmp	si, di			;see if at top of region
	je	WVCL_FS_25		;if pointing at start, stop here
WVCL_FS_20:
	lodsw				;back up to next line
WEC <	call	CheckSIInMask						>
	cmp	ax, EOREGREC
	jne	WVCL_FS_20
	cmp	ds:[si]+4, bx		;keep moving backward until past
	jge	WVCL_FS_15		;clip region we're looking for
	add	si, 4			;point at Y value in line
WVCL_FS_25:
	cld				;pointing below EOREGREC before line
	mov	di, ds:[si]+0		;get Y position of start
	inc	si			;point at first data
	inc	si
WEC <	call	CheckSIInMask						>
	jmp	short WVCL_beforeSkipEOLN

	; clip area is not valid -- start at top
WVCL_top:
	mov	di, 0c000h		; Initial W_clipRect.R_top value
	mov	si, ds:[W_maskReg]	; start at beginning of reg
	mov	si, ds:[si]

	; loop moving down region -- di = clipLo, si points at Y value

WVCL_downLoop:
	lodsw				;get Y value (possible clipHi)
WEC <	call	CheckSIInMask						>
	cmp	ax, EOREGREC		;at end?
	jz	WVCL_pastEnd
WVCL_below:
	cmp	ax,bx
	jge	WVCL_found
	mov	di,ax
WVCL_beforeSkipEOLN:
	inc	di
WVCL_skipEOLN:
	lodsw				;move past this scan area
WEC <	call	CheckSIInMask						>
	cmp	ax, EOREGREC
	jnz	WVCL_skipEOLN
	jmp	short WVCL_downLoop

	; found correct clip line -- di = clipLo, ax = clipHi

WVCL_found:
WEC <	call	CheckSIInMask						>
	mov	ds:[W_clipRect.R_bottom],ax		;store clipHi and clipLo
	mov	ds:[W_clipRect.R_top],di
	push	si			;
	mov_tr	ax, si			;
	mov	si, ds:W_maskReg	;
	sub	ax, ds:[si]		;ax <- offset into mask region
	pop	si			;si <- ptr to clip-line again.
	mov	ds:[W_clipPtr], ax	;store pointer to start of line data
	lodsw				;get firstON (or NULL)
	cmp	ax, EOREGREC
	jz	WVCL_lineNull
	mov	ds:[W_clipRect.R_left],ax
	lodsw
	mov	di,ax			;di = possible lastON
	lodsw				;get next ON (of NULL)
	cmp	ax, EOREGREC
	jz	WVCL_lineSimple		;if NULL then simple line
WVCL_lineLoop:
	lodsw				;get corresponding lastON
WEC <	call	CheckSIInMask						>
	mov	di,ax
	lodsw				;get next ON (of NULL)
	cmp	ax, EOREGREC
	jnz	WVCL_lineLoop		;if NULL then simple line
	mov	ds:[W_clipRect.R_right],di
;;EC<	call	WinCheckClipInfo			>
	ret				;clip neither NULL nor simple

	; line is simple (all points between firstON and lastON set)

WVCL_lineSimple:
	mov	ds:[W_clipRect.R_right],di
	ornf	ds:[W_grFlags],mask WGF_CLIP_SIMPLE
;;EC<	call	WinCheckClipInfo			>
	ret				;clip neither NULL nor simple

	; line is null

WVCL_lineNull:
	mov	ax,EOREGREC		;store nulls
	mov	ds:[W_clipRect.R_left],ax
	mov	ds:[W_clipRect.R_right],ax
	ornf	ds:[W_grFlags],mask WGF_CLIP_NULL
;;EC<	call	WinCheckClipInfo			>
	ret

	; rest of region is same as this

WVCL_pastEnd:
	mov	ax,3fffh
	dec	si			;point at end
	dec	si
	jmp	short WVCL_found

WinValClipLine	endp



if	ERROR_CHECK
if	(0)
WinCheckClipInfo	proc	near
EC<	call	CheckDeathVigil			; Err if mask!=NULL & closed >

	push	ax
	push	bx
	push	cx
	push	dx
	push	di
	mov	di, ds:W_maskReg	;
	mov	di, ds:[di]		;
	add	di, ds:[W_clipPtr]	; get ptr to clip info
					; ds is segment of window
					; MASK MUST BE VALID HERE
	test	ds:[W_grFlags], mask WGF_MASK_VALID
	jnz	WCCI_10
	ERROR	BAD_REGION_DEF
WCCI_10:
	mov	ax, ds:[W_clipRect.R_left]
	mov	bx, ds:[W_clipRect.R_top]
	mov	cx, ds:[W_clipRect.R_right]
	mov	dx, ds:[W_clipRect.R_bottom]
					; If top & bottom are NULL,
	cmp	bx, EOREGREC
	jne	WCCI_12
	cmp	dx, EOREGREC
	jne	WCCI_12
	jmp	WCCI_200		; all OK
WCCI_12:
	cmp	bx, dx			; make sure top <= bottom
	jle	WCCI_14
	ERROR	BAD_REGION_DEF
WCCI_14:
	cmp	ax, cx			; make sure left <= right
	jle	WCCI_15
	ERROR	BAD_REGION_DEF
WCCI_15:
	push	ax
	push	bx
	mov	bx, ds:[W_maskReg]	; get chunk of W_maskReg
	mov	ax, ds:[bx]		; get ptr to mask reg, put in ax
	cmp	di, ax			; make sure clip ptr in MaskReg
	jae	WCCI_16
	ERROR	BAD_REGION_DEF
WCCI_16:
	push	ax, si
	mov	si, bx
	call	ChunkSizeHandleDS_SI_AX
	mov	bx, ax
	pop	ax, si

	add	ax, bx				; add in the size.
	cmp	di, ax				; make sure not past end
	jb	WCCI_18
	ERROR	BAD_REGION_DEF
WCCI_18:
	pop	bx
	pop	ax

					; NULL clip region?
	test	ds:[W_grFlags], mask WGF_CLIP_NULL
	jz	WCCI_100			; skip if not null
				; CHECK FOR PROPPER NULL CLIP REGION
	cmp	ax, EOREGREC
	je	WCCI_25			; make sure ON & OFF at EOREGREC
	ERROR	BAD_REGION_DEF
WCCI_25:
	cmp	cx, EOREGREC
	je	WCCI_30			; make sure ON & OFF at EOREGREC
	ERROR	BAD_REGION_DEF
WCCI_30:
					; If CLIP NULL, must point at NULL
	cmp	{word} ds:[di], EOREGREC
	je	WCCI_40
	ERROR	BAD_REGION_DEF
WCCI_40:
	jmp	WCCI_200		; all OK

WCCI_100:
				; CHECK FOR PROPPER NON-NULL CLIP REGION
	cmp	ax, ds:[W_maskRect.R_left]
	jge	WCCI_110
	ERROR	BAD_REGION_DEF
WCCI_110:
	cmp	cx, ds:[W_maskRect.R_right]
	jle	WCCI_120
	ERROR	BAD_REGION_DEF
WCCI_120:
	cmp	word ptr ds:[di]-2, dx	; Make sure value before W_clipPtr is
					;	bottom
	je	WCCI_130
	ERROR	BAD_REGION_DEF
WCCI_130:
					; Make sure at start of a line
	cmp	{word} ds:[di]-4, EOREGREC
	je	WCCI_135
	ERROR	BAD_REGION_DEF
WCCI_135:
	cmp	word ptr ds:[di], ax	; Make sure 1st point matches left
	je	WCCI_140		;	value
	ERROR	BAD_REGION_DEF
WCCI_140:
	jmp	WCCI_200		; all OK

WCCI_200:
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
WinCheckClipInfo	endp
endif
endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	WinGenLineMask

DESCRIPTION:	Generate lineMaskBuffer from thew current clipping state

CALLED BY:	GLOBAL
		Graphics driver

PASS:
	WinValClipLine called
	ds - PLock'd Window
	es:di - buffer to fill
	ax - pixel width of buffer to fill

RETURN:
	ds - unchanged (THIS ROUTINE NOT ALLOWED TO MOVE WINDOW!)
	es:di buffer set

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

-------------------------------------------------------------------------------@

WinGenLineMask	proc	far
EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>

if	FULL_EXECUTE_IN_PLACE
EC <	push	ds, si							>
EC <	segmov	ds, es, si						>
EC <	mov	si, di							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
endif
 
	ornf	ds:[W_grFlags], mask WGF_BUFFER_VALID

	push	bp
	mov	bp,ax			;number of bytes to fill
	mov	si, ds:W_maskReg	;
	mov	si, ds:[si]		;
	add	si,ds:[W_clipPtr]	;point at clip line

	clr	ax			;start at left of screen
	jmp	short GLM_off

	; do ON run

GLM_loop:
	mov	bx,ax
	lodsw				;get lastON
	push	ax
	mov	dx, -1
	call	DoPartialMask
	pop	ax
	inc	ax			;ax = first OFF pixel

	; do OFF run

GLM_off:
	mov	bx,ax			;bx = left
	lodsw				;get firstON
	push	ax
	cmp	ax, EOREGREC
	jnz	GLM_1
	mov	ax,bp
GLM_1:
	dec	ax			;ax = last off point
	cmp	bx,ax
	jg	GLM_same
	clr	dx
	call	DoPartialMask
GLM_same:
	pop	ax
	cmp	ax, EOREGREC
	jnz	GLM_loop
	pop	bp
	ret

WinGenLineMask	endp




COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoPartialMask

DESCRIPTION:	Fill a part of lineMaskBuffer

CALLED BY:	INTERNAL
		WinGenLineMask

PASS:
	ax - right pixel to fill
	bx - left pixel to fill
	dx - mask to fill with
	es:di - buffer to fill

RETURN:
	none

DESTROYED:
	bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

-------------------------------------------------------------------------------@

DoPartialMask	proc	near
	push	ax
	push	bp
	mov	bp,di			;save buffer offset

	; calculate and push masks

	mov	di,ax			;calculate right mask
	and	di, 0x7
	clr	cx
	mov	cl, cs:[DPM_maskTable][di]
	test	ax, 8
	jz	pushRight
	xchg	ch, cl
	dec	cl
pushRight:
	push	cx

	; now do the same (almost) for the left side

	mov	di,bx			;calculate left mask
	and	di, 0x7
	clr	cx
	mov	cl, cs:[DPM_maskTable][di]
	shl	cl, 1
	test	bx, 8
	jz	pushLeft
	xchg	ch, cl
	dec	cl
pushLeft:
	not	cx
	push	cx

	; calculate byte indecies

	mov	cl,4
	shr	ax,cl
	shr	bx,cl
	mov	di,bx
	shl	di,1			;make word index
	add	di,bp
	sub	ax,bx
	mov	cx,ax			;cx = number of middle words
	jcxz	DPM_oneWord
	dec	cx

	; do left word

	pop	ax			;get mask
	mov	bx,ax
	and	bx,dx			;bx = mask AND data
	not	ax
	and	ax,es:[di]		;ax = NOT mask AND screen
	or	ax,bx
	stosw

	; do middle words

	mov	ax,dx
	rep stosw

	; do right word

	pop	ax			;get mask
DPM_lastWord:
	mov	bx,ax
	and	bx,dx			;bx = mask AND data
	not	ax
	and	ax,es:[di]		;ax = NOT mask AND screen
	or	ax,bx
	stosw

	mov	di,bp
	pop	bp
	pop	ax
	ret

	; one word word case

DPM_oneWord:
	pop	ax			;get full mask
	pop	bx
	and	ax,bx

	jmp	short DPM_lastWord

DoPartialMask	endp

;------------------------------------------------------------------------------
;		Mask tables
;------------------------------------------------------------------------------

if (0)
DPM_leftMasks	label	word
	byte	11111111b,11111111b
	byte	01111111b,11111111b
	byte	00111111b,11111111b
	byte	00011111b,11111111b
	byte	00001111b,11111111b
	byte	00000111b,11111111b
	byte	00000011b,11111111b
	byte	00000001b,11111111b
	byte	00000000b,11111111b
	byte	00000000b,01111111b
	byte	00000000b,00111111b
	byte	00000000b,00011111b
	byte	00000000b,00001111b
	byte	00000000b,00000111b
	byte	00000000b,00000011b
	byte	00000000b,00000001b

DPM_rightMasks	label	word
	byte	10000000b,00000000b
	byte	11000000b,00000000b
	byte	11100000b,00000000b
	byte	11110000b,00000000b
	byte	11111000b,00000000b
	byte	11111100b,00000000b
	byte	11111110b,00000000b
	byte	11111111b,00000000b
	byte	11111111b,10000000b
	byte	11111111b,11000000b
	byte	11111111b,11100000b
	byte	11111111b,11110000b
	byte	11111111b,11111000b
	byte	11111111b,11111100b
	byte	11111111b,11111110b
	byte	11111111b,11111111b
endif

DPM_maskTable	label	byte
	byte	10000000b
	byte	11000000b
	byte	11100000b
	byte	11110000b
	byte	11111000b
	byte	11111100b
	byte	11111110b
	byte	11111111b

;===============================

WinMovable segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinAddToInvalReg

DESCRIPTION:	Adds region into invalid region, sending Exposed event
		if new invalid area & no exposed event sent.  Also washes
		background color of window in exposed area.

CALLED BY:	INTERNAL

PASS:
	ds		- segment of PLock'ed window
	ds:W_visReg	- visible region of window
	ds:W_temp1Reg	- region to add into W_invalReg
				allowed to be WHOLE_REG

RETURN:
	ds		- new segment of window

DESTROYED:
	ax, bx, cx, dx, si, di
	W_temp3Reg is also destroyed. (your welcome jim).

	We use W_temp3Reg instead of W_temp2Reg because we may eventually
	call WinMaskOutSaveUnder which uses (destroys) W_temp2Reg.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
------------------------------------------------------------------------------@

WIN_MAX_INVAL_REG_SIZE	= 512
;
; This is the # of bytes an inval region is allowed to grow to until it set to
; WHOLE to keep the window block itself a reasonable size (& of course, to
; keep it from blowing up)	-- Doug 1/93
;
; NOTE:  figuring maximum 14 bytes per rectangle, a value of 512 here 
; allows some 36 rectangles at miniumum until the optimization is taken
; (which basically whites out the entire window)

WinAddToInvalReg	proc	far
EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>
	test	ds:[W_regFlags], mask WRF_CLOSED	; closed?
	LONG jnz	exit			; if so, do nothing

					; W_temp1Reg is new area to invalidate
	push	es
	segmov	es, ds			; put seg of window in es

	; Check to see if we are being called from WinInvalTree(Here) and need
	; to do WinWashOut even if the entire window is already invalidated.
	; (This is suppose to fix the problem with SysNotify coming up over
	; windows are already fully invalidated.  The SysNotify dialog wasn't
	; getting washed out. - Joon 6/16/93)

	test	ds:[W_regFlags], mask WRF_INVAL_TREE
	jnz	afterOpt

	mov	si, ds:[W_invalReg]	; inval region WHOLE already ?
	mov	di, ds:[si]		; dereference chunk handle
	cmp	{word} ds:[di], WHOLE_REG ; already maxed out ?
	je	invalWashDone		;  yes, nothing more to do.

afterOpt:
	mov	si, ds:[W_temp1Reg]
	mov	di, ds:[si]		; ds = es
	cmp	ds:[di], WHOLE_REG	; OR'ing in WHOLE?
	LONG je	invalWhole		; yes, do it (can deal w/temp1 = WHOLE)

	; Check to see if W_invalReg is already too big.   If it is, just
	; change temp1 to WHOLE & go from there.

	mov	si, ds:[W_invalReg]	; ds = es
	mov	di, ds:[si]		; ds = es
	ChunkSizePtr	ds, di, ax
	cmp	ax, WIN_MAX_INVAL_REG_SIZE
	ja	invalWhole

	; Trim passed region down to visible bounds

			; w:W_temp3Reg = w:W_temp1Reg AND w:W_visReg;
	mov	bx, ds:[W_temp1Reg]
	mov	si, ds:[W_visReg]
	mov	di, ds:[W_temp3Reg]
	call	FarWinANDLocReg
	mov	si, ds:[W_temp3Reg]	; ds = es
	mov	di, ds:[si]		; ds = es
	cmp	{word} ds:[di], EOREGREC	; is region to inval NULL?
	je	done			; if so, nothing else to do

	; CALC new W_invalReg

	mov	si, ds:[W_invalReg]	; ds = es
	mov	di, ds:[si]		; ds = es
	cmp	{word} ds:[di], EOREGREC	; is InvalReg NULL?
	je	invalNull

			; w:W_temp1Reg = w:W_temp3Reg OR w:W_invalReg;
	mov	bx, ds:[W_temp3Reg]
	mov	di, ds:[W_temp1Reg]	; ds = es
	call	FarWinORLocReg

EC <	mov	ax, NULL_SEGMENT	; Indicate done with es	>
EC <	mov	es, ax							>
			; w:W_invalReg = w:W_temp1Reg
	call	SwapInvalTemp1 

	; Wash out area being invalidated, in Temp3

	call	SwapInvalTemp3		; Get Temp3 into "Inval" for WinWashOut
	call	WinWashOut		; wash it out
					; es unknown at this point
	call	SwapInvalTemp3

invalWashDone:
EC <	mov	ax, NULL_SEGMENT	; Indicate done with es	>
EC <	mov	es, ax							>

	call	WinSendExpEvent		; Send exposure event, if needed
					; es unknown at this point
	andnf	ds:[W_grFlags], not (mask WGF_MASK_VALID)

done:
	segmov	es, ds			; Need es = seg of window
	mov	di, ds:[W_temp1Reg]	; Don't need W_temp1Reg anymore
	call	FarWinSMALLReg
	mov	di, ds:[W_temp3Reg]	; Don't need W_temp3Reg anymore
	call	FarWinSMALLReg
	pop	es
exit:
	ret



invalNull:
	call	SwapInvalTemp3		; Set Inval region to passed reg
	jmp	short washInvalThenDone

invalWhole:
	mov	di, ds:[W_invalReg]
	call	FarWinWHOLEReg		; Set Inval region to WHOLE
washInvalThenDone:
	call	WinWashOut		; & wash it all out
					; es unknown at this point
	jmp	short invalWashDone


WinAddToInvalReg	endp

;
;---------
;

SwapInvalTemp1	proc	near
	mov	ax, ds:[W_temp1Reg]
	xchg	ds:[W_invalReg], ax
	mov	ds:[W_temp1Reg], ax
	ret
SwapInvalTemp1	endp

SwapInvalTemp3	proc	near
	mov	ax, ds:[W_temp3Reg]
	xchg	ds:[W_invalReg], ax
	mov	ds:[W_temp3Reg], ax
	ret
SwapInvalTemp3	endp

WinMovable ends
