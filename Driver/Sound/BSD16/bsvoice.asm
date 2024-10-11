COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Template

DATEI:		bsvoice.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init
	RainerB	09/15/2024	InstrumentTable updated

ROUTINEN:
	Name			Description
	----			-----------


Beschreibung:
	Template zum Erstellen von Soundtreibern.

*****************************************************************@

idata	segment

	;  As channels and voices numbers are stored in registers, it
	;  becomes necessary to have a table of offsets into the FM
	;  chip register map that allows a simple table look up to
	;  determine which register to write to.
	modOpCellTable	byte	CHANNEL_1_MOD, CHANNEL_2_MOD, CHANNEL_3_MOD,
				CHANNEL_4_MOD, CHANNEL_5_MOD, CHANNEL_6_MOD,
				CHANNEL_7_MOD, CHANNEL_8_MOD, CHANNEL_9_MOD

idata	ends

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDVoiceOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start playing a specific note

CALLED: 	Strategy Routine

PASS:		ax	-> frequency of tone (in Hz)
		bx	-> volume of note    (0000h-ffffh)
		cx	-> voice for note    (0-8)

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The only tricky thing here is how to figure out what
		the f-number and block # for a given frequency should
		be.

		It works out like this:

		        frequency = 50000 * F-NUMBER * 2**(BLOCK-20)
		2**20 * frequency = 50000 * F-NUMBER * 2**BLOCK
		2**20 * frequency = (2**4 * 3125) * F-NUMBER * 2**BLOCK
		2**16 * frequency = 3125 * F-NUMBER * 2**BLOCK
		2**16 * frequency = F-NUMBER * 2**BLOCK
		-----------------
		      3125

		However, doing a dword divide by 3125 puts a maximum
		frequency limit of 3125Hz (or we get a divide by zero).
		As it turns out, the maximum frequency of the soundblaster
		itself is 6243 Hz.  So, we simply change the formula to:

		frequency * 2**16 = F-NUMBER * 2**BLOCK-1
		-----------------
		      6250


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/14/92		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDVoiceOn	proc	near
	uses	ax, bx, cx, dx, si
	.enter
EC<	pushf						>
EC<	pop	dx					>
EC<	test	dx, mask CPU_INTERRUPT			>
EC<	ERROR_NZ -1					>
	;
	;  Make sure the voice value is legal
	cmp	cl, 8				; check for legal voice
	ja	cleanUpStack

	push	bx,cx				; save volume and voice

	;
	;  Ignore those notes out of our range
	cmp	ax, 20				; 20Hz (lower limit for human)
	jbe	cleanUpStack

	cmp	ax, 6243			; 6243Hz (upper limit of board)
	jae	done

		;
		;  We must set the volume (attack) and frequency (note).
		;  It is the carrier wave total level that determines the
		;  volume of the sound.  The modulator amplitude deterimes
		;  the amount of warble.
	mov	bx, cx				; bx <- voice to play note on
	mov	bl, ds:modOpCellTable[bx]	; bx <- offset to mod opCell
	add	bx, DISP_FROM_MOD_TO_CAR	; bx <- offset to car opCell
	mov	si, bx				; si <- offset to car opCell

	;
	;  Calculate the F-NUMBER and Block for the given frequency
	;
	clr	dx				; dx <- 0
	xchg	ax, dx				; dxax <- ax * 2**16
	mov	bx, 6250			; bx <- a secret, magic number
	div	bx				; ax <- F-NUMBER * 2**BLOCK-1
		;
		;  We now check each bit from high to low, couting
		;  the number of free bits we have.  We start on block seven,
		;  and decrement the block until we reach zero, or a non-zero
		;  bit value.
	mov	bx, 8000h			; bx <- 1000 0000 0000 0000b
	mov	cx, 7				; cx <- block value 7
checkForOne:
	test	ax, bx				; is bit set
	jnz	gotIt
	shr	bx, 1				; shift mask one bit to left
	loop	checkForOne
