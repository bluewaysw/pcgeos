COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdiExt.asm

AUTHOR:		Todd Stumpf, Apr 10, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/10/96   	Initial revision


DESCRIPTION:
	
		

	$Id: gdiExt.asm,v 1.1 97/04/04 18:03:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonitorCode			segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDISMMonitorSystem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the monitoring inside the GDI Library for
		events. Client is informed of an event by registering a
		callback function.
		

CALLED BY:	GLOBAL
PASS:		dx:si	-> callback
RETURN:		carry set on error
		ax	<- ErrorCode
		si	<- registerID (ffffh if error)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDISMMonitorSystem	proc	far
		.enter
	;
	;	First register the callback to all hardware: keyboard, mouse
	;	and power for now.
	;
		mov	bx, offset systemMonitorCallbackTable
		call	GDIRegisterCallback
						; bx <- slot index in
						; systemMonitorCallbackTable,

		inc	bx		
		mov	si, bx			; registration ID for
						; systemMonitor has 1-based index.
						; 0 is reserved for hardware
		.leave
		ret
GDISMMonitorSystem	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDISMGenerateState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To generate fake events.

CALLED BY:	GLOBAL
PASS:		si	-> registerID
		di	-> SystemEventType
		others	-> as SystemEventType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDISMGenerateState	proc	far
		uses	bp
		.enter

	;
	;	see which SystemEventType and call which table
	;

		cmp	di, SET_KEYBOARD
		jne	tryPointer

		mov	di, offset keyboardCallbackTable
		jmp	filter

tryPointer:
		cmp	di, SET_POINTER
		jne	tryPower

		mov	di, offset pointerCallbackTable
		jmp	filter

tryPower:
		cmp	di, SET_POWER
		jne	done				; do nothing
	;EC <		ERROR_NE EC_WRONG_EVENT_TYPE
		mov	di, offset powerCallbackTable
filter:
		mov	bp, offset GDINoCallback
		call	GDIFilterEventsFar
done:
		.leave
		ret
GDISMGenerateState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDISMRemoveMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the callback event by a client geode and thus stop
		the reporting of events to the client geode.

CALLED BY:	GLOBAL
PASS:		si	-> registerID
RETURN:		carry set if error
		ax	<- ErrorCode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDISMRemoveMonitor	proc	far

		uses	bx, ds
		.enter

	;
	;	We are not using the general Unregister routine here, 'coz
	;	now we now know which slot to remove.
	;
		MOV_SEG	ds, dgroup
		mov	bx, offset systemMonitorCallbackTable
	;
	;	Each slot contains 2 far pointers = 4 bytes
	;
		dec	si			; make it a slot index 
		shl	si, 1
		shl	si, 1
		add	bx, si

		cmpdw	ds:[bx], 0		; empty slot?
		je	error

		clrdw	ds:[bx]			; remove callback
		mov	ax, EC_NO_ERROR
		clc	
done:
		.leave
		ret
error:
		mov	ax, EC_CALLBACKS_NOT_PRESENT
		stc
		jmp	done

GDISMRemoveMonitor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDISMGetExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
+PASS:		si	-> registerID
RETURN:		carry clear if successful
		carry set if get exclusive rejected.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDISMGetExclusive	proc	far
		.enter
		call	GDIGetExclusiveFar
		.leave
		ret
GDISMGetExclusive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDISMReleaseExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		si	-> register ID
RETURN:		ax	<- ErrorCode
		carry clear if successful
		carry set if release fails
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	8/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDISMReleaseExclusive	proc	far
		.enter
		call	GDIReleaseExclusiveFar
		.leave
		ret
GDISMReleaseExclusive	endp


MonitorCode			ends
























