COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Date Input Gadget
FILE:		uiDateInput.asm

AUTHOR:		Skarpi Hedinsson, Jul  1, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT SendDIActionMessage     Sends the action message (DII_actionMsg) to
				the output (GCI_output).

    INT DateInputUpdateText     Displays the current date in the
				InputDateText GenText object.

    INT DateAutoCompletion      Adds the currect year to the date string if
				the user only entered day and month.

    INT SendToDateInput         Message sent out on any keyboard press or
				release.  We need to subclass this message
				to catch the arrow-up and arrow_down
				keystrokes. We then send a message to
				increment or decrement the date to the
				DateInput control.

    INT GetSystemDateSeparator  Returns the system date seperator.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: uiDateInput.asm,v 1.1 97/04/04 17:59:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsClassStructures	segment resource

	DateInputClass		; declare the control class record

GadgetsClassStructures	ends

;---------------------------------------------------

GadgetsSelectorCode segment resource

if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set DII_date to current date unless it's been initialized
		via restoring from state.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
		es 	= segment of DateInputClass
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIMetaInitialize	method dynamic DateInputClass, 
					MSG_META_INITIALIZE
		.enter

		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

	;
	; If the first field of DII_date is -1, then we should
	; put today's date in there.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].DII_date.DT_year, -1
		jne	exit
		call	DISetToCurrentDate

exit:
		.leave
		ret
DIMetaInitialize	endm

endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	DateInputGetInfo --
		MSG_GEN_CONTROL_GET_INFO for DateInputClass

DESCRIPTION:	Return group

PASS:
	*ds:si 	- instance data
	es 	- segment of DateInputClass
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
DateInputGetInfo	method dynamic	DateInputClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset DIC_dupInfo
	call	CopyBuildInfoCommon
	ret
DateInputGetInfo	endm

DIC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0,				; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	0,				; GCBI_controllerName

	handle DateInputUI,		; GCBI_dupBlock
	DIC_childList,			; GCBI_childList
	length DIC_childList,		; GCBI_childCount
	DIC_featuresList,		; GCBI_featuresList
	length DIC_featuresList,	; GCBI_featuresCount
	DI_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

GadgetsControlInfo	segment resource

DIC_childList	GenControlChildInfo	\
   <offset DateInputGroup, mask DIF_DATE, mask GCCF_ALWAYS_ADD>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

DIC_featuresList	GenControlFeaturesInfo	\
	<offset DateInputGroup, offset DateInputName, 0>

GadgetsControlInfo	ends

COMMENT @----------------------------------------------------------------------

MESSAGE:	DateInputGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for DateInputClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the filled/unfilled items

PASS:		*ds:si - instance data
		es - segment of DateInputClass
		ax - The message

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Skarpi	06/22/94	Initial version
   	PBuck	03/24/95	Added ATTR_DATE_INPUT_TARGETABLE handler

------------------------------------------------------------------------------@
DateInputGenerateUI		method dynamic	DateInputClass,
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Call the superclass.
	;
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
	;
	; Set up the text object to be targetable if so specified
	;
		mov	ax, ATTR_DATE_INPUT_TARGETABLE
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
	; If the do draw/don't draw feature isn't set, then we shouldn't
	; do anything.
	;
		call	GetChildBlockAndFeatures ; bx <- handle
		test	ax, mask DIF_DATE
		jz	exit

	;
	; If the first field of DII_date is -1, then we should
	; put today's date in there.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].DII_date.DT_year, -1
		jne	updateText
		call	DISetToCurrentDate

	;
	; Display date in DII_date.
	;
updateText:
		call	DateInputUpdateText

exit:		
		.leave
		ret
DateInputGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIGenControlAddToGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add us to system GCN lists. 

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= DateInputClass object
		es 	= segment of DateInputClass
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
DIGenControlAddToGcnLists	method dynamic DateInputClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		.enter

		call	AddSelfToDateTimeGCNLists
		
		.leave
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		ret
DIGenControlAddToGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DISpecActivateObjectWithMnemonic
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
DISpecActivateObjectWithMnemonic	method dynamic DateInputClass, 
					MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		uses	ax, cx, dx, bp
		.enter
	;
	; Call superclass.  If the mnemonic is a match the carry is set.
	;
		mov	di, offset DateInputClass
		call	ObjCallSuperNoLock
		jnc	done
	;
	; We have a match.  Send MSG_GEN_MAKE_FOCUS to the GenText object.
	;
		mov	di, offset DIText
		mov	ax, MSG_GEN_MAKE_FOCUS		
		call	ObjCallControlChild
		stc					; return carry
done:
		.leave
		ret
DISpecActivateObjectWithMnemonic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIMetaGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass focus to GenText.

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL
PASS:		*ds:si	= DateInputClass object
		es 	= segment of DateInputClass
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
DIMetaGainedFocusExcl	method dynamic DateInputClass, 
					MSG_META_GAINED_FOCUS_EXCL
		.enter
	;
	; Call superclass.
	;
		mov	di, offset DateInputClass
		call	ObjCallSuperNoLock

	;
	; Pass focus on.
	;
		mov	di, offset DIText
		mov	ax, MSG_GEN_MAKE_FOCUS		
		call	ObjCallControlChild

		.leave
		ret
DIMetaGainedFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIDateDec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment/decrement the date by one.

CALLED BY:	MSG_DI_DATE_DEC, MSG_DI_DATE_INC
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Updates the DSI_date instance data.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIDateDec	method dynamic DateInputClass, MSG_DI_DATE_DEC,
						MSG_DI_DATE_INC
		uses	ax, cx, dx, bp
		.enter
	;
	; First parse the text in the text object and save the result
	; to instance data.  We do this all the time, not just
	; when modified, because apps are subclassing
	; MSG_DI_PARSE_DATE_STRING to detect when the gadget has been
	; modified.
	;
		push	ax			; #1 save msg

		mov	ax, MSG_DI_PARSE_DATE_STRING
		call	ObjCallInstanceNoLock	 ; sets carry
	;
	; Decrement/increment the date by one
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset DII_date	; ds:di <- struct to inc/dec
	;
	; Increment/decrement the time by incrementValue based on which
	; message wuz actually sent.
	;
		pop	ax			; #1 ax <- msg
		cmp	ax, MSG_DI_DATE_INC
		je	incDate
		call	DecrementDate
		jmp	incDecDone
incDate:
		call	IncrementDate
incDecDone:

	;
	; Show the new date
	;
		call	DateInputUpdateText

	;
	; Do what a GenValue would do.
	;
		call	DISelectAllText

	;
	; Send message letting the output know the date has changed
	;
		call	SendDIActionMessage

		.leave
		ret
DIDateDec	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIParseDateStringIfModified
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
DIParseDateStringIfModified	proc	near
	uses	ax, di, bx
	.enter
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		mov	di, offset DIText
		call	ObjCallControlChild	; carry set if modified,
						; bx = 0 if no child
		lahf
		tst	bx
		clc				 ; no child? no problem!
		jz	done
		sahf
		jnc	done

		mov	ax, MSG_DI_PARSE_DATE_STRING
		call	ObjCallInstanceNoLock	 ; sets carry
done:
	.leave
	ret
DIParseDateStringIfModified	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DISelectAllText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name says it all.

CALLED BY:	(INTERNAL)
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
DISelectAllText	proc	near
		mov	di, offset DIText
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjCallControlChild
		ret
DISelectAllText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIDateInputSetCurrentDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the date to the current system date.

CALLED BY:	MSG_DATE_INPUT_SET_CURRENT_DATE
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIDateInputSetCurrentDate	method dynamic DateInputClass, 
					MSG_DATE_INPUT_SET_CURRENT_DATE
		uses	ax, cx, dx, bp
		.enter

		call	DISetToCurrentDate
	;
	; Update the GenText with the current date
	;
		call	DateInputUpdateText

		.leave
		ret
DIDateInputSetCurrentDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DISetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent to the DateInput to change the current
		displayed date.

