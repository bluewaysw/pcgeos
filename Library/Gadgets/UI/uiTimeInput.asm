COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Time Input Gadget
FILE:		uiTimeInput.asm

AUTHOR:		Skarpi Hedinsson, Jul  6, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT TISelectAllText         Name says it all.

    INT SendTIActionMessage     Sends the action message (TII_actionMsg) to
				the output (GCI_output).

    INT IntervalAutoCompletion  Fills in the interval time of fields with 1
				char entered.

    INT IntervalAutoCompletion  Fills in the interval time of fields with 1
				char entered.

    INT TimeAutoCompletion      Fills in the time for fields with at least
				1 number entered.

    INT CharIsNull              The number terminator was a null.  This
				means that the number preceding the null is
				the hour.

    INT CharIsP                 The number terminator was a p or P.  This
				means that the number the user entered
				before the P should be PM.

    INT CharIsA                 The number terminator was a or A. This
				means that the number should be AM.

    INT CharIsSpace             The number terminator is a space. We have
				to ignore this space and continue. We need
				this do deal with: 12:00 AM etc.

    INT CharIsTimeSeparator     Extract the minutes from the time string.

    INT ConvertTextToNumber     Converts a text number to a int number.
				Given a string es:di the function will scan
				it until it finds a non-digit and convert
				the preceding text to number.

    INT TimeInputUpdateText     Displays the current time in the TIText
				GenText object.

    INT ReplaceTIText           Replace text in the text object.

    INT TimeInputFormatTime     Formats the time correctly depending on the
				TII_timeType.

    INT TimeInputParseTime      Does the reverse of TimeInputFormatTime.
				This function parses a time string and
				returns the time in registers.

    INT SetTime                 Copies the time (in ch and dx) to a
				TimeStruct pointed to by ds:si.

    INT GetTime                 Copies the time from a TimeStruct pointed
				to by ds:si to ch and dx.

    INT TISetAMPMMode           Look in the .INI file and figure and reset
				our notion of whether or not the AM/PM-ness
				has changed.

    INT TISendApplyMsg          Complete text and send out the apply
				message.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 6/94   	Initial revision


DESCRIPTION:
	Implementation of TimeInputClass.
		

	$Id: uiTimeInput.asm,v 1.1 97/04/04 17:59:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsClassStructures	segment resource

	TimeInputClass		; declare the control class record

GadgetsClassStructures	ends

;---------------------------------------------------

GadgetsSelectorCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TimeInputGetInfo --
		MSG_GEN_CONTROL_GET_INFO for TimeInputClass

DESCRIPTION:	Return group

PASS:
	*ds:si 	- instance data
	es 	- segment of TimeInputClass
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
TimeInputGetInfo	method dynamic	TimeInputClass, 
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TIC_dupInfo
	call	CopyBuildInfoCommon
	ret
TimeInputGetInfo	endm

TIC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0, 				; GCBI_initFileKey
	0, 				; GCBI_gcnList
	0, 				; GCBI_gcnCount
	0, 				; GCBI_notificationList
	0, 				; GCBI_notificationCount
	0, 				; GCBI_controllerName

	handle TimeInputUI, 		; GCBI_dupBlock
	TIC_childList, 			; GCBI_childList
	length TIC_childList, 		; GCBI_childCount
	TIC_featuresList, 		; GCBI_featuresList
	length TIC_featuresList, 	; GCBI_featuresCount
	TI_DEFAULT_FEATURES, 		; GCBI_features

	0, 				; GCBI_toolBlock
	0, 				; GCBI_toolList
	0, 				; GCBI_toolCount
	0, 				; GCBI_toolFeaturesList
	0, 				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

GadgetsControlInfo	segment resource

TIC_childList	GenControlChildInfo	\
   <offset TimeInputGroup, mask TIF_DATE, mask GCCF_ALWAYS_ADD>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TIC_featuresList	GenControlFeaturesInfo	\
	<offset TimeInputGroup, offset TimeInputName, 0>

GadgetsControlInfo	ends


COMMENT @----------------------------------------------------------------------

MESSAGE:	TimeInputGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for TimeInputClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the filled/unfilled items

PASS:
	*ds:si - instance data
	es - segment of TimeInputClass
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
   	PBuck	03/24/95	Added ATTR_DATE_INPUT_TARGETABLE handler

------------------------------------------------------------------------------@
TimeInputGenerateUI		method dynamic	TimeInputClass, 
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Call the superclass
	;
		mov	di, offset TimeInputClass
		call	ObjCallSuperNoLock
	;
	; Set up the text object to be targetable if so specified
	;
		mov	ax, ATTR_TIME_INPUT_TARGETABLE
		call	ObjVarFindData
		jnc	afterTarget
		mov	di, offset TIText
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallControlChild
		clr	ch
		mov	cl, mask GA_TARGETABLE
		mov	ax, MSG_GEN_SET_ATTRS
		call	ObjCallControlChild
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallControlChild

afterTarget:
	;
	; If the do draw/don't draw feature isn't set, then we have no worries
	;
		call	GetChildBlockAndFeatures	; bx <- handle
		test	ax, mask TIF_DATE
   		LONG_EC	jz	done

	;
	; Deal with AM/PM mode.
	;
		call	TISetAMPMMode

	;
	; Set up the text object to display custom string when empty,
	; if vardata so requires it.
	;
		mov	ax, ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY
		call	ObjVarFindData		; stc -> ds:bx <- ptr to optr
		jnc	noString
		mov	dx, ds:[bx].handle
		mov	bp, ds:[bx].offset	; ^ldx:bp <- string to draw
		mov	di, offset TIText
		mov	ax, MSG_TIME_INPUT_TEXT_DISPLAY_STRING_WHEN_EMPTY
		call	ObjCallControlChild
noString:
	;
	; Set the TimeInputTime of TimeInputTextClass to be the same as
	; as TimeInputClass.  This is done so the correct filter routine
	; is called when the TimeInputType is not TIT_TIME_OF_DAY.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	cx, ds:[di].TII_timeType
		mov	di, offset TIText
		mov	ax, MSG_TIME_INPUT_TEXT_SET_TIME_TYPE
		call	ObjCallControlChild

	;
	; If the time in instance data is all -1 then we set the time to
	; the current time.  Else we display the time in instance data.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset TII_time
		call	GetTime				; ch <- hour
		cmp	ch, -1
		je	setCurrent
	;
	; Set the GenText to display the time in TII_time.
	;
		call	TimeInputUpdateText
done:
		.leave
		ret
	;
	; Update TIText to be the current system time.
	;
setCurrent:
		mov	ax, MSG_TIME_INPUT_SET_CURRENT_TIME
		call	ObjCallInstanceNoLock
		jmp	done

TimeInputGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIGenControlAddToGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add us to system GCN lists. 

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= controller object
		es 	= segment of class
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
TIGenControlAddToGcnLists	method dynamic TimeInputClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		.enter

		call	AddSelfToDateTimeGCNLists
		
		.leave
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
TIGenControlAddToGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TISpecActivateObjectWithMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent whenever the user enters the keyboard
		mnemonic for this control.  We call superclass if the 
		activation was a success when we pass the the focus and
		target to the GenText.

CALLED BY:	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
PASS:		*ds:si	= TimeInputClass object
		ds:di	= TimeInputClass instance data
		es 	= segment of TimeInputClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState (ModBits)
		bp low	= ToggleState
		bp high = scan code
RETURN:		carry set if mnemonic found
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TISpecActivateObjectWithMnemonic	method dynamic TimeInputClass, 
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		.enter
	;
	; Call superclass.  If the mnemonic is a match the carry is set.
	;
		mov	di, offset TimeInputClass
		call	ObjCallSuperNoLock
		jnc	done

	;
	; We have a match.  Send MSG_GEN_MAKE_FOCUS to the GenText object.
	;
		mov	di, offset TIText
		mov	ax, MSG_GEN_MAKE_FOCUS
		call	ObjCallControlChild
		stc					; return carry

done:
		.leave
		ret
TISpecActivateObjectWithMnemonic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIMetaGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass focus on to the GenText.  If we don't do this,
		then explicitly sending focus grab to us won't work.

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL
PASS:		*ds:si	= TimeInputClass object
		es 	= segment of TimeInputClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIMetaGainedFocusExcl	method dynamic TimeInputClass, 
					MSG_META_GAINED_FOCUS_EXCL
		.enter
	;
	; Call superclass.
	;
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

	;
	; Pass focus on to subclass.
	;
		mov	di, offset TIText
		mov	ax, MSG_GEN_MAKE_FOCUS
		call	ObjCallControlChild

		.leave
		ret
TIMetaGainedFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITimeIncDec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment/decrement the time by incrementValue or
		incrementAltValue.

CALLED BY:	MSG_TI_TIME_INC, MSG_TI_TIME_DEC, MSG_TI_TIME_ALT_DEC,
		MSG_TI_TIME_ALT_INC
PASS:		*ds:si	= TimeInputClass object
		ds:di	= TimeInputClass instance data
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Updates the TII_time instance data.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITimeIncDec	method dynamic TimeInputClass, 
					MSG_TI_TIME_INC,
					MSG_TI_TIME_DEC,
					MSG_TI_TIME_ALT_DEC,
					MSG_TI_TIME_ALT_INC
		uses	ax, cx, dx, bp
		.enter
	;
	; First parse the text in the text object and save the data to
	; instance data.
	;
		push	ax			; #1 save msg
		mov	ax, MSG_TI_PARSE_TIME_STRING
		call	ObjCallInstanceNoLock

	;
	; Determine increment amount from message sent.
	;
		pop	ax			; #1 ax <- msg

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].TII_timeType	; bx <- time type
	;
	; If TIT_TIME_OF_DAY and time == NONE_VALUE, then disallow inc/dec
	;
		cmp	bx, TIT_TIME_OF_DAY
		jne	carryOn

		cmp	ds:[di].TII_time.T_hours, NONE_VALUE
		je	done
carryOn:
		cmp	ax, MSG_TI_TIME_ALT_DEC
		je	altValue
		cmp	ax, MSG_TI_TIME_ALT_INC
		je	altValue
		mov	cx, ds:[di].TII_incrementValue	; cx <- value
		jmp	valueFound
altValue:
		mov	cx, ds:[di].TII_incrementAltValue	; cx <- value
valueFound:
	;
	; Increment/decrement the time by incrementValue based on which
	; message wuz actually sent.
	;
		add	di, offset TII_time	; ds:di <- time struct to alter
		cmp	ax, MSG_TI_TIME_INC
		je	incTime
		cmp	ax, MSG_TI_TIME_ALT_INC
		je	incTime

	;
	; Make sure we call the right decrement procedure
	;
		cmp	bx, TIT_TIME_OFFSET
		jne	decRegular

		call	DecrementOffsetTime
		jmp	incDecDone
		
decRegular:
		call	DecrementTime
		jmp	incDecDone
	;
	; Make sure we call the right increment procedure
	;
incTime:
		cmp	bx, TIT_TIME_OFFSET
		jne	incRegular

		call	IncrementOffsetTime
		jmp	incDecDone

incRegular:
		call	IncrementTime
incDecDone:

	;
	; Display the new time.
	;
		call	TimeInputUpdateText

	;
	; Select all text, so we act like a GenValue.
	;
		call	TISelectAllText

	;
	; Send message letting the output know the time has changed
	;
		call	SendTIActionMessage
done:
		.leave
		ret
TITimeIncDec	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIParseTimeStringIfModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the text has been modified by the user,
		then re-parse the string.

CALLED BY:	
PASS:		*ds:si = DateInput object
RETURN:		carry set if string not valid.
		ds fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

		This could move the object block around.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	6/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIParseTimeStringIfModified	proc	near
	uses	ax, di, bx
	.enter
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		mov	di, offset TIText
		call	ObjCallControlChild	; carry set if modified,
						; bx = 0 if no child
		lahf
		tst	bx
		clc				 ; no child? no problem!
		jz	done
		sahf
		jnc	done

		mov	ax, MSG_TI_PARSE_TIME_STRING
		call	ObjCallInstanceNoLock	 ; sets carry
done:
	.leave
	ret
TIParseTimeStringIfModified	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TISelectAllText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all.

CALLED BY:	(INTERNAL) TITimeIncDec
PASS:		*ds:si	= control object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TISelectAllText	proc	near
		.enter

		mov	di, offset TIText
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjCallControlChild

		.leave
		ret
TISelectAllText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TISetCurrentTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the TII_time value to be the current system time.

CALLED BY:	MSG_TIME_INPUT_SET_CURRENT_TIME
PASS:		*ds:si	= TimeInputClass object
		ds:di	= TimeInputClass instance data
		ds:bx	= TimeInputClass object (same as *ds:si)
		es 	= segment of TimeInputClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TISetCurrentTime	method dynamic TimeInputClass, 
					MSG_TIME_INPUT_SET_CURRENT_TIME
		uses	ax, cx, dx, bp
		.enter
	;
	; Do nothing if we're not in time-of-day mode.
	;
		cmp	ds:[di].TII_timeType, TIT_TIME_OF_DAY
		jne	exit
		
	;
	; Get the current time
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
		add	di, offset TII_time
		call	SetTime

	;
	; Update the GenText with the current date
	;
		call	TimeInputUpdateText

