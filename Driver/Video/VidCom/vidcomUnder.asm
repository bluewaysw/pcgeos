COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common video driver
FILE:		vidcomUnder.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VidSaveUnder		Set the save under area
   GLB	VidRestoreUnder		Restore the save under area
   GLB	VidNukeUnder		Reset the save under area
   GLB	VidRequestUnder		Determine whether an existing save under area
				needs to be removed for a new save under area
				to be created

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version
	jeremy	5/91		Added support for the mono EGA driver

DESCRIPTION:
	This file contains routines to implement save under

	$Id: vidcomUnder.asm,v 1.1 97/04/18 11:41:51 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidCheckUnder

DESCRIPTION:	Check a rectangular region against all the save under areas

CALLED BY:	INTERNAL
		DriverStrategy

PASS:
	ax - left
	bx - top
	cx - right
	dx - bottom

RETURN:
	al - flags for all save under areas hit

DESTROYED:
	ah

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

-------------------------------------------------------------------------------@

VidCheckUnder	proc	near
EC <	call	ECVidCheckRectBounds					>

if	SAVE_UNDER_COUNT	gt	0
	cmp	cs:[suCount], 0			; any active save under areas?
	jne	CheckForCollisions	; => yes, there are!
endif
	clr	al				; return no collisions
	ret

if	SAVE_UNDER_COUNT	gt	0
CheckForCollisions:
	; check for collision with save under areas

	.assert segment suCount eq @CurSeg
	push	si, di, ds			; save trashed registers

	mov_tr	di, ax			; di <- left

	segmov	ds, cs, si			; ds <- code segment

	clr	al				; al <- no collisions initially
	mov	ah, ds:[suCount]		; ah <- # of SU areas

	mov	si, offset ds:[suTable]		; si <- base of table

VCU_loop:
	cmp	di, ds:[si].SUS_right
	jg	VCU_nc			;;rect to right -> branch
	cmp	cx, ds:[si].SUS_left
	jl	VCU_nc			;;rect to left -> branch
	cmp	bx, ds:[si].SUS_bottom
	jg	VCU_nc			;;rect to bottom -> branch
	cmp	dx, ds:[si].SUS_top
	jl	VCU_nc			;;rect to top -> branch

	ornf	al, ds:[si].SUS_flags	; show collisiion
VCU_nc:
	add	si, size SaveUnderStruct	; go to next area
	dec	ah				; reduce # of areas left
	jnz	VCU_loop	; => process next area

VCU_Done::

	pop	si, di, ds			; restore trashed registers
	ret
endif
VidCheckUnder	endp
	public	VidCheckUnder




COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidInfoUnder

DESCRIPTION:	Return information about a save under area

CALLED BY:	DriverStrategy via DR_VIDEO_INFO_UNDER

PASS:
	al	- bit mask of single save under area to get info for

RETURN:
	ax	- left
	bx	- top
	cx	- right
	dx	- bottom

	di	- window	(0 if no save under area in use here)

DESTROYED:	( si, bp ,ds, es   allowed)
		si, ds destroyed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	Todd	8/94		Optimized a bit for 2.1

-------------------------------------------------------------------------------@

if	SAVE_UNDER_COUNT	gt	0
	;
	;  VidInfoUnder Depends upon following structure for SaveUnderStruct
	.assert		offset SUS_left		eq 0
	.assert		offset SUS_top		eq 2
	.assert		offset SUS_right	eq 4
	.assert		offset SUS_bottom	eq 6
	.assert		offset SUS_window	eq 8
endif

VidInfoUnder	proc	near

if	SAVE_UNDER_COUNT	gt	0
ifdef	IS_CASIO
	tst	cs:[suCount]		; there is only one save under area
	jz	NotInUse		;  for casio

	segmov	ds, cs, si			; ds <- code segment
	mov	si, offset ds:[suTable]	; start at the top...

	lodsw				; ax <- left
	mov_tr	di, ax				; di <- left
	lodsw				; ax <- top
	mov_tr	bx, ax				; bx <- top
	lodsw				; ax <- right
	mov_tr	cx, ax				; cx <- right
	lodsw				; ax <- bott
	mov_tr	dx, ax				; dx <- bott
	lodsw				; ax <- window
	xchg	ax, di				; di <- window
						; ax <- left
else
	test	al, cs:[suFreeFlags]	; First, check to see if save under
					; area is actually free..
	jnz	NotInUse		; if it is FREE, & not in use, return
					; all zero's

	segmov	ds, cs, si			; ds <- code segment
	mov	si, offset ds:[suTable]	; start at the top...

	mov	dx, size SaveUnderStruct; preload constant

InfoLoop:
	test	al, ds:[si].SUS_flags	; see if this one is it...
	jnz	FoundIt
	add	si, dx			; advance to next SU region
EC<	cmp	si, offset end_suTable					>
EC<	ERROR_AE VIDEO_CAN_NOT_FIND_SAVE_UNDER_WINDOW			>
	jmp	short InfoLoop		; otherwise, keep looking

FoundIt:

	lodsw				; ax <- left
	mov_tr	di, ax				; di <- left
	lodsw				; ax <- top
	mov_tr	bx, ax				; bx <- top
	lodsw				; ax <- right
	mov_tr	cx, ax				; cx <- right
	lodsw				; ax <- bott
	mov_tr	dx, ax				; dx <- bott
	lodsw				; ax <- window
	xchg	ax, di				; di <- window
						; ax <- left
endif
	ret

NotInUse:
endif
	clr	ax, bx, cx, dx, di
	ret

VidInfoUnder	endp
	public	VidInfoUnder


COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidRequestUnder

DESCRIPTION:	Determine whether an existing save under area needs to be
		removed for a new save under area to be created

CALLED BY:	INTERNAL
		DriverStrategy

PASS:
	ax - width (in pixels) for requested save under area
	bx - height (in pixels) for requested save under area

RETURN:
	carry - set if a save under area needs to be removed
	ax - flags of save under to remove
	bx - handle of window of save under to remove

DESTROYED:
	cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	/* See if a save under area needs to be removed */

	needed = # of bytes needed for save buffer;

	if ((SAVE_AREA_SIZE - suSaveFreePtr < needed) ||
				(suFreePtr == end_suTable)) {
		if (not enough room after removing save under #0) {
			return(error)
		}
		return(suTable[0].winHandle);
	}
	return(noneToRemove);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version
	Jim	02/89		Modified to generalize if more than 1bit/pixel
				within the same scanline

------------------------------------------------------------------------------@

VidRequestUnder	proc	near

if	SAVE_UNDER_COUNT	gt	0

ifdef 	IS_JEDI
	;
	; Since we have only two save under areas and enough space to
	; save 2 complete save under areas on Jedi it is not necessary
	; to check if we have enough space only that we have no save
	; under table entries available.
	;
	cmp	cs:[suFreePtr], offset dgroup:end_suTable
	jne	VRU_removeNone
else
	
ifdef	IS_CASIO
	cmp	cs:[suCount], 0			; any active save under areas?
	jz	VRU_removeNone			; If no save-unders, return
else

ifdef	IS_CANDT
	cmp	cs:[suCount], 0			; any active save under areas?
	jz	VRU_removeNone			; If no save-unders, return
endif

ifdef	ALT_VIDEO_RAM

	tst_clc	cs:[suCount]			; any active save under areas?
	je	VRU_removeNone			; If no save-unders, return

	; See if a save under area needs to be removed
	; needed = # of bytes needed for save buffer;

	add	ax, SAVE_UNDER_SLOP-2		;ax = (width + 31) / 8
ifdef	BIT_CLR32
	shl	ax, 2		;ax = bytes needed per line (assumes 32bit/pixel)
elifdef	BIT_CLR16
	shl	ax		;ax = bytes needed per line (assumes 16bit/pixel)
elifdef	BIT_CLR8
	; <no shift>		;ax = bytes needed per line (assumes 8bit/pixel)
elifdef	BIT_CLR4
	shr	ax		;ax = bytes needed per line (assumes 4bit/pixel)
elifdef	BIT_CLR2
	shr	ax, 2		;ax = bytes needed per line (assumes 2bit/pixel)
else
	shr	ax, 1		;ax = bytes needed per line (assumes 1bit/pixel)
	shr	ax, 1
	shr	ax, 1
endif	; BIT_CLR32

	mul	bx		;dxax = number of bytes needed
SVR<	EC<	tst	dx				; way overflowed?>>
SVR<	EC<	ERROR_NZ VIDEO_BAD_SAVE_UNDER_BOUNDS			>>

	; if ((SAVE_AREA_SIZE - suSaveFreePtr < needed) ||
	;			(suFreePtr == end_suTable)) {
	;	if (not enough room after removing save under #0) {
	;		return(error)
	;	}
	;	return(suTable[0].winHandle);
	; }

ifdef	LARGE_VIDEO_RAM
NOHALF< MRES <	movdw	bxcx, cs:[suSaveAreaSize]			>>
NOHALF<	FRES <	movdw	bxcx, SAVE_AREA_SIZE				>>
NOHALF<	subdw	bxcx, cs:[suSaveFreePtr];cx = number of free bytes	>
HALF<	movdw	bxcx, cs:[suSaveSpaceFree]				>
	cmpdw	bxcx, dxax
else
NOHALF<	MRES <	mov	cx, cs:[suSaveAreaSize]				>>
NOHALF<	FRES <	mov	cx, SAVE_AREA_SIZE				>>
NOHALF<	sub	cx, cs:[suSaveFreePtr]	;cx = number of free bytes	>
HALF<	mov	cx, cs:[suSaveSpaceFree]				>
	cmp	cx, ax
endif	; LARGE_VIDEO_RAM
	jb	VRU_removeOne

endif

	cmp	cs:[suFreePtr], offset dgroup:end_suTable
	jne	VRU_removeNone

ifdef	ALT_VIDEO_RAM

VRU_removeOne:

LVR <	pushdw	dxax							>
SVR <	push	ax							>
if	BIT_SHIFTS le 2
	mov	ax, cs:[suTable].SUS_unitsPerLine
else
	mov	al, cs:[suTable].SUS_unitsPerLine
	clr	ah
endif	; BIT_SHIFTS le 2
	ShiftLeftIf16	ax		; convert to bytes
	mul	cs:[suTable].SUS_lines	; dxax = # bytes of 1st save-under area
LVR <	adddw	bxcx, dxax						>
LVR <	popdw	dxax							>
LVR <	cmpdw	bxcx, dxax						>
SVR <	add	cx, ax							>
SVR <	pop	ax							>
SVR <	cmp	cx, ax							>
	jb	VRU_removeNone

