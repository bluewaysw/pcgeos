COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		Graphics/grUtils.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    INT GrTransCoord2Far	Translate 2 coordinate pairs
    INT GrTransCoord2		Translate 2 coordinate pairs
    INT GrTransCoordFar		translate coordinate from document
				coordinates to screen coordinates,
    INT GrTransform	
    INT GrTransCoord		
    INT TransCoordCommon
    INT TransExtCoordCommon
    GLB GrTransformWWFixed	Translate a coordinate presented in fixed
				point notation
    GLB GrTransformDWFixed	Translate a coordinate presented in fixed
				point notation
    INT TransComplex		Translate a coordinate, transformation has
				scaling/rotation
    GLB GrTransformDWord	Transform 32-bit document coords to 32-bit
				screen coords
    GLB GrUntransformDWord	UnTransform 32-bit document coords to
				32-bit screen coords
    GLB GrUntransform	Translate a coordinate pair from screen
				coordinates to document coordinates,
    GLB UnTransCoordCommon	Translate a coordinate pair from screen
				coordinates to document coordinates,
    GLB UnTransExtCoordCommon	Translate a coordinate pair from screen
				coordinates to document coordinates,
    GLB GrUntransformWWFixed	Untranslate a coordinate presented in fixed
				point notation
    GLB GrUntransformDWFixed	Untranslate a coordinate presented in fixed
				point notation
    INT UnTransComplex		Do complex part of reverse translation
    INT EnterTranslate		Utility entry and exit routines used by
				global versions of the GrTransform and
				GrUntransform
    INT ExitTranslate		Utility entry and exit routines used by
				global versions of the GrTransform and
				GrUntransform
    GLB GrCopyDrawMask		Set the draw mask buffer pointed to from
				the draw mask index passed in dl
    EXT GrShiftDrawMask		Align draw masks with window position on
				screen
    INT GrShiftMaskFar		Utility routine to do the shifting
    INT GrShiftMask		Utility routine to do the shifting
    GLB GrMapColorToGrey	Map a color index to a bit pattern
    GLB CalcLuminance		Map a color index to a bit pattern
    GLB GrCalcLuminance		Given an RGB triplet, calculate the
				luminance of the pixel
    INT EnterGraphicsTemp	Enter or exit a graphics routine by saving
				registers, getting the graphics semaphore,
				updating grWinSeg and validating the
				clipping structure
    INT EnterGraphics		Enter or exit a graphics routine by saving
				registers, getting the graphics semaphore,
				updating grWinSeg and validating the
				clipping structure
    INT ExitGraphics		Enter or exit a graphics routine by saving
				registers, getting the graphics semaphore,
				updating grWinSeg and validating the
				clipping structure
    INT ExitGraphicsGseg	Enter or exit a graphics routine by saving
				registers, getting the graphics semaphore,
				updating grWinSeg and validating the
				clipping structure
    GLB GrGrabExclusive	Start drawing exclusively to a video driver
    GLB GrReleaseExclusive		Stop drawing exclusively to a video driver

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	4/88	initial version
	jim	8/89	changed names GrTransform and GrUntransform


DESCRIPTION:
	This file contians a number of internal routines used by the
	graphics system.

	$Id: graphicsUtils.asm,v 1.1 97/04/05 01:12:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the VM file in the associated Window or GString, if any.

		This routine must be called if the VM file handle stored in
		the Window/GString has changed (eg., via VMSaveAs)

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax	- VM file handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		Check to see whether there's a Window or a GString
		Stuff the VM file in if so

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 mar 1993	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetVMFile	proc	far
		uses	ds, ax, bx, cx
		.enter

EC <		call	ECCheckGStateHandle				>

	;
	;  See if there's a window
	;

		mov_tr	cx, ax			; cx <- VM file handle
		mov	bx, di			; lock GState
		call	MemLock			; ax -> GState
		mov	ds, ax			; ds -> GState
		mov	ax, ds:[GS_window]	; get window handle
		tst	ax
		jz	checkGString

		call	MemUnlock
		mov_tr	bx, ax			; lock window
		call	MemPLock		; ax -> Window
		mov	ds, ax			; ds -> Window
		xchg	cx, ds:[W_bitmap].handle

	;
	;  If W_bitmap was 0 to begin with, we'd like to leave it that way
	;

		jcxz	resetBitmap

unlockWin:
		call	MemUnlockV		; release window
done:
		.leave
		ret

resetBitmap:
		mov	ds:[W_bitmap].handle, cx
		jmp	unlockWin


checkGString:
		mov	ax, ds:[GS_gstring]	; get window handle
		call	MemUnlock
		tst	ax
		jz	done

	;
	;  Lock the GString down and write in the VM file if it's a
	;  VM based gstring
	;

		mov_tr	bx, ax
		call	MemLock
		mov	ds, ax
		mov	ax, ds:[GSS_flags]		; test the flags
		and	ax, mask GSF_HANDLE_TYPE	; isolate type
		cmp	al, GST_VMEM			; chunk based ?
		jne	unlockGString

	;
	;  If GSS_hString was 0, keep it that way
	;

		xchg	cx, ds:[GSS_hString]
		jcxz	resetGString
unlockGString:
		call	MemUnlock
		jmp	done
resetGString:
		mov	ds:[GSS_hString], cx
		jmp	unlockGString
GrSetVMFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetUpdateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the passed gstate's handle into its Window's
		W_updateState, returning the GState that was previously there.

CALLED BY:	GLOBAL

PASS:		di	- GState handle

RETURN:		carry set if no Window, else
		di	- GState that was previosuly in the
			  Window's W_updateState field

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 mar 1993	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetUpdateGState	proc	far
		uses	ds, ax, bx
		.enter

EC <		call	ECCheckGStateHandle				>

	;
	;  See if there's a window
	;

		mov	bx, di			; lock GState
		call	MemLock			; ax -> GState
		mov	ds, ax			; ds -> GState
		mov	ax, ds:[GS_window]	; get window handle
		tst	ax
		call	MemUnlock
		stc
		jz	done

	;
	;  Stuff the gstate's handle into the Window, returning
	;  whatever it over-writes
	;

		mov_tr	bx, ax			; lock window
		call	MemPLock		; ax -> Window
		mov	ds, ax			; ds -> Window
		xchg	di, ds:[W_updateState]	; stuff it!
		call	MemUnlockV		; release window
		clc
done:
		.leave
		ret
GrSetUpdateGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransCoord2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate 2 coordinate pairs

CALLED BY:	INTERNAL

PASS:		ax 	- x1 (document coords)
		bx 	- y1 (document coords)
		cx 	- x2 (document coords)
		dx 	- y2 (document coords)
		es 	- Window structure segment

RETURN:		carry	- set if an overflow on any translation
		ax 	- x1 (device coords)
		bx 	- y1 (device coords)
		cx 	- x2 (device coords)
		dx 	- y2 (device coords)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call GrTransCoord for each pait;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTransCoord2Far	proc	far
		call	GrTransCoord2
		ret
GrTransCoord2Far	endp

GrTransCoord2	proc	near
		uses	ds, si, di, bp
		.enter

		segmov	ds, es, si
		mov	si, W_curTMatrix	; use Window matrix to xlate
		mov	bp, cx			; save 2nd coord pair
		mov	di, dx
		call	TransCoordCommon
		xchg	bp, ax			; get 2nd, save first pair
		xchg	di, bx
		jc	done
		call	TransCoordCommon
		mov	cx, ax			; align all the results in the
		mov	dx, bx			;  right registers
		mov	ax, bp
		mov	bx, di
done:
		.leave
		ret
GrTransCoord2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransCoord	GrTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	translate coordinate from document coordinates to screen
		coordinates, including the effect of the gstate transformation
		matrix and the window transformation matrix.

CALLED BY:	INTERNAL	(GrTransCoord)
		EXTERNAL	(GrTransCoordFar) (for use by other kernel mods)
		GLOBAL		(GrTransform)

PASS:		ax - x coordiante to translate
		bx - y coordinate to translate

		di - GState handle		(GrTransform only)
		es - Window structure		(GrTransCoord, GrTransCoordFar)

RETURN:		carry	- set if translation overflow, else
		ax - translated x coordinate
		bx - translated y coordinate

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
	Jim	4/88...		Initial version
	Jim	3/89		Rewritten to use transformation matrix
	Jim	4/89		Global routine added

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTransCoordFar	proc	far
		call	GrTransCoord		; global entry point for
		ret				; kernel library
GrTransCoordFar	endp

GrTransform proc	far
		call	EnterTranslate		; lock windows, etc.
		push	dx, cx
		call	TransCoordCommon
		pop	dx, cx
		jmp	ExitTranslate		; unlock windows, etc.
GrTransform endp

GrTransCoord	proc	near
		uses	dx, cx, ds, si
		.enter
		segmov	ds, es, si
		mov	si, W_curTMatrix	; use Window matrix to xlate
		call	TransCoordCommon
		.leave
		ret
GrTransCoord	endp

;
;	This utility routine is used by a few different routines.  It xlates
;	a coordinate pair, given a pointer (in ds:si) to a TMatrix.  There is
;	an alternate entry point for 32-bit routines to use.
;	
;	passed:	ds:si	- pointer to TMatrix
;		ax	- x coordinate	(TransCoordCommon)
;		bx	- y coordinate	(TransCoordCommon)
;		dx.cx	- x coordinate  (TransExtCoordCommon)
;		bx.ax	- y coordinate  (TransExtCoordCommon)
;	return	carry	- set if 32-bit integers would overflow a 16-bit word
;			  (TransCoordCommon)
;		ax	- x device coordinate	(TransCoordCommon)
;		bx	- y device coordinate	(TransCoordCommon)
;		dx.cx	- transformed x coord (TransExtCoordCommon)
;		bx.ax	- transformed y coord (TransExtCoordCommon)
;	trashes: 	- cx, dx	(TransCoordCommon)
;			- nothing	(TransExtCoordCommon)

TransCoordCommonFar	proc	far
		call	TransCoordCommon
		ret
TransCoordCommonFar	endp

