COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:	PC GEOS
MODULE:		Swat -- Debugging stub: handle a com port
FILE:		com.asm

AUTHOR:		Adam de Boor, November 17, 1988

ROUTINES:
	Name		Description
	----		-----------
	Com_Init	Initializes the module
	Com_Read	Returns a character from the input ring
	Com_Write	Transfers a character to the serial line
	Com_ReadBlock	Read a block of data to the given address.
	Com_WriteBlock	Writes a block of data from the given address
	Com_Exit	Restores the serial line state.

	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	adam	6/7/88	Initial Revision


DESCRIPTION:
	This module handles all I/O for a single serial line. All the I/O
	is interrupt-driven.

	The buffers are, naturally, ring buffers with no checking for
	overflow (we assume the nature of the communication mechanism (with
    	replies and so on) will prevent this...).

	The single-byte functions will not block, but the block functions will.
		
    	Unfortunately, the interrupt routine understands about RPCs and will
	call Rpc_Wait when an rpc is complete if the 'waiting' bit of sysFlags
	is clear. This is to allow RPC_INTERRUPT to work.

	$Id: com.asm,v 2.31 97/03/03 00:25:39 allen Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_Com	    	=	1
		include	stub.def

ifndef NETWARE		; don't have any of this stuff when using netware
ifndef WINCOM

scode		segment

hardwareType	HardwareType	HT_PC		; default is for the PC
include com.def


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
head		word	0		; Head index
tail		word	0		; Tail index
numChars	word	0		; Number of characters in buffer
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

comIn		BUFFER	<>		; Receiver buffer
comOut		BUFFER	<>		; Output buffer

comCurMsgStart	word		; offset in comIn at which message currently
				;  being received is located
com_NumMessages	byte	0	; number of messages outstanding in the
				;  input buffer
;
; Various state flags and macros for manipulating them
;
;
; Flag definitions:
;	IRQPEND		Set => a transmitter interrupt should be coming in.
;			Tells us whether to queue a character or send it
;			directly.
;
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
		even

;
; Place for storing old interrupt vector
;

comIntVec	dword

comIntVecNum	word
com_IntLevel	byte			; Interrupt level
		even

;
; The four ports needed by the interrupt routine. These are set up by Com_Init
; based on the device being used.
;
comDataInPort	word	
comDataOutPort	word	
comCurIRQPort	word
comCurStatPort	word
comCurIENPort	word

comdAvail	byte
comThre		byte
comRecvEnable	byte
comTransEnable	byte
comIrq		word
;
; Place for storing old interrupt vector
;
;
ComStates	etype	byte
    CS_SYNC		enum	ComStates	; looking for RPC_MSG_START
    CS_QUOTE		enum	ComStates	; received RPC_MSG_QUOTE, need
						;  second byte of sequence
    CS_BASE		enum	ComStates	; normal state reading message

comState	ComStates	CS_SYNC

scode		ends

scode	segment
    	    	assume	    cs:scode,ds:cgroup,es:cgroup,ss:sstack
ComPortData	struct
    CPD_portMask	word		; Mask for figuring out other
    					; ports for the channel. The number
					; being masked is 3fXh where X is
					; 8 through f
    CPD_level		word		; Interrupt level (as far as
					; interrupt controller is concerned)
ComPortData	ends

ports		ComPortData	<0ffffh,4>	; COM1 (3f8, level 4)
		ComPortData	<0feffh,3>	; COM2 (2f8, level 3)
		ComPortData	<0ffefh,4>	; COM3 (3e8, level 4)
		ComPortData	<0feefh,3>	; COM4 (2e8, level 3)

; default parameters, as determined from environment and other things.
comPort		byte
comBaud		word
comIRQ		byte

TIMER0_IPR	equ	30h
TIMER1_IPR	equ	31h
TIMER2_IPR	equ	32h
SIO_IPR		equ	34h

PSP_ENV_SEG	equ	2ch


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComDeterminePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the port number from port description string.

CALLED BY:	ComParseEnvString
PASS:		ds:si	= port description string
RETURN:		carry set if port number invalid
		carry clear if port number ok:
				al = com port
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	ComDeterminePort
MAX_PORT	equ	'4'

ComDeterminePort proc near
	;
	; Fetch the first char of the descriptor. This must be a char between
	; 1 and 4, inclusive.
	; 
		xor	ax, ax
		lodsb			; al <- port number
		cmp	al, '1'
		jl	SDP_fail
		cmp	al, MAX_PORT
		jg	SDP_fail
	;
	;
	; Skip over the comma that must follow the port number.
	; 
		cmp	byte ptr ds:[si], ','
		jne	SDP_fail
		inc	si
		sub	al, '0'
SDP_done:
		ret
SDP_fail:
		stc
		jmp	SDP_done
ComDeterminePort endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComDetermineBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the number at ds:si into a number and see if that's
		a valid baud rate, returning the divisor for the rate if so.

CALLED BY:	ComParseEnvString
PASS:		ds:si	= baud rate string (ending with null or comma)
RETURN:		carry set if invalid baud rate
		carry clear if baud rate is ok:
			ds:si	= null terminator, or first char of interrupt
				  level
			dx	= divisor (low 16 bits are relevant)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	ComDetermineBaud
ComDetermineBaud proc near
		push	ax
		push	bx
		push	cx
		mov	bx, 10		; used as a multiplier in loop
		xor	dx, dx
		mov	ax, dx		; clear high 3 bytes of eax
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
;		imul	dx, 10			; dx = dx * 10
		mov_tr	cx, ax			; save ax
		mov_tr  ax, dx			; ax = dx for mul
		mul	bx			; ax = ax * 10
		mov_tr	dx, ax			; dx = ax (old dx * 10)
		mov_tr	ax, cx			; restore ax
		add	dx, ax
		jmp	SDB_charLoop
