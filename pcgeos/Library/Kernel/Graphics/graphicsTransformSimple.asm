COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		28 March 1990

AUTHOR:		Jim DeFrisco, 3/29/90

ROUTINES:
	Name			Description
	----			-----------
	WSetNullTransform	Reset window transformation matrix
	GSetNullTransform	Reset gstate transformation matrix

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/29/90		Initial revision


DESCRIPTION:
	This file contains some TMatrix manipulation routines that are
	pretty frequently called.
		

	$Id: graphicsTransformSimple.asm,v 1.1 97/04/05 01:13:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsTransformUtils	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSetNullTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation with null (identity) transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to window or GState 
		cx	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set matrix to:
			1 0 0
			0 1 0
			0 0 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinSetNullTransform	proc	far

;this will give a nice warning message if WWFixed is not an even number
;of bytes. this assumptions is made through out this routine
CheckHack < ((size WWFixed and 1) eq 0) >
;this will give a nice warning message if 2 is not an even number.
;this assumptions is made through out this routine
CheckHack < ((2 and 1) eq 0) >

		uses	es,ds,di,cx,bx,ax,dx	; save regs we trash
		.enter

		; lock the window block

		call	FarWinLockFromDI	; ds -> window
		segmov	es, ds			; es -> window
		push	di			; save window handle
		push	cx			; save inval flag
		mov	di, W_TMatrix	; set up pointer to matrix
		clr	ax			; set up values to use
		mov	cx, (size TMatrix) / 2	; size of store
		rep	stosw			; init to all 0s
		sub	di, size TMatrix	; back to beginning
		mov	ds:[di].TM_11.WWF_int, 1	  ; set scale to 1.0
		mov	ds:[di].TM_22.WWF_int, 1	  ;  
		pop	cx			; restore inval flag

		; finish for window: UnlockV block, inval CurMatrix

		and	ds:[W_grFlags], not ( \
				   mask WGF_XFORM_VALID \
				or mask WGRF_PATH_VALID shl 8 \
				or mask WGRF_WIN_PATH_VALID shl 8)
		cmp	cx, WIF_INVALIDATE	; invalidate the window ?
		jne	unlockWin		;  no, skip it
		call	InvalWholeWin		; invalidate the whole window
unlockWin:
		pop	bx			; get handle for window
		call	MemUnlockV		; unlock, disown block
		.leave
		ret
WinSetNullTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSetNullTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation with null (identity) transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState 

RETURN:		nothing

DESTROYED:	es, ax, cx

PSEUDO CODE/STRATEGY:
		set matrix to:
			1 0 0
			0 1 0
			0 0 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSetNullTransform	proc	far

		; set up the right segregs, pointers

		push	di			; save regs
		mov	bx, di			; lock GState
		call	MemLock			;
		mov	es, ax			; set up segreg
		mov	ds, ax			; set up ds too
		mov	di, GS_TMatrix	; set up pointer to matrix
		clr	ax			; set up values to use
		mov	cx, (size TMatrix) / 2	; size of store
		rep	stosw			; init to all 0s
		sub	di, size TMatrix	; back to beginning
		mov	ds:[di].TM_11.WWF_int, 1	; set scale to 1.0
		mov	ds:[di].TM_22.WWF_int, 1	;
		call	FarInvalidateFont	; invalidate font handle
		pop	di			; restore regs
		ret
GSetNullTransform	endp

GraphicsTransformUtils	ends

GraphicsSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinGetTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve transformation matrix

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		ds:si	- pointer to TransMatrix buffer
			  
RETURN:		The buffer at ds:si is filled with the 6 elements, in row order.

			  That is, for the matrix:
				[e11 e12 0]
				[e21 e22 0]
				[e31 e32 1]
			   The returned array will look like:
				[e11 e12 e21 e22 e31 e32]

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the transformation into buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinGetTransform	proc	far
		uses ds, es, cx, ax, bx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx					>
EC <		mov	bx, ds					>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx					>
endif
		segmov	es, ds, bx
		call	FarWinLockFromDI	;
		push	di			; save window handle
		mov	di, si			; es:di -> buffer
		mov	si, W_TMatrix.TM_11	; set up pointer to matrix
		mov	cx, (size TransMatrix)/2 ; #words to copy
		rep	movsw			; copy the matrix
		mov	si, di			; restore reg
		sub	si, size TransMatrix
		pop	bx
		mov	di, bx			; restore handle
		call	MemUnlockV		; unlock the gstate

		.leave
		ret
WinGetTransform	endp

GraphicsSemiCommon ends
