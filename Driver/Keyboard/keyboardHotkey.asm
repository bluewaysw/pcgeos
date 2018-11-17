COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		keyboardHotKey.asm

AUTHOR:		Adam de Boor, May 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/30/92		Initial revision


DESCRIPTION:
	Functions for dealing with hotkeys. 
		
	XXX: use IsCharOnKey to locate viable scancodes, rather than all
	this other stuff we've got.

	$Id: keyboardHotkey.asm,v 1.1 97/04/18 11:47:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCheckHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current scan code is a registered hotkey and
		act on it.

CALLED BY:	KbdInterrupt
PASS:		al	= scan code
		ds = es	= dgroup
RETURN:		carry set if key processed:
			ax	= destroyed
		carry clear if key not processed:
			ax	= preserved
DESTROYED:	cx, bx, dx, si, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn		HARDWARE_TYPE, <PC>
KbdCheckHotkey	proc	near
		.enter
		test	ds:[kbdStratFlags], mask KSF_HAVE_HOTKEY
		jz	done
		
		push	ax
		mov	ah, ds:[kbdShiftState]
		mov	cx, ds:[keyboardNumHotkeys]
		mov	di, offset keyboardHotkeys

		test	ds:[kbdStratFlags], mask KSF_ALL_HOTKEY
		jz	search
		mov	ax, SCANCODE_ILLEGAL	; search for special key
search:
		repne	scasw
		pop	ax
		clc
		jne	done
		
	;
	; Pass the scan code and shift state in the message.
	;
		mov	ah, ds:[kbdShiftState]
		mov_tr	cx, ax			; cx = <ShiftState, scan code>

	;
	; Found a match. Disable the keyboard interface so the keyboard
	; continues to store scan codes, but can't send them to us, thereby
	; keeping the scancode in the keyboard data latch for the interested
	; external party to read.
	; 
		test	ds:[kbdStratFlags], mask KSF_USE_PC_ACK
		jnz	disableXT
		
		mov	al, KBD_CMD_DISABLE_INTERFACE
		out	KBD_COMMAND_PORT, al
		jmp	sendNotification

disableXT:
		in	al, KBD_PC_CTRL_PORT
		andnf	al, not mask XP61_KBD_DISABLE
		out	KBD_PC_CTRL_PORT, al

sendNotification:
	;
	; Flag the hotkey as pending so we know to keep the interface
	; disabled if we suspend.
	; 
		ornf	ds:[kbdStratFlags], mask KSF_HOTKEY_PENDING
	;
	; Load up the notification message and queue it.
	; 
		mov	bx, ds:[di-2][keyboardADHandles-keyboardHotkeys]
		mov	si, ds:[di-2][keyboardADChunks-keyboardHotkeys]
		mov	ax, ds:[di-2][keyboardADMessages-keyboardHotkeys]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		stc
done:
		.leave
		ret
KbdCheckHotkey	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdPassHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass control to the previous keyboard-interrupt handler
		so it can recognize the hotkey.

CALLED BY:	DR_KBD_PASS_HOTKEY
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn		HARDWARE_TYPE, <PC>
KbdPassHotkey	proc	near
		.enter
	;
	; Pass control off as if it were an interrupt.
	; 
		pushf
		cli
		call	ds:[kbdVector]
	;
	; Flush keyboard buffer on return, in case no one was actually
	; interested in the keystroke we just passed on.
	;
		INT_OFF
		push	ds
		mov	ax, BIOS_SEG
		mov	ds, ax
		mov	ax, ds:[BIOS_KEYBOARD_BUFFER_TAIL_POINTER]
		mov	ds:[BIOS_KEYBOARD_BUFFER_HEAD_POINTER], ax
		pop	ds		
		INT_ON
	;
	; Re-enable the keyboard interface.
	; 
		call	KbdCancelHotkey
		.leave
		ret
KbdPassHotkey	endp
else
KbdPassHotkey	proc	near
		ret
KbdPassHotkey	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdCancelHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've decided not to hand off the keypress after all, so
		re-enable the keyboard interface.

