COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportBitmap.asm

AUTHOR:		Jim DeFrisco, 18 April 1991

ROUTINES:
	Name			Description
	----			-----------
	EmitBitmap		write out bitmap to PS file

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/18/91		Initial revision


DESCRIPTION:
	This file contains the code to output a PC/GEOS bitmap to PostScript
		

	$Id: exportBitmap.asm,v 1.1 97/04/07 11:25:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportBitmap	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a bitmap

CALLED BY:	INTERNAL
		EPSExportBitmap

PASS:		es	= points to locked options block
		si	= gstate to use to export bitmap
		di	= handle of EPSExportLowStreamStruct
		bx.ax	= Huge bitmap (VMfile.VMblock)

RETURN:		ax	= TransError

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateBitmap	proc	far
tgs		local	TGSLocals

; Locals used in the speedier EmitMonoBitmap, which now cuts wide
; lines into smaller packets and attempts to send each one as binary.  If
; that fails, then the traditional hex ascii is sent.
count		local	word	; Used to reset count when
				; when we revert to hex after bin fails
start		local	word	; Used to reset source ptr when bin fails
writeProc	local	nptr	; Holds the offset to the curren byte
				; write procedure
bytesPerBuff	local	word	; Number of bytes per packet
buffsPerLine	local	word	; Number of packets per scan line 
originalBMWidth	local	word	; Width of the bitmap
bmWidthDiff	local	word	; Difference between original width and
				; rounded width for dealing with packets
buffCount	local	word	; let's us know when to clear the end of a
				; packet
		uses	bx,cx,dx,si,di,ds,es
		.enter
		ForceRef	count
		ForceRef	start
		ForceRef	writeProc
		ForceRef	bytesPerBuff
		ForceRef	buffsPerLine
		ForceRef	originalBMWidth
		ForceRef	bmWidthDiff
		ForceRef	buffCount

	; set up TGSLocals

		push	ax, di, es
		segmov	es, ss
		lea	di, tgs
		clr	ax
		mov	cx, (size tgs)/2
		rep	stosw
		pop	ax, di, es

		mov	tgs.TGS_options, es
		mov	tgs.TGS_bmFile, bx	; save bitmap file
		mov	tgs.TGS_bmBlock, ax	; save bitmap block
		mov	tgs.TGS_stream, di	; save the stream block handle
		mov	tgs.TGS_xfactor, 1	; assume TMatrix is OK
		mov	tgs.TGS_yfactor, 1	; assume TMatrix is OK
		mov	tgs.TGS_gstate, si

	; Load bitmap header info

		push	bp
		mov	bx, tgs.TGS_bmFile
		mov	ax, tgs.TGS_bmBlock
		call	VMLock			; lock the HugeArray dir block
		mov	dx, bp			; save memory handle of vmblock
		pop	bp

		mov	ds, ax
		mov	bx, size HugeArrayDirectory ; skip past dir header
		memmov	tgs.TGS_bmWidth, ds:[bx].CB_simple.B_width, ax
		memmov	tgs.TGS_bmHeight, ds:[bx].CB_simple.B_height, ax
		memmov	tgs.TGS_bmType, ds:[bx].CB_simple.B_type, al
		memmov	tgs.TGS_bmXres, ds:[bx].CB_xres, ax
		memmov	tgs.TGS_bmYres, ds:[bx].CB_yres, ax

		; make sure the bitmap that we were passed is not compacted

EC <		cmp	ds:[bx].CB_simple.B_compact, BMC_UNCOMPACTED	>
EC <		ERROR_NE PS_ERROR_BITMAP_MUST_BE_UNCOMPACTED		>

		push	bp
		mov	bp, dx
		call	VMUnlock		; release the VM block
		pop	bp

	; next, all the Emit{SomeObject} routines need some scratch
	; LMem space.  Allocate it here so they all don't have to 
	; allocate it themselves

		mov	ax, LMEM_TYPE_GENERAL		
		clr	cx
		call	MemAllocLMem			; get a block
		mov	tgs.TGS_chunk.handle, bx	; save block handle
		call	MemLock
		mov	ds, ax				; ds-> block
		clr	cx				; no space to start
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_chunk.chunk, ax		; save chunk handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_pathchunk, ax		; save chunk handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_xtrachunk, ax		; save xtra chunk han
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmRed.CC_chunk, ax	; save color handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmGreen.CC_chunk, ax	; save color handle
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmBlue.CC_chunk, ax	; save color handle
		mov	cx, 256*(size RGBValue)+(size Palette) ; alloc palette
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_bmPalette, ax		; save palette handle
		mov	cx, size PageFonts		; 
		call	LMemAlloc			; allocate a chunk
		mov	tgs.TGS_pageFonts.chunk, ax	; save chunk handle
		mov	bx, ax
		mov	bx, ds:[bx]
		clr	ds:[bx].PF_count		; no fonts to start
		mov	bx, tgs.TGS_chunk.handle	; save block handle
		call	MemUnlock			; unlock the block

	; now, emit bitmap

		mov	di, tgs.TGS_gstate
		call	EmitBitmap

	; free the damn thing

		mov	bx, tgs.TGS_chunk.handle	; free the scratch blk
		call	MemFree

	; return error code

		mov	ax, TE_NO_ERROR
		tst	ss:[tgs].TGS_writeErr
		jz	exit
		mov	ax, TE_EXPORT_ERROR
exit:
		.leave
		ret
TranslateBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a bitmap 

CALLED BY:	TranslateGString
		EXTERNAL

PASS:		si		- handle to gstring
		bx		- gstring opcode (in kind of a twisted way)
		es		- points to locked options block

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if monochrome
			output data and DMB procedure
		else
			output data and DCB procedure

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EPS_COMPACTED	equ 0x80			; local flag in BMType field

EmitBitmap	proc	far
		uses	ax, bx, cx, dx, si, di, ds, es
tgs		local	TGSLocals
count		local	word	
				
start		local	word	
writeProc	local	nptr	
				
bytesPerBuff	local	word	
buffsPerLine	local	word	
originalBMWidth	local	word	
bmWidthDiff	local	word	
buffCount	local	word
		.enter	inherit

		; get the first slice

		call	EmitStartObject		; start it out
		call	ExtractBitmapElement	; get the first piece of the bm
		call	EmitTransform		; set up TMatrix
		call	EmitAreaAttributes	; set color in case it's mono

		; extract some info from the header

		cmp	ds:[si].ODB_opcode, GR_DRAW_BITMAP_CP ; if CP....
		LONG je	dealWithCP
		cmp	ds:[si].ODB_opcode, GR_FILL_BITMAP_CP ; if CP....
		LONG je	dealWithCP
		mov	ax, ds:[si].ODB_x	; get and store position
		mov	bx, ds:[si].ODB_y
		add	si, size OpDrawBitmap	; bump past element data to
						;  bitmap header
setBMpos:
		mov	tgs.TGS_bmPos.P_x, ax	
		mov	tgs.TGS_bmPos.P_y, bx
		mov	ax, ds:[si].B_height	; get and store size info
		mov	tgs.TGS_bmHeight, ax	
		mov	cx, ds:[si].B_width
		mov	tgs.TGS_bmWidth, cx	

		; check the bitmap for a palette and either get it or set
		; up the default palette

		call	SetupBitmapPalette	; set up in a chunk
		
		; fetch how many scan lines in this slice, even if simple
		; also, set the data pointer

		mov	tgs.TGS_bmDataPtr, size Bitmap ; assume simple
		mov	tgs.TGS_bmXres, 72	; assume default resolution
		mov	tgs.TGS_bmYres, 72	; assume default resolution
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex ?
		jz	getLineSize
		mov	ax, ds:[si].CB_numScans	; get #rows in this slice
		mov	dx, ds:[si].CB_data	; get offset to data
		mov	tgs.TGS_bmDataPtr, dx	; add complex offset
		mov	dx, ds:[si].CB_xres	; get resolution info
		mov	tgs.TGS_bmXres, dx	;  and save it
		mov	dx, ds:[si].CB_yres
		mov	tgs.TGS_bmYres, dx

		; calculate how much data space there will be per scan line
