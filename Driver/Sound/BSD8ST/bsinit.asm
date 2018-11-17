COMMENT @/********************************************************

	Copyright (c) Dirk Lausecker -- All Rights Reserved

PROJECT:	BestSound driver

DATEI:		bsinit.asm

AUTOR:		Dirk Lausecker

REVISION HISTORY:
	Name	Datum		Beschreibung
	----	-----		------------
	DL	08.08.98	Init
        DL	2000		reading settings from INI
        DL	16.08.2000	Translation for ND

ROUTINES:
	Name                            Description
	----                            -----------
	SoundInitBoardFM                Sets up board for FM synthesis
	SBDInitChipFM                   Sets up FM synth chip
	SBDInitChipMixer                Set up mixer chip on Sound Blaster PRO
	SBDExitDriver                   Deal with leaving PC/GEOS
	SBDSupsend                      Deal with task-switching
	SBDUnsuspend                    Deal with waking up after task switch
	SBDTestDevice                   Find out of device is present
	SBDSetDevice                    Set up the device specified


Descr.:
	Initial. soundcard and handler for SUSPEND

*****************************************************************/@

udata           segment
	oldInterruptVector      fptr            ; pointer to old int. routine
	DMADriver               fptr            ; fptr to DMA strategy routine

	numOfVoices             word            ; # of FM voices
	numOfDACs               word            ; # of DACs

udata           ends


InitCode        segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDInitBoard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Initialize the Board (both FM and DAC)

CALLED BY:      Strategy Routine

PASS:           ds      -> driver's dgroup

RETURN:         nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
                Turn the FM chip on and set the nine voices to default
                values that produce sound.

                Turn on the DSP and speaker

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                This biffs the PC/Speaker.  Gotta do something
                'bout that...

                It would be nice if we could just disable the
                DAC support if DMA failed to load, or the DSP
                failed to init.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/ 4/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDInitBoard    proc    far
        uses    ax, cx, dx
        .enter
        ;
        ;  Assume things will go bad.  Assume that the FM
        ;       synth chip will explode and the DSP will
        ;       fail to reset.  This will mean we have no
        ;       FM voices and no DACs.
        clr     ds:[numOfVoices]        ; assume no FM voices
        clr     ds:[numOfDACs]          ; assume no DAC

        ;
        ;  Now, read our hardware settings from the .ini
        ;

        call    GetDefaultSettings     ; gets base IO and interrupt level

        call    ReadIniFileSettings     ; gets base IO and interrupt level

        ;
        ;  The FM chip requires a 3 usec delay after selecting
        ;       a register and a 23 usec delay after writing
        ;       data.  To deal with this in interrupt time,
        ;       use the pc-speaker timer to do micro second
        ;       accurate timing.

        call    InitMicroTimer          ; set up timer 2 for micro timer

initDACs::
        ;
        ;  All SoundBlaster boards have a DSP which is used for
        ;       DAC and ADC sounds.


        call    SBDInitChipDSP          ; set up DSP chip
        jc      initFM
        ;
        ;  The DAC on the SoundBlaster uses the DMA driver
        ;       Load that puppy up so we can get our hands on it
        call    LoadDMADriver
        ;jc     initFM

        ;
        ;  The DSP sends out an interrupt when a DMA transfer is
        ;       completed.  We must intercept this interrupt
        ;       and deal with it.
        call    SBDInitDMAInterrupt     ; set up interrupt routine
;       jc      initFM

        mov     ds:[numOfDACs], cx      ; set DACs available
        call	BSGetDSPVersion		; DSP-Version laden

initFM:
        ;
        ;  Once we have a micro-second accurate timer, can set
        ;       up the FM registers so we know what they are set
        ;       to.
        call    SBDInitChipFM           ; set up FM chip to make noise
        jc      done

        mov     ds:[numOfVoices], cx    ; set Voices available

done:
        .leave
        ret
SBDInitBoard    endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ReadIniFileSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Read the base hardware settings from the .ini file

CALLED BY:      SBDInitBoard
PASS:           nothing
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:
                Sets the base port level and things

PSEUDO CODE/STRATEGY:
                Read category/key from .ini file.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      3/ 1/93         Initial version
        DL	18.03.2000	Funktionalit„t implementiert

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
soundCategory	char    "sound",0
addressKey	char    "Address",0
irqKey		char    "Irq",0
dmaKey		char    "Dma",0

