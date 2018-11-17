COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Treiber

DATEI:		bsrecord.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	06.10.98	Init
        DL	08.10.99	Ableitung Recording
        DL	20.02.2000	NewWave

ROUTINEN:
	Name			Description
	----			-----------
	BSDRecGetMaxProperties	Max Samprate/Bittiefe/Kanalzahl
	BSDRecGetData		Warten auf Samplingdaten
	BSDStopRecOrPlay 	Recording stoppen
	BSDRecStartRecording 	Recording starten
	BSDRecAllocateBuffer 	Buffer belegen
	BSDRecFreeBuffer 	Belegten Puffer freigeben
	BSDRecProgramDMA 	DMA programmieren
	BSRECISR		ISR fÅr Recording
        BSRecordGetRMSValue	ADC-RMS Spannungsmessung

Beschreibung:
	Mit den folgenden Routinen wurde der Treiber um
        Recording-Features erweitert.
        In der ISR mu· getestet werden, ob das Flag bsStatus
	(vorher	bsRecordState) gesetzt ist und damit die Record-ISR
	aufgerufen werden mu·.   (Statt BSDACISR)

NewWave:
	Da zum selben Zeitpunkt nur eine Betriebsart moeglich ist,
        wird die Statusvariable bsStatus (vorher bsRecordState)
        von NewWave-Play und Recording gleichermassen benutzt.


*****************************************************************@

;
; Maximale Samplingparameter
; gÅltig fÅr Recording / NewWave-Play
;
BSD_MAX_RATE		equ	44100
BSD_MAX_BITS		equ	16
BSD_MAX_CHANNELS        equ	2
BSD_STEREO_TOGGLE	equ	0	; StereokanÑle sind nicht vertauscht
BS_STATE_IDLE		equ	0	; Zustaende fuer bsStatus

BSREC_STATE_PREPARE	equ	1
BSREC_STATE_RUN		equ	2
; Status 3,4 in Modul BSNWAV.ASM definiert !
BSREC_STATE_GET_RMS	equ	5	; RMS-Messung am ADC-Eingang

BSREC_DATA_WAIT		equ	0	; ZustÑnde fÅr bsRecDataFlag
BSREC_DATA_READY	equ	1

BSREC_HALF_LOW		equ	1	; ZustÑnde fÅr bsRecDataHalf
BSREC_HALF_HIGH		equ	0

;/////////////////////////////////
;	globale Variable
;/////////////////////////////////

idata           segment

	bsStatus		byte	0	; 0 = kein Recording
        					; 1 = Vorbereitungsphase
                                                ; 2 = Recording aktiv

        bsRecSamplerate		word	22050	; Samplerate
	bsRecChannels		byte	1	; Kanalzahl
        bsRecBits		byte	8	; Bittiefe

        bsRecDataFlag		byte	0	;>0 = Daten stehen bereit
						; 0 = auf neue Daten warten
	bsRecDataHalf		byte	0	; 1 = untere HÑlfte fertig
        					; 0 = obere HÑlfte fertig
idata           ends



;===========================================================

LoadableCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecGetMaxProperties
;
; 	Maximale Recordingparameter
;       zurÅckgeben
;
;  IN:	-
;
; OUT:	cx	max. Samplerate
;	dl	max. Kanalzahl
;	dh	max. Bittiefe
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecGetMaxProperties	proc	far
	uses	ds,di
        .enter

;-----------------------------------------
; Maximale Recordingparameter zurÅckgeben
;-----------------------------------------
	mov	cx,BSD_MAX_RATE		; 44100
        mov	dh,BSD_MAX_BITS		; 16 Bit
        mov	dl,BSD_MAX_CHANNELS	; 2
        mov	ax,BSD_STEREO_TOGGLE	; 0

        .leave
	ret

BSDRecGetMaxProperties	endp

LoadableCode    ends


ResidentCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecGetData
;
; 	Wartet bis Daten bereit stehen
;       und gibt Zeiger und LÑnge zurÅck.
;
;  IN:	-
;
; OUT:	dx	Zeiger Segmentadresse
;	ax	Zeiger Offset
;	bx	LÑnge
;	cx	0 = OK
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecGetData	proc	far
	uses	ds,di
        .enter
	mov	ax,segment dgroup	; dgroup setzen
        mov	ds,ax

;------------------------------
; Warten bis Flag gesetzt wird
; oder Timeout anschlÑgt
;------------------------------
	mov	cx,500			; 500 Zyklen bis Timeout
next:
	tst	ds:[bsRecDataFlag]	; stehen Daten bereit ?
        jz	waitforflag		; nein, warten

