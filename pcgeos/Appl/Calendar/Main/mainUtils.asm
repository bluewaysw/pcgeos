COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainUtils.asm

AUTHOR:		Don Reeves, July 11, 1989

ROUTINES:
	Name			Description
	----			-----------
    GLB TimeToTextObject	Creates a time string and sets the Text
				Object to display this string.

    GLB DateToTextObject	Creates a time string and sets the Text
				Object to display this string.

    GLB TimeToMoniker		Creates a time string and sets the moniker
				of the passed object to be the this string.

 ?? INT CreateTimeString	Create the event time title

 ?? INT AddEndTimeString	Creates end time string, adding it to the
				regular time string.

    GLB CreateDateString	Create a window title

 ?? INT WriteLocalizedString	Write the "today is" string into the buffer

 ?? INT ParseTime		Parses a text string into a time of day

 ?? INT SkipSpaces		Skip spaces until non-space or
				end-of-string

 ?? INT GetNum			Gets a number (in ascii) and converts to
				hex

    GLB GetTwoDigitNum		Gets the value for a 1 or 2 digit number

 ?? INT ParseDate		Parses a full date (11-21-89) into the
				month, day & year

    GLB StringToDate		Converts a string to a date

    GLB StringToTime		Converts a string into time

    INT StringToCommonError	Display the error message, and possible
				reset the focus

    GLB CheckValidDayMonth	Checks for valid day (1->31) & month
				(1->12)

    EXT CalendarGetShortDateFullYear
				Get the current date in short form and full
				year like 01.19.1997

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/25/91		Broken out of mainCalendar.asm

DESCRIPTION:
	Define the calendar application's main utility functions

	$Id: mainUtils.asm,v 1.1 97/04/04 14:48:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a time string and sets the Text Object to display
		this string.

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		DS	= Relocatable segment
		DI:SI	= Block:chunk of TextObject
		CX	= Hours/Minutes

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TimeToTextObject	proc	far

	; Create the time string
	;
	push	di, es
	mov	bx, di				; BX:SI is the TextEditObject
	segmov	es, ss, dx			; SS to ES and DX!
	sub	sp, DATE_TIME_BUFFER_SIZE	; allocate room on the stack
	mov	di, sp				; ES:DI => buffer to fill
	mov	bp, di				; buffer also in DX:BP
	call	CreateTimeString		; create the string

	; Now stuff the string into a text object
toTextObjectCommon	label	far
	clr	cx				; string is NULL terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
toObjectCommon		label	far
	call	ObjMessage_common_call		; send the method
	add	sp, DATE_TIME_BUFFER_SIZE	; restore the stack
	pop	di, es
	ret
TimeToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a time string and sets the Text Object to display
		this string.

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		DS	= Relocatable segment
		DI:SI	= Block:chunk of TextObject
		BP	= Year
		DX	= Month/Day
		CX	= DateTimeFormat (for date strings only!)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DateToTextObject	proc	far
	
	; First create the date string
	;
	push	di, es
	mov	bx, di				; BX:SI is the TextEditObject
	segmov	es, ss, di
	sub	sp, DATE_TIME_BUFFER_SIZE	; allocate buffer on stack
	mov	di, sp				; ES:DI => buffer to fill
	call	CreateDateString		; create the string
	mov	bp, sp				; stack hasn't changed...
	mov	dx, es				; DX:BP is the time string

	; Now stuff the text object with the string
	;
	jmp	toTextObjectCommon
DateToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 		TimeToMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a time string and sets the moniker of the passed
		object to be the this string.

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		DS	= Relocatable segment
		DI:SI	= Block:chunk of TextObject
		CX	= Hours/Minutes

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Prepends a space onto the string, for spacing reasons.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DISPLAY_TIME
TimeToMoniker	proc	far
	
	; Create the time string
	;
	push	di, es
	mov	bx, di				; BX:SI is the TextEditObject
	segmov	es, ss, dx			; SS to ES and DX!
	sub	sp, DATE_TIME_BUFFER_SIZE	; allocate room on the stack
	mov	di, sp				; ES:DI => buffer to fill
SBCS <	mov	{byte} es:[di], ' '		; prepend a space	>
DBCS <	mov	{wchar} es:[di], ' '		; prepend a space	>
	LocalNextChar esdi			; go to the next character
	call	CreateTimeString		; create the string

	; Now stuff the string into a text object

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, dx
	mov	dx, sp				; time string => CX:DX
	mov	bp, VUM_NOW			; update now
	jmp	toObjectCommon			; finish up
TimeToMoniker	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTimeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the event time title

CALLED BY:	DayEventInit

PASS:		CL	= Minutes
		CH	= Hours
		ES:DI	= String buffer to fill

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/24/89		Initial version
	Don	12/19/90	Use the localization routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateTimeString	proc	far
	uses	cx, dx, si
	.enter
	
	; Setup call to localization driver
	;
