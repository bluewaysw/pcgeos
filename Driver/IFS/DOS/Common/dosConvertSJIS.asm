COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosConvertSJIS.asm

AUTHOR:		Gene Anderson, Oct 20, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/20/93		Initial revision


DESCRIPTION:
	Code for SJIS support.  For a more detailed explanation of SJIS,
	see dosConstantSJIS.def and "Understanding Japanese Information
	Processing" by Ken Lunde.

	$Id: dosConvertSJIS.asm,v 1.1 97/04/10 11:55:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosSJISToGeosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a SJIS DOS character to a GEOS character

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ax - SJIS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
			al - DTGSS_INVALID_CHARACTER
		else:
			ax - GEOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosSJISToGeosChar		proc	near
		.enter

	;
	; At this point, everything is 16-bit, so we don't need to
	; recheck the range starts.
	;
	; Check for trivial case (ASCII == single byte).
	;
		cmp	ax, SJIS_SB_END_1
		jbe	doneConvert
	;
	; Check for simple case (halfwidth katakana == single byte).
	;
		cmp	ax, SJIS_SB_END_2
		jbe	isHalfwidth
	;
	; See if it is a valid DBCS SJIS character
	;
		cmp	ax, SJIS_DBCS_START_1
		jb	notSJISChar
		cmp	al, SJIS_DB2_START_1
		jb	notSJISChar
	;
	; If the character falls within the 16K gap, then
	; it is not a valid DBCS SJIS character.

		cmp	ax, SJIS_DBCS_END_1
		jbe	notInGap
		cmp	ax, SJIS_DBCS_START_2
		jb	notSJISChar
	;
	; There is another gap of invalid chars from 0xEAB0 to the
	; first IMB/NEC extension char.
	;
		cmp	ax, SJIS_DBCS_GAP2_START
		jb	notInGap
		cmp	ax, SJIS_DBCS_GAP2_END
		jbe	notSJISChar
	;
	; We should check Gaiji & IBM extensions ranges
	; First, IBM extension code authorized by NEC:
	;
		cmp	ax, SJIS_IBM_NEC_START
		jb	notInGap
		cmp	ax, SJIS_IBM_NEC_END
		jbe	notInGap
	;
	; Is it in the Gaiji user-defined range?
	;
		cmp	ax, SJIS_GAIJI_START
		jb	notSJISChar
		cmp	ax, SJIS_GAIJI_END
		jbe	notInGap
	;
	; Finally, we check the IBM extension code range
	;
		cmp	ax, SJIS_IBM_START
		jb	notSJISChar
		cmp	ax, SJIS_IBM_END
		ja	notSJISChar
	;
	; The character is a DBCS SJIS character.
	;
notInGap:
		push	bx
		mov	bx, offset miscToGeosConvEntry
		call	ConvSJISToGeosInt
		pop	bx
	;
	; See if character mapped to anything
	;
		tst	ax			;char mapped?
		jz	notSJISChar		;branch if not mapped
doneConvert:
		clc				;carry <- no error
exit:

		.leave
		ret

	;
	; See if valid SBCS char
	;
isHalfwidth:
		cmp	ax, SJIS_SB_START_2
		jb	notSJISChar
	;
	; Convert halfwidth katakana to GEOS
	;
		add	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD - SJIS_SB_START_2
		jmp	doneConvert


	;
	; Character cannot be mapped -- return an error
	;
notSJISChar:
		mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
;		mov	ax, DTGSS_SUBSTITUTIONS or (0 shl 8)
		stc				;carry <- char not mapped
		jmp	exit
DosSJISToGeosChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosSJISChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character to a SJIS DOS character.

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ax - GEOS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - SJIS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosSJISChar		proc	near
	;
	; Check for trivial case (ASCII == single byte).
	;
		cmp	ax, C_DELETE
		jbe	doneConvert
	;
	; Check for simple case (halfwidth katakana == single byte).
	;
		cmp	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD
		jb	notKatakana
		cmp	ax, C_HALFWIDTH_KATAKANA_VOICED_ITERATION_MARK
		jbe	isHalfwidth
	;
	; Check for Kanji vs. miscellaneous char (see DosSJISToGeosChar)
	; and convert.
	;
notKatakana:
		push	bx, cx, di
		cmp	ax, UNICODE_KANJI_START
		jb	isMisc
		cmp	ax, UNICODE_KANJI_END
		jbe	isKanji

		cmp	ah, UNICODE_GAIJI_START_HIGH_BYTE
		jb	isMisc
		cmp	ah, UNICODE_GAIJI_END_HIGH_BYTE
		jbe	isGaiji

		cmp	ax, UNICODE_IBM_NEC_START
		jb	isMisc
		cmp	ax, UNICODE_IBM_NEC_END
		jbe	isIBMNec

		cmp	ax, UNICODE_IBM_START
		jb	isMisc
		cmp	ax, UNICODE_IBM_END
		jbe	isIBM
	;
	; Convert GEOS character to SJIS character
	;
