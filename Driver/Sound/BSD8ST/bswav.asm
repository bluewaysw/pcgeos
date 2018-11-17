COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound driver

DATEI:		bswav.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	29.08.98	Init
	DL	02.03.2000	Speakerausgaberoutinen entfernt
	DL	16.08.2000	Translation for ND

ROUTINEN:
	Name			Description
	----			-----------
	BSSecondAlloc		Secondarybuffer belegen
	BSSecondUnlock		Secondarybuffer freigeben
	BSSecondWrite		Secondarybuffer fllen
	BSDMAGrenzen		Segmentgrenzen prfen

Beschreibung:
	Additional routines for playing WAV's

*****************************************************************/@

idata           segment

	bufferHandle		word	0h	; Handle Streambuffer
	bufferSegment		word	0h	; segment Secondarybuffer
	bufferLen		word	2h	; buffersize
        bufferO2		word	0h	;
        bufferP2		word	0h	; Copypointer
        bufferFree		word	0h	;
        bufferMax		word	1h	; Endoffset Buffer
        bufferState		byte	0h	; 1 = lower half
	dacStatus		byte	0h	; 0 = ready
        					; 1 = AI fill lower half
                                                ; 2 = fill upper half
                                                ; 3 = Single cycle (End)
        endeFlag		byte	0h	; 1 Play will be ending

        blockISR		byte	0h	; for Debugging
        					; 0 = BSDACISR can do the job
	stackHandle		word	0	; MemHandle for ISR-Stack
	DSPVersion		word	0h	; DSP Version
        hsFlag			byte	0h	; 1 = Highspeedmode
        bsInterleave		byte	1h
	singleCommand		byte	14h	; DSP Command Singletransfer
        stopCommand		byte	0dah

idata           ends

LoadableCode    segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSPrepareMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Interpreter for special DSP commands (80..84)

called by:	SBDDACSetSample

IN:		[sampleRate]
		[DSPFormatCommand]

OUT:		CF=1 Fehler

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	22.09.98	Init
        DL	19.03.2000	Downgrade auf Monowiedergabe

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSPrepareMode proc    far
	uses    ax,bx,cx,dx		;PUSH ax, ...
	.enter

	clr	ds:[hsFlag]
        mov	ds:[bsInterleave],1

;-----------------------
; Zwischencode erkennen
;-----------------------
	mov	al,ds:[DSPFormatCommand]
        cmp	al,7fh			; Bit 7 ?
        jbe	done			; not set, end

;-----------------------
;	8 Bit MONO
;-----------------------
	mov	ah,DSP_DMA_PCM_AI_MONO_LOW	; (1ch)
        mov	cl,DSP_DMA_PCM_MODE	; Singlecycle
        mov	ch,DSP_EXIT_AUTOINIT	; Exit

;-----------------------
;  Store DSPCommand
;-----------------------
setDSPCommand:
	mov	ds:[singleCommand],cl
        mov	ds:[stopCommand],ch
	mov	ds:[DSPFormatCommand],ah
        jmp	done

;-----------------
;	ENDE
;-----------------
done:
	.leave
        ret

BSPrepareMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSecondAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Allocate Secondary Buffer

IN:		cx = size

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

;-----------------------
; Buffer already alloc. ?
;-----------------------
	tst	ds:[bufferHandle]	; Handle to block allocated
					; Handle = 0 ?
        jne	done			; no, End

;----------------------
; Allocate buffer
;----------------------
	mov	ax,cx			; size
        mov	ds:[bufferLen],ax
        mov	cl,mask HF_FIXED	; HeapFlags
        mov	ch,mask HAF_ZERO_INIT	; HeapAllocFlags
	call	MemAlloc
	jc	error

	mov	ds:[bufferHandle],bx	; Handle to block allocated
	mov	ds:[bufferSegment],ax	; Address of block allocated

	call	BSFillRest		; fill buffer with silence
	call	BSCreateStack		; create Stack for ISR

;-----------------------
;	prepare DMA
;-----------------------
	mov	bx,ax			; Bufferaddress
	mov	dx,ds:[bufferLen]	; size

        call	BSDMAGrenzen		; check Segmentborders
	mov	ds:[bufferSegment],bx	; corrected Segmentaddress
	call	ProgramDMADriver	; prepare DMA

