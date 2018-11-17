COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		charClass.asm

AUTHOR:		John Wedgwood, Dec  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	IsUpper			Is a character uppercase?
	IsLower			Is a character lowercase?
	IsAlpha			Is a character a text character?
	IsSpace			Is a character white space?
	IsPunctuation		Is a character a punctuation character?
	IsLigature		Is a character a ligature?
	IsSymbol		Is a character a symbol character?
	IsControl		Is a character a control character?
	IsDigit			Is a character a digit?
	IsHexDigit		Is a character a hex digit?
	IsPrintable		Is a character a printable character?	
	IsGraphic		Is a character a graphic character?
	IsAlphaNumeric		Is a character a digit or text character?
	IsDateChar		Is character part of a legal date?
	IsTimeChar		Is character part of a legal time?
	IsNumChar		Is character part of a legal number?
	LexicalValue		Return lexical value of character
	LexicalValueNoCase	Return 1st order lexical value of character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/ 6/90	Initial revision
	schoon 	4/13/92		Updated to Ansi C standard

DESCRIPTION:
	Character class table and routines.

	$Id: stringChar.asm,v 1.1 97/04/05 01:16:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DBCS_PCGEOS
StringMod	segment	resource
else
StringCmpMod	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsAlpha, LocalIsSpace, LocalIsPunctuation
		LocalIsSymbol, LocalIsUpper, LocalIsLower, LocalIsControl,
		LocalIsDigit, LocalIsHexDigit, LocalIsAlphaNumeric,
		LocalIsPrintable, LocalIsGraphic, 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Functions which check bits in the classTable

CALLED BY:	Utility
PASS:		ax	= Character to check
RETURN:		zero flag: clear (nz) if the character is alpha, numeric, or
				whatever the function implies
			   set (z) if the character is not alpha, etc...
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DBCS_PCGEOS

LocalIsAlpha	proc	far
	push	bx
	mov	bx, mask CC_ALPHA
	GOTO	TextCommon, bx
LocalIsAlpha	endp

LocalIsSpace	proc	far
	push	bx
	mov	bx, mask CC_SPACE
	GOTO	TextCommon, bx
LocalIsSpace	endp

LocalIsPunctuation	proc	far
	push	bx
	mov	bx, mask CC_PUNCTUATION
	GOTO	TextCommon, bx
LocalIsPunctuation	endp

LocalIsSymbol	proc	far
	push	bx
	mov	bx, mask CC_SYMBOL
	GOTO	TextCommon, bx
LocalIsSymbol	endp

LocalIsUpper	proc	far
	push	bx
	mov	bx, mask CC_UPPER
	GOTO	TextCommon, bx
LocalIsUpper	endp

LocalIsLower	proc	far
	push	bx
	mov	bx, mask CC_LOWER
	GOTO	TextCommon, bx	
LocalIsLower	endp

LocalIsControl	proc	far
	push	bx
	mov	bx, mask CC_CONTROL
	GOTO	TextCommon, bx	
LocalIsControl	endp

LocalIsDigit	proc	far
	push	bx
	mov	bx, mask CC_DIGIT
	GOTO	TextCommon, bx
LocalIsDigit	endp

LocalIsHexDigit	proc	far
	push	bx
	mov	bx, mask CC_HEX
	GOTO	TextCommon, bx
LocalIsHexDigit endp

LocalIsAlphaNumeric proc	far
	push	bx
	mov	bx, mask CC_ALPHA or mask CC_DIGIT
	GOTO	TextCommon, bx
LocalIsAlphaNumeric endp

LocalIsPrintable proc	far
	push	bx
	mov	bx, mask CC_PRINTABLE
	GOTO	TextCommon, bx
LocalIsPrintable	endp

LocalIsGraphic	proc	far
	push	bx
	mov	bx, mask CC_GRAPHIC
	FALL_THRU	TextCommon, bx
LocalIsGraphic 	endp

;---

TextCommon	proc	far

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	push	si
	mov	si, ax
	shl	si, 1				;CharClassTable has word 
						;entries, so shift left 1
	test	cs:CharClassTable[si], bx
	pop	si

	FALL_THRU_POP	bx

	ret
TextCommon	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsDateChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if character is part of valid date
CALLED BY:	DR_LOCAL_IS_DATE_CHAR

PASS:		ax - character to check
RETURN:		z flag - clear if part of valid date
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsDateChar	proc	far

if PZ_PCGEOS	;------------------------------------------------------------
	push	ax, bx, es, di, si
	sub	sp, size GengoNameData
	mov	di, sp
	segmov	es, ss
	mov	bx, ax
	clr	ax
nextName:
	call	LocalGetGengoInfo
	jc	notValid			;no more, not valid
	lea	si, es:[di].GND_shortName
