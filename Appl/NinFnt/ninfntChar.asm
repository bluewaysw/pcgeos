COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		ninfntChar.asm

AUTHOR:		Gene Anderson, Apr 17, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	CopyNimbusChar		copy data for Nimbus character to file
EXT	ReadNimbusChar		read data for Nimbus character from file

INT	NimCopyTuples		copy x- or y-hints
INT	NimCopyAccent		copy accent command data
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/17/91		Initial revision

DESCRIPTION:
	Routines for reading and writing Nimbus character data

	$Id: ninfntChar.asm,v 1.1 97/04/04 16:16:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadNimbusChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read Nimbus character data
CALLED BY:	CopyNimbusChar()

PASS:		bx - source file handle
		ax - URW character #
		cx - block handle of header
RETURN:		bx - handle of block (0 if character not found)
		ds - seg addr of block
		ax - size of block (0 if character not found)
		carry - set if error
			ax - NimbusError
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReadNimbusChar	proc	near
	uses	cx, dx, es, di

sourceFileHandle	local	hptr
headerHandle		local	hptr

	.enter

	mov	ss:sourceFileHandle, bx
	mov	ss:headerHandle, cx
	mov	dx, ax				;dx <- URW character #
	call	LockNimbusHeader		;ax <- seg addr of header
	jc	done				;branch if error
	mov	es, ax				;es <- seg addr of header
	mov	cx, es:DTCFH_numChars		;cx <- # of characters
	push	cx
	mov	di, (size DTCFontHeader)	;es:di <- ptr to char ID table
	mov	ax, dx				;ax <- URW character #
	repne	scasw				;scan me jesus
	jne	charNotFound			;branch if character not found
	sub	di, (size word) + (size DTCFontHeader)
	shl	di, 1				;di <- *2*2 for each offset
	add	di, (size DTCFontHeader)
	pop	cx				;cx <- # chars
	shl	cx, 1				;cx <- size of char ID table
	add	di, cx				;es:di <- ptr to file offset
	mov	dx, es:[di].low
	mov	cx, es:[di].high		;cx:dx <- offset in file
	mov	bx, es:[di][(size dword)].low
	mov	ax, es:[di][(size dword)].high	;bx:ax <- offset of next char
	sub	ax, cx
	sbb	bx, dx				;bx <- size of char data
	jz	charNotFoundNoPop		;branch if zero-sized
	push	bx
	mov	al, FILE_SEEK_START		;al <- FileSeekModes
	mov	bx, ss:sourceFileHandle		;bx <- handle of source file
	call	FilePos
	pop	ax				;ax <- size of char data
	mov	dx, ax				;dx <- size of char data
	mov	cx, ALLOC_DYNAMIC_LOCK		;cx <- HeapFlags, HeapAllocFlags
	call	MemAlloc
	jc	memoryError			;branch if error
	push	bx
	mov	bx, ss:sourceFileHandle		;bx <- handle of source file
	mov	ds, ax				;ds <- seg addr of block
	mov	cx, dx				;cx <- size of data
	clr	dx				;ds:dx <- ptr to buffer
	clr	al				;al <- file flags
	call	FileRead			;carry set for error
	mov	ax, cx				;ax <- size of block
	pop	bx				;bx <- handle of char block
	jc	readError

	tst	ds:DTCD_width			;any width?
	jz	charEmpty			;branch if no width
	clc					;carry <- no error
done:
	mov	cx, ss:headerHandle		;cx <- handle of header
	call	UnlockNimbusHeader		;preserves flags, ax, bx

	.leave
	ret

	;
	; Nimbus files have two bits of goofiness:
	; First, characters can have valid offsets but no data.
	; This is signified by the difference between the offset
	; for the character and the next character being zero.
	; Second, characters can have actual data that specifies
	; no character.  The width is zero (as are the bounds)
	;
charEmpty:
	call	MemFree				;free block
	jmp	charNotFoundNoPop

charNotFound:
	pop	cx				;clean stack
charNotFoundNoPop:
	clr	bx				;bx <- character not found
	clr	ax				;ax <- character not found
	clc					;carry <- no error
	jmp	done

memoryError:
	mov	ax, NE_MEM_ALLOC		;ax <- error from Mem routine
	jmp	done				;carry set