SDB_hitNullTerm:
		dec	si		; point back to null
SDB_haveBaud:
	;
	; Blech. Isn't there some cleaner way to do this?
	;
		xchg	ax, dx	; ax <- baud

	irp	baud, <300,1200,2400,4800,9600,19200,38400>
		mov	dx, BAUD_&baud
		cmp	ax, baud
		je	SDB_done	; (carry clear if branch taken)
	endm
SDB_error:
		stc
SDB_done:
		pop	cx
		pop	bx
		pop	ax
		ret
ComDetermineBaud		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComDetermineIRQ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the interrupt level to be used for the port.

CALLED BY:	ComParseEnvString
PASS:		ds:si	= remainder of port descriptor
		cs:di	= ComPortData for selected port (contains default
			  interrupt level)
RETURN:		carry set on error
		carry clear if ok:
			al	= interrupt level for port
DESTROYED:	si, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	ComDetermineIRQ
ComDetermineIRQ proc	near
		push	dx
		push	bx
		push	cx
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
		cwd			; clear high 3 bytes by sign-extension
	;
	; See if level is 2 digits.
	; 
		cmp	byte ptr ds:[si], 0
		je	SDIRQ_done	; => single digit; eax is level
	;
	; Multiply previous digit by 10 and add new digit to get level.
	; 
