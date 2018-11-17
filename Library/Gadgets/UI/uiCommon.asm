COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Jedi
MODULE:		Gadgets Library
FILE:		uiCommon.asm

AUTHOR:		Jacob A. Gabrielson, Jan 11, 1995

ROUTINES:
	Name			Description
	----			-----------
    EXT ObjCallControlChild     Calls a child of a control object.

    EXT GetChildBlock           Get block containing child.

    EXT GetChildBlockAndFeatures 
				Name says it all.

    EXT SetDate                 Copies the date (in ax,bx,cl) to a
				DateStruct pointed to by ds:di.

    EXT GetDate                 Copies the date from a DateStruct pointed
				to by ds:di to ax, bx, cx and dx.

    EXT StrCopy                 Copy a string from ds:si (source) to es:di
				(destination).

    EXT StrCat                  Concatenates string at ds:si (source) to
				the string at es:di (destination).

				NOTE: Make sure that es:di (destination) is
				big enough to hold the new string.

    EXT GetSystemTimeSeparator  Returns the system Time seperator.

    EXT AddSelfToDateTimeGCNLists 
				Add this controller to the GCN list for
				date/time format changes.

    EXT RemoveSelfFromDateTimeGCNLists 
				Remove us from any GCN lists we were on.

    EXT CopyBuildInfoCommon     Copies GenControlBuildInfoStruct

    EXT LockStringResource      Locks a string resource and returns a
				pointer to the string

    EXT UnlockStringResource    Unlocks a string resource that was locked
				using LockStringResource

    INT IncrementTime           Increments the time by a given value.

    INT DecrementTime           Decrements the time by a given value.

    EXT DecrementDate           Decrement the date by one.

    EXT IncrementDate           Increments the date by one.

    EXT IncrementWeek           Increments the date by one week (that's
				seven days)

    EXT IncrementMonth          Decrements the current month by 1. The day
				will be set to 1.  The day of week will be
				invalid.

    EXT DecrementYear           Decrements the year by one.  The date is
				set to 01.01 and the week day is invalid.

    EXT IncrementYear           Increments the year by one.  The date is
				set to 01.01 and the week day is invalid.

    EXT DecrementWeek           Decrements the date by one week (seven
				days)

    EXT DecrementMonth          Decrements the current month by 1. The day
				will be set to 1.  The day of week will be
				invalid.

    EXT CalcDayOfWeek           Figure the day of the week given its
				absolute date.

    EXT GetWeekNumber           Calculates the week number given a date

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/11/95   	Initial revision


DESCRIPTION:
	Routines used by more than one of the different controllers.
		

	$Id: uiCommon.asm,v 1.1 97/04/04 17:59:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjCallControlChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls a child of a control object.

CALLED BY:	(EXTERNAL) DIMetaGainedFocusExcl, DIMetaTextLostFocus,
		DIParseDateString, DISelectAllText,
		DISpecActivateObjectWithMnemonic, DateAutoCompletion,
		DateInputGenerateUI, DateInputUpdateText, ReplaceDateText,
		ReplaceTIText, SetIncDecTriggersNotUsable,
		TIMetaGainedFocusExcl, TIMetaTextLostFocus,
		TIParseTimeString, TISelectAllText, TISetAMPMMode,
		TISpecActivateObjectWithMnemonic, TimeInputGenerateUI,
		TimerUpdateText
PASS:		*ds:si     = control object
		ax	   = message
		di	   = destination (child) object offset
		cx, dx, bp = data
RETURN:		bx	   = child's block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjCallControlChild	proc	far
		uses	di, si
		.enter
		
EC <		call	ECCheckObject					>
	;
	; Send the message to the controller object. 
	;
		call	GetChildBlock	; bx <- handle
		tst	bx
		jz	noChild

		mov	si, di
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx <- length
noChild:
		.leave
		ret
ObjCallControlChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get block containing child.

CALLED BY:	(EXTERNAL) ObjCallControlChild
PASS:		*ds:si	= controller object
RETURN:		bx	= handle of block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlock	proc	far
		uses	ax
		.enter

		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	bx, ds:[bx].TGCI_childBlock

		.leave
		ret
GetChildBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all. 

CALLED BY:	(EXTERNAL) DateInputGenerateUI DateSelectorGenerateUI
		SetGenTextDefaultWidth SetTextFrame TimeInputGenerateUI
		TimerGenerateUI
PASS:		*ds:si	= controller object
RETURN:		ax	= features
		bx	= handle of block containing child
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlockAndFeatures	proc	far
		.enter
		
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	ax, ds:[bx].TGCI_features
		mov	bx, ds:[bx].TGCI_childBlock

		.leave
		ret
GetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the date (in ax,bx,cl) to a DateStruct
		pointed to by ds:di.

CALLED BY:	(EXTERNAL) DIDateInputSetCurrentDate DIParseDateString
		DISetDate DSSetDateForReal DateSelectorGenerateUI
PASS:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ds:di - ptr to DateStruct
RETURN:		nothing	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDate	proc	far
		mov	ds:[di].DT_year,    ax
		mov	ds:[di].DT_month,   bl
		mov	ds:[di].DT_day,     bh
		mov	ds:[di].DT_weekday, cl
		ret
SetDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the date from a DateStruct pointed to by 
		ds:di to ax, bx, cx and dx.

CALLED BY:	(EXTERNAL) DIGetDate DSGetDate DateInputUpdateText
		DateSelectorSetYearText SendDIActionMessage
		SendDSActionMessage UpdateDateText UpdateShortMonthText
		UpdateWeekText UpdateYearText
PASS:		ds:di - ptr to DateStruct
RETURN:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ch - 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDate		proc	far
		mov	ax, ds:[di].DT_year
		mov	bl, ds:[di].DT_month
		mov	bh, ds:[di].DT_day
		mov	cl, ds:[di].DT_weekday
		clr	ch
		ret
GetDate		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string from ds:si (source) to es:di (destination).  

CALLED BY:	(EXTERNAL) ConvertTextToNumber
PASS:		ds:si	- Source
		es:di	- Destination
		cx	- String length (0 if null terminated)		

RETURN:		es:di	- Copy of ds:si

DESTROYED:	cx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StrCopy	proc	far
	uses	si, di	
	.enter

EC <	cmp	cx, 256	>
EC <	ERROR_A -1      >

	cmp	cx, 0
	jne	notNullTerminated

	;
	; get size of source string    es:di = string pointer
	;
	segxchg	es, ds			; switch pointers to call
	xchg	di, si			; LocalStringSize

	call	LocalStringSize		; cx <- Number of bytes - NULL
	inc	cx			; also copy null

	segxchg	es, ds			; switch pointers back
	xchg	di, si

notNullTerminated:

	;
	; move bytes
	;
	rep	movsb

	.leave
	ret
StrCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrCat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Concatenates string at ds:si (source) to the string at 
		es:di (destination).

		NOTE: Make sure that es:di (destination) is big enough to
		      hold the new string.

CALLED BY:	(EXTERNAL) AppendText AppendZero DateAutoCompletion
		FormatWeek PrependText StopwatchFormatText

PASS:		ds:si	- Source
		es:di	- Destination
		cx	- number of char to concatenate (0 if null terminated)

RETURN:		es:di	- New string

DESTROYED:	cx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StrCat	proc	far
		uses	si, di
		.enter
	;
	; get the size of the string in es:di
	;
		push	cx			; #1
		call	LocalStringSize		; cx <- Number of bytes - NULL
		add	di, cx			; di <- end of string in es:di
		pop	cx			; #1
		tst	cx
		jnz	notNullTerminated
	;
	; get size of source string    es:di = string pointer
	;
		segxchg	es, ds			; switch pointers to call
		xchg	di, si			; LocalStringSize
		call	LocalStringSize		; cx <- Number of bytes - NULL
		segxchg	es, ds			; switch pointers back
		segxchg	di, si
	
notNullTerminated:
		rep	movsb
	;
	; null terminate the destination string
	;
		mov	{byte} es:[di], C_NULL
	
		.leave
		ret
StrCat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSystemTimeSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the system Time seperator.

