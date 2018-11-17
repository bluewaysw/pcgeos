COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Timer
FILE:		timerMisc.asm

ROUTINES:
	Name				Description
	----				-----------
   GLB	TimerGetCount			Return system time counter
   GLB	TimerGetDateAndTime		Get system time and date
   GLB	TimerSetDateAndTime		Set system time and date

   EXT	RestoreMSDOSTime		Restore MS-DOS's notion of time

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This file handles timer interrupts

	$Id: timerMisc.asm,v 1.2 98/05/02 22:15:10 gene Exp $

-------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TimerGetCount

C DECLARATION:	extern dword
			_far _pascal TimerGetCount();

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TIMERGETCOUNT	proc	far
	call	TimerGetCount
	mov	dx, bx
	ret

TIMERGETCOUNT	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerGetCount

DESCRIPTION:	Return system time counter which contains the number of ticks
		since PC GEOS started.

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ax - low word of system time counter
	bx - high word of system time counter

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
-------------------------------------------------------------------------------@

TimerGetCount	proc	far
	push	ds
	LoadVarSeg	ds
	INT_OFF
	mov	ax,ds:[systemCounter.low]
	mov	bx,ds:[systemCounter.high]
	INT_ON
	pop	ds
	ret

TimerGetCount	endp

FileCommon	segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerGetDateAndTime

DESCRIPTION:	Get the current date and time.

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ax - year (1980 through 2099)
	bl - month (1 through 12)
	bh - day (1 through 31)
	cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
	ch - hours (0 through 23)
	dl - minutes (0 through 59)
	dh - seconds (0 through 59)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

TimerGetDateAndTime	proc	far
	push	ds
	LoadVarSeg	ds, ax
	INT_OFF

	;
	; Call DOS to get the time now, since we may have been task switched
	; for an indeterminate length of time. Actually, there is no need
	; to do this, as the task switch driver can do the right things
	; (i.e. call DOS and call TimerSetDateAndTime) to restore the time
	; and the code to reload the time & date from DOS open up a
	; synchronization hole. -Don 3/4/00
	;
	; Since there is no task-switch driver for running under Windows,
	; we'll go ahead and leave the old version in for everything but
	; GPC. -Don 3/18/00
	;
ifdef	GPC
	mov	ax, ds:[years]
	mov	bx, {word} ds:[months]
	mov	cx, {word} ds:[dayOfWeek]
	mov	dx, {word} ds:[minutes]
else
	mov	ah,MSDOS_GET_TIME		;get time
	call	FileInt21
	mov	ds:[hours],ch
	mov	ds:[minutes],cl
	mov	ds:[seconds],dh

	mov	ah, MSDOS_GET_DATE		;get date
	call	FileInt21
	mov	ds:[years], cx
	mov	ds:[months], dh
	mov	ds:[days], dl
	mov	ds:[dayOfWeek], al

	mov_tr	ax, cx				; ds:[years]
	mov	bx, dx				; word ptr ds:[months]
	xchg	bh, bl				; DOS gets 'em backwards.
	mov	cx,word ptr ds:[dayOfWeek]
	mov	dx,word ptr ds:[minutes]
endif

	INT_ON
	pop	ds
	ret
TimerGetDateAndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIMERGETFILEDATETIME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the current date and time into two 16-bit records
		(FileDate and FileTime)

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ax	= FileDate
		dx	= FileTime
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/4/92		Stolen from primary IFS drivers (hence the
				formatting)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIMERGETFILEDATETIME	proc	far
		uses	cx, bx
		.enter
		call	TimerGetDateAndTime
	;
	; Create the FileDate record first, as we need to use CL to the end...
	; 
		sub	ax, 1980	; convert to fit in FD_YEAR
			CheckHack <offset FD_YEAR eq 9>
		mov	ah, al
		shl	ah		; shift year into FD_YEAR
		mov	al, bh		; install FD_DAY in low 5 bits
		
		mov	cl, offset FD_MONTH
		clr	bh
		shl	bx, cl		; shift month into place
		or	ax, bx		; and merge it into the record
		xchg	dx, ax		; dx <- FileDate, al <- minutes,
					;  ah <- seconds
		xchg	al, ah
	;
	; Now for FileTime. Need seconds/2 and both AH and AL contain important
	; stuff, so we can't just sacrifice one. The seconds live in b<0:5> of
	; AL (minutes are in b<0:5> of AH), so left-justify them in AL and
	; shift the whole thing enough to put the MSB of FT_2SEC in the right
	; place, which will divide the seconds by 2 at the same time.
	; 
		shl	al
		shl	al		; seconds now left justified
		mov	cl, (8 - width FT_2SEC)
		shr	ax, cl		; slam them into place, putting 0 bits
					;  in the high part
	;
	; Similar situation for FT_HOUR as we need to left-justify the thing
	; in CH, so just shift it up and merge the whole thing.
	; 
		CheckHack <(8 - width FT_2SEC) eq (8 - width FT_HOUR)>
		shl	ch, cl
		or	ah, ch
		xchg	dx, ax		; ax <- date, dx <- time
					;  (corresponds to C FileDateAndTime
					;  declaration, ya know)
		.leave
		ret
