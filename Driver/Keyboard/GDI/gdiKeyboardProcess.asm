COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		gdiKeyboardProcess.asm

AUTHOR:		Kenneth Liu, Jun  7, 1996

ROUTINES:
	Name			Description
	----			-----------
	KbdCallback		Callback routine for GDI Library
	KbdCheckHotkey		See if current scan code is a
				registered hotkey and act on it
	KbdMonRoutine		Input Monitor Routine
	KbdXlateScan		Main function to translate scan
				code to characters.
	ProcessKeyElement
	FindScanCode		Check scan code in keyDownList
	ProcessScanCode
	ProcessStateRelease
	AccentTranslation
	HandleExtendedDef
	HandleExtendedSet
	HandleExtendedCapslock
	HandleNormalDef

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu		6/ 7/96   	Initial revision


DESCRIPTION:
	Contains the callback routine and translation code for GDI
	Keyboard Driver.
		
	$Id: gdiKeyboardProcess.asm,v 1.1 97/04/18 11:47:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	         	KbdCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler routine for keyboard interrupt.(GDI-Driver level)

CALLED BY:	GDI-Library (Keyboard Interrupt)

PASS:		bx	-> first scan code avaiable
		cx	-> TRUE if press, FALSE if release
		ax	<- KeyboardErrorCodes
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Hardware specific stuff should now be handled by the Gdi-Lib.
	What gdi-driver has to do is to call the GDIKeyboardGetKey
	to retrieve the list of make and break codes received from
	the last time this routine was called.

	Send the message and let Input manager do the rest.
	Note: we are passing the press/release information "secretly"
	to the input monitor since dx is not used in MSG_IM_KBD_SCAN
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdCallback	proc	far

		uses	ax, bx, cx, dx, bp, si, di, ds
		.enter
sendCode:
	;
	;	Should have a scan code ready here, do error check
	;	according to the documentation errorcode is not passed
	;	in ax, so we don't check it	-mjoy
	;EC <		cmp	ax, EC_NO_ERROR
	;EC <		ERROR_NE KBD_GET_KEY_ERROR

	;
	;	First, we want to check for Hotkey before it's passed
	;
		call	KbdCheckHotkey			; carry set if key processed
		jc	done
	;
	;	we use dx to pass the information of
	;	whether it's a press / release to the input monitor
	;	Only this callback and input monitor know about.
	;
		mov	dx, cx				; dx = isPress?
		mov	cx, bx				; cx = scan code
		clr	bp		
		clr	si				; don't send driver handle
		mov	ax, segment dgroup
		mov	ds, ax
		mov	bx, ds:[kbdOutputProcHandle]
		cmp	bx, 0fffh			; check for no recipient
EC <		ERROR_E	KBD_NO_RECIPIENT_SPECIFIED
		je	done

	;
	;	send that out to input monitor
	;
		mov	ax, MSG_IM_KBD_SCAN
		mov	di, mask MF_FORCE_QUEUE 
		call	ObjMessage
EC <		cmp	di, MESSAGE_NO_ERROR
EC <		ERROR_NE KBD_INPUT_MON_MESSAGE_FAILS
		
	;
	;	Now continue to get key, bail if no additional scancode
	;
		call	GDIKeyboardGetKey
		cmp	ax, KEC_NO_ADDITIONAL_SCANCODES
		jne	sendCode

done:
		.leave
		ret
KbdCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCheckHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current scan code is a registered hotkey and
		act on it.

CALLED BY:	INTERNAL: KbdCallback
PASS:		bx	-> scan code

RETURN:		carry set if key processed.
		carry clear if key not processed.
		nothing else.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
ECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	07/16		

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdCheckHotkey	proc	near

		uses	ds, ax
		.enter
		
		mov	ax, segment dgroup
		mov_tr	ds, ax
		mov	al, ds:kbdShiftState

	;
	;	al <- ShiftState,	bx <- scan code
	;		
		call	GDIKeyboardCheckHotkey
EC <		cmp	ax, EC_NO_ERROR
EC <		ERROR_NE KBD_CHECK_HOTKEY_ERROR
		.leave
		ret
KbdCheckHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdMonRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Input Monitor Routine

CALLED BY:	EXTERNAL: InputManager

PASS:		di	-> EVENT TYPE, or 0 if request for more data
		ds	-> droup
RETURN:		if (di == MSG_IM_KBD_SCAN) {
			di	       <- MSG_META_KBD_CHAR
			cx, dx, bp, si <- keyboard char data
			al	       <- bit 0 set if data being returned
					  bit 1 set if more to come
		} else {
			none
		}
		
DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:
		Do scancode translation if MSG_IM_KBD_SCAN is passed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	6/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdMonRoutine	proc	far
		.enter

		cmp	di, MSG_IM_KBD_SCAN
		jne	done

	;
	;	do the actual translation since it's a kbd scan message
	;
		call	KbdXlateScan
done:
		.leave
		ret
KbdMonRoutine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdXlateScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	EXTERNAL: DR_KBD_XLATE_SCAN
		INTERNAL: KbdMonRoutine
PASS:		cx 	-> scan code
		dx 	-> TRUE if press, FALSE if release
		ds 	-> dgroup