CALLED BY:	MSG_DATE_INPUT_SET_DATE
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
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
DISetDate	method dynamic DateInputClass, 
					MSG_DATE_INPUT_SET_DATE
		uses	ax, cx, dx, bp
		.enter

		cmp	cx, MIN_YEAR
EC <		ERROR_B YEAR_OUT_OF_RANGE				>
		jb	done
		cmp	cx, MAX_YEAR
EC <		ERROR_A	YEAR_OUT_OF_RANGE				>
		ja	done
	;
	; First change the instance data DII_date to reflect the new date
	;	
		mov	ax, cx			; ax <- year
		mov	bx, dx			; bx <- month/day
		add	di, offset DII_date
		call	SetDate
	;
	; Now update the date in the GenText.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		call	DateInputUpdateText
done:
		.leave	
		ret
DISetDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSGetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current date of the DateInput.

CALLED BY:	MSG_DATE_INPUT_GET_DATE
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
RETURN:		cx	= year
		dl	= month
		dh	= day
		bp	= day of week
DESTROYED:	dl
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIGetDate	method dynamic DateInputClass, 
					MSG_DATE_INPUT_GET_DATE
		uses	ax, bp
		.enter
	;
	; Act like a GenValue: first expand out the currently entered
	; thing.  But only if we are built out, and the text has been
	; modified.
	;
		call	DIParseDateStringIfModified
	;
	; Get the date for instance data
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset DII_date
		call	GetDate			; ax, bx, cl <- date
	;
	; Set the correct return values
	;
		mov	bp, cx			; bp <- day of week
		mov	cx, ax			; cx <- year
		mov	dx, bx			; dx <- month/day

		.leave
		ret
DIGetDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIDateInputRedisplayDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces the date to be redisplayed

CALLED BY:	MSG_DATE_INPUT_REDISPLAY_DATE
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIDateInputRedisplayDate	method dynamic DateInputClass, 
					MSG_DATE_INPUT_REDISPLAY_DATE
		call	DateInputUpdateText
		ret
DIDateInputRedisplayDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with changes in date/time format in .INI file.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= DateInputClass object
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
	JAG	1/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIMetaNotify	method dynamic DateInputClass, 
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
	; We need to redraw if the time format has changed.
	;
		cmp	bp, IFE_DATE_TIME_FORMAT
		jne	exit
		call	DateInputUpdateText

exit:
		.leave
		ret

callSoup:
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		jmp	exit
DIMetaNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDIActionMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the action message (DII_actionMsg) to the output 
		(GCI_output).

CALLED BY:	DIDateInc, DIDateDec, DISetDate
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
SendDIActionMessage	proc	near
		uses	ax,bx,cx,dx,di,bp
		class	DateInputClass
		.enter

EC <		call	ECCheckObject					>

	;
	; First get the current date
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	di
		add	di, offset DII_date
		call	GetDate			; ax, bx <- date

	;
	; We want to tell the user what day of the week it is, which
	; we haven't been otherwise keeping track of.
	;
		call	CalcDayOfWeek		; cx <- day of week
		mov	bp, cx			; bp <- day of week
		mov	dx, bx			; dx <- month and day
		mov	cx, ax			; cx <- year
		pop	di			; ds:di <- instance data

	;
	; Get the action message and destination from instance data and
	; send message.
	;
		mov	ax, ds:[di].DII_actionMsg	; ax <- msg to send
		mov	bx, segment DateInputClass
		mov	di, offset DateInputClass

		call	GadgetOutputActionRegs

		.leave
		ret
SendDIActionMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateInputUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the current date in the InputDateText GenText object.

CALLED BY:	DateInputGenerateUI
PASS:		*ds:si	= object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateInputUpdateText	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		class	DateInputClass
		.enter
