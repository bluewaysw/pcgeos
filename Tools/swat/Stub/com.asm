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

ifdef ZOOMER
include pcmcia.def
hardwareType	HardwareType	HT_ZOOMER	; default is for the ZOOMER
else
hardwareType	HardwareType	HT_PC		; default is for the PC
endif
ifdef RESPONDER
include respcom.def
else
include com.def
endif

; PENELOPE: additional com defintions are in penelope.def


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

; initialize all the values for the ZOOMER, if that turns out not to
; be the case, these values will be overwritten with the proper values
comIntVec	dword
comIntVecNum	word
com_IntLevel	byte			; Interrupt level
		even

;
; The four ports needed by the interrupt routine. These are set up by Com_Init
; based on the device being used.
;
ifndef PENELOPE		; Penelope doesn't use these... it's all fixed.

comDataInPort	word	
comDataOutPort	word	
comCurIRQPort	word
comCurStatPort	word
comCurIENPort	word

endif ;not PENELOPE	; -----------------------

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

stubInit	segment
    	    	assume	    cs:stubInit,ds:cgroup,es:cgroup,ss:sstack
ComPortData	struct
    CPD_portMask	word		; Mask for figuring out other
    					; ports for the channel. The number
					; being masked is 3fXh where X is
					; 8 through f
    CPD_level		word		; Interrupt level (as far as
					; interrupt controller is concerned)
ComPortData	ends

ifdef	RESPONDER
ports		ComPortData	<003ffh,5>	; COM1 (3f8, level 4)
		ComPortData	<002ffh,6>	; COM2 (2f8, level 3)
		ComPortData	<003efh,4>	; COM3 (3e8, level 4)
		ComPortData	<002efh,3>	; COM4 (2e8, level 3)
		ComPortData	<0f8ffh,3>	; COM5 (debug port at f8f8)
elseifdef PENELOPE
    ; Don't need "ports" for Penelope; the debug port is fixed.
    ;

elseifdef DOVE
ports		ComPortData	<0ffffh,4>	; COM1 (3f8, level 4)
		ComPortData	<0feffh,3>	; COM2 (2f8, level 3)
		ComPortData	<0ffefh,7>	; COM3 (3e8, level 7)
		ComPortData	<0feefh,5>	; COM4 (2e8, level 5)
else
ports		ComPortData	<0ffffh,4>	; COM1 (3f8, level 4)
		ComPortData	<0feffh,3>	; COM2 (2f8, level 3)
		ComPortData	<0ffefh,4>	; COM3 (3e8, level 4)
		ComPortData	<0feefh,3>	; COM4 (2e8, level 3)
endif

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
ifdef	RESPONDER
MAX_PORT	equ	'5'
else
MAX_PORT	equ	'4'
endif

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
ifndef ZOOMER
		xchg	ax, dx	; ax <- baud

	irp	baud, <300,1200,2400,4800,9600,19200,38400>
		mov	dx, BAUD_&baud
		cmp	ax, baud
		je	SDB_done	; (carry clear if branch taken)
	endm
else
		call	Com_GetHardwareType
		cmp	ax, HT_PC
		jne	doZoomerBaud
		xchg	ax, dx	; ax <- baud

	irp	baud, <2400,4800,9600,19200,38400>
		mov	dx, PCMCIA_BAUD_&baud
		cmp	ax, baud
		je	SDB_done	; (carry clear if branch taken)
	endm
doZoomerBaud:
		xchg	ax, dx	; ax <- baud

	irp	baud, <300,1200,2400,4800,9600,19200,38400>
		mov	dx, Z_BAUD_&baud
		cmp	ax, baud
		je	SDB_done	; (carry clear if branch taken)
	endm
endif
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
	segmov	ds, cs
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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchBaudArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the baud arg based on hardware type

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/15/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef ZOOMER
ComFetchBaudArg	proc	near
		uses	ax
		.enter
		call	Com_GetHardwareType
		cmp	ax, HT_PC
		jne	doZoomer
		call	ComFetchPCMCIABaudArg
		jmp	done
doZoomer:
		call	ComFetchZoomerBaudArg
done:
		.leave
		ret
ComFetchBaudArg	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchPCBaudArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a /b argument, if there is one, and transform it
		into a baud rate divisor.

CALLED BY:	(INTERNAL) Com_Init
PASS:		es	= stubInit
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
		assume	es:stubInit
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
		mov	cs:[comBaud], ax; save divisor for later
done:
		assume	es:cgroup
		.leave
		ret
ComFetchPCBaudArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchPCMCIABaudArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a /b argument, if there is one, and transform it
		into a baud rate divisor.

