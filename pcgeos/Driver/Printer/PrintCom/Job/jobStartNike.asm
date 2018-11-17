COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	10/94		Initial revision 


DESCRIPTION:
		

	$Id: jobStartNike.asm,v 1.1 97/04/18 11:51:04 newdeal Exp $

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
	Dave	10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartJob	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

		;init no DMA driver loaded.
	mov	es, bp			;point at PState.
	mov	es:[PS_dWP_Specific].DWPS_initialPass,TRUE

	mov	bx,es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds,ax			;segment into ds.
	mov	al,ds:PI_type		;get the printer type field.
	mov	ah,ds:PI_smarts		;get the printer smarts field.
	mov	{word} es:PS_printerType,ax	;set both in PState.
	call	MemUnlock

	; Ensure that it's clear that the printer is not in use.  The print
	; driver's semaphore is usually locked and unlocked by the spooler,
	; but we need a reasonable initial value, and it's easiest to do it
	; here.  -cbh 2/15/94
	;
        mov     es:[PS_dWP_Specific].DWPS_jobSem,PJS_unlocked

	;set the paper path variables

	mov	ds, dx			;ds:si <- JobParameters
	mov	al, ds:[si][JP_printerData].[PUID_paperInput]
	mov	ah, ds:[si][JP_printerData].[PUID_paperOutput]
	call	PrintSetPaperPath

	; initialize some info in the PState

	clr	ax
	mov	es:[PS_asciiStyle], ax		; set to plain text
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0
	mov	es:[PS_cursorPos].P_y, ax
	mov	es:PS_dWP_Specific.DWPS_savedErrorStatus,ax

	; create fixed buffers for printing

	call	PrCreateRotateBuffers
	call	PrCreatePrintBuffers

	; now find home position before we start printing

	call	PrWaitForMechanismLow

	mov	ah, PB_FIND_HOME_POSITION
	call	PrinterBIOS

	call	PrintCapHead		; and re-cap the printhead

	.leave
	ret
PrintStartJob	endp