getLineSize:
		mov	tgs.TGS_bmScansPS, ax	; record #scan lines in slice
		mov	al, ds:[si].B_type
		mov	tgs.TGS_bmType, al	; save type
		call	CalcLineSize		; get size of each scan line
		mov	tgs.TGS_bmBytesPL, ax	; store #bytes per scanline

		; if it is compacted, then allocate a chunk that we can use
		; to de-compact into.

		and	tgs.TGS_bmType, not EPS_COMPACTED ; clear high bit
		cmp	ds:[si].B_compact, BMC_PACKBITS ; only can handle this
		jne	checkColorAlloc		; assume it is uncompacted data
		or	tgs.TGS_bmType, EPS_COMPACTED	; re-use this flag..
		mov	cx, ax			; put desired size in cx
		mov	ax, tgs.TGS_xtrachunk	; already have one, just resize
		call	LMemReAlloc		; resize the chunk

		; if we're going to print in color, then we need to alloc a 
		; chunk for the color buildout.  Alloc a chunk for each of 
		; RGB and make them 1.5 times the pixel width, just for 
		; safety.  Also, if there is a palette, set it 
checkColorAlloc:
		mov	si, tgs.TGS_chunk.chunk	; it may have moved 
		mov	si, ds:[si]
		add	si, size OpDrawBitmap
		cmp	ds:[si-size OpDrawBitmap].ODB_opcode, GR_DRAW_BITMAP
		je	checkForMono
		cmp	ds:[si-size OpDrawBitmap].ODB_opcode, GR_FILL_BITMAP
		je	checkForMono
		add	si, size OpDrawBitmapAtCP - size OpDrawBitmap
checkForMono:
		mov	al, ds:[si].B_type
		and	al, mask BMT_FORMAT	; isolate format
		cmp	al, BMF_MONO		; monochrome ?
		je	doMonoColor
		mov	cx, ds:[si].B_width	; get width
		mov	ax, cx
		shr	ax, 1
		add	cx, ax			; cx = 1.5*width
		mov	ax, tgs.TGS_bmRed.CC_chunk ; realloc color chunks
		call	LMemReAlloc
		mov	ax, tgs.TGS_bmGreen.CC_chunk
		call	LMemReAlloc
		mov	ax, tgs.TGS_bmBlue.CC_chunk
		call	LMemReAlloc

		; check to see if the bitmap is monochrome or color, and do
		; the right thing.  But first, we need to dereference the 
		; chunk again, since we may have re-alloc'd
doMonoColor:
		mov	si, tgs.TGS_chunk.chunk
		mov	si, ds:[si]
		add	si, size OpDrawBitmap
		cmp	ds:[si-size OpDrawBitmap].ODB_opcode, GR_DRAW_BITMAP
		je	havePointer
		cmp	ds:[si-size OpDrawBitmap].ODB_opcode, GR_FILL_BITMAP
		je	havePointer
		add	si, size OpDrawBitmapAtCP - size OpDrawBitmap
havePointer:
		add	tgs.TGS_bmDataPtr, si	; safe to store now
		mov	tgs.TGS_newstyle, 0	; use this as a color/grey flag
		mov	al, ds:[si].B_type
		and	al, mask BMT_FORMAT	; isolate format
		cmp	al, BMF_MONO		; monochrome ?
		jne	checkColor
		call	EmitMonoBitmap

		; done emitting data.  fix up the gstring
done:
		call	EmitEndObject

		.leave
		ret

		; handle color bitmaps
checkColor:
		mov	ax, es:[PSEO_level]	; See if going to color device
		cmp	al, 2			; if level 2 device, do color
		jae	testGray
		test	ax, mask PSL_CMYK	;  or if device has CMYK ext
		jz	doGrey

testGray:	; check if palette only grayscale -> gray output too.
        mov	al, tgs.TGS_bmType
		and	al, mask BMT_FORMAT
		cmp al, BMF_24BIT
		je	doColor
        mov	cx,255
		cmp	al, BMF_8BIT
		je	testloop
		mov	cx,15
		
testloop:
		mov	ah,cl
        call	MapBitmapColorIndex
        cmp	al, bl
        jne	doColor		; color values not equal -> no grayscale
        cmp	al, bh
        jne	doColor
        dec	cx			; color values not equal -> no grayscale
        jnz	testloop
        
doGrey:
		inc	tgs.TGS_newstyle	; non-zero = grey
		call	EmitGreyBitmap
		jmp	done

doColor:
		call	EmitColorBitmap
		jmp	done


		; dealing with a bitmapAtCP...
dealWithCP:
		call	GrGetCurPos
		add	si, size OpDrawBitmapAtCP
		jmp	setBMpos

EmitBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupBitmapPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the chunk allocated for a bitmap palette with either
		the default palette or one from the bitmap

CALLED BY:	INTERNAL
		EmitBitmap
PASS:		ds:[si]	- pointer to Bitmap element
		
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		If there is a palette with the bitmap
			copy it
		else
			get the default system palette

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupBitmapPalette	proc	near
		uses	di, si, ds, es, cx, ax, bx
tgs		local	TGSLocals
		.enter	inherit

		; get a pointer to our palette buffer

		segmov	es, ds, di
		mov	di, tgs.TGS_bmPalette		; *es:di -> palette buf
		mov	di, es:[di]			; es:di -> pal buffer

		; check out the palette bit in the bitmap header...

		test	ds:[si].B_type, mask BMT_PALETTE ; check for palette
		jz	getDefault			 ;  none, get default

		; OK, the bitmap has a palette.  Get a pointer to it and 
		; copy the appropriate number of entries.  If there are zero
		; entries, treat it like there was no palette.

		mov	cx, ds:[si].CB_palette		; get offset to palette
		jcxz	getDefault			;  if offset zero...
		add	si, cx				; ds:si -> palette
		tst	ds:[si].P_entries		; if zero entries...
		jz	getDefault
		mov	cx, ds:[si].P_entries		; get number of entries
		mov	ax, cx				; mul * 3
		shl	cx, 1
		add	cx, ax				; cx = #bytes entries
		add	cx, (size Palette)		; add it space for #ent
		shr	cx, 1				; div by 2 for words
		jnc	movewords
		movsb					; should always be even
movewords:						;  but just in case...
		rep	movsw
done:
		.leave
		ret

		; there is no palette stored with the bitmap, so get the
		; system default and use that.
getDefault:
		push	di
		clr	di
		mov	al, GPT_DEFAULT
		call	GrGetPalette			; bx = mem handle
		pop	di
		call	MemLock
		mov	ds, ax				; get pointer to src
		clr	si				; ds:si -> default pal
		mov	cx, (256*(size RGBValue)+(size Palette))/2
		rep	movsw
		call	MemFree	
		jmp	done
SetupBitmapPalette	endp


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

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitColorBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out color info

CALLED BY:	INTERNAL
		EmitBitmap

PASS:		TGSLocals, on stack.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out all the parameters for the DCB (DrawColorBitmap)
		PostScript function, then write out the data.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitColorBitmap	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; emit the parameters.  The only extra info we need is the 
		; #bytes needed to hold a scanline of data.  For color bitmaps,
		; we need one byte per pixel (and one each for RGB)

		mov	ax, tgs.TGS_bmWidth	; get width in pixels
		clr	cx			; pass flag saying we're color
		call	EmitBitmapParams

		; write out the DCB opcode

		push	ds, si
		mov	bx, handle PSCode
		call	MemLock			; lock down where PS code is
		mov	ds, ax
		mov	bx, tgs.TGS_stream
		EmitPS	emitDCB			; send out the code
		mov	bx, handle PSCode	; release the block
		call	MemUnlock
		pop	ds, si

		; setup a palette in the GState if there is one, so that
		; our mapping from index to RGB goes correctly.  Save the 
		; state first, so we don't keep the palette there later.

		mov	di, tgs.TGS_gstate
		call	GrSaveState

		
		; set up the data pointer and loop count for first slice

		mov	si, tgs.TGS_bmDataPtr	; ds:si -> data
		mov	cx, tgs.TGS_bmScansPS	; cx = loop count
		jcxz	getNextSlice

		; loop through all the scan lines in this slice.  
scanLoop:
		call	EmitColorScan		; write out the hex string
		loop	scanLoop		; keep going

		; see if there is any left to get.  If so, fetch it and continue

		mov	cx, tgs.TGS_bmScansPS	; get # in this slice
		sub	tgs.TGS_bmHeight, cx	; fewer after we finish
		jg	getNextSlice

		; all done.  Restore the state so we don't keep the palette
		; there...

		mov	di, tgs.TGS_gstate
		call	GrRestoreState

		; unlock the data block

		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock

		.leave
		ret

		; get the next slice of data
