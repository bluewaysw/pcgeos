COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		atron.asm

AUTHOR:		Adam de Boor, Dec 17, 1989

ROUTINES:
	Name			Description
	----			-----------
	Atron_Init		Initialize the atron board and support for it
	AtronStartTrace		Reset trace buffer for free-running mode
	AtronTraceFetch		Begin transfer of trace buffer records
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/17/89	Initial revision


DESCRIPTION:
	Device-specific routines for using the Atron board.
		
	NOTE: THIS FILE CONTAINS INFORMATION THAT IS PROPRIETARY TO
	CADRE, INC., AND HAS BEEN PROVIDED UNDER A NON-DISCLOSURE
	AGREEMENT. IF YOU HAVE NOT SIGNED THIS AGREEMENT, DO NOT LOOK
	AT THIS FILE.


	$Id: atron.asm,v 1.4 92/04/13 00:13:32 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ATRON

DEF_BASE	= 0d0h

		include	stub.def
		.286p
;
;		      DEVICE OVERLAY DEFINITIONS
;
; The device overlay is enabled by setting CR_REGMODE in the command register.
; The overlay is mapped into the high 64K of the 128K window in real mode and
; into the highest 64K of the 1M window in protected mode.
;
AtrDevSeg	segment	at 0
Bank0	label	byte	; Addressed by address-bits 0-7 and the four output bits
			;  from Bank1. This bank lies in the low four bits of
			;  the range 0 to 0fffh
Bank1	label	byte	; Addressed by address-bits 8-19; output goes to Bank0.
			;  Lies in the high four bits of 0 to 0fffh
	org	2000h
Bank2	label	byte	; Addressed by address bits 20-23 and various bus-
			;  control signals. Lies in the high four bits of
			;  2000h-2fffh
Bank3	label	byte	; Addressed by S1, PEACK, S0, COD/-INTA. Lies in the
			;  low four bits of 2000h-23ffh
	org	4000h
Bank4	label	byte	; Addressed by d0-d7. Low four bits of 4000-43ffh
Bank5	label	byte	; Addressed by d8-d15. High four bits of 4000-43ffh

;
; Trace buffer memory banks
;
		org	6000h
TraceA0A7	label	byte
		org	6800h
TraceA8A15	label	byte
		org	7000h
TraceA16A23	label	byte
		org	7800h
TraceD0D7	label	byte
		org	8000h
TraceD8D15	label	byte
		org	8800h
TraceBus	label	byte
		org	9000h
TraceMisc	label	byte

TRACE_MAX	equ	2048	; Length of each bank of trace RAM
;
; UART definitions
;
		org	0f010h
UARTData	label	byte
		org	0f011h
UARTCtrl	label	byte

UART_SETRTS	=	7	; Force RTS high, resetting trace counter
UART_CLRRTS	=	27h	; Force RTS low.

;
; Board status register
;
StatusRegRecord	record
	SR_STOP:1=1,		; Stop button pressed (high)
	SR_PERR:1=1,		; On-board parity error (high)
	SR_PERFTICK:1=0,	; Performance counter overflow (low)
	:1,
	SR_BP1:1=0,		; BP1 triggered (low)
	SR_BP2:1=0,		; BP2 triggered (low)
	SR_BP3:1=0,		; BP3 triggered (low)
	SR_BP4:1=0		; BP4 triggered (low)
StatusRegRecord	end

		org	0f000h
StatusReg	label	StatusRegRecord
		org	0f030h
NMIAcknowledge	label	byte

AtrDevSeg	ends

;
; Constants passed to GateA20 to determine state of address bit 20
;
A20_ON		= 0dfh
A20_OFF		= 0ddh