CALLED BY:	(INTERNAL) Com_Init
PASS:		es	= stubInit
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
ifdef ZOOMER
ComFetchPCMCIABaudArg	proc	near
		.enter
		assume	es:stubInit
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
		mov	al, PCMCIA_BAUD_9600	
		cmp	ah, '9'		; check for 9600 as value
		je	setNewBaud

		mov	al, PCMCIA_BAUD_38400	; check for 38400 baud
		cmp	ah, '3'
		je	setNewBaud

		mov	al, PCMCIA_BAUD_4800	; check for 4800 baud
		cmp	ah, '4'		; 
		je	setNewBaud	; use 4800 baud

		mov	al, PCMCIA_BAUD_2400	; check for 2400 baud
		cmp	ah, '2'		; 
		je	setNewBaud	; use 2400 baud
use19_2:
		mov	al, PCMCIA_BAUD_19200	; if no match, use 19200
setNewBaud:
		clr	ah
		mov	cs:[comBaud], ax; save divisor for later
done:
		assume	es:cgroup
		.leave
		ret
ComFetchPCMCIABaudArg	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchZoomerBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch the zoomer baud rate

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/15/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef ZOOMER

ComFetchZoomerBaudArg	proc	near
		.enter
		assume	es:stubInit
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
		mov	al, Z_BAUD_9600	
		cmp	ah, '9'		; check for 9600 as value
		je	setNewBaud

		mov	al, Z_BAUD_38400	; check for 38400 baud
		cmp	ah, '3'
		je	setNewBaud

		mov	al, Z_BAUD_4800	; check for 4800 baud
		cmp	ah, '4'		; 
		je	setNewBaud	; use 4800 baud

		mov	al, Z_BAUD_2400	; check for 2400 baud
		cmp	ah, '2'		; 
		je	setNewBaud	; use 2400 baud

		mov	al, Z_BAUD_1200	; check for 1200 baud
		cmp	ah, '1'		; 
		jne	use19_2		; no, use 19200 baud
		cmp	es:[baudrate][1], '2'	; check for 1200, vs. 19200
		je	setNewBaud	;  yes, use 1200
use19_2:
		mov	al, Z_BAUD_19200	; if no match, use 19200
setNewBaud:
		clr	ah
		mov	cs:[comBaud], ax; save divisor for later
done:
		assume	es:cgroup
		.leave
		ret
ComFetchZoomerBaudArg	endp
endif

ifndef	PENELOPE		; not needed for PENELOPE ------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComFetchPortArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a /c argument, if there is one, and override the
		default port with its value.

CALLED BY:	(INTERNAL) Com_Init
PASS:		es	= stubInit
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
		assume	es:stubInit
		mov	di, offset devarg
		mov	bx, offset device
		mov	dx, length device
		call	FetchArg

		cmp	bx, offset device
		je	done
		mov	al, es:[device]
		cmp	al, '1'
		jl	done
		cmp	al, MAX_PORT
		jg	done
		sub	al, '0'

		mov	cs:[comPort], al
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
PASS:		es	= stubInit
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
		assume	es:stubInit
		mov	di, offset irqarg
		mov	bx, offset irqbuf
		mov	dx, length irqbuf-1
		call	FetchArg

		cmp	bx, offset irqbuf
		je	done

		DPC	DEBUG_COM_INIT, '/'
		DPC	DEBUG_COM_INIT, 'i'
		segmov	ds, cs
		mov	si, offset irqbuf
		call	ComDetermineIRQ
		mov	cs:[comIRQ], al
done:		
		assume	es:cgroup
		.leave
		ret
ComFetchIRQArg	endp

endif	;not PENELOPE		; not needed for PENELOPE ------------------


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
ifndef ZOOMER
ifndef PENELOPE
ComInitPC	proc	near
		.enter
		push	es
		segmov	es, cs

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

		assume	es:stubInit
		;
		; Fetch the port mask and interrupt level now so we have no
		; further need for the port data.
		;
		mov	al, cs:[comIRQ]
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

ifdef	DOVE
		;
		; BIOS sets DPCF_14MON to off by default.  We need to turn it
		; on so that we can use the real com4 on hardware.
		;
		; Theoretically we need to wait for 50ms before we can use the
		; port, but it takes much longer for the user to tell the host
		; swat to connect anyway.  So we don't bother waiting here.
		;
		mov	dx, DOVE_POWCTRL
		in	ax, dx
		BitSet	ax, DPCF_14MON
		out	dx, ax
endif	; DOVE

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
ifdef JEDI
		mov	al, COMRTS OR COMOUT2
else
		mov	al, COMDTR OR COMRTS OR COMOUT2
endif

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
endif	;not PENELOPE
endif	;not ZOOMER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComInitPenelope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the "debug" memory-mapped COM port on the
		Penelope prototype

CALLED BY:	Com_Init

PASS:		ds	= cgroup
		es	= cgroup

RETURN:		noting

DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef PENELOPE

useDebugPortString	char	'PENELOPE swat v1.2.  Use DEBUG port for'
			char	' serial connection.\n\n\r$'