ReadIniFileSettings     proc    near
        uses    ax, bx, cx, dx, di, si, ds, es, bp
tempStringBuffer local 20 dup (byte)
        .enter

        push    bp                              ; save bp for later

        ;
        ;  Set es:di to point to base of tempStringBuffer
        mov     di, ss                          ; es:di <- driverNameBuffer
        mov     es, di
        mov     di, bp                          ; di <- base of frame
        add     di, offset tempStringBuffer     ; di <- offset to buffer

        ;
        ;  Read Category/Key value for address/irq/dma
        ;
        mov     si, offset soundCategory    	; ds:si <- category asciiz
        mov     cx, cs                          ; cx:dx <- key asciiz
        mov	ds,cx				; LA
        mov     dx, offset addressKey
        mov     bp, InitFileReadFlags <IFCC_INTACT,,,13>
        call    InitFileReadString              ; String -> es:di
        mov	bx,0				; Adressdummy
	jc	read_irq			; Fehler -> Ende

;-----------------------
; Settings aus INI lesen
;	[sound]
;	address = 220
;	irq 	= 5
;	dma	= 1
;-----------------------
	push	ds
        push	si

        mov	ax,es
        mov	ds,ax				; ds:di = String

        call	BSHexAsciiToHex			; Hex32 -> dx:ax
	mov	bx,ax				; BX = Address

        pop	si
        pop	ds
read_irq:
        mov	cx,cs
        mov     dx, offset irqKey
        mov	ax,0				; Dummy IRQ
        call	InitFileReadInteger		; ax = IRQ
	mov	bp,ax				; BP = IRQ

        mov     dx, offset dmaKey
        mov	ax,0				; Dummy DMA
        call	InitFileReadInteger		; al = DMA
        mov	dx,4
        mov	cx,bp				; CX = IRQ
        jc	store_values
	mov	dx,ax				; DX = DMA

store_values:
	mov	ax,segment dgroup
        mov     ds,ax

        tst	bx
        jz	test_irq
        mov     ds:[basePortAddress],bx		; Base address
test_irq:
        tst	cx
        jz	test_dma
        mov     ds:[baseInterruptLevel],cx	; IRQ
test_dma:
	cmp	dx,4				; DMA-Entry found ?
        jae	done				; no !
        mov     ds:[baseDMAChannel],dx		; DMA

;------ Ende ------
done:
	pop	bp

        .leave
        ret
ReadIniFileSettings     endp

;----------------------------------------------------------
;
;	BSHexAsciiToHex
;
;	Konvert Hexnumber (Null terminated ASCII-String)
;	into HexValue
;
; IN:	es:di	String
; OUT:	ax	Hexvalue
;----------------------------------------------------------
BSHexAsciiToHex	proc	near
	uses	dx,es,di,si
        .enter

	mov	si, di

	;
	;  Well, we need to read HEX values here, not decimal,
	;  so we get to to play the "parse the string" game...
	clr	dx
	lodsb					; al <- 1st numeral

readHexNumeral:
	sub	al, '0'				; convert from char to #
	or	dl, al				; OR into low nibble

	lodsb					; al <- next numeral

	tst	al
	jz	done				; => null read

	shl	dx, 1				; shift over 4 bits
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1

	jmp	short readHexNumeral

done:
        mov	ax,dx
        .leave
        ret

BSHexAsciiToHex	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDInitChipFM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set the FM chip to allow 9 voices, with each voice
                having an initial voice setting that produces sound.

CALLED BY:      SBDInitBoardFM

PASS:           ds      -> driver's dgroup

RETURN:         cx      <- # of FM voices available
                        - or -
                carry set on error

DESTROYED:      nothing
                        - or -
                cx destroyed if error

