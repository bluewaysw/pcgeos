COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KLib Graphics
FILE:		graphicsBitmapString.asm

AUTHOR:		Jim DeFrisco, 5 April 1990

ROUTINES:
	Name			Description
	----			-----------
	BitmapToString		write out a bitmap to a gstring

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/5/90		Initial revision


DESCRIPTION:
	code to write a bitmap out to a gstring
		

	$Id: graphicsBitmapString.asm,v 1.1 97/04/05 01:12:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsStringStore	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapToString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out bitmap to a graphics string

CALLED BY:	INTERNAL
		GrDrawBitmap, GrDrawBitmapAtCP

PASS:		dx:cx	- vfptr to app supplied callback (dx=0 if no callback)
		bp:si	- pointer to bitmap
		di	- gstring handle
		ds	- gstate segment

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		if (simple)
		    SliceToString;
		else
		    do
			SliceToString;
			get next slice;
		        until (no more slices)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapToString	proc	far
		uses	ds, bp
		.enter

		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		jnz	path			; jump if defining a path
		mov	ds, bp			; ds:si -> bitmap

		; determine if bitmap is simple or not

		mov	al, GSE_INVALID		; first slice has no opcode
		test	ds:[si].B_type, mask BMT_COMPLEX
		jnz	complex			; handle complex case
		call	SliceToString		; copy this one out
exit:
		.leave
		ret

		; writing to a path, so go do it
path:
		call	BitmapToPath
		jmp	exit

		; complex bitmap, write it out a slice at a time
complex:
if	FULL_EXECUTE_IN_PLACE
EC<		tst	dx					>
EC<		jz	goAhead					>
EC<		push	bx, si					>
EC<		movdw	bxsi, dxcx				>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		pop	bx, si					>
goAhead::
endif
		mov	bp, sp			; allocate stack frame
		push	dx, cx			; push segment, then offst
		clr	cx			; store #scans written
		jmp	start			; start at beginning  :)
sliceLoop:
if	FULL_EXECUTE_IN_PLACE
		mov	ss:[TPD_dataAX],ax
		mov	ss:[TPD_dataBX],bx
		movdw	bxax,ss:[bp-4]
		call	ProcCallFixedOrMovable
else
		call	{dword} ss:[bp-4]	; do callback
endif
		mov	al, GSE_BITMAP_SLICE	; pseudo-opcode to write
start:
		call	SliceToString		; write out this slice
		tst	{word}ss:[bp-2]		; if zero, bail
		jz	doneSlices
		add	cx, ds:[si].CB_numScans	; bump to next #scans
		cmp	ds:[si].B_height, cx	; are we done yet ?
		ja	sliceLoop		;  no, still more to do
	
		; done with complex bitmap, cleanup and exit
doneSlices:
		mov	sp, bp			; restore stack pointer
		jmp	exit			; now really all done...
BitmapToString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SliceToString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a slice of a bitmap to a graphics string

CALLED BY:	INTERNAL
		BitmapToString

PASS:		ds:si	- pointer to bitmap slice 
		di	- gstring handle
		al	- either GSE_INVALID (if this is the first/only slice)
			  or GSE_BITMAP_SLICE (if this is a follow-on slice)

RETURN:		nothing

DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
		if(uncompacted)
		    calc size of bitmap;
		    copy bytes to graphics string;
		else
		    for (each row of slice)
			calc #bytes in row;
			copy row to graphics string;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SliceToString	proc	near

		; save some regs and the offsets to data and palette.

		test	ds:[si].B_type, mask BMT_COMPLEX
		jz	offsetsHandled
		push	ds:[si].CB_palette	; save offsets we screw with
		push	ds:[si].CB_data
offsetsHandled:
		push	 cx, si			; save regs

		; see if we need to write out a pseudo-op to begin the slice

		push	ax			; save opcode so we can tell
						;  if it is 1st slice or not
		cmp	al, GSE_INVALID
		je	checkSimple
		mov	cx, (GSSC_DONT_FLUSH shl 8)
		call	GSStoreBytes		; save the pseudo-op

		; check for simple bitmap
