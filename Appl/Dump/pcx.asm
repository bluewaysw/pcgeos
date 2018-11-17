COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- PC Paintbrush Format
FILE:		pcx.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
	PCXPrologue		Initialize file
	PCXSlice		Write a bitmap slice to the file
	PCXEpilogue		Cleanup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 4/89	Initial revision


DESCRIPTION:
	Output-dependent routines for creating a PC-paintbrush file.
		

	$Id: pcx.asm,v 1.1 97/04/04 15:36:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def
include Internal/videoDr.def

PCXVersions	etype	byte
PCX_V2_5	enum	PCXVersions, 0
PCX_V2_8PALETTE	enum	PCXVersions, 2
PCX_V2_8NOPAL	enum	PCXVersions, 3
PCX_V3		enum	PCXVersions, 5

PCXEncoding	etype	byte
PCX_NOENCODING	enum	PCXEncoding, 0
PCX_RLE		enum	PCXEncoding, 1

PCXPaletteTypes	etype	word
PCX_COLOR_BW	enum	PCXPaletteTypes, 1	; Color or B&W image
PCX_GREY_SCALE	enum	PCXPaletteTypes, 2	; Greyscale image

PCX_MAX_RUN	equ	63
PCX_RUN		equ	0xc0

PCXHeader	struct
    PCXH_id		byte	0xa	; Magic number
    PCXH_version	PCXVersions	PCX_V3	; Version number
    PCXH_encoding	PCXEncoding	PCX_RLE	; Encoding style
    PCXH_bitsPerPixel	byte	1	; Number of bits per pixel
	; Image bounding box
    PCXH_upLeftX	word	0
    PCXH_upLeftY	word	0
    PCXH_lowRightX	word	?
    PCXH_lowRightY	word	?
	; Screen characteristics
    PCXH_dispXRes	word	?	; Horizontal resolution (dpi)
    PCXH_dispYRes	word	?	; Vertical resolution (dpi)
    PCXH_palette	RGBValue	<0x00, 0x00, 0x00>,	;Black\
					<0x00, 0x00, 0xaa>,	;Dark Blue\
					<0x00, 0xaa, 0x00>,	;Dark Green\
					<0x00, 0xaa, 0xaa>,	;Dark Cyan\
					<0xaa, 0x00, 0x00>,	;Dark Red\
					<0xaa, 0x00, 0xaa>,	;Dark Violet\
					<0xaa, 0x55, 0x00>,	;Brown\
					<0xaa, 0xaa, 0xaa>,	;Light Grey\
					<0x55, 0x55, 0x55>,	;Dark Grey\
					<0x55, 0x55, 0xff>,	;Light blue\
					<0x55, 0xff, 0x55>,	;Light green\
					<0x55, 0xff, 0xff>,	;Light cyan\
					<0xff, 0x55, 0x55>,	;Light red\
					<0xff, 0x55, 0xff>,	;Light violet\
					<0xff, 0xff, 0x55>,	;Yellow\
					<0xff, 0xff, 0xff>	;White
    			byte	?	; Reserved...
    PCXH_planes		byte	1	; # of planes
    PCXH_bytesPerPlane	word	?	; # of bytes in a bitplane
    PCXH_paletteInfo	PCXPaletteTypes	PCX_COLOR_BW	; Type of image
    			byte	128 - size PCXHeader dup(?)
PCXHeader	ends

idata	segment

PCXProcs	DumpProcs	<
	0, PCXPrologue, PCXSlice, PCXEpilogue, <'pcx'>,
	mask DUI_DESTDIR or mask DUI_BASENAME or mask DUI_DUMPNUMBER or \
	mask DUI_ANNOTATION
>

pcxHeader	PCXHeader

idata	ends

udata	segment

pcxRealBPP		word	0	; Real bytes-per-plane, for mono dumps

udata	ends

PCX	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCXPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a PC-Paintbrush file

CALLED BY:	DumpScreen
PASS:		si	= BMFormat
		bp	= file handle
		cx	= dump width
		dx	= dump height
		ds	= dgroup
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCXPrologue	proc	far	uses es, di, cx, dx
		.enter
		les	di, ds:vidDriver

		;
		; Make sure the bitmaps will be in a format we can handle
		;
		cmp	si, BMF_MONO
		je	formatOK
		cmp	si, BMF_4BIT
		je	formatOK
		stc
		jmp	done