ComInitPenelope	proc	near

		push	ds
		segmov	ds, cs, dx
		mov	dx, offset useDebugPortString
		mov	ah, 9h
		int	21h
		pop	ds
		
		mov	ds:[comdAvail], COMDAVAIL
		mov	ds:[comThre], COMTHRE
		mov	ds:[comRecvEnable], COMRECVENABLE
		mov	ds:[comTransEnable], COMTRANSENABLE
		
		DPC	DEBUG_COM_INIT, 'P'
		DPC	DEBUG_COM_INIT, 'A'
		mov	ds:[com_IntLevel], DCOM_IRQ
		DPB	DEBUG_COM_INIT, ds:[com_IntLevel]
		mov	ds:[comIntVecNum], DCOM_VEC
		DPW	DEBUG_COM_INIT, ds:[comIntVecNum]
		DPW	DEBUG_COM_INIT, cs:[comBaud]
		
		mov	ax, ds:[comIntVecNum]
		mov	bx, offset comIntVec	; address to store old vec
		mov	dx, offset ComInterrupt	; our vector
		call	SetInterrupt
		
	; These two I/O commands ensure that IRQ11 comes from pin #124 on
	; the E3G.
	;
	    ; Set the Global Peripheral Disable Register on the E3G such that
	    ; the input to IRQ11 on the second PIC comes from SPKR.
	    ;
		mov	dx, E3G_GLOBALDIS
		in	ax, dx
		or	ax, 4			; BIT 2=1 - Disable TIMER2
		out	dx, ax
		
	    ; Set the Pin Configuration Register 4 on the E3G such that the
	    ; internal line "SPKR" is connected to the E3G's package pin #124.
	    ;
		mov	dx, E3G_PINCFG4
		in	al, dx
		and	al, not 2		; BIT 1=0 - SPKR conn. to pin
		out	dx, al
		
	; Set the EMS window so we can access the memory-mapped registers
	;
	    ; Init the EMS window location to the right segment.  
	    ; Everything in the system expects it there anyway, so let's set
	    ; it to be sure for ourselves.
	    ;
		mov	dx, DCOM_EMS_COMP_REGISTER
		mov	al, 80h or (DCOM_SEGMENT shr 10)
		out	dx, al
		
		pushf				; Ints off while EMS page
		dsi				; is open.
		call	PenelopeDCOMOpenFar
		push	es
		segmov	es, DCOM_IO_SEGMENT, ax
		
	; Enable Divisor Latch to program Baud Rate
	;
		mov	{byte} es:[DCOM_LINEPORT], 80h
		
	; Install the baud rate divisor (write the whole word at once)
	;
		mov	ax, cs:[comBaud]
		mov	es:[DCOM_DLLPORT], al
		mov	es:[DCOM_DLHPORT], ah
		
	; Initialize the port to 8 bits, no parity, 1 stop bit.  Disable the
	; Divisor Latch.
	;
		mov	{byte} es:[DCOM_LINEPORT], 3
		
	; Enable DTR, RTS and OUT2.  The first 2 because they're expected.
	; OUT2 enables interrupts to be sent to the PIC.
	;
		mov	{byte} es:[DCOM_MODEMPORT], COMDTR or COMRTS or COMOUT2
		
	; Make sure the input buffer is clear and the interrupt-
	; pending flag is clear by reading the buffer now. If we
	; don't and for some reason an interrupt is already pending
	; from the device, we're hosed.
	;
		mov	al, es:[DCOM_DATAPORT]
	
	; Enable the receiver interrupts.  We've nothing to transmit now so
	; don't enable transmitter interrupts.
	;
		mov	{byte} es:[DCOM_IENPORT], COMRECVENABLE
		
	; Restore the EMS page as it was.
	;
		pop	es
		call	PenelopeDCOMCloseFar
		popf				; Restore ints.
		
	; Enable interrupts from the PIC
	;
	; Do whatever ComInitPC does to COM_Mask{1,2} and PIC{1,2}_Mask and
	; enable the interrupts in PIC2 because we know it's PIC2.
	;
		mov	ds:[COM_Mask1], 0
		
		mov	ah, DCOM_INTMASK
		mov	ds:[COM_Mask2], ah
		not	ah
		and	ds:[PIC2_Mask], ah
		
		mov	dx, ICMASKPORT2
		in	al, dx
		and	al, ah			; clear/enable our interrupt
		out	dx, al
		
		DPC	DEBUG_COM_INIT, 'M'
		DPB	DEBUG_COM_INIT, ds:[COM_Mask1]
		DPB	DEBUG_COM_INIT, ds:[PIC1_Mask]
		DPB	DEBUG_COM_INIT, ds:[COM_Mask2]
		DPB	DEBUG_COM_INIT, ds:[PIC2_Mask]
		mov	dx, ICMASKPORT
		in	al, dx
		DPB	DEBUG_COM_INIT, al
		mov	dx, ICMASKPORT2
		in	al, dx
		DPB	DEBUG_COM_INIT, al
		
		ret
ComInitPenelope	endp

endif ;PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComInitPCMCIA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do init for a PCMCIA

