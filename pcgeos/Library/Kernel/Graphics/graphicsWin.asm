COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Graphics
FILE:		graphicsWin.asm

AUTHOR:		Jim DeFrisco, 22 July 1991

ROUTINES:
	Name			Description
	----			-----------
    GLB GrInvalRect		Invalidates portion of window, as indicated
				by rectangle passed, in document
				coordinates
    INT LockValidateWindow	PLock a window structure and validate the
				transformation matrix, given a gstate
				handle.
    GLB GrInvalRectDWord		Invalidates portion of window, as indicated
				by rectangle passed, in extended document
				coordinates
    INT ExtDocToWindowCoords	Convert a pair of coordinates to window
				coords, and limit the results to valid
				16-bit coords
    EXT GrGetWinBoundsDWord	Returns bounds of current window's region
				(in document coordinates)
    INT CompareMins		Check out the sdwords in registers vs the
				RectDWord at ds:si
    INT CompareMaxs		Check out the sdwords in registers vs the
				RectDWord at ds:si
    EXT GrGetMaskBoundsDWord	Returns bounds of current window's region
				in 32 bit document coordinates
    GLB GrGetWinBounds		Returns bounds of current window's region
				(in document coordinates)
    GLB GrGetMaskBounds		Get 16-bit bounds of the current clip
				rectangle
    GLB GrGetWinHandle		Get the window handle associated with a
				gstate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/91		Initial revision


DESCRIPTION:
	These routines deal with the window in some way
		

	$Id: graphicsWin.asm,v 1.1 97/04/05 01:13:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode		segment

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInvalRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidates portion of window, as indicated by rectangle
		passed, in document coordinates

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- left/top coord of rect to invalidate
		cx,dx	- right/bottom coords of rectangle to invalidate

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine started out in life as WinInvalRect.  It was 
		moved over to the graphics system for 2.0, and completely
		rewritten to use WinInvalReg.

		We build out the region to draw (if rotated) or set up the 
		rectangular coords (if not rotated) and call WinInvalReg

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/10/90		Initial version
	Doug	5/91		Reviewed header doc
	Jim	7/91		Moved to Gr routine from Win, support rotation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

RotRect		struct
    RR_ul	Point <>
    RR_ur	Point <>
    RR_lr	Point <>
    RR_ll	Point <>
RotRect		ends

GrInvalRect	proc	far
		uses	ax,bx,cx,dx,si,di,es
rect		local	RotRect
		.enter

		; lock down the GState and the Window so we can call trans coord

		call	LockValidateWindow	; es -> Window struct
		jc	done			;  ... or lock failed
		test	es:[W_curTMatrix].TM_flags, TM_ROTATED
		jnz	handleRotation		; there is rotation...

		; if there is no rotation, then we just need to pass some 
		; rectangular bounds on to WinInvalReg.

		call	GrTransCoord2		; translate coordinates

		; Order those puppies

		cmp	ax,cx
		jle	10$
		xchg	ax,cx
10$:
		cmp	bx,dx
		jle	20$
		xchg	bx,dx
20$:

		; we need window-coordinates for WinInvalReg, so subtract out
		; the upper left corner of the window from both coords

		mov	di, si			; di = window handle
		push	bp
		mov	bp, es:[W_winRect].R_left
		sub	ax, bp
		sub	cx, bp
		mov	bp, es:[W_winRect].R_top
		sub	bx, bp
		sub	dx, bp
		clr	bp			; signal rectangular coords
		xchg	bx, di			; so we can unlock the window
		call	MemUnlockV
		xchg	bx, di
		call	WinInvalReg		; invalidate the window
		pop	bp
done:
		.leave
		ret

		; if there is rotation, then we need to build a region that
		; represents the rotated rectangle.  Transform all four coords
		; then use the points to build the region.
		; es -> Window
		; si = window handle
