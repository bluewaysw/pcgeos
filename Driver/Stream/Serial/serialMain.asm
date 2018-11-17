COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Serial Driver - Public Interface
FILE:		serial.asm

AUTHOR:		Adam de Boor, Jan 12, 1990

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/12/90		Initial revision
	andres	12/10/96	Modified for Penelope

DESCRIPTION:
	Code to communicate with multiple serial ports.

	Some notes of interest:

	There can be up to four serial ports on some machines, but
	there are only two interrupt levels allocated to the things, and
	most cards don't handle sharing the levels well at all (maybe
	because they're edge-triggered...). Some cards, however, offer other
	levels besides SDI_ASYNC and SDI_ASYNC_ALT, so we allow the user
	to specify the level in the .ini file under the [serial] category:

		port 1	= <num> gives the interrupt level for COM1
		port 2	= <num> gives the interrupt level for COM2
		port 3	= <num> gives the interrupt level for COM3
		port 4	= <num> gives the interrupt level for COM4

	The given interrupt level is verified, however, and the specification
	ignored if it is not correct.

	When a port is opened, its interrupt vector will be snagged by the
	driver, but not before then.

	$Id: serialMain.asm,v 1.96 98/05/05 17:49:49 cthomas Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	serial.def
include initfile.def
include heap.def		; need HF_FIXED
UseDriver Internal/powerDr.def

if LOG_MODEM_SETTINGS
include	Internal/log.def
endif

DefStub	macro	realFunc
Resident	segment	resource
realFunc&Stub	proc	near
		call	realFunc
		ret
realFunc&Stub	endp
Resident	ends
		endm


;------------------------------------------------------------------------------
;		       MISCELLANEOUS VARIABLES
;------------------------------------------------------------------------------
idata		segment

if	STANDARD_PC_HARDWARE

if	NEW_ISR

primaryVec	SerialVectorData <,,MiniSerialPrimaryInt,SDI_ASYNC>
alternateVec	SerialVectorData <,,MiniSerialAlternateInt,SDI_ASYNC_ALT>
weird1Vec	SerialVectorData <,,MiniWeird1Int>
weird2Vec	SerialVectorData <,,MiniWeird2Int>

else

primaryVec	SerialVectorData	<,,SerialPrimaryInt,SDI_ASYNC>
alternateVec	SerialVectorData	<,,SerialAlternateInt,SDI_ASYNC_ALT>
weird1Vec	SerialVectorData	<,,SerialWeird1Int>
							; Data for first weird
							;  port interrupting at
							;  non-standard level
weird2Vec	SerialVectorData	<,,SerialWeird2Int>
							; Data for second weird
							;  port interrupting at
							;  non-standard level
endif	; NEW_ISR

    irpc	n,<12345678>
    ;
    ; Data for the active port
    ;
    com&n	SerialPortData	<
	    0,0,0, offset com&n&_Sem, offset com&n&_passive, 0,
	    SERIAL_COM&n
    >
    com&n&_Sem	Semaphore

    ;
    ; Data for the passive port
    ;
    com&n&_passive	SerialPortData	<
	    0,0,0, offset com&n&_passive_Sem, offset com&n, mask SPS_PASSIVE,
	    SERIAL_COM&n&_PASSIVE
    >
    com&n&_passive_Sem	Semaphore

endm

;
; com port table of structures
;
comPorts	nptr.SerialPortData	com1, com2, com3, com4,
					com5, com6, com7, com8
;
; These are the passive representations of the serial ports, used when
; dealing with a passive (read-only, preemptible) connection.
;
comPortsPassive	nptr.SerialPortData com1_passive, com2_passive, com3_passive,
				    com4_passive, com5_passive, com6_passive,
				    com7_passive, com8_passive
else
		ImplementMe
endif	; ------------------- HARDWARE TYPE ---------------------------------

idata		ends

udata		segment
;
; Device map to return from DR_STREAM_GET_DEVICE_MAP
;
deviceMap	SerialDeviceMap	<0,0,0,0,0,0,0,0>

powerStrat	fptr.far

udata		ends

if	INTERRUPT_STAT
udata	segment

com1Stat	InterruptStatStructure
com2Stat	InterruptStatStructure
com3Stat	InterruptStatStructure

udata	ends
endif	; INTERRUPT_STAT

;------------------------------------------------------------------------------
;	Driver info table
;------------------------------------------------------------------------------


Resident	segment resource
DriverTable	DriverInfoStruct	<
	SerialStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>
ForceRef	DriverTable
Resident	ends

idata		segment
numPorts	word	0		; No known ports... will be changed by
					;  SerialRealInit

idata		ends

Resident	segment	resource
DefFunction	macro	funcCode, routine
if ($-serialFunctions) ne funcCode
	ErrMessage <routine not in proper slot for funcCode>
endif
.assert (TYPE routine eq NEAR) AND (SEGMENT routine eq @CurSeg), <Improper serial handler routine>
		nptr	routine
		endm

serialFunctions	label	nptr
DefFunction	DR_INIT,			SerialInitStub
DefFunction	DR_EXIT,			SerialExitStub
DefFunction	DR_SUSPEND,			SerialSuspend
DefFunction	DR_UNSUSPEND,			SerialUnsuspend
DefFunction	DR_STREAM_GET_DEVICE_MAP,	SerialGetDeviceMap
DefFunction	DR_STREAM_OPEN,			SerialOpenStub
DefFunction	DR_STREAM_CLOSE,		SerialCloseStub
DefFunction	DR_STREAM_SET_NOTIFY,		SerialSetNotify
DefFunction	DR_STREAM_GET_ERROR,		SerialHandOff
DefFunction	DR_STREAM_SET_ERROR,		SerialHandOff
DefFunction	DR_STREAM_FLUSH,		SerialFlush
DefFunction	DR_STREAM_SET_THRESHOLD,	SerialHandOff
DefFunction	DR_STREAM_READ,			SerialRead
DefFunction	DR_STREAM_READ_BYTE,		SerialReadByte
DefFunction	DR_STREAM_WRITE,		SerialWrite

DefFunction	DR_STREAM_WRITE_BYTE,		SerialWriteByte
DefFunction	DR_STREAM_QUERY,		SerialHandOff

DefFunction	DR_SERIAL_SET_FORMAT,		SerialSetFormat
DefFunction	DR_SERIAL_GET_FORMAT,		SerialGetFormat
DefFunction	DR_SERIAL_SET_MODEM,		SerialSetModem
DefFunction	DR_SERIAL_GET_MODEM,		SerialGetModem

DefFunction	DR_SERIAL_OPEN_FOR_DRIVER,	SerialOpenStub

DefFunction	DR_SERIAL_SET_FLOW_CONTROL,	SerialSetFlowControl

DefFunction	DR_SERIAL_DEFINE_PORT,		SerialDefinePortStub
DefFunction	DR_SERIAL_STAT_PORT,		SerialStatPort
DefFunction	DR_SERIAL_CLOSE_WITHOUT_RESET,	SerialCloseWithoutResetStub
DefFunction	DR_SERIAL_REESTABLISH_STATE,	SerialReestablishState
DefFunction	DR_SERIAL_PORT_ABSENT,		SerialPortAbsent

DefFunction	DR_SERIAL_GET_PASSIVE_STATE,	SerialGetPassiveState

DefFunction	DR_SERIAL_GET_MEDIUM,		SerialGetMedium
DefFunction	DR_SERIAL_SET_MEDIUM,		SerialSetMedium

DefFunction	DR_SERIAL_SET_BUFFER_SIZE,	SerialSetBufferSizeStub
DefFunction	DR_SERIAL_ENABLE_FLOW_CONTROL,	SerialEnableFlowControl
DefFunction	DR_SERIAL_SET_ROLE,		SerialSetRole


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all serial-driver functions

CALLED BY:	GLOBAL
PASS:		di	= routine number
		bx	= open port number (usually)
RETURN:		depends on function, but an ever-present possibility is
		carry set with AX = STREAM_CLOSING
DESTROYED:

PSEUDO CODE/STRATEGY:
		There are three classes of functions in this interface:
			- those that open a port
			- those that work on an open port
			- those that don't require a port to be open
		Each open port has a reference count that must be incremented
		for #2 functions on entry and decremented on exit.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;serialData	sptr	dgroup
SerialStrategy proc	far	uses es, ds
		.enter
		push	bx
EC <		cmp	di, SerialFunction				>
EC <		ERROR_AE	INVALID_FUNCTION			>
		segmov	es, ds		; In case segment passed in DS
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx
;		mov	ds, cs:serialData
   		cmp	di, DR_STREAM_OPEN
		jb	openNotNeeded
		je	openCall
		cmp	di, DR_SERIAL_OPEN_FOR_DRIVER
		je	openCall
		cmp	di, DR_SERIAL_DEFINE_PORT
		je	definePort
		cmp	di, DR_SERIAL_STAT_PORT
		je	openNotNeeded
		cmp	di, DR_SERIAL_SET_MEDIUM
		ja	mustBeOpen
		cmp	di, DR_SERIAL_GET_PASSIVE_STATE
		jae	openNotNeeded		;(get_passive_state,
						;get_medium, and set_medium may
						;all be done with the port open
						;or closed)
mustBeOpen:
	;
	; Point at port data if already open -- most things will
	; need it.
	;
		call	SerialGetPortData	; bx <- port data offset
	;
	; Up the reference count if the port is open. Fail if it's closed.
	;
		call	SysEnterCritical
		IsPortOpen bx
		jg	portNotOpen
		inc	ds:[bx].SPD_refCount
		call	SysExitCritical
	;
	; Call the function.
	;
		push	ds, bx
		call	cs:serialFunctions[di]
		pop	ds, bx

decRefCount:
	;
	; Port open/call complete. Reduce the reference count and clean up the
	; streams/V the openSem if the count is now 0. Again the check & cleanup
	; must be atomic. The port state should have been reestablished, and
	; any control returned to the passive open, in SerialClose
	;
		pushf
		call	SysEnterCritical
EC <		tst	ds:[bx].SPD_refCount				>
EC <		ERROR_Z	REF_COUNT_UNDERFLOW				>
		dec	ds:[bx].SPD_refCount
		jz	cleanUpStreams
		popf

exitCriticalAndExit:
		call	SysExitCritical
exit:
		pop	bx
		.leave
		ret

openCall:
	;
	; Open the port and reduce the reference count (initialized to 2) if
	; the open succeeds.
	;
		call	SerialOpen
		jnc	decRefCount
	;
	; If opened passive port preempted, we still need to drop the refcount
	;
		cmp	ax, STREAM_ACTIVE_IN_USE
		stc
		je	decRefCount
		jmp	exit

openNotNeeded:
	;
	; Port doesn't need to be open, so don't bother with the reference
	; count or open semaphore.
	;
		call	cs:serialFunctions[di]
		jmp	exit

portNotOpen:
	;
	; ERROR: Port is not open.  return with carry set and an error enum
	;
		mov	ax, STREAM_CLOSED		; signal error type
		stc
		jmp	exitCriticalAndExit

definePort:
	;
	; Defining a new port. No reference count shme, but we have to
	; return a different BX than we were passed, so we have to handle
	; this specially.
	;
		call	cs:serialFunctions[di]
		inc	sp		; return the BX we got back
		inc	sp
		push	bx
		jmp	exit

cleanUpStreams:
	;
	; Ref count down to 0. Finish destroying the two streams and release
	; the port.
	;
		push	cx, dx, ax
		clr	cx
		xchg	ds:[bx].SPD_inStream, cx
		clr	dx
		xchg	ds:[bx].SPD_outStream, dx

		mov	bx, ds:[bx].SPD_openSem
		VSem	ds, [bx], TRASH_AX_BX
	;
	; Exit critical section before attempting to free up the streams.
	;
		call	SysExitCritical

	;
	; Free the input stream.
	;
		mov	bx, cx
		tst	bx
		jz	inStreamGone
		call	StreamFree
inStreamGone:
	;
	; Then the output stream.
	;
		mov	bx, dx
		tst	bx
		jz	cleanUpDone
		call	StreamFree
cleanUpDone:
	;
	; Boogie with appropriate error code & flag from call.
	;
		pop	cx, dx, ax
		popf
		jmp	exit
SerialStrategy endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetPortData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the offset for the active or passive SerialPortData
		associated with a passed SerialPortNum.

CALLED BY:	Internal

PASS:		bx - SerialPortNum
		ds - serialData segment

RETURN:		bx - offset to either the active or passive SerialPortData
		     as indicated by the passed SerialPortNum.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialGetPortDataFAR	proc	far
		.enter
		call	SerialGetPortData
		.leave
		ret
SerialGetPortDataFAR	endp

SerialGetPortData	proc	near uses si
	.enter
EC <		push	ax, bx						>
EC <		and	bx, (not SERIAL_PASSIVE)			>
EC <		test	bx, 1						>
EC <		ERROR_NZ	INVALID_PORT_NUMBER			>
EC <		cmp	bx, SERIAL_COM8 				>
EC <		ERROR_A 	INVALID_PORT_NUMBER			>
;EC <		mov	ax, cs:serialData				>
EC <		push	es						>
EC <		mov	bx, handle dgroup				>
EC <		call	MemDerefES					>
EC <		mov	ax, es						>
EC <		pop	es						>
EC <		mov	bx, ds						>
EC <		cmp	ax, bx						>
EC <		ERROR_NE	DS_NOT_POINTING_TO_SERIAL_DATA		>
EC <		pop	ax, bx						>

	mov	si, offset comPorts
	test	bx, SERIAL_PASSIVE
	jz	loadOffset			; jump if active port

	;
	; The requested port has the passive flag set.  Clear the
	; flag, and the offset will be appropriate for indexing into
	; the comPortsPassive table.
	;
	mov	si, offset comPortsPassive
	and	bx, (not SERIAL_PASSIVE)

loadOffset:
	mov	bx, ds:[si][bx]

	.leave
	ret
SerialGetPortData	endp

Resident	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInitStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end for DR_INIT function. Just calls to SerialInit,
		which is movable.

CALLED BY:	DR_INIT (SerialStrategy)
PASS:		ds	= dgroup
RETURN:		Carry clear if we're happy
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialInitStub	proc	near
		.enter
		CallMod	SerialInit
		.leave
		ret
SerialInitStub	endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialExitStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle driver exit.

CALLED BY:	DR_EXIT (SerialStrategy)
PASS:		Nothing
RETURN:		Carry clear if we're happy, which we generally are...
DESTROYED:

PSEUDO CODE/STRATEGY:
		Nothing to do on exit, in contrast to init, so we don't.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialExitStub	proc	near
		.enter
		CallMod	SerialExit
		.leave
		ret
SerialExitStub	endp
Resident	ends


OpenClose	segment	resource

if INTERRUPT_STAT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialResetStatVar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear all variables in stat

CALLED BY:	SerialOpen
PASS:		ds:si	= SerialPortData for the port that was open just now
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialResetStatVar	proc	near
		uses	ax, di, es
		.enter
		segmov	es, ds, ax
		clr	ax
		mov	di, offset com1Stat
		cmp	si, offset com1
		je	doclr
		mov	di, offset com2Stat
		cmp	si, offset com2
		je	doclr
		mov	di, offset com3Stat
		cmp	si, offset com3
		je	doclr
		jmp	exit
