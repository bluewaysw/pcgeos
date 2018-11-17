COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		dateTimeParse.asm

AUTHOR:		John Wedgwood, Nov 28, 1990

ROUTINES:
	Name			Description
	----			-----------
	DateTimeParse		Parse a string into a date/time.
	DateTimeFieldParse	Parse a string using a format string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/28/90	Initial revision

DESCRIPTION:
	Routines to parse dates and times.

	$Id: dateTimeParse.asm,v 1.1 97/04/05 01:17:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Format	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalParseDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a string using a generic format.

CALLED BY:	Global.
PASS:		es:di	= the string to parse.
		si	= DateTimeFormat to compare the string against.
RETURN:		carry set if the string is a valid date/time.
			ax	= Year
			bl	= Month
			bh	= Day (1-31)
			cl	= Weekday (0-6)

			ch	= Hours (0-23)
			dl	= Minutes (0-59)
			dh	= Seconds (0-59)
		    Any field for which there is no data specified in the
		    format string is returned containing -1.

		    For instance if you are comparing a string against a
		    format that contains only the month and year, then the
		    day, weekday, hour, minute, and seconds will all be
		    returned containing -1.

		carry clear if the string did not parse correctly.
			cx	= offset to the start of the text that didn't
				  to match.

DESTROYED:	If string matched: nothing
		If string didn't match: ax, bx, dx
		Basically, you should always assume that ax, bx, cx, dx
		are affected by a call to this routine.

PSEUDO CODE/STRATEGY:
	Choose the appropriate format string from the FormatStrings resource
	and call DateTimeFieldParse().

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalParseDateTime	proc	far
	uses	ds, si, di
	.enter

	;
	; Make sure that the generic format passed is valid.
	;
EC <	cmp	si, DateTimeFormat					>
EC <	ERROR_AE DATE_TIME_ILLEGAL_FORMAT	; Bad format in si.	>

	call	LockStringsDS
	shl	si, 1				; si <- offset into chunks
	add	si, offset DateLong		; Always the first one.
	mov	si, ds:[si]			; ds:si <- formatting string.

	call	LocalCustomParseDateTime	; Do the parsing.

	call	UnlockStrings

	.leave
	ret
LocalParseDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCustomParseDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a string using a specific format string.

CALLED BY:	Global, DateTimeParse
PASS:		es:di	= string to parse.
		ds:si	= format string to compare against.
RETURN:		carry set if the string is a valid date/time.
			ax	= Year
			bl	= Month
			bh	= Day (1-31)
			cl	= Weekday (0-6)

			ch	= Hours (0-23)
			dl	= Minutes (0-59)
			dh	= Seconds (0-59)
		    Any field for which there is no data specified in the
		    format string is returned containing -1.

		    For instance if you are comparing a string against a
		    format that contains only the month and year, then the
		    day, weekday, hour, minute, and seconds will all be
		    returned containing -1.

		carry clear if the string did not parse correctly.
			cx	= offset to the start of the text that didn't
				  match.

DESTROYED:	If string matched: nothing
		If string didn't match: ax, bx, dx
		Basically, you should always assume that ax, bx, cx, dx
		are affected by a call to this routine.

PSEUDO CODE/STRATEGY:

loop:
	if (next format character == '|') then
	    parse token
	    skip token end
	else
	    if (next format character != next string character) then
	        quit, didn't match.
	    endif
	endif
	goto loop;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version
	sean	1/10/96		Responder change so 24:00 isn't
				returned as 00:00.  Error(clc) is
				returned instead.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
LocalCustomParseDateTime	proc	far
	mov	ss:[TPD_dataBX], handle LocalCustomParseDateTimeReal
	mov	ss:[TPD_dataAX], offset LocalCustomParseDateTimeReal
	GOTO	SysCallMovableXIPWithESDI	
LocalCustomParseDateTime	endp
CopyStackCodeXIP	ends

else

LocalCustomParseDateTime	proc	far
	FALL_THRU	LocalCustomParseDateTimeReal
LocalCustomParseDateTime	endp

endif

LocalCustomParseDateTimeReal	proc	far
	uses	bp, si
	.enter
	
if 	FULL_EXECUTE_IN_PLACE
EC <	push	bx					>
EC <	mov	bx, ds					>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx					>
endif
	;
	; Set all the default values...
	;
	mov	ax, -1			; Year
	mov	bp, ax			; Yearr
	mov	bx, bp			; Month, Day
	mov	cx, bp			; Weekday, Hour
	mov	dx, bp			; Minute, Second

	push	di			; Save ptr to string start.
parseLoop:
SBCS <	cmp	{byte} es:[di], ' '	; See if string has a space	>
DBCS <	cmp	{wchar} es:[di], ' '	; See if string has a space	>
	jne	getFormatStringChar	; No, branch
	LocalNextChar esdi		; Else ignore it
	jmp	short parseLoop		; And try again

getFormatStringChar:
	LocalGetChar	ax, dssi	; al <- next format character.	>
	LocalCmpChar	ax, ' '		; a space?
	je	getFormatStringChar	; yes, ignore it and try again
	
	LocalCmpChar	ax, TOKEN_DELIMITER	; Check for on a token.
	jne	compareChars		; Branch if not on a token.

	lodsw				; ax <- the token to match.
