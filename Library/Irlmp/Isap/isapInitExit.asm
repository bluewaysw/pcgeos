COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		isapInitExit.asm

AUTHOR:		Chung Liu, Mar 17, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95   	Initial revision


DESCRIPTION:
	Routines to load/unload Irlap driver.

	$Id: isapInitExit.asm,v 1.1 97/04/05 01:07:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsapCode	segment resource

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapUseIrlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment irlap reference count.  If nobody else is using
		the Irlap driver, then load and initialize it.

CALLED BY:	(EXTERNAL) IrlmpRegister
PASS:		nothing
RETURN:		carry clear if okay:
			ax destroyed
		carry set if could not load IrLAP Driver:
			ax	= IE_UNABLE_TO_LOAD_IRLAP_DRIVER
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapUseIrlap	proc	far
	uses	es
	.enter
	call	UtilsLoadDGroupES
	tst	es:[isapUseCount]
	jnz	incCount

	call	IIEInitIrlap
	jc	exit

incCount:
	inc	es:[isapUseCount]
exit:
	.leave
	ret
IsapUseIrlap	endp
endif

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapFreeIrlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the Irlap reference count.  If nobody is using
		the Irlap Driver, then free it.

CALLED BY:	(EXTERNAL) IrlmpUnregister
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapFreeIrlap	proc	far
	uses	es,ax
	.enter
	call	UtilsLoadDGroupES
EC <	tst	es:[isapUseCount]				>
EC <	ERROR_Z IRLMP_IRLAP_USE_COUNT_UNDERFLOW			>

	dec	es:[isapUseCount]
	jnz	exit

	call	IIEExitIrlap
exit:
	.leave
	ret
IsapFreeIrlap	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapInitIrlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load and initialize the Irlap Driver.

CALLED BY:	(EXTERNAL) IAFInitialize
PASS:		nothing
RETURN:		carry clear if okay:
			ax destroyed
		carry set if couldn't load Irlap Driver:
			ax	= IE_UNABLE_TO_LOAD_IRLAP_DRIVER
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapInitIrlap	proc	far
deviceInfo	local	DiscoveryInfo
	uses	bx,cx,dx,ds,si,es,di
	.enter
	;	
	; load the driver
	;
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	segmov	ds, cs
	mov	si, offset cs:[irlapDriverName]
	mov	ax, IRLAP_PROTO_MAJOR
	mov	bx, IRLAP_PROTO_MINOR
	call	GeodeUseDriver			;bx = handle of IrLAP Driver
	call	FilePopDir			;flags preserved
	jc	error
	call	UtilsLoadDGroupES
	clr	es:[isapClientHandle]
	mov	es:[isapDriverHandle], bx
	;
	; get the strategy
	;
	call	GeodeInfoDriver			;ds:si = DriverInfoStruct
	movdw	es:[isapStrategy], ds:[si].DIS_strategy, ax
	;
	; Register with the driver
	;
	mov	ax, IRLAP_DEFAULT_PORT
	mov	cx, vseg IsapNativeIrlapCallback
	mov	dx, offset IsapNativeIrlapCallback
	;
	; Pass device info to IrLAP.
	;
	segmov	ds, ss
	lea	si, ss:[deviceInfo]
	call	IsapGetDeviceInfo			;ds:si filled in.

	mov	di, NIR_REGISTER_NATIVE_CLIENT
	call	es:[isapStrategy]
	jc	freeAndExit
	mov	es:[isapClientHandle], bx

exit:
	.leave
	ret

freeAndExit:
	clr	bx
	xchg	bx, es:[isapDriverHandle]
	call	GeodeFreeDriver
	stc
error:
	mov	ax, IE_UNABLE_TO_LOAD_IRLAP_DRIVER
	jmp	exit
IsapInitIrlap	endp

NEC <irlapDriverName	TCHAR "Socket\\\\IRLAP Driver", 0		>
EC <irlapDriverName	TCHAR "Socket\\\\EC IRLAP Driver", 0		>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapGetDeviceInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the device info from the initfile, or if that does not
		exist, then use the default device info.

CALLED BY:	IsapInitIrlap
PASS:		ds:si	= DiscoveryInfo buffer
RETURN:		ds:si	= filled in with device info.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
defaultDeviceInfo	word	0x0F
			char	"Geoworks GEOS", 0, "                 "
irlmpCategory		char	"irlmp", 0
deviceInfoKey		char	"deviceInfo", 0

IsapGetDeviceInfo	proc	near
	uses	bp,es,di,ds,si,cx,dx,bx,ax
	.enter
	mov	bp, size DiscoveryInfo		;size of buffer
	movdw	esdi, dssi			;es:di = buffer
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[irlmpCategory]	;ds:si = "irlmp"
	mov	dx, offset cs:[deviceInfoKey]	;cx:dx = "deviceinfo"
	call	InitFileReadData		;es:di filled in
						;bx destroyed
	jc	useDefault

exit:
	.leave
	ret

useDefault:
	;
	; es:di = buffer passed in.
	; ds = cs
	;
	mov	si, offset cs:[defaultDeviceInfo] ;ds:si = default string
	mov	cx, size DiscoveryInfo
	rep	movsb				;copy default into buffer
	jmp	exit
IsapGetDeviceInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapExitIrlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload Irlap Driver

CALLED BY:	(EXTERNAL) IAFExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapExitIrlap	proc	far
	uses	es,di,bx
	.enter
	call	UtilsLoadDGroupES
	;
	; Unregister with the driver
	;
	clr	bx
	xchg	bx, es:[isapClientHandle]
	tst	bx
	jz	freeDriver

	pushdw	es:[isapStrategy]
	mov	di, NIR_UNREGISTER
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; Free the driver
	;
freeDriver:
	clr	bx
	xchg	bx, es:[isapDriverHandle]
	tst	bx
	jz	done
	call	GeodeFreeDriver
done:
	.leave
	ret
IsapExitIrlap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapCheckIrlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if Irlap driver is loaded and initialized.

CALLED BY:	(EXTERNAL) IrlmpRegister
PASS:		nothing
RETURN:		carry clear if Irlap Driver is loaded and initialized:
			ax	= IE_SUCCESS
		carry set otherwise:
			ax	= IE_UNABLE_TO_LOAD_IRLAP_DRIVER
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapCheckIrlap	proc	far
	uses	es
	.enter
	call	UtilsLoadDGroupES
	tst	es:[isapClientHandle]
	jz	error

	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret
error:
	mov	ax, IE_UNABLE_TO_LOAD_IRLAP_DRIVER
	stc
	jmp	exit
IsapCheckIrlap	endp


IsapCode	ends
