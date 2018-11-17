COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Source
FILE:		sourcePointer.asm

AUTHOR:		Gene Anderson, Feb  5, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT GetBitmapAndWritePointer 
				Get the specified bitmap and write as a
				pointer image.

    INT WritePointerHeader	Write the header for a pointer

    INT WritePointerData	Writes the formatted bits of the icon as a
				cursor image.

    INT WriteOneScanLine	Writes 1 scan line of the mask for the
				pointer image.

    INT GetNextCharacterForMask Gets a byte from the bitmap and makes 2
				characters from it.

    INT GetNextCharacterForImage 
				Gets a byte from the bitmap and makes 2
				characters from it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/ 5/93		Initial revision
	stevey	2/ 9/93		finished it up
	stevey	6/14/94		rewrote

DESCRIPTION:
	

	$Id: sourcePointer.asm,v 1.1 97/04/04 16:06:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SourceCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapAndWritePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the specified bitmap and write as a pointer image.

CALLED BY:	WriteSourceCode

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry 	- set if error
		ax	- WriteSourceErrors

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 5/93		Initial version
	stevey	2/ 9/93		finished it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapAndWritePointer	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,ds
		.enter	inherit DBViewerWriteSource
	;
	;  Get the format to write.
	;
		push	bp			; locals
		mov	bx, ss:WSFrame.WSF_curFormat
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat		; ^vcx:dx = current format
		pop	bp			; locals
		
		tst	dx			; any bitmap?
		jz	done
	;
	;  Write the header for the pointer.
	;
		movdw	ss:WSFrame.WSF_bitmap, cxdx
		call	WritePointerHeader
		jc	done
	;
	;  Write the data.
	;
		call	WritePointerData
		mov	ax, WSE_FILE_WRITE
		jc	done
noError::
		mov	ax, WSE_NO_ERROR
done:
		.leave
		ret
GetBitmapAndWritePointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePointerHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the header for a pointer

CALLED BY:	GetBitmapAndWritePointer()

