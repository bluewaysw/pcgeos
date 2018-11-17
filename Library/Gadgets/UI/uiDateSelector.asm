COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Date Selector Gadget
FILE:		uiDateSelector.asm

AUTHOR:		Skarpi Hedinsson, Jun 24, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT CopyBuildInfoCommon     Return group

    INT PrependText             This message is sent by the output in
				response to
				MSG_DATE_SELECTOR_REPLACE_YEAR_TEXT to the
				DateSelector, passing a fptr to a
				null-terminated string which is
				appended/prepended to the year.

    INT AppendText              This message is sent by the output in
				response to
				MSG_DATE_SELECTOR_REPLACE_YEAR_TEXT to the
				DateSelector, passing a fptr to a
				null-terminated string which is
				appended/prepended to the year.

    INT DSSetDateForReal        Message sent to the DateSelector to change
				the current displayed date.

    INT SendDSActionMessage     Sends the action message (DSI_actionMsg) to
				the output (GCI_output).

    INT GetWeekNumber           Calculates the week number given a date

    INT DecrementWeek           Decrements the date by one week (seven
				days)

    INT IncrementWeek           Increments the date by one week (that's
				seven days)

    INT DecrementMonth          Decrements the current month by 1. The day
				will be set to 1.  The day of week will be
				invalid.

    INT IncrementMonth          Decrements the current month by 1. The day
				will be set to 1.  The day of week will be
				invalid.

    INT DecrementYear           Decrements the year by one.  The date is
				set to 01.01 and the week day is invalid.

    INT IncrementYear           Increments the year by one.  The date is
				set to 01.01 and the week day is invalid.

    INT UpdateDateSelectorText  Update the DSText according to
				DSI_dateType.

    INT DisplayLongCondensedDate 
				Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayLongDate         Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayShortDate        Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayZPaddedShortDate Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayWeek             Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayWeekYear         Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayMonth            Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayShortMonth       Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayMonthYear        Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayShortMonthYear   Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayShortMonthShortYear 
				Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayYear             Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayYearText         Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayWeekday          Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT DisplayShortWeekday     Sets up the size of the GenText, formats
				the date in the correct format and displays
				it in the GenText.

    INT InitDateSelector        Sets the fixed size of the GenText object
				of the controller. The text is centered
				within the GenText.  You can override this
				default by setting the textWidth field in
				instance data.

    INT SetTextFrame            Draws a frame around the GenText if
				HINT_DATE_SELECTOR_DRAW_FRAME is defined on
				the object.

    INT SetIncDecTriggersNotUsable 
				If GA_READ_ONLY is set this function the
				Inc and Dec triggers not usable.

    INT SetGenTextDefaultWidth  Sets the default width of the GenText
				object used to display the date.  The
				default width varies depending on what
				dateType the DateSelector is set to.

    INT UpdateDateText          Formats, Sizes and Displays the date.

    INT ReplaceDateText         Formats, Sizes and Displays the date.

    INT UpdateWeekText          Formats, Sizes and Displays the week with
				or without the year.

    INT FormatWeek              Formats the week text.

    INT UpdateShortMonthText    Updates the custom short month text.

    INT UpdateYearText          Sends a MSG_DATE_SELECTOR_REPLACE_YEAR text
				to the output.

    INT LockStringResource      Locks a string resource and returns a
				pointer to the string

    INT UnlockStringResource    Unlocks a string resource that was locked
				using LockStringResource

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/24/94   	Initial revision


DESCRIPTION:
	
	This file contains routines to implement DateSelectorControlClass

	$Id: uiDateSelector.asm,v 1.1 97/04/04 17:59:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsClassStructures	segment resource

	DateSelectorClass		;declare the class record

GadgetsClassStructures	ends

;---------------------------------------------------

GadgetsSelectorCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateSelectorMetaQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to make sure we handle this because otherwise
   		we'll go into an infinite loop of sending ourselves this
   		message forever in the specific-ui.

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		ds:bx	= DateSelectorClass object (same as *ds:si)
		es 	= segment of DateSelectorClass
		ax	= message #

RETURN:		ax	= InkReturnValue
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	3/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateSelectorMetaQueryIfPressIsInk	method dynamic DateSelectorClass, 
					MSG_META_QUERY_IF_PRESS_IS_INK
	uses	cx, dx, bp
	.enter

	mov	ax, IRV_NO_INK
	
	.leave
	ret
DateSelectorMetaQueryIfPressIsInk	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	DateSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for DateSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si 	- instance data
	es 	- segment of DateSelectorClass
	ax 	- The message
	cx:dx	- GenControlBuildInfo structure to fill in

RETURN:
	cx:dx - list of children

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
DateSelectorGetInfo	method dynamic	DateSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

		mov	si, offset DSC_dupInfo
		call	CopyBuildInfoCommon
		ret
DateSelectorGetInfo	endm


DSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0,				; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	0,				; GCBI_controllerName

	handle DateSelectorUI,		; GCBI_dupBlock
	DSC_childList,			; GCBI_childList
	length DSC_childList,		; GCBI_childCount
	DSC_featuresList,		; GCBI_featuresList
	length DSC_featuresList,	; GCBI_featuresCount
	DS_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

GadgetsControlInfo	segment resource

DSC_childList	GenControlChildInfo	\
   <offset DateSelectorGroup, mask DSF_DATE, mask GCCF_ALWAYS_ADD>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

DSC_featuresList	GenControlFeaturesInfo	\
	<offset DateSelectorGroup, offset DateSelectorName, 0>

GadgetsControlInfo	ends

COMMENT @----------------------------------------------------------------------

MESSAGE:	DateSelectorGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for DateSelectorClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the filled/unfilled items

