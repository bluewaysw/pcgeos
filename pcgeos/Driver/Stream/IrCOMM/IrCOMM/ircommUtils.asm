COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		ircommUtils.asm

AUTHOR:		Greg Grisco, Dec  4, 1995

ROUTINES:
	Name				Description
	----				-----------
EXT	IrCommGetDGroupDS		Loads dgroup into DS
EXT	IrCommGetDGroupES		Loads dgroup into ES
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 4/95   	Initial revision


DESCRIPTION:
	Utility routines for IrCOMM module
		

	$Id: ircommUtils.asm,v 1.1 97/04/18 11:46:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ResidentCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommGetDGroupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads dgroup into DS

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing
SIDE EFFECTS:	

	flags preserved

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommGetDGroupDS	proc	far
	uses	bx
	.enter
	mov	bx, handle dgroup
	call	MemDerefDS			;flags preserved
	.leave
	ret
IrCommGetDGroupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommGetDGroupES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads dgroup into ES

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		es	= dgroup
DESTROYED:	nothing
SIDE EFFECTS:	

	flags preserved

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	 1/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommGetDGroupES	proc	far
	uses	bx
	.enter

	pushf
	mov	bx, handle dgroup
	call	MemDerefES
	popf

	.leave
	ret
IrCommGetDGroupES	endp

ResidentCode	ends