checkSimple:
		mov	cx, size Bitmap		; assume simple bitmap
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex bitmap ?
		LONG jnz STS_complex		;  yes, handle it
		mov	ax, ds:[si].B_height	; height of slice

		; figure out how many bytes in bitmap, cx = header size +
		; size of color table if there is one
STS_calcSize:
		push	cx			; save #bytes in header
		push	ax			; save #scans in slice
		mov	al, ds:[si].B_type 	; format info
		mov	cx, ds:[si].B_width	; get #bits wide
		call	CalcLineSize		; get #bytes/scan line

		; see if compacted...	ax = #bytes/uncompacted scan line

;		cmp	ds:[si].B_compact, BMC_UNCOMPACTED ; check for no compact
;		LONG jne STS_compacted		; deal with compacted one
;handle LGZ format:
		cmp	ds:[si].B_compact, BMC_PACKBITS
		LONG je	STS_compacted
		cmp	ds:[si].B_compact, BMC_LZG
		LONG je	STS_lzged

		; not compacted, just *height for #bytes to transfer

		pop	dx			; dx = #scans in this slice
		mul	dx			; ax = #bytes to transfer
		pop	bx			; restore #header bytes
		add	bx, ax			; total #bytes to transfer
writeIt:
		push	bx			; save count
		mov	al, GSE_INVALID
		mov	cl, 2			; size is 1 word
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; write out the size
		pop	cx			; restore count

		; if the bitmap is complex, the components may not be right
		; after one another.

		pop	ax			; restore opcode
		test	ds:[si].B_type, mask BMT_COMPLEX
		jnz	storeComplex
		mov	ah, GSSC_FLUSH
		call	GSStore			; copy bitmap slice & header
STS_exit:
		pop	cx, si			; restore regs

		; finally, we should restore the offsets that we mucked with,
		; if we mucked with them

		test	ds:[si].B_type, mask BMT_COMPLEX
		jz	done
		pop	ds:[si].CB_data
		pop	ds:[si].CB_palette
done:
		ret

;-------------------------------------------------------------------------

		; write out the header, then the color table, then the data.
		; Since we're changing where things are stored, we have to
		; change the offsets stored in the header before we write it 
		; out.
storeComplex:
		push	ds:[si].CB_data		; save offset
		cmp	al, GSE_BITMAP_SLICE	; only store palette for first
		je	noPalette
		test	ds:[si].B_type, mask BMT_PALETTE ; color table there ?
		jnz	storePalette
noPalette:
		mov	ds:[si].CB_data, size CBitmap
		mov	cx, size CBitmap	; write out header
		sub	bx, cx			; adjust size of data
		mov	ax, (GSSC_DONT_FLUSH shl 8) or GSE_INVALID
		call	GSStore			; write header
storeData:
		pop	ax			; restore offset
		mov	ds:[si].CB_data, ax
		add	si, ax			; bump pointer to data
		mov	cx, bx			; restore count
		mov	ax, (GSSC_FLUSH shl 8) or GSE_INVALID		; 
		call	GSStore			; copy bitmap slice & header
		jmp	STS_exit

storePalette:
		mov	ax, ds:[si].CB_palette	; grab color offset
		push	ax			; and save it
		mov	cx, size CBitmap	; going to store header first
		mov	ds:[si].CB_palette, cx
		sub	bx, cx			; reduce data size by this much
		add	si, ax			; to get size of Palette
		mov	cx, ds:[si]		; cx = #pal entries
		sub	si, ax			; get back bitmap pointer
		mov	ax, cx			; calc size of Palette
		shl	cx, 1
		add	ax, cx
		add	ax, 2 + size CBitmap	; ax = offset to data
		mov	ds:[si].CB_data, ax
		mov	cx, size CBitmap
		mov	ax, (GSSC_DONT_FLUSH shl 8) or GSE_INVALID
		call	GSStore			; write header
		pop	ax			; restore offset to color
		mov	ds:[si].CB_palette, ax	; store it in header
		mov	cx, ds:[si].CB_data	; get data offset
		sub	cx, size CBitmap	; cx = size of Palette
		sub	bx, cx			; bx = data size
		push	si
		add	si, ax			; ds:si -> palette
		mov	ax, (GSSC_DONT_FLUSH shl 8) or GSE_INVALID
		call	GSStore			; write header
		pop	si
		jmp	storeData
		
		; complex bitmap, get height of slice and size of header and
		; any color table present