EC <		call	ECCheckObject					>
	;
	; First get the current date from instance data
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset DII_date
		call	GetDate			; ax,bx,cl <- date
	;
	; Format the date according to the system defaults
	;
		sub	sp, size DateTimeBuffer
		segmov	es, ss
		mov	di, sp			; es:di <- Buffer
		call	DIFormatDate
	;
	; Now update the GenText with the short date
	;
		movdw	dxbp, esdi		; dx:bp <- date string
		mov	di, offset DIText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallControlChild
	;
	; Reset the modified state
	;
		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		clr	cx
		call	ObjCallControlChild
	;
	; Restore the stack
	;	
		add	sp, size DateTimeBuffer

		.leave
		ret
DateInputUpdateText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIFormatDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does LocalFormatDateTime with DTF_SHORT, but
		makes sure that 21'st centry dates appear as 4 digits

CALLED BY:	DateInputUpdateText
PASS:		es:di	= place to put the formatted text.

		ax	= Year
		bl	= Month (1-12)
		bh	= Day (1-31)
		cl	= Weekday (0-6)

RETURN:		es:di	= the formatted string.
		cx	= # of characters in formatted string.
			  This does not include the NULL terminator at the
			  end of the string.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	6/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIFormatDate	proc	near
	uses	si,di,ds

format	local	30 dup (TCHAR)	          ; format string to manipulate

	.enter
	;
	; Get the date formatting string
	;
		push	es, di
		mov	si, DTF_SHORT
		segmov	es, ss
		lea	di, format
		call	LocalGetDateTimeFormat
		movdw	dssi, esdi	  ; ds:si = format
		pop	es, di		  ; es:di = buffer
	;
	; If year >= 2000, format as 4 digits by replacing
	; any 2-digit year tokens with 4-digit token
	;
		cmp	ax, 2000
		jb	formatIt
		call	ReplaceYYFormatWithYYYY
formatIt:	
		call	LocalCustomFormatDateTime	; es:di <- ex. 1/1/94
	.leave
	ret
DIFormatDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceYYFormatWithYYYY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the first 2-digit year token with a 4-digit
		token in a date formatting string.

CALLED BY:	DIFormatDate, 
PASS:		ds:si = format buffer
RETURN:		ds:si = format buffer with replaced tokens
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	6/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceYYFormatWithYYYY	proc	near
	uses	ax, es, di, cx
	.enter

		movdw	esdi, dssi
		call	LocalStringLength	 ; cx <- length
tokenSearch:
		jcxz	done
	;
	; find an opening token delimiter
	;
		mov	ax, TOKEN_DELIMITER
		LocalFindChar			 ; es:di = token, cx = remainin
		jne	done
	;
	; If long year already exists, we're done.
	;
		cmp	{word}es:[di], TOKEN_LONG_YEAR
		je	done
	;
	; Is it a 2 digit year token?
	;
		mov	ax, TOKEN_SHORT_YEAR
		scasw			         ; es:di = close delimiter
		je	replace
	;
	; No. Gobble close delimiter
	;
		inc	di			 ; es:di = after close
		sub	cx, 3			 ; 'XX|' eaten
		jmp	tokenSearch
done:
	;
	; We rely heavily on being able to replace the token,
	; so check to make sure we did.
	;
EC <		cmp	{word}es:[di], TOKEN_LONG_YEAR			>
EC <		ERROR_NE	GADGETS_LIBRARY_ERROR			>
	.leave
	ret

replace:
	;
	; Yes.  replace 2-yr with 4 year
	;
		dec	di
		dec	di
		mov	{word}es:[di], TOKEN_LONG_YEAR
		jmp	done

ReplaceYYFormatWithYYYY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIGenControlRemoveFromGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove us from GCN lists.

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= DateInputClass object
		es 	= segment of DateInputClass
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
DIGenControlRemoveFromGcnLists	method dynamic DateInputClass, 
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		.enter

		call	RemoveSelfFromDateTimeGCNLists

		.leave
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
DIGenControlRemoveFromGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIParseDateString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses the date in DIText and saves it to DII_date.