PASS:
	*ds:si - instance data
	es - segment of DateSelectorClass
	ax - The message

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Skarpi	06/22/94	Initial version

------------------------------------------------------------------------------@
DateSelectorGenerateUI		method dynamic	DateSelectorClass,
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Call the superclass
	;
		mov	di, offset DateSelectorClass
		call	ObjCallSuperNoLock
	;
	; If the do draw/don't draw feature isn't set, then we have no worries
	;
		call	GetChildBlockAndFeatures	; bx <- handle
		test	ax, mask DSF_DATE
		jz	done

	;
	; Display current date UNLESS there's already a valid date
	; stored in the object.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].DSI_date.DT_year, -1
		jne	alreadyInitialized
	;
	; Get the current date
	;
	; returns:
	;	ax - year (1980 through 2099)
	;	bl - month (1 through 12)
	;	bh - day (1 through 31)
	;	cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
	;	ch - hours (0 through 23)
	;	dl - minutes (0 through 59)
	;	dh - seconds (0 through 59)
	;
		call	TimerGetDateAndTime	; axbxcxdx <- date/time
	;
	; Copy the current date to instance data
	;
		add	di, offset DSI_date
		call	SetDate
	;
	; Initialize the date selector, this sets GenText size and hint.
	; Disables the Inc/Dec triggers if so desired.
	;
alreadyInitialized:		
		call	InitDateSelector
	;
	; Format the correct date according to the display option
	;
		call	UpdateDateSelectorText
done:
		.leave
		ret
DateSelectorGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateSelectorSetYearText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent by the output in response to 
		MSG_DATE_SELECTOR_REPLACE_YEAR_TEXT to the DateSelector,
		passing a fptr to a null-terminated string which is
		appended/prepended to the year.

CALLED BY:	MSG_DATE_SELECTOR_SET_YEAR_TEXT
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		ds:bx	= DateSelectorClass object (same as *ds:si)
		es 	= segment of DateSelectorClass
		ax	= message #
		cx	= DSYearTextFormat
		dx:bp	= fptr to year text (must be fptr for XIP)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateSelectorSetYearText	method dynamic DateSelectorClass, 
					MSG_DATE_SELECTOR_SET_YEAR_TEXT
		uses	ax, cx, dx, bp
		.enter
	;
	; Some error checking code to check if the size of the string is
	; correct.
	;
EC <		push	es, di, cx					>
EC <		movdw	esdi, dxbp					>
EC <		call	LocalStringSize		; cx <- size		>
EC <		add	cx, 6			; cx <- str+year+null	>
EC <		cmp	cx, size DateTimeBuffer				>
EC <		ERROR_G GADGETS_LIBRARY_SIZE_OF_YEAR_TEXT_EXCEEDS_LIMIT	>
EC <		pop	es, di, cx					>
	;
	; Get the date from instance data.
	;
		push	cx
		add	di, offset DSI_date
		call	GetDate			; ax, bx, cl <- date
		pop	cx
	;
	; Setup stack space for string.
	;
		sub	sp, size DateTimeBuffer
		segmov	es, ss
		mov	di, sp
	;
	; First check the format type, this decides if we prepend or append.
	;
		cmp	cx, DSYTF_APPEND
		je	append
	;
	; Prepend the text to the year.
	;
		call	PrependText
sendMessage:
	;
	; Update the GenText object showing the new text.
	; 
		call	ReplaceDateText
	;
	; Reset stack space.
	;
		add	sp, size DateTimeBuffer

		.leave
		ret
append:
	;
	; Append the text to the year
	;
		call	AppendText
		jmp	sendMessage
DateSelectorSetYearText	endm
;-----
PrependText	proc near
		uses	ds, si
	class	DateSelectorClass
		.enter

		clr	bx
		mov	es:[di], bx		; null at begining for StrCat
	;
	; Copy the year text first
	;
		mov	ds, dx
		mov	si, bp
		clr	cx			; null-term
		call	StrCat
	;
	; Add space
	;
		mov	bx, C_SPACE
		push	bx
		segmov	ds, ss
		mov	si, sp
		call	StrCat
		pop	bx
	;
	; Add the year
	;
		push	di
		call	LocalStringSize		; cx <- Number of bytes - NULL
		add	di, cx
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	di
	;
	; Return string size
	;
		call	LocalStringSize		; cx <- size

		.leave
		ret
PrependText	endp
;-----
AppendText	proc near
		uses	ds, si
	class	DateSelectorClass
		.enter
	;
	; Add the year
	;
		push	dx
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	dx
	;
	; Add space
	;
		mov	bx, C_SPACE
		push	bx
		segmov	ds, ss
		mov	si, sp
		clr	cx
		call	StrCat
		pop	bx
	;
	; Copy the year text first
	;
		mov	ds, dx
		mov	si, bp
		call	StrCat
	;
	; Return string size
	;
		call	LocalStringSize		; cx <- size

		.leave
		ret
AppendText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDateInc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the date by one.

CALLED BY:	MSG_DS_DATE_INC
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Updates the DSI_date instance data.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDateInc	method dynamic DateSelectorClass, 
					MSG_DS_DATE_INC
		uses	ax, cx, dx, bp
		.enter
	;
	; Increment the date by one
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset		
		mov	bx, ds:[di].DSI_dateType
		shl	bx
		add	di, offset DSI_date
		call	cs:incTable[bx]
	;
	; Show the new date
	;
		call	UpdateDateSelectorText
	;
	; Send message letting the output know the date has changed
	;
		call	SendDSActionMessage

		.leave
		ret
DSDateInc	endm

