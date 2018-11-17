COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		Graphics/graphicsCreateBitmap.asm

AUTHOR:		Jim DeFrisco, 5/23/90

ROUTINES:
	Name			Description
	----			-----------
	CreateBitmap		Allocate memory for a bitmap structure
	GetBitmap		Grab a portion of the screen

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/23/90		Initial revision


DESCRIPTION:
	This is where the guts of GrCreateBitmap ended up
		

	$Id: graphicsBitmapCreate.asm,v 1.1 97/04/05 01:13:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsAllocBitmap segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCreateBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate memory for a bitmap and associate it with a window

CALLED BY:	GLOBAL

PASS:		al	- BMType record 
		bx	- VM file handle
		cx	- width of bitmap to allocate
		dx	- height of bitmap to allocate
		di:si	- OD for object to get MSG_META_EXPOSED for the bitmap
			  (for process/thread, use di to pass handle)

RETURN:		ax	- VM block handle of bitmap (bx.ax = HugeArray handle)
		di	- gstate handle	
		Note:	Fatal error if the unsupported bitmap format is 
			passed in.
			
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		allocate and initialize huge array for a bitmap;
		alloc gstate and window;
		clear bitmap;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	08/89		Initial version
	Jim	10/89		Moved most to KLib
	Jon	06/91		Fixed to properly handle BMC_OD flag
	Jim	1/92		Completely re-written for 2.0 
	mg	12/00		Moved bitmap creation into GrCreateBitmapRaw

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCB_frame	struct
    GCB_width	word	?	; width of bitmap, pixels
    GCB_height	word	?	; height of bitmap, scan lines
    GCB_format	word	?	; BMFormat enum
    GCB_bmHan	word	?	; handle of allocated bitmap block
    GCB_vmHan	word	?	; VM file handle
    GCB_optr	dword	?	; optr
GCB_frame	ends

GrCreateBitmap	proc	far
		uses	bx,cx,dx,si,ds,es
GCBframe	local	GCB_frame
		.enter

		; save all the passed parameters

		mov	{byte} GCBframe.GCB_format, al
		mov	GCBframe.GCB_vmHan, bx
		mov	GCBframe.GCB_width, cx
		mov	GCBframe.GCB_height, dx

		; store OD passed.

		mov	GCBframe.GCB_optr.low, si
		mov	GCBframe.GCB_optr.high, di

		; create the huge array as requested and initialize
		; its header to match the passed parameters.

		call	GrCreateBitmapRaw
		mov	GCBframe.GCB_bmHan, ax	; save block handle to return

		; allocate a window/gstate and link the bitmap to it.

		push	bp			; we're gonna mess this up good
		clr	ax			; push some bogus parameters
		push	ax			; LayerID
		push	ax			; current process owns it
		mov	ax, GDDT_MEMORY_VIDEO	; get video driver
		call	GeodeGetDefaultDriver
		push	ax			; get video driver handle
		clr	ax
		push	ax			; passing a rectangular window
		push	ax
		mov	cx, GCBframe.GCB_height ; pass bitmap size
		dec	cx
		push	cx
		mov	cx, GCBframe.GCB_width	; pass rectangular win bounds
		dec	cx
		push	cx
		push	ax			; origin at 0,0
		push	ax
		mov	ah, mask WCF_TRANSPARENT ; no background color
		clr	cx			; no OD for METHOD_?_ENTER
		mov	dx, cx
		mov	di, GCBframe.GCB_optr.high
		mov	bp, GCBframe.GCB_optr.low
		mov	si, mask WPF_ROOT or mask WPF_INIT_EXCLUDED or \
			    mask WPF_CREATE_GSTATE
		call	WinOpen			; finally, the call
		pop	bp

		; lock down the window and enter the bitmap HugeArray handle

		call	MemPLock		; lock the window
		mov	ds, ax			; ds -> window
		mov	ax, GCBframe.GCB_vmHan	; store VM file handle
		mov	ds:[W_bitmap].segment, ax
		mov	ax, GCBframe.GCB_bmHan	; return bitmap handle
		mov	ds:[W_bitmap].offset, ax 
		call	MemUnlockV		; release window structure

		; before we leave, we should make it so we can draw to the 
		; bitmap.

		call	GrBeginUpdate		; mask region will be whole
		call	GrEndUpdate

		; also, clear the bugger.  

		call	GrClearBitmap		; clear data portion
		
		; if there is a mask there, clear that as well.

		test	{byte} GCBframe.GCB_format, mask BMT_MASK
		jnz	initMask
done:
		.leave
		ret

		; the bitmap has a mask.  Initialize it to all zeroes.
initMask:
		push	ax
		clr	dx
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode
		call	GrClearBitmap
		clr	ax
		call	GrSetBitmapMode
		pop	ax
		jmp	done
GrCreateBitmap	endp


bitsAndPlanes	label	word
		word	0101h			; BMF_MONO
		word	0401h			; BMF_4BIT
		word	0801h			; BMF_8BIT
		word	0803h			; BMF_24BIT
		word	0104h			; BMF_4CMYK
		word	0104h			; BMF_3CMY

nColorTable	label	byte
		byte	1,4,8,24,4,4		; #bits of color


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCreateBitmapRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate memory for a bitmap

CALLED BY:	GLOBAL

PASS:		al	- BMType record 
		bx	- VM file handle
		cx	- width of bitmap to allocate
		dx	- height of bitmap to allocate

RETURN:		ax	- VM block handle of bitmap (bx.ax = HugeArray handle)
		Note:	Fatal error if the unsupported bitmap format is 
			passed in.
			
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		determine huge array size;
		allocate huge array for a bitmap;
		initialize bitmap block;

	The format of the bitmap block is as follows:

	+-	+-------------------------------+
  this	|	| Complex Bitmap Header		|	size CBitmap
  part	|	+-------------------------------+
 is in	|	| BitmapMode flags (1 word)	|
   the	|	+-------------------------------+
  Huge	|	| Device Info Block		|	size VideoDriverInfo
 Array	|	+-------------------------------+
header	|	| 1-scan-line buff for vidmem	|	size depends on width
	|	+-------------------------------+
	|	| [optional palette space]	|	either 16 or 256 3-byte
	+-	+-------------------------------+	 entries
		| 				|
		| Data Buffer			|
		| 				|
		+-------------------------------+

	For internal use only:  there is an EditableBitmap structure that
				can be used to access fields in this HugeArray
				directory block.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mg	12/00		Extracted code from GrCreateBitmap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GCBR_frame	struct
    GCBR_width	 word	?	; width of bitmap, pixels
    GCBR_bwidth	 word	?	; byte width of bitmap
    GCBR_sBuffer word	?	; size of buffer in header
    GCBR_height	 word	?	; height of bitmap, scan lines
    GCBR_format	 word	?	; BMFormat enum
    GCBR_bmHan	 word	?	; handle of allocated bitmap block
    GCBR_vmHan	 word	?	; VM file handle
GCBR_frame	ends

GrCreateBitmapRaw	proc	far
		uses	bx,cx,dx,si,di,ds,es
