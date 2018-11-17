COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		KernelGraphics
FILE:		Graphics/graphicsRaster.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    GLB GrBitBlt		Transfer a bit-boundary block of pixels
				between two locations in video memory.
    EXT BltCommon		where the real work of Blting gets done
    INT ScaleScalarSimple	Scale a pair of scalar quantities, assuming
				no rotation
    INT CalcDestRegion		Calc clipped dest region for blts
    INT CalcInvalRegion		Calculate a new invalid region and update
				it in window struct (Also clean up a few
				things from blt)
    INT CopyRegToWindow		Copy a region into one of the LMem blocks
				in the window structure.
    INT GrFillBitmapAtCP	Treat a monochrome bitmap as a mask,
				filling it with the current area color.
    INT GrFillBitmap		Treat a monochrome bitmap as a mask,
				filling it with the current area color.
    GLB GrDrawBitmapAtCP	Draw a bitmap
    GLB GrDrawBitmap		Draw a bitmap
    INT BMCheckAllocation	This function is called by the Bitmap
				drawing functions to determine if we can
				use the bitmap as is, or if we have to
				allocate another buffer to do scaling,
				format conversion or decompaction.
    INT InitBitmapPalette	The bitmap has a palette stored with it.
				Deal with setting up a buffer to make the
				translation painless.
    INT BMCallBack		Supply next line of bitmap to video driver
    INT BMTrivialReject		Do a trivial reject test for the bitmap
				routine. Also translates the origin to
				device coordinates.
    INT CalcLineSize		Calculate the line width (bytes) for a scan
				line of a bitmap

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	11/88	initial version
	jad	1/89	updated
	jad	4/89	implemented first pass at true BitBlt
	jad	6/89	started adding support for rotated bitmaps
	jad	8/89	Started breaking out parts to KLib, added documentation
	jad	8/89	Added GrCreateBitmap and GrDestroyBitmap


DESCRIPTION:
	This file contains the application interface for all raster graphics
	output.  Most of the routines here call the currently selected
	screen driver to do most of the work, and deal with coordinate
	translation and restricting access to the driver at this level.

	$Id: graphicsRaster.asm,v 1.1 97/04/05 01:13:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrWinBlt segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrBitBlt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a bit-boundary block of pixels between two locations
		in video memory.

CALLED BY:	GLOBAL

PASS:		ax	- x document coordinate		(source)
		bx	- y document coordinate		(source)
		cx	- x document coordinate		(destination)
		dx	- y document coordinate		(destination)

		si	- width of block (document units)
		di	- handle of graphics state

		pushed on the stack (in this order):

		(word)	height of block (document units)
		(word)	control flags:
			enum:	BLTM_COPY	to leave source alone
				BLTM_CLEAR	to clear source rect
				BLTM_MOVE	to clear and inval source rect
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		translate from document coordinates to screen coordinates;
		calculate the effective destination (see below);
		call driver to transfer block;
		add part-not-copied to invalid region;
		if (flags set to invalidate source rect)
		    invalidate source rect;

		To make this blt function useful, it has to do the appropriate
		region manipulations and send redraw events to the window
		if the entire region is not copied.  The effective destination
		consists of the source rectangle ANDed with the current clip
		region, shifted to the destination rectangle, and ANDed again
		with the current clip region.   (see CalcDestRegion)

		After the copy takes place, we need to send a redraw event to
		the window. We do this by adding part of the window to the
		current invalid region, which signals the window manager to
		send the redraw message.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/88...	Initial version
	Jim	3/89		Changed to support transformation matrix
	Jim	4/89		Changed to calculate proper clip regions and
				sending of redraw events.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrBitBlt	proc	far
		ON_STACK	retf
		call	EnterGraphics
		ON_STACK	di es ds si ax bx cx dx bp retf retf
		xchgdw	axbx, cxdx
		call	SetDocPenPos
		xchgdw	axbx, cxdx
		jc	exitBltGSeg		; don't deal with gstrings well

		; check for NULL window.  That's bad too

		tst	ds:[GS_window]		; if no window, bail
		jz	exitBltGSeg
		test	es:[W_grFlags], mask WGF_MASK_NULL ; see if null mask
		jnz	exitBltG

		; translate the coordinates and sizes into device coords

		call	GrTransCoord2Far		; translate coordinates
		jc	exitBltG			; overflow
		xchg	si, ax				; get width
		mov	bp, sp				; look at stack
		test	es:[W_curTMatrix].TM_flags, TM_COMPLEX
		jz	haveHeightWidth
		push	bx, si				; save y pos
		ON_STACK	si bx di es ds si ax bx cx dx bp retf retf
		mov	bx, [bp].EG_param2		; get height
		mov	si, W_curTMatrix
		call	ScaleScalarSimple		; translate height
		mov	[bp].EG_param2, bx
		pop	bx, si
		ON_STACK	di es ds si ax bx cx dx bp retf retf

		; call the common routine, reinstate params passed on stack
haveHeightWidth:
		xchg	si, ax				; restore regs
		push	[bp].EG_param2		; pass height
		push	[bp].EG_param1		; pass flags
		ON_STACK	ax ax di es ds si ax bx cx dx bp retf retf
		call	BltCommon

		; copy all of ExitGraphics here, since we need to pop arguments
		; that were passed on the stack

		ON_STACK	di es ds si ax bx cx dx bp retf retf
exitBltG	label	near
		LoadVarSeg	ds

		; check to see if we need to release a bitmap

		tst	es:[W_bitmap].segment	; check VM file handle
		jnz	releaseBitmap

		; now release the window
releaseWin:
		mov	bx,es:[W_header.LMBH_handle]	;release window
		call	MemUnlockV			; unlock/disown window

exitBltGSeg	label	near
		ON_STACK	di es ds si ax bx cx dx bp retf retf

		LoadVarSeg	ds
		pop	bx				;recover di passed
		ON_STACK	es ds si ax bx cx dx bp retf retf
		mov	di, bx
		call	MemUnlock			; unlock gstate

		pop	dx, cx, bx, ax, si, ds, es
		pop	bp
		add	sp, 4	; skip the retf from EnterGraphics to us
		ret	4	;  and return to our caller, biffing the args

		; we're bltting on a vidmem device -- don't ask me why.  
		; release the locked bitmap
releaseBitmap:
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
GrBitBlt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	where the real work of Blting gets done

CALLED BY:	EXTERNAL
		GrBitBlt, WinBitBlt

PASS:		es	- segment of window where blt takes place
		ax	- source x position (device coords)
		bx	- source y position (device coords)
		cx	- dest x position (device coords)
		dx	- dest y position (device coords)
		si	- width of source (device units)

		pushed on stack (in this order):
			- (word) height of blt (device units)
			- (word) flags for blt:
				enum:	BLTM_COPY 	- leave source alone
					BLTM_CLEAR	- clear source rect
					BLTM_MOVE	- clear/inval src rect

RETURN:		es	- new window segment (may have changed)

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		see BltBlt, above

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BC_local	struct
    BC_rReg	RectRegion	<>	; rectangle region
    BC_width	word			; width of blt
BC_local	ends

finishBlt	label	near
		jmp	doneBlt