PSEUDO CODE/STRATEGY:
                Init FM Chip by clearing test register, then enabling
                        wave forms.

                Init voices by reading settings in FMRegisterMap and
                        setting registers to those values.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/ 4/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDInitChipFM   proc    near
        uses    bx, dx, si
        .enter
        ;
        ;  We trash ax, and set cx at the end.  We can save a push
        ;       and a pop if we store ax in cx until we need it
        ;       and then restore it.  We use ax instead of anything
        ;       else because we can xchg it.
        mov_tr  cx, ax                  ; save ax

        ;
        ; To initialize the Sound Blaster board, write zeros to address
        ; 01H.
        mov     al, FMRM_test           ; change test register
        clr     ah                      ; set it to zero
        mov     dx, FMRWM_ALWAYS        ; really change it!
        call    SBDWriteFMRegFar

        ;
        ; Enable wave form selection by writing 20H to address 01H.
        mov     al, FMRM_test           ; change test register
        mov     ah, mask TR_DISTORT_WAVE; set it to enable waveform
        mov     dx, FMRWM_ALWAYS        ; really change it!
        call    SBDWriteFMRegFar

        mov     ah, 0                   ; zero all remaining registers
        mov     si, FMRM_timer1         ; set pointer to timer1
topOfLoop:
        inc     al                      ; set register address to new register
                                        ; ah <- value to load in register
        mov     ah, byte ptr ds:ourFMRegisterMap[si]
        mov     dx, FMRWM_ALWAYS        ; really change the value
        call    SBDWriteFMRegFar        ; set register to zero
        inc     si                      ; point to next property
        cmp     si, size FMRegisterMap
        jna     topOfLoop

        mov_tr  ax, cx                  ; restore ax
        mov     cx, NUM_OF_VOICES       ; 9 voices right now
        .leave
        ret
SBDInitChipFM   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDInitChipDSP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Make the DSP operational

CALLED BY:      SBDInitChip
PASS:           ds      -> driver's dgroup

RETURN:         carry set on error
                        - or -
                cx      <- # of DACs available

DESTROYED:      nothing
                        - or -
                cx if error

SIDE EFFECTS:
                sets up the DSP
                turns on the DSP speaker
                locks a block on the heap

PSEUDO CODE/STRATEGY:
                From Programming the DSP (p. 11-4)

                Procedure to reset DSP:

                  a. Write a "1" to RESET port (2x6h) and wait 3usec
                  b. Write a "0" to RESET port
                  c. Poll for a READYBYTE = 0aah from the READ DATA
                        port (2xah).  Before reading 2xah, it is
                        advisable to check data available status
                        at port 2xeh.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      10/26/92        Initial version
        DL	19.10.97	auf far ge„ndert
	martin	2001/2/22	Added OPL3-SA compatibility
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDInitChipDSP  proc    far
        uses    bx, dx
        .enter
        ;
        ;  Since we need to set cx at the end, we can use it
        ;       to store a register we trash instead of
        ;       pushing and popping it.  The best candidate
        ;       for this is AX, since we can xchg it and
        ;       use only one byte
        mov_tr  cx, ax                          ; savce ax

        ;
        ;  Set up the register values in the dgroup
        mov     dx, ds:[basePortAddress]

;------------------------------
;	Highspeedmode RESET
;
; Es gibt zwei Grnde, weshalb SBDInitChipDSP aufgerufen wird:
; 1. Initialisierung beim Laden des Treibers
; 2. Zurckschalten von Highspeed in Normalmodus
; Nur bei 1. drfen Portadressen berechnet werden !
; . . . . . . . . . . . . . . . . . . . . . . . . .
; There exist two reasons for calling this function:
; 1. Init. after loading the driver
; 2: reset from highspeed to normal mode
; Only for reason 1. it's allowed to calculate
; the port adresses
;------------------------------
	tst	ds:[hsFlag]		; DSP in Highspeedmode ?
        jnz	resetdsp		; yes, reset only

;------------------------------
; calculate Portadresses
;------------------------------
        add     ds:[readStatusPort], dx
        add     ds:[readDataPort], dx
        add     ds:[writeStatusPort], dx
        add     ds:[writeDataPort], dx

        ;
        ;  As per the instructions, we write a one, wait
        ;       3 micro seconds, then write a 0 and
        ;       then try to read a 0aah.
        ;  The manual also mentions that it takes around
        ;       100 usec for the DSP to reset itself.
        ;  I assume this is after the 0aah is read.
        ;

