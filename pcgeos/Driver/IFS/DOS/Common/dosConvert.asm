COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosConvert.asm

AUTHOR:		Gene Anderson, May 24, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/24/93		Initial revision


DESCRIPTION:
	DOS <-> GEOS string conversion

	$Id: dosConvert.asm,v 1.1 97/04/10 11:55:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSUtilByteToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the passed byte to hex ASCII (ie. SBCS)

CALLED BY:	DOSReadBootSector, DOSVirtMapDosToGeosName
PASS:		al	= byte to convert
		es:di	= place in which to store ASCII characters
RETURN:		es:di	= after last char
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nibbles		char	"0123456789ABCDEF"

DOSUtilByteToAscii proc	far
		uses	bx, dx
		.enter

		mov	bx, offset nibbles
		mov	ah, al
		andnf	ax, 0x0ff0
		mov	dl, ah
		clr	ah
		shr	al
		shr	al
		shr	al
		shr	al
		cs:xlatb			; ax <- nibble char
		stosb
		mov	al, dl
		cs:xlatb			; ax <- nibble char
		stosb

		.leave
		ret
DOSUtilByteToAscii endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a DOS code page

CALLED BY:	UTILITY
PASS:		ax - DosCodePage to use (0 for current)
RETURN: 	es:di - ptr to code page
		carry - set if code page not supported
			ax - DTGSS_CODE_PAGE_NOT_SUPPORTED
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; List of supported code pages, and corresponding ptrs
;

codePageList	DosCodePage \
	CODE_PAGE_US,
ifdef SJIS_SUPPORT
	CODE_PAGE_SJIS,
endif
ifdef GB_2312_EUC_SUPPORT
	CODE_PAGE_GB_2312_EUC,
endif
	CODE_PAGE_MULTILINGUAL

codePagePtrs	nptr \
	offset codePageUS,				;default must be first
ifdef SJIS_SUPPORT
	-1,						;not used for SJIS
endif
ifdef GB_2312_EUC_SUPPORT
	-1,						;not used for GB
endif
	offset codePageMulti

CheckHack <(length codePagePtrs) eq (length codePageList)>

GetCodePage	proc	far
		uses	cx, dx
		.enter

	;
	; Check for 'use current'
	;
		tst	ax				;use current?
		jnz	gotCodePageID
		call	DCSGetCurrentCodePage
		mov_tr	ax, bx				;ax <- DosCodePage
gotCodePageID:
	;
	; Scan for the DosCodePage
	;
		mov	di, offset codePageList
		segmov	es, cs				;es:di <- ptr to table
		mov	cx, (size codePageList) / 2	;cx <- # of words
		repne	scasw
		jne	noCodePage			;use default if missing
		sub	di, (offset codePageList) + 2	;convert to index
gotCodePage:
		mov	di, cs:codePagePtrs[di]		;es:di <- ptr to code pg

		.leave
		ret

noCodePage:
		clr	di				;di <- index of default
		mov	ax, DTGSS_CODE_PAGE_NOT_SUPPORTED ;al <- DTGSS; ah <- 0
		stc
		jmp	gotCodePage
GetCodePage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSConvertString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	General DOS / GEOS conversion routine

CALLED BY:	DOSStrategy() w/ DR_FS_CONVERT_STRING
PASS:		ah - FSConvertStringFunction
		ss:bx - FSConvertStringArgs
RETURN:		ah - 0 or # of bytes to back up on DTGSS_CHARACTER_INCOMPLETE
		al - DosToGeosStringStatus
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOSConvertString		proc	far
		mov	al, ah
		clr	ah
		mov	di, ax			;di <- FSConvertStringArgs
EC <		test	di, 0x1						>
EC <		ERROR_NZ	ILLEGAL_DOS_CONVERT_STRING_FUNCTION	>
EC <		cmp	di, FSConvertStringFunction			>
EC <		ERROR_A		ILLEGAL_DOS_CONVERT_STRING_FUNCTION	>
		call	cs:convertFunctions[di]
		ret