isMisc:
		mov	cx, length SJISMiscToUnicodeTable
		mov	di, offset SJISMiscToUnicodeTable
		mov	bx, offset miscToGeosConvEntry
		call	ConvGeosToDBCSSJISInt
doneConvertDBCS:
		pop	bx, cx, di
		jc	notFound		;branch if not found

doneConvert:
		clc				;carry <- no error
done:
		ret
isGaiji:
		add	ah, GAIJI_SJIS_UNICODE_DIFF
		jmp	doneConvertDBCS
isIBMNec:
		add	ax, IBM_NEC_SJIS_UNICODE_DIFF
		jmp	doneConvertDBCS
isIBM:		
		add	ax, IBM_SJIS_UNICODE_DIFF
		jmp	doneConvertDBCS
	;
	; Convert halfwidth katakana to GEOS
	;
isHalfwidth:
		sub	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD - SJIS_SB_START_2
		jmp	doneConvert

notFound:
;		mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
		mov	ax, DTGSS_SUBSTITUTIONS or (0 shl 8)
		stc				;carry <- error
		jmp	done

	;
	; Convert GEOS Kanji character to SJIS
	;
isKanji:
		mov	bx, offset kanjiToGeosConvEntry
		call	ConvKanjiGeosToSJISInt
		jmp	doneConvertDBCS
GeosToDosSJISChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosSJISToGeosCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a SJIS DOS character in a string to a GEOS character

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to DOS string
		es:di - ptr to GEOS buffer
		cx - max # of bytes to read
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS or 

			ah - # characters to back up
			al - DTGSS_CHARACTER_INCOMPLETE or

			ah - 0
			al - DTGSS_INVALID_CHARACTER
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
	gene	10/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosSJISToGeosCharString		proc	near
		.enter

	;
	; Get a character from the string -- 1 or 2 bytes
	;
		clr	ah			;ah <- assume single byte
		lodsb				;al <- get 1st byte
		cmp	al, SJIS_SB_END_1	;in first SBCS range?
		jbe	gotChar			;branch if SBCS
		cmp	al, SJIS_SB_START_2	;DBCS range?
		jb	isDBCS
		cmp	al, SJIS_SB_END_2	;in second SBCS range?
		jbe	gotChar			;branch if SBCS
	;
	; Character is two bytes -- get the 2nd byte
	;
isDBCS:
		dec	cx			;cx <- 1 more byte read
		jz	partialChar		;branch if incomplete
		xchg	ah, al			;ah <- 1st byte
		lodsb				;al <- get 2nd byte
		cmp	al, SJIS_DB2_START_1
		jb	illegalChar
		cmp	al, SJIS_DB2_END_1
		jbe	isOK
		cmp	al, SJIS_DB2_START_2
		jb	illegalChar
		cmp	al, SJIS_DB2_END_2
		ja	illegalChar
isOK:
	;
	; Convert the character to GEOS and store it
	;
gotChar:
		call	DosSJISToGeosChar	;ax <- GEOS character
;EC <		ERROR_C DOS_CHAR_COULD_NOT_BE_MAPPED
		jc	done			;branch if error
		stosw				;store GEOS character
done:
		.leave
		ret

	;
	; Read first byte of a two byte character, but second byte
	; is not there to read.  We increment cx because although
	; the character was supposed to be a 2-byte character,
	; the second byte wasn't there so we haven't read it.
	;
partialChar:
		inc	cx			;cx <- one more byte
		mov	ax, DTGSS_CHARACTER_INCOMPLETE or (1 shl 8)
		stc				;carry <- error
		jmp	done

illegalChar:
		mov	ax, DTGSS_INVALID_CHARACTER or (0 shl 8)
		stc				;carry <- error
		jmp	done
DosSJISToGeosCharString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosSJISCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a SJIS DOS character

CALLED BY:	DCSConvertToGEOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to GEOS string
		es:di - ptr to DOS buffer
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - DOS character
		ds:si - ptr to next character
		es:di - ptr to next character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/20/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosSJISCharString		proc	near
	;
	; Get the GEOS character from the string
	;
		lodsw				;ax <- GEOS character
	;
	; Convert the character
	;
		call	GeosToDosSJISChar
		jc	done			;branch if error
	;
	; Store the character in as few bytes as it will fit in
	;
		tst	ah			;SBCS? (clears carry)
		jz	isSBCS			;branch if SBCS
	;
	; Store the character
	;
