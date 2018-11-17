COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsPathLow.asm

AUTHOR:		Don Reeves

ROUTINES:
		Creating Path routines #1
		=========================
GLB		AddRectangleToPath		; used by clipping routines
EXT		CombineGStringOrPathWithPath	; combines Paths together

		Stroking Path routines #2
		=========================
EXT		StrokePath			; strokes a Path
INT		StrokePathGetStart		; returns start of path element
INT			StrokePathHLine		; opcode specific routines...
INT			StrokePathVLine
INT			StrokePathChar
INT			StrokePathArc
INT			StrokePathSpline
INT			StrokePathClosedOp
INT			StrokePathFromPoint
INT			StrokePathFromPtArray
INT			StrokePathContinuedOp
INT			StrokePathError
INT		StrokePathCloseSubPath		; close a sub-path

		Building Region routines #3
		===========================
GLB		BuildRegionFromPath		; returns Region based on Path
INT		FillGraphicsOpcode		; build Region for each opcode
INT			FillPathLine
INT			FillPathLineTo
INT			FillPathRect
INT			FillPathRectTo
INT			FillPathHLine
INT			FillPathHLineTo
INT			FillPathVLine
INT			FillPathVLineTo
INT			FillPathRoundRect
INT			FillPathRoundRectTo
INT			FillPathPoint
INT			FillPathPointAtCP
INT			FillPath
INT			FillPath
INT			FillPathChar 
INT			FillPathCharAtCP
INT			FillPathText 
INT			FillPathTextAtCP
INT			FillPathTextField
INT			FillPathPolyline
INT			FillPathEllipse
INT			FillPathArc
INT			FillPathSpline
INT			FillPathPolygon
INT			PathBuildError
INT		LoadPenPosAXBXCXDX		; penPos to (AX,BX) & (CX,DX)
INT		FillPathLowLine		; adds a line to the region
INT		CopyPointsToBlock		; copy point array to block
INT		MergeRegions			; merge two Regions together
INT		RegionReAlloc			; resize Region to minimum size
INT		PathTransformDocToWin		; document coord => window coord
INT		PathTransformDocToDev		; document coord => device coord
INT		PathTransformWinToWin		; window coord => window coord
INT		PathTransformWinToDev		; window coord => device coord

		Utility routines #4
		===================
INT		PathLoadGString		; copy Path to temporary block
INT		LockWinFromGStateHandle		; kind of obvious
EXT		CopyRegionPath			; copy a Path's Region
EXT		ConvertRegionPathToRegion	; removes RegionPath header
EXT		PathStoreState			; store state of GState on stack
EXT		PathRestoreState		; restore GS state from stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

DESCRIPTION:
	This file contains the low-level routines to support the kernel's
	graphic path operations.

	$Id: graphicsPathLow.asm,v 1.1 97/04/05 01:13:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <GR_DRAW_LINE eq GSE_FIRST_OUTPUT_OPCODE>
CheckHack <GR_DRAW_TEXT_PTR eq GSE_LAST_OUTPUT_IN_PATH>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Creating Path routines #1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPathRect	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddRectangleToPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a rectangle the passed Path

CALLED BY:	SetClipRectCommon

PASS:		DS	= GState segment
		BP	= <14:0> Path chunk offset
			= <15>  Document (=0) or Window (=1) coordinates
		SI	= PathCombineType
		AX	= R_left
		BX	= R_top
		CX	= R_right
		DX	= R_bottom

RETURN:		DS	= GState segment (possibly updated)
		AX	= Handle of new Path

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; The Path template for rectangles. We will fill in the data after
; creating a duplicate of the structure.
;
		even	; to make rep movsw, below, as fast as possible
rectPath	label	byte
		GSBeginString
			GSBeginPath	0

PATH_TRANSFORM_OFFSET	equ $-rectPath
			GSSetTransform	<0.0>, <0.0>, <0.0>, <0.0>, <0.0>, <0.0>

PATH_MOVE_TO_OFFSET	equ $-rectPath
			GSMoveTo	0, 0

PATH_DATA_OFFSET	equ $-rectPath
		 	GSDrawRect	0, 0, 0, 0

			GSEndPath
		GSEndString
		even	; ditto
PATH_RECT_SIZE		equ $-rectPath

AddRectangleToPath	proc	far
	uses	es
	.enter
	
	; Create a duplicate on the stack, and copy the data
	;
EC <	cmp	si, PathCombineType					>
EC <	ERROR_A	GRAPHICS_PATH_ILLEGAL_COMBINE_PARAMETER			>
	sub	sp, PATH_RECT_SIZE
	mov	di, sp				; buffer => SS:DI
	push	cx, si, ds
	segmov	es, ss				; destination => ES:DI
	segmov	ds, cs
	mov	si, offset rectPath		; source => DS:SI	
	mov	cx, PATH_RECT_SIZE/2
		CheckHack <(PATH_RECT_SIZE and 1) eq 0>
	rep	movsw				; copy the template GString

	; Copy in the current transformation
	;
	pop	ds				; GState segment => DS
	lea	di, [di-PATH_RECT_SIZE][PATH_TRANSFORM_OFFSET + \
		    (offset OST_elem11)]
	mov	si, offset GS_TMatrix

	; Below we need to know if the tmatrix has any rotation or
	; skew in it so that PSF_PATH_IS_RECT can be set correctly
	mov	cx, ds:[si].TM_12.WWF_int
	ornf	cx, ds:[si].TM_12.WWF_frac
	ornf	cx, ds:[si].TM_21.WWF_int
	ornf	cx, ds:[si].TM_21.WWF_frac
	push	cx				; or of TM_12 and TM_21
	mov	cx, (size TransMatrix) / 2	; number words to copy => CX
	rep	movsw

	; Fill in the rectangle's bounds
	;
	pop	di				; or of TM_12 and TM_21
	pop	cx, si				; restore other registers
	push	di				; or of TM_12 and TM_21
	mov	di, sp				
	add	di,2				; rect path => ES:DI
	mov	es:[di+PATH_DATA_OFFSET].ODR_x1, ax	; left
	mov	es:[di+PATH_DATA_OFFSET].ODR_y1, bx	; top
	mov	es:[di+PATH_DATA_OFFSET].ODR_x2, cx	; right
	mov	es:[di+PATH_DATA_OFFSET].ODR_y2, dx	; bottom

	; Complete any other information
	;
	test	bp, CLIP_RECT_COORD_MASK	; check for window coords
	jz	combine
	ornf	es:[di].OBP_flags, PCS_PAGE shl offset BPF_COORD_TYPE

	; Now combine the Path
combine:
	and	bp, not (CLIP_RECT_COORD_MASK)	; clear mask bit
	mov	ax, ds:[bp]			; current Path handle => AX
	mov	cx, si				; PathCombineType => CX
	mov	dl, PCS_RECT			; PathCombineSource => DL
	mov	bx, di				; GString => ES:BX
	tst	ax				; if NULL path, remember
	pushf
	call	CombineGStringOrPathWithPath
	popf

	; Set optimization flag, if possible. If we started out with a
	; NULL path, then we'd always better end up using the
	; optimization (DLR 2/2/95).
	;
	pop	si				; or of TM_12 and TM_21
	jz	justRect			; if no path, take optimization
	cmp	cx, PCT_REPLACE
	jne	done
justRect:
	tst	ax				; if NULL path, do nothing
	jz	done
	tst	si				; no opt if gstate matrix
	jnz	done				; had skew or rotate
	mov	si, ax
	mov	si, ds:[si]			; Path => DS:SI
	tst	ds:[si].P_slowRegion		; if non-zero, biff it
	jnz	biffSlowRegion
setRectFlag:
	or	ds:[si].P_flags, mask PSF_PATH_IS_RECT
done:
	add	sp, PATH_RECT_SIZE		; clean up stack frame

	.leave
	ret

	; there's a slow region, so biff the block
biffSlowRegion:
	push	bx
	clr	bx
	xchg	bx, ds:[si].P_slowRegion
	call	MemFree				; free the slowRegion block
	pop	bx
	jmp	setRectFlag
AddRectangleToPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineGStringOrPathWithPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine the current GString with a Path, using the passed
		combination type.

CALLED BY:	INTERNAL
	
PASS:		DS	= Segment of GState
		AX	= Handle of current path (may be NULL)
		BX	= Handle of path or GString to combine (may be NULL)
				If GString, BX is an hptr
				If Path, BX is an lptr in the GState block
				If Ptr, ES:BX is the Path
		CX	= PathCombineType (if already a Path)
		DL	= PathCombineSource

RETURN:		AX	= Handle of new path (may be NULL)
		DS	= Segment of GState (may have moved)
		SI	= Start of new sub-Path, if AX not NULL

DESTROYED:	DX, BP, ES

PSEUDO CODE/STRATEGY:
		If (PCT_NULL)
			New path = Null	
		If (PCT_REPLACE)
			New path = Passed
		If (PCT_UNION)
			If (Current Path = Null)
				New path = Null
			Else
				New path = Current + Passed (with OR bit set)
		If (PCT_INTERSECTION)
			If (Current Path = Null)
				New path = Passed
			Else
				New path = Current + Passed (with AND bit setr)
					
		The most questionable of the choices above occur when we
		consider what happens to an emtpy path when we try to combine
		it with a new path, via a UNION or INTERSECTION. Because this
		sort of operation is most useful for clip paths, we assume an
		empty path is equivalent to the entire screen.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CombineGStringOrPathWithPath	proc	far
	uses	bx, cx, di
	.enter

	; Some set-up work
	;
EC <	cmp	dl, PathCombineType		; valid type??		>
EC <	ERROR_A	GRAPHICS_PATH_INTERNAL_ILLEGAL_PATH_COMBINE_TYPE	>
	push	dx				; save the PathCombineType
	push	ax				; save the existing path
	mov	al, dl
	clr	dx				; assume no new combination
	tst	bx				; see if we were passed anything
	jz	common				; nope - so do nothing
	cmp	al, PCS_PATH
	je	withPath
	cmp	al, PCS_GSTRING
	je	withGString

	; Deal with pointers to rectangles
	;
	mov	si, bx				; GString => ES:SI
	or	es:[si].OBP_flags, cl		; or in the combine flags
	mov	dx, PATH_RECT_SIZE		; size of data => DX
	jmp	common

	; Deal with existing GStrings
	;
withGString:
	call	MemLock				; lock down the GString
	mov	es, ax
	mov	si, es:[GSS_firstBlock]		; get chunk holding GString
	mov	si, es:[si]			; derference the chunk
	ChunkSizePtr	es, si, dx		; size of chunk => DX
	mov	cx, es:[si].OBP_combine		; PathCombineType => CX
	call	WritePathBackToGString		; write back, if necessary
	jmp	common

	; Deal with existing Paths
withPath:
	segmov	es, ds
	mov	si, es:[bx]			; Path => ES:SI
	ChunkSizePtr	es, si, dx
	add	si, offset P_data		; start of opcodes => ES:SI
	sub	dx, offset P_data		; actual size of opcodes => DX
	andnf	es:[si].OBP_flags, not (mask BPF_COMBINE)
	ornf	es:[si].OBP_flags, cl		; or in the combine flags

	; See how this stuff will be combined (GString-type path is in ES:SI)
	; Size of new data is in DX. If DX is zero, no new Path will be created.
common:
EC <	cmp	cx, PathCombineType					>
EC <	ERROR_A	GRAPHICS_PATH_ILLEGAL_COMBINE_PARAMETER			>
	pop	di				; existing Path => DI
	cmp	cx, PCT_REPLACE			; replace or null current path ?
	jle	remove				; yes, so nuke current path
	cmp	cx, PCT_INTERSECTION		; if we're intersecting, we
	je	append				; ...always append the new data

	; Deal with an UNION combination
	;
	clr	ax				; assume no future Path
	tst	di				; is the current Path empty ??
	jz	done				; yes, so the result is empty
	jmp	append				; else append the new Path

	; Now combine the Path & GString (PathCombineType still in CL)
remove:
	call	GrDestroyPath			; free the path
	clr	di				; no current Path
append:
	mov	ax, di				; existing chunk handle => AX
	cmp	cl, PCT_NULL			; are we nuking the path ??
	je	done
	mov	cx, dx				; current GString size => CX
	jcxz	done				; no new Path or Gstring - done
	tst	ax				; already have a clipPath ??
	jz	allocate
	ChunkSizeHandle	ds, di, dx		; size of chunk => DX
	dec	dx				; ignore GR_END_GSTRING
	add	cx, dx
	call	LMemReAlloc
	jmp	copyData
allocate:
	mov	dx, size Path			; "original" size
	add	cx, dx				; allocate size => CX
	call	LMemAlloc			; new chunk handle => AX
	mov	di, ax				; chunk handle => DI
	mov	bp, ds:[di]			; dereference the chunk
	mov	ds:[bp].P_slowRegion, 0		; no initial Region
	mov	ds:[bp].P_flags, 0		; clear all flags

	; Now copy the GString bytes into the Path
copyData:
	segxchg	es, ds
	mov	di, es:[di]			; dereference chunk handle
	and	es:[di].P_flags, not (mask PSF_REGION_VALID or \
				      mask PSF_PATH_IS_RECT)
	add	di, dx				; start copying here
	sub	cx, dx				; bytes to copy => CX
	pop	dx				; PathCombineType => DL
	cmp	dl, PCS_PATH			; Path or GString ?
	jne	copy				; from a Gstring - copy
	mov	si, es:[bx]			; else re-dereference Path
	add	si, offset P_data		; start of opcodes => DS:SI
copy:	
	push	di				; save start of new subPath
	rep	movsb				; do the copy work
	segmov	ds, es				; GState segment back => DS
	pop	si				; start of new subPath => DS:SI
	push	dx

	; Finally, clean up. New Path handle is in AX
done:
	pop	dx
	cmp	dl, PCS_GSTRING			; dealing with a Path or GString
	jne	exit				; not a GString - boogie!
	tst	bx
	jz	exit
	call	MemUnlock			; unlock the GString
exit:
	.leave
	ret
CombineGStringOrPathWithPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDestroyPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys a path

CALLED BY:	INTERNAL
	
PASS:		DS:*DI	= Path (must be in Lmem chunk) (DI may be NULL)

RETURN:		Nothing

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDestroyPath	proc	far
	uses	ax, bx
	.enter

	; Clean up the Path, and then free it
	;
	tst	di
	jz	done
	mov	bx, ds:[di]
	mov	bx, ds:[bx].P_slowRegion
	tst	bx
	jz	freePath
	call	MemFree				; free the region
freePath:
	xchg	ax, di
	call	LMemFree			; free the actual chunk
done:
	.leave
	ret
GrDestroyPath	endp

GraphicsPathRect	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Fill Path (rectangular) routines #2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPathRect	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinPathValidateRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a clip region to be used by a Window

CALLED BY:	WinCopyPathToReg

PASS:		DS	= GState segment
		ES	= Window segment
		SI	= Path chunk handle (in GState)
		CX	= X window offset
		DX	= Y window offset

RETURN:		ES	= Window segment (possibly updated)
		DS:SI	= Region
		CX	= Region size (in bytes)
		BX	= Region handle to unlock
			  (may be zero, as may be stored in GState block)

DESTROYED:	AX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinPathValidateRegion	proc	far
	.enter

	; First check to see if we need to build a region at all.
	;
	push	es:[LMBH_handle]		; save Window handle => BX
	mov	al, RFR_ODD_EVEN
	call	PathCheckRegionValidity		; RegionPath => ES
	jc	invalid
	segmov	ds, es				; RegionFull => DS:SI
	pop	ax
	xchg	ax, bx
	call	MemDerefES			; es -> window
	xchg	ax, bx
done:
	add	si, (size RegionFull)		; want Region => DS:SI

	.leave
	ret

	; First save the Window's current TMatrix
invalid:
	pop	bx				; restore window handle
	push	bx				; re-save orig window handle
	push	ds:[LMBH_handle]		; save GState handle too
	call	MemDerefES			; es -> window
	call	CreateDupWin			; create an imposter window

	; Setup the mask rectangle bounds, as they are expected to
	; be valid by the path's build code. We can't use the current
	; mask rectangle bounds, as we are *creating* the mask region.
	;		
	mov	cx, es:[W_winRect].R_right
	mov	dx, es:[W_winRect].R_bottom
	mov	ax, es:[W_winRect].R_left
	mov	bx, es:[W_winRect].R_top

	mov	es:[W_maskRect].R_left, ax	; Store bounds of W_winReg
	mov	es:[W_maskRect].R_top, bx
	mov	es:[W_maskRect].R_right, cx
	mov	es:[W_maskRect].R_bottom, dx
	
	; Build the Region now. We need to release the Window around the
	; call to BuildRegionFromPath().
	;
	mov	bx, es:[LMBH_handle]		; window Handle => BX
	call	MemUnlockV			; V the window, and unlock it

	mov	dx, bx				; Window handle => DX
	mov	cl, RFR_ODD_EVEN		; RegionFillRule => CL
	call	PathBuildRegion			; build that region
	segmov	ds, es				; ds:si -> RegionFull

	push	bx				; save results
	mov	bx, dx				; Window handle => BX
	call	MemPLock			; lock & own Window
	mov	es, ax				; Window segment => ES
	pop	bx				; restore results

	; Now restore the current TMatrix in the Window
	;
	pop	dx				; restore GState handle
	pop	ax				; restore original win handle
	call	DestroyDupWin			; kill the imposter
	; update W_bmSegment in original window since path drawing could have
	; moved it
	tst	es:[W_bmSegment]
	jz	done