GCBRframe	local	GCBR_frame
		.enter

		; First of all, check for the supported format. If the format
		; is not support, we quit.
		;
		push	ax
		andnf	al, mask BMT_FORMAT		;al = BMFormat
		call	IsFormatSupported		;carry clr = supported
		pop	ax
		ERROR_C	GRAPHICS_BAD_BITMAP_FORMAT	;unsupported format

		; save all the passed parameters
		
		mov	{byte} GCBRframe.GCBR_format, al
		mov	GCBRframe.GCBR_vmHan, bx
		mov	GCBRframe.GCBR_width, cx		
EC <		tst	cx				; can't have zero size>
EC <		ERROR_Z	GRAPHICS_CANT_CREATE_ZERO_SIZED_BITMAP		>
		mov	GCBRframe.GCBR_height, dx
EC <		tst	dx				; can't have zero size>
EC <		ERROR_Z	GRAPHICS_CANT_CREATE_ZERO_SIZED_BITMAP		>

		; calculate the line size (in bytes)

		call	CalcLineSize		; ax = #bytes/scan line
		mov	GCBRframe.GCBR_bwidth, ax	; save line size 

		; allocate the HugeArray

		mov	di, ax			; we need one a 1-scan buffer
		mov	cx, ax			; #bytes per element
		shl	dx, 1			; dual purpose buffer is the
						; greater of 2*(bitmap height)
						; and size of one scan line
		cmp	di, dx			; use the greater
		ja	haveBufferSize
		mov	di, dx			; 2*height is larger...
haveBufferSize:
		mov	GCBRframe.GCBR_sBuffer, di ; save this size
		mov	bx, GCBRframe.GCBR_vmHan	; get vm file handle
		add	di, size EditableBitmap

		; we might need to allocate some room for a palette.  Check 
		; that out now before we size the header...

		mov	al, {byte} GCBRframe.GCBR_format ; get format bits
		test	al, mask BMT_PALETTE	; check for palette request
		jz	allocHugeArray		;  no, allocate the array
		
		; OK, we're adding a palette.  Check the size that we need, 
		; and only do it for 4 and 8-bit/pixel bitmaps.

		add	di, size Palette + (16*size RGBValue) ; add space 
		and	al, mask BMT_FORMAT	; isolate bits/pixel
		cmp	al, BMF_4BIT		; if 4-bit, we're done
		je	allocHugeArray		;  else assume it's 8-bit
		add	di, 240 * size RGBValue	;   so we need 256 altogether
		cmp	al, BMF_8BIT		; make sure it's 8-bit...
		je	allocHugeArray		; if not, then something is bad
		sub	di, size Palette + (256*size RGBValue)
		and	{byte} GCBRframe.GCBR_format, not mask BMT_PALETTE
allocHugeArray:
		call	HugeArrayCreate		; di = huge array block handle
		mov	GCBRframe.GCBR_bmHan, di	; save block handle to return

		; while we have everything set up, allocate the scan line elem

		push	bp			; save frame pointer
		mov	cx, GCBRframe.GCBR_height ; alloc this many scan lines
		clr	bp			; no init data
		call	HugeArrayAppend		; allocate new elements
EC <		call	ECCheckHugeArrayFar				>
		call	HugeArrayCompressBlocks	; take out the extra space
EC <		call	ECCheckHugeArrayFar				>

		; lock down the directory block, so we can start initializing
		; the Complex Bitmap header and the VideoDriverInfo struct

		call	HugeArrayLockDir	; ax -> block
		mov	ds, ax			; ds -> HugeArray dir block
		mov	cx, bp			; cx = mem handle
		pop	bp			; restore frame pointer
		clr	ax			; inti some fields there...
		mov	ds:[EB_flags], ax	; assume edit data, dispersed
						;  dither
		mov	ds:[EB_color], ax	; no color correction table
		mov	si, offset EB_bm	; ds:si -> CBitmap struct

		mov	ax, GCBRframe.GCBR_width	; get parameters for new bitmap
		mov	ds:[si].B_width, ax
		mov	ax, GCBRframe.GCBR_height
		mov	ds:[si].B_height, ax
		mov	al, {byte} GCBRframe.GCBR_format
		or	al, mask BMT_HUGE or mask BMT_COMPLEX
		mov	ds:[si].B_type, al
		mov	ds:[si].B_compact, BMC_UNCOMPACTED ; no compaction here
		clr	ax			; don't make sense for Huge bm
		mov	ds:[si].CB_numScans, ax
		mov	ds:[si].CB_startScan, ax
		mov	ds:[si].CB_data, ax 	; don't need for HugeArray ver
		mov	ds:[si].CB_palette, ax	; assume no palette
		mov	ds:[si].CB_devInfo, offset EB_device - offset EB_bm

		; now we check to see if we need to initialize the Palette.

		segmov	es, ds, ax		; es -> Bitmap
		test	{byte} GCBRframe.GCBR_format, mask BMT_PALETTE
		jz	initDeviceInfo		; initialize the palette

		; OK, we're gonna initialize a palette.  We need to fill in
		; two things, the number of entries, and the palette contents

		mov	di, GCBRframe.GCBR_sBuffer ; construct pointer to Palette
		add	di, (size EditableBitmap) - (size HugeArrayDirectory)
		mov	ds:[si].CB_palette, di	; store offset to Palette
		add	di, size HugeArrayDirectory ; construct real offset
		mov	al, ds:[si].B_type	; get bitmap format
		and	al, mask BMT_FORMAT	; isolate color info
		mov	cx, 16			; assume 4-bit device
		cmp	al, BMF_4BIT		; is it 4-bit ?
		je	initBitmap		;  yes, continue
		mov	cx, 256
		cmp	al, BMF_8BIT
		je	initBitmap
		mov	cx, 2			; if not 4 | 8-bit, must be mono
initBitmap:
		LoadVarSeg	ds, ax		; ds -> idata
		mov	es:[di],cx		; set size of palette
		add	di, size Palette	; set pointer past palette size
		mov	si, offset defaultPalette ; ds:si -> default palette
		mov	ax, cx			; calc #bytes to move
		shl	cx, 1			; 3 bytes/entry
		add	cx, ax			; cx = #bytes to move
		shr	cx, 1			; calc #words (will be even)
		rep	movsw

		; now init the device info table.  First get the address of
		; the mem driver strategy routine
initDeviceInfo:
		mov	di, offset EB_bm	; es:di -> bitmap
		mov	ax, 72			; init bitmap resolution
		mov	es:[di].CB_xres, ax	
		mov	es:[di].CB_yres, ax
		mov	dx, GCBRframe.GCBR_bwidth
		call	AllocBitmapInitDeviceInfo
		segmov	ds, es, ax		; es -> Bitmap

		; we're done with the HugeArray initialization, so close it

		call	HugeArrayDirty
		call	HugeArrayUnlockDir	; release the directory block

		mov	ax, GCBRframe.GCBR_bmHan ; return bitmap handle

		.leave
		ret
GrCreateBitmapRaw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsFormatSupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed bitmap format is supported.