DBCS <	lodsw				; ax <- 2nd char		>
DBCS <	mov	ah, ds:[si][-4]		; ah <- low part of 1st char	>
DBCS <	xchg	al, ah			; al <- 1st char, ah <- 2nd	>
	call	ParseToken		; Parse the token.
	LocalNextChar dssi		; skip token end.

	jc	parseLoop		; Branch if parsed correctly.
	jmp	abort			; Else abort, didn't parse correctly.

compareChars:
SBCS <	cmp	al, {byte} es:[di]	; Check for same character	>
DBCS <	cmp	ax, {wchar} es:[di]	; Check for same character	>
	jne	abort			; Nope, we're really off the pattern
	
	LocalIsNull ax			; Check for end of string.
	jz	parsedOK		; Loop if not end of string.

	LocalNextChar esdi		; Advance to next string character.
	jmp	parseLoop		; Loop to do the next one.

parsedOK:
	mov	ax, bp			; Return year in ax.
	pop	di			; Restore ptr to string start.
	;
	; One more thing before leaving... We need to convert the HourRecord
	; into a real hour value. See below for more information.
	;
	call	ConvertHourRecord

	;
	; Last thing before leaving... We need to allow 24:00:00.
	;
	cmp	ch, 24
	jne	allOK

	tst	dx			; 24:00:00 is ok
	jz	2400$
	cmp	dx, 0xff00		; 24:00:00 is ok
	je	2400$
	cmp	dx, 0x00ff		; 24:00:00 is ok
	je	2400$
	cmp	dx, 0xffff		; 24:00:00 is ok
	je	2400$
	push	di			; push di back on stack
	jmp	abort			; so we can abort

2400$:
	clr	ch			; change 24:00 -> 0:00

allOK:
	stc				; Signal: Did parse correctly.
done:
	.leave
	ret

abort:
	mov	cx, di			; cx <- ptr to start of bad text.
	pop	di			; Restore di.
	sub	cx, di			; cx <- offset to mismatched char.
	clc				; Signal: Didn't parse.
	jmp	done			; Branch to return.

LocalCustomParseDateTimeReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCalcDaysInMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of days in the passed month/year

CALLED BY:	GLOBAL

PASS:		AX	= Year
		BL	= Month

RETURN:		CH	= Days in the month

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Does not accout for ancient calendars (before 1900)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalCalcDaysInMonth	proc	far
	uses	bx
	.enter
	
	; First get number of days in this month
	;
EC <	cmp	ax, 1900						>
EC <	WARNING_B	DATE_TIME_YEAR_TOO_OLD				>
EC <	tst	bl							>
EC <	ERROR_Z		DATE_TIME_ILLEGAL_MONTH				>
EC <	cmp	bl, 12							>
EC <	ERROR_A		DATE_TIME_ILLEGAL_MONTH				>
	clr	bh				; make it a word
	mov	ch, {byte}cs:[monthLengths][bx]	; get days in this month

	; Now look for a leap year
	;
	cmp	bl, 2				; is the month February
	jne	done				; no - we're done
	call	IsLeapYear			; is it a leap year ?
	jnc	done
	inc	ch				; add a day
done:
	.leave
	ret
LocalCalcDaysInMonth	endp

;
; In parsing numbers, there are certain limits on the values that are
; acceptable.
;
; For instance:
;	Year:	 0000 - 9999
;	Month:	 1 - 12
;	Day:	 1 - 31
;	Weekday: 0 - 6
;	12-Hour: 1 - 12
;	24-Hour: 0 - 23
;	Minute:	 0 - 59
;	Second:	 0 - 59
;
; Basically we need to encode the following:
;	Zero is allowed (or not).
;	Upper limit.
; We encode this with a record (of course). This record is passed to the
; number parsing routine.
;
LimitRecord	record
    LR_ALL_DIGITS_PRESENT:1	; Set: All n digits must be present
    LR_ZERO_NOT_ALLOWED:1	; Set: Zero is not allowed.
    LR_LIMIT_VALUE:14		; The upper limit.
LimitRecord	end

;
; This encoding has some nice readability properties.
; For a month, the values are 1-12
; This is encoded as:
;	LR_ALL_DIGITS_PRESENT =  0  (1 or 2 digits is fine)
;	LR_ZERO_NOT_ALLOWED   =  1  (Zero is not allowed)
;	LR_LIMIT_VALUE	      = 12  (Upper limit)
; or as:
;	LimitRecord<0,1,12>
;


;
; We can't just store the hour. It isn't that simple. We don't know if we will
; find an AM or PM before or after we find the actual hour itself.
; If we assume the am/pm marker will come after the time, then we're set, we
; can just add 12 if we are in the pm. But if the am/pm marker comes before
; the time, we need to note it, but not set the hour yet because we don't
; know if we'll find a valid one.
;
; Also, we have no registers to spare for the flags we need, so we lump them
; in with the hour value itself.
;
; In addition, since the default value of the hour register is -1 (0xff) we
; need a sort of reverse logic, clearing bits to indicate when we have
; encountered something of importance.
;
HourRecord	record
    HR_NO_AM_PM:1		; Clear: An am/pm has been encountered.
				; Set: (Default) No am/pm encountered.
    HR_IS_AM:1			; Clear: A 'pm' has been encountered.
				; Set: (Default) Assume am.
    HR_HOUR:6			; The actual value of the hour.