RETURN:		di 	<- MSG_META_KBD_CHAR
		cx, dx, bp, si <- kbd char data
		al	<- flags: bit 0 set if data being returned
				 bit 1 set if more to come
 		carry	<- set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	1. Check KeyDownList to determine whether it's a first press, a release,
	   or a repeat press.
	2. For first press and release, return appropiate data for MSG_META_KBD_CHAR.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdXlateScan	proc	near
		uses	es
		.enter
	;
	;	No scancode should be 0
	;
		tst	cx
		jz	noData

		mov	ax, cx				; scan code in ax
	;
	;	Place or update keysDownList, if new press then
	;	generate charValue, exit if error
	;
		call	ProcessKeyElement		; ax, bx, cx, dx destroyed
		jc	noData

	;
	;	Skip AccentTranslation if key is not first press and not accentable
	;
		test	ds:[si].KDE_charFlags, mask CF_FIRST_PRESS
		jz	getData
		test	ds:[si].KDE_charFlags, mask CF_TEMP_ACCENT
		jnz	getData	

	;
	;	Translate char values into accent char values if
	;	accent is pending.
	;	
		call	AccentTranslation		; bx, cx, dx destroyed
getData:
	;
	;	Ready to get data from element
	;
		mov	cx, ds:[si].KDE_charValue	
		mov	dl, ds:[si].KDE_charFlags	
		mov	dh, ds:[si].KDE_shiftState
		mov	al, ds:[si].KDE_toggleState
		mov	ah, ds:[si].KDE_scanCode	
		mov	bp, ax			

		test	dl, mask CF_RELEASE		
		jz	afterCheckRelease
		mov	ds:[si].KDE_scanCode, 0		; free element
							; if release
afterCheckRelease:
		test	dl, mask CF_STATE_KEY		
		jz	sendData
		test	dl, mask CF_REPEAT_PRESS	
		jnz	noData				; send no data if repeat

sendData:
		mov	di, MSG_META_KBD_CHAR		; di <- return method
		mov	al, mask MF_DATA
		jmp	done

noData:
		clr	al				; show no data being
							; returned

done:
		clc
		.leave
		ret
KbdXlateScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessKeyElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	keyboard scan processing code -- determines whether code is
		a press, release, or repeat press.  Manages keysDownList to
		ensure that status state is preserved throughout press,
		repeat & release of any given key.  Calls routine to convert
		scan code to char value.  Copies end resulting key event
		to kbdEvent variable structure.

CALLED BY:	INTERNAL: KbdXlateScan

PASS:		ax	-> scan code
		dx	-> TRUE if press, FALSE if release
		ds	-> dgroup
		keysDownList	-> keys to be processed

RETURN:		ds:[si]		<- KeyDownElement table, if no error
		es:[di]		<- pointer to keyDef entry, if no error
		carry		<- set if overflow errpor in keysDownList
		keysDownList	<- updated to modify old element or include new

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		Calculate pointer to KeyDef for scan code;
		if press [
		    if scan code found in keysDownList [
			change flag to show REPEAT;
		    ] else new press [
			allocate new entry in keysDownList;
			if overflow, exit w/error else [
			    copy scan code into scanCode;
		    	    copy kbdStateFlags into charFlags;
		    	    set kbdStateFlags for PRESS only;
			    processScanCode;
		    	    copy new char over kbdLastChar;
		 	]
		    ]
		] else is release [
		    find entry in keysDownList;
		    if entry not found exit with error else [
		    	change info flag to show RELEASE;
			clear REPEAT flag;
		    ]
		]

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/25/96    	Initial version


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessKeyElement	proc	near

		.enter
	;
	;	Locate keyDefs entry for the passed scan code
	;
		mov	bx, ax				; bx = scan code
if DBCS_PCGEOS
		CheckHack <size KeyDef eq 8>
		shl	bx, 1
else
		CheckHack <size KeyDef eq 4>
endif
		shl	bx, 1
		shl	bx, 1
		movdw	esdi, ds:[kbdKeyTableListPtr]
		movdw	esdi, es:[di].KTL_keyDefs	
		sub	di, size KeyDef
		add	di, bx				; es:di <- ptr to KeyDef entry

	;
	;	Check whether scan code is in the keyDownList
	;
		call	FindScanCode			; ah, cx destroyed
		LONG jz	scanFound

	;
	;	Key wasn't down, so it's a new keypress. 
	;
		cmp	dx, BW_TRUE			; isPress?
		LONG jne	keysDownListError	; error if not a press
		mov	si, bx
		cmp	si, 0ffffh			; see if list is full
		LONG je	keysDownListError		; error if full
		mov	ds:[si].KDE_scanCode, al
		mov	ds:[si].KDE_charFlags, mask CF_FIRST_PRESS
	
		test	ds:kbdOptions, mask GKO_SHIFT_STICK_IMPLIES_SHIFT  \
					or mask GKO_ALT_STICK_IMPLIES_ALT
		jz	PKE_10
		push	{word}ds:[kbdToggleState]
		
PKE_10:
	;
	;	Convert scan code into charValue
	;
		call	ProcessScanCode			; ax = charValue

		mov	ds:[si].KDE_charValue, ax
		mov	bh, ds:[kbdShiftState]
		test	ds:kbdOptions, mask GKO_SHIFT_STICK_IMPLIES_SHIFT  \
					or mask GKO_ALT_STICK_IMPLIES_ALT
		jz	PKE_40
		pop	ax
		test	ds:kbdOptions, mask GKO_SHIFT_STICK_IMPLIES_SHIFT
		jz	PKE_30
		test	ds:kbdOptions, mask GKO_IGNORE_SHIFT_STATE_FOR_PGUP_PGDN
		jz	PKE_20
