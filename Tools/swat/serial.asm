COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		serial.asm

AUTHOR:		Adam de Boor, Jul 20, 1992

ROUTINES:
	Name			Description
	----			-----------
	Serial_Init		Initialize serial communication.
	Serial_Check		See if any data have come in
	Serial_Read		Read some bytes from the input ring buffer
	Serial_WriteV		Write data to the serial port given a scatter/
				gather vector.
	MouseStart
	MouseShowCurosr
	MouseHideCurosr
	MouseCallDriver		make a call to the mouse driver
	Mouse_Exit		clean up mouse stuff	

	Ipx_Check		see if IPX is loaded
	Ipx_Init		initialize Ipx stuff
	Ipx_Exit		clean up
	Ipx_CopyToSendBuffer	routine to copy data down to a real-mode
				buffer to be sent off to IPX
	Ipx_SendLow		send a packet to IPX
	Ipx_CheckPacket		see if a pakcet has been received
	Ipx_ReadLow		read data from a packet received
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/20/92		Initial revision
	jimmy	3/93		added mouse stuff
	jimmy	3/94		added ipx stuff

DESCRIPTION:
	This is the Extended-DOS implementation of the serial port 
	manipulation required by Swat.
	
	This module handles all I/O for a single serial line. All the I/O
	is interrupt-driven.

	The buffers are, naturally, ring buffers with no checking for
	overflow (we assume the nature of the communication mechanism (with
    	replies and so on) will prevent this...).

	The single-byte functions will not block, but the block functions will.


	Mouse support is also being thrown in here for expediency...
		
	$Id: serial.asm,v 1.15 94/07/06 15:20:30 jimmy Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	.386p		; you bet your sweet behind...

include	dosx.ah		; read DOS-Extender interface definitions

include mouse.def	; mouse stuff
include ipx.def		; ipx stuff

;------------------------------------------------------------------------------
;
; Define segment layout...
; 
_RCODESEG	segment	byte public use16 'RM_CODE'
	public	start_real
start_real	label	byte
_RCODESEG	ends

_RDATA	segment dword public use16 'RM_DATA'
_RDATA	ends
_SERDATA segment dword public use32 'DATA'
_SERDATA ends

DGROUP	group _RDATA, _SERDATA
_CODESEG	segment byte public use32 'CODE'
_CODESEG	ends

CGROUP	group	_CODESEG

;------------------------------------------------------------------------------
;
; Communications control ports and vectors
; Each of the port numbers is ANDed with 0100h if COM2 is to be used, since
; those ports are in the 02f8h-02fd range (qv. the definitions for COM1, below)
;
COMDATAPORT	equ	03f8h	; data port 
COMDLLPORT	equ	03f8h	; Low-half of divisor

COMIENPORT	equ	03f9h	; interrupt-enable port 
				; bit 0 -- data available
				; bit 1 -- transmitter empty
				; bit 2 -- line error
				; bit 3 -- modem status
COMRECVENABLE	equ	0001b
COMTRANSENABLE	equ	0010b
COMERRENABLE	equ	0100b

COMIRQPORT	equ	03fah	; interrupt ID port, formatted as:
				; bit 0 -- 0 if interrupt pending
				; bit 1-2:
				;	11 => Line error. reset by reading
				;		statport (0qfdh)
				;	10 => Data available. reset by
				;		reading dataport
				;	01 => Transmitter empty. reset by
				;		reading irqport or writing
				;		dataport
				;	00 => Modem status change (unhandled)
COMDATAREADY	equ	100b
COMLINEERR	equ	110b
COMTRANSREADY	equ	010b

COMLINEPORT	equ	03fbh	; Line control port. Controls data format and
				; whether dataport and ienport are really
				; those ports, or the divisor for determining
				; the baud rate. Bit 7 s/b 1 to change the
				; baud rate and 0 otherwise.  Different
				; divisors are listed below:

BAUD_38400	equ	3	; divisor used to get 38.4Kb
BAUD_19200	equ	6	; divisor used to get 19.2Kb
BAUD_9600	equ	12	; divisor used to get 9600
BAUD_7200	equ	16	; divisor used to get 7200
BAUD_4800	equ	24	; divisor used to get 4800
BAUD_3600	equ	32	; divisor used to get 3600
BAUD_2400	equ	48	; divisor used to get 2400
BAUD_1200	equ	96	; divisor used to get 1200
BAUD_300	equ	384	; divisor used to get 300

SerialFormat	record SF_DLAB:1=0, SF_BREAK:1, SF_PARITY:3, SF_EXTRA_STOP:1, SF_LENGTH:2

	; SF_PARITY field
	; 
    SP_NONE	equ 0	; No parity generated or expected
    SP_ODD	equ 1	; Odd parity
    SP_EVEN	equ 3	; Even parity
    SP_ONE	equ 5	; Always-One parity
    SP_MARK	equ 5	; Same, but using fancy EE name
    SP_ZERO	equ 7	; Always-Zero parity
    SP_SPACE	equ 7	; Same, but using fancy EE name

	; SF_LENGTH field
	; 
    SL_5BITS	equ	0
    SL_6BITS	equ	1
    SL_7BITS	equ	2
    SL_8BITS	equ	3

		
COMMODEMPORT	equ	03fch	; modem control port
				; bit 0 -- DTR
				; bit 1 -- RTS
				; bit 2 -- OUT1
				; bit 3 -- OUT2
				;	The OUT2 signal is used to gate the
				;	IRQ signal from the 8250. If it is
				;	set low, the IRQ line is forced
				;	low. OUT2 must be high for
				;	interrupts to be enabled.
COMDTR		equ	0001b
COMRTS		equ	0010b
COMOUT1		equ	0100b
COMOUT2		equ	1000b

COMSTATPORT	equ	03fdh	; line status port
COMDAVAIL	equ	0000001b; Data waiting in input register
COMOVERRUN	equ	0000010b; Missed a byte.
COMPERR		equ	0000100b; Parity error
COMFRAMEERR	equ	0001000b; Framing error
COMALLERR	equ	0001110b; All possible errors
COMBREAK	equ	0010000b; A break signal was detected on the line
COMTHRE		equ	0100000b; Transmitter holding-register empty -- serial
				; line ready for more data.
COMTSRE		equ	1000000b; Shift register empty too.

ICEOI	    	equ 	20h	; specific-end-of-interrupt base.
ICEOIPORT   	equ 	20h 	; Port for EOI for PIC 1
ICEOIPORT2	equ	0a0h	; Port for EOI for PIC 2

KBD_BREAK_VEC	equ	1bh	; Interrupt issued by keyboard ISR when it sees
				;  Ctrl+Break
			; All these pointer variables hold offsets from 400h
KBD_HEAD_PTR	equ	1ah	; Location of keyboard-buffer head pointer in
				;  SS_DOSMEM (next char to fetch)
KBD_TAIL_PTR	equ	1ch	; Location of keyboard-buffer tail pointer in
				;  SS_DOSMEM (first free byte)
KBD_START_PTR	equ	80h	; Location of keyboard-buffer start pointer in
				;  SS_DOSMEM
KBD_END_PTR	equ	82h	; Location of keyboard-buffer end pointer in
				;  SS_DOSMEM
;
; Buffering paramters:
;	BUFSIZE		Size of both transmit and receive buffers (power o' 2!)
;
BUFSIZE		equ	1024	; Number of characters to buffer

;
; A BUFFER is used to queue incoming and outgoing data. It contains BUFSIZE
; bytes of data arranged in a ring buffer. Two indices into the buffer are
; maintained. Data are added at the tail index and removed at the head.
; The number of characters in the buffer is maintained in the numChars field
; to make the checks as efficient as possible.
;
BUFFER		STRUC
head		dw	0		; Head index
tail		dw	0		; Tail index
numChars	dw	0		; Number of characters in buffer
data		db	BUFSIZE DUP(?)	; The characters themselves
BUFFER		ENDS

;
; Update is used to update a buffer index, modulo BUFSIZE, and store it in
; its proper location. "reg" is the register in which the index is currently
; located and "dest" is where it should eventually go.
;
Update		macro	dest, reg
		local	stuffIt
		inc	reg		;; Pointers move forward
    ife (BUFSIZE AND (BUFSIZE-1))
    	    	and 	reg, BUFSIZE-1
    else
		cmp	reg, BUFSIZE	;; At end?
		jne	stuffIt		;; Nope
		clr	reg		;; Wrap to 0
stuffIt:
    endif
    		mov	dest, reg	;; Store it
		endm

Update_Q	macro	dest, reg
		local	stuffIt_Q
		add	reg, size BPRESS
		cmp	reg, QSIZE
		jle	stuffIt_Q
		mov	reg, INIT_QUEUE_OFFSET
stuffIt_Q:
		mov	dest, reg
		endm

;------------------------------------------------------------------------------
;
; Global data accessed in both real and protected mode.

_RDATA		segment

comIn		BUFFER	<>		; Receiver buffer
comOut		BUFFER	<>		; Output buffer

mouseQueue	MOUSE_QUEUE <>		; only need input queue

;
; Various state flags and macros for manipulating them
;
;
; Flag definitions:
;	IRQPEND		Set => a transmitter interrupt should be coming in.
;			Tells us whether to queue a character or send it
;			directly.
;
clr		macro	reg
		xor	reg, reg
endm

set		macro	flag
		;;
		;; Set the flag TRUE. isset? will set ZF = 0 after this
		;;
		or	ds:[comFlags], MASK flag
		endm
reset		macro	flag
		;;
		;; Reset the flag to FALSE. isset? will set ZF = 1.
		;;
		and	ds:[comFlags], NOT MASK flag
		endm
isset?		macro	flag
		;;
		;; Set the flags so jnz will take if the flag is true
		;;
		test	ds:[comFlags], MASK flag
		endm
flags		record	IRQPEND:1
comFlags	flags	<0>
kbdIrqFlag	db	0
		even
;
; The four ports needed by the interrupt routine. These are set up by
; Serial_Init based on the device being used.
;
comCurDataPort	dw	?		; COMDATAPORT
comCurStatPort	dw	?		; COMSTATPORT
comCurIRQPort	dw	?		; COMIRQPORT
comCurIENPort	dw	?		; COMIENPORT

comIRQ		db	?		; interrupt level (so we know what PICs
					;  to manipulate)

public comCurIENPort, comCurIRQPort, comCurStatPort, comCurDataPort, comIRQ

	public rm_kbd_int_vec, kbd_int, rm_break_vec
kbd_int		db	?	; interrupt number for IRQ1
rm_kbd_int_vec	dd	?	; original real mode vector for kbd int
rm_break_vec	dd	?	; original real mode vector for 1Bh vector
				;  invoked by Ctrl+Break

call_prot	dd	0
code_sel	dw	0

	; IPX related data

ipx		dd 	0	; ipx routine read mode address

sendECB		EventControlBlock	<>	; these 3 muse be consecutive
sendHeader	IPXHeader		<>
sendData	db IPX_MAX_PACKET dup(?)

recvECB		EventControlBlock	<>	; these 3 must be consecutive
recvHeader	IPXHeader		<>
recvData	db IPX_MAX_PACKET dup(?)

receivedPacket	dw	0

end_real	label	byte
		public	end_real

_RDATA		ends

_SERDATA	segment
;
; Original RM and PM IRQ4 vectors
;
	public	rm_irq_vec,pm_irq_off,pm_irq_sel,irq_int
rm_irq_vec	dd	?	; original real mode vector (segment in high
				;  word...of course)
pm_irq_off	dd	?	; original prot mode vector
pm_irq_sel	dw	?		; selector for same
irq_int		db	?	; interrupt number for IRQ level
	align	4

;
; Conventional memory block control.  Note that the real mode CS and DS
; values for our real mode IRQ4 handler are not necessarily the same as
; the address of the memory block.  This is because if necessary we back
; them off so the link-time offsets to code and data will still be correct
; at run time.  It is necessary to do this if the real mode code and data
; don't begin at the start of the protected mode segment (eg, if the
; -OFFSET 1000h link-time switch is used).
;
cbuf_seg	dw	?	; real mode paragraph addr of memory block
rm_csds		dw	?	; real mode CS and DS values
	align	4