DOSConvertString		endp

convertFunctions	nptr \
	DCSCheckCodePage,
	DCSGetCurrentCodePage,
	DCSConvertToDOS,
	DCSConvertToGEOS,
	DCSConvertToDOSFileName,
	DCSConvertToGEOSFileName,
	DCSConvertToDOSChar,
	DCSConvertToGEOSChar
CheckHack <(length convertFunctions)*2 eq FSConvertStringFunction>

CCPStruct	struct
    CCPS_toGEOSChar		nptr.near
    CCPS_toDOSChar		nptr.near
    CCPS_toGEOSString		nptr.near
    CCPS_toDOSString		nptr.near
    CCPS_toDOSFileString	nptr.near
CCPStruct	ends

SBCSConvertRoutines	CCPStruct <
	DosSBToGeosChar,
	GeosToDosSBChar,
	DosSBToGeosCharString,
	GeosToDosSBCharString,
	GeosToDosSBCharFileString
>
ifdef SJIS_SUPPORT
SJISConvertRoutines CCPStruct <
	DosSJISToGeosChar,
	GeosToDosSJISChar,
	DosSJISToGeosCharString,
	GeosToDosSJISCharString,
	GeosToDosSJISCharFileString
>
JISConvertRoutines CCPStruct <
	DosJISToGeosChar,
	GeosToDosJISChar,
	DosJISToGeosCharString,
	GeosToDosJISCharString,
	-1
>
EUCConvertRoutines CCPStruct <
	DosEUCToGeosChar,
	GeosToDosEUCChar,
	DosEUCToGeosCharString,
	GeosToDosEUCCharString,
	-1
>
endif

ifdef GB_2312_EUC_SUPPORT
GBConvertRoutines CCPStruct <
	DosGBToGeosChar,
	GeosToDosGBChar,
	DosGBToGeosCharString,
	GeosToDosGBCharString,
	GeosToDosGBCharFileString
>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSCheckCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a code page is supported by this IFS driver

CALLED BY:	DOSConvertString()
PASS:		bx - DosCodePage to check
RETURN:		carry - set if code page not supported
			ax - DosToGeosStringStatus
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSCheckCodePage		proc	near
		uses	es, di
		.enter

		mov	ax, bx				;ax <- DosCodePage
		call	GetCodePage

		.leave
		ret
DCSCheckCodePage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSGetCurrentCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current code page DOS is using

CALLED BY:	DOSConvertString()
PASS:		none
RETURN:		bx - DosCodePage currently in use
		ax - 0
		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DCSGetCurrentCodePage		proc	near
		uses	ds
		.enter

		mov	ax, segment udata
		mov	ds, ax
		mov	bx, ds:currentCodePage		;bx <- DosCodePage
		clr	ax				;ax <- no error, clc

		.leave
		ret
DCSGetCurrentCodePage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSConvertToDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string from GEOS to DOS

CALLED BY:	DOSConvertString()
PASS:		ss:bx - ptr to FSConvertStringArgs
			FSCSA_source - ptr to source GEOS string
			FSCSA_dest - ptr to dest buffer
			FSCSA_length - length of GEOS chars to convert
RETURN:		carry - set if code page not supported or char not mapped
			ax - DosToGeosStringStatus
		cx - new size of text
		bx - DosCodePage
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSConvertToDOS		proc	near
		uses	dx, si, di, bp, ds, es
		.enter

	;
	; Set up args for the loop
	;
		mov	bp, bx			;ss:bp <- FSConvertStringArgs
		call	FindCodePageBuffer	;bx <- DosCodePage
		clr	ss:[bp].FSCSA_codePage	;use as error flag
		push	cs:[di].CCPS_toDOSString
		lds	si, ss:[bp].FSCSA_source
		les	di, ss:[bp].FSCSA_dest
		mov	cx, ss:[bp].FSCSA_length
		pop	dx			;dx <- convert routine
	;
	; Loop through the string
	;