TIMERGETFILEDATETIME	endp

FileCommon ends

Filemisc segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerSetDateAndTime

DESCRIPTION:	Set the current date and/or time.

CALLED BY:	GLOBAL

PASS:
	ax - year (1980 through 2099)
	bl - month (1 through 12)
	bh - day (1 through 31)
	cl - flags:
		bit 7 - set to store year, month, day (SDTP_SET_DATE)
		bit 6 - set to store hour, minute, second (SDTP_SET_TIME)
		bit 5 - set to not update DOS time, just ours
	ch - hours (0 through 23)
	dl - minutes (0 through 59)
	dh - seconds (0 through 59)

RETURN:
	ax, bx, cx, dx - destroyed

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@


TimerSetDateAndTime	proc	far
	uses	si, di, bp, ds
	.enter

	LoadVarSeg	ds
	INT_OFF

	push	cx			; save SDTP flags

CheckHack <offset SDTP_SET_DATE eq 7>
CheckHack <offset SDTP_SET_TIME eq 6>

	shl	cl,1			; CF <- set date?, SF <- set time?
	jns	notTime

EC <	pushf					;>
EC <	cmp	ch, 23				;>
EC <	ERROR_A	TIMER_BAD_HOUR			;>
EC <	cmp	dl, 59				;>
EC <	ERROR_A	TIMER_BAD_MINUTE		;>
EC <	cmp	dh, 59				;>
EC <	ERROR_A	TIMER_BAD_SECOND		;>
EC <	popf					;>

	mov	ds:[hours], ch
	mov	{word}ds:[minutes], dx
notTime:
	jnc	done

EC <	cmp	ax, 1980			;>
EC <	ERROR_B	TIMER_BAD_YEAR			;>
EC <	cmp	ax, 2099			;>
EC <	ERROR_A	TIMER_BAD_YEAR			;>
EC <	cmp	bl, 1				;>
EC <	ERROR_B	TIMER_BAD_MONTH			;>
EC <	cmp	bl, 12				;>
EC <	ERROR_A	TIMER_BAD_MONTH			;>
EC <	cmp	bh, 1				;>
EC <	ERROR_B	TIMER_BAD_DAY			;>
EC <	cmp	bh, 31				;>
EC <	ERROR_A	TIMER_BAD_DAY			;>
	mov	ds:[years],ax
	mov	word ptr ds:[months],bx
	call	CalcDayOfWeek
	mov	ds:[dayOfWeek],ah

done:
	;
	; Check the RealTimeTimerList for events to deliver
	;
	call	CheckRealTimeTimersFar

	;
	; For all machines with a RTC, we'd better reset the clock so
	; that alarms will go off at the correct time
	;
	pop	cx
	push	cx
	test	cl, TIME_SET_GEOS_TIME_ONLY
	jnz	noDOSUpdate
	call	RestoreMSDOSTime	; reset DOS date and time
					; NOTE: this leaves interrupts on
noDOSUpdate:
	INT_ON

	;
	; Now tell the world we've changed the date and/or time.
	; 
	mov	ax, MSG_NOTIFY_DATE_TIME_CHANGE
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	si, GCNSLT_DATE_TIME
	pop	cx		; Note: cx=SDTP is not in MSG_NOTIFY API
	clr	di
	call	GCNListRecordAndSend

	.leave
	ret
TimerSetDateAndTime	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CalcDayOfWeek

DESCRIPTION:	Figure the day of the week given its absolute date.