readError:
	mov	ax, NE_FILE_READ		;ax <- error from FileRead()
	jmp	done				;carry set
ReadNimbusChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNimbusChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy modified Nimbus character data from source to dest file
CALLED BY:	

PASS:		bx - source file handle
		dx - dest file handle
		cx - header block handle
		ax - URW character #
RETURN:		carry - set on error
			ax - NimbusError
		ax - size of character data written (0 if none)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyNimbusChar	proc	near
	uses	bx, cx, dx, si, di, ds, es

locals	local	ScanLocals

	.enter

	mov	ss:locals.SL_sourceFileHandle, bx
	mov	ss:locals.SL_destFileHandle, dx
	mov	ss:locals.SL_headerHandle, cx
	;
	; Load the character data
	;    returns:
	;	bx = block handle
	;	ds = seg addr of block
	;	ax = size of block
	;
	call	ReadNimbusChar
	jc	done				;branch if error
	tst	bx				;character loaded/available?
	jz	noCharData			;branch if not available
	mov	ss:locals.SL_sourceBlockHandle, bx
	clr	si				;ds:si <- ptr to data
	;
	; Allocate a block for the destination data.
	; Since our format is smaller, this block is guaranteed
	; to be large enough.
	;
	mov	cx, ALLOC_DYNAMIC_LOCK		;cx <- HeapFlags, HeapAllocFlags
	call	MemAlloc
	LONG jc	allocError			;branch if error
	mov	ss:locals.SL_destBlockHandle, bx
	mov	es, ax
	clr	di				;es:di <- ptr to NewData
	;
	; Get and save the width, and copy the rest of the header
	;
	lodsw					;ax <- width
	mov	cx, ((size DTCData) - (size DTCD_width))/(size word)
	rep	movsw				;copy DTCData
	;
	; Copy the hints, both x and y
	;
	call	NimCopyTuples			;copy x hints
	call	NimCopyTuples			;copy y hints
	;
	; Copy the command data, one command at a time
	;
commandLoop:
	lodsw					;ax <- DTCCommands
	stosb					;write command as byte
	cmp	ax, DTC_DONE			;end of character?
	je	endChar				;branch while more data
	cmp	ax, DTC_ACCENT			;accent command?
	je	accentChar			;special case for accent
	mov	bx, ax
	shl	bx, 1				;bx <- command index
	mov	cx, cs:commandSizes[bx]		;cx <- size of command
EC <	tst	cx				;>
EC <	ERROR_Z	BAD_NIMBUS_COMMAND		;>
NEC <	jcxz	dataError			;>
	rep	movsw				;copy me jesus
	jmp	commandLoop

	;
	; NOTE: it is assumed that no commands follow an accent command.
	; This is true in some fonts but not all. However, we can safefully
	; ignore anything after an accent command, as the Nimbus driver
	; ignores it, too.
	;
accentChar:
	call	NimCopyAccent			;special case for accent command
	jc	charError			;branch if error
	;
	; Done with the source block -- free it
	;
endChar:
	mov	bx, ss:locals.SL_sourceBlockHandle
	call	MemFree
	;
	; Flush the data to disk and free the block
	;
	mov	cx, di				;cx <- # of bytes
	segmov	ds, es
	clr	dx				;ds:dx <- ptr to buffer
	mov	bx, ss:locals.SL_destFileHandle	;bx <- file handle
	clr	al				;al <- flags
	call	FileWrite
	jc	writeError			;branch if error
	mov	ax, cx				;ax <- # of bytes written
	mov	bx, ss:locals.SL_destBlockHandle
	call	MemFree
	clc					;carry <- no error
done:
	.leave
	ret

noCharData:
	clr	ax				;ax <- size of data
	clc					;carry <- no error
	jmp	done

charError:
	mov	bx, ss:locals.SL_sourceBlockHandle
	call	MemFree
	mov	bx, ss:locals.SL_destBlockHandle
	call	MemFree
	clr	bx
	stc					;carry <- set for error
	jmp	done

allocError:
	mov	ax, NE_MEM_ALLOC		;ax <- error from MemAlloc()
	jmp	done				;carry set
writeError:
	mov	ax, NE_FILE_WRITE		;ax <- error from FileWrite()
	jmp	done				;carry set
