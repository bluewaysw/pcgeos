COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosWaitPost.asm

AUTHOR:		Adam de Boor, Mar 10, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/10/92		Initial revision


DESCRIPTION:
	Hooking of BIOS WAIT/POST calls for those systems that support them.
		

	$Id: dosWaitPost.asm,v 1.1 97/04/10 11:54:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSWaitPostInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize support of wait/post

CALLED BY:	Version-specific init code
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
waitPostKeyStr	char	'waitpost', 0
DOSWaitPostInit	proc	near
		.enter
	;
	; See if [system]::waitpost enabled in the ini file.
	; 
		push	ds
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	si, offset systemCatStr
		mov	dx, offset waitPostKeyStr
		call	InitFileReadBoolean
		pop	ds
		jc	done		; => doesn't exist, so leave w/p off
		tst	ax
		jz	done		; => w/p turned off
	;
	; It's set true, but make sure we didn't just crash. If we did, the
	; crash could well be our fault, so we leave w/p off...
	; 
		call	SysGetConfig
		test	al, mask SCF_CRASHED
		jnz	done
	;
	; Start guardian timer
	; 
		mov	ds:[dosWPCount], 0
		mov	ds:[dosWaitPostOn], TRUE

		mov	al, TIMER_ROUTINE_CONTINUAL
		mov	bx, segment DOSWaitPostGuardian
		mov	si, offset DOSWaitPostGuardian
		mov	cx, WP_GUARD_INTERVAL
		mov	di, cx
		mov	dx, ds			; pass dgroup in ax
		call	TimerStart
		mov	ds:[dosWPGuardian], bx
		mov	ds:[dosWPGuardianID], ax
	;
	; And intercept wait/post interrupt.
	; 
		mov	ax, WAIT_POST_INTERRUPT
		mov	bx, segment DOSWaitPostHandler
		mov	cx, offset DOSWaitPostHandler
		segmov	es, ds
		mov	di, offset dosWaitPostSave
		call	SysCatchInterrupt
done:
		.leave
		ret
DOSWaitPostInit	endp

Init	ends

if FULL_EXECUTE_IN_PLACE
ResidentXIP	segment resource
else
Resident	segment	resource
endif


if	TEST_WAIT_POST

WaitPostCall	struct
    WPC_function	BiosWaitFunctions
    WPC_type		BiosWaitTypes
    WPC_sem		Semaphore
    WPC_thread		hptr.HandleThread
    WPC_time		sword
WaitPostCall	ends

WP_HISTORY_SIZE		equ	100

idata	segment
wpHistory	WaitPostCall	WP_HISTORY_SIZE dup (<>)
wpPtr		word	0
maxWaits	word	0
idata	ends

endif

if	CATCH_MISSED_COM1_INTERRUPTS
idata	segment
waitPostIntCount	sword	-1
waitPostAX	word	0
idata	ends
endif

if	TEST_WAIT_POST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSWaitPostStoreHistory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the current call in the wait/post history log

CALLED BY:	DOSWaitPostHandler
PASS:		ah	= WaitPostFunctions
		al	= BiosWaitTypes
		ds	= dgroup
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSWaitPostStoreHistory proc	near
		.enter
		pushf

		mov	bx, ds:[wpPtr]

		mov	ds:[wpHistory][bx].WPC_function, ah
		mov	ds:[wpHistory][bx].WPC_type, al

		mov	ax, ds:[dosWPSem].Sem_value
		mov	ds:[wpHistory][bx].WPC_sem.Sem_value, ax
		mov	ax, ds:[dosWPSem].Sem_queue
		mov	ds:[wpHistory][bx].WPC_sem.Sem_queue, ax

		push	bx
		mov	ax, TGIT_THREAD_HANDLE
		clr	bx
		call	ThreadGetInfo
		pop	bx
		mov	ds:[wpHistory][bx].WPC_thread, ax

		push	bx
		call	TimerGetCount
		pop	bx
		mov	ds:[wpHistory][bx].WPC_time, ax

		add	bx, size WaitPostCall
		cmp	bx, (size WaitPostCall) * WP_HISTORY_SIZE
		jnz	done
		clr	bx
done:
		mov	ds:[wpPtr], bx

		push	cs
		call	safePopf
		.leave
		ret
safePopf:
		iret
DOSWaitPostStoreHistory		endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	DOSWaitPostHandler

DESCRIPTION:	Handle INT 15h on the 286 or 386.  This interrupt provides a
		mechanism for catching BIOS wait loops

