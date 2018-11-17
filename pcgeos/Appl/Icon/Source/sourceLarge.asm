COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Source
FILE:		sourceLarge.asm

AUTHOR:		Steve Yegge, Apr 21, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT WriteLargeBitmap        Write out source code for bitmap in
				multiple resources.

    INT WriteResourceStart      Write "start BitmapData<N>, data", etc.

    INT WriteResourceEnd        Write out the bitmap tail and resource-end
				string.

    INT WriteSwathHeader        Write out the "16, 8, BMC_UNCOMPACTED,
				etc." stuff

    INT WriteSwathData          Write out the bits of the scanlines in this
				swath.

    INT WriteGString            Write the gstring that draws the slices.

    INT WriteGStringSlice       Write out one element of the gstring.

    INT InitStackFrameLarge     Initialize any stack-frame variables that
				aren't normally initialized for writing
				source code.

    INT GetScanLineSizeInBytes  Get size of one scanline of the bitmap, in
				bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/21/95		Initial revision

DESCRIPTION:

	Code for writing large bitmaps.

	$Id: sourceLarge.asm,v 1.1 97/04/04 16:06:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LargeSourceCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteLargeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out source code for bitmap in multiple resources.

CALLED BY:	WriteBitmapSourceLow

PASS:		ss:bp	= inherited WSFrame
		*ds:si	= DBViewer object

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- figure out how many bytes per scanline
 	- integer divide desired resource size by bytes/scanline
	- store result in WSF_linesPerSwath

	- figure out how many scan lines in hugearray
	- divide total scanlines by WSF_sliceSize (lines per swath)
	- if doesn't divide evenly, add 1 to result
	- store result in WSF_numSwaths

	- call WriteSwaths to write out bitmap chunks

	- call WriteGString to write out gstring definition

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteLargeBitmap	proc	far
		uses	ax,bx,cx,dx,si,di
		.enter	inherit	WriteBitmapSourceLow
	;
	;  Set up any new stack variables for writing large bitmap.
	;
		call	InitStackFrameLarge
	;
	;  Figure out how many bytes per scanline, and divide the
	;  desired resource size by that number, to get the total
	;  scanlines that will be written per slice.
	;
		call	GetScanLineSizeInBytes		; dx = size
		mov	ss:WSFrame.WSF_elemSize, dx	; save this for later
		mov_tr	cx, dx				; won't be 0
		clr	dx
		mov	ax, ss:WSFrame.WSF_resSize	; dx:ax = divisor
		div	cx				; ax = #scanlines
		mov	ss:WSFrame.WSF_sliceSize, ax	; save it
		mov_tr	cx, ax				; keep in cx for now
	;
	;  - figure out how many scan lines in hugearray
	;  - divide total scanlines by WSF_sliceSize (lines per swath)
	;  Note:  if #scanlines < cx, don't divide.  All the scanlines
	;  will fit in one swath.  Set numSwaths to 1 and lastSwath to
	;  the total scanlines.
	;
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		call	HugeArrayGetCount		; dx:ax = #elements

		tst	dx				; >64k scanlines
		jnz	divide

		cmp	ax, cx
		ja	divide
	;
	;  One swath will suffice -- special case it.
	;
		mov	ss:WSFrame.WSF_lastSwath, ax
		mov	ax, 1				; 1 swath is enough
		jmp	gotNumSwaths
divide:
		div	cx				; ax = numSwaths
	;
	;  If there was a remainder (in dx), add 1 to the number of
	;  swaths required.  The remainder, if any, is the number of
	;  scanlines in the last swath, so store that too.
	;
		clr	ss:WSFrame.WSF_lastSwath	; assume nonexistent
		tst	dx
		jz	gotNumSwaths

		inc	ax				; ax = #swaths
		mov	ss:WSFrame.WSF_lastSwath, dx	; save for later
gotNumSwaths:
		mov	ss:WSFrame.WSF_numSwaths, ax	; save it
	;
	;  Write out the swaths.
	;
		clr	cx			; swath number
		clrdw	dxax			; current scanline
swathLoop:
		call	WriteResourceStart
		call	WriteSwathHeader

		call	WriteSwathData

		add	ax, ss:WSFrame.WSF_sliceSize
		adc	dx, 0			; dxax = dxax + slice size

		call	WriteResourceEnd
		inc	cx
		cmp	cx, ss:WSFrame.WSF_numSwaths
		jb	swathLoop
	;
	;  Write out the gstring that draws each of the swaths.
	;
		call	WriteGString

		.leave
		ret
WriteLargeBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteResourceStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write "start BitmapData<N>, data", etc.

CALLED BY:	WriteLargeBitmap

PASS:		cx = current swath

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteResourceStart	proc	near
		uses	ax,bx,cx,dx,ds
		.enter	inherit	WriteLargeBitmap
	;
	;  Set up to start writing strings, and write the first one.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		push	cx
		push	cx
		WriteString	ResStartString
	;
	;  Write the number of the resource we're on.
	;
		clr	dx
		pop	ax
		call	IconWriteNumber
	;
	;  Write the end of the start-resource string.
	;
		WriteString	ResStartEndString
	;
	;  Write the bitmap start string, followed by the swath
	;  number again, and then the end of the bitmap-start string.
	;
		WriteString	BitmapStartString
		pop	ax
		call	IconWriteNumber			; still in dx:ax
		WriteString	BitmapStartEndString

		.leave
		ret
WriteResourceStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteResourceEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the bitmap tail and resource-end string.

CALLED BY:	WriteLargeBitmap

PASS:		cx = current swath

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteResourceEnd	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit	WriteLargeBitmap
	;
	;  Set up to write strings and write Bitmap trailer.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		mov_tr	ax, cx				; ax = cur. swath
		WriteString	BitmapEndString
	;
	;  Write out the current resource number.
	;
		clr	dx
		call	IconWriteNumber
	;
	;  Write the resource trailer. -- none to write, according
	;  to Don.
	;
		WriteString	CRLF
		WriteString	RawCRLF

		.leave
		ret
WriteResourceEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSwathHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the "16, 8, BMC_UNCOMPACTED, etc." stuff

CALLED BY:	WriteLargeBitmap

PASS:		ss:bp	= inherited WriteSourceFrame

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSwathHeader	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit	WriteLargeBitmap
	;
	;  Write out the element size.
	;
		movdw	cxdx, ss:WSFrame.WSF_bitmap

		call	HugeBitmapGetFormatAndDimensions	; cx = width
		mov_tr	ax, cx

		clr	dx			; dx.ax = dword to convert
		call	IconWriteNumber

		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString	Comma
		WriteString	Space
		jc	done
	;
	;  Write out the swath size.  If we're on the last slice,
	;  it's a special number.  cx is still the current swat.
	;
		mov	ax, ss:WSFrame.WSF_sliceSize
		cmp	cx, ss:WSFrame.WSF_numSwaths
		jne	writeIt
		mov	ax, ss:WSFrame.WSF_lastSwath
writeIt:
		call	IconWriteNumber

		WriteString	Comma
		WriteString	Space
		jc	done
	;
	;  Write the BMC_UNCOMPACTED string, or BMC_PACKBITS,
	;
		mov	si, offset PackString
		cmp	ss:WSFrame.WSF_compact, WSCT_COMPACTED
		je	writeCompact
		mov	si, offset UnPackString
writeCompact:
	;
	;  Write the appropriate string.
	;
		call	GetChunkStringSize
		call	IconWriteString
		WriteString	OrSymbol
		WriteString	OpenParen
		WriteString	OpenParen
	;
	;  Write mask if necessary.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_MASK
		jz	doneMask

		WriteString	BMMaskString
	;
	;  Write " | ".
	;
		WriteString	OrSymbol
doneMask:
	;
	;  Choose the appropriate color string.
	;
		movdw	cxdx, ss:WSFrame.WSF_bitmap
		call	HugeBitmapGetFormatAndDimensions	; al = format

		mov	si, offset Bit4String
		cmp	al, BMF_4BIT shl offset BMT_FORMAT
		je	writeColor
		mov	si, offset MonoString
writeColor:
		call	GetChunkStringSize
		call	IconWriteString
	;
	;  Write the closing angle bracket/close paren.
	;
		WriteString	ShiftLeftEightString
	;
	;  Write a CRLF in any case.
	;
		WriteString	CRLF
done:
		.leave
		ret
WriteSwathHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSwathData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the bits of the scanlines in this swath.

CALLED BY:	WriteLargeBitmap

