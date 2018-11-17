COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Win
FILE:		winState.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB WinSetInfo		Set some piece of window data
    GLB WinGetInfo		Get the private data from a GState
    GLB WinGetWinScreenBounds	Returns bounds of window, in screen
				coordinates.  Useful to determine window's
				current position & size.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

DESCRIPTION:
	This file contains routines to get and set window state.

	$Id: winState.asm,v 1.1 97/04/05 01:16:10 newdeal Exp $

------------------------------------------------------------------------------@

WinMisc segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinSetInfo

DESCRIPTION:	Set some piece of window data

CALLED BY:	GLOBAL

PASS:
	si - value in WinInfoType for type of info to set
		WIT_PRIVATE_DATA:
			ax, bx, cx, dx - private data

		WIT_COLOR:
			al - color index or red value for RGB
			ah - WCF_TRANSPARENT if none, WIN_RGB if RGB colors
			     low bits are color map mode
			bl - green value (for RGB)
			bh - blue value (for RGB)

		WIT_INPUT_OBJ:
			cx:dx	- new input OD

		WIT_EXPOSURE_OBJ:
			cx:dx	- new exposure OD

		WIT_STRATEGY:
			cx:dx	- new video driver strategy routine
				  this should probably never be executed....

	di - handle of window

RETURN:
	carry set if di is a gstate or a window that is closing

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Chris 	4/26/91		Changed to return carry
	
------------------------------------------------------------------------------@

WinSetInfo	proc	far
	push	di
	push	ds
	call	FarWinLockFromDI
	jc	exit				; exit if gstring
EC<	test	si, 01h		; ODD?			>
EC<	jnz	badWinInfoType				>
EC<	cmp	si, WinInfoType			>
EC<	ja	badWinInfoType				>

	push	di
	call	cs:[winSetInfoTable][si]
	pop	di

	push	bx
	mov	bx, di			; get window handle
	call	MemUnlockV
	pop	bx
	clc					; window did exist
exit:
	pop	ds
	pop	di
	ret

EC<badWinInfoType:					>
EC<	ERROR		WIN_BAD_WIN_INFO_TYPE		>

WinSetInfo	endp

;----------------------

winSetInfoTable	label	word
	word	WinSetPrivateData
	word	WinSetColor
	word	WinSetInputOD
	word	WinSetExposureOD
	word	WinSetStrategy
	word	WinSetDummy		; Can't set flags, just reserve slot
	word	WinSetDummy		; Can't set layer ID, reserve slot
	word	WinSetDummy		; Can't set window link, reserve slot
	word	WinSetDummy		; Can't set window link, reserve slot
	word	WinSetDummy		; Can't set window link, reserve slot
	word	WinSetDummy		; Can't set window link, reserve slot
	word	WinSetDummy		; Can't set window link, reserve slot
	word	WinSetDummy		; Can't set priority, reserve slot

WinSetPrivateData	proc	near
	mov	ds:[W_privData].WPD_ax,ax
	mov	ds:[W_privData].WPD_bx,bx
	mov	ds:[W_privData].WPD_cx,cx
	mov	ds:[W_privData].WPD_dx,dx
	ret
WinSetPrivateData	endp

WinSetColor	proc	near
	mov	ds:[W_color], ah		; store into Window structure
	mov	ds:[W_colorRGB].RGB_red, al	; store red color
	mov	ds:[W_colorRGB].RGB_green, bl	; store green color
	mov	ds:[W_colorRGB].RGB_blue, bh	; store blue color
	ret
WinSetColor	endp

WinSetInputOD	proc	near
	mov	di, offset W_inputObj
	jmp	CallSetOD
WinSetInputOD	endp

WinSetExposureOD	proc	near
	mov	di, offset W_exposureObj
CallSetOD	label	near
	call	WinSetOD
	ret
WinSetExposureOD	endp

WinSetStrategy	proc	near
	mov	ds:[W_driverStrategy].segment, cx
	mov	ds:[W_driverStrategy].offset, dx
	REAL_FALL_THRU	WinSetDummy
WinSetStrategy	endp

WinSetDummy	proc	near
	ret
WinSetDummy	endp




WinSetOD	proc	near	uses bx, si
	.enter
	mov	bx, ds:[di].handle	; get OLD input/exposure OD
	mov	si, ds:[di].chunk
	cmp	bx, cx			; see if any different from new
	jne	changeOfOD
	cmp	si, dx
	je	done			; if no change, done
changeOfOD:


	; BEFORE setting new OD, flush the queues, using the OLD OD values.
	; this will make sure that any references they have of this window
	; will be cleared out before the window is allowed to die.
	;
	call	WinFlushQueue

	mov	ds:[di].handle, cx	; store NEW OD
	mov	ds:[di].chunk, dx
done:
	.leave
	ret
WinSetOD	endp

WinMisc ends

WinMovable segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WinGetInfo

DESCRIPTION:	Get the private data from a GState

CALLED BY:	GLOBAL

PASS:
	di - handle of graphics state or window
	si - value in WinInfoType for type of info to get