;-----------------------
; store buffer params
;-----------------------
        mov	ax,ds:[bufferLen]	; size
        mov	ds:[bufferFree],ax
	mov	ds:[bufferMax],ax	; Offset Bufferend
        clr	ds:[dacStatus]		; dacStatus = waiting
        clr	ds:[bufferP2]		; Start Buffer
        shr	ax			; /2
	mov	ds:[bufferO2],ax	; half buffer

;--------------------
;	OK-End
;--------------------
done:
	clc                             ; CF=0 OK
	jmp     short exit

;--------------------
;    Error-End
;--------------------
error:
	stc				; CF=1 Error !

exit:
	.leave				; POP ax, ...
	ret

BSSecondAlloc endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProgramDMADriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Program DMA-driver

CALLED BY:      BSSecondAlloc
PASS:           bx      -> stream segment
		dx      -> buffer size
		INT_ON

RETURN:         bufferLen -> DMA-buffersize

DESTROYED:      nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	09.11.97	Initial
				(aus SBDDACAttachToStream herausgel”st)
        DL	29.09.98	BestSound Template

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProgramDMADriver    proc    far
	.enter
	;
	push	dx			; stream size [1]
;---------------------------------
;	Allocate DMA-channel
;---------------------------------
	;
	;  Try to request the DMA channel
        ;
        ;
        mov	cx,ds:[baseDMAChannel]	; current DMA-Channel
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

	;
	;  Try to set up an auto-init transfer of the
	;       entire buffer.  If it fails, we
	;       just return carry set.
	pop     ax                      ; restore size of stream [1]

	mov     si, 0      		; bx:si <- buffer to DMA

;-----------------------
; Adress,size --> DMA
;-----------------------
stevor:
	dec     ax                      ; transfer size -1
	push	ax			; save for checking later
	mov     cx, ax                  ; cx <- size of buffer
	mov     dx, ds:[baseDMAChannel]  ; dl <- channel #
	mov     dh, ModeRegisterMask <DMATM_SINGLE_TRANSFER,0,1,DMATD_READ>
	mov     di, DR_START_DMA_TRANSFER

	INT_OFF

	call   ds:[DMADriver]           ; set up transfer

        INT_ON
;-----------------------
;	Prfung
;-----------------------
	pop	ax			; needed size
        cmp	ax,cx
	jnz	nokorlen
        inc	cx
nokorlen:
	mov	ds:[bufferLen],cx	; store real size

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
ProgramDMADriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSDMAGrenzen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Check segment border for DMA transfer

called by:	BSSecondAlloc

IN:		bx = Segment
		dx = size

OUT:		bx = new Segment
		dx = new size

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSDMAGrenzen proc    near
	uses    ax,cx			;PUSH ax, ...
	.enter

;--------------------
;	START
;--------------------
        mov	ax,bx			; Segment
	and	ax,0fffh		; 64K space
        mov	cl,4
	shl	ax,cl			; Offset to 64K space
        add	ax,dx
	jnc	noproblem

;--------------------
;   Problemsolving
;--------------------
	mov	cx,ax			; size behind 64K
        mov	ax,dx
        shr	ax			; ax = half size
        cmp	ax,cx
        jb	hintseg
        sub	dx,cx
	jmp short noproblem1

;---------------------------------
; Use space behind the 64k border
;---------------------------------
hintseg:
        mov	ax,dx			; old size
	sub	ax,cx			; not used space
        mov	cl,4
        shr	ax,cl			; Offset-->Segment
        inc	ax
        add	bx,ax			; new Segment
        shl	ax,cl			; Seg-->Offs
        sub	dx,ax

noproblem1:
;--------------------
;	END
;--------------------
noproblem:
	.leave				; POP ax, ...
	ret

BSDMAGrenzen endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSGetDSPVersion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Get DSP Version

IN:		-

OUT:		[DSPVersion]

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	22.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSGetDSPVersion proc    far
	uses    ax,bx,dx,ds		; PUSH ax, ...
	.enter

        mov	ax,segment dgroup
        mov	ds,ax

        mov	bx,ds:[DSPVersion]
        tst	bh			; already readed ?
        jnz	done			; yes, use cached version
	SBDDACWriteDSP	DSP_GET_VERSION,0
        SBDDACReadDSP	0
        mov	bh,al
        SBDDACReadDSP	0
        mov	bl,al
	mov	ds:[DSPVersion],bx	; store DSP version

done:
	.leave				; POP ax, ...
	ret