CALLED BY:	DR_KBD_CANCEL_HOTKEY
PASS:		ds 	= dgroup
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn		HARDWARE_TYPE, <PC>
KbdCancelHotkey	proc	near
		.enter
		andnf	ds:[kbdStratFlags], not mask KSF_HOTKEY_PENDING
	;
	; Now enable the interface. For an 8042, we send just the appropriate
	; command to its command port.
	; 
		test	ds:[kbdStratFlags], mask KSF_USE_PC_ACK
		jnz	enableXT
		
		mov	al, KBD_CMD_ENABLE_INTERFACE
		out	KBD_COMMAND_PORT, al
		jmp	done

enableXT:
	;
	; For an XT, set the appropriate bit in the KBD_PC_CTRL_PORT.
	; 
		in	al, KBD_PC_CTRL_PORT
		ornf	al, mask XP61_KBD_DISABLE
		out	KBD_PC_CTRL_PORT, al

done:
		.leave
		ret
KbdCancelHotkey	endp
else
KbdCancelHotkey	proc	near
		ret
KbdCancelHotkey	endp
endif

KbdAddHotkeyStub proc near
ifidn		HARDWARE_TYPE, <PC>
		call	KbdAddHotkey
else
		stc
endif
		ret
KbdAddHotkeyStub endp

KbdDelHotkeyStub proc near
ifidn		HARDWARE_TYPE, <PC>
		call	KbdDelHotkey
endif
		ret
KbdDelHotkeyStub endp

Resident	ends



Movable		segment	resource

ifidn		HARDWARE_TYPE, <PC>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdAddHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a hotkey to be watched for.

CALLED BY:	DR_KBD_ADD_HOTKEY
PASS:		ah	= ShiftState
		cx	= character (ch = CharacterSet, cl = Chars/VChars)
		^lbx:si	= object to notify when the key is pressed
		bp	= message to send it
		ds	= dgroup (from strategy routine)
RETURN:		carry set if hotkey couldn't be added.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdAddHotkey	proc	far
		uses	dx
		.enter
		mov	dx, offset KbdAddHotkeyLow
		call	KbdAddDelHotkeyCommon
		.leave
		ret
KbdAddHotkey	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdAddHotkeyLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add another entry into the hotkey table, if possible.

CALLED BY:	KbdAddHotkey via KbdAddDelHotkeyCommon
PASS:		ax	= ShiftState/scan code pair
		ds:di	= existing entry in table with same pair; di = 0 if
			  none
		^lbx:si	= object to notify when typed
		bp	= message to send it.
RETURN:		carry set if no room
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdAddHotkeyLow	proc	near
		.enter
		tst	di
		jnz	haveSlot
	;
	; Not passed a slot, so we have to find one that contains 0.
	; 
		mov	cx, MAX_HOTKEYS
		mov	di, offset keyboardHotkeys
		push	ax
		clr	ax
		repne	scasw
		pop	ax
		jne	error
	;
	; Found a slot. Figure what index it is in the array and set 
	; keyboardNumHotkeys as appropriate..
	; 
		dec	di
		dec	di
		sub	cx, MAX_HOTKEYS
		neg	cx
		cmp	cx, ds:[keyboardNumHotkeys]
		jbe	haveSlot
		mov	ds:[keyboardNumHotkeys], cx
haveSlot:
	;
	; Set flag indicating that we have hotkey
	;
		cmp	ax, SCANCODE_ILLEGAL
		jne	haveHotkey
		ORNF	ds:[kbdStratFlags], mask KSF_ALL_HOTKEY
haveHotkey:
		ORNF	ds:[kbdStratFlags], mask KSF_HAVE_HOTKEY

	;
	; Store the combination and the action descriptor in their respective
	; arrays.
	; 
		INT_OFF
		mov	ds:[di], ax
		mov	ds:[di][keyboardADHandles-keyboardHotkeys], bx
		mov	ds:[di][keyboardADChunks-keyboardHotkeys], si
		mov	ds:[di][keyboardADMessages-keyboardHotkeys], bp
		INT_ON
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
KbdAddHotkeyLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdDelHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a hotkey being watched for.