CALLED BY:	Com_Init

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
ifdef ZOOMER
ComInitPCMCIA	proc	near
		.enter
		mov	ds:[comIntVecNum], 78h
		mov	ds:[comCurIENPort], PCMCIA_COMIENPORT
		mov	ds:[comCurIRQPort], PCMCIA_COMIRQPORT
		mov	ds:[comCurStatPort],PCMCIA_COMSTATPORT
		mov	ds:[comdAvail], COMDAVAIL
		mov	ds:[comThre], COMTHRE
		mov	ds:[comRecvEnable], COMRECVENABLE
		mov	ds:[comTransEnable],COMTRANSENABLE
		mov	ds:[comIrq], 38h
		DPB	DEBUG_COM_INIT, PCMCIA_COMIRQ

	;
	; Now process the values we won so painfully.
	; 
		;
		; Fetch the port mask and interrupt level now so we have no
		; further need for the port data.
		;
		assume	es:cgroup
		

		;
setIOPorts:
		;
		; Set up comDataInPort, comCurStatPort and comCurIRQPort
		; for ComInterrupt 
		;
		mov	ax, PCMCIA_COMDATAPORT
		; these are the same for a PC, different for the Zoomer
		mov	ds:[comDataInPort], ax
		mov	ds:[comDataOutPort], ax

		mov	ax, PCMCIA_COMSTATPORT
		mov	ds:[comCurStatPort], ax

		mov	ax, PCMCIA_COMIRQPORT
		mov	ds:[comCurIRQPort], ax

		call	PCMCIAInitCard

		;
		; Enable interrupts from the device in the interrupt controller

		mov	dx, ICMASKPORT
		in	ax, dx		; get old mask
		and	ax, not 0100h
		out	dx, ax
		mov	ds:[COM_Mask1], 80h	; keep pen on
		mov	ds:[COM_Mask2], 01h
		; lets turn on power for the PCMCIA card
		;
		; put in our interrupt handler
		; Fetch original vector and stuff in ours in its place.
		;
;		mov	ax, ds:[comIntVecNum]
;		lea	bx, ds:[comIntVec]
;		mov	dx, offset ComInterrupt	; Our routine in DX
;		call	SetInterrupt		; Do it.

		mov	al, 40h		; 1 wait set
		out	00cch, al	; wait control register

		cli
		mov	dx, PCMCIA_COMIENPORT
		clr	al
		out	dx, al		; turn off interrupt permissions
		sti
		mov	dx, PCMCIA_COMLINEPORT
		mov	al, 80h		; DLAB = 1
		cli
		out	dx, al

		;
		; Actually install the baud rate divisor
		; 
		mov	ax, cs:[comBaud]
		mov	dx, PCMCIA_COMDLLPORT
		out	dx, ax

		;
		; Make sure the interrupt enable port and data port are
		; actually at the appropriate addresses by clearing the
		; Divisor Latch Access Bit in the line control register.
		; Also make sure the line is in the format we want:
		;	8 data bits
		;	1 stop bit
		;	no parity
		; qv. Options and Adapters vol. 2 for more info
		;
		mov	dx, PCMCIA_COMLINEPORT
		mov	al, 3
		out	dx, al

		;
		; Turn on DTR, RTS and OUT2. The first 2 are on because that's
		; what terminals normally expect. OUT2 is on b/c it must be on
		; for interrupts to come through.
		;
		mov	dx, PCMCIA_COMMODEMPORT
		mov	al, COMDTR OR COMRTS OR COMOUT2
		out	dx, al

		;
		;
		; Make sure the input buffer is clear and the interrupt-
		; pending flag is clear by reading the buffer now. If we
		; don't and for some reason an interrupt is already pending
		; from the device, we're hosed.
		;
;		mov	dx, ds:[comDataInPort]
;		in	al, dx

		;
		; Enable the receiver interrupts. We've nothing to transmit
		; yet, so no point in enabling transmitter interrupts.
		;
		mov	dx, PCMCIA_COMIENPORT
		mov	al, COMRECVENABLE
		out	dx, al
		sti
		mov	dx, PCMCIA_COMIRQPORT		; dummy read
		in	al, dx
		mov	dx, PCMCIA_COMSTATPORT		; dummy read
		in	al, dx

		; be sure to unmask the serial port interrupt or we are
		; hosed!
		and	{byte}ds:[PIC2_Mask], 0feh
		and	{byte}ds:[PIC1_Mask], 0feh
		.leave
		ret