;		imul	cx, ax, 10
		mov	bx, 10
		mul	bx
		mov_tr	cx, ax
		lodsb
		sub	al, '0'
		jb	SDIRQ_error
		cmp	al, 9
		ja	SDIRQ_error
		cwd	
		add	ax, cx	; (can't carry)
SDIRQ_done:
;		mov	ds:[comIRQ], al
		pop	cx
		pop	bx
		pop	dx
		ret
SDIRQ_error:
		stc
		jmp	SDIRQ_done

SDIRQ_useDefault:
		mov	al, -1		; no level given
		clc
		jmp	SDIRQ_done
ComDetermineIRQ endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComGetENVData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the baud rate from the environment variable if any

CALLED BY:	Com_Init

PASS:		ds	= cgroup

RETURN:		carry set if no PTTY variable found
		es:di = PTTY value string

		it is possible to just supply a com port,
		or just a com port and baud rate, so zero values
		will be found in the unspecified values 


DESTROYED:	si, di

PSEUDOCODE/STRATEGY: go through the environment block of the program
		     looking for a PTTY variable, if we find one
		     the get the value contained else return carry

		     an environment block is a series of null ('\0') ternimated
		     strings with one final null after the last null ternimated
		     string, so the block ends with two nulls

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/17/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

comData		char	"PTTY="

ComGetENVData	proc	near
	uses	ds
	.enter
	mov	es, ds:[PSP]
	mov	es, es:[PSP_ENV_SEG]
	clr	di			; es:di <- first envar
	clr	al			; al <- 0 for locating null...
	PointDSAtStub
doString:
	;
	; See if the variable matches what we're looking for.
	; 
	mov	si, offset comData
	mov	cx, length comData
	repe	cmpsb
	je	done			; => matches up to the =, so it's
					;  ours...
	dec	di			; deal with mismatch on null byte...
	mov	cx, -1
	repne	scasb
	
	cmp	es:[di], al		; double null (i.e. end of environment)?
	jne	doString		; => no

	stc
done:
	.leave
	ret
ComGetENVData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComParseEnvString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set default communication parameters from the given string

CALLED BY:	Com_Init
PASS:		es:di	= string to parse
RETURN:		carry set if string invalid
		carry clear if happy:
			al	= IRQ
			dx	= baud rate divisor
			cl	= com port #
DESTROYED:	ax, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComParseEnvString proc	near
		uses	ds
		.enter
		segmov	ds, es
		mov	si, di

		call	ComDeterminePort		; al <- com port
		jc	done
		call	ComDetermineBaud		; dx <- divisor
		jc	done
		mov	cl, al
		call	ComDetermineIRQ		; al <- IRQ level
done:
		.leave
		ret
ComParseEnvString endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchPCBaudArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a /b argument, if there is one, and transform it
		into a baud rate divisor.

CALLED BY:	(INTERNAL) Com_Init
PASS:		es	= scode (writable alias)
		ds	= cgroup
RETURN:		cs:[comBaud] altered if /b given
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
baud		byte	'b', 0	; string for /b arg
baudrate	db	2 dup (?);storage for /b arg

ComFetchPCBaudArg	proc	near
		.enter
		assume	es:scode
	;
	; Fetch the argument itself.
	; 
		mov	di, offset baud		; es:di <- arg
		mov	bx, offset baudrate	; es:bx <- buffer
		mov	dx, length baudrate	; dx <- sizeof(buffer)
		call	FetchArg

		cmp	bx, offset baudrate
		je	done	; => no /b arg, so use default

		mov	ah, es:[baudrate]; get value provided
		mov	al, BAUD_9600	
		cmp	ah, '9'		; check for 9600 as value
		je	setNewBaud

		mov	al, BAUD_38400	; check for 38400 baud
		cmp	ah, '3'
		je	setNewBaud

		mov	al, BAUD_4800	; check for 4800 baud
		cmp	ah, '4'		; 
		je	setNewBaud	; use 4800 baud

		mov	al, BAUD_2400	; check for 2400 baud
		cmp	ah, '2'		; 
		je	setNewBaud	; use 2400 baud

		mov	al, BAUD_1200	; check for 1200 baud
		cmp	ah, '1'		; 
		jne	use19_2		; no, use 19200 baud
		cmp	es:[baudrate][1], '2'	; check for 1200, vs. 19200
		je	setNewBaud	;  yes, use 1200
use19_2:
		mov	al, BAUD_19200	; if no match, use 19200
setNewBaud:
		clr	ah
		mov	es:[comBaud], ax; save divisor for later
done:
		assume	es:cgroup
		.leave
		ret
ComFetchPCBaudArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchPortArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a /c argument, if there is one, and override the
		default port with its value.

CALLED BY:	(INTERNAL) Com_Init
PASS:		es	= scode
		ds	= cgroup
RETURN:		cs:[comPort] altered if /c given
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
devarg		char	'c', 0	; string for /c arg
device		char		; place to store result of /c

ComFetchPortArg	proc	near
		.enter
		assume	es:scode
		mov	di, offset devarg
		mov	bx, offset device
		mov	dx, length device
		call	FetchArg

		cmp	bx, offset device
		je	done
		DPC	DEBUG_COM_INIT, 'P'
		DPC	DEBUG_COM_INIT, es:[device]

		mov	al, es:[device]
		cmp	al, '1'
		jl	done
		cmp	al, MAX_PORT
		jg	done
		sub	al, '0'

		mov	es:[comPort], al
done:
		assume	es:cgroup
		.leave
		ret
ComFetchPortArg	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchIRQArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a /I argument, if there is one, and override the
		default IRQ with its value.

CALLED BY:	(INTERNAL) Com_Init
PASS:		es	= scode
		ds	= cgroup
RETURN:		cs:[comIRQ] altered if /I given
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
irqarg		char	'I', 0	; string for /I arg
irqbuf		char	3 dup(?); room for 2-digit decimal + null-term

ComFetchIRQArg	proc	near
		uses	ds, si
		.enter
		assume	es:scode
		mov	di, offset irqarg
		mov	bx, offset irqbuf
		mov	dx, length irqbuf-1
		call	FetchArg

		cmp	bx, offset irqbuf
		je	done

		DPC	DEBUG_COM_INIT, '/'
		DPC	DEBUG_COM_INIT, 'i'
		PointDSAtStub
		mov	si, offset irqbuf
		call	ComDetermineIRQ
		mov	ds:[comIRQ], al
done:		
		assume	es:cgroup
		.leave
		ret
ComFetchIRQArg	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComInitPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do init for a PC

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/12/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComInitPC	proc	near
		.enter
		push	es
		PointESAtStub

		mov	ds:[comCurIENPort], COMIENPORT
		mov	ds:[comCurIRQPort], COMIRQPORT
		mov	ds:[comCurStatPort],COMSTATPORT
		mov	ds:[comdAvail], COMDAVAIL
		mov	ds:[comThre], COMTHRE
		mov	ds:[comRecvEnable], COMRECVENABLE
		mov	ds:[comTransEnable], COMTRANSENABLE

		call	ComFetchPortArg
		call	ComFetchIRQArg

		DPC	DEBUG_COM_INIT, 'A'
		DPB	DEBUG_COM_INIT, cs:[comPort]
		DPB	DEBUG_COM_INIT, cs:[comIRQ]

	;
	; Now process the values we won so painfully.
	; 
		mov	bl, cs:[comPort]
		DPC	DEBUG_COM_INIT, 'P'
		DPW	DEBUG_COM_INIT, BX
		clr	bh
		dec	bx		; change to 0-origin from 1-origin
		shl	bx, 1		; *4 for indexing into ports
		shl	bx, 1

		assume	es:scode
		;
		; Fetch the port mask and interrupt level now so we have no
		; further need for the port data.
		;
		mov	al, cs:[comIRQ]
		mov	al, 4
		cmp	al, -1
		jne	haveIRQ
		mov	ax, es:ports[bx].CPD_level
haveIRQ:

		mov	bx, es:ports[bx].CPD_portMask
		DPC	DEBUG_COM_INIT, 'M'
		DPW	DEBUG_COM_INIT, bx

		pop	es		; Point ES back at cgroup
		assume	es:cgroup
		;
		; Save the interrupt level...
		;
		
		mov	al, 4
		mov	ds:[com_IntLevel], al
		DPB	DEBUG_COM_INIT, al

		;
		; Adjust level by interrupt base for the controller to
		; get the actual vector number to use. Invert the mask since
		; we want to enable the interrupt.
		;
		clr	dx
		mov	dl, al		; dx = IRQ level
		mov	cl, al		; save IRQ level for later
		add	dx, IRQBASE	; adjusted irq level for SetInterrupt
		cmp	dx, IRQBASE+8
		jb	setIOPorts
		add	dx, IRQBASE2-(IRQBASE+8)
setIOPorts:

		DPC	DEBUG_COM_INIT, 'I'
		DPW	DEBUG_COM_INIT, dx

		;
		; Set up comDataInPort, comCurStatPort and comCurIRQPort
		; for ComInterrupt 
		;
		mov	ax, COMDATAPORT
		and	ax, bx
		DPW	DEBUG_COM_INIT, AX
		; these are the same for a PC, different for the Zoomer
		mov	ds:[comDataInPort], ax
		mov	ds:[comDataOutPort], ax

		mov	ax, COMSTATPORT
		and	ax, bx
		mov	ds:[comCurStatPort], ax

		mov	ax, COMIRQPORT
		and	ax, bx
		mov	ds:[comCurIRQPort], ax

		;
		; Fetch original vector and stuff in ours in its place.
		;
		push	bx			; Still need port mask
		mov_tr	ax, dx			; Pass vector number in AX
		mov	ds:[comIntVecNum], ax	; Store vector number for
		mov	bx, offset comIntVec	; Address of storage in BX
		mov	dx, offset ComInterrupt	; Our routine in DX
		call	SetInterrupt		; Do it. (uses old function
						; if stub relocated)
		pop	bx			; Get mask back

		;
		; Set the baud rate of the line. The baud rate is set by
		; dividing an 18.432 mhz clock by something. The divisors
		; for various baud rates are:
		;	38400		 3
		;	19200		 6
		;	 9600		12
		;	 7200		16
		;	 4800		24
		;	 3600		32
		;	 2400		48
		;	 2000		58
		;	 1800		64
		;	 1200		96
		;
		; Note that the spec claims the thing shouldn't run at more
		; than 9600, but it appears to run just fine at 19.2
		;
		mov	dx, COMLINEPORT
		and	dx, bx
		mov	al, 80h
		out	dx, al

		;
		; Actually install the baud rate divisor
		; 
		mov	ax, cs:[comBaud]
		mov	ax, 3
		mov	dx, COMDLLPORT
		and	dx, bx
		out	dx, al

		jmp	$+2		; I/O delay...

		inc	dx
		mov	al, ah
		out	dx, al

		;
		; Make sure the interrupt enable port and data port are
		; actually at the appropriate addresses by clearing the
		; Divisor Latch Access Bit in the line control register.
		; Note the and'ing of COM1's port with the mask in bx
		; Also make sure the line is in the format we want:
		;	8 data bits
		;	1 stop bit
		;	no parity
		; qv. Options and Adapters vol. 2 for more info
		;
		mov	dx, COMLINEPORT
		and	dx, bx
		mov	al, 3
		out	dx, al

		;
		; Turn on DTR, RTS and OUT2. The first 2 are on because that's
		; what terminals normally expect. OUT2 is on b/c it must be on
		; for interrupts to come through.
		;
		; Don't turn on DTR for the Jedi, since that line is used
		; to reset the uC.  Asserting it will cause the uC to
		; go into perpetual reset mode, and eventually cause the
		; the screen to blank.
		;				-- todd 04/26/94
		;
		mov	dx, COMMODEMPORT
		and	dx, bx
		mov	al, COMDTR OR COMRTS OR COMOUT2

		out	dx, al

		;
		;
		; Make sure the input buffer is clear and the interrupt-
		; pending flag is clear by reading the buffer now. If we
		; don't and for some reason an interrupt is already pending
		; from the device, we're hosed.
		;
		mov	dx, ds:[comDataInPort]
		in	al, dx

		;
		; Enable the receiver interrupts. We've nothing to transmit
		; yet, so no point in enabling transmitter interrupts.
		;
		mov	dx, COMIENPORT
		and	dx, bx
		mov	ds:[comCurIENPort], dx
		mov	al, COMRECVENABLE
		out	dx, al

		;
		; Enable interrupts from the device in the interrupt controller
		;

		; see if we are dealing with irq 0-7 or 8-15
		; 0-7 are on PIC1, and 8-15 are on PIC2
		push	di
		mov	di, offset COM_Mask1
		mov	ds:[COM_Mask2], 0
		mov	dx, ICMASKPORT		; assume 0-7
		mov	bx, offset PIC1_Mask
		cmp	cl, 8
		jl	gotPIC
		mov	ds:[COM_Mask1], 0
		mov	di, offset COM_Mask2
		mov	bx, offset PIC2_Mask
		mov	dx, ICMASKPORT2
		sub	cl, 8
gotPIC:
		mov	al, 1
		shl	al, cl			; set up mask
		mov	ds:[di], al		; save it so we know what
						;  must remain enabled

		not	al
    	    	and 	ds:[bx], al	; Make sure ints are enabled
						;  when we're halted
		mov	ah, al
		in	al, dx		; al <- current mask
		and	al, ah		; clear the proper bit
		out	dx, al
		pop	di

		.leave
		ret
ComInitPC	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the appropriate communications port

CALLED BY:	Rpc_Init
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	AX, BX, DX

PSEUDO CODE/STRATEGY:
	Figures out which device to use by looking for the /c flag in the
	command tail stored in the PSP that MS-DOS gives us. Usage is
		swat /c:[1234]
	Defaults to COM2 if nothing specified.

	Once the device is determined, we initialize it to provide interrupts
	and install our own interrupt handler via SetInterrupt. The old
	vector is saved in comIntVec.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision
	JDM	91.02.20	Added 38400 baud support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
;defaultComString char	"2,19200", 0
defaultComString char	"1,38400,4", 0

Com_Init	proc	near
		;
		; Deal with arguments now, so we can get back to having DS
		; point at cgroup...
		;
		push	es
	;
	; Establish any defaults.
	; 
		call	ComGetENVData
		jnc	haveDefaultString
useDefault:
		PointESAtStub
		mov	di, offset defaultComString
haveDefaultString:
		call	ComParseEnvString
		jc	useDefault

                ; Store the parsed settings locally in the code
                mov     es, cs:[stubDSSelector]
		mov	es:[comBaud], dx
		mov	es:[comIRQ], al
		mov	es:[comPort], cl

		DPC	DEBUG_COM_INIT, 'X'
		DPB	DEBUG_COM_INIT, cl
		DPB	DEBUG_COM_INIT, al
		DPW	DEBUG_COM_INIT, dx
		
		;
		; First see if any /b flag given.  If not, use 19.2Kbaud
		;
		assume	es:scode
		call	ComFetchPCBaudArg
		DPC	DEBUG_COM_INIT, 'B'
		DPW	DEBUG_COM_INIT, cs:[comBaud]

		pop	es		; restore es
		call	ComInitPC

done::
		clc
		ret
Com_Init	endp

scode	ends

scode		segment
    	    	assume	    cs:scode,ds:cgroup,es:cgroup,ss:sstack


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_GetHardwareType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the value from the scode segment

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/12/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Com_GetHardwareType	proc	far
	.enter
	mov	ax, cs:[hardwareType]
	.leave
	ret
Com_GetHardwareType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_SetHardwareType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the hardware type

CALLED BY:	GLOBAL

PASS:		ax = hardware type (HardwareType)

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/12/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Com_SetHardwareType	proc	far
        uses ds
	.enter
        PointDSAtStub
	mov	ds:[hardwareType], ax
	.leave
	ret
Com_SetHardwareType	endp
	public	Com_SetHardwareType


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the state of the serial port world

CALLED BY:	Exit

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Restore the original interrupt vector and turn off interrupts for
	the device.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Com_Exit	proc	near
		push	ax
		push	bx
		dsi
    	    	mov 	bl, ds:[COM_Mask1]
		not 	bl
		in	al, PIC1_REG		; Turn off interrupts for
		or	al, bl		    	; this device
		out	PIC1_REG, al

		mov	bl, ds:[COM_Mask2]
		not	bl
		in	al, PIC2_REG
		or	al, bl
		out	PIC2_REG, al

		mov	dx, ds:[comCurIENPort]
		clr	al
		out	dx, al

		mov	ax, ds:[comIntVecNum]
		lea	bx, ds:[comIntVec]
		call	ResetInterrupt
		eni
		pop	bx
		pop	ax
		ret
Com_Exit	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem an interrupt from the selected serial device

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

ComInterrupt	proc	far
		push	ax
		push	bx
		push	cx
		push	dx
		push	ds
		PUSH_ENABLE
	
	;
	; Preserve current control register (in case we interrupted
	; ourselves -- we can't just write protect on exit...)
	;
		DPB	DEBUG_COM_INPUT, 9
		DPC	DEBUG_FALK, "I"

                mov     ds, cs:[stubDSSelector]	; set up ds for our own ease
		cmp	cs:[hardwareType], HT_PC
		jne	CIIsOurs
	;
	; Make sure the interrupt's actually ours -- a bus mouse
	; shares the same interrupt level as COM2...
	;

		mov	dx, ds:[comCurIRQPort]
		in	al, dx
		test	al, 1
		jz	CIIsOurs
	;
	; Nope -- restore registers and pass control to old
	; handler.
	;
	;
	; Restore board control register -- NO FURTHER WRITES
	;


		POP_PROTECT
		pop	ds
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		jmp	cs:comIntVec
CIIsOurs:
	;
	; Force the interrupt output of the chip low by turning
	; off all interrupts. This makes sure the IRQ line makes it
	; all the way down before coming back up if an interrupt comes
	; in while we're in here.
	;
		mov	dx, ds:[comCurIENPort]
		clr	al
		out	dx, al

	;
	; We've turned off interrupts from this device, so it's ok to
	; turn interrupts on now.
	;
		;eni	NO. Don't want to be context-switched out.

	;
	; Fetch current status bits
	;
		mov	dx, ds:[comCurStatPort]
		in	al, dx
		push	ax			; Save for ComCheckTrans

;		test	al, COMALLERR
;		jz	CINoErr
;		; Reset the system on any transmission error.
;		; This is just so we know...
;		int	19h
;CINoErr:
		test	al, ds:[comdAvail]
		jz	ComCheckTrans

	;
	; Data waiting. Fetch character and process it according to our
	; current state.
	;
		mov	dx, ds:[comDataInPort]
		in	al, dx			; Fetch the character
		DPB	DEBUG_COM_INPUT, al

		mov	ah, ds:[comState]	; ah <- current state for
						;  ease of processing.

		cmp	al, RPC_MSG_START
		jne	storeByte
	;
	; Switch to BASE state upon receipt of RPC_MSG_START no matter
	; what state we were in before, resetting the input buffer
	; pointer to where the message is supposed to start.
	; 
		mov	ax, ds:[comCurMsgStart]
		mov	ds:[comIn].tail, ax
		sub	ax, ds:[comIn].head
		jae	setNumChars
		add	ax, BUFSIZE		; perform arithmetic modulo
						;  BUFSIZE
setNumChars:
		mov	ds:[comIn].numChars, ax
		mov	ah, CS_BASE
		jmp	changeState

storeByte:
	;
	; If still awaiting MSG_START, drop the byte on the floor.
	;
		cmp	ah, CS_BASE
		jne	ComCheckTrans
	;
	; Store the byte in AL into the comIn buffer.
	; 
;BRK
		mov	bx, ds:[comIn].tail
		mov	ds:[comIn].data[bx],al	; Stuff it
		Update	ds:[comIn].tail, bx
    	    	inc	ds:[comIn].numChars
	;
	; If byte was last byte of a message, flag it.
	; 
		cmp	al, RPC_MSG_END
		je	messageReceived
changeState:
	;
	; Change the machine's state to match that now in AH and fall
	; into checking for transmission now possible.
	; 
		mov	ds:[comState], ah
		
ComCheckTrans:
		;
		; See if we can send data. Original status stored on the
		; stack, so use that.
		;
		pop	ax
		test	al, ds:[comThre]
		jnz	ComIntSend

ComIntReturn:
		;
		; Signal end-of-interrupt to interrupt controller, restore
		; state and return.
		;
PC_EOI::
		mov	al, ICEOI
		out	ICEOIPORT, al

		cmp	ds:[com_IntLevel], 8	; second controller involved?
		jb	enableInts		; no
		out	ICEOIPORT2, al		; yes -- tell it we're done too
enableInts:

		;
		; Reenable interrupts from the chip. If a character came in
		; or the transmitter became ready while we were in here, this
		; will generate an interrupt right away...
		; Note that we only enable the transmitter interrupt if we
		; actually expect an interrupt to come in. Otherwise, we will
		; loop infinitely getting transmitter interrupts each time we
		; re-enable interrupts for the device.
		;
                mov	dx, ds:[comCurIENPort]				
		mov	al, ds:[comRecvEnable]
		isset?	IRQPEND
		jz	CI2
		or	al, ds:[comTransEnable]
CI2:
        	out	dx, al						
		;
		; Restore control register
		;
	
		POP_PROTECT
		pop	ds
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		iret

ComIntSend:
		;
		; Transmitter ready for more. If no characters
		; queued, clear the IRQPEND flag so we know we have to prime
		; the serial line again.
		;
		tst	ds:[comOut].numChars
		jz	ComNoTrans

		mov	bx, ds:[comOut].head	; Fetch char at head
		mov	al, ds:[comOut].data[bx]

		mov	dx, ds:[comDataOutPort]
		out	dx, al			; and send it

		Update	ds:[comOut].head, bx
		dec	ds:[comOut].numChars
		set	IRQPEND			; s/b set, but better safe...
		jmp	ComIntReturn

ComNoTrans:
		;
		; Nothing transmittable -- clear the IRQPEND flag, so we
		; know no interrupt is coming, and return.
		;
		reset	IRQPEND
		jmp	ComIntReturn

messageReceived:
	;
	; A full message is now in the input buffer. Up the count of
	; messages there so others know of it.
	; 
	; If we're not in the Rpc_Wait loop, we need to call Rpc_Wait
	; ourselves. This allows a packet to stop the machine, for example.
	; 
		mov	ds:[comState], CS_SYNC	; start looking for MSG_START
						;  again
						
		mov	ds:[comCurMsgStart], bx ; record start of next message
						;  in case MSG_START arrives
						;  while in CS_BASE state

		inc	ds:[com_NumMessages]

		DPC	DEBUG_MSG_PROTO, 'M'
		DPB	DEBUG_MSG_PROTO, ds:[com_NumMessages]
		
;		cmp	ds:[com_NumMessages], 1
;		ja	doRpcStuff		; => something got hosed, so
;						;  field the message ourselves
;
		test	ds:[sysFlags], mask waiting or mask calling
		jnz	ComCheckTrans

doRpcStuff:
	; The following is, well, a hack of sorts.  The problem is that we
	; have ComInterrupt turn on interrupts and then receive ComInterrupt.
	; DPMI seems to fail miserbly at that ... so ... we going to do
	; something radical.  It appears that the only time this really is a
	; problem is when the programmer hits CTRL-C in Swat to stop the
	; target.  So when the programmer does this, instead of going into
	; Rpc_Run state forever in here, we're actually going to set a break
	; point at the return address (yes, there is a trick there too) and
	; stop the computer at that point.  The break point will then be
	; automatically removed by it's handler (OneTimeBreakHandler) so we
	; don't keep an INT 3.  You see, INT 3 and ComInterrupts DO work
	; together, so we can sit in the INT 3 all day without conflict.
	;                                          -- lshields 12/04/2000

   DPC      DEBUG_CTRL_C, 'U'
                ; Only do the special case for INTERRUPT packets

	; ANother cheat -- I guess I could write a routine for this.  We're
	; going to peek into the upcoming packet in the buffer for the
	; rh_procNum.  We don't want to set a break point in the return
	; code unless the programmer is interrupting the flow of things
	; and wants to stop immediately.  I look at that buffer
	; directly since we just got data in above. -- lshields 12/04/2000

                push    bx
		mov	bx, ds:[comIn].head
                inc     bx
                and     bx, BUFSIZE-1
		mov	al, ds:[comIn].data[bx]
   DA       DEBUG_CTRL_C, <push ax>
   DPB      DEBUG_CTRL_C, bl
   DA       DEBUG_CTRL_C, <pop ax>
                cmp     al, RPC_INTERRUPT
                pop     bx
                jne     continueDoRpcStuff

                call BreakOnComReturn
                jmp ComCheckTrans

continueDoRpcStuff:
	;
	; An RPC packet is waiting to be dispatched. At this point, we
	; need to re-enable interrupts for the serial line (since it
	; may be a while before we return), save state, call Rpc_Wait,
	; restore state and return.
	; 
	; Signal end-of-interrupt to interrupt controller and
	; re-enable interrupts, as we may be gone for a while in
	; Rpc_Wait and we'll want to get interrupts from the com port.
	; This needs to be a specific end-of-interrupt since we're
	; likely to be in "special mask mode".
	;
PC_EOI2::
		mov	al, ICEOI
		out	ICEOIPORT, al
		cmp	ds:[com_IntLevel], 8
		jb	mrEnableInts
		out	ICEOIPORT2, al
mrEnableInts:
	;
	; Reenable interrupts from the chip. If a character came in
	; or the transmitter became ready while we were in here, this
	; will generate an interrupt when the eni instruction is
	; executed, below...
	; Note that we only enable the transmitter interrupt if we
	; actually expect an interrupt to come in. Otherwise, we will
	; loop infinitely getting transmitter interrupts each time we
	; re-enable interrupts for the device.
	;
                mov	dx, ds:[comCurIENPort]				
		mov	al, ds:[comRecvEnable]
		isset?	IRQPEND
		jz	CI1_5
		or	al, ds:[comTransEnable]
CI1_5:
                out	dx, al						
    	    	
	;
	; Restore registers/stack to their/its original state,
	; discarding the serial-line state. We need to restore the
	; state so the stack is set up as it always is -- with an
	; IRET frame just above the return address for SaveState.
	; This way, if the RPC being processed stops the machine,
	; an RPC_CONTINUE can continue in a consistent fashion.
	; 

		DISCARD_PROTECT
		inc	sp		; Discard line status
		inc	sp

		pop	ds		; Restore saved registers
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		call	SaveState   	; Save our state before enabling
					; interrupts -- this guarantees we
					; won't be context-switched out.
		call	Rpc_Wait    	; Do one Rpc thing 
		dsi 	    	    	; No Context Switch, thanks
		call	RestoreState	; Go back to previous state
		iret			; Return now.
ComInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakOnComReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a self-clearing break point when the ComInterrupt 
		returns so that we can halt the machine.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakOnComReturn	proc	near
                uses si, bp
		.enter
   DPS      DEBUG_CTRL_C, <BreakOnComReturn>
		; We need a regular break point
		mov	cx, size BptClient
		call	Bpt_Alloc
		mov	al, RPC_TOOBIG
		tst	si
		jz	noRoom

		; But make it go to our handler so it will delete
		; itself.		
		mov	ds:[si].BC_handler, offset OneTimeBreakHandler
		mov	ds:[si].BC_flags, 0

		; HACK ALERT!  DPMI calls ComInterrupt via reflector.
		; This means the immediate iret doesn't go back to the
		; place in the code where all of this started.  In fact,
		; it built out it's own special stack for us to play
		; work within.  But, they did do two nice things
		;
		; 1) The stack is always the same size of 1K
		; 2) The return vector to the actual code (not the
		;    reflector) is the top 6 bytes of the stack.
		;
		; With the above two assumptions, we have the top as
		; follows:
		;    SS:0xFFE - flags
		;    SS:0xFFC - cs
		;    SS:0xFFA - ip
		;
		; We just grab the suckers and set a breakpoint.
		; This even works if we are an interrut within an
		; another exception reflector (although I think 
		; something gets trashed).

                mov     bp, sp
                mov cx, ss:[0xFFC]
                mov dx, ss:[0xFFA]
                mov     ax, BPT_NOT_XIP

		mov	bx, si		; bx <- client data
		call	Bpt_Set
		tst	si
		jz	noRoomFreeClient
		
	DPC	DEBUG_BPT, '#'
	DPC	DEBUG_BPT, '#'
	DPC	DEBUG_BPT, 'i'
	DPW	DEBUG_BPT, es
	DPW	DEBUG_BPT, ds
	DA	DEBUG_BPT, <push ds, bx>
	DA	DEBUG_BPT, <lds bx, ds:[si].BD_addr>
	DPW	DEBUG_BPT, ds:[bx]
	DA	DEBUG_BPT, <pop ds, bx>

		; Well, this is probably not correct, but I didn't know
		; how to go about it for now.  The main problem is we don't
		; call RestoreState at any point so the break point we just
		; lovingly created isn't installed.  So, I just go ahead
		; and install them all.  The next bit of code to run is
		; going to be where we placed the break point, so we are
		; gauranteed to hit that (hmmm ... I wonder about a context
		; switch immediately .... oh well).  -- lshields 12/4/2000

                call Bpt_Install