handleRotation:
		push	ax			; save left
		push	bx			; save top
		call	DocToWindow		; transform upperleft
		mov	rect.RR_ul.P_x, ax	; save coord
		mov	rect.RR_ul.P_y, bx
		pop	bx			; restore top
		mov	ax, cx			; do top right
		call	DocToWindow		; transform upperleft
		mov	rect.RR_ur.P_x, ax	; save coord
		mov	rect.RR_ur.P_y, bx
		mov	ax, cx			; do lowerRight
		mov	bx, dx
		call	DocToWindow		; transform upperleft
		mov	rect.RR_lr.P_x, ax	; save coord
		mov	rect.RR_lr.P_y, bx
		mov	bx, dx			; do lowerLeft
		pop	ax
		call	DocToWindow		; transform upperleft
		mov	rect.RR_ll.P_x, ax	; save coord
		mov	rect.RR_ll.P_y, bx

		push	si			; save window handle
		push	bp			; save stack frame pointer
		mov	bp, es:[W_winRect].R_top    ; bp holds min y value
		mov	dx, es:[W_winRect].R_bottom ; dx holds max y value
		mov	bx, si			; bx -> window handle
		call	MemUnlockV		; release window

		; the top and bottom bounds that we pass to GrRegionPathInit
		; represent the bounds of the region that we are going to 
		; create.  Since the region coords are window-relative, we
		; must pass bounds that are also window-relative.  So the top
		; is zero, and the bottom is bottom-top.

		sub	dx, bp			; adjust bottom to be height
		clr	bp			; adjust top to window-coords

		clr	di			; allocate a new block
		mov	cx, RFR_ODD_EVEN or (MIN_REGION_POINTS shl 8)
		call	GrRegionPathInit
		pop	bp			; restore stack frame ptr

		; do the polygon

		push	ds
		mov	cx, 4			; supplying four points
		segmov	ds, ss, di		; ds:di -> point list
		lea	di, rect
		call	GrRegionPathAddPolygon
		pop	ds

		; clean up the region definition

		call	GrRegionPathClean
		
		pop	di			; di = window handle
		push	bp			; save stack frame
		mov	bp, es			; bp -> region definition
		mov	si, (size RegionPath)	; bp:si -> region
		call	WinInvalReg
		mov	bx, es:[RP_handle]	; free the region block
		call	MemFree
		pop	bp
		jmp	done
GrInvalRect	endp

	; utility routine to save some bytes
	; ax,bx = coord to transform
	; es    = sptr to locked window
DocToWindow	proc	near
		call	GrTransCoord
		sub	ax, es:[W_winRect].R_left ; make it window relative
		sub	bx, es:[W_winRect].R_top
		ret
DocToWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockValidateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PLock a window structure and validate the transformation
		matrix, given a gstate handle.

CALLED BY:	INTERNAL
		GrInvalRect, GrInvalRectDWord

PASS:		di	- GState handle

RETURN:		carry	- set if there is no window for the gstate
		es	- sptr to Window structure
		si	- window handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the gstate
		get the window handle
		unlock the gstate
		plock the window
		check translation matrix, validate if not already

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockValidateWindow	proc	near
		uses	ax, bx, ds
		.enter
		
		; make sure the GState is OK...

EC <		call	ECCheckGStateHandle				>
		mov	bx, di			; get GState handle in bx
		call	NearLockDS		; ds <- GState
		mov	si, ds:[GS_window]	; see if there is a window
		mov	bx, si			; bx = window handle
		tst	bx			; if not, return ptr to GState
		jz	noWindow		;  do it
		call	NearPLockES		;  else own/lock window

		; check W_grFlags to see if xformation matrix is valid

		test	es:[W_grFlags], mask WGF_XFORM_VALID
		jz	validateWindow		;  no, update it
		cmp	di, es:[W_curState]	; right one ?
		je	windowOK		;  yes, do translation

		; need to update transformation matrix, do it
validateWindow:
		push	cx, dx, di, si
		call	GrComposeMatrix		; compose new matrix
		and	es:[W_grFlags], not mask WGF_XFORM_VALID ; invalidate
		pop	cx, dx, di, si
windowOK:
		clc				; signal there is a window
done:
		mov	bx, di		       	; GState handle -> BX
		call	NearUnlock		; unlock the gstate
		
		.leave
		ret

		; there is no window associated with the gstate, just return
noWindow:
		stc
		jmp	done
LockValidateWindow	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrInvalRectDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidates portion of window, as indicated by rectangle
		passed, in extended document coordinates

CALLED BY:	GLOBAL

PASS: 		di	- handle of graphics state
		ds:si	- pointer to RectDWord structure containing 
			  bounds of rectangle to invalidate
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see GrInvalRect, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/91		Initial version
	Doug	5/91		Reviewed header doc
	Jim	7/91		Moved to graphics system from Win

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

GrInvalRectDWord	proc	far
		uses	ax,bx,cx,dx,si,di,es
