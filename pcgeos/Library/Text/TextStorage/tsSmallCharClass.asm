COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsSmallCharClass.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Character class stuff for small objects.

	$Id: tsSmallCharClass.asm,v 1.1 97/04/07 11:22:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintMessage <JOHN: Check resource segmentation here>
TextSelect	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallNextCharInClass
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
SmallNextCharInClass	proc	near
	class	VisTextClass
	uses	bx, cx, si, bp
	.enter
EC <	tst	dx						>
EC <	ERROR_NZ CAN_NOT_SKIP_MORE_THAN_64K_IN_SMALL_OBJECT	>

	push	ax			; Save starting offset
	mov	cx, ax			; cx <- offset to start at
	call	SmallGetTextSize	; dx.ax <- size of object
	mov	bp, ax			; Save size in bp
	sub	ax, cx			; ax <- number of bytes left in text
	mov	dx, ax			; Save number of bytes left in text
	mov	cx, ax
	pop	ax			; Restore starting offset

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset

	mov	si, ds:[si].VTI_text
	mov	si, ds:[si]		; ds:si <- pointer to text base
DBCS <	add	si, ax							>
	add	si, ax			; ds:si <- pointer to place to start
	
	push	ax			; Save starting offset again
	;
	; bp	= Size of the object
	; bx	= CharacterClass indicating the characters to skip over
	; cx,dx	= Number of bytes left in text
	; ds:si	= Pointer to the text
	; On stack:
	;	starting offset
	;
	jcxz	endLoop
SBCS <	clr	ah			; Always want high byte clear	>

skipLoop:
SBCS <	clr	ax							>
SBCS <	lodsb				; ax <- next character		>
DBCS <	lodsw				; ax <- next character		>
	call	IsCharInClass		; <nz> if in class
	jnz	endLoop			; If it is, quit loop
	dec	cx			; One less character
	jnz	skipLoop		; Loop if more to do

endLoop:
	pop	ax			; ax <- starting offset
	
	jcxz	noCharOfClass		; Branch if skipped all the text
	
	sub	dx, cx			; dx <- # of characters skipped
	add	ax, dx			; ax <- ending offset
	clr	dx			; dx.ax <- ending offset
					; Clear's the carry indicating that
					;    we did find a character of the class
quit:
	.leave
	ret

noCharOfClass:
	;
	; There was no character of the given class to find
	;
	clr	dx			; dx.ax <- last valid offset
	mov	ax, bp
	stc				; Signal: no characters of this class
	jmp	quit
SmallNextCharInClass	endp

TextSelect	ends

TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallPrevCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip to the previous character in a given class

CALLED BY:	TS_PrevCharInClass via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to start at
		bx	= CharacterClass
RETURN:		dx.ax	= Offset of previous character of this class
		carry set if there is no next character of this class
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
SmallPrevCharInClass	proc	near
	class	VisTextClass
	uses	bx, cx, si
	.enter
EC <	tst	dx						>
EC <	ERROR_NZ CAN_NOT_SKIP_MORE_THAN_64K_IN_SMALL_OBJECT	>

	push	ax			; Save starting offset
	mov	cx, ax			; cx <- offset to start at

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	
	mov	si, ds:[si].VTI_text
	mov	si, ds:[si]		; ds:si <- pointer to base of text
DBCS <	add	si, cx							>
	add	si, cx			; ds:si <- pointer to place to start
	;
	; bx	= CharacterClass indicating the characters to skip over
	; cx	= Number of bytes left in text
	; ds:si	= Pointer to the text
	; On stack:
	;	starting offset
	;
	jcxz	noCharOfClass
SBCS <	clr	ah			; Always want high byte clear	>

skipLoop:
	dec	si			; Move to previous character
DBCS <	dec	si							>
SBCS <	clr	ax							>
SBCS <	mov	al, {byte} ds:[si]	; ax <- next character		>
DBCS <	mov	ax, {wchar} ds:[si]	; ax <- next character		>

	dec	cx			; One less character

	call	IsCharInClass		; <nz> if in class
	jnz	endLoop			; If it is, quit loop
	tst	cx			; Check for more to do
	jnz	skipLoop		; Loop if more to do

	jmp	noCharOfClass

endLoop:
	pop	ax			; ax <- starting offset
	
	mov	ax, cx			; ax <- ending offset
	clr	dx			; dx.ax <- ending offset
					; Clear's the carry indicating that
					;    we did find a character of the class
quit:
	.leave
	ret

noCharOfClass:
	;
	; There was no character of the given class to find
	;
	pop	ax			; Clean up stack
	clrdw	dxax			; dx.ax <- first valid offset
	stc				; Signal: no characters of this class
	jmp	quit
SmallPrevCharInClass	endp


TextFixed	ends
