COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Local
FILE:		localC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the localization routines

	$Id: localC.asm,v 1.1 97/04/05 01:17:07 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Local	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetDateTimeFormat

C DECLARATION:	extern void
			_far _pascal LocalGetDateTimeFormat(char _far *pstr,
						DateTimeFormat format);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGETDATETIMEFORMAT	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = seg, ax = off, cx = fmt

	push	si, di, es
	mov	es, bx
	mov_trash	di, ax
	mov	si, cx
	call	LocalGetDateTimeFormat
	pop	si, di, es

	ret

LOCALGETDATETIMEFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalFormatFileDateTime

C DECLARATION:	extern word
		    _pascal LocalFormatFileDateTime(char  *pstr,
					DateTimeFormat format,
					const FileDateAndTime *dateTime);
			Note:"dateTime" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALFORMATFILEDATETIME proc far	pstr:fptr.char, format:DateTimeFormat,
					dateTime:fptr.FileDateAndTime
	uses	si, di, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dateTime					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	les	si, ss:[dateTime]
	lodsw	es:			; ax <- FDAT_date
	mov_tr	bx, ax
	lodsw	es:			; ax <- FDAT_time
	xchg	ax, bx			; ax <- FileDate, bx <- FileTime

	les	di, ss:[pstr]
	mov	si, ss:[format]

	call	LocalFormatFileDateTime
	mov_tr	ax, cx
	.leave
	ret
LOCALFORMATFILEDATETIME endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalFormatDateTime

C DECLARATION:	extern word
		    _far _pascal LocalFormatDateTime(char _far *pstr,
					DateTimeFormat format,
					const TimerDateAndTime _far *dateTime);
			Note:"dataTime" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALFORMATDATETIME	proc	far	pstr:fptr.char, format:DateTimeFormat,
					dateTime:fptr
				uses si, di, ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dateTime					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	lds	si, dateTime
	call	CGetDateTime

	les	di, pstr
	mov	si, format
	call	LocalFormatDateTime

	mov_trash	ax, cx		;return # of characters in string

	.leave
	ret

LOCALFORMATDATETIME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalParseDateTime

C DECLARATION:	extern word
		    _far _pascal LocalParseDateTime(const char _far *pstr,
					DateTimeFormat format,
					TimerDateAndTime _far *dateTime);
			Note:"dataTime" *cannot* be pointing to the XIP movable
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALPARSEDATETIME	proc	far	pstr:fptr.char, format:DateTimeFormat,
					dateTime:fptr
				uses si, di, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, dateTime					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	les	di, pstr
	mov	si, format
	call	LocalParseDateTime	; returns carry CLEAR for failure

	jnc	error

	les	di, dateTime
	call	CSetDateTime

	mov	ax, -1			;return -1 (success)

done:
	.leave
	ret

error:
	mov_trash	ax, cx
	jmp	done

LOCALPARSEDATETIME	endp


if FULL_EXECUTE_IN_PLACE
C_Local	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCustomParseDateTime

C DECLARATION:	extern word
		    _far _pascal LocalCustomParseDateTime(
		    			const char _far *pstr,
					DateTimeFormat format,
					TimerDateAndTime _far *dateTime);
			Note:The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCUSTOMPARSEDATETIME	proc	far	pstr:fptr.char, 
						formatStr:fptr.char,
						dateTime:fptr
	uses	si, di, ds, es
	.enter

	les	di, pstr
	lds	si, formatStr
	call	LocalCustomParseDateTime

	jnc	error

	les	di, dateTime
	call	CSetDateTime

	mov	ax, -1			;return -1 (success)

done:
	.leave
	ret

error:
	mov_trash ax, cx
	jmp	done

LOCALCUSTOMPARSEDATETIME	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Local	segment	resource
endif


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCalcDaysInMonth

C DECLARATION:	extern word
		    _far _pascal LocalCalcDaysInMonth(int year, int month);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/92		Initial version

------------------------------------------------------------------------------@
LOCALCALCDAYSINMONTH	proc	far
	C_GetTwoWordArgs ax,bx, cx,dx

	call	LocalCalcDaysInMonth
	mov	al, ch
	cbw

	ret
LOCALCALCDAYSINMONTH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	toupper