resetdsp:
        add     dx, dspReset
        mov     al, 1                           ; write a 1 to RESET port
        out     dx, al

        mov     bx, dx                          ; bx <- reset port address

        mov     dx, TICKS_TO_DELAY_FOR_DSP_RESET
        call    MicroDelay                      ; wait 3 usec

        mov     dx, bx                          ; dx <- reset port address
        clr     al                              ; write a 0 to RESET port
        out     dx, al

        ;
        ;  Read from DSP.  Check for data available
        ;       100 times before just reading the port.
        SBDDACReadDSP   100

        cmp     al, DSP_RESET_OK
        jne     error                           ; did reset occur correctly?

        mov     dx, TICKS_TO_DELAY_AFTER_DSP_RESET
        call    MicroDelay                      ; wait 100usec

        ;
        ;  With the DSP being re-set, we want to also
        ;       turn on the Speaker.  Why?  Because it
        ;       takes a great many msec for the speaker
        ;       to actually turn on.  It would not
        ;       be good to play something and not
        ;       hear it because the speaker was
        ;       in the process of turning itself on.
        SBDDACWriteDSP DSP_TURN_ON_SPEAKER, 250 ; extra long delay

	;;
	;; This undocumented dsp command is needed by
	;; 99.9% SoundBlaster compatible sound cards such
	;; as the Yamaha OPL3-SA.  Without it the card
	;; doesn't send an interrupt after a DMA transfer.
	;; -martin 2001/2/22 
	;; 
        SBDDACWriteDSP DSP_FORCE_INTERRUPT, 0   ; force an interrupt to make
						; the chip sends them 
done:
        mov_tr  ax, cx                          ; restore ax
        mov     cx, NUM_OF_DACS                 ; set # of voices
        .leave
        ret

error:
        stc                                     ; mark as error
        jmp     short done
SBDInitChipDSP  endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDInitDMAInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set up the hardware interrupt for the SoundBlaster

CALLED BY:      SBDInitBoard
PASS:           ds      -> dgroup of driver
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:
                alters interrupt vector table.

PSEUDO CODE/STRATEGY:
                grab interrupt and set it to our interrupt handler.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      10/26/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBDInitDMAInterrupt     proc    near
        uses    ax, bx, cx, di, es
        .enter
        ;
        ;  SysCatchDeviceInterrupt expects es:di to point
        ;  to the location to store the old address.
        ;  this means we need to set es to dgroup as well.
        mov     ax, ds                          ; ax <- driver dgroup
        mov     es, ax                          ; es <- driver dgroup

        ;
        ;  Call the kernel and have it insert our
        ;  interrupt routine in the interrupt vector table
        mov     ax, es:[baseInterruptLevel]     ; ax <- interrupt level
        push    ax
        mov     bx, segment ResidentCode        ; bx:cx <- routine to call

        mov     cx, offset SBDDACEndOfDMATransferInt7
        cmp     ax, 7
        je      changeVector

        mov     cx, offset SBDDACEndOfDMATransfer

changeVector:
        mov     di, offset oldInterruptVector   ; es:di <- storage for old rtn.
        call    SysCatchDeviceInterrupt

        pop     cx                              ; get interrupt level

        pushf
        INT_OFF

        test    cx, 8
        jnz     irqctrl2

        in      al, 021h                        ; read current int. mask

        call	WaitPerJump

        mov     ah, 0xFE
        rol     ah, cl

        and     al, ah                          ; enable int 7 by clearing bit7

        out     021h, al                        ; write mask
        jmp     short done

irqctrl2:
        and     cl, 0xF7

        in      al, 0a1h                        ; read current int. mask

        call	WaitPerJump			; frueher jmp $+2

        mov     ah, 0xFE
        rol     ah, cl

        and     al, ah                          ; enable int 7 by clearing bit7

        out     0a1h, al                        ; write mask

        in      al, 021h                        ; read current int. mask

        call	WaitPerJump			; frueher jmp $+2

        and     al, 0FBh
        out     021h, al

done:
        call    SafePopf

        .leave
        ret

SBDInitDMAInterrupt     endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                LoadDMADriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Load the DMA driver

CALLED BY:      SBDInitBoard
PASS:           nothing
RETURN:         carry set on error

DESTROYED:      nothing
SIDE EFFECTS:
                loads in DMA driver

