COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsPath.asm

AUTHOR:		Don Reeves

ROUTINES:
	Name			Description
	----			-----------
GLB	GrBeginPath		Opens a subPath for writing
GLB	GrEndPath		Closes a subPath
GLB	GrCloseSubPath		Geometrically closes a sub-Path
GLB	GrSetClipPath		Makes the current Path the clip Path
GLB	GrSetWinClipPath	Makes the current Path the winclip Path
INT	SetClipPathCommon	Does the real work of setting a clip Path
GLB	GrFillPath		Fills the current Path
GLB	GrDrawPath		Strokes the outline of the current Path
GLB	GrSetStrokePath		Changes the current Path to its stroked verion
GLB	GrGetPathBounds		Returns the bounding rectangle of the curPath
GLB	GrTestPointInPath	Tests if a point is inside of the current Path
GLB	GrGetPathPoints		Returns block holding points along current Path
GLB	GrGetPathRegion		Returns Region from current Path
GLB	GrGetClipRegion		Returns Region combined from clip Paths

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/91		Initial version

DESCRIPTION:
	This file contains the routines to access the kernel's graphic
	path support.

	$Id: graphicsPath.asm,v 1.1 97/04/05 01:13:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsPath	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrBeginPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a new graphics Path, or alters the existing current
		Path. All graphics operations that are executed until GrEndPath
		is called become part of the Path.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState
		CX	= PathCombineType

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrBeginPath	proc	far
	push	ds
	uses	ax, bx, cx, dx, si, bp, es
	.enter

	; Some set-up work
	;
	call	LockDI_DS_checkFar	
EC <	cmp	cx, PathCombineType					>
EC <	ERROR_A	GRAPHICS_PATH_ILLEGAL_COMBINE_PARAMETER			>
EC <	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH		>
EC <	ERROR_NZ GRAPHICS_PATH_CANNOT_WRITE_TO_PATH_WITH_THIS_OP	>
	test	ds:[GS_pathFlags], mask PF_FILL or mask PF_STROKE
	jnz	done				; if playing path, ignore
	cmp	cx, PCT_NULL			; destroying the current Path ??
	je	nukePath			; yes, so get out of here
	mov	ax, ds:[GS_gstring]
	mov	ds:[GS_pathData], ax		; save old GString value

	; Allocate a GString to hold the graphic opcode info
	;
	or	ds:[GS_pathFlags], mask PF_DEFINING_PATH

	mov	di, ds:[LMBH_handle]		; GState handle => DI
	call	GrSaveState			; save the state of everything
	mov	dl, cl				; PathCombineType => DL
	mov	cx, GST_PATH or ((mask CGSC_WRITING) shl 8)
	clr	bx, si				; allocate a chunk
	call	AllocGString			; GString handle => AX
	mov	ds:[GS_gstring], ax

	; Write out the GrBeginPath structure
	;
	mov	cl, dl
	clr	ch				; PathCombineType => CX
	mov_tr	di, ax				; GString handle => DI
	call	GSStorePath			; store path bytes to GString

	; Write out the current transformation matrix. To avoid locking
	; the Window, we don't call GrGetTransform().
	;
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	mov	si, offset GS_TMatrix		; TransMatrix => DS:SI
	call	GrSetTransform			; set the transformation

	; Write out the current pen position
	;
	call	GetDocPenPos			; current position => (AX, BX)
	call	GrMoveTo			; write out the current position
done:
	.leave
	GOTO	UnlockDI_popDS, ds

	; Destroy the Path, and leave
	;
nukePath:
	clr	di
	xchg	ds:[GS_currentPath], di		; current Path => DS:*DI
	call	GrDestroyPath			; nuke the Path
	jmp	done				; we're outta here
GrBeginPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEndPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ends the definition of the current Path. Should never be
		called w/o first calling GrBeginPath.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrEndPath	proc	far
	push	ds
	uses	ax, bx, cx, dx, si, bp, es
	.enter

	; Write out the data to the Path or GString
	;
	call	LockDI_DS_checkFar
	jnc	done				; do nothing for normal drawing

	; Write the end values to the GString of Path being defined.
	;
	mov	ax, GR_END_PATH or (GR_END_GSTRING shl 8)
	mov	cx, (GSSC_FLUSH shl 8)
	jz	storeBytes			; if a GString, jump. Else, path
	inc	cx				; ...so write GR_END_GSTRING too
