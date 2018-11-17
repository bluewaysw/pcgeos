COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Treiber

DATEI:		bswav.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	29.08.98	Init
        DL	02.03.2000	Speakerausgaberoutinen entfernt
	DL	02.03.2000	Ableitung SB16
	DL	25.10.2000	Translations for ND

ROUTINEN:
	Name			Description
	----			-----------
	BSSecondAlloc		Allocate Secondarybuffer
	BSSecondUnlock		Unlock Secondarybuffer
	BSSecondWrite		Fill Secondarybuffer
	BSDMAGrenzen		check DMA-Segment

*****************************************************************@

idata           segment

	bufferHandle		word	0h	; Handle to internal Streambuffer
	bufferSegment		word	0h	; Address Secondarybuffer
	bufferLen		word	2h	; Buffersize
	bufferO2		word	0h	; Bufferhalf
	bufferP2		word	0h	; Copypointer
	bufferFree		word	0h	; free Buffer
	bufferMax		word	1h	; Endoffset Buffer
	bufferState		byte	0h	; 1 = lower half
	dacStatus		byte	0h	; 0 = ready
						; 1 = AI fill lower half
						; 2 = fill upper half
						; 3 = Single cycle (End)
	endeFlag		byte	0h	; 1 Ending PLAY

	blockISR		byte	0h	; for Debugging
	stackHandle		word	0	; MemHandle for ISR-Stack
	DSPVersion		word	0h	; DSP Version
	hsFlag			byte	0h	; 1 = Highspeedmode
	bsInterleave		byte	1h	; every X. Byte will be copied
	singleCommand		byte	14h	; DSP Commando Singletransfer
	stopCommand		byte	0dah	; Stop AI
	tempDMAChannel		word	0h
	highDMAChannel		word	5h

idata           ends

LoadableCode    segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSPrepareMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Interprete DSP Helpcode

called by:	SBDDACSetSample

IN:		[sampleRate]
		[DSPFormatCommand]

OUT:		CF=1 Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	22.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSPrepareMode proc    far
	uses    ax,bx,cx,dx		;PUSH ax, ...
	.enter

	clr	ds:[hsFlag]
	mov	ds:[bsInterleave],1

;-----------------------
; detect Helpcode
;-----------------------
	mov	al,ds:[DSPFormatCommand]
	cmp	al,7fh			; Bit 7 ?
	jbe	done

	mov	bx,ds:[DSPVersion]	; Version for later
;
; In this version only SB mono capabilities
;
	mov	bx,200h
	mov	dx,ds:[sampleRate]	; Rate for later
	cmp	al,81h			; 8 Bit mono ?
	jne	done			; no

;-----------------------
;	8 Bit MONO
;-----------------------
	mov	ah,DSP_DMA_PCM_AI_MONO_LOW	; (1ch)
	mov	cl,DSP_DMA_PCM_MODE	; Singlecycle
	mov	ch,DSP_EXIT_AUTOINIT	; Exit
	cmp	dx,23000		; Highspeed ?
	jb	setDSPCommand		; no

	; Highspeed mono

	cmp	bx,200h			; Version < 2.01 ?
	ja	mv201			; no
	;
	; DSP 2.00
	;
	shr	dx,1			; yes, Samprate/2
	mov	ds:[sampleRate],dx	; store rate
	mov	al,2
        mov	ds:[bsInterleave],al	; Interleave = 2
	jmp	setDSPCommand		; End

mv201:
	mov	cl,DSP_DMA_HIGH_SPEED	; Singlecycle
	mov	ch,0			; Stop = Reset

	cmp	bh,3			; Version > 3.xx ?
	ja	progRate		; yes, programming Samplerate

	;
	; DSP 2.00...3.XX
	;
	mov	ds:[hsFlag],1
	mov	ah,DSP_DMA_PCM_AI_MONO_HIGH
	mov	cl,DSP_DMA_HIGH_SPEED	; Singlecycle
	mov	ch,0			; Stop = Reset
	jmp	setDSPCommand		; End

;-----------------------
; Samplerate for 4.XX
;-----------------------
progRate:
	SBDDACWriteDSP	DSP_SET_SAMPLE_RATE,0
	mov	cx,dx
	SBDDACWriteDSP	ch,0
	SBDDACWriteDSP	cl,0
	mov	cl,DSP_EXIT_AUTOINIT
	mov	ch,ah
	jmp	setDSPCommand		; Ende

