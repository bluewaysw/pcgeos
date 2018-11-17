COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdiPower.asm

AUTHOR:		Todd Stumpf, Apr 29, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96   	Initial revision


DESCRIPTION:
	
		

	$Id: gdiPower.asm,v 1.1 97/04/04 18:03:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


InitCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize Power module of GDI library

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set on error
		ax	<-	PowerManagementErrorCode
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
GDIPowerInit	proc	far
if HAS_POWER_HARDWARE
	uses	dx, si
	.enter

	;
	;  Activate Power interface
	.assert	segment HWPowerInit eq segment GDIPowerInit
	mov	dx, mask IMF_POWER			; dx <- interface mask
	mov	si, offset HWPowerInit		; si <- actual HW rout.
	call	GDIInitInterface		; carry set on error
						; ax <- ErrorCode

	.leave
else
	;
	;  Let caller know, no power is present
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc

endif
	ret
GDIPowerInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	*** This can be tossed ***

SYNOPSIS:	Return necessary power info

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax	<- PowerManagementErrorCode
		carry set on error (si, dx preserved)
DESTROYED:	flags only

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Currently a NOP

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPowerInfo	proc	far
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc

	ret
GDIPowerInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a Power callback with the library

CALLED BY:	GLOBAL
PASS:		dx:si	-> fptr of fixed routine to call
RETURN:		carry set on error
		ax	<- PowerManagementErrorCode
DESTROYED:	flags only

SIDE EFFECTS:
		Adds callback to list of power callbacks

PSEUDO CODE/STRATEGY:
		Call common registration routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPowerRegister	proc	far
if HAS_POWER_HARDWARE
	uses	bx,ds
	.enter

	;
	;  Try to add callback to list of Power callbacks
							; dx:si -> callback

	; since in GDI, registering the callback routine implies
	; the driver has just "unsuspended", we need to execute
	; some hardware specific code here to ensure everything is ok.
	mov	bx, segment dgroup
	mov	ds, bx
	call	HWPowerRegisterCode

	mov	bx, offset powerCallbackTable	; bx -> callback table
	call	GDIRegisterCallback		; carry set on error
						; ax <- ErrorCode
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPowerRegister	endp

InitCode			ends



ShutdownCode			segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove previously registered callback

CALLED BY:	GLOBAL
PASS:		dx:si	-> fptr for callback
RETURN:		carry set on error
		ax	<- PowerManagementErrorCode
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
GDIPowerUnregister	proc	far
if HAS_POWER_HARDWARE
	uses	bx
	.enter
	;
	;  Try to add callback to list of Power callbacks
							; dx:si -> callback
	mov	bx, offset powerCallbackTable	; bx -> callback table
	call	GDIUnregisterCallback		; carry set on error
						; ax <- ErrorCode
	.leave
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPowerUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerShutdown
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
GDIPowerShutdown	proc	far
if HAS_POWER_HARDWARE

	;
	;  Deactivate Power interface
	mov	dx, mask IMF_POWER			; dx <- interface mask
	mov	bx, offset powerCallbackTable
	mov	si, offset HWPowerShutdown		; si <- actual HW rout.
	call	GDIShutdownInterface		; carry set on error
						; ax <- ErrorCode

else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPowerShutdown	endp

ShutdownCode		ends



PowerCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerGet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the state of a specified device

CALLED BY:	GLOBAL

PASS:		bx	-> PowerDeviceType
		si	-> deviceNum
		cx	-> TRUE if block, FALSE if can't

RETURN:		dx	<- power level of device
		ax	<- PowerManagementErrorCode
		carry set on error (dx preserved)

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPowerGet	proc	far
	uses	ds
	.enter
if HAS_POWER_HARDWARE
	mov	ax, segment dgroup
	mov	ds, ax

	cmp	bx,-1; PDT_MAIN_BATTERY
	je	battery
	cmp	bx, -1;PDT_BACKUP_BATTERY
	je	battery
	cmp	bx, -1;PDT_AC_ADAPTER
	je	ac_adapter

	mov	dx, 255
	mov	ax, EC_NO_ERROR
	clc
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif

done:
	.leave
	ret

battery:
	call	HWPowerGetBatteryLevel
	jmp	done

ac_adapter:
	; hard code it for now
	mov	dx, PS_OFF
	jmp	done

GDIPowerGet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDIPowerSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the power level for a device

CALLED BY:	GLOBAL

PASS:		bx	-> PowerDeviceType
		si	-> deviceNum (see note below)
		cx	-> TRUE if can block, FALSE if can't
		ax	-> Power level for device
RETURN:		ax	<- PowerManagementErrorCode
		carry set on error

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		In the case of a GDIPowerSet of PS_SUSPEND on PDT_CPU,
		si will contain a PowerSuspendReason instead. This indicates
		to the GDI library the reason the suspend is necessary.
		Depending on the power management scheme, the GDI library
		will want to treat each situation differently.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDIPowerSet	proc	far

if HAS_POWER_HARDWARE
;	cmp	bx, PDT_CPU
;	jne	display
;	call	HWCPUPowerSet
;	jmp	done
display:
	cmp	bx, PDT_DISPLAY
	jne	done
	call	HWDISPLAYPowerSet
done:
	mov	ax, EC_NO_ERROR
	clc
else
	mov	ax, EC_INTERFACE_NOT_SUPPORTED
	stc
endif
	ret
GDIPowerSet	endp



PowerCode		ends