PASS:		ss:bp	= inherited stack frame
		dx:ax	= scanline that this swath starts on

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- loops through WSF_sliceSize scanlines starting
	  at passed scanline and writes data.

	  NOTE:  *should* be able to create a routine almost
		 exactly like WriteBitmap(), except that it
		 checks to see if we're at WSF_sliceSize
		 instead of testing ds:[HAB_next].  It should
		 call WriteElement to do all the low-level
	 	 writing.		

	- MAYBE need to delete last comma that was written.
	  If cache hasn't flushed, just back up ptr.  If
	  cache is empty (a fluke), need to back up file ptr.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSwathData	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit	WriteLargeBitmap
	;
	;  Clear the last-element flag.
	;
		BitClr	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
	;
	;  Get the first huge array element, and save the size.
	;
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		call	HugeArrayLock		; dx = element size
		mov	ss:WSFrame.WSF_elemSize, dx
		movdw	ss:WSFrame.WSF_element, dssi

		clr	cx			; loop counter
elementLoop:
	;
	; If no more elements, we're outta here.
	;
		tst	ax
		jz	done
	;
	;  Write the bytes of this element to the output file.
	;
		cmp	cx, ss:WSFrame.WSF_sliceSize
		jae	done			; we're outta here

		cmp	ax, 1			; writing last element?
		jne	writeIt

		tst	ds:[HAB_next]		; last block?
		jnz	writeIt

		BitSet	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
writeIt:
		call	WriteElement		; carry set if write failed
		jc	done			
	;
	;  HugeArrayNext returns dx = size for variable-sized bitmaps
	;  (in our case, compacted bitmaps).  Otherwise dx is undefined.
	;  If we're writing a compacted bitmap, update the size field
	;  of our local variable frame.  If not, don't mess with it.
	;
		inc	cx			; loop counter
		lds	si, ss:WSFrame.WSF_element
		call	HugeArrayNext		; ds:si = next element
		movdw	ss:WSFrame.WSF_element, dssi

		cmp	ss:WSFrame.WSF_compact, WSCT_COMPACTED
		jne	elementLoop

		mov	ss:WSFrame.WSF_elemSize, dx
		jmp	elementLoop
done:
	;
	;  Unlock the last element.
	;
		call	HugeArrayUnlock		; pass ds = sptr to last element
	;
	;  Yep, we need to delete the comma and some other stuff.
	;  You're going to hate me for this, but I'm not going
	;  to back up the file pointer as I should, until this
	;  actually happens to someone.  Instead I'll FatalError.
	;  With the default desired resource size, this is a 1/1000
	;  possibility, and only for bitmaps that are large than 5k.
	;
if 0
EC <		cmp	ss:WSFrame.WSF_outBufPtr, 5			>
EC <		ERROR_BE -1						>
		dec	ss:WSFrame.WSF_outBufPtr
		dec	ss:WSFrame.WSF_outBufPtr
		dec	ss:WSFrame.WSF_outBufPtr
		dec	ss:WSFrame.WSF_outBufPtr
		dec	ss:WSFrame.WSF_outBufPtr
endif
		.leave
		ret
WriteSwathData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the gstring that draws the slices.

CALLED BY:	WriteLargeBitmap

PASS:		ss:bp	= inherited stack frame

RETURN:		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	loop:

	  * keep counter for y-offset, incrementing by linesPerSwath
		each time

	  * keep counter for current swath (N), writing "<At>BitmapN"
		each time, up to max swaths
		
	  * write gstring element with arguments computed above

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteGString	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit	WriteLargeBitmap
	;
	;  Write the starter stuff.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString	GStringStartString
	;
	;  Write the middle stuff.
	;
		mov	dx, ss:WSFrame.WSF_yOffset	; starting offset
		clr	cx				; current swath
sliceLoop:
		call	WriteGStringSlice

		add	dx, ss:WSFrame.WSF_sliceSize	; next y-offset
		inc	cx
		cmp	cx, ss:WSFrame.WSF_numSwaths
		jb	sliceLoop
	;
	;  Write the trailer stuff.
	;
		WriteString	GStringTrailerString

		.leave
		ret
WriteGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteGStringSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out one element of the gstring.

CALLED BY:	WriteGString

