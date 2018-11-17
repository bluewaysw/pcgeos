COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		localDBCS.asm

AUTHOR:		Gene Anderson, Sep 14, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/14/93		Initial revision


DESCRIPTION:
	DBCS specific code

	$Id: localDBCS.asm,v 1.1 97/04/05 01:17:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSConvert	segment	resource

LocalCmpStringsDosToGeos	proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LocalCodePageToGeos				>
LocalCmpStringsDosToGeos	endp

LocalCodePageToGeos		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LocalGeosToCodePage				>
LocalCodePageToGeos		endp

LocalGeosToCodePage		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LocalCodePageToGeosChar				>
LocalGeosToCodePage		endp

LocalCodePageToGeosChar		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LocalGeosToCodePageChar				>
LocalCodePageToGeosChar		endp

LocalGeosToCodePageChar		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LocalSetCodePage				>
LocalGeosToCodePageChar		endp

LocalSetCodePage		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LOCALCMPSTRINGSDOSTOGEOS			>
LocalSetCodePage		endp

LOCALCMPSTRINGSDOSTOGEOS	proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LOCALCODEPAGETOGEOS				>
LOCALCMPSTRINGSDOSTOGEOS	endp

LOCALCODEPAGETOGEOS		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LOCALGEOSTOCODEPAGE				>
LOCALCODEPAGETOGEOS		endp

LOCALGEOSTOCODEPAGE		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LOCALCODEPAGETOGEOSCHAR				>
LOCALGEOSTOCODEPAGE		endp

LOCALCODEPAGETOGEOSCHAR		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	FALL_THRU	LOCALGEOSTOCODEPAGECHAR				>
LOCALCODEPAGETOGEOSCHAR		endp

LOCALGEOSTOCODEPAGECHAR		proc	far
EC <	ERROR	FUNCTION_NOT_SUPPORTED_IN_DBCS				>
NEC <	ret								>
LOCALGEOSTOCODEPAGECHAR		endp

DOSConvert	ends

StringMod	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsUpper, LocalIsLower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Functions which character type

CALLED BY:	GLOBAL
PASS:		ax	= Character to check
RETURN:		zero flag: clear (nz) if the character is upper or
				whatever the function implies
			   set (z) if the character is not upper, etc...
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsUpper	proc	far
		push	ax, bx
		call	DowncaseCharInt
		jnc	setZ			;branch if not downcased
clearZ	label	near
		inc	bx			;<- clear Z flag
		pop	ax, bx
		ret
LocalIsUpper	endp

LocalIsLower	proc	far
		push	ax, bx
		call	UpcaseCharInt
		jc	clearZ			;branch if not upcased
setZ	label	near
		clr	ax			;<- set Z flag
		pop	ax, bx
		ret
LocalIsLower	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsAlpha, LocalIsSpace, LocalIsPunctuation
		LocalIsSymbol, LocalIsUpper, LocalIsLower, LocalIsControl,
		LocalIsDigit, LocalIsHexDigit, LocalIsAlphaNumeric,
		LocalIsPrintable, LocalIsGraphic, 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Functions which character type

CALLED BY:	GLOBAL
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
	eca	10/ 6/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsKana	proc	far
		push	bx
		mov	bx, offset kanaTypeTable
		GOTO	CheckCharType, bx
LocalIsKana	endp

LocalIsKanji	proc	far
		push	bx
		mov	bx, offset kanjiTypeTable
		GOTO	CheckCharType, bx
LocalIsKanji	endp

LocalIsAlphaNumeric proc	far
		call	LocalIsAlpha
		jnz	isAlphaNumeric
		call	LocalIsDigit
isAlphaNumeric:
		ret
LocalIsAlphaNumeric endp

LocalIsSymbol	proc	far
		FALL_THRU	LocalIsPunctuation
LocalIsSymbol	endp
LocalIsPunctuation	proc	far
		push	bx
		mov	bx, offset puncTypeTable
		GOTO	CheckCharType, bx
LocalIsPunctuation	endp

LocalIsSpace	proc	far
		push	bx
		mov	bx, offset spaceTypeTable
		GOTO	CheckCharType, bx
LocalIsSpace	endp

LocalIsControl	proc	far
		push	bx
		mov	bx, offset controlTypeTable
		GOTO	CheckCharType, bx
LocalIsControl	endp

LocalIsDigit	proc	far
		push	bx
		mov	bx, offset digitTypeTable
		GOTO	CheckCharType, bx
