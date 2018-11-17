COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		nimbusPath.asm

AUTHOR:		Gene Anderson, Jun 20, 1991

ROUTINES:
	Name				Description
	----				-----------
EXT	NimbusGenPath			Generate path for character

INT	MetricsGetCharWidth		Get character width for metrics routines
INT	PathEmitPrologue		Emit bounding box and transformation
INT	PathEmitCharData		Emit character data as gstring
INT	PathEmitEpilogue		Emit clean up for end of character
INT	PathMoveTo			NIMBUS_MOVE handler
INT	PathLineTo			NIMBUS_LINE handler
INT	PathBezierTo			NIMBUS_BEZIER handler
INT	PathCompositeChar		NIMBUS_ACCENT handler
INT	PathVertLineTo			NIMBUS_VERT_LINE handler
INT	PathHorizLineTo			NIMBUS_HORIZ_LINE handler
INT	PathRelLineTo			NIMBUS_REL_LINE handler
INT	PathRelCurveTo			NIMBUS_REL_CURVE handler
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/20/91		Initial revision

DESCRIPTION:
	Routines for generating graphics string of a character.

	$Id: nimbusPath.asm,v 1.1 97/04/18 11:45:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusGenPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a path for the outline of a character
CALLED BY:	DR_FONT_GEN_PATH (via NimbusStrategy)

PASS:		ds - seg addr of font info block
		di - handle of GState (passed in bx, locked)
		dx - character to generate (Chars)
		cl - FontGenPathFlags
			FGPF_POSTSCRIPT - transform for use as Postscript
						Type 1 or Type 3 font.
			FGPF_SAVE_STATE - do save/restore for GState
RETURN:		none
DESTROYED:	ax, bx, di (on the way here)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusGenPath	proc	far
	uses	cx, dx, si, ds, es
locals	local	MetricsLocals
	.enter

if not DBCS_PCGEOS
EC <	tst	dh				;>
EC <	ERROR_NZ CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION ;>
endif
	;
	; Get the character data, style information, and transformation.
	;
	mov	ss:locals.ML_flags, cl		;save flags
	mov	ss:locals.ML_infoSeg, ds	;save seg addr of font info
	mov	cl, dl				;cl <- character
	call	PathFindCharData		;ds:si <- ptr to data
	;
	; Spew data as necessary...
	;
	call	PathEmitPrologue		;write out prologue & tmatrix
	call	PathEmitCharData		;write the character data
	call	PathEmitEpilogue		;write out epilogue

	.leave
	ret
NimbusGenPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusGenInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a character in the passed RegionPath
CALLED BY:	DR_FONT_GEN_IN_REGION (via NimbusStrategy)

PASS:		ds - seg addr of font info block
		di - handle of GState (passed in BX)
		dx - character to generate (Chars)
		cx - RegionPath handle (locked)
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		We want override some of the default functionality for
		build a font's character. Essentially:
			* Always build a character in a region
			* Build this character in the passed region

		We accomplish this by:
			1) Find the character data
			2) Calculate/store the correct transformation
			3) Stuff in some new CharGenRouts
			4) Stuf in the pen position (in device coords)
			5) Go generate the character (via MakeBigCharInRegion)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusGenInRegion	proc	far
	uses	cx, dx, si, ds, es
locals	local	MetricsLocals
	.enter
	
	; Perform some set-up work
	;
	mov	bx, cx				;bx <- RegionPath handle
	call	MemDerefES			;es <- RegionPath segment
	push	es				;save the RegionPath segment
	mov	ss:locals.ML_infoSeg, ds	;save seg addr of font info
	push	ds
	mov	cl, dl				;cl <- character
	call	PathFindCharData		;ds:si <- ptr to data
	mov	cx, bx				;bx <- handle of outline data
	;
	; Get the GState segment
	;
	mov	bx, di				;bx <- handle of GState
EC <	call	ECCheckGStateHandle		;>
	call	MemDerefDS
	push	ds				;save seg addr of GState
	;
	; Stuff the data we need into NimbusVars
	;
	call	LockNimbusVarsFar		;ax <- seg addr, bx <- handle
	mov	ds, ax				;ds <- NimbusVars
	pop	ds:gstateSegment		;store GState segment
	pop	ds:infoSegment			;store info segment
	pop	ds:guano.NB_segment		;store RegionPath segment
	mov	al, ss:locals.ML_firstChar
	mov	ds:firstChar, al		;store first char
	push	bx				;save vars handle