;-----------------------------------------------------------------------------
;		      LOADALL Definitions
;
; LOADALL is an unofficial '286 instruction that allows access to internal
; processor registers not normally available in real mode (or even in
; protected mode). It uses a fixed block of data at 000800h as the source for
; all the registers, including the internal segment register descriptor caches.
;
; Most of these registers may be safely filled with junk, so there's no need
; to save or alter the contents of their memory locations, which is good,
; since memory at 800h is used by DOS, so the values would indeed have to
; be saved. Those variables whose comment is preceded by a '*' are the
; variables that need to be changed.
;
; We don't take advantage of the above in this, the second implementation of
; the LOADALL support. The simple reason is that saving and restoring just
; those portions takes a great deal more code (doing the whole thing only 
; takes three REP MOVSW's) and only gains 50 or so cycles, if that. Instead,
; we've got the emmSavedData for the data that were at 000800h and
; emmNewData for the data we want to be there.
;-----------------------------------------------------------------------------
LA_SEGMENT	= 80h

;
; Access rights for a segment:
;	AR_PRESENT	non-zero if segment actually in memory
;	AR_PRIV		privilege level (0-3) required for access
;	AR_ISMEM	1 if a memory segment, 0 if special
;	AR_TYPE		type of segment
;	AR_ACCESSED	non-zero if memory accessed
;
SegTypes 				etype byte, 0
SEG_DATA_RD_ONLY			enum SegTypes
SEG_DATA				enum SegTypes
SEG_DATA_EXPAND_DOWN_RD_ONLY		enum SegTypes
SEG_DATA_EXPAND_DOWN			enum SegTypes
SEG_CODE_NON_READABLE			enum SegTypes
SEG_CODE				enum SegTypes
SEG_CODE_CONFORMING_NON_READABLE	enum SegTypes
SEG_CODE_CONFORMING			enum SegTypes

AccRights	record
	AR_PRESENT:1
	AR_PRIV:2
	AR_ISMEM:1
	AR_TYPE SegTypes:3
	AR_ACCESSED:1
AccRights	end

LASegmentCache	struct
    LASC_baseLow	word			; Low 16 bits of segment base
    LASC_baseHigh	byte			; High 8 bits of segment base
    LASC_access		AccRights		; Access rights (AR_PRESENT
						; becomes AR_VALID)
    LASC_limit		word			; Segment limit
LASegmentCache	ends

LADataBlock	struct
    LADB_unused1	byte	6 dup(?)	; Unused
    LADB_MSW		word			; *MSW register
    LADB_unused2	byte	14 dup(?)	; Unused
    LADB_TR		word			; Task Register
    LADB_FLAGS		word			; *Flags word
    LADB_IP		word			; *IP register
    LADB_LDT		word			; Local Descriptor Table
						;  selector
    LADB_DS		word			; DS selector
    LADB_SS		word			; SS selector
    LADB_CS		word			; *CS selector
    LADB_ES		word			; ES selector
    LADB_DI		word			; DI register
    LADB_SI		word			; SI register
    LADB_BP		word			; BP register
    LADB_SP		word			; *SP register
    LADB_BX		word			; BX register
    LADB_DX		word			; DX register
    LADB_CX		word			; CX register
    LADB_AX		word			; AX register

    LADB_ESC		LASegmentCache <>	; *Descriptor cache for ES
    LADB_CSC		LASegmentCache <>	; *Descriptor cache for CS
    LADB_SSC		LASegmentCache <>	; *Descriptor cache for SS
    LADB_DSC		LASegmentCache <>	; *Descriptor cache for DS

    LADB_GDT		LASegmentCache <>	; Global Descriptor Table
						;  address
    LADB_LDTC		LASegmentCache <>	; Local Descriptor Table cache
    LADB_IDT		LASegmentCache <>	; *Interrupt Descriptor Table
					     	; address
    LADB_TSS		LASegmentCache <>	; Task State Segment for
						;  current task
LADataBlock	ends

LOADALL		equ	<byte 0fh, 05h>	; Opcode for LOADALL instruction

scode		segment

savedData	LADataBlock	<>
newData		LADataBlock	<>

traceValid	word		0	; Set if trace buffer properly
					;  initialized.
nmiStatus	StatusRegRecord <>

scode		ends

stubInit	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Atron_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Atron board and our support of it.

CALLED BY:	Main
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Look for /a flag to find the base address of the Atron board.
		
		Initialize the various fields in the newData block since
		they're constant.

		Set the stubType variable to STUB_ATRON

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should make sure the board is operational.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Atron_Init	proc	far
		.enter
		mov	ax, scode
		mov	ds, ax
		mov	es, ax
		;
		; Fetch atron base address....later
		;
		;------------------------------------------------------------
		; One-time initialization of newData
		;------------------------------------------------------------
		;
		; Init CS and DS descriptors to scode (never change)
		; In real mode, the segment type should be SEG_DATA even if
		; it's code. If we make it SEG_CODE, then future writes via
		; CS fail with a protection violation, while execution,
		; in real mode, doesn't check the executable bit.
		;
		mov	ds:newData.LADB_CS, ax
		mov	ds:newData.LADB_DS, ax
		rol	ax, 4
		mov	dl, al
		and	dl, 0fh
		and	al, 0f0h
		mov	ds:newData.LADB_CSC.LASC_baseLow, ax
		mov	ds:newData.LADB_CSC.LASC_baseHigh, dl
		mov	ds:newData.LADB_DSC.LASC_baseLow, ax
		mov	ds:newData.LADB_DSC.LASC_baseHigh, dl
		;
		; Point ES at Atron register space (never changes)
		;
		mov	ds:newData.LADB_ESC.LASC_baseLow, 0
		mov	ds:newData.LADB_ESC.LASC_baseHigh, DEF_BASE or 0fh
		mov	ds:newData.LADB_ES, -1	;Bogus
		;
		; Point IDT at 0 with a limit of 400h, as is usual for real
		; mode.
		; 
		mov	ds:newData.LADB_IDT.LASC_baseLow, 0
		mov	word ptr ds:newData.LADB_IDT.LASC_baseHigh, 0
		mov	ds:newData.LADB_IDT.LASC_limit, 400h
		;
		; Set limits for CS, SS, DS, and ES to be 64k
		; 
		mov	ax, 0ffffh
		mov	ds:newData.LADB_ESC.LASC_limit, ax
		mov	ds:newData.LADB_CSC.LASC_limit, ax
		mov	ds:newData.LADB_SSC.LASC_limit, ax
		mov	ds:newData.LADB_DSC.LASC_limit, ax
		;
		; Set access rights for CS, SS, DS and ES to be r/w data
		; (see above for why CS is SEG_DATA)
		;
		mov	al, AccRights <1,0,1,SEG_DATA,1>
		mov	ds:newData.LADB_ESC.LASC_access, al
		mov	ds:newData.LADB_CSC.LASC_access, al
		mov	ds:newData.LADB_SSC.LASC_access, al
		mov	ds:newData.LADB_DSC.LASC_access, al
		;
		; Store current MSW as MSW to be used (never changes)
		;
		smsw	ds:newData.LADB_MSW
		;
		; Point IP at InPMode as that's where we want to be after
		; the load.
		; 
		mov	ds:newData.LADB_IP, offset InPMode
		;
		; Set the stubType to be STUB_ATRON so UNIX knows
		;
		mov	ds:stubType, STUB_ATRON
		;
		; Register RPC server for RPC_TRACE_FETCH
		;
		mov	bx, RPC_TRACE_FETCH
		mov	ax, offset AtronTraceFetch
		call	Rpc_Serve
		;
		; Initialize the UART so we can use the trace buffer
		;
		call	AtronInitUart
		.leave
		ret
Atron_Init	endp

stubInit	ends

scode		segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GateA20
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or ground address bit 20 (taken from AT BIOS)

CALLED BY:	AtronStartDev, AtronEndDev
PASS:		AH	= DD to ground A20
			= DF to enable A20
RETURN:		AL	= 0 if successful
			= 2 if failed
		Interrupts enabled
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KBD_CMD_PORT	= 64h		; Keyboard controller command port
KBD_DATA_PORT	= 60h
KCMD_WRITE_OUTPUT = 0d1h	; Command to cause next write to 60h to go
		  		;  to controller's output port
empty_8042	proc 	near
		clr	cx		; wait 64k times
E8042Loop:
		in	al, KBD_CMD_PORT
		and	al, 2		; input buffer full
		loopnz	E8042Loop
		ret
empty_8042	endp

GateA20		proc	near
		push	cx
		dsi
		call	empty_8042	; Wait for controller
		jnz	GA20Ret

		mov	al, KCMD_WRITE_OUTPUT	; Send command
		out	KBD_CMD_PORT, al
		call	empty_8042	; Wait for it to be accepted
		
		jnz	GA20Ret
		mov	al, ah
		out	KBD_DATA_PORT, al	; Send desired A20 state
		call	empty_8042
GA20Ret:
		eni
		pop	cx
		ret
GateA20		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AtronStartDev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin accessing the Atron board's devices

CALLED BY:	INTERNAL
PASS:		Nothing
RETURN:		registers set up to access the Atron board's device
		space via ES.
		INTERRUPTS OFF.

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		We gain access to the Atron board's memory from real-mode
		using an undocumented instruction in the '286 called LoadAll.

		Refer to the documentation at the beginning of this file for
		more information.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AtronStartDev	proc	near
		.enter
		;
		; First bank in the device registers to the upper 64K.
		;
		mov	ax, CmdSeg
		push	es
		mov	es, ax
		mov	es:[cmdReg], mask CR_REGMODE or CR_OVLY0
		pop	es
		;
		; Now enable address bit 20 so we can actually access the
		; board without the bit being grounded for us.
		;
		mov	ah, A20_ON
		call	GateA20
		;
		; Turn off interrupts and transfer current block of data
		; from the loadall block into our saving place
		;
		dsi
		mov	ax, LA_SEGMENT
		mov	ds, ax
		clr	si
		mov	di, offset savedData
		mov	cx, size LADataBlock/2
		cld
		rep	movsw
		mov	di, es
		mov	es, ax
		mov	ds, di
		;
		; Fill in the remaining flags in the newData block:
		;	flags, sp, bp...
		;
		pushf
		pop	ds:newData.LADB_FLAGS
		mov	ds:newData.LADB_SP, sp
		mov	ds:newData.LADB_BP, bp
		;
		; Point SS at current stack
		;
		mov	ax, ss
		mov	ds:newData.LADB_SS, ax
		rol	ax, 4
		mov	dl, al
		and	dl, 0fh
		and	al, 0f0h
		mov	ds:newData.LADB_SSC.LASC_baseLow, ax
		mov	ds:newData.LADB_SSC.LASC_baseHigh, dl
		;
		; Now copy the data block into the loadall area
		;
		mov	si, offset newData
		clr	di
		mov	cx, size LADataBlock/2
		rep	movsw
		;
		; Load all the registers with the proper values
		;
		LOADALL
InPMode		label	near
		.leave
		ret
AtronStartDev	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AtronEndDev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish accessing the atron devices

CALLED BY:	INTERNAL
PASS:		INTERRUPTS OFF
		ds	= scode
RETURN:		es	= scode
DESTROYED:	di, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AtronEndDev	proc	near		uses ax
		.enter
		;
		; Restore the old data from the loadall block
		;
		mov	ax, LA_SEGMENT
		mov	es, ax
		clr	di
		mov	si, offset savedData
		mov	cx, size LADataBlock/2
		rep	movsw
		;
		; Bank out the atron device registers
		;
		mov	ax, CmdSeg
		mov	es, ax
		mov	es:[cmdReg], CR_OVLY0
		;
		; Disable address bit 20 again. TURNS INTERRUPTS BACK ON.
		;
		mov	ah, A20_OFF
		call	GateA20
		;
		; Point ES back at scode again.
		;
		mov	ax, ds
		mov	es, ax
		.leave
		ret
AtronEndDev	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AtronFindBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the bounds of the current trace record

CALLED BY:	AtronTraceFetch
PASS:		ds	= scode
RETURN:		bx	= newest valid record+1
		ax	= oldest valid record
DESTROYED:	cx, dx, si, di

PSEUDO CODE/STRATEGY:
		When the trace buffer is disabled, it places the next 32
		bus cycles into itself with the ATRM_RUN bit clear. Since we
		reset the trace counter to 0 before letting the machine go,
		we have only to find the first record with the RUN bit clear to
		find the end of the current trace cycle.
		
		Once we've found the end, there is the question of whether
		the trace record might have wrapped around. To answer this
		question, we need to look at the remaining records. If any 
		beside the requisite 32 records has the RUN bit clear, the
		record didn't wrap, as if it did wrap, all the records would
		have the RUN bit set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AtronFindBounds	proc	near
		.enter
		call	AtronStartDev
		mov	al, ATRM_RUN
		test	{byte}es:TraceMisc[0], al
		jz	firstClear
		;
		; Doesn't start with a clear record -- find the first one
		; that is clear.
		;
		clr	si
		mov	cx, TRACE_MAX-1
findFirstClear:
		inc	si
		test	{byte}es:TraceMisc[si-1], al
		loopnz	findFirstClear
		mov	bx, si		; Record last valid
		add	si, 31		; Skip over 32 extra cycles before
					;  searching for any others with clear
		sub	cx, 31		;  (actually use 31 to account for inc
					;  at start of loop)
		lea	di, [si+1]	; In case all remaining records are good
checkFinalRecords:
		inc	si
		test	{byte}es:TraceMisc[si], al
		loopnz	checkFinalRecords
		jnz	done		; All have RUN bit set so all are valid
		clr	di		; Trace record starts at 0
done:
		mov	ax, di
doneNoTransfer:
		call	AtronEndDev
		.leave
		ret
firstClear:
		;
		; Trace buffer must have wrapped -- find out how many are
		; here at the start of the buffer so we know how many are at the
		; end.
		; 
		clr	si
		mov	cx, 32
findEnd:
		inc	si
		test	{byte}es:TraceMisc[si-1], al
		loopz	findEnd
		mov	bx, si		; First set is oldest record
		sub	ax, 32		; Figure number at the end of the
		add	ax, TRACE_MAX	;  buffer.
		jmp	doneNoTransfer
AtronFindBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AtronTraceFetch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch all the valid trace records

CALLED BY:	RPC_TRACE_FETCH
PASS:		ds	= scode
		es	= scode
RETURN:		Nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		This call doesn't return anything directly, but serves
		to begin the flow of trace records up to the host.
		
		First, we locate the range of valid trace records in 
		the trace buffer.
		
		Next, starting from the end of the trace, we issue successive
		calls to the RPC_TRACE_NEXT procedure in Swat, passing as
		arguments a full buffer of trace records. Swat in turn will
		return a non-zero byte if more records are wanted. If the
		byte is 0 or we get back an error, we stop sending.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AtronTraceFetch	proc	near
maxTrace	local	word
minTrace	local	word
		.enter
		clr	bx
		tst	ds:traceValid		; Buffer initialized?
		jz	sendReply
		;
		; Locate the bounds of the trace record.
		;
		call	AtronFindBounds
		mov	maxTrace, bx
		mov	minTrace, ax
		sub	bx, ax
		jae	checkArg
		add	bx, TRACE_MAX		; Correct for wrapping
checkArg:
		mov	{word}rpc_ToHost, bx	; Return # of records
		cmp	bx, {word}rpc_FromHost
		ja	sendReply		; Argument w/in bounds
		mov	al, RPC_TOOBIG
		call	Rpc_Error
		jmp	done
sendReply:
		mov	si, offset rpc_ToHost
		mov	cx, word
		call	Rpc_Reply
		mov	bx, maxTrace
		;
		; Skip to the first requested record
		;
		add	ax, {word}rpc_FromHost
		andnf	ax, TRACE_MAX-1
		mov	maxTrace, ax
sendLoop:
		;
		; Transfer the next set of trace records to the host.
		;
		call	AtronStartDev	; Point es to atron device segment

RECORDS_PER_CALL = (RPC_MAX_DATA-size RpcHeader)/size(AtronTraceRecord)
		mov	cx, RECORDS_PER_CALL
		mov	di, offset rpc_ToHost
		mov	bx, maxTrace
copyLoop:
		dec	bx
		and	bx, TRACE_MAX-1		; Wrap at bottom
		;
		; Fetch out the address bus
		;
		mov	al, es:TraceA0A7[bx]
		mov	ah, es:TraceA8A15[bx]
		mov	ds:[di].atr_addrLow, ax
		mov	al, es:TraceA16A23[bx]
		mov	ds:[di].atr_addrHigh, al
		;
		; Fetch the data bus
		;
		mov	al, es:TraceD0D7[bx]
		mov	ah, es:TraceD8D15[bx]
		mov	ds:[di].atr_data, ax
		;
		; Fetch the bus signals
		;
		mov	al, es:TraceBus[bx]
		mov	ah, es:TraceMisc[bx]
		mov	{word}ds:[di].atr_bus, ax
		;
		; Advance to next trace record
		;
		add	di, size AtronTraceRecord
		;
		; Hit end of packet or of trace buffer?
		;
		cmp	bx, minTrace
		loopne	copyLoop		; No -- do another record
		mov	maxTrace, bx		; Save stopping point
		;
		; Figure the length of the packet we're sending
		;
		mov	cx, di
		sub	cx, offset rpc_ToHost
		push	cx
		call	AtronEndDev		; Back to regular mode
		;
		; Send the call up to Swat
		;
		mov	ax, RPC_TRACE_NEXT
		mov	bx, offset rpc_ToHost
		pop	cx
		call	Rpc_Call
		;
		; Finish if got an error, a zero reply byte or hit the end
		; of the trace.
		;
		test	ds:sysFlags, mask error
		jnz	done
		tst	{byte}ds:rpc_FromHost
		jz	done
		mov	bx, maxTrace
		cmp	bx, minTrace
		jne	sendLoop
done:
		.leave
		ret
AtronTraceFetch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AtronInitUart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the atron's uart so we can play with its RTS
		signal to reset the trace counter 

CALLED BY:	Atron_Init
PASS:		ds	= scode
		es	= scode
RETURN:		Nothing
DESTROYED:	All but ss, ds, es, sp and bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AtronDelay	proc	near		; Delay routine "recommended" by Atron
		mov	cx, 20		;  diagnostics. What the hell...
10$:		loop	10$
		ret
AtronDelay	endp

AtronInitUart	proc	far
		.enter
		;
		; Deliver worst-case initialization string to the 8251a.
		; Sets it in sync mode, then resets it and puts it into
		; async mode the way it should be. The numbers are magic,
		; but documented in the Intel Data Component Catalog pp 9-165 on
		;
		call	AtronStartDev
		clr	al
		mov	es:[UARTCtrl], al	; Set mode
		call	AtronDelay
		mov	es:[UARTCtrl], al	; First sync char
		call	AtronDelay
		mov	es:[UARTCtrl], al	; Second sync char
		call	AtronDelay
		mov	es:[UARTCtrl], 77h	; Set async mode
		call	AtronDelay
		mov	es:[UARTCtrl], 0ceh	; More magic
		call	AtronDelay
		mov	es:[UARTCtrl], UART_CLRRTS
		;
		; Clear out an important bank of the breakpoint RAM until we
		; can actually use it, thus disabling any breakpoints. This
		; should avoid extraneous NMIs when the board is first enabled.
		;
		clr	di
		mov	cx, 0x1000
		clr	al
		rep	stosb
		call	AtronEndDev
		.leave
		ret
AtronInitUart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Atron_InitTrace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-initialize the trace buffer if not just single-stepping

CALLED BY:	RestoreState
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Need to raise the RTS signal on the UART to reset the trace
		buffer's counter to 0. This involves switching to our
		pseudo-protected mode, which destroys everything.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Atron_InitTrace	proc	near
		.enter
		pusha		; Save the world
		push	ds
		push	es
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		mov	ds:traceValid, 0
		tst	ds:stepping
		jnz	noInit

		inc	ds:traceValid		; Note that trace buffer
						;  properly initialized

		call	AtronStartDev
		;
		; Have to zero the records out if going to free-running mode
		; else if the buffer had wrapped before and we only go far
		; enough to cover the extra 32 cycles placed in the buffer for
		; that trace, we'll think the cycles at the end of the buffer
		; are valid when they're not. 
		;
		mov	di, offset TraceMisc
		mov	cx, TRACE_MAX
		clr	al
		rep	stosb
		;
		; Strobe the UART's RTS line to reset the trace counter
		;
		mov	es:[UARTCtrl], UART_SETRTS
		call	AtronDelay
		call	AtronDelay
		mov	es:[UARTCtrl], UART_CLRRTS
		call	AtronEndDev
noInit:
		pop	es
		pop	ds
		popa		; Restore the world
		.leave
		ret
Atron_InitTrace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Atron_FieldNMI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an NMI and see if it comes from the Atron board,
		recording the source and reseting the board if so.

CALLED BY:	IRQCommon via CHECK_NMI macro
PASS:		ax	= RPC being sent
		bx	= offset of RPC args being sent (rpc_ToHost)
		cx	= size of same (size HaltArgs)
		ds	= scode
		rpc_ToHost = HaltArgs
RETURN:		ax, bx, cx = Rpc_Call parameters to use
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Atron_FieldNMI	proc	near	uses ds, es, ax, bx, cx, dx, si, di, bp
		.enter
		call	AtronStartDev
assume es:AtrDevSeg
		mov	al, es:[StatusReg]
		mov	ds:nmiStatus, al
		mov	es:NMIAcknowledge, al
		call	AtronEndDev
assume es:scode
		.leave
		ret
Atron_FieldNMI	endp

scode		ends

endif	; ATRON
