
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         redwood print driver
FILE:           red64Escapes.asm

AUTHOR:         Dave Durran

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    8/93          Initial revision


DESCRIPTION:
        This file contains the ESCAPE routines:

	PrintSetTOD
	PrintCapHead
	PrintCleanHead
	PrintGetErrors
	PrintWaitForMechanism
	PrintInitPrintEngine
	PrintParkHead
	PrintMoveInXOnly
	PrintMoveInYOnly
	PrintInsertPaper
	PrintEjectPaper
	PrintGetJobStatus

        $Id: red64Escapes.asm,v 1.1 97/04/18 11:55:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintSetTOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       set the printers TOD from the GEOS values.

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
		Use DOS or GEOS time to set the TOD in the printer engine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    08/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetTOD	proc	far
	uses	ax,bx,cx,dx,si,es
	.enter
	mov	es,bp			;es-->PState
	mov	si,offset pr_codes_SetTOD ;start sending the control code.
	call	SendCodeOut
	jc	exit			;pass any errors out.
	call	TimerGetDateAndTime	;get the GEOS saved time and date.
	cmp	ax,2000
	jge	sub2k
	sub	ax,1900			;adjust awy all those high digits.
	jmp	yearAdjusted
sub2k:
	sub	ax,2000
yearAdjusted:
	call	PrintByteToBCD
	call	ControlByteOut		;al = year
	jc	exit
	mov	al,bl			;al = month
	call	PrintByteToBCD
	call	ControlByteOut
        jc      exit
	mov	al,bh			;al = day
	call	PrintByteToBCD
        call    ControlByteOut
        jc      exit
	mov	al,ch			;al = hours
	call	PrintByteToBCD
        call    ControlByteOut
        jc      exit
	mov	al,dl			;al = minutes
	call	PrintByteToBCD
        call    ControlByteOut
        jc      exit
	mov	al,dh			;al = seconds
	call	PrintByteToBCD
        call    ControlByteOut
exit:
	.leave
	ret
PrintSetTOD	endp

PrintByteToBCD	proc	near
	uses	bx
	.enter
		;al	=	byte to convert to BCD
	mov	bh,al
	clr	bl
checkTens:
	sub	bh,10		;sub 10 from the input.
	js	checkOnes
	add	bl,010h		;add hex 10, to add to the 10s place
	mov	al,bh		;store the new value.
	jmp	checkTens
checkOnes:
		;use the last valid value, before a borrow
	dec	al
	js	done
	inc	bl
	jmp	checkOnes
done:
	mov	al,bl
	.leave
	ret
PrintByteToBCD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintCapHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       cap the printer's head

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

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
	uses	si,es
	.enter
	mov	es,bp			;es-->PState
	call	PrintWaitTillReady
	jc	exit
	mov	si,offset pr_codes_CapHead
	call	SendCodeOut
	jc	exit
	call	PrintWaitTillReady
exit:
	.leave
	ret
PrintCapHead	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintCleanHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       clean the head

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
		Directly have the printer clean the printhead

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    08/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintCleanHead	proc	far
	uses	si,es
	.enter
	mov	es,bp			;es-->PState
	mov	si,offset pr_codes_CleanHead
	call	SendCodeOut
	.leave
	ret
PrintCleanHead	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintGetErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       query the print engine for any errors.

CALLED BY:      PRINT ESCAPE CALL

PASS:		al	- PrintJobLPESUpdate to decide whether or not to 
				update the LPES
		bp      - PState segment

RETURN:	
		al	=	error codes from gate array
				according to PErrorBits record
			bit0	= PES
			bit1	= MPE
			bit2	= JAM
			bit3	= LPES (saved state of last PES)
			bit4	= 1 if paused since last call to PrintGetErrors
			bit5	= 1 if ASF present
			bit6,7	= reserved

		bits 3, and 4 in the saved status byte are modified to reflect
		the new saved status by calling PrintGetErrors.
		
		The saved state of last PES bit (PER_LAST_PES) in
		RS_savedErrorStatus is modified to be the value of the
		currently read PES bit if the PJLP_update code is passed in
		al into the routine.

		The paues bit (PER_PAUSE) in RS_savedErrorStatus is always
		cleared by this routine.

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    09/93           Initial version
	Dave	03/94		Added passing in the PrintJobLPESUpdate flag

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetErrors	proc	far
	uses	bx,si,es
	.enter
	mov	es,bp			;es--> PState
	mov	bh,al			;save state of PrintJobLPESUpdate
	mov	si,offset pr_codes_GetPaperErrors
	call	SendCodeOut
	jc	exitErr
	mov	ax,1
	call	TimerSleep		;wait for things to get loaded.
	call	StatusPacketIn
	jc	exitErr
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_length,3
	jne	exitErr
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_ID,20h
	jne	exitErr
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_parameters,1
	jne	exitErr

	;If here, then the next byte contains the error codes...
	mov	al,es:[PS_redwoodSpecific].RS_status.RSB_parameters+1
	or	al,es:[PS_redwoodSpecific].RS_savedErrorStatus
	and	es:[PS_redwoodSpecific].RS_savedErrorStatus,not mask PER_PAUSE
					;wipe out state of pause bit.
	cmp	bh,PJLP_noupdate	;should we update LPES?
	je	done			;if not,skip....

	mov	bl,al
	shl	bl,1			;get PES into LPES bit position
	shl	bl,1
	shl	bl,1
	and	bl,mask PER_LAST_PES	;isolate the last PES bit.
	and es:[PS_redwoodSpecific].RS_savedErrorStatus,not mask PER_LAST_PES
					;wipe out state of LPES bit
					;The reason for the shenagagans of
					;oring into the RS_savedErrorStatus,
					;is to preserve other info, such as
					;the state of the PER_ASF bit.
	or	es:[PS_redwoodSpecific].RS_savedErrorStatus,bl ;save last PES