BSGetDSPVersion endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSingletransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Start Singlecycletransfer

called by:	DettachFromStream

IN:		cx	# of bytes

OUT:		-

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSingletransfer proc    near
	uses    ax,bx,cx,dx		;PUSH ax, ...
	.enter
;	WARNING	BS_SINGLE_START
	clr	ds:[hsFlag]

;-----------------------------
;	DSP Command
;-----------------------------
        mov	bl,DSP_DMA_PCM_MODE	; Single mono
	mov	al,ds:[DSPFormatCommand]
	cmp	al,1ch			; AI mono ?
	jz	single			; yes
        ;
        ; readout prepared Singletransfercommand
        ;
        mov	bl,ds:[singleCommand]	; Code OK ?
        jz	done			; no

;--------------------
; Exit Autoinit
;--------------------
;	SBDDACWriteDSP	DSP_EXIT_AUTOINIT,0
        tst	cx			; samples left ?
        jz	setstate		; no

;--------------------
; program DSP
;--------------------
single:
	SBDDACWriteDSP  bl, 0
        dec	cx			; size -1
	SBDDACWriteDSP  cl, 0
	SBDDACWriteDSP  ch, 0

	mov	cl,3			; Status
setstate:
        mov	ds:[dacStatus],cl	; set state

done:
	.leave				; POP ax, ...
	ret

BSSingletransfer endp

LoadableCode            ends

ResidentCode            segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSecondWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Write Streamdata into Secondarybuffer
		Start Autoinit if buffer is filled

called by:	Notificationroutine

IN:		cx	Bytes to write
		si	Offset Stream

OUT:		cx	written Bytes

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init
        DL	22.09.98	Interleave

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSSecondWrite proc    far
	uses    ax,bx,dx,es,di,ds
	.enter
        call    SysEnterInterrupt		; LA 15.09.98

;--------------------
; Secondbuffer OK ?
;--------------------
        tst	ds:[bufferHandle]		; Secondbuffer defined ?
	jz	ende				; no, do nothing
	push	ds				; Stack [1]

;-------------------
; Get Interleave
;-------------------
        mov	bx,cx				; bx = Bytes
        mov	ax,cx				; ax = Bytes
	mov	cl,ds:[bsInterleave]		; cl
        dec	cl
	mov	dl,cl				; dl = interleave
	shr	ax,cl
        mov	cx,ax				; cx = Bytes to copy

;--------------------
; adjust size
;--------------------
	mov	ax,ds:[bufferFree]
        cmp	ax,cx				; not enough free ?
        jnc	genug				; no, size is OK
	mov	cx,ax				; Maxlen
genug:
	sub	ds:[bufferFree],cx		; free space - size
        mov	ax,cx
        mov	cl,dl				; Interleave
        shl	ax,cl				; calc. sourcebytes
        mov	cx,ax				; cx = Bytes to copy
	push	cx				; Stack [2] size

;-------------------------
; Pointer to Secondbuffer
;-------------------------
        mov	di,ds:[bufferP2]		; Startoffset
	mov	ax,ds:[bufferSegment]
        mov	es,ax
        mov	bx,ds:[bufferLen]		; max Offset

;------------------------
; Pointer to Streamdata
;------------------------
        mov	ax, ds:[streamSegment]
        mov	ds,ax				; Segment Source
        mov	al,dl				; al = Interleave
        inc	al
	mov     dx, ds:[SD_max]			; dx = ptr-Max

;-------------------
; Counter = 0 ?
;-------------------
testcx:
	tst	cx				; Buffer full ?
        jz	done				; yes, do nothing

;----------------
; check Offsets
;----------------
testoffs:
	cmp	di, bx				; Dest. offset too big ?
        jb	copybyte2			; no
        sub	di, bx				; back to top

copybyte2:
        cmp     si,dx				; End of Stream ?
	jb	copybyte			; no
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
	ja	testoffs			; next Byte

;--------------------
;   COPY END
;--------------------
done:
        pop	cx			; Stack [2]
        pop	ds			; Stack [1]
        mov	ds:[bufferP2],di	; Store Bufferpointer

;--------------------
; Start AutoInit
;--------------------
	tst	ds:[dacStatus]		; DAC waiting ?
        jne	fertig			; no, End

        mov	ax,ds:[bufferFree]
        tst	ax			; Buffer full ?
        jne	fertig			; no

