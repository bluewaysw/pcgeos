COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Printer drivers
FILE:		printEntry.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	DriverStrategy		entry point to driver
	PrintInfo		Return handle of info block
	PrintEscape		Generalized escape function

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	2/90	initial verison

DESCRIPTION:
	This file contains the entry point routine for the printer drivers.
		
	$Id: printcomEntry.asm,v 1.1 97/04/18 11:50:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriverStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all printer driver calls

CALLED BY:	GLOBAL

PASS:		di 	- driver function number
		bx	- PState handle

RETURN:		carry	- set if some communications error -- should abort
			  printing
		see specific routines for other return values

DESTROYED:	bx,bp,di,ds,es returned intact.
		other regs depend on function called.
		di will be zero if an escape function is not found

PSEUDO CODE/STRATEGY:
		call function thru the jump table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverStrategy	proc	far
		uses	bp, ds, es
		.enter

		; if we're calling the DRIVER_INFO function or DRIVER_INIT, 
		; forget about locking a pstate.  (Most callers won't need 
		; one). else, ; assume we need the PState locked.  Do it and 
		; use di for holding the segment address. Escape driver
		; calls always assume that a PState is present.

		push	bx			; save possible PState handle
		cmp	di, DR_PRINT_FIRST_PSTATE_NEEDED ; do we have a pstate?
		jb	checkModule		;  no, don't lock PState
		push	ax, ds			; save register
		call	MemLock
		mov	bp, ax			; save segment address here
		mov	ds, ax
		clr	ds:[PS_error]		; init to no error
		pop	ax, ds			; restore register

		; are we dealing with escape calls?
		
		or	di, di			; is it an escape ?
		js	handleEscape		;  yes, do escape function
		
		; see if it is a simple call handled in Entry, else call the
		; right module
checkModule:
		push	di
		cmp	di, DR_PRINT_LAST_RESIDENT ; a resident function ?
		ja	callSomeModule		   ;  no, call a module
		call	cs:residentJumpTable[di]   ; make the call
donePopDI:	pop	di

		pop	bx
		pushf				;save carry
		cmp	di, DR_PRINT_FIRST_PSTATE_NEEDED ; do we have a pstate?
		jb	afterMemStuff			;  no, all done
unlock:
		push	ax
		call	MemDerefDS		; ds -> PState
		mov	al, ds:[PS_error]	; grab error flag
		call	MemUnlock		; unlock the PState
		shr	ax, 1			; will set carry if error
		pop	ax
afterMemStuff:
		popf				;recover the carry flag.
exit::
		.leave
		ret

		; handle an escape code
handleEscape:
		call	PrintEscape
		pop	bx
		pushf
		jmp	unlock

		; calling a different module, handle it
callSomeModule:
		mov	ss:[TPD_dataAX], ax	; we want ax to get through
		mov	ss:[TPD_dataBX], bx
		mov	bx, cs:modHanJumpTable[di-DR_PRINT_FIRST_MOD] ; get han
		mov	ax, cs:modOffJumpTable[di-DR_PRINT_FIRST_MOD] ; get off
		call	ProcCallModuleRoutine	; direct call to right place
		jmp	donePopDI

DriverStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute some escape function

CALLED BY:	DriverStrategy

PASS:		di	- escape code (ORed with 8000h)

RETURN:		di	- set to 0 if escape not supported
			- return unchanged if handled

DESTROYED:	see individual functions

PSEUDO CODE/STRATEGY:
		scan through the table, find the code, call the handler.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEscape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset Entry:escCodes ; di -> esc code tab
		mov	cx, NUM_ESC_ENTRIES ; init rep count
		repne	scasw		; find the right one
		pop	es
		pop	ax
		jne	notFound	;  not in table, quit

		; function is supported, call through vector
found::
		sub	di, (offset Entry:escCodes) + 2 ; get offset into table
		pop	cx
		push	bx, bp
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		mov	bx, cs:escHanJumpTable[di] ; get handle
		mov	ax, cs:escOffJumpTable[di] ; get handle
		call	ProcCallModuleRoutine	   ; direct call to right place
		pop	bx, bp
		pop	di
		ret

		; function not supported, return di==0
notFound:
		pop	cx		; restore stack
		pop	di
		clr	di		; set return value
		clc			; no comm error...
		ret
PrintEscape	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the printer into stasis while PC/GEOS is switched out

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer for reason for refusal to suspend
RETURN:		carry set if refuse to suspend
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSuspend	proc	near
		.enter
		clc
		.leave
		ret
PrintSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resume the printer

CALLED BY:	DR_UNSUSPEND
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintUnsuspend	proc	near
		.enter
		clc		; just in case...
		.leave
		ret
PrintUnsuspend	endp
