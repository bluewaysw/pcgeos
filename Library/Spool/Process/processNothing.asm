COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processNothing.asm

AUTHOR:		Don Reeves, April 29, 1991

ROUTINES:
	Name			Description
	----			-----------
	InitNothingPort		do init for port
	ExitNothingPort		do exit for port
	ErrorNothingPort	do error handling for port
	VerifyNothingPort	verify that the port accessible
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision
	Don	4/29/91		Copied code from parallel

DESCRIPTION:
	This file contains the routines to initialize and close the
	nothing "port", a port whose type we do not deal with.

	$Id: processNothing.asm,v 1.1 97/04/07 11:11:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitNothingPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the port and do special serial port initialization

CALLED BY:	INTERNAL
		InitPrinterPort

PASS:		nothing

RETURN:		carry	= set if problem opening port
				ax = error type (PortErrors enum)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitNothingPort proc	near
curJob		local	SpoolJobInfo
		.enter	inherit

		clc				; signal no problem

		.leave
		ret
InitNothingPort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitNothingPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the port 

CALLED BY:	INTERNAL
		ExitPrinterPort

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExitNothingPort	proc	near
curJob		local	SpoolJobInfo
		.enter	inherit

		.leave
		ret
ExitNothingPort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyNothingPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the existance and operation of the port

CALLED BY:	INTERNAL
		SpoolVerifyPrinterPort

PASS:		portStrategy	- inherited local variable

RETURN:		carry		- SET if there is some problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For now, do nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VerifyNothingPort proc	near
portStrategy	local	fptr
		.enter	inherit

		; There is nothing to do. Just return carry clear
		;
		clc

		.leave
		ret
VerifyNothingPort endp

PrintInit	ends



PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErrorNothingPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle parallel port errors

CALLED BY:	parallel driver, via NothingErrorHandler in idata

PASS:		ds	- segment of locked queue segment
		*ds:si	- pointer to queue that is affected
		dx	- error word

RETURN:		carry	- set if print job should abort
		ds	- still points at PrintQueue (may have changed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ErrorNothingPort	proc	near
		.enter	

		stc

		.leave
		ret
ErrorNothingPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputNothingPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common input routine (not normally needed)

CALLED BY:	INTERNAL
		CommPortInputHandler
PASS:		ds:bx	- QueueInfo
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputNothingPort	proc	near
		.enter
		.leave
		ret
InputNothingPort	endp

PrintError	ends
