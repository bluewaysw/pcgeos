COMMENT @********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Template

DATEI:		bsstream.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init

ROUTINEN:
	Name			Description
	----			-----------
	SBDDACReadNotification	Notificationroutine
        BSDischargeStream	Stream um cx Bytes entladen


Beschreibung:
	Template zum Erstellen von Soundtreibern.

*****************************************************************@


ResidentCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACReadNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification reciepiant routine

CALLED BY:	Stream Driver
PASS:		cx	-> # of bytes to read
		dx	-> stream token (virtual segment)
		bx	-> stream segment

RETURN:		nothing

DESTROYED:	ax, cx (allowed ax, bx, si, di)

SIDE EFFECTS:
		Sets up parameters for next interrupt transfer

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        DL	09.08.98	Template

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACReadNotification	proc	far
	pushf
	uses	cx, dx, ds, es			; LA 15.09.98
;	uses	ax, cx, dx, ds, es, si, di, bx
	.enter

	mov	ax, segment dgroup		; ax <- dgroup of driver
	mov	ds, ax				; ds <- dgroup of driver

;----------------------------
; Erkennung Streamdaten (cx)
;----------------------------
	tst	cx				; cx=0 ThresholdÑnderung ?
	jz	sendAck				; ja

;----------------------------------------
;	Stream enthÑlt Daten zum Senden
;----------------------------------------
streamsz:
	mov	ds:[dataOnStream], cx		; Anzahl Bytes abspeichern

	mov	ax, ds:[streamSize]		; ax <- upper limit on size

	cmp	ax, cx				; mehr Daten als Stream lang ?
						; (VERBOTEN !)
	jb	sendAck                 	; nein

;==============================
;	Stream entladen
;
; An dieser Stelle mÅssen die
; Daten aus dem Stream gelesen
; werden
;
;	cx = Anzahl Bytes
;==============================
	call	BSECTestStream		; Stream testen

	call	BSDischargeStream
        sub	ds:[dataOnStream],cx	; Streamdaten aktual.
	mov	ax,ds:[dataOnStream]
        mov	cx,ax
        tst	ax			; noch Daten drin ?
        jnz	streamsz		; ja, warten bis Stream leer ist

;----------------------------
; 	ACK an Reader senden
;----------------------------
sendAck:
	mov	ds, bx				; ds <- stream segment

	;
	;  We want to be notified of every write done by the writer.
	;  But each time this routine gets called, the driver sets
	;  flags that prevent a notification from being sent until
	;  we act on the previous notification.  That is, until we
	;  read something.  To deal with this little problem
	;  we send our own "acknowledgment" by fiddling with the
	;  stream settings.
	;
	;  Send and "ack"
	;  Reset the reader state.

	clr	ds:[SD_reader.SSD_data].SN_ack
	and	ds:[SD_state], not mask SS_RDATA

done::
	.leave

        popf			; restore flags
	ret

SBDDACReadNotification	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSDischargeStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stream "entladen"

CALLED BY:
PASS:		cx	-> # of bytes to read
		bx	-> stream segment ??? La 28.08.98

RETURN:		cx	= gelesene Bytes

DESTROYED:

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        DL	09.08.98	Template
        DL	30.09.98	Secondarybuffer
        DL	01.09.98	wartet bis cx gelesen wurde

ToDo-List:
----------
- Timeout

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSDischargeStream proc far
        uses    ax, bx, dx, ds, si, di, es
	.enter
;	INT_ON				; LA 10.09.98

ifdef	BS_SWAT_WARNING
	WARNING	BS_DISCHARGE
endif
	call	BSECTest

;-------------------------------
;	verfÅgbare Daten testen
;-------------------------------
        mov	ax,ds:[dataOnStream]	; Daten im Stream
	cmp     cx, ax   		; genug Daten vorhanden ?
	jnc	genug			; ja
        mov	cx,ax			; nein, max. moeglich

;---------------------------------
; Daten zum Secondbuffer kopieren
; und warten bis alle Daten abge-
; nommen werden.
;---------------------------------
genug:
        mov	bx,60			; max. 60 Versuche
        push	es
        mov	ax,ds:[streamSegment]	; Offset Stream
        mov	es,ax
	mov     si,es:[SD_reader].SSD_ptr
        pop	es

	mov	dx,cx			; dx = Anzahl
        mov	ax,cx			; ax = Startanzahl