CALLED BY:	GrCreateBitmap()
PASS:		al	= BMFormat
RETURN:		carry	= clear (supported)
			= set (not supported)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsFormatSupported	proc	near
		uses	bx, ds, si, di
		.enter
	;
	; Get the default VidMem Driver handle.
	;
		push	ax
		mov	ax, GDDT_MEMORY_VIDEO
		call	GeodeGetDefaultDriver		;ax = GeodeHandle
		tst	ax				;no default driver?
		jz	noDriver
		mov_tr	bx, ax				;bx = GeodeHandle
		call	GeodeInfoDriver			;ds:si = info block
	;
	; If carry clear, then the bitmap format is supported. Otherwise,
	; it is not supported.
	;
		pop	ax				;al = BMFormat
		mov	di, VID_ESC_CHECK_IF_FORMAT_IS_SUPPORTED
		call	ds:[si].DIS_strategy		;carry set or clr
done:
		.leave
		ret
noDriver:
		pop	ax
		stc
		jmp	done
IsFormatSupported		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEditBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Associate a previously created bitmap with a Window and GState

CALLED BY:	GLOBAL
PASS:		bx	- VM file handle containing bitmap
		ax	- VM block handle of first block in bitmap (the 
			  directory block of the associated HugeArray)
		di:si	- OD for object to get MSG_META_EXPOSED for the bitmap
			  (for process/thread, use di to pass handle)
RETURN:		di	- GState handle to use when drawing to bitmap
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrEditBitmap	proc	far
		uses	ds, bp, ax, bx, cx, dx, si
		.enter

		; lock down the bitmap header and extract some interesting
		; information.

		push	di, si			; save OD for EXPOSEDs
		mov	di, ax			; bx:di -> HugeArray
		call	HugeArrayLockDir	; lock directory block
		mov	ds, ax			; ds -> EditableBitmap

		; while we're here, we should do a little error checking, just
		; to make sure that we have what we think we have.

EC <		test	ds:[EB_bm].CB_simple.B_type, mask BMT_COMPLEX 	>
EC <		ERROR_Z	GRAPHICS_EDIT_BITMAP_NEEDS_HUGE_BITMAP		>
EC <		tst	ds:[EB_bm].CB_devInfo	; if zero, bail		>
EC <		ERROR_Z	GRAPHICS_EDIT_BITMAP_NEEDS_HUGE_BITMAP		>
EC <		cmp	ds:[EB_bm].CB_simple.B_compact, BMC_UNCOMPACTED	>
EC <		ERROR_NE GRAPHICS_CANT_DO_THIS_WITH_COMPACTED_BITMAP	>

		; load up height and width of bitmap so we can use it to 
		; size the window

		mov	cx, ds:[EB_bm].CB_simple.B_width
		mov	dx, ds:[EB_bm].CB_simple.B_height

		; that's all we need, so release the HugeArray dir block

		call	HugeArrayUnlockDir

		; allocate a window/gstate and link the bitmap to it.
		; at this point, regs should be:
		;	bx:di	- VM file/block handle of bitmap
		;	cx,dx	- width, height

		pop	si, bp			; restore EXPOSE OD
		push	bx, di			; save VM block handle
		clr	ax			; push some bogus parameters
		push	ax			; LayerID
		push	ax			; current process owns it
		mov	ax, GDDT_MEMORY_VIDEO	; get video driver
		call	GeodeGetDefaultDriver
		push	ax			; get video driver handle
		clr	ax
		push	ax			; passing a rectangular window
		push	ax
		dec	dx			; one less for bottom coord
		push	dx
		dec	cx			; one less for right side coord
		push	cx
		push	ax			; origin at 0,0
		push	ax
		mov	ah, mask WCF_TRANSPARENT ; no background color
		clr	cx			; no OD for METHOD_?_ENTER
		mov	dx, cx
		mov	di, si			; setup EXPOSED OD in di:bp
		mov	si, mask WPF_ROOT or mask WPF_INIT_EXCLUDED or \
			    mask WPF_CREATE_GSTATE
		call	WinOpen			; finally, the call
		pop	si, dx			; restore VM block handle

		; lock down the window and enter the bitmap HugeArray handle

		call	MemPLock		; lock the window
		mov	ds, ax			; ds -> window
		xchg	si, bx			; bx = VM file han, si=win han
		mov	ds:[W_bitmap].segment, bx
		mov	ds:[W_bitmap].offset, dx 
		xchg	si, bx			; bx = window handle
		call	MemUnlockV		; release window structure

		; before we leave, we should make it so we can draw to the 
		; bitmap.

		call	GrBeginUpdate		; mask region will be whole
		call	GrEndUpdate

		; get the current resolution, so we can properly set the window
		; scale factor

		mov	si, bx			; si = window handle
		call	GrGetBitmapRes		; get the current resolution
		cmp	ax, DEF_BITMAP_RES	; if 72 dpi, done.
		jne	setScale
		cmp	bx, DEF_BITMAP_RES
		je	done
setScale:
		push	di			; save GState handle
		mov	di, si			; di = window handle
		push	ax			; save new x res
		mov	dx, bx			; do y first
		mov	bx, DEF_BITMAP_RES	; divide by default resolution
		clr	cx, ax			; no fractions
		call	GrSDivWWFixed		; dxcx = y scale to apply
		mov	ax, dx			; axcx = y scale factor
		pop	dx			; restore new x res
		mov	bx, DEF_BITMAP_RES	; divide by default res
		pushwwf	axcx			; save y scale factor
		clr	cx, ax			; no fractions
		call	GrSDivWWFixed		; dxcx = x scale factor
		popwwf	bxax			; bxax = y scale factor
		mov	si, WIF_DONT_INVALIDATE
		call	WinApplyScale
		pop	di			; restore GState handle
done:
		.leave
		ret
GrEditBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDestroyBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the bitmap, disassociate with window

CALLED BY:	GLOBAL

PASS: 		di	- gstate handle  (as returned by GrCreateBitmap)
		al	- flags controlling destruction:
				BMD_KILL_DATA	- kill bitmap data too
				BMD_LEAVE_DATA	- leave bitmap data alone
		
RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		free window and gstate, perhaps bitmap as well

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	08/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrDestroyBitmap	proc	far
		uses	ax, ds, bx
haHandle	local	dword
		.enter

		; do some error checking on passed flags

EC <		cmp	al, BMD_LEAVE_DATA				>
EC <		ERROR_A GRAPHICS_BAD_FLAGS_RESERVED_MUST_BE_0		>
		clr	haHandle.segment	; we'll use this to determine
						; if we need to kill bitmap

		push	ax			; save flag

		; get the bitmap handle.  We need to kill the window anyway

		mov	bx, di			; bx = gstate handle
		call	MemLock			; lock gstate
		mov	ds, ax
		mov	ax, ds:[GS_window]	; get window handle
		call	MemUnlock		; release gstate 
		mov	bx, ax			; load up window handle
		call	MemPLock		; lock the window
		mov	ds, ax			; ds -> Window
		mov	ax, ds:[W_bitmap].offset ; get block handle
		mov	haHandle.offset, ax
		mov	ax, ds:[W_bitmap].segment
		mov	haHandle.segment, ax
		call	MemUnlockV		; release window

		; kill the window and gstate

		call	WinClose		; kill window and gstate

		; free the bitmap last, since WinClose wants to use it

		pop	ax			; restore flag
		cmp	al, BMD_LEAVE_DATA	; if we are to leave it alone
		je	done
		mov	bx, haHandle.segment	; load up VM file handle
		tst	bx			; if zero, nothing to do
		jz	done
		mov	di, haHandle.offset	; get VM block handle
		call	HugeArrayDestroy	; kill bitmap