doclr:
		mov	cx, size InterruptStatStructure
		rep stosw
exit:
		.leave
		ret
SerialResetStatVar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialWriteOutStat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out contents of stat variables to Ini file

CALLED BY:	SerialClose
PASS:		ds:si	= SerialPortData of the port just closed
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
com1Str		char	"com1",0
com2Str		char	"com2",0
com3Str		char	"com3",0

SerialWriteOutStat	proc	near
		uses	ds,es,di,si
		.enter
		
		segmov	es, ds, di
		segmov	ds, cs, di

		cmp	si, offset com1
		jne	ne1
		mov	di, offset com1Stat
		mov	si, offset com1Str
		jmp	doWrite
ne1:
		cmp	si, offset com2
		jne	ne2
		mov	di, offset com2Stat
		mov	si, offset com2Str
		jmp	doWrite
ne2:
		cmp	si, offset com3
		jne	ne3
		mov	di, offset com3Stat
		mov	si, offset com3Str
		jmp	doWrite
ne3:		
		jmp	done
doWrite:
		call	WriteOutStat
done:
		.leave
		ret
SerialWriteOutStat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteOutStat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out stat

CALLED BY:	SerialWriteOutStat
PASS:		es:di = one of com1Stat/com2Stat/com3Stat
		ds:si = pointer to correct category string: com1Str/com2Str/etc
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
interruptCountStr	char	"interruptCount",0
errorCountStr		char	"errorCount",0
xmitIntCountStr		char	"xmitIntCount",0
recvIntCountStr		char	"recvIntCount",0
fifoTimeoutStr		char	"fifoTimeout", 0
modemStatusCountStr	char	"modemStatusCount", 0
noActionCountStr	char	"noActionCount",0
bogusIntCountStr	char	"bogusIntCount",0
overrunCountStr		char	"overrunCount",0
bufferFullCountStr	char	"bufferFullCount",0

WriteOutStat	proc	near
		uses	cx,dx,bp
		.enter
		mov	cx, cs
		
		mov	bp, es:[di].ISS_interruptCount
		mov	dx, offset interruptCountStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_errorCount
		mov	dx, offset errorCountStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_xmitIntCount
		mov	dx, offset xmitIntCountStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_recvIntCount
		mov	dx, offset recvIntCountStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_fifoTimeout
		mov	dx, offset fifoTimeoutStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_modemStatusCount
		mov	dx, offset modemStatusCountStr
		call	InitFileWriteInteger

		mov	bp, es:[di].ISS_noActionCount
		mov	dx, offset noActionCountStr
		call	InitFileWriteInteger
				
		mov	bp, es:[di].ISS_bogusIntCount
		mov	dx, offset bogusIntCountStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_overrunCount
		mov	dx, offset overrunCountStr
		call	InitFileWriteInteger
		
		mov	bp, es:[di].ISS_bufferFullCount
		mov	dx, offset bufferFullCountStr
		call	InitFileWriteInteger

		.leave
		ret
WriteOutStat	endp

endif	; INTERRUPT_STAT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialFindVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the interrupt vector for a port.

CALLED BY:	SerialInitPort, SerialClose
PASS:		ds:si	= SerialPortData for the port
RETURN:		cx	= device interrupt level
		ds:di	= SerialVectorData to use
		carry set if no interrupt vector allocated to the port
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialFindVector proc	near
		.enter
		clr	cx
		mov	cl, ds:[si].SPD_irq	; cx <- interrupt level
		cmp 	cl, -1
		je	noInts			; -1 means can't interrupt
		;
		; Check known interrupt levels first
		;

		mov	di, offset primaryVec
if	STANDARD_PC_HARDWARE
		cmp	cl, SDI_ASYNC		; Primary vector?
		je	haveVec
		mov	di, offset alternateVec
		cmp	cl, SDI_ASYNC_ALT	; Alternate vector?
		je	haveVec
		;
		; Not a known level, so see if one of the weird interrupt
		; vector slots is available for use (or is already bound
		; to this level).
		;
		mov	di, offset weird1Vec
		cmp	ds:[di].SVD_irq, cl
		je	haveVec
		tst	ds:[di].SVD_port		; Weird1 taken?
		jz	setVec
		mov	di, offset weird2Vec
		cmp	ds:[di].SVD_irq, cl
		je	haveVec
		tst	ds:[di].SVD_port		; Weird2 taken?
		jz	setVec
endif	; STANDARD_PC_HARDWARE

noInts:
		stc				; Signal no vector available
haveVec:
		.leave
		ret
if	STANDARD_PC_HARDWARE
setVec:
		mov	ds:[di].SVD_irq, cl	; Claim this vector
						;  for our own.
		jmp	haveVec
endif
SerialFindVector endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInitVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Snag an interrupt vector. Unmasks the interrupt and makes
		sure any pending interrupt for the level has been
		acknowledged (this last is for init code, but can be
		useful...)

CALLED BY:	SerialCheckPort, SerialInitPort
PASS:		di	= SerialVectorData in dgroup for vector to be caught
		ds:si	= SerialPortData for port on whose behalf the vector is
			  being caught.
		bx	= segment of handling routine
		ds	= es
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		turn off interrupts
		fetch interrupt level from data and vector it to the
			proper handler
		figure the interrupt mask for the level
		fetch the current mask from the proper controller
		save the state of the mask bit for this level
		enable the interrupt in the controller
		send a specific end-of-interrupt command to the controller
			in charge for this level.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialInitVector proc	far	uses ax, dx, bx, cx, es
		.enter
		INT_OFF
		tst	ds:[di].SVD_port
		jnz	done		; non-zero => already intercepted
	;
	; Catch the interrupt vector
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
;		segmov	es, dgroup, ax
		clr	ax
		mov	al, ds:[di].SVD_irq
		mov	cx, ds:[di].SVD_handler
		push	di
		call	SysCatchDeviceInterrupt
		pop	di
		mov	cl, ds:[di].SVD_irq

	;
	; Figure which controller to change
	;
		mov	dx, IC1_MASKPORT
		cmp	cl, 8
		jl	10$
		sub	cl, 8
if	STANDARD_PC_HARDWARE
		;
		; Deliver specific EOI for chained-controller level to the
		; first controller while we're here...
		;
		mov	al, IC_SPECEOI or 2
		out	IC1_CMDPORT, al
endif
		mov	dx, IC2_MASKPORT
10$:
	;
	; Fetch the current mask and mask out the bit for this interrupt
	; level, saving it away in SVD_mask for restoration by
	; SerialResetVector.
	;
		mov	ah, 1
		shl	ah, cl
		in	al, dx
		and	ah, al
		mov	ds:[di].SVD_mask, ah
		;
		; Invert the result and mask the current interrupt-mask with it
		; If the bit for the level was already 0, this won't change
		; anything (only 1 bit was set in ah originally). If the bit
		; was 1, however, this will clear it.
		;
		not	ah
		and	al, ah
		out	dx, al
	;
	; Send a specific EOI for the level to the affected controller.
	;
if	STANDARD_PC_HARDWARE

		mov	al, IC_SPECEOI
		or	al, cl
CheckHack <IC1_CMDPORT - IC1_MASKPORT eq -1>
		dec	dx
endif	; STANDARD_PC_HARDWARE

		out	dx, al
done:
	;
	; Add this port to the list of ports for the interrupt vector.
	;
		mov	ax, ds:[di].SVD_port
		mov	ds:[si].SPD_next, ax
		mov	ds:[di].SVD_port, si
		
if	NEW_ISR
	;
	; initialize interrupt handler table to be non-flow control version,
	; as this is the faster of the two ( see FcHandlerTbl in
	; serialHighSpeed.asm )
	;
		mov	ds:[si].SPD_handlers, offset QuickHandlerTbl
endif
		
		INT_ON
		.leave
		ret
SerialInitVector endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialResetVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset an interrupt vector to its previous contents,
		re-masking the affected interrupt if it was masked before
		SerialInitVector was called.

CALLED BY:	SerialCheckPort, SerialClose
PASS:		di	= SerialVectorData in dgroup
		si	= SerialPortData offset of the port to unhook
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialResetVector proc	far	uses ax, dx, bx, es
		.enter
		INT_OFF
	;
	; Remove the port from the list for this vector
	;
		mov	bx, handle dgroup
		call	MemDerefES
;		segmov	es, dgroup, ax
		lea	ax, ds:[di].SVD_port-SPD_next
portLoop:
		mov	bx, ax
		mov	ax, ds:[bx].SPD_next
EC <		tst	ax					>
EC <		ERROR_Z	VECTOR_PORT_LIST_CORRUPTED		>
		cmp	ax, si
		jne	portLoop

		mov	ax, ds:[si].SPD_next
		mov	ds:[bx].SPD_next, ax

	;
	; If any ports are still using this interrupt vector, leave it alone
	;
		tst	ds:[di].SVD_port
		jnz	stillInUse
	;
	; Reset the mask bit to its original state, then put back the original
	; vector.
	;
		mov	dx, IC1_MASKPORT
		mov	al, ds:[di].SVD_irq
		cmp	al, 8
		jl	10$
		mov	dx, IC2_MASKPORT
10$:
		in	al, dx
		or	al, ds:[di].SVD_mask
		out	dx, al
		clr	ax
		mov	al, ds:[di].SVD_irq
		call	SysResetDeviceInterrupt
stillInUse:
		INT_ON
		.leave
		ret
SerialResetVector endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialFetchPortStatePC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch the port state for a PC-like port

CALLED BY:	SerialFetchPortState

PASS:		ds:si = SerialPortData
		ds:di = SerialPortState to fill

RETURN:		Void.

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 4/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialFetchPortStatePC	proc	near
		.enter
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_lineCtrl
		in	al, dx			; fetch line format first
						;  so we can mess with SF_DLAB
		mov	ds:[di].SPS_format, al

		mov	ah, al
		ornf	al, mask SF_DLAB
		out	dx, al			; go for the current baud rate
		jmp	$+2		; I/O delay
		sub	dx, offset SP_lineCtrl
		in	al, dx			; low byte
		mov	ds:[di].SPS_baud.low, al
		inc	dx
		in	al, dx			; high byte
		mov	ds:[di].SPS_baud.high, al
		mov	al, ah
		add	dx, offset SP_lineCtrl - offset SP_divHigh
		out	dx, al			; reset line format
		jmp	$+2		; I/O delay

		inc	dx			; dx <- SP_modemCtrl
		in	al, dx
		mov	ds:[di].SPS_modem, al
		add	dx, offset SP_ien - offset SP_modemCtrl
		in	al, dx
		mov	ds:[di].SPS_ien, al
		.leave
		ret
SerialFetchPortStatePC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialFetchPortState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the current state of the port in the port data for
		later restoration.

CALLED BY:	SerialInitPort, SerialCloseWithoutReset
PASS:		ds:si	= SerialPortData for the port
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialFetchPortState	proc	near	uses dx, es, di, bx, cx
		.enter
		INT_OFF
		lea	di, ds:[si].SPD_initState
if	STANDARD_PC_HARDWARE
		call	SerialFetchPortStatePC
endif	; STANDARD_PC_HARDWARE

		INT_ON
	;
	; Make sure we know the interrupt level at which the port is operating.
	;
		cmp	ds:[si].SPD_irq, -1
		clc
		jne	done
if	STANDARD_PC_HARDWARE

		mov	bx, ds:[si].SPD_portNum
	;
	; Now try and figure the interrupt level for the port.
	;
		call	SerialCheckPort
		jnc	portFound		; jump if found
	;
	; Not found, so clear the bit from our device map and return an error.
	;
		mov	cx, bx
		and	cx, (not SERIAL_PASSIVE) 	; nuke passive bit
		mov	ax, not 1
		rol	ax, cl
		andnf	ds:[deviceMap], ax

		mov	ax, STREAM_NO_DEVICE
		stc
endif	; STANDARD_PC_HARDWARE
		jmp	done

portFound:
	;
	; Copy the interrupt level and base to the passive port's data
	; structure if we're opening an active port or to the
	; active port if we're opening a passive port.
	;
		mov	ax, si			; save original pointer
		mov	cl, ds:[si].SPD_irq
		mov	dx, ds:[si].SPD_base
		mov	si, ds:[si].SPD_otherPortData
		mov	ds:[si].SPD_base, dx
		mov	ds:[si].SPD_irq, cl
		mov	si, ax			; recover original pointer

done:
		.leave
		ret
SerialFetchPortState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInitHWPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init a PC-like serial port

CALLED BY:	SerialInitPort

PASS:		ds:si = SerialPortData
		cx = buffer size

RETURN:		Void.

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 3/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialInitHWPC	proc	near
		.enter

		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_status 			; Clear pending
		in	al, dx					;  error irq
		jmp	$+2

		add	dx, offset SP_data-offset SP_status	; Clear pending
		in	al, dx					;  data avail
								;  irq
		jmp	$+2

		add	dx, offset SP_iid - offset SP_data	; Clear pending
		in	al, dx					;  transmit irq
		jmp	$+2

		add 	dx, offset SP_modemStatus-offset SP_iid	;Clear pending
		in	al, dx					;  modem status
		jmp	$+2					;  irq


	;
	; See if the port supports FIFOs.
	;
		add	dx, offset SP_iid - offset SP_modemStatus
		mov	al, mask SFC_ENABLE or mask SFC_XMIT_RESET or \
				mask SFC_RECV_RESET or \
				(FIFO_RECV_THRESHOLD_SFS shl offset SFC_SIZE)
		out	dx, al
		jmp	$+2
		in	al, dx
		test	al, mask SIID_FIFO_MODE
		jz	raiseSignals
		jpo	cantUseFIFO		; (see note there)

	;
	; 1/13/98 See if the input buffer is small.  If so, don't use
	; FIFO anyway.  If this port is for a mouse, use of a FIFO
	; produces jerky movement as the FIFO needs to time out before
	; responding.  We assume that a small buffer (<= 16 bytes) is
	; for a serial mouse. -- eca
		cmp	cx, 16			; small buffer?
		jbe	cantUseFIFO		; branch if so

	;
	; It does. Remember that we turned them on so we turn them off again
	; when we're done.
	;
		ornf	ds:[si].SPD_flags, mask SPF_FIFO
raiseSignals:

	;
	; Raise DTR and RTS on the port since it's open. Most things like to
	; have them asserted (e.g. modems) and I doubt if things would get
	; upset, so just do it here to save further calls by the user.
	;
		mov	al, mask SMC_OUT2 or mask SMC_DTR or mask SMC_RTS
