COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Windowing System
FILE:		Win/winCreDest.asm

AUTHOR:		Jim DeFrisco, Doug Fults

ROUTINES:
	Name		Description
	----		-----------
GLB	WinOpen		allocate and initialize a window for an application
GLB	WinClose	deallocate a Window structure
GLB	WinDecRefCount	decrement window reference count (Called on completion
			of MSG_META_WIN_FLUSH_QUEUE by default MetaClass
			handler on completion of flush)



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jad	6/88		Initial version
	doug	10/12/88	Changed files to win*, broke out into smaller
					files
	chris	11/22/88	Doesn't set to system font when created
	doug	2/1/89		Save Under added to window system
	john	 9-Aug-89	Documentation fixups.



DESCRIPTION:
	This file contains all library functions of the PC GEOS Window Manager.


	$Id: winCreDest.asm,v 1.1 97/04/05 01:16:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinMovable segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinOpen

DESCRIPTION:	Allocate and initialize a Window structure and optionally an
		associated graphics state.  Open the window on the screen

CALLED BY:	GLOBAL

PASS:	al - color index or red value for setting RGB
	ah - WinColorFlags:
		mask WCF_TRANSPARENT set if no background color
		mask WCF_PLAIN set if the window need not be sent
			MSG_META_EXPOSED, because it only needs to be washed
			with the background color to be fully drawn.
		mask WCF_RGB set if using RGB colors.
		Low bits, mask WCF_MAP_MODE, should be set to the
			color map mode to be used.
	bl - green value (valid only if using RGB)
	bh - blue value (valid only if using RGB)

	^lcx:dx - "InputObj" -- object responsible for handling mouse input
		for this window.
		NOTE:  Any non-NULL InputOD passed must be run by the same
		thread as geode-which-will-own-this-window's input object.
		(The input object is almost always the geode's GenApplication
		object, though could possibly be something else if the geode
		needs to be able to receive input but doesn't have a 
		GenApplication object)  This restriction is necessary not
		because of a kernel requirement, but because GenApplication
		expects to be able to call any InputOD of a window that it
		has received input for.
	^ldi:bp - "ExposureObj"  -- object to handle MSG_EXPOSED for this win.
		NOTE:  Is generally the same as the InputOD object, though
		could also be the application process, or in some cases an
		object run by a different thread than the InputOD (such as
		is the case w/GenView/Content pairs, in which the GenView
		is the InputOD, & the Content is the ExposureOD)

	si - flags:	(WinPassFlags, defined in win.def).
	    mask WPF_CREATE_GSTATE:
		Set to create graphics state also.
	    mask WPF_ROOT:
		Set to create root window.
	    mask WPF_SAVE_UNDER:
		Set for save under.
		NOTE:  Only supports rectangular windows.
	    mask WPF_INIT_EXCLUDED.
		Initialize to be the head of a branch which is excluded from
		Being the implied window.  No MSG_META_UNIV_ENTER's or
		MSG_META_VIS_ENTER's will be sent to the window. (Don't set this
		unless you know what you're doing :)
	    mask WPF_PLACE_BEHIND:
		Set to place window in back of other windows in the same
		priority group or clear to place window in front of other
		windows in the same priority group.
	    mask WPF_PLACE_LAYER_BEHIND:
		Set to place layer behind other layers, if window is first
		within layer.
	    mask WPF_INIT_SUSPENDED:
		Set if window should be created in the UpdateSuspended mode;
		no MSG_META_EXPOSED will be generated until WinUnSuspendUpdate
		is called.
	    WPF_PRIORITY: (bits 0-7)
		Priority for window (or 0 for standard priority).
	    All other bits are reserved and MUST be zero.

	On stack (pushed in this order):
	    word - Layer ID
	    word - geode which should own this window (0 if current running)
	    word - handle of window to be this window's parent or handle of
		   video driver
	    word - high word for region.	(0 for rectangular)
	    word - low word for region		(0 for rectangular)
	    word - DX_PARAM to region.		(bottom if rectangular)
	    word - CX_PARAM to region.		(right  if rectangular)
	    word - BX_PARAM to region.		(top    if rectangular)
	    word - AX_PARAM to region.		(left   if rectangular)

	    The region/rectangle passed is in screen pixels to offset
	    from the parent window.  Remember, if passing a rectangle as a
	    region, you're passing offset pixel values for the right and
	    bottom, not document coord values.  The width of your rectangle
	    should be (right - left + 1) if your parameters are correct.
	    Ditto the height.

