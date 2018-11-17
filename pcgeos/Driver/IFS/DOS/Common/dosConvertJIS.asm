COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosConvertJIS.asm

AUTHOR:		Gene Anderson, Dec 21, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	12/21/93		Initial revision


DESCRIPTION:
	Code for JIS support.

	$Id: dosConvertJIS.asm,v 1.1 97/04/10 11:55:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

DosJISToGeosChar		proc	near
		call	DosJISToGeosCharFar
		ret
DosJISToGeosChar		endp

GeosToDosJISChar		proc	near
		call	GeosToDosJISCharFar
		ret
GeosToDosJISChar		endp

DosJISToGeosCharString		proc	near
		call	DosJISToGeosCharStringFar
		ret
DosJISToGeosCharString		endp

GeosToDosJISCharString		proc	near
		call	GeosToDosJISCharStringFar
		ret
GeosToDosJISCharString		endp


DosSJISToGeosCharFar		proc	far
		call	DosSJISToGeosChar
		ret
DosSJISToGeosCharFar		endp

GeosToDosSJISCharFar		proc	far
		call	GeosToDosSJISChar
		ret
GeosToDosSJISCharFar		endp

Resident	ends

ConvertRare	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosJISToGeosCharFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a JIS character to a GEOS character

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ax - JIS character
RETURN:		carry - set if error
			ah - 0

			al - DTGSS_SUBSTITUTIONS or
			al - DTGSS_INVALID_CHARACTER
		else:
			ax - GEOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This should deal with JIS characters that are not in SJIS.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosJISToGeosCharFar		proc	far
		.enter
	;
	; Convert the JIS character to SJIS
	;
		call	ConvJISToSJIS
		jc	done
	;
	; Convert the SJIS character to GEOS
	;
		call	DosSJISToGeosCharFar
done:

		.leave
		ret
DosJISToGeosCharFar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosJISCharFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character to a JIS character.

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ax - GEOS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - JIS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This should deal with JIS characters that are not in SJIS.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosJISCharFar		proc	far
		.enter

	;
	; Convert the GEOS character to SJIS
	;
		call	GeosToDosSJISCharFar
		jc	done
	;
	; Convert the SJIS character to JIS
	;
		call	ConvSJISToJIS
done:

		.leave
		ret
GeosToDosJISCharFar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvJISToSJIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a JIS character to SJIS

CALLED BY:	DosJISToGeosCharFar()
PASS:		ax - JIS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
			al - DTGSS_INVALID_CHARACTER
		else:
			ax - SJIS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	c1 = j/256;
	c2 = j%256;

	rowOffset = (c1 < 95) ? 112 : 176;
	cellOffset = (c1 % 2) ? (31 + (c2 > 95)) : 126;

	r1 = ((c1 + 1) >> 1) + rowOffset;
 	r2 = c2 + cellOffset;
	return(r1*256 + r2);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvJISToSJIS		proc	near
		uses	dx
		.enter
	;
	; Check for SBCS character
	;
		tst	ah			;SBCS JIS char?
		jz	done			;branch if SBCS
	;
	; dh = rowOffset = (c1 < 95) ? 112 : 176;
	;
		mov	dh, 112			;dh <- row offset
		cmp	ah, 95
		jb	gotRowOffset
		mov	dh, 176			;dh <- row offset
gotRowOffset:
	;
	; dl = cellOffset = (c1 % 2) ? (31 + (c2 > 95)) : 126;
	;
		mov	dl, 126			;dl <- cell offset
		test	ah, 0x1
		jz	gotCellOffset		;branch if false
		mov	dl, 31			;dl <- cell offset
		cmp	al, 95			;branch if false
		jbe	gotCellOffset
		inc	dl			;dl <- cell offset
gotCellOffset:
	;
	; r1 = ((c1 + 1) >> 1) + rowOffset
	;
		inc	ah
		shr	ah, 1
		add	ah, dh
	;
	; r2 = c2 + cellOffset;
	;
		add	al, dl

done:
		.leave
		ret
ConvJISToSJIS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvSJISToJIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a SJIS character to JIS

CALLED BY:	GeosToDosJISCharFar()
PASS:		ax - SJIS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
			al - DTGSS_INVALID_CHARACTER
		else:
			ax - JIS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	c1 = j/256;
	c2 = j%256;

	adjust = c2 < 159;
	rowOffset = c1 < 160 ? 112 : 176;
	cellOffset = adjust ? (31 + (c2 > 127)) : 126;

	r1 = ((c1 - rowOffset) << 1) - adjust;
	r2 = c2-cellOffset;

	return(r1*256+r2);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvSJISToJIS		proc	near
		uses	cx, dx
		.enter

	;
	; Check for SBCS character
	;
		tst	ah			;SBCS SJIS char?
		jz	done			;branch if SBCS

		clr	cx			;cx <- adjust (0)
		cmp	al, 159
		jae	gotAdjust
		inc	cx			;cx <- adjust (1)
