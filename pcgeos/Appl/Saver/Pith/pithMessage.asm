COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pithMessage.asm

AUTHOR:		Gene Anderson, Jun  3, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 3/93		Initial revision


DESCRIPTION:
	

	$Id: pithMessage.asm,v 1.1 97/04/04 16:48:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PithCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PithInitMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reade the messages file and convert the text as needed

CALLED BY:	PitSetWin()
PASS:		none
RETURN:		bx - handle of message block (0 if error)
		cx - # of messages
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PithInitMessages		proc	near
		uses	si, di, ds, es, bp
		.enter

		call	ReadMessageFile
		jc	returnErrorMessage
		call	ConvertMessages
done:
		.leave
		ret

returnErrorMessage:
		clr	bx, cx
		jmp	done
PithInitMessages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadMessageFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the message file

CALLED BY:	InitMessages()
PASS:		none
RETURN:		carry - set if error
		else:
			bx - handle of message buffer
			ds - seg addr of message buffer
			cx - size of message buffer
DESTROYED:	ax, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString dataDirName <PITH_MESSAGE_DIRECTORY,0>
LocalDefNLString messageFileName <PITH_MESSAGE_FILE,0>

ReadMessageFile		proc	near
		.enter
	;
	; Go to the appropriate directory
	;
		segmov	ds, cs
		mov	dx, offset dataDirName	;ds:dx <- ptr to directory name
		mov	bx, SP_USER_DATA	;bx <- StandardPath
		call	FileSetCurrentPath
		jc	errorCommon		;branch if error
	;
	; Open the messages file
	;
		mov	dx, offset messageFileName
		mov	al, FILE_ACCESS_R or FILE_DENY_NONE
		call	FileOpen
		jc	errorCommon
	;
	; Get the file size and make sure it isn't too big
	;
		mov	bx, ax			;bx <- file handle
		call	FileSize
		tst	dx			;too large?
		jnz	tooLarge
		cmp	ax, PITH_MESSAGE_MAX_FILE_SIZE
		jbe	sizeOK
tooLarge:
		mov	ax, PITH_MESSAGE_MAX_FILE_SIZE
sizeOK:
	;
	; Allocate a buffer to hold the text
	;
		push	ax, bx			;save file size, handle
		inc	ax			;ax <- +size for NULL
DBCS <		inc	ax			;ax <- +size for NULL>
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		
		mov	bp, bx			;bp <- mem handle
		pop	cx, bx			;cx <- file size, bx <- handle
		jc	errorClose		;branch if error allocating
		mov	ds, ax			;ds <- seg addr

		mov	si, cx			;si <- file size
		LocalClrChar ds:[si], 0		;NULL-terminate the buffer
	;
	; Read the entire file into our buffer
	;
		clr	al			;al <- no flags
		clr	dx			;ds:dx <- ptr to buffer
		call	FileRead
		jc	errorFree		;branch if error
	;
	; Close the file
	;
		clr	al			;al <- no flags
		call	FileClose
	;
	; Unlock the block
	;
		mov	bx, bp			;bx <- handle of block
		clc				;carry <- no error
errorExit:

		.leave
		ret

errorClose:
		clr	al			;al <- no flags
		call	FileClose
errorCommon:
		stc				;carry <- error
		jmp	errorExit

errorFree:
		mov	bx, bp			;bx <- memory handle
		call	MemFree
		jmp	errorCommon
ReadMessageFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the messages from DOS characters to GEOS characters
		and put them into a quick-and-easy-to-access lmem heap.

CALLED BY:	PithInitMessages()
PASS:		bx - handle of message buffer
		ds - seg addr of message buffer
		cx - size of message buffer
RETURN:		bx - handle of converted messages
		cx - # of messages
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PITH_DEFAULT_CHUNK_SIZE	equ	80

ConvertMessages		proc	near
curChunk	local	lptr
chunkSize	local	word
SBCS <prevChar	local	char						>
DBCS <prevChar	local	wchar						>
numMessages	local	word
		.enter

		push	bx			;save source buffer handle
		clr	ss:numMessages
	;
	; Allocate an lmem heap for our use
	;
		push	cx
		mov	ax, LMEM_TYPE_GENERAL	;ax <- LMemType
		clr	cx			;cx <- default size
		call	MemAllocLMem
		pop	cx
	;
	; Lock the destination block and add a new chunk
	;
		call	MemLock
		mov	es, ax
	;
	; Convert the text from DOS to GEOS, and strip linefeed characters.
	;
		clr	si			;ds:si <- ptr to source text
	;
	; Skip any blank lines or comments
	;
skipBlankLoop:
		call	SkipBlankLines
		jcxz	doneChars		;branch if reached end of text
	;
	; Found a message -- allocate a chunk to put it in
	;
		inc	ss:numMessages		;one more message
		clr	ss:prevChar		;no previous character
		clr	dx			;dx <- # of bytes written
		call	allocNewChunk
	;
	; Make sure we've got enough space to write the character
	;
getMessageChar:
		cmp	dx, ss:chunkSize	;enough space?
		jbe	sizeOK			;branch if enough space
		call	resizeChunkBigger	;else resize chunk bigger