exit:
		.leave
		ret
TISetCurrentTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TISetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent to the TimeInput to change the current
		displayed time.

CALLED BY:	MSG_TIME_INPUT_SET_TIME
PASS:		*ds:si	= TimeInputClass object
		ds:di	= TimeInputClass instance data
		ds:bx	= TimeInputClass object (same as *ds:si)
		es 	= segment of TimeInputClass
		ax	= message #
		ch	= hours
		dl	= minutes
		dh	= seconds
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TISetTime	method dynamic TimeInputClass, 
					MSG_TIME_INPUT_SET_TIME
		uses	ax, cx, dx, bp
		.enter
	;
	; Hack: to support !@#$%^& ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY,
	; we erase all text in the !@#$%^& text object if the user passes
	; -2 to us in the "hours" field.
	;
if 0
		mov	ax, ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY
		call	ObjVarFindData		; stc if found
		jnc	nevermind
		cmp	ch, NONE_VALUE
		jne	nevermind
		mov	di, offset TIText
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjCallControlChild
		jmp	exit
endif
	;
	; First change the instance data TII_time to reflect the new time
	;	
nevermind::
		add	di, offset TII_time
		call	SetTime
	;
	; Now update the time in the GenText
	;
		call	TimeInputUpdateText

exit::
		.leave	
		ret
TISetTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIGetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current time of the TimeInput.

CALLED BY:	MSG_TIME_INPUT_GET_TIME
PASS:		*ds:si	= TimeInputClass object
		ds:di	= TimeInputClass instance data
		es 	= segment of TimeInputClass
		ax	= message #
RETURN:		ch	= hour
		dl	= minutes
		dh	= seconds
DESTROYED:	cl
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIGetTime	method dynamic TimeInputClass, 
					MSG_TIME_INPUT_GET_TIME
		uses	ax, bp
		.enter
	;
	; Act like a GenValue: first expand out the currently entered
	; thing.  But only if we are built out, and the text has been
	; modified.
	;
		call	TIParseTimeStringIfModified
	;
	; Get the time from instance data
	;
		mov	di, ds:[si]
		add	di, ds:[di].TimeInput_offset
		add	di, offset TII_time
		call	GetTime			; ch, dx <- time

		.leave
		ret
TIGetTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITimeInputRedisplayTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces the time to be redisplayed, using the current
		time format.

CALLED BY:	MSG_TIME_INPUT_REDISPLAY_TIME
PASS:		*ds:si	= TimeInputClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITimeInputRedisplayTime	method dynamic TimeInputClass, 
					MSG_TIME_INPUT_REDISPLAY_TIME
 		.enter
 
 		call	TimeInputUpdateText
 
 		.leave
 		ret
TITimeInputRedisplayTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITimeInputSetIncrementValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the TII_incrementValue which is used when incrementing
		or decrementing the time.

CALLED BY:	MSG_TIME_INPUT_SET_INCREMENT_VALUE
PASS:		ds:di	= TimeInputClass instance data
		cx	= Increment value
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITimeInputSetIncrementValue	method dynamic TimeInputClass, 
					MSG_TIME_INPUT_SET_INCREMENT_VALUE
	;
	; Set TII_incrementValue
	;	
		mov	ds:[di].TII_incrementValue, cx
		ret
TITimeInputSetIncrementValue	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITimeInputGetIncrementValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the TII_incrementValue used when incrementing or
		decrementing the time.

CALLED BY:	MSG_TIME_INPUT_GET_INCREMENT_VALUE
PASS:		ds:di	= TimeInputClass instance data
RETURN:		cx	= Increment value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITimeInputGetIncrementValue	method dynamic TimeInputClass, 
					MSG_TIME_INPUT_GET_INCREMENT_VALUE
	;
	; Return TII_incrementValue
	;
		mov	cx, ds:[di].TII_incrementValue
		ret
TITimeInputGetIncrementValue	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTIActionMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the action message (TII_actionMsg) to the output 
		(GCI_output).

CALLED BY:	(INTERNAL) TIMetaTextLostFocus, TITimeIncDec
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendTIActionMessage	proc	near
		uses	ax, bx, cx, dx, si, di, bp
	class	TimeInputClass
		.enter
EC <		call	ECCheckObject					>
	;
	; First get the current time
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	di
		add	di, offset TII_time
		call	GetTime		; ch, dx <- time
		pop	di		; ds:di <- instance data
	;
	; Get the action message and destination from instance data and
	; send message.
	;
		mov	ax, ds:[di].TII_actionMsg	; ax <- msg to send
		mov	bx, segment @CurClass
		mov	di, offset @CurClass
		call	GadgetOutputActionRegs

		.leave
		ret
SendTIActionMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIParseTimeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses the time string in TIText and stores the time value
		in TII_time.

CALLED BY:	MSG_TI_PARSE_TIME_STRING
PASS:		*ds:si	= TimeInputClass object
		ds:di	= TimeInputClass instance data
RETURN:		carry	= set if parse not valid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIParseTimeString	method dynamic TimeInputClass, 
					MSG_TI_PARSE_TIME_STRING
		uses	ax, cx, dx, bp
		.enter
	;
	; Get the text from the GenText
	;	
		sub	sp, size DateTimeBuffer
		mov	dx, ss
		mov	bp, sp			; dx:bp <- buffer for text
		mov	di, offset TIText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallControlChild	; cx <- length,
				                ; bx = 0 if no child
		tst	bx
		jz	doneValid

	;
	; Do the auto-completion.  The auto-completion function called is
	; determined by TII_timeType.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].TII_timeType
		Assert	etype bx TimeInputType
		shl	bx
		mov	es, dx
		mov	di, bp			; es:di <- string to parse
		call	cs:[autoCompletionTable][bx]
		jc	notValid

	;
	; Parse the text into a valid time
	;
		call	TimeInputParseTime
		jnc	notValid

	;
	; Update the instance data with the new date...
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset TII_time
		call	SetTime

doneValid:
	;
	; Restore the stack
	;
		add	sp, size DateTimeBuffer

	;
	; The parse was valid so we clear the carry
	;
		clc
done:
		pushf
		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		clr	cx
		mov	di, offset TIText
		call	ObjCallControlChild
		popf

		.leave
		ret
notValid:
	;
	; Time in GenText is not a valid date, we therefore do not update
	; the TII_time.  First we will sound the alarm indicating the date
	; is not valid.
	;
		mov	ax, SST_ERROR
		call	UserStandardSound

	;
	; Restore the "old" date in the GenText object.
	;
		call	TimeInputUpdateText

	;
	; Restore the stack
	;
		add	sp, size DateTimeBuffer

	;
	; The parse was no good so we return a carry
	;
		stc
		jmp	done