gotIt:
		;
		;  cx now holds the block value for the note and
		;  ax holds the F-number * 2**BLOCK-1
	mov	ch, cl				; ch <- BLOCK
	dec	cl				; cl <- BLOCK-1
	shr	ax, cl				; ax <- F-NUMBER
		;
		;  cx has the BLOCK value for the note
		;  al has F-NUMBER (low) and ah has F-NUMBER (high)
	shl	ch, 1				; ch <- BLOCK * 2
	shl	ch, 1				; ch <- BLOCK * 4
	add	ah, ch				; ah <- BLOCK + F-NUMBER (high)
		;
		;  Save the Block & F-Number on the stack
	pop	bx, cx				; restore volume and voice
	push	ax				; save	frequency
	;
	;  the total level for the output
	;
		;  si now contains the offset for the carrier opCell for
		;  this voice.  With this, we can mask out the total level
		;  stored in our register map and determine the correct KSL.
		;  Because the sound blaster uses 6 bit volumes, al, the
		;  lsb of the volume, is ignored, and is thus free to use.

	mov	al, byte ptr ds:ourFMRegisterMap.FMRM_totalLevel[si]
	and	al, mask OR_KSL			; al <- mask for KSL

		;  We must now set the total level for the carrier
		;  cell.  This will set the sound level for the note.
		;  HOWEVER:  The sound blaster does not allow you
		;  to set the volume level (greater being more), but
		;  the attenuation level (greater being less).  Thus,
		;  we must invert the value and shift right one
	mov	ah, 255				; ah <- 0ffh
	sub	ah, bh				; ah <- setting
	shr	ah, 1				; clear upper two bits
	shr	ah, 1				; 	of ah.
	add	ah, al				; ah <- KSL + Total Level

	;
	;  Write new value to registers
	;

	mov	bx, si				; bx <- register to change
	mov	al, bl				; al <- voices' register
	add	al, offset FMRM_totalLevel	; al <- address of car. vol.
	mov	dx, FMRWM_ONLY_ON_CHANGE	; really change the property
	call	SBDWriteFMReg			; write carrier amplitude

	pop	si				; si <- F-number settings
	mov	bx, si				; bx <- F-number settings
	mov	al, FMRM_freq			; al <- base address of freq.
	add	al, cl				; al <- address for voice freq.
	mov	ah, bl				; ah <- F-number (low)
	mov	dx, FMRWM_ONLY_ON_CHANGE	; really change the property
	call	SBDWriteFMReg			; write F-number (low)

	mov	bx, si				; bx <- F-number settings
	add	al, DISP_FROM_FREQ_TO_BLOCK	; al <- address of voice block
	mov	ah, bh				; ah <- block + F(high)
	or	ah, mask FNHR_KEY_ON		; ah <- block + F(high) + KeyOn
	mov	dx, FMRWM_ONLY_ON_CHANGE	; really change the property
	call	SBDWriteFMReg			; write F-number (high)
done:
	.leave
	ret

cleanUpStack:
	pop	bx, cx				; restore pushed variables
	jmp	short done
SBDVoiceOn	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDChangeEnvelope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the settings for a given voice to match the SBD data

CALLED BY:	SBD
PASS:		bx:si	-> Envelope info to assign to voice
		cx	-> voice to initialize

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Look up each register value in the SBI data and set the
		corropsonding register to that value.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	.assert size SBIEnvelopeFormat	eq	11
changeError	label	near
	stc
	LONG	jmp	changeDone

SBDChangeEnvelope	proc	near
	uses	ax, bx, dx, es, di, si
	.enter
EC<	pushf						>
EC<	pop	dx					>
EC<	test	dx, mask CPU_INTERRUPT			>
EC<	ERROR_NZ -1					>

	;
	;  Look for legal voice
	cmp	cx, 8				; only voices 0-8 are legal
	ja	changeError			; if cx > 8, there is an error

	tst	bx
	jnz	setVoiceEnvelope

	;
	;  We are dealing with a standard patch.
	;  We need to set up a pointer that address the
	;	propper instrument in our table
EC<	cmp	si, length InstrumentTable			>
EC<	ERROR_A	BAD_VOICE_PATCH					>

	mov	ax, si				; ax <- si * 1
	shl	si				; si <- si * 2
	add	ax, si				; ax <- si * 3
	shl	si				; si <- si * 4
	shl	si				; si <- si * 8
	add	si, ax				; si <- si * 11

	add	si, offset InstrumentTable	; si <- offset to our patch
	mov	bx, cs				; bx:si <- SBI patch info