done:
		.leave
		ret
GrDestroyBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetBitmapMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set mode bits for an editable bitmap

CALLED BY:	GLOBAL
PASS:		di	- GState handle, as returned by GrCreateBitmap
		ax	- BitmapMode record, including bits:
				BM_EDIT_MASK	- to have subsequent drawing
						  operations affect the mask 
						  instead of the picture data
				BM_CLUSTERED_DITHER - to use a clustered dither
						  for writing operations - only
						  works for BMF_MONO bitmaps
		dx	- ColorTransfer handle (0 if none supplied)
				

RETURN:		carry set if GState not pointing at a bitmap, else
		ax	- flags actually set.  This will be the same as 
			  what was passed, typically.  If the bitmap has
			  no mask, and the BM_EDIT_MASK bit was set, then
			  the bit will be cleared in the return value.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If the bitmap doesn't have a mask, then calling this function
		with the BM_EDIT_MASK bit set will have no effect.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetBitmapMode	proc	far
		uses	ds, bx, di
		.enter

EC <		test	ax,not (mask BM_EDIT_MASK or mask BM_CLUSTERED_DITHER)>
EC <		ERROR_NZ GRAPHICS_BAD_BITMAP_MODE			>
		push	ax			; save flag
		call	LockHugeBitmap		; ds -> HugeBitmap
		pop	ax			; restore flag
		jc	done			; bail if error
		test	ax, mask BM_EDIT_MASK	; if editing mask, make sure 
		jz	storeFlags		;  there is one.
		test	ds:[EB_bm].CB_simple.B_type, mask BMT_MASK
		jnz	storeFlags		; all ok
		and	ax, not (mask BM_EDIT_MASK) ; no mask, so clear bit.
storeFlags:
		mov	ds:[EB_flags], ax	; store flags
		mov	ds:[EB_color], dx	; store flags
		call	HugeArrayDirty
		call	HugeArrayUnlockDir	; clear the flags
		clc
done:
		.leave
		ret
GrSetBitmapMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetBitmapMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set mode bits for an editable bitmap

CALLED BY:	GLOBAL
PASS:		di	- GState handle, as returned by GrCreateBitmap
RETURN:		carry set if GState not pointing at a bitmap, else
		ax	- BitmapMode record, including bits:
				BM_EDIT_MASK	- to have subsequent drawing
						  operations affect the mask 
						  instead of the picture data
				BM_CLUSTERED_DITHER - to use a clustered dither
						  for writing operations - only
						  works for BMF_MONO bitmaps
			
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetBitmapMode	proc	far
		uses	ds, bx, di
		.enter

		call	LockHugeBitmap		; ds -> HugeBitmap
		jc	done
		mov	ax, ds:[EB_flags]	; store flags
		call	HugeArrayUnlockDir	; clear the flags
		clc
done:
		.leave
		ret
GrGetBitmapMode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrClearBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear out content of a bitmap

CALLED BY:	GLOBAL

PASS:		di	- gstate allocated by GrCreateState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The part of the bitmap actually cleared (set to white) depends
		on the bitmap mode.  For the normal mode, the data portion
		of the bitmap is cleared, and the masks are left alone.  If
		the bitmap is in BM_EDIT_MASK mode, then the mask is cleared
		and the data portion is left alone.

		NOTE: The value written into the data portion of the bitmap
		depends on the color format of the bitmap.  Since "white" is
		zero for monochrome bitmaps, the value 0x00 is written to all
		bytes.  For other color formats, white is 0xff, so that value
		is written.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrClearBitmap	proc	far
		uses	ax, cx, dx, es, bx, ds, di, si
clearValue	local	word
		.enter
		
		; first lock the block, then fire away

		call	LockHugeBitmap			; ds -> HugeBitmap
		jc	done
		mov	si, offset EB_bm
		mov	cx, ds:[si].B_height
		mov	dx, ds:[si].B_width		; dx = element size
		mov	ah, ds:[si].B_type		; get type
		mov	al, {byte} ds:[EB_flags]		; 
		mov	si, ds:[HAD_size]		; get size of element
EC <		tst	si				; if zero, bad news >
EC <		ERROR_Z GRAPHICS_CANT_DO_THIS_WITH_COMPACTED_BITMAP	 >
		call	HugeArrayUnlockDir		; release bitmap block

		test	ah, mask BMT_MASK		; is there a mask ?
		jnz	haveMask			; there's  a mask
		clr	dx				; offset into scan 
calcClearValue:
		mov	ss:clearValue, 0xffff		; assume white
		and	ah, mask BMT_FORMAT		; isolate color format
		cmp	ah, BMF_MONO
		je	clearZero
		cmp	ah, BMF_4CMYK
		jb	setScanOffset
clearZero:
		mov	ss:clearValue, 0x0000
setScanOffset:
		mov	ax, dx				; ax = offset into elem

		; for each element in the array, clear it.
clearArrayCommon:
		push	cx, si, ax			; save loop count
		clr	ax, dx
		call	HugeArrayLock			; ds:si -> element
		pop	cx, dx, ax			; dx = elem size
elemLoop:
		push	cx, dx, ax			; save loop count
		mov	cx, dx				; cx = byte count 
		segmov	es, ds, di
		mov	di, si				; es:di -> element
		add	di, ax
		mov	ax, ss:clearValue
		rep	stosb
		call	HugeArrayDirty			; mark block as dirty
		call	HugeArrayNext			; ds:si -> next element
		pop	cx, dx, ax
		loop	elemLoop

		; unlock the final block

		call	HugeArrayUnlock
		clc
done:
		.leave
		ret

		; if there's a mask, then we either have to clear it, or clear
		; what's after it.  Either way, we need to calculate how
		; big the mask is.
haveMask:
		add	dx, 7				; pad to nearest byte
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1
		test	al, mask BM_EDIT_MASK		; if editing the mask
		jz	clearData
		mov	si, dx				; set size to mask size
		mov	ss:clearValue, 0x0000
		clr	ax
		jmp	clearArrayCommon

		; we're not in EDIT_MASK mode, so clear the data part
clearData:
		sub	si, dx				; si = #bytes to clear
		jmp	calcClearValue
GrClearBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by a few HugeBitmap routines

CALLED BY:	INTERNAL
		GrSetBitmapMode, GrGetBitmapMode

PASS:		di	- GState handle allocated in GrCreateBitmap

RETURN:		carry clear if successful
			ds	- pointing to locked HugeArray bitmap
			bx:di	- VM file/block handle to bitmap
		carry set if error