comInPtr	dd	?	; offset in segment SS_DOSMEM of comIn
comOutPtr	dd	?	; offset in segment SS_DOSMEM of comOut
comFlagsPtr	dd	?	; offset in segment SS_DOSMEM of comFlags
mouseQueuePtr	dd	?	; offset in segment SS_DOSMEM of mouseQueue

sendECBPtr	dd	?	; offset in segment SS_DOSMEM of sendECB
recvECBPtr	dd	?	; offset in segment SS_DOSMEM of recvECB

irq		dd	DGROUP:kbdIrqFlag
		dw	SS_DATA
	public cbuf_seg, rm_csds, comInPtr, comOutPtr, comFlagsPtr, irq
	public mouseQueuePtr

_SERDATA	ends

_CODESEG	segment
		assume	cs:CGROUP,ds:DGROUP,es:DGROUP,ss:DGROUP

ComPortData	struc
    CPD_portMask	dw	?	; Mask for figuring out other
    					; ports for the channel. The number
					; being masked is 3fXh where X is
					; 8 through f
    CPD_level		dw	?	; Interrupt level (as far as
					; interrupt controller is concerned)
ComPortData	ends
ports		ComPortData	<0ffffh,4>	; COM1 (3f8, level 4)
		ComPortData	<0feffh,3>	; COM2 (2f8, level 3)
		ComPortData	<0ffefh,4>	; COM3 (3e8, level 4)
		ComPortData	<0feefh,3>	; COM4 (2e8, level 3)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call a driver function

CALLED BY:	GLOBAL (C)

PASS:		stack - function to call

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 8/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public MouseCallDriver
MouseCallDriver	proc	near
		push	ebp
		mov	ebp, esp
		push	es
		push	eax
		push	ebx
		push	ecx
		push	edx
	;
	; Fetch arguments.
	; 
		push	ds
		pop	es
	
		mov	eax, ss:[ebp+8]		
		mov	ebx, ss:[ebp+12]
		mov	ecx, ss:[ebp+16]
		mov	edx, ss:[ebp+20]
		mousecall ax

		pop	edx
		pop	ecx
		pop	ebx
		pop	eax
		pop	es
		pop	ebp
		ret
MouseCallDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseHideCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hide the curses

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 8/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public MouseHideCursor
MouseHideCursor	proc	near
;	mousecallProt	MOUSEHIDE
	mousecall	MOUSEHIDE
	ret
MouseHideCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseShowCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show the cursor

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 8/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public MouseShowCursor
MouseShowCursor	proc	near
;	mousecallProt	MOUSESHOW
	mousecall	MOUSESHOW
	ret
MouseShowCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseCallFromPretectedCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	setup to call mouse routine from Protected mode

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	eax, ebx, ecx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 8/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseCallFromProtectedCommon	proc	near
		; this is code taken from Pharlap manual
		; 386 | DOS-EXTENDER REFERENCE MANUAL page 120

		; now get the real mode interrrupt vector
		mov	cl, 33h	; MOUSE interrupt
		mov	ax, 2503h
		int	21h		; ebx = real mode address
		cmp	ebx, 0
		je	MCFPC_no_driver

		clr	eax
		mov	ax, bx
		and	ebx, 0ffff0000h
		shr	ebx, 12
		add	ebx, eax
		mov	ax, 0034h
		mov	es, ax
		cmp	byte ptr es:[ebx], 0cfh
		je	MCFPC_no_driver
		clc
MCFPC_done:
		ret
MCFPC_no_driver:
		stc
		jmp	MCFPC_done	
MouseCallFromProtectedCommon	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on the mouse

CALLED BY:	KbdHandleSys

PASS:		Nothing

RETURN:		eax is non-zero on success

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/20/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	MouseStart
MouseStart	proc	near
		push	bx
		push	cx
		push	dx
		push	es
		push	ds
		; save code selector

		mov	code_sel, cs

;		mov	ax, SS_DATA
;		mov	ds, ax
		mov	ax, SS_DOSMEM
		mov	es, ax		


		; initialize the queue	
		mov	ebx, ds:[mouseQueuePtr]
		mov	es:[ebx].mq_tail, INIT_QUEUE_OFFSET
		mov	es:[ebx].mq_head, INIT_QUEUE_OFFSET
		mov	es:[ebx].mq_numEvents, 0

		; now lets get the real mode link address
		; this is a pharlap system call
		mov	ax, 250dh
		int	21h
		mov	call_prot, eax		; save away address

		call	MouseCallFromProtectedCommon
		jc	no_driver
		; now we can initialize the mouse
		;
		; See if mouse attached. If AX returns 0, there's no mouse.
		;
		mousecall MOUSEINIT

		comment @
		; logitech mouse driver restores all registers on return
		; from function 0, so this test won't work
		tst	ax
		jz	MouseStartRet
		int	3
		@
;		mov	mouseFlags, MOUSEON

		;
		; Turn on the mouse (in mouse mode)
		;
		;mov	bx, 0
		;mousecall MOUSEMODE

		;
		; First set the text cursor. Preserve the foreground, but
		; set the background to be the mouse's assigned color: 4
		;
		mov	bx, 0		; software cursor
		mov	cx, 0000111111111111b
		mov	dx, 0100000000000000b
;		test	scrEtcFlags, SCR_ISMONO
;		jz	MS1
		;
		; Monochrome: nuke high bits on both foreground and background
		; attributes, and invert the low three bits of each. Should
		; result in inversion...
		;
		mov	cx, 0111011111111111b
		mov	dx, 0111011100000000b
MS1:
		mousecall MOUSETEXT

		mov	bx, ds:[rm_csds]
		shl	ebx, 16
		lea	bx, MouseSetupHandlerRM
		mov	ecx, ebx
		shr	ecx, 16
		lea	dx, MouseEvent	; get offset of handler
		push	cx
		mov	ecx, 1		; 1 WORD on stack
		mov	ax, 250eh
		int	21h		; call MouseSetupHandlerRM
		inc	esp		; preseve carry flag
		inc	esp
		jc	no_driver

		; 
		;
		; Set cursor boundaries. X boundaries already set.
		;
;		mov	dx, scrLines	; Fetch # of lines in screen
		mov	dx, 50
		sal	dx, 1		; *8 to get pixels
		sal	dx, 1
		sal	dx, 1
		dec	dx		; -1 since it's 0-origin...
		mov	cx, 0		; Min Y
		mousecall MOUSELIMY

		;
		; Install accelerator
		;
		;mov	dx, offset mouseAcc
		;mov	bx, 1		; Use given accelerator
		;mousecall MOUSEACCEL

		clr	cx
		clr	dx
		mousecall MOUSEWARP

		;
		; Find where the thing is currently
		;
		mousecall MOUSESTAT
		shr	cx, 1		; convert X pixels to chars
		shr	cx, 1
		shr	cx, 1

		shr	dx, 1		; convert Y pixels to chars
		shr	dx, 1
		shr	dx, 1

;		mousecall MOUSESHOW
;		mov	eax, 1
MouseStartRet:
		pop	ds
		pop	es
		pop	dx
		pop	cx
		pop	bx
		ret
no_driver:
		mov	eax, 0
		jmp	MouseStartRet
MouseStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Mouse_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the mouse to not respond to any events anymore

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/ 4/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Mouse_Exit	proc	near
	; es:dx should point to a handler, but since cx will be zero
	; it will never get called, so who cares where it points...
	clr	cx
	mousecall MOUSEHANDLE
	ret