CALLED BY:	INTERNAL
		TimerSetDateAndTime

PASS:
	ax - year (1980 through 2099)
	bl - month (1 through 12)
	bh - day (1 through 31)

RETURN:
	ah - day of the week

DESTROYED:
	ax, bx, cx, dh

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

CalcDayOfWeek	proc	near	uses ds
	.enter

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
	div	bl

	.leave
	assume	ds:dgroup
	ret

CalcDayOfWeek	endp

Filemisc	ends


COMMENT @-----------------------------------------------------------------------

FUNCTION:	IncrementTime

DESCRIPTION:	Called every second to increment system time and date

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	none

RETURN:
	carry - set if a minute has passed

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine is only valid for years from 1901 to 2099, due
	to the way leap years are calculated

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

woofWoof	label	near
	;
	; The system is hung trying to exit. Switch the video back to text
	; mode so we can display the message we need to display, then shut
	; loop forever.
	; 
	LoadVarSeg	ds
	clr	ax			; set mode 0
	int	10h
	mov	ds, ds:[fixedStringsSegment]
	assume	ds:FixedStrings
	mov	si, ds:[unableToExit]
	clr	bx			; page 0
woofLoop:
	lodsb
	tst	al
	jz	woofLoopForever
	mov	ah, 0eh
	int	10h
	jmp	woofLoop

woofLoopForever:
	jmp	woofLoopForever

	assume	ds:dgroup

IncrementTime	proc	near

	clr	al

	dec	ds:[watchdogTimer]
	jg	afterWatchdog
	je	woofWoof
	mov	ds:[watchdogTimer], al

afterWatchdog:
	; bump seconds

	inc	ds:[seconds]
	cmp	ds:[seconds],60
	clc				;return carry clear if
	jnz	exit			;a minute hasn't passed
	mov	ds:[seconds],al

	; bump minutes

	inc	ds:[minutes]
	cmp	ds:[minutes],60
	jnz	done
	mov	ds:[minutes],al

	; bump hours

	mov	ds:[ticks],INTERRUPT_RATE-3
					;tweak tickCount to keep clock accurate

if	 GULLIVER_COMMON
	; Read the RTC every hour.  If the RTC wasn't available (was
	; doing an update), then we just do it the old way with the idea
	; that it will be accessible the next time around.  Carry is clear
	; if the time/date were set successfully.  Even though we adjusted
	; the value of TIMER_UNITS_PER_SECOND, the 8254 still comes out a
	; little off.
	;
    	call	SetTimeFromRTC
	jnc	done
endif	;GULLIVER_COMMON

	inc	ds:[hours]
	cmp	ds:[hours],24
	jnz	done
	mov	ds:[hours],al

	; bump dayOfWeek

	inc	ds:[dayOfWeek]
	cmp	ds:[dayOfWeek],7
	jnz	noMonday
	mov	ds:[dayOfWeek],al
noMonday:

	; bump days

	mov	ah,ds:[days]
	inc	ds:[days]
	mov	bl,ds:[months]
	cmp	bl,2			;February ?
	jnz	notFeb
	test	byte ptr ds:[years],00000011b	;leap year ?
	jnz	notFeb
	dec	ah			;LEAP YEAR!!! Do it right!!!
notFeb:
	clr	bh
	cmp	ah,cs:[bx][daysPerMonth-1]
	jb	done
	inc	al			;days wrap to 1
	mov	ds:[days],al

	; bump months

	inc	ds:[months]
	cmp	ds:[months],13
	jnz	done
	mov	ds:[months],al

	; bump years

	inc	ds:[years]


done:
	call	CheckRealTimeTimers	;a minute has passed, so go check
					;for a real-time timer expiration?
	stc				;a minute has passed
exit:
	ret
IncrementTime	endp

daysPerMonth	label	byte
	byte	31		;January
	byte	28		;Feburary
	byte	31		;March
	byte	30		;April
	byte	31		;May
	byte	30		;June
	byte	31		;July
	byte	31		;August
	byte	30		;September
	byte	31		;October
	byte	30		;November
	byte	31		;December


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTimeFromRTC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets GEOS's time from the RTC.  Only used by Gulliver.

CALLED BY:	IncrementTime

PASS:		ds	= kdata

