COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		stringCompare.asm

AUTHOR:		Gene Anderson, Dec  6, 1990

ROUTINES:
	Name				Description
	----				-----------
	LocalGetLanguage		Get current language for comparisons
	LocalStringCompare		Compare two strings
	LocalStringCompareNoCase	Compare two strings, case-insensitive
	DoStringCompare			Do table-drive string compare
	LocalStringCompareDosToGeos	Compare two strings, converting
					characters from DOS code page
					to GEOS character set
	TranslateSpecialCharacters	Translate either string if it has a
					double-s character in it.
	TranslateSpecialCharactersESDI	If the German double-s character is
					in the string, copy the whole string
					to the stack, with the character
					replaced with two ss's.
	RemoveStringsFromStack		Remove the translated strings from
					the stack.
	TranslateAndCopyToStackESDI	Copy the string at es:di to the 
					stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/ 6/90	Initial revision

DESCRIPTION:
	Routines for dealing with string comparison.

	$Id: stringSort.asm,v 1.1 97/04/05 01:17:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Internal/prodFeatures.def

if DBCS_PCGEOS
StringMod	segment	resource
else
StringCmpMod	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetLanguage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current language for comparison

CALLED BY:	GLOBAL
PASS:		none
RETURN:		ax - StandardLanguage
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LOCALGETLANGUAGE		proc	far
	.enter

	mov	al, cs:curLanguage
	clr	ah				;ax <- StandardLanguage

	.leave
	ret
LOCALGETLANGUAGE		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do dictionary order comparison of two strings 
CALLED BY:	DR_LOCAL_COMPARE_STRING

PASS:		ds:si - ptr to string1
		es:di - ptr to string2
		cx - maximum # of chars to compare (0 for NULL terminated)
RETURN:		flags - same as in cmps instruction:
			if string1 =  string2 : if (z)
			if string1 != string2 : if !(z)
			if string1 >  string2 : if !(c|z)
			if string1 <  string2 : if (c)
			if string1 >= string2 : if !(c)
			if string1 <= string2 : if (c|z)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine should be called when lexigraphical order is
	required (ie. if one string should come before, at the same
	point, or after another string).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
LocalCmpStrings	proc	far
		mov	ss:[TPD_callVector].segment, cx
DBCS	<	shl	ss:[TPD_callVector].segment, 1			>
		mov	ss:[TPD_dataBX], handle LocalCmpStringsReal
		mov	ss:[TPD_dataAX], offset LocalCmpStringsReal
		GOTO	SysCallMovableXIPWithDSSIAndESDIBlock
LocalCmpStrings	endp
CopyStackCodeXIP	ends

else

LocalCmpStrings	proc	far
	FALL_THRU	LocalCmpStringsReal
LocalCmpStrings	endp

endif

LocalCmpStringsReal	proc	far
SBCS <	uses	bx							>
DBCS <	uses	bp							>
	.enter

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	push	ds, es, si, di, dx
	call	TranslateSpecialCharacters
endif
	;
	; For SBCS and DBCS, we compare for dictionary order by
	; comparing first ignoring case and accent.
	;
	; For Pizza, we compare for SJIS order.
	;
SBCS <	mov	bx, offset Lexical1stOrderTable				>
if DBCS_PCGEOS
if SJIS_SORTING
	mov	bp, offset CmpCharsSJISInt
else
	mov	bp, offset CmpCharsNoCaseInt
endif
endif
	call	DoStringCompare
if not SJIS_SORTING
	jne	done
SBCS <	mov	bx, offset LexicalOrderTable				>
DBCS <	mov	bp, offset CmpCharsInt					>
	call	DoStringCompare
done:
endif

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	call	RemoveStringsFromStack
	pop	ds, es, si, di, dx
endif
	.leave
	ret
LocalCmpStringsReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpStringsNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do dictionary order comparison of two strings 
CALLED BY:	DR_LOCAL_COMPARE_STRING_NO_CASE