STS_complex:
		mov	cx, size CBitmap
		test	ds:[si].B_type, mask BMT_PALETTE ; color table there ?
		jz	noColorTable
		
		; there's a palette stored.  Calculate the size of the palette
		; via the number of entries there (first word).
		
		mov	bx, ds:[si].CB_palette	; get offset to color table
		add	cx, 2			; 1word for #entries
		mov	ax, ds:[si][bx]		; get #entries
		add	cx, ax			; need *3 for RGB values
		shl	ax, 1
		add	cx, ax			; cx = size Header + table size
noColorTable:
		mov	ax, ds:[si].CB_numScans	; #scans in this slice
		jmp	STS_calcSize		; calc size of transfer

		; compacted bitmap, deal with it a scan at a time
		; ds:si = Bitmap/CBitmap
		; ax = #bytes/uncompacted scanline
		; ss:sp -> # scans in this slice
		; 	   # header bytes
STS_compacted:
		pop	dx			; #scans in this slice
		mov	bx, ax			; save #uncompacted bytes/scan
		pop	ax			; init count to #header bytes
		push	si			; save original pointer
		test	ds:[si].B_type, mask BMT_COMPLEX
		jnz	pointToData
	
		add	si, ax			; start calc at first data byte
STS_countem:
		call	CalcPackbitsBytes	; see how many to copy
		add	ax, cx			; bump #scans in slice
		add	si, cx			; bump pointer too
		dec	dx			; one fewer scan left to do
		jne	STS_countem		; count how many in next scan
	
afterCompacted:
		; have total count of bytes, write em out
		mov	bx, ax			; bx <- total # bytes (w/
						;  header)
		pop	si			; ds:si <- Bitmap
		jmp	writeIt

pointToData:
		; bitmap is complex, so header size isn't sufficient to
		; determine the start of the data. use the CB_data field
		; instead.

		add	si, ds:[si].CB_data

		; if this happens to be the first slice, then there's no
		; need to STS_countem.  
		tst	dx
		jz	afterCompacted
	
		jmp	STS_countem

;too difficult to share STS_compacted code, so dup it here
		; LZGed bitmap, deal with it a scan at a time
		; ds:si = Bitmap/CBitmap
		; ax = #bytes/uncompacted scanline
		; ss:sp -> # scans in this slice
		; 	   # header bytes
STS_lzged:
		pop	dx			; #scans in this slice
		mov	bx, ax			; save #uncompacted bytes/scan
		pop	ax			; init count to #header bytes
		push	si			; save original pointer
		test	ds:[si].B_type, mask BMT_COMPLEX
		jnz	lz_pointToData
	
		add	si, ax			; start calc at first data byte
lz_STS_countem:
		call	LZGSourceSize		; see how many to copy
		add	ax, cx			; bump #scans in slice
		add	si, cx			; bump pointer too
		dec	dx			; one fewer scan left to do
		jne	lz_STS_countem		; count how many in next scan
	
lz_afterCompacted:
		; have total count of bytes, write em out
		mov	bx, ax			; bx <- total # bytes (w/
						;  header)
		pop	si			; ds:si <- Bitmap
		jmp	writeIt

lz_pointToData:
		; bitmap is complex, so header size isn't sufficient to
		; determine the start of the data. use the CB_data field
		; instead.

		add	si, ds:[si].CB_data

		; if this happens to be the first slice, then there's no
		; need to STS_countem.  
		tst	dx
		jz	lz_afterCompacted
	
		jmp	lz_STS_countem