storeBytes:
	call	GSStoreBytes
	tst	cl				; writing to a GString ??
	jz	done				; yes, so we're done here

	; Restore the GState, so that we can make some changes
	;
	mov	bx, di				; Path-GString handle => BX
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	clr	ds:[GS_gstring]			; NULL to avoid restore problems
	call	GrRestoreState			; restore GState state
	xchg	bx, di				; GState handle => BX
	call	MemDerefDS
	mov	ds:[GS_gstring], di		; store Path-GString handle

	; Combine the new Path-GString with the current Path. Note
	; that CombineGStringOrPathWithPath will also write the contents
	; of that path into the GString, if such is being defined.
	;
	mov	ax, ds:[GS_currentPath]		; clip path handle => AX
	xchg	bx, di				; GString handle => BX
	mov	dl, PCS_GSTRING
	call	CombineGStringOrPathWithPath
	mov	ds:[GS_currentPath], ax		; store new chunk handle

	; Now, destroy the Path-GString
	;
	mov	si, di				; GString => SI
	clr	di				; GState => DI
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString		; free the Path-GString
	mov	ax, ds:[GS_pathData]
	mov	ds:[GS_gstring], ax		; restore original GString
	and	ds:[GS_pathFlags], not (mask PF_DEFINING_PATH)
done:
	.leave
	GOTO	UnlockDI_popDS, ds
GrEndPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCloseSubPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Geometrically closes the currently open Path. Note: one
		still needs to call GrEndPath to end the path definition.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCloseSubPath	proc	far
	push	ds
	uses	ax, cx
	.enter

	; Add this operand to a GString. If we're drawing, do nothing
	;
	call	LockDI_DS_checkFar
	jnc	done				; if normal drawing, do nothing
	mov	al, GR_CLOSE_SUB_PATH
	mov	cx, (GSSC_FLUSH shl 8)		; flush, no data bytes
	call	GSStoreBytes			; write out the information
done:
	.leave
	GOTO	UnlockDI_popDS, ds
GrCloseSubPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetClipPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current Path to be the clip Path for all future
		graphics operations. This Path is only affected by the
		Window's TMatrix.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState
		CX	= PathCombineType
		DL	= RegionFillRule (unnecessary for PCT_NULL)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetClipPath	proc	far

	; Set a few registers, and call common routine
	;
	push	ds, ax, bx
	mov	ax, GR_SET_CLIP_PATH or \
		    (not (mask WGRF_PATH_VALID)) shl 8
	mov	bx, offset GS_clipPath
	jmp	SetClipPathCommon		; we won't return
GrSetClipPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetWinClipPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current Path to be the document clip Path for
		all future graphics operations. This Path is affected by
		both the Window & GState TMatrix's.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		CX	= PathCombineType
		DL	= RegionFillRule (unnecessary for PCT_NULL)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetWinClipPath	proc	far

	; Set a few registers, and call common routine
	;
	push	ds, ax, bx
	mov	ax, GR_SET_WIN_CLIP_PATH or \
		    (not (mask WGRF_WIN_PATH_VALID)) shl 8
	mov	bx, offset GS_winClipPath
	jmp	SetClipPathCommon		; we won't return
GrSetWinClipPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClipPathCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs the guts of setting the clip Path

CALLED BY:	GrSetClipPath, GrSetWinClipPath (no one else!!!)

PASS:		DI	= GState
		AL	= GR_SET_CLIP_PATH or GR_SET_WIN_CLIP_PATH
		AH	= WinGrRegFlags mask to AND
		BX	= offset GS_clipPth or GS_winClipPath
		CX	= PathCombineType
		DL	= RegionFillRule

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		DS, AX, & BX are pushed onto the stack already. Perform the
		normal routine's work, and then restore AX & BX in reverse
		order. Finally get DS o stack through UnlockDI_popDS.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		You can only jump to this routine, and only if the routine
		being jumped from is a far routine!
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/ 8/91		Initial version
	Don	8/23/91		Made a little faster

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetClipPathCommon	proc	far
	uses	cx, dx, si, bp, es
	.enter
	
	; Some set-up work
	;