PASS:		-- see LocalCmpStrings --
RETURN:		-- see LocalCmpStrings --
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 7/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
LocalCmpStringsNoCase	proc	far
		mov	ss:[TPD_callVector].segment, cx
DBCS	<	shl	ss:[TPD_callVector].segment, 1			>
		mov	ss:[TPD_dataBX], handle LocalCmpStringsNoCaseReal
		mov	ss:[TPD_dataAX], offset LocalCmpStringsNoCaseReal
		GOTO	SysCallMovableXIPWithDSSIAndESDIBlock
LocalCmpStringsNoCase	endp
CopyStackCodeXIP	ends

else

LocalCmpStringsNoCase	proc	far
	FALL_THRU	LocalCmpStringsNoCaseReal
LocalCmpStringsNoCase	endp

endif

LocalCmpStringsNoCaseReal	proc	far
SBCS <	uses	bx							>
DBCS <	uses	bp							>
	.enter

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	push	ds, es, si, di, dx
	call	TranslateSpecialCharacters
endif
	;
	; For SBCS and DBCS, we compare ignoring case and accent.
	;
	; For Pizza, we compare for SJIS order, but ingoring case
	; and fullwidth vs. halfwidth.
	;
SBCS <	mov	bx, offset Lexical1stOrderTable				>
if DBCS_PCGEOS
if SJIS_SORTING
	mov	bp, offset CmpCharsSJISNoWidthInt
else
	mov	bp, offset CmpCharsNoCaseInt
endif
endif
	call	DoStringCompare

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	call	RemoveStringsFromStack
	pop	ds, es, si, di, dx
endif
	.leave
	ret
LocalCmpStringsNoCaseReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do dictionary order comparison of two chars

PASS:		ax - source char
		cx - dest char
RETURN:		flags - same as in cmps instruction:
			if source =  dest : if (z)
			if source != dest : if !(z)
			if source >  dest : if !(c|z)
			if source <  dest : if (c)
			if source >= dest : if !(c)
			if source <= dest : if (c|z)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	DON'T USE THIS unless you are sure you know what you are doing!
	-- some languages have multi-character sequences that need to be
	sorted specially (eg. "ch" sorts after "c" in Spanish), so
	comparing a character at a time will yield incorrect results.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalCmpChars	proc	far
SBCS <	uses	bx							>
DBCS <	uses	ax, bx, dx						>
	.enter

if DBCS_PCGEOS
	mov	dx, cx				;dx <- dest char
	xchg	ax, dx				;ax <- dest char
if SJIS_SORTING
	call	CmpCharsSJISInt
else
	call	CmpCharsNoCaseInt
	jne	done
	call	CmpCharsInt
done:
endif
else
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	ch							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	bx, offset Lexical1stOrderTable
	call	DoCharCompare
	jne	done
	mov	bx, offset LexicalOrderTable
	call	DoCharCompare
done:
endif
	.leave
	ret
LocalCmpChars	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpCharsNoCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do dictionary order comparison of two chars
CALLED BY:	GLOBAL

PASS:		-- see LocalCmpChars --
RETURN:		-- see LocalCmpChars --
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 7/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalCmpCharsNoCase	proc	far
SBCS <	uses	bx							>
DBCS <	uses	ax, bx, dx						>
	.enter

if DBCS_PCGEOS
	mov	dx, cx				;dx <- dest char
	xchg	ax, dx				;ax <- dest char
if SJIS_SORTING
	call	CmpCharsSJISNoWidthInt
else
	call	CmpCharsNoCaseInt
endif
else
EC <	tst	ah							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
EC <	tst	ch							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
	mov	bx, offset Lexical1stOrderTable
	call	DoCharCompare
endif

	.leave
	ret
LocalCmpCharsNoCase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCharCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do table-driven string comparison
CALLED BY:	LocalCompareChar(), LocalCompareCharNoCase()

PASS:		cs:bx - ptr to lexical table to use
		ax - char #1
		cx - char #2
RETURN:		see LocalCmpChars
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 7/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DBCS_PCGEOS

