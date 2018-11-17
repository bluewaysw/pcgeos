COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdiKeyboard.asm

AUTHOR:		Todd Stumpf, Apr 29, 1996

ROUTINES:
	Name			Description
	----			-----------
	GDIKeyboardInit		Call hardware specific init routines to
				initialize keyboard hardware.
	GDIKeyboardInfo		Return KeyDef and other tables to driver.
	GDIKeyboardRegister	Register the driver's callback.
	GDIKeyboardUnregister	Unregister the driver's callback.
	GDIKeyboardShutdown	Clean up and shut down keyboard.
	GDIKeyboardGetKey	Return the next scan code pending.
	GDIKeyboardPassHotkey
	GDIKeyboardCancelHotkey
	GDIKeyboardAddHotkey
	GDIKeyboardDelHotkey	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96   	Initial revision


DESCRIPTION:

	$Id: gdiKeyboard.asm,v 1.1 97/04/04 18:03:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize Keyboard module of GDI library

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set on error
		ax	<-	KeyboardErrorCode
DESTROYED:	flags only

SIDE EFFECTS:
		Initializes hardware

PSEUDO CODE/STRATEGY:
		Call common initialization routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardInit	proc	far
if HAS_KEYBOARD_HARDWARE
	uses	dx, si
	.enter

	;
	;  Activate Keyboard interface
	.assert	segment HWKeyboardInit	eq segment GDIKeyboardInit
	mov	dx, mask IMF_KEYBOARD			; dx <- interface mask
	mov	si, offset HWKeyboardInit		; si <- actual HW rout.
	call	GDIInitInterface		; carry set on error
						; ax <- ErrorCode

	.leave
else
	;
	;  Let caller know, no keyboard is present
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc

endif
	ret
GDIKeyboardInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return necessary keyboard info

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		dx:si	<- ptr to KeyTableList
		ax	<- KeyboardErrorCode
		carry set on error (si, dx preserved)
DESTROYED:	flags only

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Return keyboards to needed tables		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardInfo	proc	far
if HAS_KEYBOARD_HARDWARE

	mov	dx, segment keyTableList	
	mov	si, offset keyTableList
	mov	ax, EC_NO_ERROR
	clc

else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret

GDIKeyboardInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a Keyboard callback with the library

CALLED BY:	GLOBAL
PASS:		dx:si	-> fptr of fixed routine to call
RETURN:		carry set on error
		ax	<- KeyboardErrorCode
DESTROYED:	flags only

SIDE EFFECTS:
		Adds callback to list of keyboard callbacks

PSEUDO CODE/STRATEGY:
		Call common registration routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardRegister	proc	far
if HAS_KEYBOARD_HARDWARE
	uses	bx
	.enter

	;
	;  Try to add callback to list of Keyboard callbacks
							; dx:si -> callback
	mov	bx, offset keyboardCallbackTable	; bx -> callback table
	call	GDIRegisterCallback		; carry set on error
						; ax <- ErrorCode

	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIKeyboardRegister	endp

InitCode			ends


ShutdownCode			segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove previously registered callback

CALLED BY:	GLOBAL
PASS:		dx:si	-> fptr for callback
RETURN:		carry set on error
		ax	<- KeyboardErrorCode
DESTROYED:	nothing

SIDE EFFECTS:
		Removes callback from list

PSEUDO CODE/STRATEGY:
		Call common de-registration routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardUnregister	proc	far
if HAS_KEYBOARD_HARDWARE
	uses	bx
	.enter
	;
	;  Try to add callback to list of Keyboard callbacks
							; dx:si -> callback
	mov	bx, offset keyboardCallbackTable	; bx -> callback table
	call	GDIUnregisterCallback		; carry set on error
						; ax <- ErrorCode
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIKeyboardUnregister	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set on error
		ax	<- Error code
DESTROYED:	nothing

SIDE EFFECTS:
		Shuts down hardware interface

PSEUDO CODE/STRATEGY:
		Call common shutdown routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardShutdown	proc	far