PASS:		ds:di	= DBViewerInstance
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry set on error (ax = WriteSourceErrors)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	PointerDef <
		16,				; PD_width
		16,				; PD_height
		0,				; PD_hotX
		0				; PD_hotY
	>

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 5/93		Initial version
	stevey	2/ 9/93		finished it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePointerHeader	proc	near
		class	DBViewerClass
		uses	bx, cx, dx, ds
		.enter	inherit GetBitmapAndWritePointer
	;
	;  Write "PointerDef <"
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString PointerDefString
		WriteString OpenAngleBracket
		WriteString CRLF
	;
	;  Get the width & height of the bitmap and convert to ASCII.
	;
		movdw	cxdx, ss:WSFrame.WSF_bitmap
		call	HugeBitmapGetFormatAndDimensions
	;
	;  If the thing has invalid dimensions, complain.
	;
		cmp	cx, MOUSE_POINTER_WIDTH
		jne	badImage
		
		cmp	dx, MOUSE_POINTER_HEIGHT
		jne	badImage
	;
	;  The dimensions are OK...write them out.
	;
		mov	bx, dx			; bx = height
		clr	dx
		mov_tr	ax, cx			; dx:ax = dword to write
		call	IconWriteNumber
		jc	error
	;
	;  Write the width comment string.
	;
		WriteString WidthCommentString
	;
	;  Write the height and height comment.
	;
		mov_tr	ax, bx
		clr	dx			; dx:ax = dword to convert
		call	IconWriteNumber

		WriteString HeightCommentString
	;
	;  Write the rest of the header.  (Slap 0's in the hot spot x & y).
	;
		WriteString HotXCommentString
		WriteString HotYCommentString
		WriteString CloseAngleBracket
		WriteString CRLF
		jc	error
	;
	;  Return no error.
	;
		mov	ax, WSE_NO_ERROR
done:
		.leave
		ret
error:
		mov	ax, WSE_FILE_WRITE
		jmp	done
badImage:
		stc
		mov	ax, WSE_INVALID_IMAGE
		jmp	done
		
WritePointerHeader		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePointerData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the formatted bits of the icon as a cursor image.

CALLED BY:	GetBitmapAndWritePointer

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		ax = WriteSourceErrors
		(carry set on error)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Use the following scheme to write the image & mask:
	(courtesy Gene Anderson)

	pixel		mask	 	image		screen
	color		pixel		pixel		pixel
	-----		-----		-----		------
	black		  1		  0		black
	white		  1		  1		white
	dark gray	  0		  1		xor
	other		  0		  0		unchanged

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePointerData	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,ds
		.enter	inherit	GetBitmapAndWritePointer
	;
	;  Write the mask data.  Start by writing a "byte" string.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString ByteString
	;
	;  Loop through the scan lines in the bitmap (which
	;  correspond to huge array elements) and write out the
	;  data according to the table in this routine's header.
	;
		BitSet	ss:WSFrame.WSF_flags, WSF_WRITING_MASK
		BitClr	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		clr	dx, ax			; lock first element
		call	HugeArrayLock		; ds:si = element
		movdw	ss:WSFrame.WSF_element, dssi
		mov	ss:WSFrame.WSF_elemSize, dx
maskLoop:
	;
	;  Write out the data for this element as one scanline.
	;
		tst	ax			; valid element?
		jz	doneMask

		cmp	ax, 1			; writing last element?
		jne	writeMask
		BitSet	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
writeMask:
		call	WriteOneScanLine

		call	HugeArrayNext		; ds:si = next element
		jmp	short	maskLoop
doneMask:
		call	HugeArrayUnlock		; unlock last element
	;
	;  Now write the image data.  Same thing as before, basically.
	;  No need to do the error-checking this time, as the bitmap
	;  hasn't changed.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString ByteString
	;
	;  Clear mask & last-element flags.
	;
		andnf	ss:WSFrame.WSF_flags, \
			not (mask WSF_WRITING_MASK or mask WSF_LAST_ELEMENT)
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		clr	dx, ax			; lock first element
		call	HugeArrayLock		; ds:si = element
imageLoop:
		tst	ax			; valid element?
		jz	doneImage
	;
	;  If we're writing the last element, set a flag so
	;  we know not to write the final comma.
	;
		cmp	ax, 1
		jne	writeImage
		BitSet	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
writeImage:
		call	WriteOneScanLine

		call	HugeArrayNext		; ds:si = next element
		jmp	short	imageLoop
doneImage:
		call	HugeArrayUnlock		; unlock last element
	;
	;  Return no error
	;
		clc
		mov	ax, WSE_NO_ERROR
done::
		.leave
		ret
WritePointerData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteOneScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes 1 scan line of the mask for the pointer image.

CALLED BY:	WritePointerData

PASS:		ss:[bp]	= inherited WriteSourceFrame

RETURN:		ax = WriteSourceErrors
		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	We'll assume that all pointer images now and forever will
	be multiples of 8 pixels wide, and write the scan lines in
	the form:

		00010110b, 11100100b,

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteOneScanLine	proc	near
		uses	bx,cx,dx,si,di,ds
		.enter	inherit	WritePointerData
	;
	;  Write a character for each pixel (byte) in the buffer.
	;  Every 8 pixels, we'll write a "b, ".  Since we're assuming
	;  the cursor will always be 16x16 (until 3.0, at least), we
	;  know that the mask for the scan line will be 2 bytes and
	;  we skip over it.
	;
		add	si, 2			; ds:si = bitmap data
		mov	di, ss:WSFrame.WSF_elemSize
		sub	di, 2			; subtract 2 bytes of mask data
		shl	di			; number of pixels
		clr	cx			; cx counts to end of string
pixelLoop:
	;
	;  Do the right thing depending on whether we're writing
	;  data bits or mask bits.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_MASK
		jnz	writingMask

		call	GetNextCharacterForImage; puts the chars in buffer
		jmp	short	writeBuffer
writingMask:
		call	GetNextCharacterForMask
writeBuffer:
		push	ds, si, cx		; pointer & counter
		segmov	ds, ss, si
		lea	si, ss:WSFrame.WSF_hexBuffer
		mov	cx, 2			; 2 characters to write
		call	IconWriteString
		pop	ds, si, cx		; pointer & counter

		inc	cx
		inc	cx			; we wrote 2 characters
	;
	;  If cx is not a multiple of 8, continue.
	;
		test	cx, 00000111b
		jnz	noBString
	;
	;  cx IS a multiple of 8 (either 8 or 16).  In either
	;  case, write "b, " unless cx = 16 AND it's the last
	;  element, in which case we skip the comma.
	;
		push	ds
		mov	ds, ss:WSFrame.WSF_stringSeg

		push	cx
		WriteString BString		; "b"
		pop	cx

		cmp	cx, 16
		jne	writeComma		; always write if not 16
	;
	;  cx is 16, so we check if we're on the last element, and
	;  if so, don't write the comma.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_LAST_ELEMENT
		jnz	doneTail
writeComma:
	;
	;  We're not on the last element, so write ", " after the "b".
	;
		push	cx			; save counter
		WriteString Comma
		WriteString Space
		pop	cx			; restore counter
doneTail:
		pop	ds			; restore data pointer
noBString:
		cmp	cx, di			; reached end yet?
		jb	pixelLoop
	;
	;  Write a carriage return/linefeed pair, and an extra tab.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString	CRLF
		WriteString	TabChar

		mov	ax, WSE_FILE_WRITE	; assume error
		jc	done

		mov	ax, WSE_NO_ERROR
done:
		.leave
		ret
WriteOneScanLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextCharacterForMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a byte from the bitmap and makes 2 characters from it.

CALLED BY:	WriteOneScanLine

PASS:		ss:bp	= inherited WriteSourceFrame
		ds:si	= pointer to byte to grab and convert

RETURN:		nothing (fills buffer with next 2 characters)

DESTROYED:	nothing (si updated to point to next byte)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

PSEUDO CODE/STRATEGY:

	write a "1" if the pixel is black or white (other colors => 0)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextCharacterForMask	proc	near
		uses	ax
		.enter	inherit	WriteOneScanLine
	;
	;  The following ToddCode(tm) is completely unintelligible.
	;
		lodsb				; al <- next bitmap byte
		mov	ah, 0f0h
		and	ah, al
		xor	al, ah			; al = second pixel color
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1			; ah = first pixel color
	;
	;  If black or white we write a "1" in the mask.
	;
		cmp	ah, C_BLACK
		je	write1AH
		cmp	ah, C_WHITE
		je	write1AH

		mov	{byte} ss:WSFrame.WSF_hexBuffer, "0"
		jmp	short  writeAL
write1AH:
		mov	{byte} ss:WSFrame.WSF_hexBuffer, "1"
writeAL:
		cmp	al, C_BLACK
		je	write1AL
		cmp	al, C_WHITE
		je	write1AL

		mov	{byte} ss:WSFrame.WSF_hexBuffer+1, "0"
		jmp	short  done
write1AL:
		mov	{byte} ss:WSFrame.WSF_hexBuffer+1, "1"
done:
		.leave
		ret
GetNextCharacterForMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextCharacterForImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a byte from the bitmap and makes 2 characters from it.

CALLED BY:	WriteOneScanLine

PASS:		ds:si	= byte to grab and convert
		ss:bp	= inherited WriteSourceFrame

RETURN:		nothing (fills buffer with next 2 characters)

DESTROYED:	nothing (si updated to point to next byte)

PSEUDO CODE/STRATEGY:

	write a "1" if the pixel is dark gray, or white.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/10/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextCharacterForImage	proc	near
		uses	ax
		.enter	inherit	WriteOneScanLine
	;
	;  The following code burst from Todd's head, like the
	;  birth of Athena.
	;
		lodsb				; al <- next bitmap byte
		mov	ah, 0f0h
		and	ah, al
		xor	al, ah			; al = second pixel color
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1			; ah = first pixel color
	;
	;  if black or white we write a "1" in the mask
	;
		cmp	ah, C_DARK_GRAY
		je	write1AH
		cmp	ah, C_WHITE
		je	write1AH

		mov	{byte} ss:WSFrame.WSF_hexBuffer, "0"
		jmp	short  writeAL
write1AH:
		mov	{byte} ss:WSFrame.WSF_hexBuffer, "1"
writeAL:
		cmp	al, C_DARK_GRAY
		je	write1AL
		cmp	al, C_WHITE
		je	write1AL

		mov	{byte} ss:WSFrame.WSF_hexBuffer+1, "0"
		jmp	short  done
write1AL:
		mov	{byte} ss:WSFrame.WSF_hexBuffer+1, "1"
done:
		.leave
		ret
GetNextCharacterForImage	endp


SourceCode	ends
