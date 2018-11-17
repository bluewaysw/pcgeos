COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Template

DATEI:		bsvoice.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init

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
InstrumentTable	SBIEnvelopeFormat <001H,011H,04FH,000H,0F1H,0D2H,051H,043H,
				   000H,000H,006H>,
				  <002H,012H,04FH,006H,0F1H,0D2H,051H,043H,
				   000H,000H,002H>,
				  <000H,011H,04AH,004H,0F1H,0D2H,053H,074H,
				   000H,000H,006H>,
				  <003H,011H,04FH,004H,0F1H,0D2H,053H,074H,
				   001H,001H,006H>,
				  <001H,011H,066H,000H,0F1H,0D2H,051H,0C3H,
				   000H,000H,006H>,
				  <0C0H,0D2H,052H,005H,0F1H,0D2H,053H,094H,
				   000H,000H,006H>,
				  <012H,018H,086H,000H,0F3H,0FCH,000H,033H,
				   000H,000H,008H>,
				  <0D0H,012H,04EH,003H,0A8H,092H,032H,0A7H,
				   003H,002H,000H>,
				  <0C8H,0D1H,04FH,008H,0F2H,0F3H,064H,077H,
				   000H,000H,008H>,
				  <033H,034H,00EH,000H,001H,07DH,011H,034H,
				   000H,000H,008H>,
				  <017H,016H,050H,000H,0D1H,0D3H,052H,092H,
				   000H,001H,004H>,
				  <0E7H,0E1H,021H,006H,0F5H,0F6H,077H,014H,
				   000H,000H,008H>,
				  <095H,081H,04EH,000H,0DAH,0F9H,025H,015H,
				   000H,000H,00AH>,
				  <027H,021H,01FH,003H,0F5H,0F5H,096H,057H,
				   000H,000H,008H>,
				  <087H,0F1H,04EH,080H,0B1H,0E6H,033H,042H,
				   000H,000H,000H>,
				  <031H,011H,087H,080H,0A1H,07DH,011H,043H,
				   000H,000H,008H>,
				  <032H,0B1H,08CH,003H,091H,0A1H,007H,019H,
				   002H,000H,005H>,
				  <031H,0B4H,054H,083H,0F1H,0F5H,007H,019H,
				   000H,000H,007H>,
				  <024H,021H,040H,053H,0FFH,0FFH,00FH,00FH,
				   000H,000H,001H>,
				  <0D2H,0F1H,044H,080H,091H,0A1H,057H,009H,
				   001H,001H,003H>,
				  <001H,002H,052H,088H,0F0H,0F0H,01FH,01FH,
				   001H,000H,00AH>,
				  <021H,032H,04FH,00BH,0F2H,052H,00BH,00BH,
				   000H,001H,00AH>,
				  <0F0H,0F2H,093H,007H,0D8H,0B3H,00BH,00BH,
				   002H,001H,00AH>,
				  <020H,031H,05DH,007H,0F2H,052H,00BH,00BH,
				   003H,002H,000H>,
				  <001H,001H,01BH,004H,0F4H,0F3H,025H,046H,
				   002H,000H,000H>,
				  <011H,001H,00FH,007H,0F4H,0F3H,025H,046H,
				   001H,000H,000H>,
				  <001H,001H,027H,000H,0F1H,0F4H,01FH,088H,
				   002H,000H,00AH>,
				  <012H,013H,044H,003H,0EAH,0D2H,032H,0E7H,
				   001H,001H,000H>,
				  <030H,031H,045H,000H,0A4H,0F5H,032H,0E7H,
				   003H,000H,000H>,
				  <021H,021H,00FH,003H,0F5H,0F1H,017H,078H,
				   002H,001H,004H>,
				  <001H,020H,041H,007H,0D1H,0C1H,034H,0A5H,
				   003H,003H,004H>,
				  <010H,012H,043H,002H,0A7H,0E3H,097H,0E7H,
				   003H,002H,000H>,
				  <020H,021H,028H,001H,0C5H,0D2H,015H,0A4H,
				   000H,000H,00CH>,
				  <030H,021H,016H,005H,0F2H,0F3H,09FH,078H,
				   000H,000H,00CH>,
				  <030H,021H,011H,005H,082H,0F3H,09FH,078H,
				   000H,000H,00AH>,
				  <021H,021H,023H,000H,073H,093H,01AH,087H,
				   000H,000H,00CH>,
				  <030H,021H,00EH,009H,062H,0F3H,055H,068H,
				   002H,000H,00AH>,
				  <030H,022H,00CH,000H,062H,0D5H,0B5H,098H,
				   001H,000H,008H>,
				  <070H,072H,093H,043H,064H,0A1H,043H,043H,
				   000H,000H,00AH>,
				  <030H,032H,08DH,085H,044H,092H,043H,043H,
				   002H,000H,00AH>,
				  <0E1H,0E2H,04EH,000H,065H,061H,043H,044H,
				   002H,002H,000H>,
				  <0A1H,0A2H,08EH,005H,065H,063H,043H,045H,
				   002H,002H,000H>,
				  <0B0H,061H,087H,040H,0D1H,062H,011H,015H,
				   002H,001H,006H>,
				  <0F0H,020H,08AH,080H,0B1H,0A0H,011H,015H,
				   002H,001H,006H>,
				  <0F1H,0E2H,089H,043H,073H,043H,001H,005H,
				   002H,000H,006H>,
				  <031H,021H,057H,080H,0F8H,0F7H,0F9H,0E6H,
				   003H,002H,00EH>,
				  <032H,001H,024H,082H,0F1H,0F5H,035H,035H,
				   000H,000H,000H>,
				  <000H,000H,004H,000H,0AAH,0D2H,0C8H,0B3H,
				   000H,000H,00AH>,
				  <0E0H,0F1H,04FH,003H,0D4H,055H,00BH,00BH,
				   002H,002H,00AH>,
				  <0E0H,0F0H,052H,000H,096H,035H,005H,001H,
				   002H,002H,00AH>,
				  <0E1H,0F1H,04FH,000H,036H,045H,005H,002H,
				   002H,002H,00AH>,
				  <0E2H,0E1H,048H,081H,021H,041H,043H,045H,
				   002H,001H,000H>,
				  <0E0H,0F1H,016H,000H,041H,020H,052H,072H,
				   002H,002H,000H>,
				  <0E0H,0F1H,011H,000H,001H,0D0H,052H,072H,
				   002H,002H,000H>,
				  <0E0H,0F1H,01AH,000H,061H,030H,052H,073H,
				   000H,002H,000H>,
				  <050H,050H,00BH,007H,084H,0A4H,04BH,099H,
				   000H,000H,00AH>,
				  <031H,061H,01CH,084H,041H,092H,00BH,03BH,
				   000H,000H,00EH>,
				  <0B1H,061H,01CH,005H,041H,092H,01FH,03BH,
				   000H,000H,00EH>,
				  <020H,021H,018H,000H,052H,0A2H,015H,024H,
				   000H,000H,00CH>,
				  <0C1H,0C1H,094H,084H,074H,0A3H,0EAH,0F5H,
				   002H,001H,00EH>,
				  <021H,021H,028H,000H,041H,081H,0B4H,098H,
				   000H,000H,00EH>,
				  <021H,021H,01DH,001H,051H,0E1H,0AEH,03EH,
				   002H,001H,00EH>,
				  <0E0H,0E0H,093H,082H,051H,081H,0A6H,097H,
				   002H,001H,00EH>,
				  <0E0H,0E1H,093H,083H,051H,0E1H,0A6H,097H,
				   002H,001H,00EH>,
				  <0E0H,0F2H,04BH,00BH,0D8H,0B3H,00BH,00BH,
				   002H,001H,008H>,
				  <0E0H,0F1H,049H,00BH,0B8H,0B3H,00BH,00BH,
				   002H,001H,008H>,
				  <0E0H,0F0H,04EH,00BH,098H,0C3H,00BH,00BH,
				   001H,002H,008H>,
				  <0E0H,0F1H,04CH,00BH,088H,0D3H,00BH,00BH,
				   001H,001H,008H>,
				  <0F1H,0E4H,0C5H,008H,07EH,08CH,017H,00EH,
				   000H,000H,008H>,
				  <060H,072H,04FH,00AH,0D8H,0B3H,00BH,00BH,
				   000H,001H,00AH>,
				  <031H,072H,0D1H,080H,0D5H,091H,019H,01BH,
				   000H,000H,00CH>,
				  <032H,071H,0C8H,080H,0D5H,073H,019H,01BH,
				   000H,000H,00CH>,
				  <0E2H,062H,06AH,000H,09EH,055H,08FH,02AH,
				   000H,000H,00EH>,
				  <0E0H,061H,0ECH,000H,07EH,065H,08FH,02AH,
				   000H,000H,00EH>,
				  <062H,0A2H,088H,08DH,084H,075H,027H,017H,
				   000H,000H,009H>,
				  <062H,0A2H,084H,08DH,084H,075H,027H,017H,
				   000H,000H,009H>,
				  <0E3H,062H,06DH,000H,057H,057H,004H,077H,
				   000H,000H,00EH>,
				  <0F1H,0E1H,028H,000H,057H,067H,034H,05DH,
				   003H,000H,00EH>,
				  <0D1H,072H,0C7H,003H,031H,042H,00FH,009H,
				   000H,000H,00BH>,
				  <0F2H,072H,0C7H,005H,051H,042H,005H,069H,
				   000H,000H,00BH>,
				  <023H,031H,04FH,006H,051H,060H,05BH,025H,
				   001H,001H,000H>,
				  <022H,031H,048H,006H,031H,0C0H,09BH,065H,
				   002H,001H,000H>,
				  <0F1H,0E1H,028H,004H,057H,067H,034H,00DH,
				   003H,000H,00EH>,
				  <0E1H,0E1H,023H,000H,057H,067H,004H,04DH,
				   003H,000H,00EH>,
				  <0E2H,031H,042H,012H,078H,0F3H,00BH,00BH,
				   001H,001H,008H>,
				  <0E2H,0E2H,021H,007H,011H,040H,052H,073H,
				   001H,001H,008H>,
				  <023H,0A4H,0C0H,000H,051H,035H,007H,079H,
				   001H,002H,00DH>,
				  <024H,0A0H,0C0H,001H,051H,075H,007H,009H,
				   001H,002H,009H>,
				  <0E0H,0F0H,016H,003H,0B1H,0E0H,051H,075H,
				   002H,002H,000H>,
				  <003H,0A4H,0C0H,004H,052H,0F4H,003H,055H,
				   000H,000H,009H>,
				  <0E1H,0E1H,093H,081H,031H,0A1H,0A6H,097H,
				   001H,001H,00AH>,
				  <0F0H,071H,0C4H,087H,010H,011H,001H,0C1H,
				   002H,002H,001H>,
				  <0C1H,0E0H,04FH,000H,0B1H,012H,053H,074H,
				   002H,002H,006H>,
				  <0C0H,041H,06DH,007H,0F9H,0F2H,021H,0B3H,
				   001H,000H,00EH>,
				  <0E3H,0E2H,04CH,007H,021H,0A1H,043H,045H,
				   001H,001H,000H>,
				  <0E3H,0E2H,00CH,009H,011H,080H,052H,073H,
				   001H,001H,008H>,
				  <026H,088H,0C0H,000H,055H,0F8H,047H,019H,
				   000H,000H,00BH>,
				  <023H,0E4H,0D4H,000H,0E5H,035H,003H,065H,
				   000H,000H,007H>,
				  <027H,032H,0C0H,007H,032H,0A4H,062H,033H,
				   000H,000H,000H>,
				  <0D0H,031H,04EH,003H,098H,0A2H,032H,047H,
				   001H,002H,000H>,
				  <0F0H,071H,0C0H,004H,093H,043H,003H,002H,
				   001H,000H,00FH>,
				  <0E0H,0F1H,01AH,082H,013H,033H,052H,013H,
				   001H,002H,000H>,
				  <0E0H,0F1H,01AH,004H,045H,032H,0BAH,091H,
				   000H,002H,000H>,
				  <011H,015H,018H,00DH,058H,0A2H,002H,072H,
				   001H,000H,00AH>,
				  <010H,018H,080H,045H,0F1H,0F1H,053H,053H,
				   000H,000H,000H>,
				  <031H,017H,086H,080H,0A1H,07DH,011H,023H,
				   000H,000H,008H>,
				  <010H,018H,080H,040H,0F1H,0F6H,053H,054H,
				   000H,000H,000H>,
				  <031H,034H,021H,002H,0F5H,093H,056H,0E8H,
				   001H,000H,008H>,
				  <003H,015H,04FH,003H,0F1H,0D6H,039H,074H,
				   003H,000H,006H>,
				  <031H,022H,043H,006H,06EH,08BH,017H,00CH,
				   001H,002H,002H>,
				  <031H,022H,01CH,089H,061H,052H,003H,067H,
				   000H,000H,00EH>,
				  <060H,0F0H,00CH,089H,081H,061H,003H,00CH,
				   000H,001H,008H>,
				  <027H,005H,055H,005H,031H,0A7H,062H,075H,
				   000H,000H,000H>,
				  <095H,016H,081H,000H,0E7H,096H,001H,067H,
				   000H,000H,004H>,
				  <00CH,001H,087H,080H,0F0H,0F2H,005H,005H,
				   001H,001H,004H>,
				  <035H,011H,044H,000H,0F8H,0F5H,0FFH,075H,
				   000H,000H,00EH>,
				  <010H,010H,00BH,008H,0A7H,0D5H,0ECH,0F5H,
				   000H,000H,000H>,
				  <020H,001H,00BH,007H,0A8H,0D6H,0C8H,0B7H,
				   000H,000H,000H>,
				  <000H,001H,00BH,000H,088H,0D5H,0C4H,0B7H,
				   000H,000H,000H>,
				  <00CH,010H,08FH,080H,041H,033H,031H,02BH,
				   000H,003H,008H>,
				  <017H,0F7H,000H,000H,03BH,0EAH,0DFH,097H,
				   003H,000H,00BH>,
				  <012H,018H,006H,009H,073H,03CH,002H,074H,
				   000H,000H,00EH>,
				  <002H,008H,000H,002H,03EH,014H,001H,0F3H,
				   002H,002H,00EH>,
				  <0F5H,0F6H,0D4H,000H,0EBH,045H,003H,068H,
				   000H,000H,007H>,
				  <0F0H,0CAH,000H,0C0H,0DAH,0B0H,071H,017H,
				   001H,001H,008H>,
				  <0F0H,0E2H,000H,0C0H,01EH,011H,011H,011H,
				   001H,001H,008H>,
				  <0E7H,0E8H,000H,00EH,034H,010H,000H,0B2H,
				   002H,002H,00EH>,
				  <00CH,004H,000H,000H,0F0H,0F6H,0F0H,0E6H,
				   002H,000H,00EH>,
				  <000H,000H,00BH,000H,0A8H,0D6H,04CH,045H,
				   000H,000H,000H>,
				  <000H,000H,00BH,000H,0AAH,0D2H,0C8H,0B7H,
				   000H,000H,000H>,
				  <026H,000H,000H,000H,0F0H,0FAH,0F0H,0B7H,
				   003H,003H,00EH>,
				  <010H,0C2H,007H,023H,0F7H,0E0H,0F5H,041H,
				   002H,002H,082H>,
				  <0F2H,0F1H,00AH,038H,088H,0ADH,0F4H,088H,
				   002H,002H,002H>,
				  <0D0H,0C2H,081H,023H,0A6H,0E0H,0F6H,041H,
				   002H,002H,081H>,
				  <040H,0C2H,000H,023H,0F5H,0E0H,038H,041H,
				   000H,002H,005H>,
				  <001H,0C2H,003H,023H,0B8H,0E0H,0B5H,041H,
				   001H,002H,07DH>,
				  <040H,0C2H,000H,023H,0F5H,0E0H,038H,041H,
				   000H,002H,0F1H>,
				  <001H,0B3H,008H,0C1H,088H,018H,0A5H,050H,
				   001H,000H,0A3H>,
				  <000H,0C2H,000H,023H,0C6H,0E0H,098H,041H,
				   000H,002H,083H>,
				  <001H,0B3H,009H,0C1H,086H,018H,0A5H,050H,
				   001H,000H,0A3H>,
				  <000H,0C2H,000H,023H,0C6H,0E0H,098H,041H,
				   000H,002H,003H>,
				  <000H,0C2H,000H,023H,0C6H,0E0H,098H,041H,
				   000H,002H,005H>,
				  <004H,0C2H,00CH,023H,0C5H,0E0H,0F6H,041H,
				   000H,002H,005H>,
				  <001H,0C2H,000H,023H,0C6H,0E0H,098H,041H,
				   000H,002H,005H>,
				  <001H,0C2H,082H,023H,0F6H,0E0H,0D5H,041H,
				   001H,002H,083H>,
				  <003H,0BFH,009H,0FFH,0E3H,0D0H,097H,050H,
				   000H,000H,0BBH>,
				  <00EH,0BFH,007H,0FFH,0B5H,0D1H,015H,050H,
				   001H,000H,0BBH>,
				  <001H,0BFH,007H,0C1H,077H,0D1H,073H,050H,
				   001H,000H,0BBH>,
				  <00EH,0F1H,0C7H,038H,095H,0ADH,078H,08EH,
				   000H,002H,002H>,
				  <001H,0BFH,000H,0FFH,0F8H,0D2H,0B6H,050H,
				   001H,000H,0BAH>,
				  <00AH,0C2H,0C7H,023H,095H,0E0H,078H,041H,
				   000H,002H,07CH>,
				  <001H,0BFH,007H,0C1H,0F9H,0D4H,0B5H,050H,
				   000H,000H,0BBH>,
				  <0D1H,0C2H,005H,023H,0E7H,0E0H,065H,041H,
				   001H,002H,09DH>,
				  <001H,0FEH,000H,038H,0E7H,0A9H,094H,082H,
				   000H,002H,003H>,
				  <001H,0BFH,000H,0FFH,0E7H,0D8H,094H,050H,
				   000H,000H,0BBH>,
				  <001H,0BFH,000H,0FFH,096H,0D8H,067H,050H,
				   000H,000H,0BAH>,
				  <001H,0BFH,000H,0FFH,0B4H,0DAH,026H,050H,
				   000H,000H,0BAH>,
				  <001H,0BFH,000H,0C1H,0B4H,0DBH,026H,050H,
				   000H,000H,0BAH>,
				  <095H,013H,081H,000H,0E7H,095H,001H,065H,
				   000H,000H,00EH>,
				  <095H,013H,081H,000H,0E7H,095H,001H,065H,
				   000H,000H,00EH>,
				  <010H,0BFH,000H,0C1H,096H,0DEH,067H,050H,
				   000H,000H,0BAH>,
				  <011H,0BFH,000H,0FFH,096H,0DFH,067H,050H,
				   000H,000H,0BAH>,
				  <000H,0BFH,00EH,0C1H,058H,0D0H,0DCH,050H,
				   002H,000H,0BAH>,
				  <000H,0BFH,00EH,0FFH,05AH,0D2H,0D6H,050H,
				   002H,000H,0BAH>,
				  <052H,0BFH,007H,0C1H,049H,0D3H,004H,050H,
				   003H,000H,0BBH>,
				  <052H,0BFH,007H,0C1H,041H,0D4H,002H,050H,
				   003H,000H,0BBH>,
				  <000H,0BFH,00EH,0FFH,05AH,0D5H,0D6H,050H,
				   001H,000H,0BAH>,
				  <010H,0BFH,00EH,0C1H,053H,0D6H,09FH,050H,
				   001H,000H,0BAH>,
				  <011H,0FEH,000H,038H,0F5H,0A9H,075H,080H,
				   000H,002H,002H>,
				  <004H,0C2H,000H,023H,0F8H,0E0H,0B6H,041H,
				   001H,002H,003H>,
				  <004H,0C2H,000H,023H,0F8H,0E0H,0B7H,041H,
				   001H,002H,003H>,
				  <001H,0BFH,00BH,0C1H,05EH,0D8H,0DCH,050H,
				   001H,000H,0BAH>,
				  <000H,0BFH,007H,0C1H,05CH,0DAH,0DCH,050H,
				   001H,000H,0BAH>,
				  <0C5H,0D5H,04FH,000H,0F2H,0F4H,060H,07AH,
				   000H,000H,008H>,
				  <0C5H,0D5H,04FH,000H,0F2H,0F2H,060H,072H,
				   000H,000H,008H>

ResidentCode	ends
















