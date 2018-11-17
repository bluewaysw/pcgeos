COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		dmaLoadDriver.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial version


DESCRIPTION:

	$Id: dmaLoadDriver.asm,v 1.1 97/04/18 11:49:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintLoadDMADriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Load the DMA driver

CALLED BY:      PrintInitDMA
PASS:           es = PState segment
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
	Dave	4/93		modified to use with the print drivers.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dmaDriverCategory       char    "dma",0
dmaDriverKey            char    "driver",0
EC<dmaDriverDefault     char    "dosreale.geo",0>
NEC<dmaDriverDefault    char    "dosreal.geo",0>
PrintLoadDMADriver   proc    near
        uses    ax, bx, cx, dx, di, si, ds, es, bp
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
        mov     di, offset [PS_redwoodSpecific].RS_driverNameBuffer  ; es:di <- driverNameBuffer

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

        movdw   es:[PS_redwoodSpecific].[RS_DMADriver],ds:[si].DIS_strategy, ax
        mov     es:[PS_redwoodSpecific].[RS_DMAHandle], bx

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
PrintLoadDMADriver   endp
