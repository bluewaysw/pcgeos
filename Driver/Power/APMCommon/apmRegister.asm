COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		PowerDrivers
FILE:		apmRegister.asm

AUTHOR:		Todd Stumpf, Aug  1, 1994

ROUTINES:
	Name				Description
	----				-----------
	APMRegisterPowerOnOffNotify	Register another callback routine
	APMCallPowerNotifyCallbacks	Call all registered routines
	APMOnOffUnregister		Remove a registered callback
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 1/94   	Initial revision


DESCRIPTION:
	
		

	$Id: apmRegister.asm,v 1.1 97/04/18 11:48:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMRegisterPowerOnOffNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	register a call back routine for power on power off

CALLED BY:	GLOBAL

PASS:		ds	-> dgroup	
		dx:cx = fptr to call back routine

RETURN:		carry set on error

DESTROYED:	Nothing

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:
		Call each routine.
				
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/19/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMRegisterPowerOnOffNotify	proc	near
	uses	ax
	.enter

	;
	;  Quickly verify we have room left for this
	;  notification...
	CheckHack <APM_MAX_CALL_BACKS lt 255>
	INT_OFF
	mov	al, ds:[numCallbackRoutines]	; al <- # currently registered

	cmp	al, APM_MAX_CALL_BACKS	; see if we are full
	ja	done	; => too many registered

	;
	;  Good.  Turn the index # into an offset into the
	;  callback table.
	cbw					; ax <- al
	shl	ax, 1				; ax <- al * 2
	shl	ax, 1				; ax <- al * 4

	xchg	ax, bx				; ax <- bx
						; bx <- offset

	movdw	ds:callbackTable[bx], dxcx	; store fptr for callback

	xchg	ax, bx				; ax <- offset
						; bx <- bx

	inc	ds:[numCallbackRoutines]	; mark space down as used
	stc
done:
	INT_ON
	cmc
	.leave
	ret
APMRegisterPowerOnOffNotify	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMCallPowerNotifyCallbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call call back routines to notify them of power on/off

CALLED BY:	APMPowerSwitchHandler

PASS:		ds	-> dgroup
		ax = 0 power off, 1 power on

RETURN:		nothing

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	
			
KNOWN BUGS/SIDEFFECTS/IDEAS:
		CALLBACK ROUTINES MUST BE IN FIXED MEMORY AND MUST
		PRESERVE ALL THE REGISTERS
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/19/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMCallPowerNotifyCallbacks	proc	near
	uses	bx, cx
	.enter
	clr	bx, cx				; bx <- 0
						; cx <- 0

	CheckHack <APM_MAX_CALL_BACKS lt 255>
	mov	cl, ds:[numCallbackRoutines]	; cx <- # of routines
	jcxz	done				; are we done?

callLoop:
	call	ds:callbackTable[bx]		; call 1st routine
	add	bx, size fptr			; access next fptr
	loop	callLoop

done:	
	.leave
	ret
APMCallPowerNotifyCallbacks	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMOnOffUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a previously registered callback

CALLED BY:	Strategy Routine

PASS:		dx:cx	-> fptr to remove

RETURN:		carry set if not found

DESTROYED:	nothing

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Find slow containing specified fptr
		Swap it with last slot, and remove last slot
		return

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMOnOffUnregister	proc	near
	uses	ax, cx, si
	.enter
	mov_tr	ax, cx				; dx:ax <- callback

	clr	cx, si
	CheckHack <APM_MAX_CALL_BACKS lt 255>

	INT_OFF
	mov	cl, ds:[numCallbackRoutines]	; cx <- current # of CB
	jcxz	error

findLoop:
	cmpdw	ds:callbackTable[si], dxax	; look for our callback
	je	foundIt
	add	si, size fptr			; examine next slot
	loop	findLoop

error:
	stc					; not found
done:
	INT_ON
	.leave
	ret

foundIt:
	;
	;  Save trashed registers
	push	bx, dx
	;
	;  Get pointer to last callback
	mov	al, ds:[numCallbackRoutines]	; ax <- offset into table
	dec	al				; make 0 index
	cbw
	shl	ax, 1				; (fptr's, 'member?)
	shl	ax, 1

	;
	;  Removing last one?
	cmp	ax, si				; last == one to delete?
	je	removeIt	; => yes, just biff it

	;
	;  Move last callback to open slot
	mov_tr	bx, ax				; bx <- ptr to last entry
	movdw	dxax, ds:callbackTable[bx]	; dxax <- last valid entry
	movdw	ds:callbackTable[si], dxax	; stick in valid slot

removeIt:
	dec	ds:[numCallbackRoutines]	; remove ref to last slot
	clc					; all is well...

	;
	;  restore trashed registers
	pop	bx, dx
	jmp	short done

APMOnOffUnregister	endp


Resident		ends