dataError:
	mov	ax, NE_BAD_DATA			;ax <- error from bad data
	jmp	done				;carry set
CopyNimbusChar	endp

commandSizes	word \
	(size DTCMoveData)/(size word),
	(size DTCLineData)/(size word),
	(size DTCBezierData)/(size word),
	0,					;DTC_DONE
	0,					;illegal command
	-1,					;DTC_ACCENT (special case)
	(size DTCVertData)/(size word),
	(size DTCHorizData)/(size word),
	(size DTCRelLineData)/(size word),
	(size DTCRelBezierData)/(size word)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimCopyTuples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the hints for a character
CALLED BY:	WriteNimbusChar()

PASS:		ds:si - ptr to # tuples
		es:di - ptr to dest buffer
RETURN:		ds:si - ptr past last tuple read
		es:di - ptr past last tuple written
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(size DTCTuple)/(size word) eq 3>

NimCopyTuples	proc	near
	uses	ax
	.enter

	lodsw					;ax <- # of tuples
EC <	tst	ah				;>
EC <	ERROR_NZ	TOO_MANY_HINTS		;>
	mov	cx, ax				;cx <- # of tuples
	stosb					;store # of hints
	shl	ax, 1				;ax <- # of hints * 2
	add	cx, ax				;cx <- # to hints * 3
	rep	movsw

	.leave
	ret
NimCopyTuples	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimCopyAccent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy an accent command
CALLED BY:	WriteNimbusChar()

PASS:		ds:si - ptr past command
		es:di - ptr to dest buffer
RETURN:		ds:si - ptr past last byte read
		es:di - ptr past last byte written
		carry - set if error
			ax - NimbusError
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimCopyAccent	proc	near
	.enter

	lodsw					;ax <- 1st URW character
	call	MapURWToGEOS			;al <- PC/GEOS character
	jc	charNotFound			;branch if character not found
	stosb					;store 1st character
	lodsw					;ax <- x offset
	stosw
	lodsw					;ax <- y offset
	stosw
	lodsw					;ax <- 2nd URW character
	call	MapURWToGEOS			;al <- PC/GEOS character
	jc	charNotFound			;branch if character not found
	stosb					;store 2nd character
	clc					;carry <- no error
done:
	.leave
	ret

charNotFound:
	mov	ax, NE_ACCENT_CHAR_MISSING	;ax <- NimbusError
	jmp	done				;carry set
NimCopyAccent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanNimbusChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate character-based info for font header
CALLED BY:	CopyFontHeader()

PASS:		bx - handle of character data (0 if none)
		cx - handle of DTCFontHeader block
		ds - seg addr of character data
		es:di - ptr to NewWidth entry
		si - offset of CharConvertEntry
		dl - PC/GEOS character value (Chars)
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	NFH_maxwidth = MAX(DTCD_width);
	NFH_avgwidth = SUM(DTCD_width * weight[char]) / 1000;
	NFH_minLSB = MIN(DTCD_xmin);
	NFH_maxRSB = MAX(DTCD_xmax);
	NFH_maxBSB = MAX(-DTCD_ymin);
	NFH_minTSB = MAX(DTCD_ymax);

	CTF_NEGATIVE_LSB = (DTCD_xmin < 0);
	CTF_BELOW_DESCENT = (-DTCD_ymin > NIMBUS_DESCENT);
	CTF_ABOVE_ASCENT = (DTCD_ymax > NIMBUS_BASELINE);
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanNimbusChar	proc	near
	uses	cx, dx

locals	local	ScanLocals

	.enter	inherit

	tst	bx				;character loaded?
	jz	charMissing			;branch if character missing
	clr	dh				;dh <- CharTableFlags
	call	ScanCharWidth			;for DTCD_width
	call	ScanCharXMin			;for DTCD_xmin
	call	ScanCharXMax			;for DTCD_xmax
	call	ScanCharYMin			;for DTCD_ymin
	call	ScanCharYMax			;for DTCD_ymax
	mov	es:[di].NW_flags, dh		;store CharTableFlags
	;
	; Unlock the character data and go to the next character.
	;
	call	MemFree				;done with character
nextChar:

	.leave
	ret

charMissing:
	clr	es:[di].NW_width
	mov	es:[di].NW_flags, mask CTF_NO_DATA
	jmp	nextChar
ScanNimbusChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanCharWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with flags and values for character width
CALLED BY:	ScanNimbusChar()

PASS:		ds - seg addr of Nimbus character data (DTCData)
		es:di - ptr to NewWidth for character
		ss:bp  - inherited locals
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanCharWidth	proc	near
	uses	dx

locals	local	ScanLocals

	.enter	inherit

	mov	ax, ds:DTCD_width
	mov	es:[di].NW_width, ax		;store width
	cmp	ax, es:NFH_maxwidth		;new maximum width?
	jbe	notMaxWidth
	mov	es:NFH_maxwidth, ax		;store new maximum width
notMaxWidth:
	mov	dl, cs:urwToGeos[si].CCE_weight
	tst	dl
	jz	noWeight
	clr	dh
	add	ss:locals.SL_weightTotal, dx	;add weight total
	mul	dx				;dx:ax <- width*weight
	add	ss:locals.SL_weightAvg.low, ax
	adc	ss:locals.SL_weightAvg.high, dx	;add to total average
noWeight:

	.leave
	ret
ScanCharWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanCharXMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with flags and values for character x min value
CALLED BY:	ScanNimbusChar()

PASS:		ds - seg addr of Nimbus character data (DTCData)
		es - seg addr of NewFontHeader
		dh - CharTableFlags
		si - offset of CharConvertEntry
RETURN:		dh - CharTableFlags (updated)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanCharXMin	proc	near
	.enter

	mov	ax, ds:DTCD_xmin		;ax <- LSB
	cmp	ax, es:NFH_minLSB
	jge	notMinLSB
	mov	es:NFH_minLSB, ax		;store new min LSB
notMinLSB:
	cmp	ax, 0				;less than zero?
	jge	notNegLSB
	ornf	dh, mask CTF_NEGATIVE_LSB	;mark as negative LSB
notNegLSB:

	.leave
	ret
ScanCharXMin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanCharXMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with flags and values for character x min value
CALLED BY:	ScanNimbusChar()

PASS:		ds - seg addr of DTCData
		es - seg addr of NewFontHeader
		si - offset of CharConvertEntry
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanCharXMax	proc	near
	.enter

	mov	ax, ds:DTCD_xmax		;ax <- RSB
	cmp	ax, es:NFH_maxRSB
	jle	notMaxRSB
	mov	es:NFH_maxRSB, ax		;store new max RSB
notMaxRSB:

	.leave
	ret
ScanCharXMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanCharYMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with flags and values for character y min value
CALLED BY:	ScanNimbusChar()

PASS:		ds - seg addr of Nimbus character data (DTCData)
		es - seg addr of NewFontHeader
		dh - CharTableFlags
		si - offset of CharConvertEntry
RETURN:		dh - CharTableFlags (updated)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanCharYMin	proc	near
	.enter

	mov	ax, ds:DTCD_ymin		;ax <- BSB
	neg	ax
	cmp	ax, es:NFH_maxBSB
	jle	notMaxBSB
	mov	es:NFH_maxBSB, ax		;store new max BSB
notMaxBSB:
	cmp	ax, NIMBUS_DESCENT-NIMBUS_SAFETY
	jl	notBelowDescent
	ornf	dh, mask CTF_BELOW_DESCENT	;mark as below normal descent
notBelowDescent:
	test	cs:urwToGeos[si].CCE_flags, mask CCF_DESCENT
	jz	notDescent
	cmp	ax, es:NFH_descent
	jle	notDescent
	mov	es:NFH_descent, ax		;store new descent
notDescent:

	.leave
	ret
ScanCharYMin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanCharYMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with flags and values for character y max value
CALLED BY:	ScanNimbusChar()

PASS:		ds - seg addr of Nimbus character data (DTCData)
		es - seg addr of NewFontHeader
		dh - CharTableFlags
		si - offset of CharConvertEntry
RETURN:		dh - CharTableFlags (updated)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanCharYMax	proc	near
	.enter

	mov	ax, ds:DTCD_ymax		;ax <- TSB
	cmp	ax, es:NFH_minTSB
	jle	notMaxTSB
	mov	es:NFH_minTSB, ax		;store new max TSB
