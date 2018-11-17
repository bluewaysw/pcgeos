COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Source
FILE:		sourceUtils.asm

AUTHOR:		Steve Yegge, Jun 10, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/10/94		Initial revision

DESCRIPTION:

	Low-level routines for writing strings to text file.	

	$Id: sourceUtils.asm,v 1.1 97/04/04 16:06:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SourceCode	segment	resource

;
; translation table for hex->ascii conversion
;
	hexTable	char	"0123456789abcdef"


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconWriteNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write ASCII representation of a number to output buffer,
		flushing buffer to disk if full.  Converts number to text.

CALLED BY:	UTILITY

PASS:		ss:bp	= inherited WriteSourceFrame
		dx:ax	= dword number to write

RETURN:		carry set if write failed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- convert number to a string
	- call WriteString

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 3/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconWriteNumber	proc	far
		uses	ax, cx, si, di, ds, es
		.enter	inherit	DBViewerWriteSource
	;
	;  Convert the number to text.
	;
		sub	sp, UHTA_NO_NULL_TERM_BUFFER_SIZE
		segmov	es, ss, di
		mov	di, sp				; es:di = dest buffer
		clr	cx				; UtilHex32ToAsciiFlags
		call	UtilHex32ToAscii		; cx = string length
	;
	;  Call WriteString to handle writing (and maybe
	;  flushing) the output buffer.
	;
		segmov	ds, es, si
		mov	si, di				; ds:si = number string
		call	IconWriteString
	;
	;  Restore the stack.
	;
		lahf					; preserve carry
		add	sp, UHTA_NO_NULL_TERM_BUFFER_SIZE
		sahf					; restore carry
		
		.leave
		ret
IconWriteNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteHexNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert hex number to its ASCII equivalent & write it.

CALLED BY:	WriteElement

PASS:		al = byte to convert to ASCII hex format

RETURN:		carry set if write failed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Each byte of the bitmap becomes 2 characters when translated
	into ascii.  ax holds the two characters after translation.

		- start with byte in al
		- copy al into ah
		- shr ah by 4; now ah has first character
		- mask out 4 high bits of al...now al has second character
		- translate al with xlat
		- exchange al and ah
		- translate table again

	now ax has the number, with the characters reversed.  ax
	is then stored into the output buffer for writing to file.
	since the al is first written, then ah (mov does this), the
	characters in the buffer will be in the right order.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/10/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteHexNumber	proc	near
		uses	ax, bx, cx, si, ds
		.enter	inherit	WriteElement
	;
	;  Store the characters in WSF_hexBuffer.
	;
		mov	ah, al
		shr	ah
		shr	ah
		shr	ah
		shr	ah			; ah <- first char
		andnf	al, 00001111b		; al <- second char

		mov	bx, offset hexTable
		xlat	cs:[hexTable]		; convert first char
		xchg	ah, al
		xlat	cs:[hexTable]		; convert second char
		mov	{word} ss:WSFrame.WSF_hexBuffer, ax	
						; reverses order of chars in ax
	;
	;  Write the characters out.
	;
		segmov	ds, ss, si
		lea	si, ss:WSFrame.WSF_hexBuffer
		mov	cx, 2			; 2 characters to write
		call	IconWriteString
		
		.leave
		ret
WriteHexNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconWriteString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a string to the buffer, flushing if buffer is full.

CALLED BY:	UTILITY

PASS:		ss:bp	= inherited stack frame (WriteSourceFrame)
		ds:si	= string to write (dereferenced)
		cx	= size of string to write, in bytes
		
RETURN:		carry set if write failed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- see if there's enough room in the output buffer to add
	  the string.  If not, flush buffer to disk and reset pointer
	  into output buffer to zero.
	- write the string to the buffer starting at the current
	  buffer position

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 3/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconWriteString	proc	far
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter	inherit	DBViewerWriteSource
	;
	;  See if we have enough room in the buffer to write the
	;  string; if not, flush the buffer to disk.
	;
		mov	dx, SOURCE_CACHE_BUFFER_SIZE	; dx = end of buffer
		sub	dx, ss:WSFrame.WSF_outBufPtr	; dx = space left
		cmp	cx, dx
		jb	writeOK				; there's enough room
	;
	;  There's not enough room...flush to disk.
	;
		call	FlushOutputBuffer		; nothing destroyed
		jc	done
writeOK:
	;
	;  Copy the string to the output buffer and update the
	;  current buffer position.
	;
		mov	es, ss:WSFrame.WSF_outBufSeg	; es = output buffer
		mov	di, ss:WSFrame.WSF_outBufPtr	; es:di = destination
		rep	movsb				; updates di
		mov	ss:WSFrame.WSF_outBufPtr, di	; current position
		clc					; success
done:
		.leave
		ret
IconWriteString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlushOutputBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write contents of output buffer to disk & reset outBufPtr

CALLED BY:	UTILITY

PASS:		ss:[bp]	= WriteSourceFrame

RETURN:		carry set if write failed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- write the buffer contents to disk.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 3/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlushOutputBuffer	proc	near
		uses	ax,bx,cx,dx,ds
		.enter	inherit	DBViewerWriteSource
	;
	;  Write the contents of the buffer to disk.
	;
		mov	ds, ss:WSFrame.WSF_outBufSeg	; ds = output buffer
		clr	dx, ax				; ds:dx = source data
		mov	cx, ss:WSFrame.WSF_outBufPtr	; cx = #bytes to write
		mov	bx, ss:WSFrame.WSF_fileHandle	; output file handle
		call	FileWrite
		jc	done
	;
	;  Reset current buffer position to zero.
	;
		clr	ss:WSFrame.WSF_outBufPtr	; reset to zero
done:
		.leave
		ret
FlushOutputBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChunkStringSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size of string statically declared in a chunk

CALLED BY:	UTILITY

PASS:		*ds:si = string

RETURN:		cx	= size of string (excluding NULL character)
		ds:si	= fptr to string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SA	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChunkStringSize	proc	far
		.enter

		mov	si, ds:[si]		; dssi <- fptr to string
		ChunkSizePtr	ds, si, cx	; cx <- size of string declared
		dec	cx			; ds:[si+cx] <- last char
	;
	; Check to make sure that all strings are terminated with NULL
	; (zero) character
	;
EC <		push	si						>
EC <		add	si, cx			; dssi<-last char	>
EC <		cmp	{byte} ds:[si], 0	; should be NULL(zero)	>
EC <		ERROR_NZ INVALID_SOURCE_STRING				>
EC <		pop	si						>

		.leave
		ret
GetChunkStringSize		endp

SourceCode	ends