CALLED BY:	DR_KBD_REMOVE_HOTKEY
PASS:		ah	= ShiftState
		cx	= character (ch = CharacterSet, cl = Chars/VChars)
		ds	= dgroup (from strategy routine)
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdDelHotkey	proc	far
		uses	dx
		.enter
		mov	dx, offset KbdDelHotkeyLow
		call	KbdAddDelHotkeyCommon
		.leave
		ret
KbdDelHotkey	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdDelHotkeyLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke a hotkey from the table.

CALLED BY:	KbdDelHotkey via KbdAddDelHotkeyCommon
PASS:		ax	= ShiftState/scan code pair
		ds:di	= slot in table where it may be found; di = 0 if not
			  there.
RETURN:		carry set to stop enumerating scan codes
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdDelHotkeyLow	proc	near
		.enter
		tst	di
		jz	done		; not in table => nothing to biff
		
		mov	{word}ds:[di], 0

		cmp	ax, SCANCODE_ILLEGAL
		jne	numHotkeys
		ANDNF	ds:[kbdStratFlags], not (mask KSF_ALL_HOTKEY)
numHotkeys:
		dec	ds:[keyboardNumHotkeys]
		jnz	done
		ANDNF	ds:[kbdStratFlags], not (mask KSF_HAVE_HOTKEY)
done:
		.leave
		ret
KbdDelHotkeyLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdAddDelHotkeyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure all the various modifier/scancode combinations
		required to watch for a given modifier/character pair and
		call a callback function for each one, after seeing if
		the m/s combination is already in the table of known ones.

CALLED BY:	KbdAddHotkey, KbdDelHotkey
PASS:		ah	= ShiftState
		cx	= character (ch = CharacterSet, cl = Chars/VChars)
		ds 	= dgroup
		cs:dx	= near routine to call:
RETURN:		carry set if callback returned carry set
DESTROYED:	

PSEUDO CODE/STRATEGY:
		figure out where we should look for the character (KeyDef or
			ExtendedDef) based on the modifiers
		foreach entry in the keymap:
			if KD_char matches character, ShiftState+current scan
				is a combination
			else if KD_keyType != KEY_PAD, KEY_SHIFT, KEY_TOGGLE,
					KEY_XSHIFT or KEY_XTOGGLE and
				appropriate char matches chararcter,
				ShiftState+current scan is a combination

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdAddDelHotkeyCommon proc	near
		.enter
	;
	; If we get CharacterSet = VC_ISCTRL, and VChars = VC_INVALID_KEY,
	; we redirect all keys.
	;
SBCS <		cmp	cx, (VC_ISCTRL shl 8) or VC_INVALID_KEY		>
DBCS <		cmp	cx, C_NOT_A_CHARACTER				>
		jne	normalAddDel

		push	ax
		clr	ah			; say we have no ShiftState
		call	KbdHKFoundScan
		pop	ax
		jmp	short done

normalAddDel:
		call	KbdFigureModifiedCharOffset
		
		mov	di, offset KbdKeyDefTable
scanLoop:
		call	KbdHKCheckScan
		jnc	nextScan
		call	KbdHKFoundScan
		jc	done			; => callback returned
						;  carry set, so stop
nextScan:
		add	di, size KeyDef
		cmp	di, offset KbdKeyDefTable + KBD_MAX_SCAN*size KeyDef
		jb	scanLoop
done:
		.leave
		ret
KbdAddDelHotkeyCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdHKCheckScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the character matches this scan code's character.

CALLED BY:	KbdAddDelHotkeyCommon
PASS:		al	= second offset to check in key definition
		cx	= character against which to match
		ds:di	= KeyDef to check
RETURN:		carry set if matches
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdHKCheckScan 	proc	near
		uses	ax
		.enter
	;
	; Check modified form first.
	; 
		call	KbdHKCheckChar
		jc	done
	;
	; No match. Try unmodified form.
	; 
		mov	al, KD_char
		call	KbdHKCheckChar