PSEUDO CODE/STRATEGY:
                right now, go to SYSTEM/DMA and load in dosreal.geo

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      10/27/92        Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dmaDriverCategory       char    "dma",0
dmaDriverKey            char    "driver",0
EC<dmaDriverDefault     char    "dosreale.geo",0>
NEC<dmaDriverDefault    char    "dosreal.geo",0>
LoadDMADriver   proc    near
        uses    ax, bx, cx, dx, di, si, ds, es, bp
driverNameBuffer local 13 dup (byte)
        .enter
        push    bp                              ; save bp for later
        call    FILEPUSHDIR                     ; save current dir

        ;
        ;  Move dir to ../SYSTEM/DMA
        mov     si, cs                          ; ds:dx <- path name
        mov     ds, si
        mov     bx, SP_SYSTEM                   ; start in system dir
        mov     dx, offset dmaDriverCategory    ; move to SYSTEM/DMA
        call    FileSetCurrentPath
        jc      done                            ; error moving to directory

        ;
        ;  Set es:di to point to base of driverNameBuffer
        mov     di, ss                          ; es:di <- driverNameBuffer
        mov     es, di
        mov     di, bp                          ; di <- base of frame
        add     di, offset driverNameBuffer     ; di <- offset to buffer

        ;
        ;  Read Category/Key value for driver
        mov     si, offset dmaDriverCategory    ; ds:si <- category asciiz
        mov     cx, cs                          ; cx:dx <- key asciiz
        mov     dx, offset dmaDriverKey
        mov     bp, InitFileReadFlags <IFCC_INTACT,,,13>
        call    InitFileReadString              ; read driver name
        jc      loadStandardDriver

        ;
        ;  Load in the given sound driver and
        ;  determine its strategy routine.
        ;  Save a fptr to the routine in dgroup

loadSpecificDriver::
        ;
        ;  Use the driver with the given geode
        segmov  ds, es, si                      ; ds:si <- driver name
        mov     si, di
        clr     ax                              ; who cares what ver.
        clr     bx
        call    GeodeUseDriver                  ; get it

        jc      loadStandardDriver              ; pass carry back
                                                ; if error loading

readStrategyRoutine:
        call    GeodeInfoDriver                 ; ds:si <- DriverInfoStruct

        mov     ax, segment dgroup              ; es <- dgroup of driver
        mov     es, ax
                                                ; copy the far pointer
        movdw   es:[DMADriver],ds:[si].DIS_strategy, ax

        clc                                     ; everything went fine
done:
        ;  flags preserved across popdir
        call    FILEPOPDIR                      ; return to old dir

        pop     bp                              ; restore bp
        .leave
        ret


loadStandardDriver:
        ;
        ;  Either there was not category, or the category was corrupted,
        ;  or the file specified in the catagory did not exists.
        ;  In any event, we want to load something and hope it works.
        ;  The best choice is the dos-real DMA driver.
        segmov  ds, cs, si                      ; ds:si <- driver name
        mov     si, offset dmaDriverDefault
        clr     ax                              ; who cares what version
        clr     bx
        call    GeodeUseDriver
        jnc     readStrategyRoutine             ; was there an error?
        jmp     done
LoadDMADriver   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDExitDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       We are being unloaded.  Clean up after ourselves

CALLED BY:      Strategy Routine
PASS:           ds      -> dgroup
RETURN:         nothing
DESTROYED:      allowed: ax, bx, cx, dx, si, di, ds, es

SIDE EFFECTS:
                frees up two streams

PSEUDO CODE/STRATEGY:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/19/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDExitDriver   proc    far
        .enter
        .leave
        ret
SBDExitDriver   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Prepare board to go into task-switch

CALLED BY:      Strategy Routine

PASS:           cx:dx   -> buffer in which to place reason for refusal, if
                        suspension refused.
                ds      -> dgroup
RETURN:         carry set on refusal
                        cx:dx   <- buffer null terminate reason
                carry clear if accept suspend
DESTROYED:      allowed: ax, di
SIDE EFFECTS:   none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/19/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
refusalNotice   char    "DAC on SoundBlaster is currently active",0
SBDSuspend      proc    far
        .enter
        tst     ds:[streamSegment]
        clc
        jz      done

        mov     ax, cs                          ; ds:si <- refusal notice
        mov     ds, ax
        mov     si, offset refusalNotice

        mov     es, cx                          ; es:di <- buffer
        mov     di, dx

        mov     cx, size refusalNotice
        rep     movsb                           ; set refusal notice
        stc
