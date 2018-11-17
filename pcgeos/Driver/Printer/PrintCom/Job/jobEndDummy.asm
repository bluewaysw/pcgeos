
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		jobEndDummy.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial 2.0 revision


DESCRIPTION:
	This file contains various setup routines needed by the LBP printer 
	drivers.
		

	$Id: jobEndDummy.asm,v 1.1 97/04/18 11:51:01 newdeal Exp $

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
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEndJob	proc	far
	uses	ax,bx,ds,es
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
	clc			; no problems
	.leave
	ret
PrintEndJob	endp
