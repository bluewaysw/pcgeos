COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KernelGraphics
FILE:		Graphics/graphicsTransform.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GLB GrApplyRotation		Apply rotation to a transformation matrix
    INT GrIntGStateTransCoord	translate coordinate using gstate
				transformation matrix
    GLB GrApplyScale		Apply scale factor to transformation matrix
    GLB GrApplyTranslationDWord	apply 32-bit integer extended translation
				to the GState
    GLB GrApplyTranslation	apply translation to a transformation
				matrix
    GLB GrSetTransform		Replace transformation
    GLB GrApplyTransform	Catenate transformation
    GLB GrSetNullTransform	Replace transformation with null (identity)
				transformation
    GLB GrInitDefaultTransform	Initialize the default TMatrix to the
				current TMatrix
    GLB GrSetDefaultTransform	Set the current TMatrix to the default
				TMatrix
    INT GrExitTransFar		Used by all the transformation
				setting/changing routines to cleanup and
				exit.  This includes updating matrix opt.
				flags, unlocking proper blocks.
    INT GrExitTrans		Used by all the transformation
				setting/changing routines to cleanup and
				exit.  This includes updating matrix opt.
				flags, unlocking proper blocks.
    INT IntExitGState		Used by all the transformation
				setting/changing routines to cleanup and
				exit.  This includes updating matrix opt.
				flags, unlocking proper blocks.
    INT GrComposeMatrixFar	Compose the final matrix by multiplying
				GS_TMatrix by W_TMatrix and storing result
				in W_curTMatrix
    INT GrComposeMatrix		Compose the final matrix by multiplying
				GS_TMatrix by W_TMatrix and storing result
				in W_curTMatrix
    INT GrPrepReverseTrans	Pre-calculate some reverse translation
				factors, if needed

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	3/89	initial version
	gene	5/89	added font invalidation to complex transforms
	jim	8/89	moved some to kernel lib, changed some names
	jim	1/90	changed to pre-apply transformations, like postscript

DESCRIPTION:
	This file contains routines to set and manipulate the transformation
	matrix.

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

	$Id: graphicsTransform.asm,v 1.1 97/04/05 01:12:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrApplyTranslationDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	apply 32-bit integer extended translation to the GState

CALLED BY:	GLOBAL

PASS:		di	- handle of GState
		dx:cx	- x translation (signed dword)
		bx:ax	- y translation (signed dword)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		apply translation to matrix
		reset valid flag in W_grFlags if needed

		The following matrix mutliplication is performed:

		  GS_TMatrix	   =  translation  *   GS_TMatrix

		[ gs11  gs12  0 ]     [  1  0  0 ]   [ gs11  gs12  0 ]
		[ gs21  gs22  0 ]  =  [  0  1  0 ] * [ gs21  gs22  0 ]
		[ gs31  gs32  1 ]     [ Tx Ty  1 ]   [ gs31  gs32  1 ]

		  gs11 = gs11	gs12 = gs12
		  gs21 = gs21	gs22 = gs22
		  gs31 = gs11*Tx + gs21*Ty + gs31
		  gs32 = gs12*Tx + gs22*Ty + gs32

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/91		Created, from GrApplyTranslation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrApplyTranslationDWord proc	far
		uses	es, ds, si, dx, cx, bx, ax ; save regs we trash
trans		local	PointDWord
		.enter

		; copy the args to the stack

		mov	trans.PD_x.high, dx 	; copy x factor over
		mov	trans.PD_x.low, cx	
		mov	trans.PD_y.high, bx 	; copy y factor over
		mov	trans.PD_y.low, ax	

		mov	bx, di			; lock GState
		call	NearLockDS		; ds <- GState
		or	ds:[GS_TMatrix].TM_flags, TM_TRANSLATED 
		test	ds:[GS_TMatrix].TM_flags, TM_COMPLEX 
		jnz	doComplex
		add	ds:[GS_TMatrix].TM_31.DWF_int.low, cx ; add in X 
		adc	ds:[GS_TMatrix].TM_31.DWF_int.high, dx 
		mov	ax, trans.PD_y.low	; get low integer
		add	ds:[GS_TMatrix].TM_32.DWF_int.low, ax ; add in Y low int
		mov	ax, trans.PD_y.high	; get hi integer part
		adc	ds:[GS_TMatrix].TM_32.DWF_int.high, ax 

		; check for gstring