RETURN:		carry	= set: RTC was in update, could not set our clock
			  clear: time and date were set successfully

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Uses GetTimeDateFromRTC to read the RTC directly.  Look there
	for more details.
		
	Try to keep this routine as fast as possible since it is called
	from the TimerInterrupt routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn HARDWARE_TYPE, <GULLIVER>

SetTimeFromRTC	proc	near
	uses	ax,bx,cx,dx
	.enter
	
	call	GetTimeDateFromRTC
	jc	done				; couldn't read RTC, wait..
	
	;	al	= seconds
	;	ah	= minutes
	;	cl	= hours
	;	ch	= days
	;	dl	= months
	;	bx	= years
	
	mov	ds:[seconds], al
	mov	ds:[minutes], ah
	mov	ds:[hours], cl
	mov	cl, ds:[days]			; cl = old days
	mov	ds:[days], ch			; ch = new days
	mov	ds:[months], dl
	mov	ds:[years], bx
	
	; We need to see if the day of the week needs changing.  We ASSUME
	; it only needs to be inc'd or dec'd by one since the RTC should be
	; close to our clock.  (For some stupid reason, the RTC doesn't
	; keep the day of the week correct in the RTC...)
	;
	; cl = old days, ch = new days
	
	; cl = (old day of the month) - (new day of the month)
	sub	cl, ch
	jnz	bumpDay
	
doneOK:
	clc
	
done:
	.leave
	ret

bumpDay:
	; cl = (old day of the month) - (new day of the month)
	;
	; We want to increment the day of the week if:
	;	cl = -1	  (old day < new day)
	;	cl > 1	  (old day is end of month, new day is 1, we hope)
	;
	; We want to decrement the day of the week if:
	;	cl = 1	  (old day > new day)
	;	cl < -1	  (old day is 1, new day is end of month, we hope)
	;
	cmp	cl, 1
	je	backUpDay
	cmp	cl, -1
	jl	backUpDay
	
	; OK, inc the day of the week.
	;
	inc	ds:[dayOfWeek]	
	cmp	ds:[dayOfWeek], 7		; Wrap around end of week
	jl	doneOK
	mov	ds:[dayOfWeek], 0
	jmp	doneOK

backUpDay:
	dec	ds:[dayOfWeek]
	jns	doneOK				; Wrap around beginning of
	add	ds:[dayOfWeek], 7		; the week.
	jmp	doneOK
	
SetTimeFromRTC	endp
	
endif ;GULLIVER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTimeDateFromRTC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the time and date from the RTC directly. GULLIVER only.

CALLED BY:	SetTimeFromRTC
		RTCInterruptHandler

PASS:		nothing

RETURN:		carry	= set: RTC was in update, could not read
				ax destroyed
				bx, cx, dx preserved
			  clear:
				al	= seconds
				ah	= minutes
				cl	= hours
				ch	= days
				dl	= months
				bx	= years

DESTROYED:	Carry clear: Nothing.  Carry set: AX

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Reads the RTC directly because, looking at the BIOS call, it
	would essentially WAIT for the RTC to be available by looping
	64K times reading the RTC register A (which contains an update-in-
	progress bit) until it was not in the middle of an update.
	All the while it is doing that, it turns interrupts back on.
	We don't really want to do this since this is probably being
	called from within TimerInterrupt.  So we just simply check
	to see if the thing is in the middle of an update ONCE and if so, we
	just return that status.  The user can try again later.
		
	Try to keep this routine as fast as possible since it is called
	from the TimerInterrupt every minute.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn HARDWARE_TYPE, <GULLIVER>
.186

GetTimeDateFromRTC	proc	near
	uses	bp
	.enter
	
	; Check if we can access the RTC's time and date variables.  If this
	; update-in-progress bit is set, then we cannot do it now.
	
	mov	al, TIMER_RTC_REG_A or 80h	; disable NMI
	out	TIMER_RTC_INDEX_REGISTER, al
	in	al, TIMER_RTC_DATA_REGISTER
	test	al, TIMER_RTC_REGA_UPDATE
	stc					; notify caller
	jnz	done
	
	; If the update bit was clear above, we are guarenteed to have 244
	; microseconds (about 6000 cycles) to read the RTC.
	
