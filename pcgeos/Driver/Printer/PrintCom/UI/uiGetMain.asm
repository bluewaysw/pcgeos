
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		uiGetMain.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial revision


DESCRIPTION:

	$Id: uiGetMain.asm,v 1.1 97/04/18 11:50:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetMainUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:

PASS:
	bp	- Address of PSTATE

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, si, di, es, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	01/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintGetMainUI	proc	far
	uses	ax,bx,ds,es
	.enter
	mov	es,bp		;get hold of PState address.
        mov     bx,es:[PS_deviceInfo]   ; handle to info for this printer.
        call    MemLock
        mov     ds,ax                   ; ds points at device info segment.
	mov	cx,ds:[PI_mainUI].handle
	mov	dx,ds:[PI_mainUI].chunk
        call    MemUnlock       ; unlock the puppy
	clc
	.leave
	ret
PrintGetMainUI	endp