updateBMSegment::
	push	bx, di, ds
	mov	bx, es:[W_bitmap].segment
	mov	di, es:[W_bitmap].offset
	call	HugeArrayLockDir		; lock to deref (already locked)
EC <	cmp	ax, es:[W_bmSegment]					>
EC <	WARNING_NE	0						>
	mov	es:[W_bmSegment], ax
	mov	ds, ax
	call	HugeArrayUnlockDir		; remove our extra lock
	pop	bx, di, ds
	jmp	done
WinPathValidateRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDupWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a duplicate window to use during path creation 

CALLED BY:	INTERNAL
		WinPathValidateRegion
PASS:		ds	- locked GState
		es	- PLocked Window to duplicate
		bx	- handle of PLocked window
RETURN:		es	- PLocked duplicate window
		bx	- handle of PLocked duplicate
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ALLOC_WINDOW_FLAGS	= ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE or ((HAF_STANDARD_NO_ERR_LOCK) shl 8)

CreateDupWin	proc	near
		uses	ax, cx, ds, si, di
		.enter

		push	es			; save old window
	;
	; If the window has a lot of free space, contract the sucker before
	; we try to duplicate all that extra cruft....
	; 			-- ardeb 3/25/94
	; 
		cmp	es:[LMBH_totalFree], 8192
		jb	dupIt
		push	ds
		segmov	ds, es
		call	LMemContract
		pop	ds
dupIt:

		mov	ax, MGIT_SIZE		; get the size of the block
		call	MemGetInfo		; ax = block size
		push	ax			; save size
		mov	cx, ALLOC_WINDOW_FLAGS
		call	MemAllocFar		; 
		call	HandleP			; PLock the window
		mov	es, ax			; es -> new block
		mov	es:[LMBH_handle], bx	; stuff right handle
		mov	ds:[GS_window], bx	; re-orient things

		; need to set the LMEM bit in the handle table too

		LoadVarSeg ds
		or	ds:[bx].HM_flags,mask HF_LMEM

		pop	cx			; cx = size of copy
		sub	cx, 2			; already have the handle
		shr	cx, 1			; copy words for speed
		pop	ds			; ds -> old window
		mov	si, 2			; start after the block handle
		mov	di, si			; 
		jnc	doWords
		movsb				; one odd duck
doWords:
		rep	movsw			; copy block contents

		.leave
		ret
CreateDupWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyDupWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Companion to CreateDupWin, used to get rid of imposter window

CALLED BY:	INTERNAL
		WinPathValidateRegion
PASS:		es	- pointer to PLocked duplicate
		ax	- handle of original PLocked window
		dx	- handle of GState
RETURN:		es	- pointer to PLocked original
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyDupWin	proc	near
		uses	bx, ds
		.enter

		push	es			; save imposter
		mov	bx, ax
		call	MemDerefES		; es -> PLocked original
		mov	bx, dx			; grab GState handle
		call	MemDerefDS		; ds -> GState
		mov	ds:[GS_window], ax	; rejoin them
		pop	ds			; ds -> imposter
		mov	bx, ds:[LMBH_handle]	; bx = handle of imposter
		call	MemUnlockV		; release it...
		call	MemFree			; ...and free it

		.leave
		ret
DestroyDupWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathValidateRegionAndWinValWinStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the current path after making sure that
		the window is up to date

CALLED BY:	INTERNAL
		CalcPathBounds
		GrTestPointInPath

PASS:		DS	= GState segment
		SI	= Path chunk handle
		CL	= RegionFillRule

RETURN:		ES:SI	= RegionFull (Region preceded by bounds)
		CX	= Region size
		BX	= RegionFull Handle to unlock
			  (may be zero, as may be stored in GState block)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathValidateRegionAndWinValWinStruct		proc	far

	; Lock the window, if there is one
	;
	mov	bx, ds:[GS_window]	; bx = Window handle 
	tst	bx			; if zero, bogus window
	jz	validateRegion
	push	ax
	call	MemPLock
	mov	es, ax			; es -> Window

	; Make sure that clip info and transformation matrix are valid
	; ds = graphics state, es = window
	;
	mov	ax, ds:[GS_header][LMBH_handle]
	cmp	ax, es:[W_curState]	; see if we need to do both
	jne	notValid		;  no, update clip info
	test	es:[W_grFlags], mask WGF_MASK_VALID or mask WGF_XFORM_VALID
	jnz	unlockWindow
notValid:
	call	WinValWinStrucFar	; Validate clip info
unlockWindow:
	call	MemUnlockV		; release window
	pop	ax

	; Now perform the normal validation
validateRegion:
	FALL_THRU	PathValidateRegion
PathValidateRegionAndWinValWinStruct		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathValidateRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the current path

CALLED BY:	EXTERNAL

PASS:		DS	= GState segment
		SI	= Path chunk handle
		CL	= RegionFillRule

RETURN:		ES:SI	= RegionFull (Region preceded by bounds)
		CX	= Region size
		BX	= RegionFull Handle to unlock
			  (may be zero, as may be stored in GState block)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathValidateRegion	proc	far
	uses	ax
	.enter
	
	tst	ds:[GS_window]
	jz	checkRegion

	push	bx
	mov	bx, ds:[GS_window]
	call	MemPLock
	mov	es, ax				; es -> Window
	pop	bx

checkRegion:
	; First check to see if the current region is valid
	;
EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_A	GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
   	mov	al, cl				; RegionFillRule => AL

	call	PathCheckRegionValidity

	pushf
	tst	ds:[GS_window]
	jz	winReleased
	push	bx				; save the RegionPath handle
	mov	bx, ds:[GS_window]		;  in case it's valid
	call	MemUnlockV
	pop	bx				; restore RegionPath
winReleased:
	popf

	jnc	done				; it's valid, so we're done
	call	PathBuildRegion			; else go build RegionPath
done:
	.leave
	ret
PathValidateRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathCheckRegionValidity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the currently built region (if one exists)
		is valid

CALLED BY:	BuildRegionFromPath

PASS: 		DS	= GState segment
		ES	- Window segment
		SI	= Path chunk handle
		AL	= RegionFillRule

RETURN:		Carry	= Clear (valid)
		ES:SI	= RegionFull
		CX	= Region size
		BX	= Region handle to unlock
			  (may be zero, as may be stored in GState block)
			- or -
		Carry	= Set (invalid)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		* If there is no path, or one exists with a different
		  RegionFillRule, then the region is obviously invalid

		* Otherwise, we need to check to see if the same TMatrix
		  will be used, and if the top and bottom bounds are the
		  same.  The top and bottom bounds are stored in the chunk,
		  and a one-word checksum of the TMatrix is stored, constructed
		  by XORing all the words of the TMatrix together.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathCheckRegionValidity	proc	near
	uses	bp, dx
	.enter
	
	; See if we need to do any work at all
	;
EC <	cmp	al, RegionFillRule					>
EC <	ERROR_A	GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
	mov	bp, ds:[si]			; dereference the Path chunk
	mov	bx, ds:[bp].P_flags		; PathStateFlags => BX

	; before we do anything, zero out the slowRegion field if we have 
	; a rectangular region.  It *should* always be zero, but there is
	; some case where this is not so...

	test	bx, mask PSF_PATH_IS_RECT
	jz	notRect
	clr	ds:[bp].P_slowRegion		; if rect, no extra block

notRect:
	test	bx, mask PSF_REGION_VALID	; do we think it's valid ??
	LONG jz	invalidate

	; Check the RegionFillRule
	;
	andnf	bx, mask PSF_FILL_RULE		; RegionFillRule => BH
EC <	cmp	bh, RegionFillRule					>
EC <	ERROR_A	GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
	cmp	bh, al				; same fill rule ??
	LONG jne invalidate			; nope, so invalidate it

	; finally, we must check the top and bottom of the window, and the 
	; TMatrix that will be used to generate the region.  If either are 
	; different, then we need to regenerate it.

	push	di, bp				; save reg
	mov	di, ds:[LMBH_handle]		; get GState handle

	; this code below is essentially WinGetTopBottom, which we move
	; here so we don't have to call into another resource.  Also, we need
	; to fetch the sum of some matrix components

	mov	bp, -1024			; load bogus bounds in case
						;  there is no window.
	mov	dx, 1024			; load up biggest video driver
	clrdw	cxax				; use for summing
	tst	ds:[GS_window]			; check for bogus window
	jz	haveTopBottom
	mov	bp, es:[W_winRect].R_top	; minimum Y => BP
	mov	dx, es:[W_winRect].R_bottom	; maximum Y => DX
	mov	ax, es:[W_TMatrix].TM_31.DWF_frac
	mov	cx, es:[W_TMatrix].TM_31.DWF_int.low
	add	ax, es:[W_TMatrix].TM_32.DWF_frac
	adc	cx, es:[W_TMatrix].TM_32.DWF_int.low
	addwwf	cxax, es:[W_TMatrix].TM_11
	addwwf	cxax, es:[W_TMatrix].TM_22
haveTopBottom:
	mov	bx, bp				; bx = min Y
	pop	di, bp				; restore reg used for GState
	cmp	bx, ds:[bp].P_top		; top different ?
	jl	invalidate
	cmp	dx, ds:[bp].P_bottom		; check bottom too
	jg	invalidate
	cmpwwf	cxax, ds:[bp].P_matrix		; check against matrix
	jne	invalidate

if	CACHED_PATHS
	; calculate a sort of checksum for the TMatrix, so we don't have 
	; to store/compare the whole thing.  All we need to know is if it
	; has changed.

	; now we have to check the TMatrix out.  We will use either the
	; GS_TMatrix or W_curTMatrix, depending on if we have a window.

	mov	bx, ds:[GS_window]		; get suspected win handle
	tst	bx				; if a window, use that
	LONG jnz realWindow

	xor	bx, ds:[GS_TMatrix].TM_11.WWF_int
	xor	bx, ds:[GS_TMatrix].TM_11.WWF_frac
	add	bx, ds:[GS_TMatrix].TM_12.WWF_int
	add	bx, ds:[GS_TMatrix].TM_12.WWF_frac
	add	bx, ds:[GS_TMatrix].TM_21.WWF_int
	add	bx, ds:[GS_TMatrix].TM_21.WWF_frac
	xor	bx, ds:[GS_TMatrix].TM_22.WWF_int
	xor	bx, ds:[GS_TMatrix].TM_22.WWF_frac
	xor	bx, ds:[GS_TMatrix].TM_31.DWF_int.high
	xor	bx, ds:[GS_TMatrix].TM_31.DWF_int.low
	xor	bx, ds:[GS_TMatrix].TM_31.DWF_frac
	xor	bx, ds:[GS_TMatrix].TM_32.DWF_int.high
	xor	bx, ds:[GS_TMatrix].TM_32.DWF_int.low
	xor	bx, ds:[GS_TMatrix].TM_32.DWF_frac

haveChecksum:
	xchg	bx, ds:[bp].P_checksum		; update it anyway
	cmp	bx, ds:[bp].P_checksum		; see if changed
	jne	invalidate
endif

	; Yahoo !  We have a valid region.  Lock it down, scotty.
	; Assume that it is a rect region...

	segmov	es, ds, bx			; es -> GState
	lea	si, ds:[bp].P_rectRegion	; es:si -> RegionFull
	mov	cx, size RectRegion		; cx = region size
	mov	bx, ds:[bp].P_slowRegion	; get region handle
	tst	bx				; if zero, we're done
	jz	doneValid
	
	call	MemLock				; ax -> RegionPath
	mov	es, ax				; es -> RegionPath
	mov	si, offset RP_bounds		; es:si -> RegionFull
	mov	cx, es:[RP_size]		; get block size
	sub	cx, size RegionPath 		; cx = size of region
doneValid:
	clc
done:	
	.leave
	ret

	; The Region needs to be re-built.
invalidate:
	and	ds:[bp].P_flags, not (mask PSF_REGION_VALID)
	clr	bx
	xchg	bx, ds:[bp].P_slowRegion	; RegionPath handle => BX
	tst	bx				; did one exist ??
	jz	doneSTC				; no, so we're done
	call	MemFree				; else free that RegionPath
doneSTC:
	stc
	jmp	done

if	CACHED_PATHS
	; there is a real window out there.  Get a pointer to the window TM
realWindow:
	clr	bx				; init checksum
	xor	bx, es:[W_curTMatrix].TM_11.WWF_int
	xor	bx, es:[W_curTMatrix].TM_11.WWF_frac
	add	bx, es:[W_curTMatrix].TM_12.WWF_int
	add	bx, es:[W_curTMatrix].TM_12.WWF_frac
	add	bx, es:[W_curTMatrix].TM_21.WWF_int
	add	bx, es:[W_curTMatrix].TM_21.WWF_frac
	xor	bx, es:[W_curTMatrix].TM_22.WWF_int
	xor	bx, es:[W_curTMatrix].TM_22.WWF_frac
	xor	bx, es:[W_curTMatrix].TM_31.DWF_int.high
	xor	bx, es:[W_curTMatrix].TM_31.DWF_int.low
	xor	bx, es:[W_curTMatrix].TM_31.DWF_frac
	xor	bx, es:[W_curTMatrix].TM_32.DWF_int.high
	xor	bx, es:[W_curTMatrix].TM_32.DWF_int.low
	xor	bx, es:[W_curTMatrix].TM_32.DWF_frac
	jmp	haveChecksum
endif
PathCheckRegionValidity	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathBuildRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a RegionPath for the current path

CALLED BY:	WinPathValidateRegion(), PathValidateRegion()

PASS:		DS	= GState segment
		SI	= Path chunk handle
		AL	= RegionFillRule

RETURN:		ES:SI	= RegionFull
		CX	= Region size
		BX	= RegionFull handle to unlock
			  (may be zero, as may be stored in GState block)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathBuildRegion	proc	near
	uses	ax, dx, di, bp
	.enter

	mov	di, 400
	call	ThreadBorrowStackSpace
	push	di
	
	call	PathBuildRegionRect
	jnc	done				; if valid, we're done
	call	PathBuildRegionSlow
done:
	mov	si, di				; RegionFull => ES:SI
	mov_tr	cx, ax				; Region size => CX

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
PathBuildRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathBuildRegionRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds a rectangular RegionPath

CALLED BY:	PathBuildRegion()

PASS:		DS	= GState segment
		SI	= Path chunk handle
		CL	= RegionFillRule

RETURN:		Carry	= Clear (valid)
		ES:DI	= RegionFull
		BX	= 0
		AX	= Region size
			- or -
		Carry	= Set (invalid)

RETURN:		Nothing

DESTROYED:	DX, BP

PSEUDO CODE/STRATEGY:
		We can pre-build the rectangular region iff:
			* No rotation in either the GState or Window
			* A Window is present

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 3/91		Initial version
	jim	5/92		added code to check for W_curTMatrix valid

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathBuildRegionRect	proc	near
	uses	cx, si
	.enter
	
	; See if we are a simple rectangular path
	;
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	call	PathStoreState			; store GState's state on stack
	mov	si, ds:[si]
	test	ds:[si].P_flags, mask PSF_PATH_IS_RECT
	jnz	haveRect			; yes, so continue
fail:
	call	PathRestoreState
	stc					; we've failed
	jmp	exit				; and we're outta here

	; So far so good. Set thing up to translate the points.
haveRect:
	test	ds:[si + (size Path)].OBP_flags, mask BPF_COORD_TYPE
	jnz	window
	add	si, (size Path) + PATH_TRANSFORM_OFFSET + 1
	call	PathSetTransform		; set the transformation matrix
	sub	si, (size Path) + PATH_TRANSFORM_OFFSET + 1
	jmp	common
window:
	call	PathSetNullTransform		; clear any transformation
common:
	call	LockWinFromGStateHandle		; lock & own Window
	jc	fail				; if no Window, we fail
	mov	bp, bx				; Window handle => BP
	test	es:[W_curTMatrix].TM_flags, TM_ROTATED
	stc
	jnz	unlockWindow

	; Before transforming coords, save away the top and bottom of the 
	; window for later.  (and the matrix sum too).

	mov	ax, es:[W_winRect].R_top	; get top and bottom
	mov	ds:[si].P_top, ax
	mov	ax, es:[W_winRect].R_bottom
	mov	ds:[si].P_bottom, ax
	mov	ax, es:[W_TMatrix].TM_31.DWF_frac
	mov	cx, es:[W_TMatrix].TM_31.DWF_int.low
	add	ax, es:[W_TMatrix].TM_32.DWF_frac
	adc	cx, es:[W_TMatrix].TM_32.DWF_int.low
	addwwf	cxax, es:[W_TMatrix].TM_11
	addwwf	cxax, es:[W_TMatrix].TM_22
	movwwf	ds:[si].P_matrix, cxax

	; Things are looking good. Transform the coordinates
	;
	mov	ax, ds:[si + (size Path) + PATH_DATA_OFFSET].ODR_x2
	mov	bx, ds:[si + (size Path) + PATH_DATA_OFFSET].ODR_y2
	call	GrTransCoordFar
	jc	unlockWindow
	mov_tr	cx, ax
	mov	dx, bx	
	mov	ax, ds:[si + (size Path) + PATH_DATA_OFFSET].ODR_x1
	mov	bx, ds:[si + (size Path) + PATH_DATA_OFFSET].ODR_y1
	call	GrTransCoordFar