;------------------------------
;    PufferÅberlauf prÅfen
;------------------------------
	mov	al,ds:[bsRecDataFlag]	; Flagwert holen
        cmp	al,1			; 1 --> kein PufferÅberlauf ?
        jz	wakeup			; JA, alles OK --> weitermachen

; LA 05.11.2000
; resetting Overflow-counter
	clr	ds:[bsRecDataFlag]
        mov	cl,al			; Flagwert als Fehlercode zurÅckgeben
        mov	ch,0
        jmp	done			; mit Fehler zurÅck

;-----------------------------------
; Platz fÅr etwaige Pegel-Berechnung
;-----------------------------------

;-----------------------------------
waitforflag:
        mov	ax,1
	call	TimerSleep		; 1/60 sec warten
	loop	next			; (dec cx, jnz next)
        mov	cx,1			; Fehlerkennung

	WARNING	BS_REC_GET_DATA_TIMEOUT

        jmp	short done

;---------------------------
; RÅckgabewerte berechnen
;---------------------------
wakeup:
	clr	ds:[bsRecDataFlag]	; Flag lîschen
        mov     ax,0			; 1. HÑlfte
        mov	dx,ds:[bufferSegment]	; Segmentadresse
        mov     bx,ds:[bufferO2]	; LÑnge
        tst	ds:[bsRecDataHalf]	; untere HÑlfte ?
        jnz	lower			; ja
	mov	ax,bx			; nein, obere HÑlfte
lower:
	mov	cx,0			; Fehlerkennung
done:
        .leave
        ret
BSDRecGetData	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSRECISR
;
; 	ISR fÅr Recording
;       Wird aufgerufen wenn Buffer halb
;	gefÅllt wurde und geleert werden kann.
;
;
;
;  IN:	-
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSRECISR	proc	far
	uses    ax,ds
        .enter

;------------------------
; 	Flags setzen
;------------------------
; bsRecDataFlag wird durch INT inkrementiert,
; Die Abholroutine mu· den Wert dekrementieren.
; Wenn Wert grî·er wird als zum Bsp. 2 wurden
; die Daten nicht schnell genug abgeholt.
; Errorflag wird gesetzt um Fehler anzuzeigen !
;

        inc	ds:[bsRecDataFlag]

	mov	al,ds:[bsRecDataHalf]
        xor	al,01h			; Seite swappen
	mov	ds:[bsRecDataHalf],al

        .leave
        ret
BSRECISR	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDStopRecOrPlay
;
; 	Recording/Playing stoppen
;
;       ruft BSSecondUnlock auf
;
;
;  IN:	-
;
; OUT:	cx      0 = OK
;		1 = Befehl konnte nicht
;		    ausgefÅhrt werden.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDStopRecOrPlay	proc	far
	uses	ax,bx,dx,di
        .enter
	mov	ax,segment dgroup	; dgroup setzen
        mov	ds,ax

;------------------
; Puffer freigeben
;------------------
	call	BSSecondUnlock		; Job wird weitergereicht

; Status zurÅcksetzen

	mov	ds:[bsStatus],BS_STATE_IDLE

        .leave
        ret

BSDStopRecOrPlay	endp

ResidentCode    ends

LoadableCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecStartRecording
;
; 	Start Recording
;       Top-Level subroutine will call
;	other subroutines.
;
;  IN:	dx	buffersize
;
; OUT:	cx      0 = OK
;		1 = Befehl konnte nicht
;		    ausgefÅhrt werden.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecStartRecording	proc	far
	uses	ax,bx,dx,di,ds
        .enter
	mov	ax,segment dgroup	; dgroup setzen
        mov	ds,ax

;-------------------
; dacStatus = Ruhe ?
;-------------------
	tst	ds:[dacStatus]		; DAC-Ausgabe aktiv ?
        jnz	error			; ja

	mov	ds:[bsStatus],BSREC_STATE_PREPARE
	clr	ds:[bsRecDataFlag]	; DataFlag lîschen
        clr	ds:[bsRecDataHalf]	; Startwert fÅr fertige PufferhÑlfte

;-------------------
;  Buffer belegen
;-------------------
	mov	cx,dx
;        mov	cx,4000h		; 16 kByte ergibt bei ungÅnstigster
        				; PagegrenzenÅberschreitung 8 kB
                                        ; und ergibt einen INT-Takt von
                                        ; 22ms bei 44 kHz / 16 Bit / St.
	call	BSDRecAllocateBuffer	; ax = Bufferadresse

        jc	error			; Fehler !

;-------------------
;  DMA programmieren
;-------------------
	call	BSDRecProgramDMA
        jc	error1			; Fehler ! / Puffer freigeben