done:
		.leave
		ret

noRoomFreeClient:
		mov	si, bx
		call	Bpt_Free
noRoom:
		call	Rpc_Error
		jmp	done
BreakOnComReturn	endp

OneTimeBreakHandler	proc	near
		.enter
                call    Bpt_Clear
		mov	cx, mask BCS_TAKE_IT or mask BCS_UNCONDITIONAL
		mov	ax, BCR_OK
		.leave
		ret
OneTimeBreakHandler	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_Read
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
Com_Read	proc	near
		push	bx

		tst	ds:[comIn].numChars		; Anything waiting?
		jz	ComReadRet		; Nope

		mov	bx, ds:[comIn].head
		mov	al, ds:[comIn].data[bx]
		dec	ds:[comIn].numChars
		Update	ds:[comIn].head, bx
		or	bx, 1			; Make sure Z is clear
ComReadRet:
		pop	bx
		ret
Com_Read	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_Write
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
Com_Write	proc	near
		uses	ax, bx, dx, ds
		.enter

		DA	DEBUG_COM_OUTPUT, <push ax>
		DPC	DEBUG_COM_OUTPUT, 'o'
		DA	DEBUG_COM_OUTPUT, <pop ax>
		DPB	DEBUG_COM_OUTPUT, al

		PointDSAtStub
		dsi			; So we don't miss the interrupt...

		mov	bx, ds:[comOut].tail
		mov	ds:[comOut].data[bx], al
		Update	ds:[comOut].tail, bx
		inc	ds:[comOut].numChars
		isset?	IRQPEND
		jz	ComForceInt	; No interrupt will come -- force one
					; to transmit first character