RETURN: bx - handle to allocated and opened window
	di - handle to allocated and opened graphics state (if any)

DESTROYED:
	ax, cx, dx, si, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Allocate window
	Lock parent of window;
	Search sibling chain for new desired priority location;
	Add window into position in chain;
	Set wChangeBounds to bound(W_winReg);
	Start at current window, call WinTValidateHere;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version
	John	 9-Aug-89	Added some documentation
	Doug	4/91		Clarified coordinate doc

------------------------------------------------------------------------------@


if	TEST_WIN_SPEED
winOpenStart	word	0
winOpenEnd	word	0
endif

WinOpen	proc	far 	regParam:Rectangle, region:fptr.Region, parent:hptr,
			owner:hptr, layerID:hptr
saveFlags	local	WinPassFlags
winColorFlags	local	WinColorFlags	; Must be in this order!
winColorIndex	local	byte		;  (assigned reverse indices by Esp)
	.enter

ForceRef winColorFlags	; Only accessed with word access of winColorIndex...

if	TEST_WIN_SPEED
	push	ax, bx
	call	TimerGetCount			;bx.ax = count
	mov	cs:[winOpenStart], ax
	pop	ax, bx
endif

if	ERROR_CHECK
	push	ax, bx, cx, dx, bp, si, di

	test	si, not WinPassFlags
	ERROR_NZ	WIN_OPEN_BAD_FLAGS

	tst	cx
	jz	afterInputObjCheck
	mov	bx, cx
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo		; ax = exec thread of InputOD
	mov	di, ax			; save in di
	mov	bx, owner
	call	WinGeodeGetInputObj
	tst	cx
	jz	afterInputObjCheck
	mov	bx, cx
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo		; ax = exec thread of InputOD
	cmp	ax, di
	ERROR_NE	WIN_INPUT_OBJ_MUST_BE_RUN_BY_SAME_THREAD_AS_GEODE_INPUT_OBJ
afterInputObjCheck:

	pop	ax, bx, cx, dx, bp, si, di
endif

	push	ds
	push	es

	; Save some parameters

	mov	ss:[saveFlags],si
	mov	{word}ss:[winColorIndex],ax

	; allocate window

	mov	ax,ss:[owner]		; get owner for window block

	push	bp
	mov	bp,ss:[bp]
	push	bx, cx, dx
	call	AllocateWindow		; returns locked window in ds
	mov	ax,bx			; window handle
	pop	bx, cx, dx
	pop	bp

	push	di			; save GState handle
	push	ax			; save window handle


	; get tree semaphore and P window

	call	FarPWinTree		; Have to have tree first. es <- idata

					; NOTE: don't need to get driver sem
					; yet, since we're the only one with
					; this block.

	; Initialize some window state
	mov	ax, ss:[layerID]	; Store away the layer ID to use
	mov	ds:[W_layerID], ax

	mov	{word}ds:[W_grFlags], 0

	mov	ax,{word}ss:[winColorIndex];get color and flags
	mov	ds:[W_color], ah		; store into Window structure
	mov	ds:[W_colorRGB].RGB_red, al	; store red color
	mov	ds:[W_colorRGB].RGB_green, bl	; store green color
	mov	ds:[W_colorRGB].RGB_blue, bh	; store blue color


	movdw	ds:[W_inputObj], cxdx

				; NULL visible, invalid & update
				;	regions, since validation
				;	code uses previous results
	segmov	es, ds		; es <- window for WinNULLReg
	mov	di, ds:[W_visReg]
	call	FarWinNULLReg		; init W_visReg to NULL
	mov	di, ds:[W_invalReg]
	call	FarWinNULLReg		; init W_invalReg to NULL
	mov	di, ds:[W_updateReg]
	call	FarWinNULLReg		; init W_updateReg to NULL
	mov	di, ds:[W_pathReg]
	call	FarWinNULLReg		; init W_pathReg to NULL
	mov	di, ds:[W_winPathReg]
	call	FarWinNULLReg		; init W_winPathReg to NULL

	; ds = es (since WinNULLReg fixes it up), but SetupWinReg doesn't
	; fixup es if ds moves, so load es with idata since WO_root requires
	; it.

	LoadVarSeg	es

	; Set window region
	mov	dx,ss
	lea	cx,ss:[regParam]

	push	bp
	mov	di,ss:[region].offset
	mov	bp,ss:[region].segment
	call	SetupWinReg		; Set W_winReg from passed args
	pop	bp			;	based on passed arguments

	; Init window regions

	; test for opening root window

	mov	bx,ss:[parent]		;bx = parent
	mov	si,ds:[LMBH_handle]	;si = new window
	mov	cx,ss:[saveFlags]	; Get priority for window
	test	cx,mask WPF_ROOT
	jz	WO_notRoot