C DECLARATION:	extern word
			_far _pascal toupper(wchar ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TOUPPER	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalUpcaseChar
	ret

TOUPPER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	tolower

C DECLARATION:	extern word
			_far _pascal tolower(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TOLOWER	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalDowncaseChar
	ret

TOLOWER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalUpcaseString

C DECLARATION:	extern void
			_far _pascal LocalUpcaseString(char  *pstr,
								word size);
			Note: "pstr" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALUPCASESTRING	proc	far
	clc
CCaseStringCommon	label	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = seg, ax = off, cx = size

	push	si, ds
	mov	ds, bx
	mov_trash	si, ax
	jc	downcase
	call	LocalUpcaseString
	jmp	common
downcase:
	call	LocalDowncaseString
common:
	pop	si, ds

	ret

LOCALUPCASESTRING	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDowncaseString

C DECLARATION:	extern void
			_far _pascal LocalDowncaseString(char  *pstr,
								word size);
			Note: "pstr" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALDOWNCASESTRING	proc	far
	stc
	jmp	CCaseStringCommon

LOCALDOWNCASESTRING	endp


if FULL_EXECUTE_IN_PLACE
C_Local	ends
GeosCStubXIP	segment	resource
endif 


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCmpStrings

C DECLARATION:	extern sword
		    _far _pascal LocalCmpStrings(const char _far *str1,
					    const char *str2, word strSize);
		Note: The strs *can* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCMPSTRINGS	proc	far	str1:fptr.char, str2:fptr.char, strSize:word
				uses si, di, ds, es

	clc
CCmpStringsCommon	label	far
	.enter

	lds	si, str1
	les	di, str2
	mov	cx, strSize
	jc	noCase
	call	LocalCmpStrings
	jmp	common
noCase:
	call	LocalCmpStringsNoCase
common:
	call	CCmpStringsFinish
	.leave
	ret

LOCALCMPSTRINGS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCmpStringsNoCase

C DECLARATION:	extern sword
		    _far _pascal LocalCmpStringsNoCase(const char _far *str1,
					    const char *str2, word strSize);
		Note: The strs *can* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCMPSTRINGSNOCASE	proc	far
	stc
	jmp	CCmpStringsCommon

LOCALCMPSTRINGSNOCASE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCmpStringsNoSpace

C DECLARATION:	extern sword
		    _far _pascal LocalCmpStringsNoSpace(const char _far *str1,
					    const char *str2, word strSize);
		Note: The strs *can* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/92		Initial version

------------------------------------------------------------------------------@
LOCALCMPSTRINGSNOSPACE	proc far str1:fptr.char, str2:fptr.char, strSize:word
				uses si, di, ds, es

	clc
CCmpStringsNoSpaceCommon	label	far
	.enter

	lds	si, str1
	les	di, str2
	mov	cx, strSize
	jc	noCase
	call	LocalCmpStringsNoSpace
	jmp	common
noCase:
	call	LocalCmpStringsNoSpaceCase
common:
	call	CCmpStringsFinish
	.leave
	ret

LOCALCMPSTRINGSNOSPACE	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Local segment	resource
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CCmpStringsFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ax for C string comparison functions

CALLED BY:	UTILITY
PASS:		flags - set based on string comparison
RETURN:		ax - -1 if <
		   - 0 if =
		   - 1 if >
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/20/92		combined common code from C functions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FULL_EXECUTE_IN_PLACE
CCmpStringsFinish		proc	far
else
CCmpStringsFinish		proc	near
endif

	; Note that since the routine matches the "cmpsb" instruction,
	; flags are set reverse of what would be expected.

	;	flags - same as in cmps instruction:
	;		if source =  dest : if (z)
	;		if source != dest : if !(z)
	;		if source >  dest : if !(c|z)
	;		if source <  dest : if (c)
	;		if source >= dest : if !(c)
	;		if source <= dest : if (c|z)

	mov	ax, 0			;assume equal (ax == 0 -> equal
	jz	done
	inc	ax			;preserves carry (ax == 1 -> greater)
	jnc	done
	mov	ax, -1			;(ax == -1 -> less than)
done:
	ret
CCmpStringsFinish		endp


if FULL_EXECUTE_IN_PLACE
C_Local	ends
GeosCStubXIP	segment	resource
endif 

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCmpStringsNoCase

C DECLARATION:	extern sword
		  _far _pascal LocalCmpStringsNoSpaceCase(const char _far *str1,
					    const char *str2, word strSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/92		Initial version

------------------------------------------------------------------------------@
LOCALCMPSTRINGSNOSPACECASE	proc	far
	stc
	jmp	CCmpStringsNoSpaceCommon

LOCALCMPSTRINGSNOSPACECASE	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Local segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isupper

C DECLARATION:	extern Boolean
			_far _pascal isupper(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Schoon  4/92		Anci C revision

------------------------------------------------------------------------------@
ISUPPER	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsUpper
	FALL_THRU	CLocalReturnBoolean

ISUPPER	endp

CLocalReturnBoolean	proc	far
	mov	ax, 0
	jz	done
	dec	ax
done:
	ret
CLocalReturnBoolean	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	islower

C DECLARATION:	extern Boolean
			_far _pascal islower(int ch);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Schoon  4/92		Anci C revision

------------------------------------------------------------------------------@
ISLOWER	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsLower
	GOTO	CLocalReturnBoolean

ISLOWER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isalpha

C DECLARATION:	extern Boolean
			_far _pascal isalpha(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Schoon  4/92		Anci C revision

------------------------------------------------------------------------------@
ISALPHA	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsAlpha
	GOTO	CLocalReturnBoolean

ISALPHA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ispunct

C DECLARATION:	extern Boolean
			_far _pascal ispunct(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Schoon  4/92		Anci C revision

------------------------------------------------------------------------------@
ISPUNCT	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsPunctuation
	GOTO	CLocalReturnBoolean

ISPUNCT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isspace

C DECLARATION:	extern Boolean
			_far _pascal isspace(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	Schoon  4/92		Anci C revision

------------------------------------------------------------------------------@
ISSPACE	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsSpace
	GOTO	CLocalReturnBoolean

ISSPACE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	iscntrl

C DECLARATION:	extern Boolean
			_far _pascal iscntrl(int ch);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	schoon  4/92		Initial version

------------------------------------------------------------------------------@
ISCNTRL	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsControl
	GOTO	CLocalReturnBoolean

ISCNTRL	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isdigit

C DECLARATION:	extern Boolean
			_far _pascal isdigit(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Schoon  4/92		Initial version

------------------------------------------------------------------------------@
ISDIGIT	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsDigit
	GOTO	CLocalReturnBoolean

ISDIGIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isxdigit

C DECLARATION:	extern Boolean
			_far _pascal isxdigit(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Schoon  4/92		Initial version

------------------------------------------------------------------------------@
ISXDIGIT	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsHexDigit
	GOTO	CLocalReturnBoolean

ISXDIGIT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isalnum

C DECLARATION:	extern Boolean
			_far _pascal isalnum(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	schoon  4/92		Initial version

------------------------------------------------------------------------------@
ISALNUM	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsAlphaNumeric
	GOTO	CLocalReturnBoolean

ISALNUM endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isprint

C DECLARATION:	extern Boolean
			_far _pascal isprint(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Schoon  4/92		Initial version

------------------------------------------------------------------------------@
ISPRINT	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsPrintable
	GOTO	CLocalReturnBoolean

ISPRINT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	isgraph

C DECLARATION:	extern Boolean
			_far _pascal isgraph(int ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	schoon  4/92		Initial version

------------------------------------------------------------------------------@
ISGRAPH	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsGraphic
	GOTO	CLocalReturnBoolean

ISGRAPH	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsSymbol

C DECLARATION:	extern Boolean
			_far _pascal LocalIsSymbol(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALISSYMBOL	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsSymbol
	GOTO	CLocalReturnBoolean

LOCALISSYMBOL	endp

if DBCS_PCGEOS

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsKana

C DECLARATION:	extern Boolean
			_far _pascal LocalIsKana(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/94		Initial version

------------------------------------------------------------------------------@
LOCALISKANA		proc	far
	C_GetOneWordArg ax,   bx, cx	;ax = char
	call	LocalIsKana
	GOTO	CLocalReturnBoolean
LOCALISKANA		endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsKanji

C DECLARATION:	extern Boolean
			_far _pascal LocalIsKanji(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/94		Initial version

------------------------------------------------------------------------------@
LOCALISKANJI		proc	far
	C_GetOneWordArg ax,   bx, cx	;ax = char
	call	LocalIsKanji
	GOTO	CLocalReturnBoolean
LOCALISKANJI		endp

endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsDateChar

C DECLARATION:	extern Boolean
			_far _pascal LocalIsDateChar(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALISDATECHAR	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsDateChar
	GOTO	CLocalReturnBoolean

LOCALISDATECHAR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsTimeChar

C DECLARATION:	extern Boolean
			_far _pascal LocalIsTimeChar(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALISTIMECHAR	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsTimeChar
	GOTO	CLocalReturnBoolean

LOCALISTIMECHAR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsNumChar

C DECLARATION:	extern Boolean
			_far _pascal LocalIsNumChar(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALISNUMCHAR	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsNumChar
	GOTO	CLocalReturnBoolean

LOCALISNUMCHAR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsDosChar

C DECLARATION:	extern Boolean
			_far _pascal LocalIsDosChar(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALISDOSCHAR	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalIsDosChar
	GOTO	CLocalReturnBoolean

LOCALISDOSCHAR	endp


if DBCS_PCGEOS

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDosToGeosChar

C DECLARATION:	extern Boolean
			_far _pascal LocalDosToGeosChar(word _fptr *achar,
						DosCodePage codePage,
						word diskHandle,
						DosToGeosStringStatus
							_fptr *status
						word _fptr *backup);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/29/96		Initial version

------------------------------------------------------------------------------@
LOCALDOSTOGEOSCHAR	proc	far	achar:fptr.wchar, codePage:DosCodePage,
					diskHandle: word,
					status:fptr.DosToGeosStringStatus,
					backup:fptr.word
					uses	ds, si, bp, di
	.enter

	lds	si, achar
	mov	ax, ds:[si]
	mov	bx, codePage
	mov	dx, diskHandle
	call	LocalDosToGeosChar
	jc	error

	lds	si, achar
	mov	ds:[si], ax		; return the mapped charcter
	clr	ax			; no error
done:
	.leave
	ret
error:
	lds	si, status
	mov	{byte} ds:[si], al	; DosToGeosStringStatus
	lds	si, backup
	clr	al
	xchg	ah, al
	mov	ds:[si], ax		; if DTGSS_CHARACTER_INCOMPLETE, 
					;   # of bytes to back up
	clr	al
	dec	ax			; error
	jmp	done
LOCALDOSTOGEOSCHAR	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGeosToDosChar

C DECLARATION:	extern Boolean
			_far _pascal LocalGeosToDosChar(word _fptr *achar,
						DosCodePage codePage,
						word diskHandle,
						DosToGeosStringStatus 
							_fptr *status);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/26/96		Initial version

------------------------------------------------------------------------------@
LOCALGEOSTODOSCHAR	proc	far	achar:fptr.wchar, codePage:DosCodePage,
					diskHandle:word,
					status:fptr.DosToGeosStringStatus
					uses	ds, si, bp, di
	.enter

	lds	si, achar
	mov	ax, ds:[si]
	mov	bx, codePage
	mov	dx, diskHandle
	call	LocalGeosToDosChar
	jc	error

	lds	si, achar
	mov	ds:[si], ax		; return the mapped charcter
	clr	ax			; no error
done:
	.leave
	ret
error:
	lds	si, status
	mov	{byte} ds:[si], al	; DosToGeosStringStatus
	clr	ax
	dec	ax			; error
	jmp	done

LOCALGEOSTODOSCHAR	endp

else

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDosToGeosChar

C DECLARATION:	extern word
			_far _pascal LocalDosToGeosChar(word ch,
							word defaultChar);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALDOSTOGEOSCHAR	proc	far
	C_GetTwoWordArgs	ax, bx,   cx,dx	;ax = char, bx = default char

	call	LocalDosToGeosChar
	ret

LOCALDOSTOGEOSCHAR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGeosToDosChar

C DECLARATION:	extern word
			_far _pascal LocalGeosToDosChar(word ch,
							word defaultChar);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGEOSTODOSCHAR	proc	far
	C_GetTwoWordArgs	ax, bx,   cx,dx	;ax = char, bx = default char

	call	LocalGeosToDosChar
	ret

LOCALGEOSTODOSCHAR	endp

endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetCodePage

C DECLARATION:	extern DosCodePage
			_far _pascal LocalGetCodePage();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGETCODEPAGE	proc	far
	call	LocalGetCodePage
	mov_trash	ax, bx
	ret

LOCALGETCODEPAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalSetCodePage

C DECLARATION:	extern MemHandle
			_far _pascal LocalSetCodePage(DosCodePage dcp);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	skarpi	1/12/95		Initial version

------------------------------------------------------------------------------@
LOCALSETCODEPAGE	proc	far

	C_GetOneWordArg	ax,   dx,bx		
	call	LocalSetCodePage		; bx <- hptr.LocalCodePage
	mov_tr	ax, bx				; ax <- hptr.LocalCodePage
	jnc	done				; done if carry not set
	clr	ax				; FALSE	since carry was set
done:
	ret

LOCALSETCODEPAGE	endp


if DBCS_PCGEOS

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDosToGeos	(DBCS version)

C DECLARATION:	extern Boolean
		    _far _pascal LocalDosToGeos(wchar _far *destStr
						char _far *sourceStr,
						word *strSize, 
						word defaultChar,
						DosCodePage *codePage,
						word diskHandle,
						DosToGeosStringStatus
							_far *status);

		Note: "dosstr" & "ustr" *cannot* be pointing to the
			movable XIP code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/29/96		Initial version

------------------------------------------------------------------------------@
LOCALDOSTOGEOS	proc	far	destStr:fptr.wchar, sourceStr:fptr.char,
				strSize:fptr.word, defaultChar:word,
				codePage:fptr.DosCodePage, diskHandle:word,
				status:fptr.DosToGeosStringStatus,
				backup:fptr.word
				uses si, ds, bp, di
	clc
CCPCommon	label	far
	.enter

	lds	si, strSize
	mov	cx, ds:[si]
	lds	si, codePage
	mov	bx, ds:[si]			; bx = DosCodePage
	lds	si, sourceStr			; ds:si = source string
	les	di, destStr			; es:di = dest string
	mov	ax, defaultChar
	mov	dx, diskHandle			; 0 for primary FSD

	jc	geosToDos
	call	LocalDosToGeos
	jmp	common
geosToDos:
	call	LocalGeosToDos
common:
	lds	si, strSize
	mov	ds:[si], cx			; size could have changed
	lds	si, codePage
	mov	ds:[si], bx			; code page could have changed
	jc	error

	clr	ax				; no error
done:
	.leave
	ret
error:
	lds	si, status
	mov	{byte} ds:[si], al		; DosToGeosStringStatus
	lds	si, backup
	clr	al
	xchg	al, ah
	mov	ds:[si], ax			; # bytes to back up
						; if DTGSS_CHARACTER_INCOMPLETE
	clr	ax
	dec	ax				; return error
	jmp	done

LOCALDOSTOGEOS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGeosToDos (DBCS version)

C DECLARATION:	extern Boolean
		    _far _pascal LocalGeosToDos(wchar _far *destStr,
						char _far *sourceStr,
						word _far *strSize, 
						word defaultChar,
						DosCodePage _far *codePage,
						word diskHandle,
						DosToGeosStringStatus 
							_far *status);

		Note: "sourceStr" & "destStr" *cannot* be pointing to
			the movable XIP code resource.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	8/29/96		Initial version

------------------------------------------------------------------------------@
LOCALGEOSTODOS	proc	far
	stc
	jmp	CCPCommon

LOCALGEOSTODOS	endp

else

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDosToGeos

C DECLARATION:	extern Boolean
		    _far _pascal LocalDosToGeos(char _far *pstr, word strSize,
							word defaultChar);
		Note: "pstr" *cannot* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALDOSTOGEOS	proc	far	pstr:fptr.char, strSize:word, defaultChar:word
				uses si, ds
	clc
CCPCommon	label	far
	.enter

	lds	si, pstr
	mov	cx, strSize
	mov	ax, defaultChar

	jc	geosToDos
	call	LocalDosToGeos
	jmp	common
geosToDos:
	call	LocalGeosToDos
common:

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

LOCALDOSTOGEOS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGeosToDos

C DECLARATION:	extern Boolean
		    _far _pascal LocalGeosToDos(char _far *pstr, word strSize,
							word defaultChar);
		Note: "pstr" *cannot* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGEOSTODOS	proc	far
	stc
	jmp	CCPCommon

LOCALGEOSTODOS	endp

endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetQuotes

C DECLARATION:	extern void
			_far _pascal LocalGetQuotes(LocalQuotes _far *quotes);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGETQUOTES	proc	far
	C_GetOneDWordArg	cx, ax,   dx,bx	;cx = seg, ax = offset

	push	di, es
	mov	es, cx
	mov_trash	di, ax
	call	LocalGetQuotes
	stosw					;frontSingle
	mov_trash	ax, bx
	stosw					;endSingle
	mov_trash	ax, cx
	stosw					;frontDouble
	mov_trash	ax, dx
	stosw					;endDouble
	pop	di, es

	ret

LOCALGETQUOTES	endp

if FULL_EXECUTE_IN_PLACE
C_Local	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCustomFormatDateTime

C DECLARATION:	extern word
		    _far _pascal LocalFormatDateTime(char _far *pstr,
					const char _far *format,
					const TimerDateAndTime _far *dateTime);
			Note: "format" and "dataTime" *can* be pointing to the 					XIP movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCUSTOMFORMATDATETIME	proc	far	pstr:fptr.char,
						format:fptr.char, dateTime:fptr
				uses si, di, ds, es
	.enter

	lds	si, dateTime
	call	CGetDateTime

	lds	si, format
	les	di, pstr
	call	LocalCustomFormatDateTime

	mov_trash	ax, cx		;return # of characters in string

	.leave
	ret

LOCALCUSTOMFORMATDATETIME	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Local	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetNumericFormat

C DECLARATION:	extern void
			_far _pascal LocalGetNumericFormat(LocalNumericFormat
								_far *buf);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGETNUMERICFORMAT	proc	far
	C_GetOneDWordArg	cx, ax,   dx,bx	;cx = seg, ax = offset

	push	di, es
	mov	es, cx
	mov_trash	di, ax
	call	LocalGetNumericFormat
	call	CStoreNumericFormat
	pop	di, es

	ret

LOCALGETNUMERICFORMAT	endp

CStoreNumericFormat	proc	near
	stosw				;numberFormatFlags, decimalDigits
	mov_trash	ax, bx
	stosw				;thousandsSeperator
	mov_trash	ax, cx
	stosw				;decimalSeperator
	mov_trash	ax, dx
	stosw				;listSeperator
	ret
CStoreNumericFormat	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetCurrencyFormat

C DECLARATION:	extern void
			_far _pascal LocalGetCurrencyFormat(
					LocalCurrencyFormat _far *buf,
					char _far *symbol);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGETCURRENCYFORMAT	proc	far	buf:fptr, symbol:fptr
					uses di, es
	.enter

	les	di, symbol
	call	LocalGetCurrencyFormat

	les	di, buf
	call	CStoreNumericFormat

	.leave
	ret


LOCALGETCURRENCYFORMAT	endp

if not DBCS_PCGEOS

if FULL_EXECUTE_IN_PLACE
C_Local	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCmpStringsDosToGeos

C DECLARATION:	extern sword
		    _far _pascal LocalCmpStringsDosToGeos(
					const char _far *str1,
					const char _far *str2, word strSize,
					word defaultChar, word flags);
			Note:The strings *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCMPSTRINGSDOSTOGEOS	proc	far	str1:fptr.char, str2:fptr.char,
						strSize:word, defaultChar:word,
						flags:word
				uses si, di, ds, es
	.enter

	lds	si, str1
	les	di, str2
	mov	cx, strSize
	mov	ax, flags
	mov	bx, defaultChar
	call	LocalCmpStringsDosToGeos
	
	call	CCmpStringsFinish
	.leave
	ret

LOCALCMPSTRINGSDOSTOGEOS	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_Local	segment	resource
endif


endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalIsCodePageSupported

C DECLARATION:	extern Boolean
		    _far _pascal LocalIsCodePageSupported(DosCodePage codePage)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALISCODEPAGESUPPORTED	proc	far	
	C_GetOneWordArg	ax, 	cx,dx		;AX <- code page
	call	LocalIsCodePageSupported
	mov	ax, -1		;Return AX non-zero if supported
	jz	isSupported
	clr	ax
isSupported:
	.leave
	ret
LOCALISCODEPAGESUPPORTED	endp

if not DBCS_PCGEOS

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCodePageToGeos

C DECLARATION:	extern Boolean
		    _far _pascal LocalCodePageToGeos(char _far *pstr,
					DosCodePage codePage, word strSize,
					word defaultChar);
			Note: "pstr" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCODEPAGETOGEOS	proc	far	pstr:fptr, strSize:word, codePage:word,
					defaultChar:word
				uses si, ds
	clc
CCodePageCommon	label	far
	.enter

	lds	si, pstr
	mov	cx, strSize
	mov	ax, defaultChar
	mov	bx, codePage

	jc	toCodePage
	call	LocalCodePageToGeos
	jmp	common
toCodePage:
	call	LocalGeosToCodePage
common:

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

LOCALCODEPAGETOGEOS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGeosToCodePage

C DECLARATION:	extern Boolean
		    _far _pascal LocalGeosToCodePage(char _far *pstr,
					DosCodePage codePage, word strSize,
					word defaultChar);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGEOSTOCODEPAGE	proc	far
	stc
	jmp	CCodePageCommon

LOCALGEOSTOCODEPAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalCodePageToGeosChar

C DECLARATION:	extern word
		    _far _pascal LocalCodePageToGeosChar(word ch,
					DosCodePage codePage,
					word defaultChar);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALCODEPAGETOGEOSCHAR	proc	far	cch:word, codePage:word,
					defaultChar:word
				uses si, ds
	clc
CCodePageCommonChar	label	far
	.enter

	mov	ax, cch
	mov	bx, defaultChar
	mov	cx, codePage

	jc	toCodePage
	call	LocalCodePageToGeosChar
	jmp	common
toCodePage:
	call	LocalGeosToCodePageChar
common:

	.leave
	ret

LOCALCODEPAGETOGEOSCHAR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGeosToCodePageChar

C DECLARATION:	extern word
		    _far _pascal LocalGeosToCodePageChar(word ch,
					DosCodePage codePage,
					word defaultChar);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALGEOSTOCODEPAGECHAR	proc	far
	stc
	jmp	CCodePageCommonChar

LOCALGEOSTOCODEPAGECHAR	endp

endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalLexicalValue

C DECLARATION:	extern word
			_far _pascal LocalLexicalValue(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALLEXICALVALUE	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalLexicalValue
	ret

LOCALLEXICALVALUE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalLexicalValueNoCase

C DECLARATION:	extern word
			_far _pascal LocalLexicalValueNoCase(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALLEXICALVALUENOCASE	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = char

	call	LocalLexicalValueNoCase
	ret

LOCALLEXICALVALUENOCASE	endp	

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDistanceToAscii

C DECLARATION:	extern word
		LocalDistanceToAscii(char *buffer, WWFixedAsDWord value,
				 DistanceUnit distanceUnits,
				 word measurementType,
				 LocalDistanceFlags flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALDISTANCETOASCII	proc	far	buffer:fptr, value:dword,
					dunits:word, mtype:word, flags:word
				uses di, es
	.enter

	les	di, buffer
	movdw	dxax, value
	mov	cl, dunits.low
	mov	ch, mtype.low
	mov	bx, flags
	call	LocalDistanceToAscii
	mov_tr	ax, cx

	.leave
	ret

LOCALDISTANCETOASCII	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalDistanceFromAscii

C DECLARATION:	extern word
		LocalDistanceFromAscii(const char *buffer, word distanceUnits,
				       word measurementType);
			Note: "buffer" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALDISTANCEFROMASCII	proc	far	buffer:fptr, dunits:word, mtype:word
				uses di, ds
	.enter

	lds	di, buffer
	mov	cl, dunits.low
	mov	ch, mtype.low
	call	LocalDistanceFromAscii

	.leave
	ret

LOCALDISTANCEFROMASCII	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalFixedToAscii

C DECLARATION:	extern void
		LocalFixedToAscii(char *buffer, WWFixedAsDWord value,
				  word fracDigits);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALFIXEDTOASCII	proc	far	buffer:fptr, value:dword, digits:word
				uses di, es
	.enter

	les	di, buffer
	movdw	dxax, value
	mov	cx, digits
	call	LocalFixedToAscii

	.leave
	ret

LOCALFIXEDTOASCII	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalAsciiToFixed

C DECLARATION:	extern WWFixedAsDWord
		LocalAsciiToFixed(const char *buffer, char **parseEnd);
			Note: "buffer" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALASCIITOFIXED	proc	far	buffer:fptr, endptr:fptr
				uses di, ds
	.enter

	lds	di, buffer
	call	LocalAsciiToFixed
	mov	cx, ds
	lds	bx, endptr
	movdw	ds:[bx], cxdi

	.leave
	ret

LOCALASCIITOFIXED	endp

C_Local	ends

;-

C_System	segment resource

if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalSetDateTimeFormat

C DECLARATION:	extern void
			_far _pascal LocalSetDateTimeFormat(const char _far
						*pstr, DateTimeFormat format);
		Note: "pstr" *can* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALSETDATETIMEFORMAT	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = seg, ax = off, cx = fmt

	push	si, di, es
	mov	es, bx
	mov_trash	di, ax
	mov	si, cx
	call	LocalSetDateTimeFormat
	pop	si, di, es

	ret

LOCALSETDATETIMEFORMAT	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalSetQuotes

C DECLARATION:	extern void
			_far _pascal LocalSetQuotes(const LocalQuotes _far
								*quotes);
			Note: "nquotes" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALSETQUOTES	proc	far
	C_GetOneDWordArg	cx, ax,   dx,bx	;cx = seg, ax = offset

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax

	lodsw					;frontSingle
	push	ax
	lodsw					;endSingle
	mov_trash	bx, ax
	lodsw					;frontDouble
	mov_trash	cx, ax
	lodsw					;endDouble
	mov_trash	dx, ax
	pop	ax

	pop	si, ds

	call	LocalSetQuotes
	ret

LOCALSETQUOTES	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalSetNumericFormat

C DECLARATION:	extern void
			_far _pascal LocalSetNumericFormat(const
					LocalNumericFormat _far *buf);
			Note: "buf" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALSETNUMERICFORMAT	proc	far
	C_GetOneDWordArg	cx, ax,   dx,bx	;cx = seg, ax = offset

	push	si, ds
	mov	ds, cx
	mov_trash	si, ax
	call	CGetFormat
	pop	si, ds

	call	LocalSetNumericFormat
	ret

LOCALSETNUMERICFORMAT	endp

CGetFormat	proc	near
	lodsw				;numberFormatFlags, decimalDigits
	push	ax
	lodsw				;thousandsSeperator
	mov_trash	bx, ax
	lodsw				;decimalSeperator
	mov_trash	cx, ax
	lodsw				;listSeperator
	mov_trash	dx, ax
	pop	ax
	ret
CGetFormat	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalSetCurrencyFormat

C DECLARATION:	extern void
			_far _pascal LocalSetNumericFormat(
					const LocalCurrencyFormat _far *buf,
					const char _far *symbol);
			Note:The fptrs *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALSETCURRENCYFORMAT	proc	far	buf:fptr, symbol:fptr
				uses si, di, ds, es
	.enter

	lds	si, buf
	call	CGetFormat
	les	di, symbol
	call	LocalSetCurrencyFormat

	.leave
	ret

LOCALSETCURRENCYFORMAT	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalSetMeasurementType

C DECLARATION:	extern void
			_far _pascal LocalSetMeasurementType(
							MeasurementType meas);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LOCALSETMEASUREMENTTYPE	proc	far
	C_GetOneWordArg	ax,   bx,cx	;ax = type

	call	LocalSetMeasurementType
	ret

LOCALSETMEASUREMENTTYPE	endp


if FULL_EXECUTE_IN_PLACE
C_System	ends
GeosCStubXIP	segment	resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalStringSize

C DECLARATION:	extern void
			_far _pascal LocalStringSize(const char *str);
			Note: "str" *can* be pointing to the XIP movable 
				code resource.
			
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

------------------------------------------------------------------------------@
LOCALSTRINGSIZE	proc	far	str1:fptr.char
	uses	es, di
	.enter
	les	di, str1		; es:di <- ptr to string
	call	LocalStringSize		; cx <- # of chars in string
	mov	ax, cx			; Return size in ax
	.leave
	ret
LOCALSTRINGSIZE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalStringLength

C DECLARATION:	extern void
			_far _pascal LocalStringLength(const char *str);
			Note: "str" *can* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/12/91	Initial version

------------------------------------------------------------------------------@
LOCALSTRINGLENGTH	proc	far	str1:fptr.char
	uses	es, di
	.enter
	les	di, str1		; es:di <- ptr to string
	call	LocalStringLength	; cx <- # of chars in string
	mov	ax, cx			; Return size in ax
	.leave
	ret
LOCALSTRINGLENGTH	endp


if FULL_EXECUTE_IN_PLACE
GeosCStubXIP	ends
C_System	segment	resource
endif

if DBCS_PCGEOS





COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalAddGengoName

C DECLARATION:	extern Boolean
			_far _pascal LocalAddGengoName(const char *longGengo,
							const char *shortGengo,
							word year,
							word month,
							word day);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/16/93	Initial version

------------------------------------------------------------------------------@
LOCALADDGENGONAME	proc	far	longGengo:fptr.char,
					shortGengo:fptr.char,
					addYear:word,
					addMonth:word,
					addDay:word
	uses	es, di, ds, si
	.enter
	lds	si, longGengo		; ds:si = long gengo
	les	di, shortGengo		; es:di = short gengo
	mov	ax, addYear
	mov	bl, addMonth.low
	mov	bh, addDay.low
	call	LocalAddGengoName	; returns carry clear if successful
	mov	ax, 0			; return FALSE if successful
	jnc	done
	dec	ax
done:
	.leave
	ret
LOCALADDGENGONAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalRemoveGengoName

C DECLARATION:	extern Boolean
			_far _pascal LocalRemoveGengoName(word year,
							word month,
							word day,
							word *errorType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/16/93	Initial version

------------------------------------------------------------------------------@
LOCALREMOVEGENGONAME	proc	far	removeYear:word,
					removeMonth:word,
					removeDay:word,
					errorType:fptr.word
	uses	es, di
	.enter
	les	di, errorType
	mov	ax, removeYear
	mov	bl, removeMonth.low
	mov	bh, removeDay.low
	call	LocalRemoveGengoName	; returns carry clear if successful
	stosw				; save error type
	mov	ax, 0			; return FALSE if successful
	jnc	done
	dec	ax
done:
	.leave
	ret
LOCALREMOVEGENGONAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetGengoInfo

C DECLARATION:	extern Boolean
			_far _pascal LocalGetGengoInfo(word entryNum,
						GengoNameData *gengoInfo);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/18/94		Initial version

------------------------------------------------------------------------------@
LOCALGETGENGOINFO	proc	far	entryNum:word,
					gengoInfo:fptr.GengoNameData
	uses	es, di
	.enter
	les	di, gengoInfo
	mov	ax, entryNum
	call	LocalGetGengoInfo	; returns carry clear if successful
	mov	ax, 0			; return FALSE if successful
	jnc	done
	dec	ax
done:
	.leave
	ret
LOCALGETGENGOINFO	endp
endif

if DBCS_PCGEOS
COMMENT @----------------------------------------------------------------------

C FUNCTION:	LocalGetWordPartType

C DECLARATION:	extern CharWordPartType
			_far _pascal LocalGetWordPartType(word ch);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/11/94		Initial version

------------------------------------------------------------------------------@

LOCALGETWORDPARTTYPE	proc	far
	C_GetOneWordArg ax,  bx, cx	;ax = char

	call	LocalGetWordPartType
	ret
LOCALGETWORDPARTTYPE	endp

endif

C_System	ends

C_Local	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current timezone and DST info

C DECL:
	extern sword
	    _pascal LocalGetTimezone(Boolean *useDST);

CALLED BY:	UTILITY
PASS:		useDST - ptr Boolean return value
RETURN:		offset to GMT in minutes
		useDST - TRUE if offset adjusted for Daylight Savings Time
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOCALGETTIMEZONE	proc	far	useDST:fptr.Boolean
		uses	es, di
		.enter

		call	LocalGetTimezone
		les	di, ss:useDST			;es:di <- ptr to return
		mov	es:[di], bl			;return usesDST

		.leave
		ret
LOCALGETTIMEZONE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current timezone and DST info

C DECL:
	extern void
	    _pascal LocalGetTimezone(sword offsetGMT, Boolean useDST);

CALLED BY:	UTILITY
PASS:		offsetGMT - offset to GMT in minutes
		useDST - TRUE if offset adjusted for Daylight Savings Time
RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOCALSETTIMEZONE	proc	far	offsetGMT:sword, useDST:BooleanWord
		.enter

		mov	ax, ss:offsetGMT		;ax <- offset to GMT
		mov	bx, ss:useDST			;bl <- use DST
		or	bl, bh				;bl=0 iff bx==0
		call	LocalSetTimezone

		.leave
		ret
LOCALSETTIMEZONE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCompareDateTimess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two normalized datetimes

C DECL:
	extern sword
	    _pascal LocalCompareDates(TimerDateAndTime datetime1,
				      TimerDateAndTime datetime2);

CALLED BY:	UTILITY
PASS:		datetime1 - TimerDateAndTime #1
		datetime2 - TimerDateAndTime #2
RETURN:		ax - < 0, = 0, >0 for cmp datetime1, datetime2
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/21/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOCALCOMPAREDATETIMES	proc	far	datetime1:fptr.TimerDateAndTime,
					datetime2:fptr.TimerDateAndTime
		uses	ds, si, es, di
		.enter

		lds	si, ss:datetime1		;ds:si <- datetime1
		les	di, ss:datetime2		;es:di <- datetime2
		call	LocalCompareDateTimes		;set flags
		call	CCmpStringsFinish		;ax <- set for flags

		.leave
		ret
LOCALCOMPAREDATETIMES	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalNormalizeDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize a date/time

C DECL:
	extern void
	    _pascal LocalNormalizeDate(TimerDateAndTime destTDAT,
					TimerDateAndTime srcTDAT,
					sword offsetGMT);

CALLED BY:	UTILITY
PASS:		destTDAT - TimerDateAndTime
		srcTDAT - TimerDateAndTime
		offsetGMT - offset to GMT
RETURN:		destTDAT - filled in
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: destTDAT = srcTDAT is OK, i.e., in place conversion is OK
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/21/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOCALNORMALIZEDATETIME	proc	far	destTDAT:fptr.TimerDateAndTime,
					srcTDAT:fptr.TimerDateAndTime,
					offsetGMT:sword
		uses	ds, si, es, di
		.enter

		lds	si, ss:srcTDAT		;ds:si <- src TimerDateAndTime
		les	di, ss:destTDAT		;es:di <- dest TimerDateAndTime
		mov	ax, ss:offsetGMT	;ax <- offset to GMT
		call	LocalNormalizeDateTime

		.leave
		ret
LOCALNORMALIZEDATETIME	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCalcDayOfWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the day of the week

C DECL:
	extern word
	    _pascal LocalCalcDayOfWeek(word year, word month, word day);

CALLED BY:	UTILITY
PASS:		year - 1980 - 2099
		month - 1-12
		day - 1-31
RETURN:		ax - DayOfTheWeek (0-6)
DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/22/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOCALCALCDAYOFWEEK	proc	far	year:word, cdmonth:word, day:word
		.enter

		mov	ax, ss:year			;ax <- year
		mov	bl, {byte}ss:cdmonth		;bl <- month
		mov	bh, {byte}ss:day		;bh <- day
		call	LocalCalcDayOfWeek		;cl <- day of the week
		clr	ax
		mov	al, cl				;ax <- DayOfTheWeek

		.leave
		ret
LOCALCALCDAYOFWEEK	endp

C_Local	ends


	SetDefaultConvention