isDBCS::
		xchg	al, ah
		stosw				;store DBCS char
		ret

isSBCS:
		stosb				;store SBCS char
done:
		ret
GeosToDosSJISCharString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosSJISCharFileString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a SJIS DOS char
		suitable for a filename

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to GEOS string
		es:di - ptr to DOS buffer
		cx - # of bytes
RETURN:		carry - set if error
			ax - '_'
		else:
			ax - DOS character (ah = 0)
		ds:si - ptr to next character
		es:di - ptr to next character
		cx - # of bytes updated if >1 byte read
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosSJISCharFileString	proc	near
	;
	; Get the character
	;
		lodsw				;ax <- GEOS character
	;
	; allow null
	;
		tst_clc	ax
		jz	storeSBCS		;(carry clear)
	;
	; Make sure it is a legal DOS filename character, special
	; casing that we know none of the illegal DOS characters
	; are above 0x80.
	;
		cmp	ax, 0x80
		ja	gotChar
		call	DOSVirtCheckLegalDosFileChar
		jnc	illegalChar		;branch if not legal
	;
	; Upcase it first since DOS is goofy and does not support lowercase.
	; We cannot use LocalUpcaseChar() since it is in a movable resource
	; and therefore may need to be loaded by us.
	;
		cmp	ax, 'z'
		ja	gotChar
		cmp	ax, 'a'
		jb	gotChar
		sub	ax, 'a'-'A'		;ax <- lowercase letter
gotChar:
	;
	; Convert the character to SJIS
	;
		call	GeosToDosSJISChar
		jc	illegalChar		;branch if error
	;
	; Store the character in as few bytes as it will fit in
	;
		tst	ah			;SBCS? (clears carry)
		jz	storeSBCS		;branch if SBCS
	;
	; Make sure a 2-byte character will fit.  If not, flag
	; an error and replace it with a 1-byte character.
	;
isDBCS::
		dec	cx			;cx <- 1 less byte
		jz	legalCharWontFit	;branch if no space
	;
	; Store a DBCS character
	;
		xchg	al, ah
		stosw				;store DBCS char
		ret

	;
	; It is a legal character, but it won't fit.
	;
legalCharWontFit:
		inc	cx			;cx <- 1 more byte
	;
	; The character did not map or fit -- replace with '_'
	;
illegalChar:
		stc				;carry <- error
		mov	ax, '_'			;ax <- default char
	;
	; Store a SBCS character
	;
storeSBCS:
		stosb				;store SBCS char
		ret
GeosToDosSJISCharFileString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvSJISToGeosInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a SJIS character to a GEOS character given a range

CALLED BY:	DosSJISToGeosChar()
PASS:		ax - SJIS character
		cs:bx - ptr to ConvSJISToGEOSStruct
RETURN:		ax - GEOS character
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
	SJIS has a gap between 0xa000-0xe000 which is the character values
	which are not DBCS chars because the lead byte is a SBCS char.
	SJIS has gaps in each ward from 0x##00-0x##40 which means those
	character values represent only themselves in SJIS.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvSJISToGEOSStruct	struct
    CSJTGS_start	word			;start value of table
    CSJTGS_table	nptr.Chars		;ptr to lookup table
ConvSJISToGEOSStruct	ends

miscToGeosConvEntry	ConvSJISToGEOSStruct <
	SJIS_MISC_START,
	offset SJISMiscToUnicodeTable
>

kanjiToGeosConvEntry	ConvSJISToGEOSStruct <
	SJIS_KANJI_START,
	offset SJISKanjiToUnicodeTable
>

ConvSJISToGeosInt		proc	near
		uses	cx, dx
		.enter
	;
	; Check for the gap from 0xa000-0xe000
	;
		cmp	ax, SJIS_DBCS_START_2
		jb	noGap
	;
	; First, check if below user-defined range
	;
		cmp	ax, SJIS_IBM_NEC_START
		jb	doGap
	;
	; Which extension code?  IBM (NEC)? Gaiji?  IBM?  We've already
	; verified that the character doesn't fall within the gaps in
	; DosSJISToGeosChar().
	;
		cmp	ax, SJIS_IBM_NEC_END
		jbe	ibmNec
		cmp	ax, SJIS_GAIJI_END
		jbe	gaiji
		cmp	ax, SJIS_IBM_END
		jbe	ibm
doGap:
		sub	ax, (SJIS_DB1_START_2 shl 8)-SJIS_DBCS_END_1-1