;-----------------------
;	AI
; don't change cx !!!
;-----------------------
	call	BSAutoInitStart
	jmp 	short ende

;-------------------------------
; NO_INT: clean Secondarybuffer
;-------------------------------
fertig:

ifdef BS_NO_INT
	call	BSDACISR
endif

;-----------------
;	END
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

Funktion:       Starting Autoinit Transfer

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
;   Set state
;--------------------
	mov	al,1
	mov	ds:[dacStatus],al

	clr	ds:[bufferP2]
	mov	ax,ds:[bufferLen]
	clr	ds:[bufferFree]
;
; program blocksize
;
	mov	cx,ds:[bufferO2]
	dec	cx
	SBDDACWriteDSP  DSP_SET_BLOCK_SIZE, 0
	SBDDACWriteDSP  cl, 0			; L Byte
	SBDDACWriteDSP  ch, 0			; H Byte

;--------------------
; Start the Transfer
;--------------------

	mov	cl,ds:[DSPFormatCommand]
	SBDDACWriteDSP  cl, 0

	.leave				; POP ax, ...
	ret

BSAutoInitStart endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSDACISR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Additional Interruptservice

called by:	ISR

IN:		-

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	30.08.98	Init
	DL	02.09.98	endeFlag


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSDACISR proc    far
	uses    ax,bx,cx,dx,es,ds,si,di	;PUSH ax, ...
	.enter
ifdef	BS_SWAT_WARNING

	WARNING	BS_ISR
endif

;------------------------
; blockISR (for debugging)
;------------------------
	tst	ds:[blockISR]		; ISR blocked ?
;       jnz     fertig			; yes
	mov	al,1
	mov	ds:[blockISR],al	; block

;------------------------
; streamState
;------------------------
	tst	ds:[streamState]	; Status ON ?
	jnz	testdac			; yes

	call	MyBreak
	SBDDACWriteDSP	DSP_DMA_HALT,0	; DSP stop
	jmp     short fertig

;------------------------
; check dacStatus
;------------------------
testdac:
	mov	al,ds:[dacStatus]
	cmp	al,0			; idle ?
	jz      fertig			; yes, do nothing
	cmp	al,3			; dacStatus = Singletransfer ?
	jnz	secondbuftest		; no

;------------------------
; dacStatus = Singletr.
;------------------------
	call	MyBreak
	clr	ds:[dacStatus]		; Status = 0

	jmp	fertig

;------------------------
; Secondarybuffer empty ?
;------------------------
secondbuftest:
	mov	cx,ds:[bufferO2]
	mov	ax,ds:[bufferFree]
	add	ax,cx
	mov	ds:[bufferFree],ax
	mov	dx,ds:[bufferLen]
	mov	bx,dx			; bx = Len (for later)

	sub	ax,cx			; Puffer empty ?
	jbe	swapdacstate		; no

;--------------------
;  Stop output
;--------------------
	mov	ds:[bufferFree],dx
	mov	cx,ax
	mov	al,3
	mov	ds:[dacStatus],al

	call	BSFillRest

;------------------
; Halt DSP
;------------------
exitai:
	tst	ds:[hsFlag]		; Highspeed ?
	jz	exitlow			; no
	call    SBDInitChipDSP		; RESET will ending Highspeed AI
	clr	ds:[hsFlag]		; resetting Highspeedflag
	clr	ds:[dacStatus]
	call	MyBreak
	jmp	deblock
	;
	; normal Transfer
	;
exitlow:
	SBDDACWriteDSP	DSP_EXIT_AUTOINIT,0
	;
deblock:
	clr	ds:[blockISR]		; deblock next ISR
	jmp	fertig

;--------------------
; dacStatus swappen
;--------------------
swapdacstate:
	mov	dx,0			; bufferP2 Status = 1
	mov	al,ds:[dacStatus]
	xor	al,3			; toggle Status 1-->2 / 2-->1
	mov	ds:[dacStatus],al
	cmp	al,1			; old state = 2 ?
	jne	stateold2		; no
	mov	dx,cx			; bufferP2 = 0

stateold2:

	mov	ds:[bufferP2],dx	; Startpointer for next Transfer
	mov	ax,ds:[bufferP2]
	sub	ax,bx
	jb	fertig

	mov	ds:[bufferP2],ax

ifdef	BS_NO_INT
	mov	ax,30
	call	TimerSleep		; Delay for NO_INT