charLoop:
	;
	; Call the correct routine to get a character and convert it
	;
		call	dx
		jc	convertError		;branch if error
	;
	; check end condition
	;
		tst	ss:[bp].FSCSA_length
		jnz	nextChar
	;
	; See if we've reached a NULL
	;
		tst	ax			;NULL?
		jz	doneString		;branch if NULL
		jmp	charLoop		;else continue
nextChar:
		loop	charLoop
doneString:
	;
	; See if any characters were substituted
	;
		mov	ax, ss:[bp].FSCSA_codePage ;any error?
		tst	ax
		jnz	exitError		;branch if error
	;
	; Return the new size
	;
		mov	cx, di
		sub	cx, ss:[bp].FSCSA_dest.offset
exit:

		.leave
		ret

	;
	; The character was not converted for some reason 
	;
convertError:
		cmp	al, DTGSS_SUBSTITUTIONS
		jne	exitError
	;
	; The character is not mappable -- substitute the default
	;
		mov	ss:[bp].FSCSA_codePage, ax
		mov	ax, ss:[bp].FSCSA_defaultChar
		stosb
		jmp	nextChar

	;
	; The DosCodePage in question is not supported -- return an error
	;
exitError:
		mov	cx, di			;size of text
		sub	cx, ss:[bp].FSCSA_dest.offset
		stc				;carry <- error
		jmp	exit
DCSConvertToDOS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSConvertToGEOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a string from DOS to GEOS

CALLED BY:	DOSConvertString()
PASS:		ss:bx - ptr to FSConvertStringArgs
			FSCSA_source - ptr to source DOS string
			FSCSA_dest - ptr to dest buffer
			FSCSA_length - size of DOS chars to convert
RETURN:		carry - set if code page not supported or char not mapped
			ah - 0 or # bytes to back up
			al - DosToGeosStringStatus
		cx - new length of text
		bx - DosCodePage
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSConvertToGEOS		proc	near
		uses	dx, si, di, bp, ds, es
		.enter

	;
	; Set up args for the loop
	;
		mov	bp, bx			;ss:bp <- FSConvertStringArgs
		call	FindCodePageBuffer	;bx <- DosCodePage
		clr	ss:[bp].FSCSA_codePage	;use as error flag
		push	cs:[di].CCPS_toGEOSString
		lds	si, ss:[bp].FSCSA_source
		les	di, ss:[bp].FSCSA_dest
		mov	cx, ss:[bp].FSCSA_length
		pop	dx			;dx <- convert routine
	;
	; Loop through the string
	;
charLoop:
	;
	; Call the correct routine to get a character and convert it
	;
		call	dx
		jc	convertError		;branch if error
	;
	; check end condition
	;
		tst	ss:[bp].FSCSA_length
		jnz	nextChar
	;
	; See if we've reached a NULL
	;
		tst	ax			;NULL?
		jz	doneString		;branch if NULL
		jmp	charLoop		;else continue
nextChar:
		jcxz	doneString		;no more chars
		loop	charLoop
doneString:
	;
	; See if any characters were substituted
	;
		mov	ax, ss:[bp].FSCSA_codePage
		tst	ax			;any error? (clears carry)
		jnz	exitError		;branch if error
	;
	; Return the new length
	;
		call	calcLength
		clc				;just in case
exit:

		.leave
		ret

calcLength:
		mov	cx, di
		sub	cx, ss:[bp].FSCSA_dest.offset
		shr	cx, 1			;cx <- new length
		retn

	;
	; The character was not converted for some reason 
	;
convertError:
		cmp	al, DTGSS_SUBSTITUTIONS
		jne	exitError
	;
	; The character is not mappable -- substitute the default
	;
		mov	ss:[bp].FSCSA_codePage, ax
		mov	ax, ss:[bp].FSCSA_defaultChar
		stosw
		jmp	nextChar

	;
	; The DosCodePage in question is not supported -- return an error,
	; but return the number of chars in the event the error
	; was DTGSS_CHARACTER_INCOMPLETE.
	;
