COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2001.  All rights reserved.
	MYTURN.COM CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		FS driver
FILE:		dosConvertGB.asm

AUTHOR:		Allen Yuen, Feb 20, 2001

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/20/01   	Initial revision


DESCRIPTION:
	Code for GB support (specifically, GB 2312-1980 EUC encoding).

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosGBToGeosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GB DOS character to a GEOS character

CALLED BY:	DCSConvertToGEOSChar
PASS:		bx	= DosCodePage to use (not used)
		ax	= GB 2312 EUC character
RETURN:		carry set if error
			al	= DTGSS_INVALID_CHARACTER
			ah	= 0
		carry clear if okay
			ax	= GEOS character (Chars)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	According to the document CJK.INF Version 2.1 (July 12, 1996) by Ken
	Lunde, the valid ranges for GB 2312 EUC format are:
		0x21-0x7E:	ASCII or GB 1988-1989 (Why is 0x20 excluded?)
		0xA1A1-0xFEFE:	GB 2312-1980
	We ignore the differences between GB 1988 and ASCII.  (Do we need to
	specially handle 0x24, which is dollar sign in ASCII but Yuan in GB
	1988?)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/20/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosGBToGeosChar	proc	near
	uses	bx, si, ds
	.enter

	;
	; Special case: Need to allow all low characters to pass through,
	; even though not all of them are in GB 2312 EUC code set 0
	; strictly speaking.
	;
	cmp	ax, MIN_DOS_TO_GEOS_CHAR
	jb	doneConvert

	;
	; Check if char is in GB 2312 EUC range
	;
	cmp	ax, GB_2312_EUC_CODE_SET_1_START
	jb	notGB2312EUCChar
	cmp	ax, GB_2312_EUC_CODE_SET_1_END
	ja	notGB2312EUCChar

	;
	; Check if char is in proper EUC format.  We already know the high
	; byte is in the proper format, so we only need to check the low
	; byte.
	;
	test	al, HIGH_BIT_MASK
	jz	notGB2312EUCChar

	;
	; Char is GB 2312 EUC.  First convert it back to GB 2312.
	;
	andnf	ax, not ((HIGH_BIT_MASK shl 8) or HIGH_BIT_MASK)
					; ax = GBChars, possible invalid

	;
	; Scan the section start table to see which section it falls into.
	;
	segmov	ds, <segment Resident>
	clr	si			; start at first section start table

sectionStartLoop:
	cmp	ax, ds:[gbSectionStartTable][si]
	jb	startPassed
		CheckHack <size GBChars eq 2>
	inc	si
	inc	si			; si = next index
	cmp	si, size gbSectionStartTable
	jb	sectionStartLoop

startPassed:
	tst	si			; char below first section start?
	jz	notGB2312Char		; => yes

	;
	; si-2 is the index for the start value that this character fits.
	; Now check the end value to see if the character actually fits in
	; the range.
	;
	mov	bx, ds:[gbSectionEndTable][si - size GBChars]
	cmp	ax, bx
	ja	notGB2312Char		; => above section end, invalid

	;
	; Section found.  See if the section is single-row or multi-row.
	; (Row number of a GB char is the high byte of the char minus 0x20.)
	;
	cmp	bh, ds:[gbSectionStartTable][si - size GBChars].high
	jne	multiRow

	;
	; Single-row section.  Just look up the Unicode by indexing into it.
	;
		; Make sure the element size of gbSectionTable is same as
		; that of gbSectionStartTable, so that we can re-use SI as
		; offset within gbSectionTable.
		CheckHack <type gbSectionTable eq type gbSectionStartTable>
	mov	bx, ds:[gbSectionTable][si - size nptr]
	sub	ax, ds:[gbSectionStartTable][si - size GBChars]
	shl	ax			; ax = index into section
	mov_tr	si, ax			; si = index into section
	mov	ax, ds:[bx][si]		; ax = Chars
	jmp	hasUnicode