EC <	mov	ds:GenRouts.CGR_xor_func,	offset ECNullNimbusRoutine >
EC <	mov	ds:GenRouts.CGR_bit_func,	offset ECNullNimbusRoutine >
	mov	ds:GenRouts.CGR_alloc_rout,	offset CharInRegionAlloc
EC <	mov	ds:GenRouts.CGR_make_rout,	offset ECNullNimbusRoutine >
EC < 	mov	ds:GenRouts.CGR_resize_rout,	offset ECNullNimbusRoutine >

	call	PathStoreFontMatrix		;transform & store FontMatrix

	call	GrGetCurPos			;(ax, bx) <- pen position
	call	GrTransform			;(ax, bx) <- device coords
	mov	ds:penPos.P_x, ax
	mov	ds:penPos.P_y, bx

	;
	; Finally, we generate the character, and then clean up
	;
	mov	di, si				;es:di <- ptr to outline data
	push	bp				;save local variables
	call	MakeBigCharFar			;generate the character
	pop	bp				;restore local variables
	pop	bx				;bx <- NimbusVars handle
	call	MemUnlock			;unlock NimbusVars block

	.leave
	ret
NimbusGenInRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathFindCharData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find character data for building a path
CALLED BY:	NimbusGenPath()

PASS:		di - handle of GState
		ss:bp - inherited MetricsLocals
			ML_infoSeg - seg addr of font info block
		cl - character  (Chars)
RETURN:		bx - handle of outline data
		ss:bp - inherited MetricsLocals
			ML_fontHeight - height of font
			ML_firstChar - first character in font
			ML_lastChar - last character in font
			ML_defaultChar - default character for font
			ML_fontID - FontID value for font
			ML_styles - TextStyle for font
		ds:si - ptr to data
		es:si - ptr to data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathFindCharData	proc	near
	uses	ax, cx, dx
locals	local	MetricsLocals
	.enter	inherit

	mov	bx, di				;bx <- handle of GState
	push	di				;save handle of GState
	call	MemLock
	mov	es, ax				;es <- seg addr of GState
	call	FindCharData			;get style info & char data
	mov	si, di				;es:si <- ptr to data
	pop	di				;di <- handle of GState
	call	SetupTMatrix			;set up transformation
	push	bx
	mov	bx, di				;bx <- handle of GState
	call	MemUnlock			;unlock the GState
	segmov	ds, es				;ds:si <- ptr to data
	pop	bx				;bx <- handle of data

	.leave
	ret
PathFindCharData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathStoreFontMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiple the current FontMatrix by the Window TMatrix, and
		store the result in the NimbusVars block.
CALLED BY:	NimbusGenInRegion()

PASS:		ds	- NimbusVars segment
		di	- GState handle (locked)
		locals	- MetricsLocals
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathStoreFontMatrix	proc	near
locals	local	MetricsLocals
	uses	cx, dx, di, si, es
	.enter	inherit
	
	; First let's move the FontMatrix into NimbusVars. We need to
	; halve the values, due to how the matrix was first computed.
	;
	movwwf	bxax, ss:locals.ML_tmatrix.TM_11
	sarwwf	bxax				;halve value
	movwwf	ds:GenData.CGD_matrix.FM_11, bxax
	movwwf	bxax, ss:locals.ML_tmatrix.TM_12
	sarwwf	bxax				;halve value
	movwwf	ds:GenData.CGD_matrix.FM_12, bxax
	movwwf	bxax, ss:locals.ML_tmatrix.TM_21
	sarwwf	bxax				;halve value
	; JIM
	negwwf	bxax

	movwwf	ds:GenData.CGD_matrix.FM_21, bxax
	movwwf	bxax, ss:locals.ML_tmatrix.TM_22
	sarwwf	bxax				;halve value
	movwwf	ds:GenData.CGD_matrix.FM_22, bxax

	; Now setup for call to multiply by Window TMatrix
	;
	push	ds				;save NimbusVars segment
	segmov	es, ds				;es <- NimbusVars
	mov	ds, ds:[gstateSegment]		;ds <- seg addr of GState
EC <	mov	bx, ds:[LMBH_handle]		;>
EC <	call	ECCheckGStateHandle		;>


	; before we set up the Window, get the pointsize out of the GState

	movwbf	dxch, ds:[GS_fontAttr].FCA_pointsize
	mov	si, offset GS_TMatrix		; assume no window

	mov	bx, ds:[GS_window]		;bx <- Window handle
	tst	bx				; make it work without a window
	jz	haveMatrix			;  too