done:
		.leave
		ret
KbdHKCheckScan	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdHKCheckChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the character matches that generated from a particular
		slot within a key definition.

CALLED BY:	KbdHKCheckScan
PASS:		al	= if b7=0: offset within KeyDef to check
			  if b7=1: offset within ExtendedDef to check
		cx	= character to compare
		ds:di	= KeyDef to use
RETURN:		carry set if matches
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdHKCheckChar	proc	near
		uses	ax, bx, dx, di
		.enter
		mov	ah, ds:[di].KD_keyType
		tst	ah
		jz	done		; => scan not valid (carry clear)
	;
	; If the key is KEY_SOLO, it can never produce any char but
	; what's in KD_char (Chars/VChars) and KD_shiftChar (CharacterSet)
	; 
		mov	dh, ah
		andnf	dh, mask KDF_TYPE
		cmp	dh, KEY_SOLO
		jne	fetchChar
	
		mov	ax, {word}ds:[di].KD_char
		jmp	compare

fetchChar:
	;
	; State keys don't good hotkeys make...
	; 
		test	ah, mask KDF_STATE_KEY
		jnz	mismatch
	;
	; We'll need the offset in bx for fetching a byte...
	; 
		mov	bx, ax
		andnf	bx, 0x7f
	;
	; Fetch the character from the KeyDef or the ExtendedDef.
	; 
		test	al, 0x80	; requires extended def?
		jnz	checkExtended
	;
	; Fetch the char from the key def.
	; 
		mov	al, ds:[di][bx]
	;
	; Figure if it's virtual (ah <- CS_CONTROL) or normal (ah <- CS_BSW):
	; 	KEY_PAD, KEY_MISC
	; 
SBCS <			CheckHack <CS_BSW eq 0>				>
		clr	ah		; assume not virtual
		cmp	dh, KEY_PAD
		je	makeVirtual
		cmp	dh, KEY_MISC
		jne	compare
makeVirtual:
PrintMessage <fix KbdHKCheckChar>
SBCS <		mov	ah, CS_CONTROL					>
DBCS <		mov	ah, CS_CONTROL_HB				>
		jmp	compare

checkExtended:
	;
	; If key has no extended definition, there's nowhere to check.
	; 
		test	ah, mask KDF_EXTENDED
		jz	mismatch
		
	;
	; Figure offset of extended entry in KbdExtendedDefTable
	; 
		mov	al, ds:[di].KD_extEntry
		clr	ah
		shl	ax
		shl	ax
		shl	ax
if DBCS_PCGEOS
			CheckHack <size ExtendedDef eq 16>
		shl	ax
else
			CheckHack <size ExtendedDef eq 8>
endif
		add	ax, offset KbdExtendedDefTable
	;
	; Fetch the bit that must be set in EDD_charSysFlags for the character
	; to be virtual and that must not be set in EDD_charAccents for the
	; character to be valid....?
	; 
		mov	dl, cs:[hkVirtBits-EDD_ctrlChar][bx]
		mov	dh, dl
		xchg	ax, bx
SBCS <		and	dx, {word}ds:[bx].EDD_charSysFlags		>
		add	bx, ax		; ds:bx <- &char
		mov	al, ds:[bx]
SBCS <			CheckHack <CS_BSW eq 0>				>
		clr	ah		; assume not virtual
		tst	dl
		jnz	makeVirtual
compare:
	;
	; AX is now the Chars/VChars + CharacterSet that would be generated
	; from the provided slot in the definition. See if it matches what we
	; were asked about.
	; 
		cmp	ax, cx
		je	flipCarry	; => yes; carry is clear, but want it
					;  set
mismatch:
		stc			; ensure carry will be clear when we
					;  complement it, signalling a mismatch
flipCarry:
		cmc
done:
		.leave
		ret