SliceToString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPackbitsBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc number of bytes in a packbits-compacted scan line

CALLED BY:	INTERNAL
		SliceToString

PASS:		ds:si	- far pointer to start of next scan of data
		bx	- #bytes when uncompacted (line length)

RETURN:		cx	- #bytes in scan

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		act as if decompacting, but don't write anything

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcPackbitsBytes proc	near
		push	ax,bx,si	; save trashed regs
		clr	ah		; for 16 bit subtractions later
		clr	cx		; use cx as total compacted count

		; starting a packet, get flag/counts byte
CPB_5:
		lodsb			; get flag/count byte
		inc	cx		; count one for the flag/count byte
		tst	al
		jns	CPB_100		; jmp for discrete bytes

		; repeat count with data byte, just inc nbytes and pointer,
		; dec #uncompacted bytes appropriately

		inc	cx		; one more byte in 
		inc	si		; bump to next flag/count byte
		neg	al		;convert to number of bytes packed
		inc	al		;i.e. number of copies plus the orig
CPB_20:
		sub	bx, ax		; subtract from total uncompacted bytes
		jne	CPB_5		; jmp if more bytes
		pop	ax,bx,si
		ret

;-----------------------------------------------------------------------------
		; discrete bytes, see how many
CPB_100:
		inc	al		; convert to number of discrete bytes
		add	cx, ax		; bump count of compacted bytes 
		add	si, ax		; bump pointer too
		jmp	short	CPB_20
CalcPackbitsBytes endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeBitmapToString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a bitmap stored in a HugeArray to a graphics string

CALLED BY:	EXTERNAL
		GrDrawHugeBitmap
PASS:		dx	- VM file handle (or zero if TPD_file is set)
		cx	- VM block handle
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeBitmapToString	proc	far
		uses	ds, es
cbm		local	CBitmap
haFile		local	word
haBlock		local	word
scanSize	local	word
		.enter

		mov	ss:haFile, dx		; store where it is
		mov	ss:haBlock, cx
		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		jz	normalBitmap		; not a path

		; writing to a path, so go do it

		push	bp			; save frame pointer
		mov	bx, dx	
		mov	di, cx			; bx.di = HugeArray handle
		call	HugeArrayLockDir	; ax -> Directory
		mov	bp, ax			; ds -> EditableBitmap
		mov	si, offset EB_bm
		call	BitmapToPath		; write out rectangle element
		mov	ds, bp			; setup to unlock HugeArray
		call	HugeArrayUnlockDir	; release HugeArray block
		pop	bp			; restore frame pointer
		jmp	exit

		; write out each HugeArray block as a separate slice.
		; Start by reading the Complex Bitmap header into some
		; local scratch space
normalBitmap:
		push	ds			; save GState
		push	di			; save GString handle
		mov	bx, dx	
		mov	di, cx			; bx.di = HugeArray handle
		call	HugeArrayLockDir	; ax -> Directory
		mov	ds, ax			; ds -> EditableBitmap
		mov	ax, ds:[HAD_size]	; get element size
		mov	ss:scanSize, ax		; save it for later
		mov	si, offset EB_bm	; ds:si -> CBitmap struct
		segmov	es, ss, di
		lea	di, ss:cbm		; es:di -> local space
CheckHack <(size CBitmap AND 1) eq 0>
		mov	cx, size CBitmap / 2	; #words to move
		rep	movsw			; cx clear after this

		; initialize the numScans and startScan to zero, and write out
		; the first slice (0 data bytes) including any palette.

		and  	ss:cbm.CB_simple.B_type, not mask BMT_HUGE
		mov	ss:cbm.CB_startScan, cx	; 0
		mov	ss:cbm.CB_numScans, cx	; 0
		mov	cx, size CBitmap 	; in case there is one
		mov	ss:cbm.CB_palette, cx	; in case there is one
		
		; this block will be (size CBitmap) + size of palette, if there
		; is one.  Since we have to write out the size of the block
		; first, figure this total size out.

		mov	bx, cx			; bx = data size
		test	ss:cbm.CB_simple.B_type, mask BMT_PALETTE ; palette ?
		jz	writeSize
		inc	bx			; at least two for pal size
		inc	bx
		mov	si, offset EB_bm	; ds:si -> CBitmap struct
		add	si, ds:[si].CB_palette	; get access to palette
		mov	ax, ds:[si]		; ax = #pal entries
		add	bx, ax			; we need this *3
		shl	ax, 1
		add	bx, ax			; bx = block size
