COMMENT @/********************************************************

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
	DL	09.03.2000	bsSingle
        DL	13.03.2000	Ableitung BSD8ST
        DL	16.03.2000	bsSingle abgeschafft
        DL	16.08.2000	Translation for ND

Routines:
	Name			Description
	----			-----------
        BSDNWGetStatus		returns bsStatus and dacStatus
        BSDNWGetAIState		returns aiStatus
        BSDNWStartPlay		Start playing
        BSNWISR			ISR for NewWave-PLAY

Description:
        Totally new concept for playing Sampledata without
	Soundlibrary and Streamlibrary

bsOptions:
	Bit 0:  TRUE --> Buffer will be erased after playing

*****************************************************************/@

BSNW_STATE_IDLE		equ	0	; soundcard is idle

; States 1,2 and 5 are reserved for recording Recording

BSNW_PLAY_PREPARE	equ	3	; NewWave-Play Prepare phase
BSNW_PLAY_RUN		equ	4	; NewWave-Play active

;/////////////////////////////////
;	Globals
;/////////////////////////////////

idata   segment

	bsOptions	byte	1	; Bit 0 -> Buffer will be erased
					; by ISR after playing
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
; 	returns dacStatus/bsStatus
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
; 	Start WAV-Output
;       Top-Level call other subroutines
;
;
; OUT:	cx      0 = OK
;		1 = problems
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWStartPlay	proc	far
	uses	ax,bx,dx,di,ds
        .enter
	mov	ax,segment dgroup
        mov	ds,ax

;-------------------
; dacStatus = idle ?
;-------------------
	tst	ds:[dacStatus]		; DAC active ?
        jnz	error			; yes

	mov	ds:[bsStatus],BSNW_PLAY_PREPARE
	clr	ds:[bsRecDataFlag]	; clear DataFlag

;-------------------
; Mono / Stereo
;-------------------
        mov	ah,DSP_DMA_PCM_AI_MONO_LOW
	mov	al,ds:[bsChannels]	; get channels
        cmp	al,2			; Stereo ?
        jnz	set_bef			; no
;
; Stereomode
;
        mov	al,MIXER_OUTPUT
	mov	dx,ds:[basePortAddress]
        add	dx,4			; Mixer Address Port
        out	dx,al
        inc	dx
        in	al,dx
        or	al,00000010b
        out	dx,al

	mov	ah,DSP_DMA_PCM_AI_HIGH	; DSP-command

set_bef:
	mov	ds:[DSPFormatCommand],ah

;-------------------
;  DSP timeconstant
;-------------------
	call	BSDRecSetTimeConst

;-------------------
; Mono / Stereo
;-------------------
	mov	al,ds:[bsChannels]
        cmp	al,2			; Stereo ?
        jnz	set_size		; no
;
; Filterstatus
;
        mov	al,MIXER_OUTPUT
	mov	dx,ds:[basePortAddress]
        add	dx,4			; Mixer Address Port
        out	dx,al
        inc	dx
        in	al,dx
        mov	ds:[filterState],al	; store in tempbuffer
        or	al,00100000b		;
        out	dx,al
	mov	ds:[hsFlag],1		; set Highspeedflag

;------------------------
;  DSP Blocktransfersize
;------------------------
set_size:
	call	BSDRecSetTransferSize

;------------------------
; Start AutoInit Transfer
;------------------------
        mov	ds:[bsStatus],BSNW_PLAY_RUN
	call	BSDNWStartAI
        jc	error			; error !
	mov	cx,0			; no error
        jmp	done			; --> End

;------------------------
;    handling errors
;------------------------
error1:
	call	BSDRecFreeBuffer	; release buffer

;------------------------
;   	E N D
;------------------------
error:
        mov	ds:[bsStatus],BS_STATE_IDLE
	mov	cx,1
        clc			; CY = 1

done:
        .leave
        ret

BSDNWStartPlay	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWStartAI
;
; 	Start AutoInit Transfer
;	for Output
;
;
;  IN:	-
;
; OUT:	CY	TRUE = error
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDNWStartAI	proc	near
	uses	ax,bx,cx,dx,di,ds
        .enter

	mov	ax,segment dgroup
        mov	ds,ax
	clr	ds:[bsRecDataHalf]
        clr	ds:[bsRecDataFlag]

        mov	cl,ds:[DSPFormatCommand]
	SBDDACWriteDSP  cl, 0 		; AutoInit Output

        clc
        .leave
        ret

BSDNWStartAI	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDNWGetAIState
;
; 	Returns Statusvar. Autoinittransfer
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
	tst	ch			; set bsOptions ?
        jz	noset			; nein
        mov	ds:[bsOptions],cl	; ja
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
; 	ISR for NewWavePlay
;
;	Will be called when the buffer
;       must be filled with new data
;
;  IN:	(glob)	bsOptions
;	ds	dgroup
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSNWISR	proc	far
	uses    ax,cx,ds,di,es
        .enter


;-----------------------------
; 	erase the old data
;-----------------------------
kill_half:
	tst	ds:[bufferO2]		; Buffer existent ?
        jz	done			; no (zero len)

        mov	di,0			; Offsetpointer
        mov	cx,ds:[bufferO2]

	mov	ah,ds:[bsOptions]
        test	ah,01h			; Flag (Bit0) ?
        jz	done			; no, don't erase !

	mov	al,ds:[bsRecDataHalf]
	tst	al			; lower half ?
        jz	firstbuf
	mov	di,cx			; higher half

firstbuf:
	mov	ax,ds:[bufferSegment]
        mov	es,ax			; Segmentaddress
	mov	ah,080h
next:
        mov	es:[di],ah		; erase Buffer
        inc	di
        dec	cx
        jnz	next

done:
        inc	ds:[bsRecDataFlag]

	mov	al,ds:[bsRecDataHalf]
        xor	al,01h
	mov	ds:[bsRecDataHalf],al
done2:
        .leave
        ret
BSNWISR	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSResetMode
;
;
;  IN:	(glob)	bsStatus
;	ds	dgroup
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSResetMode	proc	near
	uses    ax,cx,dx,ds,di
        .enter

	mov	dx,ds:[basePortAddress]
        add	dx,4			; Mixer Address Port

;------------------------
; 	Recording
;------------------------
	mov	al,ds:[bsStatus]
        cmp	al,BSREC_STATE_RUN	; Recording ?
	jnz	new_wave		; no
;
; Restore Inputfilter
;
        mov	al,MIXER_FILTER		; Inputfilter
        out	dx,al
        inc	dx
        mov	al,ds:[filterState]	; restore old value from temp buffer
        out	dx,al
;
; Reset to Mono
;
	SBDDACWriteDSP  DSP_MONO_MODE, 0

	jmp	short done

;------------------------
; 	NewWave-Play
;------------------------
new_wave:

;
; Restore Filter
;
        mov	al,MIXER_OUTPUT		; Inputfilter (0E)
        out	dx,al
        inc	dx
        mov	al,ds:[filterState]	; restore old value from temp buffer
        out	dx,al
;
; Reset to Mono
;
        dec	dx			; Mixer Address Port (224)
        mov	al,MIXER_OUTPUT		; Inputfilter (0E)
        out	dx,al
        inc	dx
        in	al,dx
        and	al,11111101b
        out	dx,al

done:
        .leave
        ret
BSResetMode	endp

ResidentCode    ends


