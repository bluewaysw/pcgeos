COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Window
FILE:		winTrans.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    EXT	WinUnTransCoord		- translate from screen to document coordinates
    GBL	WinUntransform	- translate from screen to document coordinates
    EXT	WinTransCoord		- translate from document to screen coordinates
    GBL	WinTransCoordFar	- translate from document to screen coordinates
    GBL	WinTransform	- translate from document to screen coordinates
    GBL	WinApplyRotation	- apply rotation to current window transform
    GBL	WinApplyScale		- apply scale factor to current window transform
    GBL	WinApplyTranslation	- apply translation to current window transform,
				  subset of WinScroll
    GBL	WinSetTransform		- replace window transformation matrix
    GBL	WinApplyTransform	- catenate window transformation matrix
    GBL	WinSetNullTransform	- replace window transformation matrix with NULL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/89		Initial revision
	jim	8/9/89		Changed names, used kernel library


DESCRIPTION:
	This file contains routines used by the windowing system to
	translate coordinates via the set of transformation matrices.

        Transformation routines:

	There are two sets of coordinate transformation routines available
	under PC GEOS:  the Gr... set and the Win...  set.  This file
	contains the code to implement the Gr... set of routines.

	The difference is this:  there are (at least) two transformation
	matrices maintained for each window on the screen -- one that
	is kept in the window, and the other that is kept in the
	associated gstate.  The window t-matrix is used to apply a document
	wide transformation, such as scaling or scrolling the entire
	document.  The gstate t-matrix is used to scale or rotate a particular
	object without affecting the rest of the document. The same types
	of operations could be done (like in PostScript) with only one
	transformation matrix.  This method makes it a little easier. If
	multiple gstates are used for a single window, then each gstate
	will have its own transformation matrix that is applied when it
	is used for drawing.

	If you are interested in transforming document coordinates to
	device coordinates, or vice-versa, then you probably want to use
	the WinTransform and WinUntransform routines.  They
	do the right transformation, ignoring the effect of any gstate
	applied transformation.  To get the full effect of the current
	gstate transformation, use GrTransform and GrUntransform.

	$Id: winTrans.asm,v 1.1 97/04/05 01:16:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinUnTransCoord 	WinUntransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a coordinate pair from screen coordinates to
		document coordinates, ignoring the effect of any transformation
		in the associated gstate.

CALLED BY:	EXTERNAL	(WinUnTransCoord)
		GLOBAL		(WinUntransform)

PASS:		ax	- x screen coordinate
		bx	- y screen coordinate
		ds	- PLocked Window structure	(WinUnTransCoord)
		di	- window or gstate handle	(WinUntransform)

RETURN:		carry	- set if some error.  

		if carry is set:
			ax - error code, type WinErrEnum.  one of:
				WE_WINDOW_CLOSING - window is closing
				WE_GSTRING_PASSED - passed handle was a gstring
						    handle
				WE_COORD_OVERFLOW - coord overflowed 16-bits
			bx - destroyed
		if carry is clear:
			ax	- x document coordinate 
			bx	- y document coordinate 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine does the reverse translation from screen to
		document coordinates using W_TMatrix.

		The reverse translation is optimized depending on the type
		of transformation done:

		no scaling or rotation:
			x = x'-r31		y = y'-r32

		no rotation:
			x = (x'-r31)/r11	y = (y'-r32)/r22

		full translation:
			x = (r22(x'-r31) - r21(y'-r32)) / (r11r22-r12r21)
			y = (r11(y'-r32) - r12(x'-r31)) / (r11r22-r12r21)

		For the scaling and scaling/rotation cases, the denominator
		part of the divide operation (actually, its reciprocal) is
		pre-calculated and stored in the Window structure, to make
		this operation fast.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/89		Initial revision
	Jim	4/89		Updated to use common routine UnTransComplex
	Jim	4/89		Added global entry point
	Doug	7/89		Added return of carry flag if window being
				destroyed (Used in UI Flow object to prevent
				disasters)
	jim	8/89		Changed name from WinUnTranslateCoord

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinUntransform proc	far
		push	ds, di
		call	FarWinLockFromDI	; lock the window
		jc	exitGS			; nothing to do for gstring
		test	ds:[W_regFlags], mask WRF_CLOSED ; see if closing
		jnz	exitClosing
		call	WinUnTransCoord		; do rev xlation
