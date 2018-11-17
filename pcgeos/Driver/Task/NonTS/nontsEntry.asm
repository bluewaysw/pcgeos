COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nontsEntry.asm

AUTHOR:		Adam de Boor, May  5, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 5/92		Initial revision


DESCRIPTION:
	Strategy routine etc.
		

	$Id: nontsEntry.asm,v 1.1 97/04/18 11:58:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment

DriverTable	TaskDriverInfoStruct	<
	<			; TDIS_common
	    <				; DEIS_common
		NTSStrategy,			; DIS_strategy
		mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
		DRIVER_TYPE_TASK_SWITCH		; DIS_driverType
	    >,
	    handle NTSDriverExtInfo	; DEIS_resource
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

DefTSFunction	NTSInit,			DR_INIT
DefTSFunction	NTSDoNothing,			DR_EXIT
DefTSFunction	NTSDoNothing,			DR_SUSPEND
DefTSFunction	NTSDoNothing,			DR_UNSUSPEND
DefTSFunction	NTSTestDevice,			DRE_TEST_DEVICE
DefTSFunction	NTSDoNothing,			DRE_SET_DEVICE
DefTSFunction	NTSDoNothing,			DR_TASK_BUILD_LIST
DefTSFunction	NTSUnsupported,			DR_TASK_SWITCH
DefTSFunction	NTSUnsupported,			DR_TASK_DELETE
DefTSFunction	NTSStartStub,			DR_TASK_START
DefTSFunction	NTSAppsShutdownStub,		DR_TASK_APPS_SHUTDOWN
DefTSFunction	NTSShutdownCompleteStub,	DR_TASK_SHUTDOWN_COMPLETE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSStrategy
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
NTSStrategy	proc	far
		.enter
EC <		cmp	di, TaskFunction				>
EC <		ERROR_AE	INVALID_TASK_FUNCTION			>
EC <		test	di, 1						>
EC <		ERROR_NZ	INVALID_TASK_FUNCTION			>
   		call	cs:[tsFunctions][di]
		.leave
		ret
NTSStrategy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSInit
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
NTSInit		proc	near
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
NTSInit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSDoNothing
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
NTSDoNothing	proc	near
		.enter
		clc
		.leave
		ret
NTSDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
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
NTSTestDevice	proc	near
		.enter
		clc
		mov	ax, DP_PRESENT
		.leave
		ret
NTSTestDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSUnsupported
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
NTSUnsupported	proc	near
		.enter
		stc
		.leave
		ret
NTSUnsupported	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSStartStub
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
NTSStartStub	proc	near
		.enter
		call	NTSStart
		.leave
		ret
NTSStartStub	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSAppsShutdownStub
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
NTSAppsShutdownStub proc near
		.enter
		call	NTSAppsShutdown
		.leave
		ret
NTSAppsShutdownStub endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTSShutdownCompleteStub
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
NTSShutdownCompleteStub proc near
		jcxz	aborted
		jmp	cs:[ntsShutdownCompleteVector]
aborted:
	;
	; If shutdown was aborted, we need to call that routine directly...
	; 
		call	NTSShutdownAborted
		ret
NTSShutdownCompleteStub endp

idata		ends