endif

endif	; CASIO
endif	; JEDI

	mov	al, cs:[suTable].SUS_flags
	mov	bx, cs:[suTable].SUS_window
	stc
	ret

	; return(noneToRemove);

VRU_removeNone:
endif	; SAVE_UNDER_COUNT
	clc
	ret

VidRequestUnder	endp
	public	VidRequestUnder

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidSaveUnder

DESCRIPTION:	Set the save under area

CALLED BY:	INTERNAL
		DriverStrategy

PASS:
	es - segment of P'ed, locked window
	ax, bx, cx, dx - bounds to save under (or ax = 0x8000 to use
			 window bounds)

RETURN:
	carry - clear if save under performed
		set if save under not possible
	al - flags for window saved

DESTROYED:
	ah, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	needed = # of bytes needed for save buffer;

	************ if ALT_VIDEO_RAM ****************************
	if ((SAVE_AREA_SIZE - suSaveFreePtr < needed) ||
				(suFreePtr == end_suTable)) {
		return(error);
	}
	************ else ****************************

	if (han = MemAlloc(needed)) == ERROR) {
		return(error);
	}

	************ endif ****************************

	/* save coordinates of save under area and save under ID */

	/* save the screen area */

	SaveScreen();

	return(successful);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@


VidSaveUnder	proc	near
if	SAVE_UNDER_COUNT	eq	0
	stc
	ret
else
	segmov	ds, cs
	cmp	ds:[suCount], SAVE_UNDER_COUNT
EC <	ERROR_A	VIDEO_TOO_MANY_SAVE_UNDERS				>

;Note: the only reason that this IS_CASIO conditional has been added
;is because in the casio case, the exit RET is too far away, and making this
;a "LONG je noSaveUnder" for all of the cases would be bad.

ifndef	IS_CASIO
LONG	je	noSaveUnder		;skip to exit if too many already...
else
	jne	10$			;skip if can save under...
	stc				;no save under: return with error here,
	ret				;because the other RET is far away
10$:
endif

	cmp	ax, 0x8000
	jne	coordinatesPassed
	mov	ax, es:[W_winRect.R_left]
	mov	bx, es:[W_winRect.R_top]
	mov	cx, es:[W_winRect.R_right]
	mov	dx, es:[W_winRect.R_bottom]
coordinatesPassed:

EC <	call	ECVidCheckRectBounds					>

	; clip W_winRect to screen coordinates

	tst	ax
	jns	VSU_1
	clr	ax
VSU_1:
ifdef	MULT_RESOLUTIONS
	cmp	ax, ds:[DriverTable].VDI_pageW
	jl	VSU_1_5
	mov	ax, ds:[DriverTable].VDI_pageW
	dec	ax
else
	cmp	ax,SCREEN_PIXEL_WIDTH-1
	jle	VSU_1_5
	mov	ax,SCREEN_PIXEL_WIDTH-1
endif	; MULT_RESOLUTIONS
VSU_1_5:
	tst	bx
	jns	VSU_2
	clr	bx
VSU_2:
ifdef	MULT_RESOLUTIONS
	cmp	bx, ds:[DriverTable].VDI_pageH
	jl	VSU_2_5
	mov	bx, ds:[DriverTable].VDI_pageH
	dec	bx
else
	cmp	bx,SCREEN_HEIGHT-1
	jle	VSU_2_5
	mov	bx,SCREEN_HEIGHT-1
endif	; MULT_RESOLUTIONS
VSU_2_5:
	tst	cx
	jns	VSU_3
	clr	cx
VSU_3:
ifdef	MULT_RESOLUTIONS
	cmp	cx, ds:[DriverTable].VDI_pageW
	jl	VSU_3_5
	mov	cx, ds:[DriverTable].VDI_pageW
	dec	cx
else
	cmp	cx,SCREEN_PIXEL_WIDTH-1
	jle	VSU_3_5
	mov	cx,SCREEN_PIXEL_WIDTH-1
endif	; MULT_RESOLUTIONS
VSU_3_5:
	tst	dx
	jns	VSU_4
	clr	dx
VSU_4:
ifdef	MULT_RESOLUTIONS
	cmp	dx, ds:[DriverTable].VDI_pageH
	jl	VSU_4_5
	mov	dx, ds:[DriverTable].VDI_pageH
	dec	dx
else
	cmp	dx,SCREEN_HEIGHT-1
	jle	VSU_4_5
	mov	dx,SCREEN_HEIGHT-1
endif	; MULT_RESOLUTIONS
VSU_4_5:
	push	ax, bx, cx, dx

	; ax, bx, cx ,dx = bounds
	; needed = # of bytes needed for save buffer;

ifndef	IS_CASIO
	sub	cx,ax			;ax = ((right - left) + 32) / 8
	add	cx, SAVE_UNDER_SLOP - 1
	mov_tr	ax,cx

ifdef	BIT_CLR32
	shl	ax, 2			;ax = bytes needed per line (32bit/pix)
elifdef	BIT_CLR16
	shl	ax			;ax = bytes needed per line (16bit/pix)
elifdef	BIT_CLR8
	; <no shift>			;ax = bytes needed per line (8 bit/pix)
elifdef	BIT_CLR4
	shr	ax			;ax = bytes needed per line (4 bit/pix)
elifdef	BIT_CLR2
	shr	ax, 2			;ax = bytes needed per line (2 bit/pix)
else
ifdef	IS_NIKE_COLOR
	shr	ax,1			;ax = bytes needed per line (4 bit/pix)
else
	mov	cl,3
	shr	ax,cl			;ax = bytes needed per line (assumes 
endif					;	1 bit/pixel)
endif	; BIT_CLR32

	sub	dx,bx
	inc	dx
	mul	dx			;dxax = number of bytes needed

ifndef	ALT_VIDEO_RAM
	jo	VSU_error		;overflow, error
elifndef LARGE_VIDEO_RAM
	jo	VSU_error		;overflow, error
endif	; not ALT_VIDEO_RAM

ifdef	ALT_VIDEO_RAM

	; if ((SAVE_AREA_SIZE - suSaveFreePtr < needed) ||
	;			(suFreePtr == end_suTable)) {
	;	return(error);
	; }

ifdef	LARGE_VIDEO_RAM
NOHALF<	MRES <	movdw	bxcx, cs:[suSaveAreaSize]			>>
NOHALF<	FRES <	movdw	bxcx, SAVE_AREA_SIZE				>>
NOHALF<	subdw	bxcx, ds:[suSaveFreePtr];cx = number of free bytes	>
HALF<	movdw	bxcx, ds:[suSaveSpaceFree]				>
	cmpdw	bxcx, dxax
else
NOHALF<	MRES <	mov	cx, cs:[suSaveAreaSize]				>>
NOHALF<	FRES <	mov	cx, SAVE_AREA_SIZE				>>
NOHALF<	sub	cx, ds:[suSaveFreePtr]	;cx = number of free bytes	>
HALF<	mov	cx, ds:[suSaveSpaceFree]				>
	cmp	cx, ax
endif	; LARGE_VIDEO_RAM
	jb	VSU_error

	cmp	ds:[suFreePtr], offset dgroup:end_suTable
	jnz	VSU_continue

VSU_error:
	add	sp,8			;discard bounds
noSaveUnder:
	stc
	ret

VSU_continue:
else

NEC <ASU_FLAGS =	mask HF_SHARABLE or ((mask HAF_LOCK) shl 8) >
EC <ASU_FLAGS =	mask HF_SHARABLE or mask HF_SWAPABLE or ((mask HAF_LOCK) shl 8) >
	; if (han = MemAlloc(needed)) == ERROR) {
	;	return(error);
	; }

	cmp	ax, MAX_MEM_ALLOC_FOR_SAVE_UNDER_REGION
	ja	VSU_error
	mov	cx,ASU_FLAGS
	call	MemAlloc
	mov	ds:[suSaveSegment],ax	;save segment for later
	jnc	VSU_memContinue
VSU_error:
	add	sp,8			;discard boubds
noSaveUnder:
	stc
	ret				;return with error

VSU_memContinue:
	push	ax
	mov	ax, handle 0
	call	HandleModifyOwner	;change owner to video driver
	pop	ax


	; save coordinates of save under area and save under ID
endif

	mov	si, ds:[suFreePtr]	;ds:si = address to add at

ifdef	ALT_VIDEO_RAM
ifdef	LARGE_VIDEO_RAM
	movdw	cxbx, ds:[suSaveFreePtr]
	movdw	ds:[si].SUS_saveAddr,cxbx;store address in save buffer
HALF<	subdw	ds:[suSaveSpaceFree], dxax;adjust space left in buffer	>
NOHALF<	adddw	dxax, cxbx		;compute next free address	>
NOHALF<	movdw	ds:[suSaveFreePtr],dxax					>
else
	mov	bx, ds:[suSaveFreePtr]
	mov	ds:[si].SUS_saveAddr,bx	;store address in save buffer
HALF<	sub	ds:[suSaveSpaceFree], ax;adjust space left in buffer	>
NOHALF<	add	ax, bx			;compute next free address	>
NOHALF<	mov	ds:[suSaveFreePtr],ax					>
endif	; LARGE_VIDEO_RAM
else
	mov	ds:[si].SUS_saveAddr,bx ; store handle in save buffer
endif

endif
CASIO <	mov	si, offset cs:[suTable]				>
	mov	ax, es:[W_header.LMBH_handle]
	mov	ds:[si].SUS_window,ax	;store window handle

	mov	ax,es:[W_parent]	;fetch parent window (Needed for
					;call to WinMaskOutSaveUnder)
	mov	ds:[si].SUS_parent,ax	;store parent window handle

	mov	ah,ds:[suFreeFlags]	;find a free flag
EC <	tst	ah							>
EC <	ERROR_Z	VIDEO_TOO_MANY_SAVE_UNDERS				>

	mov	al,10000000b
VSU_bitLoop:
	rol	al,1
	shr	ah,1
	jnc	VSU_bitLoop

	mov	ds:[si].SUS_flags,al	;store flags
	not	al
	and	ds:[suFreeFlags],al	;mark flag as used

	; update freePtr

	mov	ax, si
	add	ax, size SaveUnderStruct
	mov	ds:[suFreePtr], ax
	inc	ds:[suCount]

	pop	ax, bx, cx, dx