ComWriteReturn:
		eni
		.leave
		ret

ComForceInt:
                mov	dx, ds:[comCurIENPort]				
		mov	al, COMRECVENABLE OR COMTRANSENABLE

		out	dx, al

		set	IRQPEND		; Note interrupt arriving
		jmp	short ComWriteReturn
Com_Write	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_ReadBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block of bytes from the serial line

CALLED BY:	Rpc_Wait

PASS:		DI = Offset of buffer
		ES = Segment of buffer
		CX = Number of bytes to read

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
Com_ReadBlock	proc	near
		cld
		jcxz	ComReadBlockRet
ComReadBlock1:
		call	Com_Read
		jz	ComReadBlock1
		stosb
		loop	ComReadBlock1
ComReadBlockRet:
		ret
Com_ReadBlock	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_WriteBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a block of data from a buffer

CALLED BY:	Rpc_Call, Rpc_Reply

PASS:		SI = offset of buffer
		ES = segment of buffer
		CX = number of bytes to write

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
Com_WriteBlock	proc	near
		cld
		jcxz	ComWriteBlockRet
ComWriteBlock1:
		lods	byte ptr es:[si]
		call	Com_Write
		loop	ComWriteBlock1
ComWriteBlockRet:
		ret
Com_WriteBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_WriteMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a message to the serial line, dealing with proper
		link-level framing, checksumming, etc.