adjustModemControl::
		add	dx, offset SP_modemCtrl - offset SP_iid
		out	dx, al
		mov	ds:[si].SPD_curState.SPS_modem, al
	;
	; 4/28/94: wait 3 clock ticks here to allow things to react to
	; having DTR asserted. In particular, this is here to allow a
	; serial -> parallel converter manufactured by GDT Softworks to
	; power up -- ardeb
		mov	ax, 3
		call	TimerSleep
	;
	; Now enable interrupts for the port. Only enable the DATA_AVAIL and
	; LINE_ERR interrupts until (1) we get data to transmit or (2) the user
	; expresses an interest in modem status changes.
	;
		add	dx, offset SP_ien - offset SP_modemCtrl
		mov	al, mask SIEN_DATA_AVAIL or mask SIEN_LINE_ERR
		mov	ds:[si].SPD_ien, al
		out	dx, al
		.leave
		ret

cantUseFIFO:
	;
	; The original 16550 part had asynchronous (read: random) failures
	; when operated in FIFO mode. On the 16550, the SIID_FIFO_MODE field
	; is 2 when FIFOs are enabled, while on the (working) 16550A, the field
	; is 3. Thus if the field is non-zero but the parity is odd, we've got
	; a 16550 and must turn the FIFOs back off again.
	;
		clr	al
		out	dx, al
		jmp	raiseSignals
SerialInitHWPC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInitPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize things for a newly opened port

CALLED BY:	SerialOpen
PASS:		bx	= owner handle
		ds:si	= SerialPortData for the port
		cx	= input buffer size
		dx	= output buffer size
RETURN:		carry set if port couldn't be initialized (ax = reason)
DESTROYED:	ax, cx, dx, di, bx

PSEUDO CODE/STRATEGY:
		Create a stream for the port
		Set up routine notifier for ourselves
		Set notification threshold to 1
		Grab interrupt vector and enable interrupts for port's
			interrupt level.
		Force the printer on-line and turn off auto-feed, since we
			do mostly graphics printing around here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version
	jdashe	4/27/94		Added passive port support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialInitPort 	proc	near
		.enter
		push	cx			; save size for init
		push	bx			; save handle for second stream
						;  creation
	;
	; Notify the power management driver
	;
		push	cx
		mov	cx, 1			; indicate open
		call	NotifyPowerDriver
		pop	cx
		mov	ax, STREAM_POWER_ERROR
		LONG	jc	openFailedPopOwner
	;
	; If on PCMCIA card, make sure the thing actually exists.
	;
		cmp	ds:[si].SPD_socket, -1
		je	getState

		mov	ax, ds:[si].SPD_base
		call	SerialCheckExists

		mov	ax, STREAM_NO_DEVICE
		LONG jc		openFailedPopOwner
getState:
	;
	; Fetch the initial state of the port and squirrel it away for close.
	;
	; This was already done for preempted passive ports.
	;
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
		jnz	bumpInputBuffer		; jump if passive

		call	SerialFetchPortState
		LONG	jc	openFailedPopOwner

	;
	; Replicate initial state as port's current state, for use when
	; re-establishing the port's state at some later date.
	;
		push	si, es, di, cx
		segmov	es, ds
		lea	di, ds:[si].SPD_curState
		lea	si, ds:[si].SPD_initState
		mov	cx, size SPD_curState
		rep	movsb
		pop	si, es, di, cx
	;
	; If this is a passive port, we need to bump the input buffer size
	; by one so we hold as many bytes as the caller requires, and still
	; easily check if the buffer has become full.
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jz	5$			; jump if not passive
bumpInputBuffer:
EC <		call	ECSerialVerifyPassive				>
		inc	cx
EC <		jmp	ECjump						>

5$:
EC <		call	ECSerialVerifyActive				>
EC < ECjump:								>
	;
	; Create the input stream of the specified size (first as
	; DR_STREAM_CREATE biffs CX, also want bx = output stream
	; for later calls) after setting the high- and low-water marks
	; based on the size.
	;
		call	SerialInitInput
		jc	openFailedCreatingFirstStream
	;
	; Now the output stream.
	;
	; If this is a passive connection, skip creating the output
	; stream, since a passive connections are read-only.
	;
		mov_tr	ax, dx
		pop	bx		; bx <- owner

		call	SerialInitOutput
		jc	openFailedFreeIn

		call	SerialFindVector
EC <		ERROR_C	SERIAL_PORT_CANT_INTERRUPT_AND_I_DONT_KNOW_WHY	>
		;
		; Intercept the device's interrupt vector, unless this
		; is a preempted passive port.
		;
		xchg	ax, cx			; (1-byte inst)
		mov	ds:[si].SPD_vector, di	; Record vector
		pop	cx			; cx <- input buffer size
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
		jnz	afterInit		; jump if preempted

		mov	bx, segment Resident
		call	SerialInitVector
	;
	; Disable all interrupts from the chip so we can make sure
	; all bogus existing conditions (like pending DATA_AVAIL or
	; TRANSMIT interrupts) are gone.
	;
		call	SerialInitHWPC
afterInit:
		clc				; We're happy
done:
		.leave
		ret

openFailedPopOwner:
openFailedCreatingFirstStream:
		pop	bx			;Restore "owner"
		pop	cx			;restore size
		jmp	openFailed
openFailedFreeIn:
		pop	cx			;restore size
	;
	; Open failed b/c we couldn't allocate the output stream. Need
	; to biff the input stream.
	;
		push	ax			; Save error code
		mov	bx, ds:[si].SPD_inStream
		mov	di, DR_STREAM_DESTROY
		mov	ax, STREAM_DISCARD
		call	StreamStrategy
		pop	ax
openFailed:
	;
	; Open failed, but don't want to leave the port locked, in case
	; resources get freed up later.
	;
		push	bx
		mov	bx, ds:[si].SPD_openSem
		VSem	ds, [bx]
		pop	bx

		clr	cx			; make sure power management
		call	NotifyPowerDriver	;  driver knows the thing's not
						;  actually open

		stc
		jmp	done
SerialInitPort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInitInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize the input stream for the port.

CALLED BY:	(INTERNAL) SerialInitPort
PASS:		cx	= buffer size
		ds:si	= SerialPortData
		bx	= handle to own the stream
RETURN:		carry set if couldn't create
DESTROYED:	ax, cx, bp, di, bx
SIDE EFFECTS:	SPD_inStream set

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialInitInput		proc	near
		uses	dx
		.enter
	;
	; Set the flow-control stuff and other input-related stuff first.
	; - SPD_lowWater is set to 1/4 the size of the input buffer
	; - SPD_highWater is set to 3/4 the size of the input buffer
	; - SPD_byteMask is set to 0x7f (cooked)
	; - SPD_mode is set to enable software flow control on both input
	;   and output
	;
		mov	ax, cx			; ax <- buffer size
		shr	cx			; Divide total size by 4
		shr	cx			;  to give low-water mark for
		mov	ds:[si].SPD_lowWater,cx	;  the port.

		mov	ds:[si].SPD_highWater,ax; Turn off flow-control if
						;  buffer too small (by setting
						;  high-water mark to the size
						;  of the buffer)
		neg	cx
		add	cx, ax			; cx <- bufsize - bufsize/4
		jle	10$
		mov	ds:[si].SPD_highWater,cx; cx > 0, so set as high water
10$:
		mov	ds:[si].SPD_byteMask, 0x7f
		mov	ds:[si].SPD_mode, mask SF_INPUT or mask SF_OUTPUT or \
				mask SF_SOFTWARE
	;
	; Now create the input stream.
	;
		push	ax			; save buffer size
		mov	cx, mask HF_FIXED
		mov	di, DR_STREAM_CREATE
		call	StreamStrategy		; bx = stream token
	;
	; Set the threshold for when the input stream drains below
	; the lowWater mark. We only register the notifier if we
	; send an XOFF.
	;
		pop	cx			; cx <- buffer size
		jc	done
		mov	ds:[si].SPD_inStream, bx
		sub	cx, ds:[si].SPD_lowWater
		mov	ax, STREAM_WRITE
		mov	di, DR_STREAM_SET_THRESHOLD
		call	StreamStrategy
	;
	; Initialize the data notifier on the writing side of the
	; input stream so we can just change the type to SNM_ROUTINE
	; in SerialInt when we want to cause an XON to be sent.
	;
		mov	ax, StreamNotifyType <0,SNE_DATA,SNM_NONE>
		mov	bp, si		; Pass SerialPortData offset to us
if	NEW_ISR
		mov	dx, offset ResumeIncomingData
		mov	cx, segment ResumeIncomingData
else
		mov	dx, offset SerialRestart
		mov	cx, segment SerialRestart
endif
		
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy
		clc
done:
		.leave
		ret
SerialInitInput endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInitOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the output stream for the port. If there's an open
		passive version of the port, preempt it.

CALLED BY:	(INTERNAL) SerialInitPort
PASS:		ds:si	= SerialPortData
		ax	= buffer size
		bx	= geode to own the stream
RETURN:		carry set if couldn't create
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialInitOutput proc	near
		.enter
	;
	; If port is passive, we don't have to do any of this
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
EC <		jz	noPassiveCheck					>
EC <		call	ECSerialVerifyPassive				>
EC <		jmp	doneOK						>
EC < noPassiveCheck:							>
	   	jnz	done			; (carry cleared by test)
	;
	; Create the stream.
	;
EC <		call	ECSerialVerifyActive				>
		mov	cx, mask HF_FIXED
		mov	di, DR_STREAM_CREATE
		call	StreamStrategy
		jc	done
		mov	ds:[si].SPD_outStream, bx
	;
	; Set up a routine notifier to call us when we stick data in
	; the output stream. This may seem strange, after all we're the one who
	; caused the data to go there, but it seems somehow cleaner to
	; me to do it this way...
	;
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	bp, si		; Pass SerialPortData offset to us
		mov	dx, offset SerialNotify
		mov	cx, segment SerialNotify
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy
		;
		; We need to know if even one byte goes in...
		; 8/21/95: set the threshold to 0, not 1, so we get a general
		; routine notification (not a special), but still get called
		; whenever something is there. This causes an initial
		; notification to happen (b/c there are the indicated number
		; of bytes currently in the stream [0]), but SerialNotify is
		; aware of this -- ardeb
		;
		mov	ax, STREAM_READ
		mov	cx, 0
		mov	di, DR_STREAM_SET_THRESHOLD
		call	StreamStrategy
	;
	; If there is a passive connection in progress, preempt it
	; with a call to SerialResetVector and copy any data in the
	; passive buffer to the just-created active input buffer.
	;
		mov	di, ds:[si].SPD_otherPortData
		IsPortOpen di			; passive port in use?
		jg	doneOK			; jump if no passive connection
		call	SerialCopyPassiveData
doneOK:
		clc
done:
		.leave
		ret
SerialInitOutput endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCopyPassiveData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data out of passive port, now the output stream has been
		successfully created.

CALLED BY:	(INTERNAL) SerialInitOutput
PASS:		ds:si	= SerialPortData for active
		ds:di	= SerialPortData for passive
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialCopyPassiveData proc	near
		uses	ds, si
		.enter
		mov_tr	ax, si			; ax <- active port data
		mov	si, di			; pass passive port data in si
		mov	di, ds:[di].SPD_vector	; di <- passive vector
		call	SerialResetVector
	;
	; copy data from the passive buffer to the active. (note that we can't
	; use SD_reader.SSD_sem, as that gets adjusted by reads...)
	;
		mov	di, si			; di <- passive port data
		mov_tr	si, ax			; si <- active port data
		mov	bx, ds:[si].SPD_inStream; bx <- active input stream
		mov	ds, ds:[di].SPD_inStream; ds <- passive input stream

		mov	si, offset SD_data	; ds:si <- source for copy
		mov	cx, ds:[SD_writer].SSD_ptr; cx <- number of bytes in
		sub	cx, si			  ;       the passive buffer
		jz	done			; jump if nothing to copy

		mov	ax, STREAM_NOBLOCK	; we want as much as possible
		mov	di, DR_STREAM_WRITE
		call	StreamStrategy		; Ignore results...

	;
	; Clear out the passive port's data buffer.
	;
		mov	bx, ds			; bx <- passive input stream
		mov	di, DR_STREAM_FLUSH
		call	StreamStrategy
	;
	; Reset the passive port's input stream pointer to the head of the
	; buffer.  Must change both reader and writer pointers because
	; they must be equal when the stream is empty!!
	;
		mov	ds:SD_writer.SSD_ptr, offset SD_data
		mov	ds:SD_reader.SSD_ptr, offset SD_data
done:
		.leave
		ret
SerialCopyPassiveData endp

OpenClose	ends

Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialBufferPowerChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The transmit interrupt has changed, so let the power driver
		know, if this port is a standard serial port (i.e. not
		PCMCIA)

CALLED BY:	(EXTERNAL) SerialReestablishState,
			   SerialEnableTransmit,
PASS:		ds:si	= SerialPortData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialBufferPowerChange proc	near
		.enter
		cmp	ds:[si].SPD_socket, -1
		jne	done		; => is PCMCIA

		push	cx
		mov	cx, 1
		call	NotifyPowerDriver
		pop	cx
done:
		.leave
		ret
SerialBufferPowerChange endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NotifyPowerDriver

DESCRIPTION:	Notify the power management driver that a serial port
		has opened or closed

CALLED BY:	INTERNAL

PASS:
	cx	= non-zero for open, zero for close
	ds:si	= SerialPortData for the port

RETURN:
	none

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/16/92		Initial version

------------------------------------------------------------------------------@
NotifyPowerDriver	proc	far	uses ax, bx, dx, di
	.enter
	;
	; If port is in a PCMCIA socket, specify that device instead.
	;
	cmp	ds:[si].SPD_socket, -1
	je	passSerialInfo

	mov	ax, PDT_PCMCIA_SOCKET
	mov	bx, ds:[si].SPD_socket
	mov	dx, mask PCMCIAPI_NO_POWER_OFF	; do not allow power-off while
						;  this device is open
	;
	; If this is a passive connection, then allow power-off after all.
	; If possible, have the machine wake up if there is data coming in from
	; the PCMCIA port.
	;
	test	ds:[si].SPD_passive, mask SPS_PASSIVE
	jz	notifyDriver
	;
	; Passive it is.
	;
	mov	dx, mask PCMCIAPI_WAKE_UP_ON_INTERRUPT
	jmp	notifyDriver

passSerialInfo:
	;
	; Convert SerialPortNum into a 0-based index, with the SERIAL_PASSIVE
	; bit still set in the high bit, if necessary.
	;
	mov	bx, ds:[si].SPD_portNum
	sar	bx, 1				; (duplicates SERIAL_PASSIVE)
	andnf	bx, not (SERIAL_PASSIVE shr 1)	; clear duplicate SERIAL_PASSIVE
						;  in bit 14, please

	mov	ax, PDT_SERIAL_PORT

	clr	dx
	mov	dl, ds:[si].SPD_ioMode
	ornf	dx, mask SPI_CONTROLS
	test	ds:[si].SPD_ien, mask SIEN_DATA_AVAIL
	jz	checkXmit
	ornf	dx, mask SPI_RECEIVE
checkXmit:
	test	ds:[si].SPD_ien, mask SIEN_TRANSMIT
	jz	notifyDriver
	ornf	dx, mask SPI_TRANSMIT
	.assert	$ eq notifyDriver

notifyDriver:
	mov	di, DR_POWER_DEVICE_ON_OFF
	call	SerialCallPowerDriver
	.leave
	ret

NotifyPowerDriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCallPowerDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make a call into the power driver

CALLED BY:	(EXTERNAL) NotifyPowerDriver,
			   SerialCheckExists (zoomer only)

PASS:		di = call to make
		ax,bx = args to power driver
		ds = dgroup

RETURN:		Void.

DESTROYED:	di?

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/20/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialCallPowerDriver	proc	far
	.enter
	;
	; Get the strategy routine once, if there's a power driver in the
	; system.
	;
	push	ax, bx
	mov	ax, ds:[powerStrat].segment
	inc	ax
	jz	noDriver		; => was -1, so power driver sought
					;  before and not found
	dec	ax
	jnz	haveStrategy		; => was neither -1 nor 0, so have
					;  strategy already
	mov	ds:[powerStrat].segment, -1	; assume no power driver
	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver
	tst	ax
	jz	noDriver

	mov_tr	bx, ax			; bx <- driver
	push	ds, si
	call	GeodeInfoDriver
	movdw	axbx, ds:[si].DIS_strategy
	pop	ds, si
	movdw	ds:[powerStrat], axbx

haveStrategy:
	pop	ax, bx
	call	ds:[powerStrat]
done:
	.leave
	ret

noDriver:
	pop	ax, bx
	jmp	done
SerialCallPowerDriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialResetPortPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reset a PC-like serial port

CALLED BY:	SerialResetPort

PASS:		ds:si = SerialPortData
		ds:bx = SerialPortState

RETURN:		Void.

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 3/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; this is a useful little macro to check for bogus interrupt requests coming
; in for my com3. Since we can now handle those, it's if'ed out, but I might
; need it again some day... note that it relies on an out 0xa0, 0xa having
; been done, to set the PIC to returning the IRR
chkirr	macro
if 0
	local q
	mov	cx, 2000
q:
	in	al, 0xa0
	test	al, 2
	loope	q
	ERROR_NZ	-1
endif
	endm

SerialResetPortPC	proc	far
		.enter
		chkirr

		mov	dx, ds:[si].SPD_base

	;
	; This is the action that can cause a spurious interrupt when
	; the chip is degated from the bus by our resetting OUT2, so
	; we do it first to give the system time to generate its spurious
	; interrupt while we've still got control of the vector...
	;
		add	dx, offset SP_modemCtrl	; first reset OUT2 et al
		mov	al, ds:[bx].SPS_modem
		out	dx, al

		chkirr
					; now, the enabled interrupts
		add	dx, offset SP_ien - offset SP_modemCtrl
		mov	al, ds:[bx].SPS_ien
		out	dx, al

		chkirr


		add	dx, offset SP_lineCtrl - offset SP_ien
		mov	al, ds:[bx].SPS_format
		mov	ah, al
		ornf	al, mask SF_DLAB
		out	dx, al		; reset baud-rate now

		chkirr

		jmp	$+2
		mov	al, ds:[bx].SPS_baud.low
		add	dx, offset SP_divLow - offset SP_lineCtrl
		out	dx, al

		chkirr

		inc	dx
		mov	al, ds:[bx].SPS_baud.high
		out	dx, al

		chkirr

		jmp	$+2

		mov	al, ah		; now the line format
		add	dx, offset SP_lineCtrl - offset SP_divHigh
		out	dx, al

		chkirr
	;
	; Mess with the FIFO state. If we're resetting the port to its
	; initial state, turn off FIFOs if no passive open remains. If we're
	; reestablishing the port's state (i.e. bx is SPD_curState), we
	; turn them back on again.
	;
		test	ds:[si].SPD_flags, mask SPF_FIFO
		jz	done		; => FIFO not enabled

		add	dx, offset SP_iid - offset SP_lineCtrl

		lea	ax, ds:[si].SPD_curState
		cmp	bx, ax
		je	turnFIFOsBackOn

		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jnz	resetFIFO	; => closing passive, so do reset

		push	si
		mov	si, ds:[si].SPD_otherPortData
		IsPortOpen	si
		pop	si
		jng	done		; => passive still open, so leave alone
resetFIFO:
		clr	al
setFIFO:
		out	dx, al
done:
		.leave
		ret

turnFIFOsBackOn:
		mov	al, mask SFC_ENABLE or mask SFC_XMIT_RESET or \
				mask SFC_RECV_RESET or \
				(FIFO_RECV_THRESHOLD_SFS shl offset SFC_SIZE)
		jmp	setFIFO
SerialResetPortPC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReestablishState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reprogram the port to match the state most-recently set for
		it, to cope with power having been lost, for example.
		(Must be Resident for PCMCIA support)

CALLED BY:	DR_SERIAL_REESTABLISH_STATE
PASS:		ds:bx	= SerialPortData for the port
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		We alter the state a bit by turning the transmitter interrupt
		on so any aborted outputs will actually get started up
		automatically. If there's nothing in the output stream, this
		just causes an extra interrupt, but does no harm.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialReestablishState proc	near
		uses	si
		.enter
		andnf	ds:[bx].SPD_flags, not mask SPF_PORT_GONE
		mov	si, bx
		lea	bx, ds:[si].SPD_curState
		ornf	ds:[bx].SPS_ien, mask SIEN_TRANSMIT

	;
	; Make sure the transmit buffers are enabled for the nonce.
	;
		call	SerialBufferPowerChange

		call	SerialResetPortPC
		.leave
		ret
SerialReestablishState endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialPortAbsent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a port is temporarily AWOL

CALLED BY:	DR_SERIAL_PORT_ABSENT
PASS:		ds:bx	= SerialPortData for the port
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialPortAbsent proc	near
		.enter
		ornf	ds:[bx].SPD_flags, mask SPF_PORT_GONE
		.leave
		ret
SerialPortAbsent endp

Resident	ends

OpenClose	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialResetPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset a port to its initial state, as saved in its
		SerialPortData descriptor.

CALLED BY:	SerialEnsureClosed, SerialClose
PASS:		ds:si	= SerialPortData
RETURN:		nothing
DESTROYED:	dx, ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialResetPort	proc	near	uses cx, bx
		.enter
	;
	; Tell the power management driver that we are done with the port
	;
		push	cx
		clr	cx
		call	NotifyPowerDriver
		pop	cx
	;
	; Use the reset routines to restore the port to its initial state.
	;
		INT_OFF
if 0	; for chkirr macro...
		mov	al, 10
		out	0xa0, al
endif
		lea	bx, ds:[si].SPD_initState
		call	SerialResetPortPC
		INT_ON
		.leave
		ret
SerialResetPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open one of the serial ports

CALLED BY:	DR_STREAM_OPEN,  DR_SERIAL_OPEN_FOR_DRIVER (SerialStrategy)
PASS:		ax	= StreamOpenFlags record. SOF_NOBLOCK and SOF_TIMEOUT
			  are exclusive.
		bx	= port number to open
		cx	= total size of input buffer
		dx	= total size of output buffer
		bp	= timeout value if SOF_TIMEOUT given in ax
		ds	= dgroup
		si	= owner handle, if DR_STREAM_OPEN_FOR_DRIVER
RETURN:		carry set if port couldn't be opened:
			ax = STREAM_NO_DEVICE if device doesn't exist
			     STREAM_DEVICE_IN_USE if SOF_NOBLOCK or
			         SOF_TIMEOUT given and device is already open/
				 timeout period expired.

		carry set and ax = STREAM_ACTIVE_IN_USE if a passive
			port was opened in a PREEMPTED state.

		carry clear if port opened
			ds:bx	= SerialPortData for port
DESTROYED:	cx, dx, bp, bx (preserved by SerialStrategy)
		See KNOWN BUGS below.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	By default, though, flow control is turned off.  In order to do flow
	control at driver level, you need to call DR_SERIAL_SET_FLOW_CONTROL,
	DR_SERIAL_ENABLE_FLOW_CONTROL, and DR_SERIAL_SET_ROLE( for H/W fc ).

	BUG: It is a bug that cx, dx and bp are destroyed, since they should
	     be preserved according to DR_STREAM_OPEN and
	     DR_SERIAL_OPEN_FOR_DRIVER.  But since this bug already exists
	     in shipped products, we decide to keep the bug and document it
	     here instead of fixing it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefStub	SerialOpen

SerialOpen	proc	far	uses si, di
		.enter

		call	SerialGetPortDataFAR	; ds:bx <- SerialPortData
		xchg	si, bx
		tst	ds:[si].SPD_base
		jz	portExistethNot

		;
		; Open passive ports elsewhere.
		;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jz	openActive
		call	SerialPassiveOpen
		jmp	exit

openActive:
EC <		test	ax, not StreamOpenFlags				>
EC <		ERROR_NZ	OPEN_BAD_FLAGS				>
EC <		test	ax, mask SOF_NOBLOCK or mask SOF_TIMEOUT	>
EC <		jz	10$	; neither is ok				>
EC <		jpo	10$	; just one is fine			>
EC <		ERROR		OPEN_BAD_FLAGS				>
EC <10$:								>

		test	ax, mask SOF_NOBLOCK or mask SOF_TIMEOUT
		jnz	noBlockOpenPort

		push	bx
		mov	bx, ds:[si].SPD_openSem
		PSem	ds, [bx]		; Wait for port to be available
		pop	bx
afterPortOpen:
	;
	; Set the reference count to 2: one for the thing being open (will
	; be reduced in SerialClose) and one for this call (in case someone
	; closes the thing while we're opening it, or something ludicrous
	; like that)
	;
		mov	ds:[si].SPD_refCount, 2
		;
		; This port is free for an active connection.  Do we have a
		; passive connection which we can preempt?
		;
		mov	si, ds:[si].SPD_otherPortData	; si <- passive port
		IsPortOpen	si		; passive connection?
		jg	continueOpening		; jump if no passive

		;
		; There is a passive connection in progress.  Preempt the
		; passive connection then continue with the usual connection
		; procedure.  When we have an input stream, we'll copy the
		; data from the passive connection's input stream.
		;
		call	SerialPreemptPassive

continueOpening:
		mov	si, ds:[si].SPD_otherPortData	; si <- active port
		cmp	di, DR_SERIAL_OPEN_FOR_DRIVER
		je	15$			; => bx already contains owner
		call	GeodeGetProcessHandle	; Stream owned by opener
15$:

		call	SerialInitPort

exit:
		mov	bx, si			; ds:bx <- SerialPortData, in
						;  case successful open
	;
	; interrupt stat
	; ds:si - SerialPortData
	;
IS <		pushf							>
IS <		call	SerialResetStatVar				>
IS <		popf							>

		.leave
		ret

portExistethNot:
		mov	ax, STREAM_NO_DEVICE
		stc
		jmp	exit

noBlockOpenPort:
		;
		; Perform a non-blocking PSem on the openSem for a port. We
		; also come here if just have a timeout option -- in the case
		; of a non-blocking one, we just have a timeout value of 0...
		;
		test	ax, mask SOF_TIMEOUT
		jnz	20$
		clr	bp

20$:
		push	bx
		mov	bx, ds:[si].SPD_openSem
		PTimedSem	ds, [bx], bp
		pop	bx
		jnc	afterPortOpen

		mov	ax, STREAM_DEVICE_IN_USE
		jmp	exit
SerialOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialPassiveOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to open passive serial port connections ala
		SerialOpen.  It's identical in intent to SerialOpen,
		but the arguments and actions are slightly different:

		* There are no StreamOpenFlags; passive opens are always
		  SOF_NOBLOCK.
 		* There is no output buffer in passive port connections.

CALLED BY: SerialOpen

PASS:		ds:si	= SerialPortData for this port
		cx	= input buffer size
		bx	= owner handle, if DR_STREAM_OPEN_FOR_DRIVER

RETURN:	carry set and ax set to one of the following:
		  ax 	= STREAM_NO_DEVICE if device doesn't exist
			= STREAM_DEVICE_IN_USE if the passive port is in use.
			= STREAM_ACTIVE_IN_USE if the passive port was opened
			  in a PREEMPTED state.

	carry clear if the port opened with no problems.

DESTROYED:	cx, dx, bp, bx
		(preserved by SerialStrategy or SerialOpen)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	5/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialPassiveOpen	proc	near
		uses si, di
		.enter

EC <		call	ECSerialVerifyPassive				>
		tst	ds:[si].SPD_base
	   LONG jz	portExistethNot
	;
	; If there is already a passive connection in progress, the
	; open fails.
	;
		push	bx
		mov	bx, ds:[si].SPD_openSem
		PTimedSem	ds, [bx], 0
		pop	bx
		jc	deviceInUse
	;
	; Set the reference count to 2: one for the thing being open (will
	; be reduced in SerialClose) and one for this call (in case someone
	; closes the thing while we're opening it, or something ludicrous
	; like that)
	;
		mov	ds:[si].SPD_refCount, 2
	;
	; The port exists.  Initialize its status flags.
	;
		andnf	ds:[si].SPD_passive, not (mask SPS_BUFFER_FULL or mask SPS_PREEMPTED)
	;
	; If there is not an active connection in progress, open the port
	; normally.  Otherwise, set up the passive connection as a
	; preempted port.
	;
		mov	si, ds:[si].SPD_otherPortData	; si <- active port
		IsPortOpen si
		mov	si, ds:[si].SPD_otherPortData	; si <- passive port
		jg	afterPortOpen
		ornf	ds:[si].SPD_passive, mask SPS_PREEMPTED

afterPortOpen:
	;
	; Open the port (or set things up if the port is preempted).
	;
		cmp	di, DR_SERIAL_OPEN_FOR_DRIVER
		je	15$			; => bx already contains owner
		call	GeodeGetProcessHandle	; Stream owned by opener
15$:
		call	SerialInitPort
		jc	exit

	;
	; If this port is opening preempted, copy the current state of
	; the active port into the passive port's current and initial state.
	;
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
		jz	doneOK			; jump if not opening preempted

		push	es, si
		segmov	es, ds, cx
		mov	di, ds:[si].SPD_otherPortData	; di <- active port
		add	di, SPD_initState
		add	si, SPD_initState
		xchg	di, si
	;
	; di - passive port's SPD_initState
	; si - active port's SPD_initState
	;
		mov	cx, size SerialPortState
		call	SysEnterCritical
		rep	movsb
		call	SysExitCritical
	;
	; Copy the same data for the passive's curState.
	;
		mov	cx, size SerialPortState
		sub	di, cx
		mov	si, di			; si <- passive's initState
		sub	di, cx			; di <- passive's curState
CheckHack < SPD_curState eq (SPD_initState - size SerialPortState) >
		rep	movsb

		pop	es, si

		mov	ax, STREAM_ACTIVE_IN_USE
openFailed:
		stc
		jmp	exit

doneOK:
		clc
exit:
		.leave
		ret

portExistethNot:
		mov	ax, STREAM_NO_DEVICE
		jmp	openFailed

deviceInUse:
		mov	ax, STREAM_DEVICE_IN_USE
		jmp	openFailed

SerialPassiveOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialPreemptPassive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function deals with preempting a passive
		connection with an active one.

CALLED BY:	SerialOpen