HourRecord	end


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertHourRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an hour record to a real hour value.

CALLED BY:	DateTimeFieldParse
PASS:		ch	= HourRecord.
RETURN:		ch	= The hour.
DESTROYED:	nothing, not even flags.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertHourRecord	proc	near
	uses	ax
	.enter
	pushf
	mov	al, ch
	and	al, mask HR_HOUR	; al <- value of the hour

	cmp	ch, -1			; Check for no hour encountered
	je	quit			; Quit if so.

	test	ch, mask HR_NO_AM_PM	; Check for no am/pm found.
	jnz	done			; Branch if so.
	;
	; if am was found
	;    if (hour == 12) then
	;	return 0
	;    else
	;	return hour
	; if pm was found
	;    if (hour == 12) then
	;	return hour
	;    else
	;	return hour + 12
	;
	test	ch, mask HR_IS_AM	; Set if an AM was found
	jz	isPM
	;
	; One special case, 12am should be returned as zero.
	;
	cmp	al, 12			; Check for 12am
	jne	done			; Branch if not
	and	ch, not mask HR_HOUR	; Clear the hour value (set to zero)
	jmp	done			; Finish up...
isPM:
	;
	; If the value is 12pm, then we return 12, otherwise we return
	; the hour + 12. Also added check for greater than twelve, to
	; prevent miscalculation of a 24-hour time (say 14:00) with a
	; postfix.
	;
	cmp	al, 12
	jge	done			; Quit if 12pm (or greater)
	add	ch, 12			; Else adjust the value up by 12.
done:
	and	ch, mask HR_HOUR	; Clear bits...
quit:
	popf
	.leave
	ret
ConvertHourRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a string to see if it matches a token.

CALLED BY:	DateTimeFieldParse
PASS:		ax	= token to match.
		es:di	= pointer to the string to match.
RETURN:		carry set if the token matched.
			es:di	= pointer past matching text.
			Appropriate value loaded into a register:
				bp	= year.
				bl	= Month.
				bh	= Day.
				cl	= Weekday.
				ch	= HourRecord.
				dl	= Minute.
				dh	= Seconds.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseToken	proc	near
	uses	ax, ds
	.enter
	push	es, di, cx		; Save text ptr, cx
	
	;
	; Get the segment address of the LocalStrings resource into ds
	;
	call	LockStringsDS

EC <	call	FarCheckDS_ES						>

	segmov	es, cs			; es:di <- ptr to token table.
	mov	di, offset tokenTable

	mov	cx, (size tokenTable)/2	; cx <- # of words in table.

	repne	scasw			; Find the token.
	;
	; Choke if the token wasn't found.
	;
EC <	ERROR_NZ DATE_TIME_FORMAT_UNKNOWN_TOKEN	>
	;
	; Want to get a ptr to the token parsers. di points past the token
	; that matched.
	;
	sub	di, offset tokenTable + 2
	mov	ax, cs:tokenParsers[di]
	pop	es, di, cx		; Restore text ptr, cx

	call	ax			; Call the token handler.

	;
	; Release the LocalStrings block
	;
	call	UnlockStrings

	.leave
	ret
ParseToken	endp

;---

if PZ_PCGEOS
tokenTable	char	TOKEN_TOKEN_DELIMITER,
						; Japanese Weekday tokens.
			TOKEN_LONG_WEEKDAY_JP,
			TOKEN_SHORT_WEEKDAY_JP,
						; Weekday tokens.
			TOKEN_LONG_WEEKDAY,
			TOKEN_SHORT_WEEKDAY,
						; Month tokens.
			TOKEN_LONG_MONTH,
			TOKEN_SHORT_MONTH,
			TOKEN_NUMERIC_MONTH,
			TOKEN_ZERO_PADDED_MONTH,
			TOKEN_SPACE_PADDED_MONTH,
						; Date tokens.
			TOKEN_LONG_DATE,
			TOKEN_SHORT_DATE,
			TOKEN_ZERO_PADDED_DATE,
			TOKEN_SPACE_PADDED_DATE,
						; Year tokens.
			TOKEN_LONG_YEAR,
			TOKEN_SHORT_YEAR,
						; Japanese year.
			TOKEN_LONG_EMPEROR_YEAR_JP,
			TOKEN_SHORT_EMPEROR_YEAR_JP,
						; 12-Hour tokens.
			TOKEN_12HOUR,
			TOKEN_ZERO_PADDED_12HOUR,
			TOKEN_SPACE_PADDED_12HOUR,
						; 24-Hour tokens.
			TOKEN_24HOUR,
			TOKEN_ZERO_PADDED_24HOUR,
			TOKEN_SPACE_PADDED_24HOUR,
						; Minute tokens.
			TOKEN_MINUTE,
			TOKEN_ZERO_PADDED_MINUTE,
			TOKEN_SPACE_PADDED_MINUTE,
						; Second tokens.
			TOKEN_SECOND,
			TOKEN_ZERO_PADDED_SECOND,
			TOKEN_SPACE_PADDED_SECOND,
						; AM/PM tokens
			TOKEN_AM_PM,
			TOKEN_AM_PM_CAP,
			TOKEN_AM_PM_ALL_CAPS
