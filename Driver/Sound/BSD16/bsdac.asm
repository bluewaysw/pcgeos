COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound Driver

DATEI:		bsdac.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init
        DL	03.09.98	DSP

ROUTINES:
	Name			Description
	----			-----------
	SBDDACAttachToStreamNear
	SBDDACDettachFromStreamNear
	SBDDACSetSample
	SBDDACCheckSample
	SBDDACResetADPCM
	SBDDACFlushDACNear

*****************************************************************/@

udata           segment

	streamSegment		word
	dataOnStream		word

	DSPFormatCommand	byte
	streamSize		word
        sampleRate		word		; Samplerate (SetSample)

udata           ends

idata           segment

        basePortAddress         word	220h
        baseInterruptLevel      word	05h
	baseDMAChannel          word	01h

	readStatusPort          word    dspReadStatus	; + basePortAddress

	readDataPort            word    dspDataRead     ; + basePortAddress
	writeStatusPort         word    dspDataWrite    ; + basePortAddress
	writeDataPort           word    dspDataWrite    ; + basePortAddress

        isrunning		byte	00h	; 1 = Output active
        					; preventing Overinitialising
						; by SBDDACSetSample
	streamState		byte	00h	; 0 = free
        					; 1 = attached

idata           ends

ResidentCode            segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACSetSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set a transfer rate and format for the DAC

CALLED BY:      Strategy Routine
PASS:           cx      -> DAC to set
		ax      -> ManufacturerID
		bx      -> DACSampleFormat
		dx      -> sampling rate requested (in Hz)

RETURN:         dx      <- sampling rate set (in Hz)
		cx      <- request Stream size
		carry set if un-supported format or DAC #

DESTROYED:      nothing

SIDE EFFECTS:   Attempts to alter the DSP on the Sound Blaster to
		process Data at the new rate and format

PSEUDO CODE/STRATEGY:
		Calculate the divisor for the given rate then set
		the DSP for it.

		The transfer rate of DAC data for the Sound Blaster
		is figured in the following manner:

		RATE = 65,535 - (256,000,000 / divisor)

		So:

		divisor = 65,356 - (256,000,000 / RATE * Kanalzahl)


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	DL	18.08.98	Template

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBDDACSetSample proc    near
	uses    ax
	.enter
	;

;---------------------------------
;	check runningflag
;---------------------------------
	tst	ds:[isrunning]		; Samplerate defined ?
        jne	done			; yes

	mov	ds:[sampleRate],dx	; save Samplerate

	call	BSSetSamplerate		; Formatchecking etc.
	jc	error


	call    SBDDACCheckSample  	; dx <- closest rate
	tst     dx                      ; check closest rate
	jz      error

        push	dx			; sample rate 		[0]

	clr     cx                      ; cx <- no reference byte
	call    SBDDACGetFormatSetting  ; dl <- mode to set on DSP

	mov     ds:[DSPFormatCommand], dl       ; save format for later


	pop	cx			; cx <- sampling rate	[0]

	movdw   dxax, 256000000         ; dxax <- 256000000
	div     cx                      ; ax <- 65536 - divisor

	neg     ax                      ; ax <- divisor

	mov     bx, ax                  ; bx <- divisor for rate

	;
	;  Set up the DAC to operate at the given rate

        mov	dx,cx			; dx = Samplerate

	SBDDACWriteDSP  DSP_SET_RATE_DIVISOR, 0
	SBDDACWriteDSP  bh, 0

	;
	;  Determine optimal transfer size given rate

	mov	ds:[sampleRate],dx


	call	BSPrepareMode

        mov	ds:[isrunning],1

done:
	mov	dx,ds:[sampleRate]
	mov     cx, STANDARD_DAC_STREAM_SIZE

	clc                             ; everything ok
	jmp     short exit

error:
	stc

exit:
	.leave
	ret


SBDDACSetSample endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACCheckSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Determine if a sample rate and format is supported

CALLED BY:      Strategy Routine
PASS:           cx      -> DAC to check
		ax      -> ManufacturerID
		bx      -> DACSampleFormat
		dx      -> sample rate (in Hz)

RETURN:         dx      <- closest available sample rate (in Hz)
		cx      <- request stream size
DESTROYED:      nothing
SIDE EFFECTS:
		none
