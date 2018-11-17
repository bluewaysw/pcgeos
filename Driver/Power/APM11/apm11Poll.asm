COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs in Light, 2000 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		apm10Poll.asm

AUTHOR:		Gene Anderson

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00   	Initial revision


DESCRIPTION:
	
		

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatusACLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we are hooked up to AC power source

CALLED BY:	APMGetStatus

PASS:		ds - dgroup

RETURN:		ax - PowerStatus
		bx - PowerStatus supported

DESTROYED:	nothing

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/09/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

APMGetStatusACLine	proc	far
		uses	dx
		.enter

	;
	; call APM to get the status
	;
		mov	bx, APMDID_ALL_BIOS_DEVICES
		call	SysLockBIOS
		CallAPM	APMSC_GET_POWER_STATUS		;bh <- ACLineStatus
		call	SysUnlockBIOS
		jc	unsupported			;branch if error

		clr	ax, dx				;assume off, unsprt
	;
	; PS_AC_ADAPTER_CONNECTED
	;	
		cmp	bh, ACLS_UNKNOWN		;AC detect supported?
		je	doneAC				;branch if not
		cmp	bh, ACLS_ON_LINE		;AC connected?
		jne	gotACStatus			;branch if not
gotACOn::
		ornf	ax, mask PS_AC_ADAPTER_CONNECTED ;ax <- on
gotACStatus:
		ornf	dx, mask PS_AC_ADAPTER_CONNECTED ;dx <- supported
doneAC:

	;
	; PS_CHARGING
	;
		cmp	bl, BS_UNKNOWN			;charging supported?
		je	doneCharging			;branch if not
		cmp	bl, BS_CHARGING			;charging?
		jne	gotChargeStatus
gotChargeOn::
		ornf	ax, mask PS_CHARGING		;ax <- on
gotChargeStatus:
		ornf	dx, mask PS_CHARGING		;dx <- supported
doneCharging:

		clc
done:
		mov	bx, dx				;bx <- supported

		.leave
		ret

unsupported:
		clr	ax, dx				;dx <- none supported
		stc
		jmp	done
APMGetStatusACLine	endp

Resident ends

Movable	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatusBatteryMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the status of the main battery

CALLED BY:	APMGetStatusWarnings()
PASS:		none
RETURN:		carry - set if error / not supported
		dx:ax - 0-1000 (percent * 10)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMGetStatusBatteryMain		proc	far
		uses	bx,cx,si,di,bp
		.enter

		mov	bx, APMDID_ALL_BIOS_DEVICES

		call	SysLockBIOS
		CallAPM	APMSC_GET_POWER_STATUS
		call	SysUnlockBIOS
EC<		ERROR_C	-1				;ah <- error #	>
NEC <		jc	unsupported			;>

		;
		; return power percentage as percent * 10
		;
		cmp	cl, 0xff			;unsupported?
		je	unsupported			;branch if so

		clr	ch				;cx <- 0-100%
		mov	ax, 10
		mul	cx				;dx:ax <- 0-1000

		clc					;carry <- no error
done:
		.leave
		ret

unsupported:
		stc
		jmp	short done
APMGetStatusBatteryMain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetStatusBatteryLifeMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the status of the main battery

CALLED BY:	APMGetStatusWarnings()
PASS:		none
RETURN:		carry - set if error / not supported
		dx:ax - time in minutes
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/08/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMGetStatusBatteryLifeMain		proc	far
		uses	bx,cx,si,di,bp
		.enter

		mov	bx, APMDID_ALL_BIOS_DEVICES

		call	SysLockBIOS
		CallAPM	APMSC_GET_POWER_STATUS
		call	SysUnlockBIOS
EC<		ERROR_C	-1				;ah <- error #	>
NEC <		jc	unsupported			;>

	;
	; return the value in minutes
	;
		clr	ax
		xchg	ax, dx				;dx:ax <- minutes
		cmp	ax, BT_TIME_UNKNOWN		;unsupported?
		je	unsupported			;branch if so
		test	ax, mask BT_TIME_IN_MINUTES	;time in seconds?
		jz	timeInSec			;branch if so
	;
	; clear the flag and return the minutes
	;
		andnf	ax, mask BT_TIME		;dx:ax <- minutes

gotTime:
		clc					;carry <- no error
done:
		.leave
		ret

unsupported:
		stc
		jmp	done
	;
	; time was in seconds; convert to minutes
	;
timeInSec:
		mov	cx, 60
		div	cx				;dx:ax <- minutes
		jmp	gotTime
APMGetStatusBatteryLifeMain	endp

Movable	ends