PASS:		ds:si	= SerialPortData for the passive port to be preempted

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		* Notify the passive owner that the connection is being
		  preempted.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialPreemptPassive	proc	near
		uses	cx
		.enter

EC <		test	ds:[si].SPD_passive, mask SPS_PASSIVE		>
EC <		ERROR_Z	NOT_A_PASSIVE_PORT				>
EC <		call	ECSerialVerifyPassive				>
	;
	; Set the preempted flag.
	;
		or	ds:[si].SPD_passive, mask SPS_PREEMPTED

		mov	cx, mask SPNS_PREEMPTED or mask SPNS_PREEMPTED_CHANGED
		call	SerialPassiveNotify

		.leave
		ret
SerialPreemptPassive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close an open serial port.

CALLED BY:	DR_STREAM_CLOSE (SerialStrategy)
PASS:		ds:bx	= SerialPortData for the port
		ax	= STREAM_LINGER if should wait for pending data
			  to be read before closing. STREAM_DISCARD if
			  can just throw it away.
			  NOTE: passive ports don't have output
			  buffers, so ax is ignored.
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefStub	SerialClose

SerialClose	proc	far	uses si, di, cx, dx
		.enter
		mov	si, bx
	;
	; serial Stat
	; ds:si	= current SerialPortData
	;
IS <		call	SerialWriteOutStat				>
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jz	notPassive
			CheckHack <STREAM_DISCARD eq 0>
		clr	ax
EC <		call	ECSerialVerifyPassive				>
EC <		jmp	axOK						>
notPassive:
EC <		call	ECSerialVerifyActive				>
EC <		cmp	ax, STREAM_LINGER				>
EC <		je	axOK						>
EC <		cmp	ax, STREAM_DISCARD				>
EC <		ERROR_NE AX_NOT_STREAM_LINGER_OR_STREAM_DISCARD		>
EC <axOK:								>

		mov	cx, ax
		;
		; Turn off all but transmit interrupts for the port first.
		;
CheckHack <STREAM_LINGER eq -1 AND STREAM_DISCARD eq 0>
		andnf	al, ds:[si].SPD_ien	; If discarding, this will
						;  result in al==0, disabling
						;  *all* interrupts, which
						;  will prevent us using a
						;  dead stream in the interrupt
						;  routine. If lingering, this
						;  will just give us SPD_ien
		andnf	al, mask SIEN_MODEM or mask SIEN_TRANSMIT
		jcxz	dontWorryAboutSTOPBit
		test	ds:[si].SPD_mode, mask SF_SOFTSTOP
		jz	dontWorryAboutSTOPBit
		;
		; If output is currently stopped and we're lingering, we must
		; continue to get DATA_AVAIL interrupts so we can get the XON
		; character that turns output back on again...
		;
		mov	ah, mask SIEN_DATA_AVAIL
dontWorryAboutSTOPBit:
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_ien
		or	al, ah			; or in correct DATA_AVAIL bit
	;
	; If this is a preempted passive port, no touchie the
	; hardware, please.
	;
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
EC <		jz	biffHardware					>
EC <		pushf							>
EC <		call	ECSerialVerifyPassive	; sets ZF		>
EC <		popf							>
EC <biffHardware:							>
		jnz	nukeInputStream		; jump if preempted
		out	dx, al

nukeInputStream:
		;
		; Shut down the input stream first, discarding any remaining
		; data. The thing will be freed by SerialStrategy when the
		; ref count goes to 0.
		;
		mov	bx, ds:[si].SPD_inStream
		mov	ax, STREAM_DISCARD
		call	StreamShutdown

		;
		; If this is a passive buffer, we don't have an output stream.
		;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jnz	outStreamGone

		;
		; Now biff the output stream, passing whatever linger/discard
		; constant we were given.
		;
		mov	ax, cx
		mov	bx, ds:[si].SPD_outStream
		call	StreamShutdown

outStreamGone:
	;
	; If this is a preempted port, we are not intercepting
	; interrupts, nor do we need to reset the port.  We do need to
	; update the active port's initState with the passive's,
	; however, so when the active closes down it will reset the
	; port to its original state.
	;
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
		jz	nukeInterrupts

EC <		call	ECSerialVerifyPassive				>
		push	es, cx, di, si
		segmov	es, ds, cx
		mov	di, ds:[si].SPD_otherPortData
		add	di, SPD_initState
		add	si, SPD_initState
		mov	cx, size SerialPortState
		call	SysEnterCritical
		rep	movsb
		call	SysExitCritical
		pop	es, cx, di, si
		jmp	vPort

nukeInterrupts:
	;
	; Turn off all interrupts for the port, now the streams are gone.
	;
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_ien
		clr	al
		out	dx, al

	;
	; Reset the modem-event notifier.
	;
		mov	ds:[si].SPD_modemEvent.SN_type, SNM_NONE
	;
	; Restore the initial state of the port before resetting the vector,,
	; as tri-stating the IRQ line can have the nasty side-effect of
	; allowing the interrupt line to float, thereby triggering a spurious
	; interrupt. Since our interrupt code deals with not having any
	; streams to use, it's safe to let it handle any spurious interrupts
	; this resetting can generate.
	;
		call	SerialResetPort

	;
	; Reset the appropriate interrupt vector to its earlier condition.
	;
		mov	di, ds:[si].SPD_vector
		call	SerialResetVector
	;
	; We're ready to V the semaphore if this is a passive port.
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jnz	vPort
	;
	; We're closing down an active port.  Is there a passive port
	; that needs to be reawakened?
	;
		mov	di, ds:[si].SPD_otherPortData ; ds:di <- passive port
		IsPortOpen di
		jg	vPort		; jump if no passive connection
	;
	; There is indeed a passive open that needs dealing with.
	; Redo the passive's SerialInitVector and send a notification
	; to the passive owner that it's back in business.
	;
		xchg	si, di		; ds:si <- passive port
		andnf	ds:[si].SPD_passive, not (mask SPS_PREEMPTED)
	;
	; Intercept the device's interrupt vector.
	;
		mov	di, ds:[si].SPD_vector	; Record vector
		mov	bx, segment Resident
		call	SerialInitVector
		mov	cx, 0xffff		; cx <- large size
		call	SerialInitHWPC
	;
	; Notify the owner of the passive port that the passive port
	; is back in action.
	;
		mov	cx, mask SPNS_PREEMPTED_CHANGED
		call	SerialPassiveNotify
	;
	; In case there's a pending active port, V the closing active
	; port's semaphore.
	;
		mov	si, ds:[si].SPD_otherPortData

vPort:
	;
	; We used to V the openSem here, but now we do it in SerialStrategy
	; when the refCount goes to 0.
	;
		dec	ds:[si].SPD_refCount
EC <		ERROR_Z	REF_COUNT_UNDERFLOW				>
		.leave
		ret
SerialClose	endp
OpenClose	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCloseWithoutReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down an open port without resetting it to its initial
		condition. Useful for PCAO, mostly.

CALLED BY:	DR_SERIAL_CLOSE_WITHOUT_RESET
PASS:		ds:bx	= SerialPortData for the port
		ax	= STREAM_LINGER if should wait for pending data
			  to be read before closing. STREAM_DISCARD if
			  can just throw it away.
RETURN:		port interrupts are off, but all other attributes of the
		port remain untouched (except it's closed from our perspective).
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefStub	SerialCloseWithoutReset

OpenClose	segment
SerialCloseWithoutReset	proc	far	uses si, es, cx
		.enter
	;
	; Just store the current state of the port as its initial state, so
	; SerialResetPort won't do anything to it.
	;
		lea	si, ds:[bx].SPD_curState
		lea	di, ds:[bx].SPD_initState
		mov	cx, size SPD_initState
		segmov	es, ds
		rep	movsb
		mov	si, bx
	;
	; Do not leave any interrupts on when we've closed the thing. This
	; prevents us from dying horribly should a byte come in after we've
	; closed but before the system has been shut down.
	;
		mov	ds:[si].SPD_initState.SPS_ien, 0
	;
	; And close the port normally.
	;
		call	SerialClose
		.leave
		ret
SerialCloseWithoutReset	endp
OpenClose	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a notifier for the caller. If SNT_EVENT is SNE_ERROR,
		SNT_READER must be set, as errors are posted only to the
		reading side of the stream.

		If SNT_EVENT is SNE_PASSIVE, SNT_READER must be set
		and the unit number must be for a passive port.
		If the passive port has a full buffer or has been
		preempted, a notification will be sent out immediately.

CALLED BY:	DR_STREAM_SET_NOTIFY
PASS:		ax	= StreamNotifyType
		bx	= unit number (transformed to SerialPortData offset by
			  SerialStrategy).
		cx:dx	= address of handling routine, if SNM_ROUTINE;
			  destination of output if SNM_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA with
			  threshold of 1, in which case value is passed in CX);
			  method to send if SNM_MESSAGE.
RETURN:		nothing
DESTROYED:	ax, bx (saved by SerialStrategy)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version
	jdashe	5/13/90		Added support for passive notifications

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource
SerialSetNotify proc	near	uses si, dx
		.enter
	;
	; See if the event in question is ours
	;
		mov	si, ax
		andnf	si, mask SNT_EVENT
		cmp	si, SNE_MODEM shl offset SNT_EVENT
		je	setupModemEvent	; jump if a modem event
		cmp	si, SNE_PASSIVE shl offset SNT_EVENT
		jne	handOff		; Nope -- hand off to stream driver

	;
	; We're setting a passive notification, so make sure it's a
	; passive port.  Also make sure it's being set for the reader.
	;
EC <		test	ds:[bx].SPD_passive, mask SPS_PASSIVE		>
EC <		ERROR_Z NOT_A_PASSIVE_PORT 				>
EC <		test	ax, mask SNT_READER				>
EC <		ERROR_Z	BAD_CONTEXT_FOR_PASSIVE_PORT			>
EC <		xchg	bx, si						>
EC <		call	ECSerialVerifyPassive				>
EC <		xchg	bx, si						>
	;
	; Store the parameters in our very own SPD_passiveEvent structure.
	;
		lea	si, ds:[bx].SPD_passiveEvent
		call	SerialSetNotificationEvent	; ax <- SNT_HOW only
	;
	; If there are any pending notifications for this passive
	; port, send them off now.
	;
		test	ds:[bx].SPD_passive, (mask SPS_PREEMPTED or \
					      mask SPS_BUFFER_FULL)
		jz	doneOK
		tst	ax			; clearing the notification?
		jz	doneOK			; jump if clearing.

		push	cx
		clr	cx
		test	ds:[bx].SPD_passive, mask SPS_PREEMPTED
		jz	detectBufferFull
		mov	cx, mask SPNS_PREEMPTED or mask SPNS_PREEMPTED_CHANGED

detectBufferFull:
		test	ds:[bx].SPD_passive, mask SPS_BUFFER_FULL
		jz	sendNotify
		ornf	cx, (mask SPNS_BUFFER_FULL or \
			     mask SPNS_BUFFER_FULL_CHANGED)
sendNotify:
		xchg	bx, si			; ds:si <- port data
		call	SerialPassiveNotify
		xchg	bx, si			; ds:bx <- port data
		pop	cx

		jmp	doneOK

setupModemEvent:
	;
	; Were's setting the modem notification.  Store the parameters in our
	; very own SPD_modemEvent structure.
	;
		lea	si, ds:[bx].SPD_modemEvent
		call	SerialSetNotificationEvent	; ax <- SNT_HOW only
if NOTIFY_WHEN_SNE_MODEM_CHANGED
		call	SerialNotifyModemNotifierChanged
endif
		;
		; Enable/disable modem status interrupts for the port.
		;
		CheckHack <SNM_NONE eq 0>
		tst	ax
		mov	al, ds:[bx].SPD_ien
		jz	disable		; SNT_HOW is SNM_NONE, so no longer
					;  interested in modem interrupts
		; ZSIEN_MODEM HAPPENS TO BE THE SAME AS SIEN_MODEM SO I JUST
		; LEFT THE CODE IN AS IS RATHER THAN CHECKING TO SEE WHICH
		; TO USE IN THE ZOOMER CODE
		ornf	al, mask SIEN_MODEM
		jmp	setModem
disable:
		test	ds:[bx].SPD_mode, mask SF_HARDWARE
		jnz	done		; Leave modem ints on for hwfc
		andnf	al, not mask SIEN_MODEM
setModem:
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_ien
		mov	ds:[bx].SPD_ien, al
		out	dx, al
		jmp	doneOK
handOff:
	;
	; Hand off the call to the stream driver passing the proper stream.
	; Note that if the caller sets an error notifier for the writer,
	; it won't have any effect, since errors are posted only to the
	; input stream.
	;
		mov	si, ds:[bx].SPD_inStream	; Assume reader...
		test	ax, mask SNT_READER
		jnz	10$
		mov	si, ds:[bx].SPD_outStream
10$:
		mov	bx, si
		tst	bx
		stc
		jz	done
		call	StreamStrategy
doneOK:
		clc
done:
		.leave
		ret
SerialSetNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetNotificationEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads a StreamNotifier structure.

CALLED BY:	SerialSetNotify

PASS:		ax	= StreamNotifyType
		cx:dx	= address of handling routine, if SNM_ROUTINE;
			  destination of output if SNM_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA with
			  threshold of 1, in which case value is passed in CX);
			  method to send if SNM_MESSAGE.
		ds:si	= StreamNotifier to load

RETURN:		ax	= just the SN_type

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	5/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialSetNotificationEvent	proc	near
		.enter

		andnf	ax, mask SNT_HOW
		mov	ds:[si].SN_type, al
		mov	ds:[si].SN_dest.SND_routine.low, dx
		mov	ds:[si].SN_dest.SND_routine.high, cx
		mov	ds:[si].SN_data, bp

		.leave
		ret
SerialSetNotificationEvent	endp

Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for the serial driver's DR_STREAM_FLUSH.  If called
		for an active port, pass straight through to SerialHandOff.

		A passive port will call SerialHandOff to flush pending data,
		then reset the writer's SSD_ptr to SD_data.

CALLED BY:	DR_STREAM_FLUSH

PASS:		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		di	= function code
		ax	= STREAM_READ to apply only to reading
			  STREAM_WRITE to apply only to writing
			  STREAM_BOTH to apply to both (valid only for
			  DR_STREAM_FLUSH and DR_STREAM_SET_THRESHOLD)

RETURN:		nothing

DESTROYED:	bx (saved by SerialStrategy)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	6/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource

SerialFlush	proc	near
		.enter
	;
	; If this is an active port, jump straight to SerialHandOff.
	;
		test	ds:[bx].SPD_passive, mask SPS_PASSIVE
		jnz	handlePassive

		call	SerialHandOff
		jmp	exit

handlePassive:
		push	bx
		call	SerialHandOff
		pop	bx
		mov	bx, ds:[bx].SPD_inStream
		tst	bx			; Is there an input stream?
		jz	exit			; If not, leave.
	;
	; Reset the passive port's input stream pointer to the head of the
	; buffer.  Must change both reader and writer pointers because
	; they must be equal when the stream is empty!!
	;
		push	ds
		mov	ds, bx			; ds:0 <- StreamData
		mov	ds:SD_writer.SSD_ptr, offset SD_data
		mov	ds:SD_reader.SSD_ptr, offset SD_data
		pop	ds