notMaxTSB:
	cmp	ax, NIMBUS_BASELINE-NIMBUS_SAFETY
	jl	notAboveAscent
	ornf	dh, mask CTF_ABOVE_ASCENT	;mark as above normal ascent
notAboveAscent:
	test	cs:urwToGeos[si].CCE_flags, mask CCF_ASCENT or mask CCF_CAP
	jz	notAscent
	cmp	ax, es:NFH_ascent
	jle	notAscent
	mov	es:NFH_ascent, ax		;store new ascent
notAscent:
	test	cs:urwToGeos[si].CCE_flags, mask CCF_ACCENT
	jz	notAccent
	cmp	ax, es:NFH_accent
	jle	notAccent
	mov	es:NFH_accent, ax		;store new accent
notAccent:

	.leave
	ret
ScanCharYMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanNonBrkSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup stuff for non-breaking space (C_NONBRKSPACE)
CALLED BY:	CopyFontHeader()

PASS:		es - seg addr of NewFontHeader
RETURN:		none
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanNonBrkSpace	proc	near
	.enter

	cmp	es:NFH_firstChar, ' '		;first character space?
	jne	nonBrkOK			;if not, ignore non-break

	test	es:[NewFontHeader]\
		[(C_NONBRKSPACE-' ')*(size NewWidth)].NW_width, 0xffff
	jnz	nonBrkOK
	mov	ax, es:[NewFontHeader].NW_width	;ax <- width of space
	mov	es:[NewFontHeader]\
			[(C_NONBRKSPACE-' ')*(size NewWidth)].NW_width, ax
	mov	al, es:[NewFontHeader].NW_flags
	mov	es:[NewFontHeader]\
			[(C_NONBRKSPACE-' ')*(size NewWidth)].NW_flags, al
nonBrkOK:

	.leave
	ret
ScanNonBrkSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanDefaultChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup stuff for default character
CALLED BY:	CopyFontHeader()

PASS:		es - seg addr of NewFontHeader
RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanDefaultChar	proc	near
	uses	di
	.enter

	;
	; Does the default character exist?
	;
	mov	al, es:NFH_defaultChar		;al <- default character
	sub	al, ' '
	mov	bl, (size NewWidth)
	mul	bl				;ax <- offset of NewWidth
	add	ax, (size NewFontHeader)	;ax <- ptr of NewWidth
	mov	di, ax
	test	es:[di].NW_flags, mask CTF_NO_DATA
	jz	defaultOK
	;
	; It doesn't exist.  Use the first character instead.
	;
	mov	al, es:NFH_firstChar
	mov	es:NFH_defaultChar, al
	mov	ax, es:[NewFontHeader].NW_width
	mov	es:[di].NW_width, ax
	mov	al, es:[NewFontHeader].NW_flags
	mov	es:[di].NW_flags, al
defaultOK:

	.leave
	ret
ScanDefaultChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanAverageWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure average width is valid.
CALLED BY:	CopyFontHeader()

PASS:		es - seg addr of NewFontHeader
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScanAverageWidth	proc	near

locals	local	ScanLocals


	.enter	inherit

	mov	bx, NIMBUS_WEIGHT_TOTAL
	cmp	ss:locals.SL_weightTotal, bx	;weights all accounted for?
	jne	useDefaultWidth			;if not, use default char
	;
	; The characters used for the weighted average all exist,
	; so we can just use the total weighted widths to calculate
	; the average width.
	;
	mov	ax, ss:locals.SL_weightAvg.low
	mov	dx, ss:locals.SL_weightAvg.high
	div	bx				;ax <- weight total / #
storeWidth:
	mov	es:NFH_avgwidth, ax		;store weighted average

	.leave
	ret

	;
	; One or more of the characters used for the weighted average
	; were missing -- just use the width of the default character
	; instead.
	;
useDefaultWidth:
	mov	al, es:NFH_defaultChar		;al <- default character
	sub	al, es:NFH_firstChar
	mov	bl, (size NewWidth)
	mul	bl				;ax <- offset of NewWidth
	add	ax, (size NewFontHeader)
	mov	bx, ax				;es:bx <- ptr to width entry
	mov	ax, es:[bx].NW_width		;ax <- width of default char
	jmp	storeWidth
ScanAverageWidth	endp

ConvertCode	ends