DoCharCompare	proc	near
	uses	ax
	.enter
	cs:xlat				;Map source char
	mov	ah, al			;Save in AH
	mov	al, cl
	cs:xlat				;Map dest char
	cmp	ah, al			;Compare chars
	.leave
	ret
DoCharCompare	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoStringCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do table-driven string comparison
CALLED BY:	LocalCompareString(), LocalCompareStringNoCase()

PASS:	SBCS:
		cs:bx - ptr to lexical table to use
	DBCS:
		cs:bp - ptr to character comparison routine

		ds:si - ptr to string #1
		es:di - ptr to string #2
		cx - maximum # of chars to compare (0 for NULL-terminated)
RETURN:		see LocalCompareString
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 7/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoStringCompare	proc	near
SBCS <	uses	ax, cx, si, di						>
DBCS <	uses	ax, bx, dx, cx, si, di					>
	.enter

	mov	ax, 0xffff
DCS_loop:
SBCS <	or	al, ah				;end of both strings?	>
DBCS <	or	ax, dx				;end of both strings?	>
	jz	done

	LocalGetChar	ax, dssi		;ax <- source char

if not DBCS_PCGEOS
	cs:xlat					;convert source char
endif
SBCS <	mov	ah, al				;dx <- source char	>
DBCS <	mov_tr	dx, ax				;dx <- source char	>

	LocalGetChar	ax, esdi		;ax <- dest char

if not DBCS_PCGEOS
	cs:xlat					;convert dest char
endif
SBCS <	cmp	ah, al				;compare string bytes	>
DBCS <	call	bp				;compare characters	>
	loope	DCS_loop			;loop while equal
done:
	.leave
	ret
DoStringCompare	endp

if not DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpStringsDosToGeos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do dictionary order comparison of two strings, converting
		characters from DOS code page to GEOS character set before
		comparison
CALLED BY:	GLOBAL

PASS:		ds:si - ptr to source string
		es:di - ptr to dest string
		cx - maximum # of chars to compare (0 for NULL terminated)
		ax - LocalCmpStringsDosToGeosFlags
		     LCSDTG_NO_CONVERT_STRING_1 to not convert string 1 (ds:si)
		     LCSDTG_NO_CONVERT_STRING_2 to not convert string 2 (es:di)
		bx - default character for DOS-to-GEOS conversion
RETURN:		flags - same as in cmps instruction:
			if source =  dest : if (z)
			if source != dest : if !(z)
			if source >  dest : if !(c|z)
			if source <  dest : if (c)
			if source >= dest : if !(c)
			if source <= dest : if (c|z)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/89	Initial version
	brianc	1/7/91		modified for DOS-to-GEOS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
LocalCmpStringsDosToGeos	proc	far
		mov	ss:[TPD_callVector].segment, cx
DBCS	<	shl	ss:[TPD_callVector].segment, 1			>
		mov	ss:[TPD_dataBX], handle LocalCmpStringsDosToGeosReal
		mov	ss:[TPD_dataAX], offset LocalCmpStringsDosToGeosReal
		GOTO	SysCallMovableXIPWithDSSIAndESDIBlock
LocalCmpStringsDosToGeos	endp
CopyStackCodeXIP	ends

else

LocalCmpStringsDosToGeos	proc	far
	FALL_THRU	LocalCmpStringsDosToGeosReal
LocalCmpStringsDosToGeos	endp

endif

LocalCmpStringsDosToGeosReal	proc	far
	uses	ax, bx, dx, es, bp
	.enter

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	push	ds, es, si, di, dx
	call	TranslateSpecialCharacters
	push	dx
endif
	; for now we only deal with bytes, not words

EC <	tst	bh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>

	mov	bh, bl				;bh <- default char
	mov	bl, al
	mov	bp, bx				;bp <- flags and default char

	mov	dx, es

	call	GetCurrentCodePage		; bx = handle, es = segment
	push	bx				; save handle

	mov	bx, offset Lexical1stOrderTable
	call	DoStringCompareDOSToGEOS
	jne	done
	mov	bx, offset LexicalOrderTable
	call	DoStringCompareDOSToGEOS