;-------------------
;  DSP Samplerate
;-------------------
        SBDDACWriteDSP  DSP_SET_INPUT_RATE, 0	; DSP-Command
	mov	cx,ds:[bsRecSamplerate]
        SBDDACWriteDSP  ch, 0		; Samplerate
        SBDDACWriteDSP  cl, 0

;------------------------
; Start AutoInit Transfer
;------------------------
	call	BSDRecStartAI
        jc	error			; Fehler !
	mov	ds:[bsStatus],BSREC_STATE_RUN
	mov	cx,0			; kein Fehler
        jmp	done			; --> Ende

;------------------------
;    Fehlerbehandlung
;------------------------
error1:
	call	BSDRecFreeBuffer	; Puffer freigeben

;------------------------
;   	E N D E
;------------------------
error:
        mov	ds:[bsStatus],BS_STATE_IDLE
	mov	cx,1		; Fehlerkennung
        clc			; CY = 1

done:
        .leave
        ret

BSDRecStartRecording	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecAllocateBuffer
;
; 	Buffer belegen
;
;
;  IN:	cx	PufferlÑnge
;
; OUT:  ax	Buffersegment
;	CY	TRUE = Fehler
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecAllocateBuffer	proc	near
	uses	bx,dx,di
        .enter

EC<	WARNING	BS_REC_ALLOCATE_BUFFER	>

;----------------------
; 	Puffer belegen
;----------------------
	mov	ax,cx			; LÑnge
        mov	ds:[bufferLen],ax	; abspeichern
        mov	cl,mask HF_FIXED	; HeapFlags
;        mov	ch,mask HAF_ZERO_INIT
        mov	ch,0
					; HeapAllocFlags
                                        ; LA 18.10.99 HAF_LOCK um
					; ILLEGAL_SEGMENT zu vermeiden
	call	MemAlloc
	jc	done			; Fehler !

	mov	ds:[bufferHandle],bx	; Handle to block allocated
	mov	ds:[bufferSegment],ax	; Address of block allocated

        call	BSCreateStack		; Stack fÅr ISR anlegen

	clc

done:
        .leave
        ret

BSDRecAllocateBuffer	endp



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecFreeBuffer
;
; 	Belegten Puffer freigeben
;
;
;  IN:	bufferHandle
;
; OUT:	CY	TRUE = Fehler
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecFreeBuffer	proc	near
        .enter
	call	BSSecondUnlock	; Job wird weitergereicht
        clc

        .leave
        ret

BSDRecFreeBuffer	endp


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecStartAI
;
; 	Start AutoInit Transfer
;
;
;  IN:	ds	dgroup
;
; OUT:	CY	TRUE = Fehler
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecStartAI	proc	near
	uses	ax,bx,dx,di
        .enter

;------------------------
; DSP Transfercommand
;------------------------
	mov	al,ds:[bsRecBits]
	cmp	al,16				; 16 Bit ?
        jnz	bit8				; nein

        SBDDACWriteDSP  DSP_16BIT_INPUT, 0	; Command

        mov	bh,DSP_MODE_16BIT_MONO
	mov	al,ds:[bsRecChannels]
	cmp	al,1				; Mono ?
        jz	mono
        mov	bh,DSP_MODE_16BIT_STEREO

        jmp     mono

bit8:
        SBDDACWriteDSP  DSP_8BIT_INPUT, 0	; Command

        mov	bh,DSP_MODE_8BIT_MONO
	mov	al,ds:[bsRecChannels]
	cmp	al,1			; Mono ?
        jz	mono
        mov	bh,DSP_MODE_8BIT_STEREO
mono:
        SBDDACWriteDSP  bh, 0		; Mode (Mono/Stereo)

        mov	cx,ds:[bufferO2]	; halbe Secondbufferlaenge
        mov	al,ds:[bsRecBits]
	cmp	al,16			; 16 Bit ?
	jnz	set_size		; nein
	shr	cx			; ja, Blockgroesse in Words
set_size:
        dec	cx
	SBDDACWriteDSP  cl, 0			; L Byte
	SBDDACWriteDSP  ch, 0			; H Byte

        clc
        .leave
        ret

BSDRecStartAI	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecSetSampling
;
; 	Recordparameter setzen
;
;
;  IN:	bx	Samplerate
;	cx	channels
;	dx	bits
;
; OUT:	cx      0 = OK
;		1 = Befehl konnte nicht
;		    ausgefÅhrt werden.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecSetSampling	proc	far
	uses	ax,bx,dx,di
        .enter
	mov	ax,segment dgroup	; dgroup setzen
        mov	ds,ax