exit:
		.leave
		ret
SerialFlush	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECVerifyReadWriteBothFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Make sure ax holds STREAM_READ, STREAM_WRITE or STREAM_BOTH

CALLED BY:	(INTERNAL)
PASS:		ax	= one of those
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	death if bad data

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECVerifyReadWriteBothFlag proc	near
		.enter
		cmp	ax, STREAM_READ
		je	notAHoser
		cmp	ax, STREAM_WRITE
		je	notAHoser
		cmp	ax, STREAM_BOTH
		je	notAHoser
		ERROR	AX_NOT_STREAM_WRITE_OR_STREAM_READ_OR_STREAM_BOTH
notAHoser:
		.leave
		ret
ECVerifyReadWriteBothFlag endp
endif
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialHandOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a call on to the stream driver for one or both of the
		streams associated with the port, passing the appropriate
		side for each.

CALLED BY:	DR_STREAM_GET_ERROR (STREAM_BOTH should *not* be given),
       		DR_STREAM_SET_ERROR, DR_STREAM_FLUSH, DR_STREAM_SET_THRESHOLD,
		DR_STREAM_QUERY
PASS:		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		di	= function code
		ax	= STREAM_READ to apply only to reading
			  STREAM_WRITE to apply only to writing
			  STREAM_BOTH to apply to both (valid only for
			  DR_STREAM_FLUSH and DR_STREAM_SET_THRESHOLD)
RETURN:		?
DESTROYED:	bx (saved by SerialStrategy)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialHandOff	proc	near
		.enter
CheckHack <(STREAM_WRITE AND 1) eq 0 and (STREAM_BOTH AND 1) eq 0 and (STREAM_BOTH lt 0) and (STREAM_READ lt 0) and (STREAM_READ AND 1) ne 0>
EC <		call	ECVerifyReadWriteBothFlag			>

	;
	; If this is a passive port, set ax to STREAM_READ only.
	;
		test	ds:[bx].SPD_passive, mask SPS_PASSIVE
		jz	testStreamSelection
EC <		push	si						>
EC <		mov	si, bx						>
EC <		call	ECSerialVerifyPassive				>
EC <		pop	si						>
		mov	ax, STREAM_READ
	;
	; If we're clearing out the buffer for the passive buffer,
	; clear the full buffer flag just to be sure.
	;
		cmp	di, DR_STREAM_FLUSH
		jne	testStreamSelection
		andnf	ds:[bx].SPD_passive, not (mask SPS_BUFFER_FULL)

testStreamSelection:
	;
	; See if output stream affected (STREAM_WRITE and STREAM_BOTH both have
	; the low bit 0)
	;
		test	ax, 1
		jnz	readOnly
		push	ax, bx, di
		mov	ax, STREAM_WRITE
		mov	bx, ds:[bx].SPD_outStream
		tst	bx
		jz	10$
		call	StreamStrategy
10$:
		pop	bx, di
		XchgTopStack	ax	; Preserve possible return value from
					;  function if STREAM_WRITE specified
		;
		; See if input also affected (STREAM_READ and STREAM_BOTH are
		; both < 0).
		;
		tst	ax
		pop	ax		; Recover possible result...
		jns	done
readOnly:
		mov	ax, STREAM_READ
		mov	bx, ds:[bx].SPD_inStream
		tst	bx
		jz	done
		call	StreamStrategy
done:
		.leave
		ret
SerialHandOff	endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from a port

CALLED BY:	DR_STREAM_READ
PASS:		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		cx	= number of bytes to read
		ds:si	= buffer to which to read
RETURN:		cx	= number of bytes read
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialRead	proc	near
		.enter
		mov	bx, ds:[bx].SPD_inStream
		tst	bx
		jz	noInputStream
		segmov	ds, es		; Restore ds from entry
		call	StreamStrategy
done:
		.leave
		ret
noInputStream:
		clr	cx
		stc
		jmp	done
SerialRead	endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single byte from a port

CALLED BY:	DR_STREAM_READ_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
RETURN:		al	= byte read
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialReadByte proc	near
		.enter
		mov	bx, ds:[bx].SPD_inStream
		tst	bx
		jz	noInputStream
		call	StreamStrategy
done:
		.leave
		ret
noInputStream:
		stc
		jmp	done
SerialReadByte endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a buffer to the serial port.

CALLED BY:	DR_STREAM_WRITE
PASS:		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		cx	= number of bytes to write
		es:si	= buffer from which to write (ds moved to es by
			  SerialStrategy)
		di	= DR_STREAM_WRITE
RETURN:		cx	= number of bytes written
DESTROYED:	bx (preserved by SerialStrategy)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialWrite	proc	near
		.enter
		mov	bx, ds:[bx].SPD_outStream
		tst	bx
		jz	noOutputStream
		segmov	ds, es		; ds <- buffer segment for
					;  stream driver
		call	StreamStrategy
done:
		.leave
		ret
noOutputStream:
		clr	cx
		stc
		jmp	done
SerialWrite	endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the serial port.

CALLED BY:	DR_STREAM_WRITE_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		bx	= unit number  (transformed to SerialPortData by
			  SerialStrategy)
		cl	= byte to write
		di	= DR_STREAM_WRITE_BYTE
RETURN:		carry set if byte could not be written and STREAM_NO_BLOCK
		was specified
DESTROYED:	bx (preserved by SerialStrategy)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialWriteByte proc	near
		.enter
		mov	bx, ds:[bx].SPD_outStream
		tst	bx
		jz	noOutputStream
		call	StreamStrategy
done:
		.leave
		ret
noOutputStream:
		stc
		jmp	done
SerialWriteByte endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetFormatPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set format for a PC-like serial port

CALLED BY:	SerialSetFormat

PASS:		al	= data format (SerialFormat)
		ah	= SerialMode
		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		cx	= baud rate (SerialBaud)

RETURN:		Void.

DESTROYED:	ax, cx, dx

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:
		If this is called on a preempted passive port, the
		hardware is not modified, only the curState for the
		passive port and the initState for the active port.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 3/93		Initial version.
	jdashe	5/26/94		passive support added

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialSetFormatPC	proc	near
		.enter
		mov	ds:[bx].SPD_curState.SPS_baud, cx
		mov	ds:[bx].SPD_curState.SPS_format, al

if 	_FUNKY_INFRARED
	;
	; For our funky infrared dongles, the DTR & RTS signals tell the
	; thing what baud rate we're using. If the medium is infrared, adjust
	; the modem control signals appropriately.
	;
		mov	dl, ds:[bx].SPD_curState.SPS_modem

		cmp	ds:[bx].SPD_medium.MET_manuf,
				MANUFACTURER_ID_GEOWORKS
		jne	setState
		cmp	ds:[bx].SPD_medium.MET_id, GMID_INFRARED
		jne	setState

		mov	dh, mask SMC_RTS
		cmp	cx, SB_9600
		je	modifyModem
		mov	dh, mask SMC_DTR
		cmp	cx, SB_19200
		je	modifyModem
		mov	dh, mask SMC_RTS or mask SMC_DTR
		cmp	cx, SB_115200
		jne	fail
modifyModem:
		andnf	dl, not (mask SMC_RTS or mask SMC_DTR)
		or	dl, dh
setState:
		mov	ds:[bx].SPD_curState.SPS_modem, dl
endif	; _FUNKY_INFRARED

		test	ds:[bx].SPD_passive, mask SPS_PREEMPTED
		jz	normalSet
	;
	; This is a preempted port.  Make the change in the port's
	; curState and in the active port's initState, so it'll take
	; effect when the preempted port regains control.
	;
EC <		xchg	bx, si						>
EC <		call	ECSerialVerifyPassive				>
EC <		xchg	bx, si						>
		mov	bx, ds:[bx].SPD_otherPortData

		call	SysEnterCritical
		mov	ds:[bx].SPD_initState.SPS_baud, cx
		mov	ds:[bx].SPD_initState.SPS_format, al
if 	_FUNKY_INFRARED
		mov	ds:[bx].SPD_initState.SPS_modem, dl
endif	; _FUNKY_INFRARED
		call	SysExitCritical

		mov	bx, ds:[bx].SPD_otherPortData
		jmp	done

normalSet:
	;
	; Establish the format right away while setting DLAB, allowing
	; us to store the new baud rate as well.
	;
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_lineCtrl
		ornf	al, mask SF_DLAB
		out	dx, al
	;
	; Stuff the new baud rate in its two pieces.
	;
		sub	dx, offset SP_lineCtrl - offset SP_divLow
		xchg	ax, cx
		out	dx, al
		inc	dx
		mov	al, ah
		out	dx, al
	;
	; Restore the data format and stuff it again after clearing DLAB (this
	; is also a nice, painless way to make sure the user passing us DLAB
	; set causes us no problems).
	;
		xchg	cx, ax
		andnf	al, not mask SF_DLAB
		add	dx, offset SP_lineCtrl - offset SP_divHigh
		out	dx, al
if 	_FUNKY_INFRARED
	;
	; Set modem control signals for IR baud rate
	;
		mov	al, ds:[bx].SPD_curState.SPS_modem
		sub	dx, offset SP_modemCtrl - offset SP_lineCtrl
		out	dx, al
endif	; _FUNKY_INFRARED
done:
		clc
exit::
		.leave
		ret
if 	_FUNKY_INFRARED
fail:
		mov	ax, STREAM_UNSUPPORTED_FORMAT
		stc
		jmp	exit
endif 	; _FUNKY_INFRARED
SerialSetFormatPC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the data format and baud rate and mode for a port

CALLED BY:	DR_SERIAL_SET_FORMAT
PASS:		al	= data format (SerialFormat)
		ah	= SerialMode
		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		cx	= baud rate (SerialBaud)
RETURN:		carry set if passed an invalid format
DESTROYED:	ax, cx, bx (preserved by SerialStrategy)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialSetFormat	proc	near	uses dx
		.enter
		INT_OFF
		call	SerialSetFormatPC
		jc	done
	;
	; Adjust for the passed mode.
	; dl <- SerialFlow with SF_SOFTWARE adjusted properly
	; dh <- byte mask for input bytes (0x7f or 0xff)
	;
		mov	dl, ds:[bx].SPD_mode
		ornf	dl, mask SF_SOFTWARE
		mov	dh, 0x7f		; dl, dh <- assume cooked
		cmp	ah, SM_RARE
			CheckHack <SM_COOKED gt SM_RARE>
		ja	haveMode		; => is cooked

		mov	dh, 0xff		; else set 8-bit data input
			CheckHack <SM_RAW lt SM_RARE>
		je	haveMode
    	;
	; RAW mode -- turn off all aspects of software flow-control
	;
		andnf	dl, not (mask SF_SOFTWARE or mask SF_XON or \
				mask SF_XOFF or mask SF_SOFTSTOP)
		test	dl, mask SF_HARDWARE
		jnz	haveMode
	;
	; raw mode with no hardware flow control, so no flow control at all
	; ( save some cycles in SerialInt or MiniSerialInt code )
	;
		andnf	dl, not (mask SF_OUTPUT or mask SF_INPUT)
haveMode:
		mov	ds:[bx].SPD_byteMask, dh
		call	SerialAdjustFCCommon
done:
		INT_ON
		.leave
		ret

SerialSetFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialAdjustFCCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have a new SerialFlow record that may have turned off
		output flowcontrol, and therefore overridden a hard or
		soft stop. Set the new mode and reenable transmission if
		there was a change.

CALLED BY:	(INTERNAL) SerialSetFormat, SerialSetFlowControl,
			   SerialEnableFlowControl
PASS:		ds:bx	= SerialPortData
		dl	= SerialFlow to set
		interrupts *OFF*
RETURN:		carry clear
		interrupts *ON*
DESTROYED:	dx, ax
SIDE EFFECTS:	SPD_mode set, transmit interrupt may be set in SPD_ien

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialAdjustFCCommon proc near
		.enter
	;
	; Set the new mode and get the mask of bits that have changed.
	;
		mov_tr	ax, dx
		xchg	ds:[bx].SPD_mode, al
		xor	al, ds:[bx].SPD_mode
if NEW_ISR
	;
	; if any flow control is set, switch to flow control version of
	; interrupt handlers.  If flow control is cleared, switch to fast
	; non-flow control version of interrupt handlers.
	;
		test	ds:[bx].SPD_mode, mask SF_SOFTWARE or \
					  mask SF_HARDWARE
		jz	noFc
		mov	ds:[bx].SPD_handlers, offset FcHandlerTbl
		jmp	cont
noFc:
		mov	ds:[bx].SPD_handlers, offset QuickHandlerTbl
cont:
endif	; NEW_ISR

	;
	; al = mask of SerialFlow bits that changed.
	;
		test	al, mask SF_SOFTSTOP or mask SF_HARDSTOP
		jnz	newIEN
	;
	; If hardware flow-control changed, we want to tweak the hardware,
	; in case the modem-status interrupt has been enabled or disabled.
	;
		test	al, mask SF_HARDWARE
		jz	done
newIEN:
	;
	; If preempted passive, don't tweak the hardware.
	;
		test	ds:[bx].SPD_passive, mask SPS_PREEMPTED
		jnz	done
	;
	; We enable transmit always, even if it was just a change in the
	; HWFC, but not in the softstop/hardstop flags, as it's smaller
	; codewise and does everything we need to do when we do need to turn
	; on the transmitter. In the case where we're just changing the
	; modem interrupt, this yields an extra interrupt, but it will find
	; the output stream empty, and no harm will be done.
	;
		call	SerialEnableTransmit
done:
		INT_ON
		clc
		.leave
		ret
SerialAdjustFCCommon endp
Resident	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetFormatPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get format for a PC-like serial port

CALLED BY:	SerialGetFormat

PASS:		ds:bx = SerialPortData

RETURN:		al	= SerialFormat
		cx	= SerialBaud

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 3/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment

SerialGetFormatPC proc	near
		.enter

		mov	al, ds:[bx].SPD_curState.SPS_format
		mov	cx, ds:[bx].SPD_curState.SPS_baud

		.leave
		ret
SerialGetFormatPC endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current format parameters for the port

CALLED BY:	DR_SERIAL_GET_FORMAT
PASS:		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
RETURN:		al	= SerialFormat
		ah	= SerialMode
		cx	= SerialBaud
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialGetFormat	proc	near	uses dx
		.enter
		INT_OFF
	;
	; Compute the current mode based on the SF_SOFTWARE and byteMask
	; settings.
	;
		mov	ah, SM_RAW
		test	ds:[bx].SPD_mode, mask SF_SOFTWARE
		jz	haveMode
			CheckHack <SM_RARE eq SM_RAW+1>
		inc	ah
		cmp	ds:[bx].SPD_byteMask, 0xff
		je	haveMode
			CheckHack <SM_COOKED eq SM_RARE+1>
		inc	ah
haveMode:
		;
		; Fetch the pieces of the current baud divisor into cx
		;
if	STANDARD_PC_HARDWARE
		call	SerialGetFormatPC