Mouse_Exit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseGetNextEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the next event from the event buffer (if any)

CALLED BY:	GLOBAL

PASS:		buffer in which to put event data 

RETURN:		eax is non-zero if any events are available
		fills in buffer with event data if eax non-zero

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 3/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public MouseGetNextEvent
MouseGetNextEvent	proc	near
	;
	; Set up stack frame.
	; 
		push	ebp
		mov	ebp, esp
		push	edi
		push	esi
		push	es
		push	ds
		push	fs
	;
	; Fetch arguments.
	; 
		push	ds
		pop	es

		mov	edi, ss:[ebp+8]		; es:edi <- buffer

		mov	ax, SS_DOSMEM
		mov	fs, ax		

		clr	eax	; assume nothing in queue
		mov	ebx, ds:[mouseQueuePtr]
		cmp	byte ptr fs:[ebx].mq_numEvents, 0
		jz	MGNE_getStats		; just return current
						; mouse data
		movzx	esi, fs:[ebx].mq_head	; ds:dx = next queue element
		Update_Q fs:[ebx].mq_head, si
		dec	fs:[ebx].mq_numEvents
		; copy down 3 byte structure into buffer

		add	ebx, esi
		mov	al, fs:[ebx]
		mov	es:[edi], al
		inc	edi 
		inc	ebx
		mov	al, fs:[ebx]
		mov	es:[edi], al
		inc	edi 
		inc	ebx
		mov	al, fs:[ebx]
		mov	es:[edi], al
		mov	eax, 1
		jmp	MGNE_done
MGNE_getStats:
		mousecall	MOUSESTAT
		shr	cx, 3
		mov	es:[edi], cl
		inc	edi
		shr	dx, 3
		mov	es:[edi], dl
		inc	edi
		mov	byte ptr es:[edi], 1	; means no button change
		mov	eax, 1		; return an event found
MGNE_done:		
		pop	fs
		pop	ds
		pop	es
		pop	esi
		pop	edi
		pop	ebp	
		ret
MouseGetNextEvent	endp


_CODESEG	ends

_RCODESEG	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseSetupHandlerRM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	installs a handler for mouse events

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 2/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public MouseSetupHandlerRM
MouseSetupHandlerRM	proc	far
	push	bp		; argument on stack
	mov	bp, sp
	mov	ax, word ptr 6[bp]	; argument on stack = segment
	mov	es, ax
	mov	dx, offset MouseEvent	; es:dx = MouseEvent
	mov	cx, MOUSEALL
	mousecall MOUSEHANDLE
	clc
	pop	bp
	ret
MouseSetupHandlerRM	endp

_RCODESEG	ends

_CODESEG	segment
		assume	cs:CGROUP,ds:DGROUP,es:DGROUP,ss:DGROUP



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the appropriate communications port

CALLED BY:	Rpc_Init
PASS:		const char *portDesc = "p#,b#[,i#]"
			p#	= port number (1-4)
			b#	= baud rate
			i#	= interrupt level
RETURN:		non-zero if initialization successful.
DESTROYED:	AX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	7/20/92		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	Serial_Init
Serial_Init	proc	near
		push	ebp
		mov	ebp, esp
		push	edi
		push	esi
		push	ebx
		push	es
		mov	esi, ss:[ebp+8]	; ds:esi <- portDesc
		
		call	SerialDeterminePort
		jc	SI_fail
		call	SerialDetermineBaud
		jc	SI_fail
		call	SerialDetermineIRQ
		jc	SI_fail

		call	SerialProcessPortData

		; we pass in a flag on whether to do a full init or
		; a partial init (that is, everything up to here)
		mov	bx, ss:[ebp+12]
		cmp	bx, 0
		je	SI_succeed

		call	SerialCopyToConventional
		jc	SI_fail
		call	SerialHookInterrupts
		jc	SI_fail
SI_succeed:		
		mov	eax, 1
SI_done:
		pop	es
		pop	ebx
		pop	esi
		pop	edi
		leave
		ret
SI_fail:
		xor	eax, eax
		jmp	SI_done
Serial_Init	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDeterminePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the port number from port description string.

CALLED BY:	Serial_Init
PASS:		ds:esi	= port description string
RETURN:		carry set if port number invalid
		carry clear if port number ok:
			cs:edi	= ComPortData for the port
			ds:esi	= points past comma following port number
