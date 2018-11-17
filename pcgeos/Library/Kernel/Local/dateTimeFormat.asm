COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		dateTimeFormat.asm

AUTHOR:		John Wedgwood, Nov 28, 1990

ROUTINES:
	Name			Description
	----			-----------
	DateTimeFormat		Format a date/time generically.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/28/90	Initial revision

DESCRIPTION:
	High level formatting routines for dates and times.

	$Id: dateTimeFormat.asm,v 1.1 97/04/05 01:17:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Format	segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	LocalCalcDayOfWeek

DESCRIPTION:	Figure the day of the week given its absolute date.

CALLED BY:	INTERNAL
		TimerSetDateAndTime

PASS:
	ax - year (1980 through 2099)
	bl - month (1 through 12)
	bh - day (1 through 31)

RETURN:
	cl - day of the week

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

LocalCalcDayOfWeek	proc	far
	uses	ax, bx, dx, ds
	.enter
	push	cx
	mov	cx, seg kcode
	mov	ds, cx				;ds = kcode
	assume	ds:kcode

	sub	ax,1904

	; add in extra days for leap years

	mov	dx,ax
	shr	ax,1
	shr	ax,1

	; if jan or feb and leap year then adjust

	test	dl,00000011b
	jnz	noLeap
	cmp	bl,3
	jae	noLeap
	dec	ax			;adjust
noLeap:
	add	ax,dx

	;add in offset for JAN 1, 1904 which was a FRIDAY

	add	ax,5

	; add days

	mov	cl,bh
	clr	ch
	add	ax,cx			;ax = total

	clr	bh			;bx = months
	jmp	noInc

dayLoop:
	add	al,ds:[bx][daysPerMonth-1]
	jnc	noInc
	inc	ah
noInc:
	dec	bx
	jnz	dayLoop

	mov	bl,7
	div	bl			; ah <- DOW (remainder)

	pop	cx
	mov	cl, ah
	.leave
	assume	ds:dgroup
	ret

LocalCalcDayOfWeek	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalFormatFileDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Like LocalFormatDateTime, except it works off a FileDate
		and a FileTime record

CALLED BY:	(GLOBAL)
PASS:		ax	= FileDate
		bx	= FileTime
		si	= DateTimeFormat
		es:di	= buffer into which to format
RETURN:		cx	= # of characters in formatted string, not including
			  null terminator
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalFormatFileDateTime proc	far
	uses	ax, bx, dx
	.enter
if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si					>
EC <	movdw	bxsi, esdi				>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx, si					>
endif	
	
	mov	dx, bx			; preserve time

	;
	; Break FileDate into its components
	; ax <- year
	; bl <- month (1-12)
	; bh <- day (1-31)
	; cl <- weekday
	; 
	mov	bx, ax
        and   	bx, mask FD_MONTH               ; month
EC <	ERROR_Z	DATE_TIME_ILLEGAL_MONTH					>
        mov     cl, offset FD_MONTH
        shr     bx, cl                          ; bl <- month
EC <	cmp	bx, 12							>
EC <	ERROR_A	DATE_TIME_ILLEGAL_MONTH					>

                CheckHack <offset FD_DAY eq 0 and width FD_DAY lt 8>
        mov     bh, al                          ; bh = day
        and   	bh, mask FD_DAY                 ; day
EC <	ERROR_Z	DATE_TIME_ILLEGAL_DAY					>
EC <	cmp	bh, 31							>
EC <	ERROR_A	DATE_TIME_ILLEGAL_DAY					>

                CheckHack <offset FD_YEAR + width FD_YEAR eq width FileDate>
        mov     cl, offset FD_YEAR
        shr     ax, cl                          ; ax = DOS year
        add     ax, 1980                        ; ax <- actual year

	;
	; Break FileTime into its components
	; ch <- hours (0-23)
	; dl <- minutes (0-59)
	; dh <- seconds (0-59)
	; 
	push	si
	mov	si, dx
                CheckHack <offset FT_HOUR + width FT_HOUR eq width FileTime>
        mov     cl, offset FT_HOUR
        shr     dx, cl
EC <	cmp	dl, 23							>
EC <	ERROR_A	DATE_TIME_ILLEGAL_HOUR					>
        mov     ch, dl                          ; ch = hours
        mov     dx, si                           ; minute

        andnf   dx, mask FT_MIN
        mov     cl, offset FT_MIN
        shr     dx, cl			; dl <- minutes