CALLED BY:	MSG_DI_PARSE_DATE_STRING
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
RETURN:		carry	= clear if parse was valid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIParseDateString	method dynamic DateInputClass, 
					MSG_DI_PARSE_DATE_STRING
		uses	ax, cx, dx, bp
		.enter
	;
	; Get the text from the GenText
	;	
		sub	sp, size DateTimeBuffer
		mov	dx, ss
		mov	bp, sp			; dx:dp <- buffer for text
		mov	di, offset DIText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallControlChild     ; bx <- child (0 if none)
		tst	bx
		jz	noReset	                ; if no child, succeed

	;
	; Do the auto-completion.  If the user enters the day/month
	; auto-completion will add the current year.
	;
		mov	es, dx
		mov	di, bp			; es:di <- string to parse
		call	DateAutoCompletion
	;
	; Parse the text into a valid date
	;
		call	DIParseDate
		jnc	notValid
	;
	; LocalParseDateTime accepts 2/30/92, so do some extra semantic
	; checking to make sure this is a valid date.
	;
		push	cx
		call	LocalCalcDaysInMonth    ; ch <- days in month
		cmp	ch, bh			; carry clear iff in range
		pop	cx
		jc	notValid
	;
	; LocalParseDateTime returns years higher than 2099, but
	; many of the routines used on the returned date (e.g.
	; CalcDayOfWeek) require that the passed year be <=2099, so
	; we truncate.  Note:  we use "jb" because we can then
	; use the carry flag (after calling SetDate) to determine
	; whether to redo the text.
	;
		cmp	ax, MIN_YEAR
		jae	notBelow
		mov	ax, MIN_YEAR
		clc				; redisplay text
		jmp	validYear
notBelow:
		cmp	ax, MAX_YEAR+1
		jb	validYear

		mov	ax, MAX_YEAR
validYear:		
	;
	; Update the instance data with the new date
	;
		pushf
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset DII_date
		call	SetDate
		popf
	;
	; If ax was > MAX_YEAR, then the carry flag will be clear,
	; and we have to redisplay the text.
	;
		jc	noReset	
	;
	; else, report error
	;
		mov	ax, SST_ERROR
		call	UserStandardSound
		call	DateInputUpdateText
noReset:
	;
	; Restore the stack.
	;
		add	sp, size DateTimeBuffer
		clc				; parse was valid
done:
	;
	; Reset the modified state of the text, so we don't parse again
	; before modified.
	;
		pushf
		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		clr	cx
		mov	di, offset DIText
		call	ObjCallControlChild
		popf

		.leave
		ret
notValid:
	;
	; Date in GenText is not a valid date, we do there for not update
	; the DII_date.  First we will sound the alarm indicating the date
	; is not valid.
	;
		mov	ax, SST_ERROR
		call	UserStandardSound
	;
	; Restore the "old" date in the GenText object.
	;
		call	DateInputUpdateText
	;
	; Restore the stack.
	;
		add	sp, size DateTimeBuffer
		stc				; parse not valid
		jmp	done

DIParseDateString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIParseDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses a string into a date according to system
		date format.  Parses 2-digit years as 20th century.

CALLED BY:	DIParseDateString

PASS:		es:di	= the string to parse.
		si	= DateTimeFormat to compare the string against.

RETURN:		carry set if the string is a valid date/time.
			ax	= Year
			bl	= Month
			bh	= Day (1-31)
			cl	= Weekday (0-6)
DESTROYED:	ax, bx, cx on error
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This routine exists to get around some behavior of
	the way LocalParseDateTime parses 2-digit year tokens,
	which is:
		If 2 digits are supplied as the year, then:
			if <  30, year = 20xx
			if >= 30, year = 19xx
		If 4 digits are supplied as the year, then
			accept it as-is.
		Other length years are not accepted

	On Jedi, we want all 2 digit years to be parsed as 19xx.
	So, we need to know if the user entered 2 or 4 digits
	for the year. How will we do this?

	Replace the short-year (2 digit) token in the formatting
           string with a long-year token, and try to parse.

		If it succeeds, then 4 digits were entered: accept it.

		Else, restore the 2-digit year token and parse

			If it succeeds, then force the returned
			year into the 20th century.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	6/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIParseDate	proc	near

	uses	ds, si