EC <	call	ECCheckWindowHandle					>
	call	MemPLock			;lock & own Window
	mov	ds, ax
	mov	si, offset W_curTMatrix		;ds:si <- TMatrix

	; we need to compute the translation amount for the coordinates
	; placed in the region.  Do this before the window transform is
	; applied, but while we have the window locked and handy
haveMatrix:
	push	bx				; save Window handle
	clr	cl				; dxcx = pointsize
	mov	bx, NIMBUS_GRID_SIZE
	clr	ax
	call	GrUDivWWFixed			; dxcx = scaled pointsize
	mov	bx, ss:locals.ML_accent		; acount for height of font
	add	bx, ss:locals.ML_ascent		; ...by adding accent & ascent
	clr	ax
	call	GrMulWWFixed
	movdw	bxax, dxcx			; bxax = scaled baselinePos
	movwwf	dxcx, ds:[si].TM_22
	call	GrMulWWFixed
	rndwwf	dxcx
	mov	di, dx				; di = CGD_heightY
	movwwf	dxcx, ds:[si].TM_21
	call	GrMulWWFixed
	rndwwf	dxcx				; dx = CGD_heightX
	mov	cx, di				; cx = CGD_heightY

	mov	di, offset GenData		;es:di <- CharGenData
	call	PathAddGraphicsTransform	;add the transformation
	pop	bx				; restore Window handle
	tst	bx				; if no window, bail
	jz	winReleased
	call	MemUnlockV			;unlock & release Window
winReleased:
	pop	ds				;ds <- NimbusVars

	mov	ds:GenData.CGD_heightX, dx	; save our hard fought values
	mov	ds:GenData.CGD_heightY, cx

	; Now determine the font height, so that we draw the characters in
	; the region in the correct location. Store result in CGD_height
	;
	; First, we must correct for the fact that
	; our graphics system has y->0 = up.
	;
	negwwf	ds:GenData.CGD_matrix.FM_12
	negwwf	ds:GenData.CGD_matrix.FM_21
	clr	ds:x_offset
	clr	ds:y_offset

	.leave
	ret
PathStoreFontMatrix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathEmitPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emit prologue for character path
CALLED BY:	NimbusGenPath()

PASS:		ss:bp - inherited MetricsLocals
			ML_tmatrix - transformation to apply (TMatrix)
		di - handle of GState
		ds:si - ptr to character data (NimbusData)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	V2.0 CHANGE: TMatrix[3,{1,2}] become DWFixed
	V2.0 CHANGE: TMatrix becomes common with TransMatrix, so get
	rid of the PUSHes.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <offset TM_11 eq offset TM_e11>
CheckHack <offset TM_32 eq offset TM_e32>

PathEmitPrologue	proc	near
	uses	ax, bx, cx, dx, ds, si
locals	local	MetricsLocals
	.enter	inherit

	;
	; Save the current GState so we can hooey with the transformation
	;
	test	ss:locals.ML_flags, mask FGPF_SAVE_STATE
	jz	noSaveState
	call	GrSaveState
