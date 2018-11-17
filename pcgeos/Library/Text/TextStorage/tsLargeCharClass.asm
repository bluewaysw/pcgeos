COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsLargeCharClass.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Character class code for large objects

	$Id: tsLargeCharClass.asm,v 1.1 97/04/07 11:22:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintMessage <JOHN: Check resource segmentation here>
TextSelect	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeNextCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip to the next character in a given class

CALLED BY:	TS_NextCharInClass via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
		bx	= CharacterClass
RETURN:		dx.ax	= Offset of next character of this class
		carry set if there is no next character of this class
		If no character of this class was found dx.ax will hold
			the offset of the end of the text object.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeNextCharInClass	proc	near
	class	VisTextClass
	uses	bx, cx, di, si, bp, ds
vmfile		local	word
bytesLeft	local	dword
	.enter
	;
	; Compute the number of bytes between the current offset and the
	; end of the object.
	;
	push	bx			; Save char class
	call	T_GetVMFile
	mov	vmfile, bx
	movdw	cxbx, dxax		; cx.bx <- starting offset
	call	LargeGetTextSize	; dx.ax <- size of object
	;
	; If the offset is greater than the number of characters, then
	; we just return that we could not find the character. -Don 6/3/95
	;
	cmpdw	dxax, cxbx
	jb	endOfText

	subdw	dxax, cxbx		; dx.ax <- distance to the end
	incdw	dxax			; Allow for a NULL
	movdw	bytesLeft, dxax		; Save number to check
	movdw	dxax, cxbx		; dx.ax <- starting offset
	pop	bx			; Restore char class

	;
	; Get the array
	;
	call	TextSelect_DerefVis_DI
	mov	di, ds:[di].VTI_text	; di <- huge-array handle
;-----------------------------------------------------------------------------
chunkLoop:
	;
	; di	= Huge-array
	; bytesLeft = # of bytes to search through
	; dx.ax	= Current offset to look from
	; bx	= CharacterClass
	;
	tstdw	bytesLeft		; Check for nothing left
	jz	noCharInClass		; Branch if nothing left

	pushdw	dxax			; Save offset
	push	bx
	mov	bx, vmfile
	call	HugeArrayLock		; ds:si <- ptr to the text
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
	pop	bx			; ax <- # after ptr
					; cx <- # before
					; dx <- element size (1)
	mov	cx, ax			; cx <- # after ptr
	popdw	dxax			; Restore offset

	push	ax, cx			; Save offset.low, # to check
searchLoop:
	;
	; ds:si	= Text
	; cx	= Number of characters to check
	; bx	= CharacterClass
	;
SBCS <	clr	ax							>
SBCS <	lodsb				; ax <- next character		>
DBCS <	lodsw								>
	call	IsCharInClass		; <nz> if in class
	jnz	foundCharacter		; Branch if it is
	
	loop	searchLoop		; Loop to check the next one
	pop	ax, cx

	;
	; Didn't find anything in this chunk. 
	; Release the text and update the offset and count.
	;
	call	HugeArrayUnlock		; Release the chunk

if DBCS_PCGEOS
PrintMessage <need to shift offset and/or chars left?>
endif
	add	ax, cx			; dx.ax <- offset to next byte
	adc	dx, 0
	
	sub	bytesLeft.low, cx	; bytesLeft <- # left to check
	sbb	bytesLeft.high, 0

	jmp	chunkLoop		; Loop to check next chunk
;-----------------------------------------------------------------------------

endOfText:
	pop	bx			; restore VM file handle

noCharInClass:
	;
	; Conveniently dx.ax is the offset past the NULL. If we just drop back
	; one character we are at the right offset.
	;
	decdw	dxax			; dx.ax <- offset to the null
	stc				; No character of this class found

quit:
	;
	; dx.ax	= Offset to return
	; carry set if character of class was found
	;
	.leave
	ret

