COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		Power Drivers
FILE:		apmPassword.asm

AUTHOR:		Todd Stumpf, Jul 28, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/28/94   	Initial revision


DESCRIPTION:
	This file contains the code needed to display a GEOS-level
	password screen.

	Usually this screen would be displayed upon returning from a
	suspend...

	$Id: apmPassword.asm,v 1.1 97/04/18 11:48:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



idata segment

passwordMonitor	Monitor <>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPasswordMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure keystrokes we don't want to go through, don't.

CALLED BY:	IM (Input Manager)

PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
		METHOD_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data

RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event

DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)
		
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/91		Initial version
	stevey	1/7/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMPasswordMonitor	proc	far
	.enter

	test	al, mask MF_DATA
	jz	done
	cmp	di, MSG_META_KBD_CHAR
	jne	done
	
if	DBCS_PCGEOS

	;
	; These are a few of my (least) favorite things...
	;

	cmp	cx, C_SYS_F2
	je	swallow
	cmp	cx, C_SYS_F3
	je	swallow
	cmp	cx, C_SYS_ESCAPE
	je	swallow
	cmp	cx, C_SYS_SYSTEM_RESET
	je	swallow

else

	cmp	ch, CS_CONTROL		; anything but control chars we 
	jne	done			;  let through unconditionally.
	
	;
	; These are a few of my (least) favorite things...
	;

	cmp	cl, VC_F2
	je	swallow
	cmp	cl, VC_F3
	je	swallow
	cmp	cl, VC_ESCAPE
	je	swallow
	cmp	cl, VC_SYSTEMRESET
	je	swallow

endif	; DBCS_PCGEOS

done:
	.leave
	ret

swallow:
	clr	al			; munch
	jmp	short	done

APMPasswordMonitor	endp

monitorInstalled	byte

idata	ends



Resident		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMInstallPasswordMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install a monitor to look for CTRL-ALT-DEL, etc.

CALLED BY:	APMPromptForPassword

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMInstallPasswordMonitorFar		proc far
	call	APMInstallPasswordMonitor
	ret
APMInstallPasswordMonitorFar		endp

APMInstallPasswordMonitor	proc near
		uses	ax,bx,cx,dx,ds
		.enter
	;
	; If a monitor's already installed, then bail
	;
		segmov	ds, dgroup, bx
		mov	al, TRUE
		xchg	al, ds:[monitorInstalled]
		tst	al
		jnz	done


	;
	; Install an input monitor to filter various nasties out
	;
		mov	bx, offset passwordMonitor
		mov	al, ML_DRIVER		; after the driver but before
						;  Welcome, heh
		mov	cx, segment APMPasswordMonitor
		mov	dx, offset APMPasswordMonitor
		call	ImAddMonitor
done:
		.leave
		ret
APMInstallPasswordMonitor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMRemovePasswordMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the password monitor, now that the user has
		entered a valid password

CALLED BY:	APMPasswordEntered

PASS:		nothing 
RETURN:		nothing 
DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMRemovePasswordMonitor	proc near
		uses	ax,bx,ds
		.enter

		segmov	ds, dgroup, ax
		clr	al
		xchg	ds:[monitorInstalled], al

		tst	al
		jz	done
	;
	; Remove the input monitor that filters unhealthy keystrokes
	; 
		mov	al, mask MF_REMOVE_IMMEDIATE
		mov	bx, offset passwordMonitor
		call	ImRemoveMonitor
done:
		.leave
		ret
APMRemovePasswordMonitor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMInstallRemovePasswordMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install or remove the password monitor.

CALLED BY:	APMEscCommand

PASS:		cx = nonzero to install, zero to remove

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMInstallRemovePasswordMonitor	proc	near

		jcxz	remove
		call	APMInstallPasswordMonitor
		jmp	done
remove:
		call	APMRemovePasswordMonitor
done:
		ret
APMInstallRemovePasswordMonitor	endp


;-----------------------------------------------------------------------------
;		Password Checking Code
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMSetPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the password (in BIOS, if supported)

CALLED BY:	APMStrategy

PASS:		cx:dx	-> password (size BIOS_PASSWORD_SIZE) (zero padded)

RETURN:		carry set if not supported

DESTROYED:	di

SIDE EFFECTS:
		Sets password in BIOS (if password exists)

PSEUDO CODE/STRATEGY:
		For Default Password Code:
			Bail.  Let UI use .INI file		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	USE_DEFAULT_PASSWORD_CODE
APMSetPassword	proc	near
	.enter
	stc
	.leave
	ret
APMSetPassword	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPromptForPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display password dialog box, if appropriate

CALLED BY:	INTERNAL

PASS:		ds	-> dgroup
		bl	- APMExtNMIStatusRegister

RETURN:		nothing

DESTROYED:	cx, dx

SIDE EFFECTS:
		Queues message for UI's thread.

PSEUDO CODE/STRATEGY:
		See if wakeup was caused by RTC or modem ring resume.
			If so, no password screen.

		Get UI's process thread
		queue message for thread

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMPromptForPassword	proc	near
	uses	ax, bx, di
	.enter

	; Get the UI's process handle, and send message
	;
	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo		; UI handle => AX

	tst	ax
	jz	done
		
	;
	; Now send the message.
	;

	mov_tr	bx, ax			; UI handle	
	mov	ax, MSG_USER_PROMPT_FOR_PASSWORD
	clr	di
	call	ObjMessage

done:
	.leave
	ret

APMPromptForPassword	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMCheckPassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the passwords matches

CALLED BY:	APMStrategy
PASS:		cx:dx	-> password to verify (zero padded)
			- or -
		cx=dx=0 -> check if password exists

RETURN:		carry set if not supported

		- or -

		carry clear
		ax non-zero if passwords don't match

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For Default Password Code:
			Bail.  Let UI use .INI file				

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	USE_DEFAULT_PASSWORD_CODE
APMCheckPassword	proc	near
	.enter
	stc
	.leave
	ret
APMCheckPassword	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMPasswordOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the reboot button, now that the user has
		entered a valid password

CALLED BY:	APMStrategy, DR_POWER_PASSWORD_OK

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMPasswordOK	proc near
		call	APMRemovePasswordMonitor
		call	APMEnableReboot
		ret
APMPasswordOK	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMDisablePassword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable the existing password

CALLED BY:	APMStrategy

PASS:		cx:dx	-> old password to disable (zero padded)

RETURN:		carry set if not supported
			- or -
		ax	<- PasswordDisableResult

DESTROYED:	nothing

SIDE EFFECTS:
		Disables password in BIOS

PSEUDO CODE/STRATEGY:
		For Default Password Code:
			Bail.  Let UI use .INI file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/ 3/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	USE_DEFAULT_PASSWORD_CODE
APMDisablePassword	proc	near
	.enter
	stc
	.leave
	ret
APMDisablePassword	endp
endif


Resident		ends


