COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Jedi
MODULE:		Gadgets Library
FILE:		uiTimeInputText.asm

AUTHOR:		Jacob A. Gabrielson, Jan 10, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT CallTimeInput           Call our gen parent (TimeInputClass
				object).

    INT TITInitializeTempStringIfNeeded 
				Name sez it all.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/10/95   	Broke out from uiTimeInput.asm


DESCRIPTION:
	Implementation of TimeInputTextClass, a sub-object of the
	TimeInputClass controller.
		

	$Id: uiTimeInputText.asm,v 1.1 97/04/04 17:59:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITMetaKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message sent out on any keyboard press or release.  We need
		to subclass this message to catch the arrow-up, arrow_down
		keystrokes and Ctrl-*.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		es 	= segment of TimeInputTextClass
		ax	= message #
		cx	= character value
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high	= scan code
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial version
   	PBuck	3/30/94		Modified to use FlowCheckKbdShortcut

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

                 ;P     C  S     C
                 ;h  A  t  h  S  h
                 ;y  l  r  f  e  a
                 ;s  t  l  t  t  r
                 ;
titShortCutList	\
KeyboardShortcut <1, 0, 0, 0, 0xf, VC_UP>,	; _TIME_INC
                 <1, 0, 0, 0, 0xf, VC_DOWN>,	; _TIME_DEC
                 <1, 0, 0, 0, 0xe, UC_TIME>	; _INPUT_SET_CURRENT_TIME

titActionMessages \
word		MSG_TI_TIME_INC,
	   	MSG_TI_TIME_DEC,
	   	MSG_TIME_INPUT_SET_CURRENT_TIME

TITMetaKbdChar	method dynamic TimeInputTextClass, MSG_META_KBD_CHAR
		.enter

		push	bp
	;
	; Ignore key releases.
	;
		test	dl, mask CF_RELEASE
		jnz	callSuper
if 0
	;
	; If we're in TIT_TIME_OFFSET mode, then just forget about
	; the keyboard presses we're doing and have them handled
	; normally.
	;
		cmp	ds:[di].TITI_timeType, TIT_TIME_OFFSET
		jz	callSuper
endif
	;
	; See if it's a character we're interested in.  Make sure that
	; the desired ctrl/shift/whatever key is also being pressed.
	;
		push	ds,si
		segmov	ds, cs, ax
		mov	si, offset titShortCutList
		mov	ax, length titShortCutList
		call	FlowCheckKbdShortcut		; si = offset into msg table 
		mov	bp, si
		pop	ds,si
		jnc	callSuper

	;
	; Send message associated with the action.
   	;
		mov	ax, cs:[titActionMessages][bp]
		call	CallTimeInput
		pop	bp
	
		.leave
		ret
		
callSuper:
		pop	bp
		mov	ax, MSG_META_KBD_CHAR
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
TITMetaKbdChar	endm

ditKeymap	KeyAction \
<CS_UI_FUNCS shl 8 or UC_DATE,	offset cs:KeyFuncStick,
				MSG_DATE_INPUT_SET_CURRENT_DATE>,
<CS_CONTROL shl 8 or VC_UP,	NULL,		MSG_DI_DATE_INC>,
<CS_CONTROL shl 8 or VC_DOWN,	NULL,		MSG_DI_DATE_DEC>

dsKeymap	KeyAction \
<CS_CONTROL shl 8 or VC_NEXT_BUTTON,	NULL,		MSG_DS_DATE_INC>,
<CS_CONTROL shl 8 or VC_PREV_BUTTON,	NULL,		MSG_DS_DATE_DEC>,
<CS_CONTROL shl 8 or VC_RIGHT,	NULL,		MSG_DS_DATE_INC>,
<CS_CONTROL shl 8 or VC_LEFT,	NULL,		MSG_DS_DATE_DEC>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyToMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a keystroke to a message to send.

CALLED BY:	(INTERNAL)
PASS:		cs	= segment of keymap
		bx	= (offset first KeyAction) - (size KeyAction)
		di	= first KeyAction following table
		cx	= char (as passed to MSG_META_KBD_CHAR)
		dh	= ShiftState
		bp low	= ToggleState
