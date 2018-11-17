COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Input Manager
FILE:		imInit.asm

AUTHOR:		Adam de Boor, Jan 28, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/28/91		Initial revision


DESCRIPTION:
	Initialization code for the Input Manager
		

	$Id: imInit.asm,v 1.1 97/04/05 01:17:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit segment resource

inputCategoryStr char 'input', 0
ifdef	SYSTEM_SHUTDOWN_CHAR
rebootOnResetStr char 'rebootOnReset', 0
quickShutdownStr char 'quickShutdownOnReset', 0
endif	; SYSTEM_SHUTDOWN_CHAR
leftHandedMouseStr char	"leftHanded", 0
doubleClickTimeStr char	"doubleClickTime", 0




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMAttach
		IMDetach
		IMEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle Init/Exit of Input Manager thread

CALLED BY:	MSG_META_ATTACH/MSG_META_DETACH

PASS:		ax - event type
		cx, dx, bp, si - event data
		ds, es - dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IMAttach	method	IMClass, MSG_META_ATTACH

	; GET STRATEGY ROUTINE FOR KEYBOARD DRIVER

	push	ds
	mov	ax, GDDT_KEYBOARD
	call	GeodeGetDefaultDriver	;puts keboard driver handle in ax
	mov	bx, ax
	call	GeodeInfoDriver		;puts structure in ds:si
	mov	ax, ds:[si][DIS_strategy.segment]
	mov	bx, ds:[si][DIS_strategy.offset]
	pop	ds
	mov	ds:[kbdStrategy.segment],ax
	mov	ds:[kbdStrategy.offset],bx


	call	InitIMMonitors		; Initialize our own monitors
	call	InitScreenSaver		; Initialize screen saver

	mov	cx, cs			; cx = init key seg
	mov	si, offset inputCategoryStr

ifdef	SYSTEM_SHUTDOWN_CHAR
	;
	; Fetch the input::rebootOnReset key and set our rebootOnReset
	; variable appropriately. It defaults to FALSE unless overridden by
	; the ini file.
	; 
	push	ds
	segmov	ds, cs
	mov	dx, offset rebootOnResetStr
	call	InitFileReadBoolean
	pop	ds
	jc	checkLefty		; => absent
	mov	ds:[rebootOnReset], al

	push	ds
	segmov	ds, cs
	mov	dx, offset quickShutdownStr
	call	InitFileReadBoolean
	pop	ds
	jc	checkLefty
	mov	ds:[alreadyReset], al

checkLefty:
endif	; SYSTEM_SHUTDOWN_CHAR
	push	ds
	segmov	ds, cs
	mov	dx, offset leftHandedMouseStr
	call	InitFileReadBoolean
	pop	ds
	jc	checkDoubleClickTime		; => absent
	mov	ds:[leftHanded], al

checkDoubleClickTime:
	push	ds
	segmov	ds, cs
	mov	dx, offset doubleClickTimeStr
	call	InitFileReadInteger
	pop	ds
	jc	done
	mov	ds:[doubleClickTime], ax

done:
	ret
IMAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitIMMonitors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets default user input characteristics

CALLED BY:	EXTERNAL

PASS:		ds - dgroup

RETURN:	

DESTROYED:	

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/9/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitIMMonitors	proc	near
		; SETUP STANDARD INPUT PROCESSING MONITORS

			; CombineInput Monitor
	mov	bx, offset  combineMonitor
	mov	cx, segment CombineInputMonitor
	mov	dx, offset CombineInputMonitor
	mov	al, ML_COMBINE		; processing LEVEL 40
	call	ImAddMonitor	; Add it.


			; Output Monitor
	mov	bx, offset  outputMonitor
	mov	cx, segment OutputMonitor
	mov	dx, offset OutputMonitor
	mov	al, ML_OUTPUT		; processing LEVEL 100
	call	ImAddMonitor	; Add it.

if SINGLE_STEP_PROFILING
			; Profile log dump monitor
	mov	bx, offset  profileMonitor
	mov	cx, segment ProfileMonitor
	mov	dx, offset ProfileMonitor
	mov	al, ML_DRIVER		; processing LEVEL 20
	call	ImAddMonitor	; Add it.
endif ; SINGLE_STEP_PROFILING

	ret

InitIMMonitors	endp

ObscureInitExit	ends

kinit	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitIM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Input Manager thread

CALLED BY:	InitGeos
PASS:		ds	= dgroup
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitIM		proc	near
		.enter
	;
	; Display log entry
	;
		push	ds
		segmov	ds, cs
		mov	si, offset imLogString
		call	LogWriteInitEntry
		pop	ds
	;
	; Get the class for the new beast to create us a thread.
	;
		mov	cx, segment IMClass	; cx:dx <- class for thread
		mov	dx, offset IMClass
		mov	bp, IM_STACK_SIZE	; bp <- stack size
		call	SysGetPenMode
		tst	ax
		jz	10$
		mov	bp, IM_PEN_MODE_STACK_SIZE
10$:

		mov	es, cx			; es:di <- class to call
		mov	di, dx
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
		call	ObjCallClassNoLock
EC <		ERROR_C	CANNOT_START_INPUT_MANAGER			>
		
		mov	ds:[imThread], ax	; record the thread handle
						;  for return by
						;  ImInfoInputProcess
	;
	; Raise the priority of the new thread to be major.
	;
		mov_trash	bx, ax
		mov	ax, (mask TMF_BASE_PRIO shl 8) or PRIORITY_HIGH
		call	ThreadModify

		.leave
		ret
InitIM		endp

imLogString	char	"IM Thread", 0

kinit	ends