incTable	nptr.near	\
	offset cs:IncrementDate,
	offset cs:IncrementDate,
	offset cs:IncrementDate,
	offset cs:IncrementDate,
	offset cs:IncrementWeek,
	offset cs:IncrementWeek,
	offset cs:IncrementMonth,
	offset cs:IncrementMonth,
	offset cs:IncrementMonth,
	offset cs:IncrementMonth,
	offset cs:IncrementMonth,
	offset cs:IncrementYear,
	offset cs:IncrementYear,
	offset cs:IncrementDate,		; DST_WEEKDAY
	offset cs:IncrementDate			; DST_SHORT_WEEKDAY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDateDec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the date by one.

CALLED BY:	MSG_DS_DATE_DEC
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Updates the DSI_date instance data.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDateDec	method dynamic DateSelectorClass, MSG_DS_DATE_DEC
		uses	ax, cx, dx, bp
		.enter
	;
	; Increment the date by one
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset		
		mov	bx, ds:[di].DSI_dateType
		shl	bx
		add	di, offset DSI_date
		call	cs:decTable[bx]
	;
	; Show the new date
	;
		call	UpdateDateSelectorText
	;
	; Send message letting the output know the date has changed
	;
		call	SendDSActionMessage

		.leave
		ret
DSDateDec	endm

decTable	nptr.near	\
	offset cs:DecrementDate,
	offset cs:DecrementDate,
	offset cs:DecrementDate,
	offset cs:DecrementDate,
	offset cs:DecrementWeek,
	offset cs:DecrementWeek,
	offset cs:DecrementMonth,
	offset cs:DecrementMonth,
	offset cs:DecrementMonth,
	offset cs:DecrementMonth,
	offset cs:DecrementMonth,
	offset cs:DecrementYear,
	offset cs:DecrementYear,
	offset cs:DecrementDate,
	offset cs:DecrementDate


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSSetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent to the DateSelector to change the current
		displayed date.

CALLED BY:	MSG_DATE_SELECTOR_SET_DATE
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		ds:bx	= DateSelectorClass object (same as *ds:si)
		es 	= segment of DateSelectorClass
		ax	= message #
		cx	= year
		dl	= month
		dh	= day
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSSetDate	method dynamic DateSelectorClass, 
					MSG_DATE_SELECTOR_SET_DATE
	FALL_THRU	DSSetDateForReal
DSSetDate	endm

DSSetDateForReal	proc	far
	class	DateSelectorClass
		uses	ax, cx, dx, bp
		.enter

		cmp	cx, MIN_YEAR
EC <		ERROR_B YEAR_OUT_OF_RANGE				>
		jb	done
		cmp	cx, MAX_YEAR
EC <		ERROR_A	YEAR_OUT_OF_RANGE				>
		ja	done
	;
	; Calculate the day of week for the given date.
	;
		mov	ax, cx			; ax <- year
		mov	bx, dx			; bx <- month/day
		call	CalcDayOfWeek		; cl <- day of week
	;
	; Change the instance data DSI_date to reflect the new date
	;	
		add	di, offset DSI_date
		call	SetDate
	;
	; Now update the date in the GenText
	;
		call	UpdateDateSelectorText
	;
	; Send message letting the output know the date has changed
	;
;		call	SendDSActionMessage
done:
		.leave	
		ret
DSSetDateForReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDateSelectorSetWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current weekday

CALLED BY:	MSG_DATE_SELECTOR_SET_WEEKDAY
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		cl	= day of week (0=Sunday, 6=Saturday)
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	11/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDateSelectorSetWeekday	method dynamic DateSelectorClass, 
					MSG_DATE_SELECTOR_SET_WEEKDAY
		uses	cx, dx
		.enter

EC <		cmp	ds:[di].DSI_dateType, DST_WEEKDAY		>
EC <		je	okToUse						>
EC <		cmp	ds:[di].DSI_dateType, DST_SHORT_WEEKDAY		>
EC <		ERROR_NE GADGETS_LIBRARY_CANNOT_MANIPULATE_WEEKDAY_IN_NON_WEEKDAY_MODE >
EC < okToUse:								>

	;
	; We'll set the weekday by setting ourselves to a date that
	; happens to fall on that weekday, among other things.
	;
		mov	dh, 3
		add	dh, cl
		mov	dl, 5
		mov	cx, 1970	      ; May 3, 1970 was a Sunday (0)

		call	DSSetDateForReal

		.leave
		ret
DSDateSelectorSetWeekday	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDateSelectorGetWeekday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the current weekday

CALLED BY:	MSG_DATE_SELECTOR_GET_WEEKDAY
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
RETURN:		cl	= day of week (0=Sunday, 6=Saturday)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	11/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDateSelectorGetWeekday	method dynamic DateSelectorClass, 
					MSG_DATE_SELECTOR_GET_WEEKDAY
	.enter

EC <	cmp	ds:[di].DSI_dateType, DST_WEEKDAY			>
EC <	je	okToUse							>
EC <	cmp	ds:[di].DSI_dateType, DST_SHORT_WEEKDAY			>
EC <	ERROR_NE GADGETS_LIBRARY_CANNOT_MANIPULATE_WEEKDAY_IN_NON_WEEKDAY_MODE >
okToUse::
		mov	cl, ds:[di].DSI_date.DT_weekday
	.leave
	ret
DSDateSelectorGetWeekday	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current date of the DateSelector.

CALLED BY:	MSG_DATE_SELECTOR_GET_DATE
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
RETURN:		cx	= year
		dl	= month
		dh	= day of month
		bp	= day of week
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGetDate	method dynamic DateSelectorClass, 
					MSG_DATE_SELECTOR_GET_DATE
		uses	ax
		.enter
	;
	; Get the date for instance data
	;
		add	di, offset DSI_date
		call	GetDate			; ax, bx, cl <- date
	;
	; Set the correct return values
	;
		mov	bp, cx			; bp <- day of week
		mov	cx, ax			; cx <- year
		mov	dx, bx			; dx <- month/day

		.leave
		ret
DSGetDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDSActionMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the action message (DSI_actionMsg) to the output 
		(GCI_output).

CALLED BY:	DSDateInc, DSDateDec
PASS:		*ds:si - Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDSActionMessage	proc	near
		uses	ax,bx,cx,dx,di,bp
	class	DateSelectorClass
		.enter
EC <		call	ECCheckObject					>
	;
	; First get the current date
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	di
		add	di, offset DSI_date
		call	GetDate		; ax, bx, cl <- date
		mov	bp, cx		; bp <- day of week
		mov	dx, bx		; dx <- month and day
		mov	cx, ax		; cx <- year
		pop	di		; ds:di <- instance data
	;
	; Get the action message and destination from instance data and
	; send message.
	;
		mov	ax, ds:[di].DSI_actionMsg ; ax <- msg to send
		mov	bx, segment DateSelectorClass
		mov	di, offset DateSelectorClass ; bx:di <- class
		call	GadgetOutputActionRegs
		
		.leave
		ret
SendDSActionMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDateSelectorText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the DSText according to DSI_dateType.

CALLED BY:	(INTERNAL) DSDateDec, DSDateInc, DSDateSelectorSetDateType,
		DSMetaNotify, DSSetDateForReal, DateSelectorGenerateUI
PASS:		*ds:si - Date Selector
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDateSelectorText	proc	near
		uses	bx, di
	class	DateSelectorClass
		.enter
	;
	; Get the dateType and call the corresponding function that does
	; the actual updating.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].DSI_dateType
		shl	bx
		call	cs:dateTypeTable[bx]

	;
	; If we currently have the focus, then draw the focus lines
	;
		mov	ax, TEMP_DATE_SELECTOR_HAS_FOCUS
		call	ObjVarFindData
		jnc	done

		mov	al, MM_COPY
		call	DSDrawFocusNoGState
done:
		.leave
		ret
UpdateDateSelectorText	endp

dateTypeTable	nptr.near	\
	offset	cs:DisplayLongCondensedDate,
	offset 	cs:DisplayLongDate,
	offset	cs:DisplayShortDate,
	offset	cs:DisplayZPaddedShortDate,
	offset	cs:DisplayWeek,
	offset	cs:DisplayWeekYear,
	offset	cs:DisplayMonth,
	offset	cs:DisplayShortMonth,
	offset	cs:DisplayMonthYear,
	offset	cs:DisplayShortMonthYear,
	offset  cs:DisplayShortMonthShortYear,
	offset	cs:DisplayYear,
	offset	cs:DisplayYearText,
	offset	cs:DisplayWeekday,
	offset	cs:DisplayShortWeekday


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayXXXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the size of the GenText, formats the date in the
		correct format and displays it in the GenText.

CALLED BY:	DateSelectorGenerateUI
PASS:		*ds:si	- Object
		cx	- Non zero to set text size
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayLongCondensedDate	proc	near
		.enter
EC <		call	ECCheckObject					>
	;
	; then Input the date
	;
		clr	dx
		mov	ax, DTF_LONG_CONDENSED
		call	UpdateDateText

		.leave
		ret
DisplayLongCondensedDate	endp
;------
DisplayLongDate	proc	near

		clr	dx
		mov	ax, DTF_LONG
		call	UpdateDateText

		ret
DisplayLongDate	endp
;------
DisplayShortDate	proc	near

		clr	dx
		mov	ax, DTF_SHORT
		call	UpdateDateText

		ret
DisplayShortDate	endp
;------
DisplayZPaddedShortDate	proc	near

		clr	dx
		mov	ax, DTF_ZERO_PADDED_SHORT
		call	UpdateDateText

		ret
DisplayZPaddedShortDate	endp
;------
DisplayWeek	proc	near

		mov	ax, FALSE			; no year
		call	UpdateWeekText

		ret
DisplayWeek	endp
;------
DisplayWeekYear	proc	near

		mov	cx, TRUE			; include year
		call	UpdateWeekText

		ret
DisplayWeekYear	endp
;------
DisplayMonth	proc	near

		clr	dx
		mov	ax, DTF_MONTH
		call	UpdateDateText

		ret
DisplayMonth	endp
;------
DisplayShortMonth	proc	near

		mov	ax, offset JS_ShortMonth
		call	UpdateShortMonthText

		ret
DisplayShortMonth	endp
;------
DisplayMonthYear	proc	near

		clr	dx
		mov	ax, DTF_MY_LONG		
		call	UpdateDateText

		ret
DisplayMonthYear	endp
;------
DisplayShortMonthYear	proc	near

		mov	ax, offset JS_ShortMonthYear
		call	UpdateShortMonthText

		ret
DisplayShortMonthYear	endp
;------
DisplayShortMonthShortYear	proc	near

		mov	ax, offset JS_ShortMonthShortYear
		call	UpdateShortMonthText

		ret
DisplayShortMonthShortYear	endp
;------
DisplayYear	proc	near

		clr	dx
		mov	ax, DTF_YEAR
		call	UpdateDateText

		ret
DisplayYear	endp
;------
DisplayYearText	proc	near

		call	UpdateYearText

		ret
DisplayYearText	endp
;------
DisplayWeekday	proc	near

		clr	dx
		mov	ax, DTF_WEEKDAY
		call	UpdateDateText

		ret