SBCS <		cmp	ds:[si].KDE_charValue, (CS_CONTROL shl 8) or VC_NEXT >
DBCS <		cmp	ds:[si].KDE_charValue, C_SYS_NEXT >
		je	PKE_30
SBCS <		cmp	ds:[si].KDE_charValue, (CS_CONTROL shl 8) or \
				VC_PREVIOUS >
DBCS <		cmp	ds:[si].KDE_charValue, C_SYS_PREVIOUS >
		je	PKE_30
PKE_20:
	;
	;	Set SS_LSHIFT in this KeyDownElemenet if TS_SHIFTSTICK was on before.
	;
		test	al, mask TS_SHIFTSTICK
		jz	PKE_30
		BitSet	bh, SS_LSHIFT

PKE_30:
		test	ds:kbdOptions, mask GKO_ALT_STICK_IMPLIES_ALT
		jz	PKE_40
	;
	;	Set SS_LALT on in this KeyDownElment if TS_ALTSTICK was on before.
	;
		test	al, mask TS_ALTSTICK
		jz	PKE_40
		BitSet	bh, SS_LALT

PKE_40:
	;
	;	Check which modifier keys are consumed
	;
		not 	ch
		and	bh, ch
		mov	cl, ds:[kbdToggleState]

		test	ds:kbdOptions,  mask GKO_SHIFT_STICK_IMPLIES_SHIFT  \
					or mask GKO_ALT_STICK_IMPLIES_ALT
		jz	PKE_50
	;
	;	Set TS_CTRLSCTICK on in this KeyDownElement if it was on before.
	;
		andnf	al, mask TS_CTRLSTICK
		or	cl, al
		
PKE_50:
		mov	ch, ds:[kbdXState1]
		mov	dl, ds:[kbdXState2]
		mov	ds:[si].KDE_shiftState, bh	; store shift state
		mov	ds:[si].KDE_toggleState, cl	; store toggle state
		mov	ds:[si].KDE_xState1, ch		
		mov	ds:[si].KDE_xState2, dl		
		jmp	short elementDone

scanFound:
	;
	;	Scan code is found in the KeyDownList, either a release or
	;	repeated press.
	;
		cmp	dx, BW_FALSE			; is press or release?
		je	release
		mov	bl, ds:[si].KDE_charFlags
		and	bl, not (mask CF_FIRST_PRESS)
		or 	bl, mask CF_REPEAT_PRESS
		mov	ds:[si].KDE_charFlags, bl
		jmp	short elementDone

release:
	;
	;	Event is a key release. if it's a state key
	;	(e.g shift) being released, handle it specially
	;
		mov	bl, ds:[si].KDE_charFlags
		and	bl, not (mask CF_FIRST_PRESS \
			or mask CF_REPEAT_PRESS)
		or 	bl, mask CF_RELEASE
		mov	ds:[si].KDE_charFlags, bl
	;
	;	Handle release of modifiers
	;
		call	ProcessStateRelease		; nothing destroyed

elementDone:
	;
	;	store ptr to current key
	;
		mov	ds:[kbdCurDownElement.segment],ds
		mov	ds:[kbdCurDownElement.offset], si
		clc
		jmp	done

keysDownListError:
	;
	;	indicate no key
	;
		mov	ds:[kbdCurDownElement.segment], 0
		stc					; indicate error
done:
		.leave
		ret		
ProcessKeyElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindScanCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL: 	ProcessKeyElement
PASS:		al 	-> scan code 
RETURN:		si 	<- ptr to element in keyDownList, if found
		bx 	<- ptr to empty element if element not found
		     	  or 0ffffh if element no found & list full
		z flag 	<- set if element found
DESTROYED:	ah, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		init bx = ffff;
		for each element {
			if element is empty && bx = ffff, copy ptr to bx;
			if element has matching scan code
				exit with address & flags showing found element.
		}
		exit with flag showing element not found.
KNOWN BUGS/IDEAS:
		Assume that scan code is of size byte.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindScanCode	proc	near

		.enter

		mov	si, offset keysDownList - size KeyDownElement
		mov	bx, -1			
		mov	cx, MAX_KEYS_DOWN	
loop1:
		add	si, size KeyDownElement	
		mov	ah, ds:[si].KDE_scanCode
		tst	ah
		jz	empty
		cmp	ah, al
		loopne	loop1
		jmp	done
empty:
		mov	bx, si
		jmp	short	FSC_10
loop2:
		add	si, size KeyDownElement	;move up to next element
FSC_10:
		cmp	ds:[si].KDE_scanCode, al 
		loopne	loop2		;branch while no match
done:
		.leave
		ret
FindScanCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessScanCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts scan code to char value on new press only

CALLED BY:	ProcessKeyElement

PASS:
		ds:[si]			-> ptr to KeyDownElement
		es:[di]			-> ptr to KeyDef entry
		kbdShiftState
		kbdToggleState