EC <	cmp	cx, PathCombineType					>
EC <	ERROR_A	GRAPHICS_PATH_ILLEGAL_COMBINE_PARAMETER			>
EC <	cmp	cx, PCT_NULL						>
EC <	je	endEC							>
EC <	cmp	dl, RegionFillRule					>
EC <	ERROR_A GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
EC <endEC:								>
	call	LockDI_DS_checkFar
	jc	writeToGString			; deal with writing to GString

	; Combine the Gstring with the current Path
	;
	push	ax, bx, dx			; WinGrRegFlags, GState offset
	mov	ax, ds:[bx]			; clip path handle => BX
	mov	bx, ds:[GS_currentPath]		; current path handle => BX
	mov	dl, PCS_PATH
	call	CombineGStringOrPathWithPath
	pop	bx, dx				; GState offset, fill rule
	mov	ds:[bx], ax			; store new chunk handle
	tst	ax				; NULL path ??
	jz	doWindow
	mov	cl, offset BPF_FILL_RULE
	shl	dl, cl				; move RegionFillRule into place
	or	dl, mask BPF_FILL_RULE_VALID	; use the rule when filling
	or	ds:[si].OBP_flags, dl

	; Invalidate the proper Window flag
doWindow:
	pop	cx				; WinGrRegsFlags => CH
	call	LockWinFromGStateHandle
	jc	done				; if no Window, we're done
	cmp	di, es:[W_curState]		; are we the Window's GState ??
	jne	unlockWindow
	and	es:[W_grRegFlags], ch
	and	es:[W_grFlags], not (mask WGF_MASK_VALID)
unlockWindow:
	call	MemUnlockV			; unlock & release Window
done:
	.leave
	pop	ax, bx				; restore AX & BX
	GOTO	UnlockDI_popDS, ds		; clean & return to far caller

	; Write the opcode to the GString
	;
writeToGString:
EC <	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH		>
EC <	ERROR_NZ GRAPHICS_CANT_SET_CLIP_RECT_OR_PATH_WHEN_DEFINING_PATH	>
	mov	ah, dl				; first byte = fill rule
	mov	bx, cx				; data => BX
	mov	cx, (size OpSetClipPath - 1) or (GSSC_FLUSH shl 8)
	call	GSStoreBytes			; write out the information
	jmp	done				; we're outta here
SetClipPathCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a filled representation of the current Path, using
		the supplied fill rule and the current graphic area attributes.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState
		CL	= RegionFillRule (enumerated type)
				RFR_ODD_EVEN
				RFR_WINDING

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillPath	proc	far

	; Some set-up work
	;
 EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_A	GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
	call	EnterGraphics
	LONG jc	writeToGString			; writing to a GString

	; Else we do the real work of filling the path
	;
	mov	si, ds:[GS_currentPath]		; Path => *DS:SI
	tst	si				; any Path ??
	LONG jz	exit				; nope, so do nothing
	call	TrivialRejectFar		; check null window, clip

	; we want to release the window, so we can use GrDrawRegion to draw
	; the shape.  But there could be a bitmap associated with it, which
	; screws EVERYTHING up if we don't deal with it properly here.  Sigh.

	tst	es:[W_bitmap].segment		; see if there is a bitmap ther
	jz	bmDone
	push	ds				; save GState segment
	mov	ds, es:[W_bmSegment]
	mov	es:[W_bmSegment], 0
	call	HugeArrayUnlockDir
	pop	ds
bmDone:
	mov	bx, es:[LMBH_handle]		; Window handle => BX
	push	bx				; save the Window handle
	call	MemUnlockV			; unlock & release Window
	cmp	ds:[GS_areaPattern].GCP_pattern, PT_SOLID
	jne	fillWithPattern			; if not solid, fill w/ pattern
	mov	bp, si				; Path handle => BP
	call	PathValidateRegion		; RegionFull => ES:SI
	call	PathUnlinkSlowRegion
EC <	cmp	ax, bx				; verify handle		>
EC <	ERROR_NE GRAPHICS_PATH_EXPECTED_REGION_PATH_HANDLE		>
	push	ax				; save handle to unlock

	mov	di, ds:[LMBH_handle]		; GState handle => DI
	call	PathStoreState			; save GState state on stack
	call	SetCurPosToWindowZero		; pen position = Window's origin
	segmov	ds, es				; RegionFull => DS:SI
	call	GrDrawRegionAtCP		; draw that region!
	call	PathRestoreState		; restore GState state

	pop	bx				; handle to free => BX