rect		local	RotRect
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		call	ECCheckBounds				>
endif
		; just transform all four corners into window coordinates, 
		; then we'll decide what to do about them

		movdw	dxcx, ds:[si].RD_left	; load upper left
		movdw	bxax, ds:[si].RD_top
		call	ExtDocToWindowCoords
		mov	rect.RR_ul.P_x, cx ; save result
		mov	rect.RR_ul.P_y, ax

		movdw	dxcx, ds:[si].RD_right	; load upper right
		movdw	bxax, ds:[si].RD_top
		call	ExtDocToWindowCoords
		mov	rect.RR_ur.P_x, cx ; save result
		mov	rect.RR_ur.P_y, ax

		movdw	dxcx, ds:[si].RD_right	; load lower right
		movdw	bxax, ds:[si].RD_bottom
		call	ExtDocToWindowCoords
		mov	rect.RR_lr.P_x, cx ; save result
		mov	rect.RR_lr.P_y, ax

		movdw	dxcx, ds:[si].RD_left	; load lower left
		movdw	bxax, ds:[si].RD_bottom
		call	ExtDocToWindowCoords
		mov	rect.RR_ll.P_x, cx ; save result
		mov	rect.RR_ll.P_y, ax

		; now we need to see if there was any rotation involved.  We
		; can do this by just checking the transformed coords 

		mov	bx, ax			; need to free up ax
		call	GrGetWinHandle		; ax = window handle
		tst	ax			; if this is zero, we goofed..
		jz	done
		cmp	cx, rect.RR_ul.P_x	; if diff, then rotated
		jne	handleRotation
		cmp	bx, rect.RR_lr.P_y	; if diff, then rotated
		jne	handleRotation
		
		; there is no rotation, so just pass the upper left and 
		; lower right on to WinInvalReg.  One more thing.  The 
		; coords could be sorted wrong, so flip them if so.

		mov	bx, ax
		call	MemPLock		; lock window
		mov	es, ax			; ds -> window
		mov	ax, rect.RR_ul.P_x	; load up upper left
		mov	di, rect.RR_ul.P_y
		mov	cx, rect.RR_lr.P_x
		mov	dx, rect.RR_lr.P_y
		mov	si, es:[W_winRect].R_left ; normalize coords
		sub	ax, si
		sub	cx, si
		mov	si, es:[W_winRect].R_top  ; normalize coords
		sub	di, si
		sub	dx, si
		call	MemUnlockV		; release window
		xchg	bx, di			; di = window, bx = top
		push	bp
		clr	bp
		cmp	ax, cx			; if not sorted right...
		jle	xOK
		xchg	ax, cx
xOK:
		cmp	bx, dx
		jle	yOK
		xchg	bx, dx
yOK:
		call	WinInvalReg
		pop	bp

done:
		.leave
		ret
		
		; there was some rotation in the transformation.  We need to
		; build a region to pass to WinInvalReg
		; ax = window handle
handleRotation:
		push	ax			; save window handle
		push	bp			; save stack frame
		mov	bx, ax			; bx = window handle
		call	MemPLock		; lock/own window
		mov	es, ax
		mov	bp, es:[W_winRect].R_top    ; bp holds min y value
		mov	ax, es:[W_winRect].R_left ; need left too...
		mov	dx, es:[W_winRect].R_bottom ; dx holds max y value
		call	MemUnlockV		; release window

		; make the bounds we pass window-relative

		push	bp			; save top coordinate
		sub	dx, bp			; set bottom = height
		clr	bp			; top of window is zero in win
						;  coords

		clr	di			; allocate a new block
		mov	cx, RFR_ODD_EVEN or (MIN_REGION_POINTS shl 8)
		call	GrRegionPathInit
		pop	cx			; cx = top coordinate
						; ax,cx = left,top
		pop	bp			; restore stack frame ptr

		; adjust all the coordinates by the window position.

		sub	rect.RR_ul.P_x, ax
		sub	rect.RR_ur.P_x, ax
		sub	rect.RR_ll.P_x, ax
		sub	rect.RR_lr.P_x, ax
		sub	rect.RR_ul.P_y, cx
		sub	rect.RR_ur.P_y, cx
		sub	rect.RR_ll.P_y, cx
		sub	rect.RR_lr.P_y, cx

		; do the polygon

		push	ds
		mov	cx, 4			; supplying four points
		segmov	ds, ss, di		; ds:di -> point list
		lea	di, rect
		call	GrRegionPathAddPolygon
		pop	ds

		; clean up the region definition

		call	GrRegionPathClean

		; invalidate the window.

		pop	di			; di = window handle
		push	bp			; save stack frame
		mov	bp, es			; bp -> region definition
		mov	si, (size RegionPath)	; bp:si -> region
		call	WinInvalReg
		mov	bx, es:[RP_handle]	; free the region block
		call	MemFree
		pop	bp
		jmp	done
GrInvalRectDWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtDocToWindowCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a pair of coordinates to window coords, and limit
		the results to valid 16-bit coords

CALLED BY:	INTERNAL	
		GrInvalRectDWord

PASS:		di	- GState handle
		dx.cx	- 32-bit extended x coordinate
		bx.ax	- 32-bit extended y coordinate

