
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	11/92		Initial revision 


DESCRIPTION:
		

	$Id: jobStartRedwood.asm,v 1.1 97/04/18 11:51:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		dx:si	- Job Parameters block
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	09/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

printerCategory	byte	"printer",0
ioaddKey	byte	"ioAddress",0

PrintStartJob	proc	far
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	es, bp			;point at PState.

		;init no DMA driver loaded.
	mov	es:[PS_redwoodSpecific].RS_initialPass,TRUE

	mov	bx,es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds,ax			;segment into ds.
	mov	al,ds:PI_type		;get the printer type field.
	mov	ah,ds:PI_smarts		;get the printer smarts field.
	mov {word} es:PS_printerType,ax	;set both in PState.
	call	MemUnlock


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


	; initialize the printer

	mov	dx,es:[PS_redwoodSpecific].RS_gateArrayBase
	add	dx,HCM2
	clr	al			;set up the command reg.
	call	HardwareDelayLoop
	out	dx,al			;no interrupts.
	call	HardwareDelayLoop

	mov	si,offset pr_codes_ResetPrinter
	call	SendCodeOut

	mov	si,offset pr_codes_InitSpeed	;assume hi quality...
	cmp	es:PS_mode,PM_GRAPHICS_HI_RES
	je	setTheSpeed
	mov	si,offset pr_codes_InitDraftSpeed
setTheSpeed:
        call    SendCodeOut

	mov     es:[PS_redwoodSpecific].RS_direction,0 ;set forward printing.
	mov	si,offset pr_codes_SetForward
	call	SendCodeOut
		

	;load the paper path variables from the Job Parameters block

	mov	es:[PS_redwoodSpecific].RS_savedErrorStatus,0
	clr	ax			;dummy clear.
	call	PrintSetPaperPath


	; initialize some info in the PState

	clr	ax
	mov	es:[PS_asciiStyle], ax		; set to plain text
	mov	es:[PS_redwoodSpecific].RS_yOffset,ax ;set no y offset for
							;graphics
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0
	mov	es:[PS_cursorPos].P_y, ax

	mov	es:[PS_redwoodSpecific].RS_outputBuffer, \
			PR_OUTPUT_BUFFER_START_SEG
ifdef	REDWOOD_PROTOTYPE
	mov	al,SCAT_ICR_SHADOW_RAM1
	out	SCAT_ICR_INDEX,al
	mov	al,030h				;enable b000-b7ff
	out	SCAT_ICR_DATA,al
endif


	clc

exit:
	.leave
	ret

error:
	stc
	jmp	exit
PrintStartJob	endp