;-----------------------
;  Store DSPCommand
;-----------------------
setDSPCommand:
	mov	ds:[singleCommand],cl
	mov	ds:[stopCommand],ch
	mov	ds:[DSPFormatCommand],ah
	jmp	done

;-----------------
;	END
;-----------------
done:
	.leave
	ret

BSPrepareMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSecondAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Secondary Buffer belegen

called by:	AttachToStream

IN:		cx = LÑnge

OUT:		CF=1 Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSecondAlloc proc    far
	uses    ax,cx		;PUSH ax, ...
	.enter
;	WARNING	BS_SECOND_LOCK
;--------------------
;	START
;--------------------

	call	BSECInit

;----------------------------
; Buffer already allocated ?
;----------------------------
	tst	ds:[bufferHandle]	; Handle to block allocated
					; Handle = 0 ?
	jne	done			; no, End

;----------------------
; 	Allocate Buffer
;----------------------
	mov	ax,cx			; size
	mov	ds:[bufferLen],ax	; store
	mov	cl,mask HF_FIXED	; HeapFlags
	mov	ch,mask HAF_ZERO_INIT	; HeapAllocFlags
	call	MemAlloc
	jc	error			; Fehler !

	mov	ds:[bufferHandle],bx	; Handle to block allocated
	mov	ds:[bufferSegment],ax	; Address of block allocated

	call	BSFillRest		; Clear buffer
	call	BSCreateStack		; Allocate Stack for ISR

;-----------------------
;   Prepare DMA
;-----------------------
	mov	bx,ax			; Bufferaddress
	mov	dx,ds:[bufferLen]	; size

	call	BSDMAGrenzen		; check DMA-Segment
	mov	ds:[bufferSegment],bx	; corrected segment address

        mov	cx,0			; Mode = Play
	call	ProgramDMADriver	; prepare DMA

;-----------------------
; Calculate Buffervalues
;-----------------------
	mov	ax,ds:[bufferLen]	; size
	mov	ds:[bufferFree],ax
	mov	ds:[bufferMax],ax
	clr	ds:[dacStatus]
	clr	ds:[bufferP2]		; Start Buffer
	shr	ax			; /2
	mov	ds:[bufferO2],ax	; Bufferhalf

;--------------------
;	OK-End
;--------------------
done:
	clc                             ; CF=0 OK
	jmp     short exit

;--------------------
;    Error END
;--------------------
error:
	stc				; CF=1 Error !

exit:
	.leave				; POP ax, ...
	ret

BSSecondAlloc endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSDMAGrenzen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       PrÅft Segmentgrenzen und korrigiert ggf. Einstellungen

called by:	BSSecondAlloc

IN:		bx = Segment
		dx = LÑnge

OUT:		bx = neues Segment
		dx = neue LÑnge

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init

- Wenn 64K-Segmentgrenze Åberschritten wird, den grî·eren Teil
  als Puffer definieren !
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSDMAGrenzen proc    near
	uses    ax,cx			;PUSH ax, ...
	.enter

;--------------------
;	START
;--------------------
        mov	ax,bx			; Segmentadresse
	and	ax,0fffh		; 64K Bereich ausblenden
        mov	cl,4
	shl	ax,cl			; Offset in 64K Bereich
        add	ax,dx			; Pruefung Grenzueberschreitung
	jnc	noproblem		; bestanden !

;--------------------
;   Problemloesung
;--------------------
	mov	cx,ax			; Laenge hinter 64K (Restlaenge)
        mov	ax,dx			; ax = Sollaenge
        shr	ax			; ax = halbe Laenge
        cmp	ax,cx			; Restlaenge mehr als Haelfte ?
        jb	hintseg			; ja
        sub	dx,cx
	jmp short noproblem1		; nein, Rest reicht

;--------------------
; Bereich hinter Seg-
; mentueberschreitung
; als Secondbuffer !
;--------------------
hintseg:
        mov	ax,dx			; alte Laenge
	sub	ax,cx			; toter Bereich
        mov	cl,4
        shr	ax,cl			; Offset-->Segment
        inc	ax			; Sicherheit
        add	bx,ax			; neue Segmentadresse
        shl	ax,cl			; Seg-->Offs (verlorengegange Bytes)
        sub	dx,ax			; abziehen