RETURN:		cx	- 16-bit transformed/validated x window coord
		ax	- 16-bit transformed/validated y window coord

DESTROYED:	dx, bx

PSEUDO CODE/STRATEGY:
		transform the coord to 32-bit window coords
		validate/limit the result

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtDocToWindowCoords	proc	near
		.enter
		call	GrTransformDWord
		push	dx
		CheckDWordResult dx, cx		; see if any overflow
		pop	dx
		jnc	doY			; no, check y coord
		tst	dx			; check sign of result
		mov	dx, 0
		mov	cx, LARGEST_POSITIVE_COORDINATE	; assume positive
		jns	doY
		mov	dx, -1
		mov	cx, LARGEST_NEGATIVE_COORDINATE
doY:
		push	bx
		CheckDWordResult bx, ax		; see if any overflow
		pop	bx
		jnc	exit			; no, check y coord
		tst	bx			; check sign of result
		mov	bx, 0
		mov	ax, LARGEST_POSITIVE_COORDINATE	; assume positive
		jns	exit
		mov	bx, -1
		mov	ax, LARGEST_NEGATIVE_COORDINATE
exit:
		.leave
		ret
ExtDocToWindowCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetWinHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the window handle associated with a gstate

CALLED BY:	GLOBAL

PASS:		di	- GState handle

RETURN:		ax	- Window handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just lock the gstate and fetch the handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetWinHandle	proc	far
		uses	bx, ds
		.enter
		mov	bx, di
		call	MemLock
		mov	ds, ax
		mov	ax, ds:[GS_window]
		call	MemUnlock
		.leave
		ret
GrGetWinHandle	endp

kcode	ends

GraphicsCommon	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetWinBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns bounds of current window's region (in document
		coordinates)

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom
		di 	- handle of graphics state

		carry set if coordinates cannot be expressed in 16-bits with
		the current GState transformation

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Get the window coordinates (device units);
		Untransform the coordinates;

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetWinBounds	proc	far
		uses	ds, si
winBounds	local	RectDWord
		.enter

		segmov	ds, ss, si			; ds:si -> buffer space
		lea	si, ss:winBounds
		call	GrGetWinBoundsDWord		; get extended bounds
		movdw	dxax, winBounds.RD_left
		CheckDWordResult dx, ax			; if overflow...
		jc	exit
		movdw	dxbx, winBounds.RD_top		; check all four coords
		CheckDWordResult dx, bx
		jc	exit
		movdw	dxcx, winBounds.RD_right
		CheckDWordResult dx, cx
		jc	exit
		movdw	sidx, winBounds.RD_bottom
		CheckDWordResult si, dx
exit:
		.leave
		ret	
GrGetWinBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetMaskBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get 16-bit bounds of the current clip rectangle

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

RETURN:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom
		di 	- handle of graphics state

		carry set if coordinates cannot be expressed in 16-bits with
		the current GState transformation, or if the mask is NULL.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		use the extended version and check the result		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetMaskBounds		proc	far
		uses	ds, si
maskBounds	local	RectDWord
		.enter

		segmov	ds, ss, si			; ds:si -> buffer space
		lea	si, ss:maskBounds
		call	GrGetMaskBoundsDWord		; get extended bounds
		jc	exit
		cmpdw	maskBounds.RD_left, MIN_COORD_DWORD
		je	returnMax
	
		movdw	dxax, maskBounds.RD_left
		CheckDWordResult dx, ax			; if overflow...
		jc	exit
		movdw	dxbx, maskBounds.RD_top		; check all four coords
		CheckDWordResult dx, bx
		jc	exit
		movdw	dxcx, maskBounds.RD_right
		CheckDWordResult dx, cx
		jc	exit
		movdw	sidx, maskBounds.RD_bottom
		CheckDWordResult si, dx
exit:
		.leave
		ret	

returnMax:		
	;
	; gstate has no window and no clip paths, so convert from maxed out
	; dword bounds to maxed out word bounds.
	; 
		mov	ax, MIN_COORD
		mov	bx, MIN_COORD
		mov	cx, MAX_COORD
		mov	dx, MAX_COORD
		jmp	exit
GrGetMaskBounds		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetWinBoundsDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns bounds of current window's region (in document
		coordinates)

CALLED BY:	EXTERNAL

PASS:		di - GState handle
		ds:si - pointer to buffer the size of RectDWord

RETURN:		ds:si	- RectDWord structure filled with bounds
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If there is rotation in one of the matrices, then this routine
		will return the bounds of a rectangle which contains the 
		entire rotated rectangle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/91		Initial extended version
	Doug	5/91		Reviewed header doc
	jim	7/91		moved to graphics system, fixed for rotation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetWinBoundsDWord	proc	far
		uses	ax,bx,cx,dx,es
		.enter

