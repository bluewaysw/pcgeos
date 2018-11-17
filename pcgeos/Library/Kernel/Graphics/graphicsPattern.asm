COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics	
FILE:		graphicsPattern.asm

AUTHOR:		Don Reeves, Mar 16, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/16/92		Initial revision


DESCRIPTION:
	Contains the implementation of hatch patterns in PC/GEOS.	

	$Id: graphicsPattern.asm,v 1.1 97/04/05 01:13:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Several assumptions that are made in multiple locations
;
CheckHack		<PT_SOLID  eq 0>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Global graphics-system calls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsSemiCommon	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetAreaPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the fill pattern for areas

CALLED BY:	GLOBAL

PASS:		DI	= GState
		AL	= PatternType
		AH	= Data (see PatternType definition)
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				CX	= Size of HatchPattern/Bitmap
				DX:SI	= HatchPattern/Bitmap

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetAreaPattern	proc	far
		uses	bx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		cmp	al, PT_CUSTOM_HATCH		> 
EC <		jb	xipOK				>
EC <		mov	bx, dx				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <xipOK:						>
endif		
		; Store the pattern information
		;
		mov	bx, offset GS_areaPattern
		call	SetPatternCommon

		.leave
		ret
GrSetAreaPattern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPatternCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the common work of setting a pattern

CALLED BY:	GrSetAreaPattern(), GrSetTextPattern()

PASS:		DI	= GState handle
		BX	= Offset to GrCommonPattern in GState
		AL	= PatternType
		AH	= Data (see PatternType definition)
		AX	= PatternInfo
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				CX	= Size of HatchPattern/Bitmap
				DX:SI	= HatchPattern/Bitmap

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We store the custom HatchPattern or Bitmap in a chunk
		in the GState; hence we limit the size of the Bitmap
		(& HatchPattern, though one should never get that big)
		to 16K (MAX_CUSTOM_PATTERN_SIZE)

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPatternCommon	proc	far
		uses	ax, cx, dx, ds
		.enter
	
		; Store the information away
		;
EC <		call	ECCheckPatternInfo	; check passed info	>
		call	LockDI_DS_checkFar
		jc	doGString

		; Normal drawing operation, so go for it
		;
		cmp	al, PT_CUSTOM_HATCH
		jae	newPattern		; if custom, must always reset
		cmp	{word} ds:[bx].GCP_pattern, ax
		jne	newPattern
done:
		mov	bx, di			; GState handle => BX
		call	MemUnlock		; unlock the GState

		.leave
		ret

newPattern:
		call	SetPatternComplex
		jmp	done

doGString:
		call	SetPatternGString
		jmp	done

SetPatternCommon	endp

GraphicsSemiCommon ends

;---

GraphicsPattern segment resource

SetPatternComplex	proc	far
		mov	{word} ds:[bx].GCP_pattern, ax
		clr	ax
		xchg	ax, ds:[bx].GCP_custom	; get old handle, set to NULL
		tst	ax
		jz	freeDone		; if NULL, don't free anything
		call	LMemFree		; free existing chunk
freeDone:
		cmp	ds:[bx].GCP_pattern, PT_SOLID
		je	done

		; Now copy the pattern into a chunk in the GState
		;
		push	di, si, es
		call	PatternLock		; pattern => DX:SI, size => CX
		call	LMemAlloc		; chunk handle => AX
		mov	ds:[bx].GCP_custom, ax	; store handle of custom pattern
		mov_tr	di, ax
		segmov	es, ds, ax
		mov	di, es:[di]		; storage location => ES:DI
		mov	ds, dx			; custom pattern => DS:SI
		rep	movsb			; copy the sucker
		call	PatternUnlock		; unlock pattern, if necessary
		pop	di, si, es
done:
		ret

SetPatternComplex	endp

;---

SetPatternGString	proc	far

		; Deal with a GString or Path

		jnz	gstringExit		; if Path, do nothing
		xchg	ax, bx			; GraphicPattern => BX
		cmp	ax, offset GS_textPattern
		mov	al, GR_SET_TEXT_PATTERN
		je	writeOpcode
		mov	al, GR_SET_AREA_PATTERN
writeOpcode:
		push	ds			; save GState segment
		mov	ds, dx			; custom pattern => DS:SI
		mov	dx, cx			; size (if custom) => DX
		mov	cl, (size OpSetAreaPattern) - 1
		cmp	bl, PT_CUSTOM_HATCH	; custom pattern ??
		jb	storeBytes		; if not custom, write bytes
		inc	al
		mov	cl, (size OpSetCustomAreaPattern) - 1