BltCommon	proc	near  bltFlags:word, bltHeight:word
BCframe		local	BC_local 

		; before we do anything, nuke any save unders in the window

		push	ax,bx,cx,dx
		mov	ax, es:[W_winRect].R_left ; get coords of window
		mov	bx, es:[W_winRect].R_top
		mov	cx, es:[W_winRect].R_right
		mov	dx, es:[W_winRect].R_bottom
		mov	di, DR_VID_COLLIDE_UNDER
		call	es:[W_driverStrategy]
		pop	ax,bx,cx,dx

		; if transformation matrix has rotation components,
		; then use a different routine

EC <		test	es:[W_TMatrix].TM_flags, TM_ROTATED	>
EC <		ERROR_NZ GRAPHICS_NO_ROTATED_BIT_BLT_SUPPORT		>

		; establish addresssing for parameters and local space

		.enter
		mov	BCframe.BC_width, si		; save width
		tst	si				; check for zero
		jz	finishBlt			;  just bail
		tst	bltHeight			; check for zero
		jz	finishBlt			;  just bail

EC <		call	Check4CoordsFar			; check bounds	>
EC <		push	ax,bx,cx,dx					>
EC <		add	ax, BCframe.BC_width		; check right	>
EC <		add	bx, bltHeight			; check bottom	>
EC <		add	cx, BCframe.BC_width		; check right	>
EC <		add	dx, bltHeight			; check bottom	>
EC <		call	Check4CoordsFar					>
EC <		pop	ax,bx,cx,dx					>

		; create rect region for source

		push	ax, bx				; save source pos
		dec	bx				; scan line above first
		mov	BCframe.BC_rReg.RR_y1M1, bx	; store y1-1
		add	bx, bltHeight			; calc bottom coord
		mov	BCframe.BC_rReg.RR_y2, bx
		mov	BCframe.BC_rReg.RR_x1, ax
		add	ax, BCframe.BC_width		; calc x2
		dec	ax
		mov	BCframe.BC_rReg.RR_x2, ax
		mov	ax, EOREGREC
		mov	BCframe.BC_rReg.RR_eo1, ax	; end of first record
		mov	BCframe.BC_rReg.RR_eo2, ax	; end of second record
		mov	BCframe.BC_rReg.RR_eo3, ax	; end of region
		pop	ax, bx				; save source pos

		; set up pointer to rect region and calc new dest clip reg

		lea	si, BCframe.BC_rReg
		segmov	ds, ss				; ds:si -> rect region
		sub	cx, ax				; cx = x shift amount
		sub	dx, bx				; dx = y shift amt
		call	CalcDestRegion			; set up destination
		push	cx, dx				; save shift amounts
		add	cx, ax				; restore dest pos
		add	dx, bx

		; do trivial reject test only need to check destination
		; in x and y

		push	cx, dx				; save coordinates
		cmp	cx, es:[W_maskRect].R_right
		jg	BC_noBlt			;  reject: after right
		add	cx, BCframe.BC_width
		dec	cx
		cmp	cx, es:[W_maskRect].R_left
		jl	BC_noBlt			; reject: before left
		cmp	dx, es:[W_maskRect].R_bottom
		jg	BC_noBlt			;  reject: below bottom
		add	dx, bltHeight
		dec	dx
		cmp	dx, es:[W_maskRect].R_top
		jl	BC_noBlt			;  reject: above top
		pop	cx, dx

		; call the video driver to transfer the bits

		push	bp				; save frame pointer
		mov	si, BCframe.BC_width		; restore width
		mov	bp, bltHeight			; restore height
		mov	di, DR_VID_MOVBITS
		call	es:[W_driverStrategy]		; make call to driver
		pop	bp				; restore frame pointer

		; reset the clip region back to normal and set up new inval reg
BC_cInval:
		pop	cx, dx				; restore shift amounts
		lea	si, BCframe.BC_rReg
		segmov	ds, ss				; ds:si -> rect region
		mov	bx, bltFlags			; pass copy/move flag
		call	CalcInvalRegion			; calc new inval reg

doneBlt		label	near
		.leave
		ret	4				; kill things passed

;----------------------------------------------------------------------------

		; dest is outside window, so don't blt it.
BC_noBlt:
		pop	cx, dx				; restore stack
		jmp	BC_cInval			;  and just calc new
BltCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleScalarSimple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a pair of scalar quantities, assuming no rotation

CALLED BY:	INTERNAL

PASS:		ax, bx		- pair of x/y quantities to scale
		es:si		- pointer to TMatrix to use

RETURN:		ax		- rounded, scaled x quatity
		bx		- rounded, scaled y quantity

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just multiply ax by the TM_11 component of the matrix
		and multiply bx by the TM_22 component of the matrix

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleScalarSimple	proc	near
		uses	cx, dx
		.enter
		push	bx				; save height
		mov	bx, ax
		clr	ax
		mov	cx, es:[si].TM_11.WWF_frac	; get fraction
		mov	dx, es:[si].TM_11.WWF_int	; get integer
		call	GrRegMul32			; dx.cx = new width
		pop	bx				; restore height
		add	ch, 80h
		adc	dx, 0
		push	dx				; save new width
		clr	ax
		mov	cx, es:[si].TM_22.WWF_frac	; get fraction
		mov	dx, es:[si].TM_22.WWF_int	; get integer
		call	GrRegMul32			; dx.cx = new height
		mov	bx, dx				; bx = new height
		add	ch, 80h
		adc	bx, 0
		pop	ax				; ax = new width
		.leave
		ret
ScaleScalarSimple	endp
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDestRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc clipped dest region for blts

CALLED BY:	INTERNAL
		BltCommon

PASS:		cx	- shift amount, x
		dx	- shift amount, y
		ds:si	- pointer to source region
		es	- locked window segment

RETURN:		es 	     - window segment (may have changed)
		ds	     - window segment
		es:W_maskReg - resulting mask for blt operation
		es:W_temp2Reg - former maskReg

DESTROYED:	di
		es:W_temp1Reg