noproblem1:
;--------------------
;	ENDE
;--------------------
noproblem:
	.leave				; POP ax, ...
	ret

BSDMAGrenzen endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSetSamplerate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Vorbereitende Berechnungen

called by:	SBDDACSetSample

IN:		dx	Samplerate

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	03.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSetSamplerate proc    far
	uses    ax,cx,dx		;PUSH ax, ...
	.enter

;--------------------
;	INT
;--------------------
	call	BSGetDSPVersion		; DSP Version holen

;--------------------
;	ENDE
;--------------------
	clc
	.leave				; POP ax, ...
	ret

BSSetSamplerate endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSGetDSPVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       DSP Version ermitteln

called by:	?

IN:		ds	dgroup

OUT:		[DSPVersion]

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	22.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSGetDSPVersion proc    far
	uses    ax,bx,dx		; PUSH ax, ...
	.enter

;	WARNING	GET_DSP_VERSION

	SBDDACWriteDSP	DSP_GET_VERSION,0
        SBDDACReadDSP	0		; al = RÅckgabe von DSP
        mov	bh,al
        SBDDACReadDSP	0		; al = RÅckgabe von DSP
        mov	bl,al
	mov	ds:[DSPVersion],bx	; Version abspeichern

;--------------------
;	ENDE
;--------------------

	.leave				; POP ax, ...
	ret

BSGetDSPVersion endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSingletransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Singlecycletransfer starten

called by:	DettachFromStream

IN:		cx	Anzahl Bytes

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	02.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSingletransfer proc    near
	uses    ax,bx,cx,dx		;PUSH ax, ...
	.enter
;	WARNING	BS_SINGLE_START
	clr	ds:[hsFlag]

;-----------------------------
; DSP Befehl fuer Singlecycle
; berechnen
;-----------------------------
        mov	bl,DSP_DMA_PCM_MODE	; Single mono
	mov	al,ds:[DSPFormatCommand]; AI Befehl holen
	cmp	al,1ch			; AI mono ?
	jz	single			; ja
        ;
        ; vorbereiteten Singletransfercode
        ; auslesen
        ;
        mov	bl,ds:[singleCommand]	; Code gueltig ?
        jz	done			; nein, unbekannt

;--------------------
; DSP aus AI rausholen
;--------------------
;	SBDDACWriteDSP	DSP_EXIT_AUTOINIT,0
        tst	cx			; noch was zu spielen ?
        jz	setstate		; nein

;--------------------
; DSP programmieren
;--------------------
single:
	SBDDACWriteDSP  bl, 0
        dec	cx			; Laenge -1
	SBDDACWriteDSP  cl, 0
	SBDDACWriteDSP  ch, 0

	mov	cl,3			; Status
setstate:
        mov	ds:[dacStatus],cl	; Endestatus setzen

;--------------------
;	ENDE
;--------------------
done:
	.leave				; POP ax, ...
	ret

BSSingletransfer endp

LoadableCode            ends

ResidentCode            segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSecondWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Streamdaten in Secondarybuffer schreiben
		Startet Autoinit wenn Puffer voll ist

called by:	Notificationroutine

IN:		cx	Bytes to write
		si	Offset Stream

OUT:		cx	geschriebene Bytes

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init
        DL	22.09.98	Beruecksichtigung Interleave

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSecondWrite proc    far
	uses    ax,bx,dx,es,di,ds
	.enter
        call    SysEnterInterrupt		; LA 15.09.98

;--------------------
; Secondbuffer OK ?
;--------------------
        tst	ds:[bufferHandle]		; Secondbuffer vorhanden ?
	jz	ende				; nein, nichts machen
	push	ds				; Stack [1]

;-------------------
; Interleave holen
;-------------------
        mov	bx,cx				; bx = Bytes
        mov	ax,cx				; ax = Bytes
	mov	cl,ds:[bsInterleave]		; cl
        dec	cl
	mov	dl,cl				; dl = interleave
	shr	ax,cl				; verfÅgbare Daten korrig.
        mov	cx,ax				; cx = Bytes to copy

;--------------------
; LÑnge ggf. korr.
;--------------------
	mov	ax,ds:[bufferFree]
        cmp	ax,cx				; weniger frei als gefordert ?
        jnc	genug				; nein, LÑnge ist OK
	mov	cx,ax				; MaxlÑnge