done:
	pop	bx				; unlock code page
	call	MemUnlock			; (preserves flags)

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	pop	dx
	call	RemoveStringsFromStack
	pop	ds, es, si, di, dx
endif
	.leave
	ret
LocalCmpStringsDosToGeosReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoStringCompareDOSToGEOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do table-driven string comparison
CALLED BY:	LocalCompareStringDOSToGEOS()

PASS:		cs:bx - ptr to lexical table to use
		ds:si - ptr to string #1
		dx:di - ptr to string #2
		es - segment of code page buffer
		cx - maximum # of chars to compare (0 for NULL-terminated)
		bp high - default character
		bp low - LocalCmpStringsDosToGeosFlags
		     LCSDTG_NO_CONVERT_STRING_1 to not convert string 1 (ds:si)
		     LCSDTG_NO_CONVERT_STRING_2 to not convert string 2 (es:di)
RETURN:		see LocalCompareStringDOSToGEOS
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Either:
	    (1) neither character is a ligature ==> do compare
	    (2) both characters are ligatures ==> do compare
	    (3) source is ligature ==> expand, get matching char from dest
	    (4) dest is ligature ==> expand, get matching char from source

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 7/90	Initial version
	brianc	1/7/91		modified for DOS-to-GEOS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoStringCompareDOSToGEOS	proc	near
	uses	cx, si, di
	.enter

	mov	ax, 0xffff
DCS_loop:
	or	al, ah				;end of both strings?
	jz	done

	lodsb					;al <- byte of source
	test	bp, mask LCSDTGF_NO_CONVERT_STRING_1
	jnz	10$
	call	ConvertCharDOSToGEOS		;convert to GEOS char set
10$:
	cs:xlat					;convert source char
	mov	ah, al

	push	es				;save code page segment
	mov	es, dx				;es:di = string 2
	mov	al, es:[di]			;al <- byte of dest
	pop	es				;restore code page segment
	test	bp, mask LCSDTG_NO_CONVERT_STRING_2
	jnz	20$
	call	ConvertCharDOSToGEOS		;convert to GEOS char set
20$:
	inc	di
	cs:xlat					;convert dest char

	cmp	ah, al				;compare string bytes
	loope	DCS_loop			;loop while equal
done:
	.leave
	ret
DoStringCompareDOSToGEOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertCharDOSToGEOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert single character from DOS code page to GEOS
		character set
CALLED BY:	DoStringCompareDOSToGEOS()

PASS:		al - character to convert
		bp high - default character
		es - segment of code page conversion table
RETURN:		al - converted character
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertCharDOSToGEOS	proc	near
	uses	bx, cx
	.enter
	mov	bx, offset codePageUS		; offset to code page table
	mov	cx, bp				; ch = default char
	tst	al
	jns	done				; low ASCII, no conversion
	sub	al, MIN_MAP_CHAR		; convert to index
	es:xlat					; al = converted character
	tst	al				; character mappable?
	jnz	done				; yes, return it
	mov	al, ch				; else, return default char
done:
	.leave
	ret
ConvertCharDOSToGEOS	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpStringsNoSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings, ignoring whitespace and punctuation

CALLED BY:	GLOBAL
PASS:		-- see LocalCompareString --
RETURN:		-- see LocalCompareString --
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
LocalCmpStringsNoSpace	proc	far
		mov	ss:[TPD_callVector].segment, cx
DBCS	<	shl	ss:[TPD_callVector].segment, 1			>
		mov	ss:[TPD_dataBX], handle LocalCmpStringsNoSpaceReal
		mov	ss:[TPD_dataAX], offset LocalCmpStringsNoSpaceReal
		GOTO	SysCallMovableXIPWithDSSIAndESDIBlock
LocalCmpStringsNoSpace	endp
CopyStackCodeXIP	ends

else

LocalCmpStringsNoSpace	proc	far
	FALL_THRU	LocalCmpStringsNoSpaceReal
LocalCmpStringsNoSpace	endp

endif