CALLED BY:	(EXTERNAL) StopwatchFormatText TimeAutoCompletion
PASS:		nothing
RETURN:		ax	= System time separator
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSystemTimeSeparator	proc	far
		uses	bx, cx, dx, si, di, bp, es
		.enter
	;
	; Get the formatted short time
	;
		clr	cx		; Time = 0:00
		clr	dx
		sub	sp, size DateTimeBuffer
		segmov	es, ss
		mov	di, sp
		mov	si, DTF_HM_24HOUR
		call	LocalFormatDateTime		; es:di <- 0:00
	;
	; The third character in this string should be the time separator
	;
		clr	ax
		mov	al, es:[di+1]			; return separator
	;
	; Restore stack
	;
		add	sp, size DateTimeBuffer

		.leave
		ret
GetSystemTimeSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSelfToDateTimeGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add this controller to the GCN list for date/time format
		changes.

CALLED BY:	(EXTERNAL)
PASS:		*ds:si	= controller object (class unimportant)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSelfToDateTimeGCNLists	proc	far
		uses	ax, bx, cx, dx
		.enter
	;
	; Add us to the date/time format change GCN list. 
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; cx:dx <- optr to add
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_INIT_FILE_CHANGE
		call	GCNListAdd

		.leave
		ret
AddSelfToDateTimeGCNLists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveSelfFromDateTimeGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove us from any GCN lists we were on.

CALLED BY:	(EXTERNAL)
PASS:		*ds:si = controller object (class unimportant)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveSelfFromDateTimeGCNLists	proc	far
		uses	ax, bx, cx, dx
		.enter
	;
	; Remove us from the date/time format change GCN list. 
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; cx:dx <- optr to add
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_NOTIFY_INIT_FILE_CHANGE
		call	GCNListRemove

		.leave
		ret
RemoveSelfFromDateTimeGCNLists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyBuildInfoCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies GenControlBuildInfoStruct

CALLED BY:	(EXTERNAL) DateInputGetInfo, DateSelectorGetInfo,
		TimeInputGetInfo, TimerGetInfo
PASS:		cx:dx	= dest
RETURN:		???
DESTROYED:	cx, ds, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsSelectorCode	segment resource
CopyBuildInfoCommon	proc	near
		.enter

		mov	es, cx
		mov	di, dx				;es:di = dest
		segmov	ds, cs			; 
		mov	cx, size GenControlBuildInfo
	rep	movsb

		.leave
		ret
CopyBuildInfoCommon	endp
GadgetsSelectorCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetOutputActionRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_GEN_MAKE_APPLYABLE up the tree, just like
		other Gen gadgets, before calling GenControlOutputActionRegs

CALLED BY:	INTERNAL
PASS:	*ds:si - object
	ax - message
	cx, dx, bp - data
	bx:di - class

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetOutputActionRegs	proc	far
	uses	ax,cx,dx,bp
	.enter

		mov	ax, MSG_GEN_MAKE_APPLYABLE
		call	GenCallParent       ; updates ds
		
	.leave
		call	GenControlSendToOutputRegs
	ret
GadgetOutputActionRegs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockStringResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks a string resource and returns a pointer to the string

CALLED BY:	(EXTERNAL) FormatWeek UpdateShortMonthText

PASS:		si	- Chunk handle of the string

RETURN:		ds:si	- Pointer to string
		ds:LMBH	- Handle of resource

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockStringResource	proc	far
		uses	ax, bx
		.enter

		mov	bx, handle GadgetsStrings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]
		
		.leave
		ret
LockStringResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockStringResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks a string resource that was locked using
		LockStringResource

CALLED BY:	(EXTERNAL) FormatWeek UpdateShortMonthText
PASS:		ds	- Segment of block containing string

RETURN:		Nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockStringResource	proc	far
		uses	bx
		.enter

		mov	bx, ds:LMBH_handle
		call	MemUnlock

		.leave
		ret
UnlockStringResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncrementTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments the time by a given value.