genug:
	sub	ds:[bufferFree],cx		; freier Speicher - LÑnge
        mov	ax,cx
        mov	cl,dl				; Interleave
        shl	ax,cl				; Quellbytes berechnen
        mov	cx,ax				; cx = Bytes to copy
	push	cx				; Stack [2] LÑnge

;-------------------------
; Zeiger auf Secondbuffer
;-------------------------
        mov	di,ds:[bufferP2]		; Startoffset
	mov	ax,ds:[bufferSegment]
        mov	es,ax
        mov	bx,ds:[bufferLen]		; max Offset

;------------------------
; Zeiger auf Streamdaten
;------------------------
        mov	ax, ds:[streamSegment]		; Zeiger auf Stream
        mov	ds,ax				; Segment Quelle
        mov	al,dl				; al = Interleave
        inc	al				; zurueckkorrigieren
	mov     dx, ds:[SD_max]			; dx = ptr-Max

;-------------------
; Zaehler auf NULL ?
;-------------------
	tst	cx				; Puffer voll ?
        jz	done				; ja ! nicht kopieren

;----------------
; Offsets prÅfen
;----------------
testoffs:
	cmp	di, bx				; Zieloffset zu gro· ?
        jb	copybyte2			; nein
        sub	di, bx				; zurÅck an Anfang

copybyte2:
        cmp     si,dx				; Streamende ?
	jb	copybyte			; nein
        ;
        ;  We wrapped the pointer.  Subtract the max value
        ;       and add to starting value.
        ;
        sub     si, dx				; cx <- # past end
        add     si, offset SD_data              ; cx <- # past beginning

;-------------------
;	Transfer
;-------------------
copybyte:
	mov	ah,ds:[si]
	mov	es:[di],ah			; es:[di] := ds:[si]

        inc	di

        clr	ah
        add	si,ax				; SI + Interleave

	sub	cx,ax
        ja	testoffs			; nÑchstes Byte

;--------------------
;   Kopieren ENDE
;--------------------
done:
        pop	cx			; Stack [2]
        pop	ds			; Stack [1]
        mov	ds:[bufferP2],di	; Pufferzeiger speichern

;--------------------
; AutoInit starten
;--------------------
	tst	ds:[dacStatus]		; DAC noch wartend ?
        jne	fertig			; nein, Ende

        mov	ax,ds:[bufferFree]
        tst	ax			; Puffer voll ?
        jne	fertig			; nein

;-----------------------
;	AI
; hier Autoinit starten
; cx nicht Ñndern !!!
;-----------------------
	call	BSAutoInitStart
	jmp 	short ende

;-------------------------------
; NO_INT: Secondarybuffer leeren
;-------------------------------
fertig:

ifdef BS_NO_INT
	call	BSDACISR
endif

;-----------------
;	ENDE
;-----------------
ende:
        call    SysExitInterrupt	; LA 15.09.98
	.leave				; POP ax, ...

;	clr	ds:[blockISR]		; LA 10.09.98
	ret

BSSecondWrite endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSAutoInitStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Startet Autoinit bzw. Bearbeitung Daten im Secondarybuffer

called by:	BSSecondWrite

IN:		-

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	30.08.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSAutoInitStart proc    near
	uses    ax,cx,dx		;PUSH ax, ...

;	WARNING	BS_AI_START

	.enter

;--------------------
;   Status setzen
;--------------------
        mov	al,1
        mov	ds:[dacStatus],al	; Startstatus

	clr	ds:[bufferP2]		; LA 15.09.98
        mov	ax,ds:[bufferLen]
        clr	ds:[bufferFree]

;--------------------
;	NO_INT
;--------------------
ifdef BS_NO_INT

;	call	BSDACISR			; so tun als ob Interrupt
        				; ausgelîst wurde
endif

;--------------------
;	INT
;--------------------
        mov	cx,ds:[bufferO2]	; halbe Secondbufferlaenge
        dec	cx
	SBDDACWriteDSP  DSP_SET_BLOCK_SIZE, 0	; Blocklaenge
	SBDDACWriteDSP  cl, 0			; L Byte
	SBDDACWriteDSP  ch, 0			; H Byte