getNextSlice:
		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock		; release chunk block
		mov	si, tgs.TGS_gstring
		mov	di, tgs.TGS_gstate
		call	ExtractBitmapElement	; get next block
		add	si, size OpBitmapSlice
		mov	cx, ds:[si].CB_numScans	; get #scans in this slice
		mov	tgs.TGS_bmScansPS, cx	; store it away
		add	si, ds:[si].CB_data	; point at bitmap data
		mov	tgs.TGS_bmDataPtr, si	; save pointer
		jmp	scanLoop
EmitColorBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitGreyBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out color info as greyscale

CALLED BY:	INTERNAL
		EmitBitmap

PASS:		TGSLocals, on stack.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out all the parameters for the DGB (DrawGreyBitmap)
		PostScript function, then write out the data.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitGreyBitmap	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; emit the parameters.  The only extra info we need is the 
		; #bytes needed to hold a scanline of data.  For greyscale 
		; bitmaps, we need one byte per pixel 
		mov	ax, tgs.TGS_bmWidth	; get width in pixels
		mov	bl, tgs.TGS_bmType	; get type to check width
		and	bl, mask BMT_FORMAT
		cmp	bl, BMF_4BIT
		ja	xgrey				
		inc	ax
		shr	ax, 1			; need half as many bytes for 4 bit bitmaps
xgrey:	mov	cx, 1			; pass flag indicating no color
		call	EmitBitmapParams

		; write out the DGB opcode

		push	ds, si
		mov	bx, handle PSCode
		call	MemLock	; lock down where PS code is
		mov	ds, ax
		mov	bx, tgs.TGS_stream
		push	bx
		mov	bl, tgs.TGS_bmType	; get type
		and	bl, mask BMT_FORMAT
		cmp	bl, BMF_4BIT
		pop	bx
		ja	cDXB				; >4 bit
		EmitPS	emitDGB			; send out the code
		jmp	cdone
cDXB:	EmitPS  emitDXB		
cdone:	mov	bx, handle PSCode	; release the block
		call	MemUnlock
		pop	ds, si

		; set up the data pointer and loop count for first slice

		mov	si, tgs.TGS_bmDataPtr	; ds:si -> data
		mov	cx, tgs.TGS_bmScansPS	; cx = loop count
		jcxz	getNextSlice		;  zero in this slice

		; loop through all the scan lines in this slice.  
scanLoop:
		call	EmitGreyScan		; write out the hex string
		loop	scanLoop		; keep going

		; see if there is any left to get.  If so, fetch it and continue

		mov	cx, tgs.TGS_bmScansPS	; get # in this slice
		sub	tgs.TGS_bmHeight, cx	; fewer after we finish
		jg	getNextSlice

		; unlock the data block

		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock

		.leave
		ret

		; get the next slice of data
getNextSlice:
		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock		; release chunk block
		mov	si, tgs.TGS_gstring
		mov	di, tgs.TGS_gstate
		call	ExtractBitmapElement	; get next block
		add	si, size OpBitmapSlice
		mov	cx, ds:[si].CB_numScans	; get #scans in this slice
		mov	tgs.TGS_bmScansPS, cx	; store it away
		add	si, ds:[si].CB_data	; point at bitmap data
		mov	tgs.TGS_bmDataPtr, si	; save pointer
		jmp	scanLoop
EmitGreyBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitMonoBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out color info

CALLED BY:	INTERNAL
		EmitBitmap

PASS:		TGSLocals, on stack.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out all the parameters for the DMB (DrawMonoBitmap)
		PostScript function, then write out the data.

NOTES:
		This has been rewritten to incorporate sending binary data
		when possible.  Binary data is 1/2 of the size of hex ascii
		data and speeds up IR printing substantially.

		Sending all binary is not possible because many byte values
	 	are interpreted by postscript printers as ctrl codes
		resulting in stopped jobs and garbage printouts.

		To (partially) get around this, we split each long scan line
		into 4 packets.  Each packet is encoded as binary data as long
		as no "bad" byte values are detected.  When a bad byte is
		encountered, the packet is re-encoded in hex ascii before
		being sent to the stream.

		Each packet starts with a tag byte indicating whether it is
		binary or hex data, and the DMB (drawMonoBitmap) postcript
		function reads the tag byte to determine whether to use
		readstring (binary) or readhexstring (ascii).  



REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version
		jimw	10/96		Binary/Hex Ascii modifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitMonoBitmap	proc	near
tgs		local	TGSLocals
count		local	word
start		local	word
writeProc	local	nptr		
bytesPerBuff	local	word
buffsPerLine	local	word
originalBMWidth	local	word
bmWidthDiff	local	word		
buffCount	local	word
		.enter	inherit

		; emit the parameters.  The only extra info we need is the 
		; #bytes needed to hold a scanline of data.  For mono bitmaps,
		; we need one byte per eight pixels.

		mov	ax, tgs.TGS_bmWidth	; get width in pixels
		add	ax, 7			; round up to nearest byte
		and	ax, 0xfff8		; clear low three bits
		mov	tgs.TGS_bmWidth, ax
		shr	ax, 1			; divide by 8 for #bytes
		shr	ax, 1
		shr	ax, 1
		mov	ss:[originalBMWidth], ax

		; If the bitmap is very wide, then we'll cut up the lines to
		; increase the chances of passing binary data. 

		mov	ss:[bytesPerBuff], ax	; assume one large line
		mov	ss:[buffsPerLine], 1	
		mov	ss:[bmWidthDiff], 0
		cmp	ax, EPS_WIDE_LINE_LENGTH
		jb	getBytesPerBuff
		
		; This is a wide bitmap.  Set up for sending the line in
		; four packets.

		add	ax, 7			; round up to next byte	
		and	ax, 0xfff8		
		shr	ax, 1			; divide by four
		shr	ax, 1			; to get bytes per buffer
		mov	ss:[bytesPerBuff], ax
		mov	ss:[buffsPerLine], EPS_WIDE_LINE_BUFFS_PER_LINE
		
		; Figure how wide rounded bitmap is in pixels by
		; multiplying the by 4 (packets -> whole buffer), then by 8
		; (bytes to bits).

		shl	ax, 1
		shl	ax, 1			; bytes/scanline

		; Since we rounded up, we need to clean the extra bits at the
		; end of the last packet.  This value is in bytes.

		mov	cx, ax
		sub	cx, ss:[originalBMWidth]
		mov	ss:[bmWidthDiff], cx

		shl	ax, 1			
		shl	ax, 1
		shl	ax, 1			; pixels/scanline

		; Store the width of the bitmap.  

		mov	tgs.TGS_bmWidth, ax
		
getBytesPerBuff:
		mov	ax, ss:[bytesPerBuff]
		mov	cx, 1			; pass flag indicating no color
		call	EmitBitmapParams

		; write out the DMB opcode

		push	ds, si
		mov	bx, handle PSCode
		call	MemLock			; lock down where PS code is
		mov	ds, ax
		mov	bx, tgs.TGS_stream
		EmitPS	emitDMB			; send out the code
		mov	bx, handle PSCode	; release the block
		call	MemUnlock
		pop	ds, si

		; set up the data pointer and loop count for first slice

		mov	si, tgs.TGS_bmDataPtr	; ds:si -> data
		mov	cx, tgs.TGS_bmScansPS	; set up loop count
		jcxz	getNextSlice

		; loop through all the scan lines in this slice.  
scanLoop:
		call	EmitMonoScan		; write out the hex string
		loop	scanLoop		; keep going

		; see if there is any left to get.  If so, fetch it and continue

		mov	cx, tgs.TGS_bmScansPS	; get # in this slice
		sub	tgs.TGS_bmHeight, cx	; fewer after we finish
		jg	getNextSlice

		; unlock the data block

		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock

		.leave
		ret

		; get the next slice of data
getNextSlice:
		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock		; release chunk block
		mov	si, tgs.TGS_gstring
		mov	di, tgs.TGS_gstate
		call	ExtractBitmapElement	; get next block
		add	si, size OpBitmapSlice
		mov	cx, ds:[si].CB_numScans	; get #scans in this slice
		mov	tgs.TGS_bmScansPS, cx	; store it away
		add	si, ds:[si].CB_data	; point at bitmap data
		mov	tgs.TGS_bmDataPtr, si	; save pointer
		jmp	scanLoop
EmitMonoBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitBitmapParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out parameters to pass to DMB and DCB functions

CALLED BY:	INTERNAL
		EmitMonoBitmap, EmitColorBitmap

PASS:		ax	- #bytes needed to hold one scanline of data
		cx	- flag to tell if we are called from EmitColorBitmap
			  0        = called from EmitColorBitmap
			  non-zero = called from Emit{Grey,Mono}Bitmap

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		just write out:

		<width> <height> <line size> <xscale> <yscale> <xpos> <ypos>

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitBitmapParams proc	near
		uses	bx, es, di, cx, dx
tgs		local	TGSLocals
count		local	word
start		local	word
writeProc	local	nptr		
bytesPerBuff	local	word
buffsPerLine	local	word
originalBMWidth	local	word
bmWidthDiff	local	word
buffCount	local	word
		.enter	inherit

		; use the buffer in the "tgs" structure...

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer

		; write out width and height

		push	ax			; save line length
		mov	bx, tgs.TGS_bmWidth
		mov	al, tgs.TGS_bmType	; get type to check width
		and	al, mask BMT_FORMAT
		cmp	al, BMF_4BIT
		ja	writeWidth
		jb	incWidthForMono

		; if the bitmap is 4-bits/pixel, then we might have to round
		; up the width and we might not.  If we are going to a color
		; printer (that is, if this function is being called from
		; EmitColorBitmap), then we *don't* want to round it up.  Else
		; we do.  So check that here (check for level 2 printer or
		; CMYK extensions)

		jcxz	writeWidth		; cx passed to indicate ColorBM
		jmp	incWidthMaybe		; going to Grey, round up

incWidthForMono:
		add	bx, 7
		and	bx, 0xfff8		; round up to next eight
incWidthMaybe:
		inc	bx
		and 	bx, 0xfffe

writeWidth:
		call	UWordToAscii
		mov	al, ' '			; separate with spaces
		stosb
		mov	bx, tgs.TGS_bmHeight
		call	UWordToAscii
		stosb

		; write out line length

		pop	bx			; restore line length
		call	UWordToAscii
		stosb

		; calculate x scale factor and write it out
		; xscale = (width*72) / xres
		
		mov	bx, tgs.TGS_bmWidth	; assume it's at 72 dpi
		clr	ax
		cmp	tgs.TGS_bmXres, 72	; 72 dpi ?
		je	writeXres		;  yes, done
		mov	dx, bx			; in case it's 72 dpi
		clr	cx
		mov	bx, tgs.TGS_bmXres	;  no, div by resolution
		clr	ax
		call	GrUDivWWFixed
		mov	bx, 72			; load up xresolution
		clr	ax
		call	GrMulWWFixed
		mov	bx, dx			; move result to bx.ax
		mov	ax, cx
writeXres:
		call	WWFixedToAscii
		mov	al, ' '			; separate with spaces
		stosb


		; calculate y scale factor and write it out
		; xscale = (height*72) / xres

		mov	bx, tgs.TGS_bmHeight	; assume it's at 72 dpi
		clr	ax
		cmp	tgs.TGS_bmYres, 72	; 72 dpi ?
		je	writeYres		;  yes, done
		mov	dx, bx
		clr	cx
		mov	bx, tgs.TGS_bmYres
		call	GrUDivWWFixed
		mov	bx, 72			;  no, mul by 72
		clr	ax
		call	GrMulWWFixed
		mov	bx, dx			; move result to bx.ax
		mov	ax, cx
writeYres:
		call	WWFixedToAscii
		mov	al, ' '			; separate with spaces
		stosb

		; write out position

		mov	bx, tgs.TGS_bmPos.P_x	; get x position
		tst	tgs.TGS_xfactor		; see if OK
		jnz	xOK
		clr	bx
xOK:
		call	SWordToAscii
		stosb
		mov	bx, tgs.TGS_bmPos.P_y	; get y position
		tst	tgs.TGS_yfactor		; see if OK
		jnz	yOK
		clr	bx
yOK:
		call	SWordToAscii
		call	EmitBuffer
		.leave
		ret
EmitBitmapParams endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitMonoScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a scan line from a monochrome bitmap

CALLED BY:	INTERNAL
		EmitMonoBitmap

PASS:		ds:si	- pointer to data
		tgs, on stack

RETURN:		ds:si	- pointer after data just written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert the bitmap data to hex, apply mask, do decompaction.
		Not neccesarily in that order.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitMonoScan	proc	near
		uses	es, di, cx, ax, bx
tgs		local	TGSLocals
count		local	word
start		local	word		
writeProc	local	nptr
bytesPerBuff	local	word
buffsPerLine	local	word
originalBMWidth	local	word	
bmWidthDiff	local	word
buffCount	local	word
		.enter	inherit
	;
	; New;  try to send the data as binary to start with.
	;
		mov	ss:[writeProc], offset	WriteBinByte
							; assume bin
		mov	tgs.TGS_nchars, 0		; zero out #chars
		test	tgs.TGS_bmType, EPS_COMPACTED	; compacted ?
		LONG 	jnz	decompactScan
		
		mov	ax, tgs.TGS_bmBytesPL		; bump past
		add	tgs.TGS_bmDataPtr, ax

		; alright.  have decompacted data.  If mask, use a different 
		; loop.  Setup es:di -> tgs buffer
convertScan:
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer		; es:di -> output buff
		mov	{byte}es:[di], EPS_BIN_TAG	; set tag to binary
		inc	di				; move past tag
		mov	ss:[start], si			; start of source
		mov	cx, tgs.TGS_bmWidth		; figure right mask
		and	cx, 0x7
		mov	ax, 0xff00
		rol	ax, cl				; ah = right OR mask
	
		; Set loop count for how many packets in each line.
		; Could be 1.  Also remember how many bytes we were supposed
		; to do in case we have to redo them in ascii.

		mov	cx, ss:[buffsPerLine]		; # packets to do
		mov	ss:[buffCount], cx		; init packet count
		push	cx				
		mov	cx, ss:[bytesPerBuff]		; bytes to do
		mov	ss:[count], cx			
		test	tgs.TGS_bmType, mask BMT_MASK	; if mask, do it diff
		jz nomaskLoop
		jmp	withMask

		; no mask.  just convert the data.  use the TGS_nchars for a
		; character count.
nomaskLoop:
		lodsb					; get next byte
		cmp	cx, 1				; if on the last round
		je	rightByte
		
writeByte:
		call	ss:[writeProc]			; write it out
		loop	nomaskLoop

		; Set up to do the next packet, unless we're done.

		pop	cx				
		dec	cx
		jz	done

		; Save counter, reset the byte counter, and set the Write
		; procedure to be binary again.

		dec	ss:[buffCount]
		push	cx
		mov	cx, ss:[bytesPerBuff]
		mov	ss:[writeProc], offset	WriteBinByte
		jmp	nomaskLoop
		
		; finished with the scan.  Output the whatever is left.
done:		
		cmp	tgs.TGS_nchars, 0		; if non-zero
		jz	exit

		mov	cx, ss:[bmWidthDiff]
		jcxz	emitBuffer

		mov	ax, offset WriteBinByte
		cmp	ss:[writeProc], ax
		je	cleanBinary

		shl	cx
		sub	di, cx
		shr	cx
		mov	al, C_ZERO
hexCleanLoop:
		call	ByteToHexAscii
		loop	hexCleanLoop
		jmp	emitBuffer
cleanBinary:
		clr	al
		sub	di, cx
		dec	cx			; es:di points *after* buffer
		rep	stosb
emitBuffer:	
		; emit CR/LF after each packet. DSC rules allow only 
		; 255 character per line and it looks nicer.
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer

exit:
		mov	si, tgs.TGS_bmDataPtr		; ds:si -> next scan 
		.leave
		ret

rightByte:
		and	al, ah				; make right white
		jmp	writeByte


		; we need to decompact the sucker first. Use the convenient
		; already-allocated-extra-chunk.
decompactScan:
		segmov	es, ds, di			; es -> block
		mov	di, tgs.TGS_xtrachunk		; get chunk handle
		mov	di, ds:[di]			; es:di -> chunk
		push	di
		mov	cx, tgs.TGS_bmBytesPL		; #bytes per scan line
		call	UncompactPackBits		; do it
		mov	tgs.TGS_bmDataPtr, si		; save for next time
		pop	si				; ds:si -> uncompacted
		jmp	convertScan

		; bitmap has a mask stored with it.  setup ds:di -> mask data