formatOK:
		;
		; Copy data about the pixels into the header.
		;
		mov	al, es:[di].VDI_nBits
		mov	ds:pcxHeader.PCXH_bitsPerPixel, al
		mov	al, es:[di].VDI_nPlanes
		mov	ds:pcxHeader.PCXH_planes, al
		;
		; Copy the display-resolution information in
		;
		mov	ax, es:[di].VDI_pageW
		mov	ds:pcxHeader.PCXH_dispXRes, ax
		mov	ax, es:[di].VDI_pageH
		mov	ds:pcxHeader.PCXH_dispYRes, ax
		;
		; Convert pixels to # bytes. Since we always store things as
		; a succession of one or more bit-planes, the number of bytes
		; per plane is (width + 7) / 8.
		;
		mov	ax, cx
		add	ax,7				
		shr	ax
		shr	ax
		shr	ax				;AX <- bytes per plane
		mov	ds:[pcxRealBPP], ax

		inc	ax			; round up to nearest word
		andnf	ax, not 1		;  as required...
		mov	ds:pcxHeader.PCXH_bytesPerPlane, ax

		dec	cx		; Need coordinates, not 1-origin
		dec	dx		;  size.
		mov	ds:pcxHeader.PCXH_lowRightX, cx
		mov	ds:pcxHeader.PCXH_lowRightY, dx
		
		;
		; Now the header is properly initialized, write the whole thing
		; out at once. This will position the file properly as well.
		;
		mov	bx, bp
		mov	dx, offset pcxHeader
		mov	cx, size pcxHeader
		clr	al
		call	FileWrite
done:
		.leave
		ret
PCXPrologue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine converts the bits in a buffer to be in bitplane
		format.

CALLED BY:	ConvertToBitPlanes
PASS:		ds:si - source bitmap
		es:di - destination for bit plane
		dl - bit in pixel to grab to put into plane buffer (0-3)
			(3 is most significant bit of nibble)
		bx - # bytes per line
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertScanLine	proc	near 	uses ax,bx,cx,dx,si,di
		.enter
		mov	cx, 0x404	;Convert right-oriented index into
					; left-oriented one
					;CH <- 4 for use in getting second
					; pixel bit
		sub	cl, dl		
		mov	dx, bx		;DX <- # bytes per line
		mov	bx, 4		;Initialize pixel counter (we handle
					; two pixels at once, so initial count
					; is 4)
scanLoop:
		lodsb			;AL <- byte in line
		shl	al, cl		;Shift interesting bit into CF
		rcl	ah		;Shift it into the byte we're building
					; (leftmost pixel in msb)
		xchg	ch, cl		;CL <- 4 to shift equivalent bit from
					; second pixel into CF
		shl	al, cl
		rcl	ah		;Shift second pixel's bit into byte
		xchg	ch, cl		;Recover left-pixel shift count
		dec	bx		;Another pixel-pair complete
		jnz	byteNotDone
		mov	al, ah		;Store byte we've built up.
		not	al		;Invert, so comes out right in the face
					; of inverting bitplane in PCXSlice
		stosb
		mov	bx, 4		;Reinitialize pixel-pair counter