checkGS:
		tst	ds:[GS_gstring]		; test alleged gstring handle
		jz	done

		; write out the gstring element

		push	di, si, ds
		mov	di, ds:[GS_gstring]	; get the gstring handle
		segmov	ds, ss
		lea	si, trans		; point ds:si at values on stack
		mov	ax, (GSSC_FLUSH shl 8) or GR_APPLY_TRANSLATION_DWORD
		mov	cx, size PointDWord
		call	GSStore			; store the element
		pop	di, si, ds
done:
		call	GrExitTrans
		.leave
		ret

		; handle more complex trans matrix
doComplex:
		mov	si, GS_TMatrix
		lea	dx, trans
		call	PreApplyExtTranslation
		jmp	checkGS			; mark window TM as invalid
GrApplyTranslationDWord endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrApplyTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	apply translation to a transformation matrix

CALLED BY:	GLOBAL

PASS:		di	- handle of GState
		dx:cx	- x translation (WWFixed)
		bx:ax	- y translation (WWFixed)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		apply translation to matrix
		reset valid flag in W_grFlags if needed

		The following matrix mutliplication is performed:

		  GS_TMatrix	   =  translation  *   GS_TMatrix

		[ gs11  gs12  0 ]     [  1  0  0 ]   [ gs11  gs12  0 ]
		[ gs21  gs22  0 ]  =  [  0  1  0 ] * [ gs21  gs22  0 ]
		[ gs31  gs32  1 ]     [ Tx Ty  1 ]   [ gs31  gs32  1 ]

		  gs11 = gs11	gs12 = gs12
		  gs21 = gs21	gs22 = gs22
		  gs31 = gs11*Tx + gs21*Ty + gs31
		  gs32 = gs12*Tx + gs22*Ty + gs32

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	jim	8/9/89		Changed name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrApplyTranslation proc	far
		uses	es, ds, si, dx, cx, bx, ax ; save regs we trash
tOffset		local	PointWWFixed
		.enter

		; copy the args to the stack

		mov	tOffset.PF_x.WWF_int, dx ; copy x factor over
		mov	tOffset.PF_x.WWF_frac, cx	
		mov	tOffset.PF_y.WWF_int, bx ; copy y factor over
		mov	tOffset.PF_y.WWF_frac, ax	

		mov	bx, di			; lock GState
		call	NearLockDS		; ds <- GState
		or	ds:[GS_TMatrix].TM_flags, TM_TRANSLATED 
		test	ds:[GS_TMatrix].TM_flags, TM_COMPLEX 
		jnz	doComplex
		mov	ax, dx			; need to convert to dword
		cwd
		add	ds:[GS_TMatrix].TM_31.DWF_frac, cx ; add in X frac
		adc	ds:[GS_TMatrix].TM_31.DWF_int.low, ax ; add in X int
		adc	ds:[GS_TMatrix].TM_31.DWF_int.high, dx 
		mov	ax, tOffset.PF_y.WWF_frac ; get fraction part
		add	ds:[GS_TMatrix].TM_32.DWF_frac, ax ; add in Y frac
		mov	ax, tOffset.PF_y.WWF_int ; get integer part
		cwd
		adc	ds:[GS_TMatrix].TM_32.DWF_int.low, ax ; add in Y int
		adc	ds:[GS_TMatrix].TM_32.DWF_int.high, dx  

		; check for gstring
checkGS:
		tst	ds:[GS_gstring]		; test alleged gstring handle
		jz	done

		; write out the gstring element

		push	di, si, ds
		mov	di, ds:[GS_gstring]	; get the gstring handle
		segmov	ds, ss
		lea	si, tOffset		; point ds:si at values on stack
		mov	ax, (GSSC_FLUSH shl 8) or GR_APPLY_TRANSLATION
		mov	cx, size PointWWFixed
		call	GSStore			; store the element
		pop	di, si, ds
