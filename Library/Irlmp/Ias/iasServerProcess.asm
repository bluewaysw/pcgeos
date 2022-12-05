COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasServerProcess.asm

AUTHOR:		Andy Chiu, Dec 14, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial revision


DESCRIPTION:
	Create the object block and FSM associated with the IAS Server
		

	$Id: iasServerProcess.asm,v 1.1 97/04/05 01:07:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


IasCode	segment	resource





if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISPProcessFinalBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We intercept this message as a signal it's time to kill
		our thread.  This message is sent by the last obj block,
		when it's done freeing itself.

CALLED BY:	MSG_PROCESS_FINAL_BLOCK_FREE
PASS:		*ds:si	= IasServerProcessClass object
		ds:di	= IasServerProcessClass instance data
		ds:bx	= IasServerProcessClass object (same as *ds:si)
		es 	= segment of IasServerProcessClass
		ax	= message #
		cx	= handle to freed block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISPProcessFinalBlockFree	method dynamic IasServerProcessClass, 
					MSG_PROCESS_FINAL_BLOCK_FREE
		.enter

	;
	; Call the super to do whatever the super does.
	;
		push	ds
		segmov	ds, ss
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		pop	ds
	;
	; Let's detach our thread.
	;
		PSem	ds, iasServerSem

		clr	bx
		xchg	bx, ds:[iasServerThread]
		clr	cx,dx,bp		; no ack needed
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_META_DETACH
		call	ObjMessage

		VSem	ds, iasServerSem
				
		.leave
		ret
ISPProcessFinalBlockFree	endm
endif
IasCode	ends