byteNotDone:
		dec	dx		;Reduce line-byte count; that it?
		jnz	scanLoop	;Nope -- go get more
	;
	; Handle potential partially-filled byte. If bx is anything but
	; 4, we've got a partial pixel in ah. We need to shift those
	; bits up so the leftmost one is up at the msb where it needs
	; to be. We do this a little backwards, however. We want to end
	; up with the byte in al so we can store it away, so we make
	; the shift count be
	;	8 - (2 * pairs-needed)
	; and shift all of ax right that amount (note we don't/shouldn't
	; care what is in the right-most bits of al when we store it as
	; the reader of this file isn't supposed to pay attention to
	; pixels off the end of the scan-line.
	;
		mov	cl, 8
		shl	bx		;pairs-needed *= 2
		sub	cl, bl
		jz	noFragment	;zero => we don't have any leftovers
		shr	ax, cl		;position properly in al
		not	al		;Invert, so comes out right in the face
					; of inverting bitplane in PCXSlice
		stosb			;stuff the byte away.
noFragment:
		.leave
		ret
ConvertScanLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToBitPlanes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes a pointer to a bitmap and returns the bit-
		per-pixel data in bitplane format

CALLED BY:	PCXSlice
PASS:		es:0 - ptr to bitmap
		dx - height of bitmap
		si - BMFormat enum
		ds - idata
RETURN:		bx - handle of new bitmap block (es - ptr to it)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertToBitPlanes	proc	near	uses	ax,cx,dx,di,si,ds
		.enter
		push	bx
	;
	; Allocate another block to hold a new "monochrome" bitmap made
	; from all the pixels converted to bit-planes.
	;
		mov	ax,ds:pcxHeader.PCXH_bytesPerPlane
		mov	ds:[pcxRealBPP], ax	;Adjust to rounded form as
						; ConvertScanLine will create
						; scans that are rounded.
		push	ax			;Save # bytes per plane for
						; when we don't have ds = dgroup
		shl	ax,1			;Multiply bytes per plane *
						; 4 planes = bytes per scanline
		shl	ax,1
		push	dx
		mul	dx			;AX <- bytes per line * height
						; of BM
		pop	dx
		add	ax, size Bitmap		;AX <- total size of converted
						; bitmap
		segmov	ds,es,cx		;DS <- segment of old bitmap
						; block
		mov	cx,ALLOC_DYNAMIC_NO_ERR_LOCK;Alloc and lock a block for
		call	MemAlloc		; converted bitmap
		mov	es,ax
	;
	; Initialize new bitmap block
	;
		clr	si			;DS:SI <- beginning of old block
		mov	di,si			;ES:DI <- beginning of new block
		mov	cx,size Bitmap
		rep	movsb			;Copy over bitmap header
		mov	cx,dx			;CX <- # lines in bitmap
		shl	dx
		shl	dx
		mov	es:B_height, dx	;Store actual height of bitmap
		;
		; Now break each scanline of 4-bit pixels into a set of 4
		; bit-planes
		;
		pop	ax			;Get # bytes per plane
		push	bx
		mov	bx, ds:B_width		;BX <- # bytes per scanline in
		inc	bx			; source (two pixels/byte,
		shr	bx			; rounded to nearest byte)
						
scanloop:
		mov	dx,0
		call	ConvertScanLine		;Convert low bit of scan line.
		add	di, ax			;Point to next scan line
		inc	dx
		call	ConvertScanLine		;Convert 2nd bit of scan line.
		add	di, ax
		inc	dx
		call	ConvertScanLine		;Convert 3rd bit of scan line.
		add	di, ax
		inc	dx
		call	ConvertScanLine		;Convert high bit of scan line.
		add	di, ax
		add	si, bx			;Go to next scan line
		loop	scanloop		;Loop until all lines processed

		pop	ax			;AX <- handle of new block
		pop	bx			;BX <- handle of old block
		call	MemFree			;Free up old bitmap block
		mov	bx,ax			;BX <- handle of new bitmap
		.leave
		ret
ConvertToBitPlanes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCXSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single bitmap slice out to the file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		si	= bitmap block handle
		cx	= size of bitmap (bytes)
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCXSlice	proc	far	uses es, di, ax, bx, dx
fileBuf		local	1024 dup(byte)	; Buffer filled by PCXWrite
filePtr		local	word		; Temp var to make life easier
		.enter
		mov	bx, si
		call	MemLock
		mov	es, ax
		;
		; Deal with a color bitmap: the PCX format demands things in
		; bit-planes. Sadly, we get the data as actual pixels, so we
		; must convert the thing to bit-planes. Rather than have a
		; separate routine to deal with this color stuff and its
		; run-length encoding and so on, we simply convert the slice
		; into a monochrome bitmap that is four times as high...it's
		; just data, after all.
		;
		mov	si, {word}es:B_type
		and	si, mask BMT_FORMAT
		cmp	si, BMF_MONO	;Is it a black and white bitmap?
		je	common		;If so, branch
		call	ConvertToBitPlanes
common:
		;
		; Now run-length encode each scanline. Through the loop,
		; di tends to contain the position in fileBuf at which the
		; next byte is to be written; cx contains the number of
		; bytes left to encode; dx contains the number of scanlines
		; left to encode.
		; 
		mov	dx, es:B_height
		mov	si, size Bitmap
		clr	di		;Initialize file buffer pointer
scanLineTop:
		mov	cx, ds:pcxHeader.PCXH_bytesPerPlane
		push	si
scanLoop:
		lodsb	es:
		dec	cx
		mov	filePtr, di	; Save file pointer
		mov	di, si
		repe	scasb		; Will do nothing and exit with ZF=1
					;  if al is the last byte of the line
					;  (the decrement sets ZF if last byte)
		je	atEnd
		dec	di		; Pushback mismatch
		inc	cx
atEnd:
		sub	di, si		; Figure run length
		tst	di
		jz	noRun
		add	si, di		; Shift SI to the end of the run now
		inc	di		; Need it 1-origin, not 0-origin
					;  as the format doesn't take advantage
					;  of knowing you can't have a run of 0
		push	cx		; Save byte counter
		;
		; Create as many runs as are necessary given the limit on
		; run-length inherent in the encoding.
		;
		mov	cx, di
		mov	di, filePtr	; Recover file index for PCXWrite
runLoop:
		mov	ax, cx
		cmp	ax, PCX_MAX_RUN
		jle	10$
		mov	ax, PCX_MAX_RUN
10$:
		sub	cx, ax		; Adjust bytes left in run
		or	al, PCX_RUN	; Make into run-length token
		call	PCXWrite
		jc	error
		mov	al, es:[si-1]	; Fetch match byte
		not	al		; Convert to PCX polarity
		call	PCXWrite
		jc	error
		;
		; Run complete?
		;
		tst	cx
		jnz	runLoop
		;
		; Recover byte counter and go past non-run case
		;
		pop	cx
		jmp	scanLoopEnd
error:
		;
		; Write error -- clean up stack and get out of here with
		; carry still set.
		;
		pop	cx
nonRunError:
		pop	si
		jmp	done		
noRun:
		;
		; Handle non-run case and problem bytes.
		; al = byte, si points past it
		;
		mov	di, filePtr
		not	al		; convert to standard PCX polarity
		test	al, PCX_RUN
		jz	noProblem
		jnp	noProblem
		;
		; This byte's a problem in that it has the top two bits set.
		; we need to create a "run" of 1 for it.
		;
		push	ax
		mov	al, PCX_RUN or 1
		call	PCXWrite
		pop	ax
		jc	nonRunError
noProblem:
		; write the byte to the file
		call	PCXWrite
		jc	nonRunError
scanLoopEnd:
		; done with this scanline?
		tst	cx
		jnz	scanLoop
		
		pop	si
		add	si, ds:[pcxRealBPP]
		dec	dx		; Reduce scan-line counter
		jnz	scanLineTop
		;
		; Flush any remaining bytes to the file
		;
		tst	di
		jz	done
		push	ds
		push	bx		;Save bitmap block handle
		mov	cx, di		; cx <- count
		segmov	ds, ss, dx	; ds:dx <- buffer address
		lea	dx, fileBuf
		mov	bx, ss:[bp]	; bx <- file handle
		clr	ax		; We can take errors
		call	FileWrite
		pop	bx		;Restore handle of bitmap
		pop	ds
done:
		;
		; bitmap's memory handle still in BX: free the block (it
		; doesn't matter that it's still locked).
		;
		pushf			; Save possible error return
		call	MemFree
		popf
		.leave
		ret