exitError:
		call	calcLength		;cx <- length converted
		stc				;carry <- error
		jmp	exit

DCSConvertToGEOS		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSConvertToDOSFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSConvertToDOSFileName		proc	near
		ERROR	-1
DCSConvertToDOSFileName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSConvertToGEOSFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSConvertToGEOSFileName		proc	near
		ERROR	-1
DCSConvertToGEOSFileName		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSConvertToDOSChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character to a DOS character

CALLED BY:	DOSConvertString()
PASS:		bx - DosCodePage to use (0 for current)
		cx - GEOS character
RETURN:		carry - set if code page not supported or char not mapped
			ax - DosToGeosStringStatus
		else:
			cx - DOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DCSConvertToDOSChar		proc	near
		uses	bx, di

	;
	; Check for the trivial case
	;
		mov	ax, cx			;ax <- character
		cmp	ax, MIN_DOS_TO_GEOS_CHAR
		jae	mapChar
		clc				;carry <- no error
		ret

mapChar:
		.enter
	;
	;
	; Get the code page and routine to use
	;
		call	FindCodePage
	;
	; Call the routine
	;
		call	cs:[di].CCPS_toDOSChar
		jc	done			;branch if error
		mov	cx, ax			;cx <- DOS char
done:

		.leave
		ret
DCSConvertToDOSChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSConvertToGEOSChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a DOS character to a GEOS character

CALLED BY:	DOSConvertString()
PASS:		bx - DosCodePage to use (0 for current)
		cx - DOS character
RETURN:		carry - set if code page not supported or char not mapped
			ah - 0 or # bytes to back up
			al - DosToGeosStringStatus
		else:
			cx - GEOS character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSConvertToGEOSChar		proc	near
		uses	bx, di
	;
	; Check for the trivial case
	;
		mov	ax, cx			;ax <- character
		cmp	ax, MIN_DOS_TO_GEOS_CHAR
		jae	mapChar
		clc				;carry <- no error
		ret

mapChar:
		.enter
	;
	;
	; Get the code page and routine to use
	;
		call	FindCodePage
	;
	; Call the routine
	;
		call	cs:[di].CCPS_toGEOSChar
		mov	cx, ax			;cx <- GEOS char (or error)

		.leave
		ret
DCSConvertToGEOSChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSGeosToDosCharFileStringCurBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a DOS character
		suitable for a filename using the current DosCodePage

CALLED BY:	UTILITY
PASS:		bx - offset to CCPStruct
		ds:si - ptr to GEOS string
		es:di - ptr to DOS buffer
		cx - # of bytes left
RETURN:		carry - set if error
			ax - '_'
		else:
			ax - DOS character
		ds:si - ptr to next character
		es:di - ptr to next character
		cx - # of bytes updated if >1 byte char
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: Care should be used when calling this routine
	w.r.t. size versus length of strings.  Normally routines
	calling this will have a string length, not size, and
	will not want cx updated.  Routines that have a maximum buffer
	size (eg. 8+1+3 bytes for an 8.3 DOS name) will want cx updated
	to account for potential 2-byte characters.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSGeosToDosCharFileStringCurBX			proc	far
		uses	bp, bx
		.enter

		mov	bp, bx			;bp <- CCPStruct
		clr	bx			;bx <- use current DosCodePage
		call	cs:[bp].CCPS_toDOSFileString

		.leave
		ret
DCSGeosToDosCharFileStringCurBX			endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSGeosToDosCharFileString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a DOS character
		suitable for a filename.

CALLED BY:	UTILITY
PASS:		bx - DosCodePage to use
		bp - offset to CCPStruct
		ds:si - ptr to GEOS string
		es:di - ptr to DOS buffer
		cx - # of bytes left
