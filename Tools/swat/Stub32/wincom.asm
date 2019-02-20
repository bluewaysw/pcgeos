COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		wincom.asm

AUTHOR:		Ronald Braunstein, Sep 11, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/11/96   	Initial revision


DESCRIPTION:
		
	Code for doing communication via vdd in windows

	$Id: wincom.asm,v 1.2 96/10/25 19:35:44 ron Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_WinCom		= 1
		include	stub.def
ifdef WINCOM

scode	segment

DllName DB      "STUBDLL.DLL",0
InitFunc  DB    "VDDRegisterInit32",0
DispFunc  DB    "VDDDispatch",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Emulate int21h/ah=MSDOS_DISPLAY_STRING.

CALLED BY:	some stuff below
PASS:		ds:dx = string
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		It seems NTVDM DPMI doesn't emulate that particular
		function, so we do it ourselves.  Luckily, it does
		handle the charout BIOS call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 	12/06/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayString	proc near
		uses	si
		.enter
		mov	si, dx
ploop:
		lodsb
		cmp	al, '$'
		je	done
		mov	ah, 0xe
		int	10h
		jmp	ploop
done:
		.leave
		ret
DisplayString	endp
		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCom_ReadMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the waiting message, if any

CALLED BY:	(EXTERNAL) Rpc_Wait
PASS:		es:di	= place to store message
		ds	= cgroup
		cx	= size of buffer
RETURN:		carry set if message was corrupt
		carry clear if message was ok:
			cx	= size of message
				= 0 if no message present
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/11/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinCom_ReadMsg proc	near
		uses	si, bx, dx
		.enter
	;
	; This is a good time to let IPX do some processing.
	; 
	;
	; See if there's a packet available.
	;
		mov	dx, cx			; size of buffer 
		mov	bx, VDD_FUNC_TEST_FOR_READ
		call	CallVDD
		clc
		jcxz	done
getMessage::
	DPC DEBUG_COM_INPUT, 'R'
	;
	; Resubmit the ECB for receiving the next packet.
	; 
	DA  DEBUG_COM_INPUT, <push ax>
	DPC DEBUG_COM_INPUT, 'c'
	DA  DEBUG_COM_INPUT, <pop ax>
		mov_tr	cx, dx			; size of buffer
		mov	bx, VDD_FUNC_READ_INTO_BUFFER
		call	CallVDD

if DEBUG and DEBUG_COM_INPUT
		push	cx, di
again:
		mov	al, es:[di]
		inc	di
		call	DebugPrintByte
		loop	again
		pop	cx, di
endif
done:
		.leave
		ret
WinCom_ReadMsg endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCom_WriteMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the passed data to the place from which the most
		recent packet was received.

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= buffer to write
		cx	= # bytes in the buffer
RETURN:		nothing
DESTROYED:	si, cx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/11/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinCom_WriteMsg proc	near
		uses	es, di, bx, ds, dx, bp
		.enter
		PointESAtStub
		
	DPC DEBUG_COM_OUTPUT, 'w'
	DPW DEBUG_COM_OUTPUT, cx

	;
	; Wait for the previous packet we sent to actually get out the door.
	; 
		;; Don't bother, it will get ordered for us.
	;
	; Make sure there's not too much data for our buffer.
	; 

		mov	bx, VDD_FUNC_WRITE_FROM_BUFFER
		call	CallVDD
done::
		.leave
		ret
WinCom_WriteMsg endp

hVDD    DW      0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCom_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up

CALLED BY:	(EXTERNAL) Rpc_Exit
PASS:		ds	= cgroup
		ax = 0 if calling afer call to SaveState
		ax = 1 if not calling from after call to SaveState 
		ss:bp = state block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/11/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinCom_Exit	proc	near
		uses	ax, es, ds, si, di, bx
		.enter
	;
	; Release the timer interrupt, again. Note that we don't get called
	; until GEOS has been torn down, so this is fine.
	;
	; RestoreState will restore whatever was in the timer interrupt when
	; we return, so the only way to actually restore the timer interrupt
	; to what's in wincomOldTimer is to adjust the state block at ss:[bp]
	; 
		tst	ax
		jnz	normalReset
		movdw	ss:[bp].state_timerInt, ds:[wincomOldTimer], ax
		jmp	resetIdle