TransCoordCommon proc near

		; expand coords to 32-bit integers until we have the results

		cwd				; convert x to double
		mov	cx, dx			; cx.ax = x coord
		xchg	ax, bx			; now do y coord
		cwd
		xchg	ax, bx			; dx.bx = y coord

		; see if we're only translating, to make it easy

		test	ds:[si].TM_flags, TM_COMPLEX
		jnz	doComplex			; no, complex operation

		; simple translation of 16-bit coordinates, just add offsets

		add	ax, ds:[si].TM_31.DWF_int.low	; add x offset
		adc	cx, ds:[si].TM_31.DWF_int.high
		tst	ds:[si].TM_31.DWF_frac.high 	; round?
		jns	xlatY
		add	ax, 1				; don't use inc.
		adc	cx, 0

		; all ok.  Do y coordinate
xlatY:
		add	bx, ds:[si].TM_32.DWF_int.low	; add y offset
		adc	dx, ds:[si].TM_32.DWF_int.high
		tst	ds:[si].TM_32.DWF_frac.high 	; round ?
		jns	checkResult
		add	bx, 1
		adc	dx, 0
checkResult:
		CheckDWordResult cx, ax			; check x coord
		jc	done
		CheckDWordResult dx, bx
done:
		ret

		; more complex transformation, use other routine
doComplex:
		call	TransComplex
		jmp	checkResult
TransCoordCommon endp

TransExtCoordCommonFar	proc	far
		call	TransExtCoordCommon
		ret
TransExtCoordCommonFar	endp

TransExtCoordCommon	proc	near

		; see if we're only translating, to make it easy

		test	ds:[si].TM_flags, TM_COMPLEX
		jnz	doComplex			; no, complex operation

		; simple translation , just add offsets

		add	cx, ds:[si].TM_31.DWF_int.low	; add x offset
		adc	dx, ds:[si].TM_31.DWF_int.high
		tst	ds:[si].TM_31.DWF_frac.high 	; round?
		jns	xlatY
		add	cx, 1				; don't use inc.
		adc	dx, 0

		; all ok.  Do y coordinate
xlatY:
		add	ax, ds:[si].TM_32.DWF_int.low	; add y offset
		adc	bx, ds:[si].TM_32.DWF_int.high
		tst	ds:[si].TM_32.DWF_frac.high 	; round ?
		jns	done
		add	ax, 1
		adc	bx, 0
done:
		ret

		; more complex transformation, use other routine
doComplex:
		xchg	ax, bx		; align the regs
		xchg	cx, dx
		xchg	ax, dx
		call	TransComplex
		xchg	ax, dx		; get em back again
		xchg	cx, dx
		xchg	ax, bx
		jmp	done
TransExtCoordCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransformWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	TRanslate a coordinate presented in fixed point notation

CALLED BY:	GLOBAL

PASS:		di	- handle to gstring
		dx.cx	- x coordinate to translate
		bx.ax	- y coordinate to translate

RETURN:		carry	- set if some overflow due to 32-bit document space,
			  if carry set, returned coordinates are invalid
		dx.cx	- translated x coordinate
		bx.ax	- translated y coordinate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTransformWWFixed proc	far
		call	EnterTranslate		; lock windows, etc.
		call	TransCoordFixed
		jmp	ExitTranslate		; unlock windows, etc.
GrTransformWWFixed endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransformDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a coordinate presented in fixed point notation

CALLED BY:	GLOBAL

PASS:		di	- handle to gstring
		es:dx	- points to PointDWFixed coordinate pair

RETURN:		es:dx	- points to transformed PointDWFixed coordinate pair

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTransformDWFixed proc	far

if	FULL_EXECUTE_IN_PLACE
EC <		push	ds, si						>
EC <		segmov	ds, es, si					>
EC <		mov	si, dx						>
EC <		call	ECCheckBounds					>
EC <		pop	ds, si						>
endif
		call	EnterTranslate		; lock windows, etc.
		mov	bp,sp
		mov	es,ss:[bp].ET_es	; seg of PointDWFixed
		call	TransCoordDWFixed
		jmp	ExitTranslate		; unlock windows, etc.
GrTransformDWFixed endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a coordinate, transformation has scaling/rotation

CALLED BY:	INTERNAL
		GrTransCoord, WinTransCoord

PASS:		cx.ax	- x coordinate (32bit integer document coordinates)
		dx.bx	- y coordinate (32bit integer document coordinates)
		ds:si	- far pointer to transformation matrix

RETURN:		cx.ax	- x coordinate (32bit integer screen coordinates)
		dx.bx	- y coordinate (32bit integer screen coordinates)

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
TransComplex	proc	near
		uses	es, di				; save a bunch of regs
origX		local	DWFixed
origY		local	DWFixed
tempX		local	DWFixed
tempY		local	DWFixed
		.enter

		mov	origX.DWF_int.low, ax		; store x coord
		mov	origX.DWF_int.high, cx		
		mov	origY.DWF_int.low, bx		; store y coord
		mov	origY.DWF_int.high, dx	
		clr	ax				
		mov	origX.DWF_frac, ax		; store 0 fractions
		mov	origY.DWF_frac, ax
		segmov	es, ss, di			; set up es:di ->,
		lea	di, origX
		add	si, TM_11			; ds:si -> TM_11

		; since both scale/rotate need TM_11*x and TM_22*y, do it

		call	MulWWFbyDWF			; dx.cx.bx = TM_11*x
		mov	tempX.DWF_frac, bx		;  save result
		mov	tempX.DWF_int.low, cx
		mov	tempX.DWF_int.high, dx
		add	si, TM_22-TM_11			; set ds:si->TM_22
		lea	di, origY			; set es:di->y
		call	MulWWFbyDWF			; dx.cx.bx = TM_22*y

		; see if we need to do more work for rotation

		test	ds:[si-TM_22].TM_flags, TM_ROTATED
		jnz	TC_rotate			; yes, do final muls
		sub	si, TM_22			; ds:si -> matrix

		; all complex transformations end with adding r31 and r32
		; at this point, dx.cx.bx = partial y result
applyTranslation:
		add	bx, ds:[si].TM_32.DWF_frac	; get low words of each
		adc	cx, ds:[si].TM_32.DWF_int.low	; add high word
		adc	dx, ds:[si].TM_32.DWF_int.high	; add high word
		add	bh, 80h				; round result
		adc	cx, 0
		adc	dx, 0
		mov	bx, cx				; set dx.bx = y result

		mov	cx, tempX.DWF_int.high		; load up x partial res
		mov	ax, tempX.DWF_int.low
		mov	di, tempX.DWF_frac

		add	di, ds:[si].TM_31.DWF_frac	; add in x offset
		adc	ax, ds:[si].TM_31.DWF_int.low
		adc	cx, ds:[si].TM_31.DWF_int.high
		add	di, 8000h			; round result
		adc	ax, 0
		adc	cx, 0

		; done with complex translation, restore stack and exit

		.leave
		ret

;------------------------------

		; do full transformation, one more mul for each of x and y
TC_rotate:
		mov	tempY.DWF_frac, bx		; save partial y result
		mov	tempY.DWF_int.low, cx
		mov	tempY.DWF_int.high, dx
		add	si, TM_21-TM_22			; ds:si->r12
		lea	di, origY
		call	MulWWFbyDWF			; dx:cx = r12*x
		add	tempX.DWF_frac, bx		; add to previous result
		adc	tempX.DWF_int.low, cx
		adc	tempX.DWF_int.high, dx
		lea	di, origX			; es:di -> y
		add	si, TM_12-TM_21			; ds:si -> TM_21
		call	MulWWFbyDWF			; dx.cx.bx = r21*x
		add	bx, tempY.DWF_frac		; add to previous result
		adc	cx, tempY.DWF_int.low
		adc	dx, tempY.DWF_int.high
		sub	si, TM_12			; ds:si -> matrix
		jmp	applyTranslation

TransComplex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTransformDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform 32-bit document coords to 32-bit screen coords

CALLED BY:	GLOBAL

PASS:		di	- gstate handle
		dx.cx	- x coordinate (32-bit integer)
		bx.ax	- y coordinate (32-bit integer)

RETURN:		dx.cx	- x coordinate (32-bit integer)
		bx.ax	- y coordinate (32-bit integer)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do full 32-bit translations

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTransformDWord	proc	far
		call	EnterTranslate		; lock windows, etc.
		call	TransExtCoordCommon
		jmp	ExitTranslate		; unlock windows, etc.
GrTransformDWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUntransformDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	UnTransform 32-bit document coords to 32-bit screen coords

CALLED BY:	GLOBAL

PASS:		di	- gstate handle
		dx.cx	- x coordinate (32-bit integer)
		bx.ax	- y coordinate (32-bit integer)

RETURN:		dx.cx	- x coordinate (32-bit integer)
		bx.ax	- y coordinate (32-bit integer)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do full 32-bit translations

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrUntransformDWord	proc	far
		call	EnterTranslate		; lock windows, etc.
		call	UnTransExtCoordCommon
		jmp	ExitTranslate		; unlock windows, etc.
GrUntransformDWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUntransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a coordinate pair from screen coordinates to
		document coordinates, including the effect of the gstate 
		transformation matrix and the window transformation matrix.

CALLED BY:	GLOBAL		

PASS:		ax	- x screen coordinate
		bx	- y screen coordinate
		di	- GState handle			

RETURN:		carry	- set if untransformation will cause an overflow (
			  that is, result is larger than can be expressed in
			  16 bits), else:
		ax	- x document coordinate 
		bx	- y document coordinate 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		basically the reverse of GrTransCoord.  The reverse translation
		is optimized depending on the type of transformation done:

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
		note that cx and dx will normally be zero, unless the document
		has been translated by more than 2^16.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/88...		Initial version
	Jim	3/89		Re-written to use transformation matrix
	Jim	4/89		Global routine added

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrUntransform	proc	far
		call	EnterTranslate		; lock windows, etc
		call	UnTransCoordCommon	; do translation
		jmp	ExitTranslate		; unlock windows, etc.
GrUntransform	endp

;
;	This utility routine is used by a few different routines.  It 
;	untranslates ;	a coordinate pair, given a pointer (in ds:si) 
;	to a TMatrix
;	
;	passed:	ds:si	- pointer to TMatrix
;		ax	- x coordinate (UnTransCoordCommon)
;		bx	- y coordinate (UnTransCoordCommon)
;		dx.cx	- x coordinate (UnTransExtCoordCommon)
;		bx.ax	- y coordinate (UnTransExtCoordCommon)
;	return	carry	- set if overflow occured (UnTransCoordCommon)
;		ax	- document X coordinate   (UnTransCoordCommon)
;		bx	- document Y coordinate   (UnTransCoordCommon)
;		dx.cx	- document X coordinate   (UnTransExtCoordCommon)
;		bx.ax	- document Y coordinate   (UnTransExtCoordCommon)
;
;	trashes: 	- nothing