RETURN:		carry clear if keystroke found:
			ax	= message to send
		carry set otherwise:
			ax destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyToMsg	proc	far
		uses	bx
		.enter

		mov	ax, bp			; al <- ToggleState
	;
	; Only keep ToggleStates we care about.
	;
		andnf	al, mask TS_SHIFTSTICK or mask TS_FNCTSTICK

	;
	; Search for matching KeyAction.
	;
nextAction:
		add	bx, size KeyAction	; cs:[bx] <- next KeyAction
		cmp	bx, di			; past end?
		jae	notFound
		cmp	cx, cs:[bx].KA_char
		jne	nextAction
		tst	cs:[bx].KA_handler
		jnz	testViaHandler
	;
	; Test the ShiftState and ToggleState by default: they should
	; both be clear.
	;
		tst	dh
		jnz	nextAction
		tst_clc	al
		jnz	nextAction
		jmp	found
	;
	; Test the ShiftState and ToggleState by passing 'em to a custom
	; handler.
	;
testViaHandler:
		call	cs:[bx].KA_handler	; carry clear if found
		jc	nextAction

	;
	; The character was found in the keymap.  Return the message
	; to send out.
	;
found:
EC <		ERROR_C -1			; I'm a fool, if error	>
		mov	ax, cs:[bx].KA_msg

exit:
		.leave
		ret

notFound:
		stc
		jmp	exit
KeyToMsg	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyAnyShift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept any kind of shift-ing.

CALLED BY:	(INTERNAL)
PASS:		al	= ToggleState
		dh	= ShiftState
RETURN:		carry set to accept
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyAnyShift	proc	near
		uses	ax, dx
		.enter

		andnf	al, mask TS_SHIFTSTICK
		cmp	al, mask TS_SHIFTSTICK
		stc
		jne	exit

		andnf	dh, mask SS_LSHIFT or mask SS_RSHIFT
		cmp	dh, mask SS_LSHIFT or mask SS_RSHIFT
		stc
		jne	exit

		clc
exit:		
		.leave
		ret
KeyAnyShift	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyFuncStick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept if TS_FNCTSTICK only is set.

CALLED BY:	(INTERNAL)
PASS:		see KeyAnyShift
RETURN:		see KeyAnyShift
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyFuncStick	proc	near
		uses	dx
		.enter

		andnf	al, mask TS_FNCTSTICK
		cmp	al, mask TS_FNCTSTICK
		jne	error

		tst_clc	dh			; should be no ShiftState
		jz	exit

error:
		stc
		
exit:
		.leave
		ret
KeyFuncStick	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTimeInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call our gen parent (TimeInputClass object).

CALLED BY:	(INTERNAL) TITMetaKbdChar
PASS:		*ds:si	= object (any subclass of GenClass)
		ax	= message to send
		cx, dx, bp = data to pass along with message
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTimeInput	proc near
		.enter
	;
	; Record the event.
	;	
		push	ds:[LMBH_handle], si	; #1
		mov	bx, segment TimeInputClass
		mov	si, offset TimeInputClass
		mov	di, mask MF_RECORD
		call	ObjMessage

	;
	; Call object.
	;
		mov	cx, di		; cx <- handle to ClassedEvent
		pop	bx, si		; #1 ^lbx:si <- TimeInputText obj
		clr	di
		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	ObjMessage

		.leave
		ret
CallTimeInput endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITMetaTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when text object becomes empty or not empty
		This message is sent to the text object itself first.


CALLED BY:	MSG_META_TEXT_EMPTY_STATUS_CHANGED
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		ax	= message #
		cx:dx	= text object
		bp	= zero if text is becoming empty
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITMetaTextEmptyStatusChanged	method dynamic TimeInputTextClass, 
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		uses	ax, cx, dx, bp
		.enter
	;
	; We may need to redraw if the text object is becoming empty,
	; and we've been configured to draw "NONE" in that case.
	;
		tst	ds:[di].TITI_drawNoneIfEmpty
		jz	done
		mov	ds:[di].TITI_notEmpty, bp

	;
	; Make the thing redraw itself, so as our MSG_VIS_DRAW handler
	; will happen.
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock

done:		
		.leave				; restore passed regs

		mov	di, offset @CurClass
		call	ObjCallSuperNoLock	; will go to gen parent

		ret
TITMetaTextEmptyStatusChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITVisTextReplaceAllPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does additional checking to see if the text becomes
		empty, since there are cases when no empty_status_changed
		message is sent, but the initial value of TITI_notEmpty
		is wrong, and doesn't get reset.

CALLED BY:	MSG_VIS_TEXT_REPLACE_ALL_PTR
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		ds:bx	= TimeInputTextClass object (same as *ds:si)
		es 	= segment of TimeInputTextClass
		ax	= message #
		dx:bp	= Pointer to text string
		cx	= string length, 0 if null-terminated
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Changes the value of TITI_notEmpty

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITVisTextReplaceAllPtr	method dynamic TimeInputTextClass, 
					MSG_VIS_TEXT_REPLACE_ALL_PTR
	;
	; If replacing with non-0length text, then set notEmpty to TRUE
	;
		mov	ax, TRUE		  ; Assume not-empty
		jcxz	testLength

callSuper:
		push	ax
		mov	ds:[di].TITI_notEmpty, ax
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
	;
	; We must send this to the Controller so that it can
	; disable the triggers, if it wants to.
	;
		pop	bp
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	ax, MSG_META_TEXT_EMPTY_STATUS_CHANGED
		call	CallTimeInput
	ret

testLength:
	;
	; String either 0-length, or non-0 null-terminated. Which?
	;
		segxchg	ds, dx
		LocalIsNull	ds:[bp]
		segxchg	ds, dx
		jnz	callSuper                 ; Not empty
		clr	ax			  ; empty
		jmp	callSuper

TITVisTextReplaceAllPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw custom string when empty, if needed.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		ax	= message #
		cl	= DrawFlags:  DF_EXPOSED set if GState is set
			  to update window
		^hbp	= GState to draw through.
			  This will be in the default state except for:
				pen position, colors -- undefined
			  Specific UI & GenGadget objects only:
				font, size -- set to default for UI
				private data -- set to DisplayScheme to use
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITVisDraw	method dynamic TimeInputTextClass, 
					MSG_VIS_DRAW
		.enter

		push	bp			; #3 gstate

		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

	;
	; Get bounds of object.  We later use a hack to draw the
	; desired string in the proper place.
	;
		mov	ax, MSG_VIS_GET_BOUNDS	; ax, bp <- left, top
		call	ObjCallSuperNoLock

		pop	dx			; #3 gstate

	;
	; If the object's not empty, or we're not supposed to draw the string,
	; then just exit.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		tst	ds:[di].TITI_drawNoneIfEmpty
		jz	exit
		tst	ds:[di].TITI_notEmpty
		jnz	exit

	;
	; Get pointer to string to draw.
	;
		mov	bx, ds:[di].TITI_emptyString.handle
		mov	si, ds:[di].TITI_emptyString.offset
		push	bx			; #2 save handle
		push	ax			; #1 save offset
		call	MemLock
		mov	ds, ax
		pop	ax			; #1
		mov	si, ds:[si]		; ds:si <- string to draw

	;
	; Calculate offset where at to draw the string.
	;
		add	ax, 4			; ax <- left + 3
		lea	bx, [bp][8]		; hack: bx <- top + 8
		mov	di, dx			; ^hdi <- gstate
		clr	cx			; null-terminated
		call	GrDrawText
		pop	bx			; #2 handle to free

		call	MemUnlock

exit:
		.leave
		ret
TITVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITReplaceWithTextTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	detect and report error since we have
		ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR set

