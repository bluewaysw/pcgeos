COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		gdi-keyboardInit.asm

AUTHOR:		Kenneth Liu, Apr 24, 1996

ROUTINES:
	Name			Description
	----			-----------
	KbdInitFar		Initialize keyboard
	InitKbdOptions		Initialize GDI keyboard options
	KbdSwapCtrl		Swap the meaning for left-ctrl and caplock
	KbdAltGr		Right <Alt> act as <Ctrl><Alt>
	CheckKeyboardOption	Check .INI file for GDI keyboard option
	KbdExitFar		Exit keyboard
	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu		4/24/96   	Initial revision


DESCRIPTION:
	
	$Id: gdiKeyboardInit.asm,v 1.1 97/04/18 11:47:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable segment resource

keyboardCategoryStr	char	"GDI keyboard", 0

keyboardShiftStickStr	char	"shift_stick_implies_shift", 0
keyboardAltStickStr	char	"alt_stick_implies_alt", 0
keyboardIgnoreShiftStateStr	char \
		"ignore_shift_state_for_pgup_pgdn",0
keyboardShiftExtStr	char	"shiftedExtension", 0
keyboardShiftReleaseStr	char	"shiftRelease", 0
keyboardSwapCtrl	char	"swapCtrl", 0
keyboardAltGr		char	"altGr", 0
keyboardHandleToggles	char	"kbdHandleToggles",0
keyboardExtendedCharSet	char	"extendedCharSet",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdInitFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
 
CALLED BY:	INTERNAL: KbdInit
PASS:		ds	-> dgroup
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

nnPSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description

	----	----		-----------
	kliu	4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdInitFar	proc	far

		uses	ax, bx, cx, dx, ds, si, di
		.enter
	;
	;	use gdi-lib init function
	;
		call	GDIKeyboardInit		; ax = KeyboardErrorCode
EC <		cmp	ax, EC_NO_ERROR
EC <		ERROR_NE EC_NO_ERROR
		
	;
	; 	add the imonitor
	;
		Assert	dgroup, ds
		mov	al, ML_DRIVER
		mov	bx, offset kbdMonitor
		mov	cx, segment Resident
		mov	dx, offset Resident:KbdMonRoutine
		call	ImAddMonitor		; input manager handle => BX
						; ax, cx, dx destroyed

		mov	ds:[kbdOutputProcHandle], bx

	;
	;	register the callback
	;
		mov	dx, segment Resident
		mov	si, offset Resident:KbdCallback
		call	GDIKeyboardRegister
EC <		cmp	ax, EC_NO_ERROR
EC <		ERROR_NE KBD_REGISTER_CALLBACK_ERROR

	;
	;	Now get the keymap table from the GDI-lib, set record in dgroup
	;
		Assert	dgroup, ds
		call	GDIKeyboardInfo
EC <		cmp	ax, EC_NO_ERROR
EC <		ERROR_NE KBD_GET_INFO_ERROR
		mov	ds:[kbdKeyTableListPtr.segment], dx
		mov	ds:[kbdKeyTableListPtr.offset], si

	;
	;	Finally, read .ini file and get the GdiKeyboardOptions right
	;
		call	InitKbdOptions

	;
	;	Call function to swap ctrl and caplock if we are
	;	asked for.

		test	ds:kbdOptions, mask GKO_SWAP_CTRL
		jz	checkAltGr
		call	KbdSwapCtrl

checkAltGr:
	;
	;	Deal with Alt_gr if option is set.
	;
		test	ds:kbdOptions, mask GKO_ALT_GR
		jz	done
		call	KbdAltGr

done:
		clc
		.leave
		ret
KbdInitFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitKbdOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the GDIKbdOptions record.

CALLED BY:	INTERNAL: KbdInitFar
PASS:		ds	-> dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	6/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitKbdOptions	proc	near
		uses	cx, bx, dx, si
		.enter

	;
	;	Check whether shift stick implies shift
	;
		mov	dx, offset keyboardShiftStickStr
		mov	bx, mask GKO_SHIFT_STICK_IMPLIES_SHIFT
		call	CheckKeyboardOption

	;
	;	Check whether alt stick implies alt
	;
		mov	dx, offset keyboardAltStickStr
		mov	bx, mask GKO_ALT_STICK_IMPLIES_ALT
		call	CheckKeyboardOption

	;
	;	Check whether ignoring shiftState on page up and page down
	;
		mov	dx, offset keyboardIgnoreShiftStateStr
		mov	bx, mask GKO_IGNORE_SHIFT_STATE_FOR_PGUP_PGDN
		call	CheckKeyboardOption

	;
	;	Check whether supporting shifted version of extended key
	;
		mov	dx, offset keyboardShiftExtStr
		mov	bx, mask GKO_SHIFTED_EXTENSION
		call	CheckKeyboardOption

	;
	;	Check for shift release
	;
		mov	dx, offset keyboardShiftReleaseStr
		mov	bx, mask GKO_SHIFT_RELEASE
		call	CheckKeyboardOption

	;
	;	Check for swap ctrl
	;
		mov	dx, offset keyboardSwapCtrl
		mov	bx, mask GKO_SWAP_CTRL
		call	CheckKeyboardOption

	;
	;	Check for Alt Gr
	;
		mov	dx, offset keyboardAltGr
		mov	bx, mask GKO_ALT_GR
		call	CheckKeyboardOption

	;
	;	Check for Keyboard Handling Toggles
	;
		mov	dx, offset keyboardHandleToggles
		mov	bx, mask GKO_KBD_HANDLE_TOGGLES
		call	CheckKeyboardOption

	;
	;	Check if extended character sets are used
	;
		mov	dx, offset keyboardExtendedCharSet
		mov	bx, mask GKO_EXTENDED_CHAR_SET
		call	CheckKeyboardOption

		.leave
		ret
InitKbdOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdSwapCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
SYNOPSIS:	Swap the scancode for caplock and left ctrl.

CALLED BY:	INTERNAL: KbdInitFar
PASS:		dx:si	-> kbdKeyTableListPtr
RETURN:		nothing
DESTROYED:	ds, cx, di, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdSwapCtrl	proc	near
		uses	bp, si
		.enter

		mov	ds, dx
		mov	bx, ds:[si].KTL_caplockScan
		mov	bp, ds:[si].KTL_leftCtrlScan
		dec	bx
		dec	bp
if DBCS_PCGEOS
		CheckHack <size KeyDef eq 8>
		shl	bx, 1
		shl	bp, 1
else
		CheckHack <size KeyDef eq 4>
endif
		shl	bx, 1
		shl	bx, 1
		shl	bp, 1
		shl	bp, 1

	;
	;	Now get pointer to keyDef table
	;
		movdw	dssi, ds:[si].KTL_keyDefs
		lea	di, ds:[si][bx]
		lea	si, ds:[si][bp]
		mov	cx, (size KeyDef)

	;
	;	Swap the two KeyDefs in the table
	;
ko_loop:
		lodsb
		xchg	ds:[di], al
		mov	ds:[si][-1], al
		inc	di
		loop	ko_loop

		.leave
		ret
		
KbdSwapCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdAltGr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set right <Alt> key to act as <Ctrl><Alt> and return
		<Alt Gr> for a character value.

CALLED BY:	INTERNAL: KbdInitFar
PASS:		dx:si	-> kbdKeyTableListPtr
RETURN:		nothing
DESTROYED:	bx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdAltGr	proc	near

		.enter

		mov	ds, dx
		mov	bx, ds:[si].KTL_rightAltScan
		dec	bx			; bx -> scancode_right_alt-1
	;
	;	Now get pointer to KeyDef
	;
		movdw	dssi, ds:[si].KTL_keyDefs
if DBCS_PCGEOS
		CheckHack	<size KeyDef eq 8>
		shl	bx, 1
else
		CheckHack	<size KeyDef eq 4>
		shl	bx, 1
		shl	bx, 1
endif

if DBCS_PCGEOS
		mov	ds:[si][bx].KD_char, C_SYS_ALT_GR
else
		mov	ds:[si][bx].KD_char, VC_ALT_GR
endif
		mov	ds:[si][bx].KD_shiftChar, \
			RCTRL or RALT

		.leave
		ret
KbdAltGr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckKeyboardOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check .ini settings for the GDI Keyboard Driver.

CALLED BY:	INTERNAL: InitKbdOptions
PASS:		cs:dx	-> seg addr of idata
		ds	-> dgroup
		bx	-> which setting to initialize (GDIKbdOption)
RETURN:		carry clear if keyboard setting initialize
		carry set if ini setting can't be found.
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
	
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	6/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckKeyboardOption	proc	near

		.enter
	;
	;	Check the appropriate category
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset keyboardCategoryStr
		call	InitFileReadBoolean
		pop	ds
		jc	error
		tst	al
		jz	isFalse
		ornf	ds:kbdOptions, bx	; set bit in settings
done:
		.leave
		ret

isFalse:
		not	bx 
		andnf	ds:kbdOptions, bx

		jmp	done
error:
		stc
		jmp	done

		
CheckKeyboardOption	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KbdExitFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	KbdExit
PASS:		ds	-> dgroup
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	4/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KbdExitFar	proc	far

		uses	ax, dx, si, bx
		.enter
	;
	;	Unregister callback routine
	;
		mov	dx, segment Resident
 		mov	si, offset Resident:KbdCallback
		call 	GDIKeyboardUnregister
EC <		cmp	ax, EC_NO_ERROR
EC <		ERROR_NE KBD_UNREGISTER_CALLBACK_ERROR
		
	;
	;	Shut it down NOW!
	;
		call	GDIKeyboardShutdown
EC <		cmp	ax, EC_NO_ERROR
EC <		ERROR_NE KBD_SHUTDOWN_ERROR

	;
	;	Remove the keyboard monitor 
	;
		Assert dgroup, ds
		mov	bx, offset kbdMonitor
		mov	al, mask MF_REMOVE_IMMEDIATE
		call	ImRemoveMonitor			; remove monitor
		
		clc
		.leave
		ret
		
KbdExitFar	endp
	
Movable		ends	





















