COMMENT @********************************************************

	Copyright (C) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Treiber

DATEI:		bsnwav.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	06.10.98	Init
        DL	20.02.2000	Ableitung BSNWAV.ASM
	DL	02.03.2000	bsOptions Bit 0 definiert
	DL	25.10.2000	Translations for NewDeal

ROUTINEN:
	Name			Description
	----			-----------
	BSDNWGetStatus		returns bsStatus and dacStatus
	BSDNWGetAIState		returns aiStatus
	BSDNWStartPlay		Starting Play

*****************************************************************@

BSNW_STATE_IDLE		equ	0	; Soundcard idle

; The states 1 and 2 are reserved for recording

BSNW_PLAY_PREPARE	equ	3	; NewWave-Play Prepare state
BSNW_PLAY_RUN		equ	4	; NewWave-Play Run State


;/////////////////////////////////
;	Globals
;/////////////////////////////////

idata   segment

	bsOptions	byte	1	; Bit 0 -> ISR must clear old
					; DMA bufferhalf
	bsPause		byte	0	; 1 = Pause 2 = Restart


idata   ends



;===========================================================

LoadableCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWSetPause
;
; 	Pause Mode
;
;  IN:	cl	Mode	0 = request mode
;			1 = PAUSE
;			2 = RESTART
;
; OUT:	ch	current mode
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWSetPause	proc	far
	uses	ax,bx,dx,ds
	.enter
	mov	ax,segment dgroup
	mov	ds,ax

	mov	ch,0			; default value
	tst	ds:[dacStatus]		; old WAV-Output ?
	jnz	done

	mov	al,ds:[bsStatus]	; NewWave Play
	cmp	al,BSNW_PLAY_RUN	; running ?
	jnz	done

;----------------------------
; 	PAUSE / RESTART
;----------------------------
	mov	ch,ds:[bsPause]		; current mode
	cmp	cl,ch			; new mode equal old mode ?
	jz	done			; yes

	cmp	ch,1			; current mode = PAUSE ?
	jz	nopause			; yes
	cmp	cl,1			; new mode = PAUSE ?
	jnz	nopause			; nein
;
; PAUSE
;
	SBDDACWriteDSP	DSP_DMA_HALT,0
	mov	ch,1
	mov	ds:[bsPause],ch
	jmp	done

;
; PAUSE already active
;
nopause:
	cmp	cl,2			; new mode = RESTART ?
	jnz	done			; no
;
; RESTART
;
	SBDDACWriteDSP	DSP_DMA_CONTINUE,0
	mov	ch,2
	mov	ds:[bsPause],ch
done:
	.leave
	ret

BSDNWSetPause	endp



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWGetStatus
;
; 	will return dacStatus/bsStatus
;
;  IN:	-
;
; OUT:	cl	bsStatus
;	ch	dacStatus
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWGetStatus	proc	far
	uses	ax,bx,dx,ds
	.enter
	mov	ax,segment dgroup
	mov	ds,ax

	mov	ch,ds:[dacStatus]
	mov	cl,ds:[bsStatus]

	.leave
	ret

BSDNWGetStatus	endp


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWStartPlay
;
; Start WAV-output
; Top-Level UP will call other subroutines
;
; OUT:	cx      0 = OK
;		1 = error
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWStartPlay	proc	far
	uses	ax,bx,dx,di,ds
	.enter
	mov	ax,segment dgroup	; dgroup setzen
	mov	ds,ax

;-------------------
; dacStatus = idle ?
;-------------------
	tst	ds:[dacStatus]		; active ?
	jnz	error			; yes

	mov	ds:[bsStatus],BSNW_PLAY_PREPARE
	clr	ds:[bsRecDataFlag]	; clear DataFlag

;-------------------
;  DSP Samplerate
;-------------------
	SBDDACWriteDSP  DSP_SET_SAMPLE_RATE, 0	; DSP-Command
	mov	cx,ds:[bsRecSamplerate]
	SBDDACWriteDSP  ch, 0		; Samplerate
	SBDDACWriteDSP  cl, 0

;------------------------
;  Flags initialisieren
;------------------------
	mov	ds:[bsStatus],BSNW_PLAY_RUN
	clr	ds:[bsRecDataHalf]
	clr	ds:[bsRecDataFlag]

