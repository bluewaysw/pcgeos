COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosConvertEUC.asm

AUTHOR:		Greg Grisco, May 10, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94	Initial revision


DESCRIPTION:
	Code for EUC support.

	EUC Code Set 4 is not currently supported.

	$Id: dosConvertEUC.asm,v 1.1 97/04/10 11:55:11 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

DosEUCToGeosChar		proc	near
		call	DosEUCToGeosCharFar
		ret
DosEUCToGeosChar		endp

GeosToDosEUCChar		proc	near
		call	GeosToDosEUCCharFar
		ret
GeosToDosEUCChar		endp

DosEUCToGeosCharString		proc	near
		call	DosEUCToGeosCharStringFar
		ret
DosEUCToGeosCharString		endp

GeosToDosEUCCharString		proc	near
		call	GeosToDosEUCCharStringFar
		ret
GeosToDosEUCCharString		endp

Resident	ends

ConvertRare	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvEUCToJIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a EUC char to a JIS char

CALLED BY:	DosEUCToGeosCharFar
PASS:		ax - EUC character
RETURN:		carry set on error
			ah - 0
			al - DTGSS_INVALID_CHARACTER
		else
			ax - JIS character
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	simply subtract 0x80 from both bytes.
	This means un-setting the high bits of both bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvEUCToJIS	proc	near

	;
	; test the high byte first
	;

	test	ah, HIGH_BIT_MASK		;high bit must be set
	jz	notEUCChar

	;
	; convert the high byte
	;

	and	ah, not HIGH_BIT_MASK		;clear high bit & carry

	test	al, HIGH_BIT_MASK		;high bit must be set
	jz	notEUCChar

	;
	; convert the low byte
	;

	and	al, not HIGH_BIT_MASK		;clear high bit & carry
done:
	ret

notEUCChar:
	mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
	stc
	jmp	done

ConvEUCToJIS	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvJISToEUC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a JIS char to a EUC char

CALLED BY:	GeosToDosEUCCharFar, GeosToDosEUCCharStringFar
PASS:		ax - JIS character
RETURN:		carry set on error
			ah - 0
			al - DTGSS_INVALID_CHARACTER
		else
			ax - EUC character
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	simply add 0x80 to both bytes.
	This means setting the high bits of both bytes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvJISToEUC	proc	near

	;
	;test high byte first
	;

	test	ah, HIGH_BIT_MASK		;high bit must be clear
	jnz	notJISChar

	;
	; convert the high byte
	;

	or	ah, HIGH_BIT_MASK		;set high bit & clear carry

	test	al, HIGH_BIT_MASK		;high bit must be clear
	jnz	notJISChar

	;
	; convert the low byte
	;

	or	al, HIGH_BIT_MASK		;set high bit & clear carry
done:
	ret

notJISChar:
	mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
	stc					;error -- not a JIS char
	jmp	done

ConvJISToEUC	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosEUCToGeosCharFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a EUC character to a GEOS character

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ax - EUC character
RETURN:		carry - set if error
			ah - 0

			al - DTGSS_SUBSTITUTIONS or
			al - DTGSS_INVALID_CHARACTER
		else:
			ax - GEOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosEUCToGeosCharFar		proc	far
		.enter

	;
	; If Half-width Katakana, then JIS is same as EUC value
	;

	tst	ah				;is double byte?
	jnz	notHalfWidthKatakanaOrAscii
	cmp	al, EUC_CODE_SET_2_END
	jbe	halfWidthKatakanaOrAscii

notHalfWidthKatakanaOrAscii:

	;
	; Convert the EUC character to JIS
	;

	call	ConvEUCToJIS
	jc	done

halfWidthKatakanaOrAscii:

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
DosEUCToGeosCharFar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosEUCCharFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character to an EUC character.

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ax - GEOS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - EUC character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosEUCCharFar		proc	far
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
	jc	done

	;
	; Convert the JIS character to EUC
	;

	tst	ah			;is Ascii or HW-Katakana?
	jz	done
	call	ConvJISToEUC
done:

	.leave
	ret