UnTransCoordCommonFar	proc	far
		call	UnTransCoordCommon
		ret
UnTransCoordCommonFar	endp

UnTransCoordCommon proc near
		uses	cx, dx, es
bigPoint	local	PointDWFixed
		.enter

		; expand coords to DWFixed to get an accurate result

		cwd	
		movdw	bigPoint.PDF_x.DWF_int, dxax
		clr	bigPoint.PDF_x.DWF_frac
		mov	ax, bx
		cwd
		movdw	bigPoint.PDF_y.DWF_int, dxax
		clr	bigPoint.PDF_y.DWF_frac
		segmov	es, ss, dx
		lea	dx, bigPoint
		call	UnTransCoordDWFixed

		movdwf	cxaxbx, bigPoint.PDF_x
		rnddwf	cxaxbx
		CheckDWordResult cx, ax
		jc	done

		movdwf	dxbxcx, bigPoint.PDF_y
		rnddwf	dxbxcx
		CheckDWordResult dx, bx
done:
		.leave
		ret
UnTransCoordCommon endp

UnTransExtCoordCommonFar	proc	far
		call	UnTransExtCoordCommon
		ret
UnTransExtCoordCommonFar	endp

UnTransExtCoordCommon proc near
		uses	es, di
bigPoint	local	PointDWFixed
		.enter

		; expand coords to DWFixed to get an accurate result

		movdw	bigPoint.PDF_x.DWF_int, dxcx
		clr	bigPoint.PDF_x.DWF_frac
		movdw	bigPoint.PDF_y.DWF_int, bxax
		clr	bigPoint.PDF_y.DWF_frac
		segmov	es, ss, dx
		lea	dx, bigPoint
		call	UnTransCoordDWFixed

		movdwf	dxcxdi, bigPoint.PDF_x
		rnddwf	dxcxdi
		movdwf	bxaxdi, bigPoint.PDF_y
		rnddwf	bxaxdi

		.leave
		ret
UnTransExtCoordCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUntransformWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Untranslate a coordinate presented in fixed point notation

CALLED BY:	GLOBAL

PASS:		di	- handle to gstring
		dx.cx	- x coordinate to untranslate
		bx.ax	- y coordinate to untranslate

RETURN:		carry	- set if result would require 32-bit integer.
			  (results invalid if carry is set)
		dx.cx	- untranslated x coordinate 
		bx.ax	- untranslated y coordinate 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		see also GrUntransformDWFixed for 32-bit document spaces.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrUntransformWWFixed proc	far
		call	EnterTranslate		; lock windows, etc.
		call	UnTransCoordFixed
		jmp	ExitTranslate		; unlock windows, etc.
GrUntransformWWFixed endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUntransformDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Untranslate a coordinate presented in fixed point notation

CALLED BY:	GLOBAL

PASS:		di	- handle to gstring
		es:dx	- far pointer to PointDWFixed structure

RETURN:		es:dx	- PointDWFixed value at ds:si is un-transformed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrUntransformDWFixed proc	far

if	FULL_EXECUTE_IN_PLACE
EC <		push	ds, si						>
EC <		segmov	ds, es, si					>
EC <		mov	si, dx						>
EC <		call	ECCheckBounds					>
EC <		pop	ds, si						>
endif
		call	EnterTranslate		; lock windows, etc.
		mov	bp,sp
		mov	es,ss:[bp].ET_es	; seg of PointDWFixed
		call	UnTransCoordDWFixed
		jmp	ExitTranslate		; unlock windows, etc.
GrUntransformDWFixed endp

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnTransComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do complex part of reverse translation

CALLED BY:	INTERNAL
		GrUnTransCoord, WinUnTransCoord

PASS:		cx.ax	- x coordinate (32-bit screen), minus translation part
		dx.bx	- y coordinate (32-bit screen), minus translation part
		ds:si	- far pointer to matrix

RETURN:		cx.ax	- x coordinate (32-bit integer document coordinates)
		dx.bx	- y coordinate (32-bit integer document coordinates)

DESTROYED:	si

PSEUDO CODE/STRATEGY:
		see notes for GrUnTransCoord, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnTransComplex	proc	near
		uses	es,di,si
tempX		local	DDFixed
tempY		local	DDFixed
		.enter

		; check out the inverse factors, and update them if needed
		
		test	ds:[si].TM_flags, mask TF_INV_VALID
		jz	validateInverse

		; init our temp variables
inverseValidated:
		movdw	tempX.DDF_int, cxax	; x integer
		movdw	tempY.DDF_int, dxbx	; y integer
		clr	ax			; get a zero
		clrdw	tempX.DDF_frac, ax 	
		clrdw	tempY.DDF_frac, ax

		segmov	es, ss, di		; get es -> TMatrix segment
		test	ds:[si].TM_flags, TM_ROTATED
		jnz	rotated			; rotated, do lots o' work

		; scaling, but no rotation, just mul by factor in window
lastbit:
		add	si, TM_xInv		; ds:si -> inverse factor
		lea	di, tempX		; es:di -> x-TM_31
		call	MulDDF			; dxcxbxax = x doc coord
		rcl	ax, 1			; get high bit into carry
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0
		push	dx, cx			; save 32-bit integer x coord
		lea	di, tempY		; es:di -> y-TM_32
		add	si, TM_yInv-TM_xInv	; ds:si -> inverse factor
		call	MulDDF			; dx:cx = y doc coord
		rcl	ax, 1			; get high bit into carry
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0
		mov	bx, cx			; dx.bx = y coord
		pop	cx, ax			; cx.ax = x coord
		.leave
		ret

validateInverse:
		push	ax,bx,cx,dx,si,di
		mov	dl, ds:[si].TM_flags
		call	CalcInverse
		pop	ax,bx,cx,dx,si,di
		jmp	inverseValidated
;---------------------------------------

		; special case: do backward rotation