RETURN:		ax			<- character value
		ch 			<- modifier bits used in translation
		kbdShiftState		<- updated only if modifier char
		kbdToggleState		<- updated only if toggle char
		kbdXState1		<- update only if xtended state/toggle char

DESTROYED:	cl, bx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessScanCode	proc	near

		.enter
		
		clr	ch				; ch = init: no modifiers
	;
	;	Test whether key is a state key, set flag if it is.
	;
		mov	dh, es:[di].KD_keyType
		test	dh, KD_STATE_KEY
		jz	afterStateKey			; branch if not
		or	ds:[si].KDE_charFlags, mask CF_STATE_KEY
		
afterStateKey:
	;
	;	Now check whether is of type KD_EXTENDED
	;	If it's, do HandleExtendedDef to catch any extended translation.
	;	If there is no extended translation, try normal translation.
	;	Use HandleNormalDef for non KD_EXTENDED type keys
	;
		mov	dl, dh				; dl <- key type and flags
		and	dl, KD_TYPE			; keep type bits only

		test	dh, KD_EXTENDED
		jz	notExtended

		call	HandleExtendedDef		; bl, cl destroyed
							; (al destroyed if
							; code translated)
		
		jc	normalXlate			; no extension, handle normal

	;
	;	clear shift on extended key
	;
		andnf	ds:[kbdToggleState], not (TOGGLE_SHIFTSTICK or \
					  TOGGLE_CTRLSTICK or \
					  TOGGLE_ALTSTICK or \
					  TOGGLE_FNCTSTICK)
done:
		.leave
		ret

notExtended:
		call	HandleNormalDef			; cl destroyed, bl also
							; destroyed if code translated.
		
		jnc	done				; done if translated,
							; else continue
normalXlate:

if DBCS_PCGEOS
		mov	ax, es:[di].KD_char		
		mov	bx, es:[di].KD_shiftChar	
else
		mov	al, es:[di].KD_char
		mov	bl, es:[di].KD_shiftChar
endif
		cmp	dl, KEY_ALPHA
		je	caseAlpha
		cmp	dl, KEY_NONALPHA
	LONG 	je	shift
		cmp	dl, KEY_SOLO
		je	caseSolo
		cmp	dl, KEY_PAD
		je	casePad	
		cmp	dl, KEY_SHIFT
		je	caseShift
		cmp	dl, KEY_TOGGLE
	LONG	je	caseToggle
		cmp	dl, KEY_MISC
		je	shift
		cmp	dl, KEY_SHIFT_STICK
		je	caseStick
		cmp	dl, KEY_XSHIFT
	LONG	je	caseXShift
		cmp	dl, KEY_XTOGGLE
	LONG 	je	caseXToggle

	;
	;	Something unknown happened -- signal an error
	;

if DBCS_PCGEOS
		mov	ax, C_NOT_A_CHARACTER	
else
		mov	ax, (0ffh shl 8) or VC_INVALID_KEY
endif
		jmp	done

caseSolo:
	;
	;	Clear shift state
	;
		andnf	ds:[kbdToggleState], not (TOGGLE_SHIFTSTICK or \
						  TOGGLE_CTRLSTICK or \
						  TOGGLE_ALTSTICK or \
						  TOGGLE_FNCTSTICK)

if DBCS_PCGEOS
					; shiftChar is unused
else
		mov	ah, bl		; shiftChar is really high byte
endif      
		jmp	done

caseAlpha:
		test	ds:[kbdToggleState], TOGGLE_CAPSLOCK
		jz	shift					; branch if no CAPSLOCK
		xchg	ax, bx					; swap if CAPSLOCK
		jmp	shift

casePad:
		test	ds:[kbdToggleState], TOGGLE_NUMLOCK
		jz	PSC_10
		xchg	ax, bx				; swap if NUMLOCK
PSC_10:
		jmp	shift
		
shiftStick:
		xornf	ds:[kbdToggleState], TOGGLE_SHIFTSTICK

caseShift:
		or	ds:[kbdShiftState], bl
		test	ds:[kbdOptions], mask GKO_SHIFT_RELEASE
		jnz	handleShiftRelease
		jmp	done

shift:
		test	ds:[kbdToggleState], TOGGLE_SHIFTSTICK
		jnz	setShifted
		mov	cl, SHIFT_KEYS
		test	ds:[kbdShiftState], cl
		jz 	afterShift

setShifted:
		xchg	ax, bx		

afterShift:
	;
	;	Now that shift state has been taken care of, 
	;	clear any sticky settings
	;
		andnf	ds:[kbdToggleState], not (TOGGLE_SHIFTSTICK or \
						 TOGGLE_CTRLSTICK or \
						 TOGGLE_ALTSTICK or \
						 TOGGLE_FNCTSTICK)

	;
	;	If the character generated with or without <Shift> is the
	;	same, then don't add <Shift> in as a modifier used.  This
	;	allows <Shift> to go through as a modifier for the space
	;	bar (or for any such keys on foreign keyboards).  This
	;	will normally be ignored anyway, but allows using modifiers
	;	with spacebar as shortcuts (eg. <Shift>-spacebar) -- eca 11/30/92
	;
		cmp	ax, bx				; same key w/ or w/o <Shift>?
		LONG je	done				; branch if same
		or	ch, cl				; show modifiers used
		LONG jmp done

caseStick:

if DBCS_PCGEOS
	;
	;	ax <- character to send
	;	bx <- ShiftState to change
	;
		cmp	ax, C_SYS_LEFT_SHIFT
		je	shiftStick
		cmp	ax, C_SYS_LEFT_CTRL
		je	ctrlStick
else
	;
	;	al <- character to send
	;	bl <- ShiftState to change
	;
		cmp	al, VC_LSHIFT
		je	shiftStick
		cmp	al, VC_LCTRL
		je	ctrlStick

endif
		xornf	ds:[kbdToggleState], TOGGLE_ALTSTICK
		jmp	short caseShift

caseToggle:
		xor	ds:[kbdToggleState], bl
		LONG	jmp	done

caseXShift:
		or	ds:[kbdXState1], bl
		jmp	done

caseXToggle:
		xor	ds:[kbdXState1], bl
		LONG	jmp	done

ctrlStick:
		xornf	ds:[kbdToggleState], TOGGLE_CTRLSTICK
		jmp	short caseShift

handleShiftRelease:
		test	bl, SHIFT_KEYS			;shift keys?
		LONG jz	done
		andnf	ds:[kbdToggleState], not (TOGGLE_CAPSLOCK)
		jmp	done

ProcessScanCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessStateRelease
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Monitors SHIFT & MODIFIER key releases
CALLED BY:	ProcessKeyElement

PASS:
		es:[di] 		-> pointer to KeyDef entry
		ds			-> dgroup
		kbdShiftState
		kbdXState1
RETURN:
		kbdShiftState		<- updated only if modifier char
		kbdXState1		<- updated only if extended modifier char
		
DESTROYED:	nothing
SIDE EFFECTS:


PSEUDO CODE/STRATEGY:
		get pointer to char entry in kbdTabUSExtd;
		if KEY_SHIFT {
		    AND kbdShiftState w/(0ffh XOR data2);
		} else if KEY_XSHIFT {
		    AND kbdXState1 w/(0ffh XOR data2);
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/29/96    	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessStateRelease	proc	near

		uses	dx
		.enter
		
		mov	dl, es:[di].KD_keyType
		and	dl, KD_TYPE
if DBCS_PCGEOS
		mov	dh, {byte}es:[di].KD_shiftChar
else
		mov	dh, es:[di].KD_shiftChar
endif

		test	ds:[kbdOptions], mask GKO_KBD_HANDLE_TOGGLES
		jz	lookForShift
		cmp	dl, KEY_TOGGLE
		je	caseToggle
		cmp	dl, KEY_XTOGGLE
		je	caseXToggle

lookForShift:
		not	dh			
		cmp	dl, KEY_SHIFT
		je	caseShift		
		cmp	dl, KEY_SHIFT_STICK
		je	caseShift
		cmp	dl, KEY_XSHIFT
		je	caseXShift

done:
		.leave
		ret

caseShift:
		and	ds:[kbdShiftState], dh		;indicate key up
		jmp	done

caseXShift:
		and	ds:[kbdXState1], dh		; indicate key up
		jmp	done

caseXToggle:
		xor	ds:[kbdXState1], dh
		jmp	done

caseToggle:
		xor	ds:[kbdToggleState], dh
		jmp	done

		
ProcessStateRelease	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccentTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL: KbdXlateScan
PASS:		ds:[si]		-> pointer to KeyDown entry
		es:[di]		-> pointer to keyDef entry
RETURN:		KeyDownEntry modified to have new charValue if translation possible
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	5/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccentTranslation	proc	near

		uses	ax, es, di
		.enter
	;
	;	see if pending accent, branch if none
	;
DBCS <		tst	ds:[kbdAccentPending]		
SBCS <		mov	al, ds:[kbdAccentPending]
SBCS <		tst	al						>
		jz	seeIfAccent			; not pending
		test	es:[di].KD_keyType, (KD_ACCENTABLE or KD_ACCENT)
		jz	seeIfAccent			; not accentable

	;
	;	see if accent hit twice.
	;
DBCS <		mov	ax, ds:[si].KDE_charValue			>
DBCS <		cmp	ax, ds:[kbdAccentPending]			>
SBCS <		mov	ah, byte ptr ds:[si].KDE_charValue		>
SBCS <		cmp	ah, al						>
		je	twoAccents

	;
	;	now get the accentChars list and number of accentable chars
	;
		movdw	esdi, ds:[kbdKeyTableListPtr]
		mov	cx, es:[di].KTL_numAccentDefs
		mov	dx, cx				; ch, cl = numAccentDefs
		movdw	esdi, es:[di].KTL_accentChars	
		clr	bx
	
checkEntry:
DBCS <		cmp	es:[di][bx], ax			>
SBCS <		cmp	es:[di][bx], ah			>
		je	matchAccentChar
		
		inc	bx
DBCS <		inc	bx						>
		dec	cx
		jnz	checkEntry
		jmp	AT_10

matchAccentChar:
		
if DBCS_PCGEOS
		CheckHack <(size AccentDef) eq 16>
		shl	bx, 1
else
		CheckHack <(size AccentDef) eq 8>
endif
		shl	bx, 1				; *8
		shl	bx, 1
		shl	bx, 1				; bx <- offset of entry
		mov	al, ds:[kbdAccentOffset]	; al <- accent offset
		clr	ah				;
		add	bx, ax				; bx <- ptr to entry
SBCS <		add	bx, dx						>
SBCS <		mov	al, es:[di][bx]					>
SBCS <		or	al, al						>
DBCS <		shl	dx, 1						>
DBCS <		add	bx, dx						>
DBCS <		mov	ax, es:[di][bx]					>
DBCS <		tst	ax						>
		je	AT_10				; branch if no
							; translation

twoAccents:
		
SBCS <		mov	byte ptr ds:[si].KDE_charValue, al		>
DBCS <		mov	ds:[si].KDE_charValue, ax			>
		mov	ds:[kbdAccentPending], 0	; indicate no pending
							; accent
done:
		.leave
		ret
AT_10:

seeIfAccent:
	;
	;	done if state key
	;		
		test	ds:[si].KDE_charFlags, mask CF_STATE_KEY
		jnz	done
	
	;
	;	Having a <Shift> key pressed is OK for an accent, but nothing
	;	else is.
	;
		test	ds:[si].KDE_shiftState, not (mask SS_LSHIFT or mask SS_RSHIFT)
		jnz	noTempAccent	
		test	es:[di].KD_keyType, KD_ACCENT	; see if an accent char
		jnz	haveAccent			; branch if accent

noTempAccent:
		mov	ds:[kbdAccentPending], 0	; indicate no pending accent
		jmp	done
		
haveAccent:
SBCS <		mov	al, byte ptr ds:[si].KDE_charValue  ; al <- char	>
DBCS <		mov	ax, ds:[si].KDE_charValue	    ; ax <- char	>
		clr	bx

	;
	;	es:di gets the head of accent table
	;
		movdw	esdi, ds:[kbdKeyTableListPtr]
		movdw	esdi, es:[di].KTL_accentDefs
ATHA_10:
SBCS <		cmp	es:[di][bx], al					>
DBCS <		cmp	{Chars}es:[di][bx], ax				>
		je	ATHA_20				; branch if match
		inc	bx				; inc ptr into table
DBCS <		inc	bx						>
		cmp	bx, KBD_NUM_ACCENTS
		jb	ATHA_10
		jmp	done

ATHA_20:
SBCS <		mov	ds:[kbdAccentPending], al	; indicate accent pending >
DBCS <		mov	ds:[kbdAccentPending], ax	; indicate accent pending >
		mov	ds:[kbdAccentOffset], bl	; store offset in table
		or	ds:[si].KDE_charFlags, mask CF_TEMP_ACCENT
		jmp	done

AccentTranslation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleExtendedDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	

SYNOPSIS:	Handle case of KeyDef containing extended definition.  If
		Alt, Ctrl, or Alt Ctrl pressed & charValue exists for that
		case, use it.  Otherwise, just determine virtual/char
		orientation of base & shift case

CALLED BY:	INTERNAL: ProcessScanCode
PASS:		ch	-> shift modifiers used in translation so far
		dh	-> First byte of KeyDef for this scan code, complete
		dl	-> keyType only, for this scan code
		es:[di] -> pointer to KeyDef for scan code being processed
		ds:[si] -> pointer to KeyDownElement
RETURN:
		if (carry clear) {
		/* scan code translated */
	 	ax	<- charValue
		ch	<- updated w/any modifier bits involved w/translation
		bx, cl	- destroyed
		} else {
		/* scan code not translated */
		ah	<- 0xff or 00, based on vrt/char flag for key base case
		bh	<- 0xff or 00, based on vrt/char flag for key shift case
		al, bl, cl - destroyed

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/30/96    	Initial version
	jwu	3/04/97		extended character set code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	.assert offset kbdToggleState eq (offset kbdShiftState + 1)

HandleExtendedDef	proc	near

		uses	di, dx, es, si
  		.enter

	;
	;	assign si as the number for extended entry	
	;
		mov	bp, si				; save si
		mov	bl, es:[di].KD_extEntry	
		clr	bh
		mov	si, bx

	;
	;	make es:di points to the extended table
	;
		movdw	esdi	ds:[kbdKeyTableListPtr]
		movdw	esdi, es:[di].KTL_keyExts	; essi -> extended table.

	;
	;	calculate the offset of the entry in the extended table.
	;
		
if DBCS_PCGEOS
		CheckHack < (size ExtendedDef) eq 16>
		shl	si, 1
else
		CheckHack <(size ExtendedDef) eq 8>.
endif
		shl	si, 1
		shl	si, 1
		shl	si, 1
		add	di, si				; es:di points to
							; desired entry


		mov	ax, {word}ds:[kbdShiftState]	; al <- ShiftState
							; ah <- ToggleState
	;
	;	check modifier keys to use
	;

SBCS <		clr	bl
DBCS <		clr	bx
		test	ax, SHIFT_KEYS or (TOGGLE_SHIFTSTICK shl 8)
		jz	noShift
		ornf	bl, EXT_SHIFT_MASK		; use shifted key
noShift:
		test	ax, CTRL_KEYS or (TOGGLE_CTRLSTICK shl 8)
		jz 	noCtrl
		ornf	bl, EXT_CTRL_MASK		; use ctrl key
noCtrl:
		test	ax, ALT_KEYS or (TOGGLE_ALTSTICK shl 8)
		jz	noAlt
		ornf	bl, EXT_ALT_MASK		; use alt key
noAlt:
	;
	;	check whether there is an extension for the key or not
	;
DBCS <		cmp	bl, EXT_SHIFT_MASK		; see if key or shift-key>
DBCS <		jbe	notExtended					>
SBCS <		clr	bh				; bx <- offset		>
		mov	cl, ds:bitTable[bx]		; cl <- mask for offset
DBCS <		shl	bx						>
SBCS <		tst	{byte}es:[di][bx]				>
DBCS <		tst	{Chars}es:[di][bx][-3]				>
		je	notExtended			; branch if no extenstion
SBCS <		cmp	bl, EXT_SHIFT_MASK		; see if key or <shift>-key >
SBCS <		jbe	notExtended			; if so, not really extended >

		test	ds:kbdOptions, mask GKO_SHIFTED_EXTENSION
		jz	afterShiftExt

	;
	;	See if we have to generate the <shift> version of an extended key.
	;	First see if any kind of <shift>
	;
SBCS <		test	bl, EXT_SHIFT_MASK				>
DBCS <		test	bl, (EXT_SHIFT_MASK) shl 1			>
		jz	afterShiftExt			; no, not shift-ext key
SBCS <		test	es:[di].EDD_charSysFlags, cl	; see if VChar	>
SBCS <		jz	afterShiftExt					>
SBCS <		cmp	es:[di][bx].C_CTRL, VC_INVALID_KEY		>
DBCS <		cmp	{Chars}es:[di][bx-3], C_NOT_A_CHARACTER		>
		jne	afterShiftExt

	;
	;	Map this key combo to the <shift>- of the character in the
	;	non-shift key combo.
	;
		andnf	al, not (SHIFT_KEYS)
		CheckHack <EXT_SHIFT_MASK eq 1>
		dec	bl
DBCS <		dec	bl						>
		shr	cl				; change mask for
							; offset from
							; shift-xx-yy to
							; no-shift-xx-yy 
afterShiftExt:
	;
	;	extension exists for key
	;
		pushdw	esdi		
		test	es:[di].EDD_charAccents, cl
		jnz	doAccent
afterAccent:
		popdw	esdi
SBCS <		mov	ah, VC_ISANSI					>
SBCS <		test	es:[di].EDD_charSysFlags, cl 			>
SBCS <		jz	notVirtual					>
SBCS <		mov	ah, VC_ISCTRL					

SBCS <		call	HandleExtendedSet   ; ah <- correct char set	>

SBCS < notVirtual:
		pushdw	dssi
		movdw	dssi, ds:kbdKeyTableListPtr
		tstdw	ds:[si].KTL_extFlipCase
		jz	noExtFlipCaseTable

		mov	dx, ds:[si].KTL_numExtFlipCase
		movdw	dssi, ds:[si].KTL_extFlipCase

	;
	;	ds:si <- extFlispCase,	 es:di <- extended table
	;
		call	HandleExtendedCapslock		; update offset,
							; destroy nothing
		
noExtFlipCaseTable:
		popdw	dssi
		or	ch, al
SBCS <		mov	al, {byte}es:[di][bx]				>
DBCS <		mov	ax, {Chars}es:[di][bx][-3]			>

finishUp:
		.leave
		ret

notExtended:
if DBCS_PCGEOS
else
		clr	ah
		clr	bh
		test	es:[di].EDD_charSysFlags, EV_KEY
		je	baseNotVirtual			; branch if base key not virtual
		dec	ah				; ah <- 0xff: base is virtual
baseNotVirtual:
		test	es:[di].EDD_charSysFlags, EV_SHIFT
		je	shiftNotVirtual			; branch if shifted not virtual
		dec	bh				; bh <- 0xff: shifted is virtual
shiftNotVirtual:
endif
		stc					; indicate no translation
		jmp	finishUp
doAccent:
		push	ax, bx
SBCS <		mov	al, {byte}es:[di][bx]				>
DBCS <		mov	ax, {Chars}es:[di][bx][-3]			>
		clr	bx

	;
	;	es:di gets head of accent table
	;
		movdw	esdi, ds:[kbdKeyTableListPtr]
		movdw	esdi, es:[di].KTL_accentDefs

accentLoop:
SBCS <		cmp	{byte}es:[di][bx], al				>
DBCS <		cmp	{Chars}es:[di][bx], ax				>
		je	foundAccent		; branch if match
		inc	bx
DBCS <		inc	bx
EC <		cmp	bx, KBD_NUM_ACCENTS
EC <		ERROR_AE	KBD_BAD_ACCENT_TABLE			>
		jmp 	accentLoop
		
foundAccent:
	;
	;	indicate accent pending
	;
SBCS <		mov	ds:kbdAccentPending, al 			>
DBCS <		mov	ds:kbdAccentPending, ax

		mov	ds:kbdAccentOffset, bl
		mov	si, bp			; restore si-> keyDown
		or 	ds:[si].KDE_charFlags, mask CF_TEMP_ACCENT
		pop	ax, bx
		jmp	afterAccent
		

HandleExtendedDef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleExtendedSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if extended char should be in non-ctrl set

CALLED BY:	HandleExtendedDef

PASS:		es:di	-> ptr to ExtendedDef entry in table
		bx	-> offset into ExtendedDef struct
		ds	-> dgroup
		ah	-> VC_ISCTRL

RETURN:		ah	<- char set for key
DESTROYED:	nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Search ExtendedExtended table for matching offset

		If located, return correct type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/04/97		Modified kbd driver version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	not DBCS_PCGEOS

HandleExtendedSet	proc	near
	;
	; Don't bother if extended char sets not used.
	;
		test	ds:[kbdOptions], mask GKO_EXTENDED_CHAR_SET
		jz	exit
		
	;
	;  Scan table for matching Def.  Make sure there is a table.
	;
		push	cx, di, si, ds 
		movdw	dssi, ds:[kbdKeyTableListPtr]
		mov	cx, ds:[si].KTL_numKeyExtExts
		jcxz	done				; no table
		
		movdw	dssi, ds:[si].KTL_keyExtExts	; ds:si = table
		sub	di, si		; di = offset to ExtendedDef
topOfLoop:
		cmp	di, ds:[si].EED_di		; does DI match?
		je	checkBX				; => matches!
afterCheck:
		add	si, size ExtendedExtendedDef	; go to next def
		loop	topOfLoop			; => check next def

done:
		pop	cx, di, si, ds
exit:
		ret

checkBX:
		cmp	bx, ds:[si].EED_bx		; does BX match?
		jne	afterCheck			; => no match...

		mov	ah, ds:[si].EED_charSet		; get correct set
		jmp	done

HandleExtendedSet	endp

endif ; not DBCS_PCGEOS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleExtendedCapslock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip the case of the extended char if the caps lock is on and
		a different case of this char exists

CALLED BY:	HandleExtendedDef
PASS:		es:di	-> ExtendedDef table entry
		ds:si	-> head of extFlipCaseTable
		dx	-> number of extFlipCase
		SBCS:
			bx = ExtOffsets (offset into ExtendedDef for this char)
			ah = char set (VC_ISxx)
		DBCS:
			bx = ExtOffsets shl 1 (offset+3 into ExtendedDef for
				this char)
RETURN:		bx	<- modified offset pointing to the char with the
			   right case.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleExtendedCapslock	proc	near

		uses	cx, ax
		.enter
	;
	;	Do nothing if Caps-Lock off or non-ANSI character set.
	;
		push	ds, ax
		mov	ax, segment dgroup
		mov	ds, ax
		test	ds:[kbdToggleState], TOGGLE_CAPSLOCK
		jz	done
		pop	ds, ax

	;
	;	See if ah = VC_ISANSI, done if not.
	;
SBCS <		CheckHack <VC_ISANSI eq 0>				>
SBCS <		tst	ah						>
SBCS <		jnz	done						>

	;
	;	Scan the char table to see if we have to flip the case.
	;
SBCS <		LocalLoadChar	ax, {Chars}es:[di][bx]			>
DBCS <		LocalLoadChar	ax, {Chars}es:[di][bx-3]		>
	
		segxchg	ds, es
		xchg	si, di
		mov	cx, dx			; cx = length of FlipCase table
		LocalFindChar
		segxchg	ds, es
		xchg	si, di
		jne	done

	;
	;	Character found, flip the case by flipping the EO_SHIFT bit.
	;

SBCS <		xornf	bx, EXT_SHIFT_MASK				>
DBCS <		xornf	bx, (EXT_SHIFT_MASK) shl 1			>

done:
		.leave
		ret
HandleExtendedCapslock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNormalDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle case of normal KeyDef, checking for use of the ALT
		translation.

CALLED BY:	INTERNAL: ProcessScanCode
PASS:		ch	-> Modifier used in translation so far
		dh	-> First byte of KeyDef for this scan code
		dl	-> KeyType only, for this scan code

		es:[di] -> pointer to KeyDef for scan code beign procesed
RETURN:
		if carry clear: scan code has been translated
		ax 	<- charValue
		ch	<- updated to show any new modifiers involved in
			  translation
		bh, cl	<- destroyed

		if carry set: scan code not translated
		ah 	<- FF or 00, based on keyType
		bh	<- FF or 00.
		cl	<- destroyed

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	5/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNormalDef	proc	near

		.enter
		clr	ah, bh				; char options

	;
	;	see if normal or virtual
	;
		cmp	dl, MIN_VIRTUAL_KEY_TYPE
		jb 	afterVirtual			; branch if normal
		dec	ah				; ah <- 0xff: virtual
		dec	bh				; bh <- 0xff: virtual

afterVirtual:
		mov	cl, es:[di].KD_keyType
		test	cl, KD_ACCENT
 		je	notAccent			; branch if not an accent
		mov	ah, 0ffh			; ah <-0xff: virtual
	
notAccent:
		test	cl, KD_EXTENDED			; see if extended
		je	noTranslation
		
		CheckHack < kbdShiftState + size byte eq kbdToggleState>
		test	{word}ds:[kbdShiftState], \
			(CTRL_KEYS) or (TOGGLE_CTRLSTICK) shl 8
		jnz	noTranslation

		test	ds:[kbdShiftState], ALT_KEYS
		jz 	noTranslation

		or	ch, ALT_KEYS
		mov	al, es:[di].KD_extEntry		; al <- extended entry
		clc					; indicate translation
		jmp	short done

noTranslation:
		stc		
done:
		.leave
		ret

HandleNormalDef	endp

Resident 	ends













