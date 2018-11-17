COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Treiber

DATEI:		bsrecord.asm

AUTOR:		Dirk Lausecker


 THE RECORDING FUNCTIONS ARE NOT PART OF THE LICENSING CONTRACT
 BETWEEN NEWDEAL INC. AND DIRK LAUSECKER !
 THE COMMENTS WILL BE FULLY TRANSLATED WHEN THE RECORDING FEATURE
 WAS LICENSED BY NEWDEAL OR OTHER COMPANIES !


REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	06.10.98	Init
        DL	08.10.99	Ableitung Recording
        DL	20.02.2000	NewWave
        DL	06.04.2000	Optimierung
        DL	16.08.2000	Translation

ROUTINEN:
	Name			Description
	----			-----------
	BSDRecGetMaxProperties	Get max Samprate/Bits/Channels
	BSDRecGetData		Waiting for Samplingdata
	BSDStopRecOrPlay 	Stop Recording or Playing
	BSDRecStartRecording 	Start Recording
	BSDRecAllocateBuffer 	Allocate Buffer for Recording
	BSDRecFreeBuffer 	Free the allocated buffer
	BSDRecProgramDMA 	Program DMA
	BSRECISR		ISR for Recording
        BSRecordGetRMSValue	ADC-RMS Levelmeter

Description:
	The following routines will improve the soundcard driver
        with recording capabilities.

Knowing problems:
	At this time a good PC is needed (>= P133) for recording.
        I believe the mechanism for saving the sampled data
        must be redesigned (Timeout problems)

*****************************************************************/@

;
; Max. Samplingparameter
; for Recording / NewWave-Play
;

BSD_MAX_RATE		equ	22050	; 22050 Hz
BSD_MAX_BITS		equ	8	; 8 Bit
BSD_MAX_CHANNELS        equ	2	; Stereo
BSD_STEREO_TOGGLE	equ	1	; channels must be toggled

BS_STATE_IDLE		equ	0	; states for bsStatus
BSREC_STATE_PREPARE	equ	1
BSREC_STATE_RUN		equ	2
; Status 3,4,6 defined in BSNWAV.ASM !

BSREC_STATE_GET_RMS	equ	5	; RMS-measuring on ADC-input

BSREC_DATA_WAIT		equ	0	; states for bsRecDataFlag
BSREC_DATA_READY	equ	1

BSREC_HALF_LOW		equ	1	; states for bsRecDataHalf
BSREC_HALF_HIGH		equ	0

;/////////////////////////////////
;	    Globals
;/////////////////////////////////

idata           segment

	bsStatus		byte	0	; 0 = no Recording
        					; 1 = Preparation phase
                                                ; 2 = Recording !

        bsSampleRate		word	22050	; Samplerate
	bsChannels		byte	1	; channels
        bsRecBits		byte	8	; Bits

        bsRecDataFlag		byte	0	;>0 = sample data ready for saving
						; 0 = wait for new sample data
	bsRecDataHalf		byte	0	; 1 = lower bufferhalf ready
        					; 0 = higher bufferhalf ready
        filterState		byte	0	; temp buffer for Filterstatus
	stereoMode		byte	0	; temp buffer fÅr Stereomode

idata           ends



;===========================================================

LoadableCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecGetMaxProperties
;
; 	Get max capabilities
;
;  IN:	-
;
; OUT:	cx	max. Samplerate
;	dl	max. channels
;	dh	max. Bits
;	al	0 = Stereo channel alignment OK
;		1 = channels must be swapped
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecGetMaxProperties	proc	far
	uses	ds,di
        .enter

	mov	cx,BSD_MAX_RATE		; 22050
        mov	dh,BSD_MAX_BITS		; 8 Bit
        mov	dl,BSD_MAX_CHANNELS	; 2
        mov	ax,BSD_STEREO_TOGGLE	; 1

        .leave
	ret

BSDRecGetMaxProperties	endp

LoadableCode    ends


ResidentCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecGetData
;
; 	Wait for data
;       return pointer and len of data
;
;  IN:	-
;
; OUT:	dx	Segment
;	ax	Offset
;	bx	Len
;	cx	0 = OK
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecGetData	proc	far
	uses	ds,di
        .enter
	mov	ax,segment dgroup
        mov	ds,ax

;------------------------------
; Warten bis Flag gesetzt wird
; oder Timeout anschlÑgt
;------------------------------
	mov	cx,200			; 200 Zyklen bis Timeout
next:
	tst	ds:[bsRecDataFlag]	; stehen Daten bereit ?
        jz	waitforflag		; nein, warten

;------------------------------
;    PufferÅberlauf prÅfen
;------------------------------
	mov	al,ds:[bsRecDataFlag]	; Flagwert holen
        cmp	al,1			; 1 --> kein PufferÅberlauf ?
        jz	wakeup			; JA, alles OK --> weitermachen

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

;	WARNING	BS_REC_GET_DATA_TIMEOUT

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

done:
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
;  IN:	(glob)	bsStatus
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
unlock:
	call	BSSecondUnlock		; Job wird weitergereicht

; Status zurÅcksetzen

	mov	ds:[bsStatus],BS_STATE_IDLE