hkVirtBits	ExtVirtualBits	mask EVB_CTRL,		; EDD_ctrlChar
				mask EVB_SHIFT_CTRL,	; EDD_shiftCtrlChar
				mask EVB_ALT,		; EDD_altChar
				mask EVB_SHIFT_ALT,	; EDD_shiftAltChar
				mask EVB_CTRL_ALT,	; EDD_ctrlAltChar
				mask EVB_SHIFT_CTRL_ALT ; EDD_shiftCtrlAltChar
KbdHKCheckChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdHKFoundScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Found a scan code that's acceptable. See if it's in the
		table of known hotkeys and call the callback appropriately.

CALLED BY:	KbdAddDelHotkeyCommon
PASS:		ah	= ShiftState
		cx	= character (ch = CharacterSet, cl = Chars/VChars)
		ds:di	= KeyDef
		cs:dx	= callback routine
RETURN:		carry set if callback returned carry set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		callback is called:
			Pass:	ax	= ShiftState/scan code pair
				ds:di	= slot in table where pair is
					  located. di is 0 if not already
					  in the table
				es	= ds
				bx, si, bp as passed to KbdAddDelHotkeyCommon
			Return:	carry set to stop going through the table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdHKFoundScan	proc	near
		uses	ax, cx, di
		.enter
	;
	; Check character to see if all characters need to be redirected
	;
		mov	al, SCANCODE_ILLEGAL
SBCS <		cmp	cx, (VC_ISCTRL shl 8) or VC_INVALID_KEY		>
DBCS <		cmp	cx, C_NOT_A_CHARACTER				>
		je	haveScanCode
	;
	; Figure the scan code. We subtract size KeyDef from the start of
	; KbdKeyDefTable since scan codes start at 1.
	; 
		sub	di, offset KbdKeyDefTable-size KeyDef
		shr	di
		shr	di
if DBCS_PCGEOS
			CheckHack <size KeyDef eq 8>
		shl	di
else
			CheckHack <size KeyDef eq 4>
endif
	;
	; Put the scan code into al.
	; 
		mov	cx, di
		mov	al, cl

haveScanCode:
	;
	; Now see if the thing's already in the table.
	; 
		mov	di, offset keyboardHotkeys
		segmov	es, ds
		mov	cx, ds:[keyboardNumHotkeys]
		jcxz	notInTable
		repne	scasw
		lea	di, ds:[di-2]
		je	callCallback
notInTable:
		clr	di
callCallback:
		call	dx
		.leave
		ret
KbdHKFoundScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdFigureModifiedCharOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the offset of the place to look for the character 
		within a key definition, given the set of modifiers to
		be applied.

CALLED BY:	KbdAddDelHotkeyCommon
PASS:		ah	= ShiftState
RETURN:		al	= if b7 is 0:
				offset of slot in KeyDef to check
			  if b7 is 1:
				offset of slot in ExtendedDef to check
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdFigureModifiedCharOffset proc near
		.enter
	;
	; Assume no modifiers.
	; 
		mov	al, offset KD_char
		tst	ah
		jz	done
		
		test	ah, mask SS_LSHIFT or mask SS_RSHIFT
		jz	notShifted
		
		mov	al, offset KD_shiftChar	; assume just shift
		test	ah, mask SS_LCTRL or mask SS_RCTRL
		jz	notShiftCtrl
		
		mov	al, offset EDD_shiftCtrlChar or 0x80
		test	ah, mask SS_LALT or mask SS_RALT
		jz	done
		
		mov	al, offset EDD_shiftCtrlAltChar or 0x80
		jmp	done

notShiftCtrl:
		test	ah, mask SS_LALT or mask SS_RALT
		jz	done		; => just shift
		
		mov	al, offset EDD_shiftAltChar or 0x80
		jmp	done

notShifted:
		mov	al, offset EDD_altChar or 0x80
		test	ah, mask SS_LCTRL or mask SS_RCTRL
		jz	done
		
		mov	al, offset EDD_ctrlChar or 0x80
		test	ah, mask SS_LALT or mask SS_RALT
		jz	done

		mov	al, offset EDD_ctrlAltChar or 0x80
done:
		.leave
		ret
KbdFigureModifiedCharOffset endp

endif

Movable		ends