done:
        .leave
        ret
SBDSuspend      endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Return for a task switch.  Re-initialize board

CALLED BY:      Strategy Routine

PASS:           nothing
RETURN:         nothing
DESTROYED:      allowed: ax, di
SIDE EFFECTS:
                sets up board to where it was after we last left it.

PSEUDO CODE/STRATEGY:
                as idata has been changed to keep up with the board,
                we just call SBDInitBoardFM.  This will run through
                all the registers setting them to the values we
                last had in them.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/19/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDUnsuspend    proc    far
        .enter
        call    SBDInitBoard
        .leave
        ret
SBDUnsuspend    endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Determine if the board is of propper type

CALLED BY:      Strategy Routine
PASS:           dx:si   -> pointer to null-terminate device name string

RETURN:         ax      <- DevicePresent
                carry set if DP_INVALID_DEVICE,
                carry clear otherwise

DESTROYED:      di
SIDE EFFECTS:
                Determines if the particular device is here

PSEUDO CODE/STRATEGY:
                Currently, the only way I know of to determine if
                the device is functioning is to look in the autoexec.bat.

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/19/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDTestDevice   proc    far
        uses    cx, ds, es
        .enter
        EnumerateDevice SoundExtendedInfoSegment
        jc      done

        call    MemUnlock               ; unlock resource

        ;
        ;  Well, somone wanted to select some sort of soundblaster.
        ;  It might be possible to see if its there, but I
        ;       don't know how...
        mov     ax, DP_CANT_TELL                ; who knows....
done:
        .leave
        ret
SBDTestDevice   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SBDSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Sets up which of the devices were are supposed to support

CALLED BY:      Strategy Routine

PASS:           dx.si   -> null terminated device name string
RETURN:         nothing
DESTROYED:      nothing
SIDE EFFECTS:
                none

PSEUDO CODE/STRATEGY:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        TS      8/19/92         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBDSetDevice    proc    far
        uses    ax, cx, ds, es
        .enter
        EnumerateDevice SoundExtendedInfoSegment
        jc      done

        call    MemUnlock               ; unlockResource

        call    SBDInitBoard            ; set up everything
done:
        .leave
        ret
SBDSetDevice    endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the DOS environment string

CALLED BY:	SBDInitBoard

PASS:		ds	-> dgroup

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Assigns values to defaults

PSEUDO CODE/STRATEGY:
		Read in blaster environment string
		Parse string looking for:
			Axxx		= xxxh base address
			Ixx		= xxh IRQ level
			Dxx		= xxh DMA channel

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/16/94    	Initial version
	DL	10.12.97	šbernahme aus Falks SB16-Code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dosEnvironName		char	"BLASTER",0
DOS_ENVIRON_BUFFER_SIZE	equ	80			; one full line...

GetDefaultSettings	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
	.enter
	;
	;  Allocate space on stack for buffer
	mov	cx, DOS_ENVIRON_BUFFER_SIZE		; cx <- size of buffer
	sub	sp, cx					; allocate space
	mov	di, ss
	mov	es, di					; es:di <- buffer
	mov	di, sp

	;
	;  Try to find the enviroment variable
        push    ax
        mov     ax, cs
        mov     ds, ax
        mov     si, offset dosEnvironName
        pop     ax
	call	SysGetDosEnvironment		; carry set on error
	jc	done		; => no such variable found

	;
	;  Get the length of the environment string so that
	;  we know when we have parsed all the tokens (we mangle
	;  the string as we go along making this the easiest way
	;  to determine when we are through...)
	segmov	ds, es, cx				; ds:di <- buffer
	call	LocalStringSize		; cx <- # of bytes in string
	inc	cx					; include null

	;
	;  Parse the string into its component pieces, and see which,
	;  if any, are relevent to our needs...
	mov	al, es:[di]				; al <- 1st char

	cmp	al, C_SPACE
	je	skipWhiteSpace	; => skip white space
	cmp	al, C_TAB
	jne	firstNonWhite	; => read 1st token