PASS:		ss:bp	= inherited WSFrame
		ds	= stringSeg
		dx	= y offset at which to draw bitmap
		cx	= current swath

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteGStringSlice	proc	near
		uses	ax, cx, dx
		.enter	inherit	WriteLargeBitmap
	;
	;  Write the start string for the element.
	;
		push	cx
		WriteString	SliceStartString
	;
	;  Write the x-offset.
	;
		push	dx
		clr	dx
		mov	ax, ss:WSFrame.WSF_xOffset
		call	IconWriteNumber

		WriteString	Comma
		WriteString	Space
	;
	;  Write the y-offset.
	;
		pop	ax
		call	IconWriteNumber
		
		WriteString	Comma
		WriteString	Space
	;
	;  Write the @Bitmap<whatever> string.
	;
		WriteString	SliceBitmapString
		pop	ax
		call	IconWriteNumber
		WriteString	Space
	;
	;  Write the trailer.
	;
		WriteString	SliceTrailerString

		.leave
		ret
WriteGStringSlice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitStackFrameLarge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize any stack-frame variables that aren't
		normally initialized for writing source code.

CALLED BY:	GetBitmapAndWriteLarge

PASS:		ss:bp = stack frame
		*ds:si = DBViewer object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitStackFrameLarge	proc	near
		uses	ax,bx,cx,dx,si,di
		class	DBViewerClass
		.enter	inherit	WriteLargeBitmap
	;
	;  Get base resource size.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset

		push	bp
		mov	bx, ds:[di].GDI_display
		mov	si, offset ResourceSizeValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage			; dx = #kbytes
		pop	bp

	;
	;  Shift left by 10 (i.e. multiply by 1024) to get #bytes.
	;	
EC <		cmp	dx, MAX_RESOURCE_SIZE_IN_KBYTES			>
EC <		ERROR_A	SELECTED_TOO_LARGE_A_RESOURCE_SIZE		>

		mov_tr	ax, dx
		clr	dx				; dx:ax = kbytes
		mov	cx, 10
shiftLoop:
		shldw	dxax
		loop	shiftLoop

		mov	ss:WSFrame.WSF_resSize, ax
	;
	;  See what the desired X & Y offsets are.
	;
		push	bp
		mov	si, offset XOffsetValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage			; dx = integer value
		pop	bp

		mov	ss:WSFrame.WSF_xOffset, dx
	;
	;  Get desired Y offset.
	;
		push	bp
		mov	si, offset YOffsetValue
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjMessage			; dx = integer value
		pop	bp

		mov	ss:WSFrame.WSF_yOffset, dx

		.leave
		ret
InitStackFrameLarge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScanLineSizeInBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get size of one scanline of the bitmap, in bytes.

CALLED BY:	UTILITY

PASS:		ss:bp	= inherited stack frame

RETURN:		dx	= size in bytes

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if bitmap is compacted, create an uncompacted version first
	- lock the first element to get size
	- clean up

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScanLineSizeInBytes	proc	near
		uses	ax,bx,cx,si,di,ds
		.enter	inherit	WriteLargeBitmap

		BitClr	ss:WSFrame.WSF_flags, WSF_UNCOMPACTED_BITMAP
	;
	;  If the bitmap is compacted, uncompact a copy of it in
	;  the clipboard file.
	;
		movdw	bxax, ss:WSFrame.WSF_bitmap
		call	CheckHugeArrayBitmapCompaction
		jz	noCompact
	;
	;  Uncompact it.
	;
		mov	dx, bx				; dx:ax = bitmap
		call	ClipboardGetClipboardFile
		xchg	dx, bx				; bx:ax = bitmap
		call	GrUncompactBitmap		; dx:cx = new bitmap
		movdw	bxax, dxcx

		BitSet	ss:WSFrame.WSF_flags, WSF_UNCOMPACTED_BITMAP
noCompact:
	;
	;  Lock the first element to get element size, and then
	;  immediately unlock it.
	;
		mov	di, ax				; bx:di = bitmap
		clr	dx, ax
		call	HugeArrayLock			; dx = size

EC <		tst	ax						>
EC <		ERROR_Z	NO_SCANLINES_IN_BITMAP				>

EC <		tst	dx						>
EC <		ERROR_Z	CORRUPTED_BITMAP				>

		call	HugeArrayUnlock
	;
	;  Free the compacted bitmap if any.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_UNCOMPACTED_BITMAP
		jz	done

		push	bp				; locals
		mov	ax, di				; bx:ax = bitmap
		clr	bp				; no DB items
		call	VMFreeVMChain
		pop	bp
done:
		.leave
		ret
GetScanLineSizeInBytes	endp


LargeSourceCode	ends