CALLED BY:	EXTERNAL
PASS:		ds:si	= buffer to write as a single message
		cx	= # bytes in the buffer
RETURN:		nothing
DESTROYED:	si, cx, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Com_WriteMsg	proc	near
		.enter
		clr	ah		; initialize checksum to 0
		mov	al, RPC_MSG_START
		call	Com_Write
writeLoop:
		lodsb
		add	ah, al
		call	writeIt
		loop	writeLoop
		neg	ah		; form two's-complement of the sum
		mov	al, ah		;  and write it out so the sum of
		call	writeIt		;  the unquoted bytes on the other
					;  end will be 0.
		mov	al, RPC_MSG_END
		call	Com_Write
		.leave
		ret

; internal routine to write a byte out to the serial line, taking required
; quoting into consideration.
; 	Pass:	al 	= byte to write
; 	Return:	nothing
; 	Destroy:al
; 
writeIt:
		cmp	al, RPC_MSG_START
		je	quoteStart
		cmp	al, RPC_MSG_END
		je	quoteEnd
		cmp	al, RPC_MSG_QUOTE
		je	quoteQuote
doWrite:
		call	Com_Write
		retn
quoteStart:
		mov	al, RPC_MSG_QUOTE
		call	Com_Write
		mov	al, RPC_MSG_QUOTE_START
		jmp	doWrite