skipWhiteSpace:
	;
	;  Remove white-space between tokens.  White space
	;  is defined as: Spaces & Tabs.
	mov	al, C_SPACE
	repe	scasb

	mov	al, es:[di]-1				; al <- possible token

	cmp	al, C_TAB
	je	skipWhiteSpace	; => more whitespace

	tst	al
	jz	done		; => terminating null

	dec	di					; read one too many...
	inc	cx

firstNonWhite:
	;
	;  We have found an interesting character.
	;  At this point:
	;	al    <- 1st char of token
	;	es:di <- 1st char of token
	;	cx    <- # of char left in string
	push	ax					; save 1st interest

	mov	si, di					; si <- start of token
	inc	di					; advance past 1st char

skipNonWhiteSpace:
	lodsb						; al <- next char
	dec	cx

	cmp	al, C_SPACE
	je	markWithNull	; => whitespace

	cmp	al, C_TAB
	je	markWithNull	; => whitespace

	tst	al
	jnz	skipNonWhiteSpace

markWithNull:
	mov	{byte} ds:[si]-1, ah			; null termined token

	pop	ax					; restore 1st interest

	;
	;  Now that we have an isolated null terminated string,
	;  determine if the token is for a parameter we recognize,
	;  or if it something else...
	;  At this point:
	;	al    <- 1st token of char
	;	ds:di <- char after 1st char in token
	;	cx    <- # of char after this token

	cmp	al, C_CAP_A	; => Base IO Address
	je	readAddress
	cmp	al, C_SMALL_A
	je	readAddress

        cmp     al, C_CAP_D     ; => DMA Channel 8 bit
	je	readDMA
	cmp	al, C_SMALL_D
	je	readDMA

	cmp	al, C_CAP_I	; => IRQ level
	je	readIRQ
	cmp	al, C_SMALL_I
	je	readIRQ

continueSearch:
	jcxz	done		; => reached end of string

	mov	di, si					; es:di <- after null
	jmp	skipWhiteSpace

done:
	add	sp, DOS_ENVIRON_BUFFER_SIZE
	.leave
	ret

readAddress:
	;
	;  Read the Base Address of the card from the string of the
	;  form Axxx, where xxx is a the HEX address of the card.
	mov	bx, offset basePortAddress

readHex::
	push	si
	mov	si, di

	;
	;  Well, we need to read HEX values here, not decimal,
	;  so we get to to play the "parse the string" game...
	clr	dx
	lodsb					; al <- 1st numeral

readHexNumeral:
	sub	al, '0'				; convert from char to #
	or	dl, al				; OR into low nibble

	lodsb					; al <- next numeral

	tst	al
	jz	storeValue	; => null read

	shl	dx, 1				; shift over 4 bits
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1
	jmp	readHexNumeral

readDMA:
	;
	;  Read the DMA channel for the low 8-bits of the DAC.
	;  This is stored in a string of the form: Dx, where x is
	;  the decimal representation of the DMA channel
        mov     bx, offset baseDMAChannel
	jmp	short readDecimal

readIRQ:
	;
	;  Read the IRQ level for the DAC.  This is stored in a
	;  string of the form: Ixx, where xx is the decimal
	;  representation of the IRQ level.
	mov	bx, offset baseInterruptLevel

readDecimal:
	push	si
	mov	si, di

	call	UtilAsciiToHex32

	jc	useDefault	; => error reading number

	mov_tr	dx, ax

storeValue:
	push	ds
	mov	si, segment dgroup
	mov	ds, si
	mov	ds:[bx], dx
	pop	ds

useDefault:
	pop	si
	jmp	short continueSearch
GetDefaultSettings	endp

;-----------------------
;   Delay Subroutine
;
; bis Rel. 0.12.2.X
; 8 mal jmp $+2
; TimerSleep() is not
; usable for this !
;-----------------------

WaitPerJump proc near
	.enter

        push	ax

	mov	ax,10000
next:
        dec	ax
        jnz	next

        pop	ax

;        jmp     $+2
;        jmp     $+2
;        jmp     $+2
;        jmp     $+2
;        jmp     $+2
;        jmp     $+2
;        jmp     $+2
;        jmp     $+2

        .leave
        ret

WaitPerJump	endp


InitCode        ends

