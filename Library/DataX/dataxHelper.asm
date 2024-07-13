COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Data Exchange Library
MODULE:		
FILE:		dataxHelper.asm

AUTHOR:		Robert Greenwalt, Nov  9, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 9/96   	Initial revision


DESCRIPTION:
		
	

	$Id: dataxHelper.asm,v 1.1 97/04/04 17:54:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DataXFixed	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXHKillSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_DXH_KILL_SELF
PASS:		*ds:si	= DataXHelperClass object
		ds:di	= DataXHelperClass instance data
		ds:bx	= DataXHelperClass object (same as *ds:si)
		es 	= segment of DataXHelperClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	robertg 	2/26/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXHKillSelf	method dynamic DataXHelperClass, 
					MSG_DXH_KILL_SELF
	.enter
		clr	cx, dx, bp, si
		jmp	ThreadDestroy
	.leave	.unreached
DXHKillSelf	endm

DataXFixed	ends

ExtCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXHMetaIacpDataExchange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle incoming acknowledgements.

CALLED BY:	MSG_META_IACP_DATA_EXCHANGE
PASS:		*ds:si	= DataXHelperClass object
		ds:di	= DataXHelperClass instance data
		ds:bx	= DataXHelperClass object (same as *ds:si)
		es 	= segment of DataXHelperClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXHMetaIacpDataExchange	method dynamic DataXHelperClass, 
					MSG_META_IACP_DATA_EXCHANGE
	uses	ax, cx, dx, bp
	.enter
	.leave
	ret
DXHMetaIacpDataExchange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXHMetaIacpProcessMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_IACP_PROCESS_MESSAGE
PASS:		*ds:si	= DataXHelperClass object
		ds:di	= DataXHelperClass instance data
		ds:bx	= DataXHelperClass object (same as *ds:si)
		es 	= segment of DataXHelperClass
		ax	= message #
		bx	= IACP messsage
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	This is somewhat wierd, but if we are to timeout from bad pipe
setups (pipes containing non-pipe-aware geodes), there exists the
possibility of a pipe-aware geode just taking a real long time.  I
think we have to work from the assumption that any pipe-aware geode
will get done in time X, and if they don't we've got worse things to
worry about.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXHMetaIacpProcessMessage	method dynamic DataXHelperClass, 
					MSG_META_IACP_PROCESS_MESSAGE
	.enter
		mov	bx, cx
		call	ObjGetMessageInfo
	;
	; verify it is a MSG_META_IACP_DATA_EXCHANGE
	;
		cmp	ax, MSG_META_IACP_DATA_EXCHANGE
		jne	done
	;
	; Ok, it's ours, now lets get data from DX
	;
		call	ObjGetMessageData
	;
	; Ok, get rid of it.
	;
		call	ObjFreeMessage
	;
	; Wake up your better half
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	ds:[lastReturnValue], dx
		VSem	ds, openWaitSem, TRASH_AX_BX
done:
	.leave
	ret
DXHMetaIacpProcessMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DXHKillPipe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill the pipe

CALLED BY:	MSG_DXH_KILL_PIPE
PASS:		*ds:si	= DataXHelperClass object
		ds:di	= DataXHelperClass instance data
		ds:bx	= DataXHelperClass object (same as *ds:si)
		es 	= segment of DataXHelperClass
		ax	= message #
		dx	= pipe descriptor handle
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	1/15/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DXHKillPipe	method dynamic DataXHelperClass, 
					MSG_DXH_KILL_PIPE
	uses	dx, ax
	.enter
		push	dx
		call	DXClosePipe
	
	;
	; Free the PipeDescriptorBlock
	;
		mov	bx, dx
		call	MemFree

	.leave
	ret
DXHKillPipe	endm


ExtCode		ends
