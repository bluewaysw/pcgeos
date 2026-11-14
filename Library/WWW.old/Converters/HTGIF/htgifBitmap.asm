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
		
	

	$Id: htgifBitmap.asm,v 1.1 97/04/07 11:51:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include geode.def
include resource.def
include ec.def
include object.def
include Objects/inputC.def
include timer.def
include sem.def
include hugearr.def

include stdapp.def
include file.def
include localize.def
include char.def

include htgifBitmap.def
;include htconv.def

GifCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    			GifToGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GifToBitmap

C DECLARATION:	extern word _pascal GifToBitmap(word dataHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GifToBitmap	proc	far	dataHandle:word

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
substColorTable	local	256 dup (byte)
buffBytesLeft	local	word
buffByteCount	local	word
recvBuff	local	512 dup (byte)

	ForceRef	gifFileHeader
	ForceRef	lzwDecodeVars
	ForceRef	pixCol
	ForceRef	pixRow
	ForceRef	interlacePass
	ForceRef	numColors
	ForceRef	colorTable
	ForceRef	substColorTable
	ForceRef	recvBuff

	uses	si,di,ds,es
	.enter

	; Receive GIF file

	clr	ss:[buffBytesLeft]
	clr	ss:[buffByteCount]

	call	LoadGifFileHeader
	LONG jc	done

	call	LoadGifImageHeader
	LONG jc	done

	; set bitmap type

	call	SetBitmapType

createBitmap::
	; create bitmap and decode gif image data

	call	ClipboardGetClipboardFile	; bx <- VM file handle
	mov	ss:[clipboardFile], bx
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

	push	ds:[htobject_offset]
	push	ds:[htobject_handle]
	push 	ss:[clipboardFile]
	push	ss:[clipboardBlock]
	call 	SETTARGETBITMAP

	; set the bounds 
	push	ds:[htobject_offset]
	push	ds:[htobject_handle]
	push	ss:[gifImageHeader].GIFIH_width
	push	ss:[gifImageHeader].GIFIH_height
	call	SETTARGETSIZE

	; tell the uigenerator to resize all components
	push	ds:[htobject_offset]
	push	ds:[htobject_handle]
	call 	CALLRESIZE

	mov	bx, ss:[dataHandle]
	call	MemUnlock

	call	SetBitmapPalette

	mov	ax, size LZWDecodeBuffers
	add	ax, ss:[gifImageHeader].GIFIH_width
	mov	cx, ALLOC_FIXED
	call	MemAlloc
	mov	es, ax
	call	GIFDecodeGIFData
	call	MemFree

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
	uses	ax, cx
	.enter	inherit GifToBitmap

	call	UserGetDisplayType
	andnf	ah, mask DT_DISP_CLASS

	; always create an 8 bit bitmap if we have an 8 bit display.

	mov	cl, BMF_8BIT shl offset BMT_FORMAT
	cmp	ah, DC_COLOR_8
	je	gotBitmapType
	cmp	ah, DC_GRAY_8
	je	gotBitmapType

	; else, set bitmap type based on number of colors in bitmap

	mov	al, ss:[gifFileHeader].GIFFH_globalFlags
	andnf	al, mask GIFGF_COLORRESOLUTION
	mov	cl, offset GIFGF_COLORRESOLUTION
	shr	al, cl
	inc	al
	mov	cl, al
	mov	ax, 1
	shl	ax, cl				; ax <- number of color entries
	cmp	ax, ss:[numColors]
	ja	10$
	mov	ax, ss:[numColors]
10$:
	mov	cl, BMF_MONO shl offset BMT_FORMAT
	cmp	ax, 2
	jbe	gotBitmapType

	mov	cl, BMF_4BIT shl offset BMT_FORMAT
	cmp	ax, 16
	jbe	gotBitmapType

	mov	cl, BMF_8BIT shl offset BMT_FORMAT

gotBitmapType:
	mov	ss:[bitmapType], cl

	.leave
	ret
SetBitmapType	endp



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
SetBitmapPalette	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter	inherit GifToBitmap

	push	bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	UserCallApplication
	mov	di, bp				; di <- gstate
	pop	bp
	jnc	done

	call	GrCreatePalette			; must always create palette
						; (bug in GrMapColorRGB) 
if (0)
	; if we have an 8bit display, lets change the palette.

	call	UserGetDisplayType
	andnf	ah, mask DT_DISP_CLASS
	cmp	ah, DC_COLOR_8
	je	changePalette
	cmp	ah, DC_GRAY_8
	jne	mapColors

changePalette:
	mov	ax, 16				; start at palette entry 16
	mov	cx, ss:[numColors]
	cmp	cx, 256 - 16
	jbe	setPalette
	mov	cx, 256 - 16
setPalette:
	mov	dx, ss
	lea	si, ss:[colorTable]
	call	GrSetPalette

	push	di
	mov	ax, GIT_WINDOW
	call	GrGetInfo
	mov	di, ax
	call	WinRealizePalette
	pop	di
endif

mapColors::
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

	call	GrDestroyState
done:
	.leave
	ret
SetBitmapPalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GIFDecodeGIFData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decode GIF data

CALLED BY:	GifToBitmap
PASS:		es = segment of LZWDecodeBuffers
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
GIFDecodeGIFData	proc	near
	uses	ax,bx,cx,dx,si,di,es
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
	mov	si, ax
	mov	al, ss:substColorTable[si]
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
	mov	si, cx
	mov	cl, ss:substColorTable[si]
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
EC <	WARNING	WARNING_ERROR_IN_GIF_DATA				>
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

	mov	ss:[lzwDecodeVars].LZWDV_stack_ptr, offset LZWDS_stack

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
	jae	getCode

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
PASS:		es = segment of LZWDecodeBuffers
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
	jae	nextScan

	mov	bx, ss:[clipboardFile]
	mov	di, ss:[clipboardBlock]
	call	HugeArrayLock
	tst	ax
	jz	nextScan

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

write24bit::
write8bit::
	shr	cx, 1
	jnc	mwords
	movsb
mwords:	rep	movsw
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
	.leave
	ret
GIFWriteScanline	endp

	; Interlace Tables
baseRow	word	0, 4, 2, 1
rowIncr	word	8, 8, 4, 2



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
EC <	WARNING_C -1							>
	jc	done				; exit with carry set

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
		SocketRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read from socket

CALLED BY:	ReadGifFileData
PASS:		ds = es = dgroup
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