storeBytes:
		cmp	bl, PT_CUSTOM_HATCH	; custom pattern ??
		jae	storeCustom		;  yes, other code needed
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; store the bytes now
gstringDone:
		pop	ds			; restore GState segment
gstringExit:
		mov	di, ds:[LMBH_handle]	; GState handle => DI
		ret				; we're outta here

		; store a custom pattern
storeCustom:
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; store the bytes now
		mov	cx, dx			; custom size => CX
		mov	ax, (GSSC_FLUSH shl 8) or 0xff
		call	GSStore			; store the custom pattern
		jmp	gstringDone

SetPatternGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the fill pattern for text

CALLED BY:	GLOBAL

PASS:		DI	= GState
		AL	= PatternType
		AH	= Data (see PatternType definition)
		AX	= PatternInfo
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				CX	= Size of HatchPattern/Bitmap
				DX:SI	= HatchPattern/Bitmap

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextPattern	proc	far
		uses	bx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		cmp	al, PT_CUSTOM_HATCH		> 
EC <		jb	xipOK				>
EC <		mov	bx, dx				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <xipOK:						>
endif		
		; Store the pattern information
		;
		mov	bx, offset GS_textPattern
		call	SetPatternCommon

		.leave
		ret
GrSetTextPattern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a pattern down, returning a pointer to it.

CALLED BY:	PatternDraw()

PASS:		DS:BX	= GrCommonPattern

RETURN:		DX:SI	= HatchPattern or Bitmap
		CX	= Size of Pattern

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternLock	proc	near
		.enter
	
		; Find the pattern the user has selected, and go for it
		;
EC <		cmp	ds:[bx].GCP_pattern, PT_SOLID			>
EC <		ERROR_E	GRAPHICS_PATTERN_INTERNAL_CANT_BE_SOLID_HERE	>
		cmp	ds:[bx].GCP_pattern, PT_CUSTOM_HATCH
		jae	done			; if custom, don't do anything

		; We have a system pattern, so lock it down
		;
		push	ax, bx, ds
		mov	cx, {word} ds:[bx].GCP_pattern
		xchg	ch, cl			; PatternType => CH, data => CL
		clr	ax			; system bitmaps are first
		mov	bx, handle SystemBitmapsAndHatches
		test	ch, 0x1	
		jz	common			; if bitmap, jump
		mov	ax, SystemBitmap	; skip over system bitmaps

		; Lock the resource, and get pointer to pattern
common:
		cmp	ch, PT_USER_HATCH
		jae	userPattern
		clr	ch
		add	cx, ax			; pattern => CX		
		call	MemLock			; lock the pattern resource
		mov	ds, ax			; resource segment => DS
EC <		cmp	cx, ds:[SPLMBH_numPatterns]			>
EC <		ERROR_AE GRAPHICS_PATTERN_ILLEGAL_SYSTEM_PATTERN	>
		shl	cx, 1	
		mov	si, cx			; pattern offset => SI
		mov	si, ds:[SPLMBH_patterns][si]
		mov	si, ds:[si]		; HatchPattern/Bitmap => DS:SI
		ChunkSizePtr	ds, si,cx	; size of pattern => CX
		mov_tr	dx, ax			; pattern => DX:SI
		pop	ax, bx, ds		
done:
		.leave
		ret

		; Deal with a user HatchPattern or Bitmap
userPattern:
EC  <		ERROR	GRAPHICS_USER_PATTERNS_NOT_SUPPORTED_YET	>
NEC <		jmp	done						>
PatternLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a pattern after it's been used

CALLED BY:	PatternDraw()

PASS:		ES:BX	= GrCommonPattern
		DS	= Segment of pattern (system or custom)

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternUnlock	proc	near
		.enter
	
		; Unlock the pattern, & dereference the GState handle
		;
		cmp	ds:[bx].GCP_pattern, PT_CUSTOM_HATCH
		jae	done			; if custom, don't do anything
		mov	bx, ds:[LMBH_handle]	; resource handle => BX
		call	MemUnlock		; unlock resource
done:
		.leave
		ret
PatternUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetAreaPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the fill pattern for areas

CALLED BY:	GLOBAL

PASS:		DI	= GState

RETURN:		AL	= PatternType
		AH	= Data (see PatternType definition)
		AX	= PatternInfo
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				BX	= Block holding HatchPattern/Bitmap
				CX	= Size of HatchPattern/Bitmap

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetAreaPattern	proc	far

		; Goto common routine to get the values
		;
		push	si
		mov	si, offset GS_areaPattern
		GOTO	GetPatternCommon, si
GrGetAreaPattern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the fill pattern for text

CALLED BY:	GLOBAL

PASS:		DI	= GState