DESTROYED:	ax (ds, bx, di also destroyed if carry set)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockHugeBitmap	proc	near
		mov	bx, di			; lock GState
		call	MemLock			; ax -> GState
		jc	done
		mov	ds, ax			; ds -> GState
		mov	ax, ds:[GS_window]	; get window handle
		call	MemUnlock
		tst	ax
		stc
		jz	done

		mov_tr	bx, ax			; lock window
		call	MemPLock		; ax -> Window
		jc	done
		mov	ds, ax			; ds -> Window
		mov	ax, ds:[W_bitmap].segment ; get VM file handle
		mov	di, ds:[W_bitmap].offset  ; get VM block handle
		call	MemUnlockV		; release window

		tst	ax
		stc
		jz	done
		mov_tr	bx, ax			; bx.di -> HugeBitmap
		call	HugeArrayLockDir	; lock directory
		mov	ds, ax			; ds -> HugeArray dir block
		clc
done:
		ret
LockHugeBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the color of a single pixel

CALLED BY:	GLOBAL
PASS:		di	- GState
		ax, bx	- coord of point (document coords)
RETURN:		ah	- raw pixel value (except 24-bit devices)
		al	- pixel color (red component)
		bl	- pixel color (green component)
		bh	- pixel color (blue component)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If the point is outside the window, BLACK is returned.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrGetPoint	proc	far
		call	EnterGraphics		; returns with  ds->gState
		jc	quickExit		;		es->window

		; make sure there is a window and it has a real clip region.

		tst	ds:[GS_window]		; if no window, bail
		jz	returnBlack
		test	es:[W_grFlags], mask WGF_MASK_NULL ; see if null mask
		jnz	returnBlack

		call	GrTransCoordFar		; do coord translation

		; if the coordinate is outside the window bounds, return BLACK

		cmp	ax, es:[W_winRect].R_left ; check left/right
		jl	returnBlack		; if out, say so
		cmp	ax, es:[W_winRect].R_right
		jg	returnBlack		
		cmp	bx, es:[W_winRect].R_top ; check top/bottom
		jl	returnBlack		; if out, say so
		cmp	bx, es:[W_winRect].R_bottom 
		jg	returnBlack

		mov	di, DR_VID_GETPIXEL	; get some bits
		call	es:[W_driverStrategy]	; get the value
		;
		; Store return values from GetPixel in EnterGraphics frame
		; for return to our caller
		;
done:
		mov	bp, sp
		mov	ss:[bp].EG_ax, ax
		mov	ss:[bp].EG_bx, bx
		jmp	ExitGraphics

		; graphical string open...don't do anything
quickExit:
		mov	ss:[bp].EG_ax, 0	; just set return value to zero
		mov	ss:[bp].EG_bx, 0
		jmp	ExitGraphicsGseg

		; outside the window, return black
returnBlack:
		clr	ax, bx
		jmp	done
		
GrGetPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a bitmap from the screen to system memory

CALLED BY:	GLOBAL

PASS:		di	- handle to gstate
		ax	- x coordinate of source rectangle  (document units)
		bx	- y coordinate of source rectangle  (document units)
		cx	- bitmap width 			    (document units)
		dx	- bitmap height			    (document units)

RETURN:		bx	- handle to memory block allocated for bitmap
			- 0 if error allocating memory
		cx	- width of bitmap copied	    (pixels)
		dx	- height of bitmap copied	    (pixels)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy as much of bitmap as can be copied in 64K;
		fix return values;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function does NOT do any checking of the source rectangle
		to determine if/how it is clipped by other windows.  This
		function will probably be useful for screen dumps, but may
		not be as useful for normal application use.  One exception
		will be when it is used in conjunction with a memory driver,
		where it is unlikely that there will be any overlapping windows.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetBitmap	proc	far
		call	EnterGraphics		; returns with  ds->gState
		jc	quickExit		;		es->window

		; make sure there is a window too

		tst	ds:[GS_window]		; if no window, bail
		jz	done
		call	GetBitmap		; let KLib do it
		;
		; Store return values from GetBitmap in EnterGraphics frame
		; for return to our caller
		;
		mov	bp, sp
		mov	ss:[bp].EG_cx, cx
		mov	ss:[bp].EG_dx, dx
		mov	ss:[bp].EG_bx, si
done:
		jmp	ExitGraphics

;------------------------------------------------------------------------

		; graphical segment open...don't do anything
quickExit:
		jmp	ExitGraphicsGseg
GrGetBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a bitmap from the screen to system memory

CALLED BY:	GLOBAL

PASS:		di	- handle to gstate
		ax	- x coordinate of source rectangle  (document units)
		bx	- y coordinate of source rectangle  (document units)
		cx	- bitmap width 			    (document units)
		dx	- bitmap height			    (document units)
		bp	- offset of EnterGraphics frame on stack

RETURN:		si	- handle to memory block allocated for bitmap
			- 0 if error allocating memory
		cx	- width of bitmap copied	    (pixels)
		dx	- height of bitmap copied	    (pixels)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy as much of bitmap as can be copied in 64K;
		fix return values;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function does NOT do any checking of the source rectangle
		to determine if/how it is clipped by other windows.  This 
		function will probably be useful for screen dumps, but may 
		not be as useful for normal application use.  One exception
		will be when it is used in conjunction with a memory driver,
		where it is unlikely that there will be any overlapping windows.

		This function does not work well when rotation is applied.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GGB_local	struct
    GGB_x	dw	?		; x position of bitmap
    GGB_y	dw	?		; y position of bitmap
    GGB_width	dw	?		; width of bitmap
    GGB_height	dw	?		; height of bitmap
GGB_local	ends
	GGB_loc	equ	[bp-size GGB_local]

		; constant for MemAlloc flag: makes code look nicer

GGB_MEM_FLAGS equ ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8) or mask HF_SHARABLE or mask HF_SWAPABLE

;----------------------------------------------------------------------

		; complex transformation 
GGB_complex:
		xchg	ax, cx			; translate the height and width
		xchg	bx, dx			;   too
		call	GrTransCoordFar			; do translation
		sub	ax, es:[W_winRect].R_left	; get win relative
		sub	bx, es:[W_winRect].R_top
		xchg	ax, cx			; get everything back where it
		xchg	bx, dx			;   was
		jmp	short GGB_saveSize

GetBitmap	proc	near

		; allocate some local scratch	;

		mov	bp, sp			; bp saved by EnterGraphics
		sub	sp, size GGB_local

		; translate coordinates and save for later

		call	GrTransCoordFar		; translate point
		test	es:[W_curTMatrix].TM_flags, TM_COMPLEX 
		jnz	GGB_complex			; if no scaling, all ok