multiRow:
	;
	; Multi-row section.  See if the character falls into the gaps between
	; row sub-sections, which means it has no entry in the table, hence
	; invalid.
	;
	cmp	al, GB_2312_LOW_BYTE_MIN
	jb	notGB2312Char
	cmp	al, GB_2312_LOW_BYTE_MAX
	ja	notGB2312Char

	;
	; The character has an entry in the table (but it may still be
	; invalid.)  Calculate the index based on the offset of the row
	; sub-section and the offset within the sub-section.
	;
	sub	ax, ds:[gbSectionStartTable][si - size GBChars]
					; ah = row # in section, al = char #
					;  in row
	mov	bl, al			; bl = char # in row
	mov	al, (GB_2312_LOW_BYTE_MAX - GB_2312_LOW_BYTE_MIN + 1) \
			* size GBChars	; al = size of a row
	mul	ah			; ax = offset of row
	clr	bh			; bx = char # in row
		CheckHack <size GBChars eq 2>
	shl	bx			; bx *= size GBChars, bx = offset of
					;  char in row
	add	bx, ax			; bx = offset of char in section
	mov	si, ds:[gbSectionTable][si - size GBChars]
	mov	ax, ds:[si][bx]		; ax = Chars

hasUnicode:
	;
	; See if such a GB 2312 character exists.
	;
	cmp	ax, C_NOT_A_CHARACTER
	je	notGB2312Char		; => no such GB 2312 char

doneConvert:
	clc				; success

exit:
	.leave
	ret

notGB2312Char:
notGB2312EUCChar:
	mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
	stc				; error
	jmp	exit

DosGBToGeosChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosGBChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character to a GB DOS character.

CALLED BY:	DCSConvertToDOSChar
PASS:		bx	= DosCodePage to use
		ax	= GEOS character (Chars)
RETURN:		carry set if error
			al	= DTGSS_SUBSTITUTIONS
			ah	= 0
		carry clear if okay
			ax	= GB 2312 EUC character
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/26/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosGBChar	proc	near
	uses	cx, si, di, ds, es
	.enter

	;
	; Special case: Need to allow all low characters to pass through,
	; even though not all of them have equivalents in GB 2312 EUC
	; strictly speaking.
	;
	cmp	ax, MIN_DOS_TO_GEOS_CHAR
	jb	doneConvert

	;
	; Go through all the section tables to find a match.
	;
	segmov	ds, <segment Resident>
	clr	si			; start at first section table
	segmov	es, ds

sectionLoop:
	mov	di, ds:[gbSectionTable][si]	; es:di = section table
		; Make sure the element size of gbSectionEnd/StartTable is
		; same as that of gbSectionTable, so that we can re-use SI as
		; offset within gbSectionEnd/StartTable.
		CheckHack <type gbSectionEndTable eq type gbSectionTable>
		CheckHack <type gbSectionStartTable eq type gbSectionTable>
	mov	cx, ds:[gbSectionEndTable][si]
	sub	cx, ds:[gbSectionStartTable][si]
	inc	cx			; cx = length (if single-row)
	cmp	cx, GB_2312_LOW_BYTE_MAX - GB_2312_LOW_BYTE_MIN + 1
	ja	multiRow

	;
	; Single-row seciton.  Scan the table.
	;
	repne	scasw
	jne	nextSection		; => not in this section

	;
	; Found.  di-2 is the offset of the Chars that matches.  Now
	; calculate the equivalet GB 2312 character from the index.
	;
	mov_tr	ax, di
	sub	ax, ds:[gbSectionTable][si]	; ax = offset in table
		CheckHack <size Chars eq 2>
	shr	ax
	dec	ax			; ax = (ax - size Chars) / size Chars
	add	ax, ds:[gbSectionStartTable][si]	; ax = GBChars
	jmp	convertToEUC