done:
        .leave
        ret

BSDStopRecOrPlay	endp

ResidentCode    ends

LoadableCode            segment resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecStartRecording
;
; 	Recording starten
;       Top-Level UP ruft andere UP auf.
;
;
;
;  IN:	-
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
        mov	cx,4000h		; 16 kByte ergibt bei ungÅnstigster
        				; PagegrenzenÅberschreitung 8 kB
                                        ; und ergibt einen INT-Takt von
                                        ; 22ms bei 44 kHz / 16 Bit / St.
	call	BSDRecAllocateBuffer	; OUT: ax = Bufferadresse

        jc	error			; Fehler !

;-------------------
;  Mono/Stereo
;-------------------
        push	ax				; (1)

        mov	cl,DSP_RECORD_PCM_INPUT_AI
        mov	ch,0				; Highspeed-Flag = OFF

	mov	al,ds:[bsChannels]		; Kanalzahl
        cmp	al,2				; Stereo ?
        jnz	mono				; nein
; Stereo
	SBDDACWriteDSP  DSP_STEREO_INPUT, 0	; Mixer programmieren

        mov	ch,1				; Highspeed-Flag = ON
        mov	cl,DSP_DMA_PCM_AI_INPUT_HIGH	; DSP Kommando
mono:
        mov	ds:[hsFlag],ch			; Highspeedflag
	mov	ds:[DSPFormatCommand],cl	; DSP-Kommando fuer spaeter

;-------------------
;  DMA programmieren
;-------------------
        pop	ax				; (1)
	call	BSDRecProgramDMA		; IN ax = Buffersegmentadresse

;-------------------
;  DSP Zeitkonstante
;-------------------
	call	BSDRecSetTimeConst

;-------------------
;  Mono/Stereo
;-------------------
	mov	al,ds:[bsChannels]	; Kanalzahl
        cmp	al,2			; Stereo ?
        jnz	prog_size		; nein
;
; Input-Filter-Status speichern
; und ausschalten
;
        mov	al,MIXER_FILTER		; Inputfilter
	mov	dx,ds:[basePortAddress]
        add	dx,4			; Mixer Address Port
        out	dx,al
        inc	dx
        in	al,dx			; Auslesen
        mov	ds:[filterState],al	; merken
        or	al,00100000b		; Inputfilter deaktivieren
        out	dx,al

;------------------------
;  DSP Blocktransfersize
;------------------------
prog_size:
	call	BSDRecSetTransferSize

;------------------------
; Start AutoInit Transfer
;------------------------
	call	BSDRecStartAI
	mov	ds:[bsStatus],BSREC_STATE_RUN
	mov	cx,0			; kein Fehler
        jmp	done			; --> Ende

;------------------------
;    Fehlerbehandlung
;------------------------
	call	BSDRecFreeBuffer	; Puffer freigeben

;------------------------
;   	E N D E
;------------------------
error:
        mov	ds:[bsStatus],BS_STATE_IDLE
	mov	cx,1			; Fehlerkennung
        clc				; CY = 1

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

; EC<	WARNING	BS_REC_ALLOCATE_BUFFER	>

;----------------------
; 	Puffer belegen
;----------------------
	mov	ax,cx			; LÑnge
        mov	ds:[bufferLen],ax	; abspeichern
        mov	cl,mask HF_FIXED	; HeapFlags
        mov	ch,mask HAF_ZERO_INIT
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
;	Interne Routine
;
;13.02.2000 Inputfilter wieder herstellen
;
;
;  IN:	bufferHandle
;
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecFreeBuffer	proc	near
        .enter

unlock:
;	call	BSSecondUnlock		; (bis P 0.0)
	call	BSDStopRecOrPlay
;        mov	ds:[hsFlag],0		; Highspeedflag zuruecksetzen

        .leave
        ret

BSDRecFreeBuffer	endp


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecProgramDMA
;
; 	DMA programmieren
;
;
;  IN:	ax	Buffersegmentadresse
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
	call	RecProgramDMADriver	; DMA vorbereiten

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

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecSetTimeConst
;
; 	DSP Zeitkonstante
;
;
;  IN:	ds	dgroup
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecSetTimeConst	proc	near
	uses	ax,bx,dx,di
        .enter

;--------------------------------
; 16 Bit Zeitkonstante berechnen
;--------------------------------
	mov	cx,ds:[bsSampleRate]	; cx <- sampling rate

        mov	al,ds:[bsChannels]	; Kanalzahl
        cmp	al,1			; Mono ?
        jz	mono
        shl	cx			; Byterate * 2 wenn Stereo
mono:
	movdw   dxax, 256000000         ; dxax <- 256000000
	div     cx                      ; ax <- 65536 - divisor

	neg     ax                      ; ax <- divisor

	mov     bx, ax                  ; bx <- divisor for rate

	;
	;  Set up the DAC to operate at the given rate

        mov	dx,cx			; dx = Samplerate

	SBDDACWriteDSP  DSP_SET_RATE_DIVISOR, 0
	SBDDACWriteDSP  bh, 0

        .leave
        clc
        ret

