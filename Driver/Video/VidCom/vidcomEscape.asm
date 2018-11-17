COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video drivers
FILE:		vidcomEscape.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	VidQEscape	Query for escape support
	VidEscScreenOff	Disable video output
	VidEscScreenOn	Enable video output

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	5/88	initial verison

DESCRIPTION:
	This file contains routines to support some of the escape functions
	for the video drivers.
		
	$Id: vidcomEscape.asm,v 1.1 97/04/18 11:41:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidQEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query for escape capability

CALLED BY:	GLOBAL

PASS:		ax	- escape code to test for

RETURN:		ax	- unchanged if escape is supported
			- 0 if escape is not supported

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Search the table and exit with results;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidQEscape	proc	near
		push	di		; save a few regs
		push	cx
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	di, offset escCodes ; es:di -> esc code tab
		mov	cx, NUM_ESC_ENTRIES ; init rep count
		repne	scasw		; find the right one
		pop	es
		jne	VQE_notFound	;  not in table, quit

		; function is supported, just return
VQE_done:
		pop	cx
		pop	di
		ret

		; function not supported, return ax==0
VQE_notFound:
		clr	ax		; set return value
		jmp	short VQE_done
VidQEscape	endp

ifndef IS_MEM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidUnsetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop using the current device

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	2/15/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidUnsetDevice	proc	near
		mov	cs:[DriverTable].VDI_device, 0xffff
		ret
VidUnsetDevice	endp
endif