LocalIsDigit	endp

LocalIsHexDigit	proc	far
		push	bx
		mov	bx, offset hexTypeTable
		GOTO	CheckCharType, bx
LocalIsHexDigit endp

LocalIsPrintable proc	far
		push	bx
		mov	bx, offset printableTypeTable
		GOTO	CheckCharType, bx
LocalIsPrintable	endp

LocalIsGraphic	proc	far
		push	bx
		mov	bx, offset graphicTypeTable
		GOTO	CheckCharType, bx
LocalIsGraphic 	endp

LocalIsAlpha	proc	far
		push	bx
		mov	bx, offset alphaTypeTable
		FALL_THRU	CheckCharType, bx
LocalIsAlpha	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCharType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if a character is of a particular type

CALLED BY:	UTILITY
PASS:		ax - character to check
		cs:bx - ptr to table of CharTypeStruct
		ax	= Character to check
		on stack:
			saved bx
RETURN:		zero flag: clear (nz) if the character is alpha, numeric, or
				whatever the function implies
			   set (z) if the character is not alpha, etc...
		cx:bx - ptr to matching CharTypeStruct
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: the last entry in the table should be C_LAST_UNICODE_CHARACTER
	NOTE: the entries should be sorted by character value
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 6/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCharType		proc	far
		.enter

EC <		call	ECCheckCharTypeTable				>
	;
	; See if the character is in this range
	;
charLoop:
		cmp	ax, cs:[bx].CTS_end
		jbe	gotEntry
	;
	; Character is not in current range -- go to next
	;
		add	bx, (size CharTypeStruct)
		jmp	charLoop

	;
	; Found the correct entry -- test for correct type
	;
gotEntry:
		test	cs:[bx], mask CT_CHAR_IN_CLASS

		.leave
		FALL_THRU_POP	bx
		ret
CheckCharType		endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCharTypeTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a CharTypeStruct table is valid

CALLED BY:	CheckCharType()
PASS:		cs:bx - ptr to table of CharTypeStructs
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 7/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCharTypeTable		proc	far
		uses	ax, bx, dx
		.enter

		pushf

		mov	dl, cs:[bx].CTS_flags
		xor	dl, mask CT_CHAR_IN_CLASS
		shr	dl, 1
charLoop:
	;
	; Verify no unused flags are set
	;
		mov	dh, cs:[bx].CTS_flags
		test	dh, not (mask CharType)
		ERROR_NZ ILLEGAL_CHAR_TYPE_TABLE
	;
	; Make sure the table entries for char in class are alternating
	;
		ornf	dl, dh
		test	dl, mask CT_CHAR_IN_CLASS or \
				(mask CT_CHAR_IN_CLASS shr 1)
		ERROR_PE ILLEGAL_CHAR_TYPE_TABLE
		andnf	dl, not (mask CT_CHAR_IN_CLASS shr 1)
		shr	dl, 1
	;
	; Check for the end of the table
	;
		mov	ax, cs:[bx].CTS_end
		cmp	ax, C_LAST_UNICODE_CHARACTER
		je	done
	;
	; Make sure the entries are in increasing order
	;
		cmp	ax, cs:[bx][(CharTypeStruct)].CTS_end
		ERROR_AE ILLEGAL_CHAR_TYPE_TABLE
	;
	; Move to the next entry
	;
		add	bx, (size CharTypeStruct)
		jmp	charLoop

done:
		popf

		.leave
		ret
ECCheckCharTypeTable		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpcaseCharInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upcase a character

CALLED BY:	LocalUpcaseChar(), ConvertString()
PASS:		ax - character to upcase
RETURN:		ax - character, upcased
		cs:bx - ptr to CharCaseStruct
		carry - set if character upcased
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpcaseCharInt		proc	near
		uses	dx
		.enter

	;
	; Get the CharCaseStruct entry
	;
		call	FindCaseEntry
		jnz	isPairs			;branch if in pairs
	;
	; Check for no change needed (clear carry)
	;
		test	dl, mask CCF_LOWERCASE
		jz	done			;branch if not lowercase
	;
	; Character is lowercase -- see if it can be upcased
	;
doUpcase:
		mov	dx, cs:[bx].CCS_convChar
		tst	dx			;any conversion char?
		jz	isCased			;branch if no conversion char
	;
	; Convert character to uppercase
	;
		add	ax, dx
		sub	ax, cs:[bx].CCS_start
isCased:
		stc				;carry <- char upcased