RETURN:		AL	= PatternType
		AH	= Data (see PatternType definition)
		AX	= PatternInfo
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				BX	= Block holding HatchPattern/Bitmap
				CX	= Size of HatchPattern/Bitmap

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetTextPattern	proc	far

		; Goto common routine to get the values
		;
		push	si
		mov	si, offset GS_textPattern
		FALL_THRU	GetPatternCommon, si
GrGetTextPattern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPatternCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pattern defined by the user.

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= Offset to GrCommonPattern in GState

RETURN:		AL	= PatternType
		AH	= Data (see PatternType definition)
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				BX	= Block holding HatchPattern/Bitmap
				CX	= Size of HatchPattern/Bitmap

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPatternCommon	proc	far
		uses	dx, ds
		.enter
	
		; Lock the GState, and get some information
		;
		mov	dx, bx			; data in BX => DX
		mov	bx, di			; GState handle => BX
		call	MemLock		
		mov	ds, ax			; GState segment => DS
		mov	ax, {word} ds:[si].GCP_pattern
		cmp	al, PT_USER_BITMAP	; last pre-defined pattern
		jbe	done			; if so, then we're done

		; We have a custom pattern, so allocate a block to hold
		; the information, and copy it over.
		;
		push	ax, di, es
		mov	si, ds:[si].GCP_custom
		mov	si, ds:[si]		; HatchPattern or Bitmap =>DS:SI
		push	ax
		ChunkSizePtr	ds, si, ax	; size of custom pattern => AX
		mov	cx, (ALLOC_DYNAMIC or \
			    (HAF_STANDARD_NO_ERR_LOCK shl 8))
		call	MemAllocFar		;
		mov	es, ax
		clr	di			; destination => ES:DI
		pop	cx			; # of bytes => CX
		mov	dx, cx
		rep	movsb			; copy the bytes
		mov	cx, dx			; size of custom pattern => CX
		mov	dx, bx			; handle holding pattern => DX
		pop	ax, di, es
done:
		call	MemUnlock		; unlock the GState
		mov	bx, dx			; returned data => BX

		.leave
		FALL_THRU_POP	si
		ret
GetPatternCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		External graphics-system calls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the area bounded by the current clip path (still being
		defined) with the pattern stored in the GState.

CALLED BY:	ExitGraphicsFill()

PASS:		DI	= GState handle (unlocked)
		DL	= RegionFillRule (only used for filling polygons)

RETURN:		Nothing

DESTROYED:	DX

PSEUDO CODE/STRATEGY:
		* Complete the path definition
		* Set the clip path
		* Draw the pattern

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The GState's transformation matrix & area attributes
		may be changed, and are not restored.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternFill	proc	far
	
		; Finish defining the path, and set the clip path
		;
		push	ax, cx
		call	GrEndPath
		call	PathGetPatternInfo	; RegionFillRule => DL
						; GrCommonPattern (offset) => AX
		mov	cx, PCT_INTERSECTION	; AND with existing, if any
		call	GrSetClipPath		; set the clip path
		mov_tr	dx, ax			; GrCommonPattern (offset) => DX
		pop	ax, cx

		; Now we actually fill the area with a pattern.
PatternFillLow	label	far
		call	EnterGraphics
		call	TrivialRejectFar
		mov	si, dx			; GrCommonPattern (offset) => SI
		mov	di, ds:[LMBH_handle]	; GState handle => DI
		mov	bp, sp
		sub	sp, size PatternInfo
EC <		cmp	ds:[si].GCP_pattern, PT_SOLID			>
EC <		ERROR_E	GRAPHICS_PATTERN_INTERNAL_CANT_BE_SOLID_HERE	>
		mov	ax, offset PatternDrawBitmap
		test	ds:[si].GCP_pattern, 0x1	
		jz	fill			; if bitmap, jump
		mov	ax, offset PatternDrawHatch
fill:
		mov	si, ds:[si].GCP_custom	; chunk handle => SI
		mov	si, ds:[si]		; csutom pattern => DS:SI
		call	ax			; call proper pattern generator
		mov	sp, bp
		jmp	ExitGraphics		; return to caller
PatternFill	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Hatch Pattern Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternDrawHatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a hatch pattern

CALLED BY:	PatternDraw()

PASS:		DS:SI	= HatchPattern
		ES	= Window segment
		DI	= GState handle

RETURN:		ES	= Window segment (updated)

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternDrawHatch	proc	near
patternInfo	local	PatternInfo
		.enter	inherit
	
		; Loop through all the lines in the pattern, drawing each
		;
EC <		call	ECCheckHatchPattern				>
		mov	cx, ds:[si].HP_numLines
		add	si, offset HP_lineData	; DS:SI => HatchLine