CALLED BY:	(INTERNAL) TITimeIncDec
PASS:		ds:di = ptr to TimeStruct
		cl    = Increment value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Steal from kernel		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncrementTime	proc	far
		uses	ax, dx
		.enter

		clr	al

	;
	; Bump minutes
	;
		add	ds:[di].T_minutes, cl		; increment by amount
		cmp	ds:[di].T_minutes, 60
		jl	done
		mov	dl, ds:[di].T_minutes
		sub	dl, 60
		mov	ds:[di].T_minutes, dl

	;
	; Bump hours
	;
		inc	ds:[di].T_hours
		cmp	ds:[di].T_hours, 24
		jnz	done
		mov	ds:[di].T_hours, al

done:
		.leave
		ret
IncrementTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecrementTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the time by a given value.

CALLED BY:	(INTERNAL) TITimeAltDec TITimeDec
PASS:		ds:di = ptr TimeStruct
		cl    = Value to decrement by
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecrementTime	proc	far
		uses	dx
		.enter
	;
	; sub minutes
	;
		sub	ds:[di].T_minutes, cl		; increment by amount
		cmp	{byte}ds:[di].T_minutes, -1
		jg	done
		mov	dl, 60
		add	dl, ds:[di].T_minutes
		mov	ds:[di].T_minutes, dl
	;
	; sub hours
	;
		dec	ds:[di].T_hours
		cmp	{byte}ds:[di].T_hours, -1	; Is is 12am
		jg	done
		mov	ds:[di].T_hours, 23		; 11pm
done:
		.leave
		ret
DecrementTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncrementOffsetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments a time offset by a given value

CALLED BY:	(INTERNAL) TITimeIncDec
PASS:		ds:di	= ptr to TimeStruct
		cl	= Increment Value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Yes, I know multiply and divides are nasty, but
		I'm thinking that this way produces the smallest
		code and you don't have to worry about the special
		cases.

		- Convert offset to minutes.
		- increment by minutes
		- Convert back to offset

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ACJ	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncrementOffsetTime	proc	far
		uses	ax, bx, cx, dx
		.enter
	;
	; See if we have a negative value.  Use bl as a flag to remember
	; if we have a negative value.
	;
		mov	al, ds:[di].T_hours
		mov	dh, 60
		imul	dh				; ax <- value

		mov	bl, cl				; bl <- increment value
		mov	dh, ds:[di].T_minutes		; make signed byte
		mov	cl, 8				; into signed word
		sar	dx, cl
		
		add	ax, dx				; ax <- number of minutes

	;
	; Make a signed word out of cl into dx.  DX will be
	; increment value
	;
		mov	dh, bl
		sar	dx, cl				; cl=8;

	;
	; AX will contain our total number of minutes
	;
		add	ax, dx
		
	;
	; If we overflowed the number of minutes, let it wrap
	; around
	;
		cmp	ax, 24 * 60
		jl	checkToSmall

		
		sub	ax, 48 * 60
		jmp	short	convertToTimeOffset
checkToSmall:
		cmp	ax, -24 * 60
		jge	convertToTimeOffset

		add	ax, 48 * 60

convertToTimeOffset:
		mov	cl, 60
		idiv	cl			; ax <- quotient
						; dx < remainder
		mov	ds:[di].T_hours, al
		mov	ds:[di].T_minutes, ah
		
		.leave
		ret
IncrementOffsetTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecrementOffsetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the offset time by a certain number of minutes

CALLED BY:	(INTERNAL) TITimeIncDec
PASS:		ds:di	= ptr to TimeStruct
		cl	= Increment Value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ACJ	3/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecrementOffsetTime	proc	far
		uses	cx
		.enter

	;
	; Use the increment offset time routine.
	;
		neg	cl
		call	IncrementOffsetTime

		.leave
		ret
DecrementOffsetTime	endp

CommonCode ends

GadgetsSelectorCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecrementDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the date by one.

CALLED BY:	(EXTERNAL) DIDateDec
PASS:		ds:di	- ptr to DateTimeStruct
RETURN:		Date incremented by one
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecrementDate	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MIN_YEAR
EC <		ERROR_B YEAR_OUT_OF_RANGE				>
		LONG jb	done
		ja	ok
		cmp	ds:[di].DT_month, 1
		ja	ok
		cmp	ds:[di].DT_day, 1
		LONG jna	done