PSEUDO CODE/STRATEGY:
		What we need to do here is calculate the effective
		destination region for the blt.

		First, we start with a source region.  This region may be
		non-rectangular if there is rotation applied to the window,
		so just assume (worst case) that is an arbitrary shape.  This
		source region represents the bits that we are trying to move
		by some offset (passed here in cx and dx) to another part of
		the screen.  Call this other part the destination region (i.e.
		the one we're trying to calculate).

		Part of the source may be obscured.  To get the effective
		part of the source region, we AND with the current mask
		region (maskReg = visReg AND clipReg AND updateReg AND
		NOT (invalReg)).  Then we shift the result by the passed
		offsets.  Then we AND again with maskReg to get the final
		effective destination region.

		copy region to window struct;		; temp2 = source
		AND with mask region;			; temp1 = src ^ mask
		SHIFT to destination coordinate;	; shift temp1
		AND again with mask region		; temp2 = temp1 ^ mask
		STORE as the new mask region		; mask = temp2

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version
	jim	8/89		Rewritten to use maskReg instead of visReg

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDestRegion	proc	near

		; allocate local space to store shift amounts

		push	bp
		mov	bp, sp
		sub	sp, 4
		mov	[bp-4], cx			; save x shift
		mov	[bp-2], dx			; save y shift
		push	ax, bx				; save regs

		; copy region to window

		mov	di, es:[W_temp2Reg]		; temp2 = source reg
		call	CopyRegToWindow
		segmov	ds, es				; set ds -> window

		; AND source region with mask region

		mov	si, ds:[W_temp2Reg]		; *ds:si -> src reg
		mov	bx, ds:[W_maskReg]		; *es:bx -> visible reg
		mov	di, ds:[W_temp1Reg]		; *es:di -> result reg
		call	FarWinANDReg			; temp1=src AND vis
		segmov	ds, es				; update ds

		; test for any inval region, need to deal with it if so

		mov	si, ds:[W_invalReg]		; get handle
		mov	di, ds:[si]			; get pointer
		cmp	{word} ds:[di], EOREGREC	; any invalReg ?
		jne	CDR_someInval			;  yes, deal with it

		; check to see if resulting source is out of bounds
CDR_chkSource:
		mov	si, ds:[W_temp1Reg]		; get handle
		mov	di, ds:[si]			; get pointer
		cmp	{word} ds:[di], EOREGREC	; see if source reg NULL
		jne	CDR_shift			;  no, continue
		mov	si, ds:[W_temp1Reg]		;  yes, swap handles
		mov	di, ds:[W_temp2Reg]
		mov	ds:[W_temp1Reg], di
		mov	ds:[W_temp2Reg], si
		jmp	CDR_setMask			; and set flags

		; shift the resulting region to destination location
CDR_shift:
		mov	cx, [bp-4]			; restore shift amounts
		mov	dx, [bp-2]
		mov	si, ds:[W_temp1Reg]		; region to shift
		mov	si, ds:[si]			; get offset to region
		call	GrMoveReg			; move the region

		; AND with maskReg again

		mov	si, ds:[W_maskReg]		; *ds:si -> partial res
		mov	bx, ds:[W_temp1Reg]		; *es:bx -> vis reg
		mov	di, ds:[W_temp2Reg]		; *es:di -> result reg
		call	FarWinANDReg			; temp1=partial result
		segmov	ds, es				; update ds

		; swap handles so that mask region is final one
CDR_setMask:
		mov	si, ds:[W_temp2Reg]
		mov	di, ds:[W_maskReg]
		mov	ds:[W_temp2Reg], di
		mov	ds:[W_maskReg], si

		; set up resulting region as clip region

		call	SetupMaskFlags			; set new opt flags

		; all done, restore regs and exit

		mov	cx, [bp-4]			; restore shift amounts
		mov	dx, [bp-2]
		pop	ax, bx				; restore regs
		mov	sp, bp				; restore stack ptr
		pop	bp				; restore base pointer
		ret

;----------	some non-NULL invalid region, deal with it

		; need to subtract out the inval region.  So AND it with
		; NOT(inval).
CDR_someInval:
		mov	si, ds:[W_invalReg]		; need NOT(inval)
		mov	di, ds:[W_temp2Reg]		; store it here
		call	FarWinNOTReg			; temp2=NOT(inval)
		segmov	ds, es				; restore ds

		; swap some handles.  We will end up trashing inval,
		; but we can reconstruct it from NOT(inval) later.

		mov	si, ds:[W_invalReg]		; swap handles
		mov	di, ds:[W_temp2Reg]		;
		mov	ds:[W_temp2Reg], si		; temp2 = inval
		mov	ds:[W_invalReg], di		; inval = NOT(inval)

		; now do the AND.  NOT(inval) is now in inval.

		mov	si, ds:[W_temp1Reg]		; get (src & mask)
		mov	bx, ds:[W_invalReg]		; ~inval
		mov	di, ds:[W_temp2Reg]		;
		call	FarWinANDReg			; temp2=temp1 & ~(inval)
		segmov	ds, es				;

		; swap some handles.  We need to have the result in temp1
		; to hook up with the rest of the routine.

		mov	si, ds:[W_temp1Reg]		; swap handles
		mov	di, ds:[W_temp2Reg]		;
		mov	bx, ds:[W_invalReg]		;
		mov	ds:[W_temp2Reg], bx		; temp2 = ~inval
		mov	ds:[W_temp1Reg], di		; temp1=src&mask&~inval
		mov	ds:[W_invalReg], si		; inval = garbage

		; reconstruct the inval region again. we have ~inval in temp2

		mov	si, ds:[W_temp2Reg]		; get ~inval
		mov	di, ds:[W_invalReg]		; store it back here
		call	FarWinNOTReg			; inval = inval
		segmov	ds, es				;
		jmp	CDR_chkSource



CalcDestRegion	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInvalRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a new invalid region and update it in window struct
		(Also clean up a few things from blt)

CALLED BY:	INTERNAL
		BltCommon

PASS:		bx 		- flag indicates whether to inval/clear source
				  region (see BitBlt header, above)
		cx, dx		- x,y offsets between source and dest regions
		ds:si		- source region
		es		- window segment
		es:maskReg 	- effective destination from blt
		es:temp2Reg 	- old mask region (left over from CalcDestReg)

RETURN:		es		- new window segment


DESTROYED:	ax,bx,cx,dx,si,di,ds

PSEUDO CODE/STRATEGY:
		if (bit set to invalidate source)
		   invalReg += (source v full dest) ^ old maskReg ^
				~(effective dest)
		else if (bit set to clear source)
		   clear the following region instead of adding it to inval:
		   invalReg += (source v full dest) ^ old maskReg ^
				~(effective dest)
		else
		   invalReg += full desk ^ old maskReg ^ ~(effective dest)
		make sure W_grFlags set right;

		Basically, we form the partial product
			old mask AND NOT (effective destination)
		in maskReg.  This is used as a base to and with either the
		full destination or the full dest ORed with the source.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		It is unfortunate, but we end up losing the old mask reg, due
		to lack of region chunks.  Things could be optimized if
		we had another temporary chunk for region calcs. (Avoid
		the eventual recalc of the maskReg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version
	jim	8/89		fixed to use leftover results from CalcDestReg
				also added support for BLTM_CLEAR mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CIR_local	struct
    CIR_flag	word			; move/copy flags
    CIR_shiftX	word			; amount to shift source, x
    CIR_shiftY	word			; amount to shift source, y
    CIR_srcOff	word			; source region offset
    CIR_srcSeg	word			; source region segment
CIR_local	ends
CIR_loc		equ	[bp-size CIR_local]

CalcInvalRegion	proc	near

		; allocate some space for local scratch and save few things

		push	bp
		mov	bp, sp
		sub	sp, size CIR_local
		mov	CIR_loc.CIR_flag, bx		; save move/copy flags
		mov	CIR_loc.CIR_srcOff, si		; save source pointer
		mov	si, ds
		mov	CIR_loc.CIR_srcSeg, si		; save source segment
		mov	CIR_loc.CIR_shiftX, cx		; save offset
		mov	CIR_loc.CIR_shiftY, dx
		segmov	ds, es				; save overrides

		; we're messing with the mask region, so invalidate it

		and	ds:[W_grFlags], not mask WGF_MASK_VALID

		; calc  NOT (effective destination)

		mov	si, ds:[W_maskReg]		; calc NOT effect dest
		mov	di, ds:[W_temp1Reg]		;  put in temp1
		call	FarWinNOTReg			; temp1 = NOT eff dest
		segmov	ds, es				; restore ds

		; and with old mask region

		mov	si, ds:[W_temp2Reg]		; old mask reg
		mov	bx, ds:[W_temp1Reg]		; not(eff dest)
		mov	di, ds:[W_maskReg]		; mask ^ ~(eff dest)
		call	FarWinANDReg			;

		; at this point:
		;	W_temp1Reg = NOT(effective destination)
		;	W_temp2Reg = old mask region
		;	W_maskReg  = old mask AND NOT (effective dest)

		; copy and shift the passed region to destination location

		mov	si, CIR_loc.CIR_srcSeg		; get source reg segment
		mov	ds, si
		mov	si, CIR_loc.CIR_srcOff		; get offset too
		mov	di, es:[W_temp2Reg]		; temp1 = target reg
		call	CopyRegToWindow
		segmov	ds, es				; restore ds->window

		; shift the resulting region to destination location

		mov	cx, CIR_loc.CIR_shiftX		; restore shift amounts
		mov	dx, CIR_loc.CIR_shiftY
		mov	si, ds:[W_temp2Reg]		; region to shift
		mov	si, ds:[si]			; get offset to region
		call	GrMoveReg			; move the region

		; now and with current content of maskReg, almost done w/1st pt

		mov	si, ds:[W_maskReg]		; first source
		mov	bx, ds:[W_temp2Reg]		; full dest
		mov	di, ds:[W_temp1Reg]		; put it here
		call	FarWinANDReg			;
		segmov	ds, es				; restore ds

		; now just add to inval region, done with dest

		mov	si, ds:[W_temp1Reg]		; don't add if not null
		mov	si, ds:[si]
		cmp	{word} ds:[si], EOREGREC	; NULL ?
		je	CIR_check			;  yes, skip work
		call	WinAddToInvalReg		; add result to inval
		segmov	es, ds				; restore es

		; check to see if invalidating source, if so, handle it
CIR_check:
		cmp	byte ptr CIR_loc.CIR_flag, BLTM_COPY ; just a copy ?
		jne	CIR_invalSource			;  no, handle move/inval

		; all finished, cleanup and leave
CIR_done:
		mov	sp, bp				; restore stack pointer
		pop	bp				; restore frame pointer
		ret

;------------------------

		; include source in inval reg.
CIR_invalSource:
		; copy the passed region to destination location

		mov	si, CIR_loc.CIR_srcSeg		; get source reg segment
		mov	ds, si
		mov	si, CIR_loc.CIR_srcOff		; get offset too
		mov	di, es:[W_temp2Reg]		; temp1 = target reg
		call	CopyRegToWindow
		segmov	ds, es				; restore ds->window

		; AND directly with previous result

		mov	si, ds:[W_maskReg]		; maskReg = partial res
		mov	bx, ds:[W_temp2Reg]		; temp1 = target reg
		mov	di, ds:[W_temp1Reg]
		call	FarWinANDReg
		segmov	ds, es				; restore ds->window

		; if resulting region is null, all done

		mov	si, ds:[W_temp1Reg]		; don't add if not null
		mov	si, ds:[si]
		cmp	{word} ds:[si], EOREGREC	; NULL ?
		je	CIR_done			;  yes, skip work

		; check for clear or inval...

		cmp	byte ptr CIR_loc.CIR_flag, BLTM_MOVE ; inval ?
		jne	CIR_clear			;  no, just clear it
		call	WinAddToInvalReg		;  yes, add to inval
		segmov	es, ds				; restore es
		jmp	CIR_done

		; just clear the region, use window function
CIR_clear:
		mov	si, ds:[W_temp1Reg]		; swap region temp
		mov	di, ds:[W_invalReg]
		mov	ds:[W_invalReg], si
		mov	ds:[W_temp1Reg], di
		call	WinWashOut
		mov	si, ds:[W_temp1Reg]		; swap 'em back
		mov	di, ds:[W_invalReg]
		mov	ds:[W_invalReg], si
		mov	ds:[W_temp1Reg], di
		jmp	CIR_done

CalcInvalRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyRegToWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a region into one of the LMem blocks in the window
		structure.

CALLED BY:	INTERNAL
		CalcDestRegion, CalcInvalRegion

PASS:		ds:si	- far pointer to region
		es:di	- far ptr to LMem handle of chunk to copy to

RETURN:		es	- new segment address of LMem heap
		region copied to (resized) LMem chunk

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		determine the size of the region to be copied;
		resize the LMem chunk to that size;
		copy the bytes;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	08/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyRegToWindow	proc	near

		push	si				; save pointer to reg
		call	GrGetPtrRegBounds		; sets si past end
		mov	cx, si				; save end ptr
		pop	si				; restore ptr to reg
		sub	cx, si				; cx = size of region

		; resize target chunk

		mov	ax, es				; swap segments
		mov	bx, ds
		mov	ds, ax
		mov	es, bx
		mov	ax, di				; copy c-handle to ax
		call	LMemReAlloc			; make space for reg
		mov	ax, es				; swap segments
		mov	bx, ds
		mov	ds, ax
		mov	es, bx
		mov	di, es:[di]			; get ptr to new space
		sar	cx, 1				; #bytes -> #words
		rep	movsw				; copy region over
		ret
CopyRegToWindow	endp

GrWinBlt ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillBitmap  GrFillBitmapAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Treat a monochrome bitmap as a mask, filling it with the
		current area color.
CALLED BY:	GLOBAL
PASS:		ax	- x value of coordinate	(dest, only GrDrawBitmap)
		bx	- y value of coordinate	(dest, only GrDrawBitmap)

		ds:si	- pointer to bitmap
		dx:cx	- vfptr to callBack routine
			  (dx must be 0 if no callBack routine supplied)

		di	- handle of graphics state

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		join in with normal bitmap drawing code asap		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrFillBitmapAtCP proc	far
if	0	;FULL_EXECUTE_IN_PLACE
EC<		push	bx					>
EC<		mov	bx, ds					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx					>
endif
		call	EnterGraphics
		call	GetDocPenPos
		jnc	maskBitmapCommon

		; handle writing to a gstring

		mov	al, GR_FILL_BITMAP_CP ; set opcode
		jmp	bmcpGSCommon
GrFillBitmapAtCP endp

GrFillBitmap proc	far
BMframe		local	BitmapFrame

if	0	;FULL_EXECUTE_IN_PLACE
EC<		push	bx					>
EC<		mov	bx, ds					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx					>
endif
		call	EnterGraphics		; returns with  ds->gState
		call	SetDocPenPos
		jnc	maskBitmapCommon

		; handle writing to a gstring

		mov	bp, [bp].EG_ds	; retreive bitmap seg pointer
		push	cx, dx		; save callback address
		mov	dx, bx		; write out coordinate and opcode
		mov	bx, ax		; put x position in bx
		mov	al, GR_FILL_BITMAP
		jz	GSCommon		; if GString, jump
		mov	al, GR_DRAW_RECT	; if path, draw a rectangle
GSCommon:
		mov	cl, size Point 	; write 4 bytes at first
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes	; write em out
		pop	cx, dx		; restore callback address
		jmp	writeBitmapData

maskBitmapCommon label	near

		; make sure there is no evil window lurking

		call	TrivialReject		; won't return if rejected

		; set up a local stack frame to save some stuff away

		mov	di, ss:[bp].EG_ds	; save old bp (bm segment)

		.enter				; allocate stack frame
if	FULL_EXECUTE_IN_PLACE and ERROR_CHECK
		push	ds
		mov	ds, di
		test	ds:[si].B_type, mask BMT_COMPLEX
		pop	ds
		jz	continue
		tst	dx				
		jz	continue			
		push	bx, si				
		movdw	bxsi, dxcx			
		call	ECAssertValidFarPointerXIP	
		pop	bx, si				
continue:						
endif
		mov	BMframe.BF_cbFunc.segment, dx 	; save ptr to callback
		mov	BMframe.BF_cbFunc.offset, cx 	;
		mov	BMframe.BF_origBM.segment, di	; save ptr to bitmap
		mov	BMframe.BF_origBM.offset, si
		mov	BMframe.BF_finalBM.segment, di	; save ptr to bitmap
		mov	BMframe.BF_finalBM.offset, si
		clr	cx
		mov	BMframe.BF_finalBMsliceSize, cx	; init # bytes/scanline
		mov	BMframe.BF_getSliceDSize, cx	; init callback flag 
		mov	BMframe.BF_args.PBA_flags, cx
		mov	BMframe.BF_imageFlags, cl
		mov	BMframe.BF_stateFlags, cx	; init state flags
		mov	BMframe.BF_opType,  mask BMOT_FILL_MASK
		jmp	bitmapTrivialReject
		.leave	.UNREACHED
GrFillBitmap endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawBitmap, GrDrawBitmapAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap

CALLED BY:	GLOBAL

PASS:		ax	- x value of coordinate	(dest, only GrDrawBitmap)
		bx	- y value of coordinate	(dest, only GrDrawBitmap)

		ds:si	- pointer to bitmap
		dx:cx	- pointer to callBack routine
			  (dx must be 0 if no callBack routine supplied)
			  (vfptr on XIP systems)

		di	- handle of graphics state

RETURN:		ds:si	- if a callback routine is supplied, ds:si is set
		 	  to the value supplied in the last call to the 
			  callback function.
			  Otherwise it will be the same as the passed ds:si.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do trivial reject on whole bitmap;
		Set up kernel callback routine if complex;
		call common routine to draw bitmap;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		The supplied callback routine is given a pointer to the
		passed bitmap in ds:si and is expected to return ds:si
		pointing at the next slice.  It is also expected to set
		the carry if the bitmap is completed.

		CallBack routine:
			passed:		ds:si	- points at bitmap (for the
						  first call to the callback
						  routine, this is the same
						  pointer as was passed to 
						  GrDrawBitmap, on subsequent 
						  calls, the pointer is the 
						  same as the callback supplied
						  the last go-around).
			returns:	ds:si	- should point at new slice,
						  which can be totally different
					carry	- set if bitmap is completely
						  drawn (i.e. no more slices),
						  else clear

		    also, it should not trash *any* other registers 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/89...		Initial version
	Jim	3/89		Changed to support transformation matrix
	Jim	6/89		Broke up routine to handle complex bitmaps
				more easily.
	Jim	1/90		Added scaling support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

GrDrawBitmapAtCP proc	far
if	0	;FULL_EXECUTE_IN_PLACE
EC<		push	bx					>
EC<		mov	bx, ds					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx					>
endif
		call	EnterGraphics
		call	GetDocPenPos
		jnc	drawBitmapCommon

		; handle writing to a gstring

		mov	al, GR_DRAW_BITMAP_CP	; set opcode
bmcpGSCommon	label	near
		jz	cpGSCommon		; if GString, jump
		mov	al, GR_DRAW_RECT_TO	; if path, draw a rectangle
cpGSCommon:
		mov	bp, ss:[bp].EG_ds	; retreive bitmap seg pointer
		mov	bx, cx			; save register
		clr	cl			; no data bytes yet
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; just write opcode
		mov	cx, bx			; restore reg
		jmp	writeBitmapData		; join up with code below
GrDrawBitmapAtCP endp

GrDrawBitmap	proc	far
BMframe		local	BitmapFrame
if	FULL_EXECUTE_IN_PLACE
EC<		push	bx					>
EC<		mov	bx, ds					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx					>
endif
		call	EnterGraphics		; returns with  ds->gState
		call	SetDocPenPos
		jnc	drawBitmapCommon

		; write the bitmap to the GString
		mov	bp, [bp].EG_ds	; retreive bitmap seg pointer
		push	cx, dx		; save callback address
		mov	dx, bx		; write out coordinate and opcode
		mov	bx, ax		; put x position in bx
		mov	al, GR_DRAW_BITMAP
		jz	GSCommon		; if GString, jump
		mov	al, GR_DRAW_RECT	; if path, draw a rectangle
GSCommon:
		mov	cl, size Point	; write 4 bytes at first
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes	; write em out
		pop	cx, dx		; restore callback address

		; now write out bitmap data (including header)
writeBitmapData	label	near
		call	BitmapToString	; copy bitmap to graphics string
		jmp	ExitGraphicsGseg

		; update pen position

drawBitmapCommon label	near

		; make sure there is no evil window lurking

		call	TrivialReject		; won't return if rejected

		; set up a local stack frame to save some stuff away

		mov	di, ss:[bp].EG_ds	; save old bp (bm segment)

		.enter				; allocate stack frame
if	FULL_EXECUTE_IN_PLACE and ERROR_CHECK
		push	ds
		mov	ds, di
		test	ds:[si].B_type, mask BMT_COMPLEX
		pop	ds
		jz	continue
		tst	dx				
		jz	continue			
		push	bx, si				
		movdw	bxsi, dxcx			
		call	ECAssertValidFarPointerXIP	
		pop	bx, si				
continue:						
endif
		mov	BMframe.BF_cbFunc.segment, dx 	; save ptr to callback
		mov	BMframe.BF_cbFunc.offset, cx 	;
		mov	BMframe.BF_origBM.segment, di	; save ptr to bitmap
		mov	BMframe.BF_origBM.offset, si
		mov	BMframe.BF_finalBM.segment, di	; save ptr to bitmap
		mov	BMframe.BF_finalBM.offset, si
		clr	cx
		mov	BMframe.BF_finalBMsliceSize, cx	; init # bytes/scanline
		mov	BMframe.BF_getSliceDSize, cx	; init callback flag 
		mov	BMframe.BF_args.PBA_flags, cx
		mov	BMframe.BF_opType,  cl		; init function pointer
		mov	BMframe.BF_imageFlags, cl	; not doing image thing
		mov	BMframe.BF_stateFlags, cx	; init state flags

		; check if bitmap is visible at all.  save device coordinates
bitmapTrivialReject label near
		stc				; check entire bitmap
		push	ax, bx
		call	BMTrivialReject		; returns carry set if rejected
		pop	ax, bx
		jnc	setDrawPoint		; visible, so continue
endShort:
		jmp	bitmapEnd

		; store the starting position (& error in that position)
		; for the bitmap (assumes document coord for bitmap origin
		; is in (ax, bx))
setDrawPoint:
		call	BitmapSetDrawPoint	; window coords -> (ax, bx)
		jc	endShort

		; get the format of the video buffer (bits/pixel)

		mov	cx, ds			; save GState seg
		mov	di, DR_VID_INFO		; get ptr to info table
		call	es:[W_driverStrategy]	; driver knows where
		mov	ds, dx			; set ds:si -> table
		mov	dl, ds:[si].VDI_bmFormat ; bitmap format supp
		and	dl, mask BMT_FORMAT	; only interested in bits/pix
		mov	BMframe.BF_deviceType, dl ; and save it

		; check if we need to allocate a supplementary buffer

		mov	ds, BMframe.BF_finalBM.segment	; get ptr to bitmap
		mov	si, BMframe.BF_finalBM.offset	;  and offset

if	(DISPLAY_CMYK_BITMAPS eq FALSE)
EC <		mov	dl, ds:[si].B_type	; get color format	>
EC <		and	dl, mask BMT_FORMAT				>
EC <		cmp	dl, BMF_4CMYK		; don't do this		>
EC <		ERROR_AE GRAPHICS_CMYK_BITMAPS_NOT_SUPPORTED		>
endif

		; check to see if we need to allocate another block

		call	BMCheckAllocation	; more work to do ?
		jc	alloc			;  yep, do it.

		; nothing complicated about this bitmap.  just draw it.
		; if it's a complex one, we need a loop to do each piece.
		; first, copy the header.

		mov	dx, cx			; save gstate segment in dx
		mov	BMframe.BF_args.PBA_data.segment, ds
		mov	BMframe.BF_args.PBA_data.offset, si
		mov	cx, ds:[si].B_width	; copy over right pieces
		mov	BMframe.BF_args.PBA_bm.B_width, cx
		mov	ax, {word} ds:[si].B_compact
		and	ah, not mask BMT_COMPLEX ; don't set this for driver
		mov	{word} BMframe.BF_args.PBA_bm.B_compact, ax
		xchg	al, ah			; al = B_type
		call	CalcLineSize		; ax = line size
		mov	BMframe.BF_args.PBA_size, ax

		; if there is a palette stored with the bitmap, then pass
		; that information to the video driver

		mov	cl, ds:[si].B_type	; grab type information
		test	cl, mask BMT_PALETTE	; see if there is one there
		jnz	handlePalette

		; if we're filling the bitmap with the current area color, 
		; then set the complex bit in the PutBitsArgs, which will
		; signal to the video driver that we want that...

		test	BMframe.BF_opType, mask BMOT_FILL_MASK
		jz	checkComplex
setFillFlag:
		or	BMframe.BF_args.PBA_flags, mask PBF_FILL_MASK
checkComplex:
		test	cl, mask BMT_COMPLEX  	; more than 1 piece ?
		jnz	handleComplex
		add	BMframe.BF_args.PBA_data.offset, size Bitmap
		mov	cx, ds:[si].B_height	; store  height
		mov	BMframe.BF_args.PBA_bm.B_height, cx
		mov	ds, dx			; restore gState seg
		mov	di,DR_VID_PUTBITS	; use putbits
		mov	ax, BMframe.BF_drawPoint.P_x
		mov	bx, BMframe.BF_drawPoint.P_y
		call	es:[W_driverStrategy]	; make call to driver
		
		; all done drawing the bitmap.  If we allocated some space
		; to store a palette, then release the block
bitmapEnd:
		test	BMframe.BF_args.PBA_flags, mask PBF_ALLOC_PALETTE
		jz	palFreed
		mov	bx, {word} BMframe.BF_palette	; get handle
		call	MemFree			; release block
palFreed:
		movdw	axbx, BMframe.BF_origBM	; get (maybe updated) ptr
		.leave				; restore stack
		mov	ss:[bp].EG_ds, ax	; setup return values
		mov	ss:[bp].EG_si, bx
		jmp	ExitGraphics		; all done, go home

;-------------------------------------------------------------------------

		; need to alloc some space, use different routine.  This will
		; end up drawing the whole thing.
alloc:
		call	DrawSlice		; alloc and draw
		jmp	bitmapEnd

		; there is a palette stored with the bitmap.  Handle it.
		; unless we are filling the bitmap.  Then skip it.
handlePalette:
		test	BMframe.BF_opType, mask BMOT_FILL_MASK
		jnz	setFillFlag
		call	InitBitmapPalette
		jmp	checkComplex

		; the bitmap may be in more than one piece.  Draw one piece
		; at a time.
handleComplex:
		mov	BMframe.BF_origBMtype, cl
		mov	cx, ds:[si].CB_numScans	; get hight of this piece
		jcxz	afterVideoCall		; allow slice to have no data
		mov	BMframe.BF_args.PBA_bm.B_height, cx
		mov	cx, ds:[si].CB_data	; get data pointer
		add	BMframe.BF_args.PBA_data.offset, cx
complexLoop:
		mov	ax, BMframe.BF_drawPoint.P_x ; reload x position
		mov	di,DR_VID_PUTBITS	; use putbits
		mov	ds, dx
		push	dx			; save gstate segment
		call	es:[W_driverStrategy]	; make call to driver
doCallBack:
		call	BMCallBack		; get next slice
		pop	dx			; restore gstate seg
		jc	bitmapEnd
		mov	bx, ds:[si].CB_startScan	; get first scan line
		add	bx, BMframe.BF_drawPoint.P_y ; new y position
		jmp	complexLoop

afterVideoCall:
		push	dx
		jmp	doCallBack
GrDrawBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapSetDrawPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the drawing point for the Bitmap, and also calculates
		any error in that position so that we can scale appropriately

CALLED BY:	INTERNAL

PASS:		inherits BitmapFrame
		es	- Window segment
		(ax,bx)	- Document coordinate of bitmap origin

RETURN:		(ax,bx)	- Window coordinate of bitmap origin

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Sets BF_drawPoint, BF_drawPointErrorX, BF_drawPointErrorY

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapSetDrawPoint	proc	far
BMframe		local	BitmapFrame
		uses	cx, dx, si, ds
		.enter	inherit

		; First transform the coordinate pair to device coordinates

		segmov	ds, es, si
		mov	si, offset W_curTMatrix
		mov_tr	dx, ax
		clr	ax, cx
		call	TransCoordFixed
		jc	done			; if error, abort		

		; Round the results, and record the device coordinate and
		; the error in that position (positive error means we
		; rounded down, negative error indicates we rounded up).
		; Due to the beauty of WWFixed notation, a value greater
		; than or equal to 8000h causes us to round, and that
		; value is also negative (when viewed as a signed number).
		; Also, we include the "rounding" of the eventual bitmap
		; dimension now to avoid later rounding problems (imagine
		; relying upon the carry value after something like
		; fractional width + error X position + 8000h).
	
		rndwwf	dxcx			; rounded X position -> dx
		rndwwf	bxax			; rounded Y position -> bx
		add	cx, 8000h		; include rounding
		add	ax, 8000h		; include rounding

		; Store the results

		mov	BMframe.BF_drawPointErrorX, cx
		mov	BMframe.BF_drawPointErrorY, ax
		mov_tr	ax, dx
		mov	BMframe.BF_drawPoint.P_x, ax
		mov	BMframe.BF_drawPoint.P_y, bx
		clc
done:		
		.leave
		ret
BitmapSetDrawPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMCheckAllocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function is called by the Bitmap drawing functions to 
		determine if we can use the bitmap as is, or if we have to
		allocate another buffer to do scaling, format conversion or
		decompaction.

CALLED BY:	INTERNAL
		GrDrawBitmap, GrDrawHugeBitmap
	
PASS:		ds:si	- points to bitmap header
		es	- locked window	

RETURN:		carry	- set if we need to allocate a block

DESTROYED:	dl


PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMCheckAllocation proc	far
BMframe		local	BitmapFrame
		.enter	inherit

		; if there is any compaction, we need to alloc a block

		cmp	ds:[si].B_compact, BMC_UNCOMPACTED ; alloc if compacted
		jnz	allocateBlock

		; allocate if scaled or rotated (which probably means we have
		; to scale the puppy)

		test	es:[W_curTMatrix].TM_flags, TM_COMPLEX 
		jnz	allocateBlock
		mov	dl, ds:[si].B_type	; get color format
		test	dl, mask BMT_COMPLEX	; check for resolution if any
		jz	checkFormat		;  not complex, check format

		; if complex, we might have a bitmap whose resolution is not
		; 72 DPI.  Check and treat like a scale if that is the case.

		cmp	ds:[si].CB_xres, DEF_BITMAP_RES	; normal width ?
		jne	allocateBlock		;  no, go the long way
		cmp	ds:[si].CB_yres, DEF_BITMAP_RES	; same check in height
		jne	allocateBlock
checkFormat:
		and	dl, mask BMT_FORMAT	; isolate format 
		cmp	dl, BMF_MONO		; if mono, ok
		je	done			; skip if mono (carry clr)

if	(DISPLAY_CMYK_BITMAPS eq TRUE)
		cmp	dl, BMF_4CMYK
		jae	done
endif

		cmp	{byte} BMframe.BF_deviceType, dl ; need to translate 
		jb	allocateBlock		;  color ?
		clc
done:
		.leave
		ret

		; something is complicated.  Alloc away.
allocateBlock:
		stc
		jmp	done
BMCheckAllocation endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBitmapPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The bitmap has a palette stored with it.  Deal with 
		setting up a buffer to make the translation painless.

CALLED BY:	INTERNAL
		GrDrawBitmap, DrawSlice

PASS:		ds:si	- pointer to Bitmap header
		cl	- B_type for bitmap
		BMframe on stack
			
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/16/92		Initial version
	Don	2/08/94		Optimized, fixed 256->16 color mapping

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitBitmapPalette proc	far
		uses	cx, bx, ax, es, di, si, dx
BMframe		local	BitmapFrame
		.enter	inherit

EC <		cmp	BMframe.BF_deviceType, BMFormat			>
EC <		ERROR_AE GRAPHICS_BITMAP_INTERNAL_ERROR			>
		mov	di, si
		add	di, ds:[si].CB_palette	; get pointer to palette
		cmp	{word} ds:[di], 0	; if zero entries, bad palette
		je	badPalette
		mov	dx, es			; save window 
		or	BMframe.BF_args.PBA_flags, mask PBF_ALLOC_PALETTE
		mov	ax, 256			; assume 256 1-byte entries
		cmp	BMframe.BF_deviceType, BMF_24BIT ; see if we need RGBs
		jb	haveSize
		mov	ax, 256*(size RGBValue)	; alloc enuf space 
haveSize:
		mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or mask HF_SWAPABLE
		call	MemAllocFar
		mov	BMframe.BF_palette, bx	; save handle
		mov	BMframe.BF_args.PBA_pal.segment, ax
		clr	BMframe.BF_args.PBA_pal.offset
		mov	es, ax			; es:di -> pal block
		clr	di

		; OK, we have the necc buffer space.  Init the space.
		; es:di -> space to store palette info
		; There are two different scenarios here.  If the device we
		; are drawing on is 24BIT or CMYK, then we need to build out
		; a palette with  RGB values as entries.  If the device is 4
		; or 8-bit, then we need indices.  Which means that we need
		; to map the desired RGB values to the closest index.

		cmp	BMframe.BF_deviceType, BMF_24BIT ; see if we need RGBs
		jb	doIndexLookup			 ;  no, need indices
		
		; since we need RGB values, just copy them from the bitmap
		; header.

EC <		test	BMframe.BF_args.PBA_flags, mask PBF_PAL_TYPE	>
EC <		ERROR_NZ GRAPHICS_BITMAP_INTERNAL_ERROR			>
		add	si, ds:[si].CB_palette	; get pointer to palette
		lodsw				; ax = number of entries
		mov	cx, ax			; get count in cx
		shl	cx, 1
		add	cx, ax			; cx = #bytes
		shr	cx, 1			; div 2 for words (always even)
		rep	movsw			; copy palette
done:
		.leave
		ret

		; palette has size zero
		; turn off palette bit to avoid further complications
		; NOTE: we don't want to turn it off in the source bitmap, as
		;       that would be modifying the user's data.  But we do
		;	want to reset it in the PB_args structure.
badPalette:
		and	BMframe.BF_args.PBA_bm.B_type, not mask BMT_PALETTE
		jmp	done

		; we have an indexed palette.  So figure what the 1-to-1 
		; mapping will be (need to map each RGB value to a valid index)
doIndexLookup:
		or	BMframe.BF_args.PBA_flags, \
					BMPT_INDEX shl offset PBF_PAL_TYPE
		add	si, ds:[si].CB_palette	; get pointer to palette
		lodsw				; ax = number of entries
		mov	cx, ax			; loop countd
		mov	ax, (0xff shl 8)	; map to all 256 entries
		cmp	BMframe.BF_deviceType, BMF_8BIT
		je	checkFor16Colors
		mov	ax, (0x0f shl 8)	; else only use first 16 entries
checkFor16Colors:
		cmp	cx, 16			; if only 16, optimize look-up
		je	colorLoop
		mov	al, ah			; mark AH non-zero to denote
						; a non-16-color bitmap
		cmp	cx, 256
		ja	badPalette

		; we have a 2 or 256-color palette that we want to map to
		; the current Window's palette. Take some care to only
		; map to the resolution of the device, however, by using
		; the maximum # of entries value (pass in AH) to limit
		; our search in the Window's palette.
colorLoop:
		push	ax			; save # of entries to map to
		lodsb				; get next RED
		mov	bx, ds:[si]		; get GREEN and BLUE
		push	ds, si, cx
		call	GetCurrentPalette 	; ds:si -> palette
		mov	ch, ah			; ch -> # of entries to check
		call	MapRGBtoIndex		; just use default mapping
		pop	ds, si, cx
		mov	al, ah			; al <- closest index
		stosb				; store index
		add	si, 2
		pop	ax			; restore entry count
		loop	colorLoop

		; See if we should now fill out the rest of the palette
		; structure, so that was can optimize our look-up of
		; 4-bit/pixel bitmaps.

		tst	al			; this optimization only works
		jnz	done			; ...on 16-color bitmaps
		cmp	BMframe.BF_deviceType, BMF_4BIT
		jne	done			; ...and 4-bit/pixel devices

		; now we need to set the high nibble of each byte
		; but only for 4BIT devices
		
		mov	di, 15		; back to beginning
		mov	bx, 240		; es:bx -> end of palette 
orLoop:
		mov	al, es:[di]	; get nibble
		mov	cl, 4
		shl	al, cl		; up to high nibble
		mov	cx, di		; save pointer
		mov	di, 15
innerLoop:
		or	al, es:[di]
		mov	es:[bx][di], al
		and	al, 0xf0
		dec	di
		jns	innerLoop
		mov	di, cx		; restore pointer
		sub	bx, 16
		sub	di, 1
		jns	orLoop
		jmp	done
InitBitmapPalette endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to the palette for the window

CALLED BY:	INTERNAL
		InitBitmapPalette
PASS:		dx	- Window segment
RETURN:		ds:si	- Pointer to Palette entries
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentPalette	proc	far
	.enter

	mov	ds, dx			; ds -> Window
	tst	ds:[W_palette]		; see if there is a custom one
	jz	useDefault		;  if not, use the default palette

	; OK, there's a custom palette.  W_palette holds the chunk handle

	mov	si, ds:[W_palette]	; get chunk handle and...
	mov	si, ds:[si]		; ...dereference it
done:
	.leave
	ret

	; there is no custom palette, so use the default system one
useDefault:
	LoadVarSeg	ds
	mov	si, offset idata:defaultPalette ; ptr to start of pal
	jmp	done
GetCurrentPalette	endp

 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Supply next line of bitmap to video driver

CALLED BY:	INTERNAL (video driver)

PASS:		inherits stack frame from GrDrawBitmap

RETURN:		carry	- set if no more bitmap to draw, else clear
		ds:si	- pointer to new bitmap slice

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call BMGetSlice to get next scan of bitmap;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMCallBack	proc	far
		uses	ax, bx, dx, di
BMframe		local	BitmapFrame
		.enter	inherit

		; just call the BMGetSlice routine - it does all the work

		test	BMframe.BF_origBMtype, mask BMT_HUGE ; don't load if
		jnz	callGetSlice			      ;  Huge
		mov	ds, BMframe.BF_origBM.segment	; get ptr to orig bm
		mov	si, BMframe.BF_origBM.offset
callGetSlice:
		call	BMGetSlice
		mov	ds, BMframe.BF_finalBM.segment	; return new slice ptr
		mov	si, BMframe.BF_finalBM.offset
		jc	done
		mov	BMframe.BF_args.PBA_data.segment, ds
		mov	ax, ds:[si].CB_data
		add	ax, si
		mov	BMframe.BF_args.PBA_data.offset, ax
		mov	ax, ds:[si].CB_numScans
		mov	BMframe.BF_args.PBA_bm.B_height, ax
		clc
done:
		.leave
		ret
BMCallBack	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a trivial reject test for the bitmap routine. Also
		translates the origin to device coordinates.

CALLED BY:	INTERNAL
		GrDrawBitmap

PASS:		carry	- set to check entire bitmap
			  clear to check current slice (for complex ones)
		ax	- x coordinate to draw string at	(doc coords)
		bx	- y coordinate to draw string at	(doc coords)
		es	- Window segment

		inherits stack frame from GrDrawBitmap

RETURN:		carry	- set if rejected
		ax	- translated x coordinate		(dev coords)
		bx	- translated y coordinate		(dev coords)
		si	- offset to bitmap header

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check bounds of bitmap vs. bounds of window

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMTrivialReject	proc	near
		uses	cx,dx,ds		; save things we trash
BMframe		local	BitmapFrame
		.enter	inherit

		; set up pointer to bitmap

		mov	ds, BMframe.BF_origBM.segment	; get segment address
		mov	si, BMframe.BF_origBM.offset	; ds:si -> bitmap
		mov	dx, bx				; set up rect coords
		mov	cx, ax				; in (ax,bx)-(cx,dx)

		; check flag for what to test.  Setup regs to do testing

		jnc	checkSlice			; check this slice

		; check whole bitmap.

		add	dx, ds:[si].B_height		; add in full height

		; get width
getWidth:
		add	cx, ds:[si].B_width		; slice width=bm width
		dec	cx				; back up one in each
		dec	dx

		; if we're rotated, we need to do some extra work..

		test	es:[W_curTMatrix].TM_flags, TM_COMPLEX ; 
		jnz	complexReject			; do extra work
		test	ds:[si].B_type, mask BMT_COMPLEX ; might have res info
		jnz	checkResolution			;   if complex

		; check extent of bitmap
doRejectTest:
		call	GrTransCoord2			; translate coordinates
		cmp	ax, es:[W_maskRect.R_right]
		jg	rejectIt			; reject: after right
		cmp	cx, es:[W_maskRect.R_left]
		jl	rejectIt			; reject: before left
		cmp	bx, es:[W_maskRect.R_bottom]
		jg	rejectIt			; reject: below bottom
		cmp	dx, es:[W_maskRect.R_top]
		jl	rejectIt			; reject: above top
		clc					; signal ok
done:
		.leave
		ret
rejectIt:
		stc					; signal reject
		jmp	done

		; special case: just check this slice
checkSlice:
		add	dx, ds:[si].CB_numScans		; add in #rows
		jmp	getWidth

		; we might have to do something if the resolution is no 72dpi
checkResolution:
		cmp	ds:[si].CB_xres, DEF_BITMAP_RES ; check for 72dpi
		jne	complexReject
		cmp	ds:[si].CB_yres, DEF_BITMAP_RES ; check for 72dpi
		je	doRejectTest

		; special case: tmatrix has rotation
complexReject:
		mov	cx, ax				; can't pass stuff in
		mov	dx, bx				;  ax,bx
		call	BMComplexReject			; do special check
		pushf					; save carry status
		mov	ax, cx
		mov	bx, dx
		call	GrTransCoord			; pass back trans coords
		popf	
		jmp	done				; all done 

BMTrivialReject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the line width (bytes) for a scan line of a bitmap

CALLED BY:	INTERNAL
		GetBitSizeBlock, DrawSlice

PASS:		al	- B_type byte
		cx	- width of bitmap (pixels)

RETURN:		ax	- #bytes needed

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		case BMT_FORMAT:
		    BMF_MONO:	#bytes = (width+7)>>3
		    BMF_4BIT:	#bytes = (width+1)>>1
		    BMF_8BIT:	#bytes = width
		    BMF_24BIT:	#bytes = width * 3
		    BMF_4CMYK:	#bytes = 4*((width+7)>>3)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLineSize	proc	far
		uses	dx
		.enter
		mov	ah, al			; make a copy
		and	ah, mask BMT_FORMAT	; isolate format
		xchg	ax, cx			; ax = line width, cx = flags
		
		mov	dx, ax			; save line width
		add	dx, 7			; calc mask size
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1

		cmp	ch, BMF_MONO 		; are we monochrome ?
		ja	colorCalc		;  no, do color calculation
		
		mov	ax, dx			; ax = BMF_MONO size

		; done with scan line calc.  If there is a mask, add that in
checkMask:
		test	cl, mask BMT_MASK	; mask stored too ?
		jz	done
		add	ax, dx
done:
		.leave
		ret

		; more than one bit/pixel, calc size
colorCalc:
		cmp	ch, BMF_8BIT		; this is really like mono
		je	checkMask
		jb	calcVGA			; if less, must be 4BIT
		cmp	ch, BMF_24BIT		; this is really like mono
		je	calcRGB

		; it's CMYK or CMY, this should be easy
		
		mov	ax, dx			; it's 4 times the mask size
		shl	ax, 1
		shl	ax, 1
		jmp	checkMask

		; it's 4BIT
calcVGA:
		inc	ax			; yes, round up
		shr	ax, 1			; and calc #bytes
		jmp	checkMask

		; it's RGB.
calcRGB:
		mov	dx, ax			; *1
		shl	ax, 1			; *2
		add	ax, dx			; *3
		add	dx, 7			; recalc mask since we used dx
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1
		jmp	checkMask
						; THIS FALLS THROUGH IF MASK
CalcLineSize	endp