writeSize:
		pop	di			; restore GString handle
		mov	ax, (GSSC_DONT_FLUSH shl 8) or GSE_INVALID
		mov	cx, 2			; just writing a word
		call	GSStoreBytes

		; write out the header
		
		mov	dx, ds			; save HugeArray blk hdr seg
		segmov	ds, ss, si
		lea	si, ss:cbm		; ds:si -> header
		mov	cx, size CBitmap	; writing this many bytes
		test	ds:[si].B_type, mask BMT_PALETTE ; is there a palette 
		jnz	writeHeader
		mov	ah, GSSC_FLUSH
		call	GSStore
		mov	ds, dx
		jmp	unlockHADir		; continue with data slices
writeHeader:
		call	GSStore			; write out header

		; write out the palette

		mov	ds, dx			; restore HugeArray block
		mov	si, offset EB_bm
		add	si, ds:[si].CB_palette	; ds:si -> palette
		mov	cx, ds:[si]		; get #pal entries
		mov	ax, cx			; calc size of palette
		shl	cx, 1
		add	cx, ax			; cx = 3*#entries
		inc	cx
		inc	cx			; for P_entries field
		mov	ax, (GSSC_FLUSH shl 8) or GSE_INVALID
		call	GSStore			; write out palette
unlockHADir:

		; for subsequent slices, we don't want the Palette bit set
		; in the header.  So deal with it.  Harshly.

		and	ss:cbm.CB_simple.B_type, not mask BMT_PALETTE
		call	HugeArrayUnlockDir	; release directory block
		pop	ds			; restore GState pointer

		; OK, now we've written out the header and palette.  Go for
		; the data blocks.
writeNextSlice:
		call	WriteHugeArraySlice	; write a slice out
		mov	ax, ss:cbm.CB_startScan	; figure if we're done
		cmp	ax, ss:cbm.CB_simple.B_height	;  writing all scans 
		jb	writeNextSlice
exit:
		.leave
		ret

HugeBitmapToString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteHugeArraySlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a slice of HugeArray bitmap to a graphics string

CALLED BY:	HugeBitmapToString
PASS:		inherits some local variables

		di - gstring handle

RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteHugeArraySlice		proc	near
		.enter	inherit HugeBitmapToString

		push	di			;save gstring handle
		mov	ax, ss:cbm.CB_startScan
		clr	dx
		mov	bx, ss:haFile
		mov	di, ss:haBlock		; bx:di = HugeArray handle
		call	HugeArrayLock		; ds:si -> 1st element in block
		mov	ss:cbm.CB_numScans, ax	; store number we're doing
		mov	ss:cbm.CB_data, size CBitmap

		; before we write the header, we need to write the size of this
		; block.  Calculate differently based on whether scans are 
		; compacted.

		mov	cx, ss:scanSize		; see if compacted
		jcxz	calcCompactSize		;  yes, calc total size
		mul	cx			; ax = size to write

		; have the size.  Write out opcode and size