noSaveState:
	;
	; Emit a comment with the width and bounding box information.
	; We pass it in the order of the Postscript(tm) setcachedevice
	; command arguments: width(x),width(y),ll(x),ll(y),ur(x),ur(y).
	;
	push	ds:[si].ND_ymax
	push	ds:[si].ND_xmax
	push	ds:[si].ND_ymin
	push	ds:[si].ND_xmin			;pass bounds
	clr	cx
	push	cx				;pass width(y)
	push	ss:locals.ML_charWidth		;pass width(x)
	mov	cx, (size NimbusData)+(size word)*2 ;cx  <- size of data
	mov	si, sp
	segmov	ds, ss				;ds:si <- ptr to data
	call	GrComment
	add	sp, cx				;restore stack
	;
	; Here's the sequence of operation we should need to perform
	; on an arbitrary point in the font outline
	;	1) Transform by font TransMatrix
	;	2) Flip on X-axis (scale by -1 in Y)
	;	3) Translate by font height
	;	4) Translate by current position
	;	5) Transform by current matrix
	;
	; Remember that since the order of matrix multiplication is
	; extremely important, we must perform these transformations
	; in reverse order. Step 5 is, of course, already in the GState.
	;
	call	GrGetCurPos			;(ax, bx) <- current position
	mov	dx, ax				;dx.cx <- x translation
	clr	ax, cx				;bx.ax <- y translation
	call	GrApplyTranslation
	;
	; We only perform steps 2 & 3 if the POSTSCRIPT flag wasn't passed.
	;
	test	ss:locals.ML_flags, mask FGPF_POSTSCRIPT
	jnz	notPostscript
	;
	; We need the font height in terms of the graphics system space,
	; not the outline data space, so we transform it first.
	;
	call	GrGetFont			;dx.ah <- pointsize
	mov	ch, ah
	clr	cl				;dx.cx <- ptsize
	clr	ax
	mov	bx, NIMBUS_GRID_SIZE		;bx:ax <- grid size
	call	GrUDivWWFixed			;dx:cx <- ptsize / grid
	mov	bx, ss:locals.ML_accent		; acount for height of font
	add	bx, ss:locals.ML_ascent		; ...by adding accent & ascent
	clr	ax				;bx.ax <- Y translation
	call	GrMulWWFixed
	movdw	bxax, dxcx			;bx.ax <- y translation
	clrdw	dxcx				;dx.cx <- x translation
	call	GrApplyTranslation
	;
	mov	dx, 1				;x transform is 1.0 (no change)
	mov	bx, dx
	neg	bx				;y transform is -1.0 (flip)
	clr	cx, ax				; fractional parts zero
	call	GrApplyScale	
notPostscript:
	;
	lea	si, ss:locals.ML_tmatrix	;ds:si <- ptr to TransMatrix
	call	GrApplyTransform

	.leave
	ret
PathEmitPrologue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathEmitEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emit epilogue for character path
CALLED BY:	NimbusGenPath()

PASS:		di - handle of GState
		ss:bp - inherited MetricsLocals
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathEmitEpilogue	proc	near
locals	local	MetricsLocals
	.enter	inherit

	;
	; Recover the original GState...
	;
	test	ss:locals.ML_flags, mask FGPF_SAVE_STATE
	jz	noRestoreState
	call	GrRestoreState
noRestoreState:

	.leave
	ret
PathEmitEpilogue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathEmitCharData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emit character data for character path
CALLED BY:	NimbusGenPath()

PASS:		di - handle of GState
		ds:si - ptr to character data (NimbusData)
		ss:bp - inherited MetricsLocals
		bx - handle of outline data
RETURN:		none
DESTROYED:	ds (block unlocked), es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

pathRoutines	nptr \
	PathMoveTo,				;NIMBUS_MOVE
	PathLineTo,				;NIMBUS_LINE
	PathBezierTo,				;NIMBUS_BEZIER
	PathIllegal,				;NIMBUS_DONE
	PathIllegal,
	PathCompositeChar,			;NIMBUS_ACCENT
	PathVertLineTo,				;NIMBUS_VERT_LINE
	PathHorizLineTo,			;NIMBUS_HORZ_LINE
	PathRelLineTo,				;NIMBUS_REL_LINE
	PathRelCurveTo				;NIMBUS_REL_CURVE

pathSizes	word \
	(size NimbusMoveData),			;NIMBUS_MOVE
	(size NimbusLineData),			;NIMBUS_LINE
	(size NimbusBezierData),		;NIMBUS_BEZIER
	0,					;NIMBUS_DONE
	0,
	(size NimbusAccentData),		;NIMBUS_ACCENT
	(size NimbusVertData),			;NIMBUS_VERT_LINE
	(size NimbusHorizData),			;NIMBUS_HORZ_LINE
	(size NimbusRelLineData),		;NIMBUS_REL_LINE
	(size NimbusRelBezierData)		;NIMBUS_REL_CURVE

PathEmitCharData	proc	near
	uses	ax, bx, si
	.enter

	push	bx				;save handle of outline data
	add	si, (size NimbusData)		;skip character header
	call	PathSkipTuples			;skip x tuples
	call	PathSkipTuples			;skip y tuples
commandLoop:
	lodsb					;al <- NimbusCommand
	cmp	al, NIMBUS_DONE			;end of character?
	je	done				;branch if end of character
	clr	bh
	mov	bl, al
	shl	bx, 1				;bx <- command as index
	call	cs:pathRoutines[bx]		;call appropriate routine
	add	si, cs:pathSizes[bx]		;ds:si <- ptr to next command
	cmp	al, NIMBUS_ACCENT		;composite command?
	jne	commandLoop			;branch if not