withMask:
		push	ax				; need to save ah
		mov	bx, si				; mask comes first
		mov	ax, tgs.TGS_bmWidth		; bump past to data
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		add	si, ax				; ds:si -> data
		sub	cx, ax				; fewer data bytes
		pop	ax
maskLoop:
		lodsb					; get data byte
		cmp	cx, 1				; if last
		je	rightMaskByte
writeMaskByte:
		and	al, ds:[bx]			; apply mask
		inc	bx				; on to next mask
		push	bx
		call	ss:[writeProc]			; write it out
		pop	bx
		loop	maskLoop
		jmp	done
		
rightMaskByte:
		and	al, ah
		jmp	writeMaskByte


EmitMonoScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBinByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a binary byte, with some buffer control.

CALLED BY:	INTERNAL
		EmitMonoScan

PASS:		al		- byte to write
		es:di		- pointer into buffer

RETURN:		es:di		- bumped to where next char should go

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteBinByte	proc	near
		uses	ax
tgs		local	TGSLocals
count		local	word
start		local	word
writeProc	local	nptr
bytesPerBuff	local	word
buffsPerLine	local	word
originalBMWidth	local	word
bmWidthDiff	local	word		
buffCount	local	word
		
		.enter	inherit

	;
	; This happens a lot.
	;
		tst	al
		jz	storeIt

ifndef	EPS_NO_PACKETS
	;
	; See if this is a bad byte.
	;
		push	es, di, cx
		segmov	es, cs		
		mov	di, offset BadByteTable
		mov	cx, BBT_SIZE
		repnz	scasb
		pop	es, di, cx
		jnz	storeIt
endif
	;
	; It's a bad byte.  Set up to re encode the buffer in ascii hex.
	;
		mov	cx, ss:[count]
		inc	cx			; fool the loop instruction
		mov	si, ss:[start]		; ds:si <- source start
		lea	di, tgs.TGS_buffer
		mov	{byte} es:[di], EPS_HEX_TAG	; change tag byte
		inc	di				; bump past tag
		mov	ss:[writeProc], offset WriteHexByte
						; chagne WRite procedure
		clr	tgs.TGS_nchars		; no character done
		jmp	done			; that's it.

storeIt:
		stosb				; es:[di] <= al
		inc	tgs.TGS_nchars		; see if line is complete
		mov	bx, ss:[bytesPerBuff]
		cmp	tgs.TGS_nchars, bx
		jae	finishLine
		clc
done:
		.leave
		ret

		; have a full line.  Write out the CRLF
finishLine:

		cmp	ss:[buffCount], 1
		
		jne	emitBuffer

		push	cx
		mov	cx, ss:[bmWidthDiff]
		jcxz	noTrash

		sub	di, cx			; es:di <- end of buffer
		clr	al
		rep	stosb
noTrash:
		pop	cx

		
emitBuffer:
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
		inc	di			; same tag byte you know
		mov	tgs.TGS_nchars, 0	; reset count
		mov	ss:[start], si
		clc
		jmp	done



BadByteTable	label	byte
		byte	0x01
		byte	0x03
		byte	0x04
		byte	0x11
		byte	0x12
		byte	0x13
		byte	0x14
		byte	0x1b		
BBT_SIZE	equ	($ - BadByteTable) / (size byte)
		
		

WriteBinByte	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteHexByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a hex byte, with some buffer control

CALLED BY:	INTERNAL
		EmitMonoScan

PASS:		al		- byte to write
		es:di		- pointer into buffer

RETURN:		es:di		- bumped to where next char should go

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteHexByte	proc	near
		uses	ax
tgs		local	TGSLocals
count		local	word
start		local	word
writeProc	local	nptr
bytesPerBuff	local	word
buffsPerLine	local	word
originalBMWidth	local	word
bmWidthDiff	local	word
buffCount	local	word
		.enter	inherit

		
		call	ByteToHexAscii		; convert it
		add	tgs.TGS_nchars, 2	; see if line is complete
		mov	bx, ss:[bytesPerBuff]
		shl	bx			; two bytes per ascii char
		cmp	tgs.TGS_nchars, bx
						; if at line's end
		jae	finishLine
		clc
done:
		.leave
		ret

		; have a full line.  Write out the CRLF
finishLine:
	;
	; If not on the last buffer, then we know the thing is full.
	;
		cmp	ss:[buffCount], 1
		jne	emitBuffer

	;
	; Last buffer; clear out the last bytes.
	;
		push	cx
		mov	cx, ss:[bmWidthDiff]
		jcxz	noTrash

		shl	cx
		sub	di, cx
		shr	cx
		clr	al
hexCleanLoop:
		call	ByteToHexAscii
		loop	hexCleanLoop
noTrash:
		pop	cx
emitBuffer:
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
		mov	{byte}es:[di], EPS_BIN_TAG	; try bin, you know 
		inc	di
		mov	tgs.TGS_nchars, 0	; reset count
		mov	cx, 1		; HACK HACK HACK
		mov	ss:[start], si
		clc
		jmp	done

WriteHexByte	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a scan line from a color bitmap

CALLED BY:	INTERNAL
		EmitColorBitmap

PASS:		ds:si	- pointer to data
		tgs, on stack

RETURN:		ds:si	- pointer after data just written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert the bitmap data to hex, apply mask, do decompaction.
		Not neccesarily in that order.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitColorScan	proc	near
		uses	es, di, cx, ax
tgs		local	TGSLocals
		.enter	inherit

		; check for uncompaction...

		test	tgs.TGS_bmType, EPS_COMPACTED	; compacted ?
		jnz	decompactScan		;        (see EmitBitmap, above)
		mov	ax, tgs.TGS_bmBytesPL		; bump past
		add	tgs.TGS_bmDataPtr, ax

		; alright.  have decompacted data.  If mask, use a different 
		; loop.  Setup es:di -> tgs buffer
convertScan:
		mov	cx, tgs.TGS_bmWidth		; do this many bytes
		test	tgs.TGS_bmType, mask BMT_MASK	; if mask, do it diff
		jz	doneWithMask
		call	MaskOffPixels			; turn pixels to black

		; finished with mask, so convert the data.  Init some 
		; compaction flags to start
doneWithMask:
		mov	ax, 0xffff			; bogus offset to init
		mov	tgs.TGS_bmRed.CC_offset, ax	; clear out offsets
		mov	tgs.TGS_bmGreen.CC_offset, ax	; clear out offsets
		mov	tgs.TGS_bmBlue.CC_offset, ax	; clear out offsets
		mov	al, tgs.TGS_bmType		; get type
		and	al, mask BMT_FORMAT		; isolate color type
		cmp	al, BMF_4BIT			; different loop if 
							;  more colors
		jne	bigcolor
pixLoop:
		lodsb					; get next byte
		mov	ah, al
		push	ax
		shr	ah, 1				; need high nibble
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1
		call	MapBitmapColorIndex
		call	CompactRGBPixel			; write it out
		pop	ax
		dec	cx				; one less pixel
		jcxz	done
		and	ah, 0xf				; isolate low nibble
		call	MapBitmapColorIndex
		call	CompactRGBPixel			; write it out
		loop	pixLoop
done:		
		call	WriteCompactedScan		; write out to stream

		mov	si, tgs.TGS_bmDataPtr		; ds:si -> next scan 
		.leave
		ret

;--------------------------------------------------------------------------
		; we need to decompact the sucker first. Use the convenient
		; already-allocated-extra-chunk.
decompactScan:
		segmov	es, ds, di			; es -> block
		mov	di, tgs.TGS_xtrachunk		; get chunk handle
		mov	di, ds:[di]			; es:di -> chunk
		push	di
		mov	cx, tgs.TGS_bmBytesPL		; #bytes per scan line
		call	UncompactPackBits		; do it
		mov	tgs.TGS_bmDataPtr, si		; save for next time
		pop	si				; ds:si -> uncompacted
		jmp	convertScan

		; it's either 8 or 24-bits per pixel.
bigcolor:
		mov	dx, cx				; dx = width
		cmp	al, BMF_8BIT			; different loop if 
		jne	pix24Loop