done:
		.leave
		ret

	;
	; Range is character pairs -- see if conversion is necessary
	; ie. if start is even/odd and char is odd/even.
	;
isPairs:
		mov	dl, {byte}cs:[bx].CCS_start
		mov	dh, al
		andnf	dx, 0x0101		;dx <- keep only low bits
		xor	dl, dh			;clears carry
		jz	done			;branch if same
		jmp	doUpcase
UpcaseCharInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DowncaseCharInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Downcase a character

CALLED BY:	LocalDowncaseChar(), ConvertString()
PASS:		ax - character to downcase
RETURN:		ax - character, downcased
		cs:bx - ptr to CharCaseStruct
		carry - set if character downcased
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DowncaseCharInt		proc	near
		uses	dx
		.enter

	;
	; Get the CharCaseStruct entry
	;
		call	FindCaseEntry
		jnz	isPairs			;branch if in pairs
	;
	; Check for no change needed (clear carry)
	;
		test	dl, mask CCF_UPPERCASE
		jz	done			;branch if not uppercase
	;
	; Character is uppercase -- see if it can be downcased
	;
doDowncase:
		mov	dx, cs:[bx].CCS_convChar
		tst	dx			;any conversion char?
		jz	isCased			;branch if no conversion char
	;
	; Convert character to uppercase
	;
		add	ax, dx
		sub	ax, cs:[bx].CCS_start
isCased:
		stc				;carry <- char upcased
done:
		.leave
		ret

	;
	; Range is character pairs -- see if conversion is necessary
	; ie. if start is even/odd and char is even/odd.
	;
isPairs:
		mov	dl, {byte}cs:[bx].CCS_start
		mov	dh, al
		andnf	dx, 0x0101		;dx <- keep only low bits
		xor	dl, dh			;clears carry
		jnz	done			;branch if same
		jmp	doDowncase
DowncaseCharInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCaseEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find entry for upcase/downcase of characters

CALLED BY:	UpcaseCharInt(), DowncaseCharInt()
PASS:		ax - character
RETURN:		cs:bx - ptr to CharCaseStruct
		z flag - clear if range of letter pairs
		dl - CharCaseFlags for entry
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCaseEntry		proc	near
		.enter

		mov	bx, offset caseTable
EC <		call	ECCheckCharCaseTable				>
charLoop:
		cmp	ax, cs:[bx][(size CharCaseStruct)].CCS_start
		jb	gotEntry
		add	bx, (size CharCaseStruct)
		cmp	bx, size caseTable
		jne	charLoop
	;
	; Get and test the flags for the entry
	;
gotEntry:
		mov	dl, cs:[bx].CCS_flags
		test	dl, mask CCF_LETTER_PAIRS

		.leave
		ret
FindCaseEntry		endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCharCaseTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify table for upcase/downcase is reasonable

CALLED BY:	FindCaseEntry()
PASS:		cs:bx - ptr to CharCaseStruct table
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/11/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCharCaseTable		proc	near
		uses	ax, bx
		.enter

		pushf
charLoop:
		mov	al, cs:[bx].CCS_flags
	;
	; Verify no unused flags are set
	;
		test	al, not (mask CharCaseFlags)
		ERROR_NZ ILLEGAL_CHAR_CASE_TABLE
	;
	; Make sure legal combinations are set
	;
		test	al, mask CCF_LETTER_PAIRS
		jz	notPairs
		test	al, mask CCF_LOWERCASE
		ERROR_NZ ILLEGAL_CHAR_CASE_TABLE
		test	al, mask CCF_UPPERCASE
		ERROR_Z ILLEGAL_CHAR_CASE_TABLE
notPairs:
	;
	; Check for the end of the table
	;
		mov	ax, cs:[bx].CCS_start
		cmp	ax, C_LAST_UNICODE_CHARACTER
		je	done
	;
	; Make sure the entries are in increasing order
	;
		cmp	ax, cs:[bx][(size CharCaseStruct)].CCS_start
		ERROR_AE ILLEGAL_CHAR_CASE_TABLE
	;
	; Move to the next entry
	;
		add	bx, (size CharCaseStruct)
		jmp	charLoop
done:
		popf

		.leave
		ret
ECCheckCharCaseTable		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalLexicalValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return lexical value of a character

CALLED BY:	GLOBAL
PASS:		ax - character (Chars)
RETURN:		ax - lexical value
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: the lexical value routines should be used with care.
	Most apps should stick to using LocalCmpStrings().
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalLexicalValue		proc	far
		.enter