LocalCmpStringsNoSpaceReal		proc	far
	uses	bx
	.enter

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	push	ds, es, si, di, dx
	call	TranslateSpecialCharacters
endif

SBCS <	mov	bx, offset Lexical1stOrderTable				>
if DBCS_PCGEOS
if SJIS_SORTING
	mov	bx, offset CmpCharsSJISInt
else
	mov	bx, offset CmpCharsNoCaseInt
endif
endif
	call	DoStringCompareNoSpace
if not SJIS_SORTING
	jne	done
SBCS <	mov	bx, offset LexicalOrderTable				>
DBCS <	mov	bx, offset CmpCharsInt					>
	call	DoStringCompareNoSpace
done:
endif
if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	call	RemoveStringsFromStack
	pop	ds, es, si, di, dx
endif
	.leave
	ret
LocalCmpStringsNoSpaceReal		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCmpStringsNoSpaceCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two strings, ignoring whitespace, punctuation and case

CALLED BY:	GLOBAL
PASS:		-- see LocalCompareString --
RETURN:		-- see LocalCompareString --
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
LocalCmpStringsNoSpaceCase	proc	far
		mov	ss:[TPD_callVector].segment, cx
DBCS	<	shl	ss:[TPD_callVector].segment, 1			>
		mov	ss:[TPD_dataBX], handle LocalCmpStringsNoSpaceCaseReal
		mov	ss:[TPD_dataAX], offset LocalCmpStringsNoSpaceCaseReal
		GOTO	SysCallMovableXIPWithDSSIAndESDIBlock
LocalCmpStringsNoSpaceCase	endp
CopyStackCodeXIP	ends

else

LocalCmpStringsNoSpaceCase	proc	far
	FALL_THRU	LocalCmpStringsNoSpaceCaseReal
LocalCmpStringsNoSpaceCase	endp

endif

LocalCmpStringsNoSpaceCaseReal		proc	far
	uses	bx
	.enter

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	push	ds, es, si, di, dx
	call	TranslateSpecialCharacters
endif

SBCS <	mov	bx, offset Lexical1stOrderTable				>
if DBCS_PCGEOS
if SJIS_SORTING
	mov	bx, offset CmpCharsSJISNoWidthInt
else
	mov	bx, offset CmpCharsNoCaseInt
endif
endif
	call	DoStringCompareNoSpace

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS
	call	RemoveStringsFromStack
	pop	ds, es, si, di, dx
endif
	.leave
	ret
LocalCmpStringsNoSpaceCaseReal		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoStringCompareNoSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do table-driven string comparison ignoring spaces & punctuation
CALLED BY:	LocalCompareStringNoSpace(), LocalCompareStringNoSpaceCase()

PASS:	SBCS:
		cs:bx - ptr to lexical table to use
	DBCS:
		cs:bx - ptr to routine to compare chars

		ds:si - ptr to string #1
		es:di - ptr to string #2
		cx - maximum # of chars to compare (0 for NULL-terminated)
RETURN:		see LocalCompareString
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: any space or punctuation that is ignored is still
	included in the character counts.  For example, if you pass
	    cx - 2 characters
	    ds:si - "o'leary"
	    es:di - "o'"
	it will compare the "o" in each string, and ignore the "'" in each
	string, and return that the strings are equal.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 7/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoStringCompareNoSpace	proc	near
	uses	ax, dx, cx, si, di, bp
	.enter

	mov	ax, 0xffff
DCS_loop:
SBCS <	or	dl, al				;end of both strings?	>
DBCS <	or	ax, dx				;end of both strings?	>
	jz	done

	clr	bp				;bp <- ignored char count
getNextSource:
	LocalGetChar ax, dssi			;ax <- character of source
SBCS <	clr	ah							>
	call	LocalIsSpace
	jnz	nextSourceChar			;branch if a space
	call	LocalIsPunctuation
	jnz	nextSourceChar			;branch if punctuation

SBCS <	cs:xlat					;convert source char	>
SBCS <	mov	dl, al							>
DBCS <	mov	dx, ax							>