DESTROYED:	eax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	SerialDeterminePort
SerialDeterminePort proc near
	;
	; Fetch the first char of the descriptor. This must be a char between
	; 1 and 4, inclusive.
	; 
		xor	eax, eax
		lodsb			; al <- port number
		cmp	al, '1'
		jl	SDP_fail
		cmp	al, '4'
		jg	SDP_fail
	;
	; Skip over the comma that must follow the port number.
	; 
		cmp	byte ptr ds:[esi], ','
		jne	SDP_fail
		inc	esi
	;
	; Convert from ASCII to binary.
	; 
		sub	al, '1'
	;
	; Offset into the "ports" array and return the address of the
	; appropriate ComPortData structure in cs:edi.
	; 
		shl	eax, 2		; *4 (size of ComPortData)
		xchg	edi, eax	; cs:edi <- ComPortData
		add	edi, offset ports; (can't carry)
SDP_done:
		ret
SDP_fail:
		stc
		jmp	SDP_done
SerialDeterminePort endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDetermineBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the number at ds:esi into a number and see if that's
		a valid baud rate, returning the divisor for the rate if so.

CALLED BY:	Serial_Init
PASS:		ds:esi	= baud rate string (ending with null or comma)
RETURN:		carry set if invalid baud rate
		carry clear if baud rate is ok:
			ds:esi	= null terminator, or first char of interrupt
				  level
			edx	= divisor (low 16 bits are relevant)
DESTROYED:	eax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	SerialDetermineBaud
SerialDetermineBaud proc near
		xor	edx, edx
		mov	eax, edx		; clear high 3 bytes of eax
						;  for the loop...
SDB_charLoop:
		lodsb
		or	al, al
		jz	SDB_hitNullTerm
		cmp	al, ','
		je	SDB_haveBaud
		sub	al, '0'
		jb	SDB_error
		cmp	al, 9
		ja	SDB_error
		imul	edx, 10
		add	edx, eax
		jmp	SDB_charLoop
SDB_hitNullTerm:
		dec	esi		; point back to null
SDB_haveBaud:
	;
	; Blech. Isn't there some cleaner way to do this?
	; 
		xchg	eax, edx	; eax <- baud

	irp	baud, <300,1200,2400,4800,9600,19200,38400>
		mov	edx, BAUD_&baud
		cmp	eax, baud
		je	SDB_done	; (carry clear if branch taken)
	endm
SDB_error:
		stc
SDB_done:
		ret
SerialDetermineBaud		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDetermineIRQ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the interrupt level to be used for the port.

CALLED BY:	Serial_Init
PASS:		ds:esi	= remainder of port descriptor
		cs:edi	= ComPortData for selected port (contains default
			  interrupt level)
RETURN:		carry set on error
		carry clear if ok:
			al	= interrupt level for port
DESTROYED:	esi, ecx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	SerialDetermineIRQ
SerialDetermineIRQ proc	near
		push	edx
	;
	; Fetch the first character of the potential interrupt level.
	; 
		lodsb
		or	al, al
		jz	SDIRQ_useDefault	; => no interrupt level given,
						;  so return default for the
						;  port.
	;
	; Convert the first digit to binary.
	; 
		sub	al, '0'
		jb	SDIRQ_error	; => not numeric
		cmp	al, 9
		ja	SDIRQ_error	; => not numeric
		xor	ah, ah		; clear byte 2 of eax
		cwde			; clear high 2 bytes by sign-extension
	;
	; See if level is 2 digits.
	; 
		cmp	byte ptr ds:[esi], 0
		je	SDIRQ_saveIRQ	; => single digit; eax is level
	;
	; Multiply previous digit by 10 and add new digit to get level.
	; 
		imul	ecx, eax, 10
		lodsb
		sub	al, '0'
		jb	SDIRQ_error
		cmp	al, 9
		ja	SDIRQ_error
		xor	ah, ah		; clear byte 2 of eax
		cwde			; clear high 2 bytes of eax
		add	eax, ecx	; (can't carry)
SDIRQ_saveIRQ:
		mov	ds:[comIRQ], al
SDIRQ_done:
		pop	edx
		ret
SDIRQ_error:
		stc
		jmp	SDIRQ_done

SDIRQ_useDefault:
		mov	ax, cs:[edi].CPD_level
		cwd
		clc
		jmp	SDIRQ_saveIRQ
SerialDetermineIRQ endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialProcessPortData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process all the data we've gathered on the serial port we're
		to use.

CALLED BY:	Serial_Init
PASS:		eax	= interrupt level
		edx	= baud rate divisor
		cs:edi	= ComPortData
RETURN:		comCurDataPort, comCurStatPort, comCurIRQPort, comCurIENPort
			all initialized properly
		port line format and baud rate established
		port interrupts *not* enabled, but OUT2 set
DESTROYED:	edx, ebx, ecx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	SerialProcessPortData
SerialProcessPortData proc near
		push	eax		; save IRQ for snagging vector
		mov	bx, cs:[edi].CPD_portMask

	;
	; Set up comCurDataPort, comCurStatPort and comCurIRQPort
	; for ComInterrupt
	;
		mov	ax, COMDATAPORT
		and	ax, bx
		mov	ds:[comCurDataPort], ax

		mov	ax, COMSTATPORT
		and	ax, bx
		mov	ds:[comCurStatPort], ax

		mov	ax, COMIRQPORT
		and	ax, bx
		mov	ds:[comCurIRQPort], ax
		
		mov	ax, COMIENPORT
		and	ax, bx
		mov	ds:[comCurIENPort], ax

	;
	; Install the baud rate
	; 
		mov	ecx, edx		; save baud rate divisor

		mov	dx, COMLINEPORT
		and	dx, bx
		mov	al, mask SF_DLAB	; gain access to the divisor
						;  latch
		out	dx, al

		jmp	$+2

		xchg	eax, ecx		; ax <- divisor
		mov	dx, COMDLLPORT
		and	dx, bx
		out	dx, al			; ship low byte

		jmp	$+2

		inc	dx
		mov	al, ah
		out	dx, al			; ship high byte

	;
	; Make sure the interrupt enable port and data port are actually at the
	; appropriate addresses by clearing the Divisor Latch Access Bit in the
	; line control register.
	; 
	; Also makes sure the line is in the format we want:
	;	8 data bits
	;	1 stop bit
	;	no parity
	; qv. Options and Adapters vol. 2 for more info
	;
		mov	dx, COMLINEPORT
		and	dx, bx
		mov	al, (SP_NONE shl SF_PARITY) or (SL_8BITS shl SF_LENGTH)
		out	dx, al

	;
	; Turn on DTR, RTS and OUT2. The first 2 are on because that's
	; what terminals normally expect. OUT2 is on b/c it must be on
	; for interrupts to come through.
	;
		mov	dx, COMMODEMPORT
		and	dx, bx
		mov	al, COMDTR OR COMRTS OR COMOUT2
		out	dx, al

	;
	; Make sure the input buffer is clear and the interrupt-pending flag is
	; clear by reading the buffer now. If we don't and for some reason an
	; interrupt is already pending from the device, we're hosed.
	;
		mov	dx, ds:[comCurDataPort]
		in	al, dx

		pop	eax		; recover IRQ
		ret
SerialProcessPortData endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCopyToConventional
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the real-mode interrupt handler and data to conventional
		memory.

CALLED BY:	Serial_Init
PASS:		nothing
RETURN:		carry set on error
		carry clear if ok:
			cbuf_seg, rm_csds, comInPtr, comOutPtr, comFlagsPtr
				all set
DESTROYED:	ebx, esi, edi, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	SerialCopyToConventional
SerialCopyToConventional proc	near
		push	eax
		push	ecx
	;
	; Fetch the keyboard and break vectors before we copy things to
	; conventional memory so both we and the interrupt handler end up with
	; a copy...
	; 
		mov	ax, DX_HWIV_GET
		int	21h
		inc	al
		mov	ds:[kbd_int], al
		mov	cl, al
		mov	ax, DX_RMIV_GET
		int	21h
		mov	ds:[rm_kbd_int_vec], ebx
		mov	cl, KBD_BREAK_VEC
		mov	ax, DX_RMIV_GET
		int	21h
		mov	ds:[rm_break_vec], ebx
	;
	; Make sure the real-mode handler is within the first 64k (XXX: why
	; is this necessary? all jumps etc. should be near or short and
	; therefore position-independent...)
	; 
		lea	ebx, end_real	; (in _RDATA)
		test	ebx, 0ffff0000h
		jnz	SCTC_fail
		lea	ecx, start_real	; (in _RCODESEG)
		and	ecx, not 0fh	; round start down to nearest paragraph
		sub	ebx, ecx
		push	ecx		; save start of range to shift
		push	ebx		;  and # bytes
	;
	; Make room in conventional space by reducing maximum by that many
	; pages.
	; 
		add	ebx, 4095
		shr	ebx, 12
		mov	ecx, ebx
		mov	ebx, 3		; maximize conventional mem
		mov	ax, DX_MEM_USAGE
		int	21h		; ignore error, as we assume it
					;  means there's already enough room
					;  and max == min...
	;
	; Now allocate that many paragraphs in conventional memory.
	; 
		pop	ebx
		push	ebx
		add	ebx, 15
		shr	ebx, 4		; convert to paragraphs
		mov	ax, DX_REAL_ALLOC
		int	21h
		jc	SCTC_allocFailed
		
		mov	ds:[cbuf_seg], ax
	;
	; Figure a cs/ds for the real-mode code that will allow it to use
	; all its link-time offsets.
	; 
		pop	ecx		; ecx <- # bytes
		pop	ebx
		mov	esi, ebx	; save start for move...
		shr	ebx, 4
		sub	ax, bx
		mov	ds:[rm_csds], ax
	;
	; Now copy all that data to the conventional-memory block we allocated.
	; 
		mov	ax, SS_DOSMEM
		mov	es, ax
		movzx	edi, ds:[cbuf_seg]
		shl	edi, 4		; convert to linear address
		cld
		rep	movsb
	;
	; Calculate the protected-mode offsets of comIn, comOut and comFlags
	; 
		movzx	ebx, ds:[rm_csds]	; ebx <- rm_csds
		shl	ebx, 4		; convert to linear address

	irp	var, <comIn, comOut, comFlags, mouseQueue, sendECB, recvECB>
		lea	eax, var
		add	eax, ebx
		mov	ds:[var&Ptr], eax
	endm
	;
	; Set up far pointer to kbdIrqFlag for others to use.
	; 
		lea	eax, kbdIrqFlag
		add	eax, ebx
		mov	ds:[irq], eax
		mov	word ptr ds:[irq+4], SS_DOSMEM

		clc			; happiness
SCTC_done:
		pop	ecx
		pop	eax
		ret
SCTC_allocFailed:
		add	esp, 8		; clear start and size of rm block off
					;  stack
SCTC_fail:
		stc			; signal our distress
		jmp	SCTC_done
SerialCopyToConventional endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HookKeyboardInterrupts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hook the keyboard inetrrupts

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HookKeyboardInterrupts	proc	near
	;
	; Install keyboard interceptor.
	; 
		mov	bx, ds:[rm_csds]
		shl	ebx, 16
		lea	bx, SerialKbdInterrupt	; ebx <- rm handler
		mov	cl, ds:[kbd_int]
		mov	ax, DX_RMIV_SET
		int	21h

		lea	bx, SerialBreakInterrupt; ebx <- rm handler
		mov	cl, KBD_BREAK_VEC
		mov	ax, DX_RMIV_SET
		int	21h		
		ret
HookKeyboardInterrupts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnhookKeyboardInterrupts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the keyboard interrupts back to what they once were

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnhookKeyboardInterrupts	proc	near

		mov	cl, ds:[kbd_int]
		mov	ebx, ds:[rm_kbd_int_vec]
		mov	ax, DX_RMIV_SET
		int	21h
		
		mov	cl, KBD_BREAK_VEC
		mov	ebx, ds:[rm_break_vec]
		mov	ax, DX_RMIV_SET
		int	21h
		ret
UnhookKeyboardInterrupts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialHookInterrupts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the real- and protected-mode interrupts for the com
		port, now everything is set up...

CALLED BY:	Serial_Init
PASS:		eax	= IRQ for the port
		rm_csds	= segment of real-mode handler
RETURN:		carry set if couldn't grab interrupts
DESTROYED:	eax, ecx, ebx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	SerialHookInterrupts
SerialHookInterrupts proc near
		mov	ecx, eax	; save IRQ
	;
	; Figure vector to use for the serial port
	; 
		mov	ax, DX_HWIV_GET
		int	21h
		cmp	ecx, 8
		jb	figureVector
		sub	ecx, 8		; adjust to be relative to starting
					;  IRQ of 2nd interrupt controller
		mov	al, ah
		or	al, al
		jz	SHI_error	; => machine has no such interrupt
figureVector:
		add	al, cl
		mov	ds:[irq_int], al
	;
	; Fetch current vector values.
	; 
		mov	cl, al
		mov	ax, DX_RMIV_GET
		int	21h
		mov	ds:[rm_irq_vec], ebx
		
		mov	ax, DX_PMIV_GET
		int	21h
		mov	ds:[pm_irq_off], ebx
		mov	ds:[pm_irq_sel], es
	;
	; Install both interrupt handlers at the same time.
	; 
		push	ds
		mov	bx, ds:[rm_csds]
		shl	ebx, 16
		lea	bx, SerialRealInterrupt	; ebx <- rm handler
		lea	edx, SerialProtInterrupt
		push	cs
		pop	ds		; ds:edx <- pm handler
		mov	ax, DX_RPMIV_SET
		int	21h
		pop	ds
	;
	; Install keyboard interceptor.
	; 
		call	HookKeyboardInterrupts
	;
	; Now enable interrupts in the appropriate PIC and the port itself.
	; We enable receiver interrupts only, as we don't care about line
	; errors (the Rpc module will deal with bogus packets), and we've
	; nothing to transmit.
	; 
		mov	cl, ds:[comIRQ]
		mov	dx, 21h		; assume 0-7
		cmp	cl, 8
		jb	SHI_havePIC
		sub	cl, 8
		mov	dx, 0a1h
SHI_havePIC:
		in	al, dx
		mov	ah, not 1
		shl	ah, cl
		and	al, ah
		out	dx, al
		
		mov	dx, ds:[comCurIENPort]
		mov	al, COMRECVENABLE
		out	dx, al
		clc
SHI_done:		
		ret
SHI_error:
		stc
		jmp	SHI_done
SerialHookInterrupts endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismantle the serial port manipulation.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	eax, ecx, edx, fs

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	Serial_Exit
Serial_Exit	proc	near
		push	ebx
	;
	; Wait for output to drain.
	;
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	ebx, ds:[comOutPtr]
SE_drainLoop:
		cmp	fs:[ebx].numChars, 0
		jne	SE_drainLoop
	;
	; Mask out the interrupt level in the appropriate PIC.
	; 
		mov	cl, ds:[comIRQ]
		mov	dx, 21h
		cmp	cl, 8
		jb	SE_havePIC
		sub	cl, 8
		mov	dx, 0a1h
SE_havePIC:
		in	al, dx
		mov	ah, 1
		shl	ah, cl
		or	al, ah
		out	dx, al
	;
	; Disable interrupts for the port.
	;
		mov	dx, ds:[comCurIENPort]
		xor	al, al
		out	dx, al
		
		add	dx, COMMODEMPORT - COMIENPORT
		out	dx, al
	;
	; Reset the interrupt vectors.
	; 
		mov	cl, ds:[irq_int]
		push	ds
		mov	ebx, ds:[rm_irq_vec]
		lds	edx, pword ptr ds:[pm_irq_off]
		mov	ax, DX_RPMIV_SET
		int	21h
		pop	ds

		call	UnhookKeyboardInterrupts
	;
	; Free up the conventional memory block.
	; 
		mov	cx, ds:[cbuf_seg]
		mov	ax, DX_REAL_FREE
		int	21h
		pop	ebx
		call	Mouse_Exit
		ret
Serial_Exit	endp

_CODESEG	ends

_RCODESEG	segment

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a mouse event

CALLED BY:	Mouse driver

PASS:		CS	= our code segment
		AX	= mask of event type (see beginning of file)
		BX	= current button state:
				bit 0 = left button
				bit 1 = right button
				bit 2 = middle button
		CX	= current X position (in pixels)
		DX	= current Y position (in pixels)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	If the event contains mouse motion, update our idea of where the
	cursor is. The driver takes care of the cursor.

	If it's a mouse button, we need to shove a string into the
	input stream.\M-m<button><x><y>

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/20/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
	public MouseEvent
MouseEvent	proc	far

		nop
		nop
		nop
		push	ds
		push	cs
		pop	ds
		push	bx

		;
		; The characters are in an 8x8 box, so divide both coordinates
		; by 8 to get the character position.
		;
		; if the queue is full then ignore the click
		lea	bx, mouseQueue
		cmp	ds:[bx].mq_numEvents, MAX_EVENTS
		je	MERet
		push	dx
		mov	dx, ds:[bx].mq_tail
		Update_Q ds:[bx].mq_tail, dx
		inc	ds:[bx].mq_numEvents
		add	bx, dx
		pop	dx
		shr	cx, 1
		shr	cx, 1
		shr	cx, 1
		mov	ds:[bx].xcoord, cl
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1
		mov	ds:[bx].ycoord, dl
		mov	ds:[bx].button, al
MERet:
		pop	bx
		pop	ds
		ret
MouseEvent	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialRealInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an interrupt from the selected serial device

CALLED BY:	INTERNAL (and SPONTANEOUS)

PASS:		CS set to proper segment

RETURN:		Nothing

DESTROYED:	Nothing (I Hope)

PSEUDO CODE/STRATEGY:
	While interrupt pending
		read status
		if data available, read and queue. send xoff if too much.
		if can send and have data to send, send it.
	loop

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	It should probably check for buffer overrun and do something about
	it...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision
	adam	6/20/88		Made use of OUT2 to make sure the IRQ line
				goes all the way down before coming back up
				again if more than one interrupt is pending.
    	adam	6/88	    	That didn't work. Now disarms adapter and
				rearms it on exit.
				
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	SerialRealInterrupt
SerialRealInterrupt	proc	far
		push	ax
		push	bx
		push	dx
		push	ds
	;
	; Preserve current control register (in case we interrupted
	; ourselves -- we can't just write protect on exit...)
	;
		mov	ax, cs
		mov	ds, ax			; set up ds for our own ease

	;
	; Force the interrupt output of the chip low by turning
	; off all interrupts. This makes sure the IRQ line makes it
	; all the way down before coming back up if an interrupt comes
	; in while we're in here.
	;
		mov	dx, ds:[comCurIENPort]
		xor	al, al
		out	dx, al

	;
	; We've turned off interrupts from this device, so it's ok to
	; turn interrupts on now.
	;
		sti
	;
	; Fetch current status bits
	;
		add	dx, COMSTATPORT - COMIENPORT
		in	al, dx
		push	ax			; Save for SRI_checkTrans

		test	al, COMDAVAIL
		jz	SRI_checkTrans

	;
	; Data waiting. Fetch character and process it according to our
	; current state.
	;
		add	dx, COMDATAPORT - COMSTATPORT
		in	al, dx			; Fetch the character

	;
	; Store the byte in AL into the comIn buffer.
	; 
		mov	bx, ds:[comIn].tail
		mov	ds:[comIn].data[bx],al	; Stuff it
		Update	ds:[comIn].tail, bx
    	    	inc	ds:[comIn].numChars
		
SRI_checkTrans:
	;
	; See if we can send data. Original status stored on the
	; stack, so use that.
	;
		pop	ax
		test	al, COMTHRE
		jnz	SRI_send

SRI_done:
	;
	; Signal end-of-interrupt to interrupt controller(s), restore
	; state and return.
	;
		mov	al, ICEOI
		out	ICEOIPORT, al

		cmp	ds:[comIRQ], 8
		jb	SRI_enableInts
		
		out	ICEOIPORT2, al
SRI_enableInts:

	;
	; Reenable interrupts from the chip. If a character came in or the
	; transmitter became ready while we were in here, this will generate
	; an interrupt right away...
	; 
	; Note that we only enable the transmitter interrupt if we actually
	; expect an interrupt to come in. Otherwise, we will loop infinitely
	; getting transmitter interrupts each time we re-enable interrupts for
	; the device.
	;
		mov	dx, ds:[comCurIENPort]
		mov	al, COMRECVENABLE
		isset?	IRQPEND
		jz	SRI_reArm
		or	al, COMTRANSENABLE
SRI_reArm:
 		out	dx, al

		pop	ds
		pop	dx
		pop	bx
		pop	ax
		iret

SRI_send:
	;
	; Transmitter ready for more. If no characters
	; queued, clear the IRQPEND flag so we know we have to prime
	; the serial line again.
	;
		cmp	ds:[comOut].numChars, 0
		jz	SRI_noTrans

		mov	bx, ds:[comOut].head	; Fetch char at head
		mov	al, ds:[comOut].data[bx]
		mov	dx, ds:[comCurDataPort]
		out	dx, al			; and send it
		Update	ds:[comOut].head, bx
		dec	ds:[comOut].numChars
		set	IRQPEND			; s/b set, but better safe...
		jmp	SRI_done

SRI_noTrans:
	;
	; Nothing transmittable -- clear the IRQPEND flag, so we know no
	; interrupt is coming, and return.
	;
		reset	IRQPEND
		jmp	SRI_done

SerialRealInterrupt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialKbdInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interceptor for the keyboard interrupt to detect and remove
		Ctrl+C from the input buffer.

CALLED BY:	IRQ 1
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialKbdInterrupt proc	far
	;
	; Save the registers we'll be needing.
	; 
		push	bx
		push	ds
		push	es
	;
	; Point to our code/data segment.
	; 
		mov	bx, cs
		mov	ds, bx
	;
	; Pass off to the previous interrupt handler.
	; 
		pushf
		call	ds:[rm_kbd_int_vec]
	;
	; See if there's anything in the input buffer.
	; 
		mov	bx, 40h
		mov	es, bx
		mov	bx, es:[KBD_TAIL_PTR]
		cmp	bx, es:[KBD_HEAD_PTR]
		je	done
	;
	; There is, so we want to back up BX to the last char in the buffer,
	; dealing with the problem of wrapping around to the end...
	; 
		cmp	bx, es:[KBD_START_PTR]
		jne	pointToLast
		mov	bx, es:[KBD_END_PTR]	; es:bx <- byte after the buffer
pointToLast:
		dec	bx			; entries are char, then
		dec	bx			;  scan code
		cmp	byte ptr es:[bx], 3	; control-C?
		je	flagBreak
		cmp	word ptr es:[bx], 0	; Ctrl+Break hit?
		jne	done
flagBreak:
	;
	; Found a Ctrl+C or Ctrl+Break -- biff it (by backing up the tail
	; pointer) and set the flag indicating Ctrl+C has been hit.
	; 
		mov	es:[KBD_TAIL_PTR], bx
		mov	ds:[kbdIrqFlag], -1
done:
		pop	es
		pop	ds
		pop	bx
		iret
SerialKbdInterrupt endp
	public SerialKbdInterrupt

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialBreakInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a do-nothing interceptor that exists just to keep
		control away from DOS.

CALLED BY:	INT 1Bh
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The flagging of the interrupt is taken care of by
		SerialKbdInterrupt, which detects the word of 0 the
		interrupt handler puts in the input buffer and removes it,
		setting the kbdIrqFlag at the same time.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialBreakInterrupt proc far
		iret
SerialBreakInterrupt endp

_RCODESEG	ends

_CODESEG	segment


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialProtInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an interrupt from the selected serial device

CALLED BY:	INTERNAL (and SPONTANEOUS)

PASS:		CS set to proper segment

RETURN:		Nothing

DESTROYED:	Nothing (I Hope)

PSEUDO CODE/STRATEGY:
	While interrupt pending
		read status
		if data available, read and queue. send xoff if too much.
		if can send and have data to send, send it.
	loop

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	It should probably check for buffer overrun and do something about
	it...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision
	adam	6/20/88		Made use of OUT2 to make sure the IRQ line
				goes all the way down before coming back up
				again if more than one interrupt is pending.
    	adam	6/88	    	That didn't work. Now disarms adapter and
				rearms it on exit.
				
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	SerialProtInterrupt
SerialProtInterrupt	proc	far
		push	eax
		push	ebx
		push	edx
		push	ds
		push	es
	;
	; Preserve current control register (in case we interrupted
	; ourselves -- we can't just write protect on exit...)
	;
		mov	ax, SS_DATA
		mov	ds, ax
		mov	ax, SS_DOSMEM
		mov	es, ax

	;
	; Force the interrupt output of the chip low by turning
	; off all interrupts. This makes sure the IRQ line makes it
	; all the way down before coming back up if an interrupt comes
	; in while we're in here.
	;
		mov	dx, ds:[comCurIENPort]
		xor	al, al
		out	dx, al

	;
	; We've turned off interrupts from this device, so it's ok to
	; turn interrupts on now.
	;
		sti
	;
	; Fetch current status bits
	;
		add	dx, COMSTATPORT - COMIENPORT
		in	al, dx
		push	eax			; Save for SPI_checkTrans

		test	al, COMDAVAIL
		jz	SPI_checkTrans

	;
	; Data waiting. Fetch character and process it according to our
	; current state.
	;
		add	dx, COMDATAPORT - COMSTATPORT
		in	al, dx			; Fetch the character

	;
	; Store the byte in AL into the comIn buffer.
	; 
		mov	ebx, ds:[comInPtr]
		movzx	edx, es:[ebx].tail
		mov	es:[ebx].data[edx],al	; Stuff it
		Update	es:[ebx].tail, dx
    	    	inc	es:[ebx].numChars
		
SPI_checkTrans:
	;
	; See if we can send data. Original status stored on the
	; stack, so use that.
	;
		pop	eax
		test	al, COMTHRE
		jnz	SPI_send

SPI_done:
	;
	; Signal end-of-interrupt to interrupt controller, restore
	; state and return.
	;
		mov	al, ICEOI
		out	ICEOIPORT, al
		
		cmp	ds:[comIRQ], 8
		jb	SPI_enableInts
		
		out	ICEOIPORT2, al
SPI_enableInts:
	;
	; Reenable interrupts from the chip. If a character came in or the
	; transmitter became ready while we were in here, this will generate
	; an interrupt right away...
	; 
	; Note that we only enable the transmitter interrupt if we actually
	; expect an interrupt to come in. Otherwise, we will loop infinitely
	; getting transmitter interrupts each time we re-enable interrupts for
	; the device.
	;
		mov	dx, ds:[comCurIENPort]
		mov	al, COMRECVENABLE
		mov	ebx, ds:[comFlagsPtr]
		test	byte ptr es:[ebx], mask IRQPEND
		jz	SPI_reArm
		or	al, COMTRANSENABLE
SPI_reArm:
 		out	dx, al

		pop	es
		pop	ds
		pop	edx
		pop	ebx
		pop	eax
		iretd

SPI_send:
	;
	; Transmitter ready for more. If no characters
	; queued, clear the IRQPEND flag so we know we have to prime
	; the serial line again.
	;
		mov	ebx, ds:[comOutPtr]
		cmp	es:[ebx].numChars, 0
		jz	SPI_noTrans

		push	esi
		movzx	esi, es:[ebx].head	; Fetch char at head
		mov	al, es:[ebx].data[esi]
		mov	dx, ds:[comCurDataPort]
		out	dx, al			; and send it
		Update	es:[ebx].head, si
		dec	es:[ebx].numChars
		pop	esi
		mov	ebx, ds:[comFlagsPtr]
		or	byte ptr es:[ebx], mask IRQPEND
						; s/b set, but better safe...
		jmp	SPI_done

SPI_noTrans:
	;
	; Nothing transmittable -- clear the IRQPEND flag, so we know no
	; interrupt is coming, and return.
	;
		mov	ebx, ds:[comFlagsPtr]
		and	byte ptr es:[ebx], not mask IRQPEND
		jmp	SPI_done

SerialProtInterrupt endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a byte from the serial device, if any there.

CALLED BY:	Main

PASS:		Nothing

RETURN:		Z = 1 if nothing there, else
		Z = 0 and AL contains byte.

DESTROYED:	AL

PSEUDO CODE/STRATEGY:
	See if the char count for the input buffer is non-zero.
	If so, there's a byte available, so return it, stupid.
		If this reduces the number of characters to the low water
		mark, and we're supposed to send an XON, send it.
	Else leave Z set and return.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	SerialRead
SerialRead	proc	near
		push	ebx
		push	esi

		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	esi, ds:[comInPtr]
		cmp	fs:[esi].numChars, 0		; Anything waiting?
		jz	SR_done		; Nope

		movzx	ebx, fs:[esi].head
		mov	al, fs:[esi].data[ebx]
		dec	fs:[esi].numChars
		Update	fs:[esi].head, bx
ComReadRetNZ:
		or	bl, 1			; Make sure Z is clear
SR_done:
		pop	esi
		pop	ebx
		ret
SerialRead	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the serial port.

CALLED BY:	Main

PASS:		AL = the byte to write

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Wait for the port to become ready.
	Write the data byte.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This should also be interrupt driven, eventually, methinks.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	SerialWrite
SerialWrite	proc	near
		push	eax
		push	ebx
		push	edx
		push	esi

		mov	si, SS_DOSMEM
		mov	fs, si
		mov	esi, ds:[comOutPtr]

		cli			; So we don't miss the interrupt...

SW_queue:
		movzx	ebx, fs:[esi].tail
		mov	fs:[esi].data[ebx], al
		Update	fs:[esi].tail, bx
		inc	fs:[esi].numChars
		mov	esi, ds:[comFlagsPtr]
		test	byte ptr fs:[esi], mask IRQPEND
		jz	SW_forceInt	; No interrupt will come -- force one
					; to transmit first character
SW_done:
		sti
		pop	esi
		pop	edx
		pop	ebx
		pop	eax
		ret

SW_forceInt:
		mov	dx, ds:[comCurIENPort]
		mov	al, COMRECVENABLE OR COMTRANSENABLE
		out	dx, al
		or	byte ptr fs:[esi], mask IRQPEND
					; Note interrupt arriving
		jmp	SW_done
SerialWrite	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Read
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block of bytes from the serial line

CALLED BY:	Rpc_Wait

PASS:		void	*buffer	= place to which to read the bytes
		int	bufSize	= number of bytes to read

RETURN:		Nothing

DESTROYED:	DI, CX, AX, DF = 0

PSEUDO CODE/STRATEGY:
	Call Com_Read until CX goes to 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
		public	Serial_Read
Serial_Read	proc	near
	;
	; Set up stack frame.
	; 
		push	ebp
		mov	ebp, esp
		push	edi
	;
	; Fetch arguments.
	; 
		push	ds
		pop	es
		mov	edi, ss:[ebp+8]		; es:edi <- buffer
		mov	ecx, ss:[ebp+12]	; ecx <- bufSize

		cld
		jcxz	SRB_done		; => read everything
SRB_loop:
		call	SerialRead
		jz	SRB_loop		; => no byte available
		stosb				; store fetched byte...
		loop	SRB_loop		;  and loop for more
SRB_done:
		mov	eax, ss:[ebp+12]	; no EOF, so just return #
						;  we were supposed to read.
		pop	edi
		pop	ebp
		ret
Serial_Read	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_WriteV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a block of data from a scatter/gather vector

CALLED BY:	EXTERNAL

PASS:		struct iovec *iov	= vector of buffers to write
		int len			= elements in the vector

RETURN:		Nothing

DESTROYED:	SI, CX, AX, DF = 0

PSEUDO CODE/STRATEGY:
	Call Com_Write repeatedly until CX is 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
iovec	struc
    iov_base	dd	?	; base of buffer
    iov_len	dd	?	; number of bytes in same
iovec	ends

		public	Serial_WriteV
Serial_WriteV	proc	near
	;
	; Set up frame and fetch args.
	; 
		push	ebp
		mov	ebp, esp
		push	esi
		
		mov	esi, ss:[ebp+8]	; ds:esi <- iov
		mov	ecx, ss:[ebp+12]; ecx <- len
	;
	; Loop through all the vectors. edx accumulates the number of bytes
	; written so far.
	; 
		xor	edx, edx
		jcxz	SWV_done	; => no vectors, so done
SWV_vectorLoop:
	;
	; Save address of current vector and fetch its pointer and count.
	; 
		push	esi
		push	ecx
		mov	ecx, ds:[esi].iov_len
		mov	esi, ds:[esi].iov_base
		jcxz	SWV_nextIOV
SWV_byteLoop:
	;
	; Fetch and write the next byte.
	; 
		lodsb
		call	SerialWrite
		inc	edx		; another one gone...
		loop	SWV_byteLoop
SWV_nextIOV:
	;
	; Advance to the next vector.
	; 
		pop	ecx
		pop	esi
		add	esi, size iovec
		loop	SWV_vectorLoop
SWV_done:
	;
	; Return the number of bytes written after dismantling the stack frame.
	; 
		xchg	eax, edx	; eax <- bytes written
		pop	esi
		pop	ebp
		ret
Serial_WriteV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there are any characters available from the serial
		port.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		number of chars available
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	Serial_Check
Serial_Check	proc	near
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	eax, ds:[comInPtr]
		movzx	eax, fs:[eax].numChars
		ret
Serial_Check	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_RsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	run geos through the stub on the remote machine

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	send the swat stub a startup signal

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Serial_RsCommon	proc	near
	mov	al, 1bh		; escape character
	call	SerialWrite
	mov	al, 'R'		; the restart
	call	SerialWrite
	mov	al, 'S'
	call	SerialWrite
	ret
Serial_RsCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Rs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	run geos through the stub on the remote machine

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	send the swat stub a startup signal

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public Serial_Rs
Serial_Rs	proc	near
	call	Serial_RsCommon
	mov	al, 20h
	call	SerialWrite
	ret
Serial_Rs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Rss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	run geos through the stub on the remote machine

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	send the swat stub a startup signal

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public Serial_Rss
Serial_Rss	proc	near
	call	Serial_RsCommon
	mov	al, 21h
	call	SerialWrite
	ret
Serial_Rss	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Rsn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	run geos through the stub on the remote machine

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	send the swat stub a startup signal

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public Serial_Rsn
Serial_Rsn	proc	near
	call	Serial_RsCommon
	mov	al, 22h
	call	SerialWrite
	ret
Serial_Rsn	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Serial_Rssn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	run geos through the stub on the remote machine

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	send the swat stub a startup signal

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 6/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public Serial_Rssn
Serial_Rssn	proc	near
	call	Serial_RsCommon
	mov	al, 23h
	call	SerialWrite
	ret
Serial_Rssn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PokeMDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give control back to MDB so we can look at things.

CALLED BY:	DbgMeCmd
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	PokeMDB
PokeMDB		proc	near
		int	3
		ret
PokeMDB		endp

_CODESEG	ends

;;;;;;;;;IPX stuff;;;;;;;;;;;;;;;;;



_CODESEG	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_Check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check to see if IPX is loaded

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/22/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IPX_INSTALL_CHECK equ 7a00h

Ipx_Check	proc	near
		push	ebx
		push	ecx
		push	edx
		push	es
		push	ds

	; first set up our read mode/protected mode link	
		call	SerialCopyToConventional

	; now use pharlap to make a real-mode call from portected mode
	; IpxCheckRM is a real mode routine that does the actual check
	; to see if IPX is installed
	; int 21h, function 2510h does this real-mode call for us

	; we need to construct a real-mode address for IpxCheckRM
		mov	bx, ds:[rm_csds]
		shl	ebx, 16
		lea	bx, IpxCheckRM	; ebx = real mode address

		mov	ecx, 0		; 0 WORDS on stack
		sub	esp, 24		; size of register block of paramters
		mov	edx, esp
		mov	ax, ss
		mov	ds, ax
		mov	ax, 2510h
		int	21h		; call IpxCheckRM
		add	esp, 24		; restore esp

	; al contains a return value from IpxCheckRM
		and	eax, 000000ffh	; set up return value

		pop	ds
		pop	es
		pop	edx
		pop	ecx
		pop	ebx
		ret
Ipx_Check	endp
	public Ipx_Check

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallIpx
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make a call to the IPX routine

CALLED BY:	GLOBAL

PASS:		ss:[ebp+8] = 	eax value
		ss:[ebp+12] = 	ebx value
		ss:[ebp+12] = 	edx value
		ss:[ebp+12] = 	esdi value
		ss:[ebp+12] = 	essivalue

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
			use the pharlap int 21, 2510h routine to call the
			real mode IPX routine from protected mode
KNOWN BUGS/SIDEFFECTS/IDEAS:
			I originally wrote this routine to be called from C
			so that's why the arguments are passed on the stack
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/22/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallIpx	proc	near
		push	ebp
		mov	ebp, esp	; ss:ebp is our stack frame
		push	ebx
		push	ecx
		push	esi
		push	edi
		push	ds

	; we set up a paramters block on the stack to allow us to
	; pass and receive return values for registers through the
	; pharlap call to the real-mode ipx routine

		sub	esp, 24	; size of parameter block (register values)

	; so we grab values off of the stack and put them into our
	; paramter buffer

		mov	eax, ss:[ebp+20]	; esdi value
		mov	di, ax			; di value
		shr	eax, 16
		mov	ss:[esp+2], ax

;		mov	ss:[esp], ax		; TEMPORARY

		mov	eax, ss:[ebp+8]	; ax value
		mov	ss:[esp+8], eax

		mov	eax, ss:[ebp+12]; bx value
		mov	ss:[esp+12], eax

		mov	eax, ss:[ebp+16]; dx value
		mov	ss:[esp+20], eax	

		mov	si, ss:[ebp+24]	; get si value off of stack

	; now fetch the real-mode address of the ipx routine
		mov	ax, SS_DOSMEM
		mov	fs, ax
		movzx	edx, ds:[rm_csds]
		shl	edx, 4
		lea	ebx, ipx
		add	edx, ebx
		mov	ebx, fs:[edx] ; ebx = real-mode address of ipx routine

		mov	ecx, 0	; we are passing zero extra data to the
				; ipx routine

		mov	edx, esp
		mov	ax, ss
		mov	ds, ax	; ds:edx = buffer with regster values in it
		mov	eax, 2510h	;  real-mode call fuction
		int	21h		;  make the damn call (finally)

		mov	edx, ss:[esp+20]	; must get edx return value
						; from the paramter block
		add	esp, 24		; restore the stack

		pop	ds
		pop	edi
		pop	esi
		pop	ecx
		pop	ebx
		pop	ebp
		ret
CallIpx	endp
	public	CallIpx





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize our IPX data strucutures

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	hook the keyboard interrrupts
			initalize the ECB data structures and IPXHeeaders
				for sendECB and recvECB
			open up the socket for communication
			tell the socket we are ready to recive packets

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

extrn parsehexaddress:near

Ipx_Init	proc	near
		push	ebp
		mov	ebp, esp	; ss:[ebp] is our stack block


		sub	esp, 12		; buffer to hold data from parsehex
		mov	esi, esp

	; hook the keyboard interrupts, somebody has to do it
		call	HookKeyboardInterrupts

	; first lets set up pointers to sendECB and recvECB
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	ebx, ds:[sendECBPtr]	; fs:ebx = sendECB
		mov	edx, ds:[recvECBPtr]	; fs:edx = recvECB

	; now esatblish our service routines
		mov	cx, ds:[rm_csds]
		shl	ecx, 16	
		lea	cx, IPXDummyRoutine	; ebx = real mode address
		mov	fs:[ebx].ECB_serviceRoutine, ecx
		lea	cx, IpxReceivePacket
		mov	fs:[edx].ECB_serviceRoutine, ecx

	; put the header and data addresses into the ECBs
		lea	cx, sendHeader
		mov	fs:[ebx].ECB_Header_data, ecx
		mov	fs:[ebx].ECB_Header_size, size sendHeader

		lea	cx, sendData
		mov	fs:[ebx].ECB_Data_data, ecx
		mov	fs:[ebx].ECB_Data_size, size sendData

		lea	cx, recvHeader
		mov	fs:[edx].ECB_Header_data, ecx
		mov	fs:[edx].ECB_Header_size, size recvHeader
	
		lea	cx, recvData
		mov	fs:[edx].ECB_Data_data, ecx
		mov	fs:[edx].ECB_Data_size, size recvData

	; now intialize a few other paramters of use
		mov	fs:[ebx].ECB_inUse, 0
		mov	fs:[edx].ECB_inUse, 0

		mov	fs:[ebx].ECB_complete, 0
		mov	fs:[edx].ECB_complete, 0

		mov	fs:[ebx].ECB_socket, IPX_SOCKET_NUM
		mov	fs:[edx].ECB_socket, IPX_SOCKET_NUM

		mov	fs:[ebx].ECB_numFragments, 2
		mov	fs:[edx].ECB_numFragments, 2

	; parse the passed in IPX address of the stub's IPX node
		push	edx	; save this value as parsehexaddress trashes it
		push	esi		; buffer on stack
		mov	ecx, ss:[ebp+8]	; character string of netware address
		push	ecx	
		call	parsehexaddress
		add	esp, 8	; pop off arguments
		pop	edx

	; the localNode field should now be filled in with the node parsed
		mov	eax, ss:[esp+4] ; get first 4 bytes of node address
		mov	fs:[ebx+28], eax	; ECB_localNode
		mov	fs:[edx+28], eax	; ECB_localNode
		mov	ax, ss:[esp+8]	; get last 2 bytes of node address
		mov	fs:[ebx+32], ax		; ECB_localNode+4
		mov	fs:[edx+32], ax		; ECB_localNode+4

	; now advance the pointers to the Headers
		add	ebx, size EventControlBlock	; fs:ebx = sendHeader
		add	edx, size EventControlBlock	; fs:edx = recvHeader

		mov	fs:[ebx].IPXH_packetType, IPXPT_DATA
		mov	fs:[edx].IPXH_packetType, IPXPT_DATA
	
	 	add	ebx, 6	; advance the pointers to point into the Header
		add	edx, 6	; structure so we can copy the parsed address

	; we move the address into 4 places, a src and dest address
	; for sendECB and recvECB, its 12 bytes long, so we do it in
	; 3 dword chunks
		mov	eax, ss:[esp]
		mov	fs:[ebx], eax
		mov	fs:[edx], eax
		mov	fs:[ebx+12], eax
		mov	fs:[edx+12], eax

		mov	eax, ss:[esp+4]
		mov	fs:[ebx+4], eax
		mov	fs:[edx+4], eax
		mov	fs:[ebx+16], eax
		mov	fs:[edx+16], eax

		mov	eax, ss:[esp+8]
		mov	fs:[ebx+8], eax
		mov	fs:[edx+8], eax
		mov	fs:[ebx+20], eax
		mov	fs:[edx+20], eax


	; get real mode address of recvECB
		mov	dx, ds:[rm_csds]
		shl	edx, 16
		lea	ebx, recvECB
		add	edx, ebx
	
	; lets open up a socket to receive message on
		push	edx	; save, as CallIpx will trash it
		push	edx
		push	edx
		push	IPX_SOCKET_NUM
		push	IPXF_OPEN_SOCKET
		push	0
		call	CallIpx
		add	esp, 20	; pop off agruments
		pop	edx	; restore for next call to CallIpx
	
	; tell IPX we are ready to receive a packet
		push	edx	; real mode address of recvECB
		push	edx	; es:di value
		push	eax	; random value
		push	IPXF_RECEIVE_PACKET
		push	eax	; random value
		call	CallIpx	
		add	esp, 20	; pop off agruments

		add	esp, 12	; restore the stack
		pop	ebp
		ret
Ipx_Init	endp
	public Ipx_Init



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clean up things

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	the SOCKET will automatically be close when we
			exit
			unhook the keyboard interrupts
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/25/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Ipx_Exit	proc	near

		; first lets restore the keyboard interrupts
		call	UnhookKeyboardInterrupts
		call	Mouse_Exit
		ret
Ipx_Exit	endp
	public Ipx_Exit


if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_GetFileSystemStatistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find out info about the file system

CALLED BY:	GLOBAL

PASS:		buffer to stuff info into

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 2/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Ipx_GetFileSystemStatistics	proc	near
		push	ebp
		mov	ebp, esp

		push	eax
		push	ebx
		push	ecx
		push	edx
		push	fs

		mov	eax, ss:[ebp+8]
		push	eax


	; now copy data up to protected mode buffer
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	ebx, ds:[recvECBPtr]
		add	ebx, size IPXHeader + size EventControlBlock
		mov	byte ptr fs:[ebx], 2
		mov	byte ptr fs:[ebx+1], 0
		mov	byte ptr fs:[ebx+2], 0d4h

	; now make the IPX call
		mov	bx, ds:[rm_csds]
		shl	ebx, 16
		lea	bx, recvData
		
		push	ebx
		lea	bx, sendData
		push	ebx
		push	ebx
		push	ebx
		mov	ebx, 0e300h
		push	ebx
		call	CallIpx
		add	esp, 20

	; now copy data up to protected mode buffer
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	ebx, ds:[sendECBPtr]	
		add	ebx, size IPXHeader + size EventControlBlock	
						; fs:[ebx] = send buffer
		mov	ecx, 21
		pop	edx
copyLoop2:
		mov	di, fs:[ebx]
		mov	ds:[edx], di
		add	ebx, 2
		add	edx, 2
		loop	copyLoop2

		pop	fs
		pop	edx
		pop	ecx
		pop	ebx
		pop	eax
		pop	ebp
		ret
Ipx_GetFileSystemStatistics	endp
	public Ipx_GetFileSystemStatistics
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_CopyToSendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy data to the send buffer

CALLED BY:	GLOBAL

PASS:		data, length of data, offset into send buffer

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	we are copying data from a protected mode buffer
			down to a real-mode buffer in conventional memory
			so IPX can get at it

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Ipx_CopyToSendBuffer	proc	near
		push	ebp
		mov	ebp, esp	; ss:[ebp] = stack frame
		push	es
		push	edi
		push	esi
		push	ecx

		mov	ax, SS_DOSMEM
		mov	es, ax
		mov	edi, ds:[sendECBPtr] 	; es:edi = real mode address
						; of sendECB
	
	; now add in offset to the start of the data buffer
	; and the offset within the buffer
		add	edi, size EventControlBlock + size IPXHeader
		add	edi, ss:[ebp+16]

		mov	ecx, ss:[ebp+12]	; get amount of data to copy
		mov	esi, ss:[ebp+8]		; address of data to copy
	; copy the data in word size chunks
		shr	ecx, 1
		rep	movsw
		jnc	ICTSB_done
		movsb			; get leftover byte if needed
ICTSB_done:	
	; restore the stack
		pop	ecx
		pop	esi
		pop	edi
		pop	es
		pop	ebp
		ret
Ipx_CopyToSendBuffer	endp
	public Ipx_CopyToSendBuffer

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_SendLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	actually send of a packet by calling the ipx routine

CALLED BY:	GLOBAL

PASS:		size of packet, packet data to send

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Ipx_SendLow	proc	near
		push	ebp
		mov	ebp, esp	; ss:[ebp] = stack frame
		push	ebx

		mov	ecx, ss:[ebp+8]	; get size of packet

	; set up pointer to sendECB	
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	ebx, ds:[sendECBPtr]	; fs:ebx = sendECB

	; if the thing is busy, wait till its done
waitForPrevPacket:
		cmp	fs:[ebx].ECB_inUse, 0
		jnz	waitForPrevPacket

	; if we are trying to send too much data, bail
		cmp	ecx, IPX_MAX_PACKET
		ja	ISL_done

	; set the size of the packet in the appropriate places
		mov	fs:[ebx].ECB_Data_size, cx
		add	cx, size IPXHeader
		add	ebx, size EventControlBlock	; fs:ebx = sendHeader
		mov	fs:[ebx].IPXH_length, cx

	; now contruct a real-mode address of sendECB
		mov	bx, ds:[rm_csds]
		shl	ebx, 16
		lea	bx, sendECB	; ebx = real-mode address of sendECB

	; now lets call IPX
		push	ebx	; essi value = sendECB real mode address
		push	ebx	; esdi value
		push	eax	; random value
		push	IPXF_SEND_PACKET
		push	eax	; random value
		call	CallIpx
		add	esp, 20	; pop off agruments
ISL_done:
		pop	ebx	; restore stack
		pop	ebp
		ret
Ipx_SendLow	endp
	public Ipx_SendLow



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_ReadLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read a packet 

CALLED BY:	GLOBAL

PASS:		buffer to read data into

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	we are copying data from a real-mode buffer up
			to a protected mode buffer

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/24/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Ipx_ReadLow	proc	near
		push	ebp
		mov	ebp, esp	; ss:[ebp] = stack frame
		push	edi

	; first lets let IPX do some stuff if it wants to
	; I don't know what this does but the swat stub does it so
	; why not do it here too
		push	eax
		push	eax
		push	eax
		push	IPXF_YIELD
		push	eax
		call	CallIpx
		add	esp, 20	; pop off the arguments to CallIpx

	; set up a pointer to recbECB in ebx	
		mov	ax, SS_DOSMEM
		mov	fs, ax
		mov	ebx, ds:[recvECBPtr]

	; wait while the thing is busy
busyLoop:
		cmp	fs:[ebx].ECB_inUse, 0
		jnz	busyLoop
	
	; ok, its no longer busy, we should have a packet
		mov	ecx, ss:[ebp+12]		; get size of buffer
		mov	edx, ss:[ebp+8]			; get buffer address
	; the IPXHeader sits just beyond the EventControlBlock
		add	ebx, size EventControlBlock ; fs:ebx = recvHeader
		mov	ax, fs:[ebx].IPXH_length
		xchg	al, ah			; byte swap the value
	; we don't want to count the header in the data size
		sub	ax, size IPXHeader
	; now make sure we won't overwrite the buffer
		cmp	cx, ax
		jb	IRL_bail	; buffer too small to hold packet
	; ok, then set the size of the actual data and save it
		mov	cx, ax	
		push	ax		; save for a return value

	; now advance ebx to point to the actual data buffer	
		add	ebx, size IPXHeader	; fs:ebx = recvData
		shr	cx, 1		; copy in words for speed
copyLoop:	
		mov	di, fs:[ebx]
		mov	ds:[edx], di
		add	ebx, 2
		add	edx, 2
		loop	copyLoop
		test	ax, 1		; now get the odd byte if needed
		jz	gotPacket
		mov	al, fs:[ebx]
		mov	ds:[edx], al
gotPacket:
	; now got the packet, so we just need to tell IPX we are ready
	; for another, thank you sir may I have another?
		mov	ax, ds:[rm_csds]
		shl	eax, 16
		lea	ax, recvECB
		push	eax		; essi = real-mode address or recvECB
		push	eax		; esdi (must be same es as essi value)
		push	eax		; dx (unused)
		push	IPXF_RECEIVE_PACKET
		push	eax		; ax (unused)
		call	CallIpx
		add	esp, 20		; pop off the arguments to CallIpx
		pop	ax		; return size of packet
		movzx	eax, ax		; zero extend the thing
IRL_done:
		pop	edi		; restore stack
		pop	ebp
		ret
IRL_bail:
		mov	eax, 0		; return 0 on bail
		jmp	IRL_done
Ipx_ReadLow	endp
	public Ipx_ReadLow


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Ipx_CheckPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check to see if a packet came in

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		size of packet received (0 if none)

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	the service routine for receiving packets sets
			the receivedPacket variable to the size of the
			packet, so if its non-zero we got a packet
		
			we reset the variable to zero everytime this is called

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/24/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Ipx_CheckPacket	proc	near

	; just construct the real-mode address of the variable, and
	; get its value, and replace it with a zero
		mov	ax, SS_DOSMEM
		mov	fs, ax
		movzx	ebx, ds:[rm_csds]
		shl	ebx, 4
		lea	edx, receivedPacket
		add	ebx, edx
		mov	eax, 0			; reset value to zero
		xchg	ax, fs:[ebx]
		ret
Ipx_CheckPacket	endp
	public Ipx_CheckPacket

_CODESEG	ends

_RCODESEG	segment		; stuff that need to be done in real-mode




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IpxCheckRM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make the interrupt call from real mode

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IpxCheckRM	proc	far
	; make the call
		mov	ax, IPX_INSTALL_CHECK
		int	2fh
	; now store the result in ipx, if we were successful ipx will
	; be set to the real-mode address of the ipx routine
		push	eax	; save the return value
		push	ds	; and the segment register
		mov	ax, cs
		mov	ds, ax
	
	; the address is returned in es:si, so stuff it into ipx
		mov	ax, es
		shl	eax, 16
		mov	ax, di
		mov	ds:[ipx], eax

		pop	ds	; restore the stack
		pop	eax
		ret
IpxCheckRM	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IPXDummyRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	a do-nothing routine for sending packets

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IPXDummyRoutine	proc	far
	ret
IPXDummyRoutine	endp
	public IPXDummyRoutine



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IpxReceivePacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	note that a packet has been received

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	set a variable to the size of the received packet
			so when the Rpc module is looking for a packet it
			will know that one has arrived

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/24/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IpxReceivePacket	proc	far
		push	ax	; save our registers, like a good citizen
		push	ds

		mov	ax, cs
		mov	ds, ax
		mov	ax, ds:[recvHeader].IPXH_length
		xchg	al, ah	; for some reason we need to byte swap it
		mov	ds:[receivedPacket], ax

		pop	ds	; restore the stack
		pop	ax
		ret
IpxReceivePacket	endp
	public IpxReceivePacket

_RCODESEG	ends	




end