RETURN:		carry - set if error
			ax - '_'
		else:
			ax - DOS character
		ds:si - ptr to next character
		es:di - ptr to next character
		cx - # of bytes updated if >1 byte char
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: Care should be used when calling this routine
	w.r.t. size versus length of strings.  Normally routines
	calling this will have a string length, not size, and
	will not want cx updated.  Routines that have a maximum buffer
	size (eg. 8+1+3 bytes for an 8.3 DOS name) will want cx updated
	to account for potential 2-byte characters.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSGeosToDosCharFileString			proc	far
		call	cs:[bp].CCPS_toDOSFileString
		ret
DCSGeosToDosCharFileString			endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSDosToGeosCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a DOS character in a string to a GEOS char

CALLED BY:	UTILITY
PASS:		bx - DosCodePage to use
		bp - offset to CCPStruct
		ds:si - ptr to DOS string
		es:di - ptr to GEOS buffer
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - GEOS character
		ds:si - ptr to next character
		es:di - ptr to next character
		cx - decremented if character was larger than 1 byte
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: Care should be used when calling this routine
	w.r.t. size versus length of strings.  Normally routines
	calling this will have a string size, not length, and
	will want cx updated, but not always.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSDosToGeosCharString			proc	far
		call	cs:[bp].CCPS_toGEOSString
		ret
DCSDosToGeosCharString			endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCodePageBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the code page in question is supported

CALLED BY:	CheckGetCodePage()
PASS:		ss:bx - ptr to FSConvertStringArgs
RETURN:		bx - DosCodePage to use
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindCodePageBuffer		proc	near
		mov	bx, ss:[bx].FSCSA_codePage
		FALL_THRU	FindCodePage
FindCodePageBuffer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the code page in question is supported

CALLED BY:	CheckGetCodePage()
PASS:		bx - DosCodePage (0 for current)
RETURN:		bx - DosCodePage to use
		di - offset to CCPStruct
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindCodePage		proc	near
	;
	; Check for 'use current code page' flag
	;
		tst	bx			;code page passed?
		jnz	gotCodePage		;branch if passed
		push	ax
		call	DCSGetCurrentCodePage	;bx <- current code page
		pop	ax
gotCodePage:
	;
	; Figure out what routines to use
	;
ifdef SJIS_SUPPORT
		mov	di, offset SJISConvertRoutines
		cmp	bx, CODE_PAGE_SJIS
		je	gotRoutine
		mov	di, offset EUCConvertRoutines
		cmp	bx, CODE_PAGE_EUC_DB
		je	gotRoutine
		cmp	bx, CODE_PAGE_EUC
		je	gotRoutine
		mov	di, offset JISConvertRoutines
		cmp	bx, CODE_PAGE_JIS_DB
		je	gotRoutine
		cmp	bx, CODE_PAGE_JIS
		je	gotRoutine
endif
ifdef GB_2312_EUC_SUPPORT
		mov	di, offset GBConvertRoutines
		cmp	bx, CODE_PAGE_GB_2312_EUC
		je	gotRoutine
endif
		mov	di, offset SBCSConvertRoutines
gotRoutine::
		ret
FindCodePage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCSFindCurCodePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the current code page for conversion

CALLED BY:	UTILITY
PASS:		none
RETURN:		bx - DosCodePage to use
		bp - offset to CCPStruct
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCSFindCurCodePage		proc	far
		uses	di
		.enter

		clr	bx			;bx <- use current DosCodePage
		call	FindCodePage
		mov	bp, di			;bp <- offset to CCPStruct

		.leave
		ret
DCSFindCurCodePage		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosSBCharFileString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a single-byte DOS char
		suitable for a filename

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to GEOS string
		es:di - ptr to DOS buffer
RETURN:		carry - set if error
			ax - '_'
		else:
			ax - DOS character (ah = 0)
		ds:si - ptr to next character
		es:di - ptr to next character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosSBCharFileString		proc	near
	;
	; Get the character
	;
		lodsw				;ax <- GEOS character
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
		call	GeosToDosSBStringCommon
		jnc	done			;branch if char mapped