EC <	tst	bx				; should be valid	>
EC <	ERROR_Z	GRAPHICS_PATH_EXPECTED_REGION_PATH_HANDLE		>
	call	MemFree				; free the RegionPath
	mov	bx, di				; GState handle => BX
	call	MemDerefDS			; GState segment => DS
done:
	pop	bx				; Window handle => BX
	call	MemPLock			; re-lock & own Window
	mov	es, ax				; Window segment => ES
	
	; again, we might need to re-lock the bitmap.

	tst	es:[W_bitmap].segment		; see if there is a bitmap ther
	jz	exit
	push	bx, di
	mov	bx, es:[W_bitmap].segment
	mov	di, es:[W_bitmap].offset
	call	HugeArrayLockDir
	mov	es:[W_bmSegment], ax
	pop	bx, di
exit:
	jmp	ExitGraphics

	; Fill with a pattern. Make sure that we fill the area that
	; is the intersection of the current clip region (if any)
	; with that of the current path (fixed 10/17/94 by Don)
	;
fillWithPattern:
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	call	GrSaveState
	mov	dl, cl				; RegionFillRule => DL
	mov	cx, PCT_INTERSECTION		; PathCombineType => CX
	call	GrSetClipPath
	mov	dx, offset GS_areaPattern	; DS:DX => GrCommonPattern
	call	PatternFillLow			; go fill the path
	call	GrRestoreState
	jmp	done	

	; Deal with a GString
	;
writeToGString:
EC <	call	VerifyGString			; make sure it's a GString >
	mov	al, GR_FILL_PATH
	mov	ah, cl				; data byte => AH
	mov	cx, 1 or (GSSC_FLUSH shl 8)	; write one data byte
	call	GSStoreBytes
	jmp	ExitGraphicsGseg
GrFillPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the stroked representation of the current Path,
		using the current graphic line attributes.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawPath	proc	far
	push	ds
	uses	ax, cx, si
	.enter

	; All we want to do is draw the path.
	;
	call	LockDI_DS_checkFar
	jc	writeToGString

	; Now play the GString
	;
	mov	si, ds:[GS_currentPath]		; current Path chunk => SI
	tst	si				; any current Path
	jz	done				; none - so do nothing
	call	StrokePath			; do the hard work
	jmp	done

	; Deal with writing to a GString
	;
writeToGString:
EC <	call	VerifyGString			; make sure we have a GString >
	mov	al, GR_DRAW_PATH
	mov	cx, (GSSC_FLUSH shl 8)		; no data bytes
	call	GSStoreBytes
done:
	.leave
	GOTO	UnlockDI_popDS, ds
GrDrawPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetStrokePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the current path with the one that is defined as
		the stroked representation of the current path.

CALLED BY:	GLOBAL
	
PASS:		DI	= GState

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetStrokePath	proc	far
	push	ds
	uses	ax, cx, di
	.enter

	; All we want to do is draw the path.
	;
	call	LockDI_DS_checkFar
	jc	writeToGString
	;...
	jmp	done

	; Deal with writing to a GString
	;
writeToGString:
	mov	di, ds:[GS_gstring]		; GString handle => DI
EC <	call	VerifyGString			; make sure we have a GString >
	mov	al, GR_SET_STROKE_PATH
	mov	cx, (GSSC_FLUSH shl 8)		; no data bytes
	call	GSStoreBytes
done:
	.leave
	GOTO	UnlockDI_popDS, ds
GrSetStrokePath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTestPointInPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests whether or not the passed point is inside of the
		current path.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		CL	= RegionFillRule
		(AX,BX)	= Document coordinate

RETURN:		Carry	= Set if inside
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrTestPointInPath	proc	far
	push	ds
	uses	ax, bx, cx, dx, bp, si, es
	.enter

	; Some set-up work
	;
EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_AE	GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE	>
	call	LockDI_DS_checkFar
	cmc					; invert the carry
	jnc	done				; if GString or Path, ignore

	; Simply get the Region for the current Path, and call routine for
	; testing a point inside of a Region
	;
	mov	si, ds:[GS_currentPath]		; Path chunk handle => SI
	tst	si				; also clears carry
	jz	done
	mov	dx, bx	
	call	PathValidateRegionAndWinValWinStruct
						; RegionFull (locked) => ES:SI

	push	bx				; save RegionFull handle
	mov	bx, dx				; bx <- Y coord
	call	GrTransform			; device coordinate => (AX, BX)
	segmov	ds, es
	add	si, RF_region			; Region => DS:SI
	mov_tr	cx, ax
	mov	dx, bx				; test point => (CX, DX)
	call	GrTestPointInReg		; destroys two words at DS:SI-4

	pop	bx				; bx <- RegionFull handle
EC <	pushf					; save flags from tst	>
EC <	tst	bx				; should be valid	>
EC <	ERROR_Z	GRAPHICS_PATH_EXPECTED_REGION_PATH_HANDLE		>
EC <	popf					; restore return flags  >
	call	MemUnlock			; unlock the RegionPath
	mov	bx, di				; GState handle => DI
	call	MemDerefDS			; GState segment => DS
done:
	.leave
	GOTO	UnlockDI_popDS, ds
GrTestPointInPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the GString data which defines the current Path.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		BX	= GetPathType enum
				GPT_CURRENT	- current path
				GPT_CLIP	- current clip path
				GPT_WIN_CLIP	- win clip path

RETURN:		Carry	= Clear
		BX	= Handle of memory holding GString for path
			- or -
		Carry	= Set (no Path or out of memory)
		BX	= NULL

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetPath	proc	far
	push	ds
	uses	ax, cx, dx, si, es, di
	.enter

	; Get the current path's GString
	;
	call	LockDI_DS_checkFar

	; based on the passed enum, return the right path.
	;
	CheckHack <(offset GS_clipPath) - (offset GS_currentPath) eq 2>
	CheckHack <(offset GS_winClipPath) - (offset GS_clipPath) eq 2>
EC <	cmp	bx, GetPathType
EC <	ERROR_AE GRAPHICS_ILLEGAL_PATH_TYPE				>
	shl	bx, 1				; make table index
	add	bx, offset GS_currentPath	; offset to path => BX
	mov	si, ds:[bx]			; Path chunk handle => SI
	tst	si				
	stc
	jz	errorShort			; if no Path, return error

	; Allocate block to hold GString
	;
	mov	si, ds:[si]			; path => DS:SI
	ChunkSizePtr	ds, si, ax		; path size => AX
	sub	ax, (size Path)			; Path-GString size => AX
	push	ax				; save # of byte to copy
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx				; # of bytes to copy => CX
errorShort:
	jc	error				; of out of memory, abort

	; Now copy the GString over, after verifying some assumptions
	;
	push	ds				; save GState segment
	mov	es, ax
	clr	di				; destination => ES:DI
	add	si, (size Path)			; Path-GString data => DS:SI
	rep	movsb				; copy the GString

	; Go find all of the GR_BEGIN_PATH statements
	;
	push	bx				; save the memory handle
	mov	cl, GST_PTR
	mov	bx, es
	clr	si
	call	GrLoadGString			; GString handle => SI
	clr	di
	call	GrCreateState			; (null) GState => DI
nextElement:
	mov	dx, mask GSC_PATH
	call	GrDrawGStringAtCP
	cmp	dx, GSRT_COMPLETE
	je	doneSearch
	cmp	dx, GSRT_PATH
	jne	nextElement
	cmp	cl, GR_BEGIN_PATH
	jne	nextElement

	; Found a GR_BEGIN_PATH. Do a little swapping around.
	;
	push	di, si				; save GState, GString handles
	call	GrDerefPtrGString		; offset => SI
	mov	ax, ds:[si].OBP_combine		; PathCombineType => AX
	mov	{byte} ds:[si], GR_APPLY_TRANSFORM
	inc	si				; skip over opcode
	mov	di, si				; destination => ES:DI
	add	si, size OpBeginPath		; source => DS:SI
	mov	cx, (size OpApplyTransform) + (size OpMoveTo) - 1
	rep	movsb
	mov	{byte} es:[di], GR_BEGIN_PATH
	inc	di
	stosw					; store PathCombineType, twice
	stosw
	pop	di, si				; restore GState,GString han
	mov	al, GSSPT_RELATIVE
	mov	cx, 3				; skip the three elements
	call	GrSetGStringPos
	jmp	nextElement

	; There was some error. Exit gracefully.