lineLoop:
		call	HatchDrawLine
		loop	lineLoop

		.leave
		ret
PatternDrawHatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HatchDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single hatch line repeatdly

CALLED BY:	HatchDraw()

PASS:		ES	= Window segment
		DI	= GState handle
 		DS:SI	= HatchLine

RETURN:		ES	= Window segment (may have changed)
		DS:SI	= Next HatchLine

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HatchDrawLine	proc	near
patternInfo	local	PatternInfo
		uses	ax, bx, cx, dx
		.enter	inherit
	
		; First perform some set-up work. We clear the GS_window
		; field to avoid deadlock in ExitTransform. Nothing is
		; accessing the window other than this, and we recompose
		; the Window's TMatrix when we're done, so this should be OK
		;
		push	es:[LMBH_handle]	; save Window handle
		push	ds
		mov	bx, di
		call	MemDerefDS
		clr	ds:[GS_window]
		pop	ds

		; Initialize the transformation matrix
		;
		call	GrSetNullTransform
		movwwf	dxcx, ds:[si].HL_origin.PF_x
		movwwf	bxax, ds:[si].HL_origin.PF_y
		call	GrApplyTranslation	; translate origin
		movwwf	dxcx, ds:[si].HL_angle
		call	GrApplyRotation		; rotate line
		mov	ax, {word} ds:[si].HL_color.CQ_redOrIndex
		cmp	ah, CF_SAME
		je	finishInit
		mov	bx, {word} ds:[si].HL_color.CQ_green
		call	GrSetAreaColor

		; Complete the initialization work
finishInit:
		pop	bx			; Window handle => BX
		call	MemDerefES		; Window segment => ES
		mov	ax, bx
		push	ds
		mov	bx, di
		call	MemDerefDS
		mov	ds:[GS_window], ax	; reset the Window handle
		call	GrComposeMatrixFar	; compose Window matrix
		mov	ds:[GS_lineEnd], LE_SQUARECAP
		call	PatternCalcFillBounds	; calculate the fill bounds
		pop	ds
		jc	done			; if error, don't draw

		; Compute the line length (sum of dash lengths)
		;
		clr	ax, dx			; running total => DX.AX
		mov	bx, offset HL_dashData
		mov	cx, ds:[si].HL_numDashes
		jcxz	storeLength
		shl	cx, 1			; # of WWFixed values => CX
nextDash:
		addwwf	dxax, ds:[si][bx]
		add	bx, size WWFixed
		loop	nextDash
storeLength:
		movwwf	ss:[patternInfo].PI_lineLength, dxax
		push	bx			; save size of HatchLine

		; Now find where we should start drawing
		;
		clr	ax, bx, cx, dx		; startX=>DX.AX, startY=>BX.CX
		call	HatchCheckY		

		; Repeatedly draw a single occurrence of the line
nextLine:
		call	HatchCheckX
		call	HatchDoLine
		addwwf	dxax, ds:[si].HL_deltaX
		addwwf	bxcx, ds:[si].HL_deltaY
		cmp	bx, ss:[patternInfo].PI_fillBounds.R_bottom
		jle	nextLine
		call	HatchCheckX		; draw one last line to ensure
		call	HatchDoLine		; ...the area is covered
		pop	ax			; size of HatchLine => AX
		add	si, ax			; next HatchLine => DS:SI
done:
		.leave
		ret
HatchDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HatchDoLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single line, possible consisting of multiple dash pairs

CALLED BY:	HatchDrawLine()

PASS: 		ES	= Window segment
		DI	= GState handle
		DS:SI	= HatchLine
		DX.AX	= X position
		BX.CX	= Y position
		local	= PatternInfo.PI_fillBounds

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HatchDoLine	proc	near
patternInfo	local	PatternInfo
		uses	ax, bx, cx, dx
		.enter	inherit
	
		; First see if we have a solid line. If so, do it
		;
		movwwf	ss:[patternInfo].PI_yPos, bxcx
		tst	ds:[si].HL_numDashes
		jnz	repeatDashes
		mov	bx, ss:[patternInfo].PI_fillBounds.R_right
		clr	cx
		call	HatchDrawLineSegment
done:
		.leave
		ret

		; We have a dashed line. Go for it.
repeatDashes:
		mov	cx, ds:[si].HL_numDashes
		clr	bx