gotAdjust:
	;
	; dh = rowOffset = c1 < 160 ? 112 : 176;
	;
		mov	dh, 112			;dh <- row offset
		cmp	ah, 160
		jb	gotRowOffset
		mov	dh, 176			;dh <- row offset
gotRowOffset:
	;
	; dl = cellOffset = adjust ? (31 + (c2 > 127)) : 126;
	;
		mov	dl, 126			;dl <- cell offset
		jcxz	gotCellOffset		;branch if false
		mov	dl, 31			;dl <- cell offset
		cmp	al, 127
		jbe	gotCellOffset		;branch if false
		inc	dl			;dl <- cell ofset
gotCellOffset:
	;
	; r1 = ((c1 - rowOffset) << 1) - adjust;
	;
		sub	ah, dh
		shl	ah, 1
		sub	ah, cl
	;
	; r2 = c2-cellOffset;
	;
		sub	al, dl
done:
		.leave
		ret
ConvSJISToJIS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosJISToGeosCharStringFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a JIS character in a string to a GEOS character

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to JIS string
		es:di - ptr to GEOS buffer
		cx - max # of bytes to read
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
			ah - # of bytes to back up
			al - DTGSS_CHARACTER_INCOMPLETE
		else:
			ax - GEOS character
		ds:si - ptr to next character
		es:di - ptr to next character
		cx - updated if >1 byte read
		bx - DosCodePage (may have changed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosJISToGeosCharStringFar		proc	far
		.enter

	;
	; Get a byte and see if it is the start of an escape sequence
	;
nextChar:
		lodsb				;al <- byte of JIS string
		cmp	al, C_ESCAPE		;<Esc>?
		je	handleEsc
	;
	; See if we are doing SBCS or DBCS
	;
		cmp	bx, CODE_PAGE_JIS	;doing SBCS?
		jne	isDBCS			;branch if not
	;
	; Reading SBCS -- just use the byte
	;
		call	doSBCSChar		;ax = GEOS char
		jc	exit
	;
	; Store the GEOS character
	;
storeChar:
		stosw				;store GEOS character
exit:
		.leave
		ret

	;
	; Read first byte of a two byte character, or first one or
        ; two bytes of three byte ESC seq, but rest is not there to read
	;
partialChar3:
		mov	ah, 3			;ah <- # bytes to back up
		jmp	partialCharCommon
partialChar2:
		mov	ah, 2			;ah <- # bytes to back up
		jmp	partialCharCommon
partialChar1:
		mov	ah, 1			;ah <- # bytes to back up
partialCharCommon:
		mov	al, DTGSS_CHARACTER_INCOMPLETE
		stc				;carry <- error
		jmp	exit

	;
	; Reading DBCS -- get another byte
	;
isDBCS:
		call	readDBCSByte2
		jz	partialChar1		;branch if partial character
	;
	; Convert JIS to GEOS
	;
		call	DosJISToGeosCharFar
		jc	exit			;branch if error
		jmp	storeChar

	;
	; We've hit an <Esc> -- switch modes if necessary.
	;
handleEsc:
		call	readDBCSByte1		;al <-  byte after ESC
		jz	partialChar1
		call	readDBCSByte2		;ax <- both bytes after ESC
		jz	partialChar2		;branch if partial character
		cmp	bx, CODE_PAGE_JIS	;in SBCS or DBCS?
		je	inSBCS			;branch if in SBCS
	;
	; We're in DBCS -- check for an escape to SBCS
	;
		cmp	ax, JIS_C_0208_1978_KANJI_ESC
		je	doneEscape		;allow redundant escape
		cmp	ax, JIS_X_0208_1983_KANJI_ESC
		je	doneEscape		;allow redundant escape
		cmp	ax, ANSI_X34_1986_ASCII_ESC
		je	switchToSBCS
		cmp	ax, JIS_X_0201_1976_ROMAN_ESC
		je	switchToSBCS
	;
	; other escape sequence while in double byte JIS mode,
	; return error as ESC is illegal JIS first byte
	;
		mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
		stc				;carry <- error
		jmp	exit

switchToSBCS:
		mov	bx, CODE_PAGE_JIS	;bx <- new DosCodePage
		jmp	doneEscape

	;
	; We're in SBCS -- check for an escape to DBCS
	;
inSBCS:
		cmp	ax, ANSI_X34_1986_ASCII_ESC
		je	doneEscape		;allow redundant escape
		cmp	ax, JIS_X_0201_1976_ROMAN_ESC
		je	doneEscape		;allow redundant escape
		cmp	ax, JIS_C_0208_1978_KANJI_ESC
		je	switchToDBCS
		cmp	ax, JIS_X_0208_1983_KANJI_ESC
		je	switchToDBCS
	;
	; other escape sequence while in JIS single byte mode
	; -- store the three bytes in GEOS format
	;	ESC = 1st byte
	;	ah = 2nd byte
	;	al = 3rd byte
	;	cx = (number of characters after escape) + 1
	;
		push	dx
		mov	dx, ax			;save 2nd and 3rd bytes
		mov	ax, C_ESCAPE		;first is escape
		stosw				;store 1st char
		clr	ax
		mov	al, dh			;ax = 2nd byte
		call	doSBCSChar
		jc	doneEscapePop
		stosw				;store 2nd char
		clr	ax
		mov	al, dl			;ax = 3rd byte
		call	doSBCSChar
		jc	doneEscapePop
		stosw
doneEscapePop:
	;
	; finish off non-recognized escape sequence
	;
		pop	dx
		dec	cx
		jnz	nextChar
		clc				;indicate success
		jmp	exit

doneEscape:
	;
	; finish off a recognized escape sequence -- return "incomplete" error
	; if nothing follows the escape sequence.  This is because we
	; are expected to return a converted character, and at this
	; point we have read nothing but the escape sequence.
	;
		dec	cx
		jz	partialChar3
		jmp	nextChar

switchToDBCS:
	;
	; Switch to DBCS
	;
		mov	bx, CODE_PAGE_JIS_DB	;bx <- new DosCodePage
		jmp	doneEscape


	;
	; al = SBCS char
	;
doSBCSChar:
		clr	ah			;ax <- ASCII char
	;
	; Handle half-width katakana (JIS same as SJIS)
	;
		cmp	al, SJIS_SB_START_2
		jb	doSBCSReturn		;not half-width katakana
		cmp	al, SJIS_SB_END_2
		ja	doSBCSReturn		;not half-width katakana
		call	DosJISToGeosCharFar	;convert half-width katakana
		retn				;return status in carry flag
doSBCSReturn:
		clc				;indicate success
		retn

readDBCSByte1:
		dec	cx			;cx <- read one more byte
		jz	isPartialChar		;branch if no more bytes
		lodsb				;al <- 1st byte
		retn
readDBCSByte2:
		dec	cx			;cx <- read one more byte
		jz	isPartialChar		;branch if no more bytes
		xchg	al, ah
		lodsb				;ax <- JIS character
isPartialChar:
		retn

DosJISToGeosCharStringFar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosJISCharStringFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a JIS character

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to GEOS string
		es:di - ptr to JIS buffer
		cx - max # of chars to read
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - JIS character
		ds:si - ptr to next character
		es:di - ptr to next character
		bx - DosCodePage (may have chanaged)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosJISCharStringFar		proc	far
		.enter

	;
	; Get a GEOS character and convert to JIS
	;
		lodsw				;ax <- GEOS character
		call	GeosToDosJISCharFar
		jc	exit			;branch if error
	;
	; Check for ASCII / SBCS
	;
		tst	ah			;SBCS or DBCS?
		jnz	isDBCS			;branch if DBCS
	;
	; ASCII char -- make sure we're in SBCS mode
	;
		cmp	bx, CODE_PAGE_JIS
		jne	switchToSBCS
storeSBCSChar:
		stosb				;store SBCS character
done:
		clc				;carry <- no error
exit:

		.leave
		ret

	;
	; Switch to SBCS and emit the proper escape sequence
	;
switchToSBCS:
		mov	bx, offset escapeToSBCS
		call	writeEsc
		mov	bx, CODE_PAGE_JIS
		jmp	storeSBCSChar

	;
	; DBCS char -- make sure we're in DBCS mode
	;
isDBCS:
		cmp	bx, CODE_PAGE_JIS_DB
		jne	switchToDBCS
storeDBCSChar:
		xchg	al, ah			;store high-low
		stosw				;store DBCS character
		jmp	done

	;
	; Switch to SBCS and emit the proper escape sequence
	;
switchToDBCS:
		mov	bx, offset escapeToDBCS
		call	writeEsc
		mov	bx, CODE_PAGE_JIS_DB
		jmp	storeDBCSChar

	;
	; Emit a 3-byte escape sequence
	;
escapeToSBCS	byte	0x1b, 0x28, 0x4a	;<ESC> ( J
escapeToDBCS	byte	0x1b, 0x24, 0x42	;<ESC> $ B

writeEsc:
		push	ds, si
		segmov	ds, cs
		mov	si, bx
		movsb
		movsb
		movsb
			CheckHack <(length escapeToSBCS) eq 3>
		pop	ds, si
		retn

GeosToDosJISCharStringFar		endp

ConvertRare	ends
