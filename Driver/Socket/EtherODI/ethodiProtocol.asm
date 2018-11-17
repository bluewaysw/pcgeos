COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet ODI link driver
FILE:		ethodiProtocol.asm

AUTHOR:		Todd Stumpf, Jul 30th, 1998

ROUTINES:

REVISION HISTORY:

DESCRIPTION:

	This file contains the code needed to actually implement
	an ODI protocol stack as a way of transmitting and
	receiving ethernet packets



	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResidentCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIRegisterProtoStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish communicaiton with LSL, and register stack

CALLED BY:	EtherInit

PASS:		DS	-> DGROUP
RETURN:		carry set on error
DESTROYED:	AX, BX, CX, DX, SI, DI, ES, DS
		BP preserved

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EthODICntrlHandler	proc	far
		uses	ax, ds
		.enter
	;
	;  Nice little NOP until we can figure out what the heck is
	;  going on...
		GetDGroup	ds, ax
		mov	ax, -1
		mov	ds:[cntrlEverCalled], ax

		.leave
		ret
EthODICntrlHandler	endp

ResidentCode		ends