GeosToDosEUCCharFar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosEUCToGeosCharStringFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a EUC character in a string to a GEOS character

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to EUC string
		es:di - ptr to GEOS buffer
		cx - max # of bytes to read
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_INVALID_CHARACTER
			ah - # of bytes to back up
			al - DTGSS_CHARACTER_INCOMPLETE
		else:
			ax - GEOS character
		ds:si - ptr to next character
		es:di - ptr to next character
		cx - updated if >1 byte read
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosEUCToGeosCharStringFar		proc	far
		.enter

	;
	; Get a byte and see which code set it lies in
	;

	lodsb				;al <- byte of EUC string
	cmp	al, EUC_SS2_CHAR	;single shift char?
	je	doHalfWidthKatakana	;in CODE SET 2

	cmp	al, EUC_CODE_SET_0_START
	jb	illegalChar		;out of range
	cmp	al, EUC_CODE_SET_0_END
	jbe	doAsciiJISRoman		;in CODE SET 0
		
	cmp	al, EUC_CODE_SET_1_START
	jb	illegalChar		;out of range
	cmp	al, EUC_CODE_SET_1_END
	ja	illegalChar

	; in CODE SET 1 -- JIS

	; We have first of two bytes, read the second then convert.

doJISChar:
	call	readDBCSByte2
	jz	partialChar

	; We have both bytes.  Do the conversion and check for error.

	call	DosEUCToGeosCharFar
	jc	exit
storeChar:
	stosw
exit:	
	.leave
	ret

	;
	; Read first byte of a two byte character, but rest 
	; is not there to read.
	;

partialChar:
	mov	ax, DTGSS_CHARACTER_INCOMPLETE or (1 shl 8)
	stc				;carry <- error
	jmp	exit			;couldn't convert

	; We have read the Single Shift char.  Read next byte into al,
	; clear high byte, then convert.

doHalfWidthKatakana:
	clr	al			;will be xchnged to ah
	jmp	doJISChar		;store it/no convert
doAsciiJISRoman:
	clr	ah
	jmp	storeChar
readDBCSByte2:
	dec	cx			;cx <- read one more byte
	jz	isPartialChar		;branch if no more bytes
	xchg	al, ah
	lodsb				;ax <- JIS character
isPartialChar:
	retn
illegalChar:
	stc
	mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
	jmp	exit

DosEUCToGeosCharStringFar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosEUCCharStringFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a EUC character

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to GEOS string
		es:di - ptr to EUC buffer
		cx - max # of chars to read
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - EUC character
		ds:si - ptr to next character
		es:di - ptr to next character
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	05/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosEUCCharStringFar		proc	far
		uses bx
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
	jz	isSBCS			;branch if SBCS

	;
	; DBCS char -- convert to EUC then store
	;

	call	ConvJISToEUC
	jc	exit

	xchg	al, ah			;store high-low
	stosw				;store DBCS character
done:
	clc				;carry <- no error
exit:
	.leave
	ret
isSBCS:
	;
	; SB -- ASCII or Half-width Katakana char
	;

	cmp	al, EUC_CODE_SET_0_START
	jb	illegalChar
	cmp	al, EUC_CODE_SET_0_END
	jbe	storeSBCSChar		;is Ascii/JIS Roman?
	cmp	al, EUC_CODE_SET_2_START
	jb	illegalChar
	cmp	al, EUC_CODE_SET_2_END
	ja	illegalChar

	;
	; Half-width Katakana character.  Store Single Shift char + byte
	;

	mov	bx, EUC_SS2_CHAR	;Single Shift 2
	call	writeSingleShift	

storeSBCSChar:
	stosb				;store SBCS character
	jmp	done
writeSingleShift:
	push	ax			;save current char
	mov_tr	al, bl			;al <- single shift char
	stosb
	pop	ax			;ax <- current char
	retn
illegalChar:
	mov	ax, DTGSS_SUBSTITUTIONS or (0 shl 8)
	stc
	jmp	exit

GeosToDosEUCCharStringFar		endp

ConvertRare	ends