done:
		call	GrExitTrans
		.leave
		ret

		; handle more complex trans matrix
doComplex:
		mov	si, GS_TMatrix
		lea	dx, tOffset
		call	PreApplyTranslation
		jmp	checkGS			; mark window TM as invalid
GrApplyTranslation endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInitDefaultTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the default TMatrix to the current TMatrix

CALLED BY:	GLOBAL

PASS:		di	- gstate handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the current TMatrix out to the defTMatrix chunk

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be used with great care.  It should
		almost never be used by applications.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrInitDefaultTransform	proc	far
		uses	ax, cx, ds, es, di, si, bx
		.enter

		mov	cl, GR_INIT_DEFAULT_TRANSFORM
		call	EnterPushPopTransform	; handle gstring an'hooey
		mov	di, ds:[GS_defTMatrix]	; if it doesn't exist, 
		tst	di			;  create one.
		jz	createChunk
haveChunk:
		mov	di, ds:[di]		; es:di -> chunk
		mov	si, GS_TMatrix		; ds:si -> TMatrix to copy
		mov	cx, (size TMatrix)/2	; move words for speed
		rep	movsw			; copy the chunk

		mov	di, bx			; restore handle
		call	MemUnlock		; release GState
		.leave
		ret

		; create a chunk to store default matrix
createChunk:
		clr	al			; no object flags
		mov	cx, size TMatrix	; this is how big
		call	LMemAlloc
		mov	ds:[GS_defTMatrix], ax	; save chunk handle
		mov	di, ax			; need handle
		jmp	haveChunk
GrInitDefaultTransform	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetDefaultTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current TMatrix to the default TMatrix

CALLED BY:	GLOBAL

PASS:		di	- gstate handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the defTMatrix out to the current TMatrix 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		In most cases, the default transformation is the identity
		transformation.  There are times when this is not the case,
		however, and that is why this routine should be used in place
		of GrSetNullTransform (in almost all cases).

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetDefaultTransform	proc	far
		uses	ax, cx, es, ds, si, bx
		.enter

		mov	cl, GR_SET_DEFAULT_TRANSFORM
		call	EnterPushPopTransform	; handle gstring an'hooey

		mov	si, ds:[GS_defTMatrix]	; see if there is one there
		tst	si			; if not, use NULL tmatrix
		jz	setToNull		;
		mov	si, ds:[si]		; ds:si -> defMatrix chunk
		mov	di, offset GS_TMatrix	; es:di -> destination
		call	InvalidateFont		; invalidate font handle
		mov	cx, (size TMatrix)/2	; move words for speed
		rep	movsw			; copy the chunk
done:
		mov	di, bx			; di <- GState handle
		call	GrExitTrans		; biff flags, unlock GState
		.leave
		ret

		; init the TMatrix to NULL.  
setToNull:
		mov	di, offset GS_TMatrix	; set up pointer to matrix
		clr	ax			; set up values to use
		mov	cx, (size TMatrix) / 2	; size of store
		rep	stosw			; init to all 0s
		inc	ax
		mov	ds:[GS_TMatrix].TM_11.WWF_int, ax ; set scale to 1
		mov	ds:[GS_TMatrix].TM_22.WWF_int, ax
		call	InvalidateFont		; invalidate font handle
		jmp	done

GrSetDefaultTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSaveTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current transformation matrix

CALLED BY:	GLOBAL	
PASS:		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Save the current transformation matrix into a chunk allocated
		in the GState block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SavedTMatrix	struct
    STM_next		lptr			;chunk of next link
    STM_matrix		TMatrix			;saved TMatrix
    STM_default		lptr			;chunk of current default
SavedTMatrix	ends

SavedTMatrixWithDefault	struct
    STMWD_next		lptr			;chunk of next link
    STMWD_matrix	TMatrix			;saved TMatrix
    STMWD_default	lptr			;chunk of current default
    STMWD_defMatrix	TMatrix			;current defTMatrix
SavedTMatrixWithDefault	ends

