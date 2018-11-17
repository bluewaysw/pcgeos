COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Standalone Driver
FILE:		resident.asm


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0

DESCRIPTION:
	This file contains SOME of the resident code for this driver.
	See other .asm files for more.


RCS STAMP:
	$Id: standaloneResident.asm,v 1.1 97/04/18 11:48:50 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			StandaloneResidentCode
;------------------------------------------------------------------------------

StandaloneResidentCode	segment	resource	;start of code resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	StandaloneStrategy

DESCRIPTION:	This is the main strategy routine for this driver.

CALLED BY:	Net Library, applications...

PASS:		di	= NetDriverFunctions enum

RETURN:		carry set if error

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

StandaloneStrategy	proc	far

	;check the function code

	cmp	di, NetDriverFunction
	jae	badCall

	;call the function:

	call	cs:[NetDriverProcs][di]
	ret

badCall: ;Error: function code is illegal.

EC <	ERROR	INVALID_DRIVER_FUNCTION			>

NEC <	stc								>
NEC <	ret								>

StandaloneStrategy endp

NetDriverProcs	nptr.near	\
    StandaloneInit,	
    StandaloneExit,
    StandaloneSuspend,
    StandaloneUnsuspend,
    StandaloneUserFunction,	; DR_NET_USER_FUNCTION               
    Stub,			; DR_NET_INITIALIZE_HECB             
    Stub,			; DR_NET_SEND_HECB                   
    Stub,			; DR_NET_SEMAPHORE_FUNCTION          
    Stub,			; DR_NET_GET_DEFAULT_CONNECTION_ID   
    Stub,			; DR_NET_GET_SERVER_NAME_TABLE       
    Stub,			; DR_NET_GET_CONNECTION_ID_TABLE     
    Stub,			; DR_NET_SCAN_FOR_SERVER             
    Stub,			; DR_NET_SERVER_ATTACH               
    Stub,			; DR_NET_SERVER_LOGIN                
    Stub,			; DR_NET_SERVER_LOGOUT               
    Stub,			; DR_NET_SERVER_CHANGE_USER_PASSWORD 
    Stub,			; DR_NET_SERVER_VERIFY_USER_PASSWORD 
    Stub,			; DR_NET_SERVER_GET_NET_ADDR         
    Stub,			; DR_NET_SERVER_GET_WS_NET_ADDR      
    Stub,			; DR_NET_MAP_DRIVE                   
    Stub,			; DR_NET_MESSAGING                   
    Stub,			; DR_NET_PRINT_FUNCTION              
    Stub,			; DR_NET_OBJECT_FUNCTION             
    Stub,			; DR_NET_TEXT_MESSAGE_FUNCTION
    Stub,			; DR_NET_GET_VOLUME_NAME
    Stub,			; DR_NET_GET_DRIVE_CURRENT_PATH
    Stub,			; DR_NET_GET_STATION_ADDRESS
    Stub			; DR_NET_UNMAP_DRIVE

.assert	(size NetDriverProcs	eq NetDriverFunction)

Stub 	proc near
	ret
Stub	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StandaloneInit

DESCRIPTION:	

CALLED BY:	StandaloneStrategy

PASS:		
;	PASS:	cx	= di passed to GeodeLoad. Garbage if loaded via
;			  GeodeUseDriver
;		dx	= bp passed to GeodeLoad. Garbage if loaded via
;			  GeodeUseDriver
;	RETURN:	carry set if driver initialization failed. Driver will be
;			unloaded by the system.
;		carry clear if initialization successful.
;
;	DESTROYS:	bp, ds, es, ax, di, si, cx, dx

RETURN:		carry set if error

DESTROYED:	all regs

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

StandaloneInit	proc	near

	call	RegisterDriver	
	clc				;no error
	ret
StandaloneInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegisterDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register ourself to the net Library

CALLED BY:	StandaloneInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
standaloneDomainName	char 	"STANDALONE",0

RegisterDriver	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	segmov	ds, cs, si
	mov	si, offset standaloneDomainName
	mov	cx, cs
	mov	dx, offset StandaloneStrategy ; cx:dx - strategy routine
	mov	bx, handle 0	
	call	NetRegisterDomain
	.leave
	ret
RegisterDriver	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StandaloneExit

DESCRIPTION:	

CALLED BY:	StandaloneStrategy

;	PASS:	nothing
;	RETURN:	nothing
;	DESTROYS:	ax, bx, cx, dx, si, di, ds, es
;
;	NOTES:	If the driver has GA_SYSTEM set, the handler for this function
;		*must* be in fixed memory and may not use anything in movable
;		memory.

DESTROYED:	all regs.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

StandaloneExit	proc	near
	clc
	ret
StandaloneExit	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StandaloneSuspend

DESCRIPTION:	This routine is called by the Net Library, when a V1.2
		task switcher driver (TaskMax, B&F, DOS5) is preparing to
		switch.

IMPORTANT:	Due to the nature of the call to this routine, we must NOT:
		    - take too long
		    - attempt to grab any semaphores, or block for any reason
		    - call any routines which are not fixed.

		It is OK to:
		    - call FileGrabSystem for the DOS lock (because
		    TaskPrepareForSwitch has already grabbed the
		    DOS thread-lock, so our call will just be a nested
		    lock, which is ok.)

CALLED BY:	StandaloneStrategy

;	SYNOPSIS:	Prepare the device for going into stasis while PC/GEOS
;			is task-switched out. Typical actions include disabling
;			interrupts or returning to text-display mode.
;
;	PASS:	cx:dx	= buffer in which to place reason for refusal, if
;			  suspension refused (DRIVER_SUSPEND_ERROR_BUFFER_SIZE
;			  bytes long)
;	RETURN:	carry set if suspension refused:
;			cx:dx	= buffer filled with null-terminated reason,
;				  standard PC/GEOS character set.
;		carry clear if suspension approved
;	DESTROYS:	ax, di
;

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

StandaloneSuspend	proc	near

	clc
	ret
StandaloneSuspend	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StandaloneUnsuspend

DESCRIPTION:	

CALLED BY:	StandaloneStrategy

;	SYNOPSIS:	Reconnect to the device when PC/GEOS is task-switched
;			back in.
;
;	PASS:	nothing
;	RETURN:	nothing
;	DESTROYS:	ax, di
;

DESTROYED:	?

PSEUDO CODE/STRATEGY:
 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

StandaloneUnsuspend	proc	near

	clc
	ret
StandaloneUnsuspend	endp


StandaloneResidentCode	ends