else
tokenTable	char	TOKEN_TOKEN_DELIMITER,
						; Weekday tokens.
			TOKEN_LONG_WEEKDAY,
			TOKEN_SHORT_WEEKDAY,
						; Month tokens.
			TOKEN_LONG_MONTH,
			TOKEN_SHORT_MONTH,
			TOKEN_NUMERIC_MONTH,
			TOKEN_ZERO_PADDED_MONTH,
			TOKEN_SPACE_PADDED_MONTH,
						; Date tokens.
			TOKEN_LONG_DATE,
			TOKEN_SHORT_DATE,
			TOKEN_ZERO_PADDED_DATE,
			TOKEN_SPACE_PADDED_DATE,
						; Year tokens.
			TOKEN_LONG_YEAR,
			TOKEN_SHORT_YEAR,
						; 12-Hour tokens.
			TOKEN_12HOUR,
			TOKEN_ZERO_PADDED_12HOUR,
			TOKEN_SPACE_PADDED_12HOUR,
						; 24-Hour tokens.
			TOKEN_24HOUR,
			TOKEN_ZERO_PADDED_24HOUR,
			TOKEN_SPACE_PADDED_24HOUR,
						; Minute tokens.
			TOKEN_MINUTE,
			TOKEN_ZERO_PADDED_MINUTE,
			TOKEN_SPACE_PADDED_MINUTE,
						; Second tokens.
			TOKEN_SECOND,
			TOKEN_ZERO_PADDED_SECOND,
			TOKEN_SPACE_PADDED_SECOND,
						; AM/PM tokens
			TOKEN_AM_PM,
			TOKEN_AM_PM_CAP,
			TOKEN_AM_PM_ALL_CAPS
endif

;
; A list of handlers for these tokens.
;
if PZ_PCGEOS
tokenHandlers	word	offset InsertTokenDelimiter,
						; Japanese Weekday handlers.
			offset InsertLongWeekdayJp,
			offset InsertShortWeekdayJp,
						; Weekday handlers.
			offset InsertLongWeekday,
			offset InsertShortWeekday,
						; Month handlers.
			offset InsertLongMonth,
			offset InsertShortMonth,
			offset InsertNumericMonth,
			offset InsertZeroPaddedMonth,
			offset InsertSpacePaddedMonth,
						; Date tokens.
			offset InsertLongDate,
			offset InsertShortDate,
			offset InsertZeroPaddedDate,
			offset InsertSpacePaddedDate,
						; Year tokens.
			offset InsertLongYear,
			offset InsertShortYear,
						; Japanese Year handlers.
			offset InsertLongEmperorYearJp,
			offset InsertShortEmperorYearJp,
						; 12-Hour tokens.
			offset Insert12Hour,
			offset InsertZeroPadded12Hour,
			offset InsertSpacePadded12Hour,
						; 24-Hour tokens.
			offset Insert24Hour,
			offset InsertZeroPadded24Hour,
			offset InsertSpacePadded24Hour,
						; Minute tokens.
			offset InsertMinute,
			offset InsertZeroPaddedMinute,
			offset InsertSpacePaddedMinute,
						; Second tokens.
			offset InsertSecond,
			offset InsertZeroPaddedSecond,
			offset InsertSpacePaddedSecond,
						; AM/PM tokens.
			offset InsertAM_PM,
			offset InsertAM_PM_Cap,
			offset InsertAM_PM_AllCaps
else
tokenHandlers	word	offset InsertTokenDelimiter,
						; Weekday handlers.
			offset InsertLongWeekday,
			offset InsertShortWeekday,
						; Month handlers.
			offset InsertLongMonth,
			offset InsertShortMonth,
			offset InsertNumericMonth,
			offset InsertZeroPaddedMonth,
			offset InsertSpacePaddedMonth,
						; Date tokens.
			offset InsertLongDate,
			offset InsertShortDate,
			offset InsertZeroPaddedDate,
			offset InsertSpacePaddedDate,
						; Year tokens.
			offset InsertLongYear,
			offset InsertShortYear,
						; 12-Hour tokens.
			offset Insert12Hour,
			offset InsertZeroPadded12Hour,
			offset InsertSpacePadded12Hour,
						; 24-Hour tokens.
			offset Insert24Hour,
			offset InsertZeroPadded24Hour,
			offset InsertSpacePadded24Hour,
						; Minute tokens.
			offset InsertMinute,
			offset InsertZeroPaddedMinute,
			offset InsertSpacePaddedMinute,
						; Second tokens.
			offset InsertSecond,
			offset InsertZeroPaddedSecond,
			offset InsertSpacePaddedSecond,
						; AM/PM tokens.
			offset InsertAM_PM,
			offset InsertAM_PM_Cap,
			offset InsertAM_PM_AllCaps
endif

	.assert	(size tokenTable eq size tokenHandlers)