getNextDest:
	LocalGetChar ax, esdi			;ax <- character of dest
SBCS <	clr	ah							>
	call	LocalIsSpace
	jnz	nextDestChar			;branch if a space
	call	LocalIsPunctuation
	jnz	nextDestChar			;branch if punctuation

SBCS <	cs:xlat					;convert dest char	>

SBCS <	cmp	dl, al				;compare string bytes	>
DBCS <	push	bx							>
DBCS <	call	bx				;compare characters	>
DBCS <	pop	bx							>
	loope	DCS_loop			;loop while equal
done:

	.leave
	ret

	;
	; bp is the number of characters we've ignored since the last
	; compare -- sort of.
	; (1) For each source character ignored, we increment bp and have
	; one less character to compare (ie. decrement cx)
	; (2) For each destination character ignored, we decrement bp.
	; (3) As long as bp is non-negative, it means we've already
	; decremented cx when ignoring a character in the source.
	; (4) If bp is negative, it means we've ignored more destination
	; characters then source characters, and so we need to adjust cx.
	; (5) If cx reaches zero while ignoring characters, we're done
	; and the strings are equal.
	;
nextSourceChar:
	inc	bp				;bp <- one more in source
	dec	cx				;cx <- one less to compare
	clc					;carry <- in case equal
	jz	done				;branch (Z flag set -> equal)
	jmp	getNextSource

nextDestChar:
	dec	bp				;bp <- one more in dest
	jns	getNextDest
	dec	cx				;cx <- one less to compare
	clc					;carry <- in case equal
	jz	done				;branch (Z flag set -> equal)
	jmp	getNextDest

DoStringCompareNoSpace	endp

if SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateSpecialCharacters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate either string if it has a double-s character in
		it.

CALLED BY:	LocalCmpStringsReal, LocalCmpStringsNoCaseReal,
		LocalCmpStringsDosToGeosReal, LocalCmpStringsNoSpaceReal,
		LocalCmpStringsNoSpaceCaseReal
PASS:		ds:si - ptr to string #1
		es:di - ptr to string #2
		cx - maximum # of chars to compare (0 for NULL-terminated)
RETURN:		dx - count of strings copied to stack
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateSpecialCharacters	proc	near
		uses	ax
		.enter

		clr	dx		; Count of strings copied to stack
		call	TranslateSpecialCharactersESDI

		segxchg	es, ds
		xchg	si, di
		call	TranslateSpecialCharactersESDI
		segxchg	es, ds
		xchg	si, di
done::					; Leave in for swat verbose.
		.leave
		ret
TranslateSpecialCharacters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateSpecialCharactersESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the German double-s character is in the string, copy
		the whole string to the stack, with the character replaced
		with two ss's.

CALLED BY:	TranslateSpecialCharacters
PASS:		es:di = string
		cx = maximum # of chars to compare (0 for NULL-terminated)
		dx = current number of strings on stack

RETURN:		if double-s is in string,
			es:di = translated string on the stack
		dx = current number of strings on stack
DESTROYED:	ax
SIDE EFFECTS:	if double-s is in string,
			Allocates space on bottom of stack (below TPD_stackBot)

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/ 6/95    	Initial version
	kho	7/15/96		Preserve cx so that it will work if
				both strings are to be translated in
				TranslateSpecialCharacters.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateSpecialCharactersESDI	proc	near
		uses	cx
		.enter

	; If cx is specified, just check that number of characters.

		tst	cx
		jnz	scanForDoubleS

	; Find the null termination.

		push	di
		mov	cx, 0FFFFh
		clr	al
		repnz	scasb
		pop	di
		neg	cx
		dec	cx		; cx = number of characters to compare.

scanForDoubleS:

	; Look for a German double-s.

		push	di
		mov	al, C_GERMANDBLS
		repnz	scasb
		pop	di
		je	translate

done:
		.leave
		ret

translate:
		inc	dx		; Increment count of strings on stack.
		call	TranslateAndCopyToStackESDI
		jmp	done

