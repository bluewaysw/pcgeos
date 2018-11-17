COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		dateTimeFields.asm

AUTHOR:		John Wedgwood, Nov 28, 1990

ROUTINES:
	Name			Description
	----			-----------
	DateTimeFieldFormat	Format date/time fields.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/28/90	Initial revision

DESCRIPTION:
	Low level routines for formatting date/time fields.

	$Id: dateTimeFields.asm,v 1.1 97/04/05 01:16:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Format	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCustomFormatDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a date. This is the externally-callable version.

		If you call this directly then you will NOT be language
		independent. This routine is intended to be used by applications
		who do not wish to be language independent or by the higher
		level date formatting routine.

		Before you decide to use this routine, I suggest you look
		into using DateFormat(), the language independent date
		formatting code.

CALLED BY:	Global.
PASS:		ds:si	= Format string.
		es:di	= Buffer to save formatted text in.

		ax	= Year (0000-9999)
		bl	= Month (1-12)
		bh	= Day (1-31)
		cl	= Weekday (0-6)

		ch	= Hours (0-23)
		dl	= Minutes (0-59)
		dh	= Seconds (0-59)

		Clearly you only need valid information in the registers
		which will actually be referenced. The registers used will
		depend on the data in the format string.

RETURN:		es:di	= Unchanged. (Pointer to start of string).
		cx	= # of characters in formatted string.
			  This does not include the NULL terminator at the
			  end of the string.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The algorithm is pretty simple:
loop:
	al <- next character from format-string.
	if al == 0, goto endloop
	if al == TOKEN_DELIMITER then
	    ax <- next two bytes
	    loop up token in table
	    call token handler
	    skip next byte in text (it's a TOKEN_DELIMITER).
	else
	    copy byte to destination string
	endif
	goto loop;
endloop:
	null terminate string
	compute string length
	return

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
LocalCustomFormatDateTime	proc	far
		mov	ss:[TPD_dataBX], handle LocalCustomFormatDateTimeReal
		mov	ss:[TPD_dataAX], offset LocalCustomFormatDateTimeReal
		GOTO	SysCallMovableXIPWithDSSI
LocalCustomFormatDateTime	endp
CopyStackCodeXIP	ends

else

LocalCustomFormatDateTime	proc	far
		FALL_THRU	LocalCustomFormatDateTimeReal
LocalCustomFormatDateTime	endp

endif

LocalCustomFormatDateTimeReal	proc	far
	uses	si, bp
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <		push	bx, si					>
EC <		movdw	bxsi, esdi				>
EC <		call	ECAssertValidFarPointerXIP		>
EC <		pop	bx, si					>
endif
	call	DateTimeFieldFormat

	.leave
	ret
LocalCustomFormatDateTimeReal	endp

;---

LockStringsDS	proc	far	uses ax, bx
	.enter

	mov	bx, handle LocalStrings
	call	MemThreadGrabFar

;	The LocalStrings resource should *never* be discarded, as it is a
;	writable pre-loaded resource.

EC <	ERROR_C	-1							>
	mov	ds, ax

	.leave
	ret
LockStringsDS	endp

UnlockStrings	proc	far	uses ax, bx
	.enter

	mov	bx, handle LocalStrings
	call	MemThreadReleaseFar

	.leave
	ret
UnlockStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateTimeFieldFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a date. This is the low-level routine.

		If you call this directly then you will NOT be language
		independent. This routine is intended to be used by applications
		who do not wish to be language independent or by the higher
		level date formatting routine.

		Before you decide to use this routine, I suggest you look
		into using DateFormat(), the language independent date
		formatting code.

CALLED BY:	Global.
PASS:		ds:si	= Format string.
		es:di	= Buffer to save formatted text in.

		ax	= Year (0000-9999)
		bl	= Month (1-12)
		bh	= Day (1-31)
		cl	= Weekday (0-6)

		ch	= Hours (0-23)
		dl	= Minutes (0-59)
		dh	= Seconds (0-59)

		Clearly you only need valid information in the registers
		which will actually be referenced. The registers used will
		depend on the data in the format string.

RETURN:		es:di	= Unchanged. (Pointer to start of string).
		cx	= # of characters in formatted string.
			  This does not include the NULL terminator at the
			  end of the string.
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	The algorithm is pretty simple:
loop:
	al <- next character from format-string.
	if al == 0, goto endloop
	if al == TOKEN_DELIMITER then
	    ax <- next two bytes
	    loop up token in table
	    call token handler
	    skip next byte in text (it's a TOKEN_DELIMITER).
	else
	    copy byte to destination string
	endif
	goto loop;
endloop:
	null terminate string
	compute string length
	return

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateTimeFieldFormat	proc	near
	uses	ax, bx, si, bp
	.enter
EC <	call	ECDateTimeCheckESDI	; Make sure ptr is OK.	>

	mov	bp, ax			; bp <- year.

	push	di			; Save ptr to string start.
stringLoop:
EC <	call	ECDateTimeCheckDSSI	; Make sure ptr is OK.	>
	LocalGetChar ax, dssi		; ax <- next char
	LocalIsNull ax			; Check for end of string.
	jz	endLoop			; Branch if so.

	LocalCmpChar ax, TOKEN_DELIMITER ; Check for a token start
	jne	saveByte		; Branch if not a token.

EC <	call	ECDateTimeCheckDSSI	; Make sure ptr is OK.	>
	lodsw				; ax <- the token.
DBCS <	lodsw				; ax <- 2nd char		>
DBCS <	mov	ah, ds:[si][-4]		; ah <- low part of 1st char	>
DBCS <	xchg	al, ah			; al <- 1st char, ah <- 2nd	>

	call	HandleToken		; Handle the token.

EC <	call	ECDateTimeCheckDSSI	; Make sure ptr is OK.	>
	LocalGetChar ax, dssi		; Skip end delimiter

EC <	LocalCmpChar	ax, TOKEN_DELIMITER		>
EC <	ERROR_NZ DATE_TIME_FORMAT_NO_END_DELIMITER	>
	jmp	stringLoop
saveByte:
	LocalPutChar esdi, ax		; Save char and move on.
EC <	call	ECDateTimeCheckESDI	; Make sure ptr is OK.	>
	jmp	stringLoop		; Loop to do next character
endLoop:
	LocalPutChar esdi, ax		; Save the null
EC <	call	ECDateTimeCheckESDI	; Make sure ptr is OK.	>

	mov	cx, di
	pop	di			; Restore source ptr.
	sub	cx, di			; cx <- length...
DBCS <	shr	cx, 1			; cx <- length			>
	dec	cx			; Don't count the null.
	.leave
	ret
DateTimeFieldFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a token that was encountered in the format string.

CALLED BY:	DateFieldFormat
PASS:		ax	= the token.
		bx,cx,dx,bp = possible arguments to the token handler.
		es:di	= ptr to pass on to token handler.
RETURN:		es:di	= possibly changed by token handler.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleToken	proc	near
	uses	ds, si
	.enter
	push	ds, es, di, cx		; Save text ptr, cx

	segmov	es, cs			; es:di <- ptr to token table.
	mov	di, offset tokenTable

	mov	cx, (size tokenTable)/2	; cx <- # of words in table.

	repne	scasw			; Find the token.
	;
	; Choke if the token wasn't found.
	;
EC <	ERROR_NZ DATE_TIME_FORMAT_UNKNOWN_TOKEN	>
	;
	; Want to get a ptr to the token handlers. di points past the token
	; that matched.
	;
	sub	di, offset tokenTable + 2
	mov	si, cs:tokenHandlers[di]
	pop	ds, es, di, cx		; Restore text ptr, cx

	call	LockStringsDS
	call	si			; Call the token handler.
	call	UnlockStrings
	.leave
	ret
HandleToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertTokenDelimiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a token delimiter into the output stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the character.
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertTokenDelimiter	proc	near
EC <	call	ECDateTimeCheckESDI			>
SBCS <	mov	{byte} es:[di], TOKEN_DELIMITER				>
DBCS <	mov	{wchar} es:[di], TOKEN_DELIMITER			>
	LocalNextChar esdi
	ret
InsertTokenDelimiter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertLongWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a weekday longname.

CALLED BY:	HandleToken
PASS:		es:di	= place to insert the weekday name.
		cl	= the weekday (0-6).
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertLongWeekday	proc	near
	uses	bx, cx, si
	.enter

	clr	ch
	shl	cx, 1			; cx <- offset into chunks.
	mov	si, offset SundayLongName
	add	si, cx			; si <- the chunk.
	call	StoreResourceString	; Save the string.
	.leave
	ret
InsertLongWeekday	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertShortWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an abbreviated weekday name.

CALLED BY:	HandleToken
PASS:		es:di	= place to store the weekday name.
		cl	= the weekday.
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertShortWeekday	proc	near
	uses	bx, cx, si
	.enter

	clr	ch
	shl	cx, 1			; cx <- offset into chunks.
	mov	si, offset SundayShortName
	add	si, cx			; si <- the chunk.
	call	StoreResourceString	; Save the string.
	.leave
	ret
InsertShortWeekday	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertLongMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the longname of a month.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bl	= month (1-12)
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertLongMonth	proc	near
	uses	bx, si
	.enter
	clr	bh			; bx <- month.
	dec	bx			; (get it in 0-11)
	shl	bx, 1			; Offset into a list of words.

	mov	si, offset JanuaryLongName
	add	si, bx			; si <- chunk handle.

	call	StoreResourceString
	.leave
	ret
InsertLongMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertShortMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an abbreviated month into the output stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bl	= Month (1-12).
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertShortMonth	proc	near
	uses	bx, si
	.enter
	clr	bh			; bx <- month.
	dec	bx			; (get it in 0-11)
	shl	bx, 1			; Offset into a list of words.

	mov	si, offset JanuaryShortName
	add	si, bx			; si <- chunk handle.

	call	StoreResourceString
	.leave
	ret
InsertShortMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertNumericMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a numeric version of the month into the output stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bl	= Month (1-12)
RETURN:		es:di	= pointer after the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertNumericMonth	proc	near
	uses	ax
	.enter
	mov	al, 0xff		; No padding.
	mov	ah, bl			; # to insert.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertNumericMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertZeroPaddedMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a month, but pad with '0' if it is only one digit.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bl	= Month (1-12)
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertZeroPaddedMonth	proc	near
	uses	ax
	.enter
	mov	al, '0'			; Pad character.
	mov	ah, bl			; # to insert.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertZeroPaddedMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSpacePaddedMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a month, but pad with spaces if one digit.

CALLED BY:	HandleToken
PASS:		es:di	= place to put text.
		bl	= the month.
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSpacePaddedMonth	proc	near
	uses	ax
	.enter
	mov	al, ' '			; Pad character.
	mov	ah, bl			; ah <- number to insert.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSpacePaddedMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertPadded2DigitNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a padded 2 digit number into the output stream.

CALLED BY:	Utility
PASS:		es:di	= place to put the text.
		ah	= the number to insert.
		al	= pad character.
			= 0xff for no padding.
RETURN:		es:di	= pointer after the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertPadded2DigitNumber	proc	near
	uses	ax, cx
	.enter
EC <	push	cx					>
EC <	mov	cx, 2			; Write 2 bytes	>
EC <	call	ECDateTimeCheckESDIForWrite		>
EC <	pop	cx					>

	mov	ch, al			; ch <- pad character
	mov	al, ah			;
	clr	ah			; ax <- the number

	mov	cl, 10			; cl <- # to divide by.
	div	cl			; al <- high digit.
					; ah <- low digit.
DBCS <	mov	cl, ah			; cl <- low digit		>

	add	al, '0'			; Set to '0'-'9'
DBCS <	clr	ah							>

	cmp	al, '0'			; Check for no high digit
	jne	hasHighDigit		; Branch if it has one
	;
	; No high digit, pad the number if desired.
	;
	cmp	ch, 0xff		; Check for no padding desired
	je	skipHighDigit		; Skip this digit if so.
	mov	al, ch			; Use pad character if no high digit.
hasHighDigit:
SBCS <	stosb				; Save high digit.		>
DBCS <	stosw				; Save high digit.		>
skipHighDigit:
SBCS <	mov	al, ah			; al <- low digit		>
DBCS <	mov	al, cl			; al <- low digit		>
	add	al, '0'			; Set to '0'-'9'
	LocalPutChar esdi, ax		; Save low digit.
	.leave
	ret
InsertPadded2DigitNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertLongDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a date, complete with suffix.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bh	= Day (1-31)
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertLongDate	proc	near
	uses	ax, bx, si
	.enter
	mov	al, 0xff		; No padding.
	mov	ah, bh			; # to insert.
	call	InsertPadded2DigitNumber
	;
	; Now save the suffix.
	;
	mov	bl, bh
	clr	bh
	dec	bx
	shl	bx, 1			; bx <- offset to correct suffix.
	mov	si, offset Suffix_1
	add	si, bx			; si <- chunk to use.

	call	StoreResourceString	; Save the suffix.
	.leave
	ret
InsertLongDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertShortDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a date without suffix.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bh	= Day (1-31)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertShortDate	proc	near
	uses	ax
	.enter
	mov	al, 0xff		; No padding.
	mov	ah, bh			; # to insert.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertShortDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertZeroPaddedDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a zero padded day into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bh	= Day (0-31)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertZeroPaddedDate	proc	near
	uses	ax
	.enter
	mov	al, '0'			; Zero padded.
	mov	ah, bh			; # to insert.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertZeroPaddedDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSpacePaddedDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a space padded date into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bh	= Day (1-31)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSpacePaddedDate	proc	near
	uses	ax
	.enter
	mov	al, ' '			; Space padded.
	mov	ah, bh			; # to insert.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSpacePaddedDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertLongYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a 4 digit year into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bp	= the year.
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertLongYear	proc	near
	uses	ax, bx, dx
	.enter
	mov	ax, bp			; dx.ax <- number
	clr	dx

	mov	bx, 100			; bx <- # to divide by
	div	bx			; ax <- high 2 digits.
					; dx <- low 2 digits.

	mov	ah, al			; ah <- 1st 2 digits.
	mov	al, '0'			; Zero padded.
	call	InsertPadded2DigitNumber

	mov	ah, dl			; ah <- 1st 2 digits.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertLongYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertShortYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a 2 digit year into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bp	= the year
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertShortYear	proc	near
	uses	ax, bx, dx
	.enter
	mov	ax, bp			; dx.ax <- number
	clr	dx

	mov	bx, 100			; bx <- # to divide by
	div	bx			; ax <- high 2 digits.
					; dx <- low 2 digits.

	mov	ah, dl			; ah <- low 2 digits.
	mov	al, '0'			; al <- padding character
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertShortYear	endp



if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertLongWeekdayJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a Japanese Weekday into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		cl	= the weekday(0-6).
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version
	koji	9/15/93		copy from InsertLongWeekday

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertLongWeekdayJp	proc near
	uses	bx, cx, si
	.enter
	clr	ch
	shl	cx, 1			; cx <- offset into chunks.
	mov	si, offset SundayLongNameJp
	add	si, cx			; si <- the chunk.
	call	StoreResourceString	; Save the string.
	.leave
	ret
InsertLongWeekdayJp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertShortWeekdayJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an abbreviated weekday name.

CALLED BY:	HandleToken
PASS:		es:di	= place to store the weekday name.
		cl	= the weekday.
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version
	koji	9/15/93		copy from InsertShortWeekday

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertShortWeekdayJp	proc near
	uses	bx, cx, si
	.enter
	clr	ch
	shl	cx, 1			; cx <- offset into chunks.
	mov	si, offset SundayShortNameJp
	add	si, cx			; si <- the chunk.
	call	StoreResourceString	; Save the string.
	.leave
	ret
InsertShortWeekdayJp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertLongEmperorYearJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a japanese year into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bp	= the year.
		bl	= Month (1-12)
		bh	= Day (1-31)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertLongEmperorYearJp	proc near
	uses	ax
	.enter
	mov	ax, bp				; ax = year
	call	LocalFormatLongGengo		; ax = remaining years
	call	InsertEmperorYearJpCommon
	.leave
	ret
InsertLongEmperorYearJp	endp

InsertEmperorYearJpCommon	proc near
	uses	bx, dx
	.enter
	LocalPrevChar	esdi			; point at null
	clr	dx
	mov	bx, 100				; bx <- # to divide by
	div	bx				; ax <- high 2 digits.
						; dx <- low 2 digits.
	tst	al
	jz	noHigh
	mov	ah, al				; ah <- 1st 2 digits.
	mov	al, 0xff			; not padded.
	call	InsertPadded2DigitNumber
noHigh:
	mov	ah, dl				; ah <- 1st 2 digits.
	mov	al, 0xff			; not padded.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertEmperorYearJpCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertShortEmperorYearJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a japanese year into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		bp	= the year.
		bl	= Month (1-12)
		bh	= Day (1-31)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertShortEmperorYearJp	proc near
	uses	ax
	.enter
	mov	ax, bp				; ax = year
	call	LocalFormatShortGengo		; ax = remaining years
	call	InsertEmperorYearJpCommon
	.leave
	ret
InsertShortEmperorYearJp	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Insert12Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert 24-hour clock value to 12-hour clock and insert.

CALLED BY:	HandleToken
PASS:		es:di	= place to insert.
		ch	= Hours (0-23).
RETURN:		es:di	= pointer after inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Insert12Hour	proc	near
	uses	ax
	.enter
	mov	al, 0xff		; No padding.
	mov	ah, ch			; ah <- # to insert.
	cmp	ah, 12			; Check for > 11
	jb	insertHour
	sub	ah, 12			; Force to 0-11
insertHour:
	;
	; In a 12-hour format, 0 isn't a valid number, it is replaced with 12.
	;
	tst	ah
	jnz	doInsert
	mov	ah, 12
doInsert:
	call	InsertPadded2DigitNumber
	.leave
	ret
Insert12Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertZeroPadded12Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a zero padded 12-hour into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= position to insert at.
		ch	= Hours (0-23)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertZeroPadded12Hour	proc	near
	uses	ax
	.enter
	mov	al, '0'			; Zero pad.
	mov	ah, ch			; ah <- # to insert.
	cmp	ah, 12			; Check for > 11
	jb	insertHour
	sub	ah, 12			; Force to 0-11
insertHour:
	;
	; In a 12-hour format, 0 isn't a valid number, it is replaced with 12.
	;
	tst	ah
	jnz	doInsert
	mov	ah, 12
doInsert:
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertZeroPadded12Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSpacePadded12Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a space padded 12 hour into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		ch	= Hour (0-23)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSpacePadded12Hour	proc	near
	uses	ax
	.enter
	mov	al, ' '			; Space pad.
	mov	ah, ch			; ah <- # to insert.
	cmp	ah, 12			; Check for > 11
	jb	insertHour
	sub	ah, 12			; Force to 0-11
insertHour:
	;
	; In a 12-hour format, 0 isn't a valid number, it is replaced with 12.
	;
	tst	ah
	jnz	doInsert
	mov	ah, 12
doInsert:
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSpacePadded12Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Insert24Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a 24-hour into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		ch	= Hour (0-23)
RETURN:		es:di	= pointer past the inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Insert24Hour	proc	near
	uses	ax
	.enter
	mov	al, 0xff		; No padding.
	mov	ah, ch			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
Insert24Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertZeroPadded24Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a zero padded 24-hour into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		ch	= Hour (0-23).
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertZeroPadded24Hour	proc	near
	uses	ax
	.enter
	mov	al, '0'			; Zero padded.
	mov	ah, ch			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertZeroPadded24Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSpacePadded24Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a space padded 24 hour into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		ch	= Hour (0-23)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSpacePadded24Hour	proc	near
	uses	ax
	.enter
	mov	al, ' '			; Space padded.
	mov	ah, ch			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSpacePadded24Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertMinute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a minute into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		dl	= Minute (0-59)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertMinute	proc	near
	uses	ax
	.enter
	mov	al, 0xff		; No padding
	mov	ah, dl			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertMinute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertZeroPaddedMinute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a zero padded minute into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		dl	= Minute (0-59)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertZeroPaddedMinute	proc	near
	uses	ax
	.enter
	mov	al, '0'			; Zero padding.
	mov	ah, dl			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertZeroPaddedMinute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSpacePaddedMinute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a space padded minute into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		dl	= Minute (0-59)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSpacePaddedMinute	proc	near
	uses	ax
	.enter
	mov	al, ' '			; Zero padding.
	mov	ah, dl			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSpacePaddedMinute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSecond
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a second into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		dh	= Second (0-59)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSecond	proc	near
	uses	ax
	.enter
	mov	al, 0xff		; No padding.
	mov	ah, dh			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSecond	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertZeroPaddedSecond
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a zero padded second into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the second
		dh	= Second (0-59)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertZeroPaddedSecond	proc	near
	uses	ax
	.enter
	mov	al, '0'			; Zero padding.
	mov	ah, dh			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertZeroPaddedSecond	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertSpacePaddedSecond
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a space padded second into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		dh	= Second (0-59)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertSpacePaddedSecond	proc	near
	uses	ax
	.enter
	mov	al, ' '			; Space padding.
	mov	ah, dh			; ah <- value to store.
	call	InsertPadded2DigitNumber
	.leave
	ret
InsertSpacePaddedSecond	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertAM_PM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an 'am/pm' into the stream.

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		ch	= Hour (0-23)
RETURN:		es:di	= pointer after the text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertAM_PM	proc	near
	uses	bx, si
	.enter
	mov	si, offset AMText	; Assume am string.
	cmp	ch, 12
	jb	gotString		; Branch if am
	mov	si, offset PMText	; Sigh, use pm string.
gotString:
	call	StoreResourceString
	.leave
	ret
InsertAM_PM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertAM_PM_Cap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert some sort of capitalized am/pm string.

CALLED BY:	HandleToken
PASS:		es:di	= place to store text.
		ch	= Hour (0-23)
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertAM_PM_Cap	proc	near
	uses	bx, si
	.enter
	mov	si, offset AMCapText	; Assume am string.
	cmp	ch, 12
	jb	gotString		; Branch if am
	mov	si, offset PMCapText	; Sigh, use pm string.
gotString:
	call	StoreResourceString
	.leave
	ret
InsertAM_PM_Cap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertAM_PM_AllCaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert some sort of all-caps version of am/pm

CALLED BY:	HandleToken
PASS:		es:di	= place to put the text.
		ch	= the hour.
RETURN:		es:di	= pointer past inserted text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertAM_PM_AllCaps	proc	near
	uses	bx, si
	.enter
	mov	si, offset AMAllCapsText ; Assume am string.
	cmp	ch, 12
	jb	gotString		; Branch if am
	mov	si, offset PMAllCapsText ; Sigh, use pm string.
gotString:
	call	StoreResourceString
	.leave
	ret
InsertAM_PM_AllCaps	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreResourceString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a string from a resource into a buffer.

CALLED BY:	Utility.
PASS:		es:di	= place to store the string.
		si	= chunk handle of the string in that resource.
RETURN:		es:di	= pointer after the last character stored.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreResourceString	proc	far
	uses	ax, bx, cx, ds, si
	.enter
	;
	; Lock the resource.
	;
	call	LockStringsDS		; ds <- resource segment address.
	;
	; Get the size of the string to copy and copy it into the buffer.
	;
	ChunkSizeHandle	ds, si, cx	; cx <- length of the string.
	mov	si, ds:[si]		; Dereference chunk handle.

DBCS <	shr	cx			; cx <- length of string	>
	dec	cx			; The string in the chunk is null
					;  terminated, we don't want to copy
					;  the NULL.
	;
	; cx = # of bytes to write.
	;
EC <	call	ECDateTimeCheckESDIForWrite	>

	LocalCopyNString		; Copy the string. rep movsb/movsw
	;
	; Unlock the resource.
	;
	call	UnlockStrings
	.leave
	ret
StoreResourceString	endp


Format	ends