PSEUDO CODE/STRATEGY:
		call SBDDACGetFormat range, check bounds and return

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	TS      10/20/92                Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACCheckSample       proc    near
	uses    si,di
	.enter
	;
	;  See if the requested DAC # even exits
	cmp     cx, ds:[numOfDACs]
	jae     notSupported

	;
	;  Get the range of sample rates supported for
	;       the specified manufacturer and format.
	;  The maximum and minimum will be zero if
	;       the format is not supported
	call    SBDDACGetFormatRange    ; di <- max rate, si <- min rate

	tst     di                      ; is format supported at all
	jz      notSupported

	;
	;  Is the requested format rate to low?
	cmp     dx, si
	jb      setToMin

	;
	;  Is the requested format rate to fast?
	cmp     dx, di
	ja      setToMax
done:
	mov     cx, STANDARD_DAC_STREAM_SIZE
	.leave
	ret
notSupported:
	clr     dx                      ; unsupported format. set rate to zero
	jmp     short done

setToMin:
	mov     dx, si                  ; rate is to low, set to min.
	jmp     short done

setToMax:
	mov     dx, di                  ; rate is to fast, set to max.
	jmp     short done
SBDDACCheckSample       endp
ResidentCode            ends

LoadableCode            segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACAttachToStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Attach to the given stream

CALLED BY:      Strategy Routine
PASS:           cx      -> DAC to attach
		ax      -> stream token (virtual segment)
		bx      -> stream segment
		dx      -> stream size
		INT_ON

RETURN:         carry set on error

DESTROYED:      nothing
SIDE EFFECTS:


REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
        DL	09.08.98	Template
        DL	29.08.98	Secondarybuffer (BSSecondAlloc)
        DL	02.09.98	dacStatus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACAttachToStream    proc    far
	uses    ax,bx,cx,dx,si,di,bp
	.enter
	;

;	WARNING	BS_ATTACH_STREAM

	cmp     cx, ds:[numOfDACs]
	jae     done

;-----------------------
;	streamState
;-----------------------
	tst	ds:[streamState]
	jne     done

;-----------------------
; Wait for old PLAY
;-----------------------
        mov	cx,10			; 10 times

waitfordac:
	tst	ds:[dacStatus]		; dacStatus = 0 ?
        jz	streamset		; yes, continue
        mov	ax,6			; 1/10 sec
        call	TimerSleep
        dec     cx
        jnz	waitfordac

        jmp	error			; Timeout = ABBRUCH

streamset:
	mov	ds:[streamSegment],bx	; Pointer to Stream
	mov	ds:[streamSize],dx
	clr	ds:[endeFlag]

;-----------------------------
;	Stream init.
;-----------------------------
	;
	;  Set the notification threshold for the reader
	;       half of the stream.  The threshold
	;       is zero, meaning that anytime the writer
	;       writes data, we want to know about it.
	mov     ax, STREAM_READ
	clr     cx			; Threshold = 0

	mov     di, DR_STREAM_SET_THRESHOLD
	call    StreamStrategy

;----------------------------------
;	Notificationroutine defin.
;----------------------------------
	push    dx                      ; save stream size [1]
	;
	;  Set notification routine for the reader half
	;       of the stream.
	mov     ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE,>
	mov     cx, segment ResidentCode
	mov     dx, offset SBDDACReadNotification
	mov     di, DR_STREAM_SET_NOTIFY
	call    StreamStrategy

        pop	dx			; stream size [1]

;---------------------------------
;	Prepare Output
;
;---------------------------------
        mov	ds:[streamState],1

;---------------------------------
; 	Secondarybuffer
;---------------------------------
	mov	cx,10			; Timeout counter
buffwait:
        mov	ax,ds:[bufferHandle]
	tst	ax			; Buffer allocated ?
        jz	alloc			; no, continue

;---------------------
; 	Timeout
;---------------------
        mov	ax,1
        call	TimerSleep		; 80ms
        dec	cx
        jne	buffwait
        jmp	error			; TIMEOUT = Error

;---------------------
; 	Allocate
;---------------------
alloc:
        mov	cx,ds:[streamSize]
	shr	cx
        mov	cx,4000h
	call	BSSecondAlloc
	jc	error

done:
	.leave
	ret

error:
	clr     ds:[streamSegment]
	stc
	jmp     short done

SBDDACAttachToStream    endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACDettachFromStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Clean up stream and stop transfer

CALLED BY:      Strategy Routine
PASS:           cx      -> DAC to stop
		bx      -> segment for stream

		ds      -> dgroup of driver
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:
                Stops the DAC in progress.  Stops the DMA transfer