normalReset:
DPC	DEBUG_WINCOM, 'E'
DPW	DEBUG_WINCOM, ds:[wincomOldTimer].segment
DPW	DEBUG_WINCOM, ds:[wincomOldTimer].offset
		mov	bx, offset wincomOldTimer
		mov	ax, 8
		call	ResetInterrupt
resetIdle:
DPC	DEBUG_WINCOM, 'E'
DPW	DEBUG_WINCOM, ds:[wincomOldIdle].segment
DPW	DEBUG_WINCOM, ds:[wincomOldIdle].offset
		mov	bx, offset wincomOldIdle
		mov	ax, 28h
		call	ResetInterrupt
		
		segmov	es, ds
	;
	;
	; Cancel any outstanding send or receive on the socket.
	; 
	
	;
	; Close down the socket itself.
	; 
	;;
	;; Unregister the VDD
	;;
		mov	ax, cs:[hVDD]
	DPS	DEBUG_EXIT, <cs: >
	DPW	DEBUG_EXIT, cs
	DPS	DEBUG_EXIT, <ax: >
	DPW	DEBUG_EXIT, ax
		UnRegisterModule

		PointDSAtStub
		mov	dx, offset testExitString
		call	DisplayString

		clr	cs:[hVDD]

;	DPS	<DEBUG_EXIT>, <vdd unloaded>
		
		.leave
		ret
WinCom_Exit	endp
testExitString		char 'Exited vdd\r\n$'


scode	segment
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCom_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the communication subsystem

CALLED BY:	(EXTERNAL) Rpc_Init
PASS:		es, ds	= cgroup
RETURN:		Nothing
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/11/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinCom_Init	proc	near
		uses	es, ds, si, di, cx
		.enter

		PointDSAtStub
		mov	dx, offset testInitString
		call	DisplayString

	;;
	;; Setup regs to load vdd
	;; 	
	        ; Load ioctlvdd.dll
	        mov     si, offset DllName                   ; ds:si = dll name
	        mov     di, offset InitFunc                  ; ds:di = init routine
	        mov     bx, offset DispFunc                  ; ds:bx = dispatch routine

	DPC	DEBUG_EXIT, 'r'
		RegisterModule
		nop					; make debugging easier
		jc	error
	DPW	DEBUG_EXIT, ax


	;; Should we print a message on errors?

saveHVDD::
	        mov     ds:[hVDD], ax			; save for later use
	DPS	DEBUG_EXIT, <zowie >
	DPW	DEBUG_EXIT, ax

		call	WinComHookInts
		clc
done:
		.leave
		ret
error:
		PointDSAtStub
		mov	dx, offset vddErrorString
		call	DisplayString
		jmp	done
WinCom_Init	endp

vddErrorString		char 'Trouble with Init\r\n$'
testInitString		char 'Starting vdd\r\n$'

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinComHookInts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hook the interrupt(s) that will allow us to gain control of
		the machine when a packet comes in.

CALLED BY:	(INTERNAL) WinCom_Init
PASS:		ds	= scode
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	WinComOldTimer

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version
	ron	9/13/96		Stolen from NetWare

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinComHookInts	proc	near
		uses	bx, dx
		.enter
		mov	ax, 8
		mov	bx, offset wincomOldTimer
		mov	dx, offset WinComTimer
		call	SetInterrupt
DPS	DEBUG_WINCOM, "ints"
DPW	DEBUG_WINCOM, ds:[wincomOldTimer].segment
DPW	DEBUG_WINCOM, ds:[wincomOldTimer].offset
		mov	ax, 28h
		mov	bx, offset wincomOldIdle
		mov	dx, offset WinComIdle
		call	SetInterrupt
DPW	DEBUG_WINCOM, ds:[wincomOldIdle].segment
DPW	DEBUG_WINCOM, ds:[wincomOldIdle].offset
		.leave
		ret
WinComHookInts	endp

scode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCom_SetHardwareType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine to cope with parsing of /h flag

CALLED BY:	(EXTERNAL) MainHandleInit
PASS:		ax	= HardwareType
		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/11/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinCom_SetHardwareType proc	far
		.enter
		.leave
		ret
