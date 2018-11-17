COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskTrigger.asm

AUTHOR:		Adam de Boor, May 23, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/23/92		Initial revision


DESCRIPTION:
	(Enormous) Implementation of the TaskTriggerClass
		

	$Id: taskTrigger.asm,v 1.1 97/04/18 11:58:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTSetIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the task index stored with the trigger.

CALLED BY:	MSG_TT_SET_INDEX
PASS:		*ds:si	= TaskTrigger object
		ds:di	= TaskTriggerInstance
		cx	= index for the beast
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTSetIndex	method dynamic TaskTriggerClass, MSG_TT_SET_INDEX
		.enter
		mov	ds:[di].TTI_index, cx
		.leave
		ret
TTSetIndex	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTActivate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that this TaskTrigger object was selected by the
		user to switch to.

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION
PASS:		*ds:si	= TaskTrigger object
		ds:di	= TaskTriggerInstance
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTSendAction method dynamic TaskTriggerClass, MSG_GEN_TRIGGER_SEND_ACTION
		.enter
	;
	; Just ship our index off to our process to switch to the thing.
	; 
		mov	dx, ds:[di].TTI_index
		mov	ax, MSG_TD_SWITCH
		mov	bx, handle 0
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
TTSendAction endm

Movable	ends

