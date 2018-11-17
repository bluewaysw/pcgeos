COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		GeoWrite
FILE:		uiGifImage.asm

AUTHOR:		Joon Song, Dec 03, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/03/98   	Initial revision


DESCRIPTION:
		
	

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GifImageCode	segment	resource

include uiGifImage.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    			ConvertGifToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert GIF file to GEOS bitmap

CALLED BY:	INTERNAL
PASS:		bx	= GIF FileHandle
RETURN:		^lcx:dx = Bitmap
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertGifToBitmap	proc	far
gifFileHeader	local	GIFFileHeader
gifImageHeader	local	GIFImageHeader
lzwDecodeVars	local	LZWDecodeVars
colorTable	local	hptr
pixCol		local	word
pixRow		local	word
interlacePass	local	word
numColors	local	word
bitmapType	local	BMType
bitmapFile	local	word
bitmapBlock	local	word
bufferBytes	local	word
bufferLength	local	word
fileHandle	local	word
fileBuffer	local	512 dup (byte)

	ForceRef	gifFileHeader
	ForceRef	lzwDecodeVars
	ForceRef	pixCol
	ForceRef	pixRow
	ForceRef	interlacePass
	ForceRef	numColors
	ForceRef	bufferBytes
	ForceRef	bufferLength
	ForceRef	fileHandle
	ForceRef	fileBuffer
	ForceRef	colorTable

	uses	ax,bx,si,di,es
	.enter

	mov	ss:[fileHandle], bx
	clr	ss:[bufferBytes]
	clr	ss:[bufferLength]

	mov	ax, (size RGBValue) * 256
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	ss:[colorTable], bx

	call	GIFLoadFileHeader
	jc	done

	call	GIFLoadImageHeader
	jc	done

	call	GIFSetBitmapType

	; create bitmap and decode gif image data

	call	ClipboardGetClipboardFile	; bx <- VM file handle
	mov	ss:[bitmapFile], bx
	mov	al, ss:[bitmapType]
	mov	cx, ss:[gifImageHeader].GIFIH_width
	mov	dx, ss:[gifImageHeader].GIFIH_height
	clr	di, si				; no MSG_META_EXPOSED OD
	call	GrCreateBitmap			; ax <- VM block handle
						; di <- gstate
	mov	ss:[bitmapBlock], ax

	call	GIFSetBitmapPalette

	mov	ax, size LZWDecodeBuffers
	add	ax, ss:[gifImageHeader].GIFIH_width
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	call	GIFDecodeGIFData
	call	MemFree

	mov	al, BMD_LEAVE_DATA
	call	GrDestroyBitmap

	mov	cx, ss:[bitmapFile]
	mov	dx, ss:[bitmapBlock]
done:
	pushf
	mov	bx, ss:[colorTable]
	call	MemFree
	popf

	.leave
	ret
ConvertGifToBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFLoadFileHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load GIF file header

CALLED BY:	ConvertGifToBitmap
PASS:		inherit ConvertGifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFLoadFileHeader	proc	near
	uses	ax,cx,di,es
	.enter	inherit ConvertGifToBitmap

	; load GIF file header

	segmov	es, ss
	lea	di, ss:[gifFileHeader]
	mov	ax, size gifFileHeader
	call	GIFReadGIFFileData	; es:di = GIFFileHeader
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
	call	GIFLoadColorTable
done:
	.leave
	ret

error:
	WARNING	-1
	stc
	jmp	done

GIFLoadFileHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFLoadImageHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load GIF image header

CALLED BY:	ConvertGifToBitmap
PASS:		inherit ConvertGifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFLoadImageHeader	proc	near
	uses	ax,cx,di,es
	.enter	inherit ConvertGifToBitmap

readLabel:
	segmov	es, ss
	lea	di, ss:[gifImageHeader]
	mov	ax, 1
	call	GIFReadGIFFileData
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
	call	GIFReadGIFFileData		; skip extension introducer