nochmal:
        tst	ds:[bufferFree]		; Puffer noch leer ?
        jz	warten			; ja, warten

        mov	cx,ax
        call	BSSecondWrite		; Daten --> Secondbuffer
	call	BSECTest
        				; cx = gelesene Bytes
        sub	ax,cx			; alles gelesen ?
        jz	fertig			; ja
warten:
        push	ax
        mov	ax,1
	call	TimerSleep		; LA 17.09.98
        pop	ax

ifdef	BS_NO_INT
	call	BSDACISR
        mov	ax,2
	call	TimerSleep		; LA 17.09.98
endif
	dec	bx			; Versuche ausgeschoepft
        jnz 	nochmal			; nein, nochmal

;---------------------------------
; 60 Versuche haben nicht
; gereicht Stream zu entladen
; Vermutlich wurde Abspielvorgang
; unterbrochen und die BSDACISR hat
; dacStatus auf Null gesetzt.
;---------------------------------
        tst	ds:[dacStatus]		; DSP in Ruhe ?

        jnz	fertig			; nein, Problem ignorieren

        				; LA: BEARBEITUNGSWUERDIG !!!

	call	BSAutoInitStart		; Transfer neu starten
        jmp	short genug

;--------------------------------
;     Kopieren abgeschlossen
;--------------------------------
fertig:
        mov	cx,dx			; Anzahl zurÅck
        mov	bx,ds:[streamSegment]	; bx Zeiger auf Streamstruktur

	push	cx			; Stack [1] cx

;--------------------------------
;	Stream aktualisieren
;--------------------------------

; updateStream label near
        push    es                      ; Stack [2] es

        mov     es, ds:[streamSegment]

        ;
        ;  Update semaphores for reader and writer
        ;
;---------------------------
; Semaphoren aktualisieren
;---------------------------

        sub     es:[SD_reader.SSD_sem].Sem_value, cx	; Bytes die gelesen werden mÅssen
        add     es:[SD_writer.SSD_sem].Sem_value, cx	; freie Bytes im Stream

;-----------------------------
;  Pointer fÅr Reader aktual.
;-----------------------------
	add     cx, es:[SD_reader].SSD_ptr
	cmp     cx, es:[SD_max]

;	jbe	writeReaderPtr			; LA 04.09.98
	jb	writeReaderPtr			; LA 04.09.98

        ;
        ;  We wrapped the pointer.  Subtract the max value
        ;       and add to starting value.
        ;
        sub     cx, es:[SD_max]                 ; cx <- # past end
        add     cx, offset SD_data              ; cx <- # past beginning

;---------------------------
; Readerpointer setzen (cx)
;---------------------------

writeReaderPtr:
	mov     es:[SD_reader].SSD_ptr, cx

	mov     cx, di                                  ; save trashed reg.

        ;
        ;  We are now going to call the stream driver to
        ;       handle updating the stream.  This can
        ;       and does enable interrupts, so we need to
        ;       make sure we don't context switch.
        ;  Call SysEnterInterrupt to deal with this.

;-------------------------------------------
; neue Daten in Stream schreiben lassen
;
;- Contextswitching verbieten
;- Writer freigeben
;- INT sperren
;- Contextswitching erlauben
;-------------------------------------------

        call    SysEnterInterrupt

        call    StreamWriteDataNotify   		; destroys ax, di

        mov     di, cx                                  ; restore trashed reg.

        tst     es:[SD_reader.SSD_sem].Sem_queue
        jz      sendACK

;-------------------------------
; Writersemaphore de-blockieren
;-------------------------------

        ;
        ;  Since there is a writer blocked on writing,
        ;       we need to free it up so it can write.
        mov     cx, bx                                  ; save trashed reg.

        mov     ax, es                                  ; ax:bx <- queue
        mov     bx, offset SD_reader.SSD_sem.Sem_queue
        call    ThreadWakeUpQueue

        INT_OFF			; LA 17.09.98

        mov     bx, cx                                  ; restore trashed reg.

sendACK:
        pop     es                              ; Stack [2]

        call    SysExitInterrupt

        pop	cx				; Stack [1] cx

        .leave
	ret

BSDischargeStream endp


ResidentCode		ends

