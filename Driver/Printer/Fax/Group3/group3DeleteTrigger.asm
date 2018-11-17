COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		group3DeleteTrigger.asm

AUTHOR:		Andy Chiu, Nov 16, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/16/93   	Initial revision


DESCRIPTION:
	Methods for the delete trigger used in text objects.
		

	$Id: group3DeleteTrigger.asm,v 1.1 97/04/18 11:52:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will send the message plus a modified message.  To be
		used only for erase all triggers associated with a 
		text object.

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION
PASS:		*ds:si	= DeleteTriggerClass object
		ds:di	= DeleteTriggerClass instance data
		ds:bx	= DeleteTriggerClass object (same as *ds:si)
		es 	= segment of DeleteTriggerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax. cx. dx. bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteTriggerSendAction	method dynamic DeleteTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION

		mov	di, offset DeleteTriggerClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].DeleteTrigger_offset
		
		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		mov	cx, ax			; cx <- non zero
		mov	si, ds:[di].GTI_destination.chunk
		call	ObjCallInstanceNoLock

		ret
DeleteTriggerSendAction	endm