nextDash:
		push	cx, bx			; HatchDash offset, count
		mov	cx, ds:[si].HL_dashData[bx].HD_on.WWF_frac
		mov	bx, ds:[si].HL_dashData[bx].HD_on.WWF_int
		addwwf	bxcx, dxax		; ending position => BX.CX
		call	HatchDrawLineSegment	; draw the line segment
		movwwf	dxax, bxcx
		pop	bx			; restore HatchDash offset
		addwwf	dxax, ds:[si].HL_dashData[bx].HD_off
		pop	cx			; restore dash pair count
		cmp	dx, ss:[patternInfo].PI_fillBounds.R_right
		jg	done
		add	bx, size HatchDash	; go to next dash pair
		loop	nextDash		; continue until done
		jmp	repeatDashes
HatchDoLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HatchDrawLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single line segment that is part of a hatch pattern

CALLED BY:	HatchDoLine

PASS:		ES	= Window segment
		DI	= GState handle
		DX.AX	= Starting X position
		BX.CX	= Ending X position
		local	= PatternInfo.PI_yPos

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HatchDrawLineSegment	proc	near
patternInfo	local	PatternInfo
		uses	ax, bx, cx, dx, di, si, ds
		.enter	inherit
	
		; Some set-up work
		;
		segmov	ds, es, si		; Window segment => DS
		push	di			; save GState handle
		mov	di, bx
		mov	si, cx			; ending X position => DI.SI

		; Transform the two pairs of points
		;
		mov	cx, ax			; starting X => DX.CX
		movwwf	bxax, ss:[patternInfo].PI_yPos
		push	si
		mov	si, offset W_curTMatrix	; TMatrix => DS:SI
		call	TransCoordFixed		; transform starting point
		pop	si
		rndwwf	dxcx			; starting X position => DX
		rndwwf	bxax, cx		; starting Y position => CX
		xchg	dx, di			; start => (DI, SI)
		xchg	cx, si			; ending X position => DX.CX
		movwwf	bxax, ss:[patternInfo].PI_yPos
		push	si
		mov	si, offset W_curTMatrix	; TMatrix => DS:SI
		call	TransCoordFixed		; transform ending point
		pop	si
		rndwwf	dxcx			; ending X position => DX
		rndwwf	bxax			; ending Y position => BX

		; Now call the video driver
		;
		mov	cx, dx
		mov	dx, bx			; end => (CX, DX)
		pop	bx			; GState handle => BX
		call	MemDerefDS		; GState segment => DS
		mov	ax, di
		mov	bx, si			; start => (AX, BX)
		mov	si, offset GS_areaAttr
		mov	di, DR_VID_LINE
		push	bp
		call	es:[W_driverStrategy]	; call the video driver
		pop	bp
		
		.leave
		ret
HatchDrawLineSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HatchCheckX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the X position is left of the object we're filling

CALLED BY:	HatchDrawLine()

PASS: 		DX.AX	= X position
		local	= PatternInfo.PI_fillBounds
			= PatternInfo.PI_lineLength

RETURN:		DX.AX	= X position (updated if necessary)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HatchCheckX	proc	near
patternInfo	local	PatternInfo
		uses	bx, cx, di
		.enter	inherit
	
		; Check for too large or small
		;
		movwwf	bxcx, ss:[patternInfo].PI_lineLength
		mov	di, ss:[patternInfo].PI_fillBounds.R_left
		tstwwf	bxcx			; if zero line length, then
		jz	solidLine		; ...we don't need to worry
		cmp	dx, di			; check against left bounds
		jge	moveLeft

		; Move the start point to the right. We actually go past
		; where we want to be, and then back up.
moveRight:
		addwwf	dxax, bxcx
		cmp	dx, di			; check against left bounds
		jl	moveRight		; while left, keep looping
		mov	di, MAX_COORD		; absolute maximum => DI

		; Move the start point to the left
moveLeft:
		subwwf	dxax, bxcx
		cmp	dx, di			; check against left bounds
		jge	moveLeft		; while right, keep looping
done:
		.leave
		ret

		; We have a solid line, so start drawing it from the left
solidLine:
		mov	dx, di
		mov	ax, cx			; CX is zero, so left => DX.AX
		jmp	done
HatchCheckX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HatchCheckY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the Y position is above the object we're filling

CALLED BY:	HatchDrawLine()

PASS:		DS:SI	= HatchLine
		DX.AX	= X position
		BX.CX	= Y position
		local	= PatternInfo.PI_fillBounds

RETURN:		DX.AX	= X position (updated if necessary)
		BX.CX	= Y position (updated if necessary)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HatchCheckY	proc	near
patternInfo	local	PatternInfo
		uses	di
		.enter	inherit
	
		; Check for too large or small
		;
		mov	di, ss:[patternInfo].PI_fillBounds.R_top
		cmp	bx, di			; check against top bounds 
		jge	moveUp

		; Move the start point down. We actually go past where we
		; want to be, and then back up.