endif	; STANDARD_PC_HARDWARE

		INT_ON
		.leave
		ret
SerialGetFormat endp
Resident	ends

if LOG_MODEM_SETTINGS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialLogModemSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the SerialModem settings to the log file

CALLED BY:	(Internal) SerialSetModem
PASS:		al	= SerialModem
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment

SBCS <	serialModemString	char	"RI,DCD,CTS,DSR = 0,0,0,0",0	>
DBCS <	serialModemString	wchar	"RI,DCD,CTS,DSR = 0,0,0,0",0	>

SerialLogModemSettings	proc	near
		uses	ax,cx,si,di,ds,es
		.enter
	;
	; Copy string template to the stack
	;
		mov	cx, cs
		segmov	ds, cx
		mov	si, offset serialModemString	; ds:si = string

		sub	sp, size serialModemString
		mov	cx, ss
		segmov	es, cx
		mov	di, sp				; es:di = target

		LocalCopyString SAVE_REGS		; copy to stack
	;
	; Loop to set up the string
	;
		mov	si, di				; si = offset to start
SBCS <		add	di, size serialModemString-2	; idx to last 0	>
DBCS <		add	di, size serialModemString-4			>
		mov	cx, 4				; # bits to set
loopTop:
		shr	ax, 1				; LSB in carry
		jnc	notSet
SBCS <		mov	{byte} es:[di], '1'				>
DBCS <		mov	{word} es:[di], '1'				>
notSet:
SBCS <		dec	di						>
SBCS <		dec	di				; previous zero >
DBCS <		sub	di, 4						>
		loop	loopTop				; do the rest

		segmov	ds, es, ax			; ds:si = final string
		call	LogWriteEntry			; write the string

		add	sp, size serialModemString

		.leave
		ret
SerialLogModemSettings	endp
Resident	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the modem-control bits for a port

CALLED BY:	DR_SERIAL_SET_MODEM
PASS:		al	= modem control bits (SerialModem). SMC_OUT2 is
			  silently forced high.
		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
RETURN:		Nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/90		Initial version
	jdashe	5/26/94		added passive support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment

SerialSetModem	proc	near	uses dx
		.enter
EC <		test	al, not SerialModem				>
EC <		ERROR_NZ	BAD_MODEM_FLAGS				>

if LOG_MODEM_SETTINGS
		call	SerialLogModemSettings
endif
	;
	; If this is a preempted port, set the modem-contol bits in
	; curState and in the active port's initState, then leave
	; without modifying the hardware.
	;
		test	ds:[bx].SPD_passive, mask SPS_PREEMPTED
		jz	notPreempted
EC <		xchg	bx, si						>
EC <		call	ECSerialVerifyPassive				>
EC <		xchg	bx, si						>
		ornf	al, mask SMC_OUT2
		mov	bx, ds:[bx].SPD_otherPortData
		mov	ds:[bx].SPD_initState.SPS_modem, al
		mov	bx, ds:[bx].SPD_otherPortData
		jmp	done

notPreempted:
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_modemCtrl
		ornf	al, mask SMC_OUT2
		out	dx, al
	;
	; 4/28/94: wait 3 clock ticks here to allow things to react to
	; having DTR asserted. In particular, this is here to allow a
	; serial -> parallel converter manufactured by GDT Softworks to
	; power up -- ardeb
	;
checkDTR::
		mov	ds:[bx].SPD_curState.SPS_modem, al
		test	al, mask SMC_DTR
		jz	done
		mov	ax, 3
		call	TimerSleep
done:
		.leave
		ret
SerialSetModem	endp
Resident	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the modem-control bits for a port

CALLED BY:	DR_SERIAL_GET_MODEM
PASS:		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
RETURN:		al	= modem control bits (SerialModem).
DESTROYED:	ax

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialGetModem	proc	near	uses dx
		.enter
	;
	; If this is a preempted port, grab the modem control bits
	; from the curState rather than from the hardware (we
	; don't have control of the hardware, after all).
	;
		test	ds:[bx].SPD_passive, mask SPS_PREEMPTED
		jz	notPreempted
EC <		xchg	bx, si						>
EC <		call	ECSerialVerifyPassive				>
EC <		xchg	bx, si						>
		mov	al, ds:[bx].SPD_curState.SPS_modem
		jmp	gotModem

notPreempted:
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_modemCtrl
		in	al, dx
gotModem:
; deal with non-existent port being enabled by masking out all but the
; real modem bits, preventing BAD_MODEM_FLAGS in EC version when caller
; attempts to restore the original modem flags...
EC <		andnf	al, SerialModem					>
		.leave
		ret
SerialGetModem	endp
Resident	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the flow-control used by a port

CALLED BY:	DR_SERIAL_SET_FLOW_CONTROL
PASS:		ax	= SerialFlowControl record describing what method(s)
			  of control to use
		bx	= unit number (transformed to SerialPortData by
			  SerialStrategy)
		cl	= signal(s) to use to tell remote to stop sending
			  (SerialModem) if de-asserted
		ch	= signal(s) whose de-assertion indicates we should
			  stop sending (one or more of SMS_DCD, SMS_DSR
			  or SMS_CTS). If more than one signal is given, the
			  dropping of any will cause output to stop until
			  all signals are high again.
RETURN:		Nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialSetFlowControl proc near
		uses	dx
		.enter

		INT_OFF

EC <		test	ax, not SerialFlowControl			>
EC <		ERROR_NZ	BAD_FLOW_CONTROL_FLAGS			>

		mov	dl, ds:[bx].SPD_mode

		; for Zoomer, we are not allowing Hardware Handshaking,
		; due to the way the hardware was designed (cannot be interrupt
		; driven as the modem signals are wire-or'ed to be the IRQ
		; line, meaning the thing keeps interrupting as long as the
		; other side has the signal dropped)
		test	al, mask SFC_SOFTWARE
		jz	clearSWFC
		ornf	dl, mask SF_SOFTWARE
		jmp	checkHWFC
clearSWFC:
		andnf	dl, not (mask SF_SOFTWARE or mask SF_XON or \
			         mask SF_XOFF or mask SF_SOFTSTOP)

checkHWFC:
		test	al, mask SFC_HARDWARE
		jz	clearHWFC
		ornf	dl, mask SF_HARDWARE
EC <		test	cl, not (mask SMC_RTS or mask SMC_DTR)		>
EC <		ERROR_NZ 	BAD_FLOW_CONTROL_FLAGS			>
EC <		test	ch, not (mask SMS_CTS or mask SMS_DCD or mask SMS_DSR)>
EC <		ERROR_NZ	BAD_FLOW_CONTROL_FLAGS			>
		mov	ds:[bx].SPD_stopCtrl, cl
		mov	ds:[bx].SPD_stopSignal, ch
		; SIEN_MODEM IS THE SAME AS ZSIEN_MODEM SO NO NEED TO CHECK
		; WHICH PORT IN ZOOMER CODE
		ornf	ds:[bx].SPD_ien, mask SIEN_MODEM
done:
	;
	; Adjust the port's interrupt-enable register to match what we want
	; dl = SerialFlow to set
	;
		call	SerialAdjustFCCommon
		.leave
		ret
clearHWFC:
		andnf	dl, not (mask SF_HARDWARE or mask SF_HARDSTOP)
		tst	ds:[bx].SPD_modemEvent.SN_type
		jnz	done		; Modem event registered -- leave modem
					;  status interrupt enabled.

		; SIEN_MODEM IS THE SAME AS ZSIEN_MODEM SO NO NEED TO CHECK
		; WHICH PORT IN ZOOMER CODE
		andnf	ds:[bx].SPD_ien, not mask SIEN_MODEM
		jmp	done
SerialSetFlowControl endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnableFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set whether flow control is enabled for either or both
		sides of the serial port.

CALLED BY:	DR_SERIAL_ENABLE_FLOW_CONTROL
PASS:		ax	= STREAM_READ/STREAM_WRITE/STREAM_BOTH
		bx	= unit
RETURN:		carry set on error:
			ax	= STREAM_NO_DEVICE
				= STREAM_CLOSED
		carry clear if ok:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialEnableFlowControl		proc	near
		uses	dx
		.enter
EC <		call	ECVerifyReadWriteBothFlag			>

		INT_OFF
	;
	; Assume enabling flow control for both sides.
	;
		mov	dl, ds:[bx].SPD_mode
		ornf	dl, mask SF_INPUT or mask SF_OUTPUT
			CheckHack <(STREAM_WRITE and 1) eq 0>
			CheckHack <(STREAM_BOTH and 1) eq 0>
		test	ax, 1
		jz	checkInput
	;
	; Disabling flow control for output. This means we clear SF_OUTPUT
	; and also clear SF_SOFTSTOP and SF_HARDSTOP as we are no longer
	; constrained not to transmit.
	;
		andnf	dl, not (mask SF_OUTPUT or mask SF_SOFTSTOP or \
				mask SF_HARDSTOP)
checkInput:
			CheckHack <(STREAM_READ and 0x8000) eq 0x8000>
			CheckHack <(STREAM_BOTH and 0x8000) eq 0x8000

		tst	ax
		js	setMode
	;
	; Disabling flow control for input. This means we clear SF_INPUT
	; and also clear SF_XOFF and SF_XON flags (we clear SF_XON to
	; ensure consistent behaviour: if the stream hadn't yet drained to
	; the low water mark, we would not send an XON when the thing got
	; there, so we shouldn't allow one to be sent on the next interrupt
	; either; once you disable input flow control, you don't get an
	; XON or XOFF generated, period)
	;
		andnf	dl, not (mask SF_INPUT or mask SF_XOFF or mask SF_XON)
setMode:
		call	SerialAdjustFCCommon

		.leave
		ret
SerialEnableFlowControl		endp
Resident	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetRole
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the role of the driver (either DCE or DTE)

CALLED BY:	DR_SERIAL_SET_ROLE
PASS:		al	= SerialRole
		bx	= unit number
RETURN:		carry set on error
		carry clear if ok
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

This doesn't do anything for the serial driver, but the API needed to
be defined here so that it could be used in IrCOMM.  If the serial
driver is ever to be used as a DCE, this routine will need to set the
state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialSetRole	proc	near
	clc
	ret
SerialSetRole	endp
Resident	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetDeviceMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the map of existing stream devices for this driver

CALLED BY:	DR_STREAM_GET_DEVICE_MAP
PASS:		ds	= dgroup (from SerialStrategy)
RETURN:		ax	= SerialDeviceMap
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialGetDeviceMap proc	near
		.enter
		mov	ax, ds:[deviceMap]
		.leave
		ret
SerialGetDeviceMap endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDefinePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define an additional port for the driver to handle.

CALLED BY:	DR_SERIAL_DEFINE_PORT
PASS:		ax	= base I/O port of device
		cl	= interrupt level for device
RETURN:		bx	= unit number for later calls.
		carry set if port couldn't be defined (no interrupt vectors
		available, e.g.)
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefStub	SerialDefinePort

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStatPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check on the status of a serial port. (Must be Resident
		for PCMCIA support)

CALLED BY:	DR_SERIAL_STAT_PORT
PASS:		bx	= unit number (SerialPortNum)
RETURN:		carry set if port doesn't exist
		carry clear if port is known:
			al	= interrupt level (-1 => unknown)
			ah	= BB_TRUE if port is currently open
DESTROYED:	nothing (interrupts turned on)

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialStatPort	proc	near	uses bx
		.enter
		call	SerialGetPortData	; ds:bx <- SerialPortData
		INT_OFF
		tst	ds:[bx].SPD_base
		jz	nonExistent
		mov	al, ds:[bx].SPD_irq
		clr	ah		; assume not open
		push	bx
		mov	bx, ds:[bx].SPD_openSem
		tst	ds:[bx].Sem_value	; (clears carry)
		pop	bx
		jg	done
		dec	ah
done:
		INT_ON
		.leave
		ret
nonExistent:
		stc
		jmp	done
SerialStatPort	endp

Resident	ends

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetPassiveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the status of a passive port.

CALLED BY:	DR_SERIAL_GET_PASSIVE_STATE

PASS:		bx	= Serial unit number

RETURN:		carry clear if the port exists and is available for passive use
		carry set otherwise, and:
			ax	= STREAM_NO_DEVICE if the indicated unit
				  doesn't exist.
				= STREAM_ACTIVE_IN_USE if the unit is
				  actively allocated, which means that
				  a passive allocation is allowed (but
				  will immediately block).
				= STREAM_PASSIVE_IN_USE if the unit is
				  currently passively allocated.  An attempted
				  SerialOpen will be unsuccessful.
				  If ax = STREAM_PASSIVE_IN_USE, check
				  cl for more details.
				  cl	= SerialPassiveStatus for the open
					  port, with SPS_PREEMPTED and
					  SPS_BUFFER_FULL set as appropriate.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment
SerialGetPassiveState	proc	near
		uses	bx

		.enter
		call	SerialGetPortData		; bx <- port data offset

EC <		xchg	si, bx						>
EC <		call	ECSerialVerifyPassive				>
EC <		xchg	si, bx						>

		tst	ds:[bx].SPD_base
		jnz	checkPassiveInUse
		mov	ax, STREAM_NO_DEVICE
		jmp	error

checkPassiveInUse:
		mov	cl, ds:[bx].SPD_passive

		IsPortOpen bx
		jg	portNotOpen
		mov	ax, STREAM_PASSIVE_IN_USE
		jmp	error

portNotOpen:
		mov	bx, ds:[bx].SPD_otherPortData
		IsPortOpen bx
		mov	bx, ds:[bx].SPD_otherPortData
		jg	activeNotOpen
		mov	ax, STREAM_ACTIVE_IN_USE
		jmp	error

activeNotOpen:
		clc
		jmp	exit
error:
		stc
exit:
		.leave
		ret
SerialGetPassiveState	endp

Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSerialVerifyPassive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the passed offset points to a passive port's
		SerialPortData structure rather than to an active port's.

PASS:		ds:si - pointer to the port's data structure

RETURN:		The Z flag set.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
Resident	segment
ECSerialVerifyPassive	proc	far
		.enter
	;
	; Passive ports are not yet available for the Zoomer.
	;

if	STANDARD_PC_HARDWARE

	;
	; See if it's one of the passive ports...
	;
		push	es, di, cx
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
;		segmov	es, dgroup, di
		mov	di, offset comPortsPassive
		mov	cx, length comPortsPassive
		xchg	ax, si
		repne	scasw
		xchg	ax, si
		pop	es, di, cx
		ERROR_NE	INVALID_PORT_DATA_OFFSET
	;
	; It's in the right place.  Make sure the passive bit is set.
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		ERROR_Z	NOT_A_PASSIVE_PORT

		cmp	si, si			; cheesy way to set Z...
endif	; STANDARD_PC_HARDWARE

		.leave
		ret
ECSerialVerifyPassive	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSerialVerifyActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the passed offset points to an active port's
		SerialPortData structure rather than to a passive port's.

PASS:		ds:si - pointer to the port's data structure