PCXSlice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCXWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write another character to the output file.

CALLED BY:	PCXSlice
PASS:		ss:[bp]	= file handle
		al	= character to write
		di	= buffer offset
		stack frame containing fileBuf and filePtr inherited from
		PCXSlice
RETURN:		di	= new buffer offset
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCXWrite	proc	near	uses bx, cx, dx, ds
fileBuf		local	1024 dup(byte)
filePtr		local	word
		.enter	inherit
		;
		; Store the character away
		;
		mov	fileBuf[di], al
		;
		; Buffer overflow?
		;
		inc	di
		cmp	di, size fileBuf
		clc			; signal no error...
		jne	noWrite
		;
		; Flush the buffer to disk
		;
		mov	cx, di		; cx <- count
		segmov	ds, ss, dx	; ds:dx <- buffer address
		lea	dx, fileBuf
		mov	bx, ss:[bp]	; bx <- file handle
		clr	di		; Clear buffer offset now so we don't
					;  biff the returned carry.
		mov	ax, di		; We can take errors
		call	FileWrite
noWrite:
		.leave
		ret
PCXWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCXEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off a PC-Paintbrush file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCXEpilogue	proc	far
		.enter
		clc		; Nothing to do here
		.leave
		ret
PCXEpilogue	endp

PCX		ends