if HAS_KEYBOARD_HARDWARE
	uses	bx, dx, si
	.enter
	;
	;  Deactivate Keyboard interface
	mov	dx, mask IMF_KEYBOARD			; dx <- interface mask
	mov	bx, offset keyboardCallbackTable
	mov	si, offset HWKeyboardShutdown		; si <- actual HW rout.
	call	GDIShutdownInterface		; carry set on error
						; ax <- ErrorCode
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIKeyboardShutdown	endp

ShutdownCode		ends

CallbackCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardGetKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return any additional scancodes if available

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		bx	<- scancode
		cx	<- TRUE if press, FALSE if release
		ax	<- KeyboardErrorCodes
		carry set on errors

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardGetKey	proc	far
if HAS_KEYBOARD_HARDWARE
	uses	ds
	.enter
	;
	;  Make sure things are active
	MOV_SEG	ds, dgroup

	test	ds:[activeInterfaceMask], mask IMF_KEYBOARD	; are we on?
	mov	ax, EC_INTERFACE_NOT_INITIALIZED		; assume not
	stc
	jz	done	; => Not on

							; ds -> dgroup
	call	HWKeyboardGetKey		; ax <- error code
	cmp	ax, EC_NO_ERROR				; things go okay?
	je	done	; => carry cleared

	stc						; mark problem

done:
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIKeyboardGetKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardPassHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax	<- KeyboardErrorCodes
		carry set if error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardPassHotkey	proc	far 
if HAS_KEYBOARD_HARDWARE
		uses	ds
		.enter
		
	MOV_SEG	ds, dgroup
							; ds -> dgroup
	call	HWKeyboardPassHotkey
	cmp	ax, EC_NO_ERROR				; things go okay?
	je	done	; => carry cleared

	stc						; mark problem

done:
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
		
GDIKeyboardPassHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardCancelHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax	<- KeyboardErrorCode
		carry set if error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardCancelHotkey	proc	far 
if HAS_KEYBOARD_HARDWARE
	uses	ds
	.enter

	MOV_SEG	ds, dgroup
							; ds -> dgroup
	call	HWKeyboardCancelHotkey
	cmp	ax, EC_NO_ERROR				; things go okay?
	je	done					; => carry cleared

	stc						; mark problem

done:
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
		
GDIKeyboardCancelHotkey endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardAddHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	Global
PASS:		ah	-> ShiftState
		cx	-> character (ch = CharacterSet, cl =
				Chars/VChars)
		^lbx:si -> object to notify when the key is pressed
		bp	-> message to send it
RETURN:		ax	<- KeyboardErrorCodes
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardAddHotkey	proc	far 
if HAS_KEYBOARD_HARDWARE
	uses	ds
		.enter

	MOV_SEG	ds, dgroup
							; ds -> dgroup
	call	HWKeyboardAddHotkey
	cmp	ax, EC_NO_ERROR				; things go okay?
	je	done	; => carry cleared

	stc						; mark problem

done:
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
		
GDIKeyboardAddHotkey endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardDelHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	Global
PASS:		ah	-> ShiftState
		cx	-> character (ch = CharacterSet, cl =
			Chars/VChars)
RETURN:		ax	<- KeyboardErrorCodes
		clear set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardDelHotkey	proc	far
if HAS_KEYBOARD_HARDWARE
	uses	ds
	.enter
	MOV_SEG	ds, dgroup
							; ds -> dgroup
	call	HWKeyboardDelHotkey
	cmp	ax, EC_NO_ERROR				; things go okay?
	je	done	; => carry cleared

	stc						; mark problem

done:
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIKeyboardDelHotkey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIKeyboardCheckHotkey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		al	-> ShiftState
		bx	-> scancode
RETURN:		ax	<- KeyboardErrorCode
		carry set if key processed
		carry clear if key not processed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	7/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIKeyboardCheckHotkey	proc	far 
if HAS_KEYBOARD_HARDWARE 
	uses	bx, cx, dx, ds, es, si, di
	.enter
						
	call	HWKeyboardCheckHotkey			; bx, ds, es,
							; dx, cx, di,
							; si destroyed
	cmp	ax, EC_NO_ERROR				; things go okay?
	je	done	; => carry cleared

	stc						; mark problem

done:
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
		
GDIKeyboardCheckHotkey endp

		
CallbackCode		ends




 