if SJIS_SORTING
		call	LexValueSJISInt
endif

		.leave
		ret
LocalLexicalValue		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalLexicalValueNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return case/accent-insensitive lexical value of a character

CALLED BY:	GLOBAL
PASS:		ax - character (Chars)
RETURN:		ax - lexical value
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: the lexical value routines should be used with care.
	Most apps should stick to using LocalCmpStrings().
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalLexicalValueNoCase		proc	far
		uses	bx
		.enter

if SJIS_SORTING
		call	LexValueSJISNoWidthInt
else
		call	LexValueNCNAInt
endif

		.leave
		ret
LocalLexicalValueNoCase		endp

if not SJIS_SORTING

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LexValueNCAInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine to get accent/case-insensitive lexical value

CALLED BY:	LocalLexicalValueNoCase()
PASS:		ax - character
RETURN:		ax - lexical value
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LexValueNCNAInt		proc	near
		uses	cx, dx
		.enter

		mov	bx, offset sortTable
EC <		call	ECCheckSortTable				>
	;
	; Loop to find matching entry
	;
charLoop:
		cmp	ax, cs:[bx][(size CharSortStruct)].CSS_start
		jb	gotEntry
		add	bx, (size CharSortStruct)
		cmp	bx, size sortTable
		jne	charLoop

gotEntry:
		sub	ax, cs:[bx].CSS_start	;ax <- offset from range start
		mov	dl, cs:[bx].CSS_flags	;dl <- flags for entry
	;
	; Check for indexed table
	;
		test	dl, mask CSF_IS_TABLE
		jnz	isTable			;branch if indexed table
	;
	; Check for not single value
	;
		test	dl, mask CSF_CONVERT_SINGLE
		mov	cx, cs:[bx].CSS_cmpChar	;dx <- lexical value
		jz	isRelative		;branch if not single value
	;
	; Simple case -- range mapped to single value
	;
		mov_tr	ax, cx
done:

		.leave
		ret
	;
	; Values are relative to comparison character -- adjust
	;
isRelative:
		add	ax, cx 			;ax <- lexical value
		jmp	done

	;
	; Values are in a separate indexed table
	;
isTable:
		shl	ax, 1			;ax <- table of words
		mov	bx, cs:[bx].CSS_cmpChar	;cs:bx <- ptr to new table
		mov	ax, cs:[bx]		;ax <- lexical value
		jmp	done

LexValueNCNAInt		endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSortTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a table of CharSortStructs()

CALLED BY:	LexValueNCInt()
PASS:		cs:bx - ptr to table CharSortStructs
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSortTable		proc	near
		uses	ax, bx
		.enter

charLoop:
	;
	; Verify no unused flags are set
	;
		test	cs:[bx].CSS_flags, not (mask CharSortFlags)
		ERROR_NZ ILLEGAL_CHAR_SORT_TABLE
	;
	; Check for the end of the table
	;
		mov	ax, cs:[bx].CSS_start
		cmp	ax, C_LAST_UNICODE_CHARACTER
		je	done
	;
	; Make sure the entries are in increasing order
	;
		cmp	ax, cs:[bx][(size CharSortStruct)].CSS_start
		ERROR_AE ILLEGAL_CHAR_SORT_TABLE
	;
	; Move to the next entry
	;
		add	bx, (size CharSortStruct)
		jmp	charLoop

done:

		.leave
		ret
ECCheckSortTable		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LexValueNAInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine to get accent-insensitive lexical value

CALLED BY:	CmpCharsInt()
PASS:		ax - character
RETURN:		ax - character w/o accent
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/19/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LexValueNAInt		proc	near
		uses	cx, dx
		.enter

		mov	bx, offset accentTable
EC <		call	ECCheckSortTable				>
	;
	; Loop to find matching entry
	;
charLoop:
		cmp	ax, cs:[bx][(size CharSortStruct)].CSS_start
		jb	gotEntry
		add	bx, (size CharSortStruct)
		cmp	bx, size accentTable
		jne	charLoop

gotEntry:
		sub	ax, cs:[bx].CSS_start	;ax <- offset from range start
		mov	dl, cs:[bx].CSS_flags	;dl <- flags for entry
	;
	; Check for not single value
	;
		test	dl, mask CSF_CONVERT_SINGLE
		mov	cx, cs:[bx].CSS_cmpChar	;dx <- lexical value
		jz	isRelative		;branch if not single value
	;
	; Check for upper/lowercase pairs
	;
		test	dl, mask CSF_LETTER_PAIRS
		jnz	isPairs			;branch if upper/lower pairs
	;
	; Simple case -- range mapped to single value
	;