TIParseTimeString	endm

autoCompletionTable	nptr.near \
	offset	cs:TimeAutoCompletion,		; TIT_TIME_OF_DAY
	offset	cs:IntervalAutoCompletion,	; TIT_TIME_INTERVAL
	offset	cs:OffsetAutoCompletion		; TIT_TIME_OFFSET

.assert (length autoCompletionTable) eq (TimeInputType)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntervalAutoCompletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills in the interval time of fields with 1 char entered.

CALLED BY:	TIParseTimeString
PASS:		es:di	- Time String in DTF_HM format
		cx	- String length
		*ds:si	- Object
RETURN:		es:di	- Time string auto-completed
		carry set if error, clear if not
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IntervalAutoCompletion	proc	near
		uses	ax, bx, cx, dx, si, di
		.enter

EC <		call	ECCheckObject					>


		call	IntervalAutoCompletionLow
		jc	exit

		call	ReplaceTIText
		clc

exit:
		.leave
		ret
IntervalAutoCompletion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IntervalAutoCompletionLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Completes the string for Interval times.
		This code is also common to Time Offset Completions,
		so it will be used by both of them

CALLED BY:	(INTERNAL) IntervalAutoCompletion, OffsetAutoCompletion
PASS:		es:di	= Time String in DTF_HM format
		cx	= String length
		*ds:si	= Object
RETURN:		es:di	= Time string auto-completed
		cx	= new length
		carry will be set if error, cx will be trashed
DESTROYED:	nothing
SIDE EFFECTS:	This procedure will not update the text object.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ACJ	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IntervalAutoCompletionLow	proc	near

		uses	ax,bx,dx,si,di,bp
		.enter

EC <		call	ECCheckObject					>

		mov	bp, di			; bp <- save buffer offset
		
	;
	; If the first char is not a digit, it must be the separator, in
	; which case we want to assume that what's to the right of it
	; is the number of minutes.
	;
		clr	ax, dx			; dx <- 0 hours
		LocalGetChar	ax, esdi, NO_ADVANCE
;;		mov	al, es:[di]
		call	LocalIsDigit
		jz	notNull

	;
	; Get the first number -- it may be the only one.
	;
		call	ConvertTextToNumber	; dx <- number

	;
	; Conversion could only have stopped for two reasons, a null or
	; a time separator.  But which one?
	;
;;		cmp	{byte} es:[di], C_NULL
		LocalCmpChar	es:[di], C_NULL
		jne	notNull

	;
	; At this point dx is the number of MINUTES.  If the number is
	; greater than 60, the MINUTES need to be converted to hours:minutes.
	;
		clr	ch			; assume 0 hours, ?? minutes
		cmp	dx, 60
		jb	formatTime

	;
	; Ok, now, if the user entered minutes > 1439 (23:59), just cap
	; off the value at 23:59 (just like the 200LX).
	;
		mov	ax, dx			; ax <- minutes
		mov	ch, 23			; ch <- 23 hours
		mov	dl, 59			; dl <- 59 minutes
		cmp	ax, (23 * 60) + 59
		ja	formatTime

	;
	; Format the minutes into hours:minutes by division.
	;
		clr	dx			; clear high word of numerator
		mov	bx, 60			; bx <- denominator
		div	bx			; ax <- quotient, dx <- rem
		mov	ch, al			; ch <- hours
		jmp	formatTime

	;
	; The conversion did not stop on a null so it must be on the
	; separator. Since there's a separator, the number to the left is
	; the number of hours.  If it's > 23, then top the whole thing
	; off at 23:59.
	;
notNull:
		mov	ax, dx			; ax <- # hours
		mov	ch, 23			
		mov	dl, 59
		cmp	ax, 23
		ja	formatTime
		mov	ch, al			; ch <- hours

	;
	; Get the number of minutes (whatever's after the separator).
	;
		push	ds, si			; #2
		inc	di			; es:di <- rest of string
		movdw	dssi, esdi		; ds:si <- string
		call	ConvertTextToNumber	; dx <- entered # of minutes
		pop	ds, si			; #2

	;
	; Cap minutes at 59.
	;
		cmp	dx, 60
		jb	formatTime
		mov	dl, 59

formatTime:
EC <		cmp	ch, 23						>
EC <		ERROR_A	-1						>
EC <		cmp	dl, 59						>
EC <		ERROR_A	-1						>
		mov	di, bp			; es:di <- buffer
		call	TimeInputFormatTime	; carry set if error
		
		.leave
		ret

IntervalAutoCompletionLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OffsetAutoCompletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills in the time offset field when only partially
		complete data has been added.

CALLED BY:	TIParseTimeString
PASS:		es:di	= Time String in DTF_HM format
		cx	= String length
		*ds:si	= Object
RETURN:		es:di	= Time string auto-completed.
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

		Since is almost exactly like the IntervalAutoCompletion,
		We're just going to make sure that if the negative
		sign is in front, that we just auto-complete the rest of
		the string.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ACJ	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
offsetCompletionException	char	"-0", C_NULL
OffsetAutoCompletion	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	;
	; Check if the first character is a negative sign.
	; If so we'll just pass everything after that to
	; IntervalAutoCompletion.
	;
	; We will also use bp as a flag to see if we incremented the
	; the string ptr past the minus sign so we know if we should
	; decrement the string ptr
	;
		mov	bp, BW_FALSE			; we didn't increment
		LocalCmpChar	es:[di], C_MINUS
		jnz	autoComplete

		LocalNextChar	esdi
		mov	bp, BW_TRUE
autoComplete:
	;
	; Auto complete our string.
	;
		call	IntervalAutoCompletionLow	; es:di = completed
							; cx = string length
		jc	done			 ; Error

	;
	; Revert the ptr (es:di) back to the begining of the string
	; if we incremented it past the minus sign
	;
.assert		0 eq BW_FALSE
		tst	bp
		jz	checkException

		LocalPrevChar	esdi
		
	;
	; There's one exception.  This stuff might auto-complete to "-0"
	; If that happens, then lets just make it "0"
	;
checkException:
		pushdw	dssi
		segmov	ds, cs
		mov	si, offset offsetCompletionException
		clr	cx
FXIP <		call	SysCopyToStackDSSI	;ds:si = format on stack >
		call	LocalCmpStrings
FXIP <		call	SysRemoveFromStack	;release stack space	>
		popdw	dssi
		
		jnz	replaceText

	;
	; Instead of "-0", we're going to write "0" in it's place.
	;
		push	di		; save offset to buffer
		LocalLoadChar	ax, C_ZERO
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_NULL
		LocalPutChar	esdi, ax
		pop	di		; restore offset to buffer

	;
	; Replace the text in the text object
	;
replaceText:
		call	ReplaceTIText
		clc				; success!

done:
		.leave
		ret
OffsetAutoCompletion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeAutoCompletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fills in the time for fields with at least 1 number entered.

CALLED BY:	TIParseTimeString
PASS:		es:di	- time string in DTF_HM format
		cx	- string length
		*ds:si	- Object
RETURN:		es:di	- Time string auto-completed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Here are the rules:

		1p	=  1:00pm : no minute specified, assumes '00' min.
		8a	=  8:00am : 'a' or 'p' specified, fills in the 'm'.
		9	=  9:00am : am/pm not specified, for '9, 10 & 11'
                                     fills in 'am', other numbers 'pm'.
		0	= 12:00am : 0 hour assumes 12:00am (midnight).
		10:5	= 10:50am : single digit minute, for 0 to 5 assumes
				    '00' to '50'.
		10:6	= 10:06am : single digit minute, for 6 to 9 assumes
				    '06' to '09'.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeAutoCompletion	proc	near
		class	TimeInputClass
		uses	ax, bx, cx, dx, si, di
bufferOffset	local	nptr.char	push di
ampmMode	local	BooleanWord		
		.enter

EC <		call	ECCheckObject					>

	;
	; Figure out if we're in AM/PM mode.
	;
		push	di			; #1
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].TII_ampmMode
		mov	ss:ampmMode, ax
		pop	di			; #1
		
	;
	; Check if the first char is a number.  If not there is nothing
	; we can do.
	;
		LocalGetChar	ax, esdi, NO_ADVANCE
		clr	ah			; ARGH!
		call	LocalIsDigit
		stc				; assume error
		jz	doneHaveError	

	;
	; Get the first number
	;
		call	ConvertTextToNumber	; dx <- number

	;
	; Find why the conversion stopped and deal with it
	;
		mov	cx, (length validTerminators) - 1
						; cx <- # of validTerminators