;--------------------
;  Transfer starten
;--------------------
	mov	cl,ds:[DSPFormatCommand]	; AI Befehl holen
	SBDDACWriteDSP  cl, 0		; abschicken

;--------------------
;	ENDE
;--------------------

	.leave				; POP ax, ...
	ret

BSAutoInitStart endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSDACISR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Zusatzcode fÅr Interruptservice

called by:	ISR

IN:		-

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	30.08.98	Init
        DL	02.09.98	endeFlag

- bufferFree + bufferO2
- bufferFree=bufferLen  --> dacStatus = 3
- dacStatus = 1 	--> (DSP spielt gerade zweite HÑlfte ab)
		    	    bufferP2  = 0
                    	    dacStatus = 2
- dacStatus = 2 	--> (DSP spielt gerade erste HÑlfte ab)
		    	    bufferP2  = bufferO2
                    	    dacStatus = 1
- dacStatus = 3		--> Singlecycle programmieren

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSDACISR proc    far
	uses    ax,bx,cx,dx,es,ds,si,di	;PUSH ax, ... LA 15.09.98
	.enter
ifdef	BS_SWAT_WARNING

	WARNING	BS_ISR
endif

;------------------------
; blockISR (fuer debug)
;------------------------
	tst	ds:[blockISR]		; ISR blockiert ?
;       jnz     fertig			; ja
        mov	al,1
        mov	ds:[blockISR],al	; blockieren

;------------------------
; Notbehandlung wenn
; streamStatus = 0
;------------------------
	tst	ds:[streamState]	; Status gesetzt ?
        jnz	testdac			; ja, OK

        call	MyBreak
	SBDDACWriteDSP	DSP_DMA_HALT,0	; DSP stoppen
	jmp     fertig			; fertig

;------------------------
; 	dacStatus testen
;------------------------
testdac:
        mov	al,ds:[dacStatus]
        cmp	al,0			; in Ruhe ?
        jz      fertig			; ja, nichts machen
	cmp	al,3			; dacStatus = Singletransfer ?
        jnz	secondbuftest		; nein

;------------------------
; dacStatus war Singletr.
;
; Stream wurde geleert (letzter Transfer war Singlecycle)
; solange endeFlag nicht gesetzt ist, kann Ausgabe wieder
; gestartet werden indem Stream wieder gefÅllt wird !
;------------------------
	call	MyBreak
	clr	ds:[dacStatus]		; Status = 0
;	clr	ds:[bufferP2]		; LA 10.08.98

        jmp	fertig

;------------------------
; Secondarybuffer leer ?
;------------------------
secondbuftest:
	mov	cx,ds:[bufferO2]	; PufferhÑlfte
	mov	ax,ds:[bufferFree]	; freier Puffer
	add	ax,cx			; eine HÑlfte ist wieder frei !
        mov	ds:[bufferFree],ax	; PufferhÑlfte freigeben
        mov	dx,ds:[bufferLen]
        mov	bx,dx			; bx = Laenge (fuer spaeter)

        sub	ax,cx			; Puffer geleert ?
        jbe	swapdacstate		; nein

;--------------------
;  Ausgabe beenden
;
; Rest der Pufferhaelfte
; mit Stummwert (80h)
; fuellen
;--------------------
        mov	ds:[bufferFree],dx	; max. Len frei !
        mov	cx,ax			; Restlaenge
	mov	al,3			; Status = 3
        mov	ds:[dacStatus],al	; speichern

        call	BSFillRest		; Rest mit Stummwert lîschen

;------------------
;   DSP anhalten
;------------------

	tst	ds:[hsFlag]		; Highspeed ?
        jz	exitlow			; nein
        call    SBDInitChipDSP		; RESET beendet Highspeed AI
	clr	ds:[hsFlag]		; Highspeedflag resetten
        clr	ds:[dacStatus]
        call	MyBreak
        jmp	deblock			; fertig
        ;
	; normaler Transfer
        ;
exitlow:
	SBDDACWriteDSP	DSP_EXIT_AUTOINIT,0
        ;
deblock:
	clr	ds:[blockISR]		; nÑchsten ISR deblockieren
        jmp	fertig