doneSet:
		mov_tr	ax, cx
done:

		.leave
		ret
	;
	; Values are relative to comparison character -- adjust
	;
isRelative:
		add	ax, cx 			;ax <- lexical value
		jmp	done

	;
	; Range is character pairs -- see if conversion is necessary
	; ie. if start is even/odd and char is odd/even.
	;
isPairs:
		mov	dl, cl			;dl <- low bit of cmpChar
		mov	dh, al
		andnf	dx, 0x0101		;dx <- keep only low bits
		xor	dl, dh			;clears carry
		jz	doneSet			;branch if same
	;
	; Make the (hopefully valid) assumption that if we are mapping
	; pairs, we are mapping them to the ASCII range.
	;
EC <		cmp	cx, 'A'						>
EC <		ERROR_B ILLEGAL_CHAR_SORT_TABLE				>
EC <		cmp	cx, 'Z'						>
EC <		ERROR_A ILLEGAL_CHAR_SORT_TABLE				>
		add	cx, 'a'-'A'		;ax <- adjust to lowercase
		jmp	doneSet
LexValueNAInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpCharsInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two characters, taking into account case, etc.

CALLED BY:	DoStringCompare(), LocalCmpChars()
PASS:		dx - source char
		ax - dest char
RETURN:		c, z - flags set as for cmp dx, ax
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpCharsInt		proc	near
		.enter
	;
	; Special case already equal strings
	;
		cmp	dx, ax			;set flags for cmp src, dest
		je	done			;branch if equal
	;
	; Compare ignoring accents only.  This is to take into account
	; the fact that uppercase accent letters are after lowercase
	; letters in Unicode.
	;
		push	ax, dx
		call	LexValueNAInt		;ax <- lexical value of dest
		xchg	ax, dx			;ax <- source char
		call	LexValueNAInt		;ax <- lexical value of src
		cmp	ax, dx			;set flags for cmp src, dest
		pop	ax, dx
		jne	done			;branch if not equal
	;
	; Compare taking into account case, accents, etc.
	;
		cmp	dx, ax			;set flags for cmp src, dest
done:

		.leave
		ret
CmpCharsInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpCharsNoCaseInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two characters, ignoring case, accents, etc.

CALLED BY:	DoStringCompare(), LocalCmpChars(), LocalCmpCharsNoCase()
PASS:		dx - source char
		ax - dest char
RETURN:		c, z - flags set as for cmp dx, ax
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpCharsNoCaseInt		proc	near
		.enter
	;
	; Get lexical value of chars ignoring case and accent
	;
		call	LexValueNCNAInt		;ax <- lexical value of dest
		xchg	ax, dx			;ax <- source char
		call	LexValueNCNAInt		;ax <- lexical value of src
	;
	; Compare ignoring case and accent
	;
		cmp	ax, dx			;set flags for cmp src, dest

		.leave
		ret
CmpCharsNoCaseInt		endp

else


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LexValueSJISInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine to get SJIS value of a character

CALLED BY:	CmpCharsSJISInt()
PASS:		ax - character
RETURN:		carry - clear
			ax - SJIS value
		else:
			ax - character
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LexValueSJISInt		proc	near
		uses	cx, dx
		.enter

		mov	cx, ax			;cx <- save char
		mov	bx, CODE_PAGE_SJIS	;bx <- DosCodePage
		clr	dx			;dx <- use primary FSD
		call	LocalGeosToDosChar
		jc	noConvert		;branch if not convertable
done:
		.leave
		ret

noConvert:
		mov_tr	ax, cx			;ax <- orginal value
		jmp	done
LexValueSJISInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LexValueSJISNoWidthInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal routine to get SJIS value of a character,
		ignoring case and fullwidth vs. halfwidth.

