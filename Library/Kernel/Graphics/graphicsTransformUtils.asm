COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsTransformUtils.asm

AUTHOR:		Jim DeFrisco, 9 August 1989

ROUTINES:
	Name			Description
	----			-----------
	ComposeFullMatrix	Do the hard part of ComposeMatrix
	RotateCommon		Common code for ApplyRotation
	ScaleCommon		Common code for ApplyScale

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/9/89		Initial revision
	Jim	10/24/89	Added ScaleCommon


DESCRIPTION:
	This file contains some parts of the graphics transformation
	code.
		

	$Id: graphicsTransformUtils.asm,v 1.1 97/04/05 01:13:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrApplyScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply scale factor to transformation matrix

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		dx.cx	- X-scale (WWFixed)
		bx.ax	- Y-scale (WWFixed)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Apply scaling to appropriate matrix.
		mark CurXform as invalid

		The following matrix mutliplication is performed:

		  GS_TMatrix	   =	 scaling   *   GS_TMatrix

		[ gs11  gs12  0 ]     [ Sx  0  0 ]   [ gs11  gs12  0 ]
		[ gs21  gs22  0 ]  =  [  0 Sy  0 ] * [ gs21  gs22  0 ]
		[ gs31  gs32  1 ]     [  0  0  1 ]   [ gs31  gs32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	jim	8/8/89		Changed name, added scale about
	jim	1/24/90		Eliminated ABOUT_COORD option

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrApplyScale	proc	far	
		uses	es, ds, si, dx, cx, bx, ax ; save regs we trash
		.enter

		;
		; If the scale is 1x1, don't even bother
		;

		cmp	dx, 1
		jne	doIt
		cmp	bx, dx
		jne	doIt
		tst	ax
		jnz	doIt
		jcxz	exit	

		; set up the right segregs, pointers
doIt:
		push	ax			; save parms trashed by
		xchg	bx, di			; lock GState, save parm
		call	MemLock
		mov	ds, ax			; ds, ax <- GState
		xchg	bx, di			; restore parms, handle
		pop	ax			;
		push	di			; save gstate handle

		mov	si, GS_TMatrix		; set up pointer to matrix
		call	FarInvalidateFont	; invalidate font handle
		call	ScaleCommon		; use common routine

		; check for gstring

		mov	di, ds:[GS_gstring]	; get alleged gstring handle
		tst	di			; check for valid handle
		jz	done

		; write to a graphics string

		push	ds			; save gstate segment
		push	bx			; save parameters on stack
		push	ax
		push	dx
		push	cx
		mov	cx, 2*(size WWFixed)
		segmov	ds, ss
		mov	si, sp			; ds:si -> data
		mov	ax, (GSSC_FLUSH shl 8) or GR_APPLY_SCALE ; set up opcode
		call	GSStore			; write to graphics string
		add	sp, cx
		pop	ds			; restore gstate segment

done:
		pop	di			; restore gstate handle
		call	ExitTransform
exit:
		.leave
		ret
GrApplyScale	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Done with transformation stuff.  Restore state and exit

CALLED BY:	INTERNAL
		Various transform routines
PASS:		ds	- pointer to GState block
		di	- handle of GState block
RETURN:		nothing
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitTransform		proc	far
		uses	ax, bx, ds
		.enter
		mov	cx, not (mask WGF_XFORM_VALID or \
			         mask WGRF_PATH_VALID shl 8)
		;
		; Lock the window, and see if the current GState is us.
		; If so, we need to invalidate the matrix and regions as
		; specified by the flags passed.
		;
		mov	bx, ds:GS_window		;bx <- handle of window
		tst	bx				;any window?
		jz	unlockGS			;branch if no window
EC <		call	ECCheckWindowHandle		;>
		call	MemPLock
		mov	ds, ax				;ds -> Window
		cmp	di, ds:W_curState		;are we current GState?
		jne	validBitOK			;no, leave flags alone
		andnf	{word} ds:W_grFlags, cx		;biff appropriate flags
validBitOK:
		call	MemUnlockV			;release the window
unlockGS:
		mov	bx, di				;bx <- handle of GState
		call	MemUnlock			;unlock GState
		.leave
		ret
ExitTransform		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common scaling routine for window and GState 

CALLED BY:	INTERNAL

PASS:		ds:si	- points to transformation matrix to apply scale to
		di	- handle of GState or window
		dx.cx	- x scale factor
		bx.ax	- y scale factor 

RETURN:		bx.ax	- y scale factor (WWFixed)

DESTROYED:	es

PSEUDO CODE/STRATEGY:
	  	apply scale factor to passed trans matrix
		update flags;

		Performs the following matrix multiplication:

		  TMatrix	   =	scaling      *   TMatrix

		[ tm11  tm12  0 ]     [  Sx   0  0 ]   [ tm11  tm12  0 ]
		[ tm21  tm22  0 ]  =  [   0  Sy  0 ] * [ tm21  tm22  0 ]
		[ tm31  tm32  1 ]     [   0   0  1 ]   [ tm31  tm32  1 ]

		tm11 =  tm11*Sx		tm12 =  tm12*Sx
		tm21 =  tm21*Sy 	tm22 =  tm22*Sy
		tm31 =  tm31		tm32 =  tm32

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleCommon	proc	far
		uses	di, cx, dx
xScale		local	WWFixed
yScale		local	WWFixed
		
		; allocate some local scratch space, save arguments

		.enter
		mov	yScale.WWF_int, bx	; save y scale factor
		mov	yScale.WWF_frac, ax
		mov	xScale.WWF_int, dx	; save x scale factor
		mov	xScale.WWF_frac, cx

		; need to use es:di to point to factors

		segmov	es, ss, di		; set up for multiply
		lea	di, xScale		; es:di -> x scale factor
		mov	al, ds:[si].TM_flags	; get flags for TMatrix
		test	al, TM_COMPLEX
		jnz	doComplex		;  not simple, more work
		mov	ds:[si].TM_11.WWF_frac, cx ; write out the scale fact
		mov	ds:[si].TM_11.WWF_int, dx  ;  high word too
		mov	cx, yScale.WWF_frac	   ; fetch y factor from stack
		mov	ds:[si].TM_22.WWF_frac, cx ; write out the scale fact
		mov	ds:[si].TM_22.WWF_int, bx  ;  high word too
		jmp	done

		; matrix already has some rotation/scale component
		; tm11 =  tm11*Sx	tm12 =  tm12*Sx
		; tm21 =  tm21*Sy 	tm22 =  tm22*Sy
doComplex:	
		add	si, TM_11		; ds:si -> TM_11
		lea	di, xScale		; es:di -> xScale factor
		call	GrMulWWFixedPtr		; element11 = Sx * TM_11
		mov	ds:[si].WWF_frac, cx	; store result (already
		mov	ds:[si].WWF_int, dx	;  pointing there)
		lea	di, yScale		; es:di -> Sy
		add	si, TM_22-TM_11		; ds:si -> TM_22
		call	GrMulWWFixedPtr		; element22 = Sy * TM_22
		mov	ds:[si].WWF_frac, cx	; store result (already 
		mov	ds:[si].WWF_int, dx	;  pointing there)
		sub	si, TM_22		; ds:si -> start of matrix
		test	al, TM_ROTATED		; done if no rotation
		jz	done			;  sorry, all done

		; some rotation already, do off-diagonals
		; tm11 =  tm11*Sx	tm12 =  tm12*Sx
		; tm21 =  tm21*Sy 	tm22 =  tm22*Sy

		add	si, TM_21		; ds:si -> TM_21
		call	GrMulWWFixedPtr		; calc TM_21
		mov	ds:[si].WWF_frac, cx	; store result
		mov	ds:[si].WWF_int, dx
		add	si, TM_12-TM_21		; ds:si -> TM_12
		lea	di, xScale		; es:di -> Sx
		call	GrMulWWFixedPtr		; calc TM_12
		mov	ds:[si].WWF_frac, cx	; store result
		mov	ds:[si].WWF_int, dx
		sub	si, TM_12		; si -> matrix
done:
		push	es			; set the new flags in matrix
		mov	di, si
		segmov	es, ds, si
		call	SetTMatrixFlags
		mov	si, di
		pop	es
		mov	bx, yScale.WWF_int	; recover the scale factor
		mov	ax, yScale.WWF_frac
		.leave
		ret
ScaleCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComposeFullMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a full 3x3 Matrix multiply

CALLED BY:	GLOBAL

PASS:		ch	- flags for Window TMatrix
		cl	- flags for GState TMatrix
		ds:si	- pointer to locked GState TMatrix
		es:di	- pointer to locked Window TMatrix

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		Do the matrix multiplication, checking for optimizations.
		For full pseudo-code, see the file:
			Kernel/Graphics/graphicsTransform.asm

		Performs the following matrix multiplication:

		  W_curTMatrix	     =	  GS_TMatrix	  *   W_TMatrix

		[ cur11  cur12  0 ]     [ gs11  gs12  0 ]   [ w11  w12  0 ]
		[ cur21  cur22  0 ]  =  [ gs21  gs22  0 ] * [ w21  w22  0 ]
		[ cur31  cur32  1 ]     [ gs31  gs32  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	08/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ComposeFullMatrix	proc	far

;this will give a nice warning message if WWFixed is not an even number
;of bytes. this assumptions is made through out this routine
CheckHack < ((size WWFixed and 1) eq 0) >

		mov	ax, cx			; get flags back
		test	ah, TM_COMPLEX
		jz	notComplex
		call	ComposeFullMatrixComplex
		jmp	composeCommon
notComplex:

		mov	cx, 4*(size WWFixed)/2	; set count to scale/rotate siz
		mov	si,GS_TMatrix.TM_11
		mov	di,W_curTMatrix.TM_11
		rep	movsw			; copy scale/rotate
		mov	cx, ds:[GS_TMatrix].TM_31.DWF_frac
		mov	bx, ds:[GS_TMatrix].TM_31.DWF_int.low
		mov	si, ds:[GS_TMatrix].TM_31.DWF_int.high
		add	cx, es:[W_TMatrix].TM_31.DWF_frac
		adc	bx, es:[W_TMatrix].TM_31.DWF_int.low
		adc	si, es:[W_TMatrix].TM_31.DWF_int.high
		mov	es:[W_curTMatrix].TM_31.DWF_frac, cx
		mov	es:[W_curTMatrix].TM_31.DWF_int.low, bx
		mov	es:[W_curTMatrix].TM_31.DWF_int.high, si
		mov	cx, ds:[GS_TMatrix].TM_32.DWF_frac
		mov	bx, ds:[GS_TMatrix].TM_32.DWF_int.low
		mov	si, ds:[GS_TMatrix].TM_32.DWF_int.high
		add	cx, es:[W_TMatrix].TM_32.DWF_frac
		adc	bx, es:[W_TMatrix].TM_32.DWF_int.low
		adc	si, es:[W_TMatrix].TM_32.DWF_int.high
		mov	es:[W_curTMatrix].TM_32.DWF_frac, cx
		mov	es:[W_curTMatrix].TM_32.DWF_int.low, bx
		mov	es:[W_curTMatrix].TM_32.DWF_int.high, si
		or	al, ah			; combine flags
		mov	byte ptr es:[W_curTMatrix].TM_flags, al ; set flags 

composeCommon:

		; check GrMatrix for no scale/rotate

		test	al, TM_COMPLEX
		jnz	GCM_grComplex
		mov	bx, ds			; save segreg
		segmov	ds, es			; set both -> window
		mov	si, W_TMatrix.TM_11	;copy scale rotate
		mov	di, W_curTMatrix.TM_11
		mov	cx, 4*(size WWFixed)/2	; move 4 elemets
		rep	movsw
		or	al, ah			; combine flags
		mov	ds:[W_curTMatrix].TM_flags, al
		mov	ds, bx			; restore segreg
		ret

;---

		; GrMatrix has some scaling/rotation

GCM_grComplex:
		call	ComposeScaleRot
		ret

ComposeFullMatrix	endp

GraphicsSemiCommon ends

;---

GraphicsTransformUtils segment resource

ComposeScaleRot	proc	far
		; do element Cur11 = G11*W11
		mov	si, GS_TMatrix.TM_11 ; set up pointers for mul
		mov	di, W_TMatrix.TM_11
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		test	ax, (TM_ROTATED shl 8) or TM_ROTATED ; test both
		jz	GCM_store11
		push	ax			; save flags
		mov	ax, cx			; save partial result
		mov	bx, dx
		mov	si, GS_TMatrix.TM_12
		mov	di, W_TMatrix.TM_21
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		add	cx, ax
		adc	dx, bx
		pop	ax			; restore flags
GCM_store11:
		mov	es:[W_curTMatrix].TM_11.WWF_frac, cx
		mov	es:[W_curTMatrix].TM_11.WWF_int, dx
		
		; do element Cur22 = G22*W22
		mov	si, GS_TMatrix.TM_22 ; set up pointers for mul
		mov	di, W_TMatrix.TM_22
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		test	ax, (TM_ROTATED shl 8) or TM_ROTATED ; test both
		jz	GCM_store22
		push	ax			; save flags
		mov	ax, cx			; save partial result
		mov	bx, dx
		mov	si, GS_TMatrix.TM_21
		mov	di, W_TMatrix.TM_12
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		add	cx, ax
		adc	dx, bx
		pop	ax			; restore flags
GCM_store22:
		mov	es:[W_curTMatrix].TM_22.WWF_frac, cx
		mov	es:[W_curTMatrix].TM_22.WWF_int, dx
		
		; test for rotation in either to simplify off-diagonals

		test	ah, TM_ROTATED 		; test WinMatrix
		jnz	GCM_winRotated		;  yep, there's some rotation
		test	al, TM_ROTATED 		; test GrMatrix
		jnz	GCM_grRotated		;  yep, there's some rotation

		; no rotation in either, just write 0s for off-diagonals
		mov	dx, ax			; save flags
		clr	ax			; get ready for stosw
		mov	cx, 2*(size WWFixed)/2	; two elements to fill
		mov	di, W_curTMatrix.TM_12
		rep	stosw
		or	dl, dh			; combine flags
		mov	byte ptr es:[W_curTMatrix].TM_flags, dl ; set flags 
		ret

		; WinMatrix rotated
GCM_winRotated:
		; do element Cur12 = G11*W12
		mov	si, GS_TMatrix.TM_11 ; set up pointers for mul
		mov	di, W_TMatrix.TM_12
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		test	al, TM_ROTATED 		; test GrMatrix
		jz	GCM_store12		;  yep, there's some rotation
		push	ax			; save flags
		mov	ax, cx			; save partial result
		mov	bx, dx
		mov	si, GS_TMatrix.TM_12
		mov	di, W_TMatrix.TM_22
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		add	cx, ax
		adc	dx, bx
		pop	ax			; restore flags
GCM_store12:
		mov	es:[W_curTMatrix].TM_12.WWF_frac, cx
		mov	es:[W_curTMatrix].TM_12.WWF_int, dx

		; do element Cur21 = G22*W21
		mov	si, GS_TMatrix.TM_22 ; set up pointers for mul
		mov	di, W_TMatrix.TM_21
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		test	al, TM_ROTATED 		; test GrMatrix
		jz	GCM_store21		;  yep, there's some rotation
		push	ax			; save flags
		mov	ax, cx			; save partial result
		mov	bx, dx
		mov	si, GS_TMatrix.TM_21
		mov	di, W_TMatrix.TM_11
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		add	cx, ax
		adc	dx, bx
		pop	ax			; restore flags
GCM_store21:
		mov	es:[W_curTMatrix].TM_21.WWF_frac, cx
		mov	es:[W_curTMatrix].TM_21.WWF_int, dx
		jmp	combineFlags

		; GrMatrix rotated, WinMatrix not rotated
GCM_grRotated:
		; do element Cur12 = G12*W22
		mov	si, GS_TMatrix.TM_12
		mov	di, W_TMatrix.TM_22
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		mov	es:[W_curTMatrix].TM_12.WWF_frac, cx
		mov	es:[W_curTMatrix].TM_12.WWF_int, dx

		; do element Cur21 = G21*W11
		mov	si, GS_TMatrix.TM_21
		mov	di, W_TMatrix.TM_11
		call	GrMulWWFixedPtr		; dx:cx has result (dx high)
		mov	es:[W_curTMatrix].TM_21.WWF_frac, cx
		mov	es:[W_curTMatrix].TM_21.WWF_int, dx
combineFlags:
		or	al, ah			; combine flags
		mov	es:[W_curTMatrix].TM_flags, al

		; all done, just figure out if the 32bit flag should be set

		ret

ComposeScaleRot endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComposeFullMatrixComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle DWFixed portions of a TMatrix multiplication

CALLED BY:	GLOBAL

PASS:		ah	- flags for Window TMatrix
		al	- flags for GState TMatrix
		ds:si	- pointer to locked GState TMatrix
		es:di	- pointer to locked Window TMatrix

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		Do the matrix multiplication, checking for optimizations.
		For full pseudo-code, see the file:
			Kernel/Graphics/graphicsTransform.asm

		Performs the following matrix multiplication:

		  W_curTMatrix	     =	  GS_TMatrix	  *   W_TMatrix

		[ cur11  cur12  0 ]     [ gs11  gs12  0 ]   [ w11  w12  0 ]
		[ cur21  cur22  0 ]  =  [ gs21  gs22  0 ] * [ w21  w22  0 ]
		[ cur31  cur32  1 ]     [ gs31  gs32  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ComposeFullMatrixComplex	proc	far
		call	FarInvalidateFont	;invalidate font handle
		; do element Cur31 = G31*W11 + W31	(win no rotate)
		; 		     G31*W11 + W31 + G32*W21 (full) 
		mov	si, GS_TMatrix.TM_31 ; set up pointers for mul
		mov	di, W_TMatrix.TM_11
		call	MulDWFbyWWF		; dx:cx.bx has result (dx high)
		add	bx, es:[W_TMatrix].TM_31.DWF_frac
		adc	cx, es:[W_TMatrix].TM_31.DWF_int.low
		adc	dx, es:[W_TMatrix].TM_31.DWF_int.high
		test	ah, TM_ROTATED		; see if only scaled
		jz	store31		;  nope, do full compose
		push	ax			; save flags
		push	dx, cx, bx		; save - high to low
		mov	si, GS_TMatrix.TM_32
		mov	di, W_TMatrix.TM_21
		call	MulDWFbyWWF		; dx.cx.bx has result (dx high)
		pop	ax			; restore previous fraction
		add	bx, ax			; add in partial result
		pop	ax
		adc	cx, ax
		pop	ax
		adc	dx, ax
		pop	ax			; restore flags
store31:
		mov	es:[W_curTMatrix].TM_31.DWF_frac, bx
		mov	es:[W_curTMatrix].TM_31.DWF_int.low, cx
		mov	es:[W_curTMatrix].TM_31.DWF_int.high, dx

		; do element Cur32 = G32*W22 + W32	(win no rotate)
		; 		     G32*W22 + W32 + G31*W12 (full) 
		mov	si, GS_TMatrix.TM_32 ; set up pointers for mul
		mov	di, W_TMatrix.TM_22
		call	MulDWFbyWWF		; dx:cx.bx has result (dx high)
		add	bx, es:[W_TMatrix].TM_32.DWF_frac
		adc	cx, es:[W_TMatrix].TM_32.DWF_int.low
		adc	dx, es:[W_TMatrix].TM_32.DWF_int.high
		test	ah, TM_ROTATED		; see if only scaled
		jz	store32		;  nope, do full compose
		push	ax			; save flags
		push	dx, cx, bx		; save partial result
		mov	si, GS_TMatrix.TM_31
		mov	di, W_TMatrix.TM_12
		call	MulDWFbyWWF		; dx:cx has result (dx high)
		pop	ax			; add in partial result
		add	bx, ax
		pop	ax
		adc	cx, ax
		pop	ax
		adc	dx, ax
		pop	ax			; restore flags
store32:
		mov	es:[W_curTMatrix].TM_32.DWF_frac, bx
		mov	es:[W_curTMatrix].TM_32.DWF_int.low, cx
		mov	es:[W_curTMatrix].TM_32.DWF_int.high, dx
		ret

ComposeFullMatrixComplex	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrApplyRotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply rotation to a transformation matrix

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		dx.cx	- 32-bit signed integer representing angle*65536

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Apply rotation to appropriate matrix.
		mark CurXform as invalid

		Performs the following matrix multiplication:

		  GS_TMatrix	   =	rotation       *   GS_TMatrix

		[ gs11  gs12  0 ]     [  cos -sin  0 ]   [ gs11  gs12  0 ]
		[ gs21  gs22  0 ]  =  [  sin  cos  0 ] * [ gs21  gs22  0 ]
		[ gs31  gs32  1 ]     [    0    0  1 ]   [ gs31  gs32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	jim	8/8/89		Changed name, added rotate about
	jim	1/24/90		Eliminated ABOUT_COORD option

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrApplyRotation	proc	far
		uses	es, ds, si, dx, cx, bx, ax	; save regs we trash
		.enter

		; check for null rotation

		tst	dx			; if angle == 0, don't do
		jnz	doIt			;  anything
		tst	cx
		jz	exit

		; set up the right segregs, pointers
doIt:
		push	di			; save gstate handle
		mov	bx, di			; lock GState
		call	MemLock
		mov	ds, ax			; ds <- GState
		mov	si, GS_TMatrix		; set up pointer to matrix
		call	FarInvalidateFont	; invalidate font handle
		mov	ax, cx			; setup for RotateCommon
		call	RotateCommon		; apply rotation

		; check for gstring

		mov	di, ds:[GS_gstring]	; get alleged gstring handle
		tst	di			; check for valid handle
		jnz	GAR_gseg

		; all done exit and go home
done:
		pop	di			; restore gstate handle
		call	ExitTransform		; cleanup
exit:
		.leave
		ret

;-----------	 handle writing to graphics string

GAR_gseg:
		mov	bx, cx			; bx.dx = info to write
		mov	cl, size WWFixed	; size of fixed point angle 
		mov	al, GR_APPLY_ROTATION	; set up opcode
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write to graphics string
		jmp	done			; all done

GrApplyRotation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		ds:si	- pointer to new TMatrix to use
			  There should be six elements, four of them are 
			  32-bit fixed point number (WWFixed structure), and
			  the last two are 48-bit fixed point numbers 
			  (DWFixed structure), arranged in row order.  
			  That is, for the matrix:
				[e11 e12 0]
				[e21 e22 0]
				[e31 e32 1]
			   The passed array should be the six elements:
				[e11 e12 e21 e22 e31 e32]
			    where e31 and e32 are the 48-bit DWFixed numbers

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the new transformation into GS_TMatrix

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrSetTransform	proc	far
		mov	ss:[TPD_callVector].segment, size TMatrix
		mov	ss:[TPD_dataBX], handle GrSetTransformReal
		mov	ss:[TPD_dataAX], offset GrSetTransformReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrSetTransform	endp
CopyStackCodeXIP	ends

else

GrSetTransform	proc	far
		FALL_THRU	GrSetTransformReal
GrSetTransform	endp

endif

GrSetTransformReal	proc	far

		; use this instead of .enter so we can use common code 
		; with GrApplyTransform

		push  es, cx, bx, ax          ; save regs we trash
		push	ds

		call	GSetTransform		; all in KLib now

		; set up opcode in case this is a gstring we're writing to
		; then join in on some common code.

		mov     ax, (GSSC_FLUSH shl 8) or GR_SET_TRANSFORM ; opcode

		; check for gstring
SetApplyCommon	label	near
		tst	es:[GS_gstring]		; get alleged gstring handle
		jz	done

		; write out the gstring

		pop	ds
		
		push	di
		mov	di, es:[GS_gstring]	; get the gstring handle
		mov     cx, size TransMatrix    ; #bytes to copy
		call    GSStore                 ; write out the element
		pop	di

		push	ds
done:
		segmov	ds, es			; ds -> gstate to exit
		call	ExitTransform
		pop	ds
		pop es, cx, bx, ax          ; restore regs we trash
		ret
GrSetTransformReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrApplyTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catenate transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		ds:si	- pointer to new TMatrix to use
			  There should be six elements, four of them are 
			  32-bit fixed point number (WWFixed structure), and
			  the last two are 48-bit fixed point numbers 
			  (DWFixed structure), arranged in row order.  
			  That is, for the matrix:
				[e11 e12 0]
				[e21 e22 0]
				[e31 e32 1]
			   The passed array should be the six elements:
				[e11 e12 e21 e22 e31 e32]
			    where e31 and e32 are the 48-bit DWFixed numbers

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		apply the new transformation to GS_TMatrix

		The following matrix mutliplication is performed:

		  GS_TMatrix	   =	 matrix      *   GS_TMatrix

		[ gs11  gs12  0 ]     [ e11 e12  0 ]   [ gs11  gs12  0 ]
		[ gs21  gs22  0 ]  =  [ e21 e22  0 ] * [ gs21  gs22  0 ]
		[ gs31  gs32  1 ]     [ e31 e32  1 ]   [ gs31  gs32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrApplyTransform	proc	far
		mov	ss:[TPD_callVector].segment, size TMatrix
		mov	ss:[TPD_dataBX], handle GrApplyTransformReal
		mov	ss:[TPD_dataAX], offset GrApplyTransformReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrApplyTransform	endp
CopyStackCodeXIP	ends

else

GrApplyTransform	proc	far
		FALL_THRU	GrApplyTransformReal
GrApplyTransform	endp

endif

GrApplyTransformReal proc	far

		; forget the .enter so we can use common code

		push  es, cx, bx, ax      ; save regs we trash
		push	ds

		call	GApplyTransform		; all in KLib now

		; set up opcode and join common code

		mov     ax, (GSSC_FLUSH shl 8) or GR_APPLY_TRANSFORM  ;
		jmp	SetApplyCommon
GrApplyTransformReal endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetNullTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation with null (identity) transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set matrix to:
			[ 1 0 0 ]
			[ 0 1 0 ]
			[ 0 0 1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		You probably don't want to use this routine.  You probably
		want to use GrSetDefaultTransform instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetNullTransform	proc	far
		uses ds,es,cx,bx,ax      	; save regs we trash
		.enter
		call	GSetNullTransform	; all in KLib now

		; check for gstring

		tst	ds:[GS_gstring]		; get alleged gstring handle
		jz	done

		; write out the the graphics string

		push	di
		mov	di, ds:[GS_gstring]	; get gstring handle
		mov     al, GR_SET_NULL_TRANSFORM
		clr     cl			; no data to write
		mov	ch, GSSC_FLUSH
		call    GSStoreBytes            ; write the element
		pop	di

		; all done, exit quietly
done:
		call    ExitTransform
		.leave
		ret
GrSetNullTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common rotation code used by WinRotate and GrApplyRotation

CALLED BY:	GLOBAL

PASS:		ds:si	- points to transformation matrix to apply rotate to
		di	- handle of GState or window
		dx:ax	- angle to rotate (dx=integer part, cx=fractional part)

RETURN:		al	- flags to update matrix flags

DESTROYED:	ax,bx,es

PSEUDO CODE/STRATEGY:
		check for optimizations, but apply rotation to matrix.

		Performs the following matrix multiplication:

		  TMatrix	   =	rotation        *   TMatrix

		[ tm11  tm12  0 ]     [  cos  -sin  0 ]   [ tm11  tm12  0 ]
		[ tm21  tm22  0 ]  =  [  sin   cos  0 ] * [ tm21  tm22  0 ]
		[ tm31  tm32  1 ]     [    0     0  1 ]   [ tm31  tm32  1 ]

		tm11 =  tm11*cos - tm21*sin	tm12 =  tm12*cos - tm22*sin
		tm21 =  tm11*sin + tm21*cos	tm22 =  tm12*sin + tm22*cos
		tm31 =  tm31			tm32 =  tm32

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RotateCommon	proc	far
		uses	di,cx,dx		; save handle, angle
sine		local	WWFixed
nsine		local	WWFixed
cosine		local	WWFixed
temp1		local	WWFixed
		.enter

		; calculate the sine and cosine, save it

		push	dx			; save angle
		push	ax
		call	GrQuickCosine		; get cosine of angle
		mov	cosine.WWF_int, dx	; save high word of cosine
		mov	cosine.WWF_frac, ax	; save low word of cosine
		pop	ax
		pop	dx			; restore angle
		call	GrQuickSine		; get sine of angle
		mov	sine.WWF_int, dx	; save high word of sine
		mov	sine.WWF_frac, ax	; save low word of sine
		NegateFixed dx, ax		; we want -sine(angle) too
		mov	nsine.WWF_int, dx	; save high word of sine
		mov	nsine.WWF_frac, ax	; save low word of sine

		; get transformation matrix flags 
		; handle simple case (trans matrix had no scale/rotation)

		segmov	es, ss, di		; set up es:di -> sine/cos
		mov	al, [si].TM_flags	; get current flags for matrix
		test	al, TM_COMPLEX
		jnz	doComplex		; matrix already has sc/rot
		mov	bx, cosine.WWF_frac	; get low word of cosine
		mov	cx, cosine.WWF_int	; get high word of cosine
		mov	ds:[si].TM_11.WWF_frac, bx 	; store as tm11 and tm22
		mov	ds:[si].TM_11.WWF_int, cx
		mov	ds:[si].TM_22.WWF_frac, bx
		mov	ds:[si].TM_22.WWF_int, cx
		mov	cx, sine.WWF_int	; get high word of sine
		mov	bx, sine.WWF_frac	; get low word of sine
		mov	ds:[si].TM_21.WWF_frac, bx 	; store as element 21
		mov	ds:[si].TM_21.WWF_int, cx
		mov	cx, nsine.WWF_int	; get high word of -sine
		mov	bx, nsine.WWF_frac	; get low word of -sine
		mov	ds:[si].TM_12.WWF_frac, bx 	; store as element 12
		mov	ds:[si].TM_12.WWF_int, cx
		jmp	done			; rejoin code below

		; original matrix has some rotation and/or scaling
		; calculate first column of matrix
		; tm11 =  tm11*cos - tm21*sin	tm12 =  tm12*cos - tm22*sin
		; tm21 =  tm11*sin + tm21*cos	tm22 =  tm12*sin + tm22*cos
doComplex:
		lea	di, sine		; es:di -> sin
		add	si, TM_11		; ds:si -> element11
		call	GrMulWWFixedPtr		; tm11*sin
		mov	temp1.WWF_frac, cx	; save for later
		mov	temp1.WWF_int, dx
		lea	di, cosine		; es:di -> cosine
		call	GrMulWWFixedPtr		; tm11*cos
		mov	ds:[si].WWF_frac, cx	; store new tm11
		mov	ds:[si].WWF_int, dx
		sub	si, TM_11		; ds:si -> element11
		test	al, TM_ROTATED		; see if already rotated
		jnz	doSomeRotation		;  no, continue
		mov	cx, temp1.WWF_frac	; save for later
		mov	dx, temp1.WWF_int
		mov	ds:[si].TM_21.WWF_frac, cx	; store value
		mov	ds:[si].TM_21.WWF_int, dx
		jmp	doColumn2		;  no, continue
		
		; matrix has some rotation component, calc 2nd part of tm11,tm21
doSomeRotation:
		add	si, TM_21		; ds:si -> tm21
		lea	di, nsine		; es:di -> -sin
		call	GrMulWWFixedPtr		; do multiplication
		add	ds:[si+TM_11.WWF_frac-TM_21], cx	; save result
		adc	ds:[si+TM_11.WWF_int-TM_21], dx
		lea	di, cosine		; es:di -> cosine
		call	GrMulWWFixedPtr		; do multiplication
		add	cx, temp1.WWF_frac	; combine with previous result
		adc	dx, temp1.WWF_int	; 
		mov	ds:[si].WWF_frac, cx	; save result
		mov	ds:[si].WWF_int, dx	; tm21 finished
		sub	si, TM_21

		; finished with column 1, on to column two
		; tm11 =  tm11*cos - tm21*sin	tm12 =  tm12*cos - tm22*sin
		; tm21 =  tm11*sin + tm21*cos	tm22 =  tm12*sin + tm22*cos
doColumn2:
		add	si, TM_22		; ds:si -> tm22
		lea	di, nsine		; es:di -> -sin
		call	GrMulWWFixedPtr		; dx.cx = tm22*sin
		mov	temp1.WWF_frac, cx	; save for later
		mov	temp1.WWF_int, dx
		lea	di, cosine
		call	GrMulWWFixedPtr		; dx.cx = tm12*cos
		mov	ds:[si].WWF_frac, cx	; save partial result
		mov	ds:[si].WWF_int, dx	
		sub	si, TM_22		; ds:si -> start of matrix
		test	al, TM_ROTATED		; see if already rotated
		jnz	moreRotation		;  no, continue
		mov	cx, temp1.WWF_frac	; save for later
		mov	dx, temp1.WWF_int
		mov	ds:[si].TM_12.WWF_frac, cx	; store value
		mov	ds:[si].TM_12.WWF_int, dx
		jmp	done			;  no, continue

		; matrix has some rotation component, calc 2nd part of tm12,tm22
moreRotation:
		add	si, TM_12		; ds:si -> tm12
		lea	di, sine		; es:di -> sin
		call	GrMulWWFixedPtr		; do multiplication
		add	ds:[si+TM_22.WWF_frac-TM_12], cx	; save result
		adc	ds:[si+TM_22.WWF_int-TM_12], dx
		lea	di, cosine		; es:di -> cosine
		call	GrMulWWFixedPtr		; do multiplication
		add	cx, temp1.WWF_frac	; combine with previous result
		adc	dx, temp1.WWF_int	
		mov	ds:[si].WWF_frac, cx	; save result
		mov	ds:[si].WWF_int, dx	; tm12 finished
		sub	si, TM_12

		; all done: set state, unlock blocks, restore regs, invalidate
		; CurMatrix if needed, and quit
done:
		push	es			; set the new flags in matrix
		mov	di, si
		segmov	es, ds, si
		call	SetTMatrixFlags
		mov	si, di
		pop	es
		.leave
		ret
RotateCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMatrixPreMul
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two transformation matrices. result stored in source.

CALLED BY:	GLOBAL

PASS:		ds:si	- far pointer to source matrix
		es:di	- far pointer to dest matrix

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		Do full matrix multiply:

			[s11 s12 0]	[d11 d12 0]   [s11 s12 0]
			[s21 s22 0]  =  [d21 d22 0] * [s21 s22 0]
			[s31 s32 1]	[d31 132 1]   [s31 s32 1]


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version
	jim	8/89		moved to kernel lib, changed name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMatrixPreMul	proc	far
temp1		local	DWFixed
temp2		local	DWFixed
temp3		local	DWFixed
temp4		local	DWFixed
temp5		local	DWFixed

		.enter				; allocate local scratch

		; s11 = d11s11 + d12s21
		; s12 = d11s12 + d12s22

		add	si, TM_11		; ds:si -> s11
		add	di, TM_11		; es:di -> d11
		call	GrMulWWFixedPtr		; dx:cx = d11s11
		push	cx, dx
		add	di, TM_21-TM_11		; es:di -> d21
		call	GrMulWWFixedPtr		; dx.cx = d21s11
		mov	ax, dx
		cwd
		mov	temp1.DWF_int.high, dx	; temp1 = d21s11
		mov	temp1.DWF_int.low, ax	
		mov	temp1.DWF_frac, cx	
		add	di, TM_31-TM_21		; es:di -> d31
		call	MulWWFbyDWF		; dx.cx.bx = d31s11
		mov	temp2.DWF_int.high, dx	; temp2 = d31s11
		mov	temp2.DWF_int.low, cx
		mov	temp2.DWF_frac, bx
		add	si, TM_21-TM_11		; ds:si -> s21
		add	di, TM_12-TM_31		; es:di -> d12
		call	GrMulWWFixedPtr		; dx:cx = d12s21
		pop	ax, bx
		add	cx, ax			; add in previous partial
		adc	dx, bx			;  dx:cx = d11s11 + d12s21
		mov	ds:[si-TM_21].TM_11.WWF_frac, cx	; store new s11
		mov	ds:[si-TM_21].TM_11.WWF_int, dx
		add	si, TM_12-TM_21		; ds:si -> s12
		add	di, TM_11-TM_12		; es:di -> d11
		call	GrMulWWFixedPtr		; dx:cx = d11s12
		push	cx, dx
		add	di, TM_21-TM_11		; es:di -> d21
		call	GrMulWWFixedPtr		; dx:cx = d21s12
		mov	ax, dx
		cwd
		mov	temp3.DWF_int.high, dx	; temp3 = d21s12
		mov	temp3.DWF_int.low, ax
		mov	temp3.DWF_frac, cx	
		add	di, TM_31-TM_21		; es:di -> d31
		call	MulWWFbyDWF		; dx:cx = d31s12
		mov	temp4.DWF_int.high, dx	; temp4 = d31s12
		mov	temp4.DWF_int.low, cx
		mov	temp4.DWF_frac, bx
		add	si, TM_22-TM_12		; ds:si -> s22
		add	di, TM_12-TM_31		; es:di -> d12
		call	GrMulWWFixedPtr		; dx:cx = d12s22
		pop	ax, bx
		add	cx, ax			; add in previous partial
		adc	dx, bx			;  dx:cx = d11s12 + d12s22
		mov	ds:[si-TM_22].TM_12.WWF_frac, cx	; store new s12
		mov	ds:[si-TM_22].TM_12.WWF_int, dx

		; s21 = d21s11 + d22s21
		; s22 = d21s12 + d22s22
				
		add	si, TM_21-TM_22		; ds:si -> s21
		add	di, TM_32-TM_12		; es:di -> d32
		call	MulWWFbyDWF		; dx.cx.bx = d32s21
		mov	temp5.DWF_int.high, dx	; temp5 = d32s21
		mov	temp5.DWF_int.low, cx
		mov	temp5.DWF_frac, bx
		add	di, TM_22-TM_32		; es:di -> d22
		call	GrMulWWFixedPtr		; dx:cx = d22s21
		mov	ax, dx			; ax = low integer
		cwd				; dx = high integer
		add	cx, temp1.DWF_frac	; add previous partial result
		adc	ax, temp1.DWF_int.low
		adc	dx, temp1.DWF_int.high	; NOTE: assuming no overflow
		mov	ds:[si].WWF_frac, cx	; store new s21
		mov	ds:[si].WWF_int, ax
		add	si, TM_22-TM_21		; ds:si -> s22
		add	di, TM_32-TM_22		; es:di -> d32
		call	MulWWFbyDWF		; dx.cx.bx = d32s22
		mov	temp1.DWF_int.high, dx	; temp1 = d32s22
		mov	temp1.DWF_int.low, cx
		mov	temp1.DWF_frac, bx
		add	di, TM_22-TM_32		; es:di -> d22
		call	GrMulWWFixedPtr		; dx:cx = d22s22
		mov	ax, dx			; ax = low integer
		cwd				; dx = high integer
		add	cx, temp3.DWF_frac	; add previous partial result
		adc	ax, temp3.DWF_int.low
		adc	dx, temp3.DWF_int.high
		mov	ds:[si].WWF_frac, cx		; store new s22
		mov	ds:[si].WWF_int, ax

		; s31 = d31s11 + d32s21 + s31
		; s32 = d31s12 + d32s22 + s32
				
		add	si, TM_31-TM_22		; ds:si -> s31
		mov	ax, ds:[si].DWF_frac	; get previous s31
		mov	bx, ds:[si].DWF_int.low
		mov	cx, ds:[si].DWF_int.high
		add	ax, temp5.DWF_frac	; add in previous result
		adc	bx, temp5.DWF_int.low
		adc	cx, temp5.DWF_int.high
		add	ax, temp2.DWF_frac	; add in previous result
		adc	bx, temp2.DWF_int.low
		adc	cx, temp2.DWF_int.high
		mov	ds:[si].DWF_frac, ax	; store new s31
		mov	ds:[si].DWF_int.low, bx
		mov	ds:[si].DWF_int.high, cx
		add	si, TM_32-TM_31		; ds:si -> s32
		mov	ax, ds:[si].DWF_frac	; get previous s32
		mov	bx, ds:[si].DWF_int.low
		mov	cx, ds:[si].DWF_int.high
		add	ax, temp4.DWF_frac	; add in previous result
		adc	bx, temp4.DWF_int.low
		adc	cx, temp4.DWF_int.high
		add	ax, temp1.DWF_frac	; add in previous result
		adc	bx, temp1.DWF_int.low
		adc	cx, temp1.DWF_int.high
		mov	ds:[si].DWF_frac, ax		; store new s32
		mov	ds:[si].DWF_int.low, bx
		mov	ds:[si].DWF_int.high, cx

		; restore regs, exit

		sub	di, TM_22		; set di -> matrix
		sub	si, TM_32		; set si -> matrix
		.leave
		ret
TMatrixPreMul	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinSetTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to window or GState
		ds:si	- pointer to new TransMatrix to use
		cx	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the new transformation into W_TMatrix 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
WinSetTransform	proc	far
		mov	ss:[TPD_callVector].segment, size TransMatrix
		mov	ss:[TPD_dataBX], handle WinSetTransformReal
		mov	ss:[TPD_dataAX], offset WinSetTransformReal
		GOTO	SysCallMovableXIPWithDSSIBlock
WinSetTransform	endp
CopyStackCodeXIP	ends

else

WinSetTransform	proc	far
	FALL_THRU	WinSetTransformReal
WinSetTransform	endp

endif

WinSetTransformReal	proc	far

;this will give a nice warning message if WWFixed is not an even number
;of bytes. this assumptions is made through out this routine
CheckHack < ((size WWFixed and 1) eq 0) >

		uses 	ax, bx, cx, dx, di, si, es
		.enter

		; lock the window block

		push	cx			; save inval flags
		push	ds			; save source pointer
		call	FarWinLockFromDI	; ds -> window
		segmov	es, ds			; es -> window
		pop	ds			; ds -> source matrix

		push	di			; save window handle
		mov	di, W_TMatrix+TM_11	; set up pointer to matrix
		mov	cx, (size TransMatrix)/2 ; #words to copy
		rep	movsw			; copy the matrix
		sub	si, size TransMatrix	; restore si
		mov	di, W_TMatrix		; set up pointer to matrix
		call	SetTMatrixFlags		; check/set matrix flags
		pop	di			;DI <- win handle


		; finish for window: UnlockV block, inval CurMatrix

		andnf	es:[W_grFlags], not (mask WGF_XFORM_VALID \
					  or mask WGRF_PATH_VALID shl 8 \
					  or mask WGRF_WIN_PATH_VALID shl 8)
		pop	cx			; restore inval flag
		cmp	cx, WIF_INVALIDATE	; invalidate ?
		jne	unlockWin		;  no, skip it
		call	InvalWholeWin		; invalidate the whole window
unlockWin:
		mov	bx, di			; get handle for window
		call	MemUnlockV		; unlock, disown block
		.leave
		ret
WinSetTransformReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinApplyTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catenate transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to window or GState 
		ds:si	- pointer to new TMatrix to use
		cx	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		apply the new transformation to W_TMatrix 

		Performs the following matrix multiplication:

		  W_TMatrix	   =	matrix        *   W_TMatrix

		[ w11  w12  0 ]     [ tm11  tm11  0 ]   [ w11  w12  0 ]
		[ w21  w22  0 ]  =  [ tm11  tm11  0 ] * [ w21  w22  0 ]
		[ w31  w32  1 ]     [ tm11  tm11  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
WinApplyTransform	proc	far
		mov	ss:[TPD_callVector].segment, size TMatrix
		mov	ss:[TPD_dataBX], handle WinApplyTransformReal
		mov	ss:[TPD_dataAX], offset WinApplyTransformReal
		GOTO	SysCallMovableXIPWithDSSIBlock
WinApplyTransform	endp
CopyStackCodeXIP	ends

else

WinApplyTransform	proc	far
	FALL_THRU	WinApplyTransformReal
WinApplyTransform	endp

endif

WinApplyTransformReal proc	far

		uses	ax, bx, cx, dx, di, si, ds, es
appTMatrix	local	TMatrix
		.enter

		; set up local version of TMatrix

		push	cx			; save inval win flags
		mov	bx, di			; save here too
		segmov	es, ss, ax
		lea	di, appTMatrix
		clr	ax
		mov	cx, size TMatrix	; store all zeroes
		rep	stosb			; clear out temp matrix
		lea	di, appTMatrix.TM_11	; set up pointer to matrix
		mov	cx, (size TransMatrix)/2; #words to copy
		rep	movsw			; copy the matrix
		lea	di, appTMatrix
		call	SetTMatrixFlags		; set flags for temp matrix

		; lock the window block

		mov	di, bx			; restore window handle
		call	FarWinLockFromDI	; ds -> window
		push	di			;Save window handle
		segmov	es, ss, bx
		lea	di, appTMatrix		; es:di -> source matrix
		mov	si, W_TMatrix		; ds:si -> window matrix
 
 		; assume the full deal, since they could have used WinTranslate
		; etc.. easier.
 
		call	TMatrixPreMul		; do the whole thing
		segmov	es, ds, di		; es -> window
		mov	di, W_TMatrix		; set up pointer to matrix
		call	SetTMatrixFlags		; check/set matrix flags
 
		; finish for window: UnlockV block, inval CurMatrix

		pop	di			;Restore window handle
		pop	cx			; restore inval win flag
		cmp	cx, WIF_INVALIDATE	; invalidate the window ?
		jne	unlockWin		;  no, skip it
		call	InvalWholeWin		; invalidate the whole window
unlockWin:
		andnf	es:[W_grFlags], not (mask WGF_XFORM_VALID \
					  or mask WGRF_PATH_VALID shl 8 \
					  or mask WGRF_WIN_PATH_VALID shl 8)
		mov	bx, di			; get handle for window
		call	MemUnlockV		; unlock, disown block
 		.leave
 		ret
WinApplyTransformReal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GApplyTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catenate transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState 
		ds:si	- pointer to new TMatrix elements to use
			  There should be six elements, each a 32-bit fixed
			  point number (1 word integer, 1 word fraction), 
			  arranged in row order.  That is, for the matrix:
				[e11 e12 0]
				[e21 e22 0]
				[e31 e32 1]
			   The passed array should be the six elements:
				[e11 e12 e21 e22 e31 e32]

RETURN:		es	- gstate segment

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		apply the new transformation to GS_TMatrix 

		Performs the following matrix multiplication:

		  GS_TMatrix	   =	matrix          *   GS_TMatrix

		[ gs11  gs12  0 ]     [ tm11  tm11  0 ]   [ gs11  gs12  0 ]
		[ gs21  gs22  0 ]  =  [ tm11  tm11  0 ] * [ gs21  gs22  0 ]
		[ gs31  gs32  1 ]     [ tm11  tm11  1 ]   [ gs31  gs32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GApplyTransform proc	far

;this will give a nice warning message if WWFixed is not an even number
;of bytes. this assumptions is made through out this routine
CheckHack < ((size WWFixed and 1) eq 0) >

		uses	di, si, dx, ds
gaMatrix	local	TMatrix
		.enter

		; move the supplied matrix elements into a stack frame so
		; we can expand them into the full TMatrix structure.

 		mov	bx, di			; save GState
		segmov	es, ss, di
		lea	di, gaMatrix.TM_11
		mov	cx, (size TransMatrix)/2
		rep	movsw			; transfer elements in right
		mov	word ptr gaMatrix.TM_flags, TM_COMPLEX or TM_TRANSLATED
		lea	di, gaMatrix

 		; assume the full deal, since they could have used GrTranslate
		; etc.. easier.
 
 		call	MemLock			; bx = gstate handle
 		mov	ds, ax			; set up segreg
 		mov	si, GS_TMatrix		; set up pointer to matrix
		call	TMatrixPreMul		; do the whole thing
		segmov	es, ds, di
 		mov	di, GS_TMatrix		; set up pointer to matrix
		call	SetTMatrixFlags	; check/set matrix flags

		; restore stack and registers

		.leave
 		ret
GApplyTransform endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreApplyTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the window TMatrix, pre-applying the transformation
		matrix formed by the offsets passed

CALLED BY:	GLOBAL

PASS:		ss:dx	- pointer to PointWWFixed structure
		ds:si	- ptr to TMatrix structure
				
RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:

		The following matrix multiplication is performed:

		  TMatrix	   =	matrix       *   TMatrix

		[ tm11  tm12  0 ]     [  1   0   0 ]   [ tm11  tm12  0 ]
		[ tm21  tm22  0 ]  =  [  0   1   0 ] * [ tm21  tm22  0 ]
		[ tm31  tm32  1 ]     [ Tx  Ty   1 ]   [ tm31  tm32  1 ]

		tm31 = tm11*Tx + tm21*Ty + tm31
		tm32 = tm12*Tx + tm22*Ty + tm32

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreApplyTranslation	proc	far
xOffset		local	WWFixed
yOffset		local	WWFixed
		uses	es, di, cx, dx
		.enter
		mov	di, dx			; ss:di points at PointWWFixed
		mov	cx, ss:[di].PF_x.WWF_int ; get integer portions
		mov	xOffset.WWF_int, cx	
		mov	cx, ss:[di].PF_y.WWF_int
		mov	yOffset.WWF_int, cx
		mov	cx, ss:[di].PF_x.WWF_frac ; get fraction portions
		mov	xOffset.WWF_frac, cx	
		mov	cx, ss:[di].PF_y.WWF_frac
		mov	yOffset.WWF_frac, cx
		segmov	es, ss, di
		lea	di, xOffset		; es:di -> xOffset
		add	si, TM_11		; ds:si -> tm11
		call	GrMulWWFixedPtr
		mov	ax, dx
		cwd
		add	ds:[si+TM_31.DWF_frac-TM_11], cx	; add to tm31
		adc	ds:[si+TM_31.DWF_int.low-TM_11], ax
		adc	ds:[si+TM_31.DWF_int.high-TM_11], dx
		add	si, TM_22-TM_11		; ds:si -> tm22
		lea	di, yOffset
		call	GrMulWWFixedPtr
		mov	ax, dx
		cwd
		add	ds:[si+TM_32.DWF_frac-TM_22], cx	; add to tm32
		adc	ds:[si+TM_32.DWF_int.low-TM_22], ax
		adc	ds:[si+TM_32.DWF_int.high-TM_22], dx
		sub	si, TM_22
		test	ds:[si].TM_flags, TM_ROTATED
		jz	finished		; no rotation, all done

		; some rotation component, deal with extra multiplies

		add	si, TM_21		; ds:si -> tm21
		call	GrMulWWFixedPtr		; 
		mov	ax, dx
		cwd
		add	ds:[si+TM_31.DWF_frac-TM_21], cx; add in final part
		adc	ds:[si+TM_31.DWF_int.low-TM_21], ax
		adc	ds:[si+TM_31.DWF_int.high-TM_21], dx
		add	si, TM_12-TM_21
		lea	di, xOffset
		call	GrMulWWFixedPtr
		mov	ax, dx
		cwd
		add	ds:[si+TM_32.DWF_frac-TM_12], cx ; add in final part
		adc	ds:[si+TM_32.DWF_int.low-TM_12], ax
		adc	ds:[si+TM_32.DWF_int.high-TM_12], dx
		sub	si, TM_12
finished:
		.leave
		ret
PreApplyTranslation	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreApplyExtTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate the window TMatrix, pre-applying the transformation
		matrix formed by the 32-bit offsets passed

CALLED BY:	GLOBAL

PASS:		ss:dx	- pointer to PointDWord structure
		ds:si	- ptr to TMatrix structure
				
RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:

		The following matrix multiplication is performed:

		  TMatrix	   =	matrix       *   TMatrix

		[ tm11  tm12  0 ]     [  1   0   0 ]   [ tm11  tm12  0 ]
		[ tm21  tm22  0 ]  =  [  0   1   0 ] * [ tm21  tm22  0 ]
		[ tm31  tm32  1 ]     [ Tx  Ty   1 ]   [ tm31  tm32  1 ]

		tm31 = tm11*Tx + tm21*Ty + tm31
		tm32 = tm12*Tx + tm22*Ty + tm32

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreApplyExtTranslation	proc	far
xOffset		local	DWFixed
yOffset		local	DWFixed
		uses	es, di, cx, dx
		.enter
		mov	di, dx			; ss:di points at PointDWord
		mov	ax, ss:[di].PD_x.low 		; get integer portions
		mov	xOffset.DWF_int.low, ax	
		mov	ax, ss:[di].PD_x.high 		; get integer portions
		mov	xOffset.DWF_int.high, ax	
		mov	ax, ss:[di].PD_y.low
		mov	yOffset.DWF_int.low, ax
		mov	ax, ss:[di].PD_y.high
		mov	yOffset.DWF_int.high, ax
		clr	ax				; clear out fractions
		mov	xOffset.DWF_frac, ax	
		mov	yOffset.DWF_frac, ax
		segmov	es, ss, di
		lea	di, xOffset		; es:di -> xOffset
		add	si, TM_11		; ds:si -> tm11
		call	MulWWFbyDWF
		add	ds:[si+TM_31.DWF_frac-TM_11], bx	; add to tm31
		adc	ds:[si+TM_31.DWF_int.low-TM_11], cx
		adc	ds:[si+TM_31.DWF_int.high-TM_11], dx
		add	si, TM_22-TM_11		; ds:si -> tm12
		lea	di, yOffset
		call	MulWWFbyDWF
		add	ds:[si+TM_32.DWF_frac-TM_22], bx	; add to tm32
		adc	ds:[si+TM_32.DWF_int.low-TM_22], cx
		adc	ds:[si+TM_32.DWF_int.high-TM_22], dx
		sub	si, TM_22
		test	ds:[si].TM_flags, TM_ROTATED
		jz	finished		; no rotation, all done

		; some rotation component, deal with extra multiplies

		add	si, TM_21		; ds:si -> tm21
		call	MulWWFbyDWF		; 
		add	ds:[si+TM_31.DWF_frac-TM_21], bx; add in final part
		adc	ds:[si+TM_31.DWF_int.low-TM_21], cx
		adc	ds:[si+TM_31.DWF_int.high-TM_21], dx
		add	si, TM_12-TM_21
		lea	di, xOffset
		call	MulWWFbyDWF
		add	ds:[si+TM_32.DWF_frac-TM_12], bx ; add in final part
		adc	ds:[si+TM_32.DWF_int.low-TM_12], cx
		adc	ds:[si+TM_32.DWF_int.high-TM_12], dx
		sub	si, TM_12
finished:
		.leave
		ret
PreApplyExtTranslation	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInverse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to calculate inverse factors for trans matrix

CALLED BY:	INTERNAL (GrPrepReverseTrans)

PASS:		ds:si	- TMatrix needing calculation
		dl	- matrix optimization flags

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		see GrPrepReverseTrans (above)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcInverse	proc	far

		; if the inverse factors are already valid, don't do them
		; again.

		test	ds:[si].TM_flags, mask TF_INV_VALID
		LONG jnz CI_done

		; check for rotated matrix, then do lots more

		mov	al, dl
		test	al, TM_ROTATED		; rotation components ?
		jnz	CI_rot			;  yes, deal with it

		; no rotation, only scaling: calc 1/Sx and 1/Sy
		; while we're doing this, check for zero scale factor, which
		; would make the inverse factor nonsense.   Also, the inverse
		; factors are now stored as DDFixed numbers.  There is no way
		; that we'll overflow WWFixed math if there is no rotation,
		; so be sure to initialize the high word and low fraction 
		; fields appropriately.

		mov	ax, ds:[si].TM_11.WWF_frac	; do 1/Sx first
		mov	bx, ds:[si].TM_11.WWF_int
		mov	cx, ax				; check for zero
		or	cx, bx
		jcxz	haveXInv
		call	GrReciprocal32Far		; take reciprocal
haveXInv:
		clr	ds:[si].TM_xInv.DDF_frac.low
		mov	ds:[si].TM_xInv.DDF_frac.high, ax ; store inv factor
		mov	ax, bx				; need to make dword
		cwd
		movdw	ds:[si].TM_xInv.DDF_int, dxax
		mov	ax, ds:[si].TM_22.WWF_frac	; do 1/Sy
		mov	bx, ds:[si].TM_22.WWF_int
		mov	cx, ax				; check for zero
		or	cx, bx
		jcxz	haveYInv
		call	GrReciprocal32Far		; take reciprocal
haveYInv:
		clr	ds:[si].TM_yInv.DDF_frac.low
		mov	ds:[si].TM_yInv.DDF_frac.high, ax ; store inv factor
		mov	ax, bx
		cwd
		movdw	ds:[si].TM_yInv.DDF_int, dxax
		or	ds:[si].TM_flags, mask TF_INV_VALID ; sig valid
		jmp	short CI_done		; all done

		; rotation component, do more work.  Also, we have the 
		; possibility here of big numbers, since we are dealing with
		; the scaling components squared.  So that means we have to
		; do the big time DDFixed math.  Yuck.
CI_rot:
		push	es			; need to set up both -> window
		segmov	es, ds			; set both -> window
		mov	di, si			; set both -> matrix
		add	si, TM_12		; ds:si -> TM_12
		add	di, TM_21		; es:di -> TM_21
		call	GrMulWWFixedToDDF	; dxcxbxax has result (dx high)
		push	dx
		push	cx
		push	bx
		push	ax			; save 64-bit result 
		add	si, TM_11-TM_12		; ds:si -> TM_11
		add	di, TM_22-TM_21		; es:di -> TM_22
		call	GrMulWWFixedToDDF	; dxcxbxax has result (dx high)
		pop	di			; restore prev result
		sub	ax, di			; 
		pop	di
		sbb	bx, di
		pop	di
		sbb	cx, di
		pop	di
		sbb	dx, di
		mov	di, ax			; check for zero
		or	di, bx
		or	di, cx
		or	di, dx
		jz	haveRotInv
		call	GrReciprocalDDF		; calc reciprocal

		; we want to optimize where appropriate, and we may not need
		; that extra bit of fraction.  If the fractional component
		; of the number (high part) is above TM_WFRAC_MIN, then clear
		; out the low word of the fraction.
haveRotInv:
		cmp	bx, TM_WFRAC_MIN
		jb	haveFrac
		clr	ax				; don't save if not req
haveFrac:
		movdw	ds:[si-TM_11].TM_xInv.DDF_frac, bxax ; store inverse 
		movdw	ds:[si-TM_11].TM_xInv.DDF_int, dxcx
		movdw	ds:[si-TM_11].TM_yInv.DDF_frac, bxax	; same for both
		movdw	ds:[si-TM_11].TM_yInv.DDF_int, dxcx
		or	ds:[si-TM_11].TM_flags, mask TF_INV_VALID ; sig valid
		pop	es			; restore es
CI_done:
		ret
CalcInverse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnTransCoordFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do complex part of reverse translation

CALLED BY:	INTERNAL
		GrUnTransCoord, WinUnTransCoord

PASS: 		dx.cx	- x coordinate to untranslate
		bx.ax	- y coordinate to untranslate
		ds:si	- far pointer to matrix

RETURN:		carry	- set if some overflow from 32-bit integer part
			  if carry is set, coordinates are invalid
		dx.cx 	- untranslated x coordinate 
		bx.ax 	- untranslated y coordinate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see notes for GrUnTransCoord, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnTransCoordFixed	proc	far
		uses	es,di,si			; save a few regs
tempX		local	DDFixed
tempY		local	DDFixed
		.enter

		; no matter what we do, we have to do these adds

		mov	di, ax				; save y fraction
		mov	ax, dx				; ax.cx = x coord
		cwd					; dx.ax.cx = x coord
		sub	cx, ds:[si].TM_31.DWF_frac	
		sbb	ax, ds:[si].TM_31.DWF_int.low
		sbb	dx, ds:[si].TM_31.DWF_int.high
		push	ax				; save x.int.low
		mov	ax, bx				; ax = y.int.low
		mov	bx, dx				; bx = x.int.high
		cwd					; dx = y.int.high
		sub	di, ds:[si].TM_32.DWF_frac	
		sbb	ax, ds:[si].TM_32.DWF_int.low
		sbb	dx, ds:[si].TM_32.DWF_int.high

		; if we were only doing translation, we're done

		test	ds:[si].TM_flags, TM_COMPLEX
		jnz	complexTrans		; nope, do it hard way

		; all done, so restore the registers, and check for overflow

		CheckDWordResult dx, ax			; check y coord result
		pop	dx				; dx.cx = x coord
		jc	exit
		CheckDWordResult bx, dx			; check x coord result
		mov	bx, ax				; bx = y.int.low	
		mov	ax, di				; bx.ax = y coord
exit:
		.leave
		ret

		; save away result for mult.  Make sure the inverse factors are
		; calculated.
complexTrans:
		test	ds:[si].TM_flags, mask TF_INV_VALID ; is it valid ?
		jz	validateInverse
inverseValid:
		clr	tempY.DDF_frac.low
		mov	tempY.DDF_frac.high, di	; store away y coordinate
		movdw	tempY.DDF_int, dxax
		clr	tempX.DDF_frac.low
		mov	tempX.DDF_frac.high, cx	; store away x coord
		pop	tempX.DDF_int.low
		mov	tempX.DDF_int.high, bx

		segmov	es, ss, di		; get es:di -> x-TM_31
		lea	di, tempX.DDF_frac.high	; es:di -> x-TM_31
		test	ds:[si].TM_flags, TM_ROTATED
		jnz	UTC_rotated		; rotated, do lots o' work

		; scaling, but no rotation, just mul by factor in window

		add	si, TM_xInv.DDF_frac.high ; ds:si -> WWF inverse factor
		call	MulWWFbyDWF		; dx.cx.bx = value
		mov	tempX.DDF_frac.high, bx	; save value
		movdw	tempX.DDF_int, dxcx
		lea	di, tempY.DDF_frac.high	; es:di -> y-TM_32
		add	si, TM_yInv-TM_xInv 	; ds:si -> WWF inverse factor
		call	MulWWFbyDWF		; dx.cx.bx = y doc coord

		; translation is finished: check result, setup return values.
		; at this point, the final y value is in dx.cx.bx

		CheckDWordResult dx, cx
		jc	exit			; just return if overflow
		mov	ax, bx			; set up y return value
		mov	bx, cx			; bx.ax = y return value
		mov	cx, tempX.DDF_frac.high
		movdw	didx, tempX.DDF_int	; setup x return value
		CheckDWordResult di, dx		; set flag and we're gone
		jmp	exit

		; inverse factor is not up to date, make it so.
validateInverse:
		push	ax,bx,cx,dx,si,di
		mov	dl, ds:[si].TM_flags
		call	CalcInverse
		pop	ax,bx,cx,dx,si,di
		jmp	inverseValid
;---------------------------------------

		; special case: do backward rotation
UTC_rotated:					; es:di -> x-TM_31
		add	si, TM_22 		; ds:si -> TM_22
		call	MulWWFbyDWF		; do 32x48-bit multiply
		push	dx, cx, bx		; save TM_22(x-TM_31)
		add	si, TM_12-TM_22		; ds:si -> TM_12
		call	MulWWFbyDWF		; dx.cx.bx = TM_12(x-TM_31)
		pop	tempX.DDF_frac.high	; recover TM22(x-TM31) fr stack
		pop	tempX.DDF_int.low
		pop	tempX.DDF_int.high
		push	dx, cx, bx		; save TM_12(x-TM_31)

		lea	di, tempY.DDF_frac.high	; es:di -> y-TM_32
		add	si, TM_21-TM_12		; ds:si -> TM_21
		call	MulWWFbyDWF		; dx.cx.bx = TM_21(y-TM_32)
		sub	tempX.DDF_frac.high, bx	; need space for last result
		sbb	tempX.DDF_int.low, cx
		sbb	tempX.DDF_int.high, dx	
		add	si, TM_11-TM_21		; ds:si -> TM_11
		call	MulWWFbyDWF		; dx.cx.bx = TM_11(y-TM_32)
		pop	ax			; ax = TM_12(x-TM_31).frac
		sub	bx, ax
		pop	ax			; ax = TM_12(x-TM_31).int.low
		sbb	cx, ax
		pop	ax			; ax = TM_12(x-TM_31).int.high
		sbb	dx, ax			; dx.cx.bx = final y coord
		mov	tempY.DDF_frac.high, bx	; save away value
		movdw	tempY.DDF_int, dxcx

		; now apply the inverse factor we precalculated.

		lea	di, tempX
		add	si, TM_xInv-TM_11	; ds:si -> DDF inverse factor
		call	MulDDF			; dxcxbxax = value
		movdw	tempX.DDF_frac, bxax	; save value
		movdw	tempX.DDF_int, dxcx
		lea	di, tempY		; es:di -> y-TM_32
		add	si, TM_yInv-TM_xInv 	; ds:si -> WWF inverse factor
		call	MulDDF			; dxcxbxax = y doc coord

		; translation is finished: check result, setup return values.
		; at this point, the final y value is in dx.cx.bx

		shl	ax, 1
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0
		CheckDWordResult dx, cx
		LONG jc	exit			; just return if overflow
		mov	ax, bx			; set up y return value
		mov	bx, cx			; bx.ax = y return value
		movdw	didx, tempX.DDF_int	; setup x return value
		mov	cx, tempX.DDF_frac.high
		tst	tempX.DDF_frac.low
		jns	checkResult
		add	cx, 1
		adc	dx, 0
		adc	di, 0
checkResult:
		CheckDWordResult di, dx		; set flag and we're gone
		jmp	exit
UnTransCoordFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransformByMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the coordinate-pair by the passed TransMatrix

CALLED BY:	GLOBAL
	
PASS:		DS:SI	= TransMatrix
		AX	= X coordinate
		BX	= Y coordinate
		
RETURN:		AX	= new X coordinate
		BX	= new Y coordinate

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrTransformByMatrix	proc	far
		mov	ss:[TPD_callVector].segment, size TransMatrix
		mov	ss:[TPD_dataBX], handle GrTransformByMatrixReal
		mov	ss:[TPD_dataAX], offset GrTransformByMatrixReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrTransformByMatrix	endp
CopyStackCodeXIP	ends

else

GrTransformByMatrix	proc	far
		FALL_THRU	GrTransformByMatrixReal
GrTransformByMatrix	endp

endif

GrTransformByMatrixReal	proc	far
		uses	cx, dx, di, si, ds
		.enter

		sub	sp, size TMatrix
		mov	di, sp
		call	ConvertTransMatrixToTMatrix
		call	TransCoordCommonFar
		add	sp, size TMatrix

		.leave
		ret
GrTransformByMatrixReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransformByMatrixDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the coordinate-pair by the passed TransMatrix

CALLED BY:	GLOBAL
	
PASS:		DS:SI	= TransMatrix
		DX.CX	= X coordinate
		BX.AX	= X coordinate
		
RETURN: 	DX.CX	= new X coordinate
		BX.AX	= new X coordinate

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrTransformByMatrixDWord	proc	far
		mov	ss:[TPD_callVector].segment, size TransMatrix
		mov	ss:[TPD_dataBX], handle GrTransformByMatrixDWordReal
		mov	ss:[TPD_dataAX], offset GrTransformByMatrixDWordReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrTransformByMatrixDWord	endp
CopyStackCodeXIP	ends

else

GrTransformByMatrixDWord	proc	far
		FALL_THRU	GrTransformByMatrixDWordReal
GrTransformByMatrixDWord	endp

endif

GrTransformByMatrixDWordReal	proc	far
		uses	di, si, ds
		.enter

		sub	sp, size TMatrix
		mov	di, sp
		call	ConvertTransMatrixToTMatrix
		call	TransExtCoordCommonFar
		add	sp, size TMatrix

		.leave
		ret
GrTransformByMatrixDWordReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUntransformByMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	UnTransform the coordinate-pair by the passed TransMatrix
		(most likely to go from device coords to document coords)

CALLED BY:	GLOBAL
	
PASS:		DS:SI	= TransMatrix
		AX	= X coordinate (GrUntransformByMatrix)
		BX	= Y coordinate (GrUntransformByMatrix)
			- or -
		DX.CX	= X coordinate  (GrUntransformByMatrixDWord)		
		BX.AX	= X coordinate  (GrUntransformByMatrixDWord)		
		
RETURN:		AX	= new X coordinate (GrUntransformByMatrix)
		BX	= new Y coordinate (GrUntransformByMatrix)
			- or -
		DX.CX	= new X coordinate  (GrUntransformByMatrixDWord)
		BX.AX	= new X coordinate  (GrUntransformByMatrixDWord)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrUntransformByMatrix	proc	far
		mov	ss:[TPD_callVector].segment, size TransMatrix
		mov	ss:[TPD_dataBX], handle GrUntransformByMatrixReal
		mov	ss:[TPD_dataAX], offset GrUntransformByMatrixReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrUntransformByMatrix	endp
CopyStackCodeXIP	ends

else

GrUntransformByMatrix	proc	far
		FALL_THRU	GrUntransformByMatrixReal
GrUntransformByMatrix	endp

endif

GrUntransformByMatrixReal	proc	far
		uses	di, si, ds
		.enter

		sub	sp, size TMatrix
		mov	di, sp
		call	ConvertTransMatrixToTMatrix
		call	UnTransCoordCommonFar
		add	sp, size TMatrix

		.leave
		ret
GrUntransformByMatrixReal	endp

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrUntransformByMatrixDWord	proc	far
		mov	ss:[TPD_callVector].segment, size TransMatrix
		mov	ss:[TPD_dataBX], handle GrUntransformByMatrixDWordReal
		mov	ss:[TPD_dataAX], offset GrUntransformByMatrixDWordReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrUntransformByMatrixDWord	endp
CopyStackCodeXIP	ends

else

GrUntransformByMatrixDWord	proc	far
		FALL_THRU	GrUntransformByMatrixDWordReal
GrUntransformByMatrixDWord	endp

endif

GrUntransformByMatrixDWordReal	proc	far
		uses	di, si, ds
		.enter

		sub	sp, size TMatrix
		mov	di, sp
		call	ConvertTransMatrixToTMatrix
		call	UnTransExtCoordCommonFar
		add	sp, size TMatrix

		.leave
		ret
GrUntransformByMatrixDWordReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTransMatrixToTMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a TransMatrix into a TMatrix buffer, and calculate
		any values needed.

CALLED BY:	INTERNAL

PASS:		DS:SI	= TransMatrix
		SS:DI	= TMatrix buffer

RETURN:		DS:SI	= TMatrix

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertTransMatrixToTMatrix	proc	near
		uses	cx, dx, ax, bx, es, di
		.enter
	
		; Copy the TransMatrix into a temporary TMatrix on the stack
		;
		segmov	es, ss, dx
		push	di			; save start of TMatrix
		mov	cx, size TransMatrix
		rep	movsb
		pop	di			; TMatrix => ES:DI
		call	SetTMatrixFlags		; initialize TMatrix flags
		mov	ds, dx
		mov	si, di			; TMatrix => DS:SI
		mov	dl, ds:[si].TM_flags
		push	si			; save pointer
		call	CalcInverse		; calculate inverse factors
		pop	si

		.leave
		ret
ConvertTransMatrixToTMatrix	endp

GraphicsTransformUtils ends

;---

; This ends up making sense because the common place for this routine to
; be called from is drawing underlines

GraphicsText segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransCoordFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a fixed pt coordinate, 

CALLED BY:	GLOBAL
		GrTransformWWFixed

PASS:		ds:si	- pointer to TMatrix to use
		dx.cx	- x coordinate (document coordinates)
		bx.ax	- y coordinate (document coordinates)

RETURN:		carry	- set if overflow condition (if set, coords are invalid)
		dx.cx	- x coordinate (screen coordinates)
		bx.ax	- y coordinate (screen coordinates)

DESTROYED:	

PSEUDO CODE/STRATEGY:
		see TransCoord for equations (above)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version (split out from GrTransCoord)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransCoordFixed	proc	far
		uses	es, di			; save a bunch of regs
		.enter

		; check for an easy out

		test	ds:[si].TM_flags, TM_COMPLEX
		jnz	complexTrans		; nope, do it hard way

		; all complex transformations end with adding r31 and r32
doTranslation:
		mov	di, ax				; save y fraction
		mov	ax, dx
		cwd					; form high word of int
		add	cx, ds:[si].TM_31.DWF_frac	; get low words of each
		adc	ax, ds:[si].TM_31.DWF_int.low	; add high word
		adc	dx, ds:[si].TM_31.DWF_int.high	; add high word
		CheckDWordResult dx, ax			; check for overflow
		jc	done
		xchg	di, ax				; di= x int, ax= y frac
		xchg	ax, bx				; bx=frac, ax=int
		cwd					; make sdword
		add	bx, ds:[si].TM_32.DWF_frac
		adc	ax, ds:[si].TM_32.DWF_int.low	; add lo part of int
		adc	dx, ds:[si].TM_32.DWF_int.high	; add hi part of int
		CheckDWordResult dx, ax			; check for overflow
		mov	dx, di				; dx = x int
		xchg	ax, bx				; ax=y frac, bx= y int

		; done with complex translation, restore stack and exit
done:
		.leave
		ret

		; complex transformation. save passed coordinate.
complexTrans:
		call	TransCoordFixedComplex
		jmp	doTranslation

TransCoordFixed	endp

GraphicsText ends

;---

GraphicsTextObscure segment resource

TransCoordFixedComplex	proc	far
tempX		local	WWFixed
tempY		local	WWFixed
		.enter

		mov	tempX.WWF_frac, cx		; save passed coords
		mov	tempX.WWF_int, dx
		mov	tempY.WWF_frac, ax		
		mov	tempY.WWF_int, bx	
		segmov	es, ss, di			; set up es:di ->
		lea	di, tempX
		add	si, TM_11			; ds:si -> TM_11

		; since both scale/rotate need TM_11*x and TM_22*y, do it

		call	GrMulWWFixedPtr			; do 32-bit multiply
		mov	ax, cx				; set bx:ax = TM_11*x
		mov	bx, dx
		add	si, TM_22-TM_11			; set ds:si->TM_22
		lea	di, tempY			; set es:di->y
		call	GrMulWWFixedPtr			; dx:cx = TM_22*y
		xchg	ax, cx				; move x into dx.cx
		xchg	bx, dx				;  and y into bx.ax

		; see if we need to do more work for rotation

		sub	si, TM_22			; ds:si -> matrix
		test	ds:[si].TM_flags, TM_ROTATED
		jz	done				; yes, do final muls

		; do full transformation, one more mul for each of x and y

		push	dx, cx				; save x partial result
		lea	di, tempX
		add	si, TM_12			; ds:si->r12
		call	GrMulWWFixedPtr			; dx:cx = r12*x
		add	ax, cx				; add to previous result
		adc	bx, dx
		pop	dx, cx				; restore prev x result
		push	ax, bx				; save new part y result
		mov	bx, dx				; bx.ax = part x result
		mov	ax, cx
		lea	di, tempY			; es:di -> y
		add	si, TM_21-TM_12			; ds:si -> TM_21
		call	GrMulWWFixedPtr			; dx:cx = r21*y
		add	cx, ax				; dx.cx = part x result
		adc	dx, bx
		pop	ax, bx				; bx.ax = part y result
		sub	si, TM_21			; ds:si -> matrix
done:
		.leave
		ret

TransCoordFixedComplex endp

GraphicsTextObscure ends
