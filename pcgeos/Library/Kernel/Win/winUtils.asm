COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Win -- utility functions
FILE:		winUtils.asm

AUTHOR:		Doug Fults

ROUTINES:
	Name			Description
	----			-----------
INT	WinLockFromDI		Locks window from window or gstate passed
INT	WinHandleFromDI		Get win handle from window or gstate passed
INT	SwapESDS		Guess what this one does...
INT	SetupWinReg		Stuff W_winReg from passed parameters
INT	SetupOtherReg		Stuff some window reg. from passed parameters
INT	WinSetReg		Set region in window from far pointer
INT	SetChangeBounds		Set changing screen bounds to W_winReg
INT	ExpandChangeBounds	Get MAX rectangular bounds of old Change bounds
				& new rectangle, put in change bounds
INT	SetValidateFlags	Setup wValidateFlags for window validation rtns
INT	WinPLockAndMaybeMark	PLock window, check for DELAYED_V mode
INT	WinUnlockAndMaybeV	Unlock window, V if not DELAYED_V mode
INT	WinCallVidDriver	Call video driver for window
INT	CheckIfWinOverlapsChangeBounds	See if window overlaps wChangeBounds
INT	CheckIfChangeCompletelyInWin	See if wChangeBounds inside of window
INT	WinLockWinAndParent	Locks window & its parent on heap
INT	WinCalcWinBounds	Calculates W_winRect.R_left, Right, etc. from W_winReg
INT	LoadWinBounds		Load win bounds into registers from window vars
INT	WinCopyReg		Copy region between two different windows
INT	WinCopyLocReg		Copy region within one window
INT	WinNOTReg		NOT a win region, output goes to different win
INT	WinNOTLocReg		NOT a win region, output goes to same win
INT	WinANDORReg		AND/OR win regions, output goes to different win
INT	WinANDORLocReg		AND/OR win regions, output goes to same win
;;; INT	WinCmpReg		Compare two regions in Window struct
INT	CheckDeathVigil		EC code to make sure death is handled correctly

INT	PWinTree, VWinTree	Lock and unlock the window tree semaphore

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	10/12/88	Initial version


DESCRIPTION:


	$Id: winUtils.asm,v 1.1 97/04/05 01:16:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if	ERROR_CHECK