RETURN:
	for si =
		WIT_PRIVATE_DATA:
			ax, bx, cx, dx - private data
		WIT_COLOR:
			al - color index or red value for RGB
			ah - WCF_TRANSPARENT if none, WIN_RGB if RGB colors
			     low bits are color map mode
			bl - blue value (for RGB)
			bh - green value (for RGB)

		WIT_INPUT_OBJ:
			cx:dx	- input OD

		WIT_EXPOSURE_OBJ:
			cx:dx	- exposure OD

		WIT_STRATEGY:
			cx:dx	- strategy routine

		WIT_FLAGS:	(READ ONLY)
			al -	WinRegFlags.  Bits that may be inspected are:

				mask WRF_EXPOSE_PENDING - set if MSG_META_EXPOSED
					has been sent out, & neither
					GrBeginUpdate nor WinAckUpdate have
					been called yet.

			ah -	WinPtrFlags.  Bits that may be inspected are:
				mask WPF_WIN_GRABBED - set if Window has grabbed
						       mouse input
				mask WPF_WIN_BRANCH_EXCLUDED - set if window
							is excluded from mouse
							input
				mask WPF_PTR_IN_UNIV  - set if ptr is in univ
							of window (RAW), NOT
							synchronous w/UI thread
				mask WPF_PTR_IN_VIS   - set if ptr is in vis
							reg of window (RAW),
							NOT synchronous w/UI
							thread.
				mask WPF_UNIV_ENTERED - set if in middle of
							MSG_META_UNIV_ENTER/LEAVE
							pair (NOT sync w/UI)
				mask WPF_VIS_ENTERED - set if in middle of
							MSG_META_VIS_ENTER/LEAVE
							pair (NOT sync w/UI)
			

		WIT_LAYER_ID
			ax - layer ID (a unique handle)

		WIT_PARENT_WIN, WIT_FIRST_CHILD_WIN, WIT_LAST_CHILD_WIN,
		WIT_PREV_SIBLING_WIN, WIT_NEXT_SIBLING_WIN:
			ax	- window  link (generally only useful
				  from within callback routine of WinProcess)

		WIT_PRIORITY
			al - WinPriorityData

	carry set if di is a gstate or a window that is closing
	
DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Chris 	4/26/91		Changed to return carry

-------------------------------------------------------------------------------@

WinGetInfo	proc	far
	push	di
	push	ds
	call	FarWinLockFromDI
	jc	exit				; exit if gstring
EC<	test	si, 01h		; ODD?			>
EC<	jnz	badWinInfoType				>
EC<	cmp	si, WinInfoType			>
EC<	ja	badWinInfoType				>
	push	di
	call	cs:winGetInfoTable[si]
	pop	di

	push	ax, bx
	mov	bx, di				; get window handle
	call	WinUnlockV
	pop	ax, bx
	clc						;window did exist
exit:
	pop	ds
	pop	di
	ret

EC<badWinInfoType:					>
EC<	ERROR		WIN_BAD_WIN_INFO_TYPE		>

WinGetInfo	endp

;----------------------

winGetInfoTable	label	word
	word	WinGetPrivateData
	word	WinGetColor
	word	WinGetInputOD
	word	WinGetExposureOD
	word	WinGetStrategy
	word	WinGetFlags
	word	WinGetLayerID
	word	WinGetParentWin
	word	WinGetFirstChildWin
	word	WinGetLastChildWin
	word	WinGetPrevSiblingWin
	word	WinGetNextSiblingWin
	word	WinGetPriority


WinGetPrivateData	proc	near
	mov	ax,ds:[W_privData].WPD_ax
	mov	bx,ds:[W_privData].WPD_bx
	mov	cx,ds:[W_privData].WPD_cx
	mov	dx,ds:[W_privData].WPD_dx
	ret
WinGetPrivateData	endp


WinGetColor	proc	near
	mov	ah, ds:[W_color]		; get flags
	mov	al, ds:[W_colorRGB].RGB_red	; get red color
	mov	bh, ds:[W_colorRGB].RGB_green	; get green color
	mov	bl, ds:[W_colorRGB].RGB_blue	; get blue color
	ret
WinGetColor	endp

WinGetInputOD	proc	near
	mov	di, offset W_inputObj
	jmp	GetTwoWords
WinGetInputOD	endp

WinGetExposureOD	proc	near
	mov	di, offset W_exposureObj
	jmp	GetTwoWords
WinGetExposureOD	endp

WinGetStrategy	proc	near
	mov	di, offset W_driverStrategy
	REAL_FALL_THRU	GetTwoWords
WinGetStrategy	endp

GetTwoWords	proc	near
	mov	cx, ds:[di].segment
	mov	dx, ds:[di].offset
	ret
GetTwoWords	endp

WinGetFlags	proc	near
	mov	al, ds:[W_regFlags]
	mov	ah, ds:[W_ptrFlags]
	ret
WinGetFlags	endp

WinGetLayerID	proc	near
	mov	ax, ds:[W_layerID]
	ret
WinGetLayerID	endp

WinGetParentWin	proc	near
	mov	ax, ds:[W_parent]
	ret
WinGetParentWin	endp