done:
	clc
exit:
	.leave
	ret

exitErr:
	stc
	jmp	exit
PrintGetErrors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintInitPrintEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Initialize the printer engine without starting a print
			job.

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    01/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInitPrintEngine	proc	far
	uses	ax,dx,si,es
	.enter
	mov	es,bp			;es--> PState

	; search for the gate array base address in the .INI file.

	mov	ax,02a0h		;set up default i/o add.
	mov	dx,offset ioaddKey	;set up to fetch the printers
	mov	si,offset printerCategory ;i/o address.
        segmov  ds,cs,cx                ;stuff cx, and ds with the code seg
	call    InitFileReadInteger     ;grab the value.
	mov	es:[PS_redwoodSpecific].RS_gateArrayBase,ax

	;
	; Ensure that it's clear that the printer is not in use.  The print
	; driver's semaphore is usually locked and unlocked by the spooler,
	; but we need a reasonable initial value, and it's easiest to do it
	; here.  -cbh 2/15/94
	;
        mov     es:[PS_redwoodSpecific].RS_jobSem,PJS_unlocked


	mov	dx,ax
	call	StatusByteIn
	in	al,dx

	call	PrintSetTOD
	
	; initialize the printer

	mov	dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	add	dx,HCM2
	clr	al			;set up the command reg.
	call	HardwareDelayLoop
	out	dx,al			;no interrupts.
	call	HardwareDelayLoop

	mov	si,offset pr_codes_ResetPrinter
	call	SendCodeOut

	;
	; Now, we're going to set language and mouseless versions of the 
	; system in the .ini file.   The default .ini file entries are:
	;	ini = c:\net.ini c:\us.ini
	;	drawCalcVersion = false
	;
if	0
	call	PrintGetConfig		;configuration in al

	mov	cx, cs
	mov	ds, cx
	mov	es, cx
	
	test	al, mask SC_USE_US_INI		;using us.ini, do nothing
	jnz	10$

	mov	si, offset pathsCategory		
	mov	dx, offset iniKey
	mov	di, offset ukString		;assume uk.ini

	test	al, mask SC_USE_UK_INI
	jnz	5$
	mov	di, offset oceaniaString
5$:
	
	call	InitFileWriteString

10$:
	test	al, mask SC_MOUSELESS
	jnz	20$

	mov	si, offset uiCategory
	mov	dx, offset drawCalcKey
	mov	ax, cx				;non-zero = true
	call	InitFileWriteBoolean
20$:
endif

	clc
	.leave
	ret

PrintInitPrintEngine	endp



pathsCategory	char	"paths",0
iniKey		char	"ini",0
ukString	char	"c:\\geos.ini c:\\uk.ini",0
oceaniaString	char	"c:\\geos.ini c:\\oceania.ini",0

uiCategory	char	"ui",0
drawCalcKey	char	"drawCalcVersion",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintGetConfig
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       query the print engine for the system configuration, stored
		in EEPROM byte 0.

CALLED BY:      PrintInitPrintEngine, above

PASS:		es      - PState segment

RETURN:		al 	- SysConfigBits

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    09/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetConfig	proc	near
	uses	si,es
	.enter
	mov	si,offset pr_codes_enableEEPROM
	call	SendCodeOut
	mov	si,offset pr_codes_ReadLoc00
	jc	setMouselessAmerican
	call	SendCodeOut
	jc	setMouselessAmerican
	mov	ax,20	;try this
	call	TimerSleep		;wait for things to get loaded.
	call	StatusPacketIn
	jc	setMouselessAmerican
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_length,3
	jne	setMouselessAmerican
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_ID,41h
	jne	setMouselessAmerican
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_parameters,1
	jne	setMouselessAmerican

	; If here, then the next byte contains the configuration...

	mov	al,es:[PS_redwoodSpecific].RS_status.RSB_parameters+1
	
	; Do some cleanup in case there's random data.  I.E., if there
	; are any non-zero unused bits, we'll assume mouseless and American
	
	test	al, mask SC_UNUSED
	jz	exit