extensionBlockLoop:
	mov	ax, 1
	call	GIFReadGIFFileData		; read block size
	jc	done
	
	mov	al, es:[di]
	tst	al				; if blocksize = 0, end of ext
	jz	readLabel

	call	GIFReadGIFFileData
	jnc	extensionBlockLoop
	jmp	done

loadImageHeader:
	lea	di, ss:[gifImageHeader][1]
	mov	ax, size gifImageHeader - 1
	call	GIFReadGIFFileData
	jc	done

	mov	cl, ss:[gifImageHeader].GIFIH_localFlags
	test	cl, mask GIFLF_COLORTABLE
	jz	done

	andnf	cl, mask GIFLF_COLORTABLESIZE
	inc	cl
	mov	ax, 1
	shl	ax, cl				; ax <- number of color entries
	mov	ss:[numColors], ax
	call	GIFLoadColorTable
done:
	.leave
	ret
GIFLoadImageHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFLoadColorTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load color table

CALLED BY:	ConvertGifToBitmap
PASS:		inherit ConvertGifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFLoadColorTable	proc	near
	uses	ax,di,es
	.enter	inherit ConvertGifToBitmap

	; load color table

	mov	bx, ss:[colorTable]
	call	MemDerefES
	clr	di
	mov	ax, ss:[numColors]
	add	ax, ax
	add	ax, ss:[numColors]
	call	GIFReadGIFFileData	; es:di = color table, ax = errorCode

	.leave
	ret
GIFLoadColorTable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFSetBitmapType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bitmap type

CALLED BY:	ConvertGifToBitmap
PASS:		inherit ConvertGifToBitmap stack frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFSetBitmapType	proc	near
	uses	ax, cx
	.enter	inherit ConvertGifToBitmap

	; set bitmap type based on number of colors in bitmap

	mov	cl, ss:[gifFileHeader].GIFFH_globalFlags
	andnf	cl, mask GIFGF_COLORRESOLUTION
	shr	cl, offset GIFGF_COLORRESOLUTION
	inc	cl
	mov	ax, 1
	shl	ax, cl				; ax = number of color entries
	cmp	ax, ss:[numColors]

	mov	cl, (BMF_MONO shl offset BMT_FORMAT) or mask BMT_PALETTE
	cmp	ax, 2
	jbe	gotBitmapType

	mov	cl, (BMF_4BIT shl offset BMT_FORMAT) or mask BMT_PALETTE
	cmp	ax, 16
	jbe	gotBitmapType

	mov	cl, (BMF_8BIT shl offset BMT_FORMAT) or mask BMT_PALETTE

gotBitmapType:
	mov	ss:[bitmapType], cl

	.leave
	ret
GIFSetBitmapType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFSetBitmapPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set palette

CALLED BY:	ConvertGifToBitmap
PASS:		ds = dgroup
		di = gstate
		inherit ConvertGifToBitmap stack frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFSetBitmapPalette	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter	inherit ConvertGifToBitmap

	call	GrCreatePalette

	mov	bx, ss:[colorTable]
	call	MemDerefES
	mov	dx, es
	clr	si

	clr	ax
	mov	cx, ss:[numColors]
	call	GrSetPalette

	push	di
	mov	ax, GIT_WINDOW
	call	GrGetInfo
	mov	di, ax
	call	WinRealizePalette
	pop	di

	.leave
	ret
GIFSetBitmapPalette	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFDecodeGIFData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decode GIF data

CALLED BY:	ConvertGifToBitmap
PASS:		ds = dgroup
		es = segment of LZWDecodeBuffers
		inherit ConvertGifToBitmap stack frame
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFDecodeGIFData	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter	inherit ConvertGifToBitmap

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
	mov	es:LZWDS_scanline[di], al
	inc	di
	mov	ss:[pixCol], di
	cmp	di, ss:[gifImageHeader].GIFIH_width
	jb	getCode

