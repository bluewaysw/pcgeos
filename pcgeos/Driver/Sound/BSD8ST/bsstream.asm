COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound

DATEI:		bsstream.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init
        DL	17.08.2000	Translation for ND

ROUTINEN:
	Name			Description
	----			-----------
	SBDDACReadNotification	Notificationroutine
	BSDischargeStream	discharge Stream cx Bytes

*****************************************************************/@


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACReadNotification	proc	far
	pushf
	uses	cx, dx, ds, es			; LA 15.09.98
;	uses	ax, cx, dx, ds, es, si, di, bx
	.enter

	mov	ax, segment dgroup		; ax <- dgroup of driver
	mov	ds, ax				; ds <- dgroup of driver

	tst	cx				; cx=0 ThresholdÑnderung ?
	jz	sendAck				; ja

streamsz:
	mov	ds:[dataOnStream], cx		; store number of bytes

	mov	ax, ds:[streamSize]		; ax <- upper limit on size

	cmp	ax, cx				; more data then Stream long ?
						; (not allowed !)
	jb	sendAck                 	; no

;==============================
;	discharge Stream
;
;	cx = number of bytes
;==============================
	call	BSECTestStream

	call	BSDischargeStream
        sub	ds:[dataOnStream],cx
	mov	ax,ds:[dataOnStream]
        mov	cx,ax
        tst	ax			; data in stream ?
        jnz	streamsz		; yes, wait until stream is empty

;----------------------------
; 	ACK to Reader
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

SYNOPSIS:

CALLED BY:
PASS:		cx	-> # of bytes to read
		bx	-> stream segment ???

RETURN:		cx	= number of bytes

DESTROYED:

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        DL	09.08.98	Template
        DL	30.09.98	Secondarybuffer
        DL	01.09.98	wait until cx bytes was read

ToDo-List:
----------
- Timeout

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSDischargeStream proc far
        uses    ax, bx, dx, ds, si, di, es
	.enter

	call	BSECTest

        mov	ax,ds:[dataOnStream]	; Data in Stream
	cmp     cx, ax   		; enough ?
	jnc	genug			; yes
        mov	cx,ax			; no

;---------------------------------
; Copy data to Secondarybuffer
; and wait until all data was
; accepted
;---------------------------------
genug:
        mov	bx,60			; max. 60 try's
        push	es
        mov	ax,ds:[streamSegment]	; Offset Stream
        mov	es,ax
	mov     si,es:[SD_reader].SSD_ptr
        pop	es

	mov	dx,cx			; dx = size
        mov	ax,cx
nochmal:
        tst	ds:[bufferFree]		; Puffer empty ?
        jz	warten			; yes , wait

        mov	cx,ax
        call	BSSecondWrite		; Dat --> Secondbuffer
	call	BSECTest
        sub	ax,cx			; all readed ?
        jz	fertig			; yes
warten:
        push	ax
        mov	ax,1
	call	TimerSleep
        pop	ax

ifdef	BS_NO_INT
	call	BSDACISR
        mov	ax,2
	call	TimerSleep
endif
	dec	bx
        jnz 	nochmal

;---------------------------------
; Timeout
;---------------------------------
        tst	ds:[dacStatus]		; DSP idle ?

        jnz	fertig			; no, ignore Problem

	call	BSAutoInitStart		; Start new Transfer
        jmp	short genug

;--------------------------------
; Copying over
;--------------------------------
fertig:
        mov	cx,dx			; number of bytes
        mov	bx,ds:[streamSegment]

	push	cx			; Stack [1] cx


; updateStream label near
        push    es                      ; Stack [2] es

        mov     es, ds:[streamSegment]

        ;
        ;  Update semaphores for reader and writer
        ;

        sub     es:[SD_reader.SSD_sem].Sem_value, cx	; Bytes die gelesen werden mÅssen
        add     es:[SD_writer.SSD_sem].Sem_value, cx	; freie Bytes im Stream

	add     cx, es:[SD_reader].SSD_ptr
	cmp     cx, es:[SD_max]

	jb	writeReaderPtr			; LA 04.09.98

        ;
        ;  We wrapped the pointer.  Subtract the max value
        ;       and add to starting value.
        ;
        sub     cx, es:[SD_max]                 ; cx <- # past end
        add     cx, offset SD_data              ; cx <- # past beginning


writeReaderPtr:
	mov     es:[SD_reader].SSD_ptr, cx

	mov     cx, di                                  ; save trashed reg.

        ;
        ;  We are now going to call the stream driver to
        ;       handle updating the stream.  This can
        ;       and does enable interrupts, so we need to
        ;       make sure we don't context switch.
        ;  Call SysEnterInterrupt to deal with this.


        call    SysEnterInterrupt

        call    StreamWriteDataNotify   		; destroys ax, di

        mov     di, cx                                  ; restore trashed reg.

        tst     es:[SD_reader.SSD_sem].Sem_queue
        jz      sendACK


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