pix8Loop:
		lodsb
		mov	ah,al				; MapBitmapColorIndex needs index in AH, not AL
		call	MapBitmapColorIndex
		call	CompactRGBPixel
		loop	pix8Loop
		jmp	done
pix24Loop:
;		mov	bx, dx				; bx = width
;		add	si, bx				; bump to blue plane
;		mov	dh, ds:[si][bx]			; get blue pixel
;		mov	dl, ds:[si]			; get green pixel
;		sub	si, bx
;		lodsb					; get red pixel
;		xchg	bx, dx				; bx = pixel values
		lodsw					; 
		mov	bx, ax
		lodsb
		xchg	al, bl
		xchg	bl, bh
		call	CompactRGBPixel			; compact it
		loop	pix24Loop
		jmp	done

EmitColorScan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapBitmapColorIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A replacement for GrMapColorIndex, where it uses the 
		bitmap palette stored in our TGS_bmPalette chunk.

CALLED BY:	INTERNAL
		EmitColorScan, EmitGreyScan
PASS:		ah		- color index to map
RETURN:		al,bl,bh	- RGB value for pixel
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapBitmapColorIndex	proc	near
		uses	si
tgs		local	TGSLocals
		.enter	inherit

		mov	si, tgs.TGS_bmPalette	; get palette chunk	
		mov	si, ds:[si]		; ds:si -> palette
		mov	bl, ah			; setup lookup value
		clr	bh
		mov	ax, bx			; get copy of value
		cmp	ax, ds:[si].P_entries	; if out of range...
		ja	useDefault		; ...then use default
		shl	bx, 1			; index into table
		add	bx, ax
		add	bx, (size Palette)	; bump past #entries
		add	si, bx			; ds:si -> entry we want
		mov	ah, al			; retain original value
		mov	al, ds:[si].RGB_red	; get red value
		mov	bx, {word} ds:[si].RGB_green ; get green and blue
done:
		.leave
		ret

		; shouldn't ever get here, but you know those wacky bitmaps
useDefault:
		mov	ah, bl
		push	di
		clr	di
		call	GrMapColorIndex
		pop	di
		jmp	done
MapBitmapColorIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaskOffPixels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bitmap has a mask stored with it, so make a pass over a scan
		line to blacken the pixels that we don't want to see.

CALLED BY:	INTERNAL
		EmitColorScan, EmitGreyScan

PASS:		ds:si	- pointer to bitmap
		cx	- bitmap width
		tgs	- passed on stack

RETURN:		ds:si	- points past mask to data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set up a pair of pointers -- one into masks, the other into
		the pixel data -- and set pixels not included to 0.  Most
		often, this will mean black.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MaskOffPixels	proc	near
		uses	es, ax, di, cx, bx
tgs		local	TGSLocals
		.enter	inherit

		; setup ds:si -> masks and es:di -> data

		mov	di, si				; mask comes first
		mov	ax, cx				; bump past mask 
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		add	di, ax				; ds:di -> data
		push	di				; save pointer to data
		segmov	es, ds, ax			; es:di -> data

		; ch will hold the pixel mask, cl holds the #bits to shift
		; dh will hold the current mask mask, dl will be a work register
		; bx holds the pixel count
		; assume 4BIT/pixel

		mov	bx, cx				; bx = pixel count
		mov	ch, 0xf0			; initial pixel mask
		mov	dh, 0x80			; initial mask mask
		mov	cl, 4
		mov	al, tgs.TGS_bmType		; get type
		and	al, mask BMT_FORMAT		; isolate color type
		cmp	al, BMF_4BIT			; different init ?
		jne	handle8BitInit			; must be 8 or 24 bit

		; go through each pixel.  
maskLoop:
		mov	dl, dh				; set up mask mask
		and	dl, ds:[si]			; bit clear ?
		jz	maskPixel			;  no, continue
donePixel:
		shr	dh, 1				; advance masks
		jnc	bumpPixelMask			; if no carry, OK
		inc	si				; bump mask pointer
		mov	dh, 0x80			; re-init mask mask
bumpPixelMask:
		clr	ax
		mov	ah, ch
		shr	ax, cl
		mov	ch, ah				; assume no overflow
		tst	ah
		jnz	oneLessPixel
		mov	ch, al
		inc	di
oneLessPixel:
		dec	bx
		jnz	maskLoop
exit:
		pop	si				; ds:si -> data
		.leave
		ret

		; mask off this pixel
maskPixel:
		cmp	cl, 1				; if monochrome...
		je	maskMonoPixel
		or	es:[di], ch			; make masked white
		jmp	donePixel
maskMonoPixel:
		not	ch				; for mono, 0=white
		and	es:[di], ch
		not	ch
		jmp	donePixel

		; handle initialization for 8bit and 24bit per pixel bitmaps
handle8BitInit:
		cmp	al, BMF_24BIT			; might need this
		je	loop24
		cmp	al, BMF_MONO			; might need this
		je	handleMonoInit
		mov	ch, 0xff			; pixel mask
		mov	cl, 8
		cmp	al, BMF_8BIT			; might need this
		jmp	maskLoop
handleMonoInit:
		mov	ch, 0x80			; pixel mask
		mov	cl, 1
		jmp	maskLoop

		; mask loop, but for 24 bits/pixel
loop24:
		mov	dl, dh				; set up mask mask
		and	dl, ds:[si]			; bit clear ?
		jz	maskPix24
donePix24:
		shr	dh, 1
		jnc	bumpPixMask24
		inc	si
		mov	dh, 0x80
bumpPixMask24:
		add	di, 3
		loop	loop24
		jmp	exit

maskPix24:
		mov	dl, 0xff
		mov	es:[di], dl		; make it white
		mov	es:[di+1], dl		; 
		mov	es:[di+2], dl		; 
		jmp	donePix24

MaskOffPixels	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompactRGBPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out RGB values

CALLED BY:	INTERNAL
		EmitColorScan

PASS:		al	- R
		bl	- G
		bh	- B

RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompactRGBPixel	proc	near
		uses	ax, bx, cx, dx
tgs		local	TGSLocals
		.enter	inherit

		; do some color correction

		call	MapRGBForPrinter

		; write out the RGB values

		push	bx			; save green and blue
		lea	bx, tgs.TGS_bmRed	; do red first
		call	CompactPixel		
		pop	ax			; restore green and blue
		lea	bx, tgs.TGS_bmGreen
		call	CompactPixel
		mov	al, ah			; do blue
		lea	bx, tgs.TGS_bmBlue
		call	CompactPixel

		.leave
		ret

CompactRGBPixel	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompactPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compact one component (R,G,B) of a pixel

CALLED BY:	INTERNAL
		CompactRGBPixel

PASS:		al	- component to compact
		ss:bx	- pointer to ColorCompact structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		the ColorCompact structure has all we need

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompactPixel	proc	near
		uses	ax, si, cx
tgs		local	TGSLocals
		.enter	inherit

		; if offset is bogus, then just store the pixel value

		tst	ss:[bx].CC_offset	; bogus if negative
		js	handlePixel1		; first pixel

		; not the first time through.  Check to see if we can just
		; exit quickly

		cmp	al, ss:[bx].CC_pixel	; check new vs. curr
		jne	pixelDifferent
		tst	ss:[bx].CC_count	; if count negative, repeating
		jns	changeToRepeat		;  no, was doing unique bytes
		cmp	ss:[bx].CC_count, 128	; if 128 already, need to start
		LONG je	startAnotherRepeatRun	;  another run
		dec	ss:[bx].CC_count	; add one to repeat count
done:
		.leave
		ret

		; handle the first pixel
handlePixel1:
		mov	ss:[bx].CC_offset, 0
		mov	ss:[bx].CC_count, 0
		mov	ss:[bx].CC_pixel, al
		jmp	done

		; we were doing unique bytes, now change to repeat
changeToRepeat:
		mov	si, ss:[bx].CC_chunk	; get handle
		mov	si, ds:[si]		; dereference
		add	si, ss:[bx].CC_offset
		mov	al, ss:[bx].CC_count	; get count
		tst	al			; if zero, skip the write
		jz	resetCount
		dec	al			; else stored count is one less
		mov	ds:[si], al
		clr	ah
		add	ax, 2
		add	ss:[bx].CC_offset, ax
resetCount:
		mov	ss:[bx].CC_count, 0xff	; reset count
		jmp	done

		; OK, new pixel is different than old one.  Check what we
		; were doing...