setVoiceEnvelope:
	;
	;  Shuffle around the segment:offset pair so we can
	;  use it and it is as quick as possible (no ea calc)
	mov	es, bx				; es:di <- Envelope info
	mov	di, si

	;
	;  Set overall voice specific parameters
	mov	al, FMRM_feedback		; al <- base address for prop.
	add	al, cl				; al <- voice address for prop.
	mov	ah, es:[di].SBIEF_feedback	; ah <- feedback parameter
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	;
	;  Set OpCell specific parameters for modulator and carrier cells
	mov	si, cx				; cx <- our voice #

	mov	al, FMRM_timbre			; al <- base address of timbre
	add	al, ds:modOpCellTable[si]	; al <- timbre address of mod.
	mov	ah, es:[di].SBIEF_modTimbre	; value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_TIMBRE_TO_LEVEL	; al <- volume address of mod.
	mov	ah, es:[di].SBIEF_modScaling	; value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_LEVEL_TO_ATTACK	; al <- attack address of mod.
	mov	ah, es:[di].SBIEF_modAttack	; value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_ATTACK_TO_SUSTAIN ; al <- attack address of mod.
	mov	ah, es:[di].SBIEF_modSustain	; value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_SUSTAIN_TO_WAVE	; al <- attack address of mod.
	mov	ah, es:[di].SBIEF_modWave	; value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	;  Set OpCell specific parameters
						; al <- timbre for car.
	sub	al, DISP_FROM_MOD_WAVE_TO_CAR_TIMBRE
	mov	ah, es:[di].SBIEF_carTimbre	; value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_TIMBRE_TO_LEVEL	; al <- volume address of car.
	mov	ah, es:[di].SBIEF_carScaling	; ah <- value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_LEVEL_TO_ATTACK	; al <- attack address of car.
	mov	ah, es:[di].SBIEF_carAttack	; ah <- value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_ATTACK_TO_SUSTAIN ; al <- attack address of car.
	mov	ah, es:[di].SBIEF_carSustain	; ah <- value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg

	add	al, DISP_FROM_SUSTAIN_TO_WAVE	; al <- attack address of car.
	mov	ah, es:[di].SBIEF_carWave	; ah <- value for this stream
	mov	dx, FMRWM_ONLY_ON_CHANGE	; change only if needed
	call	SBDWriteFMReg
	
	clc					; everything went well
changeDone 	label near
	.leave
	ret
SBDChangeEnvelope	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDVoiceOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn a voice off

CALLED BY:	global

PASS:		cx	-> voice to turn off

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		nothing
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBDVoiceOff	proc	near
	uses	ax, bx, dx, si
	.enter
EC<	pushf						>
EC<	pop	dx					>
EC<	test	dx, mask CPU_INTERRUPT			>
EC<	ERROR_NZ -1					>
	;
	;  Check for a legal voice
	cmp	cx, NUM_OF_VOICES-1		; voices go from 0 to 8
	ja	done

	;
	;  To turn a note off, all we must do is flip the key-on bit on
	;  the voice's block register.  To do so, we set ds:si to the
	;  block register, load its old value, clear the bit, and then
	;  write the new value
	mov	si, offset FMRM_block
	add	si, cx				; si <- voice's block # offset

						; ah <- current block # value
	mov	ah, byte ptr ds:ourFMRegisterMap[si]
	and	ah, not mask FNHR_KEY_ON	; ah <- note off
	clr	al				; al <- 0
	add	ax, si				; al <- base block addr
	mov	dx, FMRWM_ALWAYS		; always turn off
	call	SBDWriteFMReg			; turn note off
done:
	.leave
	ret
SBDVoiceOff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDVoiceSilence
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the voice, NOW!

CALLED BY:	Strategy Routine
PASS:		cx	-> voice to turn off

		ds	-> dgroup of driver
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		turns off a voice immediately, even if it means
		crunching the envelope

PSEUDO CODE/STRATEGY:
		turn off the voice (KEY_OFF)
		set total volume to zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDVoiceSilence	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