noGap:
	;
	; Adjust to table start
	;
		sub	ax, cs:[bx].CSJTGS_start
		mov	dx, ax
	;
	; Account for gaps from 0x##00-0x##40 in each ward.  This amounts
	; to multiplying the character value by 1/256*192.  Instead, we
	; multiply the high byte by 1/4 and subtract that from the char
	; value because it is easier & faster.  (/256 ignores the low byte)
	;
		clr	dl
		shr	dx, 1
		shr	dx, 1			;dx <- ax*1/4
		sub	ax, dx			;ax <- adjust char
	;
	; Do the table lookup
	;
		shl	ax, 1			;ax <- offset into table (words)
		mov	bx, cs:[bx].CSJTGS_table
		add	bx, ax			;cs:bx <- ptr to entry
		mov	ax, cs:[bx]		;ax <- GEOS character
done:
		.leave
		ret
	;
	; For Gaiji user-defined characters, it's just a matter of
	; converting the high byte since the whole character range is
	; mapped instead of compressing and using a lookup table.
	;
	; Likewise for IBM & IBM (NEC authorized) extension chars.
	;
gaiji:
		sub	ah, GAIJI_SJIS_UNICODE_DIFF
		jmp	done
ibmNec:
		sub	ax, IBM_NEC_SJIS_UNICODE_DIFF
		jmp	done
ibm:		
		sub	ax, IBM_SJIS_UNICODE_DIFF
		jmp	done

ConvSJISToGeosInt		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvKanjiGeosToSJISInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS Kanji character into a SJIS Kanji character
CALLED BY:	GeosToDosSJISChar()
PASS:		ax - GEOS character
		cs:bx - ptr to ConvSJISToGEOSStruct
RETURN:		carry - set if error
		else:
			ax - SJIS character
DESTROYED:	es, di, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvNoSJIS			proc	near
		stc				;carry <- character not mapped
		ret
ConvNoSJIS			endp

ConvKanjiGeosToSJISInt		proc	near
	;
	; Lookup the pointer for the start of the scan
	;
		mov	di, ax			;di <- Chars
		sub	di, UNICODE_KANJI_START	;adjust for table start
		mov	cl, 4			;cl <- 4 for index
		shr	di, cl			;di <- index into table
		shl	di, 1			;di <- table of nptrs
		mov	di, cs:UnicodeToSJISTable[di]
	;
	; See if there are any SJIS characters in the range
	;
		tst	di			;empty range?
		jz	ConvNoSJIS		;branch if empty range
	;
	; Calculate the length for the scan
	;
		mov	cx, offset EndSJISKanjiToUnicodeTable
		sub	cx, di			;cx <- size of table to scan
EC <		ERROR_C	ILLEGAL_TABLE_OFFSET_FOR_SJIS_CONVERSION	>
		shr	cx, 1			;cx <- length of table to scan

		FALL_THRU	ConvGeosToDBCSSJISInt
ConvKanjiGeosToSJISInt		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvGeosToDBCSSJISInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character into a SJIS character given a range

CALLED BY:	GeosToDosSJISChar()
PASS:		ax - GEOS character
		cs:di - ptr to table to search
		cx - length of table to search
		cs:bx - ptr to ConvSJISToGEOSStruct
RETURN:		carry - set if error
		else:
			ax - SJIS character
DESTROYED:	bx, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvGeosToDBCSSJISInt		proc	near
		uses	dx, es
		.enter

	;
	; Scan for the character
	;
		segmov	es, cs			;es:di <- ptr to table
		repne	scasw			;scan me jesus
		stc				;carry <- not found
		jne	done			;branch if not found
	;
	; Convert the index into a SJIS character value
	;
		mov_tr	ax, di			;ax <- table offset
		sub	ax, cs:[bx].CSJTGS_table
		shr	ax, 1			;ax <- table index
		dec	ax			;ax <- scan goes one past
		mov	di, ax			;di <- table index
	;
	; Reinsert gaps from 0x##00-0x##40 in each ward.  This amounts
	; to multiplying the character index by 256/192 = 4/3.
	;
		clr	dx			;dx:ax <- dividend
		mov	cx, 192			;cx <- divisor
		div	cx			;ax <- index/192
		mov	cl, 6			;cl <- 64=2^6
		shl	ax, cl			;ax <- index/192*64
		add	ax, di			;ax <- index*4/3
	;
	; Adjust for the start of the table
	;
		add	ax, cs:[bx].CSJTGS_start
	;
	; Check and adjust for 0xa000-0xe000 gap
	;
		cmp	ax, SJIS_DBCS_END_1
		jbe	noGap
		add	ax, (SJIS_DB1_START_2 shl 8)-(SJIS_DBCS_END_1+1)
noGap:
		clc				;indicate success
done:

		.leave
		ret
ConvGeosToDBCSSJISInt	endp

Resident	ends