;WO_root:

	; root window -- get device strategy from driver
	; es = idata

	call	MemLock
	mov	es, ax				; es <- driver core block
	mov	bx,es:[GH_driverTabOff]			;bx = offset
	push	es:[GH_driverTabSegment]		;es = segment
	push	bx
	mov	bx, es:[GH_geodeHandle]
	call	MemUnlock
	pop	bx
	pop	es

	mov	ax, es:[bx][DIS_strategy].offset
	mov	ds:[W_driverStrategy].offset,ax
	mov	ax, es:[bx][DIS_strategy].segment
	mov	ds:[W_driverStrategy].segment,ax
	mov	di, NULL_WINDOW
	mov	ds:[W_parent],di
	mov	es,di			; Pass NULL parent
	call	WinCalcWinBounds	; Generate wWinBounds, leave in
					;	registers
	call	SetChangeBounds	; Set changing bounds to this
				; NULL visible, invalid & update
				;	regions, since validation
				;	code uses previous results
	clr	ax
	jmp	WO_doValidate


WO_notRoot:
					; Lock Parent window, so nobody else
					;	plays with it.
	; not root window -- insert in tree

	mov	si,ds:[W_header.LMBH_handle]
	mov	di,bx
EC <	call	ECCheckLMemHandle					>
	call	MemPLock
	mov	es, ax		; lock window (or GState)
	cmp	es:[LMBH_lmemType],LMEM_TYPE_WINDOW	;window ?
	jz	WO_10
EC <	call	ECCheckGStateHandle					>

	mov	di,es:[GS_window]	;get window from GState
	call	WinUnlockV		;release GState
	mov	bx,di
	call	MemPLock
	mov	es, ax			;lock window

WO_10:
EC <	call	ECCheckWindowHandle					>
	mov	ds:[W_parent], bx; store handle to parent, in case

	mov	ax, es:[W_driverStrategy].offset
	mov	ds:[W_driverStrategy].offset,ax
	mov	ax, es:[W_driverStrategy].segment
	mov	ds:[W_driverStrategy].segment,ax

				; See if requesting save under
	test	cx, mask WPF_SAVE_UNDER
	jz	WO_20		; skip if not
	push	cx
	call	WinRequestUnder		; Pass width & height, requesting save
					;	under.  NUKE any SaveUnders
					;	necessary in process.
	pop	cx
WO_20:

	mov	ax, ds:[LMBH_handle]	; only inserting one window, this one.
	call	WinTInsert	; Insert window at appropriate place
				; Set change bounds to window region
				;	root
				; Offset window from parent window

				; Get parent's offset
	push	si
	mov	cx, es:[W_winRect.R_left]	; Window org to offset to
	mov	dx, es:[W_winRect.R_top]

	mov	si, ds:[W_winReg]	; point to region
	mov	si, ds:[si]
	call	GrMoveReg		; Move the region to be offset
					;	from parent
	call	WinCalcWinBounds	; Generate wWinBounds, leave in
					;	registers
	; initialize the dither offsets, so when we dither the patterns are
	; rotated correctly.

	mov	ds:[W_ditherX], ax	; store full words for complex dithers
	mov	ds:[W_ditherY], bx
	mov	si, ax			; save a register
	mov	ah, bl			; pack in left and top in 1 word
	and	ax, 0x707		; only interested in low three bits
	mov	ds:[W_pattPos], ax	; initialize pattern position before
	mov	ax, si			; restore left side position

	pop	si
	call	SetChangeBounds		; Set changing bounds to this

					; Opening a window underneath any window
					; which has save-under active for it
					; wipes out the validity of that save-
					; under are.  Therefore, clear any
					; such save-under areas.
	call	WinGetOverlyingSaveUnders
	call	WinClearSaveUnders	; Clear them out.

				; See if requesting save under
	test	ss:[saveFlags], mask WPF_SAVE_UNDER
	jz	WO_50		; skip if not
				; Request save-under for window
	push	di
	mov	ax, 0x8000			; Use window bounds
	mov	di, DR_VID_SAVE_UNDER		; Try to save under
	call	WinCallVidDriver		; call the video driver
	pop	di
	jc	WO_30			; if not granted, OK, live with it
	mov	ds:[W_saveUnder], al	; if granted, store save-under mask
					;	here