;;;; BEGIN 244 microsecond run -- only essential code relating to reading
;;;; RTC in this section.

	; Disable interrupts just in case we were called from somewhere
	; else.  We don't want to be interrupted while we read these values
	; since we only have 244 microseconds to do so.
	;
	pushf	
	INT_OFF
	
	mov	al, TIMER_RTC_REG_SECONDS
	call	ReadRTCRegToBinary
	mov	cl, al
	
	mov	al, TIMER_RTC_REG_MINUTES
	call	ReadRTCRegToBinary
	mov	ch, al
	
	mov	bp, cx				; store min:sec in bp
	
	mov	al, TIMER_RTC_REG_HOURS
	call	ReadRTCRegToBinary
	mov	cl, al
	
	mov	al, TIMER_RTC_REG_DAY
	call	ReadRTCRegToBinary
	mov	ch, al
	
	mov	al, TIMER_RTC_REG_MONTH
	call	ReadRTCRegToBinary
	mov	dl, al
	
	clr	bx
	mov	al, TIMER_RTC_REG_YEAR
	call	ReadRTCRegToBinary
	mov	bl, al				; bx = year (full year mod 100)
	
;;;; END 244 microsecond run.  The century byte is not really technically
;;;; part of the RTC and it is maintained by our BIOS but not by the RTC
;;;; part itself.
	
	mov	al, TIMER_RTC_REG_CENT
	call	ReadRTCRegToBinary		; ax = century (ah clear)
	
	; Restore interrupts, however they were.
	;
	popf
	
	; bx = year mod 100, ax = century.
	shl	ax, 2				; ax = cent * 4
	add	bx, ax				; bx = cent * 4 + year
	shl	ax, 3				; ax = cent * 32
	add	bx, ax				; bx = cent * 36 + year
	shl	ax, 1				; ax = cent * 64
	add	bx, ax				; bx = cent * 100 + year
						;    = full years
	
	mov	ax, bp				; restore min:sec in ax
	
	; al = seconds, ah = minutes
	; bx = years
	; cl = hours, ch = days
	; dl = months
	
	clc					; we read the RTC successfully

done:
	.leave
	ret
GetTimeDateFromRTC	endp

	
;	Pass:	al	= RTC register
;	Return:	al	= Binary value
;		ah	= 0
;
ReadRTCRegToBinary	proc	near
	or	al, 80h				; disable NMI
	out	TIMER_RTC_INDEX_REGISTER, al
	in	al, TIMER_RTC_DATA_REGISTER
	
	; Convert BCD to binary
	clr	ah
	shl	ax, 4
	shr	al, 4
	
	;  (On a 386, aad is 2 bytes, 19 cycles.  Slightly slower than the
	;	move, shift, add counterpart, but smaller.)
	aad
	ret
ReadRTCRegToBinary	endp

.8086
endif ;GULLIVER



COMMENT @-----------------------------------------------------------------------

FUNCTION:	RestoreMSDOSTime

DESCRIPTION:	Restore MS-DOS's notion of time

CALLED BY:	INTERNAL
		FileCreateTempFileLow, EndGeos

PASS:
	dosSem P'd

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

RestoreMSDOSTime	proc	far
	call	PushAll

	LoadVarSeg	ds
	tst	ds:timerInitialized
	jz	notInitialized

	; read all of the variables together to ensure consistency

	INT_OFF
	mov	si,ds:[years]
	mov	bh,ds:[months]
	mov	bl,ds:[days]

	mov	dl,ds:[hundredCount]		; increment hundredths count
	inc	dl				; ...to ensure the MS-DOS
	cmp	dl,100				; ...create temp file works
	jnz	10$
	clr	dl
10$:
	mov	ds:[hundredCount],dl
	mov	dh,ds:[seconds]
	mov	ch,ds:[hours]
	mov	cl,ds:[minutes]
	INT_ON

	; now write the settings back to DOS

	call	SysLockBIOS
	mov	ah,MSDOS_SET_TIME
	int	21h
EC <	tst	al							>
EC <	ERROR_NZ BAD_MSDOS_TIME_SET					>

	mov	ah,MSDOS_SET_DATE
	mov	cx, si				; years -> cx
	mov	dx, bx				; month/days => dx
	int	21h
EC <	tst	al							>
EC <	ERROR_NZ BAD_MSDOS_DATE_SET					>
	call	SysUnlockBIOS

notInitialized:
	call	PopAll
	ret
RestoreMSDOSTime	endp
