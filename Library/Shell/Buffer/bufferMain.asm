COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Shell -- Buffer
FILE:		bufferMain.asm

AUTHOR:		Martin Turon, Aug 21, 1992

GLOBAL ROUTINES:
	Name			Description
	----			-----------
	ShellBufferOpen		Opens a ShellBuffer
	ShellBufferReadNLines	Reads the next N lines from ShellBuffer
	ShellBufferReadLine	Reads the next line of a ShellBuffer
	ShellBufferClose	Closes a ShellBuffer file
	ShellBufferLock		Locks a ShellBuffer
	ShellBufferUnlock	Unlocks a ShellBuffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/21/92		Initial version


DESCRIPTION:
	Routines to deal with reading huge files. (64k+)

	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

RCS STAMP:
	$Id: bufferMain.asm,v 1.1 97/04/04 19:37:18 newdeal Exp $

=============================================================================@



COMMENT @-------------------------------------------------------------------
			ShellBufferOpen
----------------------------------------------------------------------------

DESCRIPTION:	Opens the file, and allocates memory for a read buffer.

CALLED BY:	GLOBAL - BookmarkListOldStyleBookmarks

PASS:		al	= FileAccessFlags
		ds:dx 	= file name 
RETURN:	 	IF File opened successfully:
			carry clear
			es	= ShellBuffer
	 	ELSE:
			carry set
			ax	= FileError
			es	destroyed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	*** Must use ShellBufferClose when done ***	

	Some fields in returned ShellBuffer may be invalid before
	ShellBufferReadNLines or ShellBufferReadLine is called.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/16/97	Initial version

---------------------------------------------------------------------------@
ShellBufferOpen	proc	far

	.enter
	;
	; open the file
	;
		call	FileOpen
		jc	done
		mov_tr	dx, ax			; dx = file handle
		call	ShellBufferAlloc
done:
	.leave
	ret
		
ShellBufferOpen	endp


COMMENT @-------------------------------------------------------------------
			ShellBufferAlloc
----------------------------------------------------------------------------

DESCRIPTION:	Allocates memory for a ShellBuffer to read the given file.

CALLED BY:	GLOBAL - ShellBufferOpen

PASS:		dx 	= FileHandle
RETURN:	 	IF File opened successfully:
			carry clear
			es	= ShellBuffer
	 	ELSE:
			carry set
			ax	= FileError
			es	destroyed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Some fields in returned ShellBuffer may be invalid before
	ShellBufferReadNLines or ShellBufferReadLine is called.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/21/92		Initial version
	AY	7/22/93		Fixed when MemAlloc returns error

---------------------------------------------------------------------------@
ShellBufferAlloc	proc	far
	uses	bx, cx, dx
	.enter
	;
	; open the file
	;
		call	FileOpen
		jc	done
		mov_tr	dx, ax			; dx = file handle
	;
	; allocate memory for ShellBuffer and read buffer
	;
		mov	ax, size ShellBuffer
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		mov	es, ax
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jc	done

		mov	es:SB_bufferHandle, bx
		mov	es:SB_fileHandle, dx
		mov	es:SB_nextLine, size ShellBuffer

done:
	.leave
	ret
ShellBufferAlloc	endp



COMMENT @-------------------------------------------------------------------
			ShellBufferClose
----------------------------------------------------------------------------

DESCRIPTION:	Closes the given Buffer, and frees any memory it was
		using.

CALLED BY:	GLOBAL - BookmarkListOldStyleBookmarks
	
PASS:		es 	= ShellBuffer

RETURN:		IF ERROR:
			carry set
			ax 	= FileError
		ELSE:
			carry clear

DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/21/92		Initial version

---------------------------------------------------------------------------@
ShellBufferClose	proc	far
	uses	bx
	.enter
	clr	al
	mov	bx, es:[SB_fileHandle]
	call	FileClose
	pushf
	mov	bx, es:[SB_bufferHandle]
	call	MemFree
	popf
	.leave
	ret
ShellBufferClose	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellBufferReadLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read one line from a huge file.

CALLED BY:	GLOBAL
PASS:		es	= ShellBuffer sptr
RETURN:		es:di	= next line in file
		CF	= set if either EOF or returned line is too long to fit
			  in buffer
			  clear otherwise
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call HugeFileReadNLines to do the work.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/28/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellBufferReadLine	proc	far

	mov	cx, 1			; read one line
	FALL_THRU	ShellBufferReadNLines

ShellBufferReadLine	endp



COMMENT @-------------------------------------------------------------------
			ShellBufferReadNLines
----------------------------------------------------------------------------

DESCRIPTION:	Read N lines from a huge file

CALLED BY:	EXTERNAL

PASS:		es	= ShellBuffer
		cx	= # of lines to read