error:
	clr	bx				; return NULL handle
	stc					; return carry set for error
	jmp	done

	; We've finished moving stuff around. Clean up.
doneSearch:
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	call	GrDestroyState			; destroy GState
	pop	bx				; restore GString data block
	call	MemUnlock			; unlock it, and return
	clc					; indicate success
	pop	ds				; restore GState segment
done:
	.leave
	GOTO	UnlockDI_popDS, ds
GrGetPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTestPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for the existence of a path

CALLED BY:	GLOBAL

PASS:		DI	= GState
		AX	= GetPathType enum
				GPT_CURRENT	- current path
				GPT_CLIP	- current clip path
				GPT_WIN_CLIP	- win clip path

RETURN:		Carry Clear if path exists

DESTROYED:	Nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	14 mar 93	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrTestPath	proc	far
	push	ds
	uses	ax, bx
	.enter

	; Get the current path's GString
	;
	call	LockDI_DS_checkFar

	; based on the passed enum, return the right path.
	;
	CheckHack <(offset GS_clipPath) - (offset GS_currentPath) eq 2>
	CheckHack <(offset GS_winClipPath) - (offset GS_clipPath) eq 2>
EC <	cmp	ax, GetPathType
EC <	ERROR_AE GRAPHICS_ILLEGAL_PATH_TYPE				>
	mov_tr	bx, ax
	shl	bx, 1				; make table index
	mov	ax, 0xffff
	add	ax, ds:[bx].GS_currentPath	; carry set if non-zero
	cmc
	.leave
	GOTO	UnlockDI_popDS, ds
GrTestPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPathBoundsDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the rectangular bounds that encompass the current
		path (as it would be filled).

CALLED BY:	GLOBAL

PASS:		di	- GState
		ax	- GetPathType
		ds:bx	- fptr to buffer the size of RectDWord

RETURN:		carry	- clear (success)
		ds:bx	- RectDWord structure filled with bounds		

			else
	
		carry	- set (indicates there is no path)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetPathBoundsDWord	proc	far
		uses	si, bx, ax, di, cx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si					>
EC <		movdw	bxsi, dsbx				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>
endif		
		mov	si, bx			; ds:si -> RectDWord
		clrdw	ds:[si].RD_left		; initialize values to 
		clrdw	ds:[si].RD_right	;  something reasonable
		clrdw	ds:[si].RD_top
		clrdw	ds:[si].RD_bottom
		mov	bx, ax			; bx = GetPathType
		call	GrGetPath		; bx = path handle or zero
		tst	bx			; if zero, bail with error
		LONG jz	noPath

		; OK, there is a path.  Lock it down and get the bounds

		push	bx			; save block handle
		push	di			; save GState
		clr	di
		call	GrCreateState		; start anew, so we don't hose
						;  any GStrings being created 
		clr	dx, ax
		call	GrSetLineWidth		; set zero line width...
		push	si			; save offset to results struc
		call	MemLock
		mov	bx, ax			; bx -> GString
		clr	si			; bx:si -> RectDWord
		mov	cx, GST_PTR	
		call	GrLoadGString		; si = GString handle
		pop	bx			; ds:bx -> RectDWord
		clr	dx			; dx <- GSControl
		call	GrGetGStringBoundsDWord	; get the bounds
		mov	dl, GSKT_LEAVE_DATA	; can't nuke PTR type anyway
		call	GrDestroyGString	; release structures
		call	GrDestroyState		; nuke allocated GState
		pop	di			; restore passed GState

		; now we need to reverse transform through the passed GState

		push	ds			; save segment of RectDWord
		mov	si, bx			; ds:si -> RectDWord
		xchg	bx, di			; save offset, setup GS handle
		call	MemLock
		mov	ds, ax
		test	ds:[GS_TMatrix].TM_flags, mask TF_ROTATED
		call	MemUnlock		; release GState
		xchg	bx, di
		pop	ds
		jnz	handleRotate

		; simple untransform of corners will suffice

		movdw	dxcx, ds:[si].RD_left
		movdw	bxax, ds:[si].RD_top
		call	UntransformDWordByGStateOnly
		movdw	ds:[si].RD_left, dxcx
		movdw	ds:[si].RD_top, bxax
		xchgdw	dxcx, ds:[si].RD_right
		xchgdw	bxax, ds:[si].RD_bottom
		call	UntransformDWordByGStateOnly
		call	PathBoundMinMax

		; finally, release the block holding the path GString