outputLine::
	call	GIFWriteScanline
	jmp	getCode

done:
	.leave
	ret


notClear:
	; not clear code
	;	ax = c, bx = code, di = sp

	mov	bx, ax
	mov	ss:[lzwDecodeVars].LZWDV_code, bx	; code = c

	mov	di, ss:[lzwDecodeVars].LZWDV_stack_ptr
	cmp	bx, ss:[lzwDecodeVars].LZWDV_slot	; code >= slot
	jb	10$
	LONG ja	error

	mov	bx, ss:[lzwDecodeVars].LZWDV_oc
	mov	ss:[lzwDecodeVars].LZWDV_code, bx	; code = oc
	mov	cx, ss:[lzwDecodeVars].LZWDV_fc
	mov	es:LZWDS_stack[di], cl			; *sp = fc
	inc	di					; sp++
10$:
	; Here we scan back along the linked list of prefixes, pushing
	; helpless characters (ie. suffixes) onto the stack as we do so.

	mov	cx, ss:[lzwDecodeVars].LZWDV_newcodes
	jmp	scanTest
scanLoop:
	mov	dl, es:LZWDS_suffix[bx]
	mov	es:LZWDS_stack[di], dl			; *sp <- suffix[code]
	inc	di					; sp++
	shl	bx, 1					; bx <- word offset
	mov	bx, es:LZWDS_prefix[bx]			; code <- prefix[code]
scanTest:
	cmp	bx, cx					; (code >= newcodes)
	jae	scanLoop

	mov	es:LZWDS_stack[di], bl			; *sp <- code
	inc	di					; sp++
	mov	ss:[lzwDecodeVars].LZWDV_stack_ptr, di
	mov	ss:[lzwDecodeVars].LZWDV_code, bx

	mov	di, ss:[lzwDecodeVars].LZWDV_slot
	cmp	di, ss:[lzwDecodeVars].LZWDV_top_slot
	jae	20$
							; slot < top_slot
	mov	ss:[lzwDecodeVars].LZWDV_fc, bx		; fc = code
	mov	es:LZWDS_suffix[di], bl			; suffix[slot] = code
	mov	cx, ss:[lzwDecodeVars].LZWDV_oc
	shl	di, 1					; di <- word offset
	mov	es:LZWDS_prefix[di], cx			; prefix[slot] = oc
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
pixelLoop:
	cmp	di, offset LZWDS_stack
	je	doneCode

	dec	di
	mov	cl, es:LZWDS_stack[di]
	mov	es:LZWDS_scanline[bx], cl
	inc	bx
	cmp	bx, ax
	jb	pixelLoop

	call	GIFWriteScanline
	clr	bx
	jmp	pixelLoop

doneCode:
	mov	ss:[lzwDecodeVars].LZWDV_stack_ptr, di
	mov	ss:[pixCol], bx
	jmp	getCode

error:
	WARNING	-1
	stc
	jmp	done

GIFDecodeGIFData	endp



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
	call	GIFReadGIFFileData		; ax = errorCode
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

	mov	ss:[lzwDecodeVars].LZWDV_stack_ptr, offset LZWDS_stack

	; pixCol = pixRow = interlacePass = 0

	mov	ss:[pixCol], ax
	mov	ss:[pixRow], ax
	mov	ss:[interlacePass], ax
done:	
	.leave
	ret

error:
	WARNING	-1
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
	jae	getCode

	; we need to move any leftover bits to the front of the buffer

	segmov	es, ss
	mov	di, ss:[lzwDecodeVars].LZWDV_block_size
	shr	di, 3
	mov	ax, {word} ss:[lzwDecodeVars].LZWDV_byte_buff[di-2]
	lea	di, ss:[lzwDecodeVars].LZWDV_byte_buff[0]
	stosw
	mov	ss:[lzwDecodeVars].LZWDV_block_size, 16

	; now read more data

	mov	ax, 1
	call	GIFReadGIFFileData
	jc	done

	clr	ax
	mov	al, es:[di]
	call	GIFReadGIFFileData
	jc	done

	shl	ax, 3
	add	ss:[lzwDecodeVars].LZWDV_nbits_left, ax
	add	ss:[lzwDecodeVars].LZWDV_block_size, ax
	mov	ax, ss:[lzwDecodeVars].LZWDV_nbits_left

