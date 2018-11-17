COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Power Driver Module
FILE:		apmEsc.asm

AUTHOR:		Todd Stumpf, Jan 20, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/20/95   	Initial revision


DESCRIPTION:
	
		

	$Id: apmEsc.asm,v 1.1 97/04/18 11:48:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMEscCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an exetended (Escape) command

CALLED BY:	APMStrategy

PASS:		si	-> command
		ds, es	-> dgroup
		<others>-> as per command

RETURN:		carry set if not supported
		<others> <- as per command

DESTROYED:	nothing

SIDE EFFECTS:
		Depends upon command

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMEscCommand	proc	near
	.enter

	cmp	si, size escCommandTable		; off table?
	ja	unsupported	; => off table

	test	si, 1					; odd value?
	clc						; doesn't affect jump
	jnz	unsupported	; => odd offset

	cmp	cs:escCommandTable[si], -1
	clc
	je	unsupported				;branch if unsupported
	call	cs:escCommandTable[si]
	stc						; signal support

unsupported:
	cmc
	.leave
	ret

escCommandTable		nptr	APMCheckPassword,
				APMSetPassword,
				APMDisablePassword,
				APMPasswordOK,
				APMRTCAck,
				APMOnOffPress,
				APMInstallRemovePasswordMonitor,
				-1,		;reload preferences
				-1,		;video mode change
				-1,		;button notif register
				-1,		;button notif unregister
				APMGetVersion,
				APMForceSuspend

CheckHack <2*(length escCommandTable) le PowerEscCommand>

APMEscCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMOnOffPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an on-off press

CALLED BY:	APMEscCommand

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Marks us for death...  Well, sleep, anyway.  :)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	1/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMOnOffPress	proc	near
	.enter

if	HAS_COMPLEX_ON_OFF_BUTTON
	push	ds

	segmov	ds, dgroup
	ornf	ds:[miscState], mask MS_ON_OFF_PRESS

	pop	ds	
endif

	.leave
	ret
APMOnOffPress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMGetVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the APM version

CALLED BY:	APMEscCommand

PASS:		ds - dgroup

RETURN:		ah - proto major
		al - proto miscState

DESTROYED:	nothing

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	02/04/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

APMGetVersion	proc	near
		.enter

		mov	ax, ds:protoMajorMinor

		.leave
		ret
APMGetVersion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APMForceSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forcefully suspends the machine

CALLED BY:	APMEscCommand
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/03/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APMForceSuspend	proc	near
	uses	bp
	.enter

	BitSet	ds:[powerDownOnIdle], AOIS_SUSPEND
		CheckHack <ISRT_SUSPEND eq 0>
	clr	bp			; bp = ISRT_SUSPEND
	call	APMSendSuspendResumeGCN
	call	InitFileCommit

	.leave
	ret
APMForceSuspend	endp

Resident		ends