SBCS <	mov	{byte} es:[di], 0		; NULL terminated	>
DBCS <	mov	{wchar} es:[di], 0		; NULL terminated	>
	cmp	cx, -1
	je	done				; if no time, get NULL string
	mov	si, DTF_HM			; use hours & minutes
	mov	dl, cl				; minutes => DL, hours => CH
	call	LocalFormatDateTime		; create the string => ES:DI
done:
	.leave
	ret
CreateTimeString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDateString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a window title

CALLED BY:	GLOBAL

PASS:		BP	= Year
		DH	= Month
		DL	= Day
		CX	= DateTimeFormat (for date strings only!)
		ES:DI	= Pointer to the string

RETURN:		ES:DI	= Points to end of the string (NULL termination)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If the day of week is required by the passed format, then
		set the high bit of CX when passing the DateTimeFormat.
		Otherwise it will not be calculated.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	06/89		Initial version
	Don	11/29/89	Separated into several routines
	Don	12/19/90	Use the localization routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateDateString	proc	far
	uses	ax, bx, cx, dx, si
	.enter

	; Call the localization driver
	;
SBCS <	mov	{byte} es:[di], 0		; terminate the string	>
DBCS <	mov	{wchar} es:[di], 0		; terminate the string	>
	cmp	dx, -1				; no date ??
	je	done				; yes, so we're done
	mov	si, cx
	and	si, not (USES_DAY_OF_WEEK)
	test	cx, USES_DAY_OF_WEEK
	jz	checkForYear
	call	CalcDayOfWeek			; day of week => CL
checkForYear:
	mov	ax, bp				; Year => AX
	mov	bl, dh				; month => BL
	mov	bh, dl				; day => BH
	call	LocalFormatDateTime		; create the string
DBCS <	shl	cx, 1							>
	add	di, cx				; point to end of the string
done:
	.leave
	ret
CreateDateString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteLocalizedString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the "today is" string into the buffer

CALLED BY:	CreateDateString
	
PASS: 		ES:DI	= String buffer		
		SI	= Chunk handle in DataBlock to use

RETURN:		ES:DI	= Points to next char position

DESTROYED:	AX, BX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteLocalizedString	proc	far
	uses	cx, ds
	.enter

	; Access the strings block
	;
	mov	bx, handle DataBlock
	call	MemLock				; lock the block
	mov	ds, ax

	; Access the correct day of week
	;	
	mov	si, ds:[si]			; dereference the handle
	ChunkSizePtr	ds, si, cx		; bytes length => CX
DBCS <	shr	cx, 1							>
	dec	cx				; don't include final NULL
SBCS <	rep	movsb				; move the bytes	>
DBCS <	rep	movsw				; move the bytes	>
SBCS <	mov	{byte} es:[di], ' '		; put in a space	>
DBCS <	mov	{wchar} es:[di], ' '		; put in a space	>
	LocalNextChar esdi

	; Now clean up
	;
	mov	bx, handle DataBlock		; get the block handle
	call	MemUnlock			; unlock the block

	.leave
	ret
WriteLocalizedString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses a text string into a time of day

CALLED BY:	StringToTime

PASS:		CX	= Length of string
		BX	= Text handle

RETURN:		Carry	= Set if invalid time
		CL	= Minutes
		CH	= Hours

DESTROYED:	AX, BX, DX, DI, ES

PSEUDO CODE/STRATEGY:
		Assume time format of HH:MM am or pm
		If hour missing, assume twelve noon
		If delimiter of minutes missing, fail
		If bad postfix, fail
		If no postfix, 8:00 -> 11:59 is AM
			       12:00 -> 7:59 is PM

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/3/89		Initial version
	Don	6/12/90		Allow partial times (no postfix)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParseTime	proc	far
	uses	si
	.enter
	
	; Lock the block first
	;
	push	bx				; save the block handle
	call	MemLock				; lock this block
	mov	es, ax				; move segment to ES
	clr	di				; ES:DI points to the string
		
	; We will accept one of the following formats
	; - BLANK
	; - DTF_HM
	; - DTF_H
	;
	call	SkipSpaces			; skip all spaces
	mov	ch, -1				; assume no time
	mov	dl, -1
	jc	done				; if carry set, no time!
	mov	si, DTF_HM			; check the default format
	call	LocalParseDateTime		; carry set if valid
	jc	done
	mov	si, DTF_H			; check the hour only format
	call	LocalParseDateTime		; carry set if valid
	mov	dl, 0				; no minutes, obviously
	jc	done

	; If the time has not yet been parsed, we'll try one more thing.
	; We'll attempt to parse assuming that the user failed to append
	; the postfix (an AM or PM), and will make an intelligent choice
	; as to what side of noon the event falls, based upon the hour.
	;
	push	ds
	segmov	ds, cs, si
	mov	si, offset customTimeTokenStr
	call	LocalCustomParseDateTime	; carry = set if successful
	pop	ds
	jnc	done				; if failed, we're done
	cmp	ch, 7				; hour is 8 or greater
	cmc					; invert the carry (set if gtr)
	jc	done				; if so, we're done
	add	ch, 12				; go to PM
	stc					; and set the carry

	; Accept the time provided
