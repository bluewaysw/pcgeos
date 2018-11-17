COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         Brother NIKE 56-jet print driver
FILE:           nike56Escapes.asm

AUTHOR:         Dave Durran

ROUTINES:
	Name			Description
	----			-----------
    INT PrintWaitForMechanism   Wait for the printer mechanical movement to
				stop.
    INT PrWaitForMechanismLow   Wait for the printer mechanical movement to
				stop.
    INT PrintGetErrors          query the print engine for any errors.
    INT PrintGetErrorsLow       query the print engine for any errors.
    INT PrintInitPrintEngine    Initialize the printer engine without
				starting a print job.
    INT PrintParkHead           Position the printhead off the printable area
    INT PrintMoveInXOnly        Position the printhead on the printable area
    INT PrintMoveInYOnly        Position the printhead on the printable area
    INT PrintInsertPaper        Position the paper on the printable area
    INT PrintEjectPaper         Eject the paper.
    INT PrintCapHead            cap the printer's head
    INT PrintGetJobStatus       Return the state of the job.
    INT PrintSetJobStatus       Set the dgroup variable
    INT PrintChangeInkCartridge	Change ink cartridge
    INT PrintCleanPrintHead	Clean print head

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    10/94          Initial revision


DESCRIPTION:
        This file contains the ESCAPE routines:	

        $Id: nike56Escapes.asm,v 1.1 97/04/18 11:55:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintWaitForMechanism
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Wait for the printer mechanical movement to stop.

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		carry set if timed out
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintWaitForMechanism	proc	far
	call	PrWaitForMechanismLow
	ret
PrintWaitForMechanism	endp

PrWaitForMechanismLow	proc	near
	uses	ax,cx
	.enter

	mov	cx,40			;1/4 x 40 = 10 sec
testAgain:
	mov	ah,PB_GET_PRINTER_STATUS
	call	PrinterBIOSNoDMA
	test	ax,mask PER_BUSY	;see if the print engine is doing
	jnz	exit			;carry clear

	mov	ax,15
	call	TimerSleep		;wait 1/4 sec.
	loop	testAgain

	mov	cx, CPMSG_TIMEOUT
	call	PrintErrorBox
	call	PrintInitPrintEngine
	stc				;fail test....
exit:
	.leave
	ret
PrWaitForMechanismLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintGetErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       query the print engine for any errors.

CALLED BY:      PRINT ESCAPE CALL or INTERNAL (PrintGetErrorsLow)

PASS:		al	- PrintJobLPESUpdate to decide whether or not to 
				update the LPES
		(PrintGetErrors)
		bp      - PState segment
		(PrintGetErrorsLow)
		es      - PState segment

RETURN:	
		ax	= error codes from Printer BIOS
			  according to PErrorBits and PErrorBitsHi records

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintGetErrors	proc	far
	uses	es
	.enter

	mov	es,bp			;es--> PState
	call	PrintGetErrorsLow

	.leave
	ret
PrintGetErrors	endp

PrintGetErrorsLow	proc	near
	uses	bx
	.enter

	mov	bh,al			;save LPES update flag
	mov	ah,PB_GET_PRINTER_STATUS
	int	17h
	mov	bl,al			;save the output for rearrainging al
	and	ax,mask PER_ACK or mask PER_BUSY or mask PEF_INIT
					;clear off high bits of return
					;and low byte for re arraingement.
					;(bits 6, 7 and 8 returned unchanged)
	rcr	bl,1			;check jam bit
	jnc	afterJam
	or	al,mask PER_JAM		;set jam bit.
afterJam:
	rcr	bl,1			;check paper feed.
	rcr	bl,1			
	jnc	afterASF
	or	al,mask PER_ASF		;set ASF installed
afterASF:
	rcr	bl,1			;check error locating home
	jnc	afterHome
	or	ax,mask PEF_STARTUP_ERROR	;set startup error.
afterHome:
	rcr	bl,1			;check cartridge type
	jnc	afterCart
	or	ax,mask PEF_COLOR	;set color cart.
afterCart:
	rcr	bl,1			;check paper out
	jnc	afterPaper
	or	al,mask PER_PES or mask PER_MPE ;set paper out
afterPaper:
	and	es:PS_dWP_Specific.DWPS_savedErrorStatus,not mask PER_PAUSE
					;clean out the pause flag.

		;set the last PES flag based on the passed command.
	test	es:PS_dWP_Specific.DWPS_savedErrorStatus,mask PER_LAST_PES
	jnz	afterLPES
	or	al,mask PER_LAST_PES		;set lastPES state.

afterLPES:
	cmp	bh,PJLP_update		;do we set LPES this time?
	je	saveAndExit			;if so, just save and exit
		;otherwise, we need the last PER_LAST_PES to add into the 
		;returned and saved flags.
	and	al,not mask PER_LAST_PES	;clear out old bit
	test	es:PS_dWP_Specific.DWPS_savedErrorStatus,mask PER_LAST_PES
	jz	saveAndExit		;if saved is zero nothing to do.
	or	al,mask PER_LAST_PES	;else, set the saved bit.