GrSaveTransform		proc	far
		uses	ax, cx, ds, es, bx, di, si
		.enter

		mov	cl, GR_SAVE_TRANSFORM
		call	EnterPushPopTransform	; handle gstring an'hooey

		; save the matrix.  This means copying the think to a chunk,
		; as well as the default matrix.  The layout of the chunk we
		; are saving is:
		;	first word:	chunk handle link to next on stack
		;	TMatrix:	saved GS_TMatrix 
		;	next word:	chunk handle of current defTMatrix
		;			(zero if there is none)
		;	TMatrix:	defTMatrix (if there is one)

		clr	al
		mov	cx, size TMatrix + 4	; to save default handle too..
		tst	ds:[GS_defTMatrix]	; if zero, we're OK
		jz	haveSize
		add	cx, size TMatrix	; store another
haveSize:
		call	LMemAlloc		; allocate chunk
		mov	di, ax			; set up pointer to chunk
		mov	di, ds:[di]		; es:di -> chunk
		xchg	ax, ds:[GS_savedMatrix]	; store as first on stack
		stosw				; copy chunk handle link to 1st
		mov	si, offset GS_TMatrix	; setup source pointer
		mov	cx, (size TMatrix)/2	; move it by words
		rep	movsw
		mov	si, ds:[GS_defTMatrix]	; move this too if needed
		mov	ax, si
		stosw
		tst	si			; see if done
		jnz	copyDefMatrix
done:
		call	MemUnlock
		.leave
		ret

		; there is one defined, so copy it
copyDefMatrix:
		mov	si, ds:[si]		; get pointer to defTMatrix
		mov	cx, (size TMatrix)/2
		rep	movsw
		jmp	done
GrSaveTransform		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRestoreTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore a saved transformation matrix

CALLED BY:	GLOBAL
PASS:		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Copy the "top" transformation from a chunk into GS_TMatrix

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrRestoreTransform	proc	far
		uses	ax, cx, ds, es, bx, di, si
		.enter

		mov	cl, GR_RESTORE_TRANSFORM
		call	EnterPushPopTransform	; handle gstring an'hooey
		
		; restore the matrix.  This means copying the top element of
		; the transformation matrix stack into GS_TMatrix and the
		; default matrix if there is one.

		mov	si, ds:[GS_savedMatrix]	; get chunk handle of top one
		push	si			; save chunk handle
EC <		tst	si			; if zero, something bad >
EC <		ERROR_Z GRAPHICS_BAD_RESTORE_XFORM			>
		mov	si, ds:[si]		; ds:si -> saved Matrix
		lodsw				; ax = chunk handle link
		mov	ds:[GS_savedMatrix], ax	; save new top of xform stack
		mov	di, offset GS_TMatrix	; 
		call	FarInvalidateFont	; invalidate font handle
		mov	cx, (size TMatrix)/2	; move words for speed
		rep	movsw			; copy the chunk
		lodsw				; get chunk handle of defMatrix
		mov	di, ds:[GS_defTMatrix]	; get current default handle
		tst	ax			; if zero, we're done
		jz	freeCurDefault		;  but free current default
EC <		tst	di			; must be non-zero 	>
EC <		ERROR_Z GRAPHICS_BAD_RESTORE_XFORM			>
		mov	di, ds:[di]		; es:di -> defMatrix
		mov	cx, (size TMatrix)/2
		rep	movsw
freeChunk:
		pop	ax			; restore chunk to free
		call	LMemFree		; free the chunk
		mov	di, bx			; di <- GState handle
		call	GrExitTrans		; biff flags, unlock GState

		.leave
		ret

		; free the current default matrix, if there is one.
freeCurDefault:
		mov	ds:[GS_defTMatrix], ax	; wasn't a default, make it so
		mov	ax, di			; free the current def chunk
		tst	ax			; if already zero, don't free
		jz	freeChunk
		call	LMemFree		;
		jmp	freeChunk		; now free saved chunk. 
GrRestoreTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterPushPopTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some common prep work for transform routines

CALLED BY:	INTERNAL
		GrSaveTransform, GrRestoreTransform, GrInitDefaultTransform
		GrSetDefaultTransform
PASS:		di	- GState handle
		cl	- graphics string opcode
