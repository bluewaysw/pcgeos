COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Template

DATEI:		bstimer.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init

ROUTINEN:
	Name			Description
	----			-----------


Beschreibung:
	This contains all the structures, enum types and constants needed
	to program the I8255 and I8253.  These chips, in case you are
	not familiar with them, are what are used to program the PC
	speaker.

	Note:  Most of this was lifted off of the original sound code
	(written by adam).  That is why it looks so organized in
	comparison to the rest of the code....

*****************************************************************@

;-----------------------------------------------------------------------------
;	8255 Chip Description
;-----------------------------------------------------------------------------
I8255		equ	60h		; port address for 8255

PBBites	record				; The 8255 controls functions of PC
	PBB_KBD_CLR:1=1,		; Clear keycode-ready latch
	PBB_KBD_DISABLE:1=1,		; Don't accept data from keyboard
	PBB_IOCHK_ENBL:1=0,		; Enable I/O Channel Check NMIs
	PBB_PCHK_ENBL:1=0,		; Enable Memory Parity Check NMIs
	PBB_CASS_OFF:1=1,		; Turn off cassette motor
	PBB_READ_MEMSZ:1,
	PBB_SPKR_ENBL:1=1,		; Allow timer output to get to speaker
	PBB_GATE2:1=1,			; Let timer 2 count
PBBits	end

SPKR_ON		equ	mask PBB_SPKR_ENBL or mask PBB_GATE2
SPKR_OFF	equ	NOT mask PBB_SPKR_ENBL

I8255Map	struct
	portA	byte
	portB	PBBites
	portC	byte
	Control	byte
I8255Map	ends


;-----------------------------------------------------------------------------
;	8253 Chip Description
;-----------------------------------------------------------------------------
I8253		equ	40h			; port address of 8253

TIMER_SPEED	equ	1193180			; 1.193180 MHz clock

TICKS_PER_MICRO	equ	TIMER_SPEED / 1000000	; counter ticks per micro sec.

TTimers		etype 	byte, 0,  64
	TT_TIMER_0		enum TTimers	; system clock (don't touch!)
	TT_TIMER_1		enum TTimers	; memory refresh (don't touch!)
	TT_TIMER_2		enum TTimers	; speaker driver (ok.  touch.)

TReadLoad	etype 	byte, 0, 16
	TRL_LATCH		enum TReadLoad	; Latch for read
	TRL_MSB_ONLY		enum TReadLoad	; Load MSB of counter only
	TRL_LSB_ONLY		enum TReadLoad	; Load LSB of counter only
	TRL_WORD		enum TReadLoad	; Load full counter low-high

TModes		etype 	byte, 0, 2		; counting modes for timers
	TM_ONE_SHOT		enum TModes
	TM_RETRIG_ONE_SHOT	enum TModes
	TM_RATE_GEN		enum TModes
	TM_SQUARE_WAVE		enum TModes
	TM_SW_STROBE		enum TModes
	TM_HW_STROBE		enum TModes

TCodes		etype 	byte, 0, 1		; conting format
	TC_BINARY		enum TCodes
	TC_BCDECIMAL		enum TCodes

TControl	record
	TC_SEL			:2,
	TC_RD_LD TReadLoad	:2,
	TC_MODE	 TModes		:3,
	TC_BCD			:1,
TControl	end


I8253Map	struct
	Counter0	byte			; Port to counter 0
	Counter1	byte			; Port to counter 1
	Counter2	byte			; Port to counter 2
	Mode		byte			; Mode
I8253Map	ends




;-----------------------------------------------------------------------------
;		SPEAKER CONTROL MACROS
;-----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPEAKER_OFF/SPEAKER_ON
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable/Enable the speaker

CALLED BY:	GlobalMacro
PASS:		Nothing
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		Tweak the controller to stop passing timer 2 to the
		speaker.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/23/89		Initial version
	TS	7/29/92		copied to new sound library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPEAKER_OFF	macro
	in	al, I8255.PortB
	and	al, SPKR_OFF
	jmp	$+2			; Delay for fast computers
	jmp	$+2			; Delay for fast computers
	out	I8255.PortB, al
	jmp	$+2			; Delay for fast computers
	endm

SPEAKER_ON	macro
	in	al, I8255.PortB
	or	al, SPKR_ON
	jmp	$+2			; Delay for fast computers
	jmp	$+2			; Delay for fast computers
	out	I8255.PortB, al
	jmp	$+2			; Delay for fast computers
	endm