PSEUDO CODE/STRATEGY:
		determine transfer type and call appropriate routine

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
        DL	09.08.98	Template
	DL	07.09.98	INT_OFF/ON auf Wunsch von EC auskommentiert

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBDDACDettachFromStream proc    far
	uses    ax, bx, cx, dx, di, ds, es, si
        .enter

;	WARNING	BS_DETTACH_STREAM

        ;
        ;  See if we are dealing with a legal DAC
	;
	INT_OFF

;---------------------
; Stream attached ?
;---------------------
	tst	ds:[streamState]	; attached ?
        jnz	waitfordsp		; yes

        clr	ds:[endeFlag]
        jmp	short done		; no, End

;---------------------------
; Waiting for DSP
;---------------------------
waitfordsp:
        mov	cx,10			; 10 trys
waitdsp:
	tst	ds:[dacStatus]
        jz	restwav
        mov	ax,10
        call	TimerSleep
        INT_OFF

        dec	cx
        jnz	waitdsp
        jmp	done

;---------------------
;    Remaining-WAV
;---------------------
restwav:
        mov	dx,ds:[bufferLen]
        mov	cx,dx
        sub	cx,ds:[bufferFree]	; Buffer with Data ?
        jz	unlock			; no
        call	BSFillRest
        call	BSSingletransfer	; Start Single Transfer
	mov	ds:[bufferFree],dx
	jmp	waitdsp

;------------------------
; Free Secondbuffer
;------------------------
unlock:
        call	BSSecondUnlock


        clr	ds:[isrunning]
        clr	ds:[streamState]	; Status = not attached

	mov	al,1
	tst	ds:[dacStatus]		; DAC working ?
        jnz	setflag			; yes

        clr	al
setflag:
	mov	ds:[endeFlag],al

done:

	.leave
	ret
SBDDACDettachFromStream endp

LoadableCode                    ends

ResidentCode            segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACResetADPCM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Reset the reference bit for the ADPCM transfer

CALLED BY:      Strategy Routine
PASS:           cx      -> DAC to change
                ds      -> dgroup of driver
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:
		alters the dmaTransferMode if applicable

PSEUDO CODE/STRATEGY:
		check for legal DAC
		check for appropriate transfer mode
                set bit
		return

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	TS      12/ 3/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACResetADPCM        proc    near
        .enter
        ;
	;
	;  As there is only one DAC on the Sound blaster, we
	;       know that cx was zero when we reached here.
	;  To preserve cx, all we do is clear cl.
	clr     cl

	.leave
	ret
SBDDACResetADPCM        endp

ResidentCode            ends

LoadableCode                    segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACFlushDAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Clean out the stream and stop the DAC

CALLED BY:      Strategy Routine
PASS:           cx      -> DAC to clean out
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name    Date            Description
        ----    ----            -----------
        TS      11/25/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACFlushDAC  proc    far
	uses    ax, cx, dx, di
	.enter

	.leave
	ret
SBDDACFlushDAC  endp


LoadableCode            ends

ResidentCode            segment resource

COMMENT @/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBDDACGetFormatRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Return the maximum and minimum rate for the given format

		For detecting a BestSound-driver this function can be used !
                - The DACSampleFormat must be set to DACSF_MIXER_TEST

                Sample rate | BestSound Capability
                ----------------------------------
                	2   | Mixer control
                        3   | Recording feature
                        5   | BestSound NewWave

CALLED BY:      SBDCheck(Set)Sample

PASS:           ax      -> ManufacturerID
		bx      -> DACSampleFormat
		dx      -> sample rate (in Hz)
		ds      -> dgroup of driver

RETURN:         si      <- minimum rate for format (zero if unsupported)
		di      <- maximum rate for format (zero if unsupported)

DESTROYED:      nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		Look for legal
REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	TS      10/21/92	Initial version
        DL	13.10.98	Mixertest: Geoworks hatte eine Mixerunter-
        			nicht vorgesehen. Deshalb musste die Sprung-
                                tabelle um die Routinen zur Mixersteuerung
                                erweitert werden. Die Mixerlibrary erkennt
                                einen Treiber mit Mixerunterstuetzung daran,
                                dass das DACSampleFormat DACSF_MIXER_TEST
                                mit einer Samplerate von 2 unterstuetzt wird.
        DL	24.10.1999	Recordtest:
        			Ob der Treiber auch Recording untersttzt,
                                wird durch Rckmeldung der Samplerate 3
                                angezeigt.
        DL	12.03.2000	Samplerate 5 = NewWave-Play wird untersttzt

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/@
SBDDACGetFormatRange    proc    near
	uses    bx, cx, ds
	.enter
	mov     cx, bx                                  ; cx <- format

	clr     bx,si,di
