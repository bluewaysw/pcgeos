
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseDateTime.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
		
	$Id: parseDateTime.asm,v 1.1 97/04/05 01:27:19 newdeal Exp $

-------------------------------------------------------------------------------@

EvalCode	segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionDate

DESCRIPTION:	Implements the DATE() function.

		Calculates the date number for a set of year, month, and
		day values.  For example, DATE(89, 1, 7) returns 32515, the
		date number for January 7, 1989.

		(A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050)).

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionDate	proc	near	uses	cx,dx
	.enter
	mov	ax, 3
	call	FunctionCheckNNumericArgs
	jc	done

	;
	; get day
	;
	call	GetByteArg		; ax <- int, cx decremented
	jc	done

	mov	dh, al			; dh <- day

	;
	; get month
	;
	call	GetByteArg		; ax <- int, cx decremented
	jc	done

	mov	dl, al			; dl <- month

	;
	; get year
	;
	call	GetWordArg		; ax <- year, cx decremented
	jc	done

	cmp	ax, 100
	jge	10$

	add	ax, 1900

10$:
	push	bx
	mov	bx, dx
	call	FloatGetDateNumber
	pop	bx

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionDate	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionDateValue

DESCRIPTION:	Implements the DATEVALUE() function.

		DATEVALUE(date_text)
		Returns the date number of the date represented by date_text.
		Use DATEVALUE to convert a date represented by text to a
		date number.

		If any portion of date_text is omitted, DATEVALUE uses the
		current value from the computer's built-in clock.

CALLED BY:	INTERNAL ()

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

FunctionDateValue	proc	near	uses	di
	.enter
	call	FunctionCheck1StringArg
	jc	done

	;
	; get format and point to string
	;
	push	di
	lea	di, es:[bx].ASE_data.ESAD_string.ESD_length+2
	call	FloatStringGetDateNumber
	pop	di

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionDateValue	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionDay

DESCRIPTION:	Implements the DAY() function.

		Get the day of the month given a date number.
		For example, DAY(32515) returns the value 7 because 32515 is
		the date number for Jan 7, 1989.

		(A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050)).

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	use dx:ax to track number of days

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionDay	proc	near	uses	cx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatTrunc

	push	bx
	call	FloatDateNumberGetMonthAndDay	; bh <- day
	mov	al, bh
	mov	ah, 0				; preserve carry
	pop	bx
	jc	doneErr

	call	FloatWordToFloat
	clc

doneErr:
	mov	al, PSEE_GEN_ERR		; in case of error
done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionDay	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionWeekday

DESCRIPTION:	Implements the WEEKDAY() function.

		Converts a date number to a day of the week.
		For example, WEEKDAY(32515) returns the value 7 because 32515
		is the date number for Sat Jan 7, 1989.

		Sun = 1
		Mon = 2
		...
		Sat = 7

		(A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050)).

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionWeekday	proc	near	uses	cx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatDateNumberGetWeekday

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionWeekday	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionMonth

DESCRIPTION:	Implements the MONTH() function.

		Get the month given a date number.
		For example, MONTH(32515) returns the value 1 because 32515 is
		the date number for Jan 7, 1989.

		(A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050)).

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	use dx:ax to track number of days

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionMonth	proc	near	uses	cx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatTrunc

	push	bx
	call	FloatDateNumberGetMonthAndDay	; bl <- month
	mov	al, PSEE_GEN_ERR
	jc	err

	mov	al, bl
	mov	ah, 0				; preserve carry
err:
	pop	bx
	jc	done

	call	FloatWordToFloat
	clc

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionMonth	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionYear

DESCRIPTION:	Implements the YEAR() function.

		Get the month given a date number.
		For example, YEAR(32515) returns the value 1989 because 32515
		is the date number for Jan 7, 1989.

		(A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050)).

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	use dx:ax to track number of days

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionYear	proc	near	uses	cx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatTrunc

	call	FloatDateNumberGetYear	; ax <- year
	jc	done

	call	FloatWordToFloat
	clc

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionYear	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionHour

DESCRIPTION:	Implements the HOUR() function.

		Calculates the hour in a time number (based on a 24 hour
		format).  For example, HOUR(0.604745) returns the value 14
		because 0.604745 is the time number for 2:30:50 PM.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
		time number on the fp stack

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionHour	proc	near	uses	dx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatFrac

	call	FloatTimeNumberGetHour
	jc	done

	call	FloatDup
	mov	ax, MINUTE_MAX
	call	FloatWordToFloat
	call	FloatCompAndDrop		; flags set
	clc
	jle	done

	mov	al, PSEE_GEN_ERR
	stc

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionHour	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionMinute

DESCRIPTION:	Implements the MINUTE() function.

		Calculates the minutes in a time number. For example,
		MINUTE(0.604745) returns the value 30 because 0.604745
		is the time number for 2:30:50 PM.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
		time number on the fp stack

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionMinute	proc	near	uses	dx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatFrac

	call	FloatTimeNumberGetMinutes
	jc	done

	call	FloatDup
	mov	ax, MINUTE_MAX
	call	FloatWordToFloat
	call	FloatCompAndDrop		; flags set
	clc
	jle	done

	mov	al, PSEE_GEN_ERR
	stc

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionMinute	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionSecond

DESCRIPTION:	Implements the SECOND() function.

		Calculates the seconds in a time number. For example,
		SECOND(0.604745) returns the value 50 because 0.604745
		is the time number for 2:30:50 PM.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.
		time number on the fp stack

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionSecond	proc	near	uses	dx
	.enter
	call	FunctionCheck1NumericArg
	jc	done

	call	FloatFrac

	call	FloatTimeNumberGetSeconds
	jc	done

	call	FloatDup
	mov	ax, SECOND_MAX
	call	FloatWordToFloat
	call	FloatCompAndDrop		; flags set
	clc
	jle	done

	mov	al, PSEE_GEN_ERR
	stc

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionSecond	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTime

DESCRIPTION:	Implements the TIME() function.

		Calculates the time number for a set of hour, minute, and
		second values.  For example, TIME(14, 30, 50) returns
		0.604745, the time number 2:30:50 PM.

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionTime	proc	near	uses	cx,dx
	.enter
	mov	ax, 3
	call	FunctionCheckNNumericArgs
	jc	done

	;
	; get seconds
	;
	call	GetByteArg		; ax <- int, cx decremented
	jc	done

	mov	dh, al			; dh <- seconds

	;
	; get minutes
	;
	call	GetByteArg		; ax <- int, cx decremented
	jc	done

	mov	dl, al			; dl <- minutes

	;
	; get hours
	;
	call	GetByteArg		; ax <- year, cx decremented
	jc	done

	push	cx
	mov	ch, al			; ch <- hours
	call	FloatGetTimeNumber
	pop	cx

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionTime	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionTimeValue

DESCRIPTION:	Implements the TIMEVALUE() function.

		TIMEVALUE(time_text)
		Returns the time number of the time represented by time_text.
		Use TIMEVALUE to convert a time represented by text to a
		time number.

		If any portion of time_text is omitted, TIMEVALUE uses 0.

CALLED BY:	INTERNAL ()

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

-------------------------------------------------------------------------------@

FunctionTimeValue	proc	near	uses	di
	.enter
	call	FunctionCheck1StringArg
	jc	done

	;
	; get format and point to string
	;
	push	di	;;; Added 5/11/95 -jw
			;;; You can't nuke the operator-stack pointer.
			;;; The code deep down in the call chain from
			;;; FunctionCleanUpDateOp() needs it.
			
	lea	di, es:[bx].ASE_data.ESAD_string.ESD_length+2
	call	FloatStringGetTimeNumber

	pop	di	;;; Added 5/11/95 -jw
			;;; Matches the push above.

done:
	call	FunctionCleanUpDateOp
	.leave
	ret
FunctionTimeValue	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionNow

DESCRIPTION:	Implements the NOW() function.

		Calculates the date and time number from the system
		date and time.

		A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050).

		Time Numbers are consecutive decimal values that correspond
		to times from midnight (time number 0.000000) through
		11:59:59 PM (time number 0.999988)

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionNow	proc	near
	call	FunctionCheck0Args
	jc	done

	push	bx,cx,dx
	call	TimerGetDateAndTime
	;
	; ax - year (1980 through 2099)
	; bl - month (1 through 12)
	; bh - day (1 through 31)
	; cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
	; ch - hours (0 through 23)
	; dl - minutes (0 through 59)
	; dh - seconds (0 through 59)
	;

	call	FloatGetDateNumber	; pass ax, bx; ax destroyed
	call	FloatGetTimeNumber	; pass ch, dx; ax destroyed
	call	FloatAdd		; ( fp: date and time number )
	pop	bx,cx,dx
	clc

done:
	GOTO	FunctionCleanUpDateOp
FunctionNow	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FunctionToday

DESCRIPTION:	Calculates the date number from the system date.

		A Date Number is the number of days from Jan 1, 1900 (date
		number 1) to through December 31, 2099 (date number 73050).

CALLED BY:	PopOperatorAndEval via functionHandlers

PASS:		es:bx	- pointer to top of argument stack
		cx	- number of arguments passed to the function
		ss:bp	- pointer to EvalParameters on the stack.

RETURN:		es:bx	- pointer to new top of argument stack
		carry set on error
			al - error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FunctionToday	proc	near
	call	FunctionCheck0Args
	jc	err

	call	FunctionNow
	call	FloatTrunc
	ret

err:
	GOTO	FunctionCleanUpDateOp
FunctionToday	endp

EvalCode	ends