RETURN:		The Z flag clear.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Hackish.  The code assumes the passive port structure
		definitions are placed after the active ones.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECSerialVerifyActive	proc	far
		.enter
	;
	; Make sure the thing is a port at all.
	;
		cmp	si, offset com1
		ERROR_B	INVALID_PORT_DATA_OFFSET
		cmp	si, LAST_ACTIVE_SERIAL_COMPORT
		ERROR_A	NOT_AN_ACTIVE_PORT	; It's something else.
	;
	; It's in the right place.  Make sure the passive bit is clear.
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		ERROR_NZ NOT_AN_ACTIVE_PORT

		.leave
		ret
ECSerialVerifyActive	endp

Resident	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the medium bound to a particular port

CALLED BY:	DR_SERIAL_GET_MEDIUM
PASS:		bx	= unit number (SerialPortNum)
		cx	= medium # to fetch (0 == primary)
RETURN:		carry set on error:
			ax	= STREAM_NO_DEVICE
		carry clear if ok:
			dxax	= MediumType (medium.def)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource
SerialGetMedium	proc	near
		.enter
		Assert	l, cx, SERIAL_MAX_MEDIA
		and	bx, not SERIAL_PASSIVE	; ignore passive bit -- data
						;  set only on the active
		call	SerialGetPortData
		tst_clc	ds:[bx].SPD_base
		jz	honk
			CheckHack <size MediumType eq 4>
		mov	ax, cx
		shl	ax
		shl	ax
		add	bx, ax			; offset bx by index into
						; SPD_medium so next thing
						; fetches the right medium out
		movdw	dxax, ds:[bx].SPD_medium

		mov	bx, ax
		or	bx, dx
		jz	noMedium		; => nothing in that slot
done:
		.leave
		ret
honk:
		mov	ax, STREAM_NO_DEVICE
error:
		stc
		jmp	done

noMedium:
		mov	ax, STREAM_NO_SUCH_MEDIUM
		jmp	error
SerialGetMedium	endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Specify the medium for a particular port.

CALLED BY:	DR_SERIAL_SET_MEDIUM
PASS:		bx	= unit number (SerialPortNum)
		ds	= serialData segment (from SerialStrategy)
		dx:ax	= array of MediumTypes to bind to the port
		cx	= # of MediumTypes to bind to it
RETURN:		carry set on error:
			ax	= STREAM_NO_DEVICE
		carry clear if ok:
			ax	= destroyed
DESTROYED:	nothing (bx, but that's saved by the caller)
SIDE EFFECTS:	if port had medium bound, MESN_MEDIUM_NOT_AVAILABLE generated
     			for it
		MESN_MEDIUM_AVAILABLE generated for new medium

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource
SerialSetMedium	proc	near
		uses	cx, dx, si, di
		.enter
	;
	; Point to the port data and make sure it exists.
	;
		and	bx, not SERIAL_PASSIVE	; ignore passive bit -- data
						;  set only on the active
		mov	si, bx
		call	SerialGetPortData
		tst	ds:[bx].SPD_base
		jz	honk
	;
	; First let the world know the currently bound media are gone, before
	; we overwrite the info.
	;
		push	si			; save port #
		push	dx, ax
		mov	di, MESN_MEDIUM_NOT_AVAILABLE
		call	SerialNotifyMedia
	;
	; Move the new media into the port data.
	;
		segmov	es, ds
		lea	di, ds:[bx].SPD_medium
		pop	ds, si
		Assert	le, cx, SERIAL_MAX_MEDIA
			CheckHack <size MediumType eq 4>
		shl	cx
		mov	dx, SERIAL_MAX_MEDIA * 2
		sub	dx, cx			; dx <- # words to zero
		push	si, cx, dx
		rep	movsw
		mov	cx, dx
		clr	ax
		rep	stosw			; mark the rest of the array
						;  invalid
	;
	; Now do the same for the passive port, please.
	;
		pop	si, cx, dx
		mov	di, es:[bx].SPD_otherPortData
		add	di, offset SPD_medium
		rep	movsw
		mov	cx, dx
		rep	stosw
	;
	; Let the world know the thing exists.
	;
		pop	si			; si <- port #
		segmov	ds, es			; ds:bx <- SPD

		mov	di, MESN_MEDIUM_AVAILABLE
		call	SerialNotifyMedia
		clc
done:
		.leave
		ret

honk:
		mov	ax, STREAM_NO_DEVICE
		stc
		jmp	done
SerialSetMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialNotifyMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification for each of the Media types bound to a port.

CALLED BY:	(INTERNAL) SerialSetMedium
PASS:		ds:bx	= SerialPortData with SPD_medium set
		si	= SerialPortNum
		di	= MediumSubsystemNotification to send
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialNotifyMedia proc	near
		uses	si, bx, cx
		.enter
		add	bx, offset SPD_medium
		xchg	bx, si			; bx <- unit #
						; ds:si <- array
		mov	cx, SERIAL_MAX_MEDIA	; cx <- # media to check
mediumLoop:
	;
	; Fetch the next medium out of the array.
	;
		push	cx
		lodsw
		mov_tr	dx, ax			; dx <- low word
		lodsw
		mov	cx, ax			; cxdx <- MediumType
		or	ax, dx
		jz	loopDone		; => GMID_INVALID, so done
	;
	; Send notification out for the medium.
	;
		mov	al, MUT_INT
		push	si
		mov	si, SST_MEDIUM
		call	SysSendNotification
		pop	si			; ds:si <- next medium entry
		pop	cx			; cx <- loop counter
		loop	mediumLoop
done:
		.leave
		ret
loopDone:
		pop	cx
		jmp	done

SerialNotifyMedia endp

SerialSetMediumFAR proc far	; for SerialLookForMedium & SerialDefinePort to
				;  use
		push	bx
		call	SerialSetMedium
		pop	bx
		ret
SerialSetMediumFAR endp

Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetBufferSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the size of an open stream's buffers.

CALLED BY:	DR_SERIAL_SET_BUFFER_SIZE
PASS:		ax	= STREAM_READ/STREAM_WRITE
		bx	= unit #
		cx	= new size
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	if new size smaller than actual number of bytes, most recent
     			bytes will be discarded.

PSEUDO CODE/STRATEGY:
		fetch & 0 the stream pointer for the appropriate side
		compute new stream size
		if too small to hold current # bytes, drop enough to leave
			stream full
		if shrinking & data wraps, move bytes down so last byte in
			current buffer is before new SD_max. there must
			be enough room in the buffer to do this without
			overwriting anything vital, because of the size
			adjusting we did in the previous step. set
			SD_reader.SSD_ptr accordingly
		MemRealloc the stream
		if growing & data wraps, move data in last part of buffer up
			to reach new SD_max
		adjust SD_writer.SSD_sem.Sem_value by size difference
		store new stream pointer back in appropriate side

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefStub	SerialSetBufferSize

OpenClose	segment
SerialSetBufferSize proc	far
		.enter
	;
	; Figure which variable holds the stream pointer, based on what
	; we were passed.
	;
		mov	si, offset SPD_inStream
		cmp	ax, STREAM_READ
		je	haveStreamOffset
EC <		cmp	ax, STREAM_WRITE				>
EC <		ERROR_NE MUST_SPECIFY_READER_OR_WRITER			>
		mov	si, offset SPD_outStream
haveStreamOffset:
	;
	; Make sure the new buffer size isn't too large.
	;
		cmp	cx, STREAM_MAX_STREAM_SIZE
		jb	bufferSizeOk
		mov	ax, STREAM_BUFFER_TOO_LARGE
		stc
		jmp	done

bufferSizeOk:
	;
	; Fetch the current stream out of the port and set the stream
	; pointer to 0 for the duration. This will cause data to get dropped
	; on the floor, etc., but that's fine by us.
	;
		push	bx, si, ds
		clr	ax
		xchg	ax, ds:[bx][si]
		tst	ax
		jz	errBusy			; => no stream, so someone else
						;  must be doing something
	;
	; If we're not the only thread actively messing with this port, claim
	; the thing is busy and do nothing.
	;
		cmp	ds:[bx].SPD_refCount, 2
		jne	errBusy			; => another thread is doing
						;  stuff in here and might
						;  be dicking with this stream
	;
	; Figure how big to make the new stream buffer.
	;
		mov	ds, ax			; ds <- stream
		mov	dx, ds:[SD_max]		; dx <- old size
		add	cx, size StreamData	; cx <- new size
	;
	; Shift the data around to account for any shrinkage we're about to
	; perform.
	;
		call	SerialAdjustForShrinkage
	;
	; Resize the stream block, please.
	;
		mov	bx, ds:[SD_handle]
		push	cx
		mov_tr	ax, cx			; ax <- new size
		clr	cx
		call	MemReAlloc
		pop	cx			; cx <- new size
		jc	allocErr
	;
	; Shift the data around to account for any enlargement we just
	; performed.
	;
		mov	ds, ax			; ds <- stream, again
		call	SerialAdjustForGrowth
	;
	; All the new space or the lost old space come from the writer's side,
	; as the data in the stream remain constant.
	;
		sub	cx, dx			; cx <- size difference
		Assert	ge, ds:[SD_writer].SSD_sem.Sem_value, 0
		add	ds:[SD_writer].SSD_sem.Sem_value, cx
	;
	; The max value for the stream data pointer gets adjusted by the
	; same amount, please.
	;
		add	ds:[SD_max], cx
		clc
		mov	ax, ds			; ax <- stream, for restoration
replaceStream:
	;
	; Restore the stream pointer in the SerialPortData
	;
		pop	bx, si, ds
		mov	ds:[bx][si], ax
done:
		.leave
		ret

allocErr:
		xchg	cx, dx			; cx <- old size, dx <- new
		call	SerialAdjustForGrowth	;  so we can pretend the stream
						;  grew to its old size and
						;  undo the work of
						;  SerialAdjustForShrinkage
		mov	ax, ds
		mov	cx, STREAM_CANNOT_ALLOC
		stc
		jmp	replaceStream

errBusy:
		mov	cx, STREAM_BUSY
		stc
		jmp	replaceStream
SerialSetBufferSize endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialAdjustForShrinkage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard enough data to make it fit in the new size, then
		shift data down from the end of the buffer to fit under
		the new limit

CALLED BY:	(INTERNAL) SerialSetBufferSize
PASS:		ds	= stream being shrunk
		dx	= old size
		cx	= new size
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	data in the buffer shifted to be below the new max

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialAdjustForShrinkage proc	near
		uses	cx, si, di, es
		.enter
		mov	ax, cx
		sub	ax, size StreamData
		sub	ax, ds:[SD_reader].SSD_sem.Sem_value
		jge	bytesWillFit
	;
	; Too many bytes in the stream. Scale back the SSD_sem and advance the
	; SSD_ptr for the reader. We adjust the SD_writer.SSD_sem to account
	; for the scaling back that'll happen in SerialSetBufferSize itself
	; once all is said and done (and in case of error, too...).
	;
		add	ds:[SD_reader].SSD_sem.Sem_value, ax

		neg	ax
		add	ds:[SD_writer].SSD_sem.Sem_value, ax
		add	ax, ds:[SD_reader].SSD_ptr

		cmp	ax, ds:[SD_max]		; wrap around end?
		jb	setReaderPtr		; no
		sub	ax, ds:[SD_max]		; ax <- amount of wrap
		add	ax, offset SD_data	; ax <- new pointer

setReaderPtr:
		mov	ds:[SD_reader].SSD_ptr, ax

bytesWillFit:
	;
	; There is now room for all the bytes in the new world order. See
	; if we need to move any data down from the end of the buffer.
	; Note that if the two SSD_ptrs are equal, it either means the buffer
	; is empty (in which case we need only shift stuff down to the bottom
	; of the buffer) or the buffer is full, which means we're not actually
	; shrinking (else we would have thrown away some bytes, above...).
	;
		segmov	es, ds			; for moving
		mov	ax, ds:[SD_writer].SSD_ptr
		cmp	ax, ds:[SD_reader].SSD_ptr
		jae	noWrap			; => contiguous or empty
	;
	; Data wraps around the end of the buffer. If we're actually shrinking,
	; we have to shift that data down by the size difference.
	;
		sub	cx, dx
		jae	done			; => buffer growing, so don't
						;  care yet.

		mov	si, ds:[SD_reader].SSD_ptr
		mov	di, si
		add	di, cx			; di <- destination
		Assert	ae, di, ds:[SD_writer].SSD_ptr
		mov	ds:[SD_reader].SSD_ptr, di
		mov	cx, ds:[SD_max]
		sub	cx, si			; cx <- # bytes to move
		rep	movsb
		jmp	done

noWrap:
	;
	; Ok, the data is contiguous or the buffer is empty, but it (the data
	; or the pointers) might still be in the way.
	;
		cmp	ax, cx			; write pointer after new max?
		jbe	done			; => no so not in the way
	;
	; Is in the way. Just shift the whole thing down to the start of
	; the buffer. For an empty buffer, this moves nothing, but does set
	; the SSD_ptr variables to SD_data, which is where we want them.
	;
		mov	si, ds:[SD_reader].SSD_ptr
		mov	cx, ax			; cx <- write pointer
		sub	cx, si			; cx <- # bytes to move
		mov	di, offset SD_data	; es:di <- dest
		mov	ds:[SD_reader].SSD_ptr, di
		rep	movsb
		mov	ds:[SD_writer].SSD_ptr, di
done:
		.leave
		ret
SerialAdjustForShrinkage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialAdjustForGrowth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift any data at the end of the ring buffer up to be at the
		new end of the ring buffer.

CALLED BY:	(INTERNAL) SerialSetBufferSize
PASS:		ds	= stream affected
		cx	= new size
		dx	= old size
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialAdjustForGrowth proc	near
		uses	cx, si, di, es
		.enter
	;
	; If didn't grow, do nothing.
	;
		cmp	cx, dx
		jbe	done
	;
	; See if the data wrap around the end of the buffer. If they don't
	; then we have nothing to worry about, as the data can merrily reside
	; in the middle of the buffer contiguously without hurting anything.
	;
		segmov	es, ds
		mov	ax, ds:[SD_reader].SSD_ptr
		cmp	ax, ds:[SD_writer].SSD_ptr
		ja	wraps
		jb	done		; => doesn't wrap, so don't need to
					;  worry
	;
	; Either full (wraps) or empty (doesn't wrap). Don't have to worry about
	; < 0 case, as no one can be blocked on the thing, since we're the only
	; ones here...
	;
		tst	ds:[SD_reader].SSD_sem.Sem_value
		jz	done
wraps:
	;
	; Sigh. It wraps. Woe is me. Sniff.
	;
	; Must move the data up in the world from the old end to the new end.
	;
		mov	di, cx		; es:di <- new end+1
		mov	si, dx		; ds:si <- old end+1
		mov	cx, dx
		sub	cx, ax		; cx <- # bytes to move
		dec	di		; move to actual last byte
		dec	si		; from actual last byte
		std			; do that wacky decrement thing
		rep	movsb
		cld
	;
	; Point to the new position of the first byte for reading.
	;
		inc	di
		mov	ds:[SD_reader].SSD_ptr, di
done:
		.leave
		ret
SerialAdjustForGrowth endp

OpenClose	ends