releasePath:
		pop	bx			; restore memory handle
		call	MemFree			; nuke temp block
		clc				; signal success
exit:
		.leave
		ret

		; if there isn't a path, set the carry and leave.
noPath:
		stc				; all done
		jmp	exit

		; passed GState has rotation.  hurl.
handleRotate:
		call	PathBoundRotate
		jmp	releasePath
GrGetPathBoundsDWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathBoundRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get path bounds when GState has rotation

CALLED BY:	INTERNAL
		GrGetPathBoundsDWord
PASS:		ds:si	- RectDWord
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathBoundRotate	proc	near
topRight	local	PointDWord
bottomLeft	local	PointDWord
		.enter

		; transform first points, copy to other corners

		movdw	dxcx, ds:[si].RD_left
		movdw	bxax, ds:[si].RD_top
		movdw	bottomLeft.PD_x, dxcx
		movdw	topRight.PD_y, bxax
		call	UntransformDWordByGStateOnly
		movdw	ds:[si].RD_left, dxcx
		movdw	ds:[si].RD_top, bxax
		xchgdw	dxcx, ds:[si].RD_right
		xchgdw	bxax, ds:[si].RD_bottom
		movdw	topRight.PD_x, dxcx
		movdw	bottomLeft.PD_y, bxax
		call	UntransformDWordByGStateOnly
		call	PathBoundMinMax

		movdw	dxcx, topRight.PD_x
		movdw	bxax, topRight.PD_y
		call	UntransformDWordByGStateOnly
		call	PathBoundMinMax

		movdw	dxcx, bottomLeft.PD_x
		movdw	bxax, bottomLeft.PD_y
		call	UntransformDWordByGStateOnly
		call	PathBoundMinMax

		.leave
		ret
PathBoundRotate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathBoundMinMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do min/max calculation for path bounds routine

CALLED BY:	INTERNAL
		PathBoundRotate, GrGetPathBoundsDWord
PASS:		ds:si	- RectDWord (current bounds)
		dxcx	- coord.PD_x to test
		bxax	- coord.PD_y to test
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PathBoundMinMax	proc	near
		jgedw	dxcx, ds:[si].RD_left, checkRight
		movdw	ds:[si].RD_left, dxcx
checkRight:
		jledw	dxcx, ds:[si].RD_right, checkTop
		movdw	ds:[si].RD_right, dxcx
checkTop:
		jgedw	bxax, ds:[si].RD_top, checkBottom
		movdw	ds:[si].RD_top, bxax
checkBottom:
		jledw	bxax, ds:[si].RD_bottom, done
		movdw	ds:[si].RD_bottom, bxax
done:
		ret
PathBoundMinMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPathBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the rectangular bounds that encompass the current
		path (as it would be filled).

CALLED BY:	GLOBAL

PASS:		DI	= GState
		AX	= GetPathType