;
; A list of handlers for these tokens.
;
if PZ_PCGEOS
tokenParsers	word	offset ParseTokenDelimiter,
						; Japanese Weekday handlers.
			offset ParseLongWeekdayJp,
			offset ParseShortWeekdayJp,
						; Weekday handlers.
			offset ParseLongWeekday,
			offset ParseShortWeekday,
						; Month handlers.
			offset ParseLongMonth,
			offset ParseShortMonth,
			offset ParseNumericMonth,
			offset ParseNumericMonth,	; Zero padded
			offset ParseNumericMonth,	; Space padded
						; Date tokens.
			offset ParseLongDate,
			offset ParseShortDate,
			offset ParseShortDate,		; Zero padded
			offset ParseShortDate,		; Space padded
						; Year tokens.
			offset ParseLongYear,
			offset ParseShortYear,
						; Japanese Year handlers.
			offset ParseLongEmperorYearJp,
			offset ParseShortEmperorYearJp,
						; 12-Hour tokens.
			offset Parse12Hour,
			offset Parse12Hour,		; Zero padded
			offset Parse12Hour,		; Space padded
						; 24-Hour tokens.
			offset Parse24Hour,
			offset Parse24Hour,		; Zero padded
			offset Parse24Hour,		; Space padded
						; Minute tokens.
			offset ParseMinute,
			offset ParseMinute,		; Zero padded
			offset ParseMinute,		; Space padded
						; Second tokens.
			offset ParseSecond,
			offset ParseSecond,		; Zero padded
			offset ParseSecond,		; Space padded
						; AM/PM tokens.
			offset ParseAM_PM,
			offset ParseAM_PM,		; Capitalized
			offset ParseAM_PM		; All caps.
else
tokenParsers	word	offset ParseTokenDelimiter,
						; Weekday handlers.
			offset ParseLongWeekday,
			offset ParseShortWeekday,
						; Month handlers.
			offset ParseLongMonth,
			offset ParseShortMonth,
			offset ParseNumericMonth,
			offset ParseNumericMonth,	; Zero padded
			offset ParseNumericMonth,	; Space padded
						; Date tokens.
			offset ParseLongDate,
			offset ParseShortDate,
			offset ParseShortDate,		; Zero padded
			offset ParseShortDate,		; Space padded
						; Year tokens.
			offset ParseLongYear,
			offset ParseShortYear,
						; 12-Hour tokens.
			offset Parse12Hour,
			offset Parse12Hour,		; Zero padded
			offset Parse12Hour,		; Space padded
						; 24-Hour tokens.
			offset Parse24Hour,
			offset Parse24Hour,		; Zero padded
			offset Parse24Hour,		; Space padded
						; Minute tokens.
			offset ParseMinute,
			offset ParseMinute,		; Zero padded
			offset ParseMinute,		; Space padded
						; Second tokens.
			offset ParseSecond,
			offset ParseSecond,		; Zero padded
			offset ParseSecond,		; Space padded
						; AM/PM tokens.
			offset ParseAM_PM,
			offset ParseAM_PM,		; Capitalized
			offset ParseAM_PM		; All caps.
endif

	.assert	(size tokenTable eq size tokenParsers)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseTokenDelimiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for a token delimiter in the text.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseTokenDelimiter	proc	near
SBCS <	cmp	{byte} es:[di], TOKEN_DELIMITER				>
DBCS <	cmp	{wchar} es:[di], TOKEN_DELIMITER			>
	jne	noMatch
	LocalNextChar esdi		; Advance the ptr.
	stc				; Signal a match.
done:
	ret

noMatch:
	clc				; Signal no match.
	jmp	done
ParseTokenDelimiter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseLongWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a long weekday name.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			cl	= Weekday.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseLongWeekday	proc	near
	uses	si, bx
	.enter
	push	cx
	mov	si, offset SundayLongName ; ^lbx:si <- ptr to 1st string.
	mov	cx, 7			; 7 strings to check.
	call	ParseResourceStrings	; Find one...
	mov	bl, cl			; bl <- weekday.
	pop	cx
	jnc	done			; Quit if no match.
	;
	; No error checking because if we are here we must have matched one
	; of the string resources, in which case the value must be 0-6.
	;
	mov	cl, bl			; cl <- weekday.
done:
	.leave
	ret
ParseLongWeekday	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseShortWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a short weekday name.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			cl	= Weekday.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseShortWeekday	proc	near
	uses	si, bx
	.enter
	push	cx
	mov	si, offset SundayShortName ; ^lbx:si <- ptr to 1st string.
	mov	cx, 7			; 7 strings to check.
	call	ParseResourceStrings	; Find one...
	mov	bl, cl			; bl <- weekday.
	pop	cx
	jnc	done			; Quit if no match.
	;
	; No error checking because if we are here we must have matched one
	; of the string resources, in which case the value must be 0-6.
	;
	mov	cl, bl			; cl <- weekday.
done:
	.leave
	ret
ParseShortWeekday	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseLongMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a long month name.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bl	= Month
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseLongMonth	proc	near
	uses	si, cx
	.enter
	push	bx
	mov	si, offset JanuaryLongName ; ^lbx:si <- ptr to 1st string.
	mov	cx, 12			; 12 strings to check.
	call	ParseResourceStrings	; Find one...
	pop	bx
	jnc	done			; Quit if no match.
	;
	; No error checking because if we are here we must have matched one
	; of the string resources, in which case the value must be 0-11.
	;
	mov	bl, cl			; bl <- month.
	inc	bl			; Count from 1 please.
done:
	.leave
	ret
ParseLongMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseShortMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a short month name.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bl	= Month
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseShortMonth	proc	near
	uses	si, cx
	.enter
	push	bx
	mov	si, offset JanuaryShortName ; ^lbx:si <- ptr to 1st string.
	mov	cx, 12			; 12 strings to check.
	call	ParseResourceStrings	; Find one...
	pop	bx
	jnc	done			; Quit if no match.
	;
	; No error checking because if we are here we must have matched one
	; of the string resources, in which case the value must be 0-11.
	;
	mov	bl, cl			; bl <- month.
	inc	bl			; Count from 1 please.
done:
	.leave
	ret
ParseShortMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseNumericMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a numeric month.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bl	= Month
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseNumericMonth	proc	near
	uses	ax, cx, bp
	.enter
	mov	bp, LimitRecord<0,1,12>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber

	jnc	done
	mov	bl, al			; bl <- month.
done:
	.leave
	ret
ParseNumericMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseLongDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a long day format (eg: 3rd)

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bh	= Day.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseLongDate	proc	near
	uses	ax, cx, si, bp
	.enter
	mov	bp, LimitRecord<0,1,31>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber

	jnc	done
	mov	bh, al			; bh <- day.
	;
	; Now we need to check the suffix.
	;
	push	bx			; Save day.
	mov	si, ax
	shl	si, 1
	add	si, (offset Suffix_1)-(size word)
					; si <- suffix to check.
					; -(size word) is because the day is
					; 1-31, not 0-based.

	mov	cx, 1			; Only check this one suffix.
	call	ParseResourceStrings	; Check for correct suffix.
	pop	bx			; Restore the day.
	;
	; Carry set if the suffix matched, clear otherwise.
	;
done:
	.leave
	ret
ParseLongDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseShortDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a short day format (eg: 3)

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bh	= Day.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseShortDate	proc	near
	uses	ax, cx, bp
	.enter
	mov	bp, LimitRecord<0,1,31>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber

	jnc	done
	mov	bh, al			; bh <- day.
done:
	.leave
	ret
ParseShortDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseLongYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a four digit year.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bp	= Year.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseLongYear	proc	near
	uses	ax, cx
	.enter
	mov	bp, LimitRecord<1,0,9999>
	mov	ch, 4			; 4 digits only please.
	call	ParsePaddedNumber

	jnc	done
	mov	bp, ax			; bp <- year.
done:
	.leave
	ret
ParseLongYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseShortYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a 2 digit year.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bp	= Year.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version
	don	 8/03/94	Now accepts long years too

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseShortYear	proc	near
	uses	ax, cx
	.enter
	;
	; There is really no reason why we shouldn't accept long years
	; too, so as to give the user some flexibility.
	;
	call	ParseLongYear
	jc	exit			; success, so we're done
	;
	; Otherwise try to parse a short year
	;
	mov	bp, LimitRecord<1,0,99>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber
	jnc	exit
	;
	; Add in the current century. For compatability reasons, always
	; assume that a short year is in the 20th century.
	;
	; *** Well, if the year is less than 30 then assume that it is in the
	; *** 21st century
	;
	cmp	ax, 30
	jae	10$
	add	ax, 100
10$:
	add	ax, 1900
	mov	bp, ax			; bp <- year.
	stc
exit:
	.leave
	ret
ParseShortYear	endp



if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseLongWeekdayJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a long Japanese weekday name.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			cl	= Weekday.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version
	koji	9/15/93		copy from ParseLongWeekday

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseLongWeekdayJp proc	near
	uses	si, bx
	.enter
	push	cx
	mov	si, offset SundayLongNameJp ; ^lbx:si <- ptr to 1st string.
	mov	cx, 7			; 7 strings to check.
	call	ParseResourceStrings	; Find one...
	mov	bl, cl			; bl <- weekday.
	pop	cx
	jnc	done			; Quit if no match.
	;
	; No error checking because if we are here we must have matched one
	; of the string resources, in which case the value must be 0-6.
	;
	mov	cl, bl			; cl <- weekday.
done:
	.leave
	ret
ParseLongWeekdayJp endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseShortWeekdayJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a short Japanese weekday name.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			cl	= Weekday.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version
	koji	9/15/93		copy from ParseShortWeekday

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseShortWeekdayJp proc near
	uses	si, bx
	.enter
	push	cx
	mov	si, offset SundayShortNameJp ; ^lbx:si <- ptr to 1st string.
	mov	cx, 7			; 7 strings to check.
	call	ParseResourceStrings	; Find one...
	mov	bl, cl			; bl <- weekday.
	pop	cx
	jnc	done			; Quit if no match.
	;
	; No error checking because if we are here we must have matched one
	; of the string resources, in which case the value must be 0-6.
	;
	mov	cl, bl			; cl <- weekday.
done:
	.leave
	ret
ParseShortWeekdayJp endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseLongEmperorYearJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a long Japanese year.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bp	= Year.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseLongEmperorYearJp proc near
	uses	ax, bx
	.enter
	call	LocalGetLongGengo	; bp = base year, ax = next emperor yr
					; bl, bh = base month, di = updated
	call	ParseEmperorYearJpCommon
	.leave
	ret
ParseLongEmperorYearJp endp