EC <	cmp	si, offset end_suTable					>
EC <	ERROR_AE	VIDEO_TOO_MANY_SAVE_UNDERS			>

	mov	ds:[si].SUS_left, ax	;store left
	mov	ds:[si].SUS_top, bx	;store top
	mov	ds:[si].SUS_right, cx	;store right
	mov	ds:[si].SUS_bottom, dx	;store bottom

	; save screen area

	push	word ptr ds:[si].SUS_flags

NOALT <	push	ds:[si].SUS_saveAddr	;;save handle			>

	call	SaveScreen

NOALT <	pop	bx							>
NOALT <	call	MemUnlock						>

	pop	ax		;recover flags

	; return(successful);

	clc
	ret
endif
VidSaveUnder	endp
	public	VidSaveUnder
if	SAVE_UNDER_COUNT	gt	0

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidRestoreUnder

DESCRIPTION:	Restore the save under area

CALLED BY:	INTERNAL
		DriverStrategy

PASS:
	es - Window structure (contains valid W_maskReg and mask variables for
	     blt'ing)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	index = FindSaveUnder(window);

	/* Restore screen area */

	RestoreScreen();

	/* Remove save under */

	RemoveSaveUnder();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

VidRestoreUnder	proc	near
	call	FindSaveUnder
	push	si
	call	RestoreScreen
	pop	si

	GOTO	RemoveSaveUnder

VidRestoreUnder	endp
	public	VidRestoreUnder

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidNukeUnder

DESCRIPTION:	Reset the save under area

CALLED BY:	INTERNAL
		DriverStrategy

PASS:
	es - segment of P'ed, locked window

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp ,ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

VidNukeUnder	proc	near
	call	FindSaveUnder
	FALL_THRU	RemoveSaveUnder

VidNukeUnder	endp
	public	VidNukeUnder


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RemoveSaveUnder

DESCRIPTION:	Remove a save under area from the table and from the save under
		store area

CALLED BY:	INTERNAL
		VidNukeUnder, VidSaveUnder

PASS:
	si - index of save under area to remove
	ds - cs

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp ,ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	/* Free flag used for save under */

	if (si != last valid save under area) {

		/* Remove save under memory area */

		************ if ALT_VIDEO_RAM ****************************

		destPtr = si.SUS_saveAddr;
		sourcePtr = (si+1).SUS_saveAddr;
		while (sourcePtr != suSaveFreePtr) {
			*destPtr++ = *sourcePtr++;
		}
		suSaveFreePtr = destPtr;

		************ else ****************************

		MemFree(si.SUS_saveAddr);

		************ endif ****************************

		/* Remove save under from table */

		sourcePtr = si + (size SaveUnderStruct);   destPtr = si;
		while (sourcePtr != suFreePtr) {
			*destPtr++ = *sourcePtr++;
		}

	}

	/* Mark as free */

	suFreePtr -= size SaveUnderStruct;
	suFreePtr.SUS_left = -1;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

RemoveSaveUnder	proc	near

	; Free flag used for save under

	mov	al,ds:[si].SUS_flags
	or	ds:[suFreeFlags],al


ifndef	IS_CASIO

ifndef	ALT_VIDEO_RAM

	;	MemFree(si.SUS_saveAddr);

	push	bx
	mov	bx,ds:[si].SUS_saveAddr
	call	MemFree
	pop	bx
endif	; ALT_VIDEO_RAM

	; if (si != last valid save under area) {

	mov	bx,si			;bx = one being removed
	mov	bp,si			;bp = one after one being removed
	add	bp,size SaveUnderStruct

	cmp	bp,ds:[suFreePtr]
	je	RSU_lastOne

	;	/* Remove save under memory area */

ifdef	ALT_VIDEO_RAM
	;	destPtr = si.SUS_saveAddr;
	;	sourcePtr = (si+1).SUS_saveAddr;
	;	while (sourcePtr != suSaveFreePtr) {
	;		*destPtr++ = *sourcePtr++;
	;	}
	;	suSaveFreePtr = destPtr;
	;
	; On Jedi the memory layout is a little awkward to work with so instead
	; of using the normal calculations, we assume that there are
	; only two save unders and we are copying the second one over
	; the first.
	;
ifdef	IS_JEDI
	mov	di, ds:[bx].SUS_saveAddr		;es:di = dest (lower addr)
	mov	si, ds:[bp].SUS_saveAddr		;ds:si = source (higher addr)

	clr	ax
	mov	al, ds:[bp].SUS_unitsPerLine	
	mul	ds:[bp].SUS_lines
IS16<	shl	ax, 1							>
	mov	cx, ax
else
ifdef	LARGE_VIDEO_RAM
	movdw	ds:[dest],ds:[bx].SUS_saveAddr, di
	movdw	dxax,ds:[bp].SUS_saveAddr	;dxax = source (higher addr)
	movdw	ds:[src], dxax

	subdw	dxax, ds:[dest]			;dxax <- distance moved

	movdw	cxsi, ds:[suSaveFreePtr]
	subdw	cxsi, ds:[src]			;cxsi = # bytes
	movdw	ds:[unitsToMove], cxsi
	subdw	ds:[suSaveFreePtr], dxax	;update end pointer
else
	mov	di,ds:[bx].SUS_saveAddr		;es:di = dest (lower addr)
	mov	ax,ds:[bp].SUS_saveAddr		;ds:si = source (higher addr)
	mov	si,ax

	sub	ax,di				;ax <- distance moved

	mov	cx, ds:[suSaveFreePtr]		;compute # of bytes
	sub	cx, si				;cx = # bytes
	sub	ds:[suSaveFreePtr],ax		;update end pointer
endif	; LARGE_VIDEO_RAM
endif
	; update pointers to data in save unders being moved
	
ifdef	IS_JEDI
	CheckHack <SAVE_UNDER_COUNT eq 2>				
	mov	ds:[bp].SUS_saveAddr, di
else
	push	bp

10$:
LVR<	subdw	ds:[bp].SUS_saveAddr, dxax				>
SVR<	sub	ds:[bp].SUS_saveAddr, ax				>
	add	bp, size SaveUnderStruct
	cmp	bp, ds:[suFreePtr]
	jb	10$

	pop	bp
endif	; JEDI

ifdef	LARGE_VIDEO_RAM
						;cxsi = # bytes
IS16 <	incdw	ds:[unitsToMove]		;;ensure last byte copied >
IS16 <	shrdw	ds:[unitsToMove]		;convert to words	>
else
HALF <	mov	ax, cx				;save # of bytes	>
IS16 <	inc	cx				;;ensure last byte copied >
IS16 <	shr	cx,1				;convert to words	>
endif	; LARGE_VIDEO_RAM

EGA <	call	InitEGAForUnder						>

	SetAltBuffer	ds, dx
	segmov	es,ds
ifdef	LARGE_VIDEO_RAM
	; Analogous to SetAltBuffer above, convert 32-bit offsets in
	; save-under area to offsets in video RAM.
	adddw	cs:[src], cs:[suSaveAreaStart], dx
	adddw	cs:[dest], cs:[suSaveAreaStart], dx
endif

ifdef	IS_HALF_SCREEN
LVR<	adddw	cs:[suSaveSpaceFree], cxsi	; restore removed space	>
SVR<	add	cs:[suSaveSpaceFree], ax	; restore removed space	>
SVR<	mov_tr	ax, cx				; ax <- # of units to copy>
RSU_copyScanLine:
	;
	;  Get size of 1 altBuffer scanline
IS8 <	mov	cx, ALT_BUFFER_BYTE_WIDTH				>
IS16 <	mov	cx, ALT_BUFFER_BYTE_WIDTH / 2				>
endif	; IS_HALF_SCREEN

	; IS_HALF_SCREEN: move one altBuffer scanline
	; !IS_HALF_SCREEN: move all the remaining altBuffer data
LVR <	call	SaveUnderMemMove					>
SVR <	MoveStrUnit							>

ifdef	IS_HALF_SCREEN

ifdef	IS_JEDI
	NextSaveScan 	di, -ALT_BUFFER_BYTE_WIDTH
	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH
else
	NextScan 	di, -ALT_BUFFER_BYTE_WIDTH
	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH
endif

ifdef	IS_JEDI
IS8 <	sub	ax, ALT_BUFFER_BYTE_WIDTH					>
IS16<	sub	ax, ALT_BUFFER_BYTE_WIDTH / 2				>
	ja	RSU_copyScanLine
else
IS8 <	sub	ax, BUFFER_BYTE_WIDTH					>
IS16<	sub	ax, BUFFER_BYTE_WIDTH / 2				>
EC<	ERROR_B	VIDEO_BAD_SAVE_UNDER_BOUNDS				>
	jnz	RSU_copyScanLine
endif


	;
	; Since there are only 2 save unders, we can assume that the
	; end of the destination is now the beginning of the free
	; memory 
	;

endif	; IS_HALF_SCREEN

endif	; IS_ALT_VIDEO_RAM

	;	/* Remove save under from table */
	;	sourcePtr = si + (size SaveUnderStruct);   destPtr = si;
	;	while (sourcePtr != suFreePtr) {
	;		*destPtr++ = *sourcePtr++;
	;	}

	mov	si, cs				; es, ds <- cs (dgroup)
	mov	ds, si
	mov	es, si

	mov	si, bp				;ds:si = source
	mov	di, bx				;es:di = dest

	mov	cx, ds:[suFreePtr]		;compute # of words
	sub	cx, si
	shr	cx, 1
if (size SaveUnderStruct and 1)
	jnc	moveWords
	movsb
moveWords:
endif
	rep movsw

	; }
	; /* Mark as free */
	; suFreePtr -= size SaveUnderStruct;
	; suFreePtr.SUS_left = -1;

ALT <	jmp	short RSU_common					>

RSU_lastOne:

ifdef	LARGE_VIDEO_RAM
ALT <	movdw	dxax, ds:[bx].SUS_saveAddr				>
ALT <	movdw	ds:[suSaveFreePtr],dxax					>
HALF<	movdw	ds:[suSaveSpaceFree], ALT_BUFFER_TOTAL_SIZE		>
else
ALT <	mov	ax, ds:[bx].SUS_saveAddr				>
ALT <	mov	ds:[suSaveFreePtr],ax					>
HALF<	mov	ds:[suSaveSpaceFree], ALT_BUFFER_TOTAL_SIZE		>
endif	; LARGE_VIDEO_RAM

ALT <RSU_common:							>

ifdef	IS_HALF_SCREEN
ifdef	HAS_EXTRA_ALT
	mov	ds:[suSpaceInHalfBuffer], -1	; basically unlimited space...
	IsInExtraAlt	si
	jnc	RSU_done
endif	; HAS_EXTRA_ALT

IS8 <	mov	ds:[suSpaceInHalfBuffer], ALT_BUFFER_BYTE_WIDTH		>
IS16 <	mov	ds:[suSpaceInHalfBuffer], ALT_BUFFER_BYTE_WIDTH	/ 2	>


RSU_done::
endif	; IS_HALF_SCREEN

endif	; IS_CASIO

	mov	si,ds:[suFreePtr]
	sub	si,size SaveUnderStruct
	mov	ds:[suFreePtr],si

	dec	ds:[suCount]

	ret

RemoveSaveUnder	endp
	public	RemoveSaveUnder

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FindSaveUnder

DESCRIPTION:	Find a save under area given a window

CALLED BY:	INTERNAL
		VidNukeUnder, VidRestoreUnder

PASS:
	es - window segment

RETURN:
	si - index into table for save under area
	ds - cs

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

FindSaveUnder	proc	near
	segmov	ds, cs, si
	mov	si,offset dgroup:suTable
	mov	ax,es:[W_header.LMBH_handle]

FSU_loop:
	cmp	ax,ds:[si].SUS_window
	jz	FSU_found
	add	si,size SaveUnderStruct

EC <	cmp	si, offset suTable + ((size SaveUnderStruct) * SAVE_UNDER_COUNT)>
EC <	ERROR_Z	VIDEO_CAN_NOT_FIND_SAVE_UNDER_WINDOW			>

	jmp	short FSU_loop

FSU_found:
	ret

FindSaveUnder	endp
	public	FindSaveUnder

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SaveScreen

DESCRIPTION:	Save the given screen area

CALLED BY:	INTERNAL
		VidSaveUnder

PASS:
	ax - left coordinate of area to save
	bx - top coordinate of area to save
	cx - right coordinate of area to save
	dx - bottom coordinate of area to save
	si - index into suTable with these fields set:
		SUS_left, SUS_top, SUS_right, SUS_bottom
		SUS_id, SUS_window, SUS_saveAddr
	ds - cs

RETURN:
	suTable entry filled

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

SaveScreen	proc	near
EC <	call	ECVidCheckRectBounds					>
	mov	di,si
	mov	si,dx				;si = bottom

	; check for cursor collision

	call	CheckCursorCollision

	cmp	cs:[xorRegionHandle],0
	jz	noXOR
	call	CheckXORCollision
noXOR:

EGA <	call	InitEGAForUnder						>

CASIO <	push	bx							>
CASIO <	mov	bx, 0x100				; auto-trans off>
CASIO <	call	cs:[biosFunctions].CF_autoTransMode			>
CASIO <	pop	bx							>

	; calculate word positions for left and right

	mov	dx,cx				;dx = right
if	BIT_SHIFTS lt 0
	shl	ax, -BIT_SHIFTS			;ax = unit position (left)
	mov	ds:[di].SUS_leftUnit,ax
	shl	dx, -BIT_SHIFTS			;dx = unit position (right)
	mov	ds:[di].SUS_rightUnit,dx
elif	BIT_SHIFTS eq 0
	mov	ds:[di].SUS_leftUnit,ax
	mov	ds:[di].SUS_rightUnit,dx
elif	BIT_SHIFTS eq 1 or BIT_SHIFTS eq 2
	shr	ax, BIT_SHIFTS			;ax = unit position (left)
	mov	ds:[di].SUS_leftUnit,ax
	shr	dx, BIT_SHIFTS			;dx = unit position (right)
	mov	ds:[di].SUS_rightUnit,dx
else	; BIT_SHIFTS gt 2
	mov	cl,BIT_SHIFTS
	shr	ax,cl				;ax = unit position (left)
	mov	ds:[di].SUS_leftUnit,al
	shr	dx,cl				;dx = unit position (right)
	mov	ds:[di].SUS_rightUnit,dl
endif	; BIT_SHIFTS lt 0
	sub	dx,ax

if	BIT_SHIFTS lt 0
	addnf	dx, <1 shl -BIT_SHIFTS>
else
	inc	dx
endif	; BIT_SHIFTS lt 0

if	BIT_SHIFTS le 2
	mov	ds:[di].SUS_unitsPerLine,dx
else
	mov	ds:[di].SUS_unitsPerLine,dl
endif	; BIT_SHIFTS le 2
	xchg	dx,si				;si = # units, dx = bottom

	; calculate # of lines and starting screen address

	sub	dx,bx
	inc	dx
	mov	ds:[di].SUS_lines,dx
	xchg	bx,si				;bx = #words, si = top
	ShiftLeftIf16	ax			;;convert to byte
	CalcScanLine	si, ax			;si = screen address
ifdef	LARGE_VIDEO_RAM
	mov	ax, cs:[curWinPage]		;axsi = offset in VRAM
	movdw	ds:[di].SUS_screenAddr, axsi
ALT <	movdw	cs:[src], axsi						>
ALT <	clr	ax				;axbx = # units		>
ALT <	movdw	cs:[unitsToMove], axbx					>
else
	mov	ds:[di].SUS_screenAddr,si
endif	; LARGE_VIDEO_RAM

	; calculate value used to move to next scan line

	mov	ax,bx
	ShiftLeftIf16	ax			;;convert to byte
	neg	ax				;; fewer to copy
MRES <	add	ax, ds:[DriverTable].VDI_bpScan				>

	mov	ds:[di].SUS_scanMod,ax

ifndef IS_CASIO
ALT <	LVR <	movdw	ds:[dest], ds:[di].SUS_saveAddr, bp		>>
ALT <	SVR <	mov	di,ds:[di].SUS_saveAddr				>>
else
	mov	di, si
	add	di, SCREEN_BYTE_WIDTH
endif

ifndef	IS_HALF_SCREEN
ALT <	SetAltBuffer	es, bp						>
ifdef	LARGE_VIDEO_RAM
ALT <	; Analogous to SetAltBuffer above, convert 32-bit offset in	>
ALT <	; save-under area to offset in video RAM.			>
ALT <	adddw	ds:[dest], ds:[suSaveAreaStart], bp			>
endif	; LARGE_VIDEO_RAM

NOALT <	mov	es, ds:[suSaveSegment]					>
NOALT <	clr	di							>
endif

	SetBuffer	ds,bp			;ds = screen

	;  For half-buffer, make destination buffer same as screen and
	;  determine how many pixels fit in half-buffer
HALF<	segmov	es, ds, bp						>
HALF<	mov	bp, cs:[suSpaceInHalfBuffer]				>

	; do copy: dx = # lines, ds:si = source, es:di = dest, bx = words/line
	;	   ax = value to add to move to next scan line

	; if partial-screen display:   bp <- # of units left in part scan-line

SS_loop:
	mov	cx,bx
HALF<	sub	bp,cx							>
HALF<	jb	SS_trim							>
HALF<SS_afterTrim:							>

ifdef	IS_NIKE_COLOR	; Move 4 times for Nike color - once for each bit plane
	push	ax, bx
SS_10$:	mov	al, ds:[si]
	mov	ah, ds:[si]
	mov	bl, ds:[si]
	mov	bh, ds:[si]
	inc	si
	stosw
	mov_tr	ax, bx
	stosw
	loop	SS_10$
	pop	ax, bx
else
LVR <	call	SaveUnderMemMove					>
SVR <	MoveStrUnit							>
endif

LVR <	NextScanLVR	cs:[src], ax					>
SVR <	NextScan	si, ax						>

CASIO <	mov	di, si							>
CASIO <	add	di, SCREEN_BYTE_WIDTH					>
	dec	dx
	jnz	SS_loop

SS_fallOut::
ifdef	IS_HALF_SCREEN
IS16 <	shl	bp, 1				; words -> bytes	>
	sub	bp, ALT_BUFFER_BYTE_WIDTH
	NextSaveScan	di, bp
	mov	cs:[suSaveFreePtr], di

ifdef	HAS_EXTRA_ALT
	mov	bp, -1
	IsInExtraAlt	di
	jnc	SS_saveSize
endif
IS8 <	mov	bp, ALT_BUFFER_BYTE_WIDTH				>
IS16 <	mov	bp, ALT_BUFFER_BYTE_WIDTH / 2				>

SS_saveSize::
	mov	cs:[suSpaceInHalfBuffer], bp
endif	

SS_common label	near

	cmp	cs:[xorHiddenFlag],0	;check for ptr hidden.
	jz	noRedrawXOR		;go and redraw it if it was hidden.
	call	ShowXOR
noRedrawXOR:

	cmp	cs:[hiddenFlag],0
	jz	SS_noRedraw
	call	CondShowPtr
SS_noRedraw:

CASIO <	mov	bh, 1					; auto-trans on>
CASIO <	mov	bl, CASIO_AT_VRAM_XFER					>
CASIO <	call	cs:[biosFunctions].CF_autoTransMode			>

	ret

ifdef	IS_HALF_SCREEN
SS_trim:
	add	cx, bp					; cx <- # units to move

ifdef	IS_NIKE_COLOR	; Move 4 times for Nike color - once for each bit plane
	push	ax, bx
SS_20$:	mov	al, ds:[si]
	mov	ah, ds:[si]
	mov	bl, ds:[si]
	mov	bh, ds:[si]
	inc	si
	stosw
	mov_tr	ax, bx
	stosw
	loop	SS_20$
	pop	ax, bx
else
	MoveStrUnit
endif

	mov	cx, bp					; cx <- # units to move
	neg	cx

	NextSaveScan	di, -ALT_BUFFER_BYTE_WIDTH
IS8 <	add	bp, ALT_BUFFER_BYTE_WIDTH				>
IS16 <	add	bp, ALT_BUFFER_BYTE_WIDTH / 2				>

ifdef	HAS_EXTRA_ALT
	IsInExtraAlt	di
	jc	SS_afterTrim

	mov	bp, -1
endif
	jmp	SS_afterTrim
endif

SaveScreen	endp
	public	SaveScreen

ifdef	IS_VGALIKE

InitEGAForUnder	proc	near	uses	ax
	.enter

	; set up ega registers, but set currentDrawMode to -1 to force
	; later update

	mov	cs:[currentDrawMode], 0xff

	mov	dx, GR_CONTROL		; ega control register
	mov	ax, WR_MODE_0
	out	dx, ax
	mov	ax, EN_SR_ALL
	out	dx, ax
	mov	ax, SR_BLACK
	out	dx, ax
	mov	ax, DATA_ROT_OR
	out	dx, ax

	mov	ax, BMASK_ALL		; include all bits 
	out	dx,ax

	.leave
	ret

InitEGAForUnder	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	RestoreScreen

DESCRIPTION:	Restore the given screen area

CALLED BY:	INTERNAL
		VidRestoreUnder

PASS:
	si - index into suTable
	ds - cs
	es - window

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

RestoreScreen	proc	near
ALT <	LVR <	movdw	ds:[src], ds:[si].SUS_saveAddr, ax		>>
ALT <	SVR <	mov	ax, ds:[si].SUS_saveAddr			>>
ALT <	SVR <	mov	ds:[d_bytes], ax  ;;use d_bytes to save saveAddr>>

NOALT <	mov	bx,ds:[si].SUS_saveAddr					>
NOALT <	call	MemLock							>
NOALT <	mov	ds:[suSaveSegment],ax					>
NOALT <	mov	ds:[d_bytes],0		;;use d_bytes to save saveAddr	>

	mov	ax,ds:[si].SUS_left
	mov	bx,ds:[si].SUS_top
	mov	cx,ds:[si].SUS_right
	mov	dx,ds:[si].SUS_bottom

	; check for cursor collision

	call	CheckCursorCollision

	cmp	cs:[xorRegionHandle],0
	jz	noXOR
	call	CheckXORCollision
noXOR:

EGA <	call	InitEGAForUnder						>

	mov	dx,ds:[si].SUS_lines
	mov	ds:[d_lineCount],dx

ifdef	LARGE_VIDEO_RAM
	; Unlike in SaveScreen (where the screen addr is calculated by the
	; CalcScanLine macro which has the side effect of setting curWinPage
	; and lastWinPtr, both used indirectly by NextScan), here we
	; retrieve the screen addr from the suTable.  Thus curWinPage and
	; lastWinPtr are not set correctly.  This is not a problem, however,
	; because the video window will be set in RestoreSimpleRect and
	; RestoreMaskedRect when needed, and curWinPage and lastWinPtr are
	; not used by NextScanLVR macro.
	movdw	ds:[dest], ds:[si].SUS_screenAddr, di
else
	mov	di,ds:[si].SUS_screenAddr
endif	; LARGE_VIDEO_RAM

	mov	ds:[d_y1],bx

RS_loop:

	; make sure that clip info is correct

	mov	bx,ds:[d_y1]
	mov	bp,es:[W_clipRect.R_bottom]

	cmp	bx,bp
	jg	RS_setClip
	cmp	bx,es:[W_clipRect.R_top]	; above definition area ?
	jge	RS_afterClip

RS_setClip:
	segmov	ds,es
	push	si,di
	call	WinValClipLine
	pop	si,di
	mov	bp,ds:[W_clipRect.R_bottom]
	segmov	ds,cs

RS_afterClip:

	; bp = W_clipRect.R_bottom, compute # of lines

	sub	bp,bx
	inc	bp			;bp = # of valid lines from top

	cmp	bp,ds:[d_lineCount]	;get max (valid lines, lines to draw)
	jb	RS_noWrap
	mov	bp,ds:[d_lineCount]
RS_noWrap:

	; test for type of clipping region

	mov	cl, es:[W_grFlags]
	test	cl,mask WGF_CLIP_NULL
	jnz	RS_null

	test	cl, mask WGF_CLIP_SIMPLE
	jz	RS_notSimple

	cmp	ds:[si].SUS_unitsPerLine, 1
	je	RS_notSimple

	; simple clipping region -- recover it
	; bp = # of lines to draw, bx = top line
	; make sure W_clipRect.R_left and W_clipRect.R_right are legal,
	; calc masks

	mov	ax, es:[W_clipRect.R_left]
	mov	bx, ax
if	BIT_SHIFTS lt 0
	shl	ax, -BIT_SHIFTS
elif	BIT_SHIFTS eq 0
	; <no shift>
elif	BIT_SHIFTS eq 1 or BIT_SHIFTS eq 2
	shr	ax, BIT_SHIFTS
else	; BIT_SHIFTS gt 2
	mov	cl, BIT_SHIFTS
	shr	ax, cl
endif	; BIT_SHIFTS lt 0

if	BIT_SHIFTS le 2
	cmp	ax,ds:[si].SUS_leftUnit	;if left side is not in same word
else
	cmp	al,ds:[si].SUS_leftUnit	;if left side is not in same word
endif	; BIT_SHIFTS le 2
	jne	RS_notSimple		;then use special routine
ifdef	UNIT_MASK
	and	bx,UNIT_MASK
	ShiftLeftIf16	bx			;;convert to byte
	mov	D_REG,ds:[bx][leftMaskTable]	;dx = left mask
endif	; UNIT_MASK

	mov	ax, es:[W_clipRect.R_right]
	mov	bx, ax
if	BIT_SHIFTS lt 0
	shl	ax, -BIT_SHIFTS
elif	BIT_SHIFTS eq 0
	; <no shift>
elif	BIT_SHIFTS eq 1 or BIT_SHIFTS eq 2
	shr	ax, BIT_SHIFTS
else	; BIT_SHIFTS gt 2
	shr	ax, cl
endif	; BIT_SHIFTS lt 0

if	BIT_SHIFTS le 2
	cmp	ax,ds:[si].SUS_rightUnit ;if right side is not is same word
else
	cmp	al,ds:[si].SUS_rightUnit ;if right side is not is same word
endif	; BIT_SHIFTS le 2
	jnz	RS_notSimple		;then use special routine
ifdef	UNIT_MASK
	and	bx,UNIT_MASK
	ShiftLeftIf16	bx			;;convert to byte
	mov	A_REG,ds:[bx][rightMaskTable]	;ax = right mask
endif	; UNIT_MASK

	push	bp
	push	es
	SetBuffer	es, bx
	call	RestoreSimpleRect
	pop	es
	pop	bp

	; loop if not all done

RS_beforeNext:

	segmov	ds,cs
	xchg	si,ds:[d_bytes]		;save index, get saveAddr

RS_next:
	add	ds:[d_y1],bp
	sub	ds:[d_lineCount],bp
	jz	RS_toEnd
	jmp	RS_loop
RS_toEnd:

	GOTO	SS_common

;------------------------------

	; not simple region

RS_notSimple:

	; ensure that line buffer is valid

	push	si
	push	ds
	segmov	ds,es
	call	ValLineMask
	pop	ds
	pop	si

	push	bp
	push	es
	SetBuffer	es, ax
	call	RestoreMaskedRect
	pop	es
	pop	bp

	jmp	short RS_beforeNext

;-----------------------------

	; null region

RS_null:
	; OK.  There's nothing that can be recovered for BP number of lines, so
	; we just want to bump both pointers down by this many lines.  This
	; case was never dealt with before, the result being that screen data
	; would just end up beng recovered for the wrong portions of the screen.
	; -- Doug  3/28/93
	;
	; ds:[d_bytes] is the pointer to saved screen data
	; di is the offset to screen data
	; bp is the # of scan lines down we want to go, for both d_bytes & di
	;

	; First, calculate how far to move down in saved screen data, to
	; get past BP number of lines
	;
if	BIT_SHIFTS le 2
	mov	ax, ds:[si].SUS_unitsPerLine	; "units" per scan line
else
	mov	al, ds:[si].SUS_unitsPerLine	; "units" per scan line
	clr	ah			; extend to word value
endif	; BIT_SHIFTS le 2
	mul	bp			; multiply by number of lines
ifdef	IS_16
LVR <	shldw	dxax			; times 2, as unit is 2 bytes	>
SVR <	shl	ax, 1			; times 2, as unit is 2 bytes	>
endif
	;
	; If our save under buffer uses a HALF_SCREEN, then we need to
	; advance through the save under buffer line by line and not
	; by adding the number of bytes to d_bytes.
	;
ifndef HALF_SCREEN
LVR <	adddw	ds:[src], dxax		; add to saved-under data ptr	>
SVR <	add	ds:[d_bytes], ax	; add to saved-under data ptr	>
else
	;
	; It is assumed that d_bytes points to the beginnin of a save
	; under scan line.
	;
	push	ax, cx, dx
	clr 	dx
	mov	cx, ALT_BUFFER_BYTE_WIDTH 
	div	cx
	mov_tr	cx, ax
	mov	ax, ds:[d_bytes]

RS_saveUnderLineUpdateLoop:
	NextSaveScan ax, 0
	loop	RS_saveUnderLineUpdateLoop
	add	ax, dx
	mov	ds:[d_bytes], ax

	pop	ax, cx, dx
endif ; HALF_SCREEN
  
	; Next, move screen pointer down BP number of lines.
	; NOTE:  This doesn't happen that often, so it's OK to just slow-boat
	; a  correct answer.  Loop to bump screen pointer enough scan lines
	; to get to next area.
	;
	push	cx			; practice "safe bug fixing"
	mov	cx, bp			; get # of lines in cx
RS_screenLineUpdateLoop:
LVR <NextScanLVR	ds:[dest]	; bump down one line		>
SVR <NextScan	di		; bump down one line			>
	loop	RS_screenLineUpdateLoop	; loop for each line
	pop	cx

	jmp	short RS_next

RestoreScreen	endp
	public	RestoreScreen

COMMENT @-----------------------------------------------------------------------

FUNCTION:	RestoreSimpleRect

DESCRIPTION:	Restore a simple rectangle that has no holes and just needs
		masking at the sides

CALLED BY:	INTERNAL
		RestoreScreen

PASS:
	si - index to save under entry
	ds - cs

	ifdef	LARGE_VIDEO_RAM
		[src] - source address for screen data
		[dest] - destination address for screen data
	else
		[d_bytes] - source address for screen data
		es:di - destination address for screen data
	endif

	ifdef	UNIT_MASK
		dx - mask for left word
		ax - mask for right word
	endif

	SUS_unitsPerLine - number of words per line
	bp - number of lines
	SUS_scanMod - value to add to get to next scan line

RETURN:
	ifdef	LARGE_VIDEO_RAM
		[src] - updated pointer for screen data
		[dest] - updated
	else
		si - updated pointer for screen data
		di - updated
	endif

	[d_bytes] - si passed

DESTROYED:
	ax, bx, cx, dx, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@


RestoreSimpleRect	proc	near
ifdef	UNIT_MASK
	mov	ds:[RSR_leftMask],D_REG
	mov	ds:[RSR_rightMask],A_REG
endif	; UNIT_MASK

	;
	; Clear the prefetch queue to allow the above self-modifying code to
	; take effect.
	;
	jmp	$+2			; prefetch queue-clearing NOP

	mov	dx,ds:[si].SUS_scanMod
if	BIT_SHIFTS le 2
	mov	bx,ds:[si].SUS_unitsPerLine
else
	mov	bl,ds:[si].SUS_unitsPerLine
	clr	bh
endif	; BIT_SHIFTS le 2
ifdef	UNIT_MASK
	; decrease # units by 1 for left unit and 1 for right unit, because
	; the loop handles them specially.
	dec	bx
	dec	bx
endif	; UNIT_MASK
LVR <	mov	ds:[unitsToMove].low, bx				>
LVR <	clr	ds:[unitsToMove].high					>

	xchg	si,ds:[d_bytes]		;save index, get saveAddr

	; saveAddr has no meaning for Casio driver.  Do the right thing
CASIO <	mov	si, di			; source is to right of dest 	>
CASIO <	add	si, SCREEN_BYTE_WIDTH					>

ifdef	IS_HALF_SCREEN
	; Adjust ds to point to video memory, and determine starting
	; values from 'si' source.
	segmov	ds, es, cx

	CalcUnitsLeft	ax, si
	push	ax

else
ALT <	SetAltBuffer	ds, cx						>
ifdef	LARGE_VIDEO_RAM
ALT <	; Analogous to SetAltBuffer above, convert 32-bit offset in	>
ALT <	; save-under area to offset in video RAM.			>
ALT <	adddw	cs:[src], cs:[suSaveAreaStart], cx			>
endif	; LARGE_VIDEO_RAM
endif

NOALT <	mov	ds,ds:[suSaveSegment]					>

	; do copy: bp = # lines, ds:si = source, es:di = dest, bx = words/line
	;	   dx = value to add to move to next scan line

RSR_loop:

	; do left word specially
HALF<	pop	ax		; retreive # of units left in line	>
HALF<	tst	ax							>
HALF<	jz	RSR_adjustLeft						>
HALF<RSR_afterAdjustLeft:						>
HALF<	dec	ax			; remove Left Unit		>
HALF<	push	ax							>

ifdef	UNIT_MASK

ifdef	IS_VGALIKE
	push	dx
	push	bx
	mov	dx,GR_CONTROL
	mov	al,BITMASK
LabelUnit	RSR_1
RSR_leftMask	=	RSR_1 + 1
	mov	ah,12h
	out	dx,ax			;set mask
	ReadBitPlanes		ds, si, bh, bl, ch, cl
	StartBitWrite
	WriteBitPlanes	es, di, bh, bl, ch, cl
	EndBitWrite
	mov	ah,0ffh
	out	dx,ax
	pop	bx
	inc	si
	inc	di
endif

ifdef	IS_NIKE_COLOR
	push	dx
	lodsw
	mov_tr	cx, ax
	lodsw
	mov_tr	dx, ax
LabelUnit	RSR_1
RSR_leftMask	=	RSR_1 + 1
	mov	ah,12h
	and	cl, ah
	and	ch, ah
	and	dl, ah
	and	dh, ah
	not	ah
	mov	al, es:[di]
	and	al, ah
	or	cl, al
	mov	al, es:[di]
	and	al, ah
	or	ch, al
	mov	al, es:[di]
	and	al, ah
	or	dl, al
	mov	al, es:[di]
	and	al, ah
	or	dh, al
	WriteOneByte	es,di,	cl,ch,dl,dh
endif	; IS_NIKE_COLOR

ifdef	IS_BITMAP
ifndef	IS_MEGA
ifdef	LARGE_VIDEO_RAM
	push	dx		; save value to add to move to next line
	movdw	axsi, cs:[src]
	call	SetWinNoOffsetSrc	; ds:si = addr to read
	movdw	axdi, cs:[dest]
	call	SetWinNoOffset		; es:di = addr to write
endif	; LARGE_VIDEO_RAM
	LOAD_UNIT		;get left word
LabelUnit	RSR_1
RSR_leftMask	=	RSR_1 + 1
	mov	C_REG,12h
ifdef	REVERSE_WORD
	xchg	ch, cl
endif
	and	A_REG,C_REG		;ax = new bits
	not	C_REG
	and	C_REG,es:[di]	;cx = old bits
	or	A_REG,C_REG
	STORE_UNIT
ifdef	LARGE_VIDEO_RAM
IS8 <	adddw	cs:[src], <size byte>					>
IS8 <	adddw	cs:[dest], <size byte>					>
IS16 <	adddw	cs:[src], <size word>					>
IS16 <	adddw	cs:[dest], <size word>					>
endif	; LARGE_VIDEO_RAM
endif	; !IS_MEGA
endif	; IS_BITMAP

endif	; UNIT_MASK

	; do middle words

	mov	cx, bx
HALF<	pop	ax							>
HALF<	sub	ax, cx							>
HALF<	jb	RSR_trimMiddle						>
HALF<RSR_afterTrim:							>

ifdef	IS_NIKE_COLOR	; Move 4 times for Nike color - once for each bit plane
SS_30$:	lodsw
	mov_tr	dx, ax
	lodsw
	WriteOneByte	es,di, dl,dh,al,ah
	loop	SS_30$
else
LVR <	call	SaveUnderMemMove					>
SVR <	MoveStrUnit							>
endif

HALF<	tst	ax							>
HALF<	jz	RSR_adjustRight						>
HALF<RSR_afterAdjustRight:						>
HALF<	dec	ax			; remove Right Unit		>
HALF<	push	ax		; save # of units left in line		>

ifdef	UNIT_MASK

	; do right word specially
ifdef	IS_VGALIKE
	push	bx
	mov	dx,GR_CONTROL
	mov	al,BITMASK
LabelUnit	RSR_2
RSR_rightMask	=	RSR_2 + 1
	mov	ah,12h
	out	dx,ax			;set mask
	ReadBitPlanes		ds, si, bh, bl, ch, cl
	StartBitWrite
	WriteBitPlanes	es, di, bh, bl, ch, cl
	EndBitWrite
	pop	bx
	pop	dx
	inc	si
	inc	di
endif

ifdef	IS_NIKE_COLOR
	lodsw
	mov_tr	cx, ax
	lodsw
	mov_tr	dx, ax
LabelUnit	RSR_2
RSR_rightMask	=	RSR_2 + 1
	mov	ah,12h
	and	cl, ah
	and	ch, ah
	and	dl, ah
	and	dh, ah
	not	ah
	mov	al, es:[di]
	and	al, ah
	or	cl, al
	mov	al, es:[di]
	and	al, ah
	or	ch, al
	mov	al, es:[di]
	and	al, ah
	or	dl, al
	mov	al, es:[di]
	and	al, ah
	or	dh, al
	WriteOneByte	es,di,	cl,ch,dl,dh
	pop	dx
endif	; IS_NIKE_COLOR

ifdef	IS_BITMAP
ifndef	IS_MEGA
ifdef	LARGE_VIDEO_RAM
	movdw	axsi, cs:[src]
	call	SetWinNoOffsetSrc	; ds:si = addr to read
	movdw	axdi, cs:[dest]
	call	SetWinNoOffset		; es:di = addr to write
	pop	dx		; restore value to add to move to next line
endif	; LARGE_VIDEO_RAM
	LOAD_UNIT		;get right word
LabelUnit	RSR_2
RSR_rightMask	=	RSR_2 + 1
	mov	C_REG,12h
ifdef	REVERSE_WORD
	xchg	ch, cl
endif
	and	A_REG,C_REG	;ax = new bits
	not	C_REG
	and	C_REG,es:[di]	;cx = old bits
	or	A_REG,C_REG
	STORE_UNIT
ifdef	LARGE_VIDEO_RAM
IS8 <	adddw	cs:[src], <size byte>					>
IS8 <	adddw	cs:[dest], <size byte>					>
IS16 <	adddw	cs:[src], <size word>					>
IS16 <	adddw	cs:[dest], <size word>					>
endif	; LARGE_VIDEO_RAM
endif	; !IS_MEGA
endif	; IS_BITMAP

endif	; UNIT_MASK

LVR <	NextScanLVR	ds:[dest], dx					>
SVR <	NextScan di, dx							>
CASIO <	mov	si, di							>
CASIO < add	si, SCREEN_BYTE_WIDTH					>
	dec	bp
EGA <	jz	RSR_done						>
EGA <	jmp	RSR_loop						>
EGA <RSR_done:								>

NIKEC <	LONG jnz	RSR_loop					>
BIT <	LONG jnz	RSR_loop					>

ifdef 	IS_HALF_SCREEN
	pop	ax							
	tst	ax							
	jnz	noAdjust
	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH			
noAdjust:
endif

ifdef	LARGE_VIDEO_RAM
ifdef	ALT_VIDEO_RAM
	; Since RestoreSimpleRect and RestoreMaskedRect are called in a loop
	; in RestoreScreen we need to subtract the [suSaveAreaStart] value
	; back from [src] which we added to earlier.  Otherwise, [src] will
	; be incorrect when we are called again later.
	subdw	cs:[src], cs:[suSaveAreaStart], ax
endif	; ALT_VIDEO_RAM
endif	; LARGE_VIDEO_RAM

	ret

ifdef	IS_HALF_SCREEN
RSR_adjustLeft:
	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH
IS8<	mov	ax, ALT_BUFFER_BYTE_WIDTH				>
IS16<	mov	ax, ALT_BUFFER_BYTE_WIDTH / 2				>
	jmp	short	RSR_afterAdjustLeft

RSR_trimMiddle:
	add	cx, ax					; cx # to transfer

ifdef	IS_NIKE_COLOR	; Move 4 times for Nike color - once for each bit plane
	push	ax
SS_30$:	lodsw
	mov_tr	dx, ax
	lodsw
	WriteOneByte	es,di, dl,dh,al,ah
	loop	SS_30$
	pop	ax
else
	MoveStrUnit					; move remainder of line
endif

	mov	cx, ax					; cx # left to transfer
	neg	cx

IS8<	add	ax, ALT_BUFFER_BYTE_WIDTH				>
IS16<	add	ax, ALT_BUFFER_BYTE_WIDTH / 2				>

	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH

ifdef	HAS_EXTRA_ALT
	IsInExtraAlt
	jc	RSR_afterTrim

	mov	ax, EXTRA_ALT_BUFFER_SIZE
endif
	jmp	RSR_afterTrim

RSR_adjustRight:
	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH

	mov	ax, (BUFFER_BYTE_WIDTH - SCREEN_BYTE_WIDTH) / 2
	jmp	short	RSR_afterAdjustRight
endif
RestoreSimpleRect	endp
	public	RestoreSimpleRect

COMMENT @-----------------------------------------------------------------------

FUNCTION:	RestoreMaskedRect

DESCRIPTION:	Restore a masked rectangle

CALLED BY:	INTERNAL
		RestoreScreen

PASS:
	si - index to save under entry
	ds - cs

	ifdef	LARGE_VIDEO_RAM
		[src] - source address for screen data
		[dest] - destination address for screen data
	else
		[d_bytes] - source address for screen data
		es:di - destination address for screen data
	endif

	lineMaskBuffer - mask buffer for this line

	SUS_leftUnit - left word to copy
	SUS_unitsPerLine - number of words per line
	bp - number of lines
	SUS_scanMod - value to add to get to next scan line

RETURN:
	ifdef	LARGE_VIDEO_RAM
		[src] - updated pointer for screen data
		[dest] - updated
	else
		si - updated pointer for screen data
		di - updated
	endif

	[d_bytes] - si passed

DESTROYED:
	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

RestoreMaskedRect	proc	near
	mov	ax,ds:[si].SUS_scanMod
LVR <	StoreNextScanModLVR	<ds:[RMR_nextScanOffset]>,ax		>
SVR <	StoreNextScanMod	<ds:[RMR_nextScanOffset]>,ax		>

if	BIT_SHIFTS le 2
	; The original code uses currentDrawMode as a temporary variable for
	; the count, but we can't since we need a word variable here.  So
	; we have to use a separate one.
	mov	ax,ds:[si].SUS_unitsPerLine
	mov	ds:[unitsPerLine], ax
	mov	ax, ds:[si].SUS_leftUnit
else
	mov	al,ds:[si].SUS_unitsPerLine
	mov	ds:[currentDrawMode],al
	mov	al,ds:[si].SUS_leftUnit
	clr	ah
endif	; BIT_SHIFTS le 2

	; *** Custom code depending on # bits per pixel and # bits of driver.
	; Convert initial unit # to initial mask bit pos.
if	BIT_SHIFTS le 0
	push	ax			; save left unit #
if	BIT_SHIFTS lt 0
	shr	ax, -BIT_SHIFTS		; convert unit # to pixel #
endif	; BIT_SHIFTS lt 0
IS8 <	andnf	al, 0x07						>
IS16 <	andnf	al, 0x0f						>
	mov	ds:[leftMaskBitPos], al
	pop	ax			; ax = left unit #
endif	; BIT_SHIFTS le 0

	; Convert unit offset of pixel to byte offset in lineMaskBuffer.
if	BIT_SHIFTS lt 3
	shr	ax, 3 - BIT_SHIFTS
IS16 <	andnf	ax, 0xfffe		; align at word boundary	>
elif	BIT_SHIFTS eq 3
	; <no shift>
IS16 <	andnf	ax, 0xfffe		; align at word boundary	>
else	; BIT_SHIFTS gt 3
	shl	ax, BIT_SHIFTS - 3	; already word-aligned
endif	; BIT_SHIFTS lt 3

	add	ax,offset dgroup:lineMaskBuffer
	mov	ds:[d_x1],ax

	xchg	si,ds:[d_bytes]		;save index, get saveAddr

	; saveAddr has no meaning for Casio driver.  Do the right thing
CASIO <	mov	si, di			; source is to right of dest 	>
CASIO <	add	si, SCREEN_BYTE_WIDTH					>

NOALT <	mov	ds,ds:[suSaveSegment]					>

ifdef	IS_HALF_SCREEN
	segmov	ds, es, cx

	; Adjust ds to point to video memory, and determine starting
	; values from 'si' source.
	CalcUnitsLeft	ax, si			; ax <- # of units left in line
else
ALT <	SetAltBuffer	ds, cx						>
ifdef	LARGE_VIDEO_RAM
ALT <	; Analogous to SetAltBuffer above, convert 32-bit offset in	>
ALT <	; save-under area to offset in video RAM.			>
ALT <	adddw	cs:[src], cs:[suSaveAreaStart], cx			>
endif	; LARGE_VIDEO_RAM
endif

ifdef	LARGE_VIDEO_RAM
	movdw	axsi, cs:[src]
	FirstWinNoOffsetSrc		; ds:si = addr to read
	movdw	axdi, cs:[dest]
	FirstWinNoOffset		; es:di = addr to write
	mov	dx, cs:[dest].high	; dx = dest win #
	call	CalcLastScanPtr		; ax = offset to last scan line
	mov	cs:[lastWinPtr], ax
endif	; LARGE_VIDEO_RAM
	
	; do copy: bp = # lines, ds:si = source, es:di = dest, cs:bx = mask
	; if IS_HALF_SCREEN : ax = # if units left in scan line
RMR_loop:
if	BIT_SHIFTS le 2
	mov	cx, cs:[unitsPerLine]
else
	mov	cl,cs:[currentDrawMode]
	clr	ch
endif	; BIT_SHIFTS le 2
	mov	bx,cs:[d_x1]
HALF<	push	bp				; save # of lines	>
HALF<	mov_tr	bp, ax				; bp <- # of units left	>
	
	; *** Custom code depending on # bits per pixel and # bits of driver.
	; Read initial mask.
if	BIT_SHIFTS le 0
	push	cx		; save units per line
	mov	D_REG, cs:[bx]
IS16 <	xchg	dl, dh		; high bit of low byte goes first	>
	mov	cl, cs:[leftMaskBitPos]
	shl	D_REG, cl	; fast-forward to first mask bit used
IS8 <	sub	cl, 8							>
IS16 <	sub	cl, 16							>
	neg	cl
	mov	cs:[maskBitsLeft], cl
	pop	cx		; cx = units per line
endif	; BIT_SHIFTS le 0

RMR_innerLoop:

ifdef	IS_VGALIKE
	mov	dx,GR_CONTROL
	mov	al,BITMASK
	mov	ah,cs:[bx]
	out	dx,ax			;set mask
	push	bx
	push	cx
	ReadBitPlanes		ds, si, bh, bl, ch, cl
	StartBitWrite
	WriteBitPlanes	es, di, bh, bl, ch, cl
	EndBitWrite
	pop	cx
	pop	bx
	inc	si
	inc	di
endif

ifdef	IS_NIKE_COLOR
	push	cx
	lodsw
	mov_tr	cx, ax
	lodsw
	mov_tr	dx, ax
	mov	ah, cs:[bx]
	and	cl, ah
	and	ch, ah
	and	dl, ah
	and	dh, ah
	not	ah
	mov	al, es:[di]
	and	al, ah
	or	cl, al
	mov	al, es:[di]
	and	al, ah
	or	ch, al
	mov	al, es:[di]
	and	al, ah
	or	dl, al
	mov	al, es:[di]
	and	al, ah
	or	dh, al
	WriteOneByte	es,di,	cl,ch,dl,dh
	pop	cx
endif	; IS_NIKE_COLOR

ifdef	IS_BITMAP

	; *** Custom code depending on # bits per pixel and # bits of driver.
	; Restore pixels
if	BIT_SHIFTS le 0

	LOAD_UNIT			;get source
	shl	D_REG			;put mask for this pixel in CF
	jc	write

	; Mask is 0.  Skip this src pixel.
if	BIT_SHIFTS eq 0
	; <no-op>
elif	BIT_SHIFTS eq -1
	LOAD_UNIT			; skip the rest of this src pixel
elif	BIT_SHIFTS eq -2
	LOAD_UNIT			; skip the rest of this src pixel
	LOAD_UNIT			; skip the rest of this src pixel
	LOAD_UNIT			; skip the rest of this src pixel
else	; BIT_SHIFTS lt -2
	ErrMessage <Need to add custom code here.>
endif	; BIT_SHIFTS eq 0
	; Skip this dest pixel.
	addnf	di, <BITS_PER_PIXEL / 8>
	jmp	afterWrite

write:
	; Mask is 1.  Write old pixel to screen.
	STORE_UNIT
if	BIT_SHIFTS eq 0
	; <no-op>
elif	BIT_SHIFTS eq -1
	LOAD_UNIT			; read the rest of this src pixel
	STORE_UNIT			; write the rest of this dest pixel
elif	BIT_SHIFTS eq -2
	LOAD_UNIT			; read the rest of this src pixel
	STORE_UNIT			; write the rest of this dest pixel
	LOAD_UNIT			; read the rest of this src pixel
	STORE_UNIT			; write the rest of this dest pixel
	LOAD_UNIT			; read the rest of this src pixel
	STORE_UNIT			; write the rest of this dest pixel
else	; BIT_SHIFTS lt -2
	ErrMessage <Need to add custom code here.>
endif	; BIT_SHIFTS eq 0

afterWrite:

elif	BITS_PER_PIXEL eq 1

	LOAD_UNIT			;get source
	mov	D_REG,cs:[bx]		;get mask
	and	A_REG,D_REG		;ax = new bits
	not	D_REG
	and	D_REG,es:[di]		;di = old bits
	or	A_REG,D_REG
	STORE_UNIT

else

	ErrMessage <Need to add custom code here.>

endif	; BIT_SHIFTS le 0

endif

HALF<	dec	bp							>
HALF<	jz	RMR_skipToEnd						>
HALF<RMR_afterSkip:							>

ifdef	LARGE_VIDEO_RAM
if	BITS_PER_PIXEL gt 8
	add	cs:[src].low, BITS_PER_PIXEL / 8	; advance 1 pixel
elif	BITS_PER_PIXEL eq 8
	inc	cs:[src].low		; advance 1 pixel
elif	BITS_PER_PIXEL eq 1
IS8 <	inc	cs:[src].low		; advance 1 unit		>
IS16 <	add	cs:[src].low, size word	; advance 1 unit		>
else
	ErrMessage <Need to add custom code here.>
endif	; BITS_PER_PIXEL gt 8

	jnz	afterSrc
	push	dx			; save mask bits
	NextWinNoOffsetSrc
	pop	dx			; restore mask bits
	inc	cs:[src].high		; carry over
afterSrc:

if	BITS_PER_PIXEL gt 8
	add	cs:[dest].low, BITS_PER_PIXEL / 8	; advance 1 pixel
elif	BITS_PER_PIXEL eq 8
	inc	cs:[dest].low		; advance 1 pixel
elif	BITS_PER_PIXEL eq 1
IS8 <	inc	cs:[dest].low		; advance 1 unit		>
IS16 <	add	cs:[dest].low, size word	; advance 1 unit	>
else
	ErrMessage <Need to add custom code here.>
endif	; BITS_PER_PIXEL gt 8

	jnz	afterDest
	push	dx			; save mask bits
	NextWinNoOffset
	pop	dx			; restore mask bits
	inc	cs:[dest].high		; carry over
afterDest:
endif	; LARGE_VIDEO_RAM

	; *** Custom code depending on # bits per pixel and # bits of driver.
	; Decrement mask bit counter.
if	BIT_SHIFTS le 0
	dec	cs:[maskBitsLeft]
	jnz	RMR_innerLoopNext	; => no need to read next mask word
IS8 <	mov	cs:[maskBitsLeft], 8					>
IS16 <	mov	cs:[maskBitsLeft], 16					>
endif	; BIT_SHIFTS le 0

	inc	bx
	IncIf16	bx		;;move to next unit

	; *** Custom code depending on # bits per pixel and # bits of driver.
	; Read mask for the next pixels.
if	BIT_SHIFTS le 0
	mov	D_REG, cs:[bx]
IS16 <	xchg	dl, dh		; high bit of low byte goes first	>
endif	; BIT_SHIFTS le 0

RMR_innerLoopNext::
	; *** Custom code depending on # bits per pixel and # bits of driver.
if	BIT_SHIFTS lt 0
	; For multiple-unit-per-pixel displays, RMR_innerLoop is traversed
	; once for each pixel, not once for each unit.  Hence we need to
	; adjust the unit counter in CX accordingly.
	subnf	cx, <(1 shl -BIT_SHIFTS)  - 1>
endif	; BIT_SHIFTS lt 0
	loop	RMR_innerLoop

LVR <	NextScanModLVR	cs:[dest], RMR_nextScanOffset			>
LVR <	mov	di, cs:[dest].low					>
SVR <	NextScanMod	di, RMR_nextScanOffset				>
CASIO <	mov	si, di			; save area is to right		>
CASIO <	add	si, SCREEN_BYTE_WIDTH					>

HALF <	mov_tr	ax, bp							>
HALF <	pop	bp							>
	dec	bp
	jnz	RMR_loop

ifdef	LARGE_VIDEO_RAM
ifdef	ALT_VIDEO_RAM
	; Since RestoreSimpleRect and RestoreMaskedRect are called in a loop
	; in RestoreScreen we need to subtract the [suSaveAreaStart] value
	; back from [src] which we added to earlier.  Otherwise, [src] will
	; be incorrect when we are called again later.
	subdw	cs:[src], cs:[suSaveAreaStart], ax
endif	; ALT_VIDEO_RAM
endif	; LARGE_VIDEO_RAM

	ret

ifdef	IS_HALF_SCREEN
RMR_skipToEnd:
	NextSaveScan	si, -ALT_BUFFER_BYTE_WIDTH

IS8<	mov	bp, ALT_BUFFER_BYTE_WIDTH				>
IS16<	mov	bp, ALT_BUFFER_BYTE_WIDTH / 2				>
	jmp	short	RMR_afterSkip
endif
RestoreMaskedRect	endp
	public	RestoreMaskedRect

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SaveUnderCollision

DESCRIPTION:	Handle a save under collision

CALLED BY:	INTERNAL
		DoAlloc, MemInfoHeap

PASS:
	ah - suCount - (number of save under area hit) - 1
		suCount-1 -> suTable[0]
		0 -> suTable[suCount-1]
	es - window

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
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

SaveUnderCollision	proc	near
	push	ax, bx, cx, dx, si, di, bp, ds

	segmov	ds, cs
ifndef	IS_CASIO
	mov	al,ds:[suCount]
	dec	al
	sub	al,ah
	mov	bl,size SaveUnderStruct
	mul	bl
	mov_tr	si,ax
	add	si,offset dgroup:suTable
else
	mov	si, offset dgroup:suTable
endif
	mov	ax,ds:[si].SUS_left
	mov	bx,ds:[si].SUS_top
	mov	cx,ds:[si].SUS_right
	mov	dx,ds:[si].SUS_bottom
	mov	di,word ptr ds:[si].SUS_flags
	mov	bp,ds:[si].SUS_parent		; pass parent window of
						; 	save-under win in bp
	mov	si,ds:[si].SUS_window		; pass save under win in si
	call	WinMaskOutSaveUnder
	pop	ax, bx, cx, dx, si, di, bp, ds
	ret

SaveUnderCollision	endp
	public	SaveUnderCollision

ifdef	ALT_VIDEO_RAM
ifdef	LARGE_VIDEO_RAM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveUnderMemMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move data within large video RAM using read and write windows.

CALLED BY:	INTERNAL
PASS:		cs:[src]	= 32-bit linear offset within video RAM
		cs:[dest]	= 32-bit linear offset within video RAM
		cs:[unitsToMove]= # bytes/words to move
RETURN:		cs:[src]	= past end of src
		cs:[dest]	= past end of dest
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/20/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveUnderMemMove	proc	near
unitsLeft	local	dword	push	cs:[unitsToMove].high, \
					cs:[unitsToMove].low
len2		local	word
len3		local	word
	ForceRef	unitsLeft	; used in SUMMAdjLenAndMove
	uses	ds, es
	.enter
	pusha

	;
	; If src.low <= dest.low, we want: (a = src.low, b = dest.low)
	;	len1 = 64K - b
	;	len2 = b - a
	;	len3 = 64K - (b - a)
	;
	mov	di, cs:[dest].low	; di = dest.low = b
	mov	ax, di			; ax = b
	neg	ax			; ax = -b = 64K - b
	mov	cx, ax			; cx = len1 = 64K - b
	mov	si, cs:[src].low	; si = src.low = a
	add	ax, si			; ax = 64K - (b - a)
	mov	ss:[len3], ax		; len3 = 64K - (b - a)
	neg	ax			; ax = (b - a) - 64K = b - a
	mov	ss:[len2], ax		; len2 = b - a
	clr	bx			; bx = 0, assume src.low <= dest.low

	cmp	si, di
	jbe	hasLengths		; jump if src.low <= dest.low

	;
	; Else, src.low > dest.low, we want: (a = src.low, b = dest.low)
	;	len1 = 64K - a
	;	len2 = a - b
	;	len3 = 64K - (a - b)
	;
	mov	cx, si			; cx = a
	neg	cx			; cx = len1 = -a = 64K - a
	neg	ss:[len2]		; len2 = a - b
	neg	ss:[len3]		; len3 = (b - a) - 64K = b - a
					;  = - (a - b) = 64K - (a - b)

	inc	bx			; bx = 1, src.low > dest.low

hasLengths:
	; For 16-bit drivers, convert # bytes to # words.
	ShiftRightIf16	cx
	ShiftRightIf16	ss:[len2]
	ShiftRightIf16	ss:[len3]

ifdef	IS_16
	;
	; Special case: for 16-bit drivers, if len3 = 0, it really means
	; len3 = 32768.  We handle this by manually storing the correct length.
	;
	jnz	step1			; using ZF from ShiftRightIf16 above
	mov	ss:[len3].high, 32768 shr 8	; len3 = 32768
endif	; IS_16

step1::
	;
	; STEP 1.
	;
	mov	ax, cs:[dest].high
	FirstWinNoOffset		; es = segment to write
	mov	ax, cs:[src].high
	FirstWinNoOffsetSrc		; ds = segment to read

	call	SUMMAdjLenAndMove	; CF clear if done
	jnc	done

step2:
	;
	; STEP 2.
	;
	tst	bx			; bx = 0 if src.low <= dest.low
	jz	s2AdjWinDest
	NextWinNoOffsetSrc
	jmp	s2GetLen
s2AdjWinDest:
	NextWinNoOffset

s2GetLen:
	mov	cx, ss:[len2]
	call	SUMMAdjLenAndMove	; CF clear if done
	jnc	done

step3::
	;
	; STEP 3.
	;
	tst	bx			; bx = 0 if src.low <= dest.low
	jz	s3AdjWinSrc
	NextWinNoOffset
	jmp	s3GetLen
s3AdjWinSrc:
	NextWinNoOffsetSrc

s3GetLen:
	mov	cx, ss:[len3]

ifdef	IS_8
	;
	; Special case: for 8-bit drivers, if len3 = 0, it really means
	; len3 = 65536.  We handle this by moving 1 byte here and then
	; 65535 bytes later.  (We know there is at least one byte left.)
	;
	tst	cx
	jnz	s3Move
	MOVE_UNIT
	dec	cx			; cx = 65535
	adddw	ss:[unitsLeft], cxcx	; cxcx = 0xffffffff = -1
s3Move:
endif	; IS_8

	call	SUMMAdjLenAndMove	; CF clear if done
	jc	step2

done:
	;
	; Update src and dest.
	;
	movdw	dxax, cs:[unitsToMove]
IS16<	shldw	dxax			; convert to bytes		>
	adddw	cs:[src], dxax
	adddw	cs:[dest], dxax

	popa
	.leave
	ret
SaveUnderMemMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SUMMAdjLenAndMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move data within current src and dest window bounds.

CALLED BY:	INTERNAL
		SaveUnderMemMove
PASS:		ds:si	= src addr
		es:di	= dest addr
		cx	= max # bytes/words allowed to move within current
			  window bounds (0x0000 means zero byte/word).  Actual
			  # bytes moved may be limited by ss:[unitsLeft].
		bp	= inherited stack frame
RETURN:		si	= updated src offset
		di	= updated dest offset
		cx, dx	= 0
		ss:[unitsLeft] deducted by # bytes moved
		CF clear if done
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	4/21/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SUMMAdjLenAndMove	proc	near
	.enter inherit SaveUnderMemMove

	clr	dx			; dxcx = len
	cmpdw	dxcx, ss:[unitsLeft]	; CF clear iff dxcx >= unitsLeft
	jbe	deductTotal
	mov	cx, ss:[unitsLeft].low	; dxcx = unitsLeft
deductTotal:
	pushf				; save CF from "cmpdw"
	subdw	ss:[unitsLeft], dxcx
	MoveStrUnit
	popf				; return CF clear if done

	.leave
	ret
SUMMAdjLenAndMove	endp

endif	; LARGE_VIDEO_RAM
endif	; ALT_VIDEO_RAM

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVidCheckRectBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check rectangle bounds

CALLED BY:	VidCheckUnder
		VidSaveUnder
		SaveScreen

PASS:		ax - left
		bx - top
		cx - right
		dx - bottom

RETURN:		doesn't if bad bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECVidCheckRectBounds	proc	near
	cmp	ax, cx
	ERROR_G	VIDEO_BAD_SAVE_UNDER_BOUNDS
	cmp	bx, dx
	ERROR_G	VIDEO_BAD_SAVE_UNDER_BOUNDS
	ret
ECVidCheckRectBounds	endp
endif