WO_30:
	cmp	ds:[W_saveUnder], 0	; save under generated?
	je	WO_50			; branch if not

					; Validate open, setting save flags
					;	for windows affected
	mov	ax, WIN_V_PASSED_LAST OR WIN_OPEN_SAVE_UNDER
	jmp	short WO_60

WO_50:
					; If there are any save-unders in the
					; area of our parent window, remove
					; those save-under areas & punch
					; through a hole in all underlying
					; windows.
	call	WinClearSaveUndersOverlappingParent

	mov	ax, WIN_V_PASSED_LAST
WO_60:

WO_doValidate:


if      (WIN_ENTER_LEAVE_CONTROL)
					; See if we should init to be excluded
	test	ss:[saveFlags],mask WPF_INIT_EXCLUDED
	jz	WO_NotExcluded		; skip if not
					; otherwise, set flag to show excluded
	ornf	ds:[W_ptrFlags], mask WPF_WIN_BRANCH_EXCLUDED
WO_NotExcluded:
endif

					; See if we should init to be suspended
	test	ss:[saveFlags],mask WPF_INIT_SUSPENDED
	jz	WO_NotSuspended
					; otherwise, inc suspend count
	inc	ds:[W_suspendCount]
WO_NotSuspended:

	call	WinTValidateOpen	; NEW, faster version

	pop	bx		;window handle
	pop	di		;graphics state handle

	call	FarVWinTree
	clc			; no error

	pop	es
	pop	ds

if	TEST_WIN_SPEED
	push	ax, bx
	call	TimerGetCount			;bx.ax = count
	mov	cs:[winOpenEnd], ax
	pop	ax, bx
endif

	.leave
	ret	@ArgSize
WinOpen	endp





COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinRequestUnder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Requests save under for window passed, via video driver.
		If driver returns a save under to be nuked, we validate
		the tree for that window, removing save-under flags, &
		call driver to nuke the save under area.

CALLED BY:	WinOpen

