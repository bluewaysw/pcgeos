
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobEndDotMatrix.asm

AUTHOR:		Dave Durran, 8 Sept 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	 Dave	3/92		Initial revision from epson24Setup.asm
	 Dave	5/92		Parsed up from printcomEpsonSetup.asm


DESCRIPTION:
		

	$Id: jobEndDotMatrix.asm,v 1.1 97/04/18 11:50:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do post-job cleanup

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	09/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEndJob	proc	far
	uses	ax,bx,cx,dx,ds,es
	.enter
		

	mov	es,bp			;es --> PState
	mov	bx,es:PS_deviceInfo	;get the device specific info.
	call	MemLock
	mov	ds,ax			;segment into ds.
	mov	ax,ds:PI_customExit	;get address of any custom routine.
	call	MemUnlock

	test	ax,ax			;see if a custom routine exists.
	je	useStandard		;if not, skip to use standard init.
	jmp	ax			;else jmp to the custom routine.
					;(It had better jump back here to
					;somwhere in this routine or else
					;things will get ugly on return).

useStandard:
	; clear out any styles left over

	call	PrintClearStyles
	clc			; no problems
	call	PrintResetPrinterAndWait ;init the printer hardware and exit.
EndExit		label	near
	.leave
	ret
PrintEndJob	endp