WinGetFirstChildWin	proc	near
	mov	ax, ds:[W_firstChild]
	ret
WinGetFirstChildWin	endp

WinGetLastChildWin	proc	near
	mov	ax, ds:[W_lastChild]
	ret
WinGetLastChildWin	endp

WinGetPrevSiblingWin	proc	near
	mov	ax, ds:[W_prevSibling]
	ret
WinGetPrevSiblingWin	endp

WinGetNextSiblingWin	proc	near
	mov	ax, ds:[W_nextSibling]
	ret
WinGetNextSiblingWin	endp

WinGetPriority	proc	near
	mov	al, ds:[W_priority]
	ret
WinGetPriority	endp

WinMovable ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGetWinScreenBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns bounds of window, in screen coordinates.  Useful
		to determine window's current position & size.

CALLED BY:	GLOBAL

PASS:		di - handle of window or graphics state

RETURN:		ax	- window left
		bx	- window top
		cx	- window right
		dx	- window bottom
		carry set if di is a gstate or a window that is closing
		
DESTROYED:	nothing
		
PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/18/88	Initial version
	Jim	2/90		changed to use common code
	Chris 	4/26/91		Changed to return carry
	Doug	5/14/91		Corrected header doc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinGetWinScreenBounds	proc	far
	uses	di, ds	
	.enter

	call	FarWinLockFromDI	; ds = window segment.
	jc	handleGS		; handle passed gstring

					; see if closing (note:  clears carry)
	test	ds:[W_regFlags], mask WRF_CLOSED
	jz	10$
	stc				; set carry flag to indicate closing
10$:
	mov	ax, ds:[W_winRect.R_left]
	mov	bx, ds:[W_winRect.R_top]
	mov	cx, ds:[W_winRect.R_right]
	mov	dx, ds:[W_winRect.R_bottom]
	xchg	bx, di			; get window handle, save coord.
	call	MemUnlockV		; release window
	xchg	bx, di 			; restore coord.
					; carry should be intact from above
exit:					;
	.leave
	ret

	; if passed a gstring, return big bounds
handleGS:
	mov	ax, MIN_COORD
	mov	bx, ax
	mov	cx, MAX_COORD
	mov	dx, cx
	stc				; say the window didn't exist
	jmp	short exit
WinGetWinScreenBounds	endp

GraphicsObscure segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinRealizePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Realize the palette for this window in hardware

CALLED BY:	GLOBAL
		OpenWinUpdateSystemFocusExcl
PASS:		di		- Window handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinRealizePalette	proc	far
		uses	bx, ax, ds, si, dx, cx, di, es
		.enter

		mov	bx, di			; setup Win handle
		call	MemPLock
		mov	es, ax
		
		; check for palette

		mov	si, es:[W_palette]	; get palette handle
		tst	si
		jz	defPalette
		mov	si, es:[si]		; ds:si -> palette data
		clr	ax			; start with 1st entry
		mov	cx, 0x100		; set all of them
		mov	dx, es			; dx:si -> palette entries

		; check for vidmem.  If we're writing to vidmem, then lock
		; down the bitmap block and allow modifications to all entries.
setPalCommon:
		tst	es:[W_bitmap].segment	; check VM file handle
		jnz	handleBitmap		;  there is one, deal with it

		mov	di, DR_VID_SET_PALETTE
		call	es:[W_driverStrategy]	; call video driver
done:
		call	MemUnlockV		; release window

		.leave
		ret

defPalette:
		mov	dx, segment idata
		mov	si, offset idata:defaultPalette
		mov	ax, 0x100
		mov	cx, 0x100		; set all registers
		jmp	setPalCommon

		; we are going to vidmem.  Lock down bitmap header
handleBitmap:
		push	ax, bx
		mov	bx, es:[W_bitmap].segment
		mov	di, es:[W_bitmap].offset
		call	HugeArrayLockDir
EC <		tst	es:[W_bmSegment]	; has to be zero here	>
EC <		ERROR_NZ GRAPHICS_BITMAP_SHOULDNT_BE_LOCKED		>
		mov	es:[W_bmSegment], ax
		pop	ax, bx

		; if we're already setting all the entries, continue

;		tst	ax			; if starting at zero
;		jz	callDriver
		
		; need to determine what the size of the palette is
		
		push	ds	
		mov	ds, es:[W_bmSegment]
		mov	di, offset EB_bm
		add	di, ds:[di].CB_palette
		mov	cx, ds:[di]		; get number of entries in palette
		pop	ds

		mov	di, DR_VID_SET_PALETTE
		call	es:[W_driverStrategy]	; call video driver

		; unlock the bitmap

		push	ds	
		mov	ds, es:[W_bmSegment]
		mov	es:[W_bmSegment], 0
		call	HugeArrayUnlockDir
		pop	ds
EC <		push	bx, di					>
EC <		mov	bx, es:[W_bitmap].segment		>
EC <		mov	di, es:[W_bitmap].offset		>
EC <		call	ECCheckHugeArrayFar			>
EC <		pop	bx, di					>
		jmp	done
WinRealizePalette	endp

GraphicsObscure ends