TranslateSpecialCharactersESDI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveStringsFromStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the translated strings from the stack.

CALLED BY:	LocalCmpStringsReal, LocalCmpStringsNoCaseReal,
		LocalCmpStringsDosToGeosReal, LocalCmpStringsNoSpaceReal,
		LocalCmpStringsNoSpaceCaseReal
PASS:		dx - number of strings to remove (0, 1, or 2)
RETURN:		If strings are on stack,
			ds:si and/or es:di will be restored to again point
			to the original strings
		** Flags preserved **
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	6/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveStringsFromStack	proc	near
		uses	ax,di
		.enter

		pushf
EC <		cmp	dx, 2						>
EC <		ERROR_A	STRING_SORT_STACK_CAN_ONLY_HAVE_TWO_STRINGS	>

	; Streamlined for nothing on the stack.

		tst	dx
		jnz	remove
done:
		popf
		.leave
		ret				; <-- EXIT HERE.

remove:

	; Remove a string from the stack.

		mov	di, ss:[TPD_stackBot]
		sub	di, 2
		mov	ax, ss:[di]		; Previous stack bottom.
		mov	ss:[TPD_stackBot], ax

		dec	dx
		jnz	remove			; Is another string on stack?
		jmp	done

RemoveStringsFromStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateAndCopyToStackESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the string at ds:si to the stack

CALLED BY:	TranslateSpecialCharactersESDI

PASS:		es:di - data to copy

RETURN:		es:di - now point to copy of data on the stack

DESTROYED:	nothing

SIDE EFFECTS:	Allocates space on bottom of stack (below TPD_stackBot)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateAndCopyToStackESDI proc near
		uses	ax,cx,ds,si
		.enter

	; Swap ds:si and es:di.

		xchg	si, di
		segxchg	ds, es

	; Count the number of double-s's so we know how much space to
	; allocate.  This is a royal pain in patookis, for one letter,
	; albeit a double-letter.	

		clr	cx			; Character count.
		push	si			; Start of string.
getNextChar:
		lodsb
		inc	cx

	; If we reached the null-termination, we are done.

		tst	al
		jz	copyToStack
	
	; If this is a double-s, we'll need space to translate this to
	; two s's.

		cmp	al, C_GERMANDBLS
		jne	getNextChar
		inc	cx			; Count double-s as two chars.
		jmp	getNextChar

copyToStack:
		pop	si			; Start of string.

	; Allocate space on bottom of the stack, like SysCopyToStackDSSI.

		mov	ax, ss:[TPD_stackBot]
		mov	di, ax
		add	di, cx
		push	di		; Offset to store previous stack bottom.
		add	di, 2
		cmp	di, sp
		jae	stackOverflow
		mov	ss:[TPD_stackBot], di	; Adjust stack bottom.

	; Stuff previous stack bottom.

		pop	di
		mov	ss:[di], ax		; Previous stack bottom.

	; Set up destination for translated string.

		segmov	es, ss, di
		mov	di, ax

	; Copy string to stack, translating double-s's

		push	di			; Offset of translated string.
		jcxz	setReturnValue
nextChar:
		dec	cx
		lodsb
		cmp	al, C_GERMANDBLS
		je	doubleS
		stosb
		tst	cx
		jnz	nextChar

setReturnValue:
		segmov	es, ss, si		; Segment of translated string.
		pop	di			; Offset of translated string.
done:
		.leave
		ret				; <---- EXIT HERE

doubleS:
		mov 	al, C_SMALL_S		; Store two s's in place of 
		stosb				; German double-s.
		stosb
		dec 	cx			; Decrement again for double-s.
		jmp	nextChar

stackOverflow:
		pop	di
EC <		ERROR_AE STACK_OVERFLOW						>
		xchg	si, di
		segxchg	ds, es		
		jmp	done	

TranslateAndCopyToStackESDI endp
endif ; SORT_DOUBLE_S_CORRECTLY and not DBCS_PCGEOS

if DBCS_PCGEOS
StringMod	ends
else
StringCmpMod	ends
endif