unlockWindow:
	xchg	bx, bp				; Window handle => BX, top => BP
	call	MemUnlockV			; unlock & release Window
	LONG jc	fail				; some error, so we fail

	; if the current Transform has a negative scale factor, but no rotation
	; then the coords may be reversed here.  Sort them before using them.

	cmp	ax, cx				; check X coords
	jle	xOK
	xchg	ax, cx
xOK:
	cmp	bp, dx				; check Y coords
	jle	yOK
	xchg	bp, dx

	; Now go stuff the values into the Path, and we are done
	;
yOK:
	mov	ds:[si].P_rectRegion.RFR_header.RF_bounds.R_left, ax
	mov	ds:[si].P_rectRegion.RFR_header.RF_bounds.R_top, bp
	mov	ds:[si].P_rectRegion.RFR_header.RF_bounds.R_right, cx
	mov	ds:[si].P_rectRegion.RFR_header.RF_bounds.R_bottom, dx

	; The coordinates are in the normal (0 based) convention.  Change
	; them to the screwy region coordinates

	dec	bp			;top = top - 1
	dec	dx			;bottom = bottom - 1
	dec	cx			;right = right - 1

	mov	ds:[si].P_rectRegion.RFR_left, ax
	mov	ds:[si].P_rectRegion.RFR_top, bp
	mov	ds:[si].P_rectRegion.RFR_right, cx
	mov	ds:[si].P_rectRegion.RFR_bottom, dx
	
	mov	ax, EOREGREC
	mov	ds:[si].P_rectRegion.RFR_stop1, ax
	mov	ds:[si].P_rectRegion.RFR_stop2, ax
	mov	ds:[si].P_rectRegion.RFR_stop3, ax

	; mark region valid, even for rectangular region

	or	ds:[si].P_flags, mask PSF_REGION_VALID
	clr	ds:[si].P_slowRegion

	call	PathRestoreState		; restore GState's state
	segmov	es, ds
	mov	di, si
	add	di, offset P_rectRegion		; RegionFull => ES:DI
	mov	ax, (size RegionFullRect) - (size RegionFull)
	clr	bx				; no handle to unlock
exit:
	.leave
	ret
PathBuildRegionRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathStoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store any part of the GState data away that we might
		alter

CALLED BY:	INTERNAL
	
PASS:		DI	= GState

RETURN:		Lots of stuff pushed onto the stack

DESTROYED:	AX, DX, flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PATH_STORE_STATE_BUFFER_SIZE = (size TransMatrix) + (size PointWWFixed)

PathStoreState	proc	far

	; Get the return address. Store some crucial information,
	; and then return
	;
	popdw	dxax				; return address => DX:AX
	sub	sp, PATH_STORE_STATE_BUFFER_SIZE
	pushdw	dxax				; store return address
	push	bx, cx, si, ds			; save some data
	segmov	ds, ss
	mov	si, sp
	add	si, 12				; 4 registers + ret_addr
	call	GrGetTransform
	add	si, size TransMatrix
	call	GrGetCurPosWWFixed		; position => AX, BX
	movdw	ds:[si].PF_x, dxcx
	movdw	ds:[si].PF_y, bxax
	pop	bx, cx, si, ds
	ret
PathStoreState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState
		ds:si	- pointer to buffer to fill with new TransMatrix to use
			  There should be room for 6 elements, 
			  each of type WWFixed.
			  
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
GrGetTransform	proc	far
		uses ds, es, cx, ax, bx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx				>
EC <		mov	bx, ds				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		pop	bx				>
endif
		segmov	es, ds, bx
		mov	bx, di			; lock GState
		call	MemLock			;
		mov	ds, ax			; set up segreg
		mov	di, si			; es:di -> buffer
		mov	si, GS_TMatrix.TM_11	; set up pointer to matrix
		mov	cx, (size TransMatrix)/2 ; #words to copy
		rep	movsw			; copy the matrix
		mov	si, di			; restore reg
		sub	si, size TransMatrix
		mov	di, bx
		call	MemUnlock		; unlock the gstate

		.leave
		ret
GrGetTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the GState data we earlier saved

CALLED BY:	INTERNAL
	
PASS:		DI	= GState handle

RETURN:		Lots of stuff popped from the stack

DESTROYED:	AX, DX, flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathRestoreState	proc	far

	; Buffer lies just below the return address. Restore information
	;
	push	bx, cx, si, ds
	segmov	ds, ss
	mov	si, sp
	add	si, 12				; 4 registers + ret_addr
	call	PathSetTransform
	segmov	ds, ss				; restore stack segment
						; (for some reason,
						;	PathSetTransform sets
						;	ds = GState)
	add	si, size TransMatrix
	movdw	dxcx, ds:[si].PF_x
	movdw	bxax, ds:[si].PF_y
	call	GrMoveToWWFixed			; move back to this position	
	pop	bx, cx, si, ds
	popdw	dxax				; return address => DX:AX
	add	sp, PATH_STORE_STATE_BUFFER_SIZE
	pushdw	dxax				; return address to stack
	ret
PathRestoreState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathSetTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transform w/o the data being written to a GString

CALLED BY:	INTERNAL

PASS:		di	- GState
		ds:si	- pointer to TransMatrix to set

RETURN:		nothing

DESTROYED:	ds, 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathSetTransform	proc	far
		push	ax, bx, cx, es
		call	GSetTransform		
		GOTO	PST_common, es, cx, bx, ax
PathSetTransform	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSetTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace transformation

CALLED BY:	GLOBAL

PASS:		di	- handle to GState 
		ds:si	- pointer to new TMatrix to use
			  There should be six elements, each a 32-bit fixed
			  point number (1 word integer, 1 word fraction), 
			  arranged in row order.  That is, for the matrix:
				[e11 e12 0]
				[e21 e22 0]
				[e31 e32 1]
			   The passed array should be the six elements:
				[e11 e12 e21 e22 e31 e32]

RETURN:		ds,es	- pointer to GState

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		copy the new transformation into GS_TMatrix 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSetTransform	proc	far

;this will give a nice warning message if WWFixed is not an even number
;of bytes. this assumptions is made through out this routine
CheckHack < ((size WWFixed and 1) eq 0) >

		; set up the right segregs, pointers

		push	di			; save GState handle
		mov	bx, di			; lock GState
		call	MemLock			;
		mov	es, ax			; set up segreg
		mov	di, GS_TMatrix+TM_11	; set up pointer to matrix
		mov	cx, (size TransMatrix)/2 ; #words to copy
		rep	movsw			; copy the matrix
		sub	si, size TransMatrix	; restore si
		mov	di, GS_TMatrix		; set up pointer to matrix
		call	SetTMatrixFlags	; check/set matrix flags
		segmov	ds, es, di		; set ds -> gstate
		pop	di			; restore handle
		ret
GSetTransform	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTMatrixFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate TMatrix flags, make sure right optimization bits set

CALLED BY:	INTERNAL

PASS:		es:di	- pointer to tmatrix to check

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTMatrixFlags proc	far
		uses	ax, bx
		.enter

		; clear out the flags first
	
		clr	bl				; use bl as temp reg
		mov	ax, es:[di].TM_31.DWF_int.high
		or	ax, es:[di].TM_32.DWF_int.high
		or	ax, es:[di].TM_31.DWF_frac	; or in all bits
		or	ax, es:[di].TM_31.DWF_int.low
		or	ax, es:[di].TM_32.DWF_frac	; or in all bits
		or	ax, es:[di].TM_32.DWF_int.low
		jz	check11				; no translation
		or	bl, mask TF_TRANSLATED		; set translation bit

		; check to see if we are within 1 in the fractions place to
		; zero.  If so, make it so (for all the upper 2x2).
check11:
		add	di, offset TM_11
		mov	ax, es:[di].WWF_frac		; checking fracs
		tst	ax
		jz	check22
		call	CheckForInteger			; if non-zero, check
check22:
		add	di, offset TM_22 - offset TM_11
		mov	ax, es:[di].WWF_frac		; checking fracs
		tst	ax
		jz	check21
		call	CheckForInteger			; if non-zero, check
check21:
		add	di, offset TM_21 - offset TM_22
		mov	ax, es:[di].WWF_frac		; checking fracs
		tst	ax
		jz	check12
		call	CheckForInteger			; if non-zero, check
check12:
		add	di, offset TM_12 - offset TM_21
		mov	ax, es:[di].WWF_frac		; checking fracs
		tst	ax
		jz	checkRotation
		call	CheckForInteger			; if non-zero, check
		
		; check for rotation, check off-diagonals
checkRotation:
		sub	di, offset TM_12
		mov	ax, es:[di].TM_12.WWF_frac	; get all four words
		or	ax, es:[di].TM_12.WWF_int
		or	ax, es:[di].TM_21.WWF_frac	; get all four words
		or	ax, es:[di].TM_21.WWF_int
		jz	checkScale			; no rotation
		or	bl, mask TF_ROTATED or mask TF_SCALED ; set bits

		; check for scaling by a factor of one
checkScale:
		cmp	es:[di].TM_11.WWF_int, 1 ; check for scale of one
		jne	setScaleBit		;  no, do it
		cmp	es:[di].TM_22.WWF_int, 1 ; check for scale of one
		jne	setScaleBit		;  no, do it
		mov	ax, es:[di].TM_11.WWF_frac ; check fractions
		or	ax, es:[di].TM_22.WWF_frac
		jz	done
setScaleBit:
		or	bl, mask TF_SCALED
done:
		mov	es:[di].TM_flags, bl ; set the flags
		.leave
		ret
SetTMatrixFlags endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a TMatrix element for something close to an integer

CALLED BY:	INTERNAL
		SetTMatrixFlags
PASS:		es:di	- ptr to WWFixed number
		ax	- fraction
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForInteger	proc	near
		cmp	ax, 1			; check for 1 and 0xffff
		je	changeItDown
		cmp	ax, 0xffff
		je	changeItUp
		ret

changeItUp:
		inc	es:[di].WWF_int
changeItDown:
		clr	es:[di].WWF_frac
		ret
CheckForInteger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathSetNullTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transform to NULL (identity), w/o writing to GString

CALLED BY:	INTERNAL

PASS:		same as GrSetNullTransform

RETURN:		same as GrSetNullTransform

DESTROYED:	same as GrSetNullTransform

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathSetNullTransform	proc	far
		push	ax, bx, cx, es
		call	GSetNullTransform		
		FALL_THRU	PST_common, es, cx, bx, ax
PathSetNullTransform	endp

PST_common	proc	far
		; now that we've set the new transform, we need to invalidate
		; the curTMatrix in the window, if there is one.

		mov	bx, ds:[GS_window]		; window handle => BX
		tst	bx				; check window handle
		stc					; assume no Window
		jz	unlock
EC <		call	ECCheckWindowHandle	; verify valid Window>
		call	MemPLock			; segment => AX
		mov	es, ax				; Window segment = ES
		and 	es:[W_grFlags], not mask WGF_XFORM_VALID
		call	MemUnlockV			; release window
unlock:
		mov	bx, di		; GState handle => BX
		call	MemUnlock	; unlock the sucker
		FALL_THRU_POP es, cx, bx, ax
		ret
PST_common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockWinFromGStateHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks the Window store in the GState

CALLED BY:	INTERNAL

PASS:		DI	= GState handle  (LockWinFromGStateHandle)

RETURN:		ES	= Window segment
		BX	= Window handle
		Carry	= Clear
			- or -
		BX	= 0 (no Window)
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockWinFromGStateHandle	proc	far
	uses	ax, ds
	.enter
	
	; Lock the Window, and compose matrix if necessary
	;
EC <	call	ECCheckGStateHandle		; verfiy handle		>
	mov	bx, di				; GState => BX
	call	MemDerefDS			; GState segment => DS
	mov	bx, ds:[GS_window]		; window handle => BX
	tst	bx				; check window handle
	stc					; assume no Window
	jz	done
EC <	call	ECCheckWindowHandle		; verify valid Window	>
	call	MemPLock			; segment => AX
	mov	es, ax				; Window segment = ES
	
	; check to see if the transform needs to be updated.  This is the 
	; case if either the flag is reset *or* there is a new GState 
	; associated with the window.
	;
	mov	ax, ds:[LMBH_handle]		; get GState handle
	cmp	ax, es:[W_curState]		; see if same GState
	jne	composeIt			;  yes, all is kosher
	test	es:[W_grFlags], mask WGF_XFORM_VALID
	jnz	done				; branch if TMatrix valid
composeIt:
	call	GrComposeMatrixFar		; else update the TMatrix
done:
	.leave
	ret
LockWinFromGStateHandle	endp

GraphicsPathRect	ends


		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Fill Path (general) routines #3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPath	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathBuildRegionSlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure a complete region is built from the passed Path

CALLED BY:	INTERNAL
	
PASS:		DS	= GState segment
		SI	= Path chunk handle
		CL	= RegionFillRule

RETURN: 	ES:DI	= RegionFull (ES:0 = RegionPath)
		BX	= RegionPath handle (locked)
		AX	= Region size

DESTROYED:	DX, BP

PSEUDO CODE/STRATEGY:
		Play the GString, stopping at every output element
			For each sub-Path
				Possibly close an earlier element
				Add the element to the RegionPath
				Repeat until end of sub-Path
			Clean the RegionPath
			Combine it with the current RegionPpath
		Loop until done

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		A path is made up of sub-Paths, which are combined together
		using the user-specified rule (replace, and, or).

		A sub-Path is comprised of many graphic elements, not all
		of which are closed geometrically. For many reasons
		(compatability with the existing RegionPath code & Postscript),
		it is easiest to ensure that all elements in a subPath are
		closed. For example:
			* rectangles & ellipses are closed
			* a series of several lines may be closed (only if
				GrLineTo is used after the first line)
			* a single line is not closed

		We will close all elements by keeping track of the current
		position, and adding an imaginary GR_LINE_TO everywhere an
		un-closed graphic elements remains.

		Note that the RegionFillRule will be overridden if a
		sub-Path indicates that its RegionFillRule (BPF_FILL_RULE)
		is valid (BPF_FILL_RULE_VALID is set). This should only
		be true when creating Regions that are part of a clip Path.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathBuildRegionSlow	proc	far
	uses	cx
	.enter

	; Let's build a RegionPath
	;
	call	PathStoreState			; save GState state
	mov	bp, ds:[si]			; Path => DS:BP
	mov	dx, ds:[bp].P_slowRegion	; RegionPath handle => DX
	andnf	ds:[bp].P_flags, not (mask PSF_FILL_RULE)
	or	{byte} ds:[bp+1].P_flags, cl	; store RegionFillRule
	push	si				; save the Path chunk handle
	call	PathLoadGString			; memory => BX, GString => SI
	push	bx				; save this block handle
	clr	bx				; no previous RegionPath

	; Else create a new RegionPath
newRegion:
	push	si				; save the GString handle
	call	GrDerefPtrGString		; OpBeginPath => DS:SI
	mov	al, ds:[si].OBP_flags
EC <	test	al, not (mask BeginPathFlags)	; check for bad record	>
EC <	ERROR_NZ	GRAPHICS_PATH_ILLEGAL_BEGIN_PATH_FLAGS		>
	mov	ah, al
	test	al, mask BPF_FILL_RULE_VALID
	jz	haveFillRule
	and	al, mask BPF_FILL_RULE		; clear all other bits
	mov	cl, offset BPF_FILL_RULE
	shr	al, cl
	mov	cl, al
haveFillRule:
	pop	si				; restore GString handle => SI
	push	cx				; save the RegionFillRule
	push	bx				; save the old RegionPath hand
	push	di				; save the GState handle
	mov	bx, dx				; save old handle
	call	GetWinTopBottom			; bp=top, dx=bottom
	mov	di, bx				; old handle to use (maybe)
	mov	ch, MIN_REGION_POINTS		; default on/off points/line
	call	GrRegionPathInit		; ES => RegionSegment
	pop	di				; restore the GState handle

	; Store the type of combination to perform (look in GR_COMMENT field)
	;
	mov	bl, ah				; BeginPathFlags => BL
	and	ah, mask BPF_COMBINE		; PathCombineType => AH
	cmp	ah, PCT_UNION
	mov	ax, mask ROF_OR_OP
	je	storeCombine
	mov	ax, mask ROF_AND_OP
storeCombine:
	push	ax	

	; Play the GString, stopping at each output element so we can
	; build the appropriate region. If we have page coordinates, then
	; we set the GState's transformation matrix to NULL
	;
	test	bl, mask BPF_COORD_TYPE		; check the coordinate type
	jz	playGString			; if DOCUMENT, just play GString
	call	PathSetNullTransform		; if PAGE, then ignore GState