DisplayWeekday	endp
;------
DisplayShortWeekday	proc	near

		push	es, bp
		clr	dx
		mov	ax, -1
		sub	sp, ((TOKEN_LENGTH+2) and 0xfffe)
		mov	bx, sp
		segmov	es, ss
		mov	{byte}es:[bx], TOKEN_DELIMITER
		mov	{word}es:[bx][1], TOKEN_SHORT_WEEKDAY
		mov	{byte}es:[bx][3], TOKEN_DELIMITER
		clr	{byte}es:[bx][4]
		mov	cx, bx	; es:cx = format string

		call	UpdateDateText

		add	sp, ((TOKEN_LENGTH+2) and 0xfffe)
		pop	es, bp
		ret
DisplayShortWeekday	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDateSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the fixed size of the GenText object of the controller.
		The text is centered within the GenText.  You can override
		this default by setting the textWidth field in instance 
		data.

CALLED BY:	(INTERNAL) DateSelectorGenerateUI
PASS:		*ds:si	- Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitDateSelector	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter
EC <		call	ECCheckObject					>
	;
	; First check if we need to display the text frame.
	;
		call	SetTextFrame
	;
	; Check if we have to set the INC/DEC triggers not usable.
	;
		call	SetIncDecTriggersNotUsable
	;
	; Set the default size of the GenText used to display the date.
	;
		call	SetGenTextDefaultWidth

		.leave
		ret
InitDateSelector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a frame around the GenText if 
		HINT_DATE_SELECTOR_DRAW_FRAME is defined on the object.

CALLED BY:	(INTERNAL) InitDateSelector
PASS:		*ds:si - DateSelector object
RETURN:		nothing
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextFrame	proc	near
		uses	ax, si
		.enter
EC <		call	ECCheckObject					>
	;
	; First check if we need to display the text frame.
	;
		mov	ax, HINT_DATE_SELECTOR_DRAW_FRAME
		call	ObjVarFindData
		jnc	done
	;
	; Send the GenText object the HINT_TEXT_FRAME to display the frame.
	;
		mov	dx, size AddVarDataParams
		sub	sp, dx
		mov	bp, sp
		clrdw	ss:[bp].AVDP_data
		clr	ss:[bp].AVDP_dataSize
		mov	ss:[bp].AVDP_dataType, HINT_TEXT_FRAME
		call	GetChildBlockAndFeatures	; bx <- handle
		mov	si, offset DateText
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
		call	ObjMessage
		add	sp, size AddVarDataParams
done:
		.leave
		ret
SetTextFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetIncDecTriggersNotUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If GA_READ_ONLY is set this function the Inc and Dec
		triggers not usable.

CALLED BY:	(INTERNAL) InitDateSelector
PASS:		*ds:si - DateSelector Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetIncDecTriggersNotUsable	proc	near
		uses	ax, si
		.enter
EC <		call	ECCheckObject					>
	;
	; See if we've been set to read-only.
	;
		mov	ax, MSG_GEN_GET_ATTRIBUTES
		call	ObjCallInstanceNoLock	; cl <- GenAttrs
		test	cl, mask GA_READ_ONLY
		jz	done
		
	;
	; Send the Inc trigger MSG_GEN_SET_NOT_USABLE...
	;
		mov	di, offset IncTrigger
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallControlChild
	;
	; ...and now the Dec trigger.
	;
		mov	di, offset DecTrigger
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallControlChild			
done:
		.leave
		ret
SetIncDecTriggersNotUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGenTextDefaultWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the default width of the GenText object used to
		display the date.  The default width varies depending on
		what dateType the DateSelector is set to.

CALLED BY:	(INTERNAL) DSDateSelectorSetDateType InitDateSelector
PASS:		*ds:si - DateSelector Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGenTextDefaultWidth	proc	near
		uses	ax,si
	class	DateSelectorClass
		.enter
EC <		call	ECCheckObject					>
	;
	; Check if the text width was set in the .ui file.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].DSI_textWidth
		tst	ax
		jnz	widthDefined
	;
	; The width is not defined in DSI_testWidth which means we use
	; the default width.
	;
		mov	bx, ds:[di].DSI_dateType
		shl	bx
		mov	ax, cs:[dateSelectorTextWidthTable][bx]
	;
	; Set the correct size of the GenText field
	;
widthDefined:
		sub	sp, size SetSizeArgs
		mov	bp, sp
		or	ax, SST_AVG_CHAR_WIDTHS shl offset SH_TYPE
		mov	ss:[bp].SSA_width, ax
		clr	ss:[bp].SSA_height
		clr	ss:[bp].SSA_count
		mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_UI_QUEUE
		call	GetChildBlockAndFeatures	; bx <- handle
		tst	bx
		jz	noChild
		mov	si, offset DateText
		mov	dx, size SetSizeArgs
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		mov	di, mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
noChild:
		add	sp, size SetSizeArgs

		.leave
		ret
SetGenTextDefaultWidth	endp

	;
	; This table has to be in the same order as DateSelectorType enum.
	;
dateSelectorTextWidthTable	word \
	DS_CONDENSED_SIZE,
	DS_LONG_SIZE,
	DS_SHORT_SIZE,
	DS_ZP_SHORT_SIZE,
	DS_WEEK_SIZE,
	DS_WEEK_YEAR_SIZE,
	DS_MONTH_SIZE,
	DS_SHORT_MONTH_SIZE,
	DS_MONTH_YEAR_SIZE,
	DS_SHORT_MONTH_YEAR_SIZE,
	DS_SHORT_MONTH_SHORT_YEAR_SIZE,
	DS_YEAR_SIZE,
	DS_YEAR_TEXT_SIZE,
	DS_WEEKDAY_SIZE,
	DS_SHORT_WEEKDAY_SIZE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats, Sizes and Displays the date.