;--------------------
; dacStatus swappen
;--------------------
swapdacstate:
	mov	dx,0			; bufferP2 bei Status = 1
        mov	al,ds:[dacStatus]
        xor	al,3			; Status swappen 1-->2 bzw. 2-->1
        mov	ds:[dacStatus],al	; speichern
        cmp	al,1			; alter Status 2 ?
        jne	stateold2		; nein
        mov	dx,cx			; bufferP2 = 0 bei Status 2

stateold2:

	mov	ds:[bufferP2],dx	; Startzeiger fÅr nÑchsten Transfer
	mov	ax,ds:[bufferP2]	; Startzeiger fÅr nÑchsten Transfer
        sub	ax,bx
        jb	fertig			; Zeiger am Ende ?

	mov	ds:[bufferP2],ax	; korrigierter Zeiger

;----------------
; 	ENDE
;----------------
fertig:

	.leave				; POP ax, ...
	ret

BSDACISR endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSFillRest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Rest loeschen

called by:	?

IN:		cx	Anzahl Bytes
		(glob)	bsRecBits

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	08.09.98	Init
        DL	04.01.2000	Value for fill depends from bsRecBits

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSFillRest	proc far
	uses    ax,cx,dx,es,si		;PUSH ax, ...
	.enter

EC<	WARNING	BS_FILL_REST>

;-------------------
; define fill value
;-------------------

        mov	al,80h			; fillvalue 8 Bit
	mov	ah,ds:[bsRecBits]
        cmp	ah,16			; 16 Bit ?
        jnz	fill			; no
        mov	al,0			; yes

	;
        ; cx = Anzahl Bytes
        ;
fill:
        mov	es,ds:[bufferSegment]
        mov	si,ds:[bufferP2]
        mov	dx,ds:[bufferLen]	; Grenze
        tst	cx			; Laenge = 0 ?
        jz	fertig			; ja, fertig
stumm:
	cmp	si,dx			; si < bufferLen ?
        jae	fertig			; nein, fertig
        mov	es:[si],al
        inc	si
        dec	cx
        jnz	stumm
fertig:
        .leave
        ret

BSFillRest	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSecondUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       Speicher fÅr Secondarybuffer freigeben
		DMA stoppen (wenn nîtig)

called by:	Routine die den Transfer beendet

IN:		-

OUT:
		bufferHandle = 0
                bufferSegment= 0
                bufferLen    = 0


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init
        DL	07.09.98	bufferSegment,-Len werden nicht resettet

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSecondUnlock proc    far
	uses    ax,cx			;PUSH ax, ...
	.enter

;	WARNING	BS_SECOND_UNLOCK

;--------------------
;	aktiv ?
;--------------------
	mov	ax,ds:[bufferHandle]	; Handle to block allocated
        mov	bx,ax
        tst	ax			; Handle = 0 ?
        jz	done			; ja, Ende

;----------------------------
;	DMA Stop
;----------------------------
	push	bx			; Stack[1] = bx

;-----------------
; DSP DMA Stop
;-----------------
        mov	bh,DSP_EXIT_AI8
	mov	al,ds:[bsRecBits]
	cmp	al,16				; 16 Bit
	jnz	exitdsp			; nein
        mov	bh,DSP_EXIT_AI16
exitdsp:
	SBDDACWriteDSP	bh,0	; der eigentliche Befehl zum Beenden

        mov	ax,30
        call	TimerSleep

;---------------------
;	DMA disable'n
;---------------------
	mov     cx, ds:[baseDMAChannel]  ; cx <- channel for transfer
	mov     dl, 1
	shl     dl, cl                  ; dl <- mask for channel

	mov     di, DR_DISABLE_DMA_REQUESTS

	INT_OFF
	call    ds:[DMADriver]                  ; mask out the channel
        INT_ON

	;
	;  Also, we tell the DMA chip to
	;       stop the transfer and finally
	;       we release the channel

;-------------------
;	DMA stoppen
;-------------------

	mov     dx, ds:[baseDMAChannel]         ; dl <- channel
	mov     di, DR_STOP_DMA_TRANSFER
	INT_OFF
	call    ds:[DMADriver]                  ; stop the DMA transfer
        INT_ON
	mov     cx, ds:[baseDMAChannel]
	mov     dl, 1
	shl     dl, cl
	mov     di, DR_RELEASE_CHANNEL
	INT_OFF
	call    ds:[DMADriver]
        INT_ON

	pop	bx			; bx = Stack[1]