pixelDifferent:
		mov	si, ss:[bx].CC_chunk	; always need this
		mov	si, ds:[si]		; dereference
		add	si, ss:[bx].CC_offset	; offset into chunk
		xchg	al, ss:[bx].CC_pixel	; store old byte, set new up
		cmp	ss:[bx].CC_count, 127	; check count
		jae	changeToUnique		; was repeat...
		clr	ch
		mov	cl, ss:[bx].CC_count	; get previous count
		inc	cx			; bump past count byte
		add	si, cx			; index to where byte goes
		mov	ds:[si], al		; store byte
		inc	ss:[bx].CC_count	; one more unique byte stored
		jmp	done

		; were doing repeat count, changing to unique bytes
changeToUnique:
		je	uniqueTooLong		; start another unique string
		mov	ah, ss:[bx].CC_count	; write out count
		mov	ds:[si], ah
		mov	ds:[si+1], al		; store old pixel value
		clr	ss:[bx].CC_count	; reset count for unique bytes
		add	ss:[bx].CC_offset, 2	; bump to next location
		jmp	done
		
		; unique string grew too long.  Terminate current one & start
		; new one
uniqueTooLong:
		mov	cl, ss:[bx].CC_count	; store old pixel at right loc
		clr	ch
		mov	ds:[si], cl		; first store count
		inc	cx			; bump past count byte
		add	si, cx			; this is where we store it
		mov	ds:[si], al		; store old pixel value
		mov	ss:[bx].CC_count, 0	; clear count
		inc	cx
		add	ss:[bx].CC_offset, cx	; bump offset
		jmp	done

		; we've run out of room in our repeat run.  Start another, but
		; first write out the one we're currently on
startAnotherRepeatRun:
		mov	si, ss:[bx].CC_chunk	; get chunk handle
		mov	si, ds:[si]		; deref chunk
		add	si, ss:[bx].CC_offset	; index into chunk
		mov	{byte} ds:[si], 128	; set max count
		mov	ds:[si+1], al		; set value
		mov	ss:[bx].CC_count, 0	; set count to zero again
		add	ss:[bx].CC_offset, 2	; bump offset
		jmp	done
		

CompactPixel	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TerminateCompactedLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Companion routine to CompactPixel.  Called at the end of a
		scan line

CALLED BY:	INTERNAL
		WriteCompactedScan

PASS:		ss:bx	- pointer to ColorCompact structure

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		write out the last run to the buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TerminateCompactedLine	proc	near
		uses	ax, si, cx
tgs		local	TGSLocals
		.enter	inherit

		; deref the chunk first

		mov	si, ss:[bx].CC_chunk	; get handle
		mov	si, ds:[si]		; deref it
		add	si, ss:[bx].CC_offset	; offset into chunk
		mov	al, ss:[bx].CC_count	; terminate depends on this
		tst	al
		jns	termUnique		; terminate unique run

		mov	ds:[si], al		; store count
		mov	al, ss:[bx].CC_pixel	; then store pixel
		mov	ds:[si+1], al		; store pixel value
		add	ss:[bx].CC_offset, 2

		; OK everything is now in the buffer, and the offset has the
		; count of bytes to convert
writeOutLine:
		mov	cx, ss:[bx].CC_offset	; cx = #bytes to write
		mov	si, ss:[bx].CC_chunk	; deref chunk again
		mov	si, ds:[si]		; ds:si -> data to write
byteLoop:
		lodsb				; get next byte
		call	ByteToHexAscii		; convert it
		add	tgs.TGS_nchars, 2	; see if line is complete
		cmp	tgs.TGS_nchars, 240
		jb	goloop
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
		mov	tgs.TGS_nchars, 0	; reset count
goloop:		
		loop	byteLoop
		.leave
		ret

		; unique run
termUnique:
		mov	ah, ss:[bx].CC_count	; get count
		mov	ds:[si], ah		; store count
		clr	ah			; calc offset into run
		inc	ax			; bump past count
		add	si, ax
		inc	ax			; offset will be after this
		add	ss:[bx].CC_offset, ax	; bump offset too
		mov	ah, ss:[bx].CC_pixel	; get last pixel
		mov	ds:[si], ah		; store it
		jmp	writeOutLine

TerminateCompactedLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCompactedScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out compacted color information for a scan line

CALLED BY:	INTERNAL
		EmitColorScan

PASS:		tgs	- stack frame with everything we need

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just convert the stuff to ascii and send it out

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteCompactedScan	proc	near
		uses	ax, bx
tgs		local	TGSLocals
		.enter	inherit

		; set up es:di -> buffer.  

		mov	tgs.TGS_nchars, 0	; to keep track of #buff chars
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> output buffer

		; terminate all the runs, then write them out

		lea	bx, tgs.TGS_bmRed	; terminate red run
		call	TerminateCompactedLine
		lea	bx, tgs.TGS_bmGreen	; terminate red run
		call	TerminateCompactedLine
		lea	bx, tgs.TGS_bmBlue	; terminate red run
		call	TerminateCompactedLine

		; if any left, terminate with CRLF and write it out

		tst	tgs.TGS_nchars		; if zero, really done
		jz	done
		mov	al, C_CR		; else store CRLF
		mov	ah, C_LF
		stosw				; store word
		call	EmitBuffer		; write it out
done:
		.leave
		ret
WriteCompactedScan	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitGreyScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a scan line from a color bitmap

CALLED BY:	INTERNAL
		EmitGreyBitmap

PASS:		ds:si	- pointer to data
		tgs, on stack

RETURN:		ds:si	- pointer after data just written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert the bitmap data to hex, apply mask, do decompaction.
		Not neccesarily in that order.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitGreyScan	proc	near
		uses	es, di, cx, ax
tgs		local	TGSLocals
		.enter	inherit

		mov	tgs.TGS_nchars, 0		; zero out #chars (used
							;   by WriteHexByte)
		test	tgs.TGS_bmType, EPS_COMPACTED 	; compacted ?
		LONG jnz decompactScan		;         (see EmitBitmap}
		mov	ax, tgs.TGS_bmBytesPL		; bump past
		add	tgs.TGS_bmDataPtr, ax

		; alright.  have decompacted data.  If mask, use a different 
		; loop.  Setup es:di -> tgs buffer
convertScan:
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer		; es:di -> output buff
		mov	cx, tgs.TGS_bmWidth		; do this many bytes
		test	tgs.TGS_bmType, mask BMT_MASK	; if mask, do it diff
		jz	doneWithMask
		call	MaskOffPixels

		; no mask.  just convert the data.  use the TGS_nchars for a
		; character count.
doneWithMask:
		mov	al, tgs.TGS_bmType		; get type
		and	al, mask BMT_FORMAT		; isolate color type
		cmp	al, BMF_4BIT			; different loop if 
							;  more colors
		jne	bigcolor
nomaskLoop:
		lodsb					; get next byte
		mov	ah, al
		push	ax
		shr	ah, 1				; need high nibble
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1
		call	MapBitmapColorIndex
		call	WriteGreyPixel			; write it out
		pop	ax
		dec	cx				; one less pixel
		jcxz	makeRightWhite
		and	ah, 0xf				; isolate low nibble
writeRight:
		call	MapBitmapColorIndex
		call	WriteGreyPixel			; write it out
		loop	nomaskLoop
done:		
		cmp	tgs.TGS_nchars, 0		; if non-zero
		jz	exit
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer
exit:
		mov	si, tgs.TGS_bmDataPtr		; ds:si -> next scan 
		.leave
		ret

makeRightWhite:
		mov	ah, 0xf
		inc	cx
		jmp	writeRight
;--------------------------------------------------------------------------
		; it's either 8 or 24-bits per pixel, withou a mask
bigcolor:
		cmp	al, BMF_24BIT
		je	hugeColor
pix8Loop:
		lodsb					; get next byte
		mov	ah, al				; load up index in ah
		call	MapBitmapColorIndex
		call	WriteGreyPixel		; write it out
		loop	pix8Loop
		jmp	done

		; 24-bit color.  go for it.
hugeColor:
		lodsw					; 
		mov	bx, ax
		lodsb
		xchg	al, bl
		xchg	bl, bh
		call	WriteGreyPixel
		loop	hugeColor
		jmp		done

		; we need to decompact the sucker first. Use the convenient
		; already-allocated-extra-chunk.