RETURN:		ds, es	- locked GState
		bx	- GState handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnterPushPopTransform proc	near
		uses	ax
		.enter

		; first lock down the gstate

		mov	bx, di			; bx = handle
		call	MemLock			; lock the gstate
		mov	ds, ax			; ds -> gstate
		mov	es, ax			;  set both there

		; check for writing to a gstring, handle it if so...

		tst	ds:[GS_gstring]		; writing to a gstring ?
		jz	done			;  no, done
		push	di			;  yes, handle it
		mov	di, ds:[GS_gstring]	; get gstring handle
		mov	ax, cx			; get opcode
		clr	cl			; no data to write
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write out the code
		mov	cx, ax			; restore opcode
		pop	di
done:
		.leave
		ret
EnterPushPopTransform endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrExitTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used by all the transformation setting/changing routines
		to cleanup and exit.  This includes updating matrix opt.
		flags, unlocking proper blocks.

CALLED BY:	INTERNAL

PASS:		ds	- pointer to GState block
		di	- handle of GState block
		cl	- WinGrFlags to save (IntExitGState)
		ch	- WinGrRegFlags to save (IntExitGState)

RETURN:		flags updated
		all blocks locked

DESTROYED:	cx (GrExitTrans)

PSEUDO CODE/STRATEGY:
		write out the transformation matrix flags
		unlock the right blocks

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrExitTrans	proc	near
	mov	cx, not (mask WGF_XFORM_VALID or \
		         mask WGRF_PATH_VALID shl 8)
	REAL_FALL_THRU	IntExitGState
GrExitTrans	endp

IntExitGState	proc	near
	uses	ax, bx, ds
	.enter
	;
	; Lock the window, and see if the current GState is us.
	; If so, we need to invalidate the matrix and regions as
	; specified by the flags passed.
	;
	mov	bx, ds:GS_window		;bx <- handle of window
	tst	bx				;any window?
	jz	unlockGS			;branch if no window
EC <	call	ECCheckWindowHandle		;>
	call	NearPLock
	mov	ds, ax				;ds <- seg addr of Window
	cmp	di, ds:W_curState		;are we current GState?
	jne	validBitOK			;no, leave flags alone
	andnf	{word} ds:W_grFlags, cx		;biff appropriate flags
validBitOK:
	call	NearUnlockV			;release the window
unlockGS:
	mov	bx, di				;bx <- handle of GState
	call	NearUnlock			;unlock GState

	.leave
	ret
IntExitGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrComposeMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compose the final matrix by multiplying GS_TMatrix
		by W_TMatrix and storing result in W_curTMatrix

CALLED BY:	INTERNAL