topLoop:
		mov	bx, cx
		mov	al, cs:[validTerminators][bx]
		cmp	al, es:[di]
		je	found
		loop	topLoop
	;
	; The terminator was not found so we check if it is the system
	; time separator
	;
		call	GetSystemTimeSeparator	; ax <- system time separator
		cmp	al, es:[di]
		stc				; assume error
		jne	doneHaveError		; this is bogus
		mov	bx, (length termTable - 1)
						; to call CharIsTimeSeparator
	;
	; The terminator was found; now call the correct function to continue 
	;
found:
		shl	bx
		call	cs:[termTable][bx]	; ch, dx <- time
		jmp	formatTime

doneHaveError:
		.leave
		ret

	;
	; Replace the TIText GenText object with the auto-completed text
	;
formatTime:
		mov	di, ss:[bufferOffset]	; es:di <- buffer
		call	TimeInputFormatTime
		call	ReplaceTIText
		clc				; no error
		jmp	doneHaveError

TimeAutoCompletion	endp

validTerminators	char \
			C_NULL,			; should never be reached
			C_NULL,
			C_SMALL_P,
			C_CAP_P,
			C_SMALL_A,
			C_CAP_A,
			C_SPACE

termTable	nptr.near	\
	offset	cs:CharIsNull, 
	offset	cs:CharIsNull, 
	offset	cs:CharIsP, 
	offset	cs:CharIsP, 
	offset	cs:CharIsA, 
	offset	cs:CharIsA, 
	offset  cs:CharIsSpace, 
	offset	cs:CharIsTimeSeparator

.assert (length termTable) eq (length validTerminators + 1)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharIsNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The number terminator was a null.  This means that the
		number preceding the null is the hour.

CALLED BY:	TimeAutoCompletion
PASS:		dx - hour
RETURN:		ch - hour
		dx - min/sec
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharIsNull	proc	near
		.enter	inherit TimeAutoCompletion
	;
	; If we're not in AM/PM mode, then the interpretation done by this
	; function is not desirable.
	;
		tst	ss:ampmMode
		jz	done
		
	;
	; If hour bigger than 12 then exit since the user entered 24hour
	;
		cmp	dx, 12
		ja	done
	;
	; Add 12 to the hours to get the 24hour format
	;
		add	dx, 12
	;
	; If the hour is 12, 21, 22, 23 we should return 0, 9, 10, 11
	;
		cmp	dx, 12
		je	change
		cmp	dx, 21
		je	change
		cmp	dx, 22
		je	change
		cmp	dx, 23
		je	change	
done:
	;
	; Set the return values
	;
		mov	ch, dl			; ch <- hour
		clr	dx			; dx <- min/sec

		.leave
		ret
change:
	;
	; Go from PM to AM
	;
		sub	dx, 12
		jmp	done
CharIsNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharIsP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The number terminator was a p or P.  This means that the
		number the user entered before the P should be PM.

CALLED BY:	TimeAutoCompletion
PASS:		dx - hour
RETURN:		ch - hour
		dx - min/sec
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharIsP	proc	near
		.enter	inherit TimeAutoCompletion
	; 	
	; Format the number to be PM and set the return values, only
	; if it's not already > 12!
	;
		cmp	dl, 12
		ja	noAdd
		add	dl, 12
noAdd:
		mov	ch, dl			; ch <- hour
		clr	dx			; dx <- 0 min/sec

		.leave
		ret
CharIsP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharIsA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The number terminator was a or A. This means that the
		number should be AM.
CALLED BY:	TimeAutoCompletion
PASS:		dx - hour
RETURN:		ch - hour
		dx - min/sec
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharIsA	proc	near
		.enter	inherit TimeAutoCompletion
	;
	; If the hour is 12 then return 0.  This will convert 12:00am -> the
	; number 0, which is what we want.  Otherwise, ignore the "a" and
	; return the hour as-is.  This will convert 14:00am -> 14 (2pm).
	;
		cmp	dl, 12
		jne	afterConvert
		clr	dl			; dl <- 12am
afterConvert:
		mov	ch, dl			; ch <- hour
		clr	dx			; dx <- 0 min/sec

		.leave
		ret
CharIsA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharIsSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The number terminator is a space. We have to ignore this
		space and continue.
		We need this do deal with: 12:00 AM etc.

CALLED BY:	TimeAutoCompletion
PASS:		dx - hour
RETURN:		ch - hour
		dx - min/sec
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharIsSpace	proc	near
		.enter	inherit TimeAutoCompletion
		
	;
	; Find why the conversion stopped and deal with it
	;
		mov	cx, 6			; cx <- # of validTerminators
		inc	di			; next char in string
topLoop:
		mov	bx, cx
		mov	al, cs:[validTerminators][bx]
		cmp	al, es:[di]
		je	found
		loop	topLoop
	;
	; The terminator was found now call the correct function to continue 
	;