ParseEmperorYearJpCommon proc near
	uses	cx
	.enter
	jnc	done			; no match
	push	bp
	sub	ax, bp			; ax = years till next emperor
	inc	ax			; make 1-based
	mov	bp, ax			; pass as LimitRecord
	mov	ch, 4			; 4 digits only please.
	call	ParsePaddedNumber	; ax = number
	pop	bp
	jnc	done
	tst_clc	ax
	jz	done			; zero not allowed (carry clear)
	dec	ax
	add	bp, ax			; bp <- year.
	stc				; success
done:
	.leave
	ret
ParseEmperorYearJpCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseShortEmperorYearJp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a short Japanese year.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			bp	= Year.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseShortEmperorYearJp proc near
	uses	ax, bx
	.enter
	call	LocalGetShortGengo	; bp = base year, ax = next emperor yr
					; bl, bh = base month, di = updated
	call	ParseEmperorYearJpCommon
	.leave
	ret
ParseShortEmperorYearJp endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Parse12Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a 12 hour.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			ch.HR_HOUR	= Hour.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Parse12Hour	proc	near
	uses	ax, bp
	.enter
	push	cx
	mov	bp, LimitRecord<0,1,12>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber
	pop	cx

	jnc	done
	and	ch, not mask HR_HOUR
	or	ch, al			; Save the # of hours.
	stc
done:
	.leave
	ret
Parse12Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Parse24Hour
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a 24 hour.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			ch.HR_HOUR	= Hour.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Parse24Hour	proc	near
	uses	ax, bp
	.enter
	push	cx
	mov	bp, LimitRecord<0,0,24>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber
	pop	cx

	jnc	done
	and	ch, not mask HR_HOUR
	or	ch, al			; Save the # of hours.
	stc
done:
	.leave
	ret
Parse24Hour	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseMinute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a minute.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			dl	= Minute.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseMinute	proc	near
	uses	ax, cx, bp
	.enter
	mov	bp, LimitRecord<0,0,59>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber
	jnc	done
	mov	dl, al			; Save the # of minutes.
done:
	.leave
	ret
ParseMinute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseSecond
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a second.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			dh	= Second.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseSecond	proc	near
	uses	ax, cx, bp
	.enter
	mov	bp, LimitRecord<0,0,59>
	mov	ch, 2			; 2 digits only please.
	call	ParsePaddedNumber
	jnc	done
	mov	dh, al			; Save the # of seconds.
done:
	.leave
	ret
ParseSecond	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseAM_PM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an am/pm string.

CALLED BY:	ParseToken via tokenParsers.
PASS:		es:di	= pointer to the string to match against.
		ds	= LocalStrings (locked)
RETURN:		carry set if the token matched the string.
			es:di	= pointer past the matched text.
			ch.HR_NO_AM_PM = 0
			ch.HR_IS_AM set.
		carry clear otherwise.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseAM_PM	proc	near
	uses	bx, dx, si
	.enter
	mov	dx, cx			; Save cx.

	mov	si, offset AMText	; ^lbx:si <- ptr to 1st string.
	mov	cx, 2			; 2 strings to check (AM/PM).
	call	ParseResourceStrings	; Find one...
	jnc	done			; Quit if no match.
	;
	; Found a match, convert cx into flags and store them into dh.
	; These flags will get stuffed into cx before returning.
	;
	and	dh, not mask HR_NO_AM_PM ; There is an AM/PM.
	jcxz	fini			; Quit if matched AM.
	and	dh, not mask HR_IS_AM	; Is not AM.
fini:
	stc
done:
	mov	cx, dx			; Restore cx.
	.leave
	ret
ParseAM_PM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseResourceStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare a string against a series of resource strings.

CALLED BY:	Utility.
PASS:		es:di	= string to compare.
		ds	= Resource segment (locked)
		si	= chunk handle of first string to check against.
		cx	= # of strings to compare against.
RETURN:		carry set if a string match was found.
			cx = The string which matched (counting from 0,
			     where 0 is the first string checked).
			es:di = pointer past matched text.
		carry clear if no string match was found.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseResourceStrings	proc	near
	uses	ax, si
	.enter
	mov	bx, cx			; bx <- # of strings to check.
stringCompareLoop:
	push	di, si, cx		; Save pointer, chunk, # of strings.
	mov	si, ds:[si]		; ds:si <- ptr to the resource string.

	ChunkSizePtr	ds, si, ax	; ax <- length of the string
DBCS <	shr	ax, 1							>
	dec	ax			; Don't count the NULL.

	mov	cx, ax			; cx <- length of string to compare.
	call	LocalCmpStringsNoCase
	pop	di, si, cx		; Restore pointer, chunk, # of strings.
	je	foundMatch
	;
	; No match found, skip to next string.
	;
	add	si, 2			; Advance to next chunk handle.
	dec	bx			; One less to check
	jnz	stringCompareLoop	; Loop to check the next one.
	;
	; No matching string was found.
	;
	clc				; Signal: No match found.
	jmp	done
foundMatch:
	;
	; A matching string was found.
	; es:di	= pointer to start of text that matched.
	; ax	= # of characters in string that matched.
	; cx-bx	= the string which matched.
	;
DBCS <	shl	ax, 1							>
	add	di, ax			; Advance the pointer.
	sub	cx, bx			; cx <- string that matched.
	stc				; Signal: Match was found.
done:
	.leave
	ret
ParseResourceStrings	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParsePaddedNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse a padded number, 2-4 digits long.