EC<	pushf								>
EC<	pop	dx							>
EC<	test	dx, mask CPU_INTERRUPT					>
EC<	ERROR_NZ -1							>
	;
	;  Check for a legal voice
	cmp	cx, NUM_OF_VOICES-1		; voices go from 0 to 8
	ja	done

	;
	;  To silence a voice, we must flip the key-on bit for the
	;  voice's block register and we must also set the attenuation
	;  level to maximum.
	mov	si, offset FMRM_block
	add	si, cx				; si <- voice's block # offset

						; ah <- current block # value
	mov	ah, byte ptr ds:ourFMRegisterMap[si]
	and	ah, not mask FNHR_KEY_ON	; ah <- note off
	clr	al				; al <- 0
	add	ax, si				; al <- base block addr
	mov	dx, FMRWM_ALWAYS		; always turn off
	call	SBDWriteFMReg			; turn note off

	mov	si, cx				; si <- voice #
						; al <- address of total level
	mov	al, (DISP_FROM_MOD_TO_CAR + offset FMRM_totalLevel)
	add	al, ds:modOpCellTable[si]	; al <- totalLevel for voice
	mov	ah, 0ffh			; ah <- maximum attenuation
	mov	dx, FMRWM_ALWAYS		; always silence carOpCell
	call	SBDWriteFMReg			; turn note off	
done:
	.leave
	ret
SBDVoiceSilence	endp

;-----------------------------------------------------------------------------
;
;  	Voice Patch Info
;
;-----------------------------------------------------------------------------

	;
	;  Go ahead.  I dare you to debug this table!
	;			-- todd  :)
	;  Reworked by RainerB in 2024.
	;  It sounds very much better now, but it's still just FM sounds.
	;