format	local	30 dup (TCHAR)	          ; format string to manipulate

	.enter

	;
	; Get the date formatting string, and turn short years
	; into long years
	;
		push	es, di
		mov	si, DTF_SHORT
		segmov	es, ss
		lea	di, format
		call	LocalGetDateTimeFormat
		movdw	dssi, esdi	  ; ds:si = format
		pop	es, di		  ; es:di = buffer
	;
	; try to parse year as 4-digits
	;
		call	ReplaceYYFormatWithYYYY
		call	LocalCustomParseDateTime
		jc	done			 ; accepted
	;
	; Failed.  Try to parse as 2 digits
	;
		mov	si, DTF_SHORT
		call	LocalParseDateTime
		jnc	done			 ; failed again
	;
	; 2 digit years should always 20'th centry dates, so make
	; sure this is so
	;
		cmp	ax, 2000
		jb	done			 ; carry set
		sub	ax, 100
		stc
done:
	.leave
	ret
DIParseDate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateAutoCompletion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the currect year to the date string if the user
		only entered day and month.
			
CALLED BY:	DIMetaTextLostFocus
PASS:		es:di	- Date string in DTF_SHORT format
		cx	- String length
		*ds:si	- Object
RETURN:		es:di   - Date string with year added (if needed)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For D/M/Y format:
			22/4/94 = 22.4, 22-04, 22:04:94 etc.
		For M/D/Y format
			4/22/94 = 04.22, 04;22, 4-22-94 etc.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DateAutoCompletion	proc	near
		uses	ax,bx,cx,dx,si,di
stringOffset	local	word	push	di
		.enter
EC <		call	ECCheckObject					>
	;
	; First get the system date seperator
	;
		call	GetSystemDateSeparator		; ax <- sperator
	;
	; Find the first seperator between day and month
	;
		repne	scasb
		jne	firstNotFound
	;
	; Make sure that the character following the separator is not the
	; null-terminator. If it is then we cannot auto-complete since
	; we don't have the required day and month
	;
		cmp	{byte} es:[di], C_NULL
		je	done
	;
	; Now check if there is a second speparator.
	;
		repne	scasb
		jne	complete		; there is none
	;
	; If there is a second separator then check if the next character is
	; null.  If it is then auto-compleation has to be done
	;
		cmp	{byte} es:[di], C_NULL
		jne	done
	;
	; The last character is a null, before the jump to complete terminate
	; the string before the last separator since the complete code adds
	; it.
	;
		mov	{byte} es:[di-1], C_NULL
		jmp	complete
done:
		.leave
		ret
firstNotFound:
	;
	; The first seperator was not found, which means that there is not
	; much need for auto-completion so we bail.
	;
		jmp	done
complete:
	;
	; First we concatenate a separator
	;
		mov	di, ss:[stringOffset]
		push	ds, si
		push	ax			; separator
		segmov	ds, ss
		mov	si, sp
		call	StrCat
		pop	ax
	;
	; then the year
	;
		sub	sp, size DateTimeBuffer
		push	es, di	
		segmov	es, ss
		mov	di, sp
		add	di, 4
		call	TimerGetDateAndTime	; ax <- year
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	ds, si			; ds:si <- date string
		segxchg	es, ds			; es:di <- date string
		xchg	di, si
		cmp	ax, 2000
		jae	keepCentury
		add	si, 2			; ds:si <- 94
keepCentury:
		clr	cx
		call	StrCat			; add 94 to date string
		add	sp, size DateTimeBuffer
		pop	ds, si
	;
	; Update the GenText to show auto-completion
	;
		push	bp
		mov	dx, es
		mov	bp, di
		mov	di, offset DIText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallControlChild
		pop	bp
		jmp	done

DateAutoCompletion	endp

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DITMetaKbdChar
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
DITMetaKbdChar	method dynamic DateInputTextClass, MSG_META_KBD_CHAR
		.enter
	;
	; Ignore key releases.
	;
		test	dl, mask CF_RELEASE
		jnz	callSuper

	;
	; See if it's a character we're interested in.  Make sure that
	; the desired ctrl/shift/whatever key is also being pressed.
	;
		mov	bx, (offset ditKeymap) - (size KeyAction)
		mov	di, (offset ditKeymap) + (size ditKeymap)
		call	KeyToMsg		; ax <- message to send
		jc	callSuper

	;
	; Send message associated with the action.
	;
		call	SendToDateInput

		.leave
		ret
		