topOfLoop:
	;
	;  Check for a legal manufacturer ID
	cmp     cs:slowFormatList[bx].DACFR_manufacturerID, ax
	je      checkFormat

incBXAndLoop:
	add     bx, size DACFormatRange                 ; get next listing
	cmp     cs:slowFormatList[bx].DACFR_manufacturerID, END_OF_DAC_FORMAT_LIST
	jne     topOfLoop

done:
	.leave
	ret

checkFormat:
	;
	;  Check for a matching format #
	cmp     cs:slowFormatList[bx].DACFR_format, cx
	jne     incBXAndLoop
	mov     si, cs:slowFormatList[bx].DACFR_min     ; si <- min
	mov     di, cs:slowFormatList[bx].DACFR_max     ; di <- max
	jmp     short done
SBDDACGetFormatRange    endp

	;
	;  List must be ordered by Manufacturer if GetFormatRange
	;       is to work.
slowFormatList  DACFormatRange  \
	<MANUFACTURER_ID_GEOWORKS     , DACSF_8_BIT_PCM   , 4000, 23000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_8_BIT_PCM   , 4000, 23000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_2_TO_1_ADPCM, 4000, 12000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_3_TO_1_ADPCM, 4000, 13000>,
	<MANUFACTURER_ID_CREATIVE_LABS, DACSF_4_TO_1_ADPCM, 4000, 11000>,
	<MANUFACTURER_ID_BSW,		DACSF_8_BIT_MONO    , 4000, 45000>,
	<MANUFACTURER_ID_BSW,		DACSF_8_BIT_STEREO  , 4000, 45000>,
	<MANUFACTURER_ID_BSW,		DACSF_16_BIT_MONO   , 4000, 45000>,
	<MANUFACTURER_ID_BSW,		DACSF_16_BIT_STEREO , 4000, 45000>,
	<MANUFACTURER_ID_BSW,		DACSF_MIXER_TEST    , 1, 5>


	word    END_OF_DAC_FORMAT_LIST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDDACGetFormatSetting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Return the command and value to send to the DSP

CALLED BY:      SBDSetSample
PASS:           dx      -> Hz setting for sample
                bx      -> DACSampleFormat
                cx      -> DACReferenceByte

RETURN:         dl      <- command to send to DSP

DESTROYED:      nothing
SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		look up rate and see if it is "high speed".

REVISION HISTORY:
        Name    Date            Description
	----    ----            -----------
	TS      10/21/92        Initial version
	DL	13.04.97        formatCommandTable erweitert
				liefert bei MANUFACTURER_ID_BSW
				keinen DSP Befehl sondern Zwischencode 80..87H
				der von --- ausgewertet werden muá.
        DL	20.12.97	SBLASTER


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDDACGetFormatSetting  proc    near
	uses    ax,bx
	.enter
	;
	;  Look at format and determine propper command
	;       to send to DSP.
	mov     al, bl                          ; al <- DACSampleFormat
	shl     al, 1                           ; make room for reference
	add     al, cl                          ; al <- format + reference
	mov     bx, offset formatCommandTable   ; cs:bx <- formatCommandTable

	xlat    cs:[bx]                         ; al <- DSP command for format

	mov     dl, al                          ; dl <- command for DSP

	.leave
	ret

SBDDACGetFormatSetting  endp

formatCommandTable      byte    1ch,            ; 8 bit PCM
				1ch,            ; 8 bit PCM with reference?
				74h,            ; 2:1 ADPCM
				75h,            ; 2:1 ADPCM with reference
				76h,            ; 3:1 ADPCM
				77h,            ; 3:1 ADPCM with reference
				16h,            ; 4:1 ADPCM
				17h,            ; 4:1 ADPCM with reference
				81h,		; 8 bit mono
				81h,		; 8 bit mono
				82h,		; 8 bit stereo
				82h,		; 8 bit stereo
				83h,		; 8 bit mono
				83h,		; 8 bit mono
				84h,		; 8 bit stereo
				84h		; 8 bit stereo


;--------------------
; Sub:	SBDOutput
;--------------------
SBDOutput proc far

	out 	dx, al
	ret

SBDOutput endp

;--------------------
; Sub:	MyBreak
;--------------------
MyBreak proc far

	ret

MyBreak endp

ResidentCode            ends