RETURN:		es:di	= first line requested
		cx	= # of lines actually read(may be fewer than requested)
		ax	= # of bytes read (including CR-LF's if found)
		CF	= set if not enough lines are read (either EOF or
			  lines too long to fit in buffer)
			  clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Each line must be ended with CR-LF pair.  CR or LF only are not
	considered line terminator.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/21/92		Initial version (ShellBufferReadLine)
	AY	10/28/92	Changed to ShellBufferReadNLines

---------------------------------------------------------------------------@
ShellBufferReadNLines	proc	far
numLinesToRead		local	word	push	cx
fileAlreadyReadOnce	local	byte
		uses	bx, dx, si, ds
		.enter
		mov	ss:fileAlreadyReadOnce, FALSE
		mov	bx, es:SB_fileHandle
	;
	; first get last line, and check if valid
	;
		mov	di, es:SB_nextLine
		cmp	di, size ShellBuffer
		jae	fillBufferFromFile
	;
	; now check if next line is complete
	;
		mov	es:SB_offset, di
checkIfLinesAreComplete:
		mov	si, ss:numLinesToRead
		mov	cx, es:SB_bufferEnd
		sub	cx, di
		jz	notEnoughLines	; will then jump to done, and return
		mov	al, C_CR
lineLoop:
		; ZF must be clear here before "repne scasb"
		repne 	scasb
		jne	notEnoughLines
		tst	cx
		jz	notEnoughLines	; jump if LF not read
		cmp	{char} es:[di], C_LF
		jne	lineLoop	; this is not LF, check if it's CR

		; this line is complete
		inc	di
		dec	cx
		dec	si		; decrement line count
		jnz	lineLoop	; loop for next line

		mov	cx, ss:numLinesToRead	; cx = # of lines read
		clc

done:
		pushf			; save CF
		mov	es:SB_nextLine, di
		mov	ax, di
		mov	di, es:SB_offset
		sub	ax, di		; ax = # of bytes read
		popf			; restore CF
		.leave
		ret

notEnoughLines:
	; see if lines are too long to fit in buffer
		cmp	ss:fileAlreadyReadOnce, TRUE
		je	returnError	; return error if lines too long

	; see if file already exhausted
		cmp	es:SB_bufferEnd, size ShellBuffer
		je	positionFileAndFillBuffer
		; file exhaused
returnError:	mov	cx, ss:numLinesToRead
		sub	cx, si		; cx = # of lines read
		stc
		jmp	done

positionFileAndFillBuffer:
		clr	cx
		mov	dx, es:SB_nextLine
		sub	dx, size ShellBuffer
		sbb	cx, 0
	;
	; replace with:
	;	movwdw	cxdx, es:SB_nextLine
	;	subwdw	cxdx, size ShellBuffer
	;
	; error if not zero or not negative
EC <		ERROR_G		CORRUPT_SHELL_BUFFER_NEXT_LINE_POINTER	>

		mov	al, FILE_POS_RELATIVE
	 	call	FilePos

fillBufferFromFile:
		clr	al
		mov	cx, SHELL_BUFFER_MAX_LINE_LENGTH
		segmov	ds, es, dx
		mov	dx, offset SB_buffer
		mov	es:SB_offset, dx
		call	FileRead	; return cx = # of bytes read
		mov	di, dx
		jc	checkForEOF
		mov	es:SB_bufferEnd, size ShellBuffer
		mov	ss:fileAlreadyReadOnce, TRUE
		jmp	checkIfLinesAreComplete

checkForEOF:
		cmp	ax, ERROR_SHORT_READ_WRITE	; EOF reached
		jne	error
		add	cx, dx
		mov	es:SB_bufferEnd, cx
		jmp	checkIfLinesAreComplete

error:
		mov_tr	bx, ax				; preserve error code
		ERROR	PROBLEMS_WHEN_READING_SHELL_BUFFER

ShellBufferReadNLines	endp



COMMENT @-------------------------------------------------------------------
			ShellBufferLock
----------------------------------------------------------------------------

DESCRIPTION:	Locks a ShellBuffer

CALLED BY:	GLOBAL

PASS:		bx = handle of ShellBuffer
RETURN:		es = ShellBuffer
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/23/92		Initial version

---------------------------------------------------------------------------@
ShellBufferLock	proc	far
	uses	ax
	.enter
	call	MemLock
	mov	es, ax
	.leave
	ret
ShellBufferLock	endp



COMMENT @-------------------------------------------------------------------
			ShellBufferUnlock
----------------------------------------------------------------------------

DESCRIPTION:	Unlocks a ShellBuffer

CALLED BY:	GLOBAL

PASS:		es 	= ShellBuffer
RETURN:		bx	= handle of ShellBuffer
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/23/92		Initial version

---------------------------------------------------------------------------@
ShellBufferUnlock	proc	far
	.enter
	mov	bx, es:[SB_bufferHandle]
	call	MemUnlock
	.leave
	ret
ShellBufferUnlock	endp