callSuper:
		mov	ax, MSG_META_KBD_CHAR
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
DITMetaKbdChar	endm
;----
SendToDateInput	proc near

	;
	; Record the event.  ax = Message to send
	;	
		push	ds:[LMBH_handle]
		push	si
		mov	bx, segment DateInputClass
		mov	si, offset DateInputClass
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; Send the event.
	;
		mov	cx, di		; Get handle to ClassedEvent in cx
		pop	bx, si		; TimeInputText OD
		clr	di
		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	ObjMessage
		ret
SendToDateInput endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DITVisTextFilterViaBeforeAfter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only accept valid input.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
PASS:		*ds:si	= DateInputTextClass object
		ds:di	= DateInputTextClass instance data
		cx	= chunk handle of "before" text (unused)
		dx	= chunk handle of "after" text
RETURN:		carry set if new text is valid
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DITVisTextFilterViaBeforeAfter	method dynamic DateInputTextClass, 
					MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
parseOutBut	local	DATE_TIME_BUFFER_SIZE dup (char)
		.enter
	;
	; Set up (unused) buffer for parser.  Gimme a break, I don't have
	; much time to write this code :-)
	;
		lea	di, ss:parseOutBut
		segmov	es, ss

	;
	; AM/PM is never legal for dates, of course.
	;
		clr	al

	;
	; Set up parser start state.  Use the relaxed-rules
	; parser.
	;
		mov	bx, offset CommonCode:drStart

	;
	; Call the parser.
	;
		mov	si, dx
		mov	si, ds:[si]		; ds:si <- text to parse
		call	TimeInputParseString	; sets carry if illegal
		
		.leave
		ret
DITVisTextFilterViaBeforeAfter	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DITVisTextFilterViaCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called for every character entered into the GenText.  Here
		all characters exept the valid date characters are filtered
		out.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_CHARACTER
PASS:		*ds:si	= DateInputTextClass object
		ds:di	= DateInputTextClass instance data
		ds:bx	= DateInputTextClass object (same as *ds:si)
		es 	= segment of DateInputTextClass
		ax	= message #
		cx	= character to filter
RETURN:		cx	= 0 to reject replacement, otherwise the replacement
			  char. 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DITVisTextFilterViaCharacter	method dynamic DateInputTextClass, 
					MSG_VIS_TEXT_FILTER_VIA_CHARACTER
		uses	ax, dx, bp
		.enter
	;
	; First check if character is numeric
	;
		mov	ax, cx			; ax <- character
		call	LocalIsDigit
		jnz	done
	;
	; Is it one of the valid date separators?
	;
		mov	cx, 6			; number of seperators
		clr	dx
topLoop:
		mov	bx, cx
DBCS <		shl	bx, 1						>
DBCS <		mov	dx, cs:[validDateSeparators][bx]		>
SBCS <		mov	dl, cs:[validDateSeparators][bx]		>
DBCS <		cmp	ax, dx						>
SBCS <		cmp	al, dl						>
		je	same
		loop	topLoop
		jmp	notGood
same:
	;
	; Only return the system selected date seperator
	;
		call	GetSystemDateSeparator	; ax <- separator
done:
		mov	cx, ax			; cx <- return char
		.leave
		ret
notGood:
		clr	ax
		jmp	done

DITVisTextFilterViaCharacter	endm

validDateSeparators	label	TCHAR
		TCHAR	C_NULL			; should never be reached
		TCHAR	C_SLASH
		TCHAR	C_MINUS
		TCHAR	C_PERIOD
		TCHAR	C_COMMA
		TCHAR	C_COLON
		TCHAR	C_SEMICOLON


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DITMetaGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select all the text.

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL
PASS:		*ds:si	= DateInputTextClass object
		es 	= segment of DateInputTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