haveBlockSize:
		pop	di			;di <- gstring handle
		push	ax			; save #bytes to write
		mov_tr	bx, ax			; bx = block size
		add	bx, size CBitmap	; also writing a header
		mov	ax, (GSSC_DONT_FLUSH shl 8) or GSE_BITMAP_SLICE
		mov	cx, 2			; just writing a word
		call	GSStoreBytes

		; now write out the header
		
		push	ds, si
		segmov	ds, ss, si
		lea	si, ss:cbm
		mov	cx, size CBitmap	; writing header
		mov	al, GSE_INVALID		; no opcode this time
		mov	ah, GSSC_DONT_FLUSH	; still not done
		call	GSStore			; write out header
		pop	ds, si
		pop	cx			; restore #bytes to write

		; now write out data

		mov	ax, (GSSC_FLUSH	shl 8) or GSE_INVALID
		call	GSStore

		; update the info in the header and unlock the block

		call	HugeArrayUnlock		; release block
		mov	ax, ss:cbm.CB_numScans	; the number that we did
		add	ss:cbm.CB_startScan, ax	; scan line to start next time
		
		.leave
		ret

		; bitmap is compacted.  Figure the total size
calcCompactSize:
		mov	cx, dx			; cx = size of first scan
		jmp	nextCompactedScan
scanLoop:
		push	ax			; save #left to do
		call	HugeArrayNext		; dx = size of next scan
		add	cx, dx			; cx = total size so far
		pop	ax			; restore #left to do
nextCompactedScan:
		dec	ax			; one less to do
		jnz	scanLoop
		push	cx			; save total size
		call	HugeArrayUnlock		; release this block
		mov	ax, ss:cbm.CB_startScan	; relock at scan we want
		clr	dx
		mov	bx, ss:haFile
		mov	di, ss:haBlock		; bx:di = HugeArray handle
		call	HugeArrayLock		; ds:si -> 1st element in block
		pop	ax			; restore size to write
		jmp	haveBlockSize
WriteHugeArraySlice		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapToPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a bitmap to a path, substiting a rectangle for the bitmap

CALLED BY:	BitmapToString()

PASS:		ds	- GState segment
		bp:si	- Bitmap data
		di	- GString handle

RETURN:		Nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		We've already written the opcode (and the starting
		coordinate, if needed) to the GString, so all we need to
		do is write the ending coordinate. Unfortunately, we need
		to take into account the resolution of the bitmap to ensure
		we have the correct dimensions of the rectangle.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapToPath	proc	near
		.enter
	
		; Get the bitmap's width & height
		;
		push	ds			; save the GState segment
		mov	ds, bp
		mov	ax, ds:[si].B_width
		mov	bx, ds:[si].B_height
		test	ds:[si].B_type, mask BMT_COMPLEX
		jz	done			; simple, so we're done

		; We have a complex bitmap, so scale trhe dimensions
		;
		mov	dx, ds:[si].CB_yres
		call	ScaleBitmapSide
		xchg	ax, bx
		mov	dx, ds:[si].CB_xres
		call	ScaleBitmapSide
		xchg	ax, bx
done:
		pop	ds			; GState segment => DS
		movdw	dxcx, bxax		; save calculated values
		call	GetDocPenPos		; ax,bx = pen position
		add	ax, cx			; add in previously calc'd vals
		add	dx, bx			; dx = y value to write
		mov_tr	bx, ax			; bx = x value to write
		mov	cl, 4			; really four bytes
		mov	ch, GSSC_DONT_FLUSH
		mov	al, GSE_INVALID		; don't write an opcode
		call	GSStoreBytes		; write out the data

		.leave
		ret
BitmapToPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleBitmapSide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale the side of a bitmap, based upon the resolution

CALLED BY:	BitmapToPath()

PASS:		dx	- Resolution (DPI)
		bx	- Width or height (in pixels)

RETURN:		bx	= New width or height (in pixels)

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleBitmapSide	proc	near
		uses	ax
		.enter
	
		; First calculate the change in resolution from 72 DPI.
		; Then multiply it by the dimension.
		;
		cmp	dx, 72
		je	done
		push	bx
		clr	ax, cx
		mov	bx, 72
		call	GrUDivWWFixed		; change in resolution => DX.CX
		pop	bx
		clr	ax			; dimension => BX.AX
		call	GrMulWWFixed		; new dimension => DX.CX
		rndwwf	dxcx, bx		; rounded value => BX
done:
		.leave
		ret
ScaleBitmapSide	endp

GraphicsStringStore	ends