done:
	pop	bx				;bx <- handle of outline data
	call	MemUnlock			;unlock me jesus

	.leave
	ret
PathEmitCharData	endp

PathIllegal	proc	near
EC  <	ERROR BAD_NIMBUS_COMMAND		;>
NEC <	ret					;>
PathIllegal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathSkipTuples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip over the x or y hint tuples.
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to # of tuples
RETURN:		ds:si - ptr past tuples
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes size(tuple) = 3*size(word) = 6
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(size NimbusTuple) eq 6>

PathSkipTuples	proc	near
	mov	al, ds:[si]
	clr	ah				;ax <- # of triples
	shl	ax, 1
	mov	bx, ax				;bx <- #*2
	shl	ax, 1				;ax <- #*4
	add	ax, bx				;ax <- #*6 = #*3*size(word)
	inc	ax				;one for # of tuples
	add	si, ax				;skip triples
	ret
PathSkipTuples	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_MOVE command as gstring.
CALLED BY:	PathEmitCharData()

PASS:		di - handle of GState
		ds:si - ptr to NimbusMoveData
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathMoveTo	proc	near
	uses	ax, bx
	.enter

	mov	ax, ds:[si].NMD_x
	mov	bx, ds:[si].NMD_y		;(ax,bx) <- (x,y) position
	call	GrMoveTo			;move me jesus

	.leave
	ret
PathMoveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_LINE command as gstring
CALLED BY:	PathEmitCharData()

PASS:		di - handle of GState
		ds:si - ptr to NimbusLineData
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathLineTo	proc	near
	uses	cx, dx
	.enter

	mov	cx, ds:[si].NLD_x
	mov	dx, ds:[si].NLD_y		;(cx,dx) <- (x,y) position
	call	GrDrawLineTo			;draw me jesus

	.leave
	ret
PathLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathBezierTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_BEZIER command as gstring
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to to NimbusBezierData
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	V2.0 CHANGE: When the bug in GrDrawSpline() related to not updating
	the pen position correctly is fixed, the final GrMoveTo() can be
	removed.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathBezierTo	proc	near
	uses	ax, bx, cx, si, es, ds
curve	local	BEZIER_POINTS dup (Point)	;point buffer
	.enter

	push	di
	mov	cx, (size NimbusBezierData)/(size word)
	segmov	es, ss
	lea	di, ss:curve			;es:di <- ptr to 1st point
	rep	movsw				;copy me jesus
	pop	di				;di <- handle of GState
	segmov	ds, ss, si
	lea	si, ss:curve
	call	GrDrawCurveTo

	.leave
	ret
PathBezierTo	endp

if (0)
PathBezierCommon	proc	near
	uses	ax, bx, cx, si, ds
curve	local	BEZIER_POINTS dup (Point)
	.enter	inherit

	call	GrGetCurPos			;(ax,bx) <- current pen pos
	mov	ss:curve[0].P_x, ax
	mov	ss:curve[0].P_y, bx		;set first point
	mov	al, BEZIER_ACCURACY		;al <- accuraccy factor
	mov	cx, BEZIER_POINTS		;cx <- # of points
	segmov	ds, ss
	lea	si, ss:curve			;ds:si <- ptr to points buffer
	call	GrDrawSpline
;	mov	ax, ss:curve[(size Point)*3].P_x
;	mov	bx, ss:curve[(size Point)*3].P_y
;	call	GrMoveTo			;not needed in V2.0

	.leave
	ret
PathBezierCommon	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathCompositeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_ACCENT command as gstring
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to NimbusAccentData
		di - handle of GState
		ss:bp - inherited MetricsLocals
RETURN:		none
DESTROYED:	ds, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathCompositeChar	proc	near
	uses	ax, bx, cx, dx
	.enter	inherit

	push	{word}ds:[si].NAD_char2		;save 2nd char
	push	ds:[si].NAD_y
	push	ds:[si].NAD_x			;save (x,y) offset
	mov	cl, ds:[si].NAD_char1		;cl <- 1st character
	call	PathFindCharData		;ds:si <- ptr to 1st char data
	call	PathEmitCharData
	pop	dx
	clr	cx				;dx.cx <- x offset
	pop	bx
	clr	ax				;bx.ax <- y offset
	call	GrApplyTranslation
	pop	cx				;cl <- 2nd character
	call	PathFindCharData		;ds:si <- ptr to 2nd char data
	call	PathEmitCharData

	.leave
	ret
PathCompositeChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathVertLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_VERT_LINE command as gstring
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to NimbusVertData
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathVertLineTo	proc	near
	uses	ax, bx, cx, dx
	.enter

	call	GrGetCurPos			;(ax,bx) <- current pen pos
	mov	dx, ds:[si].NVD_length
	add	dx, bx				;dx <- y position
	call	GrDrawVLineTo

	.leave
	ret
PathVertLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathHorizLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_HORZ_LINE command as gstring
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to NimbusHorizData
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathHorizLineTo	proc	near
	uses	ax, bx, cx
	.enter

	call	GrGetCurPos			;(ax,bx) <- current pen pos
	mov	cx, ds:[si].NHD_length		;cx <- length
	add	cx, ax				;cx <- x position
	call	GrDrawHLineTo

	.leave
	ret
PathHorizLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathRelLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_REL_LINE command as gstring
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to NimbusRelLineData
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathRelLineTo	proc	near
	uses	ax, bx, cx, dx
	.enter

if (0)
	call	GrGetCurPos			;(ax,bx) <- current pen pos
	mov	cx, ax
	mov	dx, bx				;(cx,dx) <- current pen pos
	mov	al, ds:[si].NRLD_x
	cbw					;ax <- x offset
	add	cx, ax				;cx <- x position
	mov	al, ds:[si].NRLD_y
	cbw					;ax <- y offset
	add	dx, ax				;dx <- y position
	call	GrDrawLineTo
endif

	mov	al, ds:[si].NRLD_x
	cbw
	mov	dx, ax
	mov	al, ds:[si].NRLD_y
	cbw					;ax <- y offset
	mov	bx, ax
	clr	ax, cx
	call	GrDrawRelLineTo

	.leave
	ret
PathRelLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathRelCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw NIMBUS_REL_CURVE command as gstring
CALLED BY:	PathEmitCharData()

PASS:		ds:si - ptr to NimbusRelBezierData
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <offset NRBD_x1 eq offset NRBD_y1+1>

PathRelCurveTo	proc	near
	uses	ax, bx, cx, dx, si, ds
curve	local	BEZIER_POINTS dup (Point)	;point buffer
	.enter

;	call	GrGetCurPos			;(ax,bx) <- (x,y) pos
	push	di

;	mov	dx, ax				;(dx,bx) <- (x,y) pos
	mov	cx, (size NimbusRelBezierData)/((size NRBD_x1)+(size NRBD_y1))
	clr	di				;di <- offset of 1st point
	clr	bx, dx
pointLoop:
	lodsb					;al <- y offset
	cbw
	add	bx, ax				;bx <- y position
	mov	ss:curve[di].P_y, bx
	lodsb					;al <- x offset
	cbw
	add	dx, ax				;dx <- x position
	mov	ss:curve[di].P_x, dx
	add	di, (size Point)		;di <- offset of next point
	loop	pointLoop

	pop	di				;di <- handle of GState
	segmov	ds, ss
	lea	si, ss:curve			;ds:si <- ptr to points buffer
	call	GrDrawRelCurveTo

	.leave
	ret
PathRelCurveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MetricsGetCharWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get width of character given locked header
CALLED BY:	FindCharData()

PASS:		es - seg addr of NewFontHeader
		cl - character to get (Chars)
		dh - default character (Chars)
		al, ah - first, last character (Chars)
RETURN:		si - width of character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(size NewWidth) eq 3>

MetricsGetCharWidth	proc	near
	uses	cx
	.enter

	;
	; Check for character out of bounds
	;
	cmp	cl, al				;before first?
	jb	charMissing
	cmp	cl, ah				;after last?
	ja	charMissing
afterMissing:
	sub	cl, al				;cl <- character index
	clr	ch
	mov	si, cx				;si <- character
	shl	si, 1
	add	si, cx				;si <- char * (size NewWidth)
	add	si, (size NewFontHeader)	;es:si <- ptr to NewWidth entry
	;
	; See if the character has data, and get its width if it does...
	;
	test	es:[si].NW_flags, mask CTF_NO_DATA
	jnz	charMissing			;branch if no data
	mov	si, es:[si].NW_width		;si <- width of character

	.leave
	ret

charMissing:
	mov	cl, dh				;cl <- default character
	jmp	afterMissing
MetricsGetCharWidth	endp
