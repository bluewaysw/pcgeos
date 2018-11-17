COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomAdmin.asm

AUTHOR:		Don Reeves, April 26, 1991

ROUTINES:
	Name		Description
	----		-----------
	PrintInit	initialize the driver, called once by OS at load time
	PrintExit	exit the driver
	PrintInitStream	initialize the stream, if necessary

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	don	4/91	initial version

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: ccomremAdmin.asm,v 1.1 97/04/18 11:52:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver

CALLED BY:	GLOBAL
		(PC GEOS kernel at load time)

PASS:		nothing

RETURN:		carry	- clear signalling successful init
			- set if the Complete Communicator is not loaded

DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
	Initialize driver local variable space;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/91		Initial version
	Don	4/91		Remove queue work

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInit	proc	near
		.enter

		call	EnsureFaxServersDefined

		.leave
		ret
PrintInit	endp

CommonCode	segment	resource

EnsureFaxServersDefined	proc far
		segmov	ds, cs, cx
		mov	si, offset printerCatString
		mov	dx, offset faxServerKeyString
		mov	bp, IFCC_INTACT shl offset IFRF_CHAR_CONVERT
		mov	di, cs
		mov	ax, offset callback
		call	InitFileEnumStringSection
		cmc
		ret

callback:
		stc
		retf
EnsureFaxServersDefined endp

CommonCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the driver

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Clean up anything before getting killed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintExit	proc	near
		clc
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

RETURN:		carry	- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		some type of required init

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInitStream	proc	near
		clc			; no errors possible
		ret
PrintInitStream	endp
