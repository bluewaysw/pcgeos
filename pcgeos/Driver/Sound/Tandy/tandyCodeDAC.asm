COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS Sound System	
MODULE:		Tandy 1000 Sound Driver
FILE:		tandyCodeDAC.asm

AUTHOR:		Todd Stumpf, Nov 19, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/19/92   	Initial revision


DESCRIPTION:
	Dummy routines for DAC, just incase someone tries to use us
		as a DAC driver
		
	$Id: tandyCodeDAC.asm,v 1.1 97/04/18 11:57:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment	resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDCarrySet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry set

CALLED BY:	Strategy Routine

PASS:		nothing

RETURN:		carry set

DESTROYED:	nothing

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/19/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDCarrySet	proc	near
	.enter
	stc
	.leave
	ret
TDCarrySet	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDCarryClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry clear

CALLED BY:	Strategy Routine

PASS:		nothing

RETURN:		carry clear

DESTROYED:	nothing

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/19/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDCarryClear	proc	near
	.enter
	clc
	.leave
	ret
TDCarryClear	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDClearCXAndDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return cx and dx clear

CALLED BY:	Strategy Routine

PASS:		nothing

RETURN:	
		dx	<- clear
		cx	<- clear

DESTROYED:
		nothing

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/19/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDClearCXAndDX	proc	near
	.enter
	clr	cx, dx
	.leave
	ret
TDClearCXAndDX	endp

ResidentCode		ends