sizeOK:
	;
	; Actually get and store the character (amazing, isn't it?)
	;
		call	GetMessageChar
		jcxz	doneMessage		;branch if reached end of text
	;
	; See if we've reached the end of the message -- two CRs in a row
	;
		LocalCmpChar	ax, C_CR		;current char a CR?
		jne	notEnd
		cmp	ss:prevChar, C_CR	;previous char a CR?
		je	doneMessage
notEnd:
		LocalPutChar esdi, ax
		inc	dx			;dx <- 1 more byte written
DBCS <		inc	dx			;dx <- 2 more bytes written>
SBCS <		mov	ss:prevChar, al					>
DBCS <		mov	ss:prevChar, ax					>
		jmp	getMessageChar
	;
	; Done with this message -- NULL-terminate it and resize the chunk
	; to the size of the text.  We back up and wipe out the last <CR>...
	;
doneMessage:
		mov	ss:chunkSize, dx
		call	resizeChunk
		LocalPrevChar esdi
		clr	ax			;ax <- NULL
		LocalPutChar esdi, ax
	;
	; Go back and do it again
	;
		jmp	skipBlankLoop

doneChars:
	;
	; Free the source block
	;
		pop	ax
		xchg	ax, bx			;bx <- handle of source block
		call	MemFree
		mov_tr	bx, ax			;bx <- handle of dest block
	;
	; Return the number of messages and unlock the dest buffer
	;
		mov	cx, ss:numMessages	;cx <- # of messages found
		call	MemUnlock

		.leave
		ret

	;
	; PASS:
	;	ss:bp - locals
	;	es - seg addr of lmem heap
	; RETURN:
	;	es:di - ptr to chunk
	;
allocNewChunk:
		push	ds, cx, ax
		mov	cx, PITH_DEFAULT_CHUNK_SIZE
		mov	ss:chunkSize, cx
		segmov	ds, es			;ds <- seg addr of block
		call	LMemAlloc
		mov	ss:curChunk, ax
		mov	di, ax
		mov	di, es:[di]		;es:di <- ptr to chunk
		pop	ds, cx, ax
		retn

	;
	; PASS:
	;	ss:bp - locals
	;	es - seg addr of lmem heap
	;	es:di - ptr into chunk
	; RETURN:
	;	es:di - ptr into chunk (updated)
	;
resizeChunkBigger:
		add	ss:chunkSize, PITH_DEFAULT_CHUNK_SIZE
resizeChunk:
		push	ds, cx, ax, si
		mov	ax, ss:curChunk
		mov	si, ax
		sub	di, es:[si]		;di <- offset into chunk
		mov	cx, ss:chunkSize
		segmov	ds, es
		call	LMemReAlloc
		xchg	ax, di			;ax <- offset into chunk
		mov	di, es:[di]		;es:di <- ptr to chunk
		add	di, ax			;es:di <- ptr into chunk
		pop	ds, cx, ax, si
		retn
ConvertMessages		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipBlankLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip any blank or comment lines

CALLED BY:	ConvertMessages()
PASS:		ds:si - ptr to text
		cx - # of characters left
RETURN:		cx - 0 if no characters left
		else:
			ds:si - updated
			cx - updated
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipBlankLines		proc	near
		.enter
	;
	; Skip any blank lines or comments
	;
blankLoop:
		call	GetMessageChar
		jcxz	doneChars		;branch if reached end
		LocalCmpChar ax, C_CR		;blank line?
		je	blankLoop		;branch if blank line
	;
	; Is this a comment line?
	;
		LocalCmpChar ax, PITH_MESSAGE_COMMENT_CHAR
		jne	foundNonBlankChar
	;
	; Reached a line that starts with '#' -- skip it
	;
commentLoop:
		call	GetMessageChar
		jcxz	doneChars		;branch if reached end
		LocalCmpChar ax, C_CR		;reached eoln?
		jne	commentLoop		;loop until eoln
		jmp	blankLoop

	;
	; Back up one character
	;
foundNonBlankChar:
		LocalPrevChar dssi
		inc	cx

doneChars:

		.leave
		ret
SkipBlankLines		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMessageChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a character from the message buffer

CALLED BY:	ConvertMessages()
PASS:		ds:si - ptr into source text
		cx - # of characters left
RETURN:		cx - zero if no more characters
		else:
			ax - character
			ds:si - updated
			cx - updated
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To be DBCS compliant, this really needs to convert a buffer of DOS
	text to GEOS and attempt to parse that, since it cannot legally
	(or sanely) parse DOS text...
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMessageChar		proc	near
		.enter

nextChar:
		jcxz	done			;branch if no more chars
		LocalGetChar ax, dssi		;ax <- character of string
		dec	cx			;cx <- one less character
		LocalCmpChar ax, C_CR		;CR?
		je	charOK			;branch if CR
		LocalCmpChar ax, C_TAB		;tab?
		je	charOK			;branch if tab
		LocalCmpChar ax, ' '		;control character?
		jb	nextChar		;branch if control character
charOK:
		push	bx
		mov	bx, '_'			;bx <- default character
		call	LocalDosToGeosChar
		pop	bx
done:

		.leave
		ret
GetMessageChar		endp

PithCode	ends