CALLED BY:	INT 15h

PASS:
	ah - function code (BiosWaitFunctions)
		BWF_WAIT - About to enter busy loop
		BWF_POST - Ready to exit busy loop
		Other - pass on
	al - type code (BiosWaitTypes)


RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/90		Initial version
	ardeb	3/11/92		brought into IFS driver

------------------------------------------------------------------------------@

DOSWaitPostHandler	proc	far
		push	bx
		push	ax
		push	ds
		push	cx
FXIP<		call	LoadVarSegDSFar					>
NOFXIP<		call	LoadVarSegDS					>

	;
	; go to code appropriate for function call...
	;
		tst	ds:[dosWPDisabled]	; if we've turned this off,
						;  then bypass
		jnz	passOn

		cmp	ah, BWF_WAIT
		jz	handleWait
		cmp	ah, BWF_POST
		jz	handlePost

	; unknown function, pass it on

passOn:
		pop	cx
		mov	bx, offset dosWaitPostSave
		jmp	DOSPassOnInterrupt

handleWait:
		inc	ds:[dosWPCount]

		cmp	ds:[dosWPCount], WP_DISABLE_THRESHOLD
		jnz	noMax
		mov	ds:[dosWPDisabled], TRUE
		jmp	passOn
noMax:
	;
	; Determine max wait time for the operation. If it's not one of
	; the operations we support, just pass the call on.
	; 
		mov	cx, FIXED_DISK_TIMEOUT
		cmp	al, BWT_FIXED_DISK
		jz	waitCommon

		mov	cx, FLOPPY_DISK_TIMEOUT
		cmp	al, BWT_FLOPPY_DISK
		jz	waitCommon

		mov	cx, FLOPPY_MOTOR_TIMEOUT
		cmp	al, BWT_FLOPPY_MOTOR_START
		jnz	passOn
waitCommon:

if	TEST_WAIT_POST
		call	DOSWaitPostStoreHistory
endif

		PTimedSem	ds, dosWPSem, cx, TRASH_AX_BX_CX, NO_EC

if	TEST_WAIT_POST
		jnc	noTimeout
		mov	ah, BWF_WAIT_TIMEOUT
		call	DOSWaitPostStoreHistory
noTimeout:
endif
		jmp	exit

handlePost:
	;
	; Field a post call, waking up the thread that's waiting on dosWPSem,
	; if something actually is.
	; 
		CheckHack <BWT_FLOPPY_DISK eq 1 AND BWT_FIXED_DISK eq 0>
		cmp	al, BWT_FLOPPY_DISK
		ja	passOn

if	TEST_WAIT_POST
		call	DOSWaitPostStoreHistory
endif
		; XXX: what if the thing just timed out? unlikely, but unhappy
		; nonetheless
		VSem	ds, dosWPSem, TRASH_AX_BX, NO_EC

exit:
	;
	; Common exit code. Restore registers and return with carry flag
	; set properly.
	; 
		pop	cx
		pop	ds
		lahf
		andnf	ah, mask CPU_CARRY shr 8
		mov	bx, sp
		ornf	ss:[bx+8], ah	; 8 = 2 (ax) + 2 (bx) + 2 (ip) + 2 (cs)
		pop	ax
		pop	bx
		iret

DOSWaitPostHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSWaitPostGuardian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Guardian routine for wait/post. Zeroes dosWPCount so
		DOSWaitPostHandler can tell when it is receiving too many
		calls.

CALLED BY:	Continual Timer
PASS:		ax	= dgroup
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSWaitPostGuardian proc far
		.enter
		mov	ds, ax
if TEST_WAIT_POST
   		mov	ax, ds:[dosWPCount]
		cmp	ax, ds:[dosWPMaxCount]
		jbe	zeroCounter
		mov	ds:[dosWPMaxCount], ax
zeroCounter:
endif
		mov	ds:[dosWPCount], 0
		.leave
		ret
DOSWaitPostGuardian endp

if FULL_EXECUTE_IN_PLACE
ResidentXIP	ends
Resident	segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSWaitPostExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset wait/post vector if we grabbed it.

CALLED BY:	DOSExit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, es, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSWaitPostExit	proc	near
		.enter
		tst	ds:[dosWaitPostOn]
		jz	done
		mov	ax, WAIT_POST_INTERRUPT
		mov	di, offset dosWaitPostSave
		segmov	es, ds
		call	SysResetInterrupt
done:
		.leave
		ret
DOSWaitPostExit	endp

Resident	ends
