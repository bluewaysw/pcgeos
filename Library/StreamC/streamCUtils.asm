COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		streamCUtils.asm

AUTHOR:		Adam de Boor, Aug 31, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/31/95		Initial revision


DESCRIPTION:
	Utility routines
		

	$Id: streamCUtils.asm,v 1.1 97/04/07 11:15:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamResident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCUPrepareForDriverCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save si, di, and ds and point ds:si to the DriverInfoStruct
		for the passed driver, after ensuring a driver was passed
		
		Caller must call SCUDoneWithDriverCall with nothing additional
		on the stack.

CALLED BY:	(INTERNAL)
PASS:		bx	= driver handle
RETURN:		ds:si	= DriverInfoStruct
DESTROYED:	di
SIDE EFFECTS:	si, di, ds are saved.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCUPrepareForDriverCall proc	far
		push	si, di, ds
EC <		call	ECCheckDriverHandle				>
   		call	GeodeInfoDriver
		mov	di, sp
		jmp	{fptr.far}ss:[di+6]
SCUPrepareForDriverCall endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCUDoneWithDriverCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo the work of SCUPrepareForDriverCall

CALLED BY:	(INTERNAL)
PASS:		stack as returned from SCUPrepareForDriverCall
		carry flag set/clear by driver call
RETURN:		si, di, ds restored
		ax	= 0 if no error (carry clear on entry)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCUDoneWithDriverCall proc far
		mov	di, sp
		pop	ss:[di+10]		; replace SCUPrepare's ret addr
		pop	ss:[di+12]		;  with our own
		pop	si, di, ds		; pop the saved regs
		jc	done
		clr	ax			; return 0 if no error, else
						;  ax holds StreamError
done:
		ret
SCUDoneWithDriverCall endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCULoadDGroupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load DS with the library's dgroup segment

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		DS	= dgroup
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCULoadDGroupDS	proc	far
		uses	bx
		.enter
		mov	bx, handle dgroup
		call	MemDerefDS
		.leave
		ret
SCULoadDGroupDS	endp

StreamResident	ends