CALLED BY:	MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		ds:bx	= TimeInputTextClass object (same as *ds:si)
		es 	= segment of TimeInputTextClass
		ax	= message #
		ss:bp	= CommonTransferParams
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITReplaceWithTextTransferFormat	method dynamic TimeInputTextClass, 
				MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT

	;
	; check paste size
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock		; dx.ax = text size
	pop	bp
	pushdw	dxax
	mov	bx, ss:[bp].CTP_vmFile
	mov	ax, ss:[bp].CTP_vmBlock
	push	bp, es
	call	VMLock
	mov	es, ax
	mov	di, es:[TTBH_text].high		; ^vbx:di = text
	call	HugeArrayGetCount		; dx.ax = size w/null
	decdw	dxax				; dx.ax = size w/o null
	call	VMUnlock
	pop	bp, es
	popdw	cxbx				; cx.bx = text size
	adddw	dxax, cxbx			; dx.ax = current + new size
	pushdw	dxax
	mov	di, bp				; ss:di = CTP
	mov	dx, size VisTextGetTextRangeParameters
	sub	sp, dx
	mov	bp, sp
	movdw	ss:[bp].VTGTRP_range.VTR_end, ss:[di].CTP_range.VTR_end, ax
	movdw	ss:[bp].VTGTRP_range.VTR_start, ss:[di].CTP_range.VTR_start, ax
	mov	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE or \
					mask VTGTRF_ALLOCATE_ALWAYS
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_BLOCK
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	call	ObjCallInstanceNoLock		; dx.ax = range size
	add	sp, size VisTextGetTextRangeParameters
	mov	bx, cx				; bx = range text block
	call	MemFree				; nuke it, just want size
	mov	bp, di				; ss:bp = CTP
	popdw	cxbx				; cx.bx = text size
	subdw	cxbx, dxax			; cx.bx = size after change
	tst	cx
	jnz	tooBig
	push	ax, bp
	mov	ax, MSG_VIS_TEXT_GET_MAX_LENGTH
	call	ObjCallInstanceNoLock		; cx = max length
	pop	ax, bp
	sub	bx, cx				; bx = excess chars
	jbe	sizeOK
tooBig:
	;
	; else, report error
	;
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	jmp	short done

sizeOK:
	;
	; let superclass handle
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	mov	di, offset TimeInputTextClass
	call	ObjCallSuperNoLock
done:
	ret
TITReplaceWithTextTransferFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITVisTextFilterViaBeforeAfter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only accept valid input.  Does some auto-completion, too.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER

PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		cx	= chunk handle of "before" text (unused)
		dx	= chunk handle of "after" text