foundCharacter:
	;
	; We found the character.
	; dx	= High word of offset to the start of the current chunk
	; cx	= Number left to check after the current character
	; On stack:
	;	Number of characters in the total chunk
	; 	Low word of offset to the start of the current chunk
	;
	; Release the text and update the offset and count.
	;
	call	HugeArrayUnlock		; Release the chunk

	pop	ax, bx			; dx.ax <- offset, bx <- total number
	sub	bx, cx			; bx <- number we skipped over
	
	add	ax, bx			; dx.ax <- offset to char in class
	adc	dx, 0
	
	clc				; Signal: is char of class
	jmp	quit
LargeNextCharInClass	endp

TextSelect	ends

TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargePrevCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip to the previous character in a given class

CALLED BY:	TS_PrevCharInClass via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
		bx	= CharacterClass
RETURN:		dx.ax	= Offset of previous character of this class
		carry set if there is no previous character of this class
		If no character of this class was found dx.ax will hold
			the offset of the start of the text object.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargePrevCharInClass	proc	near
	class	VisTextClass
	uses	bx, cx, di, si, bp, ds
	.enter

	mov	bp, bx
	call	T_GetVMFile		; bx = VM file
	xchg	bx, bp			;bp = vm file

	tstdw	dxax			; Check for nothing left
	jz	noCharInClass		; Branch if nothing left
	decdw	dxax

	;
	; Get the array
	;
	call	TextFixed_DerefVis_DI
	mov	di, ds:[di].VTI_text	; di <- huge-array handle
;-----------------------------------------------------------------------------
chunkLoop:
	;
	; di	= Huge-array
	; dx.ax	= Current offset to look from
	; bx	= CharacterClass
	;
	tst	dx			; Check for gone past start
	js	noCharInClass		; Branch if nothing left

	pushdw	dxax			; Save offset
	push	bx
	mov	bx, bp
	call	HugeArrayLock		; ds:si <- ptr to the text
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
	pop	bx			; ax <- # after ptr
					; cx <- # before
					; dx <- element size (1)
	popdw	dxax			; Restore offset

	push	ax, cx			; Save offset.low, # to check
searchLoop:
	;
	; ds:si	= Text
	; cx	= Number of characters to check
	; bx	= CharacterClass
	;
SBCS <	clr	ax							>
SBCS <	mov	al, ds:[si]		; al <- character		>
DBCS <	mov	ax, ds:[si]		; al <- character		>
	call	IsCharInClass		; <nz> if in class
	jnz	foundCharacter		; Branch if it is
	
	dec	si			; Move to previous character
DBCS <	dec	si							>
	loop	searchLoop		; Loop to check the next one
	pop	ax, cx

	;
	; Didn't find anything in this chunk. 
	; Release the text and update the offset and count.
	;
	call	HugeArrayUnlock		; Release the chunk

if DBCS_PCGEOS
PrintMessage <need to shift offset and/or chars left?>
endif
	sub	ax, cx			; dx.ax <- offset to previous byte
	sbb	dx, 0
	
	jmp	chunkLoop		; Loop to check next chunk
;-----------------------------------------------------------------------------

noCharInClass:
	clrdw	dxax			; dx.ax <- offset to start
	stc				; No character of this class found

quit:
	;
	; dx.ax	= Offset to return
	; carry set if character of class was found
	;
	.leave
	ret

foundCharacter:
	;
	; We found the character.
	; dx	= High word of offset to the end of the current chunk
	; cx	= Number left to check after the current character
	; On stack:
	;	Number of characters in the total chunk
	;	Low word of offset to the end of the current chunk
	;
	; Release the text.
	;
	call	HugeArrayUnlock		; Release the chunk

	pop	ax, bx			; dx.ax <- offset, bx <- total number
	sub	bx, cx			; bx <- number we skipped over
	
	sub	ax, bx			; dx.ax <- offset to char in class
	sbb	dx, 0
	
	clc				; Signal: is char of class
	jmp	quit
LargePrevCharInClass	endp

TextFixed	ends