EC <		call ECCheckGStateHandle	>

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx				>
EC <		mov	bx, ds				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		pop	bx				>
endif
		mov	dx, ds			; save RectDWord segment
		mov	bx, di
		call	MemLock			; ds -> GState
		mov	ds, ax
		mov	ax, ds:[GS_window]	; bx = Window handle 
		tst	ax			; if zero, bogus window
		jz	bogusWindow
		mov	bx, ax			; setup window handle
		call	MemPLock		; es -> Window
		mov	es, ax

		; make sure that clip info and transformation matrix are valid
		; ds = graphics state, es = window

		test	es:[W_regFlags], mask WRF_CLOSED
		LONG jnz reallySmallWindow	; Branch if closing

		cmp	di, es:[W_curState]	; see if we need to do both
		jne	notValid		;  no, update clip info

		test	es:[W_grFlags], mask WGF_XFORM_VALID ; is info right ?
		jnz	valid			;
notValid:
		call	GrComposeMatrixFar	; Validate transform matrix

		; while we have everything locked, get the mask bounds and 
		; see if there is any rotation
		; Also, update the W_curState field to reflect the right 
		; GState, and kill the MASK_VALID flag, since we haven't
		; done anything with that.
valid:
		mov	bx, ds:[LMBH_handle]	; don't need GState no more
		mov	es:[W_curState], bx
		and	es:[W_grFlags], not (mask WGF_MASK_VALID or\
					     mask WGF_BUFFER_VALID)
		and	es:[W_grRegFlags], not (mask WGRF_WIN_PATH_VALID or\
						mask WGRF_PATH_VALID)
		call	MemUnlock		; release GState
		mov	ds, dx			; ds -> RectDWord structure
		mov	ax, es:[W_winRect.R_left] 	; setup bounds
		mov	bx, es:[W_winRect.R_top]
		mov	cx, es:[W_winRect.R_right]
		inc	cx
		mov	dx, es:[W_winRect.R_bottom]
		inc	dx
		test	es:[W_curTMatrix].TM_flags, TM_COMPLEX
		LONG jz	doItFast		; no scale or rotation...
		push	bx
		mov	bx, es:[W_header].LMBH_handle ; get win handle
		call	MemUnlockV			; release window
		pop	bx
		call	GetBoundsDWord			; get dword bounds
done:
		.leave
		ret

		; no window handle, just load bounds of graphics system
bogusWindow:
		call	MemUnlock			; releae GState
		mov	ds, dx				; restore RectDWord
		movdw	ds:[si].RD_left, MIN_COORD
		movdw	ds:[si].RD_top, MIN_COORD
		movdw	ds:[si].RD_right, MAX_COORD
		movdw	ds:[si].RD_bottom, MAX_COORD
		jmp	done

		; Window is closing, put something in there.
reallySmallWindow:
		mov	bx, ds:LMBH_handle	; Release the GState
		call	MemUnlock
		mov	bx, es:[W_header].LMBH_handle ; get win handle
		call	MemUnlockV			; release window
		mov	ds, dx			; ds -> RectDWord struct
		movdw	ds:[si].RD_left, MIN_COORD
		movdw	ds:[si].RD_top, MIN_COORD
		movdw	ds:[si].RD_right, MIN_COORD+1
		movdw	ds:[si].RD_bottom, MIN_COORD+1
		jmp	done

		; there's no scale or rotation in the window, just subtract
		; out the window translation.
doItFast:
		push	dx
		cwd				; make left a dword
		movdw	ds:[si].RD_left, dxax
		mov	ax, bx			; same for top
		cwd
		movdw	ds:[si].RD_top, dxax
		mov	ax, cx
		cwd
		movdw	ds:[si].RD_right, dxax
		pop	ax
		cwd
		movdw	ds:[si].RD_bottom, dxax
		movdw	dxax, es:[W_curTMatrix].TM_31.DWF_int
		tst	es:[W_curTMatrix].TM_31.DWF_frac
		jns	haveXtrans
		decdw	dxax
haveXtrans:
		subdw	ds:[si].RD_left, dxax
		subdw	ds:[si].RD_right, dxax
		movdw	dxax, es:[W_curTMatrix].TM_32.DWF_int
		tst	es:[W_curTMatrix].TM_32.DWF_frac
		jns	haveYtrans
		decdw	dxax
haveYtrans:
		subdw	ds:[si].RD_top, dxax
		subdw	ds:[si].RD_bottom, dxax
		mov	bx, es:[LMBH_handle]	; release window
		call	MemUnlockV
		jmp	done
GrGetWinBoundsDWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetMaskBoundsDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns bounds of current window's region in 32 bit 
		document coordinates

CALLED BY:	EXTERNAL

PASS:		di - handle of GState
		ds:si - fptr to buffer the size of RectDWord

RETURN:
		ds:si - RectDWord structure filled with bounds		
		carry	- set if mask null

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	steve	4/10/91		Initial version
	jim	7/91		moved to graphics system

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetMaskBoundsDWord	proc	far
		uses	ax,bx,cx,dx,es
tempBounds	local	RectDWord
		.enter

EC <		call ECCheckGStateHandle	>

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx				>
EC <		mov	bx, ds				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		pop	bx				>
endif
		mov	dx, ds			; save RectDWord segment
		mov	bx, di
		call	MemLock			; lock graphics state
		mov	ds, ax			; ds -> GState
		mov	ax, ds:[GS_window]	; bx = Window handle 
		tst	ax			; if zero, bogus window
		jz	bogusWindow
		mov	bx, ax			; setup window handle
		call	MemPLock
		mov	es, ax			; es -> Window

		; make sure that clip info and transformation matrix are valid
		; ds = graphics state, es = window

		cmp	di, es:[W_curState]	; see if we need to do both
		jne	notValid		;  no, update clip info

		test	es:[W_grFlags], mask WGF_MASK_VALID ; is info right ?
		jz	notValid			;

		test	es:[W_grFlags], mask WGF_XFORM_VALID ; is info right ?
		jnz	valid			;
notValid:
		call	WinValWinStrucFar	; Validate clip info

		; while we have everything locked, get the mask bounds and 
		; see if there is any rotation
valid:
		mov	bx, ds:[LMBH_handle]	; don't need GState no more
		call	MemUnlock		; release GState
		mov	ds, dx			; ds -> RectDWord structure
		test	es:[W_grFlags], mask WGF_MASK_NULL; is there any mask ?
		LONG jnz  nullMask
		mov	ax, es:[W_maskRect.R_left] 	; setup bounds
		mov	bx, es:[W_maskRect.R_top]
		mov	cx, es:[W_maskRect.R_right]
		inc	cx			; bump out for imaging conv
		mov	dx, es:[W_maskRect.R_bottom]
		inc	dx
		test	es:[W_curTMatrix].TM_flags, TM_COMPLEX
		LONG jz	doItFast
		push	bx
		mov	bx, es:[W_header].LMBH_handle ; get win handle
		call	MemUnlockV			; release window
		pop	bx
		call	GetBoundsDWord			; get dword bounds
done:
		clc
exit:
		.leave
		ret

		; no window handle, intersect the bounds of the window
		; clip path and the document clip path.
bogusWindow:
		call	MemUnlock			; release GState
		segmov	ds, ss, bx
		lea	bx, tempBounds
		mov	ax, GPT_WIN_CLIP
		mov	cx, -1				; assume winclip present
		call	GrGetPathBoundsDWord
		jnc	getClipBounds
		inc	cx				; flag no winclip

getClipBounds:
		mov	ds, dx				; restore RectDWord
		mov	bx, si				; ds:bx -> RectDWord
		mov	ax, GPT_CLIP			; get clip bounds
		call	GrGetPathBoundsDWord
		jnc	getBoundsIntersect
		jcxz	returnMax		; => no clip of any sort

		; no doc clip, so copy win clip bounds into return area

		push	es, di, si, ds
		mov	di, si
		mov	es, dx			; es:di <- return area
		segmov	ds, ss
		lea	si, tempBounds
			CheckHack <(size tempBounds and 1) eq 0>
		mov	cx, size tempBounds / 2
		rep	movsw
		pop	es, di, si, ds
		jmp	done

returnMax:
		movdw	bxax, MIN_COORD_DWORD	; bxax <- min
		movdw	ds:[si].RD_left, bxax
		movdw	ds:[si].RD_top, bxax

			CheckHack <MIN_COORD_DWORD-1 eq MAX_COORD_DWORD>
		dec	bx			; convert to max
		dec	ax			; always affects low word too
		
		movdw	ds:[si].RD_right, bxax
		movdw	ds:[si].RD_bottom, bxax
		jmp	done

getBoundsIntersect:
		jcxz	done			; => no winclip, so use doc clip
						;  which is already in return
						;  area

		movdw	bxax, tempBounds.RD_left	; min of x bounds
		jledw	bxax, ds:[si].RD_left, checkRight
		movdw	ds:[si].RD_left, bxax