EC <	cmp	dl, 59							>
EC <	ERROR_A	DATE_TIME_ILLEGAL_MINUTE				>

	xchg	cx, si
	andnf	cx, mask FT_2SEC
	shl	cx, 1
	mov	dh, cl			; dh <- seconds
EC <	cmp	dh, 59							>
EC <	ERROR_A	DATE_TIME_ILLEGAL_SECONDS				>

	mov	cx, si
	pop	si
	call	LocalCalcDayOfWeek	; cl <- day of week

	call	LocalFormatDateTime
	.leave
	ret
LocalFormatFileDateTime endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalFormatDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a date/time generically.

CALLED BY:	Global.
PASS:		es:di	= place to put the formatted text.
		si	= DateTimeFormat. (Format enum to use).

		ax	= Year
		bl	= Month (1-12)
		bh	= Day (1-31)
		cl	= Weekday (0-6)

		ch	= Hours (0-23)
		dl	= Minutes (0-59)
		dh	= Seconds (0-59)

		You only need valid information in the registers which will
		actually be referenced. The registers used will depend on
		the data used as part of the format.
RETURN:		es:di	= the formatted string.
		cx	= # of characters in formatted string.
			  This does not include the NULL terminator at the
			  end of the string.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalFormatDateTime	proc	far
	uses	ds, si
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si						>
EC <	movdw	bxsi, esdi					>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	pop	bx, si						>
endif	
	;
	; Make sure that the generic format passed is valid.
	;
EC <	cmp	si, DateTimeFormat					>
EC <	ERROR_AE DATE_TIME_ILLEGAL_FORMAT	; Bad format in si.	>
EC <	call	ECDateTimeCheckESDI		; Make sure ptr is OK.	>

	call	LockStringsDS

	shl	si, 1				; si <- offset into chunks
	add	si, offset DateLong		; Always the first one.
	mov	si, ds:[si]			; ds:si <- formatting string.

	call	DateTimeFieldFormat		; Do the formatting.

	call	UnlockStrings

	.leave
	ret
LocalFormatDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDateTimeCheckESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if es:di points to a reasonable place.

CALLED BY:	Utility.
PASS:		es:di	= pointer to check.
RETURN:		nothing
DESTROYED:	nothing, not even flags.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK

ECDateTimeCheckESDI	proc	far
	uses	cx
	.enter
	clr	cx				; Writing nothing
	call	ECDateTimeCheckESDIForWrite
	.leave
	ret
ECDateTimeCheckESDI	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDateTimeCheckESDIForWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a pointer and a number of bytes to make sure that
		we can write the data out safely.

		This routine is also called to check ds:si to see if it is
		a valid pointer to read from, see ECDateTimeCheckDSSI() for
		more information.

CALLED BY:	Utility
PASS:		es:di	= pointer.
		cx	= # of bytes to write.
RETURN:		nothing
DESTROYED:	nothing, not even flags.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK

ECDateTimeCheckESDIForWrite	proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	pushf				; Save flags too.
	;
	; If the code dies in ECCheckSegment(), then one of two things is
	; possible:
	;	1 - es got trashed by one of the internal formatting routines.
	;	2 - es was no good when it was passed to a formatting routine.
	; I expect that #2 is the most likely.
	;
	; Keep in mind that if this is called from ECDateTimeCheckDSSI()
	; then the pointer we are checking is actually the format string
	; that we are reading from.
	;
	mov	ax, es			; ax <- segment to check.
	call	ECCheckSegment		; Double check es.

	push	cx, di			; Save # of bytes we expect to write.
	;
	; Now we want to make sure that di is in the bounds of the block
	; of which es is the segment.
	;
	mov	cx, ax			; cx <- segment address.
	call	MemSegmentToHandle	; cx <- handle.
	jc	10$			; found, continue

	pop	dx, di			; not found, pop stuff off stack
	jmp	short skipLockCheck	; and get out (block is kdata, probably)