PASS:	si	- handle of window being opened (not yet inserted in tree)
	di	- handle of parent of window being opened
	ds	- segment of window block (locked & P'd)
	es	- segment of parent window block (locked & P'd)

RETURN:		si, di	- unchanged
		ds	- new segment of window block
		es	- new segment of parent block

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinRequestUnder	proc	near
	push	si
	push	di
					; REQUEST SAVE UNDER SPACE
	call	WinCalcWinBounds		; get bounds before insert
						;	into tree
	mov	ax, ds:[W_winRect.R_right]
	sub	ax, ds:[W_winRect.R_left]		; get difference
	inc	ax				; get width
	mov	bx, ds:[W_winRect.R_bottom]
	sub	bx, ds:[W_winRect.R_top]		; get difference
	inc	bx				; get height
	push	di
	mov	di, DR_VID_REQUEST_UNDER	; do request under operation
	call	WinCallVidDriver
	pop	di
	jnc	WRU_90				; if no carry, done

					; OTHERWISE, have to Nuke a save under.
					; HandleMem of window is in bx
	push	si
	push	di
	push	ds
					; First, Unlock parent window
	push	bx
	mov	bx, di
	call	WinUnlockV		; release parent window
	pop	bx

	call	WinLockWinAndParent	; setup si, di, ds & es for window to
					;	clear save under for
	mov	ax, WIN_V_PASSED_LAST OR WIN_CLEAR_SAVE_UNDER
	call	WinTValidateOpen

	pop	ds
	pop	di
	pop	si
					; re-lock parent window
	mov	bx, di
	call	MemPLock
	mov	es, ax

WRU_90:
	pop	di
	pop	si
	ret
WinRequestUnder	endp





COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocateWindow

DESCRIPTION:	Allocate and initialize a window

CALLED BY:	WinOpen

PASS:
	ax - Process to own block (or 0 for current running)
	si - flags:	(WinPassFlags, defined in win.def).
	    mask WPF_CREATE_GSTATE:
		Set to create graphics state also.
	    mask WPF_ROOT:
		Set to create root window.
	    mask WPF_SAVE_UNDER:
		Set for save under.
	    mask WPF_PLACE_BEHIND:
		Set to place window in back of other windows in the same
		priority group or clear to place window in front of other
		windows in the same priority group.
	    mask WPF_PLACE_LAYER_BEHIND:
		Set to place layer in back of other layers, if window
		is first within layer.
	    WPF_PRIORITY: (bits 0-7)
		Priority for window (or 0 for standard priority).
	    All other bits are reserved and MUST be zero.

	<di>,<bp> - output descriptor

RETURN:
	bx - handle to allocated and opened window (locked and owned)
	di - handle to allocated and opened graphics state (if any) (unlocked)
	ds - locked window segment
DESTROYED:
	ax, bx, cx, dx, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

AllocateWindow	proc	near

	push	ax				; save owner for block
	; Allocate window on heap

	mov	ax, size Window + WINDOW_FREE_SPACE + 16
						; Get default window size
	mov	cx, ALLOC_WINDOW		; non-swap, non-discard, lock
						; zero-init
	call	MemAllocFar			; allocate mem for reg buffers
	call	HandleP
	mov	ds, ax
	pop	ax				; retrieve owner for block

					; SET NEW OWNER FOR WINDOW BLOCK
	tst	ax
	jz	AW_ownerOK			; if 0, leave as is.
EC <	xchg	ax, bx						>
EC <	call	ECCheckGeodeHandle				>
EC <	xchg	ax, bx						>
	LoadVarSeg	es			; Get idata seg in es
	mov	es:[bx][HM_owner], ax		; store new owner for block
AW_ownerOK:

					; INIT LITTLE HEAP
	mov	dx, size Window			; Where to start heap
						; general heap type
	mov	ax, LMEM_TYPE_WINDOW
	mov	cx, WIN_NUM_HANDLES + 1		; no. of handles + W_temp3Reg
	push	si, di
	mov	si, WINDOW_FREE_SPACE		; number of bytes.
	clr	di
	call	LMemInitHeap			; Initialize heap for window's
						;	regions
	pop	si, di
	mov	ds:[W_exposureObj.chunk],bp
	mov	ds:[W_exposureObj.segment],di
					; CREATE HANDLES FOR VARIOUS REGIONS
					;	WE'LL USE
	segmov	es, ds
	mov	di, offset WIN_FIRST_HANDLE	; Offset to first region handle
	mov	cx, size RectRegion		; Init size of all chunks to
						; the size of a rectangle.
						; Will be shrunk later if not
						;	used.
AW_lmemLoop:
	call	LMemAlloc			; create a "chunk"
	stosw					; store handle
	cmp	di, offset WIN_LAST_HANDLE + 2	; see if done
	jb	AW_lmemLoop				; as many as we want

	call	LMemAlloc			; alloc a chunk for W_temp3Reg
	mov	es:[W_temp3Reg], ax		; W_temp3Reg is separate from
						;  other window regions

if NULL_WINDOW ne 0
	mov	ax, NULL_WINDOW			; NIL
	mov	ds:[W_prevSibling], ax		; no siblings
	mov	ds:[W_nextSibling], ax
	mov	ds:[W_firstChild], ax		; no children
	mov	ds:[W_lastChild], ax
endif

	; init the scale factors for the window transformation matrix

	mov	ds:[W_TMatrix].TM_11.WWF_int, 1
	mov	ds:[W_TMatrix].TM_22.WWF_int, 1

	mov	ax, si
	test	al, mask WPD_LAYER
	jnz	haveLayerPrio
	or	al, LAYER_PRIO_STD shl offset WPD_LAYER
haveLayerPrio:
	test	al, mask WPD_WIN
	jnz	haveWinPrio
	or	al, WIN_PRIO_STD shl offset WPD_WIN
haveWinPrio:
	mov	ds:[W_priority], al	; init to default priority

	inc	ds:[W_refCount]		; increment ref count, waiting on
					; WinClose of the window

					; ALLOCATE GRAPHICS STATE IF NEEDED
	test	si,mask WPF_CREATE_GSTATE
	jz	AW_done
	mov	di,bx
	call	GrCreateState			; Create a graphics state

AW_done:
	ret

AllocateWindow	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	WinClose

DESCRIPTION:	Close a window on the screen and de-allocate it

CALLED BY:	GLOBAL

PASS:		di - handle or graphics state OR handle of window to close

RETURN:		none

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

-------------------------------------------------------------------------------@

WinClose	proc	far
	call	PushAllFar
;
; NOTE: Do not call ECCheckWindowHandle as di may be either a window or
; a gstate. We test only that the thing's a valid local memory handle. The
; checking of the type comes later.
;
EC <	xchg	bx, di							>
EC <	call	ECCheckLMemHandle					>
EC <	xchg	bx, di							>

	mov	bx,di
	call	WinPLockDS		; lock graphics state/window
	cmp	ds:[LMBH_lmemType],LMEM_TYPE_WINDOW	; window ?
	jz	WC_window		; branch if window
EC <	call	ECCheckGStateHandle					>

	; graphics state passed -- destroy it

	push	ds:[GS_window]		;save window to destroy
	call	GrDestroyState		;destroy graphics state
	pop	bx
	jmp	short WC_doClose

WC_window:
EC <	call	ECCheckWindowHandle					>
	call	WinUnlockV		;unlock it again

WC_doClose:
	call	FarPWinTree		; es <- idata

	call	WinLockWinAndParent	; lock window & parent
			; set wChangeBounds to be W_winReg
	call	LoadWinSetChangeBounds	; get bounds of window, from variables


	mov	bx, si			; Pass handle of window in bx
	call	WinChangePtrNotification; let ptr mechanism know that
					; window is closing.

	push	si
	cmp	ds:[W_saveUnder], 0	; save under on?
					; If not, just branch to clear any 
					; overlapping save under areas.
	jz	JustClearAffectedSaveUnders

; If we are underneath any save-under windows, we'll have to clear them,
; first, then RESTORE our own save-under.
;
;
	call	WinGetOverlyingSaveUnders
	mov	ah, ds:[W_saveUnder]
	not	ah
	and	al, ah			; Let's not clear our own save under
					; just yet.
	call	WinClearSaveUnders	; Clear them out.

	; RESTORE the save under area, DON'T wash the window, & DON'T clear any
	; more save under areas.
	push	si
	push	di
	call	SwapUnivMaskReg		; Swap Univ & Mask reg for a moment,
					; so that RESTORE_UNDER will use
					; Univ reg to blit through.
	call	SetupMaskFlags		; Adjust mask flags to represent
					; W_maskReg
	mov	di, DR_VID_RESTORE_UNDER; Call driver to recover
	call	WinCallVidDriver
	call	SwapUnivMaskReg		; Restore Univ & Mask regions
	pop	di
	pop	si
						; Unmark windows w/save under.
						; Don't have to validate them.
	mov	ax, WIN_SKIP_PASSED OR WIN_CLOSE_SAVE_UNDER
	jmp	short Validate

JustClearAffectedSaveUnders:
NEC <	;An optimization, placed in non-EC only for space reasons	>
NEC <	mov	bx, ds:[W_univReg]	; Test to see if window at all visible>
NEC <	mov	bx, ds:[bx]						>
NEC <	cmp	{word} ds:[bx], EOREGREC	; NULL?			>
NEC <	je	AfterCloseWash			; if so, skip save under>
						; inval, washing	>

					; Clear any save unders overlapping
					; the bounds of our parent window
					; (INCLUDING this window's, if it has
					; one, & this code is allowed to be
					; executed...)
					; (BEFORE the wash, please..)
	call	WinClearSaveUndersOverlappingParent

	test	ds:[W_color], mask WCF_TRANSPARENT
	jnz	AfterCloseWash
	push	si
	push	di
	push	es
	call	SwapUnivInvalReg	; Swap Univ & Inval reg for a moment
	call	WashOutInval		; wash out window w/back color
	call	SwapUnivInvalReg	; Swap Univ & Inval reg for a moment
	pop	es
	pop	di
	pop	si
AfterCloseWash:

	mov	ax, WIN_SKIP_PASSED

Validate:
					; ax = validate mode

	cmp	di, NULL_WINDOW		; Anything to unlink from (do we
					;  have a parent)?
	je	WC_noRemove
	push	ax			; Save validate mode
	mov	ax, ds:[LMBH_handle]	; just remove one window
	call	WinTRemove	; Remove window from list
	pop	ax			; Restore validate mode

WC_noRemove:

	mov	bx, ds:[W_univReg]	; Test to see if window at all visible
	mov	bx, ds:[bx]
	cmp	{word} ds:[bx], EOREGREC	; NULL?
	pushf

	push	ax			; Save flags
	push	si
	push	di

	; NOW, make sure that any drawing done will not screw up anything, 
	; & also that the ptr, if in the window, will discover that it is
	; no longer possibly in this window.

	push	es
	segmov	es, ds
	mov	di, ds:[W_univReg]
	call	FarWinNULLReg		; Null-out vis region.
	mov	di, es:[W_visReg]
	call	FarWinNULLReg		; Null-out vis region.
	mov	di, es:[W_maskReg]
	call	FarWinNULLReg		; Null-out mask region.
	segmov	ds, es
	pop	es
	andnf	ds:[W_grRegFlags], not (mask WGRF_PATH_VALID or \
					mask WGRF_WIN_PATH_VALID)
	call	SetupMaskFlags		; Adjust mask flags to represent
					; W_maskReg

					; Mark window as CLOSED.
	or	ds:[W_regFlags], mask WRF_CLOSED

	; Make sure all relavent queues are flushed before this window is
	; actually nuked.  Clear out W_exposureObj at this time as well, as
	; there is nothing further to be sent to it.  (W_inputObj, on the
	; other hand, may be needed to deliver the last LEAVE events still
	; in the queue, which will be flushed out)
	;
	mov	bx, ds:[W_inputObj].handle
	mov	si, ds:[W_inputObj].chunk
	call	WinFlushQueue
	clr	cx
	clr	dx
	xchg	cx, ds:[W_exposureObj].handle
	xchg	dx, ds:[W_exposureObj].chunk
	cmp	cx, bx
	jne	notSame
	cmp	dx, si
	je	checkNull
notSame:
	xchg	bx, cx
	xchg	si, dx
	call	WinFlushQueue
afterExposureObjFlushed:

	pop	di
	pop	si
	pop	ax			; get flags to pass to WinTValidateHere

	popf				; Get flag for wether universe is NULL
	jne	doValidate		; if not, do full validation
	call	WinUnlockVBoth		; Otherwise, just unlock windows
	jmp	afterValidate

doValidate:
	call	WinTValidateHere	; Validate window tree, now that this
					; window is gone.
afterValidate:

	call	FarVWinTree		; es <- idata

	pop	di			; Get window handle
	call	WinDecRefCount		; Acknowledge death for WinClose.
					; If all death acknowledges have come
					; in, destroy window

	call	PopAllFar
	ret

checkNull:

	or	cx, dx
	jnz	afterExposureObjFlushed
	;
	; Both ODs were null, which means no flushing of any sort went on.
	; Flush to the owner of the window instead, to make sure the exit
	; of the window is synchronized in some fashion.
	; 
	mov	bx, ds:[LMBH_handle]
	call	MemOwnerFar
	mov	ax, GGIT_ATTRIBUTES
	call	GeodeGetInfo
	test	ax, mask GA_PROCESS
	jz	flushToSysInput		; => owner won't be able to receive
					;  the message, so use the system
					;  input administrator object.
	cmp	bx, handle 0
	je	flushToSysInput		; => the kernel, which claims to be
					;  a process, but its first thread
					;  isn't actually event-driven...

	clr	si
doSpecialFlush:
	call	WinFlushQueue
	jmp	afterExposureObjFlushed

flushToSysInput:
	push	ds
	LoadVarSeg	ds
	movdw	bxsi, ds:[wPtrOutputOD]
	pop	ds
	tst	bx
	jnz	doSpecialFlush
	jmp	afterExposureObjFlushed	; no one can possibly care, so we can
					;  nuke the window now...
WinClose	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinFlushQueue

DESCRIPTION:	Inc the refCount for current window, then start a
		queue-flushing sequence for the object passed, at the
		end of which dec the refCunt for the window.   Uses
		MSG_META_OBJ_FLUSH_INPUT_QUEUE to accomplish this.

CALLED BY:	INTERNAL
		WinClose, WinSetInfo

PASS:		ds	- locked segment of window
		^lbx:si	- object whose input queue must be flushed before this
			  this window can be destroyed.  (Or zero, to do
			  nothing)

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/92		Initial version
------------------------------------------------------------------------------@

WinFlushQueue	proc	far
	tst	bx
	jz	done
	call	PushAllFar

EC <	call	ECCheckOD						>

EC <	; Make sure we don't try to treat a process like an obj block	>
EC <	;								>
EC <	push	es							>
EC <	LoadVarSeg	es						>
EC <	mov	al, es:[bx].HG_type					>
EC <	cmp	bx, es:[bx].HM_owner	;a process owns itself		>
EC <	pop	es							>
EC <	je	afterTest						>
EC <	cmp	al, SIG_QUEUE						>
EC <	je	afterTest						>
EC <	cmp	al, SIG_THREAD						>
EC <	je	afterTest						>
EC <	;								>
EC <	; Make sure we're not about to send a message to an object	>
EC <	; that's  not going to be around by the time the message is 	>
EC <	; actually sent to it.	(We can actually only make this check	>
EC < 	; if the block is run by the current thread, or we'll blow up	>
EC <	; trying to lock the block)					>
EC <	;								>
EC <	call	ObjTestIfObjBlockRunByCurThread				>
EC <	jne	afterTest						>
EC <	call	ECObjEnsureBlockNotDying				>
EC <afterTest:								>

	inc	ds:[W_refCount]		; increment death count

	; Prepare final message to be dispatched to passed object once its
	; input queues have been flushed
	;
	mov	ax, MSG_META_WIN_DEC_REF_COUNT
	mov	cx, ds:[LMBH_handle]	; Dec ref count on this window
	mov	di, mask MF_RECORD
	call	ObjMessage

	; Pass window handle to MSG_META_OBJ_FLUSH_INPUT_QUEUE
	; as reference point for flushing process queue.
	; (window is presumably owned by owner of destination 
	; object/thread). Adam says so.

	mov	dx,cx			; window handle
	mov	cx, di			; cx is now "dec ref count" event,
					; Next ObjFlushInputQueueNextStop
					; after input manager
	mov	bp, OFIQNS_SYSTEM_INPUT_OBJ
	call	ImInfoInputProcess	; Fetch bx = IM thread
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	call	ObjMessage

	call	PopAllFar
done:
	ret
WinFlushQueue	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinDecRefCount

DESCRIPTION:	HandleMem acknowledge of window death.  To be called by whoever
		recives a MSG_META_WIN_DEC_REF_COUNT.

CALLED BY:	GLOBAL

PASS:		di	- window handle

RETURN:		Nothing

DESTROYED:	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
------------------------------------------------------------------------------@

WinDecRefCount	proc	far
	call	PushAllFar
	call	FarPWinTree		; Needed for WinDeathPtrNotification
	call	FarWinLockFromDI	; Get window locked
	jc	exit			; exit if gstring
	mov	bx, di
	dec	ds:[W_refCount]		; decrement death count
	jnz	WDA_50			; if hasn't reached 0 yet, skip

;EC <	test	ds:[W_ptrFlags], mask WPF_PTR_IN_UNIV		>
;EC <	ERROR_NZ	WIN_MOUSE_PTR_IN_DEAD_WINDOW		>
					; If death count has reached 0,
					;	destroy window
					; BUT, first let ptr notification
					; system know that this handle is
					; being killed

	mov	di, ds:[W_parent]	; Pass di = parent window, bx = win
	call	WinDeathPtrNotification	; let ptr mechanism know that

	call	MemFree			; Free up memory block.  Window is
					; officially dead.
	jmp	exit			;

WDA_50:
	call	WinUnlockV		; else just release window
exit:

	call	FarVWinTree
	call	PopAllFar
	ret
WinDecRefCount	endp

WinMovable ends