nextChar:
	cmp	{wchar} es:[si], 0
	jz	endName
	cmp	bx, {wchar} es:[si]
	je	valid				;valid, done
	LocalNextChar	essi
	jmp	short nextChar

endName:
	inc	ax				;try next GengoNameData
	jmp	short nextName

notValid:
	cmp	ax, ax				;set Z flag
	jmp	short haveAnswer

valid:
	cmp	ax, -1				;clear Z flag
haveAnswer:
	lea	sp, es:[di][(size GengoNameData)]
	pop	ax, bx, es, di, si
	jz	checkMore			;not valid, check others
	ret

checkMore:
endif	;---------------------------------------------------------------------

	push	di
	push	si
	mov	si, DTF_SHORT			;use short format to check
	mov	di, offset DateChars
	jmp	CheckDateTimeChar
LocalIsDateChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsTimeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if character is part of valid time string
CALLED BY:	DR_LOCAL_IS_TIME_CHAR

PASS:		ax - character to check
RETURN:		z flag - clear if part of valid time
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsTimeChar	proc	far
	push	di
	push	si
	mov	si, DTF_HMS			;use HMS format to check
	mov	di, offset TimeChars
	REAL_FALL_THRU	CheckDateTimeChar
LocalIsTimeChar	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDateTimeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if character is part of valid date or time string
CALLED BY:	DR_LOCAL_IS_TIME_CHAR

PASS:		ax - character to check
		si - format to check for character in
		di - pointer to other chars to check
		on stack - old si, di
RETURN:		z flag - clear if part of valid time
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	1/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDateTimeChar	proc	far
if not DBCS_PCGEOS
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif
	call	IsLegalFormatChar
	pop	si
	jz	CheckCharGroup			;no match, try some more chars
	pop	di
	ret
CheckDateTimeChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsNumChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if character is part of a valid number
CALLED BY:	DR_LOCAL_IS_NUM_CHAR

PASS:		ax - character to check
RETURN:		z flag - clear if part of valid time
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalIsNumChar	proc	far

if DBCS_PCGEOS
EC <	tst	ah							>
EC <	WARNING_NZ LARGE_VALUE_FOR_CHARACTER				>
endif
	push	cx
	push	ax, bx, dx
	call	LocalGetNumericFormat		;returns decimal in bl
	pop	ax, bx, dx
	cmp	ax, cx				;is this the decimal point?
	pop	cx

	jnz	tryOthers			;no, branch

	; clear zero flag

	push	ax
	or	al, 1
	pop	ax
	ret
	
tryOthers:
	push	di
	mov	di, offset NumChars
	REAL_FALL_THRU	CheckCharGroup
LocalIsNumChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCharGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check string resource a character
CALLED BY:	NumChar() IsTimeChar(), IsDateChar()

PASS:		ax - character to check
		di - lmem handle of char group resource
		saved di - on stack
RETURN:		z flag - clear if part of character group
		di - popped off stack
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCharGroup	proc	far
	uses	ax, cx, ds, es
	.enter

	call	LockStringsDS
	segmov	es, ds
	mov	di, es:[di]			;es:di <- ptr to resouce
	ChunkSizePtr	es, di, cx		;cx <- size of resource
DBCS <	shr	cx, 1				;cx <- # of chars	>
	LocalFindChar				;repne scasb/scasw

	call	UnlockStrings
	lahf					;ah <- flags
	xor	ah, mask CPU_ZERO		;toggle 'z' flag
	sahf					;restore flags

	.leave
	pop	di
	ret
CheckCharGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalLexicalValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return lexical value of a character
CALLED BY:	DR_LOCAL_LEXICAL_VALUE

PASS:		ax - character
RETURN:		ax - LexicalOrder of character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DBCS_PCGEOS

LocalLexicalValue	proc	far
	uses	di
	.enter

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	di, ax				;di.low <- character
	mov	al, cs:LexicalOrderTable[di]	;al <- LexicalOrder of char

	.leave
	ret
LocalLexicalValue	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalLexicalValueNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return case-insenstive lexical value of a character
CALLED BY:	DR_LOCAL_LEXICAL_VALUE_NO_CASE

PASS:		ax - character
RETURN:		ax - Lex1stOrder of character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DBCS_PCGEOS

LocalLexicalValueNoCase	proc	far
	uses	di
	.enter

EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	di, ax				;di.low <- character
	mov	al, cs:Lexical1stOrderTable[di]	;al <- LexicalOrder of char

	.leave
	ret
LocalLexicalValueNoCase	endp

endif

if DBCS_PCGEOS
StringMod	ends
else
StringCmpMod	ends
endif