CALLED BY:	CmpCharsSJISNoWidthInt()
PASS:		ax - character
RETURN:		ax - SJIS value (ignoring case and fullwidth vs. halfwidth)
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LexValueSJISNoWidthInt		proc	near
		.enter

	;
	; Upcase all characters
	;
		call	UpcaseCharInt
	;
	; Map fullwidth and halfwidth to equivalents
	;
		cmp	ah, (C_FULLWIDTH_EXCLAMATION_MARK shr 8)
		jne	getValue
	;
	; Check for fullwidth ASCII
	;
		cmp	ax, C_FULLWIDTH_SPACING_TILDE
		ja	notASCII
		sub	ax, C_FULLWIDTH_EXCLAMATION_MARK-C_EXCLAMATION_MARK
		jmp	getValue
	;
	; Check for halfwidth katakana
	;
notASCII:
		cmp	ax, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
		ja	getValue
		sub	ax, C_HALFWIDTH_KATAKANA_LETTER_WO
		shl	ax, 1			;ax <- table of words
		mov_tr	bx, ax
		mov	ax, cs:halfwidthKatakana[bx]
	;
	; Get the SJIS value of the character
	;
getValue:
		call	LexValueSJISInt

		.leave
		ret
LexValueSJISNoWidthInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpCharsSJISInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two characters using SJIS ordering

CALLED BY:	DoStringCompare(), LocalCmpChars()
PASS:		dx - source char
		ax - dest char
RETURN:		c, z - flags set as for cmp dx, ax
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpCharsSJISInt		proc	near
		.enter
	;
	; Special case already equal strings
	;
		cmp	dx, ax			;set flags for cmp src, dest
		je	done			;branch if equal
	;
	; Compare SJIS values
	;
		push	ax, dx
		call	LexValueSJISInt		;ax <- lexical value of dest
		xchg	ax, dx			;ax <- source char
		call	LexValueSJISInt
		cmp	ax, dx			;set flags for cmp src, dest
		pop	ax, dx
done:

		.leave
		ret
CmpCharsSJISInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpCharsSJISNoWidthInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two characters using SJIS ordering, ignoring case
		and fullwidth vs. halfwidth

CALLED BY:	DoStringCompare(), LocalCmpCharsNoCase()
PASS:		dx - source char
		ax - dest char
RETURN:		c, z - flags set as for cmp dx, ax
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CmpCharsSJISNoWidthInt		proc	near
		.enter
	;
	; Special case already equal strings
	;
		cmp	dx, ax			;set flags for cmp src, dest
		je	done			;branch if equal
	;
	; Compare SJIS values
	;
		push	ax, dx
		call	LexValueSJISNoWidthInt	;ax <- lexical value of dest
		xchg	ax, dx			;ax <- source char
		call	LexValueSJISNoWidthInt
		cmp	ax, dx			;set flags for cmp src, dest
		pop	ax, dx
done:
		.leave
		ret
CmpCharsSJISNoWidthInt		endp

endif

StringMod	ends

if PZ_PCGEOS

kcode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalIsNonJapanese
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a character is Japanese or not for purposes of 
		word-wrapping w.r.t. Kinsoku characters.

CALLED BY:	GrTextObjCalc()
PASS:		ax - character to check
RETURN:		zero flag: clear (nz) if the character is non-Japanese
			   set (z) if the character is Japanese
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	This is placed in kcode because it only called from kcode,
	and is called for potentially every character by GrTextObjCalc().
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalIsNonJapanese	proc	near
		uses	bx, ds
		.enter

		segmov	ds, cs, bx
		mov	bx, offset nonJapaneseTypeTable
	;
	; See if the character is in this range
	;
charLoop:
		cmp	ax, ds:[bx].CTS_end
		jbe	gotEntry
	;
	; Character is not in current range -- go to next
	;
		add	bx, (size CharTypeStruct)
		jmp	charLoop

	;
	; Found the correct entry -- test for correct type
	;
gotEntry:
		test	ds:[bx], mask CT_CHAR_IN_CLASS

		.leave
		ret
LocalIsNonJapanese	endp

kcode	ends

endif

kcode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetWordPartType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the word part type of a character for purposes
		of word selection.

CALLED BY:	GLOBAL
PASS:		ax - character (Chars)
RETURN:		ax - type (CharWordPartType)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGetWordPartType		proc	far
		uses	bx
		.enter

	;
	; Loop to find the char range
	;
		mov	bx, offset wordPartTypeList
charRangeLoop:
		cmp	ax, cs:[bx].WPTS_end
		jbe	gotRange
		add	bx, (size WordPartTypeStruct)
		jmp	charRangeLoop

	;
	; Get its type
	;
gotRange:
		clr	ah
		mov	al, cs:[bx].WPTS_type

		.leave
		ret
LocalGetWordPartType		endp

kcode	ends