;
; Werte abspeichern
;
	mov	ds:[bsRecSamplerate],bx
	mov	ds:[bsRecChannels],cl
	mov	ds:[bsRecBits],dl
        mov	cx,0			; RÅckgabewert

;----------------------------
;   Samplingdaten prÅfen
;----------------------------

        .leave
        ret

BSDRecSetSampling	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSRecordGetRMSValue
;
; RMS-Effektivspannung messen
;
; Methode: Die in ax angegebene Durchlauf-
;	   zahl gibt an, wie oft vom DSP
;	   im Direct Mode Sampledaten abge-
;          holt werden.
;          Die MIN und MAX-Werte werden
;          zur Berechnung der Effektiv-
;          spannung benutzt.
;
;  IN:	ax	Anzahl DurchlÑufe
;
; OUT:	bx  	Value (0...255)
;	cx      0 = OK
;		1 = Befehl konnte nicht
;		    ausgefÅhrt werden.
;
; 19.10.99	Abbruch wenn Play im Gange
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSREC_RMS_OK	equ	0	; Fehlercode fÅr RÅckmeldung
BSREC_RMS_ERROR	equ	1


BSRecordGetRMSValue	proc	far
	uses	ax,dx,di
        .enter
        mov	cx,ax			; Anzahl DurchlÑufe
	mov	ax,segment dgroup
        mov	ds,ax

;------------------------
; Test ob DSP belegt ist
;------------------------
        mov	bx,0			; RÅckgabewert im Fehlerfall
	tst	ds:[dacStatus]		; DAC frei ? (alte Routinen)
        jnz	notfree

	tst	ds:[bsStatus]		; Recording / NewWave ?
        jz	free			; ja
notfree:
        mov	cx,BSREC_RMS_ERROR	; Fehlercode
        jmp	done

;------------------------
; RMS Messung durchfÅhren
;------------------------
free:
        mov	ds:[bsStatus],BSREC_STATE_GET_RMS
        mov	bx,8080h		; BL = MIN / BH = MAX
next:
	SBDDACWriteDSP  DSP_RECORD_DIRECT, 0
	SBDDACReadDSP 0			; Wert holen

;------------------------
; 	MIN / MAX Werte
;------------------------
	cmp	al,bl
	jnc	not_under
	mov	bl,al			; neuer MIN Wert
not_under:
	cmp	al,bh
	jc	not_over
        mov	bh,al			; neuer MAX Wert

not_over:
	loop	next			; cx-1 ungleich 0 --> next

;------------------------
;	RMS Berechnung
; Ruhepegel (80h) abziehen
;------------------------
	mov	al,80h
        sub	al,bl			; al = Absolutwert von MIN
        mov	bl,al			; bl = Absolutwert von MIN

        mov	al,bh			; MIN
        sub	al,80h			; Ruhepegel abziehen
        mov	ah,0

        mov	bh,0			; bx = MIN

        add	ax,bx			; ax = Spitze + Spitze
        mov	bx,ax			; RÅckgabewert

        mov	cx,BSREC_RMS_OK		; Fehlercode
        mov	ds:[bsStatus],BS_STATE_IDLE

; Value zurÅckgeben
done:
        .leave
        ret

BSRecordGetRMSValue	endp

;/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecProgramDMA
;
; 	DMA programmieren
;
;
;  IN:	ax	Buffersegmentadresse
;
; OUT:	CY	TRUE = Fehler
;
; DL	04.11.2000	RecProgramDMADriver replaced by
;			ProgramDMADriver for 16 Bit Recording
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

BSDRecProgramDMA	proc	near
	uses	ax,bx,dx,di
        .enter

;-----------------------
;	DMA vorbereiten
;-----------------------
	mov	bx,ax			; Pufferadresse
	mov	dx,ds:[bufferLen]	; LÑnge

        call	BSDMAGrenzen		; Segmentgrenzen prÅfen
	mov	ds:[bufferSegment],bx	; korrigierte Segmentadresse

        mov	cx,2			; Playmode = Recording
	call	ProgramDMADriver	; DMA vorbereiten

;-----------------------
; Pufferwerte berechnen
;-----------------------
        mov	ax,ds:[bufferLen]	; LÑnge
        mov	ds:[bufferFree],ax	; freier Speicher
        mov	ds:[bufferMax],ax	; Offset Pufferende
        clr	ds:[dacStatus]		; dacStatus = wartend
        clr	ds:[bufferP2]		; Start Buffer
        shr	ax			; /2
	mov	ds:[bufferO2],ax	; PufferhÑlfte

	clc

        .leave
        ret

BSDRecProgramDMA	endp

LoadableCode            ends