found:
		shl	bx
		call	cs:[termTable][bx]	; ch, dx <- time

		.leave
		ret	
CharIsSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharIsTimeSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the minutes from the time string.

CALLED BY:	TimeAutoCompletion
PASS:		es:di = time string (null-terminated)
		dx    = hour
RETURN:		ch    = hour
		dx    = min/sec
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharIsTimeSeparator	proc	near
		uses	ax, bx, di, si
		.enter	inherit	TimeAutoCompletion
	;
	; Get the minutes number, and remember if has leading 0
	;
		inc	di			; one beyond the term
		mov	ax, 1
		LocalCmpChar	es:[di], C_ZERO
		je	convert
		mov	ax, 10
convert:
		push	ax	                ; save minute multiplier
		push	dx			; save hours
		call	ConvertTextToNumber	; dx <- minutes
	;
	; Find why the conversion stopped and deal with it
	;
		mov	cx, 6			; cx <- # of validTerminators
topLoop:
		mov	bx, cx
		mov	al, cs:[validTerminators][bx]
		cmp	al, es:[di]
		je	found
		loop	topLoop
	;
	; If at this point the end is not valid so we bail
	;
		pop	bx			; hours
		pop	ax	                ; minute multiplier
		mov	ch, bl			; ch <- hours
		jmp	done
	;
	; The terminator was found now call the correct function to continue 
	;
found:
		pop	cx			; cx <- hours
		push	dx			; save min
		mov	dx, cx			; dx <- hours
		shl	bx
		call	cs:[termTable][bx]	; ch, dx <- time
		pop	dx			; dx <- minutes
	;
	; If the minutes are less then 6 then we multiply them by
	; the minute multipler (1 if leading zero, 10 if no leading zero).
	;
		pop	bx	                ; Minute multiplier
		cmp	dx, 6
		jae	done
		mov	al, dl
		mul	bl			; al <- min
		mov	dl, al			; dl <- min
done:
		.leave
		ret
CharIsTimeSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTextToNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a text number to a int number.  Given a string
		es:di the function will scan it until it finds a non-digit
		and convert the preceding text to number.

CALLED BY:	(INTERNAL) CharIsTimeSeparator, IntervalAutoCompletion,
		TimeAutoCompletion
PASS:		es:di = Numer string (null-terminated)
RETURN:		dx    = Number
		es:di = Points to where the scan ended
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertTextToNumber	proc	near
		uses	ax, bx, cx, si, bp, ds
		.enter
	;
	; First copy the string to a temp buffer
	;
		sub	sp, size DateTimeBuffer
		push	es, di
		segmov	es, ss			; es:di <- temp buffer
		mov	di, sp
		add	di, 4
		pop	ds, si			; ds:si <- source
		clr	cx
		call	StrCopy
		segxchg	ds, es
		xchg	si, di			; ds:si <- temp buffer
	;
	; Scan the string until we find a non-digit
	;
		mov	bx, si
		clr	ax
topLoop:
		mov	al, ds:[bx]
		call	LocalIsDigit
		jz	thatsAll
		inc	bx
		jmp	topLoop
	;
	; Insert a null where the stream of digits ended so we can convert it
	;
thatsAll:
		mov	{byte} ds:[bx], C_NULL
	;
	; Convert the text number into ints
	;
		call	UtilAsciiToHex32	;dxax <- number

	;
	; If the number overflowed the word, we'll just max out ax
	;
		tst	dx
		jz	setReturnValue
		mov	ax, 0xffff
	;
	; Have dx be our return value
	;
setReturnValue:
		mov	dx, ax			;dx <- number
	;
	; Return es:di as the position in the string where the scan ended
	;
		sub	bx, si
		add	di, bx
	;
	; Restore the stack
	;
		add	sp, size DateTimeBuffer

		.leave
		ret
ConvertTextToNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeInputUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the current time in the TIText GenText object.

CALLED BY:	(INTERNAL) TIMetaNotify, TIParseTimeString,
		TISetCurrentTime, TISetTime, TITimeIncDec,
		TITimeInputRedisplayTime, TimeInputGenerateUI
PASS:		*ds:si	- Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeInputUpdateText	proc	near
		uses	ax, bx, cx, dx, si, di, bp, es
		class	TimeInputClass
		.enter

EC <		call	ECCheckObject					>
	;
	; First get the current date from instance data
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset TII_time
		call	GetTime			; ch, dx <- time
	;
	; Format the date according to the system defaults
	;
		sub	sp, size DateTimeBuffer
		segmov	es, ss
		mov	di, sp			; es:di <- Buffer
	;
	; Check to see if in NONE state
	;

if _BUGFIX_40017
	;
	; ACJ 10/4/95 Check to see if we're in NONE state and
	; the attribute ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY
	; is set.
	;
		mov	ax, ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY
		call	ObjVarFindData		; stc if found
		jnc	formatTime		
endif
		mov	{word}es:[di], C_NULL
		cmp	ch, NONE_VALUE
		je	replace
if _BUGFIX_40017
formatTime:
endif
		call	TimeInputFormatTime	; es:di <- Time in buffer
replace:
	;
	; Now update the GenText with the short date
	;
		clr	cx			; Null terminated
		call	ReplaceTIText
	;
	; Reset the modified state of the text
	;
		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		clr	cx
		mov	di, offset TIText
		call	ObjCallControlChild
	;
	; Restore the stack
	;	
		add	sp, size DateTimeBuffer

		.leave
		ret
TimeInputUpdateText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceTIText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace text in the text object.

CALLED BY:	(INTERNAL) IntervalAutoCompletion, TimeAutoCompletion,
		TimeInputUpdateText
PASS:		es:di	= string
		cx	= length of string (0 for null-terminated)
		*ds:si	= control object
RETURN:		nothing
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceTIText	proc near
		uses bp
		.enter

		movdw	dxbp, esdi		; dx:bp <- date string
		mov	di, offset TIText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallControlChild

		.leave
		ret
ReplaceTIText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeInputFormatTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the time correctly depending on the TII_timeType.

CALLED BY:	(INTERNAL) IntervalAutoCompletionLow, TimeAutoCompletion,
		TimeInputUpdateText
PASS:		*ds:si	= TimeInput Object
		es:di   = buffer for text
		ch	= Hours (0-23)
		dl	= Minutes (0-59)
		dh	= Seconds (0-59)
RETURN:		cx	= length of string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeInputFormatTime	proc	near
		uses	ax, bx, dx, si, di, bp, ds
	class	TimeInputClass
		.enter