10$:
	mov	bx, cx			; bx <- handle.
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	mov	cx, ax			; ch <- lock count.
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	pop	dx, di			; dx <- # of bytes we expect to write.
	add	di, dx			; di <- byte we will have written to.
	;
	; If the code dies in the next compare, then the formatting code has
	; a pointer past the end of the block, and is (in all likelyhood)
	; going to attempt to write data there. This can happen if:
	;	- The buffer allocated to hold the formatted string is not
	;	  large enough. This means the caller didn't allocate enough
	;	  space, or the system constants are incorrect, and didn't
	;	  account for the true size of the formatted text.
	;	- di got trashed in one of the internal formatting routines.
	;
	; Keep in mind that if this is called from ECDateTimeCheckDSSI()
	; then the pointer we are checking is actually the format string
	; that we are reading from.
	;
	cmp	di, ax
	ERROR_A	DATE_TIME_POINTER_BEYOND_BLOCK_END
	;
	; If the code dies in the next section, then the formatting code
	; is attempting to write to a block which isn't locked.
	;
	; Keep in mind that if this is called from ECDateTimeCheckDSSI()
	; then the pointer we are checking is actually the format string
	; that we are reading from.
	;
	test	cl, mask HF_FIXED	; Check for a fixed block.
	jnz	skipLockCheck
	tst	ch
	ERROR_Z	DATE_TIME_POINTER_INTO_UNLOCKED_BLOCK
skipLockCheck:

	popf				; Restore flags.
	.leave
	ret
ECDateTimeCheckESDIForWrite	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECDateTimeCheckDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a pointer to see if we are still reading valid data.

CALLED BY:	Utility
PASS:		ds:si	= pointer to check.
RETURN:		nothing
DESTROYED:	nothing, not even flags.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	ERROR_CHECK

ECDateTimeCheckDSSI	proc	far
	uses	es, di
	.enter
	segmov	es, ds
	mov	di, si
	call	ECDateTimeCheckESDI
	.leave
	ret
ECDateTimeCheckDSSI	endp

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetDateTimeFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a date/time format from our resource.

CALLED BY:	Global.

PASS:		es:di	= place to put new format string
		si	= DateTimeFormat. (Format enum to use).

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	12/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetDateTimeFormat	proc	far
	uses	ax, bx, cx, dx, di, si
	.enter

if	FULL_EXECUTE_IN_PLACE
EC <	push	bx, si					>
EC <	movdw	bxsi, esdi				>
EC <	call	ECAssertValidFarPointerXIP		>
EC <	pop	bx, si					>
endif
	
	shl	si, 1				; double for offset into chunks
	add	si, offset DateLong		; start of chunks
	call	StoreResourceString		; Return the string in es:di.
SBCS <	clr	al				; store a null terminator >
DBCS <	clr	ax							>
	LocalPutChar esdi, ax

	.leave
	ret
LocalGetDateTimeFormat	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	IsLegalFormatChar

SYNOPSIS:	Checks to see if character is legal for the given format.
		Only checks non-token characters; tokens must be dealt with
		another way.

CALLED BY:	EXTERNAL

PASS:	SBCS:	
		al 	- char to check
	DBCS:
		ax	- char to check
		si	- DateTimeFormat (format enum to use)

RETURN:		zero flag clear if legal, set if not.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 2/91		Initial version

------------------------------------------------------------------------------@

IsLegalFormatChar	proc	far
	uses	ds, si, bx, ax, cx
	.enter

EC <	cmp	si, DateTimeFormat					>
EC <	ERROR_AE DATE_TIME_ILLEGAL_FORMAT	; Bad format in si.	>

SBCS < 	mov	cl, al			; keep character to check in cl >
DBCS < 	mov	cx, ax			; keep character to check in cx >
	call	LockStringsDS
	shl	si, 1			;
	add	si, offset DateLong	; format string in *ds:si now
	mov	si, ds:[si]		; dereference

doChar:
	LocalGetChar ax, dssi		; get a character.
	LocalIsNull ax			; are we done?
	jne	tryChar			; no, try the character
	clr	al			; else set the zero flag
	jmp	exit			; and exit

tryChar:
	;
	; If this is a token, we'll ignore it, unless it represents
	; the delimiter character itself.
	;
	LocalCmpChar ax, TOKEN_DELIMITER	; is it the delimiter?
	jne	compareToFormatChar	; no, normal non-token char, do compare
SBCS <	add	si, 3							>
DBCS <	add	si, 3*(size wchar)					>
SBCS <	cmp	{word} ds:[si]-3, TOKEN_TOKEN_DELIMITER			>
DBCS <	cmp	{wchar} ds:[si]-6, TOKEN_TOKEN_CHAR_1			>
	jne	doChar			; if not representing the delimiter char