ComInitPCMCIA	endp
endif
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConInitZoomer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init com port for the zoomer

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
ifdef ZOOMER
ComInitZoomer	proc	near
		.enter
		assume	es:cgroup

		mov	ds:[comDataInPort], 57h
		mov	ds:[comDataOutPort], 56h
		mov	ds:[comIntVecNum], 74h
		mov	ds:[comCurIENPort], Z_COMIENPORT
		mov	ds:[comCurIRQPort], Z_COMIRQPORT
		mov	ds:[comCurStatPort],Z_COMSTATPORT
		mov	ds:[comdAvail], Z_COMDAVAIL
		mov	ds:[comThre], Z_COMTHRE
		mov	ds:[comRecvEnable], Z_COMRECVENABLE
		mov	ds:[comTransEnable], Z_COMTRANSENABLE
		mov	ds:[comIrq], 34h

		; first lets turn on the power and that kind o stuff
		mov	dx, Z_OUTPUTCONTROLPORT
		mov	al, Z_OUTPUTCONTROLENABLE
		out	dx, al

		mov	dx, Z_INPUTCONTROLPORT
		mov	al, Z_INPUTCONTROLPOWERON or Z_INPUTCONTROLACTIVE
		out	dx, al

		; make sure we are set to do serial communications
		; rather than infra-red
		mov	dx, Z_COMMEDIUMPORT
		mov	al, Z_COMSERIAL
		out	dx, al

		;
		; put in our interrupt handler
		;
		mov	ax, ds:[comIntVecNum]
		lea	bx, ds:[comIntVec]
		mov	dx, offset ComInterrupt	; Our routine in DX
		call	SetInterrupt		; Do it.
		;
		; Set the baud rate of the line. The baud rate is set by
		; dividing an 18.432 mhz clock by something. The divisors
		; Actually install the baud rate divisor
		; 
		mov	ax, cs:[comBaud]
		mov	dx, Z_COMDLLPORT
		out	dx, al
		;
		; The zoomer has a power mode field in this port,
		; which we set to asynchornous mode. See zoomer.def
		; for more details.
		;
		mov	dx, Z_COMLINEPORT
		mov	al, Z_COMPOWERENABLE or \
			    Z_COMRECVENABLE2 or \
			    Z_COMTRANSENABLE2 or \
			    Z_COMDATALENGTH or \
			    Z_COMPARITY or \
			    Z_COMSTOPBITS
		out	dx, al

		;
		; Turn on DTR, RTS and OUT2. The first 2 are on because that's
		; what terminals normally expect. OUT2 is on b/c it must be on
		; for interrupts to come through.
		;
		mov	dx, Z_COMMODEMPORT
		mov	al, Z_COMDTR OR Z_COMRTS OR Z_COMOUT
		out	dx, al
		;
		; Enable the receiver interrupt as we have nothing
		; to transmit yet.
		;
		mov	dx, ds:[comCurIENPort]
		mov	al, Z_COMRECVENABLE
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
		; clear the serial interrupt status before we enable the
		; interrupts
		;
		mov	dx, Z_COMINTCLEARPORT
		mov	al, Z_COMINTCLEARALL
		out	dx, al
		;
		; Reset the interrupt priorities so we don't get bothered
		; in the middle of talking to the serial port
		;
		clr	al
		out	SIO_IPR, al	; serial priority = 0
		inc	al
		out	TIMER0_IPR, al	; digitizer timer priority = 1
		inc	al
		out	TIMER1_IPR, al	; GEOS system timer priority = 2
		inc	al
		out	TIMER2_IPR, al	; timer 2 priority = 3
		;
		; Enable interrupts from the device in the interrupt controller
		;
		mov	dx, ICMASKPORT
 		mov	cl, Z_COMIRQ
		in	al, dx		; get old mask
		mov	ah, 1
		shl	ah, cl		; set up mask
		mov	ds:[COM_Mask1], ah
		mov	ds:[COM_Mask2], 0
		not	ah
		and	al, ah
		out	dx, al

		.leave
		ret
ComInitZoomer	endp
endif



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
ifdef ZOOMER
defaultComString char	"1,9600", 0
else
defaultComString char	"2,19200", 0
endif

Com_Init	proc	near
		;
		; Deal with arguments now, so we can get back to having DS
		; point at cgroup...
		;
		push	es
	;
	; Establish any defaults.
	; 
ifndef ZOOMER
		call	ComGetENVData
		jnc	haveDefaultString
endif
useDefault:
		segmov	es,cs
		mov	di, offset defaultComString
haveDefaultString:
		call	ComParseEnvString
		jc	useDefault

		mov	cs:[comBaud], dx
		mov	cs:[comIRQ], al
		mov	cs:[comPort], cl

		DPC	DEBUG_COM_INIT, 'X'
		DPB	DEBUG_COM_INIT, cl
		DPB	DEBUG_COM_INIT, al
		DPW	DEBUG_COM_INIT, dx
		
		;
		; First see if any /b flag given.  If not, use 19.2Kbaud
		;
		segmov	es,cs,di

		assume	es:stubInit
ifdef ZOOMER		
		call	ComFetchBaudArg
else
		call	ComFetchPCBaudArg
endif
		DPC	DEBUG_COM_INIT, 'B'
		DPW	DEBUG_COM_INIT, cs:[comBaud]

		pop	es		; restore es
ifdef ZOOMER
		call	Com_GetHardwareType
		DPW	DEBUG_COM_INIT, ax
		cmp	ax, HT_PC
		jne	doZoomerInit
		call	ComInitPCMCIA
		jmp	afterSpecificInit
doZoomerInit:
		call	ComInitZoomer
afterSpecificInit:

elseifdef PENELOPE
		call	ComInitPenelope
else
		call	ComInitPC
endif

done::
if 0
		mov	ax, 'a'
		call	ComWriteFar
		mov	ax, 'b'
		call	ComWriteFar	
		mov	ax, 'c'
		call	ComWriteFar	
		mov	ax, 'd'
		call	ComWriteFar	
		mov	ax, 'e'
		call	ComWriteFar
		mov	dx, 414h
		in	al, dx
		DPB	DEBUG_COM_INIT, al
endif
		clc
		ret
Com_Init	endp

stubInit	ends

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
	.enter
	mov	cs:[hardwareType], ax
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

ifdef PENELOPE
	; For Penelope, use memory-mapped I/O port.
	;
		pushf				; Ints off while EMS page
		dsi				; is open.
		call	PenelopeDCOMOpen
		push	ds
		segmov	ds, DCOM_IO_SEGMENT, ax
		mov	{byte} ds:[DCOM_IENPORT], 0
		pop	ds
		call	PenelopeDCOMClose
		popf				; Restore ints.
else
		mov	dx, ds:[comCurIENPort]
		clr	al
		out	dx, al
endif

		mov	ax, ds:[comIntVecNum]
		lea	bx, ds:[comIntVec]
		call	ResetInterrupt
		eni
		pop	bx
		pop	ax
		ret
Com_Exit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCMCIAInitCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init the PCMCIA card

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/19/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef ZOOMER
PCMCIAInitCard	proc	far
		uses	es, ax, dx
		.enter
		in	al, PSYS_VEC_PROTECT	; vector protect
		push	ax
		clr	ax
		out	PSYS_VEC_PROTECT, al		; protect off
		
		mov	es, ax
		mov	di, 78h * 4		; es:di = vector address
		mov	ax, offset ComInterrupt
		cld
		stosw
		mov	ax, cs
		stosw
		pop	ax
		out	PSYS_VEC_PROTECT, al

	; now activate the card

		mov	al, BCARD_MODE_REGE
		mov	dx, PCARD_MODE_AREA
		out	dx, al

		clr	al
		mov	dx, PCARD_ACTIVITY_CONTROL
		out	dx, al

		in	al, PPMG_POWER_CONTROL
		or	al, BPMG_POWER_P5S
		out	PPMG_POWER_CONTROL, al
		or	al, BPMG_POWER_PCP
		out	PPMG_POWER_CONTROL, al 

		mov	al, BCARD_RESET
		mov	dx, PCARD_RESET
		out	dx, al
				
		mov	al, BCARD_ACTIVITY_EN1
		mov	dx, PCARD_ACTIVITY_CONTROL
		out	dx, al

		clr	al
		mov	dx, PCARD_RESET
		out	dx, al

		mov	cx, SYS_WAIT_CARD_ON
		loop	$
		
		mov	al, (BCARD_ACTIVITY_EN1 or BCARD_ACTIVITY_EN2)
		mov	dx, PCARD_ACTIVITY_CONTROL
		out	dx, al

		mov	al, BCARD_MODE_IOE
		mov	dx, PCARD_MODE_AREA
		out	dx, al
		
		.leave
		ret
PCMCIAInitCard	endp
endif

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
PENE <		push	es						>
		PUSH_ENABLE
	
	;
	; For Penelope, set up the EMS window for the memory-mapped I/O and
	; point es at the correct segment.
	;