done:
	pop	bx
	pushf
	call	MemFree	
	popf
	mov	cl, dl				; minutes => CL
	cmc					; invert the carry

	.leave
	ret
ParseTime	endp

customTimeTokenStr	TCHAR	"|HH|:|mm|", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipSpaces
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip spaces until non-space or end-of-string

CALLED BY:	ParseTime, GePostfix

PASS:		ES:DI	= Current character
		CX	= Last string position

RETURN: 	CF	= 1 if EOS
			= 0 otherwise

DESTROYED:	AL, CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipSpaces	proc	near
	jcxz	fail				; if 0-length string, done
	sub	cx, di				; number of chars left
	LocalLoadChar ax, ' '			; space into AX		>
SBCS <	repe	scasb				; look for a space	>
DBCS <	repe	scasw				; look for a space	>
	jz	fail				; nothing but space - fail

	; Success, have es:[di] point to first mismatch
	;
	LocalPrevChar esdi
	clc
	ret

	; Failure, end of string
fail:
	stc
	ret
SkipSpaces	endp

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a number (in ascii) and converts to hex

CALLED BY:	ParseTime

PASS:		ES:DI	= Current character
		DX	= Last string position

RETURN:		AL	= The digit
		CF	= 1 if not a number or EOS
			= 0 otherwise

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetNum	proc	near
	cmp	di, dx
	jge	fail				; end of string
	mov	al, es:[di]
	sub	al, '0'				; turn into a number
	jl	fail
	cmp	al, 9
	jg	fail
	inc	di				; go to the next character
	clc
	ret

fail:
	stc
	ret
GetNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTwoDigitNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value for a 1 or 2 digit number

CALLED BY:	GLOBAL

PASS:		ES:DI	= String to start at
		ES:DX	= Last string position

RETURN:		AX	= Value
		Carry	= Set if no number

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetTwoDigitNum	proc	near
	
	call	GetNum
	jc	done				; no number
	mov	ah, al				; store MSB in AH
	call	GetNum
	jc	singleDigit			

	; Two digit number
	;
	mov	cl, al				; store LSB
	mov	al, ah				; MSB to AL
	mov	ch, 10				; multiplier
	mul	ch
	clr	ch
	add	ax, cx				; add in LSB
	clc					; clear the carry
	jmp	done

	; Singe digit number
	;
singleDigit:
	mov	al, ah				; store in AL
	clr	ah				; clears the carry
done:
	ret
GetTwoDigitNum	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses a full date (11-21-89) into the month, day & year

CALLED BY:	StringToDate

PASS:		CX	= Length of string
		BX	= Text handle

RETURN:		Carry	= Set if invalid date
		BP	= Year
		DH	= Month
		DL	= Day

DESTROYED:	AX, BX, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/21/89	Initial version
	Don	12/26/90	Now uses localization functions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParseDate	proc	far
	uses	si
	.enter

	; Lock the block, and some set-up
	;
	push	bx				; save the handle
	clc					; assume no text
	jcxz	done				; if no length, we're done
	call	MemLock				; lock the block
	mov	es, ax
	clr	di				; ES:DI points at the string
	mov	si, DTF_SHORT			; DateTimeFormat to use
	call	LocalParseDateTime		; perform the parse
	jc	found
	mov	si, DTF_ZERO_PADDED_SHORT
	call	LocalParseDateTime
	jnc	done				; if invalid parse, we're done

	; Move year, month, day to proper registers
found:
	mov	bp, ax				; year => AX
	mov	dh, bl				; month => DH
	mov	dl, bh				; day => DL
	call	CalcDaysInMonth			; days in month => CH
	inc	ch
	cmp	dl, ch				; set carry flag if OK
done:
	pop	bx				; restore the handle
	pushf
	call	MemFree				; free up the memory
	popf
	cmc					; invert the carry flag

	.leave
	ret
ParseDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringToDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a string to a date

CALLED BY:	GLOBAL

PASS: 		DI:SI	= Block:Chunk of text object

