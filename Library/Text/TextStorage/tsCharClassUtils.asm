COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsCharClassUtils.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Utility routines for handling character class related stuff.
	This stuff may eventually move into the kernel

	$Id: tsCharClassUtils.asm,v 1.1 97/04/07 11:22:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharInClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a character is of a given class.

CALLED BY:	Utility
PASS:		ax	= Character to check
		bx	= CharacterClass
RETURN:		zero flag clear (nz) if character is visible
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharInClass	proc	far
if DBCS_PCGEOS
EC <	cmp	bl, CharacterClass				>
EC <	ERROR_AE ILLEGAL_CHARACTER_CLASS			>
	push	bp
	mov	bp, bx
	andnf	bp, 0x00ff
	call	cs:charClassHandlers[bp]
	pop	bp
else
EC <	cmp	bx, CharacterClass				>
EC <	ERROR_AE ILLEGAL_CHARACTER_CLASS			>
EC <	tst	ah						>
EC <	ERROR_NZ DOUBLE_BYTE_NOT_SUPPORTED			>
	call	cs:charClassHandlers[bx]	; Call the handler
endif
	ret
IsCharInClass	endp

if DBCS_PCGEOS
charClassHandlers	label	word
	word	offset cs:IsAnything			; ANYTHING
	word	offset cs:IsCharWordPartMismatch	; WORD_PART_MISMATCH
	word	offset cs:IsCharParagraphBoundary	; PARAGRAPH_BOUNDARY
	word	offset cs:IsCharWhiteSpace		; WHITE_SPACE
	word	offset cs:IsCharVisible			; VISIBLE
	word	offset cs:IsCharWordWrapBreak		; WORD_WRAP_BREAK
else
charClassHandlers	label	word
	word	offset cs:IsAnything			; ANYTHING
	word	offset cs:IsCharWordPart		; WORD_PART
	word	offset cs:IsCharNotWordPart		; NOT_WORD_PART
	word	offset cs:IsCharParagraphBoundary	; PARAGRAPH_BOUNDARY
	word	offset cs:IsCharWhiteSpace		; WHITE_SPACE
	word	offset cs:IsCharVisible			; VISIBLE
	word	offset cs:IsCharWordWrapBreak		; WORD_WRAP_BREAK
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsAnything
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Always return "true"

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) always
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsAnything	proc	near
	tst	ax		; Clear zero flag (nz)
	ret
IsAnything	endp

if DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharWordPartMismatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a character mismatches the WordPartType

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= character to check
		bh	= WordPartType to mismatch
RETURN:		zero flag (nz) if char's WordPartType mismatches
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharWordPartMismatch		proc	near
EC <	cmp	bh, WordPartType					>
EC <	ERROR_A	ILLEGAL_WORD_PART_TYPE					>
	push	ax
	call	LocalGetWordPartType
			CheckHack <WordPartType lt 256>
	cmp	al, bh			; same WordPartType?
	pop	ax
	ret
IsCharWordPartMismatch		endp

endif

if not DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharWordPart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide if a character is part of a word.

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) if character is part of a word
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharWordPart	proc	near
	call	LocalIsAlphaNumeric	; Word-part if alpha or number
	jnz	quit
	
	call	LocalIsSymbol		; Word-part if symbol
;;;	jz	quit
quit:
	ret
IsCharWordPart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharNotWordPart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide if a character is not part of a word.

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) if character is not a word part
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharNotWordPart	proc	near
	call	IsCharWordPart		; Zero flag clear (nz) if word part
	jnz	isWordPart
SBCS <	or	al, al			; Clear zero flag (nz)		>
DBCS <	or	ax, ax			; Clear zero flag (nz)		>
quit:
	ret

isWordPart:
	test	al, 0			; Set zero flag (z)
	jmp	quit
IsCharNotWordPart	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharParagraphBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide if a character is a paragraph boundary character

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) if character is a paragraph boundary
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharParagraphBoundary	proc	near
	cmp	ax, C_COLUMN_BREAK
	je	isBoundary
	cmp	ax, C_SECTION_BREAK
	je	isBoundary
	cmp	ax, C_CR
	je	isBoundary
	test	al, 0			; Always sets zero flag (z)

quit:
	ret

isBoundary:
SBCS <	or	al, al			; Always clears zero flag (nz)	>
DBCS <	or	ax, ax			; Always clears zero flag (nz)	>
	jmp	quit
IsCharParagraphBoundary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide if a character is whitespace

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) if character is whitespace
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharWhiteSpace	proc	near
	call	LocalIsSpace
	jnz	quit
	;
	; Special checks for C_COLUMN_BREAK and C_SECTION_BREAK
	;
	cmp	ax, C_COLUMN_BREAK
	je	isWhite
	cmp	ax, C_SECTION_BREAK
	jne	notWhite
isWhite:
	or	ax, ax		; Clears zero flag

quit:
	ret

notWhite:
	test	al, 0		; Sets zero flag
	jmp	quit
IsCharWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide if a character is visible

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) if character is visible
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharVisible	proc	near
SBCS <	cmp	ax, C_OPTHYPHEN						>
DBCS <	cmp	ax, C_SOFT_HYPHEN					>
	;
	; zero set (z) if invisible (optional hyphen)
	; zero clear (nz) if visible
	;
	ret
IsCharVisible	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCharWordWrapBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide if a character is suitable for word-wrapping at.

CALLED BY:	IsCharInClass via charClassHandlers
PASS:		ax	= Character to check
RETURN:		zero flag clear (nz) if character is suitable
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsCharWordWrapBreak	proc	near
	;
	; The following characters are valid:
	;	C_SPACE
	;	C_TAB
	;	C_CR
	;	C_SECTION_BREAK
	;	C_COLUMN_BREAK
	;	C_HYPHEN
	;	C_OPTHYPHEN
	;	C_ENDASH
	;	C_EMDASH
	;
	
	cmp	ax, C_SPACE
	je	isSuitable

	cmp	ax, C_TAB
	je	isSuitable

	cmp	ax, C_CR
	je	isSuitable

	cmp	ax, C_SECTION_BREAK
	je	isSuitable

	cmp	ax, C_COLUMN_BREAK
	je	isSuitable

	cmp	ax, C_HYPHEN
	je	isSuitable

SBCS <	cmp	ax, C_OPTHYPHEN						>
DBCS <	cmp	ax, C_SOFT_HYPHEN					>
	je	isSuitable

SBCS <	cmp	ax, C_ENDASH						>
DBCS <	cmp	ax, C_EN_DASH						>
	je	isSuitable

SBCS <	cmp	ax, C_EMDASH						>
DBCS <	cmp	ax, C_EM_DASH						>
	je	isSuitable

	test	al, 0		; Sets zero flag

quit:
	ret

isSuitable:
	or	ax, ax		; Clears zero flag
	jmp	quit
IsCharWordWrapBreak	endp



TextFixed	ends