CALLED BY:	Utility
PASS:		es:di	= pointer to text to parse as a number.
		bp	= LimitRecord
		ch	= the maximum number of digits to allow.
RETURN:		carry set if the string was a number.
			es:di	= pointer past parsed text.
			ax	= the number.
		carry clear if the string was not a number.
			ax	= -1.
		es:di	= pointer past the parsed text.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	foundDigit = 0			; Assume we haven't found a digit.
	retVal = 0			; Starting value.

	skip padding characters (spaces).
	while nDigits > 0 do
	    if next character is a digit then
		foundDigit++		; We have found one more digit.
	        retVal = retVal * 10	; Add it into the current value.
		retVal += nextChar - '0'
	    else
	        goto endLoop
	    endif
	    nDigits--
	end
endLoop:
	if foundDigit == 0 then
	    return( no number found, -1 )
	else
	    return( number found, retVal )
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParsePaddedNumber	proc	near
	uses	bx, cx, dx, bp
	.enter
	push	di			; Save ptr to start of text.
					;
	clr	cl			; cl <- "found a digit" flag.
	clr	ax			; ax <- return value.
	mov	bx, 10			; bx <- value to multiply by.
	;
	; <space> is the only padding character we can skip. The other
	; padding character is <0>, which will be interpreted as a digit.
	;
checkPadLoop:
SBCS <	cmp	{byte} es:[di], 0	; Check for terminator.		>
DBCS <	cmp	{wchar} es:[di], 0	; Check for terminator.		>
	je	checkNextDigit		; Branch if NULL.
SBCS <	cmp	{byte} es:[di], ' '	; Check for a space.		>
DBCS <	cmp	{wchar} es:[di], ' '	; Check for a space.		>
	jne	checkNextDigit		; Branch if no space.

	LocalNextChar esdi		; Skip character
	jmp	checkPadLoop		; Loop to check next character.
checkNextDigit:
	;
	; We had better be staring at a digit...
	;
SBCS <	cmp	{byte} es:[di], '0'					>
DBCS <	cmp	{wchar} es:[di], '0'					>
	jb	notADigit
SBCS <	cmp	{byte} es:[di], '9'					>
DBCS <	cmp	{wchar} es:[di], '9'					>
	ja	notADigit
	;
	; It is a digit.
	; Multiply ax by 10 and add the value of the digit.
	;
	mul	bx			; ax <- ax * 10.

	add	al, es:[di]		; Add in the value of the digit.
	adc	ah, 0
	sub	ax, '0'

	LocalNextChar esdi		; Skip to the next character.
	mov	cl, 1			; Mark that we've found a digit.
	dec	ch			; One less digit to find.
	jnz	checkNextDigit
notADigit:
	;
	; One of two things happened:
	;	- We parsed a number, and we have reached the end of it.
	;	- We failed to find any number.
	; Luckily cl holds a flag which tells us if we've found a digit.
	;
	tst	cl			; Check for found any digits.
	jz	notANumber		; Branch if not.
	test	bp, mask LR_ALL_DIGITS_PRESENT
	jz	checkZero
	tst	ch			; If caller forces all digits to be
	jnz	notANumber		; present, then check for this
checkZero:
	;
	; Found digits, ax already holds the number, check against limit.
	;
	test	bp, mask LR_ZERO_NOT_ALLOWED
	jz	checkLimit
	;
	; Zero is not allowed, make sure ax isn't zero.
	;
	tst	ax			; Uh oh...
	jz	notANumber		; Invalid if zero.
checkLimit:
	and	bp, mask LR_LIMIT_VALUE	; bp <- limit.
	cmp	ax, bp
	ja	notANumber		; Not valid if over the limit

	pop	cx			; Discard pointer on stack.
	stc				; Signal: is a number.
done:
	.leave
	ret

notANumber:
	pop	di			; Restore ptr to text.
	mov	ax, -1			; Not-a-number value.
	clc				; Signal: not a number.
	jmp	done
ParsePaddedNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Date routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Days in each month (excluding leap years)
;
monthLengths 	label	byte
	byte	0	; zero padding
	byte	31	; January
	byte	28	; February
	byte	31	; March
	byte	30	; April
	byte	31	; May
	byte 	30	; June
	byte	31	; July
	byte	31	; August
	byte	30	; September
	byte	31	; October
	byte 	30	; November
	byte	31	; December


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsLeapYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the given year is a leap year

CALLED BY:	LocalCalcDaysInMonth

PASS:		AX	= Year

RETURN:		Carry	= Set if a leap year
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsLeapYear	proc	near
	uses	ax, cx, dx, bp
	.enter

	; Is the year divisible by 4
	;
	mov	bp, ax				; year to BP
	and	ax, 3				; is a leap year?
	jnz	done				; carry is clear

	; Maybe a leap year - check for divisible by 100
	;
	mov	ax, bp				; get the year again
	clr	dx				; clear the high byte
	mov	cx, 100				; set up divisor
	div	cx				; is it a century ??
	tst	dx				; check remainder
	jne	setCarry			; a leap year - carry clear

	; Still a leap year if divisible by 400 (at this point by 4)
	;
	and	ax, 3				; is evenly divisble by 4 ??
	jnz	done				; no
setCarry:
	stc					; set carry for leap year
done:
	.leave
	ret
IsLeapYear	endp

Format	ends