decompactScan:
		segmov	es, ds, di			; es -> block
		mov	di, tgs.TGS_xtrachunk		; get chunk handle
		mov	di, ds:[di]			; es:di -> chunk
		push	di
		mov	cx, tgs.TGS_bmBytesPL		; #bytes per scan line
		call	UncompactPackBits		; do it
		mov	tgs.TGS_bmDataPtr, si		; save for next time
		pop	si				; ds:si -> uncompacted
		jmp	convertScan

EmitGreyScan	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteGreyPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out Grey values

CALLED BY:	INTERNAL
		EmitColorScan

PASS:		al	- R
		bl	- G
		bh	- B

RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteGreyPixel	proc	near
		uses	cx, dx
tgs		local	TGSLocals
		.enter	inherit

		; calculate grey value.  Want red*.375 + green*.5 + blue*.125

		shr	al, 1			; red * .5
		shr	al, 1			; red * .25
		mov	dl, al
		adc	dl, 0			; round up from shift
		shr	al, 1
		add	al, dl			; al = red * .375
		shr	bl, 1			; cl = green * .5
		adc	al, bl			; add and round
		shr	bh, 1			; ch = blue * .5
		shr	bh, 1			; ch = blue * .25
		shr	bh, 1			; ch = blue * .125
		adc	al, bh			; add and round
		push ax
		shr	al, 1			; reduce to 4 bits
		shr	al, 1
		shr	al, 1
		shr	al, 1
		call	NibbleToHexAscii
		add	tgs.TGS_nchars, 1	; bump character count
		pop ax
		mov	ah, tgs.TGS_bmType	; get type to check width
		and	ah, mask BMT_FORMAT
		cmp	ah, BMF_8BIT
		jb	pixdon				; no 8bit image, discard low nibble
		call	NibbleToHexAscii
		add	tgs.TGS_nchars, 1	; bump character count

pixdon:	cmp	tgs.TGS_nchars, 240	; if at line's end
		jb	done
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
		mov	tgs.TGS_nchars, 0	; reset count
done:
		.leave
		ret
WriteGreyPixel	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UncompactPackBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompact a block of data that is compacted in the
		Macintosh PackBits format.

CALLED BY:	INTERNAL
		BMGetSlice

PASS:
		ds:si	- segment,offset to data to uncompact
		es:di	- segment, offset to buffer to place uncompacted data
		cx	- # of bytes after uncompaction
RETURN:
		ds:si 	- segment, offset to first byte after compacted data
		es:di	- segment, offset to first byte after uncompacted

DESTROYED:
		cx

PSEUDO CODE/STRATEGY:
	see Macintosh documentation on PackBits

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	no error flagged in uncompacted data larger than cx bytes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/29/89		Initial version
	jim	1/27/90		Didn't work if passed cx > 256.  added "clr cx"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UncompactPackBits	proc	near
	push	ax,bx,dx
	clr	dh			;for 16 bit subtractions later
	mov	bx,cx			;use bx as total count
	clr	cx			; clear out count register
UPB_5:
	lodsb				;get flag/count byte
	tst	al
	jns	UPB_100			;jmp for discrete bytes
	neg	al			;convert to number of bytes packed
	inc	al			;i.e. number of copies plus the orig
	mov	dl,al			;save num bytes for sub from total
	mov	cl,al			;move into count register
	lodsb				;get byte to duplicate
	mov	ah,al			;so can duplicate as words
	shr	cl,1			;number of words to duplicate
	jnc	UPB_10			;jmp if even number of bytes
	stosb				;store odd byte
UPB_10:
	rep	stosw			;store copies of byte
UPB_20:
	sub	bx,dx			;subtract from total uncompacted bytes
	ja	UPB_5			;jmp if more bytes
	pop	ax,bx,dx
	ret

UPB_100:
	inc	al			;convert to number of discrete bytes
	mov	cl,al			;move into count register
	mov	dl,al			;save num bytes for sub from total
	shr	cl,1			;move discrete words not bytes
	jnc	UPB_120			;jmp if even number of bytes
	movsb				;move odd byte
UPB_120:
	rep	movsw			;move discrete bytes
	jmp	short	UPB_20
UncompactPackBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractBitmapElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special routine to extract bitmap element from gstring
		or bitmap

CALLED BY:	EmitBitmap

PASS:		tgs	- inherited locals
		si	- gstring handle
RETURN:		ds:si	- pointer to next part of data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtractBitmapElement	proc	near
tgs		local	TGSLocals
		.enter	inherit

		segmov	ds, tgs.TGS_options
		test	ds:[PSEB_status], mask PSES_EXPORTING_BITMAP
		jz	gstring

		call	ExtractBitmapSlice
		jmp	done

gstring:
		call	ExtractElement
done:
		.leave
		ret
ExtractBitmapElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractBitmapSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract bitmap slice

CALLED BY:	INTERNAL
PASS:		tgs	- inherited locals
		si	- gstring handle
RETURN:		ds:si	- pointer to next part of data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtractBitmapSlice	proc	near
tgs		local	TGSLocals
		uses	ax,bx,cx,dx,di,bp,es
		.enter	inherit

	; Get bitmap slice

		mov	bx, tgs.TGS_bmFile	; bx = bitmap file
		mov	di, tgs.TGS_bmBlock	; di = bitmap block
		mov	ax, tgs.TGS_bmScansPS	; ax = #scanlines in last slice
		add	tgs.TGS_bmSliceFS, ax	; update slice first scanline #
		clr	dx
		mov	ax, tgs.TGS_bmSliceFS	; dx:ax = 1st scanline of slice
		call	HugeArrayLock		; ds:si	= pointer to element
						; ax = # of elements in slice
						; dx = size of element
		mov	cx, ax			; cx = # of elements in slice
		mul	dx			; ax = size of slice
		mov	dx, ax			; dx = size of slice
		add	dx, (size OpDrawBitmapAtCP) + (size CBitmap)
		xchg	cx, dx			; cx = size of bitmap slice
						; dx = # of elements in slice
	; Limit slice height to bitmap height

		cmp	dx, tgs.TGS_bmHeight	; is slice taller than bitmap?
		jbe	heightOK		; skip if not
		mov	dx, tgs.TGS_bmHeight	; slice height = bitmap height
heightOK:

	; Resize chunk to store bitmap slice

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock

		push	ds
		mov	ds, ax
		mov	es, ax
		mov	ax, tgs.TGS_chunk.chunk	; ax = chunk handle
		call	LMemReAlloc		; reallocate to store bm slice

	; Fill in bitmap slice info

		mov	di, ax			; di = chunk handle
		mov	di, ds:[di]		; ds:di = chunk
		mov	ds:[di].ODBCP_opcode, GR_DRAW_BITMAP_CP
		mov	ds:[di].ODBCP_size, cx
		add	di, size OpDrawBitmapAtCP	; ds:di = CBitmap
		memmov	ds:[di].CB_simple.B_width, tgs.TGS_bmWidth, ax
		memmov	ds:[di].CB_simple.B_height, tgs.TGS_bmHeight, ax
		memmov	ds:[di].CB_simple.B_type, tgs.TGS_bmType, al
		mov	ds:[di].CB_simple.B_compact, BMC_UNCOMPACTED
		mov	ds:[di].CB_startScan, 0
		mov	ds:[di].CB_numScans, dx
		mov	ds:[di].CB_devInfo, 0
		mov	ds:[di].CB_data, size CBitmap
		mov	ds:[di].CB_palette, 0
		memmov	ds:[di].CB_xres, tgs.TGS_bmXres, ax
		memmov	ds:[di].CB_yres, tgs.TGS_bmYres, ax
		pop	ds

	; Copy bitmap data

		add	di, size CBitmap	; es:di = CB_data
		sub	cx, (size OpDrawBitmapAtCP) + (size CBitmap)
		shr	cx, 1
		jnc	10$
		movsb
10$:		rep	movsw			; copy bitmap data

		tst	dx			; if no scanlines
		jz	done			;  then skip unlock

		call	HugeArrayUnlock		; unlock bitmap vm block
done:
		segmov	ds, es
		mov	si, tgs.TGS_chunk.chunk
		mov	si, ds:[si]		; ds:si = OpDrawBitmapAtCP

		.leave
		ret
ExtractBitmapSlice	endp

ExportBitmap	ends



