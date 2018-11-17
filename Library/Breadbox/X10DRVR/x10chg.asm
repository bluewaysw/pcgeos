COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Breadbox Computer 1995 -- All Rights Reserved

PROJECT:	Breadbox Home Automation
MODULE:	X-10 Power Code Driver
FILE:		x10chg.asm

AUTHOR:		David Hunter
	
DESCRIPTION:
	This file contains the routines to handle searching for the proper
	interface when changing the serial port.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		X10ChangePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the port on which the X-10 interface is attached.

CALLED BY:	Strategy Routine

PASS:		cx = new port to use: 0 = none, 1 = COM1, 2 = COM2, .., 4 = COM4.
RETURN:		dx = zero if no error, 1 if no controller found on new port,
				 2 if unable to reopen old port
DESTROYED:	nothing
SIDE EFFECTS:
		Finds controller on new port.
		Modifies .INI file if initialization successful.

PSEUDO CODE/STRATEGY:
		Create and display the "Searching for interface" dialog.
		Close old port.
		Call the test routines for each type of interface, updating the dialog.
		When we find one that works, use it; otherwise, restore the old port.
		Store new port data if successful via WriteIniFileSettings
		Close the dialog.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
X10ChangePort		proc	far
	uses ax,bx,si,di
	errorRet local word

	.enter
	clr ss:[errorRet]					; assume no error yet
	clr si								; no dialog either

	cmp	cx, 4							; only allow COM1 to COM4
	ja	error

	call X10Close						; close old port

	mov ds:[X10Port], cx				; store it in memory
	tst	cx								; is new port = none?
	jz	write							; yep, we're done

	; Create the dialog and bring it onscreen.
	mov	bx, handle DialogResource
	mov	si, offset ChangePortDialog
	call UserCreateDialog
	tst si
	jz	error
	push bp
	mov di, mask MF_CALL
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call ObjMessage
	pop bp

	; Test for TW523 interface
	mov ax, offset DirectText
	call ShowTesting
	mov ds:[X10Settings], SETTINGS_DIRECT
	call  	X10TestPort ; test port to see if there's a controller there
	jnc		write						; controller found
	
	; Test for HD11 interface
	mov	ax, offset SerialHD11Text
	call ShowTesting
	mov ds:[X10Settings], SETTINGS_SERIAL_CM11
	call	X10SerialInit				; test serial interface for response
	jnc		write						; controller found

	; Nothing worked, re-init the old port.
	inc ss:[errorRet]					; return an error
	call X10Init						; re-init old port
	jnc	done							; if re-init fails, big trouble.
error:
	inc	ss:[errorRet]					; return an error
	
	; Dismiss and destroy the dialog.
done:
	tst si
	jz	reallyDone
	call UserDestroyDialog
reallyDone:
	mov	dx, ss:[errorRet]				; load the error return value
	.leave
;	clr   dx                            ; never return error on change port.
	ret

write:
	tst si
	jz	skip
	call ShowFound
skip:
	call WriteIniFileSettings			; write the change
	jmp	done
X10ChangePort		endp

; Change the moniker of the testing interface glyph to the moniker passed in ax
ShowTesting	proc
	uses ax,cx,dx,si,di,bp
	.enter
	mov dx, ax
	mov cx, bx
	mov si, offset TestingInterfaceGlyph
	mov bp, VUM_NOW
	mov	es, bx
	mov di, mask MF_CALL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call ObjMessage
	.leave
	ret
ShowTesting	endp

; Change the moniker of the testing status glyph to the FoundText moniker.
ShowFound	proc
	uses ax,cx,dx,si,di,bp
	.enter
	mov cx, bx
	mov dx, offset FoundText
	mov si, offset TestingStatusGlyph
	mov bp, VUM_NOW
	mov di, mask MF_CALL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call ObjMessage
	; Insert a short one second delay so the user can actually SEE it.
	mov ax, 60
	call TimerSleep
	.leave
	ret
ShowFound	endp	


ResidentCode	ends