illegalChar:
		stc				;carry <- error
		mov	ax, '_'			;ax <- default char
		stosb
done:
		ret
GeosToDosSBCharFileString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosSBCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character in a string to a single-byte DOS char

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to GEOS string
		es:di - ptr to DOS buffer
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - DOS character (ah = 0)
		ds:si - ptr to next character
		es:di - ptr to next character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosSBCharString		proc	near
		lodsw				;ax <- GEOS character
		FALL_THRU	GeosToDosSBStringCommon
GeosToDosSBCharString		endp

GeosToDosSBStringCommon		proc	near
		call	GeosToDosSBChar		;ax <- DOS character
		jc	done			;branch if error
		stosb				;store DOS character
done:
		ret
GeosToDosSBStringCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeosToDosSBChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS character to a single-byte DOS char

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ax - GEOS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - DOS character (ah = 0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeosToDosSBChar		proc	near
		uses	cx, dx, di, es
		.enter

	;
	; Check for the trivial case
	;
		cmp	ax, MIN_DOS_TO_GEOS_CHAR
		jb	charMapped		;branch if no mapping required
	;
	; Get the code page handle and lock it
	;
		push	ax
		mov_tr	ax, bx			;ax <- DosCodePage
		call	GetCodePage		;es:di <- ptr to code page
		pop	ax
		jc	done			;branch if not supported
	;
	; Scan to find the character
	;
		mov	dx, di			;dx <- offset of table
		mov	cx, (length codePageUS)
		repne	scasw			;scan me jesus
		jne	notMappable		;branch if can't be mapped
	;
	; The character was found -- convert the index to a character
	;
		mov	ax, di			;ax <- offset into table + 2
		sub	ax, dx			;ax <- index into table + 2
		shr	ax, 1			;ax <- table of words
		add	ax, MIN_DOS_TO_GEOS_CHAR-1
charMapped:
		clc				;carry <- no error
done:
		.leave
		ret

	;
	; A character could not be mapped
	;
notMappable:
		mov	ax, DTGSS_SUBSTITUTIONS or (0 shl 8)
		stc				;carry <- error
		jmp	done

GeosToDosSBChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosSBToGeosCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a SBCS DOS character in a string to a GEOS char

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ds:si - ptr to DOS string
		es:di - ptr to GEOS buffer
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - GEOS character
		ds:si - ptr to next character
		es:di - ptr to next character
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosSBToGeosCharString		proc	near
		lodsb
		clr	ah			;ax <- DOS character
		call	DosSBToGeosChar
		jc	done			;branch if error
		stosw				;store GEOS character
done:
		ret
DosSBToGeosCharString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosSBToGeosChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a single-byte DOS char to a GEOS character

CALLED BY:	DCSConvertToDOSChar()
PASS:		bx - DosCodePage to use
		ax - DOS character
RETURN:		carry - set if error
			ah - 0
			al - DTGSS_SUBSTITUTIONS
		else:
			ax - GEOS character (ah = 0)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DosSBToGeosChar		proc	near
		uses	di, es
		.enter

	;
	; Check for the trivial case
	;
		cmp	al, MIN_DOS_TO_GEOS_CHAR
		jb	charMapped		;branch if no mapping required
	;
	; Get the code page handle and lock it
	;
		push	ax
		mov_tr	ax, bx			;ax <- DosCodePage
		call	GetCodePage		;es:di <- ptr to code page
		pop	ax
		jc	done			;branch if not supported
	;
	; Look up the character
	;
		sub	ax, MIN_DOS_TO_GEOS_CHAR
		shl	ax, 1			;ax <- table of words
		add	di, ax			;di <- ptr + offset
		mov	ax, es:[di]		;ax <- GEOS character
charMapped:
		clc				;carry <- no error
done:
		.leave
		ret
DosSBToGeosChar		endp

Resident	ends