PENE <		call	PenelopeDCOMOpen				>
PENE <		segmov	es, DCOM_IO_SEGMENT, ax				>
	;
	; Preserve current control register (in case we interrupted
	; ourselves -- we can't just write protect on exit...)
	;
		DPB	DEBUG_COM_INPUT, 9
		mov	ax, cs
		mov	ds, ax			; set up ds for our own ease
ifndef ZOOMER
		cmp	cs:[hardwareType], HT_PC
		jne	CIIsOurs
	;
	; Make sure the interrupt's actually ours -- a bus mouse
	; shares the same interrupt level as COM2...
	;

ifdef PENELOPE		; For Penelope, use memory-mapped I/O port.
		mov	al, es:[DCOM_IRQPORT]
else
		mov	dx, ds:[comCurIRQPort]
		in	al, dx
endif
		test	al, 1
		jz	CIIsOurs
	;
	; Nope -- restore registers and pass control to old
	; handler.
	;
	;
	; Restore board control register -- NO FURTHER WRITES
	;

PENE <		call	PenelopeDCOMClose	; Restore EMS window	>

		POP_PROTECT
PENE <		pop	es						>
		pop	ds
		pop	dx
		pop	cx
		pop	bx
		pop	ax
		jmp	cs:comIntVec
CIIsOurs:
endif
	;
	; Force the interrupt output of the chip low by turning
	; off all interrupts. This makes sure the IRQ line makes it
	; all the way down before coming back up if an interrupt comes
	; in while we're in here.
	;
ifdef PENELOPE		; For Penelope, use memory-mapped I/O port.
		mov	{byte} es:[DCOM_IENPORT], 0
else
		mov	dx, ds:[comCurIENPort]
		clr	al
		out	dx, al
endif

	;
	; We've turned off interrupts from this device, so it's ok to
	; turn interrupts on now.
	;
		;eni	NO. Don't want to be context-switched out.

	;
	; Fetch current status bits
	;
ifdef PENELOPE		; For Penelope, use memory-mapped I/O port.
		mov	al, es:[DCOM_STATPORT]
else
		mov	dx, ds:[comCurStatPort]
		in	al, dx
endif
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
ifdef PENELOPE		; For Penelope, use memory-mapped I/O port.
		mov	al, es:[DCOM_DATAPORT]
else
		mov	dx, ds:[comDataInPort]
		in	al, dx			; Fetch the character
endif
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
ifdef ZOOMER
		cmp	cs:[hardwareType], HT_ZOOMER
		jne	doPCMCIA_EOI		
		; clear the serial interrupt status before we enable the
		; interrupts
		mov	dx, Z_COMINTCLEARPORT
		mov	al, Z_COMINTCLEARALL
		out	dx, al
		
		mov	cl, Z_COMIRQ
		mov	dx, ICEOIPORT
		jmp	doEOI
doPCMCIA_EOI:
		DPB	DEBUG_COM_INPUT, 1
		in	al, ICMASKPORT2
		and	al, not (PCMCIA_COMIRQ - 8)
		out	ICMASKPORT2, al
	
		mov	cl, PCMCIA_COMIRQ - 8
		mov	dx, ICEOIPORT2
doEOI:
		mov	al, 1
		shl	al, cl
		; now send the EOI so the IC knows that we are done
		out	dx, al
else
PC_EOI::
		mov	al, ICEOI
		out	ICEOIPORT, al

		cmp	ds:[com_IntLevel], 8	; second controller involved?
		jb	enableInts		; no
		out	ICEOIPORT2, al		; yes -- tell it we're done too
endif
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
NOPENE <	mov	dx, ds:[comCurIENPort]				>
		mov	al, ds:[comRecvEnable]
		isset?	IRQPEND
		jz	CI2
		or	al, ds:[comTransEnable]
CI2:
PENE <		mov	es:[DCOM_IENPORT], al				>
NOPENE <	out	dx, al						>
		;
		; Restore control register
		;
PENE <		call	PenelopeDCOMClose	; Restore EMS window	>
		
		POP_PROTECT
PENE <		pop	es						>
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

ifdef PENELOPE		; For Penelope, use memory-mapped I/O port.
		mov	es:[DCOM_DATAPORT], al
else
		mov	dx, ds:[comDataOutPort]
		out	dx, al			; and send it
endif

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
		
		cmp	ds:[com_NumMessages], 1
		ja	doRpcStuff		; => something got hosed, so
						;  field the message ourselves

		test	ds:[sysFlags], mask waiting or mask calling
		jnz	ComCheckTrans

doRpcStuff:		
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
ifdef ZOOMER
		cmp	cs:[hardwareType], HT_PC
		je	DO_EOI2
		mov	dx, Z_COMINTCLEARPORT
		mov	al, Z_COMINTCLEARALL
		out	dx, al
DO_EOI2:
		;
		; Signal end-of-interrupt to interrupt controller, restore
		; state and return.
		; we will to the unspecific EOI by setting the AFI bit
		; see page 15 of the hardware spec (9/25)
		in	al, ICEOIPORT2
		or	al, ICEOI		; non-specific EOI
		out	ICEOIPORT2, al
else
PC_EOI2::
		mov	al, ICEOI
		out	ICEOIPORT, al
		cmp	ds:[com_IntLevel], 8
		jb	mrEnableInts
		out	ICEOIPORT2, al
endif
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
NOPENE <	mov	dx, ds:[comCurIENPort]				>
		mov	al, ds:[comRecvEnable]
		isset?	IRQPEND
		jz	CI1_5
		or	al, ds:[comTransEnable]
CI1_5:
PENE <		mov	es:[DCOM_IENPORT], al				>
NOPENE <	out	dx, al						>
    	    	
	;
	; Restore registers/stack to their/its original state,
	; discarding the serial-line state. We need to restore the
	; state so the stack is set up as it always is -- with an
	; IRET frame just above the return address for SaveState.
	; This way, if the RPC being processed stops the machine,
	; an RPC_CONTINUE can continue in a consistent fashion.
	; 
PENE <		call	PenelopeDCOMClose	; Restore EMS window	>

		DISCARD_PROTECT
		inc	sp		; Discard line status
		inc	sp

PENE <		pop	es						>
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

		segmov	ds, cgroup, bx
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
NOPENE <	mov	dx, ds:[comCurIENPort]				>
		mov	al, COMRECVENABLE OR COMTRANSENABLE

ifdef PENELOPE		; For Penelope, use memory-mapped I/O port.
		pushf				; Ints off while EMS page
		dsi				; is open.
		call	PenelopeDCOMOpen
		push	ds
		segmov	ds, DCOM_IO_SEGMENT, bx
		mov	ds:[DCOM_IENPORT], al
		pop	ds
		call	PenelopeDCOMClose
		popf				; Restore ints.
else
		out	dx, al
endif

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

		DPC	DEBUG_MSG_PROTO, 'Q'

		jmp	skipLoop
Com_ReadMsg	endp

ifdef PENELOPE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PenelopeDCOMOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the EMS window to access the Debug COM port's
		memory mapped registers

CALLED BY:	COM module

PASS:		Interrupts OFF

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PenelopeEMSOld	word			; hold old EMS Register value to be
					; restored by PenelopeDCOMClose
					
penelopeOpenCount	byte	0
					
PenelopeDCOMOpenFar	proc	far
		call	PenelopeDCOMOpen
		ret
PenelopeDCOMOpenFar	endp

PenelopeDCOMOpen	proc	near
		push	ax
		push	dx
	;
	; Check that ints are off!
	;
DA		DEBUG_COM_INIT, <	pushf				>
DA		DEBUG_COM_INIT, <	pop	ax			>
DA		DEBUG_COM_INIT, <.186					>
DA		DEBUG_COM_INIT, <	shr	ax, 9	; I flag	>
DA		DEBUG_COM_INIT, <.8086					>
DA		DEBUG_COM_INIT, <	and	ax, 1			>
DA		DEBUG_COM_INIT, <	test	ax, 1			>
DA		DEBUG_COM_INIT, <	jz	noWorries		>
		DPC	DEBUG_COM_INIT, 'X'
		DPC	DEBUG_COM_INIT, 'O'
		DPC	DEBUG_COM_INIT, 'I'
		DPC	DEBUG_COM_INIT, '!'
DA		DEBUG_COM_INIT, <noWorries:				>
		
DA		DEBUG_COM_INIT, <	cmp	cs:[penelopeOpenCount], 0 >
DA		DEBUG_COM_INIT, <	je	noRepeats		>
		DPC	DEBUG_COM_INIT, '!', INVERSE
		DPC	DEBUG_COM_INIT, 'R', INVERSE
		DPC	DEBUG_COM_INIT, 'P', INVERSE
		DPC	DEBUG_COM_INIT, 'D', INVERSE
		DPC	DEBUG_COM_INIT, 'O', INVERSE
		DPB	DEBUG_COM_INIT, cs:[penelopeOpenCount]
DA		DEBUG_COM_INIT, <noRepeats:				>

		inc	cs:[penelopeOpenCount]
		
		mov	dx, DCOM_EMS_REGISTER
		in	ax, dx
		mov	cs:[PenelopeEMSOld], ax
		
		mov	ax, DCOM_BASE_PAGE_NUM
		out	dx, ax
		
		pop	dx
		pop	ax
		ret
PenelopeDCOMOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PenelopeDCOMClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores the EMS window set in PenelopeDCOMClose

CALLED BY:	COM module

PASS:		Interrupts OFF

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	5/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PenelopeDCOMCloseFar	proc	far
		call	PenelopeDCOMClose
		ret
PenelopeDCOMCloseFar	endp

PenelopeDCOMClose	proc	near
		push	ax
		push	dx
		
		dec	cs:[penelopeOpenCount]
	;
	; Check that ints are off!
	;
DA		DEBUG_COM_INIT, <	pushf				>
DA		DEBUG_COM_INIT, <	pop	ax			>
DA		DEBUG_COM_INIT, <.186					>
DA		DEBUG_COM_INIT, <	shr	ax, 9	; I flag	>
DA		DEBUG_COM_INIT, <.8086					>
DA		DEBUG_COM_INIT, <	and	ax, 1			>
DA		DEBUG_COM_INIT, <	test	ax, 1			>
DA		DEBUG_COM_INIT, <	jz	noWorries		>
		DPC	DEBUG_COM_INIT, 'X'
		DPC	DEBUG_COM_INIT, 'C'
		DPC	DEBUG_COM_INIT, 'I'
		DPC	DEBUG_COM_INIT, '!'
DA		DEBUG_COM_INIT, <noWorries:				>
		
		mov	dx, DCOM_EMS_REGISTER
		
DA		DEBUG_COM_INIT, <	in	ax, dx			>
DA		DEBUG_COM_INIT, <	cmp	ax, DCOM_BASE_PAGE_NUM	>
DA		DEBUG_COM_INIT, <	je	pageOK			>
		DPC	DEBUG_COM_INIT, 'X'
		DPC	DEBUG_COM_INIT, 'C'
		DPC	DEBUG_COM_INIT, 'P'
		DPC	DEBUG_COM_INIT, '!'
DA		DEBUG_COM_INIT, <pageOK:				>

		mov	ax, cs:[PenelopeEMSOld]
		out	dx, ax

		pop	dx
		pop	ax
		ret
PenelopeDCOMClose	endp

		
endif ;PENELOPE

scode		ends
		end

endif   ; !def WINCOM
endif	; !def NETWARE