ok:
		clr	al
	;
	; Dec dayOfWeek
	;
		dec	ds:[di].DT_weekday
		cmp	ds:[di].DT_weekday, -1
		jnz	noMonday
		mov	ds:[di].DT_weekday, 6
noMonday:
	;
	; Dec days
	;
		mov	ah, ds:[di].DT_day
		dec	ds:[di].DT_day
		clr	bh
		cmp	ah, 1
	LONG_EC	ja	done
	;
	; Dec months
	;
		dec	ds:[di].DT_month
		cmp	ds:[di].DT_month, 2			;February ?
		jnz	notFeb
		test	byte ptr ds:[di].DT_year, 00000011b	;leap year ?
		jnz	notFeb
		mov	ds:[di].DT_day, 29	;LEAP YEAR!!! Do it right!!!
		jmp	done
notFeb:
		cmp	ds:[di].DT_month, 0
		jnz	doDays
		mov	ds:[di].DT_month, 12
	;
	; Dec years
	;
		dec	ds:[di].DT_year
doDays:
		mov	bl,ds:[di].DT_month
		mov	dl, cs:[bx][daysPerMonth-1]
		mov	ds:[di].DT_day, dl
done:
		.leave
		ret
DecrementDate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncrementDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments the date by one.

CALLED BY:	(EXTERNAL) DIDateInc
PASS:		ds:di	- ptr to DateStruct
RETURN:		Date incremented by one
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Steal form Tony	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncrementDate	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MAX_YEAR
EC <		ERROR_A YEAR_OUT_OF_RANGE				>
		LONG ja	done
		jb	ok
		cmp	ds:[di].DT_month, 12
		jb	ok
		cmp	ds:[di].DT_day, 31
		LONG jnb	done
ok:
		clr	al
	;
	; bump dayOfWeek
	;
		inc	ds:[di].DT_weekday
		cmp	ds:[di].DT_weekday,7
		jnz	noMonday
		mov	ds:[di].DT_weekday,al
noMonday:
	;
	; bump days
	;
		mov	ah, ds:[di].DT_day
		inc	ds:[di].DT_day
		mov	bl,ds:[di].DT_month
		cmp	bl,2			;February ?
		jnz	notFeb
		test	byte ptr ds:[di].DT_year, 00000011b	;leap year ?
		jnz	notFeb
		dec	ah			;LEAP YEAR!!! Do it right!!!
notFeb:
		clr	bh
		cmp	ah, cs:[bx][daysPerMonth-1]
		jb	done
		inc	al			;days wrap to 1
		mov	ds:[di].DT_day,al
	;
	; bump months
	;
		inc	ds:[di].DT_month
		cmp	ds:[di].DT_month, 13
		jnz	done
		mov	ds:[di].DT_month, al
	;
	; bump years
	;
		inc	ds:[di].DT_year
done:
		.leave
		ret
IncrementDate	endp