quoteEnd:
		mov	al, RPC_MSG_QUOTE
		call	Com_Write
		mov	al, RPC_MSG_QUOTE_END
		jmp	doWrite
quoteQuote:
		mov	al, RPC_MSG_QUOTE
		call	Com_Write
		mov	al, RPC_MSG_QUOTE_QUOTE
		jmp	doWrite
Com_WriteMsg	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Com_ReadMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single message from the serial line

CALLED BY:	Rpc_Wait
PASS:		es:di	= place to store message
		ds	= cgroup
		cx	= size of buffer
RETURN:		carry set if message was corrupt.
		carry clear if message was ok:
			cx	= size of message, 0 if no message present
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Com_ReadMsg	proc	near
		uses	dx, bx
		.enter
	;
	; If no messages queued, we can't read one.
	; 
		tst	ds:[com_NumMessages]
		jz	noMessages
		DPC	DEBUG_MSG_PROTO, 'R', inverse

		clr	ah		; initialize checksum
		mov	dx, di		; save buffer start for size calculation
readLoop:
		call	Com_Read
		jz	readLoop

		DPB	DEBUG_MSG_PROTO, al
		
		cmp	al, RPC_MSG_END	; end of message?
		je	checkMsg	; yes -- make sure the checksum's ok
					;  and figure the total length of
					;  the message

	;
	; If byte is quoted, go unquote it.
	; 
		cmp	al, RPC_MSG_QUOTE
		je	handleQuote