WinCom_SetHardwareType endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallVDD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a function of to the DLL

CALLED BY:	
PASS:		bx	- enum for function
RETURN:		depends on function
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallVDD	proc	near
	uses	ax
	.enter
		mov	ax, cs:[hVDD]
;	DPW	DEBUG_EXIT, ax
		;; this happens when we try to send debugging output
		;; before loadint the dll.
		cmp	ax, 0
		je	done
		DispatchCall
done:		
	.leave
	ret
CallVDD endp


;
; Old interrupt handlers for timer and idle
;
wincomOldTimer	fptr.far
wincomOldIdle	fptr.far




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinComTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a packet every 60th of a second

CALLED BY:	Timer0 (int 8h)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	machine may be stopped

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/11/94		Initial version
	ron	9/13/96		Stolen from NetWare

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinComTimer	proc	far
	;
	; If we have never been idle, then don't look
	;
;		cmp	cs:[haveBeenIdle], 0
;		je	done
		push	bx
		DPS	DEBUG_WINCOM, <timer >
		mov	bx, offset wincomOldTimer
		jmp	WinComCheckPacket
done:
		iret
WinComTimer	endp

haveBeenIdle	word	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinComIdle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a packet when the kernel has declared the system
		idle.

CALLED BY:	int 28h
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	machine may be stopped

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/11/94		Initial version
	ron	9/13/96		Stolen from NetWare

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinComIdle	proc	far
;		mov	cs:[haveBeenIdle], 1
		push	bx
		mov	bx, offset wincomOldIdle
		DPS	DEBUG_WINCOM, <idle >
		.assert $ eq WinComCheckPacket
		.fall_thru
WinComIdle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinComCheckPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a packet has been received and we're not in Rpc_Wait

CALLED BY:	timer & idle interrupts
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version
	ron	9/13/96		Stolen from NetWare

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WinComCheckPacket proc	far
		push	ax
		push	ds
		on_stack ds ax bx iret
		PointDSAtStub
	;
	; Always pass this thing off ASAP, but call, don't jmp, so we have
	; control when old handler is done.
	; 
		pushf
		call	{fptr.far}ds:[bx]
	;
	; If we're in Rpc_Call or Rpc_Run, then the message will be picked up
	; shortly.
	; 
		test	ds:[sysFlags], mask waiting or mask calling
		jnz	done
	;
	; See if there is a packet waiting,
	; if not bail
	;
		push	bx, cx
		mov	bx, VDD_FUNC_TEST_FOR_READ
		call	CallVDD
		mov	ax, cx
		pop	bx, cx
		cmp	ax, 0
		je	done
if 0
	;;
	;; I don't think we need this as we send messages 
	;; in packets instantaneously, no waiting.
	;;

	; If ECB is still marked in-use, it means no packet has arrived
	; 
		tst	ds:[recvECB].ECB_inUse
		jnz	done
endif
	;
	; Packet has arrived. Save state and go handle the packet. Note that
	; if the packet is RPC_INTERRUPT, we will *not* return from Rpc_Wait.
	; 
		pop	ds
		pop	ax
		pop	bx
		on_stack	iret

		call	SaveState
	DPC DEBUG_MSG_PROTO, 'M', inv

		call	Rpc_Wait
		dsi			; make sure we don't context-switch
					;  until we iret
		call	RestoreState
		iret
done:
	;
	; No packet waiting, so just get out of here.
	;
		pop	ds
		pop	ax
		pop	bx
		iret
WinComCheckPacket endp
if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinCom_Init2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does initialization steps needed after loader has beeen loaded.

CALLED BY:	MainFinishLoaderLoad
PASS:		ds	= cgroup
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	Hooks Timer and idle interrupt.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.386
WinCom_Init2	proc	far
	.enter
	;
	; Notify vdd of a callback it can use. 
	; This must be done after the timer calibration loop.
	;
		push	ds
		segmov	ds, scode
		call	WinComHookInts
		mov	ds:[kernelLoaded], TRUE	
		pop	ds
	.leave
	ret
WinCom_Init2	endp
endif

scode	ends

endif	; WINCOM