EC <		call	ECCheckObject					>
	;
	; First check the TII_timeType.
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].Gen_offset
		cmp	ds:[bx].TII_timeType, TIT_TIME_OF_DAY
		jne	timeLength

	;
	; The TII_timeType is TIT_TIME_OF_DAY so format the time in
	; 12:00 PM fasion.
	;
		mov	si, DTF_HM
		call	LocalFormatDateTime	; es:di <- ex. 1:30 AM
done:
		.leave
		ret
	;
	; Check if we're doing a TIT_TIME_OFFSET.  if not, just
	; do the regular thing.
	;
timeLength:
		mov	bp, BW_FALSE		; assume not negative
		cmp	ds:[bx].TII_timeType, TIT_TIME_INTERVAL
		jz	timeInterval

	;
	; We're doing a time offset.  If we're negative, then
	; format time time without the negative sign
	; and add it on later.
	;
		tst	ch
		jg	timeInterval
		jl	doNegative

	;
	; We have a zero hours. Therefore it depends on whether
	; the minutes field is negative or not
	;
		tst	dl
		jge	timeInterval

	;
	; We have a negative time offset.  We'll have to add the
	; negative sign later.
	;
doNegative:
		LocalNextChar	esdi
		mov	bp, BW_TRUE
		neg	ch		; make the values positive
		neg	dl

timeInterval:
	;
	; It is established that the timeType is TIT_TIME_INTERVAL.  How
	; see if we are only dealing with minutes or hours and minutes
	;
		tst	ch
		jz	noHours
	;
	; Hours and minutes so we format the string accordingly...
	;
		mov	si, DTF_HM_24HOUR
		call	LocalFormatDateTime
		jmp	doneInterval
noHours:
	;
	; Only minutes.  This means that we have to set up a custom format
	; string since the system does not handle just minutes.
	;
		segmov	ds, cs
		mov	si, offset timeInputMinuteFormat
		call	LocalCustomFormatDateTime	

	;
	; See if we have to append the minus sign to the string.
	;
doneInterval:
		cmp	bp, BW_FALSE
		jz	done

		LocalPrevChar	esdi
		LocalLoadChar	ax, C_MINUS
		LocalPutChar	esdi, ax, NO_ADVANCE
		inc	cx
		jmp	done

TimeInputFormatTime	endp

timeInputMinuteFormat	char	TOKEN_DELIMITER,
				TOKEN_MINUTE,
				TOKEN_DELIMITER,
				C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeInputParseTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does the reverse of TimeInputFormatTime.  This function
		parses a time string and returns the time in registers.

CALLED BY:	(INTERNAL) TIParseTimeString
PASS:		*ds:si  = TimeInput Object
		es:di   = ptr to time string (null-terminated)
RETURN:		ch	= hours (0-23)
		dl	= minutes (0-59)
		dh	= (seconds) always 0
		carry set if valid 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimeInputParseTime	proc	near
		uses	ax, bx, si, di, bp, ds
		class	TimeInputClass
		.enter

EC <		call	ECCheckObject					>

	;
	; First check the TII_timeType.
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].Gen_offset
		cmp	ds:[bx].TII_timeType, TIT_TIME_OF_DAY
		jne	timeLength
	;
	; If string is NULL, and we're allowing NONE, then return
	;  NONE_VALUE's
	;
		LocalIsNull	es:[di]           ; null string
		jnz	normalParse
		push	bx
		mov	ax, ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY
		call	ObjVarFindData
		pop	bx
		jnc	normalParse		; and NONE allowed

		mov	dh, NONE_VALUE
		mov	dl, dh
		mov	ch, dl
		stc
		jmp	reallyDone
normalParse:
	;
	; The TII_timeType was TIT_TIME_OF_DAY so we parse a string that should
	; look like "12:00 AM".
	;
		mov	si, DTF_HM
		call	LocalParseDateTime	; ch, dx <- time


done:
		mov	dh, 0			; don't return -1
						; don't disturb carry
reallyDone:
		.leave
		ret
timeLength:
	;
	; Check to see if we're doing a timeOffset or timeInterval.
	; If we're doing a timeInterval, then do that code now.
	;
		mov	bp, BW_FALSE		; not doing negative numbers
		cmp	ds:[bx].TII_timeType, TIT_TIME_INTERVAL
		je	timeInterval
	;
	; Well, we must be doing a timeOffset.
	; Check if the first character is a negative sign.
	; If so we'll just pass everything after that to
	; the timeInterval code
	; Use bp to indicate if there is a minus sign.
	; 
		Assert	e	ds:[bx].TII_timeType, TIT_TIME_OFFSET
		LocalCmpChar	es:[di], C_MINUS
		jnz	timeInterval

		LocalNextChar	esdi
		mov	bp, BW_TRUE		; doing negative numbers

timeInterval:
	;
	; Because we are dealing with a string that contains either minutes
	; or hours and minutes we first try to parse the hour minute string
	; and if that fails we parse the minute string.
	;
		mov	si, DTF_HM_24HOUR
		call	LocalParseDateTime	; carry set if OK
		jc	negateValue
	;
	; The string did not parse using DTF_HM_24HOUR so try using the
	; non-standard minute string.
	;
customParse::
		segmov	ds, cs
		mov	si, offset timeInputMinuteFormat
FXIP <		clr	cx			;null-terminated format	>
FXIP <		call	SysCopyToStackDSSI	;ds:si = format on stack >
		call	LocalCustomParseDateTime
FXIP <		call	SysRemoveFromStack	;release stack space	>
		mov	cx, 0			; don't want to return -1
		jnc	done

	;
	; If we were doing this time interval parsing for a time offset
	; object, then we have to check if there was a minus sign
	; in the front of the string.  If there was, then we'd
	; better negate the valuse.
	;
negateValue:
		cmp	bp, BW_FALSE
		jz	exitClean		; since the cmp uses the
						; carry we want to return,
						; set it.

	;
	; There was a minus sign in front of the string, so the values
	; are negative.
	;
		neg	ch	
		neg	dl

exitClean:
		stc
		jmp	done

TimeInputParseTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the time (in ch and dx) to a TimeStruct
		pointed to by ds:si.

CALLED BY:	(INTERNAL) TIParseTimeString, TISetCurrentTime, TISetTime
PASS:		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		dh - seconds (0 through 59)
		ds:di - ptr to TimeStruct
RETURN:		nothing	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTime	proc	near
		mov	ds:[di].T_hours, ch
		mov	ds:[di].T_minutes, dl
		mov	ds:[di].T_seconds, dh
		ret
SetTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the time from a TimeStruct pointed to by 
		ds:si to ch and dx.

CALLED BY:	(INTERNAL) SendTIActionMessage, TIGetTime,
		TimeInputGenerateUI, TimeInputUpdateText