daysPerMonth		byte \
		31,		;January
		28,		;Feburary
		31,		;March
		30,		;April
		31,		;May
		30,		;June
		31,		;July
		31,		;August
		30,		;September
		31,		;October
		30,		;November
		31		;December


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncrementWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments the date by one week (that's seven days)

CALLED BY:	(EXTERNAL)
PASS:		ds:di	- ptr to DateStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncrementWeek	proc	near
		uses	ax,bx
		.enter
	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MAX_YEAR
EC <		ERROR_A YEAR_OUT_OF_RANGE				>
		LONG ja	done
		jb	ok
		cmp	ds:[di].DT_month, 12
		jb	ok
		cmp	ds:[di].DT_day, 25
		LONG jnb	done
ok:
	;
	; Bump days
	;
		add	ds:[di].DT_day, 7
		mov	ah, ds:[di].DT_day
		mov	bl, ds:[di].DT_month
		clr	bh
	;
	; Test for end of month
	;
		mov	al, cs:[bx][daysPerMonth-1]      ; al <- days/month
		cmp	bl, 2			;Feb?
		jne	notLeap
		test	byte ptr ds:[di].DT_year, 00000011b	;leap year ?
		jnz	notLeap
		inc	al				 ; Leap Feb has 29 days
notLeap:
		sub	ah, al				 ; too many days?
		jle	done
	;
	; We have overshoot the end of the month so we need to adjust
	;
		mov	ds:[di].DT_day, ah
		inc	bl
		mov	ds:[di].DT_month, bl
	;
	; Overshot end of year?
	;
		cmp	ds:[di].DT_month, 13
		jnz	done
		mov	ds:[di].DT_month, 1
	;
	; bump years
	;
		inc	ds:[di].DT_year
done:
		.leave
		ret
IncrementWeek	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncrementMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the current month by 1. The day will be set to
		1.  The day of week will be invalid.

CALLED BY:	(EXTERNAL)
PASS:		ds:di	- ptr DateStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncrementMonth	proc	near
		.enter
	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MAX_YEAR
EC <		ERROR_A YEAR_OUT_OF_RANGE				>
		ja	done
		jb	ok
		cmp	ds:[di].DT_month, 12
		jnb	done
ok:
	;
	; Set the day to the first of the month.
	;
		mov	ds:[di].DT_day, 1
	;
	; Add one to the month and check if we are into jan
	;	
		inc	ds:[di].DT_month
		cmp	ds:[di].DT_month, 13
		jnz	done
		mov	ds:[di].DT_month, 1
	;
	; Add one year
	;
		inc	ds:[di].DT_year
done:
		.leave
		ret
IncrementMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecrementYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the year by one.  The date is set to 01.01 and
		the week day is invalid.

CALLED BY:	(EXTERNAL)
PASS:		ds:di	- ptr to DateStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecrementYear	proc	near

	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MIN_YEAR
EC <		ERROR_B YEAR_OUT_OF_RANGE				>
		jbe	done
	;
	; Set the date to 1/1
	;
		mov	ds:[di].DT_day, 1
		mov	ds:[di].DT_month, 1
	;
	; Check if the year is 0 if so don't decrement any more.
	;
		dec	ds:[di].DT_year
done:
		ret
DecrementYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IncrementYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments the year by one.  The date is set to 01.01 and
		the week day is invalid.

CALLED BY:	(EXTERNAL)
PASS:		ds:di	- ptr to DateStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IncrementYear	proc	near

	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MAX_YEAR
EC <		ERROR_A YEAR_OUT_OF_RANGE				>
		jae	done
	;
	; Set date to 1/1/y+1
	;	
		mov	ds:[di].DT_day, 1
		mov	ds:[di].DT_month, 1
		inc	ds:[di].DT_year
done:
		ret
IncrementYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecrementWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the date by one week (seven days)

CALLED BY:	(EXTERNAL)
PASS:		ds:di	- ptr to DateStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecrementWeek	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MIN_YEAR
EC <		ERROR_B YEAR_OUT_OF_RANGE				>
		LONG jb	done
		ja	ok
		cmp	ds:[di].DT_month, 1
		ja	ok
		cmp	ds:[di].DT_day, 7
		LONG jna	done
ok:
	;
	; Diminish days
	;
		sub	ds:[di].DT_day, 7
		mov	ah, ds:[di].DT_day
		cmp	ah, 1
	LONG_EC	jge	done

		dec	ds:[di].DT_month		
		cmp	ds:[di].DT_month, 0
		jnz	date
		mov	ds:[di].DT_month, 12
	;
	; Slice a year off
	;
		dec	ds:[di].DT_year

	;
	; We are the begining of a month so we need to adjust
	;
date:
		mov	bl, ds:[di].DT_month
		clr	bh
		mov	cl, cs:[bx][daysPerMonth-1]
		add	cl, ah
		mov	ds:[di].DT_day, cl 
		cmp	bl, 2			; Feb?
		jnz	done
		test	byte ptr ds:[di].DT_year, 00000011b	;leap year ?
		jnz	done
		inc	ds:[di].DT_day		;LEAP YEAR!!! Do it right!!!
done:
		.leave
		ret
DecrementWeek	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DecrementMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the current month by 1. The day will be set to
		1.  The day of week will be invalid.

CALLED BY:	(EXTERNAL)
PASS:		ds:di	- ptr DateStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DecrementMonth	proc	near
		.enter

	;
	; Check to make sure the destination date will be in range
	;
		cmp	ds:[di].DT_year, MIN_YEAR
EC <		ERROR_B YEAR_OUT_OF_RANGE				>
		jb	done
		ja	ok
		cmp	ds:[di].DT_month, 1
		jna	done
ok:
	;
	; Set the day to the first of the month.
	;
		mov	ds:[di].DT_day, 1
	;
	; Sub one from the month and check if we are into december
	;	
		dec	ds:[di].DT_month
		cmp	ds:[di].DT_month, 0
		jnz	done
		mov	ds:[di].DT_month, 12
	;
	; Minus one year
	;
		dec	ds:[di].DT_year
done:
		.leave
		ret
DecrementMonth	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CalcDayOfWeek

DESCRIPTION:	Figure the day of the week given its absolute date.

CALLED BY:	(EXTERNAL) DSSetDateForReal SendDIActionMessage

PASS:
	ax - year (1901 through 2099)
	bl - month (1 through 12)
	bh - day (1 through 31)

RETURN:
	cl - day of the week
	ch - 0

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	SH	07/94		Lifted from the kernel
------------------------------------------------------------------------------@
CalcDayOfWeek	proc	near
		uses ax, bx, dx, ds
		.enter
	;
	; For now, let's barf it the year isn't in the desired range.
	;
		cmp	ax, MIN_YEAR
EC <		ERROR_B	YEAR_OUT_OF_RANGE				>
		jae	checkHigh
		mov	ax, MIN_YEAR					
checkHigh:
		cmp	ax, MAX_YEAR
EC <		ERROR_A	YEAR_OUT_OF_RANGE				>
		jbe	okYear
		mov	ax, MAX_YEAR				    
okYear:
		sub	ax, 1904
	;
	; add in extra days for leap years
	;
		mov	dx, ax
		shr	ax, 1
		shr	ax, 1
	;
	; if jan or feb and leap year then adjust
	;
		test	dl, 00000011b
		jnz	noLeap
		cmp	bl, 3
		jae	noLeap
		dec	ax			;adjust
noLeap:
		add	ax, dx
	;
	; add in offset for JAN 1, 1904 which was a FRIDAY
	;
		add	ax, 5
	;
	; add days
	;
		mov	cl, bh
		clr	ch
		add	ax, cx			;ax = total

		clr	bh			;bx = months
		jmp	noInc

dayLoop:
		add	al, cs:[bx][daysPerMonth-1]
		jnc	noInc
		inc	ah
noInc:
		dec	bx
		jnz	dayLoop	

		mov	bl, 7
		div	bl
		
		clr	cx
		mov	cl, ah			; cl <- day_of_week

		.leave
		ret

CalcDayOfWeek	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWeekNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the week number given a date

CALLED BY:	(EXTERNAL) UpdateWeekText
PASS:		ax, bx, cl - year/month/day/day_of_week
RETURN:		bx	   - week number (1-52)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWeekNumber	proc	near

		uses	ax,cx,dx,di
		.enter
	
		clr	dx
		clr	cx
		mov	cl, bl			; cl <- month
		mov	dl, bh			; dl <- day
		clr	di			; bx <- number of days
		clr	bx

		cmp	cx, 1			; is it jan?
		je	addDay
		dec	cx			; don't count current month
topLoop:
		mov	si, cx
		mov	bl, cs:[si][daysPerMonth-1]
		add	di, bx
		cmp	cx, 2
		jne	notFeb
		test	ax, 00000011b		;leap year ?
		jnz	notFeb
		inc	di			; LEAP YEAR		
notFeb:
		loop	topLoop
addDay:
		add	di, dx			; add the number of days in
						;  current month.
		dec	di	                ; since days are 1-based
	;
	; Take div 7 of di to get the number of weeks
	;
		mov	ax, di
		mov	bl, 7
		div	bl
		mov	bl, al
		clr 	bh			; bx <- week number
		inc	bx
done::
		.leave
		ret

GetWeekNumber	endp

GadgetsSelectorCode	ends