CALLED BY:	(INTERNAL) DisplayLongCondensedDate DisplayLongDate
		DisplayMonth DisplayMonthYear DisplayShortDate
		DisplayShortWeekday DisplayWeekday DisplayYear
		DisplayZPaddedShortDate
PASS:		ds:si	- Object
		ds:di	- Instance date
		ax - DateTimeFormat
			if -1, 
			es:cx = format string
		dx - Max chars to use (0 for all)
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateDateText	proc	near
formatOffset	local	nptr		push cx
dateBuffer	local	DateTimeBuffer

	class	DateSelectorClass
		uses	si, dx
		.enter
EC <		call	ECCheckObject					>

	;
	; Get the date from instance data
	;
		push	si, ax
		add	di, offset DSI_date
		call	GetDate			; ax, bx, cl <- date
	;
	; Format the date
	;
		pop	si			; DateTimeFormat

		push	ds
		segmov	ds, es
		segmov	es, ss
		lea	di, ss:[dateBuffer]

		cmp	si, -1
		jne	localFormat
		mov	si, ss:[formatOffset]   ; ds:si = format string
		call	LocalCustomFormatDateTime
		jmp	doneFormatting
localFormat:
		call	LocalFormatDateTime	; es:di <- date string,
						; cx <- size
doneFormatting:
		pop	ds
	;
	; Truncate if desired
	;
		tst	dx
		jz	updateIt
DBCS <		shl	dx, 1					>
		mov	si, dx
		mov	cx, dx		      ; cx <- length
		clr	dx
SBCS <		mov	ss:[dateBuffer][si], dl			>
DBCS <		mov	ss:[dateBuffer][si], dx			>
	;
	; Update the DateText to show today's date
	;
updateIt:
		pop	si				; *ds:si <- Object
		call	ReplaceDateText

		.leave
		ret
UpdateDateText	endp
;-----
ReplaceDateText	proc	near
		push	bp
		movdw	dxbp, esdi		; dx:bp <- date string
		mov	di, offset DateText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallControlChild
		pop	bp
		ret
ReplaceDateText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWeekText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats, Sizes and Displays the week with or without the
		year.

CALLED BY:	(INTERNAL) DisplayWeek DisplayWeekYear
PASS:		ds:si	- Object
		ds:di	- Instance date
		ax - Non zero if include year
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWeekText	proc	near
dateBuffer	local	DateTimeBuffer
	class	DateSelectorClass
		uses	si
		.enter
EC <		call	ECCheckObject					>
	;
	; Get the date from instance data
	;
		push	si, ax
		add	di, offset DSI_date
		call	GetDate			; ax, bx, cl <- date
	;
	; Convert the date into week number
	;
		call	GetWeekNumber		; bx <- week #
	;
	; Format the week
	;
		pop	cx			; Non zero to include year
		segmov	es, ss
		lea	di, ss:[dateBuffer]
		call	FormatWeek		; es:di <- week string
						; cx <- size
	;
	; Update the DateText to show today's date
	;
		pop	si				; *ds:si <- Object
		call	ReplaceDateText

		.leave
		ret
UpdateWeekText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the week text.

CALLED BY:	(INTERNAL) UpdateWeekText
PASS:		es:di	- Buffer for Week text
		ax	- Year
		bx	- Week number
		cx	- Non zero to include the year in text.
RETURN:		es:di	- Week text
		cx	- Length of string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatWeek	proc	near
		uses	ax,bx,dx,si,bp,ds
		.enter
	;
	; Save year data
	;
		push	ax, cx
	;
	; Copy the week string to the buffer
	;
		clr	si
		mov	es:[di], si		; null at begining for StrCat
		mov	si, offset JS_Week
		call	LockStringResource	; ds:si <- ptr to string
		clr	cx			; null-terminated
		call	StrCat
		call	UnlockStringResource
	;
	; Add a space
	;
		mov	ax, C_SPACE
		push	ax
		segmov	ds, ss
		mov	si, sp
		call	StrCat
		pop	ax			; restore stack
	;
	; Convert the week number to text
	;	
		push	di
		call	LocalStringSize		; cx <- Number of bytes - NULL
		add	di, cx
		clr	dx
		mov	ax, bx			; ax <- week number
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	di
	;
	; Do we add the year?
	;
		pop	ax, cx
		tst	cx			; non-zero for year
		jz	done
	;
	; Yes, we do. But first add a comma and space.
	;
		push	ax
		mov	ax, C_COMMA
		push	ax
		segmov	ds, ss
		mov	si, sp
		clr	cx			; null-terminated
		call	StrCat
		pop	ax			; restore stack

		mov	ax, C_SPACE
		push	ax
		segmov	ds, ss
		mov	si, sp
		call	StrCat
		pop	ax			; restore stack

		pop	ax			; year	
		push	di
		call	LocalStringSize		; cx <- Number of bytes - NULL
		add	di, cx
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	di
	;
	; Return the size
	;	
done:
		call	LocalStringSize		; cx <- Number of bytes - NULL

		.leave
		ret
FormatWeek	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateShortMonthText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the custom short month text.

CALLED BY:	(INTERNAL) DisplayShortMonth DisplayShortMonthShortYear
		DisplayShortMonthYear
PASS:		ds:si	- Object
		ds:di	- Instance date
		ax - Offset of Format token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateShortMonthText	proc	near
dateBuffer	local	DateTimeBuffer
	class	DateSelectorClass
		uses	si
		.enter