;----------------------------
; Secondarybuffer freigeben
;----------------------------
	call	MemFree			; Speicher freigeben
        clr	ds:[bufferHandle]

;--------------------
; ISR-Stack freigeben
;--------------------
	call	BSFreeStack

;--------------------
;	ENDE
;--------------------
done:
        mov	ds:[bsRecBits],8	; 16 Bit-Kennung loeschen
        mov	ax,ds:[tempDMAChannel]
        mov	ds:[baseDMAChannel],ax	; aktueller DMA-Channel
					; wiederhergestellt
	.leave				; POP ax, ...
	ret

BSSecondUnlock endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSECInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       EC PrÅfung vorbereiten

called by:       ?

IN:             -

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	17.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSECInit proc    far

	.enter

;-----------------------
;	DS abspeichern
;-----------------------
	mov     cs:[BS_ECListDS],ds	; Datensegment speichern

        .leave
	ret

BSECInit endp

BS_ECListDS	word	0			; DS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSECTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       EC PrÅfung

called by:       ?

IN:             -

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	17.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSECTest proc    far
	uses	ax
	.enter

;-----------------------
;	DS testen
;-----------------------
	mov     ax,ds			; Datensegment holen
	cmp	ax,cs:[BS_ECListDS]	; vergleichen
        jnz	error			; Fehler !

;-----------------------
;	SS testen
;-----------------------
	mov	ax,ss
        cmp	ax,00ffh		; Stacksegment zweifelhaft ?
        jbe	error			; ja
        cmp	ax,09f00h		; oberhalb 640k ?
        jb	done			; nein
error:
;EC<	ERROR	BS_EC_TEST_ERROR_DS	>
done:
        .leave
	ret

BSECTest endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSECTestStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Function:       EC PrÅfung

called by:      ?

IN:             ds	dgroup
		bx	Streamsegment

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	22.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSECTestStream proc    far
	uses	ax
	.enter

;-----------------------
;	Stream testen
;-----------------------
	mov	ax,ds:[streamSegment]
        cmp	ax,bx			; Segment gleichgeblieben ?
        jz	done			; ja

	ERROR	BS_EC_TEST_ERROR_STREAM
done:
        .leave
	ret

BSECTestStream endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProgramDMADriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       DMA-Treiber programmieren

CALLED BY:      BSSecondAlloc

PASS:           bx      -> stream segment
		dx      -> buffer size
                cx	-> Modeflag	(2 -> Recording, else Playing)
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
        DL	23.03.2000	16 Bit
        DL	04.11.2000	Recording/Playing (cx)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProgramDMADriver    proc    far
        uses	ax			; 23.03.2000

	.enter
	;
        push	cx			; mode (2 = Record) [2]
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
        mov	ds:[tempDMAChannel],cx
	mov	al,ds:[bsRecBits]
        cmp	al,16			; 16 Bit ?
        jnz	prep
        mov	cx,ds:[highDMAChannel]	; High-DMA-Kanal
        mov	ds:[baseDMAChannel],cx	; aktueller DMA-Channel
prep:
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
	mov     dx, ds:[baseDMAChannel] ; dl <- channel #
        cmp	dl,4			; High-DMA ?
	jb	setsize			; nein
        shr	ax			; High-DMA -> Puffergroesse wird
        				; in "wordsize" uebergeben
setsize:
	mov     dh, ModeRegisterMask <DMATM_SINGLE_TRANSFER,0,1,DMATD_READ>
        pop	cx			; [2]
        cmp	cx,2			; Recording ?
        jnz	norec			; nein
	mov     dh, ModeRegisterMask <DMATM_SINGLE_TRANSFER,0,1,DMATD_WRITE>
norec:
	dec     ax                      ; transfer size -1
	push	ax			; fÅr PrÅfung retten
	mov     cx, ax                  ; cx <- size of buffer
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
	cmp	dl,4			; High-DMA ? (Word)
        jb	setlen			; nein, cx enthÑlt size in Bytes
	shl	cx			; High-DMA -> Umrechnung "wordsize"
        				; in "bytesize"
setlen:
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
	pop	cx			; clean up stack [2] [1]
	pop     dx
	stc
	jmp     short done
ProgramDMADriver	endp

ResidentCode            ends