DBCS <	cmp	{wchar} ds:[si]-4, TOKEN_TOKEN_CHAR_2			>
DBCS <	jne	doChar							>
					;   ignore this token altogether,
					;   else we'll compare to the delimiter
					;   character (it's still in al)
compareToFormatChar:
SBCS <	cmp	al, cl			; see if we have a match	>
DBCS <	cmp	ax, cx			; see if we have a match	>
	jne	doChar			; no match, try another one
	or	al, 0ffh		; else clear the zero flag for a match
exit:
	;
	; Unlock the resource.
	;
	call	UnlockStrings

	.leave
	ret
IsLegalFormatChar	endp


Format	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetDateTimeFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a date/time format.

CALLED BY:	Global.

PASS:		es:di	= the new format string
		si	= DateTimeFormat. (Format enum to use).

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	12/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment resource

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
LocalSetDateTimeFormat	proc	far
		mov	ss:[TPD_dataBX], handle LocalSetDateTimeFormatReal
		mov	ss:[TPD_dataAX], offset LocalSetDateTimeFormatReal
		GOTO	SysCallMovableXIPWithESDI
LocalSetDateTimeFormat	endp
CopyStackCodeXIP	ends

else

LocalSetDateTimeFormat	proc	far
		FALL_THRU	LocalSetDateTimeFormatReal
LocalSetDateTimeFormat	endp

endif

LocalSetDateTimeFormatReal	proc	far
	uses	ax, cx, dx, si, bp, ds
	.enter

	push	si				; save resource num
	push	di				; save es:di (our string)
	push	es
	call	SetupFormatParameters		; setup parameters
	call	LocalWriteStringAsData		; write the stuff out
	pop	es
	pop	di				; restore es:di, new format str
	pop	si				; restore format enum

	shl	si, 1				;
	add	si, offset DateLong		;
	call	SetResourceString		; set the resource string

	.leave
	ret
LocalSetDateTimeFormatReal	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetResourceString

SYNOPSIS:	Sets a new resource string, over the old one.

CALLED BY:	DateTimeInitFormats

PASS:		es:di   -- buffer containing string to use
		cx      -- number of characters to store
		^lLocalStrings:si -- resource chunk to set

RETURN:		nothing

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/90	Initial version

------------------------------------------------------------------------------@

SetResourceString	proc	near	uses	ds, es, di, si
	.enter
if DBCS_PCGEOS
	call	LocalStringLength	;cx <- # chars w/o NULL
	inc	cx			;cx <- # chars w/NULL
	shl	cx, 1			;cx <- # bytes
else
	push	di
	mov	cx, -1
	clr	al
	repne	scasb			; find null byte to get size
	not	cx
	pop	di
endif

	call	LockStringsDS	; ax <- resource segment address.

	;
	; Resize the resource chunk to hold the new string.
	;
	mov	ax, si			; chunk handle in ax
	call	LMemReAlloc		; resize the resource chunk.

	mov	si, ds:[si]		; Dereference chunk handle.

	;
	; Source in es:di now, destination in ds:si.  Swap registers and copy.
	;
	mov	ax, es			;
	segmov	es, ds
	mov	ds, ax
	xchg	si, di
DBCS <	shr	cx, 1							>
	LocalCopyNString		; rep movsb/movsw
	;
	; Unlock the resource.
	;
	call	UnlockStrings		; Unlock the resource.
	.leave
	ret
SetResourceString	endp

ObscureInitExit	ends



COMMENT @----------------------------------------------------------------------

ROUTINE:	DateTimeInitFormats

SYNOPSIS:	Initializes any user-defined formats.

CALLED BY:	LocalInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/12/9		Initial version

------------------------------------------------------------------------------@

ObscureInitExit	segment resource

DateTimeInitFormats	proc	near
	sub	sp, (DATE_TIME_FORMAT_SIZE+1)/2*2 ; leave room for format string
	mov	di, sp				; have di point to format buffer
	segmov	es, ss				; have es point to format buffer

	mov	si, DateTimeFormat-1		; do all the formats
doFormat:
	push	si
	call	SetupFormatParameters		; setup parameters
	mov	bp, DATE_TIME_FORMAT_SIZE	; max size to read in
	call	LocalGetStringAsData		; destroys cx
	pop	si				; restore format
	jc	doNext				; nothing read, go do next one

	push	si
	shl	si, 1				;
	add	si, offset DateLong		;
	call	SetResourceString		; set the resource string
	pop	si
doNext:
	dec	si				; next format
	jns	doFormat			; do another format if not done

	add	sp, (DATE_TIME_FORMAT_SIZE+1)/2*2	; restore stack
	ret
DateTimeInitFormats	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupFormatParameters

SYNOPSIS:	Sets up some stuff for reading and writing to .ini files.

CALLED BY:	DateTimeSetFormat, DateTimeGetFormat

PASS:		es:di	   -- buffer to read from / write to
		si	   -- format to get info for

RETURN:		ds:si	   -- category ASCIIZ string
		cx:dx	   -- key ASCIIZ string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/10/90	Initial version

------------------------------------------------------------------------------@

SetupFormatParameters	proc	near
	;
	; Make sure that the generic format passed is valid.
	;
EC <	cmp	si, DateTimeFormat					>
EC <	ERROR_AE DATE_TIME_ILLEGAL_FORMAT	; Bad format in si.	>
EC <	call	ECDateTimeCheckESDI		; Make sure ptr is OK.	>

	;
	; Figure out what key to set.
	;
	segmov	ds, cs
	assume	ds:ObscureInitExit
	mov	cx, ds
	shl	si, 1				; double for word offset
	mov	dx, ds:formatKeyPointers[si]	; cx:dx holds key
	mov	si, offset localizationCategory	; ds:si holds category string
	ret
SetupFormatParameters	endp
	assume	ds:dgroup


formatKeyPointers	nptr \
	offset	longDate,
	offset	longCondensedDate,
	offset 	longDateNoWeekday,
	offset	longCondensedDateNoWeekday,
	offset	shortDate,
	offset	zeroPaddedShortDate,
	offset	monthDayLongDate,
	offset	monthDayLongDateNoWeekday,
	offset	monthDayShort,
	offset	monthYearLong,
	offset	monthYearShort,
	offset	yearStr,
	offset	month,
	offset	dayStr,
	offset	weekday,
	offset	hoursMinsSecsTime,
	offset	hoursMinsTime,
	offset	hoursTime,
	offset	minsSecsTime,
	offset	hoursMinsSecs24HourTime,
	offset	hoursMins24HourTime
CheckHack <(length formatKeyPointers) eq (DateTimeFormat)>

localizationCategory		char	"localization",0
longDate			char	"longDate", 0
longCondensedDate		char	"longCondensedDate",0
longDateNoWeekday		char	"longDateNoWeekday",0
longCondensedDateNoWeekday	char	"longCondensedDateNoWeekday",0
shortDate			char	"shortDate",0
zeroPaddedShortDate		char	"zeroPaddedShortDate",0
monthDayLongDate		char	"monthDayLongDate",0
monthDayLongDateNoWeekday	char	"monthDayLongDateNoWeekday",0
monthDayShort			char	"monthDayShort",0
monthYearLong			char	"monthYearLong",0
monthYearShort			char	"monthYearShort",0
yearStr				char	"year",0
month				char	"month",0
dayStr				char	"day",0
weekday				char	"weekday",0
hoursMinsSecsTime		char	"hoursMinsSecsTime",0
hoursMinsTime			char	"hoursMinsTime",0
hoursTime			char	"hoursTime",0
minsSecsTime			char	"minsSecsTime",0
hoursMinsSecs24HourTime		char	"hoursMinsSecs24HourTime",0
hoursMins24HourTime		char	"hoursMins24HourTime",0

ObscureInitExit	ends

idata	segment
	localTimezone	sword		-8*60
	localDST	BooleanByte	FALSE
idata	ends

Format segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the timezone information

CALLED BY:	(GLOBAL)
PASS:		none
RETURN:		ax - offset to GMT
		bl - TRUE if offset adjusted for Daylight Savings Time
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalGetTimezone	proc	far
		uses	ds
		.enter

		LoadVarSeg ds
		mov	ax, ds:localTimezone		;ax <- offset to GMT
		mov	bl, ds:localDST			;bl <- DST adjusted

		.leave
		ret
LocalGetTimezone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalCompareDateTimes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two normalized date/times

CALLED BY:	(GLOBAL)
PASS:		ds:si - ptr to TimerDateAndTime #1
		es:di - ptr to TimerDateAndTime #2
RETURN:		flags set for cmp #1, #2
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	compare date/times in decreasing order of significance:
		year
		month
		day
		hour
		minute
		seconds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/21/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalCompareDateTimes	proc	far
		uses	cx, si, di
		.enter

	;
	; for ease of coding, we compare TDAT_dayOfWeek after TDAT_day
	; which is OK as they should be equal if and only if TDAT_day
	; is equal, too, if the year and month were also equal.
	; Assuming they were normalized correctly, of course...
	;
		mov	cx, (size TimerDateAndTime)/(size word)
		repe	cmpsw

	CheckHack <offset TDAT_year eq 0>
	CheckHack <(offset TDAT_month) eq (offset TDAT_year)+(size word)>
	CheckHack <(offset TDAT_day) eq (offset TDAT_month)+(size word)>
	CheckHack <(offset TDAT_dayOfWeek) eq (offset TDAT_day)+(size word)>
	CheckHack <(offset TDAT_hours) eq (offset TDAT_dayOfWeek)+(size word)>
	CheckHack <(offset TDAT_minutes) eq (offset TDAT_hours)+(size word)>
	CheckHack <(offset TDAT_seconds) eq (offset TDAT_minutes)+(size word)>
	CheckHack <(size TimerDateAndTime) eq 14>

		.leave
		ret
LocalCompareDateTimes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalNormalizeDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize a date/time, i.e., convert to GMT

CALLED BY:	(GLOBAL)
PASS:		ds:si - ptr to src TimerDateAndTime
		es:di - ptr to dest TimerDateAndTime
		ax - offset to GMT
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:
	NOTE: es:di = ds:si is OK, i.e., in place conversion is OK

PSEUDO CODE/STRATEGY:
	We use byte-sized math where ever possible (months, days, hours,
	and minutes) to save on code size.

	seconds = seconds
	minutes += timezone%60
	hours += timezone/60 + borrow
	days += borrow
	months += borrow
	years += borrow

	At each stage, if the result wraps below the minimum value, we
	adjust the value to be within range and 'borrow' -1 at the next
	stage. If the result wraps above the maximum value, we adjust the
	value to be within range and 'borrow' +1 at the next stage.

	Note that on 12/31 or 1/1, depending on the time and timezone, the
	adjustment can ripple through minutes, hours, the day, the month and
	the year.

	NOTE: this routine is optimized for small size first, speed second.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/21/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalNormalizeDateTime	proc	far
		uses	ax, bx, cx, dx
		.enter

	;
	; convert the offsetGMT into hours (/60) and minutes (%60)
	;
		mov	cl, 60				;cl <- 60
		idiv	cl				;al <- tz/60,ah <- tz%60
		mov	bl, al				;bl <- tz/60
	;
	; minutes = minutes - timezone%60
	;
doMinutes::
		mov	al, {byte}ds:[si].TDAT_minutes	;al <- minutes
		sub	al, ah				;al <- minutes - tz%60
		mov	cx, 59 or (0 shl 8)		;cl <- max, ch <- min
		call	doNormalization
		mov	es:[di].TDAT_minutes, ax
	;
	; hours = hours - timezone/60 + borrow
	;
doHours::
		mov	al, {byte}ds:[si].TDAT_hours	;al <- hours
		sub	al, bl				;al <- hours -= tz/60
		add	al, dl				;al <- hours += borrow
		mov	cx, 23 or (0 shl 8)		;cl <- max, ch <- min
		call	doNormalization
		mov	es:[di].TDAT_hours, ax
	;
	; days = days + borrow
	;
doDay::
		mov	ax, ds:[si].TDAT_year		;ax <- year
		mov	bl, {byte}ds:[si].TDAT_month	;bl <- month
		call	LocalCalcDaysInMonth
		mov	cl, ch				;cl <- days in month
		mov	ch, 1				;ch <- min
		mov	al, {byte}ds:[si].TDAT_day	;al <- day
		add	al, dl				;al <- day += borrow
		cmp	al, 1
		jl	dayBM1				;branch if <1
		call	doNormalization
doneDay:
		mov	es:[di].TDAT_day, ax
	;
	; month = month + borrow
	;
doMonth::
		mov	al, {byte}ds:[si].TDAT_month	;al <- month
		add	al, dl				;al <- month += borrow
		mov	cx, 12 or (1 shl 8)		;cl <- max, ch <- min
		call	doNormalization
		mov	es:[di].TDAT_month, ax
	;
	; year = year + borrow
	;
doYear::
		mov	al, dl				;al <- borrow
		cbw					;ax <- borrow
		add	ax, ds:[si].TDAT_year		;ax <- year += borrow
		mov	es:[di].TDAT_year, ax
	;
	; copy seconds -- no adjustment needed
	;
		mov	ax, ds:[si].TDAT_seconds
		mov	es:[di].TDAT_seconds, ax
	;
	; calculate the new day of the week; it's easier than adjusting
	; as we'd need to check for it wrapping, too.
	;
doDOW::
		mov	ax, es:[di].TDAT_year		;ax <- year
		mov	bl, {byte}es:[di].TDAT_month	;bl <- month
		mov	bh, {byte}es:[di].TDAT_day	;bh <- day
		call	LocalCalcDayOfWeek		;cl <- day of week
		clr	ch
		mov	es:[di].TDAT_dayOfWeek, cx
done::

		.leave
		ret

	;
	; Pass:
	;	al - value
	;	cl - maximum
	;	ch - minimum
	; Return:
	;	al - adjusted value
	;	dl - borrow
	;
doNormalization:
		clr	dl				;dl <- assume no borrow
		cmp	al, ch				;<min?
		jge	dnMinOK				;branch if >= min
		dec	dl				;dl <- borrow -1
		sub	cl, ch				;cl <- range-1
		inc	cl				;cl <- range
		add	al, cl
		jmp	dnMaxOK
dnMinOK:
		cmp	al, cl				;>max?
		jle	dnMaxOK				;branch if <= max
		inc	dl				;dl <- borrow +1
		sub	cl, ch				;cl <- range-1
		inc	cl				;cl <- range
		sub	al, cl
dnMaxOK:
		clr	ah
		retn

	;
	; days < 1; add days in *previous* month and subtract 1 month
	;
dayBM1:
		mov	dl, -1				;dl <- borrow -1 month
	;
	; get the days in the previous month, taking care to wrap the month
	; as needed
	;
		push	ax
		mov	ax, ds:[si].TDAT_year		;ax <- year
		mov	bl, {byte}ds:[si].TDAT_month	;bl <- month
		dec	bl				;bl <- month - 1
		jnz	gotPrevMonth
		mov	bl, 12
		dec	ax
gotPrevMonth:
		call	LocalCalcDaysInMonth		;ch <- days in prev. mth
		pop	ax
		add	al, ch				;al <- += days prev. mth
		clr	ah				;ax <- day
		jmp	doneDay
LocalNormalizeDateTime	endp

Format ends


ObscureInitExit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalSetTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the timezone information

CALLED BY:	(GLOBAL)
PASS:		ax - offset to GMT
		bl - TRUE if offset adjusted for Daylight Savings Time
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

timezoneKey	char "timezone", 0
dstKey		char "useDST", 0

LocalSetTimezone	proc	far
		uses	cx, dx, bp, ds, si
		.enter

	;
	; store the timezone info
	;
		LoadVarSeg ds, cx
		mov	ds:localTimezone, ax
		mov	ds:localDST, bl
	;
	; save it in the INI file
	;
		segmov	ds, cs, cx
		mov	si, offset localizationCategory	;ds:si <- category
		mov	dx, offset timezoneKey		;cx:dx <- key
		mov	bp, ax				;bp <- offset GMT
		call	InitFileWriteInteger
		clr	ax
		mov	al, bl				;ax <- use DST value
		mov	dx, offset dstKey		;cx:dx <- key
		call	InitFileWriteBoolean

		.leave
		ret
LocalSetTimezone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the timezone information

CALLED BY:	(GLOBAL)
PASS:		none
RETURN:		none
DESTROYED:	ax, bx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/11/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitTimezone	proc	near
		uses	si, cx, dx
		.enter

		segmov	ds, cs, cx
		mov	si, offset localizationCategory
		mov	dx, offset timezoneKey
		mov	ax, -8*60			;ax <- assume PST
		call	InitFileReadInteger

		push	ax
		mov	dx, offset dstKey
		mov	ax, FALSE			;ax <- assume no DST
		call	InitFileReadBoolean
		mov	bl, al
		ornf	bl, ah				;bl <- zero/non-zero
		pop	ax
		LoadVarSeg ds, cx
		mov	ds:localTimezone, ax		;store offset GMT
		mov	ds:localDST, bl			;store DST
 
		.leave
		ret
InitTimezone	endp

ObscureInitExit ends