endif

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

Funktion:       Erase rest of buffer

called by:	?

IN:		cx	number of bytes

OUT:		-

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	08.09.98	Init

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSFillRest	proc far
	uses    ax,cx,dx,es,si		;PUSH ax, ...
	.enter


	mov	al,80h			; silence
	mov	es,ds:[bufferSegment]
	mov	si,ds:[bufferP2]
	mov	dx,ds:[bufferLen]
	tst	cx
	jz	fertig			; bytes = 0 !
stumm:
	cmp	si,dx			; si < bufferLen ?
	jae	fertig			; no, done
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

Funktion:       Unlock memory for Secondarybuffer
		Stop DMA (if neccessary)

IN:		ds	dgroup

OUT:
		bufferHandle = 0
		bufferSegment= 0
		bufferLen    = 0


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	29.08.98	Init
	DL	07.09.98	bufferSegment,-Len werden nicht resettet
	DL	09.03.2000	Stackverwaltung fuer INT deaktiviert
				Singlecycleverarbeitung fuer NewWave
	DL	13.03.2000	SB-Pro

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
	jz	done			; yes

;----------------------------
;	DMA Stop
;----------------------------
	push	bx			; Stack[1] = bx

;------------------------------
; EXIT AI and wait (NewWave)
;------------------------------
	tst	ds:[bsStatus]		; NewWave ?
	jz      dis_dma			; no
;
; 	Mono/Stereo
;
	mov	al,ds:[bsChannels]
	cmp	al,2			; Stereo ?
	jnz	exit_mono
;
; End Highspeedmode
;
	call	SBDInitChipDSP
	jmp	wait_last

exit_mono:
	SBDDACWriteDSP	DSP_EXIT_AUTOINIT,0

wait_last:
	mov	ax,30			; default wait time
	mov	cx,ds:[bsSampleRate]	; Samplerate
	tst	cx
	jz	norate			; no Rate defined !

	mov	dx,ds:[bufferO2]
	tst	dx
	jz	norate

	mov	ax,60			; 60 Ticks = 1 sec
	mul	dx
	div     cx                      ; len*60/rate -> Waittime in Ticks
	inc	ax			; Sicherheit
norate:
	call	TimerSleep		; wait until transfer is ready


;------------------------------
; 	Mono/Stereo
;------------------------------
	mov	al,ds:[bsChannels]
	cmp	al,2			; Stereo ?
	jnz	dis_dma

	call	BSResetMode		; reset Mixerflags (after Stereomodus)

;---------------------
;	DMA disable
;---------------------
dis_dma:
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
; release Secondarybuffer
;----------------------------
	call	MemFree
	clr	ds:[bufferHandle]

;--------------------
; delete ISR-Stack
;--------------------
	call	BSFreeStack

;--------------------
;	END
;--------------------
done:
	clr	ds:[hsFlag]		; clear Highspeedflag
	.leave				; POP ax, ...
	ret

BSSecondUnlock endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSECInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Prepare EC Checking

called by:       ?

IN:             -

OUT:		-


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSECInit proc    far

	.enter

	mov     cs:[BS_ECListDS],ds

	.leave
	ret

BSECInit endp

BS_ECListDS	word	0			; DS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSECTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Funktion:       Errorchecking routine

called by:       ?

IN:             -

OUT:		-

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSECTest proc    far
	uses	ax
	.enter

;-----------------------
;	check DS
;-----------------------
	mov     ax,ds
	cmp	ax,cs:[BS_ECListDS]
	jnz	error			; error !

;-----------------------
;	check SS
;-----------------------
	mov	ax,ss
	cmp	ax,00ffh		; Stacksegment OK ?
	jbe	error			; no
	cmp	ax,09f00h		; above 640k ?
	jb	done			; no
error:
;EC<	ERROR	BS_EC_TEST_ERROR_DS	>
done:
	.leave
	ret

BSECTest endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSECTestStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


IN:             ds	dgroup
		bx	Streamsegment

OUT:		-

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSECTestStream proc    far
	uses	ax
	.enter

;-----------------------
;	check Stream
;-----------------------
	mov	ax,ds:[streamSegment]
	cmp	ax,bx			; Segment OK ?
	jz	done			; yes

error:
	ERROR	BS_EC_TEST_ERROR_STREAM
done:
	.leave
	ret

BSECTestStream endp


ResidentCode            ends