storeIt:
	;
	; Store the byte in the buffer, making sure there's room. If there
	; isn't room, we return with cx == 0
	; 
		add	ah, al
		jcxz	done		; => message can't fit
		stosb
		loop	readLoop
checkMsg:
	;
	; Message is complete. Since the checksum is the negative of the
	; sum of all the preceding unquoted bytes, when we added the checksum
	; in just now, our total (in AH) will be 0 if the message is ok.
	; 
		tst	ah	; checksum must be 0 or message is bad
		jnz	checksumError

	;
	; Calculate the length of the message, exclusive of the checksum,
	; by subtracting our buffer pointer (which points past the checksum)
	; from the start of the buffer + 1.
	; 
		stc
		sbb	di, dx		; di -= dx+1 to get # bytes w/o
					;  checksum
		mov	cx, di
done:
	;
	; One fewer message in the input buffer...
	; 
		dec	ds:[com_NumMessages]
laterDaze:
		.leave
		ret
checksumError:
		DPC	DEBUG_MSG_PROTO, 'C'

error:
		stc
		jmp	done

noMessages:
		clr	cx
		jmp	laterDaze
handleQuote:
	;
	; Deal with a quote sequence. Fetch the next byte, which must be
	; one of RPC_MSG_QUOTE_START, RPC_MSG_QUOTE_END, or RPC_MSG_QUOTE_QUOTE
	; or we declare the message corrupt.
	; 
		call	Com_Read
		jz	handleQuote
		
		DPB	DEBUG_MSG_PROTO, al
		
		mov	bl, RPC_MSG_START	; assume start
		cmp	al, RPC_MSG_QUOTE_START
		je	haveUnquoted
		
		mov	bl, RPC_MSG_END		; assume end
		cmp	al, RPC_MSG_QUOTE_END
		je	haveUnquoted
		
		cmp	al, RPC_MSG_QUOTE_QUOTE
		jne	skipToEnd
		mov	bl, RPC_MSG_QUOTE
haveUnquoted:
		mov	al, bl
		jmp	storeIt

skipToEnd:
	;
	; Message is corrupt, but we still need to read bytes until we
	; encounter the RPC_MSG_END...
	; 
		cmp	al, RPC_MSG_END
		je	error
skipLoop:
		call	Com_Read
		jnz	skipToEnd

		DPB	DEBUG_MSG_PROTO, al
		
		DPC	DEBUG_MSG_PROTO, 'Q'

		jmp	skipLoop
Com_ReadMsg	endp

scode		ends
		end

endif   ; !def WINCOM
endif	; !def NETWARE