getCode:
	mov	di, ss:[lzwDecodeVars].LZWDV_block_size
	sub	di, ax				; di <- LZW code bit position
	mov	cx, di				; cx <- LZW code bit position
	shr	di, 3				; di <- LZW code byte position
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
PASS:		ds = dgroup
		es = segment of LZWDecodeBuffers
		inherit GIFDecodeGIFData stack frame
RETURN:		bitmap data
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
EC <	WARNING_AE -1							>
	LONG jae nextScan

	mov	bx, ss:[bitmapFile]
	mov	di, ss:[bitmapBlock]
	call	HugeArrayLock
	tst	ax
	LONG jz	nextScan

	segxchg	es, ds
	mov	di, si
	mov	si, offset LZWDS_scanline
	mov	cx, dx
	jcxz	unlock

	mov	al, ss:[bitmapType]
	and	al, mask BMT_FORMAT
	cmp	al, BMF_MONO shl offset BMT_FORMAT
	je	writeMono

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
	lodsb
	mov	ah, al
	shl	ah, 4
	lodsb
	and	al, 0x0f	
	ornf	al, ah
	stosb
	dec	dx
	jnz	write4bit
	jmp	unlock

writeMono:
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
	lodsb
	shr	al, 1
	rcr	ah, 1
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
	jae	done			; no more after 4 passes

	mov	bx, ss:[interlacePass]
	shl	bx, 1			; convert to word index
	mov	ax, cs:baseRow[bx]	; ax <- 1st row of next interlace pass
	mov	ss:[pixRow], ax
done:
	.leave
	ret
GIFWriteScanline	endp

	; Interlace Tables
baseRow	word	0, 4, 2, 1
rowIncr	word	8, 8, 4, 2



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFReadGIFFileData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read GIF file data

CALLED BY:	INTERNAL
PASS:		inherit ConvertGifToBitmap stack frame
		es:di	= buffer to read into
		ax	= number of bytes to read
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GIFReadGIFFileData	proc	near
	uses	bx,cx,si,di,ds
	.enter	inherit ConvertGifToBitmap

readLoop:
	cmp	ax, size fileBuffer
	jbe	readData

	push	ax
	mov	ax, size fileBuffer
	call	GIFReadGIFFileData
	pop	ax
	jc	done

	sub	ax, size fileBuffer
	add	di, size fileBuffer
	jmp	readLoop

readData:
	segmov	ds, ss
	cmp	ss:[bufferBytes], ax
	jae	copyBytes

	push	es, di
	segmov	es, ss
	lea	di, ss:[fileBuffer]
	mov	si, di
	add	si, ss:[bufferLength]
	mov	cx, ss:[bufferBytes]
	sub	si, cx
	rep	movsb
	pop	es, di

	mov	cx, ss:[bufferBytes]
	mov	ss:[bufferLength], cx

	push	ax
	clr	ax
	mov	bx, ss:[fileHandle]
	lea	dx, ss:[fileBuffer]
	add	dx, cx
	sub	cx, size fileBuffer
	neg	cx
	call	FileRead
	pop	ax

	add	ss:[bufferBytes], cx
	add	ss:[bufferLength], cx

	cmp	ss:[bufferBytes], ax
	jc	done

copyBytes:
	lea	si, ss:[fileBuffer]
	add	si, ds:[bufferLength]
	sub	si, ds:[bufferBytes]
	mov	cx, ax
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb
	sub	ds:[bufferBytes], ax
done:
	.leave
	ret
GIFReadGIFFileData	endp

GifImageCode	ends