RETURN:		carry set (always, 'cuz we replace text with right stuff)
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITVisTextFilterViaBeforeAfter	method dynamic TimeInputTextClass, 
					MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER
		.enter
	;
	; Set up TITI_tempString if needed.
	;
		call	TITInitializeTempStringIfNeeded
	LONG_EC	jc	reject

	;
	; Determine correct start state for parser.
	;

	;
	; First, check to see if the user is adding text to the end,
	; or to the middle.  We might want to use different parsers.
	;
		push	si			; #1
		push	di			; #2
		segmov	es, ds, di
		mov	di, cx
		mov	di, ds:[di]		; es:di <- before string
		mov	si, di			; ds:si <- before string
		LocalStrLength			; cx <- length of before string
	;
	; Does the before string match a prefix of the after string?
	;
		mov	di, dx
		mov	di, ds:[di]		; es:di <- after string
		call	LocalCmpStrings
		mov	si, 0
		jz	fetchMachine
		mov	si, (timeTypeToStartStateMiddle - timeTypeToStartState)
fetchMachine:
		pop	di			; #2
		mov	bx, ds:[di].TITI_timeType
		shl	bx, 1			; index nptrs
		mov	bx, cs:[timeTypeToStartState][bx][si]
		pop	si			; #1
	;
	; Tell parser whether "[apm]" is legal input.  "Interval" mode
	; won't care either way, but so what?
	;
		mov	al, ds:[di].TITI_ampmMode ; al <- AM/PM legal?
	;
	; Set up pointers to both strings, then call the parser thingy.
	;
		push	di, si			; #1
;		segmov	es, ds			; es <- same as ds (for parser)
		mov	si, dx
		mov	dx, ds:[di].TITI_timeType ; pass in the time type
		mov	si, ds:[si]		; ds:si <- text to parse
		mov	di, ds:[di].TITI_tempString
		mov	di, es:[di]		; es:di <- buffer for result
		call	TimeInputParseString	; sets carry to reject buffer
		pop	ax, bx			; #1
		jc	beepAtUser

	;
	; If the parser-expanded string == the "after" text, then
	; just accept the text -- it'll look more elegant to the
	; user.
	;
		clr	cx			; null-terminated
		call	LocalCmpStrings
		clc				; assume equal
		je	exit
		movdw	disi, axbx		; restore di, si from push

	;
	; The string was good, so queue up to replace the text with
	; the parser-expanded string.
	;
		mov	bx, ds:[LMBH_handle]	; ^lbx:si <- this obj
		mov	dx, bx			
		mov	bp, ds:[di].TITI_tempString ; ^ldx:bp <- new text
		clr	cx			; null-terminated
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		call	ObjMessage

	;
	; We have to manually set the modified bit in this case.  Otherwise
	; the GenText won't send out an apply msg...
	;
		mov	cx, 1			; signal to set modified
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		call	ObjMessage

reject:
		stc				; appear to "reject" text

exit:		
		.leave
		ret

	;
	; Since we often appear to "reject" the text, we need to beep
	; manually when the user really did enter an illegal character.
	;
beepAtUser:
		mov	ax, SST_NO_INPUT
		call	UserStandardSound
		jmp	reject

timeTypeToStartState	nptr.TimeParseTransition \
			offset CommonCode:tmEmpty,	; TIT_TIME_OF_DAY
			offset CommonCode:iStart,	; TIT_TIME_INTERVAL
			offset CommonCode:oStart	; TIT_TIME_OFFSET

timeTypeToStartStateMiddle	nptr.TimeParseTransition \
			offset CommonCode:tmrStart,	; TIT_TIME_OF_DAY
			offset CommonCode:iStart,	; TIT_TIME_INTERVAL
			offset CommonCode:oStart	; TIT_TIME_OFFSET

TITVisTextFilterViaBeforeAfter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITInitializeTempStringIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name sez it all.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
RETURN:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		carry set if error!
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITInitializeTempStringIfNeeded	proc	near
		class	TimeInputTextClass
		uses	ax, cx
		.enter
	;
	; See if we need to allocate space.
	;
		tst_clc	ds:[di].TITI_tempString
		jnz	exit
		clr	al			; no flags
		mov	cx, DATE_TIME_BUFFER_SIZE
		call	LMemAlloc
		pushf				; #1 save carry

	;
	; Re-dereference.
	;
		mov	di, ds:[si]
		add	di, ds:[di].TimeInputText_offset
		mov	ds:[di].TITI_tempString, ax
		popf				; #1 restore carry

exit:
		.leave
		ret
TITInitializeTempStringIfNeeded	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITTimeInputTextSetTimeType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the timeType for this class.  The TypeInputType is
		used in MSG_VIS_TEXT_FILTER_VIA_BEFORE_AFTER to determine
		what filter routine to execute.

CALLED BY:	MSG_TIME_INPUT_TEXT_SET_TIME_TYPE
PASS:		ds:di	= TimeInputTextClass instance data
		cx	= TimeInputType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITTimeInputTextSetTimeType	method dynamic TimeInputTextClass, 
					MSG_TIME_INPUT_TEXT_SET_TIME_TYPE
	;
	; Set the TimeInputTime in instance data.
	; 
		mov	ds:[di].TITI_timeType, cx

		ret
TITTimeInputTextSetTimeType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITTimeInputTextDisplayStringWhenEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start displaying passed string whenver object is empty.

CALLED BY:	MSG_TIME_INPUT_TEXT_DISPLAY_STRING_WHEN_EMPTY
PASS:		*ds:si	= TimeInputTextClass object
		ds:di	= TimeInputTextClass instance data
		^ldx:bp	= string to display when empty
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITTimeInputTextDisplayStringWhenEmpty	method dynamic TimeInputTextClass, 
				MSG_TIME_INPUT_TEXT_DISPLAY_STRING_WHEN_EMPTY
		.enter

		Assert	optr dxbp

	;
	; Set flag wot causes desired behaviour.
	;
		mov	ds:[di].TITI_drawNoneIfEmpty, BB_TRUE

	;
	; Store the string's optr in instance data.
	;
		movdw	ds:[di].TITI_emptyString, dxbp

		.leave
		ret
TITTimeInputTextDisplayStringWhenEmpty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TITTimeInputTextSetAmpmMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn AM/PM mode on or off.

CALLED BY:	MSG_TIME_INPUT_TEXT_SET_AMPM_MODE
PASS:		ds:di	= TimeInputTextClass instance data
		cl	= BooleanByte (BB_FALSE == 24hr mode)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TITTimeInputTextSetAmpmMode	method dynamic TimeInputTextClass, 
					MSG_TIME_INPUT_TEXT_SET_AMPM_MODE
		.enter

		mov	ds:[di].TITI_ampmMode, cl

		.leave
		ret
TITTimeInputTextSetAmpmMode	endm

CommonCode	ends