rotated:
		push	tempX.DDF_int.high
		push	tempX.DDF_int.low
		push	tempX.DDF_frac.high	; x-TM31 on stack (as DWFixed)
		add	si, TM_22 		; ds:si -> TM_22
		lea	di, tempX.DDF_frac.high	; es:di -> x-TM_31
		call	MulWWFbyDWF		; do 32-bit multiply
		mov	tempX.DDF_frac.high, bx ; save the result
		movdw	tempX.DDF_int, dxcx 	; save the result

		add	si, TM_21-TM_22		; ds:si -> TM_21
		lea	di, tempY.DDF_frac.high	; es:di -> y-TM_32
		call	MulWWFbyDWF		; dx.cx.bx = TM_21(y-TM_32)
		sub	tempX.DDF_frac.high, bx ; TM_22(x-TM_31)-TM_21(y-TM_32)
		sbb	tempX.DDF_int.low, cx 
		sbb	tempX.DDF_int.high, dx

		add	si, TM_11-TM_21		; ds:si -> TM_11
						; es:di => y-TM_32 (already)
		call	MulWWFbyDWF		; dx:cx.bx = TM_11(y-TM32
		mov	tempY.DDF_frac.high, bx ; save the result
		movdw	tempY.DDF_int, dxcx 

		add	si, TM_12-TM_11		; ds:si -> TM_12
		mov	di, sp			; es:di -> x-TM_31
		call	MulWWFbyDWF		; dx:cx.bx = TM_12(x-TM_31)
		sub	tempY.DDF_frac.high, bx ; TM_11(y-TM_32)-TM_12(x-TM_31)
		sbb	tempY.DDF_int.low, cx
		sbb	tempY.DDF_int.high, dx

		add	si, TM_11-TM_12		; ds:si -> TM_11
		add	sp, (size DWFixed)	; clean up the stack
		jmp	lastbit			; last mul and done
UnTransComplex	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterTranslate  ExitTranslate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility entry and exit routines used by global versions
		of the GrTransform and GrUntransform

CALLED BY:	INTERNAL

PASS:		di	- handle of GState

RETURN:		ds:si	- TMatrix to use, might be W_curTMatrix or GS_TMatrix

DESTROYED:	nothing
		ExitTranslate preserves flags as well

PSEUDO CODE/STRATEGY:
		lock GState and window;
		if matrix not valid, validate it
		If no window, return pointer into GState TMatrix

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version
	Jim	06/90		Changed to do goofy stack thing, return
				pointer to TMatrix instead of just segregs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnterTranslate	proc	near

		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		; NOTE: There is a structure called ETframe in
		;	graphicsConstant.def that is used by the tranform
		;	routines to access registers saved on the
		;	stack by this routine.  If you want to
		;	change the way the stack is treated here
		;	(i.e. add pushes, change the order, etc.)
		;	then be sure to alter the structure.
		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


		;Exchange bp with return address

		XchgTopStack	bp		;;bp = return address

		ON_STACK	bp ret= bp

		push	ds, es, si		; save a few until ExitTransl
		push	ax, bx			; save regs we need here

		ON_STACK	bx  ax  si  es  ds  bp ret= bp

EC <		call	ECCheckGStateHandle				>

		mov	bx, di			; get GState handle in bx
		call	NearLockDS		; ds <- GState
		mov	si, GS_TMatrix		; ds:si -> TMatrix to use
		mov	bx, ds:[GS_window]	; see if there is a window
		tst	bx			; if not, return ptr to GState
		jz	havePointer		;  do it
		call	NearPLockES		;  else own/lock window

		; check W_grFlags to see if xformation matrix is valid

		test	es:[W_grFlags], mask WGF_XFORM_VALID
		jz	validateWindow		;  no, update it
		cmp	di, es:[W_curState]	; right one ?
		je	windowOK		;  yes, do translation

		; need to update transformation matrix, do it
validateWindow:
		push	cx, dx, di
		call	GrComposeMatrix		; compose new matrix
		and	es:[W_grFlags], not mask WGF_XFORM_VALID ; invalidate
		pop	cx, dx, di
windowOK:
		segmov	ds, es, si
		mov	si, W_curTMatrix	; ds:si -> TMatrix to use

		; all done.  We have what we need.
havePointer:
		pop	ax, bx			; restore coords
		jmp	bp			; get back to business
EnterTranslate	endp

;---------------------------------------------------------------------------
;		ExitTranslate	(IMPORTANT: preserves flags)
;---------------------------------------------------------------------------

ExitTranslate	proc	near jmp
		ON_STACK	si  es  ds  bp retf
		push	bx			; save result
		LoadVarSeg ds			; dereference GState handle
		mov	ds, ds:[di].HM_addr	; get address from handle tab
		mov	bx, ds:[GS_window]	; get window handle
		pushf				; save carry status
		tst	bx			; if no window, skip it
		jz	unlockGS
		call	NearUnlockV		; release window
unlockGS:
		popf				; restore carry status	
		mov	bx, di			; get handle of GState
		call	NearUnlock		; release GState
		pop	bx			; restore coord
		pop	ds, es, si		; restore regs pushed in Enter.
		pop	bp
		retf				; returning to caller's caller
ExitTranslate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCopyDrawMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the draw mask buffer pointed to from the draw mask index
		passed in dl

CALLED BY:	GLOBAL
		GrSetLineDrawMode, GrSetAreaDrawMode

PASS:		ds:di	- buffer to put draw mask into
		al	- new pattern index (for system pattern)
		- OR -
		al	- SET_CUSTOM_PATTERN (for custom pattern)
		es:si	- pattern to set

RETURN:		ds:[di] - set to draw mask

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		if (pattern number < 32)
		   set pointer into systm pattern table
		else
		   set pointer into user's pattern table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version
	Doug	9/23/88		Added cs: in front of sysPatt00., changed
				loading of segment for sysPatt00 to cs instead
				of idata.  Assembled
				code was generating wrong address.  sysPatt00
			 	is part of the graphics tables which are
				assembled into code space.
	Tony	10/19/88	Changed to set buffer, not pointer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCopyDrawMask	proc	far

	call	PushAll

	mov	cx, ds				;save dest 

	mov	bl, al				; save high bit (reversal)

	segmov	ds,es				; assume in es
	and	ax, 0x007f			; isolate DrawMask enum
	cmp	al, SDM_CUSTOM			; test for user pattern
	je	GCDM_60

	LoadVarSeg ds
	mov	si, offset idata:sysPatt00 	; set source to system table

	shl	ax, 1				; * 8 for index into table
	shl	ax, 1
	shl	ax, 1
	add	si,ax				; correct pointer

GCDM_60:
	
if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckBounds		 				>	
endif	
	mov	es, cx				; recover dest

	mov	cx,PATTERN_SIZE / 2
	rep movsw

	; now check reversal bit to invert mask

	tst	bl				; else check for reversal
	jns	done				;  nope, done
	sub	di, PATTERN_SIZE
	mov	ax, 0xffff			; invert the bits of mask
	xor	es:[di], ax
	xor	es:[di+2], ax
	xor	es:[di+4], ax
	xor	es:[di+6], ax
done:
	call	PopAll
	ret

GrCopyDrawMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrShiftDrawMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Align draw masks with window position on screen

CALLED BY:	EXTERNAL

PASS:		ds	- segment of GState
		es	- segment of window

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each draw mask in GState:
		   do the shift
		reassign the shift count

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrShiftDrawMask	proc	far
		uses	ax, bx
		.enter

		; if there is no window, skip the shifting.

		tst	ds:[GS_window]
		jz	GSDM_done

		push	ds
		segmov	ds, es				; ds -> window
		clr	ax				; figure out where 0,0
		clr	bx				;  is
		call	WinTransCoord			; get device position
		mov	ds:[W_ditherX], ax		; save dither indices
		mov	ds:[W_ditherY], bx		;  in case printing
		mov	ah, bl				; ah=y shift,al=x shift
		and	ax, 707h			; only need first 3 bits
		mov	ds:[W_pattPos], ax		; save new patt reg
		pop	ds
		cmp	ax, word ptr ds:[GS_xShift]	; see if changed
		je	GSDM_done			;   nope, all done
		mov	bx, si				; save a reg
		mov	si, GS_lineAttr.CA_mask  ; set ptr to 1st buf
		call	GrShiftMask			; shift a mask
		mov	si, GS_areaAttr.CA_mask  ; set ptr to 2nd buf
		call	GrShiftMask			; shift a mask
		mov	si, GS_textAttr.CA_mask  ; set ptr to 3rd buf
		call	GrShiftMask			; shift a mask
		mov	word ptr ds:[GS_xShift], ax	; set new shift amt
		mov	si, bx				; restore a reg
GSDM_done:
		.leave
		ret
GrShiftDrawMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrShiftMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to do the shifting

CALLED BY:	INTERNAL

PASS:		al	- new shift amount in x
		ah	- new shift amount in y
		ds:si	- far pointer to mask buffer

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		rotate in x first, then shuffle in y

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrShiftMaskFar	proc	far
		call	GrShiftMask
		ret
GrShiftMaskFar	endp

GrShiftMask	proc	near

		push	ax, bx, cx, dx
		push	bp				; allocate local space
		mov	bp, sp
		sub	sp, 2				; just need 2 bytes

		; calc relative shifts, store new shift value

		sub	al, ds:[GS_xShift]		; calc relative shift
		sub	ah, ds:[GS_yShift]
		mov	[bp-2], ax			; [bp-2]=xshift,[bp-1]=y

		; first get bytes into registers (can fit all but one)

		mov	ah, ds:[si+1]			; use all regs but cl
		mov	al, ds:[si+2]
		mov	bh, ds:[si+3]
		mov	bl, ds:[si+4]
		mov	ch, ds:[si+5]
		mov	dh, ds:[si+6]
		mov	dl, ds:[si+7]

		; next, do rotates in x

		mov	cl, [bp-2]			; set up shift count
		tst	cl				; see if neg
		js	GSM_absX			;  yes, shift left
		jz	GSM_Xshifted			; no change
		ror	byte ptr ds:[si], cl		; shift all 8 bytes
		ror	ah, cl
		ror	al, cl
		ror	bh, cl
		ror	bl, cl
		ror	ch, cl
		ror	dh, cl
		ror	dl, cl

		; now shuffle bytes in y
GSM_Xshifted:
		mov	cl, [bp-1]			; get count in cl
		tst	cl				; see if negative
		js	GSM_absY			;  yes, shuffle up
		jz	GSM_done			; no change
GSM_10:
		xchg	dl, dh
		xchg	dh, ch
		xchg	ch, bl
		xchg	bl, bh
		xchg	bh, al
		xchg	al, ah
		xchg	ah, ds:[si]			; start shuffling
		dec	cl
		jnz	GSM_10
GSM_done:
		mov	ds:[si+1], ah			; write out new values
		mov	ds:[si+2], al
		mov	ds:[si+3], bh
		mov	ds:[si+4], bl
		mov	ds:[si+5], ch
		mov	ds:[si+6], dh
		mov	ds:[si+7], dl
		mov	sp, bp				; restore stack ptr
		pop	bp				; restore frame ptr
		pop	ax, bx, cx, dx
		ret

GSM_absX:
		neg	cl
		rol	byte ptr ds:[si], cl		; shift all 8 bytes
		rol	ah, cl
		rol	al, cl
		rol	bh, cl
		rol	bl, cl
		rol	ch, cl
		rol	dh, cl
		rol	dl, cl
		jmp	GSM_Xshifted

GSM_absY:
		neg	cl
GSM_20:
		xchg	ah, ds:[si]			; start shuffling
		xchg	ah, al
		xchg	al, bh
		xchg	bh, bl
		xchg	bl, ch
		xchg	ch, dh
		xchg	dh, dl
		dec	cl
		jnz	GSM_20
		jmp	GSM_done


GrShiftMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMapColorToGrey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a color index to a bit pattern

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to CommonAttr structure

RETURN:		ds:bx 	- pattern bytes

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		For MAP_DITHER mode, all colors are mapped to a dithering 
		patterns.  

		color
		writing		passed			PATTERN
		on ?		color 			USED
		-------		------			-------
		white		white			0s
		white		non-white		1s
		black		black			0s
		black		non-black		1s


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrMapColorToGrey	proc	far

if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckBounds						>
endif	
	; check for solid mapping

	mov	ah, ds:[si].CA_mapMode
	test	ds:[si].CA_mapMode, mask CMM_MAP_TYPE
	jz	GMG_solid			;  special case not solid map

	; Check for all white and black as special cases. 

	mov	al, ds:[si].CA_colorRGB.RGB_red ; we need this here anyway
	mov	ah, ds:[si].CA_colorRGB.RGB_green
	mov	bl, ds:[si].CA_colorRGB.RGB_blue
	mov	bh, bl
	and	bh, ah
	and	bh, al
	cmp	bh, 0xff			; if all white, go with it
	je	allZeroes
	tst	ax				; check for zero
	jnz	calcLum
	tst	bl				; check blue value
	jz	allOnes
calcLum:
	call	CalcLuminance

	; we need to map this luminence value (0-255) to a smaller range
	; (0-63) so that's a shift right two bits. We then need to index into
	; a table of dither patterns, 8 bytes each.  Thats a 3-bit shift left.

	shr	bl, 1				; divide luminence by 4
	shr	bl, 1
	adc	bl, 0				; account for rounding
	shl	bx, 1				;   make into an index
	shl	bx, 1
	shl	bx, 1
	add	bx, offset idata:ditherPatterns	; index into dither patterns

done:
	LoadVarSeg	ds			; ds:bx -> pattern
	ret

	; special cases
allZeroes:
	mov	bx, offset idata:ditherZeroes	; assume all white
	jmp	done

allOnes:
	mov	bx, offset idata:ditherOnes	; assume all black
	jmp	done

	; map to solid
GMG_solid:
	mov	bl, ds:[si].CA_colorIndex
	test	ah, mask CMM_ON_BLACK		; test what background color is
	jnz	GMG_onblack			;  on black, chk for non-black
	sub	bl, C_WHITE			;  on white, chk for non-white
GMG_onblack:
	tst	bl				; see if non-background color
	mov	bx, offset idata:ditherZeroes	; assume all zeroes
	jz	done				; if same, use empty pattern
	mov	bx, offset idata:ditherOnes	; else use solid pattern
	jmp	done


GrMapColorToGrey	endp


	; utility routine used by GrMapColorToGrey and GrCalcLuminance
CalcLuminance	proc	near
	uses	cx
	.enter

	; Map color to grey level.  This section of code maps an RGB triplet
	; into a value (0-63) that is used to pick one of 64 dither patterns.
	; The optimal mapping is: level = .299 *red + .587 *green + .114*blue
	; The mapping we use is:  level = .3025*red + .5625*green + .125*blue
	; since it's easier/faster to calculate.

	mov	cx, bx				; save blue value
	clr	bh				; need to calculate index * 3
	shr	al, 1				; red * .5
	shr	al, 1				; red * .25
	mov	bl, al				; bl = red * .25
	shr	al, 1				; red * .125
	shr	al, 1				; red * .0625
	adc	bh, 0				; accumulate carry
	add	bl, al				; bl = red * .3025
	mov	al, ah				; get green component
	shr	al, 1				; green * .5
	add	bl, al				; accum, plus rounding
	shr	al, 1				; green * .25
	shr	al, 1
	shr	al, 1				; green * .0625
	adc	bh, 0
	add	bl, al				; green * .5625
	mov	al, cl				; restore blue
	shr	al, 1
	shr	al, 1
	shr	al, 1				; al = blue * .125
	adc	bh, 0
	add	bl, al				; bl = total luminence
	shr	bh, 1				; divide carries
	adc	bl, bh
	clr	bh
	.leave
	ret
CalcLuminance	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCalcLuminance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an RGB triplet, calculate the luminance of the pixel

CALLED BY:	GLOBAL

PASS:		al,ah,bl	- red, green and blue intensities
RETURN:		al		- luminance (0-255)
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
	 The optimal mapping is: level = .299 *red + .587 *green + .114*blue
	 The mapping we use is:  level = .3025*red + .5625*green + .125*blue
	 since it's easier to calculate.	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrCalcLuminance	proc	far
		uses	bx
		.enter
		call	CalcLuminance
		mov	ax, bx			; return result in ax
		.leave
		ret
GrCalcLuminance	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDocPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current pen position, given document coords

CALLED BY:	INTERNAL
		Gr{Draw,Fill}XXXX routines
PASS:		ax,bx	- new penPos (doc coords)
		ds	- GState
RETURN:		nothing
DESTROYED:	nothing (flags preserved also)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		handles relative mode.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDocPenPos	proc	far
		uses	dx
		.enter

		; save the offset, then translate the origin.

		mov	dx, 0				; DON'T USE CLR
		call	SetDocWBFPenPos			; use common routine

		.leave
		ret

SetDocPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDocWBFPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	More accurate pen positioning routine, for text stuff

CALLED BY:	INTERNAL
		SetDocPenPos, text routines
PASS:		ds	- GState
		ax.dl	- x posiiton (document coords)
		bx.dh	- y position 
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDocWBFPenPosFar	proc	far
		call	SetDocWBFPenPos
		ret
SetDocWBFPenPosFar	endp

SetDocWBFPenPos	proc	near
		uses	cx, ax, dx
		pushf
		.enter

		xchg	ax, dx
		mov	ch, al
		clr	al
		clr	cl
		call	SetDocWWFPenPos

		.leave
		popf
		ret
SetDocWBFPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDocWWFPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set WWFixed pen position

CALLED BY:	INTERNAL
PASS:		ds	- GState
		dx.cx	- x posiiton (WWFixed document coords)
		bx.ax	- y position 
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDocWWFPenPos		proc	far
		pushf					; save carry too
		uses	ax, bx, es, dx, si
penPt	local	PointDWFixed
		.enter

		; save the offset, then translate the origin.

		mov	ss:penPt.PDF_x.DWF_frac, cx
		mov	ss:penPt.PDF_y.DWF_frac, ax
		mov	ax, dx
		cwd
		movdw	ss:penPt.PDF_x.DWF_int, dxax	; save offset
		mov	ax, bx
		cwd
		movdw	ss:penPt.PDF_y.DWF_int, dxax

		; do the translations

		mov	si, offset GS_TMatrix		; ds:si -> matrix
		segmov	es, ss, dx
		lea	dx, ss:penPt			; this one too
		call	TransCoordDWFixed

		; update the current pen position

		mov	si, penPt.PDF_x.DWF_frac	; load up x coord
		movdw	dxax, penPt.PDF_x.DWF_int
		mov	ds:[GS_penPos].PDF_x.DWF_frac, si
		movdw	ds:[GS_penPos].PDF_x.DWF_int, dxax
		mov	si, penPt.PDF_y.DWF_frac	; load up y coord
		movdw	dxax, penPt.PDF_y.DWF_int
		mov	ds:[GS_penPos].PDF_y.DWF_frac, si
		movdw	ds:[GS_penPos].PDF_y.DWF_int, dxax

		.leave
		popf					; restore carry
		ret
SetDocWWFPenPos		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransCoordDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a DWFixed coordinate, 

CALLED BY:	GLOBAL
		GrTransformDWFixed

PASS:		ds:si	- pointer to TMatrix to use
		es:dx	- pointer to PointDWFixed structure

RETURN:		es:dx	- points at same structure with translated value

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		see TransCoord for equations (above)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/91		Initial version (from TransCoordFixed)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransCoordDWFixed	proc	far
		uses	ax,bx,cx,di
		.enter

; make sure that the first element of this structure is PDF_x
CheckHack	< ((offset PDF_x) eq 0) >

		; check for an easy out

		mov	di, dx				; es:di -> PointDWFixed
		test	ds:[si].TM_flags, TM_COMPLEX
		jnz	complexTrans		; nope, do it hard way

		; all complex transformations end with adding r31 and r32
doTranslation:
		mov	bx, ds:[si].TM_31.DWF_frac	; load up x translation
		mov	cx, ds:[si].TM_31.DWF_int.low	
		mov	dx, ds:[si].TM_31.DWF_int.high	
		add	es:[di].PDF_x.DWF_frac, bx	; add it in
		adc	es:[di].PDF_x.DWF_int.low, cx
		adc	es:[di].PDF_x.DWF_int.high, dx

		mov	bx, ds:[si].TM_32.DWF_frac	; load up y translation
		mov	cx, ds:[si].TM_32.DWF_int.low	
		mov	dx, ds:[si].TM_32.DWF_int.high
		add	es:[di].PDF_y.DWF_frac, bx	; add it in
		adc	es:[di].PDF_y.DWF_int.low, cx
		adc	es:[di].PDF_y.DWF_int.high, dx

		; done with translation, restore stack and exit

		mov	dx, di				; es:dx -> PointDWFixed
		.leave
		ret

		; complex transformation. save passed coordinate.
complexTrans:
		call	TComplex
		jmp	doTranslation

TransCoordDWFixed	endp

;---

GraphicsTransformUtils segment resource

TComplex	proc	far
		add	si, TM_11			; ds:si -> TM_11
							; es:di -> x coord
		; since both scale/rotate need TM_11*x and TM_22*y, do it

		call	MulWWFbyDWF			; do 48-bit multiply
		push	dx, cx, bx			; push TM_11 * x
		add	si, TM_22-TM_11			; set ds:si->TM_22
		add	di, PDF_y			; set es:di->y
		call	MulWWFbyDWF			; dx.cx.bx = TM_22*y

		; see if we need to do more work for rotation

		sub	si, TM_22			; ds:si -> matrix
		sub	di, PDF_y
		test	ds:[si].TM_flags, TM_ROTATED
		jnz	TC_rotate			; rotation, more 2 do

		; no rotation to do, so store away the results so far

		mov	es:[di].PDF_y.DWF_frac, bx	; store y result
		mov	es:[di].PDF_y.DWF_int.low, cx
		mov	es:[di].PDF_y.DWF_int.high, dx
		pop	dx, cx, bx
		mov	es:[di].PDF_x.DWF_frac, bx	; store y result
		mov	es:[di].PDF_x.DWF_int.low, cx
		mov	es:[di].PDF_x.DWF_int.high, dx
		ret

		; do full transformation, one more mul for each of x and y
TC_rotate:
		push	dx, cx, bx			; save y partial result
		add	si, TM_12			; ds:si -> r12
		call	MulWWFbyDWF			; dx.cx.bx = r12*x
		pop	ax				; pop frac of prev res
		add	bx, ax
		pop	ax				; pop int.low
		adc	cx, ax
		pop	ax				; pop int.high
		adc	dx, ax
		push	dx, cx, bx			; save new y result
		add	di, PDF_y			; es:di -> y
		add	si, TM_21-TM_12			; ds:si -> TM_21
		call	MulWWFbyDWF			; dx:cx = r21*y
		sub	di, PDF_y			; es:di -> PointDWFixed
		sub	si, TM_21			; ds:si -> matrix
		pop	es:[di].PDF_y.DWF_frac
		pop	es:[di].PDF_y.DWF_int.low
		pop	es:[di].PDF_y.DWF_int.high
		pop	ax				; pop frac of prev res
		add	bx, ax
		mov	es:[di].PDF_x.DWF_frac, bx	; replace x coord
		pop	ax				; pop int.low
		adc	cx, ax
		mov	es:[di].PDF_x.DWF_int.low, cx
		pop	ax				; pop int.high
		adc	dx, ax
		mov	es:[di].PDF_x.DWF_int.high, dx
		ret
TComplex endp

GraphicsTransformUtils ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRelDocPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current position, given an offset from the current one

CALLED BY:	INTERNAL
		GrRelMoveTo, GrRelLineTo, GrRelCurveTo, GrRelArcTo
PASS:		ds	- GState
		dx.cx	- X document offset from current position
		bx.ax	- Y document offset from current position
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRelDocPenPos	proc	far
		uses	ax, bx, cx, es, dx, si
		.enter
		pushf					; save carry too

		; set up to use TransformRelVector function.

		call	TransformRelVector		; transformed vector

		; update the current pen position

		push	ax
		mov	ax, dx
		cwd
		add	ds:[GS_penPos].PDF_x.DWF_frac, cx
		adc	ds:[GS_penPos].PDF_x.DWF_int.low, ax
		adc	ds:[GS_penPos].PDF_x.DWF_int.high, dx

		pop	ax
		xchg	ax, bx
		cwd
		add	ds:[GS_penPos].PDF_y.DWF_frac, bx
		adc	ds:[GS_penPos].PDF_y.DWF_int.low, ax
		adc	ds:[GS_penPos].PDF_y.DWF_int.high, dx

		popf					; restore carry
		.leave
		ret
SetRelDocPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransRelCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by Rel routines

CALLED BY:	INTERNAL
		GrDrawRelLineTo, GrDrawRelCurveTo, GrRelMoveTo
PASS:		ds	- GState
		dx.cx	- X displacement
		bx.ax	- Y displacement
RETURN:		carry	- set if any coords are out of coordinate space
		ax,bx	- current pen pos, dev coords
		cx,dx	- new pen pos, dev coords
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		this routine returns the current pen position and sets
		the new pen position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransRelCoord	proc	far
curPenPos	local	Point
		.enter

		push	bx, ax			; save Y displacement
		call	GetDevPenPos		; ax.bx = current position
		movdw	ss:curPenPos, axbx
		pop	bx, ax			; restore displacement
		jc	done

		; set new pen position

		call	SetRelDocPenPos		; set new position
		call	GetDevPenPos		; ax/bx = curpos
		jc	done
		movdw	cxdx, axbx
		movdw	axbx, ss:curPenPos	; get pen pos
done:
		.leave
		ret
TransRelCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformRelVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform small vector (fits in WWFixed) into page coords

CALLED BY:	INTERNAL
		text routines
PASS:		ds	- GState
		dxcx	- x component of vector (WWFixed, doc coords)
		bxax	- y component of vector 
RETURN:		dxcx	- x component in page coords
		bxax	- y component in page coords
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformRelVector proc	far
pageOff		local	PointWWFixed

		; if there is no scale or rotation, we're done

		test	ds:[GS_TMatrix].TM_flags, TM_COMPLEX
		jnz	somethingToDo
done:
		ret

		; OK, something to do.  Start out by doing the scale thing
somethingToDo:
		; check for rotation

		test	ds:[GS_TMatrix].TM_flags, TM_ROTATED
		jnz	fullRotation

		push	dx, cx		; save y component
		movdw	dxcx, ds:[GS_TMatrix].TM_22
		call	GrMulWWFixed
		pop	bx, ax
		push	dx, cx
		movdw	dxcx, ds:[GS_TMatrix].TM_11
		call	GrMulWWFixed
		pop	bx, ax
		jmp	done

fullRotation:
		.enter
		movdw	ss:pageOff.PF_x, dxcx
		movdw	ss:pageOff.PF_y, bxax
		movdw	bxax, ds:[GS_TMatrix].TM_11
		call	GrMulWWFixed
		xchgdw	ss:pageOff.PF_x, dxcx
		movdw	bxax, ds:[GS_TMatrix].TM_12
		call	GrMulWWFixed
		xchgdw	ss:pageOff.PF_y, dxcx 
		push	dx, cx
		movdw	bxax, ds:[GS_TMatrix].TM_22
		call	GrMulWWFixed
		adddw	ss:pageOff.PF_y, dxcx
		pop	dx, cx
		movdw	bxax, ds:[GS_TMatrix].TM_21
		call	GrMulWWFixed
		adddw	dxcx, ss:pageOff.PF_x
		movdw	bxax, ss:pageOff.PF_y
		.leave
		jmp	done
TransformRelVector endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current position, in document coords

CALLED BY:	INTERNAL
		various graphics routines
PASS:		ds	- GState
RETURN: 	ax,bx	- current pen position, in doc coords
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocPenPos	proc	far
		uses	dx, cx
		.enter
	
		pushf
		call	GetDocWWFPenPos			; use common routine
		jc	done
		xchg	ax, dx				; axcx = xpos, bxdx=y
		shl	cx, 1
		adc	ax, 0
		shl	dx, 1
		adc	bx, 0
done:		
		popf
		.leave
		ret
GetDocPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRelDocPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get relative pen position, set a new one

CALLED BY:	INTERNAL
		GrDrawRelLineTo
PASS:		ds	- GState
		dxcx	- WWFixed X displacement
		bxax	- WWFixed Y displacement
RETURN:		carry	- set of some coord overflow
		ax,bx	- current pen pos (doc coords)
		cx,dx	- new pen pos (doc coords)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRelDocPenPos	proc	far
penPos		local	Point
		.enter

		push	ax, bx			; save Y displacement
		call	GetDocPenPos		; get the current position
		movdw	ss:penPos, axbx		; save current pos
		pop	ax, bx
		jc	done			; quit on error
		call	SetRelDocPenPos		; set new pen pos
		call	GetDocPenPos		; get new one
		movdw	cxdx, axbx
		movdw	axbx, ss:penPos		; get prev result
done:
		.leave
		ret
GetRelDocPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetCurPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current pen position

CALLED BY:	GLOBAL

PASS:		di	- gstate handle

RETURN:		ax	- current x position
		bx	- current y position

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Use the GrGetInfo routine, it already does it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetCurPos	proc	far
		uses	ds
		
		; lock down the GState

		.enter
		mov	bx, di
		call	NearLock
		mov	ds, ax
		call	GetDocPenPos

		; release the GState

		xchg	bx, di
		call	NearUnlock
		xchg	bx, di

		.leave
		ret
GrGetCurPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocWBFPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get WBFixed pen positin (document coords)

CALLED BY:	INTERNAL
		Text routines
PASS:		ds	- GState
RETURN:		carry	- set if coordinate overflow
		ax.dl	- x coordinate
		bx.dh	- y coordinate
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocWBFPenPos	proc	near
		uses	cx
		.enter
	
		; move current position into local variable

		call	GetDocWWFPenPos			; use higher res rout
		xchg	ax, dx				; ax = x coord
		mov	dl, ch				; dh, dl set correctly

		.leave
		ret
GetDocWBFPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetCurPosWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current pen position

CALLED BY:	GLOBAL
PASS:		di	- GState handle
RETURN:		dxcx	- WWFixed x coordinate
		bxax	- WWFixed y coordinate
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetCurPosWWFixed		proc	far
		uses	ds
		.enter
		mov	bx, di			; lock GState
		call	MemLock
		mov	ds, ax
		call	GetDocWWFPenPos
		xchg	di, bx			; bx = GState handle
		call	MemUnlock
		xchg	di, bx			; restore handle, return val
		.leave
		ret
GrGetCurPosWWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocWWFPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pen pos in WWFixed coords

CALLED BY:	INTERNAL, GLOBAL
PASS:		ds	- GState
RETURN:		carry	- set if coordinate overflow
		dx.cx	- x WWFixed coord
		bx.ax	- y WWFixed coord
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocWWFPenPos	proc	near
		uses	es, si, di
penPos		local	PointDWFixed
		.enter
	
		; move current position into local variable

		mov	si, offset GS_penPos		; ds:si -> PenPos
		segmov	es, ss, di
		lea	di, ss:penPos			; es:di -> penPos
		mov	cx, size PointDWFixed/2
		rep	movsw			

		; unTransform it through gstate matrix

		mov	si, offset GS_TMatrix		; ds:si -> TMatrix
		lea	dx, ss:penPos			; es:dx -> penPos
		call	UnTransCoordDWFixed		; get doc coords

		; do bounds checking

		movdwf	sidxcx, ss:penPos.PDF_x
		CheckDWordResult si, dx
		jc	done

		movdwf	sibxax, ss:penPos.PDF_y
		CheckDWordResult si, bx
done:		
		.leave
		ret
GetDocWWFPenPos	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnTransCoordDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do complex part of reverse translation, DWFixed style

CALLED BY:	INTERNAL
		GrUntransformDWFixed

PASS: 		ds:si	- far pointer to matrix
		es:dx	- pointer to PointDWFixed structure

RETURN:		es:dx	- points at same structure with translated value

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see notes for GrUnTransCoord, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnTransCoordDWFixed	proc	far
		uses	ax,bx,cx,di,si
		.enter

		; no matter what we do, we have to do these adds

		mov	di, dx				; es:di -> PointDWFixed
		mov	bx, ds:[si].TM_31.DWF_frac	
		mov	cx, ds:[si].TM_31.DWF_int.low
		mov	dx, ds:[si].TM_31.DWF_int.high
		sub	es:[di].PDF_x.DWF_frac, bx
		sbb	es:[di].PDF_x.DWF_int.low, cx
		sbb	es:[di].PDF_x.DWF_int.high, dx

		mov	bx, ds:[si].TM_32.DWF_frac	
		mov	cx, ds:[si].TM_32.DWF_int.low
		mov	dx, ds:[si].TM_32.DWF_int.high
		sub	es:[di].PDF_y.DWF_frac, bx
		sbb	es:[di].PDF_y.DWF_int.low, cx
		sbb	es:[di].PDF_y.DWF_int.high, dx

		; if we were only doing translation, we're done

		test	ds:[si].TM_flags, TM_COMPLEX
		jnz	complexTrans		; nope, do it hard way

		; all done, so leave already
exit:
		mov	dx, di				; es:dx -> PointDWFixed
		.leave
		ret

		; save away result for mult
complexTrans:
		call	UTComplex
		jmp	exit

UnTransCoordDWFixed	endp

;---

GraphicsTransformUtils segment resource

UTComplex	proc	far
tempX		local	DDFixed
tempY		local	DDFixed
		.enter

		test	ds:[si].TM_flags, mask TF_INV_VALID ; is it valid ?
		jz	validateInverse
inverseValid:
		test	ds:[si].TM_flags, TM_ROTATED
		jnz	UTC_rotated		; rotated, do lots o' work

		; scaling, but no rotation, just mul by factor in window

		add	si, TM_xInv.DDF_frac.high ; ds:si -> inverse factor
		call	MulWWFbyDWF		; dx.cx.bx = value
		mov	es:[di].PDF_x.DWF_frac, bx	; save final
		mov	es:[di].PDF_x.DWF_int.low, cx
		mov	es:[di].PDF_x.DWF_int.high, dx
		add	di, PDF_y		; es:di -> y-TM_32
		add	si, TM_yInv-TM_xInv 	; ds:si -> inverse factor
		call	MulWWFbyDWF		; dx.cx.bx = y doc coord
		sub	di, PDF_y		; es:di -> PointDWFixed
		mov	es:[di].PDF_y.DWF_frac, bx	; save final
		mov	es:[di].PDF_y.DWF_int.low, cx
		mov	es:[di].PDF_y.DWF_int.high, dx
		jmp	done

		; inverse factor is not up to date.  make it so.
validateInverse:
		push	ax,bx,cx,dx,si,di
		mov	dl, ds:[si].TM_flags
		call	CalcInverse
		pop	ax,bx,cx,dx,si,di
		jmp	inverseValid
;---------------------------------------

		; special case: do backward rotation
UTC_rotated:					; es:di -> x-TM_31
		clr	tempY.DDF_frac.low
		clr	tempX.DDF_frac.low
		add	si, TM_22 		; ds:si -> TM_22
		call	MulWWFbyDWF		; do 32x48-bit multiply
		push	dx, cx, bx		; save TM_22(x-TM_31)
		add	si, TM_12-TM_22		; ds:si -> TM_12
		call	MulWWFbyDWF		; dx.cx.bx = TM_12(x-TM_31)
		pop	ss:tempX.DDF_frac.high	; recover TM22(x-TM31) fr stack
		pop	ss:tempX.DDF_int.low
		pop	ss:tempX.DDF_int.high
		push	dx, cx, bx		; save TM_12(x-TM_31)

		add	di, PDF_y		; es:di -> y-TM_32
		add	si, TM_21-TM_12		; ds:si -> TM_21
		call	MulWWFbyDWF		; dx.cx.bx = TM_21(y-TM_32)
		sub	di, PDF_y
		sub	ss:tempX.DDF_frac.high, bx ; need space for last result
		sbb	ss:tempX.DDF_int.low, cx
		sbb	ss:tempX.DDF_int.high, dx
		add	si, TM_11-TM_21		; ds:si -> TM_11
		add	di, PDF_y		; es:di -> y-TM_32
		call	MulWWFbyDWF		; dx.cx.bx = TM_11(y-TM_32)
		sub	di, PDF_y
		pop	ax			; ax = TM_12(x-TM_31).frac
		sub	bx, ax
		pop	ax			; ax = TM_12(x-TM_31).int.low
		sbb	cx, ax
		pop	ax			; ax = TM_12(x-TM_31).int.high
		sbb	dx, ax			; dx.cx.bx = final y coord
		mov	ss:tempY.DDF_frac.high, bx	; store result
		mov	ss:tempY.DDF_int.low, cx
		mov	ss:tempY.DDF_int.high, dx
		sub	si, TM_11		; set ds:si -> matrix

		; apply full inverse scale factors

		push	es, di			; save ptr to PointDWFixed
		segmov	es, ss, di
		lea	di, tempX
		add	si, TM_xInv-TM_11	; ds:si -> DDF inverse factor
		call	MulDDF			; dxcxbxax = value
		pop	es, di
		shl	ax, 1
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0
		movdwf	es:[di].PDF_x, dxcxbx	; save value

		push	es, di
		segmov	es, ss, di
		lea	di, tempY		; es:di -> y-TM_32
		add	si, TM_yInv-TM_xInv 	; ds:si -> WWF inverse factor
		call	MulDDF			; dxcxbxax = y doc coord
		pop	es, di
		shl	ax, 1
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0
		movdwf	es:[di].PDF_y, dxcxbx	; save value
done:
		.leave
		ret

UTComplex	endp

GraphicsTransformUtils ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDevPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current pen position, in device coordinates

CALLED BY:	INTERNAL
		various graphics routines
PASS:		ds	- GState
		es	- Window
RETURN:		carry	- set if device coordinates are outside graphics space
		ax,bx	- device coordinates of pen position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This should be thought of as a replacement for GrTransCoord
		for routines that use the current position as one of their
		coordinates.

		es must be pointing at a Window.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDevPenPos	proc	far
		uses	dx, si
penPos		local	PointDWFixed
		.enter

		; copy the current position into our local stack frame

		movdwf	ss:penPos.PDF_x, ds:[GS_penPos].PDF_x, ax
		movdwf	ss:penPos.PDF_y, ds:[GS_penPos].PDF_y, ax

		; transform the coordinate, using the window matrix

		push	ds			; save GState
		segmov	ds, es, ax
		mov	si, offset W_TMatrix	; ds:si -> Matrix to use
		segmov	es, ss, dx
		lea	dx, ss:penPos		; es:dx -> Point to xform
		call	TransCoordDWFixed	; 

;	Transform the Y coordinate to device coordinates (converting from a
;	DWFixed to an integer

		mov	ax, ds:[W_winRect].R_top
		cwd
		mov	si, penPos.PDF_y.DWF_frac
		shl	si, 1			;Round up the fraction
						;(Carry set if frac >= 1/2)
		adc	ax, penPos.PDF_y.DWF_int.low
		adc	dx, penPos.PDF_y.DWF_int.high
		mov_tr	bx, ax

		CheckDWordResult dx, bx		; check for overflow
		jc	done			; Exit if overflow

;	Transform the X coordinate to device coordinates too

		mov	ax, ds:[W_winRect].R_left
		cwd
		mov	si, penPos.PDF_x.DWF_frac
		shl	si, 1			;Round up the fraction
		adc	ax, penPos.PDF_x.DWF_int.low
		adc	dx, penPos.PDF_x.DWF_int.high
		CheckDWordResult dx, ax		; check for overflow
done:
		segmov	es, ds, dx		; es -> Window
		pop	ds			; restore GState 
		.leave
		ret
GetDevPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterGraphics ExitGraphics ExitGraphicsGseg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter or exit a graphics routine by saving registers, getting
		the graphics semaphore, updating grWinSeg and validating the
		clipping structure

		*** CAUTION: These routines play with the stack in ways that
			     could be described as "inappropriate programming
			     practice".  Be careful when using them!

		*** CAUTION: Use the pair of routines or neither one of them!

CALLED BY:	INTERNAL
		All graphics drawing routines

PASS:
		EnterGraphics:
			di - handle of graphics state (locked and owned)

RETURN:
		EnterGraphics:
			on stack - all registers
			exclusive access to window
			clipping variables valid

		if normal drawing operation
				carry clear
				zero clear
				ds - locked gstate segment
				es - Window structure
				bp - ss:bp points at EGframe
				di - ds passed
      		if graphics string operation
				carry set
				zero set
				ds - locked gstate segment
				es - ds passed
				di - GString handle 
				bp - ss:bp points at EGframe
		if path operation
				carry set
				zero clear
				ds - locked gstate segment
				es - ds passed
				di - GString handle 
				bp - ss:bp points at EGframe
		if NULL window operation
				carry clear
				zero clear
				ds - locked gstate segment
				es - trashed (actually, idata)
				bp - ss:bp points at EGframe
				di - ds passed

		ExitGraphics:
			RETURNS to CALLER'S CALLER
			in registers - recovered stuff
			graphics semaphore released

		NOTE: If you want to perform certain actions only if a GString
		      is *not* present, use JNZ. Otherwise, use the Carry flag
		      to detect GStrings or Paths, and use the Zero flag to
		      the differentiate between the two.
			
DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:
		EnterGraphics:
			save all the registers;
			if (handle is to real gstate)
			    lock the gstate;
			    get the window handle from the gstate;
			    lock the window;
			    if (window assoc with memory device driver)
			       lock the bitmap block;
			    if (clipping or transformation info not valid)
			        validate it;

		ExitGraphics:
			if (window assoc with memory device driver)
			   unlock the bitmap block;
			get the window handle from the window struct;
			unlock the window;
			unlock the gstate;
			restore all the registers;


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	3/89		Changed to check validity of trans matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnterGraphicsTemp	proc	far
		FastLock2	ds, di, ax, EG_l1, EG_l2
EnterGraphicsTemp	endp
ForceRef	EnterGraphicsTemp

EnterGraphics	proc	far call

EC <	call	AssertInterruptsEnabled					>

		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		; NOTE: There is a structure called EGframe in
		;	graphicsConstant.def that is used by the graphics
		;	routines to access registers saved on the
		;	stack by this routine.  If you want to
		;	change the way the stack is treated here
		;	(i.e. add pushes, change the order, etc.)
		;	then be sure to alter the structure.
		;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		; save bp so we can use it to access the stack

		push	bp			; 

		; Push all registers on the stack so that graphics routines
		; can trash them (popped by ExitGraphics)

		push	dx, cx, bx, ax, si, ds, es, di

		mov	bp, sp			; set up stack addressing
						;  ss:bp -> EGframe structure
		push	ax			; working variable
		push	ds			; save passed ds
		LoadVarSeg	ds, ax
		mov	es, ax

		; ensure valid gstate handle
		; Lock graphics state and window (fast)

EC <		call	ECCheckGStateHandle				>
		FastLock1	ds, di, ax, EG_l1, EG_l2
		mov	ds, ax

		; check for gstring

		mov	di, ds:[GS_gstring]	; get gstring handle
		tst	di			; valid gstring handle ?
		jnz	doGString		;  yes, deal with it
		mov	di, ds:[GS_window]	;  no, deal with window instead
		tst	di			; valid window handle ?
		jz	notGString		;  no, skip draw (carry is clr)

		; own and lock window

		FastMemP	es, di
		FastLock1	es, di, ax, EG_l3, EG_l4
		mov	es, ax

		; if there is a bitmap out there, lock it

		tst	es:[W_bitmap].segment	; check VM file handle
		jnz	handleBitmap

		; make sure that clip info and transformation matrix are valid
		; ds = graphics state, es = window
checkClip:
		mov	di, es:[W_curState]	; see if we need to do both
		cmp	di, ds:[LMBH_handle]	; is info ok for this GState ?
		jne	notValid		;  no, update clip and xform

		; the clip/xform info is for the right GState, let's see if
		; either are invalid for any reason. Both must be valid.

		mov	ax, {word}es:[W_grFlags] ; ax <- current valid flags
		andnf	ax, mask WGF_MASK_VALID or \
			    mask WGF_XFORM_VALID or \
			    mask WGRF_PATH_VALID shl 8 or \
			    mask WGRF_WIN_PATH_VALID shl 8
		cmp	ax, mask WGF_MASK_VALID or \
			    mask WGF_XFORM_VALID or \
			    mask WGRF_PATH_VALID shl 8 or \
			    mask WGRF_WIN_PATH_VALID shl 8
		je	notGString		;

		; not valid, so validate
notValid:
		call	WinValWinStruct		; Make clipping region valid,
						;  now that we have graphics
						;  semaphore
notGString:
		pop	di			; recover passed ds
		xor	ax, ax			; clear the zero & carry flags
commonExit:
		pop	ax
		jmp	{fptr} ss:[bp].EG_grRet	; return

		; Special case for semaphores

		FastLock2	es, di, ax, EG_l3, EG_l4

		; Must determine the type of GString. Could actually be
		; a GString, or it might be a Path.
doGString:
		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		stc				; still have a GString or Path!
		pop	es			; recover passed ds into es
		jmp	commonExit

		; this is a bitmap device (vidmem).  Lock down the directory
		; structure.
handleBitmap:
		push	bx
		mov	bx, es:[W_bitmap].segment
		mov	di, es:[W_bitmap].offset
		call	HugeArrayLockDir
EC <		tst	es:[W_bmSegment]	; has to be zero here	>
EC <		ERROR_NZ GRAPHICS_BITMAP_SHOULDNT_BE_LOCKED		>
		mov	es:[W_bmSegment], ax
		pop	bx
		jmp	checkClip
EnterGraphics	endp

;---------------------------------------------------------------------------
;	ExitGraphics
;---------------------------------------------------------------------------

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	NOTE: The content of ExitGraphics has been copied for use in GrBitBlt,
;	      since there are parameters passed on the stack to that routine
;	      and it needs to do a "ret 4" to remove the parameters from
;	      the stack.  Any changes made here should also be made there
;	      (in the file graphicsRaster.asm).  Thanks.
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

;---------------------------------------------------------------------------
;	ExitGraphics
;---------------------------------------------------------------------------

releaseBitmap	label	near
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
		jmp	releaseWin

ExitGraphics	proc	far jmp
		ON_STACK	di es ds si ax bx cx dx bp retf retf
		LoadVarSeg	ds

		; check to see if we need to release a bitmap

		tst	es:[W_bitmap].segment	; check VM file handle
		jnz	releaseBitmap
		
		; now release the window
releaseWin	label	near
		mov	bx,es:[W_header.LMBH_handle]	;release window
		FastUnLock	ds, bx, ax
		FastMemV1	ds, bx, ExG_u1, ExG_u2, file-global

		REAL_FALL_THRU	ExitGraphicsGseg
ExitGraphics	endp

;---------------------------------------------------------------------------
;	ExitGraphicsGseg
;---------------------------------------------------------------------------

ExitGraphicsGseg proc	far jmp

EC <	call	AssertInterruptsEnabled					>

		ON_STACK	di es ds si ax bx cx dx bp retf retf

		LoadVarSeg	ds
		pop	bx			;recover di passed
		mov	di, bx			; get gstate handle back in di
		FastUnLock	ds, bx, ax

		pop	dx, cx, bx, ax, si, ds, es
		pop	bp
		add	sp, 4			; skip over other return addr

		retf				; returning to caller's caller

;-------------

		; Special case of wake up/block code

		FastMemV2	ds, bx, ExG_u1, ExG_u2, file-global

ExitGraphicsGseg endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterGraphicsFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start working with a "filled" graphic operation. This routine
		is called in lieu of EnterGraphics, s.t. we may perform some
		checking for patterns, etc. DO NOT CALL ExitGraphicsFill
		DIRECTLY. It will be called indirectly by ExitGraphicsGseg,
		and will clean up any mess, and then return to the correct
		location.

CALLED BY:	EXTERNAL

PASS:		same as EnterGraphics

RETURN:		same as EnterGraphics

DESTROYED:	same as EnterGraphics

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Has the horrible side effect of changing the data found
		in the EGframe:
			EG_grRet		-> this routine
			EG_appRet		-> ExitGraphicsFill
			EG_param2:EG_param1	-> EG_grRet
			EG_param3		-> EG_appRet.offset
						   EG_appRet.segment
						   EG_param1
						   EG_param2
						   EG_param3
		and so on. Esentially, we've inserted 4 words of
		data between EG_bp & EG_grRet.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnterGraphicsText	proc	far

		; Perform the normal work, and see if we have a pattern
		;
		push	cs, ax			; will become EG_appRet
		call	EnterGraphics
		mov	ss:[bp].EG_appRet.offset, offset ExitGraphicsFillDone
		jc	EGFDone			; if Path or GString, we're done
		cmp	ds:[GS_textPattern].GCP_pattern, PT_SOLID
		je	EGFDone			; CF = 0, ZF = 1
		jmp	EGFCommon
EnterGraphicsText	endp

EnterGraphicsFill	proc	far

		; Perform the normal work, and see if we have a pattern
		;
		push	cs, ax			; will become EG_appRet
		call	EnterGraphics
		mov	ss:[bp].EG_appRet.offset, offset ExitGraphicsFillDone
		jc	EGFDone			; if Path or GString, we're done
		cmp	ds:[GS_areaPattern].GCP_pattern, PT_SOLID
		je	EGFDone			; CF = 0, ZF = 1

		; We have a pattern, so begin a Path, and return values
		; indicative of drawing to a path.
EGFCommon	label	near

		; Unlock & release the window handle
		;
		push	bx			; save data in BX
		mov	bx, ds:[GS_window]	; Window handle => BX
		tst	bx			; check for NULL Window
		jz	donePopBX		; if null, get out now
		tst	es:[W_bitmap].segment	; check VM file handle
		jnz	releaseBitmap2
releaseWindow2:
		call	NearUnlockV		; unlock & release Window

		; Now start defining the path structure
		;
		push	cx			; save data in CX
		mov	ss:[bp].EG_appRet.offset, offset ExitGraphicsFill
		mov	es, di			; passed DS => ES
		mov	di, ds:[LMBH_handle]	; GState handle => DI
		call	GrSaveState
		mov	cx, PCT_REPLACE		; replace any existing path
		call	GrBeginPath		; begin a path
		mov	di, ds:[GS_gstring]	; GString handle => DI
		or	di, di			; clears zero flag
		stc				; we're a Path
		pop	cx			; restore data => CX
donePopBX:
		pop	bx			; restore data => BX
EGFDone		label	near
		jmp	{fptr} ss:[bp].EG_param1 ; return to graphics caller

		; Release the bitmap huge array
releaseBitmap2:
		push	ds	
		mov	ds, es:[W_bmSegment]
		mov	es:[W_bmSegment], 0
		call	HugeArrayUnlockDir
		pop	ds
EC <		push	bx, di						>
EC <		mov	bx, es:[W_bitmap].segment			>
EC <		mov	di, es:[W_bitmap].offset			>
EC <		call	ECCheckHugeArrayFar				>
EC <		pop	bx, di						>
		jmp	releaseWindow2
EnterGraphicsFill	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitGraphicsFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete filling of graphic operation with pattern

CALLED BY:	ExitGraphicsGseg (via "retf" at end of routine)

PASS:		DI	= GState handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		To properly deal with polygons, we need to know which
		RegionFillRule was passed. Since this value is now in AL, we
		pass it on to PatternFill().

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExitGraphicsFill	proc	far
	
		; Go fill the graphic figure with a pattern.
		;
		push	ax, bx, dx
		mov	dl, al			; RegionFillRule (maybe) => DL
		call	GrGetCurPos		; current position => (AX, BX)
		call	PatternFill		; go fill with a pattern
		call	GrRestoreState
		call	GrMoveTo		; move the pen => (AX, BX)
		pop	ax, bx, dx

		; Restore the state of the GState, and return to original
		; caller of graphic operation
ExitGraphicsFillDone	label	far
		add	sp, 4			; clean up the stack
		retf				; return to application caller
ExitGraphicsFill	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if anyone has the exclusive

CALLED BY:	GLOBAL
PASS:		bx - handle of video driver (or 0 for default)
RETURN:		bx - handle of gstate with exclusive (or 0 if noone has
		     exclusive access)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetExclusive	proc	far	uses	ds, di, si
		.enter
		LoadVarSeg	ds

		tst	bx
		jnz	GGE_notDefault
		mov	bx, ds:[defaultDrivers].DDT_video
GGE_notDefault:
		call	GeodeInfoDriver
		mov	di,DR_VID_GET_EXCLUSIVE
		call	ds:[si][DIS_strategy]
		.leave
		ret
GrGetExclusive	endp

kcode	ends

;-----------------------------------------------------

GraphicsObscure	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGrabExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start drawing exclusively to a video driver

CALLED BY:	GLOBAL

PASS: 		bx - handle of video driver (0 for default)
		di - graphics state to use exclusively

RETURN: 	nothing

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:
		exclusivity handled by the video driver in question.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGrabExclusive proc	far	
		uses	bx, si, di, ds
		.enter
		LoadVarSeg	ds

		tst	bx
		jnz	GSE_notDefault
		mov	bx, ds:[defaultDrivers].DDT_video
GSE_notDefault:
		call	GeodeInfoDriver
		mov	bx, di
		mov	di,DR_VID_START_EXCLUSIVE
		call	ds:[si][DIS_strategy]
		.leave
		ret

GrGrabExclusive endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrReleaseExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop drawing exclusively to a video driver

CALLED BY:	GLOBAL

PASS: 		bx - handle of video driver (0 for default)
		di - handle of gstate originally passed to GrGrabExclusive
RETURN: 	ax...dx - bounds of invalidation area required (device coords)

DESTROYED: 	none

PSEUDO CODE/STRATEGY:
		exclusivity handled by the video driver in question.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrReleaseExclusive	proc	far
		uses	si,di,ds
		.enter

		LoadVarSeg	ds

		tst	bx
		jnz	GEE_notDefault
		mov	bx, ds:[defaultDrivers].DDT_video
GEE_notDefault:
		call	GeodeInfoDriver
		mov	bx, di			;BX <- gstate to end exclusive
						; with
		mov	di,DR_VID_END_EXCLUSIVE
		call	ds:[si][DIS_strategy]
		tst	ax
		movdw	axbx, sidi
		jz	bogusBounds
done:
		.leave
		ret

		; if nothing tried to draw while we had the exclusive, then
		; return a rectangle that is offscreen.
bogusBounds:
		mov	ax, 0xffff		; invalidate offscreen
		mov	bx, ax
		mov	cx, ax
		mov	dx, ax
		jmp	done
GrReleaseExclusive	endp

GraphicsObscure	ends
