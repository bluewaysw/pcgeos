
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartDefeatPaperout.asm

AUTHOR:		Dave Durran, 8 Sept 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	3/92		Initial revision from epson24Setup.asm
	 Dave	3/92		Parsed from epson24Setup.asm


DESCRIPTION:
		

	$Id: jobStartDefeatPaperout.asm,v 1.1 97/04/18 11:50:59 newdeal Exp $

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

PrintStartJob	proc	far
	uses	ax,bx,cx,dx,si,di,es
	.enter

	mov	es, bp			;point at PState.

	mov	bx,es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds,ax			;segment into ds.
	mov	al,ds:PI_type		;get the printer smarts field.
	mov	ah,ds:PI_smarts		;get the printer smarts field.
	mov {word} es:PS_printerType,ax	;set both in PState.
	mov	ax,ds:PI_customEntry	;get address of any custom routine.
	call	MemUnlock

	test	ax,ax			;see if a custom routine exists.
	je	useStandard		;if not, skip to use standard init.
	jmp	ax			;else jmp to the custom routine.
					;(It had better jump back here to
					;somwhere in this routine or else
					;things will get ugly on return).

useStandard:

        call    PrintResetPrinterAndWait ;init the printer hardware

	; Initialize the paper path.

	;load the paper path variables from the Job Parameters block

	mov	al,es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
	clr	ah
	call	PrintSetPaperPath

	; initialize some info in the PState

	clr	ax
	mov	es:[PS_asciiSpacing], 12	; set to 1/6th inch
	mov	es:[PS_asciiStyle], ax		; set to plain text
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0 text
	mov	es:[PS_cursorPos].P_y, ax
	not	ax				;set to ffff
	mov	es:[PS_previousAttribute],ax

	;initialize the character set .....
	;garbage the symbol set enum so that it loads during SetFont
	mov	es:[PS_curFont].FE_symbolSet,ax	;ax = ffff from above.

	; initialize the font

        mov     cx,FID_DTC_URW_ROMAN   ;load the desired font ID.
        mov     dx,12                   ;12 point font.
	mov	bl,TP_10_PITCH		;10 pitch fixed font
        call    PrintSetFont            ;set the font.


		; set  up init codes (assuming graphic printing)
	mov	si,offset pr_codes_InitPrinter
	call	SendCodeOut
	jc	exit

		; check for a text mode, and set any text specific modes.
	cmp	es:[PS_mode],PM_FIRST_TEXT_MODE
	jb	printerInitialized
	mov	si,offset pr_codes_InitTextMode
	call	SendCodeOut
	jc	exit
printerInitialized:

	;send the code to defeat the paper out sensor, if in cut
	;sheet mode. (not in tractor mode)

	test	es:[PS_paperInput],mask PIO_TRACTOR
	clc
	jnz	exit
	mov	si, offset pr_codes_DefeatPaperOut
	call	SendCodeOut

exit:

	.leave
	ret
PrintStartJob	endp