playGString:
	clr	ax, bx				; initialize starting position
	call	GrMoveTo			; move to starting position
	mov	cx, CLOSED_GRAPHIC_OPCODE	; initialize path element pos
	jmp	skipElement			; skip GR_BEGIN_PATH

	; Stop for each output & path element, building the region
playElement:
	call	FillGraphicsOpcode		; add operation to the Path
skipElement:
	mov	al, GSSPT_SKIP_1
	call	GrSetGStringPos			; now skip over the element
nextElement:
	push	cx, dx				; save start of the sub-path
	mov	dx, (mask GSC_OUTPUT) or (mask GSC_PATH) 
	call	GrDrawGStringAtCP		; play until output element
	mov_tr	ax, cx				; GString element => AL
	cmp	dx, GSRT_PATH
	pop	cx, dx				; restore start of sub-path
	jne	playElement			; if not path opcode, do elem
	cmp	al, GR_CLOSE_SUB_PATH		; check for closure
	je	doneSub
	cmp	al, GR_END_PATH			; other closure element
	jne	skipElement			;  else skip other path stuff
doneSub:
	call	FillCompleteElement		; complete the last element
	cmp	al, GR_END_PATH
	jne	nextElement

	; Merge two PathRegions together
	;
	call	GrRegionPathClean		; clean the RegionPath
	call	RegionReAlloc			; resize the Region downward
	pop	ax				; RegionOpFlags => AX
	pop	bx				; original RegionPath => BX
	call	MergeRegions			; bring them together
	mov	al, GSSPT_SKIP_1		; bump curPos
	call	GrSetGStringPos			; bump over GR_END_PATH
	clr	cx				; don't really want to read any
	call	GrGetGStringElement
	cmp	al, GR_END_GSTRING		; are we done ??
	pop	cx
	je	done				; yes, so get out of here
	call	MemUnlock			; else unlock the newest Region
	jmp	newRegion			; and loop again

	; Ok - we're done. Clean up and exit
done:
	pop	bx				; restore block handle for Path
	call	PathDestroyGString		; destroy GString & temp memory	
	mov	bx, dx				; save RegionPath handle
	tst	bx				; any old RegionPath ??
	jz	cleanUp				; no, so do nothing
	call	MemFree				; else free old RegionPath
cleanUp:
	mov	bx, di				; GState handle => BX
	call	MemDerefDS			; GState segment => DS
	pop	si				; Path chunk => SI
	call	PathRestoreState		; restore GState state
	mov	bx, es:[RP_handle]		; RegionPath handle => BX
	call	GetWinTopBottomAndMatrixSum	; special routine for path code
	mov	di, bp				; ax = top
	mov	bp, ds:[si]			; Path => DS:BP
	mov	ds:[bp].P_top, di		; store top and bottom
	mov	ds:[bp].P_bottom, dx
	movwwf	ds:[bp].P_matrix, cxax		; save matrix sum
	mov	ds:[bp].P_slowRegion, bx	; store the handle
	or	ds:[bp].P_flags, mask PSF_REGION_VALID
	mov	ax, es:[RP_size]
	sub	ax, (size RegionPath)		; Region size => AX
	mov	di, offset RP_bounds		; RegionFull => ES:DI

	.leave
	ret
PathBuildRegionSlow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GStringElement table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; A listing of all the opcodes that output data, and hence
; must be able to create a region for our Path. Note that
; none of the filled operands are present, as we changed
; those to non-fileld representations when the Path
; (GString) was created.
;
opcodeRegionTable	label	word
	word	offset FillPathLine 		; GR_DRAW_LINE
	word	offset FillPathLineTo 		; GR_DRAW_LINE_TO
	word	offset FillPathRelLineTo	; GR_DRAW_REL_LINE_TO
	word	offset FillPathHLine 		; GR_DRAW_HLINE
	word	offset FillPathHLineTo 		; GR_DRAW_HLINE_TO
	word	offset FillPathVLine 		; GR_DRAW_VLINE
	word	offset FillPathVLineTo 		; GR_DRAW_VLINE_TO
	word	offset FillPathPolyline		; GR_DRAW_POLYLINE
	word	offset FillPathArc		; GR_DRAW_ARC
	word	offset FillPathArc3Point	; GR_DRAW_ARC_3POINT
	word	offset FillPathArc3PointTo 	; GR_DRAW_ARC_3POINT_TO
	word	offset FillPathRelArc3PointTo	; GR_DRAW_REL_ARC_3POINT_TO
	word	offset FillPathRect 		; GR_DRAW_RECT
	word	offset FillPathRectTo 		; GR_DRAW_RECT_TO
	word	offset FillPathRoundRect	; GR_DRAW_ROUND_RECT
	word	offset FillPathRoundRectTo 	; GR_DRAW_ROUND_RECT_TO
	word	offset FillPathSpline		; GR_DRAW_SPLINE
	word	offset FillPathSplineTo		; GR_DRAW_SPLINE_TO
	word	offset FillPathCurve		; GR_DRAW_CURVE
	word	offset FillPathCurveTo		; GR_DRAW_CURVE_TO
	word	offset FillPathRelCurveTo	; GR_DRAW_REL_CURVE_TO
	word	offset FillPathEllipse		; GR_DRAW_ELLIPSE
	word	offset FillPathPolygon		; GR_DRAW_POLYGON
	word	offset FillPathPoint 		; GR_DRAW_POINT
	word	offset FillPathPointAtCP	; GR_DRAW_POINT_CP
	word	offset FillPathPolyline		; GR_BRUSH_POLYLINE
	word	offset FillPathChar 		; GR_DRAW_CHAR
	word	offset FillPathCharAtCP		; GR_DRAW_CHAR_CP
	word	offset FillPathText 		; GR_DRAW_TEXT
	word	offset FillPathTextAtCP		; GR_DRAW_TEXT_CP
	word	offset FillPathTextField	; GR_DRAW_TEXT_FIELD
	word	offset FillPathTextPtr		; GR_DRAW_TEXT_PTR


