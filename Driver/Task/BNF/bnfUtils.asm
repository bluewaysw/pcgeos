COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bnfUtils.asm

AUTHOR:		Adam de Boor, May 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/29/92		Initial revision


DESCRIPTION:
	Utility routines, of course.
		

	$Id: bnfUtils.asm,v 1.1 97/04/18 11:58:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BNFCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call Back & Forth

CALLED BY:	EXTERNAL
PASS:		bx	= BackAndForthAPI member
		other regs as appropriate
RETURN:		whatever
DESTROYED:	ax, bx, dx may all be biffed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BNFCall		proc	far
		uses	cx, si, di, ds, es
		.enter
	;
	; AX & CX always get BNF_MAGIC
	; 
		mov	ax, BNF_MAGIC
		mov	cx, ax
	;
	; Grab BIOS and make the call.
	; 
		call	SysLockBIOS
		int	12h
		call	SysUnlockBIOS
		.leave
		ret
BNFCall		endp

Resident	ends