checkRight:
		movdw	bxax, tempBounds.RD_right	; max of x bounds
		jgedw	bxax, ds:[si].RD_right, checkTop
		movdw	ds:[si].RD_right, bxax
checkTop:
		movdw	bxax, tempBounds.RD_top		; min of y bounds
		jledw	bxax, ds:[si].RD_top, checkBottom
		movdw	ds:[si].RD_top, bxax
checkBottom:
		movdw	bxax, tempBounds.RD_bottom	; max of y bounds
		jgedw	bxax, ds:[si].RD_bottom, checkNULL
		movdw	ds:[si].RD_bottom, bxax

		; if either is flipped, we have the NULL set.
checkNULL:
		movdw	bxax, ds:[si].RD_left
		jgdw	bxax, ds:[si].RD_right, nullPath
		movdw	bxax, ds:[si].RD_top
		jgdw	bxax, ds:[si].RD_bottom, nullPath
		jmp	done




		; there's a window, but the mask region is NULL...
nullMask:
		mov	bx, es:[LMBH_handle]		; get win handle
		call	MemUnlockV			; release window
nullPath:
		stc
		jmp	exit

		; there's no scale or rotation in the window, just subtract
		; out the window translation.
doItFast:
		push	dx
		cwd				; make left a dword
		movdw	ds:[si].RD_left, dxax
		mov	ax, bx			; same for top
		cwd
		movdw	ds:[si].RD_top, dxax
		mov	ax, cx
		cwd
		movdw	ds:[si].RD_right, dxax
		pop	ax
		cwd
		movdw	ds:[si].RD_bottom, dxax
		movdw	dxax, es:[W_curTMatrix].TM_31.DWF_int
		tst	es:[W_curTMatrix].TM_31.DWF_frac
		jns	haveXtrans
		decdw	dxax
haveXtrans:
		subdw	ds:[si].RD_left, dxax
		subdw	ds:[si].RD_right, dxax
		movdw	dxax, es:[W_curTMatrix].TM_32.DWF_int
		tst	es:[W_curTMatrix].TM_32.DWF_frac
		jns	haveYtrans
		decdw	dxax
haveYtrans:
		subdw	ds:[si].RD_top, dxax
		subdw	ds:[si].RD_bottom, dxax
		mov	bx, es:[LMBH_handle]	; release window
		call	MemUnlockV
		jmp	done

GrGetMaskBoundsDWord	endp

GraphicsCommon	ends

GraphicsTransformUtils segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBoundsDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine used by GetMask and GetWin bounds

CALLED BY:	INTERNAL
		GrGetMaskBoundsDWord, GrGetWinBoundsDWord
PASS:		ax...dx	- rect bounds to use to calculate
		di	- GState handle
		ds:si	- pointer to RectDWord structure to return bounds
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetBoundsDWord	proc	far
		uses	ax,dx,es
upLeft		local	PointDWFixed
lowRight	local	PointDWFixed
upRight		local	PointDWFixed
lowLeft		local	PointDWFixed
		.enter

		; mov the coords into local variables

		push	dx			; save bottom bound
		cwd
		movdw	upLeft.PDF_x.DWF_int, dxax
		movdw	lowLeft.PDF_x.DWF_int, dxax
		mov	ax, bx			; do top
		cwd
		movdw	upLeft.PDF_y.DWF_int, dxax
		movdw	upRight.PDF_y.DWF_int, dxax
		mov	ax, cx			; do right
		inc	ax  			; adjust for imaging conv.
		cwd
		movdw	lowRight.PDF_x.DWF_int, dxax
		movdw	upRight.PDF_x.DWF_int, dxax
		pop	ax			; restore bottom coord
		inc	ax  			; adjust for imaging conv.
		cwd
		movdw	lowRight.PDF_y.DWF_int, dxax
		movdw	lowLeft.PDF_y.DWF_int, dxax
		clr	ax
		mov	upLeft.PDF_x.DWF_frac, ax
		mov	upLeft.PDF_y.DWF_frac, ax
		mov	lowRight.PDF_x.DWF_frac, ax
		mov	lowRight.PDF_y.DWF_frac, ax
		mov	upRight.PDF_x.DWF_frac, ax
		mov	upRight.PDF_y.DWF_frac, ax
		mov	lowLeft.PDF_x.DWF_frac, ax
		mov	lowLeft.PDF_y.DWF_frac, ax


		segmov	es, ss, dx		; es -> stack
		lea	dx, ss:upLeft		; es:dx -> upper left coord
		call	GrUntransformDWFixed	; do upper left
		lea	dx, ss:lowRight		; es:dx -> lower right coord
		call	GrUntransformDWFixed	; do lower right
		lea	dx, ss:upRight		; es:dx -> up right coord
		call	GrUntransformDWFixed	; do up right
		lea	dx, ss:lowLeft		; es:dx -> lower left coord
		call	GrUntransformDWFixed	; do lower left

		; now we need to sort the results

		movdw	ds:[si].RD_left, 0x7fffffff
		movdw	ds:[si].RD_top, 0x7fffffff
		movdw	ds:[si].RD_right, 0x80000000
		movdw	ds:[si].RD_bottom, 0x80000000
		lea	dx, ss:upRight
		call	MinMaxDWFixed
		lea	dx, ss:lowLeft
		call	MinMaxDWFixed
		lea	dx, ss:lowRight
		call	MinMaxDWFixed		; do min/max calc for low right
		lea	dx, ss:upLeft
		call	MinMaxDWFixed		; and upper left

		.leave
		ret
GetBoundsDWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MinMaxDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a simple min/max calculation

CALLED BY:	GetBoundsDWord
PASS:		es:dx	-> PointDWFixed structure
		ds:si	-> RectDWord structure
RETURN:		nothing
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MinMaxDWFixed	proc	near
		uses	ax, di
		.enter

		mov	di, dx
		movdw	dxax, es:[di].PDF_x.DWF_int

		; dxax = x coord to check.  Could be a fraction, but 
		; doesn't matter for min calc.

		cmp	dx, ds:[si].RD_left.high	; check high word
		jg	checkXMax			; greater, continue
		jl	newXmin				; less, store it
		cmp	ax, ds:[si].RD_left.low		; check low word
		jae	checkXMax			; greater, continue
newXmin:
		movdw	ds:[si].RD_left, dxax		; store new x min
checkXMax:
		tst	es:[di].PDF_x.DWF_frac		; check for frac
		jz	haveCheckX
		incdw	dxax				; use ceil if fraction
haveCheckX:
		cmp	dx, ds:[si].RD_right.high	; check for new max
		jl	checkY
		jg	newXmax
		cmp	ax, ds:[si].RD_right.low	
		jbe	checkY
newXmax:
		movdw	ds:[si].RD_right, dxax

		; have x completed, do Y
checkY:
		movdw	dxax, es:[di].PDF_y.DWF_int	; get coord to check
		cmp	dx, ds:[si].RD_top.high		; check high word
		jg	checkYMax			; greater, continue
		jl	newYmin				; less, store it
		cmp	ax, ds:[si].RD_top.low		; check low word
		jae	checkYMax			; greater, continue
newYmin:
		movdw	ds:[si].RD_top, dxax		; store new x min
checkYMax:
		tst	es:[di].PDF_y.DWF_frac		; check for frac
		jz	haveCheckY
		incdw	dxax				; use ceil if fraction
haveCheckY:
		cmp	dx, ds:[si].RD_bottom.high	; check for new max
		jl	done
		jg	newYmax
		cmp	ax, ds:[si].RD_bottom.low	
		jbe	done
newYmax:
		movdw	ds:[si].RD_bottom, dxax
done:		
		.leave
		ret
MinMaxDWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTestRectInMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test a rectangle against the current clip region

CALLED BY:	GLOBAL
PASS:		di	- GState
		ax...dx	- bounds of rectangle to test (document coords)
RETURN:		al - TestRectReturnType - TRRT_OUT     if not in region
				 	  TRRT_PARTIAL if partially in region
				 	  TRRT_IN      if entirely in region
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrTestRectInMask	proc	far

		; Need to transform coord and lock window

		call	EnterGraphics		; ds -> GState, es -> Window
		jc	whole			; if GString, return TRRT_IN

		; check to see if we're clipped out

		tst	ds:[GS_window]		; if no window, return true
		jz	nullWindow
		test	es:[W_grFlags], mask WGF_MASK_NULL ; see if null mask
		jnz	nullWindow

		; OK, we have something.  Get device coords

		call	GrTransCoord2Far	; ax...dx transformed
		
		; setup ds-> Window and test the rectangle

		push	ds			; save GState
		segmov	ds, es, si
		mov	si, ds:[W_maskReg]
		mov	si, ds:[si]		; ds:si -> mask region
		clc
		call	GrTestRectInReg
		pop	ds			; restore GState
		jmp	done

		; the whole rect is in the mask.
whole:
		mov	ss:[bp].EG_ax, TRRT_IN	; setup return value
		jmp	ExitGraphicsGseg

		; null window, return OUT
nullWindow:
		mov	ax, TRRT_OUT
done:
		mov	ss:[bp].EG_ax, ax
		jmp	ExitGraphics
GrTestRectInMask	endp

GraphicsTransformUtils ends