EC <		call	ECCheckObject					>
	;
	; Lock the token string
	;
		push	ds, si, ds
		mov	si, ax
		call	LockStringResource	; ds:si <- token string
	;
	; Get the date from instance data
	;
		mov	dx, ds			; dx <- segment
		pop	ds			; ds:di <- Instance data
		add	di, offset DSI_date
		call	GetDate			; ax, bx, cl <- date
	;
	; Format the text	
	;
		mov	ds, dx			; ds:si <- token string
		segmov	es, ss
		lea	di, ss:[dateBuffer]	
		call	LocalCustomFormatDateTime
	;
	; Unlock the token string resource
	;
		call	UnlockStringResource
	;
	; Update the GenText with the short month text
	;
		pop	ds, si			; *ds:si - Object
		call	ReplaceDateText

		.leave
		ret
UpdateShortMonthText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateYearText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_DATE_SELECTOR_REPLACE_YEAR text to the output.

CALLED BY:	(INTERNAL) DisplayYearText
PASS:		*ds:si	- Object
		ds:di	- Instance date
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateYearText	proc	near
	class	DateSelectorClass
		.enter
EC <		call	ECCheckObject					>
	;
	; Get the date from instance data
	;
		push	si
		add	di, offset DSI_date
		call	GetDate			; ax, bx, cl <- date
		mov	bp, ax			; cx <- year
	;
	; Send a message to the output requesting a year text.  	
	; A MSG_DATE_SELECTOR_SET_YEAR_TEXT is sent to the DateSelector in
	; response.  The actual formatting of the text is done in the
	; method handler for that message.
	;
		pop	si			; *ds:si - Object
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, segment DateSelectorClass
		mov	di, offset DateSelectorClass
		mov	ax, MSG_DATE_SELECTOR_REPLACE_YEAR_TEXT
		call	GenControlSendToOutputRegs

		.leave
		ret
UpdateYearText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDateSelectorSetDateType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the format of the displayed date.  Forces object
		to redraw itself.

CALLED BY:	MSG_DATE_SELECTOR_SET_DATE_TYPE
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		cx	= DateSelectorType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDateSelectorSetDateType	method dynamic DateSelectorClass, 
					MSG_DATE_SELECTOR_SET_DATE_TYPE
		.enter

		Assert	etype cx DateSelectorType

	;
	; Store value passed to us by user.
	;
		cmp	cx, ds:[di].DSI_dateType
		je	done

		mov	ds:[di].DSI_dateType, cx

	;
	; Resize.
	;
		call	SetGenTextDefaultWidth
		
	;
	; Redraw.
	;
		call	UpdateDateSelectorText
done:		
		.leave
		ret
DSDateSelectorSetDateType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGenControlAddToGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add us to system GCN lists. 

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= DateSelectorClass object
		es 	= segment of DateSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGenControlAddToGcnLists	method dynamic DateSelectorClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		.enter

		call	AddSelfToDateTimeGCNLists
		
		.leave
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		ret
DSGenControlAddToGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGenControlRemoveFromGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name sez it all.

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= DateSelectorClass object
		es 	= segment of DateSelectorClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSGenControlRemoveFromGcnLists	method dynamic DateSelectorClass, 
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		.enter

		call	RemoveSelfFromDateTimeGCNLists

		.leave
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
DSGenControlRemoveFromGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw us if date/time format hath chang'd.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= DateSelectorClass object
		es 	= segment of DateInputClass
		ax	= message #
		cx:dx	= NotificationType
			cx - NT_manuf
			dx - NT_type
		bp	= change specific data (InitFileEntry)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSMetaNotify	method dynamic DateSelectorClass, 
					MSG_META_NOTIFY
	;
	; See if it's the notification we're interested in.
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	callSoup
		cmp	dx, GWNT_INIT_FILE_CHANGE
		jne	callSoup

	;
	; We need to redraw if the time format has changed.
	;
		cmp	bp, IFE_DATE_TIME_FORMAT
		jne	exit
		call	UpdateDateSelectorText

exit:
		ret

callSoup:
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
DSMetaNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSSpecActivateObjectWithMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is send when ever the user enters the keyboard
		mnemonic for this control.  We call supercalls if the 
		activation was a success when we pass the the focus and
		target to the GenText.

CALLED BY:	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
		ds:bx	= DateInputClass object (same as *ds:si)
		es 	= segment of DateInputClass
		ax	= message #
RETURN:		carry set if found, clear otherwise.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSSpecActivateObjectWithMnemonic	method dynamic DateSelectorClass, 
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		uses	ax, cx, dx, bp
		.enter
	;
	; Call superclass.  If the mnemonic is a match the carry is set.
	;
		mov	di, offset DateSelectorClass
		call	ObjCallSuperNoLock
		jnc	done
	;
	; We have a match.  Send MSG_GEN_MAKE_FOCUS to the GenText object.
	;
	;	mov	di, offset DateText
		mov	ax, MSG_GEN_MAKE_FOCUS		
		call	ObjCallInstanceNoLock
		stc					; return carry
done:
		.leave
		ret
DSSpecActivateObjectWithMnemonic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSSpecNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we don't get focus if hint tells us so.

CALLED BY:	MSG_SPEC_NAVIGATION_QUERY
PASS:		*ds:si	= RepeatTriggerClass object
		es 	= segment of RepeatTriggerClass
		ax	= message #
		^lcx:dx	= object which originated this query
		bp	= NavigateFlags (see below)
RETURN:		carry set if object to give focus to, with:
			^lcx:dx	= object which is replying
		else
			^lcx:dx = next object to query
		bp	= NavigateFlags (will be altered as message is
			  passed around)
		al	= set if the object is focusable via backtracking
			  (i.e. can take the focus if it is previous to the
			  originator in backwards navigation)
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSSpecNavigationQuery	method dynamic DateSelectorClass,
					MSG_SPEC_NAVIGATION_QUERY
		.enter

		mov	ax, HINT_DATE_SELECTOR_NOT_FOCUSABLE
		call	ObjVarFindData		  ; ds:bx <- data
		mov	bl, mask NCF_IS_FOCUSABLE ; assume focusable
		jnc	navigate
		clr	bl			  ; hint found