GGB_saveSize	label	near
		mov	GGB_loc.GGB_x, ax	; store parms away first
		mov	GGB_loc.GGB_y, bx
		mov	GGB_loc.GGB_height, dx	; save dx since we trash it soon

		; calculate the size of the block we need

		call	GetBitSizeBlock		; dx:ax = size of block (int32)
		jc	GGB_exit		; if nothing visible, just exit

		; see if bytes needed are > 64K, if not -- allocate away

		tst	dx			; see if high word is non-zero
		jnz	GGB_huge		;  yes, handle huge bitmaps
		mov	si, ax			; save the size of the block
		mov	cx, GGB_MEM_FLAGS	; set MemAlloc flags
		call	MemAllocFar		; allocate memory for bitmap
		jc	GGB_memError		; error allocating...

		; everything copasetic, call the driver

		push	bx			; save handle
		push	ds			; save gstate segment
		push	bp
		mov	ds, ax			; set ds = segment of block
		mov	ax, GGB_loc.GGB_x	; set the position
		mov	bx, GGB_loc.GGB_y
		mov	cx, GGB_loc.GGB_width	; set size
		mov	dx, GGB_loc.GGB_height
		clr	bp			; ds:bp -> empty block
		mov	di, DR_VID_GETBITS	; get some bits
		call	es:[W_driverStrategy]	; fill the buffer
		pop	bp
		pop	ds			; restore gstate segment
		pop	bx			; restore memory handle
		call	MemUnlock		; unlock the block before ret


		; all done -- fixup return values, restore stack and leave
GGB_exit:
		mov	cx, GGB_loc.GGB_width	; get width
		mov	dx, GGB_loc.GGB_height	; get height
		mov	si, bx			; return handle too.
		mov	sp, bp			; restore stack pointer
		ret

;------------------------------------------------------------------------

		; error allocating memory, just quit
GGB_memError:
		clr	bx			; set error return value
		jmp	GGB_exit

		; huge bitmap, just return for now, need to handle somehow
GGB_huge:
		clr	bx			; set error return value
		jmp	GGB_exit
GetBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitSizeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for GetBitmap to size the block required

CALLED BY:	INTERNAL
		GetBitmap

PASS:		see GetBitmap, above

RETURN:		carry	- set if no part of bitmap is visible
			- clear for something to copy
		dx:ax	- size of block to allocate (32-bits)

DESTROYED:	ax,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		restrict passed size to window bounds;
		calculate #bytes needed;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitSizeBlock	proc	near

		; first calc and save the maximum width and height.  This
		; allows calculating the actual width and height of the transfer

		mov	dx, es:[W_winRect].R_right ; get right side of window
		sub	dx, ax			; sub left side coord
		inc	dx			; one more for width
		js	GBSB_exit		;  exit if nothing to copy
		cmp	dx, cx			; use lesser of max and desired
		jg	GGB_savMaxW		;  skip the exchange
		xchg	cx, dx
GGB_savMaxW:
		mov	GGB_loc.GGB_width, cx	; store width
		mov	dx, es:[W_winRect].R_bottom ; get bottom side of window
		sub	dx, bx			; sub top side coord
		inc	dx			; one more for width
		js	GBSB_exit		;  exit if nothing to copy
		cmp	dx, GGB_loc.GGB_height	; use lesser of max and desired
		jg	GGB_savedHeight		;  skip the exchange
		mov	GGB_loc.GGB_height, dx

		; need to calc how big a block to alloc.  first get info
		; about the device, then calc away
GGB_savedHeight:
		mov	di, DR_VID_INFO		; call driver to get ptr to 
		call	es:[W_driverStrategy]	;  info table  dx:si -> table
		push	ds			; save gstate ptr
		mov	ds, dx			; ds:si -> info block
		mov	cx, GGB_loc.GGB_width	; retreive width of transfer
		mov	al, ds:[si].VDI_bmFormat	; get format of buffer
		pop	ds			; don't need pointer anymore
		call	CalcLineSize		; calc #bytes/scan

		mov	dx, GGB_loc.GGB_height
		mul	dx			; dx:ax = #bytes needed
		add	ax, size Bitmap		; add in some for header
		adc	dx, 0
		clc				; no error
		ret

;---------------------------------------------------------------------

		; nothing visible, exit
GBSB_exit:
		stc
		ret

GetBitSizeBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCompactBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compact a HugeBitmap

CALLED BY:	GLOBAL
PASS:		bx:ax	- VM file:block handle containing bitmap
		dx	- VM file for destination bitmap 
			  (may be the same as bx)
RETURN:		dx:cx	- VM file:block handle of new compacted bitmap.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Create the destination HugeArray.
		For each scan line in the original bitmap
		    Compact it and append it to the destination.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The resulting bitmap is *not* editable.  That is, you cannot
		use GrEditBitmap to start drawing into the compacted bitmap.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SENTINEL	=	'D' or ('R' shl 8)

GrCompactBitmap	proc	far
		uses	es, ds, si, di, ax, bx
oldBMfile	local	word
oldBMblock	local	word
newBMfile	local	word
newBMblock	local	word
scratchBlock	local	hptr
scanSize	local	word
EC <sentinelOffset	local	word					>
EC <uncompactOffset	local	word					>
		.enter

		; save away some info

		mov	newBMfile, dx		; save new file handle
		mov	oldBMfile, bx
		mov	oldBMblock, ax

		; allocate a new HugeArray to store the new bitmap into.
		; make the directory headers size on the new one the same
		; size as the old one, so we don't lose any info

		mov	di, ax			; bx:di = old BM
		call	HugeArrayLockDir	; 
		mov	ds, ax			; ds -> EditableBitmap
EC <		cmp	ds:[EB_bm].CB_simple.B_compact, BMC_UNCOMPACTED	>
EC <		ERROR_NE GRAPHICS_BITMAP_ALREADY_COMPACTED		>
		mov	di, ds:[LMBH_offset]	; di = size of header

		clr	cx			; it's variable sized
		mov	bx, dx			; bx = new VM file handle
		call	HugeArrayCreate		; di = new VM block handle
		mov	newBMblock, di

		; lock down the headers and copy the usual info across.

		call	HugeArrayLockDir	; lock down new one
		mov	es, ax
		mov	di, EB_bm		; es:di -> CBitmap structure
		mov	si, di			; ds:si -> CBitmap Structure
		mov	cx, ds:[LMBH_offset]	; cx = size of header
		sub	cx, si			; cx = part we're interested in
		rep	movsb			;  for now

		; release the source block, and fixup the info in the new 
		; block.

		call	HugeArrayUnlockDir	; release the source directory
		mov	di, EB_bm		; es:di -> new bitmap struct
		mov	es:[di].CB_simple.B_compact, BMC_PACKBITS
		clr	es:[di].CB_devInfo	; make it not editable

		; Allocate a small buffer to do the compaction.  Release the
		; destination directory block. The maximum buffer size
		; required is (# of bytes per scan line) + 1 + (# of bytes
		; per scan line / 128 rounded up). See the header of
		; CompactPackBits() for why this is so.

		mov	cx, es:[di].CB_simple.B_width ; cx = #scans to do
		mov	al, es:[di].CB_simple.B_type
		call	CalcLineSize		; ax = uncompacted scan size
		mov	scanSize, ax		; save uncompacted scan size
		add	ax, 2			; add one + possible round
		mov	cx, ax
		shl	cx, 1			; ch = # of 128 byte pieces
		add	al, ch
		adc	ah, 0