setMouselessAmerican:
	or	al, mask SC_USE_US_INI or mask SC_MOUSELESS

exit:
	mov	si,offset pr_codes_disableEEPROM
	call	SendCodeOut
	.leave
	ret

PrintGetConfig	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintWaitForMechanism
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Wait for the printer mechanical movement to stop.

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
	Try to wait for the print mechanism to stop what it is doing. Try 3
	times, if all three fail then issue a carry set on exit.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    09/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintWaitForMechanism	proc	far
	uses	ax,es
	.enter
	mov	es,bp			;es--> PState
testAgain:
	call	PrintLoadStatusBuffer
	jnc	examineBuffer
	call	PrintLoadStatusBuffer
	jnc	examineBuffer
	call	PrintLoadStatusBuffer
	jc	exit
examineBuffer:
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_length,3
	jne	testAgain
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_ID,20h
	jne	testAgain
	cmp	es:[PS_redwoodSpecific].RS_status.RSB_parameters,0
	jne	testAgain
	;If here, then the next byte contains the status codes...
	test	es:[PS_redwoodSpecific].RS_status.RSB_parameters+1,1
	jnz	testAgain
exit:
	.leave
	ret
PrintWaitForMechanism	endp

PrintLoadStatusBuffer	proc	near
	mov	si,offset pr_codes_GetPrinterCondition
	call	SendCodeOut
	jc	exit
	mov	ax,1
	call	TimerSleep		;wait for things to get loaded.
	call	StatusPacketIn
exit:
	ret
PrintLoadStatusBuffer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintParkHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Position the printhead off the printable area

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    12/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintParkHead	proc	far
	uses	si,es
	.enter
	mov	es,bp			;es--> PState
	mov	si,offset pr_codes_ParkHead
	call	SendCodeOut
	.leave
	ret
PrintParkHead	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintMoveInXOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Position the printhead on the printable area

CALLED BY:      PRINT ESCAPE CALL

PASS:		cx.bx	- WWFixed position in points for x position
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

PrintMoveInXOnly	proc	far
	uses	si,es,ax,dx
	.enter
	mov	es,bp			;es--> PState
	mov	ax,bx			;mov fraction into ax
	mov	dx,cx			;and integer into dx
					;now in the correct reg for WWFixed.
		;Service the X position.
	call	PrConvertToDriverCoordinates

	add	dx,es:[PS_redwoodSpecific].RS_xOffset
					;add in the correction for the paper.
					;dx is assumed to have the correct
					;absolute position at this point.
	mov	es:[PS_cursorPos].P_x,dx ;set in PState.
	mov	si, offset pr_codes_AbsPos
	call	SendCodeOut
        mov     al,dl
        call    ControlByteOut
        mov     al,dh
        call    ControlByteOut

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
	uses	si,es,bx,cx
	.enter
	mov	es,bp			;es--> PState

		;Service the Y position.
	call	PrConvertToDriverCoordinates
	sub	dx,es:[PS_cursorPos].P_y ;see if the position desired is below
	clc				; make sure carry is clear for exiting
					; when there are no errors.  "jle" does
					; not look at the carry bit
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

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    12/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInsertPaper	proc	far
	uses	si,es
	.enter
	mov	es,bp			;es--> PState
        mov     si,offset pr_codes_ASFQuery     ;see if an ASF is hooked up.
        call    SendCodeOut                     ;send the query....
        jc      exit                            ;(errors out)
        call    StatusPacketIn                  ;...and get response from Gate
        jc      exit                            ;errors out
                ;now check the buffer for the ASF bits.
        cmp {word} es:[PS_redwoodSpecific].RS_status.RSB_length,ASF_TEST_ID
        jne     assumeASF
     cmp {word} es:[PS_redwoodSpecific].RS_status.RSB_parameters,ASF_TEST_MANUAL
        jne     assumeASF
		;if here then manual feed only
        mov     si,offset pr_codes_SetManualFeed ;load the paper, enable
						;reverse motion
	jmp	sendIt

assumeASF:
	mov	si,offset pr_codes_SetASF	;load the paper disable reverse
						;motion
sendIt:
	call	SendCodeOut
exit:
	.leave
	ret
PrintInsertPaper	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEjectPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Eject the paper.

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    12/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEjectPaper	proc	far
	uses	si,es
	.enter
	mov	es,bp			;es--> PState
	mov	si,offset pr_codes_FormFeed	;spit the paper out.
	call	SendCodeOut
	.leave
	ret
PrintEjectPaper	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintGetJobStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Return the state of the job.

CALLED BY:      PRINT ESCAPE CALL

PASS:		bp      - PState segment

RETURN:		al	- PrintJobSemaphore enum

DESTROYED:      nothing

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

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	ax

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