navigate:
		mov	di, si
		call	VisNavigateCommon

		.leave
		ret

DSSpecNavigationQuery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSMetaGainedSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows the object with the focus

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		ds:bx	= DateSelectorClass object (same as *ds:si)
		es 	= segment of DateSelectorClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSMetaGainedSysFocusExcl	method dynamic DateSelectorClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL
	uses	ax
	.enter

		mov	al, MM_COPY
		call	DSDrawFocusNoGState

		mov	ax, TEMP_DATE_SELECTOR_HAS_FOCUS
		clr	cx
		call	ObjVarAddData

	.leave
	mov	di, offset @CurClass
	GOTO	ObjCallSuperNoLock

DSMetaGainedSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSMetaLostSysFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_LOST_SYS_FOCUS_EXCL
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		ds:bx	= DateSelectorClass object (same as *ds:si)
		es 	= segment of DateSelectorClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSMetaLostSysFocusExcl	method dynamic DateSelectorClass, 
					MSG_META_LOST_SYS_FOCUS_EXCL
	uses	ax
	.enter
	;
	; Erase focus
	;
		mov	al, MM_CLEAR
		call	DSDrawFocusNoGState

		mov	ax, TEMP_DATE_SELECTOR_HAS_FOCUS
		call	ObjVarDeleteData

	.leave
	mov	di, offset @CurClass
	GOTO	ObjCallSuperNoLock

DSMetaLostSysFocusExcl	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDrawFocusNoGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the focus on an object.  Creates its own gstate

CALLED BY:	
PASS:		al	= Mix mode in which to draw focus
		*ds:si	= DateSelector object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDrawFocusNoGState	proc	near
	uses	ax,cx,dx,bp,di
	.enter
		push	ax
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock     ; bp <- gstate
		pop	ax
		jnc	done
	;
	; How about a dotted box?
	;
		mov	di, bp
		call	GrSetMixMode

		call	DSDrawFocus
		call	GrDestroyState
done:
	.leave
	ret
DSDrawFocusNoGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSDrawFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws graphics to indicate focus on DateSelector

CALLED BY:	
PASS:		di = GState to draw into
		*ds:si = DateSelector object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSDrawFocus	proc	near
	uses	ax, bx, cx, dx, bp
	.enter

	;
	; Get text object bounds
	;
		push	di
		mov	ax, MSG_VIS_GET_BOUNDS
		mov	di, offset DateText
		call	ObjCallControlChild	  ; ax,bp,cx,dx <- l,t,r,b
		tst	bx	
		jz	noChild
		mov_tr	bx, bp
		dec	cx
		dec	dx
	;
	; Tweak bounds if certain hints exist
	;
		push	ax, bx
		mov	ax, HINT_DATE_SELECTOR_DRAW_FRAME
		call	ObjVarFindData
		pop	ax, bx
		jnc	draw

		inc	ax	; Text frame exists: bring focus box in 1 pixel
		inc	bx
		dec	cx
		dec	dx
draw:
		pop	di
	;
	; Draw box
	;
		call	GrSaveState

		mov_tr	bp, ax		
		mov	al, SDM_50
		call	GrSetLineMask
		mov_tr	ax, bp
		call	GrDrawRect

		call	GrRestoreState
done:
	.leave
	ret

noChild:
		pop	di
		jmp	done

DSDrawFocus	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If object has system focus, draw it so.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= DateSelectorClass object
		ds:di	= DateSelectorClass instance data
		ds:bx	= DateSelectorClass object (same as *ds:si)
		es 	= segment of DateSelectorClass
		ax	= message #
		cl	= DrawFlags
		bp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSVisDraw	method dynamic DateSelectorClass, 
					MSG_VIS_DRAW
		push	bp
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	; If we currently have the focus, then draw the focus lines
	;
		mov	ax, TEMP_DATE_SELECTOR_HAS_FOCUS
		call	ObjVarFindData
		jnc	done

		mov	di, bp
		call	GrSaveState
		mov	al, MM_COPY
		call	GrSetMixMode
		call	DSDrawFocus
		call	GrRestoreState
done:
		ret
DSVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSMetaKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent out on any keyboard press or release.  We need
		to subclass this message to catch the arrow-up and arrow_down
		keystrokes. We then send a message to increment or decrement
		the date to the DateInput control.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= DateInputTextClass object
		ds:di	= DateInputTextClass instance data
		ds:bx	= DateInputTextClass object (same as *ds:si)
		es 	= segment of DateInputTextClass
		ax	= message #
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSMetaKbdChar	method dynamic DateSelectorClass, MSG_META_KBD_CHAR
	;
	; Ignore key releases.
	;
		test	dl, mask CF_RELEASE
		jnz	callSuper
	;
	; See if it's a character we're interested in.  Make sure that
	; the desired ctrl/shift/whatever key is also being pressed.
	;
		mov	bx, (offset dsKeymap) - (size KeyAction)
		mov	di, (offset dsKeymap) + (size dsKeymap)
		call	KeyToMsg		; ax <- message to send
		jc	callSuper

	;
	; Send message associated with the action.
	;
		GOTO	ObjCallInstanceNoLock

		
callSuper:
		mov	ax, MSG_META_KBD_CHAR
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
DSMetaKbdChar	endm

GadgetsSelectorCode ends