; A listing of all opcodes that do not begin new graphics path elements
; (i.e. they don't pick up the pen and move it around)
;
opCodeOpen	GStringElement \
	GR_DRAW_LINE_TO,
	GR_DRAW_REL_LINE_TO,
	GR_DRAW_RECT_TO,
	GR_DRAW_HLINE_TO,
	GR_DRAW_VLINE_TO,
	GR_DRAW_ARC_3POINT_TO,
	GR_DRAW_REL_ARC_3POINT_TO,
	GR_DRAW_ROUND_RECT_TO,
	GR_DRAW_SPLINE_TO,
	GR_DRAW_CURVE_TO,
	GR_DRAW_REL_CURVE_TO,
	GR_DRAW_POINT_CP

NUM_OP_CODE_OPEN_ELEMENTS	= $ - opCodeOpen


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillGraphicsOpcode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the next graphic operation (based upon the opcode),
		ensuring that any open path elements are closed if we are
		picking up the pen and moving it.

CALLED BY:	PathBuildRegionSlow

PASS:		SI	= GString handle
		ES	= Region segment
		CX	= X position at end of Path element
		DX	= Y position at end of Path element
		DI	= GState handle

RETURN:		CX	= X position (updated)
		DX	= Y position (updated)		
		ES	= Region segment (updated)

DESTROYED:	AX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CLOSED_GRAPHIC_OPCODE	= 0x8100		; indicates not to close figure

FillGraphicsOpcode	proc	near
	uses	bx, si
	.enter
	
	; Check to see if we need to close the last path element
	;
	push	cx, di, es
	call	GrDerefPtrGString		; ds:si -> Graphics string
	mov	al, ds:[si]			; get opcode
	segmov	es, cs
	mov	di, offset opCodeOpen
	mov	cx, NUM_OP_CODE_OPEN_ELEMENTS
	repne	scasb				; find first match
	pop	cx, di, es
	pushf					; save these flags
	jz	doOpcode			; if no match, do nothing
	call	FillCompleteElement		; complete the last element

	; Now perform the proper graphics opcode
doOpcode:
	push	es
	call	LockWinFromGStateHandle		; Window handle => BX
	pop	es				; restore Region segment
	push	cx, dx				; save start of path element
	push	bx				; save the Window handle
	mov	bl, al				; move opcode to BL
	clr	bh
	sub	bl, GSE_FIRST_OUTPUT_OPCODE	; first output element => 0
EC <	cmp	bl, (GSE_LAST_OUTPUT_IN_PATH - GSE_FIRST_OUTPUT_OPCODE)	>
EC <	ERROR_A	GRAPHICS_PATH_BUILD_REGION_ILLEGAL_OPCODE		>
	shl	bx, 1				; offset by words
	call	cs:[opcodeRegionTable][bx]	; call the appropriate routine
	pop	bx				; Window handle => BX
	tst	bx				; check for NULL Window
	jz	doneOpcode
	call	MemUnlockV			; unlock & Release Window
doneOpcode:
	pop	ax, bx				; restore old start of element

	; Now store the current position in the RegionPath
	;
	popf
	jnz	done				; if a new element, done
	xchg	cx, ax				; else move new start => (CX,DX)
	mov	dx, bx
done:
	.leave
	ret
FillGraphicsOpcode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillCompleteElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the last graphic element, if it was open

CALLED BY:	INTERNAL

PASS: 		ES	= Region segment
		CX	= X position at end of Path element
		DX	= Y position at end of Path element

RETURN:		ES	= Region segment (updated)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillCompleteElement	proc	near
	.enter
	
	cmp	cx, CLOSED_GRAPHIC_OPCODE	; open path element remaining ??
	je	done				; no, so do nothing
	call	GrRegionPathAddLineAtCP		; else close last path element
	mov	cx, CLOSED_GRAPHIC_OPCODE	; mark last element as closed
done:
	.leave
	ret
FillCompleteElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeRegions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Merge two RegionPaths together, using the passed operation

CALLED BY:	PathBuildRegionSlow, GrGetClipRegion
	
PASS:		ES	= Segment of current RegionPath (#2) (locked)
		BX	= Handle of original RegionPath (#1) (unlocked)
		AX	= RegionOpFlags

RETURN: 	ES	= Segment of resulting RegionPath (#3) (locked)
		BX	= Handle of resulting RegionPath  (#3)
		DX	= Handle of RegionPath to re-use (#1) (unlocked)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Currently does not abort if insufficient memory - the
		system will just die

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MergeRegions	proc	near
	uses	ax, cx, di, si, ds
	.enter

	; See if we need to do any work at all
	;
	tst	bx				; any original RegionPath ??
EC <	LONG	jz	done			; nope - so do nothing	>
NEC <	jz	done				; nope - so do nothing	>
	
	; Re-allocate the current Region to hold enough room for the
	; resulting Region.
	;
	xchg	bp, ax				; RegionOpFlags => BP
	push	bx				; save RegionPath #1 handle
	call	MemLock				; RegionPath segment => DS
	mov	ds, ax
	mov	ax, ds:[RP_endPtr]		; size #1 => AX
	add	ax, es:[RP_endPtr]		; add in size of #2 => AX
	mov	dx, ax
	shr	ax, 1
	add	ax, dx				; 1.5 times size => AX
	add	ax, 14				; mystery value from GrPtrRegOp
resize:
	mov	bx, es:[LMBH_handle]		; block handle => BX
	push	ax				; store this size
	add	ax, es:[RP_endPtr]		; add in size of Region #2
	mov	ch, mask HAF_NO_ERR		; HeapAllocFlags => CH
	call	MemReAlloc			; reallocate the block
	mov	es, ax				; this is OK, as block is locked

	; Now combine the Regions
	;
	mov	si, size (RegionPath)		; DS:SI => Region #1
	mov	bx, si				; ES:BX => Region #2		
	mov	di, es:[RP_endPtr]		; ES:DI => Region #3
	pop	cx				; size for Region #3 => CX
	mov	ax, bp				; RegionOpFlags => AX
	call	GrPtrRegOp			; combine them regions
	mov	ax, cx				; size of Region => AX
	jc	resize

	; Copy the result to the front of the Block
	;
	xchg	di, ax				; size of Region => DI
	add	di, (size RegionPath)		; total size => DI
	xchg	es:[RP_endPtr], di		; start of RegionPath #3 => DI
	mov	si, (size RegionPath)
	segmov	ds, es
	xchg	di, si				; source => DS:SI, dest => ES:DI
	shr	cx, 1
EC <	ERROR_C	GRAPHICS_REGION_ODD_SIZE	; for odd-sized regions	>
	rep	movsw
	call	RegionReAlloc			; reallocate RegionPath down
	mov	si, (size RegionPath)		; DS:SI points to Region
	call	GrGetPtrRegBounds
	mov	ds:[RP_bounds].R_left, ax	
	mov	ds:[RP_bounds].R_top, bx
	mov	ds:[RP_bounds].R_right, cx	
	mov	ds:[RP_bounds].R_bottom, dx	
	pop	bx
	call	MemUnlock			; unlock old RegionPath
done:	
	mov	dx, bx				; handle to re-use => DX
	mov	bx, es:[RP_handle]

	.leave
	ret
MergeRegions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegionReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-allocates a RegionPath down to the size of its data

CALLED BY:	INTERNAL
	
PASS:		ES	= Segment of RegionPath

RETURN:		BX	= Handle of RegionPath

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RegionReAlloc	proc	near
	uses	cx
	.enter

	mov	bx, es:[RP_handle]		; RegionPath handle => BX
	mov	ax, es:[RP_endPtr]
	mov	es:[RP_size], ax
	clr	ch				; no HeapAllocFlags
	call	MemReAlloc			; downsize block to actual data
	mov	es, ax				; update segment in ES

	.leave
	ret
RegionReAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathLine 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawLine in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathLine 	proc	near

	; Grab the points, and add the line to the Region
	;
	mov	ax, ds:[si].ODL_x1
	mov	bx, ds:[si].ODL_y1
	mov	cx, ds:[si].ODL_x2
	mov	dx, ds:[si].ODL_y2
	add	si, size OpDrawLine		; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathLine 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Added the line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawLineTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathLineTo	proc	near

	; Grab the points, and add the line to the Region
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	cx, ds:[si].ODLT_x2
	mov	dx, ds:[si].ODLT_y2
	add	si, size OpDrawLineTo		; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRelLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Added the line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRelLineTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathRelLineTo	proc	near
	call	LoadPenPosAXBXCXDX
	push	ax, bx				; save starting position
	call	GrGetCurPosWWFixed		; position => (DX.CX, BX.AX)
	addwwf	dxcx, ds:[si].ODRLT_x2
	rndwwf	dxcx				; end X => DX
	addwwf	bxax, ds:[si].ODRLT_y2
	rndwwf	bxax				; end Y => BX
	mov	cx, dx
	mov	dx, bx				; ending point => (CX, DX)
	pop	ax, bx				; starting point => (AX, BX)
	add	si, size OpDrawRelLineTo	; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathRelLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a rectangle to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRect in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathRect	proc	near

	; Get the rectangle bounds, and then do the real work
	;
	mov	ax, ds:[si].ODR_x1
	mov	bx, ds:[si].ODR_y1
	mov	cx, ds:[si].ODR_x2
	mov	dx, ds:[si].ODR_y2
	add	si, size OpDrawRect		; DS:SI points to next element
	GOTO	doRect
FillPathRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRectTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a rectangle to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRectTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathRectTo	proc	near

	; Grab the coordinates of the rectangle
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	cx, ds:[si].ODRT_x2
	mov	dx, ds:[si].ODRT_y2
	add	si, size OpDrawRectTo		; DS:SI points to next element

	; Now load the points onto the stack
	;
doRect	label	near
	call	StorePenPos			; write the new pen position
	push	ds, di				; save registers
	push	dx, ax, dx, cx			; push lower left, lower right
	push	bx, cx, bx, ax			; push upper right, upper left
	mov	cx, 4				; loop four times
	mov	dx, bp				; conversion routine => DX
	mov	bp, sp				; SS:BP points at the points

	; Loop through the points, applying a transformation to each
	;
pointLoop:
	mov	ax, ss:[bp].P_x			; get original point
	mov	bx, ss:[bp].P_y
	call	PathTransCoord			; new point => (AX, BX)
	mov	ss:[bp].P_x, ax
	mov	ss:[bp].P_y, bx
	add	bp, size Point
	loop	pointLoop			; loop while more points

	; Add the rotated rectangle as a polygon:
	;
	segmov	ds, ss
	mov	di, sp				; points => DS:DI
	mov	cx, 4				; number of points => CX
	call	GrRegionPathAddPolygon		; add polygon to Region

	; Clean up
	;
	mov	cx, CLOSED_GRAPHIC_OPCODE	; indicates not to close figure
	add	sp, (size Point) * 4		; nuke bounds from stack
	pop	ds, di				; restore registers
	ret
FillPathRectTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathHLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a horizontal line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawHLine in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathHLine	proc	near

	; Grab the points, and add the line to the region
	;
	mov	ax, ds:[si].ODHL_x1
	mov	bx, ds:[si].ODHL_y1
	mov	cx, ds:[si].ODHL_x2
	mov	dx, bx
	add	si, size OpDrawHLine		; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathHLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathHLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a horizontal line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawHLineTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathHLineTo	proc	near

	; Grab the points, and add the line to the region
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	cx, ds:[si].ODHLT_x2
	add	si, size OpDrawHLineTo		; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathHLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathVLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a vertical line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawVLine in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathVLine	proc	near

	; Grab the points, and add the line to the region
	;
	mov	ax, ds:[si].ODVL_x1
	mov	bx, ds:[si].ODVL_y1
	mov	cx, ax
	mov	dx, ds:[si].ODVL_y2
	add	si, size OpDrawVLine		; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathVLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathVLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the vertical line to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawVLineTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathVLineTo	proc	near

	; Grab the points, and add the line to the region
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	dx, ds:[si].ODVLT_y2
	add	si, size OpDrawVLineTo		; DS:SI points to next element
	GOTO	FillPathLowLine
FillPathVLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a rounded rectangle to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRoundRect in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathRoundRect	proc	near

	; First get the data from the GString
	;
	mov	ax, ds:[si].ODRR_x1
	mov	bx, ds:[si].ODRR_y1
	mov	bp, ds:[si].ODRR_radius
	add	si, (size OpDrawRoundRect) - (size OpDrawRoundRectTo)
	jmp	drawRRCommon			; do the rounded-rectangle stuff
FillPathRoundRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRoundRectTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a rounded rectangle-to to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRoundRectTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <((size OpDrawRoundRect)   - (offset ODRR_x2)) eq \
	   ((size OpDrawRoundRectTo) - (offset ODRRT_x2))>

FillPathRoundRectTo proc	near
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	bp, ds:[si].ODRRT_radius
drawRRCommon	label	near
	call	StorePenPos			; write the new pen position
	push	di, si				; save data, GString pointer
	mov	cx, ds:[si].ODRRT_x2
	mov	dx, ds:[si].ODRRT_y2		
	mov	si, bp				; radius => SI

	; Now get the points along the rounded rectangle, and add them to
	; the region
	;
	push	ds, es				; save segment registers
	call	LoadDSESGStateWindow		; load segment registers
	call	PrepRoundRectLowFar		; Point buffer & count => BX, CX
	pop	es				; restore RegionPath segment

	; Now finally draw all of these Points
	;
	mov	bp, ACT_CHORD			; fake ArcCloseType => BP
	call	AddArcEllipsePointsLow		; add points to region
	pop	di, si, ds			; restore GSring pointer
	add	si, size OpDrawRoundRectTo	; DS:SI points to next element
	ret
FillPathRoundRectTo endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a point to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawPoint in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathPoint	proc	near

	; Grab the point, add it to the region
	;
	mov	cx, ds:[si].ODP_x1
	mov	dx, ds:[si].ODP_y1
	add	si, size OpDrawPoint		; DS:SI points to next element
	jmp	doPoint
FillPathPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathPointAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a point to the Region being build

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawPointAtCP in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathPointAtCP	proc	near
	; Grab the point, add it to the region
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	add	si, size OpDrawPointAtCP	; DS:SI points to next element
doPoint	label	near
	mov	ax, cx
	mov	bx, dx
	call	StorePenPos
	call	GrRegionPathAddOnOffPoint	; add the point to the region
	ret
FillPathPointAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a character to the Path being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawChar in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathChar	proc	near

	; Grab the position, and then do the common work
	;
	mov	ax, ds:[si].ODC_x1
	mov	bx, ds:[si].ODC_y1
	mov	bp, si
	add	bp, offset ODC_char		; text => DS:BP
	add	si, size OpDrawChar		; next GString element => DS:SI
	jmp	doChar	
FillPathChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathCharAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a character to the Path being built

CALLED BY:	BuildFromPath
	
PASS:		DS:SI	= OpDrawCharAtCP in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathCharAtCP	proc	near

	; Grab the current position, and then do the real work
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	bp, si
	CheckHack <(offset ODCCP_char) eq 1>
	inc	bp				; text => DS:BP
	add	si, size OpDrawCharAtCP

	; Now do the real work for adding a character to a path
	; Assume DS:SI+1 = Character to be drawn
doChar	label	near
	xchg	bp, si				; character => DS:SI
	mov	cx, 1				; we have one character
	call	FillPathLowText		; add the text to the region
	mov	si, bp				; next GString element => DS:SI
	ret
FillPathCharAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a string of characters to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawText in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathText	proc	near

	; Find the position of the text, and jump to do the real work
	;
	mov	ax, ds:[si].ODT_x1
	mov	bx, ds:[si].ODT_y1
	mov	cx, ds:[si].ODT_len
	add	si, size OpDrawText		; DS:SI points to next element
	jmp	doText
FillPathText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathTextAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a string of characters to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawTextAtCP in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathTextAtCP	proc	near

	; Grab the current position, and then do the real work
	;
	call	LoadPenPosAXBXCXDX		; GS_penPos to (AX,BX) & (CX,DX)
	mov	cx, ds:[si].ODTCP_len
	add	si, size OpDrawTextAtCP		; DS:SI points to next element

	; Now do the real work for adding a character string to a path
doText	label	near
	call	FillPathLowText		; add the text to the region
	ret
FillPathTextAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a text field to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawTextField in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathTextField	proc	near
		
		; allocate some breathing room, and copy over the saved params

		sub	sp, size GDF_vars		
		mov	bp, sp				; ss:bp -> GDF_vars
		push	es				; save retion ptr
		mov	ax, di				; ax = GState han
		segmov	es, ss, di
		mov	di, bp				; es:di -> GDF_vars
		add	di, offset GDFV_saved		; 
		add	si, offset ODTF_saved		; ds:si -> GDF_saved
		mov	cx, size GDF_saved
		rep	movsb				; move parameters
		mov	di, ax				; restore GState han
		pop	es				; restore region ptr

		; setup the callback address, and save an address of our own

		movdw	ss:[bp].GDFV_other, dssi	; set ptr to 1st run

		; Setup for eventual call to TextCallDriver()

		xchg	bx, di
		call	MemDerefDS		; GState => DS
		xchg	bx, di			; restore di=GState handle
		mov	bx, es:[RP_handle]
		mov	ds:[GS_pathData], bx	; store RegionPath handle
		or	ds:[GS_pathFlags], mask PF_FILL
		mov	bx, ds:[GS_window]
		tst	bx			; must have Window	
		jz	haveWindow		; skip if not there...
		call	MemDerefES		; Window => ES

		; everything is set.  do it.
haveWindow:
		call	PathDrawTextField		; special version for
							;  path code
		xchg	bx, di				; bx = GState handle
		call	MemDerefDS			; ds -> GState
		and	ds:[GS_pathFlags], not (mask PF_FILL)
		xchg	bx, di
		mov	bx, ds:[GS_pathData]
		call	MemDerefES		; RegionPath segment => ES
		mov	cx, CLOSED_GRAPHIC_OPCODE
		movdw	dssi, ss:[bp].GDFV_other	; ends up pointing to
							;  next element
		add	sp, size GDF_vars		; backup stack

		ret
FillPathTextField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathDrawTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Simulate GrDrawTextField, assuming that GState and Window
		are already locked.

CALLED BY:	INTERNAL
		FillPathTextField
PASS:		same as GrDrawTextField
RETURN:		same as GrDrawTextField
DESTROYED:	ds

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathDrawTextField	proc	near
		uses	ax,bx,cx,dx,si,di,es
		.enter

		; load up #chars to draw
	
		mov	bx, ss:[bp].GDFV_saved.GDFS_nChars
		clr	si				; start at beginning

		; Call the callback routine to find out how many chars 
		; there are in this style.
		;
		; ss:bp = GDF_vars structure
		; ds	= segment address of the gstate
		; di	= GState handle
		; bx	= Number of characters in the field
		; si	= Offset into the field
drawLoop:
		tst	bx				; Check for no chars
		jle	done				; Branch if none left

		call	PathSetupGState			; Set up gstate
							; ds:si <- ptr to text
							; cx <- #chars in run

		; Use the minimum of the length of the run and the number 
		; of characters to draw.

		cmp	cx, bx				; cx <- #chars to draw
		jbe	gotNChars
		mov	cx, bx

gotNChars:
		sub	bx, cx				; bx <- # left 

		; Load up the coordinates to draw at.

		push	bx, cx, di, si, bp		; Save lots of stuff
		movwbf	bxdh, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_y
		addwbf	bxdh, ss:[bp].GDFV_saved.GDFS_baseline

		movwbf	axdl, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_x

		mov	di, ss:[bp].GDFV_saved.GDFS_limit

						; bp:si <- ptr to string
		mov	si, ss:[bp].GDFV_textPointer.offset
		mov	bp, ss:[bp].GDFV_textPointer.segment

		; ds	= Segment address of gstate
		; es	= Segment address of window
		; ax.dl	= X coordinate (WBFixed, document coordinate)
		; bx.dh	= Y coordinate (WBFixed, document coordinate)
		; bp:si	= Pointer to the text
		; cx	= Number of characters to draw
		; di	= Limit

		call	SetDocWBFPenPosFar		; set pen position
		call	TextCallDriverFar		; Draw the piece
						; cx, di, si, bp Destroyed
		pop	bx, cx, di, si, bp		; Restore lots of stuff
	
		; ax.dl	= X coordinate for next character
		;
		; Save the new X position

		movwbf	ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_x, axdl

		; cx	= Number of characters drawn
		; bx	= Number of characters left after this draw

		add	si, cx				; si <- field offset
		jmp	drawLoop			; Loop to do more

		; if there is an auto-hyphen, draw it now
done:
		test	ss:[bp].GDFV_saved.GDFS_flags, mask HF_AUTO_HYPHEN
		jz	noAutoHyphen
	
		push	ax,bx,cx,dx,si,di,bp	; save a bunch of stuff
		mov	cx, 1			; draw 1 char
SBCS <		mov	al, C_HYPHEN		; set up bp:si -> hyphen char>
DBCS <		mov	al, C_HYPHEN_MINUS	; set up bp:si -> hyphen char>
		clr	ah
		push	ax			; param 
		mov	si, sp

		; setup rest of params to TextCallDriver

		movwbf	bxdh, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_y
		addwbf	bxdh, ss:[bp].GDFV_saved.GDFS_baseline

		movwbf	axdl, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_x

		mov	di, ss:[bp].GDFV_saved.GDFS_limit

		mov	bp, ss
		call	TextCallDriverFar
		pop	ax			; pop parameter
		pop	ax,bx,cx,dx,si,di,bp	; restore bunch of stuff

noAutoHyphen:
		.leave
		ret
PathDrawTextField	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathSetupGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the gstate for drawing.

CALLED BY:	GrDrawTextField
PASS:		ds	= Segment address of the gstate
		es	= Segment address of window
		di	= GState handle
		si	= Offset into the field
		ss:bp	= GDF_vars
RETURN:		GState set up for drawing
		cx	= Number of characters in this run
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathSetupGState	proc	near
	uses	ax, bx, di, si, ds
	.enter
	;
	; Allocate a stack frame and call the style-callback to fill in the
	; various character attributes. Also locks the text and returns
	; a pointer to the current position.
	;
	mov	ax, di				; ax <- gstate handle

	sub	sp, size TextAttr		; allocate some space
	movdw	bxdi, sssp			; bx:di -> TextAttr structure
	
	push	es, ax				; Save window seg, gstate han
	segmov	es, ds, cx			; es <- seg address of gstate

	;
	; Fill in the text attributes
	;
	call	PathTFieldCB			; Fill the TextAttr structure
						; ds:si <- ptr to text
						; cx <- # of chars in this run

	movdw	ss:[bp].GDFV_textPointer, dssi	; Save the address of the text

	;
	; Set up a pointer to the text-attributes and then set everything up
	; in the gstate we're drawing with.
	;
	movdw	dssi, bxdi			; ds:si <- ptr to TextAttr

	;
	; Before we get too happy here we need to set the space-padding in
	; the TextAttr structure.
	;
	; The space-padding to use is the same space-padding that is currently
	; set in the gstate.
	;
	; ds:si	= Pointer to the TextAttr
	; es	= Segment containing the gstate
	; di	= GState handle
	;
	movwbf	ds:[si].TA_spacePad, es:GS_textSpacePad, ax

	pop	es, di				; Restore window seg, gstate han

	call	SetTextAttrInt			; use special version of 
						;  GrSetTextAttr that assumes
						;  window is locked.
	add	sp, size TextAttr		; restore stack
	.leave
	ret
PathSetupGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathTFieldCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for FillPathTextField

CALLED BY:	EXTERNAL
		GrDrawTextField

PASS:		ss:bp	- pointer to GDF_vars struct (see above)
		bx:di	- pointer to buffer to fill with TextAttr
		si	- current offset to the text
RETURN:		cx	- # characters in this run
		ds:si	- Pointer to text

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		stuff style run info for this run into buffer;
		return run length in cx;
		bump nextRunPtr to next run;
		reduce #chars left;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathTFieldCB	proc	far
		uses	es, di, ax
		.enter

		; first fill the TextAttr structre.  The GDFV_other field is
		; already pointing there..

		mov	es, bx			; es:di -> buffer to fill
		movdw	dssi, ss:[bp].GDFV_other ; ds:si -> TFStyleRun
		mov	ax, ds:[si].TFSR_count	; need this later
		add	si, offset TFSR_attr	; ds:si -> TextAttr
		mov	cx, size TextAttr
		rep	movsb
		
		; at this point ds:si -> text string.  Record the position
		; of the next run.

		movdw	ss:[bp].GDFV_textPointer, dssi ; save pointer
		mov	cx, ax			; return string len in cx
		add	si, cx			; calc next pointer
DBCS <		add	si, cx			; char offset -> byte offset>
		movdw	ss:[bp].GDFV_other, dssi ; save next run pointer
		sub	si, cx
DBCS<		sub	si, cx			; char offset -> byte offset>
		
		.leave
		ret
PathTFieldCB	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a string of characters to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawText in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathTextPtr	proc	near
	.enter

	; Find the position of the text, and jump to do the real work
	;
	mov	ax, ds:[si].ODTP_x1
	mov	bx, ds:[si].ODTP_y1
	mov	cx, ds:[si].ODTP_ptr		; chunk handle => CX
	add	si, size OpDrawTextPtr
	push	si				; save end of GString element	
	mov	si, cx
	mov	si, ds:[si]			; text => DS:SI
	ChunkSizePtr	ds, si, cx		; text length => CX
	call	FillPathLowText
	pop	si				; restore end of GString element

	.leave
	ret
FillPathTextPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a polyline (brushed polyline) to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawPolyline in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathPolyline	proc	near
	uses	ds, di
	.enter

	; Transform the points, and add to the RegionPath
	;
	CheckHack <(offset ODPL_count) eq (offset OBPL_count)>
	mov	ax, ds:[si].ODPL_count		; number of points => AX
	mov	bx, size OpBrushPolyline	; opcode structure size => BX
	cmp	ds:[si].ODPL_opcode, GR_BRUSH_POLYLINE
	je	common
	mov	bx, size OpDrawPolyline		; opcode structure size => BX
common:
	add	si, bx				; DS:SI => array of points
	call	CopyPointsToBlock		; point array => DS:DI
	xchg	cx, ax				; number of points=>CX, save AX
	call	GrRegionPathAddPolyline		; add the multiple # of lines
	call	MemFree				; free global block holding pts
	xchg	cx, ax				; final point => (CX, DX)

	.leave
	ret
FillPathPolyline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an ellipse to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawEllipse in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathEllipse	proc	near
	uses	di
	.enter

	; First get the data from the GString
	;
	mov	ax, ds:[si].ODE_x1
	mov	bx, ds:[si].ODE_y1
	mov	cx, ds:[si].ODE_x2
	mov	dx, ds:[si].ODE_y2		
	mov	bp, ACT_CHORD			; fake ArcCloseType => BP

	; Now get the points along the ellipse, and add them to the region
	;
	push	ax, bx				; save start position
	push	di				; push GState handle
	mov	di, offset SetupEllipseLow
	call	AddArcEllipsePoints		; calculate & add points
	pop	ax, bx				; restore GSring pointer
	call	StorePenPos			; write the new pen position
	add	si, size OpDrawEllipse		; DS:SI points to next element

	.leave
	ret
FillPathEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an arc to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawArc in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathArc	proc	near
	uses	di
	.enter

	; First get the data from the GString
	;
	mov	bp, ds:[si].ODA_close		; ArcCloseType => BP
	mov	ax, ds
	inc	si				; ArcParams => AX:SI

	; Now get the points along the arc, and add them to the region
	;
	push	di				; push GState on stack
	mov	di, offset SetupArcLow
	call	AddArcEllipsePoints		; calculate & add Points
	add	si, (size OpDrawArc) - 1	; DS:SI points to next element

	.leave
	ret
FillPathArc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathArc3Point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an arc to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawArc3Point in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathArc3Point	proc	near
	uses	di
	.enter

	; First get the data from the GString
	;
	mov	bp, ds:[si].ODATP_close		; ArcCloseType => BP
	mov	ax, ds
	inc	si				; ThreePointArcParams => AX:SI

	; Now get the points along the arc, and add them to the region
	;
	push	di				; push GState on the stack
	mov	di, offset SetupArc3PointLow
	call	AddArcEllipsePoints		; calculate & add points
	add	si, (size OpDrawArc3Point) - 1	; DS:SI points to next element

	.leave
	ret
FillPathArc3Point	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathArc3PointTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an arc to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawArc3PointTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathArc3PointTo	proc	near
	uses	di
	.enter

	; First get the data from the GString
	;
	mov	bp, ds:[si].ODATPT_close	; ArcCloseType => BP
	mov	ax, ds
	inc	si				; ThreePointArcToParams =>AX:SI

	; Now get the points along the arc, and add them to the region
	;
	push	di				; push GState on the stack
	mov	di, offset SetupArc3PointToLow
	call	AddArcEllipsePoints		; calculate & add points
	add	si, (size OpDrawArc3PointTo) - 1 ; DS:SI points to next element

	.leave
	ret
FillPathArc3PointTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRelArc3PointTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an arc to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRelArc3PointTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathRelArc3PointTo	proc	near
	uses	di
	.enter

	; First get the data from the GString
	;
	mov	bp, ds:[si].ODRATPT_close	; ArcCloseType => BP
	mov	ax, ds
	inc	si				; ThreePointArcToParams =>AX:SI

	; Now get the points along the arc, and add them to the region
	;
	push	di				; push GState on the stack
	mov	di, offset SetupRelArc3PointToLow
	call	AddArcEllipsePoints		; calculate & add points
	add	si, (size OpDrawRelArc3PointTo)-1 ; DS:SI -> to next element

	.leave
	ret
FillPathRelArc3PointTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a spline to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawSpline in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathSpline	proc	near

	; Setup to call common routine
	;
	mov	ax, ds:[si].ODS_count
	mov	bp, ax				; draw from 1st point
	add	si, size OpDrawSpline		; point array => DS:SI
	GOTO	FillPathLowBezier
FillPathSpline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathSplineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a spline to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawSplineTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathSplineTo	proc	near
	
	; Setup to call common routine
	;
	mov	ax, ds:[si].ODST_count
	clr	bp				; draw from current position
	add	si, size OpDrawSplineTo		; point array => DS:SI
	GOTO	FillPathLowBezier
FillPathSplineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a (bezier) curve to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawCurve in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathCurve	proc	near
	
	; Setup to call common routine
	;
	mov	ax, 4				; 4 points
	mov	bp, ax				; draw from 1st point
	add	si, offset ODCV_x1		; point array => DS:SI
	GOTO	FillPathLowBezier
FillPathCurve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a (bezier) curve to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawCurveTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathCurveTo	proc	near
	
	; Setup to call common routine
	;
	mov	ax, 3				; 3 points
	clr	bp				; draw from current position
	add	si, offset ODCVT_x2		; point array => DS:SI
	GOTO	FillPathLowBezier
FillPathCurveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathRelCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a relative (bezier) curve to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawRelCurveTo in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathRelCurveTo	proc	near
	.enter
	
	; Setup to call common routine
	;
	push	ds, si				; save GString opcode
	call	LoadPenPosAXBXCXDX
	add	ax, ds:[si].ODRCVT_x4
	add	bx, ds:[si].ODRCVT_y4
	push	bx, ax				; push point #4
	movdw	bxax, dxcx
	add	ax, ds:[si].ODRCVT_x3
	add	bx, ds:[si].ODRCVT_y3
	push	bx, ax				; push point #3
	add	cx, ds:[si].ODRCVT_x2
	add	dx, ds:[si].ODRCVT_y2
	push	dx, cx				; push point #2
	movdw	bxax, dxcx
	segmov	ds, ss
	mov	si, sp				; point array => DS:SI
	mov	ax, 3				; 3 points
	clr	bp				; draw from current position
	call	FillPathLowBezier
	add	sp, 3 * (size Point)		; clean up the stack
	pop	ds, si				; GString opcode => DS:SI
	add	si, (size OpDrawRelCurveTo)

	.leave
	ret
FillPathRelCurveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a polygon to the Region being built

CALLED BY:	FillGraphicsOpcode
	
PASS:		DS:SI	= OpDrawPolygon in GString
		ES	= Region segment
		DI	= GState handle

RETURN:		DS:SI	= Next element in GString
		ES	= Updated Region segment
		(CX,DX)	= Start of this graphic element

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathPolygon	proc	near
	uses	ds, di
	.enter

	; Transform the points, and add to the RegionPath
	;
	mov	ax, ds:[si].ODPG_count		; number of points => AX
	add	si, size OpDrawPolygon		; DS:SI => array of points
	call	CopyPointsToBlock		; point array => DS:DI
	xchg	cx, ax				; number of points => CX
	call	GrRegionPathAddPolygon		; add the multiple # of lines
	call	MemFree				; free global block holding pts
	mov	cx, CLOSED_GRAPHIC_OPCODE	; we drew a closed figure

	.leave
	ret
FillPathPolygon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPenPosAXBXCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the pen position into (AX, BX) & (CX, DX)

CALLED BY:	INTERNAL

PASS:		DI	= GState handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadPenPosAXBXCXDX	proc	near
	uses	ds
	.enter
	
	mov	bx, di				; GState handle => BX
	call	MemDerefDS
	call	GetDocPenPos			; ax,bx = pen pos
	mov	cx, ax
	mov	dx, bx

	.leave
	ret
LoadPenPosAXBXCXDX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StorePenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the new pen position

CALLED BY:	INTERNAL

PASS:		DI	= GState handle (locked)
		(AX,BX)	= New pen position

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StorePenPos	proc	near
	uses	ds
	.enter
	
	; Update the pen position stored in the GState
	;
	xchg	bx, di				; swap y, GState
	call	MemDerefDS
	xchg	bx, di				; restore y, GState
	call	SetDocPenPos

	.leave
	ret
StorePenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadDSESGStateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the segment registers with the GState & Window segments

CALLED BY:	INTERNAL

PASS:		DI	= GState handle (locked)

RETURN:		DS	= GState segment
		if there is a window associated with the GState, then
			ES	= Window segment
		else
			ES 	does not change

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assume the Window handle is already locked & owned

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/13/91	Initial version
	jim	12/92		No longer dies if no window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadDSESGStateWindow	proc	near
	.enter
	
	xchg	bx, di				; GState => BX, data => DI
	call	MemDerefDS			; GState segment => DS
	mov	bx, ds:[GS_window]		; Window handle => BX	
	tst	bx				; must have Window
	jz	haveWindow
	call	MemDerefES			; Window segment => ES
haveWindow:
	mov	bx, di				; restore data => BX

	.leave
	ret
LoadDSESGStateWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathLowLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line to a Region, with the passed coordinates

CALLED BY:	FillGraphicsOpcode

PASS:		ES	= Region segment
		DI	= GState handle
		BP	= Coordinate conversion routine
		(AX,BX)	= Start point of line
		(CX,DX)	= End point of line

RETURN:		ES	= Region segment (updated)
		(CX,DX)	= Start of this graphic element

DESTROYED:	CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathLowLine	proc	near
	.enter
	
	; Transform the line coordinates
	;
	call	PathTransCoord			; convert start of line
	xchg	ax, cx
	xchg	bx, dx
	call	StorePenPos			; update the pen position
	call	PathTransCoord			; convert end of line

	; Now add the line to the Region
	;
	call	GrRegionPathMovePen		; move pen to start of line
	xchg	ax, cx
	xchg	bx, dx
	call	GrRegionPathAddLineAtCP		; add the line
	xchg	cx, ax
	mov	dx, bx				; start of line => (CX,DX)

	.leave
	ret
FillPathLowLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathLowBezier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add one or move bezier curves to the Region being built

CALLED BY:	INTERNAL

PASS:		DS:SI	= Point array
		ES	= RegionPath segment
		DI	= GState		
		AX	= # of points
		BP	= 0 - draw from current position
			!=0 - draw from 1st point

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathLowBezier	proc	near
	uses	di, ds
	.enter

	; Transform the points, and go the the 1st point
	;
	call	CopyPointsToBlock		; transformed points => DS:DI
	tst	bp
	jz	doCurves
	call	GrRegionPathMovePen		; move penPos to first point
	add	di, size Point			; go to 2nd point pair
	dec	ax				; decrement point count

	; Now draw a series of bezier curves
doCurves:
	push	cx				; save starting position
	mov	cx, REC_BEZIER_STACK		; buffer size => CX
	clr	bp				; pass buffer size to allocate
nextCurve:
	call	GrRegionPathAddBezierAtCP	; add the bezier curve
	add	di, size RegionBezier
	sub	ax, 3
EC <	ERROR_L	GRAPHICS_SPLINE_ILLEGAL_NUMBER_OF_POINTS		>
	jnz	nextCurve			; if more points, go again

	; Clean up
	;
	call	MemFree				; free global block holding pts
	pop	cx				; first point => (CX, DX)

	.leave
	ret
FillPathLowBezier	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyPointsToBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies an array of points into a temporary buffer, using
		a global memory block. The points are transformed as they
		are copied

CALLED BY:	INTERNAL

PASS:		DS:SI	= Array of points
		DI	= GState
		AX	= Number of points

RETURN:		DS:DI	= Buffer holding array of points
		SI	= Points to end of original array
		BX	= Memory handle
		(CX,DX)	= First point in the array

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyPointsToBlock	proc	near
	uses	ax, bp, es
	.enter
	
	; First allocate a block of the proper size
	;
	mov	dx, ax				; # of points => DX
	shl	ax, 1
	shl	ax, 1				; each point is four bytes long
	mov	cx, (mask HF_SWAPABLE) or \
		    ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8)
	call	MemAllocFar
	mov	es, ax
	push	bx				; save the handle
	
	; Copy them points over, while transforming
	;
	mov	cx, dx				; # of points => CX
	clr	bp				; ES:BP => start of point buffer
pointLoop:
	lodsw
	xchg	bx, ax
	lodsw
	xchg	bx, ax				; point => (AX, BX)
	call	PathTransCoord			; transform the point
	jc	coordOverflow			; if coords overflow, use last
coordOK:
	xchg	bp, di				; GState => BP, buffer => ES:DI
	stosw					; store P_x
	xchg	ax, bx
	stosw					; store P_y
	xchg	bp, di				; GState => DI, buffer => ES:BP
	loop	pointLoop

	; Clean up and exit
	;
	mov	ax, ds:[si-4].P_x
	mov	bx, ds:[si-4].P_y		; end Point => (AX, BX)
	call	StorePenPos			; store the new pen position
	segmov	ds, es				; buffer => DS:DI
	clr	di				; points begin at start of buf
	mov	cx, ds:[P_x]
	mov	dx, ds:[P_y]			; first point => (CX,DX)
	pop	bx				; memory handle => BX
	
	.leave
	ret

	; if the coords overflowed, use the last set 
coordOverflow:
	tst	bp				; if just starting...
	jz	makeupNumber			; ...make up a number
	mov	ax, es:[bp-(size Point)].P_x	; else use the last point
	mov	bx, es:[bp-(size Point)].P_y	; 
	jmp	coordOK
makeupNumber:
	mov	ax, 1000h			; use something out of bounds
	mov	bx, ax				;  that won't overflow the math
	jmp	coordOK
CopyPointsToBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddArcEllipsePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add points generated by the arc/ellipse code to the region

CALLED BY:	FillPath[RoundRect,Ellipse,Arc,*ArcThreePoint]Region

PASS: 		ES	- RegionPath segment
		DI	- Setup routine to call
		BP	- ArcCloseType
		GState	- on stack before return address

RETURN:		(CX,DX)	- Start of graphic element
		DI	- GState

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddArcEllipsePoints	proc	near
	
	; First, some serious hacking
	;
	push	ds, es
	push	bp, di
	mov	bp, sp
	mov	di, ss:[bp+10]			; GState handle => DI

	; Generate the Points, and then add them to the Region
	;
	call	LoadDSESGStateWindow		; load segment registers
	pop	di				; setup routine => DI
	pop	bp				; ArcCloseType => BP
	call	PathArcEllipseLow		; data => AX, BX, CX, DX
	pop	es				; restore RegionPath segment
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	call	StorePenPos
	mov	bx, dx				; point buffer handle => BX
	call	AddArcEllipsePointsLow		; add points to Region

	; Return the correct address, & clean up the stack
	;
	pop	ds
	pop	ax				; return address => AX
	pop	di				; GState handle => DI
	push	ax				; re-save return address
	ret
AddArcEllipsePoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddArcEllipsePointsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a set of pre-computed arc/ellipse points to the
		region being built.

CALLED BY:	AddArcEllipsePoints(), FillPathRoundRectTo()

PASS:		ES	= RegionPath segment
		BP	= ArcCloseType
		CX	= # of points in buffer
		BX	= Buffer handle

RETURN:		(CX,DX)	= Start of graphic element

DESTROYED:	AX, DI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddArcEllipsePointsLow	proc	near
	.enter
	
	; Now finally draw all of these Points
	;
	mov	ax, CLOSED_GRAPHIC_OPCODE	; if no points, nothing to close
	tst	bx
	jz	done
	jcxz	free
	call	MemLock				; lock the Points buffer
	mov	ds, ax
	mov	ax, ds:[P_x]			; starting Point => (AX, DX)
	mov	dx, ds:[P_y]
	cmp	bp, ACT_OPEN			; open element ??
	je	addPolyline			; yes, so jump
	mov	ax, CLOSED_GRAPHIC_OPCODE	; else we have a closed element
addPolyline:
	clr	di				; point array => DS:DI
	call	GrRegionPathAddPolyline		; add the multiple # of lines
free:
	call	MemFree				; free global block holding pts
done:
	mov_tr	cx, ax				; starting Point (CX, DX)

	.leave
	ret
AddArcEllipsePointsLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathTransCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a coordinate from its current state (either
		PAGE or DOCUMENT) to DEVICE.

CALLED BY:	INTERNAL

PASS:		DI	= GState handle
		AX	= X position
		BX	= Y position

RETURN: 	CARRY	= set if transform overflows 16-bits
		AX	= New X position
		BX	= New Y position

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathTransCoord	proc	near
	uses	cx, dx, di, si, ds
	.enter
	
	; Set things up to transform the coordinate
	;
	xchg	bx, di				; GState handle => BX, point=>DI
	call	MemDerefDS			; GState segment => DS
	mov	si, offset GS_TMatrix		; GState's TMatrix => DS:SI
	mov	bx, ds:[GS_window]		; Window handle => BX
	tst	bx
	jz	doTrans				; if no Window, use 
	call	MemDerefDS			; Window segment => DS
	mov	si, offset W_curTMatrix		; Window's TMatrix => DS:SI
doTrans:
	mov	bx, di				; coordinate back to (AX, BX)
	call	TransCoordCommonFar		; transform the sucker

	.leave
	ret
PathTransCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWinTopBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Windows top and bottom coordinates

CALLED BY:	INTERNAL

PASS:		DI	= GState handle

RETURN:		BP	= top 
		DX	= bottom 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetWinTopBottom		proc	near
	uses	bx, es 
	.enter

	mov	bp, -1024
	mov	dx, 1024			; load up biggest video driver
	call	LockWinFromGStateHandle		; ES = Window segment, BX=han
	jc	done
	mov	bp, es:[W_winRect].R_top	; minimum Y => BP
	mov	dx, es:[W_winRect].R_bottom	; maximum Y => DX
	call	MemUnlockV			; unlock & Release Window
done:
	.leave
	ret
GetWinTopBottom		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWinTopBottomAndMatrixSum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Windows top and bottom coordinates

CALLED BY:	INTERNAL

PASS:		DI	= GState handle

RETURN:		BP	= top 
		DX	= bottom 
		cxax	- matrix sum

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetWinTopBottomAndMatrixSum	proc	near
	uses	bx, es 
	.enter

	mov	bp, -1024
	mov	dx, 1024			; load up biggest video driver
	clrwwf	cxax
	call	LockWinFromGStateHandle		; ES = Window segment, BX=han
	jc	done
	mov	bp, es:[W_winRect].R_top	; minimum Y => BP
	mov	dx, es:[W_winRect].R_bottom	; maximum Y => DX
	mov	ax, es:[W_TMatrix].TM_31.DWF_frac
	mov	cx, es:[W_TMatrix].TM_31.DWF_int.low
	add	ax, es:[W_TMatrix].TM_32.DWF_frac
	adc	cx, es:[W_TMatrix].TM_32.DWF_int.low
	addwwf	cxax, es:[W_TMatrix].TM_11
	addwwf	cxax, es:[W_TMatrix].TM_22
	call	MemUnlockV			; unlock & Release Window
done:
	.leave
	ret
GetWinTopBottomAndMatrixSum	endp

GraphicsPath	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Text-related routines #4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPath	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPathLowText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add text to a Region that is being built

CALLED BY:	INTERNAL

PASS:		ES	= Region segment	
		DS:SI	= Text string (1 or more characters)
		DI	= GState handle
		(AX,BX)	= Position of first character (untransformed)
		CX	= Length of text

RETURN:		(CX,DX)	= Position of first character
		DS:SI	= Past end of text string
		ES	= Region segment (may have changed)

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This current won't work if there is a NULL window, as 
		TextCallDriver bails if there is not window.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillPathLowText	proc	near
		uses	bp, ds
		.enter
	
		; Setup for call to TextCallDriver()
		;
EC <		tst	cx			; check length		>
EC <		ERROR_Z	GRAPHICS_PATH_TEXT_LENGTH_MUST_BE_VALID		>
		mov	bp, ds			; text => BP:SI
		xchg	bx, di
		call	MemDerefDS		; GState => DS
		mov	bx, es:[RP_handle]
		mov	ds:[GS_pathData], bx	; store RegionPath handle
		or	ds:[GS_pathFlags], mask PF_FILL
		mov	bx, ds:[GS_window]
		tst	bx			; don't deref if no window
		jz	skipWinDeref		;  TextCallDriver is OK...
		call	MemDerefES		; Window => ES
skipWinDeref:
		mov	bx, di			; restore data => BX
		clr	dx			; no fractional positions
		mov	di, -1			; no limit
		call	TextCallDriverFar	; spew the character data

		; Clean up & exit
		;
		mov	di, ds:[LMBH_handle]	; GState handle => DI
		mov	bx, ds:[GS_pathData]
		call	MemDerefES		; RegionPath segment => ES
EC <		call	FarCheckDS_ES		; check segments	>
		and	ds:[GS_pathFlags], not (mask PF_FILL)
		mov	cx, CLOSED_GRAPHIC_OPCODE
		
		.leave
		ret
FillPathLowText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathOutputText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outline of text part of a path

CALLED BY:	TextCallDriver()

PASS:		AX.DL	= X position (WBFixed) (device coordinate)
		BX.DH	= Y position (WBFixed) (device coordinate)
		CX	= Segment address of font (ignored)
		SS:BP	= VPS_params
		SI	= Offfset into VPS_stringSeg for string
		DS	= GState
		ES	= Window

RETURN:		AX.DL	= X position for next character (device coordinate)
		BX.DH	= Y position for next character (device coordinate)
		SI	= Points after last character drawn
		BP	= Segment address of font (may have moved)
		DS	= GState (may have moved)
		ES	= Window (may have moved)

DESTROYED:	CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathOutputText	proc	far
		uses	bp
		.enter
	
		; Some set-up work (trashes, CX & DI)
		; - unlock font
		; - unlock bitmap (if any)
		; - unlock Window (if any)
		;
		mov	cx, bx			; temporarily store CX
		mov	di, ax			; save reg
		call	GetDocPenPos
		push	ax, bx			; save pen position
		push	di
		mov	bx, ds:[GS_fontHandle]
		call	FontDrUnlockFont	; unlock the font handle
		mov	di, ds:[LMBH_handle]	; Gstate handle => DI
		mov	bx, ds:[GS_window]	; Window handle => BX
		tst	bx
		jz	winUnlocked
		clr	ax
		xchg	ax, es:[W_bmSegment]
		tst	ax
		jz	unlockWindow
		push	ds	
		mov	ds, ax
		call	HugeArrayUnlockDir
		pop	ds
unlockWindow:
		call	MemUnlockV		; unlock & release Window
winUnlocked:
		pop	ax			; restore data => AX
		mov	bx, cx			; restore data => BX

		; First, figure the true maker of the font in the gstate.
		; We can't rely on what LockFont will give us, as it may be
		; a set of bitmaps for an outline font, and there's no
		; FM_BITMAP font driver, so we'd put out nothing.
		;	
		mov	cx, ds:[GS_fontAttr].FCA_fontID
		push	ds, bx, di
		call	FarLockInfoBlock	; ds <- info block
		call	FarIsFontAvail		; ds:bx <- FontInfo chunk
		mov	cx, ds:[bx].FI_maker
		call	FarUnlockInfoBlock
		pop	ds, bx, di
		push	cx			; POTP_maker
		
		; Now stroke or fill the text
		;
		test	ds:[GS_pathFlags], mask PF_FILL
		jnz	setupFill
		mov	cl, mask FGPF_SAVE_STATE ; FontGenPathFlags => CL
		push	cx			; POTP_dataCX
		mov	cx, DR_FONT_GEN_PATH
		push	cx			; POTP_function
doCall:
		mov	cx, ss:[bp].VPS_numChars		
		push	cx			; POTP_numChars
		mov	cx, ss:[bp].VPS_stringSeg
		mov	ds, cx			; string => DS:SI
		mov	bp, sp			; PathOutputTextParams => SS:BP
		call	PathOutputTextLow
		add	sp, (size PathOutputTextParams)

		; Clean up
		;
		xchg	bx, di			; GState handle=>BX, data=>DI
		call	MemDerefDS		; GState segment => DS
		pop	cx, bx			; restore penPos
		push	ax
		mov_tr	ax, cx
		call	SetDocPenPos		; reset pen position
		call	FontDrLockFont		; re-lock the font
		mov	ds:[GS_fontHandle], bx
		mov	bp, ax			; font segment => BP
		mov	bx, ds:[GS_window]	; Window handle => BX
		tst	bx
		jz	winLocked
		call	MemPLock		; lock & own Window
		mov	es, ax			; Window segment => ES
		tst	es:[W_bitmap].segment
		jnz	relockBitmap
winLocked:
		mov	bx, di
		pop	ax

		.leave
		ret

		; Setup for the fill
setupFill:
		push	ds:[GS_pathData]	; POTP_dataCX
		mov	cx, DR_FONT_GEN_IN_REGION
		push	cx			; POTP_function
		jmp	doCall

		; lock down the bitmap's directory structure
relockBitmap:
		push	di
		mov	bx, es:[W_bitmap].segment
		mov	di, es:[W_bitmap].offset
		call	HugeArrayLockDir
		mov	es:[W_bmSegment], ax
		pop	di
		jmp	winLocked
PathOutputText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathOutputTextLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outline of one or more text characters, replacing
		the functionality of the video driver 

CALLED BY:	INTERNAL
       		PathOutputText()

PASS:		AX.DL	= X position (WBFixed) (device coordinate)
		BX.DH	= Y position (WBFixed) (device coordinate)
		SS:BP	= PathOutputTextParams
		DS:SI	= NULL-terminated string to draw
		DI	= GState handle

RETURN:		AX.DL	= X position for next character (device coordinate)
		BX.DH	= Y position for next character (device coordinate)
		SI	= Points after last character drawn

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Just like the video driver, the horizontal is returned
		unchanged.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathOutputTextLow	proc	near
		uses	cx
		.enter
	
		; Draw the character thru the GState
charLoop:
		push	di, bx, ax, dx
		rndwbf	axdl			; x position => AX
		rndwbf	bxdh			; y position => BX
		call	GrUntransform		; doc coordinates => (AX, BX)
		call	GrMoveTo		; move to the correct position
		LocalGetChar	dx, dssi, NO_ADVANCE	; character => DX
SBCS <		clr	dh						>
		mov	bx, di			; also need GState => BX
		push	di
		mov	di, ss:[bp].POTP_function
		mov	ax, ss:[bp].POTP_maker
		mov	cx, ss:[bp].POTP_dataCX
		call	GrCallFontDriverID	; draw the actual font data
		pop	di

		; Calculate the device-coordinate position for the next char
		; GrTextWidthBBFixed calculates the width in document coords,
		; so we need to convert after we find the character width.
		;
		mov	cx, 2			; check two chars
		cmp	ss:[bp].POTP_numChars, 1	; only 1 left?
		jne	checkTwo
		dec	cx			; check only one left
checkTwo:
		call	GrTextWidthWBFixed	; width of pair => DX.AH
		movwbf	bxal, dxah
		LocalNextChar	dssi		; real character => DS:SI
		dec	cx			; check only one character
		jcxz	noMoreToCheck		; already checked only char
		call	GrTextWidthWBFixed	; width of character => DX:AH
		subwbf	bxal, dxah		; character width => BX.AL
noMoreToCheck:
		call	DocDeltaToDevice	; delta => (AX.DL, BX.DH)
		pop	cx			; restore old fractions
		pop	di			; restore old X position
		addwbf	axdl, dicl
		pop	di			; restore old Y position
		addwbf	bxdh, dich
		pop	di			; GState handle => DI
		dec	ss:[bp].POTP_numChars	; decrement character count
		jnz	charLoop		; loop until done

		.leave
		ret
PathOutputTextLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocDeltaToDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a character width (delta) expressed in document
		coordinates to a value in device coordinates

CALLED BY:	PathOutputTextLow()

PASS:		BX.AL	= X-delta (character width)
		DI	= GState

RETURN:		AX.DL	= X-delta (device coordinates)
		BX.DH	= Y-delta (device coordinates)

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocDeltaToDevice	proc	near
		uses	bp, si
		.enter
	
		; First compute where the origin lies
		;
		push	bx, ax
		clr	ax, bx, cx, dx
		call	GrTransformWWFixed	; X0 => DX.CX, Y0 => BX.AX
		pop	bp, si
		xchgwwf	bpsi, dxcx		; X0 => BP.SI, X-delta => DX.CL
		pushwwf	bxax			; save Y0

		; Now compute where the delta lies
		;
		mov	ch, cl
		clr	cl
		clr	ax, bx
		call	GrTransformWWFixed	; X-delta=>DX.CX, Y-delta=>BX.AX

		; Now find the difference, and return WBFixed values
		;
		subwwf	dxcx, bpsi		; X => DX.CX
		popwwf	bpsi
		subwwf	bxax, bpsi		; Y => BX.AX
		rndwwbf	bxax			; convert Y to WBFixed => BX.AH
		rndwwbf	dxcx			; convert X to WBFixed => DX.CH
		xchg	ax, dx			; X => AX.CH  Y => BX.DH
		mov	dl, ch			; X => AX.DL

		.leave
		ret
DocDeltaToDevice	endp

GraphicsPath	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Pattern-related routines #5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPattern	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathGetPatternInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	By looking at current path, we should be able to determine
		both the type of path attributes to use (area or text) &
		the RegionFillRule to use (RFR_ODD_EVEN, except with polygons).

CALLED BY:	PatternFill()

PASS:		DI	= GState handle
		DL	= RegionFillRule hint (valid only for GR_DRAW_POLYGON)

RETURN:		AX	= Offset to GrCommonPattern
		DL	= RegionFillRule

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes only one graphic opcode is contained in the path, 
		located directly after the data placed in the GString in
		GrBeginPath().

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FIRST_OPCODE_IN_PATH	equ (size Path) + PATH_DATA_OFFSET

PathGetPatternInfo	proc	far
		uses	bx, si, ds
		.enter
	
		; Lock the GState, and get a pointer to the path
		;
		mov	bx, di
		call	MemLock
		mov	ds, ax
		mov	si, ds:[GS_currentPath]
		mov	si, ds:[si]
		cmp	{byte} ds:[si+FIRST_OPCODE_IN_PATH], GR_DRAW_POLYGON
		je	getPatternAttrs
		mov	dl, RFR_ODD_EVEN

		; Determine the pattern attributes to use. If we have a text
		; opcode, use the text attributes. Else, use the area attrs
getPatternAttrs:
		mov	ax, offset GS_areaPattern
		cmp	{byte} ds:[si+FIRST_OPCODE_IN_PATH],\
			       GSE_FIRST_TEXT_OPCODE
		jl	done
		cmp	{byte} ds:[si+FIRST_OPCODE_IN_PATH],\
			       GSE_LAST_TEXT_OPCODE
		jg	done
		mov	ax, offset GS_textPattern
done:
		call	MemUnlock		; unlock GState

		.leave
		ret
PathGetPatternInfo	endp

GraphicsPattern	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Stroke Path routines #6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPath	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GStringElement table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; A listing of all the output opcodes, and the associated routines to return
; the starting position of these graphic operations
;
opcodeStrokeTable	label	word
	word	offset StrokePathFromPoint 	; GR_DRAW_LINE
	word	offset StrokePathContinued 	; GR_DRAW_LINE_TO
	word	offset StrokePathContinued 	; GR_DRAW_REL_LINE_TO
	word	offset StrokePathHLine		; GR_DRAW_HLINE
	word	offset StrokePathContinued	; GR_DRAW_HLINE_TO
	word	offset StrokePathVLine		; GR_DRAW_VLINE
	word	offset StrokePathContinued	; GR_DRAW_VLINE_TO
	word	offset StrokePathPolySpline	; GR_DRAW_POLYLINE
	word	offset StrokePathArc		; GR_DRAW_ARC
	word	offset StrokePathThreePointArc	; GR_DRAW_ARC_3POINT
	word	offset StrokePathContinued	; GR_DRAW_ARC_3POINT_TO
	word	offset StrokePathContinued	; GR_DRAW_REL_ARC_3POINT_TO
	word	offset StrokePathClosed		; GR_DRAW_RECT
	word	offset StrokePathContinued	; GR_DRAW_RECT_TO
	word	offset StrokePathClosed		; GR_DRAW_ROUND_RECT
	word	offset StrokePathContinued	; GR_DRAW_ROUND_RECT_TO
	word	offset StrokePathPolySpline	; GR_DRAW_SPLINE
	word	offset StrokePathContinued	; GR_DRAW_SPLINE_TO
	word	offset StrokePathFromPoint	; GR_DRAW_CURVE
	word	offset StrokePathContinued	; GR_DRAW_CURVE_TO
	word	offset StrokePathContinued	; GR_DRAW_REL_CURVE_TO
	word	offset StrokePathClosed		; GR_DRAW_ELLIPSE
	word	offset StrokePathClosed		; GR_DRAW_POLYGON
	word	offset StrokePathFromPoint 	; GR_DRAW_POINT
	word	offset StrokePathContinued	; GR_DRAW_POINT_CP
	word	offset StrokePathBrushPolyline	; GR_BRUSH_POLYLINE
	word	offset StrokePathChar		; GR_DRAW_CHAR
	word	offset StrokePathContinued	; GR_DRAW_CHAR_CP
	word	offset StrokePathFromPoint	; GR_DRAW_TEXT
	word	offset StrokePathContinued	; GR_DRAW_TEXT_CP
	word	offset StrokePathTextField	; GR_DRAW_TEXT_FIELD
	word	offset StrokePathFromPoint	; GR_DRAW_TEXT_PTR
	word	offset StrokePathFromPoint	; GR_DRAW_TEXT_OPTR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stoke the current Path

CALLED BY:	GrDrawPath

PASS:		DS	= GState segment
		DI	= GState handle
		SI	= Path chunk handle

RETURN:		Nothing

DESTROYED:	AX, CX, SI

PSEUDO CODE/STRATEGY:
		Draw a Gstring, stopping for the following:
		If output element {
			Determine if pen has been picked up
			If so {
				Record start of element
			}
			Play element
			Record end of element
		}
		If pen picked up {
			Invalidate start of element
		}
		If close sub-path {
			If valid start & end, draw line between them
			Invalidate start
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StrokePath	proc	near
	uses	bx, dx
	.enter
	
	; First some set-up work
	;
	call	PathStoreState			; store current state on stack
	or	ds:[GS_pathFlags], mask PF_STROKE
	call	PathLoadGString			; memory => BX, GString => SI
	push	bx				; save memory handle
	mov	ax, CLOSED_GRAPHIC_OPCODE	; initially, nothing to close

	; Play the graphics string, stopping wherever needed to ensure
	; we have a closed path
nextElement:
	mov	dx, (mask GSC_OUTPUT) or (mask GSC_PATH) or (mask GSC_ATTR)
	call	GrDrawGStringAtCP
	cmp	dx, GSRT_OUTPUT			; output element ??
	je	output
	cmp	dx, GSRT_ATTR			; graphics attributes ??
	je	attribute
	cmp	dx, GSRT_COMPLETE		; are we done ??
	je	done
EC <	cmp	dx, GSRT_PATH			; close sub-path ??	>
EC <	ERROR_NE	GRAPHICS_PATH_ERROR_PLAYING_PATH_AS_GSTRING	>

	; Deal with a path element
	;
	cmp	cx, GR_CLOSE_SUB_PATH
	jne	nextElement
closeSubPath:
	cmp	ax, CLOSED_GRAPHIC_OPCODE
	je	nextElement
	call	StrokePathCloseSubPath		; close the sub-path
	jmp	nextElement

	; Deal with an output element
output:
	call	StrokePathGetStart		; get the starting position
	jmp	nextElement			; draw the element, & continue

	; Deal with an attribute element
attribute:
	cmp	cl, GR_MOVE_TO
	je	closeSubPath
	cmp	cl, GR_REL_MOVE_TO
	je	closeSubPath
	jmp	nextElement

	; Clean up
done:	
	pop	bx				; temporary block handle => BX
	call	PathDestroyGString		; destroy the GString
	mov	bx, di				; GState => BX
	call	MemDerefDS			; GState segment => DS
	and	ds:[GS_pathFlags], not (mask PF_STROKE)
	call	PathRestoreState		; restore things from stack

	.leave
	ret
StrokePath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokePathGetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the starting position for a graphic element

CALLED BY:	StrokePath

PASS:		DS:SI	= Graphic opcode
		DI	= GState handle
		CL	= GStringElement
		(AX,BX)	= Current start position

RETURN:		(AX,BX)	= Updated start position

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StrokePathGetStart	proc	near
	uses	cx, si, ds
	.enter
	
	; Call the correct routine to return the starting position
	;
	call	GrDerefPtrGString		; ds:si -> element
	xchg	cx, bx				; start point => (AX, CX)
	sub	bl, GSE_FIRST_OUTPUT_OPCODE	; first output element => 0
	shl	bl, 1
	clr	bh
	call	cs:[opcodeStrokeTable][bx]
	mov	bx, cx				; new start => (AX, BX)

	.leave
	ret
StrokePathGetStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokePathHLine
		StrokePathVLine
		StrokePathChar
		StrokePathBrushPolyline
		StrokePathPolySpline
		StrokePathArc
		StrokePathThreePointArc
		StrokePathTextField
		StrokePathClosed
		StrokePathFromPoint
		StrokePathContinued
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the starting point of a graphic opcode

CALLED BY:	StrokePathGetStart

PASS:		DS:SI	= Graphic opcode
		DI	= GState
		(AX,CX)	= Current starting position

RETURN:		(AX,CX)	= Updated starting position

DESTROYED:	BX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Handles:		GR_DRAW_HLINE
;
StrokePathHLine		proc	near
	call	GrGetCurPos
	mov	cx, bx
	mov	ax, ds:[si].ODHL_x1
	ret
StrokePathHLine		endp

; Handles:		GR_DRAW_VLINE
;
StrokePathVLine		proc	near
	call	GrGetCurPos
	mov	cx, ds:[si].ODVL_y1
	ret
StrokePathVLine		endp

; Handles:		GR_DRAW_CHAR
;
StrokePathChar		proc	near
	mov	ax, ds:[si].ODC_x1
	mov	cx, ds:[si].ODC_y1
	ret
StrokePathChar		endp

; Handles:		GR_BRUSH_POLYLINE,
;
CheckHack	<((size OpBrushPolyline) - 2) eq (size OpDrawPolyline)>
StrokePathBrushPolyline	proc	near
	add	si, 2
	FALL_THRU	StrokePathPolySpline
StrokePathBrushPolyline	endp

; Handles:		GR_DRAW_POLYLINE, GR_DRAW_SPLINE
;
CheckHack	<(size OpDrawPolyline) eq (size OpDrawSpline)>
CheckHack	<(size OpDrawPolyline) eq (offset ODATP_x1)>
StrokePathPolySpline	proc	near
	mov	ax, ds:[si+(size OpDrawPolyline)].P_x
	mov	cx, ds:[si+(size OpDrawPolyline)].P_y
	ret
StrokePathPolySpline	endp

; Handles:		GR_DRAW_ARC
;
StrokePathArc		proc	near
	cmp	ds:[si].ODA_close, ACT_OPEN
	jne	StrokePathClosed		; if not open, we're closed :)
	push	bp
	mov	bp, offset AP_angle1
	inc	si				; ArcParams => DS:SI
	call	ArcGetAnglePos
	mov	cx, bx				; starting position => (AX, CX)
	pop	bp
	ret
StrokePathArc		endp

; Handles:		GR_DRAW_ARC_3POINT
;
StrokePathThreePointArc	proc	near
	movwwf	axbx, ds:[si].ODATP_x1
	rndwwf	axbx
	movwwf	cxbx, ds:[si].ODATP_y1
	rndwwf	cxbx
	ret
StrokePathThreePointArc	endp

; Handles:		GR_DRAW_TEXT_FIELD
;
StrokePathTextField	proc	near
	mov	ax, ds:[si].ODTF_saved.GDFS_drawPos.PWBF_x.WBF_int
	mov	bl, ds:[si].ODTF_saved.GDFS_drawPos.PWBF_x.WBF_frac
	mov	cx, ds:[si].ODTF_saved.GDFS_drawPos.PWBF_y.WBF_int
	mov	bh, ds:[si].ODTF_saved.GDFS_drawPos.PWBF_y.WBF_frac
	rndwbf	axbl
	rndwbf	cxbh
	ret
StrokePathTextField	endp

; Handles:		GR_DRAW_RECT, GR_DRAW_ROUNDED_RECT, GR_DRAW_ELLIPSE
;			GR_DRAW_POLYGON, GR_DRAW_ARC
;
StrokePathClosed	proc	near
	mov	ax, CLOSED_GRAPHIC_OPCODE		; can't close this
	ret
StrokePathClosed	endp

; Handles:		GR_DRAW_LINE, GR_DRAW_POINT, GR_DRAW_TEXT,
;			GR_DRAW_TEXT_PTR
;
CheckHack	<(offset ODL_x1) eq (offset ODP_x1)>
CheckHack	<(offset ODL_x1) eq (offset ODT_x1)>
CheckHack	<(offset ODL_x1) eq (offset ODTP_x1)>

CheckHack	<(offset ODL_y1) eq (offset ODP_y1)>
CheckHack	<(offset ODL_y1) eq (offset ODT_y1)>
CheckHack	<(offset ODL_y1) eq (offset ODTP_y1)>

StrokePathFromPoint	proc	near
	mov	ax, ds:[si].ODL_x1
	mov	cx, ds:[si].ODL_y1	
	ret
StrokePathFromPoint	endp

; Handles:		GR_DRAW_LINE_TO, GR_DRAW_REL_LINE_TO,
;			GR_DRAW_HLINE_TO, GR_DRAW_VLINE_TO,
;			GR_DRAW_ARC_3_POINT_TO, GR_DRAW_REL_ARC_3POINT_TO,
;			GR_DRAW_RECT_TO, GR_DRAW_ROUND_RECT_TO,
;			GR_DRAW_SPLINE_TO,
;			GR_DRAW_CURVE_TO, GR_DRAW_REL_CURVE_TO,
;			GR_DRAW_CHAR_CP, GR_DRAW_TEXT_CP
;
StrokePathContinued	proc	near
	ret
StrokePathContinued	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokePathCloseSubPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a sub-path when stroking

CALLED BY:	StrokePath

PASS:		DI	= GState (locked)
		(AX,BX)	= Start position of sub-path

RETURN:		AX	= CLOSED_GRAPHIC_OPCODE

DESTROYED:	BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StrokePathCloseSubPath	proc	near
	uses	ds
	.enter
	
	; We want to draw a line from the current position to the starting
	; position, but we cannot allow the pen position to be altered.
	;
	mov_tr	cx, ax
	mov	dx, bx				; starting point => (CX,DX)
	mov	bx, di				; GState handle => BX
	call	MemDerefDS			; GState segment => DS
	push	ds:[GS_penPos].PDF_x.DWF_frac
	pushdw	ds:[GS_penPos].PDF_x.DWF_int
	push	ds:[GS_penPos].PDF_y.DWF_frac
	pushdw	ds:[GS_penPos].PDF_y.DWF_int
	call	GrDrawLineTo			; draw a connecting line
	popdw	ds:[GS_penPos].PDF_y.DWF_int
	pop	ds:[GS_penPos].PDF_y.DWF_frac
	popdw	ds:[GS_penPos].PDF_x.DWF_int
	pop	ds:[GS_penPos].PDF_x.DWF_frac
	mov	ax, CLOSED_GRAPHIC_OPCODE

	.leave
	ret
StrokePathCloseSubPath	endp

GraphicsPath	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utility routines #7
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPath	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePathBackToGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the Path data back through to the GString, in case
		a Path was defined while a GString was being written to.

CALLED BY:	CombineGStringOrPathWithPath

PASS:		DS	= GState handle
		ES:SI	= Path-GString segment
		BX	= Path-GString handle
		CX	= PathCombineType

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WritePathBackToGString	proc	far
		.enter
	
		; Some set-up work
		;
		mov	ax, ds:[GS_pathData]
		tst	ax
		jz	done			; if old GString is NULL, done
		xchg	ax, ds:[GS_gstring]	; Path-GString => AX
		push	ax, bx, cx, dx, di, si
		and	ds:[GS_pathFlags], not (mask PF_DEFINING_PATH)
		
		; Manually draw the GrBeginPath
		;
		mov	di, ds:[GS_gstring]	; GString handle => DI
		call	GSStorePath

		; Now draw the rest of the Path
		;
		mov	di, ds:[LMBH_handle]	; GState handle => DI
		mov	cl, GST_PTR
		mov	bx, es
		add	si, PATH_DATA_OFFSET	; Path-GString data => ES:SI
		call	GrLoadGString
pathLoop:
		clr	ax, bx			; draw at 0,0
		mov	dx, mask GSC_PATH		; look for GR_END_PATH
		call	GrDrawGString		; draw the GString
		cmp	cl, GR_END_PATH		; see if done...
		jne	pathLoop

		; done drawing the shape.  Destroy the string then write the
		; final GR_END_PATH

		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString	; destroy the GString

		push	di			; save GState handle
		mov	bx, di			; need to deref again
		call	MemDerefDS		; ds -> GState
		mov	di, ds:[GS_gstring]	; GString handle => DI
		mov	cx, (GSSC_FLUSH shl 8)	; no data, just opcode
		mov	al, GR_END_PATH
		call	GSStoreBytes		; 
		pop	di

		; Clean up
		;
		mov	bx, di			; GState handle => BX
		call	MemDerefDS		; GState segment => DS
		pop	ax, bx, cx, dx, di, si
		or	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		mov	ds:[GS_gstring], ax	; restore GString value
done:
		.leave
		ret
WritePathBackToGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSStorePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the OpBeginPath structure to a GString

CALLED BY:	INTERNAL

PASS:		DI	= GString handle
		CX	= PathCombineType

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GSStorePath	proc	near
	.enter

EC <	cmp	cx, PathCombineType					>
EC <	ERROR_A	GRAPHICS_PATH_ILLEGAL_COMBINE_PARAMETER			>
	mov	bx, cx				; PathCombineType => BX
	mov	dx, cx
	mov	cx, (size OpBeginPath - 1) or (GSSC_FLUSH shl 8)
	mov	al, GR_BEGIN_PATH
	call	GSStoreBytes			; ignore transformation matrix

	.leave
	ret
GSStorePath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathLoadGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a path gstring

CALLED BY:	INTERNAL
	
PASS:		DS:*SI	= Path

RETURN:		BX	= Temporary memory handle (free after GrDestroyGString)
		SI	= GString handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathLoadGString	proc	near
	uses	ax, cx, bp, di, es
	.enter

	; Allocate a block
	;
	mov	si, ds:[si]			; Path structure => DS:SI
	ChunkSizePtr	ds, si, ax		; size to AX
	push	ax				; save the size

	mov	cx, HAF_STANDARD_NO_ERR_LOCK shl 8 or mask HF_SWAPABLE
	call	MemAllocFar			; handle => BX, segment => AX	
	mov	es, ax
	clr	di				; destination buffer => ES:DI
	pop	cx				; size (in bytes) => CX
	shr	cx, 1
	jnc	copyWords
	movsb					; copy odd byte
copyWords:
	rep	movsw				; copy all remaining words

	; Now load this into a GString
	;
	xchg	bx, ax				; memory handle => AX
	mov	si, offset P_data		; GString data => BX:SI
	mov	cl, GST_PTR
	call	GrLoadGString			; GString => SI
	mov_tr	bx, ax				; memory handle => BX

	.leave
	ret
PathLoadGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathDestroyGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the GString & free the temporary memory

CALLED BY:	INTERNAL

PASS:		SI	= GString handle
		DI	= GState handle (may be zero)
		BX	= Temporary memory handle

RETURN:		Nothing

DESTROYED:	ds and/or es, if they pointed to the freed gstring or gstate
		blocks.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathDestroyGString	proc	near
	pushf
	uses	dx
	.enter
	
	mov	dl, GSKT_LEAVE_DATA		; we'll take care of this sep.
	call	GrDestroyGString		; release data structures
EC <	call	NullSegmentRegisters					>
	call	MemFree				; free the sucker

	.leave
	popf
	ret
PathDestroyGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurPosToWindowZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the position in document coordinates to be (0,0) in
		Window coordinates.

CALLED BY:	GrFillPath()

PASS:		DI	= GState (locked)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCurPosToWindowZero	proc	near
	.enter

	mov	bx, di
	call	MemDerefDS		; GState => DS
	clr	ax, bx, cx, dx		; want origin of device
	call	GrUntransformWWFixed	; new coordinates => (DX.CX, BX.AX)	
	call	SetDocWWFPenPos		; store the position away

	.leave
	ret
SetCurPosToWindowZero	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyRegionPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a copy of the RegionPath for the passed Path

CALLED BY:	EXTERNAL

PASS:		DS:*BX	= Path
		CL	= RegionFillRule

RETURN:		BX	= Handle of unlocked RegionPath or 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyRegionPath	proc	near
	uses	ax, cx, dx, di, si, bp, es
	.enter

	; Now get a Path for the fine caller
	;
EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_A GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
	tst	bx				; any Path ??
	jz	done				; nope, so do nothing
	mov	si, ds:[bx]			; Path => DS:SI

	; Create a new RegionPath, ignore the current one
	;
	push	ds:[si].P_slowRegion
	push	ds:[si].P_flags
	push	ds:[si].P_top
	push	ds:[si].P_bottom
	mov	ds:[si].P_slowRegion, 0
	mov	si, bx				; Path chunk handle => SI
	call	PathBuildRegionSlow		; build a region from the path
	mov	bp, ds:[si]			; Path => DS:BP
	pop	ds:[si].P_bottom
	pop	ds:[si].P_top
	pop	ds:[bp].P_flags
	pop	ds:[bp].P_slowRegion
	call	MemUnlock			; unlock the sucker
done:
	.leave
	ret
CopyRegionPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRegionPathToRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a RegionPath into a Region by eliminating all of
		the RegionPath header information

CALLED BY:	EXTERNAL

PASS:		BX	= RegionPath block handle

RETURN:		BX	= 0 if NULL Region was passed
		Carry	= Set if no Region or if NULL Region

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertRegionPathToRegion	proc	near
	uses	ax, cx, di, si, ds, es
	.enter
	
	; Lock the block, copy, and re-allocate
	;
	tst	bx
	stc					; assume no path
	jz	done
	call	MemLock				; segment handle => AX
	mov	ds, ax
	mov	es, ax
	clr	di
	mov	si, offset RP_bounds
	cmp	ds:[si].R_left, EOREGREC	
	jne	copy
	cmp	ds:[si].R_right, EOREGREC
	je	nullRegion
copy:
	mov	ax, ds:[RP_size]		; size, including header
	sub	ax, (size RegionPath) - (size Rectangle)
	mov	cx, ax
	shr	cx, 1				; go to word size
EC <	ERROR_C	GRAPHICS_REGION_ODD_SIZE	; this can't happen	>
	rep	movsw				; copy them words
	clr	ch
	call	MemReAlloc			; resize the block
	call	MemUnlock			; and unlock it
done:
	.leave
	ret

	; We have a NULL region, so free the memory and return carry set
nullRegion:
	call	MemFree
	clr	bx
	stc
	jmp	done
ConvertRegionPathToRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UntransformDWordByGStateOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Untransform a DWord by the GState only

CALLED BY:	UTILITY

PASS:		DI	= GState
		DX:CX	= X coordinate (32-bit integer)
		BX:AX	= Y coordiante (32-but integer)

RETURN:		DX:CX	= X coordinate (32-bit integer)
		BX:AX	= Y coordiante (32-but integer)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UntransformDWordByGStateOnly	proc	near
		uses	si, ds
		.enter

		xchg	ax, si			; save y.high
		xchg	bx, di			; GState => BX
		call	MemLock			; lock GState
		mov	ds, ax
		mov	ax, offset GS_TMatrix
		xchg	ax, si			; restore y.high; TMatrix=>DS:SI
		xchg	bx, di			; restore y.low & GState
		call	UnTransExtCoordCommonFar
		xchg	bx, di			; GState => BX
		call	MemUnlock		; unlock GState
		xchg	bx, di			; restore resultY.high & GState

		.leave
		ret
UntransformDWordByGStateOnly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathUnlinkSlowRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlink the "slow region" (the RegionPath) for a Path,
		so that it may be used for other purposes without worry
		that it will be deleted by the system.

CALLED BY:	GrFillRegionPath

PASS:		*DS:BP	= Path

RETURN:		AX	= RegionPath handle (or zero if none)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathUnlinkSlowRegion	proc	near
		uses	bp
		.enter
	
		; Clear the VALID flag & zero-out the memory handle
		;
		mov	bp, ds:[bp]
		and	ds:[bp].P_flags, not (mask PSF_REGION_VALID)
		clr	ax
		xchg	ax, ds:[bp].P_slowRegion

		.leave
		ret
PathUnlinkSlowRegion	endp

GraphicsPath	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Error checking routines #8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
GraphicsPath	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyGString, VerifyPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that we are writing to a GString or a Path, as the
		circumstances warrant.

CALLED BY:	INTERNAL
	
PASS:		DS	= GState segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VerifyGString	proc	near
	uses	bx
	.enter

	mov	bx, ds:[GS_gstring]		; GString handle => BX
	call	ECCheckMemHandleFar
	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	ERROR_NZ	GRAPHICS_PATH_CANNOT_WRITE_TO_PATH_WITH_THIS_OP

	.leave
	ret
VerifyGString	endp

if	0
VerifyPath	proc	near
	uses	bx
	.enter

	mov	bx, ds:[GS_gstring]		; Path handle => BX
	call	ECCheckMemHandleFar
	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	ERROR_Z		GRAPHICS_PATH_CANNOT_WRITE_TO_GSTRING_WITH_THIS_OP

	.leave
	ret
VerifyPath	endp
endif

GraphicsPath	ends
endif