RETURN:		DX	= Year
		CH	= Month
		CL	= Day
		Carry	= Set if not a number

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Must be called from the Calendar thread!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringToDate	proc	far
	uses	ax, bx, di, bp, es
	.enter

	; Get the text
	;
	mov	bx, di				; block handle to BX
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; allocate a block of memory
	call	ObjMessage_common_call		; get the text
	push	bx				; save the block handle
	mov	bx, cx				; text handle => BX
	mov_tr	cx, ax				; text length => CX

	; Now parse the text
	;
	call	ParseDate
	pop	bx				; restore the block handle
	mov	cx, dx				; Month/Day => CX
	mov	dx, bp				; Year => DX
	mov	bp, CAL_ERROR_BAD_DATE		; error to display (maybe)
	jc	fail
	cmp	dx, LOW_YEAR			; check for year too low
	jge	done				; if larger or equal, good!
	mov	bp, CAL_ERROR_BAD_YEAR		; else display an error message

	; Else display the error message
fail:
	mov	di, DTF_SHORT			; DateTimeFormat => DI
	call	StringToCommonError		; call common error routine
done:
	.leave
	ret
StringToDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringToTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a string into time

CALLED BY:	GLOBAL

PASS: 		DI:SI	= Block:Chunk of text object
		CX	= 0 to allow no time
			<>  to force time text

RETURN:		CH	= Hours
		CL	= Minutes
		Carry	= Set if not a number

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Must be called from the Calendar thread!
		Note: if CX is returned with -1, no time string was provided.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringToTime	proc	far
	uses	ax, bx, dx, di, bp, es
	.enter

	; Get the text
	;
	mov	bx, di				; block handle to BX
	push	bx, cx				; save the flag
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; allocate a block of memory
	call	ObjMessage_common_call		; get the text
	mov	bx, cx				; text handle => BX
	mov_tr	cx, ax				; text length => CX

	; Now parse the text
	;
	call	ParseTime			; parse the time
	pop	bx, di				; restore obj handle, time flag
	jc	fail				; jump if parse errors
	tst	di				; allow no time ??
	jz	done				; yes, so all times are OK
	cmp	cx, -1				; do we have empty time??
	clc					; clear the carry flag
	jne	done				; no, so time is valid
fail:
	mov	bp, CAL_ERROR_BAD_TIME		; error message to display
	mov	di, DTF_HM			; DateTimeFormat => DI
	call	StringToCommonError		; call common error routine
done:
	.leave
	ret 
StringToTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringToCommonError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the error message, and possible reset the focus

CALLED BY:	INTERNAL
	
PASS:		BP	= CalErrorValue
		DI	= DateTimeFormat
		BX:SI	= OD of text object containing date/time
		
RETURN:		Carry	= Set

DESTROYED:	AX, BX, CX, DX, BP, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringToCommonError	proc	near
	.enter

	; Should we display errors at all ?
	;
	GetResourceSegmentNS	systemStatus, es
	test	es:[systemStatus], SF_DISPLAY_ERRORS
	jz	done

	; Create the time/date string & display the error message
	;
	push	bx, si				; save the text object OD
	mov	si, di				; DateTimeFormat => SI
	sub	sp, DATE_BUFFER_SIZE		; allocate space on the stack
	mov	di, sp
	segmov	es, ss
	mov	ax, 1999			; year 1999
	mov	bx, 18 shl 8 or 11		; November 18
	mov	cx, 15 shl 8 or 4		; 3 pm, Thursday
	mov	dx, 32 shl 8 or 45		; 32 seconds, 45 minutes
	call	LocalFormatDateTime		; create the appropriate string
	mov	cx, es
	mov	dx, di				; date/time string => CX
	call	GeodeGetProcessHandle		; my process handle => BX
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	call	ObjMessage_common_call		; display the error message
	add	sp, DATE_BUFFER_SIZE		; clean up the stack
	pop	bx, si				; restore the text object OD

	; Reset the focus & target to this object & select the text
	;	
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	ObjMessage_common_send		; select the text
	mov	ax, MSG_GEN_MAKE_FOCUS
	call	ObjMessage_common_send		; grab the focus
	mov	ax, MSG_GEN_MAKE_TARGET
	call	ObjMessage_common_send		; grab the target
done:
	stc

	.leave
	ret
StringToCommonError	endp

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValidDayMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for valid day (1->31) & month (1->12)

CALLED BY:	GLOBAL
	
PASS:		DL	= Day
		DH	= Month

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckValidDayMonth	proc	far
	cmp	dl, 1				; compare day with 1
	jl	error
	cmp	dl, 31				; compare day with 31
	jg	error
	cmp	dh, 1				; compare month with 1
	jl	error
	cmp	dh, 12				; compare month with 12
	jle	ok
error:
	ERROR	CHECK_VALID_DAY_MONTH_BAD_DATE
ok:
	ret
CheckValidDayMonth	endp
endif


CommonCode	ends

