COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dos5Entry.asm

AUTHOR:		Adam de Boor, May 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/30/92		Initial revision


DESCRIPTION:
	Strategy routine etc.
		

	$Id: dos5Entry.asm,v 1.1 97/04/18 11:58:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment

DriverTable	TaskDriverInfoStruct	<
	<			; TDIS_common
	    <				; DEIS_common
		DOS5Strategy,			; DIS_strategy
		mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
		DRIVER_TYPE_TASK_SWITCH		; DIS_driverType
	    >,
	    handle DOS5DriverExtInfo	; DEIS_resource
	>,
	0			; TDIS_flags
>
public	DriverTable

tsFunctions	label	nptr.near

DefTSFunction	macro	routine, constant
.assert ($-tsFunctions) eq constant, <Routine for constant in the wrong slot>
.assert (type routine eq near)
		nptr	routine
		endm

DefTSFunction	DOS5Init,			DR_INIT
DefTSFunction	DOS5DoNothing,			DR_EXIT
DefTSFunction	DOS5DoNothing,			DR_SUSPEND
DefTSFunction	DOS5DoNothing,			DR_UNSUSPEND
DefTSFunction	DOS5TestDevice,			DRE_TEST_DEVICE
DefTSFunction	DOS5DoNothing,			DRE_SET_DEVICE
DefTSFunction	DOS5DoNothing,			DR_TASK_BUILD_LIST
DefTSFunction	DOS5Unsupported,		DR_TASK_SWITCH
DefTSFunction	DOS5Unsupported,		DR_TASK_DELETE
DefTSFunction	DOS5StartStub,			DR_TASK_START
DefTSFunction	DOS5AppsShutdownStub,		DR_TASK_APPS_SHUTDOWN
DefTSFunction	DOS5ShutdownCompleteStub,	DR_TASK_SHUTDOWN_COMPLETE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5Strategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a call to this driver.

CALLED BY:	GLOBAL
PASS:		di	= TaskFunction to perform
RETURN:		?
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5Strategy	proc	far
		.enter
EC <		cmp	di, TaskFunction				>
EC <		ERROR_AE	INVALID_TASK_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_TASK_FUNCTION			>
   		call	cs:[tsFunctions][di]
		.leave
		ret
DOS5Strategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver.

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry clear if ok
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5Init	proc	near
		uses	bx
		.enter
	;
	; Reference ourselves so we're sure never to exit and have our blocks
	; freed.
	; 
		mov	bx, handle 0
		call	GeodeAddReference
		.leave
		ret
DOS5Init	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5DoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just what the name implies.

CALLED BY:	DR_EXIT, DR_TASK_BUILD_LIST, DRE_SET_DEVICE
PASS:		?
RETURN:		carry clear
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5DoNothing	proc	near
		.enter
		clc
		.leave
		ret
DOS5DoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5TestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the device is around

CALLED BY:	DRE_TEST_DEVICE
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5TestDevice	proc	near
		.enter
	;
	; See if DOS version is >= 3.0, where int 2f was first defined.
	;
		mov	ax, MSDOS_GET_VERSION shl 8
		call	FileInt21
		cmp	al, 3
		jb	done
	;
	; Yup. See if a switcher's in evidence.
	;
		clr	bx
		mov	di, bx
		mov	es, bx
		mov	ax, MSS2F_DETECT_SWITCHER
		int	2fh
		
		mov	ax, es
		or	ax, di
		jz	absent	; null call-in address, so no t/s

		mov	ax, DP_PRESENT
done:
		clc
		.leave
		ret
absent:
	;
	; Tell our application object to make our process exit, since otherwise
	; we won't go away.
	; 
		push	ax, bx, cx, dx, bp, si
		mov	ax, MSG_META_QUIT
		mov	bx, handle TaskApp
		mov	si, offset TaskApp
		clr	cx, dx, bp
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax, bx, cx, dx, bp, si
		
		mov	ax, DP_NOT_PRESENT
		jmp	done
DOS5TestDevice	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5Unsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an unsupported function, returning an appropriate
		error.

CALLED BY:	DR_TASK_SWITCH, DR_TASK_DELETE
PASS:		nothing
RETURN:		carry set
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5Unsupported	proc	near
		.enter
		stc
		.leave
		ret
DOS5Unsupported	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5StartStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call NTSStart

CALLED BY:	DR_TASK_START
PASS:		ds	= DosExecArgs block
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5StartStub	proc	near
		.enter
		call	NTSStart
		.leave
		ret
DOS5StartStub	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5AppsShutdownStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call NTSAppsShutdown

CALLED BY:	DR_TASK_APPS_SHUTDOWN
PASS:		nothing
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5AppsShutdownStub proc near
		.enter
		call	NTSAppsShutdown
		.leave
		ret
DOS5AppsShutdownStub endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOS5ShutdownCompleteStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call NTSShutdownComplete

CALLED BY:	DR_TASK_SHUTDOWN_COMPLETE
PASS:		cx	= non-zero if switch has been confirmed by all active
			  applications. zero if some active application has
			  refused permission to switch (thereby aborting the
			  DR_TASK_SWITCH/DR_TASK_START in-progress)
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOS5ShutdownCompleteStub proc near
		jcxz	aborted
		jmp	cs:[ntsShutdownCompleteVector]
aborted:
	;
	; If shutdown was aborted, we need to call that routine directly...
	; 
		call	NTSShutdownAborted
		ret
DOS5ShutdownCompleteStub endp

idata		ends