InstrumentTable SBIEnvelopeFormat  <001H,011H,04FH,000H,0F1H,0D2H,051H,043H,
				   000H,000H,006H>,
				  <031H,021H,04BH,000H,0F2H,0F2H,054H,056H,
				   000H,000H,008H>,
				  <013H,011H,0C6H,000H,0F2H,0F1H,0F5H,0F5H,
				   001H,000H,000H>,
				  <031H,031H,08EH,080H,0F1H,0F3H,0F9H,0F9H,
				   000H,000H,00AH>,
				  <001H,011H,066H,000H,0F1H,0D2H,051H,0C3H,
				   000H,000H,006H>,
				  <002H,002H,022H,000H,0F2H,0F5H,013H,043H,
				   000H,000H,00EH>,
				  <021H,036H,080H,00EH,0A2H,0F1H,001H,0D5H,
				   000H,000H,008H>,
				  <001H,001H,092H,000H,0C2H,0C2H,0A8H,058H,
				   000H,000H,00AH>,
				 
				  <00CH,081H,05CH,000H,0F6H,0F3H,054H,0B5H,
				   000H,000H,000H>,
				  <017H,012H,05EH,008H,0F2H,0F2H,061H,074H,
				   000H,000H,008H>,
				  <017H,001H,021H,000H,056H,0F6H,004H,004H,
				   000H,000H,002H>,
				  <093H,091H,097H,000H,0AAH,0ACH,012H,021H,
				   002H,000H,00EH>,
				  <095H,081H,04EH,000H,0DAH,0F9H,025H,015H,
				   000H,000H,00AH>,
				  <027H,021H,01FH,003H,0F5H,0F5H,096H,057H,
				   000H,000H,008H>,
				  <045H,081H,059H,080H,0D3H,0A3H,082H,0E3H,
				   000H,000H,00CH>,
				  <003H,081H,049H,080H,074H,0B3H,055H,005H,
				   001H,000H,004H>,
				 
				  <064H,021H,086H,080H,0FFH,0FFH,00FH,00FH,
				   000H,000H,001H>,
				  <072H,030H,014H,000H,0C7H,0C7H,058H,008H,
				   000H,000H,002H>,
				  <070H,0B1H,044H,000H,0AAH,08AH,018H,008H,
				   000H,000H,004H>,
				  <0D2H,0F1H,044H,080H,091H,0A1H,057H,009H,
				   001H,001H,003H>,
				  <061H,0B1H,013H,080H,097H,055H,004H,004H,
				   001H,000H,000H>,
				  <024H,031H,04FH,000H,0F2H,052H,00BH,00BH,
				   000H,000H,00EH>,
				  <061H,021H,013H,000H,091H,061H,006H,007H,
				   001H,000H,00AH>,
				  <020H,031H,05DH,007H,0F2H,052H,00BH,00BH,
				   003H,002H,000H>,
				 
				  <002H,041H,09CH,080H,0F3H,0F3H,094H,0C8H,
				   001H,000H,00CH>,
				  <003H,011H,05EH,000H,0F5H,0F2H,071H,083H,
				   001H,000H,00EH>,
				  <011H,011H,08DH,080H,0FFH,0FFH,001H,003H,
				   000H,000H,000H>,
				  <021H,006H,040H,080H,0F1H,0F4H,031H,044H,
				   000H,000H,000H>,
				  <001H,001H,01DH,000H,0F2H,0F5H,0EFH,078H,
				   000H,000H,00AH>,
				  <021H,021H,00FH,003H,0F5H,0F1H,017H,078H,
				   002H,001H,004H>,
				  <023H,021H,04AH,000H,095H,094H,019H,019H,
				   001H,000H,008H>,
				  <001H,001H,011H,000H,0F2H,0F4H,013H,0F8H,
				   000H,000H,00AH>,
				 
				  <001H,000H,000H,000H,094H,083H,0B6H,026H,
				   000H,000H,001H>,
				  <000H,001H,023H,000H,0C1H,0F3H,0EEH,0DEH,
				   000H,000H,00AH>,
				  <050H,000H,000H,000H,0FBH,0F3H,071H,0B9H,
				   000H,000H,000H>,
				  <030H,021H,01EH,000H,0F2H,0F5H,0EFH,078H,
				   000H,000H,00EH>,
				  <000H,010H,040H,000H,095H,0FFH,088H,003H,
				   001H,000H,006H>,
				  <030H,022H,00CH,000H,062H,0D5H,0B5H,098H,
				   001H,000H,008H>,
				  <031H,031H,08BH,000H,0F4H,0F1H,0E8H,078H,
				   000H,000H,00AH>,
				  <000H,010H,04FH,000H,0D5H,083H,021H,001H,
				   000H,000H,00AH>,
				 
				  <021H,021H,013H,000H,091H,061H,007H,008H,
				   001H,000H,00AH>,
				  <031H,021H,016H,000H,0DDH,066H,013H,006H,
				   001H,000H,008H>,
				  <0B0H,0B1H,0C5H,080H,052H,031H,011H,0FEH,
				   001H,001H,000H>,
				  <0F0H,020H,08AH,080H,0B1H,0A0H,011H,015H,
				   002H,001H,006H>,
				  <0F1H,0E1H,040H,000H,0F1H,06FH,021H,016H,
				   001H,000H,002H>,
				  <001H,011H,04FH,000H,0F2H,0F5H,053H,074H,
				   000H,000H,006H>,
				  <032H,001H,024H,082H,0F1H,0F5H,034H,034H,
				   000H,000H,000H>,
				  <010H,011H,041H,000H,0F5H,0F2H,005H,0C3H,
				   001H,000H,002H>,
				 
				  <0E0H,0F1H,04FH,003H,0D4H,055H,00BH,00BH,
				   002H,002H,00AH>,
				  <0B1H,061H,08BH,040H,071H,042H,011H,015H,
				   000H,001H,006H>,
				  <0A1H,061H,093H,000H,0C1H,04FH,012H,005H,
				   000H,000H,00AH>,
				  <021H,061H,018H,000H,0C1H,04FH,022H,005H,
				   000H,000H,00CH>,
				  <031H,072H,05BH,083H,0F4H,08AH,015H,005H,
				   000H,000H,000H>,
				  <0A1H,061H,090H,000H,074H,071H,039H,067H,
				   000H,000H,000H>,
				  <071H,072H,057H,000H,054H,07AH,005H,005H,
				   000H,000H,00CH>,
				  <000H,000H,00FH,000H,091H,052H,005H,006H,
				   000H,002H,000H>,
				 
				  <021H,021H,092H,001H,085H,08FH,017H,009H,
				   000H,000H,00CH>,
				  <0B1H,061H,01CH,080H,041H,092H,01FH,03BH,
				   000H,000H,00EH>,
				  <021H,021H,018H,001H,053H,052H,01FH,03FH,
				   000H,000H,00CH>,
				  <031H,021H,043H,000H,09EH,062H,017H,02CH,
				   001H,001H,002H>,
				  <021H,021H,09BH,000H,061H,07FH,06AH,00AH,
				   000H,000H,002H>,
				  <061H,022H,08AH,006H,075H,074H,01FH,00FH,
				   000H,000H,008H>,
				  <021H,021H,01DH,001H,051H,0E1H,0AEH,03EH,
				   002H,001H,00EH>,
				  <021H,021H,04DH,000H,054H,0A6H,03CH,01CH,
				   000H,000H,008H>,
				 
				  <0E0H,0F2H,04BH,00BH,0D8H,0B3H,00BH,00BH,
				   002H,001H,008H>,
				  <031H,061H,08EH,000H,093H,072H,003H,009H,
				   001H,000H,008H>,
				  <031H,061H,091H,000H,093H,082H,003H,009H,
				   001H,000H,00AH>,
				  <0E0H,0F1H,04CH,00BH,088H,0D3H,00BH,00BH,
				   001H,001H,008H>,
				  <021H,021H,04BH,000H,0AAH,08FH,016H,00AH,
				   001H,000H,008H>,
				  <031H,021H,090H,000H,07EH,08BH,017H,00CH,
				   001H,001H,006H>,
				  <030H,071H,0C8H,080H,0D5H,061H,019H,01BH,
				   000H,000H,00CH>,
				  <032H,021H,090H,000H,09BH,072H,021H,017H,
				   000H,000H,004H>,
				 
				  <021H,0A2H,083H,08DH,074H,065H,017H,017H,
				   000H,000H,007H>,
				  <020H,022H,05BH,080H,000H,050H,016H,015H,
				   000H,000H,00AH>,
				  <0E0H,061H,0ECH,000H,06EH,065H,08FH,02AH,
				   000H,000H,00EH>,
				  <020H,021H,01BH,000H,000H,050H,016H,015H,
				   000H,000H,00AH>,
				  <062H,0A1H,0CBH,000H,076H,055H,046H,036H,
				   000H,000H,000H>,
				  <0F1H,0E1H,028H,000H,057H,067H,034H,05DH,
				   003H,000H,00EH>,
				  <062H,0A1H,093H,000H,077H,076H,007H,007H,
				   000H,000H,00BH>,
				  <0E0H,061H,0ECH,000H,06EH,065H,08FH,02AH,
				   000H,000H,00EH>,
				 
				  <023H,031H,04FH,006H,051H,060H,05BH,025H,
				   001H,001H,000H>,
				  <021H,021H,00EH,000H,0FFH,0FFH,00FH,00FH,
				   001H,001H,000H>,
				  <0F1H,0E1H,028H,004H,057H,067H,034H,00DH,
				   003H,000H,00EH>,
				  <060H,060H,003H,000H,0F6H,076H,04FH,00FH,
				   000H,000H,002H>,
				  <0E2H,031H,042H,012H,078H,0F3H,00BH,00BH,
				   001H,001H,008H>,
				  <0A2H,061H,09EH,040H,0DFH,06FH,005H,007H,
				   000H,000H,002H>,
				  <020H,060H,01AH,000H,0EFH,08FH,001H,006H,
				   000H,002H,000H>,
				  <021H,021H,08FH,080H,0F1H,0F4H,029H,009H,
				   000H,000H,00AH>,
				 
				  <031H,0A1H,01CH,080H,041H,092H,00BH,03BH,
				   000H,000H,00CH>,
				  <061H,0B1H,01FH,080H,0A8H,025H,011H,003H,
				   000H,000H,00AH>,
				  <061H,061H,017H,000H,091H,055H,034H,016H,
				   000H,000H,00CH>,
				  <071H,072H,05DH,000H,054H,06AH,001H,003H,
				   000H,000H,000H>,
				  <021H,0A2H,097H,000H,021H,042H,043H,035H,
				   000H,000H,008H>,
				  <005H,046H,040H,080H,0B3H,0F2H,0D3H,024H,
				   000H,000H,002H>,
				  <000H,011H,00DH,080H,0F1H,050H,0FFH,0FFH,
				   000H,000H,006H>,
				  <0F0H,0F1H,046H,080H,022H,031H,011H,02EH,
				   001H,000H,00CH>,
				 
				  <011H,001H,08AH,04BH,0F1H,0F1H,011H,0B3H,
				   000H,000H,006H>,
				  <0F1H,0F1H,041H,041H,011H,011H,011H,011H,
				   000H,000H,002H>,
				  <027H,032H,0C0H,007H,032H,0A4H,062H,033H,
				   000H,000H,000H>,
				  <074H,035H,018H,080H,058H,026H,000H,001H,
				   000H,000H,006H>,
				  <041H,042H,04DH,000H,0F1H,0F2H,051H,0F5H,
				   001H,000H,000H>,
				  <0E0H,0F1H,01AH,082H,013H,033H,052H,013H,
				   001H,002H,000H>,
				  <0E0H,0F1H,01AH,004H,045H,032H,0BAH,091H,
				   000H,002H,000H>,
				  <07EH,031H,000H,000H,0F1H,0F1H,001H,004H,
				   000H,000H,004H>,
				 
				  <010H,018H,080H,045H,0F1H,0F1H,053H,053H,
				   000H,000H,000H>,
				  <011H,013H,00CH,080H,0A3H,0A2H,011H,0E5H,
				   001H,000H,000H>,
				  <031H,034H,021H,002H,0F5H,093H,056H,0E8H,
				   001H,000H,008H>,
				  <001H,008H,011H,000H,0F2H,0F5H,01FH,088H,
				   000H,000H,008H>,
				  <004H,001H,04FH,000H,0FAH,0C2H,056H,005H,
				   000H,000H,00CH>,
				  <021H,022H,049H,000H,07CH,06FH,020H,00CH,
				   000H,001H,006H>,
				  <031H,022H,01CH,089H,061H,052H,003H,067H,
				   000H,000H,00EH>,
				  <020H,021H,004H,081H,0DAH,08FH,005H,00BH,
				   002H,000H,006H>,
				 
				  <007H,008H,048H,080H,0F1H,0FCH,072H,004H,
				   000H,000H,000H>,
				  <007H,002H,015H,000H,0ECH,0F8H,026H,016H,
				   000H,000H,00AH>,
				  <005H,001H,09DH,000H,067H,0DFH,035H,005H,
				   000H,000H,008H>,
				  <002H,002H,000H,000H,0C8H,0C8H,097H,097H,
				   000H,000H,001H>,
				  <000H,000H,00DH,000H,0E8H,0A5H,0EFH,0FFH,
				   000H,000H,006H>,
				  <011H,010H,041H,003H,0F8H,0F3H,047H,003H,
				   002H,000H,004H>,
				  <000H,000H,00BH,000H,0A9H,0D6H,044H,044H,
				   000H,000H,000H>,
				  <00EH,0C0H,000H,000H,01FH,01FH,000H,0FFH,
				   000H,003H,00EH>,
				 
				  <012H,011H,000H,000H,0A5H,07BH,007H,006H,
				   000H,002H,008H>,
				  <00EH,0D0H,000H,005H,0F8H,034H,000H,004H,
				   000H,003H,00EH>,
				  <002H,008H,000H,002H,03EH,014H,001H,0F3H,
				   002H,002H,00EH>,
				  <0D5H,0DAH,095H,040H,037H,056H,0A3H,037H,
				   000H,000H,000H>,
				  <0B0H,0B5H,035H,08EH,0FBH,0A0H,0F0H,09BH,
				   000H,000H,00EH>,
				  <0B0H,0A0H,000H,0C0H,0FEH,0F1H,011H,019H,
				   001H,000H,008H>,
				  <0E7H,0E8H,000H,00EH,034H,010H,000H,0B2H,
				   002H,002H,00EH>,
				  <006H,000H,000H,00BH,0F4H,0F6H,0A0H,046H,
				   000H,000H,00EH>,
				 
				  <000H,000H,00BH,000H,0A8H,0D6H,04CH,045H,
				   000H,000H,000H>,
				  <000H,000H,00BH,000H,0AAH,0D2H,0C8H,0B7H,
				   000H,000H,000H>,
				  <026H,000H,000H,000H,0F0H,0FAH,0F0H,0B7H,
				   003H,003H,00EH>,
				  <000H,000H,000H,000H,0FCH,0FAH,005H,017H,
				   002H,000H,00EH>,
				  <042H,001H,000H,000H,074H,08FH,038H,037H,
				   000H,000H,00CH>,
				  <006H,000H,000H,000H,0F0H,0F6H,0F1H,0B6H,
				   000H,000H,00EH>,
				  <000H,000H,00DH,000H,0E8H,0A5H,0EFH,0FFH,
				   000H,000H,006H>,
				  <064H,003H,000H,093H,0B2H,098H,082H,0DAH,
				   002H,001H,00EH>,
				 
				  <012H,011H,090H,080H,0F0H,0F0H,007H,005H,
				   000H,000H,000H>,
				  <00CH,012H,000H,000H,0F6H,0FBH,008H,047H,
				   000H,002H,00AH>,
				  <011H,031H,02DH,000H,0C8H,0F5H,02FH,0F5H,
				   000H,000H,00CH>,
				  <064H,003H,000H,080H,0B2H,097H,082H,0D4H,
				   002H,001H,00EH>,
				  <000H,000H,00DH,00BH,0E8H,0A5H,0EFH,0FFH,
				   000H,000H,006H>,
				  <001H,020H,000H,000H,0C7H,0EAH,0D8H,0E9H,
				   000H,000H,001H>,
				  <064H,003H,002H,000H,0B2H,096H,0A1H,0D4H,
				   000H,001H,00EH>,
				  <004H,0C2H,000H,000H,0FEH,0F6H,0F0H,0B5H,
				   000H,000H,00EH>,
				 
				  <064H,003H,000H,080H,0B2H,097H,082H,0D4H,
				   002H,001H,00EH>,
				  <024H,005H,000H,080H,0B5H,0D5H,034H,085H,
				   000H,001H,00EH>,
				  <007H,012H,04FH,000H,0FFH,0F2H,060H,072H,
				   000H,000H,008H>,
				  <05FH,041H,006H,000H,077H,088H,07DH,0FDH,
				   003H,002H,004H>,
				  <002H,005H,003H,04AH,0B4H,097H,004H,0F7H,
				   000H,000H,00EH>,
				  <016H,014H,028H,000H,080H,0F0H,005H,005H,
				   000H,000H,000H>,
				  <006H,000H,000H,040H,0F0H,0F6H,0F1H,0B4H,
				   000H,000H,00EH>,
				  <044H,060H,053H,080H,0F5H,0FDH,033H,025H,
				   000H,002H,006H>,
				 
				  <02EH,002H,00AH,05BH,0FFH,0F6H,004H,046H,
				   000H,000H,00EH>,
				  <013H,014H,007H,080H,0FDH,090H,039H,007H,
				   000H,000H,00EH>,
				  <012H,011H,04EH,000H,0F7H,0F0H,045H,006H,
				   000H,000H,000H>,
				  <001H,002H,059H,000H,0FAH,0F8H,088H,0B6H,
				   000H,000H,006H>,
				  <001H,000H,000H,040H,0F9H,0FAH,00AH,006H,
				   003H,000H,00EH>,
				  <011H,031H,02DH,000H,0C8H,0F5H,02FH,0F5H,
				   000H,000H,00CH>,
				  <0C3H,082H,05CH,000H,0F3H,0F4H,029H,006H,
				   001H,003H,008H>,
				  <032H,011H,044H,000H,0F8H,0F5H,0FFH,07FH,
				   000H,000H,00EH>,
				 
				  <013H,011H,091H,080H,0FFH,0FFH,021H,003H,
				   000H,000H,00AH>,
				  <008H,002H,04DH,000H,0FFH,0FFH,006H,006H,
				   000H,000H,00CH>,
				  <02EH,000H,040H,058H,0FFH,0F6H,00FH,01FH,
				   000H,000H,00EH>,
				  <02EH,000H,040H,018H,0FFH,086H,02FH,00FH,
				   000H,000H,00EH>,
				  <0C4H,0C3H,00AH,000H,055H,065H,03AH,04AH,
				   001H,000H,009H>,
				  <004H,043H,00AH,000H,0B0H,060H,0F9H,0A7H,
				   000H,000H,00DH>,
				  <010H,0DBH,00EH,080H,054H,064H,04AH,04AH,
				   001H,000H,00AH>,
				  <030H,0BFH,00EH,0C1H,052H,052H,01BH,09FH,
				   001H,000H,00AH>, 
				 
				  <006H,015H,03FH,000H,000H,0F7H,0F4H,0F5H,
				   000H,000H,001H>,
				  <002H,006H,000H,002H,0E8H,097H,0FAH,0FAH,
				   000H,000H,007H>,
				  <006H,012H,03FH,000H,000H,0F7H,0F4H,0F5H,
				   003H,000H,000H>,
				  <014H,009H,000H,000H,066H,076H,0FFH,0FFH,
				   000H,000H,004H>,
				  <016H,004H,000H,000H,066H,076H,0FFH,0FFH,
				   000H,000H,004H>,
				  <0C5H,0D5H,04FH,000H,0F2H,0F4H,061H,07AH,
				   000H,000H,008H>,
				  <0C5H,0D5H,04FH,000H,0F2H,0F2H,061H,072H,
				   000H,000H,008H>

ResidentCode	ends

