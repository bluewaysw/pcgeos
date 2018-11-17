COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		textSetSymbolSet.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintSetSymbolSet	Set up the symbol set to use in the printer

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/92		Initial Version


DESCRIPTION:

	$Id: textSetSymbolSet.asm,v 1.1 97/04/18 11:50:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetSymbolSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the printers Symbol set up and match it with the 
		PState ASCII Translation Table.

CALLED BY: 	INTERNAL PrintStyleRun

PASS: 		es	- Segment of PSTATE

RETURN: 	carry	- set if some error sending string to printer

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version
	Don	10/93		Initialized FE_styles & FE_stylesSet and
				also always unlock the PS_deviceInfo block
	Dave	10/94		Got rid of Big Don fix for FontEntry, moved to
				StartJob routine specific to PCL drivers.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetSymbolSet	proc	near
	uses	ax,bx,si,ds
	.enter

        mov     bx,es:[PS_deviceInfo]   ; handle to info for this printer.
        call    MemLock
	mov	ds,ax			;address into ds
	mov	si,ds:[PI_fontSymbolSets] ;offset to table of pointers to 
					;control codes.
	ornf	si,si		;see if null.
	jz	unlockDeviceInfo ;if unavailable, leave default in from setfont
        mov     bx,es:[PS_jobParams].[JP_printerData].[PUID_symbolSet]
	mov	si,ds:[si].[bx]	;get offset to code page selection code.
	ornf	si,si		;see if null.
	jz	unlockDeviceInfo ;if unavailable, leave default in from setfont
	mov	es:[PS_curFont].FE_symbolSet,bx	;set in PState
	call	SendCodeOut	;set in printer.
unlockDeviceInfo:
        mov     bx,es:[PS_deviceInfo]   ; handle to info for this printer.
        call    MemUnlock

	.leave
	ret
PrintSetSymbolSet	endp