doneTrans:
		pushf				; save carry
		push	bx			; save coordinate
		mov	bx, di			; get handle for block
		call	NearUnlockV		; unlock, disown block
		pop	bx			; restore coordinate
		popf				; restore carry
exit:
		pop	ds, di
		ret

exitGS:
		mov	ax, WE_GSTRING_PASSED	; gstring handle was passed
		jmp	exit
exitClosing:
		mov	ax, WE_WINDOW_CLOSING
		stc
		jmp	doneTrans

WinUntransform endp

WinUnTransCoord	proc	near

		; first subtract out the window offsets

		sub	ax, ds:[W_winRect].R_left
		sub	bx, ds:[W_winRect].R_top

		; convert passed word values to double words.
		; x coordinate in dx.cx  and  y coordinate in bx.ax

		push	si
		mov	si, W_TMatrix
		call	UnTransCoordCommonFar		; use common routine
		pop	si				; restore reg
		jnc	done
		mov	ax, WE_COORD_OVERFLOW		; signal error type
done:
		ret
WinUnTransCoord	endp

WinMisc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinUntransformDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		dx.cx	- x screen coordinate (32-bit integer)
		bx.ax	- y screen coordinate (32-bit integer)
		di	- window or gstate handle	(WinUntransformDWord)

RETURN:		if carry is set:
			passed di was to a gstring or a window that is closing
			ax,bx,cx,dx unchanged

		if carry is not set:
			dx.cx	- x document coordinate (32-bit integer)
			bx.ax	- y document coordinate (32-bit integer)


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see WinUntransform, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinUntransformDWord proc	far
		push	ds, di
		call	FarWinLockFromDI	; lock the window
		jc	exitGS			; nothing to do for gstring
		test	ds:[W_regFlags], mask WRF_CLOSED ; see if closing
		jnz	exitClosing
		call	WinUnTransExtCoord	; do rev xlation
doneTrans:
		pushf
		push	bx			; save coordinate
		mov	bx, di			; get handle for block
		call	MemUnlockV		; unlock, disown block
		pop	bx			; restore coordinate
		popf				; restore carry
exit:
		pop	ds, di
		ret

exitGS:
		mov	ax, WE_GSTRING_PASSED	; gstring handle was passed
		jmp	exit
exitClosing:
		mov	ax, WE_WINDOW_CLOSING
		stc
		jmp	doneTrans

WinUntransformDWord endp

WinUnTransExtCoord	proc	near
		uses	si
		.enter

		; before we do anything, subtract out the window offsets

		push	dx, cx			; save x coord
		mov	cx, ax
		mov	ax, ds:[W_winRect].R_top ; need to convert to sdword
		cwd
		sub	cx, ax			; 
		sbb	bx, dx
		pop	dx, ax			; restore x coord
		push	bx, cx			; save y coord
		mov	bx, dx
		mov	cx, ax
		mov	ax, ds:[W_winRect].R_left ; add in x offset
		cwd
		sub	cx, ax			; 
		sbb	bx, dx			; bx.cx = x coord
		mov	dx, bx
		pop	bx, ax			; bx.ax = y coord

		; finish untrans

		mov	si, W_TMatrix
		call	UnTransExtCoordCommonFar	; use common routine

		.leave
		ret
WinUnTransExtCoord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTransCoord	WinTransform WinIntTransCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	translate coordinate from document coordinates to screen
		coordinates, ignoring the effect of any transformation
		in the associated gstate.

CALLED BY:	EXTERNAL	(WinTransCoord)
		GLOBAL		(WinTransform)

PASS:		ax - x coordiante (document coordinates)
		bx - y coordinate (document coordinates)
		ds - Window structure		(WinTransCoord or 
						 WinIntTransCoord)
		di - window handle		(WinTransform only)