multiRow:
	;
	; Multi-row section.  Calculate the length appropriately.
	;
	; ch = # rows - 1, cl = length of last row
	push	ax			; save Chars to find
	mov	al, GB_2312_LOW_BYTE_MAX - GB_2312_LOW_BYTE_MIN + 1
					; al = len. of a row
	mul	ch			; ax = total len. of rows except last
	clr	ch			; cx = len. of last row
	add	cx, ax			; cx = len. of section

	;
	; Scan the table.
	;
	pop	ax			; ax = Chars to find
	repne	scasw
	jne	nextSection		; => not in this section

	;
	; Found.  di-2 is the offset of the Chars that matches.  Now
	; calculate the equivalet GB 2312 character from the index.
	;
	mov_tr	ax, di
	sub	ax, ds:[gbSectionTable][si]	; ax = offset in table
		CheckHack <size Chars eq 2>
	shr	ax
	dec	ax			; ax = (ax - size Chars) / size Chars,
					;  # of Chars from start of section
	mov	cl, GB_2312_LOW_BYTE_MAX - GB_2312_LOW_BYTE_MIN + 1
	div	cl			; al = row offset, ah = Chars offset
					;  in last row (won't overflow)
	xchg	ah, al			; ah = row offset, al = Chars offset
					;  in last row
	add	ax, ds:[gbSectionStartTable][si]	; ax = GBChars
	jmp	convertToEUC

nextSection:
	;
	; Loop to next section table
	;
		CheckHack <size nptr eq 2>
	inc	si
	inc	si			; si = next index
	cmp	si, size gbSectionTable
	jb	sectionLoop

	;
	; GEOS character not found in any of the tables.  Can't convert.
	;
	mov	ax, DTGSS_SUBSTITUTIONS or (0 shl 8)
	stc				; error
	jmp	exit

convertToEUC:
	;
	; Convert GBChars to EUC format.
	;
	ornf	ax, (HIGH_BIT_MASK shl 8) or HIGH_BIT_MASK
					; ax = GB 2312 EUC

doneConvert:
	clc				; success

exit:
	.leave
	ret
GeosToDosGBChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosGBToGeosCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GB DOS character in a string to a GEOS character

CALLED BY:	DCSConvertToGEOS, DCSDosToGeosCharString
PASS:		bx	= DosCodePage to use (not used)
		ds:si	= DOS string
		es:di	= GEOS buffer
		cx	= max # of bytes to read
RETURN:		carry set if error
			al	= DTGSS_CHARACTER_INCOMPLETE
				ah	= # characters to back up
			al	= DTGSS_INVALID_CHARACTER
				ah	= 0
		carry clear if okay
			ax	= GEOS character (Chars)
		ds:si	= next character
		es:di	= next character
		cx updated if >1 bytes read
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/22/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosGBToGeosCharString	proc	near
	.enter

	;
	; Get a byte, and see if it is the 1st byte of a 2-byte char.
	;
	clr	ah			; assume 1 byte
	lodsb				; ax = al = 1st byte
	cmp	al, GB_2312_EUC_CODE_SET_1_START shr 8
	jb	gotChar			; => 1 byte char, maybe invalid
	cmp	al, GB_2312_EUC_CODE_SET_1_END shr 8
	ja	gotChar			; => invalid char, let DosGBToGeosChar
					;  handle it to save code.
	;
	; Character is 2 bytes.  Get the 2nd byte.
	;
	dec	cx			; cx = 1 more byte read
	jz	partialChar		; => incomplete
	mov	ah, al			; ah = high byte
	lodsb				; ax = char, maybe invalid

gotChar:
	;
	; Convert the possibly invalid character to GEOS and store it.
	;
	call	DosGBToGeosChar		; ax = Chars, CF if error
	jc	done			; => error
	stosw				; store GEOS char

done:
	.leave
	ret

partialChar:
	;
	; Read first byte of a two byte character, but second byte
	; is not there to read.  We increment cx because although
	; the character was supposed to be a 2-byte character,
	; the second byte wasn't there so we haven't read it.
	;
	inc	cx			; cx = one more byte
	mov	ax, DTGSS_CHARACTER_INCOMPLETE or (1 shl 8)
	stc				; error
	jmp	done

DosGBToGeosCharString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosGBCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a GB DOS character

CALLED BY:	DCSConvertToDOS
PASS:		bx	= DosCodePage
		ds:si	= GEOS string
		es:di	= DOS buffer
RETURN:		carry set if error
			al	= DTGSS_SUBSTITUTIONS
			ah	= 0
		carry clear if okay
			ax	= GB 2312 EUC character
		ds:si	= ptr to next character
		es:di	= ptr to next character
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/26/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosGBCharString	proc	near

	;
	; Get the GEOS character from the string
	;
	lodsw				; ax = Chars

	;
	; Convert the character
	;
	call	GeosToDosGBChar		; ax = DOS char
	jc	done			; => error

	;
	; Store the character in as few bytes as it will fit in
	;
	tst_clc	ah			; one byte?
	jz	oneByte			; => yes
	xchg	al, ah			; high byte goes first
	stosw				; store two bytes

	ret

oneByte:
	stosb				; store one byte

done:
	ret
GeosToDosGBCharString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosGBCharFileString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a GB DOS char
		suitable for a filename

CALLED BY:	DCSGeosToDosCharFileStringCurBX, DCSGeosToDosCharFileString
PASS:		bx	= DosCodePage
		ds:si	= GEOS string
		es:di	= DOS byffer
		cx	= size of DOS buffer in bytes
RETURN:		carry set if error
			ax	= '_'
		carry clear if okay
			ax	= DOS character (ah = 0)
		ds:si	= next character
		es:di	= next character
		cx	= # of bytes updated if >1 byte read
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	2/27/01    	Initial version (copied from
				GeosToDosSJISCharFileString)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosGBCharFileString	proc	near

	;
	; Get the character
	;
	lodsw				; ax = Chars

	;
	; allow null
	;
	tst_clc	ax
	jz	storeOneByte		; => null

	;
	; Make sure it is a legal DOS filename character, special
	; casing that we know none of the illegal DOS characters
	; are above 0x80.
	;
	cmp	ax, MIN_DOS_TO_GEOS_CHAR
	ja	gotChar
	call	DOSVirtCheckLegalDosFileChar
	jnc	illegalChar

	;
	; Upcase it first since DOS is goofy and does not support lowercase.
	; We cannot use LocalUpcaseChar() since it is in a movable resource
	; and therefore may need to be loaded by us.
	;
	cmp	ax, C_LATIN_SMALL_LETTER_Z
	ja	gotChar
	cmp	ax, C_LATIN_SMALL_LETTER_A
	jb	gotChar
	sub	ax, C_LATIN_SMALL_LETTER_A - C_LATIN_CAPITAL_LETTER_A
					; ax = lowercase letter
gotChar:
	;
	; Convert the character to GB
	;
	call	GeosToDosGBChar
	jc	illegalChar

	;
	; Store the character in as few bytes as it will fit in
	;
	tst_clc	ah			; one byte?
	jz	storeOneByte		; => yes

	;
	; Make sure a 2-byte character will fit.  If not, flag
	; an error and replace it with a 1-byte character.
	;
	dec	cx			; cx = less byte
	jz	legalCharWontFit	; => no space

	;
	; Store a two-byte character
	;
	xchg	al, ah			; high byte goes first
	stosw				; store two bytes

	ret

legalCharWontFit:
	;
	; It is a legal character, but it won't fit.
	;
	inc	cx			; cx = 1 more byte

illegalChar:
	;
	; The character did not map or fit -- replace with '_'
	;
	stc				; error
	mov	ax, '_'			; ax = default char

	;
	; Store a one-byte character
	;
storeOneByte:
	stosb				; store one byte

	ret
GeosToDosGBCharFileString	endp

Resident	ends