BSDRecSetTimeConst	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecSetTransferSize
;
; 	DSP Blocktransfersize setzen
;       _
;
;
;  IN:	ds	dgroup
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecSetTransferSize	proc	near
	uses	ax,bx,dx,di
        .enter

        mov	cx,ds:[bufferO2]	; halbe Secondbufferlaenge
        dec	cx
	SBDDACWriteDSP  DSP_SET_BLOCK_SIZE, 0	; Blocklaenge (48h)
	SBDDACWriteDSP  cl, 0			; L Byte
	SBDDACWriteDSP  ch, 0			; H Byte
        clc

done:
        .leave
        ret

BSDRecSetTransferSize	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	BSDRecStartAI
;
; 	Start AutoInit Transfer
;
;
;  IN:	ds	dgroup
;
; OUT:	-
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BSDRecStartAI	proc	near
	uses	ax,bx,dx,di
        .enter

        mov	bl,ds:[DSPFormatCommand]
	SBDDACWriteDSP  bl,0 ; AutoInit Recording
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
	mov	ds:[bsSampleRate],bx
	mov	ds:[bsChannels],cl
	mov	ds:[bsRecBits],dl
        mov	cx,0			; RÅckgabewert

;----------------------------
;   Samplingdaten prÅfen
;----------------------------

done:
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

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecProgramDMADriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       DMA-Treiber fÅr Ausgabe programmieren

CALLED BY:      BSDRecProgramDMA
PASS:           bx      -> stream segment
		dx      -> buffer size
		INT_ON

RETURN:         bufferLen -> DMA-LÑnge

DESTROYED:      nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	09.11.97	Initial
				(aus SBDDACAttachToStream herausgelîst)
        DL	29.09.98	BestSound Template
        DL	14.10.99	FÅr Recording abgeleitet

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecProgramDMADriver    proc    far
	.enter
	;
	push	dx			; stream size [1]
;---------------------------------
;	DMA-Kanal belegen
;---------------------------------
	;
	;  Try to request the DMA channel
        ;
        ;DL:	gÅltiger DMA-Kanal wird in
        ;	[baseDMAChannel] bereitgestellt.
        ;
        mov	cx,ds:[baseDMAChannel]	; aktueller DMA-Channel
	mov     dl, 1
	shl     dl, cl                  ; dl <- mask of request channel
	mov     dh, dl                  ; dh <- mask of request channel
	mov     di, DR_REQUEST_CHANNEL

	INT_OFF
	call   ds:[DMADriver]           ; call DMA driver

	INT_ON

;-------------------------
;	Fehler ?
;-------------------------

	tst     dl                      ; did we get it?
	jnz     error

;-------------------------
;	DMA Halt
;-------------------------

	mov     dl, dh                  ; dl <- channel of transfer
	mov     di, DR_DISABLE_DMA_REQUESTS
	INT_OFF
	call   ds:[DMADriver]           ; turn off requests to chip

	INT_ON

;--------------------------------------
;	AutoINIT-DMA??? initialisieren
;--------------------------------------
	;
	;  Try to set up an auto-init transfer of the
	;       entire buffer.  If it fails, we
	;       just return carry set.
	pop     ax                      ; restore size of stream [1]

	mov     si, 0      		; bx:si <- buffer to DMA

;-----------------------
; Adresse,LÑnge --> DMA
;-----------------------
stevor:
	dec     ax                      ; transfer size -1
	push	ax			; fÅr PrÅfung retten
	mov     cx, ax                  ; cx <- size of buffer
	mov     dx, ds:[baseDMAChannel]  ; dl <- channel #
	mov     dh, ModeRegisterMask <DMATM_SINGLE_TRANSFER,0,1,DMATD_WRITE>
	mov     di, DR_START_DMA_TRANSFER

	INT_OFF

	call   ds:[DMADriver]           ; set up transfer

        INT_ON
;-----------------------
;	PrÅfung
;-----------------------
	pop	ax			; Sollaenge
        cmp	ax,cx			; Istlaenge = Sollaenge ?
	jnz	nokorlen		; nein, Rueckkorrektur nicht
					; durchfuheren !
                                        ; DMA-Treiber liefert bei Nichtein-
                                        ; haltung der Laenge nicht L-1 son-
                                        ; dern L zurueck. L nur korrigieren,
                                        ; wenn angeforderte Laenge zurueck-
                                        ; gegeben wurde.
        inc	cx			; DMA benutzt fÅr LÑnge l-1
nokorlen:
	mov	ds:[bufferLen],cx	; neue LÑnge abspeichern

;-----------------------
; 	DMA enable'n
;-----------------------

	mov     cx, ds:[baseDMAChannel]
	mov     dl, 1
	shl     dl, cl
	mov     di, DR_ENABLE_DMA_REQUESTS

	INT_OFF

	call   ds:[DMADriver]

	INT_ON                          ; turn off request to chip

	clc                             ; clear carry flag
done:
	.leave
	ret

;----------------------
;	FEHLER
;----------------------
error:
	pop     dx                      ; clean up stack [1]
	stc
	jmp     short done
RecProgramDMADriver	endp



LoadableCode            ends