RETURN:		carry	- set if some error.  

		if carry is set:
			ax - error code, type WinError.  one of:
				WE_WINDOW_CLOSING - window is closing
				WE_GSTRING_PASSED - passed handle was a gstring
						    handle
				WE_COORD_OVERFLOW - coord overflowed 16-bits
			bx - destroyed
		if carry is clear:
			ax	- x screen coordinate 
			bx	- y screen coordinate 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The basic algorithm for converting from document coordinates
		to screen coordinates involves the following matrix
		multiplication.

		   [x'  y'  1] = [x   y   1] *  [ r11  r12  0 ]
						[ r21  r22  0 ]
						[ r31  r32  1 ]

		This results in the following equations:

		   x' = r11x + r21y + r31
		   y' = r12x + r22y + r32

		The code is optimized for the cases of no rotation (r12=r21=0),
		and no rotation/scaling (r12=r21=0, r11=r22=1).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes Window structure is already locked;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/89...		Initial version (from GrTransCoord)
	Jim	4/89		Added global entry point
	jim	8/89		Changed name from WinTranslateCoord

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode segment

WinTransform proc	far
		push	ds, di
		call	FarWinLockFromDI	; lock the window
		jc	exitGS
		call	WinTransCoord		; do rev xlation
		pushf
		push	bx			; save coordinate
		mov	bx, di			; get handle for block
		call	MemUnlockV		; unlock, disown block
		pop	bx			; restore coordinate
		popf
exit:
		pop	ds, di
		ret

exitGS:
		mov	ax, WE_GSTRING_PASSED
		jmp	exit

WinTransform endp

WinTransCoord	proc	far
		uses	cx, dx
		.enter

		; just use the routine done for GrXXXX routines

		push	si				; save si
		mov	si, W_TMatrix			; set up matrix ptr
		call	TransCoordCommon		; use common routine
		pop	si				; save restore
		jc	doneErr
		add	ax, ds:[W_winRect].R_left	; add in x offset
		add	bx, ds:[W_winRect].R_top	; add it y offset
		clc					; make sure add 
							; doesn't set carry!
done:
		.leave
		ret

doneErr:
		mov	ax, WE_COORD_OVERFLOW		; signal error type
		jmp	done
WinTransCoord	endp

kcode ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinTransformDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a 32-bit integer document coordinate to screen coords

CALLED BY:	GLOBAL

PASS:		dx.cx	- x document coordinate (32-bit integer)
		bx.ax	- y document coordinate (32-bit integer)
		di	- window or gstate handle	(WinUntransformDWord)

RETURN:		dx.cx	- x screen coordinate (32-bit integer)
		bx.ax	- y screen coordinate (32-bit integer)
		carry set if di is a gstate or a window that is closing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see WinUntransform, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version
		Chris 	4/26/91		Changed to return carry

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinTransformDWord	proc	far
		push	ds, di
		call	FarWinLockFromDI	; lock the window
		jc	exitGS
		call	WinTransExtCoord	; do rev xlation
		push	bx			; save coordinate
		mov	bx, di			; get handle for block
		call	MemUnlockV		; unlock, disown block
		pop	bx			; restore coordinate
		clc				; say there was a window
exit:
		pop	ds, di
		ret

exitGS:
		mov	ax, WE_GSTRING_PASSED
		jmp	exit
WinTransformDWord	endp

WinTransExtCoord	proc	far
		push	si
		mov	si, W_TMatrix
		call	TransExtCoordCommonFar	; use common routine
		pop	si			; restore reg

		; now we have to add in the window offset.  Only take a sec.

		push	dx, cx			; save x coord
		mov	cx, ax
		mov	ax, ds:[W_winRect].R_top ; need to convert to sdword
		cwd
		add	cx, ax			; 
		adc	bx, dx
		pop	dx, ax			; restore x coord
		push	bx, cx			; save y coord
		mov	bx, dx
		mov	cx, ax
		mov	ax, ds:[W_winRect].R_left ; add in x offset
		cwd
		add	cx, ax			; 
		adc	dx, bx			; dx.cx = x coord
		pop	bx, ax			; bx.ax = y coord
		ret
WinTransExtCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinApplyRotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply rotation to a transformation matrix

CALLED BY:	GLOBAL

PASS:		di	- handle to window or GState
		dx.ax	- angle to rotate (WWFixed)
		si	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN:		carry set if di is a gstate or a window that is closing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Apply rotation to DefMatrix matrix.
		mark CurXform as invalid

		The following matrix multiplication is performed:

		  W_TMatrix      =    rotation	      *   W_TMatrix

		[ w11  w12  0 ]     [  cos  -sin  0 ]   [ w11  w12  0 ]
		[ w21  w22  0 ]  =  [  sin   cos  0 ] * [ w21  w22  0 ]
		[ w31  w32  1 ]     [    0     0  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	jim	8/89		Changed name from WinRotate, use kernel lib
	Chris 	4/26/91		Changed to return carry

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinApplyRotation proc	far
		call	PushAllFar

		; lock the window block

		call	FarWinLockFromDI	; see if GState OR win, lock win
		jc	exit			; nothing to do for gstring
	
		; set up pointer to matrix

		push	si, di			; save invalidation flag
		mov	si, W_TMatrix		; set up pointer to matrix
		call	RotateCommon		; use common rotation routine
		call	CalcInverse		; calc inverse factors
		pop	si, di			; restore invalidation flag

		; finish for window: invalidate win and curMatrix, UnlockV block

		call	FinishWinTransform	; unlock window, inval if necc.
		clc				; say OK
exit:
		call	PopAllFar
		ret
WinApplyRotation endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishWinTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common utility routine used by a few WinApplyXXXX functions

CALLED BY:	INTERNAL
		WinApplyRotation, WinApplyTranslation

PASS:		ds	- locked/owned window segment address
		si	- WinInvalFlag
		di	- window handle

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FinishWinTransform proc	near
		;
		; set window transform invalid, invalidate window if desired
		; also invalidate any application clip regions
		;
		andnf	{word}ds:[W_grFlags], \
			not (mask WGF_XFORM_VALID or \
			     mask WGRF_PATH_VALID shl 8 or \
			     mask WGRF_WIN_PATH_VALID shl 8)
		cmp	si, WIF_INVALIDATE	; need to invalidate ?
		jne	unlockWin		;  no, skip it
		call	InvalWholeWin		; invalidate the window

		; unlock/disown the window
unlockWin:
		mov	bx, di			; get handle for block
		call	MemUnlockV		; unlock, disown block
		ret
FinishWinTransform endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalWholeWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the whole window, causing redraw

CALLED BY:	INTERNAL

PASS:		ds	- window segment

RETURN:		ds	- new window segment

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		Setup up temp region = WHOLE_REG;
		add temp region to InvalReg;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvalWholeWin	proc	far

		; now that we're done with TMatrix, set InvalReg to whole

		push	di			; save window handle
		push	si
		segmov	es, ds			; es -> Window struct
		mov	di, ds:[W_temp1Reg]	; di = chunk handle
		call	FarWinWHOLEReg		; set Temp1 to whole region
		segmov	ds, es			; in case it moved
		call	WinAddToInvalReg	; add to invalidation region
		pop	si
		pop	di			; restore window handle
		ret
InvalWholeWin	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinApplyScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply scale factor to transformation matrix

CALLED BY:	GLOBAL

PASS:		di	- handle to window
		dx.cx	- X-scale factor (WWFixed)
		bx.ax	- Y-scale factor (WWFixed)
		si	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN:		carry set if di is a gstate or a window that is closing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Apply scaling to appropriate matrix.
		mark CurXform as invalid

		The following matrix multiplication is performed:

		  W_TMatrix      =    scale        *   W_TMatrix

		[ w11  w12  0 ]     [  Sx   0  0 ]   [ w11  w12  0 ]
		[ w21  w22  0 ]  =  [   0  Sx  0 ] * [ w21  w22  0 ]
		[ w31  w32  1 ]     [   0   0  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	jim	8/89		Changed name from WinScale
	jim	11/89		Eliminated options to scale about a point.
				They screw up other parts of the system and
				are generally more work here than in an
				application.
	Chris 	4/26/91		Changed to return carry


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinApplyScale	proc	far	
		call	PushAllFar

		; lock the window block

		call	FarWinLockFromDI	; ds -> window, di=window handle
		jc	exit

		; check for scaling by one, in which case we'll leave

		cmp	dx, 1			; check for scale of one
		jne	doTheScale		;  no, do it
		cmp	bx, 1			; check for scale of one
		jne	doTheScale		;  no, do it
		tst	cx
		jnz	doTheScale	
		tst	ax
		jz	unlockWin		; everything is zero, exit

		; set up for call into KLib, can't use ax,bx
doTheScale:
		push	si, di			; save invalidation flag
		mov	si, W_TMatrix		; set up pointer to matrix
		call	ScaleCommon		; use common routine
		call	CalcInverse		; calc new inverse factors
		pop	si, di			; restore inval flag
		call	FinishWinTransform	; set flags, etc.
		clc				; window did exist
exit:
		call	PopAllFar
		ret
unlockWin:
		mov	bx, di			; get handle for block
		call	MemUnlockV		; unlock, disown block
		clc				; window did exist
		jmp	exit
WinApplyScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinApplyTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply translation to the current window transform

CALLED BY:	GLOBAL

PASS:		di	- window handle
		dx.cx	- x translation to apply  (WWFixed)
		bx.ax	- y translation to apply  (WWFixed)
		si	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN		carry set if di is a gstate or a window that is closing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Add the offsets to the current matrix;

		The following matrix multiplication is performed:

		  W_TMatrix      =    translation *   W_TMatrix

		[ w11  w12  0 ]     [  1   0  0 ]   [ w11  w12  0 ]
		[ w21  w22  0 ]  =  [  0   1  0 ] * [ w21  w22  0 ]
		[ w31  w32  1 ]     [ Tx  Ty  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: 	The window is not Blt'd or invalidated, if you
			want this behaviour, use WinScroll.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	09/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinApplyTranslation proc	far
		uses	ds, ax, bx, cx, dx
		.enter

		; lock the window block

		call	FarWinLockFromDI	; ds -> window, di=window handle
		jc	exit
		call	WinApplyTransCommon	; do the real work
		call	FinishWinTransform	; do unlocking, invalidating
		clc				; window OK
exit:
                .leave
		ret

WinApplyTranslation endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinApplyTranslationDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a 32-bit translation to the current window tmatrix

CALLED BY:	GLOBAL

PASS:		di	- window handle
		dx.cx	- x translation to apply (32-bit integer)
		bx.ax	- y translation to apply (32-bit integer)
		si	- WinInvalFlag enum
			  WIF_INVALIDATE 	- to invalidate the window
			  WIF_DONT_INVALIDATE 	- to avoid invalidating window

RETURN:		carry set if di is a gstate or a window that is closing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see WinApplyTranslation, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version
		Chris 	4/26/91		Changed to return carry

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinApplyTranslationDWord	proc	far
		uses	ds, ax, bx, cx, dx, si
tOffset		local	PointDWord
		.enter

		; lock the window block

		call	FarWinLockFromDI	; ds -> window, di=window handle
		jc	exit

		; see if simple operation, or more detailed..

		or      ds:[W_TMatrix].TM_flags, TM_TRANSLATED 
		test	ds:[W_TMatrix].TM_flags, TM_COMPLEX
		jnz	doComplex

		; no scale or rotate, just some adds..

		add     ds:[W_TMatrix].TM_32.DWF_int.low, ax    ; add in Y off
		adc	ds:[W_TMatrix].TM_32.DWF_int.high, bx
		add     ds:[W_TMatrix].TM_31.DWF_int.low, cx    ; add in X off
		adc	ds:[W_TMatrix].TM_31.DWF_int.high, dx
done:
		call	FinishWinTransform	; do unlocking, invalidating
		clc				; window OK
exit:
                .leave
		ret

		; handle complex transformation matrix
doComplex:
		push	si			; save invalidate flag

		; copy the args to the stack

		mov	tOffset.PD_x.low, cx ; copy x factor over
		mov	tOffset.PD_x.high, dx 
		mov	tOffset.PD_y.low, ax ; copy y factor over
		mov	tOffset.PD_y.high, bx 
		mov	si, W_TMatrix		; ds:si -> matrix
		lea	dx, tOffset		; ss:bp -> PointWWFixed
		call	PreApplyExtTranslation
		pop	si			; restore invalidate flag
		jmp	done
WinApplyTranslationDWord	endp

WinMisc ends

GrWinBlt segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinApplyTransCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used by both WinApplyTranslation and WinScroll

CALLED BY:	INTERNAL

PASS:		ds	- points to locked/owned window
		dx.cx	- x scroll amount (WWFixed)
		bx.ax	- y scroll amount (WWFixed)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do the right matrix manipulation thing.  See description in
		WinApplyTranslation.

		One strange thing about this routine.  I have found that in
		WinScroll, we occasionally end up with a rounding error of
		one in the fractions place (that is, 1/65535th), due to 
		the inherent inaccuracies of dealing with fixed point math.
		Hence here we check for -1 and 1 in the one's place, and 
		round appropriately.  It seems to do the right thing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinApplyTransCommon	proc	far
		uses	ax, cx, dx
tOffset		local	PointWWFixed
		.enter

		or      ds:[W_TMatrix].TM_flags, TM_TRANSLATED 
		test	ds:[W_TMatrix].TM_flags, TM_COMPLEX
		jnz	doComplex
		add     ds:[W_TMatrix].TM_31.DWF_frac, cx    ; add in X off
		adc	ds:[W_TMatrix].TM_31.DWF_int.low, dx
		mov	cx, ax				 	; save y frac
		mov	ax, dx
		cwd
		adc	ds:[W_TMatrix].TM_31.DWF_int.high, dx
		add     ds:[W_TMatrix].TM_32.DWF_frac, cx    ; add in Y off
		adc	ds:[W_TMatrix].TM_32.DWF_int.low, bx
		mov	ax, bx
		cwd
		adc	ds:[W_TMatrix].TM_32.DWF_int.high, dx

		; we are done.  but check for wierd rounding (see header)
done:
		cmp	ds:[W_TMatrix].TM_31.DWF_frac, 1 ; check for 1
		jne	checkXneg1
		clr	ds:[W_TMatrix].TM_31.DWF_frac
		jmp	checkY
checkXneg1:
		cmp	ds:[W_TMatrix].TM_31.DWF_frac, -1 ; check for -1
		jne	checkY
		add	ds:[W_TMatrix].TM_31.DWF_frac, 1
		adc	ds:[W_TMatrix].TM_31.DWF_int.low, 0 
		adc	ds:[W_TMatrix].TM_31.DWF_int.high, 0 
checkY:
		cmp	ds:[W_TMatrix].TM_32.DWF_frac, 1 ; check for 1
		jne	checkYneg1
		clr	ds:[W_TMatrix].TM_32.DWF_frac
		jmp	exit
checkYneg1:
		cmp	ds:[W_TMatrix].TM_32.DWF_frac, -1 ; check for -1
		jne	exit
		add	ds:[W_TMatrix].TM_32.DWF_frac, 1
		adc	ds:[W_TMatrix].TM_32.DWF_int.low, 0 
		adc	ds:[W_TMatrix].TM_32.DWF_int.high, 0 
exit:
		.leave
		ret

		; handle complex transformation matrix. stand back.
doComplex:
		push	si			; save invalidate flag

		; copy the args to the stack

		mov	tOffset.PF_x.WWF_int, dx ; copy x factor over
		mov	tOffset.PF_x.WWF_frac, cx	
		mov	tOffset.PF_y.WWF_int, bx ; copy y factor over
		mov	tOffset.PF_y.WWF_frac, ax	
		mov	si, W_TMatrix		; ds:si -> matrix
		lea	dx, tOffset		; ss:dx -> PointWWFixed
		call	PreApplyTranslation
		pop	si			; restore invalidate flag
		jmp	done
WinApplyTransCommon	endp

GrWinBlt ends
