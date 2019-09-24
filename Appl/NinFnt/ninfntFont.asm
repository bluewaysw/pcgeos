COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfntFont.asm

AUTHOR:		Gene Anderson, Apr 18, 1991

ROUTINES:
	Name			Description
	----			-----------
	LockNimbusHeader	Lock Nimbus font header.
	UnlockNimbusHeader	Unlock Nimbus font header.
	ConvertFontHeader	Scan Nimbus font to build PC/GEOS values
				and write result to disk.
	CountGEOSChars		Scan Nimbus font to count number of usable
				characters.
	WriteHalfData		Write character data for half of font.

	ScanBaseline		Calculate baseline, etc. from font header.
	WriteFontHeader		Flush NewFontHeader to disk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/18/91		Initial revision
	JDM	91.05.13	Added conversion status updating.

DESCRIPTION:
	Routines for reading and writing Nimbus font headers and data.

	$Id: ninfntFont.asm,v 1.1 97/04/04 16:16:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockNimbusHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure Nimbus font header is loaded.
CALLED BY:	ReadNimbusChar(), CopyFontHeader()

PASS:		bx - file handle
		cx - block handle (0 if unknown)
RETURN:		cx - block handle
		ax - seg addr of block
		carry - set if error
			ax - NimbusError
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockNimbusHeader	proc	near
	uses	bx, dx, di, si, ds
	.enter

	tst	cx				;handle passed?
	jnz	justLock			;branch if handle passed
	;
	; Allocate a block to hold the header
	;
	mov	di, bx				;di <- file handle
	mov	ax, (size DTCFontHeader)	;ax <- size of block
	mov	cx, ALLOC_DYNAMIC_LOCK		;cx <- HeapFlags, HeapAllocFlags
	call	MemAlloc
	jc	memoryError			;branch if error
	;
	; Read in the Nimbus header
	;
	xchg	di, bx				;bx <- file handle
	mov	ds, ax
	clr	dx				;ds:dx <- ptr to buffer
	mov	cx, (size DTCFontHeader)	;cx <- # of bytes to read
	clr	al				;al <- file flags
	call	FileRead
	jc	readError			;branch if error
	;
	; Figure out how many characters there are, and hence how
	; many character IDs and offsets there are.  Resize the
	; block to make space for the IDs and offsets.
	; NOTE: space for one additional offset is allocated so that:
	;	offset[n+1] = offset[n]+size[n]
	; This allows consistenly calculating the size of char data.
	;
	mov	ax, ds:DTCFH_numChars		;ax <- # of characters
	shl	ax, 1				;ax <- #*2 (each ID)
	mov	dx, ax
	shl	dx, 1				;dx <- #*4 (each offset)
	add	ax, dx				;ax <- (# of chars) * 6
	mov	dx, ax				;dx <- additional space
	add	ax, (size dword)		;ax <- space for extra offset
	add	ax, cx				;ax <- new size of block
	clr	ch				;ch <- HeapAllocFlags
	xchg	bx, di				;bx <- block handle
	call	MemReAlloc
	jc	memoryError			;branch if error
	;
	; Read in the character IDs table and the offsets table.
	;
	mov	ds, ax				;ds <- (new) seg addr of block
	mov	cx, dx				;cx <- additional bytes
	mov	dx, (size DTCFontHeader)	;ds:dx <- ptr to buffer
	xchg	bx, di				;bx <- file handle
	clr	al				;al <- file flags
	call	FileRead
	jc	readError			;branch if error
	;
	; Find the file size to store as the extra offset.
	;
	push	cx
	mov	al, FILE_SEEK_END		;al <- FileSeekModes
	clr	cx
	clr	dx				;cx:dx <- offset from end
	call	FilePos				;seek me jesus
	pop	si				;si <- # of bytes in tables
	add	si, (size DTCFontHeader)	;ds:si <- ptr to extra offset
	mov	ds:[si].low, ax
	mov	ds:[si].high, dx
	mov	cx, di				;cx <- block handle
	mov	ax, ds				;ax <- seg addr of block
	clc					;carry <- no error

done:
	.leave
	ret

justLock:
	mov	bx, cx				;bx <- handle of header block
	call	MemLock
	jnc	done				;branch if no error
memoryError:
	mov	ax, NE_MEM_ALLOC		;ax <- error from Mem routine
	jmp	done				;carry set

readError:
	mov	ax, NE_FILE_READ		;ax <- error from FileRead()
	jmp	done				;carry set
LockNimbusHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockNimbusHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the Nimbus font header
CALLED BY:	ReadNimbusChar(), CopyFontHeader()

PASS:		cx - block handle
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlockNimbusHeader	proc	near
	uses	bx
	.enter

	mov	bx, cx				;bx <- handle of header block
	call	MemUnlock

	.leave
	ret
UnlockNimbusHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertFontHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a Nimbus font for necessary calculated values
		and write to disk.
CALLED BY:	ConvertOneNimbusFont()

PASS:		bx - source file handle
		dx - dest file handle
		cx - block handle of DTC header (0 if not loaded)
RETURN:		ax - size of PC/GEOS NewFontHeader block
		cx - block handle of DTC header
		carry - set if error
			ax - NimbusError
		di.low - first PC/GEOS character in font
		di.high - last PC/GEOS character in font
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(size NewWidth) eq 3>
CheckHack	<(size CharConvertEntry) eq 4>

ConvertFontHeader	proc	near
	uses	bx, dx, ds, es, si

locals	local	ScanLocals

	.enter

	mov	ss:locals.SL_sourceFileHandle, bx
	mov	ss:locals.SL_destFileHandle, dx
	call	LockNimbusHeader		;ax <- seg addr of of header
	LONG jc	done				;branch if error
	mov	ss:locals.SL_headerHandle, cx	;saver header handle
	;
	; Allocate a block big enough for the table of character widths
	; and flags, and the font header.  This constitutes the outline
	; header section for the font that font metrics are built from.
	;
	mov	di, bx				;di <- file handle
	mov	ds, ax				;ds <- seg addr of header
	call	CountGEOSChars			;figure out how many characters
	LONG jc	done				;branch if error
	mov	{word}ss:locals.SL_firstChar, dx
	push	ax
	mov	cx, ax				;cx <- # of characters
	shl	ax, 1				;ax <- #*2
	add	ax, cx				;ax <- #*3
	add	ax, (size NewFontHeader)	;ax <- size of outline header
	mov	ss:locals.SL_destBlockSize, ax	;save block size
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	pop	cx				;cx <- # of chars
	LONG jc	memoryError			;branch if error
	mov	ss:locals.SL_destBlockHandle, bx ;save block handle
	mov	es, ax				;es <- seg addr of block
	;
	; Copy the stuff that is verbatim from the Nimbus file,
	; already calculated, or just a constant.
	;
	mov	es:NFH_numChars, cx		;store # chars
	mov	es:NFH_firstChar, dl		;store first char
	mov	es:NFH_lastChar, dh		;store last character
	mov	es:NFH_defaultChar, DEFAULT_DEFAULT_CHAR
	mov	es:NFH_continuitySize, DEFAULT_CONTINUITY_CUTOFF
	mov	ax, ds:DTCFH_h_height
	mov	es:NFH_h_height, ax		;store h height
	mov	ax, ds:DTCFH_x_height
	mov	es:NFH_x_height, ax		;store x height
	mov	ax, ds:DTCFH_ascender
	mov	es:NFH_ascent, ax		;store ascent
	mov	ax, ds:DTCFH_descender
	mov	es:NFH_descent, ax		;store descent
	;
	; Cycle through the characters, calculating
	; various minimums, maximums, etc.
	;
	clr	ax
	mov	ss:locals.SL_weightTotal, ax
	mov	ss:locals.SL_weightAvg.low, ax
	mov	ss:locals.SL_weightAvg.high, ax
	mov	es:NFH_minLSB, 9999
	mov	es:NFH_maxBSB, -9999
	mov	es:NFH_minTSB, -9999
	mov	es:NFH_maxRSB, -9999
	mov	si, dx				;si <- first character
	andnf	si, 0x00ff
	sub	si, ' '
	shl	si, 1
	shl	si, 1				;si <- *4 for each entry
	mov	di, (size NewFontHeader)	;es:di <- ptr to NewWidth
	mov	cx, ss:locals.SL_headerHandle	;cx <- handle of header block
charLoop:
	DoPush	ds, si
	mov	ss:locals.SL_actualChar, dl
tryUppercase:
	mov	bx, ss:locals.SL_sourceFileHandle ;bx <- source file handle
	mov	ax, cs:urwToGeos[si].CCE_urwID	;ax <- URW ID
	call	ReadNimbusChar
	jc	doneFree			;branch if error
	tst	ax				;any character loaded?
	jnz	afterCharMissing		;branch if loaded
	push	dx
	mov	dl, ss:locals.SL_actualChar
	call	DoUpcaseChar			;ax <- uppercase URW ID
	mov	ss:locals.SL_actualChar, al
	pop	dx
	jnc	tryUppercase			;branch if char upcased
afterCharMissing:
	call	ScanNimbusChar
	DoPopRV	ds, si				;ds <- seg addr of header
	add	si, (size CharConvertEntry)	;cs:si <- next source
	add	di, (size NewWidth)		;es:di <- next dest
	cmp	dl, dh				;last character?
	je	endLoop				;branch if done
	inc	dl				;dl <- next character
	jmp	charLoop

endLoop:
	;
	; Finish calculating results
	;
	call	ScanNonBrkSpace
	call	ScanDefaultChar
	call	ScanAverageWidth
	call	ScanBaseline

	mov	bx, ss:locals.SL_destBlockHandle ;bx <- handle of font block
	mov	ax, ss:locals.SL_destBlockSize	;ax <- size of font block
	mov	dx, ss:locals.SL_destFileHandle	;dx <- dest file handle
	;
	; Now write the NewFontHeader block and free it
	;
	call	WriteFontHeader
	jc	done				;branch if error
	mov	di, {word}ss:locals.SL_firstChar
done:
	mov	cx, ss:locals.SL_headerHandle	;cx <- handle of header block
	call	UnlockNimbusHeader

	.leave
	ret

doneFree:
	DoPopRV	ds, si
	mov	bx, ss:locals.SL_destBlockHandle ;bx <- handle of font block
	call	MemFree
	stc					;carry <- error
	jmp	done

memoryError:
	mov	ax, NE_MEM_ALLOC		;ax <- error from Mem routine
	jmp	done				;carry set

ConvertFontHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountGEOSChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the number of GEOS characters in Nimbus file
CALLED BY:	CopyFontHeader()

PASS:		ds - seg addr of Nimbus header & char IDs table
RETURN:		ax - # of characters
		dl - first PC/GEOS character found (Chars)
		dh - last PC/GEOS character found (Chars)
		carry - set if error
			ax - NimbusError
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CountGEOSChars	proc	near
	uses	bx, cx, si, di
	.enter

	mov	cx, ds:DTCFH_numChars		;cx <- # of characters
	mov	si, (size DTCFontHeader)	;ds:si <- ptr to char IDs
	mov	dx, 255				;dl <- min, dh <- max
charLoop:
	mov	ax, ds:[si]			;ax <- URW character ID
	call	MapURWToGEOS			;map me jesus
	jc	nextChar			;branch if not PC/GEOS char
	cmp	al, dl				;new minimum?
	ja	notMin
	mov	dl, al				;dl <- new minimum
notMin:
	cmp	al, dh				;new maximum?
	jb	notMax
	mov	dh, al				;dh <- new maximum
notMax:

nextChar:
	add	si, (size word)			;ds:si <- ptr to next char
	loop	charLoop			;loop while more characters

	clr	ah
	mov	al, dh				;al <- last character
	sub	al, dl				;al <- (last - first)
	jc	noChars				;branch if borrow (dl > dh)
	inc	al				;al <- (last - first) + 1
	clc					;carry <- no error
done:
	.leave
	ret

noChars:
	mov	ax, NE_NO_CHARS			;ax <- no characters found
	jmp	done				;carry set
CountGEOSChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanBaseline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate baseline, accent, etc. for NewFontHeader
CALLED BY:	CopyFontHeader()

PASS:		ds - seg addr of DTCFontHeader
		es - seg addr of NewFontHeader
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanBaseline	proc	near
	.enter

	;
	; Make sure accent is reasonable, and calculate the actual
	; accent height.
	;
	mov	ax, es:NFH_accent		;ax <- accent height
	cmp	ax, 0
	jle	smallAccent
	mov	bx, ax				;bx <- scanned accent value
	sub	ax, es:NFH_ascent		;ax <- accent - ascent
	mov	es:NFH_accent, ax		;store accent height
afterAccent:
	mov	dx, bx
	;
	; Calculate the adjusted baseline offset
	;	bx, dx = MAX(scanned accent,scanned ascent)
	;
	mov	ax, NIMBUS_BASELINE
	sub	ax, dx
	mov	es:NFH_baseAdjust, ax		;store adjusted baseline
	;
	; Calculate the height
	;
	mov	ax, es:NFH_maxBSB
	add	ax, dx				;ax <- baseline + max BSB
	mov	es:NFH_height, ax		;store height
	;
	; Play around with the bounds until they're in
	; the format we want.
	;
	sub	es:NFH_minTSB, NIMBUS_BASELINE
	sub	es:NFH_maxBSB, (NIMBUS_DESCENT - NIMBUS_SAFETY)
	;
	; Deal with the underline position and thickness
	; NOTE: the position is supposed to be negative.
	; If it is not, it is missing or bogus.
	;
	mov	ax, ds:DTCFH_underPos		;ax <- suggested underline pos
	cmp	ax, 0
	jl	underPosOK
	mov	ax, NIMBUS_DEFAULT_UNDER_POSITION
underPosOK:
	sub	dx, ax				;dx <- baseline offset - pos
	mov	es:NFH_underPos, dx		;store underline offset

	mov	ax, ds:DTCFH_underThick		;ax <- underline thickness
	cmp	ax, 0
	jg	underThickOK
	mov	ax, NIMBUS_DEFAULT_UNDER_THICK
underThickOK:
	mov	es:NFH_underThick, ax		;store underline thickness
	;
	; Finally (?), deal with the strikethrough position.
	; It is 3/5ths the x-height.  For all-CAPs things,
	; use the ascent instead.
	;
	mov	ax, ds:DTCFH_x_height		;ax <- x-height
	cmp	ax, 0
	jg	meanOK
	mov	ax, es:NFH_ascent		;ax <- ascent
meanOK:
	mov	ax, dx
	shl	ax, 1				;ax <- *2
	add	ax, dx				;ax <- *3
	clr	dx
	mov	cx, 5
	div	cx				;ax <- 3/5 * x-height
	sub	bx, ax				;bx <- baseline - (3/5*x-height)
	mov	es:NFH_strikePos, bx		;store strikethrough position

	.leave
	ret

smallAccent:
	clr	es:NFH_accent
	mov	bx, es:NFH_ascent		;bx <- scanned ascent value
	jmp	afterAccent

ScanBaseline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteFontHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write NewFontHeader block to file
CALLED BY:	CopyFontHeader()

PASS:		bx - handle of NewFontHeader block
		ax - size of NewFontHeader block
		es - seg addr of NewFontHeader block
		dx - dest file handle
RETURN:		carry - set if error
			ax - NimbusError
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteFontHeader	proc	near
	uses	ds, di
	.enter

	mov	di, bx				;di <- block handle
	mov	cx, ax				;cx <- # bytes to write
	clr	al				;al <- file flags
	mov	bx, dx				;bx <- dest file handle
	clr	dx
	segmov	ds, es				;ds:dx <- ptr to buffer
	call	FileWrite
	pushf
	mov	bx, di				;bx <- block handle
	call	MemFree				;free me jesus
	popf
	jc	writeError			;branch if error from FileWrite

done:
	.leave
	ret

writeError:
	mov	ax, NE_FILE_WRITE		;ax <- NimbusError
	jmp	done				;carry set
WriteFontHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteHalfData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data lump of half of character data
CALLED BY:	ConvertOneNimbusFont()

PASS:		al - first character
		ah - last character
		cx - block handle of DTCHeader
		dx - dest file handle
		bx - source file handle
RETURN:		ax - size of data block
		carry - set if error
			ax - NimbusError
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteHalfData	proc	near
	uses	bx, cx, dx, si, di, ds, es

sourceFileHandle	local	hptr	push	bx
destFileHandle		local	hptr	push	dx
headerBlockHandle	local	hptr	push	cx
pointerBlockHandle	local	hptr
pointerBlockSize	local	hptr
pointerOffset		local	dword
firstChar		local	Chars
lastChar		local	Chars
charOffset		local	word

	.enter

	mov	ss:firstChar, al
	mov	ss:lastChar, ah
	;
	; Figure out how many characters there are and allocate a block
	; big enough for word-sized offsets to each.
	;
	xchg	ah, al
	sub	al, ah				;al <- # of characters - 1
	LONG jb	noChars				;branch if borrow
	inc	al				;ah <- # of characters
	clr	ah				;ax <- # of characters
	push	ax
	shl	ax, 1				;ax <- # of characters * 2
	mov	ss:pointerBlockSize, ax		;save size of block
	mov	cx, ALLOC_DYNAMIC_LOCK		;cl,ch <- HeapFlags
	call	MemAlloc
	pop	cx				;cx <- # of characters
	LONG jc	memoryError			;branch if error
	mov	ss:pointerBlockHandle, bx	;save handle
	mov	es, ax				;es <- seg addr of block
	;
	; Record the current file position to come back to later.
	;
	push	cx
	call	GetFilePos
	mov	ss:pointerOffset.low, ax
	mov	ss:pointerOffset.high, cx
	;
	; Move the file pointer beyond the current position
	;
	add	ax, ss:pointerBlockSize		;add size of pointer block
	adc	cx, 0				;cx:ax <- file offset
	call	SetFilePos
	pop	cx
	;
	; Figure out the offset in the URW -> PC/GEOS map table
	;
	mov	dl, ss:firstChar		;dl <- first character
	mov	al, dl
	sub	al, ' '
	mov	bl, (size CharConvertEntry)
	mul	bl
	mov	si, ax				;si <- offset of first entry

	clr	di
	mov	ax, ss:pointerBlockSize		;ax <- size of pointers
	mov	ss:charOffset, ax		;first offset
	stosw					;store first offset
	mov	bx, ss:sourceFileHandle		;bx <- source file handle

	;
	; Copy each character to the destination file, and store
	; pointer to the next character.
	;
charLoop:
	; Inform the application that we're handling another character.
	; NOTE:	DL contains the current character number.
	;	It had better preserve everything!
	call	ConvertStatusSetChar

	mov	ax, cs:urwToGeos[si].CCE_urwID	;ax <- URW character value
	DoPush	cx, dx
	mov	cx, ss:headerBlockHandle	;cx <- handle of DTC header
	mov	dx, ss:destFileHandle		;dx <- destination file handle
	call	CopyNimbusChar
	DoPopRV	cx, dx				;cx <- # of characters
	LONG jc	done				;branch if error
	tst	ax				;character missing?
	jnz	afterCharMissing		;branch if not missing
	push	si
	call	DoUpcaseChar			;ax <- uppercase URW ID
	pop	si
	jnc	charUpcased			;branch if upcased
	mov	{word}es:[di][-2], 0		;mark as missing
	jmp	afterMissing
charUpcased:
	mov	{word}es:[di][-2], -1		;mark as upcased
afterMissing:
	clr	ax				;ax <- no size
afterCharMissing:
	add	ax, ss:charOffset		;ax <- next offset
	mov	ss:charOffset, ax
	cmp	cx, 1				;end of the line?
	je	endLoop				;branch if no more data
	stosw					;store offset
	add	si, (size CharConvertEntry)	;si <- offset of next entry
	inc	dl				;dl <- character #
	loop	charLoop			;loop & decrement

	;
	; We've copied all the characters.  Go back and write the table
	; of pointers into the file.  But first we need to go back and
	; patch up any pointers for lowercase letters that had their
	; uppercase equivalents substituted.
	;
endLoop:
	clr	di
	mov	dl, ss:firstChar		;dl <- first character
	mov	cl, ss:lastChar
	sub	cl, dl
	inc	cl
	clr	ch				;cx <- # of characters
pointerLoop:
	cmp	{word}es:[di], -1		;char upcased?
	jne	nextPointer			;branch if data exists
	call	DoUpcaseChar			;al <- upcased character
	sub	al, ss:firstChar
	clr	ah
	shl	ax, 1
	mov	si, ax				;si <- offset of pointer
	mov	ax, es:[si]			;ax <- pointer for uppercase
	mov	es:[di], ax
nextPointer:
	add	di, (size word)			;es:di <- ptr to next pointer
	inc	dl				;dl <- character #
	loop	pointerLoop

	mov	dx, ss:destFileHandle		;dx <- destination file handle
	mov	ax, ss:pointerOffset.low
	mov	cx, ss:pointerOffset.high	;cx.ax <- offset in file
	call	SetFilePos

	mov	bx, ss:destFileHandle		;bx <- destination file handle
	clr	al				;al <- file flags
	mov	cx, ss:pointerBlockSize		;cx <- # of bytes to write
	segmov	ds, es
	clr	dx				;ds:dx <- ptr to buffer
	call	FileWrite
	jc	writeError			;branch if error
	;
	; Put the file pointer back at the end of the file
	;
	mov	al, FILE_SEEK_END		;al <- FileSeekModes
	clr	cx
	clr	dx				;cx:dx <- offset from end
	call	FilePos
	;
	; Free the pointer block
	;
	mov	bx, ss:pointerBlockHandle	;bx <- handle of pointer block
	call	MemFree
	;
	; Return size of block written
	;
	mov	ax, ss:charOffset		;ax <- # of bytes for char data

	clc					;carry <- no error
done:
	.leave
	ret

noChars:
	clr	ax				;ax <- size of data == 0
	clc					;carry <- no error
	jmp	done

memoryError:
	mov	ax, NE_MEM_ALLOC		;ax <- NimbusError
	jmp	done				;carry set
writeError:
	mov	ax, NE_FILE_WRITE		;ax <- NimbusError
	jmp	done				;carry set
WriteHalfData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoUpcaseChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upcase character to something we can handle
CALLED BY:	WriteHalfData()

PASS:		dl - Chars value to check
RETURN:		carry - clear if character upcased
			ax - upcased character
			si - offset of CharConvertEntry
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoUpcaseChar	proc	near
	uses	di
	.enter

	cmp	dl, C_GERMANDBLS		;can't handle this
	je	charMissing
	cmp	dl, C_LI_DOTLESS		;can't handle this
	je	charMissing
	mov	al, dl
	mov	di, DR_LOCAL_IS_LOWER
	call	SysLocalInfo			;lowercase?
	jz	charMissing		;branch if not lowercase
	mov	di, DR_LOCAL_UPCASE_CHAR
	call	SysLocalInfo
calcChar:
	clr	ah
	mov	si, ax				;si <- character
	sub	si, ' '				;table starts at ' '
	shl	si, 1
	shl	si, 1				;si <- *4 for each entry
	clc					;carry <- character upcased

done:
	.leave
	ret

charMissing:
	stc					;carry <- no substitution
	jmp	done
DoUpcaseChar	endp

ConvertCode	ends