EC <		mov	sentinelOffset, ax	; offset to sentinel	>
EC <		add	ax, 2			; add word for sentinel	>
EC <		mov	uncompactOffset, ax	; offset to uncompacted	>
EC <		add	ax, scanSize					>
EC <		add	ax, 2			; add word for sentinel	>

		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAllocFar		; bx = file handle
		mov	scratchBlock, bx	;
		mov	cx, es:[di].CB_simple.B_height ; cx = #scans to do
		segmov	ds, es			; release source dir block
		call	HugeArrayDirty
		call	HugeArrayUnlockDir
		mov	es, ax			; es -> newly alloc'd block

EC <		mov	di, sentinelOffset	; initialize sentinel	>
EC <		mov	{word} es:[di], SENTINEL			>
EC <		mov	di, uncompactOffset	; ...and 2nd sentinel	>
EC <		add	di, scanSize					>
EC <		mov	{word} es:[di], SENTINEL			>
		
		; loop for each scan line, compacting as we go. 
		; REGISTER USAGE:
		;  cx = #scans to do
		;  es -> scratch block
		;  ds:si -> source scan line
		;  bx:di -> destination HugeArray file/block handle

		push	cx			; save #scans to do
		mov	di, oldBMblock
		mov	bx, oldBMfile
		clr	ax, dx
		call	HugeArrayLock		; ds:si -> first scan line
		pop	cx
		jmp	startScan
scanLoop:
		call	HugeArrayNext		; ds:si -> next scan line
startScan:
		push	cx			; save #scanlines to go

		mov	cx, scanSize		; pass input scanline size
		clr	di			; es:di -> output buffer
		call	CompactPackBits		; compact a single scan line

EC <		mov	di, sentinelOffset	; verify the sentinel	>
EC <		cmp	{word} es:[di], SENTINEL			>
EC <		ERROR_NE GRAPHICS_SENTINEL_FOR_BITMAP_COMPRESSION_CORRUPTED >

		; now verify that the compacted data is valid

EC <		push	cx, si						>
EC <		push	ds, si						>
EC <		mov	di, uncompactOffset	; es:di -> destination	>
EC <		segmov	ds, es						>
EC <		clr	si			; ds:si -> source	>
EC <		mov	cx, scanSize					>
EC <		call	UncompactPackBitsFar				>
EC <		pop	ds, si			; ds:si -> original data>
EC <		mov	di, uncompactOffset	; es:di -> new data	>
EC <		mov	cx, scanSize					>
EC <		repe	cmpsb			; compare them bytes	>
EC <		ERROR_NZ GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	>
EC <		cmp	{word} es:[di], SENTINEL			>
EC <		ERROR_NZ GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	>
EC <		pop	cx, si						>

		; finished compaction.  Write out the buffer.

		mov	di, newBMblock
		mov	bx, newBMfile
		push	si, bp
		mov	bp, es
		clr	si
		call	HugeArrayAppend				
		pop	si, bp

		pop	cx
		loop	scanLoop

		; release the last block of the source array and scratch buff

		call	HugeArrayUnlock		; release the last block
		mov	bx, scratchBlock
		call	MemFree
		
		; return the correct information about the new BM

		mov	dx, newBMfile		; return file and
		mov	cx, newBMblock		;  block handle

		.leave
		ret
GrCompactBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompactPackBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run-length encode a single scan line of a bitmap

CALLED BY:	INTERNAL
		GrCompactBitmap
PASS:		ds:si	- pointer to bitmap scanline data
		cx	- #bytes in input scan line
		es:di	- pointer to output buffer
			  (should be sized about 1% larger than original scan,
			   for the degenerate case).
RETURN:		cx	- #bytes in compacted scan line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The format is as follows:

			<count><pattern>+

		where:	
			if <count> is less than 0x80
				the count byte is followed by "count+1" number
				of individual bytes.
			if <count> is 0x80 through 0xff
				the count byte is followed by a single pattern
				byte, which should be copied (-count)+1 times

		The latter case is only used for a sequence of bytes
		of length three or more, as otherwise we could get an
		alternating pattern of of the two types of data storage
		that would result in more space being occuppied then the
		uncompressed bitmap.

	REGISTER USAGE:
		AH	= Byte to match
		BX	= Start of unique or repeat byte sequence
		DL	= Unique byte sequence count
		DH	= Repeat byte sequence count
		CX	= # of bytes left in original scan line
		DS:SI	= Scan-line soure
		ES:DI	= Compacted scan-line destination

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/13/92	Initial version
	don	 1/12/94	Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompactPackBits	proc	near
		uses	ax, bx, dx, si
		.enter
		
		; Start the whole process
		;
		push	di			; save starting offset
newSeed:
		jcxz	done
		lodsb
		dec	cx
		jmp	uniqueStart

		; We've run out of bytes in the middle of a unique series
cleanUpUnique:
		dec	dl
EC <		cmp	dl, 127			; can't be more than 127     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		mov	es:[bx], dl		; end unique count

		; We're done - return the number of bytes in the scan-line
done:
		mov	cx, di			; last offset => CX
		pop	di			; starting offset => DI
		sub	cx, di			; cx = # destination bytes

		.leave
		ret

		; We've just found a byte that does not match the previous
uniqueStart:
		mov	bx, di
		inc	di			; leave room for count byte
		stosb				; store this first byte
		mov	ah, al
		mov	dx, 0x101		; initialize both counts
uniqueByte:
		jcxz	cleanUpUnique
		lodsb
		dec	cx
		stosb
		cmp	ah, al
		je	endUniqueness
		mov	ah, al
		mov	dh, 1			; initialize repeat count
uniqueContinue:
		inc	dl			; increment unique count
		cmp	dl, 128			; compare against maximum count
		jne	uniqueByte
EC <		cmp	dl, 128			; can't be more than 127     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		dec	dl			; reached maximum byte count
		mov	es:[bx], dl		; ...so store (count - 1)
		jmp	newSeed			; look for a new seed byte again
endUniqueness:
		inc	dh			; increment repeat count
		cmp	dh, 2			; if only two matches
		jle	uniqueContinue		; ...then keep on going
		cmp	dl, 2			; if unique count is only 2(+1),
		je	matchStart		; ...then no unique bytes
		sub	dl, 3			; subtract repeat length
EC <		cmp	dl, 127			; can't be more than 127     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		mov	es:[bx], dl		; store unique count
		inc	di

		; We've found three consecutive matching bytes.
matchStart:
		sub	di, 2			; we've written three matching
		mov	bx, di			; ...bytes, we'll use byte 0
		sub	bx, 2			; ...to hold the count and start
						; ...storing bytes at byte 2
matchByte:
		jcxz	cleanUpRepeat
		lodsb
		dec	cx
		cmp	ah, al
		jne	endMatching
		inc	dh			; increment repeat count
		cmp	dh, 128			; see if we've wrapped
		jbe	matchByte		; ...if not, continue
		dec	dh			; ...else end run of matches

		; We've end a run of matching bytes. Store the count
endMatching:
EC <		cmp	dh, 3			; must be at least 3 matches >
EC <		ERROR_B	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
EC <		cmp	dh, 128			; can't be more than 128     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		dec	dh
		neg	dh
		mov	es:[bx], dh
		jmp	uniqueStart

		; We've run out of bytes in the middle of a repeat series