;------------------------
; DSP Transfercommand
;------------------------
	mov	al,ds:[bsRecBits]
	cmp	al,16				; 16 Bit
	jnz	bit8

	SBDDACWriteDSP  DSP_16BIT_OUTPUT, 0	; Command

	mov	bh,DSP_MODE_16BIT_MONO
	mov	al,ds:[bsRecChannels]
	cmp	al,1				; Mono ?
	jz	mono
	mov	bh,DSP_MODE_16BIT_STEREO

	jmp     mono

bit8:
	SBDDACWriteDSP  DSP_8BIT_OUTPUT, 0	; Command

	mov	bh,DSP_MODE_8BIT_MONO
	mov	al,ds:[bsRecChannels]
	cmp	al,1			; Mono ?
	jz	mono
	mov	bh,DSP_MODE_8BIT_STEREO
mono:
	SBDDACWriteDSP  bh, 0		; Mode (Mono/Stereo)

	mov	cx,ds:[bufferO2]
	mov	al,ds:[bsRecBits]
	cmp	al,16				; 16 Bit
	jnz	blocksize
	shr	cx,1

blocksize:
	dec	cx			; Blocksize - 1
	SBDDACWriteDSP  cl, 0
	SBDDACWriteDSP  ch, 0

;------------------------
; Start AutoInit Transfer
;------------------------

	mov	cx,0			; no error
	jmp	done			; --> End

;------------------------
;    	Error
;------------------------
error:
	mov	ds:[bsStatus],BS_STATE_IDLE
	mov	cx,1
	clc				; CY = 1

done:
	.leave
	ret

BSDNWStartPlay	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWGetAIState
;
; Will return state of Autoinittransfer
;
;
;  IN:	ch	>0 -> set bsOptions (cl)
;	cl	bsOptions
;
; OUT:	cl	bsRecDataFlag
;	ch	bsRecDataHalf
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWGetAIState	proc	far
	uses	ax,bx,dx,ds
	.enter
	mov	ax,segment dgroup
	mov	ds,ax

;-------------------
; set bsOptions
;-------------------
	tst	ch			; setting bsOptions ?
	jz	noset			; no
	mov	ds:[bsOptions],cl	; yes
noset:

	mov	ch,ds:[bsRecDataHalf]
	mov	cl,ds:[bsRecDataFlag]

	.leave
	ret

BSDNWGetAIState	endp

LoadableCode    ends

ResidentCode    segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSNWISR
;
;  ISR for NewWavePlay
;  Will be called if half of the buffer
;  was played
;
;  IN:	-
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSNWISR	proc	far
	uses    ax,cx,ds,di,es
	.enter

	tst	ds:[bufferO2]		; Buffer existent ?
	jz	done			; no (zerosize)

	mov	di,0			; Offsetpointer
	mov	cx,ds:[bufferO2]

;-----------------------------
; 	clear old halfbuffer
;-----------------------------
	mov	ah,ds:[bsOptions]
	or	ah,1			; Bit 1 ?
	jz	done			; no, not delete

	mov	al,ds:[bsRecDataHalf]
	tst	al			; lower half
	jz	firstbuf
	mov	di,cx			; upper half

firstbuf:
	mov	ax,ds:[bufferSegment]
	mov	es,ax			; Segmentaddress
	mov	ah,080h
	mov	al,ds:[bsRecBits]
	cmp	al,16			; 16 Bit ?
	jnz	next			; no
	mov	ah,0			; yes, clear with 0
next:
	mov	es:[di],ah		; clear Buffer
	inc	di
	dec	cx
	jnz	next

;------------------------
; 	Set Flags
;------------------------
; bsRecDataFlag will be incremented by every INT.
; The Data-Writer must decrement this flag
; Values above 2 will indicate problems with the transfer speed
;
done:
	inc	ds:[bsRecDataFlag]

	mov	al,ds:[bsRecDataHalf]
	xor	al,01h			; swap
	mov	ds:[bsRecDataHalf],al

	.leave
	ret
BSNWISR	endp

if 0
; /*

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWStartAI
;
; 	Start AutoInit Transfer
;	for Playing
;
;
;  IN:	-
;
; OUT:	CY	TRUE = Fehler
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWStartAI	proc	near
	uses	ax,bx,dx,di,ds
	.enter

	mov	ax,segment dgroup	; dgroup setzen
	mov	ds,ax
	clr	ds:[bsRecDataHalf]
	clr	ds:[bsRecDataFlag]
;	SBDDACWriteDSP  DSP_DMA_PCM_AI_MONO_LOW, 0 ; AutoInit Output
						   ; 8 Bit Mono AI-Transfer
	clc
	.leave
	ret

BSDNWStartAI	endp

;*/

endif

ResidentCode    ends