moveDown:
		addwwf	dxax, ds:[si].HL_deltaX
		addwwf	bxcx, ds:[si].HL_deltaY
		cmp	bx, di			; check against top bounds 
		jl	moveDown		; while above, keep looping
		mov	di, MAX_COORD		; absolute maximum => DI

		; Move the start point up
moveUp:
		subwwf	dxax, ds:[si].HL_deltaX
		subwwf	bxcx, ds:[si].HL_deltaY
		cmp	bx, di			; check against top bounds 
		jge	moveUp			; while below, keep looping

		.leave
		ret
HatchCheckY	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bitmap Pattern Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Repeatedly draw a bitmap to fill an area.

CALLED BY:	PatternDraw()

PASS:		DS:SI	= Bitmap
		ES	= Window segment
		DI	= GState segment

RETURN:		ES	= Window segment (updated)

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternDrawBitmap	proc	near
patternInfo	local	PatternInfo
		.enter	inherit
	
		; Draw the bitmap now
		;
EC <		call	ECCheckBitmap		; check for validity	>
		call	PatternCalcFillBounds	; calculate fill bounds
		jc	done			; if error, don't draw
		mov	bx, es:[LMBH_handle]	; Window handle => BX
		call	MemUnlockV		; unlock & release window
		push	bx			; save Window handle
		call	GrGetBitmapSize		; size (points) => (AX, BX)
		call	BitmapCalcStartPos	; origin => (AX, BX)
						; columns => CX, rows => DX

		; Now draw the bitmap repeatedly to fill the area
rowLoop:
		push	ax, cx			; save left side, column count
columnLoop:
		call	GrDrawBitmap
		add	ax, ss:[patternInfo].PI_bmWidth
		loop	columnLoop
		add	bx, ss:[patternInfo].PI_bmHeight
		pop	ax, cx			; restore left side, # columns
		dec	dx			; decrement row count
		jnz	rowLoop			; and loop until we're done

		; Clean up & exit
		;
		pop	bx			; Window handle => BX
		call	MemPLock		; lock & own Window
		mov	es, ax			; Window segment => DS
done:
		.leave
		ret
PatternDrawBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCalcStartPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the starting position for tiling a bitmap to
		fill an area.

CALLED BY:	PatternDrawBitmap()

PASS:		local	= PatternInfo
		AX	= Width
		BX	= Height

RETURN:		(AX,BX)	= Starting position
		CX	= # of columns across
		DX	= # of rows down
		local	= PatternInfo.PI_bmWidth
			  PatternInfo.PI_bmheight

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapCalcStartPos	proc	near
patternInfo	local	PatternInfo
		uses	si
		.enter	inherit
	
		; Some set-up work
		;
		mov	ss:[patternInfo].PI_bmWidth, ax
		mov	ss:[patternInfo].PI_bmHeight, bx

		; Find the starting X & Y positions
		;
		mov	dx, ax			; width => DX
		mov	cx, bx			; height => CX
		mov	si, ss:[patternInfo].PI_fillBounds.R_top
		call	BitmapCalcStart		; top position => AX
		mov	si, ss:[patternInfo].PI_fillBounds.R_bottom
		call	BitmapCalcExtent	; # of rows => CX
		mov	bx, ax			; starting.Y => BX
		xchg	cx, dx			; rows => DX, width => CX
		mov	si, ss:[patternInfo].PI_fillBounds.R_left
		call	BitmapCalcStart		; left position => AX
		mov	si, ss:[patternInfo].PI_fillBounds.R_right
		call	BitmapCalcExtent	; # of columns => CX

		.leave
		ret
BitmapCalcStartPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCalcStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the starting position in one dimmension

CALLED BY:	BitmapCalcStartPos()

PASS: 		CX	= Size of bitmap (width or height)
		SI	= Bounds edge

RETURN:		AX	= Starting position

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapCalcStart	proc	near
		uses	dx
		.enter
	
		; Call utility routine to do the real work
		;
		clr	ax
		call	BitmapCalcLow		; starting position => AX

		.leave
		ret
BitmapCalcStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCalcExtent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the extent of the area we need to fill, measured
		in multiples of the size passed.

CALLED BY:	BitmapCalcStartPos()

PASS:		AX	= Starting position
		CX	= Size of bitmap (width or height)
		SI	= Bounds edge

RETURN:		CX	= # of multiples (rows or columns)

DESTROYED:	SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapCalcExtent	proc	near
		uses	ax, dx
		.enter
	
		; Call utility routine to do the real work
		;
		add	si, cx			; force coverage of entire area
		call	BitmapCalcLow		; rows or columns => DX
		mov	cx, dx

		.leave
		ret