cleanUpRepeat:
EC <		cmp	dh, 128			; can't be more than 128     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		dec	dh
		neg	dh
		mov	es:[bx], dh
		jmp	done
CompactPackBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUncompactBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompact a HugeBitmap

CALLED BY:	GLOBAL
PASS:		bx:ax	- VM file:block handle containing bitmap
		dx	- VM file for destination bitmap 
			  (may be the same as bx)
RETURN:		dx:cx	- VM file:block handle of new compacted bitmap.
DESTROYED:	nothing
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Take the easy route.  Create a bitmap and draw this one into
		it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrUncompactBitmap proc	far
		uses	es, ds, si, di, ax, bx
oldBMfile	local	word
oldBMblock	local	word
newBMfile	local	word
newBMblock	local	word
scratchBlock	local	hptr
scanSize	local	word
		.enter

		; save away some info

		mov	newBMfile, dx		; save new file handle
		mov	oldBMfile, bx
		mov	oldBMblock, ax

		; access the current bitmap

		mov	di, ax			; bx:di = old BM
		call	HugeArrayLockDir	; 
		mov	ds, ax			; ds -> EditableBitmap
EC <		cmp	ds:[EB_bm].CB_simple.B_compact, BMC_PACKBITS	>
EC <		ERROR_NE GRAPHICS_BITMAP_MUST_BE_PACKBITS		>

		; calculate the width of the bitmap in bytes

		mov	al, ds:[EB_bm].CB_simple.B_type
		mov	cx, ds:[EB_bm].CB_simple.B_width
		call	CalcLineSize		; ax = bytes / scanline
		mov	scanSize, ax

		; allocate the new bitmap (in a HugeArray, of course)

		mov	bx, dx			; bx = new VM file handle
		mov_tr	cx, ax			; cx = scan size (bytes / line)
		mov	di, ds:[LMBH_offset]	; size of header + extra space
		call	HugeArrayCreate		; di = new VM block handle
		mov	newBMblock, di

		; lock down the headers and copy the usual info across.

		call	HugeArrayLockDir	; lock down new one
		mov	es, ax
		mov	di, EB_bm		; es:di -> CBitmap structure
		mov	si, di			; ds:si -> CBitmap Structure
		mov	cx, ds:[LMBH_offset]	; cx = size of header
		sub	cx, si			; cx = part we're interested in
		rep	movsb			;  for now

		; release the source block, and fixup the info in the new 
		; block.

		call	HugeArrayUnlockDir	; release the source directory
		mov	di, EB_bm		; es:di -> new bitmap struct
		mov	es:[di].CB_simple.B_compact, BMC_UNCOMPACTED
		mov	es:[di].CB_devInfo, offset EB_device - offset EB_bm

		; initialize the device info

		mov	dx, scanSize
		call	AllocBitmapInitDeviceInfo

		; Allocate a small buffer to do the de-compaction.  Release the
		; destination directory block

		mov	ax, scanSize		; get uncompacted scan size
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAllocFar		; bx = file handle
		mov	scratchBlock, bx
		mov	cx, es:[EB_bm].CB_simple.B_height
		segmov	ds, es			; release source dir block
		call	HugeArrayDirty		; dirty the block
		call	HugeArrayUnlockDir
		mov	es, ax			; es -> scratch block
		
		; loop for each scan line, compacting as we go. 
		; REGISTER USAGE:
		;  cx = #scans to do
		;  es -> scratch block
		;  ds:si -> source scan line
		;  bx:di -> destination HugeArray file/block handle

		push	cx			; save height of bitmap
		mov	di, oldBMblock
		mov	bx, oldBMfile
		clr	ax, dx
		call	HugeArrayLock		; ds:si -> first scan line
		pop	cx			; cx = # of scanlines
		jmp	startScan
scanLoop:
		call	HugeArrayNext		; ds:si -> next scan line
startScan:
		push	cx			; save #scanlines to go

		mov	cx, scanSize		; pass input scanline size
		push	si			; want to save source ptr
		clr	di			; es:di -> output buffer
		call	UncompactPackBitsFar	; compact a single scan line
		pop	si

		; finished compaction.  Write out the buffer.

		mov	di, newBMblock
		mov	bx, newBMfile
		push	si, bp
		mov	bp, es
		clr	si
		mov	cx, 1			; just one scan line
		call	HugeArrayAppend				
		pop	si, bp

		pop	cx
		loop	scanLoop

		; release the last block of the source array and scratch buff

		call	HugeArrayUnlock		; release the last block
		mov	bx, scratchBlock
		call	MemFree
		
		; return the correct information about the new BM

		mov	dx, newBMfile		; return file and
		mov	cx, newBMblock		;  block handle

		.leave
		ret
GrUncompactBitmap endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocBitmapInitDeviceInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the VideoDriverInfo structure after having
		allocated a bitmap.

CALLED BY:	GrCreateBitmap, GrCompactBitmap

PASS:		ES:DI	= CBitmap
		DX	= Bytes / scanline

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocBitmapInitDeviceInfo	proc	near
		.enter
	
		mov	si, es:[di].CB_devInfo	; offset to device info
		add	di, si			; es:di -> device info
		LoadVarSeg      ds, ax          ; ds -> idata
		mov	ax, ds:[memVidStrategy].offset ; get strat rout addr
		mov	bx, ds:[memVidStrategy].segment ; get strat rout addr
		mov	es:[di].DIS_strategy.offset, ax ; save strategy rout
		mov	es:[di].DIS_strategy.segment, bx
		mov	es:[di].DIS_driverAttributes, mask DA_CHARACTER
		mov	es:[di].DIS_driverType, DRIVER_TYPE_VIDEO
		mov	es:[di].VDI_tech, DT_MEMORY
		mov	es:[di].VDI_verMaj, VIDMEM_VERSION_MAJOR
		mov	es:[di].VDI_verMin, VIDMEM_VERSION_MINOR
		mov	ax, es:[EB_bm].CB_simple.B_height ; get bitmap height
		mov	es:[di].VDI_pageH, ax	; store as device size
		mov	ax, es:[EB_bm].CB_simple.B_width
		mov	es:[di].VDI_pageW, ax
		mov	ax, 72			; assume default resolution
		mov	es:[di].VDI_vRes, ax
		mov	es:[di].VDI_hRes, ax
		mov	es:[di].VDI_bpScan, dx

		mov	al, es:[EB_bm].CB_simple.B_type
		and	ax, mask BMT_FORMAT	; get format bits
		mov	es:[di].VDI_bmFormat, al
		mov_tr	bx, ax			; get into addressing register
		mov	al, cs:[nColorTable][bx] ; get total #colors
		mov	es:[di].VDI_nColors, al
		shl	bx, 1			; access a word table
		mov	bx, cs:[bitsAndPlanes][bx]
		mov	{word} es:[di].VDI_nPlanes, bx
		mov	es:[di].VDI_wColTab, 24	; palette is 24-bit/pixel

		.leave
		ret
AllocBitmapInitDeviceInfo	endp

GraphicsAllocBitmap	ends
