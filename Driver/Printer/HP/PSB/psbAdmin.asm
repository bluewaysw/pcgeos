
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		psbAdmin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	PrintInit	initialize the driver, called once by OS at load time

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	2/90	initial version

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: psbAdmin.asm,v 1.1 97/04/18 11:52:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver

CALLED BY:	GLOBAL
		(PC GEOS kernel at load time)

PASS:		nothing

RETURN:		carry	- clear signalling successful init

DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
	Initialize driver local variable space;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintInit	proc	near

		; clear carry to signal successful init

		clc
		ret
PrintInit	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the driver

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
	Clean up anything before getting killed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintExit	proc	near

	ret

PrintExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInitStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do any stream-type, device specific initialization required

CALLED BY:	INTERNAL
		PrintSetStream

PASS:		ds	- points to locked PState
			- contains valid PS_streamType, PS_streamToken and
			  PS_streamStrategy

RETURN:		carry	- set if some transmission error from printer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		some type of required init

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInitStream	proc	near
		clc			; no errors
		ret
PrintInitStream	endp
