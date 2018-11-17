COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3InkDelete.asm

AUTHOR:		Andy Chiu, Nov  7, 1993

ROUTINES:
	Name			Description
	----			-----------
	InkDeleteTriggerSendAction
				This is a special trigger so that it 
				deletes the ink object used.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/ 7/93   	Initial revision


DESCRIPTION:
	
		

	$Id: group3InkDelete.asm,v 1.1 97/04/18 11:52:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDeleteTriggerSendAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a special trigger so that it deletes the ink object
		used.

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION
PASS:		*ds:si	= InkDeleteTriggerClass object
		ds:di	= InkDeleteTriggerClass instance data
		ds:bx	= InkDeleteTriggerClass object (same as *ds:si)
		es 	= segment of InkDeleteClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	11/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDeleteTriggerSendAction	method dynamic InkDeleteTriggerClass, 
					MSG_GEN_TRIGGER_SEND_ACTION
	uses	ax, cx, dx, bp
	.enter

	;
	; Tell the ink object to erase all it's ink
	;
		mov	dx, size InkDBFrame
		sub	sp, dx
		mov	bp, sp
		clrdw	ss:[bp].IDBF_DBGroupAndItem
		mov	ax, MSG_INK_LOAD_FROM_DB_ITEM
		mov	di, mask MF_CALL or mask MF_STACK
		mov	si, offset CoverPageCommentsInk
		call	ObjCallInstanceNoLock

		add	sp, size InkDBFrame

	.leave
	ret
InkDeleteTriggerSendAction	endm