RETURN:		Carry	= Clear (success)
		AX	= Left
		BX	= Top
		CX	= Right
		DX	= Bottom
			- or -
		Carry	= Set (no Path or transformation error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetPathBounds	proc	far
		uses	ds, si
bigRect		local	RectDWord
		.enter

		segmov	ds, ss, bx
		lea	bx, ss:bigRect		; ds:bx -> RectDWord
		call	GrGetPathBoundsDWord	; get them ALL
		jc	noPath			; signal error

		; OK, we have something to work with.   Need to evaluate
		; the returned coords to make sure they are in bounds and
		; round the DWords to words.

		movdw	siax, ss:bigRect.RD_left
		CheckDWordResult si, ax
		jc	exit
		movdw	sibx, ss:bigRect.RD_top
		CheckDWordResult si, bx
		jc	exit
		movdw	sicx, ss:bigRect.RD_right
		CheckDWordResult si, cx
		jc	exit
		movdw	sidx, ss:bigRect.RD_bottom
		CheckDWordResult si, dx
exit:
		.leave
		ret

		; signal error and leave
noPath:
		clr	ax,bx,cx,dx
		stc
		jmp	exit
GrGetPathBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPathPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a series of points that fall along the current Path.
		The points are in document coordinates.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		AX	= Resolution (dots per inch) of points returned.

RETURN:		BX	= Handle of block containing points (or 0 if no path)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetPathPoints	proc	far
	.enter
	
	clr	bx

	.leave
	ret
GrGetPathPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPathRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the Region corresponding to the current Path. The
		Region is expressed in terms of device coordinates. The
		first four words of the Region are its bounds. If a Region
		is returned, it is guaranteed to be non-NULL.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		CL	= RegionFillRule

RETURN:		Carry	= Clear (success)
		BX	= Handle of block containing Region (non-NULL)
			- or -
		Carry	= Set
		BX	= NULL

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetPathRegion	proc	far
	push	ds
	uses	cx
	.enter
	
	; Get a copy of the Region, as long as we're not in the middle
	; of defining a Path or a GString.
	;
EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_A GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
	call	LockDI_DS_checkFar
EC <	jnc	endCheck						>
EC <	ERROR_NZ	GRAPHICS_PATH_CANNOT_WRITE_TO_PATH_WITH_THIS_OP	>
EC <endCheck:								>
	mov	bx, ds:[GS_currentPath]		; Path => *DS:BX
	call	CopyRegionPath			; copy => BX
	call	ConvertRegionPathToRegion	; simple conversion

	.leave
	GOTO	UnlockDI_popDS, ds
GrGetPathRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetClipRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the Region corresponding to the clip Paths. The
		Region is expressed in terms of device coordinates. The
		first 4 words of the Region are its bounds. If a Region is
		returned, it is guaranteed to be non-NULL.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		CL	= RegionFillRule

RETURN:		Carry	= Clear (success)
		BX	= Handle of block containing Region (non-NULL)
			- or -
		Carry	= Set
		BX	= NULL

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetClipRegion	proc	far
	uses	ax, cx
	.enter
	
	; Get a copy of the Region, as long as we're not in the middle
	; of defining a Path or a GString.
	;
EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_A GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
	call	LockDI_DS_checkFar
EC <	jnc	endCheck						>
EC <	ERROR_NZ	GRAPHICS_PATH_CANNOT_WRITE_TO_PATH_WITH_THIS_OP	>
EC <endCheck:								>
	mov	bx, ds:[GS_clipPath]		; Path => *DS:BX
	call	CopyRegionPath			; copy => BX
	xchg	ax, bx				; move handle => AX
	mov	bx, ds:[GS_winClipPath]		; Path *DS:BX
	call	CopyRegionPath			; copy => BX
	tst	ax
	jz	done				; if one empty Region, return
	xchg	ax, bx
	tst	ax
	jz	done				; if one empty Region, return

	; Else we need to merge two clip Regions together. No problem.
	;
	push	dx, es				; save registers
	call	MemLock				; lock RegionPath #1
	mov	es, ax
	xchg	bx, ax				; handle of RegionPath #2 => BX
	mov	ax, mask ROF_AND_OP		; AND the clip regions together
	call	MergeRegions			; resulting region handle => BX
	call	MemUnlock			; unlock the sucker
	xchg	bx, dx
	call	MemFree				; free unused handle
	mov	bx, dx				; resulting handle again => BX
	pop	dx, es				; restore registers
done:
	call	ConvertRegionPathToRegion	; simple conversion

	.leave
	GOTO	UnlockDI_popDS, ds
GrGetClipRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Path utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPathMinMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a path minimum/maximum

CALLED BY:	CalcPathBounds()

PASS:		DI	= GState handle
		(AX,BX)	= Device coordinate
		local	= Point (minimum X & Y)
		CX	= X maximum
		DX	= Y maximum
		
RETURN:		update any of BP, SI, CX, DX

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcPathMinMax	proc	near
minPoint	local	Point
	.enter	inherit

	call	GrUntransform			; corner => (AX, BX)
	jc	done
	cmp	ax, ss:[minPoint].P_x
	jge	top
	mov	ss:[minPoint].P_x, ax
top:
	cmp	bx, ss:[minPoint].P_y
	jge	right
	mov	ss:[minPoint].P_y, bx
right:
	cmp	ax, cx
	jle	bottom
	mov	cx, ax
bottom:
	cmp	bx, dx
	jle	done
	mov	dx, bx
done:
	.leave
	ret
CalcPathMinMax	endp
endif

GraphicsPath	ends
