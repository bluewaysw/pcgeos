COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS WWW Library
MODULE:		htgif
FILE:		htgifGstring.asm

AUTHOR:		Joon Song, Jan 13, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/13/97   	Initial revision


DESCRIPTION:
		
	

	$Id: htgifBitmap.asm,v 1.9.1.11 98/07/19 21:25:43 jeremyb Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include geode.def
include resource.def
include ec.def
include	assert.def
include object.def
include Objects/inputC.def
include timer.def
include sem.def
include hugearr.def
include Internal/heapInt.def

include stdapp.def
include file.def
include localize.def
include char.def

include htgifBitmap.def
;include htconv.def

GifCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    			GifToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GifToBitmap

C DECLARATION:	extern word _pascal GifToBitmap(word dataHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GifToBitmap	proc	far	dataHandle:hptr.HTConverterStruct

gifFileHeader	local	GIFFileHeader
gifImageHeader	local	GIFImageHeader
lzwDecodeVars	local	LZWDecodeVars
pixCol		local	word
pixRow		local	word
interlacePass	local	word
bitmapType	local	BMType
clipboardFile	local	word
clipboardBlock	local	word
numColors	local	word
colorTable	local	256 dup (RGBValue)
if USE_FULL_COLOR_PALETTE
substColorTable	local	256 dup (byte)
endif
buffBytesLeft	local	word
buffByteCount	local	word
recvBuff	local	512 dup (byte)
lzwdbStackHptr		local	hptr.byte
lzwdbStackSptr		local	sptr.byte
lzwdbSuffixHptr		local	hptr.byte
lzwdbSuffixSptr		local	sptr.byte
lzwdbPrefixHptr		local	hptr.word
lzwdbPrefixSptr		local	sptr.word
lzwdbScanlineHptr	local	hptr.byte
lzwdbScanlineSptr	local	sptr.byte

	ForceRef	gifFileHeader
	ForceRef	lzwDecodeVars
	ForceRef	pixCol
	ForceRef	pixRow
	ForceRef	interlacePass
	ForceRef	numColors
	ForceRef	colorTable
if USE_FULL_COLOR_PALETTE
	ForceRef	substColorTable
endif
	ForceRef	recvBuff
	ForceRef	lzwdbStackSptr
	ForceRef	lzwdbSuffixSptr
	ForceRef	lzwdbPrefixSptr
	ForceRef	lzwdbScanlineSptr

	uses	si,di,ds,es
	.enter

	; Receive GIF file

	clr	ss:[buffBytesLeft]
	clr	ss:[buffByteCount]

	call	LoadGifFileHeader
	LONG jc	done

	call	LoadGifImageHeader
	LONG jc	done

	; calculate the space we need for this image
	mov	ax, ss:[gifImageHeader].GIFIH_height
	mul	ss:[gifImageHeader].GIFIH_width
	mov	bx, ax
	mov 	cx, dx	

	; check if we have enough swap space
	mov 	ax, SGIT_SWAP_FREE_SIZE
	call    SysGetInfo
	sub	ax, 30000
	sbb	dx, 0
	cmpdw	dxax, cxbx
	LONG  jb done

	; set bitmap type

	call	SetBitmapType

createBitmap::
	; create bitmap and decode gif image data

	mov	bx, ss:[dataHandle]
	call	MemLock				;ax = segment address
	mov	ds, ax

	; use our own vm file if we have
	;call	ClipboardGetClipboardFile	; bx <- VM file handle
	mov 	ax, ds:[vmFileHandle]
	mov	bx, ss:[dataHandle]
	call	MemUnlock

	mov	bx, ax
	mov	ss:[clipboardFile], ax
	mov	al, ss:[bitmapType]
	mov	cx, ss:[gifImageHeader].GIFIH_width
	mov	dx, ss:[gifImageHeader].GIFIH_height
	clr	di, si				; no MSG_META_EXPOSED OD
	call	GrCreateBitmap			; ax <- VM block handle
						; di <- gstate
	mov	ss:[clipboardBlock], ax

	; connect the bitmap with the targetObject 
	mov	bx, ss:[dataHandle]
	call	MemLock				;ax = segment address
	mov	ds, ax

	pushdw	ds:[htobject]
	push 	ss:[clipboardFile]
	push	ss:[clipboardBlock]
	push	ds:[request]
	call 	SETTARGETBITMAP

	; set the bounds 
	pushdw	ds:[htobject]
	push	ss:[gifImageHeader].GIFIH_width
	push	ss:[gifImageHeader].GIFIH_height
	call	SETTARGETSIZE

	; tell the uigenerator to resize all components
	pushdw	ds:[htobject]
	call 	CALLRESIZE

	mov	bx, ss:[dataHandle]
	call	MemUnlock

EC <	segmov	ds, NULL_SEGMENT, ax					>

if USE_FULL_COLOR_PALETTE
	call	SetBitmapPalette
endif

	mov	ax, LZW_DECODE_BUFFER_STACK_LENGTH * size byte
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	jc	freeBitmap			; => out of memory
	mov	ss:[lzwdbStackHptr], bx

	mov	ax, LZW_DECODE_BUFFER_SUFFIX_LENGTH * size byte
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	jc	freeStack			; => out of memory
	mov	ss:[lzwdbSuffixHptr], bx

	mov	ax, LZW_DECODE_BUFFER_PREFIX_LENGTH * size word
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	jc	freeSuffix			; => out of memory
	mov	ss:[lzwdbPrefixHptr], bx

	mov	ax, ss:[gifImageHeader].GIFIH_width
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	jc	freePrefix			; => out of memory
	mov	ss:[lzwdbScanlineHptr], bx

	call	GIFDecodeGIFData
	call	MemFree

freePrefix:
	mov	bx, ss:[lzwdbPrefixHptr]
	call	MemFree

freeSuffix:
	mov	bx, ss:[lzwdbSuffixHptr]
	call	MemFree

freeStack:
	mov	bx, ss:[lzwdbStackHptr]
	call	MemFree

freeBitmap:
	; free the bitmap
	mov	al, BMD_LEAVE_DATA
	call 	GrDestroyBitmap

done:
	; done
	mov	bx, ss:[dataHandle]
	call	MemLock				;ax = segment address
	mov	ds, ax

	; tell the other side, we are done.
	mov	bx, ds:[done_sem]
	call	ThreadPSem
	
	mov	ax, -1
	mov	ds:[done_flag], ax

	call	ThreadVSem

	mov	bx, ds:[buffer_empty]
	call	ThreadVSem
	mov	ax, ds:[converter_exit]
	mov	bx, ss:[dataHandle]
	call	MemUnlock

	mov	bx, ax
	call 	ThreadVSem

	.leave
	ret
GifToBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadGifFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load GIF file header

CALLED BY:	GifToBitmap
PASS:		inherit GifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadGifFileHeader	proc	near
	uses	ax,cx,di,es
	.enter	inherit GifToBitmap

	; load GIF file header

	segmov	es, ss
	lea	di, ss:[gifFileHeader]
	mov	ax, size gifFileHeader
	call	ReadGifFileData	; es:di = GIFFileHeader
	jc	error

	cmp	{word} ss:[gifFileHeader].GIFFH_signature[0], 'GI'
	jne	error
	cmp	{word} ss:[gifFileHeader].GIFFH_signature[2], 'F8'
	jne	error
	cmp	{word} ss:[gifFileHeader].GIFFH_signature[4], '7a'
	je	gotGIF
	cmp	{word} ss:[gifFileHeader].GIFFH_signature[4], '9a'
	jne	error
gotGIF:
	mov	cl, ss:[gifFileHeader].GIFFH_globalFlags
	andnf	cl, mask GIFGF_COLORTABLESIZE
	inc	cl
	mov	ax, 1
	shl	ax, cl				; ax <- number of color entries
	mov	ss:[numColors], ax

	; load global color table

	clr	ax				; assume no color table
	test	ss:[gifFileHeader].GIFFH_globalFlags, mask GIFGF_COLORTABLE
	jz	setColorTable
	mov	ax, ss:[numColors]
setColorTable:
	call	LoadGifColorTable
done:
	.leave
	ret

error:
EC <	WARNING	WARNING_NOT_A_GIF_FILE					>
	stc
	jmp	done

LoadGifFileHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadGifImageHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load GIF image header

CALLED BY:	GifToBitmap
PASS:		inherit GifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadGifImageHeader	proc	near
	uses	ax,cx,di,es
	.enter	inherit GifToBitmap

readLabel:
	segmov	es, ss
	lea	di, ss:[gifImageHeader]
	mov	ax, 1
	call	ReadGifFileData
	jc	done

	mov	al, es:[di]
	cmp	al, GIF_IMAGE_MARKER
	je	loadImageHeader
	cmp	al, GIF_EXTENSION_MARKER
	stc					; assume error
	jne	done

skipExtension::
	lea	di, ss:[lzwDecodeVars].LZWDV_byte_buff
	mov	ax, 1
	call	ReadGifFileData		; skip extension introducer

extensionBlockLoop:
	mov	ax, 1
	call	ReadGifFileData		; read block size
	jc	done
	
	mov	al, es:[di]
	tst	al				; if blocksize = 0, end of ext
	jz	readLabel

	call	ReadGifFileData
	jnc	extensionBlockLoop
	jmp	done

loadImageHeader:
	lea	di, ss:[gifImageHeader][1]
	mov	ax, size gifImageHeader - 1
	call	ReadGifFileData
	jc	done

	mov	cl, ss:[gifImageHeader].GIFIH_localFlags
	test	cl, mask GIFLF_COLORTABLE
	jz	done

	andnf	cl, mask GIFLF_COLORTABLESIZE
	inc	cl
	mov	ax, 1
	shl	ax, cl				; ax <- number of color entries
	mov	ss:[numColors], ax
	call	LoadGifColorTable
done:
	.leave
	ret
LoadGifImageHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadGifColorTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load color table

CALLED BY:	GifToBitmap
PASS:		ax = length of color table
		inherit GifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadGifColorTable	proc	near
	uses	ax,cx,di,es
	.enter	inherit GifToBitmap

EC <	cmp	ax, length colorTable					>
EC <	ERROR_A	-1			; cx >= length(colorTable)	>

	; load color table

	segmov	es, ss
	lea	di, ss:[colorTable]
	mov	cx, ax
	add	ax, ax
	add	ax, cx
	mov	cx, ax
	call	ReadGifFileData	; es:di = color table, ax = errorCode
	jc	done

	; clear out unused entries

	add	di, cx
	sub	cx, size colorTable
	neg	cx
	clr	ax
	shr	cx, 1
	jnc	swords
	stosb
swords:	rep	stosw			; clear carry, ax = 0

done:
	.leave
	ret
LoadGifColorTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bitmap type

CALLED BY:	GifToBitmap
PASS:		inherit GifToBitmap stack frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBitmapType	proc	near
	uses	ax, bx
	.enter	inherit GifToBitmap

	call	UserGetDisplayType
	andnf	ah, mask DT_DISP_CLASS

	clr	bx
	mov	bl, ah
	mov	al, cs:[bitmapTypeTable][bx]
	mov	ss:[bitmapType], al

	.leave
	ret
SetBitmapType	endp

if USE_FULL_COLOR_PALETTE
bitmapTypeTable	BMFormat \
	BMF_MONO shl offset BMT_FORMAT,	; DC_TEXT
	BMF_MONO shl offset BMT_FORMAT,	; DC_GRAY_1
	BMF_4BIT shl offset BMT_FORMAT,	; DC_GRAY_2
	BMF_4BIT shl offset BMT_FORMAT,	; DC_GRAY_4
	BMF_8BIT shl offset BMT_FORMAT,	; DC_GRAY_8
	BMF_4BIT shl offset BMT_FORMAT,	; DC_COLOR_2
	BMF_4BIT shl offset BMT_FORMAT,	; DC_COLOR_4
	BMF_8BIT shl offset BMT_FORMAT,	; DC_COLOR_8
	(BMF_8BIT shl offset BMT_FORMAT) or mask BMT_PALETTE	; DC_CF_RGB
else
bitmapTypeTable	BMFormat \
	BMF_MONO shl offset BMT_FORMAT,	; DC_TEXT
	BMF_MONO shl offset BMT_FORMAT,	; DC_GRAY_1
	BMF_4BIT shl offset BMT_FORMAT,	; DC_GRAY_2
	BMF_4BIT shl offset BMT_FORMAT,	; DC_GRAY_4
	BMF_4BIT shl offset BMT_FORMAT,	; DC_GRAY_8
	BMF_4BIT shl offset BMT_FORMAT,	; DC_COLOR_2
	BMF_4BIT shl offset BMT_FORMAT,	; DC_COLOR_4
	BMF_4BIT shl offset BMT_FORMAT,	; DC_COLOR_8
	BMF_4BIT shl offset BMT_FORMAT	; DC_CF_RGB
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set palette

CALLED BY:	GifToBitmap
PASS:		di = gstate
		inherit GifToBitmap stack frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if USE_FULL_COLOR_PALETTE

SetBitmapPalette	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter	inherit GifToBitmap

	; if we've created a bitmap with a palette, change the bitmap palette

	test	ss:[bitmapType], mask BMT_PALETTE
	jz	mapColors

	call	GrCreatePalette

	clr	ax
	mov	cx, ss:[numColors]
	mov	dx, ss
	lea	si, ss:[colorTable]
	call	GrSetPalette

	push	di
	mov	ax, GIT_WINDOW
	call	GrGetInfo
	mov	di, ax
	call	WinRealizePalette
	pop	di

mapColors:
	; Map each of the colors in our bitmap to one of the available colors.

	clr	si, cx
10$:	mov	al, ss:colorTable[si].RGB_red
	mov	bx, {word} ss:colorTable[si].RGB_green
	call	GrMapColorRGB
	xchg	si, cx
	mov	ss:substColorTable[si], ah
	xchg	si, cx
	add	si, size RGBValue
	inc	cx
	cmp	cx, ss:[numColors]
	jb	10$
done:
	.leave
	ret
SetBitmapPalette	endp

endif ; USE_FULL_COLOR_PALETTE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFDecodeGIFData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decode GIF data

CALLED BY:	GifToBitmap
PASS:		inherit GifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	The LZW decode buffers block may be left locked upon return.
		(We don't bother unlocking them since they will be freed
		right away.)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFDecodeGIFData	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter	inherit GifToBitmap

	call	GIFInitializeLZWDecodeVars

getCode:
	call	GetNextLZWCode
	jc	done

	cmp	ax, ss:[lzwDecodeVars].LZWDV_ending
	je	done	

	cmp	ax, ss:[lzwDecodeVars].LZWDV_clear
	jne	notClear

	; clear code - reinitialize all necessary items
	;	ax = c, bx = initial_size, cx = curr_size, dx = newcodes

	mov	bx, ss:[lzwDecodeVars].LZWDV_initial_size
	inc	bx
	mov	ss:[lzwDecodeVars].LZWDV_curr_size, bx

	mov	dx, ss:[lzwDecodeVars].LZWDV_newcodes
	mov	ss:[lzwDecodeVars].LZWDV_slot, dx

	mov	cx, bx
	mov	bx, 1
	shl	bx, cl
	mov	ss:[lzwDecodeVars].LZWDV_top_slot, bx

nCode:	call	GetNextLZWCode
	jc	done
	cmp	ax, ss:[lzwDecodeVars].LZWDV_clear
	je	nCode
	cmp	ax, ss:[lzwDecodeVars].LZWDV_ending
	je	done

	mov	ss:[lzwDecodeVars].LZWDV_fc, ax
	mov	ss:[lzwDecodeVars].LZWDV_oc, ax
EC <	cmp	ax, 0xff						>
EC <	WARNING_A -1							>

savePixel::
	mov	di, ss:[pixCol]
if USE_FULL_COLOR_PALETTE
	mov	si, ax
	mov	al, ss:substColorTable[si]
endif
	call	LockDecodeBuffers
	mov	es, ss:[lzwdbScanlineSptr]
	stosb
	mov	ss:[pixCol], di
	cmp	di, ss:[gifImageHeader].GIFIH_width
	jb	unlockGetCode

outputLine::
	call	GIFWriteScanline
	jc	done

unlockGetCode:
	call	UnlockDecodeBuffers
	jmp	getCode

done:
	.leave
	ret


notClear:
	call	LockDecodeBuffers

	; not clear code
	;	ax = c, bx = code, ds = stack, di = sp

	mov	bx, ax
	mov	ss:[lzwDecodeVars].LZWDV_code, bx	; code = c

	mov	ds, ss:[lzwdbStackSptr]
	mov	di, ss:[lzwDecodeVars].LZWDV_stack_ptr
	cmp	bx, ss:[lzwDecodeVars].LZWDV_slot	; code >= slot
	jb	10$
	LONG ja	error

	mov	bx, ss:[lzwDecodeVars].LZWDV_oc
	mov	ss:[lzwDecodeVars].LZWDV_code, bx	; code = oc
	mov	cx, ss:[lzwDecodeVars].LZWDV_fc
	mov	ds:[di], cl				; *sp = fc
	inc	di					; sp++
10$:
	; Here we scan back along the linked list of prefixes, pushing
	; helpless characters (ie. suffixes) onto the stack as we do so.

	mov	cx, ss:[lzwDecodeVars].LZWDV_newcodes
	jmp	scanTest
scanLoop:
	mov	es, ss:[lzwdbSuffixSptr]
	mov	dl, es:[bx]
	mov	ds:[di], dl				; *sp <- suffix[code]
	inc	di					; sp++
	shl	bx, 1					; bx <- word offset
	mov	es, ss:[lzwdbPrefixSptr]
	mov	bx, es:[bx]				; code <- prefix[code]
scanTest:
	cmp	bx, cx					; (code >= newcodes)
	jae	scanLoop

	mov	ds:[di], bl				; *sp <- code
	inc	di					; sp++
	mov	ss:[lzwDecodeVars].LZWDV_stack_ptr, di
	mov	ss:[lzwDecodeVars].LZWDV_code, bx

	mov	di, ss:[lzwDecodeVars].LZWDV_slot
	cmp	di, ss:[lzwDecodeVars].LZWDV_top_slot
	jae	20$
							; slot < top_slot
	mov	ss:[lzwDecodeVars].LZWDV_fc, bx		; fc = code
	mov	es, ss:[lzwdbSuffixSptr]
	mov	es:[di], bl				; suffix[slot] = code
	mov	cx, ss:[lzwDecodeVars].LZWDV_oc
	shl	di, 1					; di <- word offset
	mov	es, ss:[lzwdbPrefixSptr]
	mov	es:[di], cx				; prefix[slot] = oc
	shr	di, 1					; di <- byte offset
	inc	di					; slot++
	mov	ss:[lzwDecodeVars].LZWDV_slot, di
	mov	ss:[lzwDecodeVars].LZWDV_oc, ax	; oc = c
20$:							; slot >= top_slot
	cmp	di, ss:[lzwDecodeVars].LZWDV_top_slot
	jb	30$

	cmp	ss:[lzwDecodeVars].LZWDV_curr_size, 12
	jae	30$

	shl	ss:[lzwDecodeVars].LZWDV_top_slot, 1
	inc	ss:[lzwDecodeVars].LZWDV_curr_size
30$:
	mov	ax, ss:[gifImageHeader].GIFIH_width
	mov	bx, ss:[pixCol]
	clr	cx
	mov	di, ss:[lzwDecodeVars].LZWDV_stack_ptr
	mov	es, ss:[lzwdbScanlineSptr]
pixelLoop:
	tst	di				; see if stack bottom reached
	je	doneCode

	dec	di
	mov	cl, ds:[di]
if USE_FULL_COLOR_PALETTE
	mov	si, cx
	mov	cl, ss:substColorTable[si]
endif
	mov	es:[bx], cl
	inc	bx
	cmp	bx, ax
	jb	pixelLoop

	call	GIFWriteScanline
	LONG jc	done

	clr	bx
	jmp	pixelLoop

doneCode:
	mov	ss:[lzwDecodeVars].LZWDV_stack_ptr, di
	mov	ss:[pixCol], bx
	call	UnlockDecodeBuffers
	jmp	getCode

error:
EC <	WARNING	WARNING_ERROR_IN_GIF_DATA				>
	stc
	jmp	done

GIFDecodeGIFData	endp



LockDecodeBuffers	proc	near
	uses	ax
	.enter	inherit GifToBitmap

	mov	bx, ss:[lzwdbStackHptr]
	call	MemLock
	mov	ss:[lzwdbStackSptr], ax
	mov	bx, ss:[lzwdbSuffixHptr]
	call	MemLock
	mov	ss:[lzwdbSuffixSptr], ax
	mov	bx, ss:[lzwdbPrefixHptr]
	call	MemLock
	mov	ss:[lzwdbPrefixSptr], ax
	mov	bx, ss:[lzwdbScanlineHptr]
	call	MemLock
	mov	ss:[lzwdbScanlineSptr], ax
EC <	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT				>
EC <	call	MemGetInfo			; ah = lock count	>
EC <	Assert	e, ah, 1						>

	.leave
	ret
LockDecodeBuffers	endp



UnlockDecodeBuffers	proc	near
	.enter	inherit GifToBitmap

	mov	bx, ss:[lzwdbScanlineHptr]
	call	MemUnlock
EC <	mov	ss:[lzwdbScanlineSptr], NULL_SEGMENT
	mov	bx, ss:[lzwdbPrefixHptr]
	call	MemUnlock
EC <	mov	ss:[lzwdbPrefixSptr], NULL_SEGMENT
	mov	bx, ss:[lzwdbSuffixHptr]
	call	MemUnlock
EC <	mov	ss:[lzwdbSuffixSptr], NULL_SEGMENT
	mov	bx, ss:[lzwdbStackHptr]
	call	MemUnlock
EC <	mov	ss:[lzwdbStackSptr], NULL_SEGMENT
EC <	pushf								>
EC <	push	ax							>
EC <	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT				>
EC <	call	MemGetInfo			; ah = lock count	>
EC <	Assert	e, ah, 0						>
EC <	pop	ax							>
EC <	popf								>

	.leave
	ret
UnlockDecodeBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFInitializeLZWDecodeVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize LZW decode variables

CALLED BY:	GIFDecodeGIFData
PASS:		inherit GIFDecodeGIFData stack frame
RETURN:		if carry clear
			lzwDecodeVars initialized
		else
			ax = GifError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFInitializeLZWDecodeVars	proc	near
	uses	cx,di,es
	.enter	inherit GIFDecodeGIFData

	segmov	es, ss
	lea	di, ss:[lzwDecodeVars].LZWDV_byte_buff
	mov	ax, 1			; read LZW code size
	call	ReadGifFileData		; ax = errorCode
	jc	done

	clr	cx
	mov	cl, es:[di]
	cmp	cl, MIN_INITIAL_LZW_CODE_SIZE
	jb	error
	cmp	cl, MAX_INITIAL_LZW_CODE_SIZE
	ja	error		

	mov	ss:[lzwDecodeVars].LZWDV_initial_size, cx

	; clear = 1 << size;

	mov	ax, 1
	shl	ax, cl
	mov	ss:[lzwDecodeVars].LZWDV_clear, ax

	; ending = clear + 1;

	inc	ax
	mov	ss:[lzwDecodeVars].LZWDV_ending, ax

	; slot = newcodes = ending + 1;

	inc	ax
	mov	ss:[lzwDecodeVars].LZWDV_slot, ax
	mov	ss:[lzwDecodeVars].LZWDV_newcodes, ax

	; curr_size = size + 1;

	inc	cx
	mov	ss:[lzwDecodeVars].LZWDV_curr_size, cx

	; top_slot = 1 << curr_size;

	mov	ax, 1
	shl	ax, cl
	mov	ss:[lzwDecodeVars].LZWDV_top_slot, ax

	; nbits_left = block_size = 0;

	clr	ax
	mov	ss:[lzwDecodeVars].LZWDV_nbits_left, ax
	mov	ss:[lzwDecodeVars].LZWDV_block_size, ax

	; set stack ptr

	czr	ax, ss:[lzwDecodeVars].LZWDV_stack_ptr

	; pixCol = pixRow = interlacePass = 0

	mov	ss:[pixCol], ax
	mov	ss:[pixRow], ax
	mov	ss:[interlacePass], ax
done:	
	.leave
	ret

error:
EC <	WARNING	WARNING_ERROR_IN_GIF_DATA				>
	stc				; error
	jmp	done

GIFInitializeLZWDecodeVars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextLZWCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get next code

CALLED BY:	GIFDecodeGIFData
PASS:		inherit GIFDecodeGIFData stack frame
RETURN:		if carry clear
			ax = LZW code
		else
			ax = GifError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

codeMask word	0x0000, 0x0001, 0x0003, 0x0007, 0x000F, 0x001F, 0x003F, \
			0x007F, 0x00FF, 0x01FF, 0x03FF, 0x07FF, 0x0FFF

GetNextLZWCode	proc	near
	uses	cx,di,es
	.enter	inherit GIFDecodeGIFData

	mov	ax, ss:[lzwDecodeVars].LZWDV_nbits_left
	cmp	ax, ss:[lzwDecodeVars].LZWDV_curr_size

	; If the LZW code block does not terminate with the sub-block,
	; you will encouter a negative value for curr_size, which
	; was misintepreted by the previous 'jae'.  This results in
	; a bad read.
	jg	getCode

	; we need to move any leftover bits to the front of the buffer

	segmov	es, ss
	mov	di, ss:[lzwDecodeVars].LZWDV_block_size
	shr	di, 1
	shr	di, 1
	shr	di, 1
	mov	ax, {word} ss:[lzwDecodeVars].LZWDV_byte_buff[di-2]
	lea	di, ss:[lzwDecodeVars].LZWDV_byte_buff[0]
	stosw
	mov	ss:[lzwDecodeVars].LZWDV_block_size, 16

	; now read more data

	mov	ax, 1
	call	ReadGifFileData
	jc	done

	clr	ax
	mov	al, es:[di]
	call	ReadGifFileData
	jc	done

	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	add	ss:[lzwDecodeVars].LZWDV_nbits_left, ax
	add	ss:[lzwDecodeVars].LZWDV_block_size, ax
	mov	ax, ss:[lzwDecodeVars].LZWDV_nbits_left
	cmp	ax, ss:[lzwDecodeVars].LZWDV_curr_size
	jc	done

getCode:
	mov	di, ss:[lzwDecodeVars].LZWDV_block_size
	sub	di, ax				; di <- LZW code bit position
	mov	cx, di				; cx <- LZW code bit position
	shr	di, 1
	shr	di, 1
	shr	di, 1				; di <- LZW code byte position
	and	cx, 0x07			; cx <- LZW code bit offset
	mov	ax, {word} ss:[lzwDecodeVars].LZWDV_byte_buff[di]
	mov	di, {word} ss:[lzwDecodeVars].LZWDV_byte_buff[di+2]
	jcxz	maskCode

codeLoop:
	shrdw	diax
	loop	codeLoop

maskCode:
	mov	di, ss:[lzwDecodeVars].LZWDV_curr_size
	sub	ss:[lzwDecodeVars].LZWDV_nbits_left, di
EC <	ERROR_C -1							>
	shl	di, 1				; di <- word offset
	mov	di, cs:codeMask[di]
	and	ax, di				; carry clear
done:
	.leave
	ret
GetNextLZWCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFWriteScanline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy scanline to bitmap

CALLED BY:	GIFDecodeGIFData
PASS:		es = segment of scanline buffer
		inherit GIFDecodeGIFData stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFWriteScanline	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter	inherit GIFDecodeGIFData

	clr	dx
	mov	ax, ss:[pixRow]
	cmp	ax, ss:[gifImageHeader].GIFIH_height
	jb	writeScanline

EC <	WARNING	WARNING_ERROR_IN_GIF_DATA				>
	stc				; indicate error
	jmp	exit

writeScanline:
	mov	bx, ss:[clipboardFile]
	mov	di, ss:[clipboardBlock]
	call	HugeArrayLock
	tst	ax
	jz	nextScan

	segxchg	es, ds
	mov	di, si
	clr	si
	mov	cx, dx
	jcxz	unlock

	mov	al, ss:[bitmapType]
	and	al, mask BMT_FORMAT
	cmp	al, BMF_MONO shl offset BMT_FORMAT
	je	writeMono

if USE_FULL_COLOR_PALETTE
	cmp	al, BMF_4BIT shl offset BMT_FORMAT
	je	write4bit

	cmp	al, BMF_8BIT shl offset BMT_FORMAT
	jne	nextScan

write8bit::
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb		
	jmp	unlock

write4bit:
	mov	cl, 4
write4bitLoop:
	lodsb
	mov	ah, al
	shl	ah, cl
	lodsb
	and	al, 0x0f	
	ornf	al, ah
	stosb
	dec	dx
	jnz	write4bitLoop
	jmp	unlock
else
write4bit:
	;
	; Map RGB to black/dkgray/ltgray/white
	;
	lodsw
	call	GIFMapRGBto4Grays
ifdef	BROTHER_KERNEL
	push 	cx
	mov	cl, 4
	shl	al, cl
	pop	cx
else
	shl	al, 4
endif
	mov	dl, al
	mov	al, ah
	call	GIFMapRGBto4Grays
	or	al, dl
	stosb
	loop	write4bit
	jmp	unlock
endif

writeMono:
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	lodsb
	not	al
	ror	al, 1
	shl	ax, 1
	mov	al, ah
	stosb
	loop	writeMono

unlock:
	segmov	ds, es
	call	HugeArrayDirty
	call	HugeArrayUnlock

nextScan:
	clr	ss:[pixCol]

	test	ss:[gifImageHeader].GIFIH_localFlags, mask GIFLF_INTERLACE
	jnz	interlaced

	inc	ss:[pixRow]
	jmp	done

interlaced:
	mov	bx, ss:[interlacePass]
	shl	bx, 1			; convert to word index
	mov	ax, cs:rowIncr[bx]	; ax <- increment for next scanline
	add	ss:[pixRow], ax
	mov	ax, ss:[gifImageHeader].GIFIH_height
	cmp	ss:[pixRow], ax
	jb	done

	inc	ss:[interlacePass]
	cmp	ss:[interlacePass], 4
	jae	done			; no more than 4 passes

	mov	bx, ss:[interlacePass]
	shl	bx, 1			; convert to word index
	mov	ax, cs:baseRow[bx]	; ax <- 1st row of next interlace pass
	mov	ss:[pixRow], ax
done:
	clc				; no errors
exit:
	.leave
	ret
GIFWriteScanline	endp

	; Interlace Tables
baseRow	word	0, 4, 2, 1
rowIncr	word	8, 8, 4, 2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFMapRGBto4Grays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map RGB color to 4 grays

CALLED BY:	GIFWriteScanline
PASS:		al = color index
		inherit GIFDecodeGIFData stack frame
RETURN:		al = Color
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	joon    	7/ 8/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if (not USE_FULL_COLOR_PALETTE)

GIFMapRGBto4Grays	proc	near
	uses	cx, di
	.enter	inherit GIFDecodeGIFData

	mov	ch, ah
	clr	ah
	mov	di, ax				; di = index
	add	di, ax				; di = 2*index
	add	di, ax				; di = 3*index
	mov	al, ss:[colorTable][di].RGB_red
	add	al, ss:[colorTable][di].RGB_green
	adc	ah, 0
	add	al, ss:[colorTable][di].RGB_blue
	adc	ah, 0

	mov	cl, C_BLACK
	cmp	ax, 128
	jl	gotColor

	mov	cl, C_DARK_GRAY
	cmp	ax, 384
	jl	gotColor

	mov	cl, C_LIGHT_GRAY
	cmp	ax, 640
	jl	gotColor

	mov	cl, C_WHITE

gotColor:
	mov	ax, cx

	.leave
	ret
GIFMapRGBto4Grays	endp

endif ; not USE_FULL_COLOR_PALETTE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadGifFileData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read GIF file data

CALLED BY:	INTERNAL
PASS:		es:di	= buffer to read into
		ds	= dgroup
		ax	= number of bytes to read
		inherit GifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadGifFileData	proc	near
	uses	ax,bx,cx,si,di,ds
	.enter	inherit GifToBitmap

	cmp	ss:[buffBytesLeft], ax
	jae	copyBytes

recv:
	segmov	ds, ss
	lea	si, ss:[recvBuff]
	add	si, ss:[buffByteCount]
	mov	cx, ss:[buffBytesLeft]
	sub	si, cx
	sub	ax, cx
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb

	call	GifSocketRecv
EC <	WARNING_C -1							>
	jc	done				; exit with carry set

	cmp	ss:[buffBytesLeft], ax
	jc	recv

copyBytes:
	segmov	ds, ss
	lea	si, ss:[recvBuff]
	add	si, ss:[buffByteCount]
	sub	si, ss:[buffBytesLeft]
	mov	cx, ax
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb

	sub	ss:[buffBytesLeft], ax
done:
	.leave
	ret

ReadGifFileData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GifSocketRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read from socket

CALLED BY:	ReadGifFileData
PASS:		inherit GifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GifSocketRecv	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter	inherit GifToBitmap

	; read data from the shared buffer

	mov	bx, ss:[dataHandle]
	call	MemLock
	mov	ds, ax

	; test if it's done
	mov	bx, ds:[done_sem]
	call	ThreadPSem

	mov	ax, ds:[done_flag]
	tst	ax
	jz	cont

	call	ThreadVSem
	jmp	abort
	
cont:	
	call	ThreadVSem
	
	mov	bx, ds:[buffer_full]
	call	ThreadPSem
	jc	unlock

	mov	cx, ds:[buffer_size]
	tst	cx
	jz	abort

	mov	ss:[buffByteCount], cx
	mov	ss:[buffBytesLeft], cx

	push	ds
	mov	bx, ds:[buffer_handle]
	call	MemPLock
	mov	ds, ax
	clr	si
	segmov	es, ss
	lea	di, ss:[recvBuff]
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb
	call	MemUnlockV
	pop	ds

	mov	bx, ds:[buffer_empty]
	call	ThreadVSem
unlock:
	mov	bx, ss:[dataHandle]
	call	MemUnlock
	clc
done:
	.leave
	ret

abort:
	mov	bx, ss:[dataHandle]
	call	MemUnlock
	stc
	jmp	done
	
GifSocketRecv	endp

GifCode	ends