saveAndExit:
	mov	es:PS_dWP_Specific.DWPS_savedErrorStatus,ax
	clc

	.leave
	ret
PrintGetErrorsLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintInitPrintEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Initialize the printer engine without starting a print
			job.

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintInitPrintEngine	proc	far
	uses	ax
	.enter

	mov	ah,PB_INITIALIZE_PRINTER
	call	PrinterBIOS

	.leave
	ret
PrintInitPrintEngine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintParkHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Position the printhead off the printable area

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintParkHead	proc	far
	uses	ax,cx
	.enter

	call	PrWaitForMechanismLow
	jc	exit

	clr	cx
	mov	ah,PB_POSITION_CARRIAGE
	call	PrinterBIOS
exit:
	.leave
	ret
PrintParkHead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintMoveInXOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Position the printhead on the printable area

CALLED BY:      PRINT ESCAPE CALL

PASS:		cx.si	- WWFixed position in points for x position
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintMoveInXOnly	proc	far
	uses	ax,cx,dx
	.enter

	call	PrWaitForMechanismLow
	jc	exit

	mov	dx,cx		;and integer into dx
	mov	ax,si		;mov fraction into ax
	call	PrConvertToDriverCoordinates
	mov	cx,dx		;move the head to cx column

	mov	ah,PB_POSITION_CARRIAGE
        call    PrinterBIOS
exit:
	.leave
	ret
PrintMoveInXOnly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintMoveInYOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Position the printhead on the printable area

CALLED BY:      PRINT ESCAPE CALL

PASS:		dx.ax	- WWFixed position in points for y position
		bp      - PState segment
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    1/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintMoveInYOnly	proc	far
	uses	dx,es
	.enter

	mov	es,bp			;es--> PState
	call	PrConvertToDriverCoordinates
	sub	dx,es:[PS_cursorPos].P_y ;see if the position desired is below
	jz	exit			;dont update position if zero.

	call	PrLineFeed		;adjust the position in PSTATE and
					;the printhead position.
exit:
	.leave
	ret
PrintMoveInYOnly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintInsertPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Position the paper on the printable area

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintInsertPaper	proc	far
	uses	ax
	.enter

	call	PrWaitForMechanismLow
	jc	exit

        mov     ah,PB_INSERT_PAPER	;load the paper.
        call    PrinterBIOS
exit:
	.leave
	ret
PrintInsertPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEjectPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Eject the paper.

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEjectPaper	proc	far
	uses	ax
	.enter

	call	PrWaitForMechanismLow
	jc	exit

	mov	ah,PB_EJECT_PAPER	;spit the paper out.
	call	PrinterBIOS
exit:
	.leave
	ret
PrintEjectPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintCapHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       cap the printer's head

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		nothing
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
		Directly have the printer cap the printhead, and wait for the 
		mechanism to stop.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    08/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCapHead	proc	far
	uses	ax
	.enter

	call	PrWaitForMechanismLow
	jc	exit

	mov	ah,PB_CAP_PRINT_HEAD
	call	PrinterBIOS
exit:
	.leave
	ret
PrintCapHead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintGetJobStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Return the state of the job.

CALLED BY:      PRINT ESCAPE CALL

PASS:		nothing
RETURN:		al - PrintJobSemaphore enum
DESTROYED:      ah

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    1/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintGetJobStatus	proc	far
	uses	ds
	.enter

	segmov	ds, dgroup, ax
	mov	al, ds:[jobStatus]

	.leave
	ret
PrintGetJobStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetJobStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the dgroup variable

CALLED BY:	PRINT ESCAPE CALL

PASS:		al	- PrintJobSemaphore enum
RETURN:		nothing 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/10/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
jobStatus	byte	0
idata	ends

PrintSetJobStatus	proc far
	uses	ds, bx
	.enter

	segmov	ds, dgroup, bx
	mov	ds:[jobStatus], al

	.leave
	ret
PrintSetJobStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintChangeInkCartridge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change ink cartridge

CALLED BY:	DR_PRINT_ESC_CHANGE_INK_CARTRIDGE
PASS:		nothing
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintChangeInkCartridge	proc	far
	uses	ax,cx
	.enter

	call	PrWaitForMechanismLow
	jc	done

	mov	ah, PB_CHANGE_INK_CARTRIDGE
	call	PrinterBIOS

	call	PrWaitForMechanismLow
	jc	done

	; Put up dialog telling user to change the ink cartridge

	mov	cx, CPMSG_CHANGE_CARTRIDGE
	call	PrintErrorBox

	; Now re-initialize the printer

	call	PrintInitPrintEngine
done:
	.leave
	ret
PrintChangeInkCartridge	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintCleanPrintHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean print head

CALLED BY:	DR_PRINT_ESC_CLEAN_HEAD
PASS:		nothing
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintCleanPrintHead	proc	far
	uses	ax
	.enter

	call	PrWaitForMechanismLow
	jc	done

	mov	ah, PB_CLEAN_PRINT_HEAD
	call	PrinterBIOS
done:
	.leave
	ret
PrintCleanPrintHead	endp
