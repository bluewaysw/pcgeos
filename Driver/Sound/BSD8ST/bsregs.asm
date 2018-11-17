COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Template

DATEI:		bsregs.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init

ROUTINEN:
	Name			Description
	----			-----------
	SBDWriteFMReg		Write to a specific register on the FM chip
	SBDWriteFMRegFar	Far call location for register writes

Beschreibung:

*****************************************************************@

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDWriteFMReg,  SBDWriteFMRegFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write to a FM Synth register on the Sound Blaster boards

CALLED BY:	INTERNAL

PASS:		al	-> register address in FM chip to change
		ah	-> new value of register
		dx	-> register write mode	(FMRegisterWriteMode)

		ds	-> dgroup of driver

RETURN:		nothing
DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:
		First, determine if register is changing, if so,
		Select register, pause 3.3usec, write to register,
		pause 23 usec, if not, leave.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		delays are longer than needed, but never shorter (hopefully).
		As it does not preform a write if the RegisterMap says the
		value in the register is that same, we must make sure they
		never, NEVER, get out of wack.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDWriteFMRegFar	proc	far
	call	SBDWriteFMReg
	ret
SBDWriteFMRegFar	endp

SBDWriteFMReg	proc	near
	uses	ax
	.enter
EC<	mov	bx, ds			; double check ds is dgroup	>
EC<	cmp	bx, segment dgroup					>
EC<	ERROR_NE -1							>

	clr	bx				; bx <- 0
	mov	bl, al				; bx <- al

	cmp	byte ptr ds:ourValidFMRegisterMap[bx], 0
	jne	done				; do not write to invalid reg.

EC	<cmp	al, FMRM_waveform.CHANNEL_9_CAR ; look for register to large >
EC	<ERROR_A 	ILLEGAL_FM_REGISTER	; error if past 18th waveform>
EC	<cmp	byte ptr ds:ourValidFMRegisterMap[bx],0			     >
EC	<ERROR_NE	ILLEGAL_FM_REGISTER	; how did we get here?	     >

	add	bx, offset ourFMRegisterMap	; bx <- register to change

	cmp	dx, FMRWM_ALWAYS		; do we care if we change?
	je	writeRegister

	cmp	ah, ds:[bx]			; are we changing values?
	je	done				; hopefully not...

writeRegister:
	; must store new value we will write to register
	mov	ds:[bx], ah			; update register

	mov	bx, ax				; bx <- reg/data to set
	;
	;  Select register to write to by sending register index
	;  thru the FM select port.
	;  Then delay for 3.3 usec
	mov	dx, ds:[basePortAddress]
	add	dx, fmSelect			; dx <- select port
	out	dx, al				; select the correct register
	mov	dx, TICKS_TO_DELAY_AFTER_SELECT
	call	MicroDelay			; pause atleast 3.3 usec

	;
	;  Now that the port has been selected, write the new
	;  value into the register by sending it through the FM Data port.
	;  Then wait for 23usec.

	mov	al, bh				; al <- data to write
	mov	dx, ds:[basePortAddress]
	add	dx, offset fmData
	out	dx, al				; write new value for register

	mov	dx, TICKS_TO_DELAY_AFTER_WRITE
	call	MicroDelay			; pause at least 23 usec
done:
	.leave
	ret
SBDWriteFMReg	endp

ResidentCode	ends