BitmapCalcExtent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCalcLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate how many times a bitmap needs to be tiled to come
		near the passed bounds, and where that final postion lies.

CALLED BY:	BitmapCalcStart(), BitmapCalcExtent()

PASS:		AX	= Starting position
		CX	= Size of bitmap (width or height)
		SI	= Bounds

RETURN:		AX	= Position near bounds
		DX	= # of rows or columns need to fill area

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		We always choose to come closest to a boundary with
		the *smallest* integer-position possible. Hence, if
		passed:
			AX = 0  (start)		AX = 0
			CX = 10 (size)		CX = 10
			SI = 50 (boundary)	SI = -50
		we would return:
			AX = 40			AX = -60
			DX = 2			DX = 3

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapCalcLow	proc	near
		.enter
	
		; Keep adding or subtracting until we're done
		;
		clr	dx
		cmp	ax, si
		je	done
		jg	subtractLoop
addLoop:
		inc	dx
		add	ax, cx
		cmp	ax, si
		jle	addLoop
		dec	dx
subtractLoop:
		inc	dx
		sub	ax, cx
		cmp	ax, si
		jg	subtractLoop
done:
		.leave
		ret
BitmapCalcLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Common Pattern Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternCalcFillBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the fill bounds based on the area bounds &
		the current transformations applied.

CALLED BY:	HatchDrawLine()

PASS: 		ES	= Window segment (W_maskRect valid)

RETURN:		local	= PatternInfo.PI_fillBounds
		Carry	= Clear
			- or -
		Carry	= Set (no bounds to fill)

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternCalcFillBounds	proc	near
patternInfo	local	PatternInfo
		uses	di, si, ds
		.enter	inherit
	
		; Setup for some reverse transformations
		;
		segmov	ds, es, ax
		mov	cx, MAX_COORD		; left
		mov	dx, cx			; top
		mov	di, MIN_COORD		; right
		mov	si, di			; bottom

		; Untransform all four corners, and find extrema
		;
		mov	ax, es:[W_maskRect].R_left
		mov	bx, es:[W_maskRect].R_top
		cmp	ax, EOREGREC
		stc				; assume error 
		je	done			; NULL bounds, so don't draw
		call	PatternFindExtrema	; upper-left
		mov	ax, es:[W_maskRect].R_right
		call	PatternFindExtrema	; upper-right
		mov	bx, es:[W_maskRect].R_bottom
		call	PatternFindExtrema	; lower-right
		mov	ax, es:[W_maskRect].R_left
		call	PatternFindExtrema	; lower-left

		; Now store the extrema in the PatternInfo
		;
		mov	ss:[patternInfo].PI_fillBounds.R_left, cx
		mov	ss:[patternInfo].PI_fillBounds.R_top, dx
		mov	ss:[patternInfo].PI_fillBounds.R_right, di
		mov	ss:[patternInfo].PI_fillBounds.R_bottom, si
		clc
done:		
		.leave
		ret
PatternCalcFillBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatternFindExtrema
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find any extrema, after un-transforming the passed corner

CALLED BY:	PatternCalcFillBounds()

PASS:		DS	= Window segment
		(AX,BX)	= Corner (device coords)
		CX	= Minimum X
		DX	= Minimum Y
		DI	= Maximum X
		SI	= Maximum Y

RETURN:		Minimums & maximums updated, if appropriate

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PatternFindExtrema	proc	near
		uses	ax, bx
		.enter

		push	si			; save maximum Y
		mov	si, offset W_curTMatrix	; TMatrix => DS:SI
		call	UnTransCoordCommonFar	; lower-right => (AX, BX)
		pop	si			; restore maximum Y
		jc	done			; if overflow, ignore result
		cmp	ax, cx
		jl	minX
checkMaxX:
		cmp	ax, di
		jg	maxX
checkMinY:
		cmp	bx, dx
		jl	minY
checkMaxY:
		cmp	bx, si
		jg	maxY
done:
		.leave
		ret

minX:
		mov	cx, ax
		jmp	checkMaxX
maxX:
		mov	di, ax
		jmp	checkMinY
minY:
		mov	dx, bx
		jmp	checkMaxY
maxY:
		mov	si, bx
		jmp	done
PatternFindExtrema	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Error-checking routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if		ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPatternInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the information passed to set a pattern

CALLED BY:	INTERNAL