PASS:		ds:di - ptr to TimeStruct
RETURN:		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		dh - seconds (0 through 59)
		cl - 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTime		proc	near
		clr	cl
		mov	ch, ds:[di].T_hours
		mov	dl, ds:[di].T_minutes
		mov	dh, ds:[di].T_seconds
		ret
GetTime		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIMetaTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This was passed to us by our child GenText.  We are
		going to pass it along to our output, so that they
		deal with it if they want to.

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= TimeInputClass object
		es 	= segment of TimeInputClass
		ax	= message #
		cx:dx	= text object (unused)
		bp	= non-zero if text is becoming non-empty
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIMetaTextEmptyStatusChanged	method dynamic TimeInputClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		.enter
	;
	; If ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY is set, then
	; disable the +/- triggers when the text object becomes empty,
	; enable 'em when it becomes non-empty.
	;
		mov	ax, ATTR_TIME_INPUT_DISPLAY_STRING_WHEN_EMPTY
		call	ObjVarFindData		; stc -> ds:bx <- ptr to optr
		jnc	sendToOutput

	;
	; Either enable or disable the +/- triggers.
	;
		mov	di, offset TimeInputIncTrigger
		call	TIEnableDisableTrigger

		mov	di, offset TimeInputDecTrigger
		call	TIEnableDisableTrigger
		
sendToOutput:
		mov	ax, MSG_META_TEXT_EMPTY_STATUS_CHANGED
		mov	bx, es
		mov	di, offset @CurClass	; bx:di <- class
		call	GadgetOutputActionRegs

		.leave
		ret
TIMetaTextEmptyStatusChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIEnableDisableTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the object.

CALLED BY:	(INTERNAL) TIMetaTextEmptyStatusChanged
PASS:		*ds:si	= control object
		di	= offset to object
		bp	= zero to disable, non-zero to enable
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIEnableDisableTrigger	proc	near
		uses	ax, bx, cx, dx, bp
		.enter
		
		mov	ax, MSG_GEN_SET_ENABLED
		tst	bp
		jnz	doIt
		mov	ax, MSG_GEN_SET_NOT_ENABLED
doIt:
		mov	dl, VUM_NOW
		call	ObjCallControlChild	; bx <- block

		.leave
		ret
TIEnableDisableTrigger	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIGenControlRemoveFromGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name sez it all.

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= TimeInputClass object
		es 	= segment of TimeInputClass
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
TIGenControlRemoveFromGcnLists	method dynamic TimeInputClass, 
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		.enter

		call	RemoveSelfFromDateTimeGCNLists

		.leave
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
TIGenControlRemoveFromGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw us if date/time format hath chang'd.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= TimeInputClass object
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
TIMetaNotify	method dynamic TimeInputClass, 
					MSG_META_NOTIFY
		.enter
	;
	; See if it's the notification we're interested in.
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	callSoup
		cmp	dx, GWNT_INIT_FILE_CHANGE
		jne	callSoup

	;
	; Update our notion of AM/PM-ness.
	;
		call	TISetAMPMMode

	;
	; We need to redraw if the time format has changed.
	;
		cmp	bp, IFE_DATE_TIME_FORMAT
		jne	exit
		call	TimeInputUpdateText

exit:
		.leave
		ret

callSoup:
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
TIMetaNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TISetAMPMMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the .INI file and figure and reset our notion
		of whether or not the AM/PM-ness has changed.

CALLED BY:	(INTERNAL) TIMetaNotify, TimeInputGenerateUI
PASS:		*ds:si	= TimeInputClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

timeFmtCatString	char	TIMEDATE_CATEGORY_STRING
timeFmtKeyString	char	TIMEDATE_TIME_FMT_STRING

TISetAMPMMode	proc	near
		class	TimeInputClass
		uses	ax, bx, cx, dx, di
		.enter

	;
	; Get the AM/PM mode .INI file setting.
	;
		push	ds, si			; #1
		mov	cx, cs
		mov	ds, cx
		mov	si, offset timeFmtCatString
		mov	dx, offset timeFmtKeyString
		mov	ax, 2			; assume 24hr (in case error)
		call	InitFileReadInteger	; ax <- TimeFormatIdentifier
		pop	ds, si			; #1

	;
	; Set instance data saying whether or not we're in AM/PM mode.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	ds:[di].TII_ampmMode	; assume 24hr mode
		tst	ax			; ax == zero -> AM/PM okay
		jnz	notAMPM
		not	ds:[di].TII_ampmMode	; change to BB_TRUE
notAMPM:

	;
	; Set the GenText object's notion of AM/PM-ness.
	;
		mov	cx, ds:[di].TII_ampmMode ; cl <- BooleanByte
		mov	di, offset TIText
		mov	ax, MSG_TIME_INPUT_TEXT_SET_AMPM_MODE
		call	ObjCallControlChild	; bx <- child block

		.leave
		ret
TISetAMPMMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TIMetaTextLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent whenever the text object loses the focus.

CALLED BY:	MSG_META_TEXT_LOST_FOCUS
PASS:		*ds:si	= TimeInputClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the date out of the GenText and store it in the
		DateInput instance data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TIMetaTextLostFocus	method dynamic TimeInputClass, 
					MSG_META_TEXT_LOST_FOCUS
		.enter
	;
	; Act like a GenValue: only send out the apply message if
	; the text has been modified.
	;
		mov	di, offset TIText
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		call	ObjCallControlChild	; carry set if modified
		jnc	exit

	;
	; Don't send apply message if we have
	; ATTR_DONT_SEND_APPLY_MSG_ON_TEXT_LOST_FOCUS.
	;
		mov	ax, ATTR_DONT_SEND_APPLY_MSG_ON_TEXT_LOST_FOCUS
		call	ObjVarFindData	; CF set if found
		jc	exit

	;
	; Everything's fine.  Send the apply message.
	;
		call	TISendApplyMsg

exit:		
		.leave
		ret
TIMetaTextLostFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITextApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to internal text object's apply message --
		send message to output.

CALLED BY:	MSG_TI_TEXT_APPLY
PASS:		*ds:si	= TimeInputClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITextApply	method dynamic TimeInputClass, 
					MSG_TI_TEXT_APPLY
		.enter

		call	TISendApplyMsg
		
		.leave
		ret
TITextApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TISendApplyMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete text and send out the apply message.

CALLED BY:	(INTERNAL) TIMetaTextLostFocus, TITextApply
PASS:		*ds:si	= TimeInputClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TISendApplyMsg	proc	near
		.enter
	;
	; Parse the time string and do auto-completion
	;
		call	TIParseTimeStringIfModified
		jc	done	; error.  Old state reverted, don't send
	;
	; Let the output know that a new time has been set.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		call	SendTIActionMessage
done:
		.leave
		ret
TISendApplyMsg	endp

GadgetsSelectorCode ends
