
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobStartCapsl.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial 2.0 version from lbpSetup.asm


DESCRIPTION:
	This file contains various setup routines needed by the LBP printer 
	drivers.
		

	$Id: jobStartCapsl.asm,v 1.1 97/04/18 11:50:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStartJob	proc	far
	uses	ax,bx,cx,dx,si,di,es,ds
	.enter

	mov	es,bp			;es---> PState
	mov	bx,es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds,ax			;segment into ds.
	mov	al,ds:PI_type		;get the printer type field.
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

	; initialize the printer

	mov	si,offset pr_codes_ResetPrinter
	call	SendCodeOut
	jc	errorStep		;pass any error out.

		;initialize the number of copies.
                ;first, check for multiple copies, and non-collated.
        test    es:[PS_jobParams].JP_spoolOpts,mask SO_COLLATE
        jz      setMultCopies
        mov     ax,1
        jmp     setCopies
setMultCopies:
                ;works for up to 99 copies only!
        mov     al,es:[PS_jobParams].JP_numCopies ;value to set in printer.
        clr     ah
        mov     es:[PS_jobParams].JP_numCopies,1 ;set the PState to one pass
setCopies:
        call    PrintSetCopies          ;set the # copies in the printer.
        jc      errorStep

	;set up the paper path.
        mov     ah,es:[PS_jobParams].[JP_printerData].[PUID_paperOutput]
        mov     al,es:[PS_jobParams].[JP_printerData].[PUID_paperInput]
	call	PrintSetPaperPath

	; initialize some info in the PState

	clr	ax
	mov	es:[PS_asciiSpacing], 12	; set to 1/6th inch
	mov	es:[PS_asciiStyle], ax		; set to plain text
	mov	es:[PS_cursorPos].P_x, ax	; set to 0,0 text
	mov	es:[PS_cursorPos].P_y, ax
	not	ax				;set to $ffff
	mov	es:PS_previousAttribute,ax

	;page size, and format (portrait)....
	;test for a standard Paper size to keep the printer from
	;prompting for the new paper size
		
	mov	ax,es:[PS_customHeight]
	mov	si,offset pr_codes_InitPaperLetter
	cmp	ax,792				;hieght of letter
	je	itsStandard
	mov	si,offset pr_codes_InitPaperLegal
	cmp	ax,1008				;height of legal
	je	itsStandard
	mov	si,offset pr_codes_InitPaperA4
	cmp	ax,842				;height of A4
	je	itsStandard
	mov	si,offset pr_codes_InitPaperB5
	cmp	ax,709				;height of ISO B5
	jne	itsCustom
itsStandard:
	call	SendCodeOut
	jc	exit
	jmp	pastPaperInit
itsCustom:				;Oh Well the printer is going to 
					;prompt for the new size.....
	mov	si,offset pr_codes_InitPaperCustom
	call	SendCodeOut
errorStep:				;intermediate step for error jump.
	jc	exit
	clr	ax
	mov	dx,es:PS_customHeight	;get the paper size in points.
	call	PrConvertToDriverCoordinates	;get it to dot units.
	mov	ax,dx
	call	HexToAsciiStreamWrite
	jc	exit
	mov	cl,";"			;delimiter.
	call	PrintStreamWriteByte
	jc	exit
	mov	dx,es:PS_customWidth	;get the paper size in points.
	call	PrConvertToDriverCoordinates	;get it to dot units.
	mov	ax,dx
	call	HexToAsciiStreamWrite
	jc	exit

pastPaperInit:

	; set no perforation skipping.

	mov	si,offset pr_codes_InitPrinter
	call	SendCodeOut
	jc	exit			;pass any error out.

                ;Initialize the default symbol set for internal fonts.
        mov     ax,PSS_IBM437
        mov     es:[PS_curFont].FE_symbolSet,ax
        mov     es:[si].[JP_printerData].[PUID_symbolSet],ax
        mov     es:[si].[JP_printerData].[PUID_countryCode],PCC_USA
        call    PrintSetSymbolSet               ;set in PState
        call    PrintLoadSymbolSet              ;set up translation table

exit:

	.leave
	ret
PrintStartJob	endp