PASS:		ds	- points to locked GState structure
		es	- points to locked Window structure

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		Do matrix mulitply, checking flags for any possible
		optimizations.  There is a second step after the mulitply --
		to add in the window offsets.  This is actually a third
		transformation matrix, where there are no scaling or
		rotation components neccesary.  These offsets are stored
		in the Window structure as part of the W_winRect structure
		containing the left/right/top/bottom coordinates for the
		window.

		Performs the following matrix multiplication:

		  W_curTMatrix	     =	  GS_TMatrix	  *   W_TMatrix

		[ cur11  cur12  0 ]     [ gs11  gs12  0 ]   [ w11  w12  0 ]
		[ cur21  cur22  0 ]  =  [ gs21  gs22  0 ] * [ w21  w22  0 ]
		[ cur31  cur32  1 ]     [ gs31  gs32  1 ]   [ w31  w32  1 ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		W_curTMatrix set to [W_TMatrix]*[GS_TMatrix]
					+ window offset

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	Jim	8/89		Moved bulk of this routine to kernel library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrComposeMatrixFar	proc	far
		uses	ax, bx, cx, dx, di, si
		.enter

		call	GrComposeMatrix		; do the real work

		.leave
		ret
GrComposeMatrixFar	endp

GrComposeMatrix	proc	near

		; check for SIMPLE GrMatrix (no scale/rotate)

		mov	al, ds:[GS_TMatrix].TM_flags ; fetch flags
		mov	ah, es:[W_TMatrix].TM_flags ; fetch flags
		tst	al			; see if NULL GrMatrix
		jnz	GCM_grNotNull		;  nope, more complex compose

		; GrMatrix is NULL, just copy WinMatrix

		mov	bx, ds			; save segreg
		segmov	ds, es			; set both -> Window struct
		mov	si, W_TMatrix	; set ds:si source
		mov	di, W_curTMatrix	; set es:di dest
		mov	cx, (size TMatrix) / 2	; copy entire matrix
		rep	movsw
		mov	ds, bx			; restore segreg
		jmp	GCM_done		; all done

		; test for NULL WinMatrix
GCM_grNotNull:
		mov	si, GS_TMatrix	; set ds:si source
		mov	di, W_curTMatrix	; set es:di dest
		tst	ah			; test for NULL WinMatrix
		jnz	GCM_winNotNull		;  no, continue
		mov	cx, (size TMatrix) / 2	; copy entire matrix
		rep	movsw
		jmp	GCM_done		; all finished

		; WinMatrix and GrMatrix both non-NULL
GCM_winNotNull:
		mov	cx, ax			; since can't use ax
		call	ComposeFullMatrix	; neither null, do dirty work

		; all translations done, add in the window offset
		; also set XFORM valid flag
GCM_done:
		and	es:[W_TMatrix].TM_flags, not mask TF_INV_VALID
		and	es:[W_curTMatrix].TM_flags, not mask TF_INV_VALID
		call	GrPrepReverseTrans		; pre-calc reverse trans
		mov	ax, es:[W_winRect].R_left      ; get offset to left edge
		cwd
		add	es:[W_curTMatrix].TM_31.DWF_int.low, ax ; add to matrix
		adc	es:[W_curTMatrix].TM_31.DWF_int.high, dx
		mov	ax, es:[W_winRect].R_top       ; get offset to top edge
		cwd
		add	es:[W_curTMatrix].TM_32.DWF_int.low, ax ; add to matrix
		adc	es:[W_curTMatrix].TM_32.DWF_int.high, dx
		or	es:[W_curTMatrix].TM_flags, TM_TRANSLATED ; set 1 flg
		or	es:[W_grFlags], mask WGF_XFORM_VALID	; mark as valid
		ret
GrComposeMatrix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrPrepReverseTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pre-calculate some reverse translation factors, if needed

CALLED BY:	INTERNAL (GrComposeMatrix)

PASS:		es	- points to Window structure

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		Calculate some inverse factors for WinUnTransCoord and Gr...
		reverse translation functions.  The reverse translations use
		the following equations, and this routine calculates the
		denominators of the last two sets of equations (for scaling
		and rotation).  The UnTrans functions then use these factors
		(stored in the matrices) instead of doing divisions then.

		no scaling or rotation:
			x = x'-r31		y = y'-r32

		no rotation:
			x = (x'-r31)/r11	y = (y'-r32)/r22

		full translation:
			x = (r22(x'-r31) - r21(y'-r32)) / (r11r22-r12r21)
			y = (r11(y'-r32) - r12(x'-r31)) / (r11r22-r12r21)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrPrepReverseTrans	proc	near

			; Save ds and move es over, to save cycles

			push	ds			; save data seg
			segmov	ds, es			; ds -> window

			; We need to do inverse factors for both WinTransMatrix
			; and CurTransMatrix, but only if they are complex.

			mov	dl, ds:[W_TMatrix].TM_flags
			test	dl, TM_COMPLEX		; matrix complex ?
			jz	GPRT_chkCur		;   no, check CurTrans
			mov	si, W_TMatrix	; set up pointer
			call	CalcInverse		; do the calc

			; finished with WinTransMatrix, deal with CurTrans
GPRT_chkCur:
			mov	dl, ds:[W_curTMatrix].TM_flags
			test	dl, TM_COMPLEX		; matrix complex ?
			jz	GPRT_done		;   no, all done
			mov	si, W_curTMatrix	; set up pointer
			call	CalcInverse		; do the calc
GPRT_done:
			pop	ds			; restore data seg
			ret
GrPrepReverseTrans	endp