PASS:		AL	= PatternType
		AH	= Data (see PatternType definition)
			  If (AL = PT_CUSTOM_HATCH or PT_CUSTOM_BITMAP)
				CX	= Size of HatchPattern/Bitmap
				DX:SI	= HatchPattern/Bitmap

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckPatternInfo	proc	far
		uses	ds
		.enter
	
		; First check the PatternType
		;
		mov	ds, dx			; custom pattern=>DS:SI
		cmp	al, PatternType		; check PatternType
		ERROR_AE GRAPHICS_PATTERN_ILLEGAL_PATTERN_TYPE	
		cmp	al, PT_SOLID		; solid pattern ??
		je	done			; if so, done EC code

		; *** Now check for a custom pattern ***
		;
		cmp	al, PT_CUSTOM_HATCH
		jb	checkUser
		cmp	cx, MAX_CUSTOM_PATTERN_SIZE		
		ERROR_A	GRAPHICS_PATTERN_CUSTOM_PATTERN_TOO_BIG	
		cmp	al, PT_CUSTOM_BITMAP
		je	customBitmap
		call	ECCheckHatchPattern	; verify HatchPattern
		jmp	done
customBitmap:
		call	ECCheckBitmap		; verify Bitmap
		jmp	done

		; *** Now check for a user pattern ***
checkUser:
		cmp	al, PT_USER_HATCH
		jb	checkSystem
		ERROR	GRAPHICS_USER_PATTERNS_NOT_SUPPORTED_YET

		; *** Now check the system pattern ***
checkSystem:
		cmp	al, PT_SYSTEM_BITMAP
		je	systemBitmap
		cmp	ah, SystemHatch		; check SystemHatch
		ERROR_AE GRAPHICS_PATTERN_ILLEGAL_SYSTEM_HATCH	
		jmp	done
systemBitmap:
		cmp	ah, SystemBitmap	; check SystemBitmap
		ERROR_AE GRAPHICS_PATTERN_ILLEGAL_SYSTEM_BITMAP	
done:
		.leave
		ret
ECCheckPatternInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckHatchPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the passed hatch pattern is valid

CALLED BY:	INTERNAL

PASS:		DS:SI	= HatchPattern

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckHatchPattern	proc	near
		uses	ax, bx, cx, dx, si
		.enter
	
		; First check the HatchPattern structure
		;
		mov	cx, ds:[si].HP_numLines
		tst	cx
		ERROR_Z GRAPHICS_HATCH_PATTERN_CANNOT_BE_EMPTY
		cmp	cx, 256
		ERROR_A	GRAPHICS_HATCH_PATTERN_PROBABLY_TOO_MANY_LINES		
		add	si, offset HP_lineData

		; Now check each of the HatchLine structures
nextLine:
		push	cx
		mov	ax, ds:[si].HL_origin.PF_x.WWF_int
		mov	bx, ds:[si].HL_origin.PF_y.WWF_int
		mov	cx, ds:[si].HL_deltaX.WWF_int
		mov	dx, ds:[si].HL_deltaY.WWF_int
		tst	dx			; Y offset should never be zero
		ERROR_Z	GRAPHICS_HATCH_PATTERN_DELTA_Y_CANT_BE_ZERO
		call	Check4CoordsFar
		mov	cx, ds:[si].HL_numDashes
		add	si, offset HL_color
		call	ECCheckColorQuad
		add	si, (offset HL_dashData) - (offset HL_color)
		jcxz	doneLine

		; Check each of the dashes
		;
		shl	cx, 1			; # of WWFixed values => CX
nextDash:
		mov	ax, ds:[si].WWF_int
		call	CheckCoordFar
		add	si, size WWFixed
		loop	nextDash
doneLine:
		pop	cx
		loop	nextLine				

		.leave
		ret
ECCheckHatchPattern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckColorQuad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to ensure the passed color quad is valid

CALLED BY:	ECCheckHatchPattern

PASS:		DS:SI	= ColorQuad

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckColorQuad	proc	near
		.enter
	
		; All we can do is check the ColorFlag
		;
		cmp	ds:[si].CQ_info, CF_RGB
		je	done
		cmp	ds:[si].CQ_info, CF_SAME
		ERROR_A	GRAPHICS_ILLEGAL_COLOR_FLAG
done:
		.leave
		ret
ECCheckColorQuad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a bitmap appears to be valid

CALLED BY:	INTERNAL

PASS:		DS:SI	= Bitmap

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckBitmap	proc	near
		.enter
	
		; There isn't much to check, but we'll go for it
		;
		cmp	ds:[si].B_compact, BMC_USER_DEFINED
		je	done
		cmp	ds:[si].B_compact, BMC_PACKBITS
		ERROR_A	GRAPHICS_BITMAP_ILLEGAL_COMPACT_TYPE
done:
		.leave
		ret
ECCheckBitmap	endp

endif

GraphicsPattern	ends