DITMetaGainedFocusExcl	method dynamic DateInputTextClass, 
					MSG_META_GAINED_FOCUS_EXCL
		.enter
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

		.leave
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjCallInstanceNoLock
		ret
DITMetaGainedFocusExcl	endm
endif
CommonCode ends
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSystemDateSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the system date seperator.

CALLED BY:	DITVisTextFilterViaCharacter, DateAutoCompletion
PASS:		nothing
RETURN:		ax - System data separator
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
BUGS/IDEAS:
		This routine is HIGHLY non-localizable.  It assumes
	the JEDI platform.  Specifically:

	  - LocalFormatDateAndTime(DTF_SHORT) must return a string
		in which the third character is the single character
		used to separate the fields of a date.  On Jedi,
		the only allowable formats for DTF_SHORT are
			mm/dd/yy, mm-dd-yy, dd/mm/yy, dd.mm.yy, etc,


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSystemDateSeparator	proc	far
		uses	bx,cx,dx,si,di,bp,es
		.enter
	;
	; Get the formatted short date
	;
		mov	ax, 1994
		mov	bl, 11
		mov	bh, 11
		sub	sp, DATE_TIME_BUFFER_SIZE
		segmov	es, ss
		mov	di, sp
		mov	si, DTF_SHORT
		call	LocalFormatDateTime		; es:di <- 01/01/94
	;
	; The third character in this string should be the date separator
	;
		clr	ax
		mov	al, es:[di+2]			; return separator
	;
	; Restore stack
	;
		add	sp, size DateTimeBuffer

		.leave
		ret
GetSystemDateSeparator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIMetaTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This was passed to us by our child GenText.  We are
		going to pass it along to our output, so that they
		deal with it if they want to.

CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= DateInputClass object
		es 	= segment of DateInputClass
		ax	= message #
		cx:dx	= text object
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
DIMetaTextEmptyStatusChanged	method dynamic DateInputClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		.enter

		mov	bx, es
		mov	di, offset @CurClass	; bx:di <- class
		call	GadgetOutputActionRegs

		.leave
		ret
DIMetaTextEmptyStatusChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DIMetaTextLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send whenever the text object loses the focus.

CALLED BY:	MSG_META_TEXT_LOST_FOCUS
PASS:		*ds:si	= DateInputClass object
		ds:di	= DateInputClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the date out of the GenText and store it in the
		DateInput instance data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DIMetaTextLostFocus	method dynamic DateInputClass, 
					MSG_META_TEXT_LOST_FOCUS
		.enter
	;
	; Act like a GenValue: only send out the apply message if
	; the text has been modified.
	;
		mov	di, offset DIText
		mov	ax, MSG_GEN_TEXT_IS_MODIFIED
		call	ObjCallControlChild	; carry set if modified
		jnc	exit

		call	DISendApplyMsg

exit:		
		.leave
		ret
DIMetaTextLostFocus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DITextApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out apply msg.

CALLED BY:	MSG_DI_TEXT_APPLY
PASS:		*ds:si	= DateInputClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DITextApply	method dynamic DateInputClass, 
					MSG_DI_TEXT_APPLY
		.enter

		call	DISendApplyMsg
		
		.leave
		ret
DITextApply	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DISendApplyMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete text and send out the apply message.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= DateInputClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DISendApplyMsg	proc	near
		.enter
	;
	; Parse the time string and do auto-completion
	;
		call	DIParseDateStringIfModified
		jc	done			 ; error: don't do anything

	;
	; Let the output know that a new time has been set.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		call	SendDIActionMessage

done:
		.leave
		ret
DISendApplyMsg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DISetToCurrentDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set DII_date to current date

CALLED BY:	(INTERNAL)
PASS:		ds:di	= DateInputClass instance data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DISetToCurrentDate	proc	near
		class	DateInputClass
		.enter

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
		add	di, offset DII_date
		call	SetDate

		.leave
		ret
DISetToCurrentDate	endp


GadgetsSelectorCode ends