CheckDeathVigil	proc	far
if	(0)			; LOOKING FOR SPACE!
	pushf
	push	si
	test	ds:[W_regFlags], mask WRF_CLOSED		; dying?
	jz	CDV_90				; skip if not
				; This window is dying.  Make sure we've
				; managed to keep its state so that it appears
				; to have a NULL mask

				; IF mask is valid
	test	ds:[W_grFlags], mask WGF_MASK_VALID
	jz	CDV_10		; (if not, we don't care)
				; THEN mask must be NULL
	test	ds:[W_grFlags], mask WGF_MASK_NULL
	jnz	CDV_10
	ERROR	BAD_STATE_IN_DYING_WINDOW
CDV_10:
	mov	si, ds:[W_visReg]		; See if vis reg is null
	mov	si, ds:[si]
	cmp	{word} ds:[si], EOREGREC
	je	CDV_20
	ERROR	BAD_STATE_IN_DYING_WINDOW	; if not, fatal error.
CDV_20:


CDV_90:
	pop	si
	popf
endif
	ret
CheckDeathVigil	endp
endif




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinLockFromDI

DESCRIPTION:	Get window locked, from GState or window handle passed in di

CALLED BY:	INTERNAL

PASS:
	di - GState or window handle

RETURN:
	carry	- clear if everything OK, then:
			di - window handle
			ds - segment of window, which is NearPLock'ed
		- set if passed handle is to a gstring

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version
------------------------------------------------------------------------------@

FarWinLockFromDI proc	far
	call	WinLockFromDI
	ret
FarWinLockFromDI endp

WinLockFromDI	proc	near
	push	ax
	push	bx
WLFDI_10:
	mov	bx, di			; put handle in bx
	call	NearPLock
	mov	ds, ax			; lock block (GState or window)
	cmp	ds:[LMBH_lmemType],LMEM_TYPE_WINDOW
	jz	WLFDI_90		; if so, done

EC <	call	ECCheckGStateHandle					>

	tst	ds:[GS_gstring]		; check for gstring 
	jnz	handleGS		;  yep, deal with it
	mov	di, ds:[GS_window]	; get window handle
EC <	tst	di			; make sure valid window handle	>
EC <	ERROR_Z WIN_PASSED_GSTATE_HAS_NO_WINDOW				>

	call	NearUnlockV		; release graphics state
	jmp	short WLFDI_10

WLFDI_90:
EC <	call	ECCheckWindowHandle					>
	clc
exit:
	pop	bx
	pop	ax
	ret

	; return carry set if gstring
handleGS:
	call	NearUnlockV		; release gstate
	stc				; signal gstring
	jmp	exit
WinLockFromDI	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinHandleFromDI

DESCRIPTION:	Get window handle for window or GState passed in di

CALLED BY:	INTERNAL

PASS:
	di - GState or window handle

RETURN:
	carry	- set if passed di was for a gstring (no window attached)
			di - returned unaltered
		  else
			di - window handle (not locked or P'd)

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version
------------------------------------------------------------------------------@

FarWinHandleFromDI	proc	far
	call	WinHandleFromDI
	ret
FarWinHandleFromDI	endp

WinHandleFromDI	proc	near
	push	ax
	call	WinLockFromDI	; Get window locked
	jc	exit		; just exit if gstring
	xchg	bx, di
	call	NearUnlockV	; Then, unlock it, but keep handle
	xchg	bx, di
	clc
exit:
	pop	ax
	ret

WinHandleFromDI	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCopyLocReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies region from chunk to chunk

CALLED BY:	EXTERNAL

PASS:		*es:si	- reg1
		*es:di	- reg3

RETURN:		ds, es	- fixed up
		reg1 -> reg3

DESTROYED:	ax, cx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinCopyLocReg	proc	far
	call	WinCopyLocReg
	ret
FarWinCopyLocReg	endp

WinCopyLocReg	proc	near
	mov	cx, offset cs:WinCopyReg
	GOTO	WinCallLocRegRoutine

WinCopyLocReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCopyReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies region from chunk to chunk

CALLED BY:	EXTERNAL

PASS:		*ds:si	- reg1
		*es:di	- reg3
		NOTE:  ds & es MAY point at the same block

RETURN:		ds, es	- fixed up
		reg1 -> reg3

DESTROYED:	ax, cx, si, di

PSEUDO CODE/STRATEGY:
		Re-allocate destination chunk
		Copy data

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note that the fix-up of DS is handled by the call
		to LMemRealloc

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version
	Don	6/20/91		Cleaned up, removed unecessary push/pop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinCopyReg	proc	far
	call	WinCopyReg
	ret
FarWinCopyReg	endp

WinCopyReg	proc	near
EC <	call	FarCheckDS_ES						>
	push	si				; src chunk handle
	mov	si, ds:[si]			; get pointer to reg1
	ChunkSizePtr	ds, si, cx		; get size of reg1
	call	ReAllocESDI			; realloc chunk at *es:di
	mov	di, es:[di]
	pop	si				; src chunk handle
	mov	si, ds:[si]			; in case realloc moved things
	shr	cx, 1				; convert size to words
	jz	done
	rep	movsw				; Copy them words!
done:
EC <	call	FarCheckDS_ES						>
	ret
WinCopyReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinNOTReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS: 		*ds:si	- reg1
		*es:di	- reg3
		NOTE:  ds & es MAY point to the same block

RETURN:		ds, es	- fixed up
		NOT(reg1) -> reg3,

DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinNOTReg	proc	far
	call	WinNOTReg
	ret
FarWinNOTReg	endp

WinNOTReg	proc	near
EC <	call	FarCheckDS_ES				>
	push	si
	mov	si, ds:[si]			; get ptr to region
	cmp	word ptr ds:[si], NULL_REG	; NULL_REG?
	je	WNR_50
	cmp	word ptr ds:[si], WHOLE_REG	; WHOLE?
	je	WNR_60
	pop	si
	mov	ax, 04h
	call	GrChunkRegOp
EC <	call	FarCheckDS_ES				>
	ret
WNR_50:
	pop	si
	GOTO	WinWHOLEReg			; Change NULL -> WHOLE
WNR_60:
	pop	si
	GOTO	WinNULLReg			; Change WHOLE -> NULL
WinNOTReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinWHOLEReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set region to WHOLE

CALLED BY:	INTERNAL

PASS:		*es:di	- reg1

RETURN:		ds, es	- fixed up

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/23/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinWHOLEReg	proc	far
	call	WinWHOLEReg
	ret
FarWinWHOLEReg	endp

WinWHOLEReg	proc	near
	mov	ax, WHOLE_REG	; store a WHOLE_REG
	FALL_THRU	WinWORDReg

WinWHOLEReg	endp





COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinWORDReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set region to word passed in bx (NULL or WHOLE)

CALLED BY:	INTERNAL
		WinNULLReg
		WinWHOLEReg

PASS:		*es:di	- reg1
		ax	- word to store into word-sized region generated

RETURN:		ds, es	- fixed up

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/90		Saving bytes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinWORDReg	proc	near
EC <	call	FarCheckDS_ES				>
	push	ax
				; Need 2 words
	call	ChunkSizeHandleES_DI_AX	; ax <- size.
	cmp	ax, 2				;
	jb	WWR_10				;
				; Allow up to 14 bytes to remain (size of rect)
	cmp	ax, 14				;
	jbe	WWR_80				;
WWR_10:
	mov	cx, 2		; size down to 2
	call	ReAllocESDI	; realloc chunk at *es:di
WWR_80:
	mov	di, es:[di]	; fetch pointer to region
	pop	ax
	mov	word ptr es:[di], ax		; store word value passed
	ret
WinWORDReg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReAllocESDI

DESCRIPTION:	Realloc chunk handle in di (in block es:0) to size in cx

CALLED BY:	EXTERNAL

DESTROYED:
	none

-------------------------------------------------------------------------------@
ReAllocESDI	proc	near
EC <	call	FarCheckDS_ES				>
				; es is LMem block
				; di is chunk handle
				; cx = new size
	mov	ax, di		; put chunk handle in ax
	call	SwapESDS
	call	LMemReAlloc	; make space for region
	FALL_THRU	SwapESDS

ReAllocESDI	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SwapESDS

DESCRIPTION:	Swap ES and DS

CALLED BY:	EXTERNAL

DESTROYED:
	none

-------------------------------------------------------------------------------@

SwapESDS	proc	near
	push	ds
	push	es
	pop	ds
	pop	es
	ret
SwapESDS	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinNOTLocReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		*es:si	- reg1
		*es:di	- reg3

RETURN:		ds, es	- fixed up
		NOT(reg1) -> reg3,

DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinNOTLocReg	proc	far
	call	WinNOTLocReg
	ret
FarWinNOTLocReg	endp

WinNOTLocReg	proc	near
	mov	cx, offset cs:WinNOTReg
	GOTO	WinCallLocRegRoutine

WinNOTLocReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinORReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:
		*ds:si	- reg1

		*es:bx	- reg2
		*es:di	- reg3
		NOTE:  ds & es MAY point to the same block

RETURN:		ds, es	- fixed up
		reg1 OR reg2 -> reg3,

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinORReg	proc	far
	call	WinORReg
	ret
FarWinORReg	endp

WinORReg	proc	near
EC <	call	FarCheckDS_ES				>
	push	bx
	push	si
	mov	si, ds:[si]	; get ptr to region
	mov	bx, es:[bx]	; get ptr to region
	cmp	word ptr ds:[si], WHOLE_REG		; OR'ing with WHOLE?
	je	WOR_50
	cmp	word ptr es:[bx], WHOLE_REG		; OR'ing with WHOLE?
	je	WOR_50
	cmp	word ptr ds:[si], NULL_REG		; OR'ing with NULL?
	je	WOR_60
	cmp	word ptr es:[bx], NULL_REG		; OR'ing with NULL?
	je	WOR_70
	pop	si
	pop	bx
	mov	ax, 0002h	; do OR operation
	call	GrChunkRegOp
EC <	call	FarCheckDS_ES				>
	ret
WOR_50:				; Result is WHOLE
	pop	si
	pop	bx
	GOTO	WinWHOLEReg
WOR_60:				; Result is es:*bx
	pop	si
	pop	bx
	mov	si, bx
	GOTO	WinCopyLocReg	; copy es:*bx to es:*di
WOR_70:				; Result is ds:*si
	pop	si
	pop	bx
	GOTO	WinCopyReg	; copy result from ds:*si to es:*di
WinORReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinORLocReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		*es:si	- reg1

		*es:bx	- reg2
		*es:di	- reg3

RETURN:		ds, es	- fixed up
		reg1 OR reg2 -> reg3,

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinORLocReg	proc	far
	call	WinORLocReg
	ret
FarWinORLocReg	endp

WinORLocReg	proc	near
	mov	cx, offset cs:WinORReg
	GOTO	WinCallLocRegRoutine
WinORLocReg	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinANDReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		*ds:si	- reg1

		*es:bx	- reg2
		*es:di	- reg3
		NOTE:  ds & es MAY point to the same block

RETURN:		ds, es	- fixed up
		reg1 AND reg2 -> reg3,

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinANDReg	proc	far
	call	WinANDReg
	ret
FarWinANDReg	endp

WinANDReg	proc	near
EC <	call	FarCheckDS_ES				>
	push	bx
	push	si
	mov	si, ds:[si]	; get ptr to region
	mov	bx, es:[bx]	; get ptr to region
	cmp	word ptr ds:[si], NULL_REG	; ANDING w/NULL?
	je	WAR_50
	cmp	word ptr es:[bx], NULL_REG	; ANDING w/NULL?
	je	WAR_50
	cmp	word ptr ds:[si], WHOLE_REG	; ANDING w/WHOLE?
	je	WAR_60
	cmp	word ptr es:[bx], WHOLE_REG	; ANDING w/WHOLE?
	je	WAR_70
	pop	si
	pop	bx
	mov	ax, 0001h	; do AND operation
	call	GrChunkRegOp
EC <	call	FarCheckDS_ES				>
	ret
WAR_50:				; Result is NULL
	pop	si
	pop	bx
	GOTO	WinNULLReg
WAR_60:				; Result is es:*bx
	pop	si
	pop	bx
	mov	si, bx
	GOTO	WinCopyLocReg		; copy es:*bx to es:*di
WAR_70:				; Result is ds:*si
	pop	si
	pop	bx
	GOTO	WinCopyReg	; copy result from ds:*si to es:*di
WinANDReg	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinANDLocReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		*es:si	- reg1

		*es:bx	- reg2
		*es:di	- reg3

RETURN:		ds, es	- fixed up
		reg1 AND reg2 -> reg3,

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FarWinANDLocReg	proc	far
	call	WinANDLocReg
	ret
FarWinANDLocReg	endp

WinANDLocReg	proc	near
	mov	cx, offset cs:WinANDReg
	FALL_THRU	WinCallLocRegRoutine

WinANDLocReg	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCallLocRegRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls routine passed in cx, around which the ds register is
		saved & patched up should it match the es register passed.

CALLED BY:	INTERNAL
		WinCopyLocReg
		WinNOTLocReg
		WinORLocReg
		WinANDLocReg

PASS:		*es:si	- reg1

		*es:bx	- reg2
		*es:di	- reg3

		cx	- near routine to call to do operation

RETURN:		ds, es	- fixed up
		reg1 OP reg2 -> reg3,

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinCallLocRegRoutine	proc	near
EC <	call	FarCheckDS_ES				>
	push	ds			; Save segs for later fixup
	push	es

	mov	ax, es
	mov	ds, ax
	call	cx			; call routine passed in cx

	pop	cx			; get original ds value
	pop	ax			; get original es value
	cmp	ax, cx			; See if segs were the same on entry
	jne	haveDSinAX		; if not, we're done.
	mov	ax, es			; exit with ds= es
haveDSinAX:
	mov	ds, ax			; copy desired ds value into ds

EC <	call	FarCheckDS_ES				>
	ret
WinCallLocRegRoutine	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SwapESTemp2Univ

DESCRIPTION:	Routines to swap two region chunks in window at es:0
		Used to help reduce memory usage of win sys

CALLED BY:	INTERNAL

DESTROYED:
	ax

-------------------------------------------------------------------------------@
SwapESTemp2Univ	proc	far
			; Swap W_univReg into W_temp2Reg
	mov	ax, es:[W_temp2Reg]
	xchg	es:[W_univReg], ax
	mov	es:[W_temp2Reg], ax
	ret
SwapESTemp2Univ	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSMALLReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make region small (size of a rectangular region)

CALLED BY:	INTERNAL

PASS:		*es:di	- reg1

RETURN:		ds, es	- fixed up

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

; WARNING: Do not call WinSMALLReg on W_temp3Reg from SetTempRegsSMALL - Joon

SetTempRegsSMALL	proc	far
	mov	di, es:[W_temp1Reg]
	call	WinSMALLReg	; Don't need W_temp1Reg anymore
	mov	di, es:[W_temp2Reg]
	FALL_THRU	FarWinSMALLReg	; Don't need W_temp2Reg anymore
SetTempRegsSMALL	endp

FarWinSMALLReg	proc	far
	call	WinSMALLReg
	ret
FarWinSMALLReg	endp

WinSMALLReg	proc	near
EC <	call	FarCheckDS_ES				>
				; Allow up to 14 bytes to remain (size of rect)
	call	ChunkSizeHandleES_DI_AX	; ax <- size.
	cmp	ax, size RectRegion
	ja	DoWinNullReg
	ret

DoWinNullReg:
				; If above that reduce to a NULL (it's nice
				; to leave 2 bytes, as when it is used next,
				; it may be NULL or WHOLE, requiring no resize)
	FALL_THRU	WinNULLReg

WinSMALLReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinNULLReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set region to NULL

CALLED BY:	INTERNAL

PASS:		*es:di	- reg1

RETURN:		ds, es	- fixed up

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/23/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinNULLReg	proc	near
	mov	ax, NULL_REG	; store a NULL_REG
	GOTO	WinWORDReg

WinNULLReg	endp

FarWinNULLReg	proc	far
	call	WinNULLReg
	ret
FarWinNULLReg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCopyPathToReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a RegionPath to a Region

CALLED BY:	UpdateClipPath()

PASS:		*DS:SI	= Path
		*ES:DI	= Destination Region
			  NOTE: DS & ES MAY point at the same block
		CX	= X window offset
		DX	= Y window offset

RETURN:		DS, ES	= Fixed up
		Path -> Region

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		Access the RegionPath
		Copy the data

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The resulting Region returned will be properly adjusted
		for the current Window offset.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinCopyPathToReg	proc	near
	.enter

	; Some set-up work
	;
EC <	call	FarCheckDS_ES						>
EC <	mov	bx, ds:[LMBH_handle]		; block handle => BX	>
EC <	call	ECCheckMemHandleFar		; verify it		>
	push	ds:[LMBH_handle]		; don't rely on handle in BX

	; Access the RegionPath, and copy away
	;
	call	WinPathValidateRegion		; Region => DS:SI
	call	ReAllocESDI			; realloc chunk at *ES:DI
	mov	di, es:[di]			; destination => ES:DI
EC <	call	FarCheckDS_ES						>
	shr	cx, 1				; convert size to words
EC <	ERROR_Z	GRAPHICS_REGION_ZERO_SIZE	; for zero-size regions >
EC <	ERROR_C	GRAPHICS_REGION_ODD_SIZE	; for odd-sized regions	>
	rep	movsw				; copy them words!
	tst	bx
	jz	done
	call	NearUnlock			; unlock Region handle
done:
	pop	bx				; Path block handle => BX
	call	MemDerefDS			; restore DS
EC <	call	FarCheckDS_ES						>

	.leave
	ret
WinCopyPathToReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSetReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies region of unknown size into chunk

CALLED BY:	EXTERNAL

PASS:	ds:si	- pointer to region
	*es:di	- seg, handle of chunk
	dx:cx - paramters in order: AX_PARAM, BX_PARAM, cx_PARAM, DX_PARAM

RETURN:		es	- new segment for block containing chunk
		cx	- size of region

DESTROYED:	ax, bx, dx, si, di

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
	Doug	8/88		Initial version
	doug	4/9/91		Fixed null region bug

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

WinSetReg	proc	far

	; get last word of region

	push	cx, dx
	push	si			; save start position
	call	GrGetPtrRegBounds	; sets si past end
	mov	cx, si
	pop	si			; get start position

	; compute size and resize chunk

	sub	cx, si			; cx = size
	call	ReAllocESDI	; realloc chunk at *es:di
	mov	di, es:[di]		; get pointer to new region
	pop	cx, dx

	mov	ax, EOREGREC		; in case null, store this..
	jmp	short WSR_start		; start by checking for NULL region

WSR_loop:
	lodsw
	call	TransRegCoord
	stosw
	cmp	ax, EOREGREC
	jnz	WSR_loop
WSR_start:
	cmp	{word} ds:[si],EOREGREC
	jnz	WSR_loop
	stosw				;store last word

	ret

WinSetReg	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TransRegCoord

DESCRIPTION:	Translate a parameterized region coordinate

CALLED BY:	INTERNAL

PASS:
	ax - coordinate to translate
	dx:cx - paramters in order: AX_PARAM, BX_PARAM, cx_PARAM, DX_PARAM

RETURN:
	ax - translated coordinate

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

TransRegCoord	proc	near

	; test for translation -- only translate if top two bits are 01 or 10
	test	ah,0c0h
	jpe	done

	cmp	ax,EOREGREC
	jz	done

	push	cx, si, ds
	mov	si,cx
	mov	ds,dx

	mov	ch,ah
	mov	cl,4
	shr	ch,cl
	mov	cl,ch
	and	cx,1110b		;bl = 4, 6, 8, a for AX, BX, CX, DX
	add	si,cx

	and	ah,00011111b		;mask off top three
	sub	ax,1000h		;make +/-
	add	ax,ds:[si][-4]

	pop	cx, si, ds

done:
	ret
TransRegCoord	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PWinTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the window tree semaphore

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		es	= idata and winTreeSem grabbed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FarPWinTree	proc	far
	call	PWinTree
	ret
FarPWinTree	endp

PWinTree	proc	near
		LoadVarSeg	es
		push	bx
		mov	bx, offset winTreeSem
NEC <		jmp	SysPSemCommon					>

EC <		PSem	es, [bx]					>
EC <		pop	bx						>
EC <		call	ECValidateWinTreeNoSem				>
EC <		ret							>

PWinTree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VWinTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the window tree semaphore

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		es	= idata and winTreeSem released
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarVWinTree	proc	far
	call	VWinTree
	ret
FarVWinTree	endp

VWinTree	proc	near
EC <		call	ECValidateWinTreeNoSem				>
		LoadVarSeg	es
		push	bx
		mov	bx, offset winTreeSem
		jmp	SysVSemCommon
VWinTree	endp

WinMovable segment resource

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupWinReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take passed region info, store into window's W_winRegion

CALLED BY:	INTERNAL
		WinMoveResize, WinOpen

PASS:
	bp:di - region, in window coordinates (or 0 for rectangular)
	dx:cx - parameters, or rectangle in window coordinates,
		in order of: AX_PARAM, BX_PARAM, cx_PARAM, DX_PARAM
	ds - window segment

RETURN:
	ds	- fixed up
	ds:[W_winReg]	- set according to user's wishes.

DESTROYED:
	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
SetupWinReg	proc	near
	mov	si, ds:[W_winReg]	; copy region into W_winReg
	FALL_THRU	SetupOtherReg

SetupWinReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupOtherReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take passed region info, offset from window, & store into
		some chunk region

CALLED BY:	INTERNAL
		WinSetAppReg, WinInvalReg

PASS:
	ds - segment address of window
	bp:di - region, in window coordinates (or 0 for rectangular)
	dx:cx - parameters, or rectangle in window coordinates,
		in order of: AX_PARAM, BX_PARAM, cx_PARAM, DX_PARAM
	si - chunk handle

RETURNS:
	ds	- fixed up
	region specified by bx set up

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

SetupOtherReg	proc	near
	call	SetupOtherRegLow	; Create region

	; offset region to window coordinates
	mov	si, ds:[si]
	mov	cx,ds:[W_winRect.R_left]
	mov	dx,ds:[W_winRect.R_top]
	call	GrMoveReg
	ret

SetupOtherReg	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupOtherRegLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take passed region info, & store into some chunk region

CALLED BY:	INTERNAL
		SetupOtherReg

PASS:	ds - segment address of window
	bp:di - region, (or 0 for rectangular)
	dx:cx - parameters, or rectangle
		in order of: AX_PARAM, BX_PARAM, cx_PARAM, DX_PARAM
	si - chunk handle

RETURNS:
	ds	- fixed up
	region set up

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/17/89	Stolen from insides of SetupOtherReg to
				make primitive

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

SetupOtherRegLow	proc	far
	push	si
	push	es

	segmov	es,ds			;es points at window

	tst	bp
	jnz	SOR_region

	mov	bp,seg idata		;use rectRegion
	mov	di,offset rectRegion
SOR_region:
	mov	ds,bp
	xchg	si,di

	call	WinSetReg

	segmov	ds,es
	pop	es
	pop	si
	ret

SetupOtherRegLow	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches current wChangeBounds

CALLED BY:	INTERNAL

PASS:		Nothing


RETURN:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetChangeBounds		proc	far
	push	ds
	LoadVarSeg	ds		; Get segment of our var
					;	space
	mov	bx, offset wChangeBounds; Fetch change bounds rectangle
	call	FetchRect		; Fetch rectangle at ds:[bx]
	pop	ds
	ret
GetChangeBounds		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetChangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets wChangeBounds

CALLED BY:	INTERNAL

PASS:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom


RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadWinSetChangeBounds  proc    far
        call    LoadWinBounds
        FALL_THRU	SetChangeBounds
LoadWinSetChangeBounds  endp


SetChangeBounds		proc	far
	push	ds
	LoadVarSeg	ds		; Get segment of our var
					;	space
					; Get bounds of W_winReg
	mov	ds:[wChangeBounds].R_left, ax	; Store bounds of W_winReg
	mov	ds:[wChangeBounds].R_top, bx
	mov	ds:[wChangeBounds].R_right, cx
	mov	ds:[wChangeBounds].R_bottom, dx
	pop	ds
	ret
SetChangeBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandChangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Widen wChangeBounds to be rectangle including both its
		previous area + that passed

CALLED BY:	INTERNAL

PASS:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom


RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadWinExpandChangeBounds  proc    near
        call    LoadWinBounds
        FALL_THRU       ExpandChangeBounds
LoadWinExpandChangeBounds  endp

ExpandChangeBounds	proc	near
	push	ds
	LoadVarSeg	ds		; Get segment of our var
					;	space
					; Get bounds of W_winReg
	cmp	ds:[wChangeBounds].R_left, ax	; Store bounds of W_winReg
	jle	ECB_10
	mov	ds:[wChangeBounds].R_left, ax	; Store bounds of W_winReg
ECB_10:
	cmp	ds:[wChangeBounds].R_top, bx
	jle	ECB_20
	mov	ds:[wChangeBounds].R_top, bx
ECB_20:
	cmp	ds:[wChangeBounds].R_right, cx
	jge	ECB_30
	mov	ds:[wChangeBounds].R_right, cx
ECB_30:
	cmp	ds:[wChangeBounds].R_bottom, dx
	jge	ECB_40
	mov	ds:[wChangeBounds].R_bottom, dx
ECB_40:
	pop	ds
	ret
ExpandChangeBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetValidateFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets wValidateFlags.  Should be set before calls to
		WinTValidateHere, WinTValidateOpen, WinTValidateSuperior,
		etc.  Should only be called inside P, V of winTreeSem.

CALLED BY:	INTERNAL

PASS:		ax	- flags:

		WIN_NO_PARENT_AFFECT	- set if parent never affected by
					 operation
		si	- top of branch validate is starting with
		ds	- segment of window branch starting with


RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version		lock OK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetValidateFlags	proc	near
	push	es
	LoadVarSeg	es		; Get segment of our var
					;	space
	mov	es:[wValidateFlags], al	; set Validate flags
	mov	es:[wChangeWin], si	; store window changing
	mov	es:[wCurBranch], si	; store that we're in its branch
	mov	al, ds:[W_saveUnder]	; get save under mask from window
					;	passed
	mov	es:[wChangeSaveUnder], al	; save save under mask
					; See if delaying V's
	test	es:[wValidateFlags], WIN_V_PASSED_LAST
	jz	SVF_90			; if not, done
					; Else init to not delayed wash
	and	ds:[W_regFlags], not mask WRF_DELAYED_WASH
					; but mark window as having delayed V
	or	ds:[W_regFlags], mask WRF_DELAYED_V
SVF_90:
	pop	es
	ret
SetValidateFlags	endp


WinPLockAndMaybeMark	proc	near
	call	MemPLock		; PLock this window
	push	es
	LoadVarSeg	es		; Get segment of our var space
					; See if delaying V's
	test	es:[wValidateFlags], WIN_V_PASSED_LAST
	jz	WPLAMM_90		; if not, skip out
	push	ds
	mov	ds, ax			; get segment of window
					; Init to delay flags being cleared
	and	ds:[W_regFlags], not (mask WRF_DELAYED_V or mask WRF_DELAYED_WASH)
	cmp	es:[wCurBranch], 0	; in change branch?
	je	WPLAMM_80		; skip if not
					; Mark window as having delayed V
	or	ds:[W_regFlags], mask WRF_DELAYED_V
WPLAMM_80:
	pop	ds
WPLAMM_90:
	pop	es
	ret
WinPLockAndMaybeMark	endp


WinUnlockAndMaybeV	proc	near
	push	es
	LoadVarSeg	es		; Get segment of our var space
					; See if delaying V's
	test	es:[wValidateFlags], WIN_V_PASSED_LAST
	jnz	WUAMV_10		; branch if so, else
WUAMV_5:
	call	WinUnlockV		; do UnlockV right away.
	pop	es			; & we're all done
	ret
WUAMV_10:
	push	ds
	mov	ds, es:[bx][HM_addr]	; get segment of block
						; & see if delayed V request
	test	ds:[W_regFlags], mask WRF_DELAYED_V
	pop	ds
	jz	WUAMV_5			; if not, branch & NearUnlockV it

	call	MemUnlock		; if so, then just unlock it, no V
	cmp	bx, es:[wCurBranch]	; Are we unlocking the branch?
	jne	WUAMV_100		; skip if not
	mov	es:[wCurBranch], 0	; if so, no longer in changing branch.
WUAMV_100:
	pop	es
	ret

WinUnlockAndMaybeV	endp


WinCallVidDriver	proc	far
						; di = driver routine # to call
						; ds = locked seg of window
	push	si
	push	bp
	push	ds
	push	es
	segmov	es, ds				; setup es to have window seg
	call	es:[W_driverStrategy]		; make call to driver
	pop	es
	pop	ds
	pop	bp
	pop	si
	ret
WinCallVidDriver	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfWinOverlapsChangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if window overlaps area that's changing (Used for
		trivial reject of region recalculation)

CALLED BY:	INTERNAL

PASS:
		si	- handle of window or sibling of window being changed,
			  which is parent of window passed in ds
		ds	- segment of locked window
		wChangeBounds	- area being changed

RETURN:		carry	- set if overlap (must do recalc)

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

CheckIfWinOverlapsChangeBounds	proc	near
	push	es
	LoadVarSeg	es		; Get segment of our var
					;	space
	test	es:[wValidateFlags], WIN_V_PASSED_LAST
	jz	CFWI_10			; If not delaying V, skip compare
	cmp	es:[wCurBranch], 0	; in tree branch of window causing
					;	change?
	jnz	CFWI_MustRecalc		; if so, we have to recalc, because
					; we need to P these children's
					; windows, as we're going to V them
					; later...
CFWI_10:
	mov	ax, es:[wChangeBounds].R_right
	cmp	ax, ds:[W_winRect].R_left
	jl	CFWI_Clear		; if change right < win left, clear
	mov	ax, ds:[W_winRect].R_right
	cmp	ax, es:[wChangeBounds].R_left
	jl	CFWI_Clear		; if win right < change left, clear
	mov	ax, es:[wChangeBounds].R_bottom
	cmp	ax, ds:[W_winRect].R_top
	jl	CFWI_Clear		; if change bottom < win top, clear
	mov	ax, ds:[W_winRect].R_bottom
	cmp	ax, es:[wChangeBounds].R_top
	jl	CFWI_Clear		; if win bottom < change top, clear
CFWI_MustRecalc:
	stc				; show overlap
	jmp	short CFWI_90		; branch to end
CFWI_Clear:
	clc
CFWI_90:
	pop	es
	ret
CheckIfWinOverlapsChangeBounds	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfChangeCompletelyInWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if rectangle of change bounds fits completely in current
		window.

CALLED BY:	INTERNAL

PASS:
		ds	- segment of locked window
		wChangeBounds	- area being changed

RETURN:		carry	- set if change completely fits in window
			NOTE:  If this flag is set, then the change area IS
				inside.  If the flag is clear, then nothing
				may be assumed (could be in or out).

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

CheckIfChangeCompletelyInWin	proc	near
	push	si
	push	es
	LoadVarSeg	es		; Get segment of our var
					;	space

;	If doing a layer change (multiple windows affected), then skip this
;	optimization - we need to validate all windows beneath this one


	test	es:[wValidateFlags], mask WVF_LAYER_CHANGE
	jnz	CFBIW_Clear

					; FIRST, see if blatantly out
	mov	ax, es:[wChangeBounds].R_left
	cmp	ax, ds:[W_winRect].R_left
	jl	CFBIW_Clear		; if change left < win left, clear
	mov	ax, ds:[W_winRect].R_right
	cmp	ax, es:[wChangeBounds].R_right
	jl	CFBIW_Clear		; if win right < change right, clear
	mov	ax, es:[wChangeBounds].R_top
	cmp	ax, ds:[W_winRect].R_top
	jl	CFBIW_Clear		; if change top < win top, clear
	mov	ax, ds:[W_winRect].R_bottom
	cmp	ax, es:[wChangeBounds].R_bottom
	jl	CFBIW_Clear		; if win bottom < change bottom, clear

					; Rectangle is inside rectangle bounds.
					; If arbeitrary region, need to do
					;	further check.
	mov	si, ds:[W_winReg]	; get handle of window region def
	mov	si, ds:[si]		; get ptr to window region def
	lodsw				; see if null region
	cmp	ax, EOREGREC
	je	CFBIW_Clear		; if null, can't possibly be inside
	mov	ax, ds:[si] + 12 - 2	; see if earliest possible end
					;	(rectangle)
	cmp	ax, EOREGREC
	je	CFBIW_Inside		; if rectangle, then IS inside, return
					;	carry set.
					; Else need to check in arb. region
	jmp	short CFBIW_Clear	; for now, just say NO, not inside
;MORE TO DO
;
; Do case for arbeitrary region, OR decide that it's not worth it...

CFBIW_Inside:
	stc				; show overlap
	jmp	short CFBIW_90		; branch to end
CFBIW_Clear:
					; Not inside window
	clc
CFBIW_90:
	pop	es
	pop	si
	ret
CheckIfChangeCompletelyInWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinLockWinAndParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL

PASS:
		bx	- handle of window

RETURN:
		Carry	- set if successful, continue operation.  clear
			  if neither block locked.
		si	- handle of new window
		di	- handle of parent
				OR NULL_WINDOW if opening root window
		ds	- segment of window
		es	- segment of parent (or NULL_WINDOW if window is root)

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinLockWinAndParent	proc	far
		mov	si, bx		; get handle of window in si
		call	WinPLockDS	; ds <- seg addr of Window
		test	ds:[W_regFlags], mask WRF_CLOSED
		jnz	WLWAP_20	; quit out if window is dying

		mov	ax, ds:[W_parent]; get handle of parent
		mov	di, ax
		cmp	ax, NULL_WINDOW
		je	WLWAP_10
					; Lock Parent window, so nobody else
					;	plays with it.
		mov	bx, ax
		call	MemPLock	; put a sole lock on this sucker
WLWAP_10:
		mov	es, ax		; setup segment for parent window
		stc			; all OK, both blocks locked
		ret
WLWAP_20:
		call	WinUnlockV	; Unlock block
		clc			; not successful
		ret

WinLockWinAndParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCalcWinBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL

PASS:		ds	- pointer to segment of locked window

RETURN:
		ax	- W_winRect.R_left
		bx	- W_winRect.R_top
		cx	- W_winRect.R_right
		dx	- W_winRect.R_bottom

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/5/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinCalcWinBounds	proc	near
EC <	call	FarCheckDS_ES						>
	push	si
	mov	si, ds:[W_winReg]	; Get handle to W_winReg in si
	mov	si, ds:[si]
					; CONVERT to rectangular bounds
	call	GrGetPtrRegBounds
					; ax = left
					; bx = top
					; cx = right
					; dx = bottom

	mov	ds:[W_winRect.R_left], ax	; Store bounds of W_winReg
	mov	ds:[W_winRect.R_top], bx
	mov	ds:[W_winRect.R_right], cx
	mov	ds:[W_winRect.R_bottom], dx
	and	ds:[W_grFlags], not mask WGF_XFORM_VALID 
					; clear transform valid flag
	pop	si
	ret
WinCalcWinBounds	endp

LoadWinBounds	proc	near
	mov	bx, offset W_winRect
	FALL_THRU	FetchRect
LoadWinBounds	endp

FetchRect	proc	near
				; Fetch the rectangle at ds:[bx]
	mov	cx, ds:[bx].R_right
	mov	dx, ds:[bx].R_bottom
	mov	ax, ds:[bx].R_left
	mov	bx, ds:[bx].R_top	; fetch bx last, which trashes ptr
	ret
FetchRect	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SwapUnivMaskReg
FUNCTION:	SwapUnivInvalReg
FUNCTION:	SwapInvalVis
FUNCTION:	SwapInvalMask

DESCRIPTION:	Routines to swap two region chunks in the window at ds:0.
		Used to help reduce memory usage of win sys

CALLED BY:	INTERNAL

DESTROYED:
	ax

-------------------------------------------------------------------------------@
SwapUnivMaskReg	proc	near
				; Swap Univ & Mask regions
	mov	ax, ds:[W_univReg]
	xchg	ds:[W_maskReg], ax
	mov	ds:[W_univReg], ax
	ret
SwapUnivMaskReg	endp

SwapUnivInvalReg	proc	near
				; Swap Univ & Inval regions
	mov	ax, ds:[W_univReg]
	xchg	ds:[W_invalReg], ax
	mov	ds:[W_univReg], ax
	ret
SwapUnivInvalReg	endp


SwapInvalVis	proc	near
				; Swat inval & vis regions
	mov	ax, ds:[W_visReg]
	xchg	ds:[W_invalReg], ax
	mov	ds:[W_visReg], ax
	ret
SwapInvalVis	endp

SwapInvalMask	proc	near
				; Swap inval & mask regions
	mov	ax, ds:[W_maskReg]
	xchg	ds:[W_invalReg], ax
	mov	ds:[W_maskReg], ax
	ret
SwapInvalMask	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCmpReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two regions in Window structure

CALLED BY:	INTERNAL

PASS:		ds	- segment of reg 1
		si	- handle of reg1
		es	- segment of reg2
		di	- segemnt of reg2

RETURN:		flags set to equal if equal

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
if	0
WinCmpReg	proc	near
	call	ChunkSizeHandleDS_SI_CX	; cx <- size of reg 1
	call	ChunkSizeHandleES_DI_AX	; ax <- size.
	cmp	cx, ax			; see if reg 2 has same size
	jne	WCMPR_90		; if not =, skip
	mov	si, ds:[si]		; get address of reg 1
	mov	di, ds:[di]		;
	shr	cx, 1			; divide count by 2
	rep	cmpsw			; do compare, return equal if
						;	match
WCMPR_90:					;
	ret				;
WinCmpReg	endp
endif

;---

WinPLockDS	proc	near
	call	MemPLock
	mov	ds, ax
	ret
WinPLockDS	endp

WinUnlockV	proc	near
	call	MemUnlockV
	ret
WinUnlockV	endp

WinMovable ends
